create or replace trigger TRG_ATU_QT_INTEGRADORA
 after
 DELETE OR UPDATE OF qt
 ON PCPEDI
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

declare
vnnumpedrca             pcpedc.numpedrca%type;
vddtaberturapedpalm     pcpedc.dtaberturapedpalm%type;
vsbrinde                pcpedc.brinde%type;
vsmaquina               varchar2(80);
vsusuario               varchar2(80);
vsprograma              varchar2(80);
vscodfilial             pcpedc.codfilial%type;
vnnumpedrcafv           pcpedifv.numpedrca%type;
vddtaberturapedpalmfv   pcpedifv.dtaberturapedpalm%type;
vncodusurfv             pcpedifv.codusur%type;
vncodprodfv             pcpedifv.codprod%type;
vnnumseqfv              pcpedifv.numseq%type;
vncorte                 number;
vncancitem              number;
vnpossuicorte           varchar2(1);

begin

   VSUSUARIO     := SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30);
   VSPROGRAMA    := f_obternomeaplicacao;
   BEGIN
       -- Na decisao estava dando erro trazendo mais de um registro para a mesma sessao, por isso a
       -- utilização do rownum. Se a alteração for disparada por um usuário com permissão de sysdba
       -- ou for um job cadastrado por este usuário, o USERENV('SESSIONID') deste usuário é null.
       SELECT SUBSTR(terminal,1,80), SUBSTR(osuser,1,80), SUBSTR(program,1,80)
         INTO vsmaquina, vsusuario, vsprograma
         FROM usuarios_logados
        WHERE audsid = USERENV ('SESSIONID')
          AND rownum = 1;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          vsmaquina := SYS_CONTEXT('USERENV','TERMINAL');
          vsusuario := SYS_CONTEXT('USERENV','OS_USER');
          vsprograma := NULL;
    END;


   begin
     select i.numpedrcafv, i.codusurfv, i.dtaberturapedpalmfv,
            i.codprodfv, i.numseqfv
       into vnnumpedrcafv, vncodusurfv, vddtaberturapedpalmfv,
            vncodprodfv, vnnumseqfv
       from pcpedipcpedifv i
      where i.numped  = nvl(:new.numped,  :old.numped)
        and i.codprod = nvl(:new.codprod, :old.codprod)
        and i.numseq  = nvl(:new.numseq,  :old.numseq);
   exception
     when others then
       vnnumpedrcafv         := null;
       vncodusurfv           := null;
       vddtaberturapedpalmfv := null;
       vncodprodfv           := null;
       vnnumseqfv            := null;
   end;

   select count(*) into vncorte
     from pccortei c
   where c.numped  = :old.numped
     and c.codprod = :old.codprod/*
     and c.numseq  = :old.numseq*/;

   select count(*) into vncancitem
     from pcnfcanitem c
   where c.numped  = :old.numped
     and c.codprod = :old.codprod/*
     and c.numseq  = :old.numseq*/;

   if updating then --alterando quantidade

    begin
     select numpedrca,dtaberturapedpalm,nvl(brinde,'N'),codfilial
     into vnnumpedrca,vddtaberturapedpalm,vsbrinde,vscodfilial
     from pcpedc
     where numped = :new.numped;
     exception when no_data_found then
     vnnumpedrca := null;
    end;


    if vnnumpedrca is not null and vnnumpedrca <> 0 and trim(vddtaberturapedpalm) is not null then

     if :new.qt <> :old.qt then


       if vsbrinde = 'N' then --pedido não é brinde


           if :new.brinde = 'S' then --item é brinde

            begin

                update pcretornoitv5fv
                set qt_faturada = (:new.qt/nvl(:new.qtunitemb,1))
                where numpedrca         = vnnumpedrca
                and   dtaberturapedpalm = vddtaberturapedpalm
                and   codusur           = :new.codusur
                and   numpedorigem      = :new.numped
                and   codprod           = :new.codprod
                and   (codauxiliar       = :new.codauxiliar  or codauxiliar is null)
                and  rownum = 1  ;


                exception when no_data_found then
                null;
               end;



           else -- item não é brinde

            begin
                select nvl(corte, 'N')
                into vnpossuicorte
                from pcpedifv
                where numpedrca         = vnnumpedrcafv
                and   dtaberturapedpalm = vddtaberturapedpalmfv
                and   codusur           = vncodusurfv
                and   codprod           = :new.codprod
                and   numseq            = vnnumseqfv
                and   (codauxiliar       = :new.codauxiliar  or codauxiliar is null)
                and  rownum = 1  ;

                if (:new.qt < :old.qt) or vnpossuicorte = 'S'   then
                  vnpossuicorte := 'S';
                else
                  vnpossuicorte := 'N';
                end if;

                update pcpedifv
                set qt_faturada = (:new.qt/nvl(:new.qtunitemb,1)),
                    corte   = vnpossuicorte,
                    observacao_pc = substr(observacao_pc || chr(13) || 'Atualizado em: ' || sysdate
                                                         || chr(13) || 'Programa: '      || vsprograma
                                                         || chr(13) || 'Usuário: '       || vsusuario,1,4000)
                where numpedrca         = vnnumpedrcafv
                and   dtaberturapedpalm = vddtaberturapedpalmfv
                and   codusur           = vncodusurfv
                and   codprod           = :new.codprod
                and   numseq            = vnnumseqfv
                and   (codauxiliar       = :new.codauxiliar  or codauxiliar is null)
                and  rownum = 1  ;




                exception when no_data_found then
                null;
               end;

           end if;

          begin
           update pcpedcfv
            set retorno = 2
            where numpedrca         = vnnumpedrca
            and   dtaberturapedpalm = vddtaberturapedpalm
            and   codusur           = :new.codusur;
           exception when no_data_found then
            null;
           end;

       else

            begin

            update pcretornoitv5fv
            set qt_faturada = (:new.qt/nvl(:new.qtunitemb,1))
            where numpedrca         = vnnumpedrca
            and   dtaberturapedpalm = vddtaberturapedpalm
            and   codusur           = :new.codusur
            and   numpedtv5         = :new.numped
            and   codprod           = :new.codprod
            and   (codauxiliar      = :new.codauxiliar  or codauxiliar is null)
            and  rownum = 1  ;



            exception when no_data_found then
            null;
           end;

          begin
           update pcretornoctv5fv
            set retorno = 2
            where numpedrca         = vnnumpedrca
            and   dtaberturapedpalm = vddtaberturapedpalm
            and   codusur           = :new.codusur
            and   numpedtv5         = :new.numped;
           exception when no_data_found then
            null;
           end;


       end if;


       --se foi feito corte
       if (:new.qt < :old.qt) and
          not(:old.numlote is null     and :new.numlote is not null) and
           not(:old.numlote is not null and :old.numlote <> :new.numlote) then

           --BEGIN
               -- Na decisao estava dando erro trazendo mais de um registro para a mesma sessao, por isso a
               -- utilização do rownum. Se a alteração for disparada por um usuário com permissão de sysdba
               -- ou for um job cadastrado por este usuário, o USERENV('SESSIONID') deste usuário é null.
               --SELECT SUBSTR(terminal,1,80), SUBSTR(osuser,1,80), SUBSTR(program,1,80)
               --  INTO vsmaquina, vsusuario, vsprograma
               --  FROM usuarios_logados
               -- WHERE audsid = USERENV ('SESSIONID')
               --   AND rownum = 1;
            --EXCEPTION
            --   WHEN NO_DATA_FOUND THEN
            --      vsmaquina := SYS_CONTEXT('USERENV','TERMINAL');
            --      vsusuario := SYS_CONTEXT('USERENV','OS_USER');
            --      vsprograma := NULL;
            --END;


           insert into pccortefv
            ( numpedrca,
              numped,
              codusur,
              codcli,
              dtaberturapedpalm,
              codprod,
              codauxiliar,
              numseq,
              qtant ,
              qtcorte,
              dtcorte ,
              codfunccorte,
              programa,
              maquina,
              codfilial,
              codfilialretira )
              values( vnnumpedrca,
                      :new.numped,
                      :new.codusur,
                      :new.codcli,
                      vddtaberturapedpalm,
                      :new.codprod,
                      :new.codauxiliar,
                      :new.numseq,
                      :old.qt,
                      :old.qt - :new.qt,
                      sysdate,
                      vsusuario,
                      vsprograma,
                      vsmaquina,
                      vscodfilial,
                      :new.codfilialretira
                      );


        end if;

      end if;

    end if;


    elsif DELETING and ((nvl(vncorte,0) > 0) or (nvl(vncancitem,0) > 0)) then  --excluindo item

    begin
     select numpedrca,dtaberturapedpalm,nvl(brinde,'N')
     into vnnumpedrca,vddtaberturapedpalm,vsbrinde
     from pcpedc
     where numped = :old.numped;
     exception when no_data_found then
     vnnumpedrca := null;
    end;



    if vnnumpedrca is not null and vnnumpedrca <> 0  and trim(vddtaberturapedpalm) is not null then


      if vsbrinde = 'N' then --pedido não é brinde


        if :new.brinde = 'S' then --item é brinde

            begin

                update pcretornoitv5fv
                set qt_faturada = 0
                where numpedrca         = vnnumpedrca
                and   dtaberturapedpalm = vddtaberturapedpalm
                and   codusur           = :old.codusur
                and   numpedorigem      = :old.numped
                and   codprod           = :old.codprod
                and   (codauxiliar       = :old.codauxiliar  or codauxiliar is null)
                and  rownum = 1  ;
                exception when no_data_found then
                null;
               end;



           else -- item não é brinde

              begin
                update pcpedifv
                set qt_faturada = 0,
                    corte = 'S',
                    observacao_pc = substr(observacao_pc || chr(13) || 'Atualizado em: ' || sysdate
                                                         || chr(13) || 'Programa: '     || vsprograma
                                                         || chr(13) || 'Usuário: '      || vsusuario,1,4000)
                where numpedrca         = vnnumpedrcafv
                and   dtaberturapedpalm = vddtaberturapedpalmfv
                and   codusur           = vncodusurfv
                and   codprod           = :old.codprod
                and   numseq            = vnnumseqfv
                and   (codauxiliar      = :old.codauxiliar  or codauxiliar is null)
                and   rownum = 1    ;


              exception when no_Data_found then
                  null;
              end;

        end if;

          begin
           update pcpedcfv
            set retorno = 2
            where numpedrca         = vnnumpedrca
            and   dtaberturapedpalm = vddtaberturapedpalm
            and   codusur           = :old.codusur;
           exception when no_data_found then
            null;
           end;


     else  --pedido é brinde

          begin
            update pcretornoitv5fv
            set qt_faturada = 0
            where numpedrca         = vnnumpedrca
            and   dtaberturapedpalm = vddtaberturapedpalm
            and   codusur           = :old.codusur
            and   numpedtv5         = :old.numped
            and   codprod           = :old.codprod
            and   (codauxiliar       = :old.codauxiliar  or codauxiliar is null)
            and   rownum = 1    ;
          exception when no_Data_found then
              null;
          end;


          begin
           update pcretornoctv5fv
            set retorno = 2
            where numpedrca         = vnnumpedrca
            and   dtaberturapedpalm = vddtaberturapedpalm
            and   codusur           = :old.codusur
            and   numpedtv5         = :old.numped;
           exception when no_data_found then
            null;
           end;


     end if;




             --   BEGIN
               -- Na decisao estava dando erro trazendo mais de um registro para a mesma sessao, por isso a
               -- utilização do rownum. Se a alteração for disparada por um usuário com permissão de sysdba
               -- ou for um job cadastrado por este usuário, o USERENV('SESSIONID') deste usuário é null.
             --  SELECT SUBSTR(terminal,1,80), SUBSTR(osuser,1,80), SUBSTR(program,1,80)
             --    INTO vsmaquina, vsusuario, vsprograma
             --    FROM usuarios_logados
             --   WHERE audsid = USERENV ('SESSIONID')
             --     AND rownum = 1;
            --EXCEPTION
            --   WHEN NO_DATA_FOUND THEN
           --       vsmaquina := SYS_CONTEXT('USERENV','TERMINAL');
           --       vsusuario := SYS_CONTEXT('USERENV','OS_USER');
           --       vsprograma := NULL;
           -- END;

           if :old.corte = 'S' then
             insert into pccortefv
              ( numpedrca,
                numped,
                codusur,
                codcli,
                dtaberturapedpalm,
                codprod,
                codauxiliar,
                numseq,
                qtant ,
                qtcorte,
                dtcorte ,
                codfunccorte,
                programa,
                maquina,
                codfilial,
                codfilialretira )
                values( vnnumpedrca,
                        :old.numped,
                        :old.codusur,
                        :old.codcli,
                        vddtaberturapedpalm,
                        :old.codprod,
                        :old.codauxiliar,
                        :old.numseq,
                        :old.qt,
                        :old.qt,
                        sysdate,
                        vsusuario,
                        vsprograma,
                        vsmaquina,
                        vscodfilial,
                        :old.codfilialretira
                        );
           end if;

    end if;

  end if;

  if DELETING and (vnnumpedrcafv is not null)  then  --excluindo item

    delete from pcpedipcpedifv i
     where i.numped              = :old.numped
       and i.codprod             = :old.codprod
       and i.numseq              = :old.numseq;

  end if;

end TRG_ATU_QT_INTEGRADORA;