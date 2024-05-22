DECLARE
    vCodRotina INTEGER;
    vCodModulo INTEGER;
    vCodMalhaRotinas INTEGER;
    vCount INTEGER;
BEGIN
    FOR DADOS IN (
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Inicializar Venda do Mês e Consolidar Mês Anterior' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  			   
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '12' AS CODMODULO,
               'Consolidação de Dados Históricos' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '12' AS CODMODULO,
               'Atualizacao Balancete 12 Meses' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Consolidar dados de vendas' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Atualização de Classificação ABC de Venda dos Clientes' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Atualização de Classificação ABC de Venda dos Produtos' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Atualização de Classificação ABC de Venda dos Fornecedores' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '12' AS CODMODULO,
               'Gerar  Posição Analítica do Contas a Receber' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '2' AS CODMODULO,
               'Cancelar pedidos de compra pendentes automaticamente' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Atualização de Sub-Classe ABC' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '3' AS CODMODULO,
               'Consolidação de Média ponderada para calculo de ST, apenas na transferência' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL UNION ALL
        SELECT 'C:\Winthor\Prod\MOD-005\PCSIS504.PC' AS PATH, 
               'N' AS EXECUTAPORLOJA, 'N' AS EXECUTAPORTIMEZONE, '2' AS CODMODULO,
               'Calculo da Base de ST para atualizar ST no preço de venda' AS DESCRICAO,
               'S' AS CRIADOSISTEMA, 'M' AS LIMITEUTILIZADO,
               '1' as PASSO, '0' AS DELAY  
          FROM DUAL
    ) LOOP
        SELECT COUNT(*) INTO vCount 
        FROM PCMALHA
        WHERE DESCRICAO = DADOS.DESCRICAO 
          AND CRIADOSISTEMA = DADOS.CRIADOSISTEMA 
          AND LIMITEUTILIZADO = DADOS.LIMITEUTILIZADO;
          
        IF vCount = 0 THEN
            SELECT DFSEQ_PCROTINAAGENDAMENTO.NEXTVAL INTO vCodRotina FROM DUAL;            
            EXECUTE IMMEDIATE 'INSERT INTO PCROTINAAGENDAMENTO (CODROTINA, PATH, EXECUTAPORLOJA, EXECUTAPORTIMEZONE, CODMODULO) 
                               VALUES (:CODROTINA, :PATH, :EXECUTAPORLOJA, :EXECUTAPORTIMEZONE, :CODMODULO)'
            USING vCodRotina, DADOS.PATH, DADOS.EXECUTAPORLOJA, DADOS.EXECUTAPORTIMEZONE, DADOS.CODMODULO;
			

            SELECT DFSEQ_PCMALHA.NEXTVAL INTO vCodModulo FROM DUAL;
            EXECUTE IMMEDIATE 'INSERT INTO PCMALHA (CODMALHA, DESCRICAO, CRIADOSISTEMA, LIMITEUTILIZADO) 
                               VALUES (:CODMALHA, :DESCRICAO, :CRIADOSISTEMA, :LIMITEUTILIZADO)'
            USING vCodModulo, DADOS.DESCRICAO, DADOS.CRIADOSISTEMA, DADOS.LIMITEUTILIZADO;
			

            SELECT DFSEQ_PCMALHAROTINA.NEXTVAL INTO vCodMalhaRotinas FROM DUAL;            
            EXECUTE IMMEDIATE 'INSERT INTO PCMALHAROTINA (CODMALHAROTINAS, CODMALHA, CODROTINA, PASSO, DELAY) 
                               VALUES (:CODMALHAROTINAS, :CODMALHA, :CODROTINA, :PASSO, :DELAY)'
            USING vCodMalhaRotinas, vCodModulo, vCodRotina, DADOS.PASSO, DADOS.DELAY;
        END IF;
    END LOOP;
    COMMIT;
END
