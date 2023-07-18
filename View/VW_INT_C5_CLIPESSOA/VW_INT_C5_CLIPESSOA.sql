CREATE OR REPLACE VIEW VW_INT_C5_CLIPESSOA AS
(
SELECT c.codcli seqpessoa,
       SUBSTR(UPPER(COALESCE(c.cliente,c.fantasia, ' ')),1,50) nomerazao,
       SUBSTR(UPPER(COALESCE(c.fantasia,c.cliente, ' ')), 1, 50) nomefantasia,
       NVL(c.tipofj,'J') fisicajuridica,
       REPLACE(REPLACE(REPLACE(c.cgcent,'.',''),'/',''),'-','') cnpjcpf,
       (CASE
            WHEN NVL(c.tipofj,'J') = 'J'
                THEN c.ieent
            ELSE
                c.rg
        END) inscrestadualrg,
       c.dtnasc dtanascimento,
       NVL(c.contribuinte,'N') contribuinteicms,
       CAST(c.orgaorg AS VARCHAR2 (6)) orgexp,
       c.sexo,
       CAST(NVL(c.emailnfe,c.email) AS VARCHAR2 (80)) email,
       (CASE
            WHEN c.dtexclusao IS NULL
                THEN 'S'
            ELSE 'N'
         END) ativo,
       NULL nroregtributacao,
       LEAST(NVL(c.limcred,0),999) vlrlimiteglobal,
       LEAST(c.qtdiasvenclimcred,999) prazomaximo,
       c.dtbloq dtahorultrestricao,
       c.obs observacao,
       (CASE
            WHEN NVL(c.limcred,0) > 0
                 AND
                 NVL(c.bloqueio,'N') = 'N'
                THEN 'L'
            ELSE
                'B'
         END) situacaocredito,
        (CASE
            WHEN NVL(c.bloqueio,'N') = 'S'
                THEN 'B'
            ELSE
                'L'
         END) situacaocomercial,
         1 nrosegmento,
       c.dtultalter,
       c.dtcadastro,
       2 codperfildestino
  FROM pcclient c,
       (SELECT LEAST(A.ultimaexecucao, B.ultimaexecucao, C.ultimaexecucao) ULTIMAEXECUCAO
         FROM (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_PESSOA') A,
       (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CLIENTE') B,
       (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CLIENTESEGMENTO') C) DTPADRAO
 WHERE c.cgcent IS NOT NULL
   
  AND NVL(C.Dtalterc5, DTPADRAO.ULTIMAEXECUCAO) >=DTPADRAO.ULTIMAEXECUCAO
   )