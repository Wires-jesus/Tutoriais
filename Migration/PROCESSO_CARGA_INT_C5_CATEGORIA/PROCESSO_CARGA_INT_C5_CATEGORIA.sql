CREATE OR REPLACE VIEW VW_INT_C5_CATEGORIA AS
(
 SELECT "SEQCATEGORIA","NRODIVISAO","SEQCATEGORIAPAI","TIPO","NIVELHIERARQUIA","CATEGORIA","ATIVO","LERPESO","NROCARGA","DATA","ULTIMAEXECUCAO"
  FROM (SELECT A.CODEPTO SEQCATEGORIA,
               1 NRODIVISAO,
               NULL SEQCATEGORIAPAI,
               'M' TIPO,
               1 NIVELHIERARQUIA,
               SUBSTR(A.descricao, 0, 25)  CATEGORIA,
               COALESCE(ATIVO, 'S') ATIVO,
               'N' lerpeso,
               0 NROCARGA,
               GREATEST(NVL(C.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(B.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(A.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(D.dtalterc5, DATAPADRAO.ultimaexecucao)) DATA,
               DATAPADRAO.ultimaexecucao
          FROM PCSUBCATEGORIA D,
               PCCATEGORIA C,
               PCSECAO B,
               PCDEPTO A,
               (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') DATAPADRAO
         WHERE A.CODEPTO = B.CODEPTO(+)
           and B.CODSEC = C.CODSEC(+)
           and C.CODCATEGORIA = D.CODCATEGORIA(+)
        UNION ALL
        SELECT B.CODSEC SEQCATEGORIA,
               1 NRODIVISAO,
               A.CODEPTO SEQCATEGORIAPAI,
               'M' TIPO,
               2 NIVELHIERARQUIA,
               SUBSTR(B.DESCRICAO, 0, 25) CATEGORIA,
               COALESCE(ATIVO, 'S') ATIVO,
               'N' lerpeso,
               0 NROCARGA,
               GREATEST(NVL(C.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(B.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(A.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(D.dtalterc5, DATAPADRAO.ultimaexecucao)) DATA,
               DATAPADRAO.ultimaexecucao
          FROM PCSUBCATEGORIA D,
               PCCATEGORIA C,
               PCSECAO B,
               PCDEPTO A,
               (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') DATAPADRAO
         WHERE A.CODEPTO = B.CODEPTO
           and B.CODSEC = C.CODSEC(+)
           and C.CODCATEGORIA = D.CODCATEGORIA(+)

        UNION ALL
        SELECT C.CODCATEGORIA SEQCATEGORIA,
               1 NRODIVISAO,
               B.CODSEC SEQCATEGORIAPAI,
               'M' TIPO,
               3 NIVELHIERARQUIA,
               SUBSTR(C.CATEGORIA, 0,25) CATEGORIA,
               COALESCE(ATIVO, 'S') ATIVO,
               'N' lerpeso,
               0 NROCARGA,
               GREATEST(NVL(C.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(B.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(A.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(D.dtalterc5, DATAPADRAO.ultimaexecucao)) DATA,
               DATAPADRAO.ultimaexecucao
          FROM PCSUBCATEGORIA D,
               PCCATEGORIA C,
               PCSECAO B,
               PCDEPTO A,
               (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') DATAPADRAO
         WHERE A.CODEPTO = B.CODEPTO
           and B.CODSEC = C.CODSEC
           and C.CODCATEGORIA = D.CODCATEGORIA(+)
        UNION ALL
        SELECT D.CODSUBCATEGORIA SEQCATEGORIA,
               1 NRODIVISAO,
               D.CODCATEGORIA SEQCATEGORIAPAI,
               'M' TIPO,
               4 NIVELHIERARQUIA,
               SUBSTR(D.SUBCATEGORIA, 0 , 25) CATEGORIA,
               COALESCE(ATIVO, 'S') ATIVO,
               'N' lerpeso,
               0 NROCARGA,
               GREATEST(NVL(C.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(B.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(A.dtalterc5, DATAPADRAO.ultimaexecucao),
                        NVL(D.dtalterc5, DATAPADRAO.ultimaexecucao)) DATA,
               DATAPADRAO.ultimaexecucao
          FROM PCSUBCATEGORIA D,
               PCCATEGORIA C,
               PCSECAO B,
               PCDEPTO A,
               (SELECT s.ultimaexecucao FROM pccontroleconsinco s WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CATEGORIA') DATAPADRAO
         WHERE A.CODEPTO = B.CODEPTO
           and B.CODSEC = C.CODSEC
           and C.CODCATEGORIA = D.CODCATEGORIA(+)) A
 WHERE A.DATA >= A.ultimaexecucao
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMDIVISAOCATEGORIA AS
(SELECT
       e.codprod seqfamilia,
       COALESCE(s.codsec,d.codepto) seqcategoria,
       1 nrodivisao,
       'S' ativo
  
  FROM  pcdepto  d,
        pcsecao  s,
        VW_INT_C5_EMBPROD e,
        (select s.ultimaexecucao ultimaexecucao from pccontroleconsinco s where upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMDIVISAOCATEGORIA') DTPADRAO
 WHERE  e.codepto = d.codepto
   AND  e.codsec = s.codsec
   AND  d.codepto = s.codepto
   AND  (d.codepto <> 999
         OR
         s.codsec <> 9999)
  AND GREATEST(NVL(S.dtalterc5, DTPADRAO.ULTIMAEXECUCAO),
               NVL(D.dtalterc5, DTPADRAO.ULTIMAEXECUCAO)) >= DTPADRAO.ULTIMAEXECUCAO)

