CREATE OR REPLACE VIEW VW_INT_C5_EMBPROD AS
(
    SELECT
            e.codfilial,
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
            --NVL(e.qtunit,1) qtunit,
            LEAST(NVL(e.qtunit, 1), 999999.999) qtunit,
            NVL(e.prazoval,0) prazoval,
            --NVL(e.qtminimaatacado,0) qtminimaatacado,
            LEAST(NVL(e.qtminimaatacado, 0), 999999.999) qtminimaatacado,
            NVL(e.pvendaatac,0) pvendaatac,
            NVL(e.enviabalanca, 'N') enviabalanca,
            NVL(e.unidade,p.unidade) unidade,
            NVL(NVL(e.pesobruto,p.pesobruto),0) pesobruto,
            NVL(NVL(e.pesoliq,p.pesoliq),0) pesoliq,

            /*CASE WHEN p.pesovariavel NOT IN ('S', 'N') THEN
                  'N'
             ELSE NVL(p.pesovariavel, 'N')
            END pesovariavel,*/

            CASE WHEN e.tipoembalagem = 'P' THEN
                  'S'
             ELSE 'N'
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
            NVL(M.codmarca, PCPARAMFILIAL.MARCAPADRAO) CODMARCA,
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
                WHEN f.proibidavenda = 'S'
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
            e.dtalterc5,
            p.codauxiliartrib,
            0 CODCEST --PROVISORIO
       FROM pcembalagem e,
            pcprodut p
            LEFT JOIN PCMARCA M ON (P.CODMARCA = M.CODMARCA AND M.ATIVO = 'S'),    
            pcprodfilial f,
            VW_INT_C5_OBTER_FILIAIS_C5 c5,
            (select VALOR MARCAPADRAO FROM PCPARAMFILIAL WHERE NOME = 'MARCAINTEGRACAOCONSINCO' AND CODFILIAL = 99) PCPARAMFILIAL,
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
        and e.codfilial = c5.codfilial
        AND NVL(P.REVENDA,'S') = 'S'
        --AND NVL(P.TIPOMERC, 'L') = 'L'
        AND P.DTEXCLUSAO IS NULL
        AND LENGTH(p.nbm) >= 2
        AND e.codprod >= 0
        AND f.codprod >= 0
        AND NVL(e.enviafrentecaixa,'S') = 'S'
        AND e.dtinativo IS NULL
        AND NVL(f.proibidavenda, 'N') = 'N'
        --AND p.codprod >= 0
        AND LENGTH(e.codauxiliar) <= 14
		AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM',
                                                                  c5.CODFILIAL,
                                                                  'N') = 'S'
        AND GREATEST(NVL(e.dtalterc5, DTPADRAO.ULTIMAEXECUCAO),
                     NVL(p.dtalterc5, DTPADRAO.ULTIMAEXECUCAO),
                     NVL(f.dtalterc5, DTPADRAO.ULTIMAEXECUCAO)) >= DTPADRAO.ULTIMAEXECUCAO
    UNION ALL
    SELECT E.CODFILIAL,
        E.DTULALTERINTEGRA,
        E.DTCADASTRO,
        E.DTINATIVO,
        E.CODPROD,
        E.CODAUXILIAR,
        LENGTH(E.CODAUXILIAR) TAMANHO_EAN,
        P.DESCRICAO DESCRICAO,
        E.DESCRICAOECF DESCRICAOREDUZIDA,
        (NVL(TPR.PVENDA1, 0) * NVL(E.QTUNIT, 1)) PVENDA,
        TPR.DTULTALTPVENDA,
        0 POFERTA,
        0 POFERTAATAC,
        E.DTOFERTAINI,
        E.DTOFERTAFIM,
        E.DTOFERTAATACINI,
        E.DTOFERTAATACFIM,
        LEAST(NVL(E.QTUNIT, 1), 999999.999) QTUNIT,
        NVL(NVL(PF.PRAZOVAL, E.PRAZOVAL), 0) PRAZOVAL,
        LEAST(NVL(PF.QTMINIMAATACADO, 0), 999999.999) QTMINIMAATACADO,
        (NVL(TPR.PVENDAATAC1, 0)*NVL(E.QTUNIT, 1)) PVENDAATAC,
        NVL(E.ENVIABALANCA, 'N') ENVIABALANCA,
        NVL(E.UNIDADE, P.UNIDADE) UNIDADE,
        NVL(NVL(E.PESOBRUTO, P.PESOBRUTO), 0) PESOBRUTO,
        NVL(NVL(E.PESOLIQ, P.PESOLIQ), 0) PESOLIQ,
        CASE
          WHEN E.TIPOEMBALAGEM = 'P' THEN
           'S'
          ELSE
           'N'
        END PESOVARIAVEL,
        CASE
          WHEN NVL(PF.ACEITAVENDAFRACAO ,P.ACEITAVENDAFRACAO) NOT IN ('S', 'N') THEN
           'N'
          ELSE
           NVL(NVL(PF.ACEITAVENDAFRACAO,P.ACEITAVENDAFRACAO), 'N')
        END ACEITAVENDAFRACAO,
        'S' PERMITEMULTIPLICACAO, --NECESSÁRIO CRIAR O CAMPO NA 203
        NVL(NVL(NVL(TPR.PCOMREP1 ,E.PCOMREP1), P.PCOMREP1), 0) COMISSAO,
        NVL(E.TIPOEMBALAGEM, 'U') TIPOEMBALAGEM,
        NVL(E.PRODSEMCODBARRAS, 'N') PRODSEMCODBARRAS,
        P.CODFORNEC CODFORNEC_PROD,
        P.VOLUME VOLUME_PROD,
        NVL(M.CODMARCA, PCPARAMFILIAL.MARCAPADRAO) CODMARCA,
        NVL(P.TIPOMERC, 'L') TIPOMERC,
        P.NBM CODNCMSH,
        LENGTH(P.NBM) TAMANHO_CODNCMSH,
        P.DTULTALTER DTULTALTER_PROD,
        P.DTCADASTRO DTCADASTRO_PROD,
        P.DTEXCLUSAO DTEXCLUSAO_PROD,
        TPR.DTULTALTPVENDA DTULTALTPVENDAATAC,
        P.ANP ANP,
        P.DESCANP DESCANP,
        P.CODPRODPRINC,
        (CASE
          WHEN E.DTINATIVO IS NOT NULL THEN
           'N'
          WHEN PF.PROIBIDAVENDA = 'S' THEN
           'N'
          WHEN P.DTEXCLUSAO IS NOT NULL THEN
           'N'
          ELSE
           'S'
        END) ATIVO,
        NVL(NVL(PF.REVENDA,P.REVENDA), 'S') REVENDA,
        P.CODSEC,
        P.CODEPTO,
        P.CODCATEGORIA,
        P.CODSUBCATEGORIA,
        (CASE
          WHEN NVL(P.OBS2, 'XX') = 'FL' THEN
           'S'
          WHEN PF.FORALINHA = 'S' THEN
           'S'
          ELSE
           'N'
        END) FORALINHA,
        PF.INDESCALARELEVANTE,
        PF.CNPJFABRICANTE,
        TPR.DTALTERC5,
        P.CODAUXILIARTRIB,
        0 CODCEST --PROVISORIO  
   FROM PCTABPR TPR
  INNER JOIN PCEMBALAGEM E
     ON (E.CODPROD = TPR.CODPROD)
  INNER JOIN PCPRODUT P
     ON (P.CODPROD = TPR.CODPROD)
  INNER JOIN PCPRODFILIAL PF
     ON (PF.CODPROD = P.CODPROD AND E.CODFILIAL = PF.CODFILIAL)
  INNER JOIN VW_INT_C5_OBTER_FILIAIS_C5 FC5
     ON (FC5.CODFILIAL = PF.CODFILIAL AND FC5.CODFILIAL = E.CODFILIAL)
   LEFT JOIN PCMARCA M
     ON (M.CODMARCA = P.CODMARCA),
  (SELECT MIN(S.ULTIMAEXECUCAO) ULTIMAEXECUCAO
           FROM PCCONTROLECONSINCO S
          WHERE (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODUTO')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMEMBALAGEM')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODEMPRESA')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODCODIGO')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODPRECO')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAO')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMSEGMENTO')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAOCATEGORIA')
             OR (UPPER(S.OBJETOREFERENCIA) =
                'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODPRECOAPARTIR'))
  DTPADRAO, (SELECT VALOR MARCAPADRAO
           FROM PCPARAMFILIAL
          WHERE NOME = 'MARCAINTEGRACAOCONSINCO'
            AND CODFILIAL = 99) PCPARAMFILIAL
  WHERE NVL(NVL(PF.REVENDA ,P.REVENDA), 'S') = 'S'
    --AND NVL(P.TIPOMERC, 'L') = 'L'
    AND P.DTEXCLUSAO IS NULL
    AND LENGTH(P.NBM) >= 2
    AND E.CODPROD >= 0
    AND PF.CODPROD >= 0
    AND NVL(E.ENVIAFRENTECAIXA, 'S') = 'S'
    AND E.DTINATIVO IS NULL
    AND NVL(PF.PROIBIDAVENDA, 'N') = 'N'
    AND LENGTH(E.CODAUXILIAR) <= 14
    AND TPR.NUMREGIAO = (SELECT FERRAMENTAS.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',
                                                                  FC5.CODFILIAL,
                                                                  1)
                           FROM DUAL)
    AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM',
                                                                  FC5.CODFILIAL,
                                                                  'N') = 'N'
    AND GREATEST(NVL(E.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO),
                 NVL(P.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO),
                 NVL(PF.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO),
                 NVL(TPR.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO)) >=
        DTPADRAO.ULTIMAEXECUCAO	
)
