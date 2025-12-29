CREATE OR REPLACE FUNCTION REPROCESSAR_FINANC3PREST(PDATA      IN DATE,
                                                    PCODFILIAL IN VARCHAR2)
  RETURN VARCHAR2 IS
  VTOTALPCFINANC NUMBER;
  PRAGMA AUTONOMOUS_TRANSACTION;
  V_MENSSAGEM VARCHAR2(20);
BEGIN
  BEGIN
    SELECT COUNT(1) TOTAL
      INTO VTOTALPCFINANC
      FROM PCFINANC3PREST
     WHERE DATAREFERENCIA = PDATA
       AND CODFILIAL = PCODFILIAL
       AND CODROTINAGERACAO <> 117;
  
    IF VTOTALPCFINANC = 0 THEN
      INSERT INTO PCFINANC3PREST
        (DATAREFERENCIA
        ,DATAGERACAO
        ,CODROTINAGERACAO
        ,TIPODADO
        ,CODROTINA
        ,CODFILIAL
        ,NUMTRANSVENDA
        ,DUPLIC
        ,PREST
        ,VALOR
        ,CODCOB
        ,DTVENC
        ,DTPAG
        ,VPAGO
        ,TXPERM
        ,DTEMISSAO
        ,VALORDESC
        ,DTDESD
        ,DTBAIXA
        ,DTCANCEL
        ,DTFECHA
        ,NUMTRANS
        ,DTDEVOL
        ,VLDEVOL
        ,DTESTORNO
        ,VALORMULTA)
        SELECT PDATA
              ,TRUNC(SYSDATE)
              ,CODROTINAGERACAO
              ,TIPODADO
              ,CODROTINA
              ,CODFILIAL
              ,NUMTRANSVENDA
              ,DUPLIC
              ,PREST
              ,VALOR
              ,CODCOB
              ,DTVENC
              ,DTPAG
              ,VPAGO
              ,TXPERM
              ,DTEMISSAO
              ,VALORDESC
              ,DTDESD
              ,DTBAIXA
              ,DTCANCEL
              ,DTFECHA
              ,NUMTRANS
              ,DTDEVOL
              ,VLDEVOL
              ,DTESTORNO
              ,VALORMULTA
          FROM PCFINANC3PREST
         WHERE DATAREFERENCIA = PDATA - 1
           AND CODFILIAL = PCODFILIAL
           AND CODROTINAGERACAO <> 117;
    
      V_MENSSAGEM := 'OK';
	  COMMIT;
    
    ELSE
      V_MENSSAGEM := 'Tabela não está vazia';
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, ('Erro original: ' || SQLERRM));
	ROLLBACK;  
  END;

  RETURN V_MENSSAGEM;
END;
