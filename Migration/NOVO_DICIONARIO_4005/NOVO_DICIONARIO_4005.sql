DECLARE 
  vCodigoAtual    NUMBER; 
  vExisteSequence VARCHAR2(1);
  vLastNumber     NUMBER; 
  vSQL            VARCHAR2(16000);
BEGIN 
  vExisteSequence := 'N'; 
  vCodigoAtual := 0; 
  vSQL := '';
  -- Verificando se existe a sequence na base do cliente. 
  BEGIN
    SELECT CASE WHEN LAST_NUMBER > 0 THEN 'S' ELSE 'N' END, 
           LAST_NUMBER
      INTO vExisteSequence, vLastNumber 
      FROM USER_SEQUENCES  
     WHERE SEQUENCE_NAME  = 'DFSEQ_PCCADASTROCNAE';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    vExisteSequence := 'N';
    vLastNumber := 0; 
  END;  

  -- Verificando o código atual do cadastro da PCCADASTROCNAE  
  SELECT MAX(CODIGO) 
         INTO vCodigoAtual 
    FROM PCCADASTROCNAE;

  -- Criando ou alterando a sequence se caso ela existir.
  IF vExisteSequence = 'S' THEN 
     IF vLastNumber < vCodigoAtual THEN 
        vSQL := vSQL || 'ALTER SEQUENCE DFSEQ_PCCADASTROCNAE increment by ' || (vCodigoAtual + 1);
        execute immediate vSQL;
     END IF;         
  ELSE 
    -- Populando comando para criar Sequence.
    vSQL := vSQL || 'create sequence DFSEQ_PCCADASTROCNAE';
    vSQL := vSQL || ' minvalue 1';
    vSQL := vSQL || ' maxvalue 999999999999999999999999999';
    
    -- Se sequencie não existir, mas o código da tabela ja existir, então assume o maior código + 1 para a sequencie ficar correta.
    IF vCodigoAtual = 0 THEN 
       vSQL := vSQL || ' start with 1';
    ELSE 
       vSQL := vSQL || ' start with ' || (vCodigoAtual + 1);
    END IF;             
    
    vSQL := vSQL || ' increment by 1';
    vSQL := vSQL || ' nocache';
    
    execute immediate vSQL; 
  END IF; 
   
  -- Ajuste na descrição do dicionário de ddos. 
  UPDATE PCDICIONARIO SET DESCRICAO = 'Código CNAE' WHERE NOMEOBJETO = 'PCCADASTROCNAE';
  Commit;
END;
