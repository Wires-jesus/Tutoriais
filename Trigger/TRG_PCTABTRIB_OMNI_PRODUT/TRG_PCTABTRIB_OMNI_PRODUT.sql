CREATE OR REPLACE TRIGGER TRG_PCTABTRIB_OMNI_PRODUT
    AFTER INSERT OR UPDATE OF CODST OR DELETE
    ON PCTABTRIB
    FOR EACH ROW
DECLARE
    v_codprod   NUMBER;
    v_usa_omni  NUMBER := 0;
    v_sql       VARCHAR2(1000);
BEGIN
    IF INSERTING OR UPDATING THEN
        v_codprod := :NEW.CODPROD;
    ELSIF DELETING THEN
        v_codprod := :OLD.CODPROD;
    END IF;

    v_sql := 'SELECT 1 ' ||
             'FROM PCINTEGRACAODADOSEMPRESA a, PCINTEGRACAOFLUXOEXECUCAO b ' ||
             'WHERE a.nome = ''PDVSYNC'' ' ||
             'AND b.DESCRICAO = ''Produto'' ' ||
             'AND b.ativo = ''S'' ' ||
             'AND ROWNUM = 1';

    BEGIN
        EXECUTE IMMEDIATE v_sql INTO v_usa_omni;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_usa_omni := 0;
        WHEN OTHERS THEN
            v_usa_omni := 0;
    END;

    IF v_usa_omni > 0 THEN
        UPDATE PCPRODUT
        SET DTULTALTER = SYSDATE
        WHERE CODPROD = v_codprod;
    END IF;
END;