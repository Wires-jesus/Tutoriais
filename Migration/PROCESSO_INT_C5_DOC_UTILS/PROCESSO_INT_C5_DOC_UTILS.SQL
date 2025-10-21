CREATE OR REPLACE VIEW VW_INT_C5_TRIBUTOS AS 
 ( SELECT DISTINCT t.codst,
       t.mensagem,
       '0'||t.sittribut cst,
       (CASE
            WHEN t.sittribut = '40'
                THEN 100
            WHEN t.sittribut = '20'
                THEN 100 - NVL(t.percbasered,0)
            ELSE
                0
        END) percisento,
       (CASE
            WHEN t.sittribut = '20'
                THEN NVL(t.percbasered,0)
            WHEN t.sittribut NOT IN ('20','60','40','41')
                THEN 100
            ELSE
                0
        END) perctributado,
       (CASE
            WHEN t.sittribut = '60'
                THEN 100
            ELSE
                0
        END) percoutro,
       NVL(t.aliqstsaida,0) percisentost,
       NVL(t.peracrescimofuncep,0) percaliqfcpicms,
       (CASE
            WHEN NVL(t.aliqstsaida,0) > 0
                THEN 'S'
            ELSE 
                'N'
        END) reducaobasest,
       t.dtalterc5,
       NVL(t.percacrescbenffis,0) percacrescbenffis
  FROM pctribut t
 WHERE t.sittribut IN ('00','20','40','41','60','61','90')
   AND t.codst >= 0 )

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_DIASCARENCIA(pCODFINALIZADORA NUMBER)
    RETURN NUMBER
IS
    vDIASCARENCIA NUMBER;
BEGIN
  begin
    SELECT  NVL(P.DIASCARENCIA,0)
      INTO  vDIASCARENCIA
    FROM PCFINALIZADORA F, PCPLPAG P
    WHERE F.CODPLPAG = P.CODPLPAG
    AND F.CODFINALIZADORA = pCODFINALIZADORA;
  exception
    WHEN OTHERS THEN
      vDIASCARENCIA := 0;
  END;
    RETURN(vDIASCARENCIA);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_DIAFIXO(pCODFINALIZADORA NUMBER)
    RETURN NUMBER
IS
    vDIAFIXO NUMBER;
BEGIN
  begin
    SELECT  NVL(P.DIAFIXO,0)
      INTO  vDIAFIXO
    FROM PCFINALIZADORA F, PCPLPAG P
    WHERE F.CODPLPAG = P.CODPLPAG
    AND F.CODFINALIZADORA = pCODFINALIZADORA;
  exception
    WHEN OTHERS THEN
      vDIAFIXO := 0;
  END;
    RETURN(vDIAFIXO);
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_CALCDIAFIXO(pddtemissao  IN DATE,
                                           pncarencia   IN NUMBER,
                                           pndiafixo    IN NUMBER,
                                           VDPROXDTMINIMA IN DATE
    ) RETURN DATE IS
    vnteste_diafixo   NUMBER(1);
    vddata_vencimento DATE;
    vndiafixo         NUMBER(2);
    vnmes             NUMBER(2);
    vb_diavalido      BOOLEAN;
    vnultimodiames    NUMBER(2);
BEGIN
    

    vddata_vencimento := NULL;
    vnteste_diafixo   := 0;
    vnmes             := 0;
    vb_diavalido      := FALSE;
    vndiafixo         := pndiafixo;

    BEGIN
      vnmes             := GREATEST(ROUND(MONTHS_BETWEEN(VDPROXDTMINIMA, TRUNC(SYSDATE)), 0)-1, 0);
    EXCEPTION
      WHEN OTHERS THEN
        
        RETURN TRUNC(SYSDATE);
    END;

    WHILE (NOT vb_diavalido) LOOP
      WHILE vnteste_diafixo = 0 LOOP
        BEGIN

          SELECT EXTRACT(DAY FROM LAST_DAY(TO_DATE(TO_CHAR(1) || '/' ||
                         TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), vnmes),
                                 'MM/YYYY'),
                         'DD/MM/YYYY')))
            INTO vnultimodiames
            FROM PCCONSUM;

          IF vndiafixo <= vnultimodiames THEN
            SELECT TO_DATE(TO_CHAR(vndiafixo) || '/' ||
                           TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), vnmes),
                                   'MM/YYYY'),
                           'DD/MM/YYYY')
              INTO vddata_vencimento
              FROM PCCONSUM;
          ELSE
            SELECT LAST_DAY(TO_DATE(TO_CHAR(1) || '/' ||
                            TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), vnmes),
                                   'MM/YYYY'),
                           'DD/MM/YYYY'))
              INTO vddata_vencimento
              FROM PCCONSUM;
          END IF;

          vnteste_diafixo := 1;
        EXCEPTION
          WHEN OTHERS THEN
            
            RETURN TRUNC(SYSDATE);
        END;
      END LOOP;

      IF ((pddtemissao + nvl(pncarencia,0)) <= vddata_vencimento) and (vddata_vencimento >= VDPROXDTMINIMA) THEN
        vddata_vencimento := vddata_vencimento;
        vb_diavalido := TRUE;
      ELSE
        if vnmes >= 99 then
          
          RETURN TRUNC(SYSDATE);
        end if;
        vndiafixo       := pndiafixo;
        vnmes           := vnmes + 1;
        vnteste_diafixo := 0;
      END IF;

    END LOOP;    
    RETURN vddata_vencimento;
END;

\

CREATE OR REPLACE VIEW VW_INT_C5_PISCOFINS AS 
  (SELECT  a.codtribpiscofins,
        a.percpis,
        a.perccofins,
        a.sittribut,
        v.dtinicio,
        v.dtfinal
  FROM  pctribpiscofins a,
        pctribpiscofinsvigencia v
 WHERE  a.codtribpiscofins = v.codtribpiscofins(+)
   AND  a.codtribpiscofins >= 0)
   
   
\

CREATE OR REPLACE VIEW VW_INT_C5_PIX AS 
  (SELECT 'pix' nomecarteira, 3001 idcarteira FROM PCCONSUM
     UNION
     SELECT 'mercadopago' nomecarteira, 3002 idcarteira FROM PCCONSUM
     UNION
     SELECT 'picpay' nomecarteira, 3003 idcarteira FROM PCCONSUM
     UNION
     SELECT 'ame' nomecarteira, 3004 idcarteira FROM PCCONSUM
     UNION
     SELECT 'shipaypagador' nomecarteira, 30099 idcarteira FROM PCCONSUM
   )

\

