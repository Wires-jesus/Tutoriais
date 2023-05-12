CREATE OR REPLACE TRIGGER TR_WMS_GERARWMSAUTOMATICO
 AFTER 
 INSERT
 ON PCNFSAID
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
DECLARE
   vgerawmsautomatico              pcparametrowms.valor%TYPE;
   vgerawmsautomaticovendabalcao   pcparametrowms.valor%TYPE;
   vnumped                         pcpedc.numped%TYPE;
   vfilialusawms                   pcfilial.usawms%TYPE;
BEGIN
   IF (:NEW.rotinalanc = 'AutoServico.Faturamento.exe') OR (:NEW.rotinalanc LIKE '%2030%') OR (:NEW.numped > 0)
   THEN
      BEGIN                                                      --Parametros
         SELECT NVL (valor, 'N')
           INTO vgerawmsautomatico
           FROM pcparametrowms
          WHERE nome IN ('GERARWMSAUTOMATICOPARAAUTOSERVICO')
            AND codfilial = :NEW.codfilial;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vgerawmsautomatico := 'N';
      END;

      IF vgerawmsautomatico = 'S'
      THEN
         BEGIN                                 --Filial do pedido utiliza WMS
            SELECT NVL (usawms, 'N')
              INTO vfilialusawms
              FROM pcfilial
             WHERE codigo IN (
                           SELECT MAX (NVL (i.codfilialretira, c.codfilial))
                             FROM pcpedi i, pcpedc c
                            WHERE i.numped = c.numped
                                  AND c.numped = :NEW.numped);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               vfilialusawms := 'N';
         END;

         IF vfilialusawms = 'S'
         THEN
            BEGIN                                                --Parametros
               SELECT DECODE (NVL (valor, 'N'), 'N', 'A', 'B')
                 INTO vgerawmsautomaticovendabalcao
                 FROM pcparametrowms
                WHERE nome IN ('GERAWMSAUTOMATICOVENDABALCAO')
                  AND codfilial = :NEW.codfilial;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  vgerawmsautomaticovendabalcao := 'N';
            END;

            --Ilquias - Devido autosservico faturar todas as origens exceto B
            IF ((:NEW.rotinalanc = 'AutoServico.Faturamento.exe') OR (:NEW.rotinalanc LIKE '%2030%')) and (vgerawmsautomaticovendabalcao in ('B', 'A'))
            THEN
               SELECT origemped
                 INTO vgerawmsautomaticovendabalcao
                 FROM pcpedc
                WHERE numped = :NEW.numped;
            END IF;

            FOR reg IN (SELECT DISTINCT (NVL (c.numped, 0)) numped
                                   FROM pcpedc c
                                  WHERE c.numped = :NEW.numped
                                    AND c.dtwms IS NULL
                  AND nvl(c.condvenda,0) NOT IN (4, 7, 14) --venda igual 4 é simples remessa, e gera somente o contabil.
                                    AND (   (c.origemped = 'A')
                                         OR (c.origemped = vgerawmsautomaticovendabalcao
                                            )
                                        )
                                    AND NOT EXISTS (
                                                 SELECT 1
                                                   FROM pcwms
                                                  WHERE pcwms.numped = c.numped
                                                       AND PCWMS.CODFILIAL = C.CODFILIAL
                                                       AND PCWMS.CODOPER = 'S'))
            LOOP
               IF reg.numped > 0
               THEN
                  BEGIN
                  insert into PCLOGALTERACAODADOS
                  (DATA,
                   TABELA,
                   COLUNA,
                   TIPOVALOR,
                   VALORALFA,
                   TERMINAL,
                   MAQUINA,
                   PROGRAMA,
                   OSUSER,
                   OBSERVACOES2,
                   OBSERVACOES)
                 values
                  (sysdate,
                   'PCNFSAID',
                   'TR_WMS_GERARWMSAUTOMATICO',
                   '',
                   '',
                   SYS_CONTEXT('USERENV', 'TERMINAL'),
                   SYS_CONTEXT('USERENV', 'HOST'),
                   SYS_CONTEXT('USERENV', 'MODULE'),
                   SYS_CONTEXT('USERENV', 'OS_USER'),

                   'NUMPED_PASSADO_TR_WMS_GERARWMSAUTOMATICO=' || TO_CHAR(:NEW.numped) ||
                   ', NUMPED_PASSADO_wms_gera_movimentacao=' || TO_CHAR(reg.numped),

                   'wms_gera_movimentacao');

                  EXCEPTION
                    WHEN OTHERS THEN
                      vgerawmsautomaticovendabalcao := 'N';
                  END;
                  wms_gera_movimentacao (reg.numped, 1700);
               END IF;
            END LOOP;
         END IF;
      END IF;
   END IF;
END;
