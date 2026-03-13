begin
  --ajusta notas com aprovadas/ inutilizadas, com especie NE, de janeiro pra cá
  update pcnfsaid
     set especie = 'NF'
   where especie = 'NE'
     and dtsaida >= to_date('01-jan-2026')
     and ((situacaonfe in (100, 150) and protocolonfe is not null and chavenfe is not null) 
      or (situacaonfe in (102, 152) and 
          (select count(*)
              from pcinutilizacaonfe i
             where pcnfsaid.numnota between i.numnotainicial and
                   i.numnotafinal
               and i.serie = pcnfsaid.serie
               and i.codfilial =
                   nvl(pcnfsaid.codfilialnf, pcnfsaid.codfilial)) > 0));
                   
  --ajusta notas com inutilizadas na sefaz, e reenviadas pelo docfiscal que causou a rejeição 206, mudando para inutilizada novamente no sistema                   
  update pcnfsaid
     set especie = 'NF', situacaonfe = 102
   where especie = 'NE'
     and dtsaida >= to_date('01-jan-2026')
     and situacaonfe = 206 
     and (select count(*)
              from pcinutilizacaonfe i
             where pcnfsaid.numnota between i.numnotainicial and
                   i.numnotafinal
               and i.serie = pcnfsaid.serie
               and i.codfilial =
                   nvl(pcnfsaid.codfilialnf, pcnfsaid.codfilial)) > 0;                   
  
  commit;
end;