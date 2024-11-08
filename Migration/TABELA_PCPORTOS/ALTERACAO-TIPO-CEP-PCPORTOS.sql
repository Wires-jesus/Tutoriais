DECLARE
vSQL VARCHAR2(200);
BEGIN
 
 -- add a coluna temporaria na tabela PCPORTOS
 vSQL := 'ALTER TABLE PCPORTOS ADD CEP_TEMP  NUMBER(8)';
 EXECUTE IMMEDIATE vSQL;
 
 -- clonando os registros da coluna CEP para a coluna CEP_TEMP
 vSQL := 'UPDATE PCPORTOS SET CEP_TEMP = CEP';
 EXECUTE IMMEDIATE vSQL;
 
 -- limpando os dados da coluna cep
 vSQL := 'UPDATE PCPORTOS SET CEP = NULL';
 EXECUTE IMMEDIATE vSQL;
 
 -- modificando o tipo da coluna cep 
 vSQL := 'ALTER TABLE PCPORTOS MODIFY CEP VARCHAR(9)';
 EXECUTE IMMEDIATE vSQL;
 
 -- copiando o valor da cep_temp para a coluna cep
 vSQL := 'UPDATE PCPORTOS SET CEP = CEP_TEMP';
 EXECUTE IMMEDIATE vSQL;
 
 COMMIT;  
END;