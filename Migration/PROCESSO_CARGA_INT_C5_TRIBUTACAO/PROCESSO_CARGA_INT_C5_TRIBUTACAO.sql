CREATE OR REPLACE VIEW VW_INT_C5_TRIB_UF AS
(SELECT     distinct
            t.codst nrotributacao,
            c.UFORIGEM uforigem,
            c.UFDESTINO ufdestino,
            'SN' tipotributacao,
            0 nroregtributacao,
            c.percaliquota,
            (case
              when (Length(NVL(t.sittributecf, t.sittributpf))) = 2 then
                   '0' || NVL(t.sittributecf, t.sittributpf) 
              else NVL(t.sittributecf, t.sittributpf)
            end)  situacaotributacao,
            c.percisento,
            c.perctributado,
            c.percoutro,
            0 percacrescst,
            NVL(t.aliqstsaida,0) percisentost,
            'B' tipocalcfcp,
            NVL(C.percaliqfcpicms, t.peracrescimofuncep) percaliqfcpicms,

            (case
               when NVL(C.percaliqfcpicms, t.peracrescimofuncep) > 0 THEN
                    100
               else  0
            end) percbasefcpicms,

            c.reducaobasest,
            'T' tiporeducaoicmscalcst,
            0 perctributst,
            'S' ativo,
            0 situacaopis,
            0 situacaocofins,
            0 percpis,
            0 perccofins,
            0 percbasefcpst,
            0 percaliqfcpst,
            c.calcicmsdeson,
            c.percdesoneracao percaliqicmsdeson,
            c.codmotivodesoneracao motivodesonicms,
            c.codbeneficiofiscal codbeneficiodesonicms,
            t.codst||(SELECT TO_NUMBER(CODIBGE) FROM PCESTADO WHERE UF = C.UFORIGEM) codobservacao,
            t.codst,
            t.mensagem || ' - TRIBUTACAO' tributacao,
            t.mensagem || ' - TRIBUTACAO' descaplicacao,
            COALESCE(t.codecf, '0000') codecf,
            GREATEST(
                     NVL(t.DTALTERC5, d.datapadrao),
                     NVL(c.DTALTERC5, d.datapadrao)) data,

            COALESCE(c.aliqicms1,0) aliqicms1,
            COALESCE(c.aliqicms2,0) aliqicms2
FROM pctribut t,
     PCCONSOLIDATRIBUTACAO c,
     (SELECT MIN(s.ultimaexecucao) datapadrao FROM pccontroleconsinco s) d

WHERE t.codst = c.codst
AND t.codecf IS NOT NULL
AND t.codst is not null)

\

