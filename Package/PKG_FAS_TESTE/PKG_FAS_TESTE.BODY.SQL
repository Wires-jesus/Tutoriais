CREATE OR REPLACE PACKAGE BODY pkg_fas_teste AS
  PROCEDURE minha_rotina IS
  BEGIN
    -- Código que roda em todas as versões
    DBMS_OUTPUT.PUT_LINE('Executando lógica padrão, comum a todas as versões.');

    -- Bloco para Oracle 11g e anteriores.
    -- A constante VER_LE_11 existe e significa "Versão Menor ou Igual a 11".
    $IF DBMS_DB_VERSION.VER_LE_11 $THEN
      DBMS_OUTPUT.PUT_LINE('Lógica específica para Oracle 11g ou anterior.');
    $END

    -- Bloco APENAS para Oracle 12c (qualquer release, 12.1 ou 12.2)
    -- A forma correta é verificar a constante numérica VERSION.
    $IF DBMS_DB_VERSION.VERSION = 12 $THEN
       DBMS_OUTPUT.PUT_LINE('Feature exclusiva do Oracle 12c.');
    $END

    -- Bloco para Oracle 18c ou superior
    -- Para pegar 18c, 19c e futuras versões, usamos a constante numérica.
    $IF DBMS_DB_VERSION.VERSION >= 18 $THEN
      DBMS_OUTPUT.PUT_LINE('Usando feature moderna do 18c, 19c ou superior.');
    $END

    -- Exemplo mais complexo: Apenas para Oracle 19c ou superior
    $IF DBMS_DB_VERSION.VERSION >= 19 $THEN
      DBMS_OUTPUT.PUT_LINE('Lógica que só funciona no Oracle 19c ou mais recente.');
    $END

  END minha_rotina;
END pkg_fas_teste;
