CREATE OR REPLACE FUNCTION FCT_MED_OBTER_EST_DISPONV_BLOQ(pi_vCodProd   IN NUMBER,
                                                          pi_vCodFilial IN VARCHAR2)
RETURN NUMBER
IS
  vvVersao       VARCHAR2(250);  
  vnSaldoRetorno NUMBER;
BEGIN
  vnSaldoRetorno := 0;
  
  -- Força a Recompilação da Package (Evita Erro de Objeto Descartado)
  BEGIN
    vvVersao := PKG_ESTOQUE.VERSAO;
  EXCEPTION
   WHEN OTHERS THEN
      BEGIN
        vvVersao := PKG_ESTOQUE.VERSAO;
      EXCEPTION
        WHEN OTHERS THEN
          vvVersao := PKG_ESTOQUE.VERSAO;
       END;
  END;  
  
  -- Obtém Estoque Disponível
  vnSaldoRetorno := PKG_ESTOQUE.ESTOQUE_DISPONIVEL_BLOQUEADO(pi_vCodProd, pi_vCodFilial); -->> Pedido de Avaria Transferência

  -- Retorno
  RETURN vnSaldoRetorno;

END;
