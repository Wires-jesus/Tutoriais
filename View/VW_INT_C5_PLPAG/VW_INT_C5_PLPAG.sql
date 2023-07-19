CREATE OR REPLACE VIEW VW_INT_C5_PLPAG AS
(
  SELECT
    pcplpag.codplpag NROCONDICAOPAGTO,
    SUBSTR(pcplpag.descricao,1,40) CONDICAOPAGTO,
    NVL(pcplpag.pertxfim,0) PERCACRESCIMO,
    (CASE WHEN pcplpag.formaparcelamento = 'T' THEN  
          pcplpag.numeroparcelasdiafixo WHEN pcplpag.formaparcelamento = 'V' THEN 
          pcplpag.numparcelas 
     ELSE 0 END) NROMAXIMOPARCELA,
    pcplpag.numdias NRODIASVENCTO,
    (CASE WHEN pcplpag.status = 'A' THEN 'S'
      ELSE 'N' END) ATIVO
  FROM PCPLPAG
  WHERE NVL(pcplpag.usaplpagautoservico,'N') = 'S'
)