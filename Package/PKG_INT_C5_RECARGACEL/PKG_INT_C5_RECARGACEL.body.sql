CREATE OR REPLACE PACKAGE BODY PKG_INT_C5_RECARGACEL IS

  PROCEDURE processar_recargas(p_seqdocto NUMBER Default 0, p_nrocheckout NUMBER default 0, p_nroempresa NUMBER default 0) IS
    CURSOR c_recargacel IS
      SELECT defseq_numpedecf.NEXTVAL numpedecf,
             a.SEQDOCTO,
             a.NROEMPRESA,
             C5.CODFILIAL CODFILIALWINTHOR,
             a.NROCHECKOUT,
             a.TIPOOPERACAO,
             a.CODOPERRECARGACEL,
             
             CASE
               WHEN A.TIPOOPERACAO = 'R' THEN
                    'RP' 
               ELSE 'VG'
             END ESPECIEPDV,
             
             a.INFPRODUTO,
             a.NSUTEF,
             a.VALOR,
             a.DTAHOREMISSAO,
             a.CODIGO,
             a.SEQUSUARIO,
             a.COO,
             a.OPERADORA,
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
       FROM VW_INT_C5_RECARGACEL a,
            vw_int_c5_pcprestecf p,
            VW_INT_C5_OBTER_FILIAIS_C5 C5
       WHERE a.NROEMPRESA = C5.CODFILIALINTEGRACAO
       AND   p.codfilial = C5.CODFILIALINTEGRACAO
       AND   a.seqdocto = p.seqdocto
       AND   a.NROCHECKOUT = p.numcheckout
       AND   a.NROEMPRESA = p.codfilial 
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

    r_recargacel         c_recargacel%ROWTYPE;
    l_xmltype            XMLTYPE;
    mensagemerro         VARCHAR2(1000);
    dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;

    -- PROCESSAR_RECARGAS E VALE GAS ( RETORNAR_XML_RECARGAS )
    FUNCTION retornar_xml_recargas(r_recargacel c_recargacel%ROWTYPE)
      RETURN XMLTYPE IS
      l_xmlesquema      XMLTYPE;
      l_recargacel   XMLTYPE;

      -- Recarga celular e Vale Gás
      FUNCTION retornar_xmlRecargaCel(p_recargacel c_recargacel%ROWTYPE)
        RETURN XMLTYPE IS
        l_xmltyperecarga XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("DefinicaoRecarga",
                          XMLAGG(XMLELEMENT("Recarga",
                                            XMLFOREST(a.DTAHOREMISSAO AS "Data",
                                                      --a.NROEMPRESA AS "Codfilial",
                                                      C5.CODFILIAL AS "Codfilial",
                                                      a.SEQUSUARIO AS "Codfunccx",
                                                      a.NROCHECKOUT AS "Numcaixa",
                                                      a.CODOPERRECARGACEL AS "Codoperrecargacel",
                                                      NULL AS "Exportado",
                                                      NULL AS "Dtexportacao",
                                                      'NotaFiscal' AS "Numserieequip",
                                                      a.COO AS "Numcupom",
                                                      a.NSUTEF AS "Nsu",
                                                      a.OPERADORA AS "Operadora",
                                                      a.VALOR AS "Valor",
                                                      p_recargacel.numpedecf AS "Numpedecf",
                                                      NULL AS "Numtransvenda",
                                                      a.DTAHOREMISSAO AS "Dtmovimentocx",
                                                      a.seqdocto AS "Numfechamentomovcx",
                                                      a.TIPOOPERACAO AS "Tipooperacao",
                                                      a.INFPRODUTO AS "Infproduto",
                                                      NULL AS "Recnum"
                                                      )
                                              )),
                                              
                                  XMLELEMENT ("Parcelas",
                                   XMLAGG (XMLELEMENT("PCPRESTECF",
                                   XMLFOREST (
                                       p.numgiftcard AS "Numgiftcard",
                                       p.exportado AS "Exportado",
                                       p_recargacel.numpedecf AS "Numpedecf",
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
                                       --p.codfilial AS "Codfilial",
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
                                       --p.codfilialnf AS "Codfilialnf",
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
           INTO l_xmltyperecarga
         FROM VW_INT_C5_RECARGACEL a,
              vw_int_c5_pcprestecf p,
              VW_INT_C5_OBTER_FILIAIS_C5 C5
         WHERE a.NROEMPRESA = C5.CODFILIALINTEGRACAO
         AND   p.codfilial = C5.CODFILIALINTEGRACAO
         AND   a.seqdocto = p.seqdocto
         AND   a.NROCHECKOUT = p.numcheckout
         AND   a.NROEMPRESA = p.codfilial 
         AND   a.seqdocto  = p_recargacel.seqdocto
         AND   a.NROCHECKOUT = p_recargacel.NROCHECKOUT
         AND   a.nroempresa  = p_recargacel.nroempresa;

        RETURN l_xmltyperecarga;
      END retornar_xmlRecargaCel;

    BEGIN
      l_recargacel := retornar_xmlRecargaCel(r_recargacel);
      
      SELECT XMLELEMENT("EsquemaExportacao",
                        XMLELEMENT("Recargas",
                                   l_recargacel)
                       ) esquemaexportacao
      
      
        INTO l_xmlesquema
        FROM DUAL;

      RETURN l_xmlesquema;
    END retornar_xml_recargas;

    -- PROCESSAR_Recargas_Celular( RETORNAR_PCFILAMENSAGEM )
    FUNCTION retornar_pcfilamensagem(r_recargacel c_recargacel%ROWTYPE)
      RETURN PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem
        IS
          dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem;
          l_xmltype            XMLTYPE;
          daodoscabecalhoxml   VARCHAR2(200) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
      -- recebe xml da VENDA

      dados_pcfilamensagem.rowpcfilamensagem.idmensagem          := dfseq_pcfilamensagem.NEXTVAL;
      dados_pcfilamensagem.rowpcfilamensagem.datatransacao       := SYSDATE;
      dados_pcfilamensagem.rowpcfilamensagem.codfilial           := r_recargacel.CODFILIALWINTHOR;
      dados_pcfilamensagem.rowpcfilamensagem.numcaixa            := r_recargacel.NROCHECKOUT;
      dados_pcfilamensagem.rowpcfilamensagem.numnota             := r_recargacel.coo;
      dados_pcfilamensagem.rowpcfilamensagem.serie               := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.chavesefaz          := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.protocolo           := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.contingencia        := 'N';
      dados_pcfilamensagem.rowpcfilamensagem.idexterno           := dados_pcfilamensagem.rowpcfilamensagem.idmensagem || '-' ||
                                                                    r_recargacel.seqdocto || '-' ||
                                                                    r_recargacel.NROCHECKOUT || '-' ||
                                                                    r_recargacel.especiepdv;
      dados_pcfilamensagem.rowpcfilamensagem.status              := 0;
      dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento     := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.tipodocumento       := 'RC';
      dados_pcfilamensagem.rowpcfilamensagem.tipooperacao        := 'RECC';

      l_xmltype := retornar_xml_recargas(r_recargacel);

      dados_pcfilamensagem.rowpcfilamensagem.mensagem            := REPLACE(l_xmltype.getclobval(),
                                                                            '<EsquemaExportacao>',
                                                                            daodoscabecalhoxml);
      dados_pcfilamensagem.rowpcfilamensagem.tipomensagem        := 1;
      dados_pcfilamensagem.rowpcfilamensagem.codigoerro          := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao := SYSDATE;
      dados_pcfilamensagem.rowpcfilamensagem.pdvorigem           := 'PDV SUPERMERCADOS';
      dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado      := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.seqdocto            := r_recargacel.seqdocto;

      RETURN dados_pcfilamensagem;
    END retornar_pcfilamensagem;

  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

  FOR r_recargacel IN c_recargacel
  LOOP
      BEGIN
        -- insere os dados da PCFILAMENSAGEM
        dados_pcfilamensagem := retornar_pcfilamensagem(r_recargacel);
        PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem(dados_pcfilamensagem);

      EXCEPTION
        WHEN OTHERS THEN
          mensagemerro := 'Consinco - erro ao persistir recargas de celular de caixa na tabela PCFILAMENSAGEM - ERROR: ' ||
                          SQLCODE || '-' || SQLERRM || '- LINHA: ' ||
                          DBMS_UTILITY.format_error_backtrace;

          PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem_erro(dados_pcfilamensagem, mensagemerro);
      END;


    END LOOP;
  END processar_recargas;
END PKG_INT_C5_RECARGACEL;