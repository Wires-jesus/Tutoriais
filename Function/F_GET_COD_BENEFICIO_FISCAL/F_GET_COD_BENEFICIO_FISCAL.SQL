CREATE OR REPLACE FUNCTION F_GET_COD_BENEFICIO_FISCAL (P_TIPOOPER        VARCHAR2,
                                                       P_TIPOCLIENTE     VARCHAR2,
                                                       P_CODFILIAL       VARCHAR2,
                                                       P_CODPROD         NUMBER,
                                                       P_UFORIG          VARCHAR2,
                                                       P_UFDEST          VARCHAR2,
                                                       P_NCM             VARCHAR2,
                                                       P_CODST           VARCHAR2,
                                                       P_CSTICMS         VARCHAR2,
                                                       P_CODFISCAL       NUMBER,
                                                       P_CODCLI          NUMBER) RETURN VARCHAR2
IS
  V_MSG   VARCHAR2(4000);
  V_MSG_COD_COMPLEMENTAR VARCHAR2(100);
  V_RESULT VARCHAR2(100);
BEGIN
    V_RESULT := GET_CODIGO_BENEFICIO_FISCAL(CASE WHEN P_TIPOOPER = 'D' THEN 'E' ELSE P_TIPOOPER END,
                                            P_TIPOCLIENTE,
                                            P_CODFILIAL,
                                            P_CODPROD,
                                            P_UFORIG,
                                            P_UFDEST,
                                            P_NCM,
                                            P_CODST,
                                            V_MSG,       
                                            P_CSTICMS,
                                            P_CODFISCAL,
                                            P_CODCLI,
                                            'S',
                                            V_MSG_COD_COMPLEMENTAR);
  IF (UPPER(SUBSTR(V_MSG, 1, 1)) = 'N')
  THEN
    RETURN NULL;
  ELSE
    RETURN V_RESULT;
  END IF;
END;
