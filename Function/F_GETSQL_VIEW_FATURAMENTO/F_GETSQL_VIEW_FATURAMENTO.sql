CREATE OR REPLACE FUNCTION F_GETSQL_VIEW_FATURAMENTO(
  PDATAINI   IN DATE,
  PDATAFIM   IN DATE,
  PCODFILIAL IN VARCHAR2,
  PCONDVENDA IN VARCHAR2,
  PCODFISCAL IN VARCHAR2
)
RETURN CLOB IS

  V_SQL      CLOB;
  V_CONDVENDA VARCHAR2(100) := '';
  V_CODFISCAL VARCHAR2(100) := '';

BEGIN

  V_CONDVENDA := REPLACE(PCONDVENDA, 'VENDAS.', 'PCNFSAID.');
  V_CODFISCAL := REPLACE(PCODFISCAL, 'VENDAS.', 'PCNFSAID.');

  SELECT V.TEXT
    INTO V_SQL
    FROM table(F_USER_VIEWS_PTF('V%')) V
   /*
    * "V%" is a table object refers to USER_VIEW to more details check :
    * @source https://ellebaek.wordpress.com/2010/12/06/converting-a-long-column-to-a-clob-on-the-fly/
    * This strategy solve the problem of long type corvetion to clob.
    * When size of characters string too much of 32k characters.
    */
   WHERE V.VIEW_NAME = 'VIEW_VENDAS_RESUMO_FATURAMENTO';
   
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