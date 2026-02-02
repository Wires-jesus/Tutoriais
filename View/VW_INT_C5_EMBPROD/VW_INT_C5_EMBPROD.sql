CREATE OR REPLACE VIEW VW_INT_C5_EMBPROD AS
CREATE OR REPLACE VIEW VW_TESTE_11 AS
WITH
  DTPADRAO AS (SELECT /*+ INLINE */ MIN(S.ULTIMAEXECUCAO) -1440/24/60 AS ULTIMAEXECUCAO
               FROM PCCONTROLECONSINCO S
               WHERE S.ATIVO = 'A'
               AND  ((upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODUTO')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMEMBALAGEM')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODEMPRESA')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODCODIGO')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODPRECO')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAO')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMSEGMENTO')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAOCATEGORIA')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODCOMPOSTO')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PRODPRECOAPARTIR')
               OR    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_LIMITEVENDAFAMILIA'))
              ),

  FILIAIS AS (SELECT /*+ INLINE */ CODFILIAL, CODFILIALINTEGRACAO FROM VW_INT_C5_OBTER_FILIAIS_C5),

  PARAM_REGIAO AS (
    SELECT /*+ INLINE */ 
	       F.CODFILIAL,
           FERRAMENTAS.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO', F.CODFILIAL, 1) AS NUMREGIAO
    FROM FILIAIS F
  ),

  DTFIMCARGA AS (
    SELECT /*+ INLINE */ NVL(PAR.VALOR_DATA, CURRENT_TIMESTAMP) DTFIM
    FROM PCPARAMETROS2651 PAR
    WHERE PAR.NOME = 'DTFIMCARGA'
  ),

