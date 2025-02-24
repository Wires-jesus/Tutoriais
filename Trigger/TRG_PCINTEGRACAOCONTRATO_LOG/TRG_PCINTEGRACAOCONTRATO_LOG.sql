CREATE OR REPLACE TRIGGER TRG_PCINTEGRACAOCONTRATO_LOG
AFTER UPDATE ON PCINTEGRACAOCONTRATODIGITAL
FOR EACH ROW
DECLARE
    v_campomov CLOB := '';
BEGIN
    -- Verifica quais campos foram alterados e concatena no campo CAMPOMOV
    IF :OLD.INFORMACOES != :NEW.INFORMACOES OR (:OLD.INFORMACOES IS NULL AND :NEW.INFORMACOES IS NOT NULL) OR (:OLD.INFORMACOES IS NOT NULL AND :NEW.INFORMACOES IS NULL) THEN
        v_campomov := v_campomov || 'INFORMACOES, ';
    END IF;

    IF :OLD.DATACRIACAO != :NEW.DATACRIACAO THEN
        v_campomov := v_campomov || 'DATACRIACAO, ';
    END IF;

    -- Comparação de BLOB usando DBMS_LOB.COMPARE
    IF DBMS_LOB.COMPARE(:OLD.CONTEUDO, :NEW.CONTEUDO) != 0 THEN
        v_campomov := v_campomov || 'CONTEUDO, ';
    END IF;

    IF NVL(:OLD.PRODUTO, 'X') != NVL(:NEW.PRODUTO, 'X') THEN
        v_campomov := v_campomov || 'PRODUTO, ';
    END IF;

    IF NVL(:OLD.VERSAO, 'X') != NVL(:NEW.VERSAO, 'X') THEN
        v_campomov := v_campomov || 'VERSAO, ';
    END IF;

    IF NVL(:OLD.ACEITE, 'X') != NVL(:NEW.ACEITE, 'X') THEN
        v_campomov := v_campomov || 'ACEITE, ';
    END IF;

    IF NVL(:OLD.DATAACEITE, 'X') != NVL(:NEW.DATAACEITE, 'X') THEN
        v_campomov := v_campomov || 'DATAACEITE, ';
    END IF;

    IF NVL(:OLD.USUARIOACEITE, 'X') != NVL(:NEW.USUARIOACEITE, 'X') THEN
        v_campomov := v_campomov || 'USUARIOACEITE, ';
    END IF;

    -- Remove a última vírgula e espaço
    IF LENGTH(v_campomov) > 0 THEN
        v_campomov := SUBSTR(v_campomov, 1, LENGTH(v_campomov) - 2);
    END IF;

    -- Insere o registro na tabela de log
    INSERT INTO PCINTEGRACAOCONTRATOLOG (
        ID, INFORMACOES, DATACRIACAO, CONTEUDO, PRODUTO, VERSAO, ACEITE, DATAACEITE, USUARIOACEITE, DATAMOV, USUARIOMOV, CAMPOMOV
    ) VALUES (
        :OLD.ID, :OLD.INFORMACOES, :OLD.DATACRIACAO, :OLD.CONTEUDO, :OLD.PRODUTO, :OLD.VERSAO, :OLD.ACEITE, :OLD.DATAACEITE, :OLD.USUARIOACEITE, SYSDATE, USER, v_campomov
    );
END;
