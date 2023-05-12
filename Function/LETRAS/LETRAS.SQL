CREATE OR REPLACE FUNCTION LETRAS (Numero Integer) return varchar2 is
  Algarismos VarChar2(27);
  Simbolo VarChar2(20);
  Resto Integer;
  vnAux Integer;
  -- Marcos Lima 26-Apr-2007
begin
  Algarismos :='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Simbolo := '';
  vnAux := nvl(Numero,0);
  Loop
    Resto := Mod(vnAux,26);
    Simbolo := SubStr(Algarismos,Resto+1,1) || Simbolo;
    vnAux := Trunc(vnAux/26);
    exit when (vnAux=0 );
  end loop;
  return Simbolo;
end;
