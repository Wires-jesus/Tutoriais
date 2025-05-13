CREATE OR REPLACE PACKAGE BODY PKG_GERAPCLANCCREDITO IS
/*
Package de geração de lançamentos para crédito de cliente. Utilizado no processo de cashback.

Parâmetros de Entrada:
PS_CODFILIAL   - Código da Filial do lançamento selecionado (PCLANC.CODFILIAL)
PN_CODCLI      - Código do Cliente/Fornecedor do lançamento selecionado (PCLANC.CODFORNEC)
PN_VALOR       - Valor do lançamento selecionado (PCLANC.VALOR). Obs.: Se for Inserção espera-se o valor positivo, caso seja estorno espera-se o valor negativo.
PS_CODROTINA   - Código da rotina geradora (PCLANC.CODROTINAALT)
PN_MATRICULA   - Matrícula do usuário (PCEMPR.MATRICULA)
PN_CODIGO      - Código do crédito (PCCRECLI.CODIGO)
PS_TIPO        - Tipo da geração, 'I' para inserção e 'E' para estorno. 
*/

  FUNCTION F_GERAR_RECNUM
    RETURN NUMBER
  IS
    PRAGMA  AUTONOMOUS_TRANSACTION;
    VNVALOR NUMBER;
  BEGIN
      --Obtendo o valor do próximo recnum
      SELECT PCCONSUM.PROXNUMLANC
        INTO VNVALOR
        FROM PCCONSUM
         FOR UPDATE;

      --Atualizando o proximo número
      UPDATE PCCONSUM
         SET PCCONSUM.PROXNUMLANC = PCCONSUM.PROXNUMLANC + 1;

      COMMIT;
      --Retornando valor encontrado
      RETURN VNVALOR;
  END;

  FUNCTION F_RETORNA_CODCONTA_CASHBACK(PS_CODFILIAL IN PCLANC.CODFILIAL%TYPE)
    RETURN NUMBER 
  IS
    VSCODIGO VARCHAR2(8);   
  BEGIN
    SELECT VALOR
      INTO VSCODIGO
      FROM PCPARAMFILIAL 
     WHERE NOME = 'CONTACORRENTECASHBACK'
       AND CODFILIAL = PS_CODFILIAL;
   
    IF VSCODIGO IS NULL THEN
      RAISE_APPLICATION_ERROR(-20001,'Não foi definido o parâmetro CONTACORRENTECASHBACK para a filial: ' || PS_CODFILIAL);
    END IF;     
  
    RETURN TO_NUMBER(VSCODIGO); 
  END;    

  FUNCTION F_RETORNA_NOME_FUNCIONARIO(PN_MATRICULA IN PCEMPR.MATRICULA%TYPE)
    RETURN VARCHAR2 
  IS
    VSNOME VARCHAR2(40);   
  BEGIN
    SELECT NOME
      INTO VSNOME
      FROM PCEMPR
     WHERE MATRICULA = PN_MATRICULA;
   
    RETURN VSNOME; 
  END;
  
  PROCEDURE P_ATUALIZAR_PCCRECLI(PS_TIPO   IN VARCHAR2,
                                 PN_CODIGO IN NUMBER,
                                 PN_RECNUM IN NUMBER) IS  
    VN_QTDE NUMBER;                                   
  BEGIN
    SELECT COUNT(1)
      INTO VN_QTDE
      FROM PCCRECLI    
     WHERE CODIGO = PN_CODIGO
       AND CASHBACK = 'S';
    
    IF VN_QTDE = 0 THEN
      RAISE_APPLICATION_ERROR(-20001,'O crédito de cliente informado não trabalha com cashback. PCCRECLI.CODIGO = ' || PN_CODIGO);  
    END IF;     
       
    IF PS_TIPO = T_TIPO_INSERCAO THEN
      UPDATE PCCRECLI 
         SET NUMLANC = PN_RECNUM 
       WHERE CODIGO = PN_CODIGO
         AND CASHBACK = 'S';
    ELSIF PS_TIPO = T_TIPO_ESTORNO THEN
      UPDATE PCCRECLI
         SET NUMLANCBAIXA = PN_RECNUM
       WHERE CODIGO = PN_CODIGO
         AND CASHBACK = 'S';
    END IF;                                      
  END;                                    

  PROCEDURE P_GERARLANCAMENTO(PS_CODFILIAL         IN VARCHAR2,
                              PN_CODCLI            IN NUMBER,                              
                              PN_VALOR             IN NUMBER,
                              PS_CODROTINA         IN VARCHAR2,
                              PN_MATRICULA         IN NUMBER,
                              PN_CODIGO            IN NUMBER,
                              PS_TIPO              IN VARCHAR2) IS
    VN_RECNUM NUMBER;
    VN_CODCONTA NUMBER; 
    VS_HISTORICO VARCHAR2(200); 
    VN_VALOR NUMBER; 
    VS_NOMEFUNC VARCHAR2(40);
    VD_DATA DATE;                          
  BEGIN  
    IF (PS_TIPO IS NULL) OR (PS_TIPO NOT IN (T_TIPO_INSERCAO, T_TIPO_ESTORNO)) THEN
      RAISE_APPLICATION_ERROR(-20001,'Parâmetro PS_TIPO inválido. Use apenas ''I'' ou ''E''.');
    END IF;  

    VN_VALOR := PN_VALOR;

    IF PS_TIPO = T_TIPO_INSERCAO THEN
      IF PN_VALOR < 0 THEN
        VN_VALOR := PN_VALOR * -1; -- CASO SEJA INSERÇÃO, DEVE SER POSITIVO.       
      END IF; 

      VS_HISTORICO := 'INSERCAO AUTOMATICA - PROCESSO DE CASHBACK'; 
    ELSIF PS_TIPO = T_TIPO_ESTORNO THEN
      IF PN_VALOR > 0 THEN
        VN_VALOR := PN_VALOR * -1; -- CASO SEJA ESTORNO, DEVE SER NEGATIVO.
      END IF;

      VS_HISTORICO := 'ESTORNO AUTOMATICO - PROCESSO DE CASHBACK (EXPIRADO)';
    END IF;
    
    VN_CODCONTA := F_RETORNA_CODCONTA_CASHBACK(PS_CODFILIAL);
    VS_NOMEFUNC := F_RETORNA_NOME_FUNCIONARIO(PN_MATRICULA);
    VN_RECNUM := F_GERAR_RECNUM;
    VD_DATA := TRUNC(SYSDATE);
    
    INSERT INTO PCLANC (
      RECNUM,
      DTLANC,
      HISTORICO,
      DUPLIC,
      CODFILIAL,
      INDICE,
      TIPOLANC,
      TIPOPARCEIRO,
      NOMEFUNC,
      MOEDA,
      NFSERVICO,
      PREST,
      CODROTINACAD,
      CODROTINAALT,
      PARCELA,
      NUMNOTA,
      CODFORNEC,
      VLRUTILIZADOADIANTFORNEC,
      UTILIZOURATEIOCONTA,
      PRCRATEIOUTILIZADO,
      VALOR,
      CODCONTA,
      VPAGO,
      DTVENC,
      DTPAGTO,
      DTEMISSAO,
      DTCOMPETENCIA
    ) VALUES (
      VN_RECNUM,        -- RECNUM
      VD_DATA,          -- DTLANC
      VS_HISTORICO,     -- HISTORICO
      '1',              -- DUPLIC
      PS_CODFILIAL,     -- CODFILIAL
      'A',              -- INDICE
      'C',              -- TIPOLANC
      'C',              -- TIPOPARCEIRO
      VS_NOMEFUNC,      -- NOMEFUNC
      'R',              -- MOEDA
      'N',              -- NFSERVICO
      '1',              -- PREST
      PS_CODROTINA,     -- CODROTINACAD
      PS_CODROTINA,     -- CODROTINAALT
      '1',              -- PARCELA
      '0',              -- NUMNOTA
      PN_CODCLI,        -- CODFORNEC
      '0',              -- VLRUTILIZADOADIANTFORNEC
      'N',              -- UTILIZOURATEIOCONTA
      '0',              -- PRCRATEIOUTILIZADO
      VN_VALOR,         -- VALOR
      VN_CODCONTA,      -- CODCONTA
      VN_VALOR,         -- VPAGO
      VD_DATA,          -- DTVENC
      VD_DATA,          -- DTPAGTO
      VD_DATA,          -- DTEMISSAO
      VD_DATA           -- DTCOMPETENCIA
    );
    
    P_ATUALIZAR_PCCRECLI(PS_TIPO, PN_CODIGO, VN_RECNUM);      
    COMMIT;        
    EXCEPTION
      WHEN OTHERS THEN
      BEGIN
        ROLLBACK;
        RAISE;
      END;        
  END;

END PKG_GERAPCLANCCREDITO;