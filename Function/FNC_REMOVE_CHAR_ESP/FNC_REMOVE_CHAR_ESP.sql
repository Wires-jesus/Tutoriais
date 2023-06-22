CREATE OR REPLACE FUNCTION fnc_remove_char_esp (texto IN VARCHAR2)
    RETURN VARCHAR2
IS
BEGIN
    RETURN TRANSLATE (
               texto,
               '¥µÖàé·ÔÞãë¶Ò×âêÇå¿ÓØ¿¿¿¤ ¿¡¢£¿¿¿¿¿¿¿¿¿Æä¿¿¿¿¿.-!"''`#$%().:[/]{}ù+?;§¦øõ*<>',
               'NAEIOUAEIOUAEIOUAOAEIOUCnaeiouaeiouaeiouaoaeiouc');
END;