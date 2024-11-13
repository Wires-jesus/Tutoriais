begin
  for mdfes in (select pcmanifestoeletronicoc.numtransacao,
                       protocolomdfe,
                       to_char(substr(xmlmdfe,
                                      instr(xmlmdfe, '<nProt>') + 7,
                                      15)) as protocolo_xml
                  from pcmanifestoeletronicoc, pcdoceletronico
                 where pcmanifestoeletronicoc.numtransacao =
                       pcdoceletronico.numtransacao
                   and pcmanifestoeletronicoc.situacaomdfe = 100
                   and pcmanifestoeletronicoc.protocolomdfe is null
                   and pcmanifestoeletronicoc.chavemdfe is not null
                   and pcdoceletronico.movimento = 'M'
                   and pcdoceletronico.xmlmdfe is not null
                   and trunc(pcmanifestoeletronicoc.datahorageracao) >= to_date('30-jun-2024') ) loop
  
    update pcmanifestoeletronicoc
       set protocolomdfe = mdfes.protocolo_xml
     where numtransacao = mdfes.numtransacao
       and protocolomdfe is null;
  
  end loop;
end;
