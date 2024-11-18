CREATE OR REPLACE VIEW VW_INT_C5_CLI_CONV AS
(
SELECT DISTINCT
       C.CODCLI SEQPESSOAPORTADOR,
       C.CODCLI NROCARTAO, 
       C.CODCLIPRINC SEQPESSOATITULAR, 
       F.CODFINALIZADORA NROFORMAPAGTO,
       TRUNC(SYSDATE) + 100000 DTAVALIDADE,
       
       CASE
         WHEN C.DTEXCLUSAO IS NULL THEN
              'S'
         ELSE 'N'     
       END ATIVO
       
FROM PCCLIENT C, 
     (SELECT DISTINCT * FROM PCFINALIZADORA FIN, VW_INT_C5_OBTER_FILIAIS_C5 C5 WHERE FIN.CODFILIAL = C5.CODFILIAL) F
WHERE ((F.ESPECIE = 'CNV') OR ((F.ESPECIE = 'O') AND (F.CODCOB = 'CONV')))
AND F.dtinativacao IS NULL
AND ( 
      ((NVL(C.CODCLIPRINC, 0) <> 0) AND (C.CODCLIPRINC <> C.CODCLI) AND (codcliprinc is not null) and (codcliprinc in
      (select codcli from pcclient where codcli = codcliprinc and empresaconveniada = 'S'))  OR 
      (NVL(C.EMPRESACONVENIADA, 'N') = 'S') AND (C.CODCLIPRINC = C.CODCLI)
      )
    )
)
