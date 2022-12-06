CREATE OR REPLACE PACKAGE PKG_RELCAMPACUMUL IS

  -- Responsável  : Rodrigo Santos
  -- Dt. Criação  : 16/04/2013
  -- Objetivo     : Massa de dados inteligente para relatórios de campanhas acumulativas(Brinde Express)

/*Tipos declarados externamente
  TYPE T_REL_CAMPACUMUL_DR IS RECORD(
    codcamp          pcbrindeex.codbrex%TYPE,
    gruporegra       pcbrindeexvalidacoes.gruporegra%TYPE,
    tipo             pcbrindeexvalidacoes.tipo%TYPE,
    codigo           pcbrindeexvalidacoes.codigo%TYPE,
    descricao        VARCHAR2(100),
    codcli           pcclient.codcli%TYPE,
    tipovalor        pcbrindeexvalidacoes.tipovalor%TYPE,
    qtvendida        pcmov.qt%TYPE,
    qtprom           pcmov.qt%TYPE,
    qtproxbrinde     pcmov.qt%TYPE,
    qtvezescontempla pcmov.qt%TYPE,
    qtbrindes        pcmov.qt%TYPE);

  TYPE T_REL_CAMPACUMUL_DT IS TABLE OF T_REL_CAMPACUMUL_DR;*/

  FUNCTION REL_SINTETICO(PCODCAMP   IN NUMBER,
                         PCODSUPERV IN NUMBER DEFAULT 0,
                         PCODRCA    IN NUMBER DEFAULT 0,
                         PCODCLI    IN NUMBER DEFAULT 0)
    RETURN T_REL_CAMPACUMUL_DT
    PARALLEL_ENABLE PIPELINED
    ;

END PKG_RELCAMPACUMUL;
