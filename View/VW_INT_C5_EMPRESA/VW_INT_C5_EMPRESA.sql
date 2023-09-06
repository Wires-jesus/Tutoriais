CREATE OR REPLACE VIEW VW_INT_C5_EMPRESA AS
(
SELECT f.codigo nroempresa,
       NVL(f.codcli,1) seqpessoa,
       
       (SELECT R.NRODIVISAO
        FROM   PCDEPARAREGIAOC5 R
        WHERE  R.NUMREGIAO = ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO', 
                                                               F.CODIGO, 
                                                              '1') 
       )NRODIVISAO,
       
       --ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO',f.codigo, '1') nrodivisao,
       1 nrosegmento,
       SUBSTR(COALESCE(f.fantasia, F.RAZAOSOCIAL, ' '), 1, 20) nomereduzido,
       f.codigo nroempresamatriz,
       0 nroempresaseguranca,
       f.dtultalter,
       f.dtcadastro,
       (CASE
            WHEN f.dtexclusao IS NULL
                THEN 'S'
            ELSE
          'N'
        END) ativo,
        (SELECT NUMREGIAO||UF FROM PCREGIAO WHERE NUMREGIAO = ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO', f.codigo, '1') ) idref
  FROM  pcfilial f,
       (select min(s.ultimaexecucao) ultimaexecucao from pccontroleconsinco s
        where upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESA'
        or upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESASEGMENTO') DTPADRAO
 WHERE f.codigo >= '0'
   AND f.codigo < '99'
   AND NVL(F.Dtalterc5, DTPADRAO.ULTIMAEXECUCAO)  >= DTPADRAO.ULTIMAEXECUCAO

)