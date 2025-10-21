CREATE OR REPLACE VIEW VW_INT_C5_USUARIO_GRUPO AS
(
SELECT DISTINCT
      GRUPO.valor CODGRUPO,
      GRUPO.NOMEGRUPO NOMEGRUPO,
      FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_PERMAXDESCITEMCF', '99', 0) PERCDESCMAX,
      'S' ATIVO
FROM
    (SELECT valor, 'OPERADOR DE CAIXA' NOMEGRUPO
      FROM pcparamfilial
      WHERE nome = 'CON_CODSETOROPERCX'
      AND codfilial = '99'
      UNION ALL
      SELECT valor, 'FISCAL DE CAIXA' NOMEGRUPO
      FROM pcparamfilial
      WHERE nome = 'CON_CODSETORFISCALCX'
      AND codfilial = '99'
    ) GRUPO
)

\

CREATE OR REPLACE VIEW VW_INT_C5_USUARIO AS
(
  SELECT R.CODFILIAL,
        R.CODUSUR,
        R.MATRICULA SEQUSUARIO,
        T.SEQPESSOA,
        SUBSTR(R.NOME, 1, 40) NOME,
        SUBSTR(NVL(R.NOME_GUERRA, R.NOME), 1, 30) APELIDO,
        (CASE
          WHEN REGEXP_LIKE(DECRYPT(SENHABD, USUARIOBD),'\D+') THEN
            TO_CHAR(PKG_CRC32.CALCULATE('0'))
          ELSE
            TO_CHAR(PKG_CRC32.CALCULATE(DECRYPT(R.SENHABD, R.USUARIOBD))) 
        END) SENHA,  
        (CASE
            WHEN R.CODSETOR = G.CODGRUPO THEN 0
            ELSE 1
        END) NIVEL,
        R.DTEXPIRASENHA DTAEXPIRAR,
        (CASE
            WHEN NVL(R.PERDESCMAXITEM, 0) > 0 THEN R.PERDESCMAXITEM
            WHEN TO_NUMBER(G.PERCDESCMAX) > 0 THEN G.PERCDESCMAX
            ELSE 0
        END) PERCDESCMAXIMO,
        SUBSTR(R.EMAIL, 80) EMAIL,
        (CASE
            WHEN R.DT_EXCLUSAO IS NULL AND NVL(R.SITUACAO, 'A') = 'A' THEN 'S'
            ELSE 'N'
        END) ATIVO,
        R.CODSETOR CODGRUPO,
        R.FUNCAO NOMEGRUPO,
        G.PERCDESCMAX
  FROM PCEMPR R
  
  INNER JOIN VW_INT_C5_USUARIO_GRUPO G
  ON (R.CODSETOR = G.CODGRUPO)
  
  LEFT JOIN (SELECT DISTINCT MIN(SEQPESSOA) SEQPESSOA , REGEXP_REPLACE(CNPJCPF, '[^0-9]', '') CNPJCPF, 
                    MAX(DTAHORALTERACAO) DTAHORALTERACAO 
               FROM MONITORPDVMIDDLE.TB_PESSOA 
              WHERE ATIVO = 'S' 
              GROUP BY REGEXP_REPLACE(CNPJCPF, '[^0-9]', '') ) T 
  ON (REGEXP_REPLACE(R.CPF, '[^0-9]', '') = REGEXP_REPLACE(T.CNPJCPF, '[^0-9]', '') ),

   PCUSUARI I,
    (SELECT MIN(S.ULTIMAEXECUCAO) ULTIMAEXECUCAO
    FROM PCCONTROLECONSINCO S
    WHERE  (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_USUARIO')
        OR (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_GRUPOUSUARIO')
    ) DTPADRAO
    WHERE R.CODUSUR = I.CODUSUR
      AND I.CODSUPERVISOR IS NOT NULL
      AND R.CODUSUR > 0
      AND R.MATRICULA > 0
	  AND R.SENHABD IS NOT NULL
	  AND R.USUARIOBD IS NOT NULL
      AND (NVL(R.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
        OR CODSETOR IN (SELECT
                          CODGRUPO
                        FROM VW_INT_C5_USUARIO_GRUPO V
                        LEFT JOIN MONITORPDVMIDDLE.TB_GRUPO G
                        ON (G.SEQGRUPO = V.CODGRUPO AND G.ATIVO = 'S')
                        LEFT JOIN MONITORPDVMIDDLE.TB_GRUPOUSUARIO GU
                        ON (GU.SEQGRUPO = V.CODGRUPO AND GU.ATIVO = 'S')
                        WHERE G.SEQGRUPO IS NULL OR GU.SEQGRUPO IS NULL)
        OR T.DTAHORALTERACAO >= DTPADRAO.ULTIMAEXECUCAO
     )
)

\

CREATE OR REPLACE VIEW VW_INT_C5_CLIPESSOA AS
(
SELECT c.codcli seqpessoa,
       SUBSTR(UPPER(COALESCE(c.cliente,c.fantasia, ' ')),1,50) nomerazao,
       SUBSTR(UPPER(COALESCE(c.fantasia,c.cliente, ' ')), 1, 50) nomefantasia,
       CASE WHEN c.tipofj IS NULL THEN
         CASE WHEN LENGTH(FERRAMENTAS.SONUMEROS(c.cgcent)) = 11 THEN
             'F'
           ELSE
             'J' 
           END
         ELSE
           c.tipofj
         END fisicajuridica,
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

\

CREATE or REPLACE VIEW VW_INT_C5_GRUPOPESSOA AS (
SELECT 
  CODGRUPOFIDELIDADE SEQGRUPOPESSOA,
  GRUPOFIDELIDADE DESCRICAO,
  'S' ATIVO
  FROM PCGRUPOFIDELIDADE
)

\

CREATE or REPLACE VIEW VW_INT_C5_PESSOAGRUPO AS (
SELECT 
  CODGRUPOFIDELIDADE SEQGRUPOPESSOA,
  CODCLI SEQPESSOA,
  'S' ATIVO
  FROM PCGRUPOFIDELIDADECLIENTE
)

\

CREATE OR REPLACE VIEW VW_INT_C5_ENDERECO_ALTERNATIVO AS(
  SELECT
    f.codigo codfilial,
    f.codcli seqpessoa,
    f.codcli || f.codfilialintegracao seqlogradouro,
    'P' tipo,
    UPPER(
      SUBSTR(
        NVL(NVL(c.numeroent, c.numerocob), f.numero2)
        ,1
        ,10)
    ) nrologradouro,
    UPPER(
      SUBSTR(
        NVL(NVL(c.enderent,c.endercob),f.endereco)
        ,1
        ,60)
    ) logradouro,
    UPPER(
    SUBSTR(
      NVL(NVL(c.bairroent,c.bairrocob),f.bairro)
        ,1
        ,50)
    ) bairro,
    UPPER(
      SUBSTR(
        NVL(NVL(c.complementoent,c.complementocob),f.complementoendereco)
        ,1
        ,60)
    ) complemento,
    UPPER(
      SUBSTR(
        NVL(NVL(c.municent,c.municcob),f.cidade)
        ,1
        ,60)
    ) cidade,
    UPPER(
      SUBSTR(
        NVL(NVL(c.estent,c.estcob),f.uf)
        ,1
        ,2)
    ) uf,
    TO_NUMBER(REPLACE(nvl(nvl(c.cepent, c.cepcob), f.cep), '-', '')) cep,
    (CASE WHEN c.dtexclusao IS NOT NULL THEN 'N' ELSE 'S' END) ativo,
    UPPER(NVL(c.codmunicipio,f.codmun)) codibge
  FROM PCFILIAL F
  INNER JOIN PCCLIENT C
  ON (C.CODCLI = F.CODCLI AND C.CODCLI > 0 AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USAINTEGRACAOCONSINCO', F.CODIGO, 'N') = 'S'),

  (
    SELECT
      MIN(S.ULTIMAEXECUCAO) ULTIMAEXECUCAO
    FROM
      PCCONTROLECONSINCO S
    WHERE
      UPPER(S.OBJETOREFERENCIA) IN ( 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_ENDERECOALTERNATIVO')
  ) D
  WHERE
    NVL(F.DTALTERC5, D.ULTIMAEXECUCAO) >= D.ULTIMAEXECUCAO
    OR NVL(C.DTALTERC5, D.ULTIMAEXECUCAO) >= D.ULTIMAEXECUCAO
)