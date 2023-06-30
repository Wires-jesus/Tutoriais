CREATE OR REPLACE FUNCTION FNC_INT_C5_PWD (pMatricula IN NUMBER)
    RETURN VARCHAR2
IS
    vFuncS VARCHAR2(32);

BEGIN

SELECT decrypt(senhabd,usuariobd)
  INTO vFuncS
  FROM pcempr
 WHERE matricula = pMatricula;
 RETURN(vFuncS);
END;