CREATE OR REPLACE VIEW VW_INT_C5_PCVENDACONSUMECF AS 
  (SELECT d.seqdocto,
       TO_CHAR(d.dtamovimento, 'YYYY-MM-DD') DATA,
       0 numpedecf,
       d.sequsuario codfunccheckout,
       d.nrocheckout numcaixa,
       C5.CODFILIAL codfilial,
     d.NROEMPRESA NROEMPRESA,
       'NOTAFISCAL' numserieequip,
       CASE WHEN NF.DOCEMISSAO in ('SF', 'MF') THEN NF.NUMCUPOMSAT ELSE c.nronotafiscal END numcupom,
       NVL(c.nomecliente, 'CONSUMIDOR FINAL') cliente,
       c.cnpjcpf cgcent,
       c.idestrangeiro identificacao_estrangeiro,
       'N' exportado,
       NVL(F.TELENT,
           (SELECT CLI.TELENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) TELENT,
       NVL(F.MUNICENT,
           (SELECT CLI.MUNICENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) MUNICENT,
       NVL(F.ESTENT,
           (SELECT CLI.ESTENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) ESTENT,
       NVL(F.CEPENT,
           (SELECT CLI.CEPENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) CEPENT,
       NVL(F.IEENT,
           (SELECT CLI.IEENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) IEENT,
       NVL(F.CODCIDADE,
           (SELECT CLI.CODCIDADE
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) CODCIDADE,
       NVL(F.NUMEROENT,
           (SELECT CLI.NUMEROENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) NUMEROENT,
       NVL(F.BAIRROENT,
           (SELECT CLI.BAIRROENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) BAIRROENT,
       NVL(F.ENDERENT,
           (SELECT CLI.ENDERENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = C5.CODFILIAL))) ENDERENT
  FROM monitorpdvmiddle.tb_docto      d,
       monitorpdvmiddle.tb_doctocupom c,
       /*monitorpdvmiddle.tb_doctonfe   e,*/
     VW_INT_C5_NFESAT NF,
       PCCLIENT                       F,
     VW_INT_C5_OBTER_FILIAIS_C5    C5
 WHERE d.nroempresa = c.nroempresa
   AND d.nrocheckout = c.nrocheckout
   AND d.seqdocto = c.seqdocto
   AND d.nroempresa = NF.nroempresa
   AND d.nrocheckout = NF.nrocheckout
   AND C5.CODFILIALINTEGRACAO = d.nroempresa
   AND C5.CODFILIALINTEGRACAO = NF.NROEMPRESA
   AND C5.CODFILIALINTEGRACAO = c.nroempresa
   AND d.seqdocto = NF.seqdocto
   AND d.especie = 'NF'
   AND NVL(c.seqpessoa,1) IN (1,2,3)
   AND c.cnpjcpf IS NOT NULL
   AND NVL(C.SEQPESSOA, 1) = F.CODCLI(+))

\

CREATE OR REPLACE VIEW VW_INT_C5_PCPRODUT  AS 
  (SELECT  e.codprod,
        e.codauxiliar,
        c.seqproduto,
        e.codfilial,
    C5.codfilialintegracao nroempresa,
        p.codepto,
        p.codsec,
        p.codcategoria,
        p.codsubcategoria,
        NVL(e.qtunit,1) qtunit,
        NVL(NVL(e.unidade,p.unidade),'UN') unidade,
        NVL(NVL(e.pesobruto,p.pesobruto),0) pesobruto,
        NVL(NVL(e.pesoliq,p.pesoliq),0) pesoliq,
        NVL(f.percdesoneracao,0) percdesoneracao,
        p.codfornec,
        p.codmarca,
        f.indescalarelevante,
        f.fabricante,
        f.cnpjfabricante,
        NVL(f.origmerctrib, 0) origmerctrib,
        p.anp,
        p.descanp,
        
        (SELECT  s.codcest
           FROM  pccest s,
                 pccestproduto sp
          WHERE  s.codigo = sp.codseqcest
            AND  sp.codprod = p.codprod
      AND ROWNUM = 1) codcest,
        NVL(p.tipomerc,'L') tipomerc,
        p.nbm,
        NVL(NVL(e.pcomrep1,p.pcomrep1),0) comissao,
        (CASE
            WHEN e.dtinativo IS NOT NULL
                 THEN 'N'
            WHEN f.proibidavenda = 'N'
                 THEN 'N'
            WHEN p.dtexclusao IS NOT NULL
                 THEN 'N'
            ELSE
                    'S'
         END) ativo,
    p.volume volume_prod
  FROM  pcembalagem e,
        pcprodut p,
        pcprodfilial f,
        PCDEPARAPRODC5 c,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  p.codprod = e.codprod
   AND  e.codprod = f.codprod
   AND  e.codfilial = f.codfilial
   AND  e.codfilial = C5.codfilial
   AND  f.codfilial = C5.codfilial
   AND  c.codprod = e.codprod
   AND  (CASE WHEN P.tipomerc IN ('CB', 'KT') THEN 1 ELSE LENGTH (p.nbm)  END ) >= (CASE WHEN P.tipomerc IN ('CB', 'KT') THEN  1  ELSE 2 END )
   AND  e.codprod >= 0
   AND  f.codprod >= 0 )
   
\

CREATE OR REPLACE VIEW VW_INT_C5_CBENEF AS 
  SELECT  DISTINCT codprod, 
        codbeneficiofiscal, 
        cfop,
        codst,
        cst,
        numregiao,
        codfilial
  FROM (SELECT /*+ index(t PCTRIBUT_PK) */
               e.codfilial codfilial,
               r.codprod codprod,
               f.uf uforigem,
               f.uf ufdestino,
               r.codst,
               t.sittribut cst,
               t.codfiscal cfop,
               trib.codigobeneficio codbeneficiofiscal,
               r.numregiao
          FROM pctabpr r,
               pctribut t,
               pcembalagem e,
               pcfilial f,
               (SELECT codigobeneficio,
                       ufdestino,
                       codfiscal,
                       sittribut
                  FROM pccodigobeneficiofiscalvinculo i
                 WHERE i.codfiscal > 0 
                   AND i.sittribut IS NOT NULL) trib
         WHERE r.codst = t.codst
           AND t.sittribut = trib.sittribut
           AND r.codprod = e.codprod
           AND e.codfilial = f.codigo
           AND f.uf = trib.ufdestino
           AND t.sittribut IN ('00','20','40','41','60','90'))

\

CREATE OR REPLACE VIEW VW_INT_C5_COBRANCA_WINTHOR AS 
  (SELECT o.codcob,
        (CASE
            WHEN o.codcob = 'BK'
                THEN 'B'
            WHEN o.codcob IN ('CHP','CHV')
                THEN 'B'
            WHEN o.codcob = 'D'
                THEN 'D'
            WHEN NVL(o.tipooperacaotef,'02') = '02'
                 AND
                 NVL(o.cartao,'N') = 'S'
                THEN 'R'
            WHEN NVL(o.tipooperacaotef,'02') IN ('01','03')
                 AND
                 NVL(o.cartao,'N') = 'S'
                THEN 'E'
            WHEN NVL(o.tipooperacaotef,'02') = '99'
                THEN 'S'
            WHEN NVL(o.carteiradigital,'N') = 'S'
                THEN 'G'
            WHEN o.codcob = 'CRED'
                THEN 'I'
            WHEN o.codcob = 'CONV'
                THEN 'V'
            ELSE
                'D'
         END) especie,
        NVL(o.nivelvenda,10) nivel,
        o.boleto,
        NVL(o.cartao,'N') cartao,
        o.codclicc,
        LPAD(NVL(o.codoperadoracartao,'0'), 5, '0') codoperadoracarto,
        LPAD(NVL(o.codbandeira,0),5,'0') codbandeira,
        REPLACE(REPLACE(REPLACE(c.cgcent, '.', ''), '/', ''), '-', '') cnpjcredenccartao,
        NVL(o.codbandeiraoperadoracartao,'99') codcobsefaz,
        (CASE
            WHEN NVL(o.tipooperacaotef,'02') = '01'
                THEN '0100'
            WHEN NVL(o.tipooperacaotef,'02') = '02'
                 AND
                 NVL(o.tipopagtoecf,'T') = 'P'
                THEN '0202'
            WHEN NVL(o.tipooperacaotef,'02') = '02'
                 AND
                 NVL(o.tipopagtoecf,'T') IN ('A','T')
                THEN '0200'
      WHEN NVL(o.tipooperacaotef,'02') = '03'
          THEN '0300'
            ELSE
                '0000'
         END) modalidadetef,
     NVL(o.tipooperacaotef,'02') tipooperacaotef,
     (CASE NVL(o.tipopagtoecf,'T')
      WHEN 'A' THEN  '00'
      WHEN 'P' THEN  '02'
      ELSE 'T'
     END) tipopagtotef,
         NVL(o.nomecarteiradigital,'N') nomecarteiradigital,
        (CASE
            WHEN NVL(o.carteiradigital,'N') = 'S'
                 AND
                 o.nomecarteiradigital = 'shipaypagador'
                THEN '30099'
            WHEN NVL(o.carteiradigital,'N') = 'S'
                 AND
                 o.nomecarteiradigital = 'pix'
                THEN '3001'
            WHEN NVL(o.carteiradigital,'N') = 'S'
                 AND
                 o.nomecarteiradigital = 'mercadopago'
                THEN '3002'
            WHEN NVL(o.carteiradigital,'N') = 'S'
                 AND
                 o.nomecarteiradigital = 'ame'
                THEN '3004'
            WHEN NVL(o.carteiradigital,'N') = 'S'
                 AND
                 o.nomecarteiradigital = 'picpay'
                THEN '3003'
            ELSE
                '0000'
         END) idcarteira,
        NVL(o.carteiradigital,'N') carteiradigital,
    o.codfilial
  FROM  pccob o,
        pcclient c
 WHERE  o.codclicc = c.codcli(+)
   AND  o.exportarecf = 'S'
   AND  o.codcob NOT IN ('BNFT','DEVT','DEVP','DNI','TK','CH','CHD1','CHD2','CHD3','CHDV','DBFM','DBFV','DBFV','DEP','DH','JUR','PEND','ESTR'))

\

CREATE OR REPLACE VIEW VW_INT_C5_FINALIZ_VENDA AS
(
    SELECT  f.codfilial,
            f.codfinalizadora nroformapagto,
            SUBSTR(f.descricao,1,40) formapagto,
            (CASE
                WHEN f.especie = 'BK'
                    THEN 'B'
                WHEN f.especie IN ('CHP','CHV')
                    THEN 'C'
                WHEN f.especie IN ('CTC','DIG')
                    THEN 'R'
                WHEN f.especie = 'CTD'
                    THEN 'E'
                WHEN f.especie IN ('CNV','CONV')
                    THEN 'V'
                WHEN f.especie = 'CRED'
                    THEN 'I'
                WHEN f.especie = 'D'
                    THEN 'D'
                WHEN f.especie = 'PIX'
                    THEN 'G'
                WHEN f.especie LIKE 'POS%'
                    THEN 'S'
                ELSE 'S'
             END) especie,
            NVL(c.boleto,'N') boleto,
            (CASE
                WHEN f.dtinativacao IS NULL
                    THEN 'S'
                ELSE 'N'
             END) ativo,
            NVL(f.codcobintegracao,f.codcob) codcob,
            NVL(f.codplpagintegracao,f.codplpag) codplpag
    FROM    vw_int_c5_especie_formapgto vef,
            pcfinalizadora f,
            pccob c
    WHERE   f.especie = vef.winthor(+)
      AND   NVL(f.codcobintegracao,f.codcob) = c.codcob(+)
      AND   f.codfinalizadora >= 0
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PCDOCELETRONICO AS 
( SELECT  C5.codfilial codfilial,
        a.sequsuario codfunccx,
        TO_CHAR(a.dtamovimento,'YYYY-MM-DD') data,
        NULL dtexportacao,
        'N' exportado,
        a.nrocheckout numcaixa,
        case when x.docemissao = 'CE' then 'NOTAFISCAL' else TO_CHAR(x.NUMSERIESAT) end  numserieequip,
        case when x.docemissao = 'CE' then x.xmlnf else x.XMLSAT end xmlnfce,
        case when x.docemissao = 'CE' then x.XMLCANCNF else x.XMLCANCSAT end xmlnfcecancelamento,
        a.seqdocto,
    a.nroempresa
  FROM  monitorpdvmiddle.tb_docto a,
        VW_INT_C5_NFESAT x,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  a.nroempresa = x.nroempresa
   AND  a.nrocheckout = x.nrocheckout
   AND  a.seqdocto = x.seqdocto
   AND  C5.CODFILIALINTEGRACAO = a.nroempresa
   AND  C5.CODFILIALINTEGRACAO = x.nroempresa
)

\

CREATE OR REPLACE VIEW VW_INT_C5_TRIB_PIS AS 
  (
SELECT  c.codacesso codauxiliar,
        c5.codfilial,
        r.codprod,
        r.numregiao,
        p.codtribpiscofins,
        r.codst,
        p.sittribut,
        NVL(p.percpis,0) percpis,
        NVL(p.perccofins,0) perccofins,
        p.excluiricmsbasepiscofins,
        C5.codfilialintegracao nroempresa,
        e.seqproduto        
  FROM  monitorpdvmiddle.tb_produto e,  --vw_int_c5_pcprodut E,
        monitorpdvmiddle.tb_prodcodigo c,
        vw_int_c5_obter_filiais_c5 C5,
        pctabpr r,
        pctribpiscofins p
 WHERE  e.codproduto = r.codprod
   AND  r.codtribpiscofins = p.codtribpiscofins
   AND  p.codtribpiscofins > 0
   AND  c.seqproduto = e.seqproduto
   AND  c.nroempresa = c5.codfilialintegracao
   AND  r.numregiao = ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',c5.codfilial,1)
)

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_ESPECIE_COB_VENDAS (pSeqDocto    IN NUMBER,
                                                          pNumeroCaixa IN NUMBER,
                                                          pNroCheckout IN NUMBER,
                                                          pSeqItem IN NUMBER)
    RETURN VARCHAR2
IS
    vCodCob   VARCHAR2(4);
    vCodCobF  VARCHAR2(4);
    vEspecie  VARCHAR2(1);
BEGIN
  begin
    SELECT  f.especie, a.codcob
      INTO  vEspecie, vCodCobF
      FROM  monitorpdvmiddle.tb_doctopagto p,
            monitorpdvmiddle.tb_formapagto f,
            VW_INT_C5_FINALIZ_VENDA a,
      VW_INT_C5_OBTER_FILIAIS_C5 C5
     WHERE  p.nroformapagto = f.nroformapagto
       AND  f.nroformapagto = a.NROFORMAPAGTO
     AND  C5.CODFILIALINTEGRACAO = p.nroempresa
       AND  p.seqitem = pSeqItem
       AND  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pNroCheckout
       AND  p.nrocheckout = pNumeroCaixa;
  end;

  if vEspecie in ('R','E') then
    
    begin
      SELECT  a.CODCOB
        INTO  vCodCob
        FROM  monitorpdvmiddle.tb_doctopagto p,
              monitorpdvmiddle.tb_formapagto f,
            VW_INT_C5_COBRANCA_WINTHOR a
     WHERE  p.nroformapagto = f.nroformapagto
       AND  f.ESPECIE = a.ESPECIE
         AND  p.seqitem = pSeqItem
         AND  p.seqdocto = pSeqDocto
         AND  p.nroempresa = pNroCheckout
     AND  P.CODREDETEF = LPAD(A.CODOPERADORACARTO, 5, '0')
         AND  p.codbandeiratef = a.codbandeira(+)
         AND  p.nrocheckout = pNumeroCaixa
     AND ( (NVL(a.codfilial,'99') ='99') OR (a.codfilial = (SELECT C5.CODFILIAL 
                                                      FROM VW_INT_C5_OBTER_FILIAIS_C5 C5 
                             WHERE C5.codfilialintegracao = p.NROEMPRESA)))
     AND ((A.modalidadetef = P.MODALIDADETEF) OR
              (a.tipooperacaotef = substr(p.modalidadetef, 1, 2) AND
              (A.tipopagtotef = 'T' OR
               A.tipopagtotef = SUBSTR(p.modalidadetef, 3, 2))));
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
      SELECT  a.CODCOB
        INTO  vCodCob
        FROM  monitorpdvmiddle.tb_doctopagto p,
              monitorpdvmiddle.tb_formapagto f,
              VW_INT_C5_COBRANCA_WINTHOR a
       WHERE  p.nroformapagto = f.nroformapagto
         AND  f.ESPECIE = a.ESPECIE
         AND  p.seqitem = pSeqItem
         AND  p.seqdocto = pSeqDocto
         AND  p.nroempresa = pNroCheckout
     AND  P.CODREDETEF = LPAD(A.CODOPERADORACARTO, 5, '0')
         AND  p.codbandeiratef = a.codbandeira(+)
         AND  p.nrocheckout = pNumeroCaixa
     AND ( (NVL(a.codfilial,'99') = '99') OR (a.codfilial = (SELECT C5.CODFILIAL 
                                                      FROM VW_INT_C5_OBTER_FILIAIS_C5 C5 
                             WHERE C5.codfilialintegracao = p.NROEMPRESA)))
     AND ((A.modalidadetef = P.MODALIDADETEF) OR
              (a.tipooperacaotef = substr(p.modalidadetef, 1, 2) AND
              (A.tipopagtotef = 'T' OR
               A.tipopagtotef = SUBSTR(p.modalidadetef, 3, 2))))
         AND  ROWNUM = 1;     
      WHEN OTHERS THEN
         vCodCob := 'CAR';
    end;
  
  elsif vEspecie = 'S' then
    begin
         vCodCob := 'CAR';
    end;
     
  elsif vEspecie = 'G' then
   begin
      SELECT  a.CODCOB
        INTO  vCodCob
        FROM  monitorpdvmiddle.tb_doctopagto p,
              monitorpdvmiddle.tb_formapagto f,
              VW_INT_C5_COBRANCA_WINTHOR a
       WHERE  p.nroformapagto = f.nroformapagto
         AND  f.ESPECIE = a.ESPECIE
         AND  p.seqitem = pSeqItem
         AND  p.seqdocto = pSeqDocto
         AND  p.nroempresa = pNroCheckout
         AND  p.idcarteira = a.idcarteira(+)
         AND  p.nrocheckout = pNumeroCaixa
         AND  ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        vCodCob := 'D';
    end;
     
  else
    begin
    SELECT  a.CODCOB
      INTO  vCodCob
      FROM  monitorpdvmiddle.tb_doctopagto p,
            monitorpdvmiddle.tb_formapagto f,
            VW_INT_C5_FINALIZ_VENDA a
     WHERE  p.nroformapagto = f.nroformapagto
       AND  f.nroformapagto = a.NROFORMAPAGTO
       AND  p.seqitem = pSeqItem
       AND  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pNroCheckout
       AND  p.nrocheckout = pNumeroCaixa;
    exception
      when others then
        vCodCob := 'D'; 
    end;
        
  end if;

  RETURN(NVL(vCodCobF ,vCodCob));
END;


\

CREATE OR REPLACE FUNCTION fnc_int_c5_cab_total_acresc(pSeqDocto NUMBER,
                                                       pNroCheckout NUMBER,
                                                       pNroEmpresa NUMBER)
    RETURN NUMBER
IS
    vTotalAcresc NUMBER;
BEGIN
   SELECT   SUM(z.vlracrescimo)
      INTO  vTotalAcresc
      FROM  monitorpdvmiddle.tb_doctopagto z,
            monitorpdvmiddle.tb_docto a
     WHERE  z.nroempresa = a.nroempresa
       AND  z.nrocheckout = a.nrocheckout
       AND  z.seqdocto = a.seqdocto
       AND  a.especie = 'NF'
       AND  z.nroempresa = pNroEmpresa
       AND  z.nrocheckout = pNroCheckout
       AND  z.seqdocto = pSeqDocto;
   RETURN(vTotalAcresc);
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_FINALIZADORA_CAB (pSeqDocto NUMBER,
                                      pNroCheckout NUMBER,
                                      pNroEmpresa NUMBER)
    RETURN VARCHAR2
IS
    vFinalizadora VARCHAR2(4);

BEGIN
SELECT  CASE
            WHEN p.nroformapagto in (SELECT DISTINCT
                                           f.nroformapagto
                                      FROM monitorpdvmiddle.tb_formapagto f)
                THEN p.nroformapagto
            ELSE
                0
         END
  INTO  vFinalizadora
  FROM  monitorpdvmiddle.tb_doctopagto p,
        monitorpdvmiddle.tb_docto a
 WHERE  p.seqdocto = a.seqdocto
   AND  p.NROEMPRESA = a.NROEMPRESA
   AND  p.NROCHECKOUT = a.nrocheckout
   AND  a.seqdocto = pSeqDocto
   AND  a.nroempresa = pNroEmpresa
   AND  a.nrocheckout = pNroCheckout
   AND  ROWNUM = 1;
 RETURN(vFinalizadora);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_BUSCATRIB(pNroEmpresa  NUMBER,
                                                pNroCheckout    NUMBER,
                                                pSeqdocto    NUMBER,
                                                pSeqItem     NUMBER,
                        pSeqTipoTrib NUMBER,
                        pCampo       VARCHAR2)
    RETURN VARCHAR2
IS
    vReturn VARCHAR2(100);
  vExecSQL VARCHAR2(4000);
  vDataType VARCHAR2(200);
BEGIN

    BEGIN
       SELECT  C.DATA_TYPE
       INTO vDataType
       FROM ALL_TAB_COLUMNS C
       WHERE C.TABLE_NAME = 'TB_DOCTOTRIBUTACAOITEM'
       AND C.COLUMN_NAME = pCampo
       AND C.OWNER = 'MONITORPDVMIDDLE';
    EXCEPTION
    WHEN OTHERS THEN 
     vDataType := 'NAO_EXISTE';
  END;

    IF vDataType <> 'NAO_EXISTE' THEN
    BEGIN
    vExecSQL := ' SELECT ';

    IF vDataType = 'NUMBER' THEN
      vExecSQL := vExecSQL || ' TO_CHAR(' || pCampo ||') ';
    ELSE 
      vExecSQL := vExecSQL || pCampo || ' ';        
    END IF;

    vExecSQL := vExecSQL || 
    ' FROM MONITORPDVMIDDLE.TB_DOCTOTRIBUTACAOITEM I ' ||
    ' WHERE I.SEQDOCTO = :1 ' ||
    ' AND I.NROEMPRESA = :2 ' ||
    ' AND I.NROCHECKOUT = :3 ' ||
    ' AND I.SEQITEM = :4 ' ||
    ' AND I.SEQTIPOTRIBUTACAO = :5';            

    EXECUTE IMMEDIATE vExecSQL INTO vReturn
      USING pSeqDocto, pNroEmpresa, pNroCheckout, pSeqItem, pSeqTipoTrib;
    
    EXCEPTION
            WHEN OTHERS THEN
                vReturn := NULL;
      END;
  END IF;
  RETURN vReturn;
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_EXBENEF(pSeqFamilia  NUMBER,
                                                pUF    VARCHAR2)
    RETURN VARCHAR2
IS
    vReturn VARCHAR2(10);
BEGIN

SELECT  T.CODAJUSTEEFD 
  INTO  vReturn
  FROM  MONITORPDVMIDDLE.TB_CADOBSSPEDFAMILIA T
 WHERE  T.SEQFAMILIA = pSeqFamilia
   AND  T.UF = pUF;
 RETURN(vReturn);
  EXCEPTION
   WHEN OTHERS then
     RETURN NULL; 
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_codplpag_venda(pNroFormaPagto NUMBER,
                             pCodFilial     VARCHAR2)
    RETURN NUMBER
IS
    vCodPlPag NUMBER;
BEGIN
    SELECT  a.codplpag
      INTO  vCodPlPag
      FROM  VW_INT_C5_FINALIZ_VENDA a,
            monitorpdvmiddle.tb_doctopagto p,
            monitorpdvmiddle.tb_docto d,
      VW_INT_C5_OBTER_FILIAIS_C5 C5
     WHERE  p.nroformapagto = a.nroformapagto
       AND  p.nroempresa = d.nroempresa
     AND  p.seqdocto = d.seqdocto
     AND  p.nrocheckout = d.nrocheckout
       AND  a.nroformapagto = pNroFormaPagto
     AND  C5.codfilialintegracao = d.NROEMPRESA
     AND  C5.codfilialintegracao = p.NROEMPRESA
     AND  a.codfilial = c5.codfilial
       AND  a.codfilial = pCodFilial
       AND  ROWNUM = 1;
    RETURN(vCodPlPag);
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_VLTOTAL (pSeqDocto number,
                                                   pNroCheckout NUMBER,
                                                   pNroEmpresa NUMBER)
    RETURN NUMBER
IS
    vTotal NUMBER;

BEGIN
    SELECT  SUM(p.valor)
      INTO  vTotal
      FROM  monitorpdvmiddle.tb_doctopagto p
     WHERE  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pNroEmpresa
       AND  p.nrocheckout = pNroCheckout;
    RETURN(vTotal);
END;

\

CREATE OR REPLACE VIEW VW_INT_C5_PLANOP_VENDA AS
(SELECT  p.codplpag,
        g.nroformapagto,
        g.seqitem,
        g.seqdocto,
        g.nroempresa,
        g.nrocheckout,
        NVL(p.numdias,0) numdias,
        NVL(p.prazo1,0) prazo1,
        NVL(p.prazo2,0) prazo2,
        NVL(p.prazo3,0) prazo3,
        NVL(p.prazo4,0) prazo4,
        NVL(p.prazo5,0) prazo5,
        NVL(p.prazo6,0) prazo6,
        NVL(p.prazo7,0) prazo7,
        NVL(p.prazo8,0) prazo8,
        NVL(p.prazo9,0) prazo9,
        NVL(p.prazo10,0) prazo10,
        NVL(p.prazo11,0) prazo11,
        NVL(p.prazo12,0) prazo12,
        NVL(p.tipovenda,'VV') tipovenda
  FROM  pcplpag p,
        monitorpdvmiddle.tb_doctopagto g,
        monitorpdvmiddle.tb_docto a,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  g.seqdocto = a.seqdocto
   AND  g.nroempresa = a.nroempresa
   AND  g.nrocheckout = a.nrocheckout
   AND  g.nroempresa = C5.CODFILIALINTEGRACAO
   AND  a.nroempresa = C5.codfilialintegracao
   AND  a.especie = 'NF'
   AND  p.codplpag = NVL(fnc_int_c5_codplpag_venda(g.nroformapagto,C5.codfilial),1)
   AND  p.codplpag > 0)

\

CREATE OR REPLACE FUNCTION fnc_int_c5_cab_total_vol(pSeqDocto NUMBER,
                                                    pNroCheckout NUMBER,
                                                    pNroEmpresa NUMBER)
    RETURN NUMBER
IS
    vTotalVol NUMBER;
BEGIN
SELECT  SUM(NVL(a.volume_prod,0))
  INTO  vTotalVol
  FROM  monitorpdvmiddle.tb_doctoitem i,
        VW_INT_C5_PCPRODUT a
 WHERE  i.nroempresa = a.nroempresa
   AND  i.codacesso = a.codauxiliar
   AND  i.seqproduto = a.seqproduto
   AND  i.seqdocto = pSeqDocto
   AND  i.nroempresa = pNroEmpresa
   AND  i.STATUS = 'V'
   AND  i.nrocheckout = pNroCheckout;
 RETURN(vTotalVol);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_tipovenda_pag_venda(pNroFormaPagto NUMBER,
                                                          pnroempresa    NUMBER,
                                                          pNumcheckout   NUMBER,
                              pseqdocto      NUMBER)
    RETURN CHAR
IS
    vTipoVenda CHAR(2);
BEGIN
    SELECT  a.tipovenda
      INTO  vTipoVenda
      FROM  VW_INT_C5_PLANOP_VENDA a,
            monitorpdvmiddle.tb_doctopagto p
     WHERE  p.nroformapagto = a.nroformapagto
       AND  p.nroempresa = a.nroempresa
        AND p.nrocheckout = a.nrocheckout
       AND  p.seqdocto = a.seqdocto    
       AND  a.nroformapagto = pNroFormaPagto
       AND  a.nroempresa = pnroempresa
     AND  a.nrocheckout = pNumcheckout
     AND  a.seqdocto = pseqdocto
       AND  ROWNUM = 1;
  
    RETURN(vTipoVenda);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_praca_cli (pseqpessoa IN NUMBER)
    RETURN NUMBER
IS
    vcodpraca   NUMBER;
BEGIN
    SELECT NVL(c.codpraca,0)
      INTO vcodpraca
      FROM pcclient c
     WHERE c.codcli = DECODE(NVL(pseqpessoa,0),0,1,pseqpessoa);

    RETURN (vcodpraca);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_codsuperv (pSeqUsuario IN NUMBER)
    RETURN NUMBER
IS
    vCodSupervisor NUMBER;
BEGIN
    SELECT  NVL(c.codsupervisor,1)
      INTO  vCodSupervisor
      FROM  pcusuari c,
            pcempr r
     WHERE  r.codusur = c.codusur
       AND  r.matricula = pSeqUsuario;
    RETURN(vCodSupervisor);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_tot_custofin (pSeqDocto IN NUMBER,
                                  pNumeroCaixa IN NUMBER,
                                  pNroEmpresa IN NUMBER)
    RETURN NUMBER
IS
    vTotalCustoFin NUMBER;
BEGIN
    SELECT  SUM(s.vlcustofin)
      INTO  vTotalCustoFin
      FROM  vw_int_c5_custos s,
            monitorpdvmiddle.tb_doctoitem i,
      VW_INT_C5_OBTER_FILIAIS_C5 C5
     WHERE  i.nroempresa = C5.CODFILIALINTEGRACAO
     AND  C5.CODFILIAL = s.codfilial
       AND  i.codacesso = s.codauxiliar
       AND  i.seqdocto = pSeqDocto
       AND  I.nroempresa = pNroEmpresa
     AND  i.STATUS = 'V'
       AND  i.nrocheckout = pNumeroCaixa;
    RETURN(vTotalCustoFin);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_numitens (pSeqDocto IN NUMBER,
                              pNumeroCaixa IN NUMBER,
                              pNroEmpresa IN NUMBER)
    RETURN NUMBER
IS
    vNumItens NUMBER;
BEGIN
    SELECT  COUNT(i.seqdocto)
      INTO  vNumItens
      FROM  monitorpdvmiddle.tb_doctoitem i
     WHERE  i.seqdocto = pSeqDocto
       AND  i.nrocheckout = pNumeroCaixa
     AND  i.STATUS = 'V'
       AND  i.nroempresa = pNroEmpresa
     AND (
        i.SEQPRODCOMPOSTO IS NOT NULL 
        AND i.seqitem = (
                SELECT min(x.seqitem) 
                FROM monitorpdvmiddle.tb_doctoitem X 
                WHERE x.seqdocto = i.seqdocto 
                  AND x.nroempresa = i.nroempresa
                  AND x.nrocheckout = i.nrocheckout
                  AND x.seqprodcomposto = i.seqprodcomposto
                  AND X.SEQITEMPRODCOMPOSTO = i.SEQITEMPRODCOMPOSTO
                )
        OR 
        i.SEQPRODCOMPOSTO IS NULL 
    );
    RETURN(vNumItens);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_perdesc_acresc_r(pNroEmpresa   NUMBER,
                                                       pNroCheckout    NUMBER,
                                                       pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vPerAcrescimoRodape NUMBER;
BEGIN

SELECT
        (CASE
            WHEN i.VLRACRESCIMO > 0
                 AND
                 i.seqdocto IN (SELECT seqdocto
                                  FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                                 WHERE z.NROEMPRESA = i.NROEMPRESA
                                   AND z.NROCHECKOUT = i.NROCHECKOUT
                                   AND z.SEQTIPOACRESCDESCTO = 7)
                THEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6)
           ELSE
              0
         END)
  INTO   vPerAcrescimoRodape
  FROM  monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        monitorpdvmiddle.tb_doctoitem i
 WHERE  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqdocto = d.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.especie = 'NF'
   AND  d.replicacao = 'P'
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.STATUS = 'V'
   AND  i.seqdocto = pSeqDocto
   AND  ROWNUM = 1;
  RETURN(vPerAcrescimoRodape);
  EXCEPTION
     WHEN OTHERS
          THEN
     RETURN 0;
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_perdesc_desc_r(pNroEmpresa   NUMBER,
                                                     pNroCheckout    NUMBER,
                                                     pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vPerDescRodape NUMBER;
BEGIN

 SELECT  (CASE
            WHEN i.vlrdesconto > 0
                 THEN a.VALOR
           ELSE
              0
          END)
  INTO  vPerDescRodape
  FROM  monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        monitorpdvmiddle.tb_doctoitem i,
        monitorpdvmiddle.TB_DOCTOACRESCDESCTO a
 WHERE  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqdocto = d.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  a.NROEMPRESA = d.nroempresa
   AND  a.nrocheckout = d.NROCHECKOUT
   AND  a.seqdocto = d.seqdocto
   AND  a.SEQTIPOACRESCDESCTO = 1
   AND  d.especie = 'NF'
   AND  d.replicacao = 'P'
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.STATUS = 'V'
   AND  i.seqdocto = pSeqDocto
   AND  ROWNUM = 1;
  RETURN(vPerDescRodape);
  EXCEPTION
     WHEN OTHERS
          THEN
     RETURN 0;
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_total_acresc_r(pNroEmpresa   NUMBER,
                                                     pNroCheckout    NUMBER,
                                                     pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vTotalAcrescimoRodape NUMBER;
BEGIN

SELECT  SUM(
        (CASE
            WHEN i.VLRACRESCIMO > 0
                 AND
                 i.seqdocto IN (SELECT seqdocto
                                  FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                                 WHERE z.NROEMPRESA = i.NROEMPRESA
                                   AND z.NROCHECKOUT = i.NROCHECKOUT
                                   AND z.SEQTIPOACRESCDESCTO = 7)
                THEN i.VLRACRESCIMO
           ELSE
              0
         END))
  INTO   vTotalAcrescimoRodape
  FROM  monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        monitorpdvmiddle.tb_doctoitem i
 WHERE  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqdocto = d.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.especie = 'NF'
   AND  d.replicacao = 'P'
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.STATUS = 'V'
   AND  i.seqdocto = pSeqDocto;
  RETURN(vTotalAcrescimoRodape);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_valordesc_acresc_r(pNroEmpresa   NUMBER,
                                                       pNroCheckout    NUMBER,
                                                       pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vValorAcrescimoRodape NUMBER;
BEGIN

 SELECT
        sum(i.VLRACRESCIMO )   
  INTO  vValorAcrescimoRodape
  FROM  monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        monitorpdvmiddle.tb_doctoitem i
 WHERE  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqdocto = d.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.especie = 'NF'
   AND  exists (SELECT * FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO a WHERE a.SEQTIPOACRESCDESCTO IN (1,2))
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.STATUS = 'V'
   AND  i.seqdocto = pSeqDocto;
  RETURN(vValorAcrescimoRodape);
  EXCEPTION
     WHEN OTHERS
          THEN
     RETURN 0;
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_valordesc_desc_r(pNroEmpresa   NUMBER,
                                                     pNroCheckout    NUMBER,
                                                     pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vValorDescRodape NUMBER;
BEGIN

 SELECT  
        sum(i.vlrdesconto)
  INTO  vValorDescRodape
  FROM  monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        monitorpdvmiddle.tb_doctoitem i
 WHERE  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqdocto = d.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.especie = 'NF'
   AND  exists (SELECT * FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO a WHERE a.SEQTIPOACRESCDESCTO IN (1,2))
   AND  d.replicacao = 'P'
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.STATUS = 'V'
   AND  i.seqdocto = pSeqDocto;
  RETURN(vValorDescRodape);
  EXCEPTION
     WHEN OTHERS
          THEN
     RETURN 0;
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_cab_total(pSeqDocto NUMBER,
                                                pNroCheckout NUMBER,
                                                pNroEmpresa NUMBER)
    RETURN NUMBER
IS
    vTotal NUMBER;
BEGIN
   SELECT   SUM(z.vlrtotal)
      INTO  vTotal
      FROM  monitorpdvmiddle.tb_doctoitem z,
            monitorpdvmiddle.tb_docto a
     WHERE  z.nroempresa = a.nroempresa
       AND  z.nrocheckout = a.nrocheckout
       AND  z.seqdocto = a.seqdocto
       AND  a.especie = 'NF'
       AND  z.nroempresa = pNroEmpresa
       AND  z.nrocheckout = pNroCheckout
     AND  z.STATUS = 'V'
       AND  z.seqdocto = pSeqDocto;
   RETURN(vTotal);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_total_ptabela(pNroEmpresa   NUMBER,
                                                     pNroCheckout    NUMBER,
                                                     pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vTotalPTabela NUMBER;
BEGIN

SELECT  SUM(i.VLRUNITARIO*i.quantidade)
  INTO   vTotalPTabela
  FROM  monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        monitorpdvmiddle.tb_doctoitem i
 WHERE  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqdocto = d.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.especie = 'NF'
   AND  d.replicacao = 'P'
   AND  i.STATUS = 'V'
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.seqdocto = pSeqDocto;
  RETURN(vTotalPTabela);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_vlacrescimofcp(pNroEmpresa  NUMBER,
                                                     pNroCheckout   NUMBER,
                                                     pSeqdocto   NUMBER,
                                                     pSeqItem    NUMBER)
    RETURN NUMBER
IS
    vVlAcrescimoFCP NUMBER;
BEGIN

SELECT  CASE
            WHEN a.percaliqfcpicms = 0
                 THEN 0
            WHEN a.percaliqfcpicms > 0
                 AND
                 a.sittribut IN ('00','20','90')
                 THEN  ((CASE
                            WHEN i.VLRACRESCIMO > 0
                                 THEN i.vlrunitario + (i.vlracrescimo/ i.quantidade)
                            WHEN i.VLRDESCONTO > 0
                                 THEN i.vlrunitario - (i.vlrdesconto/ i.quantidade)
                            ELSE
                              i.VLRUNITARIO
                         END) * t.vlrbase)
         END
  INTO  vVlAcrescimoFCP
  FROM  monitorpdvmiddle.tb_doctoitem i,
        monitorpdvmiddle.tb_doctotributacaoitem t,
        pcconsolidatributacao a
 WHERE  i.nroempresa = t.nroempresa
   AND  i.nrocheckout = t.nrocheckout
   AND  i.seqdocto = t.seqdocto
   AND  i.seqitem = t.seqitem
   AND  i.nrotributacao = a.codst
   AND  t.seqtipotributacao = 11
   AND  i.status = 'V'
   and  a.numregiao = ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',i.nroempresa,1)
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.seqdocto = pSeqdocto
   AND  i.STATUS = 'V'
   AND  i.seqitem = pSeqItem
   AND ROWNUM = 1;
   
   
   
 RETURN(vVlAcrescimoFCP);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_vldescitem(pNroEmpresa NUMBER,
                                                 pNroCheckout  NUMBER,
                                                 pSeqdocto  NUMBER,
                                                 pNumSeq    NUMBER)
    RETURN NUMBER
IS
    vVlDesc NUMBER;
BEGIN
 vVlDesc := 0;
SELECT  i.vlrdesconto/NVL(i.quantidade,1)
 INTO   vVlDesc
 FROM   monitorpdvmiddle.tb_doctoitem i,
        monitorpdvmiddle.tb_doctoacrescdesctoitem ia,
        monitorpdvmiddle.tb_doctoacrescdescto a
 WHERE  i.nroempresa = a.nroempresa
   AND  i.nrocheckout = a.nrocheckout
   AND  ia.seqitem = i.seqitem
   AND  i.seqdocto = a.seqdocto
   AND  ia.seqdocto = a.seqdocto
   AND  ia.nrocheckout = a.nrocheckout
   and  ia.nroempresa = a.nroempresa
   and  ia.seqacrescdescto = a.seqacrescdescto
   AND  i.seqdocto = pSeqdocto
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout
   AND  i.STATUS = 'V'
   AND  i.seqitem = pNumSeq
   AND  a.seqtipoacrescdescto = 2
   AND  i.vlrdesconto = (a.valor) * -1;
 RETURN(vVlDesc);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_vldesoneracao(pNroEmpresa  NUMBER,
                                                    pNumCaixa   NUMBER,
                                                    pSeqdocto   NUMBER,
                                                    pSeqItem    NUMBER)
    RETURN NUMBER
IS
    vVlDeson NUMBER;
BEGIN

SELECT  (CASE
            WHEN a.codmotivodesoneracao > 0
                 AND
                 a.sittribut = '20'
                 AND
                 a.perctributado <> 100
                 AND
                 ferramentas.F_BUSCARPARAMETRO_ALFA('AGREGAVLDESONBASEDESON',i.nroempresa,'N') = 'S'
                THEN  ((CASE
                            WHEN i.VLRACRESCIMO > 0
                                 THEN i.vlrunitario + (i.vlracrescimo/ i.quantidade)
                            WHEN i.VLRDESCONTO > 0
                                 THEN i.vlrunitario - (i.vlrdesconto/ i.quantidade)
                            ELSE
                              i.VLRUNITARIO
                         END) * (1 -(a.perctributado/ 100)))/ (1 - a.percaliquota/ 100) * (a.percaliquota/ 100)
            WHEN a.codmotivodesoneracao > 0
                 AND
                 a.sittribut = '20'
                 AND
                 a.perctributado <> 100
                 AND
                 ferramentas.F_BUSCARPARAMETRO_ALFA('AGREGAVLDESONBASEDESON',i.nroempresa,'N') = 'N'
                THEN  ((CASE
                            WHEN i.VLRACRESCIMO > 0
                                 THEN i.vlrunitario + (i.vlracrescimo/ i.quantidade)
                            WHEN i.VLRDESCONTO > 0
                                 THEN i.vlrunitario - (i.vlrdesconto/ i.quantidade)
                            ELSE
                              i.VLRUNITARIO
                         END) * (1 -(a.perctributado/ 100)))/ (1 - a.percaliquota/ 100)
            ELSE
             0
         END)/ v.qtunit
  INTO  vVlDeson
  FROM  monitorpdvmiddle.tb_doctoitem i,
        monitorpdvmiddle.tb_doctotributacaoitem t,
        pcconsolidatributacao a,
        vw_int_c5_pcprodut v
 WHERE  i.nroempresa = t.nroempresa
   AND  i.nrocheckout = t.nrocheckout
   AND  i.seqdocto = t.seqdocto
   AND  i.seqitem = t.seqitem
   AND  i.nrotributacao = a.codst
   AND  i.nroempresa = v.nroempresa
   AND  i.seqproduto = v.seqproduto
   AND  i.codacesso = v.codauxiliar
   AND  t.seqtipotributacao = 15
   AND  a.numregiao = ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',i.nroempresa,1)
   AND  i.status = 'V'
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqdocto = pSeqdocto
   AND  i.seqitem = pSeqItem;
 RETURN(vVlDeson);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_nome_pix (pIdCarteira IN NUMBER)
    RETURN VARCHAR2
IS
    vNome VARCHAR2(60);

BEGIN

SELECT  DISTINCT
        o.nomecarteiradigital
  INTO  vNome
  FROM  pccob o,
        vw_int_c5_pix v
 WHERE  o.carteiradigital = 'S'
   AND  o.nomecarteiradigital = v.nomecarteira
   AND  v.idcarteira = pIdCarteira;
 RETURN(vNome);
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_PRAZOCC(pCODCOB IN VARCHAR2)
    RETURN NUMBER
IS
  vPRAZOCC NUMBER;
BEGIN
 vPRAZOCC := 0;
 BEGIN
 SELECT NVL(B.PRAZOCC, 0) PRAZOCC
   INTO vPRAZOCC
   FROM PCCOB B
  WHERE B.CODCOB = pCODCOB;
 END;
 RETURN(vPRAZOCC);
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_OBTERNUMPED(pSeqDocto NUMBER,
                                                  pNroEmpresa NUMBER,
                                                  pNroCheckout NUMBER)
RETURN NUMBER
IS 
  vNROPREVENDA NUMBER;
BEGIN
  SELECT 
    MAX(TB_DOCTOITEM.NROPREVENDA) NROPREVENDA
  INTO VNROPREVENDA
  FROM 
    MONITORPDVMIDDLE.TB_DOCTOITEM TB_DOCTOITEM
  WHERE TB_DOCTOITEM.SEQDOCTO = pSeqDocto
    AND TB_DOCTOITEM.NROEMPRESA = pNroEmpresa
    AND TB_DOCTOITEM.NROCHECKOUT = pNroCheckout;
    
  RETURN VNROPREVENDA;
END;

\


CREATE OR REPLACE FUNCTION FNC_INT_C5_OBTERNUMCAR(pSeqDocto NUMBER,
                                                  pNroEmpresa NUMBER,
                                                  pNroCheckout NUMBER)
RETURN NUMBER
IS 
  vNUMCAR NUMBER;
BEGIN
  vNUMCAR := 0;
  BEGIN
  SELECT 
    NUMCAR
  INTO vNUMCAR
  FROM 
    PCPEDC
  WHERE NUMPED = FNC_INT_C5_OBTERNUMPED(pSeqDocto, pNroEmpresa, pNroCheckout);
  EXCEPTION
  WHEN OTHERS THEN
   vNUMCAR := 0;
  END;  
  RETURN vNUMCAR;
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_CODAUXPRODCOMPOSTO(pseqprodcomposto NUMBER,
                                                                   pnroempresa NUMBER)
RETURN NUMBER
 IS
    vCODAUXILIAR NUMBER := 0;
          BEGIN
              BEGIN
                  SELECT CODACESSO
                  INTO vCODAUXILIAR
                  FROM (
                      SELECT P.CODACESSO
                      FROM MONITORPDVMIDDLE.TB_PRODCODIGO P
                      WHERE P.SEQPRODUTO = pseqprodcomposto
                        AND P.NROEMPRESA = pnroempresa
                        AND P.QTDEMBALAGEM = 1
                        AND P.ATIVO = 'S'
                      ORDER BY P.DTAHORINCLUSAO DESC
                  )
                  WHERE ROWNUM = 1;
              EXCEPTION
                  WHEN OTHERS THEN
                      vCODAUXILIAR := 0;
              END;
    RETURN vCODAUXILIAR;
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_CODCLIORCA(pSeqDocto NUMBER,
                                                  pNroEmpresa NUMBER,
                                                  pNroCheckout NUMBER)
RETURN number
IS 
   vCODCLI NUMBER;
BEGIN
   vCODCLI := 1;
   BEGIN
     SELECT C.CODCLI
   INTO vCODCLI
   FROM PCORCAVENDAC C
   WHERE C.NUMDOCTOPDV = pSeqDocto
     AND C.CODEMPRESAPDV = pNroEmpresa
     AND C.CODCHECKOUTPDV = pNroCheckout;
   EXCEPTION
     WHEN OTHERS THEN
    vCODCLI := 1;
   END;
   RETURN vCODCLI;
END;

\

CREATE OR REPLACE VIEW vw_int_c5_agrup_dinheiro AS
(
  SELECT P.NROEMPRESA,
       P.NROCHECKOUT,
       P.SEQDOCTO,
       P.nroformapagto,
       SUM(P.VLRTOTAL) AS VALOR,
       MAX(P.DTABASECOBRANCA) AS DTABASECOBRANCA,
       MAX(P.DTAVENCIMENTO) AS DTAVENCIMENTO,
       MIN(SEQITEM) SEQITEM,
       P.NROCARTAO
    FROM MONITORPDVMIDDLE.TB_DOCTOPAGTO P
   WHERE P.NROFORMAPAGTO IN
       (SELECT fp.nroformapagto
        FROM monitorpdvmiddle.tb_formapagto fp
       where fp.especie = 'D'
               and fp.formapagto LIKE '%DINHEIRO%')
     --AND P.VLRTOTAL > 0
     AND ( (case when FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_GERARTROCOCOBDIN', '99', 'N') = 'S' THEN
             P.VLRTOTAL
         end > 0
         )

         OR

         (case when FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_GERARTROCOCOBDIN', '99', 'N') <> 'S' THEN
             P.VLRTOTAL
          end = P.VLRTOTAL
         )
       )
   GROUP BY P.NROEMPRESA, P.NROCHECKOUT, P.SEQDOCTO, P.nroformapagto , P.NROCARTAO
)

\

CREATE OR REPLACE VIEW vw_int_c5_agrup_troco AS
(
SELECT P.NROEMPRESA,
       P.NROCHECKOUT,
       P.SEQDOCTO,
       SUM(P.VLRTOTAL) AS VALOR,
       MAX(P.DTABASECOBRANCA) AS DTABASECOBRANCA,
       MAX(P.DTAVENCIMENTO) AS DTAVENCIMENTO,
       MIN(SEQITEM) SEQITEM,
     P.nroformapagto,
     P.NROCARTAO
  FROM MONITORPDVMIDDLE.TB_DOCTOPAGTO P
 WHERE P.NROFORMAPAGTO IN
       (SELECT fp.nroformapagto
          FROM monitorpdvmiddle.tb_formapagto fp
         where fp.especie = 'D'
         and fp.formapagto LIKE '%DINHEIRO%')
   AND P.VLRTOTAL < 0
 GROUP BY P.NROEMPRESA, P.NROCHECKOUT, P.SEQDOCTO, P.nroformapagto, P.NROCARTAO
 )

\

CREATE OR REPLACE VIEW VW_INT_C5_TIPOCANCEL AS(
SELECT DISTINCT c.seqdocto,        
       c.nrocheckout,       
       c.nroempresa,       
       CASE WHEN i.status = 'C' AND c.status = 'V' THEN 'P'           
         ELSE 'T'       
       END Tipocancel 
 FROM  monitorpdvmiddle.tb_doctoitem i, monitorpdvmiddle.tb_doctocupom c, monitorpdvmiddle.tb_docto a 
 WHERE i.nrocheckout = a.nrocheckout   
       AND i.nroempresa = a.nroempresa   
       AND i.seqdocto = a.seqdocto   
       AND a.nrocheckout = c.nrocheckout   
       AND a.nroempresa = c.nroempresa   
       AND a.seqdocto = c.seqdocto   
       AND (i.status = 'C' OR c.status = 'C'))

\

CREATE OR REPLACE VIEW VW_INT_C5_PLANOP AS(
SELECT  p.codplpag,
        g.nroformapagto,
        g.seqitem,
        g.seqdocto,
        g.nroempresa,
        g.nrocheckout,
        NVL(p.numdias,0) numdias,
        NVL(p.prazo1,0) prazo1,
        NVL(p.prazo2,0) prazo2,
        NVL(p.prazo3,0) prazo3,
        NVL(p.prazo4,0) prazo4,
        NVL(p.prazo5,0) prazo5,
        NVL(p.prazo6,0) prazo6,
        NVL(p.prazo7,0) prazo7,
        NVL(p.prazo8,0) prazo8,
        NVL(p.prazo9,0) prazo9,
        NVL(p.prazo10,0) prazo10,
        NVL(p.prazo11,0) prazo11,
        NVL(p.prazo12,0) prazo12
  FROM  pcplpag p,
        monitorpdvmiddle.tb_doctopagto g,
        monitorpdvmiddle.tb_docto a
 WHERE  g.seqdocto = a.seqdocto
   AND  g.nroempresa = a.nroempresa
   AND  g.nrocheckout = a.nrocheckout
   AND  a.especie = 'NF'
   AND  p.codplpag = NVL(fnc_int_c5_codplpag(g.nroformapagto,g.nroempresa),1)
   AND  p.codplpag > 0)
  
\

CREATE OR REPLACE VIEW vw_int_c5_pcprestecf AS
( SELECT  d.seqdocto,
        p.nrocreditocupom numgiftcard,
        'N' exportado,
        (CASE
            WHEN (f.especie IN ('E','R','S')) or (NVL(p.qtdparcelatef,0) > 0)
                THEN NVL(r.parcela, p.nroparcela)
            ELSE
                NULL
         END) presttef,
        d.sequsuario codfunccheckout,
        d.nrocheckout numcheckout,
        'NOTAFISCAL' numserieequip,
        case when nf.DOCEMISSAO in ('SF', 'MF') then nf.NUMCUPOMSAT else c.nronotafiscal end duplic,
        NVL(TO_NUMBER(regexp_replace(P.NROCARTAO, '[^0-9]', '')) ,NVL(c.seqpessoa,1)) codcli,
        CASE WHEN FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem) = 'CONV' AND ((SELECT NVL(PL.FORMAPARCELAMENTO,'C') FROM PCPLPAG PL WHERE PL.CODPLPAG = F.codplpag ) = 'T'  )THEN
            TO_CHAR(FNC_INT_C5_CALCDIAFIXO(TRUNC(p.Dtahoremissao),FNC_INT_C5_DIASCARENCIA(p.nroformapagto), fnc_int_c5_DIAFIXO(p.nroformapagto) , TRUNC(SYSDATE)), 'YYYY-MM-DD' )
          ELSE 
            TO_CHAR(NVL(r.dtvenc,
                p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))) ),'YYYY-MM-DD')
        END dtvenc,
        NVL(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'D') codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        c5.codfilial codfilial,
        c5.codfilialintegracao, 
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(NVL(r.dtvenc,
                p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
          ),'YYYY-MM-DD') dtvencorig,
        'N' operacao,
        f.boleto,
        NULL numbanco,
        NULL numagencia,
        NULL numcheque,
        NVL(fnc_int_c5_codsuperv(d.sequsuario),1) codsupervisor,
        p.cmc7 codbarra,
        NVL(r.valor, p.valor) valororig,
        NVL(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'D') codcoborig,
       0 vltxboleto,
       c5.codfilial codfilialnf,
       NULL numcontacorrente,
       0 numcar,
       NULL numtransvenda,
       NULL numped,
       NULL importado,
       NULL dtexportacao,
       c.seriedocto numcaixafiscal,
       (CASE
            WHEN f.especie = 'G'
                THEN NULL
            ELSE
                REGEXP_REPLACE(p.nsutef,'[^0-9]', '') 
         END) nsutef,
       NULL numecf,
       (CASE
            WHEN NVL(p.qtdparcelatef,0) > 1
                THEN 'S'
            ELSE 'N'
         END) parcelamentotef,
       NULL prestef,
       p.codredetef codadmcartao,
       SUBSTR(p.modalidadetef,1,4) tipooperacaotef,
       p.codbandeiratef codbandeiratef,
       NULL dtbaixa,
       (CASE
            WHEN f.especie = 'G'
                THEN NULL
            ELSE
                SUBSTR(REGEXP_REPLACE(p.codautorizacaotef,'[^0-9]', ''), 1, 20)
         END) codautorizacaotef,
       NULL numccf,
       NULL linhadig,
       NULL vlmexiva,
       NULL assinatura,
       NULL numgnf,
       nf.numseriesat,
       p.codcredenciadoratef cnpjcredenccartao,
       NULL numcartaocrm,
       (CASE
            WHEN f.especie = 'G'
                THEN NULL
            ELSE
               REGEXP_REPLACE(p.nsuhosttef,'[^0-9]', '')
         END) nsuhost,
       0 valorcontravale,
       NULL compensacaobco,
       NULL cgccpfch,
       NULL dvagencia,
       NULL dvconta,
       NULL dvcheque,
       0 numfechamentomovcx,
       TO_CHAR(d.dtamovimento,'YYYY-MM-DD') dtmovimentocx,
       NULL codautoricredtef,
       NULL dtemissaoorig,
       NULL codigocontravale,
       NULL retornocrm1via,
       NULL retornocrm2via,
       p.retornoconsultacheque numprotocolochq,
       p.valor  valorcomtroco,
       0 idpagamento,
       NULL serialpos,
       NULL idrespfiscal,
       NULL bandeiracartao,
       NVL((SELECT CODCOBSEFAZ FROM PCCOB WHERE CODCOB = FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'99') codcobsefaz,
       NULL md5paf,
       3 tipodoc,
       NULL dtcxmot,
       NULL tipocorban,
       NULL autorizacaopagamentopontos,
       NULL autorizacaoacumulopontos,
       NULL somatxboleto,
       NULL Prest,
       0 codusur2,
       (CASE
            WHEN f.especie = 'G'
                THEN p.codautorizacaotef
            ELSE
                NULL
          END) processadortranspagdigital,
        (CASE
            WHEN f.especie = 'G'
                THEN p.idtransacao
            ELSE NULL
         END) numtranspagdigital,
        (CASE
            WHEN f.especie = 'G'
                THEN p.nsutef
            ELSE NULL
         END) nsupagdigital,
        fnc_int_c5_nome_pix(p.idcarteira) nomecarteiradigital,
        (CASE
            WHEN f.especie = 'G'
                THEN 'S'
            ELSE 'N'
         END) carteiradigital,
        NVL(r.valor, p.valor) valor,
    d.nroempresa,
    d.nrocheckout,
	fnc_int_c5_codplpag_venda(p.nroformapagto, c5.CODFILIAL) CODPLPAG
  FROM  monitorpdvmiddle.tb_doctopagto p,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        VW_INT_C5_OBTER_FILIAIS_C5 C5,
        vw_int_c5_cobranca_winthor v,
    VW_INT_C5_NFESAT NF ,
    TABLE(FNC_INT_C5_PRESTS_TEF(p.seqdocto, p.nrocheckout, p.nroempresa, FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))))) r
 WHERE  p.seqdocto = d.seqdocto
   AND p.nroformapagto not in (SELECT fp.nroformapagto
          FROM monitorpdvmiddle.tb_formapagto fp
         where fp.especie = 'D'
         and fp.formapagto LIKE '%DINHEIRO%')
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto(+)
   AND  d.nroempresa = c.nroempresa(+)
   AND  d.nrocheckout = c.nrocheckout(+)
   AND  p.nroformapagto = f.nroformapagto
   AND  C5.CODFILIALINTEGRACAO = d.NROEMPRESA
   AND  C5.CODFILIALINTEGRACAO = p.NROEMPRESA
   AND  d.seqdocto = nf.seqdocto(+)
   and  d.NROCHECKOUT = nf.NROCHECKOUT(+)
   and  d.nroempresa = nf.nroempresa(+)
   --and  c5.codfilialintegracao = nf.nroempresa
  -- AND  C5.CODFILIALINTEGRACAO = c.NROEMPRESA
   AND  f.codcob = v.codcob(+)
   AND  d.especie IN ('NF', 'CF', 'RP', 'VG', 'PL', 'GC', 'VC')
   AND p.Seqdocto = r.seqdocto(+)
   AND p.seqitem = r.seqitem(+)
   AND p.nroempresa = r.nroempresa(+)
   AND p.nrocheckout = r.nrocheckout(+)
   
   UNION ALL
   
   SELECT  d.seqdocto,
        NULL numgiftcard,
        'N' exportado,
        NULL presttef,
        d.sequsuario codfunccheckout,
        d.nrocheckout numcheckout,
        'NOTAFISCAL' numserieequip,
        case when nf.DOCEMISSAO in ('SF', 'MF') then nf.NUMCUPOMSAT else c.nronotafiscal end duplic,
        NVL(TO_NUMBER(regexp_replace(P.NROCARTAO, '[^0-9]', '')) ,NVL(c.seqpessoa,1)) codcli,
        TO_CHAR(p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
            ,'YYYY-MM-DD') dtvenc,
        NVL(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'D') codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        c5.codfilial codfilial,
        c5.codfilialintegracao, 
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
            ,'YYYY-MM-DD') dtvencorig,
        'N' operacao,
        f.boleto,
        NULL numbanco,
        NULL numagencia,
        NULL numcheque,
        NVL(fnc_int_c5_codsuperv(d.sequsuario),1) codsupervisor,
        NULL codbarra,
        p.valor valororig,
       NVL(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'D') codcoborig,
       0 vltxboleto,
       c5.codfilial codfilialnf,
       NULL numcontacorrente,
       0 numcar,
       NULL numtransvenda,
       NULL numped,
       NULL importado,
       NULL dtexportacao,
       c.seriedocto numcaixafiscal,
       NULL nsutef,
       NULL numecf,
       'N' parcelamentotef,
       NULL prestef,
       NULL codadmcartao,
       NULL tipooperacaotef,
       NULL codbandeiratef,
       NULL dtbaixa,
       NULL codautorizacaotef,
       NULL numccf,
       NULL linhadig,
       NULL vlmexiva,
       NULL assinatura,
       NULL numgnf,
       NULL numseriesat,
       NULL cnpjcredenccartao,
       NULL numcartaocrm,
       NULL nsuhost,
       0 valorcontravale,
       NULL compensacaobco,
       NULL cgccpfch,
       NULL dvagencia,
       NULL dvconta,
       NULL dvcheque,
       0 numfechamentomovcx,
       TO_CHAR(d.dtamovimento,'YYYY-MM-DD') dtmovimentocx,
       NULL codautoricredtef,
       NULL dtemissaoorig,
       NULL codigocontravale,
       NULL retornocrm1via,
       NULL retornocrm2via,
       NULL numprotocolochq,
       --p.valor  valorcomtroco,
       (p.valor + NVL((SELECT ABS(VALOR) 
                   FROM vw_int_c5_agrup_troco 
                   WHERE SEQDOCTO = P.SEQDOCTO 
                   AND NROEMPRESA = P.NROEMPRESA 
                   AND NROCHECKOUT = P.NROCHECKOUT 
                   AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_GERARTROCOCOBDIN', '99', 'N') <> 'S'),0)
       )  valorcomtroco,
       0 idpagamento,
       NULL serialpos,
       NULL idrespfiscal,
       NULL bandeiracartao,
       NVL((SELECT CODCOBSEFAZ FROM PCCOB WHERE CODCOB = FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'99') codcobsefaz,
       NULL md5paf,
       3 tipodoc,
       NULL dtcxmot,
       NULL tipocorban,
       NULL autorizacaopagamentopontos,
       NULL autorizacaoacumulopontos,
       NULL somatxboleto,
       NULL Prest,
       0 codusur2,
       NULL processadortranspagdigital,
       NULL numtranspagdigital,
     NULL nsupagdigital,
     NULL nomecarteiradigital,
     NULL carteiradigital,
     p.valor valor,
     d.NROEMPRESA,
     d.nrocheckout,
	 fnc_int_c5_codplpag_venda(p.nroformapagto, c5.CODFILIAL) CODPLPAG
  FROM  vw_int_c5_agrup_dinheiro p,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        vw_int_c5_cobranca_winthor v,
    VW_INT_C5_NFESAT NF ,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  p.seqdocto = d.seqdocto
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto(+)
   AND  d.nroempresa = c.nroempresa(+)
   AND  d.nrocheckout = c.nrocheckout(+)
   AND  p.nroformapagto = f.nroformapagto
   AND  C5.codfilialintegracao = d.NROEMPRESA
   AND  C5.codfilialintegracao = p.NROEMPRESA
   AND  d.seqdocto = nf.seqdocto(+)
   and  d.NROCHECKOUT = nf.NROCHECKOUT(+)
   and  d.nroempresa = nf.nroempresa(+)
   --and  c5.codfilialintegracao = nf.nroempresa
  -- AND  C5.codfilialintegracao = c.NROEMPRESA
   AND  f.codcob = v.codcob(+)
   AND  d.especie IN ('NF', 'CF', 'RP', 'VG', 'PL', 'GC', 'VC')
   
   UNION ALL
   
   SELECT  d.seqdocto,
        NULL numgiftcard,
        'N' exportado,
        NULL presttef,
        d.sequsuario codfunccheckout,
        d.nrocheckout numcheckout,
        'NOTAFISCAL' numserieequip,
        case when nf.DOCEMISSAO in ('SF', 'MF') then nf.NUMCUPOMSAT else c.nronotafiscal end duplic,
        NVL(TO_NUMBER(regexp_replace(P.NROCARTAO, '[^0-9]', '')) ,NVL(c.seqpessoa,1)) codcli,
        TO_CHAR(p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
            ,'YYYY-MM-DD') dtvenc,
        NVL(
        (CASE
            WHEN p.valor < 0
                THEN 'TR'
            ELSE
                NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))
          END),'D') codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        c5.codfilial codfilial,
        c5.codfilialintegracao, 
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
            ,'YYYY-MM-DD') dtvencorig,
        'N' operacao,
        f.boleto,
        NULL numbanco,
        NULL numagencia,
        NULL numcheque,
        NVL(fnc_int_c5_codsuperv(d.sequsuario),1) codsupervisor,
        NULL codbarra,
        p.valor valororig,
        NVL(
        (CASE
            WHEN p.valor < 0
                THEN 'TR'
            ELSE
                NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))
          END),'D') codcoborig,
       0 vltxboleto,
       c5.codfilial codfilialnf,
       NULL numcontacorrente,
       0 numcar,
       NULL numtransvenda,
       NULL numped,
       NULL importado,
       NULL dtexportacao,
       c.seriedocto numcaixafiscal,
       NULL nsutef,
       NULL numecf,
       'N' parcelamentotef,
       NULL prestef,
       NULL codadmcartao,
       NULL tipooperacaotef,
       NULL codbandeiratef,
       NULL dtbaixa,
       NULL codautorizacaotef,
       NULL numccf,
       NULL linhadig,
       NULL vlmexiva,
       NULL assinatura,
       NULL numgnf,
       NULL numseriesat,
       NULL cnpjcredenccartao,
       NULL numcartaocrm,
       NULL nsuhost,
       0 valorcontravale,
       NULL compensacaobco,
       NULL cgccpfch,
       NULL dvagencia,
       NULL dvconta,
       NULL dvcheque,
       0 numfechamentomovcx,
       TO_CHAR(d.dtamovimento,'YYYY-MM-DD') dtmovimentocx,
       NULL codautoricredtef,
       NULL dtemissaoorig,
       NULL codigocontravale,
       NULL retornocrm1via,
       NULL retornocrm2via,
       NULL numprotocolochq,
       p.valor  valorcomtroco,
       0 idpagamento,
       NULL serialpos,
       NULL idrespfiscal,
       NULL bandeiracartao,
       NVL((SELECT CODCOBSEFAZ FROM PCCOB WHERE CODCOB = FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'99') codcobsefaz,
       NULL md5paf,
       3 tipodoc,
       NULL dtcxmot,
       NULL tipocorban,
       NULL autorizacaopagamentopontos,
       NULL autorizacaoacumulopontos,
       NULL somatxboleto,
       NULL Prest,
       0 codusur2,
       NULL processadortranspagdigital,
       NULL numtranspagdigital,
     NULL nsupagdigital,
     NULL nomecarteiradigital,
     NULL carteiradigital,
     p.valor valor,
     d.NROEMPRESA,
     d.nrocheckout,
	 fnc_int_c5_codplpag_venda(p.nroformapagto, c5.CODFILIAL) CODPLPAG
  FROM  vw_int_c5_agrup_troco p,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        vw_int_c5_cobranca_winthor v,
    VW_INT_C5_NFESAT NF,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  p.seqdocto = d.seqdocto
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto(+)
   AND  d.nroempresa = c.nroempresa(+)
   AND  d.nrocheckout = c.nrocheckout(+)
   AND  p.nroformapagto = f.nroformapagto
   AND  C5.codfilialintegracao = d.NROEMPRESA
   AND  C5.codfilialintegracao = p.NROEMPRESA
   AND  d.seqdocto = nf.seqdocto(+)
   and  d.NROCHECKOUT = nf.NROCHECKOUT(+)
   and  d.nroempresa = nf.nroempresa(+)
   --and  c5.codfilialintegracao = nf.nroempresa
   --AND  C5.codfilialintegracao = c.NROEMPRESA
   AND  f.codcob = v.codcob(+)
   AND  FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_GERARTROCOCOBDIN', '99', 'N') = 'S'
   AND  d.especie IN ('NF', 'CF', 'RP', 'VG', 'PL', 'GC', 'VC')
   
   UNION ALL
   
   SELECT  d.seqdocto,
        NULL numgiftcard,
        'N' exportado,
        NULL presttef,
        d.sequsuario codfunccheckout,
        d.nrocheckout numcheckout,
        'NOTAFISCAL' numserieequip,
        case when nf.DOCEMISSAO in ('SF', 'MF') then nf.NUMCUPOMSAT else c.nronotafiscal end duplic,
        NVL(TO_NUMBER(regexp_replace(P.NROCARTAO, '[^0-9]', '')) ,NVL(c.seqpessoa,1)) codcli,
        TO_CHAR(p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
            ,'YYYY-MM-DD') dtvenc,
        'DOAC' codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        c5.codfilial codfilial,
        c5.codfilialintegracao, 
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(p.dtavencimento + FNC_INT_C5_PRAZOCC(NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)))
            ,'YYYY-MM-DD') dtvencorig,
        'N' operacao,
        f.boleto,
        NULL numbanco,
        NULL numagencia,
        NULL numcheque,
        NVL(fnc_int_c5_codsuperv(d.sequsuario),1) codsupervisor,
        NULL codbarra,
        p.valor valororig,
        'DOAC' codcoborig,
       0 vltxboleto,
       c5.codfilial codfilialnf,
       NULL numcontacorrente,
       0 numcar,
       NULL numtransvenda,
       NULL numped,
       NULL importado,
       NULL dtexportacao,
       c.seriedocto numcaixafiscal,
       NULL nsutef,
       NULL numecf,
       'N' parcelamentotef,
       NULL prestef,
       NULL codadmcartao,
       NULL tipooperacaotef,
       NULL codbandeiratef,
       NULL dtbaixa,
       NULL codautorizacaotef,
       NULL numccf,
       NULL linhadig,
       NULL vlmexiva,
       NULL assinatura,
       NULL numgnf,
       NULL numseriesat,
       NULL cnpjcredenccartao,
       NULL numcartaocrm,
       NULL nsuhost,
       0 valorcontravale,
       NULL compensacaobco,
       NULL cgccpfch,
       NULL dvagencia,
       NULL dvconta,
       NULL dvcheque,
       0 numfechamentomovcx,
       TO_CHAR(d.dtamovimento,'YYYY-MM-DD') dtmovimentocx,
       NULL codautoricredtef,
       NULL dtemissaoorig,
       NULL codigocontravale,
       NULL retornocrm1via,
       NULL retornocrm2via,
       NULL numprotocolochq,
       p.valor  valorcomtroco,
       0 idpagamento,
       NULL serialpos,
       NULL idrespfiscal,
       NULL bandeiracartao,
       NVL((SELECT CODCOBSEFAZ FROM PCCOB WHERE CODCOB = FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem)),'99') codcobsefaz,
       NULL md5paf,
       3 tipodoc,
       NULL dtcxmot,
       NULL tipocorban,
       NULL autorizacaopagamentopontos,
       NULL autorizacaoacumulopontos,
       NULL somatxboleto,
       NULL Prest,
       0 codusur2,
       NULL processadortranspagdigital,
       NULL numtranspagdigital,
     NULL nsupagdigital,
     NULL nomecarteiradigital,
     NULL carteiradigital,
     (p.valor) valor,
     d.NROEMPRESA,
     d.nrocheckout,
	 fnc_int_c5_codplpag_venda(p.nroformapagto, c5.CODFILIAL) CODPLPAG
  FROM  MONITORPDVMIDDLE.TB_DOCTOPAGTO p,
        MONITORPDVMIDDLE.TB_DOCTOTROCOSOLIDARIO TS,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        vw_int_c5_cobranca_winthor v,
    VW_INT_C5_NFESAT NF,
    VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  p.seqdocto = TS.seqdocto
   AND  TS.SEQDOCTOORIGEM = d.seqdocto
   AND  TS.NROEMPRESA = d.NROEMPRESA
   AND  TS.NROCHECKOUT = d.nrocheckout
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto(+)
   AND  d.nroempresa = c.nroempresa(+)
   AND  d.nrocheckout = c.nrocheckout(+)
   AND  p.nroformapagto = f.nroformapagto
   AND  C5.codfilialintegracao = d.NROEMPRESA
   AND  C5.codfilialintegracao = p.NROEMPRESA
   AND  d.seqdocto = nf.seqdocto(+)
   and  d.NROCHECKOUT = nf.NROCHECKOUT(+)
   and  d.nroempresa = nf.nroempresa(+)
   --and  c5.codfilialintegracao = nf.nroempresa
   AND  f.codcob = v.codcob(+)
   AND  d.especie IN ('NF', 'CF', 'RP', 'VG', 'PL', 'GC', 'VC')
)
