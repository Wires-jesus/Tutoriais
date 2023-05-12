create or replace function WMS_QTUNITCX(pCODPROD number)
  return NUMBER is
  vPesoVariavel varchar(1);
  vQtUnitcCX  number;
  vPesoBrutoMaster number;
  vTipoestoque varchar2(2);
begin
 /* Essa função tem o objetivo de retornar o valor do qtunitcx de acordo com o tipo de produto  */
  select PESOBRUTOMASTER,QTUNITCX,NVL(PESOVARIAVEL,'N'), nvl(tipoestoque,'X') into 
         vPesoBrutoMaster,vQtUnitcCX,vPesoVariavel,vTipoestoque
  from pcprodut where codprod =  pCODPROD;

  /* if vPesoVariavel = 'S' and vTipoestoque='FR' then */
  if vTipoestoque='FR' then
     return nvl(vPesoBrutoMaster,0);
  else
      return nvl(vQtUnitcCX,0);
  end if;
  
end;
