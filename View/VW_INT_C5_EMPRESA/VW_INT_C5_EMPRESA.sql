CREATE OR REPLACE VIEW VW_INT_C5_EMPRESA AS
(
SELECT f.codigo nroempresa,
       NVL(f.codcli,1) seqpessoa,
       1 nrodivisao,
       1 nrosegmento,
       SUBSTR(COALESCE(f.fantasia, F.RAZAOSOCIAL, ' '), 1, 20) nomereduzido,
       f.codigo nroempresamatriz,
       0 nroempresaseguranca,
       (CASE
            WHEN f.dtexclusao IS NULL
                THEN 'S'
            ELSE
          'N'
        END) ativo
      
  FROM pcfilial f,
       (SELECT LEAST(A.ultimaexecucao, B.ultimaexecucao) ULTIMAEXECUCAO
         FROM (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESA') A,
              (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESASEGMENTO') B
       ) DTPADRAO
       
       --(select s.ultimaexecucao from pccontroleconsinco s where upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESA') DTPADRAO
 WHERE f.codigo >= 0
   AND f.codigo < '99'
   AND NVL(F.Dtalterc5,DTPADRAO.ULTIMAEXECUCAO)  >= DTPADRAO.ULTIMAEXECUCAO)
