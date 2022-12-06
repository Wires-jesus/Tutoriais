CREATE OR REPLACE PACKAGE BODY PKG_TRIBUTACAO IS

  --HIS.03069.2016 -------------------------------------------------------------------
  FUNCTION BUSCAR_BONIFICACAO(pCodBNF IN NUMBER) RETURN T_BONIFICACAO IS
    R_BONIFICACAO T_BONIFICACAO;
  BEGIN
    SELECT PCTIPOBONIFIC.CODBNF,
           PCTIPOBONIFIC.CALCULAIPI
      INTO R_BONIFICACAO.CODBNF,
           R_BONIFICACAO.CALCULAIPI
      FROM PCTIPOBONIFIC
     WHERE CODBNF = pCodBNF;
     RETURN R_BONIFICACAO;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
  END;

  ------------------------------------------------------------------------------------
  FUNCTION BUSCAR_REGIAO(pNumRegiao IN NUMBER) RETURN T_REGIAO IS
    R_REGIAO T_REGIAO;
  BEGIN
    SELECT PCREGIAO.NUMREGIAO,
           PCREGIAO.NUMREGIAO
      INTO R_REGIAO.NumRegiao,
           R_REGIAO.Regiao
      FROM PCREGIAO
     WHERE NUMREGIAO = pNumRegiao;
    RETURN R_REGIAO;
  END;

  ------------------------------------------------------------------------------------
  FUNCTION BUSCAR_REGIAO_CLIENTE(Imposto T_IMPOSTO, pOrigemPedido IN varchar2 DEFAULT 'T') RETURN NUMBER IS
    vnnumregiao PCREGIAO.Numregiao%TYPE;
  BEGIN
    vnnumregiao := Imposto.Cliente.numregiao;

    if (Imposto.Parametros132.UtilizaTribEndEnt = 'S') AND
       (Imposto.EnderecoEntrega.NumRegiao > 0)
    THEN
      vnnumregiao := Imposto.EnderecoEntrega.NUMREGIAO;
    END IF;

    IF pOrigemPedido in ('B', 'R') THEN
      IF Imposto.Filial.UF = Imposto.Cliente.estent THEN
        IF (Imposto.Filial.UsaRegiaoFilialVendaEstadual = 'S') AND
           (Imposto.Filial.NumRegiaoPadrao > 0) THEN
          vnnumregiao := Imposto.Filial.NumRegiaoPadrao;
        END IF;
      ELSE
        IF (Imposto.Filial.UsaRegiaoFilialVendaInter = 'S') AND
           (Imposto.Filial.NumRegiaoPadraoInter > 0) THEN
          vnnumregiao := Imposto.Filial.NumRegiaoPadraoInter;
        END IF;
      END IF;
    END IF;

    IF vnnumregiao = 0 THEN
      vnnumregiao := Imposto.Cliente.numregiao;
    END IF;

    RETURN vnnumregiao;

  END;

  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_PRACA(pCodPraca IN NUMBER) RETURN T_PRACA IS
    R_PRACA     T_PRACA;
    vnNumRegiao NUMBER;
  BEGIN
    SELECT PCPRACA.CODPRACA,
           PCPRACA.PRACA,
           PCPRACA.NUMREGIAO
      INTO R_PRACA.CodPraca,
           R_PRACA.Praca,
           vnNumRegiao
      FROM PCPRACA
     WHERE CODPRACA = pCodPraca;

    R_PRACA.Regiao := BUSCAR_REGIAO(vnNumRegiao);
    RETURN R_PRACA;
  END;

  ------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_CNAE(pCodCNAE IN VARCHAR2) RETURN T_CNAE IS
    R_CNAE T_CNAE;

  BEGIN
    BEGIN
      SELECT PCCNAE.CODCNAE,
             PCCNAE.MARGEMMVA,
             PCCNAE.PERCARGATRIBMEDIA
        INTO R_CNAE.CODCNAE,
             R_CNAE.MARGEMMVA,
             R_CNAE.PERCARGATRIBMEDIA
        FROM PCCNAE
       WHERE CODCNAE = pCodCNAE;
    EXCEPTION
      WHEN OTHERS THEN
        R_CNAE.CODCNAE           := 0;
        R_CNAE.MARGEMMVA         := 0;
        R_CNAE.PERCARGATRIBMEDIA := 0;
    END;

    RETURN R_CNAE;
  END;

  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_PLANO_PAGTO(pCodPlPag IN NUMBER) RETURN T_PLANO_PAGAMENTO IS
    R_PLANO_PAGAMENTO T_PLANO_PAGAMENTO;
  BEGIN
    BEGIN
      SELECT PCPLPAG.CODPLPAG,
         PCPLPAG.DESCRICAO,
         PCPLPAG.NUMPR,
         PCPLPAG.NUMDIAS
      INTO R_PLANO_PAGAMENTO.CodPlPag,
         R_PLANO_PAGAMENTO.Descricao,
         R_PLANO_PAGAMENTO.NumPR,
         R_PLANO_PAGAMENTO.NumDias
      FROM PCPLPAG
      WHERE CODPLPAG = pCodPlPag;
      RETURN R_PLANO_PAGAMENTO;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
  END;

  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_PRODUTO(pCodProd IN NUMBER) RETURN T_PRODUTO IS
    R_PRODUTO T_PRODUTO;
    vnCodSec  NUMBER;
  BEGIN
    SELECT PCPRODUT.CODPROD,
           PCPRODUT.DESCRICAO,
           PCPRODUT.CODPRODPRINC,
           PCPRODUT.CODCATEGORIA,
           PCPRODUT.CODSUBCATEGORIA,
           PCPRODUT.CODFORNEC,
           PCPRODUT.CODMARCA,
           PCPRODUT.CODSEC,
           PCPRODUT.FRETEESPECIAL,
           NVL(PCPRODUT.PERCIPIVENDA, 0),
           --NVL(PCPRODUT.PERCDIFALIQUOTAS,0),
           NVL(PCPRODUT.PRECOMAXCONSUM, 0),
           PCPRODUT.IMPORTADO,
           NVL(PCPRODUT.VLPAUTAIPIVENDA, 0),
           NVL(PCPRODUT.VLIPIPORKGVENDA, 0),
           NVL(PCPRODUT.PesoBruto, 0),
           NVL(PCPRODUT.PRECOFIXO, 'N'),
           NVL(PCPRODUT.APLICAPERCREDALIQIPI, 'N'),
           NVL(PCPRODUT.VERIFCRAMOATIVCALCST, 'N'),
		       NVL(PCPRODUT.TIPOMERC, 'L'),
           NVL(PCPRODUT.VLIPIPAUTATV10, 0),
           NVL(PCPRODUT.ISENTOSTCOZINHAINDUSTRIAL, 'N')

      INTO R_PRODUTO.CodProd,
           R_PRODUTO.Descricao,
           R_PRODUTO.CodProdPrinc,
           R_PRODUTO.CodCategoria,
           R_PRODUTO.CodSubCategoria,
           R_PRODUTO.CodFornec,
           R_PRODUTO.CodMarca,
           vnCodSec,
           R_PRODUTO.FreteEspecial,
           R_PRODUTO.Percipi,
           --R_PRODUTO.PercDifAliquotas,
           R_PRODUTO.PrecoMaxConsum,
           R_PRODUTO.Importado,
           R_PRODUTO.Vlpautaipi,
           R_PRODUTO.Vlipiporkgvenda,
           R_PRODUTO.PesoBruto,
           R_PRODUTO.PrecoFixo,
           R_PRODUTO.AplicaPercRedAliqIpi,
           R_PRODUTO.VerificRamoAtiviCalcSt,
		       R_PRODUTO.TipoMercadoria,
           R_PRODUTO.VlIpiPautaTV10,
           R_PRODUTO.IsentoSTClienteCozinaInd

      FROM PCPRODUT
     WHERE CODPROD = pCodProd;

    RETURN R_PRODUTO;
  END;

  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_PRODUTO_FILIAL(pCodProd   IN NUMBER,
                                 pCodFilial IN VARCHAR2)
    RETURN T_PRODUTO_FILIAL IS
    R_PRODFILIAL T_PRODUTO_FILIAL;
  BEGIN
    BEGIN
      SELECT NVL(PCPRODFILIAL.CALCULAIPI, 'I'),
             NVL(PCPRODFILIAL.INDESCALARELEVANTE, 'S'),
             NVL(PCPRODFILIAL.PERACRESBASEIPI, 0) --HIS.02641.2017
        INTO R_PRODFILIAL.CalculaIpi,
             R_PRODFILIAL.RELEVANTE,
             R_PRODFILIAL.PerAcresBaseIPI --HIS.02641.2017
        FROM PCPRODFILIAL
       WHERE PCPRODFILIAL.CODPROD = pCodProd
             AND PCPRODFILIAL.CODFILIAL = pCodFilial;
    EXCEPTION
      WHEN OTHERS THEN
        R_PRODFILIAL.CAlculaIpi := 'I';
    END;

    RETURN R_PRODFILIAL;

  END;
  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_EMBALAGEM(pCodProd     IN NUMBER,
                            pCodAuxiliar IN NUMBER,
                            pCodFilial   IN VARCHAR2) RETURN T_EMBALAGEM IS
    R_EMBALAGEM T_EMBALAGEM;

  BEGIN
    BEGIN
      SELECT PCEMBALAGEM.CODAUXILIAR,
             PCEMBALAGEM.CODPROD,
             PCEMBALAGEM.CODFILIAL,
             PCEMBALAGEM.QTUNIT
        INTO R_EMBALAGEM.CODAUXILIAR,
             R_EMBALAGEM.CODPROD,
             R_EMBALAGEM.CODFILIAL,
             R_EMBALAGEM.QTUNIT
        FROM PCEMBALAGEM
       WHERE CODAUXILIAR = pCodAuxiliar
             AND CODPROD = pCodProd
             AND CODFILIAL = pCodFilial;
    EXCEPTION
      WHEN OTHERS THEN
        R_EMBALAGEM.CODAUXILIAR := '';
        R_EMBALAGEM.CODPROD     := 0;
        R_EMBALAGEM.CODFILIAL   := '';
        R_EMBALAGEM.QTUNIT      := 0;
    END;
    RETURN R_EMBALAGEM;
  END;

  ------------------------------------------------------------------------------------
  FUNCTION BUSCAR_TRIBUTACAO(pCodST IN NUMBER) RETURN T_TRIBUTACAO IS
    R_TRIBUTACAO T_TRIBUTACAO;
  BEGIN
    SELECT PCTRIBUT.codst,
           NVL(pctribut.Iva, 0),
           NVL(pctribut.aliqicms1, 0),
           NVL(pctribut.aliqicms2, 0),
           NVL(pctribut.Ivafonte, 0),
           pctribut.aliqicms1fonte, --  NÃO PODE MAIS TER NVL NESSE PONTO!! - VAI TER DIFERENÇA ENTRE NULO E ZERO -
           pctribut.aliqicms2fonte, -- GUILHERME FREITAS - 07/04/2015 - HIS.00587.2015
           NVL(pctribut.pauta, 0),
           NVL(PCTRIBUT.codicmtab, 0),
           NVL(PCTRIBUT.codicmtabpf, 0),
           NVL(PCTRIBUT.perdesccusto, 0),
           NVL(PCTRIBUT.PercBaseRedST, 0),
           PCTRIBUT.PercBaseRedSTFonte, -- HIS.00587.2015
           NVL(PCTRIBUT.mostrarpvendasemst, 'N'),
           NVL(PCTRIBUT.usavalorultentbasest, 'N'),
           NVL(PCTRIBUT.usavalorultentbasest2, 'N'),
           NVL(PCTRIBUT.usapmcbasest, 'N'),
           NVL(PCTRIBUT.tipocalculognre, 'P'),
           NVL(PCTRIBUT.agregaripicalculost, 'N'),
           NVL(PCTRIBUT.usavlultentmediobasest, 'N'),
           NVL(PCTRIBUT.percbasestrj, 0),
           NVL(PCTRIBUT.UtilizaPercBaseredPF, 'N'),
           NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
           NVL(PCTRIBUT.Percredpvendasimplesnac, 0),
           NVL(PCTRIBUT.IsentNumEmpenho, 'N'),
           NVL(PCTRIBUT.PERCDESCPIS, 0),
           NVL(PCTRIBUT.PERCDESCCOFINS, 0),
           NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
           NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
           NVL(PCTRIBUT.Usaisencaoicmsvp, 'S'),
           NVL(PCTRIBUT.BNFNAOCALCULAICMS, 'N'),
           NVL(PCTRIBUT.ALTERAFATORAJUSTEIVASN, 'N'),
           NVL(PCTRIBUT.Ivatransf, 0),
           NVL(PCTRIBUT.Aliqicms1transf, 0),
           NVL(PCTRIBUT.Aliqicms2transf, 0),
           NVL(PCTRIBUT.Pautatransf, 0),
           NVL(PCTRIBUT.Percbaseredsttransf, 0),
           NVL(PCTRIBUT.mostrarpvendasemIPI, 'N'),
           NVL(PCTRIBUT.compararpautacomst, 'N'),
           NVL(PCTRIBUT.UsaValorultEntbaseSTFonte, 'N'),
           NVL(PCTRIBUT.UsaValorSTFonte, 'N'),
           NVL(AGREGASUFRAMAST2, 'N') AGREGASUFRAMAST2,
           NVL(AGREGAICMSISENCAOST2, 'N') AGREGAICMSISENCAOST2,
           NVL(AGREGAPISCOFINSST2, 'N') AGREGAPISCOFINSST2,
           NVL(AGREGAPISCOFINSST1, 'N') AGREGAPISCOFINSST1,
           NVL(AGREGAICMSISENCAOST1, 'N') AGREGAICMSISENCAOST1,
           NVL(AGREGASUFRAMAST1, 'N') AGREGASUFRAMAST1,
           NVL(AGREGADESCST1, 'N') AGREGADESCST1,
           NVL(RIOLOGISENTOST, 'N') RIOLOGISENTOST,
           NVL(TV9ISENTOST, 'N') TV9ISENTOST,
           -----
           NVL(USABASEICMSREDUZIDA, 'N') USABASEICMSREDUZIDA,
           NVL(ZERARBASEICMSORGPUBSUFRAMA, 'N') ZERARBASEICMSORGPUBSUFRAMA,
           NVL(PERCBASERED, 0) PERCBASERED,
           NVL(PERCBASEREDCONSUMIDOR, 0) PERCBASEREDCONSUMIDOR,
           PERBASEREDNRPA,
           PERBASEREDSIMPLESNAC,
           NVL(PERCBASEREDTRANFSAID, 0) PERCBASEREDTRANFSAID,
           PCTRIBUT.IVATRANSFVIRT,
           PCTRIBUT.ALIQICMS1TRANSFVIRT,
           PCTRIBUT.ALIQICMS2TRANSFVIRT,
           PCTRIBUT.PAUTATRANSFVIRT,
           PCTRIBUT.PERCBASEREDSTTRANSFVIRT,
           PCTRIBUT.CODICMTRANSFVIRT,
           PCTRIBUT.SITTRIBUTTRANSFVIRT,
           PCTRIBUT.SITTRIBUTTRANSVFVIRTENT,
           PCTRIBUT.PERDIFERENCIALTRANSFVIRT,
           PCTRIBUT.PERBASEREDTRANSFVIRTENT,
           PCTRIBUT.PERCBASEREDTRANFVIRTSAID,
           NVL(PCTRIBUT.CALCSTTRANSF, 'S'),
           PCTRIBUT.PERCBASEREDST2TRANSF,
           PCTRIBUT.PERCBASEREDST2TRANSFVIRT,
           PCTRIBUT.INDICECOMPBASESTMT,
           PCTRIBUT.INDICECOMPBASESTMG,
           PCTRIBUT.PERCREDBCSTCLISN,
           NVL(PCTRIBUT.CALCMEDIAPONDSTMG, 'N'),
           NVL(PCTRIBUT.CALCULASTMT, 'S'),
           NVL(PCTRIBUT.UTILIZAMOTORCALCULO, 'N'),
           PCTRIBUT.FORMULAPVENDA,
           PCTRIBUT.FORMULAPVENDATRANSF,
           PCTRIBUT.FORMULAPVENDATRANSFVIRT,
           PCTRIBUT.SITTRIBUT_MC,
           PCTRIBUT.ALIQICMS2_MC,
           PCTRIBUT.IVA_MC,
           NVL(PCTRIBUT.PERCBASEREDST_MC,100),
           NVL(PCTRIBUT.PERCBASERED_MC,100),
           PCTRIBUT.CODICM_MC,
           PCTRIBUT.PAUTA_MC,
           PCTRIBUT.ALIQICMS1_MC,
           NVL(PCTRIBUT.BNFNAOCALCULAICMSTV14, 'N'),
           NVL(ALIQICMSFECP, 0),
           NVL(PCTRIBUT.PERACRESCIMOFUNCEP, 0) PERACRESCIMOFUNCEP,
           NVL(pctribut.vlpautaicmsinterest, 0) ,
           NVL(pctribut.vlpautaicmsest, 0),
           NVL(PCTRIBUT.TIPOCALCULOGNRETRANSFTAB, 'P')
      INTO R_TRIBUTACAO.CodST,
           R_TRIBUTACAO.Iva,
           R_TRIBUTACAO.aliqicms1,
           R_TRIBUTACAO.aliqicms2,
           R_TRIBUTACAO.Ivafonte,
           R_TRIBUTACAO.aliqicms1fonte,
           R_TRIBUTACAO.aliqicms2fonte,
           R_TRIBUTACAO.pauta,
           R_TRIBUTACAO.codicmtab,
           R_TRIBUTACAO.codicmtabpf,
           R_TRIBUTACAO.perdesccusto,
           R_TRIBUTACAO.PercBaseRedST,
           R_TRIBUTACAO.PercBaseRedSTFonte,
           R_TRIBUTACAO.mostrarpvendasemst,
           R_TRIBUTACAO.usavalorultentbasest,
           R_TRIBUTACAO.usavalorultentbasest2,
           R_TRIBUTACAO.usapmcbasest,
           R_TRIBUTACAO.tipocalculognre,
           R_TRIBUTACAO.agregaripicalculost,
           R_TRIBUTACAO.usavlultentmediobasest,
           R_TRIBUTACAO.percbasestrj,
           R_TRIBUTACAO.UtilizaPercBaseredPF,
           R_TRIBUTACAO.PERCDIFALIQUOTAS,
           R_TRIBUTACAO.PERCREDPVENDASIMPLESNAC,
           R_TRIBUTACAO.IsentNumEmpenho,
           R_TRIBUTACAO.PercDescPIS,
           R_TRIBUTACAO.PercDescCOFINS,
           R_TRIBUTACAO.PerDescSUFRAMA,
           R_TRIBUTACAO.PerDescICMIsencao,
           R_TRIBUTACAO.UsaIsencaoIcmsVP,
           R_TRIBUTACAO.BNFNAOCALCULAICMS,
           R_TRIBUTACAO.AlteraFatorAjusteIVASN,
           R_TRIBUTACAO.IVATransf,
           R_TRIBUTACAO.Aliqicms1Transf,
           R_TRIBUTACAO.Aliqicms2Transf,
           R_TRIBUTACAO.PautaTransf,
           R_TRIBUTACAO.PercBaseRedSTTransf,
           R_TRIBUTACAO.mostrarpvendasemipi,
           R_TRIBUTACAO.compararpautacomst,
           R_TRIBUTACAO.UsaValorultEntbaseSTFonte,
           R_TRIBUTACAO.UsaValorStFonte,
           R_TRIBUTACAO.AGREGASUFRAMAST2,
           R_TRIBUTACAO.AGREGAICMSISENCAOST2,
           R_TRIBUTACAO.AGREGAPISCOFINSST2,
           R_TRIBUTACAO.AGREGAPISCOFINSST1,
           R_TRIBUTACAO.AGREGAICMSISENCAOST1,
           R_TRIBUTACAO.AGREGASUFRAMAST1,
           R_TRIBUTACAO.AgregaDescST1,
           R_TRIBUTACAO.RioLogIsentoST,
           R_TRIBUTACAO.Tv9IsentoSt,
           -----
           R_TRIBUTACAO.USABASEICMSREDUZIDA,
           R_TRIBUTACAO.ZerarBaseIcmsOrgPubSuf,
           R_TRIBUTACAO.PercRedNormal,
           R_TRIBUTACAO.PercRedConsfinal,
           R_TRIBUTACAO.PercRedNormalNrpa,
           R_TRIBUTACAO.PercRedNormalsimplesnac,
           R_TRIBUTACAO.PercBaseRedTransfSaid,
           R_TRIBUTACAO.IvaTransfVirt,
           R_TRIBUTACAO.AliqICMS1TransfVirt,
           R_TRIBUTACAO.AliqICMS2TransfVirt,
           R_TRIBUTACAO.PautaTransfVirt,
           R_TRIBUTACAO.PercBaseRedSTTransfVirt,
           R_TRIBUTACAO.CodICMTransFVirt,
           R_TRIBUTACAO.SitTributTransfVirt,
           R_TRIBUTACAO.SitTributTransvfVirtEnt,
           R_TRIBUTACAO.PerDiferencialTransfVirt,
           R_TRIBUTACAO.PerBaseredTransfVirtEnT,
           R_TRIBUTACAO.PercBaseRedTransfVirtSaid,
           R_TRIBUTACAO.CalcStTransf,
           R_TRIBUTACAO.PercBaseRedST2Transf,
           R_TRIBUTACAO.PercBaseRedST2TransfVirt,
           R_TRIBUTACAO.IndiceCompBaseStMt,
           R_TRIBUTACAO.IndiceCompBaseStMG,
           R_TRIBUTACAO.PercRedBaseStCliSN,
           R_TRIBUTACAO.CalcMediaPondsStMG,
           R_TRIBUTACAO.CALCULASTMT,
           R_TRIBUTACAO.UtilizaMotorCalculo,
           R_TRIBUTACAO.FormulaPVENDA,
           R_TRIBUTACAO.FormulaPVENDATRANSF,
           R_TRIBUTACAO.FormulaPVENDATRANSFVIRT,
           R_TRIBUTACAO.SITTRIBUT_MC,
           R_TRIBUTACAO.ALIQICMS2_MC,
           R_TRIBUTACAO.IVA_MC,
           R_TRIBUTACAO.PERCBASEREDST_MC,
           R_TRIBUTACAO.PERCBASERED_MC,
           R_TRIBUTACAO.CODICM_MC,
           R_TRIBUTACAO.PAUTA_MC,
           R_TRIBUTACAO.ALIQICMS1_MC,
           R_TRIBUTACAO.BNFNAOCALCULAICMSTV14,
           R_TRIBUTACAO.ALIQICMSFECP,
           R_TRIBUTACAO.PercAcrescimoFuncep,
           R_TRIBUTACAO.vlpautaicmsinterest,
           R_TRIBUTACAO.vlpautaicmsest,
		   R_TRIBUTACAO.TipoCalculoGNRETransf
      FROM PCTRIBUT
     WHERE CODST = pCodST;

    RETURN R_TRIBUTACAO;

  END;
  ------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------
FUNCTION BUSCAR_PRECIFICACAO(pCodProd         IN NUMBER,
                               pNumRegiao       IN NUMBER,
                               pconsultardblink IN varchar2 DEFAULT 'N')
    RETURN T_PRECIFICACAO IS
    R_PRECIFICACAO T_PRECIFICACAO;
    vsscript       VARCHAR2(1000);
    v_cursor       SYS_REFCURSOR;
    vbCountDbLink  number := 0;
  BEGIN
    IF (pconsultardblink = 'S') THEN
      BEGIN
        SELECT COUNT(1)
          INTO vbcountdblink
          FROM user_db_links a
         WHERE a.db_link = 'DBLSERVIDOR';
      EXCEPTION
        WHEN OTHERS THEN
          vbcountdblink := 0;
      END;
    END IF;

    vsscript := '
      SELECT NVL(PCTABPR.VlUltEntMes, 0),
             NVL(VLIPI, 0),
             NVL(PCTABPR.PERCDESCSIMPLESNAC, 0),
             NVL(PCTABPR.CALCULARIPI, ''S''),
             PCTABPR.FORMULA,
             NVL(PCTABPR.CALCULARFECPSTVENDA, ''N''),
             NVL(PCTABPR.VLFCPST,''0''),
             NVL(PCTABPR.VLULTENTCONTSEMST, 0)';

    IF (pconsultardblink = 'S') and (vbcountdblink >= 1) THEN
      vsscript := vsscript || ' FROM PCTABPR@DBLSERVIDOR';
    ELSE
      vsscript := vsscript || ' FROM PCTABPR';
    END IF;

    vsscript := vsscript || '
       WHERE CODPROD = :codprod
             AND NUMREGIAO = :numregiao';

    OPEN v_cursor FOR vsscript
      using pCodProd, pNumRegiao;
    FETCH v_cursor
      INTO r_precificacao.vlultentmes,
           r_precificacao.vlipi,
           r_precificacao.percdescsimplesnac,
           r_precificacao.calcularipi,
           R_PRECIFICACAO.FormulaPrecific,
           R_PRECIFICACAO.CALCULARFECPSTVENDA,
           R_PRECIFICACAO.VLFCPST,
           R_PRECIFICACAO.VLULTENTCONTSEMST;
    CLOSE v_cursor;

    RETURN R_PRECIFICACAO;
  END;
  ------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------
  FUNCTION BUSCAR_FILIAL(pCodFilial IN VARCHAR) RETURN T_FILIAL IS
    R_FILIAL T_FILIAL;
  BEGIN
    SELECT PCFILIAL.Codigo,
           PCFILIAL.UF,
           PCFILIAL.UTILIZAVENDAPOREMBALAGEM,
           PCFILIAL.USAREGIAOFILIALVENDAESTADUAL,
           PCFILIAL.NUMREGIAOPADRAO,
           PCFILIAL.USAREGIAOFILIALVENDAINTEREST,
           PCFILIAL.NUMREGIAOBALCAOINTER,
           PCFILIAL.CGC,
           PCFILIAL.CODCLI

      INTO R_FILIAL.CodFilial,
           R_FILIAL.UF,
           R_FILIAL.UtilizaVendaporEmbalagem,
           R_FILIAL.UsaRegiaoFilialVendaEstadual,
           R_FILIAL.NumRegiaoPadrao,
           R_FILIAL.UsaRegiaoFilialVendaInter,
           R_FILIAL.NumRegiaoPadraoInter,
           R_FILIAL.CGC,
           R_FILIAL.CODCLI

      FROM PCFILIAL
     WHERE CODIGO = pCodFilial;

    RETURN R_FILIAL;
  END;
  ------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------
  FUNCTION BUSCAR_ESTOQUE(pCodProd IN NUMBER, pCodFilial IN VARCHAR)
    RETURN T_ESTOQUE IS
    R_ESTOQUE T_ESTOQUE;
  BEGIN
    SELECT NVL(PCEST.VLULTENTCONTSEMST,0) VALORULTENT,
           NVL(PCEST.VLSTULTENT, 0),
           NVL(PCEST.VLSTGUIAULTENT, 0),
           NVL(PCEST.IVAULTENT, 0),
           NVL(PCEST.ALIQICMS1ULTENT, 0),
           NVL(PCEST.ALIQICMS2ULTENT, 0),
           NVL(PCEST.REDBASEIVAULTENT, 0),
           NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
           NVL(PCEST.VLFRETECONHECULTENT, 0),
           NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
           NVL(PCEST.BASEICMSULTENT, 0),
           NVL(PCEST.CUSTONFSEMST, 0),
           NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
           NVL(PCEST.PERCMVAORIGULTENT, 0)
      INTO R_ESTOQUE.VALORULTENT,
           R_ESTOQUE.VLSTULTENT,
           R_ESTOQUE.VLSTGUIAULTENT,
           R_ESTOQUE.IVAULTENT,
           R_ESTOQUE.ALIQICMS1ULTENT,
           R_ESTOQUE.ALIQICMS2ULTENT,
           R_ESTOQUE.REDBASEIVAULTENT,
           R_ESTOQUE.PERCICMSFRETEFOBSTULTENT,
           R_ESTOQUE.VLFRETECONHECULTENT,
           R_ESTOQUE.PERCALIQEXTGUIAULTENT,
           R_ESTOQUE.BASEICMSULTENT,
           R_ESTOQUE.CUSTONFSEMST,
           R_ESTOQUE.CUSTONFSEMSTGUIAULTENT,
           R_ESTOQUE.PERCMVAORIGULTENT
      FROM PCEST
     WHERE CODFILIAL = pCodFilial
           AND CODPROD = pCodProd;

    RETURN R_ESTOQUE;
  END;
  ------------------------------------------------------------------------------------

  -------------------1400 - FATURAMENTO -----------------------------------------------------------------
  FUNCTION BUSCAR_ITEMPEDIDO(pROWID IN varchar, pORIGEM IN VARCHAR) RETURN T_ITEMPEDIDO IS
    R_ITEMPEDIDO T_ITEMPEDIDO;
  BEGIN
    BEGIN
      IF pORIGEM <> 'ITEM_CB' THEN
        SELECT NVL(PCPEDI.VLOUTRASDESP, 0) VLOUTRASDESP,
               NVL(PCPEDI.VLFRETE, 0) VLFRETE,
               NVL(PCPEDI.ST, 0) ST,
               NVL(PCPEDI.VLIPI, 0) VLIPI,
               NVL(PCPEDI.VLFECP, 0) VLFECP,
               NVL(PCPEDI.CODST, 0) CODST
          INTO R_ITEMPEDIDO.VLOUTRASDESP,
               R_ITEMPEDIDO.VLFRETE,
               R_ITEMPEDIDO.ST,
               R_ITEMPEDIDO.VLIPI,
               R_ITEMPEDIDO.VLFECP,
               R_ITEMPEDIDO.CODST
          FROM PCPEDI
         WHERE PCPEDI.ROWID = pROWID;
      ELSE
        SELECT NVL(PCPEDICESTA.VLOUTRAS_RATEIO, 0) VLOUTRASDESP,
               NVL(PCPEDICESTA.VLFRETE_RATEIO, 0) VLFRETE,
               NVL(PCPEDICESTA.ST, 0) ST,
               NVL(PCPEDICESTA.VLIPI, 0) VLIPI,
               NVL(PCPEDICESTA.VLFECP, 0) VLFECP,
               NVL(PCPEDICESTA.CODST, 0) CODST
          INTO R_ITEMPEDIDO.VLOUTRASDESP,
               R_ITEMPEDIDO.VLFRETE,
               R_ITEMPEDIDO.ST,
               R_ITEMPEDIDO.VLIPI,
               R_ITEMPEDIDO.VLFECP,
               R_ITEMPEDIDO.CODST
          FROM PCPEDICESTA
         WHERE PCPEDICESTA.ROWID = pROWID;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        R_ITEMPEDIDO.VLOUTRASDESP := 0;
        R_ITEMPEDIDO.VLFRETE      := 0;
        R_ITEMPEDIDO.ST           := 0;
        R_ITEMPEDIDO.VLIPI        := 0;
        R_ITEMPEDIDO.VLFECP       := 0;
        R_ITEMPEDIDO.CODST        := 0;
    END;

    RETURN R_ITEMPEDIDO;
  END;
  ------------------------------------------------------------------------------------
  FUNCTION BUSCAR_ENDERECO_ENTREGA(pCodEndEnt IN number) RETURN T_ENDERECO_ENTREGA IS
    R_ENDERECO_ENTREGA  T_ENDERECO_ENTREGA;
  BEGIN
    IF pCodEndEnt <= 0 THEN
      RETURN R_ENDERECO_ENTREGA;
    END IF;

    BEGIN
      SELECT A.CODENDENTCLI
            ,NVL(A.NUMREGIAO, 0)
            ,A.ESTENT
        INTO R_ENDERECO_ENTREGA.CODENDENT
            ,R_ENDERECO_ENTREGA.NUMREGIAO
            ,R_ENDERECO_ENTREGA.ESTENT
        FROM PCCLIENTENDENT A
       WHERE A.CODENDENTCLI = pCodEndEnt;
    EXCEPTION
      WHEN OTHERS THEN
        R_ENDERECO_ENTREGA.CODENDENT  := NULL;
        R_ENDERECO_ENTREGA.NUMREGIAO  := NULL;
        R_ENDERECO_ENTREGA.ESTENT     := NULL;
    END;

     RETURN R_ENDERECO_ENTREGA;

  END;
  -------------------------------------------------------------------------------------

/* MEDIA PONDERADA ST DE MG */
FUNCTION BUSCAR_VLBASE_ST_MG(pCodProd IN NUMBER,
						                 pValorBaseAtual IN NUMBER,psCodFilial IN VARCHAR2) RETURN NUMBER IS
  RLINHA PCCONSOLIDAMES%ROWTYPE;
  TYPE CUR_EMP IS REF CURSOR;
  CUR_CONSOLIDA CUR_EMP;
  SQL_SELECT VARCHAR2(2000);
BEGIN
  SQL_SELECT := 'SELECT * FROM PCCONSOLIDAMES WHERE TIPO = ''V'' AND CODIGO = :1 AND CODFILIAL = :3 AND ( ';

  FOR i IN 2..13 LOOP
    IF i = 2 THEN
    SQL_SELECT := SQL_SELECT || '( PCCONSOLIDAMES.MES = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -' || i || ')) ' ||
                     'AND PCCONSOLIDAMES.ANO = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -' || i ||')) )';
    ELSE
    SQL_SELECT := SQL_SELECT || 'OR ( PCCONSOLIDAMES.MES = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -' || i || ')) ' ||
                     '  AND PCCONSOLIDAMES.ANO = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -' || i ||')) )';
    END IF;
  END LOOP;

  SQL_SELECT := SQL_SELECT || ') ORDER BY MES DESC';

  OPEN CUR_CONSOLIDA FOR SQL_SELECT USING pCodProd,psCodFilial;

  FETCH cur_consolida INTO rlinha;

  IF CUR_CONSOLIDA%NOTFOUND THEN
    RETURN pValorBaseAtual;
  ELSE
    RETURN rlinha.VLPONDSAIDMES;
  END IF;

  CLOSE CUR_CONSOLIDA;
