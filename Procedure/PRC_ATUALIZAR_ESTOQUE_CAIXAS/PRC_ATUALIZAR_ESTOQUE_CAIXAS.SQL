CREATE OR REPLACE PROCEDURE PRC_ATUALIZAR_ESTOQUE_CAIXAS (pscodfilial IN VARCHAR2)
IS
/*------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data       Comentário
| -------------    ----------   ------------------------------------------------------
| Sabrina/Juliana  13/02/2008   Tarefa N.58296 - Procedure criada para efetuar validação
|                               da quantidade do estoque disponível nos caixas, exigencia
|                               resolução 001/2006 da Sefaz de Manaus-AM;
|***********************************************************************************/
   vsutilizafilialregiaocx   pcconsum.utilizafilialregiaocx%TYPE;
   vdlast_date               DATE;
   v_sql                     VARCHAR2 (3700);
   vsmensagem                VARCHAR (3700);
BEGIN
   vsmensagem := '';

   SELECT pcconsum.utilizafilialregiaocx
     INTO vsutilizafilialregiaocx
     FROM pcconsum;

   /*SELECT last_date
     INTO vdlast_date
     FROM user_jobs
    WHERE user_jobs.what LIKE '%prc_atualizar_estoque_caixas%' AND ROWNUM = 1;

   IF vdlast_date IS NULL
   THEN
      vdlast_date := TRUNC (SYSDATE) - 1;
   END IF;*/

   vdlast_date := TRUNC (SYSDATE) - 1;

   v_sql := '';

   FOR c_caixa IN (SELECT pccaixa.numcaixa
                     FROM pccaixa
                    WHERE NVL (pccaixa.codfilial, '99') =
                             DECODE (vsutilizafilialregiaocx,
                                     'S', pscodfilial,
                                     NVL (pccaixa.codfilial, '99')
                                    ))
   LOOP
      v_sql :=
            'UPDATE pcest@dblcaixa'
         || c_caixa.numcaixa
         || ' SET qtest =
          (SELECT e.qtest
             FROM pcest e
            WHERE e.codprod = pcest.codprod AND e.codfilial = pcest.codfilial),
       qtestger =
          (SELECT e.qtestger
             FROM pcest e
            WHERE e.codprod = pcest.codprod AND e.codfilial = pcest.codfilial),
       qtreserv =
          (SELECT e.qtreserv
             FROM pcest e
            WHERE e.codprod = pcest.codprod AND e.codfilial = pcest.codfilial),
       qtbloqueada =
          (SELECT e.qtbloqueada
             FROM pcest e
            WHERE e.codprod = pcest.codprod AND e.codfilial = pcest.codfilial),
       qtpendente =
          (SELECT e.qtpendente
             FROM pcest e
            WHERE e.codprod = pcest.codprod AND e.codfilial = pcest.codfilial)
 WHERE (codfilial, codprod) IN (
          SELECT pcpedc.codfilial, pcpedi.codprod
            FROM pcpedi, pcpedc
           WHERE TO_DATE (   TO_CHAR (NVL (pcpedc.dtfat,
                                           NVL (pcpedc.DATA, TRUNC (SYSDATE))
                                          ),
                                      ''dd/mm/yyyy''
                                     )
                          || '' ''
                          || TO_CHAR (NVL (pcpedc.horafat,
                                           NVL (pcpedc.hora, 0)
                                          )
                                     )
                          || '':''
                          || TO_CHAR (NVL (pcpedc.minutofat,
                                           NVL (pcpedc.minuto, 0)
                                          )
                                     ),
                          ''dd/mm/yyyy hh24:mi''
                         ) BETWEEN TO_DATE('''
         || vdlast_date
         || ''') AND SYSDATE
             AND pcpedc.codfilial = '''
         || pscodfilial
         || ''''
         || 'AND pcpedc.posicao = ''F''
             AND pcpedi.numped = pcpedc.numped)';

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT INTO pcest@dblcaixa'
         || c_caixa.numcaixa
         || ' (codfilial, codprod, qtestger, qtest, qtreserv, qtbloqueada,
             qtpendente)
   SELECT e.codfilial, e.codprod, e.qtestger, e.qtest, e.qtreserv,
          e.qtbloqueada, e.qtpendente
     FROM pcest e
    WHERE (e.codfilial, e.codprod) IN (
             SELECT pcpedc.codfilial, pcpedi.codprod
               FROM pcpedi, pcpedc
              WHERE TO_DATE (   TO_CHAR (NVL (pcpedc.dtfat,
                                              NVL (pcpedc.DATA,
                                                   TRUNC (SYSDATE)
                                                  )
                                             ),
                                         ''dd/mm/yyyy''
                                        )
                             || '' ''
                             || TO_CHAR (NVL (pcpedc.horafat,
                                              NVL (pcpedc.hora, 0)
                                             )
                                        )
                             || '':''
                             || TO_CHAR (NVL (pcpedc.minutofat,
                                              NVL (pcpedc.minuto, 0)
                                             )
                                        ),
                             ''dd/mm/yyyy hh24:mi''
                            ) BETWEEN TO_DATE('''
         || vdlast_date
         || ''') AND SYSDATE
                AND pcpedc.codfilial = '''
         || pscodfilial
         || ''''
         || '  AND pcpedc.posicao = ''F''
                AND pcpedi.numped = pcpedc.numped)
      AND NOT EXISTS (SELECT *
                        FROM pcest@dblcaixa'
         || c_caixa.numcaixa
         || ' estcaixa)';

      EXECUTE IMMEDIATE v_sql;

      COMMIT;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      vsmensagem := 'ERRO :' || SQLCODE || ' - ' || SQLERRM;
      ROLLBACK;

      INSERT INTO pclogjob
                  (modulo, funcao, tipo_log, data_log,
                   ds_job, parametros
                  )
           VALUES ('ATUALIZAR_ESTOQUE_CX', 'ESTOQUE', 'N', SYSDATE,
                   vsmensagem, pscodfilial
                  );

      COMMIT;
END;                                                              -- Procedure
