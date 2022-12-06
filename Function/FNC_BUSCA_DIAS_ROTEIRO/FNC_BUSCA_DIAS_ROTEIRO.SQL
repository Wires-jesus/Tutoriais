create or replace function fnc_busca_dias_roteiro(p_mes          in number,
                                                   p_ano          in number,
                                                   p_semana       in number,
                                                   p_tipo         in varchar2
) return date is

  vddatainicio_1 date;
  vddatainicio_2 date;
  vddatainicio_3 date;
  vddatainicio_4 date;
  vddatainicio_5 date;
  vddatafim_1 date;
  vddatafim_2 date;
  vddatafim_3 date;
  vddatafim_4 date;
  vddatafim_5 date;

  p_datainicio_1 date;
  p_datainicio_2 date;
  p_datainicio_3 date;
  p_datainicio_4 date;
  p_datainicio_5 date;
  p_datafim_1 date;
  p_datafim_2 date;
  p_datafim_3 date;
  p_datafim_4 date;
  p_datafim_5 date;


  vddataaux      date;
  vsdiautil      varchar2(1);

begin
/*
--ESQUEMA PARA ACHAR ERRO NAS DATAS FOI MUITO UTIL DEIXEI O CÃ“DIGO AQUI
create table teste_dias_roteiro(data date, texto varchar2(400)) tablespace ts_dados;
select * from teste_dias_roteiro;
-- delete teste_dias_roteiro;

begin
 GRAVARLOG_dias_roteiro('teste');
end;

create or replace PROCEDURE GRAVARLOG_dias_roteiro(texto varchar2)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

    insert into teste_dias_roteiro (data, texto) values(sysdate, texto);
    commit;
  END;

*/

  --semana 1
begin

  -- inicio
  if (p_mes is not null) and (p_ano is not null) then
  select last_day(add_months(to_date(to_char(p_mes)||'/'||to_char(p_ano),'mm/yyyy'),-1))+1
    into vddatainicio_1
    from dual;

  select pcdatas.diautil
    into vsdiautil
    from pcdatas
   where pcdatas.data = vddatainicio_1;

  if vsdiautil = 'S' or
     trim(to_char(vddatainicio_1, 'DAY')) in ('SATURDAY', 'SUNDAY', 'SÃBADO', 'DOMINGO' ) then

    p_datainicio_1 := vddatainicio_1;

  else

    while p_datainicio_1 is null loop

      if vsdiautil = 'S' or
         trim(to_char(vddatainicio_1, 'DAY')) in ('SATURDAY', 'SUNDAY', 'SÃBADO', 'DOMINGO') then

        p_datainicio_1 := vddatainicio_1;
      else

        vddatainicio_1 := vddatainicio_1 + 1;

        select pcdatas.diautil
          into vsdiautil
          from pcdatas
         where pcdatas.data = vddatainicio_1;
      end if;

    end loop;

  end if;



--fim
begin
  select last_day(add_months(to_date(to_char(p_mes)||'/'||to_char(p_ano),'mm/yyyy'),-1))+1
    into vddatafim_1
    from dual;


  --GRAVARLOG_dias_roteiro('vddataaux: ' || vddataaux || ' - vddatafim_1: ' || vddatafim_1);
  vddataaux := vddatafim_1;

  while trim(to_char(vddataaux, 'DAY')) <> 'SUNDAY' and trim(to_char(vddataaux, 'DAY')) <> 'DOMINGO' loop

    vddataaux := vddataaux + 1;
    --GRAVARLOG_dias_roteiro('vddataaux: ' || vddataaux || ' - vddatafim_1: ' || vddatafim_1 || ' DAY :' || to_char(vddataaux, 'DAY'));

  end loop;

  vddatafim_1 := vddataaux;
  p_datafim_1 := vddatafim_1;

exception

when others then
   null;
