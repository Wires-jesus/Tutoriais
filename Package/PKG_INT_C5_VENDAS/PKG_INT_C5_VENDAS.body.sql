CREATE OR REPLACE PACKAGE BODY PKG_INT_C5_VENDAS
IS
    PROCEDURE inserir_pcfilamensagem (p_pcfilamensagem tr_dados_pcfilamensagem)
    IS
        dados_pcfilamensagem   tr_dados_pcfilamensagem;
    BEGIN
        dados_pcfilamensagem.rowpcfilamensagem.idmensagem           := p_pcfilamensagem.rowpcfilamensagem.idmensagem;
        dados_pcfilamensagem.rowpcfilamensagem.datatransacao        := p_pcfilamensagem.rowpcfilamensagem.datatransacao;
        dados_pcfilamensagem.rowpcfilamensagem.codfilial            := p_pcfilamensagem.rowpcfilamensagem.codfilial;
        dados_pcfilamensagem.rowpcfilamensagem.numcaixa             := p_pcfilamensagem.rowpcfilamensagem.numcaixa;
        dados_pcfilamensagem.rowpcfilamensagem.numnota              := p_pcfilamensagem.rowpcfilamensagem.numnota;
        dados_pcfilamensagem.rowpcfilamensagem.serie                := p_pcfilamensagem.rowpcfilamensagem.serie;
        dados_pcfilamensagem.rowpcfilamensagem.chavesefaz           := p_pcfilamensagem.rowpcfilamensagem.chavesefaz;
        dados_pcfilamensagem.rowpcfilamensagem.protocolo            := p_pcfilamensagem.rowpcfilamensagem.protocolo;
        dados_pcfilamensagem.rowpcfilamensagem.contingencia         := p_pcfilamensagem.rowpcfilamensagem.contingencia;
        dados_pcfilamensagem.rowpcfilamensagem.idexterno            := p_pcfilamensagem.rowpcfilamensagem.idexterno;
        dados_pcfilamensagem.rowpcfilamensagem.status               := p_pcfilamensagem.rowpcfilamensagem.status;
        dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento      := p_pcfilamensagem.rowpcfilamensagem.qtprocessamento;
        dados_pcfilamensagem.rowpcfilamensagem.tipodocumento        := p_pcfilamensagem.rowpcfilamensagem.tipodocumento;
        dados_pcfilamensagem.rowpcfilamensagem.tipooperacao         := p_pcfilamensagem.rowpcfilamensagem.tipooperacao;
        dados_pcfilamensagem.rowpcfilamensagem.mensagem             := p_pcfilamensagem.rowpcfilamensagem.mensagem;
        dados_pcfilamensagem.rowpcfilamensagem.tipomensagem         := p_pcfilamensagem.rowpcfilamensagem.tipomensagem;
        dados_pcfilamensagem.rowpcfilamensagem.codigoerro           := p_pcfilamensagem.rowpcfilamensagem.codigoerro;
        dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao  := p_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao;
        dados_pcfilamensagem.rowpcfilamensagem.pdvorigem            := p_pcfilamensagem.rowpcfilamensagem.pdvorigem;
        dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado       := p_pcfilamensagem.rowpcfilamensagem.qtreprocessado;

        ----
        INSERT INTO
            pcfilamensagem s
        VALUES
            dados_pcfilamensagem.rowpcfilamensagem;
    ----
    END inserir_pcfilamensagem;

    --
    -- Inserir inserir_pcfilamensagem_erro
    --
    PROCEDURE inserir_pcfilamensagem_erro(p_pcfilamensagem tr_dados_pcfilamensagem,
                                          p_msg_erro       VARCHAR2)
    IS
        rowpcfilamensagemerro   pcfilamensagemerro%ROWTYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        rowpcfilamensagemerro.idmensagem            := p_pcfilamensagem.rowpcfilamensagem.idmensagem;
        rowpcfilamensagemerro.datatransacao         := p_pcfilamensagem.rowpcfilamensagem.datatransacao;
        rowpcfilamensagemerro.codfilial             := p_pcfilamensagem.rowpcfilamensagem.codfilial;
        rowpcfilamensagemerro.numcaixa              := p_pcfilamensagem.rowpcfilamensagem.numcaixa;
        rowpcfilamensagemerro.numnota               := p_pcfilamensagem.rowpcfilamensagem.numnota;
        rowpcfilamensagemerro.serie                 := p_pcfilamensagem.rowpcfilamensagem.serie;
        rowpcfilamensagemerro.chavesefaz            := p_pcfilamensagem.rowpcfilamensagem.chavesefaz;
        rowpcfilamensagemerro.protocolo             := p_pcfilamensagem.rowpcfilamensagem.protocolo;
        rowpcfilamensagemerro.contingencia          := p_pcfilamensagem.rowpcfilamensagem.contingencia;
        rowpcfilamensagemerro.idexterno             := p_pcfilamensagem.rowpcfilamensagem.idexterno;
        rowpcfilamensagemerro.status                := p_pcfilamensagem.rowpcfilamensagem.status;
        rowpcfilamensagemerro.qtprocessamento       := p_pcfilamensagem.rowpcfilamensagem.qtprocessamento;
        rowpcfilamensagemerro.tipodocumento         := p_pcfilamensagem.rowpcfilamensagem.tipodocumento;
        rowpcfilamensagemerro.tipooperacao          := p_pcfilamensagem.rowpcfilamensagem.tipooperacao;
        rowpcfilamensagemerro.mensagem              := p_pcfilamensagem.rowpcfilamensagem.mensagem;
        rowpcfilamensagemerro.tipomensagem          := p_pcfilamensagem.rowpcfilamensagem.tipomensagem;
        rowpcfilamensagemerro.codigoerro            := p_pcfilamensagem.rowpcfilamensagem.codigoerro;
        rowpcfilamensagemerro.dataultimaalteracao   := p_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao;
        rowpcfilamensagemerro.pdvorigem             := p_pcfilamensagem.rowpcfilamensagem.pdvorigem;
        rowpcfilamensagemerro.qtreprocessado        := p_pcfilamensagem.rowpcfilamensagem.qtreprocessado;
        rowpcfilamensagemerro.detalhe               := p_msg_erro;

        ----
        INSERT INTO
            pcfilamensagemerro s
        VALUES
            rowpcfilamensagemerro;

        COMMIT;
    ----
    END inserir_pcfilamensagem_erro;

    --
    -- Sangria
    --
    PROCEDURE processar_sangria(p_seqdocto NUMBER DEFAULT 0)
    IS
        CURSOR c_sangria(pnespecie VARCHAR2)
        IS
            SELECT '0' numpedecf,
                   a.codbanco,
                   a.dtlanc,
                   a.numcaixa,
                   a.numvale,
                   a.tipo,
                   a.historico,
                   a.codfunc,
                   NULL codusurautori,
                   a.dtmovimentocx,
                   a.numfechamentomovcx,
                   a.valor,
                   a.codcob,
                   '0' nummalote,
                   '0' numlacre,
                   a.idexterno,
                   a.especie,
                   a.codfilial,
                   a.rowid_tb_docto,
                   a.seqdocto
              FROM vw_int_c5_vales a
             WHERE a.tipo = 'A'
               AND a.seqdocto = DECODE(p_seqdocto,0,a.seqdocto,p_seqdocto);

        r_sangria            c_sangria%ROWTYPE;
        mensagemerro         VARCHAR2(1000);
        dados_pcfilamensagem tr_dados_pcfilamensagem;

        FUNCTION retornar_xml_sangria (p_r_sangria c_sangria%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmltypeesquema   XMLTYPE;
        BEGIN
            SELECT XMLELEMENT (
                        "EsquemaExportacao" ,
                       XMLELEMENT (
                            "Complemento" ,
                           XMLELEMENT (
                                "PCVALECXECF" ,
                               XMLAGG (
                                   XMLELEMENT (
                                        "PCVALECXECF" ,
                                       XMLFOREST (
                                           p_r_sangria.numpedecf AS "Numpedecf" ,
                                           p_r_sangria.codbanco AS  "Codbanco" ,
                                           p_r_sangria.dtlanc AS  "Dtlanc" ,
                                           p_r_sangria.codfilial AS  "Codfilial" ,
                                           p_r_sangria.numcaixa AS  "Numcaixa" ,
                                           p_r_sangria.numvale AS  "Numvale" ,
                                           p_r_sangria.tipo AS  "Tipo" ,
                                           p_r_sangria.historico AS  "Historico" ,
                                           p_r_sangria.codfunc AS  "Codfunc" ,
                                           p_r_sangria.codusurautori AS  "Codusurautori" ,
                                           p_r_sangria.dtmovimentocx AS  "Dtmovimentocx" ,
                                           p_r_sangria.numfechamentomovcx AS  "Numfechamentomovcx" ,
                                           p_r_sangria.valor AS  "Valor" ,
                                           p_r_sangria.codcob AS  "Codcob" ,
                                           p_r_sangria.nummalote AS  "Nummalote" ,
                                           p_r_sangria.numlacre AS  "Numlacre" ,
                                           p_r_sangria.idexterno AS  "Idexterno" ))))))
                       pcvalecxecf
              INTO l_xmltypeesquema
              FROM DUAL;

            RETURN l_xmltypeesquema;
        END retornar_xml_sangria;

        FUNCTION retornar_pcfilamensagem(p_r_sangria c_sangria%ROWTYPE)
            RETURN tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            vsangria               c_sangria%ROWTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            dados_pcfilamensagem.rowpcfilamensagem.idmensagem := dfseq_pcfilamensagem.NEXTVAL;
            vsangria := p_r_sangria;
            vsangria.numvale := dados_pcfilamensagem.rowpcfilamensagem.idmensagem||p_r_sangria.numvale;

            -- recebe xml da sangria
            l_xmltype := retornar_xml_sangria(vsangria);
 
            dados_pcfilamensagem.rowpcfilamensagem.datatransacao            := p_r_sangria.dtlanc;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial                := p_r_sangria.codfilial;
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa                 := p_r_sangria.numcaixa;
            dados_pcfilamensagem.rowpcfilamensagem.numnota                  := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.serie                    := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz               := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo                := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia             := 'N';
            dados_pcfilamensagem.rowpcfilamensagem.idexterno                := dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                                                                            || '-'
                                                                            || p_r_sangria.numvale
                                                                            || '-'
                                                                            || p_r_sangria.numcaixa
                                                                            || '-'
                                                                            || p_r_sangria.especie;
            dados_pcfilamensagem.rowpcfilamensagem.status                   := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento          := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento            := 'OD';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao             := 'SANG';
            dados_pcfilamensagem.rowpcfilamensagem.mensagem                 := REPLACE (l_xmltype.getclobval (),
                                                                                         '<EsquemaExportacao>',
                                                                                         daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.seqdocto                 := p_r_sangria.seqdocto;                                                                            
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem             := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro               := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao      := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem                := 'consinco';
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado           := NULL;

            RETURN dados_pcfilamensagem;
        END retornar_pcfilamensagem;
    BEGIN
        --INÍCIO LOOP SANGRIA
        --
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
        --
        OPEN c_sangria('SG');

        FETCH c_sangria INTO r_sangria;

        WHILE c_sangria%FOUND
        LOOP
            BEGIN
                -- recebe xml da sangria
                --R_SANGRIA.XML := RETORNAR_XML_SANGRIA(R_SANGRIA);
                dados_pcfilamensagem := retornar_pcfilamensagem(r_sangria);
                -- insere os dados da PCFILAMENSAGEM
                inserir_pcfilamensagem(dados_pcfilamensagem);

                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_sangria.rowid_tb_docto;

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    mensagemerro := 'Consinco - erro ao persistir sangria na tabela PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_sangria.rowid_tb_docto;

                    inserir_pcfilamensagem_erro(dados_pcfilamensagem,mensagemerro);
            --ROLLBACK;
            END;

            FETCH c_sangria INTO r_sangria;
        END LOOP;

        CLOSE c_sangria;
    -- FIM LOOP SANGRIA
    END processar_sangria;

    --
    -- Processar suprimento
    --
    PROCEDURE processar_suprimento(p_seqdocto NUMBER DEFAULT 0)
    IS
        CURSOR c_suprimento(pnespecie    VARCHAR2)
        IS
            SELECT '0' numpedecf,
                   a.codbanco,
                   a.dtlanc,
                   a.numcaixa,
                   a.numvale,
                   a.tipo,
                   a.historico,
                   a.codfunc,
                   NULL codusurautori,
                   a.dtmovimentocx,
                   a.numfechamentomovcx,
                   a.valor,
                   a.codcob,
                   '0' nummalote,
                   '0' numlacre,
                   a.idexterno,
                   a.especie,
                   a.codfilial,
                   a.rowid_tb_docto,
                   a.seqdocto
              FROM vw_int_c5_vales a
             WHERE a.tipo = 'U'
               AND a.seqdocto = DECODE(p_seqdocto,0,a.seqdocto,p_seqdocto);

        r_suprimento           c_suprimento%ROWTYPE;
        mensagemerro           VARCHAR2(1000);
        dados_pcfilamensagem   tr_dados_pcfilamensagem;

        FUNCTION retornar_xml_suprimento(pn_r_suprimento c_suprimento%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmltypeesquema   XMLTYPE;
        BEGIN
            SELECT XMLELEMENT (
                        "EsquemaExportacao" ,
                       XMLELEMENT (
                            "Complemento" ,
                           XMLELEMENT (
                                "PCVALECXECF" ,
                               XMLAGG (
                                   XMLELEMENT (
                                        "PCVALECXECF" ,
                                       XMLFOREST (
                                           pn_r_suprimento.numpedecf AS  "Numpedecf" ,
                                           pn_r_suprimento.codbanco AS  "Codbanco" ,
                                           pn_r_suprimento.dtlanc AS  "Dtlanc" ,
                                           pn_r_suprimento.codfilial AS  "Codfilial" ,
                                           pn_r_suprimento.numcaixa AS  "Numcaixa" ,
                                           pn_r_suprimento.numvale AS  "Numvale" ,
                                           pn_r_suprimento.tipo AS  "Tipo" ,
                                           pn_r_suprimento.historico AS  "Historico" ,
                                           pn_r_suprimento.codfunc AS  "Codfunc" ,
                                           pn_r_suprimento.codusurautori AS  "Codusurautori" ,
                                           pn_r_suprimento.dtmovimentocx AS  "Dtmovimentocx" ,
                                           pn_r_suprimento.numfechamentomovcx AS  "Numfechamentomovcx" ,
                                           pn_r_suprimento.valor AS  "Valor" ,
                                           pn_r_suprimento.codcob AS  "Codcob" ,
                                           pn_r_suprimento.nummalote AS  "Nummalote" ,
                                           pn_r_suprimento.numlacre AS  "Numlacre" ,
                                           pn_r_suprimento.idexterno AS  "Idexterno" ))))))
                       pcvalecxecf
              INTO l_xmltypeesquema
              FROM DUAL;

            RETURN l_xmltypeesquema;
        END;

        FUNCTION retornar_pcfilamensagem(p_r_suprimento c_suprimento%ROWTYPE)
            RETURN tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            vsuprimento            c_suprimento%ROWTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            dados_pcfilamensagem.rowpcfilamensagem.idmensagem       := dfseq_pcfilamensagem.NEXTVAL;
            vsuprimento                                             := p_r_suprimento;
            vsuprimento.numvale                                     := dados_pcfilamensagem.rowpcfilamensagem.idmensagem||p_r_suprimento.numvale;
            -- recebe xml de SUPRIMENTO
            l_xmltype := retornar_xml_suprimento (vsuprimento);

            dados_pcfilamensagem.rowpcfilamensagem.datatransacao    := p_r_suprimento.dtlanc;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial        := p_r_suprimento.codfilial;
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa         := p_r_suprimento.numcaixa;
            dados_pcfilamensagem.rowpcfilamensagem.numnota          := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.serie            := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz        := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo        := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia     := 'N';
            dados_pcfilamensagem.rowpcfilamensagem.idexterno        := dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                                                                    || '-'
                                                                    || p_r_suprimento.numvale
                                                                    || '-'
                                                                    || p_r_suprimento.numcaixa
                                                                    || '-'
                                                                    || p_r_suprimento.especie;
            dados_pcfilamensagem.rowpcfilamensagem.seqdocto         := p_r_suprimento.seqdocto;                                                       
            dados_pcfilamensagem.rowpcfilamensagem.status           := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento  := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento    := 'OD';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao     := 'SUPR';
            dados_pcfilamensagem.rowpcfilamensagem.mensagem         := REPLACE (l_xmltype.getclobval (),
                                                                               '<EsquemaExportacao>',
                                                                                daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem         := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro           := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao  := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem            := 'consinco';
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado       := NULL;

            RETURN dados_pcfilamensagem;
        END retornar_pcfilamensagem;
    BEGIN
        -- INÍCIO LOOP C_SUPRIMENTO
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
        --
        OPEN c_suprimento('SP');

        FETCH c_suprimento
         INTO r_suprimento;

        WHILE c_suprimento%FOUND
        LOOP
            BEGIN
                -- insere os dados da PCFILAMENSAGEM
                dados_pcfilamensagem := retornar_pcfilamensagem(r_suprimento);
                inserir_pcfilamensagem(dados_pcfilamensagem);

                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_suprimento.rowid_tb_docto;

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    mensagemerro := 'Consinco - erro ao persistir SUPRIMENTO na tabela PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;
                    inserir_pcfilamensagem_erro (dados_pcfilamensagem,
                                                 mensagemerro);

                    --ATUALIZA O REGISTRO na tabela consinco
                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_suprimento.rowid_tb_docto;
            --ROLLBACK;

            END;

            FETCH c_suprimento INTO r_suprimento;
        END LOOP;

        CLOSE c_suprimento;
    -- FIM LOOP C_SUPRIMENTO
    END processar_suprimento;

    --
    -- Prcessamento de vendas (CABECALHO)
    --
    PROCEDURE processar_venda(p_seqdocto        NUMBER DEFAULT 0,
                              p_nrocheckout     NUMBER DEFAULT 0,
                              p_nroempresa      NUMBER DEFAULT 0)
    IS
        CURSOR c_pedido
        IS                         -- CABECALHO DO PEDIDO
            SELECT *
              FROM vw_int_c5_pcpedcecf c
             WHERE c.seqdocto  = DECODE(p_seqdocto,0,c.seqdocto,p_seqdocto)
               AND c.NUMCAIXA  = DECODE(p_nrocheckout,0,c.NUMCAIXA ,p_nrocheckout)
               AND c.codfilial = DECODE(p_nroempresa,0,c.codfilial,p_nroempresa);

        r_pedido             c_pedido%ROWTYPE;
        l_xmltype            XMLTYPE;
        mensagemerro         VARCHAR2(1000);
        dados_pcfilamensagem tr_dados_pcfilamensagem;

        -- RETORNAR_XML_VENDA
        FUNCTION retornar_xml_venda(r_pedido c_pedido%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmlesquema           XMLTYPE;
            l_xmlitens             XMLTYPE;
            l_xmlcabecalho         XMLTYPE;
            l_xmlparcela           XMLTYPE;
            l_xmldoceletronico     XMLTYPE;
            l_xmlconsumidorfinal   XMLTYPE;
            l_xmllogdadospessoas   XMLTYPE;
            v_numpedecf            NUMBER;

            -- RETORNAR_XML_VENDA ( RETORNAR_XMLITENS )
            FUNCTION retornar_xmlitens(p_numpedecf NUMBER,
                                       p_pedido    c_pedido%ROWTYPE)
                RETURN XMLTYPE
            IS
                l_xmltypeitens XMLTYPE;

            BEGIN
                -- REGRAS DO ITEM NF

                SELECT XMLELEMENT (
                            "Itens" ,
                           XMLAGG (
                               XMLELEMENT (
                                    "PCPEDIECF" ,
                                   XMLFOREST (
                                       rowvw_pcpediecf.exportado AS  "Exportado" ,
                                       p_numpedecf AS  "Numpedecf" ,
                                       rowvw_pcpediecf.numcheckout AS  "Numcheckout" ,
                                       rowvw_pcpediecf.vlitemtributos AS  "Vlitemtributos" ,
                                       rowvw_pcpediecf.aliqfcp AS  "Aliqfcp" ,
                                       rowvw_pcpediecf.aliqicms1 AS  "Aliqicms1" ,
                                       rowvw_pcpediecf.aliqicms1ret AS  "Aliqicms1ret" ,
                                       rowvw_pcpediecf.aliqicms2 AS  "Aliqicms2" ,
                                       rowvw_pcpediecf.aliqicmsfecp AS  "Aliqicmsfecp" ,
                                       rowvw_pcpediecf.aliqinternadest AS  "Aliqinternadest" ,
                                       rowvw_pcpediecf.aliqinterorigpart AS  "Aliqinterorigpart" ,
                                       rowvw_pcpediecf.aliqreducaocofins AS  "Aliqreducaocofins" ,
                                       rowvw_pcpediecf.aliqreducaopis AS  "Aliqreducaopis" ,
                                       rowvw_pcpediecf.anp AS  "Anp" ,
                                       rowvw_pcpediecf.basebcr AS  "Basebcr" ,
                                       rowvw_pcpediecf.baseicms AS  "Baseicms" ,
                                       rowvw_pcpediecf.baseicmsbcr AS  "Baseicmsbcr" ,
                                       rowvw_pcpediecf.baseicst AS  "Baseicst" ,
                                       rowvw_pcpediecf.baseipiecf AS  "Baseipiecf" ,
                                       rowvw_pcpediecf.basemexiva AS  "Basemexiva" ,
                                       rowvw_pcpediecf.bciss AS  "Bciss" ,
                                       rowvw_pcpediecf.brinde AS  "Brinde" ,
                                       rowvw_pcpediecf.cnpjfabricante AS  "Cnpjfabricante" ,
                                       rowvw_pcpediecf.codagregacao AS  "Codagregacao" ,
                                       rowvw_pcpediecf.codauxiliar AS  "Codauxiliar" ,
                                       rowvw_pcpediecf.codbarrabalanca AS  "Codbarrabalanca" ,
                                       rowvw_pcpediecf.codbeneficiofiscal AS  "Codbeneficiofiscal" ,
                                       rowvw_pcpediecf.codcampanha AS  "Codcampanha" ,
                                       rowvw_pcpediecf.codcest AS  "Codcest" ,
                                       rowvw_pcpediecf.codcli AS  "Codcli" ,
                                       rowvw_pcpediecf.codcontrolevasilhame AS  "Codcontrolevasilhame" ,
                                       rowvw_pcpediecf.codfilial AS  "Codfilial" ,
                                       rowvw_pcpediecf.codfilialretira AS  "Codfilialretira" ,
                                       rowvw_pcpediecf.codecf AS  "Codecf" ,
                                       rowvw_pcpediecf.codfiscal AS  "Codfiscal" ,
                                       rowvw_pcpediecf.codfornec AS  "Codfornec" ,
                                       rowvw_pcpediecf.codfunccx AS  "Codfunccx" ,
                                       rowvw_pcpediecf.codicmtab AS  "Codicmtab" ,
                                       rowvw_pcpediecf.codigobrinde AS  "Codigobrinde" ,
                                       rowvw_pcpediecf.codmotivoicmsdesonerado AS  "Codmotivoicmsdesonerado" ,
                                       rowvw_pcpediecf.codprod AS  "Codprod" ,
                                       rowvw_pcpediecf.codst AS  "Codst" ,
                                       NVL(rowvw_pcpediecf.codtribpiscofins ,0) AS  "Codtribpiscofins" ,
                                       rowvw_pcpediecf.codusur AS  "Codusur" ,
                                       rowvw_pcpediecf.codvasilhameecf AS  "Codvasilhameecf" ,
                                       rowvw_pcpediecf.custofinest AS  "Custofinest" ,
                                       rowvw_pcpediecf.custoultent AS  "Custoultent" ,
                                       rowvw_pcpediecf.data AS  "Data" ,
                                       rowvw_pcpediecf.dtexportacao AS  "Dtexportacao" ,
                                       rowvw_pcpediecf.descanp AS  "Descanp" ,
                                       rowvw_pcpediecf.descricaopaf AS  "Descricaopaf" ,
                                       rowvw_pcpediecf.emoferta AS  "Emoferta" ,
                                       rowvw_pcpediecf.enviaraliqreducaopiscofins AS  "Enviaraliqreducaopiscofins" ,
                                       rowvw_pcpediecf.excluiricmsbasepiscofins AS  "Excluiricmsbasepiscofins" ,
                                       rowvw_pcpediecf.fabricante AS  "Fabricante" ,
                                       rowvw_pcpediecf.idcancel AS  "Idcancel" ,
                                       rowvw_pcpediecf.importado AS  "Importado" ,
                                       rowvw_pcpediecf.indescalarelevante AS  "Indescalarelevante" ,
                                       rowvw_pcpediecf.iva AS  "Iva" ,
                                       rowvw_pcpediecf.logerro AS  "Logerro" ,
                                       rowvw_pcpediecf.md5paf AS  "Md5paf" ,
                                       rowvw_pcpediecf.numcaixa AS  "Numcaixa" ,
                                       rowvw_pcpediecf.numcaixafiscal AS  "Numcaixafiscal" ,
                                       rowvw_pcpediecf.numseq AS  "Numseq" ,
                                       rowvw_pcpediecf.numseqorig AS  "Numseqorig" ,
                                       rowvw_pcpediecf.numcar AS  "Numcar" ,
                                       rowvw_pcpediecf.numlista AS  "Numlista" ,
                                       rowvw_pcpediecf.numccf AS  "Numccf" ,
                                       rowvw_pcpediecf.numcoo AS  "Numcoo" ,
                                       rowvw_pcpediecf.numlote AS  "Numlote" ,
                                       rowvw_pcpediecf.numserieequip AS  "Numserieequip" ,
                                       rowvw_pcpediecf.numped AS  "Numped" ,
                                       rowvw_pcpediecf.numserie AS  "Numserie" ,
                                       rowvw_pcpediecf.numseriesat AS  "Numseriesat" ,
                                       rowvw_pcpediecf.origemitem AS  "Origemitem" ,
                                       rowvw_pcpediecf.origmerctrib AS  "Origmerctrib" ,
                                       rowvw_pcpediecf.pauta AS  "Pauta" ,
                                       rowvw_pcpediecf.pbaserca AS  "Pbaserca" ,
                                       rowvw_pcpediecf.peracrescimocusto AS  "Peracrescimocusto" ,
                                       rowvw_pcpediecf.peracrescimofuncep AS  "Peracrescimofuncep" ,
                                       rowvw_pcpediecf.percbasered AS  "Percbasered" ,
                                       rowvw_pcpediecf.percbaseredst AS  "Percbaseredst" ,
                                       rowvw_pcpediecf.percdesccofins AS  "Percdesccofins" ,
                                       rowvw_pcpediecf.percdescpis AS  "Percdescpis" ,
                                       rowvw_pcpediecf.perdifereimentoicms AS  "Perdifereimentoicms" ,
                                       rowvw_pcpediecf.percmexiva AS  "Percmexiva" ,
                                       rowvw_pcpediecf.perciss AS  "Perciss" ,
                                       rowvw_pcpediecf.percicm AS  "Percicm" ,
                                       rowvw_pcpediecf.percicmsefet AS  "Percicmsefet" ,
                                       rowvw_pcpediecf.perccofins AS  "Percofins" ,
                                       rowvw_pcpediecf.percom AS  "Percom" ,
                                       rowvw_pcpediecf.percredbaseefet AS  "Percredbaseefet" ,
                                       rowvw_pcpediecf.perctributos AS  "Perctributos" ,
                                       rowvw_pcpediecf.perctributosestadual AS  "Perctributosestadual" ,
                                       rowvw_pcpediecf.perctributosmunicipal AS  "Perctributosmunicipal" ,
                                       rowvw_pcpediecf.perdesc AS  "Perdesc" ,
                                       rowvw_pcpediecf.perdesccusto AS  "Perdesccusto" ,
                                       rowvw_pcpediecf.perdescisentoicms AS  "Perdescisentoicms" ,
                                       rowvw_pcpediecf.piscofinsdeduzido AS  "Piscofinsdeduzido" ,
                                       rowvw_pcpediecf.percpis AS  "Perpis" ,
                                       rowvw_pcpediecf.pglp AS  "Pglp" ,
                                       rowvw_pcpediecf.pgni AS  "Pgni" ,
                                       rowvw_pcpediecf.pgnn AS  "Pgnn" ,
                                       rowvw_pcpediecf.poriginal AS  "Poriginal" ,
                                       rowvw_pcpediecf.possuicomplemento AS  "Possuicomplemento" ,
                                       rowvw_pcpediecf.posicaoretorno AS  "Posicaoretorno" ,
                                       rowvw_pcpediecf.pvendavasilhame AS  "Pvendavasilhame" ,
                                       rowvw_pcpediecf.posicao AS  "Posicao" ,
                                       rowvw_pcpediecf.ptabela AS  "Ptabela" ,
                                       rowvw_pcpediecf.pvenda AS  "Pvenda" ,
                                       rowvw_pcpediecf.qt AS  "Qt" ,
                                       rowvw_pcpediecf.qtfalta AS  "Qtfalta" ,
                                       rowvw_pcpediecf.qtminatacvenda AS  "Qtminatacvenda" ,
                                       rowvw_pcpediecf.qtsaidavasilhame AS  "Qtsaidavasilhame" ,
                                       rowvw_pcpediecf.qtlitragem AS  "Qtlitragem" ,
                                       rowvw_pcpediecf.qtunitemb AS  "Qtunitemb" ,
                                       rowvw_pcpediecf.rotinalanc AS  "Rotinalanc" ,
                                       rowvw_pcpediecf.sittribut AS  "Sittribut" ,
                                       rowvw_pcpediecf.st AS  "St" ,
                                       rowvw_pcpediecf.stbcr AS  "Stbcr" ,
                                       rowvw_pcpediecf.tipomerc AS  "Tipomerc" ,
                                       rowvw_pcpediecf.truncaritem AS  "Truncaritem" ,
                                       rowvw_pcpediecf.tipoentrega AS  "Tipoentrega" ,
                                       rowvw_pcpediecf.totalizador AS  "Totalizador" ,
                                       rowvw_pcpediecf.txvenda AS  "Txvenda" ,
                                       rowvw_pcpediecf.tipodescatacvenda AS  "Tipodescatacvenda" ,
                                       rowvw_pcpediecf.usapiscofinslit AS  "Usapiscofinslit" ,
                                       rowvw_pcpediecf.usaunidademaster AS  "Usaunidademaster" ,
                                       rowvw_pcpediecf.utilizoumotorcalculo AS  "Utilizoumotorcalculo" ,
                                       rowvw_pcpediecf.vendapbm AS  "Vendapbm" ,
                                       rowvw_pcpediecf.versaoservicopartilha AS  "Versaoservicopartilha" ,
                                       rowvw_pcpediecf.valorultent AS  "Valorultent" ,
                                       rowvw_pcpediecf.vlacrescimofuncep AS  "Vlacrescimofuncep" ,
                                       rowvw_pcpediecf.vlacrescrodape AS  "Vlacrescrodape" ,
                                       rowvw_pcpediecf.vlbaseefet AS  "Vlbaseefet" ,
                                       rowvw_pcpediecf.vlbasefcpicms AS  "Vlbasefcpicms" ,
                                       rowvw_pcpediecf.vlbasefcpst AS  "Vlbasefcpst" ,
                                       rowvw_pcpediecf.vlbasepiscofins AS  "Vlbasepiscofins" ,
                                       rowvw_pcpediecf.vlbcfcpstret AS  "Vlbcfcpstret" ,
                                       rowvw_pcpediecf.vlcofins AS  "Vlcofins" ,
                                       rowvw_pcpediecf.vlcredcofins AS  "Vlcredcofins" ,
                                       rowvw_pcpediecf.vlcredpis AS  "Vlcredpis" ,
                                       rowvw_pcpediecf.vlcustocont AS  "Vlcustocont" ,
                                       rowvw_pcpediecf.vlcustofin AS  "Vlcustofin" ,
                                       rowvw_pcpediecf.vlcustoreal AS  "Vlcustoreal" ,
                                       rowvw_pcpediecf.vlcustorep AS  "Vlcustorep" ,
                                       rowvw_pcpediecf.vldescfin AS  "Vldescfin" ,
                                       rowvw_pcpediecf.vldescicmisencao AS  "Vldescicmisencao" ,
                                       rowvw_pcpediecf.vldescitem AS  "Vldescitem" ,
                                       rowvw_pcpediecf.vldescreducaocofins AS  "Vldescreducaocofins" ,
                                       rowvw_pcpediecf.vldescreducaopis AS  "Vldescreducaopis" ,
                                       rowvw_pcpediecf.vldescrodape AS  "Vldescrodape" ,
                                       rowvw_pcpediecf.vldescsociotorcedor AS  "Vldescsociotorcedor" ,
                                       rowvw_pcpediecf.vlfrete AS  "Vlfrete" ,
                                       rowvw_pcpediecf.vlicmsbcr AS  "Vlicmsbcr" ,
                                       rowvw_pcpediecf.vlicmsdesoneracao AS  "Vlicmsdesoneracao" ,
                                       rowvw_pcpediecf.vlicmsdifaliqpart AS  "Vlicmsdifaliqpart" ,
                                       rowvw_pcpediecf.vlitem AS  "Vlitem" ,
                                       rowvw_pcpediecf.vlitemtributos AS  "Vlitemtributos" ,
                                       rowvw_pcpediecf.vlitemtributosestadual AS  "Vlitemtributosestadual" ,
                                       rowvw_pcpediecf.vlitemtributosmunicipal AS  "Vlitemtributosmunicipal" ,
                                       rowvw_pcpediecf.vliss AS  "Vliss" ,
                                       rowvw_pcpediecf.vlicmspartrem AS  "Vlicmspartrem" ,
                                       rowvw_pcpediecf.vlipi AS  "Vlipi" ,
                                       rowvw_pcpediecf.vlipiecf AS  "Vlipiecf" ,
                                       rowvw_pcpediecf.vloutrasdesp AS  "Vloutrasdesp" ,
                                       rowvw_pcpediecf.vlmexiva AS  "Vlmexiva" ,
                                       rowvw_pcpediecf.vlpis AS  "Vlpis" ,
                                       rowvw_pcpediecf.vlsubtotitem AS  "Vlsubtotitem" ,
                                       rowvw_pcpediecf.vlricmssimplesnac AS  "Vlricmssimplesnac" ,
                                       rowvw_pcpediecf.vpart AS  "Vpart" ))))
                  INTO l_xmltypeitens
                  FROM vw_int_c5_pcpediecf rowvw_pcpediecf
                 WHERE rowvw_pcpediecf.seqdocto = p_pedido.seqdocto
                   AND rowvw_pcpediecf.codfilial = p_pedido.codfilial
                   AND rowvw_pcpediecf.numcaixa = p_pedido.numcaixa;

                --END LOOP;

                RETURN l_xmltypeitens;
            END retornar_xmlitens;

            -- RETORNAR_XML_VENDA ( RETORNAR_XMLCABECALHO )
            FUNCTION retornar_xmlcabecalho(p_pedido         c_pedido%ROWTYPE,
                                           p_numpedecf   IN NUMBER,
                                           p_seqdocto       NUMBER)
                RETURN XMLTYPE
            IS
                l_xmlcabecalho   XMLTYPE;
            BEGIN
                SELECT XMLAGG (
                           XMLELEMENT (
                                "Pedido",
                               XMLFOREST (
                                   p_numpedecf AS "Numpedecf",
                                   p_pedido.serieecf AS "Serieecf",
                                   p_pedido.exportado AS "Exportado",
                                   p_pedido.ambientenfce AS "Ambientenfce",
                                   p_pedido.cartaocrm AS "Cartaocrm",
                                   p_pedido.cgcfrete AS "Cgcfrete",
                                   p_pedido.chavenfce AS "Chavenfce",
                                   p_pedido.chavesat AS "Chavesat",
                                   p_pedido.cnpjintermediador AS "Cnpjintermediador",
                                   p_pedido.codcli AS "Codcli",
                                   p_pedido.codcob AS "Codcob",
                                   p_pedido.numserieequip AS "Numserieequip",
                                   p_pedido.codemitente AS "Codemitente",
                                   p_pedido.codfilial AS "Codfilial",
                                   p_pedido.codfornecfrete AS "Codfornecfrete",
                                   p_pedido.codfunccx AS "Codfunccx",
                                   p_pedido.codplpag AS "Codplpag",
                                   p_pedido.codpraca AS "Codpraca",
                                   p_pedido.codprofissional "Codprofissional",
                                   p_pedido.codretornosat "Codretornosat",
                                   p_pedido.codsefazsat "Codsefazsat",
                                   p_pedido.codstatussat "Codstatussat",
                                   p_pedido.codsupervisor AS "Codsupervisor",
                                   p_pedido.codusur AS "Codusur",
                                   p_pedido.condvenda AS "Condvenda",
                                   p_pedido.contingenciaservidor AS "Contingenciaservidor",
                                   p_pedido.crmconfirmado crmconfirmado,
                                   p_pedido.custofinest AS "Custofinest",
                                   p_pedido.data AS "Data",
                                   p_pedido.datahoraemissaosat AS "Datahoraemissaosat",
                                   p_pedido.descintermediador AS "Descintermediador",
                                   p_pedido.docemissao AS "Docemissao",
                                   p_pedido.dtahoraentradacontigencia AS "Dtahoraentradacontigencia",
                                   p_pedido.dtcancel AS "Dtcancel",
                                   p_pedido.dtentrega AS "Dtentrega",
                                   p_pedido.dtexportacao AS "Dtexportacao",
                                   p_pedido.dtfat AS "Dtfat",
                                   p_pedido.existesefaz AS "Existesefaz",
                                   p_pedido.dthoraautorizacaosefaz AS "Dthoraautorizacaosefaz",
                                   p_pedido.dtmovimentocx AS "Dtmovimentocx",
                                   p_pedido.emaildest AS "Emaildest",
                                   p_pedido.entrega AS "Entrega",
                                   p_pedido.faturanotaservfat AS "Faturanotaservfat",
                                   p_pedido.fichasimportadas AS "Fichasimportadas",
                                   p_pedido.fretedespacho AS "Fretedespacho",
                                   p_pedido.gerardadosnfpaulista AS "Gerardadosnfpaulista",
                                   p_pedido.hora "Hora",
                                   p_pedido.horacontingencia AS "Horacontingencia",
                                   p_pedido.horacupom AS "Horacupom",
                                   p_pedido.horafat AS "Horafat",
                                   p_pedido.identificarclientenfce AS "Identificarclientenfce",
                                   p_pedido.idparceiro AS "Idparceiro",
                                   p_pedido.iefrete AS "Iefrete",
                                   p_pedido.importado AS "Importado",
                                   p_pedido.idtipopresenca AS "Idtipopresenca",
                                   p_pedido.indicadoracrescimo AS "Indicadoracrescimo",
                                   p_pedido.indicadordesconto AS "Indicadordesconto",
                                   p_pedido.jsonvendacrm AS "Jsonvendacrm",
                                   p_pedido.justificativacontingencia AS "Justificativacontingencia",
                                   p_pedido.logerro AS "Logerro",
                                   p_pedido.notadupliquesvc AS "Notadupliquesvc",
                                   p_pedido.naturezanfce AS "Naturezanfce",
                                   p_pedido.numcaixa AS "Numcaixa",
                                   p_pedido.numcar AS "Numcar",
                                   p_pedido.numecf AS "Numecf",
                                   p_pedido.md5listaarq AS "Md5listaarq",
                                   p_pedido.md5paf AS "Md5paf",
                                   p_pedido.minuto AS "Minuto",
                                   p_pedido.minutofat AS "Minutofat",
                                   p_pedido.motoristaveiculo AS "Motoristaveiculo",
                                   p_pedido.minutocupom AS "Minutocupom",
                                   p_pedido.numcaixafiscal AS "Numcaixafiscal",
                                   p_pedido.numexecucao AS "Numexecucao",
                                   p_pedido.numfechamentomovcx AS "Numfechamentomovcx",
                                   p_pedido.numcupom AS "Numcupom",
                                   p_pedido.numitens AS "Numitens",
                                   p_pedido.numlista AS "Numlista",
                                   p_pedido.numorca AS "Numorca",
                                   p_pedido.numregiao AS "Numregiao",
                                   p_pedido.numped AS "Numped",
                                   p_pedido.numpedcanc AS "Numpedcanc",
                                   p_pedido.numpedrca AS "Numpedrca",
                                   p_pedido.numviasmapasep AS "Numviasmapasep",
                                   p_pedido.numserieplacamae AS "Numserieplacamae",
                                   p_pedido.numseriesat AS "Numseriesat",
                                   p_pedido.numsessaosat AS "Numsessaosat",
                                   p_pedido.numtransvenda AS "Numtransvenda",
                                   p_pedido.numvolume AS "Numvolume",
                                   p_pedido.numcheckout AS "Numcheckout",
                                   p_pedido.obsnf1 AS "Obsnf1",
                                   p_pedido.obsnf2 AS "Obsnf2",
                                   p_pedido.obsnf3 AS "Obsnf3",
                                   p_pedido.obsnfce AS "Obsnfce",
                                   p_pedido.operacao AS "Operacao",
                                   p_pedido.percvenda AS "Percvenda",
                                   p_pedido.percicm AS "Percicm",
                                   p_pedido.placaveiculo AS "Placaveiculo",
                                   p_pedido.perdesc AS "Perdesc",
                                   p_pedido.posicao AS "Posicao",
                                   p_pedido.posicaoretorno AS "Posicaoretorno",
                                   p_pedido.prazo1 AS "Prazo1",
                                   p_pedido.prazo2 AS "Prazo2",
                                   p_pedido.prazo3 AS "Prazo3",
                                   p_pedido.prazo4 AS "Prazo4",
                                   p_pedido.prazo5 AS "Prazo5",
                                   p_pedido.prazo6 AS "Prazo6",
                                   p_pedido.prazo7 AS "Prazo7",
                                   p_pedido.prazo9 AS "Prazo9",
                                   p_pedido.prazo10 AS "Prazo10",
                                   p_pedido.prazo11 AS "Prazo11",
                                   p_pedido.prazo12 AS "Prazo12",
                                   p_pedido.prazomedio AS "Prazomedio",
                                   p_pedido.protocolonfce AS "Protocolonfce",
                                   p_pedido.qrcodenfce AS "Qrcodenfce",
                                   p_pedido.qrcodesat AS "Qrcodesat",
                                   --P_PEDIDO.Situacaonfce as "Situacaonfce",
                                   p_pedido.situacaonfce AS "Situacaonfce",
                                   p_pedido.situacaosat AS "Situacaosat",
                                   p_pedido.taxaentrega AS "Taxaentrega",
                                   p_pedido.tipoemissao AS "Tipoemissao",
                                   p_pedido.tipodoc AS "Tipodoc",
                                   p_pedido.tipomovrca AS "Tipomovrca",
                                   p_pedido.tipovenda AS "Tipovenda",
                                   p_pedido.totpeso AS "Totpeso",
                                   p_pedido.totvolume AS "Totvolume",
                                   p_pedido.transportadora AS "Transportadora",
                                   p_pedido.uffrete AS "Uffrete",
                                   p_pedido.ufveiculo AS "Ufveiculo",
                                   p_pedido.uidregistro AS "Uidregistro",
                                   p_pedido.usacredrca AS "Usacredrca",
                                   p_pedido.usadebcredrca AS "Usadebcredrca",
                                   p_pedido.validadoestacionamento AS "Validadoestacionamento",
                                   p_pedido.vendaassistida AS "Vendaassistida",
                                   p_pedido.vendanfseried AS "Vendanfseried",
                                   p_pedido.versaofaturamento AS "Versaofaturamento",
                                   p_pedido.versaominfaturamento AS "Versaominfaturamento",
                                   p_pedido.vlcustocont AS "Vlcustocont",
                                   p_pedido.vlcustofin AS "Vlcustofin",
                                   p_pedido.vlcustoreal AS "Vlcustoreal",
                                   p_pedido.vlcustorep AS "Vlcustorep",
                                   p_pedido.vlfrete AS "Vlfrete",
                                   p_pedido.vljurosparcelamento AS "Vljurosparcelamento",
                                   p_pedido.vlmexiva AS "Vlmexiva",
                                   p_pedido.xmlnfce AS "Xmlnfce",
                                   p_pedido.versaorotina AS "Versaorotina",
                                   p_pedido.vlcofins AS "Vlcofins",
                                   p_pedido.vloutrasdesp AS "Vloutrasdesp",
                                   p_pedido.vlpis AS "Vlpis",
                                   p_pedido.vltributos AS "Vltributos",
                                   p_pedido.vltributosestadual AS "Vltributosestadual",
                                   p_pedido.vltributosmunicipal AS "Vltributosmunicipal",
                                   p_pedido.vlacrescrodape AS "Vlacrescrodape",
                                   p_pedido.vltotal AS "Vltotal",
                                   p_pedido.vlatend AS "Vlatend",
                                   p_pedido.vltabela AS "Vltabela",
                                   p_pedido.vlsubtotal AS "Vlsubtotal",
                                   p_pedido.vltotalcomtroco AS "Vltotalcomtroco" )))
                  INTO l_xmlcabecalho
                  FROM DUAL;

                RETURN l_xmlcabecalho;
            END retornar_xmlcabecalho;

            -- RETORNAR_XML_VENDA ( RETORNAR_XMLPARCELAS )
            FUNCTION retornar_xmlparcelas(p_numpedecf NUMBER,
                                          p_seqdocto  NUMBER)
                RETURN XMLTYPE
            IS
                l_xmltypeparcela   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                            "Parcelas",
                           XMLAGG (
                               XMLELEMENT (
                                   "PCPRESTECF",
                                   XMLFOREST (
                                       p.numgiftcard AS "Numgiftcard",
                                       p.exportado AS "Exportado",
                                       p_numpedecf AS "Numpedecf",
                                       p.prestecf AS "Prestecf",
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
                                       p.carteiradigital AS "Carteiradigital" ))))
                  INTO l_xmltypeparcela
                  FROM vw_int_c5_pcprestecf p
                 WHERE p.seqdocto = p_seqdocto;

                RETURN l_xmltypeparcela;
            END retornar_xmlparcelas;

            -- RETORNAR_XML_VENDA ( RETORNAR_XMLDOCELETRONICO )
            FUNCTION retornar_xmldoceletronico(p_numpedecf NUMBER,
                                               p_seqdocto  NUMBER)
                RETURN XMLTYPE
            IS
                l_xmltypedoceletronico   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                            "DocumentoEletronico",
                           XMLAGG (
                               XMLELEMENT (
                                   "PCDOCELETRONICOECF",
                                   XMLFOREST (
                                       a.codfilial AS "Codfilial",
                                       a.codfunccx AS "Codfunccx",
                                       a.data AS "Data",
                                       a.dtexportacao AS "Dtexportacao",
                                       a.exportado AS "Exportado",
                                       a.numcaixa AS "Numcaixa",
                                       p_numpedecf AS "Numpedecf",
                                       a.numserieequip AS "Numserieequip",
                                       a.xmlnfce AS "Xmlnfce",
                                       a.xmlnfcecancelamento AS "Xmlnfcecancelamento" ))))
                  INTO l_xmltypedoceletronico
                  FROM vw_int_c5_pcdoceletronico a
                 WHERE a.seqdocto = p_seqdocto;

                RETURN l_xmltypedoceletronico;
            END retornar_xmldoceletronico;

            -- RETORNAR_XML_VENDA ( RETORNAR_XMLCONSUMIDORFINAL )
            FUNCTION retornar_xmlconsumidorfinal(p_numpedecf NUMBER,
                                                  p_seqdocto NUMBER)
                RETURN XMLTYPE
            IS
                l_xmltypeconsumidorfinal   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                            "ConsumidorFinal",
                           XMLAGG (
                               XMLELEMENT (
                                   "PCVENDACONSUMECF",
                                   XMLFOREST (
                                       a.DATA AS "Data",
                                       p_numpedecf AS "Numpedecf",
                                       a.codfunccheckout AS "Codfunccx",
                                       a.numcaixa AS "Numcaixa",
                                       a.codfilial AS "Codfilial",
                                       a.numserieequip AS "Numserieequip",
                                       a.numcupom AS "Numcupom",
                                       NULL AS "Serieecf",
                                       NULL AS "Numped",
                                       a.cliente AS "Cliente",
                                       a.cgcent AS "Cgcent",
                                       a.identificacao_estrangeiro AS "Identificacao_estrangeiro",
                                       a.exportado AS "Exportado" ))))
                  INTO l_xmltypeconsumidorfinal
                  FROM vw_int_c5_pcvendaconsumecf a
                 WHERE a.seqdocto = p_seqdocto;

                RETURN l_xmltypeconsumidorfinal;
            END retornar_xmlconsumidorfinal;

            -- RETORNAR_XML_VENDA ( RETORNAR_XMLLOGDADOSPESSOAS )
            FUNCTION retornar_xmllogdadospessoas (p_numpedecf    NUMBER,
                                                  p_seqdocto     NUMBER)
                RETURN XMLTYPE
            IS
                l_xmltypelogdadospessoas   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                           "LogDadosPessoas",
                           XMLAGG (
                               XMLELEMENT ("PCLOGDADOSPESSOAS",
                                           XMLFOREST ('1' AS "Teste" ))))
                  INTO l_xmltypelogdadospessoas
                  FROM DUAL;

                RETURN l_xmltypelogdadospessoas;
            END retornar_xmllogdadospessoas;
        BEGIN
            v_numpedecf := defseq_numpedecf.NEXTVAL;
            l_xmlitens := retornar_xmlitens(v_numpedecf,r_pedido);
            l_xmlcabecalho := retornar_xmlcabecalho(r_pedido,
                                                    v_numpedecf,
                                                    r_pedido.seqdocto);
            l_xmlparcela            := retornar_xmlparcelas(v_numpedecf,r_pedido.seqdocto);
            l_xmldoceletronico      := retornar_xmldoceletronico(v_numpedecf,r_pedido.seqdocto);
            l_xmlconsumidorfinal    := retornar_xmlconsumidorfinal(v_numpedecf,r_pedido.seqdocto);

            --L_XMLLOGDADOSPESSOAS := RETORNAR_XMLLOGDADOSPESSOAS(V_NUMPEDECF, R_PEDIDO.SEQDOCTO);

            SELECT XMLELEMENT ( "EsquemaExportacao" ,
                               XMLELEMENT ( "Pedido" ,
                                           l_xmlparcela,
                                           l_xmlconsumidorfinal,
                                           l_xmldoceletronico,
                                           l_xmllogdadospessoas,
                                           l_xmlitens,
                                           l_xmlcabecalho))
                       pedido
              INTO l_xmlesquema
              FROM DUAL;

            RETURN l_xmlesquema;
        END retornar_xml_venda;

        -- RETORNAR_PCFILAMENSAGEM
        FUNCTION retornar_pcfilamensagem (r_pedido c_pedido%ROWTYPE)
            RETURN tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            -- recebe xml da VENDA
            l_xmltype := retornar_xml_venda (r_pedido);

            dados_pcfilamensagem.rowpcfilamensagem.idmensagem       := dfseq_pcfilamensagem.NEXTVAL;
            dados_pcfilamensagem.rowpcfilamensagem.datatransacao    := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial        := r_pedido.codfilial;
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa         := r_pedido.numcaixa;
            dados_pcfilamensagem.rowpcfilamensagem.numnota          := r_pedido.numcupom;
            dados_pcfilamensagem.rowpcfilamensagem.serie            := r_pedido.serie;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz       := r_pedido.chavenfe;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo        := r_pedido.protocoloenvio;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia     := (CASE
                                                                            WHEN r_pedido.protocoloenvio IS NULL
                                                                                THEN 'S'
                                                                            ELSE 'N'
                                                                        END);
            dados_pcfilamensagem.rowpcfilamensagem.idexterno        := dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                                                                    || '-'
                                                                    || r_pedido.seqdocto
                                                                    || '-'
                                                                    || r_pedido.numcaixa
                                                                    || '-'
                                                                    || r_pedido.especie;
            dados_pcfilamensagem.rowpcfilamensagem.status           := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento  := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento    := 'CE';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao     := 'VEND';
            dados_pcfilamensagem.rowpcfilamensagem.mensagem         :=  REPLACE (l_xmltype.getclobval (),
                                                                                 '<EsquemaExportacao>',
                                                                                 daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.seqdocto         := r_pedido.seqdocto;                                                                     
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem     := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro       := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem        := 'consinco';
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado   := NULL;

            RETURN dados_pcfilamensagem;
        END retornar_pcfilamensagem;

        PROCEDURE adicionarregrascabecalhonf (
            p_r_pedido   IN OUT c_pedido%ROWTYPE)
        IS
            vvlcofins        NUMBER;
            vvlpis           NUMBER;
            --rowvw_peso       vw_peso%ROWTYPE;
            --rowvw_impostos   vw_impostos%ROWTYPE;
        BEGIN
            --      R_C_PEDIDO :=
            /*SELECT v.*
              INTO rowvw_peso
              FROM vw_peso v
             WHERE     v.seqdocto = p_r_pedido.seqdocto
                   AND v.nrocheckout = p_r_pedido.numcaixa
                   AND v.nroempresa = p_r_pedido.codfilial;

            BEGIN
                SELECT v.*
                  INTO rowvw_impostos
                  FROM vw_impostos v
                 WHERE     v.seqdocto = p_r_pedido.seqdocto
                       AND v.nrocheckout = p_r_pedido.numcaixa
                       AND v.nroempresa = p_r_pedido.codfilial;
            EXCEPTION
                WHEN OTHERS
                THEN
                    rowvw_impostos := NULL;
            END;*/

            vvlcofins := 0;
                --get_sum_vlcofins (p_r_pedido.seqdocto,
                --                  p_r_pedido.numcaixa,
                --                  p_r_pedido.codfilial);
            vvlpis := 0;
                --get_sum_vlpis (p_r_pedido.seqdocto,
                  --             p_r_pedido.numcaixa,
                  --             p_r_pedido.codfilial);

            p_r_pedido.vlcofins := vvlcofins;
                --(CASE
                 --    WHEN vvlcofins < 1 THEN TO_CHAR (vvlcofins, '0.99')
                 --    ELSE TO_CHAR (vvlcofins)
                -- END);
            p_r_pedido.vlpis := vvlpis;
                --(CASE
                --     WHEN vvlpis < 1 THEN TO_CHAR (vvlpis, '0.99')
                --     ELSE TO_CHAR (vvlpis)
               --  END);

            /*p_r_pedido.totpeso := fnc_int_c5_cab_total_peso(p_r_pedido.seqdocto,
                                                            p_r_pedido.numcaixa,
                                                            p_r_pedido.codfilial);*/
                /*(CASE
                     WHEN rowvw_peso.totpeso < 1
                        THEN TO_CHAR(rowvw_peso.totpeso,'0.99')
                     ELSE
                         TO_CHAR(rowvw_peso.totpeso)
                 END); */
            p_r_pedido.totvolume := fnc_int_c5_cab_total_vol(p_r_pedido.seqdocto,
                                                             p_r_pedido.numcaixa,
                                                             p_r_pedido.codfilial);
            /*  (CASE
                     WHEN rowvw_peso.totvolume < 1
                     THEN
                         TO_CHAR (rowvw_peso.totvolume, '0.99')
                     ELSE
                         TO_CHAR (rowvw_peso.totvolume)
                 END);
            p_r_pedido.vlcustofin :=
                (CASE
                     WHEN rowvw_impostos.vlcustofin < 1
                     THEN
                         TO_CHAR (rowvw_impostos.vlcustofin, '0.99')
                     ELSE
                         TO_CHAR (rowvw_impostos.vlcustofin)
                 END);
            p_r_pedido.vltributos :=
                (CASE
                     WHEN rowvw_impostos.vlitemtributos < 1
                     THEN
                         TO_CHAR (rowvw_impostos.vlitemtributos, '0.99')
                     ELSE
                         TO_CHAR (rowvw_impostos.vlitemtributos)
                 END);
        */
            p_r_pedido.vlacrescrodape   := fnc_int_c5_cab_total_acresc(p_r_pedido.seqdocto,
                                                                       p_r_pedido.numcaixa,
                                                                       p_r_pedido.codfilial);
                /*get_acresc_cupom (p_r_pedido.seqdocto,
                                  p_r_pedido.numcaixa,
                                  p_r_pedido.codfilial);*/
            p_r_pedido.vltotal          := fnc_int_c5_cab_total(p_r_pedido.seqdocto,
                                                                p_r_pedido.numcaixa,
                                                                p_r_pedido.codfilial);
                /*get_cab_total (p_r_pedido.seqdocto,
                               p_r_pedido.numcaixa,
                               p_r_pedido.codfilial);*/
            p_r_pedido.vlatend          := p_r_pedido.vltotal;
            p_r_pedido.vltabela         := p_r_pedido.vltotal;
            p_r_pedido.vlsubtotal       := ROUND(p_r_pedido.vltotal,2);
            p_r_pedido.vltotalcomtroco  := p_r_pedido.vltotal;
        END;
    BEGIN
        ------------- INÍCIO LOOP C_PEDIDO ---------------
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

        OPEN c_pedido;

        FETCH c_pedido   INTO r_pedido;

        WHILE c_pedido%FOUND
        LOOP
            BEGIN
                -- REGRAS DO CABEÇALHO DA NF DE VENDA
                adicionarregrascabecalhonf (r_pedido);
                -- insere os dados da PCFILAMENSAGEM
                dados_pcfilamensagem := retornar_pcfilamensagem (r_pedido);
                inserir_pcfilamensagem(dados_pcfilamensagem);

                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_pedido.rowid_tb_docto;

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    mensagemerro :=
                           'Consinco - erro ao persistir PEDIDO na tabela PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_pedido.rowid_tb_docto;

                    inserir_pcfilamensagem_erro (dados_pcfilamensagem,
                                                 mensagemerro);
            --ROLLBACK;
            END;

            FETCH c_pedido   INTO r_pedido;
        END LOOP;

        CLOSE c_pedido;
    ------------- FIM LOOP C_PEDIDO ---------------
    END processar_venda;

    --
    --
    --
    PROCEDURE processar_movimento_caixa(p_seqdocto NUMBER DEFAULT 0)
    IS
        CURSOR c_logaberturacx
        IS
            SELECT defseq_numpedecf.NEXTVAL numpedecf,
                   a.numcaixa,
                   a.codfunccxatual,
                   a.dtabertura,
                   a.seqturno,
                   a.nroempresa,
                   a.seqdocto,
                   a.especie,
                   a.ROWID rowid_tb_docto
              FROM vw_int_c5_aberturacx a
             WHERE a.especie = 'AC'
               AND a.seqdocto = DECODE(p_seqdocto,0,a.seqdocto,p_seqdocto);

        r_logaberturacx        c_logaberturacx%ROWTYPE;
        l_xmltype              XMLTYPE;
        mensagemerro           VARCHAR2(1000);
        dados_pcfilamensagem   tr_dados_pcfilamensagem;

        -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XML_MOVIMENTO_CAIXA )
        FUNCTION retornar_xml_movimento_caixa (
            r_logaberturacx    c_logaberturacx%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmlesquema        XMLTYPE;
            l_logaberturacx     XMLTYPE;
            l_fechamentomovcx   XMLTYPE;
            l_logcaixa          XMLTYPE;

            -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLLOGABERTURACX )
            FUNCTION retornar_xmllogaberturacx (
                p_logaberturacx    c_logaberturacx%ROWTYPE)
                RETURN XMLTYPE
            IS
                l_xmltypelogaberturacx   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                            "PCLOGABERTURACX" ,
                           XMLAGG (
                               XMLELEMENT (
                                   "PCLOGABERTURACX",
                           XMLAGG (
                               XMLELEMENT (
                                   "PCLOGABERTURACX",
                                   XMLFOREST (
                                       p_logaberturacx.numpedecf AS "Numpedecf",
                                       a.numcaixa AS "Numcaixa",
                                       'F' AS "Posicaoant",
                                       'A' AS "Posicaoatual",
                                       NULL AS "Codfunccxant",
                                       a.codfunccxatual AS "Codfunccxatual", --OPERADOR
                                       a.codfunccxatual AS "Codfuncfiscalcx", --FISCAL
                                       a.dtabertura AS "Dtabertura",
                                       'S' AS "Exportado",
                                       NULL AS "Dtexportacao",
                                       a.seqdocto AS "Numfechamentomovcx" ))))))
                  INTO l_xmltypelogaberturacx
                  FROM vw_int_c5_aberturacx a
                 WHERE a.numcaixa = p_logaberturacx.numcaixa
                   AND a.especie = 'AC'
                   AND a.dtabertura = p_logaberturacx.dtabertura
                   AND a.seqturno = p_logaberturacx.seqturno
                   AND a.nroempresa = p_logaberturacx.nroempresa
                   AND a.codfunccxatual = p_logaberturacx.codfunccxatual
                   AND ROWNUM = 1;

                RETURN l_xmltypelogaberturacx;
            END retornar_xmllogaberturacx;

            -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLFECHAMENTOMOVCX )
            FUNCTION retornar_xmlfechamentomovcx (
                p_logaberturacx    c_logaberturacx%ROWTYPE)
                RETURN XMLTYPE
            IS
                l_xmlfechamentomovcx   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                            "PCFECHAMENTOMOVCX",
                           XMLAGG (
                               XMLELEMENT (
                                   "PCFECHAMENTOMOVCX",
                                   XMLFOREST (
                                       p_logaberturacx.numpedecf AS "Numpedecf", --<Numpedecf>0</Numpedecf>
                                       NULL AS "Exportado",   -->N</Exportado>
                                       a.seqdocto AS "Numfechamentomovcx", -->2854</Numfechamentomovcx>
                                       a.nroempresa AS "Codfilial", -->1</Codfilial>
                                       a.numcaixa AS "Numcaixa", -->1</Numcaixa>
                                       a.codfunccxatual AS "Codfunccx", -->13</Codfunccx>
                                       a.dtabertura AS "Dtmovimentocx", -->2022-09-27</Dtmovimentocx>
                                       a.dtabertura AS "Dtabertura", -->2022-09-27T12:20:27</Dtabertura>
                                       NULL AS "Horaabertura", -->12</Horaabertura>
                                       NULL AS "Minutoabertura", -->9</Minutoabertura>
                                       NULL AS "Dtfechamento", --xsi:nil="true"/>
                                       NULL AS "Horafechamento", --xsi:nil="true"/>
                                       NULL AS "Minutofechamento", --xsi:nil="true"/>
                                       a.seqdocto AS "Nummovimentopdv"  -->149</Nummovimentopdv> NÃO TEM CONTADOR DE MOVIEMNTO
                                                                      ))))
                  INTO l_xmlfechamentomovcx
                  FROM vw_int_c5_aberturacx a
                 WHERE     a.especie IN ('FC', 'FM')
                   AND a.numcaixa = p_logaberturacx.numcaixa
                   AND a.dtabertura = p_logaberturacx.dtabertura
                   AND a.seqturno = p_logaberturacx.seqturno
                   AND a.nroempresa = p_logaberturacx.nroempresa
                   AND a.codfunccxatual = p_logaberturacx.codfunccxatual
                   AND ROWNUM = 1;

                RETURN l_xmlfechamentomovcx;
            END retornar_xmlfechamentomovcx;

            -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLLOGCAIXA )
            FUNCTION retornar_xmllogcaixa (
                p_logaberturacx    c_logaberturacx%ROWTYPE)
                RETURN XMLTYPE
            IS
                l_xmltypepclogcaixa   XMLTYPE;
            BEGIN
                SELECT XMLELEMENT (
                            "PCLOGCAIXA",
                           XMLAGG (
                               XMLELEMENT (
                                   "PCLOGCAIXA",
                                   XMLFOREST (
                                       p_logaberturacx.numpedecf AS "numpedecf",
                                       a.dtabertura AS "Data", -->2022-09-27</Data>
                                       NULL AS "Hora",       --<Hora>12</Hora>
                                       NULL AS "Minuto", --<Minuto>20</Minuto>
                                       a.numcaixa AS "Numcaixa", --->1</Numcaixa>
                                       a.codfunccxatual AS "Codfunccx", --->13</Codfunccx> OPERADOR
                                       a.codfunccxatual AS "Codfiscalcx", --->14</Codfiscalcx> FISCAL
                                       '1' AS "Codcli",
                                       '0' AS "Valor",
                                       CASE a.especie
                                           WHEN 'FC'
                                           THEN
                                                  'Caixa Aberto pelo Fiscal de Caixa'
                                               || ' - '
                                               || a.codfunccxatual
                                               || '' -->4-Caixa Aberto pelo Fiscal de Caixa</Historico>
                                           WHEN 'AC'
                                           THEN
                                                  'Caixa Fechado pelo Fiscal de Caixa'
                                               || ' - '
                                               || a.codfunccxatual
                                               || '' -->4-Caixa Fechado pelo Fiscal de Caixa</Historico>
                                       END AS "Historico",
                                       '0' AS "Numseqitem",
                                       '0' AS "Numcupom",
                                       a.seqdocto AS "Numseq", --->1230012227</Numseq>
                                       a.nroempresa AS "Codfilial", -->1</Codfilial>
                                       NULL AS "Motivocancelamento", -- xsi:nil="true"/>
                                       NULL AS "Dtexportacao", --xsi:nil="true"/>
                                       NULL AS "Exportado"      -->N</Exportado
                                                          ))))
                  INTO l_xmltypepclogcaixa
                  FROM vw_int_c5_aberturacx a
                 WHERE a.especie IN ('AC','FC','CX','FM')
                   AND a.numcaixa = p_logaberturacx.numcaixa
                   AND a.dtabertura = p_logaberturacx.dtabertura
                   AND a.seqturno = p_logaberturacx.seqturno
                   AND a.nroempresa = p_logaberturacx.nroempresa
                   AND a.codfunccxatual = p_logaberturacx.codfunccxatual
                   AND ROWNUM = 1;

                RETURN l_xmltypepclogcaixa;
            END retornar_xmllogcaixa;
        BEGIN
            l_logaberturacx := retornar_xmllogaberturacx (r_logaberturacx);
            l_fechamentomovcx := retornar_xmlfechamentomovcx (r_logaberturacx);
            l_logcaixa := retornar_xmllogcaixa (r_logaberturacx);

            SELECT XMLELEMENT ( "EsquemaExportacao",
                               XMLELEMENT ("Complemento" ,
                                           l_logaberturacx,
                                           l_fechamentomovcx,
                                           l_logcaixa))
                       esquemaexportacao
              INTO l_xmlesquema
              FROM DUAL;

            RETURN l_xmlesquema;
        END retornar_xml_movimento_caixa;

        -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_PCFILAMENSAGEM )
        FUNCTION retornar_pcfilamensagem (
            r_logaberturacx    c_logaberturacx%ROWTYPE)
            RETURN tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            -- recebe xml da VENDA
            l_xmltype := retornar_xml_movimento_caixa(r_logaberturacx);

            dados_pcfilamensagem.rowpcfilamensagem.idmensagem            := dfseq_pcfilamensagem.NEXTVAL;
            dados_pcfilamensagem.rowpcfilamensagem.datatransacao         := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial             := '1';
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa              := '10';
            dados_pcfilamensagem.rowpcfilamensagem.numnota               := 109;
            dados_pcfilamensagem.rowpcfilamensagem.serie                 := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz            := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo             := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia          := 'N';
            dados_pcfilamensagem.rowpcfilamensagem.idexterno             := dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                                                                            || '-'
                                                                            || r_logaberturacx.seqdocto
                                                                            || '-'
                                                                            || r_logaberturacx.numcaixa
                                                                            || '-'
                                                                            || r_logaberturacx.especie;
            dados_pcfilamensagem.rowpcfilamensagem.status                := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento       := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento         := 'OD';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao          := 'MOVC';
            dados_pcfilamensagem.rowpcfilamensagem.mensagem              := REPLACE (l_xmltype.getclobval (),
                                                                                     '<EsquemaExportacao>',
                                                                                     daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.seqdocto              := r_logaberturacx.seqdocto;                                                                         
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem          := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro            := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao   := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem             := 'consinco';
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado        := NULL;

            RETURN dados_pcfilamensagem;
        END retornar_pcfilamensagem;
    BEGIN
        ------------- INÍCIO LOOP C_LOGABERTURACX ---------------
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

        OPEN c_logaberturacx;

        FETCH c_logaberturacx INTO r_logaberturacx;

        WHILE c_logaberturacx%FOUND
        LOOP
            BEGIN
                -- insere os dados da PCFILAMENSAGEM
                dados_pcfilamensagem := retornar_pcfilamensagem (r_logaberturacx);
                inserir_pcfilamensagem(dados_pcfilamensagem);

                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_logaberturacx.rowid_tb_docto;
            EXCEPTION
                WHEN OTHERS
                THEN
                    mensagemerro :=
                           'Consinco - erro ao persistir Abertura/Fechamento de caixa na tabela PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_logaberturacx.rowid_tb_docto;

                    inserir_pcfilamensagem_erro(dados_pcfilamensagem,mensagemerro);
            --ROLLBACK;
            END;

            FETCH c_logaberturacx INTO r_logaberturacx;
        END LOOP;

        CLOSE c_logaberturacx;
    ------------- FIM LOOP C_LOGABERTURACX ---------------
    END processar_movimento_caixa;

    --
    --
    --
    PROCEDURE processar_inutilizacao_nota (p_seqdocto NUMBER DEFAULT 0)
    IS
        CURSOR c_inutilizacao
        IS
            SELECT i.exportado,                            --->N</Exportado>
                   i.codfilial,                    -->1</Codfilial>
                   i.data,                   -->2022-09-22</Data>
                   i.dthoraprocessamento, -->2022-09-22T14:35:35</Dthoraprocessamento>
                   i.justificativa, --->Inutilizao automtica falha de comunicao com SEFAZ</Justificativa>
                   i.numnotainicial, -->10000150</Numnotainicial>
                   i.numnotafinal,    -->10000150</Numnotafinal>
                   i.serie,                          -->101</Serie>
                   i.ano, -- to_char(a.dtcadastro,'MM') --<Ano>2022</Ano>
                   i.codusuario,                 -->13</Codusuario>
                   i.protocoloinutilizacao, -->152220024264664</Protocoloinutilizacao>
                   i.ambiente,                        -->P</Ambiente>
                   i.numcaixa,                     -->1</Numcaixa>
                   i.posicao,                                 -->L</Posicao>
                   i.seqdocto,
                   i.especie,
                   i.ROWID AS rowid_tb_docto
              FROM vw_int_c5_inut i
             WHERE i.seqdocto = DECODE (p_seqdocto,0,i.seqdocto,p_seqdocto);

        r_inutilizacao         c_inutilizacao%ROWTYPE;
        l_xmltype              XMLTYPE;
        mensagemerro           VARCHAR2 (1000);
        dados_pcfilamensagem   tr_dados_pcfilamensagem;

        -- RETORNAR_XML_INUTILIZACAO
        FUNCTION retornar_xml_inutilizacao (
            p_r_inutilizacao    c_inutilizacao%ROWTYPE)
            RETURN XMLTYPE
        IS
        BEGIN
            SELECT XMLELEMENT (
                       "EsquemaExportacao",
                       XMLELEMENT (
                           "Complemento",
                           XMLELEMENT (
                               "PCINUTILIZACAONFCE",
                               XMLAGG (
                                   XMLELEMENT (
                                       "PCINUTILIZACAONFCE",
                                       XMLFOREST (
                                           p_r_inutilizacao.exportado AS "Exportado",
                                           p_r_inutilizacao.codfilial AS "Codfilial", -->1</Codfilial>
                                           p_r_inutilizacao.data AS "Data", -->2022-09-22</Data>
                                           p_r_inutilizacao.dthoraprocessamento AS "Dthoraprocessamento", -->2022-09-22T14:35:35</Dthoraprocessamento>
                                           p_r_inutilizacao.justificativa AS "Justificativa", --->Inutilizao automtica falha de comunicao com SEFAZ</Justificativa>
                                           p_r_inutilizacao.numnotainicial AS "Numnotainicial", -->10000150</Numnotainicial>
                                           p_r_inutilizacao.numnotafinal AS "Numnotafinal", -->10000150</Numnotafinal>
                                           p_r_inutilizacao.serie AS "Serie", -->101</Serie>
                                           p_r_inutilizacao.ano AS "Ano", -- to_char(a.dtcadastro,'MM') --<Ano>2022</Ano>
                                           p_r_inutilizacao.codusuario AS "Codusuario", -->13</Codusuario>
                                           p_r_inutilizacao.protocoloinutilizacao AS "Protocoloinutilizacao", -->152220024264664</Protocoloinutilizacao>
                                           p_r_inutilizacao.ambiente AS "Ambiente", -->P</Ambiente>
                                           p_r_inutilizacao.numcaixa AS "Numcaixa", -->1</Numcaixa>
                                           p_r_inutilizacao.posicao AS "Posicao" ))))))
                       pcinutilizacaonfce
              INTO l_xmltype
              FROM DUAL;

            RETURN l_xmltype;
        END retornar_xml_inutilizacao;

        -- RETORNAR_PCFILAMENSAGEM
        FUNCTION retornar_pcfilamensagem (
            p_r_inutilizacao    c_inutilizacao%ROWTYPE)
            RETURN tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            -- recebe xml para INUTILIZAÇÃO
            l_xmltype := retornar_xml_inutilizacao(p_r_inutilizacao);

            dados_pcfilamensagem.rowpcfilamensagem.idmensagem           := dfseq_pcfilamensagem.NEXTVAL;
            dados_pcfilamensagem.rowpcfilamensagem.datatransacao        := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial            := p_r_inutilizacao.codfilial;
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa             := p_r_inutilizacao.numcaixa;
            dados_pcfilamensagem.rowpcfilamensagem.numnota              := p_r_inutilizacao.numnotainicial;
            dados_pcfilamensagem.rowpcfilamensagem.serie                := p_r_inutilizacao.serie;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz           := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo            := p_r_inutilizacao.protocoloinutilizacao;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia         := 'N';
            dados_pcfilamensagem.rowpcfilamensagem.idexterno            := dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                                                                            || '-'
                                                                            || p_r_inutilizacao.seqdocto
                                                                            || '-'
                                                                            || p_r_inutilizacao.numcaixa
                                                                            || '-'
                                                                            || p_r_inutilizacao.especie;
            dados_pcfilamensagem.rowpcfilamensagem.seqdocto             := p_r_inutilizacao.seqdocto;                    
            dados_pcfilamensagem.rowpcfilamensagem.status               := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento      := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento        := 'CE';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao         := 'VEND';
            dados_pcfilamensagem.rowpcfilamensagem.mensagem             := REPLACE (l_xmltype.getclobval (),
                                                                                    '<EsquemaExportacao>',
                                                                                    daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem         := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro           := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao  := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem            := 'consinco';
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado       := NULL;

            RETURN dados_pcfilamensagem;
        END retornar_pcfilamensagem;
    BEGIN
        --INÍCIO LOOP C_INUTILIZACAO
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

        OPEN c_inutilizacao;

        FETCH c_inutilizacao   INTO r_inutilizacao;

        WHILE c_inutilizacao%FOUND
        LOOP
            BEGIN
                -- insere os dados da PCFILAMENSAGEM
                dados_pcfilamensagem := retornar_pcfilamensagem(r_inutilizacao);
                inserir_pcfilamensagem(dados_pcfilamensagem);

                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_inutilizacao.rowid_tb_docto;
            EXCEPTION
                WHEN OTHERS
                THEN
                    mensagemerro :=
                           'Consinco - erro ao persistir INUTILIZACAO na tabela PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_inutilizacao.rowid_tb_docto;

                    inserir_pcfilamensagem_erro (dados_pcfilamensagem,
                                                 mensagemerro);
            --ROLLBACK;
            END;

            FETCH c_inutilizacao   INTO r_inutilizacao;
        END LOOP;

        CLOSE c_inutilizacao;
    -- FIM LOOP C_INUTILIZACAO
    END processar_inutilizacao_nota;

    --
    --
    --
    PROCEDURE processar_cancelamento (p_seqdocto NUMBER DEFAULT 0)
    IS
        -- PRAGMA AUTONOMOUS_TRANSACTION;
        CURSOR c_canc_cabecalho
        IS
            SELECT *
              FROM vw_int_c5_pcpedccancecf a
             WHERE a.seqdocto =
                       DECODE (p_seqdocto, 0, a.seqdocto, p_seqdocto);

        r_canc_cabecalho       c_canc_cabecalho%ROWTYPE;
        l_xmltype              XMLTYPE;
        mensagemerro           VARCHAR2 (1000);
        dados_pcfilamensagem   tr_dados_pcfilamensagem;
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
                               XMLFOREST(
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
                                   NULL AS "Motivocancelamento",
                                   p_r_canc_cabecalho.numfechamentomovcx AS "Numfechamentomovcx",
                                   p_r_canc_cabecalho.dtmovimentocx AS "Dtmovimentocx",
                                   p_r_canc_cabecalho.vlacresrodape AS "Vlacresrodape",
                                   p_r_canc_cabecalho.notadupliquesvc AS "Notadupliquesvc",
                                   p_r_canc_cabecalho.md5paf AS "Md5paf",
                                   p_r_canc_cabecalho.docemissao AS "Docemissao",
                                   p_r_canc_cabecalho.ambientenfce AS "Ambientenfce",
                                   p_r_canc_cabecalho.dtexportacaoservint AS "Dtexportacaoservint",
                                   p_r_canc_cabecalho.dtimportacaoservprinc AS "Dtimportacaoservprinc",
                                   p_r_canc_cabecalho.exportadoservint AS "Exportadoservint",
                                   p_r_canc_cabecalho.importadoservprinc AS "Importadoservprinc",
                                   p_r_canc_cabecalho.rotinalanc AS "Rotinalanc",
                                   p_r_canc_cabecalho.assinatura AS "Assinatura" ))))
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
                        "PCPEDICANCECF" ,
                       XMLAGG (
                           XMLELEMENT (
                                "PCPEDICANCECF" ,
                               XMLFOREST (
                                   'N' AS  "Exportado" ,
                                   p_r_canc_cabecalho.numpedecf AS  "Numpedecf" ,
                                   i.codfunccx AS  "Codfunccx" ,
                                   i.numcaixa AS  "Numcaixa" ,
                                   'NOTAFISCAL' AS  "Numserieequip" ,
                                   i.Codprod AS  "Codprod" ,
                                   i.numseq AS  "Numseq" ,
                                   i.dtcancelecf AS  "Dtcancelecf" ,
                                   i.codfunccancelecf AS  "Codfunccancelecf" ,
                                   i.data AS  "Data" ,
                                   i.codcli AS  "Codcli" ,
                                   i.codusur  "Codusur" ,
                                   i.qt AS  "Qt" ,
                                   i.pvenda AS  "Pvenda" ,
                                   i.poriginal  "Poriginal" ,
                                   0 AS  "St" ,
                                   0 AS  "Percom" ,
                                   0 AS  "Perdesc" ,
                                   0 AS  "Vlcustofin" ,
                                   0 AS  "Vlcustoreal" ,
                                   0 AS  "Vlcustorep" ,
                                   0 AS  "Vlcustocont" ,
                                   0 AS  "Qtfalta" ,
                                   i.codauxiliar  "Codauxiliar" ,
                                   --i.nrotributacao as  "Codst" ,
                                   i.codst AS  "Codst" ,
                                   i.poriginal  "Poriginal" ,
                                   0 AS  "Percbaseredstfonte" ,
                                   0 AS  "Vlipi" ,
                                   0 AS  "Percipi" ,
                                   0 AS  "Percbaseredst" ,
                                   0 AS  "Perfretecmv" ,
                                   NULL AS  "Numcar" ,
                                   NULL AS  "Numped" ,
                                   'N' AS  "Importado" ,
                                   NULL AS  "Posicaoretorno" ,
                                   i.dtcancel  "Dtcancel" ,
                                   i.codfunccancel AS  "Codfunccancel" ,
                                   i.dtexportacao AS  "Dtexportacao" ,
                                   NULL AS  "Totalizador" ,
                                   i.codfilial AS  "Codfilial" ,
                                   NULL AS  "Motivocancelamento" ,
                                   i.cupomfechado AS  "Cupomfechado" ,
                                   NULL AS  "Vldescrodape" ,
                                   NULL AS  "Cancmanual" ,
                                   NULL AS  "Md5paf" ,
                                   i.codcest AS  "Codcest" ,
                                   0 AS  "Numccf" ,
                                   i.vldescfin AS  "Vldescfin" ,
                                   NULL AS  "Vloutrasdesp" ,
                                   NULL AS  "Vlacrescrodape" ,
                                   i.tipocancel AS  "Tipocancel" ,
                                   NULL AS  "Dtexportacaoservint" ,
                                   NULL AS  "Dtimportacaoservprinc" ,
                                   NULL AS  "Exportadoservint" ,
                                   NULL AS  "Importadoservprinc" ,
                                   i.numcupom AS  "Numcupom" ,
                                   NULL AS  "Percbasered" ,
                                   NULL AS  "Percicm" ,
                                   '2099' AS  "Rotinalanc" ))))
              INTO l_xmltypeitens
              FROM vw_int_c5_pcpedicancecf i
             WHERE i.seqdocto =
                           DECODE (p_r_canc_cabecalho.seqdocto,
                                   0, i.seqdocto,
                                   p_r_canc_cabecalho.seqdocto)
                   AND i.codfilial = p_r_canc_cabecalho.codfilial
                   AND i.numcaixa = p_r_canc_cabecalho.numcaixa;

            RETURN l_xmltypeitens;
        END retornar_xml_canc_itens;

        -- RETORNAR_CANCELAMENTO
        FUNCTION retornar_cancelamento (
            p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
            RETURN XMLTYPE
        IS
            l_xmlesquema     XMLTYPE;
            l_xmlitens       XMLTYPE;
            l_xmlcabecalho   XMLTYPE;
        BEGIN
            l_xmlcabecalho := retornar_xml_canc_cabecalho (p_r_canc_cabecalho);
            l_xmlitens := retornar_xml_canc_itens (p_r_canc_cabecalho);

            SELECT XMLELEMENT (
                        "EsquemaExportacao" ,
                       XMLELEMENT ( "Complemento" , l_xmlitens, l_xmlcabecalho))
                       esquemaexportacao
              INTO l_xmlesquema
              FROM DUAL;

            RETURN l_xmlesquema;
        END retornar_cancelamento;

        -- RETORNAR_PCFILAMENSAGEM
        FUNCTION retornar_pcfilamensagem_canc (
            p_r_canc_cabecalho    c_canc_cabecalho%ROWTYPE)
            RETURN tr_dados_pcfilamensagem
        IS
            dados_pcfilamensagem   tr_dados_pcfilamensagem;
            l_xmltype              XMLTYPE;
            daodoscabecalhoxml     VARCHAR2 (200)
                := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <EsquemaExportacao xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">';
        BEGIN
            -- recebe xml para CANCELAMENTO
            l_xmltype := retornar_cancelamento (p_r_canc_cabecalho);

            dados_pcfilamensagem.rowpcfilamensagem.idmensagem :=
                dfseq_pcfilamensagem.NEXTVAL;
            dados_pcfilamensagem.rowpcfilamensagem.datatransacao := SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.codfilial :=
                p_r_canc_cabecalho.codfilial;
            dados_pcfilamensagem.rowpcfilamensagem.numcaixa :=
                p_r_canc_cabecalho.numcaixa;
            dados_pcfilamensagem.rowpcfilamensagem.numnota :=
                p_r_canc_cabecalho.numcupom;
            dados_pcfilamensagem.rowpcfilamensagem.serie := NULL; --P_R_CANC_CABECALHO.SERIEECF;
            dados_pcfilamensagem.rowpcfilamensagem.chavesefaz := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.protocolo := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.contingencia := 'N';
            dados_pcfilamensagem.rowpcfilamensagem.idexterno :=
                   dados_pcfilamensagem.rowpcfilamensagem.idmensagem
                || '-'
                || p_r_canc_cabecalho.seqdocto
                || '-'
                || p_r_canc_cabecalho.numcaixa
                || '-'
                || p_r_canc_cabecalho.especie;
            dados_pcfilamensagem.rowpcfilamensagem.seqdocto := p_r_canc_cabecalho.seqdocto;    
            dados_pcfilamensagem.rowpcfilamensagem.status := 0;
            dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.tipodocumento := 'CE';
            dados_pcfilamensagem.rowpcfilamensagem.tipooperacao :=
                CASE
                    WHEN p_r_canc_cabecalho.tipocancel = 'P' THEN 'CANP'
                    ELSE 'CANT'
                END;
            dados_pcfilamensagem.rowpcfilamensagem.mensagem :=
                REPLACE (l_xmltype.getclobval (),
                         '<EsquemaExportacao>',
                         daodoscabecalhoxml);
            dados_pcfilamensagem.rowpcfilamensagem.tipomensagem := 1;
            dados_pcfilamensagem.rowpcfilamensagem.codigoerro := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao :=
                SYSDATE;
            dados_pcfilamensagem.rowpcfilamensagem.pdvorigem := NULL;
            dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado := NULL;

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
                          FROM (SELECT COUNT(1) contavenda
                                  FROM pcfilamensagem s
                                 WHERE s.idexterno LIKE '%-'||p_r_canc_cabecalho.seqdocto||'-%'
                                   AND codfilial = p_r_canc_cabecalho.codfilial
                                   AND numcaixa = p_r_canc_cabecalho.numcaixa
                                   AND s.tipooperacao = 'VEND'
                                   AND TRUNC(datatransacao) = TRUNC(SYSDATE)
                                UNION ALL
                                SELECT COUNT(1) contavenda
                                  FROM pcfilamensagemerro s
                                 WHERE s.idexterno LIKE '%-'||p_r_canc_cabecalho.seqdocto||'-%'
                                   AND codfilial = p_r_canc_cabecalho.codfilial
                                   AND numcaixa = p_r_canc_cabecalho.numcaixa
                                   AND s.tipooperacao = 'VEND'
                                   AND TRUNC(datatransacao) = TRUNC(SYSDATE)
                                UNION ALL
                                SELECT COUNT (1) contavenda
                                  FROM pcfilamensagemhistorico s
                                 WHERE s.idexterno LIKE '%-'||p_r_canc_cabecalho.seqdocto||'-%'
                                   AND codfilial = p_r_canc_cabecalho.codfilial
                                   AND numcaixa = p_r_canc_cabecalho.numcaixa
                                   AND s.tipooperacao = 'VEND'
                                   AND TRUNC(datatransacao) = TRUNC(SYSDATE)));
            END;
        BEGIN
            verificar_se_venda_existe;

            IF (vcontavenda = 0)
            THEN
                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto s
                   SET replicacao = 'P'
                 WHERE ROWID = p_r_canc_cabecalho.rowid_tb_docto;

                UPDATE monitorpdvmiddle.tb_doctocupom s
                   SET status = 'V'
                 WHERE seqdocto = p_r_canc_cabecalho.seqdocto
                   AND nrocheckout = p_r_canc_cabecalho.numcaixa
                   AND nroempresa = p_r_canc_cabecalho.codfilial
                   AND s.status = 'C';

                -- commit;

                processar_venda(p_r_canc_cabecalho.seqdocto,
                                p_r_canc_cabecalho.numcaixa,
                                p_r_canc_cabecalho.codfilial);

                UPDATE monitorpdvmiddle.tb_doctocupom s
                   SET status = 'C'
                 WHERE seqdocto = p_r_canc_cabecalho.seqdocto
                   AND nrocheckout = p_r_canc_cabecalho.numcaixa
                   AND nroempresa = p_r_canc_cabecalho.codfilial
                   AND s.status = 'V';


                verificar_se_venda_existe;

                IF (vcontavenda = 0)
                THEN
                    RAISE e_venda_nao_existe;
                END IF;
            END IF;

            COMMIT;
        END;

        PROCEDURE adicionarregrascabecalhonf (
            r_canc_cabecalho   IN OUT c_canc_cabecalho%ROWTYPE)
        IS
            vnumpedecf pcpedcecf.numpedecf%TYPE;
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

            r_canc_cabecalho.numpedecf := COALESCE (vnumpedecf, defseq_numpedecf.NEXTVAL);
            --r_canc_cabecalho.codcli :=  NVL(r_canc_cabecalho.seqpessoa,1);
            r_canc_cabecalho.codpraca := COALESCE (fnc_int_c5_codpraca_cli(r_canc_cabecalho.codcli), 0);
            r_canc_cabecalho.codsupervisor := NVL(fnc_int_c5_codsuperv(r_canc_cabecalho.codemitente),
            COALESCE(fnc_int_c5_codsuperv(r_canc_cabecalho.codemitente),0));
            r_canc_cabecalho.codcob := fnc_int_c5_cobranca_cab(r_canc_cabecalho.seqdocto,r_canc_cabecalho.numcaixa,r_canc_cabecalho.codfilial);
            r_canc_cabecalho.vltotal := fnc_int_c5_cab_total (r_canc_cabecalho.seqdocto,r_canc_cabecalho.numcaixa,r_canc_cabecalho.codfilial);
            r_canc_cabecalho.vlatend := r_canc_cabecalho.vltotal;
            r_canc_cabecalho.vltabela := r_canc_cabecalho.vltotal;
            r_canc_cabecalho.vldesconto :=FNC_INT_C5_CAB_TOTAL_DESC( r_canc_cabecalho.seqdocto,r_canc_cabecalho.numcaixa,r_canc_cabecalho.codfilial);
            r_canc_cabecalho.numitens := FNC_INT_C5_NUMITENS(r_canc_cabecalho.seqdocto,r_canc_cabecalho.numcaixa,r_canc_cabecalho.codfilial);
            r_canc_cabecalho.vlacresrodape := fnc_int_c5_cab_total_acresc(r_canc_cabecalho.seqdocto,r_canc_cabecalho.numcaixa,r_canc_cabecalho.codfilial);
            r_canc_cabecalho.docemissao := 'CE';
        END;
    BEGIN
        --INÍCIO LOOP C_CANC_CABECALHO
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

        OPEN c_canc_cabecalho;

        FETCH c_canc_cabecalho   INTO r_canc_cabecalho;

        WHILE c_canc_cabecalho%FOUND
        LOOP
            BEGIN
                gerar_venda_caso_nao_exista (r_canc_cabecalho);

                -- REGRAS DO CABEÇALHO DO CANCELAMENTO
                adicionarregrascabecalhonf (r_canc_cabecalho);

                -- insere os dados da PCFILAMENSAGEM
                dados_pcfilamensagem := retornar_pcfilamensagem_canc (r_canc_cabecalho);
                inserir_pcfilamensagem (dados_pcfilamensagem);

                --ATUALIZA O REGISTRO na tabela consinco
                UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_canc_cabecalho.rowid_tb_docto;

                COMMIT;
            EXCEPTION
                WHEN e_venda_nao_existe
                THEN
                    mensagemerro :=
                           ' A venda não existe para o cancelamento - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_canc_cabecalho.rowid_tb_docto;

                    inserir_pcfilamensagem_erro (dados_pcfilamensagem,
                                                 mensagemerro);
                WHEN OTHERS
                THEN
                    mensagemerro :=
                           'Consinco - erro ao persistir CANC_CABECALHO na tabela PCFILAMENSAGEM - ERROR: '
                        || SQLCODE
                        || '-'
                        || SQLERRM
                        || '- LINHA: '
                        || DBMS_UTILITY.format_error_backtrace;

                    UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_canc_cabecalho.rowid_tb_docto;

                    inserir_pcfilamensagem_erro (dados_pcfilamensagem,
                                                 mensagemerro);
            --ROLLBACK;
            END;

            FETCH c_canc_cabecalho   INTO r_canc_cabecalho;
        END LOOP;

        CLOSE c_canc_cabecalho;

        COMMIT;
    -- FIM LOOP C_CANC_CABECALHO
    END processar_cancelamento;
END PKG_INT_C5_VENDAS;
