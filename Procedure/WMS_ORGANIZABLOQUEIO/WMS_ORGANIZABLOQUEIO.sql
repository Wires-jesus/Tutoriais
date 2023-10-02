CREATE OR REPLACE PROCEDURE WMS_ORGANIZABLOQUEIO(PCODPROD   NUMBER,
                                                        PCODFILIAL PCFILIAL.CODIGO%TYPE) IS
BEGIN

--- PRODUTO SEM QTBLOQUEADA NA PCESTENDERECO E COM REGISTRO pcwmsbloqest
-- LIMPAR pcwmsbloqest
delete
  FROM   pcwmsbloqest b
 WHERE   b.codprod = PCODPROD AND b.qt > 0
         AND NOT EXISTS
                (SELECT   1
                   FROM   pcestendereco
                  WHERE   NVL (qtbloqueada, 0) > 0
                          AND codendereco = b.codendereco)
       AND b.tipo = 'BC';

-- COM CONTROLE DE LOTE - LIMPAR pcestenderecobloq
delete
  FROM   pcestenderecobloq b
 WHERE   b.codprod = PCODPROD
         AND NOT EXISTS
                (SELECT   1
                   FROM   pcestendereco
                  WHERE   NVL (qtbloqueada, 0) > 0
                          AND codendereco = b.codendereco)
         AND B.CODFILIAL = PCODFILIAL
         AND B.CODOPER='B';

--- PRODUTO COM QT QTBLOQUEADA NA PCESTENDERECO <> DA QT pcwmsbloqest  e pcestenderecobloq

-- update pcwmsbloqest qtbloqueada da pcestendereco


       UPDATE pcwmsbloqest b
          SET QT = (SELECT   QTbloqueada   FROM   pcestendereco
                  WHERE   codendereco = b.codendereco and codprod = b.codprod)
       WHERE   b.codprod = PCODPROD AND b.qt > 0
      AND (SELECT   QTbloqueada   FROM   pcestendereco
                  WHERE   codendereco = b.codendereco and codprod = b.codprod)
                           <> B.QT
       AND b.tipo = 'BC';


-- COM CONTROLE DE LOTE - update pcestenderecobloq,  qtbloqueada da pcestendereco
delete from   pcestenderecobloq  c
where c.codendereco in (SELECT A.CODENDERECO
         FROM (SELECT CODPROD,QTBLOQUEADA,CODENDERECO FROM PCESTENDERECO WHERE CODPROD = PCODPROD AND NVL(QTBLOQUEADA,0)>0) A,
         (select CODPROD,SUM(QT)QTS,CODENDERECO from pcestenderecobloq where codoper='B' AND CODPROD = PCODPROD AND CODFILIAL = PCODFILIAL  GROUP BY CODPROD, CODENDERECO) B
         WHERE A.CODPROD=B.CODPROD
         AND A.CODENDERECO=B.CODENDERECO
         AND A.QTBLOQUEADA<>B.QTS)
         AND C.CODFILIAL = PCODFILIAL ;

end;
