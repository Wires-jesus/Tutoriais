CREATE OR REPLACE PACKAGE BODY PKG_INT_C5_CANCELAMENTO
IS
    PROCEDURE processar_cancelamento(p_seqdocto NUMBER DEFAULT 0,
	                                 p_nrocheckout NUMBER DEFAULT 0,
                                     p_nroempresa  NUMBER DEFAULT 0)
    IS
        CURSOR c_canc_cabecalho
        IS
            SELECT *
              FROM vw_int_c5_pcpedccancecf a
             WHERE a.seqdocto = DECODE(p_seqdocto, 0, a.seqdocto, p_seqdocto)
			   AND a.NUMCAIXA = DECODE(p_nrocheckout, 0, a.numcaixa, p_nrocheckout)
			   AND a.CODFILIAL = DECODE(p_nroempresa, 0, a.codfilial, p_nroempresa)
			   AND NOT EXISTS (SELECT 1
                                 FROM PCFILAMENSAGEM M
								WHERE M.SEQDOCTO = a.seqdocto
								  AND M.NUMCAIXA = a.numcaixa
								  AND M.CODFILIAL = a.codfilial
								UNION ALL
							   SELECT 1
								 FROM PCFILAMENSAGEMHISTORICO MH
								WHERE MH.SEQDOCTO = a.seqdocto
								  AND MH.NUMCAIXA = a.numcaixa
								  AND MH.CODFILIAL = a.codfilial
								UNION ALL
							   SELECT 1
								 FROM PCFILAMENSAGEMERRO ME
								WHERE ME.SEQDOCTO = a.seqdocto
								  AND ME.NUMCAIXA = a.numcaixa
								  AND ME.CODFILIAL = a.codfilial);

        r_canc_cabecalho       c_canc_cabecalho%ROWTYPE;
        l_xmltype              XMLTYPE;
        mensagemerro           VARCHAR2 (1000);
        dados_pcfilamensagem   pkg_sinc_pdv_consinco_util.tr_dados_pcfilamensagem;
        e_venda_nao_existe     EXCEPTION;

        -- RETORNAR_XML_CANC_CABECALHO
        FUNCTION retornar_xml_canc_cabecalho (
            p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmltypecabecalho   XMLTYPE;
        BEGIN
            SELECT XMLELEMENT (
                       "PCPEDCCANCECF",
                       XMLAGG (
                           XMLELEMENT (
                               "PCPEDCCANCECF",
                               XMLFOREST (
                                   p_r_canc_cabecalho.exportado AS "Exportado",
                                   p_r_canc_cabecalho.numpedecf AS "Numpedecf",
                                   p_r_canc_cabecalho.codfunccx AS "Codfunccx",
                                   p_r_canc_cabecalho.numcaixa AS "Numcaixa",
                                   p_r_canc_cabecalho.numserieequip AS "Numserieequip",
                                   p_r_canc_cabecalho.dtcancelecf AS "Dtcancelecf",
                                   p_r_canc_cabecalho.codfunccancelecf AS "Codfunccancelecf",
                                   p_r_canc_cabecalho.data AS "Data",
                                   p_r_canc_cabecalho.codcli AS "Codcli",
                                   p_r_canc_cabecalho.codusur AS "Codusur",
                                   p_r_canc_cabecalho.codfilial AS "Codfilial",
                                   p_r_canc_cabecalho.codpraca AS "Codpraca",
                                   p_r_canc_cabecalho.codsupervisor AS "Codsupervisor",
                                   p_r_canc_cabecalho.codplpag AS "Codplpag",
                                   p_r_canc_cabecalho.numcupom AS "Numcupom",
                                   p_r_canc_cabecalho.serieecf AS "Serieecf",
                                   p_r_canc_cabecalho.codcob AS "Codcob",
                                   p_r_canc_cabecalho.condvenda AS "Condvenda",
                                   p_r_canc_cabecalho.percvenda AS "Percvenda",
                                   p_r_canc_cabecalho.codemitente AS "Codemitente",
                                   p_r_canc_cabecalho.prazo1 AS "Prazo1",
                                   p_r_canc_cabecalho.prazo2 AS "Prazo2",
                                   p_r_canc_cabecalho.prazo3 AS "Prazo3",
                                   p_r_canc_cabecalho.prazo4 AS "Prazo4",
                                   p_r_canc_cabecalho.prazo5 AS "Prazo5",
                                   p_r_canc_cabecalho.prazo6 AS "Prazo6",
                                   p_r_canc_cabecalho.prazo7 AS "Prazo7",
                                   p_r_canc_cabecalho.prazo8 AS "Prazo8",
                                   p_r_canc_cabecalho.prazo9 AS "Prazo9",
                                   p_r_canc_cabecalho.prazo10 AS "Prazo10",
                                   p_r_canc_cabecalho.prazo11 AS "Prazo11",
                                   p_r_canc_cabecalho.prazo12 AS "Prazo12",
                                   p_r_canc_cabecalho.prazomedio AS "Prazomedio",
                                   p_r_canc_cabecalho.dtentrega AS "Dtentrega",
                                   p_r_canc_cabecalho.vlatend AS "Vlatend",
                                   p_r_canc_cabecalho.vltabela AS "Vltabela",
                                   p_r_canc_cabecalho.vltotal AS "Vltotal",
                                   p_r_canc_cabecalho.vloutrasdesp AS "Vloutrasdesp",
                                   p_r_canc_cabecalho.vldesconto AS "Vldesconto",
                                   p_r_canc_cabecalho.tipovenda AS "Tipovenda",
                                   p_r_canc_cabecalho.vlcustoreal AS "Vlcustoreal",
                                   p_r_canc_cabecalho.vlcustofin AS "Vlcustofin",
                                   p_r_canc_cabecalho.vlcustorep AS "Vlcustorep",
                                   p_r_canc_cabecalho.vlcustocont AS "Vlcustocont",
                                   p_r_canc_cabecalho.totpeso AS "Totpeso",
                                   p_r_canc_cabecalho.totvolume AS "Totvolume",
                                   p_r_canc_cabecalho.numitens AS "Numitens",
                                   p_r_canc_cabecalho.operacao AS "Operacao",
                                   p_r_canc_cabecalho.hora AS "Hora",
                                   p_r_canc_cabecalho.minuto AS "Minuto",
                                   p_r_canc_cabecalho.numviasmapasep AS "Numviasmapasep",
                                   p_r_canc_cabecalho.numped AS "Numped",
                                   p_r_canc_cabecalho.numcar AS "Numcar",
                                   p_r_canc_cabecalho.numtransvenda AS "Numtransvenda",
                                   p_r_canc_cabecalho.dtfat AS "Dtfat",
                                   p_r_canc_cabecalho.horafat AS "Horafat",
                                   p_r_canc_cabecalho.minutofat AS "Minutofat",
                                   p_r_canc_cabecalho.importado AS "Importado",
                                   p_r_canc_cabecalho.posicaoretorno AS "Posicaoretorno",
                                   p_r_canc_cabecalho.dtcancel AS "Dtcancel",
                                   p_r_canc_cabecalho.codfunccancel AS "Codfunccancel",
                                   p_r_canc_cabecalho.dtexportacao AS "Dtexportacao",
                                   p_r_canc_cabecalho.posicaopedido AS "Posicaopedido",
                                   p_r_canc_cabecalho.numecf AS "Numecf",
                                   p_r_canc_cabecalho.tipocancel AS "Tipocancel",
                                   p_r_canc_cabecalho.numccf AS "Numccf",
                                   p_r_canc_cabecalho.observacao AS "Observacao",
                                   p_r_canc_cabecalho.cartaocrm AS "Cartaocrm",
                                   p_r_canc_cabecalho.exportacrm AS "Exportacrm",
                                   p_r_canc_cabecalho.cupomfechado AS "Cupomfechado",
                                   p_r_canc_cabecalho.motivocancelamento AS "Motivocancelamento",
                                   p_r_canc_cabecalho.numfechamentomovcx AS "Numfechamentomovcx",
                                   p_r_canc_cabecalho.dtmovimentocx AS "Dtmovimentocx",
                                   p_r_canc_cabecalho.vlacresrodape AS "Vlacrescrodape",
                                   p_r_canc_cabecalho.notadupliquesvc AS "Notadupliquesvc",
                                   p_r_canc_cabecalho.md5paf AS "Md5paf",
                                   p_r_canc_cabecalho.docemissao AS "Docemissao",
                                   p_r_canc_cabecalho.ambientenfce AS "Ambientenfce",
                                   p_r_canc_cabecalho.dtexportacaoservint AS "Dtexportacaoservint",
                                   p_r_canc_cabecalho.dtimportacaoservprinc AS "Dtimportacaoservprinc",
                                   p_r_canc_cabecalho.exportadoservint AS "Exportadoservint",
                                   p_r_canc_cabecalho.importadoservprinc AS "Importadoservprinc",
                                   p_r_canc_cabecalho.rotinalanc AS "Rotinalanc",
                                   p_r_canc_cabecalho.assinatura AS "Assinatura"))))
              INTO l_xmltypecabecalho
              FROM DUAL;

            RETURN l_xmltypecabecalho;
        END retornar_xml_canc_cabecalho;

        -- RETORNAR_XML_CANC_ITENS
        FUNCTION retornar_xml_canc_itens (
            p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmltypeitens   XMLTYPE;
        BEGIN
            SELECT XMLELEMENT (
                       "PCPEDICANCECF",
                       XMLAGG (
                           XMLELEMENT (
                               "PCPEDICANCECF",
                               XMLFOREST (
                                   v.exportado AS "Exportado",
                                   p_r_canc_cabecalho.numpedecf AS "Numpedecf",
                                   v.codfunccx AS "Codfunccx",
                                   v.numcaixa AS "Numcaixa",
                                   v.numserieequip AS "Numserieequip",
                                   v.codprod AS "Codprod",
                                   v.numseq AS "Numseq",
                                   v.dtcancelecf AS "Dtcancelecf",
                                   v.codfunccancelecf AS "Codfunccancelecf",
                                   v.data AS "Data",
                                   v.codcli AS "Codcli",
                                   v.codusur AS "Codusur",
                                   v.qt AS "Qt",
                                   v.pvenda AS "Pvenda",
                                   v.poriginal AS "Poriginal",
                                   v.st AS "St",
                                   v.percom AS "Percom",
                                   v.perdesc AS "Perdesc",
                                   v.vlcustofin AS "Vlcustofin",
                                   v.vlcustoreal AS "Vlcustoreal",
                                   v.vlcustorep AS "Vlcustorep",
                                   v.vlcustocont AS "Vlcustocont",
                                   v.qtfalta AS "Qtfalta",
                                   v.codauxiliar AS "Codauxiliar",
                                   v.codst AS "Codst",
                                   v.percbaseredstfonte AS "Percbaseredstfonte",
                                   v.vlipi AS "Vlipi",
                                   v.percipi AS "Percipi",
                                   v.percbaseredst AS "Percbaseredst",
                                   v.perfretecmv AS "Perfretecmv",
                                   v.numcar AS "Numcar",
                                   v.numped AS "Numped",
                                   v.importado AS "Importado",
                                   v.posicaoretorno AS "Posicaoretorno",
                                   v.dtcancel AS "Dtcancel",
                                   v.codfunccancel AS "Codfunccancel",
                                   v.dtexportacao AS "Dtexportacao",
                                   v.totalizador AS "Totalizador",
                                   v.codfilial AS "Codfilial",
                                   v.motivocancelamento AS "MOTIVOCANCELAMENTO",
                                   v.cupomfechado AS "Cupomfechado",
                                   v.vldescrodape AS "Vldescrodape",
                                   v.cancmanual AS "Cancmanual",
                                   v.md5paf AS "Md5paf",
                                   v.codcest AS "Codcest",
                                   v.numccf AS "Numccf",
                                   v.vldescfin AS "Vldescfin",
                                   v.vloutrasdesp AS "Vloutrasdesp",
                                   v.vlacrescrodape AS "Vlacrescrodape",
                                   v.tipocancel AS "Tipocancel",
                                   v.dtexportacaoservint AS "Dtexportacaoservint",
                                   v.dtimportacaoservprinc AS "Dtimportacaoservprinc",
                                   v.exportadoservint AS "Exportadoservint",
                                   v.importadoservprinc AS "Importadoservprinc",
                                   v.numcupom AS "Numcupom",
                                   v.percbasered AS "Percbasered",
                                   v.percicm AS "Percicm",
                                   v.rotinalanc AS "Rotinalanc"))))
              INTO l_xmltypeitens
              FROM vw_int_c5_pcpedicancecf v;

            RETURN l_xmltypeitens;
        END retornar_xml_canc_itens;

        -- RETORNAR_CANCELAMENTO
        FUNCTION retornar_cancelamento(p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmlesquema     XMLTYPE;
            l_xmlitens       XMLTYPE;
            l_xmlcabecalho   XMLTYPE;
        BEGIN
            l_xmlcabecalho := retornar_xml_canc_cabecalho(p_r_canc_cabecalho);
            l_xmlitens := retornar_xml_canc_itens(p_r_canc_cabecalho);

            SELECT XMLELEMENT(
                       "EsquemaExportacao",
                       XMLELEMENT ("Complemento", l_xmlitens, l_xmlcabecalho))
                       esquemaexportacao
              INTO l_xmlesquema
              FROM DUAL;

            RETURN l_xmlesquema;
        END retornar_cancelamento;

        -- RETORNAR_PCFILAMENSAGEM
        FUNCTION retornar_pcfilamensagem_canc (
            p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
            RETURN pkg_sinc_pdv_consinco_util.tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   pkg_sinc_pdv_consinco_util.tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            -- RECEBE XML PARA CANCELAMENTO
            l_xmltype := retornar_cancelamento (p_r_canc_cabecalho);

            dados_pcfilamensagem.rowpcfilamensagem.idmensagem       := dfseq_pcfilamensagem.NEXTVAL;
            dados_pcfilamensagem.rowpcfilamensagem.datatransacao    := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial        := p_r_canc_cabecalho.codfilial;
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa         := p_r_canc_cabecalho.numcaixa;
            dados_pcfilamensagem.rowpcfilamensagem.numnota          := p_r_canc_cabecalho.numcupom;
            dados_pcfilamensagem.rowpcfilamensagem.serie            := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz       := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo        := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia     := 'N';
            dados_pcfilamensagem.rowpcfilamensagem.idexterno        := dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                                                                    || '-'
                                                                    || p_r_canc_cabecalho.seqdocto
                                                                    || '-'
                                                                    || p_r_canc_cabecalho.numcaixa
                                                                    || '-'                       /*|| P_R_CANC_CABECALHO.ESPECIE*/
                                                                      ;
            dados_pcfilamensagem.rowpcfilamensagem.status           := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento  := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento    := 'CE';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao     := CASE
                                                                            WHEN p_r_canc_cabecalho.tipocancel = 'P' 
                                                                                THEN 'CANP'
                                                                            ELSE 'CANT'
                                                                        END;
            dados_pcfilamensagem.rowpcfilamensagem.mensagem         := REPLACE(l_xmltype.getclobval(),'<EsquemaExportacao>',daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem     := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro       := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem        := 'consinco';
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado   := NULL;
			dados_pcfilamensagem.rowpcfilamensagem.seqdocto         := p_r_canc_cabecalho.seqdocto;

            RETURN dados_pcfilamensagem;
        END retornar_pcfilamensagem_canc;

        PROCEDURE gerar_venda_caso_nao_exista (
            p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
        IS
            vcontavenda   NUMBER;

            PROCEDURE verificar_se_venda_existe
            IS
            BEGIN
                SELECT SUM (contavenda)
                  INTO vcontavenda
                  FROM (SELECT DISTINCT contavenda
                          FROM (SELECT COUNT (1) contavenda
                                  FROM pcfilamensagem s
                                 WHERE 0 = 0
                                   AND s.idexterno LIKE '%-'||p_r_canc_cabecalho.seqdocto|| '-%'
                                   AND codfilial = p_r_canc_cabecalho.codfilial
                                   AND numcaixa = p_r_canc_cabecalho.numcaixa
                                   AND s.tipooperacao = 'VEND'
                                   AND TRUNC(datatransacao) = TRUNC(SYSDATE)
                                UNION ALL
                                SELECT COUNT (1) contavenda
                                  FROM pcfilamensagemerro s
                                 WHERE 0 = 0
                                   AND s.idexterno LIKE '%-'|| p_r_canc_cabecalho.seqdocto||'-%'
                                   AND codfilial = p_r_canc_cabecalho.codfilial
                                   AND numcaixa = p_r_canc_cabecalho.numcaixa
                                   AND s.tipooperacao = 'VEND'
                                   AND TRUNC(datatransacao) = TRUNC(SYSDATE)
                                UNION ALL
                                SELECT COUNT (1) contavenda
                                  FROM pcfilamensagemhistorico s
                                 WHERE 0 = 0
                                   AND s.idexterno LIKE '%-'||p_r_canc_cabecalho.seqdocto||'-%'
                                   AND codfilial = p_r_canc_cabecalho.codfilial
                                   AND numcaixa = p_r_canc_cabecalho.numcaixa
                                   AND s.tipooperacao = 'VEND'
                                   AND TRUNC(datatransacao) = TRUNC(SYSDATE)));
            END;
        BEGIN
            verificar_se_venda_existe;

            IF (vcontavenda = 0)
            THEN
                --ATUALIZA O REGISTRO NA TABELA CONSINCO

                UPDATE monitorpdvmiddle.tb_docto s
                   SET replicacao = 'P'
                 WHERE ROWID = p_r_canc_cabecalho.rowid_tb_docto;


                UPDATE monitorpdvmiddle.tb_doctocupom s
                   SET status = 'V'
                 WHERE seqdocto = p_r_canc_cabecalho.seqdocto
                   AND nrocheckout = p_r_canc_cabecalho.numcaixa
                   AND nroempresa = p_r_canc_cabecalho.codfilial
                   AND s.status = 'C';

                --COMMIT;

                /*
                    PROCESSAR_VENDA(P_R_CANC_CABECALHO.SEQDOCTO,
                                    P_R_CANC_CABECALHO.NUMCAIXA,
                                    P_R_CANC_CABECALHO.CODFILIAL);
                */

                UPDATE monitorpdvmiddle.tb_doctocupom s
                   SET status = 'C'
                 WHERE seqdocto = p_r_canc_cabecalho.seqdocto
                   AND nrocheckout = p_r_canc_cabecalho.numcaixa
                   AND nroempresa = p_r_canc_cabecalho.codfilial
                   AND s.status = 'V';

                verificar_se_venda_existe;

                /*IF (vcontavenda = 0)
                THEN
                    RAISE e_venda_nao_existe;
                END IF;*/
            END IF;

            --COMMIT;
        END;

        PROCEDURE adicionarregrascabecalhonf (
            r_canc_cabecalho   IN OUT c_canc_cabecalho%ROWTYPE)
        IS
            vnumpedecf   pcpedcecf.numpedecf%TYPE;
        BEGIN
            BEGIN
                SELECT numpedecf
                  INTO vnumpedecf
                  FROM pcpedcecf
                 WHERE data >= SYSDATE - 10
                   AND numtransvenda = (SELECT numtransvenda
                                          FROM pcnfsaid
                                         WHERE chavenfe = r_canc_cabecalho.numpedecf
                                           AND dtsaida = TRUNC(SYSDATE)
                                           AND ROWNUM = 1);
            EXCEPTION
                WHEN OTHERS
                    THEN vnumpedecf := 0;
            END;

            r_canc_cabecalho.numpedecf      := NVL(vnumpedecf,defseq_numpedecf.NEXTVAL);
            r_canc_cabecalho.codpraca       := NVL(fnc_int_c5_praca_cli(r_canc_cabecalho.codcli),0);
            r_canc_cabecalho.codsupervisor  := NVL(fnc_int_c5_codsuperv(r_canc_cabecalho.codemitente),1);
            r_canc_cabecalho.vltotal        := fnc_int_c5_cab_total(r_canc_cabecalho.seqdocto,r_canc_cabecalho.numcaixa,r_canc_cabecalho.codfilial);
            r_canc_cabecalho.vlatend        := r_canc_cabecalho.vltotal;
            r_canc_cabecalho.vltabela       := r_canc_cabecalho.vltotal;
        END;
    BEGIN
        --IN CIO LOOP C_CANC_CABECALHO
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

        OPEN c_canc_cabecalho;

        FETCH c_canc_cabecalho   INTO r_canc_cabecalho;

        WHILE c_canc_cabecalho%FOUND
        LOOP
            BEGIN
                gerar_venda_caso_nao_exista (r_canc_cabecalho);

                -- REGRAS DO CABE ALHO DO CANCELAMENTO
                adicionarregrascabecalhonf (r_canc_cabecalho);

                -- INSERE OS DADOS DA PCFILAMENSAGEM
                dados_pcfilamensagem :=
                    retornar_pcfilamensagem_canc (r_canc_cabecalho);
                pkg_sinc_pdv_consinco_util.inserir_pcfilamensagem (
                    dados_pcfilamensagem);

                --ATUALIZA O REGISTRO NA TABELA CONSINCO
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_canc_cabecalho.rowid_tb_docto;

                --COMMIT;
            EXCEPTION
               /* WHEN e_venda_nao_existe
                THEN
                    mensagemerro :=
                           ' A VENDA N O EXISTE PARA O CANCELAMENTO - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_canc_cabecalho.rowid_tb_docto;

                    --COMMIT;

                    pkg_sinc_pdv_consinco_util.inserir_pcfilamensagem_erro(dados_pcfilamensagem,mensagemerro);*/
                WHEN OTHERS
                THEN
                    mensagemerro :=
                           'CONSINCO - ERRO AO PERSISTIR CANC_CABECALHO NA TABELA PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_canc_cabecalho.rowid_tb_docto;

                    --COMMIT;

                    pkg_sinc_pdv_consinco_util.inserir_pcfilamensagem_erro(dados_pcfilamensagem,mensagemerro);
            END;

            FETCH c_canc_cabecalho   INTO r_canc_cabecalho;
        END LOOP;

        CLOSE c_canc_cabecalho;

        --COMMIT;
    -- FIM LOOP C_CANC_CABECALHO
    END processar_cancelamento;
END PKG_INT_C5_CANCELAMENTO;