END;

  -------------------------------------------------------------------------------------
  FUNCTION RETORNA_CODIGO_TRIBUTACAO(pCliente          IN FERRAMENTAS.T_CLIENTE,
                                     pCodProd          IN NUMBER,
                                     psCodFilial       VARCHAR2,
                                     pnNumRegiao       IN NUMBER DEFAULT 0,
                                     psVendaTriangular IN VARCHAR2 DEFAULT 'N',
                                     pCondVenda        IN NUMBER DEFAULT 0,
                                     pCodEndEnt        IN NUMBER DEFAULT 0,
                                     pCodfilialNF      IN VARCHAR2 DEFAULT NULL) RETURN NUMBER IS

    vnnumregiao         pcclient.numregiaocli%TYPE;
    vncodst             pctribut.codst%TYPE;
    vnCodStVendaTriang  PCTRIBUT.CODFIGVENDATRIANGULAR%TYPE;
    Imposto             T_IMPOSTO;
  BEGIN
    Imposto.Parametros132.usaTributacaoPorUF := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF'
                                                                                  ,'99'
                                                                                  ,'N');

    Imposto.Parametros132.UtilizaTribEndEnt  := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZATRIBENDENT'
                                                                                  ,psCodFilial
                                                                                  ,'N');

    Imposto.EnderecoEntrega                  := BUSCAR_ENDERECO_ENTREGA(pCodEndEnt);

    IF pCodfilialNF <> '' THEN
       BEGIN
         SELECT NUMREGIAO
         INTO vnnumregiao
         FROM PCTABPRCLI
         WHERE PCTABPRCLI.CODCLI = pCliente.codcli
               AND  PCTABPRCLI.CODFILIALNF = pCodfilialNF;
       EXCEPTION
        WHEN OTHERS THEN
          vnNumRegiao := pnNumRegiao;
          IF vnnumregiao = 0 THEN
            vnnumregiao := pCliente.NumRegiao;
           END IF;
        END        ;

    ELSE
      vnNumRegiao := pnNumRegiao;
      IF vnnumregiao = 0 THEN
        vnnumregiao := pCliente.NumRegiao;
      END IF;
    END IF;

	IF (pCodEndEnt > 0) AND (Imposto.Parametros132.UtilizaTribEndEnt = 'S') THEN
	  BEGIN
          SELECT NUMREGIAO
          INTO vnnumregiao
        FROM PCCLIENTENDENT
        WHERE CODENDENTCLI = pCodEndEnt
          AND CODCLI =  pCliente.codcli;
        EXCEPTION
          WHEN OTHERS THEN
            vnNumRegiao := pnNumRegiao;
            IF vnnumregiao = 0 THEN
              vnnumregiao := pCliente.NumRegiao;
            END IF;
      END;

	END IF;

    IF Imposto.Parametros132.usaTributacaoPorUF = 'S' THEN
      SELECT pctabtrib.codst
        INTO vncodst
        FROM pctabtrib
       WHERE pctabtrib.codprod = pCodProd
         AND pctabtrib.ufdestino = CASE WHEN (Imposto.Parametros132.UtilizaTribEndEnt = 'S') AND
                                             (Imposto.EnderecoEntrega.EstEnt IS NOT NULL)
                                        THEN
                                          Imposto.EnderecoEntrega.EstEnt

                                        ELSE
                                          pCliente.estent
                                        END
         AND pctabtrib.codfilialnf =  NVL(pCodfilialNF, psCodFilial);

    ELSE
      SELECT pctabpr.codst
        INTO vncodst
        FROM pctabpr
       WHERE pctabpr.codprod = pCodProd
         AND pctabpr.numregiao = vnnumregiao;
    END IF;


    IF psVendaTriangular = 'S' THEN
      BEGIN
        SELECT CODFIGVENDATRIANGULAR
          INTO vnCodStVendaTriang
          FROM PCTRIBUT
         WHERE CODST = vncodst;
      EXCEPTION
        WHEN OTHERS THEN
          vnCodStVendaTriang := 0;
      END;

      IF NVL(vnCodStVendaTriang, 0) > 0 THEN
        RETURN vnCodStVendaTriang;
      END IF;
    END IF;


    RETURN vncodst;
  END;
  ------------------------------------------------------------------------------------
  FUNCTION RETORNA_CODIGO_TRIBUTACAO(pCodCli           IN NUMBER,
                                     pCodProd          IN NUMBER,
                                     psCodFilial       VARCHAR2,
                                     pnNumRegiao       IN NUMBER DEFAULT 0,
                                     psVendaTriangular IN VARCHAR2 DEFAULT 'N',
                                     pCondVenda        IN NUMBER DEFAULT 0,
                                     pCodEndEnt        IN NUMBER DEFAULT 0) RETURN NUMBER IS
    pCliente          FERRAMENTAS.T_CLIENTE;
  BEGIN

    pCliente := FERRAMENTAS.BUSCAR_CLIENTE(pCodCli, psCodFilial);

    RETURN RETORNA_CODIGO_TRIBUTACAO(pCliente,
                                     pCodProd,
                                     psCodFilial,
                                     pnNumRegiao,
                                     psVendaTriangular,
                                     pCondVenda,
                                     pCodEndEnt);
  END;
  ------------------------------------------------------------------------------------
  FUNCTION RETORNA_CODIGO_FORMULA_PVENDA(Imposto IN OUT T_IMPOSTO) RETURN VARCHAR2 IS
    vsFormula  PCFORMULA.CODFORMULA%TYPE;
  BEGIN
    CASE
   WHEN (Imposto.Pedido.Transferencia = 'S')  or
       ((Imposto.Parametros132.UsarTributacaoTransfTV10 = 'S') and
       (Imposto.Pedido.CondVenda = 10) and  (NVL(Imposto.Pedido.TransferenciaVirtual,'N') = 'N')) THEN
       vsFormula := NVL(Imposto.Tributacao.FormulaPVENDATRansf,
                        Imposto.Tributacao.FormulaPVENDA);
     WHEN Imposto.Pedido.TransferenciaVirtual = 'S' THEN
       vsFormula := NVL(NVL(Imposto.Tributacao.FormulaPVENDATRansfVirt,
                            Imposto.Tributacao.FormulaPVENDATRansf),
                        Imposto.Tributacao.FormulaPVENDA) ;
     ELSE
       vsFormula := Imposto.Tributacao.FormulaPVENDA;
    END CASE;
	  /*
	BEGIN

      SELECT *
        INTO Imposto.Tributacao.formula_preco
        FROM PCFORMULATEMP C
       WHERE C.CODFORMULA = VSFORMULA;


      FORMULA.G_SUBSTITUIR_FORMULA := true;
    EXCEPTION
      WHEN OTHERS THEN
        Imposto.Tributacao.formula_preco := NULL;
        FORMULA.G_SUBSTITUIR_FORMULA       := TRUE;
    END;
               */
    RETURN VSFORMULA;
  END;

  PROCEDURE MONTAR_PARAMETROS_MOTOR(Imposto     IN t_IMPOSTO,
                                    pVenda      IN NUMBER,
                                    vtVariaveis IN OUT formula.TBVARIAVEIS) IS
    variavel    formula.RVARIAVEL;
  BEGIN
    IF Imposto.Tributacao.UtilizaMotorCalculo = 'N' THEN
      RETURN;
    end IF;

    variavel.Nome         := '[PTABELASEMIMPOSTO1]';
    variavel.Valor        := pVenda;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[CONDVENDA]';
    variavel.Valor        := Imposto.Pedido.CondVenda;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLIPIPAUTATV10TAB]';
    variavel.Valor        := Imposto.Produto.VLIPIPAUTATV10;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLIPIPORKGVENDATAB]';
    variavel.Valor        := Imposto.Produto.VLIPIPORKGVENDA;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PESOBRUTO]';
    variavel.Valor        := Imposto.Produto.PESOBRUTO;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLPAUTAIPIVENDATAB]';
    variavel.Valor        := Imposto.Produto.VLPAUTAIPI;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCIPIVENDATAB]';
    variavel.Valor        := Imposto.Produto.Percipi;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    --variavel.Nome         := '[APLICAPERCREDALIQIPI]';
    --variavel.Valor        := Imposto.Produto.AplicaPercRedAliqIpi;
    --FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCREDALIQIPI]';
    variavel.Valor        := CASE
                               WHEN Imposto.Produto.AplicaPercRedAliqIpi = 'S' THEN
                                 Imposto.Cliente.RamoAtividade.PercRedAliqIpi
                               ELSE
                                 0
                               END;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    --variavel.Nome         := '[PERCIPIVENDA]';
    --variavel.Valor        := vtVariaveis(6).VALOR;
    --FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERACRESBASEIPI]';
    variavel.Valor        := CASE
                               WHEN Imposto.Pedido.CondVenda =10 THEN
                                Imposto.Produto.ProdutoFilial.peracresBaseIPI
                               ELSE
                                 0
                             END;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[UFCLIENTE]';
    variavel.Valor        := Imposto.Cliente.estEnt;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[MARGEMMVA]';
    variavel.Valor        := NVL(Imposto.Cnae.MARGEMMVA, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCARGATRIBMEDIA]';
    variavel.Valor        := NVL(Imposto.Cnae.percargaTribMedia, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[UFFILIAL]';
    variavel.Valor        := Imposto.Filial.uf;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLDESCICMISENCAO]';
    variavel.Valor        := NVL(Imposto.ItemPedido.VLDESCICMISENCAO, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLDESCREDUCAOPIS]';
    variavel.Valor        := NVL(Imposto.ItemPedido.VLDESCREDUCAOPIS    , 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLDESCREDUCAOCOFINS]';
    variavel.Valor        := NVL(Imposto.ItemPedido.VLDESCREDUCAOCOFINS, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLDESCSUFRAMA]';
    variavel.Valor        := NVL(Imposto.ItemPedido.VLDESCSUFRAMA, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[INDICECOMPBASESTMT]';
    variavel.Valor        := NVL(Imposto.Tributacao.IndiceCompBaseStMt, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[INDICECOMPBASESTMG]';
    variavel.Valor        := NVL(Imposto.Tributacao.IndiceCompBaseStMG, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PRECOMAXCONSUM]';
    variavel.Valor        := Imposto.produto.PrecoMaxConsum ;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCBASESTRJ]';
    variavel.valor        := Imposto.Tributacao.PercBasestRJ ;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLDESCONTO]';
    variavel.valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    -- PARA FÓRMULAS DE IPI, NÃO PARAR DE FUNCIONAR
    variavel.Nome         := '[PERCBASEREDST]';
    variavel.Valor        := NVL(Imposto.Tributacao.PERCBASEREDST, 100);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[ALIQICMS1TAB]';
    variavel.Valor        := Imposto.Tributacao.ALIQICMS1;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[ALIQICMS2TAB]';
    variavel.Valor        := Imposto.Tributacao.ALIQICMS2;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[IVATAB]';
    variavel.Valor        := Imposto.Tributacao.iva;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCBASERED]';
    variavel.Valor        := 100;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCBASEREDST2TRANSF]';
    variavel.Valor        := 100;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCREDBCSTCLISN]';
    variavel.Valor        := 100;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLULTENTMES]';
    variavel.Valor        := COALESCE(Imposto.Precificacao.VlUltEntMes, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLULTENT]';
    variavel.Valor        := COALESCE(Imposto.Estoque.VALORULTENT, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[ALIQICMSFECP]';
    variavel.Valor        := COALESCE(Imposto.Tributacao.ALIQICMSFECP, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLFRETE]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLFRETEIPI]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLOUTRASDESP]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    --- VARIÁVEIS COMPRAS
    variavel.Nome         := '[TAXA0]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VLACRESFRETEKG]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCACRESCIMOFRETE]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERFRETE]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[VALORULTENT]';
    variavel.Valor        := COALESCE(imposto.Estoque.CUSTONFSEMST, imposto.Estoque.VALORULTENT, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[CUSTONFSEMST]';
    IF (COALESCE(imposto.Estoque.CUSTONFSEMST,0) > 0 ) THEN
      variavel.Valor      := COALESCE(imposto.Estoque.CUSTONFSEMST, 0);
    ELSE
      variavel.Valor      := COALESCE(imposto.Estoque.VALORULTENT, 0);
    END IF;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERACRESCIMOFUNCEP]';
    variavel.Valor        := Imposto.Tributacao.PercAcrescimoFuncep;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.nome         := '[VLICMSPARTREM]';
    variavel.Valor        := COALESCE(Imposto.ItemPedido.VLICMSPARTREM, 0);
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[CONSUMIDORFINAL]';
    variavel.Valor        := Imposto.Cliente.ConsumidorFinal;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[UFCLIENTE]';
    variavel.Valor        := Imposto.Cliente.EstEnt;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[UFFILIAL]';
    variavel.Valor        := Imposto.Filial.UF;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[CONTRIBUINTE]';
    variavel.Valor        := Imposto.Cliente.Contribuinte;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    -- PARA FÓRMULAS DE IPI, NÃO PARAR DE FUNCIONAR


  END;
  ------------------------------------------------------------------------------------
  FUNCTION RETORNAR_PERC_RED_ICMS(pImposto   IN T_IMPOSTO,
                                  pCondVenda IN NUMBER
                                           )
  RETURN NUMBER IS
    VBPESSOAFISICA    BOOLEAN;

    --Retorno
    VNPERCRED         PCTRIBUT.PERCBASERED%TYPE;
  BEGIN

    vnPercRed := pImposto.Tributacao.PercRedNormal;

    VBPESSOAFISICA := (FERRAMENTAS.VERIFICAR_FJ(pImposto.Cliente.CodCli) =
                       'PESSOA FISICA');

    IF (pImposto.Cliente.ConsumidorFinal = 'S') AND
       (NVL(pImposto.Tributacao.PercRedConsFinal, 0) > 0)
    THEN
      IF (VBPESSOAFISICA) AND (pImposto.Tributacao.UtilizaPercBaseredPF = 'S')
      THEN
        vnPercRed := pImposto.Tributacao.PercRedConsFinal;
      ELSIF (not VBPESSOAFISICA) THEN
        vnPercRed := pImposto.Tributacao.PercRedConsFinal;
      END IF;
    END IF;

    CASE pImposto.Cliente.TipoEmpresa
      WHEN 'NRPA' THEN
        vnPercRed := nvl(pImposto.Tributacao.PercRedNormalNRPA, vnPercRed);
      WHEN 'SN'   THEN
        vnPercRed := nvl(pImposto.Tributacao.PercRedNormalSimplesNac, vnPercRed);
      ELSE
        NULL;
    END CASE;

    IF pCondVenda = 10 THEN
      IF pImposto.Parametros132.UsarTributacaoTransfTV10 = 'S' THEN
        vnPercRed := pImposto.Tributacao.PercBaseRedTransfSaid;
      /*ELSE
        vnPercRed := 0;  */
      END If;
    END IF;

    -- regras que fazer não ter redução da base de icms
    IF pImposto.Cliente.Isentoicms = 'S'
    THEN
      VNPERCRED := 0;
    END IF;

    IF ((pImposto.Cliente.OrgaoPub = 'S') OR
        (pImposto.Cliente.Sulframa IS NOT NULL)) AND
       (pImposto.Tributacao.ZerarBaseIcmsOrgPubSuf = 'S')
    THEN
      vnpercred := 0;
    END IF;

    IF (pImposto.Cliente.Utilizaiesimplificada = 'S') and
       (VBPESSOAFISICA) THEN
      vnpercred := 0;
    END IF;

    IF (pImposto.Tributacao.UtilizaPercBaseredPF = 'N')
    THEN
      if VBPESSOAFISICA THEN
        vnpercred := 0;
      END IF;
    end IF;

    --fim regras red. base icms

    IF NVL(VNPERCRED, 0) <= 0
    THEN
      VNPERCRED := 100;
    END IF;

    RETURN VNPERCRED;
  END;
  ------------------------------------------------------------------------------------
  FUNCTION EH_ISENTOIPI(imposto          IN T_IMPOSTO,
                        pCodProd         IN NUMBER,
                        vnnumregiao      IN pcregiao.numregiao%TYPE,
                        pCondVenda       IN NUMBER,
                        psVendaExportacao IN VARCHAR2,
                        pVendaLocalEstrangeira IN VARCHAR2,
                        pconsultardblink IN VARCHAR2 DEFAULT 'N',
                        pCodBnf          IN NUMBER  DEFAULT 0,
                        pRotinaConsum    IN VARCHAR2 DEFAULT 'T',
                        pcontaordem      IN VARCHAR2 DEFAULT 'N'

                        )
  RETURN varchar2 IS

    vsIsentoIPI varchar2(1);
  BEGIN

    -------- VERIFICA SE REGIÃO DO CLIENTE CÁLCULA IPI (HIS.03398.2014)-----------
    IF imposto.Produto.TipoMercadoria = 'CB' THEN
       vsIsentoIPI := 'S';
    END IF;

    IF (Imposto.Precificacao.CALCULARIPI = 'N') AND (pRotinaConsum <> 'L') THEN
       vsIsentoIPI := 'S';
    END IF;

    if ((Imposto.Parametros132.CalcularIPIVenda = 'N') AND
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'N') THEN
      vsIsentoIPI := 'S';
    END IF;

    ----- VERIFICA SE O CLIENTE É ISENTO DE IPI ---------
    IF vsIsentoIPI IS NULL THEN
      vsIsentoIPI := Imposto.Cliente.isentoIPI;
    END IF;

    IF (((Imposto.Cliente.sulframa IS NOT NULL) AND
       (Imposto.Produto.importado = 'N')) OR
       (Imposto.Cliente.tipoPessoa = 'E')) THEN
      vsIsentoIPI := 'S';
    END IF;

    if pcontaordem = 'S' and pCondVenda = 8 and
       (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_VALIDARPRECOVENDATV8', Imposto.Filial.codfilial, 'N') = 'N') then
       vsIsentoIPI := 'S';
    END IF;

    IF ((Imposto.Cliente.EstEnt = 'EX') OR (psVendaExportacao = 'S')) AND
       (pVendaLocalEstrangeira = 'N')
    THEN
      vsIsentoIPI := 'S';
    END IF;

    IF (Imposto.Parametros132.RetiraIpiPedidoTV8 = 'S') AND
       (pCondVenda = 8) THEN
      vsIsentoIPI := 'S';
    END IF;

    IF (pCodBnf > 0) AND (Imposto.Bonificacao.CALCULAIPI = 'N') THEN -- HIS.03069.2016
        vsIsentoIPI := 'S';
    END IF;

    /* HIS.02938.2017
     *
     * Se o parâmetro "4051 - Calcular IPI no Pedido com  tipo CUPOM FISCAL" estiver marcado "Não" e
     * o pedido foi selecionado tipo documento como cupom fiscal, então sistema não calcula o IPI
     *
     */
    IF (Imposto.Parametros132.CalculAIPICUPOMFISCAL = 'N') AND
       (Imposto.Pedido.TipoDocumento = 'C') THEN
       vsIsentoIPI := 'S';
    END IF;

    RETURN vsIsentoIPI;

  END;


  ------------------------------------------------------------------------------------
  PROCEDURE PROCESSAR_IPI(Imposto                IN OUT T_IMPOSTO,
                          pCondVenda             IN NUMBER,
                          psVendaExportacao      IN VARCHAR2,
                          pVendaLocalEstrangeira IN VARCHAR2,
                          pVenda                 IN NUMBER,
                          pVlIPI                 OUT NUMBER,
                          pBaseIpi               OUT NUMBER,
                          pPercIpi               OUT NUMBER,
                          pNaoArredondar         IN VARCHAR2 DEFAULT 'N') IS

    vnPercIPI pcprodut.percipi%TYPE;

    VnIpiPorKGVenda NUMBER(18, 6);
    VnPesoBruto     NUMBER(18, 6);
    vnPautaIpi      NUMBER(18, 6);
    vnPautaIpiTv10  NUMBER(18, 6);
    -- Local variables here
    vtVariaveis formula.tbVariaveis;
    resultado   formula.tbvariaveis;
    vnPreco         number(18, 6);
    vsFormula   PCFORMULA.CODFORMULA%TYPE;
    VFORMULA    PCFORMULA.FORMULA%TYPE;
    vstemp      VARCHAR2(400);
    variavel    formula.RVARIAVEL;
  BEGIN
    vnPreco := pVenda;

    IF (Imposto.Tributacao.UtilizaMotorCalculo = 'S') THEN

      vsFormula := RETORNA_CODIGO_FORMULA_PVENDA(Imposto);

      MONTAR_PARAMETROS_MOTOR(Imposto,
                              vnPreco,
                              vtVariaveis);

      IF (Imposto.Produto.AplicaPercRedAliqIpi = 'S') THEN
        variavel.Nome         := '[APLICAPERCREDALIQIPI]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);
      END IF;

      if ( Imposto.Produto.percipi > 0 or
           Imposto.Produto.VlPautaIpi > 0 or
           Imposto.Produto.VlIpiPautaTV10 > 0 or
           Imposto.Produto.VlIpiPorKGVenda > 0) then


        VFORMULA := FORMULA.SUBSTITUIFORMULAS(VSFORMULA, RESULTADO);
        VFORMULA := FORMULA.BUSCAVALOR(RESULTADO, 'IPI');


        --Resultado                   := formula.CALCULAR(VFORMULA /*vsFormula*/, vtVariaveis);
        /*pVlIPI                      := formula.BUSCAVALOR(resultado, 'RESULTADO');
        pBaseIpi                    := Formula.BUSCAVALOR(resultado, 'BASE_IPI');
        pPercIpi                    := formula.BUSCAVALOR(resultado, 'PERC_IPI');  */

        VFORMULA                    := FORMULA.BUSCAVALOR(RESULTADO, 'IPI');

        pVlIPI                      := formula.CalcularSubFormula(VFORMULA,
                                                                  vtVariaveis);
        ----------------------------------------------------------------------------------------
        VFORMULA                    := FORMULA.BUSCAVALOR(RESULTADO, 'BASE_IPI');

        pBaseIpi                    := formula.CalcularSubFormula(VFORMULA,
                                                                  vtVariaveis);
        -----------------------------------------------------------------------------------------
        VFORMULA                    := FORMULA.BUSCAVALOR(RESULTADO, 'PERC_IPI');

        pPercIpi                    := formula.CalcularSubFormula(VFORMULA,
                                                                  vtVariaveis);
      else
        pVlIPI                      := 0;
        pBaseIpi                    := 0;
        pPercIpi                    := 0;
      end if;

      --FORMULA.G_SUBSTITUIR_FORMULA := TRUE;

      RETURN;
    end IF;

    --HIS.02641.2017
    IF (Imposto.Pedido.CondVenda = 10) AND
       (Imposto.Produto.ProdutoFilial.peracresBaseIPI > 0) AND
       (vnPreco > 0) THEN
       vnPreco := vnPreco * (1 + (Imposto.Produto.ProdutoFilial.peracresBaseIPI / 100));
    END IF;

    pVlIPI := 0;
    IF (Imposto.Produto.AplicaPercRedAliqIpi = 'S') THEN
      vnPercIpi := Imposto.Produto.percipi * (1 - (Imposto.Cliente.RamoAtividade.PercRedAliqIpi / 100));
    ELSE
      vnPercIPI := Imposto.Produto.percipi;
    END IF;

    IF (NVL(Imposto.Filial.UtilizaVendaporEmbalagem, 'N') = 'S') AND
       (Imposto.Embalagem.QTUNIT > 0) THEN
      VnIpiPorKGVenda := Imposto.Produto.VlIpiPorKGVenda * Imposto.Embalagem.QTUNIT;
      VnPesoBruto     := Imposto.Produto.PesoBruto;
      vnPautaIpi      := Imposto.Produto.VlPautaIpi * Imposto.Embalagem.QTUNIT;
      vnPautaIpiTv10  := Imposto.Produto.VlIpiPautaTV10 * Imposto.Embalagem.QTUNIT;
    ELSE
      VnIpiPorKGVenda := Imposto.Produto.VlIpiPorKGVenda;
      VnPesoBruto     := Imposto.Produto.PesoBruto;
      vnPautaIpi      := Imposto.Produto.VlPautaIpi;
      vnPautaIpiTv10  := Imposto.Produto.VlIpiPautaTV10;
    END IF;

    if vnpercipi > 0 then
      pVlIPI   := vnPreco * (vnpercipi / 100);
      pBaseIpi := vnPreco;
      pPercIpi := vnpercipi;
    END IF;

    if vnPautaIpi > 0 then
      pVlIPI := vnPautaIpi;
    END IF;

    if VnIpiPorKGVenda > 0 then
      pVlIPI := VnPesoBruto * VnIpiPorKGVenda;
    END IF;

    IF (vnPautaIpiTv10 > 0) AND
       (pCondVenda = 10)
    THEN
      pVlIpi := vnPautaIpiTV10;
    END IF;

  END;

  FUNCTION CALCULAR_IPI(psCodFilial            VARCHAR2,
                        psCodFilialNF          VARCHAR2,
                        psCodFilialRetira      VARCHAR2,
                        pCodCli                IN NUMBER,
                        pCodProd               IN NUMBER,
                        pCodAuxiliar           IN NUMBER,
                        pCondVenda             IN NUMBER,
                        psVendaExportacao      IN VARCHAR2,
                        pVenda                 IN NUMBER,
                        pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                        pOrigemPedido          IN VARCHAR2 DEFAULT 'T',
                        pPtabelaSemImposto     IN NUMBER DEFAULT 0,
                        pRotinaConsum          IN VARCHAR2 DEFAULT 'T',
                        pCodBnf                IN NUMBER  DEFAULT 0,  -- HIS.03069.2016
                        pNaoArredondar         IN VARCHAR2 DEFAULT 'N'
                   ) RETURN TB_CALCULOIPI
   PIPELINED IS
      DADOS_SAIDA T_CALCULOIPI;
   BEGIN
      SELECT NVL(VALORIPI,0), NVL(PERCENTUAL_IPI,0), NVL(BASE_IPI,0)
      INTO DADOS_SAIDA.VALORIPI, DADOS_SAIDA.PERCENTUAL_IPI, DADOS_SAIDA.BASE_IPI
      FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(psCodFilial,
                          psCodFilialNF,
                          psCodFilialRetira,
                          pCodCli,
                          pCodProd,
                          pCodAuxiliar,
                          pCondVenda,
                          psVendaExportacao,
                          pVenda,
                          'N',
                          0,
                          'N',
                          'N',
                          pVendaLocalEstrangeira,
                          pOrigemPedido,
                          pPtabelaSemImposto,
                          pRotinaConsum,
                          pCodBnf,  -- HIS.03069.2016
                          pNaoArredondar
                          ));

      PIPE ROW(DADOS_SAIDA);

      RETURN;

   END;


  FUNCTION CALCULAR_IPI(psCodFilial            VARCHAR2,
                        psCodFilialNF          VARCHAR2,
                        psCodFilialRetira      VARCHAR2,
                        pCodCli                IN NUMBER,
                        pCodProd               IN NUMBER,
                        pCodAuxiliar           IN NUMBER,
                        pCondVenda             IN NUMBER,
                        psVendaExportacao      IN VARCHAR2,
                        pVenda                 IN NUMBER,
                        pVendaTriangular       IN VARCHAR2,
                        pCodEndEnt             IN NUMBER,
                        pTransferencia         IN VARCHAR2,
                        pTransferenciaVirtual  IN VARCHAR2,
                        pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                        pOrigemPedido          IN VARCHAR2 DEFAULT 'T',
                        pPtabelaSemImposto     IN NUMBER   DEFAULT 0,
                        pRotinaConsum          IN VARCHAR2 DEFAULT 'T',
                        pCodBnf                IN NUMBER   DEFAULT 0,  -- HIS.03069.2016
                        pNaoArredondar         IN VARCHAR2 DEFAULT 'N',
                        pTipoDocumento         IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                        pconsultardblink       IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
                        pcontaordem            IN VARCHAR2 DEFAULT 'N', -- Conta e ordem
						pCodst                   IN NUMBER   DEFAULT 0
                   ) RETURN TB_CALCULOIPI
    PIPELINED IS
    DADOS_SAIDA T_CALCULOIPI;
    Imposto T_IMPOSTO;
    vsIsentoIPI pcclient.isentoipi%TYPE;
    pVlIPI      NUMBER(18, 6);
    vnnumregiao pcregiao.numregiao%TYPE;
    vnPreco     NUMBER(18, 6);
    vsCodFilial VARCHAR2(10);
    vncodst     number(10);
    pBaseIpi    NUMBER(18,6);
    pPercIpi    NUMBER(18,6);
  BEGIN

    Imposto.Parametros132.ValidarIpiPor := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDARIPIPOR'
                                                                             ,'99'
                                                                             ,'V');

    Imposto.Parametros132.CalcularIPIVenda   := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_CALCULARIPIVENDA'
                                                                                  ,CASE
                                                                                    Imposto.Parametros132.ValidarIpiPor
                                                                                     WHEN 'V' THEN
                                                                                      psCodFilial
                                                                                     WHEN 'N' THEN
                                                                                      NVL(psCodFilialNF
                                                                                         ,psCodFilial)
                                                                                   END
                                                                                  ,'N');
    Imposto.Parametros132.RetiraIpiPedidoTV8 := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('RETIRAIPIPEDIDOTV8'
                                                                                  ,'99'
                                                                                  ,'N');

    Imposto.Parametros132.ConsideraPrecoSemDescCalcIpi :=  FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONSIDERAPSDCALCIPI'
                                                                                              ,psCodFilial
                                                                                              ,'N');

    Imposto.Parametros132.CALCULAIPICUPOMFISCAL := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCULAIPICUPOMFISCAL' ,psCodFilial ,'S');

    Imposto.Produto               := BUSCAR_PRODUTO(pCODPROD);

    Imposto.Produto.ProdutoFilial := BUSCAR_PRODUTO_FILIAL(pCODPROD
                                                          ,CASE
                                                            Imposto.Parametros132.ValidarIpiPor
                                                             WHEN 'V' THEN
                                                              psCodFilial
                                                             WHEN 'N' THEN
                                                              NVL(psCodFilialNF
                                                                 ,psCodFilial)
                                                           END);

    Imposto.Cliente               := FERRAMENTAS.BUSCAR_CLIENTE(pCODCli
                                                               ,psCodFilialNF);
    Imposto.Embalagem             := BUSCAR_EMBALAGEM(pCODPROD
                                                     ,pCodAuxiliar
                                                     ,NVL(psCodFilialRetira
                                                         ,psCodFilial));

    Imposto.Filial                := BUSCAR_FILIAL(psCodFilial);

    Imposto.Bonificacao           := BUSCAR_BONIFICACAO(pCodBnf); -- HIS.03069.2016

    Imposto.Parametros132.ConsVlUltEntContSSTPrecific := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONSVLULTENTCONTSSTPRECIFICVENDA',
                                                                                            psCodFilial,
                                                                                            'N');

    -------------- DADOS DE PEDIDO -----------------
    Imposto.Pedido.CondVenda            := pCondVenda;
    Imposto.Pedido.RotinaConsum         := pRotinaConsum;
    Imposto.Pedido.OrigemPedido         := pOrigemPedido;
    Imposto.Pedido.VendaTriangular      := pVendaTriangular;
    Imposto.Pedido.VendaExportacao      := psVendaExportacao;
    Imposto.Pedido.Transferencia        := pTransferencia;
    Imposto.Pedido.TransferenciaVirtual := pTransferenciaVirtual;
    Imposto.Pedido.CodEnderecoEntrega   := pCodEndEnt;
    Imposto.Pedido.TipoDocumento        := pTipoDocumento;
    -------------- DADOS DE PEDIDO -----------------

    -------------- ITEM PEDIDO ---------------------
    Imposto.ItemPedido.VLDESCICMISENCAO := 0;
    Imposto.ItemPedido.VLDESCREDUCAOPIS := 0;
    Imposto.ItemPedido.VLDESCSUFRAMA    := 0;
    -------------- ITEM PEDIDO ---------------------

    vnnumregiao  := BUSCAR_REGIAO_CLIENTE(Imposto, pOrigemPedido);
    Imposto.Cnae := BUSCAR_CNAE(Imposto.Cliente.CodCnae);

    IF ((psCodFilialNF IS NOT NULL) or (Imposto.Cliente.CodFilialNF IS NOT NULL)) AND
       (nvl(pTransferenciaVirtual, 'N') = 'N') THEN -- VEN-8909 // VEN-9237

      vsCodFilial := NVL(psCodFilialNF, Imposto.Cliente.CodFilialNF);
    ELSE
      vsCodFilial := psCodFilial;
    END IF;
	IF (pCodst > 0) THEN
		vncodst := pCodst;
    ELSE 
		vncodst := RETORNA_CODIGO_TRIBUTACAO(Imposto.Cliente
                                        ,pCodProd
                                        ,vsCodFilial
                                        ,vnnumregiao
                                        ,pVendaTriangular
                                        ,pCondVenda
                                        ,pCodEndEnt);
    END IF;												

    Imposto.Tributacao   := BUSCAR_TRIBUTACAO(vncodst);

    Imposto.Estoque      := BUSCAR_ESTOQUE(pCodProd, psCodFilial);

    Imposto.Precificacao := BUSCAR_PRECIFICACAO(pCodProd, vnnumregiao, pconsultardblink);

    Imposto.Estoque.VALORULTENT := COALESCE((CASE WHEN Imposto.Parametros132.ConsVlUltEntContSSTPrecific = 'S' THEN
                                               CASE WHEN nvl(Imposto.Precificacao.VlUltEntContSemSt, 0) = 0 THEN
                                                 Imposto.Estoque.VALORULTENT
                                               ELSE
                                                 Imposto.Precificacao.VlUltEntContSemSt
                                               END
                                              ELSE
                                                Imposto.Estoque.VALORULTENT
                                             END),
                                             0);
    -------------------------------------------

    vnPreco := pVenda;

    IF (Imposto.Parametros132.ConsideraPrecoSemDescCalcIpi = 'S') AND
       (obterprecoutilizadonfe(NVL(psCodFilialNF,
                                   psCodFilial),
                               pCodCli,
                               pCodProd) = 'B') AND
        (pPtabelaSemImposto > 0)
    THEN
      vnPreco := pPtabelaSemImposto;
    END IF;

    PROCESSAR_IPI(Imposto
                 ,pCondVenda
                 ,psVendaExportacao
                 ,pVendaLocalEstrangeira
                 ,vnPreco--pVenda
                 ,pVlIPI
                 ,pBaseIpi
                 ,pPercIpi
                 ,pNaoArredondar);

    if pNaoArredondar = 'N' then
      /* NÃO ESTAVA RESPEITANDO O PARAMETRO DE ARREDONDADAMENTO */
      CASE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOCALCIPI'
                                             ,'99'
                                             ,'PV')
        WHEN 'A2' THEN
          pVlIpi := round(pVlIpi,2);
        WHEN 'PV' THEN
          pVlIpi := round(pVlIpi
                         ,FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA'
                                                            ,'99'
                                                            ,6));
        WHEN 'CT' THEN
          pVlIpi := pVlIpi;
        WHEN 'T2' THEN
          pVlIpi := trunc(pVlIpi,2);
      END CASE;
      /* NÃO ESTAVA RESPEITANDO O PARAMETRO DE ARREDONDADAMENTO */
    end if;

    vsIsentoIPI := EH_ISENTOIPI(Imposto,
                                pCodProd,
                                vnnumregiao,
                                pCondVenda,
                                psVendaExportacao,
                                pVendaLocalEstrangeira,
                                pconsultardblink,
                                pCodBnf,
                                pRotinaConsum,
                                pcontaordem);

    IF vsIsentoIPI = 'S' THEN
      pVlIPI := 0;
    END IF;

    IF pVlIPI = 0 THEN
      pPercIpi := 0;
      pBaseIpi := 0;
    END IF;
    -----FIM VERIFICA SE O CLIENTE É ISENTO DE IPI ---------

	IF (Imposto.Produto.TipoMercadoria = 'CB') THEN
      pVlIPI := 0;
	END IF;


    DADOS_SAIDA.VALORIPI       := pVlIPI;
    DADOS_SAIDA.PERCENTUAL_IPI := pPercIpi;
    DADOS_SAIDA.BASE_IPI       := pBaseIpi;
    PIPE ROW(DADOS_SAIDA);

    RETURN;
  END;

  ------------------------------------------------------------------------------------
  FUNCTION CALCULA_ST_FONTE(pImposto  in T_IMPOSTO)
  RETURN BOOLEAN
  IS
    vbCalcula BOOLEAN;
  BEGIN
    vbCalcula := (pImposto.Cliente.ClienteFonteST = 'S') AND
                 (((pImposto.Tributacao.UsaValorStFonte = 'S') AND
                 pImposto.Tributacao.Aliqicms1Fonte IS NOT NULL AND
                 pImposto.Tributacao.Aliqicms2Fonte IS NOT NULL) OR
                 ((pImposto.Tributacao.Aliqicms1Fonte > 0) OR
                 (pImposto.Tributacao.Aliqicms2Fonte > 0))) AND
                 ((pImposto.Cliente.PessoaFisicaJuridica = 'PESSOA JURIDICA') OR
                 ((pImposto.Cliente.PessoaFisicaJuridica = 'PESSOA FISICA') AND
                 (pImposto.Parametros132.calcstpf = 'S')));
    RETURN vbcalcula;
  END;

  FUNCTION RETORNA_IVA_ST_FONTE(pImposto in T_IMPOSTO,
                                pIva     IN NUMBER) -- iVA QUE JÁ ESTAVA NA VARIÁVeL
  RETURN NUMBER
  IS
    vnIVA  PCTRIBUT.IVAFONTE%TYPE;
  BEGIN
    vnIVA := pIva;
    --Não usa IVA diferenciado então pega o IVAFonte dsa tributção
    IF pImposto.Cliente.UsaivaFonteDiferenciado = 'N' or pImposto.Cliente.IvaFonte is null THEN
      vnIVA := pImposto.Tributacao.IvaFonte;
      /*IF vnIVA = 0 THEN
        vnAliqICMS1 := 0;
        vnAliqICMS2 := 0;
      END IF;*/
    END IF;

    --Usa IVA diferenciado então pega o IVAFonte do cliente
    IF pImposto.Cliente.UsaivaFonteDiferenciado = 'S' and pImposto.Cliente.IvaFonte is not null THEN
      vnIVA := pImposto.Cliente.IvaFonte;
    END IF;

    --Pega p maiot IVAFonte entre o cliente e a tributação
    IF pImposto.Cliente.UsaivaFonteDiferenciado = 'M' and pImposto.Cliente.IvaFonte is not null THEN
      IF pImposto.Cliente.IvaFonte > pImposto.Tributacao.IvaFonte THEN
        vnIVA := pImposto.Cliente.IvaFonte;
      ELSE
        vnIVA := pImposto.Tributacao.IvaFonte;
      END IF;
    END IF;

   RETURN vnIVA;
  END;

  FUNCTION RETORNAR_PERCREDBASE_ST_FONTE(pImposto in T_IMPOSTO,
                                           pCondVenda IN number)
  RETURN NUMBER
  IS
    vnPercentualdeReducaoBaseST number(18,6);
  BEGIN
    vnPercentualdeReducaoBaseST := pImposto.Tributacao.PercBaseRedSTFonte;

    IF (pImposto.cliente.Utilizaiesimplificada = 'S') AND
       (pImposto.Cliente.PessoaFisicaJuridica = 'PESSOA FISICA') AND
       (pImposto.Parametros132.AceitaPFContribuinte = 'S') THEN
      vnPercentualdeReducaoBaseST := 0;
    END IF;

    IF (pImposto.Cliente.Isentoicms = 'S') or (pCondVenda = 7) then
      vnPercentualdeReducaoBaseST := 0;
    END IF;

    IF (pImposto.Cliente.SimplesNacional = 'S') AND
       (nvl(pImposto.Tributacao.PercRedBaseStCliSN, 0) > 0)
    THEN
      vnPercentualdeReducaoBaseST := pimposto.Tributacao.PercRedBaseStCliSN;
    END IF;

    IF NVL(vnPercentualdeReducaoBaseST, 0) = 0 THEN
      vnPercentualdeReducaoBaseST := 100;
    END IF;

    RETURN NVL(vnPercentualdeReducaoBaseST, 100);
  END;

  /*Inicia o processo de calculo de ST*/
  FUNCTION PROCESSAR_ST(pImposto                 IN OUT T_IMPOSTO,
                        pCondVenda               IN NUMBER,
                        psVendaExportacao        IN VARCHAR2,
                        pVendaLocalEstrangeira   IN VARCHAR2,
                        pPvenda                  IN FLOAT,
                        pPerDesconto             IN FLOAT,
                        pItemTV1Bnf              IN VARCHAR2 DEFAULT 'N',
                        pSomenteIVATribut        IN VARCHAR2 DEFAULT 'N',
                        pValorDescPIS_COFINS     IN NUMBER   DEFAULT 0,
                        pValorDescICMS           IN NUMBER   DEFAULT 0,
                        pValorSUFRAMA            IN NUMBER   DEFAULT 0,
                        pRowid                   IN VARCHAR2 DEFAULT NULL,
                        pCalculaIPI              IN VARCHAR2 DEFAULT 'S',
                        pTransferencia           IN VARCHAR2 DEFAULT 'N',
                        pCodPrecoFixo            IN NUMBER   DEFAULT 0,
                        pOrigemPedido            IN VARCHAR2 DEFAULT 'T',
                        pTransferenciaVirtual    IN VARCHAR2 DEFAULT 'N',
                        pPtabelaSemImposto       IN NUMBER   DEFAULT 0 ,
                        pRotinaConsum            IN VARCHAR2 DEFAULT 'T',
                        pCodBnf                  IN NUMBER   DEFAULT 0, -- HIS.03069.2016
                        pTransfCNPJMesmoRadical  IN VARCHAR2 DEFAULT 'N', -- HIS.01139.2017
                        pNaoArredondar           IN VARCHAR2 DEFAULT 'N',
                        pconsultardblink         IN VARCHAR2 DEFAULT 'N', --quando usando banco caixa, se vai no servidor ou não
                        vnnumregiao              in number   default '0',
                        pcontaordem              IN VARCHAR2 DEFAULT 'N'
                        )
    RETURN T_CALCULOST
  --PIPELINED
   IS

    DADOS_SAIDA T_CALCULOST;


    vnPercentualdeReducaoBaseST pctribut.percbaseredst%TYPE;
    vnPercentualdeRedSimplesNac pctribut.percredpvendasimplesnac%TYPE;
    --Variáveis para calculo do st
    vnPauta                  NUMBER;
    VnValorUltEnt            NUMBER;
    VnUltEntMes              NUMBER;
    vnPrecoSemImposto        NUMBER;
    vnPreco                  NUMBER;
    vnIPI                    NUMBER;
    vnBaseIPI                NUMBER;
    vnBaseST                 NUMBER;
    vnValorBaseST            NUMBER;
    vnIVA                    NUMBER;
    vnAliqICMS1              NUMBER;
    vnAliqICMS2              NUMBER;
    vnST1                    NUMBER;
    vnST2                    NUMBER;
    vnST                     NUMBER;
    vnSTMinRJ                NUMBER;
    vnPrecoAux               NUMBER;
    vnPSemImposto            NUMBER;
    vbConsiderarIpiAliqicms2 BOOLEAN;
    vnBaseSTXPauta           NUMBER;
    vnPercRedIcms            NUMBER;
    ------ 1400 - FATURAMENTO -------------
    vnVlODespVlFrete NUMBER;
    ---------------------------------------

    vsConsideraPrecoFixoSemImposto varchar2(1);
    vsAplicaDescSimplesPrecoFixo varchar2(1);
    vbPrecoFixo  BOOLEAN;
    vnPercRedBaseST2        NUMBER(18, 8);
    vsCalcMediaPondSTMGFilDest     varchar2(1);
    vsCodFilialCliTransf           PCFILIAL.CODIGO%TYPE;
    vsUSAPMPFBASEST varchar2(1);
    vsPMPF NUMBER(18,6);
    vsSQL VARCHAR2(500);

    --- MOTOR DE CÁLCULO --
    variavel                formula.RVARIAVEL;
    vsFormula               PCFORMULA.CODFORMULA%TYPE;
    vtVariaveis             formula.tbVariaveis;
    resultado               formula.tbvariaveis;
    VFORMULA                PCFORMULA.FORMULA%TYPE;
    VFORMULATEMP                PCFORMULA.FORMULA%TYPE;
    --- MOTOR DE CÁLCULO --
  BEGIN

    IF (pImposto.Tributacao.UsaBaseIcmsReduzida = 'S') or
       (pImposto.Tributacao.UtilizaMotorCalculo = 'S') THEN
      vnPercRedIcms := RETORNAR_PERC_RED_ICMS(pImposto, pCondVenda);
    ELSE
      vnPercRedIcms := 100;
    END IF;


    BEGIN
      SELECT NVL(PCPRECOPROM.CONSIDERAPRECOSEMIMPOSTO, 'N'),
             NVL(PCPRECOPROM.Aplicadescontosimples, 'N')
        INTO vsConsideraPrecoFixoSemImposto,vsAplicaDescSimplesPrecoFixo
        FROM PCPRECOPROM
       WHERE PCPRECOPROM.CODPRECOPROM = pCodPrecoFixo;
    EXCEPTION
      WHEN OTHERS THEN
        vsConsideraPrecoFixoSemImposto := 'N';
        vsAplicaDescSimplesPrecoFixo   := 'N';
    END;

    vbPrecoFixo := ((pImposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0));

    -----VALIDAÇÃO SE O IPI ENTRARÁ NO CALCULO DO ST2------------
    vbConsiderarIpiAliqicms2 := FALSE;
    if (pImposto.Cliente.ConsumidorFinal = 'S') and
       ((pImposto.Produto.Importado = 'S') or
       (pImposto.Produto.Importado = 'D')) and
       (pImposto.Filial.UF <> pImposto.Cliente.EstEnt) and
       (pImposto.Tributacao.AgregarIpiCalculoST = 'S') then
      vbConsiderarIpiAliqicms2 := True;
    END IF;
    -----FIM VALIDAÇÃO SE O IPI ENTRARÁ NO CALCULO DO ST2--------

    --- PERCENTUAL DE REDUÇÃO DO SIMPLES NACIONAL
    IF (NVL(pImposto.Tributacao.PercRedPvendaSimplesnac, 0) = 0) or
       (pImposto.Parametros132.USADESCSIMPLESNAC = 'S') or
       (pImposto.Cliente.SimplesNacional = 'N')  THEN
      vnPercentualdeRedSimplesNac := 100;
    ELSE
      vnPercentualdeRedSimplesNac := pImposto.Tributacao.PercRedPvendaSimplesnac;
    END IF;
    --- FIM PERCENTUAL DE REDUÇÃO DO SIMPLES NACIONAL

     vnPrecoSemImposto := pPvenda;

    --Codigo abaixo: caso as flags de ICMS e PIS/COFINS esteja desmarcadas na 514
    vnBaseIPI := pPvenda;

    /*IF pImposto.Tributacao.AGREGAICMSISENCAOST2 = 'S' THEN
     vnBaseIPI := vnBaseIPI + pValorDescICMS;
    END IF;

    IF pImposto.Tributacao.AGREGAPISCOFINSST2 = 'S' THEN
     vnBaseIPI := vnBaseIPI + pValorDescPIS_COFINS;
    END IF;*/

    IF (pImposto.Parametros132.ConsideraPrecoSemDescCalcIpi = 'S') AND
       (pPtabelaSemImposto > 0)
    THEN
      vnBaseIPI := pPtabelaSemImposto;
    END IF;

     IF (pRowid IS NOT NULL) THEN
      -- Apenas quando for faturamento - 1400
      -- Se for pelo faturamento, retirar o st da pcpedi (pImposto.ItemPedido.ST) e o vnIPI adicionado acima.

        vnBaseIPI := pPvenda - pImposto.ItemPedido.vlipi - pImposto.ItemPedido.ST;
   END IF;

    DADOS_SAIDA.TIPO_ST := 'ST NORMAL';

    --***********CALCULA IPI PARA O PRODUTO ***********--
    IF NVL(pCalculaIPI, 'S') = 'S' and pImposto.Tributacao.UtilizaMotorCalculo = 'N' then
      select VALORIPI
        INTO vnIPI
        FROM TABLE(CALCULAR_IPI(pImposto.Filial.CodFilial
                               ,pImposto.FilialNF.CodFilial
                               ,pImposto.FilialRetira.CodFilial
                               ,pImposto.Cliente.CodCli
                               ,pImposto.Produto.CodProd
                               ,pImposto.Embalagem.CodAuxiliar
                               ,pCondVenda
                               ,psVendaExportacao
                               ,vnBaseIPI
                               ,pImposto.Pedido.VendaTriangular
                               ,pImposto.Pedido.CodEnderecoEntrega
                               ,pImposto.Pedido.Transferencia
                               ,pImposto.Pedido.TransferenciaVirtual
                               ,pImposto.Pedido.VendaLocalEstrangeira
                               ,pOrigemPedido --HIS.00288.2016
                               ,0
                               ,'T'
                               ,pCodBnf
                               ,'N'
                               ,pImposto.Pedido.TipoDocumento
                               ));
    END IF;
    --***********FIM CALCULA IPI PARA O PRODUTO ***********--
    vnIPI := NVL(vnIPI, 0);

    IF (pRowid IS NOT NULL) THEN
     -- Apenas quando for faturamento - 1400
       vnPreco       := vnPrecoSemImposto ;
    ELSE
       vnPreco       := vnPrecoSemImposto +  NVL(vnIPI, 0);
    END IF;

    vnPSemImposto := vnPrecoSemImposto;


    ------ 1400 - FATURAMENTO -------------------------------------
    -- Solicitação: 0.041515.2015
    -- Autor: Deyvid Costa
    -- Descrição: Neste ponto é agregado, após a chamada do "CALCULAR_ST" pela rotina 1400 - FATURAMENTO,
    --            o valor de outras despesas e o valor de frete. As validações abaixo devem compreender
    --            apenas o chamado da PACKAGE, o parâmetro "pRowid", default NULL, é preenchido apenas na PACKAGE FATURAMENTO.
    vnVlODespVlFrete := pImposto.ItemPedido.VLOUTRASDESP +
                        pImposto.ItemPedido.VLFRETE;
    VnUltEntMes      := 0;
    VnValorUltEnt    := 0;
    vnPauta          := 0;
    IF (/*(vnVlODespVlFrete > 0) AND*/ (pRowid IS NOT NULL)) AND (pImposto.Tributacao.UtilizaMotorCalculo = 'N') THEN
      -- Apenas quando for faturamento - 1400
      -- Se for pelo faturamento, retirar o st da pcpedi (pImposto.ItemPedido.ST) e o vnIPI adicionado acima.
      --IF vnIPI > 0 THEN
      --  vnPreco := vnPreco - vnIPI - pImposto.ItemPedido.ST;
      --ELSE
      --  vnPreco := vnPreco - pImposto.ItemPedido.ST;
      --END IF;

      vnIPI          := pImposto.ItemPedido.VLIPI;
      vnPreco := vnPreco - vnIPI - pImposto.ItemPedido.ST - pImposto.ItemPedido.VLFECP;
      vnPSemImposto  := vnPreco;

      -- Comentado, estava adicionando o IPI duas vezes no cálculo
      --IF vbConsiderarIpiAliqicms2 THEN
        -- Cálculo ST2
      --  vnPrecoSemImposto := vnPrecoSemImposto - pImposto.ItemPedido.ST;
      --ELSE
        vnPrecoSemImposto := vnPrecoSemImposto - pImposto.ItemPedido.VLIPI -
                             pImposto.ItemPedido.ST;
      --END IF;

      -- Retira o diferencial de alíquotas da composição da base e ST2, apenas para o preço de venda
      IF pImposto.Tributacao.PercDifAliquotas > 0 THEN
        vnPreco := vnPreco - (((vnPreco - pImposto.ItemPedido.VLIPI) *
                   pImposto.Tributacao.PercDifAliquotas) /
                   (100 + pImposto.Tributacao.PercDifAliquotas));

        vnPrecoSemImposto := vnPrecoSemImposto -
                             ((vnPrecoSemImposto *
                             pImposto.Tributacao.PercDifAliquotas) /
                             (100 + pImposto.Tributacao.PercDifAliquotas));
      END IF;

