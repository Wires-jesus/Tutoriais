CREATE OR REPLACE package body PKG_DEBUGGING_FWPC as
  VGDEBUG   boolean;
  VGSERVICO varchar2(400);
  VGVERSAO  varchar2(400);
  VTRANSACAO NUMBER(10);
  VSPROGRAMA varchar2(400);
  C_TIPOERRO constant varchar2(5) := 'ERRO';
  C_TIPOMSG  constant varchar2(5) := 'DEBUG';
  VSEQUENCIA NUMBER(10);
  --------------------------------------------------------------------------------------------------  
  procedure LOG(PMSG in varchar2, PTIPO in varchar2) is
    pragma autonomous_transaction;
    DATA date;
  begin
    if VGDEBUG is null
       or VGDEBUG = false then
      return;
    end if;
    
    VSPROGRAMA    := SUBSTR(UPPER(SYS_CONTEXT('USERENV', 'MODULE')), 1, 48); 
    VSEQUENCIA := VSEQUENCIA + 1; 
	
    insert into PCFWLOGDEBUG
	  (DATA, TIPO, SERVICO, VERSAO, MENSAGEM, TRANSACAO,ROTINACAD, SEQUENCIA)
    values
      (sysdate, PTIPO, VGSERVICO, VGVERSAO, PMSG, VTRANSACAO, VSPROGRAMA, VSEQUENCIA);
    commit;
  exception
    when others then
       null;
  end;
  --------------------------------------------------------------------------------------------------  
  procedure LOG_SQL(PMSG in CLOB, PTIPO in varchar2) is
    pragma autonomous_transaction;
    DATA date;
  begin
    if VGDEBUG is null
       or VGDEBUG = false then
      return;
    end if;
    
    VSPROGRAMA    := SUBSTR(UPPER(SYS_CONTEXT('USERENV', 'MODULE')), 1, 48); 
    VSEQUENCIA := VSEQUENCIA + 1; 
     
    insert into PCFWLOGDEBUG
      (DATA,    TIPO,  SERVICO,   VERSAO, MENSAGEM, SQL, TRANSACAO, ROTINACAD, SEQUENCIA)
    values
      (sysdate, PTIPO, VGSERVICO, VGVERSAO, 'SQL registrado', PMSG, VTRANSACAO, VSPROGRAMA, VSEQUENCIA);
    commit;
  exception
    when others then
       null;
  end;  
  --------------------------------------------------------------------------------------------------
  procedure LOG_MSG(PMSG in varchar2) is
  begin
    LOG(PMSG, C_TIPOMSG);
  end;
  --------------------------------------------------------------------------------------------------  
  procedure LOG_ERRO(PMSG in varchar2) is
  begin
    LOG(PMSG, C_TIPOERRO);
  end;
  --------------------------------------------------------------------------------------------------  
  procedure LOG_RETORNO(PCODMENS in number, PMSG in varchar2) is
  begin
    LOG(PCODMENS || ' - ' || PMSG, C_TIPOMSG);
  end;
  --------------------------------------------------------------------------------------------------  
  procedure ATIVARDEBUG(PSERVICO in varchar2, PVERSAO in varchar2, PTRANSACAO in NUMBER default NULL) is
  begin
    VGSERVICO := PSERVICO;
    VGVERSAO  := PVERSAO;
    VTRANSACAO := PTRANSACAO;
    VGDEBUG := true;
	VSEQUENCIA := 0;
  end;
  --------------------------------------------------------------------------------------------------  
  procedure DESATIVARDEBUG is
  begin
    VGDEBUG := false;
  end;
  --------------------------------------------------------------------------------------------------  
end PKG_DEBUGGING_FWPC;