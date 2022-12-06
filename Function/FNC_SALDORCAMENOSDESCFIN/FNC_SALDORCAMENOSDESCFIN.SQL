CREATE OR REPLACE FUNCTION Fnc_Saldorcamenosdescfin(Pcodusur IN NUMBER
                                                   ,Pcodfilial IN VARCHAR2)
 RETURN NUMBER
 IS
  /*******************************************************************************
   Objetivo: Pesquisar os descontos financeiros dos pedidos do RCA, e abater
    este valor do Saldo do RCA. O retorno da função é o resultado desta subtração:
    Saldo RCA - Desconto Financeiro dos Pedidos
           Historico de Alteracoes
  --------------------------------------------------------------------------------
    Data               Responsavel            Descricao
    ----------------   ---------------------  ------------------------------------
    13/08/2007         Carolina              Criacao da função
    14/08/2007         Pablo                  Alteração para não retornar Valor negativo
    15/08/2007         Pablo                  Alteração para corrigir o Cálculo do Valor do Desconto Financeiro concedido
                                                          foi acrescentado  (Nvl(Pcpedc.Perdescfin, 0) / 100) pois estava somente  Nvl(Pcpedc.Perdescfin, 0) 
    14/09/2007         Pablo                  Tarefa 51188 Caso não exista registro em PCSALDORCA será gerado um registro com Saldo zerado.
  *******************************************************************************/
  -- Declaracao de Variaveis  
 vnContador NUMBER(3);
  Vvalordesc  NUMBER(14, 2);
  Vvalorsaldo NUMBER(14, 2);
  vnResultado NUMBER(14, 2);
BEGIN
  Vvalordesc := 0;
  Vvalorsaldo := 0;

  SELECT SUM(Nvl(Pcpedc.Vlatend, 0) * (Nvl(Pcpedc.Perdescfin, 0) / 100))
    INTO Vvalordesc
    FROM Pcpedc
   WHERE Posicao IN ('L', 'M')
     AND Codusur = Pcodusur
     AND Codfilial = Pcodfilial
     AND Data BETWEEN (Trunc(SYSDATE) - 120) AND Trunc(SYSDATE);

 SELECT COUNT(*)
    INTO  vnContador 
    FROM Pcsaldorca
   WHERE Codusur = Pcodusur;

 IF vnContador = 0
THEN 
   INSERT INTO PCSALDORCA
       (CODUSUR, VLSALDO, VLSALDOANT)
   VALUES
       (Pcodusur, 0, 0);
   
   Vvalorsaldo := 0;
ELSE
  SELECT Nvl(Vlsaldo, 0)
    INTO Vvalorsaldo
    FROM Pcsaldorca
   WHERE Codusur = Pcodusur;
END IF;
   
   vnResultado := NVL(Vvalorsaldo,0) - NVL(Vvalordesc,0);
   
   IF vnResultado < 0 
   THEN
     vnResultado := 0;
   END IF;  
  RETURN(vnResultado);
EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END;
/
