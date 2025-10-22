DECLARE 
  vTemRotinaTabela integer := 0;
  v_DeleteBaseCBSIBS_Antigo   varchar2(4000);  
BEGIN

  
  SELECT COUNT(1)
    INTO vTemRotinaTabela
   FROM PCROTINATABELA
  WHERE NOMEOBJETO = 'PCTRIBUTACAO'
    AND CODROTINA = 4000; 

  IF vTemRotinaTabela = 0 THEN
    INSERT INTO PCROTINATABELA (
        CODROTINA, NOMEOBJETO, USARCADGENERICO, WHEREADICIONALPESQ,
        PERMITEINCLUIR, PERMITEALTERAR, PERMITEEXCLUIR, TITULOROTINA,
        DTCADASTRO, ATUALIZARPERMISSAO
    ) VALUES (
       4000, 'PCTRIBUTACAO', 'N', '...',
        'S', 'S', 'S', 'Cadastro de reforma tributária',
        TO_DATE('24/01/2023 18:00:30', 'DD/MM/YYYY HH24:MI:SS'), 'S'
    );
  ELSE  
    UPDATE PCROTINATABELA
       SET PERMITEINCLUIR = 'S', 
           PERMITEALTERAR = 'S', 
           PERMITEEXCLUIR = 'S'
     WHERE NOMEOBJETO = 'PCTRIBUTACAO'
       AND CODROTINA = 4000;             
  END IF;
  
  UPDATE PCDICIONARIOITEM D
    SET D.FORMULAAUTOGERACAO = UPPER(D.FORMULAAUTOGERACAO)
  WHERE D.NOMEOBJETO = 'PCTRIBUTACAO';
  
  UPDATE PCDICIONARIOITEMROT R
    SET R.EXIBIRRESPESQ = 'S', R.USARNAPESQUISA = 'S'
  WHERE R.CODROTINA = 4000;

  UPDATE PCDICIONARIOITEMROT R
   SET R.OBRIGATORIO = 'N'
  WHERE R.NOMEOBJETO = 'PCTRIBUTACAO'
   AND R.NOMECAMPO = 'PERC_IBS_MUN'
   AND R.CODROTINA = 4000;
  
  UPDATE PCDICIONARIO 
     SET DESCRICAO = 'Tributos'
  WHERE NOMEOBJETO = 'PCTRIBUTACAO';  
  
  COMMIT;
  
  -----------------------------------------------------------------
  --Delete dos cadastros antigos para não gerar erro na pkg FORMULA
  
  v_DeleteBaseCBSIBS_Antigo := 'DELETE FROM pctributacao WHERE base_calculo IN (';
  
  FOR i IN 1..15 LOOP
    IF i > 1 THEN
      v_DeleteBaseCBSIBS_Antigo := v_DeleteBaseCBSIBS_Antigo || ',';
    END IF;
    v_DeleteBaseCBSIBS_Antigo := v_DeleteBaseCBSIBS_Antigo || '''BASE_CBS_' || i || '''';
  END LOOP;

  FOR i IN 1..15 LOOP
    v_DeleteBaseCBSIBS_Antigo := v_DeleteBaseCBSIBS_Antigo || ',''' || 'BASE_IBS_' || i || '''';
  END LOOP;
  
  FOR i IN 2..15 LOOP
    v_DeleteBaseCBSIBS_Antigo := v_DeleteBaseCBSIBS_Antigo || ',''' || 'BASE_IS_' || i || '''';
  END LOOP;  

  v_DeleteBaseCBSIBS_Antigo := v_DeleteBaseCBSIBS_Antigo || ')';

  EXECUTE IMMEDIATE v_DeleteBaseCBSIBS_Antigo;

  COMMIT;  
    

  -----------------------------------------------------------------
  -- O código 29 representava o cadastro da base do CBS que foi unificado no codigo 28
  --Exclusão e insersão dos tipos de fórmula.
  DELETE FROM PCFORMULA WHERE CODTIPOFORMULA IN (28, 29, 30, 31, 32, 33);
  
  DELETE FROM PCFORMULATIPO WHERE CODTIPOFORMULA IN (28, 29, 30, 31, 32, 33);

  --Insersão dos tipos de fórmula.   
  INSERT INTO PCFORMULATIPO
    (CODTIPOFORMULA, DESCRICAO, DTCADASTRO)
  VALUES
    (28, 'BASE_CBSIBS', SYSDATE);   
    
  INSERT INTO PCFORMULATIPO
    (CODTIPOFORMULA, DESCRICAO, DTCADASTRO)
  VALUES
    (30, 'ALIQUOTA_CBS', SYSDATE);
    
  INSERT INTO PCFORMULATIPO
    (CODTIPOFORMULA, DESCRICAO, DTCADASTRO)
  VALUES
    (31, 'ALIQUOTA_IBS', SYSDATE);
    
  INSERT INTO PCFORMULATIPO
    (CODTIPOFORMULA, DESCRICAO, DTCADASTRO)
  VALUES
    (32, 'BASE_IS', SYSDATE);
    
  INSERT INTO PCFORMULATIPO
    (CODTIPOFORMULA, DESCRICAO, DTCADASTRO)
  VALUES
    (33, 'ALIQUOTA_IS', SYSDATE);

  --Insersão das formulas. 
  INSERT INTO PCFORMULA
    (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO)
  VALUES
    ('BASE_CBSIBS_1',
     'Base sobre Valor do Produto',
     'GREATEST(' || '&' || 'PUNITCONT' || '&' || ',0)',
     28,
     SYSDATE);
     
  INSERT INTO PCFORMULA
    (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO)
  VALUES
    ('BASE_IS_1',
     'Base sobre Valor do Produto',
     'GREATEST(' || '&' || 'PUNITCONT' || '&' || ',0)',
     32,
     SYSDATE);

  COMMIT;     
  
END;