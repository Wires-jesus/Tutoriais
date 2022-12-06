CREATE OR REPLACE TRIGGER TRG_ATU_POSICAO_INTEGRADORA
 AFTER
 DELETE OR UPDATE OF POSICAO
 ON PCPEDC
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW



declare
  vsposicao varchar2(1);
  vnnumped  pcpedc.numped%type;
  vnnumpedrca pcpedc.numpedrca%type;
  vncondvenda pcpedc.condvenda%type;

begin

  if updating --alterando pedido
  then
    if :new.numpedrca is not null and :new.numpedrca <> 0
    then

      if :new.posicao <> :old.posicao
      then

       if :new.condvenda = 14 then

             begin
              update pcpedcfvmanif
                 set posicao_atual = :new.posicao,
                     retorno       = 2
               where numpedrca in (:new.numpedrca, :new.numorca)
               and   numped    = :new.numped
               and   codusur   = :new.codusur ;
               exception when no_data_found then
                null;
               end;
        else
        if nvl(:new.brinde,'N') = 'N' then --pedido não é brinde

             begin
              update pcpedcfv
                 set posicao_atual = :new.posicao,
                     retorno       = 2
               where numpedrca in (:new.numpedrca, :new.numorca)
               and   numped    = :new.numped
               and   codusur   = :new.codusur
               and   dtaberturapedpalm = :new.dtaberturapedpalm;
               exception when no_data_found then
                null;
               end;

          else --pedido de brinde

             begin
              update pcretornoctv5fv
                 set posicao_atual = :new.posicao,
                     retorno       = 2
               where numpedrca    = :new.numpedrca
               and   numpedtv5    = :new.numped
               and   codusur      = :new.codusur
               and   dtaberturapedpalm = :new.dtaberturapedpalm;
             exception when no_data_found then
            null;
           end;

         end if;
        end if;
      end if;
    end if;

  else --excluindo pedido

    if :old.numpedrca is not null and :old.numpedrca <> 0
    then
        if :new.condvenda = 14 then

             begin
              update pcpedcfvmanif
                 set posicao_atual = 'C',
                     retorno       = 2
               where numpedrca in (:old.numpedrca, :old.numorca)
               and   numped    = :old.numped
               and   codusur   = :old.codusur ;
               exception when no_data_found then
                null;
               end;

       else
       if nvl(:new.brinde,'N') = 'N' then --pedido não é brinde

            begin
              update pcpedcfv
                 set posicao_atual = 'C',
                     retorno       = 2
               where numpedrca in (:old.numpedrca, :old.numorca)
               and   numped    = :old.numped
               and   codusur   = :old.codusur
               and   dtaberturapedpalm = :old.dtaberturapedpalm;
               exception when no_data_found then
                  null;
              end;

       else --pedido é brinde

        begin
        update pcretornoctv5fv
           set posicao_atual = 'C',
               retorno       = 2
         where numpedrca    = :old.numpedrca
         and   numpedtv5    = :old.numped
         and   codusur      = :old.codusur
         and   dtaberturapedpalm = :old.dtaberturapedpalm;
          exception when no_data_found then
            null;
         end;

       end if;
      end if;
    end if;

  end if;

end TRG_ATU_POSICAO_INTEGRADORA;
/
