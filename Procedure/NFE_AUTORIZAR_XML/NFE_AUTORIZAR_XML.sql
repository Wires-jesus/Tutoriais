create or replace procedure NFE_AUTORIZAR_XML( P_CODFILIAL    IN VARCHAR2,
                                               P_NUMTRANSACAO IN NUMBER,
                                               P_TIPOMOV      IN VARCHAR2,
                                               RESULTADO      OUT VARCHAR2 ) is
  V_CODCLI               NUMBER;
  V_TIPO                 VARCHAR2(1);
  V_SEQUENCIAL           NUMBER;
begin
  V_CODCLI     := 0;
  V_TIPO       := '';
  V_SEQUENCIAL := 0;
  RESULTADO    := '';

  if (P_TIPOMOV = 'S') then
    begin
      SELECT CODCLI CODIGO, 'C' TIPO INTO V_CODCLI, V_TIPO FROM PCNFSAID WHERE NUMTRANSVENDA = P_NUMTRANSACAO AND CODFILIALNF = P_CODFILIAL;
    exception
      when NO_DATA_FOUND  then
        begin
          SELECT CODCLI CODIGO, 'C' TIPO INTO V_CODCLI, V_TIPO FROM PCNFSAIDprefat WHERE NUMTRANSVENDA = P_NUMTRANSACAO AND CODFILIALNF = P_CODFILIAL;
        exception
         when others then 
           RESULTADO := 'COSULTA NOTAS SAIDAS : ERRO : '||sqlerrm;
         end;
      when others then 
        RESULTADO := 'COSULTA NOTAS SAIDAS : ERRO : '||sqlerrm;
    end;
  else 
    begin
      SELECT CODFORNEC CODIGO, 'F' TIPO INTO V_CODCLI, V_TIPO FROM PCNFENT WHERE NUMTRANSENT = P_NUMTRANSACAO AND CODFILIALNF = P_CODFILIAL;
    exception
      when others then
        RESULTADO := 'COSULTA NOTAS ENTRADA ERRO : '||sqlerrm;
    end;
  end if;
  for REG in ( SELECT      
                  CASE WHEN LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(PCFILIAL.CGCAUTORIZAXML, '.', ''), ',', ''), '/', ''), '-', '')) > 11 THEN
                    'J'
                  ELSE
                    'F'
                  END TIPOPESSOA,
                  PCFILIAL.CGCAUTORIZAXML CGC, 
                  PCFILIAL.RAZAOSOCIAL, 
                  'CONTADOR' DESCRICAO  FROM PCFILIAL  WHERE CODIGO = P_CODFILIAL AND CGCAUTORIZAXML IS NOT NULL AND NOT EXISTS(SELECT CGC FROM PCAUTORIZXML WHERE TIPO =  V_TIPO AND CODIGO = V_CODCLI)
               UNION ALL
               SELECT TIPOPESSOA, CGC, RAZAOSOCIAL, DESCRICAO  
                 FROM PCAUTORIZXML
                WHERE PCAUTORIZXML.CODIGO = V_CODCLI
                  AND PCAUTORIZXML.TIPO = V_TIPO
                  AND PCAUTORIZXML.CODFILIAL = P_CODFILIAL )
  loop
    begin
      SELECT DFSEQ_PCAUTDOWNLOADXML.NEXTVAL INTO V_SEQUENCIAL FROM DUAL;
      INSERT INTO PCAUTDOWNLOADXML(  TIPO,
                                    PCAUTDOWNLOADXML_ID,
                                    NUMTRANSACAO,
                                    TIPOPESSOA,
                                    CGC,
                                    NOME,
                                    DESCRICAO )
                           VALUES(  V_TIPO,
                                    V_SEQUENCIAL,
                                    P_NUMTRANSACAO,
                                    REG.TIPOPESSOA,
                                    REG.CGC,
                                    REG.RAZAOSOCIAL,
                                    REG.DESCRICAO);
    exception
      when others then
        RESULTADO := 'ERRO : '||sqlerrm;
    end;
  end loop;
  commit;
end;