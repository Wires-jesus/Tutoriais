-- 03_INITIAL_DATA_SETUP.sql
-- Descrição: Configura os dados iniciais de forma idempotente (apenas insere novos registros).

BEGIN
    PRC_SL_SETUP_INFRASTRUCTURE(p_force_recreate => 0);
END;
\

DECLARE
    -- Definimos um tipo de array para listar os valores de forma organizada
    TYPE t_data_type_list IS TABLE OF VARCHAR2(50);
    
    -- Lista de tipos que queremos garantir que existam na tabela
    v_types_to_insert t_data_type_list := t_data_type_list(
        'CLOB', 
        'BLOB', 
        'NCLOB', 
        'BFILE', 
        'LONG', 
        'LONG RAW', 
        'ROWID', 
        'UROWID', 
        'XMLTYPE'
    );
    
    v_inserted_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando configuração de dados iniciais (v4.0 - Idempotente)...');

    -- Loop para processar cada item da lista
    FOR i IN 1..v_types_to_insert.COUNT LOOP
        
        -- O comando MERGE verifica se existe e insere apenas se necessário
        MERGE INTO TBL_SL_IGNORED_DATA_TYPES target
        USING (SELECT v_types_to_insert(i) AS data_type FROM DUAL) source
        ON (target.DATA_TYPE = source.data_type)
        WHEN NOT MATCHED THEN
            INSERT (DATA_TYPE) VALUES (source.data_type);
            
        -- Contabiliza apenas se houve inserção (SQL%ROWCOUNT retorna 1 se inseriu, 0 se já existia)
        IF SQL%ROWCOUNT > 0 THEN
            v_inserted_count := v_inserted_count + 1;
            DBMS_OUTPUT.PUT_LINE('  > Inserido novo tipo: ' || v_types_to_insert(i));
        END IF;
        
    END LOOP;

    COMMIT;
    
    IF v_inserted_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Nenhum novo dado precisou ser inserido. A tabela já estava atualizada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('+ ' || v_inserted_count || ' novos tipos de dados foram inseridos.');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Configuração de dados iniciais finalizada com sucesso!');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERRO ao configurar dados iniciais: ' || SQLERRM);
        ROLLBACK;
END;
