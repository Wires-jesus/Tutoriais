CREATE OR REPLACE TRIGGER TRG_PCCLIENTFV_TRAVADELECAO
  BEFORE INSERT OR DELETE ON PCCLIENTFV
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
declare
begin

  if (:OLD.importado = 4)
     and (:OLD.DTINCLUSAO < trunc(sysdate-2))then
    RAISE_APPLICATION_ERROR(-20000,
                            ' Cadastro do cliente esta em processamento e esta sendo excluído, favor aguardar o fim do processamento!! ');
  end if;

end;
