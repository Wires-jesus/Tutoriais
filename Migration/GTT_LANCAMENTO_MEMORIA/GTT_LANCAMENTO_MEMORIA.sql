DECLARE
  V_COUNT NUMBER;
BEGIN

  SELECT COUNT(*)
    INTO V_COUNT
    FROM USER_TABLES
   WHERE TABLE_NAME = 'GTT_LANCAMENTO_MEMORIA';

  IF V_COUNT = 0 THEN
  
    EXECUTE IMMEDIATE '
      CREATE GLOBAL TEMPORARY TABLE GTT_LANCAMENTO_MEMORIA (
        numtranslancto      NUMBER(38),
        numtranslancto_int  NUMBER(38),
        dtlanc_int          DATE,
        numlancto           NUMBER(38),
        numseq              NUMBER(10),
        mes                 NUMBER(2),
        ano                 NUMBER(4),
        codfilial           VARCHAR2(2),
        codplanoconta       NUMBER(5),
        codreduzido_pc      VARCHAR2(12),
        codconta_pc         VARCHAR2(40),
        numtranscentrocusto NUMBER(12),
        dtlanc              DATE,
        natureza            CHAR(1),
        documento           VARCHAR2(50),
        lote                VARCHAR2(5),
        valor               NUMBER(22,2) DEFAULT 0,
        codhistorico        NUMBER(4),
        historico_compl     VARCHAR2(200),
        tipo_lancamento     VARCHAR2(2) DEFAULT ''N'',
        excluido            CHAR(1) DEFAULT ''N'',
        encerrado           CHAR(1) DEFAULT ''N'',
        dthralteracao       DATE,
        codfuncalteracao    NUMBER(8),
        codlogintegracao    NUMBER(38),
        codfilialimport     VARCHAR2(2),
        codregraintegracao  NUMBER(10),
        conciliado          VARCHAR2(1) DEFAULT ''N'',
        multifilial         VARCHAR2(1),
        comporfcont         VARCHAR2(2),
        codfuncintegracao   NUMBER(8),
        dataintegracao      DATE,
        codparceiro         NUMBER(8),
        tipoparceiro        VARCHAR2(2),
        loteintegracao      NUMBER(22),
        loteimportacao      NUMBER(10),
        codgrupobem         NUMBER(6),
        recalculopendente   VARCHAR2(1) DEFAULT ''N'',
        extemporaneo        VARCHAR2(1) DEFAULT ''N'',
        dtextemporaneo      DATE,
        agrupalancamento    VARCHAR2(2000),
        usacentroreceita    VARCHAR2(1),
        CODFATOGERADOR      NUMBER(3),
        NUMTRANSOPERACAO    NUMBER(12)
      ) ON COMMIT PRESERVE ROWS';
  
    EXECUTE IMMEDIATE 'CREATE INDEX GTT_LANCAMENTO_MEMORIA_IDX1 ON GTT_LANCAMENTO_MEMORIA (NUMTRANSLANCTO_INT, DTLANC_INT)';
    EXECUTE IMMEDIATE 'CREATE INDEX GTT_LANCAMENTO_MEMORIA_IDX2 ON GTT_LANCAMENTO_MEMORIA (DTLANC, CODREDUZIDO_PC, CODFILIAL)';
  
  END IF;
END;
