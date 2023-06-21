CREATE OR REPLACE VIEW VW_INT_C5_FAMILIA AS
(
  SELECT DISTINCT
         p.codprod seqfamilia,
         NVL(fnc_remove_char_esp(substr(p.descricao,0,39)), '-') familia,
         /*p.nbm codnbmsh,*/
         p.codncmsh,
         p.aceitavendafracao permitedecimal,
         p.permitemultiplicacao,
         0 codcest,
         'S' ativo,
         p.codmarca seqmarca,
         1 seqfamgrupo,
         p.pesovariavel PESAVEL
  FROM VW_INT_C5_EMBPROD p 
  )

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMEMBALAGEM AS
(SELECT
       /*APOS AGRUPAR AS EMBALAGENS NA TABELA TEMPORARIA "FB" DA CLAUSULA "FROM",
         É PRECISO BUSCAR MAIS ALGUMAS INFORMAÇÕES ATRAVES DOS SUBSELECTS CONTIDOS
         NESSE SELECT*/
       fb.seqfamilia,
       fb.qtdembalagem,
       'N' pesoaferido,
       'S' ativo,

       (select nvl(emb.unidade, '1') from local.pcembalagem emb
        where emb.codprod = fb.seqfamilia and emb.qtunit = fb.qtdembalagem and emb.codauxiliar = fb.codauxreferencia and rownum = 1) embalagem,

       (select nvl(emb.pesobruto,0) from local.pcembalagem emb
        where emb.codprod = fb.seqfamilia and emb.qtunit = fb.qtdembalagem and emb.codauxiliar = fb.codauxreferencia and rownum = 1) pesobruto,

       (select nvl(emb.pesoliq, 0) from local.pcembalagem emb
        where emb.codprod = fb.seqfamilia and emb.qtunit = fb.qtdembalagem and emb.codauxiliar = fb.codauxreferencia and rownum = 1) pesoliq
FROM
     /*O SELECT ABAIXO TRANSFORMA A REGRA NEGOCIAL DO WINTHOR PARA ATENDER A REGRA NEGOCIAL DA CONSINCO,
       AGRUPANDO AS EMBALAGENS COM O MESMO QTUNIT.

       A TABELA TB_FAMEMBALAGEM ESPERA RECEBER APENAS 1 EMBALAGEM POR QTUNIT
       INDPENDENTE DA FILIAL, POR ISSO É NECESSÁRIO AGRUPAR AS MESMAS PARA ENVIAR APENAS 1
       POR QTUNIT PARA A TB_FAMEMBALAGEM
       EX.:
          - WINTHOR: A COCA-COLA POSSUI 3 EMBALAGENS COM QTUNIT IGUAL A 1 E 2 COM QTUNIT IGUAL A 6;
          - CONSINCO: A FAMEMBALAGEM VAI RECEBER APENAS 1 EMBALAGEM COM QTUNIT IGUAL A 1 E 1 COM QTUNIT IGUAL A 6;

          *SEMPRE 1 DE CADA QTUNIT, INDEPENDENTE SE ESTA REPETINDO POR FILIAL NA PCEMBALAGEM*/

     (SELECT
            count(e.codauxiliar) qtdecodigobarras,
            e.codprod seqfamilia,
            NVL(e.qtunit, 1) qtdembalagem,
            (select emb.codauxiliar from local.pcembalagem emb where emb.codprod = e.codprod and emb.qtunit = NVL(e.qtunit, 1) and rownum = 1) codauxreferencia
      FROM VW_INT_C5_EMBPROD e
      group by  e.codprod, NVL(e.qtunit, 1)
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







