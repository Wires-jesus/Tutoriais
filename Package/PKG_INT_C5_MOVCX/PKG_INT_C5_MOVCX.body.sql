CREATE OR REPLACE PACKAGE BODY pkg_int_c5_movcx IS

  PROCEDURE processar_movimento_caixa(p_seqdocto NUMBER Default 0,
                                      p_nrocheckout NUMBER default 0,
									  p_nroempresa NUMBER default 0) IS
    CURSOR c_logaberturacx IS
      SELECT defseq_numpedecf.NEXTVAL numpedecf,
             a.numcaixa,
             a.codfunccxatual,
             a.dtabertura,
             a.seqturno,
             a.nroempresa,
             a.seqdocto,
             a.especie,
             a.codcli,
             a.numnota,
             a.ROWID,
             a.rowid_tb_docto
        FROM vw_int_c5_aberturacx a
       WHERE a.especie = 'AC'
         AND a.seqdocto = DECODE(p_seqdocto, 0, a.seqdocto, p_seqdocto)
		 AND a.numcaixa = DECODE(p_nrocheckout, 0, a.seqdocto, p_nrocheckout)
		 AND a.nroempresa = DECODE(p_nroempresa, 0, a.seqdocto, p_nroempresa)
		 AND NOT EXISTS (SELECT 1
                                 FROM PCFILAMENSAGEM M
								WHERE M.SEQDOCTO = a.seqdocto
								  AND M.NUMCAIXA = a.numcaixa
								  AND M.CODFILIAL = a.nroempresa
								UNION ALL
							   SELECT 1
								 FROM PCFILAMENSAGEMHISTORICO MH
								WHERE MH.SEQDOCTO = a.seqdocto
								  AND MH.NUMCAIXA = TO_CHAR(a.numcaixa)
								  AND MH.CODFILIAL = a.nroempresa
								UNION ALL
							   SELECT 1
								 FROM PCFILAMENSAGEMERRO ME
								WHERE ME.SEQDOCTO = a.seqdocto
								  AND ME.NUMCAIXA = a.numcaixa
								  AND ME.CODFILIAL = a.nroempresa);

    r_logaberturacx      c_logaberturacx%ROWTYPE;
    l_xmltype            XMLTYPE;
    mensagemerro         VARCHAR2(1000);
    dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;

    -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XML_MOVIMENTO_CAIXA )
    FUNCTION retornar_xml_movimento_caixa(r_logaberturacx c_logaberturacx%ROWTYPE)
      RETURN XMLTYPE IS
      l_xmlesquema      XMLTYPE;
      l_logaberturacx   XMLTYPE;
      l_fechamentomovcx XMLTYPE;
      l_logcaixa        XMLTYPE;

      -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLLOGABERTURACX )
      FUNCTION retornar_xmllogaberturacx(p_logaberturacx c_logaberturacx%ROWTYPE)
        RETURN XMLTYPE IS
        l_xmltypelogaberturacx XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("PCLOGABERTURACX",
                          XMLAGG(XMLELEMENT("PCLOGABERTURACX",
                                            XMLFOREST(p_logaberturacx.numpedecf AS "Numpedecf",
                                                      a.numcaixa AS "Numcaixa",
                                                      'F' AS "Posicaoant",
                                                      'A' AS "Posicaoatual",
                                                      NULL AS "Codfunccxant",
                                                      a.codfunccxatual AS "Codfunccxatual", --OPERADOR
                                                      a.codfunccxatual AS "Codfuncfiscalcx", --FISCAL
                                                      a.dtabertura AS "Dtabertura",
                                                      'S' AS "Exportado",
                                                      NULL AS "Dtexportacao",
                                                      a.seqdocto AS "Numfechamentomovcx"))))
          INTO l_xmltypelogaberturacx
          FROM vw_int_c5_aberturacx a
         WHERE numcaixa = p_logaberturacx.numcaixa
           AND a.especie = 'AC'
           AND a.dtabertura = p_logaberturacx.dtabertura
           AND a.seqturno = p_logaberturacx.seqturno
           AND a.nroempresa = p_logaberturacx.nroempresa
           AND a.codfunccxatual = p_logaberturacx.codfunccxatual
           AND ROWNUM = 1;

        RETURN l_xmltypelogaberturacx;
      END retornar_xmllogaberturacx;

      -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLFECHAMENTOMOVCX )
      FUNCTION retornar_xmlfechamentomovcx(p_logaberturacx c_logaberturacx%ROWTYPE)
        RETURN XMLTYPE IS
        l_xmlfechamentomovcx XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("PCFECHAMENTOMOVCX",
                          XMLAGG(XMLELEMENT("PCFECHAMENTOMOVCX",
                                            XMLFOREST(p_logaberturacx.numpedecf AS "Numpedecf", 
                                                      NULL AS "Exportado",
                                                      a.seqdocto AS "Numfechamentomovcx",
                                                      a.nroempresa AS "Codfilial",
                                                      a.numcaixa AS "Numcaixa",
                                                      a.codfunccxatual AS "Codfunccx",
                                                      a.dtabertura AS "Dtmovimentocx",
                                                      a.dtabertura AS "Dtabertura", 
                                                      a.HORAABERTURA AS "Horaabertura",
                                                      a.MINUTOABERTURA AS "Minutoabertura",
                                                      a.DTFECHAMENTO AS "Dtfechamento",
                                                      a.HORAFECHAMENTO AS "Horafechamento",
                                                      a.MINUTOFECHAMENTO AS "Minutofechamento",
                                                      a.seqdocto AS "Nummovimentopdv"))))
          INTO l_xmlfechamentomovcx
          FROM vw_int_c5_aberturacx a
         WHERE a.especie In ('FC', 'FM')
           AND numcaixa = p_logaberturacx.numcaixa
           AND a.dtabertura = p_logaberturacx.dtabertura
           AND a.seqturno = p_logaberturacx.seqturno
           AND a.nroempresa = p_logaberturacx.nroempresa
           AND a.codfunccxatual = p_logaberturacx.codfunccxatual
           AND ROWNUM = 1;

        RETURN l_xmlfechamentomovcx;
      END retornar_xmlfechamentomovcx;

      -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLLOGCAIXA )
      FUNCTION retornar_xmllogcaixa(p_logaberturacx c_logaberturacx%ROWTYPE)
        RETURN XMLTYPE IS
        l_xmltypepclogcaixa XMLTYPE;
      BEGIN
        SELECT XMLELEMENT("PCLOGCAIXA",
                          XMLAGG(XMLELEMENT("PCLOGCAIXA",
                                            XMLFOREST(p_logaberturacx.numpedecf AS "Numpedecf",
                                                      a.dtabertura AS "Data",
                                                      NULL AS "Hora", 
                                                      NULL AS "Minuto", 
                                                      a.Numcaixa AS "Numcaixa",
                                                      a.codfunccxatual AS "Codfunccx",
                                                      a.codfunccxatual AS "Codfiscalcx",
                                                      a.codcli AS "Codcli",
                                                      a.valor AS "Valor",
                                                      (CASE a.especie
                                                         WHEN 'AC' 
                                                             THEN 'Caixa Aberto pelo Fiscal de Caixa'||' - '||a.codfunccxatual 
                                                         WHEN 'FC' 
                                                             THEN 'Caixa Fechado pelo Fiscal de Caixa'||' - '||a.codfunccxatual
                                                       END) AS "Historico",
                                                      '0' AS "Numseqitem",
                                                      a.numnota AS "Numcupom",
                                                      a.seqdocto AS "Numseq",
                                                      a.nroempresa AS "Codfilial",
                                                      NULL AS "Motivocancelamento",
                                                      NULL AS "Dtexportacao",
                                                      NULL AS "Exportado"))))
          INTO l_xmltypepclogcaixa
          FROM vw_int_c5_aberturacx a
         WHERE a.especie IN ('AC','FC','CX','FM')
           AND numcaixa = p_logaberturacx.numcaixa
           AND a.dtabertura = p_logaberturacx.dtabertura
           AND a.seqturno = p_logaberturacx.seqturno
           AND a.nroempresa = p_logaberturacx.nroempresa
           AND a.codfunccxatual = p_logaberturacx.codfunccxatual
           AND ROWNUM = 1;

        RETURN l_xmltypepclogcaixa;
      END retornar_xmllogcaixa;
    BEGIN
      l_logaberturacx   := retornar_xmllogaberturacx(r_logaberturacx);
      l_fechamentomovcx := retornar_xmlfechamentomovcx(r_logaberturacx);
      l_logcaixa        := retornar_xmllogcaixa(r_logaberturacx);

      SELECT XMLELEMENT("EsquemaExportacao",
                        XMLELEMENT("Complemento",
                                   l_logaberturacx,
                                   l_fechamentomovcx,
                                   l_logcaixa)) esquemaexportacao
        INTO l_xmlesquema
        FROM DUAL;

      RETURN l_xmlesquema;
    END retornar_xml_movimento_caixa;

    -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_PCFILAMENSAGEM )
    FUNCTION retornar_pcfilamensagem(r_logaberturacx c_logaberturacx%ROWTYPE)
      RETURN PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem 
        IS
          dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem;
          l_xmltype            XMLTYPE;
          daodoscabecalhoxml   VARCHAR2(200) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
      -- recebe xml da VENDA
      l_xmltype := retornar_xml_movimento_caixa(r_logaberturacx);

      dados_pcfilamensagem.rowpcfilamensagem.idmensagem          := dfseq_pcfilamensagem.NEXTVAL;
      dados_pcfilamensagem.rowpcfilamensagem.datatransacao       := SYSDATE;
      dados_pcfilamensagem.rowpcfilamensagem.codfilial           := r_logaberturacx.nroempresa;
      dados_pcfilamensagem.rowpcfilamensagem.numcaixa            := r_logaberturacx.numcaixa;
      dados_pcfilamensagem.rowpcfilamensagem.numnota             := r_logaberturacx.numnota;
      dados_pcfilamensagem.rowpcfilamensagem.serie               := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.chavesefaz          := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.protocolo           := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.contingencia        := 'N';
      dados_pcfilamensagem.rowpcfilamensagem.idexterno           := dados_pcfilamensagem.rowpcfilamensagem.idmensagem || '-' ||
                                                                    r_logaberturacx.seqdocto || '-' ||
                                                                    r_logaberturacx.numcaixa || '-' ||
                                                                    r_logaberturacx.especie;
      dados_pcfilamensagem.rowpcfilamensagem.status              := 0;
      dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento     := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.tipodocumento       := 'OD';
      dados_pcfilamensagem.rowpcfilamensagem.tipooperacao        := 'MOVC';
      dados_pcfilamensagem.rowpcfilamensagem.mensagem            := REPLACE(l_xmltype.getclobval(),
                                                                            '<EsquemaExportacao>',
                                                                            daodoscabecalhoxml);
      dados_pcfilamensagem.rowpcfilamensagem.tipomensagem        := 1;
      dados_pcfilamensagem.rowpcfilamensagem.codigoerro          := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao := SYSDATE;
      dados_pcfilamensagem.rowpcfilamensagem.pdvorigem           := 'PDV SUPERMERCADOS';
      dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado      := NULL;
      dados_pcfilamensagem.rowpcfilamensagem.seqdocto            := r_logaberturacx.seqdocto;

      RETURN dados_pcfilamensagem;
    END retornar_pcfilamensagem;
  BEGIN
    ------------- INICIO LOOP C_LOGABERTURACX ---------------
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

	FOR r_logaberturacx IN c_logaberturacx
	LOOP
      BEGIN
        -- insere os dados da PCFILAMENSAGEM
        dados_pcfilamensagem := retornar_pcfilamensagem(r_logaberturacx);
        PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem(dados_pcfilamensagem);

        --ATUALIZA O REGISTRO na tabela consinco
       /* UPDATE monitorpdvmiddle.tb_docto
           SET replicacao = 'F'
         WHERE Rowid = r_logaberturacx.rowid_tb_docto; */
      EXCEPTION
        WHEN OTHERS THEN
          mensagemerro := 'Consinco - erro ao persistir Abertura/Fechamento de caixa na tabela PCFILAMENSAGEM - ERROR: ' ||
                          SQLCODE || '-' || SQLERRM || '- LINHA: ' ||
                          DBMS_UTILITY.format_error_backtrace;

        /*  UPDATE monitorpdvmiddle.tb_docto
             SET replicacao = 'E'
           WHERE ROWID = r_logaberturacx.rowid_tb_docto;  */

          PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem_erro(dados_pcfilamensagem, mensagemerro);
          --ROLLBACK;
      END;


    END LOOP;

    ------------- FIM LOOP C_LOGABERTURACX ---------------
  END processar_movimento_caixa;
END PKG_INT_C5_MOVCX;
