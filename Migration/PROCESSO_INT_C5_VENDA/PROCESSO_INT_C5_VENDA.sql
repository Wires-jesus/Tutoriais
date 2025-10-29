CREATE OR REPLACE VIEW vw_int_c5_pcpedcecf AS
(SELECT  a.seqdocto,
        nf.chavenf chavenfe,
        nf.protocoloenvio,
        c.seriedocto serie,
        a.especie,
        a.ROWID rowid_tb_docto,
        0 numpedecf,
        'X' serieecf,
        'N' exportado,
        nf.ambiente ambientenfce,
        NVL(c.seqpessoa,FNC_INT_C5_CODCLIORCA(a.seqdocto, a.NROEMPRESA,a.nrocheckout)) codcli,
        CASE WHEN NF.DOCEMISSAO = 'CE' THEN 'NOTAFISCAL' ELSE TO_CHAR(NF.NUMSERIESAT) END  numserieequip,
        a.sequsuario codemitente,
        C5.CODFILIAL codfilial,
        a.sequsuario codfunccx,
        NVL(FNC_INT_C5_ESPECIE_COB_VENDAS(a.seqdocto, a.nrocheckout, a.nroempresa, 1),'D') codcob,
        NVL(
        (SELECT fnc_int_c5_codplpag_venda(g.nroformapagto,g.nroempresa)
           FROM monitorpdvmiddle.tb_doctopagto g
          WHERE g.nroempresa = a.nroempresa
            AND g.nrocheckout = a.nrocheckout
            AND g.seqdocto = a.seqdocto
            AND ROWNUM = 1),1) codplpag,

        (SELECT fnc_int_c5_tipovenda_pag_venda(g.nroformapagto,g.nroempresa,g.nrocheckout, g.seqdocto)
           FROM monitorpdvmiddle.tb_doctopagto g
          WHERE g.nroempresa = a.nroempresa
            AND g.nrocheckout = a.nrocheckout
            AND g.seqdocto = a.seqdocto
            AND ROWNUM = 1) tipovenda,
        NVL(fnc_int_c5_praca_cli(c.seqpessoa),1) codpraca,
        NVL(fnc_int_c5_codsuperv(a.sequsuario),1) codsupervisor,
        NVL(
          (
            SELECT NROVENDEDOR 
             FROM MONITORPDVMIDDLE.TB_DOCTOITEM 
             WHERE SEQDOCTO = A.SEQDOCTO AND NROCHECKOUT = A.NROCHECKOUT AND NROEMPRESA = A.NROEMPRESA AND ROWNUM = 1),
          NVL(fnc_int_c5_codusur(a.sequsuario),1)
        ) codusur,
        'N' contingenciaservidor,
        fnc_int_c5_tot_custofin(a.seqdocto, a.nrocheckout, a.nroempresa) custofinest,
        TO_CHAR(a.DTAMOVIMENTO,'YYYY-MM-DD') DATA,
        nf.docemissao docemissao,
        TO_CHAR(a.DTAMOVIMENTO,'YYYY-MM-DD') dtentrega,
        TO_CHAR(nf.dtahorrecebimento,'YYYY-MM-DD') dthoraautorizacaosefaz,
        TO_CHAR(a.DTAMOVIMENTO,'YYYY-MM-DD') dtmovimentocx,
        NULL cartaocrm,
        NULL cgcfrete,
        NULL dtahoraentradacontigencia,
        NULL cnpjintermediador,
        NULL dtcancel,
        NULL codfornecfrete,
        NULL codprofissional,
        NULL codretornosat,
        nf.DTAHORRECEBIMENTO datahoraemissaosat,
        NULL descintermediador,
        NULL crmconfirmado,
        NULL dtexportacao,
        NULL dtfat,
        NULL existesefaz,
        NULL emaildest,
        NULL horafat,
        NULL idparceiro,
        NULL iefrete,
        NULL importado,
        NULL indicadoracrescimo,
        NULL indicadordesconto,
        NULL jsonvendacrm,
        NULL logerro,
        NULL notadupliquesvc,
        NULL naturezanfce,
        FNC_INT_C5_OBTERNUMCAR(a.seqdocto, a.nroempresa, a.nrocheckout) numcar,
        NULL numecf,
        NULL md5listaarq,
        NULL md5paf,
        NULL motoristaveiculo,
        NULL numexecucao,
        NULL numlista,
        NULL numorca,
        FNC_INT_C5_OBTERNUMPED(a.seqdocto, a.nroempresa, a.nrocheckout) numped,
        NULL numpedcanc,
        NULL numpedrca,
        NULL numserieplacamae,
        NULL numtransvenda,
        NULL obsnf1,
        NULL obsnf2,
        NULL obsnf3,
        NULL obsnfce,
        NULL percicm,
        NULL placaveiculo,
        1 condvenda,
        'N' entrega,
        'S' faturanotaservfat,
        'N' gerardadosnfpaulista,
        TO_CHAR(a.DTAHOREMISSAO,'HH24') hora,
        TO_CHAR(a.DTAHOREMISSAO,'HH24:mm:ss') horacupom,
        TO_CHAR(a.DTAHOREMISSAO,'mm') minuto,
        TO_CHAR(a.DTAHOREMISSAO,'mm') minutocupom,
        (CASE
            WHEN c.seqpessoa < 4
                 AND
                 c.cnpjcpf IS NOT NULL
                THEN 'S'
            ELSE
                'N'
         END) identificarclientenfce,
        NULL posicaoretorno,
        1 idtipopresenca,
        NULL justificativacontingencia,
        c.seriedocto numcaixafiscal,
        0 numfechamentomovcx,
        case when nf.docemissao in ('SF', 'MF') then nf.NUMCUPOMSAT else c.nronotafiscal end numcupom,
        fnc_int_c5_numitens(a.seqdocto, a.nrocheckout, a.nroempresa) numitens,
        ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',a.nroempresa,1) numregiao,
        1 numviasmapasep,
        0 taxaentrega,
        1 tipoemissao,
        0 totvolume,
        NULL transportadora,
        NULL uffrete,
        NULL ufveiculo,
        NULL uidregistro,
        NVL((SELECT Usadebcredrca
               FROM PCPEDC
              WHERE NUMPED = NVL(FNC_INT_C5_OBTERNUMPED(a.seqdocto, a.nroempresa, a.nrocheckout), -1)), 'X') Usadebcredrca,
        NULL validadoestacionamento,
        NULL vendaassistida,
        NULL vendanfseried,
        NULL versaofaturamento,
        NULL versaominfaturamento,
        NULL tipodoc,
        0 numvolume,
        'N' operacao,
        100 percvenda,
        (CASE
            WHEN fnc_int_c5_perdesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0
                 THEN (fnc_int_c5_perdesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) * -1)
            WHEN fnc_int_c5_perdesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0
                 THEN (fnc_int_c5_perdesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) * -1)
            ELSE
              0
          END) perdesc,
        (CASE
            WHEN fnc_int_c5_valordesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0 
                 AND fnc_int_c5_valordesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0
            THEN (fnc_int_c5_valordesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) * -1) 
                 + fnc_int_c5_valordesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto)
                                  
            ELSE CASE
                    WHEN fnc_int_c5_valordesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0 
                    THEN (fnc_int_c5_valordesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) * -1)
                           
                    WHEN fnc_int_c5_valordesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0
                    THEN fnc_int_c5_valordesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto)
                    ELSE 0
                 END
        END) vldesconto,        
        'L' posicao,
        DBMS_LOB.SUBSTR(nf.qrcodenf,4000,1) qrcodenfce,
        100 situacaonfce,
        ferramentas.F_BUSCARPARAMETRO_ALFA('CON_TIPOMOVRCA','99','FF') tipomovrca,
        ferramentas.F_BUSCARPARAMETRO_ALFA('CON_USACREDRCA','99','F') usacredrca,
        'C5-' || a.versaoaplicacao versaorotina,
        (SELECT i.numdias
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazomedio,
        (SELECT i.prazo1
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo1,
        (SELECT i.prazo2
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo2,
        (SELECT i.prazo3
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo3,
        (SELECT i.prazo4
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo4,
        (SELECT i.prazo5
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo5,
        (SELECT i.prazo6
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo6,
        (SELECT i.prazo7
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo7,
        (SELECT i.prazo8
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo8,
        (SELECT i.prazo9
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo9,
        (SELECT i.prazo10
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo10,
        (SELECT i.prazo11
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo11,
        (SELECT i.prazo12
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
        AND i.NROCHECKOUT = a.NROCHECKOUT
        AND i.NROEMPRESA = a.NROEMPRESA
            AND ROWNUM = 1) prazo12,
        0 vlcustofin,
        0 vlcustoreal,
        0 vlcustocont,
        0 vlcustorep,
        fnc_int_c5_total_acresc_r(a.nroempresa,a.NROCHECKOUT,a.seqdocto) vlacresrodape,
        fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA) vltotal,
        fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA) vlatend,
        fnc_int_c5_total_ptabela(a.nroempresa,a.NROCHECKOUT,a.seqdocto) vltabela,
        ROUND(fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA),6) Vlsubtotal,
        fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA) Vltotalcomtroco,
        0 Vltributos,
        0 Vltributosestadual,
        0 Vltributosmunicipal,
        0 Vlfrete,
        0 Vljurosparcelamento,
        0 Vlmexiva,
        0 Vlcofins,
        0 Vlpis,
        0 Vloutrasdesp,
        0 vlacrescrodape,
        nf.xmlnf xmlnfce,
        0 totpeso,
        nf.protocoloenvio protocolonfce,
        a.nrocheckout numcheckout,
        null minutofat,
        a.nrocheckout numcaixa,
        null horacontingencia,
        null fretedespacho,
        null fichasimportadas,
        nf.chavenf chavenfce,
    c.status,
    a.NROEMPRESA,
    a.nrocheckout,
    nf.CHAVESAT,
    nf.NUMSERIESAT,
    NULL NUMSESSAOSAT,
    nf.SITUACAOSAT,
    nf.CODSEFAZSAT,
    nf.CODSTATUSSAT,
    nf.XMLSAT,
    nf.QRCODESAT
  FROM  monitorpdvmiddle.tb_docto a,
        monitorpdvmiddle.tb_doctocupom  c,
        /*monitorpdvmiddle.tb_doctonfe    e,
        monitorpdvmiddle.tb_doctonfexml x*/
    VW_INT_C5_NFESAT nf,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  c.nroempresa = a.nroempresa
   AND  c.nrocheckout = a.nrocheckout
   AND  c.seqdocto = a.seqdocto
   AND  C5.CODFILIALINTEGRACAO = a.NROEMPRESA
   AND  C5.CODFILIALINTEGRACAO = c.NROEMPRESA
   AND  C5.CODFILIALINTEGRACAO = nf.NROEMPRESA
   AND  a.especie IN ('NF', 'CF')
   AND  c.nroempresa = nf.nroempresa
   AND  c.nrocheckout = nf.nrocheckout
   AND  c.seqdocto = nf.seqdocto
   AND  a.seqdocto = nf.Seqdocto
   AND  a.NROEMPRESA = nf.NROEMPRESA
   AND  a.nrocheckout = nf.NROCHECKOUT
   AND  c.status IN ('V', 'C')
   AND  a.replicacao = 'P'
   AND  c.cgo = 65
   /*AND  e.protocoloenvio IS NOT NULL*/
   AND  NVL(fnc_int_c5_vltotal(a.seqdocto, a.nrocheckout, a.nroempresa), 0) > 0
   AND  fnc_int_c5_finalizadora_cab(a.seqdocto,a.nrocheckout,a.nroempresa) > 0
)


\

CREATE OR REPLACE VIEW vw_int_c5_pcpediecf 
AS
(SELECT  i.SEQDOCTO,
        'N' exportado,
        0 numpedecf,
        i.nrocheckout numcheckout,
        0 vlitemtributos,
        0 aliqfcp,
        a.aliqicms1,
        a.aliqicms2,
        0 aliqicmsfecp,
        0 aliqinternadest,
        0 aliqinterorigpart,
        0 aliqreducaocofins,
        0 aliqreducaopis,
        p.codanp anp,
        0 basebcr,
        NVL((select 
        (CASE 
         WHEN doctribitem.percbasecalculo <= 0.0001 THEN
           nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (0.0001 /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)        
         WHEN doctribitem.percbasecalculo <= 100  AND doctribitem.percbasecalculo >= 0.0001 THEN           
             nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (doctribitem.percbasecalculo /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)                       
         ELSE nvl( (i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0)) / NVL(i.QTDEMBALAGEM, 1),0)         
        END) vlrbase              
                            
             from monitorpdvmiddle.tb_doctotributacaoitem doctribitem
             where doctribitem.nroempresa = i.nroempresa
             and doctribitem.nrocheckout = i.nrocheckout
             and doctribitem.seqdocto = i.seqdocto
             and doctribitem.seqitem = i.seqitem
             and doctribitem.seqtipotributacao = 1
             ), 0) baseicms,
        0 baseicmsbcr,
        0 baseicst,
        0 baseipiecf,
        0 basemexiva,
        0 bciss,
        NULL brinde,
        f.cnpjfabricante,
        NULL codagregacao,
        (case WHEN i.seqprodcomposto IS NOT null
          THEN FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto, i.nroempresa)
          ELSE i.codacesso 
          END) codauxiliar,
        NULL codbarrabalanca,
        NVL (FNC_INT_C5_EXBENEF(p.SEQFAMILIA, a.uforigem) ,a.codbeneficiofiscal) codbeneficiofiscal,
        0 codcampanha,
        (SELECT  s.codcest
          FROM  pccest s,
                 pccestproduto sp
          WHERE  s.codigo = sp.codseqcest
            AND  sp.codprod = v.codprod
        AND ROWNUM = 1) as codcest,
        NVL(c.seqpessoa,1) codcli,
        0 codcontrolevasilhame,
        C5.CODFILIAL codfilial,
        NULL codfilialretira,
        (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) codecf,
        i.cfop codfiscal,
        v.codfornec,
        d.sequsuario codfunccx,
        a.codicmtab,
        NULL codigobrinde,
        a.codmotivodesoneracao codmotivoicmsdesonerado,
        v.codprod,
        h.codtribpiscofins,
        NVL(I.NROVENDEDOR, NVL(FNC_INT_C5_CODUSUR(D.SEQUSUARIO), 1)) CODUSUR,
        0 codvasilhameecf,
        0 custofinest,
        (SELECT vlcustoultent
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = i.codacesso) custoultent,
        TO_CHAR(d.dtamovimento,'YYYY-MM-DD') data,
        NULL dtexportacao,
        REGEXP_REPLACE(p.descanp, '[^[:alnum:] ]', '') descanp,
        REGEXP_REPLACE(p.desccompleta, '[^[:alnum:] ]', '') descricaopaf,
        'N' emoferta,
        'N' enviaraliqreducaopiscofins,
        h.excluiricmsbasepiscofins,
        f.fabricante,
        NULL idcancel,
        NULL importado,
        f.indescalarelevante indescalarelevante,
        0 iva,
        NULL logerro,
        NULL md5paf,
        i.nrocheckout numcaixa,
        c.seriedocto numcaixafiscal,
        i.seqitem numseq,
        0 numseqorig,
        NULL numcar,
        NULL numlista,
        0 numccf,
        0 numcoo,
        --NULL Numlote,
        'NOTAFISCAL' numserieequip,
        NULL numped,
        NULL numserie,
        NULL numseriesat,
        NULL origemitem,
        NVL(f.origmerctrib, 0) origmerctrib,
        0 pauta,
        NVL((select pedidoi.pbaserca 
        from pcpedi pedidoi, pcembalagem emb
       where pedidoi.numped = i.NROPREVENDA
         and emb.codprod = pedidoi.codprod
         and emb.codprod = v.codprod
         and emb.codfilial = v.codfilial
         and emb.codauxiliar = pedidoi.codauxiliar
         and emb.qtunit = i.QTDEMBALAGEM
         and pedidoi.codprod = v.codprod
         and pedidoi.qt = i.quantidade
         and rownum = 1  ) ,0) pbaserca,
        0 peracrescimocusto,
        NVL(a.percaliqfcpicms, 0) peracrescimofuncep,
        (SELECT percbasered
           FROM pctribut
          WHERE codst = a.codst) percbasered,
        0 percbaseredst,
        0 percdesccofins,
        0 percdescpis,
        0 perdifereimentoicms,
        0 percmexiva,
        0 perciss,
        (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) percicm,
        0 percicmsefet,
        nvl(v.pcomrep1,0) percom,
        0 percredbaseefet,
        0 perctributosestadual,
        0 perctributosmunicipal,
        /*(CASE
             WHEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) < 0
                  THEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) * -1
             ELSE
               ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6)
          END) perdesc,*/  
    ((((i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) - ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) + (NVL(i.vlracrescimo,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1))) / (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)))*100)perdesc,
        0 perdesccusto,
        0 perdescisentoicms,
        'N' piscofinsdeduzido,
        h.perccofins,
        NVL(p.percglp,0) pglp,
        NVL(p.percgni,0) pgni,
        NVL(p.percgnn,0) pgnn,
        (CASE WHEN i.seqprodcomposto is not null THEN
            (SELECT SUM((X.VLRUNITARIO* F.QUANTIDADE) / NVL(X.QTDEMBALAGEM, 1)) 
                FROM MONITORPDVMIDDLE.TB_DOCTOITEM X, MONITORPDVMIDDLE.TB_PRODCOMPOSTO F
                  WHERE X.SEQDOCTO = i.seqdocto
                AND X.nroempresa = i.nroempresa
              AND X.nrocheckout = i.nrocheckout
              AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
              AND F.SEQPRODUTO = X.SEQPRODUTO
              AND F.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
        AND F.ATIVO = 'S'
              AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)
            ELSE
            (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1))
        END ) poriginal,
        NULL possuicomplemento,
        NULL posicaoretorno,
        0 pvendavasilhame,
        'L' posicao,
        (CASE WHEN i.seqprodcomposto is not null THEN
        (SELECT SUM((X.VLRUNITARIO*F.QUANTIDADE) / NVL(X.QTDEMBALAGEM, 1)) 
            FROM MONITORPDVMIDDLE.TB_DOCTOITEM X, MONITORPDVMIDDLE.TB_PRODCOMPOSTO F
              WHERE X.SEQDOCTO = i.seqdocto
            AND X.nroempresa = i.nroempresa
          AND X.nrocheckout = i.nrocheckout
          AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
          AND F.SEQPRODUTO = X.SEQPRODUTO
          AND F.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
      AND F.ATIVO = 'S'
          AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)
        ELSE
         CASE WHEN i.PROMOCAO = 'S' THEN
        ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1))
     ELSE 
        (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) 
     END
        END )ptabela,
        (CASE WHEN i.seqprodcomposto is not null THEN
          (SELECT SUM(((X.vlrunitario*F.QUANTIDADE) - (NVL(X.vlrdesconto*F.QUANTIDADE,0)/NVL(X.quantidade,1)) + (NVL(X.vlracrescimo*F.QUANTIDADE,0)/NVL(X.quantidade,1)) )/NVL(X.QTDEMBALAGEM, 1)) 
              FROM MONITORPDVMIDDLE.TB_DOCTOITEM X, MONITORPDVMIDDLE.TB_PRODCOMPOSTO F
                WHERE X.SEQDOCTO = i.seqdocto
              AND X.nroempresa = i.nroempresa
            AND X.nrocheckout = i.nrocheckout
            AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
            AND F.SEQPRODUTO = X.SEQPRODUTO
            AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO
      AND F.ATIVO = 'S'
            AND F.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO)
          ELSE
          ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) + (NVL(i.vlracrescimo,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1)) 
        END ) pvenda,
       /*(CASE
            WHEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) < 0
                 THEN (i.vlrunitario + (NVL(i.vlracrescimo,0)/ i.quantidade))
            ELSE
              (i.vlrunitario - (NVL(i.vlrdesconto,0)/ i.quantidade))
         END) pvenda,*/
        (CASE  WHEN i.seqprodcomposto IS NOT null
          THEN (i.quantidade * NVL(i.QTDEMBALAGEM,1)) /
                  NVL((SELECT C.QUANTIDADE 
                    FROM MONITORPDVMIDDLE.TB_PRODCOMPOSTO C
                  WHERE C.seqprodcomposto = i.seqprodcomposto
            AND C.ATIVO = 'S'
                    AND c.SEQPRODUTO = i.SEQPRODUTO),1)
          ELSE (i.quantidade * NVL(i.QTDEMBALAGEM,1))
        END) qt,
        NULL qtfalta,
        NULL qtminatacvenda,
        0 qtsaidavasilhame,
        0 qtlitragem,
        i.QTDEMBALAGEM qtunitemb,
        2099 rotinalanc,
        (CASE
            WHEN LENGTH(a.sittribut) < 2
                THEN '0'||a.sittribut
            ELSE
                TO_CHAR(a.sittribut)
          END) sittribut,
        0 st,
        0 stbcr,
        v.tipomerc tipomerc,
        'N' truncaritem,
        NULL tipoentrega,
        NULL totalizador,
        0 txvenda,
        NULL tipodescatacvenda,
        'N' usapiscofinslit,
        NULL usaunidademaster,
        'N' utilizoumotorcalculo,
        NULL vendapbm,
        NULL versaoservicopartilha,
        (SELECT valorultent
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = i.codacesso) valorultent,
        NVL(round(((i.vlrunitario / i.qtdembalagem) * a.percaliqfcpicms / 100),6), 0) vlacrescimofuncep,
        (CASE
            WHEN i.seqdocto IN (SELECT seqdocto
                                  FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                                 WHERE z.NROEMPRESA = i.NROEMPRESA
                                   AND z.NROCHECKOUT = i.NROCHECKOUT
                                   AND z.SEQTIPOACRESCDESCTO = 7)
                THEN (SELECT z.VALOR
                        FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                       WHERE z.NROEMPRESA = i.NROEMPRESA
                         AND z.NROCHECKOUT = i.NROCHECKOUT
                         AND z.SEQTIPOACRESCDESCTO = 7
                         AND z.seqdocto = i.seqdocto)/fnc_int_c5_numitens(d.seqdocto, d.nrocheckout, d.nroempresa)
           ELSE
              0
         END) vlacrescrodape,
        NVL(
        (SELECT vlbaseefet
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = i.codacesso),0) vlbaseefet,
        (CASE
            WHEN a.SITTRIBUT IN ('00','20','90')
                 AND
                 a.PERCALIQFCPICMS > 0
                then TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 11, 'VLRBASE'),'0'))               
            ELSE
              0
          END) vlbasefcpicms,
        0 vlbasefcpst,
        0 vlbasepiscofins,
        0 vlbcfcpstret,
        ((NVL(h.perccofins,0)/100) * i.vlrtotal) vlcofins,
        0 vlcredcofins,
        0 vlcredpis,
        (SELECT vlcustocont
           FROM vw_int_c5_custos
          WHERE codfilial = C5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustocont,
        (SELECT vlcustofin
           FROM vw_int_c5_custos
          WHERE codfilial = C5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustofin,
        (SELECT vlcustoreal
           FROM vw_int_c5_custos
          WHERE codfilial = C5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustoreal,
        (SELECT vlcustorep
           FROM vw_int_c5_custos
          WHERE codfilial = C5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustorep,
        0 vldescfin,
        0 vldescicmisencao,
        fnc_int_c5_vldescitem(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM) vldescitem,
        0 vldescreducaocofins,
        0 vldescreducaopis,
        0 vldescrodape,
        0 vldescsociotorcedor,
        0 vlfrete,
       (fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 15, 'VLRTRIBUTO')) vlicmsdesoneracao,
        0 vlicmsdifaliqpart,
        i.vlrunitario vlitem,
        0 vlitemtributosestadual,
        0 vlitemtributosmunicipal,
        0 vliss,
        0 vlicmspartrem,
        0 vlipi,
        0 vlipiecf,
        0 vloutrasdesp,
        NULL vlmexiva,
        ((NVL(h.percpis,0)/100) * i.vlrtotal) vlpis,
        (CASE WHEN i.seqprodcomposto is not null THEN
          (SELECT SUM(X.vlrtotal) 
              FROM MONITORPDVMIDDLE.TB_DOCTOITEM X
                WHERE X.SEQDOCTO = i.seqdocto
              AND X.nroempresa = i.nroempresa
            AND X.nrocheckout = i.nrocheckout
            AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO)
          ELSE
          (i.vlrtotal)
        END )  vlsubtotitem,
        0 vlricmssimplesnac,
        0 vpart,
        0 perctributos,
        a.codst,
        (select est.vlicmsbcr from pcest est where est.codfilial = v.codfilial and est.codprod = v.codprod) vlicmsbcr,
        h.percpis,
        0 aliqicms1ret,
        0 PERCIPI,
        0 PERFRETECMV,
        0 VLBASEIPI,
        0 PERPIS,
        0 PERCOFINS,
        0 BASEDIFALIQUOTAS,
        0 PERCDIFALIQUOTAS,
        0 VLDIFALIQUOTAS,
        0 VLDESCORGAOPUB,
        0 PERCIPIECF,
        0 QTVENDIDAVASILHAME,
        0 VLACRESCVASILHAME,
        0 PERCICMSSIMPLESNAC,
        0 VLBASEPARTDEST,
        0 VLFCPPART,
        0 VLICMSPARTDEST,
        0 PERCPROVPART,
        0 VLICMSPART,
        0 PERCBASEDPART,
        0 PERFCPSTRET,
        0 VLFCPPARTRET,
        0 PERCCPSN,
        0 VLCREDFCPICMSSN,
        0 VLFECP,
        0 VLICMSEFET,
        0 VLDESCSUFRAMA,
    d.NROEMPRESA,
    d.nrocheckout,
    (CASE
      WHEN I.SEQLOTEESTOQUE > 0 THEN
           (SELECT LT.NROLOTEESTOQUE 
            FROM MONITORPDVMIDDLE.TB_LOTEESTOQUE LT
            WHERE LT.SEQPRODUTO = I.SEQPRODUTO
            AND   LT.NROEMPRESA = I.NROEMPRESA
            AND   LT.SEQLOTEESTOQUE = I.SEQLOTEESTOQUE
           )
      ELSE NULL
    END) NUMLOTE,
    (CASE
      WHEN I.SEQLOTEESTOQUE > 0 THEN
           (SELECT LT.DTAVALIDADE 
            FROM MONITORPDVMIDDLE.TB_LOTEESTOQUE LT
            WHERE LT.SEQPRODUTO = I.SEQPRODUTO
            AND   LT.NROEMPRESA = I.NROEMPRESA
            AND   LT.SEQLOTEESTOQUE = I.SEQLOTEESTOQUE
           )
      ELSE NULL
    END) DTVALIDADE
  
  /*Campos Reforma*/
  /*NULL Xml_qttrib,
  NULL Unidadetrib,
  
  --IS
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaois,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CST') CSTIS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CCLASSTRIB') Cclasstribis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRBASE'),'0')) Vlbaseis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERCALIQUOTA'),'0')) Aliqis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRIMPOSTO'),'0')) Vlis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERALIQEFETIVA'),'0'))  Aliqespecificais,
    
  -- CBS 
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTCBS,
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') Cclasstribcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) Vlbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCALIQUOTA'),'0')) Aliqcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) Percredbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) PREDALIQCBS,  
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRIMPOSTO'),'0')) Vlcbs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERALIQEFETIVA'),'0')) Aliqespecificacbs,
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaocbs,
  
    -- IBS
    (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaoibs,
     fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CST')  Cstibs,     
   fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CCLASSTRIB') Cclasstribibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRBASE'),'0')) vlbaseibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) aliqibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA'),'0')) percredbaseibs, 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRIMPOSTO'),'0')) Vlibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA'),'0'))  Aliqespecificaibs  , 
    
  -- CBSIBS 
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) CODIGOTRIBUTACAOCBSIBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTIBSCBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') CCLASSTRIBIBSCBS,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) VLBASEIBSCBS,

    -- IBSUF 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0'))  IBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERDIFERIMENTO') ,'0')) PDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRDIFERIDO') ,'0')) VDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRTRIBUTO') ,'0')) VIBSUF,
  
  --IBSMUN
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCALIQUOTA'),'0')) PIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERDIFERIMENTO'),'0')) PDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRDIFERIDO') ,'0')) VDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRTRIBUTO') ,'0'))  VIBSMUN
*/  

FROM  monitorpdvmiddle.tb_doctoitem     i,
        monitorpdvmiddle.tb_docto       d,
        monitorpdvmiddle.tb_doctocupom  c,
        monitorpdvmiddle.tb_produto     p,
        vw_int_c5_trib_pis              h,
        pcprodut                        v, --vw_int_c5_pcprodut              v,
        pcconsolidatributacao           a,
        monitorpdvmiddle.tb_empresa     e,
        pcfilial ea,
        PCDEPARAREGIAOC5 div,
        pcprodfilial f,
    VW_INT_C5_OBTER_FILIAIS_C5  C5
 WHERE  i.seqdocto = d.seqdocto
   AND  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
  -- AND  v.seqproduto = CASE WHEN i.seqprodcomposto is null THEN i.seqproduto ELSE i.seqprodcomposto END 
   and  p.codproduto = v.codprod
   and  p.seqproduto = CASE WHEN i.seqprodcomposto is null THEN i.seqproduto ELSE i.seqprodcomposto END
   --AND  v.codfilial = ea.codigo
   AND  d.seqdocto = c.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
  -- AND  C5.CODFILIAL = v.codfilial
   AND  i.nrotributacao = a.codst
   AND  i.nrotributacao = h.codst(+)
   AND  case when i.seqprodcomposto is null then i.seqproduto else NULL END  = h.seqproduto(+)
   AND  case when i.seqprodcomposto is null then i.codacesso else NULL END  = h.codauxiliar(+)
   --AND  case when i.seqprodcomposto is null then v.codauxiliar else 1 end = case when i.seqprodcomposto is null then i.codacesso else 1 END
   and  i.nroempresa = h.nroempresa(+)
   AND  e.nroempresa = d.nroempresa
   AND  i.nroempresa = e.nroempresa
   AND  C5.CODFILIALINTEGRACAO = d.NROEMPRESA
   AND  C5.CODFILIALINTEGRACAO = c.NROEMPRESA
   AND  C5.codfilialintegracao = e.nroempresa
   AND  C5.codfilialintegracao = i.nroempresa
   AND  C5.codfilial = ea.codigo
   AND  ea.uf = a.ufdestino
   AND  div.nrodivisao = e.nrodivisao
   AND  a.numregiao = div.numregiao
   AND  c.status in ('V', 'C')
   AND  i.status = 'V'
   AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
   AND (
      i.SEQPRODCOMPOSTO IS NOT NULL 
      AND i.seqitem = (
                        SELECT min(x.seqitem) 
                        FROM monitorpdvmiddle.tb_doctoitem X 
                        WHERE x.seqdocto = i.seqdocto 
                            AND x.nroempresa = i.nroempresa
                            AND x.nrocheckout = i.nrocheckout
                            AND x.seqprodcomposto = i.seqprodcomposto
              AND x.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO
                      )
      OR 
        i.SEQPRODCOMPOSTO IS NULL 
    )
    AND v.codprod = f.codprod
    AND ea.codigo = f.codfilial
    AND c5.codfilial = f.codfilial
    AND p.codproduto = v.codprod
   UNION ALL 
   SELECT  i.SEQDOCTO,
        'N' exportado,
        0 numpedecf,
        i.nrocheckout numcheckout,
        0 vlitemtributos,
        0 aliqfcp, 
        a.aliqicms1,
        a.aliqicms2,
        0 aliqicmsfecp,
        0 aliqinternadest,
        0 aliqinterorigpart,
        0 aliqreducaocofins,
        0 aliqreducaopis,
        p.codanp anp,
        0 basebcr,
        NVL((select 
        (CASE 
         WHEN doctribitem.percbasecalculo <= 0.0001 THEN
           nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (0.0001 /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)        
         WHEN doctribitem.percbasecalculo <= 100  AND doctribitem.percbasecalculo >= 0.0001 THEN           
             nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (doctribitem.percbasecalculo /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)                       
         ELSE nvl( (i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0)) / NVL(i.QTDEMBALAGEM, 1),0)         
        END) vlrbase               
                            
             from monitorpdvmiddle.tb_doctotributacaoitem doctribitem
             where doctribitem.nroempresa = i.nroempresa
             and doctribitem.nrocheckout = i.nrocheckout
             and doctribitem.seqdocto = i.seqdocto
             and doctribitem.seqitem = i.seqitem
             and doctribitem.seqtipotributacao = 1
             ), 0) baseicms,
        0 baseicmsbcr,
        0 baseicst,
        0 baseipiecf,
        0 basemexiva,
        0 bciss,
        NULL brinde,
        f.cnpjfabricante,
        NULL codagregacao,
        (case WHEN i.seqprodcomposto IS NOT null
          THEN FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa)
          ELSE i.codacesso
        END) CODAUXILIAR,
        NULL codbarrabalanca,
        NVL (FNC_INT_C5_EXBENEF(p.SEQFAMILIA, a.uforigem) ,a.codbeneficiofiscal) codbeneficiofiscal,
        0 codcampanha,
        (SELECT  s.codcest
           FROM  pccest s,
                 pccestproduto sp
          WHERE  s.codigo = sp.codseqcest
            AND  sp.codprod = v.codprod
        AND ROWNUM = 1) as codcest,
        NVL(c.seqpessoa,1) codcli,
        0 codcontrolevasilhame,
        C5.CODFILIAL codfilial,
        NULL codfilialretira,
        (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) codecf,
        i.cfop codfiscal,
        v.codfornec,
        d.sequsuario codfunccx,
        a.codicmtab,
        NULL codigobrinde,
        a.codmotivodesoneracao codmotivoicmsdesonerado,
        v.codprod,
        h.codtribpiscofins,
        NVL(I.NROVENDEDOR, NVL(FNC_INT_C5_CODUSUR(D.SEQUSUARIO), 1)) CODUSUR,
        0 codvasilhameecf,
        0 custofinest,
        (SELECT vlcustoultent
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = i.codacesso) custoultent,
        TO_CHAR(d.dtamovimento,'YYYY-MM-DD') data,
        NULL dtexportacao,
        REGEXP_REPLACE(p.descanp, '[^[:alnum:] ]', '') descanp,
        REGEXP_REPLACE(p.desccompleta, '[^[:alnum:] ]', '') descricaopaf,
        'N' emoferta,
        'N' enviaraliqreducaopiscofins,
        h.excluiricmsbasepiscofins,
        f.fabricante,
        NULL idcancel,
        NULL importado,
        f.indescalarelevante indescalarelevante,
        0 iva,
        NULL logerro,
        NULL md5paf,
        i.nrocheckout numcaixa,
        c.seriedocto numcaixafiscal,
        i.seqitem numseq,
        0 numseqorig,
        NULL numcar,
        NULL numlista,
        0 numccf,
        0 numcoo,
        --NULL Numlote,
        'NOTAFISCAL' numserieequip,
        NULL numped,
        NULL numserie,
        NULL numseriesat,
        NULL origemitem,
        NVL(f.origmerctrib, 0) origmerctrib,
        0 pauta,
        NVL((select pedidoi.pbaserca 
        from pcpedi pedidoi, pcembalagem emb
       where pedidoi.numped = i.NROPREVENDA
         and emb.codprod = pedidoi.codprod
         and emb.codprod = v.codprod
         and emb.codfilial = v.codfilial
         and emb.codauxiliar = pedidoi.codauxiliar
         and emb.qtunit = i.QTDEMBALAGEM
         and pedidoi.codprod = v.codprod
         and pedidoi.qt = i.quantidade
         and rownum = 1) ,0) pbaserca,
        0 peracrescimocusto,
        NVL(a.percaliqfcpicms, 0) peracrescimofuncep,
        (SELECT percbasered
           FROM pctribut
          WHERE codst = a.codst) percbasered,
        0 percbaseredst,
        0 percdesccofins,
        0 percdescpis,
        0 perdifereimentoicms,
        0 percmexiva,
        0 perciss,
        (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) percicm,
        0 percicmsefet,
        NVL(v.pcomrep1,0) percom,
        0 percredbaseefet,
        0 perctributosestadual,
        0 perctributosmunicipal,
        /*(CASE
             WHEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) < 0
                  THEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) * -1
             ELSE
               ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6)
          END) perdesc,*/  
    ((((i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) - ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) + (NVL(i.vlracrescimo,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1))) / (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)))*100)perdesc,
        0 perdesccusto,
        0 perdescisentoicms,
        'N' piscofinsdeduzido,
        h.perccofins,
        NVL(p.percglp,0) pglp,
        NVL(p.percgni,0) pgni,
        NVL(p.percgnn,0) pgnn,
        (CASE WHEN i.seqprodcomposto is not null THEN
        (SELECT SUM((X.VLRUNITARIO*F.QUANTIDADE) / NVL(X.QTDEMBALAGEM, 1)) 
            FROM MONITORPDVMIDDLE.TB_DOCTOITEM X, MONITORPDVMIDDLE.TB_PRODCOMPOSTO F
              WHERE X.SEQDOCTO = i.seqdocto
            AND X.nroempresa = i.nroempresa
          AND X.nrocheckout = i.nrocheckout
          AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
          AND F.SEQPRODUTO = X.SEQPRODUTO
          AND F.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
      AND F.ATIVO = 'S'
          AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)
        ELSE
        (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1))
        END ) poriginal,
        NULL possuicomplemento,
        NULL posicaoretorno,
        0 pvendavasilhame,
        'L' posicao,
        (CASE WHEN i.seqprodcomposto is not null THEN
        (SELECT SUM((X.VLRUNITARIO*F.QUANTIDADE) / NVL(X.QTDEMBALAGEM, 1)) 
            FROM MONITORPDVMIDDLE.TB_DOCTOITEM X, MONITORPDVMIDDLE.TB_PRODCOMPOSTO F
              WHERE X.SEQDOCTO = i.seqdocto
            AND X.nroempresa = i.nroempresa
          AND X.nrocheckout = i.nrocheckout
          AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
          AND F.SEQPRODUTO = X.SEQPRODUTO
          AND F.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
      AND F.ATIVO = 'S'
          AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)
        ELSE
         CASE WHEN i.PROMOCAO = 'S' THEN
        ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1))
     ELSE 
        (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) 
     END
        END )ptabela,
        (CASE WHEN i.seqprodcomposto is not null THEN
        (SELECT SUM(((X.vlrunitario*F.QUANTIDADE) - (NVL(X.vlrdesconto*F.QUANTIDADE,0)/NVL(X.quantidade,1)) + (NVL(X.vlracrescimo*F.QUANTIDADE,0)/NVL(X.quantidade,1)) )/NVL(X.QTDEMBALAGEM, 1)) 
            FROM MONITORPDVMIDDLE.TB_DOCTOITEM X, MONITORPDVMIDDLE.TB_PRODCOMPOSTO F
              WHERE X.SEQDOCTO = i.seqdocto
            AND X.nroempresa = i.nroempresa
          AND X.nrocheckout = i.nrocheckout
          AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
          AND F.SEQPRODUTO = X.SEQPRODUTO
          AND F.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO
      AND F.ATIVO = 'S'
          AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)
        ELSE
        ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) + (NVL(i.vlracrescimo,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1))
        END ) pvenda,
        (CASE  WHEN i.seqprodcomposto IS NOT null
        THEN (i.quantidade * NVL(i.QTDEMBALAGEM,1)) /
                NVL((SELECT C.QUANTIDADE 
                  FROM MONITORPDVMIDDLE.TB_PRODCOMPOSTO C
                WHERE C.seqprodcomposto = i.seqprodcomposto
                  AND C.ATIVO = 'S'        
                  AND c.SEQPRODUTO = i.SEQPRODUTO),1)
        ELSE (i.quantidade * NVL(i.QTDEMBALAGEM,1))
        END) qt,
        NULL qtfalta,
        NULL qtminatacvenda,
        0 qtsaidavasilhame,
        0 qtlitragem,
        i.QTDEMBALAGEM qtunitemb,
        2099 rotinalanc,
        (CASE
            WHEN LENGTH(a.sittribut) < 2
                THEN '0'||a.sittribut
            ELSE
                TO_CHAR(a.sittribut)
          END) sittribut,
        0 st,
        0 stbcr,
        v.tipomerc tipomerc,
        'N' truncaritem,
        NULL tipoentrega,
        NULL totalizador,
        0 txvenda,
        NULL tipodescatacvenda,
        'N' usapiscofinslit,
        NULL usaunidademaster,
        'N' utilizoumotorcalculo,
        NULL vendapbm,
        NULL versaoservicopartilha,
        (SELECT valorultent
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) valorultent,
        NVL(round(((i.vlrunitario / i.qtdembalagem) * a.percaliqfcpicms / 100),6), 0) vlacrescimofuncep,
        (CASE
            WHEN i.seqdocto IN (SELECT seqdocto
                                  FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                                 WHERE z.NROEMPRESA = i.NROEMPRESA
                                   AND z.NROCHECKOUT = i.NROCHECKOUT
                                   AND z.SEQTIPOACRESCDESCTO = 7)
                THEN (SELECT z.VALOR
                        FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                       WHERE z.NROEMPRESA = i.NROEMPRESA
                         AND z.NROCHECKOUT = i.NROCHECKOUT
                         AND z.SEQTIPOACRESCDESCTO = 7
                         AND z.seqdocto = i.seqdocto)/fnc_int_c5_numitens(d.seqdocto, d.nrocheckout, d.nroempresa)
           ELSE
              0
         END) vlacrescrodape,
        NVL(
        (SELECT vlbaseefet
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = i.codacesso),0) vlbaseefet,
        (CASE
            WHEN a.SITTRIBUT IN ('00','20','90')
                 AND
                 a.PERCALIQFCPICMS > 0
                then TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 11, 'VLRBASE'),'0'))                 
            ELSE
              0
          END) vlbasefcpicms,
        0 vlbasefcpst,
        0 vlbasepiscofins,
        0 vlbcfcpstret,
        ((NVL(h.perccofins,0)/100) * i.vlrtotal) vlcofins,
        0 vlcredcofins,
        0 vlcredpis,
        (SELECT vlcustocont
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustocont,
        (SELECT vlcustofin
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustofin,
        (SELECT vlcustoreal
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustoreal,
        (SELECT vlcustorep
           FROM vw_int_c5_custos
          WHERE codfilial = c5.codfilial
            AND codauxiliar = case when i.seqprodcomposto is null then i.codacesso else FNC_INT_C5_CODAUXPRODCOMPOSTO(i.seqprodcomposto , i.nroempresa) end) vlcustorep,
        0 vldescfin,
        0 vldescicmisencao,
        fnc_int_c5_vldescitem(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM) vldescitem,
        0 vldescreducaocofins,
        0 vldescreducaopis,
        0 vldescrodape,
        0 vldescsociotorcedor,
        0 vlfrete,
       (fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 15, 'VLRTRIBUTO')) vlicmsdesoneracao,
        0 vlicmsdifaliqpart,
        i.vlrunitario vlitem,
        0 vlitemtributosestadual,
        0 vlitemtributosmunicipal,
        0 vliss,
        0 vlicmspartrem,
        0 vlipi,
        0 vlipiecf,
        0 vloutrasdesp,
        NULL vlmexiva,
        ((NVL(h.percpis,0)/100) * i.vlrtotal) vlpis,
        (CASE WHEN i.seqprodcomposto is not null THEN
        (SELECT SUM(X.vlrtotal) 
            FROM MONITORPDVMIDDLE.TB_DOCTOITEM X
              WHERE X.SEQDOCTO = i.seqdocto
            AND X.nroempresa = i.nroempresa
          AND X.nrocheckout = i.nrocheckout
          AND X.SEQPRODCOMPOSTO = i.SEQPRODCOMPOSTO)
        ELSE
        (i.vlrtotal)
        END )  vlsubtotitem,
        0 vlricmssimplesnac,
        0 vpart,
        0 perctributos,
        a.codst,
        (select est.vlicmsbcr from pcest est where est.codfilial = v.codfilial and est.codprod = v.codprod) vlicmsbcr,
        h.percpis,
        0 aliqicms1ret,
        0 PERCIPI,
        0 PERFRETECMV,
        0 VLBASEIPI,
        0 PERPIS,
        0 PERCOFINS,
        0 BASEDIFALIQUOTAS,
        0 PERCDIFALIQUOTAS,
        0 VLDIFALIQUOTAS,
        0 VLDESCORGAOPUB,
        0 PERCIPIECF,
        0 QTVENDIDAVASILHAME,
        0 VLACRESCVASILHAME,
        0 PERCICMSSIMPLESNAC,
        0 VLBASEPARTDEST,
        0 VLFCPPART,
        0 VLICMSPARTDEST,
        0 PERCPROVPART,
        0 VLICMSPART,
        0 PERCBASEDPART,
        0 PERFCPSTRET,
        0 VLFCPPARTRET,
        0 PERCCPSN,
        0 VLCREDFCPICMSSN,
        0 VLFECP,
        0 VLICMSEFET,
        0 VLDESCSUFRAMA,
    d.NROEMPRESA,
    d.nrocheckout,
    (CASE
      WHEN I.SEQLOTEESTOQUE > 0 THEN
           (SELECT LT.NROLOTEESTOQUE 
            FROM MONITORPDVMIDDLE.TB_LOTEESTOQUE LT
            WHERE LT.SEQPRODUTO = I.SEQPRODUTO
            AND   LT.NROEMPRESA = I.NROEMPRESA
            AND   LT.SEQLOTEESTOQUE = I.SEQLOTEESTOQUE
           )
      ELSE NULL
    END) NUMLOTE,
    (CASE
      WHEN I.SEQLOTEESTOQUE > 0 THEN
           (SELECT LT.DTAVALIDADE 
            FROM MONITORPDVMIDDLE.TB_LOTEESTOQUE LT
            WHERE LT.SEQPRODUTO = I.SEQPRODUTO
            AND   LT.NROEMPRESA = I.NROEMPRESA
            AND   LT.SEQLOTEESTOQUE = I.SEQLOTEESTOQUE
           )
      ELSE NULL
    END) DTVALIDADE
  
  /*Campos Reforma*/
  /*NULL Xml_qttrib,
  NULL Unidadetrib,
  
  -- IS
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaois,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CST') CSTIS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CCLASSTRIB') Cclasstribis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRBASE'),'0')) Vlbaseis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERCALIQUOTA'),'0')) Aliqis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRIMPOSTO'),'0')) Vlis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERALIQEFETIVA'),'0'))  Aliqespecificais,
    
  -- CBS
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTCBS,
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') Cclasstribcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) Vlbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCALIQUOTA'),'0')) Aliqcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) Percredbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) PREDALIQCBS,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRIMPOSTO'),'0')) Vlcbs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERALIQEFETIVA'),'0')) Aliqespecificacbs,
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaocbs,
  
    -- IBS
    (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaoibs,
     fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CST')  Cstibs,     
   fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CCLASSTRIB') Cclasstribibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRBASE'),'0')) vlbaseibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) aliqibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA'),'0')) percredbaseibs, 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRIMPOSTO'),'0')) Vlibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA'),'0'))  Aliqespecificaibs  , 
    
  -- CBSIBS
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) CODIGOTRIBUTACAOCBSIBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTIBSCBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') CCLASSTRIBIBSCBS,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) VLBASEIBSCBS,

    -- IBSUF 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) IBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERDIFERIMENTO') ,'0')) PDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRDIFERIDO') ,'0')) VDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRTRIBUTO') ,'0')) VIBSUF,
  
  --IBSMUN
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCALIQUOTA'),'0')) PIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERDIFERIMENTO'),'0')) PDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRDIFERIDO') ,'0')) VDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRTRIBUTO') ,'0'))  VIBSMUN
*/  

FROM  monitorpdvmiddle.tb_doctoitem      i,
        monitorpdvmiddle.tb_docto        d,
        monitorpdvmiddle.tb_doctocupom   c,
        monitorpdvmiddle.tb_produto      p,
        vw_int_c5_trib_pis               h,
        pcprodut                         v, --vw_int_c5_pcprodut       v,
        pcconsolidatributacao            a,
        monitorpdvmiddle.tb_empresa      e,
        pcfilial                         ea,
        pcprodfilial                     f,
    VW_INT_C5_OBTER_FILIAIS_C5  C5
 WHERE  i.seqdocto = d.seqdocto
   AND  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   --AND  v.codfilial = ea.codigo
   --AND  v.seqproduto = CASE WHEN i.seqprodcomposto is null THEN i.seqproduto ELSE i.seqprodcomposto END 
   AND  p.seqproduto = CASE WHEN i.seqprodcomposto is null THEN i.seqproduto ELSE i.seqprodcomposto END
   AND  d.seqdocto = c.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  C5.CODFILIALINTEGRACAO = i.nroempresa
   AND  C5.CODFILIALINTEGRACAO = d.NROEMPRESA
   AND  C5.CODFILIALINTEGRACAO = c.NROEMPRESA
   AND  C5.CODFILIALINTEGRACAO = e.NROEMPRESA
   --AND  C5.CODFILIALINTEGRACAO = v.codfilial
   AND  i.nrotributacao = a.codst
   AND  i.nrotributacao = h.codst(+)
   AND  case when i.seqprodcomposto is null then i.seqproduto else NULL END  = h.seqproduto(+)
   AND  case when i.seqprodcomposto is null then i.codacesso else NULL END  = h.codauxiliar(+)
   --AND  case when i.seqprodcomposto is null then v.codauxiliar else 1 end = case when i.seqprodcomposto is null then i.codacesso else 1 END
   and  i.nroempresa = h.nroempresa(+)
   AND  e.nroempresa = d.nroempresa
   AND  i.nroempresa = e.nroempresa
   AND  c5.codfilial = ea.codigo
   AND  ea.uf = a.ufdestino
   AND  C5.CODFILIALINTEGRACAO = e.nrodivisao
   AND  a.numregiao = C5.CODFILIALINTEGRACAO
   AND  c.status in ('V', 'C')
   AND  i.status = 'V'
   AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S'
   AND (
      i.SEQPRODCOMPOSTO IS NOT NULL 
      AND i.seqitem = (
                        SELECT min(x.seqitem) 
                        FROM monitorpdvmiddle.tb_doctoitem X 
                        WHERE x.seqdocto = i.seqdocto 
                            AND x.nroempresa = i.nroempresa
                            AND x.nrocheckout = i.nrocheckout
                            AND x.seqprodcomposto = i.seqprodcomposto
              AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO
                      )
      OR 
        i.SEQPRODCOMPOSTO IS NULL 
  )
   AND ea.codigo = f.codfilial
   AND v.codprod = f.codprod
   AND c5.codfilial = f.codfilial
   AND p.codproduto = v.codprod
)
   
\

create or replace view VW_INT_C5_PCPEDIECFCESTA AS 
(
  SELECT distinct
    I.SEQDOCTO,
    'S' EXPORTADO,
    0 NUMPEDECF,
    I.NROCHECKOUT NUMCAIXA,    
    I.NROCHECKOUT NUMCHECKOUT,
    C.SERIEDOCTO NUMCAIXAFISCAL,
    'NOTAFISCAL' NUMSERIEEQUIP,
    (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) CODECF,
    C5.CODFILIAL CODFILIAL,
    D.SEQUSUARIO CODFUNCCX,
    NULL NUMPED,
    P_ACAB.CODPROD CODPROD,
    ( SELECT min(x.seqitem) 
      FROM monitorpdvmiddle.tb_doctoitem X 
      WHERE x.seqdocto = i.seqdocto 
        AND x.nroempresa = i.nroempresa
        AND x.nrocheckout = i.nrocheckout
        AND x.seqprodcomposto = i.seqprodcomposto
    AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)  NUMSEQ,
    I.CODACESSO CODAUXILIAR,    
    V.CODPROD CODPRODMP,
    I.QUANTIDADE QTMP,
    (I.VLRUNITARIO / NVL(I.QTDEMBALAGEM, 1)) PTABELA,
    ((I.VLRUNITARIO - (NVL(I.VLRDESCONTO,0)/NVL(I.QUANTIDADE,1)) + (NVL(I.VLRACRESCIMO,0)/NVL(I.QUANTIDADE,1)) )/NVL(I.QTDEMBALAGEM, 1)) PVENDA,
    A.CODST,
    nvl(v.pcomrep1,0) PERCOM,
    A.ALIQICMS1,
    A.ALIQICMS2,
    (CASE WHEN LENGTH(A.SITTRIBUT) < 2 THEN 
          '0'||A.SITTRIBUT
    ELSE
          TO_CHAR(A.SITTRIBUT)
    END) SITTRIBUT,
    I.CFOP CODFISCAL,
  0 PBASERCA,
  0 baseicst,
  0 STCLIENTEGNRE,
  0 PERCIPI,
  0 VLIPI,
  0 PERCISS,
  0 VLISS,
  0 VLDESCSUFRAMA,
  (SELECT vlcustorep
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOREP,
  (SELECT VLCUSTOCONT
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOCONT,
  (SELECT VLCUSTOREAL
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOREAL,
  (SELECT VLCUSTOFIN
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOFIN,    
  0 VLDESCCUSTOCMV,
  0 PERDESCTAB,
  0 IVA,
  0 PAUTA,
  0 PERCBASERED,
  (SELECT vlcustofin
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) CUSTOFINEST,
  0 PERCBASEREDSTFONTE,
  0 PERCBASEREDST,
  a.CODICMTAB,
  0 TXVENDA,
  0 PERFRETECMV,
  0 VLDESCRODAPE,
  0 VLBASEIPI,
  NVL((select 
      (CASE 
       WHEN doctribitem.percbasecalculo <= 0.0001 THEN
         nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (0.0001 /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)        
       WHEN doctribitem.percbasecalculo <= 100  AND doctribitem.percbasecalculo >= 0.0001 THEN           
           nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (doctribitem.percbasecalculo /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)                       
       ELSE nvl( (i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0)) / NVL(i.QTDEMBALAGEM, 1),0)         
      END) vlrbase              
                   
     from monitorpdvmiddle.tb_doctotributacaoitem doctribitem
     where doctribitem.nroempresa = i.nroempresa
     and doctribitem.nrocheckout = i.nrocheckout
     and doctribitem.seqdocto = i.seqdocto
     and doctribitem.seqitem = i.seqitem
     and doctribitem.seqtipotributacao = 1
     ), 0) baseicms,
    (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) percicm,
  0 PERPIS,
  ((NVL(h.percpis,0)/100) * i.vlrtotal) vlpis,
  0 PERCOFINS,
  ((NVL(h.perccofins,0)/100) * i.vlrtotal) vlcofins,
  0 percdescpis,
  0 vldescreducaocofins,
  0 PERCDIFALIQUOTAS,
  0 VLDIFALIQUOTAS,
    (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) PERCICMS,
    h.percpis,
  0 VLITEMTRIBUTOS,
  0 PERCTRIBUTOS,
  0 BASEIDFALIQUOTAS,
  0 BCSS,
  I.vlrtotal VLSUBTOTITEM,
  0 VLITEMTRIBUTOSESTADUAL,
  0 ALIQINTERNADEST,
  0 ALIQFCP,
  0 VLICMSPERTREM,
  0 VLBASEPARTDEST,
  0 PERCPROVPART,
  0 VLICMSDIFALIQPART,
  0 VLICMSPART,
  0 PERCBASEDPART,
  0 ALIQINTERORIGPART,
    REGEXP_REPLACE(p.desccompleta, '[^[:alnum:] ]', '') descricaopaf,
  (CASE
  WHEN a.SITTRIBUT IN ('00','20','90')
     AND
     a.PERCALIQFCPICMS > 0
    then ((select ROUND(vlrbase,2)
         from monitorpdvmiddle.tb_doctotributacaoitem
        where nroempresa = i.nroempresa
          and nrocheckout = i.nrocheckout
          and seqdocto = i.seqdocto
          and seqitem = i.seqitem
          and seqtipotributacao = 1))
    --THEN ROUND(ti.VLRBASE,2)
  ELSE
    0
    END) vlbasefcpicms,
  0 VLBASEFCPST,
  0 VLBCFPSTRET,
  0 PERFCPSTRET,
  0 VLFCPSTRET,
  NVL(fnc_int_c5_vlacrescimofcp(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM),0) vlacrescimofuncep,
  0 peracrescimofuncep,
  0 ALIQICMSFECP,
  0 VLFECP,
  0 PERDIFEREIMENTOICMS,
  (SELECT vlcustoultent
           FROM vw_int_c5_custos
          WHERE codfilial = c5.CODFILIAL
            AND codauxiliar = i.codacesso) CUSTOULTENT,
  0 PERCREDBASEEFET,
  NVL((SELECT vlbaseefet
       FROM vw_int_c5_custos
      WHERE codfilial = c5.CODFILIAL
      AND codauxiliar = i.codacesso),0) vlbaseefet,
  0 PERCICMSEFET,
  0 VLICMSEFET,
  NULL MD5PAF,
  (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) poriginal,
  i.SEQITEM NUMSEQITEM,
  TO_CHAR(d.dtamovimento, 'YYYY-MM-DD') DATA,
  (select est.vlicmsbcr from pcest est where est.codfilial = v.codfilial and est.codprod = v.codprod) vlicmsbcr,
  0 BASEICMSBCR,
  0 VLDESCONTOMOTOROFERTA,
  0 BASEBCR,
  0 STBCR,
  v.CODFORNEC,
  fnc_int_c5_vldescitem(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM) vldescitem,
  0 VLICMSMONORET,
  0 QBCMONIRET,
  0 ADREMICMSRET,
  d.nroempresa,
  d.nrocheckout
    /*Campos Reforma*/
  /*NULL Xml_qttrib,
  NULL Unidadetrib,
  
  -- IS 
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaois,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CST') CSTIS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CCLASSTRIB') Cclasstribis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRBASE'),'0')) Vlbaseis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERCALIQUOTA'),'0')) Aliqis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRIMPOSTO'),'0')) Vlis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERALIQEFETIVA'),'0'))  Aliqespecificais,
    
  -- CBS 
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTCBS,
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') Cclasstribcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) Vlbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCALIQUOTA'),'0')) Aliqcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) Percredbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) PREDALIQCBS,  
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRIMPOSTO'),'0')) Vlcbs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERALIQEFETIVA'),'0')) Aliqespecificacbs,
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaocbs,
  
    -- IBS 
    (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaoibs,
     fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CST')  Cstibs,     
   fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CCLASSTRIB') Cclasstribibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRBASE'),'0')) vlbaseibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) aliqibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA'),'0')) percredbaseibs, 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRIMPOSTO'),'0')) Vlibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA'),'0'))  Aliqespecificaibs  , 
    
  -- CBSIBS 
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) CODIGOTRIBUTACAOCBSIBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTIBSCBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') CCLASSTRIBIBSCBS,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) VLBASEIBSCBS,

    -- IBSUF 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) IBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERDIFERIMENTO') ,'0')) PDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRDIFERIDO') ,'0')) VDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRTRIBUTO') ,'0')) VIBSUF,
  
  --IBSMUN
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCALIQUOTA'),'0')) PIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERDIFERIMENTO'),'0')) PDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRDIFERIDO') ,'0')) VDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRTRIBUTO') ,'0'))  VIBSMUN
 */
 
 FROM 
    MONITORPDVMIDDLE.TB_DOCTOITEM   I,
    MONITORPDVMIDDLE.TB_DOCTO       D,
    MONITORPDVMIDDLE.TB_DOCTOCUPOM  C,
    MONITORPDVMIDDLE.TB_PRODUTO     P,
    MONITORPDVMIDDLE.TB_PRODUTO     TB_PACAB,
    VW_INT_C5_TRIB_PIS              H,
    PCPRODUT                        V, --VW_INT_C5_PCPRODUT              V,
    PCCONSOLIDATRIBUTACAO           A,
    MONITORPDVMIDDLE.TB_EMPRESA     E,
    PCFILIAL                        EA,
    PCPRODUT                        P_ACAB, --VW_INT_C5_PCPRODUT              P_ACAB,
    VW_INT_C5_OBTER_FILIAIS_C5      C5
  WHERE  I.SEQDOCTO = D.SEQDOCTO
    AND C5.CODFILIALINTEGRACAO = I.NROEMPRESA
  AND C5.CODFILIALINTEGRACAO = D.NROEMPRESA
  AND C5.CODFILIALINTEGRACAO = C.NROEMPRESA
  --AND C5.CODFILIALINTEGRACAO = V.NROEMPRESA
  AND C5.CODFILIALINTEGRACAO = E.NROEMPRESA
  --AND C5.CODFILIALINTEGRACAO = P_ACAB.NROEMPRESA
    AND  I.NROEMPRESA = D.NROEMPRESA
    AND  I.NROCHECKOUT = D.NROCHECKOUT
    AND  I.SEQPRODUTO = P.SEQPRODUTO
    AND  D.SEQDOCTO = C.SEQDOCTO
    AND  D.NROEMPRESA = C.NROEMPRESA
    AND  D.NROCHECKOUT = C.NROCHECKOUT
    --AND  C5.CODFILIAL = V.CODFILIAL
    --AND  I.CODACESSO = V.CODAUXILIAR
    --AND  I.SEQPRODUTO = DC5.SEQPRODUTO
    --AND  C5.CODFILIAL = P_ACAB.CODFILIAL
    AND  I.SEQPRODCOMPOSTO = TB_PACAB.SEQPRODUTO
    AND  I.NROTRIBUTACAO = A.CODST
    AND  I.NROTRIBUTACAO = H.CODST(+)
    AND  I.CODACESSO = H.CODAUXILIAR(+)
    AND  I.nroempresa = H.nroempresa(+)
    AND  E.NROEMPRESA = D.NROEMPRESA
    AND  I.NROEMPRESA = E.NROEMPRESA
    AND  C5.CODFILIAL = EA.CODIGO
    AND  EA.UF = A.UFDESTINO
    AND  TO_CHAR(A.NUMREGIAO) = EA.CODIGO
    AND  C.STATUS IN ('V', 'C')
    AND  I.STATUS = 'V'
    AND  I.SEQPRODCOMPOSTO IS NOT NULL
    AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S'
    AND P.CODPRODUTO = V.CODPROD
    AND TB_PACAB.CODPRODUTO = P_ACAB.CODPROD
  UNION ALL
    SELECT distinct
    I.SEQDOCTO,
    'S' EXPORTADO,
    0 NUMPEDECF,
    I.NROCHECKOUT NUMCAIXA,    
    I.NROCHECKOUT NUMCHECKOUT,
    C.SERIEDOCTO NUMCAIXAFISCAL,
    'NOTAFISCAL' NUMSERIEEQUIP,
    (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) CODECF,
    C5.CODFILIAL CODFILIAL,
    D.SEQUSUARIO CODFUNCCX,
    NULL NUMPED,
    P_ACAB.CODPROD CODPROD,
    ( SELECT min(x.seqitem) 
      FROM monitorpdvmiddle.tb_doctoitem X 
      WHERE x.seqdocto = i.seqdocto 
        AND x.nroempresa = i.nroempresa
        AND x.nrocheckout = i.nrocheckout
        AND x.seqprodcomposto = i.seqprodcomposto
    AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO)  NUMSEQ,
    I.CODACESSO CODAUXILIAR,    
    V.CODPROD CODPRODMP,
    I.QUANTIDADE QTMP,
    (I.VLRUNITARIO / NVL(I.QTDEMBALAGEM, 1)) PTABELA,
    ((I.VLRUNITARIO - (NVL(I.VLRDESCONTO,0)/NVL(I.QUANTIDADE,1)) + (NVL(I.VLRACRESCIMO,0)/NVL(I.QUANTIDADE,1)) )/NVL(I.QTDEMBALAGEM, 1)) PVENDA,
    A.CODST,
    nvl(V.pcomrep1,0) PERCOM,
    A.ALIQICMS1,
    A.ALIQICMS2,
    (CASE WHEN LENGTH(A.SITTRIBUT) < 2 THEN 
          '0'||A.SITTRIBUT
    ELSE
          TO_CHAR(A.SITTRIBUT)
    END) SITTRIBUT,
    I.CFOP CODFISCAL,
  0 PBASERCA,
  0 baseicst,
  0 STCLIENTEGNRE,
  0 PERCIPI,
  0 VLIPI,
  0 PERCISS,
  0 VLISS,
  0 VLDESCSUFRAMA,
  (SELECT vlcustorep
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOREP,
  (SELECT VLCUSTOCONT
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOCONT,
  (SELECT VLCUSTOREAL
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOREAL,
  (SELECT VLCUSTOFIN
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) VLCUSTOFIN,    
  0 VLDESCCUSTOCMV,
  0 PERDESCTAB,
  0 IVA,
  0 PAUTA,
  0 PERCBASERED,
  (SELECT vlcustofin
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) CUSTOFINEST,
  0 PERCBASEREDSTFONTE,
  0 PERCBASEREDST,
  a.CODICMTAB,
  0 TXVENDA,
  0 PERFRETECMV,
  0 VLDESCRODAPE,
  0 VLBASEIPI,
  NVL((select 
      (CASE 
       WHEN doctribitem.percbasecalculo <= 0.0001 THEN
         nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (0.0001 /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)        
       WHEN doctribitem.percbasecalculo <= 100  AND doctribitem.percbasecalculo >= 0.0001 THEN           
           nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (doctribitem.percbasecalculo /100)) / NVL(i.QTDEMBALAGEM, 1) , 0)                       
       ELSE nvl( (i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0)) / NVL(i.QTDEMBALAGEM, 1),0)         
      END) vlrbase              
                   
     from monitorpdvmiddle.tb_doctotributacaoitem doctribitem
     where doctribitem.nroempresa = i.nroempresa
     and doctribitem.nrocheckout = i.nrocheckout
     and doctribitem.seqdocto = i.seqdocto
     and doctribitem.seqitem = i.seqitem
     and doctribitem.seqtipotributacao = 1
     ), 0) baseicms,
    (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) percicm,
  0 PERPIS,
  ((NVL(h.percpis,0)/100) * i.vlrtotal) vlpis,
  0 PERCOFINS,
  ((NVL(h.perccofins,0)/100) * i.vlrtotal) vlcofins,
  0 percdescpis,
  0 vldescreducaocofins,
  0 PERCDIFALIQUOTAS,
  0 VLDIFALIQUOTAS,
    (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) PERCICMS,
    h.percpis,
  0 VLITEMTRIBUTOS,
  0 PERCTRIBUTOS,
  0 BASEIDFALIQUOTAS,
  0 BCSS,
  I.vlrtotal VLSUBTOTITEM,
  0 VLITEMTRIBUTOSESTADUAL,
  0 ALIQINTERNADEST,
  0 ALIQFCP,
  0 VLICMSPERTREM,
  0 VLBASEPARTDEST,
  0 PERCPROVPART,
  0 VLICMSDIFALIQPART,
  0 VLICMSPART,
  0 PERCBASEDPART,
  0 ALIQINTERORIGPART,
    REGEXP_REPLACE(p.desccompleta, '[^[:alnum:] ]', '') descricaopaf,
  (CASE
  WHEN a.SITTRIBUT IN ('00','20','90')
     AND
     a.PERCALIQFCPICMS > 0
    then ((select ROUND(vlrbase,2)
         from monitorpdvmiddle.tb_doctotributacaoitem
        where nroempresa = i.nroempresa
          and nrocheckout = i.nrocheckout
          and seqdocto = i.seqdocto
          and seqitem = i.seqitem
          and seqtipotributacao = 1))
    --THEN ROUND(ti.VLRBASE,2)
  ELSE
    0
    END) vlbasefcpicms,
  0 VLBASEFCPST,
  0 VLBCFPSTRET,
  0 PERFCPSTRET,
  0 VLFCPSTRET,
  NVL(fnc_int_c5_vlacrescimofcp(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM),0) vlacrescimofuncep,
  0 peracrescimofuncep,
  0 ALIQICMSFECP,
  0 VLFECP,
  0 PERDIFEREIMENTOICMS,
  (SELECT vlcustoultent
           FROM vw_int_c5_custos
          WHERE codfilial = C5.CODFILIAL
            AND codauxiliar = i.codacesso) CUSTOULTENT,
  0 PERCREDBASEEFET,
  NVL((SELECT vlbaseefet
       FROM vw_int_c5_custos
      WHERE codfilial = C5.CODFILIAL
      AND codauxiliar = i.codacesso),0) vlbaseefet,
  0 PERCICMSEFET,
  0 VLICMSEFET,
  NULL MD5PAF,
  (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) poriginal,
  i.SEQITEM NUMSEQITEM,
  TO_CHAR(d.dtamovimento, 'YYYY-MM-DD') DATA,
  (select est.vlicmsbcr from pcest est where est.codfilial = v.codfilial and est.codprod = v.codprod) vlicmsbcr,
  0 BASEICMSBCR,
  0 VLDESCONTOMOTOROFERTA,
  0 BASEBCR,
  0 STBCR,
  v.CODFORNEC,
  fnc_int_c5_vldescitem(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM) vldescitem,
  0 VLICMSMONORET,
  0 QBCMONIRET,
  0 ADREMICMSRET,
  d.NROEMPRESA,
  d.nrocheckout
  /*Campos Reforma*/
  /*NULL Xml_qttrib,
  NULL Unidadetrib,
  -- IS
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaois,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CST') CSTIS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'CCLASSTRIB') Cclasstribis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRBASE'),'0')) Vlbaseis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERCALIQUOTA'),'0')) Aliqis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'VLRIMPOSTO'),'0')) Vlis,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 23, 'PERALIQEFETIVA'),'0'))  Aliqespecificais , 
  -- CBS 
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTCBS,
  fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') Cclasstribcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) Vlbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCALIQUOTA'),'0')) Aliqcbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) Percredbasecbs,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERCREDALIQUOTA'),'0')) PREDALIQCBS,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRIMPOSTO'),'0')) Vlcbs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'PERALIQEFETIVA'),'0')) Aliqespecificacbs,
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaocbs,
    -- IBS
    (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'IBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) Codigotributacaoibs,
     fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CST')  Cstibs,     
   fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'CCLASSTRIB') Cclasstribibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRBASE'),'0')) vlbaseibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) aliqibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA'),'0')) percredbaseibs, 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRIMPOSTO'),'0')) Vlibs,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA'),'0'))  Aliqespecificaibs, 
  -- CBSIBS 
  (SELECT TC5.CODIGO_TRIBUTACAO
    FROM PCDEPARATRIBUTACAOC5 TC5
    WHERE TC5.SEQCENARIO = TO_NUMBER(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'SEQCENARIO'))
     AND  TC5.TIPO_IMPOSTO = 'CBS'
     AND  TC5.ATIVO = 'S'
     AND ROWNUM = 1) CODIGOTRIBUTACAOCBSIBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CST') CSTIBSCBS,
    fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'CCLASSTRIB') CCLASSTRIBIBSCBS,
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 24, 'VLRBASE'),'0')) VLBASEIBSCBS,
    -- IBSUF 
    TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCALIQUOTA'),'0')) IBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERDIFERIMENTO') ,'0')) PDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRDIFERIDO') ,'0')) VDIFIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSUF,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 21, 'VLRTRIBUTO') ,'0')) VIBSUF,
  --IBSMUN
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCALIQUOTA'),'0')) PIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERDIFERIMENTO'),'0')) PDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRDIFERIDO') ,'0')) VDIFIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERCREDALIQUOTA') ,'0')) PREDALIQIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'PERALIQEFETIVA') ,'0')) PALIQEFETIBSMUN,
  TO_NUMBER(NVL(fnc_int_c5_BUSCATRIB(i.nroempresa, i.nrocheckout, i.seqdocto, i.seqitem, 22, 'VLRTRIBUTO') ,'0'))  VIBSMUN
*/  
 FROM 
    MONITORPDVMIDDLE.TB_DOCTOITEM   I,
    MONITORPDVMIDDLE.TB_DOCTO       D,
    MONITORPDVMIDDLE.TB_DOCTOCUPOM  C,
    MONITORPDVMIDDLE.TB_PRODUTO     P,
    MONITORPDVMIDDLE.TB_PRODUTO     TB_PACAB,
    VW_INT_C5_TRIB_PIS              H,
    PCPRODUT                        V, --VW_INT_C5_PCPRODUT              V,
    PCCONSOLIDATRIBUTACAO           A,
    MONITORPDVMIDDLE.TB_EMPRESA     E,
    PCFILIAL                        EA,
  PCDEPARAREGIAOC5                div,
  PCPRODUT                        P_ACAB, --VW_INT_C5_PCPRODUT              P_ACAB,
  VW_INT_C5_OBTER_FILIAIS_C5      C5
  WHERE  I.SEQDOCTO = D.SEQDOCTO
    AND C5.CODFILIALINTEGRACAO = I.NROEMPRESA
  AND C5.CODFILIALINTEGRACAO = D.NROEMPRESA
  AND C5.CODFILIALINTEGRACAO = C.NROEMPRESA
  --AND C5.CODFILIALINTEGRACAO = V.NROEMPRESA
  AND C5.CODFILIALINTEGRACAO = E.NROEMPRESA
  --AND C5.CODFILIALINTEGRACAO = P_ACAB.NROEMPRESA
    AND  I.NROEMPRESA = D.NROEMPRESA
    AND  I.NROCHECKOUT = D.NROCHECKOUT
    AND  I.SEQPRODUTO = P.SEQPRODUTO
    AND  D.SEQDOCTO = C.SEQDOCTO
    AND  D.NROEMPRESA = C.NROEMPRESA
    AND  D.NROCHECKOUT = C.NROCHECKOUT
    --AND  C5.CODFILIAL = V.CODFILIAL
    --AND  I.CODACESSO = V.CODAUXILIAR
    --AND  I.SEQPRODUTO = DC5.SEQPRODUTO
    --AND  C5.CODFILIAL = P_ACAB.CODFILIAL
    AND  I.SEQPRODCOMPOSTO = TB_PACAB.SEQPRODUTO
    AND  I.NROTRIBUTACAO = A.CODST
    AND  I.NROTRIBUTACAO = H.CODST(+)
    AND  I.CODACESSO = H.CODAUXILIAR(+)
    AND  I.nroempresa = H.nroempresa(+)
    AND  E.NROEMPRESA = D.NROEMPRESA
    AND  I.NROEMPRESA = E.NROEMPRESA
    AND  C5.CODFILIAL = EA.CODIGO
    AND  EA.UF = A.UFDESTINO
    AND  div.nrodivisao = e.nrodivisao
    AND  a.numregiao = div.numregiao
    AND  C.STATUS IN ('V', 'C')
    AND  I.STATUS = 'V'
    AND  I.SEQPRODCOMPOSTO IS NOT NULL
    AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
    AND P.CODPRODUTO = V.CODPROD
    AND TB_PACAB.CODPRODUTO = P_ACAB.CODPROD
)
