CREATE OR REPLACE PACKAGE BODY PKG_INT_C5_RECFATURA IS

  PROCEDURE processar_rec_faturas(p_seqdocto NUMBER Default 0, p_nrocheckout NUMBER default 0, p_nroempresa NUMBER default 0) IS
    CURSOR c_recfatura IS
      SELECT defseq_numpedecf.NEXTVAL numpedecf,
             a.SEQDOCTO,
             a.NROEMPRESA,
             C5.CODFILIAL CODFILIALWINTHOR,
             a.NROCHECKOUT,
             'F' TIPOOPERACAO,
             a.CODOPERRECARGACEL,
             'PL' ESPECIEPDV,
             a.NSUTEF,
             a.VLRTOTAL,
             a.DTAHOREMISSAO,
             a.DTAMOVIMENTO,
             a.SEQUSUARIO,
             a.COO,
             a.ORIGEMFATURA,
             a.STATUS,
             a.TIPOFATURA,

             p.numgiftcard AS "Numgiftcard",
             p.exportado AS "Exportado",
             ROWNUM AS "Prestecf",
             p.presttef AS "Presttef",
             p.codfunccheckout AS "Codfunccheckout",
             p.numcheckout AS "Numcheckout",
             p.numserieequip AS "Numserieequip",
             p.duplic AS "Duplic",
             p.codcli AS "Codcli",
             p.valor AS "Valor",
             p.dtvenc AS "Dtvenc",
             p.codcob AS "Codcob",
             p.dtemissao AS "Dtemissao",
             p.codfilial AS "Codfilial",
             p.status AS "Status",
             p.codusur AS "Codusur",
             p.dtvencorig AS "Dtvencorig",
             p.operacao AS "Operacao",
             p.boleto AS "Boleto",
             p.numbanco AS "Numbanco",
             p.numagencia AS "Numagencia",
             p.numcheque AS "Numcheque",
             p.codsupervisor AS "Codsupervisor",
             p.codbarra AS "Codbarra",
             p.valororig AS "Valororig",
             p.codcoborig AS "Codcoborig",
             p.vltxboleto AS "Vltxboleto",
             p.codfilialnf AS "Codfilialnf",
             p.numcontacorrente AS "Numcontacorrente",
             p.prest AS "Prest",
             p.numcar AS "Numcar",
             p.numtransvenda AS "Numtransvenda",
             p.numped AS "Numped",
             p.importado AS "Importado",
             p.dtexportacao AS "Dtexportacao",
             p.numcaixafiscal AS "Numcaixafiscal",
             p.nsutef AS "Nsutef",
             p.numecf AS "Numecf",
             p.parcelamentotef AS "Parcelamentotef",
             p.prestef AS "Prestef",
             p.codadmcartao AS "Codadmcartao",
             p.tipooperacaotef AS "Tipooperacaotef",
             p.codbandeiratef AS "Codbandeiratef",
             p.dtbaixa AS "Dtbaixa",
             p.codautorizacaotef AS "Codautorizacaotef",
             p.numccf AS "Numccf",
             p.linhadig AS "Linhadig",
             p.vlmexiva AS "Vlmexiva",
             p.assinatura AS "Assinatura",
             p.numgnf AS "Numgnf",
             p.numseriesat AS "Numseriesat",
             p.cnpjcredenccartao AS "Cnpjcredenccartao",
             p.numcartaocrm AS "Numcartaocrm",
             p.nsuhost AS "Nsuhost",
             p.valorcontravale AS "Valorcontravale",
             p.compensacaobco AS "Compensacaobco",
             p.cgccpfch AS "Cgccpfch",
             p.dvagencia AS "Dvagencia",
             p.dvconta AS "Dvconta",
             p.dvcheque AS "Dvcheque",
             p.numfechamentomovcx AS "Numfechamentomovcx",
             p.dtmovimentocx AS "Dtmovimentocx",
             p.codautoricredtef AS "Codautoricredtef",
             p.dtemissaoorig AS "Dtemissaoorig",
             p.codigocontravale AS "Codigocontravale",
             p.retornocrm1via AS "Retornocrm1via",
             p.retornocrm2via AS "Retornocrm2via",
             p.numprotocolochq AS "Numprotocolochq",
             p.valorcomtroco AS "Valorcomtroco",
             p.idpagamento AS "Idpagamento",
             p.serialpos AS "Serialpos",
             p.idrespfiscal AS "Idrespfiscal",
             p.bandeiracartao AS "Bandeiracartao",
             p.codcobsefaz AS "Codcobsefaz",
             p.md5paf AS "Md5paf",
             p.tipodoc AS "Tipodoc",
             p.dtcxmot AS "Dtcxmot",
             p.tipocorban AS "Tipocorban",
             p.autorizacaopagamentopontos AS "Autorizacaopagamentopontos",
             p.autorizacaoacumulopontos AS "Autorizacaoacumulopontos",
             p.somatxboleto AS "Somatxboleto",
             p.codusur2 AS "Codusur2",
             p.processadortranspagdigital AS "Processadortranspagdigital",
             p.numtranspagdigital AS "Numtranspagdigital",
             p.nsupagdigital AS "Nsupagdigital",
             p.nomecarteiradigital AS "Nomecarteiradigital",
             p.carteiradigital AS "Carteiradigital"
       FROM VW_INT_C5_RECFATURA a,
            vw_int_c5_pcprestecf p,
            VW_INT_C5_OBTER_FILIAIS_C5 C5
       WHERE a.NROEMPRESA = C5.CODFILIALINTEGRACAO
       --AND   p.codfilial = C5.CODFILIALINTEGRACAO
       AND   p.CODFILIALINTEGRACAO = C5.CODFILIALINTEGRACAO
       AND   a.seqdocto = p.seqdocto
       AND   a.NROCHECKOUT = p.numcheckout
       --AND   a.NROEMPRESA = p.codfilial
       AND   a.NROEMPRESA = p.CODFILIALINTEGRACAO 
       AND   a.seqdocto = DECODE(p_seqdocto, 0, a.seqdocto, p_seqdocto)
       AND   a.NROCHECKOUT = DECODE(p_nrocheckout, 0, a.seqdocto, p_nrocheckout)
       AND   a.nroempresa = DECODE(p_nroempresa, 0, a.seqdocto, p_nroempresa)
       AND NOT EXISTS (SELECT 1
                                 FROM PCFILAMENSAGEM M
                WHERE M.SEQDOCTO = a.seqdocto
                  AND M.NUMCAIXA = a.NROCHECKOUT
                  --AND M.CODFILIAL = a.nroempresa
                  AND M.CODFILIAL = c5.codfilial
                UNION ALL
                 SELECT 1
                 FROM PCFILAMENSAGEMHISTORICO MH
                WHERE MH.SEQDOCTO = a.seqdocto
                  AND MH.NUMCAIXA = TO_CHAR(a.NROCHECKOUT)
                  --AND MH.CODFILIAL = a.nroempresa
                  AND MH.CODFILIAL = c5.codfilial
                UNION ALL
                 SELECT 1
                 FROM PCFILAMENSAGEMERRO ME
                WHERE ME.SEQDOCTO = a.seqdocto
                  AND ME.NUMCAIXA = a.NROCHECKOUT
                  --AND ME.CODFILIAL = a.nroempresa
                  AND ME.CODFILIAL = c5.codfilial
                  );

    r_recfatura         c_recfatura%ROWTYPE;
    l_xmltype            XMLTYPE;
    mensagemerro         VARCHAR2(1000);
    dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;

    -- PROCESSAR_REC_FATURA
    FUNCTION retornar_xml_recfatura(r_recfatura c_recfatura%ROWTYPE)
      RETURN XMLTYPE IS
      l_xmlesquema      XMLTYPE;
      l_recfatura   XMLTYPE;

      -- Recarga recebimento fatura
      FUNCTION retornar_xmlRecfatura(p_recfatura c_recfatura%ROWTYPE)
        RETURN XMLTYPE IS
        l_xmltyperecfatura XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("DefinicaoRecebimentoDeFatura",
                          XMLAGG(XMLELEMENT("Recebimento",
                                            XMLFOREST(
                                                      C5.CODFILIAL AS "Codfilial",
                                                      a.DTAHOREMISSAO AS "Data",
                                                      a.SEQUSUARIO AS "Codfunccx",
                                                      a.NROCHECKOUT AS "Numcaixa",
                                                      'NotaFiscal' AS "Numserieequip",
                                                      a.COO AS "Numcupom",
                                                      p_recfatura.numpedecf AS "Numpedecf",
                                                      a.NSUTEF AS "Nsu",
                                                      a.VLRTOTAL AS "Valor",
                                                      'N' AS "Exportado",
                                                      NULL AS "Dtexportacao",
                                                      a.ORIGEMFATURA AS "OrigemFatura",
                                                      a.STATUS AS "Status",                                                     
                                                      a.TIPOFATURA AS "TipoFatura",
                                                      a.CODOPERRECARGACEL AS "Codoperrecargacel",
                                                      a.DTAHOREMISSAO AS "Dtpagamento",
                                                      a.SEQDOCTO AS "Numfechamentomovcx",
                                                      a.DTAHOREMISSAO AS "Dtmovimentocx"
                                                      )
                                              )),
                                              
                                  XMLELEMENT ("Parcelas",
                                   XMLAGG (XMLELEMENT("PCPRESTECF",
                                   XMLFOREST (
                                       p.numgiftcard AS "Numgiftcard",
                                       p.exportado AS "Exportado",
                                       p_recfatura.numpedecf AS "Numpedecf",
                                       ROWNUM AS "Prestecf",
                                       p.presttef AS "Presttef",
                                       p.codfunccheckout AS "Codfunccheckout",
                                       p.numcheckout AS "Numcheckout",
                                       p.numserieequip AS "Numserieequip",
                                       a.COO AS "Duplic",
                                       p.codcli AS "Codcli",
                                       p.valor AS "Valor",
                                       p.dtvenc AS "Dtvenc",
                                       p.codcob AS "Codcob",
                                       p.dtemissao AS "Dtemissao",
                                       C5.codfilial AS "Codfilial",
                                       p.status AS "Status",
                                       p.codusur AS "Codusur",
                                       p.dtvencorig AS "Dtvencorig",
                                       p.operacao AS "Operacao",
                                       p.boleto AS "Boleto",
                                       p.numbanco AS "Numbanco",
                                       p.numagencia AS "Numagencia",
                                       p.numcheque AS "Numcheque",
                                       p.codsupervisor AS "Codsupervisor",
                                       p.codbarra AS "Codbarra",
                                       p.valororig AS "Valororig",
                                       p.codcoborig AS "Codcoborig",
                                       p.vltxboleto AS "Vltxboleto",
                                       C5.codfilial AS "Codfilialnf",
                                       p.numcontacorrente AS "Numcontacorrente",
                                       p.prest AS "Prest",
                                       p.numcar AS "Numcar",
                                       p.numtransvenda AS "Numtransvenda",
                                       p.numped AS "Numped",
                                       p.importado AS "Importado",
                                       p.dtexportacao AS "Dtexportacao",
                                       p.numcaixafiscal AS "Numcaixafiscal",
                                       p.nsutef AS "Nsutef",
                                       p.numecf AS "Numecf",
                                       p.parcelamentotef AS "Parcelamentotef",
                                       p.prestef AS "Prestef",
                                       p.codadmcartao AS "Codadmcartao",
                                       p.tipooperacaotef AS "Tipooperacaotef",
                                       p.codbandeiratef AS "Codbandeiratef",
                                       p.dtbaixa AS "Dtbaixa",
                                       p.codautorizacaotef AS "Codautorizacaotef",
                                       p.numccf AS "Numccf",
                                       p.linhadig AS "Linhadig",
                                       p.vlmexiva AS "Vlmexiva",
                                       p.assinatura AS "Assinatura",
                                       p.numgnf AS "Numgnf",
                                       p.numseriesat AS "Numseriesat",
                                       p.cnpjcredenccartao AS "Cnpjcredenccartao",
                                       p.numcartaocrm AS "Numcartaocrm",
                                       p.nsuhost AS "Nsuhost",
                                       p.valorcontravale AS "Valorcontravale",
                                       p.compensacaobco AS "Compensacaobco",
                                       p.cgccpfch AS "Cgccpfch",
                                       p.dvagencia AS "Dvagencia",
                                       p.dvconta AS "Dvconta",
                                       p.dvcheque AS "Dvcheque",
                                       p.numfechamentomovcx AS "Numfechamentomovcx",
                                       p.dtmovimentocx AS "Dtmovimentocx",
                                       p.codautoricredtef AS "Codautoricredtef",
                                       p.dtemissaoorig AS "Dtemissaoorig",
                                       p.codigocontravale AS "Codigocontravale",
                                       p.retornocrm1via AS "Retornocrm1via",
                                       p.retornocrm2via AS "Retornocrm2via",
                                       p.numprotocolochq AS "Numprotocolochq",
                                       p.valorcomtroco AS "Valorcomtroco",
                                       p.idpagamento AS "Idpagamento",
                                       p.serialpos AS "Serialpos",
                                       p.idrespfiscal AS "Idrespfiscal",
                                       p.bandeiracartao AS "Bandeiracartao",
                                       p.codcobsefaz AS "Codcobsefaz",
                                       p.md5paf AS "Md5paf",
                                       p.tipodoc AS "Tipodoc",
                                       p.dtcxmot AS "Dtcxmot",
                                       p.tipocorban AS "Tipocorban",
                                       p.autorizacaopagamentopontos AS "Autorizacaopagamentopontos",
                                       p.autorizacaoacumulopontos AS "Autorizacaoacumulopontos",
                                       p.somatxboleto AS "Somatxboleto",
                                       p.codusur2 AS "Codusur2",
                                       p.processadortranspagdigital AS "Processadortranspagdigital",
                                       p.numtranspagdigital AS "Numtranspagdigital",
                                       p.nsupagdigital AS "Nsupagdigital",
                                       p.nomecarteiradigital AS "Nomecarteiradigital",
                                       p.carteiradigital AS "Carteiradigital" ))))            
                                 )
                         --  )
           INTO l_xmltyperecfatura
         FROM VW_INT_C5_RECFATURA a,
              vw_int_c5_pcprestecf p,
              VW_INT_C5_OBTER_FILIAIS_C5 C5
         WHERE a.NROEMPRESA = C5.CODFILIALINTEGRACAO
         --AND   p.codfilial = C5.CODFILIALINTEGRACAO
         AND   p.CODFILIALINTEGRACAO = C5.CODFILIALINTEGRACAO
         AND   a.seqdocto = p.seqdocto
         AND   a.NROCHECKOUT = p.numcheckout
         --AND   a.NROEMPRESA = p.codfilial
         AND   a.NROEMPRESA = p.CODFILIALINTEGRACAO 
         AND   a.seqdocto  = p_recfatura.seqdocto
         AND   a.NROCHECKOUT = p_recfatura.NROCHECKOUT
         AND   a.nroempresa  = p_recfatura.nroempresa;

        RETURN l_xmltyperecfatura;
      END retornar_xmlRecfatura;

    BEGIN
      l_recfatura := retornar_xmlRecfatura(r_recfatura);
      
      SELECT XMLELEMENT("EsquemaExportacao",
                        XMLELEMENT("RecebimentosDeFatura",
                                   l_recfatura)
                       ) esquemaexportacao
      
      
        INTO l_xmlesquema
        FROM DUAL;

      RETURN l_xmlesquema;
    END retornar_xml_recfatura;

    --RETORNAR_PCFILAMENSAGEM
    FUNCTION retornar_pcfilamensagem(r_recfatura c_recfatura%ROWTYPE)
      RETURN PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem
        IS
          dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem;
          l_xmltype            XMLTYPE;
          daodoscabecalhoxml   VARCHAR2(200) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
      -- recebe xml da VENDA

      dados_pcfilamensagem.rowpcfilamensagem.idmensagem          := dfseq_pcfilamensagem.NEXTVAL;
      dados_pcfilamensagem.rowpcfilamensagem.datatransacao       := SYSDATE;
      dados_pcfilamensagem.rowpcfilamensagem.codfilial           := r_recfatura.CODFILIALWINTHOR;
      dados_pcfilamensagem.rowpcfilamensagem.numcaixa            := r_recfatura.NROCHECKOUT;
      dados_pcfilamensagem.rowpcfilamensagem.numnota             := r_recfatura.coo;
      dados_pcfilamensagem.rowpcfilamensagem.serie               := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.chavesefaz          := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.protocolo           := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.contingencia        := 'N';
      dados_pcfilamensagem.rowpcfilamensagem.idexterno           := dados_pcfilamensagem.rowpcfilamensagem.idmensagem || '-' ||
                                                                    r_recfatura.seqdocto || '-' ||
                                                                    r_recfatura.NROCHECKOUT || '-' ||
                                                                    r_recfatura.especiepdv;
      dados_pcfilamensagem.rowpcfilamensagem.status              := 0;
      dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento     := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.tipodocumento       := 'F';
      dados_pcfilamensagem.rowpcfilamensagem.tipooperacao        := 'RFAT';

      l_xmltype := retornar_xml_recfatura(r_recfatura);

      dados_pcfilamensagem.rowpcfilamensagem.mensagem            := REPLACE(l_xmltype.getclobval(),
                                                                            '<EsquemaExportacao>',
                                                                            daodoscabecalhoxml);
      dados_pcfilamensagem.rowpcfilamensagem.tipomensagem        := 1;
      dados_pcfilamensagem.rowpcfilamensagem.codigoerro          := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao := SYSDATE;
      dados_pcfilamensagem.rowpcfilamensagem.pdvorigem           := 'PDV SUPERMERCADOS';
      dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado      := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.seqdocto            := r_recfatura.seqdocto;
      dados_pcfilamensagem.rowpcfilamensagem.datadocumento       := TO_DATE(r_recfatura.DTAMOVIMENTO, 'YYYY-MM-DD');

      RETURN dados_pcfilamensagem;
    END retornar_pcfilamensagem;

  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

  FOR r_recfatura IN c_recfatura
  LOOP
      BEGIN
        -- insere os dados da PCFILAMENSAGEM
        dados_pcfilamensagem := retornar_pcfilamensagem(r_recfatura);
        PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem(dados_pcfilamensagem);

      EXCEPTION
        WHEN OTHERS THEN
          mensagemerro := 'Consinco - erro ao persistir recebimento de fatura de caixa na tabela PCFILAMENSAGEM - ERROR: ' ||
                          SQLCODE || '-' || SQLERRM || '- LINHA: ' ||
                          DBMS_UTILITY.format_error_backtrace;

          PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem_erro(dados_pcfilamensagem, mensagemerro);
      END;

    END LOOP;
  END processar_rec_faturas;
END PKG_INT_C5_RECFATURA;