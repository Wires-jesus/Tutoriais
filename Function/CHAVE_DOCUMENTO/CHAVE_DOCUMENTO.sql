CREATE OR REPLACE FUNCTION CHAVE_DOCUMENTO( P_UF            VARCHAR2,
                                            P_CNPJ_EMITENTE VARCHAR2,
                                            P_MODELO        VARCHAR2,
                                            P_SERIE         VARCHAR2,
                                            P_NUMNOTA       VARCHAR2,
                                            P_TIPO_EMISSAO  VARCHAR2,
                                            P_NUM_SEQ       VARCHAR2,
                                            P_DTHORAEMISSAO DATE )
   RETURN VARCHAR2
IS
   V_CHAVE        VARCHAR2(1000);

   FUNCTION DIGITODV(P_TEXTO in varchar2) return varchar2 is
     V_RESP NUMBER;
     V_PESO NUMBER;
     V_POS  NUMBER;
   BEGIN
    V_RESP := 0;
    V_PESO := 2;
    FOR V_POS IN reverse 1 .. LENGTH(P_TEXTO) LOOP
      V_RESP := V_RESP + TO_NUMBER(SUBSTR(P_TEXTO,V_POS,1))*V_PESO;

      IF V_PESO = 9 THEN
        V_PESO := 2;
      ELSE
        V_PESO := V_PESO + 1;
      END IF;
    END LOOP;
    V_RESP := 11 - (V_RESP MOD 11);
    IF V_RESP > 9 THEN
      V_RESP := 0;
    END IF;
    RETURN TO_NUMBER(V_RESP);
   END;
BEGIN
  V_CHAVE := TO_CHAR(P_UF||SUBSTR(EXTRACT(year from P_DTHORAEMISSAO),3,2)||LPAD(EXTRACT(month from P_DTHORAEMISSAO),2, '0')||P_CNPJ_EMITENTE||P_MODELO||LPAD(P_SERIE, 3, '0')||LPAD(P_NUMNOTA, 9, '0')||P_TIPO_EMISSAO||LPAD(P_NUM_SEQ, 8, '0'));
  V_CHAVE := V_CHAVE||DIGITODV(V_CHAVE); 
  RETURN V_CHAVE;
END;