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
(SELECT
       fb.seqfamilia,
       fb.qtdembalagem,
       'N' pesoaferido,
       'S' ativo,

       (select nvl(emb.unidade, '1') from pcembalagem emb
        where emb.codprod = fb.seqfamilia and emb.qtunit = fb.qtdembalagem and emb.codauxiliar = fb.codauxreferencia and rownum = 1) embalagem,

       (select nvl(emb.pesobruto,0) from pcembalagem emb
        where emb.codprod = fb.seqfamilia and emb.qtunit = fb.qtdembalagem and emb.codauxiliar = fb.codauxreferencia and rownum = 1) pesobruto,

       (select nvl(emb.pesoliq, 0) from pcembalagem emb
        where emb.codprod = fb.seqfamilia and emb.qtunit = fb.qtdembalagem and emb.codauxiliar = fb.codauxreferencia and rownum = 1)  pesoliq
FROM

     (SELECT
        EMB.qtdecodigobarras,
        EMB.seqfamilia,
        EMB.qtdembalagem,
        (select s.codauxiliar from pcembalagem s where s.codprod = EMB.seqfamilia and s.qtunit = NVL(EMB.qtdembalagem, 1) and rownum = 1) codauxreferencia
      FROM
         (select
            count(e.codauxiliar) qtdecodigobarras,
            e.codprod seqfamilia,
            NVL(e.qtunit, 1) qtdembalagem
          from VW_INT_C5_EMBPROD e
          group by e.codprod, NVL(e.qtunit, 1)
          ) EMB
     )fb
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO AS
(
SELECT
        e.codauxiliar||e.codfilial seqproduto,
        e.codprod codproduto,
        fnc_remove_char_esp(e.descricao) desccompleta,
        SUBSTR((fnc_remove_char_esp(e.descricao)),1,24) descreduzida,
        'N' produtocomposto,
        e.codprod seqfamilia,
        0 QTDDIAVALIDADE,
        e.anp codanp,
        e.descanp descanp_prod,
        'S' ativo
  FROM  VW_INT_C5_EMBPROD e 
  )

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODEMPRESA AS
(
SELECT e.codfilial nroempresa,
       e.codauxiliar||e.codfilial seqproduto,
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
        e.codauxiliar||e.codfilial seqproduto,
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
SELECT
  e.codauxiliar||e.codfilial seqproduto,
  e.codfilial nroempresa,
  NVL(e.qtunit, 1) qtdembalagem,
  1 nrosegmento,
  'N' promocao,
  e.pvenda preco,
  'S' ativo
FROM VW_INT_C5_EMBPROD e
)