PROD_ALTERADOS AS (SELECT * FROM(
                   SELECT R.*,
                          /*OVERPARTITION PARA IDENTIFICAR REGISTROS COM O MESMO CODPROD ENTRE PCTABPR E AS DEMAIS TABELAS.
                            QUANDO RETORNAR REGISTRO VINDOS DA PCTABPR, DEVE-SE MANTER O MESMO E ELIMINAR OS DEMAIS COM O
                            MESMO CODPROD, INDEPENDENTE DE QUAL SEJA A TABELA(PCEMBALAGEM, PCPRODUT OU PCPRODFILIAL).
                            CASO NAO RETORNE REGISTRO DA PCTABPR, A CLAUSULA UNION SELECIONARÁ APENAS UM DOS REGISTROS
                            ENTRE AS TABELAS PCEMBALAGEM, PCPRODUT E PCPRODFILIAL. DESSA FORMA O RESULTADO DO CTE NUNCA TRARÁ
                            REGISTROS DUPLICADOS.
                          */
                          MAX(CASE
                                WHEN R.NUMREGIAO > 0 THEN
                                     1 --QUANDO CLIENTE TRABALHA COM PREÇO POR REGIÃO
                                ELSE 0 --QUANDO CLIENTE TRABALHA COM PREÇO POR EMBALAGEM
                              END
                             ) OVER (PARTITION BY R.CODPROD) AS MANTEM_REGIAO
                   FROM(
                        /*PCEMBALAGEM*/
                        SELECT /*+
                                USE_HASH(F)
                                INDEX(E IDX_E_SINC_C5_COVERING) CARDINALITY(E 100)
                            */
                            E.CODPROD,
                            0 NUMREGIAO,
                            '0' CODFILIAL, --NAO PRECISA SETAR FILIAL, POIS SERÁ CONSIDERADO TODAS AS EMBALAGENS, INDEPENDENTE DA FILIAL
                            0 PVENDA,
                            TRUNC(SYSDATE) DTULTALTPVENDA,
                            0 PVENDAATAC,
                            TRUNC(SYSDATE) DTULTALTPVENDAATAC,
                            0 COMISSAO

                        FROM PCEMBALAGEM E
                        JOIN FILIAIS F ON F.CODFILIAL = E.CODFILIAL
                        CROSS JOIN DTFIMCARGA DTC
                        JOIN DTPADRAO D ON E.DTALTERC5 BETWEEN D.ULTIMAEXECUCAO AND DTC.DTFIM

                        WHERE E.CODPROD >= 0
                        AND   LENGTH(E.CODAUXILIAR) <= 14

                        UNION

                        /*PRODFILIAL*/
                        SELECT /*+
                                USE_HASH(PF F)
                                INDEX(PF IDX_PCPRODFILIAL_C5_TESTE) CARDINALITY(PF 100)
                            */
                            PF.CODPROD,
                            0 NUMREGIAO,
                            '0' CODFILIAL, --NAO PRECISA SETAR FILIAL, POIS SERÁ CONSIDERADO TODAS AS EMBALAGENS, INDEPENDENTE DA FILIAL
                            0 PVENDA,
                            TRUNC(SYSDATE) DTULTALTPVENDA,
                            0 PVENDAATAC,
                            TRUNC(SYSDATE) DTULTALTPVENDAATAC,
                            0 COMISSAO

                        FROM PCPRODFILIAL PF
                        JOIN PCEMBALAGEM E ON E.CODPROD = PF.CODPROD AND E.CODFILIAL = PF.CODFILIAL
                        JOIN FILIAIS F ON F.CODFILIAL = PF.CODFILIAL
                        CROSS JOIN DTFIMCARGA DTC
                        JOIN DTPADRAO D ON PF.DTALTERC5 BETWEEN D.ULTIMAEXECUCAO AND DTC.DTFIM

                        UNION

                        /*PRODUTO*/
                        SELECT /*+
                                USE_HASH(P)
                                INDEX(P IDX_PCPRODUT_C5_TESTE) LEADING(D P)
                            */
                            P.CODPROD,
                            0 NUMREGIAO,
                            '0' CODFILIAL,--NAO PRECISA SETAR FILIAL, POIS SERÁ CONSIDERADO TODAS AS EMBALAGENS, INDEPENDENTE DA FILIAL
                            0 PVENDA,
                            TRUNC(SYSDATE) DTULTALTPVENDA,
                            0 PVENDAATAC,
                            TRUNC(SYSDATE) DTULTALTPVENDAATAC,
                            0 COMISSAO

                        FROM PCPRODUT P
                        CROSS JOIN DTFIMCARGA DTC
                        JOIN DTPADRAO D ON P.DTALTERC5 BETWEEN D.ULTIMAEXECUCAO AND DTC.DTFIM


                        UNION

                        /*PCTABPR*/
                        SELECT
                            /*+
                                USE_HASH(P)
                                INDEX(TPR IDX_PCTABPR_SINC_C5_COVERING) LEADING(D PR F TPR)
                            */
                            TPR.CODPROD,
                            TPR.NUMREGIAO,
                            F.CODFILIAL, --SETA A FILIAL POIS PODE NÃO EXISITIR EMBALAGENS NA FILIAL VINCULADA A UMA REGIÃO DO PRODUTO
                            TPR.PVENDA1 PVENDA,
                            TPR.DTULTALTPVENDA,
                            TPR.PVENDAATAC1 PVENDAATAC,
                            TPR.DTULTALTPVENDA DTULTALTPVENDAATAC,
                            TPR.PCOMREP1 COMISSAO

                        FROM PCTABPR TPR
                        JOIN PARAM_REGIAO PR ON TPR.NUMREGIAO = PR.NUMREGIAO
                        JOIN FILIAIS F ON F.CODFILIAL = PR.CODFILIAL
                        CROSS JOIN DTFIMCARGA DTC
                        JOIN DTPADRAO D ON TPR.DTALTERC5 BETWEEN D.ULTIMAEXECUCAO AND DTC.DTFIM

                        WHERE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM',
                                                                  F.CODFILIAL,
                                                                  'N') = 'N'

                   )R
                 )
                 WHERE (MANTEM_REGIAO = 1 AND NUMREGIAO > 0) OR (MANTEM_REGIAO = 0)
    )

    SELECT  /*+
        NO_MERGE(PA)
        CARDINALITY(PA 5000)
        LEADING(PA F)
        USE_NL(F)
        LEADING(F E)
        USE_NL(E)
        INDEX(E PCEMBALAGEM_C5_IDX01)
        LEADING(E P)
        USE_NL(P)
        INDEX(P PCPRODUT_PK)
        */
        e.codfilial,
        c5.codfilialintegracao,
        e.dtulalterintegra,
        e.dtcadastro,
        e.dtinativo,
        e.codprod,
        e.codauxiliar,
        LENGTH(E.CODAUXILIAR) tamanho_ean,
        p.descricao descricao,
        e.descricaoecf descricaoreduzida,

        /*NAO USAMOS BOAS PRATICAS NESSE PONTO PELA PERDA DE COMUNICAÇÃO EM VERSÕES ORACLE 11.0.1 DEVIDO O USO DE CROSS JOIN*/
        CASE
          WHEN PA.NUMREGIAO = 0 THEN
               NVL(e.pvenda, 0)
          WHEN FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_TIPOPRECIFICACAO', '99', 'V') = 'A' THEN
               (NVL(PA.PVENDAATAC, 0) * NVL(E.QTUNIT, 1) * DECODE(E.FATORPRECO, 0, 1, NULL, 1, E.FATORPRECO))
          ELSE (NVL(PA.PVENDA, 0) * NVL(E.QTUNIT, 1) * DECODE(E.FATORPRECO, 0, 1, NULL, 1, E.FATORPRECO))
        END PVENDA,

        CASE
           WHEN PA.NUMREGIAO = 0 THEN
                E.DTULTALTPVENDA
           ELSE PA.DTULTALTPVENDA
        END DTULTALTPVENDA,

        COALESCE(e.poferta, 0) poferta,
        COALESCE(e.pofertaatac, 0) pofertaatac,
        e.dtofertaini,
        e.dtofertafim,
        e.dtofertaatacini,
        e.dtofertaatacfim,
        LEAST(NVL(round(e.qtunit, 3), 1), 999999.999) qtunit,
        NVL(e.prazoval,0) prazoval,

        CASE
          WHEN PA.NUMREGIAO = 0 THEN
               LEAST(NVL(round(E.QTMINIMAATACADO, 3), 0), 999999.999)
          ELSE LEAST(NVL(round(F.QTMINIMAATACADO, 3), 0), 999999.999)
        END QTMINIMAATACADO,

        /*NAO USAMOS BOAS PRATICAS NESSE PONTO PELA PERDA DE COMUNICAÇÃO EM VERSÕES ORACLE 11.0.1 DEVIDO O USO DE CROSS JOIN*/
        CASE
          WHEN PA.NUMREGIAO = 0 THEN
               NVL(e.pvendaatac,0)
          WHEN FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_TIPOPRECIFICACAO', '99', 'V') = 'A' THEN
               (NVL(PA.PVENDA, 0) * NVL(E.QTUNIT, 1) * DECODE(E.FATORPRECO, 0, 1, NULL, 1, E.FATORPRECO))
          ELSE (NVL(PA.PVENDAATAC, 0) * NVL(E.QTUNIT, 1) * DECODE(E.FATORPRECO, 0, 1, NULL, 1, E.FATORPRECO))
        END PVENDAATAC,

        NVL(e.enviabalanca, 'N') enviabalanca,
        NVL(e.unidade,p.unidade) unidade,
        NVL(NVL(e.pesobruto,p.pesobruto),0) pesobruto,
        NVL(NVL(e.pesoliq,p.pesoliq),0) pesoliq,

        CASE 
		   WHEN e.tipoembalagem = 'P' THEN
               'S'
           ELSE 'N'
        END pesovariavel,

        CASE 
		   WHEN p.aceitavendafracao NOT IN ('S', 'N') THEN
                'N'
           ELSE NVL(p.aceitavendafracao, 'N')
        END aceitavendafracao,

        'S' permitemultiplicacao, 

        CASE
           WHEN PA.NUMREGIAO = 0 THEN
                NVL(NVL(e.pcomrep1,p.pcomrep1),0)
           ELSE NVL(NVL(NVL(PA.COMISSAO ,E.PCOMREP1), P.PCOMREP1), 0)
        END COMISSAO,

        NVL(e.tipoembalagem,'U') tipoembalagem,
        NVL(e.prodsemcodbarras,'N') prodsemcodbarras,
        p.codfornec codfornec_prod,
        p.volume volume_prod,
            
        /*NAO USAMOS BOAS PRATICAS NESSE PONTO PELA PERDA DE COMUNICAÇÃO EM VERSÕES ORACLE 11.0.1 DEVIDO O USO DE CROSS JOIN*/
        NVL((SELECT P.CODMARCA
             FROM PCPRODUT P2, PCMARCA M
             WHERE P.CODMARCA = M.CODMARCA
             AND M.ATIVO = 'S'
             AND P.CODPROD = P2.CODPROD
             AND P.CODMARCA > 0), FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('MARCAINTEGRACAOCONSINCO', '99', '')
            ) CODMARCA,
        NVL(p.tipomerc,'L') tipomerc,
        p.nbm codncmsh,
        LENGTH(p.nbm) tamanho_codncmsh,
        p.dtultalter dtultalter_prod,
        p.dtcadastro dtcadastro_prod,
        p.dtexclusao dtexclusao_prod,

        CASE
           WHEN PA.NUMREGIAO = 0 THEN
                E.dtultaltpvendaatac
           ELSE PA.DTULTALTPVENDA
        END DTULTALTPVENDAATAC,

        p.anp anp,
        p.descanp descanp,
        p.pglp,
        p.pgnn,
        p.pgni,
        p.codprodprinc,
        
		CASE
            WHEN e.dtinativo IS NOT NULL  THEN 
			     'N'
            WHEN f.proibidavenda = 'S' THEN 
			     'N'
            WHEN p.dtexclusao IS NOT NULL THEN 
			     'N'
            ELSE 'S'
        END ativo,
        
		NVL(p.revenda,'S') revenda,
        p.codsec,
        p.codepto,
        p.codcategoria,
        p.codsubcategoria,
        
		CASE
            WHEN NVL(p.obs2,'XX') = 'FL' THEN 
			     'S'
            WHEN f.foralinha = 'S' THEN 
			     'S'
            ELSE 'N'
        END foralinha,
        f.indescalarelevante,
        f.cnpjfabricante,
        e.dtalterc5,
        p.codauxiliartrib,
        0 CODCEST,
        e.QTMAXVENDA,
        NVL(p.estoqueporlote, 'N') estoqueporlote,
        NVL(e.checapesoetiqueta, 'N') checapesoetiqueta
      FROM PROD_ALTERADOS PA
            /*PARA PREÇO POR EMBALAGEM: VINCULA O CODPROD DO CTE COM A PCEMBALAGEM E OS REGISTROS C/ FILIAL "ZERO", PARA TRAZER TODAS AS EMBALAGENS DO PRODUTO*/
            /*PARA PREÇO POR REGIÃO :   VINCULA CODPROD E FILIAL DO CTE COM A PCEMBALAGEM(ELIMINAR REGIÕES QUE NÃO POSSUEM EMBALAGEM CADASTRADAS), PARA TRAZER TODAS AS EMBALAGENS DO PRODUTO*/
            JOIN PCEMBALAGEM E ON E.CODPROD = PA.CODPROD AND (PA.CODFILIAL = '0' OR E.CODFILIAL = PA.CODFILIAL)
            JOIN PCPRODFILIAL F ON (F.CODPROD = E.CODPROD AND F.CODFILIAL = E.CODFILIAL AND F.CODPROD = PA.CODPROD)
            JOIN PCPRODUT P ON (P.CODPROD = E.CODPROD AND  P.CODPROD = PA.CODPROD)
            JOIN VW_INT_C5_OBTER_FILIAIS_C5 C5 ON C5.CODFILIAL = E.CODFILIAL
      WHERE (LENGTH(p.nbm) >= 2 OR p.TIPOMERC in ('KT', 'CB'))
      AND E.codprod >= 0
      AND F.CODPROD >=0
      AND LENGTH(E.codauxiliar) <= 14

