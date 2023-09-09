CREATE OR REPLACE VIEW VW_INT_C5_CATEGORIA AS
(
SELECT CATEG.NRODIVISAO, 
            C.seqcategoriac5 seqcategoria,
            CATEG.seqcategoriawinthor,
            CATEG.seqcategoriapai,
            CATEG.NIVELHIERARQUIA,
            CATEG.CATEGORIA,
            CATEG.ATIVO,
            'M' TIPO,
            'N' LERPESO,
            CATEG.IDREF
 FROM 
    (SELECT DISTINCT
            (SELECT r.nrodivisao
               FROM pcdepararegiaoc5 r
              WHERE r.numregiao = regparaovarejo.valor
            ) nrodivisao,
            TO_NUMBER(regparaovarejo.valor) || TO_NUMBER(dadosclassific.seqcategoria) seqcategoriawinthor,
            dadosclassific.seqcategoriapai,
            dadosclassific.nivelhierarquia,
            dadosclassific.categoria,
            dadosclassific.ativo,
            idref
     FROM 
            (SELECT 0 || codepto || 1 seqcategoria,
                    NULL seqcategoriapai,
                    1 nivelhierarquia,
                    SUBSTR (UPPER (descricao), 0, 25) categoria,
                    'S' ativo,
                    codepto idref,
                    dtalterc5
               FROM pcdepto,
                    (SELECT s.ultimaexecucao
                       FROM pccontroleconsinco s
                      WHERE UPPER (s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA')
                    datapadrao
              WHERE NVl (dtalterc5, datapadrao.ultimaexecucao) >= datapadrao.ultimaexecucao
             ------------------
             UNION ALL
             SELECT b.codsec || 2 seqcategoria,
                    a.codepto || 1 seqcategoriapai,
                    2 nivelhierarquia,
                    SUBSTR (UPPER (b.descricao), 0, 25) categoria,
                    'S' ativo,
                    b.codsec idref,
                    b.dtalterc5
               FROM pcsecao b,
                    pcdepto a,
                    (SELECT s.ultimaexecucao
                       FROM pccontroleconsinco s
                      WHERE UPPER (s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') datapadrao
              WHERE a.codepto = b.codepto
                AND NVL(b.dtalterc5, datapadrao.ultimaexecucao) >= datapadrao.ultimaexecucao
             ------------------
             UNION ALL
             SELECT b.codsec || c.codcategoria || 3 seqcategoria,
                    b.codsec || 2 seqcategoriapai,
                    3 nivelhierarquia,
                    SUBSTR (UPPER (c.categoria), 0, 25) categoria,
                    'S' ativo,
                    c.codcategoria idref,
                    c.dtalterc5
               FROM pccategoria c,
                    pcsecao b,
                    pcdepto a,
                    (SELECT s.ultimaexecucao
                       FROM pccontroleconsinco s
                      WHERE UPPER (s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') datapadrao
              WHERE a.codepto = b.codepto
                AND b.codsec = c.codsec
                AND NVL(c.dtalterc5, datapadrao.ultimaexecucao) >= datapadrao.ultimaexecucao
             -----------------------
             UNION ALL
             SELECT b.codsec || c.codcategoria || d.codsubcategoria || 4 seqcategoria,
                    c.codcategoria || 3 seqcategoriapai,
                    4 nivelhierarquia,
                    SUBSTR (UPPER (d.subcategoria), 0, 25) categoria,
                    'S' ativo,
                    d.codsubcategoria idref,
                    d.dtalterc5
               FROM pcsubcategoria d,
                    pccategoria c,
                    pcsecao b,
                    pcdepto a,
                    (SELECT s.ultimaexecucao
                       FROM pccontroleconsinco s
                      WHERE UPPER (s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') datapadrao
              WHERE a.codepto = b.codepto
                AND b.codsec = c.codsec
                AND c.codcategoria = d.codcategoria
                AND d.codsec = b.codsec
                AND NVL (d.dtalterc5, datapadrao.ultimaexecucao) >= datapadrao.ultimaexecucao
            ) dadosclassific,
            
            (SELECT DISTINCT pcparamfilial.valor
               FROM pcparamfilial
              WHERE nome = 'NUMREGIAOPADRAOVAREJO'
                AND valor <> '99'
                AND REGEXP_LIKE (codfilial, '^[[:digit:]]+$')
            ) regparaovarejo
    WHERE regparaovarejo.valor IS NOT NULL) CATEG,
          pcdeparacategoriac5 c
 WHERE CATEG.seqcategoriawinthor = c.seqcategoriawinthor(+)
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMDIVISAOCATEGORIA AS
(
SELECT
    VW_INT_C5_CATEGORIA.NRODIVISAO,
    VW_INT_C5_FAMILIA.SEQFAMILIA,
    VW_INT_C5_CATEGORIA.SEQCATEGORIA,
    'S' ATIVO,
    
    /*Caseo seja necessário identificar no winthor a categoria atribuida
      no produto(CODPROD) do lado da Consinco, o IDREF receberá 
      a categorização que a concatenação da HIERARQUIA com a categoria(departamento /seção/categoria/subcategoria
    )*/
    (CASE
      WHEN VW_INT_C5_CATEGORIA.NIVELHIERARQUIA = 4 THEN
           VW_INT_C5_CATEGORIA.NIVELHIERARQUIA||PRODCATEGORIA.CODSUBCATEGORIA
      WHEN VW_INT_C5_CATEGORIA.NIVELHIERARQUIA = 3 THEN
           VW_INT_C5_CATEGORIA.NIVELHIERARQUIA||PRODCATEGORIA.CODCATEGORIA
      WHEN VW_INT_C5_CATEGORIA.NIVELHIERARQUIA = 2 THEN
           VW_INT_C5_CATEGORIA.NIVELHIERARQUIA||PRODCATEGORIA.CODSEC
      ELSE VW_INT_C5_CATEGORIA.NIVELHIERARQUIA||PRODCATEGORIA.CODEPTO
    END) IDREF 

 FROM VW_INT_C5_CATEGORIA,
      VW_INT_C5_FAMILIA,
      (SELECT
         /*(SELECT r.nrodivisao
          FROM pcdepararegiaoc5 r
          WHERE r.numregiao = regparaovarejo.valor
         ) nrodivisao,*/
         
         regparaovarejo.valor NUMREGIAO,
         
         CODPROD,
         CODEPTO,
         CODSEC,
         CODCATEGORIA,
         CODSUBCATEGORIA,
         (CASE
            WHEN CODSUBCATEGORIA IS NOT NULL THEN
                 CODSEC||CODCATEGORIA||CODSUBCATEGORIA||4
            WHEN CODCATEGORIA IS NOT NULL THEN
                 CODSEC||CODCATEGORIA||3
            WHEN CODSEC IS NOT NULL THEN
                 CODSEC||2
            ELSE 
                 CODEPTO||1
         END) SEQCATEGORIA

       FROM PCPRODUT p,
            (SELECT DISTINCT pcparamfilial.valor
               FROM pcparamfilial
              WHERE nome = 'NUMREGIAOPADRAOVAREJO'
                AND valor <> '99'
                AND REGEXP_LIKE (codfilial, '^[[:digit:]]+$')
            ) regparaovarejo
       WHERE ((CODEPTO IS NOT NULL) AND (CODSEC IS NOT NULL) AND (CODCATEGORIA IS NOT NULL) AND (CODSUBCATEGORIA IS NOT NULL)) --SUBCATEGORIA
          OR ((CODEPTO IS NOT NULL) AND (CODSEC IS NOT NULL) AND (CODCATEGORIA IS NOT NULL) AND (CODSUBCATEGORIA IS NULL)) -- CATEGORIA
          OR ((CODEPTO IS NOT NULL) AND (CODSEC IS NOT NULL) AND (CODCATEGORIA IS NULL) AND (CODSUBCATEGORIA IS NULL)) --SECAO
          OR (CODEPTO IS NOT NULL) --DEPARTAMENTO
      )PRODCATEGORIA,

      PCDEPARACATEGORIAC5 C
 WHERE TO_NUMBER(PRODCATEGORIA.NUMREGIAO)||TO_NUMBER(PRODCATEGORIA.SEQCATEGORIA) = C.SEQCATEGORIAWINTHOR
 AND   TO_NUMBER(PRODCATEGORIA.NUMREGIAO)||TO_NUMBER(PRODCATEGORIA.SEQCATEGORIA) = VW_INT_C5_CATEGORIA.SEQCATEGORIAWINTHOR
 AND   C.SEQCATEGORIAC5 =  VW_INT_C5_CATEGORIA.SEQCATEGORIA
 AND   C.SEQCATEGORIAWINTHOR = VW_INT_C5_CATEGORIA.SEQCATEGORIAWINTHOR
 AND   PRODCATEGORIA.CODPROD = VW_INT_C5_FAMILIA.SEQFAMILIA
)