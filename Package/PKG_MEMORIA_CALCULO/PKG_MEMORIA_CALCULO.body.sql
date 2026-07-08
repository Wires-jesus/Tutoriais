CREATE OR REPLACE PACKAGE BODY PKG_MEMORIA_CALCULO AS

  PROCEDURE INICIAR(P_CLOB OUT CLOB) IS
  BEGIN
    DBMS_LOB.CREATETEMPORARY(P_CLOB, TRUE);
  END;
--------------------------------------------- // ---------------------------------------
  FUNCTION FORMATAR_VALOR(P_VALOR IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN TO_CHAR(NVL(P_VALOR, 0), 'FM999G999G999G990D0000000000');
  END FORMATAR_VALOR;
--------------------------------------------- // ---------------------------------------
  FUNCTION FORMATAR_PERCENTUAL(P_VALOR IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN TO_CHAR(NVL(P_VALOR, 0), 'FM999G999G999G990D0000');
  END FORMATAR_PERCENTUAL;
--------------------------------------------- // ---------------------------------------
  PROCEDURE ADD_LINHA_DETALHE(P_CLOB  IN OUT NOCOPY CLOB,
                              P_TEXTO IN VARCHAR2) IS
  BEGIN
    DBMS_LOB.APPEND(P_CLOB, P_TEXTO || CHR(10));
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE ADD_TITULO_MEMORIA(P_CLOB  IN OUT NOCOPY CLOB,
                               P_TEXTO IN VARCHAR2) IS
  BEGIN
    DBMS_LOB.APPEND(P_CLOB, ''|| CHR(10));
    DBMS_LOB.APPEND(P_CLOB, '---------------------------------------------------------------------------------'|| CHR(10));
    DBMS_LOB.APPEND(P_CLOB, P_TEXTO || CHR(10));
    DBMS_LOB.APPEND(P_CLOB, '---------------------------------------------------------------------------------'|| CHR(10));
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE ADD_DETALHE_MEMORIA(P_CLOB      IN OUT NOCOPY CLOB,
                                P_DESCRICAO IN VARCHAR2,
                                P_VALOR     IN VARCHAR2) IS
  BEGIN
    ADD_LINHA_DETALHE(P_CLOB, RPAD(P_DESCRICAO, 60, '.') || ': ' || NVL(P_VALOR, ' '));
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_BLOCO_MEMORIA(P_NUMTRANSITEM IN NUMBER,
                                 P_TIPO_BLOCO   IN VARCHAR2,
                                 P_DETALHAMENTO IN CLOB,
                                 P_FIXAR_TOPO   IN VARCHAR2 DEFAULT 'N') IS
    V_MEMORIA_ATUAL CLOB;
    V_NOVO_BLOCO    CLOB;
    V_RESULTADO     CLOB;
  
    V_MARCA_INI VARCHAR2(100);
    V_MARCA_FIM VARCHAR2(100);
  
    V_POS_INI NUMBER;
    V_POS_FIM NUMBER;
  BEGIN
    V_MARCA_INI := '--[INI:' || P_TIPO_BLOCO || ']';
    V_MARCA_FIM := '--[FIM:' || P_TIPO_BLOCO || ']';
  
    DBMS_LOB.CREATETEMPORARY(V_NOVO_BLOCO, TRUE);
    DBMS_LOB.CREATETEMPORARY(V_RESULTADO, TRUE);
  
    DBMS_LOB.APPEND(V_NOVO_BLOCO, V_MARCA_INI || CHR(10));

    IF P_TIPO_BLOCO <> 'CENTRAL' THEN
      DBMS_LOB.APPEND(V_NOVO_BLOCO,
                      'Data/Hora de gravação' ||
                      RPAD('.', 60 - LENGTH('Data/Hora de gravação'), '.') || ': ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    END IF;

    DBMS_LOB.APPEND(V_NOVO_BLOCO, P_DETALHAMENTO || CHR(10));
    DBMS_LOB.APPEND(V_NOVO_BLOCO, V_MARCA_FIM || CHR(10));
  
    BEGIN
      SELECT DETALHAMENTO
        INTO V_MEMORIA_ATUAL
        FROM PCCENTRALMEMORIA
       WHERE NUMTRANSITEM = P_NUMTRANSITEM
         FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_MEMORIA_ATUAL := NULL;
    END;
  
    IF V_MEMORIA_ATUAL IS NOT NULL THEN
      V_POS_INI := DBMS_LOB.INSTR(V_MEMORIA_ATUAL, V_MARCA_INI);
      V_POS_FIM := DBMS_LOB.INSTR(V_MEMORIA_ATUAL, V_MARCA_FIM);
    ELSE
      V_POS_INI := 0;
      V_POS_FIM := 0;
    END IF;
  
    IF V_POS_INI > 0 AND V_POS_FIM > 0 THEN
      V_POS_FIM := V_POS_FIM + LENGTH(V_MARCA_FIM) + 1;
  
      IF V_POS_INI > 1 THEN
        DBMS_LOB.APPEND(V_RESULTADO,
                        DBMS_LOB.SUBSTR(V_MEMORIA_ATUAL, V_POS_INI - 1, 1));
      END IF;
  
    DBMS_LOB.APPEND(V_RESULTADO, V_NOVO_BLOCO);
  
      IF V_POS_FIM < DBMS_LOB.GETLENGTH(V_MEMORIA_ATUAL) THEN
        DBMS_LOB.APPEND(V_RESULTADO,
                        DBMS_LOB.SUBSTR(V_MEMORIA_ATUAL, 
                                        DBMS_LOB.GETLENGTH(V_MEMORIA_ATUAL) - V_POS_FIM + 1,
                                        V_POS_FIM + 1));
      END IF;
    ELSE
      IF P_FIXAR_TOPO = 'S' THEN
        DBMS_LOB.APPEND(V_RESULTADO, V_NOVO_BLOCO);
  
        IF V_MEMORIA_ATUAL IS NOT NULL THEN
          DBMS_LOB.APPEND(V_RESULTADO, V_MEMORIA_ATUAL);
        END IF;
      ELSE
        IF V_MEMORIA_ATUAL IS NOT NULL THEN
          DBMS_LOB.APPEND(V_RESULTADO, V_MEMORIA_ATUAL);
        END IF;
  
        DBMS_LOB.APPEND(V_RESULTADO, CHR(10));
        DBMS_LOB.APPEND(V_RESULTADO, V_NOVO_BLOCO);
      END IF;
    END IF;
  
    MERGE INTO PCCENTRALMEMORIA P
    USING (SELECT P_NUMTRANSITEM NUMTRANSITEM FROM DUAL) T
    ON (P.NUMTRANSITEM = T.NUMTRANSITEM)
    WHEN MATCHED THEN
      UPDATE SET P.DETALHAMENTO = V_RESULTADO
    WHEN NOT MATCHED THEN
      INSERT (NUMTRANSITEM,
              DETALHAMENTO)
      VALUES (P_NUMTRANSITEM,
              V_RESULTADO);
  
    IF DBMS_LOB.ISTEMPORARY(V_NOVO_BLOCO) = 1 THEN
      DBMS_LOB.FREETEMPORARY(V_NOVO_BLOCO);
    END IF;
  
    IF DBMS_LOB.ISTEMPORARY(V_RESULTADO) = 1 THEN
      DBMS_LOB.FREETEMPORARY(V_RESULTADO);
    END IF;
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_CENTRAL(P_NUMTRANSITEM IN NUMBER,
                                   P_DETALHAMENTO IN CLOB, 
                                   P_DETALHAMENTO_JSON IN CLOB DEFAULT NULL) IS
  BEGIN

  GRAVAR_BLOCO_MEMORIA (P_NUMTRANSITEM => P_NUMTRANSITEM,
                        P_TIPO_BLOCO   => 'CENTRAL',
                        P_DETALHAMENTO => P_DETALHAMENTO,
                        P_FIXAR_TOPO   => 'S');

    IF P_DETALHAMENTO_JSON IS NOT NULL THEN
      UPDATE PCCENTRALMEMORIA
         SET DETALHAMENTO_JSON = P_DETALHAMENTO_JSON
       WHERE NUMTRANSITEM = P_NUMTRANSITEM;
    END IF;

  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_IMP_ICMS(P_NUMTRANSITEM IN NUMBER,
                                    P_DETALHAMENTO IN CLOB) IS
  BEGIN
    GRAVAR_BLOCO_MEMORIA(
      P_NUMTRANSITEM => P_NUMTRANSITEM,
      P_TIPO_BLOCO   => 'ICMS',
      P_DETALHAMENTO => P_DETALHAMENTO,
      P_FIXAR_TOPO   => 'N');
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_IMP_ST(P_NUMTRANSITEM IN NUMBER,
                                  P_DETALHAMENTO IN CLOB) IS
  BEGIN
    GRAVAR_BLOCO_MEMORIA(
      P_NUMTRANSITEM => P_NUMTRANSITEM,
      P_TIPO_BLOCO   => 'ST',
      P_DETALHAMENTO => P_DETALHAMENTO,
      P_FIXAR_TOPO   => 'N');
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_IMP_FCP(P_NUMTRANSITEM IN NUMBER,
                                  P_DETALHAMENTO IN CLOB) IS
  BEGIN
    GRAVAR_BLOCO_MEMORIA(
      P_NUMTRANSITEM => P_NUMTRANSITEM,
      P_TIPO_BLOCO   => 'FCP',
      P_DETALHAMENTO => P_DETALHAMENTO,
      P_FIXAR_TOPO   => 'N');
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_IMP_DIFAL(P_NUMTRANSITEM IN NUMBER,
                                     P_DETALHAMENTO IN CLOB) IS
  BEGIN
    GRAVAR_BLOCO_MEMORIA(
      P_NUMTRANSITEM => P_NUMTRANSITEM,
      P_TIPO_BLOCO   => 'DIFAL',
      P_DETALHAMENTO => P_DETALHAMENTO,
      P_FIXAR_TOPO   => 'N');
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_IMP_PIS(P_NUMTRANSITEM IN NUMBER,
                                   P_DETALHAMENTO IN CLOB) IS
  BEGIN
    GRAVAR_BLOCO_MEMORIA(
      P_NUMTRANSITEM => P_NUMTRANSITEM,
      P_TIPO_BLOCO   => 'PIS',
      P_DETALHAMENTO => P_DETALHAMENTO,
      P_FIXAR_TOPO   => 'N');
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE GRAVAR_MEMORIA_IMP_COFINS(P_NUMTRANSITEM IN NUMBER,
                                      P_DETALHAMENTO IN CLOB) IS
  BEGIN
    GRAVAR_BLOCO_MEMORIA(
      P_NUMTRANSITEM => P_NUMTRANSITEM,
      P_TIPO_BLOCO   => 'COFINS',
      P_DETALHAMENTO => P_DETALHAMENTO,
      P_FIXAR_TOPO   => 'N');
  END;
--------------------------------------------- // ---------------------------------------
  PROCEDURE FINALIZAR(P_CLOB IN OUT NOCOPY CLOB) IS
  BEGIN
    IF DBMS_LOB.ISTEMPORARY(P_CLOB) = 1 THEN
       DBMS_LOB.FREETEMPORARY(P_CLOB);
    END IF;
  END;
--------------------------------------------- // ---------------------------------------
END PKG_MEMORIA_CALCULO;
-- 07/07/2026 - Pkg Implementada