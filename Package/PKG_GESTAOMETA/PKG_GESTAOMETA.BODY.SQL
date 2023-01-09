CREATE OR REPLACE PACKAGE BODY PKG_GESTAOMETA IS

  FUNCTION F_QUOTED(PS_VALOR IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CHR(39) || PS_VALOR || CHR(39);
  END;
  
  PROCEDURE P_LOG(PS_VALOR IN VARCHAR2) IS
  PRAGMA AUTONOMOUS_TRANSACTION;  
  -- CREATE TABLE PCLOG_PKG_GESTAOMETA(DTLOG DATE, VALOR VARCHAR2(4000));
  BEGIN
    EXECUTE IMMEDIATE 'INSERT INTO PCLOG_PKG_GESTAOMETA VALUES (SYSDATE, ' || F_QUOTED(PS_VALOR) || ')';
    COMMIT; 
  END;

  FUNCTION DEF_PCGMMETAGLOBALTEMP(PS_CODFILIAL IN VARCHAR2) RETURN VARCHAR2 IS
    vvTable VARCHAR2(30);
  BEGIN
    vvTable := 'PCGMMETAGLOBALTEMP_' || REPLACE(PS_CODFILIAL,CHR(39),'');
    RETURN vvTable;
  END;
  
  PROCEDURE P_InserirMetaTemp(PSINSERIR       IN VARCHAR2,
                              PSCODFILIAL     IN VARCHAR2,
                              PT_PCGMMETATEMP IN PCGMMETAGLOBALTEMP%ROWTYPE DEFAULT NULL,
                              PB_PCGMMETATEMP IN TB_PCGMMETATEMP) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    ROWPCGMMETATEMP           PCGMMETAGLOBALTEMP%ROWTYPE;
    VSSQL                     VARCHAR2(15000);

    TYPE TT_NUMTRANSVENDA          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODCOMBINACAO          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODENTIDADE            IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;
    TYPE TT_CODMETA                IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODTIPOMETA            IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODINDICADOR           IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_TABELAENTIDADE         IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
    TYPE TT_DATA                   IS TABLE OF DATE INDEX BY BINARY_INTEGER;
    TYPE TT_VLLIQUIDO              IS TABLE OF NUMBER(18, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLBONIFIC              IS TABLE OF NUMBER(18, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_CODFILIAL              IS TABLE OF VARCHAR2(3) INDEX BY BINARY_INTEGER;
    TYPE TT_VOLUMELIQUIDO          IS TABLE OF NUMBER(18, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_LITRAGEMLIQUIDO        IS TABLE OF NUMBER(18, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_CODUSUR                IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODSUPERVISOR          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODGERENTE             IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_NUMCAR                 IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODPROD                IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODCLI                 IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODFORNEC              IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODSEC                 IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_CODEPTO                IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_PERCOM                 IS TABLE OF NUMBER(18, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_TIPOMOV                IS TABLE OF VARCHAR2(2) INDEX BY BINARY_INTEGER;
    TYPE TT_NUMSEQ                 IS TABLE OF NUMBER(20) INDEX BY BINARY_INTEGER;
    TYPE TT_VLLUCRO                IS TABLE OF NUMBER(15, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_PRAZOMEDIO             IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_NUMTRANSENTNFESTORNADA IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_VLVENDA                IS TABLE OF NUMBER(18, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_NUMTRANSENT            IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE TT_VLST                   IS TABLE OF NUMBER(16, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLIPI                  IS TABLE OF NUMBER(16, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLFECP                 IS TABLE OF NUMBER(16, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLIPIBONIFIC           IS TABLE OF NUMBER(16, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLSTBONIFIC            IS TABLE OF NUMBER(16, 6) INDEX BY BINARY_INTEGER;
    TYPE TT_CODGERENTEREGIONAL     IS TABLE OF NUMBER(8) INDEX BY BINARY_INTEGER;
    TYPE TT_CODGERENTENACIONAL     IS TABLE OF NUMBER(8) INDEX BY BINARY_INTEGER;
    TYPE TT_PESOLIQUIDO            IS TABLE OF NUMBER(18,6) INDEX BY BINARY_INTEGER;
    TYPE TT_QTPRODUTO              IS TABLE OF NUMBER(20,6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLDESCONTO             IS TABLE OF NUMBER(18,6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLTABELA               IS TABLE OF NUMBER(18,6) INDEX BY BINARY_INTEGER;
    TYPE TT_VLDEVOLUCAO            IS TABLE OF NUMBER(18,6) INDEX BY BINARY_INTEGER;
    TYPE TT_CODPRACA               IS TABLE OF NUMBER(6) INDEX BY BINARY_INTEGER;
    --
    vtNUMTRANSVENDA                TT_NUMTRANSVENDA          ;
    vtCODCOMBINACAO                TT_CODCOMBINACAO          ;
    vtCODENTIDADE                  TT_CODENTIDADE            ;
    vtCODMETA                      TT_CODMETA                ;
    vtCODTIPOMETA                  TT_CODTIPOMETA            ;
    vtCODINDICADOR                 TT_CODINDICADOR           ;
    vtTABELAENTIDADE               TT_TABELAENTIDADE         ;
    vtDATA                         TT_DATA                   ;
    vtVLLIQUIDO                    TT_VLLIQUIDO              ;
    vtVLBONIFIC                    TT_VLBONIFIC              ;
    vtCODFILIAL                    TT_CODFILIAL              ;
    vtVOLUMELIQUIDO                TT_VOLUMELIQUIDO          ;
    vtLITRAGEMLIQUIDO              TT_LITRAGEMLIQUIDO        ;
    vtCODUSUR                      TT_CODUSUR                ;
    vtCODSUPERVISOR                TT_CODSUPERVISOR          ;
    vtCODGERENTE                   TT_CODGERENTE             ;
    vtNUMCAR                       TT_NUMCAR                 ;
    vtCODPROD                      TT_CODPROD                ;
    vtCODCLI                       TT_CODCLI                 ;
    vtCODFORNEC                    TT_CODFORNEC              ;
    vtCODSEC                       TT_CODSEC                 ;
    vtCODEPTO                      TT_CODEPTO                ;
    vtPERCOM                       TT_PERCOM                 ;
    vtTIPOMOV                      TT_TIPOMOV                ;
    vtNUMSEQ                       TT_NUMSEQ                 ;
    vtVLLUCRO                      TT_VLLUCRO                ;
    vtPRAZOMEDIO                   TT_PRAZOMEDIO             ;
    vtNUMTRANSENTNFESTORNADA       TT_NUMTRANSENTNFESTORNADA ;
    vtVLVENDA                      TT_VLVENDA                ;
    vtNUMTRANSENT                  TT_NUMTRANSENT            ;
    vtVLST                         TT_VLST                   ;
    vtVLIPI                        TT_VLIPI                  ;
    vtVLFECP                       TT_VLFECP                 ;
    vtVLIPIBONIFIC                 TT_VLIPIBONIFIC           ;
    vtVLSTBONIFIC                  TT_VLSTBONIFIC            ;
    vtCODGERENTEREGIONAL           TT_CODGERENTEREGIONAL     ;
    vtCODGERENTENACIONAL           TT_CODGERENTENACIONAL     ;
    vtPESOLIQUIDO                  TT_PESOLIQUIDO            ;
    vtQTPRODUTO                    TT_QTPRODUTO              ;
    vtVLDESCONTO                   TT_VLDESCONTO             ;
    vtVLTABELA                     TT_VLTABELA               ;
    vtVLDEVOLUCAO                  TT_VLDEVOLUCAO            ;
    vtCODPRACA                     TT_CODPRACA               ;    
    --        
  BEGIN
 
    VSSQL := 'INSERT INTO ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || '
                        ( NUMTRANSVENDA
                        , DATA
                        , VLLIQUIDO
                        , VLBONIFIC
                        , CODFILIAL
                        , VOLUMELIQUIDO
                        , LITRAGEMLIQUIDO
                        , CODUSUR
                        , CODSUPERVISOR
                        , CODGERENTE
                        , NUMCAR
                        , CODPROD
                        , CODCLI
                        , CODFORNEC
                        , CODSEC
                        , CODEPTO
                        , PERCOM
                        , CODCOMBINACAO
                        , CODENTIDADE
                        , CODMETA
                        , CODTIPOMETA
                        , CODINDICADOR
                        , TABELAENTIDADE
                        , TIPOMOV
                        , NUMSEQ
                        , VLLUCRO
                        , PRAZOMEDIO
                        , NUMTRANSENTNFESTORNADA
                        , VLVENDA
                        , NUMTRANSENT
                        , VLST
                        , VLIPI
                        , VLIPIBONIFIC
                        , VLSTBONIFIC
                        , CODGERENTEREGIONAL
                        , CODGERENTENACIONAL
                        , PESOLIQUIDO
                        , QTPRODUTO
                        , VLDESCONTO
                        , VLTABELA
                        , VLDEVOLUCAO
                        , CODPRACA )
                 VALUES ( :NUMTRANSVENDA
                        , :DATA
                        , :VLLIQUIDO
                        , :VLBONIFIC
                        , :CODFILIAL
                        , :VOLUMELIQUIDO
                        , :LITRAGEMLIQUIDO
                        , :CODUSUR
                        , :CODSUPERVISOR
                        , :CODGERENTE
                        , :NUMCAR
                        , :CODPROD
                        , :CODCLI
                        , :CODFORNEC
                        , :CODSEC
                        , :CODEPTO
                        , :PERCOM
                        , :CODCOMBINACAO
                        , :CODENTIDADE
                        , :CODMETA
                        , :CODTIPOMETA
                        , :CODINDICADOR
                        , :TABELAENTIDADE
                        , :TIPOMOV
                        , :NUMSEQ
                        , :VLLUCRO
                        , :PRAZOMEDIO
                        , :NUMTRANSENTNFESTORNADA
                        , :VLVENDA
                        , :NUMTRANSENT
                        , :VLST
                        , :VLIPI
                        , :VLIPIBONIFIC
                        , :VLSTBONIFIC
                        , :CODGERENTEREGIONAL
                        , :CODGERENTENACIONAL
                        , :PESOLIQUIDO
                        , :QTPRODUTO
                        , :VLDESCONTO
                        , :VLTABELA
                        , :VLDEVOLUCAO
                        , :CODPRACA ) ';                                                       
  
    BEGIN
      IF PSINSERIR = 'S' THEN
        ROWPCGMMETATEMP.NUMTRANSVENDA          := PT_PCGMMETATEMP.NUMTRANSVENDA;
        ROWPCGMMETATEMP.DATA                   := PT_PCGMMETATEMP.DATA;
        ROWPCGMMETATEMP.VLLIQUIDO              := PT_PCGMMETATEMP.VLLIQUIDO;
        ROWPCGMMETATEMP.VLBONIFIC              := PT_PCGMMETATEMP.VLBONIFIC;
        ROWPCGMMETATEMP.CODFILIAL              := PT_PCGMMETATEMP.CODFILIAL;
        ROWPCGMMETATEMP.VOLUMELIQUIDO          := PT_PCGMMETATEMP.VOLUMELIQUIDO;
        ROWPCGMMETATEMP.LITRAGEMLIQUIDO        := PT_PCGMMETATEMP.LITRAGEMLIQUIDO;
        ROWPCGMMETATEMP.CODUSUR                := PT_PCGMMETATEMP.CODUSUR;
        ROWPCGMMETATEMP.CODSUPERVISOR          := PT_PCGMMETATEMP.CODSUPERVISOR;
        ROWPCGMMETATEMP.CODGERENTE             := PT_PCGMMETATEMP.CODGERENTE;
        ROWPCGMMETATEMP.NUMCAR                 := PT_PCGMMETATEMP.NUMCAR;
        ROWPCGMMETATEMP.CODPROD                := PT_PCGMMETATEMP.CODPROD;
        ROWPCGMMETATEMP.CODCLI                 := PT_PCGMMETATEMP.CODCLI;
        ROWPCGMMETATEMP.CODFORNEC              := PT_PCGMMETATEMP.CODFORNEC;
        ROWPCGMMETATEMP.CODSEC                 := PT_PCGMMETATEMP.CODSEC;
        ROWPCGMMETATEMP.CODEPTO                := PT_PCGMMETATEMP.CODEPTO;
        ROWPCGMMETATEMP.PERCOM                 := PT_PCGMMETATEMP.PERCOM;
        ROWPCGMMETATEMP.CODCOMBINACAO          := PT_PCGMMETATEMP.CODCOMBINACAO;
        ROWPCGMMETATEMP.CODENTIDADE            := PT_PCGMMETATEMP.CODENTIDADE;
        ROWPCGMMETATEMP.CODMETA                := PT_PCGMMETATEMP.CODMETA;
        ROWPCGMMETATEMP.CODTIPOMETA            := PT_PCGMMETATEMP.CODTIPOMETA;
        ROWPCGMMETATEMP.CODINDICADOR           := PT_PCGMMETATEMP.CODINDICADOR;
        ROWPCGMMETATEMP.TABELAENTIDADE         := PT_PCGMMETATEMP.TABELAENTIDADE;
        ROWPCGMMETATEMP.TIPOMOV                := PT_PCGMMETATEMP.TIPOMOV;
        ROWPCGMMETATEMP.NUMSEQ                 := PT_PCGMMETATEMP.NUMSEQ;
        ROWPCGMMETATEMP.VLLUCRO                := PT_PCGMMETATEMP.VLLUCRO;
        ROWPCGMMETATEMP.PRAZOMEDIO             := PT_PCGMMETATEMP.PRAZOMEDIO;
        ROWPCGMMETATEMP.NUMTRANSENTNFESTORNADA := PT_PCGMMETATEMP.NUMTRANSENTNFESTORNADA;
        ROWPCGMMETATEMP.VLVENDA                := PT_PCGMMETATEMP.VLVENDA;
        ROWPCGMMETATEMP.NUMTRANSENT            := PT_PCGMMETATEMP.NUMTRANSENT;
        ROWPCGMMETATEMP.VLST                   := PT_PCGMMETATEMP.VLST;
        ROWPCGMMETATEMP.VLIPI                  := PT_PCGMMETATEMP.VLIPI;
        ROWPCGMMETATEMP.VLIPIBONIFIC           := PT_PCGMMETATEMP.VLIPIBONIFIC;
        ROWPCGMMETATEMP.VLSTBONIFIC            := PT_PCGMMETATEMP.VLSTBONIFIC;
        ROWPCGMMETATEMP.CODGERENTEREGIONAL     := PT_PCGMMETATEMP.CODGERENTEREGIONAL;
        ROWPCGMMETATEMP.CODGERENTENACIONAL     := PT_PCGMMETATEMP.CODGERENTENACIONAL;
        ROWPCGMMETATEMP.PESOLIQUIDO            := PT_PCGMMETATEMP.PESOLIQUIDO;
        ROWPCGMMETATEMP.QTPRODUTO              := PT_PCGMMETATEMP.QTPRODUTO;
        ROWPCGMMETATEMP.VLDESCONTO             := PT_PCGMMETATEMP.VLDESCONTO;
        ROWPCGMMETATEMP.VLTABELA               := PT_PCGMMETATEMP.VLTABELA;
        ROWPCGMMETATEMP.VLDEVOLUCAO            := PT_PCGMMETATEMP.VLDEVOLUCAO;
        ROWPCGMMETATEMP.CODPRACA               := PT_PCGMMETATEMP.CODPRACA;
        --INSERT INTO PCGMMETAGLOBALTEMP VALUES ROWPCGMMETATEMP;
        EXECUTE IMMEDIATE VSSQL
                 USING IN ROWPCGMMETATEMP.NUMTRANSVENDA
                        , ROWPCGMMETATEMP.DATA
                        , ROWPCGMMETATEMP.VLLIQUIDO
                        , ROWPCGMMETATEMP.VLBONIFIC
                        , ROWPCGMMETATEMP.CODFILIAL
                        , ROWPCGMMETATEMP.VOLUMELIQUIDO
                        , ROWPCGMMETATEMP.LITRAGEMLIQUIDO
                        , ROWPCGMMETATEMP.CODUSUR
                        , ROWPCGMMETATEMP.CODSUPERVISOR
                        , ROWPCGMMETATEMP.CODGERENTE
                        , ROWPCGMMETATEMP.NUMCAR
                        , ROWPCGMMETATEMP.CODPROD
                        , ROWPCGMMETATEMP.CODCLI
                        , ROWPCGMMETATEMP.CODFORNEC
                        , ROWPCGMMETATEMP.CODSEC
                        , ROWPCGMMETATEMP.CODEPTO
                        , ROWPCGMMETATEMP.PERCOM
                        , ROWPCGMMETATEMP.CODCOMBINACAO
                        , ROWPCGMMETATEMP.CODENTIDADE
                        , ROWPCGMMETATEMP.CODMETA
                        , ROWPCGMMETATEMP.CODTIPOMETA
                        , ROWPCGMMETATEMP.CODINDICADOR
                        , ROWPCGMMETATEMP.TABELAENTIDADE
                        , ROWPCGMMETATEMP.TIPOMOV
                        , ROWPCGMMETATEMP.NUMSEQ
                        , ROWPCGMMETATEMP.VLLUCRO
                        , ROWPCGMMETATEMP.PRAZOMEDIO
                        , ROWPCGMMETATEMP.NUMTRANSENTNFESTORNADA
                        , ROWPCGMMETATEMP.VLVENDA
                        , ROWPCGMMETATEMP.NUMTRANSENT
                        , ROWPCGMMETATEMP.VLST
                        , ROWPCGMMETATEMP.VLIPI
                        , ROWPCGMMETATEMP.VLIPIBONIFIC
                        , ROWPCGMMETATEMP.VLSTBONIFIC
                        , ROWPCGMMETATEMP.CODGERENTEREGIONAL
                        , ROWPCGMMETATEMP.CODGERENTENACIONAL
                        , ROWPCGMMETATEMP.PESOLIQUIDO
                        , ROWPCGMMETATEMP.QTPRODUTO
                        , ROWPCGMMETATEMP.VLDESCONTO
                        , ROWPCGMMETATEMP.VLTABELA
                        , ROWPCGMMETATEMP.VLDEVOLUCAO
                        , ROWPCGMMETATEMP.CODPRACA;        
      ELSE

        FOR i IN PB_PCGMMETATEMP.FIRST .. PB_PCGMMETATEMP.LAST LOOP
          vtNUMTRANSVENDA(i)          := PB_PCGMMETATEMP(i).NUMTRANSVENDA;
          vtDATA(i)                   := PB_PCGMMETATEMP(i).DATA;
          vtVLLIQUIDO(i)              := PB_PCGMMETATEMP(i).VLLIQUIDO;
          vtVLBONIFIC(i)              := PB_PCGMMETATEMP(i).VLBONIFIC;
          vtCODFILIAL(i)              := PB_PCGMMETATEMP(i).CODFILIAL;
          vtVOLUMELIQUIDO(i)          := PB_PCGMMETATEMP(i).VOLUMELIQUIDO;
          vtLITRAGEMLIQUIDO(i)        := PB_PCGMMETATEMP(i).LITRAGEMLIQUIDO;
          vtCODUSUR(i)                := PB_PCGMMETATEMP(i).CODUSUR;
          vtCODSUPERVISOR(i)          := PB_PCGMMETATEMP(i).CODSUPERVISOR;
          vtCODGERENTE(i)             := PB_PCGMMETATEMP(i).CODGERENTE;
          vtNUMCAR(i)                 := PB_PCGMMETATEMP(i).NUMCAR;
          vtCODPROD(i)                := PB_PCGMMETATEMP(i).CODPROD;
          vtCODCLI(i)                 := PB_PCGMMETATEMP(i).CODCLI;
          vtCODFORNEC(i)              := PB_PCGMMETATEMP(i).CODFORNEC;
          vtCODSEC(i)                 := PB_PCGMMETATEMP(i).CODSEC;
          vtCODEPTO(i)                := PB_PCGMMETATEMP(i).CODEPTO;
          vtPERCOM(i)                 := PB_PCGMMETATEMP(i).PERCOM;
          vtCODCOMBINACAO(i)          := PB_PCGMMETATEMP(i).CODCOMBINACAO;
          vtCODENTIDADE(i)            := PB_PCGMMETATEMP(i).CODENTIDADE;
          vtCODMETA(i)                := PB_PCGMMETATEMP(i).CODMETA;
          vtCODTIPOMETA(i)            := PB_PCGMMETATEMP(i).CODTIPOMETA;
          vtCODINDICADOR(i)           := PB_PCGMMETATEMP(i).CODINDICADOR;
          vtTABELAENTIDADE(i)         := PB_PCGMMETATEMP(i).TABELAENTIDADE;
          vtTIPOMOV(i)                := PB_PCGMMETATEMP(i).TIPOMOV;
          vtNUMSEQ(i)                 := PB_PCGMMETATEMP(i).NUMSEQ;
          vtVLLUCRO(i)                := PB_PCGMMETATEMP(i).VLLUCRO;
          vtPRAZOMEDIO(i)             := PB_PCGMMETATEMP(i).PRAZOMEDIO;
          vtNUMTRANSENTNFESTORNADA(i) := PB_PCGMMETATEMP(i).NUMTRANSENTNFESTORNADA;
          vtVLVENDA(i)                := PB_PCGMMETATEMP(i).VLVENDA;
          vtNUMTRANSENT(i)            := PB_PCGMMETATEMP(i).NUMTRANSENT;
          vtVLST(i)                   := PB_PCGMMETATEMP(i).VLST;
          vtVLIPI(i)                  := PB_PCGMMETATEMP(i).VLIPI;
          vtVLIPIBONIFIC(i)           := PB_PCGMMETATEMP(i).VLIPIBONIFIC;
          vtVLSTBONIFIC(i)            := PB_PCGMMETATEMP(i).VLSTBONIFIC;
          vtCODGERENTEREGIONAL(i)     := PB_PCGMMETATEMP(i).CODGERENTEREGIONAL;
          vtCODGERENTENACIONAL(i)     := PB_PCGMMETATEMP(i).CODGERENTENACIONAL;
          vtPESOLIQUIDO(i)            := PB_PCGMMETATEMP(i).PESOLIQUIDO;
          vtQTPRODUTO(i)              := PB_PCGMMETATEMP(i).QTPRODUTO;
          vtVLDESCONTO(i)             := PB_PCGMMETATEMP(i).VLDESCONTO;
          vtVLTABELA(i)               := PB_PCGMMETATEMP(i).VLTABELA;
          vtVLDEVOLUCAO(i)            := PB_PCGMMETATEMP(i).VLDEVOLUCAO;
          vtCODPRACA(i)               := PB_PCGMMETATEMP(i).CODPRACA;        
        END LOOP;

        FORALL i IN vtNUMTRANSVENDA.FIRST .. vtNUMTRANSVENDA.LAST
          EXECUTE IMMEDIATE VSSQL
                   USING IN vtNUMTRANSVENDA(i)
                          , vtDATA(i)
                          , vtVLLIQUIDO(i)
                          , vtVLBONIFIC(i)
                          , vtCODFILIAL(i)
                          , vtVOLUMELIQUIDO(i)
                          , vtLITRAGEMLIQUIDO(i)
                          , vtCODUSUR(i)
                          , vtCODSUPERVISOR(i)
                          , vtCODGERENTE(i)
                          , vtNUMCAR(i)
                          , vtCODPROD(i)
                          , vtCODCLI(i)
                          , vtCODFORNEC(i)
                          , vtCODSEC(i)
                          , vtCODEPTO(i)
                          , vtPERCOM(i)
                          , vtCODCOMBINACAO(i)
                          , vtCODENTIDADE(i)
                          , vtCODMETA(i)
                          , vtCODTIPOMETA(i)
                          , vtCODINDICADOR(i)
                          , vtTABELAENTIDADE(i)
                          , vtTIPOMOV(i)
                          , vtNUMSEQ(i)
                          , vtVLLUCRO(i)
                          , vtPRAZOMEDIO(i)
                          , vtNUMTRANSENTNFESTORNADA(i)
                          , vtVLVENDA(i)
                          , vtNUMTRANSENT(i)
                          , vtVLST(i)
                          , vtVLIPI(i)
                          , vtVLIPIBONIFIC(i)
                          , vtVLSTBONIFIC(i)
                          , vtCODGERENTEREGIONAL(i)
                          , vtCODGERENTENACIONAL(i)
                          , vtPESOLIQUIDO(i)
                          , vtQTPRODUTO(i)
                          , vtVLDESCONTO(i)
                          , vtVLTABELA(i)
                          , vtVLDEVOLUCAO(i)
                          , vtCODPRACA(i);
        
        --FORALL i IN PB_PCGMMETATEMP.FIRST .. PB_PCGMMETATEMP.LAST
        --  INSERT INTO PCGMMETAGLOBALTEMP VALUES PB_PCGMMETATEMP (I);
        
      END IF;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END;
  
  PROCEDURE P_AtualizarDtUltProcessamento(PNCODMETA      IN NUMBER,
                                          PNCODTIPOMETA  IN NUMBER,
                                          PNCODINDICADOR IN NUMBER) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    BEGIN
      UPDATE PCGMMETACONSOLIDADA
      SET    DTULTPROCESSAMENTO = SYSDATE
      WHERE  CODMETA = PNCODMETA
      AND    CODTIPOMETA = PNCODTIPOMETA
      AND    CODINDICADOR = PNCODINDICADOR;
      
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END;

  PROCEDURE P_AtualizarPCGMMETACOMB(PT_PARAMETRO IN TR_PARAMETRO) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    BEGIN
      IF PT_PARAMETRO.SUBTOTAL IS NULL THEN
        IF PT_PARAMETRO.TIPOCHAMADA = 'META' THEN
          IF PT_PARAMETRO.DTFECHAMENTO IS NULL THEN
            UPDATE PCGMMETACOMB
               SET REALIZADO    = NVL(PT_PARAMETRO.REALIZADO, 0),
                   PERCATINGIDO = NVL(PT_PARAMETRO.PERCATINGIDO, 0),
                   VLFATURADO = PT_PARAMETRO.VLFATURADO,
                   PERCOMPORIND          = PT_PARAMETRO.PERCOMPORIND,
                   PERCPESOINDNIVELATING = NVL(PT_PARAMETRO.PERCPESOINDNIVELATING, 0),
                   FAIXAINI              = PT_PARAMETRO.FAIXAINI,
                   FAIXAFIM              = PT_PARAMETRO.FAIXAFIM
             WHERE CODMETA = PT_PARAMETRO.CODMETA
               AND CODCOMBINACAO = PT_PARAMETRO.CODCOMBINACAO
               AND DATA = PT_PARAMETRO.DATA;

            IF NVL(PT_PARAMETRO.ITEMNOVOADD, 'N') = 'S' THEN
              UPDATE PCGMMETACOMB
                 SET VALOR = 0
               WHERE CODMETA = PT_PARAMETRO.CODMETA
                 AND CODCOMBINACAO = PT_PARAMETRO.CODCOMBINACAO
                 AND DATA = PT_PARAMETRO.DATA;
            END IF;

            IF NVL(PT_PARAMETRO.PERCOMMOV, 'N') = 'NOMECOMBENTIDADE' THEN
              UPDATE PCGMMETACOMB
                 SET NOMECOMBENTIDADE = PT_PARAMETRO.NOMECOMBENTIDADE
               WHERE CODMETA = PT_PARAMETRO.CODMETA
                 AND CODCOMBINACAO = PT_PARAMETRO.CODCOMBINACAO
                 AND DATA = PT_PARAMETRO.DATA;
            END IF;
          END IF;
        ELSE
          UPDATE PCGMMETACOMB
             SET VLCOMISSAO = PT_PARAMETRO.VLCOMISSAO,
                 -- VLFATURADO   = PT_PARAMETRO.VLFATURADO,
                 PERCPESOINDNIVELATING = NVL(PT_PARAMETRO.PERCPESOINDNIVELATING, 0),
                 FAIXAINI              = PT_PARAMETRO.FAIXAINI,
                 FAIXAFIM              = PT_PARAMETRO.FAIXAFIM
           WHERE CODMETA = PT_PARAMETRO.CODMETA
             AND CODTIPOMETA = PT_PARAMETRO.CODTIPOMETA
             AND CODINDICADOR = PT_PARAMETRO.CODINDICADOR
             AND CODCOMBINACAO = PT_PARAMETRO.CODCOMBINACAO
             AND DATA = PT_PARAMETRO.DATA
             AND DTFECHAMENTO IS NOT NULL;
        END IF;
      ELSE
        IF PT_PARAMETRO.PERIODICIDADE = 'D' THEN
          UPDATE PCGMMETACOMB
             SET SUBTOTAL = PT_PARAMETRO.SUBTOTAL --,
           WHERE CODMETA = PT_PARAMETRO.CODMETA
             AND CODTIPOMETA = PT_PARAMETRO.CODTIPOMETA
             AND CODINDICADOR = PT_PARAMETRO.CODINDICADOR
             AND DATA >= PT_PARAMETRO.DATA
             AND DATA <= PT_PARAMETRO.DATAFIM;
        ELSE
          IF PT_PARAMETRO.TIPOENTIDADE = 'GER' THEN
            UPDATE PCGMMETACOMB
               SET SUBTOTAL     = PT_PARAMETRO.SUBTOTAL,
                   PERCATINGIDO = NVL(PT_PARAMETRO.PERCATINGIDO, 0)
             WHERE CODMETA = PT_PARAMETRO.CODMETA
               AND CODTIPOMETA = PT_PARAMETRO.CODTIPOMETA
               AND CODINDICADOR = PT_PARAMETRO.CODINDICADOR
               AND DATA = PT_PARAMETRO.DATA;
          ELSE
            UPDATE PCGMMETACOMB
               SET SUBTOTAL = PT_PARAMETRO.SUBTOTAL
             WHERE CODMETA = PT_PARAMETRO.CODMETA
               AND CODTIPOMETA = PT_PARAMETRO.CODTIPOMETA
               AND CODINDICADOR = PT_PARAMETRO.CODINDICADOR
               AND DATA = PT_PARAMETRO.DATA;
          END IF;
        END IF;
      END IF;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END;

  PROCEDURE P_GravarPCGMMETACOMBCOMPLE(PDDATAINI               IN DATE,
                                       PDDATAFIM               IN DATE,
                                       PNCODCOMBINACAO         IN NUMBER,
                                       PNCODMETA               IN NUMBER,
                                       PSBLOCOSQLCALCREALIZADO IN VARCHAR2,
                                       PSCODFILIAL             IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    ROWPCGMMETACOMBCOMPLE PCGMMETACOMBCOMPLE%ROWTYPE;
    DADOSVENDA            TB_PCGMINDICADOR;
    CONTADADOSADD         NUMBER;
    VSSQL                 VARCHAR2(5000);
  BEGIN
    BEGIN
      VSSQL := 'SELECT 0,''0'', 0, NVL(PERCOM, 0) PERCOMMOV,
                     NVL(ROUND(SUM(NVL(VLLIQUIDO, 0) - NVL(VLST, 0) - NVL(VLIPI, 0) - NVL(VLFECP, 0)),2),0) VLFATPORPERCOM,
                      0,0,0,0,0,0
                 FROM (SELECT   MOV.*
                         FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || ' MOV ' ||
               PSBLOCOSQLCALCREALIZADO || '
--                        AND VLLIQUIDO IS NOT NULL
                          AND MOV.CODPROD IS NOT NULL
                          AND MOV.CODFILIAL IN(' ||
               PSCODFILIAL || ')
                          AND DATA >= ''' || PDDATAINI || '''
                          AND DATA <= ''' || PDDATAFIM || '''
                          ) MOV
                   GROUP BY PERCOM  ';

      EXECUTE IMMEDIATE VSSQL BULK COLLECT
        INTO DADOSVENDA;

      SELECT COUNT(1)
        INTO CONTADADOSADD
        FROM PCGMMETACOMBCOMPLE
       WHERE DATA = PDDATAINI
         AND CODCOMBINACAO = PNCODCOMBINACAO
         AND CODMETA = PNCODMETA;

      IF (DADOSVENDA.COUNT > 0) THEN
        ROWPCGMMETACOMBCOMPLE.DATA          := PDDATAINI;
        ROWPCGMMETACOMBCOMPLE.CODCOMBINACAO := PNCODCOMBINACAO;
        ROWPCGMMETACOMBCOMPLE.CODMETA       := PNCODMETA;

        IF (CONTADADOSADD > 0) THEN
          DELETE FROM PCGMMETACOMBCOMPLE
           WHERE DATA = PDDATAINI
             AND CODCOMBINACAO = PNCODCOMBINACAO
             AND CODMETA = PNCODMETA;
        END IF;
      END IF;

      FOR I IN 1 .. DADOSVENDA.COUNT LOOP
        ROWPCGMMETACOMBCOMPLE.PERCOMMOV      := DADOSVENDA(I).PERCOMMOV;
        ROWPCGMMETACOMBCOMPLE.VLFATPORPERCOM := DADOSVENDA(I)
                                               .VLFATPORPERCOM;
        INSERT INTO PCGMMETACOMBCOMPLE VALUES ROWPCGMMETACOMBCOMPLE;
      END LOOP;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        VSSQL := '' || DBMS_UTILITY.FORMAT_ERROR_STACK;
    END;

  END;

  PROCEDURE P_DeletarPCGMMETATEMP(PS_CODFILIAL IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    execute immediate 'TRUNCATE table PCGMMETAGLOBALTEMP_' || REPLACE(PS_CODFILIAL,CHR(39),'');
    COMMIT;
  END;

  /*FUNCTION F_OBTEMTODOSNUMTRANSVENDA(PSFILIAL         IN VARCHAR2,
                      PSREGRAINDICADOR IN VARCHAR2,
                      PNCODGERENTE     IN NUMBER DEFAULT NULL,
                      PNCODSUPERVISOR  IN NUMBER DEFAULT NULL,
                      PNCODUSUR        IN NUMBER DEFAULT NULL,
                      PDDATAINI        IN DATE,
                      PDDATAFIM        IN DATE) RETURN VARCHAR2 IS
    BEGIN
   NULL;
  END;*/

  FUNCTION F_ObterParametro(PSChave STRING) RETURN VARCHAR2 IS
    VSVALOR VARCHAR2(10);
  BEGIN
    FOR i IN TB_PCGMPARAMETRO.FIRST .. TB_PCGMPARAMETRO.LAST LOOP
      IF TB_PCGMPARAMETRO(I).CHAVE = PSCHAVE THEN
        VSVALOR := TB_PCGMPARAMETRO(I).VALOR;
        EXIT;
      END IF;
    END LOOP;
    RETURN VSVALOR;
  END;

  FUNCTION F_RetornarSQLVendasDevol(PN_CODIGOINDICADOR    IN NUMBER,
                                    PS_CODFILIAL          IN VARCHAR2,
                                    PS_BLOCOSQLCONSVENDAS IN VARCHAR2,
                                    PD_DATAINI            IN DATE,
                                    PD_DATAFIM            IN DATE,
                                    PS_AGRUPARPOR         IN VARCHAR2,
                                    PN_CODSUPERVISOR       IN NUMBER,
                                    PN_CODGERENTEREGIONAL IN NUMBER,
                                    PN_CODGERENTENACIONAL IN NUMBER,
                                    PN_CODGERENTE IN NUMBER,
                                    PN_CODUSUR IN NUMBER)
    RETURN VARCHAR2 IS
    VSSQL VARCHAR2(32000) := '';
    VSIMPOSTO1 VARCHAR2(300) := '';
    VSIMPOSTO2 VARCHAR2(300) := '';

  BEGIN

    IF F_ObterParametro('ABATER_VALOR_ST') = 'S' THEN
       VSIMPOSTO1 := VSIMPOSTO1 || '-(CASE WHEN VLST > 0 THEN VLST ELSE 0 END ) + (CASE WHEN VLSTBONIFIC > 0 THEN VLSTBONIFIC ELSE 0 END )';
       VSIMPOSTO2 := VSIMPOSTO2 || '-(CASE WHEN VLST > 0 THEN VLST ELSE 0 END )';
    END IF;

    IF F_ObterParametro('ABATER_VALOR_IPI') = 'S' THEN
       VSIMPOSTO1 := VSIMPOSTO1 || '-(CASE WHEN VLIPI > 0 THEN VLIPI ELSE 0 END ) + (CASE WHEN VLIPIBONIFIC > 0 THEN VLIPIBONIFIC ELSE 0 END )';
       VSIMPOSTO2 := VSIMPOSTO2 || '-(CASE WHEN VLIPI > 0 THEN VLIPI ELSE 0 END )';
    END IF;


    IF PN_CODIGOINDICADOR IN (-1) THEN
      NULL;
      --  VSSQL := PS_REGRAINDICADOR;
      /*      ELSIF PN_CODIGOINDICADOR IN (8, 11) THEN
      VSSQL := ' SELECT NVL(MAX(DISTINCT
                 (SELECT VALOR
                    FROM TABLE(PKG_GESTAOMETA.F_VENDAS('''||PS_CODFILIAL||''',
                                                       '''||PS_REGRAINDICADOR||''',
                                                       NULL,
                                                       NULL,
                                                       NULL,
                                                       '''||REPLACE(PS_BLOCOSQLCONSVENDAS, '''','''''')||''',
                                                       '''||PD_DATAINI||''',
                                                       '''||PD_DATAFIM||''')))), 0)'; */
    ELSE

      VSSQL := ' SELECT DISTINCT REALIZADO.NUMTRANSVENDA,
         0 CODCOMBINACAO ,
        0 CODENTIDADE   ,
        0 CODMETA     ,
        0 CODTIPOMETA  ,
        0 CODINDICADOR  ,
        NULL TABELAENTIDADE,
        REALIZADO.DATA,
        REALIZADO.VLLIQUIDO,
        REALIZADO.VLBONIFIC,
        REALIZADO.CODFILIAL,
        REALIZADO.VOLUMELIQUIDO,
        REALIZADO.LITRAGEMLIQUIDO,
        REALIZADO.CODUSUR,
        REALIZADO.CODSUPERVISOR,
        REALIZADO.CODGERENTE,
        REALIZADO.NUMCAR,
        REALIZADO.CODPROD,
        REALIZADO.CODCLI,
        REALIZADO.CODFORNEC,
        REALIZADO.CODSEC,
        REALIZADO.CODEPTO,
        NVL(REALIZADO.PERCOM, 0) PERCOM,
        REALIZADO.TIPOMOV ,
        REALIZADO.NUMSEQ,';
        VSSQL := VSSQL || '(((REALIZADO.VLLIQUIDO  ' || VSIMPOSTO1 || ') -
                                     ((REALIZADO.VLCUSTOFIN  ' ||VSIMPOSTO2|| ')  + VLCUSTOFINBONIF) +
                                     (REALIZADO.VLCMVDEVOL + VLCMVDEVOLBONIF +
                                     REALIZADO.VLDEVCMVAVULSAI))) VLLUCRO, ';

        VSSQL := VSSQL || 'REALIZADO.PRAZOMEDIO,
        REALIZADO.NUMTRANSENTNFESTORNADA,
        NVL(REALIZADO.VLVENDA, 0) VLVENDA,
        REALIZADO.NUMTRANSENT,
        REALIZADO.VLST,
        REALIZADO.VLIPI,
        REALIZADO.VLFECP,
        REALIZADO.VLSTBONIFIC,
        REALIZADO.VLIPIBONIFIC,
        REALIZADO.CODGERENTEREGIONAL,
        REALIZADO.CODGERENTENACIONAL,
        REALIZADO.PESOLIQUIDO,
        REALIZADO.QTPRODUTO,
        REALIZADO.VLDESCONTO,
        REALIZADO.VLTABELA,
        REALIZADO.VLDEVOLUCAO,
        REALIZADO.CODPRACA
         '; --|| PS_REGRAINDICADOR;
    END IF;

    VSSQL := VSSQL || ' FROM
                        ((SELECT VENDAS.VLVENDA  VLLIQUIDO,
                        VENDAS.VLBONIFIC VLBONIFIC,
                        SAID.CODFILIAL,
                        ROUND(NVL(MOV.QT, 0) * NVL(PROD.VOLUME, 0), 2) VOLUMELIQUIDO,
                        NVL(MOV.QT, 0) * NVL(PROD.LITRAGEM, 0) LITRAGEMLIQUIDO,
                        NVL(MOV.CODUSUR, SAID.CODUSUR) CODUSUR,
                        NVL(VENDAS.CODSUPERVMOV, SAID.CODSUPERVISOR) CODSUPERVISOR,
                        VENDAS.CODGERENTELOCAL CODGERENTE,
                        VENDAS.CODGERENTEREGIONAL,
                        VENDAS.CODGERENTENACIONAL,
                        SAID.NUMCAR,
                        SAID.NUMTRANSVENDA,
                        MOV.CODPROD,
                        MOV.CODCLI,
                        MOV.CODFORNEC,
                        MOV.CODSEC,
                        MOV.CODEPTO,
                        MOV.PERCOM,
                        ''V'' TIPOMOV,
                        MOV.NUMSEQ,
                        MOV.DTMOV DATA,
                        VENDAS.VLVENDA,
                        VENDAS.ICMSRETIDO VLST,
                        VENDAS.ICMSRETIDOBONIFIC VLSTBONIFIC,
                        VENDAS.VLIPI,
                        VENDAS.VLIPIBONIFIC VLIPIBONIFIC,
                        0 VLFECP,
                        VENDAS.VLCUSTOFIN,
                        0 VLCMVDEVOL,
                        0 VLDEVCMVAVULSAI,
                        VENDAS.PRAZOMEDIO,
                        VENDAS.VLCUSTOFINBONIF,
                        0 VLCMVDEVOLBONIF,
                        SAID.NUMTRANSENTNFESTORNADA,
                        NULL NUMTRANSENT,
                        ROUND((NVL(PROD.PESOBRUTO,MOV.PESOBRUTO) * NVL(MOV.QT, 0)),2) PESOLIQUIDO,
                        VENDAS.QT QTPRODUTO,
                        (VENDAS.VLTABELA - VENDAS.vlvenda) * -1 VLDESCONTO,
                        VENDAS.VLTABELA,
                        0 VLDEVOLUCAO,
                        SAID.CODPRACA
                        FROM PCNFSAID SAID,
                         PCMOV MOV,
                         PCPRODUT PROD,
                        (SELECT *
                            FROM VIEW_VENDAS_RESUMO_FATURAMENTO
                           WHERE DTSAIDA >= ''' || PD_DATAINI || '''
                             AND DTSAIDA <= ''' || PD_DATAFIM || '''';

                         IF (NVL(PN_CODGERENTE, 0) <> 0) THEN
                             VSSQL := VSSQL || ' AND CODGERENTELOCAL = ''' || PN_CODGERENTE || '''';
                         ELSIF  (NVL(PN_CODUSUR, 0) <> 0) THEN
                            VSSQL := VSSQL || ' AND CODUSURMOV = ''' || PN_CODUSUR || '''';
                         ELSIF (NVL(PN_CODSUPERVISOR, 0) <> 0) THEN
                            VSSQL := VSSQL || ' AND CODSUPERVMOV = ''' || PN_CODSUPERVISOR || '''';
                         END IF;
                         VSSQL := VSSQL || ' AND CODFILIAL IN(' || PS_CODFILIAL || ')
                                             AND NUMTRANSVENDA IN
                                            ((SELECT DISTINCT NUMTRANSVENDA FROM ' || DEF_PCGMMETAGLOBALTEMP(PS_CODFILIAL) || ' WHERE NVL(TIPOMOV, ''NT'') = ''NT'' AND DATA = TRUNC(SYSDATE) ))) VENDAS';

    VSSQL := VSSQL || CASE WHEN PS_BLOCOSQLCONSVENDAS IS NOT NULL THEN PS_BLOCOSQLCONSVENDAS ELSE ' WHERE 1=1 ' END;
    VSSQL := VSSQL || '

                    AND SAID.NUMTRANSVENDA = MOV.NUMTRANSVENDA
                    AND MOV.CODPROD = PROD.CODPROD
                    AND MOV.NUMTRANSVENDA = VENDAS.NUMTRANSVENDA
                    AND MOV.CODPROD = VENDAS.CODPROD
                    AND MOV.NUMSEQ = VENDAS.NUMSEQ
                    AND SAID.DTSAIDA >= ''' || PD_DATAINI || '''
                    AND SAID.DTSAIDA <= ''' || PD_DATAFIM || '''
                    AND SAID.CODFILIAL IN(' || PS_CODFILIAL || ')
                    AND NVL(VENDAS.CONDVENDA, -1) IN (1, 5, -1, 7, 9, 11, 14)
                    AND VENDAS.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
                    AND SAID.NUMTRANSVENDA IN( SELECT DISTINCT NUMTRANSVENDA FROM ' || DEF_PCGMMETAGLOBALTEMP(PS_CODFILIAL) || ' WHERE NVL(TIPOMOV, ''NT'') = ''NT'' AND DATA = TRUNC(SYSDATE) ))';

    VSSQL := VSSQL || '  UNION ALL

                  (SELECT DEVOL.VLDEVOLUCAO * -1 VLLIQUIDO,
                        DEVOL.VLDEVOLBONIFIC * -1 VLBONIFIC,
                        PCNFENT.CODFILIAL,
                        (NVL(MOV.QT, 0) * NVL(PROD.VOLUME, 0)) * -1 VOLUMELIQUIDO,
                        (NVL(MOV.QT, 0) * NVL(PROD.LITRAGEM, 0)) * -1 LITRAGEMLIQUIDO,
                        NVL(MOV.CODUSUR, SAID.CODUSUR) CODUSUR,
                        NVL(DEVOL.CODSUPERVMOV, SAID.CODSUPERVISOR) CODSUPERVISOR,
                        DEVOL.CODGERENTELOCAL CODGERENTE,
                        DEVOL.CODGERENTEREGIONAL,
                        DEVOL.CODGERENTENACIONAL,
                        SAID.NUMCAR,
                        DEVOL.NUMTRANSVENDA NUMTRANSVENDA,
                        MOV.CODPROD,
                        MOV.CODCLI,
                        MOV.CODFORNEC,
                        MOV.CODSEC,
                        MOV.CODEPTO,
                        MOV.PERCOM,
                        ''DN'' TIPOMOV,
                        DEVOL.NUMSEQ,
                        DEVOL.DTENT DATA,
                        0 VLVENDA,
                        DEVOL.VLST * -1 VLST,
                        DEVOL.ICMSRETIDO_BONIF * -1 VLSTBONIFIC,
                        DEVOL.VLIPI * -1 VLIPI,
                        DEVOL.VLIPI_BONIF * -1 VLIPIBONIFIC,
                        0 VLFECP,
                        0 VLCUSTOFIN,
                        VLCMVDEVOL,
                        0 VLDEVCMVAVULSAI,
                        0 PRAZOMEDIO,
                        0 VLCUSTOFINBONIF,
                        DEVOL.VLCMVDEVOLBONIF,
                        NULL NUMTRANSENTNFESTORNADA,
                        PCNFENT.NUMTRANSENT,
                        ROUND((NVL(PROD.PESOBRUTO,MOV.PESOBRUTO) * NVL(MOV.QT, 0)),2)* -1 PESOLIQUIDO,
                        DEVOL.QT * -1 QTPRODUTO,
                        0 VLDESCONTO,
                        0 VLTABELA,
                        DEVOL.VLDEVOLUCAO VLDEVOLUCAO,
                        SAID.CODPRACA
                   FROM PCNFSAID SAID,
                            PCMOV MOV,
                            PCNFENT,
                            PCESTCOM,
                            PCPRODUT PROD,
                     (SELECT *
                        FROM VIEW_DEVOL_RESUMO_FATURAMENTO
                       WHERE DTENT >= ''' || PD_DATAINI || '''
                         AND DTENT <= ''' || PD_DATAFIM || '''';
                         IF (NVL(PN_CODGERENTE, 0) <> 0) THEN
                             VSSQL := VSSQL || ' AND CODGERENTELOCAL = ''' || PN_CODGERENTE || '''';
                         ELSIF  (NVL(PN_CODUSUR, 0) <> 0) THEN
                            VSSQL := VSSQL || ' AND CODUSURMOV = ''' || PN_CODUSUR || '''';
                         ELSIF (NVL(PN_CODSUPERVISOR, 0) <> 0) THEN
                            VSSQL := VSSQL || ' AND CODSUPERVMOV = ''' || PN_CODSUPERVISOR || '''';
                         END IF;
                         VSSQL := VSSQL || ' AND CODFILIAL IN(' || PS_CODFILIAL || ')
                                             AND NUMTRANSVENDA IN
                             ((SELECT DISTINCT NUMTRANSVENDA FROM ' || DEF_PCGMMETAGLOBALTEMP(PS_CODFILIAL) || ' WHERE NVL(TIPOMOV, ''NT'') = ''NT'' AND DATA = TRUNC(SYSDATE)))) DEVOL';

    VSSQL := VSSQL || CASE WHEN PS_BLOCOSQLCONSVENDAS IS NOT NULL THEN PS_BLOCOSQLCONSVENDAS ELSE ' WHERE 1=1 ' END;

    VSSQL := VSSQL || ' AND SAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
                    AND PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT
                    AND PCNFENT.NUMTRANSENT = MOV.NUMTRANSENT
                    AND MOV.CODPROD = PROD.CODPROD
                    AND MOV.NUMTRANSENT = DEVOL.NUMTRANSENT
                    AND MOV.CODPROD = DEVOL.CODPROD
                    AND MOV.NUMSEQ = DEVOL.NUMSEQ
                    AND DEVOL.QT = NVL((DECODE(MOV.CODOPER,
                                                  ''S'',
                                                  (NVL(DECODE(SAID.CONDVENDA,
                                                              7,
                                                              DECODE(NVL(MOV.TIPOITEM, ''C''),
                                                                     ''C'',
                                                                     MOV.QT,
                                                                     MOV.QTCONT),
                                                              MOV.QT),
                                                       0)),
                                                  ''SM'',
                                                  (NVL(DECODE(SAID.CONDVENDA,
                                                              7,
                                                              DECODE(NVL(MOV.TIPOITEM, ''C''),
                                                                     ''C'',
                                                                     MOV.QT,
                                                                     MOV.QTCONT),
                                                              MOV.QT),
                                                       0)),
                                                  ''ST'',
                                                  (NVL(DECODE(SAID.CONDVENDA,
                                                              7,
                                                              DECODE(NVL(MOV.TIPOITEM, ''C''),
                                                                     ''C'',
                                                                     MOV.QT,
                                                                     MOV.QTCONT),
                                                              MOV.QT),
                                                       0)),
                                                  MOV.QT)),
                                          0)

                    AND PCNFENT.DTENT >= ''' || PD_DATAINI || '''
                    AND PCNFENT.DTENT <= ''' || PD_DATAFIM || '''
                    AND PCNFENT.CODFILIAL IN(' || PS_CODFILIAL || ')
                    AND DEVOL.CONDVENDA NOT IN (4, 8, 10, 13, 20, 98, 99)
                    AND SAID.NUMTRANSVENDA IN(SELECT DISTINCT NUMTRANSVENDA FROM ' || DEF_PCGMMETAGLOBALTEMP(PS_CODFILIAL) || ' WHERE NVL(TIPOMOV, ''NT'') = ''NT'' AND DATA = TRUNC(SYSDATE))';

    VSSQL := VSSQL || '  AND PCNFENT.DTCANCEL IS NULL

       UNION ALL

                SELECT NVL(VLTOTAL,0) * -1 VLLIQUIDO,
                            0 VLBONIFIC,
                            ' || CASE WHEN INSTR(PS_CODFILIAL, ''',''') > 0 THEN '''99''' ELSE PS_CODFILIAL END || ' CODFILIAL,
                            (NVL(MOV.QT, 0) * NVL(PROD.VOLUME, 0)) * -1 VOLUMELIQUIDO,
                            (NVL(MOV.QT, 0) * NVL(PROD.LITRAGEM, 0)) * -1 LITRAGEMLIQUIDO,
                            NVL(AVULSA.CODUSURMOV, AVULSA.CODUSUR) CODUSUR,
                            NVL(AVULSA.CODSUPERVMOV, AVULSA.CODSUPERVISOR) CODSUPERVMOV,
                            AVULSA.CODGERENTELOCAL CODGERENTE,
                            AVULSA.CODGERENTEREGIONAL,
                            AVULSA.CODGERENTENACIONAL,
                            0 NUMCAR,
                            0 NUMTRANSVENDA,
                            AVULSA.CODPROD,
                            AVULSA.CODCLI,
                            AVULSA.CODFORNECMOV CODFORNEC,
                            0 CODSEC,
                            AVULSA.CODEPTO,
                            0 PERCOM,
                            ''DA'' TIPOMOV,
                            AVULSA.NUMSEQ,
                            DTENT DATA,
                            0 VLVENDA,
                            AVULSA.VLST * -1 VLST,
                            0 VLSTBONIFIC,
                            AVULSA.VLIPI * -1 VLIPI,
                            0 VLIPIBONIFIC,
                            0 VLFECP,
                            0 VLCUSTOFIN,
                            0 VLCMVDEVOL,
                            VLDEVCMVAVULSAI,
                            0 PRAZOMEDIO,
                            0 VLCUSTOFINBONIF,
                            0 VLCMVDEVOLBONIF,
                            NULL NUMTRANSENTNFESTORNADA,
                            AVULSA.NUMTRANSENT,
                            ROUND((NVL(PROD.PESOBRUTO,MOV.PESOBRUTO) * NVL(MOV.QT, 0)),2)* -1 PESOLIQUIDO,
                            AVULSA.QT * -1 QTPRODUTO,
                            0 VLDESCONTO,
                            0 VLTABELA,
                            AVULSA.VLTOTAL VLDEVOLUCAO,
                            NULL CODPRACA
                      FROM VIEW_DEVOL_RESUMO_FATURAVULSA AVULSA,
                      PCMOV MOV,
                      PCPRODUT PROD';
    VSSQL := VSSQL || CASE WHEN PS_BLOCOSQLCONSVENDAS IS NOT NULL THEN PS_BLOCOSQLCONSVENDAS ELSE ' WHERE 1=1 ' END;
    VSSQL := VSSQL || ' AND AVULSA.DTENT >= ''' || PD_DATAINI || '''
                             AND AVULSA.DTENT <= ''' ||
             PD_DATAFIM || '''
                             AND AVULSA.CODFILIAL IN(' ||
             PS_CODFILIAL || ')';
    IF (NVL(PN_CODUSUR, 0) <> 0) THEN
      VSSQL := VSSQL || ' AND  AVULSA.CODUSURMOV =  ' || PN_CODUSUR;
    ELSIF (NVL(PN_CODSUPERVISOR, 0) <> 0) THEN
      VSSQL := VSSQL || ' AND AVULSA.CODSUPERVMOV =  ' || PN_CODSUPERVISOR;

    ELSIF (NVL(PN_CODGERENTE, 0) <> 0) THEN
      VSSQL := VSSQL || ' AND AVULSA.CODGERENTELOCAL  =  ' || PN_CODGERENTE;

    ELSIF (NVL(PN_CODGERENTEREGIONAL, 0) <> 0) THEN
      VSSQL := VSSQL || ' AND AVULSA.CODGERENTEREGIONAL  =  ' || PN_CODGERENTEREGIONAL;

    ELSIF (NVL(PN_CODGERENTENACIONAL, 0) <> 0) THEN
      VSSQL := VSSQL || ' AND AVULSA.CODGERENTENACIONAL  =  ' || PN_CODGERENTENACIONAL;

    END IF;


    VSSQL := VSSQL ||
             '   AND MOV.NUMTRANSENT = AVULSA.NUMTRANSENT
                        AND MOV.CODPROD = AVULSA.CODPROD
                        AND MOV.NUMSEQ = AVULSA.NUMSEQ
                        AND PROD.CODPROD = MOV.CODPROD
                        AND PROD.CODPROD = AVULSA.CODPROD )) REALIZADO';

    IF /*PNCODIGOINDICADOR = 21 THEN
                  VSSQL := VSSQL || ')';
                  VSSQL := VSSQL || 'GROUP BY PCNFSAID.NUMCAR';
                ELSIF */
     PS_AGRUPARPOR IS NOT NULL THEN
      VSSQL := VSSQL || PS_AGRUPARPOR;
    END IF;
/*
      DECLARE
      arquivo_saida UTL_File.File_Type;
      Cursor Cur_Linha is
        select to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss "seculo" CC') DATA
          from dual;
    BEGIN
      arquivo_saida := UTL_File.Fopen('TEMP_DIR', 'teste.txt', 'W');
      --    For Reg_Linha in Cur_linha Loop
      UTL_File.Put_Line(arquivo_saida, VSSQL);
      --    End Loop;
      UTL_File.Fclose(arquivo_saida);
      Dbms_Output.Put_Line('Arquivo gerado com sucesso.');
    EXCEPTION
      WHEN Others THEN
        Dbms_Output.Put_Line('Problemas na geração do arquivo.');
        UTL_File.Fclose(arquivo_saida);
    END;
*/
    RETURN VSSQL;
  END;

  PROCEDURE P_EncontrarDadosPerfil(PNCODMETA         IN NUMBER,
                                   PNCODENTIDADEMETA OUT NUMBER,
                                   PSTIPOIDENTIDADE  OUT VARCHAR2) IS
    VNCODENTIDADEMETA NUMBER;
    VSTIPOIDENTIDADE  VARCHAR2(2);
  BEGIN
    BEGIN
      SELECT PCGMMETA.CODENTIDADEMETA, PCGMPERFIL.TIPOIDENTIDADE
        INTO VNCODENTIDADEMETA, VSTIPOIDENTIDADE
        FROM PCGMMETA, PCGMPARAMMETA, PCGMPERFIL
       WHERE PCGMMETA.CODPARAMMETA = PCGMPARAMMETA.CODIGO
         AND PCGMPARAMMETA.CODPERFIL = PCGMPERFIL.CODIGO
         AND PCGMMETA.CODIGO = PNCODMETA;
    EXCEPTION
      WHEN OTHERS THEN
        VNCODENTIDADEMETA := 0;
        VSTIPOIDENTIDADE  := '';
    END;

    PNCODENTIDADEMETA := VNCODENTIDADEMETA;
    PSTIPOIDENTIDADE  := VSTIPOIDENTIDADE;
  END;

  FUNCTION F_EncontrarPercom(PT_PCGMMETATEMP IN PCGMMETAGLOBALTEMP%ROWTYPE DEFAULT NULL)
    RETURN NUMBER IS
    vnpercom          number;
    vn_codcomissao    NUMBER;
    vn_rotinacomissao VARCHAR2(20);
    vn_LetraComiss    VARCHAR(2);
    vn_mensagem       VARCHAR2(1000);
    vnNumTransEnt     NUMBER;
  begin

    BEGIN
      vnNumTransEnt := CASE WHEN PT_PCGMMETATEMP.NUMTRANSENTNFESTORNADA IS NOT NULL THEN PT_PCGMMETATEMP.NUMTRANSENTNFESTORNADA ELSE PT_PCGMMETATEMP.NUMTRANSENT END;
      vnpercom      := FUNCOESVENDAS.Definir_Comissao_Item_Vendido(P_NUMTRANSENT => vnNumTransEnt,
                                                                   P_CODPROD     => PT_PCGMMETATEMP.CODPROD,
                                                                   P_NUMSEQ      => PT_PCGMMETATEMP.NUMSEQ,

                                                                   P_CODCOMISSAO    => vn_codcomissao,
                                                                   P_ROTINACOMISSAO => vn_rotinacomissao,
                                                                   P_LETRACOMISS    => vn_LetraComiss,
                                                                   P_MENSAGEM       => vn_mensagem);

    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line(SQLCODE || ' ' || SQLERRM || ' ' ||
                             vn_mensagem);
    END;
    RETURN vnpercom;
  END;

  PROCEDURE P_EncontarEGravarTransacao(PSFILIAL         IN VARCHAR2,
                                       PSREGRAINDICADOR IN VARCHAR2,
                                       PNCODGERENTE     IN NUMBER DEFAULT NULL,
                                       PNCODGERENTEREGIONAL IN NUMBER DEFAULT NULL,
                                       PNCODGERENTENACIONAL IN NUMBER DEFAULT NULL,
                                       PNCODSUPERVISOR  IN NUMBER DEFAULT NULL,
                                       PNCODUSUR        IN NUMBER DEFAULT NULL,
                                       PDDATAINI        IN DATE,
                                       PDDATAFIM        IN DATE,
                                       PNCODMETA        IN NUMBER DEFAULT NULL) IS
    VSSQL VARCHAR2(32000) := '';
    --VNVALORINDICADOR NUMBER;
    MSG               VARCHAR2(2000) := '';
    VNCODENTIDADEMETA NUMBER;
    VSTIPOIDENTIDADE  VARCHAR2(2);
    P_CODGERENTE      VARCHAR2(20);
    P_CODGERENTEREGIONAL VARCHAR2(20);
    P_CODGERENTENACIONAL VARCHAR2(20);
    P_CODSUPERVISOR   VARCHAR2(20);
    P_CODRCA          VARCHAR2(20);
    VT_PCGMMETATEMP   TB_PCGMMETATEMP := TB_PCGMMETATEMP(NULL);
    TYPE RECEBENUMTRANSVENDA IS TABLE OF NUMBER(20) index by binary_integer;
    LISTANUMTRANSVENDA RECEBENUMTRANSVENDA;

    PROCEDURE PREENCHERTRANSACAOTEMP(TIPOMOV VARCHAR2) IS
    BEGIN
      VT_PCGMMETATEMP.EXTEND(LISTANUMTRANSVENDA.COUNT);
      FOR INDX IN 1 .. LISTANUMTRANSVENDA.COUNT LOOP
        IF TIPOMOV = 'DA' THEN
          VT_PCGMMETATEMP(INDX).NUMTRANSVENDA := -10;
        ELSE
          VT_PCGMMETATEMP(INDX).NUMTRANSVENDA := LISTANUMTRANSVENDA(INDX);
        END IF;
        VT_PCGMMETATEMP(INDX).CODMETA := PNCODMETA;
        VT_PCGMMETATEMP(INDX).DATA := TRUNC(SYSDATE);
        VT_PCGMMETATEMP(INDX).TIPOMOV := 'NT';
      END LOOP;

      P_InserirMetaTemp('N', PSFILIAL, NULL, VT_PCGMMETATEMP);
    END;
  BEGIN
    P_CODRCA        := PNCODUSUR;
    P_CODSUPERVISOR := PNCODSUPERVISOR;
    P_CODGERENTE    := PNCODGERENTE;
    P_CODGERENTEREGIONAL     := PNCODGERENTEREGIONAL;
    P_CODGERENTENACIONAL     := PNCODGERENTENACIONAL;


    P_EncontrarDadosPerfil(PNCODMETA, VNCODENTIDADEMETA, VSTIPOIDENTIDADE);

    IF P_CODGERENTEREGIONAL IS NULL THEN
      P_CODGERENTEREGIONAL := CASE VSTIPOIDENTIDADE WHEN 'R' THEN VNCODENTIDADEMETA ELSE NULL END;
    END IF;

    IF P_CODGERENTENACIONAL IS NULL THEN
      P_CODGERENTENACIONAL := CASE VSTIPOIDENTIDADE WHEN 'N' THEN VNCODENTIDADEMETA ELSE NULL END;
    END IF;
    IF P_CODGERENTE IS NULL THEN
      P_CODGERENTE := CASE VSTIPOIDENTIDADE WHEN 'L' THEN VNCODENTIDADEMETA ELSE NULL END;
    END IF;

    IF P_CODSUPERVISOR IS NULL THEN
      P_CODSUPERVISOR := CASE VSTIPOIDENTIDADE WHEN 'S' THEN VNCODENTIDADEMETA ELSE NULL END;
    END IF;

    IF P_CODRCA IS NULL THEN
      P_CODRCA := CASE VSTIPOIDENTIDADE WHEN 'U' THEN VNCODENTIDADEMETA ELSE NULL END;
    END IF;

    /*    VSSQL := 'SELECT  0, ''0'', ' || PSREGRAINDICADOR ||
    ', ''0'',''0'', 0, 0,0,0, 0,0*/
    VSSQL := 'SELECT ' || PSREGRAINDICADOR || '
                FROM (SELECT DISTINCT NUMTRANSVENDA
                        FROM VIEW_VENDAS_RESUMO_FATURAMENTO VENDAS
                       WHERE 1=1';
    IF NVL(PSFILIAL, '99') <> '99' THEN
      VSSQL := VSSQL || '     AND VENDAS.CODFILIAL IN(' || PSFILIAL || ')';
    END IF;
    VSSQL := VSSQL || '    AND VENDAS.DTSAIDA >= ''' || PDDATAINI || '''
                         AND VENDAS.DTSAIDA <= ''' || PDDATAFIM || '''';
    IF P_CODRCA IS NOT NULL THEN
      VSSQL := VSSQL || '     AND VENDAS.CODUSURMOV = ' || P_CODRCA;
    ELSIF P_CODSUPERVISOR IS NOT NULL THEN
      VSSQL := VSSQL || '     AND VENDAS.CODSUPERVMOV = ' ||
               P_CODSUPERVISOR;

    END IF;

    VSSQL := VSSQL || '            UNION ALL
                      SELECT DISTINCT NUMTRANSVENDA
                        FROM VIEW_DEVOL_RESUMO_FATURAMENTO DEVOL
                       WHERE 1=1';
    IF NVL(PSFILIAL, '99') <> '99' THEN
      VSSQL := VSSQL || '    AND DEVOL.CODFILIAL IN(' || PSFILIAL || ')';
    END IF;
    VSSQL := VSSQL || '    AND DEVOL.DTENT >= ''' || PDDATAINI || '''
                         AND DEVOL.DTENT <= ''' || PDDATAFIM || '''';
    IF P_CODRCA IS NOT NULL THEN
      VSSQL := VSSQL || '     AND DEVOL.CODUSURMOV = ' || P_CODRCA;
    ELSIF P_CODSUPERVISOR IS NOT NULL THEN
      VSSQL := VSSQL || '     AND DEVOL.CODSUPERVMOV = ' || P_CODSUPERVISOR;

    END IF;

    VSSQL := VSSQL || '        )';

    /*DECLARE
        arquivo_saida UTL_File.File_Type;
        Cursor Cur_Linha is
          select to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss "seculo" CC') DATA
            from dual;
      BEGIN
        arquivo_saida := UTL_File.Fopen('TEMP_DIR', 'teste.txt', 'W');
        --    For Reg_Linha in Cur_linha Loop
        UTL_File.Put_Line(arquivo_saida, VSSQL);
        --    End Loop;
        UTL_File.Fclose(arquivo_saida);
        Dbms_Output.Put_Line('Arquivo gerado com sucesso.');
      EXCEPTION
        WHEN Others THEN
          Dbms_Output.Put_Line('Problemas na geração do arquivo.');
          UTL_File.Fclose(arquivo_saida);
      END;
    */
    BEGIN
      EXECUTE IMMEDIATE VSSQL BULK COLLECT
        INTO LISTANUMTRANSVENDA;
      PREENCHERTRANSACAOTEMP('');

      VSSQL := '   SELECT DISTINCT NUMTRANSENT
                        FROM VIEW_DEVOL_RESUMO_FATURAVULSA AVULSA
                       WHERE 1=1';
      IF NVL(PSFILIAL, '99') <> '99' THEN
        VSSQL := VSSQL || '    AND AVULSA.CODFILIAL IN(' || PSFILIAL || ')';
      END IF;
      VSSQL := VSSQL || '    AND AVULSA.DTENT >= ''' || PDDATAINI || '''
                           AND AVULSA.DTENT <= ''' ||
               PDDATAFIM || '''';
      IF P_CODRCA IS NOT NULL THEN
        VSSQL := VSSQL || '     AND AVULSA.CODUSURMOV = ' || P_CODRCA;
      ELSIF P_CODSUPERVISOR IS NOT NULL THEN
        VSSQL := VSSQL || '     AND AVULSA.CODSUPERVISOR = ' ||
                 P_CODSUPERVISOR;


      END IF;

      EXECUTE IMMEDIATE VSSQL BULK COLLECT
        INTO LISTANUMTRANSVENDA;
      PREENCHERTRANSACAOTEMP('DA');
    EXCEPTION
      WHEN OTHERS THEN
        MSG := pSREGRAINDICADOR || DBMS_UTILITY.FORMAT_ERROR_STACK || ' - ' ||
               LISTANUMTRANSVENDA.COUNT;
        dbms_output.put_line(msg);
        --DADOSVENDA := NULL;
    END;
  END;

  PROCEDURE P_GravarEntidadeMetaTemp(PNCODMETA      IN NUMBER,
                                     PNCODTIPOMETA  IN NUMBER,
                                     PNCODINDICADOR IN NUMBER,
                                     PDDATAINI      IN DATE,
                                     PDDATAFIM      IN DATE,
                                     PSCODFILIAL    IN VARCHAR2) IS

    PT_PCGMMETATEMP PCGMMETAGLOBALTEMP%ROWTYPE;
  BEGIN
    BEGIN

      FOR DADOSMETACOMB IN (SELECT PCGMMETACOMB.CODCOMBINACAO,
                                   REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.ITEM),
                                                                  10000,
                                                                  1) CODENTIDADE
                                             FROM PCGMCOMBITEM
                                            WHERE PCGMCOMBITEM.CODIGO =
                                                  PCGMMETACOMB.CODCOMBINACAO
                                            GROUP BY PCGMCOMBITEM.CODIGO),
                                           ',',
                                           ';') CODENTIDADE,
                                   REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.FILTRO),
                                                                  10000,
                                                                  1) TIPOENTIDADE
                                             FROM PCGMCOMBITEM
                                            WHERE PCGMCOMBITEM.CODIGO =
                                                  PCGMMETACOMB.CODCOMBINACAO
                                            GROUP BY PCGMCOMBITEM.CODIGO),
                                           ',',
                                           ';') TIPOENTIDADE
                              FROM PCGMMETACOMB
                             WHERE PCGMMETACOMB.CODMETA = PNCODMETA
                               AND PCGMMETACOMB.CODTIPOMETA = PNCODTIPOMETA
                               AND PCGMMETACOMB.CODINDICADOR =
                                   PNCODINDICADOR
                               AND PCGMMETACOMB.DATA >= PDDATAINI
                               AND PCGMMETACOMB.DATA <= PDDATAFIM) LOOP

        FOR DADOS IN (SELECT REGEXP_SUBSTR(DADOSMETACOMB.CODENTIDADE,
                                           '[^;]+',
                                           1,
                                           LEVEL) CODENTIDADE,
                             REGEXP_SUBSTR(DADOSMETACOMB.TIPOENTIDADE,
                                           '[^;]+',
                                           1,
                                           LEVEL) TIPOENTIDADE
                        FROM DUAL
                      CONNECT BY REGEXP_SUBSTR(DADOSMETACOMB.CODENTIDADE,
                                               '[^;]+',
                                               1,
                                               LEVEL) IS NOT NULL) LOOP

          PT_PCGMMETATEMP.CODCOMBINACAO  := DADOSMETACOMB.CODCOMBINACAO;
          PT_PCGMMETATEMP.CODMETA        := PNCODMETA;
          PT_PCGMMETATEMP.CODTIPOMETA    := PNCODTIPOMETA;
          PT_PCGMMETATEMP.CODINDICADOR   := PNCODINDICADOR;
          PT_PCGMMETATEMP.CODENTIDADE    := DADOS.CODENTIDADE;
          PT_PCGMMETATEMP.TABELAENTIDADE := DADOS.TIPOENTIDADE;

          P_InserirMetaTemp('S', PSCODFILIAL, PT_PCGMMETATEMP, NULL);
        END LOOP;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

  END;

  PROCEDURE P_GravarEntidadeMetaTemp(PNPARAMMETA       IN NUMBER,
                                     PNCODTIPOMETA     IN NUMBER,
                                     PNCODENTIDADEMETA IN NUMBER,
                                     PSCODFILIAL       IN VARCHAR2) IS

    PT_PCGMMETATEMP PCGMMETAGLOBALTEMP%ROWTYPE;
  BEGIN
    BEGIN

      FOR DADOSMETACOMB IN (SELECT P.CODIGO
                          FROM PCGMCONFIGHISTORICOPARAM P
                         WHERE P.CODPARAMMETA = PNPARAMMETA
                           AND P.CODTIPOMETA = PNCODTIPOMETA
                           AND P.CODENTIDADEMETA = PNCODENTIDADEMETA) LOOP

        FOR DADOS IN (SELECT FILTRO TIPOENTIDADE, ITEM CODENTIDADE
                        FROM PCGMDADOSHISTORICOITEM
                       WHERE CODIGO = DADOSMETACOMB.CODIGO
                       ORDER BY FILTRO) LOOP

          PT_PCGMMETATEMP.CODCOMBINACAO  := DADOSMETACOMB.CODIGO;
          PT_PCGMMETATEMP.CODMETA        := 0;
          PT_PCGMMETATEMP.CODTIPOMETA    := PNCODTIPOMETA;
          PT_PCGMMETATEMP.CODENTIDADE    := DADOS.CODENTIDADE;
          PT_PCGMMETATEMP.TABELAENTIDADE := DADOS.TIPOENTIDADE;

          P_InserirMetaTemp('S', PSCODFILIAL, PT_PCGMMETATEMP, NULL);
        END LOOP;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

  END;

  FUNCTION F_RetornarEntidadeDinamico(PNCODENTIDADEMETA IN NUMBER DEFAULT 0,
                                      PSTIPOENTIDADE      VARCHAR2,
                                      PSCODFILIAL         VARCHAR2)
    RETURN VARCHAR2 IS
    --DADOS_SAIDA             TR_DADOSMETATEMP;
    VDDATAINI               DATE;
    VDDATAFIM               DATE;
    VSBLOCOSQLCALCREALIZADO VARCHAR2(32000);
    VSBLOCOSQL              VARCHAR2(15000) := '';
  BEGIN


      IF PSTIPOENTIDADE = 'CLI' THEN

        VSBLOCOSQL := VSBLOCOSQL ||
                      ' AND MOV.CODCLI IN((SELECT CODENTIDADE
                                                FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || '
                                               WHERE CODENTIDADE = DECODE(' ||
                      PNCODENTIDADEMETA || ', 0, CODENTIDADE, ' ||
                      PNCODENTIDADEMETA || ')
                                                 AND TABELAENTIDADE = ''' ||
                      PSTIPOENTIDADE|| '''
                                                 AND NVL(CODPROD, 0) = 0) )';

      ELSIF PSTIPOENTIDADE = 'CAT' THEN

        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ', PCCATEGORIA WHERE 1=1 AND MOV.CODPROD  = PROD.CODPROD
                                   AND PROD.CODCATEGORIA  = PCCATEGORIA.CODCATEGORIA
                                   AND (PCCATEGORIA.CODSEC , PCCATEGORIA.CODCATEGORIA) IN( SELECT SUBSTR(CODENTIDADE, 1, INSTR(CODENTIDADE, ''-'') - 1) A,
                                                                                                  REPLACE(CODENTIDADE, SUBSTR(CODENTIDADE, 1, INSTR(CODENTIDADE, ''-'')), '''') B
                                                                                        FROM (SELECT *
                                                                                                FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                                                      ' ||
                      PNCODTIPOMETA || ',
                                                                                                                                      ' ||
                      PNCODINDICADOR || ',
                                                                                                                                      ''' ||
                      VDDATAINI || ''',
                                                                                                                                      ''' ||
                      VDDATAFIM ||
                      '''))) T

                                                                                        WHERE T.TABELAENTIDADE = ''' ||
                      PSTIPOENTIDADE || ''' )';*/

      ELSIF PSTIPOENTIDADE = 'DEP' THEN
        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ' AND MOV.CODEPTO IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )';
*/
      ELSIF PSTIPOENTIDADE = 'FOR' THEN


        VSBLOCOSQL := VSBLOCOSQL ||
                     -- ' , PCFORNEC WHERE 1=1';
                       '     AND MOV.CODFORNEC = PCFORNEC.CODFORNEC
                            AND MOV.CODFORNEC IN((SELECT CODENTIDADE
                                                          FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || '
                                                         WHERE CODENTIDADE = DECODE(' ||
                      PNCODENTIDADEMETA || ', 0, CODENTIDADE, ' ||
                      PNCODENTIDADEMETA || ')
                                                           AND TABELAENTIDADE = ''' ||
                      PSTIPOENTIDADE || '''
                                                           AND NVL(CODPROD, 0) = 0) )';

      ELSIF PSTIPOENTIDADE = 'FORPRI' THEN

        VSBLOCOSQL := VSBLOCOSQL ||
                      '   AND EXISTS
                                  (SELECT 1 FROM PCFORNEC
                                          WHERE MOV.CODFORNEC = PCFORNEC.CODFORNEC
                                            AND PCFORNEC.CODFORNECPRINC IN
                                                ((SELECT CODENTIDADE
                                                    FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || '
                                                   WHERE CODENTIDADE =
                                                   DECODE(' || PNCODENTIDADEMETA || ', 0, CODENTIDADE, ' || PNCODENTIDADEMETA || ')
                                                           AND TABELAENTIDADE = ''' || PSTIPOENTIDADE || '''
                                                           AND NVL(CODPROD, 0) = 0) ))';



      ELSIF PSTIPOENTIDADE = 'PRA' THEN

        VSBLOCOSQL := VSBLOCOSQL ||
                   ' , PCPRACA, PCCLIENT WHERE 1=1
                       AND MOV.CODCLI = PCCLIENT.CODCLI
                       AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA
                       AND PCPRACA.CODPRACA IN((SELECT CODENTIDADE
                                                          FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || '
                                                         WHERE CODENTIDADE = DECODE(' ||
                   PNCODENTIDADEMETA || ', 0, CODENTIDADE, ' ||
                   PNCODENTIDADEMETA || ')
                                                        AND TABELAENTIDADE = ''' ||
                   PSTIPOENTIDADE || '''
                                                        AND NVL(CODPROD, 0) = 0) )';
      ELSIF PSTIPOENTIDADE = 'LIPRO' THEN
        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ' , PCLINHAPROD WHERE 1=1 AND MOV.CODPROD  = PROD.CODPROD
                                     AND PROD.CODLINHAPROD  = PCLINHAPROD.CODLINHA
                                     AND PCLINHAPROD.CODLINHA IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )';*/

      ELSIF PSTIPOENTIDADE = 'MAR' THEN
        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ' , PCMARCA  WHERE 1=1 AND MOV.CODPROD  = PROD.CODPROD
                            AND PROD.CODMARCA  = PCMARCA.CODMARCA  AND PCMARCA.CODMARCA IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )';*/

      ELSIF PSTIPOENTIDADE = 'PRO' THEN
        /*        VSBLOCOSQL := VSBLOCOSQL ||
        ' AND MOV.CODPROD IN( SELECT CODENTIDADE
                                            FROM (SELECT *
                                                    FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' || PNCODMETA || ',
                                                                                          ' || PNCODTIPOMETA || ',
                                                                                          ' || PNCODINDICADOR || ',
                                                                                          ''' || VDDATAINI || ''',
                                                                                          ''' || VDDATAFIM || '''))) T
                                            WHERE T.TABELAENTIDADE = ''' || DADOS.TIPOENTIDADE || ''' )';*/
        VSBLOCOSQL := VSBLOCOSQL ||
                      ' AND MOV.CODPROD IN((SELECT CODENTIDADE
                                              FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || '
                                             WHERE CODENTIDADE = DECODE(' ||
                      PNCODENTIDADEMETA || ', 0, CODENTIDADE, ' ||
                      PNCODENTIDADEMETA || ')
                                               AND TABELAENTIDADE = ''' ||
                      PSTIPOENTIDADE || '''
                                               AND NVL(CODPROD, 0) = 0) )';
      ELSIF PSTIPOENTIDADE = 'RAATIV' THEN
        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ' , PCATIVI, PCCLIENT WHERE 1=1  AND MOV.CODCLI  = PCCLIENT.CODCLI
                                     AND PCCLIENT.CODATV1  = PCATIVI.CODATIV
                                     AND PCATIVI.CODATIV IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )';*/
      ELSIF PSTIPOENTIDADE = 'SEC' THEN
        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ' AND MOV.CODSEC  IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )';*/

      ELSIF PSTIPOENTIDADE = 'SUBCAT' THEN
        VSBLOCOSQL := ''; /*VSBLOCOSQL ||
                      ', PCSUBCATEGORIA WHERE 1=1 AND MOV.CODPROD  = PROD.CODPROD
                                       AND PROD.CODSUBCATEGORIA  = PCSUBCATEGORIA.CODSUBCATEGORIA
                                       AND (PCSUBCATEGORIA.CODSEC, PCSUBCATEGORIA.CODCATEGORIA, PCSUBCATEGORIA.CODSUBCATEGORIA)IN(
                                                              SELECT SUBSTR(CODENTIDADE, 0, INSTR(CODENTIDADE, ''-'') -1) A,
                                                                     REPLACE(CODENTIDADE, SUBSTR(CODENTIDADE, 1, INSTR(CODENTIDADE, ''-'', -1)),'''') B,
                                                                     SUBSTR(CODENTIDADE, INSTR(CODENTIDADE, ''-'') + 1, (INSTR(CODENTIDADE, ''-'', -1)) - (INSTR(CODENTIDADE, ''-'') + 1)) C
                                                                FROM (SELECT *
                                                                       FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                                 ' ||
                      PNCODTIPOMETA || ',
                                                                                                                 ' ||
                      PNCODINDICADOR || ',
                                                                                                               ''' ||
                      VDDATAINI || ''',
                                                                                                               ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                                       WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )';
*/
      ELSIF PSTIPOENTIDADE = 'GRUCLI' THEN
        VSBLOCOSQL := '';/*VSBLOCOSQL ||
                      ', PCCLIENT  WHERE 1=1 AND MOV.CODCLI  = PCCLIENT.CODCLI
                                   AND PCCLIENT.CODCLI IN(SELECT I.CODITEM FROM PCGRUPOSCAMPANHAC S, PCGRUPOSCAMPANHAI I
                                                        WHERE S.CODGRUPO = I.CODGRUPO AND S.TIPO = ''CL'' AND I.CODGRUPO  IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' ))';*/
      ELSIF PSTIPOENTIDADE = 'GRUPRO' THEN
        VSBLOCOSQL := ''; /*VSBLOCOSQL ||
                      ' WHERE 1=1 AND MOV.CODPROD  = PROD.CODPROD
                                   AND PROD.CODPROD IN(SELECT I.CODITEM FROM PCGRUPOSCAMPANHAC S, PCGRUPOSCAMPANHAI I
                                                                  WHERE S.CODGRUPO = I.CODGRUPO
                                                                 AND S.TIPO = ''GP'' AND I.CODITEM IN(SELECT I.CODITEM FROM PCGRUPOSCAMPANHAC S, PCGRUPOSCAMPANHAI I
                                                        WHERE S.CODGRUPO = I.CODGRUPO AND S.TIPO = ''GP'' AND I.CODGRUPO  IN( SELECT CODENTIDADE
                                                          FROM (SELECT *
                                                                  FROM TABLE(PKG_GESTAOMETA.F_DADOSMETATEMP(' ||
                      PNCODMETA || ',
                                                                                                        ' ||
                      PNCODTIPOMETA || ',
                                                                                                        ' ||
                      PNCODINDICADOR || ',
                                                                                                        ''' ||
                      VDDATAINI || ''',
                                                                                                        ''' ||
                      VDDATAFIM ||
                      '''))) T
                                                          WHERE T.TABELAENTIDADE = ''' ||
                      DADOS.TIPOENTIDADE || ''' )))';*/
      END IF;

    RETURN VSBLOCOSQL;
  END;

FUNCTION F_RetornarSQLEntidadeIN(PNCODMETA         IN NUMBER,
                                 PNCODTIPOMETA     IN NUMBER,
                                 PNCODINDICADOR    IN NUMBER,
                                 PNCODENTIDADEMETA IN NUMBER DEFAULT 0,
                                 PDDATAINI         IN DATE,
                                 PDDATAFIM         IN DATE,
                                 PSCODFILIAL       IN VARCHAR2) RETURN VARCHAR2 IS
  --DADOS_SAIDA             TR_DADOSMETATEMP;
  VDDATAINI               DATE;
  VDDATAFIM               DATE;
  VSBLOCOSQLCALCREALIZADO VARCHAR2(32000);
  VSBLOCOSQL              VARCHAR2(15000) := '';
  
BEGIN

  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/RRRR''';
  VDDATAINI := TO_DATE(PDDATAINI, 'DD/MM/RRRR');
  VDDATAFIM := TO_DATE(PDDATAFIM, 'DD/MM/RRRR');

  P_GravarEntidadeMetaTemp(PNCODMETA,
                           PNCODTIPOMETA,
                           PNCODINDICADOR,
                           VDDATAINI,
                           VDDATAFIM,
                           PSCODFILIAL);

  FOR DADOS in (SELECT DISTINCT PCGMCOMBITEM.FILTRO TIPOENTIDADE
                  FROM PCGMMETACOMB, PCGMCOMBITEM
                 WHERE PCGMMETACOMB.CODCOMBINACAO = PCGMCOMBITEM.CODIGO
                   AND PCGMMETACOMB.CODMETA = PNCODMETA
                   AND PCGMMETACOMB.CODTIPOMETA = PNCODTIPOMETA
                   AND PCGMMETACOMB.CODINDICADOR = PNCODINDICADOR
                   AND PCGMMETACOMB.CODTIPOMETA <> 1 -- TIPO DE META GERAL
                   AND PCGMMETACOMB.DATA >= VDDATAINI
                   AND PCGMMETACOMB.DATA <= VDDATAFIM) loop

    VSBLOCOSQL := VSBLOCOSQL || F_RetornarEntidadeDinamico(PNCODENTIDADEMETA,
                                             DADOS.TIPOENTIDADE,
                                             PSCODFILIAL);
  end loop;

  IF VSBLOCOSQL NOT LIKE '%WHERE 1=1%' THEN
    VSBLOCOSQL := ' WHERE 1=1 ' || VSBLOCOSQL;
  END IF;

  VSBLOCOSQLCALCREALIZADO := VSBLOCOSQL;
  --  DBMS_OUTPUT.put_line('VSBLOCOSQL : ' || VSBLOCOSQL);

  RETURN VSBLOCOSQLCALCREALIZADO;
END;

  FUNCTION F_RetornarSQLEntidadeIN(PNPARAMMETA       IN NUMBER,
                                   PNCODTIPOMETA     IN NUMBER,
                                   PNCODENTIDADEMETA IN NUMBER DEFAULT 0,
                                   PSCODFILIAL       IN VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2 IS
    --DADOS_SAIDA             TR_DADOSMETATEMP;
    VDDATAINI               DATE;
    VDDATAFIM               DATE;
    VSBLOCOSQLCALCREALIZADO VARCHAR2(32000);
    VSBLOCOSQL              VARCHAR2(15000) := '';
    VSCODFILIAL             PCFILIAL.CODIGO%TYPE;    
  BEGIN
  
    IF (PSCODFILIAL IS NULL) THEN    
      SELECT PCGMPARAMMETA.CODFILIAL
        INTO VSCODFILIAL
        FROM PCGMPARAMMETA
           , PCGMMETA
       WHERE 1 = 1
         AND PCGMMETA.CODPARAMMETA = PCGMPARAMMETA.CODIGO
         AND PCGMMETA.CODIGO = PNPARAMMETA;
    ELSE
      VSCODFILIAL := PSCODFILIAL; 
    END IF;

    P_GravarEntidadeMetaTemp(PNPARAMMETA,
                             PNCODTIPOMETA,
                             PNCODENTIDADEMETA,
                             PSCODFILIAL);

    FOR DADOS IN (SELECT DISTINCT FILTRO TIPOENTIDADE
                    FROM PCGMDADOSHISTORICOITEM
                   WHERE CODIGO IN
                         (SELECT P.CODIGO
                            FROM PCGMCONFIGHISTORICOPARAM P
                           WHERE P.CODPARAMMETA = PNPARAMMETA
                             AND P.CODTIPOMETA = PNCODTIPOMETA
                             AND P.CODENTIDADEMETA = PNCODENTIDADEMETA)) LOOP
      VSBLOCOSQL := VSBLOCOSQL || F_RetornarEntidadeDinamico(0, DADOS.TIPOENTIDADE, VSCODFILIAL);
    end loop;

    IF VSBLOCOSQL NOT LIKE '%WHERE 1=1%' THEN
      VSBLOCOSQL := ' WHERE 1=1 ' || VSBLOCOSQL;
    END IF;

    VSBLOCOSQLCALCREALIZADO := VSBLOCOSQL;
    --  DBMS_OUTPUT.put_line('VSBLOCOSQL : ' || VSBLOCOSQL);

    RETURN VSBLOCOSQLCALCREALIZADO;
  END;


  /*FUNCTION F_DADOSMETATEMP(PNCODMETA      IN NUMBER,
                           PNCODTIPOMETA  IN NUMBER,
                           PNCODINDICADOR IN NUMBER,
                           PDDATAINI      IN DATE,
                           PDDATAFIM      IN DATE) RETURN TB_DADOSMETATEMP
    PIPELINED IS
    DADOS_SAIDA TR_DADOSMETATEMP;

    PT_PCGMMETATEMP PCGMMETAGLOBALTEMP%ROWTYPE;
  BEGIN
    BEGIN

      FOR DADOSMETACOMB IN (SELECT PCGMMETACOMB.CODCOMBINACAO,
                                   REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.ITEM),
                                                                  10000,
                                                                  1) CODENTIDADE
                                             FROM PCGMCOMBITEM
                                            WHERE PCGMCOMBITEM.CODIGO =
                                                  PCGMMETACOMB.CODCOMBINACAO
                                            GROUP BY PCGMCOMBITEM.CODIGO),
                                           ',',
                                           ';') CODENTIDADE,
                                   REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.FILTRO),
                                                                  10000,
                                                                  1) TIPOENTIDADE
                                             FROM PCGMCOMBITEM
                                            WHERE PCGMCOMBITEM.CODIGO =
                                                  PCGMMETACOMB.CODCOMBINACAO
                                            GROUP BY PCGMCOMBITEM.CODIGO),
                                           ',',
                                           ';') TIPOENTIDADE
                              FROM PCGMMETACOMB
                             WHERE PCGMMETACOMB.CODMETA = PNCODMETA
                               AND PCGMMETACOMB.CODTIPOMETA = PNCODTIPOMETA
                               AND PCGMMETACOMB.CODINDICADOR =
                                   PNCODINDICADOR
                               AND PCGMMETACOMB.DATA >= PDDATAINI
                               AND PCGMMETACOMB.DATA <= PDDATAFIM) LOOP

        FOR DADOS IN (SELECT REGEXP_SUBSTR(DADOSMETACOMB.CODENTIDADE, '[^;]+', 1, LEVEL) CODENTIDADE,
                             REGEXP_SUBSTR(DADOSMETACOMB.TIPOENTIDADE, '[^;]+', 1, LEVEL) TIPOENTIDADE
                        FROM DUAL
                    CONNECT BY REGEXP_SUBSTR(DADOSMETACOMB.CODENTIDADE, '[^;]+', 1, LEVEL) IS NOT NULL) LOOP

          DADOS_SAIDA.CODCOMBINACAO  := DADOSMETACOMB.CODCOMBINACAO;
          DADOS_SAIDA.CODMETA        := PNCODMETA;
          DADOS_SAIDA.CODTIPOMETA    := PNCODTIPOMETA;
          DADOS_SAIDA.CODINDICADOR   := PNCODINDICADOR;
          DADOS_SAIDA.CODENTIDADE    := DADOS.CODENTIDADE;
          DADOS_SAIDA.TABELAENTIDADE := DADOS.TIPOENTIDADE;
          DADOS_SAIDA.CAMPOCONDICAO  := '';

          PT_PCGMMETATEMP.CODCOMBINACAO  := DADOSMETACOMB.CODCOMBINACAO;
          PT_PCGMMETATEMP.CODMETA        := PNCODMETA;
          PT_PCGMMETATEMP.CODTIPOMETA    := PNCODTIPOMETA;
          PT_PCGMMETATEMP.CODINDICADOR   := PNCODINDICADOR;
          PT_PCGMMETATEMP.CODENTIDADE    := DADOS.CODENTIDADE;
          PT_PCGMMETATEMP.TABELAENTIDADE := DADOS.TIPOENTIDADE;

          P_InserirMetaTemp('S', PT_PCGMMETATEMP, NULL);

          PIPE ROW(DADOS_SAIDA);
        END LOOP;

      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN;
  END;*/

  FUNCTION F_QTCliAtivos(PSTIPOIDENTIDADE  IN VARCHAR2,
                         PNCODENTIDADEMETA IN NUMBER,
                         PSCODFILIAL       IN VARCHAR2) RETURN NUMBER IS
    VSSQL         VARCHAR2(10000);
    VNQTCLIATIVOS NUMBER;
  BEGIN
    VSSQL := 'SELECT COUNT(USUARI.CODCLI) QTCLIATIVOS
              FROM (SELECT PCCLIENT.CODCLI,
                           PCCLIENT.DTULTCOMP,
                           PCUSUARI.CODUSUR,
                           PCUSUARI.CODSUPERVISOR,
                           PCUSUARI.CODFILIAL CODFILIALUSUARI
                      FROM PCCLIENT, PCUSUARI
                     WHERE PCCLIENT.CODUSUR1 = PCUSUARI.CODUSUR
                       AND PCCLIENT.DTEXCLUSAO IS NULL
                    UNION
                    SELECT PCCLIENT.CODCLI,
                           PCCLIENT.DTULTCOMP,
                           PCUSUARI.CODUSUR,
                           PCUSUARI.CODSUPERVISOR,
                           PCUSUARI.CODFILIAL CODFILIALUSUARI
                      FROM PCCLIENT, PCUSUARI
                     WHERE PCCLIENT.CODUSUR2 = PCUSUARI.CODUSUR
                       AND PCCLIENT.DTEXCLUSAO IS NULL
                    UNION
                    SELECT PCCLIENT.CODCLI,
                           PCCLIENT.DTULTCOMP,
                           PCUSUARI.CODUSUR,
                           PCUSUARI.CODSUPERVISOR,
                           PCUSUARI.CODFILIAL CODFILIALUSUARI
                      FROM PCUSURCLI, PCCLIENT, PCUSUARI
                     WHERE PCUSURCLI.CODUSUR = PCUSUARI.CODUSUR
                       AND PCUSURCLI.CODCLI = PCCLIENT.CODCLI
                       AND PCCLIENT.DTEXCLUSAO IS NULL) USUARI
             WHERE USUARI.DTULTCOMP >= TRUNC(TO_DATE(SYSDATE, ''DD-MM-YYYY'') - PARAMFILIAL.OBTERCOMONUMBER(''CON_NUMDIASCLIINATIV'', ''99''))
               AND (USUARI.CODFILIALUSUARI IN (' || PSCODFILIAL ||
             ') OR (NVL(USUARI.CODFILIALUSUARI, ''99'') = ''99''))';
    IF PSTIPOIDENTIDADE IN ('D', 'N', 'R', 'L') THEN
      VSSQL := VSSQL ||
               ' AND USUARI.CODSUPERVISOR IN
                             (SELECT PCSUPERV.CODSUPERVISOR
                                 FROM PCSUPERV, PCGERENTE
                                WHERE PCSUPERV.CODGERENTE = PCGERENTE.CODGERENTE
                                  AND PCGERENTE.CODGERENTE =' ||
               PNCODENTIDADEMETA || ' )';

    ELSIF PSTIPOIDENTIDADE IN ('C') THEN
      VSSQL := VSSQL ||
               ' AND USUARI.CODSUPERVISOR IN
                             (SELECT PCSUPERV.CODSUPERVISOR
                                 FROM PCSUPERV, PCCOORDENADORVENDA
                                WHERE PCSUPERV.CODCOORDENADOR = PCCOORDENADORVENDA.CODIGO
                                  AND PCCOORDENADORVENDA.CODIGO =' ||
               PNCODENTIDADEMETA || ' )';
    ELSIF PSTIPOIDENTIDADE IN ('S') THEN
      VSSQL := VSSQL || ' AND USUARI.CODSUPERVISOR = ' || PNCODENTIDADEMETA;
    ELSIF PSTIPOIDENTIDADE IN ('U') THEN
      VSSQL := VSSQL || ' AND USUARI.CODUSUR = ' || PNCODENTIDADEMETA;
      --    ELSIF PSTIPOIDENTIDADE IN ('F') THEN
      --      VSSQL := VSSQL || ' AND SAID.CODFILIAL = ' || PNCODENTIDADEMETA;
    END IF;

    BEGIN
      EXECUTE IMMEDIATE VSSQL
        INTO VNQTCLIATIVOS;
    EXCEPTION
      WHEN OTHERS THEN
        VNQTCLIATIVOS := 0;
    END;

    RETURN VNQTCLIATIVOS;
  END F_QTCLIATIVOS;

  PROCEDURE P_CarregarParametros is
  BEGIN
    BEGIN
      SELECT PCGMPARAMETRO.* BULK COLLECT
        INTO TB_PCGMPARAMETRO
        FROM PCGMPARAMETRO;
    EXCEPTION
      WHEN OTHERS THEN
        TB_PCGMPARAMETRO := NULL;
    END;
  END;



  FUNCTION F_RetornarFaixaPremio(PNCODMETA      IN NUMBER,
                                 PNCODTIPOMETA  IN NUMBER,
                                 PNCODINDICADOR IN NUMBER,
                                 PNPERCATINGIDO IN NUMBER)
    RETURN TR_PCGMMETACOMB IS
    VT_DETALHEAPURACAOMETA TR_PCGMMETACOMB;
    VSTIPOBONUS            VARCHAR2(1);
    VN_PARAMETRO_PESO      NUMBER;
  BEGIN
    BEGIN
      SELECT PCGMPERFIL.TIPOBONUS
        INTO VSTIPOBONUS
        FROM PCGMMETA, PCGMPARAMMETA, PCGMPERFIL
       WHERE PCGMMETA.CODPARAMMETA = PCGMPARAMMETA.CODIGO
         AND PCGMPARAMMETA.CODPERFIL = PCGMPERFIL.CODIGO
         AND PCGMMETA.CODIGO = PNCODMETA
         AND ROWNUM = 1;

      IF (PNPERCATINGIDO < 0) THEN
        VN_PARAMETRO_PESO := F_ObterParametro('PESO_ESTORNO_ATINGIDO_NEGATIVO');
        SELECT VN_PARAMETRO_PESO NIVELATINGIDO,
               PCGMPREMIOCOMB.PESO PESOINDICADOR,
               VN_PARAMETRO_PESO * (PCGMPREMIOCOMB.PESO / 100) PERCPESOINDNIVELATING, --PESO PREMIO (PCGMFAIXAPADRAOITEM) * PESO (PCGMPREMIONIVEL)
               0 PERCINICIAL,
               0 PERCFINAL
          INTO VT_DETALHEAPURACAOMETA.NIVELATINGIDO,
               VT_DETALHEAPURACAOMETA.PESOINDICADOR,
               VT_DETALHEAPURACAOMETA.PERCPESOINDNIVELATING,
               VT_DETALHEAPURACAOMETA.FAIXAINI,
               VT_DETALHEAPURACAOMETA.FAIXAFIM
          FROM PCGMPARAMMETA,
               PCGMPREMIO,
               PCGMPERFIL,
               PCGMPREMIOCOMB,
               PCGMPARAMCOMB
         WHERE PCGMPARAMMETA.CODIGO = PCGMPREMIO.CODPARAMMETA
           AND PCGMPARAMMETA.CODPERFIL = PCGMPERFIL.CODIGO
           AND PCGMPREMIO.CODIGO = PCGMPREMIOCOMB.CODPREMIO
           AND PCGMPREMIOCOMB.CODPARAMCOMB = PCGMPARAMCOMB.CODIGO
           AND PCGMPREMIO.DATAEXCLUSAO IS NULL
           AND PCGMPARAMMETA.CODIGO =
               (SELECT PCGMMETA.CODPARAMMETA
                  FROM PCGMMETA
                 WHERE CODIGO = PNCODMETA)
           AND PCGMPARAMCOMB.CODTIPOMETA = PNCODTIPOMETA
           AND PCGMPARAMCOMB.CODINDICADOR = PNCODINDICADOR
           AND PCGMPERFIL.TIPOBONUS = VSTIPOBONUS; -- REMUNERAÇÃO VARIÁVEL PCGMPREMIO.GRATIFICACAO = 'V'
      ELSE
        SELECT PCGMPREMIONIVEL.PESO NIVELATINGIDO,
               PCGMPREMIOCOMB.PESO PESOINDICADOR,
               PCGMPREMIONIVEL.PESO * (PCGMPREMIOCOMB.PESO / 100) PERCPESOINDNIVELATING, --PESO PREMIO (PCGMFAIXAPADRAOITEM) * PESO (PCGMPREMIONIVEL)
               PCGMPREMIONIVEL.PERCINICIAL,
               PCGMPREMIONIVEL.PERCFINAL
          INTO VT_DETALHEAPURACAOMETA.NIVELATINGIDO,
               VT_DETALHEAPURACAOMETA.PESOINDICADOR,
               VT_DETALHEAPURACAOMETA.PERCPESOINDNIVELATING,
               VT_DETALHEAPURACAOMETA.FAIXAINI,
               VT_DETALHEAPURACAOMETA.FAIXAFIM
          FROM PCGMPARAMMETA,
               PCGMPREMIO,
               PCGMPERFIL,
               PCGMPREMIONIVEL,
               PCGMPREMIOCOMB,
               PCGMPARAMCOMB
         WHERE PCGMPARAMMETA.CODIGO = PCGMPREMIO.CODPARAMMETA
           AND PCGMPARAMMETA.CODPERFIL = PCGMPERFIL.CODIGO
           AND PCGMPREMIO.CODIGO = PCGMPREMIOCOMB.CODPREMIO
           AND PCGMPREMIOCOMB.CODIGO = PCGMPREMIONIVEL.CODIGO
           AND PCGMPREMIOCOMB.CODPARAMCOMB = PCGMPARAMCOMB.CODIGO
           AND PCGMPREMIO.DATAEXCLUSAO IS NULL
           AND PCGMPARAMMETA.CODIGO =
               (SELECT PCGMMETA.CODPARAMMETA
                  FROM PCGMMETA
                 WHERE CODIGO = PNCODMETA)
           AND PCGMPARAMCOMB.CODTIPOMETA = PNCODTIPOMETA
           AND PCGMPARAMCOMB.CODINDICADOR = PNCODINDICADOR
           AND PCGMPERFIL.TIPOBONUS = VSTIPOBONUS -- REMUNERAÇÃO VARIÁVEL PCGMPREMIO.GRATIFICACAO = 'V'
           AND DECODE(PNPERCATINGIDO, 0, NULL, PNPERCATINGIDO) BETWEEN
               PCGMPREMIONIVEL.PERCINICIAL AND PCGMPREMIONIVEL.PERCFINAL;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        VT_DETALHEAPURACAOMETA.NIVELATINGIDO         := 0;
        VT_DETALHEAPURACAOMETA.PESOINDICADOR         := 0;
        VT_DETALHEAPURACAOMETA.PERCPESOINDNIVELATING := 0;
    END;

    BEGIN
      SELECT PCGMPREMIOCOMB.PESO PESOINDICADOR
        INTO VT_DETALHEAPURACAOMETA.PESOINDICADOR
        FROM PCGMPARAMMETA,
             PCGMMETA,
             PCGMPREMIO,
             PCGMPREMIOCOMB,
             PCGMPARAMCOMB
       WHERE PCGMPARAMMETA.CODIGO = PCGMMETA.CODPARAMMETA
         AND PCGMPREMIO.CODPARAMMETA = PCGMPARAMMETA.CODIGO
         AND PCGMPREMIOCOMB.CODPREMIO = PCGMPREMIO.CODIGO
         AND PCGMPREMIOCOMB.CODPARAMCOMB = PCGMPARAMCOMB.CODIGO
         AND PCGMPREMIO.DATAEXCLUSAO IS NULL
         AND PCGMMETA.CODIGO = PNCODMETA
         AND PCGMPARAMCOMB.CODTIPOMETA = PNCODTIPOMETA
         AND PCGMPARAMCOMB.CODINDICADOR = PNCODINDICADOR;
    EXCEPTION
      WHEN OTHERS THEN
        VT_DETALHEAPURACAOMETA.PESOINDICADOR := 0;
    END;
    RETURN VT_DETALHEAPURACAOMETA;
  END;

--copia da procedure
PROCEDURE P_RetornarFiltroColaborador(PNCODMETA IN NUMBER,
                                        PSFILTROSQL OUT VARCHAR2,
                                        PSCODSUPERVISOR OUT NUMBER,
                                        PSCODGERENTEREGIONAL OUT NUMBER,
                                        PSCODGERENTENACIONAL OUT NUMBER,
                                        PSCODGERENTE OUT NUMBER,
                                        PSCODUSUR OUT NUMBER) IS
     VNCODENTIDADEMETA       NUMBER;
     VSTIPOIDENTIDADE        VARCHAR2(5);
     VSBLOCOSQLCALCREALIZADO VARCHAR2(50);
     VSCODSUPERVISOR          NUMBER;
     VSCODGERENTEREGIONAL NUMBER;
     VSCODGERENTENACIONAL NUMBER;
     VSCODGERENTE               NUMBER;
     VSCODUSUR                  NUMBER;

  BEGIN

     P_EncontrarDadosPerfil(PNCODMETA, VNCODENTIDADEMETA, VSTIPOIDENTIDADE);

     VSBLOCOSQLCALCREALIZADO := '';
     IF VSTIPOIDENTIDADE IN ('D') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODDIRETOR = ' ||
                                   VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('N') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODGERENTENACIONAL= ' ||
                                   VNCODENTIDADEMETA;
        VSCODGERENTENACIONAL       := VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('R') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODGERENTEREGIONAL = ' ||
                                   VNCODENTIDADEMETA;
        VSCODGERENTEREGIONAL      := VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('L') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODGERENTE = ' || VNCODENTIDADEMETA;
        VSCODGERENTE            := VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('C') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODCOORDENADOR = ' ||
                                   VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('S') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODSUPERVISOR = ' ||
                                   VNCODENTIDADEMETA;
        VSCODSUPERVISOR          := VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('U') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODUSUR = ' ||
                                   VNCODENTIDADEMETA;
        VSCODUSUR          := VNCODENTIDADEMETA;
     ELSIF VSTIPOIDENTIDADE IN ('F') THEN
        VSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO ||
                                   ' AND CODFILIAL = ' || VNCODENTIDADEMETA;
     END IF;

     PSCODSUPERVISOR            := VSCODSUPERVISOR;
     PSCODGERENTEREGIONAL       := VSCODGERENTEREGIONAL;
     PSCODGERENTENACIONAL       := VSCODGERENTENACIONAL;
     PSCODGERENTE               := VSCODGERENTE;
     PSCODUSUR                  := VSCODUSUR;
     PSFILTROSQL                := VSBLOCOSQLCALCREALIZADO;
  END;


  FUNCTION F_EncontrarNomeEntidade(PNCODCOMBINACAO IN NUMBER,
                                   PSCODENTIDADE   IN VARCHAR2,
                                   PSTIPOENTIDADE  IN VARCHAR2)
    RETURN TR_RETORNO IS
    VSNOMETABELA                  VARCHAR2(100);
    VSCOLUNATABELA                VARCHAR2(100);
    VSCAMPOCONDICAO               VARCHAR2(500);
    VSSQL                         VARCHAR2(500);
    VSRECEBENOMECAMPO             VARCHAR2(100);
    VSCODENTIDADE                 VARCHAR2(100);
    RETORNO                       VARCHAR2(500);
    VNCONTADOR                    NUMBER;
    VSBLOCOSQLCALCREALIZADO       VARCHAR2(5000);
    VSBLOCOSQLCALCREALIZADOFROM   VARCHAR2(100);
    VSBLOCOSQLCALCREALIZADOWHERE  VARCHAR2(20);
    VSBLOCOSQLCALCREALIZADOFILTRO VARCHAR2(1000);
    VT_RETORNO                    TR_RETORNO;
  BEGIN
    RETORNO                       := '';
    VNCONTADOR                    := 0;
    VSBLOCOSQLCALCREALIZADOFROM   := '';
    VSBLOCOSQLCALCREALIZADOWHERE  := ' WHERE 1=1';
    VSBLOCOSQLCALCREALIZADOFILTRO := '';
    FOR DADOS IN (SELECT REGEXP_SUBSTR(PSCODENTIDADE, '[^;]+', 1, LEVEL) CODENTIDADE,
                         REGEXP_SUBSTR(PSTIPOENTIDADE, '[^;]+', 1, LEVEL) TIPOENTIDADE
                    FROM DUAL
                  CONNECT BY REGEXP_SUBSTR(PSCODENTIDADE, '[^;]+', 1, LEVEL) IS NOT NULL) LOOP

      VSCODENTIDADE := DADOS.CODENTIDADE;
      IF DADOS.TIPOENTIDADE = 'CLI' THEN
        VSNOMETABELA                  := 'PCCLIENT';
        VSCOLUNATABELA                := 'PCCLIENT.CLIENTE';
        VSCAMPOCONDICAO               := 'PCCLIENT.CODCLI';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM || '';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODCLI = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'CAT' THEN
        VSNOMETABELA                  := 'PCCATEGORIA';
        VSCOLUNATABELA                := 'PCCATEGORIA.CATEGORIA';
        VSCAMPOCONDICAO               := '(PCCATEGORIA.CODSEC ||''-''|| PCCATEGORIA.CODCATEGORIA)';
        VSCODENTIDADE                 := '''' || DADOS.CODENTIDADE || '''';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCCATEGORIA, PCPRODUT PROD ';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODPROD  = PROD.CODPROD
                                           AND PROD.CODCATEGORIA  = PCCATEGORIA.CODCATEGORIA
                                           AND (PCCATEGORIA.CODSEC , PCCATEGORIA.CODCATEGORIA) IN(SELECT ' ||
                                         REPLACE(REPLACE(VSCODENTIDADE,
                                                         '-',
                                                         ','),
                                                 '''',
                                                 '') || ' FROM DUAL)';
        --                                                                           AND (PCCATEGORIA.CODSEC ||''-''|| PCCATEGORIA.CODCATEGORIA) = ' || VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'DEP' THEN
        VSNOMETABELA                  := 'PCDEPTO';
        VSCOLUNATABELA                := 'PCDEPTO.DESCRICAO';
        VSCAMPOCONDICAO               := 'PCDEPTO.CODEPTO';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ',PCDEPTO';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND PCDEPTO.CODEPTO = MOV.CODEPTO
                                      AND PCDEPTO.CODEPTO = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'FOR' THEN
        VSNOMETABELA                  := 'PCFORNEC';
        VSCOLUNATABELA                := 'PCFORNEC.FORNECEDOR';
        VSCAMPOCONDICAO               := 'PCFORNEC.CODFORNEC ';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ',PCFORNEC';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODFORNEC = PCFORNEC.CODFORNEC
                                      AND PCFORNEC.CODFORNEC = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'FORPRI' THEN

        VSNOMETABELA                  := 'PCFORNEC';
        VSCOLUNATABELA                := ' PCFORNEC.FORNECEDOR';
        VSCAMPOCONDICAO               := ' PCFORNEC.CODFORNECPRINC AND ROWNUM = 1 AND PCFORNEC.CODFORNEC = NVL(PCFORNEC.CODFORNECPRINC, PCFORNEC.CODFORNEC)';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ',PCFORNEC';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODFORNEC = PCFORNEC.CODFORNEC
                                      AND PCFORNEC.CODFORNECPRINC = ' ||
                                         VSCODENTIDADE;

      ELSIF DADOS.TIPOENTIDADE = 'PRA' THEN
        VSNOMETABELA                  := 'PCPRACA';
        VSCOLUNATABELA                := 'PCPRACA.PRACA';
        VSCAMPOCONDICAO               := 'PCPRACA.CODPRACA ';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCPRACA, PCCLIENT ';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODCLI = PCCLIENT.CODCLI
                                         AND PCPRACA.CODPRACA = PCCLIENT.CODPRACA
                                          AND PCPRACA.CODPRACA = ' ||
                                         VSCODENTIDADE;

      ELSIF DADOS.TIPOENTIDADE = 'LIPRO' THEN
        VSNOMETABELA                  := 'PCLINHAPROD';
        VSCOLUNATABELA                := 'PCLINHAPROD.DESCRICAO';
        VSCAMPOCONDICAO               := 'PCLINHAPROD.CODLINHA';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCLINHAPROD, PCPRODUT PROD';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODPROD  = PCPRODUT.CODPROD
                                             AND PCPRODUT.CODLINHAPROD  = PCLINHAPROD.CODLINHA
                                             AND PCLINHAPROD.CODLINHA = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'MAR' THEN
        VSNOMETABELA                  := 'PCMARCA';
        VSCOLUNATABELA                := 'PCMARCA.MARCA';
        VSCAMPOCONDICAO               := 'PCMARCA.CODMARCA';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCMARCA, PCPRODUT PROD';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODPROD  = PROD.CODPROD
                                             AND PROD.CODMARCA  = PCMARCA.CODMARCA  AND PCMARCA.CODMARCA = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'PRO' THEN
        VSNOMETABELA                  := 'PCPRODUT';
        VSCOLUNATABELA                := 'PCPRODUT.DESCRICAO';
        VSCAMPOCONDICAO               := 'PCPRODUT.CODPROD';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM || '';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODPROD  = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'RAATIV' THEN
        VSNOMETABELA                  := 'PCATIVI';
        VSCOLUNATABELA                := 'PCATIVI.RAMO';
        VSCAMPOCONDICAO               := 'PCATIVI.CODATIV';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCATIVI, PCCLIENT ';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODCLI  = PCCLIENT.CODCLI
                                             AND PCCLIENT.CODATV1  = PCATIVI.CODATIV
                                             AND PCATIVI.CODATIV = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'SEC' THEN
        VSNOMETABELA                  := 'PCSECAO';
        VSCOLUNATABELA                := 'PCSECAO.DESCRICAO';
        VSCAMPOCONDICAO               := 'PCSECAO.CODSEC';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM || '';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODSEC  = ' ||
                                         VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'SUBCAT' THEN
        VSNOMETABELA                  := 'PCSUBCATEGORIA';
        VSCOLUNATABELA                := 'PCSUBCATEGORIA.SUBCATEGORIA';
        VSCAMPOCONDICAO               := '(PCSUBCATEGORIA.CODSEC  ||''-''|| PCSUBCATEGORIA.CODCATEGORIA  ||''-''|| PCSUBCATEGORIA.CODSUBCATEGORIA)';
        VSCODENTIDADE                 := '''' || DADOS.CODENTIDADE || '''';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCSUBCATEGORIA, PCPRODUT PROD ';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODPROD  = PROD.CODPROD
                                             AND PROD.CODSUBCATEGORIA  = PCSUBCATEGORIA.CODSUBCATEGORIA
                                             AND (PCSUBCATEGORIA.CODSEC, PCSUBCATEGORIA.CODCATEGORIA, PCSUBCATEGORIA.CODSUBCATEGORIA) IN(SELECT ' ||
                                         REPLACE(REPLACE(VSCODENTIDADE,
                                                         '-',
                                                         ','),
                                                 '''',
                                                 '') || ' FROM DUAL)';
        --                                             AND (PCSUBCATEGORIA.CODSEC  ||''-''|| PCSUBCATEGORIA.CODCATEGORIA  ||''-''|| PCSUBCATEGORIA.CODSUBCATEGORIA) = ' || VSCODENTIDADE;
      ELSIF DADOS.TIPOENTIDADE = 'GRUCLI' THEN
        VSNOMETABELA   := 'PCGRUPOSCAMPANHAC';
        VSCOLUNATABELA := 'PCGRUPOSCAMPANHAC.DESCRICAO';
        --          VSCAMPOCONDICAO := 'PCGRUPOSCAMPANHAC.CODGRUPO AND PCGRUPOSCAMPANHAC.DTEXCLUSAO IS NULL AND PCGRUPOSCAMPANHAC.TIPO = ''CL''';
        VSCAMPOCONDICAO               := 'PCGRUPOSCAMPANHAC.CODGRUPO AND PCGRUPOSCAMPANHAC.TIPO = ''CL''';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCCLIENT ';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODCLI  = PCCLIENT.CODCLI
                                           AND PCCLIENT.CODCLI IN(SELECT I.CODITEM
                                                                                          FROM PCGRUPOSCAMPANHAC S, PCGRUPOSCAMPANHAI I
                                                                                         WHERE S.CODGRUPO = I.CODGRUPO
                                                                                           AND S.TIPO = ''CL'' AND I.CODGRUPO = ' ||
                                         VSCODENTIDADE || ')';
      ELSIF DADOS.TIPOENTIDADE = 'GRUPRO' THEN
        VSNOMETABELA   := 'PCGRUPOSCAMPANHAC';
        VSCOLUNATABELA := 'PCGRUPOSCAMPANHAC.DESCRICAO';
        --          VSCAMPOCONDICAO := 'PCGRUPOSCAMPANHAC.CODGRUPO AND PCGRUPOSCAMPANHAC.DTEXCLUSAO IS NULL AND PCGRUPOSCAMPANHAC.TIPO = ''GP''';
        VSCAMPOCONDICAO               := 'PCGRUPOSCAMPANHAC.CODGRUPO AND PCGRUPOSCAMPANHAC.TIPO = ''GP''';
        VSBLOCOSQLCALCREALIZADOFROM   := VSBLOCOSQLCALCREALIZADOFROM ||
                                         ', PCPRODUT PROD';
        VSBLOCOSQLCALCREALIZADOFILTRO := VSBLOCOSQLCALCREALIZADOFILTRO ||
                                         ' AND MOV.CODPROD  = PROD.CODPROD
                                           AND PROD.CODPROD IN(SELECT I.CODITEM
                                                                                          FROM PCGRUPOSCAMPANHAC S, PCGRUPOSCAMPANHAI I
                                                                                         WHERE S.CODGRUPO = I.CODGRUPO
                                                                                           AND S.TIPO = ''GP'' AND I.CODGRUPO = ' ||
                                         VSCODENTIDADE || ')';
      END IF;

      VSSQL := 'SELECT ' || VSCOLUNATABELA ||
               ' AS NOME
                    FROM PCGMCOMBITEM, ' || VSNOMETABELA ||
               ' WHERE PCGMCOMBITEM.FILTRO = ''' || DADOS.TIPOENTIDADE || '''
                     AND PCGMCOMBITEM.ITEM = ' ||
               VSCAMPOCONDICAO || ' AND PCGMCOMBITEM.ITEM = ' ||
               VSCODENTIDADE || ' AND PCGMCOMBITEM.CODIGO = ' ||
               PNCODCOMBINACAO;

      BEGIN
        EXECUTE IMMEDIATE VSSQL
          INTO VSRECEBENOMECAMPO;

      EXCEPTION
        WHEN OTHERS THEN
          VSRECEBENOMECAMPO := '';
      END;

      IF VNCONTADOR = 0 THEN
        RETORNO := VSRECEBENOMECAMPO;
      ELSE
        RETORNO := RETORNO || ';' || VSRECEBENOMECAMPO;
      END IF;

      VNCONTADOR := VNCONTADOR + 1;
    END LOOP;

    VSBLOCOSQLCALCREALIZADO            := VSBLOCOSQLCALCREALIZADOFROM ||
                                          VSBLOCOSQLCALCREALIZADOWHERE ||
                                          VSBLOCOSQLCALCREALIZADOFILTRO;
    VT_RETORNO.PSBLOCOSQLCALCREALIZADO := VSBLOCOSQLCALCREALIZADO;
    VT_RETORNO.NOMECOMBENTIDADE        := RETORNO;
    RETURN VT_RETORNO;
  END;

  FUNCTION MetaPrevistaPorIndicador(PNCODMETA      IN NUMBER,
                                    PNCODTIPOMETA  IN NUMBER DEFAULT 0,
                                    PNCODINDICADOR IN NUMBER DEFAULT 0,
                                    PDDATAINI      IN DATE,
                                    PDDATAFIM      IN DATE)
    RETURN TB_PCGMINDICADOR
    PIPELINED IS
    DADOS_SAIDA TR_PCGMINDICADOR;

    VNVALORINDICADOR NUMBER;
    VSSQL            VARCHAR2(10000);
    VSREGRAINDICADOR VARCHAR2(10000);
    MSG              VARCHAR2(10000);
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/RRRR''';

    FOR TABPCGMINDICADOR IN (SELECT S.*
                               FROM PCGMINDICADOR S
                              WHERE S.CODIGO =
                                    DECODE(NVL(PNCODINDICADOR, 0),
                                           0,
                                           S.CODIGO,
                                           PNCODINDICADOR)
                              ORDER BY S.CODIGO) LOOP
      BEGIN
        MSG              := 'OK';
        VSREGRAINDICADOR := TABPCGMINDICADOR.REGRACALCPREVISTO;

        IF VSREGRAINDICADOR IS NULL THEN
          VSREGRAINDICADOR := 'VALOR';
        END IF;

        VSSQL := 'SELECT ' || VSREGRAINDICADOR || '
                    FROM (SELECT *
                            FROM PCGMMETACOMB
                           WHERE PCGMMETACOMB.CODMETA  = ' ||
                 PNCODMETA || ' AND PCGMMETACOMB.CODTIPOMETA = ' ||
                 PNCODTIPOMETA || ' AND PCGMMETACOMB.CODINDICADOR = ' ||
                 PNCODINDICADOR || ' AND PCGMMETACOMB.DATA >= ''' ||
                 TO_DATE(PDDATAINI, 'DD/MM/RRRR') ||
                 ''' AND PCGMMETACOMB.DATA <= ''' ||
                 TO_DATE(PDDATAFIM, 'DD/MM/RRRR') || ''') PREVISTO';

        EXECUTE IMMEDIATE VSSQL
          INTO VNVALORINDICADOR;

        DADOS_SAIDA.CODIGO    := TABPCGMINDICADOR.CODIGO;
        DADOS_SAIDA.DESCRICAO := TABPCGMINDICADOR.DESCRICAO;
        DADOS_SAIDA.VALOR     := VNVALORINDICADOR;
        PIPE ROW(DADOS_SAIDA);
      EXCEPTION
        WHEN OTHERS THEN
          MSG := VSREGRAINDICADOR || ' --- ' ||
                 DBMS_UTILITY.FORMAT_ERROR_STACK;
          DBMS_OUTPUT.put_line(MSG);
          VNVALORINDICADOR := 0;
      END;
    END LOOP;

    RETURN;
  END METAPREVISTAPORINDICADOR;

  FUNCTION F_RetornarRealizado(PSCODFILIAL             IN VARCHAR2,
                               PNCODMETA               IN NUMBER,
                               PNCODTIPOMETA           IN NUMBER,
                               PNCODINDICADOR          IN NUMBER DEFAULT 0,
                               PSBLOCOSQLCALCREALIZADO IN VARCHAR2,
                               PDDATAINI               IN DATE,
                               PDDATAFIM               IN DATE,
                               VSCODSUPERVISOR          IN NUMBER,
                               VSCODGERENTEREGIONAL IN NUMBER,
                               VSCODGERENTENACIONAL IN NUMBER,
                               VSCODGERENTE               IN NUMBER,
                               VSCODUSUR                  IN NUMBER) RETURN NUMBER IS
    --    DADOS_SAIDA TR_PCGMINDICADOR;
    DADOSVENDA              TB_PCGMINDICADOR;
    VNVALORINDICADOR        NUMBER;
    VSSQL                   VARCHAR2(32000);
    VSREGRAINDICADOR        VARCHAR2(1000);
    MSG                     VARCHAR2(10000);
    VSCODFILIAL             VARCHAR2(500);
    VDDATAINI               DATE;
    VDDATAFIM               DATE;
    VNCODENTIDADEMETA       NUMBER;
    VSTIPOIDENTIDADE        VARCHAR2(2);
    VNCONTCLI               NUMBER := 0;
    VNSUMCLI                NUMBER := 0;
    VT_PCGMMETATEMP         TB_PCGMMETATEMP;

  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/RRRR''';
    --    VSCODFILIAL := CASE WHEN PSCODFILIAL = '99' THEN NULL ELSE PSCODFILIAL END;
    VDDATAINI := TO_DATE(PDDATAINI, 'DD/MM/RRRR');
    VDDATAFIM := TO_DATE(PDDATAFIM, 'DD/MM/RRRR');


    VSCODFILIAL := PSCODFILIAL;

    SELECT PCGMINDICADOR.REGRACALCREALIZADO --BULK COLLECT
    --  INTO TABPCGMINDICADOR
      INTO VSREGRAINDICADOR
      FROM PCGMINDICADOR
     WHERE PCGMINDICADOR.CODIGO = PNCODINDICADOR;
    /* DECODE(NVL(PNCODINDICADOR, 0),
                      0,
                      PCGMINDICADOR.CODIGO,
                      PNCODINDICADOR)
         ORDER BY PCGMINDICADOR.CODIGO;
    */
    -- FOR INDX IN 1 .. TABPCGMINDICADOR.COUNT LOOP
    BEGIN

      MSG := 'OK';
      --VSREGRAINDICADOR := TABPCGMINDICADOR(INDX).REGRACALCREALIZADO;

      VSSQL := F_RetornarSQLVendasDevol(PN_CODIGOINDICADOR    => PNCODINDICADOR, --TABPCGMINDICADOR(INDX).CODIGO,
                                        PS_CODFILIAL          => VSCODFILIAL,
                                        PS_BLOCOSQLCONSVENDAS => NULL,
                                        PD_DATAINI            => VDDATAINI,
                                        PD_DATAFIM            => VDDATAFIM,
                                        PS_AGRUPARPOR         => NULL,
                                        PN_CODSUPERVISOR       => VSCODSUPERVISOR,
                                        PN_CODGERENTEREGIONAL => VSCODGERENTEREGIONAL,
                                        PN_CODGERENTENACIONAL => VSCODGERENTENACIONAL,
                                        PN_CODGERENTE          => VSCODGERENTE,
                                        PN_CODUSUR             => VSCODUSUR);

      /*        DADOS_SAIDA.PERCOMMOV := NULL;
      DADOS_SAIDA.VLFATPORPERCOM := NULL;
      DADOS_SAIDA.NUMCAR := 0;
      DADOS_SAIDA.NUMTRANSVENDA := 0;*/

      IF VSREGRAINDICADOR IS NOT NULL THEN
/*
        IF PNCODINDICADOR = 22 THEN
          EXECUTE IMMEDIATE VSSQL
            INTO VNVALORINDICADOR
            USING VDDATAINI, VDDATAFIM;
        ELSIF PNCODINDICADOR = 21 THEN
          EXECUTE IMMEDIATE VSSQL BULK COLLECT
            INTO DADOSVENDA;

          FOR I IN 1 .. DADOSVENDA.COUNT LOOP
            VSSQL := VSREGRAINDICADOR;
            EXECUTE IMMEDIATE VSSQL
              INTO VNCONTCLI
              USING DADOSVENDA(I).NUMCAR, DADOSVENDA(I).NUMTRANSVENDA;

            IF VNCONTCLI > 0 THEN
              VNSUMCLI := VNSUMCLI + VNCONTCLI;
            END IF;
          END LOOP;

          VNVALORINDICADOR := VNSUMCLI;
        ELSE */
          --  EXECUTE IMMEDIATE VSSQL
          --   INTO VNVALORINDICADOR;

          ------------------------------------------------------------------------

          
          EXECUTE IMMEDIATE 'SELECT NVL(SUM(CODPROD), 0) ' ||
                            '  FROM ' || DEF_PCGMMETAGLOBALTEMP(VSCODFILIAL) ||
                            ' WHERE VLLIQUIDO IS NOT NULL 
                                AND DATA >= ''' || VDDATAINI || '''
                                AND DATA <= ''' || VDDATAFIM || ''''
             INTO VNCONTCLI;

          IF (VNCONTCLI = 0) THEN
            EXECUTE IMMEDIATE VSSQL BULK COLLECT
              INTO VT_PCGMMETATEMP;

            FOR INDX IN 1 .. VT_PCGMMETATEMP.COUNT LOOP
              VT_PCGMMETATEMP(INDX).CODMETA := PNCODMETA;
              VT_PCGMMETATEMP(INDX).CODTIPOMETA := PNCODTIPOMETA;
              VT_PCGMMETATEMP(INDX).CODINDICADOR := PNCODINDICADOR;

              IF ((NVL(VT_PCGMMETATEMP(INDX).TIPOMOV, 'N') = 'DA') AND (VT_PCGMMETATEMP(INDX).PERCOM = 0)) OR
                 ((NVL(VT_PCGMMETATEMP(INDX).TIPOMOV, 'N') = 'V') AND (VT_PCGMMETATEMP(INDX).NUMTRANSENTNFESTORNADA IS NOT NULL)) THEN
                VT_PCGMMETATEMP(INDX).PERCOM := F_EncontrarPercom(VT_PCGMMETATEMP(INDX));
              END IF;

              IF (NVL(F_ObterParametro('ABATER_VALOR_ST'), 'N') = 'N') THEN
                VT_PCGMMETATEMP(INDX).VLST := 0;
                VT_PCGMMETATEMP(INDX).VLSTBONIFIC := 0;
              END IF;

              IF (NVL(F_ObterParametro('ABATER_VALOR_IPI'), 'N') = 'N') THEN
                VT_PCGMMETATEMP(INDX).VLIPI := 0;
                VT_PCGMMETATEMP(INDX).VLIPIBONIFIC := 0;
              END IF;

              IF (NVL(F_ObterParametro('ABATER_VALOR_FECP'), 'N') = 'N') THEN
                VT_PCGMMETATEMP(INDX).VLFECP := 0;
              END IF;

            END LOOP;

            P_InserirMetaTemp('N', VSCODFILIAL, NULL, VT_PCGMMETATEMP);
          END IF;

          VSSQL := 'SELECT ' || VSREGRAINDICADOR ||
                   ' FROM (SELECT  MOV.*
                             FROM ' || DEF_PCGMMETAGLOBALTEMP(PSCODFILIAL) || ' MOV ' || PSBLOCOSQLCALCREALIZADO ||
                   '          AND MOV.CODPROD IS NOT NULL
                              AND MOV.CODFILIAL IN(' ||
                   VSCODFILIAL || ')
                              AND DATA >= ''' || VDDATAINI || '''
                              AND DATA <= ''' || VDDATAFIM || '''';
          IF PNCODINDICADOR IN (5,22) THEN
            VSSQL := VSSQL || ' AND TIPOMOV = ''V''';
          END IF;

          VSSQL := VSSQL || '  ) MOV';
          IF PNCODINDICADOR in (22) THEN
             EXECUTE IMMEDIATE VSSQL INTO VNVALORINDICADOR USING VDDATAINI, VDDATAFIM;
          ELSE
             EXECUTE IMMEDIATE VSSQL INTO VNVALORINDICADOR;
          END IF;
          ------------------------------------------------------------------------
   --     END IF;
      END IF;

      /*        DADOS_SAIDA.CODIGO    := PNCODINDICADOR; --TABPCGMINDICADOR(INDX).CODIGO;
      DADOS_SAIDA.DESCRICAO := NULL; --TABPCGMINDICADOR(INDX).DESCRICAO;
      DADOS_SAIDA.VALOR     := VNVALORINDICADOR;
      PIPE ROW(DADOS_SAIDA);*/

    EXCEPTION
      WHEN OTHERS THEN
        MSG := VSREGRAINDICADOR || ' --- CODENTIDADEMETA: ' ||
               VNCODENTIDADEMETA || ' - PSBLOCOSQLCALCREALIZADO' ||
               PSBLOCOSQLCALCREALIZADO || ' - ' ||
               DBMS_UTILITY.FORMAT_ERROR_STACK;
        DBMS_OUTPUT.put_line(MSG);
        VNVALORINDICADOR := 0;
    END;
    -- END LOOP;

    RETURN VNVALORINDICADOR;
  END F_RetornarRealizado;

  FUNCTION APURACAOMETA(PNCODMETA      IN NUMBER,
                        PNCODTIPOMETA  IN NUMBER DEFAULT 0,
                        PNCODINDICADOR IN NUMBER DEFAULT 0,
                        PDDATAINI      IN DATE,
                        PDDATAFIM      IN DATE) RETURN TB_PCGMMETACOMB
    PIPELINED IS
    DADOS_SAIDA TR_PCGMMETACOMB;

    VSBLOCOSQLCALCREALIZADO VARCHAR2(5000);
    VSSQL                   VARCHAR2(15000);
    VNVALORREALIZADO        NUMBER;
    VDDATAINI               DATE;
    VDDATAFIM               DATE;
    VT_FAIXAPREMIO          TR_PCGMMETACOMB;
    VT_PARAMETRO            TR_PARAMETRO;
    VNLISTANUMTRANSVENDA    NUMBER;
    VSCODFILIAL             VARCHAR2(2000);
    VNCONTADOR              NUMBER;
    VT_RETORNO              TR_RETORNO;
    VNVLFATURADORPORIND     NUMBER;
    VSFILTROCOLABORADOR     VARCHAR2(50);
    VSCODSUPERVISOR          NUMBER;
    VSCODGERENTEREGIONAL     NUMBER;
    VSCODGERENTENACIONAL     NUMBER;
    VSCODGERENTE            NUMBER;
    VSCODUSUR               NUMBER;
    e_TabTempNotFound       EXCEPTION;

    PROCEDURE ATUALIZASUBTOTAL(PN_CODMETA      IN NUMBER,
                               PN_CODTIPOMETA  IN NUMBER,
                               PN_CODINDICADOR IN NUMBER,
                               PS_CODFILIAL    IN VARCHAR2) IS

      VSREGRAINDICADOR    VARCHAR2(1000);
      VT_PARAMETROCAB     TR_PARAMETRO;
      VNCONTADTFECHAMENTO NUMBER;
      VSPERIODICIDADE     VARCHAR2(2);
      VNPREVISTO          NUMBER;
      VNREALIZADO         NUMBER;
      VSCODFILIAL         PCFILIAL.CODIGO%TYPE;
    BEGIN

      SELECT PCGMPERIODO.PERIODICIDADE, PCGMPARAMMETA.CODFILIAL
        INTO VSPERIODICIDADE, VSCODFILIAL
        FROM PCGMMETA, PCGMPARAMMETA, PCGMPERIODO
       WHERE 1 = 1
         AND PCGMMETA.CODPARAMMETA = PCGMPARAMMETA.CODIGO
         AND PCGMPERIODO.CODIGO = PCGMPARAMMETA.CODPERIODO
         AND PCGMMETA.CODIGO = PN_CODMETA;

      IF (VSPERIODICIDADE = 'D') THEN
        SELECT TO_DATE(TO_CHAR(TRUNC(VDDATAINI, 'MON')), 'DD/MM/YYYY')
          INTO VDDATAINI
          FROM DUAL;

        SELECT LAST_DAY(VDDATAINI) INTO VDDATAFIM FROM DUAL;
      END IF;

      FOR DADOSMETACOMB IN (SELECT DISTINCT PCGMMETACOMB.CODMETA,
                                            PCGMMETACOMB.CODTIPOMETA,
                                            PCGMMETACOMB.CODINDICADOR,
                                            PCGMFILTROTIPOMETA.TIPO TIPOENTIDADE
                              FROM PCGMMETACOMB,
                                   PCGMMETA,
                                   PCGMPARAMMETA,
                                   PCGMFILTROTIPOMETA
                             WHERE 1 = 1
                               AND PCGMMETA.CODPARAMMETA =
                                   PCGMPARAMMETA.CODIGO
                               AND PCGMMETA.CODIGO = PCGMMETACOMB.CODMETA
                               AND PCGMMETACOMB.CODMETA = PCGMMETA.CODIGO
                               AND PCGMFILTROTIPOMETA.CODIGO =
                                   PCGMMETACOMB.CODTIPOMETA
                               AND PCGMMETACOMB.CODMETA = PN_CODMETA) LOOP

        VT_PARAMETROCAB.TIPOENTIDADE := DADOSMETACOMB.TIPOENTIDADE;
        VSBLOCOSQLCALCREALIZADO := F_RetornarSQLEntidadeIN(PNCODMETA         => DADOSMETACOMB.CODMETA,
                                                           PNCODTIPOMETA     => DADOSMETACOMB.CODTIPOMETA,
                                                           PNCODINDICADOR    => DADOSMETACOMB.CODINDICADOR,
                                                           PNCODENTIDADEMETA => 0,
                                                           PDDATAINI         => VDDATAINI,
                                                           PDDATAFIM         => VDDATAFIM,
                                                           PSCODFILIAL       => PS_CODFILIAL);

        P_RetornarFiltroColaborador(PNCODMETA,
                                    VSFILTROCOLABORADOR,
                                    VSCODSUPERVISOR,
                                    VSCODGERENTEREGIONAL,
                                    VSCODGERENTENACIONAL,
                                    VSCODGERENTE,
                                    VSCODUSUR);

        VSBLOCOSQLCALCREALIZADO := NVL(VSBLOCOSQLCALCREALIZADO, ' WHERE 1=1 ') || VSFILTROCOLABORADOR;

        SELECT W.REGRACALCREALIZADO
          INTO VSREGRAINDICADOR
          FROM PCGMINDICADOR W
         WHERE W.CODIGO = DADOSMETACOMB.CODINDICADOR;

        VSSQL := 'SELECT ' || VSREGRAINDICADOR || '
                        FROM (SELECT MOV.*
                                FROM ' || DEF_PCGMMETAGLOBALTEMP(PS_CODFILIAL) || ' MOV ' || CASE WHEN VSBLOCOSQLCALCREALIZADO IS NULL THEN ' WHERE 1=1 ' ELSE VSBLOCOSQLCALCREALIZADO END || ' AND CODPROD IS NOT NULL
                                 AND MOV.CODFILIAL IN(' || VSCODFILIAL || ')
                                 AND DATA >= ''' || VDDATAINI || '''
                                 AND DATA <= ''' || VDDATAFIM || '''';
        IF DADOSMETACOMB.CODINDICADOR IN (5,22) THEN
          VSSQL := VSSQL || ' AND TIPOMOV = ''V''';
        END IF;
        VSSQL := VSSQL || '  ) MOV';
        BEGIN

          IF DADOSMETACOMB.CODINDICADOR in (22) THEN
             EXECUTE IMMEDIATE VSSQL INTO VNVALORREALIZADO USING VDDATAINI, VDDATAFIM;
          ELSE
             EXECUTE IMMEDIATE VSSQL INTO VNVALORREALIZADO;
          END IF;

        EXCEPTION
          WHEN OTHERS THEN
            VNVALORREALIZADO := 0;
        END;

        SELECT COUNT(1)
          INTO VNCONTADTFECHAMENTO
          FROM PCGMMETACOMB
         WHERE CODMETA = DADOSMETACOMB.CODMETA
           AND CODTIPOMETA = DADOSMETACOMB.CODTIPOMETA
           AND CODINDICADOR = DADOSMETACOMB.CODINDICADOR
           AND DATA >= VDDATAINI
           AND DATA <= VDDATAFIM
           AND DTFECHAMENTO IS NULL;

        IF VNCONTADTFECHAMENTO > 0 THEN
          VT_PARAMETROCAB.CODMETA       := DADOSMETACOMB.CODMETA;
          VT_PARAMETROCAB.CODTIPOMETA   := DADOSMETACOMB.CODTIPOMETA;
          VT_PARAMETROCAB.CODINDICADOR  := DADOSMETACOMB.CODINDICADOR;
          VT_PARAMETROCAB.DATA          := VDDATAINI;
          VT_PARAMETROCAB.DATAFIM       := VDDATAFIM;
          VT_PARAMETROCAB.SUBTOTAL      := VNVALORREALIZADO;
          VT_PARAMETROCAB.PERIODICIDADE := VSPERIODICIDADE;

          IF DADOSMETACOMB.TIPOENTIDADE = 'GER' AND
                  (VSPERIODICIDADE NOT IN ('D')) THEN
            BEGIN
              SELECT VALOR, REALIZADO
                INTO VNPREVISTO, VNREALIZADO
                FROM PCGMMETACOMB
               WHERE CODMETA = DADOSMETACOMB.CODMETA
                 AND CODTIPOMETA = DADOSMETACOMB.CODTIPOMETA
                 AND CODINDICADOR = DADOSMETACOMB.CODINDICADOR
                 AND DATA >= VDDATAINI
                 AND DATA <= VDDATAFIM
                 AND DTFECHAMENTO IS NULL;
            EXCEPTION
              WHEN OTHERS THEN
                VNPREVISTO  := 0;
                VNREALIZADO := 0;
            END;

            IF (NVL(VNPREVISTO, 0) = 0) THEN
              IF (NVL(VNREALIZADO, 0) > 0) THEN
                VT_PARAMETROCAB.PERCATINGIDO := F_ObterParametro('PERC_ATINGIDO_REALIZADO_POSITIVO_SEM_VALOR_PREVISTO');
              ELSIF (NVL(VNREALIZADO, 0) < 0) THEN
                VT_PARAMETROCAB.PERCATINGIDO := F_ObterParametro('PERC_ATINGIDO_REALIZADO_NEGATIVO_SEM_VALOR_PREVISTO');
              ELSIF (NVL(VNREALIZADO, 0) = 0) THEN
                VT_PARAMETROCAB.PERCATINGIDO := 0;
              END IF;
            ELSIF (NVL(VNPREVISTO, 0) <> 0) THEN
              VT_PARAMETROCAB.PERCATINGIDO := ROUND(((VNREALIZADO /
                                                    NVL(VNPREVISTO, 0)) * 100),
                                                    2);
            END IF;

          END IF;

        END IF;
        P_AtualizarPCGMMETACOMB(PT_PARAMETRO => VT_PARAMETROCAB);
      END LOOP;
    END;
	PROCEDURE P_ZerarValorPCGMMETACOMB(PNCODMETA IN NUMBER) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      P_CODMETA VARCHAR2(10);
    BEGIN
      P_CODMETA := PNCODMETA;
      EXECUTE IMMEDIATE 'UPDATE PCGMMETACOMB SET REALIZADO = 0, VLFATURADO = 0,PERCATINGIDO = 0, Percpesoindnivelating = 0 WHERE CODMETA = '|| P_CODMETA;
      COMMIT;
    END;
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/RRRR''';

    SELECT PCGMPARAMMETA.CODFILIAL
      INTO VSCODFILIAL
      FROM PCGMMETA, PCGMPARAMMETA
     WHERE 1 = 1
       AND PCGMMETA.CODPARAMMETA = PCGMPARAMMETA.CODIGO
       AND PCGMMETA.CODIGO = PNCODMETA;

    --P_LOG(PNCODMETA||' ; '||VSCODFILIAL||';'||PNCODTIPOMETA||' ; '||PNCODINDICADOR||' ; '||PDDATAINI||' ; '||PDDATAFIM);
       
    BEGIN
      P_DeletarPCGMMETATEMP(VSCODFILIAL);
    EXCEPTION
      WHEN OTHERS THEN -- Tabela Tempor?a n?foi criada
        RAISE e_TabTempNotFound;
    END;
    
    P_CarregarParametros;
    VDDATAINI            := TO_DATE(PDDATAINI, 'DD/MM/RRRR');
    VDDATAFIM            := TO_DATE(PDDATAFIM, 'DD/MM/RRRR');
    VNLISTANUMTRANSVENDA := 0;
    VNCONTADOR           := 0;

    FOR DADOSCOMB in (SELECT DISTINCT METACOMB.*
                        FROM (SELECT PCGMMETACOMB.CODCOMBINACAO,
                                     REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.ITEM),
                                                                    10000,
                                                                    1) CODENTIDADE
                                               FROM PCGMCOMBITEM
                                              WHERE PCGMCOMBITEM.CODIGO =
                                                    PCGMMETACOMB.CODCOMBINACAO
                                              GROUP BY PCGMCOMBITEM.CODIGO),
                                             ',',
                                             ';') CODENTIDADE,
                                     NULL NOMEENTIDADE,
                                     REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.FILTRO),
                                                                    10000,
                                                                    1) TIPOENTIDADE
                                               FROM PCGMCOMBITEM
                                              WHERE PCGMCOMBITEM.CODIGO =
                                                    PCGMMETACOMB.CODCOMBINACAO
                                              GROUP BY PCGMCOMBITEM.CODIGO),
                                             ',',
                                             ';') TIPOENTIDADE,

                                     PCGMMETACOMB.CODMETA,
                                     PCGMMETACOMB.CODTIPOMETA,
                                     PCGMMETACOMB.CODINDICADOR,
                                     PCGMMETACOMB.DATA,
                                     PCGMMETACOMB.VALOR PREVISTO,
                                     PCGMMETACOMB.REALIZADO,
                                     PCGMMETACOMB.DTFECHAMENTO,
                                     PCGMMETACOMB.ITEMNOVOADD,
                                     PCGMPARAMMETA.CODFILIAL,
                                     PCGMPERIODO.PERIODICIDADE,
                                     DECODE(PCGMFILTROTIPOMETA.TIPO,
                                            'GER',
                                            'ZGER',
                                            PCGMFILTROTIPOMETA.TIPO) FILTROTIPOMETA
                                FROM PCGMMETACOMB,
                                     PCGMMETA,
                                     PCGMPARAMMETA,
                                     PCGMINDICADOR,
                                     PCGMPERIODO,
                                     PCGMFILTROTIPOMETA
                               WHERE 1 = 1
                                 AND PCGMMETA.CODPARAMMETA =
                                     PCGMPARAMMETA.CODIGO
                                 AND PCGMMETA.CODIGO = PCGMMETACOMB.CODMETA
                                 AND PCGMFILTROTIPOMETA.CODIGO =
                                     PCGMMETACOMB.CODTIPOMETA
                                 AND PCGMMETACOMB.CODMETA = PCGMMETA.CODIGO
                                 AND PCGMPERIODO.CODIGO =
                                     PCGMPARAMMETA.CODPERIODO
                                 AND PCGMMETACOMB.CODMETA = PNCODMETA
                                    --   AND NVL(PCGMMETACOMB.CODTIPOMETA, PCGMPARAMCOMB.CODTIPOMETA) = DECODE(PNCODTIPOMETA, 0, PCGMMETACOMB.CODTIPOMETA, PNCODTIPOMETA)
                                    --  AND NVL(PCGMMETACOMB.CODINDICADOR, PCGMPARAMCOMB.CODINDICADOR) = DECODE(PNCODINDICADOR, 0, PCGMMETACOMB.CODINDICADOR, PNCODINDICADOR)
                                 AND PCGMMETACOMB.DATA >= VDDATAINI
                                 AND PCGMMETACOMB.DATA <= VDDATAFIM) METACOMB
                       ORDER BY FILTROTIPOMETA) LOOP

      VT_PARAMETRO.CODMETA       := DADOSCOMB.CODMETA;
      VT_PARAMETRO.CODCOMBINACAO := DADOSCOMB.CODCOMBINACAO;
      VT_PARAMETRO.TIPOCHAMADA   := 'META';
      VT_PARAMETRO.DTFECHAMENTO  := DADOSCOMB.DTFECHAMENTO;
      VT_PARAMETRO.CODTIPOMETA   := DADOSCOMB.CODTIPOMETA;
      VT_PARAMETRO.CODINDICADOR  := DADOSCOMB.CODINDICADOR;

      -- TRATA AS FILIAIS CASO SEJA INFORMADO "99" NA PARAMETRIZAÇÃO DA META
      VSCODFILIAL := Chr(39) || DADOSCOMB.CODFILIAL || Chr(39);
      IF NVL(DADOSCOMB.CODFILIAL, '99') = '99' THEN
        FOR FILIAL IN (SELECT * FROM PCFILIAL WHERE CODIGO <> '99') LOOP
          IF VNCONTADOR = 0 THEN
            VSCODFILIAL := '''99''' || ',' || Chr(39) || FILIAL.CODIGO ||
                           Chr(39);
          ELSE
            VSCODFILIAL := VSCODFILIAL || ',' || Chr(39) || FILIAL.CODIGO ||
                           Chr(39);
          END IF;

          VNCONTADOR := VNCONTADOR + 1;
        END LOOP;
      END IF;

      -- ENCONTRA E GRAVA NA TABELA TEMPORÁRIA TODOS OS "NUMTRANSVENDA", DE TODAS AS VENDAS DO PERÍODO
      IF NVL(VNLISTANUMTRANSVENDA, 0) = 0 THEN
        BEGIN
          P_EncontarEGravarTransacao(VSCODFILIAL,
                                     'NUMTRANSVENDA',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     VDDATAINI,
                                     VDDATAFIM,
                                     DADOSCOMB.CODMETA);
          EXECUTE IMMEDIATE 'SELECT COUNT(1) ' ||
                            '  FROM ' || DEF_PCGMMETAGLOBALTEMP(VSCODFILIAL) ||
                            ' WHERE DATA = TRUNC(SYSDATE)'
             INTO VNLISTANUMTRANSVENDA;
        EXCEPTION
          WHEN OTHERS THEN
            VNLISTANUMTRANSVENDA := -1;
        END;
      END IF;

      -------------------------

      VDDATAINI := CASE WHEN(DADOSCOMB.PERIODICIDADE = 'D') /*AND (DADOS_SAIDA.TIPOENTIDADE <> 'GERAL')*/
       THEN DADOSCOMB.DATA ELSE VDDATAINI END;
      VDDATAFIM := CASE WHEN(DADOSCOMB.PERIODICIDADE = 'D') /*AND (DADOS_SAIDA.TIPOENTIDADE <> 'GERAL') */
       THEN DADOSCOMB.DATA ELSE VDDATAFIM END;

      DADOS_SAIDA.TIPOENTIDADE  := NVL(DADOSCOMB.TIPOENTIDADE, 'GERAL');
      DADOS_SAIDA.CODCOMBINACAO := DADOSCOMB.CODCOMBINACAO;
      DADOS_SAIDA.CODENTIDADE   := CASE WHEN DADOS_SAIDA.TIPOENTIDADE = 'GERAL' THEN '0' ELSE DADOSCOMB.CODENTIDADE END;

      VT_RETORNO                    := F_EncontrarNomeEntidade(DADOSCOMB.CODCOMBINACAO,
                                                               DADOSCOMB.CODENTIDADE,
                                                               DADOS_SAIDA.TIPOENTIDADE);
      DADOS_SAIDA.NOMEENTIDADE      := VT_RETORNO.NOMECOMBENTIDADE;
      VSBLOCOSQLCALCREALIZADO       := VT_RETORNO.PSBLOCOSQLCALCREALIZADO;
      VT_PARAMETRO.NOMECOMBENTIDADE := DADOS_SAIDA.NOMEENTIDADE;

      IF (NVL(VNLISTANUMTRANSVENDA, 0) = 0) OR (VNLISTANUMTRANSVENDA = -1) THEN
	    P_ZerarValorPCGMMETACOMB(PNCODMETA);
        DBMS_OUTPUT.put_line('TRANSAÇÃO NÃO ENCONTRADA. CODENTIDADE ' ||
                             DADOSCOMB.CODENTIDADE || ' LINHA ' ||
                             $$PLSQL_LINE);
        EXIT;
      END IF;

      IF DADOSCOMB.DTFECHAMENTO IS NULL THEN
        BEGIN

-------- MUDAR DEPOIS
        P_RetornarFiltroColaborador(PNCODMETA,
                                      VSFILTROCOLABORADOR,
                                      VSCODSUPERVISOR,
                                      VSCODGERENTEREGIONAL,
                                      VSCODGERENTENACIONAL,
                                      VSCODGERENTE,
                                      VSCODUSUR);

         VSBLOCOSQLCALCREALIZADO := NVL(VSBLOCOSQLCALCREALIZADO, ' WHERE 1=1 ') || VSFILTROCOLABORADOR;

          -- ENCONTRANDO O VALOR VENDIDO PELO CODUSUR, CODSUPERVISOR OU CODGERENTE DE UMA DETERMINADO TIPO DE META (FORNECEDOR X PRODUTO)
          VNVALORREALIZADO := F_RetornarRealizado(VSCODFILIAL,
                                                  PNCODMETA,
                                                  DADOSCOMB.CODTIPOMETA,
                                                  DADOSCOMB.CODINDICADOR,
                                                  VSBLOCOSQLCALCREALIZADO,
                                                  VDDATAINI,
                                                  VDDATAFIM,
                                                  VSCODSUPERVISOR,
                                                  VSCODGERENTEREGIONAL,
                                                  VSCODGERENTENACIONAL,
                                                  VSCODGERENTE,
                                                  VSCODUSUR);
        EXCEPTION
          WHEN OTHERS THEN
            VNVALORREALIZADO := 0;
        END;

        VSSQL := 'SELECT NVL(ROUND(SUM(NVL(VLLIQUIDO, 0) - NVL(VLST, 0) - NVL(VLIPI, 0) - NVL(VLFECP, 0)),2),0) VLFATPORPERCOM
                      FROM (SELECT   MOV.*
                              FROM ' || DEF_PCGMMETAGLOBALTEMP(VSCODFILIAL) || ' MOV ' ||
                 VSBLOCOSQLCALCREALIZADO ||
                 ' AND MOV.CODPROD IS NOT NULL
                               AND MOV.CODFILIAL IN(' ||
                 VSCODFILIAL || ')
                               AND DATA >= ''' || VDDATAINI || '''
                               AND DATA <= ''' || VDDATAFIM || '''
                               ) MOV';
        EXECUTE IMMEDIATE VSSQL
          INTO VNVLFATURADORPORIND;

        IF VNVLFATURADORPORIND <> 0 THEN
          P_GRAVARPCGMMETACOMBCOMPLE(VDDATAINI,
                                     VDDATAFIM,
                                     DADOSCOMB.CODCOMBINACAO,
                                     DADOSCOMB.CODMETA,
                                     VSBLOCOSQLCALCREALIZADO,
                                     VSCODFILIAL);
        END IF;

        IF VNVALORREALIZADO <> 0 THEN
          SELECT SUM(S.VLFATPORPERCOM)
            INTO VNVLFATURADORPORIND
            FROM PCGMMETACOMBCOMPLE S
           WHERE CODMETA = DADOSCOMB.CODMETA
             AND CODCOMBINACAO = DADOSCOMB.CODCOMBINACAO
             AND DATA = DADOSCOMB.DATA;
        END IF;

        DADOS_SAIDA.VLFATURADO  := VNVLFATURADORPORIND;
        VT_PARAMETRO.VLFATURADO := DADOS_SAIDA.VLFATURADO;

      ELSE
        VNVALORREALIZADO := DADOSCOMB.REALIZADO;
      END IF;

      DADOS_SAIDA.CODMETA      := DADOSCOMB.CODMETA;
      DADOS_SAIDA.CODTIPOMETA  := DADOSCOMB.CODTIPOMETA;
      DADOS_SAIDA.CODINDICADOR := DADOSCOMB.CODINDICADOR;
      DADOS_SAIDA.DATA         := DADOSCOMB.DATA;
      DADOS_SAIDA.PREVISTO     := CASE WHEN DADOSCOMB.ITEMNOVOADD = 'S' THEN VNVALORREALIZADO ELSE DADOSCOMB.PREVISTO END;
      DADOS_SAIDA.REALIZADO    := VNVALORREALIZADO;
      DADOS_SAIDA.DTFECHAMENTO := DADOSCOMB.DTFECHAMENTO;
      DADOS_SAIDA.CODFILIAL    := DADOSCOMB.CODFILIAL;

      IF DADOSCOMB.ITEMNOVOADD = 'S' THEN
        DADOS_SAIDA.PREVISTO := 0;
      END IF;

      IF (NVL(DADOS_SAIDA.PREVISTO, 0) = 0) THEN
        IF (NVL(DADOS_SAIDA.REALIZADO, 0) > 0) THEN
          DADOS_SAIDA.PERCATINGIDO := F_ObterParametro('PERC_ATINGIDO_REALIZADO_POSITIVO_SEM_VALOR_PREVISTO');
        ELSIF (NVL(DADOS_SAIDA.REALIZADO, 0) < 0) THEN
          DADOS_SAIDA.PERCATINGIDO := F_ObterParametro('PERC_ATINGIDO_REALIZADO_NEGATIVO_SEM_VALOR_PREVISTO');
        ELSIF (NVL(DADOS_SAIDA.REALIZADO, 0) = 0) THEN
          DADOS_SAIDA.PERCATINGIDO := 0;
        END IF;
      ELSIF (NVL(DADOS_SAIDA.PREVISTO, 0) <> 0) THEN
        DADOS_SAIDA.PERCATINGIDO := ROUND(((DADOS_SAIDA.REALIZADO /
                                          NVL(DADOS_SAIDA.PREVISTO, 0)) * 100),
                                          2);
      END IF;

      VT_PARAMETRO.PERCATINGIDO := DADOS_SAIDA.PERCATINGIDO;

      VT_FAIXAPREMIO := F_RetornarFaixaPremio(PNCODMETA      => DADOSCOMB.CODMETA,
                                              PNCODTIPOMETA  => DADOSCOMB.CODTIPOMETA,
                                              PNCODINDICADOR => DADOSCOMB.CODINDICADOR,
                                              PNPERCATINGIDO => DADOS_SAIDA.PERCATINGIDO);

      DADOS_SAIDA.NIVELATINGIDO         := VT_FAIXAPREMIO.NIVELATINGIDO;
      DADOS_SAIDA.PERCPESOINDNIVELATING := NVL(VT_FAIXAPREMIO.PERCPESOINDNIVELATING, 0);
      DADOS_SAIDA.PERCOMCADASTRADO      := 0;
      DADOS_SAIDA.PESOINDICADOR         := VT_FAIXAPREMIO.PESOINDICADOR;
      DADOS_SAIDA.FAIXAINI              := VT_FAIXAPREMIO.FAIXAINI;
      DADOS_SAIDA.FAIXAFIM              := VT_FAIXAPREMIO.FAIXAFIM;

      DADOS_SAIDA.PERCOMCALCPESO := 0;
      DADOS_SAIDA.ITEMNOVOADD    := DADOSCOMB.ITEMNOVOADD;

      VT_PARAMETRO.REALIZADO             := DADOS_SAIDA.REALIZADO;
      VT_PARAMETRO.ITEMNOVOADD           := DADOSCOMB.ITEMNOVOADD;
      VT_PARAMETRO.PERCPESOINDNIVELATING := NVL(DADOS_SAIDA.PERCPESOINDNIVELATING, 0);
      VT_PARAMETRO.DATA                  := VDDATAINI;
      VT_PARAMETRO.FAIXAINI              := DADOS_SAIDA.FAIXAINI;
      VT_PARAMETRO.FAIXAFIM              := DADOS_SAIDA.FAIXAFIM;

      IF DADOSCOMB.DTFECHAMENTO IS NULL THEN
        P_AtualizarPCGMMETACOMB(PT_PARAMETRO => VT_PARAMETRO);
      END IF;
      
      P_AtualizarDtUltProcessamento(VT_PARAMETRO.CODMETA,
                                    VT_PARAMETRO.CODTIPOMETA,
                                    VT_PARAMETRO.CODINDICADOR);

      IF NOT ((DADOS_SAIDA.PREVISTO = 0) AND (DADOS_SAIDA.REALIZADO = 0)) THEN
        PIPE ROW(DADOS_SAIDA);
      END IF;

      IF (DADOS_SAIDA.TIPOENTIDADE = 'GERAL') AND (PNCODTIPOMETA <> 0) THEN
        EXIT;
      END IF;
    END LOOP;

    ATUALIZASUBTOTAL(PNCODMETA, PNCODTIPOMETA, PNCODINDICADOR, VSCODFILIAL);
    --P_DeletarPCGMMETATEMP;

    --P_LOG(PNCODMETA||' ; '||VSCODFILIAL||';'||'FIM');
    
    RETURN;
  EXCEPTION
    WHEN e_TabTempNotFound THEN
      NULL;
      --P_LOG(PNCODMETA||' ; '||VSCODFILIAL||';'||'SEM TABELA TEMPORARIA');
  END APURACAOMETA;

  FUNCTION APURACAOPREMIO(PNCODMETA       IN NUMBER,
                          PSCODENTIDADE   IN VARCHAR2 DEFAULT '',
                          PSTIPOBONUS     IN VARCHAR2,
                          PNSOMAPESONIVEL IN NUMBER,
                          PDDATAINI       IN DATE,
                          PDDATAFIM       IN DATE) RETURN TB_PCGMMETACOMB
    PIPELINED IS
    DADOS_SAIDA TR_PCGMMETACOMB;

    VSBLOCOSQLCALCREALIZADO VARCHAR2(32000);
    VDDATAINI               DATE;
    VDDATAFIM               DATE;
    VT_REMUNERACAOVARIAVEL  TR_PCGMMETACOMB;
    --    TYPE T_PCGMINDICADOR IS TABLE OF PCGMINDICADOR%ROWTYPE INDEX BY PLS_INTEGER;
    DADOSVENDA      TB_PCGMINDICADOR;
    VNCONTINDICADOR NUMBER;
    VNVLDEVOLUCAO   NUMBER := 0;
    VNVLFATURADO    NUMBER := 0;

    VNVLCOMISSAOPORIND NUMBER := 0;
    VT_PARAMETRO       TR_PARAMETRO;
    VNCONTACOMB        NUMBER;
    VNPERCOMPORIND     NUMBER := 0;
    VT_RETORNO         TR_RETORNO;
	PROCEDURE P_ZerarValorPCGMMETACOMBCOMPLE(PNCODMETA IN NUMBER,
                                           PNCOMBINACAO IN NUMBER) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      P_CODMETA VARCHAR2(10);
    BEGIN
      P_CODMETA := PNCODMETA;
      EXECUTE IMMEDIATE 'UPDATE PCGMMETACOMBCOMPLE SET PERCOMMOV = 0, Vlfatporpercom = 0 WHERE CODMETA = '|| P_CODMETA ||' AND CODCOMBINACAO = '||PNCOMBINACAO;
      COMMIT;
    END;    
  
  BEGIN

    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/RRRR''';
    EXECUTE IMMEDIATE 'ALTER SESSION  SET NLS_NUMERIC_CHARACTERS= '',.''';
    VDDATAINI := TO_DATE(PDDATAINI, 'DD/MM/RRRR');
    VDDATAFIM := TO_DATE(PDDATAFIM, 'DD/MM/RRRR');

    FOR DADOSMETACOMB IN (SELECT *
                            FROM (SELECT PCGMMETACOMB.CODCOMBINACAO,
                                         REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.ITEM),
                                                                        10000,
                                                                        1) CODENTIDADE
                                                   FROM PCGMCOMBITEM
                                                  WHERE PCGMCOMBITEM.CODIGO =
                                                        PCGMMETACOMB.CODCOMBINACAO
                                                  GROUP BY PCGMCOMBITEM.CODIGO),
                                                 ',',
                                                 ';') CODENTIDADE,
                                         REPLACE((SELECT DBMS_LOB.SUBSTR(CONCAT_COLUNA(PCGMCOMBITEM.FILTRO),
                                                                        10000,
                                                                        1) TIPOENTIDADE
                                                   FROM PCGMCOMBITEM
                                                  WHERE PCGMCOMBITEM.CODIGO =
                                                        PCGMMETACOMB.CODCOMBINACAO
                                                  GROUP BY PCGMCOMBITEM.CODIGO),
                                                 ',',
                                                 ';') TIPOENTIDADE,
                                         DATA,
                                         CODMETA,
                                         CODTIPOMETA,
                                         CODINDICADOR,
                                         VALOR PREVISTO,
                                         NVL(REALIZADO, 0) REALIZADO,
                                         DTFECHAMENTO,
                                         DTPREMIACAO,
                                         ITEMNOVOADD,
                                         NVL(PERCATINGIDO, 0) PERCATINGIDO,
                                         VLFATURADO,
                     NVL(PCGMMETACOMB.PERCPESOINDNIVELATING, 0) PERCPESOINDNIVELATING
                                    FROM PCGMMETACOMB
                                   WHERE PCGMMETACOMB.CODMETA = PNCODMETA
                                     AND PCGMMETACOMB.DATA >= VDDATAINI
                                     AND PCGMMETACOMB.DATA <= VDDATAFIM
                                     AND (PCGMMETACOMB.CODTIPOMETA,
                                          PCGMMETACOMB.CODINDICADOR) IN
                                         (SELECT DISTINCT PCGMPARAMCOMB .CODTIPOMETA,
                                                          PCGMPARAMCOMB .CODINDICADOR
                                            FROM PCGMPARAMMETA,
                                                 PCGMPREMIO,
                                                 PCGMPERFIL,
                                                 PCGMPREMIONIVEL,
                                                 PCGMPREMIOCOMB,
                                                 PCGMPARAMCOMB
                                           WHERE PCGMPARAMMETA.CODIGO =
                                                 PCGMPREMIO.CODPARAMMETA
                                             AND PCGMPARAMMETA.CODPERFIL =
                                                 PCGMPERFIL.CODIGO
                                             AND PCGMPREMIO.CODIGO =
                                                 PCGMPREMIOCOMB.CODPREMIO
                                             AND PCGMPREMIOCOMB.CODIGO =
                                                 PCGMPREMIONIVEL.CODIGO
                                             AND PCGMPREMIOCOMB.CODPARAMCOMB =
                                                 PCGMPARAMCOMB.CODIGO
                                             AND PCGMPREMIO.DATAEXCLUSAO IS NULL
                                             AND PCGMPARAMMETA.CODIGO =
                                                 (SELECT PCGMMETA.CODPARAMMETA
                                                    FROM PCGMMETA
                                                   WHERE CODIGO =
                                                         PCGMMETACOMB.CODMETA)))
                           WHERE TRIM(NVL(CODENTIDADE, '0')) =
                                 TRIM(DECODE(PSCODENTIDADE,
                                             '-1',
                                             NVL(CODENTIDADE, '0'),
                                             PSCODENTIDADE))) LOOP

      IF PSTIPOBONUS IN ('R', '') THEN
        DADOS_SAIDA.CODCOMBINACAO := DADOSMETACOMB.CODCOMBINACAO;
        DADOS_SAIDA.CODMETA       := PNCODMETA;
        DADOS_SAIDA.CODTIPOMETA   := DADOSMETACOMB.CODTIPOMETA;
        DADOS_SAIDA.CODINDICADOR  := DADOSMETACOMB.CODINDICADOR;
        DADOS_SAIDA.TIPOENTIDADE  := NVL(DADOSMETACOMB.TIPOENTIDADE, 'GER');

        VT_RETORNO               := F_EncontrarNomeEntidade(DADOSMETACOMB.CODCOMBINACAO,
                                                            DADOSMETACOMB.CODENTIDADE,
                                                            DADOS_SAIDA.TIPOENTIDADE);
        DADOS_SAIDA.NOMEENTIDADE := VT_RETORNO.NOMECOMBENTIDADE;
        VSBLOCOSQLCALCREALIZADO  := VT_RETORNO.PSBLOCOSQLCALCREALIZADO;

        DADOS_SAIDA.NOMEENTIDADE  := CASE WHEN DADOS_SAIDA.TIPOENTIDADE = 'GER' THEN 'GERAL' ELSE DADOS_SAIDA.NOMEENTIDADE END;
        DADOS_SAIDA.CODENTIDADE   := CASE WHEN DADOS_SAIDA.TIPOENTIDADE = 'GER' THEN '0' ELSE DADOSMETACOMB.CODENTIDADE END;
        DADOS_SAIDA.CODCOMBINACAO := 0;
        DADOS_SAIDA.DATA          := DADOSMETACOMB.DATA;
        DADOS_SAIDA.PREVISTO      := DADOSMETACOMB.PREVISTO;
        DADOS_SAIDA.REALIZADO     := DADOSMETACOMB.REALIZADO;
        DADOS_SAIDA.DTFECHAMENTO  := DADOSMETACOMB.DTFECHAMENTO;
        IF (DADOSMETACOMB.PERCATINGIDO IS NULL) THEN
          DADOS_SAIDA.PERCATINGIDO := ROUND(CASE WHEN NVL(DADOS_SAIDA.PREVISTO, 0) = 0 THEN 0 ELSE ROUND(((DADOS_SAIDA.REALIZADO / NVL(DADOS_SAIDA.PREVISTO, 0)) * 100), 2) END, 2);
        ELSE
          DADOS_SAIDA.PERCATINGIDO := DADOSMETACOMB.PERCATINGIDO;
        END IF;

        VT_REMUNERACAOVARIAVEL := F_RetornarFaixaPremio(PNCODMETA      => DADOSMETACOMB.CODMETA,
                                                        PNCODTIPOMETA  => DADOSMETACOMB.CODTIPOMETA,
                                                        PNCODINDICADOR => DADOSMETACOMB.CODINDICADOR,
                                                        PNPERCATINGIDO => DADOS_SAIDA.PERCATINGIDO);

        SELECT COUNT(1)
          INTO VNCONTINDICADOR
          FROM PCGMMETACOMB
         WHERE CODMETA = DADOS_SAIDA.CODMETA
           AND CODINDICADOR <> 1;
        -- AND CODTIPOMETA = DADOS_SAIDA.CODTIPOMETA
        --AND CODINDICADOR = DADOS_SAIDA.CODINDICADOR;

        DADOS_SAIDA.NIVELATINGIDO         := VT_REMUNERACAOVARIAVEL.NIVELATINGIDO;
        DADOS_SAIDA.PESOINDICADOR         := VT_REMUNERACAOVARIAVEL.PESOINDICADOR; --/ VNCONTINDICADOR;
        --DADOS_SAIDA.PERCPESOINDNIVELATING := NVL(VT_REMUNERACAOVARIAVEL.PERCPESOINDNIVELATING, 0);
    DADOS_SAIDA.PERCPESOINDNIVELATING := NVL(DADOSMETACOMB.PERCPESOINDNIVELATING, 0);
        DADOS_SAIDA.FAIXAINI              := VT_REMUNERACAOVARIAVEL.FAIXAINI;
        DADOS_SAIDA.FAIXAFIM              := VT_REMUNERACAOVARIAVEL.FAIXAFIM;

        VNVLCOMISSAOPORIND := 0;
        VNVLFATURADO       := 0;
        VNPERCOMPORIND     := 0;
        FOR CALCCOMISSAO IN (SELECT *
                               FROM PCGMMETACOMBCOMPLE
                              WHERE DATA = VDDATAINI
                                AND CODCOMBINACAO =
                                    DADOSMETACOMB.CODCOMBINACAO
                                AND CODMETA = DADOSMETACOMB.CODMETA
                              ORDER BY PERCOMMOV) LOOP

          VNVLCOMISSAOPORIND := VNVLCOMISSAOPORIND +
                                ((NVL(CALCCOMISSAO.VLFATPORPERCOM, 0) *
                                ((NVL(CALCCOMISSAO.PERCOMMOV, 0) *
                                NVL(DADOS_SAIDA.PERCPESOINDNIVELATING, 0)) / 100)) / 100);
          VNVLFATURADO       := VNVLFATURADO +
                                NVL(CALCCOMISSAO.VLFATPORPERCOM, 0);
          VNPERCOMPORIND     := NVL(VNPERCOMPORIND, 0) +
                                ((NVL(CALCCOMISSAO.PERCOMMOV, 0) *
                                 NVL(DADOS_SAIDA.PERCPESOINDNIVELATING, 0)) / 100);

        END LOOP;

        --VNVLFATURADOTOTAL:= VNVLFATURADOTOTAL + VNVLFATURADO ;
        -- FATURADO POR INDICADOR
        DADOS_SAIDA.VLFATURADO := DADOSMETACOMB.VLFATURADO; --VNVLFATURADO; --(VNVLFATURADO * DADOS_SAIDA.PERCPESOINDNIVELATING) / 100;
        -- COMISSAO POR INDICADOR
        DADOS_SAIDA.VLCOMISSAO := VNVLCOMISSAOPORIND;
        -- PERCENTUAL DE COMISSÃO REAL POR INDICADOR
        DADOS_SAIDA.PERCOMCALCPESO := VNPERCOMPORIND;

        SELECT COUNT(1)
          INTO VNCONTACOMB
          FROM PCGMMETACOMB
         WHERE CODMETA = PNCODMETA
           AND CODTIPOMETA = DADOSMETACOMB.CODTIPOMETA
           AND CODINDICADOR = DADOSMETACOMB.CODINDICADOR;

        /*        VT_PCGMINDICADOR.CODTIPOMETA  := DADOSMETACOMB.CODTIPOMETA;
        VT_PCGMINDICADOR.CODINDICADOR := DADOSMETACOMB.CODINDICADOR;
        VT_PCGMINDICADOR.VLCOMISSAO   := DADOS_SAIDA.VLCOMISSAO;-- / VNCONTACOMB;
        VT_PCGMINDICADOR.VLFATURADO   := DADOS_SAIDA.VLFATURADO;*/

        VT_PARAMETRO.CODTIPOMETA  := DADOSMETACOMB.CODTIPOMETA;
        VT_PARAMETRO.CODINDICADOR := DADOSMETACOMB.CODINDICADOR;
        VT_PARAMETRO.VLCOMISSAO   := DADOS_SAIDA.VLCOMISSAO; -- / VNCONTACOMB;
        VT_PARAMETRO.VLFATURADO   := DADOSMETACOMB.VLFATURADO;
        VT_PARAMETRO.PERCOMPORIND := DADOS_SAIDA.PERCOMCALCPESO;
        VT_PARAMETRO.FAIXAINI     := DADOS_SAIDA.FAIXAINI;
        VT_PARAMETRO.FAIXAFIM     := DADOS_SAIDA.FAIXAFIM;

        IF DADOSMETACOMB.DTPREMIACAO IS NULL THEN
          VT_PARAMETRO.CODMETA               := DADOSMETACOMB.CODMETA;
          VT_PARAMETRO.CODCOMBINACAO         := DADOSMETACOMB.CODCOMBINACAO;
          VT_PARAMETRO.DATA                  := VDDATAINI;
          VT_PARAMETRO.PERCPESOINDNIVELATING := NVL(DADOS_SAIDA.PERCPESOINDNIVELATING, 0);
          VT_PARAMETRO.TIPOCHAMADA           := 'PREMIO';
          VT_PARAMETRO.SUBTOTAL              := NULL;
          P_AtualizarPCGMMETACOMB(PT_PARAMETRO => VT_PARAMETRO);

        END IF;

        IF --NVL(DADOS_SAIDA.PERCPESOINDNIVELATING, 0) <> 0 THEN
         --(NOT  ((DADOSMETACOMB.PREVISTO = 0) AND (DADOSMETACOMB.REALIZADO = 0))) then
     (NOT ((DADOSMETACOMB.PREVISTO IS NULL) AND (DADOSMETACOMB.REALIZADO IS NULL))) then
          PIPE ROW(DADOS_SAIDA);
        END IF;
      ELSIF PSTIPOBONUS = 'C' THEN
        VNVLDEVOLUCAO := 0;
        FOR DADOSVENDA IN (SELECT *
                             FROM PCGMMETACOMBCOMPLE
                            WHERE DATA = VDDATAINI
                              AND CODCOMBINACAO =
                                  DADOSMETACOMB.CODCOMBINACAO
                              AND CODMETA = DADOSMETACOMB.CODMETA
                            ORDER BY VLFATPORPERCOM) LOOP

          DADOS_SAIDA.CODMETA      := PNCODMETA;
          DADOS_SAIDA.CODTIPOMETA  := DADOSMETACOMB.CODTIPOMETA;
          DADOS_SAIDA.CODINDICADOR := DADOSMETACOMB.CODINDICADOR;
          DADOS_SAIDA.TIPOENTIDADE := NVL(DADOSMETACOMB.TIPOENTIDADE, 'GER');

          /*          DADOS_SAIDA.NOMEENTIDADE := ENCONTRA_NOME_ENTIDADE(DADOSMETACOMB.CODCOMBINACAO,
          DADOSMETACOMB.CODENTIDADE,
          DADOSMETACOMB.TIPOENTIDADE,
          VSBLOCOSQLCALCREALIZADO);*/
          VT_RETORNO               := F_EncontrarNomeEntidade(DADOSMETACOMB.CODCOMBINACAO,
                                                              DADOSMETACOMB.CODENTIDADE,
                                                              DADOS_SAIDA.TIPOENTIDADE);
          DADOS_SAIDA.NOMEENTIDADE := VT_RETORNO.NOMECOMBENTIDADE;
          VSBLOCOSQLCALCREALIZADO  := VT_RETORNO.PSBLOCOSQLCALCREALIZADO;

          DADOS_SAIDA.NOMEENTIDADE := CASE WHEN DADOS_SAIDA.TIPOENTIDADE = 'GER' THEN 'GERAL' ELSE DADOS_SAIDA.NOMEENTIDADE END;
          DADOS_SAIDA.CODENTIDADE  := CASE WHEN DADOS_SAIDA.TIPOENTIDADE = 'GER' THEN '0' ELSE DADOSMETACOMB.CODENTIDADE END;

          /*  IF DADOSVENDA.VLFATPORPERCOM < 0 then
             VNVLDEVOLUCAO := VNVLDEVOLUCAO + DADOSVENDA.VLFATPORPERCOM;
          ELSE
             DADOS_SAIDA.VLFATURADO        := DADOSVENDA.VLFATPORPERCOM + VNVLDEVOLUCAO;
          END IF;*/

          DADOS_SAIDA.VLFATURADO := DADOSVENDA.VLFATPORPERCOM;

          DADOS_SAIDA.PERCOMCADASTRADO      := DADOSVENDA.PERCOMMOV;
          DADOS_SAIDA.PERCPESOINDNIVELATING := NVL(PNSOMAPESONIVEL, 0);
    
          IF DADOSMETACOMB.REALIZADO > 0 THEN
			DADOS_SAIDA.PERCOMCALCPESO        := DADOS_SAIDA.PERCOMCADASTRADO *
                                               (PNSOMAPESONIVEL / 100);
			DADOS_SAIDA.VLCOMISSAO            := DADOS_SAIDA.VLFATURADO *
                                               (DADOS_SAIDA.PERCOMCALCPESO / 100);
          ELSE
            DADOS_SAIDA.PERCOMCALCPESO        := 0;
            DADOS_SAIDA.VLCOMISSAO            := 0;
            P_ZERARVALORPCGMMETACOMBCOMPLE(DADOSMETACOMB.CODMETA,DADOSMETACOMB.CODCOMBINACAO);
          END IF;											   
          IF (NVL(DADOS_SAIDA.VLFATURADO, 0) <> 0) --OR
          --(NOT((DADOSMETACOMB.PREVISTO = 0) AND (DADOSMETACOMB.REALIZADO = 0)))/* and (DADOSVENDA.VLFATPORPERCOM > 0) */
           THEN
            PIPE ROW(DADOS_SAIDA);
          END IF;
        END LOOP;
      END IF;

    END LOOP;
    RETURN;
  END APURACAOPREMIO;

END PKG_GESTAOMETA;
