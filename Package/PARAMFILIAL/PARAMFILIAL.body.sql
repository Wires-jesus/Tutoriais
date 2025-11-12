CREATE OR REPLACE PACKAGE BODY PARAMFILIAL
IS
   PROCEDURE CHECKTIPODADOS(nomeParam in varchar2, tipoEsperadoPorExtenso in varchar2)
   is
      tipoLido pcmetaparamfilial.TIPODADOS%TYPE;
      tipoLidoPorExtenso varchar2(12);
      erroDeTipos char(1);
   begin
      begin
         erroDeTipos := 'N';

         select TIPODADOS into tipoLido
         from PCMETAPARAMFILIAL
         where nome = nomeParam;

         if upper(tipoEsperadoPorExtenso) = 'NUMBER' then
            if tipoLido = 'N' then
               return;
            end if;

            erroDeTipos := 'S';
         end if;

         if upper(tipoEsperadoPorExtenso) = 'DATE' then
            if tipoLido in ('D', 'H', 'T') then
               return;
            else
               erroDeTipos := 'S';
            end if;
         end if;

         if upper(tipoEsperadoPorExtenso) = 'BOOLEAN' then
            if tipoLido in ('B', 'A') then
               return;
            else
               erroDeTipos := 'S';
            end if;
         end if;

         if erroDeTipos = 'S' then
            select decode(tipoLido,
               'N', 'Número (N)',
               'D', 'Data (D)',
               'H', 'Hora (H)',
               'T', 'Data e hora (T)',
               'A', 'Texto (A)',
               'B', 'Boolean (B)')
               into tipoLidoPorExtenso
            from dual;
            RAISE_APPLICATION_ERROR(-20101, 'O parâmetro "' || nomeParam || '" não pode ser obtido como "' ||
               tipoEsperadoPorExtenso || '", pois seu tipo é "' || tipoLidoPorExtenso || '".');
         end if;
      exception
         WHEN NO_DATA_FOUND
         THEN
            RAISE_APPLICATION_ERROR(-20100, 'O parâmetro "' || nomeParam || '" não existe.');
         WHEN OTHERS
         THEN
            raise;
      end;
   end;
   PROCEDURE CheckParamExiste(nomeParam in varchar2)
   is
      contador int;
   begin
      select count(*) into contador
      from PCMETAPARAMFILIAL
      where nome = nomeParam;
      if contador = 0 then
         RAISE_APPLICATION_ERROR(-20102, 'O parâmetro "' || nomeParam || '" não existe na tabela PCParamFilial.');
      end if;
   end;
   FUNCTION ObterComoVarchar2(nomeParam in varchar2, pCodFilial in varchar2) return varchar2
   is
      retorno pcparamfilial.valor%TYPE;
   begin
      CheckParamExiste(nomeParam);
      select valor into retorno
      from pcparamfilial
      where nome = nomeParam and codfilial = pCodfilial;
      return retorno;
   end;
   FUNCTION ObterComoVarchar2(nomeParam in varchar2) return varchar2
   is
   begin
      return ObterComoVarchar2(nomeParam, '99');
   end;
   FUNCTION ObterComoBoolean(nomeParam in varchar2, codFilial in varchar2, valorTrue in varchar2,
      valorFalse in varchar2) return varchar2
   is
      valorParam pcparamfilial.valor%TYPE;
   begin
      CHECKTIPODADOS(nomeParam, 'Boolean');
      valorParam := ObterComoVarchar2(nomeParam, codFilial);
      if valorParam is null then
         return null;
      else
        if valorParam = 'S' then
           return valorTrue;
        else
           return valorFalse;
        end if;
      end if;
   end;
   FUNCTION ObterComoBoolean(nomeParam in varchar2, codFilial in varchar2) return varchar2
   is
      valorParam pcparamfilial.valor%TYPE;
   begin
      CHECKTIPODADOS(nomeParam, 'Boolean');
      valorParam := ObterComoVarchar2(nomeParam, codFilial);
      if valorParam is null then
         return null;
      else
        return valorParam;
      end if;
   end;
   FUNCTION ObterComoBoolean(nomeParam in varchar2) return varchar2
   is
   begin
      return ObterComoBoolean(nomeParam, '99');
   end;
   FUNCTION ObterComoDate(nomeParam in varchar2, codFilial in varchar2) return date
   is
      valorParam pcparamfilial.valor%TYPE;
   begin
      CHECKTIPODADOS(nomeParam, 'Date');

      valorParam := ObterComoVarchar2(nomeParam, codFilial);
      return TO_DATE(valorParam, 'DD/MM/YYYY HH24:MI:SS');
   end;
   FUNCTION ObterComoDate(nomeParam in varchar2) return date
   is
   begin
      return ObterComoDate(nomeParam, '99');
   end;
  FUNCTION ObterComoNumber(nomeParam in varchar2, codFilial in varchar2) return number
  is
     valorParam pcparamfilial.valor%TYPE;
     nls_chars varchar2(3);
  begin
     CHECKTIPODADOS(nomeParam, 'Number');
     valorParam := ObterComoVarchar2(nomeParam, codFilial);
     
     select value into nls_chars
     from nls_session_parameters
     where parameter = 'NLS_NUMERIC_CHARACTERS';

     if nls_chars = ',.' then
        return to_number(trim(replace(valorParam, '.', ',')));
     ELSE
        return to_number(trim(replace(valorParam, ',', '.')));
     end if;
  end;
   FUNCTION ObterComoNumber(nomeParam in varchar2) return number
   is
   begin
      return ObterComoNumber(nomeParam, '99');
   end;
   
   FUNCTION ParametroExiste(nomeParam in varchar2) return boolean
   is retorno pcparamfilial.valor%TYPE;
   begin
      begin
        select valor 
          into retorno
          from pcparamfilial
         where nome = nomeParam 
           and codfilial = '99';
        
        if retorno is not null then
          return true; 
        end if;       
        
      exception    
        when no_data_found then
          return false;
      end;      
   end;   
   
   FUNCTION ParametroExiste(nomeParam in varchar2, pCodFilial in varchar2) return boolean  
   is retorno pcparamfilial.valor%TYPE;
   begin
      begin
        select valor 
          into retorno
          from pcparamfilial
         where nome = nomeParam 
           and codfilial = pCodFilial;
        
        if retorno is not null then
          return true; 
        end if;
       
      exception    
        when no_data_found then
          return false;
      end; 
   end;      
end;