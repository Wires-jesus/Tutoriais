CREATE OR REPLACE PACKAGE BODY PKG_SINC_PDV_CONSINCO_CANCEL IS
    PROCEDURE PROCESSAR_CANCELAMENTO(P_SEQDOCTO NUMBER DEFAULT 0) IS    
    CURSOR C_CANC_CABECALHO IS
      SELECT *
        FROM VW_INT_C5_PCPEDCCANCECF  A
       WHERE A.SEQDOCTO = DECODE(P_SEQDOCTO, 0, A.SEQDOCTO, P_SEQDOCTO);
  
    R_CANC_CABECALHO     C_CANC_CABECALHO%ROWTYPE;
    L_XMLTYPE            XMLTYPE;
    MENSAGEMERRO         VARCHAR2(1000);
    DADOS_PCFILAMENSAGEM PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;
    E_VENDA_NAO_EXISTE EXCEPTION;

    -- RETORNAR_XML_CANC_CABECALHO
    FUNCTION RETORNAR_XML_CANC_CABECALHO(P_R_CANC_CABECALHO C_CANC_CABECALHO%ROWTYPE)
      RETURN XMLTYPE IS
      L_XMLTYPECABECALHO XMLTYPE;
    BEGIN
      SELECT XMLELEMENT("PCPEDCCANCECF",
                        XMLAGG(XMLELEMENT("PCPEDCCANCECF",
                                          XMLFOREST(P_R_CANC_CABECALHO.EXPORTADO AS "EXPORTADO",
                                                    P_R_CANC_CABECALHO.NUMPEDECF AS "NUMPEDECF",
                                                    P_R_CANC_CABECALHO.CODFUNCCX AS "CODFUNCCX",
                                                    P_R_CANC_CABECALHO.NUMCAIXA AS "NUMCAIXA",
                                                    P_R_CANC_CABECALHO.NUMSERIEEQUIP AS "NUMSERIEEQUIP",
                                                    P_R_CANC_CABECALHO.DTCANCELECF AS "DTCANCELECF",
                                                    P_R_CANC_CABECALHO.CODFUNCCANCELECF AS "CODFUNCCANCELECF",
                                                    P_R_CANC_CABECALHO.DATA AS "DATA",
                                                    P_R_CANC_CABECALHO.CODCLI AS "CODCLI",
                                                    P_R_CANC_CABECALHO.CODUSUR AS "CODUSUR",
                                                    P_R_CANC_CABECALHO.CODFILIAL AS "CODFILIAL",
                                                    P_R_CANC_CABECALHO.CODPRACA AS "CODPRACA",
                                                    P_R_CANC_CABECALHO.CODSUPERVISOR AS "CODSUPERVISOR",
                                                    P_R_CANC_CABECALHO.CODPLPAG AS "CODPLPAG",
                                                    P_R_CANC_CABECALHO.NUMCUPOM AS "NUMCUPOM",
                                                    P_R_CANC_CABECALHO.SERIEECF AS "SERIEECF",
                                                    P_R_CANC_CABECALHO.CODCOB AS "CODCOB",
                                                    P_R_CANC_CABECALHO.CONDVENDA AS "CONDVENDA",
                                                    P_R_CANC_CABECALHO.PERCVENDA AS "PERCVENDA",
                                                    P_R_CANC_CABECALHO.CODEMITENTE AS "CODEMITENTE",
                                                    P_R_CANC_CABECALHO.PRAZO1 AS "PRAZO1",
                                                    P_R_CANC_CABECALHO.PRAZO2 AS "PRAZO2",
                                                    P_R_CANC_CABECALHO.PRAZO3 AS "PRAZO3",
                                                    P_R_CANC_CABECALHO.PRAZO4 AS "PRAZO4",
                                                    P_R_CANC_CABECALHO.PRAZO5 AS "PRAZO5",
                                                    P_R_CANC_CABECALHO.PRAZO6 AS "PRAZO6",
                                                    P_R_CANC_CABECALHO.PRAZO7 AS "PRAZO7",
                                                    P_R_CANC_CABECALHO.PRAZO8 AS "PRAZO8",
                                                    P_R_CANC_CABECALHO.PRAZO9 AS "PRAZO9",
                                                    P_R_CANC_CABECALHO.PRAZO10 AS "PRAZO10",
                                                    P_R_CANC_CABECALHO.PRAZO11 AS "PRAZO11",
                                                    P_R_CANC_CABECALHO.PRAZO12 AS "PRAZO12",
                                                    P_R_CANC_CABECALHO.PRAZOMEDIO AS "PRAZOMEDIO",
                                                    P_R_CANC_CABECALHO.DTENTREGA AS "DTENTREGA",
                                                    P_R_CANC_CABECALHO.VLATEND AS "VLATEND",
                                                    P_R_CANC_CABECALHO.VLTABELA AS "VLTABELA",
                                                    P_R_CANC_CABECALHO.VLTOTAL AS "VLTOTAL",
                                                    P_R_CANC_CABECALHO.VLOUTRASDESP AS "VLOUTRASDESP",
                                                    P_R_CANC_CABECALHO.VLDESCONTO AS "VLDESCONTO",
                                                    P_R_CANC_CABECALHO.TIPOVENDA AS "TIPOVENDA",
                                                    P_R_CANC_CABECALHO.VLCUSTOREAL AS "VLCUSTOREAL",
                                                    P_R_CANC_CABECALHO.VLCUSTOFIN AS "VLCUSTOFIN",
                                                    P_R_CANC_CABECALHO.VLCUSTOREP AS "VLCUSTOREP",
                                                    P_R_CANC_CABECALHO.VLCUSTOCONT AS "VLCUSTOCONT",
                                                    P_R_CANC_CABECALHO.TOTPESO AS "TOTPESO",
                                                    P_R_CANC_CABECALHO.TOTVOLUME AS "TOTVOLUME",
                                                    P_R_CANC_CABECALHO.NUMITENS AS "NUMITENS",
                                                    P_R_CANC_CABECALHO.OPERACAO AS "OPERACAO",
                                                    P_R_CANC_CABECALHO.HORA AS "HORA",
                                                    P_R_CANC_CABECALHO.MINUTO AS "MINUTO",
                                                    P_R_CANC_CABECALHO.NUMVIASMAPASEP AS "NUMVIASMAPASEP",
                                                    P_R_CANC_CABECALHO.NUMPED AS "NUMPED",
                                                    P_R_CANC_CABECALHO.NUMCAR AS "NUMCAR",
                                                    P_R_CANC_CABECALHO.NUMTRANSVENDA AS "NUMTRANSVENDA",
                                                    P_R_CANC_CABECALHO.DTFAT AS "DTFAT",
                                                    P_R_CANC_CABECALHO.HORAFAT AS "HORAFAT",
                                                    P_R_CANC_CABECALHO.MINUTOFAT AS "MINUTOFAT",
                                                    P_R_CANC_CABECALHO.IMPORTADO AS "IMPORTADO",
                                                    P_R_CANC_CABECALHO.POSICAORETORNO AS "POSICAORETORNO",
                                                    P_R_CANC_CABECALHO.DTCANCEL AS "DTCANCEL",
                                                    P_R_CANC_CABECALHO.CODFUNCCANCEL AS "CODFUNCCANCEL",
                                                    P_R_CANC_CABECALHO.DTEXPORTACAO AS "DTEXPORTACAO",
                                                    P_R_CANC_CABECALHO.POSICAOPEDIDO AS "POSICAOPEDIDO",
                                                    P_R_CANC_CABECALHO.NUMECF AS "NUMECF",
                                                    P_R_CANC_CABECALHO.TIPOCANCEL AS "TIPOCANCEL",
                                                    P_R_CANC_CABECALHO.NUMCCF AS "NUMCCF",
                                                    P_R_CANC_CABECALHO.OBSERVACAO AS "OBSERVACAO",
                                                    P_R_CANC_CABECALHO.CARTAOCRM AS "CARTAOCRM",
                                                    P_R_CANC_CABECALHO.EXPORTACRM AS "EXPORTACRM",
                                                    P_R_CANC_CABECALHO.CUPOMFECHADO AS "CUPOMFECHADO",
                                                    P_R_CANC_CABECALHO.MOTIVOCANCELAMENTO AS "MOTIVOCANCELAMENTO",
                                                    P_R_CANC_CABECALHO.NUMFECHAMENTOMOVCX AS "NUMFECHAMENTOMOVCX",
                                                    P_R_CANC_CABECALHO.DTMOVIMENTOCX AS "DTMOVIMENTOCX",
                                                    P_R_CANC_CABECALHO.VLACRESRODAPE AS "VLACRESRODAPE",
                                                    P_R_CANC_CABECALHO.NOTADUPLIQUESVC AS "NOTADUPLIQUESVC",
                                                    P_R_CANC_CABECALHO.MD5PAF AS "MD5PAF",
                                                    P_R_CANC_CABECALHO.DOCEMISSAO AS "DOCEMISSAO",
                                                    P_R_CANC_CABECALHO.AMBIENTENFCE AS "AMBIENTENFCE",
                                                    P_R_CANC_CABECALHO.DTEXPORTACAOSERVINT AS "DTEXPORTACAOSERVINT",
                                                    P_R_CANC_CABECALHO.DTIMPORTACAOSERVPRINC AS "DTIMPORTACAOSERVPRINC",
                                                    P_R_CANC_CABECALHO.EXPORTADOSERVINT AS "EXPORTADOSERVINT",
                                                    P_R_CANC_CABECALHO.IMPORTADOSERVPRINC AS "IMPORTADOSERVPRINC",
                                                    P_R_CANC_CABECALHO.ROTINALANC AS "ROTINALANC",
                                                    P_R_CANC_CABECALHO.ASSINATURA AS "ASSINATURA"
                                                    ))))
        INTO L_XMLTYPECABECALHO
        FROM DUAL;

      RETURN L_XMLTYPECABECALHO;
    END RETORNAR_XML_CANC_CABECALHO;
  
    -- RETORNAR_XML_CANC_ITENS
    FUNCTION RETORNAR_XML_CANC_ITENS(P_R_CANC_CABECALHO C_CANC_CABECALHO%ROWTYPE)
      RETURN XMLTYPE IS
      L_XMLTYPEITENS XMLTYPE;
    BEGIN          
 SELECT XMLELEMENT("PCPEDICANCECF",
                        XMLAGG(XMLELEMENT("PCPEDICANCECF",
                                          XMLFOREST('N' AS "EXPORTADO",
                                                    P_R_CANC_CABECALHO.NUMPEDECF AS "NUMPEDECF",
                                                    V.CODFUNCCX,
                                                    V.NUMCAIXA,
                                                    'NOTAFISCAL' AS "NUMSERIEEQUIP",
                                                    V.CODPROD,
                                                    V.NUMSEQ,
                                                    V.DTCANCELECF,
                                                    V.CODFUNCCANCELECF,
                                                    V.DATA,
                                                    P_R_CANC_CABECALHO.CODCLI AS "CODCLI",
                                                    V.CODUSUR,
                                                    V.QT,
                                                    V.PVENDA,
                                                    V.PORIGINAL,
                                                    0 AS "ST",
                                                    0 AS "PERCOM",
                                                    0 AS "PERDESC",
                                                    0 AS "VLCUSTOFIN",
                                                    0 AS "VLCUSTOREAL",
                                                    0 AS "VLCUSTOREP",
                                                    0 AS "VLCUSTOCONT",
                                                    0 AS "QTFALTA",
                                                    V.CODAUXILIAR,
                                                    V.CODST,
                                                    V.CODST AS "CODST",
                                                    V.PORIGINAL,
                                                    0 AS "PERCBASEREDSTFONTE",
                                                    0 AS "VLIPI",
                                                    0 AS "PERCIPI",
                                                    0 AS "PERCBASEREDST",
                                                    0 AS "PERFRETECMV",
                                                    NULL AS "NUMCAR",
                                                    NULL AS "NUMPED",
                                                    'N' AS "IMPORTADO",
                                                    NULL AS "POSICAORETORNO",
                                                    TO_CHAR(V.DTCANCEL, 'YYYY-MM-DD') "DTCANCEL",
                                                    V.CODFUNCCANCEL,
                                                    TO_CHAR(V.DTEXPORTACAO, 'YYYY-MM-DD') AS "DTEXPORTACAO",
                                                    NULL AS "TOTALIZADOR",
                                                    V.CODFILIAL,
                                                    NULL AS "MOTIVOCANCELAMENTO",
                                                    V.CUPOMFECHADO,
                                                    NULL AS "VLDESCRODAPE",
                                                    NULL AS "CANCMANUAL",
                                                    NULL AS "MD5PAF",
                                                    V.CODCEST AS "CODCEST",
                                                    0 AS "NUMCCF",
                                                    V.VLDESCFIN,
                                                    NULL AS "VLOUTRASDESP",
                                                    NULL AS "VLACRESCRODAPE",
                                                    FNC_INT_C5_TIPOCANCEL(V.SEQDOCTO, V.NUMSEQ)                               "TIPOCANCEL",
                                                    NULL AS "DTEXPORTACAOSERVINT",
                                                    NULL AS "DTIMPORTACAOSERVPRINC",
                                                    NULL AS "EXPORTADOSERVINT", 
                                                    NULL AS "IMPORTADOSERVPRINC",
                                                    V.NUMCUPOM AS "NUMCUPOM",
                                                    NULL AS "PERCBASERED",
                                                    NULL AS "PERCICM",
                                                    '2099' AS "ROTINALANC"))))
    INTO L_XMLTYPEITENS                                                    
    FROM VW_INT_C5_PCPEDICANCECF V;
    
      RETURN L_XMLTYPEITENS;
    END RETORNAR_XML_CANC_ITENS;
  
    -- RETORNAR_CANCELAMENTO
    FUNCTION RETORNAR_CANCELAMENTO(P_R_CANC_CABECALHO C_CANC_CABECALHO%ROWTYPE)
      RETURN XMLTYPE IS
      L_XMLESQUEMA   XMLTYPE;
      L_XMLITENS     XMLTYPE;
      L_XMLCABECALHO XMLTYPE;
    BEGIN
      L_XMLCABECALHO := RETORNAR_XML_CANC_CABECALHO(P_R_CANC_CABECALHO);
      L_XMLITENS     := RETORNAR_XML_CANC_ITENS(P_R_CANC_CABECALHO);
    
      SELECT XMLELEMENT("ESQUEMAEXPORTACAO", XMLELEMENT("COMPLEMENTO", L_XMLITENS, L_XMLCABECALHO)) ESQUEMAEXPORTACAO
        INTO L_XMLESQUEMA
        FROM DUAL;
    
      RETURN L_XMLESQUEMA;
    END RETORNAR_CANCELAMENTO;
  
    -- RETORNAR_PCFILAMENSAGEM
    FUNCTION RETORNAR_PCFILAMENSAGEM_CANC(P_R_CANC_CABECALHO C_CANC_CABECALHO%ROWTYPE)
      RETURN PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM IS
      DADOS_PCFILAMENSAGEM PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;
      L_XMLTYPE            XMLTYPE;
      daodoscabecalhoxml   VARCHAR2(200) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
    BEGIN
      -- RECEBE XML PARA CANCELAMENTO
      L_XMLTYPE := RETORNAR_CANCELAMENTO(P_R_CANC_CABECALHO);
    
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM          := DFSEQ_PCFILAMENSAGEM.NEXTVAL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATATRANSACAO       := SYSDATE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODFILIAL           := P_R_CANC_CABECALHO.CODFILIAL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMCAIXA            := P_R_CANC_CABECALHO.NUMCAIXA;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMNOTA             := P_R_CANC_CABECALHO.NUMCUPOM;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.SERIE               := NULL; 
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CHAVESEFAZ          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PROTOCOLO           := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CONTINGENCIA        := 'N';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDEXTERNO           := DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM || '-' || P_R_CANC_CABECALHO.SEQDOCTO || '-' || P_R_CANC_CABECALHO.NUMCAIXA || '-' /*|| P_R_CANC_CABECALHO.ESPECIE*/;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.STATUS              := 0;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTPROCESSAMENTO     := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPODOCUMENTO       := 'CE';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOOPERACAO        := CASE WHEN P_R_CANC_CABECALHO.TIPOCANCEL = 'P' THEN 'CANP' ELSE 'CANT' END;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.MENSAGEM            := REPLACE(L_XMLTYPE.GETCLOBVAL(), '<ESQUEMAEXPORTACAO>', DAODOSCABECALHOXML);
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOMENSAGEM        := 1;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODIGOERRO          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATAULTIMAALTERACAO := SYSDATE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PDVORIGEM           := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTREPROCESSADO      := NULL;
    
      RETURN DADOS_PCFILAMENSAGEM;
    END RETORNAR_PCFILAMENSAGEM_CANC;
  
    PROCEDURE GERAR_VENDA_CASO_NAO_EXISTA(P_R_CANC_CABECALHO C_CANC_CABECALHO%ROWTYPE) IS
      VCONTAVENDA NUMBER;
    
      PROCEDURE VERIFICAR_SE_VENDA_EXISTE IS
      BEGIN
        SELECT SUM(CONTAVENDA)
          INTO VCONTAVENDA
          FROM (SELECT DISTINCT CONTAVENDA
                  FROM (SELECT COUNT(1) CONTAVENDA
                          FROM PCFILAMENSAGEM S
                         WHERE 0 = 0 
                           AND S.IDEXTERNO LIKE  '%-' || P_R_CANC_CABECALHO.SEQDOCTO || '-%'
                           AND CODFILIAL = P_R_CANC_CABECALHO.CODFILIAL
                           AND NUMCAIXA = P_R_CANC_CABECALHO.NUMCAIXA
                           AND S.TIPOOPERACAO = 'VEND'
                           AND TRUNC(DATATRANSACAO) = TRUNC(SYSDATE)
                        UNION ALL
                        SELECT COUNT(1) CONTAVENDA
                          FROM PCFILAMENSAGEMERRO S
                         WHERE 0 = 0 
                           AND S.IDEXTERNO LIKE '%-' || P_R_CANC_CABECALHO.SEQDOCTO || '-%'
                           AND CODFILIAL = P_R_CANC_CABECALHO.CODFILIAL
                           AND NUMCAIXA = P_R_CANC_CABECALHO.NUMCAIXA
                           AND S.TIPOOPERACAO = 'VEND'
                           AND TRUNC(DATATRANSACAO) = TRUNC(SYSDATE)
                        UNION ALL
                        SELECT COUNT(1) CONTAVENDA
                          FROM PCFILAMENSAGEMHISTORICO S
                         WHERE 0 = 0 
                           AND S.IDEXTERNO LIKE                               '%-' || P_R_CANC_CABECALHO.SEQDOCTO || '-%'
                           AND CODFILIAL = P_R_CANC_CABECALHO.CODFILIAL
                           AND NUMCAIXA = P_R_CANC_CABECALHO.NUMCAIXA
                           AND S.TIPOOPERACAO = 'VEND'
                           AND TRUNC(DATATRANSACAO) = TRUNC(SYSDATE)));
      END;
    BEGIN
      VERIFICAR_SE_VENDA_EXISTE;
    
      IF (VCONTAVENDA = 0) THEN
        --ATUALIZA O REGISTRO NA TABELA CONSINCO
        
        UPDATE MONITORPDVMIDDLE.TB_DOCTO S
           SET REPLICACAO = 'P'
         WHERE ROWID = P_R_CANC_CABECALHO.ROWID_TB_DOCTO;
         
      
        UPDATE MONITORPDVMIDDLE.TB_DOCTOCUPOM S
           SET STATUS = 'V'
         WHERE SEQDOCTO = P_R_CANC_CABECALHO.SEQDOCTO
           AND NROCHECKOUT = P_R_CANC_CABECALHO.NUMCAIXA
           AND NROEMPRESA = P_R_CANC_CABECALHO.CODFILIAL
           AND S.STATUS = 'C';
      
        COMMIT;
        
    /*
        PROCESSAR_VENDA(P_R_CANC_CABECALHO.SEQDOCTO,
                        P_R_CANC_CABECALHO.NUMCAIXA,
                        P_R_CANC_CABECALHO.CODFILIAL);
    */              
      
        UPDATE MONITORPDVMIDDLE.TB_DOCTOCUPOM S
           SET STATUS = 'C'
         WHERE SEQDOCTO = P_R_CANC_CABECALHO.SEQDOCTO
           AND NROCHECKOUT = P_R_CANC_CABECALHO.NUMCAIXA
           AND NROEMPRESA = P_R_CANC_CABECALHO.CODFILIAL
           AND S.STATUS = 'V';

        VERIFICAR_SE_VENDA_EXISTE;
      
        IF (VCONTAVENDA = 0) THEN
          RAISE E_VENDA_NAO_EXISTE;
        END IF;
      END IF;
    
      COMMIT;
    END;
  
    PROCEDURE ADICIONARREGRASCABECALHONF(R_CANC_CABECALHO IN OUT C_CANC_CABECALHO%ROWTYPE) IS VNUMPEDECF PCPEDCECF.NUMPEDECF%TYPE;
    BEGIN
      BEGIN
        SELECT NUMPEDECF
          INTO VNUMPEDECF
          FROM PCPEDCECF
         WHERE DATA >= SYSDATE - 10
           AND NUMTRANSVENDA = (SELECT NUMTRANSVENDA
                                  FROM PCNFSAID
                                 WHERE CHAVENFE = R_CANC_CABECALHO.NUMPEDECF
                                   AND DTSAIDA = TRUNC(SYSDATE)
                                   AND ROWNUM = 1);
      EXCEPTION
        WHEN OTHERS THEN
          VNUMPEDECF := 0;
      END;
    
      R_CANC_CABECALHO.NUMPEDECF     := COALESCE(VNUMPEDECF, DEFSEQ_NUMPEDECF.NEXTVAL);
      R_CANC_CABECALHO.CODPRACA      := COALESCE(FNC_INT_C5_PRACA_CLI(R_CANC_CABECALHO.CODCLI), 0);
      R_CANC_CABECALHO.CODSUPERVISOR := NVL(FNC_INT_C5_CODSUPERV(R_CANC_CABECALHO.CODEMITENTE), 1);
      R_CANC_CABECALHO.VLTOTAL       := FNC_INT_C5_CAB_TOTAL(R_CANC_CABECALHO.SEQDOCTO, R_CANC_CABECALHO.NUMCAIXA, R_CANC_CABECALHO.CODFILIAL);
      R_CANC_CABECALHO.VLATEND       := R_CANC_CABECALHO.VLTOTAL;
      R_CANC_CABECALHO.VLTABELA      := R_CANC_CABECALHO.VLTOTAL;
    END;
  BEGIN
    --INÍCIO LOOP C_CANC_CABECALHO
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
  
    OPEN C_CANC_CABECALHO;
  
    FETCH C_CANC_CABECALHO
      INTO R_CANC_CABECALHO;
  
    WHILE C_CANC_CABECALHO%FOUND LOOP
      BEGIN
        GERAR_VENDA_CASO_NAO_EXISTA(R_CANC_CABECALHO);
      
        -- REGRAS DO CABEÇALHO DO CANCELAMENTO
        ADICIONARREGRASCABECALHONF(R_CANC_CABECALHO);
      
        -- INSERE OS DADOS DA PCFILAMENSAGEM
        DADOS_PCFILAMENSAGEM := RETORNAR_PCFILAMENSAGEM_CANC(R_CANC_CABECALHO);
        PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM(DADOS_PCFILAMENSAGEM);
      
        --ATUALIZA O REGISTRO NA TABELA CONSINCO
        UPDATE MONITORPDVMIDDLE.TB_DOCTO
           SET REPLICACAO = 'F'
         WHERE ROWID = R_CANC_CABECALHO.ROWID_TB_DOCTO;                       
        COMMIT;
        
      EXCEPTION
        WHEN E_VENDA_NAO_EXISTE THEN
          MENSAGEMERRO := ' A VENDA NÃO EXISTE PARA O CANCELAMENTO - ERROR: ' || SQLCODE || '-' || SQLERRM || '- LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        
          UPDATE MONITORPDVMIDDLE.TB_DOCTO
             SET REPLICACAO = 'E'
           WHERE ROWID = R_CANC_CABECALHO.ROWID_TB_DOCTO;
           
           COMMIT;
        
          PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM_ERRO(DADOS_PCFILAMENSAGEM, MENSAGEMERRO);
        WHEN OTHERS THEN
          MENSAGEMERRO := 'CONSINCO - ERRO AO PERSISTIR CANC_CABECALHO NA TABELA PCFILAMENSAGEM - ERROR: ' || SQLCODE || '-' || SQLERRM || '- LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        
          UPDATE MONITORPDVMIDDLE.TB_DOCTO
             SET REPLICACAO = 'E'
           WHERE ROWID = R_CANC_CABECALHO.ROWID_TB_DOCTO;
           
           COMMIT;
        
          PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM_ERRO(DADOS_PCFILAMENSAGEM, MENSAGEMERRO);
      END;
    
      FETCH C_CANC_CABECALHO
        INTO R_CANC_CABECALHO;
    END LOOP;
  
    CLOSE C_CANC_CABECALHO;
  
    COMMIT;
    -- FIM LOOP C_CANC_CABECALHO
  END PROCESSAR_CANCELAMENTO;  
END PKG_SINC_PDV_CONSINCO_CANCEL;