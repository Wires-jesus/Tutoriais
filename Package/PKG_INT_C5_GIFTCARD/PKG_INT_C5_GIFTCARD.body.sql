CREATE OR REPLACE PACKAGE BODY PKG_INT_C5_GIFTCARD IS

  PROCEDURE PROCESSAR_GIFTCARD(P_SEQDOCTO NUMBER DEFAULT 0, P_NROCHECKOUT NUMBER DEFAULT 0, P_NROEMPRESA NUMBER DEFAULT 0) IS
    CURSOR C_GIFTCARD IS
      SELECT DEFSEQ_NUMPEDECF.NEXTVAL NUMPEDECF,
             A.SEQDOCTO,
             A.NROEMPRESA,
             A.NUMGIFTCARD,
             A.NROCHECKOUT AS "NUMCAIXA",
             A.DATA,
             A.DTABERTURA,
             A.CODFUNCCX,
             A.COO,
             C5.CODFILIAL CODFILIALWINTHOR,
             P.EXPORTADO AS "EXPORTADO",
             ROWNUM AS "PRESTECF",
             P.PRESTTEF AS "PRESTTEF",
             P.CODFUNCCHECKOUT AS "CODFUNCCHECKOUT",
             P.NUMCHECKOUT AS "NUMCHECKOUT",
             P.NUMSERIEEQUIP AS "NUMSERIEEQUIP",
             P.DUPLIC AS "DUPLIC",
             P.CODCLI AS "CODCLI",
             P.VALOR AS "VALOR",
             P.DTVENC AS "DTVENC",
             P.CODCOB AS "CODCOB",
             P.DTEMISSAO AS "DTEMISSAO",
             P.CODFILIAL AS "CODFILIAL",
             P.STATUS AS "STATUS",
             P.CODUSUR AS "CODUSUR",
             P.DTVENCORIG AS "DTVENCORIG",
             P.OPERACAO AS "OPERACAO",
             P.BOLETO AS "BOLETO",
             P.NUMBANCO AS "NUMBANCO",
             P.NUMAGENCIA AS "NUMAGENCIA",
             P.NUMCHEQUE AS "NUMCHEQUE",
             P.CODSUPERVISOR AS "CODSUPERVISOR",
             P.CODBARRA AS "CODBARRA",
             P.VALORORIG AS "VALORORIG",
             P.CODCOBORIG AS "CODCOBORIG",
             P.VLTXBOLETO AS "VLTXBOLETO",
             P.CODFILIALNF AS "CODFILIALNF",
             P.NUMCONTACORRENTE AS "NUMCONTACORRENTE",
             P.PREST AS "PREST",
             P.NUMCAR AS "NUMCAR",
             P.NUMTRANSVENDA AS "NUMTRANSVENDA",
             P.NUMPED AS "NUMPED",
             P.IMPORTADO AS "IMPORTADO",
             P.DTEXPORTACAO AS "DTEXPORTACAO",
             P.NUMCAIXAFISCAL AS "NUMCAIXAFISCAL",
             P.NSUTEF AS "NSUTEF",
             P.NUMECF AS "NUMECF",
             P.PARCELAMENTOTEF AS "PARCELAMENTOTEF",
             P.PRESTEF AS "PRESTEF",
             P.CODADMCARTAO AS "CODADMCARTAO",
             P.TIPOOPERACAOTEF AS "TIPOOPERACAOTEF",
             P.CODBANDEIRATEF AS "CODBANDEIRATEF",
             P.DTBAIXA AS "DTBAIXA",
             P.CODAUTORIZACAOTEF AS "CODAUTORIZACAOTEF",
             P.NUMCCF AS "NUMCCF",
             P.LINHADIG AS "LINHADIG",
             P.VLMEXIVA AS "VLMEXIVA",
             P.ASSINATURA AS "ASSINATURA",
             P.NUMGNF AS "NUMGNF",
             P.NUMSERIESAT AS "NUMSERIESAT",
             P.CNPJCREDENCCARTAO AS "CNPJCREDENCCARTAO",
             P.NUMCARTAOCRM AS "NUMCARTAOCRM",
             P.NSUHOST AS "NSUHOST",
             P.VALORCONTRAVALE AS "VALORCONTRAVALE",
             P.COMPENSACAOBCO AS "COMPENSACAOBCO",
             P.CGCCPFCH AS "CGCCPFCH",
             P.DVAGENCIA AS "DVAGENCIA",
             P.DVCONTA AS "DVCONTA",
             P.DVCHEQUE AS "DVCHEQUE",
             P.NUMFECHAMENTOMOVCX AS "NUMFECHAMENTOMOVCX",
             P.DTMOVIMENTOCX AS "DTMOVIMENTOCX",
             P.CODAUTORICREDTEF AS "CODAUTORICREDTEF",
             P.DTEMISSAOORIG AS "DTEMISSAOORIG",
             P.CODIGOCONTRAVALE AS "CODIGOCONTRAVALE",
             P.RETORNOCRM1VIA AS "RETORNOCRM1VIA",
             P.RETORNOCRM2VIA AS "RETORNOCRM2VIA",
             P.NUMPROTOCOLOCHQ AS "NUMPROTOCOLOCHQ",
             P.VALORCOMTROCO AS "VALORCOMTROCO",
             P.IDPAGAMENTO AS "IDPAGAMENTO",
             P.SERIALPOS AS "SERIALPOS",
             P.IDRESPFISCAL AS "IDRESPFISCAL",
             P.BANDEIRACARTAO AS "BANDEIRACARTAO",
             P.CODCOBSEFAZ AS "CODCOBSEFAZ",
             P.MD5PAF AS "MD5PAF",
             P.TIPODOC AS "TIPODOC",
             P.DTCXMOT AS "DTCXMOT",
             P.TIPOCORBAN AS "TIPOCORBAN",
             P.AUTORIZACAOPAGAMENTOPONTOS AS "AUTORIZACAOPAGAMENTOPONTOS",
             P.AUTORIZACAOACUMULOPONTOS AS "AUTORIZACAOACUMULOPONTOS",
             P.SOMATXBOLETO AS "SOMATXBOLETO",
             P.CODUSUR2 AS "CODUSUR2",
             P.PROCESSADORTRANSPAGDIGITAL AS "PROCESSADORTRANSPAGDIGITAL",
             P.NUMTRANSPAGDIGITAL AS "NUMTRANSPAGDIGITAL",
             P.NSUPAGDIGITAL AS "NSUPAGDIGITAL",
             P.NOMECARTEIRADIGITAL AS "NOMECARTEIRADIGITAL",
             P.CARTEIRADIGITAL AS "CARTEIRADIGITAL"
       FROM VW_INT_C5_GIFTCARD A,
            VW_INT_C5_PCPRESTECF P,
            VW_INT_C5_OBTER_FILIAIS_C5 C5
       WHERE A.NROEMPRESA = C5.CODFILIALINTEGRACAO
       AND   P.CODFILIALINTEGRACAO = C5.CODFILIALINTEGRACAO
       AND   A.SEQDOCTO = P.SEQDOCTO
       AND   A.NROCHECKOUT = P.NUMCHECKOUT
       AND   A.NROEMPRESA = P.CODFILIALINTEGRACAO
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

      -- GIFTCARD
      FUNCTION RETORNAR_XMLGIFTCARD(P_GIFTCARD C_GIFTCARD%ROWTYPE)
        RETURN XMLTYPE IS
        L_XMLTYPEGIFTCARD XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("DefinicaoGiftCard",
                          XMLAGG(XMLELEMENT("PCVENDAGIFTCARDECF",
                                            XMLFOREST(A.NUMGIFTCARD,
                                                      A.NROCHECKOUT AS "NUMCAIXA",
                                                      A.NUMSERIEEQUIP,
                                                      A.DATA,
                                                      A.CODFUNCCX,
                                                      A.CODCLI,
                                                      A.VALOR,
                                                      A.CODUSUR
                                                      )
                                              )),

                                  XMLELEMENT ("Parcela",
                                   XMLAGG (XMLELEMENT("PCPRESTECF",
                                   XMLFOREST (
                                       P.NUMGIFTCARD AS "NUMGIFTCARD",
                                       P.EXPORTADO AS "EXPORTADO",
                                       P_GIFTCARD.NUMPEDECF AS "NUMPEDECF",
                                       ROWNUM AS "PRESTECF",
                                       P.PRESTTEF AS "PRESTTEF",
                                       P.CODFUNCCHECKOUT AS "CODFUNCCHECKOUT",
                                       P.NUMCHECKOUT AS "NUMCHECKOUT",
                                       P.NUMSERIEEQUIP AS "NUMSERIEEQUIP",
                                       A.COO AS "DUPLIC",
                                       P.CODCLI AS "CODCLI",
                                       P.VALOR AS "VALOR",
                                       P.DTVENC AS "DTVENC",
                                       P.CODCOB AS "CODCOB",
                                       P.DTEMISSAO AS "DTEMISSAO",
                                       C5.CODFILIAL AS "CODFILIAL",
                                       P.STATUS AS "STATUS",
                                       P.CODUSUR AS "CODUSUR",
                                       P.DTVENCORIG AS "DTVENCORIG",
                                       P.OPERACAO AS "OPERACAO",
                                       P.BOLETO AS "BOLETO",
                                       P.NUMBANCO AS "NUMBANCO",
                                       P.NUMAGENCIA AS "NUMAGENCIA",
                                       P.NUMCHEQUE AS "NUMCHEQUE",
                                       P.CODSUPERVISOR AS "CODSUPERVISOR",
                                       P.CODBARRA AS "CODBARRA",
                                       P.VALORORIG AS "VALORORIG",
                                       P.CODCOBORIG AS "CODCOBORIG",
                                       P.VLTXBOLETO AS "VLTXBOLETO",
                                       C5.CODFILIAL AS "CODFILIALNF",
                                       P.NUMCONTACORRENTE AS "NUMCONTACORRENTE",
                                       P.PREST AS "PREST",
                                       P.NUMCAR AS "NUMCAR",
                                       P.NUMTRANSVENDA AS "NUMTRANSVENDA",
                                       P.NUMPED AS "NUMPED",
                                       P.IMPORTADO AS "IMPORTADO",
                                       P.DTEXPORTACAO AS "DTEXPORTACAO",
                                       P.NUMCAIXAFISCAL AS "NUMCAIXAFISCAL",
                                       P.NSUTEF AS "NSUTEF",
                                       P.NUMECF AS "NUMECF",
                                       P.PARCELAMENTOTEF AS "PARCELAMENTOTEF",
                                       P.PRESTEF AS "PRESTEF",
                                       P.CODADMCARTAO AS "CODADMCARTAO",
                                       P.TIPOOPERACAOTEF AS "TIPOOPERACAOTEF",
                                       P.CODBANDEIRATEF AS "CODBANDEIRATEF",
                                       P.DTBAIXA AS "DTBAIXA",
                                       P.CODAUTORIZACAOTEF AS "CODAUTORIZACAOTEF",
                                       P.NUMCCF AS "NUMCCF",
                                       P.LINHADIG AS "LINHADIG",
                                       P.VLMEXIVA AS "VLMEXIVA",
                                       P.ASSINATURA AS "ASSINATURA",
                                       P.NUMGNF AS "NUMGNF",
                                       P.NUMSERIESAT AS "NUMSERIESAT",
                                       P.CNPJCREDENCCARTAO AS "CNPJCREDENCCARTAO",
                                       P.NUMCARTAOCRM AS "NUMCARTAOCRM",
                                       P.NSUHOST AS "NSUHOST",
                                       P.VALORCONTRAVALE AS "VALORCONTRAVALE",
                                       P.COMPENSACAOBCO AS "COMPENSACAOBCO",
                                       P.CGCCPFCH AS "CGCCPFCH",
                                       P.DVAGENCIA AS "DVAGENCIA",
                                       P.DVCONTA AS "DVCONTA",
                                       P.DVCHEQUE AS "DVCHEQUE",
                                       P.NUMFECHAMENTOMOVCX AS "NUMFECHAMENTOMOVCX",
                                       P.DTMOVIMENTOCX AS "DTMOVIMENTOCX",
                                       P.CODAUTORICREDTEF AS "CODAUTORICREDTEF",
                                       P.DTEMISSAOORIG AS "DTEMISSAOORIG",
                                       P.CODIGOCONTRAVALE AS "CODIGOCONTRAVALE",
                                       P.RETORNOCRM1VIA AS "RETORNOCRM1VIA",
                                       P.RETORNOCRM2VIA AS "RETORNOCRM2VIA",
                                       P.NUMPROTOCOLOCHQ AS "NUMPROTOCOLOCHQ",
                                       P.VALORCOMTROCO AS "VALORCOMTROCO",
                                       P.IDPAGAMENTO AS "IDPAGAMENTO",
                                       P.SERIALPOS AS "SERIALPOS",
                                       P.IDRESPFISCAL AS "IDRESPFISCAL",
                                       P.BANDEIRACARTAO AS "BANDEIRACARTAO",
                                       P.CODCOBSEFAZ AS "CODCOBSEFAZ",
                                       P.MD5PAF AS "MD5PAF",
                                       P.TIPODOC AS "TIPODOC",
                                       P.DTCXMOT AS "DTCXMOT",
                                       P.TIPOCORBAN AS "TIPOCORBAN",
                                       P.AUTORIZACAOPAGAMENTOPONTOS AS "AUTORIZACAOPAGAMENTOPONTOS",
                                       P.AUTORIZACAOACUMULOPONTOS AS "AUTORIZACAOACUMULOPONTOS",
                                       P.SOMATXBOLETO AS "SOMATXBOLETO",
                                       P.CODUSUR2 AS "CODUSUR2",
                                       P.PROCESSADORTRANSPAGDIGITAL AS "PROCESSADORTRANSPAGDIGITAL",
                                       P.NUMTRANSPAGDIGITAL AS "NUMTRANSPAGDIGITAL",
                                       P.NSUPAGDIGITAL AS "NSUPAGDIGITAL",
                                       P.NOMECARTEIRADIGITAL AS "NOMECARTEIRADIGITAL",
                                       P.CARTEIRADIGITAL AS "CARTEIRADIGITAL" ))))
                                 )
           INTO L_XMLTYPEGIFTCARD
         FROM VW_INT_C5_GIFTCARD A,
              VW_INT_C5_PCPRESTECF P,
              VW_INT_C5_OBTER_FILIAIS_C5 C5
         WHERE A.NROEMPRESA = C5.CODFILIALINTEGRACAO
         AND   P.CODFILIALINTEGRACAO = C5.CODFILIALINTEGRACAO
         AND   A.SEQDOCTO = P.SEQDOCTO
         AND   A.NROCHECKOUT = P.NUMCHECKOUT
        AND    A.NROEMPRESA = P.CODFILIALINTEGRACAO
         AND   A.SEQDOCTO  = P_GIFTCARD.SEQDOCTO
         AND   A.NROCHECKOUT = P_GIFTCARD.NUMCAIXA
         AND   A.NROEMPRESA  = P_GIFTCARD.NROEMPRESA;

        RETURN L_XMLTYPEGIFTCARD;
      END RETORNAR_XMLGIFTCARD;

    BEGIN
      L_GIFTCARD := RETORNAR_XMLGIFTCARD(R_GIFTCARD);

      SELECT XMLELEMENT("EsquemaExportacao",
                        XMLELEMENT("GiftCard",
                                   L_GIFTCARD)
                       ) ESQUEMAEXPORTACAO


        INTO L_XMLESQUEMA
        FROM DUAL;

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
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODFILIAL           := R_GIFTCARD.CODFILIALWINTHOR;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMCAIXA            := R_GIFTCARD.NUMCAIXA;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.NUMNOTA             := R_GIFTCARD.COO;
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

      L_XMLTYPE := RETORNAR_XML_GIFTCARD(R_GIFTCARD);

      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.MENSAGEM            := REPLACE(L_XMLTYPE.GETCLOBVAL(),
                                                                            '<EsquemaExportacao>',
                                                                            DAODOSCABECALHOXML);
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.TIPOMENSAGEM        := 1;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.CODIGOERRO          := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATAULTIMAALTERACAO := SYSDATE;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.PDVORIGEM           := 'PDV SUPERMERCADOS';
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.QTREPROCESSADO      := NULL;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.SEQDOCTO            := R_GIFTCARD.SEQDOCTO;
      DADOS_PCFILAMENSAGEM.ROWPCFILAMENSAGEM.DATADOCUMENTO       := TO_DATE(R_GIFTCARD.DTABERTURA, 'YYYY-MM-DD');

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