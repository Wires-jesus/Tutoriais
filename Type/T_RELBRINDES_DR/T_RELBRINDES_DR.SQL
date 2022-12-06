CREATE OR REPLACE TYPE T_RELBRINDES_DR IS OBJECT(
    codcamp        NUMBER(6),
    grpregrabrinde NUMBER(6),
    grpregracamp   NUMBER(6),
    codbrinde      NUMBER(6),
    descricao      VARCHAR2(55),
    embalagem      VARCHAR2(12),
    qtdecamp       NUMBER(20,6),
    qtde           NUMBER(20,6),
    estdisp        VARCHAR2(1),
    similar        VARCHAR2(1),
    usadebcredrca  VARCHAR2(1),
    qtbrindedisp   NUMBER(20,6));