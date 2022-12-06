CREATE OR REPLACE TYPE T_ApuraRegra IS OBJECT(
    codcamp    NUMBER(6),
    gruporegra NUMBER(6),
    numregra   NUMBER(6),
    ok         VARCHAR2(1),
    multiplo   NUMBER(20,6));