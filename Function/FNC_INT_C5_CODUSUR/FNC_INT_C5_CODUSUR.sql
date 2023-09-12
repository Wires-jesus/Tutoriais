CREATE OR REPLACE FUNCTION FNC_INT_C5_CODUSUR (pSeqUsuario IN NUMBER)
    RETURN NUMBER
IS
    vCodusur NUMBER;
BEGIN
    SELECT  NVL(c.codusur,1)
      INTO  vCodusur
      FROM  pcempr c
     WHERE  c.matricula = pSeqUsuario;
    RETURN(vCodusur);
END;
