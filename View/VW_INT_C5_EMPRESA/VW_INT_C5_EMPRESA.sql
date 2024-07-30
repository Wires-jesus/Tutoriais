CREATE OR REPLACE VIEW VW_INT_C5_EMPRESA AS
(
SELECT c5.CODFILIALINTEGRACAO nroempresa,
       NVL(f.codcli,1) seqpessoa,

       (CASE
         WHEN FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S' THEN
              (SELECT TO_CHAR(R.NRODIVISAO) NRODIVISAO
               FROM   PCDEPARAREGIAOC5 R
               WHERE  R.NUMREGIAO = ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO',
                                                                       F.CODIGO,
                                                                       '1')
              )
         ELSE c5.CODFILIALINTEGRACAO     
       END) NRODIVISAO,

       --ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO',f.codigo, '1') nrodivisao,
       1 nrosegmento,
       SUBSTR(COALESCE(f.fantasia, F.RAZAOSOCIAL, ' '), 1, 20) nomereduzido,
       c5.CODFILIALINTEGRACAO nroempresamatriz,
       0 nroempresaseguranca,
       f.dtultalter,
       f.dtcadastro,
       (CASE
            WHEN f.dtexclusao IS NULL
                THEN 'S'
            ELSE
          'N'
        END) ativo,
        
        (CASE
         WHEN FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S' THEN
              (SELECT NUMREGIAO||UF 
               FROM PCREGIAO 
               WHERE NUMREGIAO = ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO', f.codigo, '1') 
              )
         ELSE f.UF     
       END) IDREF
        
  FROM  pcfilial f,
       (select min(s.ultimaexecucao) ultimaexecucao from pccontroleconsinco s
        where upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESA'
        or upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESASEGMENTO') DTPADRAO,
        VW_INT_C5_OBTER_FILIAIS_C5 c5
 WHERE f.codigo <> '99'
   AND f.codigo = c5.codfilial
   AND NVL(F.Dtalterc5, DTPADRAO.ULTIMAEXECUCAO)  >= DTPADRAO.ULTIMAEXECUCAO
)

