CREATE OR REPLACE VIEW VW_INT_C5_PLPAG AS
(
SELECT ora_hash(P.CODPLPAG, 999) NROCONDICAOPAGTO,
       SUBSTR(P.DESCRICAO,1,40) CONDICAOPAGTO,
       NVL(P.PERTXFIM,0) PERCACRESCIMO,
       (CASE
            WHEN P.FORMAPARCELAMENTO = 'T' 
              THEN P.NUMEROPARCELASDIAFIXO
            WHEN P.FORMAPARCELAMENTO = 'V' 
              THEN P.NUMPARCELAS
            ELSE
              0
        END) NROMAXIMOPARCELA,
       P.NUMDIAS NRODIASVENCTO,
       (CASE
            WHEN (NVL(P.STATUS,'A') = 'A' AND NVL(P.USAPLPAGAUTOSERVICO,'N') = 'S')
              THEN 'S'
            ELSE
             'N'
        END) ATIVO,
        P.CODPLPAG IDREF
FROM PCPLPAG P,
     (select min(s.ultimaexecucao) ultimaexecucao
      from pccontroleconsinco s
      where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CONDICAOPAGTO')
      ) DTPADRAO
    where NVL(P.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
)
