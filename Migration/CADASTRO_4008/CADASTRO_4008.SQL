DECLARE                                                                                   
    V_COUNT NUMBER; 
    V_ID_SEQ NUMBER;    
    
   -- Cursor dinâmico
    TYPE T_CURSOR IS REF CURSOR;
    C_REGISTROS T_CURSOR;

    -- Variáveis para armazenar os dados do cursor
    V_CODBENEFICIOFISCAL PCBENEFICFISCALCREDPRES.CODBENEFICIOFISCAL%TYPE;
    V_CODST PCBENEFICFISCALCREDPRES.CODST%TYPE;
    V_DTCADASTRO PCBENEFICFISCALCREDPRES.DTCADASTRO%TYPE;
    V_IDROWID ROWID;                                                              
BEGIN  
   -- Verificar e adicionar coluna IDPRES                                                
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_TAB_COLUMNS                                                                  
    WHERE TABLE_NAME = 'PCBENEFICFISCALCREDPRESI' AND COLUMN_NAME = 'IDPRES';         
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRESI ADD IDPRES NUMBER(10)'; 
    END IF;                                                                               
                                                                                          
    -- Verificar e adicionar coluna IDPRES                                                
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_TAB_COLUMNS                                                                  
    WHERE TABLE_NAME = 'PCBENEFICFISCALCREDPRES' AND COLUMN_NAME = 'IDPRES';          
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRES ADD IDPRES NUMBER(10)';  
    END IF;                                                                               
                                                                                          
    -- Verificar e adicionar coluna DESCRICAO                                             
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_TAB_COLUMNS                                                                  
    WHERE TABLE_NAME = 'PCBENEFICFISCALCREDPRES' AND COLUMN_NAME = 'DESCRICAO';       
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRES ADD DESCRICAO VARCHAR2(100)';  
    END IF;                                                                               
                                                                                          
    -- Verificar e criar a sequência                                                      
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_SEQUENCES                                                                    
    WHERE SEQUENCE_NAME = 'DEFSEQ_PCBENEFICFISCALCREDPRES';                             
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'CREATE SEQUENCE DEFSEQ_PCBENEFICFISCALCREDPRES                
                           MINVALUE 1 MAXVALUE 999999999999999999999999999                
                           START WITH 1 INCREMENT BY 1 NOCACHE';                         
    END IF;    
    
    -- Atualizar os IDs com com sequência nova Chave   
    
    OPEN C_REGISTROS FOR 
        'SELECT CODBENEFICIOFISCAL, CODST, DTCADASTRO, ROWID 
         FROM PCBENEFICFISCALCREDPRES 
         WHERE NVL(IDPRES, 0) = 0 
         ORDER BY DTCADASTRO';

    LOOP
        -- Busca os dados do cursor
        FETCH C_REGISTROS INTO V_CODBENEFICIOFISCAL, V_CODST, V_DTCADASTRO, V_IDROWID;

        -- Sai do loop se não houver mais registros
        EXIT WHEN C_REGISTROS%NOTFOUND;

        -- Gera o próximo valor da sequência
        EXECUTE IMMEDIATE 'BEGIN SELECT DEFSEQ_PCBENEFICFISCALCREDPRES.NEXTVAL INTO :1 FROM dual; END;'
        USING OUT V_ID_SEQ;

        -- Atualiza PCBENEFICFISCALCREDPRES usando EXECUTE IMMEDIATE
        EXECUTE IMMEDIATE 'UPDATE PCBENEFICFISCALCREDPRES 
                           SET IDPRES = :1 
                           WHERE ROWID = :2'
        USING V_ID_SEQ, V_IDROWID;

        -- Atualiza PCBENEFICFISCALCREDPRESI usando EXECUTE IMMEDIATE
        EXECUTE IMMEDIATE 'UPDATE PCBENEFICFISCALCREDPRESI 
                           SET IDPRES = :1 
                           WHERE CODBENEFICIOFISCAL = :2 
                             AND CODST = :3'
        USING V_ID_SEQ, V_CODBENEFICIOFISCAL, V_CODST;
        COMMIT;
    END LOOP;
    
    -- Fecha o cursor
    CLOSE C_REGISTROS;
    
    -- Dropar e recriar as constraints
    DECLARE
        CURSOR C_CONSTRAINTS IS
        SELECT CONSTRAINT_NAME, TABLE_NAME
        FROM USER_CONSTRAINTS
        WHERE CONSTRAINT_NAME IN (  'PCBENEFICFISCALCREDPRESI_FK1',
                                    'PCBENEFICFISCALCREDPRESI_PK',
                                    'PCBENEFICFISCALCREDPRES_PK' );
    BEGIN
        FOR C IN C_CONSTRAINTS LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || C.TABLE_NAME || ' DROP CONSTRAINT ' || C.CONSTRAINT_NAME;
            DBMS_OUTPUT.PUT_LINE('CONSTRAINT ' || C.CONSTRAINT_NAME || ' REMOVIDA.');
        END LOOP;
    END;   
    
   
   -- Criar novas PKs   
   SELECT COUNT(*) INTO V_COUNT                                                                                                               
   FROM USER_CONSTRAINTS                                                                                                                      
   WHERE CONSTRAINT_NAME = 'PCBENEFICFISCALCREDPRES1_PK';                                                                                   
                                                                                                                                                  
   IF V_COUNT = 0 THEN                                                                                                                        
       EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRES ADD CONSTRAINT PCBENEFICFISCALCREDPRES1_PK PRIMARY KEY (IDPRES)';           
   END IF;                                                                                                                                    
                                                                                                                                                  
   SELECT COUNT(*) INTO V_COUNT                                                                                                               
   FROM USER_CONSTRAINTS                                                                                                                      
   WHERE CONSTRAINT_NAME = 'PCBENEFICFISCALCREDPRESI1_PK';                                                                                  
                                                                                                                                                  
   IF V_COUNT = 0 THEN                                                                                                                        
       EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRESI ADD CONSTRAINT PCBENEFICFISCALCREDPRESI1_PK PRIMARY KEY (IDPRES, ALIQICMSNF)';                                                              
   END IF;  
  
  --------Remoção das fórmulas, não inverter a ordem. ------------
  DELETE FROM PCFORMULA WHERE CODTIPOFORMULA IN (23, 24);
  DELETE FROM PCFORMULATIPO WHERE CODTIPOFORMULA IN (23, 24);

  --Inserção PCFORMULATIPO
  INSERT INTO PCFORMULATIPO (CODTIPOFORMULA, DESCRICAO, DTCADASTRO) VALUES (23, 'BASE_CRED_PRES_BENEF_FISCAL', SYSDATE);
  INSERT INTO PCFORMULATIPO (CODTIPOFORMULA, DESCRICAO, DTCADASTRO) VALUES (24, 'VLR_CRED_PRES_BENEF_FISCAL', SYSDATE);

  --Inserção PCFORMULATIPO
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_1', 'Base sobre Valor do Produto', 'GREATEST([PUNITCONT],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_2', 'Base sobre Valor do Produto + IPI', 'GREATEST([PUNITCONT] + [VLIPI],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_3', 'Base sobre Valor do Produto + Frete', 'GREATEST([PUNITCONT] + [VLFRETE],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_4', 'Base sobre Valor do Produto + ST', 'GREATEST([PUNITCONT] + [ST],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_5', 'Base sobre Valor do produto + Outras Despesas', 'GREATEST([PUNITCONT] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_6', 'Base sobre Valor do produto + IPI + Frete', 'GREATEST([PUNITCONT] + [VLIPI] + [VLFRETE],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_7', 'Base sobre Valor do produto + IPI + ST', 'GREATEST([PUNITCONT] + [VLIPI] + [ST],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_8', 'Base sobre Valor do produto + IPI + Outras Despesas', 'GREATEST([PUNITCONT] + [VLIPI] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_9', 'Base sobre Valor do produto + Frete + ST', 'GREATEST([PUNITCONT] + [VLFRETE] + [ST],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_10', 'Base sobre Valor do produto + Frete + Outras Despesas', 'GREATEST([PUNITCONT] + [VLFRETE] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_11', 'Base sobre Valor do produto + ST + Outras Despesas', 'GREATEST([PUNITCONT] + [ST] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_12', 'Base sobre Valor do produto + IPI + Frete + ST', 'GREATEST([PUNITCONT] + [VLIPI] + [VLFRETE] + [ST],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_13', 'Base sobre Valor do produto + IPI + Frete + Outras Despesas', 'GREATEST([PUNITCONT] + [VLIPI] + [VLFRETE] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_14', 'Base sobre Valor do produto + IPI + ST + Outras Despesas', 'GREATEST([PUNITCONT] + [VLIPI] + [ST] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_15', 'Base sobre Valor do produto + Frete + ST + Outras Despesas', 'GREATEST([PUNITCONT] + [VLFRETE] + [ST] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_16', 'Base sobre Valor do produto + IPI + Frete + ST + Outras Despesas', 'GREATEST([PUNITCONT] + [VLIPI] + [VLFRETE] + [ST] + [VLOUTROS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_17', 'Base de cálculo do ICMS', 'GREATEST([BASEICMS],0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_18', 'Base de cálculo do ICMS + Frete', 'GREATEST([BASEICMS] + [VLFRETE] ,0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_19', '(Valor do produto c/ Redução', 'GREATEST([PUNITCONT] * (DECODE([PERCBASERED],0,1,([PERCBASERED]/100))),0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_20', '(Valor do produto + Frete) c/ Redução', 'GREATEST(([PUNITCONT] + [VLFRETE]) * (DECODE([PERCBASERED],0,1,([PERCBASERED]/100))),0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_21', '(Valor do produto + Frete + Outras Despesas) c/ Redução', 'GREATEST(([PUNITCONT] + [VLFRETE] + [VLOUTROS]) * (DECODE([PERCBASERED],0,1,([PERCBASERED]/100))),0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_22', '(Valor do produto + Frete + Outras Despesas + IPI) c/ Redução', 'GREATEST(([PUNITCONT] + [VLFRETE] + [VLOUTROS] + [VLIPI]) * (DECODE([PERCBASERED],0,1,([PERCBASERED]/100))),0)', 23, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('BASE_CRED_PRES_BENEF_FISCAL_23', '(Valor do produto + Frete + Outras Despesas + IPI + ST) c/ Redução', 'GREATEST(([PUNITCONT] + [VLFRETE] + [VLOUTROS] + [VLIPI] + [ST]) * (DECODE([PERCBASERED],0,1,([PERCBASERED]/100))),0)', 23, SYSDATE);

  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_1', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto', '#BASE_CRED_PRES_BENEF_FISCAL_1#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_2', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI', '#BASE_CRED_PRES_BENEF_FISCAL_2#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_3', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + Frete', '#BASE_CRED_PRES_BENEF_FISCAL_3#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_4', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + ST', '#BASE_CRED_PRES_BENEF_FISCAL_4#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_5', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_5#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_6', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + Frete', '#BASE_CRED_PRES_BENEF_FISCAL_6#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_7', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + ST', '#BASE_CRED_PRES_BENEF_FISCAL_7#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_8', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_8#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_9', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + Frete + ST', '#BASE_CRED_PRES_BENEF_FISCAL_9#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_10', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + Frete + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_10#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_11', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + ST + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_11#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_12', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + Frete + ST', '#BASE_CRED_PRES_BENEF_FISCAL_12#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_13', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + Frete + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_13#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_14', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + ST + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_14#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_15', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + Frete + ST + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_15#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_16', 'Retorna o Vlr.Créd.Presumido sobre Base Vlr.Produto + IPI + Frete + ST + Outras Despesas', '#BASE_CRED_PRES_BENEF_FISCAL_16#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_17', 'Retorna o Vlr.Créd.Presumido sobre Base de cálculo do ICMS', '#BASE_CRED_PRES_BENEF_FISCAL_17#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_18', 'Retorna o Vlr.Créd.Pres. sobre B.cálculo do ICMS + Frete', '#BASE_CRED_PRES_BENEF_FISCAL_18#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_19', 'Retorna o Vlr.Créd.Pres. sobre Base Vlr.Produto c/ Redução', '#BASE_CRED_PRES_BENEF_FISCAL_19#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_20', 'Retorna o Vlr.Créd.Pres. sobre (Base Vlr.Produto + Frete) c/ Redução', '#BASE_CRED_PRES_BENEF_FISCAL_20#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_21', 'Retorna o Vlr.Créd.Pres. sobre (Base Vlr.Produto + Frete + Outras Despesas) c/ Redução', '#BASE_CRED_PRES_BENEF_FISCAL_21#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_22', 'Retorna o Vlr.Créd.Pres. sobre (Base Vlr.Produto + Frete + Outras Despesas + IPI) c/ Redução', '#BASE_CRED_PRES_BENEF_FISCAL_22#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);
  INSERT INTO PCFORMULA (CODFORMULA, DESCRICAO, FORMULA, CODTIPOFORMULA, DTCADASTRO) VALUES ('VLR_CRED_PRES_BENEF_FISCAL_23', 'Retorna o Vlr.Créd.Pres. sobre (Base Vlr.Produto + Frete + Outras Despesas + IPI + ST) c/ Redução', '#BASE_CRED_PRES_BENEF_FISCAL_23#*[PERC_CRED_PRESUMIDO]/100', 24, SYSDATE);   
   
EXCEPTION
    WHEN OTHERS THEN           
     ROLLBACK;                                                                          
END;                                                                                                         