CREATE OR REPLACE FUNCTION ROUND_ABNT(valor real, numeroCasasDecimais int) RETURN NUMBER
IS
  nRetorno NUMBER;
  decimaisAposVirgula VARCHAR2(100);
  nSubsequente integer;
  posicaoSeparadorDecimais integer;
  primeiroDigitoDescartado VARCHAR2(100);
  separadorDecimais char(1);
BEGIN
   nRetorno := valor;

   IF INSTR(TO_CHAR(valor),',') > 0 THEN 
      separadorDecimais := ',';
   ELSE 
      separadorDecimais := '.';
   END IF;

   posicaoSeparadorDecimais := INSTR(TO_CHAR(valor), separadorDecimais);
   decimaisAposVirgula := SUBSTR( TO_CHAR(valor), posicaoSeparadorDecimais +1);
   nSubsequente := numeroCasasDecimais + 1;

   IF (numeroCasasDecimais < 1) THEN
      RETURN TRUNC(nRetorno, 0);
   END IF;

   IF (LENGTH(decimaisAposVirgula) <= numeroCasasDecimais) THEN
      RETURN nRetorno;
   END IF;

   IF (SUBSTR(decimaisAposVirgula, nSubsequente, 1) > '5' OR SUBSTR(decimaisAposVirgula, nSubsequente, 1) < '5') THEN
      nRetorno := ROUND(valor, numeroCasasDecimais);
   ELSIF (SUBSTR(decimaisAposVirgula, nSubsequente, 1) = '5') THEN

      IF (MOD(SUBSTR(decimaisAposVirgula, numeroCasasDecimais, 1), 2) <> 0) THEN
         nRetorno := ROUND(valor,numeroCasasDecimais);
      ELSE
         primeiroDigitoDescartado := NVL(SUBSTR(decimaisAposVirgula, nSubsequente + 1, 1), '0');
         IF (primeiroDigitoDescartado IS NULL) THEN
           primeiroDigitoDescartado := '0';
         END IF;

         IF (primeiroDigitoDescartado > 0) THEN
            nRetorno := ROUND(valor, numeroCasasDecimais);
         ELSE
            nRetorno := TRUNC(valor, numeroCasasDecimais);
         END IF;
      END IF;
   END IF;

   RETURN nRetorno;
END ROUND_ABNT;
