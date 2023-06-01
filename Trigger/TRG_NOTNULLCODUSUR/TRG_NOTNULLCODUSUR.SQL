create or replace trigger trg_notnullcodusur
  before insert or update on pcpedifvmanif  
  for each row
declare
  -- local variables here
begin
  if (inserting and :new.codusur is null)
  or (updating  and :new.codusur is null and :old.codusur is not null) then
    raise_application_error(-20000, 'O campo CODUSUR na tabela PCPEDIFVMANIF, não pode ser nulo');
  end if;
end trg_notnullcodusur;
