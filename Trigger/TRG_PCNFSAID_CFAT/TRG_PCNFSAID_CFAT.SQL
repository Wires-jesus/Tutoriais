CREATE OR REPLACE TRIGGER TRG_PCNFSAID_CFAT
  BEFORE INSERT ON PCNFSAID
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
DECLARE
  vsprograma  varchar2(2000);
  vssucesso   varchar2(200);
  vsparametro varchar2(100);
  vsmaior     varchar2(10);
  vsmenor     varchar2(10);
  vsContItem  number(22, 0);

  PROCEDURE GRAVARLOG(pNUMTRANSVENDA NUMBER,
                      pSucesso       varchar2,
                      pObservacao    varchar2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    insert into PCLOGALTERACAODADOS
      (data, tabela, coluna, VALORALFA, observacoes, observacoes2)
    values
      (sysdate,
       'PCNFSAID',
       'NUMTRANSVENDA',
       to_char(pNUMTRANSVENDA),
       ' Sucesso: ' || pSucesso,
       pObservacao);
    commit;
  END;

BEGIN

  VSPROGRAMA := UPPER(SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48));

  select PARAMFILIAL.ObterComoVarchar2('UTILIZACENTRALFATURAMENTO')
    into vsparametro
    from dual;

  vssucesso := 'S';

  vsContItem := 0;
  
  begin
    select count(1)
      into vsContItem
      from pcmov m
     where m.numtransvenda = :NEW.NUMTRANSVENDA
       and m.codoper in ('S', 'ST');
    EXCEPTION
      WHEN OTHERS THEN
      vsContItem := 0;
  end;

  if (vsparametro = 'S') 
    and (VSPROGRAMA <> upper('WinThorAnywhere'))
	and (vsContItem > 0)
	and (VSPROGRAMA not like '%2030%')
	and (VSPROGRAMA not like '%1124%')
    and (VSPROGRAMA not like '%1306%')
    and (VSPROGRAMA not like '%1446%')	
	and (VSPROGRAMA not like upper('%AutoServico.Faturamento%'))
	then
  
    begin
		vsprograma := SUBSTR(TRIM(SUBSTR(vsprograma,
										 INSTR(vsprograma, '-') + 1,
										 length(vsprograma))),
							 1,
							 200);
		vsmaior    := SUBSTR(TRIM(SUBSTR(vsprograma,
										 1,
										 INSTR(vsprograma, '.') - 1)),
							 1,
							 10);
		vsmenor    := SUBSTR(TRIM(SUBSTR(vsprograma,
										 INSTR(vsprograma, '.') + 1,
										 length(vsprograma) -
										 (INSTR(vsprograma, '.', 1, 2) +
										  INSTR(vsprograma, '.')) - 1)),
							 1,
							 10);
	  
		vssucesso := 'N';
		if (to_number(vsmaior) > 29) then
		  vssucesso := 'S';
		elsif (to_number(vsmaior) = 29) then
		  if (to_number(vsmenor) > 2) then
			vssucesso := 'S';
		  end if;
		end if;
	  
		GRAVARLOG(:NEW.NUMTRANSVENDA,
				  vssucesso,
				  'Validação CFAT Maior: ' || vsmaior || ' - Menor: ' ||
				  vsmenor || ' Programa: ' || vsprograma || ' Parametro: ' ||
				  vsparametro);
		if (vssucesso = 'N') then
		  raise_application_error(-20000,'Parâmetro "UTILIZACENTRALFATURAMENTO" está marcado como "Sim", operações de faturamento e transferência devem ser realizadas via rotina 1420!');
		end if;
	
	  EXCEPTION
		  WHEN OTHERS THEN
		  GRAVARLOG(:NEW.NUMTRANSVENDA,
              'Falhou a verificação da versão',
              'Validação CFAT Programa: ' || vsprograma || ' Parametro: ' ||
              vsparametro);
		  raise_application_error(-20000,'Parâmetro "UTILIZACENTRALFATURAMENTO" está marcado como "Sim", falhou a verificação da versão do programa ' || vsprograma || '!');
	  end;
  else
    GRAVARLOG(:NEW.NUMTRANSVENDA,
              'Ignorado',
              'Validação CFAT Programa: ' || vsprograma || ' Parametro: ' ||
              vsparametro);
  end if;

END;