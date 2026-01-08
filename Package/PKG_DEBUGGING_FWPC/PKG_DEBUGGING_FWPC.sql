CREATE OR REPLACE package PKG_DEBUGGING_FWPC as
  procedure LOG(PMSG in varchar2, PTIPO in varchar2);
  procedure LOG_SQL(PMSG in CLOB, PTIPO in varchar2);
  procedure LOG_MSG(PMSG varchar2);
  procedure LOG_ERRO(PMSG varchar2);
  procedure LOG_RETORNO(PCODMENS in number, PMSG in varchar2);
  pragma restrict_references(LOG, wnds, rnds);
  procedure ATIVARDEBUG(PSERVICO in varchar2, PVERSAO in varchar2, PTRANSACAO in NUMBER default NULL);
  procedure DESATIVARDEBUG;
end PKG_DEBUGGING_FWPC;