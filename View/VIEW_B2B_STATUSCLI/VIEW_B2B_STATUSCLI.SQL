CREATE OR REPLACE VIEW VIEW_B2B_STATUSCLI AS
select c.cgcent customerDocumentNr,
       e.situacaoecommerceb2b status,
       f.rowid filaid
  from pcclient c, pcecommerceb2bfila f, PCECOMMERCEB2BCLIENTE e
 where c.rowid = f.id
   and e.codcli = c.codcli
   and f.tabela = 'CLIENTE';

 
