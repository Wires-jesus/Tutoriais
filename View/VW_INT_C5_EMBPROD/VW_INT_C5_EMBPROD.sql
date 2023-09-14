CREATE OR REPLACE VIEW VW_INT_C5_EMBPROD AS
(SELECT     e.codfilial,
            e.dtulalterintegra,
            e.dtcadastro,
            e.dtinativo,
            e.codprod,
            e.codauxiliar,
            LENGTH(E.CODAUXILIAR) tamanho_ean,
            p.descricao descricao,
            e.descricaoecf descricaoreduzida,
            NVL(e.pvenda,0) pvenda,
            e.dtultaltpvenda,
            COALESCE(e.poferta, 0) poferta,
            COALESCE(e.pofertaatac, 0) pofertaatac,
            e.dtofertaini,
            e.dtofertafim,
            e.dtofertaatacini,
            e.dtofertaatacfim,
            NVL(e.qtunit,1) qtunit,
            NVL(e.prazoval,0) prazoval,
            NVL(e.qtminimaatacado,0) qtminimaatacado,
            NVL(e.pvendaatac,0) pvendaatac,
            NVL(e.enviabalanca, 'N') enviabalanca,
            NVL(e.unidade,p.unidade) unidade,
            NVL(NVL(e.pesobruto,p.pesobruto),0) pesobruto,
            NVL(NVL(e.pesoliq,p.pesoliq),0) pesoliq,

            CASE WHEN p.pesovariavel NOT IN ('S', 'N') THEN
                  'N'
             ELSE NVL(p.pesovariavel, 'N')
            END pesovariavel,

            CASE WHEN p.aceitavendafracao NOT IN ('S', 'N') THEN
                  'N'
             ELSE NVL(p.aceitavendafracao, 'N')
            END aceitavendafracao,

            'S' permitemultiplicacao, --NECESSÁRIO CRIAR O CAMPO NA 203

            NVL(NVL(e.pcomrep1,p.pcomrep1),0) comissao,
            NVL(e.tipoembalagem,'U') tipoembalagem,
            NVL(e.prodsemcodbarras,'N') prodsemcodbarras,
            p.codfornec codfornec_prod,
            p.volume volume_prod,
            p.codmarca, 
            NVL(p.tipomerc,'L') tipomerc,
            p.nbm codncmsh,
            LENGTH(p.nbm) tamanho_codncmsh,
            p.dtultalter dtultalter_prod,
            p.dtcadastro dtcadastro_prod,
            p.dtexclusao dtexclusao_prod,
            e.dtultaltpvendaatac,
            p.anp anp,
            p.descanp descanp,
            p.codprodprinc,
            (CASE
                WHEN e.dtinativo IS NOT NULL
                    THEN 'N'
                WHEN f.proibidavenda = 'N'
                    THEN 'N'
                WHEN p.dtexclusao IS NOT NULL
                    THEN 'N'
                ELSE
                    'S'
              END) ativo,
            NVL(p.revenda,'S') revenda,
            /*(SELECT CODCEST 
             FROM PCCEST 
             INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST 
             WHERE PCCESTPRODUTO.CODPROD = p.CODPROD
             AND ROWNUM = 1) codcest,*/
            p.codsec,
            p.codepto,
            p.codcategoria,
            p.codsubcategoria,
            (CASE
                WHEN NVL(p.obs2,'XX') = 'FL'
                    THEN 'S'
                WHEN f.foralinha = 'S'
                    THEN 'S'
                ELSE
                    'N'
              END) foralinha,
            f.indescalarelevante,
            f.cnpjfabricante,
            e.dtalterc5
       FROM pcembalagem e,
            pcprodut p,
            pcprodfilial f,
            (select min(s.ultimaexecucao) ultimaexecucao
             from pccontroleconsinco s
             where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODUTO')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMEMBALAGEM')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODEMPRESA')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODCODIGO')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODPRECO')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAO')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMSEGMENTO')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAOCATEGORIA')
             or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODPRECOAPARTIR')
             ) DTPADRAO
      WHERE p.codprod = e.codprod
        AND e.codprod = f.codprod
        AND e.codfilial = f.codfilial
        AND NVL(P.REVENDA,'S') = 'S'
        AND NVL(P.TIPOMERC, 'L') = 'L'
        AND P.DTEXCLUSAO IS NULL
        AND LENGTH(p.nbm) >= 2
        AND e.codprod >= 0
        AND f.codprod >= 0
        AND NVL(e.enviafrentecaixa,'S') = 'S'
        AND e.dtinativo IS NULL
        AND NVL(f.proibidavenda, 'N') = 'N'
        --AND p.codprod >= 0
        AND LENGTH(e.codauxiliar) <= 14
        AND GREATEST(NVL(e.dtalterc5, DTPADRAO.ULTIMAEXECUCAO),
                     NVL(p.dtalterc5, DTPADRAO.ULTIMAEXECUCAO),
                     NVL(f.dtalterc5, DTPADRAO.ULTIMAEXECUCAO)) >= DTPADRAO.ULTIMAEXECUCAO)

