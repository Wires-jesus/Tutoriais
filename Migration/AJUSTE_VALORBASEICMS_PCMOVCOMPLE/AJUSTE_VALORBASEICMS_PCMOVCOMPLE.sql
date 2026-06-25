DECLARE
    -- Declaração do cursor com as regras da sua query otimizada
    CURSOR c_correcao IS
        SELECT m.numtransitem,
               m.baseicms
          FROM pcmov m
         INNER JOIN pcmovcomple mc
            ON m.numtransitem = mc.numtransitem
         WHERE m.dtmov >= TRUNC(SYSDATE) - 90
           AND m.rotinacad = UPPER('AUTOSERVICO.FATURAMENTO.EXE')
           AND m.sittribut = '00'
           AND (mc.VLBASEFCPICMS IS NULL OR mc.VLBASEFCPICMS = 0)
           AND mc.vlacrescimofuncep > 0
           AND mc.peracrescimofuncep > 0;
           
    v_qtd_atualizados NUMBER := 0;
BEGIN
    FOR reg IN c_correcao LOOP
        
        -- Atualiza a pcmovcomple com a base do ICMS da pcmov
        UPDATE pcmovcomple
           SET VLBASEFCPICMS = reg.baseicms
         WHERE numtransitem = reg.numtransitem;
         
        v_qtd_atualizados := v_qtd_atualizados + 1;
        
        -- Boas práticas de banco: efetiva a transação a cada 1000 registros
        -- Isso evita travar a tabela ou estourar a memória de UNDO do Oracle
        IF MOD(v_qtd_atualizados, 1000) = 0 THEN
            COMMIT;
        END IF;
        
    END LOOP;    -- Efetiva os registros restantes e finaliza
    COMMIT;
    
    -- Imprime no console a quantidade de linhas que foram corrigidas
    DBMS_OUTPUT.PUT_LINE('Correção concluída com sucesso!');
    DBMS_OUTPUT.PUT_LINE('Total de registros atualizados: ' || v_qtd_atualizados);
	EXCEPTION
    -- Em caso de erro, desfaz tudo que não foi "commitado" e exibe o problema
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erro na execução do bloco! Nenhuma alteração pendente foi salva.');
        DBMS_OUTPUT.PUT_LINE('Mensagem do Oracle: ' || SQLERRM);
END;