/*      IF (pImposto.Parametros132.AgregStOutrasDesp = 'S') THEN
        vnVlODespVlFrete := vnVlODespVlFrete - NVL(pImposto.ItemPedido.ST, 0);
      END IF;*/

      -- Anula a composição da baseST se o parâmetro IncluiFreteOutrasDespepBaseST = "N"
      IF (pImposto.Parametros132.IncluiFreteOutrasDespepBaseST = 'N') THEN
        vnVlODespVlFrete := 0;
      END IF;


      -- Adicionando valor de outras despesas e frete
      vnPreco           := vnPreco + vnVlODespVlFrete;
      vnPrecoSemImposto := vnPrecoSemImposto + vnVlODespVlFrete; -- Cálculo ST2
      VnValorUltEnt     := VnValorUltEnt + vnVlODespVlFrete; --
      VnUltEntMes       := VnUltEntMes + vnVlODespVlFrete;
      vnPSemImposto     := vnPSemImposto + vnVlODespVlFrete;
      IF pImposto.Tributacao.pauta > 0 THEN
        vnPauta := vnPauta + vnVlODespVlFrete;
      END IF;
    END IF;
    -- FIM ---- 1400 - FATURAMENTO -----------------------------------------------------------

    --------------------------------------------------------
    --ATENÇÃO!!!
    --Definindo dados para cálculo do ST, semrpe utilizar como
    -- Alíquota 2 a variável "vnAliqICMS2"
    --------------------------------------------------------
    vnIVA                       := pImposto.Tributacao.Iva;
    vnAliqICMS1                 := pImposto.Tributacao.AliqIcms1;
    vnAliqICMS2                 := pImposto.Tributacao.AliqIcms2;
    vnPercentualdeReducaoBaseST := NVL(pImposto.Tributacao.PercBaseRedST, 0);
    vnPauta                     := vnPauta + pImposto.Tributacao.pauta;

    /***************************************************************************/
    IF (pImposto.Cliente.SimplesNacional = 'S') AND
       (nvl(pImposto.Tributacao.PercRedBaseStCliSN, 0) > 0)
    THEN
      vnPercentualdeReducaoBaseST := pimposto.Tributacao.PercRedBaseStCliSN;
    END IF;
    /****************************************************************************/

    if ((pImposto.Parametros132.UsarTributacaoTransfTV10 = 'S') and
       (pCondVenda = 10)) OR (pTransferencia = 'S') then --pTransferencia indica que é 1419 ou 1436
      vnIVA                       := nvl(pImposto.Tributacao.IvaTransf, 0);
      vnPauta                     := nvl(pImposto.Tributacao.PautaTransf, 0);
      vnAliqICMS1                 := nvl(pImposto.Tributacao.Aliqicms1transf
                                        ,0);
      vnAliqICMS2                 := nvl(pImposto.Tributacao.Aliqicms2transf
                                        ,0);
      vnPercentualdeReducaoBaseST := nvl(pImposto.Tributacao.PercBaseRedSTTransf
                                        ,0);
	  pImposto.Tributacao.TipoCalculoGnre := nvl(pImposto.Tributacao.TipoCalculoGNRETransf,'P');

      IF (NVL(pImposto.Tributacao.PercBaseRedST2Transf,0) > 0 ) then
        vnPercRedBaseST2 := NVL(pImposto.Tributacao.PercBaseRedST2Transf,0);
      END IF;
    end if;

    --// HIS.04219.2017, para atender a logistica //--
    IF pImposto.Parametros132.UTILIZARTRIBUTEAJUSTEESTOQUE = 'S' AND
       pRotinaConsum = 'L' THEN
      vnIVA                       := nvl(pImposto.Tributacao.iva_mc, 0);
      vnPauta                     := nvl(pImposto.Tributacao.pauta_mc, 0);
      vnAliqICMS1                 := nvl(pImposto.Tributacao.ALIQICMS1_MC,0);
      vnAliqICMS2                 := nvl(pImposto.Tributacao.ALIQICMS2_MC,0);
      vnPercentualdeReducaoBaseST := nvl(pImposto.Tributacao.PERCBASEREDST_MC,0);
      vnPercRedIcms               := nvl(pImposto.Tributacao.PERCBASERED_MC,0);
    END IF;
    --==============================================--


    if (pTransferenciaVirtual = 'S') then --pTransferencia indica que é transferencia virtual
      if (nvl(pImposto.Tributacao.IvaTransfVirt, pImposto.Tributacao.IVATRANSF) is not null) and
         (nvl(pImposto.Tributacao.Aliqicms1transfVirt, pImposto.Tributacao.ALIQICMS1TRANSF) is not null) and
         (nvl(pImposto.Tributacao.Aliqicms2transfVirt, pImposto.Tributacao.ALIQICMS2TRANSF) is not null) then
        vnIVA                     := nvl(pImposto.Tributacao.IvaTransfVirt, NVL(pImposto.Tributacao.IVATRANSF, pImposto.Tributacao.IVA));
        vnAliqICMS1               := nvl(pImposto.Tributacao.Aliqicms1transfVirt, NVL(pImposto.Tributacao.ALIQICMS1TRANSF, pImposto.Tributacao.ALIQICMS1));
        vnAliqICMS2               := nvl(pImposto.Tributacao.Aliqicms2transfVirt, NVL(pImposto.Tributacao.ALIQICMS2TRANSF, pImposto.Tributacao.ALIQICMS2));
      end if;

      if nvl(pImposto.Tributacao.PautaTransfVirt, pImposto.Tributacao.PAUTATRANSF) is not null then
        vnPauta                   := nvl(pImposto.Tributacao.PautaTransfVirt, NVL(pImposto.Tributacao.PAUTATRANSF, pImposto.Tributacao.PAUTA));
      end if;

      if (nvl(pImposto.Tributacao.PercBaseRedSTTransfVirt, pImposto.Tributacao.PercBaseRedSTTransf) is not null) then
        vnPercentualdeReducaoBaseST  := nvl(pImposto.Tributacao.PercBaseRedSTTransfVirt, NVL(pImposto.Tributacao.PercBaseRedSTTransf, 0));
      end if;

      IF (NVL(pImposto.Tributacao.PercBaseRedST2TransfVirt, pImposto.Tributacao.PercBaseRedST2Transf) is not null) then
        vnPercRedBaseST2 := NVL(pImposto.Tributacao.PercBaseRedST2TransfVirt, pImposto.Tributacao.PercBaseRedST2Transf);
      END IF;

    end if;

    IF COALESCE(vnIVA,0) = 0 AND
       COALESCE(vnAliqICMS1,0) = 0 AND
       COALESCE(vnAliqICMS2,0) = 0
    THEN
      pImposto.Tributacao.PercBasestRJ := 0;
    END IF;


    -----------------------------------------------------------
    --Autor: Rodrigo Santos
    --Solicitação: HIS.00789.2013
    --Data: 09/03/2015
    --Descrição: Para os casos de ST com Pauta, quando a flag
    --"Utiliza comparação entre Valor Pauta e Base ST" estiver marcada
    --o sistema irá comparar a BaseST original com o valor de Pauta
    --e utilizar o maior valor no cálculo.
    IF (vnPauta > 0) and (pImposto.Tributacao.UtilizaMotorCalculo = 'N') THEN
      IF (NVL(pImposto.Filial.UtilizaVendaporEmbalagem, 'N') = 'S') AND
         (pImposto.Embalagem.QTUNIT > 0) AND (pRotinaConsum <> 'I') THEN
        vnBaseSTXPauta := (vnPreco / pImposto.Embalagem.QTUNIT) *
                          (1 + (vnIVA / 100));

        IF (prowid is not null) THEN -- apenas 1400
          vnPauta := (vnPauta / pImposto.Embalagem.QTUNIT) ;
        END IF; -- apenas 1400
      ELSE
        vnBaseSTXPauta := vnPreco * (1 + (vnIVA / 100));
      END IF;

      IF (pImposto.Tributacao.compararpautacomst = 'S') AND
         (vnBaseSTXPauta > vnPauta) THEN
        vnPauta := vnBaseSTXPauta;
      END IF;
    END IF;
    -----------------------------------------------------------

    /*
    Autor: Rafael Braga
    Solicitação: 1337.136716.2016
    Data: 07/12/2016
    Descrição: Acima já é atribuído o percentual de redução de ST padrão.
               Depois, é analisado se existe alguma redução específica
               (transferência, etc); por isso, o else abaixo foi comentado,
               pois caso contrário sempre seria usada apenas a redução do ST
               padrão, ignorando as demais.
    */
    --- PERCENTUAL BASE DE REDUÇÃO DE ST
    IF NVL(vnPercentualdeReducaoBaseST, 0) = 0 THEN
      vnPercentualdeReducaoBaseST := 100;
    /*ELSE
      vnPercentualdeReducaoBaseST := pImposto.Tributacao.PercBaseRedST; {1337.136716.2016}*/
    END IF;
    --- FIM PERCENTUAL BASE DE REDUÇÃO DE ST

    IF NVL(vnPercRedBaseST2, 0) = 0 THEN
      vnPercRedBaseST2 := 100;
    END IF;

    IF (NVL(pImposto.Filial.UtilizaVendaporEmbalagem, 'N') = 'S') AND
       (pImposto.Embalagem.QTUNIT > 0) AND (pRotinaConsum <> 'I')  THEN
        IF (prowid is not null) THEN -- apenas 1400
          vnPauta := vnPauta;
          VnValorUltEnt := VnValorUltEnt + pImposto.Estoque.VALORULTENT;
          VnUltEntMes   := VnUltEntMes + pImposto.Precificacao.VlUltEntMes;
        else
          vnPauta       := vnPauta * pImposto.Embalagem.QTUNIT;
          VnValorUltEnt := VnValorUltEnt + (pImposto.Estoque.VALORULTENT *
                           pImposto.Embalagem.QTUNIT);
          VnUltEntMes   := VnUltEntMes + (pImposto.Precificacao.VlUltEntMes *
                         pImposto.Embalagem.QTUNIT);
        end if;
    ELSE
      VnValorUltEnt := VnValorUltEnt + pImposto.Estoque.VALORULTENT;
      VnUltEntMes   := VnUltEntMes + pImposto.Precificacao.VlUltEntMes;
    END IF;

    IF pImposto.Parametros132.Utilizacontrolemedicamentos = 'S' THEN
      BEGIN
        vsSQL := 'SELECT NVL(USAPMPFBASEST, ''N'')
                    FROM PCTRIBUT
                   WHERE CODST = :CODST';

        EXECUTE IMMEDIATE vsSQL
           INTO vsUSAPMPFBASEST
          USING pImposto.Tributacao.CodST;
      EXCEPTION
        WHEN OTHERS THEN
          vsUSAPMPFBASEST := 'N';
      END;

      IF vsUSAPMPFBASEST = 'S' THEN
        BEGIN
          vsSQL := 'SELECT NVL(PMPF, 0)
                      FROM PCTABMEDABCFARMA
                     WHERE CODPROD = :CODPROD
                       AND UF = :UF';

          EXECUTE IMMEDIATE vsSQL
             INTO vsPMPF
            USING pImposto.Produto.CodProd, pImposto.Cliente.estent;
        EXCEPTION
          WHEN OTHERS THEN
            vsPMPF := 0;
        END;

        IF vsPMPF > 0 THEN
          vnPauta := vsPMPF;
        END IF;
      END IF;
    END IF;

    -----------------------------------------------------------
    --Autor: Rodrigo Santos
    --Solicitação: HIS.01756.2014
    --Data: 30/10/2014
    --Descrição: Implentação de itens bonificados em um pedido TV1.
    -----------------------------------------------------------
    -----------------------------------------------------------
    --Autor: Guilherme Freitas
    --Solicitação: VEN-817
    --Data: 04/12/2017
    --Descrição: Implementação de itens bonificados em um pedido TV14.
    -----------------------------------------------------------
    IF (pItemTV1Bnf in ('F', 'S')) AND (((pImposto.Tributacao.bnfnaocalculaicms = 'S') AND (pCondVenda = 1)) or
                                ((pImposto.Tributacao.BNFNAOCALCULAICMSTV14 = 'S') and (pCondVenda = 14)))
    THEN
      vnAliqICMS2 := 0;
    END IF;

    IF (pSomenteIVATribut = 'N') AND (pImposto.Tributacao.UtilizaMotorCalculo = 'N') THEN
      if (pImposto.Cliente.SimplesNacional = 'S') and
         ((not vbPrecoFixo) or ((vbPrecoFixo) and (vsAplicaDescSimplesPrecoFixo = 'S')))  THEN
        vnIVA := vnIVA * (vnPercentualdeRedSimplesNac / 100);
      END IF;
    END IF;
    --------------------------------------------------------

    --******** Calcula ST NORMAL **************--

    -----------------------------------------------------------
    --Autor: Guilherme Freitas
    --Solicitação: HIS.01014.2015
    --Data: 18/09/2015
    --Descrição: Implementação para agregar na primeira parte do cálculo do ST,
    --           os descontos Comerciais, de PIS/COFINS, SUFRAMA e ICMS de acordo
    --           com a parametrização.
    vnPrecoAux := 0;
    IF pImposto.Tributacao.AGREGASUFRAMAST1 = 'S' THEN
      vnPrecoAux := vnPrecoAux + NVL(pValorSuframa, 0);
    END IF;

    IF pImposto.Tributacao.AGREGAPISCOFINSST1 = 'S' THEN
      vnPrecoAux := vnPrecoAux + NVL(pValorDescPIS_COFINS, 0);
    END IF;

    IF pImposto.Tributacao.AGREGAICMSISENCAOST1 = 'S' THEN
      vnPrecoAux := vnPrecoAux + NVL(pValorDescICMS, 0);
    END IF;

    IF pImposto.Tributacao.AGREGADESCST1 = 'S' THEN
      --Caso o IPI e o ST seja sobre uma base fixa, a rotina deve utiliza o preço de tabela sem impostos
      -- Para evitar divergencias nas ultimas casas do valor do ST
      IF (pPtabelaSemImposto > 0 ) THEN
         vnPSemImposto := pPtabelaSemImposto;
      ELSE

        vnPrecoAux := vnPrecoAux +
                      ((vnPreco + NVL(pValorSuframa, 0) +
                                  NVL(pValorDescPIS_COFINS, 0) +
                                  NVL(pValorDescICMS, 0) - vnIPI) /
                                  (1 - (pPerDesconto/100))) - (vnPreco + NVL(pValorSuframa, 0) +
                                        NVL(pValorDescPIS_COFINS, 0) +
                                        NVL(pValorDescICMS, 0) - vnIPI) ;
      END IF;
    END IF;

    -- end HIS.01014.2015 -- Guilherme Freitas

    /*vnBaseST := ((vnPreco + vnPrecoAux) * (1 + (vnIVA / 100)) *
                (vnPercentualdeReducaoBaseST / 100));  */

    DADOS_SAIDA.BASEFECP := 0;
    DADOS_SAIDA.ALIQFECP := 0;
    DADOS_SAIDA.VLRFECP  := 0;

    IF pImposto.Tributacao.UtilizaMotorCalculo = 'S' THEN

      vnPreco := COALESCE(vnPreco, 0) -
                 COALESCE(pImposto.ItemPedido.vlipi, 0) -
                 COALESCE(pImposto.ItemPedido.ST, 0) -
                 COALESCE(pImposto.ItemPedido.VLFECP, 0);


      vsFormula := RETORNA_CODIGO_FORMULA_PVENDA(PImposto);

      --VFORMULA := FORMULA.SUBSTITUIFORMULAS(VSFORMULA, RESULTADO);
      --VFORMULA := FORMULA.BUSCAVALOR(RESULTADO, 'ST');

      MONTAR_PARAMETROS_MOTOR(PImposto,
                              vnPreco,
                              vtVariaveis);

      /*variavel.Nome  := '[VLDESCONTO]';
      variavel.Valor := ((vnPreco + NVL(pValorSuframa, 0) +
                                  NVL(pValorDescPIS_COFINS, 0) +
                                  NVL(pValorDescICMS, 0) - vnIPI) /
                                  (1 - (pPerDesconto/100))) - (vnPreco + NVL(pValorSuframa, 0) +
                                        NVL(pValorDescPIS_COFINS, 0) +
                                        NVL(pValorDescICMS, 0) - vnIPI);
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis); */

      variavel.Nome  := '[VLDESCONTO]';
      variavel.Valor := pPtabelaSemImposto;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PAUTATAB]';
      variavel.Valor := vnPauta;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASEREDST]';
      variavel.valor := vnPercentualdeReducaoBaseST;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      IF CALCULA_ST_FONTE(pImposto) AND pTransferencia = 'N'
      THEN
        vnAliqICMS1                 := pImposto.Tributacao.AliqIcms1Fonte;
        vnAliqICMS2                 := pImposto.Tributacao.AliqIcms2Fonte;
        vnIVA                       := RETORNA_IVA_ST_FONTE(pImposto, vnIVA);
        vnPercentualdeReducaoBaseST := RETORNAR_PERCREDBASE_ST_FONTE(pImposto, pCondVenda);
        IF NVL(vnPercentualdeReducaoBaseST, 0) = 0 THEN
          vnPercentualdeReducaoBaseST := 100;
        END IF;

        DADOS_SAIDA.TIPO_ST         := 'ST FONTE';
      END IF;

      variavel.Nome  := '[ALIQICMS1TAB]';
      variavel.Valor := vnAliqICMS1;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[ALIQICMS2TAB]';
      variavel.Valor := vnAliqICMS2;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[IVATAB]';
      variavel.Valor := vnIVA;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASEREDST]';
      variavel.valor := vnPercentualdeReducaoBaseST;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASERED]';
      variavel.valor := vnPercRedIcms;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASEREDST2TRANSF]';
      variavel.Valor := vnPercRedBaseST2;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCREDBCSTCLISN]';
      variavel.Valor := vnPercentualdeRedSimplesNac;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[VLULTENTMES]';
      IF pImposto.Precificacao.VlUltEntMes > 0 THEN
        IF ((pImposto.Parametros132.UsarTributacaoTransfTV10 = 'S') AND
           (pImposto.Pedido.CondVenda = 10) AND
           (NVL(pImposto.Pedido.TransferenciaVirtual,'N') <> 'S'))
        THEN
            vsCalcMediaPondSTMGFilDest := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCMEDIAPONDSTMGFILDESTINO',
                                                                            nvl(pImposto.FilialNF.Codfilial,
                                                                                pImposto.Filial.codfilial),
                                                                            'N'));
         BEGIN
          select codigo
            into vsCodFilialCliTransf
            from pcfilial
           where codcli = pImposto.Cliente.CodCli
           and rownum = 1;
         EXCEPTION
           WHEN OTHERS THEN
           vsCodFilialCliTransf := nvl(pImposto.FilialNF.Codfilial,
                                         pImposto.Filial.codfilial);
         END;

          vsCodFilialCliTransf := case
                                    when vsCalcMediaPondSTMGFilDest = 'S' then
                                     vsCodFilialCliTransf
                                    else
                                     nvl(pImposto.FilialNF.Codfilial,
                                         pImposto.Filial.codfilial)
                                  end;

          variavel.Valor := BUSCAR_VLBASE_ST_MG(pImposto.Produto.CodProd,
                                                VnUltEntMes,
                                                vsCodFilialCliTransf);
          ELSE
             variavel.Valor := VnUltEntMes;
        END IF;
      ELSE
        variavel.Valor := VnValorUltEnt;
      END IF;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[VLULTENT]';
      variavel.Valor := VnValorUltEnt;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[PERACRESCIMOFUNCEP]';
      variavel.Valor        := pImposto.Tributacao.PercAcrescimoFuncep;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      if (prowid IS NOT NULL) THEN
        if pImposto.Parametros132.AGREGARFRETEBASEIPI = 'S' THEN
          variavel.Nome         := '[VLFRETEIPI]';
          variavel.Valor        := pImposto.ItemPedido.VLFRETE;
          FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);
        END IF;

		IF pImposto.Parametros132.IncluiFreteOutrasDespepBaseST = 'S' THEN
		  variavel.Nome         := '[VLFRETE]';
		  variavel.Valor        := pImposto.ItemPedido.VLFRETE;
		  FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

		  variavel.Nome         := '[VLOUTRASDESP]';
		  variavel.Valor        := pImposto.ItemPedido.VLOUTRASDESP;
		  FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);
		END IF;
      END IF;

      variavel.Nome  := '[PAUTAICMS]';
      if (pImposto.Filial.UF <> pImposto.Cliente.EstEnt) then
          variavel.Valor := pImposto.Tributacao.vlpautaicmsinterest;
      else
          variavel.Valor := pImposto.Tributacao.vlpautaicmsest;
      end if;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      if (EH_ISENTOIPI(pImposto,
                       pImposto.Produto.CodProd,
                       vnnumregiao,
                       pCondVenda,
                       psVendaExportacao,
                       pVendaLocalEstrangeira,
                       pconsultardblink,
                       pCodBnf,
                       pRotinaConsum,
                       pcontaordem) = 'S') then
        variavel.Nome         := '[VLIPIPORKGVENDATAB]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        variavel.Nome         := '[PESOBRUTO]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        variavel.Nome         := '[VLPAUTAIPIVENDATAB]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        variavel.Nome         := '[PERCIPIVENDATAB]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      end if;

      if (vnAliqICMS1 > 0 or  vnAliqICMS2 > 0 or vnIVA > 0) then

        VFORMULA := FORMULA.SUBSTITUIFORMULAS(VSFORMULA, RESULTADO);

        vformulatemp         := FORMULA.BUSCAVALOR(RESULTADO, 'ST');

        vnST                 := formula.CalcularSubFormula( vformulatemp,vtVariaveis);

        vformulatemp         := FORMULA.BUSCAVALOR(RESULTADO, 'BASE_ST');

        vnBaseST             := FORMULA.CalcularSubFormula(vformulatemp,vtVariaveis);
      else
        vnST                 := 0;
        vnBaseST             := 0;
      end if;

      IF vnST <= 0 THEN
        vnST     := 0;
      END IF;

      if (COALESCE(pImposto.Tributacao.ALIQICMSFECP,0) > 0)
          and (vnBaseST > 0) then
        vformulatemp         := FORMULA.BUSCAVALOR(RESULTADO, 'BASE_FECP');

        DADOS_SAIDA.BASEFECP := COALESCE(FORMULA.CalcularSubFormula( vformulatemp,vtVariaveis),0);

        DADOS_SAIDA.ALIQFECP := COALESCE(pImposto.Tributacao.ALIQICMSFECP,0);

        vformulatemp         := FORMULA.BUSCAVALOR(RESULTADO, 'FECP');

        DADOS_SAIDA.VLRFECP  := COALESCE(FORMULA.CalcularSubFormula(vformulatemp,vtVariaveis),0);
      else
        DADOS_SAIDA.BASEFECP := 0;
        DADOS_SAIDA.ALIQFECP := 0;
        DADOS_SAIDA.VLRFECP  := 0;
      end if;

      --FORMULA.G_SUBSTITUIR_FORMULA := TRUE;

      /*resultado            := FORMULA.CALCULAR(vsFormula, vtVariaveis);
      vnST                 := formula.BUSCAVALOR(resultado, 'ST');
      vnBaseST             := FORMULA.BUSCAVALOR(RESULTADO, 'BASE_ST');

      IF vnST <= 0 THEN
        vnST     := 0;
      END IF;

      DADOS_SAIDA.BASEFECP := coalesce(FORMULA.BUSCAVALOR(RESULTADO, 'BASE_FECP'),0);
      DADOS_SAIDA.ALIQFECP := coalesce(pImposto.Tributacao.ALIQICMSFECP,0);
      DADOS_SAIDA.VLRFECP  := coalesce(FORMULA.BUSCAVALOR(RESULTADO, 'FECP'),0); */

    ELSE
    /* Calcula média ponderada ST de MG */
      IF (pImposto.Tributacao.CalcMediaPondsStMG = 'S') AND
         (pImposto.Filial.UF = 'MG') AND
         ( pTransfCNPJMesmoRadical = 'S' ) AND
         (  (pCondVenda = 10) OR (pTransferencia = 'S') OR (pTransferenciaVirtual = 'S') ) THEN

          vsCalcMediaPondSTMGFilDest := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCMEDIAPONDSTMGFILDESTINO',
                                                                            nvl(pImposto.FilialNF.Codfilial,
                                                                                pImposto.Filial.codfilial),
                                                                            'N'));

           BEGIN
            select codigo
              into vsCodFilialCliTransf
              from pcfilial
             where codcli = pImposto.Cliente.CodCli
             and rownum = 1;
           EXCEPTION
             WHEN OTHERS THEN
             vsCodFilialCliTransf := nvl(pImposto.FilialNF.Codfilial,
                                           pImposto.Filial.codfilial);
           END;

          vsCodFilialCliTransf := case
                                    when vsCalcMediaPondSTMGFilDest = 'S' then
                                     vsCodFilialCliTransf
                                    else
                                     nvl(pImposto.FilialNF.Codfilial,
                                         pImposto.Filial.codfilial)
                                  end;

          vnPSemImposto     := BUSCAR_VLBASE_ST_MG(pImposto.Produto.CodProd,
                                                   vnPSemImposto,
                                                   vsCodFilialCliTransf);

          vnPrecoSemImposto := vnPSemImposto;
      END IF;

      vnPSemImposto  := (vnPSemImposto * (vnPercRedIcms/100)) + vnPrecoAux + vnIpi;

      vnBaseST := (vnPSemImposto * (1 + (vnIVA / 100)) * (vnPercentualdeReducaoBaseST / 100));

      vnSTMinRJ := vnBaseST * (pImposto.Tributacao.PercBasestRJ / 100);
      vnST1     := (vnBaseST * (vnAliqICMS1 / 100));

      /*IF vbconsideraripialiqicms2 = TRUE THEN
        vnST2 := vnPreco;
      ELSE
        vnST2 := vnPrecoSemImposto;
      END IF;*/

      vnST2 := vnPrecoSemImposto * (vnPercRedIcms/100);

      IF vbconsideraripialiqicms2 THEN
        vnST2 := vnST2 + vnIPI;
      END IF;

      IF pImposto.Tributacao.AGREGASUFRAMAST2 = 'S' THEN
        vnST2 := vnST2 + NVL(pValorSUFRAMA, 0);
      END IF;

      IF pImposto.Tributacao.AGREGAPISCOFINSST2 = 'S' THEN
        vnST2 := vnST2 + NVL(pValorDescPIS_COFINS, 0);
      END IF;

      IF pImposto.Tributacao.AGREGAICMSISENCAOST2 = 'S' THEN
        vnST2 := vnST2 + NVL(pValorDescICMS, 0);
      END IF;

      vnST2   := vnST2 * (vnPercRedBaseST2 / 100);

      vnST2 := vnST2 * (vnAliqICMS2 / 100);

      vnST := vnST1 - vnST2;

      if (vnSt < vnSTMinRJ) then
        vnST := vnSTMinRJ;
      END IF;
      --******** FIM Calcula ST NORMAL **************--

      --******** ST de MG *************--
      IF pImposto.Tributacao.UsaVlultentMedioBasest = 'S' THEN

        IF pImposto.Precificacao.VlUltEntMes > 0 THEN
          vnBaseST := ((VnUltEntMes + vnIPI) * (1 + (vnIVA / 100)) *
                      (vnPercentualdeReducaoBaseST / 100));
        ELSE
          vnBaseST := ((VnValorUltEnt + vnIPI) * (1 + (vnIVA / 100)) *
                      (vnPercentualdeReducaoBaseST / 100));
        END IF;

        IF (nvl(pImposto.Tributacao.Pauta, 0) > 0) and
           (NVL(pImposto.Tributacao.IndiceCompBaseStMg, 0) > 0)
        THEN
          IF (nvl(pImposto.Tributacao.Pauta, 0) * (vnPercentualdeReducaoBaseST / 100)) >
             (vnBaseST * (1 + (pImposto.Tributacao.IndiceCompBaseStMg/100)))
          THEN
            vnBaseSt := pImposto.Tributacao.Pauta * (vnPercentualdeReducaoBaseST / 100);
          END IF;
        END IF;

        vnST1 := (vnBaseST * (vnAliqICMS1 / 100));

        IF pImposto.Precificacao.VlUltEntMes > 0 THEN
          vnST2 := (VnUltEntMes) * (vnAliqICMS2 / 100);
        ELSE
          vnST2 := (VnValorUltEnt) * (vnAliqICMS2 / 100);
        END IF;

        vnST := vnST1 - vnST2;
      END IF;
      --********ST de MG*************--

      --******** ST utilizando o valor de ultima entrada  *************--
      IF (pImposto.Tributacao.UsaValorultEntbaseST = 'S') AND
         (pImposto.Filial.UF = pImposto.Cliente.EstEnt) THEN

        vnBaseST := ((VnValorUltEnt + vnIPI) * (1 + (vnIVA / 100)) *
                    (vnPercentualdeReducaoBaseST / 100));

        vnSTMinRJ := vnBaseST * (pImposto.Tributacao.PercBasestRJ / 100);

        vnST1 := (vnBaseST * (vnAliqICMS1 / 100));

        if pImposto.Tributacao.UsaValorultEntbaseST2 = 'S' THEN
          vnST2 := ((VnValorUltEnt) * (vnAliqICMS2 / 100));
        ELSE
          IF vbconsideraripialiqicms2 = TRUE THEN
            vnST2 := ((vnPreco) * (vnAliqICMS2 / 100));
          ELSE
            vnST2 := (vnPrecoSemImposto * (vnAliqICMS2 / 100));
          END IF;
        END IF;

        vnST := vnST1 - vnST2;

        IF vnSt < (vnSTMinRJ) THEN
          vnST := vnSTMinRJ;
        END IF;

      END IF;
      --******** FIM ST utilizando o valor de ultima entrada  *************--

      --********ST com pauta*************--
      IF (vnPauta > 0) AND
         ((pImposto.Tributacao.UsaVlultentMedioBasest = 'N') AND (NVL(pImposto.Tributacao.IndiceCompBaseStMg, 0) <= 0))
      THEN

        vnBaseST := vnPauta * (vnPercentualdeReducaoBaseST / 100);

        vnSTMinRJ := vnBaseST * (pImposto.Tributacao.PercBasestRJ / 100);

        vnST1 := (vnBaseST * (vnAliqICMS1 / 100));

        IF vbconsideraripialiqicms2 = TRUE THEN
          vnST2 := (vnPreco + NVL(pValorDescICMS, 0));
        ELSE
          vnST2 := (vnPrecoSemImposto + NVL(pValorDescICMS, 0));
        END IF;

        IF pImposto.Tributacao.UsaVlultentMedioBasest = 'S' THEN
          IF pImposto.Precificacao.VlUltEntMes > 0 THEN
            vnST2 := (VnUltEntMes);
          ELSE
            vnST2 := (VnValorUltEnt);
          END IF;
        END IF;

        IF pImposto.Tributacao.AGREGASUFRAMAST2 = 'S' THEN
          vnST2 := vnST2 + NVL(pValorSUFRAMA, 0);
        END IF;

        IF pImposto.Tributacao.AGREGAPISCOFINSST2 = 'S' THEN
          vnST2 := vnST2 + NVL(pValorDescPIS_COFINS, 0);
        END IF;

        IF pImposto.Tributacao.AGREGAICMSISENCAOST2 = 'S' THEN
          vnST2 := vnST2 + NVL(pValorDescICMS, 0);
        END IF;

        vnST2 := vnST2 * (vnAliqICMS2 / 100);

        vnST := vnST1 - vnST2;

        if (vnST < vnSTMinRJ) then
          vnST := vnSTMinRJ;
        END IF;
      END IF;
      --********FIM ST com pauta*************--

      --********ST com preço máximo consumidor*************--
      IF (pImposto.Tributacao.UsaPMCBasest = 'S') AND
         (pImposto.produto.PrecoMaxConsum > 0) THEN

        --Base de ST
        vnBaseST := (pImposto.produto.PrecoMaxConsum *
                    (vnPercentualdeReducaoBaseST / 100));

        -- 1º Parte do cálculo
        vnST1 := (vnBaseST * (vnAliqICMS1 / 100));

        -- 2º Parte do cálculo
        vnST2 := (vnPrecoSemImposto * (vnAliqICMS2 / 100));

        --Valor de ST
        vnST := vnST1 - vnST2;
      END IF;
      --********FIM ST com preço máximo consumidor*************--

      --********CALCULA ST FONTE*******************-
      IF CALCULA_ST_FONTE(pImposto) AND
         (pTransferencia = 'N') THEN

        vnBaseST := vnPreco;

        /*
        Autor: Rafael Braga
        Solicitação: 3575.135415.2016
        Data: 30/11/2016
        Descrição: Caso seja ST fonte e esteja recalculando no faturamento, o preço neste
                   ponto está sem IPI, e é necessário somá-lo para que o ST não fique
                   incorreto.
        */
        if (pRowid is not null) then
          vnBaseST := vnPreco + nvl(vnIPI, 0);
        end if;

        if (NVL(vnPercRedIcms, 0) > 0) then
          vnBaseST  := ((vnBaseST - nvl(vnIPI, 0)) * (vnPercRedIcms/100))+ nvl(vnIPI, 0);
        end if;

        IF (pImposto.Tributacao.UsaValorultEntbaseST = 'S') AND
           (pImposto.Filial.UF = pImposto.Cliente.EstEnt) THEN
          vnBaseST := (VnValorUltEnt + vnIPI);
        END IF;

        --PERCENTUAL DE REDUCAO DA BASE DE ST FONTE
        vnPercentualdeReducaoBaseST := RETORNAR_PERCREDBASE_ST_FONTE(pImposto, pCondVenda);

        vnAliqICMS1 := NVL(pImposto.Tributacao.AliqIcms1Fonte, 0);
        vnAliqICMS2 := NVL(pImposto.Tributacao.AliqIcms2Fonte, 0);

        --BUSCAR IVA FONTE
        vnIVA := RETORNA_IVA_ST_FONTE(pImposto, vnIVA);

        if (pImposto.Cliente.SimplesNacional = 'S') and
           (pSomenteIVATribut = 'N') and
           ((not vbPrecoFixo) or ((vbPrecoFixo) and (vsAplicaDescSimplesPrecoFixo = 'S')))  THEN
          vnIVA := vnIVA * (vnPercentualdeRedSimplesNac / 100);
        END IF;

        IF (vnPercentualdeReducaoBaseST > 0) THEN
          vnBaseST := vnBaseST *
                      (vnPercentualdeReducaoBaseST / 100);
        END IF;

        vnBaseST := (vnBaseST * (1 + (vnIVA / 100)));

        IF pImposto.Tributacao.UsaVlultentMedioBasest = 'S' THEN
          IF pImposto.Precificacao.VlUltEntMes > 0 THEN
            vnBaseST := ((VnUltEntMes + vnIPI) * (1 + (vnIVA / 100)) *
                        (vnPercentualdeReducaoBaseST / 100));
          ELSE
            vnBaseST := ((VnValorUltEnt + vnIPI) * (1 + (vnIVA / 100)) *
                        (vnPercentualdeReducaoBaseST / 100));
          END IF;

          IF (nvl(pImposto.Tributacao.Pauta, 0) > 0) and
             (NVL(pImposto.Tributacao.IndiceCompBaseStMg, 0) > 0) THEN
            IF (nvl(pImposto.Tributacao.Pauta, 0) * (vnPercentualdeReducaoBaseST / 100)) >
               (vnBaseST * (1 + (pImposto.Tributacao.IndiceCompBaseStMg/100))) THEN
              vnBaseSt := pImposto.Tributacao.Pauta * (vnPercentualdeReducaoBaseST / 100);
            END IF;
          END IF;
        END IF;

        IF (pImposto.Tributacao.UsaPMCBasest = 'S') AND
           (pImposto.produto.PrecoMaxConsum > 0) THEN
          --Base de ST
        vnBaseST := (pImposto.produto.PrecoMaxConsum *
                    (vnPercentualdeReducaoBaseST / 100));
        END IF;

        vnSTMinRJ := vnBaseST * (pImposto.Tributacao.PercBasestRJ / 100);
        vnST1     := (vnBaseST * (vnAliqICMS1 / 100));

        IF pImposto.Tributacao.UsaValorultEntbaseSTFonte = 'S' THEN
          vnST2 := VnValorUltEnt;
        ELSE
          IF vbconsideraripialiqicms2 = TRUE THEN
            IF (pRowid IS NOT NULL) THEN
              vnST2 := ((vnPreco + vnIPI) * (vnPercRedIcms/100));
            else
              vnST2 := vnPreco * (vnPercRedIcms/100);
            end if;
          ELSE
            vnST2 := vnPrecoSemImposto * (vnPercRedIcms/100);
          END IF;
        END IF;

        IF pImposto.Tributacao.UsaVlultentMedioBasest = 'S' THEN
          IF pImposto.Precificacao.VlUltEntMes > 0 THEN
            vnST2 := VnUltEntMes;
          ELSE
            vnST2 := VnValorUltEnt;
          END IF;
        END IF;

        IF pImposto.Tributacao.AGREGASUFRAMAST2 = 'S' THEN
           vnST2 := vnST2 + NVL(pValorSUFRAMA, 0);
        END IF;

        IF pImposto.Tributacao.AGREGAPISCOFINSST2 = 'S' THEN
          vnST2 := vnST2 + NVL(pValorDescPIS_COFINS, 0);
        END IF;

        IF pImposto.Tributacao.AGREGAICMSISENCAOST2 = 'S' THEN
          vnST2 := vnST2 + NVL(pValorDescICMS, 0);
        END IF;

        vnST2 := vnST2 * (vnAliqICMS2 / 100);

        vnST := vnST1 - vnST2;

        if (vnSt < vnSTMinRJ) then
          vnST := vnSTMinRJ;
        END IF;

        IF pImposto.Tributacao.UsaValorStFonte = 'S' THEN
          IF vnST < 0 THEN
            vnST := 0;
          END IF;
        END IF;
      DADOS_SAIDA.TIPO_ST := 'ST FONTE';
      END IF;
      --********FIM CALCULA ST FONTE***************-

      --********CALCULA ST DO MT**************--
      IF ((pImposto.Cliente.UtilizaCalculoSTMT = 'S' AND
           pImposto.Tributacao.CalculaSTMT = 'S') AND
         (pImposto.Cliente.EstEnt = 'MT')) AND
         ((vnAliqICMS1 <> 0) OR (vnAliqICMS2 <> 0)) THEN

        IF (pRowid IS NOT NULL) THEN
         -- Apenas quando for faturamento - 1400
          vnPreco := vnPreco + NVL(vnIPI, 0);
        END IF;

        IF (NVL(pImposto.FilialNF.UF , pImposto.Filial.UF) = pImposto.Cliente.EstEnt) THEN
          vnST1 := (vnPrecoSemImposto * (vnAliqICMS1 / 100));

          vnValorBaseST := ((vnPreco) * (pImposto.Cnae.MARGEMMVA / 100));

          IF (nvl(pImposto.Tributacao.Pauta, 0) > 0) and
             (NVL(pImposto.Tributacao.IndiceCompBaseStMt, 0) > 0)
          THEN
            IF (nvl(pImposto.Tributacao.Pauta, 0)) >
               (vnValorBaseST * (1 + (pImposto.Tributacao.IndiceCompBaseStMt/100)))
            THEN
              vnValorBaseST := pImposto.Tributacao.Pauta;
            END IF;
          END IF;

          vnST := (vnValorBaseST * (pImposto.cnae.PERCARGATRIBMEDIA / 100));

          vnBaseST := (vnST + vnST1) / (vnAliqICMS1 / 100);
        ELSE

          vnST2 := (vnPrecoSemImposto * (vnAliqICMS2 / 100));

          IF (nvl(pImposto.Tributacao.Pauta, 0) > 0) and
             (NVL(pImposto.Tributacao.IndiceCompBaseStMt, 0) > 0)
          THEN
            IF (nvl(pImposto.Tributacao.Pauta, 0)) >
               (vnPreco * (1 + (pImposto.Tributacao.IndiceCompBaseStMt/100)))
            THEN
              vnPreco := pImposto.Tributacao.Pauta;
            END IF;
          END IF;

          vnST := (vnPreco * (pImposto.cnae.PERCARGATRIBMEDIA / 100));

          vnBaseST := (vnST + vnST2) / (vnAliqICMS1 / 100);
        END IF;
      END IF;
      --********FIM CALCULA ST DO MT**************--

    END IF;

    --Zerando a Base de ST caso as Aliquotas seja zero
    if ((pImposto.Tributacao.pauta = 0) or (vnIVA = 0) or
       (pImposto.produto.PrecoMaxConsum = 0)) and (vnAliqICMS1 = 0) and
       (vnAliqICMS2 = 0) then
      vnBaseST := 0;
    END IF;

    -- ramo de atividade não calcula ST
    IF (pImposto.Produto.VerificRamoAtiviCalcSt = 'S') AND
       (pImposto.Cliente.RamoAtividade.calculaSt = 'N')
    THEN
      vnST      := 0;
      vnBaseST  := 0;
    END IF;

    ----------- 1400 - FATURAMENTO -------------------------------------------
    IF nvl(pRotinaConsum, 'X') <> 'I' THEN
      --Arredondar/Truncar valor de ST
      IF pImposto.Parametros132.tipocalcst = 'T2' THEN
        vnst := TRUNC((vnst) * 100) / 100;
      ELSIF pImposto.Parametros132.tipocalcst = 'A2' THEN
        vnst := ROUND((vnst) * 100) / 100;
      ELSIF pImposto.Parametros132.tipocalcst = 'PV' THEN
        vnst := ROUND(vnst, 6);
      END IF;
    END IF;
    --------------------------------------------------------------------------

    if pNaoArredondar = 'N' then
      /* NÃO ESTAVA RESPEITANDO O PARAMETRO DE ARREDONDADAMENTO */
      CASE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOCALCST'
                                             ,'99'
                                             ,'PV')
          WHEN 'A2' THEN
            vnST := round(vnST,2);
            vnBaseST :=  round(vnBaseST,2);
            DADOS_SAIDA.VLRFECP  := round(DADOS_SAIDA.VLRFECP,2);
            DADOS_SAIDA.BASEFECP := round(DADOS_SAIDA.BASEFECP,2);
          WHEN 'PV' THEN
            vnST := round(vnST
                         ,FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA'
                                                            ,'99'
                                                            ,6));
            vnBaseST := round(vnBaseST

                             ,FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA'
                                                              ,'99'
                                                              ,6));
            DADOS_SAIDA.VLRFECP  := round(DADOS_SAIDA.VLRFECP
                                         ,FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA'
                                                              ,'99'
                                                              ,6));
            DADOS_SAIDA.BASEFECP := round(DADOS_SAIDA.BASEFECP
                                        ,FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA'
                                                              ,'99'
                                                              ,6));
          WHEN 'CT' THEN
            vnST := vnST;
            vnBaseST := vnBaseST;
          WHEN 'T2' THEN
            vnST := trunc(vnST,2);
            vnBaseST := trunc(vnBaseST,2);
            DADOS_SAIDA.VLRFECP  := trunc(DADOS_SAIDA.VLRFECP, 2);
            DADOS_SAIDA.BASEFECP := trunc(DADOS_SAIDA.BASEFECP, 2);
      END CASE;
      /* NÃO ESTAVA RESPEITANDO O PARAMETRO DE ARREDONDADAMENTO */
    end if;

    -------------------------------------------------------------------------
    if vnBaseST = 0 then
      DADOS_SAIDA.TIPO_ST := 'SEM ST';
    end if;

    DADOS_SAIDA.BASEST := nvl(vnBaseST, 0);
    DADOS_SAIDA.ST     := nvl(vnST, 0);
    DADOS_SAIDA.ALIQICMS1 := nvl(vnAliqICMS1,0);
    DADOS_SAIDA.ALIQICMS2 := nvl(vnAliqICMS2,0);
    DADOS_SAIDA.REDUCAO := nvl(vnPercentualdeReducaoBaseST,0);
    DADOS_SAIDA.PAUTA := nvl(vnPauta,0);
    DADOS_SAIDA.IVA := NVL(vnIVA, 0);
	  DADOS_SAIDA.STGNRE := nvl(pImposto.Tributacao.tipocalculognre,'P');
    --    pVendaTributado := vnPreco + NVL(vnST,0) ;
    --PIPE ROW (DADOS_SAIDA);

    RETURN DADOS_SAIDA;

  END;
  
  FUNCTION VerificaPautaProdutUF (pImposto    IN OUT T_IMPOSTO,pCodProd     IN NUMBER, 
  pufentcli in varchar2)
  RETURN T_TRIBUTACAO  
  IS
	v_pauta_pcpautaprodutuf PCPAUTAPRODUTUF.PAUTA%TYPE;
  BEGIN
	BEGIN
		SELECT NVL(PAUTA,0) PAUTA
		  INTO v_pauta_pcpautaprodutuf
		  FROM PCPAUTAPRODUTUF
		 WHERE PCPAUTAPRODUTUF.UF = pufentcli
		   AND PCPAUTAPRODUTUF.CODPROD = pCodProd;
	  EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  v_pauta_pcpautaprodutuf := 0;
	END;
	  IF v_pauta_pcpautaprodutuf <> 0 THEN
		pImposto.Tributacao.PAUTA := v_pauta_pcpautaprodutuf;
		pImposto.Tributacao.PautaTransf := v_pauta_pcpautaprodutuf;
		pImposto.Tributacao.PautaTransfVirt := v_pauta_pcpautaprodutuf;
		pImposto.Tributacao.PAUTA_MC := v_pauta_pcpautaprodutuf;
	  END IF;
	  RETURN pImposto.Tributacao;
  END;
  
  /*Inicia o processo de calculo de ST*/
  FUNCTION CALCULAR_ST(psCodFilial              VARCHAR2,
                       psCodFilialNF            VARCHAR2,
                       psCodFilialRetira        VARCHAR2,
                       pCodCli                  IN NUMBER,
                       pCodPlPag                IN NUMBER,
                       pCodProd                 IN NUMBER,
                       pCodAuxiliar             IN NUMBER,
                       pCondVenda               IN NUMBER,
                       psVendaExportacao        IN VARCHAR2,
                       pPvenda                  IN FLOAT,
                       pPerDesconto             IN FLOAT,
                       pItemTV1Bnf              IN VARCHAR2 DEFAULT 'N',
                       pValorDescPIS_COFINS     IN NUMBER   DEFAULT 0,
                       pValorDescICMS           IN NUMBER   DEFAULT 0,
                       pValorSUFRAMA            IN NUMBER   DEFAULT 0,
                       pROWID                   IN VARCHAR2 DEFAULT NULL,
                       pCalculaIPI              IN VARCHAR2 DEFAULT 'S', --HIS.01188.2013 (verifique história)
                       pTransferencia           IN VARCHAR2 DEFAULT 'N',  --HIS.01188.2013 (verifique história)
                       pOrigemPedido            IN VARCHAR2 DEFAULT 'T',
                       pVendaLocalEstrangeira   IN VARCHAR2 DEFAULT 'N',
                       pCodPrecoFixo            IN NUMBER   DEFAULT 0,
                       pTransferenciaVirtual    IN VARCHAR2 DEFAULT 'N',
                       pPtabelaSemImposto       IN NUMBER   DEFAULT 0,   --HIS.01742.2016
                       pVendaTriangular         IN VARCHAR2 DEFAULT 'N',
                       pRotinaConsum            IN VARCHAR2 DEFAULT 'T',
                       pCodBnf                  IN NUMBER   DEFAULT 0,
                       pCodEndEnt               IN NUMBER   DEFAULT 0,
                       pNaoArredondar           IN VARCHAR2 DEFAULT 'N',
                       pTipoDocumento           IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                       pconsultardblink         IN VARCHAR2 DEFAULT 'N',
                       pcontaordem              IN VARCHAR2 DEFAULT 'N', -- Conta e ordem TV8
                       pValorICMSPartilhaRem    IN NUMBER   DEFAULT 0,
                       pORIGEM                  IN VARCHAR2 DEFAULT 'PA',
					   pCodst                   IN NUMBER   DEFAULT 0
                       )
    RETURN TB_CALCULOST
    PIPELINED IS
    DADOS_SAIDA T_CALCULOST;
    Imposto T_IMPOSTO;
    vnnumregiao pcclient.numregiaocli%TYPE;
    vncodst     pctribut.codst%TYPE;
    vsCodFilial pcfilial.codigo%type;
    vbClienteFonteST boolean;
    vdPtabelaSemImposto NUMBER;
    vTransfCNPJMesmoRadical VARCHAR2(1);
    vrLog pclogimpostos%rowtype;
  BEGIN

    vrLog.Objeto := 'PKG_TRIBUTACAO.CALCULAR_ST';
    vrLog.Descricao :=  'Iniciou function cancular_st, parâmetros da chamada: ' || chr(13) ||
                        'psCodFilial            => ''' || psCodFilial || ''',' || chr(13) ||
                        'psCodFilialNF          => ''' || psCodFilialNF || ''',' || chr(13) ||
                        'psCodFilialRetira      => ''' || psCodFilialRetira || ''',' || chr(13) ||
                        'pCodCli                => '   || pCodCli || ',' || chr(13) ||
                        'pCodPlPag              => '   || pCodPlPag || ',' || chr(13) ||
                        'pCodProd               => '   || pCodProd || ',' || chr(13) ||
                        'pCodAuxiliar           => '   || pCodAuxiliar || ',' || chr(13) ||
                        'pCondVenda             => '   || pCondVenda || ',' || chr(13) ||
                        'psVendaExportacao      => ''' || psVendaExportacao || ''',' || chr(13) ||
                        'pPvenda                => '   || pPvenda || ',' || chr(13) ||
                        'pPerDesconto           => '   || pPerDesconto || ',' || chr(13) ||
                        'pItemTV1Bnf            => ''' || pItemTV1Bnf || ''',' || chr(13) ||
                        'pValorDescPIS_COFINS   => '   || pValorDescPIS_COFINS || ',' || chr(13) ||
                        'pValorDescICMS         => '   || pValorDescICMS || ',' || chr(13) ||
                        'pValorSUFRAMA          => '   || pValorSUFRAMA || ',' || chr(13) ||
                        'pROWID                 => ''' || pROWID || ''',' || chr(13) ||
                        'pCalculaIPI            => ''' || pCalculaIPI || ''',' || chr(13) ||
                        'pTransferencia         => ''' || pTransferencia || ''',' || chr(13) ||
                        'pOrigemPedido          => ''' || pOrigemPedido || ''',' || chr(13) ||
                        'pVendaLocalEstrangeira => ''' || pVendaLocalEstrangeira || ''',' || chr(13) ||
                        'pCodPrecoFixo          => '   || pCodPrecoFixo || ',' || chr(13) ||
                        'pTransferenciaVirtual  => ''' || pTransferenciaVirtual || ''',' || chr(13) ||
                        'pPtabelaSemImposto     => '   || pPtabelaSemImposto || ',' || chr(13) ||
                        'pVendaTriangular       => '   || pVendaTriangular || ',' || chr(13) ||
                        'pRotinaConsum          => '   || pRotinaConsum || ',' || chr(13) ||
                        'pCodBnf                => '   || pCodBnf || ',' || chr(13) ||
                        'pCodEndEnt             => '   || pCodEndEnt || ',' || chr(13) ||
                        'pNaoArredondar         => ''' || pNaoArredondar || ''',' || chr(13) ||
                        'pTipoDocumento         => ''' || pTipoDocumento || ''',' || chr(13) ||
                        'pconsultardblink       => ''' || pconsultardblink || ''',' || chr(13) ||
                        'pcontaordem            => ''' || pcontaordem      || ''',' || chr(13) ||
                        'pValorICMSPartilhaRem  => ''' || pValorICMSPartilhaRem || CHR(13) ||
                        '#########################################' || chr(13);

    Imposto.Parametros132.tipoaliqoutrasdesp     := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOALIQOUTRASDESP'
                                                                                      ,'99'
                                                                                      ,'P');
    Imposto.Parametros132.aliqicmoutrasdesp      := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_ALIQICMOUTRASDESP'
                                                                                     ,'99'
                                                                                     ,0);
    Imposto.Parametros132.aliqicminteroutrasdesp := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_ALIQICMINTEROUTRASDESP'
                                                                                     ,'99'
                                                                                     ,0);
    Imposto.Parametros132.consideraisentoscomopf := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CONSIDERAISENTOSCOMOPF'
                                                                                      ,'99'
                                                                                      ,'N');
    Imposto.Parametros132.UtilizaPercBaseredPF   := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZAPERCBASEREDPF'
                                                                                      ,'99'
                                                                                      ,'N');
    Imposto.Parametros132.AceitaPFContribuinte   := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ACEITAPFCONTRIBUINTE'
                                                                                      ,'99'
                                                                                      ,'N');
    Imposto.Parametros132.NumCasasDecimais         := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA','99',2);

    Imposto.Parametros132.txvenda                  := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_TXVENDA'
                                                                                       ,'99'
                                                                                       ,0);
    Imposto.Parametros132.tipocalcst               := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOCALCST'
                                                                                        ,'99'
                                                                                        ,'PV');
    Imposto.Parametros132.percicmfrete             := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_PERCICMFRETE'
                                                                                       ,'99'
                                                                                       ,0);
    Imposto.Parametros132.percicminterfrete        := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_PERCICMINTERFRETE'
                                                                                       ,'99'
                                                                                       ,0);
    Imposto.Parametros132.mostrarpvendasemst       := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_MOSTRARPVENDASEMST'
                                                                                        ,'99'
                                                                                        ,'N');
    Imposto.Parametros132.usaTributacaoPorUF       := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF'
                                                                                        ,'99'
                                                                                        ,'N');
    Imposto.Parametros132.UsarTributacaoTransfTV10 :=  FERRAMENTAS.F_BUSCARPARAMETRO_ALFA( 'USARTRIBTRANSFVENDA10'
                                                                                           ,psCodFilial
                                                                                           ,FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USARTRIBUTACAOTRANSFTV10'
                                                                                                                               ,'99'
                                                                                                                               ,'N'));
    Imposto.Parametros132.UTILIZARTRIBUTEAJUSTEESTOQUE := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZARTRIBUTEAJUSTEESTOQUE'
                                                                                        ,psCodFilial
                                                                                        ,'N');

     Imposto.Parametros132.ConsideraPrecoSemDescCalcIpi :=  FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONSIDERAPSDCALCIPI'
                                                                                              ,psCodFilial
                                                                                              ,'N');
    ------- 1400 - FATURAMENTO ----------------
    Imposto.Parametros132.IncluiFreteOutrasDespepBaseST := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_INCLUIFRETEOUTRASDESPBASEST'
                                                                                             ,psCodFilial
                                                                                             ,'N');

    Imposto.Parametros132.AgregStOutrasDesp             := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('AGREGSTOUTRASDESP'
                                                                                             ,psCodFilial
                                                                                             ,'N');

    Imposto.Parametros132.USADESCSIMPLESNAC             := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC'
                                                                                             ,psCodFilial
                                                                                             ,'N');
    -------------------------------------------
    Imposto.Parametros132.UtilizaTribEndEnt             := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZATRIBENDENT'
                                                                                             ,psCodFilial
                                                                                             ,'N');

    Imposto.Parametros132.ValidarIpiPor                 := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDARIPIPOR'
                                                                                             ,'99'
                                                                                             ,'V');

    Imposto.Parametros132.AGREGARFRETEBASEIPI           := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('AGREGARFRETEBASEIPI'
                                                                                             ,psCodFilial
                                                                                             ,'N');

    Imposto.Parametros132.CalcularIPIVenda   := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_CALCULARIPIVENDA'
                                                                                  ,CASE
                                                                                    Imposto.Parametros132.ValidarIpiPor
                                                                                     WHEN 'V' THEN
                                                                                      psCodFilial
                                                                                     WHEN 'N' THEN
                                                                                      NVL(psCodFilialNF
                                                                                         ,psCodFilial)
                                                                                   END
                                                                                  ,'N');

    Imposto.Parametros132.Utilizacontrolemedicamentos := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZACONTROLEMEDICAMENTOS'
                                                                                             ,'99'
                                                                                             ,'N');

    Imposto.Cliente               := FERRAMENTAS.BUSCAR_CLIENTE(pCODCLI
                                                               ,psCodFilialNF);
    Imposto.PlanoPagamento        := BUSCAR_PLANO_PAGTO(pCODPLPAG);
    Imposto.Produto               := BUSCAR_PRODUTO(pCODPROD);
    Imposto.Embalagem             := BUSCAR_EMBALAGEM(pCODPROD
                                                     ,pCodAuxiliar
                                                     ,NVL(psCodFilialRetira
                                                         ,psCodFilial));
    Imposto.Filial                := BUSCAR_FILIAL(psCodFilial);
    Imposto.FilialNF              := BUSCAR_FILIAL(NVL(psCodFilialNF, psCodFilial));
    Imposto.FilialRetira          := BUSCAR_FILIAL(NVL(psCodFilialRetira, psCodFilial));
    Imposto.Cnae                  := BUSCAR_CNAE(Imposto.Cliente.CodCnae);
    Imposto.EnderecoEntrega       := BUSCAR_ENDERECO_ENTREGA(pCodEndEnt);
    Imposto.Produto.ProdutoFilial := BUSCAR_PRODUTO_FILIAL(pCODPROD
                                                          ,NVL(psCodFilialRetira ,psCodFilial));

    Imposto.Parametros132.ConsVlUltEntContSSTPrecific := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONSVLULTENTCONTSSTPRECIFICVENDA',
                                                                                            psCodFilial,
                                                                                            'N');

    vnnumregiao := Imposto.Cliente.numregiao;

    if (Imposto.Parametros132.UtilizaTribEndEnt = 'S') AND
       (Imposto.EnderecoEntrega.NumRegiao > 0)
    THEN
      vnnumregiao := Imposto.EnderecoEntrega.NUMREGIAO;
    END IF;

    IF pOrigemPedido in ('B', 'R') THEN
      IF Imposto.Filial.UF = Imposto.Cliente.estent THEN
        IF (Imposto.Filial.UsaRegiaoFilialVendaEstadual = 'S') AND
           (Imposto.Filial.NumRegiaoPadrao > 0) THEN
          vnnumregiao := Imposto.Filial.NumRegiaoPadrao;
        END IF;
      ELSE
        IF (Imposto.Filial.UsaRegiaoFilialVendaInter = 'S') AND
           (Imposto.Filial.NumRegiaoPadraoInter > 0) THEN
          vnnumregiao := Imposto.Filial.NumRegiaoPadraoInter;
        END IF;
      END IF;
    END IF;

    IF vnnumregiao = 0 THEN
      vnnumregiao := Imposto.Cliente.numregiao;
    END IF;

    IF ((psCodFilialNF IS NOT NULL) or (Imposto.Cliente.CodFilialNF IS NOT NULL)) and
    (NVL(pTransferenciaVirtual, 'N') = 'N') THEN -- VEN-8909
      vsCodFilial := NVL(psCodFilialNF, Imposto.Cliente.CodFilialNF);
    ELSE
      vsCodFilial := psCodFilial;
    END IF;

    ------- 1400 - FATURAMENTO ----------------
    Imposto.ItemPedido := BUSCAR_ITEMPEDIDO(pROWID, pORIGEM);

    Imposto.ItemPedido.VLDESCICMISENCAO := pValorDescICMS;
    Imposto.ItemPedido.VLDESCREDUCAOPIS := pValorDescPIS_COFINS;
    Imposto.ItemPedido.VLDESCSUFRAMA    := pValorSUFRAMA;

    IF (Imposto.ItemPedido.CodST > 0)
      AND (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_CALCULASTFRETEFIGPEDIDO', vsCodFilial, 'N') = 'S')
      AND (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_INCLUIFRETEOUTRASDESPBASEST', vsCodFilial, 'S') = 'S') THEN
          vncodst := Imposto.ItemPedido.CodSt;
    ELSE
		IF (pCodst > 0) THEN
			vncodst := pCodst;
		ELSE           
			vncodst := RETORNA_CODIGO_TRIBUTACAO(Imposto.Cliente

                                        ,pCodProd
                                        ,vsCodFilial
                                        ,vnnumregiao
                                        ,pVendaTriangular
                                        ,pCondVenda
                                        ,pCodEndEnt);
		END IF;
    END IF;

      -------------------------------------------

    Imposto.Tributacao   := BUSCAR_TRIBUTACAO(vncodst);
    Imposto.Precificacao := BUSCAR_PRECIFICACAO(pCodProd, vnnumregiao, pconsultardblink);
    Imposto.Estoque      := BUSCAR_ESTOQUE(pCodProd, psCodFilial);
    Imposto.Praca        := BUSCAR_PRACA(Imposto.Cliente.CodPraca);
    Imposto.Praca.Regiao := BUSCAR_REGIAO(vnnumregiao);

    Imposto.Estoque.VALORULTENT := COALESCE((CASE WHEN Imposto.Parametros132.ConsVlUltEntContSSTPrecific = 'S' THEN
                                               CASE WHEN nvl(Imposto.Precificacao.VlUltEntContSemSt, 0) = 0 THEN
                                                 Imposto.Estoque.VALORULTENT
                                               ELSE
                                                 Imposto.Precificacao.VlUltEntContSemSt
                                               END
                                              ELSE
                                                Imposto.Estoque.VALORULTENT
                                             END),
                                             0);

        -------------- DADOS DE PEDIDO -----------------
    Imposto.Pedido.CondVenda            := pCondVenda;
    Imposto.Pedido.RotinaConsum         := pRotinaConsum;
    Imposto.Pedido.OrigemPedido         := pOrigemPedido;
    Imposto.Pedido.VendaTriangular      := pVendaTriangular;
    Imposto.Pedido.VendaExportacao      := psVendaExportacao;
    Imposto.Pedido.Transferencia        := pTransferencia;
    Imposto.Pedido.TransferenciaVirtual := pTransferenciaVirtual;
    Imposto.Pedido.CodEnderecoEntrega   := pCodEndEnt;
    Imposto.Pedido.TipoDocumento        := pTipoDocumento;
    Imposto.ItemPedido.VLICMSPARTREM    := pValorICMSPartilhaRem;
    -------------- DADOS DE PEDIDO -----------------

    Imposto.Parametros132.calcstpf := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CALCSTPF'
                                                                        ,'99'
                                                                        ,'S');

    if not (obterprecoutilizadonfe(NVL(psCodFilialNF,
                                   psCodFilial),
                               pCodCli,
                               pCodProd) = 'B') then
      vdPtabelaSemImposto := 0;
    else
      vdPtabelaSemImposto := pPtabelaSemImposto;
    end if;

    IF (FERRAMENTAS.F_COMPARARCNPJ(Imposto.Filial.CodCli, Imposto.Cliente.CodCli)) THEN
      vTransfCNPJMesmoRadical := 'S';
    ELSE
      vTransfCNPJMesmoRadical := 'N';
    END IF;
	Imposto.Tributacao :=  VerificaPautaProdutUF(Imposto,pCodProd,Imposto.Cliente.estent);
    DADOS_SAIDA := PROCESSAR_ST(Imposto
                               ,pCondVenda
                               ,psVendaExportacao
                               ,pVendaLocalEstrangeira
                               ,pPvenda
                               ,pPerDesconto
                               ,pItemTV1Bnf
                               ,'N'
                               ,pValorDescPIS_COFINS
                               ,pValorDescICMS
                               ,pValorSUFRAMA
                               ,pROWID
                               ,pCalculaIPI
                               ,pTransferencia
                               ,pCodPrecoFixo
                               ,'T'
                               ,pTransferenciaVirtual
                               ,vdPtabelaSemImposto
                               ,pRotinaConsum
                               ,pCodBnf -- HIS.03069.2016
                               ,vTransfCNPJMesmoRadical -- HIS.01143.2017
                               ,pNaoArredondar
                               ,'N'
                               ,vnnumregiao
                               ,pcontaordem
                               );

    --Cliente isento de ST
    vbClienteFonteST := (Imposto.Cliente.ClienteFonteST = 'S') AND
                         (((Imposto.Tributacao.UsaValorStFonte = 'S') AND
                         Imposto.Tributacao.Aliqicms1Fonte IS NOT NULL AND
                         Imposto.Tributacao.Aliqicms2Fonte IS NOT NULL) OR
                         ((NVL(Imposto.Tributacao.Aliqicms1Fonte,0) > 0) AND
                         (NVL(Imposto.Tributacao.Aliqicms2Fonte,0) > 0))) AND
                         ((Imposto.Cliente.PessoaFisicaJuridica = 'PESSOA JURIDICA') OR
                         ((Imposto.Cliente.PessoaFisicaJuridica = 'PESSOA FISICA') AND
                         (Imposto.Parametros132.calcstpf = 'S'))) AND
                         (pTransferencia = 'N');

    if (Imposto.Cliente.CalculaSt = 'N')then --Comentado trecho para zerar st caso CalculaSt = 'N'  and not(vbClienteFonteST) then
      DADOS_SAIDA.ST := 0;
      DADOS_SAIDA.BASEST := 0; /*0.120863.2015*/
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;

    if pcontaordem = 'S' and pCondVenda = 8 and
       (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_VALIDARPRECOVENDATV8', psCodFilial, 'N') = 'N') then

      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao      := vrLog.Descricao ||
                              'Zerou ST e BASEST Linha: ' ||
                              TO_CHAR($$PLSQL_LINE) || chr(13) ||
                              '#########################################';
    END IF;

    IF imposto.Produto.TipoMercadoria = 'CB' THEN
      DADOS_SAIDA.ST := 0;
      DADOS_SAIDA.BASEST := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;

    --Cálcula ST p/ Pessoa Física
    if Imposto.Parametros132.calcstpf = 'N' then
      if Imposto.Cliente.PessoaFisicaJuridica = 'PESSOA FISICA' then
        DADOS_SAIDA.ST     := 0;
        DADOS_SAIDA.BASEST := 0;
        DADOS_SAIDA.BASEFECP := 0;
        DADOS_SAIDA.ALIQFECP := 0;
        DADOS_SAIDA.VLRFECP  := 0;
        vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
      END IF;
    END IF;

    --HIS.01257.2015
    if ((Imposto.Cliente.RioLog = 'S') and
        (Imposto.Tributacao.RioLogIsentoST = 'S'))
    THEN
      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;
    --fim HIS.01257.2015

    --HIS.04312.2015
    IF ((pCondVenda = 9) and
       (Imposto.Tributacao.Tv9IsentoSt = 'S'))
    THEN
      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;
    -- fim HIS.04312.2015

    IF (Imposto.Produto.TipoMercadoria = 'CB') THEN
      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
        vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;

    IF (Imposto.Tributacao.CalcStTransf = 'N') AND
       (pTransferenciaVirtual = 'S')
    THEN
      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;

    IF (Imposto.Produto.ProdutoFilial.Relevante = 'N')
    THEN
      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;

    IF ((Imposto.Produto.IsentoSTClienteCozinaInd = 'S') and
        (Imposto.Cliente.CozinhaIndustrial = 'S'))
    THEN
      DADOS_SAIDA.ST       := 0;
      DADOS_SAIDA.BASEST   := 0;
      DADOS_SAIDA.BASEFECP := 0;
      DADOS_SAIDA.ALIQFECP := 0;
      DADOS_SAIDA.VLRFECP  := 0;
      vrLog.Descricao := vrLog.Descricao || 'Zerou ST e BASEST Linha: ' || TO_CHAR($$PLSQL_LINE) || chr(13) ||
                                          '#########################################';
    END IF;

    IF DADOS_SAIDA.VLRFECP <= 0 THEN
      DADOS_SAIDA.VLRFECP   := 0;
    END IF;

    PIPE ROW(DADOS_SAIDA);

    vrLog.Descricao := vrLog.Descricao || 'ST/BASEST' || DADOS_SAIDA.ST || ' / ' || DADOS_SAIDA.BASEST || chr(13) ||
                                          '#########################################';
    FERRAMENTAS.GRAVARLOG(vrLOG, '');

    RETURN;
  END;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_01
  procedure PVENDA_SEM_IMPOSTO_01(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vbConsiderarIpiAliqicms2    in out BOOLEAN,
                                  voImposto                   in T_IMPOSTO,
                                  vnPercRedBaseIcms           IN NUMBER) is
  begin
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) and (vnPauta = 0) then
      if (vbConsiderarIpiAliqicms2) and
         (vnAliquota1Calculada > 0) and
         (vnAliquota2Calculada > 0) then
        vnVendaSemImposto := (pVenda /
                              ( 1 + vnpercipi/100 +
                              voImposto.Tributacao.PercDifAliquotas/100 +
                              vnPercentualdeReducaoBaseST/100*vnAliquota1Calculada/100 +
                              vnIVA/100*vnPercentualdeReducaoBaseST/100*vnAliquota1Calculada/100 +
                              vnpercipi/100*vnPercentualdeReducaoBaseST/100*vnAliquota1Calculada/100 +
                              vnpercipi/100*vnIVA/100*vnPercentualdeReducaoBaseST/100*vnAliquota1Calculada/100
                              - vnPercRedBaseIcms/100*vnAliquota2Calculada/100 -
                              vnpercipi/100*vnPercRedBaseIcms/100*vnAliquota2Calculada/100)) ;
      else
        vnVendaSemImposto := (pVenda / (1 + (vnpercipi / 100) +
                             (voImposto.Tributacao.PercDifAliquotas / 100) +
                             ((((vnAliquota1Calculada / 100) *
                             (1 + (vnIVA / 100)) *
                             (vnPercRedBaseIcms/100 +  (vnpercipi / 100)) *
                             (vnPercentualdeReducaoBaseST / 100)) -
                             ((vnPercRedBaseIcms/100) * vnAliquota2Calculada / 100)))));
      END IF;
    END IF;
  end PVENDA_SEM_IMPOSTO_01;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_02
  procedure PVENDA_SEM_IMPOSTO_02(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vbConsiderarIpiAliqicms2    in out BOOLEAN,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) and (vnPauta > 0) then
      if (vbConsiderarIpiAliqicms2) and
         (vnAliquota1Calculada > 0) and
         (vnAliquota2Calculada > 0) then
        vnVendaSemImposto := (pVenda - ((vnPauta *
                             (vnPercentualdeReducaoBaseST / 100)) *
                             (vnAliquota1Calculada / 100))) / (1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) +
                             (vnpercipi / 100) -
                             (vnAliquota2Calculada / 100) -
                             (vnpercipi / 100) *
                             (vnAliquota2Calculada / 100));
      else
        vnVendaSemImposto := (pVenda - ((vnPauta *
                             (vnPercentualdeReducaoBaseST / 100)) *
                             (vnAliquota1Calculada / 100))) / (1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) +
                             (vnpercipi / 100) -
                             (vnAliquota2Calculada / 100));
      END IF;

      if (vnVendaSemImposto > pVenda) or (vnVendaSemImposto < 0) then
        vnVendaSemImposto := pVenda;
      end if;

    END IF;
  end PVENDA_SEM_IMPOSTO_02;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_03
  procedure PVENDA_SEM_IMPOSTO_03(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) and
       (psUsaValorultEntbaseST = 'S') and (vnPauta = 0) THEN

      vnVendaSemImposto := (pVenda - ((VnValorUltEnt * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100)) *
                           (vnAliquota1Calculada / 100))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) +
                           (vnpercipi / 100) -
                           (vnAliquota2Calculada / 100) +
                           ((vnpercipi / 100) * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)));

    end IF;
  end PVENDA_SEM_IMPOSTO_03;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_04
  procedure PVENDA_SEM_IMPOSTO_04(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  psUsaValorultEntbaseST2     in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    --4. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) and
       (psUsaValorultEntbaseST = 'S') and
       --(voImposto.Tributacao.UsaValorultEntbaseST2 = 'S') and
       (psUsaValorultEntbaseST2 = 'S')  then
      vnVendaSemImposto := (pVenda +
                           (VnValorUltEnt * ((vnAliquota2Calculada / 100) -
                           (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) +
                           (vnpercipi / 100) +
                           ((vnpercipi / 100) * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)));
    END IF;
  end PVENDA_SEM_IMPOSTO_04;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_05
  procedure PVENDA_SEM_IMPOSTO_05(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vbConsiderarIpiAliqicms2    in out BOOLEAN,
                                  voImposto                   in T_IMPOSTO,
                                  vnPercRedIcms               IN NUMBER) is
  begin
    if (vnPautaIpi > 0) and (vnPauta = 0) then
      if (vbConsiderarIpiAliqicms2) and (vnIVA > 0) and
         (vnAliquota1Calculada > 0) and
         (vnAliquota2Calculada > 0) then

        vnVendaSemImposto := (pVenda - vnPautaIpi - vnPautaIpi * (1 + vnIVA / 100) *
                              vnPercentualdeReducaoBaseST / 100 * vnAliquota1Calculada / 100 +
                              vnPautaIpi * vnAliquota2Calculada/100) /
                              ((1 + voImposto.Tributacao.PercDifAliquotas / 100) +
                              vnPercRedIcms / 100 * (1 + vnIVA / 100) *
                              vnPercentualdeReducaoBaseST / 100 * vnAliquota1Calculada / 100 -
                              vnPercRedIcms / 100 * vnAliquota2Calculada / 100);
         /*
        vnVendaSemImposto := (pVenda - (vnPautaIpi *
                             (1 + ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100)))) +
                             vnPautaIpi * (vnAliquota2Calculada / 100)) /
                             ((1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100)) +
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100)));    */
      else
        vnVendaSemImposto := (pVenda - vnPautaIpi -
                              vnPautaIpi * vnPercentualdeReducaoBaseST / 100 *
                              (1 + vnIVA / 100) * (vnAliquota1Calculada / 100)) /
                              ((1 + voImposto.Tributacao.PercDifAliquotas / 100) +
                              (vnPercRedIcms / 100) * vnPercentualdeReducaoBaseST / 100 * (1 + vnIVA / 100) *
                              (vnAliquota1Calculada / 100) - vnPercRedIcms / 100 * vnAliquota2Calculada / 100);
      /*
        vnVendaSemImposto := (pVenda - (vnPautaIpi *
                             (1 + ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100))))) /
                             ((1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100)) +
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100)));
       */
      END IF;
    END IF;
  end PVENDA_SEM_IMPOSTO_05;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_06
  procedure PVENDA_SEM_IMPOSTO_06(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vbConsiderarIpiAliqicms2    in out BOOLEAN,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) and (vnPauta > 0) then
      if (vbConsiderarIpiAliqicms2) and
         (vnAliquota1Calculada > 0) and
         (vnAliquota2Calculada > 0) then
        vnVendaSemImposto := (pVenda - ((vnPauta *
                             (vnPercentualdeReducaoBaseST / 100)) *
                             (vnAliquota1Calculada / 100)) - (vnPautaIpi) +
                             (vnPautaIpi) * (vnAliquota2Calculada / 100)) / (1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100));
      else
        vnVendaSemImposto := (pVenda - ((vnPauta *
                             (vnPercentualdeReducaoBaseST / 100)) *
                             (vnAliquota1Calculada / 100)) - (vnPautaIpi)) / (1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100));
      END IF;
    END IF;
  end PVENDA_SEM_IMPOSTO_06;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_07
  procedure PVENDA_SEM_IMPOSTO_07(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) and (psUsaValorultEntbaseST = 'S') and
       (vnPauta = 0)  then
      vnVendaSemImposto := (pVenda - ((vnPautaIpi *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (VnValorUltEnt * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) -
                           (vnAliquota2Calculada / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_07;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_08
  procedure PVENDA_SEM_IMPOSTO_08(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  psUsaValorultEntbaseST2       in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) and (psUsaValorultEntbaseST = 'S') and
       --(voImposto.Tributacao.UsaValorultEntbaseST2 = 'S') and
       (psUsaValorultEntbaseST2 = 'S') and
       (voImposto.Filial.UF = voImposto.Cliente.EstEnt) then
      vnVendaSemImposto := (pVenda -
                           ((vnPautaIpi *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (VnValorUltEnt * (((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnAliquota2Calculada / 100))))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_08;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_09
  procedure PVENDA_SEM_IMPOSTO_09(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vbConsiderarIpiAliqicms2    in out BOOLEAN,
                                  voImposto                   in T_IMPOSTO,
                                  vnPercRedICMS               IN number) is
  begin
    if (VnIpiPorKGVenda > 0) and (vnPauta = 0) then
      if (vbConsiderarIpiAliqicms2) and (vnIVA > 0) and
         (vnAliquota1Calculada > 0) and
         (vnAliquota2Calculada > 0) then

        vnVendaSemImposto := (pVenda - (VnIpiPorKGVenda * VnPesoBruto) - (VnIpiPorKGVenda * VnPesoBruto) * (1 + vnIVA / 100) *
                              vnPercentualdeReducaoBaseST / 100 * vnAliquota1Calculada / 100 +
                              (VnIpiPorKGVenda * VnPesoBruto) * vnAliquota2Calculada/100) /
                              ((1 + voImposto.Tributacao.PercDifAliquotas / 100) +
                              vnPercRedIcms / 100 * (1 + vnIVA / 100) *
                              vnPercentualdeReducaoBaseST / 100 * vnAliquota1Calculada / 100 -
                              vnPercRedIcms / 100 * vnAliquota2Calculada / 100);
        /*
        vnVendaSemImposto := (pVenda - ((VnIpiPorKGVenda * VnPesoBruto) *
                             (1 + ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100)))) +
                             (vnAliquota2Calculada / 100) *
                             (VnIpiPorKGVenda * VnPesoBruto)) /
                             ((1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100)) +
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100)));
        */
      else
        vnVendaSemImposto := (pVenda - (VnIpiPorKGVenda * VnPesoBruto) -
                             (VnIpiPorKGVenda * VnPesoBruto) * vnPercentualdeReducaoBaseST / 100 *
                             (1 + vnIVA / 100) * (vnAliquota1Calculada / 100)) /
                             ((1 + voImposto.Tributacao.PercDifAliquotas / 100) +
                             (vnPercRedIcms / 100) * vnPercentualdeReducaoBaseST / 100 * (1 + vnIVA / 100) *
                             (vnAliquota1Calculada / 100) - vnPercRedIcms / 100 * vnAliquota2Calculada / 100);
       /*
        vnVendaSemImposto := (pVenda - ((VnIpiPorKGVenda * VnPesoBruto) *
                             (1 + ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100))))) /
                             ((1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100)) +
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (vnAliquota1Calculada / 100)));*/
      END IF;
    END IF;
  end PVENDA_SEM_IMPOSTO_09;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_10
  procedure PVENDA_SEM_IMPOSTO_10(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vbConsiderarIpiAliqicms2    in out BOOLEAN,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (VnIpiPorKGVenda > 0) and (vnPauta > 0) then
      if (vbConsiderarIpiAliqicms2) and
         (vnAliquota1Calculada > 0) and
         (vnAliquota2Calculada > 0) then
        vnVendaSemImposto := (pVenda - ((vnPauta *
                             (vnPercentualdeReducaoBaseST / 100)) *
                             (vnAliquota1Calculada / 100)) -
                             (VnIpiPorKGVenda * VnPesoBruto) +
                             (VnIpiPorKGVenda * VnPesoBruto) *
                             (vnAliquota2Calculada / 100)) / (1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100));
      else
        vnVendaSemImposto := (pVenda - ((vnPauta *
                             (vnPercentualdeReducaoBaseST / 100)) *
                             (vnAliquota1Calculada / 100)) -
                             (VnIpiPorKGVenda * VnPesoBruto)) / (1 +
                             (voImposto.Tributacao.PercDifAliquotas / 100) -
                             (vnAliquota2Calculada / 100));
      END IF;
    END IF;
  end PVENDA_SEM_IMPOSTO_10;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_11
  procedure PVENDA_SEM_IMPOSTO_11(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (VnIpiPorKGVenda > 0) and
       (psUsaValorultEntbaseST = 'S') and (vnPauta = 0) then
      vnVendaSemImposto := (pVenda - (((VnIpiPorKGVenda * VnPesoBruto) *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (VnValorUltEnt * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) -
                           (vnAliquota2Calculada / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_11;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_12
  procedure PVENDA_SEM_IMPOSTO_12(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  psUsaValorultEntbaseST2       in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    IF (VnIpiPorKGVenda > 0) and
       (psUsaValorultEntbaseST = 'S') and
       --(voImposto.Tributacao.UsaValorultEntbaseST2 = 'S') and
       (psUsaValorultEntbaseST2 = 'S') then
      vnVendaSemImposto := (pVenda -
                           (((VnIpiPorKGVenda * VnPesoBruto) *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (VnValorUltEnt * (((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnAliquota2Calculada / 100))))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_12;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_13
  procedure PVENDA_SEM_IMPOSTO_13(pVenda                      in NUMBER,
                                  vnPercentualdeReducaoBaseST in out NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (voImposto.Tributacao.UsaPMCBasest = 'S') and
       (voImposto.produto.PrecoMaxConsum > 0) then
      vnVendaSemImposto := (pVenda - ((voImposto.produto.PrecoMaxConsum *
                           (vnPercentualdeReducaoBaseST / 100)) *
                           (vnAliquota1Calculada / 100))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) -
                           (vnAliquota2Calculada / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_13;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_14
  procedure PVENDA_SEM_IMPOSTO_14(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  psUsaValorultEntbaseST2       in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) and
       (psUsaValorultEntbaseST = 'S') and
       --(voImposto.Tributacao.UsaValorultEntbaseST2 = 'S') and (vnPauta > 0) and
       (psUsaValorultEntbaseST2 = 'S') and (vnPauta > 0)  then
      vnVendaSemImposto := (pVenda -
                           ((vnPauta * (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (VnValorUltEnt *
                           ((vnAliquota2Calculada / 100))))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) +
                           (vnpercipi / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_14;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_15
  procedure PVENDA_SEM_IMPOSTO_15(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  psUsaValorultEntbaseST2       in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) and (psUsaValorultEntbaseST = 'S') and
       --(voImposto.Tributacao.UsaValorultEntbaseST2 = 'S') and (vnPauta > 0) and
       (psUsaValorultEntbaseST2 = 'S') and (vnPauta > 0) and
       (voImposto.Filial.UF = voImposto.Cliente.EstEnt) then
      vnVendaSemImposto := (pVenda -
                           ((vnPauta * (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (VnValorUltEnt *
                           ((vnAliquota2Calculada / 100)))) - vnPautaIpi) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_15;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_16
  procedure PVENDA_SEM_IMPOSTO_16(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  psUsaValorultEntbaseST      in varchar,
                                  psUsaValorultEntbaseST2       in varchar,
                                  voImposto                   in T_IMPOSTO) is
  begin
    IF (VnIpiPorKGVenda > 0) and
       (psUsaValorultEntbaseST = 'S') and
       --(voImposto.Tributacao.UsaValorultEntbaseST2 = 'S') and (vnPauta > 0) and
       (psUsaValorultEntbaseST2 = 'S') and (vnPauta > 0) and
       (voImposto.Filial.UF = voImposto.Cliente.EstEnt) then
      vnVendaSemImposto := (pVenda -
                           ((vnPauta * (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (VnValorUltEnt *
                           ((vnAliquota2Calculada / 100)))) -
                           (VnIpiPorKGVenda * VnPesoBruto)) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_16;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_18
  procedure PVENDA_SEM_IMPOSTO_17(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := (pVenda +
                           (vnVlUltEntMes * ((vnAliquota2Calculada / 100) -
                           (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) +
                           (vnpercipi / 100) +
                           ((vnpercipi / 100) * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)));
    END IF;
  end PVENDA_SEM_IMPOSTO_17;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_18
  procedure PVENDA_SEM_IMPOSTO_18(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) and (vnPauta = 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := (pVenda - ((vnPautaIpi *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (vnVlUltEntMes * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) -
                           (vnAliquota2Calculada / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_18;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_19
  procedure PVENDA_SEM_IMPOSTO_19(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := (pVenda -
                           ((vnPautaIpi *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (vnVlUltEntMes * (((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnAliquota2Calculada / 100))))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_19;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_20
  procedure PVENDA_SEM_IMPOSTO_20(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (VnIpiPorKGVenda > 0) and (vnPauta = 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := (pVenda - (((VnIpiPorKGVenda * VnPesoBruto) *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (vnVlUltEntMes * (1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) -
                           (vnAliquota2Calculada / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_20;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_21
  procedure PVENDA_SEM_IMPOSTO_21(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnIVA                       in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    IF (VnIpiPorKGVenda > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;
      vnVendaSemImposto := (pVenda -
                           (((VnIpiPorKGVenda * VnPesoBruto) *
                           (1 + ((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)))) +
                           (vnVlUltEntMes * (((1 + (vnIVA / 100)) *
                           (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnAliquota2Calculada / 100))))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_21;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_22
  procedure PVENDA_SEM_IMPOSTO_22(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnPercIPI                   in out pcprodut.percipi%TYPE,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
       (VnIpiPorKGVenda = 0)) and (vnPauta > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;
      vnVendaSemImposto := (pVenda -
                           ((vnPauta * (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnVlUltEntMes *
                           ((vnAliquota2Calculada / 100))))) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100) +
                           (vnpercipi / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_22;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_23
  procedure PVENDA_SEM_IMPOSTO_23(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    if (vnPautaIpi > 0) and (vnPauta > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := (pVenda -
                           ((vnPauta * (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnVlUltEntMes *
                           ((vnAliquota2Calculada / 100)))) - vnPautaIpi) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_23;

  -- Refactored procedure  PVENDA_SEM_IMPOSTO_24
  procedure PVENDA_SEM_IMPOSTO_24(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  begin
    IF (VnIpiPorKGVenda > 0) and (vnPauta > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;
      vnVendaSemImposto := (pVenda -
                           ((vnPauta * (vnPercentualdeReducaoBaseST / 100) *
                           (vnAliquota1Calculada / 100)) -
                           (vnVlUltEntMes *
                           ((vnAliquota2Calculada / 100)))) -
                           (VnIpiPorKGVenda * VnPesoBruto)) /
                           (1 + (voImposto.Tributacao.PercDifAliquotas / 100));
    END IF;
  end PVENDA_SEM_IMPOSTO_24;

  procedure PVENDA_SEM_IMPOSTO_25(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  vnPercIPI                   in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  BEGIN
    IF (vnPautaIpi <= 0) AND (VnIpiPorKGVenda = 0) THEN
      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := (((vnPauta * (vnPercentualdeReducaoBaseST /100)) *
                            (vnAliquota1Calculada/100)) -
                            (vnVlUltEntMes * (vnAliquota2Calculada/100)) - pVenda) /
                            (-1 - (vnPercIpi/100));
    END IF;

  END PVENDA_SEM_IMPOSTO_25;

  procedure PVENDA_SEM_IMPOSTO_26(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  vnPautaIpi                  in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  BEGIN
    IF (vnPautaIpi > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto  := -((vnPautaIpi) +
                              ((vnPauta * (vnPercentualdeReducaoBaseST/100)) *
                               (vnAliquota1Calculada/100)) -
                               (vnVlUltEntMes * (vnAliquota2Calculada/100))) +
                               pVenda;
    END IF;

  END PVENDA_SEM_IMPOSTO_26;

  procedure PVENDA_SEM_IMPOSTO_27(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPercentualdeReducaoBaseST in out pctribut.percbaseredst%TYPE,
                                  vnPauta                     in out NUMBER,
                                  VnValorUltEnt               in out NUMBER,
                                  VnUltEntMes                 in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  vnAliquota1Calculada        in out NUMBER,
                                  vnAliquota2Calculada        in out NUMBER,
                                  vnVlUltEntMes               in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  BEGIN

    if (VnIpiPorKGVenda > 0) THEN

      IF voImposto.Precificacao.VlUltEntMes > 0 THEN
        vnVlUltEntMes := VnUltEntMes;
      ELSE
        vnVlUltEntMes := VnValorUltEnt;
      END IF;

      vnVendaSemImposto := -((VnIpiPorKGVenda * VnPesoBruto) +
                            ((vnPauta * (vnPercentualdeReducaoBaseST/100)) *
                             (vnAliquota1Calculada/100)) -
                             (vnVlUltEntMes * (vnAliquota2Calculada/100))) + pVenda;

    END IF;
  END PVENDA_SEM_IMPOSTO_27;

  --- ST MT + PAUTA
  procedure PVENDA_SEM_IMPOSTO_28(pVenda                      in NUMBER,
                                  vnVendaSemImposto           in out NUMBER,
                                  vnPauta                     in out NUMBER,
                                  vnPercIpi                   in out number,
                                  vnIpiPauta                  in out NUMBER,
                                  VnIpiPorKGVenda             in out NUMBER,
                                  VnPesoBruto                 in out NUMBER,
                                  voImposto                   in T_IMPOSTO) is
  BEGIN
    IF NVL(vnPercIpi, 0) >= 0 THEN
      vnVendaSemImposto := (((vnpauta) * (voImposto.cnae.PERCARGATRIBMEDIA / 100)) -
                            pVenda) / (- 1 - (vnPercIpi / 100));
    END IF;

    IF NVL(vnIpiPauta, 0) > 0 THEN
      vnVendaSemImposto := -((vnIpiPauta) + ((vnpauta) *
                           (voImposto.cnae.PERCARGATRIBMEDIA / 100))) + pVenda;
    END IF;

    IF NVL(VnIpiPorKGVenda, 0) > 0 then
      vnVendaSemImposto := -((vnIpiPauta) + ((VnIpiPorKGVenda * VnPesoBruto) *
                            (voImposto.cnae.PERCARGATRIBMEDIA / 100))) + pVenda;
    END IF;

  END PVENDA_SEM_IMPOSTO_28;

  ------------------------------------------------------------------------------------
  /*Inicia o processo de calculo de ST*/
  function CALCULAR_PVENDA_SEM_IMPOSTO(psCodFilial            VARCHAR2,
                                       psCodFilialNF          VARCHAR2,
                                       psCodFilialRetira      VARCHAR2,
                                       pCodCli                IN NUMBER,
                                       pCodPlPag              IN NUMBER,
                                       pCodProd               IN NUMBER,
                                       pCodAuxiliar           IN NUMBER,
                                       pCondVenda             IN NUMBER,
                                       psVendaExportacao      IN VARCHAR2,
                                       pSTPrecificado         IN NUMBER,
                                       pVendaSemImposto       IN NUMBER,
                                       pVenda                 IN NUMBER,
                                       pRetiraImposto201      IN VARCHAR2 DEFAULT 'N',
                                       pFoiPrecificadoIPI     IN VARCHAR2 DEFAULT 'S',
                                       pItemTV1Bnf            IN VARCHAR2 DEFAULT 'N',
                                       pCodPrecoFixo          IN NUMBER   DEFAULT 0,
                                       psOrigemPedido         IN VARCHAR2 DEFAULT NULL,
                                       pUtilizaCustoVendaTV10 IN VARCHAR2 DEFAULT 'N',
                                       pTransferencia         IN VARCHAR2 DEFAULT 'N',
                                       pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                                       pTransferenciaVirtual  IN VARCHAR2 DEFAULT 'N',
                                       pPtabela               IN NUMBER   DEFAULT 0,
                                       pVendaTriangular       IN VARCHAR2 DEFAULT 'N',
                                       pRotinaConsum          IN VARCHAR2 DEFAULT 'T',
                                       pCodBnf                IN NUMBER   DEFAULT 0, -- HIS.03069.2016
                                       pCodEndEnt             IN NUMBER   DEFAULT 0,
                                       pTipoDocumento         IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                                       pconsultardblink       IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
                                       pcontaordem            IN VARCHAR2 DEFAULT 'N', -- Conta e ordem TV8
                                       pValorICMSPartilhaRem  IN NUMBER   DEFAULT 0,
                                       pRetiraFecp            IN VARCHAR2 DEFAULT 'N' --Retirar FECEP para sem somado futuramente no preço
                                       )
    RETURN TB_CALCULOPVENDASEMIMPOSTO
    PIPELINED IS

    DADOS_SAIDA T_CALCULOPVENDASEMIMPOSTO;
    DADOS_ST    T_CALCULOST;
    Imposto     T_IMPOSTO;

    vnPercentualdeReducaoBaseST pctribut.percbaseredst%TYPE;
    vnPercentualdeRedSimplesNac pctribut.percredpvendasimplesnac%TYPE;

    vnIVA                    NUMBER(18, 8);
    vnPauta                  NUMBER(18, 8);
    vnPautaTemp              NUMBER(18, 8);
    VnValorUltEnt            NUMBER(18, 8);
    VnUltEntMes              NUMBER(18, 8);
    VnIpiPorKGVenda          NUMBER(18, 8);
    VnPesoBruto              NUMBER(18, 8);
    vnPautaIpi               NUMBER(18, 8);
    vnVendaSemImposto        NUMBER(18, 8);
    vnnumregiao              pcclient.numregiaocli%TYPE;
    vncodst                  pctribut.codst%TYPE;
    vsIsentoIPI              pcclient.isentoipi%TYPE;
    vnPercIPI                pcprodut.percipi%TYPE;
    vnAliquota1Calculada     NUMBER(18, 8);
    vnAliquota2Calculada     NUMBER(18, 8);
    vnVlUltEntMes            NUMBER(18, 8);
    vbConsiderarIpiAliqicms2 BOOLEAN;
    vsIsentoST               VARCHAR2(1);
    --Variaveis para calculo do RJ e achar o valor final sem imposto
    vnVlSt                         NUMBER(18, 8);
    vnIPI                          NUMBER(18, 8);
    vsTIPOST                       varchar2(15);
    vsConsideraPrecoFixoSemImposto varchar2(1);
    vsAplicaDescSimplesPrecoFixo varchar2(1);
    vbAchouPrecoSemImposto         boolean;
    vsCodFilial pcfilial.codigo%type;

    vnPercRedIcms                  number(18, 6);

    vsUsaValorultEntbaseST    pctribut.usavalorultentbasest%type;
    vsUsaValorultEntbaseST2   pctribut.usavalorultentbasest2%type;


    vnCodStVendaTriang        PCTRIBUT.CODFIGVENDATRIANGULAR%TYPE;
    vbCnpjMesmoRadical BOOLEAN;
    vbCalculaMediaPondSTMG BOOLEAN;
    vsCalcMediaPondSTMGFilDest varchar2(1);
    vsCodFilialCliTransf       PCFILIAL.CODIGO%TYPE;

    /** MOTOR DE CÁLCULO  **/
    variavel    formula.RVARIAVEL;
    vsFormula   PCFORMULA.CODFORMULA%TYPE;
    vFormula    PCFORMULA.FORMULA%TYPE;
    vtVariaveis formula.tbVariaveis;
    resultado   formula.tbvariaveis;
    /** MOTOR DE CÁLCULO  **/
    pBaseIpi    NUMBER(18,6);
    pPercIpi    NUMBER(18,6);
    vnAliqIcmsFecp NUMBER(18,6);
    vrLog pclogimpostos%rowtype;
    vFECP201   NUMBER(18,6);
  BEGIN
    vrLog.Objeto := 'CALCULAR_PVENDA_SEM_IMPOSTO';
    vrLog.Descricao :=  'Iniciou function calcular_pvenda_sem_imposto, parâmetros da chamada: ' || chr(13) ||
                        'psCodFilial            => ''' || psCodFilial            || ''',' || chr(13) ||
                        'psCodFilialNF          => ''' || psCodFilialNF          || ''',' || chr(13) ||
                        'psCodFilialRetira      => ''' || psCodFilialRetira      || ''',' || chr(13) ||
                        'pCodCli                => ' || pCodCli                || ',' || chr(13) ||
                        'pCodPlPag              => ' || pCodPlPag              || ',' || chr(13) ||
                        'pCodProd               => ' || pCodProd               || ',' || chr(13) ||
                        'pCodAuxiliar           => ' || pCodAuxiliar           || ',' || chr(13) ||
                        'pCondVenda             => ' || pCondVenda             || ',' || chr(13) ||
                        'psVendaExportacao      => ''' || psVendaExportacao      || ''',' || chr(13) ||
                        'pSTPrecificado         => ' || pSTPrecificado         || ',' || chr(13) ||
                        'pVendaSemImposto       => ' || pVendaSemImposto       || ',' || chr(13) ||
                        'pVenda                 => ' || pVenda                 || ',' || chr(13) ||
                        'pRetiraImposto201      => ''' || pRetiraImposto201      || ''',' || chr(13) ||
                        'pFoiPrecificadoIPI     => ''' || pFoiPrecificadoIPI     || ''',' || chr(13) ||
                        'pItemTV1Bnf            => ''' || pItemTV1Bnf            || ''',' || chr(13) ||
                        'pCodPrecoFixo          => ' || pCodPrecoFixo          || ',' || chr(13) ||
                        'psOrigemPedido         => ''' || psOrigemPedido         || ''',' || chr(13) ||
                        'pUtilizaCustoVendaTV10 => ''' || pUtilizaCustoVendaTV10 || ''',' || chr(13) ||
                        'pTransferencia         => ''' || pTransferencia         || ''',' || chr(13) ||
                        'pVendaLocalEstrangeira => ''' || pVendaLocalEstrangeira || ''',' || chr(13) ||
                        'pTransferenciaVirtual  => ''' || pTransferenciaVirtual  || ''',' || chr(13) ||
                        'pPtabela               => ' || pPtabela               || ',' || chr(13) ||
                        'pVendaTriangular       => ''' || pVendaTriangular       || ''',' || chr(13) ||
                        'pRotinaConsum          => ''' || pRotinaConsum          || ''',' || chr(13) ||
                        'pCodBnf                => ''' || pCodBnf                || ''',' || chr(13) ||
                        'pCodEndEnt             => ' || pCodEndEnt             || ',' || chr(13) ||
                        'pTipoDocumento         => ''' || pTipoDocumento         || ''',' || chr(13) ||
                        'pconsultardblink       => ''' || pconsultardblink       || ''',' ||CHR(13) ||
                        'pcontaordem            => ''' || pcontaordem            || ''',' || chr(13) ||
                        'pValorICMSPartilhaRem => ''' || pValorICMSPartilhaRem || CHR(13) ;

    Imposto.Cliente   := FERRAMENTAS.BUSCAR_CLIENTE(pCODCLI, psCodFilialNF);
    Imposto.Cnae      := BUSCAR_CNAE(Imposto.Cliente.CodCnae);
    Imposto.Produto   := BUSCAR_PRODUTO(pCODPROD);
    Imposto.Embalagem := BUSCAR_EMBALAGEM(pCODPROD
                                         ,pCodAuxiliar
                                         ,NVL(psCodFilialRetira
                                             ,psCodFilial));
    Imposto.Filial    := BUSCAR_FILIAL(psCodFilial);
    Imposto.FilialNF  := BUSCAR_FILIAL(NVL(psCodFilialNF, psCodFilial));

    Imposto.Parametros132.tipoaliqoutrasdesp     := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOALIQOUTRASDESP'
                                                                                      ,'99'
                                                                                      ,'P');
    Imposto.Parametros132.aliqicmoutrasdesp      := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_ALIQICMOUTRASDESP'
                                                                                     ,'99'
                                                                                     ,0);
    Imposto.Parametros132.aliqicminteroutrasdesp := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_ALIQICMINTEROUTRASDESP'
                                                                                     ,'99'
                                                                                     ,0);
    Imposto.Parametros132.calcstpf               := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CALCSTPF'
                                                                                      ,'99'
                                                                                      ,'S');
    Imposto.Parametros132.consideraisentoscomopf := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CONSIDERAISENTOSCOMOPF'
                                                                                      ,'99'
                                                                                      ,'N');
    Imposto.Parametros132.UtilizaPercBaseredPF   := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZAPERCBASEREDPF'
                                                                                      ,'99'
                                                                                      ,'N');
    Imposto.Parametros132.AceitaPFContribuinte   := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ACEITAPFCONTRIBUINTE'
                                                                                      ,'99'
                                                                                      ,'N');
    Imposto.Parametros132.NumCasasDecimais            := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA','99',2);
    Imposto.Parametros132.txvenda            := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_TXVENDA'
                                                                                 ,'99'
                                                                                 ,0);
    Imposto.Parametros132.tipocalcst         := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOCALCST'
                                                                                  ,'99'
                                                                                  ,'PV');
    Imposto.Parametros132.percicmfrete       := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_PERCICMFRETE'
                                                                                 ,'99'
                                                                                 ,0);
    Imposto.Parametros132.percicminterfrete  := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_PERCICMINTERFRETE'
                                                                                 ,'99'
                                                                                 ,0);
    Imposto.Parametros132.mostrarpvendasemst := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_MOSTRARPVENDASEMST'
                                                                                  ,'99'
                                                                                  ,'N');
    Imposto.Parametros132.usaTributacaoPorUF := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF'
                                                                                  ,'99'
                                                                                  ,'N');
    Imposto.Parametros132.ValidarIpiPor      := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDARIPIPOR'
                                                                                  ,'99'
                                                                                  ,'V');

    Imposto.Parametros132.CalcularIPIVenda         := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_CALCULARIPIVENDA'
                                                                                        ,CASE
                                                                                          Imposto.Parametros132.ValidarIpiPor
                                                                                           WHEN 'V' THEN
                                                                                            psCodFilial
                                                                                           WHEN 'N' THEN
                                                                                            NVL(psCodFilialNF
                                                                                               ,psCodFilial)
                                                                                         END
                                                                                        ,'N');
    Imposto.Parametros132.RetiraIpiPedidoTV8       := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('RETIRAIPIPEDIDOTV8'
                                                                                        ,'99'
                                                                                        ,'N');
    Imposto.Parametros132.CALCULARSTCOMIPI         := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CALCULARSTCOMIPI'
                                                                                        ,'99'
                                                                                        ,'N');
    Imposto.Parametros132.UsarTributacaoTransfTV10 := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA( 'USARTRIBTRANSFVENDA10'
                                                                                           ,psCodFilial
                                                                                           ,FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USARTRIBUTACAOTRANSFTV10'
                                                                                                                               ,'99'
                                                                                                                               ,'N'));

    Imposto.Parametros132.USADESCSIMPLESNAC        := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC'
                                                                                        ,psCodFilial
                                                                                        ,'N');

    Imposto.Produto.ProdutoFilial := BUSCAR_PRODUTO_FILIAL(pCodProd
                                                          ,CASE
                                                            Imposto.Parametros132.ValidarIpiPor
                                                             WHEN 'V' THEN
                                                              psCodFilial
                                                             WHEN 'N' THEN
                                                              NVL(psCodFilialNF
                                                                 ,psCodFilial)
                                                           END);

    Imposto.Parametros132.ConsideraPrecoSemDescCalcIpi := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONSIDERAPSDCALCIPI'
                                                                                             ,psCodFilial
                                                                                             ,'N');

    Imposto.Parametros132.PrecoPorEmbalagem := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM'
                                                                                             ,psCodFilial
                                                                                             ,'N');

    Imposto.Parametros132.UtilizaTribEndEnt  := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZATRIBENDENT'
                                                                                  ,psCodFilial
                                                                                  ,'N');

    Imposto.Parametros132.CALCULAIPICUPOMFISCAL := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCULAIPICUPOMFISCAL',
                                                                                      psCodFilial,
                                                                                      'S');

    Imposto.Parametros132.ConsVlUltEntContSSTPrecific := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONSVLULTENTCONTSSTPRECIFICVENDA',
                                                                                            psCodFilial,
                                                                                            'N');

    vnnumregiao                   := Imposto.Cliente.numregiao;

    Imposto.Bonificacao := BUSCAR_BONIFICACAO(pCodBnf); --HIS.03069.2016

    Imposto.EnderecoEntrega := BUSCAR_ENDERECO_ENTREGA(pCodEndEnt);


    if (Imposto.Parametros132.UtilizaTribEndEnt = 'S') AND
       (Imposto.EnderecoEntrega.NumRegiao > 0)
    THEN
      vnnumregiao := Imposto.EnderecoEntrega.NUMREGIAO;
    END IF;

    IF vnnumregiao = 0 THEN
      vnnumregiao := Imposto.Cliente.numregiao;
    END IF;


    Imposto.Praca        := BUSCAR_PRACA(Imposto.Cliente.CodPraca);
    Imposto.Praca.Regiao := BUSCAR_REGIAO(vnnumregiao);


    BEGIN
      SELECT NVL(PCPRECOPROM.CONSIDERAPRECOSEMIMPOSTO, 'N'),
             NVL(PCPRECOPROM.Aplicadescontosimples, 'N')
        INTO vsConsideraPrecoFixoSemImposto,vsAplicaDescSimplesPrecoFixo
        FROM PCPRECOPROM
       WHERE PCPRECOPROM.CODPRECOPROM = pCodPrecoFixo;
    EXCEPTION
      WHEN OTHERS THEN
        vsConsideraPrecoFixoSemImposto := 'N';
        vsAplicaDescSimplesPrecoFixo   := 'N';
    END;

    /*IF (Imposto.Produto.PrecoFixo = 'S') then
       vsConsideraPrecoFixoSemImposto := 'S';
    END IF;*/
    IF psOrigemPedido in ('B', 'R') THEN
      if Imposto.Filial.UF = Imposto.Cliente.estent then
        if (Imposto.Filial.UsaRegiaoFilialVendaEstadual = 'S') and
           (Imposto.Filial.NumRegiaoPadrao > 0) then

          vnnumregiao := Imposto.Filial.NumRegiaoPadrao;
          SELECT pctabpr.codst
            INTO vncodst
            FROM pctabpr
           WHERE pctabpr.codprod = pCodProd
             AND pctabpr.numregiao = vnnumregiao;
        end if;

      else

        if (Imposto.Filial.UsaRegiaoFilialVendaInter = 'S') and
           (Imposto.Filial.NumRegiaoPadraoInter > 0) then

          vnnumregiao := Imposto.Filial.NumRegiaoPadraoInter;
          SELECT pctabpr.codst
            INTO vncodst
            FROM pctabpr
           WHERE pctabpr.codprod = pCodProd
             AND pctabpr.numregiao = vnnumregiao;
        end if;
      end if;
    END IF;

    IF ((Imposto.Parametros132.usaTributacaoPorUF = 'S') and ((pRetiraImposto201 IN ('N','I') or (pCodPrecoFixo > 0)))) or
       ((Imposto.Parametros132.usaTributacaoPorUF = 'S') and (Imposto.Parametros132.PrecoPorEmbalagem = 'S')) THEN /*1532.081003.2016*/

      IF ((psCodFilialNF IS NOT NULL) or (NVL(Imposto.Cliente.CodFilialNF, '99') <> '99' )) THEN
        vsCodFilial := NVL(psCodFilialNF, Imposto.Cliente.CodFilialNF);
      ELSE
        vsCodFilial := psCodFilial;
      END IF;

      SELECT pctabtrib.codst
        INTO vncodst
        FROM pctabtrib
       WHERE pctabtrib.codprod = pCodProd
         AND pctabtrib.ufdestino = CASE WHEN (Imposto.Parametros132.UtilizaTribEndEnt = 'S') AND
                                             (Imposto.EnderecoEntrega.EstEnt IS NOT NULL)
                                        THEN
                                          Imposto.EnderecoEntrega.EstEnt

                                        ELSE
                                          Imposto.Cliente.estent
                                        END
         AND pctabtrib.codfilialnf = vsCodFilial;

      -----------------------------------------------------------
      --Autor: Rafael Braga
      --Solicitação: 5043.014499.2015
      --Data: 19/02/2015
      --Descrição: Retirando impostos conforme definidos na 201.
      -----------------------------------------------------------
    ELSIF (Imposto.Parametros132.usaTributacaoPorUF = 'S') and
          (pRetiraImposto201 = 'S') THEN
      begin
        SELECT NVL(PCTRIBUT.CODST, 0) CODST_PRECIFICACAO
          INTO vnCODST
          FROM PCREGIAO,
               PCTABPR,
               PCTRIBUT,
               PCEST EST,
               PCPRODUT,
               PCFILIAL,
               PCFORNEC,
               PCPRODFILIAL,
               PCCONSUM,
               PCTABTRIB
         WHERE ((PCREGIAO.STATUS NOT IN ('I')) OR (PCREGIAO.STATUS IS NULL))
               AND PCTABPR.CODPROD = PCPRODUT.CODPROD
               AND PCTABPR.NUMREGIAO = PCREGIAO.NUMREGIAO
               AND PCTABPR.CODPROD = pCodProd
               AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC
               AND PCPRODFILIAL.CODPROD = EST.CODPROD
               AND PCPRODFILIAL.CODFILIAL = EST.CODFILIAL
               AND EST.CODFILIAL = PCFILIAL.CODIGO
               AND PCTABPR.CODPROD = EST.CODPROD
               AND EST.CODFILIAL = NVL(psCodFilialNF,psCodFilial)
               AND (PCTABTRIB.CODFILIALNF =
               DECODE(NVL(PCREGIAO.CODFILIAL, '99')
                          ,'99'
                          ,EST.CODFILIAL
                          ,PCREGIAO.CODFILIAL))
               AND PCTABTRIB.UFDESTINO = PCREGIAO.UF
               AND PCTABTRIB.CODPROD = PCTABPR.CODPROD
               AND PCTABTRIB.CODST = PCTRIBUT.CODST
               AND PCTABPR.NUMREGIAO = vnnumregiao;
                EXCEPTION
        WHEN NO_DATA_FOUND THEN
          begin
            SELECT NVL(PCTRIBUT.CODST, 0) CODST_PRECIFICACAO
            INTO vnCODST
            FROM PCREGIAO,
                 PCTABPR,
                 PCTRIBUT,
                 PCEST EST,
                 PCPRODUT,
                 PCFILIAL,
                 PCFORNEC,
                 PCPRODFILIAL,
                 PCCONSUM,
                 PCTABTRIB
           WHERE ((PCREGIAO.STATUS NOT IN ('I')) OR (PCREGIAO.STATUS IS NULL))
                 AND PCTABPR.CODPROD = PCPRODUT.CODPROD
                 AND PCTABPR.NUMREGIAO = PCREGIAO.NUMREGIAO
                 AND PCTABPR.CODPROD = pCodProd
                 AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC
                 AND PCPRODFILIAL.CODPROD = EST.CODPROD
                 AND PCPRODFILIAL.CODFILIAL = EST.CODFILIAL
                 AND EST.CODFILIAL = PCFILIAL.CODIGO
                 AND PCTABPR.CODPROD = EST.CODPROD
                 AND EST.CODFILIAL = NVL(psCodFilialNF,psCodFilial)
                 AND (PCTABTRIB.CODFILIALNF = EST.CODFILIAL)
                 AND PCTABTRIB.UFDESTINO = PCREGIAO.UF
                 AND PCTABTRIB.CODPROD = PCTABPR.CODPROD
                 AND PCTABTRIB.CODST = PCTRIBUT.CODST
                 AND PCTABPR.NUMREGIAO = vnnumregiao;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             SELECT NVL(PCTRIBUT.CODST, 0) CODST_PRECIFICACAO
            INTO vnCODST
            FROM PCREGIAO,
                 PCTABPR,
                 PCTRIBUT,
                 PCEST EST,
                 PCPRODUT,
                 PCFILIAL,
                 PCFORNEC,
                 PCPRODFILIAL,
                 PCCONSUM,
                 PCTABTRIB
           WHERE ((PCREGIAO.STATUS NOT IN ('I')) OR (PCREGIAO.STATUS IS NULL))
                 AND PCTABPR.CODPROD = PCPRODUT.CODPROD
                 AND PCTABPR.NUMREGIAO = PCREGIAO.NUMREGIAO
                 AND PCTABPR.CODPROD = pCodProd
                 AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC
                 AND PCPRODFILIAL.CODPROD = EST.CODPROD
                 AND PCPRODFILIAL.CODFILIAL = EST.CODFILIAL
                 AND EST.CODFILIAL = PCFILIAL.CODIGO
                 AND PCTABPR.CODPROD = EST.CODPROD
                 AND EST.CODFILIAL = NVL(psCodFilialNF,psCodFilial)
                 AND (PCTABTRIB.CODFILIALNF = EST.CODFILIAL)
                 AND PCTABTRIB.UFDESTINO = Imposto.Cliente.estent
                 AND PCTABTRIB.CODPROD = PCTABPR.CODPROD
                 AND PCTABTRIB.CODST = PCTRIBUT.CODST
                 AND PCTABPR.NUMREGIAO = vnnumregiao;
        END;
      END;
      --5043.014499.2015

    ELSE
      SELECT pctabpr.codst
        INTO vncodst
        FROM pctabpr
       WHERE pctabpr.codprod = pCodProd
             AND pctabpr.numregiao = vnnumregiao;

    END IF;

    IF (pVendaTriangular = 'S') AND
       (pRetiraImposto201 IN ('N', 'I'))
    THEN
      BEGIN
        SELECT CODFIGVENDATRIANGULAR
          INTO vnCodStVendaTriang
          FROM PCTRIBUT
         WHERE CODST = vncodst;
      EXCEPTION
        WHEN OTHERS THEN
          vnCodStVendaTriang := 0;
      END;

      if vnCodStVendaTriang > 0 THEN
        vnCodSt := vnCodStVendaTriang;
      END IF;
    END IF;

    vsTIPOST := ferramentas.VERIFICAR_TIPOST(Imposto.Cliente.CodCli
                                            ,vncodst);

    Imposto.Tributacao   := BUSCAR_TRIBUTACAO(vncodst);
	IF (pRetiraImposto201 = 'N') THEN
		Imposto.Tributacao :=  VerificaPautaProdutUF(Imposto,pCodProd,Imposto.Cliente.estent);
	END IF;	
    Imposto.Precificacao := BUSCAR_PRECIFICACAO(pCodProd, vnnumregiao, pconsultardblink);
    Imposto.Estoque      := BUSCAR_ESTOQUE(pCodProd, psCodFilial);

    Imposto.Estoque.VALORULTENT := COALESCE((CASE WHEN Imposto.Parametros132.ConsVlUltEntContSSTPrecific = 'S' THEN
                                               CASE WHEN nvl(Imposto.Precificacao.VlUltEntContSemSt, 0) = 0 THEN
                                                 Imposto.Estoque.VALORULTENT
                                               ELSE
                                                 Imposto.Precificacao.VlUltEntContSemSt
                                               END
                                              ELSE
                                                Imposto.Estoque.VALORULTENT
                                             END),
                                             0);

    -------------- DADOS DE PEDIDO -----------------
    Imposto.Pedido.CondVenda            := pCondVenda;
    Imposto.Pedido.RotinaConsum         := pRotinaConsum;
    Imposto.Pedido.OrigemPedido         := psOrigemPedido;
    Imposto.Pedido.VendaTriangular      := pVendaTriangular;
    Imposto.Pedido.VendaExportacao      := psVendaExportacao;
    Imposto.Pedido.Transferencia        := pTransferencia;
    Imposto.Pedido.TransferenciaVirtual := pTransferenciaVirtual;
    Imposto.Pedido.CodEnderecoEntrega   := pCodEndEnt;
    Imposto.Pedido.TipoDocumento        := pTipoDocumento;
    Imposto.ItemPedido.VLICMSPARTREM    := pValorICMSPartilhaRem;
    -------------- DADOS DE PEDIDO -----------------

    -----VALIDAÇÃO SE O IPI ENTRARÁ NO CALCULO DO ST2------------
    vbConsiderarIpiAliqicms2 := FALSE;
    if (Imposto.Cliente.ConsumidorFinal = 'S') and
       ((Imposto.Produto.Importado = 'S') or
       (Imposto.Produto.Importado = 'D')) and
       (Imposto.Filial.UF <> Imposto.Cliente.EstEnt) and
       (Imposto.Tributacao.AgregarIpiCalculoST = 'S') and
       (pRetiraImposto201 IN ('N','I')) then
      vbConsiderarIpiAliqicms2 := True;
    END IF;
    -----FIM VALIDAÇÃO SE O IPI ENTRARÁ NO CALCULO DO ST2------------

    --- PERCENTUAL BASE DE REDUÇÃO DE ST
    IF (NVL(Imposto.Tributacao.PercRedPvendaSimplesnac, 0) = 0) or
       (Imposto.Parametros132.USADESCSIMPLESNAC = 'S') or
       (Imposto.Cliente.SimplesNacional = 'N')
     THEN
      vnPercentualdeRedSimplesNac := 100;
    ELSE
      vnPercentualdeRedSimplesNac := Imposto.Tributacao.PercRedPvendaSimplesnac;
    END IF;
    --- FIM PERCENTUAL BASE DE REDUÇÃO DE ST

    --vnPrecoSemImposto := pPvenda;
    vnIVA   := Imposto.Tributacao.Iva;
    vnPauta := Imposto.Tributacao.Pauta;
    vFECP201 := Imposto.Precificacao.VLFCPST;

    IF (NVL(Imposto.Filial.UtilizaVendaporEmbalagem, 'N') = 'S') AND
       (Imposto.Embalagem.QTUNIT > 0) AND (pRotinaConsum <> 'I') THEN
      VnIpiPorKGVenda := Imposto.Produto.VlIpiPorKGVenda *
                         Imposto.Embalagem.QTUNIT;
      VnPesoBruto     := Imposto.Produto.PesoBruto *
                         Imposto.Embalagem.QTUNIT;
      vnPautaIpi      := Imposto.Produto.VlPautaIpi *
                         Imposto.Embalagem.QTUNIT;
      vnPauta         := (vnPauta) * Imposto.Embalagem.QTUNIT;
      VnValorUltEnt   := Imposto.Estoque.VALORULTENT *
                         Imposto.Embalagem.QTUNIT;
      VnUltEntMes     := Imposto.Precificacao.VlUltEntMes *
                         Imposto.Embalagem.QTUNIT;
    ELSE

      VnIpiPorKGVenda := Imposto.Produto.VlIpiPorKGVenda;
      VnPesoBruto     := Imposto.Produto.PesoBruto;
      vnPautaIpi      := Imposto.Produto.VlPautaIpi;
      VnValorUltEnt   := Imposto.Estoque.VALORULTENT;
      VnUltEntMes     := Imposto.Precificacao.VlUltEntMes;
    END IF;

    ----- VERIFICA SE O CLIENTE É ISENTO DE IPI ---------
    vsIsentoIPI := Imposto.Cliente.isentoIPI;
    vnPercIPI   := Imposto.Produto.percipi;

    IF (((Imposto.Cliente.sulframa IS NOT NULL) AND
       (Imposto.Produto.importado = 'N')) OR
       (Imposto.Cliente.tipoPessoa = 'E')) THEN
      vsIsentoIPI := 'S';
    END IF;

    IF ((Imposto.Cliente.EstEnt = 'EX') OR (psVendaExportacao = 'S')) and
       (pVendaLocalEstrangeira = 'N')
    THEN
      vsIsentoIPI := 'S';
    END IF;

    IF (Imposto.Parametros132.RetiraIpiPedidoTV8 = 'S') AND
       (pCondVenda = 8) THEN
      vsIsentoIPI := 'S';
    END IF;

    -----------------------------------------------------------
    --Autor: Rafael Braga
    --Solicitação: 241.015248.2015
    --Data: 16/06/2015
    --Descrição: Ajuste para ST Fonte ao mostrar preço sem impostos.
    -----------------------------------------------------------
    if (vsConsideraPrecoFixoSemImposto = 'S') and (pCodPrecoFixo > 0) and
       (pRetiraImposto201 = 'S') then
      vsIsentoIPI := 'S';
    END IF;

    -----FIM VERIFICA SE O CLIENTE É ISENTO DE IPI ---------

    -----------------------------------------------------------
    --Autor: Rafael Braga
    --Solicitação: 241.015248.2015
    --Data: 16/02/2015
    --Descrição: Ajuste para ST Fonte ao mostrar preço sem impostos.
    -----------------------------------------------------------

    IF ((vsIsentoIPI = 'S') AND (pFoiPrecificadoIPI <> 'P')) and
       ((pRetiraImposto201 IN ('N','I')) or
       ((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0))) THEN
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    END IF;
    -----------------------------------------------------------

    IF (((pFoiPrecificadoIPI = 'N') or (vsIsentoIPI = 'S')) and
       (pRetiraImposto201 IN ('N','I'))) and
       (not (((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)) and
        (((Imposto.Parametros132.CalcularIPIVenda = 'S') AND
        (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
        (Imposto.Produto.ProdutoFilial.CalculaIpi = 'S')) AND
        (vsConsideraPrecoFixoSemImposto = 'N'))) THEN
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    END IF;

    if (((Imposto.Parametros132.CalcularIPIVenda = 'N') AND
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'N')) AND
       (pFoiPrecificadoIPI = 'P') AND (pRetiraImposto201 = 'S') then
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    End if;

    if (Imposto.Precificacao.VLIPI = 0) AND (pFoiPrecificadoIPI <> 'P') AND
       (pRetiraImposto201 = 'S') AND
       (not (((Imposto.Produto.PrecoFixo = 'S') or (nvl(pCodPrecoFixo,0) > 0)) and
        (vsConsideraPrecoFixoSemImposto = 'N'))) then
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    End if;

    if (((Imposto.Parametros132.CalcularIPIVenda = 'N') AND
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'N')) AND
       (pRetiraImposto201 IN ('N','I')) then
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    End if;

    if (((Imposto.Produto.PrecoFixo = 'S') OR (pCodPrecoFixo > 0)) and
       (((Imposto.Parametros132.CalcularIPIVenda = 'N') AND
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'N'))) then
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    end if;

    if (pUtilizaCustoVendaTV10 = 'S') and (pRetiraImposto201 = 'S') then
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    End if;

    -----------------------------------------------------------
    --Autor: Rafael Soares
    --Solicitação: HIS.00288.2016
    --Data: 16/02/2016
    --Descrição: Não retirar o IPI do preço quando a região da venda não possuir IPI
    -----------------------------------------------------------
    if (Imposto.Precificacao.CALCULARIPI = 'N') and
       (pRetiraImposto201 IN ('N','I'))then
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    end if;
    -----------------------------------------------------------

    --HIS.03069.2016
    IF (pCodBnf > 0) AND (Imposto.Bonificacao.CALCULAIPI = 'N')  and
       (pRetiraImposto201 IN ('N','I')) THEN
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    END IF;
    ------

    IF (Imposto.Pedido.TipoDocumento = 'C') AND
       (Imposto.Parametros132.CALCULAIPICUPOMFISCAL = 'N') AND
       (pRetiraImposto201 IN ('N','I')) THEN
      vnpercipi       := 0;
      vnPautaIpi      := 0;
      VnIpiPorKGVenda := 0;
    END IF;

    IF (Imposto.Parametros132.ConsideraPrecoSemDescCalcIpi = 'S') AND
       (pPtabela > 0) AND
       (pRetiraImposto201 IN ('N','I')) AND
       (OBTERPRECOUTILIZADONFE(nvl(psCodFilialNF,
                                   psCodFilial),
                               pCodCli,
                               pCodProd) = 'B')
    THEN
      vnPautaIpi := nvl(pPtabela * (vnpercipi/100)
                       ,0);

      vnPercipi  := 0;
    END IF;

    --------- ** HIS.02902.2016 -----------------------------
    if (Imposto.Produto.vlIpiPautaTV10 > 0) AND
       (pRetiraImposto201 in ('N', 'I')) AND
       (pCondVenda = 10)
    THEN
      vnPautaIpi := Imposto.Produto.VlIpiPautaTV10;

      vnPercIpi  := 0;
    END IF;

    /**
      Tarefa    : HIS.02641.2017
      Descrição : Quando tiver efetuado o calculo para obter o preço da venda sem imposto,
                  utilizar o percentual de acréscimo na base do IPI, para chegar ao valor correto do preço
                  sem imposto
    **/
    IF (((Imposto.Parametros132.CalcularIPIVenda = 'S') AND
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'S')) AND
       (((pRetiraImposto201 IN ('N','I'))) OR
       ((pRetiraImposto201 = 'S') AND
       (((Imposto.Produto.PrecoFixo = 'S') OR (pCodPrecoFixo > 0)) or (pUtilizaCustoVendaTV10 = 'S')))) AND
       (pCondVenda = 10) AND
       (Imposto.Produto.ProdutoFilial.peracresBaseIPI > 0) THEN
       vnpercipi := NVL((vnpercipi * (1 + (Imposto.Produto.ProdutoFilial.peracresBaseIPI / 100)))
                      ,0);
    END IF;


    /***
        Autor : Guilherme Freitas
       Tarefa : HIS.01467.2015
         Data : 07/05/2015
    Descrição : Quando tiver efetuando o cálculo para obter o preço de venda sem impostos,
                utilizar a alíquota de IPI reduzida, para chegar ao valor correto do preço
                sem imposto.
      ***/

    IF (((Imposto.Parametros132.CalcularIPIVenda = 'S') AND
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
       (Imposto.Produto.ProdutoFilial.CalculaIpi = 'S')) AND
       (((pRetiraImposto201 IN ('N','I'))) OR
       ((pRetiraImposto201 = 'S') AND
       (((Imposto.Produto.PrecoFixo = 'S') OR (pCodPrecoFixo > 0)) or (pUtilizaCustoVendaTV10 = 'S')))) AND
       (Imposto.Produto.AplicaPercRedAliqIpi = 'S') THEN

      vnpercipi := NVL((vnpercipi * (1 -
                       (Imposto.Cliente.RamoAtividade.PercRedAliqIPi / 100)))
                      ,0);
    END IF;

    if (Imposto.Cliente.SimplesNacional = 'S') AND
       (Imposto.Cliente.CalculaSt = 'S') AND (pRetiraImposto201 IN ('N','I')) AND
       (Imposto.Parametros132.USADESCSIMPLESNAC = 'N') and
       ((not((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0))) or ((((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0))) and (vsAplicaDescSimplesPrecoFixo = 'S'))) and
       (Imposto.Tributacao.UtilizaMotorCalculo = 'N')
       THEN
      vnIVA := vnIVA * (vnPercentualdeRedSimplesNac / 100);
    END IF;

    vsIsentoST           := 'N';
    vnAliquota1Calculada := 0;
    vnAliquota2Calculada := 0;
    vnAliqIcmsFecp       := 0;

    --Cliente isento de ST
    if (Imposto.Cliente.CalculaSt = 'N') and
       ((pRetiraImposto201 IN ('N','I')) or
       ((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)))
       and (vsTIPOST <> 'ST FONTE') THEN
      vsIsentoST := 'S';
    END IF;

    -----------------------------------------------------------
    --Autor: Rafael Braga
    --Solicitação: 241.015248.2015
    --Data: 16/06/2015
    --Descrição: Ajuste para ST Fonte ao mostrar preço sem impostos.
    -----------------------------------------------------------

    if (vsConsideraPrecoFixoSemImposto = 'S') and (pCodPrecoFixo > 0) and
       (pRetiraImposto201 = 'S') then
      vsISENTOST := 'S';
    END IF;

    --Cálcula ST p/ Pessoa Física
    if (Imposto.Parametros132.calcstpf = 'N') AND
        ((pRetiraImposto201 IN ('N','I') or
         ((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)))) then
      if Imposto.Cliente.PessoaFisicaJuridica = 'PESSOA FISICA' then
        vsIsentoST := 'S';
      END IF;
    END IF;

    --Nâo calcula ST Pelo Ramo de Atividade
    IF ((Imposto.Produto.VerificRamoAtiviCalcST = 'S') AND
       (Imposto.Cliente.RamoAtividade.CalculaST = 'N')) AND
       (pRetiraImposto201 IN ('N','I')) then
      vsIsentoST := 'S';
    END IF;

    Imposto.Produto.ProdutoFilial := BUSCAR_PRODUTO_FILIAL(Imposto.Produto.Codprod
                                                          ,NVL(psCodFilialRetira ,psCodFilial));

    IF ((Imposto.Produto.ProdutoFilial.Relevante = 'N') AND
        (pRetiraImposto201 in ('N', 'I')))
    THEN
      vsIsentoST := 'S';
    END IF;

    /**** HIS.01187.2017 *****/
    IF ((Imposto.Produto.IsentoSTClienteCozinaInd = 'S') and
        (Imposto.Cliente.CozinhaIndustrial = 'S') ) and
        (pRetiraImposto201 in ('N', 'I'))
    THEN
      vsIsentoST := 'S';
    END IF;
    /**** HIS.01187.2017 *****/

    IF ((pSTPrecificado) > 0 or pRetiraImposto201 in ('N', 'I') OR
      ( pRetiraImposto201 in ('S') and ((vFECP201 > 0 and
      (Imposto.Precificacao.CALCULARFECPSTVENDA = 'S') ) or pSTPrecificado > 0) ))
      AND (vsIsentoST = 'N') THEN
      vnAliquota1Calculada := Imposto.Tributacao.AliqIcms1;
      vnAliquota2Calculada := Imposto.Tributacao.AliqIcms2;
      vnAliqIcmsFecp       := Imposto.Tributacao.ALIQICMSFECP;
    END IF;

     --- PERCENTUAL BASE DE REDUÇÃO DE ST
    IF (vsTIPOST = 'ST FONTE') AND ((pRetiraImposto201 in('N'))  OR (pCodPrecoFixo > 0)) THEN
      IF NVL(Imposto.Tributacao.PercBaseRedSTFonte,0) = 0 THEN
        vnPercentualdeReducaoBaseST := 100;
      ELSE
        vnPercentualdeReducaoBaseST := Imposto.Tributacao.PercBaseRedSTFonte;
      END IF;
    ELSE
      IF NVL(Imposto.Tributacao.PercBaseRedST,0) = 0 THEN
        vnPercentualdeReducaoBaseST := 100;
      ELSE
        vnPercentualdeReducaoBaseST := Imposto.Tributacao.PercBaseRedST;
      END IF;
    END IF;

    IF (vsTIPOST = 'ST FONTE') AND (pRetiraImposto201 in('N')) THEN
     IF (Imposto.Cliente.Isentoicms = 'S') or (pCondVenda = 7) then
          vnPercentualdeReducaoBaseST := 100;
        END IF;
    END IF;

    if (((Imposto.Parametros132.UsarTributacaoTransfTV10 = 'S') and
       (pCondVenda = 10) AND (pRetiraImposto201 IN ('N','I'))) OR
        (pTransferencia = 'S')) and (vsIsentoST = 'N') then
      vnIVA                       := nvl(Imposto.Tributacao.IvaTransf, 0);
      vnPauta                     := nvl(Imposto.Tributacao.PautaTransf, 0);
      vnAliquota1Calculada        := nvl(Imposto.Tributacao.Aliqicms1transf ,0);
      vnAliquota2Calculada        := nvl(Imposto.Tributacao.Aliqicms2transf ,0);
      vnPercentualdeReducaoBaseST := nvl(Imposto.Tributacao.PercBaseRedSTTransf ,0);
      vnAliqIcmsFecp              := nvl(Imposto.Tributacao.ALIQICMSFECP,0);
      Imposto.Tributacao.TipoCalculoGnre := nvl(Imposto.Tributacao.TipoCalculoGNRETransf,'P');

      IF vnPercentualdeReducaoBaseST = 0 THEN
        vnPercentualdeReducaoBaseST := 100;
      END IF;
    end if;

    --// HIS.04219.2017, para atender a logistica //--
    IF Imposto.Parametros132.UTILIZARTRIBUTEAJUSTEESTOQUE = 'S' AND
       pRotinaConsum = 'L' THEN
      vnIVA                       := nvl(Imposto.Tributacao.iva_mc, 0);
      vnPauta                     := nvl(Imposto.Tributacao.pauta_mc, 0);
      vnAliquota1Calculada        := nvl(Imposto.Tributacao.ALIQICMS1_MC,0);
      vnAliquota2Calculada        := nvl(Imposto.Tributacao.ALIQICMS2_MC,0);
      vnPercentualdeReducaoBaseST := nvl(Imposto.Tributacao.PERCBASEREDST_MC,0);
      vnPercRedIcms               := nvl(Imposto.Tributacao.PERCBASERED_MC,0);
      vnAliqIcmsFecp              := nvl(Imposto.Tributacao.ALIQICMSFECP,0);
    END IF;
    --==============================================--

    if (pTransferenciaVirtual = 'S') then --pTransferencia indica que é transferencia virtual
      if (nvl(Imposto.Tributacao.IvaTransfVirt, Imposto.Tributacao.IVATRANSF) is not null) and
         (nvl(Imposto.Tributacao.Aliqicms1transfVirt, Imposto.Tributacao.ALIQICMS1TRANSF) is not null) and
         (nvl(Imposto.Tributacao.Aliqicms2transfVirt, Imposto.Tributacao.ALIQICMS2TRANSF) is not null) then
        vnIVA                     := nvl(Imposto.Tributacao.IvaTransfVirt, Imposto.Tributacao.IVATRANSF);
        vnAliquota1Calculada      := nvl(Imposto.Tributacao.Aliqicms1transfVirt, Imposto.Tributacao.ALIQICMS1TRANSF);
        vnAliquota2Calculada      := nvl(Imposto.Tributacao.Aliqicms2transfVirt, Imposto.Tributacao.ALIQICMS2TRANSF);
        vnAliqIcmsFecp              := nvl(Imposto.Tributacao.ALIQICMSFECP,0);
      end if;

      if (nvl(Imposto.Tributacao.PautaTransfVirt, Imposto.Tributacao.PAUTATRANSF) is not null) then
        vnPauta                   := nvl(Imposto.Tributacao.PautaTransfVirt, Imposto.Tributacao.PAUTATRANSF);
      end if;

      if (nvl(Imposto.Tributacao.PercBaseRedSTTransfVirt, Imposto.Tributacao.PercBaseRedSTTransf) is not null) then
        vnPercentualdeReducaoBaseST  := nvl(Imposto.Tributacao.PercBaseRedSTTransfVirt, Imposto.Tributacao.PercBaseRedSTTransf);
      end if;

    end if;


    if (pUtilizaCustoVendaTV10 = 'S') and (pRetiraImposto201 = 'S') then
      vnAliquota1Calculada := 0;
      vnAliquota2Calculada := 0;
      vnAliqIcmsFecp       := 0;
    End if;

    /***************************************************************************/
    IF (Imposto.Cliente.SimplesNacional = 'S') AND
       (nvl(Imposto.Tributacao.PercRedBaseStCliSN, 0) > 0) AND
       (pRetiraImposto201 IN ('N', 'I'))
    THEN
      vnPercentualdeReducaoBaseST := Imposto.Tributacao.PercRedBaseStCliSN;
    END IF;
    /****************************************************************************/
    --- FIM PERCENTUAL BASE DE REDUÇÃO DE ST

    IF (vsTIPOST = 'ST FONTE') and (vnPauta > 0) and (Imposto.Tributacao.UtilizaMotorCalculo = 'N') then
        vnPauta := 0;
    END IF;

    /*IF (NVL(Imposto.Filial.UtilizaVendaporEmbalagem,'N') = 'S') AND (Imposto.Embalagem.QTUNIT > 0) THEN
       VnIpiPorKGVenda :=  Imposto.Produto.VlIpiPorKGVenda * Imposto.Embalagem.QTUNIT;
       VnPesoBruto     :=  Imposto.Produto.PesoBruto * Imposto.Embalagem.QTUNIT;
       vnPautaIpi      :=  Imposto.Produto.VlPautaIpi * Imposto.Embalagem.QTUNIT;
       vnPauta         :=  vnPauta * Imposto.Embalagem.QTUNIT;
       VnValorUltEnt   :=  Imposto.Estoque.VALORULTENT * Imposto.Embalagem.QTUNIT;
       VnUltEntMes     :=  Imposto.Precificacao.VlUltEntMes * Imposto.Embalagem.QTUNIT;
    ELSE

       VnIpiPorKGVenda :=  Imposto.Produto.VlIpiPorKGVenda;
       VnPesoBruto     :=  Imposto.Produto.PesoBruto;
       vnPautaIpi      :=  Imposto.Produto.VlPautaIpi;
       VnValorUltEnt   :=  Imposto.Estoque.VALORULTENT;
       VnUltEntMes     :=  Imposto.Precificacao.VlUltEntMes;
    END IF;*/ -- Removido para não retirar o imposto duas vezes

    -----------------------------------------------------------
    --Autor: Rafael Braga
    --Solicitação: 3805.127888.2014
    --Data: 15/12/2014
    --Descrição: Ajuste para ST Fonte no simples nacional.
    -----------------------------------------------------------

    if (vsTIPOST = 'ST FONTE') and
       ((pRetiraImposto201 IN('N')) OR
       ((pCodPrecoFixo > 0) AND (vsConsideraPrecoFixoSemImposto = 'N'))) then
      case
        when Imposto.Cliente.UsaivaFonteDiferenciado = 'S' and Imposto.Cliente.IvaFonte is not null then
          vnIVA := Imposto.Cliente.IvaFonte;

        when Imposto.Cliente.UsaivaFonteDiferenciado = 'N' or Imposto.Cliente.IvaFonte is null then
          vnIVA := Imposto.Tributacao.IvaFonte;

        when Imposto.Cliente.UsaivaFonteDiferenciado = 'M' and Imposto.Cliente.IvaFonte is not null  then
          vnIVA := greatest(Imposto.Tributacao.IvaFonte
                           ,Imposto.Cliente.IvaFonte);

        else
          vnIVA := Imposto.Tributacao.IvaFonte;

      end case;

      IF (Imposto.Cliente.SimplesNacional = 'S') AND
         (Imposto.Parametros132.USADESCSIMPLESNAC = 'N') AND
         (vnPercentualdeRedSimplesNac <> 100) and
         ((not((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0))) or ((((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0))) and (vsAplicaDescSimplesPrecoFixo = 'S'))) and
         (Imposto.Tributacao.UtilizaMotorCalculo = 'N') THEN
        vnIVA := vnIVA * (vnPercentualdeRedSimplesNac / 100);
      END IF;

      vnAliquota1Calculada := NVL(Imposto.Tributacao.AliqIcms1Fonte,0);
      vnAliquota2Calculada := NVL(Imposto.Tributacao.AliqIcms2Fonte,0);
      vnAliqIcmsFecp       := nvl(Imposto.Tributacao.ALIQICMSFECP,0);
    end if;

    vsUsaValorultEntbaseST  := 'N';
    vsUsaValorultEntbaseST2 := 'N';

    if pRetiraImposto201 = 'S' then
       vsUsaValorultEntbaseST  := Imposto.Tributacao.UsaValorultEntbaseST;
       vsUsaValorultEntbaseST2 := Imposto.Tributacao.UsaValorultEntbaseST2;
    else
      if (Imposto.Filial.UF = Imposto.Cliente.EstEnt) then
        vsUsaValorultEntbaseST  := Imposto.Tributacao.UsaValorultEntbaseST;
        if vsUsaValorultEntbaseST = 'S' then
          -----------------------------------------------------------
          --Autor: Rafael Soares
          --Solicitação: HIS.02754.2015
          --Data: 13/10/2015
          --Descrição: Quando o produto estiver parametrizado com ST fonte e não utilizar imposto da 201,
          --           deve ser utilizado o campo de valor da ultima entrada na segunda parte do cálculo
          --           do ST fonte.
          -----------------------------------------------------------
          if (vsTIPOST = 'ST FONTE') then
             vsUsaValorultEntbaseST2 := Imposto.Tributacao.UsaValorultEntbaseSTFonte;
          else
             vsUsaValorultEntbaseST2 := Imposto.Tributacao.UsaValorultEntbaseST2;
          end if;
        end if;
      end if;
    end if;


    -----------------------------------------------------------
    --Autor: Rodrigo Santos
    --Solicitação: HIS.01756.2014
    --Data: 30/10/2014
    --Descrição: Implentação de itens bonificados em um pedido TV1.
    -----------------------------------------------------------
    IF (pItemTV1Bnf in ('F', 'S')) AND (((Imposto.Tributacao.bnfnaocalculaicms = 'S') AND (pCondVenda = 1)) or
                                ((Imposto.Tributacao.BNFNAOCALCULAICMSTV14 = 'S') and (pCondVenda = 14))) AND
       (pRetiraImposto201 IN ('N','I')) THEN
      vnAliquota2Calculada := 0;
    END IF;

    IF (NVL(Imposto.Tributacao.TipoCalculoGnre, 'P') <> 'P') THEN
      vnIVA                := 0;
      vnAliquota1Calculada := 0;
      vnAliquota2Calculada := 0;
      vnAliqIcmsFecp       := 0;
    END IF;


	IF (Imposto.Produto.TipoMercadoria = 'CB') OR
     (Imposto.Produto.Codprod = '999999') THEN
      vnpercipi            := 0;
      vnPautaIpi           := 0;
      VnIpiPorKGVenda      := 0;
      vnIVA                := 0;
      vnAliquota1Calculada := 0;
      vnAliquota2Calculada := 0;
      vnAliqIcmsFecp       := 0;
    END IF;

    if pcontaordem = 'S' and pCondVenda = 8 and
       (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_VALIDARPRECOVENDATV8', psCodFilial, 'N') = 'N') then
      vnpercipi            := 0;
      vnPautaIpi           := 0;
      VnIpiPorKGVenda      := 0;
      vnIVA                := 0;
      vnAliquota1Calculada := 0;
      vnAliquota2Calculada := 0;
      vnAliqIcmsFecp       := 0;
    END IF;

     IF (pCondVenda = 9) AND
       (NVL(Imposto.Tributacao.Tv9IsentoSt, 'N') = 'S') AND
       (pRetiraImposto201 in('N','I')) THEN
      vnIVA                := 0;
      vnAliquota1Calculada := 0;
      vnAliquota2Calculada := 0;
      vnAliqIcmsFecp       := 0;
    END IF;

    --Zera aliquota FECEP VEN-5118
    IF(pRetiraFecp = 'S')then
      vnAliqIcmsFecp       := 0;
    END IF;

    vnPautaTemp := vnPauta;
    if (Imposto.Tributacao.compararpautacomst = 'S') then
       vnPautaTemp := 0;
    end if;

    if (Imposto.Tributacao.UsaBaseIcmsReduzida = 'S') or
       (Imposto.Tributacao.UtilizaMotorCalculo = 'S') THEN
      if (pRetiraImposto201 in('N','I')) or ((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)) THEN
        vnPercRedIcms := RETORNAR_PERC_RED_ICMS(Imposto,
                                                pCondVenda);
      ELSIF pRetiraImposto201 = 'S' THEN
        vnPercRedIcms := Imposto.Tributacao.PercRedNormal;
      ELSE
        vnPercRedIcms := 100;
      END IF;
    ELSE
      vnPercRedIcms := 100;
    END IF;

    if vnPercRedICMS = 0 then
     vnPercRedIcms := 100;
    end if;


    -----------------------------------------------------------
    --MOTOR DE CALCULO
    IF (Imposto.Tributacao.UtilizaMotorCalculo = 'S') THEN
      vFormula := RETORNA_CODIGO_FORMULA_PVENDA(Imposto);

      IF Imposto.Tributacao.formula_preco.completa IS NOT NULL THEN
        vFormula := Imposto.Tributacao.formula_preco.completa;
      END IF;


      MONTAR_PARAMETROS_MOTOR(Imposto,
                              NULL,
                              vtVariaveis);

      variavel.Nome  := '[VLDESCONTO]';
      variavel.Valor := pPtabela;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      IF (pRetiraImposto201 = 'S') AND
         ((vsConsideraPrecoFixoSemImposto = 'N') and (NVL(pCodPrecoFixo,0)<= 0) AND
          (Imposto.Produto.PrecoFixo = 'N')) AND
          (Imposto.Precificacao.FormulaPrecific is not null)
      THEN
        vFormula := Imposto.Precificacao.FormulaPrecific;

        if (Imposto.Precificacao.CALCULARFECPSTVENDA = 'N')
        then
           vnAliqIcmsFecp := 0;
        end if;

		if (vFECP201 > 0) and
           (pRetiraImposto201 = 'S') and
           ( vFormula like '%RIO_LOG%')
		then
          variavel.Nome         := '[PERCBASESTRJ]';
          variavel.valor        := 0;
          FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);
        end if;

        variavel.Nome         := '[PERCREDALIQIPI]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        variavel.Nome         := '[PERACRESBASEIPI]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        variavel.Nome         := '[MARGEMMVA]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        variavel.Nome         := '[PERCARGATRIBMEDIA]';
        variavel.Valor        := 0;
        FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        if (pUtilizaCustoVendaTV10 = 'S')  then
          variavel.Nome         := '[VLIPIPAUTATV10TAB]';
          variavel.Valor        := 0;
          FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

          variavel.Nome         := '[VLPAUTAIPIVENDATAB]';
          variavel.Valor        := 0;
          FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

          variavel.Nome         := '[PERCIPIVENDATAB]';
          variavel.Valor        := 0;
          FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

          variavel.Nome         := '[VLIPIPORKGVENDATAB]';
          variavel.Valor        := 0;
          FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);
        END IF;
      END IF;

      variavel.Nome         := '[VLULTENT]';
      if (vnAliquota1Calculada > 0) or (vnAliquota2Calculada > 0) then
        variavel.Valor        := COALESCE(VnValorUltEnt, 0);
      else
        variavel.Valor        := 0;
      end if;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[VALORULTENT]';
      if (vnAliquota1Calculada > 0) or (vnAliquota2Calculada > 0) then
        variavel.Valor        := COALESCE(VnValorUltEnt, 0);
      else
        variavel.Valor        := 0;
      end if;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome        := '[CUSTONFSEMST]';
      if (vnAliquota1Calculada > 0) or (vnAliquota2Calculada > 0) then
        variavel.Valor        := COALESCE(VnValorUltEnt, 0);
      else
        variavel.Valor        := 0;
      end if;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[VLULTENTMES]';
      variavel.Valor        := COALESCE(VnUltEntMes, 0);
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[VLPAUTAIPIVENDATAB]';
      variavel.Valor        := vnPautaIpi;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[PERCIPIVENDATAB]';
      variavel.Valor        := vnpercipi;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[VLIPIPORKGVENDATAB]';
      variavel.Valor        := VnIpiPorKGVenda;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PAUTATAB]';
      variavel.Valor := vnPauta;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASEREDST]';
      variavel.valor := vnPercentualdeReducaoBaseST;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[ALIQICMS1TAB]';
      variavel.Valor := vnAliquota1Calculada;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[ALIQICMS2TAB]';
      variavel.Valor := vnAliquota2Calculada;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[MARGEMMVA]';
      variavel.Valor        := CASE
                               WHEN vnAliquota2Calculada > 0 or vnAliquota1Calculada > 0 THEN
                                NVL(Imposto.Cnae.MARGEMMVA, 0)
                               ELSE
                                 0
                             END;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome         := '[PERCARGATRIBMEDIA]';
      variavel.Valor        := CASE
                               WHEN vnAliquota2Calculada > 0 or vnAliquota1Calculada > 0  THEN
                                  NVL(Imposto.Cnae.percargaTribMedia, 0)
                               ELSE
                                 0
                             END;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[IVATAB]';
      variavel.Valor := vnIVA;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASERED]';
      variavel.valor := vnPercRedIcms;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCREDBCSTCLISN]';
      variavel.Valor := vnPercentualdeRedSimplesNac;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[ALIQICMSFECP]';
      if (vnAliquota1Calculada > 0 or vnAliquota2Calculada > 0) then  --VEN-5492
        variavel.Valor := vnAliqIcmsFecp;
      else
        variavel.Valor := 0;
      end if;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERACRESCIMOFUNCEP]';
      variavel.Valor := Imposto.Tributacao.PercAcrescimoFuncep;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PAUTAICMS]';
      if (Imposto.Filial.UF <> Imposto.Cliente.EstEnt) then
          variavel.Valor := Imposto.Tributacao.vlpautaicmsinterest;
      else
          variavel.Valor := Imposto.Tributacao.vlpautaicmsest;
      end if;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);


      Resultado                   := formula.CALCULARREVERSO(vFormula,
                                                             vtVariaveis,
                                                             pVenda);

      DADOS_SAIDA.VALORSEMIMPOSTO := formula.BUSCAVALOR(resultado, '[PTABELASEMIMPOSTO1]');
      DADOS_SAIDA.MSG             := 'OK';

      vrLog.Descricao := vrLog.Descricao || CHR(13) ||
                         'VALOR SEM IMPOSTO' || DADOS_SAIDA.VALORSEMIMPOSTO ;

      FERRAMENTAS.GRAVARLOG(vrLOG, '');

--      FORMULA.G_SUBSTITUIR_FORMULA := TRUE;

      PIPE ROW(DADOS_SAIDA);

      RETURN;
    END IF;
    -----------------------------------------------------------


    -----------------------------------------------------------
    --Autor: Rodrigo Santos
    --Solicitação: HIS.00789.2013
    --Data: 09/03/2015
    --Descrição: Para os casos de ST com Pauta, quando a flag
    --"Utiliza comparação entre Valor Pauta e Base ST" estiver marcada
    --o sistema irá comparar a BaseST original com o valor de Pauta
    --e utilizar o maior valor no cálculo.
    -----------------------------------------------------------
    vbAchouPrecoSemImposto := FALSE;
    IF (Imposto.Tributacao.percbasestrj > 0) AND
      --(pVendaSemImposto > 0) AND
       ((vnAliquota1Calculada > 0) OR (vnAliquota2Calculada > 0)) THEN

      -- 3. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      IF (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
         (VnIpiPorKGVenda = 0)) and
         (Imposto.Tributacao.UsaValorultEntbaseST = 'S') and (vnPauta = 0) and
         ((Imposto.Filial.UF = Imposto.Cliente.EstEnt) or (pRetiraImposto201 = 'S')) THEN

        vnVendaSemImposto := (pVenda -
                             ((VnValorUltEnt * (1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (Imposto.Tributacao.percbasestrj / 100)))) /
                             (1  + vnpercipi/100 +
                              vnpercipi/100 * (1 + vnIVA/100) *
                              vnPercentualdeReducaoBaseST/100 * Imposto.Tributacao.percbasestrj/100);

      END IF;

      --7. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      if (vnPautaIpi > 0) and
         (Imposto.Tributacao.UsaValorultEntbaseST = 'S') and (vnPauta = 0) and
         ((Imposto.Filial.UF = Imposto.Cliente.EstEnt) or (pRetiraImposto201 = 'S')) then
        vnVendaSemImposto := (pVenda -
                             VnValorUltEnt *
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (Imposto.Tributacao.percbasestrj / 100)) -
                             vnPautaIpi *
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (Imposto.Tributacao.percbasestrj / 100)) -
                             vnPautaIpi);
      END IF;

      --11. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      if (VnIpiPorKGVenda > 0) and
         (Imposto.Tributacao.UsaValorultEntbaseST = 'S') and (vnPauta = 0) and
         ((Imposto.Filial.UF = Imposto.Cliente.EstEnt) or (pRetiraImposto201 = 'S')) then
        vnVendaSemImposto := (pVenda -
                             VnValorUltEnt *
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (Imposto.Tributacao.percbasestrj / 100)) -
                             (VnPesoBruto * VnIpiPorKGVenda) *
                             ((1 + (vnIVA / 100)) *
                             (vnPercentualdeReducaoBaseST / 100) *
                             (Imposto.Tributacao.percbasestrj / 100)) -
                             (VnPesoBruto * VnIpiPorKGVenda));
      END IF;

      --8. DIFERENCIAL DE ALÍQUOTAS +  (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE )
      if (vnPauta > 0) AND (VnIpiPorKGVenda > 0) and
         (Imposto.Tributacao.UsaValorultEntbaseST = 'S') and
         ((Imposto.Filial.UF = Imposto.Cliente.EstEnt) or (pRetiraImposto201 = 'S')) then
        vnVendaSemImposto := (pVenda - (VnPesoBruto * VnIpiPorKGVenda) -
                             (vnPauta *
                             (Imposto.Tributacao.percbasestrj / 100)));
      END IF;

      -- 3. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      if (((vnpercipi > 0) or (vnpercipi = 0)) and (vnPautaIpi = 0) and
         (VnIpiPorKGVenda = 0)) and
         (Imposto.Tributacao.UsaValorultEntbaseST = 'S') and (vnPauta > 0) and
         ((Imposto.Filial.UF = Imposto.Cliente.EstEnt) or (pRetiraImposto201 = 'S')) THEN

        vnVendaSemImposto := (pVenda -
                             (vnPauta *
                             (Imposto.Tributacao.percbasestrj / 100))) /
                             (1 + (vnpercipi / 100));

      end IF;

      DADOS_ST := PROCESSAR_ST(Imposto
                              ,pCondVenda
                              ,psVendaExportacao
                              ,pVendaLocalEstrangeira
                              ,vnVendaSemImposto
                              ,0
                              ,protinaconsum => protinaconsum);
      vnVlSt   := DADOS_ST.ST;
      --***********CALCULA IPI PARA O PRODUTO ***********--
      PROCESSAR_IPI(Imposto
                   ,pCondVenda
                   ,psVendaExportacao
                   ,pVendaLocalEstrangeira
                   ,vnVendaSemImposto
                   ,vnIPI
                   ,pBaseIpi
                   ,pPercIpi);

      if (Imposto.Parametros132.CalcularIPIVenda = 'N') and
         (pRetiraImposto201 IN ('N','I')) THEN
        vnIPI := 0;
      END IF;

      IF (Imposto.Precificacao.VLIPI = 0) AND
         (not (((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)) and
          (Imposto.Parametros132.CalcularIPIVenda = 'S') and
          (vsConsideraPrecoFixoSemImposto = 'N'))) AND
         (pRetiraImposto201 = 'S') THEN
        vnIPI := 0;
      END IF;

      --***********FIM CALCULA IPI PARA O PRODUTO ***********--
        --***********FIM CALCULA IPI PARA O PRODUTO ***********--
       /* vbAchouPrecoSemImposto := round(NVL((vnVendaSemImposto + vnVlSt + vnIPI),0)
                                       ,Imposto.Parametros132.NumCasasDecimais) = round(pVenda, Imposto.Parametros132.NumCasasDecimais);  */

        -----------------------------------------------------------
        --Autor: Rafael Soares
        --Solicitação: 2895.081466.2017
        --Data: 11/07/2017
        --Descrição: Ajustado para que na comparação do preço da com imposto com o preço de venda,
        --            não seja comparado o preço com todas as casas em conexão, no caso do cliente dava uma
        --             diferença na 6 cada decimal de 3 decimos e por isso o sistema aplicava a
        --             função de calculo inverso errado
        -----------------------------------------------------------

        --Autor: Tulio Sousa
        --Solicitação: VEN-4970
        --Data: 04/07/2018
        --Descrição: A comparação abaixo foi comentada porque, quando a soma das variáveis é arredonda pra 2
        --           e o valor decimal é menor que 5, é arredondado pra baixo.
        --           E quando o pVenda é arredondado pra 2 e o valor decimal é maior que 5, é arredondado pra cima,
        --           dando a falsa impressão que os valores são iguais. Setando a variável como TRUE, quando na verdade não é.
        --           Deixado apenas a comparação utilizando as casas decimais definidas na 132.

        vbAchouPrecoSemImposto := /*round(NVL((vnVendaSemImposto + vnVlSt + vnIPI),0)
                                       ,2) = round(pVenda, 2) OR*/
                                  round(NVL((vnVendaSemImposto + vnVlSt + vnIPI),0)
                                       ,greatest( Imposto.Parametros132.NumCasasDecimais-1 ,2)) =
                                  round(pVenda, greatest( Imposto.Parametros132.NumCasasDecimais-1 ,2));

    END IF;

    if (Imposto.Tributacao.UsaVlultentMedioBasest = 'S') AND
       (NOT vbAchouPrecoSemImposto) AND
       ((vnAliquota1Calculada > 0) OR (vnAliquota2Calculada > 0))
    THEN
      PVENDA_SEM_IMPOSTO_25(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnValorUltEnt
                           ,VnUltEntMes
                           ,VnIpiPorKGVenda
                           ,vnPautaIpi
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vnVlUltEntMes
                           ,vnPercIPI
                           ,Imposto);

      PVENDA_SEM_IMPOSTO_26(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnValorUltEnt
                           ,VnUltEntMes
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vnVlUltEntMes
                           ,vnPautaIpi
                           ,Imposto);

      PVENDA_SEM_IMPOSTO_27(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnValorUltEnt
                           ,VnUltEntMes
                           ,VnIpiPorKGVenda
                           ,VnPesoBruto
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vnVlUltEntMes
                           ,Imposto);

      DADOS_ST := PROCESSAR_ST(Imposto
                              ,pCondVenda
                              ,psVendaExportacao
                              ,pVendaLocalEstrangeira
                              ,vnVendaSemImposto
                              ,0
                              ,protinaconsum => protinaconsum);
      vnVlSt   := DADOS_ST.ST;
      --***********CALCULA IPI PARA O PRODUTO ***********--
      PROCESSAR_IPI(Imposto
                   ,pCondVenda
                   ,psVendaExportacao
                   ,pVendaLocalEstrangeira
                   ,vnVendaSemImposto
                   ,vnIPI
                   ,pBaseIpi
                   ,pPercIpi);

      if (Imposto.Parametros132.CalcularIPIVenda = 'N') and
         (pRetiraImposto201 IN ('N','I')) THEN
        vnIPI := 0;
      END IF;

      IF (Imposto.Precificacao.VLIPI = 0) AND
         (not (((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)) and
          (Imposto.Parametros132.CalcularIPIVenda = 'S') and
          (vsConsideraPrecoFixoSemImposto = 'N'))) AND
         (pRetiraImposto201 = 'S') THEN
        vnIPI := 0;
      END IF;

      --***********FIM CALCULA IPI PARA O PRODUTO ***********--
        vbAchouPrecoSemImposto := round(NVL((vnVendaSemImposto + vnVlSt + vnIPI),0)
                                       ,2) = round(pVenda, 2) OR
                                  round(NVL((vnVendaSemImposto + vnVlSt + vnIPI),0)
                                                                 ,Imposto.Parametros132.NumCasasDecimais) = round(pVenda, Imposto.Parametros132.NumCasasDecimais);
    END IF;

    IF (Imposto.Tributacao.compararpautacomst = 'S') AND
       (NOT vbAchouPrecoSemImposto) then
      -- 2. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (PAUTA)
      PVENDA_SEM_IMPOSTO_02(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnIpiPorKGVenda
                           ,vnPautaIpi
                           ,vnPercIPI
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vbConsiderarIpiAliqicms2
                           ,Imposto);
      --6. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (PAUTA)
      PVENDA_SEM_IMPOSTO_06(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,vnPautaIpi
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vbConsiderarIpiAliqicms2
                           ,Imposto);
      --10. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (PAUTA)
      PVENDA_SEM_IMPOSTO_10(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnIpiPorKGVenda
                           ,VnPesoBruto
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vbConsiderarIpiAliqicms2
                           ,Imposto);

      --14. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + PAUTA ST
      PVENDA_SEM_IMPOSTO_14(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnValorUltEnt
                           ,VnIpiPorKGVenda
                           ,vnPautaIpi
                           ,vnPercIPI
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vsUsaValorultEntbaseST
                           ,vsUsaValorultEntbaseST2
                           ,Imposto);

      --15. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + ST PAUTA
      PVENDA_SEM_IMPOSTO_15(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnValorUltEnt
                           ,vnPautaIpi
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vsUsaValorultEntbaseST
                           ,vsUsaValorultEntbaseST2
                           ,Imposto);

      --16. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
      PVENDA_SEM_IMPOSTO_16(pVenda
                           ,vnVendaSemImposto
                           ,vnPercentualdeReducaoBaseST
                           ,vnPauta
                           ,VnValorUltEnt
                           ,VnIpiPorKGVenda
                           ,VnPesoBruto
                           ,vnAliquota1Calculada
                           ,vnAliquota2Calculada
                           ,vsUsaValorultEntbaseST
                           ,vsUsaValorultEntbaseST2
                           ,Imposto);

      if (Imposto.Tributacao.UsaVlultentMedioBasest = 'S') then
        --22. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + PAUTA ST IGUAL AO 14.
        PVENDA_SEM_IMPOSTO_22(pVenda
                             ,vnVendaSemImposto
                             ,vnPercentualdeReducaoBaseST
                             ,vnPauta
                             ,VnValorUltEnt
                             ,VnUltEntMes
                             ,VnIpiPorKGVenda
                             ,vnPautaIpi
                             ,vnPercIPI
                             ,vnAliquota1Calculada
                             ,vnAliquota2Calculada
                             ,vnVlUltEntMes
                             ,Imposto);

        --23. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + ST PAUTA -- IGUAL AO 15.
        PVENDA_SEM_IMPOSTO_23(pVenda
                             ,vnVendaSemImposto
                             ,vnPercentualdeReducaoBaseST
                             ,vnPauta
                             ,VnValorUltEnt
                             ,VnUltEntMes
                             ,vnPautaIpi
                             ,vnAliquota1Calculada
                             ,vnAliquota2Calculada
                             ,vnVlUltEntMes
                             ,Imposto);

        --24. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) IGUAL AO 16.
        PVENDA_SEM_IMPOSTO_24(pVenda
                             ,vnVendaSemImposto
                             ,vnPercentualdeReducaoBaseST
                             ,vnPauta
                             ,VnValorUltEnt
                             ,VnUltEntMes
                             ,VnIpiPorKGVenda
                             ,VnPesoBruto
                             ,vnAliquota1Calculada
                             ,vnAliquota2Calculada
                             ,vnVlUltEntMes
                             ,Imposto);

      END IF;

      DADOS_ST := PROCESSAR_ST(Imposto
                              ,pCondVenda
                              ,psVendaExportacao
                              ,pVendaLocalEstrangeira
                              ,vnVendaSemImposto
                              ,0);
      vnVlSt   := DADOS_ST.ST;
      --***********CALCULA IPI PARA O PRODUTO ***********--
      PROCESSAR_IPI(Imposto
                   ,pCondVenda
                   ,psVendaExportacao
                   ,pVendaLocalEstrangeira
                   ,vnVendaSemImposto
                   ,vnIPI
                   ,pBaseIpi
                   ,pPercIpi);

      if (((Imposto.Parametros132.CalcularIPIVenda = 'N') AND
         (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
         (Imposto.Produto.ProdutoFilial.CalculaIpi = 'N')) and
         (pRetiraImposto201 IN ('N','I')) THEN
        vnIPI := 0;
      END IF;

      IF (Imposto.Precificacao.VLIPI = 0) AND
         (not (((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)) and
          (((Imposto.Parametros132.CalcularIPIVenda = 'S') AND
          (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
          (Imposto.Produto.ProdutoFilial.CalculaIpi = 'S')) and
          (vsConsideraPrecoFixoSemImposto = 'N'))) AND
         (pRetiraImposto201 = 'S') THEN
        vnIPI := 0;
      END IF;

      IF (((pFoiPrecificadoIPI = 'N') or (vsIsentoIPI = 'S')) and
         (pRetiraImposto201 IN ('N','I'))) and
         (not (((Imposto.Produto.PrecoFixo = 'S') or (pCodPrecoFixo > 0)) and
         (((Imposto.Parametros132.CalcularIPIVenda = 'S') AND
         (Imposto.Produto.ProdutoFilial.CalculaIpi = 'I')) OR
         (Imposto.Produto.ProdutoFilial.CalculaIpi = 'S')) AND
         (vsConsideraPrecoFixoSemImposto = 'N')))
      THEN
        vnIPI := 0;
      END IF;
      --***********FIM CALCULA IPI PARA O PRODUTO ***********--

      if round((vnVendaSemImposto + vnVlSt + vnIPI), 6) = round(pVenda, 6) or
         round((vnVendaSemImposto + vnVlSt + vnIPI), 2) = round(pVenda, 2)
      then
        vbAchouPrecoSemImposto := true;
      else
        vbAchouPrecoSemImposto := false;
      end if;

    end if;

    IF NOT vbAchouPrecoSemImposto THEN
      /*vsIsentoST := 'N';
      --Cliente isento de ST
      if Imposto.Cliente.CalculaSt = 'N' then
        vsIsentoST := 'S';
      END IF;

      --Cálcula ST p/ Pessoa Física
      if Imposto.Parametros132.calcstpf = 'N' then
        if Imposto.Cliente.PessoaFisicaJuridica = 'PESSOA FISICA' then
          vsIsentoST := 'S';
        END IF;
      END IF;*/

      IF vsIsentoST = 'S' OR imposto.Tributacao.tipocalculognre = 'C' THEN
        vnIVA                := 0;
        vnAliquota1Calculada := 0;
        vnAliquota2Calculada := 0;
      END IF;

      -- 1. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (IVA)
      PVENDA_SEM_IMPOSTO_01(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            vnPautaTemp,
                            VnIpiPorKGVenda,
                            vnPautaIpi,
                            vnPercIPI,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vbConsiderarIpiAliqicms2,
                            Imposto,
                            vnPercRedIcms);

      -- 2. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (PAUTA)
      PVENDA_SEM_IMPOSTO_02(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnPautaTemp,
                            VnIpiPorKGVenda,
                            vnPautaIpi,
                            vnPercIPI,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vbConsiderarIpiAliqicms2,
                            Imposto);

      -- 3. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      PVENDA_SEM_IMPOSTO_03(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            vnPautaTemp,
                            VnValorUltEnt,
                            VnIpiPorKGVenda,
                            vnPautaIpi,
                            vnPercIPI,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            Imposto);

      --4. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
      PVENDA_SEM_IMPOSTO_04(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            VnValorUltEnt,
                            VnIpiPorKGVenda,
                            vnPautaIpi,
                            vnPercIPI,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            vsUsaValorultEntbaseST2,
                            Imposto);

      --5. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (IVA)
      PVENDA_SEM_IMPOSTO_05(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            vnPautaTemp,
                            vnPautaIpi,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vbConsiderarIpiAliqicms2,
                            Imposto,
                            vnPercRedIcms);

      --6. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (PAUTA)
      PVENDA_SEM_IMPOSTO_06(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnPautaTemp,
                            vnPautaIpi,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vbConsiderarIpiAliqicms2,
                            Imposto);

      --7. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      PVENDA_SEM_IMPOSTO_07(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            vnPautaTemp,
                            VnValorUltEnt,
                            vnPautaIpi,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            Imposto);

      --8. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
      PVENDA_SEM_IMPOSTO_08(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            VnValorUltEnt,
                            vnPautaIpi,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            vsUsaValorultEntbaseST2,
                            Imposto);

      --9. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (IVA)
      PVENDA_SEM_IMPOSTO_09(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            vnPautaTemp,
                            VnIpiPorKGVenda,
                            VnPesoBruto,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vbConsiderarIpiAliqicms2,
                            Imposto,
                            vnPercRedIcms);

      --10. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (PAUTA)
      PVENDA_SEM_IMPOSTO_10(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnPautaTemp,
                            VnIpiPorKGVenda,
                            VnPesoBruto,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vbConsiderarIpiAliqicms2,
                            Imposto);

      --11. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
      PVENDA_SEM_IMPOSTO_11(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            vnPautaTemp,
                            VnValorUltEnt,
                            VnIpiPorKGVenda,
                            VnPesoBruto,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            Imposto);

      --12. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
      PVENDA_SEM_IMPOSTO_12(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnIVA,
                            VnValorUltEnt,
                            VnIpiPorKGVenda,
                            VnPesoBruto,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            vsUsaValorultEntbaseST2,
                            Imposto);

      --13. CALCULA ST COM BASE NO PREÇO MÁXIMO DO CONSUMIDOR FINAL
      PVENDA_SEM_IMPOSTO_13(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            Imposto);

      --14. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + PAUTA ST
      PVENDA_SEM_IMPOSTO_14(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnPautaTemp,
                            VnValorUltEnt,
                            VnIpiPorKGVenda,
                            vnPautaIpi,
                            vnPercIPI,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            vsUsaValorultEntbaseST2,
                            Imposto);

      --15. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + ST PAUTA
      PVENDA_SEM_IMPOSTO_15(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnPautaTemp,
                            VnValorUltEnt,
                            vnPautaIpi,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            vsUsaValorultEntbaseST2,
                            Imposto);

      --16. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
      PVENDA_SEM_IMPOSTO_16(pVenda,
                            vnVendaSemImposto,
                            vnPercentualdeReducaoBaseST,
                            vnPautaTemp,
                            VnValorUltEnt,
                            VnIpiPorKGVenda,
                            VnPesoBruto,
                            vnAliquota1Calculada,
                            vnAliquota2Calculada,
                            vsUsaValorultEntbaseST,
                            vsUsaValorultEntbaseST2,
                            Imposto);

      vbCnpjMesmoRadical     := FERRAMENTAS.F_COMPARARCNPJ(Imposto.Filial.CodCli, Imposto.Cliente.CodCli);
      vbCalculaMediaPondSTMG := ( (Imposto.Tributacao.CalcMediaPondsStMG = 'S') AND
                                  ( vbCnpjMesmoRadical ) AND
                                  ( pRetiraImposto201 IN ('N','I') )  AND
                                  (  (pCondVenda = 10) OR
                                     (pTransferencia = 'S') OR
                                     (pTransferenciaVirtual = 'S') ) );

      if (Imposto.Tributacao.UsaVlultentMedioBasest = 'S') OR (vbCalculaMediaPondSTMG) then
        --17. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) -- IGUAL AO 4.

        /* Calcula média ponderada ST de MG */
        IF (vbCalculaMediaPondSTMG) and
           (Imposto.Filial.UF = 'MG') THEN

          vsCalcMediaPondSTMGFilDest := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCMEDIAPONDSTMGFILDESTINO',
                                                                          nvl(Imposto.FilialNF.Codfilial,
                                                                              Imposto.Filial.Codfilial),
                                                                          'N'));

           BEGIN
            select codigo
              into vsCodFilialCliTransf
              from pcfilial
             where codcli = Imposto.Cliente.CodCli
             and rownum = 1;
           EXCEPTION
             WHEN OTHERS THEN
             vsCodFilialCliTransf := nvl(Imposto.FilialNF.Codfilial,
                                         Imposto.Filial.codfilial);
           END;

          vsCodFilialCliTransf := case
                                    when vsCalcMediaPondSTMGFilDest = 'S' then
                                     vsCodFilialCliTransf
                                    else
                                     nvl(Imposto.FilialNF.Codfilial,
                                         Imposto.Filial.codfilial)
                                  end;

          VnValorUltEnt := BUSCAR_VLBASE_ST_MG(Imposto.Produto.CodProd,
                                               VnValorUltEnt,
                                               vsCodFilialCliTransf);

          VnUltEntMes   := VnValorUltEnt;
          vnVlUltEntMes := VnValorUltEnt;
        END IF;

        PVENDA_SEM_IMPOSTO_17(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnIVA,
                              VnValorUltEnt,
                              VnUltEntMes,
                              VnIpiPorKGVenda,
                              vnPautaIpi,
                              vnPercIPI,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

        --18. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE) -- IGUAL AO 7.
        PVENDA_SEM_IMPOSTO_18(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnIVA,
                              vnPautaTemp,
                              VnValorUltEnt,
                              VnUltEntMes,
                              vnPautaIpi,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

        --19. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) -- IGUAL AO 8.
        PVENDA_SEM_IMPOSTO_19(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnIVA,
                              VnValorUltEnt,
                              VnUltEntMes,
                              vnPautaIpi,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

        --20. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE) -- IGUAL AO 11.
        PVENDA_SEM_IMPOSTO_20(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnIVA,
                              vnPautaTemp,
                              VnValorUltEnt,
                              VnUltEntMes,
                              VnIpiPorKGVenda,
                              VnPesoBruto,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

        --21. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) -- IGUAL AO 12.
        PVENDA_SEM_IMPOSTO_21(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnIVA,
                              VnValorUltEnt,
                              VnUltEntMes,
                              VnIpiPorKGVenda,
                              VnPesoBruto,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

       if (Imposto.Tributacao.UsaVlultentMedioBasest <> 'S') then

        --22. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + PAUTA ST IGUAL AO 14.
        PVENDA_SEM_IMPOSTO_22(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnPautaTemp,
                              VnValorUltEnt,
                              VnUltEntMes,
                              VnIpiPorKGVenda,
                              vnPautaIpi,
                              vnPercIPI,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

        --23. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + ST PAUTA -- IGUAL AO 15.
        PVENDA_SEM_IMPOSTO_23(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnPautaTemp,
                              VnValorUltEnt,
                              VnUltEntMes,
                              vnPautaIpi,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);

        --24. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) IGUAL AO 16.
        PVENDA_SEM_IMPOSTO_24(pVenda,
                              vnVendaSemImposto,
                              vnPercentualdeReducaoBaseST,
                              vnPautaTemp,
                              VnValorUltEnt,
                              VnUltEntMes,
                              VnIpiPorKGVenda,
                              VnPesoBruto,
                              vnAliquota1Calculada,
                              vnAliquota2Calculada,
                              vnVlUltEntMes,
                              Imposto);
       END IF;
      END IF;

    END IF;

    ---RETIRA IMPOSTO DA TRIBUTAÇÃO DO MT
    IF NOT vbAchouPrecoSemImposto THEN

      IF pRetiraImposto201 IN ('N','I') THEN

        if (Imposto.Cliente.EstEnt = 'MT') AND
           (Imposto.Cliente.UtilizaCalculoSTMT = 'S' AND Imposto.Tributacao.CalculaSTMT = 'S') AND
           (vsIsentoST = 'N') AND
           ((vnAliquota1Calculada <> 0) OR (vnAliquota2Calculada <> 0)) /*AND
           (vsTIPOST <> 'ST FONTE')    */
        then
          --2091.002839.2015

          PVENDA_SEM_IMPOSTO_28(pVenda,
                                vnVendaSemImposto,
                                vnPautaTemp,
                                vnPercIpi,
                                vnPautaIpi,
                                VnIpiPorKGVenda,
                                VnPesoBruto,
                                Imposto);

          DADOS_ST := PROCESSAR_ST(Imposto
                                  ,pCondVenda
                                  ,psVendaExportacao
                                  ,pVendaLocalEstrangeira
                                  ,vnVendaSemImposto
                                  ,0);

          vnVlSt   := DADOS_ST.ST;

          SELECT VALORIPI
            INTO vnIpi
            from TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(psCodFilial
                                                  ,psCodFilialNf
                                                  ,psCodFilialRetira
                                                  ,pCodCli
                                                  ,pCodProd
                                                  ,pCodAuxiliar
                                                  ,pCondVenda
                                                  ,psVendaExportacao
                                                  ,vnVendaSemImposto
                                                  ,pVendaTriangular
                                                  ,pCodEndEnt
                                                  ,pTransferencia
                                                  ,pTransferenciaVirtual
                                                  ,pVendaLocalEstrangeira
                                                  ,psOrigemPedido
                                                  ,pPtabela
                                                  ,'T'
                                                  ,0
                                                  ,'N'
                                                  ,Imposto.Pedido.TipoDocumento
                                                  ));

          if round((vnVendaSemImposto + vnVlSt + vnIPI), 6) = round(pVenda, 6) then
            vbAchouPrecoSemImposto := true;
          else
            vbAchouPrecoSemImposto := false;
          end if;

          IF Imposto.Cliente.EstEnt = (NVL(Imposto.FilialNF.UF , Imposto.Filial.UF)) then

            if ((vnAliquota1Calculada <> 0) or (vnAliquota2Calculada <> 0)) AND
               (NOT vbAchouPrecoSemImposto)
            then

              if (Imposto.cnae.MARGEMMVA <> 0) and
                 (Imposto.cnae.PERCARGATRIBMEDIA <> 0) then

                IF NVL(vnPercIpi, 0) >= 0 THEN
                  vnVendaSemImposto := pVenda / ((1 +
                                       (Imposto.cnae.MARGEMMVA / 100) *
                                       (Imposto.cnae.PERCARGATRIBMEDIA / 100)) *
                                       (1 + (vnpercipi / 100)));
                END IF;

                IF NVL(vnPautaIpi, 0) > 0 THEN
                   vnVendaSemImposto := pVenda / ((1 +
                                       (Imposto.cnae.MARGEMMVA / 100) *
                                       (Imposto.cnae.PERCARGATRIBMEDIA / 100))) -
                                       vnPautaIpi;
                END IF;

                IF NVL(VnIpiPorKGVenda, 0) > 0 THEN
                  vnVendaSemImposto := pVenda / ((1 +
                                       (Imposto.cnae.MARGEMMVA / 100) *
                                       (Imposto.cnae.PERCARGATRIBMEDIA / 100))) -
                                       (VnPesoBruto * VnIpiPorKGVenda);
                END IF;

              END IF;

            END IF;
          else

            if ((Imposto.cnae.PERCARGATRIBMEDIA <> 0) and
               ((vnAliquota1Calculada <> 0) OR (vnAliquota2Calculada <> 0))) AND
               (NOT vbAchouPrecoSemImposto)
            then
              IF NVL(vnPercIpi, 0) >= 0 THEN
                vnVendaSemImposto := pVenda /
                                     ((1 + (vnpercipi / 100)) * (1 +
                                     (Imposto.cnae.PERCARGATRIBMEDIA / 100)));
              END IF;

              IF NVL(vnPautaIpi, 0) > 0 THEN
                vnVendaSemImposto := (- vnPautaIpi + pVenda - vnPautaIpi *
                                      (Imposto.cnae.PERCARGATRIBMEDIA / 100)) /
                                     (1 +  (Imposto.cnae.PERCARGATRIBMEDIA / 100));
              END IF;

              IF NVL(VnIpiPorKGVenda, 0) > 0 THEN
                vnVendaSemImposto := (-(VnPesoBruto * VnIpiPorKGVenda) + pVenda -
                                       (VnPesoBruto * VnIpiPorKGVenda)*
                                       (Imposto.cnae.PERCARGATRIBMEDIA / 100))/
                                      (1 +  (Imposto.cnae.PERCARGATRIBMEDIA / 100));
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
      ---FIM RETIRA IMPOSTO DA TRIBUTAÇÃO DO MT
    END IF;

    vnVendaSemImposto           := least(vnVendaSemImposto, pVenda);

    DADOS_SAIDA.VALORSEMIMPOSTO := vnVendaSemImposto;
    DADOS_SAIDA.MSG             := 'OK';

    IF imposto.Produto.TipoMercadoria =  'CB' THEN
      DADOS_SAIDA.VALORSEMIMPOSTO := PVENDA;
    END IF;

    vrLog.Descricao := vrLog.Descricao || CHR(13) ||
                       'VALOR SEM IMPOSTO' || DADOS_SAIDA.VALORSEMIMPOSTO ;

    FERRAMENTAS.GRAVARLOG(vrLOG, '');

    PIPE ROW(DADOS_SAIDA);

    RETURN;

  EXCEPTION
    WHEN OTHERS THEN
      DADOS_SAIDA.VALORSEMIMPOSTO := NULL;
      DADOS_SAIDA.MSG             := SQLERRM || CHR(13) ||
                                  DBMS_UTILITY.format_error_backtrace();

      vrLog.Descricao := vrLog.Descricao || CHR(13) ||
                         'VALOR SEM IMPOSTO' || DADOS_SAIDA.VALORSEMIMPOSTO ;

      FERRAMENTAS.GRAVARLOG(vrLOG, '');

      PIPE ROW(DADOS_SAIDA);

      RETURN;

  END;

  FUNCTION PROCESSAR_DESC_PIS_COFINS_ICMS(pImposto          IN T_IMPOSTO,
                                          pPreco            IN FLOAT,
                                          pNumEmpenho       IN NUMBER,
                                          pPrazoMedioPedido IN NUMBER)

   RETURN T_DESCONTO_PIS_CONFINS_ICMS

   IS
    Imposto T_IMPOSTO;
    vbIsentoNumEmpenho BOOLEAN;

    vnDescReducaoPIS    NUMBER(18, 6);
    vnPerDescReducaoPIS NUMBER(18, 6);

    vnDescReducaoCOFINS    NUMBER(18, 6);
    vnPerDescReducaoCOFINS NUMBER(18, 6);

    vnDescReducaoICMS     NUMBER(18, 6);
    vnPercDescReducaoICMS NUMBER(18, 6);

    vnDescReducaoSUFRAMA     NUMBER(18, 6);
    vnPercDescReducaoSUFRAMA NUMBER(18, 6);

    vnPrecoBaseDescontos NUMBER(18, 6);

    vDTVencSuframa       DATE;

    DADOS_SAIDA T_DESCONTO_PIS_CONFINS_ICMS;
  BEGIN
    vbIsentoNumEmpenho       := FALSE;
    vnDescReducaoPIS         := 0;
    vnPerDescReducaoPIS      := 0;
    vnDescReducaoCOFINS      := 0;
    vnPerDescReducaoCOFINS   := 0;
    vnPercDescReducaoICMS    := 0;
    vnDescReducaoSUFRAMA     := 0;
    vnPercDescReducaoSUFRAMA := 0;

    BEGIN
      SELECT dtVencSuframa into vdtVencSuframa
        FROM PCCLIENT C
       WHERE C.Codcli = pImposto.Cliente.codcli;
    EXCEPTION
      WHEN OTHERS THEN
        vdtVencSuframa := NULL;
    END;

    IF ((pImposto.Cliente.TipoEmpresa = 'R') or
       (pImposto.Cliente.OrgaoPub = 'S') or
       (pImposto.Cliente.UsaDescontoICMS = 'S') or
       (pImposto.Cliente.OrgaoPubFederal = 'S') or
       (pImposto.Cliente.SULFRAMA IS NOT Null)) THEN

      vnPrecoBaseDescontos := pPreco;

      --------------------Calcula desconto de ICMS------------------------------------
      vnPercDescReducaoSUFRAMA := pImposto.Tributacao.PerDescSUFRAMA;
      vnDescReducaoSUFRAMA     := (vnPrecoBaseDescontos *
                                  (vnPercDescReducaoSUFRAMA / 100));

      --VEN-3305
      IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
         (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
         (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
      THEN
        vnDescReducaoSUFRAMA     := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                    (vnPercDescReducaoSUFRAMA / 100));
      END IF;

      vnPercDescReducaoICMS := pImposto.Tributacao.PerDescICMIsencao;
      vnDescReducaoICMS     := (vnPrecoBaseDescontos *
                               (vnPercDescReducaoICMS / 100));
      --VEN-3305
      IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
         (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
         (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
      THEN
        vnDescReducaoICMS   := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                               (vnPercDescReducaoICMS / 100));
      END IF;

      IF pImposto.Cliente.isencaoSuframa IN ('T', 'P', 'I') THEN
        IF pImposto.Cliente.isencaoSuframa <> 'I' THEN

          IF (pImposto.Tributacao.IsentNumEmpenho = 'S') THEN
            IF (pNumEmpenho <> 0) THEN
              vbIsentoNumEmpenho := TRUE;
            ELSE
              vbIsentoNumEmpenho := TRUE;
            END IF;
          ELSE
            vbIsentoNumEmpenho := FALSE;
          END IF;

          IF (pImposto.Cliente.TipoEmpresa = 'R') THEN
            vbIsentoNumEmpenho := FALSE;
          END IF;

          IF NOT (vbIsentoNumEmpenho) THEN
            IF (pImposto.Cliente.TipoDescIsencao = 'C') THEN
              vnPercDescReducaoICMS := pImposto.Cliente.PerDescIsentoICMS;
            END IF;

            IF (pImposto.Cliente.TipoDescIsencao = 'T') THEN
              -- Solicitação 4778.034927.2017, favor ler antes de descomentar
              /*IF nvl(pImposto.Tributacao.PerDescICMIsencao,0) > nvl(pImposto.Tributacao.perdescsuframa,0) THEN
                 vnPercDescReducaoICMS := nvl(pImposto.Tributacao.PerDescICMIsencao,0);
              ELSIF pImposto.Cliente.sulframa IS NOT NULL
                AND TRUNC(VDTVENCSUFRAMA) >= TRUNC(SYSDATE) THEN
                 vnPercDescReducaoICMS := nvl(pImposto.Tributacao.perdescsuframa,0);
              ELSE*/
              IF pImposto.Cliente.sulframa IS NULL THEN
                 --vnPercDescReducaoICMS    := 0;
                 vnPercDescReducaoSUFRAMA := 0;
              END IF;
            END IF;
            IF (pPrazoMedioPedido > 0) AND
               (pImposto.Tributacao.UsaIsencaoIcmsVP = 'N') /*AND
               nvl(pImposto.Tributacao.PerDescICMIsencao,0) > nvl(pImposto.Tributacao.perdescsuframa,0)*/
            THEN
              vnPercDescReducaoICMS := 0;
            END IF;

            vnDescReducaoICMS := (vnPrecoBaseDescontos *
                                 (vnPercDescReducaoICMS / 100));

            --VEN-3305
            IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
               (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
               (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
            THEN
              vnDescReducaoICMS := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                   (vnPercDescReducaoICMS / 100));
            END IF;

            vnDescReducaoSUFRAMA     := (vnPrecoBaseDescontos *
                                        (vnPercDescReducaoSUFRAMA / 100));

            --VEN-3305
            IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
               (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
               (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
            THEN
              vnDescReducaoSUFRAMA   := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                        (vnPercDescReducaoSUFRAMA / 100));
            END IF;
          END IF;

          IF (nvl(pImposto.Tributacao.PerDescICMIsencao,0) > 0) OR
             (NVL(pImposto.Cliente.PerDescIsentoICMS, 0) > 0)
          THEN
            vnPrecoBaseDescontos := vnPrecoBaseDescontos - vnDescReducaoICMS;
          END IF;
        END IF;

        IF pImposto.Cliente.isencaoSuframa <> 'P' THEN
          --------------------Calcula desconto de PIS/COFINS-----------------------
          vnPerDescReducaoPIS    := pImposto.Tributacao.percdescpis;
          vnPerDescReducaoCOFINS := pImposto.Tributacao.percdesccofins;

          vnDescReducaoPIS    := (vnPrecoBaseDescontos *
                                 (vnPerDescReducaoPIS / 100));
          vnDescReducaoCOFINS := (vnPrecoBaseDescontos *
                                 (vnPerDescReducaoCOFINS / 100));
        END IF;
      END IF;

      IF pImposto.Cliente.isencaoSuframa IN ('S','C') THEN
        ------------------------------ ant ------------------------------------------


        --------------------Calcula desconto de PIS/COFINS-----------------------
        vnPerDescReducaoPIS    := pImposto.Tributacao.percdescpis;
        vnPerDescReducaoCOFINS := pImposto.Tributacao.percdesccofins;

        vnDescReducaoPIS    := (vnPrecoBaseDescontos *
                               (vnPerDescReducaoPIS / 100));
        vnDescReducaoCOFINS := (vnPrecoBaseDescontos *
                               (vnPerDescReducaoCOFINS / 100));

        IF (pImposto.Cliente.ISENCAOSUFRAMA = 'P') THEN
          vnDescReducaoPIS       := 0;
          vnDescReducaoCOFINS    := 0;
          vnPerDescReducaoPIS    := 0;
          vnPerDescReducaoCOFINS := 0;
        END IF;

        IF (pImposto.Cliente.isencaoSuframa = 'C') AND
           (NVL(pImposto.Tributacao.percdescpis, 0) > 0) AND
           (NVL(pImposto.Tributacao.percdesccofins, 0) > 0)
        THEN
          vnPrecoBaseDescontos := NVL(vnPrecoBaseDescontos, 0) -
                                  NVL(vnDescReducaoPIS, 0) -
                                  NVL(vnDescReducaoCOFINS, 0);
        END IF;

        /*Se for difente de simutaneo então a base e reduzida com o desconto de pis e cofins ou seja deconto em cima de desconto */
        /*IF (pCliente.ISENCAOSUFRAMA <> 'S') THEN
          vnPrecoBaseDescontos := vnPrecoBaseDescontos - vnDescReducaoPIS;
          vnPrecoBaseDescontos := vnPrecoBaseDescontos - vnDescReducaoCOFINS;
        END IF;*/
        /*************************************************************************************************************************/

        --------------------------------------------------------------------------------

        --------------------Calcula desconto de ICMS------------------------------------
        vnPercDescReducaoSUFRAMA := pImposto.Tributacao.PerDescSUFRAMA;
        vnDescReducaoSUFRAMA     := (vnPrecoBaseDescontos *
                                    (vnPercDescReducaoSUFRAMA / 100));

        --VEN-3305
        IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
           (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
           (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
        THEN
          vnDescReducaoSUFRAMA   := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                    (vnPercDescReducaoSUFRAMA / 100));
        END IF;

        vnPercDescReducaoICMS := pImposto.Tributacao.PerDescICMIsencao;
        vnDescReducaoICMS     := (vnPrecoBaseDescontos *
                                 (vnPercDescReducaoICMS / 100));

        --VEN-3305
        IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
           (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
           (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
        THEN
          vnDescReducaoICMS   := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                 (vnPercDescReducaoICMS / 100));
        END IF;

        IF (pImposto.Tributacao.IsentNumEmpenho = 'S') THEN
          IF (pNumEmpenho <> 0) THEN
            vbIsentoNumEmpenho := TRUE;
          ELSE
            vbIsentoNumEmpenho := TRUE;
          END IF;
        ELSE
          vbIsentoNumEmpenho := FALSE;
        END IF;

        IF (pImposto.Cliente.TipoEmpresa = 'R') THEN
          vbIsentoNumEmpenho := FALSE;
        END IF;

        IF NOT (vbIsentoNumEmpenho) THEN
          IF (pImposto.Cliente.TipoDescIsencao = 'C') THEN
            vnPercDescReducaoICMS := pImposto.Cliente.PerDescIsentoICMS;
          END IF;
          IF (pImposto.Cliente.TipoDescIsencao = 'T') THEN
            -- Solicitação 4778.034927.2017, favor ler antes de descomentar
            /*IF nvl(pImposto.Tributacao.PerDescICMIsencao,0) > nvl(pImposto.Tributacao.perdescsuframa,0) THEN
               vnPercDescReducaoICMS := nvl(pImposto.Tributacao.PerDescICMIsencao,0);
            ELSIF pImposto.Cliente.sulframa IS NOT NULL
              AND TRUNC(VDTVENCSUFRAMA) >= TRUNC(SYSDATE) THEN
               vnPercDescReducaoICMS := nvl(pImposto.Tributacao.perdescsuframa,0);
            ELSE*/
            IF pImposto.Cliente.sulframa IS NULL THEN
              vnPercDescReducaoSUFRAMA := 0;
              --vnPercDescReducaoICMS    := 0;
            END IF;
          END IF;
          IF (pPrazoMedioPedido > 0) AND
             (pImposto.Tributacao.UsaIsencaoIcmsVP = 'N') /*AND
             nvl(pImposto.Tributacao.PerDescICMIsencao,0) > nvl(pImposto.Tributacao.perdescsuframa,0)*/
          THEN
            vnPercDescReducaoICMS := 0;
          END IF;
          vnDescReducaoICMS    := (vnPrecoBaseDescontos *
                                  (vnPercDescReducaoICMS / 100));

          --VEN-3305
          IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
             (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
             (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
          THEN
            vnDescReducaoICMS   := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                   (vnPercDescReducaoICMS / 100));
          END IF;

          vnDescReducaoSUFRAMA := (vnPrecoBaseDescontos *
                                  (vnPercDescReducaoSUFRAMA / 100));

          --VEN-3305
          IF (pImposto.Tributacao.VLPAUTAICMSINTEREST > 0) AND
             (vnPrecoBaseDescontos < pImposto.Tributacao.VLPAUTAICMSINTEREST) AND
             (pImposto.Cliente.EstEnt <> pImposto.Filial.UF)
          THEN
            vnDescReducaoSUFRAMA   := (pImposto.Tributacao.VLPAUTAICMSINTEREST *
                                      (vnPercDescReducaoSUFRAMA / 100));
          END IF;
        END IF;
      END IF;
      --END IF;
      --------------------------------------------------------------------------------

      IF (pImposto.Cliente.ISENCAOSUFRAMA IN ('I', 'N')) and
         (NVL(pImposto.Tributacao.PerDescSUFRAMA,0) = 0) THEN
        vnPercDescReducaoICMS := 0;
        vnDescReducaoICMS     := 0;
      END IF;

      IF (pImposto.Cliente.ISENCAOSUFRAMA IN ('N')) and
         (NVL(pImposto.Tributacao.PerDescSUFRAMA,0) > 0) THEN
        vnPercDescReducaoSUFRAMA := 0;
        vnDescReducaoSUFRAMA     := 0;
      END IF;

    END IF;

    DADOS_SAIDA.VALOR_DESCONTO_PIS     := NVL(vnDescReducaoPIS, 0);
    DADOS_SAIDA.PERC_DESCONTO_PIS      := NVL(vnPerDescReducaoPIS, 0);
    DADOS_SAIDA.VALOR_DESCONTO_COFINS  := NVL(vnDescReducaoCOFINS, 0);
    DADOS_SAIDA.PERC_DESCONTO_COFINS   := NVL(vnPerDescReducaoCOFINS, 0);
    DADOS_SAIDA.VALOR_DESCONTO_ICMS    := NVL(vnDescReducaoICMS, 0);
    DADOS_SAIDA.PERC_DESCONTO_ICMS     := NVL(vnPercDescReducaoICMS, 0);
    DADOS_SAIDA.VALOR_DESCONTO_SUFRAMA := NVL(vnDescReducaoSUFRAMA, 0);
    DADOS_SAIDA.PERC_DESCONTO_SUFRAMA  := NVL(vnPercDescReducaoSUFRAMA, 0);

    RETURN DADOS_SAIDA;

  END;

  FUNCTION CALCULAR_DESC_PIS_COFINS_ICMS(psCodFilial       VARCHAR2,
                                         psCodFilialNF     VARCHAR2,
                                         psCodFilialRetira VARCHAR2,
                                         pCodCli           IN NUMBER,
                                         pCodProd          IN NUMBER,
                                         pPreco            IN FLOAT,
                                         pNumEmpenho       IN NUMBER,
                                         pPrazoMedioPedido IN NUMBER,
                                         pVendaTriangular  IN VARCHAR2 DEFAULT 'N',
										 pCodEndEnt        IN NUMBER DEFAULT 0,
										 pCodst                   IN NUMBER   DEFAULT 0)
    RETURN TB_DESCONTO_PIS_CONFINS_ICMS
    PIPELINED IS
    vncodst     pctribut.codst%TYPE;
    DADOS_SAIDA T_DESCONTO_PIS_CONFINS_ICMS;
    Imposto T_IMPOSTO;
    vsCodFilial VARCHAR2(2);
  BEGIN
    Imposto.Cliente := FERRAMENTAS.BUSCAR_CLIENTE(pCODCLI, psCodFilialNF);

    IF ((Imposto.Cliente.TipoEmpresa = 'R') or
        (Imposto.Cliente.OrgaoPub = 'S') or
        (Imposto.Cliente.UsaDescontoICMS = 'S') or
        (Imposto.Cliente.OrgaoPubFederal = 'S') or
        (Imposto.Cliente.SULFRAMA IS NOT Null))
    THEN
      Imposto.Produto := BUSCAR_PRODUTO(pCODPROD);

      IF ((psCodFilialNF IS NOT NULL) or (Imposto.Cliente.CodFilialNF IS NOT NULL)) THEN
        vsCodFilial := NVL(psCodFilialNF, Imposto.Cliente.CodFilialNF);
      ELSE
        vsCodFilial := psCodFilial;
      END IF;

      Imposto.Filial     := BUSCAR_FILIAL(NVL(psCodFilialNF, psCodFilial));
	  IF (pCodst > 0) THEN
       vncodst := pCodst;
	  ELSE 
		vncodst            := RETORNA_CODIGO_TRIBUTACAO(Imposto.Cliente
														,pCodProd
														,vsCodFilial
														,0
														,pVendaTriangular
														,0
														,pCodEndEnt
														,psCodFilialNF);
	  END IF;

      Imposto.Tributacao := BUSCAR_TRIBUTACAO(vncodst);
    END IF;

    DADOS_SAIDA := PROCESSAR_DESC_PIS_COFINS_ICMS(Imposto
                                                 ,pPreco
                                                 ,pNumEmpenho
                                                 ,pPrazoMedioPedido);

    PIPE ROW(DADOS_SAIDA);

    RETURN;
  END;

  FUNCTION CALCULAR_RED_SIMPLES_NACIONAL(psCodFilial            VARCHAR2,
                                         psCodFilialNF          VARCHAR2,
                                         psCodFilialRetira      VARCHAR2,
                                         pCodCli                IN NUMBER,
                                         pCodPlPag              IN NUMBER,
                                         pCodProd               IN NUMBER,
                                         pCodAuxiliar           IN NUMBER,
                                         pCondVenda             IN NUMBER,
                                         psVendaExportacao      IN VARCHAR2,
                                         pPreco                 IN NUMBER,
                                         pPrecoTributado        IN NUMBER,
                                         pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                                         pconsultardblink       IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
										 pCodst                 IN NUMBER DEFAULT 0
                                         )
    RETURN TB_REDUCAO_SIMPLES_NACIONAL
    PIPELINED IS
    vnPercentualdeRedSimplesNac  pctribut.percredpvendasimplesnac%TYPE;
    vnPercentualdeReducaoBaseIVA pcest.REDBASEIVAULTENT%TYPE;
    vnnumregiao                  pctabpr.numregiao%TYPE;
    vncodst                      pctribut.codst%TYPE;
    vnST1                        NUMBER(18, 8);
    vnST2                        NUMBER(18, 8);
    vnST                         NUMBER(18, 8);
    vnST_Guia                    NUMBER(18, 8);
    vnST1_Guia                   NUMBER(18, 8);
    vnST2_Guia                   NUMBER(18, 8);
    vnVlReducao                  NUMBER(18, 8);
    vnVlReducao1                 NUMBER(18, 8);
    vnVlReducao2                 NUMBER(18, 8);
    vnVlReducaoUnit              NUMBER(18, 8);
    vnPercRedSimplesNasc         NUMBER(18, 8);
    vnNovoPrecoSimplesNacional   NUMBER(18, 8);
    vsCalculaST                  varchar2(1);
    DADOS_SAIDA                  T_REDUCAO_SIMPLES_NACIONAL;
    DADOS_CALCULO_ST             T_CALCULOST;

    vnFatorAjuste     NUMBER;
    vnFatorAjusteGuia NUMBER;
    vnCasasDecimais   NUMBER;
    Imposto T_IMPOSTO;
  BEGIN

    vnNovoPrecoSimplesNacional := pPrecoTributado;
    vnPercRedSimplesNasc := 0;
    vnVlReducaoUnit := 0;
    vnVlReducao     := 0;
    vnVlReducao1    := 0;
    vnVlReducao2    := 0;

    Imposto.Pedido.CondVenda            := pCondVenda;

    Imposto.Parametros132.UsaDescSimplesNac := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC'
                                                                                 ,psCodFilial
                                                                                 ,'S');

    vnCasasDecimais := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA'
                                                         ,'99'
                                                         ,2);

    Imposto.Cliente        := FERRAMENTAS.BUSCAR_CLIENTE(pCODCLI
                                                        ,psCodFilialNF);
    Imposto.PlanoPagamento := BUSCAR_PLANO_PAGTO(pCODPLPAG);
    Imposto.Produto        := BUSCAR_PRODUTO(pCODPROD);
    Imposto.Filial         := BUSCAR_FILIAL(psCodFilial);
    Imposto.FilialNF       := BUSCAR_FILIAL(NVL(psCodFilialNF, psCodFilial));

    Imposto.Embalagem      := BUSCAR_EMBALAGEM(pCODPROD
                                              ,pCodAuxiliar
                                              ,NVL(psCodFilialRetira
                                                  ,psCodFilial));

    vnnumregiao := Imposto.Cliente.numregiao;

    IF vnnumregiao = 0 THEN
      vnnumregiao := Imposto.Cliente.numregiao;
    END IF;
    IF (pCodst > 0) THEN
       vncodst := pCodst;
    ELSE 
		vncodst := RETORNA_CODIGO_TRIBUTACAO(Imposto.Cliente
                                        ,pCodProd
                                        ,psCodFilial);
	END IF;

    Imposto.Tributacao   := BUSCAR_TRIBUTACAO(vncodst);
    Imposto.Precificacao := BUSCAR_PRECIFICACAO(pCodProd, vnnumregiao, pconsultardblink);
    Imposto.Estoque      := BUSCAR_ESTOQUE(pCodProd, psCodFilial);

    --- PERCENTUAL BASE DE REDUÇÃO DE IVA ULT. ENTRADA
    IF NVL(Imposto.Estoque.REDBASEIVAULTENT, 0) = 0 THEN
      vnPercentualdeReducaoBaseIVA := 100;
    ELSE
      vnPercentualdeReducaoBaseIVA := Imposto.Estoque.REDBASEIVAULTENT;
    END IF;
    --- FIM PERCENTUAL BASE DE REDUÇÃO DE ST

    --- PERCENTUAL DE REDUÇÃO DO SIMPLES NACIONAL
    IF NVL(Imposto.Tributacao.PercRedPvendaSimplesnac, 0) = 0 THEN
      vnPercentualdeRedSimplesNac := 100;
    ELSE
      vnPercentualdeRedSimplesNac := Imposto.Tributacao.PercRedPvendaSimplesnac;
    END IF;
    --- FIM PERCENTUAL DE REDUÇÃO DO SIMPLES NACIONAL

    IF (NVL(Imposto.Cliente.SimplesNacional, 'N') = 'S') THEN
      IF (NVL(Imposto.Parametros132.UsaDescSimplesNac, 'N') = 'S') THEN

        vnVlReducao := pPreco *
                       (Imposto.Precificacao.PERCDESCSIMPLESNAC / 100);

        vnNovoPrecoSimplesNacional := pPrecoTributado -
                                       ROUND(vnVlReducao, vnCasasDecimais);

      ELSIF (NVL(Imposto.Parametros132.UsaDescSimplesNac, 'N') = 'N') AND
            (NVL(Imposto.Tributacao.PercRedPvendaSimplesnac, 0) <> 0) THEN

        vnST      := 0;
        vnST_Guia := 0;

        -----------------------------------------------------------
        --Autor: Rodrigo Santos
        --Solicitação: HIS.05473.2014
        --Data: 29/12/2014
        --Descrição: Cálculo do simples nacional alterando fator de ajuste.
        -----------------------------------------------------------
        IF (Imposto.Tributacao.AlteraFatorAjusteIVASN = 'S') AND
           (Imposto.Filial.UF = Imposto.Cliente.EstEnt) THEN
          vnFatorAjuste     := (1 - (Imposto.Estoque.ALIQICMS2ULTENT / 100)) /
                               (1 - (Imposto.Estoque.ALIQICMS1ULTENT / 100));
          vnFatorAjusteGuia := (1 -
                               (Imposto.Estoque.PERCALIQEXTGUIAULTENT / 100)) /
                               (1 - (Imposto.Estoque.ALIQICMS1ULTENT / 100));

          IF Imposto.Estoque.PERCMVAORIGULTENT > 0 THEN
            Imposto.Estoque.IVAULTENT := Imposto.Estoque.PERCMVAORIGULTENT;
          END IF;
        ELSE
          vnFatorAjuste     := 1;
          vnFatorAjusteGuia := 1;
        END IF;
        -----------------------------------------------------------

        IF (Imposto.Tributacao.Iva = 0) AND (Imposto.Tributacao.pauta = 0) AND
           (Imposto.Tributacao.AliqIcms1 <= Imposto.Tributacao.AliqIcms2) THEN

          vnVlReducao := 0;

          IF (Imposto.Estoque.CUSTONFSEMST > 0 and
            Imposto.Estoque.VLSTULTENT > 0) and
             (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT > 0 and
             Imposto.Estoque.VLSTGUIAULTENT > 0)  then

            vnST1 := (((Imposto.Estoque.CUSTONFSEMST *
                     (1 + ((Imposto.Estoque.IVAULTENT / 100) *
                     (vnPercentualdeRedSimplesNac / 100)))) *
                     (vnPercentualdeReducaoBaseIVA / 100)) * vnFatorAjuste) *
                     (Imposto.Estoque.ALIQICMS1ULTENT / 100);
            vnST2 := Imposto.Estoque.BASEICMSULTENT *
                     (Imposto.Estoque.ALIQICMS2ULTENT / 100);
            vnST  := vnST1 - vnST2;

            if vnST < 0 then
              vnST := 0;
            END IF;

            vnST1_guia := (((Imposto.Estoque.CUSTONFSEMSTGUIAULTENT *
                          (1 + ((Imposto.Estoque.IVAULTENT / 100) *
                          (vnPercentualdeRedSimplesNac / 100)))) *
                          (vnPercentualdeReducaoBaseIVA / 100)) *
                          vnFatorAjusteGuia) *
                          (Imposto.Estoque.ALIQICMS1ULTENT / 100);
            vnST2_guia := Imposto.Estoque.VLFRETECONHECULTENT *
                          (Imposto.Estoque.PERCALIQEXTGUIAULTENT / 100);
            vnST_guia  := vnST1_guia - vnST2_guia;

            if vnST_guia < 0 then
              vnST_guia := 0;
            END IF;
          END IF;

          if (Imposto.Estoque.CUSTONFSEMST = 0 OR Imposto.Estoque.VLSTULTENT = 0) and
             (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT > 0  and
             Imposto.Estoque.VLSTGUIAULTENT > 0)  then

            vnST1_guia := (((Imposto.Estoque.CUSTONFSEMSTGUIAULTENT *
                          (1 + ((Imposto.Estoque.IVAULTENT / 100) *
                          (vnPercentualdeRedSimplesNac / 100)))) *
                          (vnPercentualdeReducaoBaseIVA / 100)) *
                          vnFatorAjusteGuia) *
                          (Imposto.Estoque.ALIQICMS1ULTENT / 100);

            vnST2_guia := (Imposto.Estoque.BASEICMSULTENT *
                          (Imposto.Estoque.PERCALIQEXTGUIAULTENT / 100) +
                          ((Imposto.Estoque.VLFRETECONHECULTENT) *
                          (Imposto.Estoque.PERCICMSFRETEFOBSTULTENT / 100)));
            vnST_guia  := vnST1_guia - vnST2_guia;

            if vnST_guia < 0 then
              vnST_guia := 0;
            END IF;
          END IF;

          IF (Imposto.Estoque.CUSTONFSEMST > 0 and
            Imposto.Estoque.VLSTULTENT > 0) and
             (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT = 0 OR Imposto.Estoque.VLSTGUIAULTENT = 0) THEN

            vnST1 := (((Imposto.Estoque.CUSTONFSEMST *
                     (1 + ((Imposto.Estoque.IVAULTENT / 100) *
                     (vnPercentualdeRedSimplesNac / 100)))) *
                     (vnPercentualdeReducaoBaseIVA / 100)) * vnFatorAjuste) *
                     (Imposto.Estoque.ALIQICMS1ULTENT / 100);
            vnST2 := Imposto.Estoque.BASEICMSULTENT *
                     (Imposto.Estoque.ALIQICMS2ULTENT / 100);
            vnST  := vnST1 - vnST2;

            IF vnST < 0 THEN
              vnST := 0;
            END IF;
          END IF;

          IF (Imposto.Estoque.CUSTONFSEMST = 0 OR Imposto.Estoque.VLSTULTENT = 0) and
             (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT = 0 OR Imposto.Estoque.VLSTGUIAULTENT = 0) THEN
            vnST      := 0;
            vnST_guia := 0;
          END IF;

          vnVlReducao1 := 0;
          IF (Imposto.Estoque.VLSTULTENT - vnST) >= 0 THEN
            vnVlReducao1 := (Imposto.Estoque.VLSTULTENT - vnST);
          END IF;

          vnVlReducao2 := 0;
          IF (Imposto.Estoque.VLSTGUIAULTENT - vnST_guia) >= 0 THEN
            vnVlReducao2 := (Imposto.Estoque.VLSTGUIAULTENT - vnST_guia);
          END IF;

          vnVlReducao := vnVlReducao1 + vnVlReducao2;

          vnVlReducaoUnit := vnVlReducao;
          IF (Imposto.Embalagem.QTUNIT > 0) and
             (Imposto.Filial.UtilizaVendaporEmbalagem = 'S') THEN
            vnVlReducao := (vnVlReducao * Imposto.Embalagem.QTUNIT);
          END IF;

          IF vnVlReducaoUnit < 0 THEN
            vnVlReducaoUnit := 0;
          END IF;

          IF vnVlReducao < 0 THEN
            vnVlReducao := 0;
          END IF;

          vnNovoPrecoSimplesNacional := pPrecoTributado -
                                        ROUND(vnVlReducao, vnCasasDecimais);

          IF pPreco <> 0 THEN
            vnPercRedSimplesNasc := ROUND(vnVlReducao / pPreco, vnCasasDecimais) * 100;
          END IF;

        ELSE
          /*SELECT ST
             INTO vnST1
          FROM
            TABLE(PROCESSAR_ST(psCodFilial,pCodCli,pCodPlPag,pCodProd,pCodAuxiliar,pCondVenda,psVendaExportacao ,pPreco,0,'N','S'));
          */

          SELECT FERRAMENTAS.VERIFICAR_ISENTOST(pCodCli, pCodProd, vncodst)
            INTO vsCalculaST
            from dual;

          IF (vsCalculaST = 'S') then
            vnVlReducao := 0;
            vnPercRedSimplesNasc := 0;
            vnVlReducaoUnit := 0;
          else

            DADOS_CALCULO_ST := PROCESSAR_ST(Imposto
                                            ,pCondVenda
                                            ,psVendaExportacao
                                            ,pVendaLocalEstrangeira
                                            ,pPreco
                                            ,0
                                            ,'N'
                                            ,'S');
            vnST1            := DADOS_CALCULO_ST.ST;

            /*SELECT ST
               INTO vnST2
            FROM
              TABLE(PROCESSAR_ST(psCodFilial,pCodCli,pCodPlPag,pCodProd,pCodAuxiliar,pCondVenda,psVendaExportacao ,pPreco,0,'N','N'));
              */
            DADOS_CALCULO_ST := PROCESSAR_ST(Imposto
                                            ,pCondVenda
                                            ,psVendaExportacao
                                            ,pVendaLocalEstrangeira
                                            ,pPreco
                                            ,0
                                            ,'N'
                                            ,'N');
            vnST2            := DADOS_CALCULO_ST.ST;

            vnVlReducao := vnST1 - vnST2;

            IF vnVlReducao < 0 THEN
              vnVlReducao := 0;
            END IF;
          END IF;

        END IF;
      END IF;
    END IF;

    DADOS_SAIDA.VALOR_REDUCAO_SIMPLES_NACIONAL := ROUND(vnVlReducao, vnCasasDecimais);
    DADOS_SAIDA.PERC_REDUCAO_SIMPLES_NACIONAL  := vnPercRedSimplesNasc;
    DADOS_SAIDA.NOVO_PRECO_SIMPLES_NACIONAL    := vnNovoPrecoSimplesNacional;
    DADOS_SAIDA.VL_RED_SIMPLES_NACIONAL_UNIT   := vnVlReducaoUnit;

    PIPE ROW(DADOS_SAIDA);

    RETURN;
  END;

  --------------------------------------------------------------
  FUNCTION GET_CLIENTE_SUFRAMADO(PCODCLI IN NUMBER, PDATANF IN DATE Default TRUNC(SYSDATE))
  /*
    FUNÇÃO QUE RETORNA SE O CLIENTE OU FORNECEDOR É SUFRAMADO
    *PARÂMETROS DE ENTRADA:
     - PCODCLI = CODIGO DO CLIENTE
    *RETORNO: S = SIM, N = NÃO, E = ERRO
     - CASO O RETORNO SEJA E, HOUVE UM ERRO NO PROCESSAMENTO DA FUNÇÃO
  */
   RETURN VARCHAR2 IS

    VRESULTADO VARCHAR2(1);
  BEGIN

    --REGRA PASSADA PELO VENDAS
    SELECT CASE
       WHEN (TRIM(PCCLIENT.SULFRAMA) IS NOT NULL AND
          TRUNC(PCCLIENT.DTVENCSUFRAMA) >= TRUNC(PDATANF) ) THEN
        'S'
       ELSE
        'N'
         END
    INTO VRESULTADO
    FROM PCCLIENT
   WHERE CODCLI = PCODCLI;


    RETURN VRESULTADO;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'E';
  END;

  FUNCTION CALCULAR_PVENDA_E_IMPOSTOS(PSCODFILIAL       VARCHAR2
                                     ,PSCODFILIALNF     VARCHAR2
                                     ,PSCODFILIALRETIRA VARCHAR2
                                     ,PCODCLI           IN NUMBER
                                     ,PCODPLPAG         IN NUMBER
                                     ,PCODPROD          IN NUMBER
                                     ,PCODAUXILIAR      IN NUMBER
                                     ,PCONDVENDA        IN NUMBER
                                     ,PSVENDAEXPORTACAO IN VARCHAR2
                                     ,PPRECOVENDA       IN NUMBER
                                     ,PPRECOSI210       IN NUMBER
                                     ,PST210            IN NUMBER
                                     ,PTIPODOCUMENTO    IN VARCHAR2 DEFAULT 'N' --Tipo do documento do pedido N = Nota, C = Cupom etc...
                                     ,PCONSULTARDBLINK  IN VARCHAR2 DEFAULT 'N' --quando usando banco caixa, se vai no servidor ou não
                                     ,PALTERACAO        IN VARCHAR2 DEFAULT 'N')
    RETURN TB_VENDA_AUTOSERVICO
    PIPELINED IS
    CODCLIFILIAL NUMBER;
    DADOS_SAIDA  T_VENDA_AUTOSERVICO;
    VSTIPO_ST    VARCHAR2(10);
    VNCODCLI     NUMBER;
    VRLOG        PCLOGIMPOSTOS%ROWTYPE;
  BEGIN

    DADOS_SAIDA.MENSAGEM := 'OK';
    SELECT CODCLI
      INTO CODCLIFILIAL
      FROM PCFILIAL
     WHERE CODIGO = PSCODFILIAL;

    IF (PALTERACAO = 'N')
    THEN
      VNCODCLI := CODCLIFILIAL;
    ELSE
      VNCODCLI := PCODCLI;
    END IF;

    FERRAMENTAS.SET_GRAVARLOG('S');
    VRLOG.OBJETO    := 'CALCULAR_PVENDA_E_IMPOSTOS';
    VRLOG.DESCRICAO := 'INICIO CALCULAR_PVENDA_E_IMPOSTOS' || CHR(13) ||
                       'psCodFilial       =>' || psCodFilial       || chr(13) ||
                       'psCodFilialNF     =>' || psCodFilialNF     || chr(13) ||
                       'psCodFilialRetira =>' || psCodFilialRetira || chr(13) ||
                       'pCodCli           =>' || pCodCli           || chr(13) ||
                       'pCodPlPag         =>' || pCodPlPag         || chr(13) ||
                       'pCodProd          =>' || pCodProd          || chr(13) ||
                       'pCodAuxiliar      =>' || pCodAuxiliar      || chr(13) ||
                       'pCondVenda        =>' || pCondVenda        || chr(13) ||
                       'psVendaExportacao =>' || psVendaExportacao || chr(13) ||
                       'pPrecoVenda       =>' || pPrecoVenda       || chr(13) ||
                       'pPrecoSI210       =>' || pPrecoSI210       || chr(13) ||
                       'pST210            =>' || pST210            || chr(13) ||
                       'pTipoDocumento    =>' || pTipoDocumento    || chr(13) ||
                       'pconsultardblink  =>' || pconsultardblink  || chr(13) ||
                       'palteracao        =>' || palteracao;
    FERRAMENTAS.GRAVARLOG(VRLOG, '');

    BEGIN
      SELECT VALORSEMIMPOSTO, MSG
        INTO DADOS_SAIDA.PVENDASEMIMPOSTOS, DADOS_SAIDA.MENSAGEM
        FROM TABLE(CALCULAR_PVENDA_SEM_IMPOSTO(PSCODFILIAL,
                                               PSCODFILIALNF,
                                               PSCODFILIALRETIRA,
                                               VNCODCLI,
                                               PCODPLPAG,
                                               PCODPROD,
                                               PCODAUXILIAR,
                                               PCONDVENDA, --CONDVENDA
                                               PSVENDAEXPORTACAO, --VENDA EXPORTAÇÃO
                                               PST210,
                                               PPRECOSI210,
                                               PPRECOVENDA,
                                               'N',
                                               'S',
                                               'N',
                                               0,
                                               NULL,
                                               'N',
                                               'N',
                                               'N',
                                               'N',
                                               0,
                                               'N',
                                               'T',
                                               0,
                                               0,
                                               PTIPODOCUMENTO,
                                               PCONSULTARDBLINK));

      SELECT ROUND(NVL(VALORIPI, 0), 6)
        INTO DADOS_SAIDA.VLIPI
        FROM TABLE(CALCULAR_IPI(PSCODFILIAL,
                                PSCODFILIALNF,
                                PSCODFILIALRETIRA,
                                PCODCLI,
                                PCODPROD,
                                PCODAUXILIAR,
                                PCONDVENDA,
                                PSVENDAEXPORTACAO,
                                DADOS_SAIDA.PVENDASEMIMPOSTOS,
                                'N',
                                0,
                                'N',
                                'N',
                                'N',
                                'T',
                                0,
                                'T',
                                0,
                                'N',
                                PTIPODOCUMENTO));

      SELECT ROUND(NVL(BASEST, 0), 6)
            ,ROUND(NVL(ST, 0), 6)
            ,TIPO_ST
            ,ROUND(NVL(BASEFECP, 0), 6)
            ,NVL(ALIQFECP, 0)
            ,ROUND(NVL(VLRFECP, 0), 6)
        INTO DADOS_SAIDA.BASEST
            ,DADOS_SAIDA.ST
            ,VSTIPO_ST
            ,DADOS_SAIDA.BASEFECP
            ,DADOS_SAIDA.ALIQFECP
            ,DADOS_SAIDA.VLRFECP
        FROM TABLE(CALCULAR_ST(PSCODFILIAL,
                               PSCODFILIALNF,
                               PSCODFILIALRETIRA,
                               PCODCLI,
                               PCODPLPAG,
                               PCODPROD,
                               PCODAUXILIAR,
                               PCONDVENDA, -- CONDVENDA
                               PSVENDAEXPORTACAO, --VENDA EXPORTAÇÃO
                               DADOS_SAIDA.PVENDASEMIMPOSTOS, -- PREÇO SEM IMPOSTOS
                               0, --% DESC
                               'N',
                               0,
                               0,
                               0,
                               NULL,
                               'S',
                               'N',
                               'T',
                               'N',
                               0,
                               'N',
                               0 /*ptabelasemimpostos*/,
                               'N' /*venda triangular*/,
                               'T' /*rotina consum*/,
                               0 /*codbnf*/,
                               0 /*codendent*/,
                               'N',
                               PTIPODOCUMENTO,
                               PCONSULTARDBLINK));

      IF VSTIPO_ST = 'ST FONTE'
      THEN
        DADOS_SAIDA.CALCULOUSTFONTE := 'S';
      END IF;


      DADOS_SAIDA.PVENDA := ROUND(DADOS_SAIDA.PVENDASEMIMPOSTOS +
                                  DADOS_SAIDA.VLIPI + DADOS_SAIDA.ST +
                                  DADOS_SAIDA.VLRFECP,
                                  6);


    EXCEPTION
      WHEN OTHERS THEN
        FERRAMENTAS.SET_GRAVARLOG('S');
        VRLOG.OBJETO    := 'CALCULAR_PVENDA_E_IMPOSTOS';
        VRLOG.DESCRICAO := 'CALCULAR_PVENDA_E_IMPOSTOS EXCEPTION - ' ||
                           SQLCODE || '-' || SQLERRM;
        FERRAMENTAS.GRAVARLOG(VRLOG, '');
        DADOS_SAIDA.MENSAGEM := SQLCODE || '-' || SQLERRM;

    END;

    PIPE ROW(DADOS_SAIDA);

    RETURN;
  END;
END;
