CREATE OR REPLACE VIEW VIEW_MED_PROMOCAO AS
SELECT PCPROMOCAOMED.CODPROMOCAOMED,
       PCPROMOCAOMED.IDENTIFICADORPROMOCAO,
       PCPROMOCAOMED.DESCRICAORESUMIDA,
       PCPROMOCAOMED.DESCRICAODETALHADA,
       PCPROMOCAOMED.DATAINICIAL,
       PCPROMOCAOMED.DATAFINAL,
       PCPROMOCAOMED.TIPOPOLITICA,
       PCPROMOCAOMED.TIPOPROMOCAO,
       CASE
         WHEN (PCPROMOCAOMED.TIPOPOLITICA IN ('Q', 'F') OR
              PCPROMOCAOMED.TIPOPROMOCAO IN ('M')) THEN
           NVL(PCPROMOCAOMED.VLRMINITENSPROMOCAO, 0)
         ELSE
           NULL
       END AS VALORMINIMO,
       PCPROMOCAOMED.TIPOPLANOPAG,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOFILMED
                    WHERE PCPROMOCAOFILMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END RESTRICAOFILIAL,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOREGIAOMED
                    WHERE PCPROMOCAOREGIAOMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END RESTRICAOREGIAO,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOPRACAMED
                    WHERE PCPROMOCAOPRACAMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') OR (NVL((SELECT 'S' AS EXISTE
                                         FROM PCPROMOCAOREDEMED
                                        WHERE PCPROMOCAOREDEMED.CODPROMOCAOMED =
                                              PCPROMOCAOMED.CODPROMOCAOMED
                                          AND ROWNUM = 1),
                                       'N') = 'S') OR
              (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOCLIMED
                    WHERE PCPROMOCAOCLIMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') OR (NVL((SELECT 'S' AS EXISTE
                                         FROM PCPROMOCAORAMOATIVMED
                                        WHERE PCPROMOCAORAMOATIVMED.CODPROMOCAOMED =
                                              PCPROMOCAOMED.CODPROMOCAOMED
                                          AND ROWNUM = 1),
                                       'N') = 'S') OR
              (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOCLASSEVENDAMED
                    WHERE PCPROMOCAOCLASSEVENDAMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') OR (NVL((SELECT 'S' AS EXISTE
                                         FROM PCPROMOCAOGRUPOCOMERCMED
                                        WHERE PCPROMOCAOGRUPOCOMERCMED.CODPROMOCAOMED =
                                              PCPROMOCAOMED.CODPROMOCAOMED
                                          AND ROWNUM = 1),
                                       'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END RESTRICAOCLIENTE,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOPLPAGMED
                    WHERE PCPROMOCAOPLPAGMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END RESTRICAOPLANO,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOCONDVENDAMED
                    WHERE PCPROMOCAOCONDVENDAMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND ROWNUM = 1),
                   'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END RESTRICAOCONDICAOVENDA,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOORIGEMMED
                    WHERE PCPROMOCAOORIGEMMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND PCPROMOCAOORIGEMMED.ORIGEMPED = 'L'
                      AND ROWNUM = 1),
                   'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END ENVIAOL,
       CASE
         WHEN (NVL((SELECT 'S' AS EXISTE
                     FROM PCPROMOCAOORIGEMMED
                    WHERE PCPROMOCAOORIGEMMED.CODPROMOCAOMED =
                          PCPROMOCAOMED.CODPROMOCAOMED
                      AND PCPROMOCAOORIGEMMED.ORIGEMPED = 'E'
                      AND ROWNUM = 1),
                   'N') = 'S') THEN
           'S'
         ELSE
           'N'
       END ENVIAPE,
       PCPROMOCAOMED.BLOQUEIO,
       CASE
         WHEN (NVL(PCPROMOCAOMED.BLOQUEIO, 'N') = 'S') THEN
           'N'
         WHEN TRUNC(SYSDATE) BETWEEN PCPROMOCAOMED.DATAINICIAL AND
              PCPROMOCAOMED.DATAFINAL THEN
           'S'
         ELSE
           'N'
       END ATIVA,
       NVL(PCPROMOCAOMED.QTMINCOMBOLIBMED, 0) QTMINCOMBOLIBMED,
       NVL(PCPROMOCAOMED.QTMAXCOMBOMED, 0) QTMAXCOMBOMED
  FROM PCPROMOCAOMED
 WHERE (NVL(PCPROMOCAOMED.BLOQUEIO, 'N') = 'N')