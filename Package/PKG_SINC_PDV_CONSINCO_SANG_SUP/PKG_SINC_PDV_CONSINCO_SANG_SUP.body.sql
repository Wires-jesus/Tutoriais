CREATE OR REPLACE PACKAGE BODY PKG_SINC_PDV_CONSINCO_SANG_SUP IS

PROCEDURE PROCESSAR_SANGRIA_SUPRIMENTO(P_SEQDOCTO NUMBER DEFAULT 0) IS
    CURSOR C_SANGRIA_SUPRIMENTO(PNESPECIE VARCHAR2) IS
      SELECT '0' NUMPEDECF,
             A.CODBANCO,
             A.DTLANC,
             A.NUMCAIXA,
             A.NUMVALE,
             A.TIPO,
             A.HISTORICO,
             A.CODFUNC,
             NULL CODUSURAUTORI,
             A.DTMOVIMENTOCX,
             A.NUMFECHAMENTOMOVCX,
             A.VALOR,
             A.CODCOB,
             '0' NUMMALOTE,
             '0' NUMLACRE,
             A.IDEXTERNO,
             A.ESPECIE,
             A.CODFILIAL,
             A.ROWID_TB_DOCTO,
             CASE WHEN TIPO = 'A' THEN 'SANG' ELSE 'SUP' END TIPOOPERACAO
        FROM VW_INT_C5_VALES A
       WHERE A.TIPO IN ('A', 'U')
         AND A.SEQDOCTO = DECODE(P_SEQDOCTO, 0, A.SEQDOCTO, P_SEQDOCTO);  

    R_SANGRIA_SUPRIMENTO C_SANGRIA_SUPRIMENTO%ROWTYPE;
    MENSAGEMERRO         VARCHAR2(1000);
    DADOS_PCFILAMENSAGEM PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;

    FUNCTION RETORNAR_XML_SANGRIA(P_R_SANGRIA_SUPRIMENTO C_SANGRIA_SUPRIMENTO%ROWTYPE)
      RETURN XMLTYPE IS
      L_XMLTYPEESQUEMA XMLTYPE;
    BEGIN
      SELECT XMLELEMENT("ESQUEMAEXPORTACAO",
                        XMLELEMENT("COMPLEMENTO",
                                   XMLELEMENT("PCVALECXECF",
                                              XMLAGG(XMLELEMENT("PCVALECXECF",
                                                                XMLFOREST(P_R_SANGRIA_SUPRIMENTO.NUMPEDECF AS
                                                                          "NUMPEDECF",
                                                                          P_R_SANGRIA_SUPRIMENTO.CODBANCO AS
                                                                          "CODBANCO",
                                                                          P_R_SANGRIA_SUPRIMENTO.DTLANC AS
                                                                          "DTLANC",
                                                                          P_R_SANGRIA_SUPRIMENTO.CODFILIAL AS
                                                                          "CODFILIAL",
                                                                          P_R_SANGRIA_SUPRIMENTO.NUMCAIXA AS
                                                                          "NUMCAIXA",
                                                                          P_R_SANGRIA_SUPRIMENTO.NUMVALE AS
                                                                          "NUMVALE",
                                                                          P_R_SANGRIA_SUPRIMENTO.TIPO AS
                                                                          "TIPO",
                                                                          P_R_SANGRIA_SUPRIMENTO.HISTORICO AS
                                                                          "HISTORICO",
                                                                          P_R_SANGRIA_SUPRIMENTO.CODFUNC AS
                                                                          "CODFUNC",
                                                                          P_R_SANGRIA_SUPRIMENTO.CODUSURAUTORI AS
                                                                          "CODUSURAUTORI",
                                                                          P_R_SANGRIA_SUPRIMENTO.DTMOVIMENTOCX AS
                                                                          "DTMOVIMENTOCX",
                                                                          P_R_SANGRIA_SUPRIMENTO.NUMFECHAMENTOMOVCX AS
                                                                          "NUMFECHAMENTOMOVCX",
                                                                          P_R_SANGRIA_SUPRIMENTO.VALOR AS
                                                                          "VALOR",
                                                                          P_R_SANGRIA_SUPRIMENTO.CODCOB AS
                                                                          "CODCOB",
                                                                          P_R_SANGRIA_SUPRIMENTO.NUMMALOTE AS
                                                                          "NUMMALOTE",
                                                                          P_R_SANGRIA_SUPRIMENTO.NUMLACRE AS
                                                                          "NUMLACRE",
                                                                          P_R_SANGRIA_SUPRIMENTO.IDEXTERNO AS
                                                                          "IDEXTERNO")))))) PCVALECXECF
        INTO L_XMLTYPEESQUEMA
        FROM DUAL;

      RETURN L_XMLTYPEESQUEMA;
    END RETORNAR_XML_SANGRIA;

    FUNCTION RETORNAR_PCFILAMENSAGEM(P_R_SANGRIA C_SANGRIA_SUPRIMENTO%ROWTYPE) RETURN PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM IS
      DADOS_PCFILAMENSAGEM PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;
      L_XMLTYPE            XMLTYPE;
      VSANGRIA             C_SANGRIA_SUPRIMENTO%ROWTYPE;
      DAODOSCABECALHOXML   VARCHAR2(200) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
    BEGIN
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM := DFSEQ_PCFILAMENSAGEM.NEXTVAL;
      VSANGRIA                                          := P_R_SANGRIA;
      VSANGRIA.NUMVALE                                  := DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM ||
                                                           P_R_SANGRIA.NUMVALE;

      -- RECEBE XML DA SANGRIA
      L_XMLTYPE := RETORNAR_XML_SANGRIA(VSANGRIA);

      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATATRANSACAO       := P_R_SANGRIA.DTLANC;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODFILIAL           := P_R_SANGRIA.CODFILIAL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMCAIXA            := P_R_SANGRIA.NUMCAIXA;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMNOTA             := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.SERIE               := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CHAVESEFAZ          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PROTOCOLO           := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CONTINGENCIA        := 'N';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDEXTERNO           := DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM || '-' ||
                                                                    P_R_SANGRIA.NUMVALE || '-' ||
                                                                    P_R_SANGRIA.NUMCAIXA || '-' ||
                                                                    P_R_SANGRIA.ESPECIE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.STATUS              := 0;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTPROCESSAMENTO     := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPODOCUMENTO       := 'OD';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOOPERACAO        := P_R_SANGRIA.TIPOOPERACAO;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.MENSAGEM            := REPLACE(L_XMLTYPE.GETCLOBVAL(),
                                                                            '<EsquemaExportacao>',
                                                                            DAODOSCABECALHOXML);
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOMENSAGEM        := 1;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODIGOERRO          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATAULTIMAALTERACAO := SYSDATE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PDVORIGEM           := 'CONSINCO';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTREPROCESSADO      := NULL;

      RETURN DADOS_PCFILAMENSAGEM;
    END RETORNAR_PCFILAMENSAGEM;
  BEGIN
    OPEN C_SANGRIA_SUPRIMENTO('SG');

    FETCH C_SANGRIA_SUPRIMENTO
      INTO R_SANGRIA_SUPRIMENTO;

    WHILE C_SANGRIA_SUPRIMENTO%FOUND LOOP
      BEGIN
        DADOS_PCFILAMENSAGEM := RETORNAR_PCFILAMENSAGEM(R_SANGRIA_SUPRIMENTO);
        PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM(DADOS_PCFILAMENSAGEM);

        UPDATE MONITORPDVMIDDLE.TB_DOCTO
           SET REPLICACAO = 'F'
         WHERE ROWID = R_SANGRIA_SUPRIMENTO.ROWID_TB_DOCTO;

        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          MENSAGEMERRO := 'CONSINCO - ERRO AO PERSISTIR SANGRIA NA TABELA PCFILAMENSAGEM - ERROR: ' ||
                          SQLCODE || '-' || SQLERRM || '- LINHA: ' ||
                          DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

          UPDATE MONITORPDVMIDDLE.TB_DOCTO
             SET REPLICACAO = 'E'
           WHERE ROWID = R_SANGRIA_SUPRIMENTO.ROWID_TB_DOCTO;

          PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM_ERRO(DADOS_PCFILAMENSAGEM, MENSAGEMERRO);
      END;

      FETCH C_SANGRIA_SUPRIMENTO
        INTO R_SANGRIA_SUPRIMENTO;
    END LOOP;

    CLOSE C_SANGRIA_SUPRIMENTO;
  END PROCESSAR_SANGRIA_SUPRIMENTO;

END PKG_SINC_PDV_CONSINCO_SANG_SUP;
