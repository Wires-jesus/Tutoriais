BEGIN
  --Adicionar o valor LR na lista do rotulo PRECONFE
  INSERT INTO PCROTULOITEM(
    ID, DESCRICAO, VALOR, DTCADASTRO, CRIADOPELOCLIENTE
  ) VALUES(
    'PRECONFE', 'LR - Preço Líquido + Repasse (LR)', 'LR', sysdate, 'N'
  ); 

  
---------------------------------------------------------------
  COMMIT;     
---------------------------------------------------------------
END;