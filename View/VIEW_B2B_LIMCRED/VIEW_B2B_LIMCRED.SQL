CREATE OR REPLACE VIEW view_b2b_limcred (
   customerdocumentnr,
   value,
   filaid )
AS
select c.cgcent customerDocumentNr,
       funcoesvendas.buscarlimcredcli(c.codcli, NULL, 'D', 'S') value,
       f.rowid filaid
  from pcclient c, pcecommerceb2bfila f
  where c.rowid = f.id
   and f.tabela = 'LIMITE'
