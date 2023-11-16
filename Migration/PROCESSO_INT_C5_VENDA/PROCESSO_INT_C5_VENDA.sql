CREATE OR REPLACE VIEW VW_INT_C5_TRIBUTOS AS 
 ( SELECT t.codst,
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
  (SELECT 'pix' nomecarteira, 3001 idcarteira FROM DUAL
     UNION
     SELECT 'mercadopago' nomecarteira, 3002 idcarteira FROM DUAL
     UNION
     SELECT 'picpay' nomecarteira, 3003 idcarteira FROM DUAL
     UNION
     SELECT 'ame' nomecarteira, 3004 idcarteira FROM DUAL
     UNION
     SELECT 'shipaypagador' nomecarteira, 30099 idcarteira FROM DUAL
   )

\

CREATE OR REPLACE VIEW VW_INT_C5_PCVENDACONSUMECF AS 
  (SELECT d.seqdocto,
       TO_CHAR(d.dtamovimento, 'YYYY-MM-DD') DATA,
       0 numpedecf,
       d.sequsuario codfunccheckout,
       d.nrocheckout numcaixa,
       d.nroempresa codfilial,
       'NOTAFISCAL' numserieequip,
       c.nronotafiscal numcupom,
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
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) TELENT,
       NVL(F.MUNICENT,
           (SELECT CLI.MUNICENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) MUNICENT,
       NVL(F.ESTENT,
           (SELECT CLI.ESTENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) ESTENT,
       NVL(F.CEPENT,
           (SELECT CLI.CEPENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) CEPENT,
       NVL(F.IEENT,
           (SELECT CLI.IEENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) IEENT,
       NVL(F.CODCIDADE,
           (SELECT CLI.CODCIDADE
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) CODCIDADE,
       NVL(F.NUMEROENT,
           (SELECT CLI.NUMEROENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) NUMEROENT,
       NVL(F.BAIRROENT,
           (SELECT CLI.BAIRROENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) BAIRROENT,
       NVL(F.ENDERENT,
           (SELECT CLI.ENDERENT
              FROM PCCLIENT CLI
             WHERE CLI.CODCLI =
                   (SELECT PCFILIAL.CODCLI
                      FROM PCFILIAL
                     WHERE PCFILIAL.CODIGO = TO_CHAR(d.nroempresa)))) ENDERENT
  FROM monitorpdvmiddle.tb_docto      d,
       monitorpdvmiddle.tb_doctocupom c,
       monitorpdvmiddle.tb_doctonfe   e,
       PCCLIENT                       F
 WHERE d.nroempresa = c.nroempresa
   AND d.nrocheckout = c.nrocheckout
   AND d.seqdocto = c.seqdocto
   AND d.nroempresa = e.nroempresa
   AND d.nrocheckout = e.nrocheckout
   AND d.seqdocto = e.seqdocto
   AND d.especie = 'NF'
   AND c.seqpessoa IS NULL
   AND c.cnpjcpf IS NOT NULL
   AND NVL(C.SEQPESSOA, 1) = F.CODCLI(+))

\

CREATE OR REPLACE VIEW VW_INT_C5_PCPRODUT  AS 
  (SELECT  e.codprod,
        e.codauxiliar,
        c.seqproduto,
        --e.codauxiliar||e.codfilial seqproduto, --alterar para o DEPARA (PCDEPARAEMBALAGENSC5)
        e.codfilial,
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
        --(SELECT CODCEST FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST WHERE PCCESTPRODUTO.CODPROD = p.CODPROD) codcest,
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
        PCDEPARAEMBALAGENSC5 c
 WHERE  p.codprod = e.codprod
   AND  e.codprod = f.codprod
   AND  e.codfilial = f.codfilial
   AND  c.codauxiliar = e.codauxiliar
   AND  LENGTH (p.nbm) >= 2
   AND  e.codprod >= 0
   AND  f.codprod >= 0
   AND  NVL(e.enviafrentecaixa, 'S') = 'S' )
   
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
        NVL(o.codoperadoracartao,'0') codoperadoracarto,
        NVL(o.codbandeira,0) codbandeira,
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
            ELSE
                '0000'
         END) modalidadetef,
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
        NVL(o.carteiradigital,'N') carteiradigital
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
( SELECT  a.nroempresa codfilial,
        a.sequsuario codfunccx,
        TO_CHAR(a.dtamovimento,'YYYY-MM-DD') data,
        NULL dtexportacao,
        'N' exportado,
        a.nrocheckout numcaixa,
        --p_numpedecf numpedecf,
        'NOTAFISCAL' numserieequip,
        x.xml xmlnfce,
        x.xmlcanc xmlnfcecancelamento,
        a.seqdocto
  FROM  monitorpdvmiddle.tb_docto a,
        monitorpdvmiddle.tb_doctonfexml x
 WHERE  a.nroempresa = x.nroempresa
   AND  a.nrocheckout = x.nrocheckout
   AND  a.seqdocto = x.seqdocto
)

\

CREATE OR REPLACE VIEW VW_INT_C5_TRIB_PIS AS 
  (
SELECT  e.codauxiliar,
        e.codfilial,
        r.codprod,
        r.numregiao,
        p.codtribpiscofins,
        r.codst,
        p.sittribut,
        NVL(p.percpis,0) percpis,
        NVL(p.perccofins,0) perccofins,
        p.excluiricmsbasepiscofins
  FROM  vw_int_c5_pcprodut E,
        pctabpr r,
        pctribpiscofins p
 WHERE  e.codprod = r.codprod
   AND  r.codtribpiscofins = p.codtribpiscofins
   AND  p.codtribpiscofins > 0
   AND  r.numregiao = ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',e.codfilial,1)
)

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_ESPECIE_COB_VENDAS (pSeqDocto    IN NUMBER,
                                                          pNumeroCaixa IN NUMBER,
                                                          pCodigoFilial IN NUMBER,
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
            VW_INT_C5_FINALIZ_VENDA a
     WHERE  p.nroformapagto = f.nroformapagto
       AND  f.nroformapagto = a.NROFORMAPAGTO
       AND  p.seqitem = pSeqItem
       AND  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pCodigoFilial
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
         AND  p.nroempresa = pCodigoFilial
		 AND  P.CODREDETEF = A.CODOPERADORACARTO
         AND  p.codbandeiratef = a.codbandeira(+)
         AND  p.nrocheckout = pNumeroCaixa;
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
         AND  p.nroempresa = pCodigoFilial
		 AND  P.CODREDETEF = A.CODOPERADORACARTO
         AND  p.codbandeiratef = a.codbandeira(+)
         AND  p.nrocheckout = pNumeroCaixa
         AND  ROWNUM = 1;
      
      WHEN OTHERS THEN
         vCodCob := 'D';
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
         AND  p.nroempresa = pCodigoFilial
         AND  p.idcarteira = a.idcarteira(+)
         AND  p.nrocheckout = pNumeroCaixa
         AND  ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        vCodCob := 'D';
    end;
  
/*  elsif vEspecie in ('X', 'N', 'I') THEN --Não implementado no piloto. deverá ser definida regra posteriormente
     vCodCob := 'D';*/
     
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
       AND  p.nroempresa = pCodigoFilial
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
                                      pNumeroCaixa NUMBER,
                                      pCodigoFilial VARCHAR2)
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
   AND  a.seqdocto = pSeqDocto
   AND  a.nroempresa = pCodigoFilial
   AND  a.nrocheckout = pNumeroCaixa
   AND  ROWNUM = 1;
 RETURN(vFinalizadora);
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
            monitorpdvmiddle.tb_docto a
     WHERE  p.nroformapagto = a.nroformapagto
       AND  p.nroempresa = a.codfilial
       AND  a.nroformapagto = pNroFormaPagto
       AND  a.codfilial = pCodFilial
       AND  ROWNUM = 1;
    RETURN(vCodPlPag);
END;

\

CREATE OR REPLACE FUNCTION FNC_INT_C5_VLTOTAL (pSeqDocto number,
                                                   pNumeroCaixa NUMBER,
                                                   pCodigoFilial VARCHAR2)
    RETURN NUMBER
IS
    vTotal NUMBER;

BEGIN
    SELECT  SUM(p.valor)
      INTO  vTotal
      FROM  monitorpdvmiddle.tb_doctopagto p
     WHERE  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pCodigoFilial
       AND  p.nrocheckout = pNumeroCaixa;
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
        monitorpdvmiddle.tb_docto a
 WHERE  g.seqdocto = a.seqdocto
   AND  g.nroempresa = a.nroempresa
   AND  g.nrocheckout = a.nrocheckout
   AND  a.especie = 'NF'
   AND  p.codplpag = NVL(fnc_int_c5_codplpag_venda(g.nroformapagto,g.nroempresa),1)
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
 WHERE  i.nroempresa = a.codfilial
   AND  i.codacesso = a.codauxiliar
   AND  i.seqdocto = pSeqDocto
   AND  i.nroempresa = pNroEmpresa
   AND  i.nrocheckout = pNroCheckout;
 RETURN(vTotalVol);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_tipovenda_pag_venda(pNroFormaPagto NUMBER,
                                                          pCodFilial     VARCHAR2,
                                                          pNumcheckout   NUMBER)
    RETURN CHAR
IS
    vTipoVenda CHAR(2);
BEGIN
    SELECT  a.tipovenda
      INTO  vTipoVenda
      FROM  VW_INT_C5_PLANOP_VENDA a,
            --VW_INT_C5_FINALIZADORA a,
            monitorpdvmiddle.tb_doctopagto p
            --monitorpdvmiddle.tb_docto d
     WHERE  p.nroformapagto = a.nroformapagto
       AND  p.nroempresa = a.nroempresa
        AND p.nrocheckout = a.nrocheckout 
       AND  a.nroformapagto = pNroFormaPagto
       AND  a.nroempresa = pCodFilial
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
                                  pCodigoFilial IN NUMBER)
    RETURN NUMBER
IS
    vTotalCustoFin NUMBER;
BEGIN
    SELECT  SUM(s.vlcustofin)
      INTO  vTotalCustoFin
      FROM  vw_int_c5_custos s,
            monitorpdvmiddle.tb_doctoitem i
     WHERE  i.nroempresa = s.codfilial
       AND  i.codacesso = s.codauxiliar
       AND  i.seqdocto = pSeqDocto
       AND  I.nroempresa = pCodigoFilial
       AND  i.nrocheckout = pNumeroCaixa;
    RETURN(vTotalCustoFin);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_numitens (pSeqDocto IN NUMBER,
                              pNumeroCaixa IN NUMBER,
                              pCodigoFilial IN NUMBER)
    RETURN NUMBER
IS
    vNumItens NUMBER;
BEGIN
    SELECT  COUNT(i.seqdocto)
      INTO  vNumItens
      FROM  monitorpdvmiddle.tb_doctoitem i
     WHERE  i.seqdocto = pSeqDocto
       AND  i.nrocheckout = pNumeroCaixa
       AND  i.nroempresa = pCodigoFilial;
    RETURN(vNumItens);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_perdesc_acresc_r(pCodFilial   NUMBER,
                                                       pNumCaixa    NUMBER,
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
                  --/ fnc_int_c5_numitens(d.seqdocto, d.nrocheckout, d.nroempresa)
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
   AND  i.nroempresa = pCodFilial
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqdocto = pSeqDocto
   AND  ROWNUM = 1;
  RETURN(vPerAcrescimoRodape);
  EXCEPTION
     WHEN OTHERS
          THEN
     RETURN 0;
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_perdesc_desc_r(pCodFilial   NUMBER,
                                                     pNumCaixa    NUMBER,
                                                     pSeqDocto    NUMBER)
  RETURN NUMBER
IS
  vPerDescRodape NUMBER;
BEGIN

 SELECT  (CASE
            WHEN i.vlrdesconto > 0
                 THEN a.VALOR
                  --/ fnc_int_c5_numitens(d.seqdocto, d.nrocheckout, d.nroempresa)
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
   AND  i.nroempresa = pCodFilial
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqdocto = pSeqDocto
   AND  ROWNUM = 1;
  RETURN(vPerDescRodape);
  EXCEPTION
     WHEN OTHERS
          THEN
     RETURN 0;
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_total_acresc_r(pCodFilial   NUMBER,
                                                     pNumCaixa    NUMBER,
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
                  --/ fnc_int_c5_numitens(d.seqdocto, d.nrocheckout, d.nroempresa)
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
   AND  i.nroempresa = pCodFilial
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqdocto = pSeqDocto;
  RETURN(vTotalAcrescimoRodape);
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
       AND  z.seqdocto = pSeqDocto;
   RETURN(vTotal);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_total_ptabela(pCodFilial   NUMBER,
                                                     pNumCaixa    NUMBER,
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
   AND  i.nroempresa = pCodFilial
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqdocto = pSeqDocto;
  RETURN(vTotalPTabela);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_vlacrescimofcp(pCodFilial  NUMBER,
                                                     pNumCaixa   NUMBER,
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
   AND  i.nroempresa = pCodFilial
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqdocto = pSeqdocto
   AND  i.seqitem = pSeqItem;
 RETURN(vVlAcrescimoFCP);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_vldescitem(pCodFilial NUMBER,
                                                 pNumCaixa  NUMBER,
                                                 pSeqdocto  NUMBER,
                                                 pNumSeq    NUMBER)
    RETURN NUMBER
IS
    vVlDesc NUMBER;
BEGIN
 vVlDesc := 0;
SELECT  i.vlrdesconto
 INTO  vVlDesc
  FROM  monitorpdvmiddle.tb_doctoitem i,
        monitorpdvmiddle.tb_doctoacrescdescto a
 WHERE  i.nroempresa = a.nroempresa
   AND  i.nrocheckout = a.nrocheckout
   AND  i.seqdocto = a.seqdocto
   AND  i.seqdocto = pSeqdocto
   AND  i.nroempresa = pCodFilial
   AND  i.nrocheckout = pNumCaixa
   AND  i.seqitem = pNumSeq
   AND  a.seqtipoacrescdescto = 2
   AND  i.vlrdesconto = (a.valor) * -1;
 RETURN(vVlDesc);
END;

\

CREATE OR REPLACE FUNCTION fnc_int_c5_vldesoneracao(pCodFilial  NUMBER,
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
   AND  i.nroempresa = v.codfilial
   AND  i.seqproduto = v.seqproduto
   AND  i.codacesso = v.codauxiliar
   AND  t.seqtipotributacao = 15
   AND  a.numregiao = ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',i.nroempresa,1)
   AND  i.status = 'V'
   AND  i.nroempresa = pCodFilial
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

CREATE OR REPLACE VIEW vw_int_c5_pcpedcecf AS
(SELECT  a.seqdocto,
        e.chavenf chavenfe,
        e.protocoloenvio,
        c.seriedocto serie,
        a.especie,
        a.ROWID rowid_tb_docto,
        0 numpedecf,
        'X' serieecf,
        'N' exportado,
        e.ambiente ambientenfce,
        NVL(c.seqpessoa,1) codcli,
        'NOTAFISCAL' numserieequip,
        a.sequsuario codemitente,
        a.nroempresa codfilial,
        a.sequsuario codfunccx,
        NVL(FNC_INT_C5_ESPECIE_COB_VENDAS(a.seqdocto, a.nrocheckout, a.nroempresa, 1),'D') codcob,
        NVL(
        (SELECT fnc_int_c5_codplpag_venda(g.nroformapagto,g.nroempresa)
           FROM monitorpdvmiddle.tb_doctopagto g
          WHERE g.nroempresa = a.nroempresa
            AND g.nrocheckout = a.nrocheckout
            AND g.seqdocto = a.seqdocto
            AND ROWNUM = 1),1) codplpag,

        (SELECT fnc_int_c5_tipovenda_pag_venda(g.nroformapagto,g.nroempresa,g.nrocheckout)
           FROM monitorpdvmiddle.tb_doctopagto g
          WHERE g.nroempresa = a.nroempresa
            AND g.nrocheckout = a.nrocheckout
            AND g.seqdocto = a.seqdocto
            AND ROWNUM = 1) tipovenda,
        NVL(fnc_int_c5_praca_cli(c.seqpessoa),1) codpraca,
        NVL(fnc_int_c5_codsuperv(a.sequsuario),1) codsupervisor,
        NVL(fnc_int_c5_codusur(a.sequsuario),1) codusur,
        'N' contingenciaservidor,
        fnc_int_c5_tot_custofin(a.seqdocto, a.nrocheckout, a.nroempresa) custofinest,
        TO_CHAR(a.DTAHOREMISSAO,'YYYY-MM-DD') DATA,
        'CE' docemissao,
        TO_CHAR(a.DTAHOREMISSAO,'YYYY-MM-DD') dtentrega,
        TO_CHAR(e.dtahorrecebimento,'YYYY-MM-DD') dthoraautorizacaosefaz,
        TO_CHAR(a.DTAHOREMISSAO,'YYYY-MM-DD') dtmovimentocx,
        NULL cartaocrm,
        NULL cgcfrete,
        NULL dtahoraentradacontigencia,
        NULL chavesat,
        NULL cnpjintermediador,
        NULL dtcancel,
        NULL codfornecfrete,
        NULL codprofissional,
        NULL codretornosat,
        NULL codsefazsat,
        NULL codstatussat,
        NULL datahoraemissaosat,
        NULL descintermediador,
        NULL crmconfirmado,
        NULL dtexportacao,
        NULL dtfat,
        NULL existesefaz,
        NULL emaildest,
        NULL horafat,
        NULL idparceiro,
        NULL iefrete,
        NULL importado,
        NULL indicadoracrescimo,
        NULL indicadordesconto,
        NULL jsonvendacrm,
        NULL logerro,
        NULL notadupliquesvc,
        NULL naturezanfce,
        0 numcar,
        NULL numecf,
        NULL md5listaarq,
        NULL md5paf,
        NULL motoristaveiculo,
        NULL numexecucao,
        NULL numlista,
        NULL numorca,
        NULL numped,
        NULL numpedcanc,
        NULL numpedrca,
        NULL numserieplacamae,
        NULL numseriesat,
        NULL numsessaosat,
        NULL numtransvenda,
        NULL obsnf1,
        NULL obsnf2,
        NULL obsnf3,
        NULL obsnfce,
        NULL percicm,
        NULL placaveiculo,
        1 condvenda,
        'N' entrega,
        'S' faturanotaservfat,
        'N' gerardadosnfpaulista,
        TO_CHAR(a.DTAHOREMISSAO,'HH24') hora,
        TO_CHAR(a.DTAHOREMISSAO,'HH24:mm:ss') horacupom,
        TO_CHAR(a.DTAHOREMISSAO,'mm') minuto,
        TO_CHAR(a.DTAHOREMISSAO,'mm') minutocupom,
        (CASE
            WHEN c.seqpessoa < 4
                 AND
                 c.cnpjcpf IS NOT NULL
                THEN 'S'
            ELSE
                'N'
         END) identificarclientenfce,
        NULL posicaoretorno,
        1 idtipopresenca,
        NULL justificativacontingencia,
        c.seriedocto numcaixafiscal,
        0 numfechamentomovcx,
        c.nronotafiscal numcupom,
        fnc_int_c5_numitens(a.seqdocto, a.nrocheckout, a.nroempresa) numitens,
        ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',a.nroempresa,1) numregiao,
        1 numviasmapasep,
        NULL qrcodesat,
        NULL situacaosat,
        0 taxaentrega,
        1 tipoemissao,
        0 totvolume,
        NULL transportadora,
        NULL uffrete,
        NULL ufveiculo,
        NULL uidregistro,
        NULL usadebcredrca,
        NULL validadoestacionamento,
        NULL vendaassistida,
        NULL vendanfseried,
        NULL versaofaturamento,
        NULL versaominfaturamento,
        NULL tipodoc,
        0 numvolume,
        'N' operacao,
        100 percvenda,
        (CASE
            WHEN fnc_int_c5_perdesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0
                 THEN (fnc_int_c5_perdesc_acresc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) * -1)
            WHEN fnc_int_c5_perdesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) <> 0
                 THEN (fnc_int_c5_perdesc_desc_r(a.NROEMPRESA,a.NROCHECKOUT,a.seqdocto) * -1)
            ELSE
              0
          END) perdesc,
        'L' posicao,
        DBMS_LOB.SUBSTR(x.qrcode,4000,1) qrcodenfce,
        100 situacaonfce,
        ferramentas.F_BUSCARPARAMETRO_ALFA('CON_TIPOMOVRCA','99','FF') tipomovrca,
        ferramentas.F_BUSCARPARAMETRO_ALFA('CON_USACREDRCA','99','F') usacredrca,
        'C5-' || a.versaoaplicacao versaorotina,
        (SELECT i.numdias
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazomedio,
        (SELECT i.prazo1
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo1,
        (SELECT i.prazo2
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo2,
        (SELECT i.prazo3
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo3,
        (SELECT i.prazo4
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo4,
        (SELECT i.prazo5
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo5,
        (SELECT i.prazo6
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo6,
        (SELECT i.prazo7
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo7,
        (SELECT i.prazo8
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo8,
        (SELECT i.prazo9
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo9,
        (SELECT i.prazo10
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo10,
        (SELECT i.prazo11
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo11,
        (SELECT i.prazo12
           FROM VW_INT_C5_PLANOP_VENDA i
          WHERE i.seqdocto = a.seqdocto
            AND ROWNUM = 1) prazo12,
        0 vlcustofin,
        0 vlcustoreal,
        0 vlcustocont,
        0 vlcustorep,
        fnc_int_c5_total_acresc_r(a.nroempresa,a.NROCHECKOUT,a.seqdocto) vlacresrodape,
        fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA) vltotal,
        fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA) vlatend,
        fnc_int_c5_total_ptabela(a.nroempresa,a.NROCHECKOUT,a.seqdocto) vltabela,
        ROUND(fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA),6) Vlsubtotal,
        fnc_int_c5_cab_total(a.SEQDOCTO,a.NROCHECKOUT,a.NROEMPRESA) Vltotalcomtroco,
        0 Vltributos,
        0 Vltributosestadual,
        0 Vltributosmunicipal,
        0 Vlfrete,
        0 Vljurosparcelamento,
        0 Vlmexiva,
        0 Vlcofins,
        0 Vlpis,
        0 Vloutrasdesp,
        0 vlacrescrodape,
        x.xml xmlnfce,
        0 totpeso,
        e.protocoloenvio protocolonfce,
        a.nrocheckout numcheckout,
        null minutofat,
        a.nrocheckout numcaixa,
        null horacontingencia,
        null fretedespacho,
        null fichasimportadas,
        e.chavenf chavenfce,
		c.status
  FROM  monitorpdvmiddle.tb_docto a,
        monitorpdvmiddle.tb_doctocupom  c,
        monitorpdvmiddle.tb_doctonfe    e,
        monitorpdvmiddle.tb_doctonfexml x
 WHERE  c.nroempresa = a.nroempresa
   AND  c.nrocheckout = a.nrocheckout
   AND  c.seqdocto = a.seqdocto
   AND  a.especie IN ('NF', 'CF')
   AND  c.nroempresa = e.nroempresa
   AND  c.nrocheckout = e.nrocheckout
   AND  c.seqdocto = e.seqdocto
   AND  e.nroempresa = x.nroempresa
   AND  e.nrocheckout = x.nrocheckout
   AND  e.seqdocto = x.seqdocto
   AND  c.status IN ('V', 'C')
   AND  a.replicacao = 'P'
   AND  e.protocoloenvio IS NOT NULL
   AND  NVL(fnc_int_c5_vltotal(a.seqdocto, a.nrocheckout, a.nroempresa), 0) > 0
   AND  fnc_int_c5_finalizadora_cab(a.seqdocto,a.nrocheckout,a.nroempresa) > 0
)


\

CREATE OR REPLACE VIEW vw_int_c5_pcpediecf 
AS
(SELECT  i.SEQDOCTO,
        'N' exportado,
        0 numpedecf,
        i.nrocheckout numcheckout,
        0 vlitemtributos,
        0 aliqfcp, --a.aliqfcp
        a.aliqicms1,
        a.aliqicms2,
        0 aliqicmsfecp,
        0 aliqinternadest,
        0 aliqinterorigpart,
        0 aliqreducaocofins,
        0 aliqreducaopis,
        p.codanp anp,
        0 basebcr,
        NVL((select 
              (CASE 
                 WHEN doctribitem.percbasecalculo < 100 THEN
                      nvl(((i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0) ) * (doctribitem.percbasecalculo/100)) / NVL(i.QTDEMBALAGEM, 1) , 0)
                 ELSE nvl( (i.VLRUNITARIO - NVL((i.vlrdesconto/ NVL(i.quantidade,1)),0) + NVL((i.vlracrescimo/ NVL(i.quantidade,1)),0)) / NVL(i.QTDEMBALAGEM, 1),0)  
               END) vlrbase             
                            
             from monitorpdvmiddle.tb_doctotributacaoitem doctribitem
             where doctribitem.nroempresa = i.nroempresa
             and doctribitem.nrocheckout = i.nrocheckout
             and doctribitem.seqdocto = i.seqdocto
             and doctribitem.seqitem = i.seqitem
             and doctribitem.seqtipotributacao = 1
             ), 0) baseicms,
        0 baseicmsbcr,
        0 baseicst,
        NULL baseipiecf,
        0 basemexiva,
        0 bciss,
        NULL brinde,
        v.cnpjfabricante,
        NULL codagregacao,
        i.codacesso codauxiliar,
        NULL codbarrabalanca,
        a.codbeneficiofiscal,
        0 codcampanha,
        v.codcest,
        NVL(c.seqpessoa,1) codcli,
        0 codcontrolevasilhame,
        d.nroempresa codfilial,
        NULL codfilialretira,
        --NULL codecf,
        (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) codecf,
        i.cfop codfiscal,
        v.codfornec,
        d.sequsuario codfunccx,
        a.codicmtab,
        NULL codigobrinde,
        a.codmotivodesoneracao codmotivoicmsdesonerado,
        v.codprod,
        h.codtribpiscofins,
        NVL(fnc_int_c5_codusur(d.sequsuario),1) codusur,
        0 codvasilhameecf,
        0 custofinest,
        0 custoultent,
        TO_CHAR(d.dtamovimento,'YYYY-MM-DD') data,
        NULL dtexportacao,
        p.descanp descanp,
        p.desccompleta descricaopaf,
        'N' emoferta,
        'N' enviaraliqreducaopiscofins,
        h.excluiricmsbasepiscofins,
        v.fabricante,
        NULL idcancel,
        NULL importado,
        v.indescalarelevante indescalarelevante,
        0 iva,
        NULL logerro,
        NULL md5paf,
        i.nrocheckout numcaixa,
        c.seriedocto numcaixafiscal,
        i.seqitem numseq,
        0 numseqorig,
        NULL numcar,
        NULL numlista,
        0 numccf,
        0 numcoo,
        NULL Numlote,
        'NOTAFISCAL' numserieequip,
        NULL numped,
        NULL numserie,
        NULL numseriesat,
        NULL origemitem,
        v.origmerctrib,
        0 pauta,
        0 pbaserca,
        0 peracrescimocusto,
        0 peracrescimofuncep,
        (SELECT percbasered
           FROM pctribut
          WHERE codst = a.codst) percbasered,
        0 percbaseredst,
        0 percdesccofins,
        0 percdescpis,
        0 perdifereimentoicms,
        0 percmexiva,
        0 perciss,
        (select percaliquota
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 1) percicm,
        0 percicmsefet,
        v.comissao percom,
        0 percredbaseefet,
        0 perctributosestadual,
        0 perctributosmunicipal,
        /*(CASE
             WHEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) < 0
                  THEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) * -1
             ELSE
               ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6)
          END) perdesc,*/  
		((((i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) - ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) + (NVL(i.vlracrescimo,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1))) / (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)))*100)perdesc,
        0 perdesccusto,
        0 perdescisentoicms,
        'N' piscofinsdeduzido,
        h.perccofins,
        NVL(p.percglp,0) pglp,
        NVL(p.percgni,0) pgni,
        NVL(p.percgnn,0) pgnn,
        --i.vlrunitario poriginal,
        (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) poriginal,
        NULL possuicomplemento,
        NULL posicaoretorno,
        0 pvendavasilhame,
        'L' posicao,
        --i.vlrunitario ptabela,
        (i.VLRUNITARIO / NVL(i.QTDEMBALAGEM, 1)) ptabela,
        ((i.vlrunitario - (NVL(i.vlrdesconto,0)/NVL(i.quantidade,1)) + (NVL(i.vlracrescimo,0)/NVL(i.quantidade,1)) )/NVL(i.QTDEMBALAGEM, 1)) pvenda,
       /*(CASE
            WHEN ROUND(100 * (1 - (i.vlrtotal / i.vlrunitario)),6) < 0
                 THEN (i.vlrunitario + (NVL(i.vlracrescimo,0)/ i.quantidade))
            ELSE
              (i.vlrunitario - (NVL(i.vlrdesconto,0)/ i.quantidade))
         END) pvenda,*/
        --i.vlrunitario - (NVL(i.vlrdesconto,0)/ i.quantidade) pvenda,
        (i.quantidade * NVL(i.QTDEMBALAGEM,1)) qt,
        NULL qtfalta,
        NULL qtminatacvenda,
        0 qtsaidavasilhame,
        0 qtlitragem,
        v.qtunit qtunitemb,
        2099 rotinalanc,
        (CASE
            WHEN LENGTH(a.sittribut) < 2
                THEN '0'||a.sittribut
            ELSE
                TO_CHAR(a.sittribut)
          END) sittribut,
        0 st,
        0 stbcr,
        v.tipomerc tipomerc,
        'N' truncaritem,
        NULL tipoentrega,
        NULL totalizador,
        0 txvenda,
        NULL tipodescatacvenda,
        'N' usapiscofinslit,
        NULL usaunidademaster,
        'N' utilizoumotorcalculo,
        NULL vendapbm,
        NULL versaoservicopartilha,
        (SELECT valorultent
           FROM vw_int_c5_custos
          WHERE codfilial = i.nroempresa
            AND codauxiliar = i.codacesso) valorultent,
        --0 vlacrescimofuncep,
        NVL(fnc_int_c5_vlacrescimofcp(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM),0) vlacrescimofuncep,
        (CASE
            WHEN i.seqdocto IN (SELECT seqdocto
                                  FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                                 WHERE z.NROEMPRESA = i.NROEMPRESA
                                   AND z.NROCHECKOUT = i.NROCHECKOUT
                                   AND z.SEQTIPOACRESCDESCTO = 7)
                THEN (SELECT z.VALOR
                        FROM monitorpdvmiddle.TB_DOCTOACRESCDESCTO z
                       WHERE z.NROEMPRESA = i.NROEMPRESA
                         AND z.NROCHECKOUT = i.NROCHECKOUT
                         AND z.SEQTIPOACRESCDESCTO = 7
                         AND z.seqdocto = i.seqdocto)/fnc_int_c5_numitens(d.seqdocto, d.nrocheckout, d.nroempresa)
           ELSE
              0
         END) vlacrescrodape,
        NVL(
        (SELECT vlbaseefet
           FROM vw_int_c5_custos
          WHERE codfilial = i.nroempresa
            AND codauxiliar = i.codacesso),0) vlbaseefet,
        (CASE
            WHEN a.SITTRIBUT IN ('00','20','90')
                 AND
                 a.PERCALIQFCPICMS > 0
                then ((select ROUND(vlrbase,2)
                         from monitorpdvmiddle.tb_doctotributacaoitem
                        where nroempresa = i.nroempresa
                          and nrocheckout = i.nrocheckout
                          and seqdocto = i.seqdocto
                          and seqitem = i.seqitem
                          and seqtipotributacao = 1))
                --THEN ROUND(ti.VLRBASE,2)
            ELSE
              0
          END) vlbasefcpicms,
        0 vlbasefcpst,
        0 vlbasepiscofins,
        0 vlbcfcpstret,
        ((NVL(h.perccofins,0)/100) * i.vlrtotal) vlcofins,
        0 vlcredcofins,
        0 vlcredpis,
        0 vlcustocont,
        0 vlcustofin,
        0 vlcustoreal,
        0 vlcustorep,
        0 vldescfin,
        0 vldescicmisencao,
        fnc_int_c5_vldescitem(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM) vldescitem,
        0 vldescreducaocofins,
        0 vldescreducaopis,
        0 vldescrodape,
        0 vldescsociotorcedor,
        0 vlfrete,
       --fnc_int_c5_vldesoneracao(i.NROEMPRESA,i.NROCHECKOUT,i.SEQDOCTO,i.SEQITEM) vlicmsdesoneracao,
       (select vlrtributo 
           from monitorpdvmiddle.tb_doctotributacaoitem
          where nroempresa = i.nroempresa
            and nrocheckout = i.nrocheckout
            and seqdocto = i.seqdocto
            and seqitem = i.seqitem
            and seqtipotributacao = 15) vlicmsdesoneracao,
        0 vlicmsdifaliqpart,
        i.vlrunitario vlitem,
        0 vlitemtributosestadual,
        0 vlitemtributosmunicipal,
        0 vliss,
        0 vlicmspartrem,
        0 vlipi,
        0 vlipiecf,
        0 vloutrasdesp,
        NULL vlmexiva,
        ((NVL(h.percpis,0)/100) * i.vlrtotal) vlpis,
        --(i.quantidade * (i.vlrunitario - (NVL(i.vlrdesconto,0) / i.quantidade))) vlsubtotitem,
        i.vlrtotal vlsubtotitem,
        0 vlricmssimplesnac,
        NULL vpart,
        0 perctributos,
        a.codst,
        (select est.vlicmsbcr from pcest est where est.codfilial = v.codfilial and est.codprod = v.codprod) vlicmsbcr,
        h.percpis,
        0 aliqicms1ret
  FROM  monitorpdvmiddle.tb_doctoitem   i,
        monitorpdvmiddle.tb_docto       d,
        monitorpdvmiddle.tb_doctocupom  c,
        monitorpdvmiddle.tb_produto     p,
        --monitorpdvmiddle.tb_doctotributacaoitem ti,
        vw_int_c5_trib_pis h,
        vw_int_c5_pcprodut              v,
        pcconsolidatributacao           a
 WHERE  i.seqdocto = d.seqdocto
   AND  i.nroempresa = d.nroempresa
   AND  i.nrocheckout = d.nrocheckout
   AND  i.seqproduto = p.seqproduto
   AND  d.seqdocto = c.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  i.nroempresa = v.codfilial
   AND  i.codacesso = v.codauxiliar
   AND  i.seqproduto = v.seqproduto
   --AND  i.seqdocto = ti.seqdocto
   --AND  i.nrocheckout = ti.nrocheckout
   --AND  i.nroempresa = ti.nroempresa
  -- AND  i.seqitem = ti.seqitem
     -- AND i.seqdocto = a.seqdocto(+)
   AND  i.nrotributacao = a.codst
   AND  i.nrotributacao = h.codst(+)
   AND  i.codacesso = h.codauxiliar(+)
   and  i.nroempresa = h.codfilial(+)
   AND  a.numregiao = ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',d.nroempresa,1)
   AND  c.status in ('V', 'C')
   AND  i.status = 'V')
   
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
		   MIN(SEQITEM) SEQITEM
	  FROM MONITORPDVMIDDLE.TB_DOCTOPAGTO P
	 WHERE P.NROFORMAPAGTO IN
		   (SELECT fp.nroformapagto
			  FROM monitorpdvmiddle.tb_formapagto fp
			 where fp.formapagto = 'DINHEIRO')
	   AND P.VLRTOTAL > 0
	 GROUP BY P.NROEMPRESA, P.NROCHECKOUT, P.SEQDOCTO, P.nroformapagto
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
	   P.nroformapagto
  FROM MONITORPDVMIDDLE.TB_DOCTOPAGTO P
 WHERE P.NROFORMAPAGTO IN
       (SELECT fp.nroformapagto
          FROM monitorpdvmiddle.tb_formapagto fp
         where fp.especie = 'D'
         and fp.formapagto LIKE '%DINHEIRO%')
   AND P.VLRTOTAL < 0
 GROUP BY P.NROEMPRESA, P.NROCHECKOUT, P.SEQDOCTO, P.nroformapagto
 )

\

CREATE OR REPLACE VIEW vw_int_c5_pcprestecf AS
( SELECT  d.seqdocto,
        NULL numgiftcard,
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
        c.nronotafiscal duplic,
        NVL(c.seqpessoa,1) codcli,
        TO_CHAR(NVL(r.dtvenc, p.dtavencimento),'YYYY-MM-DD') dtvenc,
        NVL(
        (CASE
            WHEN p.valor < 0
                THEN 'TR'
            ELSE
                NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))
          END),'D') codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        p.nroempresa codfilial,
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(NVL(r.DTVENC,p.dtavencimento),'YYYY-MM-DD') dtvencorig,
        'N' operacao,
        f.boleto,
        NULL numbanco,
        NULL numagencia,
        NULL numcheque,
        NVL(fnc_int_c5_codsuperv(d.sequsuario),1) codsupervisor,
        p.cmc7 codbarra,
        NVL(r.valor, p.valor) valororig,
        NVL(
        (CASE
            WHEN p.valor < 0
                THEN 'TR'
            ELSE
                NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))
          END),'D') codcoborig,
       0 vltxboleto,
       p.nroempresa codfilialnf,
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
                p.nsutef
         END) nsutef,
       NULL numecf,
       (CASE
            WHEN NVL(p.qtdparcelatef,0) > 1
                THEN 'S'
            ELSE 'N'
         END) parcelamentotef,
       NULL prestef,
       p.codredetef codadmcartao,
       '0'||TRUNC((p.modalidadetef/ 100),2) tipooperacaotef,
       p.codbandeiratef codbandeiratef,
       NULL dtbaixa,
       (CASE
            WHEN f.especie = 'G'
                THEN NULL
            ELSE
                REGEXP_REPLACE(p.codautorizacaotef,'[^0-9]', '')
         END) codautorizacaotef,
       NULL numccf,
       NULL linhadig,
       NULL vlmexiva,
       NULL assinatura,
       NULL numgnf,
       NULL numseriesat,
       p.codcredenciadoratef cnpjcredenccartao,
       NULL numcartaocrm,
       (CASE
            WHEN f.especie = 'G'
                THEN NULL
            ELSE
                p.nsuhosttef
         END) nsuhost,
       0 valorcontravale,
       NULL compensacaobco,
       NULL cgccpfch,
       NULL dvagencia,
       NULL dvconta,
       NULL dvcheque,
       0 numfechamentomovcx,
       TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtmovimentocx,
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
        NULL nsupagdigital,
        fnc_int_c5_nome_pix(p.idcarteira) nomecarteiradigital,
        (CASE
            WHEN f.especie = 'G'
                THEN 'S'
            ELSE 'N'
         END) carteiradigital,
        NVL(r.valor, p.valor) valor
  FROM  monitorpdvmiddle.tb_doctopagto p,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        vw_int_c5_cobranca_winthor v,
    TABLE(FNC_INT_C5_PRESTS_TEF(p.seqdocto)) r
 WHERE  p.seqdocto = d.seqdocto
   AND p.nroformapagto not in (SELECT fp.nroformapagto
          FROM monitorpdvmiddle.tb_formapagto fp
         where fp.especie = 'D'
         and fp.formapagto LIKE '%DINHEIRO%')
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  p.nroformapagto = f.nroformapagto
   AND  f.codcob = v.codcob(+)
   --AND f.codcob = v.especie(+)
   AND  d.especie IN ('NF', 'CF')
   --AND c.status = 'V'
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
        c.nronotafiscal duplic,
        NVL(c.seqpessoa,1) codcli,
        TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtvenc,
        NVL(
        (CASE
            WHEN p.valor < 0
                THEN 'TR'
            ELSE
                NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))
          END),'D') codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        p.nroempresa codfilial,
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtvencorig,
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
       p.nroempresa codfilialnf,
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
       TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtmovimentocx,
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
	   p.valor valor
  FROM  vw_int_c5_agrup_dinheiro p,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        vw_int_c5_cobranca_winthor v
 WHERE  p.seqdocto = d.seqdocto
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  p.nroformapagto = f.nroformapagto
   AND  f.codcob = v.codcob(+)
   --AND f.codcob = v.especie(+)
   AND  d.especie IN ('NF', 'CF')
   --AND c.status = 'V'
   UNION ALL
      SELECT  d.seqdocto,
        NULL numgiftcard,
        'N' exportado,
        NULL presttef,
        d.sequsuario codfunccheckout,
        d.nrocheckout numcheckout,
        'NOTAFISCAL' numserieequip,
        c.nronotafiscal duplic,
        NVL(c.seqpessoa,1) codcli,
        TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtvenc,
        NVL(
        (CASE
            WHEN p.valor < 0
                THEN 'TR'
            ELSE
                NVL(f.codcob ,FNC_INT_C5_ESPECIE_COB_VENDAS(p.seqdocto, p.nrocheckout,p.nroempresa, p.seqitem))
          END),'D') codcob,
        TO_CHAR(p.dtabasecobranca,'YYYY-MM-DD') dtemissao,
        p.nroempresa codfilial,
        'A' status,
        fnc_int_c5_codusur(d.sequsuario) codusur,
        TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtvencorig,
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
       p.nroempresa codfilialnf,
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
       TO_CHAR(p.dtavencimento,'YYYY-MM-DD') dtmovimentocx,
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
	   p.valor valor
  FROM  vw_int_c5_agrup_troco p,
        monitorpdvmiddle.tb_docto d,
        monitorpdvmiddle.tb_doctocupom c,
        vw_int_c5_finaliz_venda f,
        vw_int_c5_cobranca_winthor v
 WHERE  p.seqdocto = d.seqdocto
   AND  p.nroempresa = d.nroempresa
   AND  p.nrocheckout = d.nrocheckout
   AND  d.seqdocto = c.seqdocto
   AND  d.nroempresa = c.nroempresa
   AND  d.nrocheckout = c.nrocheckout
   AND  p.nroformapagto = f.nroformapagto
   AND  f.codcob = v.codcob(+)
   AND  d.especie IN ('NF', 'CF')
)
