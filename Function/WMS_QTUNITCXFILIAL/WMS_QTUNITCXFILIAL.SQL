create or replace function WMS_QTUNITCXFILIAL(pCODPROD number,pCODFILIAL PCPRODFILIAL.CODFILIAL%TYPE)
  return NUMBER is
  vPesoVariavel    varchar(1);
  vQtUnitcCX       number;
  vPesoBrutoMaster number;
  vTipoestoque     varchar2(2);
  vNormaPalete     PCPRODFILIAL.NORMAPALETE%TYPE;
begin
  /* Essa função tem o objetivo de retornar o valor do qtunitcx de acordo com o tipo de produto  */
  select (decode(nvl(pf.PESOBRUTOMASTER,0),0, decode(nvl(p.PESOBRUTOMASTER,0), 0,1, p.PESOBRUTOMASTER), pf.PESOBRUTOMASTER)) PESOBRUTOMASTER
  ,p.QTUNITCX,NVL(p.PESOVARIAVEL,'N'), nvl(p.tipoestoque,'X'), nvl(pf.normapalete,'C')  into
         vPesoBrutoMaster,vQtUnitcCX,vPesoVariavel,vTipoestoque,vNormaPalete
  from pcprodut p, pcprodfilial pf 
  where p.codprod =  pCODPROD
        and p.codprod = pf.codprod
        and pf.codfilial = pCODFILIAL;

  if vTipoestoque='FR' or vNormaPalete = 'P' then
     return nvl(vPesoBrutoMaster,0);
  else
      return nvl(vQtUnitcCX,0);
  end if;
end;
