CREATE OR REPLACE PACKAGE PARAMFILIAL IS
   FUNCTION ObterComoVarchar2(nomeParam in varchar2) return varchar2;
   FUNCTION ObterComoVarchar2(nomeParam in varchar2, pCodFilial in varchar2) return varchar2;
   FUNCTION ObterComoBoolean(nomeParam in varchar2, codFilial in varchar2, valorTrue in varchar2,
      valorFalse in varchar2) return varchar2;
   FUNCTION ObterComoBoolean(nomeParam in varchar2, codFilial in varchar2) return varchar2;
   FUNCTION ObterComoBoolean(nomeParam in varchar2) return varchar2;
   FUNCTION ObterComoDate(nomeParam in varchar2, codFilial in varchar2) return date;
   FUNCTION ObterComoDate(nomeParam in varchar2) return date;
   FUNCTION ObterComoNumber(nomeParam in varchar2, codFilial in varchar2) return number;
   FUNCTION ObterComoNumber(nomeParam in varchar2) return number;
   FUNCTION ParametroExiste(nomeParam in varchar2) return boolean;   
   FUNCTION ParametroExiste(nomeParam in varchar2, pCodFilial in varchar2) return boolean;      
end;