CREATE OR REPLACE VIEW VW_INT_C5_TRIB_UF_CONSOLIDADA AS
(
SELECT  distinct
        NROTRIBUTACAO,
        UFORIGEM,
        UFDESTINO,
        'SN' TIPOTRIBUTACAO,
        NROREGTRIBUTACAO,
        PERCALIQUOTA,
        SITUACAOTRIBUTACAO,
        PERCISENTO,
        PERCTRIBUTADO,
        PERCOUTRO,
        PERCACRESCST,
        PERCISENTOST,
        TIPOCALCFCP,
        PERCBASEFCPICMS,
        PERCALIQFCPICMS,
        REDUCAOBASEST,
        TIPOREDUCAOICMSCALCST,
        PERCTRIBUTST,
        ATIVO,
        PERCBASEFCPST,
        PERCALIQFCPST,
        CALCICMSDESON,
        PERCALIQICMSDESON,
        MOTIVODESONICMS,
        NULL CODBENEFICIODESONICMS,
        CODOBSERVACAO,
        CODBENEFICIODESONICMS IDREF--(SELECT TO_NUMBER(CODIBGE) FROM PCESTADO WHERE UF = UFORIGEM) IDREF
  FROM VW_INT_C5_TRIB_UF
 WHERE DATA >= (SELECT MIN(S.ULTIMAEXECUCAO)  ULTIMAEXECUCAO
                FROM PCCONTROLECONSINCO S 
                WHERE (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_TRIBUTACAOUF')
                or    (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CADOBS')
                or    (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CADOBSSPED')
                or    (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CADOBSSPEDFAMILIA')
               )
 AND LENGTH(SITUACAOTRIBUTACAO) <= 3 --Não considerar CST de Simples Nacional que pode estar com 4 digitos             
)

\

CREATE OR REPLACE VIEW VW_TB_TRIBUTACAO_CONSOLIDADA AS
(
SELECT NROTRIBUTACAO,
       CODST,
       TRIBUTACAO,
       DESCAPLICACAO,
       CODECF,
       ATIVO,
       DATA,
       ALIQICMS1,
       ALIQICMS2
  FROM VW_INT_C5_TRIB_UF 
 WHERE DATA >= (SELECT MIN(S.ULTIMAEXECUCAO) FROM PCCONTROLECONSINCO S WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_TRIBUTACAO'))

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMDIVISAO AS
(
 SELECT
    PRODTRIB."SEQFAMILIA", PRODTRIB."CODPROD", PRODTRIB."NROTRIBUTACAO",PRODTRIB."NRODIVISAO",PRODTRIB."IDREF",PRODTRIB."ATIVO", PRODTRIB."CODORIGEMTRIB"
 FROM
     (SELECT DISTINCT
        R.CODPROD,
        T.SEQFAMILIA,
        R.CODST nrotributacao,
        0 codorigemtrib,
        D.NRODIVISAO,
        D.NUMREGIAO IDREF,
        'S' ativo
      FROM MONITORPDVMIDDLE.TB_FAMILIA T,
           MONITORPDVMIDDLE.TB_TRIBUTACAOUF F,
           PCTABPR R,
           PCCONSOLIDATRIBUTACAO C,
           PCDEPARAREGIAOC5 D
      WHERE T.IDREF = R.CODPROD
      AND   R.CODST = C.CODST
      AND   R.CODST = F.NROTRIBUTACAO
      AND   C.CODST = F.NROTRIBUTACAO
      AND   R.NUMREGIAO = C.NUMREGIAO
      AND   R.NUMREGIAO = D.NUMREGIAO
      AND   C.NUMREGIAO = D.NUMREGIAO
      AND   R.CODST IS NOT NULL
      AND   R.NUMREGIAO IN (SELECT VALOR
                            FROM PCPARAMFILIAL
                            WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                            AND VALOR <> '99'
                            AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                            AND VALOR IS NOT NULL)
      AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
      --GROUP BY R.CODPROD, R.CODST, D.NRODIVISAO, D.NUMREGIAO
      GROUP BY T.SEQFAMILIA, R.CODPROD, R.CODST, D.NRODIVISAO, D.NUMREGIAO

      UNION ALL
      
      SELECT DISTINCT
        TB.CODPROD,
        T.SEQFAMILIA,
        TB.CODST nrotributacao,
        0 codorigemtrib,
        --D.NRODIVISAO,
        --D.NRODIVISAO IDREF,
         TO_NUMBER(FIL.CODIGO) NRODIVISAO,
         TO_NUMBER(FIL.CODIGO) IDREF,
        'S' ativo
      FROM MONITORPDVMIDDLE.TB_FAMILIA T,
           MONITORPDVMIDDLE.TB_TRIBUTACAOUF F,
           MONITORPDVMIDDLE.TB_EMPRESA E,
           PCFILIAL FIL,
           PCTABTRIB TB,
           PCCONSOLIDATRIBUTACAO C,
           --PCDEPARAREGIAOC5 D,
           VW_INT_C5_OBTER_FILIAIS_C5 c5
      WHERE T.IDREF = TB.CODPROD
      AND   F.NROTRIBUTACAO = TB.CODST
      AND   F.UFORIGEM = TB.UFDESTINO
      AND   E.NROEMPRESA = TB.CODFILIALNF
      AND   C.CODST = TB.CODST
      AND   C.NUMREGIAO = TB.CODFILIALNF
      AND   C.UFORIGEM = TB.UFDESTINO
      --AND   D.NUMREGIAO = TB.CODFILIALNF
      AND   C5.CODFILIAL = TB.CODFILIALNF
      AND   FIL.UF = TB.UFDESTINO
      AND   FIL.CODIGO = TB.CODFILIALNF
      AND   F.NROTRIBUTACAO = C.CODST
      AND   F.UFORIGEM = C.UFORIGEM
      AND   E.NROEMPRESA = C.NUMREGIAO
      --AND   E.NROEMPRESA = D.NUMREGIAO
      AND   E.NROEMPRESA = C5.CODFILIAL
      --AND   C.NUMREGIAO  = D.NUMREGIAO
      AND   C.NUMREGIAO = C5.CODFILIAL
      --AND   D.NUMREGIAO = C5.CODFILIAL
      AND   FIL.CODIGO  = C5.CODFILIAL
      AND   FIL.CODIGO  = E.NROEMPRESA
      AND   FIL.CODIGO = C.NUMREGIAO
      --AND   FIL.CODIGO = D.NUMREGIAO
      AND   TB.CODST IS NOT NULL
      AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S'
      --GROUP BY TB.CODPROD, TB.CODST, D.NRODIVISAO, D.NUMREGIAO
      --GROUP BY TB.CODPROD, TB.CODST, FIL.CODIGO
      GROUP BY T.SEQFAMILIA, TB.CODPROD, TB.CODST, FIL.CODIGO
      )PRODTRIB    
     
 /*SELECT
    PRODTRIB."SEQFAMILIA",PRODTRIB."NROTRIBUTACAO",PRODTRIB."NRODIVISAO",PRODTRIB."IDREF",PRODTRIB."ATIVO", PRODTRIB."CODORIGEMTRIB"
 FROM
     (SELECT DISTINCT
        R.CODPROD seqfamilia,
        R.CODST nrotributacao,
        MIN(NVL(F.origmerctrib, 0)) codorigemtrib,
        D.NRODIVISAO,
        D.NUMREGIAO IDREF,
        'S' ativo
      FROM MONITORPDVMIDDLE.TB_FAMILIA T,
           PCPRODFILIAL F,
           VW_INT_C5_OBTER_FILIAIS_C5 c5,
           PCTABPR R,
           PCCONSOLIDATRIBUTACAO C,
           PCDEPARAREGIAOC5 D
      WHERE T.SEQFAMILIA = R.CODPROD
      AND   R.CODST = C.CODST
      AND   F.CODPROD = T.SEQFAMILIA
      AND   F.CODPROD = R.CODPROD
      AND   F.CODFILIAL = C5.CODFILIAL
      AND   R.NUMREGIAO = C.NUMREGIAO
      AND   R.NUMREGIAO = D.NUMREGIAO
      AND   C.NUMREGIAO = D.NUMREGIAO
      AND   R.CODST IS NOT NULL
      AND   R.NUMREGIAO IN (SELECT VALOR
                            FROM PCPARAMFILIAL
                            WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                            AND VALOR <> '99'
                            AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                            AND VALOR IS NOT NULL)
      GROUP BY R.CODPROD, R.CODST, D.NRODIVISAO, D.NUMREGIAO                              
      )PRODTRIB*/
 )

 \

CREATE OR REPLACE VIEW VW_INT_C5_CODGERALOPER AS
(SELECT 65  codgeraloper,
        SUBSTR(UPPER(O.desccfo),1,40)    descricao,
        SUBSTR(UPPER(O.desccfo),1,80)    aplicacao,
        5102                             cfopestado,
        6102                             cfopforaestado,
        'N'                              calculaicmsst,
        'N'                              gerareducaobasest,
        'N'                              calculaipi,
        'N'                              tipocalculoipi,
        'N'                              calculafecp,
        'T'                              tipofaturamento,
        'S'                              ativo,
         O.dtalterc5                     dtalterc5,
        'N'                              consumidorfinal,
        'N'                              vendapresencial,
        'P'                              tipotributacao,
        'S'                              gerareducaobasepiscofins
 FROM  PCCFO O,
       
       (select min(s.ultimaexecucao) ultimaexecucao
        from pccontroleconsinco s
        where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CODGERALOPER')
       )DTPADRAO

 WHERE O.codfiscal = 5102
 AND   NVL(O.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO)

 \

CREATE OR REPLACE VIEW VW_INT_C5_CODGERALOPERCFOP AS
(SELECT   65      codgeraloper,
          T.CODST nrotributacao,
          'N'     contribicms,
          T.CODFISCAL  cfopestado,
          T.CODFISCALINTER cfopforaestado,
          'S' ativo,
          T.DTALTERC5 dtalterc5
FROM  PCTRIBUT T,
      
     (select s.ultimaexecucao
      from pccontroleconsinco s
      where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CODGERALOPERCFOP')
     )DTPADRAO
--WHERE  NVL(T.SITTRIBUTECF, T.SITTRIBUTPF) IN ('00','20','40','41','60','61','90')
WHERE NVL(T.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
AND   T.CODFISCAL IS NOT NULL

)

\

CREATE OR REPLACE VIEW VW_INT_C5_CADOBS AS
(
 SELECT DISTINCT
     T.CODOBSERVACAO,
     'N' INFORMADOTRIBUF,
     'S' GERACBENEFFAMTRIB,
     'S' ATIVO
 FROM Vw_Int_C5_Trib_Uf_Consolidada T
 WHERE T.IDREF IS NOT NULL
)

\

CREATE OR REPLACE VIEW VW_INT_C5_CADOBSSPED AS
(
SELECT DISTINCT
  T.CODOBSERVACAO||(SELECT TO_NUMBER(CODIBGE) FROM PCESTADO WHERE UF = T.UFORIGEM) SEQOBSSPED,
  T.CODOBSERVACAO,
  T.IDREF CODAJUSTEEFD,
  'S' USACODAJUSTENFE,
  'A' REGISTRO,
  'S' ATIVO
FROM Vw_Int_C5_Trib_Uf_Consolidada T
WHERE T.IDREF IS NOT NULL
)

\

CREATE OR REPLACE VIEW VW_INT_C5_CADOBSSPEDFAMILIA AS
(

SELECT
  *
FROM (  
     SELECT 
        ROW_NUMBER() OVER(partition by FAM.SEQFAMILIA,  S.SEQOBSSPED  order BY  E.CODEXCECAO) sequencia,
        FAM.SEQFAMILIA,
        E.CODEXCECAO,
        S.SEQOBSSPED,
        E.CODCADASTROPRINC,
        E.CODCADASTROEXCECAO CODAJUSTEEFD,
        T.UFORIGEM UF,
        E.TIPO1,
        E.VALOR1,
        'S' ATIVO,
        E.TIPO1||E.VALOR1 IDREF
     FROM MONITORPDVMIDDLE.TB_CADOBSSPED S,
          MONITORPDVMIDDLE.TB_FAMILIA FAM,
          MONITORPDVMIDDLE.tb_famdivisao D,
          MONITORPDVMIDDLE.TB_TRIBUTACAOUF T,
          PCEXCECAOCADASTROSFISCAIS E,
          pcdepararegiaoc5 R
          --VW_INT_C5_TRIB_UF_CONSOLIDADA T
     WHERE S.CODAJUSTEEFD = E.CODCADASTROPRINC
     AND   D.seqfamilia = FAM.SEQFAMILIA
     AND   T.NROTRIBUTACAO = D.nrotributacao
     AND   T.IDREF = E.CODCADASTROPRINC
     AND   T.CODOBSERVACAO = S.CODOBSERVACAO
     --AND   NVL(E.VALOR1, '0') = (DECODE(NVL(E.TIPO1,'XX'), 'PR', TO_CHAR(FAM.SEQFAMILIA), 'FT', TO_CHAR(D.nrotributacao), 'CM', TO_CHAR(FAM.codnbmsh)))
     AND   NVL(E.VALOR1, '0') = (DECODE(NVL(E.TIPO1,'XX'), 'PR', TO_CHAR(FAM.IDREF), 'FT', TO_CHAR(D.nrotributacao), 'CM', TO_CHAR(FAM.codnbmsh)))
     AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
     AND   R.nrodivisao = D.nrodivisao
     AND   R.NUMREGIAO = (SELECT MIN(TO_CHAR(VALOR)) VALOR
                          FROM PCPARAMFILIAL
                          WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                          AND VALOR <> '99'
                          AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                          AND VALOR IS NOT NULL
                          --AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
                          HAVING MIN(VALOR) IS NOT NULL
                          
                          /*UNION ALL
                          
                          SELECT TO_CHAR(NROEMPRESA) VALOR 
                          FROM MONITORPDVMIDDLE.TB_EMPRESA 
                          WHERE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S' 
                          AND ROWNUM = 1*/)
                          
     UNION ALL
     
     SELECT 
        ROW_NUMBER() OVER(partition by FAM.SEQFAMILIA,  S.SEQOBSSPED  order BY  E.CODEXCECAO) sequencia,
        FAM.SEQFAMILIA,
        E.CODEXCECAO,
        S.SEQOBSSPED,
        E.CODCADASTROPRINC,
        E.CODCADASTROEXCECAO CODAJUSTEEFD,
        T.UFORIGEM UF,
        E.TIPO1,
        E.VALOR1,
        'S' ATIVO,
        E.TIPO1||E.VALOR1 IDREF
     FROM MONITORPDVMIDDLE.TB_CADOBSSPED S,
          MONITORPDVMIDDLE.TB_FAMILIA FAM,
          MONITORPDVMIDDLE.tb_famdivisao D,
          MONITORPDVMIDDLE.TB_TRIBUTACAOUF T,
          PCEXCECAOCADASTROSFISCAIS E
          --pcdepararegiaoc5 R
          --VW_INT_C5_TRIB_UF_CONSOLIDADA T
     WHERE S.CODAJUSTEEFD = E.CODCADASTROPRINC
     AND   D.seqfamilia = FAM.SEQFAMILIA
     AND   T.NROTRIBUTACAO = D.nrotributacao
     AND   T.IDREF = E.CODCADASTROPRINC
     AND   T.CODOBSERVACAO = S.CODOBSERVACAO
     --AND   NVL(E.VALOR1, '0') = (DECODE(NVL(E.TIPO1,'XX'), 'PR', TO_CHAR(FAM.SEQFAMILIA), 'FT', TO_CHAR(D.nrotributacao), 'CM', TO_CHAR(FAM.codnbmsh)))
-    AND   NVL(E.VALOR1, '0') = (DECODE(NVL(E.TIPO1,'XX'), 'PR', TO_CHAR(FAM.IDREF), 'FT', TO_CHAR(D.nrotributacao), 'CM', TO_CHAR(FAM.codnbmsh)))
     AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S'
     AND   D.nrodivisao = (SELECT TO_CHAR(NROEMPRESA) VALOR 
                          FROM MONITORPDVMIDDLE.TB_EMPRESA 
                          WHERE ROWNUM = 1)
    )EXCECAO
WHERE EXCECAO.SEQUENCIA = 1
)