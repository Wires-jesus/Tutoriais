CREATE OR REPLACE FUNCTION RET_TABLE_VIEW_DEVOLAVULSA(PDDATAINI   IN DATE,
                                                      PDDATAFIM   IN DATE,
                                                      PSCODFILIAL IN VARCHAR2)
  RETURN TABELA_VIEW_DEVOLAVULSA
  PIPELINED IS
  VTDEVOLAVULSA TIPO_VIEW_DEVOLAVULSA;

  DADOSVIEWDEVOLAVULSA   VIEW_DEVOL_RESUMO_FATURAVULSA %ROWTYPE;
  V_SQL_VIEW_DEVOLAVULSA VARCHAR2(32000);
  C_ITENS                SYS_REFCURSOR;

  --
  FUNCTION F_GETSQL_VIEW_DEVOLAVULSA(PDATAINI   IN DATE,
                                     PDATAFIM   IN DATE,
                                     PCODFILIAL IN VARCHAR2) RETURN CLOB IS

    V_SQL VARCHAR2(32000) := '';
  BEGIN
    SELECT V.TEXT
      INTO V_SQL
      FROM ALL_VIEWS V
     WHERE V.VIEW_NAME = 'VIEW_DEVOL_RESUMO_FATURAVULSA'
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
  -- RETORNA O SQL DA VIEW: VIEW_DEVOL_RESUMO_FATURAVULSA
  V_SQL_VIEW_DEVOLAVULSA := F_GETSQL_VIEW_DEVOLAVULSA(PDDATAINI, PDDATAFIM, PSCODFILIAL);
 
  OPEN C_ITENS FOR V_SQL_VIEW_DEVOLAVULSA;
  LOOP
    FETCH C_ITENS
      INTO DADOSVIEWDEVOLAVULSA;
  
    EXIT WHEN C_ITENS%NOTFOUND;
  
    VTDEVOLAVULSA := TIPO_VIEW_DEVOLAVULSA(CODFILIAL         => DADOSVIEWDEVOLAVULSA.CODFILIAL,
                                           CODSUPERVISOR     => DADOSVIEWDEVOLAVULSA.CODSUPERVISOR,
                                           CODUSUR           => DADOSVIEWDEVOLAVULSA.CODUSUR,
                                           CODUSURMOV        => DADOSVIEWDEVOLAVULSA.CODUSURMOV,
                                           CODSUPERVMOV      => DADOSVIEWDEVOLAVULSA.CODSUPERVMOV,
                                           VLTOTAL           => DADOSVIEWDEVOLAVULSA.VLTOTAL,
                                           DTENT             => DADOSVIEWDEVOLAVULSA.DTENT,
                                           UF                => DADOSVIEWDEVOLAVULSA.UF,
                                           VLDEVCMVAVULSAI   => DADOSVIEWDEVOLAVULSA.VLDEVCMVAVULSAI,
                                           VLST              => DADOSVIEWDEVOLAVULSA.VLST,
                                           VLIPI             => DADOSVIEWDEVOLAVULSA.VLIPI,
                                           VLREPASSE         => DADOSVIEWDEVOLAVULSA.VLREPASSE,
                                           CODMARCA          => DADOSVIEWDEVOLAVULSA.CODMARCA,
                                           CODLINHAPROD      => DADOSVIEWDEVOLAVULSA.CODLINHAPROD,
                                           CODEPTO           => DADOSVIEWDEVOLAVULSA.CODEPTO,
                                           CODPROD           => DADOSVIEWDEVOLAVULSA.CODPROD,
                                           CODPLPAG          => DADOSVIEWDEVOLAVULSA.CODPLPAG,
                                           NUMREGIAO         => DADOSVIEWDEVOLAVULSA.NUMREGIAO,
                                           CODPRACA          => DADOSVIEWDEVOLAVULSA.CODPRACA,
                                           ROTA              => DADOSVIEWDEVOLAVULSA.ROTA,
                                           VIP               => DADOSVIEWDEVOLAVULSA.VIP,
                                           CODATIV           => DADOSVIEWDEVOLAVULSA.CODATIV,
                                           CODATIVPRINC      => DADOSVIEWDEVOLAVULSA.CODATIVPRINC,
                                           VLCUSTOFIN        => DADOSVIEWDEVOLAVULSA.VLCUSTOFIN,
                                           QT                => DADOSVIEWDEVOLAVULSA.QT,
                                           VLDEVOLUCAO       => DADOSVIEWDEVOLAVULSA.VLDEVOLUCAO,
                                           VLOUTRAS          => DADOSVIEWDEVOLAVULSA.VLOUTRAS,
                                           VLFRETE           => DADOSVIEWDEVOLAVULSA.VLFRETE,
                                           SUPERV            => DADOSVIEWDEVOLAVULSA.SUPERV,
                                           NOME              => DADOSVIEWDEVOLAVULSA.NOME,
                                           TOTPESO           => DADOSVIEWDEVOLAVULSA.TOTPESO,
                                           NUMNOTA           => DADOSVIEWDEVOLAVULSA.NUMNOTA,
                                           NUMTRANSENT       => DADOSVIEWDEVOLAVULSA.NUMTRANSENT,
                                           CODDEVOL          => DADOSVIEWDEVOLAVULSA.CODDEVOL,
                                           DEVOLITEM         => DADOSVIEWDEVOLAVULSA.DEVOLITEM,
                                           MOTIVO            => DADOSVIEWDEVOLAVULSA.MOTIVO,
                                           CLIENTE           => DADOSVIEWDEVOLAVULSA.CLIENTE,
                                           MOTIVO2           => DADOSVIEWDEVOLAVULSA.MOTIVO2,
                                           CODCLI            => DADOSVIEWDEVOLAVULSA.CODCLI,
                                           CODMOTORISTADEVOL => DADOSVIEWDEVOLAVULSA.CODMOTORISTADEVOL,
                                           CODFORNEC         => DADOSVIEWDEVOLAVULSA.CODFORNEC,
                                           CODFORNECMOV      => DADOSVIEWDEVOLAVULSA.CODFORNECMOV,
                                           CODFORNECPRINC    => DADOSVIEWDEVOLAVULSA.CODFORNECPRINC,
                                           EMBALAGEM         => DADOSVIEWDEVOLAVULSA.EMBALAGEM,
                                           UNIDADE           => DADOSVIEWDEVOLAVULSA.UNIDADE,
                                           DESCRICAO         => DADOSVIEWDEVOLAVULSA.DESCRICAO,
                                           BONIFICADO        => DADOSVIEWDEVOLAVULSA.BONIFICADO,
                                           CODSEC            => DADOSVIEWDEVOLAVULSA.CODSEC,
                                           NUMORIGINAL       => DADOSVIEWDEVOLAVULSA.NUMORIGINAL,
                                           CODAUXILIAR       => DADOSVIEWDEVOLAVULSA.CODAUXILIAR,
                                           IEENT             => DADOSVIEWDEVOLAVULSA.IEENT,
                                           ESTENT            => DADOSVIEWDEVOLAVULSA.ESTENT,
                                           CGCENT            => DADOSVIEWDEVOLAVULSA.CGCENT,
                                           MUNICENT          => DADOSVIEWDEVOLAVULSA.MUNICENT,
                                           CODCATEGORIA      => DADOSVIEWDEVOLAVULSA.CODCATEGORIA,
                                           CODSUBCATEGORIA   => DADOSVIEWDEVOLAVULSA.CODSUBCATEGORIA,
                                           NUMTRANSVENDA     => DADOSVIEWDEVOLAVULSA.NUMTRANSVENDA,
                                           ESPECIE           => DADOSVIEWDEVOLAVULSA.ESPECIE,
                                           SITUACAONFE       => DADOSVIEWDEVOLAVULSA.SITUACAONFE,
                                           VLFECP            => DADOSVIEWDEVOLAVULSA.VLFECP);										   
  
    PIPE ROW(VTDEVOLAVULSA);
  END LOOP;
  CLOSE C_ITENS;

  RETURN;
END;