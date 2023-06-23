CREATE OR REPLACE VIEW VW_INT_C5_EMPRESA AS
(
  select  e.seqproduto,
        e.nroempresa,
        e.nrosegmento,
        e.qtdembalagem,
        e.promocao,
        1 preco,
        e.ativo,
        e.dtultalter_prod,
        e.dtcadastro_prod,
        e.dtcadastroemb,
        e.dtulalterintegra,
        e.dtultaltpvenda,
        e.codauxiliar
  FROM (SELECT
         e.codauxiliar || e.codfilial seqproduto,
         e.codfilial nroempresa,
         NVL(e.qtunit,1) qtdembalagem,
         1 nrosegmento,
         'N' promocao,
         e.codauxiliar,
         'S' ativo,
         e.dtultalter_prod,
         e.dtcadastro_prod,
         e.dtcadastro dtcadastroemb,
         e.dtulalterintegra,
         e.dtultaltpvenda
          FROM VW_INT_C5_EMBPROD e 
         ) e
)

