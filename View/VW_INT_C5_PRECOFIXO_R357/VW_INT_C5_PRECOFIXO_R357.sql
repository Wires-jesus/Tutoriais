CREATE OR REPLACE VIEW VW_INT_C5_PRECOFIXO_R357 AS
(
  SELECT 
  P.CODPRECOPROM AS SEQREGRA, -- chave primária da tabela 
  'PRECO FIXO' AS REGRA,   -- descrição da regra
  3 AS SEQREGRATIPO, -- enviar 3
  CASE
    WHEN (SELECT L.CODPRECOPROM FROM PCPRECOPROMLOG L 
            WHERE L.CODPRECOPROM = P.CODPRECOPROM) > 0 THEN 'N'
    WHEN (SELECT P.CODPRECOPROM FROM PCPRECOPROM P 
            WHERE P.DTFIMVIGENCIA = (SELECT SYSDATE FROM DUAL)) > 0 THEN 'N'  
    ELSE 'S'
  END AS ATIVO, -- caso a política esteja na tabela PCPRECOPROMLOG ou fora do período de vigência, considerar N, se não, S.
  'G' AS TIPOREGRA, -- G
  'S' AS CUMULATIVO, -- S
  P.DTINICIOVIGENCIA DTAHORINICIO, -- data de início da vigência
  P.DTFIMVIGENCIA  DTAHORFIM, -- data de fim da vigência
  D.EMBALAGEM SEQPRODUTO,
  D.QTUNIT QTDEMBALAGEM,
  0 PERCDESCONTO,
  P.PRECOFIXO  PRECO
  FROM PCPRECOPROM P,
       PCPRODUT D,
       (select min(s.ultimaexecucao) ultimaexecucao
        from pccontroleconsinco s
        where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.carrega_tb_regraincentivo')
        ) DTPADRAO
      where NVL(P.DTULTALTER, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
        AND P.CODPROD = D.CODPROD
)
