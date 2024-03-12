CREATE OR REPLACE VIEW VW_INT_C5_MARCA AS
(
  SELECT DISTINCT
         MARCA.*
  FROM(
        SELECT  DISTINCT 
              m.codmarca     AS seqmarca,
              SUBSTR(m.marca,1,20)    AS marca,
              
              (case 
                when NVL(m.ativo, 'S') = 'N' then
                     'N'
                else 'S'
               end) ativo    
        FROM pcprodut p
        INNER JOIN pcmarca m
        ON m.codmarca = p.codmarca
        AND m.codmarca > 0
  UNION ALL
        SELECT  CODMARCA seqmarca,
                SUBSTR(MARCA,1,20) marca,
                (case 
                 when NVL(ativo, 'S') = 'N' then
                     'N'
                 else 'S'
                 end) ativo
        FROM PCMARCA 
        WHERE CODMARCA > 0
        AND CODMARCA = ferramentas.f_buscarparametro_num('MARCAINTEGRACAOCONSINCO', '99', '1')) MARCA
)

 \

CREATE OR REPLACE VIEW VW_INT_C5_FAMILIA AS
(
SELECT
    DEPARA.SEQFAMILIA,
    TBFAM."CODPROD", TBFAM."CODAUXILIAR",TBFAM."ORIGEM",TBFAM."FAMILIA",TBFAM."CODNCMSH",TBFAM."PERMITEDECIMAL",TBFAM."PERMITEMULTIPLICACAO",TBFAM."CODCEST",TBFAM."ATIVO",TBFAM."SEQMARCA",TBFAM."SEQFAMGRUPO",TBFAM."PESAVEL",TBFAM."INDESCALA",TBFAM."CNPJFABRICANTE",TBFAM."EANTRIB",TBFAM."SEQFAMILIAPRINC"
FROM (
      SELECT
           /*NECESSÁRIO ATRIBUIR ZERO QUANDO O CODAUXILIAR ESTIVER NULO, POIS NA TABELA DEPARACODPRODC5 O CAMPO É PK(NÃO ACEITA NULO)*/
           MIN(PROD.CODPROD) CODPROD,
           (CASE
             WHEN MIN(PROD.CODAUXILIAR) IS NULL THEN
                  0
             ELSE MIN(PROD.CODAUXILIAR)
           END) CODAUXILIAR,
           MIN(PROD.ORIGEM) ORIGEM,
           MIN(PROD.familia) FAMILIA,
           MIN(PROD.codncmsh) codncmsh,
           MIN(PROD.permitedecimal) permitedecimal,
           MIN(PROD.permitemultiplicacao) permitemultiplicacao,
           MIN(PROD.codcest) codcest,
           MIN(PROD.ativo) ativo,
           MIN(PROD.seqmarca) seqmarca,
           MIN(PROD.seqfamgrupo) seqfamgrupo,
           MIN(PROD.PESAVEL) PESAVEL,
           MIN(PROD.indescala) indescala,
           MIN(PROD.cnpjfabricante) cnpjfabricante,
           MIN(PROD.eantrib) eantrib,
           MIN(PROD.Seqfamiliaprinc) Seqfamiliaprinc

      FROM (
            /* SELECT ORIGINAL VIEW EMBPROD */
            SELECT DISTINCT
                   p.codprod CODPROD,
                   NULL CODAUXILIAR,
                   MIN(P.CODAUXILIAR) IDREF, /*NECESSÁRIO TRAZER O CODAUXILIAR PARA SER UTILIZADO NO GROUP BY*/
                   'E' ORIGEM,
                   NVL(fnc_remove_char_esp(substr(p.descricao,0,39)), '-') familia,
                   MAX(p.codncmsh) codncmsh,
                   MAX(p.aceitavendafracao) permitedecimal,
                   MAX(p.permitemultiplicacao) permitemultiplicacao,
                   (SELECT nvl(CODCEST, 0) codcest
                    FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST
                    WHERE PCCESTPRODUTO.CODPROD = p.codprod
                    AND ROWNUM = 1
                   ) codcest,
                   'S' ativo,
                   MAX(p.codmarca) seqmarca,
                   1 seqfamgrupo,
                   (CASE
                      WHEN  MIN(p.tipoembalagem) = 'P' THEN
                            'S'
                      ELSE  'N'
                   END)PESAVEL,
                   MIN(NVL(p.indescalarelevante, 'S')) indescala,
                   MAX(fnc_remove_char_esp(p.cnpjfabricante)) cnpjfabricante,
                   MAX(p.codauxiliartrib) eantrib,
                   MAX(P.codprodprinc) seqfamiliaprinc
            FROM VW_INT_C5_EMBPROD p
            GROUP BY p.codprod, p.descricao

            UNION ALL

            /* SELECT CUSTOMIZADO PARA TRAZER EMBALAGENS COM O MESMO QTUNIT DESMEMBRADAS */
            SELECT
                   p.codprod CODPROD,
                   p.codauxiliar CODAUXILIAR,
                   p.codauxiliar IDREF, /*NECESSÁRIO REPETIR O CODAUXILIAR PARA SER UTILIZADO NO GROUP BY*/
                   'D' ORIGEM,
                   NVL(fnc_remove_char_esp(substr(p.descricao,0,39)), '-') familia,
                   p.codncmsh,
                   p.aceitavendafracao permitedecimal,
                   p.permitemultiplicacao,
                   (SELECT nvl(CODCEST, 0) codcest
                    FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST
                    WHERE PCCESTPRODUTO.CODPROD = p.codprod
                    AND ROWNUM = 1
                   ) codcest,
                   'S' ativo,
                   p.codmarca seqmarca,
                   1 seqfamgrupo,
                   (CASE
                      WHEN  p.tipoembalagem = 'P' THEN
                            'S'
                      ELSE  'N'
                   END)PESAVEL,
                   NVL(p.indescalarelevante, 'S') indescala,
                   fnc_remove_char_esp(p.cnpjfabricante) cnpjfabricante,
                   p.codauxiliartrib eantrib,
                   P.codprodprinc seqfamiliaprinc

            FROM VW_INT_C5_EMB_DESMEMBRADAS p
           ) PROD /*TABELA VIRTUAL CRIADA PARA LISTAR REGISTROS DA VIEW EMBPROD E VW_INT_C5_EMB_DESMEMBRADAS*/
      GROUP BY PROD.IDREF /*ORDERNAÇÃO DEVE SER PELO IDREF PARA AGRUPAR O RESULTADO O UNION ALL DA TABELA VIRTUAL "PROD"*/
      ) TBFAM, /*TABELA VIRTUAL COM O RESULTADO FINAL DO AGRUPAMENTO, SEM CODAUXILIAR DUPLICADO*/
      PCDEPARAPRODC5 DEPARA
WHERE TBFAM.CODPROD = DEPARA.CODPROD(+)
AND   TBFAM.CODAUXILIAR = DEPARA.CODAUXILIAR(+)
  
  /*SELECT DISTINCT
         p.codprod seqfamilia,
         NVL(fnc_remove_char_esp(substr(p.descricao,0,39)), '-') familia,
         MAX(p.codncmsh) codncmsh,
         MAX(p.aceitavendafracao) permitedecimal,
         MAX(p.permitemultiplicacao) permitemultiplicacao,
         (SELECT nvl(CODCEST, 0) codcest
          FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST
          WHERE PCCESTPRODUTO.CODPROD = p.codprod
          AND ROWNUM = 1
         ) codcest,
         'S' ativo,
         MAX(p.codmarca) seqmarca,
         1 seqfamgrupo,
         --MAX(p.pesovariavel) PESAVEL,
         (CASE
            WHEN  MIN(p.tipoembalagem) = 'P' THEN
                  'S'
            ELSE  'N'
         END)PESAVEL,
         MIN(NVL(p.indescalarelevante, 'S')) indescala,
         MAX(fnc_remove_char_esp(p.cnpjfabricante)) cnpjfabricante,
         MAX(p.codauxiliartrib) eantrib,
         MAX(P.codprodprinc) seqfamiliaprinc
  FROM VW_INT_C5_EMBPROD p
  GROUP BY p.codprod, p.descricao*/
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMEMBALAGEM AS
(
  SELECT
    SEQFAMILIA,
    QTDEMBALAGEM QTDEMBALAGEM,
    max(EMBALAGEM) EMBALAGEM,
    --max(PESOBRUTO) PESOBRUTO,
    --max(PESOLIQ) PESOLIQ,
    LEAST(max(PESOBRUTO), 9999.999) PESOBRUTO,
    LEAST(max(PESOLIQ), 9999.999) PESOLIQ,
    max(PESOAFERIDO) PESOAFERIDO,
    max(ATIVO) ATIVO
 FROM
  (
  --Embalagem preço varejo
  select distinct DEPARA.SEQFAMILIA seqfamilia,
                NVL(e.qtunit, 1) qtdembalagem,
                NVL(max(e.unidade), '1') embalagem,
                NVL(max(e.pesobruto), 0) pesobruto,
                NVL(max(e.pesoliq), 0) pesoliq,
                'N' pesoaferido,
                'S' ativo
  from VW_INT_C5_EMBPROD e, PCDEPARAPRODC5 DEPARA
 where E.qtunit <> E.qtminimaatacado
   and (((DEPARA.CODPROD = E.CODPROD)
   and (DEPARA.CODAUXILIAR = E.codprod))
    or ((DEPARA.CODPROD = E.CODPROD) 
   and (DEPARA.CODAUXILIAR = 0)))
 group by DEPARA.SEQFAMILIA,
          NVL(e.qtunit, 1)
UNION ALL
--Embalagem preço Atacado
select distinct DEPARA.SEQFAMILIA seqfamilia,
                NVL(e.qtminimaatacado, 1) qtdembalagem,
                NVL(max(e.unidade), '1') embalagem,
                NVL(max(e.pesobruto), 0) pesobruto,
                NVL(max(e.pesoliq), 0) pesoliq,
                'N' pesoaferido,
                'S' ativo
  from VW_INT_C5_EMBPROD e, PCDEPARAPRODC5 DEPARA
 where e.qtminimaatacado > 1
   and (((DEPARA.CODPROD = E.CODPROD)
   and (DEPARA.CODAUXILIAR = E.codprod))
    or ((DEPARA.CODPROD = E.CODPROD) 
	and (DEPARA.CODAUXILIAR = 0)))
 group by DEPARA.SEQFAMILIA,
          NVL(e.qtminimaatacado, 1))DADOSEMB
  group by SEQFAMILIA, QTDEMBALAGEM
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO AS
(
SELECT
    DEPARA.SEQPRODUTO,
    NVL((CASE
         WHEN ORIGEM = 'D' THEN
           DEPARA.SEQFAMILIA
         ELSE (SELECT PP.SEQFAMILIA FROM PCPRODUT P, PCDEPARAPRODC5 PP WHERE P.CODPRODPRINC = PP.CODPROD AND ROWNUM = 1)
        END
        ), DEPARA.SEQPRODUTO) SEQFAMILIA,
           
    TBPROD.*
FROM (
      SELECT 
           MIN(PROD.CODPROD) CODPROD,
           (CASE
             WHEN MIN(PROD.CODAUXILIAR) IS NULL THEN
                  0
             ELSE MIN(PROD.CODAUXILIAR)
           END) CODAUXILIAR,
           MIN(PROD.ORIGEM) ORIGEM,
           MIN(PROD.CODPRODUTO) CODPRODUTO,
           MIN(PROD.desccompleta) desccompleta,
           MIN(PROD.descreduzida) descreduzida,
           MIN(PROD.produtocomposto) produtocomposto,
           MIN(PROD.QTDDIAVALIDADE) QTDDIAVALIDADE,
           MIN(PROD.codanp) codanp,
           MIN(PROD.descanp_prod) descanp_prod,
           MIN(PROD.ATIVO) ATIVO
      FROM( 
            SELECT DISTINCT
                   p.codprod CODPROD,
                   NULL CODAUXILIAR,
                   MIN(P.CODAUXILIAR) IDREF, /*NECESSÁRIO TRAZER O CODAUXILIAR PARA SER UTILIZADO NO GROUP BY*/
                   'E' ORIGEM,
                   p.codprod codproduto,
                   fnc_remove_char_esp(p.descricao) desccompleta,
                   SUBSTR((fnc_remove_char_esp(P.descricao)),1,24) descreduzida,
                   'N' produtocomposto,
                   0 QTDDIAVALIDADE,
                   MAX(nvl(P.anp, 0)) codanp,
                   MAX(P.descanp) descanp_prod,
                   'S' ATIVO
            FROM VW_INT_C5_EMBPROD p
            GROUP BY p.codprod, p.descricao

            UNION ALL

            /* SELECT CUSTOMIZADO PARA TRAZER EMBALAGENS COM O MESMO QTUNIT DESMEMBRADAS */
            SELECT
                   p.codprod CODPROD,
                   p.codauxiliar CODAUXILIAR,
                   p.codauxiliar IDREF, /*NECESSÁRIO TRAZER O CODAUXILIAR PARA SER UTILIZADO NO GROUP BY*/
                   'D' ORIGEM,
                   p.codprod codproduto,
                   fnc_remove_char_esp(p.descricao) desccompleta,
                   SUBSTR((fnc_remove_char_esp(p.descricao)),1,24) descreduzida,
                   'N' produtocomposto,
                   0 QTDDIAVALIDADE,
                   nvl(p.anp, 0) codanp,
                   p.descanp descanp_prod,
                   'S' ATIVO

            FROM VW_INT_C5_EMB_DESMEMBRADAS p
          ) PROD /*TABELA VIRTUAL CRIADA PARA LISTAR REGISTROS DA VIEW EMBPROD E VW_INT_C5_EMB_DESMEMBRADAS*/
      GROUP BY PROD.IDREF /*ORDERNAÇÃO DEVE SER PELO IDREF PARA AGRUPAR O RESULTADO O UNION ALL DA TABELA VIRTUAL "PROD"*/
      ) TBPROD, /*TABELA VIRTUAL COM O RESULTADO FINAL DO AGRUPAMENTO, SEM CODAUXILIAR DUPLICADO*/
      PCDEPARAPRODC5 DEPARA
WHERE TBPROD.CODPROD = DEPARA.CODPROD
AND   TBPROD.CODAUXILIAR = DEPARA.CODAUXILIAR
  
  /*SELECT DISTINCT
   PROD.CODAUXILIAR IDREF,
   P.SEQPRODUTO SEQPRODUTO,
   MAX(PROD.CODPRODUTO) CODPRODUTO,
   MAX(PROD.desccompleta) desccompleta,
   MAX(PROD.descreduzida) descreduzida,
   MAX(PROD.produtocomposto) produtocomposto,
   MAX(PROD.SEQFAMILIA) SEQFAMILIA,
   MAX(PROD.QTDDIAVALIDADE) QTDDIAVALIDADE,
   MAX(PROD.codanp) codanp,
   MAX(PROD.descanp_prod) descanp_prod,
   MAX(PROD.ATIVO) ATIVO
FROM
  (
  SELECT DISTINCT
        E.CODAUXILIAR,
        MAX(e.codprod) codproduto,
        MAX(fnc_remove_char_esp(e.descricao)) desccompleta,
        MAX(SUBSTR((fnc_remove_char_esp(e.descricao)),1,24)) descreduzida,
        'N' produtocomposto,
        MAX(e.codprod) seqfamilia,
        0 QTDDIAVALIDADE,
        MAX(nvl(e.anp, 0)) codanp,
        MAX(e.descanp) descanp_prod,
        'S' ATIVO
  FROM  VW_INT_C5_EMBPROD E
  GROUP BY E.CODAUXILIAR
  ) PROD,
  PCDEPARAEMBALAGENSC5 P
WHERE PROD.CODAUXILIAR = P.CODAUXILIAR
GROUP BY P.SEQPRODUTO, PROD.CODAUXILIAR*/
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODEMPRESA AS
(
  SELECT E.codfilial nroempresa,
         E.codauxiliar idref,
         P.SEQPRODUTO SEQPRODUTO,
         0000000 estqloja,
         'S' ativo
  FROM VW_INT_C5_EMBPROD eE
       PCDEPARAPRODC5 P
  WHERE ((E.CODPROD = P.CODPROD) AND (E.CODAUXILIAR = P.CODAUXILIAR))
     OR ((E.CODPROD = P.CODPROD) AND (P.CODAUXILIAR = 0))

)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODCODIGO AS
(
  SELECT
        e.codfilial nroempresa,
        e.codauxiliar codacesso,
        P.SEQPRODUTO SEQPRODUTO,
        COALESCE(e.qtunit, 1) qtdembalagem,
        (CASE
            WHEN length(e.codauxiliar) = 13 AND NVL(E.PRODSEMCODBARRAS, 'N') = 'N'
                 THEN 'E'
            WHEN length(e.codauxiliar) = 14 AND NVL(E.PRODSEMCODBARRAS, 'N') = 'N'
                 THEN 'D'
            WHEN NVL(E.PRODSEMCODBARRAS, 'N') = 'S' THEN
             'B'
         ELSE
           'B'
         END) tipo,
        'S' ativo
 FROM  VW_INT_C5_EMBPROD e,
       PCDEPARAPRODC5 P
 WHERE ((E.CODPROD = P.CODPROD) AND (E.CODAUXILIAR = P.CODAUXILIAR))
     OR ((E.CODPROD = P.CODPROD) AND (P.CODAUXILIAR = 0))
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAMSEGMENTO AS
(SELECT
       e.codprod seqfamilia,
       1 nrosegmento,
       'S' ativo
  FROM  VW_INT_C5_EMBPROD e,
    MONITORPDVMIDDLE.TB_FAMILIA T
  WHERE
    E.CODPROD = T.SEQFAMILIA

)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODPRECO AS
(
   --Linha de preço varejo
  SELECT
    E.CODAUXILIAR IDREF,
    P.SEQPRODUTO SEQPRODUTO,
    E.CODFILIAL NROEMPRESA,
    NVL(E.QTUNIT, 1) QTDEMBALAGEM,
    1 NROSEGMENTO,
    'N' PROMOCAO,
    --E.PVENDA PRECO,
    LEAST(E.PVENDA, 9999999.999) PRECO,
    0 PRECONORMAL,
    'S' ATIVO
  FROM VW_INT_C5_EMBPROD E,
       PCDEPARAPRODC5 P
  WHERE ((E.CODAUXILIAR = P.CODAUXILIAR
    AND E.CODPROD = P.CODPROD) 
	 OR (E.CODPROD = P.CODPROD
    AND P.CODAUXILIAR = 0 ))
    AND E.QTUNIT <> E.QTMINIMAATACADO

  UNION ALL

  --LINHA DE PREÇO ATACADO
  SELECT
    E.CODAUXILIAR IDREF,
    P.SEQPRODUTO SEQPRODUTO,
    E.CODFILIAL NROEMPRESA,
    NVL(E.QTMINIMAATACADO, 1) QTDEMBALAGEM,
    1 NROSEGMENTO,
    'N' PROMOCAO,
    --ROUNDABNT((E.PVENDAATAC / E.QTUNIT) * E.QTMINIMAATACADO, 3) PRECO,
    LEAST(ROUNDABNT((E.PVENDAATAC / E.QTUNIT) * E.QTMINIMAATACADO, 3), 9999999.999) PRECO,
    0 PRECONORMAL,
    'S' ATIVO
  FROM VW_INT_C5_EMBPROD E,
       PCDEPARAPRODC5 P
  WHERE ((E.CODAUXILIAR = P.CODAUXILIAR
    AND E.CODPROD = P.CODPROD) 
	 OR (E.CODPROD = P.CODPROD
    AND P.CODAUXILIAR = 0 ))
    AND E.QTMINIMAATACADO > 1

)

\

CREATE OR REPLACE VIEW VW_INT_C5_PROMOCOES_VIGENTES AS
(
  SELECT
    PCOFERTAPROGRAMADAC.CODOFERTA || ' - 2011' IDREF, 
    PCDEPARAPRODC5.SEQPRODUTO,
    PCOFERTAPROGRAMADAC.CODFILIAL NROEMPRESA,
    PCEMBALAGEM.QTUNIT QTDEMBALAGEM,
    1 NROSEGMENTO,  
    PCOFERTAPROGRAMADAI.VLOFERTA PRECO,
    'S' PROMOCAO,
    'S' ATIVO,
    decode(PCOFERTAPROGRAMADAC.HORAINICIAL, null, 0, 1) PRIORIDADE,
    PCEMBALAGEM.PVENDA PRECONORMAL
  FROM 
    PCOFERTAPROGRAMADAI
  INNER JOIN PCOFERTAPROGRAMADAC
  ON (PCOFERTAPROGRAMADAC.CODOFERTA = PCOFERTAPROGRAMADAI.CODOFERTA)  

  INNER JOIN PCEMBALAGEM
  ON (PCEMBALAGEM.CODAUXILIAR = PCOFERTAPROGRAMADAI.CODAUXILIAR)

  INNER JOIN PCDEPARAPRODC5 
  ON ((PCDEPARAPRODC5.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR AND PCEMBALAGEM.CODPROD = PCDEPARAPRODC5.CODPROD) 
      OR (PCEMBALAGEM.CODPROD = PCDEPARAPRODC5.CODPROD  AND PCDEPARAPRODC5.CODAUXILIAR = 0))

  WHERE 
  	PCOFERTAPROGRAMADAC.DTINICIAL IS NOT NULL
  	AND PCOFERTAPROGRAMADAC.DTFINAL IS NOT NULL
    AND SYSDATE BETWEEN 
	    TO_DATE(PCOFERTAPROGRAMADAC.DTINICIAL   || ' ' || NVL(TO_CHAR(PCOFERTAPROGRAMADAC.HORAINICIAL, 'HH:MI:SS'), '00:00:01' ),'DD-MM-YY HH24:MI:SS','NLS_DATE_LANGUAGE = AMERICAN')
		  AND TO_DATE(PCOFERTAPROGRAMADAC.DTFINAL || ' ' || NVL(TO_CHAR(PCOFERTAPROGRAMADAC.HORAFINAL  , 'HH:MI:SS'), '23:59:59' ),'DD-MM-YY HH24:MI:SS','NLS_DATE_LANGUAGE = AMERICAN')
    AND PCOFERTAPROGRAMADAI.VLOFERTA > 0
    AND PCOFERTAPROGRAMADAC.PRIORIDADEOFERTA = (SELECT MIN(P.PRIORIDADEOFERTA) FROM PCOFERTAPROGRAMADAC P WHERE P.CODOFERTA = PCOFERTAPROGRAMADAC.CODOFERTA)

  UNION ALL

  SELECT
    PCEMBALAGEM.CODAUXILIAR || ' - 2017' IDREF,
    PCDEPARAPRODC5.SEQPRODUTO,
    PCEMBALAGEM.CODFILIAL NROEMPRESA,
    PCEMBALAGEM.QTUNIT QTDEMBALAGEM,  
    1 NROSEGMENTO,  
    PCEMBALAGEM.POFERTA PRECO,
    'S' PROMOCAO,
    'S' ATIVO,
    2 PRIORIDADE,
    PCEMBALAGEM.PVENDA PRECONORMAL
  FROM 
    PCEMBALAGEM

  INNER JOIN PCDEPARAPRODC5
  ON ((PCDEPARAPRODC5.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR AND PCEMBALAGEM.CODPROD = PCDEPARAPRODC5.CODPROD)
  OR (PCEMBALAGEM.CODPROD = PCDEPARAPRODC5.CODPROD AND PCDEPARAPRODC5.CODAUXILIAR =0))
  
  WHERE  
  	PCEMBALAGEM.DTOFERTAINI IS NOT NULL
  	AND PCEMBALAGEM.DTOFERTAFIM IS NOT NULL 
    AND SYSDATE BETWEEN TO_DATE(PCEMBALAGEM.DTOFERTAINI || ' 00:00:01','DD-MM-YY HH24:MI:SS','NLS_DATE_LANGUAGE = AMERICAN') AND TO_DATE(PCEMBALAGEM.DTOFERTAFIM  || ' 23:59:59','DD-MM-YY HH24:MI:SS','NLS_DATE_LANGUAGE = AMERICAN')
    AND PCEMBALAGEM.POFERTA > 0
    AND PCEMBALAGEM.QTUNIT  > 0
    
  UNION ALL 

  SELECT
    PCEMBALAGEM.CODAUXILIAR ||' - 2017' IDREF,
    PCDEPARAPRODC5.SEQPRODUTO,
    PCEMBALAGEM.CODFILIAL NROEMPRESA,
    PCEMBALAGEM.QTMINIMAATACADO QTDEMBALAGEM,
    1 NROSEGMENTO,  
    PCEMBALAGEM.POFERTAATAC PRECO,
    'S' PROMOCAO,
    'S' ATIVO,
    2 PRIORIDADE,
    PCEMBALAGEM.PVENDAATAC PRECONORMAL
  FROM 
    PCEMBALAGEM

  INNER JOIN PCDEPARAPRODC5
  ON ((PCDEPARAPRODC5.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR AND PCEMBALAGEM.CODPROD = PCDEPARAPRODC5.CODPROD) 
  OR (PCEMBALAGEM.CODPROD = PCDEPARAPRODC5.CODPROD AND PCDEPARAPRODC5.CODAUXILIAR = 0))

  WHERE
  	PCEMBALAGEM.DTOFERTAATACINI IS NOt NULL
  	AND PCEMBALAGEM.DTOFERTAATACFIM IS NOT null
    AND SYSDATE BETWEEN TO_DATE(PCEMBALAGEM.DTOFERTAATACINI || ' 00:00:01','DD-MM-YY HH24:MI:SS','NLS_DATE_LANGUAGE = AMERICAN') AND TO_DATE(PCEMBALAGEM.DTOFERTAATACFIM  || ' 23:59:59','DD-MM-YY HH24:MI:SS','NLS_DATE_LANGUAGE = AMERICAN')    
    AND PCEMBALAGEM.POFERTAATAC > 0
    AND PCEMBALAGEM.QTMINIMAATACADO > 0
    
)