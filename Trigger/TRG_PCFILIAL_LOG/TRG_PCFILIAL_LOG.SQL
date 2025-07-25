create or replace trigger TRG_PCFILIAL_LOG
  before update of NSU
  on PCFILIAL
  referencing old as old new as 
new
  for each row
declare
  procedure GERAR_LOG(PCAMPO     in varchar2,
                      PVALORANT  in varchar2,
                      PVALORNOVO in varchar2,
                      PFILIAL    in varchar2,
                      PERROADIC  in varchar2 default NULL) is
  begin
    insert into PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       VALORALFAANT,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2)
    values
      (sysdate,
       'PCFILIAL',
       PCAMPO,
       PVALORANT,
       PVALORNOVO,
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'CÓDIGO DA FILIAL: ' || PFILIAL,
       PERROADIC);
  end;

begin
  if (upper(SYS_CONTEXT('USERENV', 'MODULE')) not like '%DOCFISCAL%') then
    IF (NVL(:NEW.NSU, 0) <> NVL(:OLD.NSU, 0)) then
      GERAR_LOG('NSU',
                :OLD.NSU,
                :NEW.NSU,
                :NEW.CODIGO,
                'NSU FOI ALTERADO');
    end if;
  end if;

end;
