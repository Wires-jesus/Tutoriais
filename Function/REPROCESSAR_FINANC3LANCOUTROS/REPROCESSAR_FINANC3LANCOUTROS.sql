CREATE OR REPLACE FUNCTION REPROCESSAR_FINANC3LANCOUTROS(PDATA      IN DATE,
                                                         PCODFILIAL IN VARCHAR2)
  RETURN VARCHAR2 IS
  VTOTALPCFINANC NUMBER;
  PRAGMA AUTONOMOUS_TRANSACTION;
  V_MENSSAGEM VARCHAR2(20);
BEGIN
  BEGIN
    SELECT COUNT(1) TOTAL
      INTO VTOTALPCFINANC
      FROM PCFINANC3LANCOUTROS
     WHERE DATAREFERENCIA = PDATA
       AND CODFILIAL = PCODFILIAL
       AND CODROTINA = 504;
  
    IF VTOTALPCFINANC = 0 THEN
      INSERT INTO PCFINANC3LANCOUTROS
        (DATAREFERENCIA
        ,DATAGERACAO
        ,CODROTINAGERACAO
        ,CODFILIAL
        ,TIPODADO
        ,RECNUM
        ,RECNUMPRINC
        ,DTLANC
        ,CODGRUPO
        ,CODCONTA
        ,CODFORNEC
        ,NUMNOTA
        ,DUPLIC
        ,VALOR
        ,DTVENC
        ,VPAGO
        ,DTPAGTO
        ,TIPOPARCEIRO
        ,DTDESD
        ,VALORDEV
        ,TXPERM
        ,DESCONTOFIN
        ,NUMBORDERO
        ,VPAGOBORDERO
        ,INVESTIMENTO
        ,CODROTINA)
        SELECT PDATA
              ,TRUNC(SYSDATE)
              ,CODROTINAGERACAO
              ,CODFILIAL
              ,TIPODADO
              ,RECNUM
              ,RECNUMPRINC
              ,DTLANC
              ,CODGRUPO
              ,CODCONTA
              ,CODFORNEC
              ,NUMNOTA
              ,DUPLIC
              ,VALOR
              ,DTVENC
              ,VPAGO
              ,DTPAGTO
              ,TIPOPARCEIRO
              ,DTDESD
              ,VALORDEV
              ,TXPERM
              ,DESCONTOFIN
              ,NUMBORDERO
              ,VPAGOBORDERO
              ,INVESTIMENTO
              ,CODROTINA
          FROM PCFINANC3LANCOUTROS
         WHERE DATAREFERENCIA = PDATA - 1
           AND CODFILIAL = PCODFILIAL
           AND CODROTINA = 504;
    
      V_MENSSAGEM := 'OK';
    
    ELSE
      V_MENSSAGEM := 'Tabela não está vazia';
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, ('Erro original: ' || SQLERRM));
  END;

  RETURN V_MENSSAGEM;
END;
