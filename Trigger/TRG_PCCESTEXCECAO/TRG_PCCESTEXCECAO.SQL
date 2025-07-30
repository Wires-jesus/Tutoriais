CREATE OR REPLACE TRIGGER TRG_PCCESTEXCECAO
  BEFORE INSERT OR UPDATE OR DELETE ON PCCESTEXCECAO
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  CHAVE  VARCHAR2(2000);
  ACAO   VARCHAR2(10);
  CODLOG NUMBER;
BEGIN
  IF INSERTING THEN
    CHAVE := '|CODCESTEXCEXAO=' || NVL(:NEW.CODCESTEXCEXAO, '') ||
             '|CODSEQCEST='     || NVL(:NEW.CODSEQCEST, '')     ||
             '|TIPO1='          || NVL(:NEW.TIPO1, '')          ||
             '|VALOR1='         || NVL(:NEW.VALOR1, '')         ||
             '|TIPO2='          || NVL(:NEW.TIPO2, '')          ||
             '|VALOR2='         || NVL(:NEW.VALOR2, '')         ||
             '|TIPO3='          || NVL(:NEW.TIPO3, '')          ||
             '|VALOR3='         || NVL(:NEW.VALOR3, '')         ||
             '|CODSEQCESTNOVO=' || NVL(:NEW.CODSEQCESTNOVO, '') || '|';
    ACAO := 'INSERT';
    CODLOG := :NEW.CODCESTEXCEXAO;

  ELSIF UPDATING THEN
    CHAVE := '|CODCESTEXCEXAO=' || NVL(:NEW.CODCESTEXCEXAO, '') ||
             '|CODSEQCEST='     || NVL(:NEW.CODSEQCEST, '')     ||
             '|TIPO1='          || NVL(:NEW.TIPO1, '')          ||
             '|VALOR1='         || NVL(:NEW.VALOR1, '')         ||
             '|TIPO2='          || NVL(:NEW.TIPO2, '')          ||
             '|VALOR2='         || NVL(:NEW.VALOR2, '')         ||
             '|TIPO3='          || NVL(:NEW.TIPO3, '')          ||
             '|VALOR3='         || NVL(:NEW.VALOR3, '')         ||
             '|CODSEQCESTNOVO=' || NVL(:NEW.CODSEQCESTNOVO, '') || '|';
    ACAO := 'UPDATE';
    CODLOG := :NEW.CODCESTEXCEXAO;

  ELSIF DELETING THEN
    CHAVE := '|CODCESTEXCEXAO=' || NVL(:OLD.CODCESTEXCEXAO, '') ||
             '|CODSEQCEST='     || NVL(:OLD.CODSEQCEST, '')     ||
             '|TIPO1='          || NVL(:OLD.TIPO1, '')          ||
             '|VALOR1='         || NVL(:OLD.VALOR1, '')         ||
             '|TIPO2='          || NVL(:OLD.TIPO2, '')          ||
             '|VALOR2='         || NVL(:OLD.VALOR2, '')         ||
             '|TIPO3='          || NVL(:OLD.TIPO3, '')          ||
             '|VALOR3='         || NVL(:OLD.VALOR3, '')         ||
             '|CODSEQCESTNOVO=' || NVL(:OLD.CODSEQCESTNOVO, '') || '|';
    ACAO := 'DELETE';
    CODLOG := :OLD.CODCESTEXCEXAO;
  END IF;

  INSERT INTO PCLOGALTERACAODADOS (
    DATA,
    TABELA,
    PROGRAMA,
    TERMINAL,
    OSUSER,
    OBSERVACOES,
    OBSERVACOES2,
    CODIGO
  ) VALUES (
    SYSDATE,
    'PCCESTEXCECAO',
    SYS_CONTEXT('USERENV', 'MODULE'),
    SYS_CONTEXT('USERENV', 'TERMINAL'),
    SYS_CONTEXT('USERENV', 'OS_USER'),
    ACAO,
    CHAVE,
    CODLOG
  );
END;