CREATE OR REPLACE FUNCTION F_GETSQL_VIEW_FATURAMENTO(PDATAINI   IN DATE,
                                                     PDATAFIM   IN DATE,
                                                     PCODFILIAL IN VARCHAR2,
                                                     PCONDVENDA IN VARCHAR2,
                                                     PCODFISCAL IN VARCHAR2)
  RETURN CLOB IS

  V_SQL       VARCHAR2(32000) := '';
  V_CONDVENDA VARCHAR2(100) := '';
  V_CODFISCAL VARCHAR2(100) := '';

BEGIN

  V_CONDVENDA := REPLACE(PCONDVENDA, 'VENDAS.', 'PCNFSAID.');
  V_CODFISCAL := REPLACE(PCODFISCAL, 'VENDAS.', 'PCNFSAID.');

  SELECT V.TEXT
    INTO V_SQL
    FROM ALL_VIEWS V
   WHERE V.VIEW_NAME = 'VIEW_VENDAS_RESUMO_FATURAMENTO'
     AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
  V_SQL := V_SQL || ' AND PCMOV.DTMOV BETWEEN TO_DATE( ''' ||
           TO_CHAR(PDATAINI, 'DD/MM/YYYY') ||
           ''' , ''DD/MM/YYYY'') AND TO_DATE(''' ||
           TO_CHAR(PDATAFIM, 'DD/MM/YYYY') || ''' , ''DD/MM/YYYY'')';
  V_SQL := V_SQL || ' AND PCNFSAID.DTSAIDA BETWEEN TO_DATE( ''' ||
           TO_CHAR(PDATAINI, 'DD/MM/YYYY') ||
           ''' , ''DD/MM/YYYY'') AND TO_DATE(''' ||
           TO_CHAR(PDATAFIM, 'DD/MM/YYYY') || ''' , ''DD/MM/YYYY'') 
           AND ' || V_CONDVENDA || ' AND ' || V_CODFISCAL;
  IF PCODFILIAL IS NOT NULL THEN
    V_SQL := V_SQL || ' AND PCMOV.CODFILIAL IN ( ' || PCODFILIAL || ')';
	V_SQL := V_SQL || ' AND PCNFSAID.CODFILIAL IN ( ' || PCODFILIAL || ')';
  END IF;

  RETURN V_SQL;

END;