CREATE OR REPLACE PROCEDURE PRC_TABTESTE_DEPS
AS
    -- Declaração de variáveis para armazenar as colunas da tabela
    -- Você precisará ajustar os tipos de dados e os nomes das colunas
    -- para corresponderem exatamente à sua tabela pcversaobd.
    v_campo1  pcversaobd.ROTINA%TYPE; -- Substitua 'coluna1' pelo nome real da coluna
    v_campo2  pcversaobd.VERSAO%TYPE; -- Substitua 'coluna2' pelo nome real da coluna
    -- Adicione mais variáveis conforme o número de colunas na sua tabela
    
    -- Declaração do cursor
    CURSOR c_pcversaobd IS
        SELECT ROTINA,VERSAO
        FROM pcversaobd;
BEGIN
    -- Habilita a saída para o console (necessário para o DBMS_OUTPUT.PUT_LINE)
    DBMS_OUTPUT.ENABLE(NULL);
    
    -- Abre o cursor
    OPEN c_pcversaobd;
    
    -- Loop para buscar e exibir cada linha
    LOOP
        -- Busca os dados do cursor para as variáveis
        FETCH c_pcversaobd INTO v_campo1, v_campo2; -- Ajuste conforme suas variáveis
        
        -- Sai do loop quando não houver mais linhas
        EXIT WHEN c_pcversaobd%NOTFOUND;
        
        -- Exibe os valores no console
        DBMS_OUTPUT.PUT_LINE('Campo 1: ' || v_campo1 || ' | Campo 2: ' || v_campo2);
        
    END LOOP;
    
    -- Fecha o cursor
    CLOSE c_pcversaobd;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de erro, exibe a mensagem de erro
        DBMS_OUTPUT.PUT_LINE('Ocorreu um erro: ' || SQLERRM);
        -- É uma boa prática fechar o cursor em caso de exceção
        IF c_pcversaobd%ISOPEN THEN
            CLOSE c_pcversaobd;
        END IF;
END PRC_TABTESTE_DEPS;