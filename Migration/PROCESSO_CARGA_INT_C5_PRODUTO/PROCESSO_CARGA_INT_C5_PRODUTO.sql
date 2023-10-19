CREATE OR REPLACE VIEW VW_INT_C5_MARCA AS
(
  SELECT DISTINCT
         MARCA.*
  FROM(
        SELECT  DISTINCT 
              m.codmarca     AS seqmarca,
              SUBSTR(m.marca,1,20)    AS marca,
              
              (case 
                when NVL(m.ativo, 'S') = 'N' then
                     'N'
                else 'S'
               end) ativo    
        FROM pcprodut p
        INNER JOIN pcmarca m
        ON m.codmarca = p.codmarca
        AND m.codmarca > 0
  UNION ALL
        SELECT  CODMARCA seqmarca,
                SUBSTR(MARCA,1,20) marca,
                (case 
                 when NVL(ativo, 'S') = 'N' then
                     'N'
                 else 'S'
                 end) ativo
        FROM PCMARCA 
        WHERE CODMARCA > 0
        AND CODMARCA = ferramentas.f_buscarparametro_num('MARCAINTEGRACAOCONSINCO', '99', '1')) MARCA
)

 \

CREATE OR REPLACE VIEW VW_INT_C5_FAMILIA AS
(
  SELECT DISTINCT
         p.codprod seqfamilia,
         NVL(fnc_remove_char_esp(substr(p.descricao,0,39)), '-') familia,
         MAX(p.codncmsh) codncmsh,
         MAX(p.aceitavendafracao) permitedecimal,
         MAX(p.permitemultiplicacao) permitemultiplicacao,
         (SELECT nvl(CODCEST, 0) codcest
          FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST
          WHERE PCCESTPRODUTO.CODPROD = p.codprod
          AND ROWNUM = 1
         ) codcest,
         'S' ativo,
         MAX(p.codmarca) seqmarca,
         1 seqfamgrupo,
         MAX(p.pesovariavel) PESAVEL,
         MIN(NVL(p.indescalarelevante, 'S')) indescala,
         MAX(fnc_remove_char_esp(p.cnpjfabricante)) cnpjfabricante,
         MAX(p.codauxiliartrib) eantrib,
         MAX(P.codprodprinc) seqfamiliaprinc
  FROM VW_INT_C5_EMBPROD p
  GROUP BY p.codprod, p.descricao
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMEMBALAGEM AS
(
  SELECT
    SEQFAMILIA,
    QTDEMBALAGEM QTDEMBALAGEM,
    max(EMBALAGEM) EMBALAGEM,
    max(PESOBRUTO) PESOBRUTO,
    max(PESOLIQ) PESOLIQ,
    max(PESOAFERIDO) PESOAFERIDO,
    max(ATIVO) ATIVO
 FROM
  (
  --Embalagem preço varejo
  select distinct
    e.codprod seqfamilia,
    NVL(e.qtunit, 1) qtdembalagem,
    NVL(max(e.unidade), '1') embalagem,
    NVL(max(e.pesobruto), 0) pesobruto,
    NVL(max(e.pesoliq), 0) pesoliq,
    'N' pesoaferido,
    'S' ativo
  from VW_INT_C5_EMBPROD e
  where
    qtunit <> qtminimaatacado
  group by
    e.codprod,
    NVL(e.qtunit, 1)

  UNION ALL
 --Embalagem preço Atacado
  select distinct
    e.codprod seqfamilia,
    NVL(e.qtminimaatacado, 1) qtdembalagem,
    NVL(max(e.unidade), '1') embalagem,
    NVL(max(e.pesobruto), 0) pesobruto,
    NVL(max(e.pesoliq), 0) pesoliq,
    'N' pesoaferido,
    'S' ativo
  from VW_INT_C5_EMBPROD e
  where
    e.qtminimaatacado > 1
  group by
    e.codprod,
    NVL(e.qtminimaatacado, 1))DADOSEMB
  group by SEQFAMILIA, QTDEMBALAGEM
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO AS
(
  SELECT DISTINCT
   PROD.CODAUXILIAR IDREF,
   P.SEQPRODUTO SEQPRODUTO,
   MAX(PROD.CODPRODUTO) CODPRODUTO,
   MAX(PROD.desccompleta) desccompleta,
   MAX(PROD.descreduzida) descreduzida,
   MAX(PROD.produtocomposto) produtocomposto,
   MAX(PROD.SEQFAMILIA) SEQFAMILIA,
   MAX(PROD.QTDDIAVALIDADE) QTDDIAVALIDADE,
   MAX(PROD.codanp) codanp,
   MAX(PROD.descanp_prod) descanp_prod,
   MAX(PROD.ATIVO) ATIVO
FROM
  (
  SELECT DISTINCT
        E.CODAUXILIAR,
        MAX(e.codprod) codproduto,
        MAX(fnc_remove_char_esp(e.descricao)) desccompleta,
        MAX(SUBSTR((fnc_remove_char_esp(e.descricao)),1,24)) descreduzida,
        'N' produtocomposto,
        MAX(e.codprod) seqfamilia,
        0 QTDDIAVALIDADE,
        MAX(nvl(e.anp, 0)) codanp,
        MAX(e.descanp) descanp_prod,
        'S' ATIVO
  FROM  VW_INT_C5_EMBPROD E
  GROUP BY E.CODAUXILIAR
  ) PROD,
  PCDEPARAEMBALAGENSC5 P
WHERE PROD.CODAUXILIAR = P.CODAUXILIAR
GROUP BY P.SEQPRODUTO, PROD.CODAUXILIAR
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODEMPRESA AS
(
  SELECT e.codfilial nroempresa,
         e.codauxiliar idref,
         P.SEQPRODUTO SEQPRODUTO,
         0000000 estqloja,
         'S' ativo
  FROM VW_INT_C5_EMBPROD e,
       PCDEPARAEMBALAGENSC5 P
  WHERE E.CODAUXILIAR = P.CODAUXILIAR

)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODCODIGO AS
(
  SELECT
        e.codfilial nroempresa,
        e.codauxiliar codacesso,
        P.SEQPRODUTO SEQPRODUTO,
        COALESCE(e.qtunit, 1) qtdembalagem,
        (CASE
            WHEN length(e.codauxiliar) = 13 AND NVL(E.PRODSEMCODBARRAS, 'N') = 'N'
                 THEN 'E'
            WHEN length(e.codauxiliar) = 14 AND NVL(E.PRODSEMCODBARRAS, 'N') = 'N'
                 THEN 'D'
            WHEN NVL(E.PRODSEMCODBARRAS, 'N') = 'S' THEN
             'B'
         ELSE
           'B'
         END) tipo,
        'S' ativo
 FROM  VW_INT_C5_EMBPROD e,
       PCDEPARAEMBALAGENSC5 P
 WHERE E.CODAUXILIAR = P.CODAUXILIAR
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMSEGMENTO AS
(SELECT
       e.codprod seqfamilia,
       1 nrosegmento,
       'S' ativo
  FROM  VW_INT_C5_EMBPROD e
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODPRECO AS
(
   --Linha de preço varejo
  SELECT
    E.CODAUXILIAR IDREF,
    P.SEQPRODUTO SEQPRODUTO,
    E.CODFILIAL NROEMPRESA,
    NVL(E.QTUNIT, 1) QTDEMBALAGEM,
    1 NROSEGMENTO,
    'N' PROMOCAO,
    E.PVENDA PRECO,
    'S' ATIVO
  FROM VW_INT_C5_EMBPROD E,
       PCDEPARAEMBALAGENSC5 P
  WHERE E.CODAUXILIAR = P.CODAUXILIAR
  AND   E.QTUNIT <> E.QTMINIMAATACADO

  UNION ALL

  --LINHA DE PREÇO ATACADO
  SELECT
    E.CODAUXILIAR IDREF,
    P.SEQPRODUTO SEQPRODUTO,
    E.CODFILIAL NROEMPRESA,
    NVL(E.QTMINIMAATACADO, 1) QTDEMBALAGEM,
    1 NROSEGMENTO,
    'N' PROMOCAO,
    ROUNDABNT((E.PVENDAATAC / E.QTUNIT) * E.QTMINIMAATACADO, 3) PRECO,
    'S' ATIVO
  FROM VW_INT_C5_EMBPROD E,
       PCDEPARAEMBALAGENSC5 P
  WHERE E.CODAUXILIAR = P.CODAUXILIAR
  AND   E.QTMINIMAATACADO > 1

)
