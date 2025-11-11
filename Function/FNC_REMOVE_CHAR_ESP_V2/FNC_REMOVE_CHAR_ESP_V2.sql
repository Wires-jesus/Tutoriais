CREATE OR REPLACE FUNCTION FNC_REMOVE_CHAR_ESP_V2(texto IN VARCHAR2)
RETURN VARCHAR2
IS
  vTexto VARCHAR2(4000);
BEGIN
  vTexto := texto;

  vTexto := REPLACE(vTexto, 'Á', 'A');
  vTexto := REPLACE(vTexto, 'À', 'A');
  vTexto := REPLACE(vTexto, 'Â', 'A');
  vTexto := REPLACE(vTexto, 'Ã', 'A');
  vTexto := REPLACE(vTexto, 'Ä', 'A');
  vTexto := REPLACE(vTexto, 'É', 'E');
  vTexto := REPLACE(vTexto, 'È', 'E');
  vTexto := REPLACE(vTexto, 'Ê', 'E');
  vTexto := REPLACE(vTexto, 'Ë', 'E');
  vTexto := REPLACE(vTexto, 'Í', 'I');
  vTexto := REPLACE(vTexto, 'Ì', 'I');
  vTexto := REPLACE(vTexto, 'Î', 'I');
  vTexto := REPLACE(vTexto, 'Ï', 'I');
  vTexto := REPLACE(vTexto, 'Ó', 'O');
  vTexto := REPLACE(vTexto, 'Ò', 'O');
  vTexto := REPLACE(vTexto, 'Ô', 'O');
  vTexto := REPLACE(vTexto, 'Õ', 'O');
  vTexto := REPLACE(vTexto, 'Ö', 'O');
  vTexto := REPLACE(vTexto, 'Ú', 'U');
  vTexto := REPLACE(vTexto, 'Ù', 'U');
  vTexto := REPLACE(vTexto, 'Û', 'U');
  vTexto := REPLACE(vTexto, 'Ü', 'U');
  vTexto := REPLACE(vTexto, 'Ç', 'C');

  vTexto := REPLACE(vTexto, 'á', 'a');
  vTexto := REPLACE(vTexto, 'à', 'a');
  vTexto := REPLACE(vTexto, 'â', 'a');
  vTexto := REPLACE(vTexto, 'ã', 'a');
  vTexto := REPLACE(vTexto, 'ä', 'a');
  vTexto := REPLACE(vTexto, 'é', 'e');
  vTexto := REPLACE(vTexto, 'è', 'e');
  vTexto := REPLACE(vTexto, 'ê', 'e');
  vTexto := REPLACE(vTexto, 'ë', 'e');
  vTexto := REPLACE(vTexto, 'í', 'i');
  vTexto := REPLACE(vTexto, 'ì', 'i');
  vTexto := REPLACE(vTexto, 'î', 'i');
  vTexto := REPLACE(vTexto, 'ï', 'i');
  vTexto := REPLACE(vTexto, 'ó', 'o');
  vTexto := REPLACE(vTexto, 'ò', 'o');
  vTexto := REPLACE(vTexto, 'ô', 'o');
  vTexto := REPLACE(vTexto, 'õ', 'o');
  vTexto := REPLACE(vTexto, 'ö', 'o');
  vTexto := REPLACE(vTexto, 'ú', 'u');
  vTexto := REPLACE(vTexto, 'ù', 'u');
  vTexto := REPLACE(vTexto, 'û', 'u');
  vTexto := REPLACE(vTexto, 'ü', 'u');
  vTexto := REPLACE(vTexto, 'ç', 'c');

  vTexto := REGEXP_REPLACE(vTexto, '[^A-Za-z0-9 ,]', '');

  RETURN vTexto;
END;
