DECLARE 
  PROCEDURE INSERT_DATA(pNOME       PCPARAMETRORF.NOME%TYPE
                      ,pVALOR       PCPARAMETRORF.VALOR%TYPE
                      ,pVALORES     PCPARAMETRORF.VALORES%TYPE
                      ,pDESCRICAO   PCPARAMETRORF.DESCRICAO%TYPE
                      ,pMODULO      PCPARAMETRORF.MODULO%TYPE
                      ,pTIPO        PCPARAMETRORF.TIPO%TYPE)
 
  IS
  BEGIN
    INSERT INTO PCPARAMETRORF
                  (NOME,
                   DESCRICAO,
                   CODFILIAL,
                   VALOR,
                   VALORES,
                   TIPO,
                   MODULO)
                   (SELECT pNOME,
                           pDESCRICAO,
                           PCFILIAL.CODIGO,
                           pVALOR,
                           pVALORES,
                           pTIPO,
                           pMODULO
                      FROM PCFILIAL 
                     WHERE 1 = 1
                       AND NOT EXISTS (SELECT 1 FROM PCPARAMETRORF F WHERE F.NOME = pNOME AND F.CODFILIAL = PCFILIAL.CODIGO)
                   ); 
				   
    UPDATE PCPARAMETRORF SET DESCRICAO = pDESCRICAO WHERE NOME = pNOME; 
  END;
 
BEGIN    
  INSERT_DATA('PERCDIVFECHACONFCARREG', '0', NULL, 'Perc. de divergencia para fechar conf. do carreg.', NULL, NULL);

  INSERT_DATA('PERMITECONFSIMULTANEOS', 'S', NULL, 'Habilita conferência simultanea de um mesmo bônus (parâmetro de entrada)', NULL, NULL);
  
  INSERT_DATA('CONFERENCIACEGACARGA', 'N', NULL, 'Conferência cega por carregamento', NULL, NULL);
  
  INSERT_DATA('TEMPOMEDIOCONFITEM', '120', NULL, 'Parâm. define tempo de sep. do item no carreg.', NULL, NULL);
  
  INSERT_DATA('CONFERENCIACEGAPEDIDO', 'N', NULL, 'Conferência cega por pedido', NULL, NULL);
  
  INSERT_DATA('LETREIRO3815', '', NULL, 'Mensagem de Texto visualizada na rotina 3815', NULL, NULL);
  
  INSERT_DATA('TIPOSEPARACAOROTINA3817', 'C', NULL,  'Tipo de separação (Rotina 3817)', NULL, NULL);
  
  INSERT_DATA('TIPOSEPARACAOROTINA3801', 'P', NULL, 'Tipo de separação (Rotina 3817)', NULL, NULL);
  
  INSERT_DATA('CONFERENCIACEGABONUS', 'N', NULL, 'Conferência Cega do Bônus', 'RECEBIMENTO', 'BOOLEAN');
  
  INSERT_DATA('SOMARAVARIARECEBIMENTO', 'N', NULL, 'Somar Avaria no Recebimento', NULL, NULL);
  
  INSERT_DATA('USARQTUNITCODIGOBARRAEAN', 'N', NULL, 'Usar QTUNIT como fator de conversão código de barras EAN', NULL, NULL);
  
  INSERT_DATA('UTILIZACODFABNOBONUS', 'N', NULL, 'Visualizar código de fábrica dos itens no RF?', 'RECEBIMENTO', 'BOOLEAN');
  
  INSERT_DATA('CONFERENCIA_CEGA_CARGA', 'N', NULL, 'Utilizar conferência cega para Carga?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('INFORMA_SERIE', 'CONFERENCIA', 'CONFERENCIA-Conferência;SEPARACAO-Separação', 'Quando informar a(s) Série(s)?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('INFORMA_LOTE', 'CONFERENCIA', 'CONFERENCIA-Conferência;SEPARACAO-Separação', 'Quando informar o(s) Lote(s)?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('MOTIVO_DEPURACAO_PESO_VARIAVEL', '', NULL, 'Qual o motivo de Depuração de Peso Variável?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('SEPARA_CARGA_RUA', 'N', NULL, 'Utilizar separação de Carga Rua?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('TIPO_SEPARACAO_PEDIDO', 'P', 'P-Padrão;C-Checkout', 'Qual o tipo de separação para Pedido?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('APENAS_EMBALAGEM_DO_PEDIDO', 'N', NULL, 'Informar apenas embalagem do pedido?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('TIPO_SEPARACAO_CARGA', 'P', 'P-Padrão;C-Checkout', 'Qual o tipo de separação para Carga?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('ORDENACAO_SEPARACAO_PRODUTO_PEDIDO', 'E', 'E-Endereco;T-Tipo', 'Como deseja ordenar a separação por pedido?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('ORDENACAO_SEPARACAO_PRODUTO_CARGA', 'E', 'E-Endereco;T-Tipo', 'Como deseja ordenar a separação por carga?', 'EXPEDICAO', 'SELECT');
  
  INSERT_DATA('RESERVAR_ESTOQUE_ACIMA', 'N', NULL, 'Reservar acima do estoque disponível os produtos peso variável que estão dentro da tolerância?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('ETIQUETA_SEPARACAO_PEDIDO', 'N', NULL, 'Utilizar etiqueta de separação de pedido customizada ?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('ETIQUETA_CONFERENCIA_PEDIDO', 'N', NULL, 'Utilizar etiqueta de conferência de pedido customizada ?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('USAR_PESAGEM_PRODUTO_FRIOS', 'S', NULL, 'Considerar pesagem de produtos frios na 998 como conferidos?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('UTILIZAENDERECAMENTOPORFILIAL', 'S', NULL, 'Utilizar o endereçamento por filial?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('CONFERENCIA_CEGA_PEDIDO', 'N', NULL, 'Utilizar conferência cega para Pedido?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('UTILIZA_MULTI_OPERADOR', 'N', NULL, 'Utilizar processo de multi-operador?', 'EXPEDICAO', 'BOOLEAN');
  
  INSERT_DATA('TIPO_INVENT', 'P', 'P-Padrão;C-Checkout', 'Qual o tipo de inventário?', 'INVENTARIO', 'SELECT');
  
  INSERT_DATA('LISTAR_ITENS_INVENTARIO', 'S', NULL, 'Exibir todos os itens do inventário?', 'INVENTARIO', 'BOOLEAN'); 
  
  INSERT_DATA('VALIDA_DISTRIBUICAO', 'S', NULL, 'Validar a distribuição do pedido na conferência?', 'EXPEDICAO', 'BOOLEAN');
END;




