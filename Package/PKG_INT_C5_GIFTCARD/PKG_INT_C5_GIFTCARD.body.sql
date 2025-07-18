CREATE OR REPLACE PACKAGE BODY PKG_INT_C5_GIFTCARD IS

  PROCEDURE PROCESSAR_GIFTCARD(P_SEQDOCTO NUMBER DEFAULT 0, P_NROCHECKOUT NUMBER DEFAULT 0, P_NROEMPRESA NUMBER DEFAULT 0) IS
    CURSOR C_GIFTCARD IS
      SELECT A.*,
           DEFSEQ_NUMPEDECF.NEXTVAL NUMPEDECF,
           C5.CODFILIAL
       FROM VW_INT_C5_GIFTCARD A,
            VW_INT_C5_OBTER_FILIAIS_C5 C5
       WHERE C5.CODFILIALINTEGRACAO = A.NROEMPRESA
       AND   A.SEQDOCTO = DECODE(P_SEQDOCTO, 0, A.SEQDOCTO, P_SEQDOCTO)
       AND   A.NROCHECKOUT = DECODE(P_NROCHECKOUT, 0, A.SEQDOCTO, P_NROCHECKOUT)
       AND   A.NROEMPRESA = DECODE(P_NROEMPRESA, 0, A.SEQDOCTO, P_NROEMPRESA)
       AND NOT EXISTS (SELECT 1
                         FROM PCFILAMENSAGEM M
                        WHERE M.SEQDOCTO = A.SEQDOCTO
                          AND M.NUMCAIXA = A.NROCHECKOUT
                          AND M.CODFILIAL = C5.CODFILIAL
                        UNION ALL
                         SELECT 1
                         FROM PCFILAMENSAGEMHISTORICO MH
                        WHERE MH.SEQDOCTO = A.SEQDOCTO
                          AND MH.NUMCAIXA = TO_CHAR(A.NROCHECKOUT)
                          AND MH.CODFILIAL = C5.CODFILIAL
                        UNION ALL
                         SELECT 1
                         FROM PCFILAMENSAGEMERRO ME
                        WHERE ME.SEQDOCTO = A.SEQDOCTO
                          AND ME.NUMCAIXA = A.NROCHECKOUT
                          AND ME.CODFILIAL = C5.CODFILIAL
                      );

    R_GIFTCARD         C_GIFTCARD%ROWTYPE;
    L_XMLTYPE            XMLTYPE;
    MENSAGEMERRO         VARCHAR2(1000);
    DADOS_PCFILAMENSAGEM PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;

    -- PROCESSAR_GIFTCARD ( RETORNAR_XML_GIFTCARD )
    FUNCTION RETORNAR_XML_GIFTCARD(R_GIFTCARD C_GIFTCARD%ROWTYPE)
      RETURN XMLTYPE IS
      L_XMLESQUEMA      XMLTYPE;
      L_GIFTCARD   XMLTYPE;
      L_GIFTCARDPARC   XMLTYPE;

      -- GIFTCARD
      FUNCTION RETORNAR_XMLGIFTCARDCAB(P_GIFTCARD C_GIFTCARD%ROWTYPE)
        RETURN XMLTYPE IS
        L_XMLTYPEGIFTCARD XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("GiftCard" ,XMLELEMENT ("PCVENDAGIFTCARDECF" ,
             XMLFOREST(P_GIFTCARD.Numgiftcard "Numgiftcard",
               P_GIFTCARD.Numpedecf "Numpedecf",
               P_GIFTCARD.Numcaixa "Numcaixa",
               P_GIFTCARD.Numserieequip "Numserieequip",
               P_GIFTCARD.Data "Data",
               P_GIFTCARD.Codfunccx "Codfunccx",
               P_GIFTCARD.Numcoo "Numcoo",
               P_GIFTCARD.Codcli "Codcli",
               P_GIFTCARD.Valor "Valor",
               P_GIFTCARD.Numfechamentomovcx "Numfechamentomovcx",
               P_GIFTCARD.Dtmovimentocx "Dtmovimentocx",
               P_GIFTCARD.Codusur "Codusur")))
        INTO L_XMLTYPEGIFTCARD
    FROM PCCONSUM;


        RETURN L_XMLTYPEGIFTCARD;
      END RETORNAR_XMLGIFTCARDCAB;

    FUNCTION RETORNAR_XMLGIFTCARDPARC(P_GIFTCARD C_GIFTCARD%ROWTYPE)
      RETURN XMLTYPE IS
        L_XMLTYPEGIFTCARD XMLTYPE;
    BEGIN


         SELECT XMLELEMENT("Parcelas",
           XMLAGG(
              XMLELEMENT("PCPRESTECF",
                XMLFOREST(
                           P_GIFTCARD.Numgiftcard "Numgiftcard",
                    'S' "Exportado",
                    P_GIFTCARD.Numpedecf "Numpedecf",
                    ROWNUM "Prestecf",
                    P.Codfunccheckout "Codfunccheckout",
                    P.Numcheckout "Numcheckout",
                    P.Numserieequip "Numserieequip",
                    P.Seqdocto "Duplic",
                    P.Codcli "Codcli",
                    P.Valor "Valor",
                    P.Dtvenc "Dtvenc",
                    P.Codcob "Codcob",
                    P.Dtemissao "Dtemissao",
                    P.Codfilial "Codfilial",
                    P.Status "Status",
                    P.Codusur "Codusur",
                    P.Dtvencorig "Dtvencorig",
                    P.Operacao "Operacao",
                    P.Boleto "Boleto",
                    P.Codsupervisor "Codsupervisor",
                    P.Valororig "Valororig",
                    P.Codcoborig "Codcoborig",
                    P.Vltxboleto "Vltxboleto",
                    P.Codfilialnf "Codfilialnf",
                    P.Numcar "Numcar",
                    P.Numcaixafiscal "Numcaixafiscal",
                    P.Valorcontravale "Valorcontravale",
                    P.Numfechamentomovcx "Numfechamentomovcx",
                    P.Dtmovimentocx "Dtmovimentocx",
                    1 "Codpagtonfce",
                    P.Valorcomtroco "Valorcomtroco",
                    P.Idpagamento "Idpagamento",
                    P.Idpagamento "Idpagamentolocal",
                    P.Codcobsefaz "Codcobsefaz",
					3 "Tipodoc"
        )))) Parcelas
     INTO L_XMLTYPEGIFTCARD
     FROM VW_INT_C5_PCPRESTECF P
     WHERE P.SEQDOCTO = P_GIFTCARD.SEQDOCTO
     AND   P.NROCHECKOUT = P_GIFTCARD.NROCHECKOUT
     AND   P.NROEMPRESA = P_GIFTCARD.NROEMPRESA;

         RETURN L_XMLTYPEGIFTCARD;
    END RETORNAR_XMLGIFTCARDPARC;


    BEGIN
      L_GIFTCARD := RETORNAR_XMLGIFTCARDCAB(R_GIFTCARD);
      L_GIFTCARDPARC := RETORNAR_XMLGIFTCARDPARC(R_GIFTCARD);

      SELECT XMLELEMENT("EsquemaExportacao",
             XMLELEMENT("GiftCards",
               XMLELEMENT("DefinicaoGiftCard",
                 L_GIFTCARD,
                 L_GIFTCARDPARC
               )
             )
           ) ESQUEMAEXPORTACAO
        INTO L_XMLESQUEMA
        FROM PCCONSUM;

      RETURN L_XMLESQUEMA;
    END RETORNAR_XML_GIFTCARD;

    -- PROCESSAR_GIFTCARD( RETORNAR_PCFILAMENSAGEM )
    FUNCTION RETORNAR_PCFILAMENSAGEM(R_GIFTCARD C_GIFTCARD%ROWTYPE)
      RETURN PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM
        IS
          DADOS_PCFILAMENSAGEM PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;
          L_XMLTYPE            XMLTYPE;
          DAODOSCABECALHOXML   VARCHAR2(200) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
      -- RECEBE XML DA VENDA

      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM          := DFSEQ_PCFILAMENSAGEM.NEXTVAL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATATRANSACAO       := SYSDATE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODFILIAL           := R_GIFTCARD.CODFILIAL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMCAIXA            := R_GIFTCARD.NUMCAIXA;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMNOTA             := R_GIFTCARD.NUMCOO;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.SERIE               := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CHAVESEFAZ          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PROTOCOLO           := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CONTINGENCIA        := 'N';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDEXTERNO           := DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.IDMENSAGEM || '-' ||
                                                                    R_GIFTCARD.SEQDOCTO || '-' ||
                                                                    R_GIFTCARD.NUMCAIXA || '-' ||
                                                                    'VC';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.STATUS              := 0;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTPROCESSAMENTO     := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPODOCUMENTO       := 'VC';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOOPERACAO        := 'GIFT';


      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOMENSAGEM        := 1;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODIGOERRO          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATAULTIMAALTERACAO := SYSDATE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PDVORIGEM           := 'PDV SUPERMERCADOS';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTREPROCESSADO      := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.SEQDOCTO            := R_GIFTCARD.SEQDOCTO;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATADOCUMENTO       := TO_DATE(R_GIFTCARD.DTABERTURA, 'YYYY-MM-DD');
      
	  L_XMLTYPE := RETORNAR_XML_GIFTCARD(R_GIFTCARD);

      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.MENSAGEM            := REPLACE(L_XMLTYPE.GETCLOBVAL(),
                                                                            '<EsquemaExportacao>',
                                                                            DAODOSCABECALHOXML);
	  
      RETURN DADOS_PCFILAMENSAGEM;
    END RETORNAR_PCFILAMENSAGEM;

  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

  FOR R_GIFTCARD IN C_GIFTCARD
  LOOP
      BEGIN
        -- INSERE OS DADOS DA PCFILAMENSAGEM
        DADOS_PCFILAMENSAGEM := RETORNAR_PCFILAMENSAGEM(R_GIFTCARD);
        PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM(DADOS_PCFILAMENSAGEM);

      EXCEPTION
        WHEN OTHERS THEN
          MENSAGEMERRO := 'CONSINCO - ERRO AO PERSISTIR O GIFTCARD NA TABELA PCFILAMENSAGEM - ERROR: ' ||
                          SQLCODE || '-' || SQLERRM || '- LINHA: ' ||
                          DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

          PKG_SINC_PDV_CONSINCO_UTIL.INSERIR_PCFILAMENSAGEM_ERRO(DADOS_PCFILAMENSAGEM, MENSAGEMERRO);
      END;


    END LOOP;
  END PROCESSAR_GIFTCARD;
END PKG_INT_C5_GIFTCARD;
