CREATE OR REPLACE PACKAGE BODY PKG_XML AS
  VCHAVENFE PCNFENTXML.CHAVENFE%TYPE;

  PROCEDURE LOG_PROCESS(STEXTO IN VARCHAR2, SSITUACAO IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    UPDATE PCNFENTXML
       SET PCNFENTXML.LOG_PROCESS = CONCAT(PCNFENTXML.LOG_PROCESS,
                                           (TO_CHAR(SYSDATE,
                                                    'DD/MM/YYYY HH24:MI:SS') ||
                                           CHR(32) || STEXTO) || CHR(13)),
           PCNFENTXML.SITUACAO    = SSITUACAO
     WHERE PCNFENTXML.CHAVENFE = VCHAVENFE;
    COMMIT;
  END LOG_PROCESS;

  FUNCTION TONUMERO(SVALOR VARCHAR2) RETURN NUMBER IS
    VALOR NUMBER(18, 6);
  BEGIN
  
    SELECT TO_NUMBER(
         REPLACE(REPLACE(SVALOR, ',', '.'), '.', ','), 
         '999999999D9999999999'
       ) AS VALOR
    INTO VALOR   
    FROM DUAL;
	
    RETURN(VALOR);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END TONUMERO;

  FUNCTION TONUMERO(SVALOR VARCHAR2, NQUANTIDADE NUMBER) RETURN NUMBER IS
    VALOR NUMBER(18, 6);
  BEGIN
  
    SELECT (TO_NUMBER(REPLACE(REPLACE(SVALOR, ',', '.'), '.', ','),
                  '999999999D9999999999') / NQUANTIDADE) AS VALOR
    INTO VALOR
    FROM DUAL;
	
    RETURN(VALOR);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END TONUMERO;

  FUNCTION TODATA(SDATA VARCHAR2) RETURN DATE IS
    DATA DATE;
  BEGIN
    SELECT TO_DATE(SDATA, 'YYYY-MM-DD') INTO DATA FROM DUAL;
    RETURN(DATA);
  END TODATA;

  FUNCTION SONUMERO(STEXTO VARCHAR2) RETURN VARCHAR2 IS
    NUMERO VARCHAR2(20);
  BEGIN
    SELECT REGEXP_REPLACE(STEXTO, '[^0-9]') INTO NUMERO FROM DUAL;
    RETURN(NUMERO);
  END SONUMERO;

  FUNCTION CODEMITENTE(SCGC PCFORNEC.CGC%TYPE) RETURN PCFORNEC.CODFORNEC%TYPE IS
    CODIGO     PCFORNEC.CODFORNEC%TYPE;
    MSG        VARCHAR2(200);
    IMPORTAXML PCFORNEC.IMPORTAXMLAUTOMATICO%TYPE;
  BEGIN
    BEGIN
      SELECT PCFORNEC.CODFORNEC,
             NVL(PCFORNEC.IMPORTAXMLAUTOMATICO, 'S') IMPORTAXML
        INTO CODIGO, IMPORTAXML
        FROM PCFORNEC
       WHERE PCFORNEC.REVENDA IN ('S', 'O', 'X')
         AND REGEXP_REPLACE(PCFORNEC.CGC, '[^0-9]') =
             REGEXP_REPLACE(SCGC, '[^0-9]');
      IF (IMPORTAXML = 'N') THEN
        MSG := 'Definido no cadastro do Fornecedor para não importar XML de forma automática.';
        LOG_PROCESS(MSG, 'R');
        RAISE_APPLICATION_ERROR(-20102, MSG);
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          MSG := 'Fornecedor não encontrado com o CPF/CNPJ informado no XML. CGC: ' || SCGC ||
                 CHR(13) ||
                 'Cadastre-o e classifique como: "É Revenda", "Consumo" ou "Exportador".';
          LOG_PROCESS(MSG, 'P');
          RAISE_APPLICATION_ERROR(-20101, MSG);
        END;
      WHEN TOO_MANY_ROWS THEN
        BEGIN
          MSG := 'Encontrado mais de um Fornecedor com o CPF/CNPJ informado no XML. CGC: ' || SCGC || '.';
          LOG_PROCESS(MSG, 'P');
          RAISE_APPLICATION_ERROR(-20101, MSG);
        END;
    END;
    RETURN(CODIGO);
  END CODEMITENTE;

  FUNCTION CODDESTINATARIO(SCGC PCFILIAL.CGC%TYPE)
    RETURN PCFILIAL.CODIGO%TYPE IS
    CODIGO PCFILIAL.CODIGO%TYPE;
    MSG    VARCHAR2(100);
  BEGIN
    BEGIN
      SELECT PCFILIAL.CODIGO
        INTO CODIGO
        FROM PCFILIAL
       WHERE REGEXP_REPLACE(PCFILIAL.CGC, '[^0-9]') =
             REGEXP_REPLACE(SCGC, '[^0-9]')
         AND PCFILIAL.DTEXCLUSAO IS NULL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          MSG := 'Filial não encontrada com o CNPJ informado no XML. CGC: ' || SCGC;
          LOG_PROCESS(MSG, 'P');
          RAISE_APPLICATION_ERROR(-20101, MSG);
        END;
      WHEN TOO_MANY_ROWS THEN
        BEGIN
          MSG := 'Encontrado mais de uma Filial Ativa com o CNPJ informado no XML. CGC: ' || SCGC || '.';
          LOG_PROCESS(MSG, 'P');
          RAISE_APPLICATION_ERROR(-20101, MSG);
        END;
    END;
    RETURN(CODIGO);
  END CODDESTINATARIO;

  FUNCTION LER_PARCELAS(SCHAVENFE IN PCNFENTXML.CHAVENFE%TYPE)
    RETURN TBL_PARCELAS
    PIPELINED IS
    PARCELAS ROW_PARCELAS;
  BEGIN
    VCHAVENFE := SCHAVENFE;
    FOR REG IN (SELECT TABELA_PARCELAS.*
                  FROM PCNFENTXML XML,
                       XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                                '/nfeProc/NFe/infNFe/cobr/dup' PASSING
                                XMLTYPE.CREATEXML(XML.DADOSXML) /*campo XML*/
                                COLUMNS NDUP varchar2(15) PATH
                                '/dup/nDup/text()',
                                DVENC varchar2(10) PATH '/dup/dVenc/text()',
                                VDUP varchar2(20) PATH '/dup/vDup/text()') TABELA_PARCELAS
                 WHERE XML.CHAVENFE = SCHAVENFE) LOOP
      PARCELAS.NDUP  := REG.NDUP;
      PARCELAS.DVENC := TODATA(REG.DVENC);
      PARCELAS.VDUP  := TONUMERO(REG.VDUP);
      PIPE ROW(PARCELAS);
    END LOOP;

    RETURN;
  END LER_PARCELAS;

  FUNCTION LER_CABECALHO(SCHAVENFE IN PCNFENTXML.CHAVENFE%TYPE)
    RETURN TBL_CABECALHO
    PIPELINED IS
    CABECALHO ROW_CABECALHO;
  BEGIN
    VCHAVENFE := SCHAVENFE;
    FOR REG IN (SELECT CABECALHO.NNF,
                       CABECALHO.MOD_,
                       CABECALHO.SERIE,
                       CABECALHO.DHEMI,
                       CABECALHO.DHSAIENT,
                       CABECALHO.NATOP,
                       CABECALHO.INDPRES,
                       CABECALHO.CNPJ_EMIT,
                       CABECALHO.CPF_EMIT,
                       CABECALHO.XNOME_EMIT,
                       CABECALHO.CNPJ_DEST,
                       CABECALHO.XNOME_DEST,
                       CABECALHO.MODFRETE,
                       CABECALHO.PLACA,
                       CABECALHO.VPROD,
                       CABECALHO.VDESC,
                       CABECALHO.VFRETE,
                       CABECALHO.VSEG,
                       CABECALHO.VOUTRO,
                       CABECALHO.VBC,
                       CABECALHO.VICMSDESON,
                       CABECALHO.VICMS,
                       CABECALHO.VIPI,
                       CABECALHO.VPIS,
                       CABECALHO.VCOFINS,
                       CABECALHO.VST,
                       CABECALHO.VFCP,
                       CABECALHO.VFCPST,
                       CABECALHO.VFCPSTRET,
                       CABECALHO.VBCST,
                       CABECALHO.VNF,
                       CABECALHO.CNPJ_INTERMED,
                       CABECALHO.IDCADINTTRAN,
                       CABECALHO.INFCPL,
                       CHAVE.CHNFE,
                       XMLX.CODFORNEC
                  FROM PCNFENTXML XMLX,
                       XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                                '/nfeProc/NFe/infNFe' PASSING
                                XMLTYPE.CREATEXML(XMLX.DADOSXML) /*campo XML*/
                                COLUMNS NNF varchar2(10) PATH
                                '/infNFe/ide/nNF/text()',
                                MOD_ varchar2(2) PATH
                                '/infNFe/ide/mod/text()',
                                SERIE varchar2(3) PATH
                                '/infNFe/ide/serie/text()',
                                DHEMI varchar2(10) PATH
                                '/infNFe/ide/dhEmi/text()',
                                DHSAIENT varchar2(10) PATH
                                '/infNFe/ide/dhSaiEnt/text()',
                                NATOP varchar2(60) PATH
                                '/infNFe/ide/natOp/text()',
                                INDPRES varchar2(1) PATH
                                '/infNFe/ide/indPres/text()',
                                CNPJ_EMIT varchar2(14) PATH
                                '/infNFe/emit/CNPJ/text()',
                                CPF_EMIT varchar2(11) PATH
                                '/infNFe/emit/CPF/text()',
                                XNOME_EMIT varchar2(60) PATH
                                '/infNFe/emit/xNome/text()',
                                CNPJ_DEST varchar2(14) PATH
                                '/infNFe/dest/CNPJ/text()',
                                XNOME_DEST varchar2(60) PATH
                                '/infNFe/dest/xNome/text()',
                                MODFRETE varchar2(1) PATH
                                '/infNFe/transp/modFrete/text()',
                                PLACA varchar2(10) PATH
                                '/infNFe/transp/veicTransp/placa/text()',
                                VPROD varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vProd/text()',
                                VDESC varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vDesc/text()',
                                VFRETE varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vFrete/text()',
                                VSEG varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vSeg/text()',
                                VOUTRO varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vOutro/text()',
                                VBC varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vBC/text()',
                                VICMSDESON varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vICMSDeson/text()',
                                VICMS varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vICMS/text()',
                                VIPI varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vIPI/text()',
                                VPIS varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vPIS/text()',
                                VCOFINS varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vCOFINS/text()',
                                VST varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vST/text()',
                                VFCP varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vFCP/text()',
                                VFCPST varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vFCPST/text()',
                                VFCPSTRET varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vFCPSTRet/text()',
                                VBCST varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vBCST/text()',
                                VNF varchar2(20) PATH
                                '/infNFe/total/ICMSTot/vNF/text()',
                                CNPJ_INTERMED varchar2(20) PATH
                                '/infNFe/infIntermed/CNPJ/text()',
                                IDCADINTTRAN varchar2(60) PATH
                                '/infNFe/infIntermed/idCadIntTran/text()',
                                INFCPL varchar2(4000) PATH
                                '/infNFe/infAdic/infCpl/text()') CABECALHO,
                       XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                                '/nfeProc/protNFe' PASSING
                                XMLTYPE.CREATEXML(XMLX.DADOSXML) /*campo XML*/
                                COLUMNS CHNFE varchar2(45) PATH
                                '/protNFe/infProt/chNFe/text()') CHAVE
                 WHERE XMLX.CHAVENFE = SCHAVENFE) LOOP
      CABECALHO.NNF        := REG.NNF;
      CABECALHO.MOD_       := REG.MOD_;
      CABECALHO.SERIE      := REG.SERIE;
      CABECALHO.DHEMI      := TODATA(REG.DHEMI);
      CABECALHO.DHSAIENT   := TODATA(REG.DHSAIENT);
      CABECALHO.CNPJ_EMIT  := SONUMERO(NVL(REG.CNPJ_EMIT, REG.CPF_EMIT));
      CABECALHO.XNOME_EMIT := REG.XNOME_EMIT;
      CABECALHO.CNPJ_DEST  := SONUMERO(REG.CNPJ_DEST);
      CABECALHO.XNOME_DEST := REG.XNOME_DEST;
      CABECALHO.NATOP      := REG.NATOP;
      CABECALHO.CODFILIAL  := CODDESTINATARIO(CABECALHO.CNPJ_DEST);
      IF (NVL(REG.CODFORNEC, 0) > 0) THEN
        CABECALHO.CODFORNEC := REG.CODFORNEC;
      ELSE
        CABECALHO.CODFORNEC := CODEMITENTE(CABECALHO.CNPJ_EMIT);
      END IF;
      CABECALHO.MODFRETE      := REG.MODFRETE;
      CABECALHO.PLACA         := REG.PLACA;
      CABECALHO.VPROD         := TONUMERO(REG.VPROD);
      CABECALHO.VDESC         := TONUMERO(REG.VDESC);
      CABECALHO.VFRETE        := TONUMERO(REG.VFRETE);
      CABECALHO.VSEG          := TONUMERO(REG.VSEG);
      CABECALHO.VOUTRO        := TONUMERO(REG.VOUTRO);
      CABECALHO.VBC           := TONUMERO(REG.VBC);
      CABECALHO.VICMSDESON    := TONUMERO(REG.VICMSDESON);
      CABECALHO.VICMS         := TONUMERO(REG.VICMS);
      CABECALHO.VIPI          := TONUMERO(REG.VIPI);
      CABECALHO.VPIS          := TONUMERO(REG.VPIS);
      CABECALHO.VCOFINS       := TONUMERO(REG.VCOFINS);
      CABECALHO.VST           := TONUMERO(REG.VST);
      CABECALHO.VFCP          := TONUMERO(REG.VFCP);
      CABECALHO.VFCPST        := TONUMERO(REG.VFCPST);
      CABECALHO.VFCPSTRET     := TONUMERO(REG.VFCPSTRET);
      CABECALHO.VBCST         := TONUMERO(REG.VBCST);
      CABECALHO.VNF           := TONUMERO(REG.VNF);
      CABECALHO.INDPRES       := REG.INDPRES;
      CABECALHO.CNPJ_INTERMED := REG.CNPJ_INTERMED;
      CABECALHO.IDCADINTTRAN  := REG.IDCADINTTRAN;
      CABECALHO.INFCPL        := SUBSTR(REG.INFCPL, 1, 255);
      CABECALHO.CHNFE         := REG.CHNFE;
      PIPE ROW(CABECALHO);
    END LOOP;

    RETURN;
  END LER_CABECALHO;

  FUNCTION CODPRODUTO(SCODFILIAL IN PCPRODUT.CODFILIAL%TYPE,
                      NCODFORNEC IN PCCODFABRICA.CODFORNEC%TYPE,
                      CPROD      IN VARCHAR2,
                      CEAN       IN VARCHAR2,
                      SOMENTE253 IN PCFORNEC.UTILIZAFATOR253%TYPE,
                      USALOTE    OUT PCPRODUT.ESTOQUEPORLOTE%TYPE)
    RETURN PCPRODUT.CODPROD%TYPE IS
    CODIGO PCPRODUT.CODPROD%TYPE;
  BEGIN
    BEGIN
      SELECT /*+ INDEX (PCPRODUT PCPRODUT_IDX33) */
       PCPRODUT.CODPROD, NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') USALOTE
        INTO CODIGO, USALOTE
        FROM PCPRODUT
       WHERE (PCPRODUT.CODFILIAL = SCODFILIAL OR
             NVL(PCPRODUT.CODFILIAL, '99') = '99')
         AND PCPRODUT.CODPROD IN
             (SELECT PCCODFABRICA.CODPROD
                FROM PCCODFABRICA
               WHERE UPPER(PCCODFABRICA.CODFAB) = UPPER(CPROD)
                 AND PCCODFABRICA.CODFORNEC = NCODFORNEC)
         AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          IF (SOMENTE253 = 'N') THEN
            SELECT /*+ INDEX (PCPRODUT PCPRODUT_IDX30) */
             PCPRODUT.CODPROD, NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') USALOTE
              INTO CODIGO, USALOTE
              FROM PCPRODUT
             WHERE (PCPRODUT.CODFILIAL = SCODFILIAL OR
                   NVL(PCPRODUT.CODFILIAL, '99') = '99')
               AND UPPER(PCPRODUT.CODFAB) = UPPER(CPROD)
               AND ROWNUM = 1;
          ELSE
            RAISE NO_DATA_FOUND;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              IF (SOMENTE253 = 'N') THEN
                SELECT /*+ INDEX (PCPRODUT PCPRODUT_IDX31) */
                 PCPRODUT.CODPROD,
                 NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') USALOTE
                  INTO CODIGO, USALOTE
                  FROM PCPRODUT
                 WHERE (PCPRODUT.CODFILIAL = SCODFILIAL OR
                       NVL(PCPRODUT.CODFILIAL, '99') = '99')
                   AND NVL(PCPRODUT.CODAUXILIAR, 0) > 0
                   AND NVL(PCPRODUT.CODAUXILIAR, 0) = NVL(CEAN, 0)
                   AND ROWNUM = 1;
              ELSE
                RAISE NO_DATA_FOUND;
              END IF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                BEGIN
                  IF (SOMENTE253 = 'N') THEN
                    SELECT /*+ INDEX (PCPRODUT PCPRODUT_IDX32) */
                     PCPRODUT.CODPROD,
                     NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') USALOTE
                      INTO CODIGO, USALOTE
                      FROM PCPRODUT
                     WHERE (PCPRODUT.CODFILIAL = SCODFILIAL OR
                           NVL(PCPRODUT.CODFILIAL, '99') = '99')
                       AND NVL(PCPRODUT.CODAUXILIAR2, 0) > 0
                       AND NVL(PCPRODUT.CODAUXILIAR2, 0) = NVL(CEAN, 0)
                       AND ROWNUM = 1;
                  ELSE
                    RAISE NO_DATA_FOUND;
                  END IF;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    BEGIN
                      CODIGO := 0;
                      LOG_PROCESS('Produto não encontrado. Filial: ' ||
                                  SCODFILIAL || ', Cód.Fábrica: ' || CPROD ||
                                  ' e Cód.Barra: ' || CEAN,
                                  'P');
                    END;
                END;
            END;
        END;
    END;

    RETURN(CODIGO);
  END CODPRODUTO;

  FUNCTION LER_ITENS(SCHAVENFE IN PCNFENTXML.CHAVENFE%TYPE) RETURN TBL_ITENS
    PIPELINED IS
    ITENS      ROW_ITENS;
    CABECALHO  ROW_CABECALHO;
    USALOTE    PCPRODUT.ESTOQUEPORLOTE%TYPE;
    SOMENTE253 PCFORNEC.UTILIZAFATOR253%TYPE;
    RINCLUIR   NUMBER := 1;
  BEGIN
    VCHAVENFE := SCHAVENFE;
    SELECT CAB.* INTO CABECALHO FROM TABLE(LER_CABECALHO(SCHAVENFE)) CAB;
    SELECT (CASE
             WHEN (COALESCE(PCFORNEC.TIPOEMBALAGEMPEDIDO, 'V') = 'M') AND
                  (COALESCE(PCFORNEC.UTILIZAFATOR253, 'N') = 'S') AND
                  (COALESCE(PCFORNEC.GRAVARCODFAB253, 'N') = 'N') THEN
              'S'
             ELSE
              'N'
           END) SOMENTE253
      INTO SOMENTE253
      FROM PCFORNEC
     WHERE PCFORNEC.CODFORNEC = CABECALHO.CODFORNEC;

    FOR REG IN (SELECT TABELA_ITEM.NITEM,
                       TABELA_ITEM.XPED,
                       TABELA_ITEM.NITEMPED,
                       TABELA_ITEM.CPROD,
                       TABELA_ITEM.CEAN,
                       TABELA_ITEM.CEANTRIB,
                       TABELA_ITEM.NFCI,
                       TABELA_ITEM.NCM,
                       TABELA_ITEM.CEST,
                       TABELA_ITEM.CFOP,
                       TABELA_ITEM.EXTIPI,
                       TABELA_ITEM.CBENEF,
                       TABELA_ITEM.UCOM,
                       TABELA_ITEM.XPROD,
                       TABELA_ITEM.VUNCOM,
                       TABELA_ITEM.QCOM,
                       TABELA_ITEM.QTRIB,
                       TABELA_ITEM.VUNTRIB,
                       TABELA_ITEM.VDESC,
                       TABELA_ITEM.VFRETE,
                       TABELA_ITEM.VOUTRO,
                       TABELA_ITEM.VSEG,
                       TABELA_ITEM.VPROD,
                       TABELA_ITEM.INDESCALA,
                       TABELA_ITEM.CNPJFAB,
                       TABELA_ITEM.CPRODANVISA,
                       TABELA_ITEM.VPMC,
                       TABELA_ITEM.CST_IPI,
                       TABELA_ITEM.VBC_IPI,
                       TABELA_ITEM.PIPI,
                       TABELA_ITEM.VIPI,
                       TABELA_ITEM.CST_PIS,
                       TABELA_ITEM.VBC_PIS,
                       TABELA_ITEM.PPIS,
                       TABELA_ITEM.VPIS,
                       TABELA_ITEM.CST_COFINS,
                       TABELA_ITEM.VBC_COFINS,
                       TABELA_ITEM.PCOFINS,
                       TABELA_ITEM.VCOFINS,
                       TABELA_ITEM.ORIG,
                       TABELA_ITEM.CST,
                       TABELA_ITEM.MODBC,
                       TABELA_ITEM.PREDBC,
                       TABELA_ITEM.VBC,
                       TABELA_ITEM.PST,
                       TABELA_ITEM.PICMS,
                       TABELA_ITEM.VICMSOP,
                       TABELA_ITEM.PDIF,
                       TABELA_ITEM.VICMSDIF,
                       TABELA_ITEM.VICMS,
                       TABELA_ITEM.VICMSSUBSTITUTO,
                       TABELA_ITEM.MODBCST,
                       TABELA_ITEM.PMVAST,
                       TABELA_ITEM.PREDBCST,
                       TABELA_ITEM.VBCST,
                       TABELA_ITEM.PICMSST,
                       TABELA_ITEM.VICMSST,
                       TABELA_ITEM.VBCSTRET,
                       TABELA_ITEM.VICMSSTRET,
                       TABELA_ITEM.VBCFCP,
                       TABELA_ITEM.PFCP,
                       TABELA_ITEM.VFCP,
                       TABELA_ITEM.VBCFCPST,
                       TABELA_ITEM.PFCPST,
                       TABELA_ITEM.VFCPST,
                       TABELA_ITEM.VBCFCPSTRET,
                       TABELA_ITEM.PFCPSTRET,
                       TABELA_ITEM.VFCPSTRET,
                       TABELA_ITEM.PREDBCEFET,
                       TABELA_ITEM.VBCEFET,
                       TABELA_ITEM.PICMSEFET,
                       TABELA_ITEM.VICMSEFET,
                       TABELA_ITEM.VICMSDESON,
                       TABELA_ITEM.MOTDESICMS,
                       TABELA_ITEM.IBSCBS_CST,
                       TABELA_ITEM.IBSCBS_CCLASSTRIB,
                       TABELA_ITEM.gIBSCBS_vBC,
                       TABELA_ITEM.gIBSUF_pIBSUF,
                       TABELA_ITEM.gIBSUF_vIBSUF,
                       TABELA_ITEM.gIBSMun_pIBSMun,
                       TABELA_ITEM.gIBSMun_vIBSMun,
                       TABELA_ITEM.gIBSMun_gRed_pRedAliq,
                       TABELA_ITEM.gIBSMun_gRed_pAliqEfet,
                       TABELA_ITEM.gCBS_pCBS,
                       TABELA_ITEM.gCBS_vCBS,
                       TABELA_ITEM.RASTREIO,
                       TABELA_ITEM.TAGICMS60
                  FROM PCNFENTXML XMLX,
                       XMLTable(XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                                '/nfeProc/NFe/infNFe/det' PASSING
                                XMLTYPE.CREATEXML(XMLX.DADOSXML) /*campo XML*/
                                COLUMNS NITEM number(5) PATH '/det/@nItem',
                                XPED varchar2(15) PATH
                                '/det/prod/xPed/text()',
                                NITEMPED varchar2(6) PATH
                                '/det/prod/nItemPed/text()',
                                CPROD varchar2(18) PATH
                                '/det/prod/cProd/text()',
                                CEAN varchar2(18) PATH
                                '/det/prod/cEAN/text()',
                                CEANTRIB varchar2(18) PATH
                                '/det/prod/cEANTrib/text()',
                                NFCI varchar2(36) PATH
                                '/det/prod/nFCI/text()',
                                NCM varchar2(15) PATH '/det/prod/NCM/text()',
                                CEST varchar2(10) PATH
                                '/det/prod/CEST/text()',
                                CFOP varchar2(4) PATH '/det/prod/CFOP/text()',
                                EXTIPI varchar2(2) PATH
                                '/det/prod/EXTIPI/text()',
                                CBENEF varchar2(10) PATH
                                '/det/prod/cBenef/text()',
                                UCOM varchar2(10) PATH
                                '/det/prod/uCom/text()',
                                XPROD varchar2(60) PATH
                                '/det/prod/xProd/text()',
                                VUNCOM varchar2(20) PATH
                                '/det/prod/vUnCom/text()',
                                QCOM varchar2(20) PATH
                                '/det/prod/qCom/text()',
                                QTRIB varchar2(20) PATH
                                '/det/prod/qTrib/text()',
                                VUNTRIB varchar2(20) PATH
                                '/det/prod/vUnTrib/text()',
                                VDESC varchar2(20) PATH
                                '/det/prod/vDesc/text()',
                                VFRETE varchar2(20) PATH
                                '/det/prod/vFrete/text()',
                                VOUTRO varchar2(20) PATH
                                '/det/prod/vOutro/text()',
                                VSEG varchar2(20) PATH
                                '/det/prod/vSeg/text()',
                                VPROD varchar2(20) PATH
                                '/det/prod/vProd/text()',
                                INDESCALA varchar2(2) PATH
                                '/det/prod/indEscala/text()',
                                CNPJFAB varchar2(18) PATH
                                '/det/prod/CNPJFab/text()',
                                CPRODANVISA varchar2(13) PATH
                                '/det/prod/med/cProdANVISA/text()',
                                VPMC varchar2(20) PATH
                                '/det/prod/med/vPMC/text()',
                                CST_IPI varchar2(3) PATH
                                '/det/imposto/IPI/IPITrib/CST/text()',
                                VBC_IPI varchar2(20) PATH
                                '/det/imposto/IPI/IPITrib/vBC/text()',
                                PIPI varchar2(20) PATH
                                '/det/imposto/IPI/IPITrib/pIPI/text()',
                                VIPI varchar2(20) PATH
                                '/det/imposto/IPI/IPITrib/vIPI/text()',
                                CST_PIS varchar2(3) PATH
                                '/det/imposto/PIS/PISAliq/CST/text()',
                                VBC_PIS varchar2(20) PATH
                                '/det/imposto/PIS/PISAliq/vBC/text()',
                                PPIS varchar2(10) PATH
                                '/det/imposto/PIS/PISAliq/pPIS/text()',
                                VPIS varchar2(20) PATH
                                '/det/imposto/PIS/PISAliq/vPIS/text()',
                                CST_COFINS varchar2(3) PATH
                                '/det/imposto/COFINS/COFINSAliq/CST/text()',
                                VBC_COFINS varchar2(20) PATH
                                '/det/imposto/COFINS/COFINSAliq/vBC/text()',
                                PCOFINS varchar2(10) PATH
                                '/det/imposto/COFINS/COFINSAliq/pCOFINS/text()',
                                VCOFINS varchar2(20) PATH
                                '/det/imposto/COFINS/COFINSAliq/vCOFINS/text()',
                                ORIG varchar2(1) PATH
                                '/det/imposto/ICMS/*/orig/text()',
                                CST varchar2(2) PATH
                                '/det/imposto/ICMS/*/CST/text()',
                                MODBC varchar2(1) PATH
                                '/det/imposto/ICMS/*/modBC/text()',
                                PREDBC varchar2(10) PATH
                                '/det/imposto/ICMS/*/pRedBC/text()',
                                VBC varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBC/text()',
                                PST varchar2(10) PATH
                                '/det/imposto/ICMS/*/pST/text()',
                                PICMS varchar2(10) PATH
                                '/det/imposto/ICMS/*/pICMS/text()',
                                VICMSOP varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSOp/text()',
                                PDIF varchar2(10) PATH
                                '/det/imposto/ICMS/*/pDif/text()',
                                VICMSDIF varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSDif/text()',
                                VICMS varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMS/text()',
                                VICMSSUBSTITUTO varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSSubstituto/text()',
                                MODBCST varchar2(1) PATH
                                '/det/imposto/ICMS/*/modBCST/text()',
                                PMVAST varchar2(10) PATH
                                '/det/imposto/ICMS/*/pMVAST/text()',
                                PREDBCST varchar2(10) PATH
                                '/det/imposto/ICMS/*/pRedBCST/text()',
                                VBCST varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBCST/text()',
                                PICMSST varchar2(10) PATH
                                '/det/imposto/ICMS/*/pICMSST/text()',
                                VICMSST varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSST/text()',
                                VBCSTRET varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBCSTRet/text()',
                                VICMSSTRET varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSSTRet/text()',
                                VBCFCP varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBCFCP/text()',
                                PFCP varchar2(10) PATH
                                '/det/imposto/ICMS/*/pFCP/text()',
                                VFCP varchar2(20) PATH
                                '/det/imposto/ICMS/*/vFCP/text()',
                                VBCFCPST varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBCFCPST/text()',
                                PFCPST varchar2(10) PATH
                                '/det/imposto/ICMS/*/pFCPST/text()',
                                VFCPST varchar2(20) PATH
                                '/det/imposto/ICMS/*/vFCPST/text()',
                                VBCFCPSTRET varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBCFCPSTRet/text()',
                                PFCPSTRET varchar2(10) PATH
                                '/det/imposto/ICMS/*/pFCPSTRet/text()',
                                VFCPSTRET varchar2(20) PATH
                                '/det/imposto/ICMS/*/vFCPSTRet/text()',
                                PREDBCEFET varchar2(10) PATH
                                '/det/imposto/ICMS/*/pRedBCEfet/text()',
                                VBCEFET varchar2(20) PATH
                                '/det/imposto/ICMS/*/vBCEfet/text()',
                                PICMSEFET varchar2(10) PATH
                                '/det/imposto/ICMS/*/pICMSEfet/text()',
                                VICMSEFET varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSEfet/text()',
                                VICMSDESON varchar2(20) PATH
                                '/det/imposto/ICMS/*/vICMSDeson/text()',
                                MOTDESICMS varchar2(2) PATH
                                '/det/imposto/ICMS/*/motDesICMS/text()',
                                IBSCBS_CST varchar2(3) PATH
                                '/det/imposto/IBSCBS/CST/text()',
                                IBSCBS_CCLASSTRIB varchar2(6) PATH
                                '/det/imposto/IBSCBS/cClassTrib/text()',
                                gIBSCBS_vBC varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/vBC/text()',
                                gIBSUF_pIBSUF varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gIBSUF/pIBSUF/text()',
                                gIBSUF_vIBSUF varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gIBSUF/vIBSUF/text()',
                                gIBSMun_pIBSMun varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gIBSMun/pIBSMun/text()',
                                gIBSMun_vIBSMun varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gIBSMun/vIBSMun/text()',
                                gIBSMun_gRed_pRedAliq varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gIBSMun/gRed/pRedAliq/text()',
                                gIBSMun_gRed_pAliqEfet varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gIBSMun/gRed/pAliqEfet/text()',
                                gCBS_pCBS varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gCBS/pCBS/text()',
                                gCBS_vCBS varchar2(20) PATH
                                '/det/imposto/IBSCBS/gIBSCBS/gCBS/vCBS/text()',
                                TAGICMS60 varchar2(2) PATH
                                '/det/imposto/ICMS//ICMS60',
                                RASTREIO XMLTYPE PATH '/det/prod/rastro') TABELA_ITEM
                 WHERE XMLX.CHAVENFE = SCHAVENFE) LOOP
      RINCLUIR                     := 1;
      ITENS.NITEM                  := REG.NITEM;
      ITENS.XPED := (CASE
                      WHEN (LENGTH(TONUMERO(REG.XPED)) > 10) THEN
                       NULL
                      ELSE
                       TONUMERO(REG.XPED)
                    END);
      ITENS.NITEMPED               := TONUMERO(REG.NITEMPED);
      ITENS.CPROD                  := REG.CPROD;
      ITENS.CEAN                   := NVL(SONUMERO(REG.CEAN),
                                          SONUMERO(REG.CEANTRIB));
      ITENS.CODPROD                := CODPRODUTO(CABECALHO.CODFILIAL,
                                                 CABECALHO.CODFORNEC,
                                                 ITENS.CPROD,
                                                 ITENS.CEAN,
                                                 SOMENTE253,
                                                 USALOTE);
      ITENS.NFCI                   := REG.NFCI;
      ITENS.NCM                    := REG.NCM;
      ITENS.CEST                   := REG.CEST;
      ITENS.CFOP                   := TONUMERO(REG.CFOP);
      ITENS.EXTIPI                 := TONUMERO(REG.EXTIPI);
      ITENS.CBENEF                 := REG.CBENEF;
      ITENS.UCOM                   := REG.UCOM;
      ITENS.XPROD                  := REG.XPROD;
      ITENS.VUNCOM                 := TONUMERO(REG.VUNCOM);
      ITENS.QCOM                   := TONUMERO(REG.QCOM);
      ITENS.QTRIB                  := TONUMERO(REG.QTRIB);
      ITENS.VUNTRIB                := TONUMERO(REG.VUNTRIB, ITENS.QTRIB);
      ITENS.VDESC                  := TONUMERO(REG.VDESC, ITENS.QCOM);
      ITENS.VFRETE                 := TONUMERO(REG.VFRETE, ITENS.QCOM);
      ITENS.VOUTRO                 := TONUMERO(REG.VOUTRO, ITENS.QCOM);
      ITENS.VSEG                   := TONUMERO(REG.VSEG, ITENS.QCOM);
      ITENS.VPROD                  := TONUMERO(REG.VPROD, ITENS.QCOM);
      ITENS.INDESCALA              := REG.INDESCALA;
      ITENS.CNPJFAB                := SONUMERO(REG.CNPJFAB);
      ITENS.CPRODANVISA            := REG.CPRODANVISA;
      ITENS.VPMC                   := TONUMERO(REG.VPMC);
      ITENS.CST_IPI                := TONUMERO(REG.CST_IPI);
      ITENS.VBC_IPI                := TONUMERO(REG.VBC_IPI, ITENS.QCOM);
      ITENS.PIPI                   := TONUMERO(REG.PIPI);
      ITENS.VIPI                   := TONUMERO(REG.VIPI, ITENS.QCOM);
      ITENS.CST_PIS                := TONUMERO(REG.CST_PIS);
      ITENS.VBC_PIS                := TONUMERO(REG.VBC_PIS, ITENS.QCOM);
      ITENS.PPIS                   := TONUMERO(REG.PPIS);
      ITENS.VPIS                   := TONUMERO(REG.VPIS, ITENS.QCOM);
      ITENS.CST_COFINS             := TONUMERO(REG.CST_COFINS);
      ITENS.VBC_COFINS             := TONUMERO(REG.VBC_COFINS, ITENS.QCOM);
      ITENS.PCOFINS                := TONUMERO(REG.PCOFINS);
      ITENS.VCOFINS                := TONUMERO(REG.VCOFINS, ITENS.QCOM);
      ITENS.ORIG                   := TONUMERO(REG.ORIG);
      ITENS.CST                    := TONUMERO(REG.CST);
      ITENS.MODBC                  := TONUMERO(REG.MODBC);
      ITENS.PREDBC                 := TONUMERO(REG.PREDBC);
      ITENS.VBC                    := TONUMERO(REG.VBC, ITENS.QCOM);
      ITENS.PST                    := TONUMERO(REG.PST);
      ITENS.PICMS                  := TONUMERO(REG.PICMS);
      ITENS.VICMSOP                := TONUMERO(REG.VICMSOP, ITENS.QCOM);
      ITENS.PDIF                   := TONUMERO(REG.PDIF);
      ITENS.VICMSDIF               := TONUMERO(REG.VICMSDIF, ITENS.QCOM);
      ITENS.VICMS                  := TONUMERO(REG.VICMS, ITENS.QCOM);
      ITENS.VICMSSUBSTITUTO        := TONUMERO(REG.VICMSSUBSTITUTO,
                                               ITENS.QCOM);
      ITENS.MODBCST                := TONUMERO(REG.MODBCST);
      ITENS.PMVAST                 := TONUMERO(REG.PMVAST);
      ITENS.PREDBCST               := TONUMERO(REG.PREDBCST);
      ITENS.VBCST                  := TONUMERO(REG.VBCST, ITENS.QCOM);
      ITENS.PICMSST                := TONUMERO(REG.PICMSST);
      ITENS.VICMSST                := TONUMERO(REG.VICMSST, ITENS.QCOM);
      ITENS.VBCSTRET               := TONUMERO(REG.VBCSTRET, ITENS.QCOM);
      ITENS.VICMSSTRET             := TONUMERO(REG.VICMSSTRET, ITENS.QCOM);
      ITENS.VBCFCP                 := TONUMERO(REG.VBCFCP, ITENS.QCOM);
      ITENS.PFCP                   := TONUMERO(REG.PFCP);
      ITENS.VFCP                   := TONUMERO(REG.VFCP, ITENS.QCOM);
      ITENS.VBCFCPST               := TONUMERO(REG.VBCFCPST, ITENS.QCOM);
      ITENS.PFCPST                 := TONUMERO(REG.PFCPST);
      ITENS.VFCPST                 := TONUMERO(REG.VFCPST, ITENS.QCOM);
      ITENS.VBCFCPSTRET            := TONUMERO(REG.VBCFCPSTRET, ITENS.QCOM);
      ITENS.PFCPSTRET              := TONUMERO(REG.PFCPSTRET);
      ITENS.VFCPSTRET              := TONUMERO(REG.VFCPSTRET, ITENS.QCOM);
      ITENS.PREDBCEFET             := TONUMERO(REG.PREDBCEFET);
      ITENS.VBCEFET                := TONUMERO(REG.VBCEFET, ITENS.QCOM);
      ITENS.PICMSEFET              := TONUMERO(REG.PICMSEFET);
      ITENS.VICMSEFET              := TONUMERO(REG.VICMSEFET, ITENS.QCOM);
      ITENS.VICMSDESON             := TONUMERO(REG.VICMSDESON, ITENS.QCOM);
      ITENS.MOTDESICMS             := REG.MOTDESICMS;
      ITENS.IBSCBS_CST             := REG.IBSCBS_CST;
      ITENS.IBSCBS_CCLASSTRIB      := REG.IBSCBS_CCLASSTRIB;
      ITENS.gIBSCBS_vBC            := TONUMERO(REG.gIBSCBS_vBC, ITENS.QCOM);
      ITENS.gIBSUF_pIBSUF          := TONUMERO(REG.gIBSUF_pIBSUF);
      ITENS.gIBSUF_vIBSUF          := TONUMERO(REG.gIBSUF_vIBSUF, ITENS.QCOM);
      ITENS.gIBSMun_pIBSMun        := TONUMERO(REG.gIBSMun_pIBSMun);
      ITENS.gIBSMun_vIBSMun        := TONUMERO(REG.gIBSMun_vIBSMun, ITENS.QCOM);
      ITENS.gIBSMun_gRed_pRedAliq  := TONUMERO(REG.gIBSMun_gRed_pRedAliq);
      ITENS.gIBSMun_gRed_pAliqEfet := TONUMERO(REG.gIBSMun_gRed_pAliqEfet);
      ITENS.gCBS_pCBS              := TONUMERO(REG.gCBS_pCBS);
      ITENS.gCBS_vCBS              := TONUMERO(REG.gCBS_vCBS, ITENS.QCOM);
      ITENS.TAGICMS60              := 'N';
      IF REG.TAGICMS60 IS NOT NULL THEN
        ITENS.TAGICMS60 := 'S';
      END IF;

      ITENS.NLOTE  := NULL;
      ITENS.QTLOTE := NULL;
      ITENS.DFAB   := NULL;
      ITENS.DVAL   := NULL;
      ITENS.CAGREG := NULL;
      IF ((ITENS.CODPROD > 0) AND (USALOTE = 'S')) THEN
        FOR LOTE IN (SELECT RASTRO.NLOTE,
                            RASTRO.QTLOTE,
                            RASTRO.DFAB,
                            RASTRO.DVAL,
                            RASTRO.CAGREG
                       FROM XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                                     '/rastro' PASSING REG.RASTREIO COLUMNS
                                     NLOTE varchar2(20) PATH
                                     '/rastro/nLote/text()',
                                     QTLOTE varchar2(20) PATH
                                     '/rastro/qLote/text()',
                                     DFAB varchar2(10) PATH
                                     '/rastro/dFab/text()',
                                     DVAL varchar2(10) PATH
                                     '/rastro/dVal/text()',
                                     CAGREG varchar2(20) PATH
                                     '/rastro/cAgreg/text()') RASTRO) LOOP
          RINCLUIR     := 0;
          ITENS.NLOTE  := LOTE.NLOTE;
          ITENS.QTLOTE := TONUMERO(LOTE.QTLOTE);
          ITENS.DFAB   := TODATA(LOTE.DFAB);
          ITENS.DVAL   := TODATA(LOTE.DVAL);
          ITENS.CAGREG := LOTE.CAGREG;
          PIPE ROW(ITENS);
        END LOOP;
      END IF;

      IF RINCLUIR = 1 THEN
        PIPE ROW(ITENS);
      END IF;
    END LOOP;

    RETURN;
  END LER_ITENS;
END PKG_XML;