CREATE OR REPLACE PROCEDURE PROC_TESTE
IS
BEGIN
  raise_application_error(-20001, 'Olá teste!!!!');
END;