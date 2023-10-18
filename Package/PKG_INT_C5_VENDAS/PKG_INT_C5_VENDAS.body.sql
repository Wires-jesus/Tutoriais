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
        dados_pcfilamensagem.rowpcfilamensagem.seqdocto             := p_pcfilamensagem.rowpcfilamensagem.seqdocto;
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
        --PRAGMA AUTONOMOUS_TRANSACTION;
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
		rowpcfilamensagemerro.seqdocto              := p_pcfilamensagem.rowpcfilamensagem.seqdocto;
        rowpcfilamensagemerro.detalhe               := p_msg_erro;
        
        ----
        INSERT INTO
            pcfilamensagemerro s
        VALUES
            rowpcfilamensagemerro;

        --COMMIT;
    ----
    END inserir_pcfilamensagem_erro;
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
               AND c.codfilial = DECODE(p_nroempresa,0,c.codfilial,p_nroempresa)
			   AND NOT EXISTS (SELECT 1
                                 FROM PCFILAMENSAGEM M
								WHERE M.SEQDOCTO = c.seqdocto
								  AND M.NUMCAIXA = c.numcaixa
								  AND M.CODFILIAL = c.codfilial
								  AND M.TIPOOPERACAO  = 'VEND'
								UNION ALL
							   SELECT 1
								 FROM PCFILAMENSAGEMHISTORICO MH
								WHERE MH.SEQDOCTO = c.seqdocto
								  AND MH.NUMCAIXA = TO_CHAR(c.numcaixa)
								  AND MH.CODFILIAL = c.codfilial
								  AND MH.TIPOOPERACAO  = 'VEND'
								UNION ALL
							   SELECT 1
								 FROM PCFILAMENSAGEMERRO ME
								WHERE ME.SEQDOCTO = c.seqdocto
								  AND ME.NUMCAIXA = c.numcaixa
								  AND ME.CODFILIAL = c.codfilial
								  AND ME.TIPOOPERACAO  = 'VEND');

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
                                       rowvw_pcpediecf.vpart AS  "Vpart"
									   ))))
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
                                   p_pedido.vltotalcomtroco AS "Vltotalcomtroco" ,
								   0 AS "Multiplospedidos",
								   0 AS "Idprevenda" )))
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
				if r_pedido.status = 'C'  then
                  PKG_INT_C5_CANCELAMENTO.PROCESSAR_CANCELAMENTO(r_pedido.seqdocto, r_pedido.numcaixa, r_pedido.codfilial);
                end if;

                --ATUALIZA O REGISTRO na tabela consinco
                /*UPDATE monitorpdvmiddle.tb_docto
                   SET replicacao = 'F'
                 WHERE ROWID = r_pedido.rowid_tb_docto;*/

                --COMMIT;
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

                    /*UPDATE monitorpdvmiddle.tb_docto
                       SET replicacao = 'E'
                     WHERE ROWID = r_pedido.rowid_tb_docto;*/

                    inserir_pcfilamensagem_erro (dados_pcfilamensagem,
                                                 mensagemerro);
            --ROLLBACK;
            END;

            FETCH c_pedido   INTO r_pedido;
        END LOOP;

        CLOSE c_pedido;
    ------------- FIM LOOP C_PEDIDO ---------------
    END processar_venda;

END PKG_INT_C5_VENDAS;
