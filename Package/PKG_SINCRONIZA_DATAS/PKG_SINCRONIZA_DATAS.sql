CREATE OR REPLACE PACKAGE PKG_SINCRONIZA_DATAS AS
    PROCEDURE sincronizar_datas_saida(p_data_inicio IN DATE);
    
    FUNCTION contar_discrepancias(p_data_inicio IN DATE) RETURN NUMBER;
END PKG_SINCRONIZA_DATAS;
/