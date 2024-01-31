CREATE OR REPLACE VIEW VW_API_RET_STATUS_VENDA_ITEM AS
SELECT SITUACAO_IMPORTACAO_PEDIDO,
	   NUMERO_PEDIDO_RCA,
       CODIGO_RCA,
       DATA_ABERTURA_PEDIDO_RCA,
       IMPORTADO,
       OBSERVACAO_PC,
       NUMERO_PEDIDO,
       CODIGO_PRODUTO,
	   PRECO_VENDA,
	   PRECO_TABELA,
	   PRECO_BASE_MOV_CONTA_CORRENTE,
	   PERCENTUAL_DESCONTO,
	   CODIGO_FILIAL,
	   CODIGO_FILIAL_NF,
	   CODIGO_FILIAL_RETIRA,
       NUMERO_SEQUENCIA,
       DESCRICAO_PRODUTO,
       NCM,
       CODAUXILIAR,
       SITUACAO_IMPORTACAO_ITEM,
       POSICAO_ITEM,
       QUANTIDADE_ORIGINAL_PEDIDA,
       QUANTIDADE_IMPORTADA,
       TIPO_DESCONTO_ITEM,
       DATA_CANCELAMENTO,
       MOTIVO_CANCELAMENTO FROM(
-- Pedidos Nao-Processados
SELECT CASE
         WHEN NVL(CF.IMPORTADO, 0) = 1 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Nao Processado'
         WHEN NVL(CF.IMPORTADO, 0) = 2 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Importado com Sucesso'
         WHEN NVL(CF.IMPORTADO, 0) = 3 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Rejeitado'
		 WHEN NVL(CF.IMPORTADO, 0) = 4 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido em Processamento ou Importacao Nao Finalizada'
         WHEN NVL(CF.IMPORTADO, 0) = 9 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Cancelado para Importacao'
		 ELSE
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Status Desconhecido'
       END AS SITUACAO_IMPORTACAO_PEDIDO,
       V.NUMPEDRCA AS NUMERO_PEDIDO_RCA,
       V.CODUSUR AS CODIGO_RCA,
       V.DTABERTURAPEDPALM AS DATA_ABERTURA_PEDIDO_RCA,
       CF.IMPORTADO,
       V.OBSERVACAO_PC,
       CF.NUMPED AS NUMERO_PEDIDO,
       V.CODPROD AS CODIGO_PRODUTO,
	   V.PVENDA AS PRECO_VENDA,
	   NULL AS PRECO_TABELA,
	   NULL AS PRECO_BASE_MOV_CONTA_CORRENTE,
	   NULL AS PERCENTUAL_DESCONTO,
	   CF.CODFILIAL AS CODIGO_FILIAL,
	   CF.CODFILIALNF AS CODIGO_FILIAL_NF,
	   NVL(V.CODFILIALRETIRA, NVL(CF.CODFILIALRETIRA, CF.CODFILIAL)) AS CODIGO_FILIAL_RETIRA,
       V.NUMSEQ AS NUMERO_SEQUENCIA,
       T.DESCRICAO AS DESCRICAO_PRODUTO,
       T.NBM AS NCM,
       V.CODAUXILIAR,
       CASE
         WHEN (CF.IMPORTADO = 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM IMPORTACAO'
         WHEN (CF.IMPORTADO  <> 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM ITENS IMPORTADOS'
         WHEN (CF.IMPORTADO <> 1) AND ABS(V.QT) = ABS(NVL(V.QT_FATURADA, 0)) THEN
          'TOTAL'
         ELSE
          'PARCIAL'
       END AS SITUACAO_IMPORTACAO_ITEM,
       'N' AS POSICAO_ITEM,
       V.QT AS QUANTIDADE_ORIGINAL_PEDIDA,
       V.QT_FATURADA AS QUANTIDADE_IMPORTADA,
       CASE
         WHEN NVL(V.CODCOMBO, 0) > 0 THEN
          'Campanha nº ' || NVL(V.CODCOMBO, 0) ||
          ' - Rotina 3306(Cadastrar Campanha de Desconto)'
         WHEN NVL(V.CODDESCONTO, 0) > 0 THEN
          'Campanha nº ' || NVL(V.CODDESCONTO, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto)'
         WHEN NVL(V.CODDESCONTOSIMULADOR, 0) > 0 THEN
          'Campanha nº ' || NVL(V.CODDESCONTOSIMULADOR, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto - Simulador)'
         ELSE
          NULL
       END AS TIPO_DESCONTO_ITEM,
       NULL AS DATA_CANCELAMENTO,
       NULL AS MOTIVO_CANCELAMENTO
  FROM PCPEDIFV V, PCPEDCFV CF, PCPRODUT T
 WHERE V.NUMPEDRCA = CF.NUMPEDRCA
   AND V.DTABERTURAPEDPALM = CF.DTABERTURAPEDPALM
   AND V.CODPROD = T.CODPROD
   AND CF.IMPORTADO IN (1, 3, 4)
UNION
-- Pedidos processados ativos
SELECT CASE
         WHEN NVL(CF.IMPORTADO, 0) = 1 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Nao Processado'
         WHEN NVL(CF.IMPORTADO, 0) = 2 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Importado com Sucesso'
         WHEN NVL(CF.IMPORTADO, 0) = 3 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Rejeitado'
		 WHEN NVL(CF.IMPORTADO, 0) = 4 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido em Processamento ou Importacao Nao Finalizada'
         WHEN NVL(CF.IMPORTADO, 0) = 9 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Cancelado para Importacao'
		 ELSE
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Status Desconhecido'
       END AS SITUACAO_IMPORTACAO_PEDIDO,
	   CF.NUMPEDRCA AS NUMERO_PEDIDO_RCA,
       I.CODUSUR AS CODIGO_RCA,
       V.DTABERTURAPEDPALM AS DATA_ABERTURA_PEDIDO_RCA,
       CF.IMPORTADO,
       V.OBSERVACAO_PC,
       I.NUMPED AS NUMERO_PEDIDO,
       I.CODPROD AS CODIGO_PRODUTO,
	   NVL(I.PVENDA,0) AS PRECO_VENDA,
	   NVL(I.PTABELA,0) AS PRECO_TABELA,
	   NVL(I.PBASERCA,0) AS PRECO_BASE_MOV_CONTA_CORRENTE,
	   NVL(I.PERDESC,0) AS PERCENTUAL_DESCONTO,
	   CF.CODFILIAL AS CODIGO_FILIAL,
	   CF.CODFILIALNF AS CODIGO_FILIAL_NF,
	   I.CODFILIALRETIRA AS CODIGO_FILIAL_RETIRA,
       I.NUMSEQ AS NUMERO_SEQUENCIA,
       T.DESCRICAO AS DESCRICAO_PRODUTO,
       T.NBM AS NCM,
       I.CODAUXILIAR,
       CASE
         WHEN (CF.IMPORTADO = 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM IMPORTACAO'
         WHEN (CF.IMPORTADO  <> 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM ITENS IMPORTADOS'
         WHEN (CF.IMPORTADO <> 1) AND ABS(V.QT) = ABS(NVL(V.QT_FATURADA, 0)) THEN
          'TOTAL'
         ELSE
          'PARCIAL'
       END AS SITUACAO_IMPORTACAO_ITEM,
       I.POSICAO AS POSICAO_ITEM,
       V.QT AS QUANTIDADE_ORIGINAL_PEDIDA,
       V.QT_FATURADA AS QUANTIDADE_IMPORTADA,
       CASE
         WHEN NVL(O.CODROTINADESCFLEX, 0) = 301
          AND NVL(O.CODAUTORIZACAO, 0) > 0 THEN
          'Campanha nº ' || NVL(O.CODAUTORIZACAO, 0) ||
          ' - Rotina 301(Preço Autorizado)'
         WHEN NVL(I.CODDESCONTO, 0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODDESCONTO, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto)'
         WHEN NVL(I.CODDESCONTOSIMULADOR, 0) <> 0 THEN
          'Campanha nº ' || NVL(V.CODDESCONTOSIMULADOR, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto - Simulador)'
         WHEN NVL(I.CODCOMBO, 0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODCOMBO, 0) ||
          ' - Rotina 3306(Cadastrar Campanha de Desconto)'
         WHEN NVL(I.CODIGOBRINDE,0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODIGOBRINDE, 0) ||
          ' - Rotina 3220(Cadastrar Brinde Express)'
         WHEN NVL(I.CODPRECOFIXO,0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODPRECOFIXO, 0) ||
          ' - Rotina 357(Cadastrar Preco Fixo)' 
         WHEN NVL(I.CODPRECOCESTA,0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODPRECOCESTA, 0) ||
          ' - Rotina 3307(Cadastrar Cesta Básica)' 
         ELSE
          'Sem campanhas válidas.'
       END AS TIPO_DESCONTO_ITEM,
       NULL AS DATA_CANCELAMENTO,
       NULL AS MOTIVO_CANCELAMENTO
  FROM PCPEDIFV V, PCPEDCFV CF, PCPEDI I, PCORIGEMPRECO O, PCPRODUT T
 WHERE V.NUMPEDRCA = CF.NUMPEDRCA
   AND V.DTABERTURAPEDPALM = CF.DTABERTURAPEDPALM
   AND V.CODPROD = T.CODPROD
   AND V.CODPROD = I.CODPROD
   AND V.NUMPED = I.NUMPED
   AND V.NUMPED = O.NUMPED
   AND I.CODPROD = O.CODPROD
   AND T.CODPROD = I.CODPROD
   AND CF.NUMPED = I.NUMPED
   AND CF.NUMPED = O.NUMPED
   UNION
-- Pedidos Cancelados e não-faturados
SELECT CASE
         WHEN NVL(CF.IMPORTADO, 0) = 1 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Nao Processado'
         WHEN NVL(CF.IMPORTADO, 0) = 2 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Importado com Sucesso'
         WHEN NVL(CF.IMPORTADO, 0) = 3 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Rejeitado'
		 WHEN NVL(CF.IMPORTADO, 0) = 4 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido em Processamento ou Importacao Nao Finalizada'
         WHEN NVL(CF.IMPORTADO, 0) = 9 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Cancelado para Importacao'
		 ELSE
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Status Desconhecido'
       END AS SITUACAO_IMPORTACAO_PEDIDO,
	   CF.NUMPEDRCA AS NUMERO_PEDIDO_RCA,
       CF.CODUSUR AS CODIGO_RCA,
       CF.DTABERTURAPEDPALM AS DATA_ABERTURA_PEDIDO_RCA,
       CF.IMPORTADO,
       V.OBSERVACAO_PC,
       CF.NUMPED AS NUMERO_PEDIDO,
       V.CODPROD AS CODIGO_PRODUTO,
	   NVL(M.PVENDA,0) AS PRECO_VENDA,
	   NVL(M.PTABELA,0) AS PRECO_TABELA,
	   NVL(M.PBASERCA,0) AS PRECO_BASE_MOV_CONTA_CORRENTE,
	   ROUND(DECODE(NVL(M.PTABELA,0), 0, 0, (((NVL(M.PTABELA,0) - NVL(M.PVENDA,0)) / NVL(M.PTABELA,0)) * 100)),6) AS PERCENTUAL_DESCONTO,
	   CF.CODFILIAL AS CODIGO_FILIAL,
	   CF.CODFILIALNF AS CODIGO_FILIAL_NF,
	   NVL(V.CODFILIALRETIRA, NVL(CF.CODFILIALRETIRA, CF.CODFILIAL)) AS CODIGO_FILIAL_RETIRA,
       V.NUMSEQ AS NUMERO_SEQUENCIA,
       T.DESCRICAO AS DESCRICAO_PRODUTO,
       T.NBM AS NCM,
       V.CODAUXILIAR,
       CASE
         WHEN (CF.IMPORTADO = 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM IMPORTACAO'
         WHEN (CF.IMPORTADO <> 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM ITENS IMPORTADOS'
         WHEN (CF.IMPORTADO <> 1) AND ABS(V.QT) = ABS(NVL(V.QT_FATURADA, 0)) THEN
          'TOTAL'
         ELSE
          'PARCIAL'
       END AS SITUACAO_IMPORTACAO_ITEM,
       'C' AS POSICAO_ITEM,
       V.QT AS QUANTIDADE_ORIGINAL_PEDIDA,
       V.QT_FATURADA AS QUANTIDADE_IMPORTADA,
       CASE
         WHEN NVL(O.CODROTINADESCFLEX, 0) = 301 AND
              NVL(O.CODAUTORIZACAO, 0) > 0 THEN
          'Campanha nº ' || NVL(O.CODAUTORIZACAO, 0) ||
          ' - Rotina 301(Preço Autorizado)'
         WHEN NVL(O.CODROTINADESCFLEX, 0) = 561 AND
              NVL(O.CODDESCFLEX, 0) > 0 THEN
          'Campanha nº ' || NVL(O.CODDESCFLEX, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto)'
         WHEN NVL(V.CODDESCONTOSIMULADOR, 0) <> 0 THEN
          'Campanha nº ' || NVL(V.CODDESCONTOSIMULADOR, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto - Simulador)'
         WHEN NVL(V.CODCOMBO, 0) <> 0 THEN
          'Campanha nº ' || NVL(V.CODCOMBO, 0) ||
          ' - Rotina 3306(Cadastrar Campanha de Desconto)'
         WHEN NVL(O.CODPRECOFIXO, 0) <> 0 THEN
          'Campanha nº ' || NVL(O.CODPRECOFIXO, 0) ||
          ' - Rotina 357(Cadastrar Preco Fixo)'
         ELSE
          'Sem campanhas válidas.'
       END AS TIPO_DESCONTO_ITEM,
       M.DATACANC AS DATA_CANCELAMENTO,
       M.MOTIVO AS MOTIVO_CANCELAMENTO
  FROM PCPEDIFV V, PCPEDCFV CF, PCNFCANITEM M, PCORIGEMPRECO O, PCPRODUT T
 WHERE V.NUMPEDRCA = CF.NUMPEDRCA
   AND V.DTABERTURAPEDPALM = CF.DTABERTURAPEDPALM
   AND V.CODPROD = M.CODPROD
   AND V.CODPROD = O.CODPROD
   AND V.CODPROD = T.CODPROD
   AND M.CODPROD = O.CODPROD
   AND M.CODPROD = T.CODPROD
   AND V.NUMPED = M.NUMPED
   AND V.NUMPED = O.NUMPED
   AND V.NUMPED = CF.NUMPED
   AND CF.NUMPED = M.NUMPED
   AND CF.NUMPED = O.NUMPED
   AND M.NUMPED = O.NUMPED
   AND O.NUMSEQ = M.NUMSEQ
   AND M.NUMSEQ = V.NUMSEQ(+)  
UNION
-- Pedidos Cancelados e faturados
SELECT CASE
         WHEN NVL(CF.IMPORTADO, 0) = 1 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Nao Processado'
         WHEN NVL(CF.IMPORTADO, 0) = 2 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Importado com Sucesso'
         WHEN NVL(CF.IMPORTADO, 0) = 3 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Rejeitado'
		 WHEN NVL(CF.IMPORTADO, 0) = 4 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido em Processamento ou Importacao Nao Finalizada'
         WHEN NVL(CF.IMPORTADO, 0) = 9 THEN
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Pedido Cancelado para Importacao'
		 ELSE
          'Importado = ' || NVL(CF.IMPORTADO, 0) ||
          ' - Status Desconhecido'
       END AS SITUACAO_IMPORTACAO_PEDIDO,
	   CF.NUMPEDRCA AS NUMERO_PEDIDO_RCA,
       CF.CODUSUR AS CODIGO_RCA,
       CF.DTABERTURAPEDPALM AS DATA_ABERTURA_PEDIDO_RCA,
       CF.IMPORTADO,
       V.OBSERVACAO_PC,
       CF.NUMPED AS NUMERO_PEDIDO,
       V.CODPROD AS CODIGO_PRODUTO,
	   NVL(I.PVENDA,0) AS PRECO_VENDA,
	   NVL(I.PTABELA,0) AS PRECO_TABELA,
	   NVL(I.PBASERCA,0) AS PRECO_BASE_MOV_CONTA_CORRENTE,
	   NVL(I.PERDESC,0) AS PERCENTUAL_DESCONTO,
	   CF.CODFILIAL AS CODIGO_FILIAL,
	   CF.CODFILIALNF AS CODIGO_FILIAL_NF,
	   I.CODFILIALRETIRA AS CODIGO_FILIAL_RETIRA,
       V.NUMSEQ AS NUMERO_SEQUENCIA,
       T.DESCRICAO AS DESCRICAO_PRODUTO,
       T.NBM AS NCM,
       V.CODAUXILIAR,
       CASE
         WHEN (CF.IMPORTADO = 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM IMPORTACAO'
         WHEN (CF.IMPORTADO <> 1) AND (NVL(V.QT_FATURADA, 0) = 0) THEN
          'SEM ITENS IMPORTADOS'
         WHEN (CF.IMPORTADO <> 1) AND ABS(V.QT) = ABS(NVL(V.QT_FATURADA, 0)) THEN
          'TOTAL'
         ELSE
          'PARCIAL'
       END AS SITUACAO_IMPORTACAO_ITEM,
       I.POSICAO AS POSICAO_ITEM,
       V.QT AS QUANTIDADE_ORIGINAL_PEDIDA,
       V.QT_FATURADA AS QUANTIDADE_IMPORTADA,
       CASE
         WHEN NVL(O.CODROTINADESCFLEX, 0) = 301
          AND NVL(O.CODAUTORIZACAO, 0) > 0 THEN
          'Campanha nº ' || NVL(O.CODAUTORIZACAO, 0) ||
          ' - Rotina 301(Preço Autorizado)'
         WHEN NVL(I.CODDESCONTO, 0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODDESCONTO, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto)'
         WHEN NVL(I.CODDESCONTOSIMULADOR, 0) <> 0 THEN
          'Campanha nº ' || NVL(V.CODDESCONTOSIMULADOR, 0) ||
          ' - Rotina 561(Cadastrar Politica de Desconto - Simulador)'
         WHEN NVL(I.CODCOMBO, 0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODCOMBO, 0) ||
          ' - Rotina 3306(Cadastrar Campanha de Desconto)'
         WHEN NVL(I.CODIGOBRINDE,0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODIGOBRINDE, 0) ||
          ' - Rotina 3220(Cadastrar Brinde Express)'
         WHEN NVL(I.CODPRECOFIXO,0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODPRECOFIXO, 0) ||
          ' - Rotina 357(Cadastrar Preco Fixo)' 
         WHEN NVL(I.CODPRECOCESTA,0) <> 0 THEN
          'Campanha nº ' || NVL(I.CODPRECOCESTA, 0) ||
          ' - Rotina 3307(Cadastrar Cesta Básica)' 
         ELSE
          'Sem campanhas válidas.'
       END AS TIPO_DESCONTO_ITEM,
       M.DATACANC AS DATA_CANCELAMENTO,
       M.MOTIVO AS MOTIVO_CANCELAMENTO
  FROM PCPEDIFV V, PCPEDCFV CF, PCNFCANITEM M, PCPEDI I, PCMOV C, PCORIGEMPRECO O, PCPRODUT T
 WHERE V.NUMPEDRCA = CF.NUMPEDRCA
   AND V.DTABERTURAPEDPALM = CF.DTABERTURAPEDPALM
   AND V.CODPROD = M.CODPROD
   AND V.CODPROD = O.CODPROD
   AND V.CODPROD = T.CODPROD
   AND M.CODPROD = O.CODPROD
   AND M.CODPROD = T.CODPROD
   AND I.CODPROD = V.CODPROD
   AND I.CODPROD = M.CODPROD
   AND I.CODPROD = O.CODPROD
   AND I.CODPROD = T.CODPROD
   AND C.CODPROD = V.CODPROD
   AND C.CODPROD = M.CODPROD
   AND C.CODPROD = I.CODPROD
   AND C.CODPROD = O.CODPROD
   AND C.NUMPED = V.NUMPED
   AND C.NUMPED = CF.NUMPED
   AND C.NUMPED = M.NUMPED
   AND C.NUMPED = I.NUMPED
   AND C.NUMPED = O.NUMPED
   AND V.NUMPED = M.NUMPED
   AND V.NUMPED = O.NUMPED
   AND V.NUMPED = CF.NUMPED
   AND CF.NUMPED = M.NUMPED
   AND CF.NUMPED = O.NUMPED
   AND I.NUMPED = V.NUMPED
   AND I.NUMPED = CF.NUMPED
   AND I.NUMPED = M.NUMPED
   AND I.NUMPED = O.NUMPED
   AND M.NUMPED = O.NUMPED
   AND O.NUMSEQ = M.NUMSEQ
   AND M.NUMSEQ = V.NUMSEQ(+)
   AND I.NUMSEQ = O.NUMSEQ
   AND I.NUMSEQ = M.NUMSEQ
   AND C.NUMSEQ = I.NUMSEQ(+)
   AND C.NUMSEQ = M.NUMSEQ
   AND C.DTCANCEL IS NOT NULL
   AND C.QT > 0)