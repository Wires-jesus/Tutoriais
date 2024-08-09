CREATE OR REPLACE VIEW VW_INT_C5_LIMITEVENDAFAMILIA AS
SELECT 1 SEQLIMITEVENDA,
       OFERTAS.SEQFAMILIA,
       (NVL(MAX(OFERTAS.QTMAXVENDA), 0) * NVL(MAX(OFERTAS.QTUNIT), 1)) QTDLIMITE,
       CASE
         WHEN (NVL(MAX(OFERTAS.QTMAXVENDA), 0) * NVL(MAX(OFERTAS.QTUNIT), 1)) > 0 THEN
          'S'
         ELSE
          'N'
       END ATIVO
  FROM ( SELECT DISTINCT PROD.SEQFAMILIA,
                NVL(I.QTMAXVENDA, NVL(EMB.QTMAXVENDA,0)) QTMAXVENDA,
                NVL(EMB.qtunit,1) QTUNIT
                FROM VW_INT_C5_EMBPROD EMB,
                     PCOFERTAPROGRAMADAC C,
                     PCOFERTAPROGRAMADAI I,
                     PCDEPARAPRODC5 DEPARA,
                     MONITORPDVMIDDLE.TB_PRODUTO PROD
                     WHERE C.CODOFERTA = I.CODOFERTA
                     AND I.CODPROD = EMB.codprod
                     AND I.CODAUXILIAR = EMB.codauxiliar
                     AND TRUNC(SYSDATE) BETWEEN TRUNC(C.DTINICIAL) AND TRUNC (C.DTFINAL)
                     AND PROD.SEQPRODUTO = DEPARA.SEQPRODUTO
                     AND DEPARA.CODPROD = EMB.CODPROD
                     AND DEPARA.ATIVO = 'S'
                     AND (DEPARA.CODAUXILIAR = 0 OR DEPARA.CODAUXILIAR = EMB.codauxiliar)
                     
                     UNION ALL
         SELECT DISTINCT PROD.SEQFAMILIA,
                NVL(EMB.QTMAXVENDA,0) QTMAXVENDA,
                EMB.qtunit QTUNIT
                FROM VW_INT_C5_EMBPROD EMB,
                     PCDEPARAPRODC5 DEPARA,
                     MONITORPDVMIDDLE.TB_PRODUTO PROD
                     WHERE PROD.SEQPRODUTO = DEPARA.SEQPRODUTO
                     AND DEPARA.CODPROD = EMB.CODPROD
                     AND DEPARA.ATIVO = 'S'
                     AND (DEPARA.CODAUXILIAR = 0 OR DEPARA.CODAUXILIAR = EMB.codauxiliar) ) OFERTAS
                     GROUP BY OFERTAS.SEQFAMILIA