end;


  --semana 2


  --inicio
  vddatainicio_2 := vddatainicio_1 + 1;
  vddataaux := vddatainicio_2;

  while trim(to_char(vddataaux, 'DAY')) <> 'MONDAY' and trim(to_char(vddataaux, 'DAY')) <> 'SEGUNDA-FEIRA' loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatainicio_2 := vddataaux;

  select pcdatas.diautil
    into vsdiautil
    from pcdatas
   where pcdatas.data = vddatainicio_2;

  if vsdiautil = 'S' or
     trim(to_char(vddatainicio_2, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

    p_datainicio_2 := vddatainicio_2;

  else

    while p_datainicio_2 is  null loop

      if vsdiautil = 'S' or
         trim(to_char(vddatainicio_2, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

        p_datainicio_2 := vddatainicio_2;
      else

        vddatainicio_2 := vddatainicio_2 + 1;

        select pcdatas.diautil
          into vsdiautil
          from pcdatas
         where pcdatas.data = vddatainicio_2;
      end if;

    end loop;

  end if;

  -- fim
  vddataaux := vddatainicio_2;

  while trim(to_char(vddataaux, 'DAY')) <> 'SUNDAY' and trim(to_char(vddataaux, 'DAY')) <> 'DOMINGO' loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatafim_2 := vddataaux;
  p_datafim_2 := vddatafim_2;



  --semana 3

  --inicio
  vddatainicio_3 := vddatainicio_2 + 1;

  vddataaux := vddatainicio_3;

  while trim(to_char(vddataaux, 'DAY')) <> 'MONDAY' and trim(to_char(vddataaux, 'DAY')) <> 'SEGUNDA-FEIRA'  loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatainicio_3 := vddataaux;

  select pcdatas.diautil
    into vsdiautil
    from pcdatas
   where pcdatas.data = vddatainicio_3;

  if vsdiautil = 'S' or
     trim(to_char(vddatainicio_3, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

    p_datainicio_3 := vddatainicio_3;

  else

    while p_datainicio_3 is  null loop

      if vsdiautil = 'S' or
         trim(to_char(vddatainicio_3, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

        p_datainicio_3 := vddatainicio_3;
      else

        vddatainicio_3 := vddatainicio_3 + 1;

        select pcdatas.diautil
          into vsdiautil
          from pcdatas
         where pcdatas.data = vddatainicio_3;
      end if;

    end loop;

  end if;

 --fim
  vddataaux := vddatainicio_3;

  while trim(to_char(vddataaux, 'DAY')) <> 'SUNDAY' and trim(to_char(vddataaux, 'DAY')) <> 'DOMINGO' loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatafim_3 := vddataaux;
  p_datafim_3 := vddatafim_3;


  -- semana 4

 --inicio
  vddatainicio_4 := vddatainicio_3 + 1;

  vddataaux := vddatainicio_4;

  while trim(to_char(vddataaux, 'DAY')) <> 'MONDAY' and trim(to_char(vddataaux, 'DAY')) <> 'SEGUNDA-FEIRA' loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatainicio_4 := vddataaux;

  select pcdatas.diautil
    into vsdiautil
    from pcdatas
   where pcdatas.data = vddatainicio_4;

  if vsdiautil = 'S' or
     trim(to_char(vddatainicio_4, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

    p_datainicio_4 := vddatainicio_4;

  else

    while p_datainicio_4 is  null loop

      if vsdiautil = 'S' or
         trim(to_char(vddatainicio_4, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

        p_datainicio_4 := vddatainicio_4;
      else

        vddatainicio_4 := vddatainicio_4 + 1;

        select pcdatas.diautil
          into vsdiautil
          from pcdatas
         where pcdatas.data = vddatainicio_4;
      end if;

    end loop;

  end if;

--fim
  vddataaux := vddatainicio_4;

  while trim(to_char(vddataaux, 'DAY')) <> 'SUNDAY' and trim(to_char(vddataaux, 'DAY')) <> 'DOMINGO' loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatafim_4 := vddataaux;

  p_datafim_4 := vddatafim_4;



  -- semana 5

  --inicio
  vddatainicio_5 := vddatainicio_4 + 1;

  vddataaux := vddatainicio_5;

  while trim(to_char(vddataaux, 'DAY')) <> 'MONDAY' and trim(to_char(vddataaux, 'DAY')) <> 'SEGUNDA-FEIRA' loop

    vddataaux := vddataaux + 1;

  end loop;

  vddatainicio_5 := vddataaux;

  select pcdatas.diautil
    into vsdiautil
    from pcdatas
   where pcdatas.data = vddatainicio_5;

  if vsdiautil = 'S' or
     trim(to_char(vddatainicio_5, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

    p_datainicio_5 := vddatainicio_5;

  else

    while p_datainicio_5 is null loop

      if vsdiautil = 'S' or
         trim(to_char(vddatainicio_5, 'DAY')) in ('SATURDAY', 'SUNDAY','SÃBADO','DOMINGO') then

        p_datainicio_5 := vddatainicio_5;
      else

        vddatainicio_5 := vddatainicio_5 + 1;

        select pcdatas.diautil
          into vsdiautil
          from pcdatas
         where pcdatas.data = vddatainicio_5;
      end if;

    end loop;

  end if;

  --fim
    select last_day(to_date('01/' || to_char(p_mes) || '/' ||
                          to_char(p_ano),
                          'dd/mm/yyyy'))
    into vddatafim_5
    from dual;

  p_datafim_5 := vddatafim_5;


   if p_semana = 1 then
      if p_tipo = 'I' then
         return  p_datainicio_1;
      elsif p_tipo = 'F' then
         return  p_datafim_1;
      end if;

   elsif p_semana = 2 then
         if p_tipo = 'I' then
         return  p_datainicio_2;
      elsif p_tipo = 'F' then
         return  p_datafim_2;
      end if;

   elsif p_semana = 3 then
      if p_tipo = 'I' then
         return  p_datainicio_3;
      elsif p_tipo = 'F' then
         return  p_datafim_3;
      end if;

   elsif p_semana = 4 then
      if p_tipo = 'I' then
         return  p_datainicio_4;
      elsif p_tipo = 'F' then
         return  p_datafim_4;
      end if;

   elsif p_semana = 5 then
      if p_tipo = 'I' then
         return  p_datainicio_5;
      elsif p_tipo = 'F' then
         return  p_datafim_5;
      end if;

   end if;
else
  return '';
end if;

exception

when no_data_found then
   null;
end;

end;
/
