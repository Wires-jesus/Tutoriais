CREATE OR REPLACE FUNCTION RET_TABLE_VIEW_DEVOLUCAO(PDDATAINI   IN DATE,
                                                    PDDATAFIM   IN DATE,
                                                    PSCODFILIAL IN VARCHAR2)
  RETURN TABELA_VIEW_DEVOLUCAO
  PIPELINED IS
  VTDEVOLUCAO TIPO_VIEW_DEVOLUCAO;

  DADOSVIEWDEVOLUCAO VIEW_DEVOL_RESUMO_FATURAMENTO%ROWTYPE;
  V_SQL_VIEW_DEVOL   VARCHAR2(32000);
  C_ITENS            SYS_REFCURSOR;

  --
  FUNCTION F_GETSQL_VIEW_DEVOLUCAO(PDATAINI   IN DATE,
								   PDATAFIM   IN DATE,
								   PCODFILIAL IN VARCHAR2) RETURN CLOB IS

	V_SQL VARCHAR2(32000) := '';
  BEGIN
	SELECT V.TEXT
	  INTO V_SQL
	  FROM ALL_VIEWS V
	 WHERE V.VIEW_NAME = 'VIEW_DEVOL_RESUMO_FATURAMENTO'
	   AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
 
	 V_SQL := V_SQL || ' AND PCNFENT.DTENT BETWEEN TO_DATE( ''' || TO_CHAR(PDATAINI, 'DD/MM/YYYY') || ''' , ''DD/MM/YYYY'') 
						AND TO_DATE(''' || TO_CHAR(PDATAFIM, 'DD/MM/YYYY') || ''' , ''DD/MM/YYYY'') ';  
	IF PCODFILIAL IS NOT NULL THEN
	  V_SQL := V_SQL || ' AND PCMOV.CODFILIAL IN ( ' || PCODFILIAL || ')';
	END IF;
  
	RETURN V_SQL;
  END;
  --  

BEGIN
  --  VTDEVOLUCAO := TABELA_VIEW_DEVOLUCAO();

  -- RETORNA O SQL DA VIEW: VIEW_DEVOL_RESUMO_FATURAMENTO
  V_SQL_VIEW_DEVOL := F_GETSQL_VIEW_DEVOLUCAO(PDDATAINI, PDDATAFIM, PSCODFILIAL);
  
  OPEN C_ITENS FOR V_SQL_VIEW_DEVOL;
  LOOP
    FETCH C_ITENS
      INTO DADOSVIEWDEVOLUCAO;
  
    EXIT WHEN C_ITENS%NOTFOUND;
--    VTDEVOLUCAO.EXTEND;
    --VTDEVOLUCAO(VTDEVOLUCAO.COUNT) := 
    VTDEVOLUCAO := TIPO_VIEW_DEVOLUCAO(CODFORNEC         => DADOSVIEWDEVOLUCAO.CODFORNEC,
                                       CODFORNECMOV      => DADOSVIEWDEVOLUCAO.CODFORNECMOV,
                                       FORNECEDOR        => DADOSVIEWDEVOLUCAO.FORNECEDOR,
                                       CODCLI            => DADOSVIEWDEVOLUCAO.CODCLI,
                                       CODATIV           => DADOSVIEWDEVOLUCAO.CODATIV,
                                       CODATIVMOV        => DADOSVIEWDEVOLUCAO.CODATIVMOV,
                                       CODATIVPRINC      => DADOSVIEWDEVOLUCAO.CODATIVPRINC,
                                       CODATIVPRINCMOV   => DADOSVIEWDEVOLUCAO.CODATIVPRINCMOV,
                                       CAIXA             => DADOSVIEWDEVOLUCAO.CAIXA,
                                       NUMNOTA           => DADOSVIEWDEVOLUCAO.NUMNOTA,
                                       CODDEVOL          => DADOSVIEWDEVOLUCAO.CODDEVOL,
                                       VLOUTRAS          => DADOSVIEWDEVOLUCAO.VLOUTRAS,
                                       VLFRETE           => DADOSVIEWDEVOLUCAO.VLFRETE,
                                       CODFILIAL         => DADOSVIEWDEVOLUCAO.CODFILIAL,
                                       CODMOTORISTADEVOL => DADOSVIEWDEVOLUCAO.CODMOTORISTADEVOL,
                                       NOMEMOTORISTA     => DADOSVIEWDEVOLUCAO.NOMEMOTORISTA,
                                       DTENT             => DADOSVIEWDEVOLUCAO.DTENT,
                                       NUMTRANSENT       => DADOSVIEWDEVOLUCAO.NUMTRANSENT,
                                       NUMTRANSVENDA     => DADOSVIEWDEVOLUCAO.NUMTRANSVENDA,
                                       NOMEFUNC          => DADOSVIEWDEVOLUCAO.NOMEFUNC,
                                       MOTIVO            => DADOSVIEWDEVOLUCAO.MOTIVO,
                                       VENDAASSISTIDA    => DADOSVIEWDEVOLUCAO.VENDAASSISTIDA,
                                       CLIENTE           => DADOSVIEWDEVOLUCAO.CLIENTE,
                                       DEVOLITEM         => DADOSVIEWDEVOLUCAO.DEVOLITEM,
                                       MOTIVO2           => DADOSVIEWDEVOLUCAO.MOTIVO2,
                                       ESTENT            => DADOSVIEWDEVOLUCAO.ESTENT,
                                       UFMOV             => DADOSVIEWDEVOLUCAO.UFMOV,
                                       VIP               => DADOSVIEWDEVOLUCAO.VIP,
                                       OBS               => DADOSVIEWDEVOLUCAO.OBS,
                                       DESCRICAO         => DADOSVIEWDEVOLUCAO.DESCRICAO,
                                       CODAUXILIAR       => DADOSVIEWDEVOLUCAO.CODAUXILIAR,
                                       EMBALAGEM         => DADOSVIEWDEVOLUCAO.EMBALAGEM,
                                       UNIDADE           => DADOSVIEWDEVOLUCAO.UNIDADE,
                                       CODPROD           => DADOSVIEWDEVOLUCAO.CODPROD,
                                       DTCANCEL          => DADOSVIEWDEVOLUCAO.DTCANCEL,
                                       CODMARCA          => DADOSVIEWDEVOLUCAO.CODMARCA,
                                       CODLINHAPROD      => DADOSVIEWDEVOLUCAO.CODLINHAPROD,
                                       CODEPTO           => DADOSVIEWDEVOLUCAO.CODEPTO,
                                       CODEPTOMOV        => DADOSVIEWDEVOLUCAO.CODEPTOMOV,
                                       CODSEC            => DADOSVIEWDEVOLUCAO.CODSEC,
                                       CODCATEGORIA      => DADOSVIEWDEVOLUCAO.CODCATEGORIA,
                                       CODSUBCATEGORIA   => DADOSVIEWDEVOLUCAO.CODSUBCATEGORIA,
                                       CODSECMOV         => DADOSVIEWDEVOLUCAO.CODSECMOV,
                                       CODFAB            => DADOSVIEWDEVOLUCAO.CODFAB,
                                       DEPARTAMENTO      => DADOSVIEWDEVOLUCAO.DEPARTAMENTO,
                                       SECAO             => DADOSVIEWDEVOLUCAO.SECAO,
                                       CODSUPERVISOR     => DADOSVIEWDEVOLUCAO.CODSUPERVISOR,
                                       CODSUPERVMOV      => DADOSVIEWDEVOLUCAO.CODSUPERVMOV,
                                       CODPRACA          => DADOSVIEWDEVOLUCAO.CODPRACA,
                                       CODPRACAMOV       => DADOSVIEWDEVOLUCAO.CODPRACAMOV,
                                       NUMREGIAO         => DADOSVIEWDEVOLUCAO.NUMREGIAO,
                                       NUMREGIAOMOV      => DADOSVIEWDEVOLUCAO.NUMREGIAOMOV,
                                       ROTA              => DADOSVIEWDEVOLUCAO.ROTA,
                                       PRACA             => DADOSVIEWDEVOLUCAO.PRACA,
                                       QTMETA            => DADOSVIEWDEVOLUCAO.QTMETA,
                                       QTPESOMETA        => DADOSVIEWDEVOLUCAO.QTPESOMETA,
                                       MIXPREV           => DADOSVIEWDEVOLUCAO.MIXPREV,
                                       CLIPOSPREV        => DADOSVIEWDEVOLUCAO.CLIPOSPREV,
                                       CODPLPAG          => DADOSVIEWDEVOLUCAO.CODPLPAG,
                                       NUMPED            => DADOSVIEWDEVOLUCAO.NUMPED,
                                       TEMVENDATV8       => DADOSVIEWDEVOLUCAO.TEMVENDATV8,
                                       CODCOB            => DADOSVIEWDEVOLUCAO.CODCOB,
                                       CONDVENDA         => DADOSVIEWDEVOLUCAO.CONDVENDA,
                                       PRAZOMEDIO        => DADOSVIEWDEVOLUCAO.PRAZOMEDIO,
                                       PRAZOADICIONAL    => DADOSVIEWDEVOLUCAO.PRAZOADICIONAL,
                                       CODEMITENTE       => DADOSVIEWDEVOLUCAO.CODEMITENTE,
                                       DESCRICAOPCPLPAG  => DADOSVIEWDEVOLUCAO.DESCRICAOPCPLPAG,
                                       NUMDIAS           => DADOSVIEWDEVOLUCAO.NUMDIAS,
                                       NOME              => DADOSVIEWDEVOLUCAO.NOME,
                                       CODCOMPRADOR      => DADOSVIEWDEVOLUCAO.CODCOMPRADOR,
                                       SUPERV            => DADOSVIEWDEVOLUCAO.SUPERV,
                                       VLVENDA           => DADOSVIEWDEVOLUCAO.VLVENDA,
                                       QTBONIFIC         => DADOSVIEWDEVOLUCAO.QTBONIFIC,
                                       VLBONIFIC         => DADOSVIEWDEVOLUCAO.VLBONIFIC,
                                       QT                => DADOSVIEWDEVOLUCAO.QT,
                                       QTCONT            => DADOSVIEWDEVOLUCAO.QTCONT,
                                       QTUNITCX          => DADOSVIEWDEVOLUCAO.QTUNITCX,
                                       VLDEVOLUCAO       => DADOSVIEWDEVOLUCAO.VLDEVOLUCAO,
                                       VLDEVOLBONIFIC    => DADOSVIEWDEVOLUCAO.VLDEVOLBONIFIC,
                                       VLDEVOLBONIFIC2   => DADOSVIEWDEVOLUCAO.VLDEVOLBONIFIC2,
                                       VLDEVOLBONIFIC151 => DADOSVIEWDEVOLUCAO.VLDEVOLBONIFIC151,
                                       VLCMVDEVOL        => DADOSVIEWDEVOLUCAO.VLCMVDEVOL,
                                       VLCMVDEVOLBONIF   => DADOSVIEWDEVOLUCAO.VLCMVDEVOLBONIF,
                                       VLCUSTOFIN        => DADOSVIEWDEVOLUCAO.VLCUSTOFIN,
                                       LITRAGEM          => DADOSVIEWDEVOLUCAO.LITRAGEM,
                                       DEVOLTAB          => DADOSVIEWDEVOLUCAO.DEVOLTAB,
                                       TOTPESO           => DADOSVIEWDEVOLUCAO.TOTPESO,
                                       TOTPESOMOV        => DADOSVIEWDEVOLUCAO.TOTPESOMOV,
                                       CODCLIPRINC       => DADOSVIEWDEVOLUCAO.CODCLIPRINC,
                                       CODUSURDEVOL      => DADOSVIEWDEVOLUCAO.CODUSURDEVOL,
                                       CODUSUR           => DADOSVIEWDEVOLUCAO.CODUSUR,
                                       CODUSURMOV        => DADOSVIEWDEVOLUCAO.CODUSURMOV,
                                       ORIGEMPED         => DADOSVIEWDEVOLUCAO.ORIGEMPED,
                                       VLST              => DADOSVIEWDEVOLUCAO.VLST,
                                       VLIPI             => DADOSVIEWDEVOLUCAO.VLIPI,
                                       ICMSRETIDO_BONIF  => DADOSVIEWDEVOLUCAO.ICMSRETIDO_BONIF,
                                       VLIPI_BONIF       => DADOSVIEWDEVOLUCAO.VLIPI_BONIF,
                                       NUMLOTE           => DADOSVIEWDEVOLUCAO.NUMLOTE,
                                       SERIE             => DADOSVIEWDEVOLUCAO.SERIE,
                                       CODFORNECPRINC    => DADOSVIEWDEVOLUCAO.CODFORNECPRINC,
                                       FORNECPRINC       => DADOSVIEWDEVOLUCAO.FORNECPRINC,
                                       ESPECIE           => DADOSVIEWDEVOLUCAO.ESPECIE,
                                       SITUACAONFE       => DADOSVIEWDEVOLUCAO.SITUACAONFE,
                                       VLREPASSE         => DADOSVIEWDEVOLUCAO.VLREPASSE,
                                       NUMORIGINAL       => DADOSVIEWDEVOLUCAO.NUMORIGINAL,
                                       PESOLIQ           => DADOSVIEWDEVOLUCAO.PESOLIQ,
                                       CGCENT            => DADOSVIEWDEVOLUCAO.CGCENT,
                                       IEENT             => DADOSVIEWDEVOLUCAO.IEENT,
                                       MUNICENT          => DADOSVIEWDEVOLUCAO.MUNICENT,
                                       TIPOFJ            => DADOSVIEWDEVOLUCAO.TIPOFJ,
                                       CONSUMIDORFINAL   => DADOSVIEWDEVOLUCAO.CONSUMIDORFINAL,
                                       BONIFICADO        => DADOSVIEWDEVOLUCAO.BONIFICADO,
                                       VLVERBACMV        => DADOSVIEWDEVOLUCAO.VLVERBACMV,
                                       VLVERBACMVCLI     => DADOSVIEWDEVOLUCAO.VLVERBACMVCLI,
                                       VLFECP            => DADOSVIEWDEVOLUCAO.VLFECP,
                                       VLFECPBONIFIC     => DADOSVIEWDEVOLUCAO.VLFECPBONIFIC);
  
    PIPE ROW(VTDEVOLUCAO);
  END LOOP;
  CLOSE C_ITENS;

  RETURN;
  --  RETURN VTDEVOLUCAO;
END;