CREATE OR REPLACE TYPE T_REL_CAMPACUMUL_DR IS OBJECT(
    codcamp            NUMBER(6),
    gruporegra         NUMBER(6),
    tipo               VARCHAR2(2),
    codigo             NUMBER(10),
    descricao          VARCHAR2(100),
    codcli             NUMBER(6),
    tipovalor          VARCHAR2(2),
    qtvendida          NUMBER(20,6),
    qtprom             NUMBER(20,6),
    qtproxbrinde       NUMBER(20,6),
    qtvezescontempla   NUMBER(20,6),
    qtvezescontemplado NUMBER(20,6),
    qtbrindes          NUMBER(20,6));