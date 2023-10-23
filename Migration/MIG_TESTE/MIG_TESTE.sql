CREATE OR REPLACE PROCEDURE PROC_TESTE
IS
BEGIN
-- teste funcionamento esteira
  raise_application_error(-20001, 'Olá teste!!!!');
END;