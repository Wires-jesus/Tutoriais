CREATE OR REPLACE VIEW VW_INT_C5_EMPRESA AS
(
SELECT f.codigo nroempresa,
       NVL(f.codcli,1) seqpessoa,
       1 nrodivisao,
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
        local.ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO',f.codigo,1) idref
  FROM local.pcfilial f,
       MONITORPDVMIDDLE.tb_divisao tbd,
       monitorpdvmiddle.tb_pessoa tbp,
       (select s.ultimaexecucao from pccontroleconsinco s where upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESA') DTPADRAO
 WHERE f.codigo >= 0
   AND f.codigo < '99'
   AND tbd.nrodivisao = 1
   AND tbp.seqpessoa = NVL(f.codcli,1)
   AND NVL(F.Dtalterc5,DTPADRAO.ULTIMAEXECUCAO)  >= DTPADRAO.ULTIMAEXECUCAO);
