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
         p.codncmsh,
         p.aceitavendafracao permitedecimal,
         p.permitemultiplicacao,
         nvl(p.codcest, 0) codcest,
         'S' ativo,
         p.codmarca seqmarca,
         1 seqfamgrupo,
         p.pesovariavel PESAVEL
  FROM VW_INT_C5_EMBPROD p 
  )

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMEMBALAGEM AS
(
  SELECT
    SEQFAMILIA,
    max(QTDEMBALAGEM)QTDEMBALAGEM,
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
  group by SEQFAMILIA
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO AS
(
 SELECT DISTINCT
   PROD.SEQPRODUTO,
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
  SELECT  distinct
        e.codauxiliar seqproduto,
        MAX(e.codprod) codproduto,
        max(fnc_remove_char_esp(e.descricao)) desccompleta,
        max(SUBSTR((fnc_remove_char_esp(e.descricao)),1,24)) descreduzida,
        'N' produtocomposto,
        MAX(e.codprod) seqfamilia,
        0 QTDDIAVALIDADE,
        max(nvl(e.anp, 0)) codanp,
        max(e.descanp) descanp_prod,
        'S' ativo
  FROM  VW_INT_C5_EMBPROD e
  GROUP BY e.codauxiliar
  ) PROD
  GROUP BY PROD.SEQPRODUTO
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODEMPRESA AS
(
  SELECT e.codfilial nroempresa,
         e.codauxiliar seqproduto,
         0000000 estqloja,
         'S' ativo
  FROM VW_INT_C5_EMBPROD e

)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODCODIGO AS
(
  SELECT
        e.codfilial nroempresa,
        e.codauxiliar codacesso,
        e.codauxiliar seqproduto,
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
 FROM  VW_INT_C5_EMBPROD e
 WHERE length(E.CODAUXILIAR) <= 14
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
  codauxiliar seqproduto,
  codfilial nroempresa,
  NVL(qtunit, 1) qtdembalagem,
  1 nrosegmento,
  'N' promocao,
  pvenda preco,
  'S' ativo
FROM VW_INT_C5_EMBPROD
where
  qtunit <> qtminimaatacado

UNION ALL

--Linha de preço atacado
SELECT
  codauxiliar seqproduto,
  codfilial nroempresa,
  NVL(qtminimaatacado, 1) qtdembalagem,
  1 nrosegmento,
  'N' promocao,
  pvendaatac preco,
  'S' ativo
FROM VW_INT_C5_EMBPROD
where
  qtminimaatacado > 1
)
