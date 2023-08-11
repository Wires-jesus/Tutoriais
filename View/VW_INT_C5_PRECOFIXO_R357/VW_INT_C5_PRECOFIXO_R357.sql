CREATE OR REPLACE VIEW VW_INT_C5_PRECOFIXO_R357 AS
(
  SELECT 
  357||P.CODPRECOPROM AS SEQREGRA, -- chave primaria da tabela 
  'PRECO FIXO' AS REGRA,   -- descricao da regra
  3 AS SEQREGRATIPO, -- enviar 3
  CASE
    WHEN (SELECT L.CODPRECOPROM FROM PCPRECOPROMLOG L 
            WHERE L.CODPRECOPROM = P.CODPRECOPROM) > 0 THEN 'N'
    WHEN (SELECT P.CODPRECOPROM FROM PCPRECOPROM P 
            WHERE P.DTFIMVIGENCIA = (SELECT SYSDATE FROM DUAL)) > 0 THEN 'N'  
    ELSE 'S'
  END AS ATIVO, -- caso a politica esteja na tabela PCPRECOPROMLOG ou fora do periodo de vigencia, considerar N, se nao, S.
  'G' AS TIPOREGRA, -- G
  'S' AS CUMULATIVO, -- S
  P.DTINICIOVIGENCIA DTAHORINICIO, -- data de inicio da vigencia
  P.DTFIMVIGENCIA  DTAHORFIM, -- data de fim da vigencia
  D.EMBALAGEM SEQPRODUTO,
  D.QTUNIT QTDEMBALAGEM,
  0 PERCDESCONTO,
  P.PRECOFIXO  PRECO
  FROM PCPRECOPROM P,
       PCPRODUT D,
       (select min(s.ultimaexecucao) ultimaexecucao
        from pccontroleconsinco s
        where ( upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAINCENTIVO')
        ) DTPADRAO
      where NVL(P.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
        AND P.CODPROD = D.CODPROD
)