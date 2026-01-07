create or replace view view_validar_saltos_nsus as
SELECT codfilial,
       ambiente,
       nsu_anterior,
       nsu_atual,
       (nsu_atual - nsu_anterior - 1) AS qtd_nsu_pulados,
       (nsu_anterior + 1) AS nsu_inicio_salto,
       (nsu_atual - 1) AS nsu_fim_salto,
       data_requisicao
  FROM (SELECT codfilial,
               ambiente,
               nsu AS nsu_atual,
               LAG(nsu) OVER(PARTITION BY codfilial, ambiente ORDER BY nsu) AS nsu_anterior,
               datarequisicao AS data_requisicao
          FROM pcretconsmanifdest
         WHERE trunc(datarequisicao) > to_date('01/01/2013', 'dd/mm/yyyy'))
 WHERE nsu_anterior IS NOT NULL
   AND nsu_atual - nsu_anterior > 1
 ORDER BY nsu_anterior