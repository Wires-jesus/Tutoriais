





































































 



















CREATE OR REPLACE PACKAGE BODY IMPORTARVENDAS
IS
   VALIQFCP PCPEDI.ALIQFCP%TYPE;
   VALIQICMSFECP PCPEDI.ALIQICMSFECP%TYPE;
   VUTILIZOUMOTORCALCULO VARCHAR2(1);

PROCEDURE PROC_BLOQUEIA_PEDIDO(PNUMPED IN NUMBER, PMOTIVO IN VARCHAR2) 
IS
BEGIN
   IF PNUMPED IS NOT NULL THEN
      PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(PNUMPED, 25, PMOTIVO, 'C', NULL);
   END IF;
END;


PROCEDURE PROC_VALIDAR_BLOQUEIO(PNUMPED IN NUMBER, PPOSICAO IN VARCHAR2) 
IS
     VNUMPED NUMBER;
BEGIN
   IF PPOSICAO <> 'B' THEN
      VNUMPED := 0;
        
      BEGIN
         SELECT NVL(NUMPED,0)
         INTO VNUMPED
         FROM PCBLOQUEIOSPEDIDO 
         WHERE NUMPED = PNUMPED
           AND ROWNUM = 1;     
      EXCEPTION WHEN OTHERS THEN
         VNUMPED := 0;
      END;
        
      IF VNUMPED > 0 THEN
         UPDATE PCPEDC SET POSICAO = 'B'
         WHERE NUMPED = PNUMPED
           AND POSICAO <> 'B';
   
         UPDATE PCPEDI SET POSICAO = 'B'
         WHERE NUMPED = PNUMPED
           AND POSICAO <> 'B';
      END IF;  
   END IF;
END PROC_VALIDAR_BLOQUEIO;


PROCEDURE PROC_REGISTRALOG(P_NUMPED        IN PCPEDC.NUMPED%TYPE,
                           P_NUMPEDRCA     IN PCPEDC.NUMPEDCLI%TYPE,
                           P_CODPROD       IN PCPRODUT.CODPROD%TYPE,
                           P_CODAUXILIAR   IN PCPEDI.CODAUXILIAR%TYPE,
                           P_NUMSEQORIG    IN PCPEDI.NUMSEQ%TYPE,
                           P_CODCLI        IN PCCLIENT.CODCLI%TYPE,
                           P_CODUSUR       IN PCPEDC.CODUSUR%TYPE,
                           P_CODIGOCOTACAO IN PCCOTA.CODCOTACAO%TYPE,
                           P_NUMRECADOFV   IN PCRECFUNC.NUMRECADOFV%TYPE,
                           P_INTEGRADORA   IN PCPEDC.INTEGRADORA%TYPE,
                           P_CODRETORNOS   IN VARCHAR2,
                           P_TIPOREG       IN VARCHAR2,
                           -- 1 = generico / 2 = cabecalho / 3 = itens
                           P_ERRO     IN VARCHAR2,
                           P_LINHAREG IN NUMBER) IS
BEGIN
   VNGCONTADOR := VNGCONTADOR + 1;
   GVETREGISTRALOG(VNGCONTADOR).NUMPED := P_NUMPED;
   GVETREGISTRALOG(VNGCONTADOR).NUMPEDRCA := P_NUMPEDRCA;
   GVETREGISTRALOG(VNGCONTADOR).CODPROD := P_CODPROD;
   GVETREGISTRALOG(VNGCONTADOR).CODAUXILIAR := P_CODAUXILIAR;
   GVETREGISTRALOG(VNGCONTADOR).NUMSEQORIG := P_NUMSEQORIG;
   GVETREGISTRALOG(VNGCONTADOR).CODCLI := P_CODCLI;
   GVETREGISTRALOG(VNGCONTADOR).CODUSUR := P_CODUSUR;
   GVETREGISTRALOG(VNGCONTADOR).CODIGOCOTACAO := P_CODIGOCOTACAO;
   GVETREGISTRALOG(VNGCONTADOR).NUMRECADOFV := P_NUMRECADOFV;
   GVETREGISTRALOG(VNGCONTADOR).INTEGRADORA := P_INTEGRADORA;
   GVETREGISTRALOG(VNGCONTADOR).CODRETORNOS := P_CODRETORNOS;
   GVETREGISTRALOG(VNGCONTADOR).TIPOREG := P_TIPOREG;
   GVETREGISTRALOG(VNGCONTADOR).ERRO := P_ERRO;
   GVETREGISTRALOG(VNGCONTADOR).LINHAREG := P_LINHAREG;
END PROC_REGISTRALOG;


PROCEDURE PROC_LERPARAMETROS(P_EXISTERRO IN OUT BOOLEAN)
IS
   VSDIRIMPORTACAOFV PCCONSUM.DIRIMPORTACAOFV%TYPE;
BEGIN
   SELECT * 
   INTO GREGPCCONSUM 
   FROM PCCONSUM;

   GREGPCCONSUM.CODFILIALFV      := NVL(GREGPCCONSUM.CODFILIALFV, '1');
   GREGPCCONSUM.NUMCASASDECVENDA := NVL(GREGPCCONSUM.NUMCASASDECVENDA, 2);
   VSDIRIMPORTACAOFV             := VSGBARRASO || 'sistema' || VSGBARRASO || 'winthor' || VSGBARRASO || 'palmtop';
   GREGPCCONSUM.DIRIMPORTACAOFV  := NVL(TRIM(GREGPCCONSUM.DIRIMPORTACAOFV), VSDIRIMPORTACAOFV);
   GREGPCCONSUM.USACREDRCA       := NVL(GREGPCCONSUM.USACREDRCA, 'N');
EXCEPTION WHEN OTHERS THEN
   P_EXISTERRO := TRUE;
   PROC_REGISTRALOG(NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    '1',
                    'Erro ao ler parametros#;' || SQLCODE || '-' ||
                    SQLERRM || ';',
                    NULL);
END PROC_LERPARAMETROS;


PROCEDURE PROC_DESCONTO_ITEM_VENDA(P_CODCLI IN PCCLIENT.CODCLI%TYPE,
   P_CODPROD IN NUMBER,
   P_CODPLPAG IN NUMBER,
   P_CODUSUR IN NUMBER,
   P_PERCDESCINFORMADO IN NUMBER,
   P_PTABELA IN NUMBER,
   P_PTABELAAVISTA IN NUMBER,
   P_QTITEM IN NUMBER,
   P_ORIGEMPED IN VARCHAR2,
   P_TIPOCARGA IN VARCHAR2,
   P_CODFILIAL IN VARCHAR2,
   P_DATAPEDIDO IN DATE,
   P_SOMENTEDESAUT IN VARCHAR2,
   P_PRECOFIXO IN VARCHAR2,
   P_PVENDA IN NUMBER,
   P_DESCONTOPAUTADO IN NUMBER,
   P_CODFILIALNF IN VARCHAR2,
   P_MENSAGEMPOLITICA IN OUT VARCHAR2,
   P_DTFIM IN OUT DATE,
   P_ALTERAPTABELA IN OUT VARCHAR2,
   P_PERCDESCPOLITICA IN OUT NUMBER,
   P_BASECREDDEBRCA IN OUT VARCHAR2, 
   P_CREDITASOBREPOLITICA IN OUT VARCHAR2, 
   P_PERCPBASERCA IN OUT NUMBER,
   P_PRIORITARIA_AUX IN OUT VARCHAR2, 
   P_QUESTIONAPRIORITARIA_AUX IN OUT VARCHAR2,
   P_CODPOLPBASERCA_561 IN OUT NUMBER, 
   P_EXISTEPOLITICA IN OUT BOOLEAN)
IS
   vCODDESCONTO NUMBER;
BEGIN
   P_EXISTEPOLITICA := TRUE;
   P_PERCPBASERCA   := 0;
   P_PRIORITARIA_AUX := ''; 
   P_QUESTIONAPRIORITARIA_AUX := '';
   
   BEGIN
      SELECT MSG, --VARCHAR2
             DATAFINAL, -- DATE
             ALTERAPTABELA, -- VARCHAR2
             PERCDESC, -- NUMBER VNPERCDESCPOLITICA            
             POLITICABASEDEBITA,-- VARCHAR2 VSBASECREDDEBRCA
             POLITICABASECREDITA, --VARCHAR2 VSCREDITASOBREPOLITICA
             CODESCONTOBASE, -- NUMMBER  VNCODPOLPBASERCA_561pr
             CODESCONTO -- NUMBER vCODESCONTO
      INTO P_MENSAGEMPOLITICA,
           P_DTFIM,
           P_ALTERAPTABELA,
           P_PERCDESCPOLITICA,
           P_BASECREDDEBRCA, 
           P_CREDITASOBREPOLITICA, 
           P_CODPOLPBASERCA_561,
           vCODDESCONTO
      FROM TABLE(VENDAS.DESCONTO_ITEM_VENDA(P_CODCLI,
                                            P_CODPROD,
                                            P_CODPLPAG,
                                            P_CODUSUR,
                                            P_PERCDESCINFORMADO,
                                            P_PTABELA,
                                            P_PTABELAAVISTA,
                                            P_QTITEM,
                                            P_ORIGEMPED,
                                            P_TIPOCARGA,
                                            P_CODFILIAL,
                                            P_DATAPEDIDO,
                                            P_SOMENTEDESAUT,
                                            P_PRECOFIXO,
                                            P_PVENDA,
                                            P_DESCONTOPAUTADO,
                                            P_CODFILIALNF
                                           ));
   EXCEPTION WHEN OTHERS THEN
      P_MENSAGEMPOLITICA := '';
      P_DTFIM := NULL;
      P_ALTERAPTABELA := '';
      P_PERCDESCPOLITICA := 0;
      P_BASECREDDEBRCA := '';
      P_CREDITASOBREPOLITICA := ''; 
      P_CODPOLPBASERCA_561 := 0;
      vCODDESCONTO := 0;
      P_EXISTEPOLITICA := FALSE;
   END;
   
   IF P_CODPOLPBASERCA_561 > 0 THEN      
      BEGIN
         SELECT NVL(PERCDESC,0)
         INTO P_PERCPBASERCA
         FROM PCDESCONTO
         WHERE CODDESCONTO = P_CODPOLPBASERCA_561;
      EXCEPTION WHEN OTHERS THEN
         P_PERCPBASERCA := 0;
      END;
   END IF;
   
   IF vCODDESCONTO > 0 THEN
      BEGIN
         SELECT NVL(PRIORITARIA,'N'),
                NVL(PRIORITARIAGERAL,'N')
         INTO P_PRIORITARIA_AUX, 
              P_QUESTIONAPRIORITARIA_AUX
         FROM PCDESCONTO
         WHERE CODDESCONTO = vCODDESCONTO;
      EXCEPTION WHEN OTHERS THEN
         P_PRIORITARIA_AUX := 'N';
         P_QUESTIONAPRIORITARIA_AUX := 'N';
      END;
   END IF;
EXCEPTION WHEN OTHERS THEN
   P_MENSAGEMPOLITICA := '';
   P_DTFIM := NULL;
   P_ALTERAPTABELA := '';
   P_PERCDESCPOLITICA := 0;
   P_BASECREDDEBRCA := '';
   P_CREDITASOBREPOLITICA := ''; 
   P_CODPOLPBASERCA_561 := 0;
   P_PERCPBASERCA := 0;
   P_PRIORITARIA_AUX := '';
   P_QUESTIONAPRIORITARIA_AUX := '';
   P_EXISTEPOLITICA := FALSE;
END PROC_DESCONTO_ITEM_VENDA;


FUNCTION FUNC_CALCULARPERDESCITEM(P_PTABELA IN PCPEDI.PTABELA%TYPE,
                                  P_PVENDA  IN PCPEDI.PVENDA%TYPE,
                                  P_INTEGRADORA IN PCPEDC.INTEGRADORA%TYPE) RETURN NUMBER 
IS
   VNPERDESC NUMBER;
BEGIN
   IF P_INTEGRADORA = 4 THEN
      IF ROUND(P_PTABELA,2) <> 0 THEN
         VNPERDESC := ((ROUND(P_PTABELA,2) - ROUND(P_PVENDA,2)) / ROUND(P_PTABELA,2)) * 100;
      ELSE
         VNPERDESC := 0;
      END IF;
   ELSE
      IF NVL(P_PTABELA,0) <> 0 THEN
         VNPERDESC := ((P_PTABELA - P_PVENDA) / P_PTABELA) * 100;
      ELSE
         VNPERDESC := 0;
      END IF;
   END IF;
   
   VNPERDESC := ROUND(VNPERDESC, GREGPCCONSUM.NUMCASASDECVENDA);
   RETURN VNPERDESC;
EXCEPTION WHEN OTHERS THEN
   RETURN 0;
END FUNC_CALCULARPERDESCITEM;


FUNCTION IMPORTAR_PEDIDO_PROXNUMPED(PCODUSUR IN NUMBER) RETURN NUMBER
IS
   vnPROXNUMPED PCPEDC.NUMPED%TYPE;
   vnNUMPED PCPEDC.NUMPED%TYPE;
   vsEXISTE VARCHAR2(1);
BEGIN
   vsEXISTE := 'S';

   WHILE vsEXISTE = 'S'
   LOOP
      vnPROXNUMPED := FERRAMENTAS.F_PROX_NUMPED(PCODUSUR);

      BEGIN
         SELECT NUMPED
         INTO vnNUMPED
         FROM PCPEDC
         WHERE NUMPED = vnPROXNUMPED;
      EXCEPTION WHEN OTHERS THEN
         vsEXISTE := 'N';
      END;
   END LOOP;

   RETURN  vnPROXNUMPED;
END IMPORTAR_PEDIDO_PROXNUMPED;


PROCEDURE GERARCARREGBALCAORESERVA(P_REGPEDIDO IN OUT T_CABPED) 
IS
   PNCAREGAMENTO  NUMBER;
   VNTOTPESOPED   NUMBER;
   VNTOTVOLUMEPED NUMBER;
   VNVLATENDPED   NUMBER;
BEGIN
   BEGIN
      SELECT PROXNUMCAR 
      INTO PNCAREGAMENTO 
      FROM PCCONSUM FOR UPDATE;

      UPDATE PCCONSUM SET PROXNUMCAR = NVL(PROXNUMCAR, 0) + 1;

      UPDATE PCPEDC
      SET NUMCAR    = PNCAREGAMENTO,
          POSICAO   = P_REGPEDIDO.POSICAO,
          TIPOCARGA = 'R'
      WHERE NUMPED IN (SELECT NUMPED
                       FROM PCPEDC
                       WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
                         AND CODUSUR = P_REGPEDIDO.CODUSUR
                         AND DATA = P_REGPEDIDO.DATA);

      UPDATE PCPEDI
      SET NUMCAR = PNCAREGAMENTO, POSICAO = P_REGPEDIDO.POSICAO
      WHERE NUMPED IN (SELECT NUMPED
                       FROM PCPEDC
                       WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
                         AND CODUSUR = P_REGPEDIDO.CODUSUR
                         AND DATA = P_REGPEDIDO.DATA);

      SELECT SUM(PCPEDI.QT * PCPEDI.PVENDA),
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.PESOLIQ, 0)) TOTPESO,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.VOLUME, 0)) TOTVOLUME
      INTO VNVLATENDPED, VNTOTPESOPED, VNTOTVOLUMEPED
      FROM PCPEDI, PCPRODUT
      WHERE PCPEDI.CODPROD = PCPRODUT.CODPROD
        AND PCPEDI.NUMPED IN (SELECT NUMPED
                              FROM PCPEDC
                              WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
                                AND CODUSUR = P_REGPEDIDO.CODUSUR
                                AND DATA = P_REGPEDIDO.DATA);

      INSERT INTO PCCARREG(NUMCAR,
                           DTSAIDA,
                           TOTPESO,
                           TOTVOLUME,
                           VLTOTAL,
                           DESTINO,
                           DATAMON,
                           CODVEICULO,
                           CODFUNCMON,
                           DTFECHA)
                    VALUES(PNCAREGAMENTO,
                           TRUNC(SYSDATE),
                           VNTOTPESOPED,
                           VNTOTVOLUMEPED,
                           VNVLATENDPED,
                           'VENDA BALCAO',
                           TRUNC(SYSDATE),
                           0,
                           0,
                           TRUNC(SYSDATE));
      COMMIT;

      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       52,
                       '2',
                       'CARREGAMENTO CRIADO PARA PEDIDO BALCAO RESERVA. NUMCAR = ' ||
                       TO_CHAR(PNCAREGAMENTO, '000000'),
                       NULL);
   EXCEPTION WHEN OTHERS THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       53,
                       '2',
                       'ERRO: NAO GEROU/ATUALIZOU CARREGAMENTO. NUMCAR = ' ||
                       TO_CHAR(PNCAREGAMENTO, '000000'),
                       NULL);
      ROLLBACK;
   END;
END GERARCARREGBALCAORESERVA;
  

PROCEDURE PROC_PROCESSARLEITURAPEDIDOS(P_EXISTERRO IN OUT BOOLEAN) 
IS 
   VBLERCABOK        BOOLEAN;
   VBLERITEMOK       BOOLEAN;
   VNCONTPED         INTEGER;
   VNCONTITEM        INTEGER;
   VNCONTORIGEMPRECO INTEGER;
   VDDATAINICIAL     DATE;
   VDDATAFINAL       DATE;
   VNCONTORIGEMCOMISS INTEGER;
   VNCONTORIGEMDESC   INTEGER;
BEGIN
   /* Campo IMPORTADO:
       Valor 0 = registro bloqueado.
       Valor 1 = registro liberado para leitura.
       Valor 2 = registro lido.
       Valor 3 = registro liberado para leitura novamente (rejeitado anteriormente).
   */
   -- Ajusta a faixa de datas conforme parametro.
   VDDATAINICIAL      := TRUNC(SYSDATE) - 365;
   VDDATAFINAL        := TRUNC(SYSDATE);
   VNCONTPED          := 0;
   VNCONTITEM         := 0;
   VNCONTORIGEMPRECO  := 0;
   VNCONTORIGEMCOMISS := 0;
   VNCONTORIGEMDESC   := 0;

   FOR CR_PEDCAB IN (SELECT T.TIPOINTEGRACAO,
                            T.CODUSUR CODIGO_VENDEDOR,
                            DECODE(T.TIPOINTEGRACAO, 'C', T.NUMPEDCLI, 'R', T.NUMPEDRCA) CODIGO_PEDIDO,
                            T.CODCLI CODIGO_CLIENTE,
                            T.CODPLPAG CODIGO_PLANOPAGAMENTO,
                            T.CODCOB CODIGO_COBRANCA,
                            T.CONDVENDA TIPO_VENDA,
                            T.OBS1,
                            T.OBS2,
                            T.OBSENTREGA1,
                            T.OBSENTREGA2,
                            T.OBSENTREGA3,
                            T.DTENTREGA DATA_EXTRA,
                            T.CODFILIAL,
                            T.CODFILIALNF,
                            T.CODAUTORIZACAOTEF,
                            T.NSUTEF,
                            T.CODADMCARTAO,
                            T.VLDESCONTOFINANCEIRO,
                            T.ORIGEMPED,
                            T.POSICAO,
                            NVL(T.INTEGRADORA, 0) INTEGRADORA,
                            T.EANENTREGA,
                            T.EANCOBRANCA,
                            T.PRAZO1 PARCELA1,
                            T.PRAZO2 PARCELA2,
                            T.PRAZO3 PARCELA3,
                            T.PRAZO4 PARCELA4,
                            T.PRAZO5 PARCELA5,
                            T.PRAZO6 PARCELA6,
                            T.PRAZO7 PARCELA7,
                            T.PRAZO8 PARCELA8,
                            T.PRAZO9 PARCELA9,
                            T.PRAZO10 PARCELA10,
                            T.PRAZO11 PARCELA11,
                            T.PRAZO12 PARCELA12,
                            T.VLFRETE,
                            T.NUMPEDORIGEM,
                            T.DTABERTURAPEDPALM,
                            NVL(T.CODEMITENTE, 8888) CODEMITENTE,
                            NVL(NVL(T.FRETEDESPACHO, C.FRETEDESPACHO), 'N') FRETEDESPACHO,
                            T.CODTRANSP,
                            T.NUMPEDTV1,
                            T.AGRUPAMENTO,
                            T.TURNOENTREGA,
                            T.VLENTRADA,
                            T.CODENDENTCLI,
                            T.CODCLINF,
                            T.CODCLIRECEBEDOR,
                            T.NUMREGIAOBROKER,
                            T.CODFORNECFRETE,
                            T.CODCLITV8,
                            T.CODENDENT,
                            T.PEDIDOPAGOECOMMERCE,
                            (SELECT ROWNUM FROM PCPEDCTEMP WHERE NUMPEDCLI = T.NUMPEDCLI AND NUMPEDRCA = T.NUMPEDRCA AND NUMPEDWEB = T.NUMPEDWEB) LINHA,
                            T.VLOUTRASDESP,
                            T.NUMPEDRCA,
                            T.VLDESCONTOCUPOM,
                            T.CNPJINTERMEDIADOR,
                            T.DESCINTERMEDIADOR,
							T.CODBNF
                     FROM PCPEDCTEMP T,
                          PCCLIENT C
                     WHERE NVL(T.CODCLINF,T.CODCLI) = C.CODCLI(+)
                       AND NVL(T.IMPORTADO, 'N') = 'N'
                       AND NVL(T.DATA, TRUNC(SYSDATE)) BETWEEN VDDATAINICIAL AND VDDATAFINAL
                       AND T.TIPOINTEGRACAO IN ('C', 'R')) 
   LOOP
      BEGIN
         VBLERCABOK                      := FALSE;
         GREGPEDIDO.CODRETORNOS          := NULL;
         GREGPEDIDO.TIPOINTEGRACAO       := CR_PEDCAB.TIPOINTEGRACAO;
         GREGPEDIDO.CODUSUR              := CR_PEDCAB.CODIGO_VENDEDOR;
         GREGPEDIDO.NUMPEDINT            := CR_PEDCAB.CODIGO_PEDIDO;
         GREGPEDIDO.CODCLI               := CR_PEDCAB.CODIGO_CLIENTE;
         GREGPEDIDO.CODPLPAG             := CR_PEDCAB.CODIGO_PLANOPAGAMENTO;
         GREGPEDIDO.CODCOB               := UPPER(CR_PEDCAB.CODIGO_COBRANCA);
         GREGPEDIDO.CONDVENDA            := CR_PEDCAB.TIPO_VENDA;
         GREGPEDIDO.OBS1                 := SUBSTR(CR_PEDCAB.OBS1, 1, 50);
         GREGPEDIDO.OBS2                 := SUBSTR(CR_PEDCAB.OBS2, 1, 50);
         GREGPEDIDO.OBSENTREGA1          := SUBSTR(CR_PEDCAB.OBSENTREGA1, 1, 75);
         GREGPEDIDO.OBSENTREGA2          := SUBSTR(CR_PEDCAB.OBSENTREGA2, 1, 75);
         GREGPEDIDO.OBSENTREGA3          := SUBSTR(CR_PEDCAB.OBSENTREGA3, 1, 75);
         GREGPEDIDO.DATA                 := TRUNC(SYSDATE);
         GREGPEDIDO.DTENTREGA            := CR_PEDCAB.DATA_EXTRA;
         GREGPEDIDO.CODFILIAL            := NVL(CR_PEDCAB.CODFILIAL, GREGPCCONSUM.CODFILIALFV);
         GREGPEDIDO.CODFILIALNF          := CR_PEDCAB.CODFILIALNF;
         GREGPEDIDO.CODAUTORIZACAOTEF    := CR_PEDCAB.CODAUTORIZACAOTEF;
         GREGPEDIDO.NSUTEF               := CR_PEDCAB.NSUTEF;
         GREGPEDIDO.CODADMCARTAO         := CR_PEDCAB.CODADMCARTAO;
         GREGPEDIDO.VLDESCONTOFINANCEIRO := CR_PEDCAB.VLDESCONTOFINANCEIRO;
         GREGPEDIDO.ORIGEMPED            := NVL(CR_PEDCAB.ORIGEMPED, 'F');
         GREGPEDIDO.POSICAO              := NVL(CR_PEDCAB.POSICAO, 'P');
         GREGPEDIDO.INTEGRADORA          := CR_PEDCAB.INTEGRADORA;
         GREGPEDIDO.EANENTREGA           := CR_PEDCAB.EANENTREGA;
         GREGPEDIDO.EANCOBRANCA          := CR_PEDCAB.EANCOBRANCA;
         GREGPEDIDO.PARCELA1             := CR_PEDCAB.PARCELA1;
         GREGPEDIDO.PARCELA2             := CR_PEDCAB.PARCELA2;
         GREGPEDIDO.PARCELA3             := CR_PEDCAB.PARCELA3;
         GREGPEDIDO.PARCELA4             := CR_PEDCAB.PARCELA4;
         GREGPEDIDO.PARCELA5             := CR_PEDCAB.PARCELA5;
         GREGPEDIDO.PARCELA6             := CR_PEDCAB.PARCELA6;
         GREGPEDIDO.PARCELA7             := CR_PEDCAB.PARCELA7;
         GREGPEDIDO.PARCELA8             := CR_PEDCAB.PARCELA8;
         GREGPEDIDO.PARCELA9             := CR_PEDCAB.PARCELA9;
         GREGPEDIDO.PARCELA10            := CR_PEDCAB.PARCELA10;
         GREGPEDIDO.PARCELA11            := CR_PEDCAB.PARCELA11;
         GREGPEDIDO.PARCELA12            := CR_PEDCAB.PARCELA12;
         GREGPEDIDO.VLFRETE              := CR_PEDCAB.VLFRETE;
         GREGPEDIDO.NUMPEDORIG           := CR_PEDCAB.NUMPEDORIGEM;
         GREGPEDIDO.DTABERTURAPEDPALM    := CR_PEDCAB.DTABERTURAPEDPALM;
         GREGPEDIDO.CODEMITENTE          := CR_PEDCAB.CODEMITENTE;
         GREGPEDIDO.FRETEDESPACHO        := CR_PEDCAB.FRETEDESPACHO;
         GREGPEDIDO.CODTRANSP            := CR_PEDCAB.CODTRANSP;
         GREGPEDIDO.NUMPEDTV1            := CR_PEDCAB.NUMPEDTV1;
         GREGPEDIDO.AGRUPAMENTO          := CR_PEDCAB.AGRUPAMENTO;
         GREGPEDIDO.TURNOENTREGA         := CR_PEDCAB.TURNOENTREGA;
         GREGPEDIDO.VLENTRADA            := CR_PEDCAB.VLENTRADA;
         GREGPEDIDO.CODENDENTCLI         := CR_PEDCAB.CODENDENTCLI;
         GREGPEDIDO.CODCLINF             := CR_PEDCAB.CODCLINF;
         GREGPEDIDO.CODCLIRECEBEDOR      := CR_PEDCAB.CODCLIRECEBEDOR;
         GREGPEDIDO.NUMREGIAOBROKER      := CR_PEDCAB.NUMREGIAOBROKER;
         GREGPEDIDO.CODFORNECFRETE       := CR_PEDCAB.CODFORNECFRETE;
         GREGPEDIDO.CODCLITV8            := CR_PEDCAB.CODCLITV8;
         GREGPEDIDO.CODENDENT            := CR_PEDCAB.CODENDENT;
         GREGPEDIDO.PEDIDOPAGOECOMMERCE  := CR_PEDCAB.PEDIDOPAGOECOMMERCE;
         GREGPEDIDO.VLOUTRASDESP         := CR_PEDCAB.VLOUTRASDESP; 
         GREGPEDIDO.VLDESCONTOCUPOM      := CR_PEDCAB.VLDESCONTOCUPOM;
         GREGPEDIDO.CNPJINTERMEDIADOR    := CR_PEDCAB.CNPJINTERMEDIADOR;
         GREGPEDIDO.DESCINTERMEDIADOR    := CR_PEDCAB.DESCINTERMEDIADOR;
		 GREGPEDIDO.CODBNF               := CR_PEDCAB.CODBNF; 

         IF GREGPEDIDO.INTEGRADORA = 23 THEN
            GREGPEDIDO.NUMPEDRCA := CR_PEDCAB.NUMPEDRCA;
         END IF;

         IF GREGPEDIDO.TIPOINTEGRACAO = 'C' THEN
            GREGPEDIDO.NUMPEDCLI := GREGPEDIDO.NUMPEDINT;
         ELSIF GREGPEDIDO.TIPOINTEGRACAO = 'R' AND GREGPEDIDO.INTEGRADORA <> 23 THEN
            GREGPEDIDO.NUMPEDRCA := GREGPEDIDO.NUMPEDINT;
         END IF;

         IF NVL(GREGPEDIDO.DTENTREGA, TRUNC(SYSDATE)) < TRUNC(SYSDATE) THEN
            GREGPEDIDO.DTENTREGA := TRUNC(SYSDATE);
         END IF;

         VBLERCABOK := TRUE;

         IF VBLERCABOK = TRUE THEN
            VNCONTPED := VNCONTPED + 1;
            GVET_REGPEDIDO(VNCONTPED) := GREGPEDIDO;
         END IF;

         IF VBLERCABOK = TRUE THEN
            FOR CR_PEDCORP IN (SELECT DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA) CODIGO_PEDIDO,
                                      CODPROD CODIGO_PRODUTO,
                                      QT QUANTIDADE,
                                      PVENDA PRECO_VENDA,
                                      CODAUXILIAR,
                                      CODFILIALRETIRA,
                                      NUMSEQ,
                                      NVL(INTEGRADORA, 0) INTEGRADORA,
                                      IDVENDA,
                                      TIPOENTREGA,
                                      NVL(MOVIMENTACONTACORRENTERCA,'N') MOVIMENTACONTACORRENTERCA,
                                      ROWNUM AS LINHA
                               FROM PCPEDITEMP
                               WHERE DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA) = GREGPEDIDO.NUMPEDINT
                                 AND TIPOINTEGRACAO IN ('C', 'R')
                                 AND NVL(INTEGRADORA, 0) = CR_PEDCAB.INTEGRADORA) 
            LOOP
               BEGIN
                  VBLERITEMOK              := FALSE;
                  GREGITEM.CODRETORNOS     := NULL;
                  GREGITEM.NUMPEDINT       := CR_PEDCORP.CODIGO_PEDIDO;
                  GREGITEM.CODPROD         := CR_PEDCORP.CODIGO_PRODUTO;
                  GREGITEM.QT              := CR_PEDCORP.QUANTIDADE;
                  GREGITEM.PVENDA          := CR_PEDCORP.PRECO_VENDA;
                  GREGITEM.CODAUXILIAR     := CR_PEDCORP.CODAUXILIAR;
                  GREGITEM.CODFILIALRETIRA := CR_PEDCORP.CODFILIALRETIRA;
                  GREGITEM.NUMSEQORIG      := CR_PEDCORP.NUMSEQ;
                  GREGITEM.INTEGRADORA     := CR_PEDCORP.INTEGRADORA;
                  GREGITEM.NUMPEDORIG      := GREGPEDIDO.NUMPEDORIG;
                  GREGITEM.IDVENDA         := CR_PEDCORP.IDVENDA;
                  GREGITEM.TIPOENTREGA     := CR_PEDCORP.TIPOENTREGA;
                  GREGITEM.MOVIMENTACONTACORRENTERCA := CR_PEDCORP.MOVIMENTACONTACORRENTERCA;
                  VBLERITEMOK              := TRUE;

                  IF VBLERITEMOK = TRUE THEN
                     VNCONTITEM := VNCONTITEM + 1;
                     GVET_REGITEM(VNCONTITEM) := GREGITEM;
                     -- incrementar contador de itens do pedido atual
                     GVET_REGPEDIDO(VNCONTPED).NUMITENS := NVL(GVET_REGPEDIDO(VNCONTPED).NUMITENS, 0) + 1;
                     --origempreco
                     VNCONTORIGEMPRECO := VNCONTORIGEMPRECO + 1;
                     GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).CODPROD := GREGITEM.CODPROD;
                     GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).DATA := GVET_REGPEDIDO(VNCONTPED).DATA;
                     GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).ORIGEMPED := GVET_REGPEDIDO(VNCONTPED).ORIGEMPED;
                     GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).CODEMITENTE := GVET_REGPEDIDO(VNCONTPED).CODEMITENTE;
                     GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).CODFILIAL := GVET_REGPEDIDO(VNCONTPED).CODFILIAL;
                     GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).USATRIBUTPORUF := 'N';
                     --origemcomiss
                     VNCONTORIGEMCOMISS := VNCONTORIGEMCOMISS + 1;
                     GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODPROD := GREGITEM.CODPROD;
                     GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).ORIGEMPED := GVET_REGPEDIDO(VNCONTPED).ORIGEMPED;
                     GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODAUXILIAR := GREGITEM.CODAUXILIAR;
                     GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODFILIAL := GVET_REGPEDIDO(VNCONTPED).CODFILIAL;
                     GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODUSUR := GVET_REGPEDIDO(VNCONTPED).CODUSUR;
                     --origemdesc
                     VNCONTORIGEMDESC := VNCONTORIGEMDESC + 1;
                     GVET_REGORIGEMDESC(VNCONTORIGEMDESC).CODPROD := GREGITEM.CODPROD;
                     GVET_REGORIGEMDESC(VNCONTORIGEMDESC).ORIGEMPED := GVET_REGPEDIDO(VNCONTPED).ORIGEMPED;
                     GVET_REGORIGEMDESC(VNCONTORIGEMDESC).CODAUXILIAR := GREGITEM.CODAUXILIAR;
                  END IF;
               EXCEPTION WHEN OTHERS THEN
                  PROC_REGISTRALOG(NULL,
                                   CR_PEDCORP.CODIGO_PEDIDO,
                                   CR_PEDCORP.CODIGO_PRODUTO,
                                   CR_PEDCORP.CODAUXILIAR,
                                   CR_PEDCORP.NUMSEQ,
                                   CR_PEDCAB.CODIGO_CLIENTE,
                                   CR_PEDCAB.CODIGO_VENDEDOR,
                                   NULL,
                                   NULL,
                                   CR_PEDCAB.INTEGRADORA,
                                   76,
                                   '3',
                                   'Erro ao ler Item do Pedido#;' || SQLCODE || '-' ||
                                   SQLERRM || ';',
                                   CR_PEDCORP.LINHA);
               END;
            END LOOP;
         END IF;
      EXCEPTION WHEN OTHERS THEN
         PROC_REGISTRALOG(NULL,
                          CR_PEDCAB.CODIGO_PEDIDO,
                          NULL,
                          NULL,
                          NULL,
                          CR_PEDCAB.CODIGO_CLIENTE,
                          CR_PEDCAB.CODIGO_VENDEDOR,
                          NULL,
                          NULL,
                          CR_PEDCAB.INTEGRADORA,
                          54,
                          '2',
                          'Erro ao ler pedido#;' || SQLCODE || '-' ||
                          SQLERRM || ';',
                          CR_PEDCAB.LINHA);
      END;
   END LOOP;
EXCEPTION WHEN OTHERS THEN
   P_EXISTERRO := TRUE;
   PROC_REGISTRALOG(NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    '1',
                    'Erro ao ler pedidos#;' || SQLCODE || '-' || SQLERRM || ';',
                    NULL);
END PROC_PROCESSARLEITURAPEDIDOS;


  PROCEDURE PROC_PROCESSARLEITURAPEDWEB(P_NUMPED    IN NUMBER,
                                        P_CODUSUR   IN NUMBER,
                                        P_EXISTERRO IN OUT BOOLEAN) IS
    VBLERCABOK         BOOLEAN;
    VBLERITEMOK        BOOLEAN;
    VNCONTPED          INTEGER;
    VNCONTITEM         INTEGER;
    VNCONTORIGEMPRECO  INTEGER;
    VNCONTORIGEMCOMISS INTEGER;
    VNCONTORIGEMDESC   INTEGER;
  BEGIN
    /*
       Campo IMPORTADO:
       Valor 0 = registro bloqueado.
       Valor 1 = registro liberado para leitura.
       Valor 2 = registro lido.
       Valor 3 = registro liberado para leitura novamente (rejeitado anteriormente).
    */
    VNCONTPED          := 0;
    VNCONTITEM         := 0;
    VNCONTORIGEMPRECO  := 0;
    VNCONTORIGEMCOMISS := 0;
    VNCONTORIGEMDESC   := 0;

    FOR CR_PEDCAB IN (SELECT T.CODUSUR CODIGO_VENDEDOR,
                             T.NUMPEDWEB CODIGO_PEDIDO,
                             T.CODCLI CODIGO_CLIENTE,
                             T.CODPLPAG CODIGO_PLANOPAGAMENTO,
                             T.CODCOB CODIGO_COBRANCA,
                             T.CONDVENDA TIPO_VENDA,
                             T.OBS1,
                             T.OBS2,
                             T.OBSENTREGA1,
                             T.OBSENTREGA2,
                             T.OBSENTREGA3,
                             T.DTENTREGA DATA_EXTRA,
                             T.CODFILIAL,
                             T.CODAUTORIZACAOTEF,
                             T.CODAUTORIZACAOTEFWEB,
                             T.NSUTEF,
                             T.CODADMCARTAO,
                             NVL(T.INTEGRADORA, 0) INTEGRADORA,
                             T.ORIGEMPED,
                             T.EANENTREGA,
                             T.EANCOBRANCA,
                             T.PRAZO1 PARCELA1,
                             T.PRAZO2 PARCELA2,
                             T.PRAZO3 PARCELA3,
                             T.PRAZO4 PARCELA4,
                             T.PRAZO5 PARCELA5,
                             T.PRAZO6 PARCELA6,
                             T.PRAZO7 PARCELA7,
                             T.PRAZO8 PARCELA8,
                             T.PRAZO9 PARCELA9,
                             T.PRAZO10 PARCELA10,
                             T.PRAZO11 PARCELA11,
                             T.PRAZO12 PARCELA12,
                             T.VLFRETE,
                             T.NUMPEDORIGEM,
                             T.CODFILIALNF,
                             T.DTABERTURAPEDPALM,
                             T.VLDESCONTOFINANCEIRO,
                             NVL(T.CODEMITENTE, 8888) CODEMITENTE,
                             NVL(NVL(T.FRETEDESPACHO, C.FRETEDESPACHO), 'N') FRETEDESPACHO,
                             T.CODTRANSP,
                             T.NUMPEDTV1,
                             T.AGRUPAMENTO,
                             T.TURNOENTREGA,
                             T.VLENTRADA,
                             T.CODENDENTCLI,
                             T.CODCLINF,
                             T.CODCLIRECEBEDOR,
                             T.NUMREGIAOBROKER,
                             T.CODFORNECFRETE,
                             T.CODCLITV8,
                             T.CODENDENT,
                             T.PEDIDOPAGOECOMMERCE,
                             (SELECT ROWNUM FROM PCPEDCTEMP WHERE NUMPEDCLI = T.NUMPEDCLI AND NUMPEDRCA = T.NUMPEDRCA AND NUMPEDWEB = T.NUMPEDWEB) LINHA,
                             T.VLOUTRASDESP,
                             T.VLDESCONTOCUPOM,
                             T.CNPJINTERMEDIADOR,
                             T.DESCINTERMEDIADOR,
							 T.CODBNF
                        FROM PCPEDCTEMP T,
                             PCCLIENT C
                       WHERE NVL(T.CODCLINF,T.CODCLI) = C.CODCLI(+)
                         AND NVL(T.IMPORTADO, 'N') = 'N'
                         AND T.NUMPEDWEB = P_NUMPED
                         AND T.CODUSUR = P_CODUSUR
                         AND T.TIPOINTEGRACAO = 'W') 
    LOOP
      BEGIN
        VBLERCABOK                      := FALSE;
        GREGPEDIDO.TIPOINTEGRACAO       := 'W';
        GREGPEDIDO.CODRETORNOS          := NULL;
        GREGPEDIDO.CODUSUR              := CR_PEDCAB.CODIGO_VENDEDOR;
        GREGPEDIDO.NUMPEDINT            := CR_PEDCAB.CODIGO_PEDIDO;
        GREGPEDIDO.NUMPEDWEB            := CR_PEDCAB.CODIGO_PEDIDO;
        GREGPEDIDO.NUMPEDRCA            := CR_PEDCAB.CODIGO_PEDIDO;
        GREGPEDIDO.CODCLI               := CR_PEDCAB.CODIGO_CLIENTE;
        GREGPEDIDO.CODPLPAG             := CR_PEDCAB.CODIGO_PLANOPAGAMENTO;
        GREGPEDIDO.CODCOB               := UPPER(CR_PEDCAB.CODIGO_COBRANCA);
        GREGPEDIDO.CONDVENDA            := CR_PEDCAB.TIPO_VENDA;
        GREGPEDIDO.OBS1                 := SUBSTR(CR_PEDCAB.OBS1, 1, 50);
        GREGPEDIDO.OBS2                 := SUBSTR(CR_PEDCAB.OBS2, 1, 50);
        GREGPEDIDO.OBSENTREGA1          := SUBSTR(CR_PEDCAB.OBSENTREGA1, 1, 75);
        GREGPEDIDO.OBSENTREGA2          := SUBSTR(CR_PEDCAB.OBSENTREGA2, 1, 75);
        GREGPEDIDO.OBSENTREGA3          := SUBSTR(CR_PEDCAB.OBSENTREGA3, 1, 75);
        GREGPEDIDO.DATA                 := TRUNC(SYSDATE);
        GREGPEDIDO.DTENTREGA            := CR_PEDCAB.DATA_EXTRA;
        GREGPEDIDO.CODFILIAL            := NVL(CR_PEDCAB.CODFILIAL, GREGPCCONSUM.CODFILIALFV);
        GREGPEDIDO.CODAUTORIZACAOTEF    := CR_PEDCAB.CODAUTORIZACAOTEF;
        GREGPEDIDO.NSUTEF               := CR_PEDCAB.NSUTEF;
        GREGPEDIDO.CODADMCARTAO         := CR_PEDCAB.CODADMCARTAO;
        GREGPEDIDO.INTEGRADORA          := CR_PEDCAB.INTEGRADORA;
        GREGPEDIDO.ORIGEMPED            := NVL(CR_PEDCAB.ORIGEMPED, 'W');
        GREGPEDIDO.EANENTREGA           := CR_PEDCAB.EANENTREGA;
        GREGPEDIDO.EANCOBRANCA          := CR_PEDCAB.EANCOBRANCA;
        GREGPEDIDO.PARCELA1             := CR_PEDCAB.PARCELA1;
        GREGPEDIDO.PARCELA2             := CR_PEDCAB.PARCELA2;
        GREGPEDIDO.PARCELA3             := CR_PEDCAB.PARCELA3;
        GREGPEDIDO.PARCELA4             := CR_PEDCAB.PARCELA4;
        GREGPEDIDO.PARCELA5             := CR_PEDCAB.PARCELA5;
        GREGPEDIDO.PARCELA6             := CR_PEDCAB.PARCELA6;
        GREGPEDIDO.PARCELA7             := CR_PEDCAB.PARCELA7;
        GREGPEDIDO.PARCELA8             := CR_PEDCAB.PARCELA8;
        GREGPEDIDO.PARCELA9             := CR_PEDCAB.PARCELA9;
        GREGPEDIDO.PARCELA10            := CR_PEDCAB.PARCELA10;
        GREGPEDIDO.PARCELA11            := CR_PEDCAB.PARCELA11;
        GREGPEDIDO.PARCELA12            := CR_PEDCAB.PARCELA12;
        GREGPEDIDO.VLFRETE              := CR_PEDCAB.VLFRETE;
        GREGPEDIDO.NUMPEDORIG           := CR_PEDCAB.NUMPEDORIGEM;
        GREGPEDIDO.CODFILIALNF          := CR_PEDCAB.CODFILIALNF;
        GREGPEDIDO.DTABERTURAPEDPALM    := CR_PEDCAB.DTABERTURAPEDPALM;
        GREGPEDIDO.VLDESCONTOFINANCEIRO := CR_PEDCAB.VLDESCONTOFINANCEIRO;
        GREGPEDIDO.CODEMITENTE          := CR_PEDCAB.CODEMITENTE;
        GREGPEDIDO.FRETEDESPACHO        := CR_PEDCAB.FRETEDESPACHO;
        GREGPEDIDO.CODTRANSP            := CR_PEDCAB.CODTRANSP;
        GREGPEDIDO.CODAUTORIZACAOTEFWEB := CR_PEDCAB.CODAUTORIZACAOTEFWEB;
        GREGPEDIDO.NUMPEDTV1            := CR_PEDCAB.NUMPEDTV1;
        GREGPEDIDO.AGRUPAMENTO          := CR_PEDCAB.AGRUPAMENTO;
        GREGPEDIDO.TURNOENTREGA         := CR_PEDCAB.TURNOENTREGA;
        GREGPEDIDO.VLENTRADA            := CR_PEDCAB.VLENTRADA;
        GREGPEDIDO.CODENDENTCLI         := CR_PEDCAB.CODENDENTCLI;
        GREGPEDIDO.CODCLINF             := CR_PEDCAB.CODCLINF;
        GREGPEDIDO.CODCLIRECEBEDOR      := CR_PEDCAB.CODCLIRECEBEDOR;
        GREGPEDIDO.NUMREGIAOBROKER      := CR_PEDCAB.NUMREGIAOBROKER;
        GREGPEDIDO.CODFORNECFRETE       := CR_PEDCAB.CODFORNECFRETE;
        GREGPEDIDO.CODCLITV8            := CR_PEDCAB.CODCLITV8;
        GREGPEDIDO.CODENDENT            := CR_PEDCAB.CODENDENT;
        GREGPEDIDO.PEDIDOPAGOECOMMERCE  := CR_PEDCAB.PEDIDOPAGOECOMMERCE;
        GREGPEDIDO.VLOUTRASDESP         := CR_PEDCAB.VLOUTRASDESP;
        GREGPEDIDO.VLDESCONTOCUPOM      := CR_PEDCAB.VLDESCONTOCUPOM;
        GREGPEDIDO.CNPJINTERMEDIADOR    := CR_PEDCAB.CNPJINTERMEDIADOR;
        GREGPEDIDO.DESCINTERMEDIADOR    := CR_PEDCAB.DESCINTERMEDIADOR;
		GREGPEDIDO.CODBNF               := CR_PEDCAB.CODBNF;

        IF NVL(GREGPEDIDO.DTENTREGA, TRUNC(SYSDATE)) < TRUNC(SYSDATE) THEN
           GREGPEDIDO.DTENTREGA := TRUNC(SYSDATE);
        END IF;

        VBLERCABOK := TRUE;

        IF VBLERCABOK = TRUE THEN
          VNCONTPED := VNCONTPED + 1;
          GVET_REGPEDIDO(VNCONTPED) := GREGPEDIDO;
        END IF;

        IF VBLERCABOK = TRUE THEN
          FOR CR_PEDCORP IN (SELECT NUMPEDWEB CODIGO_PEDIDO,
                                    CODPROD CODIGO_PRODUTO,
                                    QT QUANTIDADE,
                                    PVENDA PRECO_VENDA,
                                    CODAUXILIAR,
                                    CODFILIALRETIRA,
                                    NUMSEQ,
                                    NVL(INTEGRADORA, 0) INTEGRADORA,
                                    IDVENDA,
                                    TIPOENTREGA,
                                    NVL(MOVIMENTACONTACORRENTERCA,'N')  AS MOVIMENTACONTACORRENTERCA,
                                    ROWNUM AS LINHA
                               FROM PCPEDITEMP
                              WHERE NUMPEDWEB = P_NUMPED
                                AND CODUSUR = P_CODUSUR
                                AND TIPOINTEGRACAO = 'W'
                                AND NVL(INTEGRADORA, 0) =
                                    CR_PEDCAB.INTEGRADORA) 
          LOOP
            BEGIN
              VBLERITEMOK              := FALSE;
              GREGITEM.CODRETORNOS     := NULL;
              GREGITEM.NUMPEDINT       := CR_PEDCORP.CODIGO_PEDIDO;
              GREGITEM.CODPROD         := CR_PEDCORP.CODIGO_PRODUTO;
              GREGITEM.QT              := CR_PEDCORP.QUANTIDADE;
              GREGITEM.PVENDA          := CR_PEDCORP.PRECO_VENDA;
              GREGITEM.CODAUXILIAR     := CR_PEDCORP.CODAUXILIAR;
              GREGITEM.CODFILIALRETIRA := CR_PEDCORP.CODFILIALRETIRA;
              GREGITEM.NUMSEQORIG      := CR_PEDCORP.NUMSEQ;
              GREGITEM.INTEGRADORA     := CR_PEDCORP.INTEGRADORA;
              GREGITEM.NUMPEDORIG      := GREGPEDIDO.NUMPEDORIG;
              GREGITEM.IDVENDA         := CR_PEDCORP.IDVENDA;
              GREGITEM.TIPOENTREGA     := CR_PEDCORP.TIPOENTREGA;
              GREGITEM.MOVIMENTACONTACORRENTERCA := CR_PEDCORP.MOVIMENTACONTACORRENTERCA;
              VBLERITEMOK              := TRUE;

              IF VBLERITEMOK = TRUE THEN
                VNCONTITEM := VNCONTITEM + 1;
                GVET_REGITEM(VNCONTITEM) := GREGITEM;
                -- incrementar contador de itens do pedido atual
                GVET_REGPEDIDO(VNCONTPED).NUMITENS := NVL(GVET_REGPEDIDO(VNCONTPED).NUMITENS, 0) + 1;
                --origempreco
                VNCONTORIGEMPRECO := VNCONTORIGEMPRECO + 1;
                GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).CODPROD := GREGITEM.CODPROD;
                GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).DATA := GVET_REGPEDIDO(VNCONTPED).DATA;
                GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).ORIGEMPED := GVET_REGPEDIDO(VNCONTPED).ORIGEMPED;
                GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).CODEMITENTE := GVET_REGPEDIDO(VNCONTPED).CODEMITENTE;
                GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).CODFILIAL := GVET_REGPEDIDO(VNCONTPED).CODFILIAL;
                GVET_REGORIGEMPRECO(VNCONTORIGEMPRECO).USATRIBUTPORUF := 'N';
                --origemcomiss
                VNCONTORIGEMCOMISS := VNCONTORIGEMCOMISS + 1;
                GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODPROD := GREGITEM.CODPROD;
                GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).ORIGEMPED := GVET_REGPEDIDO(VNCONTPED).ORIGEMPED;
                GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODAUXILIAR := GREGITEM.CODAUXILIAR;
                GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODFILIAL := GVET_REGPEDIDO(VNCONTPED).CODFILIAL;
                GVET_REGORIGEMCOMISS(VNCONTORIGEMCOMISS).CODUSUR := GVET_REGPEDIDO(VNCONTPED).CODUSUR;
                --origemdesc
                VNCONTORIGEMDESC := VNCONTORIGEMDESC + 1;
                GVET_REGORIGEMDESC(VNCONTORIGEMDESC).CODPROD := GREGITEM.CODPROD;
                GVET_REGORIGEMDESC(VNCONTORIGEMDESC).ORIGEMPED := GVET_REGPEDIDO(VNCONTPED).ORIGEMPED;
                GVET_REGORIGEMDESC(VNCONTORIGEMDESC).CODAUXILIAR := GREGITEM.CODAUXILIAR;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                GREGITEM.CODRETORNOS := 76;

                PROC_REGISTRALOG(NULL,
                                 CR_PEDCORP.CODIGO_PEDIDO,
                                 CR_PEDCORP.CODIGO_PRODUTO,
                                 CR_PEDCORP.CODAUXILIAR,
                                 CR_PEDCORP.NUMSEQ,
                                 CR_PEDCAB.CODIGO_CLIENTE,
                                 CR_PEDCAB.CODIGO_VENDEDOR,
                                 NULL,
                                 NULL,
                                 CR_PEDCAB.INTEGRADORA,
                                 76,
                                 '3',
                                 'Erro ao ler Item do Pedido#;' || SQLCODE || '-' ||
                                 SQLERRM || ';',
                                 CR_PEDCORP.LINHA);
            END;
          END LOOP;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          PROC_REGISTRALOG(NULL,
                           CR_PEDCAB.CODIGO_PEDIDO,
                           NULL,
                           NULL,
                           NULL,
                           CR_PEDCAB.CODIGO_CLIENTE,
                           CR_PEDCAB.CODIGO_VENDEDOR,
                           NULL,
                           NULL,
                           CR_PEDCAB.INTEGRADORA,
                           54,
                           '2',
                           'Erro ao ler pedido#;' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           CR_PEDCAB.LINHA);
      END;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_EXISTERRO := TRUE;
      PROC_REGISTRALOG(NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       '1',
                       'Erro ao ler pedidos#;' || SQLCODE || '-' || SQLERRM || ';',
                       NULL);
  END PROC_PROCESSARLEITURAPEDWEB;


  PROCEDURE PROC_VALIDAVENCTOS(P_REGPEDIDO  IN OUT T_CABPED,
                               P_REGPLPAG   IN OUT T_PLANODEPAGAMENTO,
                               P_REGCLIENTE IN T_CLIENTEPEDIDO,
                               P_REGFILIAL  IN T_FILIAL,
                               P_MENSAGEM   OUT VARCHAR2) IS
    VICONT       NUMBER;
    VBVALIDO     BOOLEAN;
    VSMENSAGEM   VARCHAR2(1000);
    VICONTPARC   NUMBER;
    VIPARCELA    NUMBER;
    VDDATAINICIO DATE;
    VDDATAAUX    DATE;
    VNDIF        NUMBER;
    VNDIFTOT     NUMBER;
    VICONTADOR   NUMBER;
    VNPRAZOMEDIO NUMBER;
    VDDTVENC     DATE;
  BEGIN
    VSMENSAGEM := NULL;
    VICONT     := 0;
    VBVALIDO   := TRUE;

    IF P_REGPEDIDO.TIPOINTEGRACAO = 'C' THEN
      SELECT COUNT(*)
        INTO VICONT
        FROM PCPEDCVCTOTEMP P
       WHERE NUMPEDCLI = P_REGPEDIDO.NUMPEDCLI
         AND CODCLI = P_REGPEDIDO.CODCLI;

    ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'R' THEN
      SELECT COUNT(*)
        INTO VICONT
        FROM PCPEDCVCTOTEMP P
       WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
         AND CODUSUR = P_REGPEDIDO.CODUSUR;

    ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN

      SELECT COUNT(*)
        INTO VICONT
        FROM PCPEDCVCTOTEMP P
       WHERE NUMPEDWEB = P_REGPEDIDO.NUMPEDWEB
         AND CODCLI = P_REGPEDIDO.CODCLI
         AND INTEGRADORA = P_REGPEDIDO.INTEGRADORA;
    END IF;

    IF VICONT > 0 THEN
      IF VICONT > P_REGPLPAG.NUMPARCELAS THEN
        VBVALIDO := FALSE;
        VSMENSAGEM := 'Numero de parcelas enviadas é maior que o número de parcelas permitidas';
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 69;
      END IF;

      IF VBVALIDO = TRUE THEN
        VIPARCELA := 0;

        IF P_REGPEDIDO.TIPOINTEGRACAO = 'C' THEN
          FOR REG IN (SELECT P.NUMPARCELA, P.DTVENC
                        FROM PCPEDCVCTOTEMP P
                       WHERE P.NUMPEDCLI = P_REGPEDIDO.NUMPEDCLI
                         AND P.CODCLI = P_REGPEDIDO.CODCLI
                       ORDER BY NUMPARCELA) LOOP

            VIPARCELA := VIPARCELA + 1;

            IF VIPARCELA = 1 THEN
              VDDATAINICIO := TRUNC(SYSDATE);
            ELSE
              VDDATAINICIO := VDDATAAUX;
            END IF;

            IF VICONT = 1 THEN
              --parcela unica
              IF REG.DTVENC > (VDDATAINICIO + P_REGPLPAG.NUMDIAS) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.NUMDIAS, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.NUMDIAS, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                END IF;
              END IF;
            ELSE
              IF REG.DTVENC < (VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento menor que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 70;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento menor que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 70;
                END IF;
              END IF;

              IF REG.DTVENC > (VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                END IF;
              END IF;
            END IF;

            IF REG.NUMPARCELA <= 0 THEN
              VBVALIDO := FALSE;

              IF VSMENSAGEM IS NULL THEN
                VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                              ' enviada está com numero inválido !';

                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 72;
              ELSE
                VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                              ' Parcela : ' || REG.NUMPARCELA ||
                              ' enviada está com numero inválido !';
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 72;
              END IF;
            END IF;

            VDDATAAUX := REG.DTVENC;
          END LOOP;
        ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'R' THEN
          FOR REG IN (SELECT P.NUMPARCELA, P.DTVENC
                        FROM PCPEDCVCTOTEMP P
                       WHERE P.NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
                         AND P.CODUSUR = P_REGPEDIDO.CODUSUR
                       ORDER BY NUMPARCELA) LOOP

            VIPARCELA := VIPARCELA + 1;

            IF VIPARCELA = 1 THEN
              VDDATAINICIO := TRUNC(SYSDATE);
            ELSE
              VDDATAINICIO := VDDATAAUX;
            END IF;

            IF VICONT = 1 THEN
              --parcela unica
              IF REG.DTVENC > (VDDATAINICIO + P_REGPLPAG.NUMDIAS) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.NUMDIAS, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.NUMDIAS, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                END IF;
              END IF;
            ELSE
              IF REG.DTVENC < (VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento menor que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 70;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento menor que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 70;
                END IF;
              END IF;

              IF REG.DTVENC > (VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                END IF;
              END IF;
            END IF;

            IF REG.NUMPARCELA <= 0 THEN
              VBVALIDO := FALSE;

              IF VSMENSAGEM IS NULL THEN
                VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                              ' enviada está com numero inválido !';
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 72;
              ELSE
                VSMENSAGEM := VSMENSAGEM || CHR(13) || ' Parcela : ' || REG.NUMPARCELA ||
                              ' enviada está com numero inválido !';
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 72;
              END IF;
            END IF;

            VDDATAAUX := REG.DTVENC;
          END LOOP;
        ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
          FOR REG IN (SELECT P.NUMPARCELA, P.DTVENC
                        FROM PCPEDCVCTOTEMP P
                       WHERE P.NUMPEDWEB = P_REGPEDIDO.NUMPEDWEB
                         AND P.CODCLI = P_REGPEDIDO.CODCLI
                         AND P.INTEGRADORA = P_REGPEDIDO.INTEGRADORA
                       ORDER BY NUMPARCELA) LOOP

            VIPARCELA := VIPARCELA + 1;

            IF VIPARCELA = 1 THEN
              VDDATAINICIO := TRUNC(SYSDATE);
            ELSE
              VDDATAINICIO := VDDATAAUX;
            END IF;

            IF VICONT = 1 THEN
              --parcela unica
              IF REG.DTVENC > (VDDATAINICIO + P_REGPLPAG.NUMDIAS) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.NUMDIAS, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.NUMDIAS, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                END IF;
              END IF;
            ELSE
              IF REG.DTVENC < (VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento menor que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 70;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento menor que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 70;
                END IF;
              END IF;

              IF REG.DTVENC > (VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA) THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) || ' Parcela : ' || REG.NUMPARCELA ||
                                ' enviada está com data de vencimento maior que o permitido : ' ||
                                TO_DATE(VDDATAINICIO + P_REGPLPAG.DIASMAXPARCELA, 'dd/mm/yyyy');
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 71;
                END IF;
              END IF;
            END IF;

            IF REG.NUMPARCELA <= 0 THEN
              VBVALIDO := FALSE;

              IF VSMENSAGEM IS NULL THEN
                VSMENSAGEM := 'Parcela : ' || REG.NUMPARCELA ||
                              ' enviada está com numero inválido !';
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 72;
              ELSE
                VSMENSAGEM := VSMENSAGEM || CHR(13) || ' Parcela : ' || REG.NUMPARCELA ||
                              ' enviada está com numero inválido !';
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 72;
              END IF;
            END IF;

            VDDATAAUX := REG.DTVENC;
          END LOOP;
        END IF;

        IF VBVALIDO = TRUE THEN
          IF P_REGPEDIDO.TIPOINTEGRACAO = 'C' THEN
            BEGIN
              INSERT INTO PCPEDCVCTO
                (NUMPED, NUMPARCELA, DTVENC)
                SELECT P_REGPEDIDO.NUMPED, P.NUMPARCELA, P.DTVENC
                  FROM PCPEDCVCTOTEMP P
                 WHERE P.NUMPEDCLI = P_REGPEDIDO.NUMPEDCLI
                   AND P.CODCLI = P_REGPEDIDO.CODCLI
                 ORDER BY NUMPARCELA;
            EXCEPTION
              WHEN OTHERS THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Erro ao inserir na tabela pcpedcvcto ' ||
                                SQLCODE || ' - ' || SQLERRM;
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                'Erro ao inserir na tabela pcpedcvcto ' ||
                                SQLCODE || ' - ' || SQLERRM;
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
                END IF;
            END;
          ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'R' THEN
            BEGIN
              INSERT INTO PCPEDCVCTO
                (NUMPED, NUMPARCELA, DTVENC)
                SELECT P_REGPEDIDO.NUMPED, P.NUMPARCELA, P.DTVENC
                  FROM PCPEDCVCTOTEMP P
                 WHERE P.NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
                   AND P.CODUSUR = P_REGPEDIDO.CODUSUR
                 ORDER BY NUMPARCELA;
            EXCEPTION
              WHEN OTHERS THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Erro ao inserir na tabela pcpedcvcto ' ||
                                SQLCODE || ' - ' || SQLERRM;
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                'Erro ao inserir na tabela pcpedcvcto ' ||
                                SQLCODE || ' - ' || SQLERRM;
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
                END IF;
            END;
          ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
            BEGIN
              INSERT INTO PCPEDCVCTO
                (NUMPED, NUMPARCELA, DTVENC)
                SELECT P_REGPEDIDO.NUMPED, P.NUMPARCELA, P.DTVENC
                  FROM PCPEDCVCTOTEMP P
                 WHERE P.NUMPEDWEB = P_REGPEDIDO.NUMPEDWEB
                   AND P.CODCLI = P_REGPEDIDO.CODCLI
                   AND P.INTEGRADORA = P_REGPEDIDO.INTEGRADORA
                 ORDER BY NUMPARCELA;
            EXCEPTION
              WHEN OTHERS THEN
                VBVALIDO := FALSE;

                IF VSMENSAGEM IS NULL THEN
                  VSMENSAGEM := 'Erro ao inserir na tabela pcpedcvcto ' ||
                                SQLCODE || ' - ' || SQLERRM;
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
                ELSE
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                'Erro ao inserir na tabela pcpedcvcto ' ||
                                SQLCODE || ' - ' || SQLERRM;
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
                END IF;
            END;
          END IF;
        END IF;
      END IF;
      --não foi enviado registro na pcpedcvctotemp
    ELSE
      IF P_REGFILIAL.ACEITAVENDASEMDTVENCFV = 'S' THEN
        VIPARCELA := 0;

        FOR REG IN 1 .. P_REGPLPAG.NUMPARCELAS LOOP
          VIPARCELA := VIPARCELA + 1;

          IF VIPARCELA = 1 THEN
            VDDATAINICIO := TRUNC(SYSDATE);
          ELSE
            VDDATAINICIO := VDDATAAUX;
          END IF;

          VDDTVENC := VDDATAINICIO + P_REGPLPAG.DIASMINPARCELA;

          BEGIN
            INSERT INTO PCPEDCVCTO
              (NUMPED, NUMPARCELA, DTVENC)
            VALUES
              (P_REGPEDIDO.NUMPED, VIPARCELA, VDDTVENC);
          EXCEPTION
            WHEN OTHERS THEN
              VBVALIDO := FALSE;

              IF VSMENSAGEM IS NULL THEN
                VSMENSAGEM := 'Erro ao inserir na tabela pcpedcvcto ' ||
                              SQLCODE || ' - ' || SQLERRM;
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
              ELSE
                VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                              'Erro ao inserir na tabela pcpedcvcto ' ||
                              SQLCODE || ' - ' || SQLERRM;
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 73;
              END IF;
          END;
          VDDATAAUX := VDDTVENC;
        END LOOP;
      ELSE
        VBVALIDO := FALSE;

        IF VSMENSAGEM IS NULL THEN
          VSMENSAGEM := 'De acordo com parâmetro aceitavendasemdtvencfv é ncessário o envio de dados pcpedcvctoTEMP';
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 74;
        ELSE
          VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                        'De acordo com parâmetro aceitavendasemdtvencfv é necessário o envio de dados pcpedcvctoTEMP ';
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 74;
        END IF;
      END IF;
    END IF;

    IF VBVALIDO = TRUE THEN
      --prazo medio
      VNDIF      := 0;
      VNDIFTOT   := 0;
      VICONTPARC := 0;

      FOR REGPRAZO IN (SELECT NUMPARCELA, DTVENC
                         FROM PCPEDCVCTO
                        WHERE NUMPED = P_REGPEDIDO.NUMPED) 
      LOOP
        VNDIF := REGPRAZO.DTVENC - TRUNC(SYSDATE);
        VNDIFTOT := VNDIFTOT + VNDIF;
        VICONTPARC := VICONTPARC + 1;
      END LOOP;

      VNPRAZOMEDIO := TRUNC(VNDIFTOT / VICONTPARC);

      IF VNPRAZOMEDIO > P_REGPLPAG.NUMDIAS THEN
        VBVALIDO := FALSE;

        IF VSMENSAGEM IS NULL THEN
          VSMENSAGEM := 'Prazo medio: ' || VNPRAZOMEDIO ||
                        ' maior que o permitido : ' || P_REGPLPAG.NUMDIAS;
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 132;
        ELSE
          VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                        'Prazo medio: ' || VNPRAZOMEDIO ||
                        ' maior que o permitido : ' || P_REGPLPAG.NUMDIAS;
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 132;
        END IF;
      ELSE
        P_REGPEDIDO.PRAZOMEDIO := VNPRAZOMEDIO;
      END IF;

      IF VBVALIDO = TRUE THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCPLPAGVARIAVELJUROS P
         WHERE P.CODPLPAG = P_REGPLPAG.CODPLPAG
           AND P.PRAZOMEDIOINICIAL <= P_REGPEDIDO.PRAZOMEDIO
           AND P.PRAZOMEDIOFINAL >= P_REGPEDIDO.PRAZOMEDIO;

        IF VICONTADOR = 1 THEN
          SELECT NVL(P.PERCDESC, 0)
            INTO P_REGPEDIDO.PERCPLPAG
            FROM PCPLPAGVARIAVELJUROS P
           WHERE P.CODPLPAG = P_REGPLPAG.CODPLPAG
             AND P.PRAZOMEDIOINICIAL <= P_REGPEDIDO.PRAZOMEDIO
             AND P.PRAZOMEDIOFINAL >= P_REGPEDIDO.PRAZOMEDIO;
        END IF;

        SELECT COUNT(*) INTO VICONTADOR FROM PCPLPAG P WHERE CODPLPAG = 99;

        IF VICONTADOR = 1 THEN
          SELECT P.PRAZO1,
                 P.PRAZO2,
                 P.PRAZO3,
                 P.PRAZO4,
                 P.PRAZO5,
                 P.PRAZO6,
                 P.PRAZO7,
                 P.PRAZO8,
                 P.PRAZO9,
                 P.PRAZO10,
                 P.PRAZO11,
                 P.PRAZO12
            INTO P_REGPLPAG.PRAZO1,
                 P_REGPLPAG.PRAZO2,
                 P_REGPLPAG.PRAZO3,
                 P_REGPLPAG.PRAZO4,
                 P_REGPLPAG.PRAZO5,
                 P_REGPLPAG.PRAZO6,
                 P_REGPLPAG.PRAZO7,
                 P_REGPLPAG.PRAZO8,
                 P_REGPLPAG.PRAZO9,
                 P_REGPLPAG.PRAZO10,
                 P_REGPLPAG.PRAZO11,
                 P_REGPLPAG.PRAZO12
            FROM PCPLPAG P
           WHERE CODPLPAG = 99;
        END IF;
      END IF;
    END IF;

    IF VBVALIDO = FALSE THEN
      P_REGPEDIDO.VALIDO := FALSE;
      P_MENSAGEM         := VSMENSAGEM;
    END IF;
  END PROC_VALIDAVENCTOS;

  PROCEDURE PROC_PCPARAMFILIAL(P_CODFILIAL IN PCFILIAL.CODIGO%TYPE,
                               P_NOME      IN PCPARAMFILIAL.NOME%TYPE,
                               P_PADRAO    IN PCPARAMFILIAL.VALOR%TYPE,
                               P_VALOR     OUT PCPARAMFILIAL.VALOR%TYPE) IS

    VSNOME PCPARAMFILIAL.NOME%TYPE;
  BEGIN
    VSNOME := UPPER(TRIM(P_NOME));

    BEGIN
      SELECT NVL(P.VALOR, P_PADRAO)
        INTO P_VALOR
        FROM PCPARAMFILIAL P
       WHERE UPPER(TRIM(P.NOME)) = VSNOME
         AND P.CODFILIAL = P_CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          SELECT NVL(P.VALOR, P_PADRAO)
            INTO P_VALOR
            FROM PCPARAMFILIAL P
           WHERE UPPER(TRIM(P.NOME)) = VSNOME
             AND P.CODFILIAL = '99';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN

            P_VALOR := P_PADRAO;
        END;
      WHEN OTHERS THEN
        P_VALOR := P_PADRAO;
    END;
  END PROC_PCPARAMFILIAL;


PROCEDURE PROC_PCPARAMFILIALNUMBER(P_CODFILIAL IN PCFILIAL.CODIGO%TYPE,
                                   P_NOME      IN PCPARAMFILIAL.NOME%TYPE,
                                   P_PADRAO    IN PCPARAMFILIAL.VALOR%TYPE,
                                   P_VALOR     OUT NUMBER)
IS
   VSNOME PCPARAMFILIAL.NOME%TYPE;
BEGIN
   VSNOME := UPPER(TRIM(P_NOME));

   BEGIN
      SELECT TO_NUMBER(NVL(P.VALOR, P_PADRAO))
      INTO P_VALOR
      FROM PCPARAMFILIAL P
      WHERE UPPER(TRIM(P.NOME)) = VSNOME
        AND P.CODFILIAL = P_CODFILIAL;
   EXCEPTION WHEN INVALID_NUMBER THEN
      BEGIN
         SELECT TO_NUMBER(NVL(P.VALOR, P_PADRAO))
         INTO P_VALOR
         FROM PCPARAMFILIAL P
         WHERE UPPER(TRIM(P.NOME)) = VSNOME
           AND P.CODFILIAL = '99';
      EXCEPTION WHEN INVALID_NUMBER THEN
         P_VALOR := TO_NUMBER(P_PADRAO);
      END;
   WHEN OTHERS THEN
      P_VALOR := TO_NUMBER(P_PADRAO);
   END;
END PROC_PCPARAMFILIALNUMBER;


  FUNCTION FUNC_HORADIGITACAOPEDIDO(P_REGFILIAL IN T_FILIAL,
                                    P_MENSAGEM  OUT VARCHAR2) RETURN BOOLEAN IS

    VBRESULT                BOOLEAN := TRUE;
    VDHORAINICIALIMPORTACAO DATE;
    VDHORAFINALIMPORTACAO   DATE;
  BEGIN
    SELECT TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'dd/mm/yyyy') ||
                   TO_CHAR(HORAINICIALIMPORTACAOPED, 'hh24:mi'),
                   'dd/mm/yyyy hh24:mi') HORAINICIALDIGITACAOPED,
           CASE GREATEST(TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'dd/mm/yyyy') ||
                             TO_CHAR(HORAINICIALIMPORTACAOPED, 'hh24:mi'),
                             'dd/mm/yyyy hh24:mi'),
                     TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'dd/mm/yyyy') ||
                             TO_CHAR(HORAFINALIMPORTACAOPED, 'hh24:mi'),
                             'dd/mm/yyyy hh24:mi'))
             WHEN TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'dd/mm/yyyy') ||
                      TO_CHAR(HORAINICIALIMPORTACAOPED, 'hh24:mi'),
                      'dd/mm/yyyy hh24:mi') THEN
              TO_DATE(TO_CHAR((TRUNC(SYSDATE) + 1), 'dd/mm/yyyy') ||
                      TO_CHAR(HORAFINALIMPORTACAOPED, 'hh24:mi'),
                      'dd/mm/yyyy hh24:mi')
             ELSE
              TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'dd/mm/yyyy') ||
                      TO_CHAR(HORAFINALIMPORTACAOPED, 'hh24:mi'),
                      'dd/mm/yyyy hh24:mi')
           END HORAFINALDIGITACAOPED
      INTO VDHORAINICIALIMPORTACAO, VDHORAFINALIMPORTACAO
      FROM PCFILIAL
     WHERE CODIGO = P_REGFILIAL.CODIGO;

    P_MENSAGEM := NULL;

    VBRESULT := (SYSDATE >= VDHORAINICIALIMPORTACAO) AND
                (SYSDATE <= VDHORAFINALIMPORTACAO);

    IF VBRESULT = FALSE THEN
      P_MENSAGEM := 'Horário limite para digitação do pedido ultrapassado.#' ||
                    'Verifique rotina 535.';
    END IF;

    RETURN VBRESULT;
  END FUNC_HORADIGITACAOPEDIDO;


PROCEDURE PROC_PARAMETROS(P_REGPEDIDO IN T_CABPED,
                            P_REGFILIAL IN OUT T_FILIAL) IS
BEGIN
    SELECT CODIGO,
           UF,
           PERMITIRVENDAINTERESTADUALPF,
           PERMITIRVENDAESTADUALPFCOMIE,
           PERMITIRVENDAESTADUALPFSEMIE,
           NVL(PCFILIAL.USAINTEGRACAOWMS, 'N'),
           CALCESTDISPCOMQTMINAUTOSERV,
           NVL(ORIGEMCUSTOFILIALRETIRA, 'V'),
           'RI',
           'N',
           'N',
           'N',
           PCFILIAL.CALCULARIPIVENDA,
           'N',
           NVL(PCFILIAL.TIPOAVALIACAOCOMISSAO, 1),
           PCFILIAL.CONSIDERARCOMISSAOZERO,
           'N',
           'N',
           'P',
           'N',
           'S',
           'N',
           'N',
           'N',
           0,
           'N',
           0,
           'N',
           'S',
           'S',
           0,
           0,
           'N',
           ' ',
           'N',
           NULL,
           0,
           0,
           'S',
           'N',
           'N',
           'N',
           'N',
           'N',
           'N',
           'N',
           'N',
           0,
           NULL,
           'N'
      INTO P_REGFILIAL
      FROM PCFILIAL
     WHERE CODIGO = P_REGPEDIDO.CODFILIAL;

    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_BROKER', 'N', P_REGFILIAL.BROKER);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_TIPOBROKER', ' ', P_REGFILIAL.TIPOBROKER);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'TIPOIMPORTACAOVENDA', 'RI', P_REGFILIAL.TIPOIMPORTACAOVENDA);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'PERCACRESCVENDACUPOM', 'N', P_REGFILIAL.PERCACRESCVENDACUPOM);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'NAOUSARAUTDEBCREDPOLDESC', 'N', P_REGFILIAL.NAOUSARAUTDEBCREDPOLDESC);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'ACEITADESCTMKFV', 'N', P_REGFILIAL.ACEITADESCTMKFV);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_UTILIZAVENDAPOREMBALAGEM', 'N', P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_PRECOPOREMBALAGEM', 'N', P_REGFILIAL.PRECOPOREMBALAGEM);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_TIPOPRECIFICACAO', 'P', P_REGFILIAL.TIPOPRECIFICACAO);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'SOMACREDITOCLIPRINCIPAL', 'N', P_REGFILIAL.SOMACREDITOCLIPRINCIPAL);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'USABNFLIMITECREDITO', 'S', P_REGFILIAL.USABNFLIMITECREDITO);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'ACEITAVENDAAVISTACLIBLOQ', 'N', P_REGFILIAL.ACEITAVENDAAVISTACLIBLOQ);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'VALIDARPOLITICASDESCCLIBLOQ', 'N', P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'VERIFICABLOQUEIOSEFAZ', 'S', P_REGFILIAL.VERIFICABLOQUEIOSEFAZ);
    PROC_PCPARAMFILIALNUMBER(P_REGPEDIDO.CODFILIAL, 'VLMAXVENDABONIFICMES', 0, P_REGFILIAL.VLMAXVENDABONIFICMES);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'ACEITAVENDASEMDTVENCFV', 'N', P_REGFILIAL.ACEITAVENDASEMDTVENCFV);
    PROC_PCPARAMFILIALNUMBER(P_REGPEDIDO.CODFILIAL, 'PERMAXDESCVENDA', 0, P_REGFILIAL.PERMAXDESCVENDA);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'OBRIGATORIOVINCULARTV5COMTV1', 'N', P_REGFILIAL.OBRIGATORIOVINCULARTV5COMTV1);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'SEPARARPRODCOMRESTRICAOTRANSP', 'S', P_REGFILIAL.SEPARARPRODCOMRESTRICAOTRANSP);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'VALIDARPRECOVENDATV20', 'N', P_REGFILIAL.VALIDARPRECOVENDATV20);
    PROC_PCPARAMFILIALNUMBER(P_REGPEDIDO.CODFILIAL, 'VLMINVENDABKFILIAL', 0, P_REGFILIAL.VLMINVENDABKFILIAL);
    PROC_PCPARAMFILIALNUMBER(P_REGPEDIDO.CODFILIAL, 'VLMINVENDA', 0, P_REGFILIAL.VLMINVENDA);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_BLOQUEARPEDIDOSABAIXOVLMINIMO', 'N', P_REGFILIAL.BLOQUEARPEDIDOSABAIXOVLMINIMO);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'BLOQPEDLIMCRED', 'N', P_REGFILIAL.BLOQPEDLIMCRED);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_NUMREGIAOBALCAOINTER', NULL, P_REGFILIAL.NUMREGIAOBALCAOINTER);
    PROC_PCPARAMFILIALNUMBER(P_REGPEDIDO.CODFILIAL, 'VLMINVENDAFV', 0, P_REGFILIAL.VLMINVENDAFV);

    IF P_REGFILIAL.VLMINVENDAFV = 0 AND NVL(P_REGFILIAL.VLMINVENDA, 0) > 0 THEN
      P_REGFILIAL.VLMINVENDAFV := P_REGFILIAL.VLMINVENDA;
    END IF;

    PROC_PCPARAMFILIALNUMBER(P_REGPEDIDO.CODFILIAL, 'VLMINVENDABNFFV', 0, P_REGFILIAL.VLMINVENDABNFFV);

    IF P_REGFILIAL.VLMINVENDABNFFV = 0 AND
       NVL(GREGPCCONSUM.VLMINVENDABNF, 0) > 0 THEN
      P_REGFILIAL.VLMINVENDABNFFV := NVL(GREGPCCONSUM.VLMINVENDABNF, 0);
    END IF;

    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'VALIDAVLMINVENDABALCAO', 'S', P_REGFILIAL.VALIDAVLMINVENDABALCAO);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'CON_INFORMARECEBEDORVENDA', 'N', P_REGFILIAL.INFORMARECEBEDORVENDA);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_UTILIZANFE', 'N', P_REGFILIAL.UTILIZANFE);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'FIL_USACODCLIVENDA', 'N', P_REGFILIAL.USACODCLIVENDA);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'SEPARARPRODCOMST', 'N', P_REGFILIAL.SEPARARPRODCOMST);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'VERIFICAESTOQUECONT', 'N', P_REGFILIAL.VERIFICAESTOQUECONT);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'VALIDARCLISEFAZ', 'N', P_REGFILIAL.VALIDARCLISEFAZ);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'BLOQPEDABAIXOMARGEMFV', 'N', P_REGFILIAL.BLOQPEDABAIXOMARGEMFV);
    PROC_PCPARAMFILIAL(P_REGFILIAL.CODIGO, 'RESERVARESTOQUETV7', 'N', P_REGFILIAL.RESERVARESTOQUETV7);
    PROC_PCPARAMFILIALNUMBER(P_REGFILIAL.CODIGO, 'FIL_NUMMAXITENSNFE', 0, P_REGFILIAL.NUMMAXITENSNFE);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'ACEITAVENDASEMESTINT', NULL, P_REGFILIAL.ACEITAVENDASEMESTINT);
    PROC_PCPARAMFILIAL(P_REGPEDIDO.CODFILIAL, 'IMPORTAPEDIDOECOMMERCEPAGO', NULL, P_REGFILIAL.IMPORTAPEDIDOECOMMERCEPAGO);
END PROC_PARAMETROS;


PROCEDURE PROC_VALIDARCABPED(P_REGPEDIDO  IN OUT T_CABPED,
                             P_REGCLIENTE OUT T_CLIENTEPEDIDO,
                             P_REGRCA     OUT T_RCA,
                             P_REGREGIAO  OUT T_REGIAOCLIENTE,
                             P_REGPLPAG   OUT T_PLANODEPAGAMENTO,
                             P_REGCOB     OUT T_PCCOB,
                             P_REGFILIAL  OUT T_FILIAL) 
IS
   VICONTADOR      NUMBER;
   VSMENSAGEM      VARCHAR2(32767);
   VSCHAR          VARCHAR2(1) DEFAULT '#';
   VNNIVELVENDACLI PCCOB.NIVELVENDA%TYPE;
   VNPRAZO1      PCPEDC.PRAZO1%TYPE;
   VNPRAZO2      PCPEDC.PRAZO2%TYPE;
   VNPRAZO3      PCPEDC.PRAZO3%TYPE;
   VNPRAZO4      PCPEDC.PRAZO4%TYPE;
   VNPRAZO5      PCPEDC.PRAZO5%TYPE;
   VNPRAZO6      PCPEDC.PRAZO6%TYPE;
   VNPRAZO7      PCPEDC.PRAZO7%TYPE;
   VNPRAZO8      PCPEDC.PRAZO8%TYPE;
   VNPRAZO9      PCPEDC.PRAZO9%TYPE;
   VNPRAZO10     PCPEDC.PRAZO10%TYPE;
   VNPRAZO11     PCPEDC.PRAZO11%TYPE;
   VNPRAZO12     PCPEDC.PRAZO12%TYPE;
   VNCODPLPAG    PCPLPAG.CODPLPAG%TYPE;
   VSCODFILIALNF PCTABPRCLI.CODFILIALNF%TYPE;
   VBEXISTEPCPLPAGRESTRICAO   BOOLEAN;
   VSMENSAGEMPCPLPAGRESTRICAO VARCHAR2(1000);
   VBEXISTEPLPAGCLI        BOOLEAN;
   VSMENSAGEMPRAZOVARIAVEL VARCHAR2(1000);
   VNNUMREGIAOCLINF        PCREGIAO.NUMREGIAO%TYPE;
   VNCODCLIPRINC           PCCLIENT.CODCLI%TYPE;
   VDDTWMS                 PCPEDC.DTWMS%TYPE;
   VNNUMVIASMAPASEP        PCPEDC.NUMVIASMAPASEP%TYPE;
   VBHORAIMPORTACAOVALIDA BOOLEAN;
   VSMENSAGEMHORA         VARCHAR2(300);
   VSACESSO               PCCONTROI.ACESSO%TYPE;
   VPROXNUMPED PCPEDC.NUMPED%TYPE;
BEGIN
   P_REGPEDIDO.VALIDO              := TRUE;
   P_REGPEDIDO.VBEXISTEITEMCOMDESC := FALSE;
   VSMENSAGEM := NULL;
   P_REGPEDIDO.PRAZOMEDIO := NULL;
   -- Tratar complemento de pedido
   IF (NVL(P_REGPEDIDO.NUMPEDORIG, 0) <> 0) THEN
      IF P_REGPEDIDO.TIPOINTEGRACAO = 'C' THEN
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPEDC
         WHERE NUMPEDCLI = P_REGPEDIDO.NUMPEDORIG
           AND CODCLI = P_REGPEDIDO.CODCLI
           AND NVL(PCPEDC.BRINDE, 'N') <> 'S'
           AND PCPEDC.NUMPEDORIGEM IS NULL;
      ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'R' THEN
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPEDC
         WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDORIG
           AND CODUSUR = P_REGPEDIDO.CODUSUR
           AND NVL(PCPEDC.BRINDE, 'N') <> 'S'
           AND PCPEDC.NUMPEDORIGEM IS NULL;
      ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPEDC
         WHERE NUMPEDWEB = P_REGPEDIDO.NUMPEDORIG
           AND CODCLI = P_REGPEDIDO.CODCLI
           AND INTEGRADORA = P_REGPEDIDO.INTEGRADORA
           AND NVL(PCPEDC.BRINDE, 'N') <> 'S'
           AND PCPEDC.NUMPEDORIGEM IS NULL;
      END IF;

      IF VICONTADOR <> 0 THEN
         IF P_REGPEDIDO.TIPOINTEGRACAO = 'C' THEN
            SELECT PCPEDC.NUMPED,
                   PCPEDC.CODUSUR,
                   PCPEDC.CODCLI,
                   PCPEDC.DATA,
                   PCPEDC.CODPLPAG,
                   PCPEDC.CODCOB,
                   PCPEDC.CONDVENDA,
                   PCPEDC.POSICAO,
                   PCPEDC.NUMCAR,
                   PCPEDC.DTWMS,
                   PCPEDC.NUMVIASMAPASEP
            INTO P_REGPEDIDO.NUMPED,
                 P_REGPEDIDO.CODUSUR,
                 P_REGPEDIDO.CODCLI,
                 P_REGPEDIDO.DATA,
                 P_REGPEDIDO.CODPLPAG,
                 P_REGPEDIDO.CODCOB,
                 P_REGPEDIDO.CONDVENDA,
                 P_REGPEDIDO.POSICAO,
                 P_REGPEDIDO.NUMCAR,
                 VDDTWMS,
                 VNNUMVIASMAPASEP
            FROM PCPEDC
            WHERE NUMPEDCLI = P_REGPEDIDO.NUMPEDORIG
              AND CODCLI = P_REGPEDIDO.CODCLI
              AND NVL(PCPEDC.BRINDE, 'N') <> 'S'
              AND PCPEDC.NUMPEDORIGEM IS NULL;
         ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'R' THEN
            SELECT PCPEDC.NUMPED,
                   PCPEDC.CODUSUR,
                   PCPEDC.CODCLI,
                   PCPEDC.DATA,
                   PCPEDC.CODPLPAG,
                   PCPEDC.CODCOB,
                   PCPEDC.CONDVENDA,
                   PCPEDC.POSICAO,
                   PCPEDC.NUMCAR,
                   PCPEDC.DTWMS,
                   PCPEDC.NUMVIASMAPASEP
            INTO P_REGPEDIDO.NUMPED,
                 P_REGPEDIDO.CODUSUR,
                 P_REGPEDIDO.CODCLI,
                 P_REGPEDIDO.DATA,
                 P_REGPEDIDO.CODPLPAG,
                 P_REGPEDIDO.CODCOB,
                 P_REGPEDIDO.CONDVENDA,
                 P_REGPEDIDO.POSICAO,
                 P_REGPEDIDO.NUMCAR,
                 VDDTWMS,
                 VNNUMVIASMAPASEP
            FROM PCPEDC
            WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDORIG
              AND CODUSUR = P_REGPEDIDO.CODUSUR
              AND NVL(PCPEDC.BRINDE, 'N') <> 'S'
              AND PCPEDC.NUMPEDORIGEM IS NULL;
         ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
            SELECT PCPEDC.NUMPED,
                   PCPEDC.CODUSUR,
                   PCPEDC.CODCLI,
                   PCPEDC.DATA,
                   PCPEDC.CODPLPAG,
                   PCPEDC.CODCOB,
                   PCPEDC.CONDVENDA,
                   PCPEDC.POSICAO,
                   PCPEDC.NUMCAR,
                   PCPEDC.DTWMS,
                   PCPEDC.NUMVIASMAPASEP
            INTO P_REGPEDIDO.NUMPED,
                 P_REGPEDIDO.CODUSUR,
                 P_REGPEDIDO.CODCLI,
                 P_REGPEDIDO.DATA,
                 P_REGPEDIDO.CODPLPAG,
                 P_REGPEDIDO.CODCOB,
                 P_REGPEDIDO.CONDVENDA,
                 P_REGPEDIDO.POSICAO,
                 P_REGPEDIDO.NUMCAR,
                 VDDTWMS,
                 VNNUMVIASMAPASEP
            FROM PCPEDC
            WHERE NUMPEDWEB = P_REGPEDIDO.NUMPEDORIG
              AND CODCLI = P_REGPEDIDO.CODCLI
              AND INTEGRADORA = P_REGPEDIDO.INTEGRADORA
              AND NVL(PCPEDC.BRINDE, 'N') <> 'S'
              AND PCPEDC.NUMPEDORIGEM IS NULL;
         END IF;

         IF P_REGPEDIDO.POSICAO NOT IN ('L', 'B', 'P') THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PEDIDO ORIGINAL NAO PODE SER ALTERADO (POSICAO = ' ||
                          P_REGPEDIDO.POSICAO || ');';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.NUMPEDORIG  := 0;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 1;
         ELSE
           IF GREGPCCONSUM.MONTANDO = 'S' AND P_REGPEDIDO.POSICAO = 'L' THEN
              IF VSMENSAGEM IS NOT NULL THEN
                 VSCHAR := '#';
              ELSE
                 VSCHAR := NULL;
              END IF;
            
              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'SISTEMA WINTHOR ESTA ALOCADO PARA MONTAGEM DE CARGA; Pedido ' ||
                            P_REGPEDIDO.NUMPEDORIG || ' NAO PODEM SER ALTERADO;';
              P_REGPEDIDO.NUMPEDORIG  := 0;
              P_REGPEDIDO.VALIDO      := FALSE;
              P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 2;
           END IF;

           IF TRIM(VDDTWMS) IS NOT NULL OR NVL(VNNUMVIASMAPASEP, 0) > 0 THEN
              IF VSMENSAGEM IS NOT NULL THEN
                 VSCHAR := '#';
              ELSE
                 VSCHAR := NULL;
              END IF;

              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Pedido em processo de WMS' ||
                            P_REGPEDIDO.NUMPEDORIG || ' NAO PODEM SER ALTERADO;';
              P_REGPEDIDO.NUMPEDORIG := 0;
              P_REGPEDIDO.VALIDO     := FALSE;
           END IF;
         END IF;
      ELSE
         VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PEDIDO ORIGINAL NAO EXISTENTE;PEDIDO ' ||
                       P_REGPEDIDO.NUMPEDORIG || ' NAO PODEM SER ALTERADO;';

         P_REGPEDIDO.NUMPEDORIG  := 0;
         P_REGPEDIDO.VALIDO      := FALSE;
         P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 3;
      END IF;
   ELSE
      P_REGPEDIDO.NUMPEDORIG := 0;
   END IF;

   --Validar origemped
   IF P_REGPEDIDO.ORIGEMPED NOT IN ('F', 'C', 'R', 'W', 'B') THEN
      IF VSMENSAGEM IS NOT NULL THEN
         VSCHAR := '#';
      ELSE
         VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'O campo "origemped" possui valor "' ||
                    P_REGPEDIDO.ORIGEMPED || '" inválido;';
      P_REGPEDIDO.VALIDO      := FALSE;
      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 4;
   END IF;
   -- verifica tipo do pedido
   -- normal
   IF P_REGPEDIDO.ORIGEMPED IN ('F', 'C', 'R', 'W', 'B') THEN
      P_REGPEDIDO.POSICAO := 'P';
   END IF;

   IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) <> 0 THEN
      IF P_REGPEDIDO.CONDVENDA = 1 THEN
         P_REGPEDIDO.PERCVENDA := 100;
         --> bonificacao
      ELSIF P_REGPEDIDO.CONDVENDA = 5 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSIF P_REGPEDIDO.CONDVENDA = 7 THEN
         P_REGPEDIDO.PERCVENDA := 100;
         P_REGPEDIDO.POSICAO   := 'L';
      ELSIF P_REGPEDIDO.CONDVENDA = 10 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSIF P_REGPEDIDO.CONDVENDA = 13 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSIF P_REGPEDIDO.CONDVENDA = 20 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSE
         P_REGPEDIDO.CONDVENDA := 1;
         P_REGPEDIDO.PERCVENDA := 100;
      END IF;
   ELSE
      IF P_REGPEDIDO.CONDVENDA = 1 THEN
         P_REGPEDIDO.PERCVENDA := 100;
         --> bonificacao
      ELSIF P_REGPEDIDO.CONDVENDA = 5 THEN
         IF GREGPCCONSUM.BLOQUEARPEDBONIFIC = 'S' THEN
            P_REGPEDIDO.POSICAO := 'B';
         END IF;

         P_REGPEDIDO.PERCVENDA     := 100;
         P_REGPEDIDO.CODMOTIVO     := 7;
         P_REGPEDIDO.MOTIVOPOSICAO := 'Pedido Bonificado';
         P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Pedido Bonificado';

         IF P_REGPEDIDO.POSICAO = 'B' THEN
            PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
         END IF;
      ELSIF P_REGPEDIDO.CONDVENDA = 7 THEN
         P_REGPEDIDO.PERCVENDA := 100;
         P_REGPEDIDO.POSICAO   := 'L';
      ELSIF P_REGPEDIDO.CONDVENDA = 10 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSIF P_REGPEDIDO.CONDVENDA = 11 THEN
         IF GREGPCCONSUM.BLOQUEARPEDBONIFIC = 'S' THEN
            P_REGPEDIDO.POSICAO := 'B';
         END IF;

         P_REGPEDIDO.PERCVENDA     := 100;
         P_REGPEDIDO.CODMOTIVO     := 7;
         P_REGPEDIDO.MOTIVOPOSICAO := 'Pedido Bonificado';
         P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Pedido Bonificado';

         IF P_REGPEDIDO.POSICAO = 'B' THEN
            PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
         END IF;
      ELSIF P_REGPEDIDO.CONDVENDA = 13 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSIF P_REGPEDIDO.CONDVENDA = 20 THEN
         P_REGPEDIDO.PERCVENDA := 100;
      ELSE
         P_REGPEDIDO.CONDVENDA := 1;
         P_REGPEDIDO.PERCVENDA := 100;
      END IF;
   END IF;

   SELECT COUNT(*)
   INTO VICONTADOR
   FROM PCFILIAL
   WHERE CODIGO = P_REGPEDIDO.CODFILIAL;

   IF VICONTADOR = 0 THEN
      IF VSMENSAGEM IS NOT NULL THEN
         VSCHAR := '#';
      ELSE
         VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Filial nao Cadastrada.';
      P_REGPEDIDO.VALIDO      := FALSE;
      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 5;
   ELSE
      PROC_PARAMETROS(P_REGPEDIDO, P_REGFILIAL);
   END IF;

   BEGIN
      VBHORAIMPORTACAOVALIDA := FUNC_HORADIGITACAOPEDIDO(P_REGFILIAL, VSMENSAGEMHORA);
   EXCEPTION WHEN OTHERS THEN
      VBHORAIMPORTACAOVALIDA := FALSE;
      VSMENSAGEMHORA := 'Erro ao validar hora digitacao do pedido :' || SQLCODE || '-' || SQLERRM;
   END;
   
   BEGIN
      SELECT NVL(PCCONTROI.ACESSO, 'N')
      INTO VSACESSO
      FROM PCCONTROI
      WHERE PCCONTROI.CODROTINA = 2596
        AND PCCONTROI.CODCONTROLE = 1
        AND PCCONTROI.CODUSUARIO = 8888;
   EXCEPTION WHEN OTHERS THEN
      VSACESSO := 'N';
   END;
 
   IF VBHORAIMPORTACAOVALIDA = FALSE AND VSACESSO = 'N' THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM         := VSMENSAGEM || VSCHAR || VSMENSAGEMHORA;
      P_REGPEDIDO.VALIDO := FALSE;
   ELSE
      IF P_REGFILIAL.BROKER = 'S' THEN
        P_REGPEDIDO.ORIGEMPED := 'K';

        IF NVL(GREGPCCONSUM.FATURAFILIALBROKER, 'N') = 'S' THEN
          P_REGPEDIDO.CONDVENDA := 1;
          P_REGPEDIDO.PERCVENDA := 100;
        ELSE
          P_REGPEDIDO.CONDVENDA := 4;
          P_REGPEDIDO.PERCVENDA := 100;
        END IF;
      END IF;

      IF P_REGPEDIDO.AGRUPAMENTO IS NOT NULL THEN
        IF P_REGPEDIDO.CONDVENDA <> 1 AND P_REGPEDIDO.AGRUPAMENTO <> 'N' THEN
          P_REGPEDIDO.AGRUPAMENTO := NULL;

          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;
          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'INFORMACAO DE AGRUPAMENTO VALIDADA APENAS PARA TV1' || ';';

          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 133;
        ELSIF P_REGPEDIDO.ORIGEMPED <> 'F' THEN
          P_REGPEDIDO.AGRUPAMENTO := NULL;

          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;
          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'INFORMACAO DE AGRUPAMENTO VALIDADA APENAS PARA ORIGEMPED F' || ';';
          P_REGPEDIDO.CODRETORNOS := 134;
        ELSE
          IF P_REGPEDIDO.AGRUPAMENTO NOT IN ('S', 'N') THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;
            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'INFORMACAO DE AGRUPAMENTO INVALIDA : ' ||
                          P_REGPEDIDO.AGRUPAMENTO || 'ALTERADA PARA N' || ';';
            P_REGPEDIDO.AGRUPAMENTO := 'N';
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 135;
          END IF;
        END IF;
      END IF;
      --verifica se tem alienacao para broker Melitta
      IF P_REGFILIAL.BROKER = 'S' AND P_REGFILIAL.TIPOBROKER = 'MEL' THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCCLIENTFORNEC P
         WHERE P.CODCLI = P_REGPEDIDO.CODCLI;

        IF VICONTADOR = 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;
          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'NAO FOI ENCONTRADA ALIENACAO PARA ESTE CLIENTE;';
          P_REGPEDIDO.VALIDO      := FALSE;
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 152;
        END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 7 AND P_REGPEDIDO.CODCLITV8 IS NOT NULL THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCCLIENT
         WHERE CODCLI = P_REGPEDIDO.CODCLITV8
           AND DTEXCLUSAO IS NULL;

        IF VICONTADOR = 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;
          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'CLIENTE TV8 NAO CADASTRADO OU EXCLUIDO;';
          P_REGPEDIDO.VALIDO := FALSE;
        END IF;
      END IF;

      IF P_REGPEDIDO.CODENDENT IS NOT NULL AND P_REGPEDIDO.CODENDENT <> 0 THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCENTREGA P
         WHERE P.CODENDENT = P_REGPEDIDO.CODENDENT;

        IF VICONTADOR = 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;
          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'CODIGO DE ENDERECO DE ENTREGA INVALIDO : ' ||
                        P_REGPEDIDO.CODENDENT || ';';
          P_REGPEDIDO.CODENDENT := NULL;
        END IF;
      END IF;
      -- verifica se cliente esta cadastrado
      SELECT COUNT(*)
        INTO VICONTADOR
        FROM PCCLIENT, PCPRACA
       WHERE PCCLIENT.CODPRACA = PCPRACA.CODPRACA
         AND CODCLI = P_REGPEDIDO.CODCLI;

      IF VICONTADOR = 0 THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente nao cadastrado;';
        P_REGPEDIDO.VALIDO      := FALSE;
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 6;
      ELSE
        SELECT NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO,
               NVL(PCCLIENT.CALCULAST, 'S'),
               PCCLIENT.CLIENTE,
               PCCLIENT.CODCLI,
               NVL(PCCLIENT.CODCLIPRINC, PCCLIENT.CODCLI),
               PCCLIENT.CODCOB,
               PCCLIENT.CODFILIALNF,
               PCCLIENT.CODPLPAG,
               PCCLIENT.CODPRACA,
               PCCLIENT.CONDVENDA1,
               PCCLIENT.CONDVENDA2,
               PCCLIENT.CONDVENDA3,
               PCCLIENT.CONDVENDA4,
               PCCLIENT.CONDVENDA5,
               PCCLIENT.CONDVENDA6,
               PCCLIENT.CONDVENDA10,
               PCCLIENT.CONDVENDA11,
               PCCLIENT.CONDVENDA12,
               NVL(PCCLIENT.DESCPRODUTO, 'N') DESCPRODUTO,
               PCCLIENT.ESTENT,
               UPPER(PCCLIENT.IEENT) IEENT,
               NVL(PCCLIENT.LIMCRED, 0) LIMCRED,
               NVL(PCPLPAG.NUMDIAS, 0) NUMDIAS,
               PCCLIENT.PERCOMCLI,
               NVL(PCCLIENT.PERDESC, 0) PERDESC,
               NVL(PCCLIENT.PRAZOADICIONAL, 0) PRAZOADICIONAL,
               PCCLIENT.TIPOFJ,
               PCPRACA.NUMREGIAO,
               PCCLIENT.CODATV1,
               VALIDAMAXVENDAPF,
               CONSUMIDORFINAL,
               NVL(PCCLIENT.CLIENTEFONTEST, 'N'),
               NVL(PCCLIENT.ISENTOICMS, 'N'),
               NVL(PCCLIENT.UTILIZAIESIMPLIFICADA, 'N'),
               TIPOEMPRESA,
               NVL(PCCLIENT.CONTRIBUINTE, 'S'),
               PCCLIENT.CLASSEVENDA,
               NVL(PCCLIENT.ISENTOIPI, 'N'),
               PCCLIENT.SULFRAMA,
               NVL(PCCLIENT.TIPODESCISENCAO, 'N'),
               NVL(PERDESCISENTOICMS, 0),
               NVL(IVAFONTE, 0),
               NVL(PCCLIENT.USAIVAFONTEDIFERENCIADO, 'N'),
               NVL(PCCLIENT.PERBASEVEND, 50),
               NVL(PCCLIENT.ORGAOPUB, 'N'),
               NVL(PCCLIENT.ORGAOPUBFEDERAL, 'N'),
               NVL(PCCLIENT.CLIENTEMONITORADO, 'N'),
               NVL(PCCLIENT.ATUALIZASALDOCCDESCFIN, 'N'),
               NVL(PCCLIENT.ISENTODIFALIQUOTAS, 'N'),
               NVL(PCCLIENT.TIPODOCUMENTO, 'N'),
               NVL(PCCLIENT.FRETEDESPACHO, 'N') FRETEDESPACHO,
			      NVL(PCCLIENT.SIMPLESNACIONAL, 'N'),
               PCCLIENT.BLOQUEIOSEFAZ,
               NVL(PCCLIENT.TIPOCUSTOTRANSF, 'R'),
               NVL(PCCLIENT.PERACRESTRANSF, 0),
               PCCLIENT.REGISTROIBAMA,
               PCCLIENT.DTVALIDADEIBAMA,
               NVL(PCCLIENT.ISENCAOSUFRAMA, 'T'),
               PCCLIENT.TURNOENTREGA,
               PCCLIENT.VALIDARMULTIPLOVENDA,
               NVL(PCCLIENT.USADESCONTOICMS, 'N'),
               PCCLIENT.ACEITAVENDAFRACAO,
               PCCLIENT.USADEBCREDRCA,
               NVL(PCCLIENT.UTILIZACALCULOSTMT, 'N'),
               NVL(PCCNAE.MARGEMMVA, 0),
               NVL(PCCNAE.PERCARGATRIBMEDIA, 0)
          INTO P_REGCLIENTE
          FROM PCCLIENT, PCPRACA, PCPLPAG, PCCNAE
         WHERE PCCLIENT.CODPRACA = PCPRACA.CODPRACA
           AND PCCLIENT.CODPLPAG = PCPLPAG.CODPLPAG(+)
           AND PCCLIENT.CODCLI = P_REGPEDIDO.CODCLI
           AND PCCLIENT.CODCNAE = PCCNAE.CODCNAE(+);
      END IF;

      P_REGPEDIDO.FRETEDESPACHO := NVL(P_REGPEDIDO.FRETEDESPACHO, P_REGCLIENTE.FRETEDESPACHO);

      IF P_REGPEDIDO.TURNOENTREGA IS NULL THEN
        P_REGPEDIDO.TURNOENTREGA := P_REGCLIENTE.TURNOENTREGA;
      ELSE
        IF P_REGPEDIDO.TURNOENTREGA NOT IN ('MT', 'MN', 'TN', 'M', 'N', 'T') THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'TURNO DE ENTREGA INVALIDO. SERA GRAVADO O TURNO CADASTRADO PARA O CLIENTE;';
          P_REGPEDIDO.TURNOENTREGA := P_REGCLIENTE.TURNOENTREGA;
        END IF;
      END IF;

      IF GREGPCCONSUM.USASALDOCONTACORRENTEDESCFIN = 'S' AND
         NVL(P_REGCLIENTE.ATUALIZASALDOCCDESCFIN, 'N') = 'N' THEN
        P_REGPEDIDO.USASALDOCONTACORRENTEDESCFIN := 'S';
      ELSE
        P_REGPEDIDO.USASALDOCONTACORRENTEDESCFIN := 'N';
      END IF;

      IF P_REGPEDIDO.CODFILIALNF IS NULL THEN
        IF P_REGCLIENTE.CODFILIALNF IS NULL THEN
          VSCODFILIALNF := P_REGPEDIDO.CODFILIAL;
        ELSE
          VSCODFILIALNF := P_REGCLIENTE.CODFILIALNF;
        END IF;
      ELSE
        VSCODFILIALNF := P_REGPEDIDO.CODFILIALNF;
      END IF;

      SELECT COUNT(*)
        INTO VICONTADOR
        FROM PCTABPRCLI
       WHERE CODCLI = P_REGPEDIDO.CODCLI
         AND CODFILIALNF = VSCODFILIALNF;

      IF VICONTADOR > 0 THEN
        SELECT PCTABPRCLI.NUMREGIAO
          INTO P_REGCLIENTE.NUMREGIAO
          FROM PCTABPRCLI
         WHERE CODCLI = P_REGPEDIDO.CODCLI
           AND CODFILIALNF = VSCODFILIALNF
           AND ROWNUM = 1;
      END IF;

      IF P_REGPEDIDO.ORIGEMPED = 'R' AND
         P_REGFILIAL.NUMREGIAOBALCAOINTER IS NOT NULL THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCREGIAO
         WHERE NUMREGIAO = P_REGFILIAL.NUMREGIAOBALCAOINTER;

        IF VICONTADOR > 0 THEN
          P_REGCLIENTE.NUMREGIAO := P_REGFILIAL.NUMREGIAOBALCAOINTER;
        END IF;
      END IF;

      IF P_REGFILIAL.BROKER = 'S' AND
         NVL(P_REGPEDIDO.NUMREGIAOBROKER, 0) > 0 THEN

        P_REGPEDIDO.NUMTABELA := '';

        BEGIN
          SELECT PCREGIAO.NUMTABELA
            INTO P_REGPEDIDO.NUMTABELA
            FROM PCREGIAO
           WHERE NUMREGIAO = P_REGPEDIDO.NUMREGIAOBROKER;
        EXCEPTION
          WHEN OTHERS THEN
            P_REGPEDIDO.NUMTABELA := '';
        END;

        P_REGCLIENTE.NUMREGIAO := P_REGPEDIDO.NUMREGIAOBROKER;
      END IF;
      -- verifica se o pedido nao foi importado por e-commere
      -- e se o pedido nao esta pago
      IF NVL(P_REGFILIAL.IMPORTAPEDIDOECOMMERCEPAGO, 'N') = 'N' AND
         NVL(P_REGPEDIDO.PEDIDOPAGOECOMMERCE, 'N') = 'N' THEN
        -- Caso positivo, verifica a situacao do cliente
        -- verifica se cliente esta bloqueado
        IF P_REGCLIENTE.BLOQUEIO = 'S' THEN
          IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
            IF NVL(GREGPCCONSUM.ACEITAVENDABLOQ, 'N') = 'S' THEN
              IF P_REGPLPAG.NUMDIAS <= 1 THEN
                IF P_REGFILIAL.ACEITAVENDAAVISTACLIBLOQ = 'N' THEN
                  P_REGPEDIDO.POSICAO       := 'B';
                  P_REGPEDIDO.MOTIVOPOSICAO := 'Cliente Bloq e parametrizado para bloquear com venda a vista';

                  IF P_REGPEDIDO.POSICAO = 'B' THEN
                    PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                  END IF;
                END IF;
              ELSE
                P_REGPEDIDO.POSICAO       := 'B';
                P_REGPEDIDO.CODMOTIVO     := 2;
                P_REGPEDIDO.MOTIVOPOSICAO := 'Cliente Bloqueado';
                P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Cliente Bloqueado';

                IF P_REGPEDIDO.POSICAO = 'B' THEN
                   PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                END IF;
              END IF;
            ELSE
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;
          ELSE
            IF P_REGPEDIDO.POSICAO <> 'B' THEN
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;
          END IF;

          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente bloqueado;';
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 7;
        END IF;
      END IF;

      IF P_REGPEDIDO.FRETEDESPACHO IS NOT NULL AND
         (P_REGPEDIDO.FRETEDESPACHO <> P_REGCLIENTE.FRETEDESPACHO) THEN
        IF GREGPCCONSUM.ACEITAVENDABLOQ = 'S' THEN
          P_REGPEDIDO.POSICAO       := 'B';
          P_REGPEDIDO.MOTIVOPOSICAO := 'Fretedespacho diferente do cliente';
          P_REGPEDIDO.CODMOTIVO     := 14;

          IF P_REGPEDIDO.POSICAO = 'B' THEN
            PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        ELSE
          P_REGPEDIDO.VALIDO := FALSE;
        END IF;

        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;
        
        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'FRETEDESPACHO DO PEDIDO ESTA DIFERENTE DO CADASTRADO PARA O CLIENTE;';
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 5 THEN
        IF P_REGFILIAL.OBRIGATORIOVINCULARTV5COMTV1 = 'S' THEN
          IF TRIM(P_REGPEDIDO.NUMPEDTV1) IS NULL THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;
            VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                          'COM PARAMETRO OBRIGATORIOVINCULARTV5COMTV1 MARCADO É OBRIGATORIO O ENVIO DO NUMPEDTV1 PARA PEDIDO BONIFICADO;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 136;
          ELSE
            SELECT COUNT(*)
              INTO VICONTADOR
              FROM PCPEDC
             WHERE NUMPED = P_REGPEDIDO.NUMPEDTV1
               AND CONDVENDA = 1
               AND CODCLI = P_REGPEDIDO.CODCLI
               AND CONTAORDEM IS NOT NULL;

            IF VICONTADOR = 0 THEN
              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;
              VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                            'COM PARAMETRO OBRIGATORIOVINCULARTV5COMTV1 MARCADO É OBRIGATORIO O ENVIO DO NUMPEDTV1 VALIDO;';
              P_REGPEDIDO.VALIDO      := FALSE;
              P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 137;
            END IF;
          END IF;
        END IF;
      END IF;

      IF NVL(P_REGPEDIDO.CODENDENTCLI, 0) > 0 THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCCLIENTENDENT P
         WHERE P.CODENDENTCLI = P_REGPEDIDO.CODENDENTCLI
           AND P.CODCLI = P_REGPEDIDO.CODCLI;

        IF VICONTADOR = 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                        'CODIGO DE ENDERECO DE ENTREGA NAO LOCALIZADO PARA ESTE CLIENTE;';
          P_REGPEDIDO.VALIDO      := FALSE;
          P_REGPEDIDO.CODRETORNOS := 157;
        END IF;
      END IF;

      IF GREGPCCONSUM.VERIFICARCLIENTESREDE = 'S' THEN
        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCCLIENT
         WHERE CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC
           AND BLOQUEIO = 'S'
           AND CODCLI <> P_REGCLIENTE.CODCLI;

        IF VICONTADOR >= 1 THEN
          IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
            P_REGPEDIDO.POSICAO       := 'B';
            P_REGPEDIDO.MOTIVOPOSICAO := 'Cliente da rede bloqueado';
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Cliente da rede bloqueado';

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          ELSE
            IF P_REGPEDIDO.POSICAO <> 'B' THEN
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;
          END IF;

          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente da rede bloqueado;';
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 156;
        END IF;
      END IF;
      -- verifica se cliente esta bloqueado no sefaz
      IF P_REGCLIENTE.BLOQUEIOSEFAZ = 'S' AND
         P_REGFILIAL.VERIFICABLOQUEIOSEFAZ = 'N' THEN
        IF P_REGFILIAL.VALIDARCLISEFAZ IN ('D', 'DE') THEN
          P_REGPEDIDO.VALIDO := FALSE;
        END IF;

        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente bloqueado - Sefaz;';
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 67;
      END IF;
      --Cliente Recebedor
      IF P_REGFILIAL.INFORMARECEBEDORVENDA = 'S' AND
         P_REGFILIAL.UTILIZANFE = 'S' THEN
        IF P_REGPEDIDO.CODCLIRECEBEDOR IS NOT NULL THEN
          SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCCLIENT
           WHERE CODCLI = P_REGPEDIDO.CODCLIRECEBEDOR;

          IF VICONTADOR = 0 THEN
            P_REGPEDIDO.VALIDO := FALSE;

            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente recebedor informado não foi encontrado;';
          ELSE
            SELECT CODCLIPRINC
              INTO VNCODCLIPRINC
              FROM PCCLIENT
             WHERE CODCLI = P_REGPEDIDO.CODCLIRECEBEDOR;

            IF VNCODCLIPRINC <> P_REGPEDIDO.CODCLI THEN
              P_REGPEDIDO.VALIDO := FALSE;

              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;

              VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                            'Cliente recebedor informado não pertence a rede do cliente do pedido;';
              P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 160;
            END IF;
          END IF;
        END IF;
      END IF;
      --Cliente Autorizador
      IF P_REGFILIAL.USACODCLIVENDA = 'S' THEN
         IF P_REGPEDIDO.CODCLINF IS NOT NULL THEN
            --verifica se cliente autorizador existe
            SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCCLIENT
            WHERE CODCLI = P_REGPEDIDO.CODCLINF;

            IF VICONTADOR = 0 THEN
               IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
               ELSE
                  VSCHAR := NULL;
               END IF;

               VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente autorizador não existe;';
               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 161;
               P_REGPEDIDO.VALIDO      := FALSE;
            ELSE
               SELECT COUNT(*)
               INTO VICONTADOR
               FROM PCAUTORNF P
               WHERE P.CODCLI = P_REGPEDIDO.CODCLI
                 AND P.CODCLINF = P_REGPEDIDO.CODCLINF;

               IF VICONTADOR = 0 THEN
                  IF VSMENSAGEM IS NOT NULL THEN
                     VSCHAR := '#';
                  ELSE
                     VSCHAR := NULL;
                  END IF;

                  VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente não autorizado ;';
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 162;
                  P_REGPEDIDO.VALIDO      := FALSE;
               ELSE
                  SELECT NUMREGIAO
                  INTO VNNUMREGIAOCLINF
                  FROM PCCLIENT, PCPRACA
                  WHERE CODCLI = P_REGPEDIDO.CODCLINF
                    AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA;

                  IF VNNUMREGIAOCLINF <> P_REGCLIENTE.NUMREGIAO THEN
                     IF VSMENSAGEM IS NOT NULL THEN
                        VSCHAR := '#';
                     ELSE
                        VSCHAR := NULL;
                     END IF;
  
                     VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                                   'Cliente autorizador precisar estar na mesma regiao do cliente do pedido;';
                      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 163;
                      P_REGPEDIDO.VALIDO      := FALSE;
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;

      -- verifica se o rca esta cadastrado
      SELECT COUNT(*)
      INTO VICONTADOR
      FROM PCUSUARI
      WHERE CODUSUR = P_REGPEDIDO.CODUSUR;

      IF VICONTADOR = 0 THEN
         IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
         ELSE
            VSCHAR := NULL;
         END IF;

         VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Rca nao cadastrado;';
         P_REGPEDIDO.VALIDO      := FALSE;
         P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 8;
      ELSE
         SELECT NVL(PCUSUARI.BLOQUEIO, 'N') BLOQUEIO,
                NVL(PCSUPERV.COD_CADRCA, 0) COD_CADRCA,
                PCUSUARI.CODDISTRIB,
                PCUSUARI.CODSUPERVISOR,
                PCUSUARI.CODUSUR,
                PCUSUARI.NOME,
                PCUSUARI.PERCENT2,
                PCUSUARI.PERCENT,
                PCUSUARI.PROXNUMPED,
                NVL(PCUSUARI.TIPOVEND, 'R') TIPOVEND,
                PCUSUARI.PERMAXVENDA,
                PCUSUARI.USADEBCREDRCA,
                NVL(PCUSUARI.VLVENDAMINPED, 0),
                PCUSUARI.PERCACRESFV
         INTO P_REGRCA
         FROM PCUSUARI, PCSUPERV
         WHERE PCUSUARI.CODUSUR = P_REGPEDIDO.CODUSUR
           AND PCUSUARI.CODUSUR = PCSUPERV.COD_CADRCA(+);

         IF NVL(P_REGRCA.USADEBCREDRCA,'N') = 'N' OR NVL(P_REGCLIENTE.USADEBCREDRCA,'N') = 'N' THEN
            P_REGPEDIDO.USADEBCREDRCA := 'N';
		 ELSE
  		    P_REGPEDIDO.USADEBCREDRCA := 'S';
         END IF;

         IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
            BEGIN
               VPROXNUMPED := IMPORTAR_PEDIDO_PROXNUMPED(P_REGPEDIDO.CODUSUR);
               P_REGPEDIDO.NUMPED := VPROXNUMPED;
            END;
         END IF;
      END IF;

      -- verifica se rca esta bloqueado
      IF P_REGRCA.BLOQUEIO = 'S' THEN
         IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
            IF NVL(GREGPCCONSUM.ACEITAVENDABLOQ, 'N') = 'S' THEN
               P_REGPEDIDO.POSICAO := 'B';
               P_REGPEDIDO.MOTIVOPOSICAO := 'RCA bloqueado';
               P_REGPEDIDO.CODMOTIVO     := 1;
               P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Rca bloqueado';

               IF P_REGPEDIDO.POSICAO = 'B' THEN
                  PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
               END IF;
            ELSE
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;
         ELSE
            IF P_REGPEDIDO.POSICAO <> 'B' THEN
               P_REGPEDIDO.VALIDO := FALSE;
            END IF;
         END IF;

         IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
         ELSE
            VSCHAR := NULL;
         END IF;

         VSMENSAGEM              := VSMENSAGEM || VSCHAR || 'Rca bloqueado;';
         P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 9;
      END IF;

      -- verifica se pedido ja existe (1)
      IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
         IF P_REGPEDIDO.TIPOINTEGRACAO = 'C' THEN
            SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCPEDC
            WHERE NUMPEDCLI = P_REGPEDIDO.NUMPEDCLI
              AND CODCLI = P_REGPEDIDO.CODCLI;
         ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'R' THEN
            SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCPEDC
            WHERE NUMPEDRCA = P_REGPEDIDO.NUMPEDRCA
              AND CODUSUR = P_REGPEDIDO.CODUSUR;
         ELSIF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
            SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCPEDC
            WHERE NUMPEDWEB = P_REGPEDIDO.NUMPEDWEB
              AND CODCLI = P_REGPEDIDO.CODCLI
              AND INTEGRADORA = P_REGPEDIDO.INTEGRADORA;
         ELSE
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Integracao desconhecida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            VICONTADOR              := 0;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 11;
         END IF;

         IF VICONTADOR > 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Pedido da integracao ja existente;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 12;
         END IF;

         -- verifica se pedido ja existe (2)
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPEDC
         WHERE NUMPED = P_REGPEDIDO.NUMPED;

         IF VICONTADOR > 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Pedido ja existente;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 13;
         END IF;
      END IF;

      -- verificar se a regiao do cliente esta cadastrada
      SELECT COUNT(*)
      INTO VICONTADOR
      FROM PCREGIAO
      WHERE PCREGIAO.NUMREGIAO = P_REGCLIENTE.NUMREGIAO
        AND PCREGIAO.STATUS = 'A';

      IF VICONTADOR = 0 THEN
         IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
         ELSE
            VSCHAR := NULL;
         END IF;

         VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Regiao ' || P_REGCLIENTE.NUMREGIAO || ' nao cadastrada;';
         P_REGPEDIDO.VALIDO      := FALSE;
         P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 14;
      ELSE
         SELECT PCREGIAO.NUMREGIAO,
                PCREGIAO.PERFRETE,
                NVL(PCREGIAO.PERFRETETERCEIROS, 0),
                NVL(PCREGIAO.PERFRETEESPECIAL, 0),
                CODESTABELECIMENTO
         INTO P_REGREGIAO
         FROM PCREGIAO
         WHERE PCREGIAO.NUMREGIAO = P_REGCLIENTE.NUMREGIAO
           AND PCREGIAO.STATUS = 'A';
      END IF;

      VBEXISTEPLPAGCLI := FALSE;
      --Plano de Pagamento Restritivo do cliente
      SELECT COUNT(*)
        INTO VICONTADOR
        FROM PCPLPAGCLI
       WHERE CODCLI = P_REGPEDIDO.CODCLI;

      IF VICONTADOR <> 0 THEN
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPLPAGCLI
         WHERE CODCLI = P_REGPEDIDO.CODCLI
           AND CODPLPAG = P_REGPEDIDO.CODPLPAG;

         IF VICONTADOR = 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de Pagamento ' ||
                          P_REGPEDIDO.CODPLPAG || ' nao cadastrado para este cliente;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 15;
         ELSE
            VBEXISTEPLPAGCLI := TRUE;

            SELECT PRAZO1,
                   PRAZO2,
                   PRAZO3,
                   PRAZO4,
                   PRAZO5,
                   PRAZO6,
                   PRAZO7,
                   PRAZO8,
                   PRAZO9,
                   PRAZO10,
                   PRAZO11,
                   PRAZO12
            INTO VNPRAZO1,
                 VNPRAZO2,
                 VNPRAZO3,
                 VNPRAZO4,
                 VNPRAZO5,
                 VNPRAZO6,
                 VNPRAZO7,
                 VNPRAZO8,
                 VNPRAZO9,
                 VNPRAZO10,
                 VNPRAZO11,
                 VNPRAZO12
            FROM PCPLPAG
            WHERE CODPLPAG = P_REGCLIENTE.CODPLPAG;
         END IF;
      END IF;

      IF P_REGPEDIDO.VALIDO = TRUE THEN
         -- plano de pagamento do pedido
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPLPAG
         WHERE CODPLPAG = P_REGPEDIDO.CODPLPAG;

         IF VICONTADOR = 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de Pagamento ' || P_REGPEDIDO.CODPLPAG ||
                          ' nao cadastrado. Será utilizado o plano do cadastro do cliente';

            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 16;

            IF P_REGPEDIDO.CODPLPAG <> 99 THEN
               P_REGPEDIDO.CODPLPAG := P_REGCLIENTE.CODPLPAG;
               VNCODPLPAG           := P_REGCLIENTE.CODPLPAG;
            ELSE
               VNCODPLPAG := P_REGCLIENTE.CODPLPAG;
            END IF;
         ELSE
            VNCODPLPAG := P_REGPEDIDO.CODPLPAG;
         END IF;

         SELECT CODPLPAG,
                NUMDIAS,
                NVL(NUMITENSMINIMO,0),
                NVL(NUMPR,1) NUMPR,
                OBS,
                NVL(PERTXFIM,0),
                PRAZO1,
                PRAZO2,
                PRAZO3,
                PRAZO4,
                PRAZO5,
                PRAZO6,
                PRAZO7,
                PRAZO8,
                PRAZO9,
                PRAZO10,
                PRAZO11,
                PRAZO12,
                NVL(TIPOPRAZO,'N'),
                TIPOVENDA,
                NVL(VLMINPEDIDO,0),
                NVL(PCPLPAG.VENDABK,'N'),
                NVL(TIPORESTRICAO,'NR'),
                CODRESTRICAO,
                TRIM(CODFILIAL),
                NVL(PCPLPAG.USAMULTIFILIAL,'N'),
                PCPLPAG.FORMAPARCELAMENTO,
                NVL(PCPLPAG.DIASMINPARCELA,0),
                NVL(PCPLPAG.DIASMAXPARCELA,0),
                NVL(PCPLPAG.VLMINPARCELA,0),
                PCPLPAG.NUMPARCELAS,
                PCPLPAG.TIPOENTRADA,
                NVL(PCPLPAG.MARGEMMIN,0),
                NVL(PCPLPAG.DESCENTLIMCREDCLI,'N')
         INTO P_REGPLPAG
         FROM PCPLPAG
         WHERE CODPLPAG = VNCODPLPAG;

         IF P_REGPEDIDO.CODPLPAG = 99 THEN
            IF P_REGPEDIDO.PARCELA1 IS NOT NULL THEN
               P_REGPLPAG.PRAZO1  := P_REGPEDIDO.PARCELA1;
               P_REGPLPAG.PRAZO2  := P_REGPEDIDO.PARCELA2;
               P_REGPLPAG.PRAZO3  := P_REGPEDIDO.PARCELA3;
               P_REGPLPAG.PRAZO4  := P_REGPEDIDO.PARCELA4;
               P_REGPLPAG.PRAZO5  := P_REGPEDIDO.PARCELA5;
               P_REGPLPAG.PRAZO6  := P_REGPEDIDO.PARCELA6;
               P_REGPLPAG.PRAZO7  := P_REGPEDIDO.PARCELA7;
               P_REGPLPAG.PRAZO8  := P_REGPEDIDO.PARCELA8;
               P_REGPLPAG.PRAZO9  := P_REGPEDIDO.PARCELA9;
               P_REGPLPAG.PRAZO10 := P_REGPEDIDO.PARCELA10;
               P_REGPLPAG.PRAZO11 := P_REGPEDIDO.PARCELA11;
               P_REGPLPAG.PRAZO12 := P_REGPEDIDO.PARCELA12;
            ELSE
               P_REGPLPAG.PRAZO1  := VNPRAZO1;
               P_REGPLPAG.PRAZO2  := VNPRAZO2;
               P_REGPLPAG.PRAZO3  := VNPRAZO3;
               P_REGPLPAG.PRAZO4  := VNPRAZO4;
               P_REGPLPAG.PRAZO5  := VNPRAZO5;
               P_REGPLPAG.PRAZO6  := VNPRAZO6;
               P_REGPLPAG.PRAZO7  := VNPRAZO7;
               P_REGPLPAG.PRAZO8  := VNPRAZO8;
               P_REGPLPAG.PRAZO9  := VNPRAZO9;
               P_REGPLPAG.PRAZO10 := VNPRAZO10;
               P_REGPLPAG.PRAZO11 := VNPRAZO11;
               P_REGPLPAG.PRAZO12 := VNPRAZO12;
            END IF;
         END IF;

         IF P_REGPLPAG.TIPOENTRADA = 3 AND NVL(P_REGPEDIDO.VLENTRADA, 0) = 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de pagamento exige entrada. Valor não informado';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 154;
         END IF;

         IF P_REGPLPAG.TIPOENTRADA <> 3 AND NVL(P_REGPEDIDO.VLENTRADA, 0) > 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de pagamento não solicita entrada. Valor não será gravado';
            P_REGPEDIDO.VLENTRADA   := NULL;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 155;
         END IF;

         IF P_REGPLPAG.USAMULTIFILIAL = 'S' THEN
          SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCPLPAGFILIAL P
           WHERE P.CODPLPAG = P_REGPEDIDO.CODPLPAG
             AND P.CODFILIAL IN (P_REGPEDIDO.CODFILIAL, '99');

            IF VICONTADOR = 0 THEN
               IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
               ELSE
                  VSCHAR := NULL;
               END IF;

               VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PLANO DE PAGAMENTO ' || P_REGPEDIDO.CODPLPAG ||
                             ' NAO EXISTE PARA RELACIONAMENTO PLANO DE PAGAMENTO X FILIAL ' || P_REGPEDIDO.CODFILIAL || ';';

               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 62;

               IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                  P_REGPEDIDO.POSICAO := 'B';
                  P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) ||
                                     'Plano de Pagamento nao existe para rel. PLANO X FILIAL';
                  P_REGPEDIDO.MOTIVOPOSICAO := 'Plano Pagto nao existe para rel. Plano X Filial';

                  IF P_REGPEDIDO.POSICAO = 'B' THEN
                     PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                  END IF;
               ELSE
                  P_REGPEDIDO.VALIDO := FALSE;
               END IF;
            END IF;
         END IF;

         IF P_REGPLPAG.FORMAPARCELAMENTO = 'V' THEN
            IF P_REGPEDIDO.NUMPEDORIG = 0 THEN
               PROC_VALIDAVENCTOS(P_REGPEDIDO,
                                  P_REGPLPAG,
                                  P_REGCLIENTE,
                                  P_REGFILIAL,
                                  VSMENSAGEMPRAZOVARIAVEL);

               IF VSMENSAGEMPRAZOVARIAVEL IS NOT NULL THEN
                  IF VSMENSAGEM IS NOT NULL THEN
                     VSCHAR := '#';
                  ELSE
                     VSCHAR := NULL;
                  END IF;

                  VSMENSAGEM := VSMENSAGEM || VSCHAR || UPPER(VSMENSAGEMPRAZOVARIAVEL);
               END IF;
            END IF;
         ELSE
            P_REGPEDIDO.PRAZOMEDIO := P_REGPLPAG.NUMDIAS;
         END IF;

         IF P_REGPLPAG.CODFILIAL IS NOT NULL AND P_REGPLPAG.CODFILIAL <> '99' AND
            P_REGPLPAG.CODFILIAL <> P_REGPEDIDO.CODFILIAL THEN

            IF P_REGPLPAG.USAMULTIFILIAL = 'N' THEN
               IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
               ELSE
                  VSCHAR := NULL;
               END IF;

               VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de Pagamento ' ||
                             P_REGPEDIDO.CODPLPAG || ' nao existe para a filial ' || P_REGPEDIDO.CODFILIAL || ';';
               P_REGPEDIDO.VALIDO      := FALSE;
               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 17;
            END IF;
         END IF;

         VBEXISTEPCPLPAGRESTRICAO := FUNCOESVENDAS.VALIDARPCPLPAGRESTRICAO(P_REGPEDIDO.CODPLPAG,
                                                                           NULL,
                                                                           P_REGPEDIDO.CODCLI,
                                                                           P_REGCLIENTE.CODATV1,
                                                                           NULL,
                                                                           NULL,
                                                                           P_REGPEDIDO.ORIGEMPED,
                                                                           NULL,
                                                                           P_REGPEDIDO.CODFILIAL,
                                                                           P_REGREGIAO.NUMREGIAO,
                                                                           P_REGPEDIDO.CONDVENDA,
                                                                           VSMENSAGEMPCPLPAGRESTRICAO,
                                                                           NULL,
                                                                           NULL);
         IF VBEXISTEPCPLPAGRESTRICAO = TRUE THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMPCPLPAGRESTRICAO || ' ;';

            P_REGPEDIDO.VALIDO := FALSE;

            IF INSTR(TRIM(VSMENSAGEMPCPLPAGRESTRICAO), 'ATIVIDADE') = 0 THEN
               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 18;
            ELSE
               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 19;
            END IF;
         END IF;

         -- verifica prazo do plano de pagamento
         IF P_REGCLIENTE.CODPLPAG > 0 THEN
            IF P_REGPEDIDO.PRAZOMEDIO > P_REGCLIENTE.NUMDIAS AND
               VBEXISTEPLPAGCLI = FALSE AND
               P_REGPLPAG.FORMAPARCELAMENTO <> 'V' THEN
               IF NVL(GREGPCCONSUM.BLOQPRAZOMDVENDA, 'N') = 'S' THEN
                  IF VSMENSAGEM IS NOT NULL THEN
                     VSCHAR := '#';
                  ELSE
                     VSCHAR := NULL;
                  END IF;

                  VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Prazo do plano de pagamento#' ||
                                'superior ao prazo do cliente#' || 'Prazo do pedido ' ||
                                P_REGPLPAG.NUMDIAS || '#Prazo do cliente ' ||
                                P_REGCLIENTE.NUMDIAS || ';';
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 20;

                  IF NVL(GREGPCCONSUM.ACEITAVENDABLOQ, 'N') = 'S' THEN
                     P_REGPEDIDO.POSICAO       := 'B';
                     P_REGPEDIDO.CODMOTIVO     := 13;
                     P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) ||
                                                  'Prazo do plano de pagto superior ao prazo do cliente';
                     P_REGPEDIDO.MOTIVOPOSICAO := 'Prazo do plano de pagto superior ao prazo do cliente';

                     IF P_REGPEDIDO.POSICAO = 'B' THEN
                        PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                     END IF;
                  ELSE
                     p_regpedido.valido := false;
                  END IF ;
               END IF;
            END IF;
         END IF;
      END IF;

      -- verificar tipo de cobranca do pedido
      SELECT COUNT(*)
      INTO VICONTADOR
      FROM PCCOB
      WHERE UPPER(TRIM(CODCOB)) = P_REGPEDIDO.CODCOB
        AND DECODE(P_REGFILIAL.BROKER, 'S', NVL(COBRANCABROKER, 'N'), 'S') = 'S';

      IF VICONTADOR = 0 THEN
         IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
         ELSE
            VSCHAR := NULL;
         END IF;

         VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' ||
                       P_REGPEDIDO.CODCOB || ' nao cadastrada;';

         P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 21;
         -- verifica cobranca do cliente
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCCOB
         WHERE UPPER(TRIM(CODCOB)) = P_REGCLIENTE.CODCOB;

         IF VICONTADOR = 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' ||
                          P_REGCLIENTE.CODCOB || ' nao cadastrada;';

            P_REGPEDIDO.VALIDO := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 21;
         ELSE
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' || P_REGPEDIDO.CODCOB ||
                          ' nao cadastrada#Alterada para ' || P_REGCLIENTE.CODCOB || ';';

            P_REGPEDIDO.CODCOB := P_REGCLIENTE.CODCOB;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 22;
         END IF;
      ELSE
         -- busca nivel da cobranca do pedido
         SELECT NVL(NIVELVENDA, 0),
                NVL(PRAZOMAXIMOVENDA, 0),
                NVL(PCCOB.BOLETO, 'N'),
                TRIM(CODFILIAL),
                NVL(CARTAO, 'N')
         INTO P_REGCOB
         FROM PCCOB
         WHERE UPPER(TRIM(CODCOB)) = P_REGPEDIDO.CODCOB
           AND DECODE(P_REGFILIAL.BROKER, 'S', NVL(COBRANCABROKER, 'N'), 'S') = 'S';

         -- busca nivel da cobranca do cliente
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCCOB
         WHERE UPPER(TRIM(CODCOB)) = P_REGCLIENTE.CODCOB;

         IF VICONTADOR > 0 THEN
            SELECT NVL(NIVELVENDA, 0)
            INTO VNNIVELVENDACLI
            FROM PCCOB
            WHERE UPPER(TRIM(CODCOB)) = P_REGCLIENTE.CODCOB;
         ELSE
            VNNIVELVENDACLI := 0;

            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Nivel da cobranca do cliente (' ||
                          P_REGCLIENTE.CODCOB || ') nao localizada;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 23;
         END IF;
         -- verifica se o campo VALIDARNIVELVENDA é igual a 'S', se sim, continua validação, se não ignora
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPEDCTEMP
         WHERE CODCLI = P_REGPEDIDO.CODCLI
           AND NVL(VALIDARNIVELVENDA, 0) = 'S'
           AND NUMPEDWEB = P_REGPEDIDO.NUMPEDWEB
           AND TIPOINTEGRACAO = 'W';

         IF VICONTADOR > 0 THEN
            IF (P_REGCOB.NIVELVENDA < VNNIVELVENDACLI) THEN
               IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
               ELSE
                  VSCHAR := NULL;
               END IF;

               VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Nivel de venda inferior#' || 'ao nivel de venda do cliente#' ||
                             'Nivel da cobranca#' || P_REGCOB.NIVELVENDA || '#Nivel do cliente ' || VNNIVELVENDACLI || ';';
               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 24;
               P_REGPEDIDO.POSICAO     := 'B';
               P_REGPEDIDO.CODMOTIVO   := 15;
               P_REGPEDIDO.LOG         := P_REGPEDIDO.LOG || CHR(13) ||
                                          ' Nivel de venda inferior ao nivel de venda do cliente';
               P_REGPEDIDO.MOTIVOPOSICAO := 'Nivel de venda inferior ao nivel de venda do cliente';

               IF P_REGPEDIDO.POSICAO = 'B' THEN
                  PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
               END IF;
            END IF;
         END IF;

         IF (P_REGCOB.PRAZOMAXIMOVENDA < P_REGPLPAG.NUMDIAS) THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Prazo maximo da cobranca#' ||
                          'inferior ao prazo do plano#' || 'Prazo maximo da cobranca ' ||
                          P_REGCOB.PRAZOMAXIMOVENDA || '#Prazo do plano ' ||
                          P_REGPLPAG.NUMDIAS || ';';
            P_REGPEDIDO.CODRETORNOS   := P_REGPEDIDO.CODRETORNOS || ';' || 25;
            P_REGPEDIDO.POSICAO       := 'B';
            P_REGPEDIDO.CODMOTIVO     := 17;
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) ||
                                       'Prazo maximo da cobranca, inferior ao prazo do plano';
            P_REGPEDIDO.MOTIVOPOSICAO := 'Prazo maximo da cobranca, inferior oa prazo do plano';

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
         END IF;
      END IF;

      IF P_REGCOB.CARTAO = 'S' AND P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
         IF P_REGPEDIDO.CODAUTORIZACAOTEF IS NULL AND
            P_REGPEDIDO.CODAUTORIZACAOTEFWEB IS NULL THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca Cartao :' ||
                          P_REGPEDIDO.CODCOB || ' exige codigo de autorizacao' || ';';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 139;
         END IF;
      END IF;

      IF P_REGCOB.CODFILIAL IS NOT NULL AND P_REGCOB.CODFILIAL <> '99' AND
         P_REGCOB.CODFILIAL <> P_REGPEDIDO.CODFILIAL THEN
         IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
         ELSE
            VSCHAR := NULL;
         END IF;

         VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' ||
                       P_REGPEDIDO.CODCOB || ' nao existe para a filial ' ||
                       P_REGPEDIDO.CODFILIAL || ';';
         P_REGPEDIDO.VALIDO      := FALSE;
         P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 26;
      END IF;

      IF P_REGCOB.BOLETO = 'S' OR P_REGPEDIDO.CODCOB = 'BK' THEN
         IF P_REGPLPAG.VENDABK = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de Pagamento nao aceita Cobranca BK' || ';';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 27;
         END IF;
      END IF;

      -- verifica permissao para o CONDVENDA
      IF P_REGPEDIDO.CONDVENDA = 1 THEN
         IF P_REGCLIENTE.CONDVENDA1 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 1 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 2 THEN
         IF P_REGCLIENTE.CONDVENDA2 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 2 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 3 THEN
         IF P_REGCLIENTE.CONDVENDA3 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 3 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 4 THEN
         IF P_REGCLIENTE.CONDVENDA4 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 4 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 5 THEN
         IF P_REGCLIENTE.CONDVENDA5 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 5 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 6 THEN
         IF P_REGCLIENTE.CONDVENDA6 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 6 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 10 THEN
         IF P_REGCLIENTE.CONDVENDA10 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 10 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 11 THEN
         IF P_REGCLIENTE.CONDVENDA11 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 11 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
             P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA = 12 THEN
         IF P_REGCLIENTE.CONDVENDA12 = 'N' THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Tipo de Venda 12 nao permitida;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 28;
         END IF;
      END IF;

      -- verifica tipo de venda relacionada a cobranca.
      IF P_REGPEDIDO.CONDVENDA IN (5, 6, 11, 12) THEN
         IF P_REGPEDIDO.CODCOB NOT IN ('BNF', 'BNFT', 'BNFR', 'BNTR') THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' || P_REGPEDIDO.CODCOB ||
                          ' nao permitida para o tipo de venda;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 29;
        END IF;
      END IF;

      IF P_REGPEDIDO.CONDVENDA NOT IN (5, 6, 11, 12) THEN
         IF P_REGPEDIDO.CODCOB IN ('BNF', 'BNFT', 'BNFR', 'BNTR') THEN
            IF VSMENSAGEM IS NOT NULL THEN
               VSCHAR := '#';
            ELSE
               VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' ||
                          P_REGPEDIDO.CODCOB || ' nao permitida para o tipo de venda;';
            P_REGPEDIDO.VALIDO      := FALSE;
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 29;
         END IF;
      END IF;
   END IF;

   P_REGPEDIDO.USACREDRCA           := GREGPCCONSUM.USACREDRCA;
   P_REGPEDIDO.BONIFICALTDEBCREDRCA := GREGPCCONSUM.BONIFICALTDEBCREDRCA;
   P_REGPEDIDO.TROCAALTDEBCREDRCA   := GREGPCCONSUM.TROCAALTDEBCREDRCA;
   P_REGPEDIDO.CRMALTDEBCREDRCA     := GREGPCCONSUM.CRMALTDEBCREDRCA;
   P_REGPEDIDO.BROKERALTDEBCREDRCA  := GREGPCCONSUM.BROKERALTDEBCREDRCA;
   P_REGPEDIDO.TIPOMOVCCRCA         := GREGPCCONSUM.TIPOMOVCCRCA;

   -- registra log
   IF (VSMENSAGEM IS NOT NULL) THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       P_REGPEDIDO.CODRETORNOS,
                       '2',
                       'Erro1:' || VSMENSAGEM,
                       NULL);
   END IF;
EXCEPTION WHEN OTHERS THEN
   P_REGPEDIDO.VALIDO := FALSE;
   PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                    P_REGPEDIDO.NUMPEDINT,
                    NULL,
                    NULL,
                    NULL,
                    P_REGPEDIDO.CODCLI,
                    P_REGPEDIDO.CODUSUR,
                    NULL,
                    NULL,
                    P_REGPEDIDO.INTEGRADORA,
                    NULL,
                    '2',
                    'Erro2:' || SQLCODE || '-' || SQLERRM,
                    NULL);
END PROC_VALIDARCABPED;

/***************************************************
Function validarAutorizacaoVenda
****************************************************/
FUNCTION PROC_VALIDARAUTORIZACAOVENDA(P_REGITEM         IN T_ITEMPED,
                                      P_REGCLIENTE      IN T_CLIENTEPEDIDO,
                                      P_REGPEDIDO       IN T_CABPED,
                                      P_REGPRODUTO      IN T_PRODUTO,
                                      P_REGPLPAG        IN T_PLANODEPAGAMENTO,
                                      P_REGRCA          IN T_RCA,
                                      P_REGFILIAL       IN T_FILIAL,
                                      VNPRECOAUTORIZADO IN OUT NUMBER) RETURN BOOLEAN 
IS
   VICONT            NUMBER := 0;
   VBRESULT          BOOLEAN;
   VNNRAUTORIZACAO   PCAUTORI.NRAUTORIZACAO%TYPE;
   VDDATAAUTORIZACAO PCAUTORI.DATAAUTORIZACAO%TYPE;
   VNPERCDESCAUTOR   PCAUTORI.PERCDESCAUTOR%TYPE;
   VNPVENDAATUAL     PCAUTORI.PVENDAATUAL%TYPE;
   VSBASECREDDEBRCA  PCAUTORI.BASECREDDEBRCA%TYPE;
BEGIN
   VBRESULT := FALSE;

   BEGIN
      SELECT COUNT(*)
      INTO VICONT
      FROM PCAUTORI
      WHERE PCAUTORI.CODCLI = P_REGCLIENTE.CODCLI
        AND PCAUTORI.CODUSUR = P_REGRCA.CODUSUR
        AND PCAUTORI.CODPLPAG = P_REGPLPAG.CODPLPAG
        AND PCAUTORI.CODPROD = P_REGPRODUTO.CODPROD
        AND PCAUTORI.STATUSUTILIZ = 'N';
   END;

   IF VICONT > 0 THEN
      SELECT PCAUTORI.NRAUTORIZACAO,
             PCAUTORI.DATAAUTORIZACAO,
             PCAUTORI.PERCDESCAUTOR,
             PCAUTORI.PVENDAATUAL,
             NVL(PCAUTORI.BASECREDDEBRCA, 'N') BASECREDDEBRCA
      INTO VNNRAUTORIZACAO,
           VDDATAAUTORIZACAO,
           VNPERCDESCAUTOR,
           VNPVENDAATUAL,
             VSBASECREDDEBRCA
      FROM PCAUTORI
      WHERE PCAUTORI.CODCLI = P_REGCLIENTE.CODCLI
        AND PCAUTORI.CODUSUR = P_REGRCA.CODUSUR
        AND PCAUTORI.CODPLPAG = P_REGPLPAG.CODPLPAG
        AND PCAUTORI.CODPROD = P_REGPRODUTO.CODPROD
        AND PCAUTORI.STATUSUTILIZ = 'N'
        AND ROWNUM = 1;

      VNPRECOAUTORIZADO := VNPVENDAATUAL - (VNPVENDAATUAL * (VNPERCDESCAUTOR / 100));

      IF TRUNC(VNPRECOAUTORIZADO * 100) <= TRUNC(P_REGITEM.PVENDA * 100) THEN
         SELECT COUNT(*)
         INTO VICONT
         FROM PCAUTORI
         WHERE PCAUTORI.NRAUTORIZACAO = VNNRAUTORIZACAO
           AND PCAUTORI.STATUSUTILIZ = 'N';

         IF VICONT > 0 THEN
            SELECT PCAUTORI.NRAUTORIZACAO,
                   PCAUTORI.DATAAUTORIZACAO,
                   PCAUTORI.PERCDESCAUTOR,
                   PCAUTORI.PVENDAATUAL,
                   NVL(PCAUTORI.BASECREDDEBRCA, 'N') BASECREDDEBRCA
            INTO VNNRAUTORIZACAO,
                 VDDATAAUTORIZACAO,
                 VNPERCDESCAUTOR,
                 VNPVENDAATUAL,
                 VSBASECREDDEBRCA
            FROM PCAUTORI
            WHERE PCAUTORI.NRAUTORIZACAO = VNNRAUTORIZACAO
              AND PCAUTORI.STATUSUTILIZ = 'N'
            FOR UPDATE;

            UPDATE PCAUTORI
            SET PCAUTORI.DATA_UTILIZACAO = TRUNC(SYSDATE),
                PCAUTORI.CODFUNCUTILIZ   = P_REGPEDIDO.CODEMITENTE,
                PCAUTORI.STATUSUTILIZ    = 'S',
                PCAUTORI.NUMPED          = P_REGRCA.PROXNUMPED,
                PCAUTORI.PVENDIDO        = P_REGITEM.PVENDA
            WHERE PCAUTORI.NRAUTORIZACAO = VNNRAUTORIZACAO;
         END IF;
      END IF;
   END IF;

   RETURN VBRESULT;
EXCEPTION WHEN OTHERS THEN
   VBRESULT := FALSE;
   RETURN VBRESULT;
      --       mensagem de erro;
END PROC_VALIDARAUTORIZACAOVENDA;


  PROCEDURE PROC_VERIFICAPRECOFIXOCESTA(P_REGITEM    IN OUT T_ITEMPED,
                                        P_REGPRODUTO IN OUT T_PRODUTO,
                                        P_REGPEDIDO  IN T_CABPED,
                                        P_REGCLIENTE IN T_CLIENTEPEDIDO,
                                        P_REGREGIAO  IN T_REGIAOCLIENTE,
                                        P_MENSAGEM   OUT VARCHAR2,
                                        P_VALIDO     OUT BOOLEAN) IS
    VICONTADOR             NUMBER;
    VNCOUNTITENSCESTA      NUMBER;
    VNTOTALCESTA           NUMBER;
    VNTOTALCESTATEMP       NUMBER;
    VNCODPRECOCESTA        PCPRECOCESTAC.CODPRECOCESTA%TYPE;

  BEGIN
    P_MENSAGEM := NULL;
    P_VALIDO   := FALSE;

    SELECT COUNT(*)
      INTO VICONTADOR
      FROM PCPRECOCESTAC P
     WHERE P.DTEXCLUSAO IS NULL
       AND P.DTINICIO <= TRUNC(SYSDATE)
       AND P.DTFIM >= TRUNC(SYSDATE)
       AND P.CODPRODACAB = P_REGITEM.CODPROD
       AND (P.CODFILIAL = P_REGPEDIDO.CODFILIAL OR P.CODFILIAL IS NULL)
       AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
       AND (P.CODPLPAG = P_REGPEDIDO.CODPLPAG OR P.CODPLPAG IS NULL)
       AND (P.CODCLI = DECODE(P.UTILIZAPRECOFIXOREDE, 'S', P_REGCLIENTE.CODCLIPRINC, P_REGPEDIDO.CODCLI) OR P.CODCLI IS NULL);

    IF VICONTADOR > 0 THEN
      IF VICONTADOR > 1 THEN
        VNTOTALCESTA := 0;
        -- verificar qual cesta utilizar ( buscando a que tem o menor preço fixo)
        FOR REG IN (SELECT P.CODPRECOCESTA
                      FROM PCPRECOCESTAC P
                     WHERE P.DTEXCLUSAO IS NULL
                       AND P.DTINICIO <= TRUNC(SYSDATE)
                       AND P.DTFIM >= TRUNC(SYSDATE)
                       AND P.CODPRODACAB = P_REGITEM.CODPROD
                       AND (P.CODFILIAL = P_REGPEDIDO.CODFILIAL OR P.CODFILIAL IS NULL)
                       AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
                       AND (P.CODPLPAG = P_REGPEDIDO.CODPLPAG OR P.CODPLPAG IS NULL)
                       AND (P.CODCLI = DECODE(P.UTILIZAPRECOFIXOREDE, 'S',
                                              P_REGCLIENTE.CODCLIPRINC, P_REGPEDIDO.CODCLI) OR P.CODCLI IS NULL)) 
        LOOP
          --verifica se tem algum item da cesta que está sem preco fixo
          SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCFORMPROD F
           WHERE F.CODPRODACAB = P_REGITEM.CODPROD
             AND NOT EXISTS (SELECT 'x'
                             FROM PCPRECOCESTAI I
                             WHERE I.CODPRODMP = F.CODPRODMP
                               AND I.CODPRECOCESTA = REG.CODPRECOCESTA);
          --todos os itens da cesta estão com preço fixo
          IF VICONTADOR = 0 THEN
            VNCOUNTITENSCESTA := GVET_REGITENSCESTA.COUNT;
            VNTOTALCESTATEMP := 0;

            FOR I IN 1 .. VNCOUNTITENSCESTA LOOP
              IF P_REGPEDIDO.NUMPED = GVET_REGITENSCESTA(I).NUMPED AND 
                 P_REGITEM.CODPROD = GVET_REGITENSCESTA(I).CODPRODCESTA THEN
                FOR REGI IN (SELECT I.PRECOFIXO, P.QTPRODMP
                               FROM PCPRECOCESTAI I, PCFORMPROD P
                              WHERE I.CODPRECOCESTA = REG.CODPRECOCESTA
                                AND I.CODPRODACAB = P_REGITEM.CODPROD
                                AND I.CODPRODMP = GVET_REGITENSCESTA(I).CODPRODMP
                                AND I.CODPRODACAB = P.CODPRODACAB
                                AND I.CODPRODMP = P.CODPRODMP) 
                LOOP
                  VNTOTALCESTATEMP := NVL(VNTOTALCESTATEMP, 0) + (REGI.PRECOFIXO * REGI.QTPRODMP);
                END LOOP;
              END IF;
            END LOOP;

            IF VNTOTALCESTATEMP < VNTOTALCESTA OR VNTOTALCESTA = 0 THEN
              VNTOTALCESTA    := VNTOTALCESTATEMP;
              VNCODPRECOCESTA := REG.CODPRECOCESTA;
            END IF;
          END IF;
        END LOOP;
      ELSE
        --tem apenas 1 campanha de preço fixo de cesta
        SELECT P.CODPRECOCESTA
          INTO VNCODPRECOCESTA
          FROM PCPRECOCESTAC P
         WHERE P.DTEXCLUSAO IS NULL
           AND P.DTINICIO <= TRUNC(SYSDATE)
           AND P.DTFIM >= TRUNC(SYSDATE)
           AND P.CODPRODACAB = P_REGITEM.CODPROD
           AND (P.CODFILIAL = P_REGPEDIDO.CODFILIAL OR P.CODFILIAL IS NULL)
           AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
           AND (P.CODPLPAG = P_REGPEDIDO.CODPLPAG OR P.CODPLPAG IS NULL)
           AND (P.CODCLI = DECODE(P.UTILIZAPRECOFIXOREDE, 'S', P_REGCLIENTE.CODCLIPRINC, P_REGPEDIDO.CODCLI) OR P.CODCLI IS NULL);
      END IF;

      VNTOTALCESTA := 0;
      --verifica se tem algum item da cesta que está sem preco fixo
      SELECT COUNT(*)
        INTO VICONTADOR
        FROM PCFORMPROD F
       WHERE F.CODPRODACAB = P_REGITEM.CODPROD
         AND NOT EXISTS (SELECT 'x'
                         FROM PCPRECOCESTAI I
                         WHERE I.CODPRODMP = F.CODPRODMP
                           AND I.CODPRECOCESTA = VNCODPRECOCESTA);
      --todos os itens da cesta estão com preço fixo
      IF VICONTADOR = 0 THEN
        VNCOUNTITENSCESTA := GVET_REGITENSCESTA.COUNT;

        FOR I IN 1 .. VNCOUNTITENSCESTA LOOP
          IF P_REGPEDIDO.NUMPED = GVET_REGITENSCESTA(I).NUMPED AND 
             P_REGITEM.CODPROD = GVET_REGITENSCESTA(I).CODPRODCESTA THEN
            FOR REGI IN (SELECT I.PRECOFIXO, P.QTPRODMP
                           FROM PCPRECOCESTAI I, PCFORMPROD P
                          WHERE I.CODPRECOCESTA = VNCODPRECOCESTA
                            AND I.CODPRODACAB = P_REGITEM.CODPROD
                            AND I.CODPRODMP = GVET_REGITENSCESTA(I).CODPRODMP
                            AND I.CODPRODACAB = P.CODPRODACAB
                            AND I.CODPRODMP = P.CODPRODMP) LOOP

              GVET_REGITENSCESTA(I).PTABELA := REGI.PRECOFIXO;
              GVET_REGITENSCESTA(I).PVENDA := REGI.PRECOFIXO;
              VNTOTALCESTA := NVL(VNTOTALCESTA, 0) + (REGI.PRECOFIXO * REGI.QTPRODMP);
            END LOOP;
          END IF;
        END LOOP;

        P_REGITEM.PBASERCA   := NVL(VNTOTALCESTA, P_REGITEM.PBASERCA);
        P_REGPRODUTO.PTABELA := NVL(VNTOTALCESTA, P_REGPRODUTO.PTABELA);

        IF NVL(VNTOTALCESTA, 0) > 0 THEN
          P_VALIDO := TRUE;
        END IF;
      ELSE
        P_MENSAGEM := 'Preço Fixo da cesta inválida. Será o utilizado o preço de tabela.';
      END IF;
    END IF;
  END PROC_VERIFICAPRECOFIXOCESTA;


  PROCEDURE PROC_VALIDAITENSCESTA(P_REGITEM              IN OUT T_ITEMPED,
                                  P_REGORIGEMPRECO       IN OUT T_ORIGEMPRECO,
                                  P_REGPRODUTO           IN OUT T_PRODUTO,
                                  P_REGPEDIDO            IN T_CABPED,
                                  P_REGFILIAL            IN T_FILIAL,
                                  P_REGREGIAO            IN T_REGIAOCLIENTE,
                                  P_REGCLIENTE           IN T_CLIENTEPEDIDO,
                                  P_REGPLPAG             IN T_PLANODEPAGAMENTO,
                                  P_MENSAGEM             OUT VARCHAR2,
                                  P_VALIDOPRECOFIXOCESTA OUT BOOLEAN) 
  IS
    VNCOUNT                 NUMBER := 0;
    VNIVA                   PCPEDI.IVA%TYPE;
    VNPTABELA               PCPEDI.PTABELA%TYPE;
    VNPAUTA                 PCPEDI.PAUTA%TYPE;
    VNALIQICMS1             PCPEDI.ALIQICMS1%TYPE;
    VNALIQICMS2             PCPEDI.ALIQICMS2%TYPE;
    VNIVAFONTE              PCTRIBUT.IVAFONTE%TYPE;
    VNALIQICMS1FONTE        PCTRIBUT.ALIQICMS1FONTE%TYPE;
    VNALIQICMS2FONTE        PCTRIBUT.ALIQICMS2FONTE%TYPE;
    VNPERCBASEREDST         PCTRIBUT.PERCBASEREDST%TYPE;
    VNPERCBASERED           PCTRIBUT.PERCBASERED%TYPE;
    VSUSAVALORULTENTBASEST  PCTRIBUT.USAVALORULTENTBASEST%TYPE;
    VSUSAVALORULTENTBASEST2 PCTRIBUT.USAVALORULTENTBASEST2%TYPE;
    VNVALORULTENT           PCEST.VALORULTENT%TYPE;
    VNPERCBASEREDCONSUMIDOR PCTRIBUT.PERCBASEREDCONSUMIDOR%TYPE;
    VSUTILIZAPERCBASEREDPF  PCTRIBUT.UTILIZAPERCBASEREDPF%TYPE;
    VNPERCBASEREDSTFONTE    PCTRIBUT.PERCBASEREDSTFONTE%TYPE;
    VNPERDESCCUSTO PCTRIBUT.PERDESCCUSTO%TYPE;
    VNCUSTOCONT    PCEST.CUSTOCONT%TYPE;
    VNCUSTOREP     PCEST.CUSTOREP%TYPE;
    VNCODICMTAB    PCTRIBUT.CODICMTAB%TYPE;
    VNVLCUSTOFIN  PCPEDI.VLCUSTOFIN%TYPE;
    VNVLCUSTOREAL PCPEDI.VLCUSTOREAL%TYPE;
    VNPCOMINT1           PCPRODUT.PCOMINT1%TYPE;
    VNPCOMEXT1           PCPRODUT.PCOMEXT1%TYPE;
    VNPCOMREP1           PCPRODUT.PCOMREP1%TYPE;
    VNCODLINHAPROD       PCPRODUT.CODLINHAPROD%TYPE;
    VNCODSEC             PCPRODUT.CODSEC%TYPE;
    VNCODEPTO            PCPRODUT.CODEPTO%TYPE;
    VNCODICMTABPF        PCTRIBUT.CODICMTABPF%TYPE;
    VNFRETEESPECIAL      PCPRODUT.FRETEESPECIAL%TYPE;
    VSMOSTRARPVENDASEMST PCTRIBUT.MOSTRARPVENDASEMST%TYPE;
    VSMENSAGEMPRECOFIXOCESTA VARCHAR2(32767);
    VBVALIDOPRECOFIXOCESTA   BOOLEAN;
    VSUSAPMCBASEST   PCTRIBUT.USAPMCBASEST%TYPE;
    VNPRECOMAXCONSUM PCPRODUT.PRECOMAXCONSUM%TYPE;
    VNCUSTONFSEMST   PCEST.CUSTONFSEMST%TYPE;
    VSCODFILIALNF          PCPEDC.CODFILIALNF%TYPE;
    VICONTADOR             NUMBER;
    VSMENSAGEM             VARCHAR2(300);
    VSCHAR                 VARCHAR2(3);
    VNCODST                PCTRIBUT.CODST%TYPE;
    VNPERACRESCISMOPF      PCTRIBUT.PERACRESCISMOPF%TYPE;
    VSAPLICAACRESCPJISENTA PCTRIBUT.APLICAACRESCPJISENTA%TYPE;
    VSTIPOCOMISSAO           PCPRODUT.TIPOCOMISSAO%TYPE;
    VSCLASSE                 PCPRODUT.CLASSE%TYPE;
    VSUSAVLULTENTMEDIOBASEST PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE;
    VNVLULTENTMES            PCTABPR.VLULTENTMES%TYPE;
    VSIMPORTADO              PCPRODUT.IMPORTADO%TYPE;
    VSAGREGARIPICALCULOST    PCTRIBUT.AGREGARIPICALCULOST%TYPE;
    VNPTABELASEMIMPOSTO      PCTABPR.PVENDASEMIMPOSTO1%TYPE;
    VNPERCBASESTRJ           PCTRIBUT.PERCBASESTRJ%TYPE;
  BEGIN
    VNCOUNT := 0;

    FOR REG_ITENSCESTA IN (SELECT P.CODPRODMP, P.QTPRODMP, P.CODAUXILIARMP
                             FROM PCFORMPROD P
                            WHERE P.CODPRODACAB = P_REGITEM.CODPROD) 
    LOOP
      VNCOUNT := VNCOUNT + 1;

      IF GREGPCCONSUM.USATRIBUTACAOPORUF = 'S' THEN
        IF P_REGPEDIDO.CODFILIALNF IS NULL THEN
          IF P_REGCLIENTE.CODFILIALNF IS NULL THEN
            VSCODFILIALNF := P_REGPEDIDO.CODFILIAL;
          ELSE
            VSCODFILIALNF := P_REGCLIENTE.CODFILIALNF;
          END IF;
        ELSE
          VSCODFILIALNF := P_REGPEDIDO.CODFILIALNF;
        END IF;

        SELECT COUNT(*)
          INTO VICONTADOR
          FROM PCTABTRIB P
         WHERE P.CODPROD = REG_ITENSCESTA.CODPRODMP
           AND P.CODFILIALNF = VSCODFILIALNF
           AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

        IF VICONTADOR = 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Não encontrada tributação por estado para item da cesta';
          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
        ELSE
          SELECT P.CODST
            INTO VNCODST
            FROM PCTABTRIB P
           WHERE P.CODPROD = REG_ITENSCESTA.CODPRODMP
             AND P.CODFILIALNF = VSCODFILIALNF
             AND P.UFDESTINO = P_REGCLIENTE.ESTENT
             AND ROWNUM = 1;

          BEGIN
            SELECT DECODE(P_REGPLPAG.NUMPR, 1,
                          PCTABPR.PVENDA1,  2,
                          PCTABPR.PVENDA2,  3,
                          PCTABPR.PVENDA3,  4,
                          PCTABPR.PVENDA4,  5,
                          PCTABPR.PVENDA5,  6,
                          PCTABPR.PVENDA6,  7,
                          PCTABPR.PVENDA7,  0),
                   NVL(PCTRIBUT.PAUTA, 0),
                   NVL(PCTRIBUT.ALIQICMS1, 0),
                   NVL(PCTRIBUT.ALIQICMS2, 0),
                   NVL(PCEST.CUSTOFIN, 0),
                   NVL(PCEST.CUSTOREAL, 0),
                   NVL(PCTRIBUT.IVA, 0),
                   NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                   NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                   NVL(PCTRIBUT.PERCBASEREDST, 0),
                   NVL(PCTRIBUT.PERCBASERED, 0),
                   PCTRIBUT.USAVALORULTENTBASEST,
                   PCTRIBUT.USAVALORULTENTBASEST2,
                   NVL(PCEST.VALORULTENT, 0),
                   NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                   PCTRIBUT.UTILIZAPERCBASEREDPF,
                   NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                   PCTRIBUT.CODST,
                   NVL(PCTRIBUT.PERDESCCUSTO, 0),
                   NVL(PCEST.CUSTOCONT, 0),
                   NVL(PCEST.CUSTOREP, 0),
                   NVL(PCTRIBUT.CODICMTAB, 0),
                   PCPRODUT.PCOMINT1,
                   PCPRODUT.PCOMEXT1,
                   PCPRODUT.PCOMREP1,
                   PCPRODUT.CODLINHAPROD,
                   PCPRODUT.CODSEC,
                   PCPRODUT.CODEPTO,
                   NVL(PCTRIBUT.CODICMTABPF,0),
                   PCPRODUT.FRETEESPECIAL,
                   NVL(PCTRIBUT.MOSTRARPVENDASEMST,
                       NVL(GREGPCCONSUM.MOSTRARPVENDASEMST, 'N')),
                   NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                   NVL(PCPRODUT.PRECOMAXCONSUM, 0),
                   NVL(PCEST.CUSTONFSEMST, PCEST.VALORULTENT),
                   NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                   NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                   PCPRODUT.TIPOCOMISSAO,
                   PCPRODUT.CLASSE,
                   NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                   NVL(PCTABPR.VLULTENTMES, 0),
                   PCPRODUT.IMPORTADO,
                   NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                   DECODE(P_REGPLPAG.NUMPR, 1,
                          PCTABPR.PVENDASEMIMPOSTO1, 2,
                          PCTABPR.PVENDASEMIMPOSTO2, 3,
                          PCTABPR.PVENDASEMIMPOSTO3, 4,
                          PCTABPR.PVENDASEMIMPOSTO4, 5,
                          PCTABPR.PVENDASEMIMPOSTO5, 6,
                          PCTABPR.PVENDASEMIMPOSTO6, 7,
                          PCTABPR.PVENDASEMIMPOSTO7, 0),
                   NVL(PCTRIBUT.PERCBASESTRJ, 0)
              INTO VNPTABELA,
                   VNPAUTA,
                   VNALIQICMS1,
                   VNALIQICMS2,
                   VNVLCUSTOFIN,
                   VNVLCUSTOREAL,
                   VNIVA,
                   VNALIQICMS1FONTE,
                   VNALIQICMS2FONTE,
                   VNPERCBASEREDST,
                   VNPERCBASERED,
                   VSUSAVALORULTENTBASEST,
                   VSUSAVALORULTENTBASEST2,
                   VNVALORULTENT,
                   VNPERCBASEREDCONSUMIDOR,
                   VSUTILIZAPERCBASEREDPF,
                   VNPERCBASEREDSTFONTE,
                   VNCODST,
                   VNPERDESCCUSTO,
                   VNCUSTOCONT,
                   VNCUSTOREP,
                   VNCODICMTAB,
                   VNPCOMINT1,
                   VNPCOMEXT1,
                   VNPCOMREP1,
                   VNCODLINHAPROD,
                   VNCODSEC,
                   VNCODEPTO,
                   VNCODICMTABPF,
                   VNFRETEESPECIAL,
                   VSMOSTRARPVENDASEMST,
                   VSUSAPMCBASEST,
                   VNPRECOMAXCONSUM,
                   VNCUSTONFSEMST,
                   VNPERACRESCISMOPF,
                   VSAPLICAACRESCPJISENTA,
                   VSTIPOCOMISSAO,
                   VSCLASSE,
                   VSUSAVLULTENTMEDIOBASEST,
                   VNVLULTENTMES,
                   VSIMPORTADO,
                   VSAGREGARIPICALCULOST,
                   VNPTABELASEMIMPOSTO,
                   VNPERCBASESTRJ
              FROM PCTABPR, PCTRIBUT, PCEST, PCPRODUT
             WHERE PCTRIBUT.CODST = VNCODST
               AND PCTABPR.CODPROD = REG_ITENSCESTA.CODPRODMP
               AND PCEST.CODPROD = REG_ITENSCESTA.CODPRODMP
               AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
               AND PCEST.CODFILIAL = P_REGPEDIDO.CODFILIAL
               AND PCTABPR.CODPROD = PCPRODUT.CODPROD;
          EXCEPTION
            WHEN OTHERS THEN
              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;

              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Erro ao buscar preço do item da cesta : ' ||
                            REG_ITENSCESTA.CODPRODMP;
              P_REGITEM.VALIDO        := FALSE;
              P_REGORIGEMPRECO.VALIDO := FALSE;
          END;
        END IF;
      ELSE
        BEGIN
          SELECT DECODE(P_REGPLPAG.NUMPR, 1,
                        PCTABPR.PVENDA1,  2,
                        PCTABPR.PVENDA2,  3,
                        PCTABPR.PVENDA3,  4,
                        PCTABPR.PVENDA4,  5,
                        PCTABPR.PVENDA5,  6,
                        PCTABPR.PVENDA6,  7,
                        PCTABPR.PVENDA7,  0),
                 NVL(PCTRIBUT.PAUTA, 0),
                 NVL(PCTRIBUT.ALIQICMS1, 0),
                 NVL(PCTRIBUT.ALIQICMS2, 0),
                 NVL(PCEST.CUSTOFIN, 0),
                 NVL(PCEST.CUSTOREAL, 0),
                 NVL(PCTRIBUT.IVA, 0),
                 NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                 NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                 NVL(PCTRIBUT.PERCBASEREDST, 0),
                 NVL(PCTRIBUT.PERCBASERED, 0),
                 PCTRIBUT.USAVALORULTENTBASEST,
                 PCTRIBUT.USAVALORULTENTBASEST2,
                 NVL(PCEST.VALORULTENT, 0),
                 NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                 PCTRIBUT.UTILIZAPERCBASEREDPF,
                 NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                 PCTABPR.CODST,
                 NVL(PCTRIBUT.PERDESCCUSTO, 0),
                 NVL(PCEST.CUSTOCONT, 0),
                 NVL(PCEST.CUSTOREP, 0),
                 NVL(PCTRIBUT.CODICMTAB,0),
                 PCPRODUT.PCOMINT1,
                 PCPRODUT.PCOMEXT1,
                 PCPRODUT.PCOMREP1,
                 PCPRODUT.CODLINHAPROD,
                 PCPRODUT.CODSEC,
                 PCPRODUT.CODEPTO,
                 NVL(PCTRIBUT.CODICMTABPF,0),
                 PCPRODUT.FRETEESPECIAL,
                 NVL(PCTRIBUT.MOSTRARPVENDASEMST,
                     NVL(GREGPCCONSUM.MOSTRARPVENDASEMST, 'N')),
                 NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                 NVL(PCPRODUT.PRECOMAXCONSUM, 0),
                 NVL(PCEST.CUSTONFSEMST, PCEST.VALORULTENT),
                 NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                 NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                 PCPRODUT.TIPOCOMISSAO,
                 PCPRODUT.CLASSE,
                 NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                 NVL(PCTABPR.VLULTENTMES, 0),
                 PCPRODUT.IMPORTADO,
                 NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                 DECODE(P_REGPLPAG.NUMPR, 1,
                        PCTABPR.PVENDASEMIMPOSTO1, 2,
                        PCTABPR.PVENDASEMIMPOSTO2, 3,
                        PCTABPR.PVENDASEMIMPOSTO3, 4,
                        PCTABPR.PVENDASEMIMPOSTO4, 5,
                        PCTABPR.PVENDASEMIMPOSTO5, 6,
                        PCTABPR.PVENDASEMIMPOSTO6, 7,
                        PCTABPR.PVENDASEMIMPOSTO7, 0),
                 NVL(PCTRIBUT.PERCBASESTRJ, 0)
            INTO VNPTABELA,
                 VNPAUTA,
                 VNALIQICMS1,
                 VNALIQICMS2,
                 VNVLCUSTOFIN,
                 VNVLCUSTOREAL,
                 VNIVA,
                 VNALIQICMS1FONTE,
                 VNALIQICMS2FONTE,
                 VNPERCBASEREDST,
                 VNPERCBASERED,
                 VSUSAVALORULTENTBASEST,
                 VSUSAVALORULTENTBASEST2,
                 VNVALORULTENT,
                 VNPERCBASEREDCONSUMIDOR,
                 VSUTILIZAPERCBASEREDPF,
                 VNPERCBASEREDSTFONTE,
                 VNCODST,
                 VNPERDESCCUSTO,
                 VNCUSTOCONT,
                 VNCUSTOREP,
                 VNCODICMTAB,
                 VNPCOMINT1,
                 VNPCOMEXT1,
                 VNPCOMREP1,
                 VNCODLINHAPROD,
                 VNCODSEC,
                 VNCODEPTO,
                 VNCODICMTABPF,
                 VNFRETEESPECIAL,
                 VSMOSTRARPVENDASEMST,
                 VSUSAPMCBASEST,
                 VNPRECOMAXCONSUM,
                 VNCUSTONFSEMST,
                 VNPERACRESCISMOPF,
                 VSAPLICAACRESCPJISENTA,
                 VSTIPOCOMISSAO,
                 VSCLASSE,
                 VSUSAVLULTENTMEDIOBASEST,
                 VNVLULTENTMES,
                 VSIMPORTADO,
                 VSAGREGARIPICALCULOST,
                 VNPTABELASEMIMPOSTO,
                 VNPERCBASESTRJ
            FROM PCTABPR, PCTRIBUT, PCEST, PCPRODUT
           WHERE PCTABPR.CODST = PCTRIBUT.CODST
             AND PCTABPR.CODPROD = REG_ITENSCESTA.CODPRODMP
             AND PCEST.CODPROD = REG_ITENSCESTA.CODPRODMP
             AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
             AND PCEST.CODFILIAL = P_REGPEDIDO.CODFILIAL
             AND PCTABPR.CODPROD = PCPRODUT.CODPROD;
        EXCEPTION
          WHEN OTHERS THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Erro ao buscar preço do item da cesta : ' ||
                          REG_ITENSCESTA.CODPRODMP;
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
        END;
      END IF;

      IF NVL(VNPTABELA, 0) = 0 THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Item da cesta ' ||
                      REG_ITENSCESTA.CODPRODMP || ' com preço de tabela zerado.';
        P_REGITEM.VALIDO        := FALSE;
        P_REGORIGEMPRECO.VALIDO := FALSE;
      END IF;

      -- aplica taxa financeira do plano de pagamento
      IF (P_REGPEDIDO.TIPOINTEGRACAO <> 'W' OR  P_REGPEDIDO.INTEGRADORA = 10) AND (NVL(P_REGPLPAG.PERTXFIM,0) <> 0) THEN
         VNPTABELA := VNPTABELA * (1 + (P_REGPLPAG.PERTXFIM / 100));
      END IF;

      IF (P_REGPEDIDO.CONDVENDA <> 3 AND P_REGPEDIDO.CONDVENDA <> 6 AND
         P_REGPEDIDO.CONDVENDA <> 12) OR
         GREGPCCONSUM.APLICAACRESCPFTV3 = 'S' THEN
        IF GREGPCCONSUM.ACRESCIMOPFCOMIE = 'S' THEN
          IF ((((VSAPLICAACRESCPJISENTA = 'S') AND
             ((P_REGCLIENTE.IEENT = 'ISENTA') OR
             (P_REGCLIENTE.IEENT = 'ISENTO'))) OR
             ((P_REGCLIENTE.TIPOFJ = 'F') OR
             (P_REGCLIENTE.CONSUMIDORFINAL = 'S'))) AND
             (P_REGCLIENTE.CONTRIBUINTE = 'N')) THEN
            VNPTABELA := (VNPTABELA + (VNPTABELA * VNPERACRESCISMOPF / 100));
          END IF;
        ELSE
          IF ((((VSAPLICAACRESCPJISENTA = 'S') AND
             ((P_REGCLIENTE.IEENT = 'ISENTA') OR
             (P_REGCLIENTE.IEENT = 'ISENTO'))) OR
             (((P_REGCLIENTE.TIPOFJ = 'F') OR
             (P_REGCLIENTE.CONSUMIDORFINAL = 'S')) AND
             (TRIM(NVL(P_REGCLIENTE.IEENT,'')) = ''))) AND
             (P_REGCLIENTE.CONTRIBUINTE = 'N')) THEN
            VNPTABELA := (VNPTABELA + (VNPTABELA * VNPERACRESCISMOPF / 100));
          END IF;
        END IF;
      END IF;

      GVET_REGITENSCESTA(VNCOUNT).NUMPED := P_REGPEDIDO.NUMPED;
      GVET_REGITENSCESTA(VNCOUNT).CODPRODCESTA := P_REGITEM.CODPROD;
      GVET_REGITENSCESTA(VNCOUNT).CODPRODMP := REG_ITENSCESTA.CODPRODMP;
      GVET_REGITENSCESTA(VNCOUNT).CODAUXILIAR := REG_ITENSCESTA.CODAUXILIARMP;
      GVET_REGITENSCESTA(VNCOUNT).PVENDA := VNPTABELA;
      GVET_REGITENSCESTA(VNCOUNT).PTABELA := VNPTABELA;
      GVET_REGITENSCESTA(VNCOUNT).QT := REG_ITENSCESTA.QTPRODMP;
      GVET_REGITENSCESTA(VNCOUNT).PAUTA := VNPAUTA;
      GVET_REGITENSCESTA(VNCOUNT).IVA := VNIVA;
      GVET_REGITENSCESTA(VNCOUNT).ALIQICMS1 := VNALIQICMS1;
      GVET_REGITENSCESTA(VNCOUNT).ALIQICMS2 := VNALIQICMS2;
      GVET_REGITENSCESTA(VNCOUNT).VLCUSTOFIN := VNVLCUSTOFIN;
      GVET_REGITENSCESTA(VNCOUNT).VLCUSTOREAL := VNVLCUSTOREAL;
      GVET_REGITENSCESTA(VNCOUNT).IVAFONTE := VNIVAFONTE;
      GVET_REGITENSCESTA(VNCOUNT).ALIQICMS1FONTE := VNALIQICMS1FONTE;
      GVET_REGITENSCESTA(VNCOUNT).ALIQICMS2FONTE := VNALIQICMS2FONTE;
      GVET_REGITENSCESTA(VNCOUNT).PERCBASEREDST := VNPERCBASEREDST;
      GVET_REGITENSCESTA(VNCOUNT).PERCBASERED := VNPERCBASERED;
      GVET_REGITENSCESTA(VNCOUNT).USAVALORULTENTBASEST := VSUSAVALORULTENTBASEST;
      GVET_REGITENSCESTA(VNCOUNT).USAVALORULTENTBASEST2 := VSUSAVALORULTENTBASEST2;
      GVET_REGITENSCESTA(VNCOUNT).VALORULTENT := VNVALORULTENT;
      GVET_REGITENSCESTA(VNCOUNT).UTILIZAPERCBASEREDPF := VSUTILIZAPERCBASEREDPF;
      GVET_REGITENSCESTA(VNCOUNT).PERCBASEREDSTFONTE := VNPERCBASEREDSTFONTE;
      GVET_REGITENSCESTA(VNCOUNT).CODST := VNCODST;
      GVET_REGITENSCESTA(VNCOUNT).PERDESCCUSTO := VNPERDESCCUSTO;
      GVET_REGITENSCESTA(VNCOUNT).CUSTOCONT := VNCUSTOCONT;
      GVET_REGITENSCESTA(VNCOUNT).CUSTOREP := VNCUSTOREP;
      GVET_REGITENSCESTA(VNCOUNT).CODICMTAB := VNCODICMTAB;
      GVET_REGITENSCESTA(VNCOUNT).PCOMINT1 := VNPCOMINT1;
      GVET_REGITENSCESTA(VNCOUNT).PCOMEXT1 := VNPCOMEXT1;
      GVET_REGITENSCESTA(VNCOUNT).PCOMREP1 := VNPCOMREP1;
      GVET_REGITENSCESTA(VNCOUNT).CODLINHAPROD := VNCODLINHAPROD;
      GVET_REGITENSCESTA(VNCOUNT).CODSEC := VNCODSEC;
      GVET_REGITENSCESTA(VNCOUNT).CODEPTO := VNCODEPTO;
      GVET_REGITENSCESTA(VNCOUNT).CODICMTABPF := VNCODICMTABPF;
      GVET_REGITENSCESTA(VNCOUNT).FRETEESPECIAL := VNFRETEESPECIAL;
      GVET_REGITENSCESTA(VNCOUNT).MOSTRARPVENDASEMST := VSMOSTRARPVENDASEMST;
      GVET_REGITENSCESTA(VNCOUNT).USAPMCBASEST := VSUSAPMCBASEST;
      GVET_REGITENSCESTA(VNCOUNT).PRECOMAXCONSUM := VNPRECOMAXCONSUM;
      GVET_REGITENSCESTA(VNCOUNT).CUSTONFSEMST := VNCUSTONFSEMST;
      GVET_REGITENSCESTA(VNCOUNT).TIPOCOMISSAO := VSTIPOCOMISSAO;
      GVET_REGITENSCESTA(VNCOUNT).TIPOCOMISSAO := VSCLASSE;
      GVET_REGITENSCESTA(VNCOUNT).USAVLULTENTMEDIOBASEST := VSUSAVLULTENTMEDIOBASEST;
      GVET_REGITENSCESTA(VNCOUNT).VLULTENTMES := VNVLULTENTMES;
      GVET_REGITENSCESTA(VNCOUNT).IMPORTADO := VSIMPORTADO;
      GVET_REGITENSCESTA(VNCOUNT).AGREGARIPICALCULOST := VSAGREGARIPICALCULOST;
      GVET_REGITENSCESTA(VNCOUNT).PERCBASESTRJ := VNPERCBASESTRJ;
    END LOOP;

    --preco fixo cesta básica
    PROC_VERIFICAPRECOFIXOCESTA(P_REGITEM,
                                P_REGPRODUTO,
                                P_REGPEDIDO,
                                P_REGCLIENTE,
                                P_REGREGIAO,
                                VSMENSAGEMPRECOFIXOCESTA,
                                VBVALIDOPRECOFIXOCESTA);

    IF VSMENSAGEMPRECOFIXOCESTA IS NOT NULL THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSMENSAGEM := VSMENSAGEM || ';' || VSMENSAGEMPRECOFIXOCESTA;
      ELSE
        VSMENSAGEM := VSMENSAGEMPRECOFIXOCESTA;
      END IF;
    END IF;

    P_MENSAGEM             := VSMENSAGEM;
    P_VALIDOPRECOFIXOCESTA := VBVALIDOPRECOFIXOCESTA;
  END PROC_VALIDAITENSCESTA;


PROCEDURE PROC_VALIDARITEMPED(P_REGITEM         IN OUT T_ITEMPED,
                              P_REGPEDIDO       IN OUT T_CABPED,
                              P_REGCLIENTE      IN T_CLIENTEPEDIDO,
                              P_REGRCA          IN T_RCA,
                              P_REGREGIAO       IN T_REGIAOCLIENTE,
                              P_REGPLPAG        IN T_PLANODEPAGAMENTO,
                              P_REGFILIAL       IN T_FILIAL,
                              P_REGORIGEMPRECO  IN OUT T_ORIGEMPRECO,
                              P_REGORIGEMCOMISS IN OUT T_ORIGEMCOMISS,
                              P_REGORIGEMDESC   IN OUT T_ORIGEMDESC,
                              P_REGPRODUTO      OUT T_PRODUTO,
                              P_REGPRECOS       OUT T_PRECOSETRIBUTACAO,
                              P_VET_REGITEM     IN TB_ITEMPEDATUAL,
                              VSCODDISTRIB      IN PCPRODUT.CODDISTRIB%TYPE) 
IS
   VICONTADOR          NUMBER;
   VSMENSAGEM          VARCHAR2(32767);
   VSMENSAGEMPOLITICA  VARCHAR2(32767);
   VSCHAR              VARCHAR2(1) DEFAULT '#';
   VNPERMAXDESC        NUMBER;
   VNPVENDAMIN         NUMBER;
   VNPVENDAMAX         NUMBER;
   VBEXISTEPOLITICA    BOOLEAN;
   VNPERCDESCPOLITICA  PCDESCONTO.PERCDESC%TYPE;
   VSBASECREDDEBRCA    PCDESCONTO.BASECREDDEBRCA%TYPE;
   VBVALIDOPRECOFIXO   BOOLEAN := TRUE;
   VNPRECOFIXO         NUMBER;
   VNPERDESCATIV       NUMBER;
   VNPTABELA_ANT       NUMBER;
   VNPPOLITICA         NUMBER;
   VNPTABELADESCQUANT  NUMBER;
   VSMENSAGEMDESCQUANT VARCHAR2(32767);
   VDDTFIM             DATE;
   VBVALIDODESCQUANT   BOOLEAN := FALSE;
   VSMENSAGEMPRECOFIXO VARCHAR2(32767);
   VNPERMAXVENDA            NUMBER;
   VNPERCDESCPOLITICA_ACRES PCDESCONTO.PERCDESC%TYPE;
   VSMENSAGEM_REST          VARCHAR2(32767);
   VSCREDITASOBREPOLITICA VARCHAR2(1);
   VNPERCAUX              NUMBER;
   VNPERCQUANTFLEX        NUMBER;
   VSCREDITASOBREPTABELA  VARCHAR2(1);
   VSMENSAGEMAUTORI VARCHAR2(1000);
   VBVALIDO_AUTORI  BOOLEAN;
   VNPERCDESCPOLITICA_ACRES_AUX PCDESCONTO.PERCDESC%TYPE;
   VNNRAUTORIZACAO              NUMBER;
   VNPERCDESCAUTOR              NUMBER;
   VDDATAAUTORI                 DATE;
   VNINICIOINTERVALO            NUMBER;
   VNFIMINTERVALO               NUMBER;
   VNCODST                      PCTRIBUT.CODST%TYPE;
   VSCODFILIALNF                PCTABTRIB.CODFILIALNF%TYPE;
   VNPTABELAAUX           PCPEDI.PTABELA%TYPE;
   VSBASECREDDEBRCA_QUANT PCDESCQUANT.BASECREDDEBRCA%TYPE;
   VSALTERAPTABELA        PCDESCONTO.ALTERAPTABELA%TYPE;
   VNPERCPBASERCA         PCDESCONTO.PERCDESC%TYPE;
   VNPERCBASERCA_QUANT    PCDESCQUANT.PERCDESC%TYPE;
   VBECESTA               BOOLEAN;
   VSMENSAGEMCESTA        VARCHAR2(300);
   VSMENSAGEMITENSCESTA   VARCHAR2(300);
   VNPTABELACESTA         NUMBER;
   VBVALIDOPRECOFIXOCESTA BOOLEAN;
   VNSUBTOTAL             NUMBER;
   VNPERDESCCESTA         NUMBER := 0;
   VNPVENDAMAIOR          NUMBER;
   VNREG                  NUMBER;
   VNDIF                  NUMBER;
   VNCOUNT                NUMBER;
   VSPRIORITARIAGERAL     PCDESCONTO.PRIORITARIAGERAL%TYPE;
   VNCODDESC              PCDESCONTO.CODDESCONTO%TYPE;
   VSQUESTIONAPRIORITARIA_AUX PCDESCONTO.QUESTIONAUSOPRIORITARIA%TYPE;
   VSPRIORITARIA_AUX          PCDESCONTO.PRIORITARIA%TYPE;
   VBEXISTEPCPLPAGRESTRICAO   BOOLEAN;
   VSMENSAGEMPCPLPAGRESTRICAO VARCHAR2(1000);
   VNCODPOLPBASERCA_561 PCDESCONTO.CODDESCONTO%TYPE;
   VNCODPOL_387         PCDESCQUANT.CODDESCONTO%TYPE;
   VNCODPOLPBASERCA_387 PCDESCQUANT.CODDESCONTO%TYPE;
   VNPPOLITICA_PBASERCA PCPEDI.PBASERCA%TYPE;
   VNPERCPBASERCATEMP PCDESCONTO.PERCDESC%TYPE;
   VNMULTIPLO             PCPRODFILIAL.MULTIPLO%TYPE;
   VNQTMAXPEDVENDA        PCPRODFILIAL.QTMAXPEDVENDA%TYPE;
   VICOTARCA         NUMBER;
   VICOTACLI         NUMBER;
   VBVALIDOCOTARCA   BOOLEAN;
   VBVALIDOCOTACLI   BOOLEAN;
   VSMENSAGEMCOTARCA VARCHAR2(1000);
   VSMENSAGEMCOTACLI VARCHAR2(1000);
   VSPROIBIDAVENDA              PCPRODFILIAL.PROIBIDAVENDA%TYPE;
   VSREVENDA                    PCPRODFILIAL.REVENDA%TYPE;
   VSCHECARMULTIPLOVENDABNF     PCPRODFILIAL.CHECARMULTIPLOVENDABNF%TYPE;
   VSACEITAVENDAFRACAO          PCPRODFILIAL.ACEITAVENDAFRACAO%TYPE;
   VSCLASSE                     PCPRODFILIAL.CLASSE%TYPE;
   VNCODDESCFLEX                PCDESCONTO.CODDESCONTO%TYPE;
   VSAPLICADESCONTO             PCDESCONTO.APLICADESCONTO%TYPE;
   VSRETIROUIMPOSTO             BOOLEAN;
   VNPTABELACESTASEMIMPOSTO     PCPEDI.PTABELA%TYPE;
   VBCALCULOSEMIMPOSTO          BOOLEAN;
   VNPTABELASEMIMPOSTO          PCPEDI.PTABELA%TYPE;
   VNPBASERCA                   PCPEDI.PBASERCA%TYPE;
   VSMENSAGEMPRECOSEMIMPOSTO    VARCHAR2(1000);
   VNPVENDASEMIMPOSTO           NUMBER;
   VNPRECOMINIMOVENDASEMIMPOSTO NUMBER;
   VSCONSIDERARIPIALIQICMS2 VARCHAR2(1);
   VNPVENDA             PCPEDI.PVENDA%TYPE;
   VNPTABELA            PCPEDI.PTABELA%TYPE;
   VN_PBASERCA          PCPEDI.PBASERCA%TYPE;
   VNVLST               PCPEDI.ST%TYPE;
   vnVLFECP             PCPEDI.VLFECP%TYPE;
   VBCALCULASTVALIDO    BOOLEAN;
   VNBASEICST           PCPEDI.BASEICST%TYPE;
   VNVLIPI              PCPEDI.VLIPI%TYPE;
   VNPERCIPI            PCPEDI.PERCIPI%TYPE;
   VSUFFILIALNF         PCFILIAL.UF%TYPE;
   VSMENSAGEM_ST        VARCHAR2(100);
   VNPVENDAORIG         PCPEDI.PVENDA%TYPE;
   VNVLDIFST201         PCPEDI.ST%TYPE;
   VNPERCIMPOSTOPTABELA NUMBER(18, 6);
   vnCALCULAR_PVENDA_SEM_IMPOSTO PCPEDI.PVENDA%TYPE;
BEGIN
   P_REGITEM.VALIDO := TRUE;
   VSMENSAGEM       := NULL;
   P_REGITEM.RETIRAIMP        := 'S';
   P_REGITEM.PVENDASEMIMPOSTO := NULL;
   VSRETIROUIMPOSTO           := FALSE;
   VNPVENDAORIG := P_REGITEM.PVENDA;
   VNVLDIFST201 := 0;
   P_REGORIGEMPRECO.VALIDO := TRUE;
   P_REGORIGEMPRECO.NUMPED := P_REGPEDIDO.NUMPED;
   P_REGORIGEMCOMISS.NUMPED                 := P_REGPEDIDO.NUMPED;
   P_REGORIGEMCOMISS.CODCLI                 := P_REGPEDIDO.CODCLI;
   P_REGORIGEMCOMISS.CODCOB                 := P_REGPEDIDO.CODCOB;
   P_REGORIGEMCOMISS.TIPOVEND               := P_REGRCA.TIPOVEND;
   P_REGORIGEMCOMISS.TIPOAVALIACAOCOMISSAO  := P_REGFILIAL.TIPOAVALIACAOCOMISSAO;
   P_REGORIGEMCOMISS.CONSIDERARCOMISSAOZERO := P_REGFILIAL.CONSIDERARCOMISSAOZERO;
   P_REGORIGEMDESC.NUMPED                      := P_REGPEDIDO.NUMPED;
   P_REGORIGEMDESC.PEMBALAGEM                  := 'N';
   P_REGORIGEMDESC.VALIDARPOLITICASDESCCLIBLOQ := P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ;
   P_REGORIGEMDESC.PRECOFIXO                   := 'N';
   P_REGORIGEMDESC.PRIORITARIAGERAL            := 'N';

   IF P_REGPEDIDO.CONDVENDA = 7 AND P_REGITEM.TIPOENTREGA IS NOT NULL AND
      P_REGITEM.TIPOENTREGA NOT IN ('RI', 'RP', 'EN', 'EF') THEN
      IF VSMENSAGEM IS NOT NULL THEN
         VSCHAR := '#';
      ELSE
         VSCHAR := NULL;
      END IF;
      
      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'TIPO DE ENTREGA INVALIDO;';
      P_REGITEM.TIPOENTREGA := NULL;
   END IF;

   -- verificar se o produto esta cadastrado
   SELECT COUNT(*)
   INTO VICONTADOR
   FROM PCPRODUT
   WHERE CODPROD = P_REGITEM.CODPROD;

   IF VICONTADOR = 0 THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto nao cadastrado;';
      P_REGITEM.VALIDO        := FALSE;
      P_REGORIGEMPRECO.VALIDO := FALSE;
      P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 97;
   ELSE
      SELECT CODCATEGORIA,
             CODEPTO,
             PCPRODUT.CODFORNEC,
             CODPROD,
             CODSEC,
             DESCRICAO,
             EMBALAGEM,
             PCPRODUT.OBS,
             PCPRODUT.OBS2,
             PCOMEXT1,
             PCOMINT1,
             PCOMREP1,
             NVL(PESOBRUTO, 0),
             0,
             QTUNIT,
             NVL(VOLUME, 0),
             CODPRODPRINC,
             CODLINHAPROD,
             NVL(PCPRODUT.CODDISTRIB, NVL(PCFORNEC.CODDISTRIB, '')) CODDISTRIB,
             PCPRODUT.FRETEESPECIAL,
             PCPRODUT.CLASSE,
             PCPRODUT.PERCIPIVENDA,
             NVL(PCPRODUT.PRAZOMEDIOVENDA, 0),
             PCPRODUT.IMPORTADO,
             NVL(PCPRODUT.PERCIPIVENDATAB, 0),
             NVL(PCPRODUT.VLPAUTAIPIVENDA, 0),
             NVL(PCPRODUT.VLPAUTAIPIVENDATAB, 0),
             NVL(PCPRODUT.VLIPIPORKGVENDA, 0),
             NVL(PCPRODUT.VLIPIPORKGVENDATAB, 0),
             PCPRODUT.TIPOCOMISSAO,
             PCPRODUT.PRECOMAXCONSUM,
             PCPRODUT.TIPOMERC,
             PCPRODUT.CODSUBCATEGORIA,
             NVL(PCPRODUT.CONTROLADOIBAMA, 'N'),
             NVL(PCPRODUT.MULTIPLO, 0),
             PCPRODUT.CHECARMULTIPLOVENDABNF,
             PCPRODUT.ACEITAVENDAFRACAO,
             0,
             PCPRODUT.REVENDA
      INTO P_REGPRODUTO
      FROM PCPRODUT, PCFORNEC
      WHERE CODPROD = P_REGITEM.CODPROD
        AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC;
   END IF;

   BEGIN
      SELECT NVL(P.MULTIPLO, 0),
             NVL(QTMAXPEDVENDA, 0),
             NVL(P.PROIBIDAVENDA, 'N'),
             P.REVENDA,
             P.CHECARMULTIPLOVENDABNF,
             P.ACEITAVENDAFRACAO,
             P.CLASSE
      INTO VNMULTIPLO,
           VNQTMAXPEDVENDA,
           VSPROIBIDAVENDA,
           VSREVENDA,
           VSCHECARMULTIPLOVENDABNF,
           VSACEITAVENDAFRACAO,
           VSCLASSE
      FROM PCPRODFILIAL P
      WHERE CODFILIAL = P_REGPEDIDO.CODFILIAL
        AND CODPROD = P_REGITEM.CODPROD;
   EXCEPTION WHEN OTHERS THEN
      VNMULTIPLO               := 0;
      VNQTMAXPEDVENDA          := 0;
      VSPROIBIDAVENDA          := 'N';
      VSREVENDA                := NULL;
      VSCHECARMULTIPLOVENDABNF := NULL;
      VSCLASSE                 := NULL;
   END;

   IF VNMULTIPLO <> 0 THEN
      P_REGPRODUTO.MULTIPLO := VNMULTIPLO;
   END IF;

   P_REGPRODUTO.CHECARMULTIPLOVENDABNF := NVL(VSCHECARMULTIPLOVENDABNF, P_REGPRODUTO.CHECARMULTIPLOVENDABNF);
   P_REGPRODUTO.ACEITAVENDAFRACAO      := NVL(VSACEITAVENDAFRACAO, P_REGPRODUTO.ACEITAVENDAFRACAO);
   P_REGPRODUTO.CLASSE                 := NVL(VSCLASSE, P_REGPRODUTO.CLASSE);

   IF P_REGITEM.TIPOINTEGRACAO <> 'W' THEN
      IF (P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' OR
          P_REGFILIAL.PRECOPOREMBALAGEM = 'S') AND
         NVL(P_REGITEM.CODAUXILIAR, 0) = 0 THEN
         IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
         ELSE
            VSCHAR := NULL;
         END IF;

         VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                       'Filial parametrizada para trabalhar com embalagem, não aceita codauxiliar nulo ou zero;';
         P_REGITEM.VALIDO := FALSE;
         P_REGORIGEMPRECO.VALIDO := FALSE;
         P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 118;
      END IF;
   END IF;

   IF NVL(P_REGPLPAG.PERTXFIM,0) > 0 THEN
      P_REGORIGEMPRECO.PERCPLPAG := P_REGPLPAG.PERTXFIM;
      P_REGORIGEMDESC.PERTXFIM   := P_REGPLPAG.PERTXFIM;
   END IF;

   P_REGORIGEMPRECO.NUMREGIAO   := P_REGREGIAO.NUMREGIAO;
   P_REGORIGEMPRECO.COLUNAPRECO := P_REGPLPAG.NUMPR;
   P_REGORIGEMPRECO.CODFILIALNF := P_REGPEDIDO.CODFILIALNF;
   P_REGORIGEMPRECO.ORIGEMPRECO := '1';
   P_REGORIGEMCOMISS.CODPLPAG  := P_REGPEDIDO.CODPLPAG;
   P_REGORIGEMCOMISS.TIPOVENDA := P_REGPLPAG.TIPOVENDA;
   P_REGORIGEMCOMISS.NUMREGIAO := P_REGREGIAO.NUMREGIAO;

   IF P_REGITEM.VALIDO = TRUE THEN
      IF P_REGPRODUTO.TIPOMERC = 'CB' THEN
        P_REGITEM.CESTA := 'S';
      ELSE
        P_REGITEM.CESTA := 'N';
      END IF;

      IF P_REGPRODUTO.PRAZOMEDIOVENDA > 0 THEN
        IF P_REGPLPAG.NUMDIAS > P_REGPRODUTO.PRAZOMEDIOVENDA THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                        'Produto nao pode ser vendido nesse# Plano de Pagamento.#
                         Numero de dias medio do cadastro# do produto, inferior ao do Plano Pagto;';

          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 98;

          IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
            P_REGPEDIDO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
            P_REGPEDIDO.POSICAO := 'B';
            IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
              P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) ||
                                 'Produto nao pode ser vendido nesse Plano de Pagamento. Numero de dias medio do cadastro do produto inferior ao do Plano';
            END IF;

            P_REGPEDIDO.MOTIVOPOSICAO := 'Prazo medio do produto inferior ao do Plano.Codprod :' || P_REGITEM.CODPROD;

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          END IF;
        END IF;
      END IF;

      IF NVL(GREGPCCONSUM.PEDIDOPORDISTRIB, 'N') = 'S' THEN
        IF P_REGPRODUTO.CODDISTRIB <> VSCODDISTRIB THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Item nao pertence a mesma distribuicao;';
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 99;

          IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
            P_REGPEDIDO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
            P_REGPEDIDO.POSICAO := 'B';

            IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
              P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Item nao pertence a mesma distribuicao';
            END IF;

            P_REGPEDIDO.MOTIVOPOSICAO := 'Item nao pertence a mesma distribuicao.Codprod :' || P_REGITEM.CODPROD;

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          END IF;
        END IF;
      END IF;
      -- verifica se produto esta proibido para venda
      IF VSPROIBIDAVENDA = 'S' OR
         (VSPROIBIDAVENDA = 'N' AND (P_REGPRODUTO.OBS = 'PV')) THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Proibida a venda do produto;';
        P_REGITEM.VALIDO        := FALSE;
        P_REGORIGEMPRECO.VALIDO := FALSE;
        P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 100;
      END IF;

      IF P_REGPRODUTO.CONTROLADOIBAMA = 'S' THEN
        IF TRIM(P_REGCLIENTE.REGISTROIBAMA) IS NOT NULL THEN
          IF P_REGCLIENTE.DTVALIDADEIBAMA < TRUNC(SYSDATE) OR
             P_REGCLIENTE.DTVALIDADEIBAMA IS NULL THEN

            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Item controlado ibama e dt validade do cliente expirou ou está nula';
            P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 119;

            IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
              P_REGITEM.VALIDO        := FALSE;
              P_REGORIGEMPRECO.VALIDO := FALSE;
            ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
              P_REGPEDIDO.VALIDO := FALSE;
            ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
              P_REGPEDIDO.POSICAO := 'B';

              IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
                P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Item controlado ibama e dt validade do cliente expirou ou está nula';
              END IF;

              P_REGPEDIDO.MOTIVOPOSICAO := 'Item controlado ibama, dtvalidade expirada ou nula :' || P_REGITEM.CODPROD;

              IF P_REGPEDIDO.POSICAO = 'B' THEN
                 PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
              END IF;
            END IF;
          END IF;
        ELSE
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Item controlado pelo ibama e cliente sem registro';
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 120;

          IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
            P_REGPEDIDO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
            P_REGPEDIDO.POSICAO := 'B';

            IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
              P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Item controlado pelo ibama e cliente sem registro';
            END IF;

            P_REGPEDIDO.MOTIVOPOSICAO := 'Item controlado pelo ibama e cliente sem registro :' || P_REGITEM.CODPROD;

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          END IF;
        END IF;
      END IF;

      SELECT COUNT(*)
        INTO VICOTARCA
        FROM PCPRODUSUR P
       WHERE P.DATAINICIO <= TRUNC(SYSDATE)
         AND P.DATAFIM >= TRUNC(SYSDATE)
         AND P.CODPROD = P_REGITEM.CODPROD
         AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
         AND P.CODUSUR = P_REGPEDIDO.CODUSUR
         AND P.TIPOCOTA = 'U';

      IF VICOTARCA > 0 THEN
        VBVALIDOCOTARCA := FUNCOESVENDAS.VERIFICARCOTARCA(P_REGITEM.CODPROD,
                                                          P_REGPEDIDO.CODUSUR,
                                                          P_REGITEM.QT,
                                                          P_REGREGIAO.NUMREGIAO,
                                                          VSMENSAGEMCOTARCA);
        IF VBVALIDOCOTARCA = FALSE THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMCOTARCA;
        END IF;

        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
          P_REGPEDIDO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
          P_REGPEDIDO.POSICAO := 'B';

          IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
            P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Produto excede quantidade da cota do rca';
          END IF;

          P_REGPEDIDO.MOTIVOPOSICAO := 'Item excede cota do rca. Codprod:' || P_REGITEM.CODPROD;

          IF P_REGPEDIDO.POSICAO = 'B' THEN
             PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        END IF;

        P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 159;
      END IF;

      SELECT COUNT(*)
        INTO VICOTACLI
        FROM PCPRODUSUR P
       WHERE P.DATAINICIO <= TRUNC(SYSDATE)
         AND P.DATAFIM >= TRUNC(SYSDATE)
         AND P.CODPROD = P_REGITEM.CODPROD
         AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
         AND P.CODUSUR IS NULL
         AND P.CODCLI = P_REGPEDIDO.CODCLI
         AND P.TIPOCOTA = 'C';

      IF VICOTACLI > 0 THEN
        VBVALIDOCOTACLI := FUNCOESVENDAS.VERIFICARCOTACLIENTE(P_REGITEM.CODPROD,
                                                              P_REGPEDIDO.CODCLI,
                                                              P_REGITEM.QT,
                                                              P_REGREGIAO.NUMREGIAO,
                                                              VSMENSAGEMCOTACLI);
        IF VBVALIDOCOTACLI = FALSE THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMCOTACLI;
        END IF;

        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
          P_REGPEDIDO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
          P_REGPEDIDO.POSICAO := 'B';

          IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
            P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Produto excede quantidade da cota do cliente';
          END IF;

          P_REGPEDIDO.MOTIVOPOSICAO := 'Item excede cota de cliente.Codprod:' || P_REGITEM.CODPROD;

          IF P_REGPEDIDO.POSICAO = 'B' THEN
             PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        END IF;

        P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 158;
      END IF;

      VBEXISTEPCPLPAGRESTRICAO := FUNCOESVENDAS.VALIDARPCPLPAGRESTRICAO(P_REGPEDIDO.CODPLPAG,
                                                                        P_REGITEM.CODPROD,
                                                                        NULL,
                                                                        NULL,
                                                                        P_REGPRODUTO.CODFORNEC,
                                                                        P_REGPRODUTO.CODEPTO,
                                                                        NULL,
                                                                        P_REGPRODUTO.CODSEC,
                                                                        NULL,
                                                                        NULL,
                                                                        NULL,
                                                                        VSMENSAGEMPCPLPAGRESTRICAO,
                                                                        P_REGPRODUTO.CODCATEGORIA,
                                                                        P_REGPRODUTO.CODSUBCATEGORIA);
      IF VBEXISTEPCPLPAGRESTRICAO = TRUE THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMPCPLPAGRESTRICAO || ';';

        IF INSTR(UPPER(VSMENSAGEMPCPLPAGRESTRICAO), 'FORNECEDOR') > 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 83;
        ELSIF INSTR(UPPER(VSMENSAGEMPCPLPAGRESTRICAO), 'DEPARTAMENTO') > 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 101;
        ELSIF INSTR(UPPER(VSMENSAGEMPCPLPAGRESTRICAO), 'SUB') > 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 86;
        ELSIF INSTR(UPPER(VSMENSAGEMPCPLPAGRESTRICAO), 'CATEGORIA') > 0 AND
              INSTR(UPPER(VSMENSAGEMPCPLPAGRESTRICAO), 'SUB') = 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 85;
        ELSIF INSTR(UPPER(VSMENSAGEMPCPLPAGRESTRICAO), 'ERRO') > 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 102;
        ELSE
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 84;
        END IF;

        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
          P_REGPEDIDO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
          P_REGPEDIDO.POSICAO := 'B';

          IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
            P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Produto com restricao para venda neste plano de pagamento';
          END IF;

          P_REGPEDIDO.MOTIVOPOSICAO := 'Item com restricao para venda neste Plano.Codprod:' || P_REGITEM.CODPROD;

          IF P_REGPEDIDO.POSICAO = 'B' THEN
             PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        END IF;
      END IF;

      IF FUNCOESVENDAS.VALIDARRESTRICAOVENDA(P_REGITEM.CODPROD,
                                             P_REGREGIAO.NUMREGIAO,
                                             P_REGPEDIDO.CODCLI,
                                             P_REGPEDIDO.CODUSUR,
                                             P_REGPRODUTO.CODFORNEC,
                                             P_REGCLIENTE.CODPRACA,
                                             P_REGPRODUTO.CLASSE,
                                             P_REGCLIENTE.CODATV1,
                                             P_REGRCA.CODSUPERVISOR,
                                             VSMENSAGEM_REST,
                                             P_REGPEDIDO.CODFILIAL,
                                             P_REGPEDIDO.CONDVENDA,
                                             P_REGPEDIDO.FRETEDESPACHO,
                                             P_REGPEDIDO.ORIGEMPED,
                                             P_REGITEM.CODAUXILIAR,
                                             P_REGPEDIDO.CODPLPAG,
                                             P_REGPEDIDO.CODCOB) = FALSE THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEM_REST;

        IF INSTR(UPPER(VSMENSAGEM_REST), 'ERRO') > 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 88;
        ELSE
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 140;
        END IF;

        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
          P_REGPEDIDO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
          P_REGPEDIDO.POSICAO := 'B';

          IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
            P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || VSMENSAGEM_REST;
          END IF;

          P_REGPEDIDO.MOTIVOPOSICAO := SUBSTR(VSMENSAGEM_REST, 1, 45) || 'Codprod :' || P_REGITEM.CODPROD;

          IF P_REGPEDIDO.POSICAO = 'B' THEN
             PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        END IF;
      END IF;

      IF FUNCOESVENDAS.VALIDARRESTRICAODEPTOSECFORN(P_REGPRODUTO.CODSEC,
                                                    P_REGPRODUTO.CODEPTO,
                                                    P_REGPEDIDO.CODUSUR,
                                                    P_REGPRODUTO.CODFORNEC,
                                                    VSMENSAGEM_REST) = FALSE THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEM_REST;

        IF INSTR(UPPER(VSMENSAGEM_REST), 'DEPARTAMENTO') > 0 THEN
          P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 89;
        ELSE
          IF INSTR(UPPER(VSMENSAGEM_REST), 'ERRO') > 0 THEN
            P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 91;
          ELSE
            P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 90;
          END IF;
        END IF;

        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
          P_REGPEDIDO.VALIDO := FALSE;
        ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
          P_REGPEDIDO.POSICAO := 'B';

          IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
            P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || VSMENSAGEM_REST;
          END IF;

          P_REGPEDIDO.MOTIVOPOSICAO := SUBSTR(VSMENSAGEM_REST, 1, 45) || 'Codprod :' || P_REGITEM.CODPROD;

          IF P_REGPEDIDO.POSICAO = 'B' THEN
             PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        END IF;
      END IF;

      IF P_REGITEM.TIPOINTEGRACAO <> 'W' THEN
        IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN
          IF P_REGITEM.CODAUXILIAR = 0 OR P_REGITEM.CODAUXILIAR IS NULL THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'CODAUXILIAR INVALIDO' || ';';

            P_REGITEM.VALIDO      := FALSE;
            P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 87;
          ELSE
            SELECT COUNT(*)
              INTO VICONTADOR
              FROM PCEMBALAGEM P
             WHERE CODPROD = P_REGITEM.CODPROD
               AND CODFILIAL = P_REGPEDIDO.CODFILIAL
               AND CODAUXILIAR = P_REGITEM.CODAUXILIAR;

            IF VICONTADOR = 0 THEN
              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;

              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PRODUTO NAO ENCONTRADO COM ESTE CODAUXILIAR' || ';';

              P_REGITEM.VALIDO      := FALSE;
              P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 121;
            END IF;
          END IF;
        END IF;
      END IF;
      IF P_REGPRODUTO.TIPOMERC = 'CB' THEN
        -- busca as informacoes da tabela de preco.
        BEGIN
          SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
                 NVL(PCTRIBUT.ALIQICMS2, 0),
                 NVL(PCTRIBUT.CODICMTAB, 0),
                 PCTABPR.CODST,
                 NVL(PCEST.CUSTOCONT, 0),
                 NVL(PCEST.CUSTOFIN, 0),
                 NVL(PCEST.CUSTOREAL, 0),
                 NVL(PCEST.CUSTOREP, 0),
                 NVL(PCEST.CUSTOULTENT, 0),
                 NVL(PCTABPR.EXCLUIDO, 'N'),
                 NVL(PCTRIBUT.IVA, 0),
                 NVL(PCTRIBUT.PAUTA, 0),
                 NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                 NVL(PCTABPR.PERDESCAUTOR, 0),
                 NVL(PCTRIBUT.PERDESCCUSTO, 0),
                 NVL(PCTABPR.PERDESCMAX, 0),
                 NVL(PCTABPR.PERDESCMAXESP, 0),
                 PCTRIBUT.PERDESTAB,
                 NVL(PCTABPR.PRECOMINIMOVENDA, 0),
                 ROUND(NVL(PCTABPR.PVENDA, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDA7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 NVL(PCTABPR.QTDESCAUTOR, 0),
                 NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                 NVL(PCTRIBUT.PERCBASEREDST, 0),
                 NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
                 NVL(PCTRIBUT.IVAFONTE, 0),
                 NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                 NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                 NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                 NVL(PCTRIBUT.PERCBASERED, 0),
                 NVL(PCTRIBUT.PERBASEREDNRPA, 0),
                 NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                 NVL(UTILIZAPERCBASEREDPF, 'N'),
                 NVL(PCEST.VALORULTENT, 0),
                 NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
                 NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
                 NVL(PCTRIBUT.CODICMTABPF, 0),
                 NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
                 NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
                 PCTABPR.DESCONTAFRETE,
                 NVL(PCTRIBUT.PERCDESCPIS, 0),
                 NVL(PCTRIBUT.PERCDESCCOFINS, 0),
                 NVL(PCTRIBUT.PERDESCREPASSE, 0),
                 NVL(PCTABPR.PRECOMAXCONSUM, 0),
                 1, --nvl(pcembalagem.qtunit,1),
                 1, --nvl(pcembalagem.fatorpreco,1),
                 0, --nvl(pcembalagem.qtminimaatacado,0),
                 0, --(pcembalagem.pvendaatac,0),
                 0, --nvl(pcembalagem.pvenda,0),
                 0, --nvl(pcembalagem.poferta,0),
                 ROUND(NVL(PCTABPR.PVENDAATAC1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATAC2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATAC3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATAC4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATAC5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATAC6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATAC7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 NULL, --pcembalagem.dtofertaini,
                 NULL, --pcembalagem.dtofertafim,
                 NULL, --pcembalagem.dtofertaatacini,
                 NULL, --pcembalagem.dtofertaatacfim,
                 0, --nvl(pcembalagem.pofertaatac,0),
                 NVL(PCTRIBUT.MOSTRARPVENDASEMST, GREGPCCONSUM.MOSTRARPVENDASEMST),
                 NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                 NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
                 NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
                 NVL(PCEST.VLSTULTENT, 0),
                 NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
                 NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
                 NVL(PCEST.IVAULTENT, 0),
                 NVL(PCEST.ALIQICMS1ULTENT, 0),
                 NVL(PCEST.ALIQICMS2ULTENT, 0),
                 NVL(PCEST.REDBASEIVAULTENT, 100),
                 NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
                 NVL(PCEST.VLFRETECONHECULTENT, 0),
                 NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
                 NVL(PCEST.BASEICMSULTENT, 0),
                 NVL(PCEST.VLSTGUIAULTENT, 0),
                 NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
                 PCTRIBUT.PAGTONOMEDOCLIENTE,
                 NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                 PCTABPR.PRECOFAB,
                 NULL,
                 NULL,
                 NULL,
                 NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                 NVL(PCTABPR.VLULTENTMES, 0),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 NVL(PCTRIBUT.PERCBASESTRJ, 0),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                 NVL(PCTRIBUT.USAALIQICMSSIMPLESNACIONAL, 'N'),
                 NVL(PCTRIBUT.ALIQSTSIMPLESNACIONAL, 0),
                 NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                 NVL(PCTABPR.VLST, 0)
            INTO P_REGPRECOS
            FROM PCTABPR, PCTRIBUT, PCEST
           WHERE PCTABPR.CODST = PCTRIBUT.CODST(+)
             AND PCEST.CODPROD = PCTABPR.CODPROD(+)
             AND PCEST.CODPROD = P_REGITEM.CODPROD
             AND P_REGREGIAO.NUMREGIAO = PCTABPR.NUMREGIAO(+)
             AND PCEST.CODFILIAL = DECODE(P_REGFILIAL.ORIGEMCUSTOFILIALRETIRA, 'F', P_REGITEM.CODFILIALRETIRA, P_REGPEDIDO.CODFILIAL);
        EXCEPTION
          WHEN OTHERS THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Erro ao buscar preco do produto#;' ||
                          SQLCODE || '-' || SQLERRM || ';';
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
            P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 104;
        END;
      ELSE
        --não é cesta
        IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' AND P_REGITEM.TIPOINTEGRACAO <> 'W' THEN
          --tributacao por estado
          IF NVL(GREGPCCONSUM.USATRIBUTACAOPORUF, 'N') = 'S' THEN
            P_REGORIGEMPRECO.USATRIBUTPORUF := 'S';

            IF P_REGPEDIDO.CODFILIALNF IS NULL THEN
              IF P_REGCLIENTE.CODFILIALNF IS NULL THEN
                VSCODFILIALNF := P_REGPEDIDO.CODFILIAL;
              ELSE
                VSCODFILIALNF := P_REGCLIENTE.CODFILIALNF;
              END IF;
            ELSE
              VSCODFILIALNF := P_REGPEDIDO.CODFILIALNF;
            END IF;

            SELECT COUNT(*)
              INTO VICONTADOR
              FROM PCTABTRIB P
             WHERE P.CODPROD = P_REGITEM.CODPROD
               AND P.CODFILIALNF = VSCODFILIALNF
               AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

            IF VICONTADOR = 0 THEN
              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;

              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

              P_REGITEM.VALIDO        := FALSE;
              P_REGORIGEMPRECO.VALIDO := FALSE;
              P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 122;
            ELSE
              SELECT P.CODST
                INTO VNCODST
                FROM PCTABTRIB P
               WHERE P.CODPROD = P_REGITEM.CODPROD
                 AND P.CODFILIALNF = VSCODFILIALNF
                 AND P.UFDESTINO = P_REGCLIENTE.ESTENT
                 AND ROWNUM = 1;

              -- busca as informacoes da tabela de preco.
              BEGIN
                SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
                       NVL(PCTRIBUT.ALIQICMS2, 0),
                       NVL(PCTRIBUT.CODICMTAB, 0),
                       PCTRIBUT.CODST,
                       NVL(PCEST.CUSTOCONT, 0),
                       NVL(PCEST.CUSTOFIN, 0),
                       NVL(PCEST.CUSTOREAL, 0),
                       NVL(PCEST.CUSTOREP, 0),
                       NVL(PCEST.CUSTOULTENT, 0),
                       NVL(PCTABPR.EXCLUIDO, 'N'),
                       NVL(PCTRIBUT.IVA, 0),
                       NVL(PCTRIBUT.PAUTA, 0),
                       NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                       NVL(PCTABPR.PERDESCAUTOR, 0),
                       NVL(PCTRIBUT.PERDESCCUSTO, 0),
                       NVL(PCTABPR.PERDESCMAX, 0),
                       NVL(PCTABPR.PERDESCMAXESP, 0),
                       PCTRIBUT.PERDESTAB,
                       NVL(PCTABPR.PRECOMINIMOVENDA, 0),
                       (ROUND(NVL(PCTABPR.PVENDA, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA1, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA2, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA3, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA4, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA5, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA6, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (ROUND(NVL(PCTABPR.PVENDA7, 0),
                              GREGPCCONSUM.NUMCASASDECVENDA) *
                        DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       NVL(PCTABPR.QTDESCAUTOR, 0),
                       NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                       NVL(PCTRIBUT.PERCBASEREDST, 0),
                       NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
                       NVL(PCTRIBUT.IVAFONTE, 0),
                       NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                       NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                       NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                       NVL(PCTRIBUT.PERCBASERED, 0),
                       NVL(PCTRIBUT.PERBASEREDNRPA, 0),
                       NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                       NVL(UTILIZAPERCBASEREDPF, 'N'),
                       NVL(PCEST.VALORULTENT, 0),
                       NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
                       NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
                       NVL(PCTRIBUT.CODICMTABPF, 0),
                       NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
                       NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
                       PCTABPR.DESCONTAFRETE,
                       NVL(PCTRIBUT.PERCDESCPIS, 0),
                       NVL(PCTRIBUT.PERCDESCCOFINS, 0),
                       NVL(PCTRIBUT.PERDESCREPASSE, 0),
                       NVL(PCTABPR.PRECOMAXCONSUM, 0),
                       NVL(PCEMBALAGEM.QTUNIT, 1),
                       DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                              NVL(PCEMBALAGEM.FATORPRECO, 1)),
                       NVL(PCEMBALAGEM.QTMINIMAATACADO, 0),
                       (DECODE(NVL(PCEMBALAGEM.PVENDAATAC, 0), 0,
                               NVL(PCEMBALAGEM.PVENDA, 0),
                               NVL(PCEMBALAGEM.PVENDAATAC, 0)) *
                       DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (NVL(PCEMBALAGEM.PVENDA, 0) *
                       DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       (NVL(PCEMBALAGEM.POFERTA, 0) *
                       DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                               NVL(PCEMBALAGEM.FATORPRECO, 1))),
                       ROUND(NVL(PCTABPR.PVENDAATAC1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATAC2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATAC3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATAC4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATAC5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATAC6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATAC7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       PCEMBALAGEM.DTOFERTAINI,
                       PCEMBALAGEM.DTOFERTAFIM,
                       PCEMBALAGEM.DTOFERTAATACINI,
                       PCEMBALAGEM.DTOFERTAATACFIM,
                       NVL(PCEMBALAGEM.POFERTAATAC, 0),
                       NVL(PCTRIBUT.MOSTRARPVENDASEMST, GREGPCCONSUM.MOSTRARPVENDASEMST),
                       NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                       NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
                       NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
                       NVL(PCEST.VLSTULTENT, 0),
                       NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
                       NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
                       NVL(PCEST.IVAULTENT, 0),
                       NVL(PCEST.ALIQICMS1ULTENT, 0),
                       NVL(PCEST.ALIQICMS2ULTENT, 0),
                       NVL(PCEST.REDBASEIVAULTENT, 100),
                       NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
                       NVL(PCEST.VLFRETECONHECULTENT, 0),
                       NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
                       NVL(PCEST.BASEICMSULTENT, 0),
                       NVL(PCEST.VLSTGUIAULTENT, 0),
                       NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
                       PCTRIBUT.PAGTONOMEDOCLIENTE,
                       NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                       PCTABPR.PRECOFAB,
                       PCEMBALAGEM.PCOMINT1,
                       PCEMBALAGEM.PCOMEXT1,
                       PCEMBALAGEM.PCOMREP1,
                       NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                       NVL(PCTABPR.VLULTENTMES, 0),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       NVL(PCTRIBUT.PERCBASESTRJ, 0),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       NVL(PCTRIBUT.USAALIQICMSSIMPLESNACIONAL, 'N'),
                       NVL(PCTRIBUT.ALIQSTSIMPLESNACIONAL, 0),
                       NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                       NVL(PCTABPR.VLST, 0)
                  INTO P_REGPRECOS
                  FROM PCTABPR, PCTRIBUT, PCEST, PCEMBALAGEM
                 WHERE PCTRIBUT.CODST = VNCODST
                   AND PCTABPR.CODPROD = P_REGITEM.CODPROD
                   AND PCEST.CODPROD = P_REGITEM.CODPROD
                   AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
                   AND PCEST.CODFILIAL = DECODE(P_REGFILIAL.ORIGEMCUSTOFILIALRETIRA, 'V', P_REGPEDIDO.CODFILIAL,
                                                NVL(P_REGITEM.CODFILIALRETIRA, P_REGPEDIDO.CODFILIAL))
                   AND PCEMBALAGEM.CODPROD = P_REGITEM.CODPROD
                   AND PCEMBALAGEM.CODAUXILIAR = P_REGITEM.CODAUXILIAR
                   AND PCEMBALAGEM.CODFILIAL = P_REGPEDIDO.CODFILIAL;
              EXCEPTION
                WHEN OTHERS THEN
                  IF VSMENSAGEM IS NOT NULL THEN
                    VSCHAR := '#';
                  ELSE
                    VSCHAR := NULL;
                  END IF;

                  VSMENSAGEM := VSMENSAGEM || VSCHAR || 'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
                                SQLCODE || '-' || SQLERRM || ';';
                  P_REGITEM.VALIDO        := FALSE;
                  P_REGORIGEMPRECO.VALIDO := FALSE;
                  P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 104;
              END;
              
              IF NVL(P_REGPRECOS.QTUNIT,0) <> 0 THEN
                 P_REGITEM.PVENDA := ROUND(P_REGITEM.PVENDA / P_REGPRECOS.QTUNIT, GREGPCCONSUM.NUMCASASDECVENDA);
              ELSE
                 P_REGITEM.PVENDA := ROUND(0, GREGPCCONSUM.NUMCASASDECVENDA);
              END IF;

              P_REGITEM.QT := P_REGITEM.QT * P_REGPRECOS.QTUNIT;
            END IF;
            --não usa tributação por estado
          ELSE
            -- busca as informacoes da tabela de preco.
            BEGIN
              SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
                     NVL(PCTRIBUT.ALIQICMS2, 0),
                     NVL(PCTRIBUT.CODICMTAB, 0),
                     PCTABPR.CODST,
                     NVL(PCEST.CUSTOCONT, 0),
                     NVL(PCEST.CUSTOFIN, 0),
                     NVL(PCEST.CUSTOREAL, 0),
                     NVL(PCEST.CUSTOREP, 0),
                     NVL(PCEST.CUSTOULTENT, 0),
                     NVL(PCTABPR.EXCLUIDO, 'N'),
                     NVL(PCTRIBUT.IVA, 0),
                     NVL(PCTRIBUT.PAUTA, 0),
                     NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                     NVL(PCTABPR.PERDESCAUTOR, 0),
                     NVL(PCTRIBUT.PERDESCCUSTO, 0),
                     NVL(PCTABPR.PERDESCMAX, 0),
                     NVL(PCTABPR.PERDESCMAXESP, 0),
                     PCTRIBUT.PERDESTAB,
                     NVL(PCTABPR.PRECOMINIMOVENDA, 0),
                     (ROUND(NVL(PCTABPR.PVENDA, 0), GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA1, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA2, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA3, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA4, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA5, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA6, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (ROUND(NVL(PCTABPR.PVENDA7, 0),
                            GREGPCCONSUM.NUMCASASDECVENDA) *
                      DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     NVL(PCTABPR.QTDESCAUTOR, 0),
                     NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                     NVL(PERCBASEREDST, 0),
                     NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
                     NVL(PCTRIBUT.IVAFONTE, 0),
                     NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                     NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                     NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                     NVL(PCTRIBUT.PERCBASERED, 0),
                     NVL(PCTRIBUT.PERBASEREDNRPA, 0),
                     NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                     NVL(UTILIZAPERCBASEREDPF, 'N'),
                     NVL(PCEST.VALORULTENT, 0),
                     NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
                     NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
                     NVL(PCTRIBUT.CODICMTABPF, 0),
                     NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
                     NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
                     PCTABPR.DESCONTAFRETE,
                     NVL(PCTRIBUT.PERCDESCPIS, 0),
                     NVL(PCTRIBUT.PERCDESCCOFINS, 0),
                     NVL(PCTRIBUT.PERDESCREPASSE, 0),
                     NVL(PCTABPR.PRECOMAXCONSUM, 0),
                     NVL(PCEMBALAGEM.QTUNIT, 1),
                     DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                            NVL(PCEMBALAGEM.FATORPRECO, 1)),
                     NVL(PCEMBALAGEM.QTMINIMAATACADO, 0),
                     (DECODE(NVL(PCEMBALAGEM.PVENDAATAC, 0), 0,
                             NVL(PCEMBALAGEM.PVENDA, 0),
                             NVL(PCEMBALAGEM.PVENDAATAC, 0)) *
                     DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (NVL(PCEMBALAGEM.PVENDA, 0) *
                     DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     (NVL(PCEMBALAGEM.POFERTA, 0) *
                     DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1), 0, 1,
                             NVL(PCEMBALAGEM.FATORPRECO, 1))),
                     ROUND(NVL(PCTABPR.PVENDAATAC1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATAC2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATAC3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATAC4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATAC5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATAC6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATAC7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     PCEMBALAGEM.DTOFERTAINI,
                     PCEMBALAGEM.DTOFERTAFIM,
                     PCEMBALAGEM.DTOFERTAATACINI,
                     PCEMBALAGEM.DTOFERTAATACFIM,
                     NVL(PCEMBALAGEM.POFERTAATAC, 0),
                     NVL(PCTRIBUT.MOSTRARPVENDASEMST, GREGPCCONSUM.MOSTRARPVENDASEMST),
                     NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                     NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
                     NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
                     NVL(PCEST.VLSTULTENT, 0),
                     NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
                     NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
                     NVL(PCEST.IVAULTENT, 0),
                     NVL(PCEST.ALIQICMS1ULTENT, 0),
                     NVL(PCEST.ALIQICMS2ULTENT, 0),
                     NVL(PCEST.REDBASEIVAULTENT, 100),
                     NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
                     NVL(PCEST.VLFRETECONHECULTENT, 0),
                     NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
                     NVL(PCEST.BASEICMSULTENT, 0),
                     NVL(PCEST.VLSTGUIAULTENT, 0),
                     NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
                     PCTRIBUT.PAGTONOMEDOCLIENTE,
                     NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                     PCTABPR.PRECOFAB,
                     PCEMBALAGEM.PCOMINT1,
                     PCEMBALAGEM.PCOMEXT1,
                     PCEMBALAGEM.PCOMREP1,
                     NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                     NVL(PCTABPR.VLULTENTMES, 0),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     NVL(PCTRIBUT.PERCBASESTRJ, 0),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     NVL(PCTRIBUT.USAALIQICMSSIMPLESNACIONAL, 'N'),
                     NVL(PCTRIBUT.ALIQSTSIMPLESNACIONAL, 0),
                     NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                     NVL(PCTABPR.VLST, 0)
                INTO P_REGPRECOS
                FROM PCTABPR, PCTRIBUT, PCEST, PCEMBALAGEM
               WHERE PCTABPR.CODST = PCTRIBUT.CODST
                 AND PCTABPR.CODPROD = P_REGITEM.CODPROD
                 AND PCEST.CODPROD = P_REGITEM.CODPROD
                 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
                 AND PCEST.CODFILIAL = DECODE(P_REGFILIAL.ORIGEMCUSTOFILIALRETIRA, 'V', P_REGPEDIDO.CODFILIAL,
                                              NVL(P_REGITEM.CODFILIALRETIRA, P_REGPEDIDO.CODFILIAL))
                 AND PCEMBALAGEM.CODPROD = P_REGITEM.CODPROD
                 AND PCEMBALAGEM.CODAUXILIAR = P_REGITEM.CODAUXILIAR
                 AND PCEMBALAGEM.CODFILIAL = P_REGPEDIDO.CODFILIAL;
            EXCEPTION
              WHEN OTHERS THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
                              SQLCODE || '-' || SQLERRM || ';';
                P_REGITEM.VALIDO        := FALSE;
                P_REGORIGEMPRECO.VALIDO := FALSE;
                P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 104;
            END;
            
            IF NVL(P_REGPRECOS.QTUNIT,0) <> 0 THEN
               P_REGITEM.PVENDA := ROUND(P_REGITEM.PVENDA / P_REGPRECOS.QTUNIT, GREGPCCONSUM.NUMCASASDECVENDA);
            ELSE
               P_REGITEM.PVENDA := ROUND(0, GREGPCCONSUM.NUMCASASDECVENDA);
            END IF;
               
            P_REGITEM.QT := P_REGITEM.QT * P_REGPRECOS.QTUNIT;
          END IF;
          --não usa venda por embalagem
        ELSE
          --tributacao por estado
          IF NVL(GREGPCCONSUM.USATRIBUTACAOPORUF, 'N') = 'S' THEN
            P_REGORIGEMPRECO.USATRIBUTPORUF := 'S';

            IF P_REGPEDIDO.CODFILIALNF IS NULL THEN
              IF P_REGCLIENTE.CODFILIALNF IS NULL THEN
                VSCODFILIALNF := P_REGPEDIDO.CODFILIAL;
              ELSE
                VSCODFILIALNF := P_REGCLIENTE.CODFILIALNF;
              END IF;
            ELSE
              VSCODFILIALNF := P_REGPEDIDO.CODFILIALNF;
            END IF;

            SELECT COUNT(*)
              INTO VICONTADOR
              FROM PCTABTRIB P
             WHERE P.CODPROD = P_REGITEM.CODPROD
               AND P.CODFILIALNF = VSCODFILIALNF
               AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

            IF VICONTADOR = 0 THEN
              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;

              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

              P_REGITEM.VALIDO        := FALSE;
              P_REGORIGEMPRECO.VALIDO := FALSE;
              P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 122;
            ELSE
              SELECT P.CODST
                INTO VNCODST
                FROM PCTABTRIB P
               WHERE P.CODPROD = P_REGITEM.CODPROD
                 AND P.CODFILIALNF = VSCODFILIALNF
                 AND P.UFDESTINO = P_REGCLIENTE.ESTENT
                 AND ROWNUM = 1;

              -- busca as informacoes da tabela de preco.
              BEGIN
                SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
                       NVL(PCTRIBUT.ALIQICMS2, 0),
                       NVL(PCTRIBUT.CODICMTAB, 0),
                       PCTRIBUT.CODST,
                       NVL(PCEST.CUSTOCONT, 0),
                       NVL(PCEST.CUSTOFIN, 0),
                       NVL(PCEST.CUSTOREAL, 0),
                       NVL(PCEST.CUSTOREP, 0),
                       NVL(PCEST.CUSTOULTENT, 0),
                       NVL(PCTABPR.EXCLUIDO, 'N'),
                       NVL(PCTRIBUT.IVA, 0),
                       NVL(PCTRIBUT.PAUTA, 0),
                       NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                       NVL(PCTABPR.PERDESCAUTOR, 0),
                       NVL(PCTRIBUT.PERDESCCUSTO, 0),
                       NVL(PCTABPR.PERDESCMAX, 0),
                       NVL(PCTABPR.PERDESCMAXESP, 0),
                       PCTRIBUT.PERDESTAB,
                       NVL(PCTABPR.PRECOMINIMOVENDA, 0),
                       ROUND(NVL(PCTABPR.PVENDA, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDA7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       NVL(PCTABPR.QTDESCAUTOR, 0),
                       NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                       NVL(PCTRIBUT.PERCBASEREDST, 0),
                       NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
                       NVL(PCTRIBUT.IVAFONTE, 0),
                       NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                       NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                       NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                       NVL(PCTRIBUT.PERCBASERED, 0),
                       NVL(PCTRIBUT.PERBASEREDNRPA, 0),
                       NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                       NVL(UTILIZAPERCBASEREDPF, 'N'),
                       NVL(PCEST.VALORULTENT, 0),
                       NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
                       NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
                       NVL(PCTRIBUT.CODICMTABPF, 0),
                       NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
                       NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
                       PCTABPR.DESCONTAFRETE,
                       NVL(PCTRIBUT.PERCDESCPIS, 0),
                       NVL(PCTRIBUT.PERCDESCCOFINS, 0),
                       NVL(PCTRIBUT.PERDESCREPASSE, 0),
                       NVL(PCTABPR.PRECOMAXCONSUM, 0),
                       1,
                       1,
                       0,
                       0,
                       0,
                       0,
                       0,
                       0,
                       0,
                       0,
                       0,
                       0,
                       0,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       0,
                       NVL(PCTRIBUT.MOSTRARPVENDASEMST, GREGPCCONSUM.MOSTRARPVENDASEMST),
                       NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                       NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
                       NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
                       NVL(PCEST.VLSTULTENT, 0),
                       NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
                       NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
                       NVL(PCEST.IVAULTENT, 0),
                       NVL(PCEST.ALIQICMS1ULTENT, 0),
                       NVL(PCEST.ALIQICMS2ULTENT, 0),
                       NVL(PCEST.REDBASEIVAULTENT, 100),
                       NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
                       NVL(PCEST.VLFRETECONHECULTENT, 0),
                       NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
                       NVL(PCEST.BASEICMSULTENT, 0),
                       NVL(PCEST.VLSTGUIAULTENT, 0),
                       NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
                       PCTRIBUT.PAGTONOMEDOCLIENTE,
                       NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                       PCTABPR.PRECOFAB,
                       NULL,
                       NULL,
                       NULL,
                       NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                       NVL(PCTABPR.VLULTENTMES, 0),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       NVL(PCTRIBUT.PERCBASESTRJ, 0),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                       NVL(PCTRIBUT.USAALIQICMSSIMPLESNACIONAL, 'N'),
                       NVL(PCTRIBUT.ALIQSTSIMPLESNACIONAL, 0),
                       NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                       NVL(PCTABPR.VLST, 0)
                  INTO P_REGPRECOS
                  FROM PCTABPR, PCTRIBUT, PCEST
                 WHERE PCTRIBUT.CODST = VNCODST
                   AND PCTABPR.CODPROD = P_REGITEM.CODPROD
                   AND PCEST.CODPROD = P_REGITEM.CODPROD
                   AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
                   AND PCEST.CODFILIAL = DECODE(P_REGFILIAL.ORIGEMCUSTOFILIALRETIRA, 'V', P_REGPEDIDO.CODFILIAL,
                                                NVL(P_REGITEM.CODFILIALRETIRA, P_REGPEDIDO.CODFILIAL));
              EXCEPTION
                WHEN OTHERS THEN
                  IF VSMENSAGEM IS NOT NULL THEN
                    VSCHAR := '#';
                  ELSE
                    VSCHAR := NULL;
                  END IF;

                  VSMENSAGEM := VSMENSAGEM || VSCHAR || 'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
                                SQLCODE || '-' || SQLERRM || ';';
                  P_REGITEM.VALIDO        := FALSE;
                  P_REGORIGEMPRECO.VALIDO := FALSE;
                  P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 104;
              END;
            END IF;
            --não usa tributação por estado
          ELSE
            -- busca as informacoes da tabela de preco.
            BEGIN
              SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
                     NVL(PCTRIBUT.ALIQICMS2, 0),
                     NVL(PCTRIBUT.CODICMTAB, 0),
                     PCTABPR.CODST,
                     NVL(PCEST.CUSTOCONT, 0),
                     NVL(PCEST.CUSTOFIN, 0),
                     NVL(PCEST.CUSTOREAL, 0),
                     NVL(PCEST.CUSTOREP, 0),
                     NVL(PCEST.CUSTOULTENT, 0),
                     NVL(PCTABPR.EXCLUIDO, 'N'),
                     NVL(PCTRIBUT.IVA, 0),
                     NVL(PCTRIBUT.PAUTA, 0),
                     NVL(PCTRIBUT.PERACRESCISMOPF, 0),
                     NVL(PCTABPR.PERDESCAUTOR, 0),
                     NVL(PCTRIBUT.PERDESCCUSTO, 0),
                     NVL(PCTABPR.PERDESCMAX, 0),
                     NVL(PCTABPR.PERDESCMAXESP, 0),
                     PCTRIBUT.PERDESTAB,
                     NVL(PCTABPR.PRECOMINIMOVENDA, 0),
                     ROUND(NVL(PCTABPR.PVENDA, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDA7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     NVL(PCTABPR.QTDESCAUTOR, 0),
                     NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
                     NVL(PERCBASEREDST, 0),
                     NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
                     NVL(PCTRIBUT.IVAFONTE, 0),
                     NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
                     NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
                     NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
                     NVL(PCTRIBUT.PERCBASERED, 0),
                     NVL(PCTRIBUT.PERBASEREDNRPA, 0),
                     NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
                     NVL(UTILIZAPERCBASEREDPF, 'N'),
                     NVL(PCEST.VALORULTENT, 0),
                     NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
                     NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
                     NVL(PCTRIBUT.CODICMTABPF, 0),
                     NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
                     NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
                     PCTABPR.DESCONTAFRETE,
                     NVL(PCTRIBUT.PERCDESCPIS, 0),
                     NVL(PCTRIBUT.PERCDESCCOFINS, 0),
                     NVL(PCTRIBUT.PERDESCREPASSE, 0),
                     NVL(PCTABPR.PRECOMAXCONSUM, 0),
                     1,
                     1,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     0,
                     NVL(PCTRIBUT.MOSTRARPVENDASEMST, GREGPCCONSUM.MOSTRARPVENDASEMST),
                     NVL(PCTRIBUT.USAPMCBASEST, 'N'),
                     NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
                     NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
                     NVL(PCEST.VLSTULTENT, 0),
                     NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
                     NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
                     NVL(PCEST.IVAULTENT, 0),
                     NVL(PCEST.ALIQICMS1ULTENT, 0),
                     NVL(PCEST.ALIQICMS2ULTENT, 0),
                     NVL(PCEST.REDBASEIVAULTENT, 100),
                     NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
                     NVL(PCEST.VLFRETECONHECULTENT, 0),
                     NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
                     NVL(PCEST.BASEICMSULTENT, 0),
                     NVL(PCEST.VLSTGUIAULTENT, 0),
                     NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
                     PCTRIBUT.PAGTONOMEDOCLIENTE,
                     NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                     PCTABPR.PRECOFAB,
                     NULL,
                     NULL,
                     NULL,
                     NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST, 'N'),
                     NVL(PCTABPR.VLULTENTMES, 0),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDASEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     NVL(PCTRIBUT.PERCBASESTRJ, 0),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO1, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO2, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO3, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO4, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO5, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO6, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     ROUND(NVL(PCTABPR.PVENDAATACSEMIMPOSTO7, 0), GREGPCCONSUM.NUMCASASDECVENDA),
                     NVL(PCTRIBUT.USAALIQICMSSIMPLESNACIONAL, 'N'),
                     NVL(PCTRIBUT.ALIQSTSIMPLESNACIONAL, 0),
                     NVL(PCTRIBUT.AGREGARIPICALCULOST, 'N'),
                     NVL(PCTABPR.VLST, 0)
                INTO P_REGPRECOS
                FROM PCTABPR, PCTRIBUT, PCEST
               WHERE PCTABPR.CODST = PCTRIBUT.CODST
                 AND PCTABPR.CODPROD = P_REGITEM.CODPROD
                 AND PCEST.CODPROD = P_REGITEM.CODPROD
                 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
                 AND PCEST.CODFILIAL = DECODE(P_REGFILIAL.ORIGEMCUSTOFILIALRETIRA, 'V', P_REGPEDIDO.CODFILIAL,
                                              NVL(P_REGITEM.CODFILIALRETIRA, P_REGPEDIDO.CODFILIAL));
            EXCEPTION
              WHEN OTHERS THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
                              SQLCODE || '-' || SQLERRM || ';';
                P_REGITEM.VALIDO        := FALSE;
                P_REGORIGEMPRECO.VALIDO := FALSE;
                P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 104;
            END;
          END IF;
        END IF;

        IF P_REGFILIAL.PRECOPOREMBALAGEM = 'S' AND
           P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' AND P_REGITEM.TIPOINTEGRACAO <> 'W' THEN

          P_REGORIGEMDESC.PEMBALAGEM := 'S';
          --Varejo
          IF NVL(P_REGPRECOS.QTUNIT,0) <> 0 THEN
             IF P_REGFILIAL.TIPOPRECIFICACAO <> 'A' THEN
               IF P_REGPRECOS.QTMINIMAATACADO > 1 THEN
                 IF P_REGITEM.QT >= P_REGPRECOS.QTMINIMAATACADO THEN
                   P_REGPRODUTO.PTABELA           := P_REGPRECOS.PVENDAATAC / P_REGPRECOS.QTUNIT;
                   P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDAATAC / P_REGPRECOS.QTUNIT;
                 ELSE
                   P_REGPRODUTO.PTABELA           := P_REGPRECOS.PVENDAEMB / P_REGPRECOS.QTUNIT;
                   P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDAEMB / P_REGPRECOS.QTUNIT;
                 END IF;
               ELSE
                 P_REGPRODUTO.PTABELA           := P_REGPRECOS.PVENDAEMB / P_REGPRECOS.QTUNIT;
                 P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDAEMB / P_REGPRECOS.QTUNIT;
               END IF;
               --Atacado
             ELSE
               P_REGPRODUTO.PTABELA           := P_REGPRECOS.PVENDAATAC / P_REGPRECOS.QTUNIT;
               P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDAATAC / P_REGPRECOS.QTUNIT;
             END IF;
             --verificar p oferta como preco minimo
             IF (P_REGPRECOS.POFERTA > 0) AND
                TRUNC(SYSDATE) BETWEEN P_REGPRECOS.DTOFERTAINI AND
                P_REGPRECOS.DTOFERTAFIM THEN
               IF P_REGITEM.QT < P_REGPRECOS.QTMINIMAATACADO THEN
                 P_REGPRODUTO.PTABELA := P_REGPRECOS.POFERTA / P_REGPRECOS.QTUNIT;
               END IF;
             END IF;

             IF P_REGFILIAL.TIPOPRECIFICACAO <> 'A' THEN
               IF (P_REGPRECOS.POFERTA > 0) AND
                  (TRUNC(SYSDATE) BETWEEN P_REGPRECOS.DTOFERTAINI AND P_REGPRECOS.DTOFERTAFIM) THEN
                 IF P_REGITEM.QT < P_REGPRECOS.QTMINIMAATACADO THEN
                   P_REGPRODUTO.PTABELA := P_REGPRECOS.POFERTA / P_REGPRECOS.QTUNIT;
                 END IF;
               END IF;
             ELSE
               IF (P_REGPRECOS.POFERTAATAC > 0) AND
                  (TRUNC(SYSDATE) BETWEEN P_REGPRECOS.DTOFERTAATACINI AND
                  P_REGPRECOS.DTOFERTAATACFIM) THEN
                 IF P_REGITEM.QT >= P_REGPRECOS.QTMINIMAATACADO THEN
                   P_REGPRODUTO.PTABELA := P_REGPRECOS.POFERTAATAC / P_REGPRECOS.QTUNIT;
                 END IF;
               END IF;
             END IF;
          END IF;

          IF NVL(P_REGPRODUTO.PTABELA, 0) = 0 THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;
            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PRECO DE TABELA ZERADO;';
            IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
              P_REGITEM.VALIDO        := FALSE;
              P_REGORIGEMPRECO.VALIDO := FALSE;
            ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
              P_REGPEDIDO.VALIDO := FALSE;
            ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
              P_REGPEDIDO.POSICAO := 'B';
              IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
                P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) ||
                                   'Produto nao pode ser vendido nesse Plano de Pagamento. Numero de dias medio do cadastro do produto inferior ao do Plano';
              END IF;

              P_REGPEDIDO.MOTIVOPOSICAO := 'Prazo medio do produto inferior ao do Plano.Codprod :' || P_REGITEM.CODPROD;

              IF P_REGPEDIDO.POSICAO = 'B' THEN
                 PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
              END IF;
            END IF;

            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
          END IF;
        ELSE
          IF P_REGPLPAG.NUMPR = 1 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA1;
          ELSIF P_REGPLPAG.NUMPR = 2 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA2;
          ELSIF P_REGPLPAG.NUMPR = 3 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA3;
          ELSIF P_REGPLPAG.NUMPR = 4 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA4;
          ELSIF P_REGPLPAG.NUMPR = 5 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA5;
          ELSIF P_REGPLPAG.NUMPR = 6 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA6;
          ELSIF P_REGPLPAG.NUMPR = 7 THEN
            P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA7;
          END IF;

          -- verifica precos sem imposto da 201
          IF P_REGPLPAG.NUMPR = 1 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO1;
          ELSIF P_REGPLPAG.NUMPR = 2 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO2;
          ELSIF P_REGPLPAG.NUMPR = 3 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO3;
          ELSIF P_REGPLPAG.NUMPR = 4 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO4;
          ELSIF P_REGPLPAG.NUMPR = 5 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO5;
          ELSIF P_REGPLPAG.NUMPR = 6 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO6;
          ELSIF P_REGPLPAG.NUMPR = 7 THEN
            P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRECOS.PVENDASEMIMPOSTO7;
          END IF;
        END IF;
      END IF;

      P_REGITEM.GERAGNRE_CNPJCLIENTE := NULL;

      IF P_REGPRECOS.TIPOCALCULOGNRE = 'P' AND
         P_REGPRECOS.PAGTONOMEDOCLIENTE = 'S' THEN
        P_REGITEM.GERAGNRE_CNPJCLIENTE := 'S';
      END IF;

      IF P_REGCLIENTE.ACEITAVENDAFRACAO = 'S' AND
         P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S' THEN
        IF P_REGPRODUTO.MULTIPLO = 0 THEN
          IF P_REGPRODUTO.ACEITAVENDAFRACAO = 'M' THEN
            IF (P_REGITEM.QT / 0.5) <> TRUNC(P_REGITEM.QT / 0.5) THEN
              IF VSMENSAGEM IS NOT NULL THEN
                VSCHAR := '#';
              ELSE
                VSCHAR := NULL;
              END IF;

              P_REGITEM.QT := TRUNC(P_REGITEM.QT / 0.5) * 0.5;

              IF P_REGITEM.QT > 0 THEN
                VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                              'Produto so pode ser vendido fracionado de 0.5 ' || CHR(13) ||
                              'Quantidade pedida alterada para :' || P_REGITEM.QT || ';';
              ELSE
                VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                              'Produto so pode ser vendido fracionado de 0.5 : ' || CHR(13) ||
                              'Item será cortado por não atingir fracionamento;';

                P_REGITEM.VALIDO := FALSE;
              END IF;
            END IF;
          ELSIF P_REGPRODUTO.ACEITAVENDAFRACAO = 'N' AND
                P_REGITEM.QT <> TRUNC(P_REGITEM.QT) THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto nao pode ser vendido fracionado ;';

            P_REGITEM.VALIDO := FALSE;
          END IF;
        END IF;
      ELSE
        IF P_REGITEM.QT <> TRUNC(P_REGITEM.QT) AND (P_REGCLIENTE.ACEITAVENDAFRACAO = 'N') THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cliente nao aceita venda fracionada ;';

          P_REGITEM.VALIDO := FALSE;
        END IF;
      END IF;

      IF (P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S') AND
         (((P_REGPEDIDO.CONDVENDA <> 5)) OR
         ((P_REGPEDIDO.CONDVENDA = 5) AND
         (P_REGPRODUTO.CHECARMULTIPLOVENDABNF = 'S'))) THEN
        IF NVL(P_REGPRODUTO.MULTIPLO,0) <> 0 THEN
          IF (P_REGITEM.QT / P_REGPRODUTO.MULTIPLO) <>
             TRUNC(P_REGITEM.QT / P_REGPRODUTO.MULTIPLO) THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            P_REGITEM.QT := TRUNC(P_REGITEM.QT / P_REGPRODUTO.MULTIPLO) * P_REGPRODUTO.MULTIPLO;

            IF P_REGITEM.QT > 0 THEN
              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto so pode ser vendido multiplo de : ' ||
                            P_REGPRODUTO.MULTIPLO || CHR(13) || 'Quantidade pedida alterada para :' || P_REGITEM.QT || ';';
            ELSE
              VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto so pode ser vendido multiplo de : ' ||
                            P_REGPRODUTO.MULTIPLO || ';';

              P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 153;

              IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
                P_REGITEM.VALIDO        := FALSE;
                P_REGORIGEMPRECO.VALIDO := FALSE;
              ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
                P_REGPEDIDO.VALIDO := FALSE;
              ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                P_REGPEDIDO.POSICAO := 'B';

                IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR
                   P_REGPEDIDO.LOG IS NULL THEN
                  P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) ||
                                     'Produto so pode ser vendido multiplo de : ' || P_REGPRODUTO.MULTIPLO || ';';
                END IF;

                P_REGPEDIDO.MOTIVOPOSICAO := SUBSTR('Produto so pode ser vendido multiplo de : ' ||
                                             P_REGPRODUTO.MULTIPLO || ';', 1, 45) || 'Codprod :' || P_REGITEM.CODPROD;

                IF P_REGPEDIDO.POSICAO = 'B' THEN
                   PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;

      IF VNQTMAXPEDVENDA > 0 THEN
        IF P_REGITEM.QT > VNQTMAXPEDVENDA THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto nao pode ser vendido na# Quantidade :' ||
                        P_REGITEM.QT || '#' || 'Quantidade maxima : ' || VNQTMAXPEDVENDA || ';';

          IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
            P_REGPEDIDO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
            P_REGPEDIDO.POSICAO := 'B';

            IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
              P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) ||
                                 'Produto nao pode ser vendido nesta quantidade. Quantidade maxima :' ||
                                 VNQTMAXPEDVENDA || ';';
            END IF;

            P_REGPEDIDO.MOTIVOPOSICAO := 'Produto nao pode ser vendido nesta quantidade :' || P_REGITEM.CODPROD;

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          END IF;
        END IF;
      END IF;

      P_REGORIGEMDESC.PTABELA := P_REGPRODUTO.PTABELA;

      IF P_REGPEDIDO.ORIGEMPED = 'R' THEN
        IF GREGPCCONSUM.ABATEFRETEVENDABALCAO = 'S' AND
           P_REGPRECOS.DESCONTAFRETE = 'S' THEN
          P_REGORIGEMPRECO.TIPOFRETE := '1';
          P_REGORIGEMPRECO.PERCFRETE := P_REGREGIAO.PERFRETE;
        END IF;

        IF NVL(GREGPCCONSUM.PERCACRESCIMOBALCAO, 0) > 0 THEN
          P_REGORIGEMPRECO.PERCACRESCBALCAO := GREGPCCONSUM.PERCACRESCIMOBALCAO;
        END IF;
      END IF;

      -- verifica se produto esta excluido na regiao
      IF P_REGPRECOS.EXCLUIDO = 'S' THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto excluido da regiao;';
        P_REGITEM.VALIDO        := FALSE;
        P_REGORIGEMPRECO.VALIDO := FALSE;
        P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 105;
      END IF;

      -- produto sem custo financeiro
      IF P_REGPRECOS.CUSTOFIN = 0 THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custo financeiro;';
        P_REGITEM.VALIDO        := FALSE;
        P_REGORIGEMPRECO.VALIDO := FALSE;
        P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 106;
      END IF;

      -- produto sem custo real
      IF P_REGPRECOS.CUSTOREAL = 0 THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custo real;';
        P_REGITEM.VALIDO        := FALSE;
        P_REGORIGEMPRECO.VALIDO := FALSE;
        P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 107;
      END IF;

      -- produto sem custo real + crédito de icm
      IF P_REGPRECOS.CUSTOREP = 0 THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custo reposicao;';
        P_REGITEM.VALIDO        := FALSE;
        P_REGORIGEMPRECO.VALIDO := FALSE;
        P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 108;
      END IF;

      -- verifica produto com preco 0 (zero)
      IF P_REGFILIAL.PRECOPOREMBALAGEM = 'N' AND P_REGITEM.CESTA = 'N' THEN
        IF (P_REGPRECOS.PVENDA <= 0) OR (P_REGPRECOS.PVENDA1 <= 0) OR
           (P_REGPRECOS.PVENDA2 <= 0) OR (P_REGPRECOS.PVENDA3 <= 0) OR
           (P_REGPRECOS.PVENDA4 <= 0) OR (P_REGPRECOS.PVENDA5 <= 0) OR
           (P_REGPRECOS.PVENDA6 <= 0) OR (P_REGPRECOS.PVENDA7 <= 0) THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Preco de tabela zerado;';

          IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
            P_REGPEDIDO.VALIDO := FALSE;
          ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
            P_REGPEDIDO.POSICAO := 'B';
            IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
              P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) ||
                                 'Produto nao pode ser vendido nesse Plano de Pagamento. Numero de dias medio do cadastro do produto inferior ao do Plano';
            END IF;

            P_REGPEDIDO.MOTIVOPOSICAO := 'Prazo medio do produto inferior ao do Plano.Codprod :' || P_REGITEM.CODPROD;

            IF P_REGPEDIDO.POSICAO = 'B' THEN
               PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          END IF;

          P_REGITEM.VALIDO        := FALSE;
          P_REGORIGEMPRECO.VALIDO := FALSE;
          P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 109;
        END IF;
      END IF;

      -- tratamento com relacao ao preco e descontos
      IF P_REGITEM.VALIDO = TRUE THEN
         IF P_REGITEM.CESTA = 'S' THEN
          FUNCOESVENDAS.BUSCARPRECOCESTABASICA(P_REGPEDIDO.NUMPED,
                                               P_REGITEM.CODPROD,
                                               P_REGREGIAO.NUMREGIAO,
                                               P_REGPLPAG.NUMPR,
                                               VBECESTA,
                                               VNPTABELACESTA,
                                               VSMENSAGEMCESTA,
                                               P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM,
                                               P_REGFILIAL.PRECOPOREMBALAGEM,
                                               P_REGFILIAL.TIPOPRECIFICACAO,
                                               P_REGPEDIDO.CODFILIAL,
                                               P_REGITEM.QT);
          IF VBECESTA = FALSE THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || ' Nao encontrado cadastro como cesta';
            P_REGITEM.VALIDO        := FALSE;
            P_REGORIGEMPRECO.VALIDO := FALSE;
            P_REGITEM.CODRETORNOS   := P_REGITEM.CODRETORNOS || ';' || 123;
          ELSE
            P_REGPRODUTO.PTABELA           := VNPTABELACESTA;
            P_REGPRODUTO.PTABELASEMIMPOSTO := VNPTABELACESTASEMIMPOSTO;
            P_REGITEM.PBASERCA             := VNPTABELACESTA;
            P_REGITEM.PVENDA1              := VNPTABELACESTA;

            PROC_VALIDAITENSCESTA(P_REGITEM,
                                  P_REGORIGEMPRECO,
                                  P_REGPRODUTO,
                                  P_REGPEDIDO,
                                  P_REGFILIAL,
                                  P_REGREGIAO,
                                  P_REGCLIENTE,
                                  P_REGPLPAG,
                                  VSMENSAGEMITENSCESTA,
                                  VBVALIDOPRECOFIXOCESTA);

            IF VBVALIDOPRECOFIXOCESTA = TRUE THEN
              P_REGPRODUTO.PTABELASEMIMPOSTO := P_REGPRODUTO.PTABELA;
            END IF;
          END IF;

          IF TRIM(VSMENSAGEMCESTA) IS NOT NULL THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM       := VSMENSAGEM || VSCHAR || VSMENSAGEMCESTA;
            P_REGITEM.VALIDO := FALSE;
          END IF;

          IF TRIM(VSMENSAGEMITENSCESTA) IS NOT NULL THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMITENSCESTA;
            P_REGITEM.VALIDO := FALSE;
          END IF;
        END IF;

        P_REGORIGEMPRECO.PORIGINAL := P_REGPRODUTO.PTABELA;
        P_REGITEM.PORIGINAL        := P_REGPRODUTO.PTABELA;
        P_REGITEM.PVENDABASE       := P_REGPRODUTO.PTABELA;

        IF (P_REGCLIENTE.CONSUMIDORFINAL = 'S') AND
           ((P_REGPRODUTO.IMPORTADO = 'S') OR
           (P_REGPRODUTO.IMPORTADO = 'D')) AND
           (P_REGFILIAL.UF <> P_REGCLIENTE.ESTENT) AND
           (P_REGPRECOS.AGREGARIPICALCULOST = 'S') THEN

          VSCONSIDERARIPIALIQICMS2 := 'S';
        END IF;

        --***********************************************
        --Retirar impostos
        IF P_REGITEM.CESTA = 'N' OR
           (P_REGITEM.CESTA = 'S' AND VBVALIDOPRECOFIXOCESTA = FALSE) THEN
          IF P_REGFILIAL.PRECOPOREMBALAGEM = 'N' THEN
            IF (NVL(P_REGPRODUTO.PTABELASEMIMPOSTO, 0) > 0) AND (P_REGITEM.INTEGRADORA <> 4) THEN
              -- 201 ja atualizada
              P_REGITEM.RETIRAIMP := 'N';
              --verifica percentual de desc/acrescimo comercial
              P_REGITEM.PERCDESCCOM := 0;
              IF NVL(P_REGPRODUTO.PTABELA,0) <> 0 THEN
                 P_REGITEM.PERCDESCCOM := 100 - ((P_REGITEM.PVENDA * 100) / P_REGPRODUTO.PTABELA);
              END IF;

              VNPVENDA    := P_REGITEM.PVENDA;
              VNPTABELA   := P_REGPRODUTO.PTABELA;
              VN_PBASERCA := P_REGITEM.PBASERCA;

              BEGIN
                 SELECT PCFILIAL.UF
                 INTO VSUFFILIALNF
                 FROM PCFILIAL
                 WHERE PCFILIAL.CODIGO = P_REGPEDIDO.CODFILIALNF;
              EXCEPTION WHEN OTHERS THEN
                  VSUFFILIALNF := NULL;
              END;
                
              VBCALCULASTVALIDO := FUNCOESVENDAS.CALCULARIMPOSTOS(VNPVENDA,
                                                                    VNPTABELA,
                                                                    VN_PBASERCA,
                                                                    VNVLIPI,
                                                                    VNPERCIPI,
                                                                    NVL(P_REGPRODUTO.PERCIPIVENDA, 0),
                                                                    P_REGPEDIDO.PERCVENDA,
                                                                    GREGPCCONSUM.TIPOCALCST,
                                                                    GREGPCCONSUM.CALCSTPF,
                                                                    P_REGPRECOS.MOSTRARPVENDASEMST,
                                                                    GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                                    P_REGCLIENTE.CALCULAST,
                                                                    P_REGCLIENTE.IEENT,
                                                                    P_REGCLIENTE.TIPOFJ,
                                                                    P_REGPRECOS.PAUTA,
                                                                    P_REGPRECOS.IVA,
                                                                    P_REGPRECOS.ALIQICMS1,
                                                                    P_REGPRECOS.ALIQICMS2,
                                                                    P_REGPRECOS.PERCBASEREDST,
                                                                    GREGPCCONSUM.NUMCASASDECVENDA,
                                                                    0,
                                                                    P_REGFILIAL.UF,
                                                                    P_REGCLIENTE.ESTENT,
                                                                    NVL(P_REGPRECOS.USAVALORULTENTBASEST, 'N'),
                                                                    NVL(P_REGPRECOS.USAVALORULTENTBASEST2, 'N'),
                                                                    P_REGPRECOS.VALORULTENT,
                                                                    P_REGCLIENTE.ISENTOIPI,
                                                                    P_REGCLIENTE.SUFRAMA,
                                                                    GREGPCCONSUM.CALCULARSTCOMIPI,
                                                                    GREGPCCONSUM.TIPOCALCIPI,
                                                                    P_REGPEDIDO.CODFILIALNF,
                                                                    P_REGPEDIDO.CONDVENDA,
                                                                    P_REGCLIENTE.CONTRIBUINTE,
                                                                    VSUFFILIALNF,
                                                                    P_REGPRODUTO.IMPORTADO,
                                                                    P_REGFILIAL.CALCULARIPIVENDA,
                                                                    P_REGPRODUTO.PERCIPIVENDATAB,
                                                                    P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                    P_REGPRODUTO.VLPAUTAIPIVENDATAB,
                                                                    P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                    P_REGPRODUTO.VLIPIPORKGVENDATAB,
                                                                    P_REGPRODUTO.PESOBRUTO,
                                                                    P_REGPRECOS.TIPOCALCULOGNRE,
                                                                    P_REGCLIENTE.SIMPLESNACIONAL,
                                                                    P_REGPRECOS.PERCREDPVENDASIMPLESNAC,
                                                                    'S',
                                                                    P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                                                    VSMENSAGEM_ST,
                                                                    VNVLST,
                                                                    VNBASEICST,
                                                                    GREGPCCONSUM.ACEITAPFCONTRIBUINTE,
                                                                    P_REGPRECOS.CUSTONFSEMST,
                                                                    P_REGPRECOS.USAPMCBASEST,
                                                                    P_REGPRODUTO.PRECOMAXCONSUM,
                                                                    P_REGCLIENTE.CONSUMIDORFINAL,
                                                                    P_REGITEM.RETIRAIMP,
                                                                    'N',
                                                                    P_REGPRECOS.AGREGARIPICALCULOST,
                                                                    P_REGCLIENTE.UTILIZACALCULOSTMT,
                                                                    P_REGCLIENTE.MARGEMMVA,
                                                                    P_REGCLIENTE.PERCARGATRIBMEDIA,
                                                                    P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                    P_REGPRECOS.VLULTENTMES,
                                                                    P_REGPRECOS.PERCBASESTRJ);

                P_REGITEM.PERCIMPOSTO := 0;
                IF NVL(P_REGITEM.PVENDA,0) <> 0 THEN
                   P_REGITEM.PERCIMPOSTO := (NVL(VNVLST, 0) * 100) / P_REGITEM.PVENDA;
                END IF;
                
                VNPERCIMPOSTOPTABELA := 0;
                IF NVL(NVL(P_REGPRODUTO.PTABELASEMIMPOSTO,P_REGPRODUTO.PTABELA),0) <> 0 THEN
                   VNPERCIMPOSTOPTABELA := (P_REGPRODUTO.PTABELA * 100) / NVL(P_REGPRODUTO.PTABELASEMIMPOSTO, P_REGPRODUTO.PTABELA) - 100;
                END IF;

                VNVLDIFST201 := ABS(NVL(VNVLST, 0) - (P_REGPRODUTO.PTABELA - P_REGPRODUTO.PTABELASEMIMPOSTO));

                IF P_REGITEM.INTEGRADORA = 23 THEN 
                   P_REGPRODUTO.PTABELA  := P_REGPRODUTO.PTABELA;
                ELSE   
                   P_REGPRODUTO.PTABELA  := (P_REGPRODUTO.PTABELA - NVL(P_REGPRECOS.VLST,0)) / (1 + (VNPERCIPI/100));
                   P_REGITEM.PVENDA      := (P_REGITEM.PVENDA - NVL(VNVLST, 0)) / (1 + (VNPERCIPI/100));
                END IF; 
                
                VSRETIROUIMPOSTO      := TRUE;
                P_REGITEM.PVENDASEMIMPOSTO := 'S';
            ELSE
              --201 ainda não atualizada
              P_REGITEM.RETIRAIMP := 'N';

              VBCALCULOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(P_REGPRODUTO.PERCIPIVENDA, 0),
                                                                              P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                              P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                              P_REGITEM.PVENDA,
                                                                              P_REGPRECOS.PAUTA,
                                                                              P_REGPRODUTO.PESOBRUTO,
                                                                              P_REGPRECOS.PERCDIFALIQUOTAS,
                                                                              P_REGPRODUTO.PERCIPIVENDA,
                                                                              P_REGPRECOS.VALORULTENT,
                                                                              P_REGPRECOS.IVA,
                                                                              P_REGPRECOS.PERCBASEREDST,
                                                                              P_REGPRECOS.ALIQICMS1,
                                                                              P_REGPRECOS.ALIQICMS2,
                                                                              P_REGPRECOS.USAVALORULTENTBASEST,
                                                                              P_REGPRECOS.USAVALORULTENTBASEST2,
                                                                              P_REGFILIAL.UF,
                                                                              P_REGCLIENTE.ESTENT,
                                                                              VNPVENDASEMIMPOSTO,
                                                                              VSMENSAGEMPRECOSEMIMPOSTO,
                                                                              P_REGPRECOS.USAPMCBASEST,
                                                                              P_REGPRODUTO.PRECOMAXCONSUM,
                                                                              VSCONSIDERARIPIALIQICMS2,
                                                                              P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                              P_REGPRECOS.VLULTENTMES);

              VBCALCULOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(P_REGPRODUTO.PERCIPIVENDA, 0),
                                                                              P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                              P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                              P_REGPRODUTO.PTABELA,
                                                                              P_REGPRECOS.PAUTA,
                                                                              P_REGPRODUTO.PESOBRUTO,
                                                                              P_REGPRECOS.PERCDIFALIQUOTAS,
                                                                              P_REGPRODUTO.PERCIPIVENDA,
                                                                              P_REGPRECOS.VALORULTENT,
                                                                              P_REGPRECOS.IVA,
                                                                              P_REGPRECOS.PERCBASEREDST,
                                                                              P_REGPRECOS.ALIQICMS1,
                                                                              P_REGPRECOS.ALIQICMS2,
                                                                              P_REGPRECOS.USAVALORULTENTBASEST,
                                                                              P_REGPRECOS.USAVALORULTENTBASEST2,
                                                                              P_REGFILIAL.UF,
                                                                              P_REGCLIENTE.ESTENT,
                                                                              VNPTABELASEMIMPOSTO,
                                                                              VSMENSAGEMPRECOSEMIMPOSTO,
                                                                              P_REGPRECOS.USAPMCBASEST,
                                                                              P_REGPRODUTO.PRECOMAXCONSUM,
                                                                              VSCONSIDERARIPIALIQICMS2,
                                                                              P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                              P_REGPRECOS.VLULTENTMES);

              VBCALCULOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(P_REGPRODUTO.PERCIPIVENDA, 0),
                                                                              P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                              P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                              P_REGPRECOS.PRECOMINIMOVENDA,
                                                                              P_REGPRECOS.PAUTA,
                                                                              P_REGPRODUTO.PESOBRUTO,
                                                                              P_REGPRECOS.PERCDIFALIQUOTAS,
                                                                              P_REGPRODUTO.PERCIPIVENDA,
                                                                              P_REGPRECOS.VALORULTENT,
                                                                              P_REGPRECOS.IVA,
                                                                              P_REGPRECOS.PERCBASEREDST,
                                                                              P_REGPRECOS.ALIQICMS1,
                                                                              P_REGPRECOS.ALIQICMS2,
                                                                              P_REGPRECOS.USAVALORULTENTBASEST,
                                                                              P_REGPRECOS.USAVALORULTENTBASEST2,
                                                                              P_REGFILIAL.UF,
                                                                              P_REGCLIENTE.ESTENT,
                                                                              VNPRECOMINIMOVENDASEMIMPOSTO,
                                                                              VSMENSAGEMPRECOSEMIMPOSTO,
                                                                              P_REGPRECOS.USAPMCBASEST,
                                                                              P_REGPRODUTO.PRECOMAXCONSUM,
                                                                              VSCONSIDERARIPIALIQICMS2,
                                                                              P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                              P_REGPRECOS.VLULTENTMES);
              BEGIN
                 SELECT NVL(VALORSEMIMPOSTO,0) VALORSEMIMPOSTO
                 INTO vnCALCULAR_PVENDA_SEM_IMPOSTO
                 FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(
                               P_REGPEDIDO.CODFILIAL,
                               NVL(P_REGPEDIDO.CODFILIALNF, P_REGCLIENTE.CODFILIALNF),
                               P_REGITEM.CODFILIALRETIRA,
                               NVL(P_REGPEDIDO.CODCLI, P_REGCLIENTE.CODCLI),
                               NVL(P_REGPEDIDO.CODPLPAG, P_REGCLIENTE.CODPLPAG),
                               P_REGITEM.CODPROD,
                               P_REGITEM.CODAUXILIAR,
                               NVL(P_REGPEDIDO.CONDVENDA, 1),
                               'N',
                               0,
                               0,
                               P_REGITEM.PVENDA
                               ));
              EXCEPTION WHEN OTHERS THEN
                  vnCALCULAR_PVENDA_SEM_IMPOSTO := P_REGITEM.PVENDA;
              END;

              IF (P_REGITEM.INTEGRADORA = 4) AND (vnCALCULAR_PVENDA_SEM_IMPOSTO > 0) THEN
   							 VNPTABELASEMIMPOSTO := vnCALCULAR_PVENDA_SEM_IMPOSTO;
   							 VNPVENDASEMIMPOSTO := vnCALCULAR_PVENDA_SEM_IMPOSTO;
						  END IF;

              BEGIN
                 SELECT NVL(BASEST,0),
                        NVL(ST,0),
                        NVL(VLRFECP,0)
                 INTO VNBASEICST,
                      VNVLST,
                      vnVLFECP
                 FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(P_REGPEDIDO.CODFILIAL,
                                                       NVL(P_REGPEDIDO.CODFILIALNF, P_REGCLIENTE.CODFILIALNF),
                                                       P_REGITEM.CODFILIALRETIRA,
                                                       NVL(P_REGPEDIDO.CODCLI, P_REGCLIENTE.CODCLI),
                                                       NVL(P_REGPEDIDO.CODPLPAG, P_REGCLIENTE.CODPLPAG),
                                                       P_REGITEM.CODPROD,
                                                       P_REGITEM.CODAUXILIAR,
                                                       NVL(P_REGPEDIDO.CONDVENDA, 1),
                                                       'N',
                                                       VNPTABELASEMIMPOSTO,
                                                       0));
              EXCEPTION WHEN OTHERS THEN
                 VNBASEICST := 0;
                 VNVLST     := 0;
                 vnVLFECP   := 0;
              END;
                
              IF VNPRECOMINIMOVENDASEMIMPOSTO < P_REGPRECOS.PRECOMINIMOVENDA AND
                 ((P_REGPRECOS.PRECOMINIMOVENDA - VNPRECOMINIMOVENDASEMIMPOSTO) > 0.01) THEN
                 P_REGPRECOS.PRECOMINIMOVENDA := ROUND(VNPRECOMINIMOVENDASEMIMPOSTO, GREGPCCONSUM.NUMCASASDECVENDA);
              END IF;

              IF VNPVENDASEMIMPOSTO < P_REGITEM.PVENDA AND
                 ((P_REGITEM.PVENDA - VNPVENDASEMIMPOSTO) > 0.01) THEN
                 P_REGITEM.PVENDA := ROUND(VNPVENDASEMIMPOSTO, GREGPCCONSUM.NUMCASASDECVENDA);
                 VSRETIROUIMPOSTO           := TRUE;
                 P_REGITEM.PVENDASEMIMPOSTO := 'S';
              END IF;
			  			  
              --verifica percentual de imposto
              P_REGITEM.PERCIMPOSTO := 0;
              IF NVL(NVL(VNPTABELASEMIMPOSTO,P_REGPRODUTO.PTABELA),0) <> 0 THEN
                 P_REGITEM.PERCIMPOSTO := (P_REGPRODUTO.PTABELA * 100) / NVL(VNPTABELASEMIMPOSTO, P_REGPRODUTO.PTABELA) - 100;
              END IF;

              IF VNPTABELASEMIMPOSTO < P_REGPRODUTO.PTABELA AND
                 ((P_REGPRODUTO.PTABELA - VNPTABELASEMIMPOSTO) > 0.01) THEN
                 IF (P_REGITEM.INTEGRADORA = 4) THEN
                    P_REGPRODUTO.PTABELA := ROUND(P_REGPRODUTO.PTABELA - (VNVLST + vnVLFECP), GREGPCCONSUM.NUMCASASDECVENDA);
                 ELSE   
                    P_REGPRODUTO.PTABELA := ROUND(VNPTABELASEMIMPOSTO, GREGPCCONSUM.NUMCASASDECVENDA);
                 END IF;
              END IF;
			  
              -- Verifica percentual de desc/acrescimo comercial
              P_REGITEM.PERCDESCCOM := 0;
              IF NVL(P_REGPRODUTO.PTABELA,0) <> 0 THEN
                 P_REGITEM.PERCDESCCOM := 100 - ((P_REGITEM.PVENDA * 100) / P_REGPRODUTO.PTABELA);
              END IF;
            END IF;
          END IF;
        END IF;
        --**********************************************
        IF P_REGITEM.VALIDO = TRUE THEN
          --Desconto por Atividade
          BEGIN
            SELECT NVL(PCATIVI.PERCDESC, 0)
              INTO VNPERDESCATIV
              FROM PCATIVI, PCCLIENT
             WHERE PCCLIENT.CODCLI = P_REGCLIENTE.CODCLI
               AND PCCLIENT.CODATV1 = PCATIVI.CODATIV;
          EXCEPTION
            WHEN OTHERS THEN
              VNPERDESCATIV := 0;
          END;

          IF NVL(VNPERDESCATIV,0) <> 0 THEN
            P_REGPRODUTO.PTABELA := (P_REGPRODUTO.PTABELA + (P_REGPRODUTO.PTABELA * VNPERDESCATIV / 100));
            P_REGORIGEMPRECO.PERCRAMOATIV   := VNPERDESCATIV;
            P_REGORIGEMDESC.PERCDESCPCATIVI := VNPERDESCATIV;
          END IF;

          IF P_REGPEDIDO.CONDVENDA = 10 THEN
            --Se TIPOCUSTOTRANSF.AsString = 'P' ->  usa preço de venda
            --Custo Reposição - > default
            IF P_REGCLIENTE.TIPOCUSTOTRANSF = 'E' THEN
              P_REGPRODUTO.PTABELA := P_REGPRECOS.CUSTOREP;

              IF NVL(P_REGPRECOS.CUSTOREP, 0) = 0 THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custorep, necessario para pedido tipo 10';

                P_REGITEM.VALIDO      := FALSE;
                P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 126;
              END IF;
            --Custo Real
            ELSIF P_REGCLIENTE.TIPOCUSTOTRANSF = 'R' THEN
              P_REGPRODUTO.PTABELA := P_REGPRECOS.CUSTOREAL;

              IF NVL(P_REGPRECOS.CUSTOREAL, 0) = 0 THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custoreal, necessario para pedido tipo 10';

                P_REGITEM.VALIDO      := FALSE;
                P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 127;
              END IF;
            --Custo Contábil
            ELSIF P_REGCLIENTE.TIPOCUSTOTRANSF = 'C' THEN
              P_REGPRODUTO.PTABELA := P_REGPRECOS.CUSTOCONT;

              IF NVL(P_REGPRECOS.CUSTOCONT, 0) = 0 THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custocont, necessario para pedido tipo 10';

                P_REGITEM.VALIDO      := FALSE;
                P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 128;
              END IF;
            --Custo Financeiro
            ELSIF P_REGCLIENTE.TIPOCUSTOTRANSF = 'F' THEN
              P_REGPRODUTO.PTABELA := P_REGPRECOS.CUSTOFIN;

              IF NVL(P_REGPRECOS.CUSTOFIN, 0) = 0 THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custofin, necessario para pedido tipo 10';

                P_REGITEM.VALIDO      := FALSE;
                P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 129;
              END IF;
            --Custo Última Entrada
            ELSIF P_REGCLIENTE.TIPOCUSTOTRANSF = 'U' THEN
              P_REGPRODUTO.PTABELA := P_REGPRECOS.CUSTOULTENT;

              IF NVL(P_REGPRECOS.CUSTOULTENT, 0) = 0 THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem custoultent, necessario para pedido tipo 10';

                P_REGITEM.VALIDO      := FALSE;
                P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 130;
              END IF;
            --Valor Última Entrada
            ELSIF P_REGCLIENTE.TIPOCUSTOTRANSF = 'V' THEN
              P_REGPRODUTO.PTABELA := P_REGPRECOS.VALORULTENT;

              IF NVL(P_REGPRECOS.VALORULTENT, 0) = 0 THEN
                IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
                ELSE
                  VSCHAR := NULL;
                END IF;

                VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Produto sem valorultent, necessario para pedido tipo 10';

                P_REGITEM.VALIDO      := FALSE;
                P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 131;
              END IF;
            END IF;

            P_REGITEM.PVENDA := P_REGPRODUTO.PTABELA * (1 + (NVL(P_REGCLIENTE.PERACRESTRANSF, 0) / 100));
          END IF;

            IF P_REGITEM.CESTA = 'N' OR (P_REGITEM.CESTA = 'S' AND VBVALIDOPRECOFIXOCESTA = FALSE) THEN
               P_REGITEM.PVENDA1 := P_REGPRECOS.PVENDA1;
               -- aplica taxa financeira do plano de pagamento
               IF (P_REGPEDIDO.TIPOINTEGRACAO <> 'W' OR P_REGPEDIDO.INTEGRADORA = 10) AND (NVL(P_REGPLPAG.PERTXFIM,0) <> 0) THEN
                  P_REGPRODUTO.PTABELA := P_REGPRODUTO.PTABELA * (1 + (P_REGPLPAG.PERTXFIM / 100));
               END IF;
               -- aplica politica acrescimo PF
               IF (P_REGPEDIDO.CONDVENDA <> 3 AND P_REGPEDIDO.CONDVENDA <> 6 AND
                  P_REGPEDIDO.CONDVENDA <> 12) OR
                  GREGPCCONSUM.APLICAACRESCPFTV3 = 'S' THEN
                  IF GREGPCCONSUM.ACRESCIMOPFCOMIE = 'S' THEN
                     IF ((((P_REGPRECOS.APLICAACRESCPJISENTA = 'S') AND
                         ((P_REGCLIENTE.IEENT = 'ISENTA') OR
                          (P_REGCLIENTE.IEENT = 'ISENTO'))) OR
                         ((P_REGCLIENTE.TIPOFJ = 'F') OR
                          (P_REGCLIENTE.CONSUMIDORFINAL = 'S'))) AND
                         (P_REGCLIENTE.CONTRIBUINTE = 'N')) OR
                        ((P_REGCLIENTE.TIPODOCUMENTO = 'C') AND
                         (P_REGFILIAL.PERCACRESCVENDACUPOM = 'S')) THEN
                        P_REGPRODUTO.PTABELA := (P_REGPRODUTO.PTABELA + (P_REGPRODUTO.PTABELA * P_REGPRECOS.PERACRESCISMOPF / 100));
                        P_REGORIGEMPRECO.PERCACRESCPF := P_REGPRECOS.PERACRESCISMOPF;
                        P_REGORIGEMDESC.PERACRESPF    := P_REGPRECOS.PERACRESCISMOPF;
                     END IF;
                  ELSE
                     IF ((((P_REGPRECOS.APLICAACRESCPJISENTA = 'S') AND
                          ((P_REGCLIENTE.IEENT = 'ISENTA') OR
                           (P_REGCLIENTE.IEENT = 'ISENTO'))) OR
                          (((P_REGCLIENTE.TIPOFJ = 'F') OR
                            (P_REGCLIENTE.CONSUMIDORFINAL = 'S')) AND
                           (TRIM(P_REGCLIENTE.IEENT) = ''))) AND
                         (P_REGCLIENTE.CONTRIBUINTE = 'N')) OR
                        ((P_REGCLIENTE.TIPODOCUMENTO = 'C') AND
                         (P_REGFILIAL.PERCACRESCVENDACUPOM = 'S')) THEN
                        P_REGPRODUTO.PTABELA := (P_REGPRODUTO.PTABELA + (P_REGPRODUTO.PTABELA * P_REGPRECOS.PERACRESCISMOPF / 100));
                        P_REGORIGEMPRECO.PERCACRESCPF := P_REGPRECOS.PERACRESCISMOPF;
                        P_REGORIGEMDESC.PERACRESPF    := P_REGPRECOS.PERACRESCISMOPF;
                     END IF;
                  END IF;
               END IF;
            END IF;

            VSPRIORITARIAGERAL := 'N';
            PROC_DESCONTO_ITEM_VENDA(P_REGPEDIDO.CODCLI, -- Código Cliente => Number
                                     P_REGITEM.CODPROD, -- Código Produto => Number
                                     P_REGPEDIDO.CODPLPAG, -- Código Plano Pagamento => Number
                                     P_REGPEDIDO.CODUSUR, -- Código Usuário => Number
                                     0, -- Percentual Informado => Number
                                     P_REGPRODUTO.PTABELA, -- Valor do PTabela => Number
                                     P_REGPRODUTO.PTABELA, -- Valor do PTabela => Number
                                     P_REGITEM.QT, -- Quantidade de itens informado no item do produto => Number
                                     P_REGPEDIDO.ORIGEMPED, -- Origem do pedido => VarChar2
                                     '', -- Tipo de carga => VarChar2
                                     P_REGPEDIDO.CODFILIAL, -- Código da Filial => VarChar2
                                     P_REGPEDIDO.DATA, -- Data do Pedito => DATE
                                     'S', -- SOMENTEDESCAUT (Somente trazer descontos automáticos) => VarChar2 default "N"
                                     'N', -- PRECOFIXO => VarChar2 default "N"
                                     P_REGITEM.PVENDA, -- Valor do pPVenda => Number default 0
                                     0, -- DescontoPautado => Number default 0
                                     P_REGPEDIDO.CODFILIALNF, -- Código da FilialNF => VarChar2
                                     -- RETORNOS OUT
                                     VSMENSAGEMPOLITICA,
                                     VDDTFIM,
                                     VSALTERAPTABELA,
                                     VNPERCDESCPOLITICA,
                                     VSBASECREDDEBRCA, 
                                     VSCREDITASOBREPOLITICA, 
                                     VNPERCPBASERCA,
                                     VSPRIORITARIA_AUX, 
                                     VSQUESTIONAPRIORITARIA_AUX,
                                     VNCODPOLPBASERCA_561, 
                                     VBEXISTEPOLITICA);
  
            IF VBEXISTEPOLITICA = TRUE AND
               SUBSTR(VSMENSAGEMPOLITICA, 1, 1) NOT IN ('N', 'E') THEN
               SELECT SUBSTR(VSMENSAGEMPOLITICA, INSTR(VSMENSAGEMPOLITICA, ',') + 1, 10)
               INTO VNCODDESC
               FROM DUAL;
               
               BEGIN
                  SELECT NVL(PCDESCONTO.PRIORITARIAGERAL, 'N')
                  INTO VSPRIORITARIAGERAL
                  FROM PCDESCONTO
                  WHERE PCDESCONTO.CODDESCONTO = VNCODDESC;
               EXCEPTION WHEN OTHERS THEN
                  VSPRIORITARIAGERAL := 'N';
               END;

               IF VSPRIORITARIAGERAL = 'S' THEN
                  IF VSMENSAGEMPOLITICA IS NOT NULL AND
                     SUBSTR(VSMENSAGEMPOLITICA, 1, 1) IN ('N', 'E') THEN
                     VSMENSAGEM            := VSMENSAGEM || VSCHAR || VSMENSAGEMPOLITICA;
                     P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 111;
                  END IF;

                  IF P_REGCLIENTE.BLOQUEIO = 'S' AND
                     P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ = 'S' AND
                     P_REGITEM.PVENDA < P_REGPRODUTO.PTABELA AND
                     VNPERCDESCPOLITICA > 0 THEN
                     IF VSMENSAGEM IS NOT NULL THEN
                        VSCHAR := '#';
                     ELSE
                        VSCHAR := NULL;
                     END IF;
                     VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                                   'NAO PERMITIDO APLICAR POLITICAS DE DESC. EM VENDAS DE CLIENTE BLOQUEADO;';

                     P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 63;
                  ELSE
                     VNPERMAXDESC := VNPERCDESCPOLITICA;
                     P_REGORIGEMPRECO.TIPODESCFLEX := '3';
                     P_REGORIGEMPRECO.PERCDESCFLEX := VNPERCDESCPOLITICA;
                     P_REGORIGEMDESC.PRIORITARIAGERAL := 'S';

                     IF SUBSTR(VSMENSAGEMPOLITICA, 1, 1) NOT IN ('N', 'E') THEN
                        SELECT TO_DATE(SUBSTR(VSMENSAGEMPOLITICA, 1, INSTR(VSMENSAGEMPOLITICA, ',') - 1), 'dd/mm/yyyy'),
                               SUBSTR(VSMENSAGEMPOLITICA, INSTR(VSMENSAGEMPOLITICA, ',') + 1, 10)
                        INTO P_REGORIGEMPRECO.DTINICIODESCFLEX,
                             P_REGORIGEMPRECO.CODDESCFLEX
                        FROM DUAL;
                     END IF;

                     P_REGORIGEMPRECO.DTFIMDESCFLEX := VDDTFIM;
                     P_REGITEM.CODDESCONTO          := P_REGORIGEMPRECO.CODDESCFLEX;
                     P_REGORIGEMDESC.PERDESC         := VNPERCDESCPOLITICA;
                     P_REGORIGEMDESC.TIPODESC        := 'F';
                     P_REGORIGEMDESC.CODROTINADESC   := 561;
                     P_REGORIGEMDESC.CODPOLITICADESC := P_REGORIGEMPRECO.CODDESCFLEX;
                     VNPPOLITICA := (ROUND(P_REGPRODUTO.PTABELA, GREGPCCONSUM.NUMCASASDECVENDA)) *
                                    (1 - (VNPERCDESCPOLITICA / 100));
                     VNPPOLITICA := ROUND(VNPPOLITICA, GREGPCCONSUM.NUMCASASDECVENDA);
                     P_REGORIGEMDESC.BASEDEBCREDRCA              := VSBASECREDDEBRCA;
                     P_REGORIGEMDESC.CREDITASOBREPOLITICABASERCA := VSCREDITASOBREPOLITICA;
                     P_REGORIGEMDESC.PRIORITARIA                 := VSPRIORITARIA_AUX;
                     P_REGORIGEMDESC.ALTERAPTABELA               := VSALTERAPTABELA;

                     IF NVL(VSBASECREDDEBRCA, 'N') = 'S' THEN
                        VNPPOLITICA_PBASERCA := (ROUND(P_REGPRODUTO.PTABELA, GREGPCCONSUM.NUMCASASDECVENDA)) *
                                                (1 - (VNPERCPBASERCA / 100));
                        VNPPOLITICA_PBASERCA := ROUND(VNPPOLITICA_PBASERCA, GREGPCCONSUM.NUMCASASDECVENDA);
                        P_REGORIGEMDESC.PERCBASERCA        := VNPERCPBASERCA;
                        P_REGORIGEMDESC.CODROTINABASERCA   := 561;
                        P_REGORIGEMDESC.CODPOLITICABASERCA := VNCODPOLPBASERCA_561;

                        IF NVL(VSCREDITASOBREPOLITICA, 'S') = 'N' AND
                           P_REGITEM.PVENDA > NVL(VNPPOLITICA_PBASERCA, 0) THEN
                           P_REGITEM.PBASERCA := P_REGITEM.PVENDA;
                        ELSE
                           P_REGITEM.PBASERCA := VNPPOLITICA_PBASERCA;
                        END IF;

                        IF VSALTERAPTABELA = 'S' THEN
                           P_REGPRODUTO.PTABELA := VNPPOLITICA;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END IF;

            IF VSPRIORITARIAGERAL = 'N' THEN
               VNPTABELAAUX := P_REGPRODUTO.PTABELA;

               IF GREGPCCONSUM.USADESCPORQUANT = 'S' THEN
                  VSMENSAGEMDESCQUANT := NULL;

                  VBVALIDODESCQUANT := FUNCOESVENDAS.VALIDARDESCONTOQUANTIDADE(0,
                                                                           P_REGITEM.CODPROD,
                                                                           P_REGITEM.QT,
                                                                           P_REGREGIAO.NUMREGIAO,
                                                                           P_REGPRODUTO.PTABELA,
                                                                           P_REGPRECOS.PVENDA1,
                                                                           P_REGCLIENTE.CODPRACA,
                                                                           GREGPCCONSUM.NUMCASASDECVENDA,
                                                                           P_REGPLPAG.NUMDIAS,
                                                                           'A',
                                                                           P_REGPRODUTO.CODPRODPRINC,
                                                                           P_REGPEDIDO.CODCLI,
                                                                           P_REGPEDIDO.CODUSUR,
                                                                           VDDTFIM,
                                                                           VSMENSAGEMDESCQUANT,
                                                                           VNPTABELADESCQUANT,
                                                                           VSCREDITASOBREPTABELA,
                                                                           VNPERCAUX,
                                                                           VSBASECREDDEBRCA_QUANT,
                                                                           VNPERCBASERCA_QUANT,
                                                                           VSPRIORITARIA_AUX,
                                                                           VSQUESTIONAPRIORITARIA_AUX,
                                                                           P_REGPEDIDO.CODFILIAL,
                                                                           VNCODPOLPBASERCA_387,
                                                                           VNCODPOL_387);
              IF VBVALIDODESCQUANT = TRUE THEN
                     IF P_REGCLIENTE.BLOQUEIO = 'S' AND
                        P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ = 'S' AND
                        P_REGITEM.PVENDA < P_REGPRODUTO.PTABELA THEN
                        IF VSMENSAGEM IS NOT NULL THEN
                           VSCHAR := '#';
                        ELSE
                           VSCHAR := NULL;
                        END IF;

                        VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                                      'NAO PERMITIDO APLICAR POLITICAS DE DESC. EM VENDAS DE CLIENTE BLOQUEADO;';
                        P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 63;
                     ELSE
                        P_REGPRODUTO.PTABELA := ROUND(VNPTABELADESCQUANT, GREGPCCONSUM.NUMCASASDECVENDA);
                        VNPTABELAAUX         := P_REGPRODUTO.PTABELA;

                        IF SUBSTR(VSMENSAGEMDESCQUANT, 1, 1) <> 'E' THEN
                           SELECT TO_DATE(SUBSTR(VSMENSAGEMDESCQUANT, 1,
                                          INSTR(VSMENSAGEMDESCQUANT, ',') - 1), 'dd/mm/yyyy'),
                                  REPLACE(SUBSTR(VSMENSAGEMDESCQUANT,
                                          INSTR(VSMENSAGEMDESCQUANT, ',') + 1,
                                          INSTR(VSMENSAGEMDESCQUANT, ',', 12) -
                                          INSTR(VSMENSAGEMDESCQUANT, ',')), ','),
                                  SUBSTR(VSMENSAGEMDESCQUANT, INSTR(VSMENSAGEMDESCQUANT, ',', 12) + 1, 10)
                           INTO P_REGORIGEMPRECO.DTINICIODESCVOLUME,
                                P_REGORIGEMPRECO.INICIOINTERVALO,
                                P_REGORIGEMPRECO.FIMINTERVALO
                           FROM DUAL;
                        END IF;

                        P_REGORIGEMPRECO.DTFIMDESCVOLUME := VDDTFIM;
                        P_REGORIGEMPRECO.PERCDESCVOLUME  := VNPERCAUX;
                        P_REGORIGEMPRECO.CODDESCVOLUME   := VNCODPOL_387;
                        P_REGORIGEMDESC.PERDESC         := VNPERCAUX * (-1); --mudar sinal para ficar no mesmo padrão de gravação da 561
                        P_REGORIGEMDESC.TIPODESC        := 'A';
                        P_REGORIGEMDESC.CODROTINADESC   := 387;
                        P_REGORIGEMDESC.CODPOLITICADESC := VNCODPOL_387;
                        P_REGORIGEMDESC.BASEDEBCREDRCA              := VSBASECREDDEBRCA_QUANT;
                        P_REGORIGEMDESC.CREDITASOBREPOLITICABASERCA := VSCREDITASOBREPTABELA;
                        P_REGORIGEMDESC.PRIORITARIA                 := VSPRIORITARIA_AUX;

                        IF VSBASECREDDEBRCA_QUANT = 'S' THEN
                           P_REGITEM.PBASERCA := (ROUND(VNPTABELAAUX, GREGPCCONSUM.NUMCASASDECVENDA)) *
                                                 (1 + (VNPERCBASERCA_QUANT / 100));
                           P_REGITEM.PBASERCA := ROUND(P_REGITEM.PBASERCA, GREGPCCONSUM.NUMCASASDECVENDA);

                           IF P_REGITEM.PVENDA > NVL(P_REGITEM.PBASERCA, 0) THEN
                              IF NVL(VSCREDITASOBREPTABELA, 'S') = 'N' THEN
                                 P_REGITEM.PBASERCA := P_REGITEM.PVENDA;
                              END IF;
                           END IF;

                           P_REGORIGEMDESC.PERCBASERCA        := VNPERCBASERCA_QUANT * (-1); --mudar sinal para ficar no mesmo padrão de gravação da 561
                           P_REGORIGEMDESC.CODROTINABASERCA   := 387;
                           P_REGORIGEMDESC.CODPOLITICABASERCA := VNCODPOLPBASERCA_387;
                        ELSE
                           P_REGITEM.PBASERCA := P_REGPRODUTO.PTABELA;
                        END IF;
                     END IF;
                  ELSE
                     IF VSMENSAGEMDESCQUANT IS NOT NULL AND
                        SUBSTR(VSMENSAGEMDESCQUANT, 1, 1) = 'E' THEN
                        IF VSMENSAGEM IS NOT NULL THEN
                           VSCHAR := '#';
                        ELSE
                           VSCHAR := NULL;
                        END IF;

                        VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMDESCQUANT;
                        P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 110;
                     END IF;

                     P_REGITEM.PBASERCA := P_REGPRODUTO.PTABELA;
                  END IF;
               END IF;

               VNPERCPBASERCATEMP := NVL(VNPERCBASERCA_QUANT * (-1), 0);
               -- *****Validação de descontos flexiveis
               VNPERMAXDESC := 0;

               IF GREGPCCONSUM.USADESCPORQUANT = 'S' THEN
                  VBVALIDODESCQUANT := FUNCOESVENDAS.VALIDARDESCONTOQUANTIDADE(0,
                                                                           P_REGITEM.CODPROD,
                                                                           P_REGITEM.QT,
                                                                           P_REGREGIAO.NUMREGIAO,
                                                                           P_REGPRODUTO.PTABELA,
                                                                           P_REGPRECOS.PVENDA1,
                                                                           P_REGCLIENTE.CODPRACA,
                                                                           GREGPCCONSUM.NUMCASASDECVENDA,
                                                                           P_REGPLPAG.NUMDIAS,
                                                                           'F',
                                                                           P_REGPRODUTO.CODPRODPRINC,
                                                                           P_REGPEDIDO.CODCLI,
                                                                           P_REGPEDIDO.CODUSUR,
                                                                           VDDTFIM,
                                                                           VSMENSAGEMDESCQUANT,
                                                                           VNPTABELADESCQUANT,
                                                                           VSCREDITASOBREPTABELA,
                                                                           VNPERCQUANTFLEX,
                                                                           VSBASECREDDEBRCA_QUANT,
                                                                           VNPERCBASERCA_QUANT,
                                                                           VSPRIORITARIA_AUX,
                                                                           VSQUESTIONAPRIORITARIA_AUX,
                                                                           P_REGPEDIDO.CODFILIAL,
                                                                           VNCODPOLPBASERCA_387,
                                                                           VNCODPOL_387);
                  IF VNPERCQUANTFLEX < 0 AND
                     (ABS(VNPERCQUANTFLEX) > VNPERMAXDESC) THEN
                     IF P_REGCLIENTE.BLOQUEIO = 'S' AND
                        P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ = 'S' AND
                        P_REGITEM.PVENDA < P_REGPRODUTO.PTABELA THEN
                        
                        IF VSMENSAGEM IS NOT NULL THEN
                           VSCHAR := '#';
                        ELSE
                           VSCHAR := NULL;
                        END IF;

                        VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                                     'NAO PERMITIDO APLICAR POLITICAS DE DESC. EM VENDAS DE CLIENTE BLOQUEADO;';
                        P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 63;
                     ELSE
                        VNPERMAXDESC                   := ABS(VNPERCQUANTFLEX);
                        P_REGORIGEMPRECO.TIPODESCFLEX  := '4';
                        P_REGORIGEMPRECO.PERCDESCFLEX  := ABS(VNPERCQUANTFLEX);
                        P_REGORIGEMPRECO.CODDESCVOLUME := VNCODPOL_387;
                        P_REGORIGEMDESC.PERDESC         := VNPERCQUANTFLEX * (-1); --mudar sinal para ficar no mesmo padrão de gravação da 561
                        P_REGORIGEMDESC.TIPODESC        := 'F';
                        P_REGORIGEMDESC.CODROTINADESC   := 387;
                        P_REGORIGEMDESC.CODPOLITICADESC := VNCODPOL_387;

                        IF SUBSTR(VSMENSAGEMDESCQUANT, 1, 1) <> 'E' THEN
                           SELECT TO_DATE(SUBSTR(VSMENSAGEMDESCQUANT, 1, INSTR(VSMENSAGEMDESCQUANT, ',') - 1), 'dd/mm/yyyy')
                           INTO P_REGORIGEMPRECO.DTINICIODESCFLEX
                           FROM DUAL;
                        END IF;

                        P_REGORIGEMPRECO.DTFIMDESCFLEX := VDDTFIM;
                     END IF;
                  END IF;

                  P_REGORIGEMDESC.BASEDEBCREDRCA              := VSBASECREDDEBRCA_QUANT;
                  P_REGORIGEMDESC.CREDITASOBREPOLITICABASERCA := VSCREDITASOBREPTABELA;
                  P_REGORIGEMDESC.PRIORITARIA                 := VSPRIORITARIA_AUX;

                  IF VSBASECREDDEBRCA_QUANT = 'S' THEN
                     IF NVL(VNPERCBASERCA_QUANT * (-1), 0) > NVL(VNPERCPBASERCATEMP, 0) THEN
                        IF P_REGCLIENTE.BLOQUEIO = 'S' AND
                           P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ = 'S' AND
                           P_REGITEM.PVENDA < P_REGPRODUTO.PTABELA THEN
                           IF VSMENSAGEM IS NOT NULL THEN
                              VSCHAR := '#';
                           ELSE
                              VSCHAR := NULL;
                           END IF;
                            
                           VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                                         'NAO PERMITIDO APLICAR POLITICAS DE DESC. EM VENDAS DE CLIENTE BLOQUEADO;';
                           P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 63;
                        ELSE
                           P_REGITEM.PBASERCA := (ROUND(VNPTABELAAUX, GREGPCCONSUM.NUMCASASDECVENDA)) *
                                                 (1 + (VNPERCBASERCA_QUANT / 100));
                           P_REGITEM.PBASERCA := ROUND(P_REGITEM.PBASERCA, GREGPCCONSUM.NUMCASASDECVENDA);

                           IF P_REGITEM.PVENDA > NVL(P_REGITEM.PBASERCA, 0) THEN
                              IF NVL(VSCREDITASOBREPTABELA, 'S') = 'N' THEN
                                 P_REGITEM.PBASERCA := P_REGITEM.PVENDA;
                              END IF;
                           END IF;

                           P_REGORIGEMDESC.PERCBASERCA        := VNPERCBASERCA_QUANT * (-1); --mudar sinal para ficar no mesmo padrão de gravação da 561
                           P_REGORIGEMDESC.CODROTINABASERCA   := 387;
                           P_REGORIGEMDESC.CODPOLITICABASERCA := VNCODPOLPBASERCA_387;
                           VNPERCPBASERCATEMP := NVL(VNPERCBASERCA_QUANT * (-1), 0);
                        END IF;
                     END IF;
                  END IF;
               END IF;

            IF P_REGPEDIDO.ORIGEMPED = 'R' THEN
              P_REGPRECOS.PERDESCMAX := P_REGPRECOS.PERDESCMAXBALCAO;
            END IF;
            -- escolha do maior desconto - comparacao com desconto da tabela de preços
            IF P_REGPRECOS.PERDESCMAX > VNPERMAXDESC THEN
              VNPERMAXDESC := P_REGPRECOS.PERDESCMAX;

              P_REGORIGEMDESC.PERDESC         := P_REGPRECOS.PERDESCMAX;
              P_REGORIGEMDESC.TIPODESC        := 'F';
              P_REGORIGEMDESC.CODROTINADESC   := 201;
              P_REGORIGEMDESC.CODPOLITICADESC := NULL;
            END IF;
            -- escolha do maior desconto - comparacao com desconto do cliente
            IF P_REGCLIENTE.PERDESC > VNPERMAXDESC THEN
              VNPERMAXDESC := P_REGCLIENTE.PERDESC;

              P_REGORIGEMDESC.PERDESC         := P_REGCLIENTE.PERDESC;
              P_REGORIGEMDESC.TIPODESC        := 'F';
              P_REGORIGEMDESC.CODROTINADESC   := 302;
              P_REGORIGEMDESC.CODPOLITICADESC := NULL;
            END IF;
            -- politica de descontos
            VSMENSAGEMPOLITICA := NULL;
            PROC_DESCONTO_ITEM_VENDA(P_REGPEDIDO.CODCLI, -- Código Cliente => Number
                                     P_REGITEM.CODPROD, -- Código Produto => Number
                                     P_REGPEDIDO.CODPLPAG, -- Código Plano Pagamento => Number
                                     P_REGPEDIDO.CODUSUR, -- Código Usuário => Number
                                     0, -- Percentual Informado => Number
                                     P_REGPRODUTO.PTABELA, -- Valor do PTabela => Number
                                     P_REGPRODUTO.PTABELA, -- Valor do PTabela => Number
                                     P_REGITEM.QT, -- Quantidade de itens informado no item do produto => Number
                                     P_REGPEDIDO.ORIGEMPED, -- Origem do pedido => VarChar2
                                     '', -- Tipo de carga => VarChar2
                                     P_REGPEDIDO.CODFILIAL, -- Código da Filial => VarChar2
                                     P_REGPEDIDO.DATA, -- Data do Pedito => DATE
                                     'S', -- SOMENTEDESCAUT (Somente trazer descontos automáticos) => VarChar2 default "N"
                                     'N', -- PRECOFIXO => VarChar2 default "N"
                                     P_REGITEM.PVENDA, -- Valor do pPVenda => Number default 0
                                     0, -- DescontoPautado => Number default 0
                                     P_REGPEDIDO.CODFILIALNF, -- Código da FilialNF => VarChar2
                                     -- RETORNOS OUT
                                     VSMENSAGEMPOLITICA,
                                     VDDTFIM,
                                     VSALTERAPTABELA,
                                     VNPERCDESCPOLITICA,
                                     VSBASECREDDEBRCA, 
                                     VSCREDITASOBREPOLITICA, 
                                     VNPERCPBASERCA,
                                     VSPRIORITARIA_AUX, 
                                     VSQUESTIONAPRIORITARIA_AUX,
                                     VNCODPOLPBASERCA_561, 
                                     VBEXISTEPOLITICA);

            IF VSMENSAGEMPOLITICA IS NOT NULL AND
               SUBSTR(VSMENSAGEMPOLITICA, 1, 1) IN ('N', 'E') THEN
               VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMPOLITICA;
               P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 111;
            END IF;

            IF P_REGCLIENTE.BLOQUEIO = 'S' AND
               P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ = 'S' AND
               P_REGITEM.PVENDA < P_REGPRODUTO.PTABELA AND
               VNPERCDESCPOLITICA > 0 THEN
               IF VSMENSAGEM IS NOT NULL THEN
                  VSCHAR := '#';
               ELSE
                  VSCHAR := NULL;
               END IF;

               VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                             'NAO PERMITIDO APLICAR POLITICAS DE DESC. EM VENDAS DE CLIENTE BLOQUEADO;';
               P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 63;
            ELSE
              BEGIN
                SELECT SUBSTR(VSMENSAGEMPOLITICA, INSTR(VSMENSAGEMPOLITICA, ',') + 1, 10)
                  INTO VNCODDESCFLEX
                  FROM DUAL;
              EXCEPTION
                WHEN OTHERS THEN
                  VNCODDESCFLEX := NULL;
              END;

              BEGIN
                SELECT P.APLICADESCONTO
                  INTO VSAPLICADESCONTO
                  FROM PCDESCONTO P
                 WHERE P.CODDESCONTO = VNCODDESCFLEX;
              EXCEPTION
                WHEN OTHERS THEN
                  VSAPLICADESCONTO := NULL;
              END;

              IF VNPERCDESCPOLITICA > VNPERMAXDESC THEN
                IF VSAPLICADESCONTO = 'N' THEN
                  VNPERMAXDESC := VNPERCDESCPOLITICA;
                END IF;

                P_REGORIGEMPRECO.TIPODESCFLEX := '3';
                P_REGORIGEMPRECO.PERCDESCFLEX := VNPERCDESCPOLITICA;

                IF SUBSTR(VSMENSAGEMPOLITICA, 1, 1) NOT IN ('N', 'E') THEN
                  SELECT TO_DATE(SUBSTR(VSMENSAGEMPOLITICA, 1,
                                        INSTR(VSMENSAGEMPOLITICA, ',') - 1), 'dd/mm/yyyy'),
                         SUBSTR(VSMENSAGEMPOLITICA, INSTR(VSMENSAGEMPOLITICA, ',') + 1, 10)
                    INTO P_REGORIGEMPRECO.DTINICIODESCFLEX,
                         P_REGORIGEMPRECO.CODDESCFLEX
                    FROM DUAL;
                END IF;

                P_REGORIGEMPRECO.DTFIMDESCFLEX := VDDTFIM;
                P_REGORIGEMDESC.PERDESC         := VNPERCDESCPOLITICA;
                P_REGORIGEMDESC.TIPODESC        := 'F';
                P_REGORIGEMDESC.CODROTINADESC   := 561;
                P_REGORIGEMDESC.CODPOLITICADESC := P_REGORIGEMPRECO.CODDESCFLEX;
                P_REGITEM.CODDESCONTO           := P_REGORIGEMPRECO.CODDESCFLEX;
              END IF;

              IF NVL(VNPERCDESCPOLITICA_ACRES, 0) > 0 THEN
                VNPPOLITICA := (ROUND(P_REGPRODUTO.PTABELA, GREGPCCONSUM.NUMCASASDECVENDA)) *
                               (1 + (VNPERCDESCPOLITICA_ACRES / 100));
                VNPPOLITICA := ROUND(VNPPOLITICA, GREGPCCONSUM.NUMCASASDECVENDA);
              END IF;

              IF VNPERCDESCPOLITICA > 0 THEN
                VNPPOLITICA := (ROUND(P_REGPRODUTO.PTABELA, GREGPCCONSUM.NUMCASASDECVENDA)) *
                               (1 - (VNPERCDESCPOLITICA / 100));
                VNPPOLITICA := ROUND(VNPPOLITICA, GREGPCCONSUM.NUMCASASDECVENDA);
              END IF;

              P_REGORIGEMDESC.BASEDEBCREDRCA              := VSBASECREDDEBRCA;
              P_REGORIGEMDESC.CREDITASOBREPOLITICABASERCA := VSCREDITASOBREPOLITICA;
              P_REGORIGEMDESC.PRIORITARIA                 := VSPRIORITARIA_AUX;
              P_REGORIGEMDESC.ALTERAPTABELA               := VSALTERAPTABELA;
              
              IF NVL(VSBASECREDDEBRCA, 'N') = 'S' THEN
                IF NVL(VNPERCPBASERCA, 0) > NVL(VNPERCPBASERCATEMP, 0) THEN
                  VNPPOLITICA_PBASERCA := (ROUND(VNPTABELAAUX, GREGPCCONSUM.NUMCASASDECVENDA)) *
                                          (1 - (VNPERCPBASERCA / 100));
                  VNPPOLITICA_PBASERCA := ROUND(VNPPOLITICA_PBASERCA, GREGPCCONSUM.NUMCASASDECVENDA);

                  IF NVL(VSCREDITASOBREPOLITICA, 'S') = 'N' AND
                     P_REGITEM.PVENDA > NVL(VNPPOLITICA_PBASERCA, 0) THEN
                    P_REGITEM.PBASERCA := P_REGITEM.PVENDA;
                  ELSE
                    P_REGITEM.PBASERCA := VNPPOLITICA_PBASERCA;
                  END IF;

                  P_REGORIGEMDESC.PERCBASERCA        := VNPERCPBASERCA;
                  P_REGORIGEMDESC.CODROTINABASERCA   := 561;
                  P_REGORIGEMDESC.CODPOLITICABASERCA := VNCODPOLPBASERCA_561;

                  VNPERCPBASERCATEMP := NVL(VNPERCPBASERCA, 0);

                  IF VSALTERAPTABELA = 'S' THEN
                    P_REGPRODUTO.PTABELA := VNPPOLITICA;
                  END IF;
                END IF;
              ELSE
                PROC_DESCONTO_ITEM_VENDA(P_REGPEDIDO.CODCLI, -- Código Cliente => Number
                                         P_REGITEM.CODPROD, -- Código Produto => Number
                                         P_REGPEDIDO.CODPLPAG, -- Código Plano Pagamento => Number
                                         P_REGPEDIDO.CODUSUR, -- Código Usuário => Number
                                         0, -- Percentual Informado => Number
                                         P_REGPRODUTO.PTABELA, -- Valor do PTabela => Number
                                         P_REGPRODUTO.PTABELA, -- Valor do PTabela => Number
                                         P_REGITEM.QT, -- Quantidade de itens informado no item do produto => Number
                                         P_REGPEDIDO.ORIGEMPED, -- Origem do pedido => VarChar2
                                         '', -- Tipo de carga => VarChar2
                                         P_REGPEDIDO.CODFILIAL, -- Código da Filial => VarChar2
                                         P_REGPEDIDO.DATA, -- Data do Pedito => DATE
                                         'S', -- SOMENTEDESCAUT (Somente trazer descontos automáticos) => VarChar2 default "N"
                                         'N', -- PRECOFIXO => VarChar2 default "N"
                                         P_REGITEM.PVENDA, -- Valor do pPVenda => Number default 0
                                         0, -- DescontoPautado => Number default 0
                                         P_REGPEDIDO.CODFILIALNF, -- Código da FilialNF => VarChar2
                                         -- RETORNOS OUT
                                         VSMENSAGEMPOLITICA,
                                         VDDTFIM,
                                         VSALTERAPTABELA,
                                         VNPERCDESCPOLITICA,
                                         VSBASECREDDEBRCA, 
                                         VSCREDITASOBREPOLITICA, 
                                         VNPERCPBASERCA,
                                         VSPRIORITARIA_AUX, 
                                         VSQUESTIONAPRIORITARIA_AUX,
                                         VNCODPOLPBASERCA_561, 
                                         VBEXISTEPOLITICA);

                P_REGORIGEMDESC.BASEDEBCREDRCA              := VSBASECREDDEBRCA;
                P_REGORIGEMDESC.CREDITASOBREPOLITICABASERCA := VSCREDITASOBREPOLITICA;
                P_REGORIGEMDESC.PRIORITARIA                 := VSPRIORITARIA_AUX;
                P_REGORIGEMDESC.ALTERAPTABELA               := VSALTERAPTABELA;

                IF NVL(VSBASECREDDEBRCA, 'N') = 'S' THEN
                  VNPPOLITICA_PBASERCA := (ROUND(P_REGPRODUTO.PTABELA, GREGPCCONSUM.NUMCASASDECVENDA)) *
                                          (1 - (VNPERCPBASERCA / 100));
                  VNPPOLITICA_PBASERCA := ROUND(VNPPOLITICA_PBASERCA, GREGPCCONSUM.NUMCASASDECVENDA);

                  IF NVL(VSCREDITASOBREPOLITICA, 'S') = 'N' AND
                     P_REGITEM.PVENDA > NVL(VNPPOLITICA_PBASERCA, 0) THEN
                    P_REGITEM.PBASERCA := P_REGITEM.PVENDA;
                  ELSE
                    P_REGITEM.PBASERCA := VNPPOLITICA_PBASERCA;
                  END IF;

                  P_REGORIGEMDESC.PERCBASERCA        := VNPERCPBASERCA;
                  P_REGORIGEMDESC.CODROTINABASERCA   := 561;
                  P_REGORIGEMDESC.CODPOLITICABASERCA := VNCODPOLPBASERCA_561;
                  P_REGITEM.CODDESCONTO              := P_REGORIGEMPRECO.CODDESCFLEX;
                END IF;

                IF VSALTERAPTABELA = 'S' THEN
                  P_REGPRODUTO.PTABELA := VNPPOLITICA;
                END IF;
              END IF;
            END IF;
            END IF;

            VSMENSAGEMPRECOFIXO := NULL;

            P_REGITEM.APLICADESCONTOSIMPLES := 'S';

            VBVALIDOPRECOFIXO := FUNCOESVENDAS.VALIDARPOLITICAPRECOFIXO(P_REGITEM.CODPROD,
                                                                      P_REGPEDIDO.DATA,
                                                                      P_REGCLIENTE.NUMREGIAO,
                                                                      P_REGPEDIDO.CODCLI,
                                                                      P_REGPEDIDO.CONDVENDA,
                                                                      P_REGPEDIDO.CODPLPAG,
                                                                      P_REGPRODUTO.PTABELA,
                                                                      GREGPCCONSUM.VALIDAPVENDABONIFIC,
                                                                      GREGPCCONSUM.UTILIZAPERCFINPRECOPROM,
                                                                      P_REGPLPAG.PERTXFIM,
                                                                      P_REGPLPAG.NUMDIAS,
                                                                      P_REGCLIENTE.CODCLIPRINC,
                                                                      P_REGPRODUTO.CODPRODPRINC,
                                                                      P_REGCLIENTE.CODPRACA,
                                                                      P_REGPEDIDO.CODUSUR,
                                                                      P_REGRCA.CODSUPERVISOR,
                                                                      NULL,
                                                                      P_REGPEDIDO.ORIGEMPED,
                                                                      P_REGCLIENTE.CODATV1,
                                                                      VDDTFIM,
                                                                      VSMENSAGEMPRECOFIXO,
                                                                      VNPRECOFIXO,
                                                                      P_REGPEDIDO.CODFILIAL,
                                                                      'S',
                                                                      P_REGFILIAL.BROKER,
                                                                      P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM,
                                                                      P_REGFILIAL.PRECOPOREMBALAGEM,
                                                                      P_REGPLPAG.CODPLPAG);
            IF VBVALIDOPRECOFIXO = TRUE THEN
               P_REGPRODUTO.PTABELA := VNPRECOFIXO;
               P_REGITEM.PBASERCA   := VNPRECOFIXO;
               P_REGORIGEMPRECO.ORIGEMPRECO  := '10';
               P_REGORIGEMPRECO.PORIGINAL    := VNPRECOFIXO;
               P_REGORIGEMPRECO.CODPRECOFIXO := VSMENSAGEMPRECOFIXO;
               P_REGORIGEMDESC.PTABELA   := VNPRECOFIXO;
               P_REGORIGEMDESC.PRECOFIXO := 'S';

               IF P_REGPRECOS.USAVALORULTENTBASEST = 'S' AND
                  P_REGCLIENTE.ESTENT = P_REGFILIAL.UF AND
                  P_REGPRECOS.PERCBASESTRJ <> 0 THEN
                  P_REGITEM.PVENDA      := VNPVENDAORIG; --não retirar impostos neste caso, utilizar o preço enviado na pcpedifv
                  P_REGITEM.PERCIMPOSTO := 0;
                  VNPERCIMPOSTOPTABELA  := 0;
               ELSE
                  --RETIRAR IMPOSTOS PREÇO FIXO
                  P_REGPRODUTO.PTABELA := P_REGPRODUTO.PTABELA * (1 - NVL(P_REGITEM.PERCIMPOSTO, 0) / 100);
                  P_REGITEM.PBASERCA   := P_REGITEM.PBASERCA * (1 - NVL(P_REGITEM.PERCIMPOSTO, 0) / 100);
               END IF;

               SELECT NVL(PCPRECOPROM.APLICADESCONTOSIMPLES, 'S')
               INTO P_REGITEM.APLICADESCONTOSIMPLES
               FROM PCPRECOPROM
               WHERE PCPRECOPROM.CODPRECOPROM = P_REGORIGEMPRECO.CODPRECOFIXO;

               IF NVL(GREGPCCONSUM.ACEITADESCPRECOFIXO, 'N') = 'N' THEN
                  VNPERMAXDESC := 0;
               END IF;

               IF NVL(GREGPCCONSUM.ACEITAACRESCIMOPRECOFIXO, 'N') = 'N' THEN
                  VNPERMAXVENDA := 0;
               END IF;
            ELSE
               IF VSMENSAGEMPRECOFIXO IS NOT NULL AND SUBSTR(VSMENSAGEMPRECOFIXO, 1, 1) = 'E' THEN
                  VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMPRECOFIXO;
                  P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 112;
               END IF;
            END IF;

            IF P_REGITEM.CESTA = 'S' AND
               (P_REGPRODUTO.PTABELA <> VNPTABELACESTA) AND VBVALIDOPRECOFIXOCESTA = FALSE THEN
               VNPERDESCCESTA := 0;
               IF NVL(VNPTABELACESTA,0) <> 0 THEN
                  VNPERDESCCESTA := ((VNPTABELACESTA - P_REGPRODUTO.PTABELA) / VNPTABELACESTA);
               END IF;
             
               VNSUBTOTAL    := 0;
               VNPVENDAMAIOR := 0;
               VNCOUNT := GVET_REGITENSCESTA.COUNT;

               FOR I IN 1 .. VNCOUNT LOOP
                  IF P_REGPEDIDO.NUMPED = GVET_REGITENSCESTA(I).NUMPED AND 
                     P_REGITEM.CODPROD = GVET_REGITENSCESTA(I).CODPRODCESTA THEN
                     GVET_REGITENSCESTA(I).PVENDA := ROUND(GVET_REGITENSCESTA(I).PVENDA -
                                                           (GVET_REGITENSCESTA(I).PVENDA * VNPERDESCCESTA), GREGPCCONSUM.NUMCASASDECVENDA);

                     GVET_REGITENSCESTA(I).PTABELA := ROUND(GVET_REGITENSCESTA(I).PTABELA -
                                                            (GVET_REGITENSCESTA(I).PTABELA * VNPERDESCCESTA), GREGPCCONSUM.NUMCASASDECVENDA);
                     VNSUBTOTAL := VNSUBTOTAL + (GVET_REGITENSCESTA(I).PVENDA * GVET_REGITENSCESTA(I).QT);

                     IF GVET_REGITENSCESTA(I).PVENDA > VNPVENDAMAIOR THEN
                        VNPVENDAMAIOR := GVET_REGITENSCESTA(I).PVENDA;
                        VNREG         := I;
                     END IF;
                  END IF;
               END LOOP;

               IF VNSUBTOTAL <> P_REGPRODUTO.PTABELA THEN
                  VNDIF := 0;
                  IF NVL(GVET_REGITENSCESTA(VNREG).QT,0) <> 0 THEN
                     VNDIF := (P_REGPRODUTO.PTABELA - VNSUBTOTAL) / GVET_REGITENSCESTA(VNREG).QT;
                  END IF;
  
                  GVET_REGITENSCESTA(VNREG).PVENDA := ROUND(GVET_REGITENSCESTA(VNREG).PVENDA + VNDIF, GREGPCCONSUM.NUMCASASDECVENDA);
                  GVET_REGITENSCESTA(VNREG).PTABELA := ROUND(GVET_REGITENSCESTA(VNREG).PTABELA + VNDIF, GREGPCCONSUM.NUMCASASDECVENDA);
               END IF;
            END IF;

            IF P_REGITEM.CESTA = 'S' AND (P_REGITEM.PVENDA <> P_REGPRODUTO.PTABELA) THEN
               VNPERDESCCESTA := 0;
               IF NVL(P_REGPRODUTO.PTABELA,0) <> 0 THEN
                  VNPERDESCCESTA := ((P_REGPRODUTO.PTABELA - P_REGITEM.PVENDA) / P_REGPRODUTO.PTABELA);
               END IF;
            
               VNSUBTOTAL    := 0;
               VNPVENDAMAIOR := 0;
               VNDIF         := 0;
               VNCOUNT       := GVET_REGITENSCESTA.COUNT;

               FOR I IN 1 .. VNCOUNT LOOP
                  IF P_REGPEDIDO.NUMPED = GVET_REGITENSCESTA(I).NUMPED AND 
                     P_REGITEM.CODPROD = GVET_REGITENSCESTA(I).CODPRODCESTA THEN
                     GVET_REGITENSCESTA(I).PVENDA := ROUND(GVET_REGITENSCESTA(I).PVENDA -
                                                           (GVET_REGITENSCESTA(I).PVENDA * VNPERDESCCESTA), GREGPCCONSUM.NUMCASASDECVENDA);
                     VNSUBTOTAL := VNSUBTOTAL + (GVET_REGITENSCESTA(I).PVENDA * GVET_REGITENSCESTA(I).QT);

                     IF GVET_REGITENSCESTA(I).PVENDA > VNPVENDAMAIOR THEN
                        VNPVENDAMAIOR := GVET_REGITENSCESTA(I).PVENDA;
                        VNREG         := I;
                     END IF;
                  END IF;
               END LOOP;

               IF VNSUBTOTAL <> P_REGITEM.PVENDA THEN
                  VNDIF := 0;
                  IF NVL(GVET_REGITENSCESTA(VNREG).QT,0) <> 0 THEN
                     VNDIF := (P_REGITEM.PVENDA - VNSUBTOTAL) / GVET_REGITENSCESTA(VNREG).QT;
                  END IF;

                  GVET_REGITENSCESTA(VNREG).PVENDA := ROUND(GVET_REGITENSCESTA(VNREG).PVENDA + VNDIF, GREGPCCONSUM.NUMCASASDECVENDA);
               END IF;
            END IF;
            -- calculo preco minimo		  
            IF P_REGITEM.INTEGRADORA <> 23 THEN 
               VNPVENDAMIN := (ROUND(P_REGPRODUTO.PTABELA * (1 + NVL(VNPERCIMPOSTOPTABELA, P_REGITEM.PERCIMPOSTO) / 100), GREGPCCONSUM.NUMCASASDECVENDA)) *
                              (1 - (VNPERMAXDESC / 100));
               VNPVENDAMIN := ROUND(VNPVENDAMIN, GREGPCCONSUM.NUMCASASDECVENDA);
            END IF; 
		  
            IF NVL(GREGPCCONSUM.TRATARRESTRICAOACRESCIMO, 'N') = 'S' THEN
               VNPERMAXVENDA := NVL(GREGPCCONSUM.PERMAXVENDA, 0);

               IF VNPERMAXVENDA <
                  NVL(NVL(P_REGRCA.PERCACRESFV, P_REGRCA.PERMAXVENDA), 0) THEN
                  VNPERMAXVENDA := NVL(NVL(P_REGRCA.PERCACRESFV, P_REGRCA.PERMAXVENDA), 100);
               END IF;

               IF NVL(VNPERCDESCPOLITICA_ACRES, 0) > VNPERMAXVENDA THEN
                  VNPERMAXVENDA := VNPERCDESCPOLITICA_ACRES;
               END IF;
            ELSE
               VNPERMAXVENDA := NVL(GREGPCCONSUM.PERMAXVENDA, 100);

               IF NVL(NVL(P_REGRCA.PERCACRESFV, P_REGRCA.PERMAXVENDA), 0) > 0 THEN
                  VNPERMAXVENDA := NVL(NVL(P_REGRCA.PERCACRESFV, P_REGRCA.PERMAXVENDA), 0);
               END IF;
            END IF;
            -- calculo preco maximo
            VNPVENDAMAX := (ROUND(P_REGPRODUTO.PTABELA * (1 + NVL(VNPERCIMPOSTOPTABELA, P_REGITEM.PERCIMPOSTO) / 100), GREGPCCONSUM.NUMCASASDECVENDA)) *
                           (1 + VNPERMAXVENDA / 100);
            VNPVENDAMAX := ROUND(VNPVENDAMAX, GREGPCCONSUM.NUMCASASDECVENDA);
            VNPTABELA_ANT := P_REGPRODUTO.PTABELA;

            IF P_REGFILIAL.BROKER = 'N' THEN
               IF P_REGPEDIDO.CONDVENDA NOT IN (10, 20) OR
                  (P_REGPEDIDO.CONDVENDA = 20 AND
                   P_REGFILIAL.VALIDARPRECOVENDATV20 = 'S') THEN
                  -- verifica desconto permitido
                  IF ROUND((P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)), GREGPCCONSUM.NUMCASASDECVENDA) < VNPVENDAMIN AND
                     (VSRETIROUIMPOSTO = FALSE OR (VSRETIROUIMPOSTO = TRUE AND
                     (VNPVENDAMIN - (P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100))) > NVL(VNVLDIFST201, 0) + 0.03)) THEN
                     VNPBASERCA := ROUND((P_REGITEM.PBASERCA * (1 + NVL(VNPERCIMPOSTOPTABELA,
                                          P_REGITEM.PERCIMPOSTO) / 100)), GREGPCCONSUM.NUMCASASDECVENDA);

                     VBVALIDO_AUTORI := FUNCOESVENDAS.VALIDARAUTORIZACAOVENDA(P_REGPEDIDO.NUMPED,
                                                                         P_REGPEDIDO.CODCLI,
                                                                         P_REGPEDIDO.CODUSUR,
                                                                         P_REGPEDIDO.CODPLPAG,
                                                                         8888,
                                                                         P_REGITEM.CODPROD,
                                                                         ROUND((VNPTABELA_ANT * (1 + NVL(VNPERCIMPOSTOPTABELA,
                                                                                P_REGITEM.PERCIMPOSTO) / 100)), GREGPCCONSUM.NUMCASASDECVENDA),
                                                                         ROUND((P_REGPRODUTO.PTABELA * (1 + NVL(VNPERCIMPOSTOPTABELA,
                                                                                P_REGITEM.PERCIMPOSTO) / 100)), GREGPCCONSUM.NUMCASASDECVENDA),
                                                                         ROUND((P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)), GREGPCCONSUM.NUMCASASDECVENDA),
                                                                         P_REGITEM.CODAUXILIAR,
                                                                         VNPERMAXDESC,
                                                                         GREGPCCONSUM.NUMCASASDECVENDA,
                                                                         P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM,
                                                                         VNPBASERCA,
                                                                         VNPVENDAMIN,
                                                                         P_REGITEM.PERCOM,
                                                                         VSMENSAGEMAUTORI);
                     IF P_REGPEDIDO.TIPOINTEGRACAO = 'W' THEN
                        VBVALIDO_AUTORI := TRUE;
                     END IF;

                     IF VBVALIDO_AUTORI = FALSE THEN
                        IF P_REGFILIAL.ACEITADESCTMKFV = 'S' THEN
                           P_REGPEDIDO.POSICAO       := 'B';
                           P_REGPEDIDO.CODMOTIVO     := 5;
                           P_REGPEDIDO.MOTIVOPOSICAO := P_REGITEM.CODPROD || '- Item com desconto acima do permitido';

                           IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
                              P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || P_REGITEM.CODPROD ||
                                                 '- Item com desconto acima do permitido';
                           END IF;

                           IF P_REGPEDIDO.POSICAO = 'B' THEN
                              PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                           END IF;
                        ELSIF P_REGFILIAL.ACEITADESCTMKFV = 'RP' THEN
                           P_REGPEDIDO.VALIDO := FALSE;

                           IF P_REGPEDIDO.VBEXISTEITEMCOMDESC = FALSE THEN
                              P_REGPEDIDO.VBEXISTEITEMCOMDESC := TRUE;

                              PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                       P_REGPEDIDO.NUMPEDINT,
                                       NULL,
                                       NULL,
                                       NULL,
                                       P_REGPEDIDO.CODCLI,
                                       P_REGPEDIDO.CODUSUR,
                                       NULL,
                                       NULL,
                                       P_REGPEDIDO.INTEGRADORA,
                                       NULL,
                                       '2',
                                       'Pedido possui item com desconto acima do permitido.',
                                       NULL);
                           END IF;
                        ELSE
                           P_REGITEM.VALIDO        := VBVALIDO_AUTORI;
                           P_REGORIGEMPRECO.VALIDO := VBVALIDO_AUTORI;
                        END IF;

                  P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 113;
                     ELSE
                  BEGIN
                    SELECT PCAUTORI.NRAUTORIZACAO,
                           PCAUTORI.PERCDESCAUTOR,
                           PCAUTORI.DATAAUTORIZACAO,
                           PCAUTORI.INICIOINTERVALO,
                           PCAUTORI.FIMINTERVALO
                      INTO VNNRAUTORIZACAO,
                           VNPERCDESCAUTOR,
                           VDDATAAUTORI,
                           VNINICIOINTERVALO,
                           VNFIMINTERVALO
                      FROM PCAUTORI
                     WHERE DATA_UTILIZACAO = TRUNC(SYSDATE)
                       AND STATUSUTILIZ = 'S'
                       AND NUMPED = P_REGPEDIDO.NUMPED
                       AND PVENDIDO = ROUND((P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)), GREGPCCONSUM.NUMCASASDECVENDA);
                  EXCEPTION
                    WHEN OTHERS THEN
                      VNNRAUTORIZACAO   := NULL;
                      VNPERCDESCAUTOR   := NULL;
                      VDDATAAUTORI      := NULL;
                      VNINICIOINTERVALO := NULL;
                      VNFIMINTERVALO    := NULL;
                  END;

                  P_REGITEM.PBASERCA := ROUND((P_REGITEM.PBASERCA * (1 - NVL(VNPERCIMPOSTOPTABELA, P_REGITEM.PERCIMPOSTO) / 100)), GREGPCCONSUM.NUMCASASDECVENDA);

                  P_REGORIGEMPRECO.CODAUTORIZACAO        := VNNRAUTORIZACAO;
                  P_REGORIGEMPRECO.PERCDESCAUTOR         := VNPERCDESCAUTOR;
                  P_REGORIGEMPRECO.DTINICIOAUTOR         := VDDATAAUTORI;
                  P_REGORIGEMPRECO.DTFIMAUTOR            := VDDATAAUTORI;
                  P_REGORIGEMPRECO.INICIOINTERVALOAUTORI := VNINICIOINTERVALO;
                  P_REGORIGEMPRECO.FIMINTERVALOAUTORI    := VNFIMINTERVALO;
                  P_REGORIGEMPRECO.TIPODESCFLEX          := '5';
                  P_REGORIGEMPRECO.PERCDESCFLEX          := VNPERCDESCAUTOR;
                  P_REGORIGEMPRECO.DTINICIODESCFLEX      := VDDATAAUTORI;
                  P_REGORIGEMPRECO.DTFIMDESCFLEX         := VDDATAAUTORI;
                  P_REGORIGEMPRECO.CODDESCFLEX           := VNNRAUTORIZACAO;
                     END IF;

                     IF VSMENSAGEMAUTORI IS NOT NULL THEN
                        IF VSMENSAGEM IS NOT NULL THEN
                           VSCHAR := '#';
                        ELSE
                           VSCHAR := NULL;
                        END IF;

                        VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMAUTORI;
                     END IF;
                  END IF;
                  -- verifica preco minimo permitido
                  IF ROUND((P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)),
                          GREGPCCONSUM.NUMCASASDECVENDA) < ROUND(P_REGPRECOS.PRECOMINIMOVENDA, GREGPCCONSUM.NUMCASASDECVENDA) THEN
                     IF VSMENSAGEM IS NOT NULL THEN
                        VSCHAR := '#';
                     ELSE
                        VSCHAR := NULL;
                     END IF;

                     VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PRECO ABAIXO DO PRECO MINIMO;';
                     VSMENSAGEM := VSMENSAGEM || 'PRECO DE VENDA: ' ||
                                   ROUND((P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)), GREGPCCONSUM.NUMCASASDECVENDA) || ';';
                     VSMENSAGEM := VSMENSAGEM || 'PRECO TABELA  : ' ||
                                   ROUND((P_REGPRODUTO.PTABELA * (1 + NVL(VNPERCIMPOSTOPTABELA, P_REGITEM.PERCIMPOSTO) / 100)), GREGPCCONSUM.NUMCASASDECVENDA) || ';';
                     VSMENSAGEM := VSMENSAGEM || 'PRECO MINIMO  : ' || ROUND(P_REGPRECOS.PRECOMINIMOVENDA, GREGPCCONSUM.NUMCASASDECVENDA) || ';';

                     IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
                        P_REGITEM.VALIDO        := FALSE;
                        P_REGORIGEMPRECO.VALIDO := FALSE;
                     ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
                        P_REGPEDIDO.VALIDO := FALSE;
                     ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                        P_REGPEDIDO.POSICAO   := 'B';
                        P_REGPEDIDO.CODMOTIVO := 5;

                        IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR P_REGPEDIDO.LOG IS NULL THEN
                           P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Item com preco abaixo do preco minimo';
                        END IF;

                        P_REGPEDIDO.MOTIVOPOSICAO := 'Item com preco abaixo do preco minimo';

                        IF P_REGPEDIDO.POSICAO = 'B' THEN
                           PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                        END IF;
                     END IF;

                     P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 114;
                  END IF;
                  -- verifica preco maximo
                  IF (P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)) > VNPVENDAMAX AND
                     (VSRETIROUIMPOSTO = FALSE OR (VSRETIROUIMPOSTO = TRUE AND
                     ((P_REGITEM.PVENDA * (1 + P_REGITEM.PERCIMPOSTO / 100)) - VNPVENDAMAX) > NVL(VNVLDIFST201, 0) + 0.03)) AND (P_REGITEM.TIPOINTEGRACAO <> 'W') THEN
                     IF VSMENSAGEM IS NOT NULL THEN
                        VSCHAR := '#';
                     ELSE
                        VSCHAR := NULL;
                     END IF;

                     VSMENSAGEM := VSMENSAGEM || VSCHAR || 'PRECO ACIMA DO PERMITIDO;';
                     VSMENSAGEM := VSMENSAGEM || 'PRECO DE VENDA: ' ||
                                   ROUND((P_REGITEM.PVENDA *
                                         (1 + P_REGITEM.PERCIMPOSTO / 100)), GREGPCCONSUM.NUMCASASDECVENDA) || ';';
                     VSMENSAGEM := VSMENSAGEM || 'PRECO TABELA  : ' ||
                                   ROUND((P_REGPRODUTO.PTABELA * (1 +
                                         NVL(VNPERCIMPOSTOPTABELA, P_REGITEM.PERCIMPOSTO) / 100)), GREGPCCONSUM.NUMCASASDECVENDA) || ';';
                     VSMENSAGEM := VSMENSAGEM || 'ACRESCIMO(%)  : ' || NVL(VNPERMAXVENDA, 100) || ';';
                     VSMENSAGEM := VSMENSAGEM || 'PRECO MAXIMO  : ' || VNPVENDAMAX || ';';

                     IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
                        P_REGITEM.VALIDO        := FALSE;
                        P_REGORIGEMPRECO.VALIDO := FALSE;
                     ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
                        P_REGPEDIDO.VALIDO := FALSE;
                     ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                        P_REGPEDIDO.POSICAO   := 'B';
                        P_REGPEDIDO.CODMOTIVO := 6;

                        IF LENGTH(P_REGPEDIDO.LOG) <= 3000 OR
                           P_REGPEDIDO.LOG IS NULL THEN
                           P_REGPEDIDO.LOG := P_REGPEDIDO.LOG || CHR(13) || 'Item com preco acima do permitido';
                        END IF;

                        P_REGPEDIDO.MOTIVOPOSICAO := 'Item com preco acima do permitido';

                        IF P_REGPEDIDO.POSICAO = 'B' THEN
                           PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
                        END IF;
                     END IF;

                     P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 115;
                  END IF;
               END IF;
            END IF;
         END IF;

         IF P_REGPEDIDO.CONDVENDA IN (5, 6, 11, 12) THEN
            IF GREGPCCONSUM.USAPTABELACOMOBASE = 'S' THEN
               P_REGITEM.PBASERCA := P_REGPRODUTO.PTABELA;
            ELSE
               P_REGITEM.PBASERCA := P_REGITEM.PVENDA;
            END IF;
         END IF;
      END IF;
   END IF;

   IF P_REGPEDIDO.INTEGRADORA <> 23 THEN
      -- registra log
      IF (VSMENSAGEM IS NOT NULL) THEN
         PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                          P_REGPEDIDO.NUMPEDINT,
                          P_REGITEM.CODPROD,
                          P_REGITEM.CODAUXILIAR,
                          P_REGITEM.NUMSEQORIG,
                          P_REGPEDIDO.CODCLI,
                          P_REGPEDIDO.CODUSUR,
                          NULL,
                          NULL,
                          P_REGPEDIDO.INTEGRADORA,
                          P_REGITEM.CODRETORNOS,
                          '3',
                           'Erro3:' || VSMENSAGEM,
                          NULL);
      END IF;
   ELSE
      P_REGITEM.VALIDO := TRUE;
   END IF;
   --   commit;
EXCEPTION WHEN OTHERS THEN
   P_REGITEM.VALIDO        := FALSE;
   P_REGORIGEMPRECO.VALIDO := FALSE;

   PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                    P_REGPEDIDO.NUMPEDINT,
                    P_REGITEM.CODPROD,
                    P_REGITEM.CODAUXILIAR,
                    P_REGITEM.NUMSEQORIG,
                    P_REGPEDIDO.CODCLI,
                    P_REGPEDIDO.CODUSUR,
                    NULL,
                    NULL,
                    P_REGPEDIDO.INTEGRADORA,
                    NULL,
                    '3',
                    'Erro4:' || SQLCODE || '-' || SQLERRM,
                    NULL);
END PROC_VALIDARITEMPED;
 

  FUNCTION FUNC_VALIDAAUTORIZACAOPCAUTORC(P_REGCLIENTE IN T_CLIENTEPEDIDO,
                                          P_CODUSUR    IN PCPEDC.CODUSUR%TYPE,
                                          P_REGFILIAL  IN T_FILIAL,
                                          P_VLDISP     IN NUMBER,
                                          P_VLATEND    IN NUMBER)
    RETURN NUMBER IS

    VNVLLIBERADO NUMBER;
  BEGIN
    BEGIN
      SELECT SUM(PCAUTORC.VLLIBERADO)
        INTO VNVLLIBERADO
        FROM PCAUTORC, PCEMPR
       WHERE ((PCAUTORC.CODCLI = P_REGCLIENTE.CODCLI) OR
             (P_REGFILIAL.SOMACREDITOCLIPRINCIPAL = 'S' AND
             (PCAUTORC.CODCLI IN
             (SELECT PCCLIENT.CODCLI
                   FROM PCCLIENT
                  WHERE CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC))))
         AND PCAUTORC.CODUSUR = P_CODUSUR
         AND PCAUTORC.CODFUNC = PCEMPR.MATRICULA
         AND PCAUTORC.LIBERALIMCRED = 'S'
         AND PCAUTORC.DTUTILIZACAO IS NULL
         AND PCAUTORC.CODFUNCUTILIZACAO IS NULL
         AND (P_VLDISP + NVL(PCAUTORC.VLLIBERADO, 0)) >= P_VLATEND
         AND ROWNUM = 1
       ORDER BY DATA;
    EXCEPTION
      WHEN OTHERS THEN
        VNVLLIBERADO := 0;
    END;

    RETURN VNVLLIBERADO;
  END FUNC_VALIDAAUTORIZACAOPCAUTORC;


  PROCEDURE PROC_ATUALIZARPCAUTORC(P_NUMPED      IN PCPEDC.NUMPED%TYPE,
                                   P_CODUSUR     IN PCPEDC.CODUSUR%TYPE,
                                   P_CODCLI      IN PCPEDC.CODCLI%TYPE,
                                   P_CODEMITENTE IN PCPEDC.CODEMITENTE%TYPE,
                                   P_VLPENDENTE  IN NUMBER,
                                   P_LIMCRED     IN NUMBER) IS
    VNNUMPEDIDO PCAUTORC.NUMPEDIDO%TYPE;
  BEGIN
    SELECT NUMPEDIDO
      INTO VNNUMPEDIDO
      FROM PCAUTORC
     WHERE CODUSUR = P_CODUSUR
       AND CODCLI = P_CODCLI
       AND CODFUNCUTILIZACAO IS NULL
       AND DTUTILIZACAO IS NULL
       AND ROWNUM = 1
     ORDER BY DATA;

    FOR REG IN (SELECT *
                  FROM PCAUTORC
                 WHERE NUMPEDIDO = VNNUMPEDIDO
                   AND CODUSUR = P_CODUSUR
                   AND CODCLI = P_CODCLI
                   FOR UPDATE) LOOP
      EXIT;
    END LOOP;

    UPDATE PCAUTORC
       SET LIMCRED           = P_LIMCRED,
           VLPENDENTE        = P_VLPENDENTE,
           DTUTILIZACAO      = TRUNC(SYSDATE),
           CODFUNCUTILIZACAO = P_CODEMITENTE,
           NUMPEDUTILIZACAO  = P_NUMPED
     WHERE NUMPEDIDO = VNNUMPEDIDO
       AND CODUSUR = P_CODUSUR
       AND CODCLI = P_CODCLI
       AND CODFUNCUTILIZACAO IS NULL
       AND DTUTILIZACAO IS NULL;
  END PROC_ATUALIZARPCAUTORC;


  FUNCTION FUNC_TIPOCONTACORRENTE(P_CONDVENDA NUMBER, P_VLTOTPED FLOAT, P_VLTOTTAB FLOAT)
  RETURN PCPEDC.TIPOCONTACORRENTE%TYPE
  IS
    V_TIPOCONTACORRENTE PCPEDC.TIPOCONTACORRENTE%TYPE;
  BEGIN
    IF P_CONDVENDA =  5 THEN
       V_TIPOCONTACORRENTE := NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTEBONIF','99',NULL), NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTEFV','99',NULL), FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTE','99',NULL)));
    ELSE
      IF  (P_VLTOTPED = P_VLTOTTAB) THEN
        V_TIPOCONTACORRENTE := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTE','99',NULL);
      ELSE
        V_TIPOCONTACORRENTE := NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTEFV','99',NULL), FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTE','99',NULL));
      END IF;
    END IF;

    RETURN V_TIPOCONTACORRENTE;
  END FUNC_TIPOCONTACORRENTE;


  FUNCTION FUNC_EXISTELIMITECLIENTE(P_REGPEDIDO       IN T_CABPED,
                                    P_REGCLIENTE      IN T_CLIENTEPEDIDO,
                                    P_REGFILIAL       IN T_FILIAL,
                                    P_VLTOTPED        IN NUMBER,
                                    P_SALDODISPONIVEL OUT NUMBER)
    RETURN BOOLEAN IS

    VNCONTASARECEBEREMABERTO NUMBER;
    VNVALORPEDIDOSPENDENTES  NUMBER;
    VNVLLIMCREDTOT           NUMBER;
  BEGIN
    P_SALDODISPONIVEL := 0;

    IF P_REGFILIAL.SOMACREDITOCLIPRINCIPAL = 'N' THEN
      IF P_REGFILIAL.USABNFLIMITECREDITO = 'S' THEN
        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(PCPREST.VALOR, 0))
          INTO VNCONTASARECEBEREMABERTO
          FROM PCPREST
         WHERE PCPREST.CODCLI = P_REGCLIENTE.CODCLI
           AND PCPREST.DTPAG IS NULL;

        SELECT SUM(NVL(VLATEND, 0))
          INTO VNVALORPEDIDOSPENDENTES
          FROM PCPEDC
         WHERE CODCLI = P_REGCLIENTE.CODCLI
           AND DTCANCEL IS NULL
           AND POSICAO IN ('L', 'M');
      ELSE
        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(PCPREST.VALOR, 0))
          INTO VNCONTASARECEBEREMABERTO
          FROM PCPREST
         WHERE PCPREST.CODCLI = P_REGCLIENTE.CODCLI
           AND PCPREST.DTPAG IS NULL
           AND PCPREST.CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP');

        SELECT SUM(NVL(VLATEND, 0))
          INTO VNVALORPEDIDOSPENDENTES
          FROM PCPEDC
         WHERE CODCLI = P_REGCLIENTE.CODCLI
           AND DTCANCEL IS NULL
           AND POSICAO IN ('L', 'M')
           AND CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP');
      END IF;
      -- Pedidos pendentes do cliente
      P_SALDODISPONIVEL := ((NVL(P_REGCLIENTE.LIMCRED, 0) * (1 + (NVL(GREGPCCONSUM.PEREXCEDELIMCRED, 0) / 100))) -
                           (NVL(VNCONTASARECEBEREMABERTO, 0) + NVL(VNVALORPEDIDOSPENDENTES, 0)));

      P_SALDODISPONIVEL := ROUND(P_SALDODISPONIVEL, GREGPCCONSUM.NUMCASASDECVENDA);
      --Calcula o valor disponivel de credito para o cliente
      IF P_VLTOTPED > P_SALDODISPONIVEL THEN
        IF P_SALDODISPONIVEL +
           FUNC_VALIDAAUTORIZACAOPCAUTORC(P_REGCLIENTE,
                                          P_REGPEDIDO.CODUSUR,
                                          P_REGFILIAL,
                                          P_SALDODISPONIVEL,
                                          P_VLTOTPED) >= P_VLTOTPED THEN

          PROC_ATUALIZARPCAUTORC(P_REGPEDIDO.NUMPED,
                                 P_REGPEDIDO.CODUSUR,
                                 P_REGPEDIDO.CODCLI,
                                 P_REGPEDIDO.CODEMITENTE,
                                 (NVL(VNCONTASARECEBEREMABERTO, 0) +
                                 NVL(VNVALORPEDIDOSPENDENTES, 0)),
                                 P_REGCLIENTE.LIMCRED);
          RETURN TRUE;
        ELSE
          RETURN FALSE;
        END IF;
      ELSE
        RETURN TRUE;
      END IF;
    ELSE
      IF P_REGFILIAL.USABNFLIMITECREDITO = 'S' THEN
        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(PCPREST.VALOR, 0))
          INTO VNCONTASARECEBEREMABERTO
          FROM PCPREST
         WHERE (PCPREST.CODCLI IN
               (SELECT PCCLIENT.CODCLI
                   FROM PCCLIENT
                  WHERE PCCLIENT.CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC) OR
               PCPREST.CODCLI = P_REGPEDIDO.CODCLI)
           AND PCPREST.DTPAG IS NULL;

        SELECT SUM(NVL(VLATEND, 0))
          INTO VNVALORPEDIDOSPENDENTES
          FROM PCPEDC
         WHERE (CODCLI IN
               (SELECT PCCLIENT.CODCLI
                   FROM PCCLIENT
                  WHERE PCCLIENT.CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC) OR
               CODCLI = P_REGPEDIDO.CODCLI)
           AND DTCANCEL IS NULL
           AND POSICAO IN ('L', 'M');
      ELSE
        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(PCPREST.VALOR, 0))
          INTO VNCONTASARECEBEREMABERTO
          FROM PCPREST
         WHERE (PCPREST.CODCLI IN
               (SELECT PCCLIENT.CODCLI
                   FROM PCCLIENT
                  WHERE PCCLIENT.CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC) OR
               PCPREST.CODCLI = P_REGPEDIDO.CODCLI)
           AND PCPREST.DTPAG IS NULL
           AND PCPREST.CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP');

        SELECT SUM(NVL(VLATEND, 0))
          INTO VNVALORPEDIDOSPENDENTES
          FROM PCPEDC
         WHERE (CODCLI IN
               (SELECT PCCLIENT.CODCLI
                   FROM PCCLIENT
                  WHERE PCCLIENT.CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC) OR
               CODCLI = P_REGPEDIDO.CODCLI)
           AND DTCANCEL IS NULL
           AND POSICAO IN ('L', 'M')
           AND CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP');
      END IF;

      SELECT SUM(PCCLIENT.LIMCRED)
        INTO VNVLLIMCREDTOT
        FROM PCCLIENT
       WHERE (PCCLIENT.CODCLIPRINC = P_REGCLIENTE.CODCLIPRINC 
          OR  PCCLIENT.CODCLI = P_REGPEDIDO.CODCLI);

      P_SALDODISPONIVEL := ((NVL(VNVLLIMCREDTOT, 0) * (1 + (NVL(GREGPCCONSUM.PEREXCEDELIMCRED, 0) / 100))) -
                           (NVL(VNCONTASARECEBEREMABERTO, 0) + NVL(VNVALORPEDIDOSPENDENTES, 0)));

      P_SALDODISPONIVEL := ROUND(P_SALDODISPONIVEL, GREGPCCONSUM.NUMCASASDECVENDA);

      --Calcula o valor disponivel de credito para o cliente
      IF P_VLTOTPED > P_SALDODISPONIVEL THEN
        IF P_SALDODISPONIVEL +
           FUNC_VALIDAAUTORIZACAOPCAUTORC(P_REGCLIENTE,
                                          P_REGPEDIDO.CODUSUR,
                                          P_REGFILIAL,
                                          P_SALDODISPONIVEL,
                                          P_VLTOTPED) >= P_VLTOTPED THEN

          PROC_ATUALIZARPCAUTORC(P_REGPEDIDO.NUMPED,
                                 P_REGPEDIDO.CODUSUR,
                                 P_REGPEDIDO.CODCLI,
                                 P_REGPEDIDO.CODEMITENTE,
                                 (NVL(VNCONTASARECEBEREMABERTO, 0) +
                                 NVL(VNVALORPEDIDOSPENDENTES, 0)),
                                 P_REGCLIENTE.LIMCRED);
          RETURN TRUE;
        ELSE
          RETURN FALSE;
        END IF;
      ELSE
        RETURN TRUE;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       NULL,
                       '2',
                       'Erro5:' || SQLCODE || '-' || SQLERRM || ';',
                       NULL);
      RETURN FALSE;
  END FUNC_EXISTELIMITECLIENTE;


FUNCTION FUNC_CALCULANUMPARCPLPAG(P_REGPLPAG IN T_PLANODEPAGAMENTO) RETURN INTEGER 
IS
   VNNUMPARCELAS INTEGER;
BEGIN
   VNNUMPARCELAS := 1;

   IF P_REGPLPAG.PRAZO1 > 0 THEN
      VNNUMPARCELAS := 1;
      IF P_REGPLPAG.PRAZO2 > 0 THEN
         VNNUMPARCELAS := VNNUMPARCELAS + 1;
         IF P_REGPLPAG.PRAZO3 > 0 THEN
            VNNUMPARCELAS := VNNUMPARCELAS + 1;
            IF P_REGPLPAG.PRAZO4 > 0 THEN
               VNNUMPARCELAS := VNNUMPARCELAS + 1;
               IF P_REGPLPAG.PRAZO5 > 0 THEN
                  VNNUMPARCELAS := VNNUMPARCELAS + 1;
                  IF P_REGPLPAG.PRAZO6 > 0 THEN
                     VNNUMPARCELAS := VNNUMPARCELAS + 1;
                     IF P_REGPLPAG.PRAZO7 > 0 THEN
                        VNNUMPARCELAS := VNNUMPARCELAS + 1;
                        IF P_REGPLPAG.PRAZO8 > 0 THEN
                           VNNUMPARCELAS := VNNUMPARCELAS + 1;
                           IF P_REGPLPAG.PRAZO9 > 0 THEN
                              VNNUMPARCELAS := VNNUMPARCELAS + 1;
                              IF P_REGPLPAG.PRAZO10 > 0 THEN
                                 VNNUMPARCELAS := VNNUMPARCELAS + 1;
                              END IF;
                           END IF;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
   END IF;

   RETURN VNNUMPARCELAS;
END FUNC_CALCULANUMPARCPLPAG;


  FUNCTION FUNC_INSERIRITEMCESTA(P_REGRCA     IN T_RCA,
                                 P_REGCLIENTE IN T_CLIENTEPEDIDO,
                                 P_REGITEM    IN OUT T_ITEMPED,
                                 P_REGPEDIDO  IN T_CABPED,
                                 P_REGREGIAO  IN T_REGIAOCLIENTE,
                                 P_REGPLPAG   IN T_PLANODEPAGAMENTO,
                                 P_REGFILIAL  IN T_FILIAL
                                 ) RETURN BOOLEAN IS
    VNCOUNTITENSCESTA  NUMBER := 0;
    VNNUMSEQ           NUMBER;
    VBCALCULARST       BOOLEAN;
    VSMENSAGEM_ST      VARCHAR2(1000);
    VNSTFONTE          NUMBER;
    VSMENSAGEM_STFONTE VARCHAR2(1000);
    VSMENSAGEM_COMISS  VARCHAR2(1000);
    VNPERDESC          NUMBER;
    VBCODICMTABPF      BOOLEAN;
    VNBASEICSTFONTE    PCPEDI.BASEICST%TYPE;
    VNPERCOM PCPEDI.PERCOM%TYPE;
    VBUSAPCTABCOMISS      BOOLEAN;
    VBUSAPCCOMISSAOUSUR   BOOLEAN;
    VBUSAPCCOMISSAOPLPAG  BOOLEAN;
    VBUSAPCCOMISSAOREGIAO BOOLEAN;
    VICONT                NUMBER;
    VBUSAPCCOMISSAOFILIAL BOOLEAN;
    VNPERLUC              NUMBER;
    VNCODCOMIS               PCORIGEMCOMIS.CODCOMIS%TYPE;
    VSCODROTINACOMIS         PCORIGEMCOMIS.CODROTINACOMIS%TYPE;
    VSLETRACOMISS            PCPEDI.LETRACOMISS%TYPE;
    VSCONSIDERARIPIALIQICMS2 VARCHAR2(1);
  BEGIN
    VNCOUNTITENSCESTA := GVET_REGITENSCESTA.COUNT;
    VNNUMSEQ          := 0;

    FOR I IN 1 .. VNCOUNTITENSCESTA LOOP
      IF P_REGPEDIDO.NUMPED = GVET_REGITENSCESTA(I).NUMPED AND 
         P_REGITEM.CODPROD = GVET_REGITENSCESTA(I).CODPRODCESTA THEN
        VSCONSIDERARIPIALIQICMS2 := 'N';

        IF (P_REGCLIENTE.CONSUMIDORFINAL = 'S') AND
           ((GVET_REGITENSCESTA(I).IMPORTADO = 'S') OR
           (GVET_REGITENSCESTA(I).IMPORTADO = 'D')) AND
           (P_REGFILIAL.UF <> P_REGCLIENTE.ESTENT) AND
           (GVET_REGITENSCESTA(I).AGREGARIPICALCULOST = 'S') THEN
          VSCONSIDERARIPIALIQICMS2 := 'S';
        END IF;

        VBCALCULARST := FUNCOESVENDAS.CALCULARST(GVET_REGITENSCESTA(I).PVENDA,
                                                 0,
                                                 P_REGPEDIDO.PERCVENDA,
                                                 GREGPCCONSUM.TIPOCALCST,
                                                 GREGPCCONSUM.CALCSTPF,
                                                 GVET_REGITENSCESTA(I).MOSTRARPVENDASEMST,
                                                 GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                 P_REGCLIENTE.CALCULAST,
                                                 P_REGCLIENTE.IEENT,
                                                 P_REGCLIENTE.TIPOFJ,
                                                 GVET_REGITENSCESTA(I).PAUTA,
                                                 GVET_REGITENSCESTA(I).IVA,
                                                 GVET_REGITENSCESTA(I).ALIQICMS1,
                                                 GVET_REGITENSCESTA(I).ALIQICMS2,
                                                 GVET_REGITENSCESTA(I).PERCBASEREDST,
                                                 GREGPCCONSUM.NUMCASASDECVENDA,
                                                 0,
                                                 P_REGFILIAL.UF,
                                                 P_REGCLIENTE.ESTENT,
                                                 GVET_REGITENSCESTA(I).USAVALORULTENTBASEST,
                                                 GVET_REGITENSCESTA(I).USAVALORULTENTBASEST2,
                                                 GVET_REGITENSCESTA(I).VALORULTENT,
                                                 P_REGCLIENTE.CONTRIBUINTE,
                                                 P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                                 VSMENSAGEM_ST,
                                                 GVET_REGITENSCESTA(I).ST,
                                                 GVET_REGITENSCESTA(I).BASEICST,
                                                 GREGPCCONSUM.ACEITAPFCONTRIBUINTE,
                                                 GVET_REGITENSCESTA(I).USAPMCBASEST,
                                                 GVET_REGITENSCESTA(I).PRECOMAXCONSUM,
                                                 GVET_REGITENSCESTA(I).CUSTONFSEMST,
                                                 P_REGCLIENTE.CONSUMIDORFINAL,
                                                 VSCONSIDERARIPIALIQICMS2,
                                                 GVET_REGITENSCESTA(I).USAVLULTENTMEDIOBASEST,
                                                 GVET_REGITENSCESTA(I).VLULTENTMES
                                                 );

        IF VSMENSAGEM_ST IS NOT NULL THEN
          PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                           P_REGPEDIDO.NUMPEDINT,
                           P_REGITEM.CODPROD,
                           P_REGITEM.CODAUXILIAR,
                           P_REGITEM.NUMSEQORIG,
                           P_REGPEDIDO.CODCLI,
                           P_REGPEDIDO.CODUSUR,
                           NULL,
                           NULL,
                           P_REGPEDIDO.INTEGRADORA,
                           92,
                           '3',
                           'Erro6:' || VSMENSAGEM_ST,
                           NULL);
        END IF;

        VNSTFONTE := 0;

        VNSTFONTE := FUNCOESVENDAS.CALCULARSTFONTE(GVET_REGITENSCESTA(I).CODPRODCESTA,
                                                   P_REGPEDIDO.CONDVENDA,
                                                   P_REGPEDIDO.PERCVENDA,
                                                   GVET_REGITENSCESTA(I).IVA,
                                                   GVET_REGITENSCESTA(I).IVAFONTE,
                                                   GVET_REGITENSCESTA(I).ALIQICMS1FONTE,
                                                   GVET_REGITENSCESTA(I).ALIQICMS2FONTE,
                                                   GVET_REGITENSCESTA(I).PERCBASEREDSTFONTE,
                                                   GVET_REGITENSCESTA(I).PERBASEREDNRPA,
                                                   GVET_REGITENSCESTA(I).PERCBASEREDCONSUMIDOR,
                                                   GVET_REGITENSCESTA(I).UTILIZAPERCBASEREDPF,
                                                   GREGPCCONSUM.TIPOCALCST,
                                                   GREGPCCONSUM.CALCSTPF,
                                                   GREGPCCONSUM.UTILIZAPERCBASEREDPF,
                                                   P_REGCLIENTE.CLIENTEFONTEST,
                                                   P_REGCLIENTE.CALCULAST,
                                                   P_REGCLIENTE.IEENT,
                                                   P_REGCLIENTE.TIPOFJ,
                                                   P_REGCLIENTE.ISENTOICMS,
                                                   P_REGCLIENTE.CONSUMIDORFINAL,
                                                   P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                                   P_REGCLIENTE.TIPOEMPRESA,
                                                   GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                   GVET_REGITENSCESTA(I).PVENDA,
                                                   0,
                                                   P_REGFILIAL.UF,
                                                   P_REGCLIENTE.ESTENT,
                                                   GVET_REGITENSCESTA(I).USAVALORULTENTBASEST,
                                                   GVET_REGITENSCESTA(I).VALORULTENT,
                                                   P_REGCLIENTE.USAIVAFONTEDIFERENCIADO,
                                                   P_REGCLIENTE.IVAFONTE,
                                                   GREGPCCONSUM.ACEITAPFCONTRIBUINTE,
                                                   GVET_REGITENSCESTA(I).ALIQICMS1,
                                                   GVET_REGITENSCESTA(I).ALIQICMS2,
                                                   P_REGCLIENTE.CONTRIBUINTE,
                                                   GREGPCCONSUM.NUMCASASDECVENDA,
                                                   VNBASEICSTFONTE,
                                                   VSMENSAGEM_STFONTE,
                                                   GVET_REGITENSCESTA(I).CUSTONFSEMST,
                                                   GVET_REGITENSCESTA(I).USAVALORULTENTBASEST2,
                                                   GVET_REGITENSCESTA(I).USAPMCBASEST,
                                                   GVET_REGITENSCESTA(I).PRECOMAXCONSUM
                                                   );
        IF VNBASEICSTFONTE > 0 THEN
          GVET_REGITENSCESTA(I).BASEICST := VNBASEICSTFONTE;
        END IF;

        IF VSMENSAGEM_STFONTE IS NOT NULL THEN
          PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                           P_REGPEDIDO.NUMPEDINT,
                           P_REGITEM.CODPROD,
                           P_REGITEM.CODAUXILIAR,
                           P_REGITEM.NUMSEQORIG,
                           P_REGPEDIDO.CODCLI,
                           P_REGPEDIDO.CODUSUR,
                           NULL,
                           NULL,
                           P_REGPEDIDO.INTEGRADORA,
                           92,
                           '3',
                           'Erro7:' || VSMENSAGEM_STFONTE,
                           NULL);
        END IF;

        IF (GVET_REGITENSCESTA(I).ST = 0) AND (VNSTFONTE <> 0) THEN
          GVET_REGITENSCESTA(I).ST := VNSTFONTE;
          GVET_REGITENSCESTA(I).PVENDA := ROUND(GVET_REGITENSCESTA(I).PVENDA + VNSTFONTE, GREGPCCONSUM.NUMCASASDECVENDA);
          GVET_REGITENSCESTA(I).PTABELA := ROUND(GVET_REGITENSCESTA(I).PTABELA + VNSTFONTE, GREGPCCONSUM.NUMCASASDECVENDA);
          GVET_REGITENSCESTA(I).IVA := GVET_REGITENSCESTA(I).IVAFONTE;
          GVET_REGITENSCESTA(I).PAUTA := 0;
          GVET_REGITENSCESTA(I).ALIQICMS1 := GVET_REGITENSCESTA(I).ALIQICMS1FONTE;
          GVET_REGITENSCESTA(I).ALIQICMS2 := GVET_REGITENSCESTA(I).ALIQICMS2FONTE;
          GVET_REGITENSCESTA(I).PERCBASEREDST := GVET_REGITENSCESTA(I).PERCBASEREDST;
          GVET_REGITENSCESTA(I).PERCBASEREDSTFONTE := GVET_REGITENSCESTA(I).PERCBASEREDSTFONTE;
        END IF;

        IF NVL(GVET_REGITENSCESTA(I).CODICMTABPF,0) = 0 THEN
          VBCODICMTABPF := TRUE;
        ELSE
          VBCODICMTABPF := FALSE;
        END IF;
        
        FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                                  GREGPCCONSUM.APLICARINDICECMV,
                                  GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                                  NVL(GREGPCCONSUM.TXVENDA, 0),
                                  P_REGCLIENTE.TIPOFJ,
                                  P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                  P_REGCLIENTE.IEENT,
                                  GVET_REGITENSCESTA(I).FRETEESPECIAL,
                                  P_REGREGIAO.PERFRETETERCEIROS,
                                  P_REGREGIAO.PERFRETEESPECIAL,
                                  GVET_REGITENSCESTA(I).VLCUSTOFIN,
                                  GVET_REGITENSCESTA(I).VLCUSTOREAL,
                                  GVET_REGITENSCESTA(I).PERDESCCUSTO,
                                  GVET_REGITENSCESTA(I).CODICMTAB,
                                  VBCODICMTABPF,
                                  GVET_REGITENSCESTA(I).CODICMTABPF,
                                  P_REGPEDIDO.PERCVENDA,
                                  GVET_REGITENSCESTA(I).PVENDA,
                                  0,
                                  GVET_REGITENSCESTA(I).ST,
                                  0,
                                  0,
                                  P_REGCLIENTE.CONTRIBUINTE,
                                  0,
                                  0,
                                  P_REGCLIENTE.CONSUMIDORFINAL,
                                  NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                                  GVET_REGITENSCESTA(I).PERFRETECMV,
                                  GVET_REGITENSCESTA(I).CUSTOFINEST,
                                  GVET_REGITENSCESTA(I).TXVENDA,
                                  GVET_REGITENSCESTA(I).PERDESCCUSTO,
                                  GVET_REGITENSCESTA(I).CODICMTAB,
                                  GVET_REGITENSCESTA(I).VLCUSTOREAL,
                                  GVET_REGITENSCESTA(I).VLCUSTOFIN,
                                  GVET_REGITENSCESTA(I).VLDESCCUSTOCMV);
        VNPERDESC := 0;
        IF NVL(GVET_REGITENSCESTA(I).PTABELA,0) <> 0 THEN
           VNPERDESC := ((GVET_REGITENSCESTA(I).PTABELA - GVET_REGITENSCESTA(I).PVENDA) / GVET_REGITENSCESTA(I).PTABELA) * 100;
        END IF;
        VNPERDESC := ROUND(VNPERDESC, GREGPCCONSUM.NUMCASASDECVENDA);

        VNPERLUC := 0;
        IF NVL(GVET_REGITENSCESTA(I).PVENDA,0) <> 0 THEN
           VNPERLUC := ((GVET_REGITENSCESTA(I).PVENDA - GVET_REGITENSCESTA(I).VLCUSTOFIN) / GVET_REGITENSCESTA(I).PVENDA) * 100;
        END IF;
        -- busca percentual de comissao
        VSMENSAGEM_COMISS := NULL;

        SELECT COUNT(*) INTO VICONT FROM PCTABCOMISS P;

        IF VICONT <> 0 THEN
          VBUSAPCTABCOMISS := TRUE;
        ELSE
          VBUSAPCTABCOMISS := FALSE;
        END IF;

        SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOUSUR P;

        IF VICONT <> 0 THEN
          VBUSAPCCOMISSAOUSUR := TRUE;
        ELSE
          VBUSAPCCOMISSAOUSUR := FALSE;
        END IF;

        SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOPLPAG P;

        IF VICONT <> 0 THEN
          VBUSAPCCOMISSAOPLPAG := TRUE;
        ELSE
          VBUSAPCCOMISSAOPLPAG := FALSE;
        END IF;

        SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOREGIAO P;

        IF VICONT <> 0 THEN
          VBUSAPCCOMISSAOREGIAO := TRUE;
        ELSE
          VBUSAPCCOMISSAOREGIAO := FALSE;
        END IF;

        IF P_REGFILIAL.BROKER = 'S' THEN
          VBUSAPCCOMISSAOFILIAL := TRUE;
        ELSE
          VBUSAPCCOMISSAOFILIAL := FALSE;
        END IF;

        BEGIN
          IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('REPLICAPERCOMCESTA', GVET_REGPEDIDO(i).CODFILIAL,'N') = 'S') THEN
             GVET_REGITENSCESTA(i).PERCOM := P_REGITEM.PERCOM;
         ELSE
          GVET_REGITENSCESTA(I).PERCOM := FUNCOESVENDAS.DEFINIR_COMISSAO_ITEM_VENDIDO(P_REGREGIAO.NUMREGIAO,
                                                                                      VNPERLUC,
                                                                                      VNPERDESC,
                                                                                      VBUSAPCTABCOMISS,
                                                                                      VBUSAPCCOMISSAOUSUR,
                                                                                      VBUSAPCCOMISSAOPLPAG,
                                                                                      VBUSAPCCOMISSAOREGIAO,
                                                                                      VBUSAPCCOMISSAOFILIAL,
                                                                                      GREGPCCONSUM.USACOMISSAOPORRCA,
                                                                                      GREGPCCONSUM.ORDEMAVALIACAOCOMISSAORCA,
                                                                                      GREGPCCONSUM.USACOMISSAOPORCLIENTE,
                                                                                      GREGPCCONSUM.USACOMISSAOPORLINHAPROD,
                                                                                      GREGPCCONSUM.COMISSAORCATIPOVENDA,
                                                                                      P_REGRCA.TIPOVEND,
                                                                                      P_REGRCA.PERCENT,
                                                                                      P_REGRCA.PERCENT2,
                                                                                      GVET_REGITENSCESTA(I).CODPRODMP,
                                                                                      GVET_REGITENSCESTA(I).PCOMINT1,
                                                                                      GVET_REGITENSCESTA(I).PCOMEXT1,
                                                                                      GVET_REGITENSCESTA(I).PCOMREP1,
                                                                                      GVET_REGITENSCESTA(I).CODLINHAPROD,
                                                                                      GVET_REGITENSCESTA(I).TIPOCOMISSAO,
                                                                                      GVET_REGITENSCESTA(I).CODEPTO,
                                                                                      GVET_REGITENSCESTA(I).CODSEC,
                                                                                      GVET_REGITENSCESTA(I).CLASSE,
                                                                                      P_REGPLPAG.TIPOVENDA,
                                                                                      P_REGPLPAG.CODPLPAG,
                                                                                      P_REGPEDIDO.DATA,
                                                                                      P_REGPEDIDO.CODFILIAL,
                                                                                      P_REGPEDIDO.CODUSUR,
                                                                                      P_REGFILIAL.CONSIDERARCOMISSAOZERO,
                                                                                      P_REGFILIAL.TIPOAVALIACAOCOMISSAO,
                                                                                      P_REGCLIENTE.PERCOMCLI,
                                                                                      P_REGCLIENTE.CODCLI,
                                                                                      NULL,
                                                                                      VNCODCOMIS,
                                                                                      VSCODROTINACOMIS,
                                                                                      VSLETRACOMISS,
                                                                                      VSMENSAGEM_COMISS,
                                                                                      GVET_REGITENSCESTA(I).CODAUXILIAR,
                                                                                      NULL, --regprecos.pcomint1_emb,
                                                                                      NULL, --regprecos.PCOMEXT1_emb,
                                                                                      NULL, --regprecos.PCOMREP1_emb,
                                                                                      P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM);
         END IF;
        EXCEPTION
          WHEN OTHERS THEN
            PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                             P_REGPEDIDO.NUMPEDINT,
                             P_REGITEM.CODPROD,
                             P_REGITEM.CODAUXILIAR,
                             P_REGITEM.NUMSEQORIG,
                             P_REGPEDIDO.CODCLI,
                             P_REGPEDIDO.CODUSUR,
                             NULL,
                             NULL,
                             P_REGPEDIDO.INTEGRADORA,
                             94,
                             '3',
                             'Erro8:' || VSMENSAGEM_COMISS,
                             NULL);
        END;

        IF NVL(GREGPCCONSUM.INCLUIRCOMISSAOCMVVENDA, 'S') = 'N' THEN
          VNPERCOM := 0;
        ELSE
          VNPERCOM := GVET_REGITENSCESTA(I).PERCOM;
        END IF;

        FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                                  GREGPCCONSUM.APLICARINDICECMV,
                                  GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                                  NVL(GREGPCCONSUM.TXVENDA, 0),
                                  P_REGCLIENTE.TIPOFJ,
                                  P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                  P_REGCLIENTE.IEENT,
                                  GVET_REGITENSCESTA(I).FRETEESPECIAL,
                                  P_REGREGIAO.PERFRETETERCEIROS,
                                  P_REGREGIAO.PERFRETEESPECIAL,
                                  GVET_REGITENSCESTA(I).VLCUSTOFIN,
                                  GVET_REGITENSCESTA(I).VLCUSTOREAL,
                                  GVET_REGITENSCESTA(I).PERDESCCUSTO,
                                  GVET_REGITENSCESTA(I).CODICMTAB,
                                  VBCODICMTABPF,
                                  GVET_REGITENSCESTA(I).CODICMTABPF,
                                  P_REGPEDIDO.PERCVENDA,
                                  GVET_REGITENSCESTA(I).PVENDA,
                                  VNPERCOM,
                                  GVET_REGITENSCESTA(I).ST,
                                  0,
                                  0,
                                  P_REGCLIENTE.CONTRIBUINTE,
                                  0,
                                  0,
                                  P_REGCLIENTE.CONSUMIDORFINAL,
                                  NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                                  GVET_REGITENSCESTA(I).PERFRETECMV,
                                  GVET_REGITENSCESTA(I).CUSTOFINEST,
                                  GVET_REGITENSCESTA(I).TXVENDA,
                                  GVET_REGITENSCESTA(I).PERDESCCUSTO,
                                  GVET_REGITENSCESTA(I).CODICMTAB,
                                  GVET_REGITENSCESTA(I).VLCUSTOREAL,
                                  GVET_REGITENSCESTA(I).VLCUSTOFIN,
                                  GVET_REGITENSCESTA(I).VLDESCCUSTOCMV);

        INSERT INTO PCPEDICESTA
          (NUMPED,
           CODPROD,
           NUMSEQ,
           CODPRODMP,
           QTMP,
           PVENDA,
           PTABELA,
           PBASERCA,
           ST,
           VLCUSTOFIN,
           VLCUSTOREAL,
           PERCOM,
           BASEICST,
           ALIQICMS1,
           ALIQICMS2,
           PERCBASEREDST,
           IVA,
           PAUTA,
           PERCBASEREDSTFONTE,
           PERCBASERED,
           CODST,
           VLCUSTOREP,
           VLCUSTOCONT,
           CUSTOFINEST,
           PERDESCCUSTO,
           CODICMTAB,
           PERFRETECMV,
           TXVENDA,
           VLDESCCUSTOCMV,
           CODAUXILIAR)
        VALUES
          (P_REGPEDIDO.NUMPED,
           P_REGITEM.CODPROD,
           P_REGITEM.NUMSEQ,
           GVET_REGITENSCESTA(I).CODPRODMP,
           GVET_REGITENSCESTA(I).QT,
           GVET_REGITENSCESTA(I).PVENDA,
           GVET_REGITENSCESTA(I).PTABELA,
           GVET_REGITENSCESTA(I).PTABELA,
           GVET_REGITENSCESTA(I).ST,
           GVET_REGITENSCESTA(I).VLCUSTOFIN,
           GVET_REGITENSCESTA(I).VLCUSTOREAL,
           GVET_REGITENSCESTA(I).PERCOM,
           GVET_REGITENSCESTA(I).BASEICST,
           GVET_REGITENSCESTA(I).ALIQICMS1,
           GVET_REGITENSCESTA(I).ALIQICMS2,
           GVET_REGITENSCESTA(I).PERCBASEREDST,
           GVET_REGITENSCESTA(I).IVA,
           GVET_REGITENSCESTA(I).PAUTA,
           GVET_REGITENSCESTA(I).PERCBASEREDSTFONTE,
           GVET_REGITENSCESTA(I).PERCBASERED,
           GVET_REGITENSCESTA(I).CODST,
           GVET_REGITENSCESTA(I).CUSTOREP,
           GVET_REGITENSCESTA(I).CUSTOCONT,
           GVET_REGITENSCESTA(I).CUSTOFINEST,
           GVET_REGITENSCESTA(I).PERDESCCUSTO,
           GVET_REGITENSCESTA(I).CODICMTAB,
           GVET_REGITENSCESTA(I).PERFRETECMV,
           GVET_REGITENSCESTA(I).TXVENDA,
           GVET_REGITENSCESTA(I).VLDESCCUSTOCMV,
           GVET_REGITENSCESTA(I).CODAUXILIAR);
      END IF;
    END LOOP;

    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       P_REGITEM.CODPROD,
                       P_REGITEM.CODAUXILIAR,
                       P_REGITEM.NUMSEQORIG,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       141,
                       '3',
                       'Problemas na gravacao do item de cesta ' || SQLCODE || '-' ||
                       SQLERRM || ';',
                       NULL);

      RETURN FALSE;
  END FUNC_INSERIRITEMCESTA;

  FUNCTION FUNC_INSERIRITEMPEDIDO(P_REGPEDIDO       IN T_CABPED,
                                  P_REGITEM         IN OUT T_ITEMPED,
                                  P_REGPRECOS       IN T_PRECOSETRIBUTACAO,
                                  P_REGPRODUTO      IN T_PRODUTO,
                                  P_REGRCA          IN T_RCA,
                                  P_REGPLPAG        IN T_PLANODEPAGAMENTO,
                                  P_REGCLIENTE      IN T_CLIENTEPEDIDO,
                                  P_REGREGIAO       IN T_REGIAOCLIENTE,
                                  P_REGFILIAL       IN T_FILIAL,
                                  P_REGORIGEMPRECO  IN T_ORIGEMPRECO,
                                  P_REGORIGEMCOMISS IN T_ORIGEMCOMISS,
                                  P_REGORIGEMDESC   IN T_ORIGEMDESC
                                  ) RETURN BOOLEAN IS
    VBVALIDO BOOLEAN;
    VNVLCUSTOFIN  PCPEDI.VLCUSTOFIN%TYPE;
    VNVLCUSTOREAL PCPEDI.VLCUSTOREAL%TYPE;
    VNVLCUSTOREP  PCPEDI.VLCUSTOREP%TYPE;
    VNCUSTOFINEST PCPEDI.CUSTOFINEST%TYPE;
    VNVLCUSTOCONT PCPEDI.VLCUSTOCONT%TYPE;
    VNPERCOM      PCPEDI.PERCOM%TYPE;
    VCODICMTAB    PCPEDI.CODICMTAB%TYPE;
    VCODICMTABPF  PCPEDI.CODICMTAB%TYPE;
    VCODICMTABPJ  PCPEDI.CODICMTAB%TYPE;
    VTIPOFJ       PCCLIENT.TIPOFJ%TYPE;
    vPERFRETE     PCREGIAO.PERFRETE%TYPE;
    vPERFRETEESPECIAL PCREGIAO.PERFRETEESPECIAL%TYPE;
    vPERFRETETERCEIROS PCREGIAO.PERFRETETERCEIROS%TYPE;    
  BEGIN
     BEGIN
        SELECT NVL(ALIQICMSFECP,0), NVL(UTILIZAMOTORCALCULO,'N'),
               NVL(CODICMTAB,0),  NVL(CODICMTABPF,0)
        INTO VALIQICMSFECP, VUTILIZOUMOTORCALCULO,
             VCODICMTABPJ, VCODICMTABPF
        FROM PCTRIBUT
        WHERE CODST = P_REGPRECOS.CODST;
        VALIQFCP := 0;
     EXCEPTION
     WHEN OTHERS THEN
        VALIQICMSFECP := 0;
        VALIQFCP := 0;
        VUTILIZOUMOTORCALCULO := 'N';
        VCODICMTABPJ := 0;
        VCODICMTABPF := 0;
     END;

     BEGIN
        SELECT NVL(PCCLIENT.TIPOFJ,'J')
        INTO VTIPOFJ
        FROM PCCLIENT
        WHERE CODCLI = P_REGPEDIDO.CODCLI;
     EXCEPTION
        WHEN OTHERS THEN
           VTIPOFJ := 'J';
     END;
     
     IF VTIPOFJ = 'J' THEN
        VCODICMTAB := VCODICMTABPJ;
     ELSE
        VCODICMTAB := VCODICMTABPF;
     END IF;
    
    SELECT PCREGIAO.PERFRETE,
           NVL(PCREGIAO.PERFRETEESPECIAL, 0),
           NVL(PCREGIAO.PERFRETETERCEIROS, 0)
     INTO vPERFRETE,
          vPERFRETEESPECIAL,
          vPERFRETETERCEIROS
     FROM PCREGIAO
     WHERE PCREGIAO.NUMREGIAO = P_REGCLIENTE.NUMREGIAO
       AND PCREGIAO.STATUS = 'A'; 
       
    vPERFRETE := vPERFRETETERCEIROS;
    IF P_REGPRODUTO.FRETEESPECIAL = 'S' THEN
      vPERFRETE := vPERFRETEESPECIAL;
    END IF;       
    
    INSERT INTO PCPEDI
      (CODCLI, --01
       CODICMTAB, --02
       CODPROD, --03
       CODST, --04
       CODUSUR, --05
       DATA, --06
       NUMPED, --07
       NUMSEQ, --08
       PERCOM, --09 
       PERDESC, --10
       POSICAO, --11
       PTABELA, --12
       PVENDA, --13
       QT, --14
       QTFALTA, --15
       ST, --16
       VLCUSTOCONT, --17
       VLCUSTOFIN, --18
       VLCUSTOREAL, --19
       VLCUSTOREP, --20
       PBASERCA, --21
       PVENDABASE, --22
       STCLIENTEGNRE, --23
       IVA, --24
       PAUTA, --25
       ALIQICMS1, --26
       ALIQICMS2, --27
       PERCBASEREDST, --28
       PERCBASEREDSTFONTE, --29
       BASEICST, --30
       PERFRETECMV, --31
       CUSTOFINEST, --32
       TXVENDA, --33
       PERDESCCUSTO, --34
       VLDESCCUSTOCMV, --35
       LETRACOMISS, --36
       VLIPI, --37
       PERCIPI, --38
       VLDESCSUFRAMA, --39
       VLDESCICMISENCAO, --40
       PERDESCISENTOICMS, --41
       VLVERBACMV, --42
       PVENDA1, --43
       CODAUXILIAR, --44
       PERCDESCPIS, --45
       PERCDESCCOFINS, --46
       VLDESCREDUCAOPIS, --47
       VLDESCREDUCAOCOFINS, --48
       CODFILIALRETIRA, --49
       PERCDIFALIQUOTAS, --50
       BASEDIFALIQUOTAS, --51
       VLDIFALIQUOTAS, --52
       NUMAPLIC, --53
       NUMCAR, --54
       VLREDPVENDASIMPLESNA, --55
       VLREDCMVSIMPLESNAC, --56
       QTUNITEMB, --57
       IDVENDA, --58
       PORIGINAL, --59
       GERAGNRE_CNPJCLIENTE, --60
       TIPOENTREGA, --61
       MOVIMENTACONTACORRENTERCA --62
      ,VLFECP --63
      ,VLBASEFCPST --64
      ,ALIQFCP --65
      ,ALIQICMSFECP --66
      ,UTILIZOUMOTORCALCULO --67
       )
    VALUES
      (P_REGPEDIDO.CODCLI, --01
       VCODICMTAB, --02
       P_REGITEM.CODPROD, --03
       P_REGPRECOS.CODST, --04
       P_REGPEDIDO.CODUSUR, --05
       TRUNC(SYSDATE), --06
       P_REGPEDIDO.NUMPED, --07
       P_REGITEM.NUMSEQ, --08
       P_REGITEM.PERCOM, --09
       P_REGITEM.PERDESC, --10
       P_REGPEDIDO.POSICAO, --11
       P_REGPRODUTO.PTABELA, --12
       P_REGITEM.PVENDA, --13
       P_REGITEM.QT, --14
       0, --15
       P_REGITEM.ST, --16
       P_REGPRECOS.CUSTOCONT, --17
       DECODE(P_REGPEDIDO.CONDVENDA, 4, 0,
              DECODE(P_REGFILIAL.TIPOBROKER, 'MAB',
                     NVL(P_REGPRECOS.PRECOFAB, P_REGITEM.VLCUSTOFIN),
                     P_REGITEM.VLCUSTOFIN)), --18
       DECODE(P_REGPEDIDO.CONDVENDA, 4, 0,
              DECODE(P_REGFILIAL.TIPOBROKER, 'MAB',
                     NVL(P_REGPRECOS.PRECOFAB, P_REGITEM.VLCUSTOREAL),
                     P_REGITEM.VLCUSTOREAL)), --19
       P_REGPRECOS.CUSTOREP, --20
       P_REGITEM.PBASERCA, --21
       P_REGITEM.PVENDABASE, --22
       P_REGITEM.STCLIENTEGNRE, --23
       P_REGITEM.IVA, --24
       P_REGITEM.PAUTA, --25
       P_REGITEM.ALIQICMS1, --26
       P_REGITEM.ALIQICMS2, --27
       P_REGITEM.PERCBASEREDST, --28
       P_REGITEM.PERCBASEREDSTFONTE, --29
       P_REGITEM.BASEICST, --30
       vPERFRETE, --31 --P_REGITEM.PERFRETECMV,
       P_REGITEM.CUSTOFINEST, --32
       P_REGITEM.TXVENDA, --33
       P_REGITEM.PERDESCCUSTO, --34
       P_REGITEM.VLDESCCUSTOCMV, --35
       P_REGITEM.LETRACOMISS, --36
       P_REGITEM.VLIPI, --37
       P_REGITEM.PERCIPI, --38
       P_REGITEM.VLDESCSUFRAMA, --39
       P_REGITEM.VLDESCICMISENCAO, --40
       P_REGITEM.PERDESCISENTOICMS, --41
       P_REGITEM.VLVERBACMV, --42
       P_REGITEM.PVENDA1, --43
       P_REGITEM.CODAUXILIAR, --44
       P_REGITEM.PERCDESCPIS, --45
       P_REGITEM.PERCDESCCOFINS, --46
       P_REGITEM.VLDESCREDUCAOPIS, --47
       P_REGITEM.VLDESCREDUCAOCOFINS,--48
       NVL(P_REGITEM.CODFILIALRETIRA, P_REGPEDIDO.CODFILIAL), --49
       P_REGITEM.PERCDIFALIQUOTAS, --50
       P_REGITEM.BASEDIFALIQUOTAS, --51
       P_REGITEM.VLDIFALIQUOTAS, --52
       P_REGITEM.NUMSEQORIG, --53
       0, --54
       P_REGITEM.VLREDPVENDASIMPLESNA, --55
       P_REGITEM.VLREDCMVSIMPLESNAC, --56
       P_REGPRECOS.QTUNIT, --57
       P_REGITEM.IDVENDA, --58
       P_REGITEM.PORIGINAL, --59
       P_REGITEM.GERAGNRE_CNPJCLIENTE, --60
       P_REGITEM.TIPOENTREGA, --61
       P_REGITEM.MOVIMENTACONTACORRENTERCA --62
      ,P_REGITEM.VLRFECP --63
      ,P_REGITEM.BASEFECP --64
      ,VALIQFCP --65
      ,VALIQICMSFECP --66
      ,VUTILIZOUMOTORCALCULO --67
       );

    BEGIN
      INSERT INTO PCORIGEMPRECO
        (NUMPED, --1
         TIPOBROKER, --2
         CODPROD, --3
         NUMSEQ, --4
         USATRIBUTPORUF, --5
         ORIGEMPRECO, --6
         COLUNAPRECO, --7
         TIPOFRETE, --8
         PERCFRETE, --9
         CODAUTORIZACAO, --10
         PERCDESCAUTOR, --11
         PERCACRESCPF, --12
         PERCRAMOATIV, --13
         TIPODESCFLEX, --14
         CODDESCFLEX, --15
         CODDESCVOLUME, --16
         PERCDESCVOLUME, --17
         CODDESCPTABELA, --18
         CODDESCVOLPTABELA, --19
         PERCDESCPTABELA, --20
         PERCDESCFLEX, --21
         CODPRECOFIXO, --22
         FATORPRECO, --23
         PORIGINAL, --24
         DTINICIOAUTOR, --25
         DTFIMAUTOR, --26
         DTINICIODESCFLEX, --27
         DTFIMDESCFLEX, --28
         DTINICIODESCVOLUME, --29
         DTFIMDESCVOLUME, --30
         DTINICIODESCPTABELA, --31
         DTFIMDESCPTABELA, --32
         DTINICIOOFERTA, --33
         DTFIMOFERTA, --34
         PERCPLPAG, --35
         PERCACRESCBALCAO, --36
         QTMINATACADO, --37
         VLST, --38
         VLIPI, --39
         VLSUFRAMA, --40
         VLDESCICMS, --41
         ORIGEMPED, --42
         INICIOINTERVALO, --43
         FIMINTERVALO, --44
         DATA, --45
         CODEMITENTE, --46
         CODFILIAL, --47
         CODFILIALNF, --48
         INICIOINTERVALOAUTORI, --49
         FIMINTERVALOAUTORI, --50
         NUMREGIAO, --51
         PERCDESCPIS, --52
         PERCDESCCOFINS, --53
         VLDESCREDUCAOPIS, --54
         VLDESCREDUCAOCOFINS --55
         ,VLFECP --56
         )
      VALUES
        (P_REGORIGEMPRECO.NUMPED, --1
         P_REGORIGEMPRECO.TIPOBROKER, --2
         P_REGORIGEMPRECO.CODPROD, --3
         P_REGORIGEMPRECO.NUMSEQ, --4
         P_REGORIGEMPRECO.USATRIBUTPORUF, --5
         P_REGORIGEMPRECO.ORIGEMPRECO, --6
         P_REGORIGEMPRECO.COLUNAPRECO, --7
         P_REGORIGEMPRECO.TIPOFRETE, --8
         P_REGORIGEMPRECO.PERCFRETE, --9
         P_REGORIGEMPRECO.CODAUTORIZACAO, --10
         P_REGORIGEMPRECO.PERCDESCAUTOR, --11
         P_REGORIGEMPRECO.PERCACRESCPF, --12
         P_REGORIGEMPRECO.PERCRAMOATIV, --13
         P_REGORIGEMPRECO.TIPODESCFLEX, --14
         P_REGORIGEMPRECO.CODDESCFLEX, --15
         P_REGORIGEMPRECO.CODDESCVOLUME, --16
         P_REGORIGEMPRECO.PERCDESCVOLUME, --17
         P_REGORIGEMPRECO.CODDESCPTABELA, --18
         P_REGORIGEMPRECO.CODDESCVOLPTABELA, --19
         P_REGORIGEMPRECO.PERCDESCPTABELA, --20
         P_REGORIGEMPRECO.PERCDESCFLEX, --21
         P_REGORIGEMPRECO.CODPRECOFIXO, --22
         P_REGORIGEMPRECO.FATORPRECO, --23
         P_REGORIGEMPRECO.PORIGINAL, --24
         P_REGORIGEMPRECO.DTINICIOAUTOR, --25
         P_REGORIGEMPRECO.DTFIMAUTOR, --26
         P_REGORIGEMPRECO.DTINICIODESCFLEX, --27
         P_REGORIGEMPRECO.DTFIMDESCFLEX, --28
         P_REGORIGEMPRECO.DTINICIODESCVOLUME, --29
         P_REGORIGEMPRECO.DTFIMDESCVOLUME, --30
         P_REGORIGEMPRECO.DTINICIODESCPTABELA, --31
         P_REGORIGEMPRECO.DTFIMDESCPTABELA, --32
         P_REGORIGEMPRECO.DTINICIOOFERTA, --33
         P_REGORIGEMPRECO.DTFIMOFERTA, --34
         P_REGORIGEMPRECO.PERCPLPAG, --35
         P_REGORIGEMPRECO.PERCACRESCBALCAO, --36
         P_REGORIGEMPRECO.QTMINATACADO, --37
         P_REGORIGEMPRECO.VLST, --38
         P_REGORIGEMPRECO.VLIPI, --39
         P_REGORIGEMPRECO.VLSUFRAMA, --40
         P_REGORIGEMPRECO.VLDESCICMS, --41
         P_REGORIGEMPRECO.ORIGEMPED, --42
         P_REGORIGEMPRECO.INICIOINTERVALO, --43
         P_REGORIGEMPRECO.FIMINTERVALO, --44
         P_REGORIGEMPRECO.DATA, --45
         P_REGORIGEMPRECO.CODEMITENTE, --46
         P_REGORIGEMPRECO.CODFILIAL, --47
         P_REGORIGEMPRECO.CODFILIALNF, --48
         P_REGORIGEMPRECO.INICIOINTERVALOAUTORI, --49
         P_REGORIGEMPRECO.FIMINTERVALOAUTORI, --50
         P_REGORIGEMPRECO.NUMREGIAO, --51
         P_REGORIGEMPRECO.PERCDESCPIS, --52
         P_REGORIGEMPRECO.PERCDESCCOFINS, --53
         P_REGORIGEMPRECO.VLDESCREDUCAOPIS, --54
         P_REGORIGEMPRECO.VLDESCREDUCAOCOFINS --55
         ,P_REGITEM.VLRFECP --56
         );
    EXCEPTION
      WHEN OTHERS THEN
        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                         P_REGPEDIDO.NUMPEDINT,
                         P_REGPRODUTO.CODPROD,
                         P_REGITEM.CODAUXILIAR,
                         P_REGITEM.NUMSEQORIG,
                         P_REGPEDIDO.CODCLI,
                         P_REGPEDIDO.CODUSUR,
                         NULL,
                         NULL,
                         P_REGPEDIDO.INTEGRADORA,
                         142,
                         '3',
                         'Erro ao inserir origem preço: ' || SQLCODE || '-' ||
                         SQLERRM || ';',
                         NULL);
    END;

    BEGIN
      INSERT INTO PCORIGEMCOMIS
        (NUMPED, -- 1
         ORIGEMPED, -- 2
         CODPROD, -- 3
         CODAUXILIAR, -- 4
         NUMSEQ, -- 5
         CODFILIAL, -- 6
         NUMREGIAO, -- 7
         PERCOM, -- 8
         PERDESC, -- 9
         CODUSUR, -- 10
         CODCLI, -- 11
         CODCOB, -- 12
         CODPLPAG, -- 13
         CODROTINACOMIS, -- 14
         CODCOMIS, -- 15
         TIPOCOMISSAO, -- 16
         TIPOVEND, -- 17
         TIPOVENDA, -- 18
         CODLINHAPROD, -- 19
         TIPOAVALIACAOCOMISSAO, -- 20
         ORDEMAVALIACAOCOMISSAORCA, -- 21
         USACOMISSAOPORRCA, -- 22
         USACOMISSAOPORCLIENTE, -- 23
         USACOMISSAOPORLINHAPROD, -- 24
         COMISSAORCATIPOVENDA, -- 25
         CONSIDERARCOMISSAOZERO -- 26
         )
      VALUES
        (P_REGORIGEMCOMISS.NUMPED, -- 1
         P_REGORIGEMCOMISS.ORIGEMPED, -- 2
         P_REGORIGEMCOMISS.CODPROD, -- 3
         P_REGORIGEMCOMISS.CODAUXILIAR, -- 4
         P_REGORIGEMCOMISS.NUMSEQ, -- 5
         P_REGORIGEMCOMISS.CODFILIAL, -- 6
         P_REGORIGEMCOMISS.NUMREGIAO, -- 7
         P_REGORIGEMCOMISS.PERCOM, -- 8
         P_REGORIGEMCOMISS.PERDESC, -- 9
         P_REGORIGEMCOMISS.CODUSUR, -- 10
         P_REGORIGEMCOMISS.CODCLI, -- 11
         P_REGORIGEMCOMISS.CODCOB, -- 12
         P_REGORIGEMCOMISS.CODPLPAG, -- 13
         P_REGORIGEMCOMISS.CODROTINACOMIS, -- 14
         P_REGORIGEMCOMISS.CODCOMIS, -- 15
         P_REGORIGEMCOMISS.TIPOCOMISSAO, -- 16
         P_REGORIGEMCOMISS.TIPOVEND, -- 17
         P_REGORIGEMCOMISS.TIPOVENDA, -- 18
         P_REGORIGEMCOMISS.CODLINHAPROD, -- 19
         P_REGORIGEMCOMISS.TIPOAVALIACAOCOMISSAO, -- 20
         P_REGORIGEMCOMISS.ORDEMAVALIACAOCOMISSAORCA, -- 21
         P_REGORIGEMCOMISS.USACOMISSAOPORRCA, -- 22
         P_REGORIGEMCOMISS.USACOMISSAOPORCLIENTE, -- 23
         P_REGORIGEMCOMISS.USACOMISSAOPORLINHAPROD, -- 24
         P_REGORIGEMCOMISS.COMISSAORCATIPOVENDA, -- 25
         P_REGORIGEMCOMISS.CONSIDERARCOMISSAOZERO -- 26
         );
    EXCEPTION
      WHEN OTHERS THEN
        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                         P_REGPEDIDO.NUMPEDINT,
                         P_REGPRODUTO.CODPROD,
                         P_REGITEM.CODAUXILIAR,
                         P_REGITEM.NUMSEQORIG,
                         P_REGPEDIDO.CODCLI,
                         P_REGPEDIDO.CODUSUR,
                         NULL,
                         NULL,
                         P_REGPEDIDO.INTEGRADORA,
                         143,
                         '3',
                         'Erro ao inserir origem comissão: ' || SQLCODE || '-' ||
                         SQLERRM || ';',
                         NULL);
    END;

    BEGIN
      INSERT INTO PCORIGEMDESC
        (NUMPED, --1
         ORIGEMPED, --2
         CODPROD, --3
         CODAUXILIAR, --4
         NUMSEQ, --5
         PTABELA, --6
         PEMBALAGEM, --7
         PERDESC, --8
         PERCBASERCA, --9
         PERCDESCPCATIVI, --10
         PERTXFIM, --11
         PERACRESPF, --12
         TIPODESC, --13
         CODROTINADESC, --14
         CODPOLITICADESC, --15
         CODROTINABASERCA, --16
         CODPOLITICABASERCA, --17
         BASEDEBCREDRCA, --18
         CREDITASOBREPOLITICABASERCA, --19
         PRIORITARIA, --20
         PRIORITARIAGERAL, --21
         ALTERAPTABELA, --22
         VALIDARPOLITICASDESCCLIBLOQ, --23
         PRECOFIXO --24
         )
      VALUES
        (P_REGORIGEMDESC.NUMPED, --1
         P_REGORIGEMDESC.ORIGEMPED, --2
         P_REGORIGEMDESC.CODPROD, --3
         P_REGORIGEMDESC.CODAUXILIAR, --4
         P_REGORIGEMDESC.NUMSEQ, --5
         P_REGORIGEMDESC.PTABELA, --6
         P_REGORIGEMDESC.PEMBALAGEM, --7
         P_REGORIGEMDESC.PERDESC, --8
         P_REGORIGEMDESC.PERCBASERCA, --9
         P_REGORIGEMDESC.PERCDESCPCATIVI, --10
         P_REGORIGEMDESC.PERTXFIM, --11
         P_REGORIGEMDESC.PERACRESPF, --12
         P_REGORIGEMDESC.TIPODESC, --13
         P_REGORIGEMDESC.CODROTINADESC, --14
         P_REGORIGEMDESC.CODPOLITICADESC, --15
         P_REGORIGEMDESC.CODROTINABASERCA, --16
         P_REGORIGEMDESC.CODPOLITICABASERCA, --17
         P_REGORIGEMDESC.BASEDEBCREDRCA, --18
         P_REGORIGEMDESC.CREDITASOBREPOLITICABASERCA, --19
         P_REGORIGEMDESC.PRIORITARIA, --20
         P_REGORIGEMDESC.PRIORITARIAGERAL, --21
         P_REGORIGEMDESC.ALTERAPTABELA, --22
         P_REGORIGEMDESC.VALIDARPOLITICASDESCCLIBLOQ, --23
         P_REGORIGEMDESC.PRECOFIXO --24
         );
    EXCEPTION
      WHEN OTHERS THEN
        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                         P_REGPEDIDO.NUMPEDINT,
                         P_REGPRODUTO.CODPROD,
                         P_REGITEM.CODAUXILIAR,
                         P_REGITEM.NUMSEQORIG,
                         P_REGPEDIDO.CODCLI,
                         P_REGPEDIDO.CODUSUR,
                         NULL,
                         NULL,
                         P_REGPEDIDO.INTEGRADORA,
                         144,
                         '3',
                         'Erro ao inserir origem desconto: ' || SQLCODE || '-' ||
                         SQLERRM || ';',
                         NULL);
    END;

    IF P_REGITEM.CESTA = 'S' THEN
      VBVALIDO := FUNC_INSERIRITEMCESTA(P_REGRCA,
                                        P_REGCLIENTE,
                                        P_REGITEM,
                                        P_REGPEDIDO,
                                        P_REGREGIAO,
                                        P_REGPLPAG,
                                        P_REGFILIAL);

      SELECT SUM(P.QTMP * VLCUSTOFIN),
             SUM(P.QTMP * VLCUSTOREAL),
             SUM(P.QTMP * VLCUSTOREP),
             SUM(P.QTMP * CUSTOFINEST),
             SUM(P.QTMP * VLCUSTOCONT),
             AVG(PERCOM)
        INTO VNVLCUSTOFIN,
             VNVLCUSTOREAL,
             VNVLCUSTOREP,
             VNCUSTOFINEST,
             VNVLCUSTOCONT,
             VNPERCOM
        FROM PCPEDICESTA P
       WHERE NUMPED = P_REGPEDIDO.NUMPED
         AND CODPROD = P_REGITEM.CODPROD
         AND NUMSEQ = P_REGITEM.NUMSEQ;

      UPDATE PCPEDI
         SET VLCUSTOFIN  = VNVLCUSTOFIN,
             VLCUSTOREAL = VNVLCUSTOREAL,
             VLCUSTOREP  = VNVLCUSTOREP,
             VLCUSTOCONT = VNVLCUSTOCONT,
             CUSTOFINEST = VNCUSTOFINEST,
             PERCOM      = VNPERCOM
       WHERE NUMPED = P_REGPEDIDO.NUMPED
         AND CODPROD = P_REGITEM.CODPROD
         AND NUMSEQ = P_REGITEM.NUMSEQ;
    ELSE
      VBVALIDO := TRUE;
    END IF;

    IF VBVALIDO = TRUE THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       P_REGPRODUTO.CODPROD,
                       P_REGITEM.CODAUXILIAR,
                       P_REGITEM.NUMSEQORIG,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       NULL,
                       '3',
                       'Erro9:' || SQLCODE || '-' || SQLERRM || ';',
                       NULL);
      RETURN FALSE;
  END FUNC_INSERIRITEMPEDIDO;


  FUNCTION FUNC_INSERIRCABPEDIDO(P_REGPEDIDO        IN OUT T_CABPED,
                                 P_REGPLPAG         IN T_PLANODEPAGAMENTO,
                                 P_REGRCA           IN T_RCA,
                                 P_REGCLIENTE       IN T_CLIENTEPEDIDO,
                                 P_REGREGIAO        IN T_REGIAOCLIENTE,
                                 P_REGFILIAL        IN T_FILIAL,
                                 P_CONTITENSVALIDOS IN NUMBER,
                                 P_VLTOTPED         IN NUMBER,
                                 P_VLTOTTAB         IN NUMBER,
                                 P_TOTPESOPED       IN NUMBER,
                                 P_TOTVOLUMEPED     IN NUMBER,
                                 P_VLCUSTOCONTPED   IN NUMBER,
                                 P_VLCUSTOFINPED    IN NUMBER,
                                 P_VLCUSTOREALPED   IN NUMBER,
                                 P_VLCUSTOREPPED    IN NUMBER,
                                 P_CODDISTRIB       IN PCPRODUT.CODDISTRIB%TYPE)
    RETURN BOOLEAN IS
    VNPERDESCPED NUMBER;

    AT_VLATEND     PCPEDC.VLATEND%TYPE;
    AT_VLTABELA    PCPEDC.VLTABELA%TYPE;
    AT_NUMITENS    PCPEDC.NUMITENS%TYPE;
    AT_VLTOTAL     PCPEDC.VLTOTAL%TYPE;
    AT_VLCUSTOFIN  PCPEDC.VLCUSTOFIN%TYPE;
    AT_VLCUSTOREP  PCPEDC.VLCUSTOREP%TYPE;
    AT_VLCUSTOREAL PCPEDC.VLCUSTOREAL%TYPE;
    AT_VLCUSTOCONT PCPEDC.VLCUSTOCONT%TYPE;
    AT_TOTPESO     PCPEDC.TOTPESO%TYPE;
    AT_TOTVOLUME   PCPEDC.TOTVOLUME%TYPE;

    P_TIPOCONTACORRENTE PCPEDC.TIPOCONTACORRENTE%TYPE;

  BEGIN
    VNPERDESCPED := 0;
    IF NVL(P_VLTOTTAB,0) <> 0 THEN
      VNPERDESCPED := ROUND((((P_VLTOTTAB - P_VLTOTPED) / P_VLTOTTAB) * 100), GREGPCCONSUM.NUMCASASDECVENDA);
    END IF;

    IF NVL(P_VLTOTPED,0) <> 0 THEN
      P_REGPEDIDO.PERDESCFIN := ROUND(((NVL(P_REGPEDIDO.VLDESCONTOFINANCEIRO,0) * 100) / P_VLTOTPED), GREGPCCONSUM.NUMCASASDECVENDA);
    END IF;

    IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
      P_TIPOCONTACORRENTE := FUNC_TIPOCONTACORRENTE(P_REGPEDIDO.CONDVENDA,P_VLTOTPED,P_VLTOTTAB);

      INSERT INTO PCPEDC
        (CODCLI,
         CODCOB,
         CODDISTRIB,
         CODEMITENTE,
         CODFILIAL,
         CODFILIALNF,
         CODPLPAG,
         CODPRACA,
         CODSUPERVISOR,
         CODUSUR,
         CONDVENDA,
         DATA,
         DTENTREGA,
         HORA,
         MINUTO,
         NUMCAR,
         NUMITENS,
         NUMPED,
         NUMPEDCLI,
         NUMPEDRCA,
         NUMPEDWEB,
         OBS1,
         OBS2,
         OBSENTREGA1,
         OBSENTREGA2,
         OPERACAO,
         ORIGEMPED,
         PERCVENDA,
         PERDESC,
         POSICAO,
         PRAZO1,
         PRAZO2,
         PRAZO3,
         PRAZO4,
         PRAZO5,
         PRAZO6,
         PRAZO7,
         PRAZO8,
         PRAZO9,
         PRAZO10,
         PRAZO11,
         PRAZO12,
         PRAZOMEDIO,
         TIPOVENDA,
         TOTPESO,
         TOTVOLUME,
         VLATEND,
         VLCUSTOCONT,
         VLCUSTOFIN,
         VLCUSTOREAL,
         VLCUSTOREP,
         VLTABELA,
         VLTOTAL,
         NUMREGIAO,
         USAINTEGRACAOWMS,
         USACREDRCA,
         USADEBCREDRCA,
         BONIFICALTDEBCREDRCA,
         TROCAALTDEBCREDRCA,
         CRMALTDEBCREDRCA,
         BROKERALTDEBCREDRCA,
         TIPOMOVCCRCA,
         CODAUTORIZACAOTEF,
         NSUTEF,
         CODADMCARTAO,
         CODMOTIVO,
         CODMOTBLOQUEIO,
         LOG,
         USASALDOCONTACORRENTEDESCFIN,
         PERDESCFIN,
         INTEGRADORA,
         EANENTREGA,
         EANCOBRANCA,
         VLFRETE,
         MOTIVOPOSICAO,
         DTABERTURAPEDPALM,
         FRETEDESPACHO,
         CODTRANSP,
         CODAUTORIZACAOTEFWEB,
         NUMPEDTV1,
         AGRUPAMENTO,
         BROKER,
         TURNOENTREGA,
         VLENTRADA,
         CODENDENTCLI,
         CODCLINF,
         CODCLIRECEBEDOR,
         CODESTABELECIMENTO,
         NUMTABELA,
         UTILIZAVENDAPOREMBALAGEM,
         CODFORNECFRETE,
         CODCLITV8,
         PEDIDOPAGOECOMMERCE,
         TIPODOCUMENTO,
         VLOUTRASDESP,
         TIPOCONTACORRENTE,
         VLDESCONTOCUPOM,
		 CNPJINTERMEDIADOR,
		 DESCINTERMEDIADOR,
		 CODBNF
         )
      VALUES
        (P_REGPEDIDO.CODCLI,
         P_REGPEDIDO.CODCOB,
         P_REGRCA.CODDISTRIB,
         P_REGPEDIDO.CODEMITENTE,
         P_REGPEDIDO.CODFILIAL,
         NVL(P_REGPEDIDO.CODFILIALNF, P_REGCLIENTE.CODFILIALNF),
         P_REGPEDIDO.CODPLPAG,
         P_REGCLIENTE.CODPRACA,
         P_REGRCA.CODSUPERVISOR,
         P_REGRCA.CODUSUR,
         P_REGPEDIDO.CONDVENDA,
         TRUNC(SYSDATE),
         NVL(P_REGPEDIDO.DTENTREGA, TRUNC(SYSDATE)),
         TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
         TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
         0,
         P_CONTITENSVALIDOS,
         P_REGPEDIDO.NUMPED,
         P_REGPEDIDO.NUMPEDCLI,
         P_REGPEDIDO.NUMPEDRCA,
         P_REGPEDIDO.NUMPEDWEB,
         P_REGPEDIDO.OBS1,
         P_REGPEDIDO.OBS2,
         P_REGPEDIDO.OBSENTREGA1,
         P_REGPEDIDO.OBSENTREGA2,
         'N',
         P_REGPEDIDO.ORIGEMPED,
         P_REGPEDIDO.PERCVENDA,
         VNPERDESCPED,
         P_REGPEDIDO.POSICAO,
         P_REGPLPAG.PRAZO1,
         P_REGPLPAG.PRAZO2,
         P_REGPLPAG.PRAZO3,
         P_REGPLPAG.PRAZO4,
         P_REGPLPAG.PRAZO5,
         P_REGPLPAG.PRAZO6,
         P_REGPLPAG.PRAZO7,
         P_REGPLPAG.PRAZO8,
         P_REGPLPAG.PRAZO9,
         P_REGPLPAG.PRAZO10,
         P_REGPLPAG.PRAZO11,
         P_REGPLPAG.PRAZO12,
         NVL(P_REGPEDIDO.PRAZOMEDIO, P_REGPLPAG.NUMDIAS),
         P_REGPLPAG.TIPOVENDA,
         P_TOTPESOPED,
         P_TOTVOLUMEPED,
         DECODE(P_REGPEDIDO.CONDVENDA, 5, 0,
                DECODE(P_REGPEDIDO.CONDVENDA, 6, 0,
                       DECODE(P_REGPEDIDO.CONDVENDA, 11, 0,
                              DECODE(P_REGPEDIDO.CONDVENDA, 12, 0,
                                     DECODE(P_REGPEDIDO.CONDVENDA, 20, 0,
                                            P_VLTOTPED))))),
         P_VLCUSTOCONTPED,
         DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, P_VLCUSTOFINPED),
         DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, P_VLCUSTOREALPED),
         DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, P_VLCUSTOREPPED),
         DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, P_VLTOTTAB + NVL(P_REGPEDIDO.VLFRETE, 0)),
         P_VLTOTPED + NVL(P_REGPEDIDO.VLFRETE, 0),
         P_REGREGIAO.NUMREGIAO,
         P_REGFILIAL.USAINTEGRACAOWMS,
         P_REGPEDIDO.USACREDRCA,
         P_REGPEDIDO.USADEBCREDRCA,
         P_REGPEDIDO.BONIFICALTDEBCREDRCA,
         P_REGPEDIDO.TROCAALTDEBCREDRCA,
         P_REGPEDIDO.CRMALTDEBCREDRCA,
         P_REGPEDIDO.BROKERALTDEBCREDRCA,
         P_REGPEDIDO.TIPOMOVCCRCA,
         P_REGPEDIDO.CODAUTORIZACAOTEF,
         P_REGPEDIDO.NSUTEF,
         P_REGPEDIDO.CODADMCARTAO,
         P_REGPEDIDO.CODMOTIVO,
         P_REGPEDIDO.CODMOTBLOQUEIO,
         P_REGPEDIDO.LOG,
         P_REGPEDIDO.USASALDOCONTACORRENTEDESCFIN,
         P_REGPEDIDO.PERDESCFIN,
         P_REGPEDIDO.INTEGRADORA,
         P_REGPEDIDO.EANENTREGA,
         P_REGPEDIDO.EANCOBRANCA,
         P_REGPEDIDO.VLFRETE,
         P_REGPEDIDO.MOTIVOPOSICAO,
         P_REGPEDIDO.DTABERTURAPEDPALM,
         P_REGPEDIDO.FRETEDESPACHO,
         P_REGPEDIDO.CODTRANSP,
         P_REGPEDIDO.CODAUTORIZACAOTEFWEB,
         P_REGPEDIDO.NUMPEDTV1,
         P_REGPEDIDO.AGRUPAMENTO,
         P_REGFILIAL.BROKER,
         P_REGPEDIDO.TURNOENTREGA,
         P_REGPEDIDO.VLENTRADA,
         P_REGPEDIDO.CODENDENTCLI,
         P_REGPEDIDO.CODCLINF,
         P_REGPEDIDO.CODCLIRECEBEDOR,
         P_REGREGIAO.CODESTABELECIMENTO,
         P_REGPEDIDO.NUMTABELA,
         P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM,
         P_REGPEDIDO.CODFORNECFRETE,
         P_REGPEDIDO.CODCLITV8,
         P_REGPEDIDO.PEDIDOPAGOECOMMERCE,
         'A',
         P_REGPEDIDO.VLOUTRASDESP,
         P_TIPOCONTACORRENTE,
         P_REGPEDIDO.VLDESCONTOCUPOM,
         P_REGPEDIDO.CNPJINTERMEDIADOR,
         P_REGPEDIDO.DESCINTERMEDIADOR,
		 P_REGPEDIDO.CODBNF
	    );
    ELSE
      SELECT SUM(NVL(PCPEDI.PVENDA, 0) * NVL(PCPEDI.QT, 0)), --1
             SUM(NVL(PCPEDI.PTABELA, 0) * NVL(PCPEDI.QT, 0)), --2
             COUNT(*), --3
             SUM((NVL(PCPEDI.QT, 0) + NVL(PCPEDI.QTFALTA, 0)) * NVL(PCPEDI.PVENDA, 0)), --4
             SUM(NVL(PCPEDI.VLCUSTOFIN, 0) * NVL(PCPEDI.QT, 0)), --5
             SUM(NVL(PCPEDI.VLCUSTOREP, 0) * NVL(PCPEDI.QT, 0)), --6
             SUM(NVL(PCPEDI.VLCUSTOREAL, 0) * NVL(PCPEDI.QT, 0)), --7
             SUM(NVL(PCPEDI.VLCUSTOCONT, 0) * NVL(PCPEDI.QT, 0)), --8
             SUM(NVL(PCPRODUT.PESOBRUTO, 0) * NVL(PCPEDI.QT, 0)), --9
             SUM(NVL(PCPRODUT.VOLUME, 0) * NVL(PCPEDI.QT, 0)) --10
        INTO AT_VLATEND, --1
             AT_VLTABELA, --2
             AT_NUMITENS, --3
             AT_VLTOTAL, --4
             AT_VLCUSTOFIN, --5
             AT_VLCUSTOREP, --6
             AT_VLCUSTOREAL, --7
             AT_VLCUSTOCONT, --8
             AT_TOTPESO, --9
             AT_TOTVOLUME --10
        FROM PCPEDI, PCPRODUT
       WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
         AND PCPEDI.CODPROD = PCPRODUT.CODPROD;
      UPDATE PCPEDC
         SET VLATEND     = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, AT_VLATEND),
             VLTABELA    = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, AT_VLTABELA),
             NUMITENS    = AT_NUMITENS,
             VLTOTAL     = AT_VLTOTAL,
             VLCUSTOFIN  = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, AT_VLCUSTOFIN),
             VLCUSTOREP  = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, AT_VLCUSTOREP),
             VLCUSTOREAL = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, AT_VLCUSTOREAL),
             VLCUSTOCONT = AT_VLCUSTOCONT,
             TOTPESO     = AT_TOTPESO,
             TOTVOLUME   = AT_TOTVOLUME
       WHERE NUMPED = P_REGPEDIDO.NUMPED;
    END IF;

    UPDATE PCCLIENT P
       SET P.DTULTCOMP = TRUNC(SYSDATE)
     WHERE CODCLI = P_REGPEDIDO.CODCLI;

    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       NULL,
                       '2',
                       'Erro10:' || SQLCODE || '-' || SQLERRM || ';',
                       NULL);
      RETURN FALSE;
  END FUNC_INSERIRCABPEDIDO;

  PROCEDURE PROC_VALIDACAOFINALCABPOSCORTE(P_REGPEDIDO        IN OUT T_CABPED,
                                           P_REGPLPAG         IN T_PLANODEPAGAMENTO,
                                           P_REGFILIAL        IN T_FILIAL,
                                           P_REGRCA           IN T_RCA,
                                           P_VLTOTPED         IN NUMBER,
                                           P_VLATENDPED       IN NUMBER,
                                           P_NUMSEQ           IN NUMBER,
                                           P_CONTITENSVALIDOS IN NUMBER) IS

    VSMENSAGEM    VARCHAR2(32767);
    VSCHAR        VARCHAR2(1) DEFAULT '#';
    VNVLMINPEDIDO PCCOB.VLMINPEDIDO%TYPE;
    VBVALIDO        BOOLEAN;
    VNVLFALTA       NUMBER;
    VSMOTIVOPOSICAO PCPEDC.MOTIVOPOSICAO%TYPE;
    VNCODMOTIVO     PCPEDC.CODMOTIVO%TYPE;
  BEGIN
    VSMENSAGEM      := NULL;
    VBVALIDO        := TRUE;
    VSMOTIVOPOSICAO := NULL;
    VNCODMOTIVO     := NULL;

    SELECT NVL(P_VLTOTPED, 0) - NVL(P_VLATENDPED, 0)
      INTO VNVLFALTA
      FROM DUAL;

    IF P_VLTOTPED > GREGPCCONSUM.VLMAXVENDA AND
       NVL(GREGPCCONSUM.VLMAXVENDA, 0) > 0 THEN
      VBVALIDO        := FALSE;
      VNCODMOTIVO     := 4;
      VSMOTIVOPOSICAO := 'Pedido excede valor maximo por pedido.';

      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido de(' || P_VLTOTPED ||
                    ') execede o valor maximo estipulado por pedido (' ||
                    GREGPCCONSUM.VLMAXVENDA || ' ).';
    END IF;

    --Por rca
    IF NVL(P_REGRCA.VLVENDAMINPED, 0) > 0 THEN
      IF P_VLATENDPED < NVL(P_REGRCA.VLVENDAMINPED, 0) THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' ||
                      P_VLATENDPED || ') Valor da falta (' || VNVLFALTA;
        VSMENSAGEM := VSMENSAGEM || ') menor que o#' || ';';
        VSMENSAGEM := VSMENSAGEM || 'mínimo permitido para o RCA: ' ||
                      P_REGRCA.VLVENDAMINPED || ';';

        VBVALIDO        := FALSE;
        VSMOTIVOPOSICAO := 'Valor do pedido menor que minimo para o RCA';
        VNCODMOTIVO     := 8;
      END IF;
    END IF;

    --Por Plano de Pagamento
    IF P_REGPLPAG.VLMINPEDIDO > 0 THEN
      IF P_VLATENDPED < P_REGPLPAG.VLMINPEDIDO THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' ||
                      P_VLATENDPED || ') Valor da falta (' || VNVLFALTA;
        VSMENSAGEM := VSMENSAGEM || ') menor que o#' || ';';
        VSMENSAGEM := VSMENSAGEM || 'mínimo permitido para o Plano de Pagamento: ' ||
                      P_REGPLPAG.VLMINPEDIDO || ';';
        VBVALIDO        := FALSE;
        VSMOTIVOPOSICAO := 'Valor do pedido menor que o minimo para Plano de Pagamento';
        VNCODMOTIVO     := 10;
      END IF;
    END IF;

    IF P_CONTITENSVALIDOS < P_REGPLPAG.NUMITENSMINIMO THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Numero de itens (' ||
                    P_CONTITENSVALIDOS || ') menor que o#';
      VSMENSAGEM := VSMENSAGEM || 'mínimo para o plano de pagamento: ' ||
                    P_REGPLPAG.CODPLPAG || ';';
      VBVALIDO   := FALSE;
    END IF;

    BEGIN
      SELECT NVL(PCCOB.VLMINPEDIDO, 0)
        INTO VNVLMINPEDIDO
        FROM PCCOB
       WHERE CODCOB = P_REGPEDIDO.CODCOB;
    EXCEPTION
      WHEN OTHERS THEN
        VNVLMINPEDIDO := 0;
    END;

    IF VNVLMINPEDIDO > 0 THEN
      IF P_VLATENDPED < VNVLMINPEDIDO THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' ||
                      P_VLATENDPED || ') Valor da falta (' || VNVLFALTA;
        VSMENSAGEM := VSMENSAGEM || ') menor que o#' || ';';
        VSMENSAGEM := VSMENSAGEM || 'mínimo permitido para a Cobrança: ' ||
                      VNVLMINPEDIDO || ';';

        VBVALIDO        := FALSE;
        VSMOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para cobrança';
        VNCODMOTIVO     := 9;
      END IF;
    END IF;

    IF P_REGPEDIDO.ORIGEMPED <> 'R' OR
       (P_REGPEDIDO.ORIGEMPED = 'R' AND
       P_REGFILIAL.VALIDAVLMINVENDABALCAO = 'S') THEN
      IF P_REGPEDIDO.CONDVENDA IN (1, 7, 13) AND
         P_REGFILIAL.VLMINVENDAFV > 0 THEN
        IF P_VLTOTPED < P_REGFILIAL.VLMINVENDAFV THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' ||
                        P_VLATENDPED || ') Valor da falta (' || VNVLFALTA;
          VSMENSAGEM := VSMENSAGEM || ') menor que o#' || ';';
          VSMENSAGEM := VSMENSAGEM || 'mínimo permitido para a Filial: ' ||
                        P_REGFILIAL.VLMINVENDAFV || ';';

          VBVALIDO        := FALSE;
          VSMOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para a Filial';

          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 43;
          VNCODMOTIVO             := 11;
        END IF;
      ELSIF P_REGPEDIDO.CONDVENDA = 5 THEN
        IF P_VLTOTPED > NVL(GREGPCCONSUM.VLMAXVENDABNF, 0) AND
           NVL(GREGPCCONSUM.VLMAXVENDABNF, 0) > 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' ||
                        P_VLTOTPED || ') maior que o #';
          VSMENSAGEM := VSMENSAGEM || 'maximo para o pedido bonificado (' ||
                        NVL(GREGPCCONSUM.VLMAXVENDABNF, 0) || ');';

          VBVALIDO        := FALSE;
          VSMOTIVOPOSICAO := 'Valor do Pedido maior que o maximo para a Filial';

          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 43;
        END IF;

        IF P_VLTOTPED < P_REGFILIAL.VLMINVENDABNFFV AND
           P_REGFILIAL.VLMINVENDABNFFV > 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' ||
                        P_VLTOTPED || ') menor que o #';
          VSMENSAGEM := VSMENSAGEM || 'mínimo para o pedido bonificado (' ||
                        P_REGFILIAL.VLMINVENDABNFFV || ');';

          VBVALIDO        := FALSE;
          VSMOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para a Filial';

          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 43;
        END IF;
      END IF;
    END IF;

    IF VBVALIDO = FALSE THEN
      IF P_REGFILIAL.BLOQUEARPEDIDOSABAIXOVLMINIMO = 'S' THEN
        P_REGPEDIDO.POSICAO       := 'B';
        P_REGPEDIDO.MOTIVOPOSICAO := VSMOTIVOPOSICAO;
        P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || VSMOTIVOPOSICAO;
        P_REGPEDIDO.CODMOTIVO     := VNCODMOTIVO;

        FOR REG_ITENS IN (SELECT PCPEDI.CODPROD,
                                 PCPEDI.QT,
                                 PCPEDI.PVENDA,
                                 PCPEDI.NUMSEQ,
                                 CODAUXILIAR,
                                 NVL(QTUNITEMB, 1) QTUNITEMB,
                                 CODFILIALRETIRA
                            FROM PCPEDI
                           WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                             AND PCPEDI.NUMSEQ > P_NUMSEQ) 
        LOOP
          UPDATE PCEST
             SET PCEST.QTRESERV   = NVL(PCEST.QTRESERV, 0) - REG_ITENS.QT,
                 PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) + REG_ITENS.QT
           WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIALRETIRA
             AND PCEST.CODPROD = REG_ITENS.CODPROD;
        END LOOP;

        UPDATE PCPEDI SET POSICAO = 'B' WHERE NUMPED = P_REGPEDIDO.NUMPED;

        UPDATE PCPEDC SET POSICAO = 'B' WHERE NUMPED = P_REGPEDIDO.NUMPED;

        IF P_REGPEDIDO.POSICAO = 'B' THEN
           PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
        END IF;
      ELSE
        P_REGPEDIDO.VALIDO := FALSE;

        FOR REG_ITENS IN (SELECT PCPEDI.CODPROD,
                                 PCPEDI.QT,
                                 PCPEDI.PVENDA,
                                 PCPEDI.NUMSEQ,
                                 CODAUXILIAR,
                                 NVL(QTUNITEMB, 1) QTUNITEMB,
                                 CODFILIALRETIRA
                            FROM PCPEDI
                           WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                             AND PCPEDI.NUMSEQ > P_NUMSEQ) 
        LOOP
          DELETE FROM PCPEDI
           WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
             AND PCPEDI.CODPROD = REG_ITENS.CODPROD
             AND PCPEDI.NUMSEQ = REG_ITENS.NUMSEQ
             AND (CODAUXILIAR = REG_ITENS.CODAUXILIAR OR
                 CODAUXILIAR IS NULL);

          DELETE FROM PCORIGEMPRECO
           WHERE NUMPED = P_REGPEDIDO.NUMPED
             AND CODPROD = REG_ITENS.CODPROD
             AND NUMSEQ = REG_ITENS.NUMSEQ;

          UPDATE PCEST
             SET PCEST.QTRESERV = NVL(PCEST.QTRESERV, 0) - REG_ITENS.QT
           WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIALRETIRA
             AND PCEST.CODPROD = REG_ITENS.CODPROD;
        END LOOP;

        DELETE FROM PCPEDC WHERE NUMPED = P_REGPEDIDO.NUMPED;
      END IF;
    END IF;

    -- registra log
    IF (VSMENSAGEM IS NOT NULL) THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       NULL,
                       '2',
                       'Erro11:' || VSMENSAGEM,
                       NULL);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      P_REGPEDIDO.VALIDO := FALSE;
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       NULL,
                       '2',
                       'Erro12:' || SQLCODE || '-' || SQLERRM,
                       NULL);
  END PROC_VALIDACAOFINALCABPOSCORTE;


  PROCEDURE PROC_GRAVALOGCONVEMBALAGEM(P_NUMPED                    IN PCPEDC.NUMPED%TYPE,
                                       P_CODFILIAL                 IN PCPEDC.CODFILIAL%TYPE,
                                       P_CODPROD                   IN PCPEDI.CODPROD%TYPE,
                                       P_QTESTGER                  IN PCEST.QTESTGER%TYPE,
                                       VBGRAVOULOGCONVERSAOESTOQUE OUT BOOLEAN,
                                       P_MENSAGEM                  OUT VARCHAR2) IS
    VNQTESTGER_DEPOIS      NUMBER;
    VNNUMTRANSVENDA        NUMBER;
    VNCODPROD_MASTER       NUMBER;
    VNQT_MASTER            NUMBER;
    VNQTESTGER_MASTER      NUMBER;
    VBBUSCOUDADOSCONVERSAO BOOLEAN;
    VICONT                 NUMBER;
    VSPROGRAMA             VARCHAR2(80);
    VNQT                   NUMBER;
  BEGIN
    --Buscar dados da Conversão
    VBBUSCOUDADOSCONVERSAO := FALSE;
    P_MENSAGEM             := NULL;

    SELECT COUNT(*)
      INTO VICONT
      FROM PCMOV
     WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
       AND PCMOV.CODPROD = P_CODPROD
       AND PCMOV.CODFILIAL = P_CODFILIAL
       AND NVL(PCMOV.CODOPER, 'X') = 'EP'
     GROUP BY PCMOV.NUMTRANSVENDA
     ORDER BY PCMOV.NUMTRANSVENDA DESC;

    IF VICONT IS NOT NULL THEN
      BEGIN
        SELECT PCMOV.NUMTRANSVENDA, SUM(PCMOV.QT) QT
          INTO VNNUMTRANSVENDA, VNQT
          FROM PCMOV
         WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
           AND PCMOV.CODPROD = P_CODPROD
           AND PCMOV.CODFILIAL = P_CODFILIAL
           AND NVL(PCMOV.CODOPER, 'X') = 'EP'
         GROUP BY PCMOV.NUMTRANSVENDA
         ORDER BY PCMOV.NUMTRANSVENDA DESC;
      EXCEPTION
        WHEN OTHERS THEN
          VNNUMTRANSVENDA := NULL;
          VNQT            := 0;
      END;

      VNQTESTGER_DEPOIS := P_QTESTGER + VNQT;

      IF VNNUMTRANSVENDA IS NOT NULL THEN
        SELECT COUNT(*)
          INTO VICONT
          FROM PCMOV, PCEST
         WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
           AND PCMOV.NUMTRANSVENDA = VNNUMTRANSVENDA
           AND PCMOV.CODFILIAL = P_CODFILIAL
           AND PCMOV.CODPROD = PCEST.CODPROD
           AND PCMOV.CODFILIAL = PCEST.CODFILIAL
           AND NVL(PCMOV.CODOPER, 'X') = 'SP';

        IF VICONT <> 0 THEN
          SELECT PCMOV.CODPROD, PCMOV.QT, PCEST.QTESTGER
            INTO VNCODPROD_MASTER, VNQT_MASTER, VNQTESTGER_MASTER
            FROM PCMOV, PCEST
           WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
             AND PCMOV.NUMTRANSVENDA = VNNUMTRANSVENDA
             AND PCMOV.CODFILIAL = P_CODFILIAL
             AND PCMOV.CODPROD = PCEST.CODPROD
             AND PCMOV.CODFILIAL = PCEST.CODFILIAL
             AND NVL(PCMOV.CODOPER, 'X') = 'SP';

          VBBUSCOUDADOSCONVERSAO := TRUE;
        END IF;
      END IF;
    END IF;

    IF VBBUSCOUDADOSCONVERSAO = TRUE THEN
      BEGIN
        -- utilização do rownum. Se a alteração for disparada por um usuário com permissão de sysdba
        -- ou for um job cadastrado por este usuário, o USERENV('SESSIONID') deste usuário é null.
        SELECT SUBSTR(PROGRAM, 1, 80)
          INTO VSPROGRAMA
          FROM USUARIOS_LOGADOS
         WHERE AUDSID = USERENV('SESSIONID')
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          VSPROGRAMA := NULL;
      END;

      --Gravação de log do acesso a esta permissão
      INSERT INTO PCLOGALTERACAODADOS
        (DATA,
         CODFUNC,
         CODROTINA,
         TABELA,
         COLUNA,
         TIPOVALOR,
         VALORNUM,
         VALORNUMANT,
         VALORALFA,
         VALORALFAANT,
         USACTRLACESSO,
         CODCTRLACESSO,
         OBSERVACOES,
         MAQUINA,
         PROGRAMA,
         TERMINAL,
         OSUSER)
      VALUES
        (SYSDATE,
         8888,
         2513,
         'PCEST',
         'QTESTGER',
         'N',
         VNQTESTGER_DEPOIS,
         P_QTESTGER,
         NULL,
         NULL,
         'S',
         NULL,
         'CONV. EMB. PROD. ' || ' PED.: ' || P_NUMPED,
         'PRODUCAO',
         VSPROGRAMA,
         P_NUMPED,
         P_CODPROD);

      INSERT INTO PCLOGALTERACAODADOS
        (DATA,
         CODFUNC,
         CODROTINA,
         TABELA,
         COLUNA,
         TIPOVALOR,
         VALORNUM,
         VALORNUMANT,
         VALORALFA,
         VALORALFAANT,
         USACTRLACESSO,
         CODCTRLACESSO,
         OBSERVACOES,
         MAQUINA,
         PROGRAMA,
         TERMINAL,
         OSUSER)
      VALUES
        (SYSDATE,
         8888,
         2513,
         'PCEST',
         'QTESTGER',
         'N',
         VNQTESTGER_MASTER,
         VNQTESTGER_MASTER + VNQT_MASTER,
         NULL,
         NULL,
         'S',
         NULL,
         'CONV. EMB. PROD. ' || ' PED.: ' || P_NUMPED,
         'REQUISICAO',
         VSPROGRAMA,
         P_NUMPED,
         VNCODPROD_MASTER);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_MENSAGEM := 'Erro ao gravar log de conversão de embalagem : ' ||
                    SQLCODE || ' ' || SQLERRM;
  END PROC_GRAVALOGCONVEMBALAGEM;


  PROCEDURE PROC_CONVERTE_ESTOQUE(P_CONDVENDA    IN PCPEDC.CONDVENDA%TYPE,
                                  P_NUMPED       IN PCPEDC.NUMPED%TYPE,
                                  P_CODFILIAL    IN PCPEDC.CODFILIAL%TYPE,
                                  P_CODPROD      IN PCPEDI.CODPROD%TYPE,
                                  P_UNIDADE      IN PCPRODUT.UNIDADE%TYPE,
                                  P_QTSOLICITADA IN NUMBER,
                                  P_QTESTGER     IN NUMBER,
                                  P_QTATENDIDA   OUT NUMBER,
                                  P_MENSAGEM     OUT VARCHAR2,
                                  P_CODRETORNOS  IN OUT NUMBER) IS
    VNQTATENDIDA    NUMBER;
    VNCODPRODMASTER PCPRODUT.CODPRODMASTER%TYPE;
    VICONT          NUMBER;
    VSMENSAGEM      VARCHAR2(1000);
    VBGRAVOULOG     BOOLEAN;
    VSMENSAGEMLOG   VARCHAR2(1000);
  BEGIN
    VNQTATENDIDA := 0;

    IF GREGPCCONSUM.USACONVERSAOEMBALAGEM = 'S' THEN
      --Verificar se produto é filho de algum outro produto}
      SELECT NVL(CODPRODMASTER, CODPROD) CODPRODMASTER
        INTO VNCODPRODMASTER
        FROM PCPRODUT
       WHERE CODPROD = P_CODPROD;

      IF P_CODPROD <> VNCODPRODMASTER THEN
        --verifica se pai existe
        SELECT COUNT(*)
          INTO VICONT
          FROM PCPRODUT
         WHERE CODPROD = VNCODPRODMASTER;

        IF VICONT > 0 THEN
          PRC_CONVERSAO_ESTOQUE_PACOTE(P_CONDVENDA,
                                       P_CODFILIAL,
                                       P_CODPROD,
                                       P_QTSOLICITADA,
                                       VSMENSAGEM);

          IF VSMENSAGEM <> 'CONVERSAO REALIZADA COM SUCESSO!!!' THEN
            P_MENSAGEM := 'Não foi possível converter estoque de caixa para o produto solicitado  : ' ||
                          P_CODPROD || CHR(13) || 'Erro: ' || VSMENSAGEM;

            VNQTATENDIDA  := P_QTSOLICITADA;
            P_CODRETORNOS := 146;
          ELSE
            PROC_GRAVALOGCONVEMBALAGEM(P_NUMPED,
                                       P_CODFILIAL,
                                       P_CODPROD,
                                       P_QTESTGER,
                                       VBGRAVOULOG,
                                       VSMENSAGEMLOG);
            P_CODRETORNOS := 145;
          END IF;
        ELSE
          VNQTATENDIDA := P_QTSOLICITADA;
        END IF;
      ELSE
        VNQTATENDIDA := P_QTSOLICITADA;
      END IF;
    ELSE
      VNQTATENDIDA := P_QTSOLICITADA;
    END IF;
  END PROC_CONVERTE_ESTOQUE;


PROCEDURE PROC_VERIFICAESTOQUE(P_REGPEDIDO  IN OUT T_CABPED,
                               P_REGFILIAL  IN T_FILIAL,
                               P_REGCLIENTE IN T_CLIENTEPEDIDO,
                               P_NUMSEQ     IN NUMBER) 
IS
   CURSOR CR_ESTOQUE(P_NUMPED PCPEDC.NUMPED%TYPE) IS
      SELECT *
      FROM PCEST
      WHERE EXISTS (SELECT PCPEDI.CODPROD
                    FROM PCPEDI
                    WHERE PCPEDI.NUMPED = P_NUMPED
                      AND PCPEDI.CODPROD = PCEST.CODPROD
                      AND PCEST.CODFILIAL = PCPEDI.CODFILIALRETIRA
                      AND PCPEDI.NUMSEQ > P_NUMSEQ)
      FOR UPDATE;

   VNQTDISPONIVEL      NUMBER;
   VBFAZRESERVAESTOQUE BOOLEAN;
   VNQTDISPONIVEL_CONT NUMBER;
   VNQTTOTPROD         NUMBER;
   VSUNIDADE              PCPRODUT.UNIDADE%TYPE;
   VNCONTPRODCONVESTOQUE  NUMBER;
   VNQTATENDCONV          NUMBER;
   VSMENSAGEM_CONVESTOQUE VARCHAR2(1000);
   VNQTESTGER             PCEST.QTESTGER%TYPE;
   VNQTRESERV             PCEST.QTRESERV%TYPE;
   VNQTBLOQUEADA          PCEST.QTBLOQUEADA%TYPE;
   VNQTMINAUTOSERVICO     NUMBER;
   VNMULTIPLO               PCPRODUT.MULTIPLO%TYPE;
   VNMULTIPLO_PROD          PCPRODUT.MULTIPLO%TYPE;
   VSCHECARMULTIPLOVENDABNF PCPRODUT.CHECARMULTIPLOVENDABNF%TYPE;
   VSACEITAVENDAFRACAO_PROD      PCPRODUT.ACEITAVENDAFRACAO%TYPE;
   VSACEITAVENDAFRACAO           PCPRODFILIAL.ACEITAVENDAFRACAO%TYPE;
   VSCHECARMULTIPLOVENDABNF_PROD PCPRODUT.CHECARMULTIPLOVENDABNF%TYPE;
   VNQTPENDENTE                  PCEST.QTPENDENTE%TYPE;
BEGIN
   VBFAZRESERVAESTOQUE   := TRUE;
   VNCONTPRODCONVESTOQUE := 0;

   FOR CR_PCEST IN CR_ESTOQUE(P_REGPEDIDO.NUMPED) 
   LOOP
      FOR REGITENS IN (SELECT PCPEDI.QT,
                              PCPEDI.CODFILIALRETIRA,
                              PCPEDI.NUMSEQ,
                              CODAUXILIAR,
                              NVL(PCPEDI.QTUNITEMB, 1) QTUNITEMB,
                              PCPEDI.NUMAPLIC
                       FROM PCPEDI
                       WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                         AND PCPEDI.CODPROD = CR_PCEST.CODPROD
                         AND PCPEDI.NUMSEQ > P_NUMSEQ
                         AND PCPEDI.CODFILIALRETIRA = CR_PCEST.CODFILIAL)
      LOOP
         --verificar se tem no mesmo pedidos outros itens com mesmo codprod
         VNQTTOTPROD := 0;

         SELECT SUM(QT)
         INTO VNQTTOTPROD
         FROM PCPEDI
         WHERE NUMPED = P_REGPEDIDO.NUMPED
           AND CODPROD = CR_PCEST.CODPROD
           AND NUMSEQ < REGITENS.NUMSEQ
           AND CODFILIALRETIRA = REGITENS.CODFILIALRETIRA;

         VNQTDISPONIVEL      := GREATEST(NVL(CR_PCEST.QTESTGER, 0), 0) - GREATEST(NVL(CR_PCEST.QTRESERV, 0), 0) -
                                GREATEST(NVL(CR_PCEST.QTBLOQUEADA, 0), 0) - NVL(VNQTTOTPROD, 0);
         VNQTDISPONIVEL_CONT := GREATEST(CR_PCEST.QTEST, 0) - GREATEST(CR_PCEST.QTRESERV, 0) - NVL(VNQTTOTPROD, 0);

         IF GREGPCCONSUM.BLOQUEIAVENDAESTPENDENTE = 'S' THEN
            VNQTDISPONIVEL := VNQTDISPONIVEL - (GREATEST(NVL(CR_PCEST.QTPENDENTE, 0), 0));
            VNQTDISPONIVEL_CONT := VNQTDISPONIVEL_CONT - (GREATEST(NVL(CR_PCEST.QTPENDENTE, 0), 0));
         END IF;

         IF VNQTDISPONIVEL_CONT < 0 THEN
            VNQTDISPONIVEL_CONT := 0;
         END IF;

         IF VNQTDISPONIVEL < 0 THEN
            VNQTDISPONIVEL := 0;
         END IF;
         
         VNQTDISPONIVEL      := 0;
         VNQTDISPONIVEL_CONT := 0;
         IF NVL(REGITENS.QTUNITEMB,0) <> 0 THEN
            VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / REGITENS.QTUNITEMB) * REGITENS.QTUNITEMB;
            VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / REGITENS.QTUNITEMB) * REGITENS.QTUNITEMB;
         END IF;

         BEGIN
            SELECT NVL(PCPRODFILIAL.MULTIPLO, 0),
                   ACEITAVENDAFRACAO,
                   CHECARMULTIPLOVENDABNF
            INTO VNMULTIPLO, VSACEITAVENDAFRACAO, VSCHECARMULTIPLOVENDABNF
            FROM PCPRODFILIAL
            WHERE CODFILIAL = P_REGPEDIDO.CODFILIAL
              AND CODPROD = CR_PCEST.CODPROD;
         EXCEPTION WHEN OTHERS THEN
            VNMULTIPLO               := 0;
            VSACEITAVENDAFRACAO      := NULL;
            VSCHECARMULTIPLOVENDABNF := NULL;
         END;

         BEGIN
            SELECT NVL(MULTIPLO, 0),
                   PCPRODUT.CHECARMULTIPLOVENDABNF,
                   PCPRODUT.ACEITAVENDAFRACAO
            INTO VNMULTIPLO_PROD,
                 VSCHECARMULTIPLOVENDABNF_PROD,
                 VSACEITAVENDAFRACAO_PROD
            FROM PCPRODUT
            WHERE CODPROD = CR_PCEST.CODPROD;
         EXCEPTION WHEN OTHERS THEN
            VNMULTIPLO_PROD               := 0;
            VSACEITAVENDAFRACAO_PROD      := NULL;
            VSCHECARMULTIPLOVENDABNF_PROD := NULL;
         END;

         IF VSACEITAVENDAFRACAO IS NOT NULL THEN
           VSACEITAVENDAFRACAO_PROD := VSACEITAVENDAFRACAO;
         END IF;

         IF VSCHECARMULTIPLOVENDABNF IS NOT NULL THEN
            VSCHECARMULTIPLOVENDABNF_PROD := VSCHECARMULTIPLOVENDABNF;
         END IF;

         IF P_REGCLIENTE.ACEITAVENDAFRACAO = 'S' AND
            P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S' THEN
            IF VNMULTIPLO_PROD = 0 THEN
               IF VSACEITAVENDAFRACAO_PROD = 'M' THEN
                  VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / 0.5) * 0.5;
                  VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / 0.5) * 0.5;
               END IF;
            END IF;
         ELSE
            VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL);
            VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT);
         END IF;

         IF (P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S') AND 
            (((P_REGPEDIDO.CONDVENDA <> 5)) OR
             ((P_REGPEDIDO.CONDVENDA = 5) AND (VSCHECARMULTIPLOVENDABNF_PROD = 'S'))) THEN
            IF NVL(VNMULTIPLO_PROD,0) <> 0 THEN
               VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
               VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
            END IF;
         END IF;

         IF P_REGFILIAL.VERIFICAESTOQUECONT = 'S' THEN
            IF VNQTDISPONIVEL_CONT < REGITENS.QT THEN
               IF VNQTDISPONIVEL < REGITENS.QT THEN
                  SELECT UNIDADE
                  INTO VSUNIDADE
                  FROM PCPRODUT
                  WHERE CODPROD = CR_PCEST.CODPROD;

                  VNCONTPRODCONVESTOQUE := VNCONTPRODCONVESTOQUE + 1;

                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CONDVENDA := P_REGPEDIDO.CONDVENDA;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMPED := P_REGPEDIDO.NUMPED;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODFILIAL := REGITENS.CODFILIALRETIRA;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODPROD := CR_PCEST.CODPROD;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).UNIDADE := VSUNIDADE;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTPEDIDA := REGITENS.QT - NVL(VNQTDISPONIVEL,0);
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTORIGINAL := REGITENS.QT;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTESTGER := CR_PCEST.QTESTGER;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODAUXILIAR := REGITENS.CODAUXILIAR;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQ := REGITENS.NUMSEQ;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQORIGEM := REGITENS.NUMAPLIC;
               ELSE
                  SELECT UNIDADE
                  INTO VSUNIDADE
                  FROM PCPRODUT
                  WHERE CODPROD = CR_PCEST.CODPROD;

                  VNCONTPRODCONVESTOQUE := VNCONTPRODCONVESTOQUE + 1;

                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CONDVENDA := P_REGPEDIDO.CONDVENDA;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMPED := P_REGPEDIDO.NUMPED;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODFILIAL := REGITENS.CODFILIALRETIRA;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODPROD := CR_PCEST.CODPROD;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).UNIDADE := VSUNIDADE;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTPEDIDA := REGITENS.QT - NVL(VNQTDISPONIVEL, 0);
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTORIGINAL := REGITENS.QT;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTESTGER := CR_PCEST.QTESTGER;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODAUXILIAR := REGITENS.CODAUXILIAR;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQ := REGITENS.NUMSEQ;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQORIGEM := REGITENS.NUMAPLIC;
               END IF;
            ELSE
               IF VNQTDISPONIVEL < REGITENS.QT THEN
                  SELECT UNIDADE
                  INTO VSUNIDADE
                  FROM PCPRODUT
                  WHERE CODPROD = CR_PCEST.CODPROD;

                  VNCONTPRODCONVESTOQUE := VNCONTPRODCONVESTOQUE + 1;

                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CONDVENDA := P_REGPEDIDO.CONDVENDA;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMPED := P_REGPEDIDO.NUMPED;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODFILIAL := REGITENS.CODFILIALRETIRA;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODPROD := CR_PCEST.CODPROD;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).UNIDADE := VSUNIDADE;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTPEDIDA := REGITENS.QT - NVL(VNQTDISPONIVEL,0);
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTORIGINAL := REGITENS.QT;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTESTGER := CR_PCEST.QTESTGER;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODAUXILIAR := REGITENS.CODAUXILIAR;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQ := REGITENS.NUMSEQ;
                  GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQORIGEM := REGITENS.NUMAPLIC;
               END IF;
            END IF;
         ELSE
            IF VNQTDISPONIVEL < REGITENS.QT THEN
               SELECT UNIDADE
               INTO VSUNIDADE
               FROM PCPRODUT
               WHERE CODPROD = CR_PCEST.CODPROD;

               VNCONTPRODCONVESTOQUE := VNCONTPRODCONVESTOQUE + 1;

               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CONDVENDA := P_REGPEDIDO.CONDVENDA;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMPED := P_REGPEDIDO.NUMPED;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODFILIAL := REGITENS.CODFILIALRETIRA;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODPROD := CR_PCEST.CODPROD;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).UNIDADE := VSUNIDADE;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTPEDIDA := REGITENS.QT - NVL(VNQTDISPONIVEL,0);
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTORIGINAL := REGITENS.QT;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).QTESTGER := CR_PCEST.QTESTGER;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).CODAUXILIAR := REGITENS.CODAUXILIAR;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQ := REGITENS.NUMSEQ;
               GVET_REGPRODCONVESTOQUE(VNCONTPRODCONVESTOQUE).NUMSEQORIGEM := REGITENS.NUMAPLIC;
            END IF;
         END IF;
      END LOOP;
   END LOOP;
   
   --verificar estoque após conversão
   FOR I IN 1 .. VNCONTPRODCONVESTOQUE 
   LOOP
      PROC_CONVERTE_ESTOQUE(GVET_REGPRODCONVESTOQUE(I).CONDVENDA,
                            GVET_REGPRODCONVESTOQUE(I).NUMPED,
                            GVET_REGPRODCONVESTOQUE(I).CODFILIAL,
                            GVET_REGPRODCONVESTOQUE(I).CODPROD,
                            GVET_REGPRODCONVESTOQUE(I).UNIDADE,
                            GVET_REGPRODCONVESTOQUE(I).QTPEDIDA,
                            GVET_REGPRODCONVESTOQUE(I).QTESTGER,
                            VNQTATENDCONV,
                            VSMENSAGEM_CONVESTOQUE,
                            P_REGPEDIDO.CODRETORNOS);

      SELECT QTESTGER, QTRESERV, QTBLOQUEADA, QTPENDENTE
      INTO VNQTESTGER, VNQTRESERV, VNQTBLOQUEADA, VNQTPENDENTE
      FROM PCEST
      WHERE PCEST.CODFILIAL = GVET_REGPRODCONVESTOQUE(I).CODFILIAL
        AND PCEST.CODPROD = GVET_REGPRODCONVESTOQUE(I).CODPROD;

      IF P_REGFILIAL.CALCESTDISPCOMQTMINAUTOSERV = 'S' THEN
         BEGIN
            SELECT NVL(PCPRODFILIAL.QTMINAUTOSERV, 0)
            INTO VNQTMINAUTOSERVICO
            FROM PCPRODFILIAL
            WHERE CODFILIAL = GVET_REGPRODCONVESTOQUE(I).CODFILIAL
              AND CODPROD = GVET_REGPRODCONVESTOQUE(I).CODPROD;
         EXCEPTION  WHEN OTHERS THEN
            VNQTMINAUTOSERVICO := 0;
         END;

         VNQTDISPONIVEL := GREATEST(NVL(VNQTESTGER, 0), 0) - GREATEST(NVL(VNQTRESERV, 0), 0) -
                            GREATEST(NVL(VNQTBLOQUEADA, 0), 0) - GREATEST(NVL(VNQTMINAUTOSERVICO, 0), 0);
      ELSE
         VNQTDISPONIVEL := GREATEST(NVL(VNQTESTGER, 0), 0) - GREATEST(NVL(VNQTRESERV, 0), 0) - GREATEST(NVL(VNQTBLOQUEADA, 0), 0);
      END IF;

      IF GREGPCCONSUM.BLOQUEIAVENDAESTPENDENTE = 'S' THEN
         VNQTDISPONIVEL := VNQTDISPONIVEL - (GREATEST(NVL(VNQTPENDENTE, 0), 0));
         VNQTDISPONIVEL_CONT := VNQTDISPONIVEL_CONT - (GREATEST(NVL(VNQTPENDENTE, 0), 0));
      END IF;

      IF VNQTDISPONIVEL < 0 THEN
         VNQTDISPONIVEL := 0;
      END IF;

      BEGIN
         SELECT NVL(PCPRODFILIAL.MULTIPLO, 0),
                ACEITAVENDAFRACAO,
                CHECARMULTIPLOVENDABNF
         INTO VNMULTIPLO, VSACEITAVENDAFRACAO, VSCHECARMULTIPLOVENDABNF
         FROM PCPRODFILIAL
         WHERE CODFILIAL = P_REGPEDIDO.CODFILIAL
           AND CODPROD = GVET_REGPRODCONVESTOQUE(I).CODPROD;
      EXCEPTION WHEN OTHERS THEN
         VNMULTIPLO               := 0;
         VSACEITAVENDAFRACAO      := NULL;
         VSCHECARMULTIPLOVENDABNF := NULL;
      END;

      BEGIN
         SELECT NVL(MULTIPLO, 0),
                PCPRODUT.CHECARMULTIPLOVENDABNF,
                PCPRODUT.ACEITAVENDAFRACAO
         INTO VNMULTIPLO_PROD,
              VSCHECARMULTIPLOVENDABNF_PROD,
              VSACEITAVENDAFRACAO_PROD
         FROM PCPRODUT
         WHERE CODPROD = GVET_REGPRODCONVESTOQUE(I).CODPROD;
      EXCEPTION WHEN OTHERS THEN
         VNMULTIPLO_PROD               := 0;
         VSACEITAVENDAFRACAO_PROD      := NULL;
         VSCHECARMULTIPLOVENDABNF_PROD := NULL;
      END;

      IF VSACEITAVENDAFRACAO IS NOT NULL THEN
         VSACEITAVENDAFRACAO_PROD := VSACEITAVENDAFRACAO;
      END IF;

      IF VSCHECARMULTIPLOVENDABNF IS NOT NULL THEN
         VSCHECARMULTIPLOVENDABNF_PROD := VSCHECARMULTIPLOVENDABNF;
      END IF;

      IF P_REGCLIENTE.ACEITAVENDAFRACAO = 'S' AND
         P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S' THEN
         IF VNMULTIPLO_PROD = 0 THEN
            IF VSACEITAVENDAFRACAO_PROD = 'M' THEN
               VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / 0.5) * 0.5;
               VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / 0.5) * 0.5;
            END IF;
         END IF;
      ELSE
         VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL);
         VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT);
      END IF;

      IF (P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S') AND
         (((P_REGPEDIDO.CONDVENDA <> 5)) OR
          ((P_REGPEDIDO.CONDVENDA = 5) AND (VSCHECARMULTIPLOVENDABNF_PROD = 'S'))) THEN
         IF NVL(VNMULTIPLO_PROD,0) <> 0 THEN
            VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
            VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
         END IF;
      END IF;

      IF VNQTDISPONIVEL < GVET_REGPRODCONVESTOQUE(I).QTORIGINAL THEN
         IF (NVL(P_REGFILIAL.ACEITAVENDASEMESTINT, NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'N') OR
            (NVL(P_REGFILIAL.ACEITAVENDASEMESTINT, NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'S' AND
             GREGPCCONSUM.LIBERARPEDIDOPENDENTE = 'S') THEN
            IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
               UPDATE PCPEDI
               SET QTFALTA = GVET_REGPRODCONVESTOQUE(I).QTORIGINAL - VNQTDISPONIVEL
               WHERE NUMPED = P_REGPEDIDO.NUMPED
                 AND CODPROD = GVET_REGPRODCONVESTOQUE(I).CODPROD
                 AND NUMSEQ = GVET_REGPRODCONVESTOQUE(I).NUMSEQ
                 AND (CODAUXILIAR = GVET_REGPRODCONVESTOQUE(I).CODAUXILIAR OR CODAUXILIAR IS NULL)
                 AND CODFILIALRETIRA = GVET_REGPRODCONVESTOQUE(I).CODFILIAL;
            END IF;
         END IF;
      END IF;

      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       GVET_REGPRODCONVESTOQUE(I).CODPROD,
                       GVET_REGPRODCONVESTOQUE(I).CODAUXILIAR,
                       GVET_REGPRODCONVESTOQUE(I).NUMSEQORIGEM,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       P_REGPEDIDO.CODRETORNOS,
                       '3',
                       VSMENSAGEM_CONVESTOQUE || ';',
                       NULL);
   END LOOP;
EXCEPTION WHEN OTHERS THEN
   PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                    P_REGPEDIDO.NUMPEDINT,
                    NULL,
                    NULL,
                    NULL,
                    P_REGPEDIDO.CODCLI,
                    P_REGPEDIDO.CODUSUR,
                    NULL,
                    NULL,
                    P_REGPEDIDO.INTEGRADORA,
                    151,
                    '2',
                    'Erro13:' || SQLCODE || '-' || SQLERRM || ';',
                    NULL);
END PROC_VERIFICAESTOQUE;


PROCEDURE PROC_GRAVAESTOQUE(P_REGPEDIDO  IN OUT T_CABPED,
                            P_REGFILIAL  IN T_FILIAL,
                            P_REGRCA     IN T_RCA,
                            P_REGPLPAG   IN T_PLANODEPAGAMENTO,
                            P_REGCLIENTE IN T_CLIENTEPEDIDO,
                            P_NUMSEQ     IN NUMBER,
                            P_VLTOTPED   IN NUMBER) 
IS
   CURSOR CR_ESTOQUE(P_NUMPED PCPEDC.NUMPED%TYPE) IS
      SELECT *
      FROM PCEST
      WHERE EXISTS (SELECT PCPEDI.CODPROD
                    FROM PCPEDI
                    WHERE PCPEDI.NUMPED = P_NUMPED
                      AND PCPEDI.CODPROD = PCEST.CODPROD
                      AND PCEST.CODFILIAL = PCPEDI.CODFILIALRETIRA
                      AND PCPEDI.NUMSEQ > P_NUMSEQ);

   VNQTDISPONIVEL      NUMBER;
   VNQTATEND           NUMBER;
   VNQTFALTA           NUMBER;
   VNVLTABELA          NUMBER;
   VNVLATEND           NUMBER;
   VNVLTOTAL           NUMBER;
   VNVLCUSTOFIN        NUMBER;
   VNVLCUSTOREAL       NUMBER;
   VNVLCUSTOREP        NUMBER;
   VNVLCUSTOCONT       NUMBER;
   VNTOTPESO           NUMBER;
   VNTOTVOLUME         NUMBER;
   VNNUMITENS          NUMBER;
   VNSOMAFALTA         NUMBER;
   VBFAZRESERVAESTOQUE BOOLEAN;
   VNQTDISPONIVEL_CONT NUMBER;
   VNNUMSEQ            NUMBER;
   VNQTMINAUTOSERVICO  NUMBER;
   VNQTTOTPROD         NUMBER;
   VICONTADOR          NUMBER;
   VBFAZRESERVAESTOQUE_AUX       BOOLEAN;
   VNMULTIPLO                    PCPRODUT.MULTIPLO%TYPE;
   VNMULTIPLO_PROD               PCPRODUT.MULTIPLO%TYPE;
   VSCHECARMULTIPLOVENDABNF      PCPRODFILIAL.CHECARMULTIPLOVENDABNF%TYPE;
   VSCHECARMULTIPLOVENDABNF_PROD PCPRODUT.CHECARMULTIPLOVENDABNF%TYPE;
   VSACEITAVENDAFRACAO_PROD      PCPRODUT.ACEITAVENDAFRACAO%TYPE;
   VSACEITAVENDAFRACAO           PCPRODFILIAL.ACEITAVENDAFRACAO%TYPE;
   vListaProduto VARCHAR2(1000);
BEGIN
   VBFAZRESERVAESTOQUE := TRUE;

   IF NVL(P_REGFILIAL.ACEITAVENDASEMESTINT, NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'S' AND
      GREGPCCONSUM.LIBERARPEDIDOPENDENTE = 'N' THEN
      VBFAZRESERVAESTOQUE_AUX := FALSE;
   ELSE
      VBFAZRESERVAESTOQUE_AUX := TRUE;
   END IF;

   VNNUMSEQ := 0;

   FOR CR_PCEST IN CR_ESTOQUE(P_REGPEDIDO.NUMPED) LOOP
      FOR REG_ITENS IN (SELECT PCPEDI.QT,
                               PCPEDI.CODFILIALRETIRA,
                               NUMSEQ,
                               NUMAPLIC NUMSEQORIG,
                               CODAUXILIAR,
                               NVL(PCPEDI.QTUNITEMB, 1) QTUNITEMB
                          FROM PCPEDI
                         WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                           AND PCPEDI.CODPROD = CR_PCEST.CODPROD
                           AND PCPEDI.NUMSEQ > P_NUMSEQ
                           AND PCPEDI.CODFILIALRETIRA = CR_PCEST.CODFILIAL) 
      LOOP
         UPDATE PCEST
         SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) + REG_ITENS.QT,
             PCEST.DTULTSAIDA = TRUNC(SYSDATE)
         WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIALRETIRA
           AND PCEST.CODPROD = CR_PCEST.CODPROD;
         --verificar se tem no mesmo pedidos outros itens com mesmo codprod
         VNQTTOTPROD := 0;

         SELECT SUM(QT)
         INTO VNQTTOTPROD
         FROM PCPEDI
         WHERE NUMPED = P_REGPEDIDO.NUMPED
           AND CODPROD = CR_PCEST.CODPROD
           AND NUMSEQ < REG_ITENS.NUMSEQ
           AND CODFILIALRETIRA = REG_ITENS.CODFILIALRETIRA;

         IF P_REGFILIAL.CALCESTDISPCOMQTMINAUTOSERV = 'S' THEN
            BEGIN
               SELECT NVL(PCPRODFILIAL.QTMINAUTOSERV, 0)
               INTO VNQTMINAUTOSERVICO
               FROM PCPRODFILIAL
               WHERE CODFILIAL = REG_ITENS.CODFILIALRETIRA
                 AND CODPROD = CR_PCEST.CODPROD;
            EXCEPTION WHEN OTHERS THEN
               VNQTMINAUTOSERVICO := 0;
            END;

            VNQTDISPONIVEL := GREATEST(NVL(CR_PCEST.QTESTGER, 0), 0) - GREATEST(NVL(CR_PCEST.QTRESERV, 0), 0) -
                              GREATEST(NVL(CR_PCEST.QTBLOQUEADA, 0), 0) - GREATEST(NVL(VNQTMINAUTOSERVICO, 0), 0) - NVL(VNQTTOTPROD, 0);
         ELSE
            VNQTDISPONIVEL := GREATEST(NVL(CR_PCEST.QTESTGER, 0), 0) - GREATEST(NVL(CR_PCEST.QTRESERV, 0), 0) -
                              GREATEST(NVL(CR_PCEST.QTBLOQUEADA, 0), 0) - NVL(VNQTTOTPROD, 0);
         END IF;

         VNQTDISPONIVEL_CONT := GREATEST(CR_PCEST.QTEST, 0) - GREATEST(CR_PCEST.QTRESERV, 0) - NVL(VNQTTOTPROD, 0);

         IF GREGPCCONSUM.BLOQUEIAVENDAESTPENDENTE = 'S' THEN
            VNQTDISPONIVEL := VNQTDISPONIVEL - (GREATEST(NVL(CR_PCEST.QTPENDENTE, 0), 0));
            VNQTDISPONIVEL_CONT := VNQTDISPONIVEL_CONT - (GREATEST(NVL(CR_PCEST.QTPENDENTE, 0), 0));
         END IF;

         IF VNQTDISPONIVEL_CONT < 0 THEN
            VNQTDISPONIVEL_CONT := 0;
         END IF;

         IF VNQTDISPONIVEL < 0 THEN
            VNQTDISPONIVEL := 0;
         END IF;

         IF NVL(REG_ITENS.QTUNITEMB,0) <> 0 THEN
            VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / REG_ITENS.QTUNITEMB) * REG_ITENS.QTUNITEMB;
            VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / REG_ITENS.QTUNITEMB) * REG_ITENS.QTUNITEMB;
         END IF;

         BEGIN
            SELECT NVL(PCPRODFILIAL.MULTIPLO, 0),
                   ACEITAVENDAFRACAO,
                   CHECARMULTIPLOVENDABNF
            INTO VNMULTIPLO, VSACEITAVENDAFRACAO, VSCHECARMULTIPLOVENDABNF
            FROM PCPRODFILIAL
            WHERE CODFILIAL = P_REGPEDIDO.CODFILIAL
              AND CODPROD = CR_PCEST.CODPROD;
         EXCEPTION WHEN OTHERS THEN
            VNMULTIPLO               := 0;
            VSACEITAVENDAFRACAO      := NULL;
            VSCHECARMULTIPLOVENDABNF := NULL;
         END;

         BEGIN
            SELECT NVL(MULTIPLO, 0),
                   PCPRODUT.CHECARMULTIPLOVENDABNF,
                   PCPRODUT.ACEITAVENDAFRACAO
            INTO VNMULTIPLO_PROD,
                 VSCHECARMULTIPLOVENDABNF_PROD,
                 VSACEITAVENDAFRACAO_PROD
            FROM PCPRODUT
            WHERE CODPROD = CR_PCEST.CODPROD;
         EXCEPTION WHEN OTHERS THEN
            VNMULTIPLO_PROD               := 0;
            VSACEITAVENDAFRACAO_PROD      := NULL;
            VSCHECARMULTIPLOVENDABNF_PROD := NULL;
         END;

         IF VSACEITAVENDAFRACAO IS NOT NULL THEN
           VSACEITAVENDAFRACAO_PROD := VSACEITAVENDAFRACAO;
         END IF;

         IF VSCHECARMULTIPLOVENDABNF IS NOT NULL THEN
           VSCHECARMULTIPLOVENDABNF_PROD := VSCHECARMULTIPLOVENDABNF;
         END IF;

         IF P_REGCLIENTE.ACEITAVENDAFRACAO = 'S' AND
            P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S' THEN

            IF VNMULTIPLO_PROD = 0 THEN
               IF VSACEITAVENDAFRACAO_PROD = 'M' THEN
                  VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / 0.5) * 0.5;
                  VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / 0.5) * 0.5;
               END IF;
            END IF;
         ELSE
            VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL);
            VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT);
         END IF;

         IF (P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S') AND
            (((P_REGPEDIDO.CONDVENDA <> 5)) OR ((P_REGPEDIDO.CONDVENDA = 5) AND
             (VSCHECARMULTIPLOVENDABNF_PROD = 'S'))) THEN
            IF NVL(VNMULTIPLO_PROD,0) <> 0 THEN
               VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
               VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
            END IF;
         END IF;

         IF VBFAZRESERVAESTOQUE_AUX = TRUE THEN
            IF P_REGFILIAL.VERIFICAESTOQUECONT = 'S' THEN
               IF VNQTDISPONIVEL_CONT < REG_ITENS.QT THEN
                  IF VNQTDISPONIVEL < REG_ITENS.QT THEN
                     IF NVL(P_REGFILIAL.ACEITAVENDASEMESTINT, NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'S' AND
                        P_REGPEDIDO.POSICAO IN ('B', 'P') THEN
                        VBFAZRESERVAESTOQUE := FALSE;

                        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                   P_REGPEDIDO.NUMPEDINT,
                                   CR_PCEST.CODPROD,
                                   REG_ITENS.CODAUXILIAR,
                                   REG_ITENS.NUMSEQORIG,
                                   P_REGPEDIDO.CODCLI,
                                   P_REGPEDIDO.CODUSUR,
                                   NULL,
                                   NULL,
                                   P_REGPEDIDO.INTEGRADORA,
                                   79,
                                   '2',
                                   'Produto sem estoque no momento da importação! ' ||
                                   CHR(13) || 'Qt Disponivel: ' ||
                                   VNQTDISPONIVEL || CHR(13) ||
                                   'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                   'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                   NULL);
                     ELSE
                        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                           VBFAZRESERVAESTOQUE := FALSE;

                           P_REGPEDIDO.POSICAO := 'B';

                           PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                     P_REGPEDIDO.NUMPEDINT,
                                     CR_PCEST.CODPROD,
                                     REG_ITENS.CODAUXILIAR,
                                     REG_ITENS.NUMSEQORIG,
                                     P_REGPEDIDO.CODCLI,
                                     P_REGPEDIDO.CODUSUR,
                                     NULL,
                                     NULL,
                                     P_REGPEDIDO.INTEGRADORA,
                                     78,
                                     '2',
                                     'Produto sem estoque no momento da Importacao. Bloqueado de acordo com parâmetro TIPOIMPORTACAOVENDA ' ||
                                     CHR(13) || 'Qt Disponivel: ' ||
                                     VNQTDISPONIVEL || CHR(13) ||
                                     'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                     'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                     NULL);
                        END IF;
                     END IF;
                  ELSE
                     IF NVL(P_REGFILIAL.ACEITAVENDASEMESTINT, NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'S' AND
                        P_REGPEDIDO.POSICAO IN ('B', 'P') THEN
                        VBFAZRESERVAESTOQUE := FALSE;

                        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                   P_REGPEDIDO.NUMPEDINT,
                                   CR_PCEST.CODPROD,
                                   REG_ITENS.CODAUXILIAR,
                                   REG_ITENS.NUMSEQORIG,
                                   P_REGPEDIDO.CODCLI,
                                   P_REGPEDIDO.CODUSUR,
                                   NULL,
                                   NULL,
                                   P_REGPEDIDO.INTEGRADORA,
                                   79,
                                   '2',
                                   'Produto sem estoque contabil no momento da importação! ' ||
                                   CHR(13) || 'Qt Disponivel: ' ||
                                   VNQTDISPONIVEL || CHR(13) ||
                                   'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                   'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                   NULL);
                     ELSE
                        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                           VBFAZRESERVAESTOQUE := FALSE;
                           P_REGPEDIDO.POSICAO := 'B';

                           PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                     P_REGPEDIDO.NUMPEDINT,
                                     CR_PCEST.CODPROD,
                                     REG_ITENS.CODAUXILIAR,
                                     REG_ITENS.NUMSEQORIG,
                                     P_REGPEDIDO.CODCLI,
                                     P_REGPEDIDO.CODUSUR,
                                     NULL,
                                     NULL,
                                     P_REGPEDIDO.INTEGRADORA,
                                     78,
                                     '2',
                                     'Produto sem estoque contabil no momento da Importacao. Bloqueado de acordo com parâmetro TIPOIMPORTACAOVENDA' ||
                                     CHR(13) || 'Qt Disponivel: ' ||
                                     VNQTDISPONIVEL || CHR(13) ||
                                     'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                     'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                     NULL);
                        END IF;
                     END IF;
                  END IF;
               ELSE
                  IF VNQTDISPONIVEL < REG_ITENS.QT THEN
                     IF NVL(P_REGFILIAL.ACEITAVENDASEMESTINT,NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'S' AND
                        P_REGPEDIDO.POSICAO IN ('B', 'P') THEN
                        VBFAZRESERVAESTOQUE := FALSE;

                        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                   P_REGPEDIDO.NUMPEDINT,
                                   CR_PCEST.CODPROD,
                                   REG_ITENS.CODAUXILIAR,
                                   REG_ITENS.NUMSEQORIG,
                                   P_REGPEDIDO.CODCLI,
                                   P_REGPEDIDO.CODUSUR,
                                   NULL,
                                   NULL,
                                   P_REGPEDIDO.INTEGRADORA,
                                   79,
                                   '2',
                                   'Produto sem estoque no momento da importação!' ||
                                   CHR(13) || 'Qt Disponivel : ' ||
                                   VNQTDISPONIVEL || CHR(13) ||
                                   'Qt Pedida : ' || REG_ITENS.QT || CHR(13) ||
                                   'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                   NULL);
                     ELSE
                        IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                           VBFAZRESERVAESTOQUE := FALSE;
                           P_REGPEDIDO.POSICAO := 'B';

                           PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                     P_REGPEDIDO.NUMPEDINT,
                                     CR_PCEST.CODPROD,
                                     REG_ITENS.CODAUXILIAR,
                                     REG_ITENS.NUMSEQORIG,
                                     P_REGPEDIDO.CODCLI,
                                     P_REGPEDIDO.CODUSUR,
                                     NULL,
                                     NULL,
                                     P_REGPEDIDO.INTEGRADORA,
                                     80,
                                     '2',
                                     'Produto sem estoque no momento da importacao. Bloqueado de acordo com parâmetro TIPOIMPORTACAOVENDA' ||
                                     CHR(13) || 'Qt Disponivel: ' ||
                                     VNQTDISPONIVEL || CHR(13) ||
                                     'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                     'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                     NULL);
                        END IF;
                     END IF;
                  END IF;
               END IF;
            ELSE
               IF VNQTDISPONIVEL < REG_ITENS.QT THEN
                  IF NVL(P_REGFILIAL.ACEITAVENDASEMESTINT, NVL(GREGPCCONSUM.ACEITAVENDASEMEST, 'N')) = 'S' AND
                     P_REGPEDIDO.POSICAO IN ('B', 'P') THEN
                     VBFAZRESERVAESTOQUE := FALSE;

                     PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                 P_REGPEDIDO.NUMPEDINT,
                                 CR_PCEST.CODPROD,
                                 REG_ITENS.CODAUXILIAR,
                                 REG_ITENS.NUMSEQORIG,
                                 P_REGPEDIDO.CODCLI,
                                 P_REGPEDIDO.CODUSUR,
                                 NULL,
                                 NULL,
                                 P_REGPEDIDO.INTEGRADORA,
                                 79,
                                 '2',
                                 'Produto sem estoque no momento da importação!' ||
                                 CHR(13) || 'Qt Disponivel: ' ||
                                 VNQTDISPONIVEL || CHR(13) ||
                                 'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                 'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                 NULL);
                  ELSE
                     IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                        VBFAZRESERVAESTOQUE := FALSE;
                        P_REGPEDIDO.POSICAO := 'B';

                        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                   P_REGPEDIDO.NUMPEDINT,
                                   CR_PCEST.CODPROD,
                                   REG_ITENS.CODAUXILIAR,
                                   REG_ITENS.NUMSEQORIG,
                                   P_REGPEDIDO.CODCLI,
                                   P_REGPEDIDO.CODUSUR,
                                   NULL,
                                   NULL,
                                   P_REGPEDIDO.INTEGRADORA,
                                   80,
                                   '2',
                                   'Produto sem estoque no momento da Importacao. Bloqueado de acordo com parâmetro TIPOIMPORTACAOVENDA' ||
                                   CHR(13) || 'Qt Disponivel: ' ||
                                   VNQTDISPONIVEL || CHR(13) ||
                                   'Qt Pedida: ' || REG_ITENS.QT || CHR(13) ||
                                   'Produto: ' || CR_PCEST.CODPROD || CHR(13),
                                   NULL);
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;
      END LOOP;
   END LOOP;

   IF (VBFAZRESERVAESTOQUE = FALSE) OR (VBFAZRESERVAESTOQUE_AUX = FALSE) THEN
      -- posicao dos itens deve estar de acordo com a do cabecalho.
      UPDATE PCPEDI
      SET PCPEDI.POSICAO = P_REGPEDIDO.POSICAO, QTFALTA = NULL
      WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED;

      UPDATE PCPEDC
      SET PCPEDC.POSICAO = P_REGPEDIDO.POSICAO
      WHERE PCPEDC.NUMPED = P_REGPEDIDO.NUMPED;

      IF P_REGPEDIDO.POSICAO = 'P' AND VBFAZRESERVAESTOQUE_AUX = FALSE THEN
         PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                          P_REGPEDIDO.NUMPEDINT,
                          NULL,
                          NULL,
                          NULL,
                          P_REGPEDIDO.CODCLI,
                          P_REGPEDIDO.CODUSUR,
                          NULL,
                          NULL,
                          P_REGPEDIDO.INTEGRADORA,
                          147,
                          '2',
                          'Pedido Pendente devido a parametro 1303 ou 3030;',
                          NULL);
      END IF;
   ELSE
      FOR CR_PCEST IN CR_ESTOQUE(P_REGPEDIDO.NUMPED) LOOP
         FOR REG_ITENS IN (SELECT PCPEDI.QT,
                                  PCPEDI.PVENDA,
                                  PCPEDI.CODFILIALRETIRA,
                                  NUMSEQ,
                                  NUMAPLIC NUMSEQORIG,
                                  CODAUXILIAR,
                                  NVL(PCPEDI.QTUNITEMB, 1) QTUNITEMB
                            FROM PCPEDI
                            WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                              AND PCPEDI.CODPROD = CR_PCEST.CODPROD
                              AND PCPEDI.NUMSEQ > P_NUMSEQ
                              AND PCPEDI.CODFILIALRETIRA = CR_PCEST.CODFILIAL) 
         LOOP
            --verificar se tem no mesmo pedidos outros itens com mesmo codprod
            VNQTTOTPROD := 0;

            SELECT SUM(QT)
            INTO VNQTTOTPROD
            FROM PCPEDI
            WHERE NUMPED = P_REGPEDIDO.NUMPED
              AND CODPROD = CR_PCEST.CODPROD
              AND NUMSEQ < REG_ITENS.NUMSEQ
              AND CODFILIALRETIRA = REG_ITENS.CODFILIALRETIRA;

            IF P_REGFILIAL.CALCESTDISPCOMQTMINAUTOSERV = 'S' THEN
            BEGIN
              SELECT NVL(PCPRODFILIAL.QTMINAUTOSERV, 0)
                INTO VNQTMINAUTOSERVICO
                FROM PCPRODFILIAL
               WHERE CODFILIAL = REG_ITENS.CODFILIALRETIRA
                 AND CODPROD = CR_PCEST.CODPROD;
            EXCEPTION
              WHEN OTHERS THEN
                VNQTMINAUTOSERVICO := 0;
            END;

              VNQTDISPONIVEL := GREATEST(NVL(CR_PCEST.QTESTGER, 0), 0) - GREATEST(NVL(CR_PCEST.QTRESERV, 0), 0) -
                                GREATEST(NVL(CR_PCEST.QTBLOQUEADA, 0), 0) - GREATEST(NVL(VNQTMINAUTOSERVICO, 0), 0) - NVL(VNQTTOTPROD, 0);
            ELSE
              VNQTDISPONIVEL := GREATEST(NVL(CR_PCEST.QTESTGER, 0), 0) - GREATEST(NVL(CR_PCEST.QTRESERV, 0), 0) -
                              GREATEST(NVL(CR_PCEST.QTBLOQUEADA, 0), 0) - NVL(VNQTTOTPROD, 0);
            END IF;

            IF VNQTDISPONIVEL < 0 THEN
               VNQTDISPONIVEL := 0;
            END IF;

            VNQTDISPONIVEL_CONT := GREATEST(CR_PCEST.QTEST, 0) - GREATEST(CR_PCEST.QTRESERV, 0) - NVL(VNQTTOTPROD, 0);

            IF GREGPCCONSUM.BLOQUEIAVENDAESTPENDENTE = 'S' THEN
               VNQTDISPONIVEL := VNQTDISPONIVEL - (GREATEST(NVL(CR_PCEST.QTPENDENTE, 0), 0) - REG_ITENS.QT);
               VNQTDISPONIVEL_CONT := VNQTDISPONIVEL_CONT - (GREATEST(NVL(CR_PCEST.QTPENDENTE, 0), 0) - REG_ITENS.QT);
            END IF;

            IF VNQTDISPONIVEL_CONT <= 0 THEN
               VNQTDISPONIVEL_CONT := 0;
            END IF;

            IF NVL(REG_ITENS.QTUNITEMB,0) <> 0 THEN
               VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / REG_ITENS.QTUNITEMB) * REG_ITENS.QTUNITEMB;
               VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / REG_ITENS.QTUNITEMB) * REG_ITENS.QTUNITEMB;
            END IF;

            BEGIN
               SELECT NVL(PCPRODFILIAL.MULTIPLO, 0),
                      ACEITAVENDAFRACAO,
                      CHECARMULTIPLOVENDABNF
               INTO VNMULTIPLO,
                    VSACEITAVENDAFRACAO,
                    VSCHECARMULTIPLOVENDABNF
               FROM PCPRODFILIAL
               WHERE CODFILIAL = P_REGPEDIDO.CODFILIAL
                 AND CODPROD = CR_PCEST.CODPROD;
            EXCEPTION WHEN OTHERS THEN
              VNMULTIPLO               := 0;
              VSACEITAVENDAFRACAO      := NULL;
              VSCHECARMULTIPLOVENDABNF := NULL;
            END;

            BEGIN
               SELECT NVL(MULTIPLO, 0),
                      PCPRODUT.CHECARMULTIPLOVENDABNF,
                      PCPRODUT.ACEITAVENDAFRACAO
               INTO VNMULTIPLO_PROD,
                    VSCHECARMULTIPLOVENDABNF_PROD,
                    VSACEITAVENDAFRACAO_PROD
               FROM PCPRODUT
               WHERE CODPROD = CR_PCEST.CODPROD;
            EXCEPTION WHEN OTHERS THEN
               VNMULTIPLO_PROD               := 0;
               VSACEITAVENDAFRACAO_PROD      := NULL;
               VSCHECARMULTIPLOVENDABNF_PROD := NULL;
            END;

            IF VSACEITAVENDAFRACAO IS NOT NULL THEN
               VSACEITAVENDAFRACAO_PROD := VSACEITAVENDAFRACAO;
            END IF;

            IF VSCHECARMULTIPLOVENDABNF IS NOT NULL THEN
               VSCHECARMULTIPLOVENDABNF_PROD := VSCHECARMULTIPLOVENDABNF;
            END IF;

            IF P_REGCLIENTE.ACEITAVENDAFRACAO = 'S' AND
               P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S' THEN

               IF VNMULTIPLO_PROD = 0 THEN
                  IF VSACEITAVENDAFRACAO_PROD = 'M' THEN
                     VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / 0.5) * 0.5;
                     VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / 0.5) * 0.5;
                  END IF;
               END IF;
            ELSE
               VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL);
               VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT);
            END IF;

            IF (P_REGCLIENTE.VALIDARMULTIPLOVENDA = 'S') AND
               (((P_REGPEDIDO.CONDVENDA <> 5)) OR ((P_REGPEDIDO.CONDVENDA = 5) AND
                (VSCHECARMULTIPLOVENDABNF_PROD = 'S'))) THEN
               IF NVL(VNMULTIPLO_PROD,0) <> 0 THEN
                  VNQTDISPONIVEL      := TRUNC(VNQTDISPONIVEL / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
                  VNQTDISPONIVEL_CONT := TRUNC(VNQTDISPONIVEL_CONT / VNMULTIPLO_PROD) * VNMULTIPLO_PROD;
               END IF;
            END IF;

            IF VNQTDISPONIVEL < 0 THEN
               VNQTDISPONIVEL := 0;
            END IF;

            IF VNQTDISPONIVEL_CONT < 0 THEN
               VNQTDISPONIVEL_CONT := 0;
            END IF;

            VNQTFALTA := 0;
            VNQTATEND := REG_ITENS.QT;

            IF P_REGFILIAL.VERIFICAESTOQUECONT = 'S' THEN
               IF VNQTDISPONIVEL_CONT < REG_ITENS.QT THEN
                  IF VNQTDISPONIVEL < VNQTDISPONIVEL_CONT THEN
                     VNQTATEND := VNQTDISPONIVEL;
                  ELSE
                     VNQTDISPONIVEL := VNQTDISPONIVEL_CONT;
                     VNQTATEND := VNQTDISPONIVEL_CONT;
                  END IF;
               ELSE
                  IF VNQTDISPONIVEL < REG_ITENS.QT THEN
                     VNQTATEND := VNQTDISPONIVEL;
                  END IF;
               END IF;
            ELSE
               IF VNQTDISPONIVEL < REG_ITENS.QT THEN
                  VNQTATEND := VNQTDISPONIVEL;
               END IF;
            END IF;

            IF VNQTDISPONIVEL < REG_ITENS.QT THEN
               IF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
                  VNQTATEND := VNQTDISPONIVEL;
                  VNQTFALTA := REG_ITENS.QT - VNQTDISPONIVEL;
               ELSIF P_REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
                  VNQTATEND          := 0;
                  VNQTFALTA          := 0;
                  P_REGPEDIDO.VALIDO := FALSE;

                  PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                   P_REGPEDIDO.NUMPEDINT,
                                   NULL,
                                   NULL,
                                   NULL,
                                   P_REGPEDIDO.CODCLI,
                                   P_REGPEDIDO.CODUSUR,
                                   NULL,
                                   NULL,
                                   P_REGPEDIDO.INTEGRADORA,
                                   50,
                                   '2',
                                   'Existe no pedido produto sem estoque suficiente: '||CR_PCEST.CODPROD||';',
                                   NULL);
               END IF;
            END IF;

            IF VNQTATEND > 0 THEN
               UPDATE PCEST
               SET PCEST.QTRESERV   = NVL(PCEST.QTRESERV, 0) + VNQTATEND,
                   PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - REG_ITENS.QT,
                   PCEST.DTULTSAIDA = TRUNC(SYSDATE)
               WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIALRETIRA
                 AND PCEST.CODPROD = CR_PCEST.CODPROD;

               UPDATE PCPEDI
               SET PCPEDI.QT      = VNQTATEND,
                   PCPEDI.QTFALTA = VNQTFALTA,
                   POSICAO        = 'L'
               WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                 AND PCPEDI.CODPROD = CR_PCEST.CODPROD
                 AND PCPEDI.NUMSEQ = REG_ITENS.NUMSEQ
                 AND (CODAUXILIAR = REG_ITENS.CODAUXILIAR 
                  OR  CODAUXILIAR IS NULL);
            ELSE
               DELETE FROM PCPEDI
               WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
                 AND PCPEDI.CODPROD = CR_PCEST.CODPROD
                 AND PCPEDI.NUMSEQ = REG_ITENS.NUMSEQ
                 AND (CODAUXILIAR = REG_ITENS.CODAUXILIAR
                  OR  CODAUXILIAR IS NULL);

               DELETE FROM PCORIGEMPRECO
               WHERE NUMPED = P_REGPEDIDO.NUMPED
                 AND CODPROD = CR_PCEST.CODPROD
                 AND NUMSEQ = REG_ITENS.NUMSEQ;

               UPDATE PCEST
               SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - REG_ITENS.QT
               WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIALRETIRA
                 AND PCEST.CODPROD = CR_PCEST.CODPROD;

               PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                P_REGPEDIDO.NUMPEDINT,
                                CR_PCEST.CODPROD,
                                REG_ITENS.CODAUXILIAR,
                                REG_ITENS.NUMSEQ,
                                P_REGPEDIDO.CODCLI,
                                P_REGPEDIDO.CODUSUR,
                                NULL,
                                NULL,
                                P_REGPEDIDO.INTEGRADORA,
                                79,
                                '2',
                                'Produto sem estoque suficiente: '||CR_PCEST.CODPROD||';',
                                NULL);
            END IF;

            IF VNQTFALTA > 0 THEN
               UPDATE PCEST
               SET PCEST.QTVENDAPERDIDA = NVL(PCEST.QTVENDAPERDIDA, 0) + VNQTFALTA
               WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIALRETIRA
                 AND PCEST.CODPROD = CR_PCEST.CODPROD;

               VNNUMSEQ := VNNUMSEQ + 1;

               INSERT INTO PCFALTA(CODCLI,
                                   CODFILIAL,
                                   CODPROD,
                                   CODUSUR,
                                   DATA,
                                   NUMSEQ,
                                   PVENDA,
                                   QT,
                                   NUMPED)
                            VALUES(P_REGPEDIDO.CODCLI,
                                   REG_ITENS.CODFILIALRETIRA,
                                   CR_PCEST.CODPROD,
                                   P_REGPEDIDO.CODUSUR,
                                   TRUNC(SYSDATE),
                                   VNNUMSEQ,
                                   REG_ITENS.PVENDA,
                                   VNQTFALTA,
                                   P_REGPEDIDO.NUMPED);

               PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                                P_REGPEDIDO.NUMPEDINT,
                                CR_PCEST.CODPROD,
                                REG_ITENS.CODAUXILIAR,
                                REG_ITENS.NUMSEQORIG,
                                P_REGPEDIDO.CODCLI,
                                P_REGPEDIDO.CODUSUR,
                                NULL,
                                NULL,
                                P_REGPEDIDO.INTEGRADORA,
                                81,
                                '3',
                                'Qt. Pedida:   ' || REG_ITENS.QT ||
                                '#Qt. Atendida: ' || VNQTATEND || ';',
                                NULL);
            END IF;
         END LOOP;
      END LOOP;

      --verifica se o pedido rejeitado ficou com algum item
      IF P_REGPEDIDO.VALIDO = FALSE AND NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
         SELECT COUNT(*)
         INTO VICONTADOR
         FROM PCPEDI
         WHERE NUMPED = P_REGPEDIDO.NUMPED;

         IF VICONTADOR > 0 THEN
            FOR REG IN (SELECT CODPROD,
                               NUMSEQ,
                               PCPEDI.CODFILIALRETIRA,
                               QT,
                               POSICAO
                        FROM PCPEDI
                        WHERE NUMPED = P_REGPEDIDO.NUMPED) 
            LOOP
               IF REG.POSICAO = 'L' THEN
                  UPDATE PCEST
                  SET PCEST.QTRESERV   = NVL(PCEST.QTRESERV, 0) - REG.QT,
                      PCEST.DTULTSAIDA = TRUNC(SYSDATE)
                  WHERE PCEST.CODFILIAL = REG.CODFILIALRETIRA
                    AND PCEST.CODPROD = REG.CODPROD;
               ELSE
                  UPDATE PCEST
                  SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - REG.QT,
                      PCEST.DTULTSAIDA = TRUNC(SYSDATE)
                  WHERE PCEST.CODFILIAL = REG.CODFILIALRETIRA
                    AND PCEST.CODPROD = REG.CODPROD;
               END IF;

            DELETE PCPEDI
             WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
               AND PCPEDI.CODPROD = REG.CODPROD
               AND PCPEDI.NUMSEQ = REG.NUMSEQ;
            END LOOP;
         END IF;
      END IF;

      SELECT SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PTABELA, 0)) VLTABELA,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PVENDA, 0)) VLATEND,
             SUM((NVL(PCPEDI.QT, 0) + NVL(PCPEDI.QTFALTA, 0)) * NVL(PCPEDI.PVENDA, 0)) VLTOTAL,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOFIN, 0)) VLCUSTOFIN,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOREAL, 0)) VLCUSTOREAL,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOREP, 0)) VLCUSTOREP,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOCONT, 0)) VLCUSTOCONT,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.PESOLIQ, 0)) TOTPESO,
             SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.VOLUME, 0)) TOTVOLUME,
             COUNT(*) NUMITENS
      INTO VNVLTABELA,
           VNVLATEND,
           VNVLTOTAL,
           VNVLCUSTOFIN,
           VNVLCUSTOREAL,
           VNVLCUSTOREP,
           VNVLCUSTOCONT,
           VNTOTPESO,
           VNTOTVOLUME,
           VNNUMITENS
      FROM PCPEDI, PCPRODUT
      WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED
        AND PCPEDI.CODPROD = PCPRODUT.CODPROD;

      -- Somar corte total de item
      VNSOMAFALTA := 0;

      SELECT NVL(SUM(NVL(PCFALTA.QT, 0) * NVL(PCFALTA.PVENDA, 0)), 0)
      INTO VNSOMAFALTA
      FROM PCFALTA
      WHERE PCFALTA.NUMPED = P_REGPEDIDO.NUMPED
        AND PCFALTA.CODPROD NOT IN (SELECT PCPEDI.CODPROD
                                    FROM PCPEDI
                                    WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED);

      IF VNNUMITENS > 0 THEN
         UPDATE PCPEDI
         SET PCPEDI.POSICAO = 'L'
         WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED;

         UPDATE PCPEDC
         SET PCPEDC.POSICAO     = 'L',
             PCPEDC.VLTABELA    = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, VNVLTABELA + NVL(VLFRETE, 0)),
             PCPEDC.VLATEND     = DECODE(P_REGPEDIDO.CONDVENDA, 5, 0,
                                         DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, VNVLATEND)),
             PCPEDC.VLTOTAL     = NVL(VNVLTOTAL, 0) + NVL(VNSOMAFALTA, 0) + NVL(VLFRETE, 0),
             PCPEDC.VLCUSTOFIN  = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, VNVLCUSTOFIN),
             PCPEDC.VLCUSTOREAL = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, VNVLCUSTOREAL),
             PCPEDC.VLCUSTOREP  = DECODE(P_REGPEDIDO.CONDVENDA, 20, 0, VNVLCUSTOREP),
             PCPEDC.VLCUSTOCONT = VNVLCUSTOCONT,
             PCPEDC.TOTPESO     = VNTOTPESO,
             PCPEDC.TOTVOLUME   = VNTOTVOLUME,
             PCPEDC.NUMITENS    = VNNUMITENS
         WHERE PCPEDC.NUMPED = P_REGPEDIDO.NUMPED;

         -- COMMIT;
         P_REGPEDIDO.POSICAO := 'L';

         IF P_VLTOTPED <> VNVLATEND AND
            GREGPCCONSUM.VALIDARVLMINVENDAAPOSCORTE = 'S' AND NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
            PROC_VALIDACAOFINALCABPOSCORTE(P_REGPEDIDO,
                                           P_REGPLPAG,
                                           P_REGFILIAL,
                                           P_REGRCA,
                                           P_VLTOTPED,
                                           VNVLATEND,
                                           P_NUMSEQ,
                                           VNNUMITENS);
         END IF;
      ELSE         
         -- ROLLBACK;         
         vListaProduto := '';
         IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN           
            FOR REG IN (SELECT CODPROD, QT, CODFILIALRETIRA, POSICAO
                        FROM PCPEDI
                        WHERE NUMPED = P_REGPEDIDO.NUMPED) 
            LOOP
               IF REG.POSICAO = 'L' THEN
                  UPDATE PCEST
                  SET PCEST.QTRESERV = NVL(PCEST.QTRESERV, 0) - REG.QT
                  WHERE PCEST.CODFILIAL = REG.CODFILIALRETIRA
                    AND PCEST.CODPROD = REG.CODPROD;
               ELSE
                  IF vListaProduto = '' THEN
                     vListaProduto := ': ' || REG.CODPROD;
                  ELSE
                     vListaProduto := vListaProduto ||', '|| REG.CODPROD;
                  END IF;
                  
                  UPDATE PCEST
                  SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - REG.QT
                  WHERE PCEST.CODFILIAL = REG.CODFILIALRETIRA
                    AND PCEST.CODPROD = REG.CODPROD;
               END IF;
            END LOOP;

            DELETE FROM PCPEDC WHERE PCPEDC.NUMPED = P_REGPEDIDO.NUMPED;
            DELETE FROM PCPEDI WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED;
            DELETE FROM PCORIGEMPRECO WHERE NUMPED = P_REGPEDIDO.NUMPED;
         END IF;

        -- COMMIT;
        P_REGPEDIDO.VALIDO := FALSE;
        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                         P_REGPEDIDO.NUMPEDINT,
                         NULL,
                         NULL,
                         NULL,
                         P_REGPEDIDO.CODCLI,
                         P_REGPEDIDO.CODUSUR,
                         NULL,
                         NULL,
                         P_REGPEDIDO.INTEGRADORA,
                         51,
                         '2',
                         'Pedido rejeitado. #Itens sem estoque'||vListaProduto||';',
                         NULL);
      END IF;
   END IF;
EXCEPTION WHEN OTHERS THEN
   P_REGPEDIDO.VALIDO := FALSE;
   PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                    P_REGPEDIDO.NUMPEDINT,
                    NULL,
                    NULL,
                    NULL,
                    P_REGPEDIDO.CODCLI,
                    P_REGPEDIDO.CODUSUR,
                    NULL,
                    NULL,
                    P_REGPEDIDO.INTEGRADORA,
                    151,
                    '2',
                    'Erro14:' || SQLCODE || '-' || SQLERRM || ';',
                    NULL);

   IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
      FOR REG IN (SELECT CODPROD, QT, CODFILIALRETIRA, POSICAO
                      FROM PCPEDI
                     WHERE NUMPED = P_REGPEDIDO.NUMPED) 
      LOOP
         IF REG.POSICAO = 'L' THEN
            UPDATE PCEST
            SET PCEST.QTRESERV = NVL(PCEST.QTRESERV, 0) - REG.QT
            WHERE PCEST.CODFILIAL = REG.CODFILIALRETIRA
              AND PCEST.CODPROD = REG.CODPROD;
         ELSE
            UPDATE PCEST
            SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - REG.QT
            WHERE PCEST.CODFILIAL = REG.CODFILIALRETIRA
              AND PCEST.CODPROD = REG.CODPROD;
         END IF;
      END LOOP;

      DELETE FROM PCPEDC WHERE PCPEDC.NUMPED = P_REGPEDIDO.NUMPED;
      DELETE FROM PCPEDI WHERE PCPEDI.NUMPED = P_REGPEDIDO.NUMPED;
      DELETE FROM PCORIGEMPRECO WHERE NUMPED = P_REGPEDIDO.NUMPED;
   END IF;
END PROC_GRAVAESTOQUE;


FUNCTION isCobrancaCartao(pCodCob IN VARCHAR) RETURN BOOLEAN 
IS
   vCartao VARCHAR2(1);
BEGIN
   BEGIN
      SELECT NVL(CARTAO,'N')
      INTO vCartao
      FROM PCCOB
      WHERE CODCOB = pCodCob;
   EXCEPTION WHEN OTHERS THEN
      vCartao := 'N';
   END;

   RETURN(vCartao = 'S');
END;


  PROCEDURE PROC_VALIDACAOFINALCAB(P_REGPEDIDO        IN OUT T_CABPED,
                                   P_REGCLIENTE       IN T_CLIENTEPEDIDO,
                                   P_REGPLPAG         IN OUT T_PLANODEPAGAMENTO,
                                   P_REGCOB           IN T_PCCOB,
                                   P_REGFILIAL        IN T_FILIAL,
                                   P_REGRCA           IN T_RCA,
                                   P_CONTITENSVALIDOS IN NUMBER,
                                   P_VLTOTPED         IN NUMBER,
                                   P_VLTOTPED_ANT     IN NUMBER,
                                   P_VLTOTTAB         IN NUMBER,
                                   P_VLCUSTOFIN       IN NUMBER) IS
    VSMENSAGEM              VARCHAR2(32767);
    VSCHAR                  VARCHAR2(1) DEFAULT '#';
    VNSALDODISPONIVEL       NUMBER;
    VNNUMEROPARCELAS        INTEGER;
    VNVALORPARCELA          NUMBER;
    VSMENSAGEM_VENDAPF      VARCHAR2(1000);
    VNVLMINPEDIDO           PCCOB.VLMINPEDIDO%TYPE;
    VNVLPEDIDO              NUMBER;
    VNVLTOTVENDABONIFICMES  NUMBER := 0;
    VNPERDESCTOT   NUMBER;
    VICONTPARC     NUMBER;
    VNVLMINVENDABK NUMBER(18, 6);
    VNPERLUC       NUMBER(18, 6);

  BEGIN
    VSMENSAGEM := NULL;

    IF P_REGPLPAG.FORMAPARCELAMENTO = 'V' AND NVL(P_REGPEDIDO.NUMPEDORIG,0) = 0 THEN
      SELECT COUNT(*)
        INTO VICONTPARC
        FROM PCPEDCVCTO
       WHERE NUMPED = P_REGPEDIDO.NUMPED;

      IF NVL(VICONTPARC,0) <> 0 THEN      
         IF P_VLTOTPED / VICONTPARC < P_REGPLPAG.VLMINPARCELA THEN
            IF VSMENSAGEM IS NULL THEN
               VSMENSAGEM := 'Valor da Parcela do pedido : ' || ROUND(P_VLTOTPED / VICONTPARC, 2) ||
                             ' menor que o permitido : ' || P_REGPLPAG.VLMINPARCELA;
            ELSE
               VSMENSAGEM := VSMENSAGEM || CHR(13) || 'Valor da Parcela do pedido : ' ||
                             ROUND(P_VLTOTPED / VICONTPARC, 2) || ' menor que o permitido : ' || 
                             P_REGPLPAG.VLMINPARCELA;
            END IF;

            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 75;
         END IF;
      END IF;
    END IF;

    IF P_REGPEDIDO.CONDVENDA = 5 AND P_REGFILIAL.VLMAXVENDABONIFICMES > 0 THEN
      BEGIN
        SELECT SUM(ROUND(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PVENDA, 0), 2))
          INTO VNVLTOTVENDABONIFICMES
          FROM PCPEDI, PCPEDC
         WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
           AND PCPEDC.DTCANCEL IS NULL
           AND TO_CHAR(PCPEDC.DATA, 'mm/yyyy') = TO_CHAR(TRUNC(SYSDATE), 'mm/yyyy')
           AND PCPEDC.CODFILIAL = P_REGPEDIDO.CODFILIAL
           AND PCPEDC.CONDVENDA IN (5, 11)
           AND PCPEDC.NUMPED <> P_REGPEDIDO.NUMPED;
      EXCEPTION
        WHEN OTHERS THEN
          VNVLTOTVENDABONIFICMES := 0;
      END;

      IF NVL(P_VLTOTPED, 0) + NVL(VNVLTOTVENDABONIFICMES, 0) >
         P_REGFILIAL.VLMAXVENDABONIFICMES THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'O pedido nao podera ser gravado, por que o valor do pedido de(' ||
                      P_VLTOTPED || ') + o valor de vendas bonificadas para este mês (' ||
                      VNVLTOTVENDABONIFICMES || ' )#';
        VSMENSAGEM := VSMENSAGEM || 'ultrapassa o valor de estipulado para bonificações no mês (' ||
                      P_REGFILIAL.VLMAXVENDABONIFICMES || ' );';

        P_REGPEDIDO.VALIDO := FALSE;

        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 68;
      END IF;
    END IF;

    IF P_VLTOTPED > GREGPCCONSUM.VLMAXVENDA AND
       NVL(GREGPCCONSUM.VLMAXVENDA, 0) > 0 THEN
      IF GREGPCCONSUM.ACEITAVENDABLOQ = 'S' THEN
        P_REGPEDIDO.POSICAO       := 'B';
        P_REGPEDIDO.CODMOTIVO     := 4;
        P_REGPEDIDO.MOTIVOPOSICAO := 'Pedido excede valor maximo por pedido.';

        IF P_REGPEDIDO.POSICAO = 'B' THEN
          PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
        END IF;
      ELSE
        P_REGPEDIDO.VALIDO := FALSE;
      END IF;

      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido de(' || P_VLTOTPED ||
                    ') execede o valor maximo estipulado por pedido (' || GREGPCCONSUM.VLMAXVENDA || ' ).';
    END IF;

    --tarefa 47538
    BEGIN
      SELECT NVL(PCCOB.VLMINPEDIDO, 0)
        INTO VNVLMINPEDIDO
        FROM PCCOB
       WHERE CODCOB = P_REGPEDIDO.CODCOB;
    EXCEPTION
      WHEN OTHERS THEN
        VNVLMINPEDIDO := 0;
    END;

    IF P_VLTOTPED < VNVLMINPEDIDO THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' || P_VLTOTPED || ') menor que o#';
      VSMENSAGEM := VSMENSAGEM || 'mínimo para a cobranca: ' || P_REGPEDIDO.CODCOB || ';';

      IF gregpcconsum.aceitavendabloq = 'S' THEN
        P_REGPEDIDO.POSICAO   := 'B';
        P_REGPEDIDO.CODMOTIVO := 9;
        P_REGPEDIDO.LOG       := P_REGPEDIDO.LOG || CHR(13) || 'Valor do pedido menor que o minimo para cobranca';
        P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do pedido menor que o minimo para cobranca';
        P_REGPEDIDO.CODRETORNOS   := P_REGPEDIDO.CODRETORNOS || ';' || 30;

        IF P_REGPEDIDO.POSICAO = 'B' THEN
          PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
        END IF;
      ELSE
        P_REGPEDIDO.CODMOTIVO := 9;
        P_REGPEDIDO.LOG       := P_REGPEDIDO.LOG || CHR(13) || 'Valor do pedido menor que o minimo para cobranca';
        P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do pedido menor que o minimo para cobranca';
        P_REGPEDIDO.CODRETORNOS   := P_REGPEDIDO.CODRETORNOS || ';' || 30;
        p_regpedido.valido := FALSE;
      END IF;
    END IF;
    --Por rca
    IF NVL(P_REGRCA.VLVENDAMINPED, 0) > 0 THEN
      IF P_VLTOTPED < NVL(P_REGRCA.VLVENDAMINPED, 0) THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;

        VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' || P_VLTOTPED || ') menor que o#' || ';';
        VSMENSAGEM := VSMENSAGEM || 'mínimo permitido para o RCA: ' || P_REGRCA.VLVENDAMINPED || ';';

        IF gregpcconsum.aceitavendabloq = 'S' THEN
          p_regpedido.posicao       := 'B';
          p_regpedido.codmotivo     := 8;
          p_regpedido.motivoposicao := 'Valor do pedido menor que minimo para RCA';

          IF P_REGPEDIDO.POSICAO = 'B' THEN
            PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
          END IF;
        ELSE
          p_regpedido.codmotivo     := 8;
          p_regpedido.motivoposicao := 'Valor do pedido menor que minimo para RCA';
          p_regpedido.valido := FALSE;
        END IF;
      END IF;
    END IF;

    IF P_REGPEDIDO.CONDVENDA NOT IN (4, 5, 8) THEN
      IF NVL(P_REGFILIAL.PERMAXDESCVENDA, 0) > 0 THEN
        IF NVL(P_VLTOTTAB,0) <> 0 THEN
          VNPERDESCTOT := ROUND((((P_VLTOTTAB - P_VLTOTPED) / P_VLTOTTAB) * 100), GREGPCCONSUM.NUMCASASDECVENDA);
        ELSE
          VNPERDESCTOT := 0;
        END IF;

        IF VNPERDESCTOT > NVL(P_REGFILIAL.PERMAXDESCVENDA, 0) THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Percentual médio de desconto do pedido (' || VNPERDESCTOT || ') maior que o#';
          VSMENSAGEM := VSMENSAGEM || 'máximo cadastrado por filial: ' || NVL(P_REGFILIAL.PERMAXDESCVENDA, 0) || ';';

          IF gregpcconsum.aceitavendabloq = 'S'
          THEN
            P_REGPEDIDO.POSICAO       := 'B';
            P_REGPEDIDO.CODMOTIVO     := 10;
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Percentual medio de desconto do pedido, maior que o maximo cadastrado';
            P_REGPEDIDO.MOTIVOPOSICAO := 'Perc medio desconto do pedido, maior que maximo cadastrado';
            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 148;

            IF P_REGPEDIDO.POSICAO = 'B' THEN
              PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          ELSE
            P_REGPEDIDO.CODMOTIVO     := 10;
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Percentual medio de desconto do pedido, maior que o maximo cadastrado';
            P_REGPEDIDO.MOTIVOPOSICAO := 'Perc medio desconto do pedido, maior que maximo cadastrado';

            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 148;
            p_regpedido.valido := FALSE;
          END IF;
        END IF;
      ELSE
        IF NVL(GREGPCCONSUM.PERMAXDESCVENDA, 0) > 0 THEN
          IF NVL(P_VLTOTTAB,0) <> 0 THEN
            VNPERDESCTOT := ROUND((((P_VLTOTTAB - P_VLTOTPED) / P_VLTOTTAB) * 100), GREGPCCONSUM.NUMCASASDECVENDA);
          ELSE
            VNPERDESCTOT := 0;
          END IF;

          IF VNPERDESCTOT > NVL(GREGPCCONSUM.PERMAXDESCVENDA, 0) THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Percentual médio de desconto do pedido (' || VNPERDESCTOT || ') maior que o#';
            VSMENSAGEM := VSMENSAGEM || 'máximo cadastrado para a empresa: ' || NVL(GREGPCCONSUM.PERMAXDESCVENDA, 0) || ';';

            IF gregpcconsum.aceitavendabloq = 'S' THEN
              P_REGPEDIDO.POSICAO       := 'B';
              P_REGPEDIDO.CODMOTIVO     := 10;
              P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Percentual medio de desconto do pedido, maior que o maximo cadastrado';
              P_REGPEDIDO.MOTIVOPOSICAO := 'Perc medio desconto do pedido, maior que maximo cadastrado';
              P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 148;

              IF P_REGPEDIDO.POSICAO = 'B' THEN
                PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
              END IF;
            ELSE
              P_REGPEDIDO.CODMOTIVO     := 10;
              P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Percentual medio de desconto do pedido, maior que o maximo cadastrado';
              P_REGPEDIDO.MOTIVOPOSICAO := 'Perc medio desconto do pedido, maior que maximo cadastrado';
              P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 148;
              p_regpedido.valido := FALSE;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    IF P_CONTITENSVALIDOS < P_REGPLPAG.NUMITENSMINIMO THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Numero de itens (' || P_CONTITENSVALIDOS || ') menor que o#';
      VSMENSAGEM := VSMENSAGEM || 'mínimo para o plano de pagamento: ' || P_REGPLPAG.CODPLPAG || ';';

      IF gregpcconsum.aceitavendabloq = 'S' THEN
        P_REGPEDIDO.POSICAO   := 'B';
        P_REGPEDIDO.CODMOTIVO := 10;
        P_REGPEDIDO.LOG       := P_REGPEDIDO.LOG || CHR(13) || 'Numero de itens menor que minimo para plano de pagto';
        P_REGPEDIDO.MOTIVOPOSICAO := 'Numero de itens menor que minimo para plano de pagto';
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 31;

        IF P_REGPEDIDO.POSICAO = 'B' THEN
          PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
        END IF;
      ELSE
        P_REGPEDIDO.CODMOTIVO := 10;
        P_REGPEDIDO.LOG       := P_REGPEDIDO.LOG || CHR(13) || 'Numero de itens menor que minimo para plano de pagto';
        P_REGPEDIDO.MOTIVOPOSICAO := 'Numero de itens menor que minimo para plano de pagto';
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 31;
        p_regpedido.valido := FALSE;
      END IF;
    END IF;

    IF P_VLTOTPED < P_REGPLPAG.VLMINPEDIDO THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' || P_VLTOTPED || ') menor que o#';
      VSMENSAGEM := VSMENSAGEM || 'mínimo para o plano de pagamento: ' || P_REGPLPAG.CODPLPAG || ';';

      IF gregpcconsum.aceitavendabloq = 'S' THEN
        P_REGPEDIDO.POSICAO       := 'B';
        P_REGPEDIDO.CODMOTIVO     := 10;
        P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Valor do pedido menor que minimo para plano pagto';
        P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do pedido menor que minimo para plano pagto';
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 32;

        IF P_REGPEDIDO.POSICAO = 'B' THEN
           PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
        END IF;
      ELSE
        P_REGPEDIDO.CODMOTIVO     := 10;
        P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Valor do pedido menor que minimo para plano pagto';
        P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do pedido menor que minimo para plano pagto';
        P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 32;
        p_regpedido.valido := FALSE;
      END IF;
    END IF;

    SELECT ROUND(DECODE(NVL(P_VLTOTPED,0), 0, 0, (((P_VLTOTPED - P_VLCUSTOFIN) / P_VLTOTPED) * 100)), GREGPCCONSUM.NUMCASASDECVENDA)
    INTO VNPERLUC
    FROM DUAL;

    IF VNPERLUC < P_REGPLPAG.MARGEMMIN AND NVL(P_REGPLPAG.MARGEMMIN, 0) > 0 THEN
      IF P_REGFILIAL.BLOQPEDABAIXOMARGEMFV = 'S' THEN
        P_REGPEDIDO.POSICAO       := 'B';
        P_REGPEDIDO.CODMOTIVO     := 16;
        P_REGPEDIDO.MOTIVOPOSICAO := 'Margem de lucratividade do pedido menor que minima ';
        P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Margem de lucratividade do pedido menor que a minima';

        IF P_REGPEDIDO.POSICAO = 'B' THEN
          PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
        END IF;
      ELSE
        P_REGPEDIDO.VALIDO := FALSE;
      END IF;

      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Margem de lucratividade do pedido (' || VNPERLUC || ') menor que a#';
      VSMENSAGEM := VSMENSAGEM || 'mínima para o plano de pagamento: ' || P_REGPLPAG.CODPLPAG || ';';

      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 164;
    END IF;

   IF NOT ((NVL(GREGPCCONSUM.VERIFICALIMCREDCODCOBD,'S') = 'N') AND
           ((P_REGPEDIDO.CODCOB IN ('D','DH','CAR')) OR (isCobrancaCartao(P_REGPEDIDO.CODCOB)))) THEN
      SELECT DECODE(P_REGPEDIDO.NUMPEDORIG, 0,
                    P_VLTOTPED, P_VLTOTPED - P_VLTOTPED_ANT)
      INTO VNVLPEDIDO
      FROM DUAL;

      IF P_REGPLPAG.TIPOENTRADA = 3 AND P_REGPLPAG.DESCENTLIMCREDCLI = 'S' THEN
        VNVLPEDIDO := VNVLPEDIDO - NVL(P_REGPEDIDO.VLENTRADA, 0);
      END IF;
      -- Verifica se o pedido nao foi importado de um e-commerce
      -- e se o pedido nao esta pago
      IF NVL(P_REGFILIAL.IMPORTAPEDIDOECOMMERCEPAGO, 'N') = 'N' AND
         NVL(P_REGPEDIDO.PEDIDOPAGOECOMMERCE, 'N') = 'N' THEN
        -- Caso positivo, valida o limite de credito
        -- Caso ultrapasse o limite de cred, grava o pedido como bloqueado.
        IF (NOT FUNC_EXISTELIMITECLIENTE(P_REGPEDIDO, P_REGCLIENTE, P_REGFILIAL,
                                         VNVLPEDIDO, VNSALDODISPONIVEL)) THEN
          IF NVL(P_REGPEDIDO.NUMPEDORIG, 0) = 0 THEN
            IF NVL(P_REGFILIAL.BLOQPEDLIMCRED, 'N') = 'S' THEN
              P_REGPEDIDO.POSICAO       := 'B';
              P_REGPEDIDO.CODMOTIVO     := 3;
              P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Cliente sem limite de credito';
              P_REGPEDIDO.MOTIVOPOSICAO := 'Cliente sem limite de credito';

              IF P_REGPEDIDO.POSICAO = 'B' THEN
                PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
              END IF;
            ELSE
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;
          ELSE
            IF P_REGPEDIDO.POSICAO <> 'B' THEN
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;
          END IF;

          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Pedido ultrapassa credito#';
          VSMENSAGEM := VSMENSAGEM || 'disponivel do cliente#';
          VSMENSAGEM := VSMENSAGEM || 'Valor do Pedido   : ' || P_VLTOTPED || '#';
          VSMENSAGEM := VSMENSAGEM || 'Credito disponivel: ' || VNSALDODISPONIVEL || ';';
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 33;
        END IF;
      END IF;
   END IF;

   IF NVL(GREGPCCONSUM.TRAVAVENDAPF, 'N') = 'S' AND
       ((P_REGCLIENTE.TIPOFJ = 'F' AND P_REGCLIENTE.CONTRIBUINTE = 'N') OR
        (P_REGCLIENTE.CONSUMIDORFINAL = 'S') OR
        ((GREGPCCONSUM.CONSIDERAISENTOSCOMOPF = 'S') AND
        ((TRIM(P_REGCLIENTE.IEENT) = '') OR (P_REGCLIENTE.IEENT IS NULL) OR
        (UPPER(P_REGCLIENTE.IEENT) = 'ISENTA') OR
        (UPPER(P_REGCLIENTE.IEENT) = 'ISENTO')))) THEN
      P_REGPEDIDO.VALIDO := FALSE;
      VSMENSAGEM         := VSMENSAGEM || VSCHAR || 'VENDA PARA PESSOA FISICA NAO PERMITIDA.';
      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 34;
   END IF;

   IF (NVL(P_REGFILIAL.PERMITIRVENDAINTERESTADUALPF, 'S') = 'N') AND
       ((P_REGCLIENTE.ESTENT <> P_REGFILIAL.UF) AND
       ((P_REGCLIENTE.TIPOFJ = 'F' AND P_REGCLIENTE.CONTRIBUINTE = 'N') OR
       (P_REGCLIENTE.CONSUMIDORFINAL = 'S') OR
       ((GREGPCCONSUM.CONSIDERAISENTOSCOMOPF = 'S') AND
       ((TRIM(P_REGCLIENTE.IEENT) = '') OR (P_REGCLIENTE.IEENT IS NULL) OR
       (UPPER(P_REGCLIENTE.IEENT) = 'ISENTA') OR
       (UPPER(P_REGCLIENTE.IEENT) = 'ISENTO'))))) THEN
      P_REGPEDIDO.VALIDO := FALSE;
      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'VENDA INTERESTADUAL PARA PESSOA FISICA NAO PERMITIDA NESTA FILIAL';
      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 35;
   END IF;

   IF ((NVL(P_REGFILIAL.PERMITIRVENDAESTADUALPFCOMIE, 'S') = 'N') AND
       (P_REGCLIENTE.ESTENT = P_REGFILIAL.UF) AND
       ((P_REGCLIENTE.TIPOFJ = 'F') AND (P_REGCLIENTE.CONTRIBUINTE = 'N') AND
       (TRIM(UPPER(P_REGCLIENTE.IEENT)) <> '' AND
       TRIM(UPPER(P_REGCLIENTE.IEENT)) <> 'ISENTA' AND
       TRIM(UPPER(P_REGCLIENTE.IEENT)) <> 'ISENTO'))) THEN
      P_REGPEDIDO.VALIDO := FALSE;
      VSMENSAGEM := VSMENSAGEM || VSCHAR || 'VENDA ESTADUAL PARA PESSOA FISICA COM INSC ESTADUAL NAO PERMITIDA NESTA FILIAL';
      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 36;
   END IF;

    IF (NVL(P_REGFILIAL.PERMITIRVENDAESTADUALPFSEMIE, 'S') = 'N') AND
       (P_REGCLIENTE.ESTENT = P_REGFILIAL.UF) AND
       ((P_REGCLIENTE.TIPOFJ = 'F') AND (P_REGCLIENTE.CONTRIBUINTE = 'N') AND
       (TRIM(UPPER(P_REGCLIENTE.IEENT)) = '' OR
       TRIM(UPPER(P_REGCLIENTE.IEENT)) = 'ISENTA' OR
       TRIM(UPPER(P_REGCLIENTE.IEENT)) = 'ISENTO')) THEN
      P_REGPEDIDO.VALIDO := FALSE;
      VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                    'VENDA ESTADUAL PARA PESSOA FISICA SEM/ISENTA INSC ESTADUAL NAO PERMITIDA NESTA FILIAL';
      P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 37;
    END IF;

    IF NVL(P_REGCLIENTE.VALIDAMAXVENDAPF, 'N') = 'S' THEN
      --Verificar venda p/ pessoa física
      IF (P_REGCLIENTE.TIPOFJ = 'F' AND P_REGCLIENTE.CONTRIBUINTE = 'N') OR
         (P_REGCLIENTE.CONSUMIDORFINAL = 'S') OR
         ((GREGPCCONSUM.CONSIDERAISENTOSCOMOPF = 'S') AND
         ((TRIM(NVL(P_REGCLIENTE.IEENT,'')) = '') OR
         (UPPER(P_REGCLIENTE.IEENT) = 'ISENTA') OR
         (UPPER(P_REGCLIENTE.IEENT) = 'ISENTO'))) THEN
        IF NOT
            FUNCOESVENDAS.VERIFICARVALORMAXIMOVENDAPF(P_REGCLIENTE.CODCLI,
                                                      P_VLTOTPED,
                                                      0,
                                                      P_REGPEDIDO.PERCVENDA,
                                                      NVL(GREGPCCONSUM.ACEITAVENDAPF, 'S'),
                                                      NVL(GREGPCCONSUM.VERIFICARLIMVENDAPF, 'N'),
                                                      GREGPCCONSUM.VLMAXVENDAPF,
                                                      GREGPCCONSUM.PERLIMVENDAPF,
                                                      GREGPCCONSUM.VLMAXPEDIDOPF,
                                                      GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                      P_REGPEDIDO.CODFILIAL,
                                                      VSMENSAGEM_VENDAPF) THEN
          IF VSMENSAGEM_VENDAPF IS NOT NULL THEN
            P_REGPEDIDO.VALIDO := FALSE;
            VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEM_VENDAPF;

            IF INSTR(UPPER(VSMENSAGEM_VENDAPF), 'ERRO') > 0 THEN
               P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 41;
            ELSE
              IF INSTR(UPPER(VSMENSAGEM_VENDAPF), 'PERMITIDA') > 0 THEN
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 34;
              ELSIF INSTR(UPPER(VSMENSAGEM_VENDAPF), 'PERMITIDO') > 0 THEN
                P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 38;
              ELSE
                IF INSTR(UPPER(VSMENSAGEM_VENDAPF), 'ESTADUAL') > 0 THEN
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 40;
                ELSE
                  P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 39;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    VNVLMINVENDABK := NVL(P_REGFILIAL.VLMINVENDABKFILIAL, 0);

    IF VNVLMINVENDABK = 0 AND GREGPCCONSUM.VLMINVENDABK > 0 THEN
      VNVLMINVENDABK := GREGPCCONSUM.VLMINVENDABK;
    END IF;
    -- verifica se o pedido foi importado de um de e-commerce
    -- e se o pedido esta pago
    IF NVL(P_REGFILIAL.IMPORTAPEDIDOECOMMERCEPAGO, 'N') = 'S' AND
       NVL(P_REGPEDIDO.PEDIDOPAGOECOMMERCE, 'N') = 'S' THEN
      -- caso verdadeiro, nao valida o valor minimo de boleto
      VNVLMINVENDABK := 0;
    END IF;
    -- verifica valor parcela minima para cobranca BK
    IF P_REGPEDIDO.CODCOB = 'BK' OR P_REGCOB.BOLETO = 'S' THEN
      VNNUMEROPARCELAS := FUNC_CALCULANUMPARCPLPAG(P_REGPLPAG);
      VNVALORPARCELA   := 0;
      IF NVL(VNNUMEROPARCELAS,0) <> 0 THEN
         VNVALORPARCELA := ROUND((P_VLTOTPED / VNNUMEROPARCELAS), GREGPCCONSUM.NUMCASASDECVENDA);
      END IF;

      IF GREGPCCONSUM.TIPOVLMINVENDABK = 'VP' THEN
        IF VNVALORPARCELA < NVL(VNVLMINVENDABK, 0) THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor da parcela menor#';
          VSMENSAGEM := VSMENSAGEM || 'que valor minimo para#';
          VSMENSAGEM := VSMENSAGEM || 'cobranca bancaria (BK)#';
          VSMENSAGEM := VSMENSAGEM || 'Vl. Parcela : ' || VNVALORPARCELA || '#';
          VSMENSAGEM := VSMENSAGEM || 'Vl. Minimo  : ' || NVL(VNVLMINVENDABK, 0) || ';';

          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 42;

          IF NVL(GREGPCCONSUM.ACEITAVENDABLOQ, 'N') = 'S' THEN
            P_REGPEDIDO.POSICAO       := 'B';
            P_REGPEDIDO.CODMOTIVO     := 15;
            P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para cobrança BK';
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Valor do Pedido menor que o minimo para cobrança BK';

            IF P_REGPEDIDO.POSICAO = 'B' THEN
              PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          ELSE
            P_REGPEDIDO.CODMOTIVO     := 15;
            P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para cobrança BK';
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Valor do Pedido menor que o minimo para cobrança BK';
            P_REGPEDIDO.VALIDO := FALSE;
          END IF;
        END IF;
      ELSIF GREGPCCONSUM.TIPOVLMINVENDABK = 'VT' THEN
        IF P_VLTOTPED < NVL(VNVLMINVENDABK, 0) THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido menor#';
          VSMENSAGEM := VSMENSAGEM || 'que valor minimo para#';
          VSMENSAGEM := VSMENSAGEM || 'cobranca bancaria (BK)#';
          VSMENSAGEM := VSMENSAGEM || 'Vl. Pedido : ' || P_VLTOTPED || '#';
          VSMENSAGEM := VSMENSAGEM || 'Vl. Minimo  : ' || NVL(VNVLMINVENDABK, 0) || ';';

          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 42;

          IF NVL(GREGPCCONSUM.ACEITAVENDABLOQ, 'N') = 'S' THEN
            P_REGPEDIDO.POSICAO       := 'B';
            P_REGPEDIDO.CODMOTIVO     := 15;
            P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para cobrança BK';
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Valor do Pedido menor que o minimo para cobrança BK';

            IF P_REGPEDIDO.POSICAO = 'B' THEN
              PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
            END IF;
          ELSE
            P_REGPEDIDO.CODMOTIVO     := 15;
            P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do Pedido menor que o minimo para cobrança BK';
            P_REGPEDIDO.LOG           := P_REGPEDIDO.LOG || CHR(13) || 'Valor do Pedido menor que o minimo para cobrança BK';
            P_REGPEDIDO.VALIDO := FALSE;
          END IF;
        END IF;
      END IF;
    END IF;

    IF P_REGPEDIDO.ORIGEMPED <> 'R' OR
       (P_REGPEDIDO.ORIGEMPED = 'R' AND
       P_REGFILIAL.VALIDAVLMINVENDABALCAO = 'S') THEN
      IF P_REGPEDIDO.CONDVENDA IN (1, 7, 13) AND
         P_REGFILIAL.VLMINVENDAFV > 0 THEN
        IF P_REGFILIAL.VLMINVENDAFV > 0 THEN
          IF P_VLTOTPED < P_REGFILIAL.VLMINVENDAFV THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;

            VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' || P_VLTOTPED || ') menor que o #';
            VSMENSAGEM := VSMENSAGEM || 'mínimo para o pedido (' || NVL(P_REGFILIAL.VLMINVENDAFV, 0) || ');';

            IF GREGPCCONSUM.ACEITAVENDABLOQ = 'S' THEN
              P_REGPEDIDO.POSICAO       := 'B';
              P_REGPEDIDO.CODMOTIVO     := 11;
              P_REGPEDIDO.MOTIVOPOSICAO := 'Valor do pedido menor que minimo para pedido';

              IF P_REGPEDIDO.POSICAO = 'B' THEN
                PROC_BLOQUEIA_PEDIDO(P_REGPEDIDO.NUMPED, P_REGPEDIDO.MOTIVOPOSICAO);
              END IF;
            ELSE
              P_REGPEDIDO.VALIDO := FALSE;
            END IF;

            P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 43;
          END IF;
        END IF;
      ELSIF P_REGPEDIDO.CONDVENDA = 5 THEN
        IF P_VLTOTPED > NVL(GREGPCCONSUM.VLMAXVENDABNF, 0) AND
           NVL(GREGPCCONSUM.VLMAXVENDABNF, 0) > 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' || P_VLTOTPED || ') maior que o #';
          VSMENSAGEM := VSMENSAGEM || 'maximo para o pedido bonificado (' || NVL(GREGPCCONSUM.VLMAXVENDABNF, 0) || ');';
          P_REGPEDIDO.VALIDO      := FALSE;
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 43;
        END IF;

        IF P_VLTOTPED < P_REGFILIAL.VLMINVENDABNFFV AND
           P_REGFILIAL.VLMINVENDABNFFV > 0 THEN
          IF VSMENSAGEM IS NOT NULL THEN
            VSCHAR := '#';
          ELSE
            VSCHAR := NULL;
          END IF;

          VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Valor do pedido (' || P_VLTOTPED || ') menor que o #';
          VSMENSAGEM := VSMENSAGEM || 'mínimo para o pedido bonificado (' || P_REGFILIAL.VLMINVENDABNFFV || ');';
          P_REGPEDIDO.VALIDO      := FALSE;
          P_REGPEDIDO.CODRETORNOS := P_REGPEDIDO.CODRETORNOS || ';' || 43;
        END IF;
      END IF;
    END IF;

    IF (P_REGPEDIDO.CODMOTIVO IS NULL) AND
       (P_REGPEDIDO.POSICAO = 'B') THEN
      P_REGPEDIDO.CODMOTIVO     := 25;
      P_REGPEDIDO.MOTIVOPOSICAO := 'PEDIDOS DA INTEGRACAO';
    END IF;

    -- registra log
    IF (VSMENSAGEM IS NOT NULL) THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       P_REGPEDIDO.CODRETORNOS,
                       '2',
                       'Erro15:' || VSMENSAGEM,
                       NULL);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      P_REGPEDIDO.VALIDO := FALSE;
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       NULL,
                       NULL,
                       NULL,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       NULL,
                       '2',
                       'Erro16:' || SQLCODE || '-' || SQLERRM,
                       NULL);
  END PROC_VALIDACAOFINALCAB;


  PROCEDURE PROC_VALIDADESCONTOFINACEIRO(P_NUMPED      IN NUMBER,
                                         P_VALIDO      OUT BOOLEAN,
                                         P_CODRETORNOS IN OUT NUMBER) IS
    VSMENSAGEM         VARCHAR2(2000);
    VICONT             NUMBER;
    VSPOSICAO          VARCHAR2(1);
    VNPERDESCFIN       NUMBER;
    VNVLATEND          NUMBER;
    VNCODUSUR          NUMBER;
    VNNUMITENS         NUMBER;
    VNPERCMAXDESCFIN   PCPARAMSALDO.PERCMAXDESCFIN%TYPE;
    VNQTMINITENS       PCPARAMSALDO.QTMINITENS%TYPE;
    VNVLTOTDESCFIN     NUMBER;
    VSCODFILIAL        PCPEDC.CODFILIAL%TYPE;
    VSMENSAGEMSALDORCA VARCHAR2(1000);
    VBSALDORCA         BOOLEAN;
    VNNUMPEDRCA        PCPEDC.NUMPEDRCA%TYPE;
    VNINTEGRADORA      PCPEDC.INTEGRADORA%TYPE;
    VNCODCLI           PCPEDC.CODCLI%TYPE;
    VNCODEMITENTE      PCPEDC.CODEMITENTE%TYPE;
  BEGIN
    VSMENSAGEM    := NULL;
    VBSALDORCA    := TRUE;
    P_CODRETORNOS := NULL;

    SELECT POSICAO,
           NVL(PERDESCFIN, 0),
           NVL(VLATEND, 0),
           CODUSUR,
           NUMITENS,
           CODFILIAL,
           NUMPEDRCA,
           INTEGRADORA,
           CODCLI,
           CODEMITENTE
      INTO VSPOSICAO,
           VNPERDESCFIN,
           VNVLATEND,
           VNCODUSUR,
           VNNUMITENS,
           VSCODFILIAL,
           VNNUMPEDRCA,
           VNINTEGRADORA,
           VNCODCLI,
           VNCODEMITENTE
      FROM PCPEDC
     WHERE NUMPED = P_NUMPED;

    SELECT COUNT(*) INTO VICONT FROM PCPARAMSALDO;

    IF VICONT = 0 THEN
      VSMENSAGEM    := 'Nao existe parametro para aceitar pedido com desconto financeiro';
      VBSALDORCA    := FALSE;
      P_CODRETORNOS := 55;
    ELSE
      SELECT NVL(P.PERCMAXDESCFIN, 0), NVL(P.QTMINITENS, 0)
        INTO VNPERCMAXDESCFIN, VNQTMINITENS
        FROM PCPARAMSALDO P;
    END IF;

    IF VNPERDESCFIN > VNPERCMAXDESCFIN THEN
      VSMENSAGEM    := 'Desconto financeiro do pedido maior que o maximo permitido';
      VBSALDORCA    := FALSE;
      P_CODRETORNOS := 56;
    END IF;

    IF VNNUMITENS < VNQTMINITENS THEN
      VSMENSAGEM    := 'Quantidade de itens do pedido menor que a minima permitida para desconto financeiro';
      VBSALDORCA    := FALSE;
      P_CODRETORNOS := 57;
    END IF;

    IF VBSALDORCA = TRUE THEN
      VNVLTOTDESCFIN := PC_PKG_CONTROLARSALDORCA.CCFINRCA_SALDORCAMENOSDESCFIN(VNCODUSUR, VSCODFILIAL);

      IF VNVLTOTDESCFIN - (VNVLATEND * VNPERDESCFIN / 100) <= 0 THEN
        VSMENSAGEM    := 'RCA sem saldo para liberar pedido com desconto financeiro';
        VBSALDORCA    := FALSE;
        P_CODRETORNOS := 58;
      END IF;
    END IF;

    IF VBSALDORCA = TRUE THEN
      VBSALDORCA := PC_PKG_CONTROLARSALDORCA.CCFINRCA_INCLUIR_ITEM_PEDIDO(VNCODEMITENTE,
                                                                          2513,
                                                                          VNCODUSUR,
                                                                          P_NUMPED,
                                                                          NULL,
                                                                          NULL,
                                                                          VSMENSAGEMSALDORCA);
      IF VBSALDORCA = FALSE THEN
        FOR REG_ITENS IN (SELECT CODPROD,
                                 NUMSEQ,
                                 QT,
                                 NVL(CODFILIALRETIRA, VSCODFILIAL) CODFILIAL
                            FROM PCPEDI
                           WHERE NUMPED = P_NUMPED) 
        LOOP
          DELETE FROM PCPEDI
           WHERE NUMPED = P_NUMPED
             AND CODPROD = REG_ITENS.CODPROD
             AND NUMSEQ = REG_ITENS.NUMSEQ;

          IF VSPOSICAO = 'L' THEN
            UPDATE PCEST
               SET PCEST.QTRESERV   = NVL(PCEST.QTRESERV, 0) - NVL(REG_ITENS.QT, 0),
                   PCEST.DTULTSAIDA = TRUNC(SYSDATE)
             WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIAL
               AND PCEST.CODPROD = REG_ITENS.CODPROD;
          ELSE
            UPDATE PCEST
               SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - NVL(REG_ITENS.QT, 0),
                   PCEST.DTULTSAIDA = TRUNC(SYSDATE)
             WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIAL
               AND PCEST.CODPROD = REG_ITENS.CODPROD;
          END IF;
        END LOOP;

        DELETE FROM PCPEDC WHERE NUMPED = P_NUMPED;

        PROC_REGISTRALOG(P_NUMPED,
                         VNNUMPEDRCA,
                         NULL,
                         NULL,
                         NULL,
                         VNCODCLI,
                         VNCODUSUR,
                         NULL,
                         NULL,
                         VNINTEGRADORA,
                         P_CODRETORNOS,
                         '2',
                         'Erro17:' || VSMENSAGEMSALDORCA,
                         NULL);
      END IF;
    ELSE
      FOR REG_ITENS IN (SELECT CODPROD,
                               NUMSEQ,
                               QT,
                               NVL(CODFILIALRETIRA, VSCODFILIAL) CODFILIAL
                          FROM PCPEDI
                         WHERE NUMPED = P_NUMPED) 
      LOOP
        DELETE FROM PCPEDI
         WHERE NUMPED = P_NUMPED
           AND CODPROD = REG_ITENS.CODPROD
           AND NUMSEQ = REG_ITENS.NUMSEQ;

        IF VSPOSICAO = 'L' THEN
          UPDATE PCEST
             SET PCEST.QTRESERV   = NVL(PCEST.QTRESERV, 0) - NVL(REG_ITENS.QT, 0),
                 PCEST.DTULTSAIDA = TRUNC(SYSDATE)
           WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIAL
             AND PCEST.CODPROD = REG_ITENS.CODPROD;
        ELSE
          UPDATE PCEST
             SET PCEST.QTPENDENTE = NVL(PCEST.QTPENDENTE, 0) - NVL(REG_ITENS.QT, 0),
                 PCEST.DTULTSAIDA = TRUNC(SYSDATE)
           WHERE PCEST.CODFILIAL = REG_ITENS.CODFILIAL
             AND PCEST.CODPROD = REG_ITENS.CODPROD;
        END IF;
      END LOOP;

      DELETE FROM PCPEDC WHERE NUMPED = P_NUMPED;

      PROC_REGISTRALOG(P_NUMPED,
                       VNNUMPEDRCA,
                       NULL,
                       NULL,
                       NULL,
                       VNCODCLI,
                       VNCODUSUR,
                       NULL,
                       NULL,
                       VNINTEGRADORA,
                       P_CODRETORNOS,
                       '2',
                       'Erro18:' || VSMENSAGEM,
                       NULL);
    END IF;

    P_VALIDO := NVL(VBSALDORCA, TRUE);
  END PROC_VALIDADESCONTOFINACEIRO;

  PROCEDURE PROC_ENCONTRAPERLUC(P_REGITEM      IN T_ITEMPED,
                                P_REGPEDIDO    IN T_CABPED,
                                P_REGCLIENTE   IN T_CLIENTEPEDIDO,
                                P_REGPRODUTO   IN OUT T_PRODUTO,
                                P_REGPRECOS    IN OUT T_PRECOSETRIBUTACAO,
                                P_REGRCA       IN T_RCA,
                                P_REGREGIAO    IN T_REGIAOCLIENTE,
                                P_REGFILIAL    IN T_FILIAL,
                                P_REGPLPAG     IN T_PLANODEPAGAMENTO,
                                P_PERLUCSEMRED OUT NUMBER,
                                P_VLCUSTOFIN   OUT NUMBER,
                                P_MENSAGEM     OUT VARCHAR2) IS

    VNIVA             PCPEDI.IVA%TYPE;
    VNPBASERCA        PCPEDI.PBASERCA%TYPE;
    VBCALCULASTVALIDO BOOLEAN;
    VSUFFILIALNF      PCFILIAL.UF%TYPE;
    VBCODICMTABPF     BOOLEAN;
    VSMENSAGEM_ST     VARCHAR2(1000);
    VSMENSAGEM_COMISS VARCHAR2(1000);
    VNPERLUC          NUMBER;
    VNPERDESC         NUMBER;
    VNPVENDA         PCPEDI.PVENDA%TYPE;
    VNPTABELA        PCPEDI.PTABELA%TYPE;
    VNVLIPI          PCPEDI.VLIPI%TYPE;
    VNPERCIPI        PCPEDI.PERCIPI%TYPE;
    VNST             PCPEDI.ST%TYPE;
    VNBASEICST       PCPEDI.BASEICST%TYPE;
    VNPERCOM         PCPEDI.PERCOM%TYPE;
    VNPERFRETECMV    PCPEDI.PERFRETECMV%TYPE;
    VNCUSTOFINEST    PCPEDI.CUSTOFINEST%TYPE;
    VNTXVENDA        PCPEDI.TXVENDA%TYPE;
    VNPERDESCCUSTO   PCPEDI.PERDESCCUSTO%TYPE;
    VNCODICMTAB      PCPEDI.CODICMTAB%TYPE;
    VNVLCUSTOREAL    PCPEDI.VLCUSTOREAL%TYPE;
    VNVLCUSTOFIN     PCPEDI.VLCUSTOFIN%TYPE;
    VNVLDESCCUSTOCMV PCPEDI.VLDESCCUSTOCMV%TYPE;
    VSLETRACOMISS    PCPEDI.LETRACOMISS%TYPE;
    VICONT                NUMBER;
    VBUSAPCTABCOMISS      BOOLEAN;
    VBUSAPCCOMISSAOUSUR   BOOLEAN;
    VBUSAPCCOMISSAOPLPAG  BOOLEAN;
    VBUSAPCCOMISSAOREGIAO BOOLEAN;
    VBUSAPCCOMISSAOFILIAL BOOLEAN;
    VNCODCOMISS           PCORIGEMCOMIS.CODCOMIS%TYPE;
    VNCODROTINACOMISS     PCORIGEMCOMIS.CODROTINACOMIS%TYPE;
  BEGIN
    VNPVENDA   := P_REGITEM.PVENDA;
    VNPTABELA  := P_REGPRODUTO.PTABELA;
    VNPBASERCA := P_REGITEM.PBASERCA;

    BEGIN
      SELECT PCFILIAL.UF
        INTO VSUFFILIALNF
        FROM PCFILIAL
       WHERE PCFILIAL.CODIGO = NVL(P_REGCLIENTE.CODFILIALNF, P_REGPEDIDO.CODFILIAL);
    EXCEPTION
      WHEN OTHERS THEN
        VSUFFILIALNF := NULL;
    END;

    IF NVL(P_REGPRECOS.CODICMTABPF,0) = 0 THEN
      VBCODICMTABPF := TRUE;
    ELSE
      VBCODICMTABPF := FALSE;
    END IF;

    VNIVA := P_REGPRECOS.IVA;

    --50 parametros
    VBCALCULASTVALIDO := FUNCOESVENDAS.CALCULARIMPOSTOS(VNPVENDA,
                                                        VNPTABELA,
                                                        VNPBASERCA,
                                                        VNVLIPI,
                                                        VNPERCIPI,
                                                        NVL(P_REGPRODUTO.PERCIPIVENDA,0),
                                                        P_REGPEDIDO.PERCVENDA,
                                                        GREGPCCONSUM.TIPOCALCST,
                                                        GREGPCCONSUM.CALCSTPF,
                                                        P_REGPRECOS.MOSTRARPVENDASEMST,
                                                        GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                        P_REGCLIENTE.CALCULAST,
                                                        P_REGCLIENTE.IEENT,
                                                        P_REGCLIENTE.TIPOFJ,
                                                        P_REGPRECOS.PAUTA,
                                                        VNIVA,
                                                        P_REGPRECOS.ALIQICMS1,
                                                        P_REGPRECOS.ALIQICMS2,
                                                        P_REGPRECOS.PERCBASEREDST,
                                                        GREGPCCONSUM.NUMCASASDECVENDA, 0,
                                                        P_REGFILIAL.UF,
                                                        P_REGCLIENTE.ESTENT,
                                                        NVL(P_REGPRECOS.USAVALORULTENTBASEST, 'N'),
                                                        NVL(P_REGPRECOS.USAVALORULTENTBASEST2, 'N'),
                                                        P_REGPRECOS.VALORULTENT,
                                                        P_REGCLIENTE.ISENTOIPI,
                                                        0,
                                                        GREGPCCONSUM.CALCULARSTCOMIPI,
                                                        GREGPCCONSUM.TIPOCALCIPI,
                                                        P_REGCLIENTE.CODFILIALNF,
                                                        P_REGPEDIDO.CONDVENDA,
                                                        P_REGCLIENTE.CONTRIBUINTE,
                                                        VSUFFILIALNF,
                                                        P_REGPRODUTO.IMPORTADO,
                                                        P_REGFILIAL.CALCULARIPIVENDA,
                                                        P_REGPRODUTO.PERCIPIVENDATAB,
                                                        P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                        P_REGPRODUTO.VLPAUTAIPIVENDATAB,
                                                        P_REGPRODUTO.VLIPIPORKGVENDA,
                                                        P_REGPRODUTO.VLIPIPORKGVENDATAB,
                                                        P_REGPRODUTO.PESOBRUTO,
                                                        P_REGPRECOS.TIPOCALCULOGNRE,
                                                        P_REGCLIENTE.SIMPLESNACIONAL,
                                                        P_REGPRECOS.PERCREDPVENDASIMPLESNAC,
                                                        'N',
                                                        NULL,
                                                        VSMENSAGEM_ST,
                                                        VNST,
                                                        VNBASEICST,
                                                        GREGPCCONSUM.ACEITAPFCONTRIBUINTE,
                                                        P_REGPRECOS.CUSTONFSEMST,
                                                        P_REGPRECOS.USAPMCBASEST,
                                                        P_REGPRODUTO.PRECOMAXCONSUM,
                                                        P_REGCLIENTE.CONSUMIDORFINAL,
                                                        P_REGITEM.RETIRAIMP,
                                                        NVL(P_REGITEM.PVENDASEMIMPOSTO, 'N'),
                                                        P_REGPRECOS.AGREGARIPICALCULOST,
                                                        P_REGCLIENTE.UTILIZACALCULOSTMT,
                                                        P_REGCLIENTE.MARGEMMVA,
                                                        P_REGCLIENTE.PERCARGATRIBMEDIA,
                                                        P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                        P_REGPRECOS.VLULTENTMES,
                                                        P_REGPRECOS.PERCBASESTRJ);
    -- calcula o percentual de desconto
    VNPERDESC := FUNC_CALCULARPERDESCITEM(VNPTABELA, VNPVENDA, P_REGPEDIDO.INTEGRADORA);

    FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                              GREGPCCONSUM.APLICARINDICECMV,
                              GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                              NVL(GREGPCCONSUM.TXVENDA, 0),
                              P_REGCLIENTE.TIPOFJ,
                              P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                              P_REGCLIENTE.IEENT,
                              P_REGPRODUTO.FRETEESPECIAL,
                              P_REGREGIAO.PERFRETETERCEIROS,
                              P_REGREGIAO.PERFRETEESPECIAL,
                              P_REGPRECOS.CUSTOFIN,
                              P_REGPRECOS.CUSTOREAL,
                              P_REGPRECOS.PERDESCCUSTO,
                              P_REGPRECOS.CODICMTAB,
                              VBCODICMTABPF,
                              P_REGPRECOS.CODICMTABPF,
                              P_REGPEDIDO.PERCVENDA,
                              (VNPVENDA -
                              NVL(P_REGITEM.VLREDPVENDASIMPLESNA, 0)),
                              0,
                              VNST,
                              VNVLIPI,
                              0,
                              P_REGCLIENTE.CONTRIBUINTE,
                              0,
                              NVL(P_REGITEM.VLREDPVENDASIMPLESNA, 0),
                              P_REGCLIENTE.CONSUMIDORFINAL,
                              NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                              VNPERFRETECMV,
                              VNCUSTOFINEST,
                              VNTXVENDA,
                              VNPERDESCCUSTO,
                              VNCODICMTAB,
                              VNVLCUSTOREAL,
                              VNVLCUSTOFIN,
                              VNVLDESCCUSTOCMV);
    VNPERLUC := 0;
    IF NVL(VNPVENDA,0) <> 0 THEN
       VNPERLUC := ((VNPVENDA - VNVLCUSTOFIN) / VNPVENDA) * 100;
    END IF;
    -- busca percentual de comissao
    VSMENSAGEM_COMISS := NULL;
    SELECT COUNT(*) INTO VICONT FROM PCTABCOMISS P;

    IF VICONT <> 0 THEN
      VBUSAPCTABCOMISS := TRUE;
    ELSE
      VBUSAPCTABCOMISS := FALSE;
    END IF;

    SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOUSUR P;

    IF VICONT <> 0 THEN
      VBUSAPCCOMISSAOUSUR := TRUE;
    ELSE
      VBUSAPCCOMISSAOUSUR := FALSE;
    END IF;

    SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOPLPAG P;

    IF VICONT <> 0 THEN
      VBUSAPCCOMISSAOPLPAG := TRUE;
    ELSE
      VBUSAPCCOMISSAOPLPAG := FALSE;
    END IF;

    SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOREGIAO P;

    IF VICONT <> 0 THEN
      VBUSAPCCOMISSAOREGIAO := TRUE;
    ELSE
      VBUSAPCCOMISSAOREGIAO := FALSE;
    END IF;

    IF P_REGFILIAL.BROKER = 'S' THEN
      VBUSAPCCOMISSAOFILIAL := TRUE;
    ELSE
      VBUSAPCCOMISSAOFILIAL := FALSE;
    END IF;

    BEGIN
      VNPERCOM := FUNCOESVENDAS.DEFINIR_COMISSAO_ITEM_VENDIDO(P_REGREGIAO.NUMREGIAO,
                                                              VNPERLUC,
                                                              VNPERDESC,
                                                              VBUSAPCTABCOMISS,
                                                              VBUSAPCCOMISSAOUSUR,
                                                              VBUSAPCCOMISSAOPLPAG,
                                                              VBUSAPCCOMISSAOREGIAO,
                                                              VBUSAPCCOMISSAOFILIAL,
                                                              GREGPCCONSUM.USACOMISSAOPORRCA,
                                                              GREGPCCONSUM.ORDEMAVALIACAOCOMISSAORCA,
                                                              GREGPCCONSUM.USACOMISSAOPORCLIENTE,
                                                              GREGPCCONSUM.USACOMISSAOPORLINHAPROD,
                                                              GREGPCCONSUM.COMISSAORCATIPOVENDA,
                                                              P_REGRCA.TIPOVEND,
                                                              P_REGRCA.PERCENT,
                                                              P_REGRCA.PERCENT2,
                                                              P_REGPRODUTO.CODPROD,
                                                              P_REGPRODUTO.PCOMINT1,
                                                              P_REGPRODUTO.PCOMEXT1,
                                                              P_REGPRODUTO.PCOMREP1,
                                                              P_REGPRODUTO.CODLINHAPROD,
                                                              P_REGPRODUTO.TIPOCOMISSAO,
                                                              P_REGPRODUTO.CODEPTO,
                                                              P_REGPRODUTO.CODSEC,
                                                              P_REGPRODUTO.CLASSE,
                                                              P_REGPLPAG.TIPOVENDA,
                                                              P_REGPLPAG.CODPLPAG,
                                                              P_REGPEDIDO.DATA,
                                                              P_REGPEDIDO.CODFILIAL,
                                                              P_REGPEDIDO.CODUSUR,
                                                              P_REGFILIAL.CONSIDERARCOMISSAOZERO,
                                                              P_REGFILIAL.TIPOAVALIACAOCOMISSAO,
                                                              P_REGCLIENTE.PERCOMCLI,
                                                              P_REGCLIENTE.CODCLI,
                                                              P_REGITEM.CODDESCONTO,
                                                              VNCODCOMISS,
                                                              VNCODROTINACOMISS,
                                                              VSLETRACOMISS,
                                                              VSMENSAGEM_COMISS,
                                                              P_REGITEM.CODAUXILIAR,
                                                              P_REGPRECOS.PCOMINT1_EMB,
                                                              P_REGPRECOS.PCOMEXT1_EMB,
                                                              P_REGPRECOS.PCOMREP1_EMB,
                                                              P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM);
    EXCEPTION
      WHEN OTHERS THEN
        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                         P_REGPEDIDO.NUMPEDINT,
                         P_REGITEM.CODPROD,
                         P_REGITEM.CODAUXILIAR,
                         P_REGITEM.NUMSEQORIG,
                         P_REGPEDIDO.CODCLI,
                         P_REGPEDIDO.CODUSUR,
                         NULL,
                         NULL,
                         P_REGPEDIDO.INTEGRADORA,
                         94,
                         '3',
                         'Erro ao calcular comissão. ' || SQLCODE || ' ' ||
                         SQLERRM,
                         NULL);
    END;

    IF VSMENSAGEM_COMISS IS NOT NULL THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       P_REGITEM.CODPROD,
                       P_REGITEM.CODAUXILIAR,
                       P_REGITEM.NUMSEQORIG,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       94,
                       '3',
                       'Erro19:' || VSMENSAGEM_COMISS,
                       NULL);
    END IF;

    FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                              GREGPCCONSUM.APLICARINDICECMV,
                              GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                              NVL(GREGPCCONSUM.TXVENDA, 0),
                              P_REGCLIENTE.TIPOFJ,
                              P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                              P_REGCLIENTE.IEENT,
                              P_REGPRODUTO.FRETEESPECIAL,
                              P_REGREGIAO.PERFRETETERCEIROS,
                              P_REGREGIAO.PERFRETEESPECIAL,
                              P_REGPRECOS.CUSTOFIN,
                              P_REGPRECOS.CUSTOREAL,
                              P_REGPRECOS.PERDESCCUSTO,
                              P_REGPRECOS.CODICMTAB,
                              VBCODICMTABPF,
                              P_REGPRECOS.CODICMTABPF,
                              P_REGPEDIDO.PERCVENDA,
                              ROUND((VNPVENDA - NVL(P_REGITEM.VLREDPVENDASIMPLESNA, 0)), 2),
                              VNPERCOM,
                              VNST,
                              0,
                              0,
                              P_REGCLIENTE.CONTRIBUINTE,
                              0,
                              NVL(P_REGITEM.VLREDPVENDASIMPLESNA, 0),
                              P_REGCLIENTE.CONSUMIDORFINAL,
                              NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                              VNPERFRETECMV,
                              VNCUSTOFINEST,
                              VNTXVENDA,
                              VNPERDESCCUSTO,
                              VNCODICMTAB,
                              VNVLCUSTOREAL,
                              VNVLCUSTOFIN,
                              VNVLDESCCUSTOCMV);
    P_PERLUCSEMRED := 0;
    IF NVL(VNPVENDA,0) <> 0 THEN
       P_PERLUCSEMRED := ((VNPVENDA - VNVLCUSTOFIN) / VNPVENDA) * 100;
    END IF;
    P_VLCUSTOFIN := VNVLCUSTOFIN;
  EXCEPTION
    WHEN OTHERS THEN
      P_MENSAGEM := 'Erro ao encontrar percentual de lucratividade :' ||
                    SQLCODE || '-' || SQLERRM;
  END PROC_ENCONTRAPERLUC;


  FUNCTION FUNC_CALCULANOVOPVENDA(VNPVENDASEMIMP  IN NUMBER,
                                  P_REGPEDIDO     IN T_CABPED,
                                  P_REGPRODUTO    IN T_PRODUTO,
                                  P_REGPRECOS     IN T_PRECOSETRIBUTACAO,
                                  VNST            OUT PCPEDI.ST%TYPE,
                                  VNVLIPI         OUT PCPEDI.VLIPI%TYPE,
                                  VNIVA           OUT PCPEDI.IVA%TYPE,
                                  VNBCST          OUT PCPEDI.BASEICST%TYPE,
                                  VNPERCBASEREDST OUT PCPEDI.PERCBASEREDST%TYPE,
                                  VNPERCIPI       OUT PCPEDI.PERCIPI%TYPE)
  RETURN NUMBER IS
  VNBASE01                  NUMBER;
  VNBASE02                  NUMBER;
  VSCALCULARIPIVENDA        PCFILIAL.CALCULARIPIVENDA%TYPE;
  VNPERCREDPVENDASIMPLESNAC NUMBER;
  VNST1                     NUMBER;
  VNST2                     NUMBER;
  VNNOVOPVENDASIMPNASC      NUMBER;
  BEGIN
    VNVLIPI   := 0;
    VNPERCIPI := 0;

    SELECT PCFILIAL.CALCULARIPIVENDA
      INTO VSCALCULARIPIVENDA
      FROM PCFILIAL
     WHERE CODIGO = P_REGPEDIDO.CODFILIAL;

    IF (P_REGPRECOS.USAPMCBASEST = 'S') AND (P_REGPRODUTO.PRECOMAXCONSUM > 0) THEN
      VNBCST := (P_REGPRODUTO.PRECOMAXCONSUM * (P_REGPRECOS.PERCBASEREDST / 100));
      VNST1 := (VNBCST * (P_REGPRECOS.ALIQICMS1 / 100));
      VNST2 := (VNPVENDASEMIMP * (P_REGPRECOS.ALIQICMS2 / 100));
      VNST  := VNST1 - VNST2;

      VNNOVOPVENDASIMPNASC := VNPVENDASEMIMP + VNST;
    ELSE
      IF VSCALCULARIPIVENDA = 'N' THEN
        VNVLIPI := 0;
      ELSE
        IF P_REGPRODUTO.VLPAUTAIPIVENDA > 0 THEN
          VNVLIPI := P_REGPRODUTO.VLPAUTAIPIVENDA;
        ELSE
          IF P_REGPRODUTO.VLIPIPORKGVENDA > 0 THEN
            VNVLIPI := P_REGPRODUTO.PESOBRUTO * P_REGPRODUTO.VLIPIPORKGVENDA;
          ELSE
            IF P_REGPRODUTO.PERCIPIVENDA > 0 THEN
              VNVLIPI   := VNPVENDASEMIMP * (P_REGPRODUTO.PERCIPIVENDA / 100);
              VNPERCIPI := P_REGPRODUTO.PERCIPIVENDA;
            END IF;
          END IF;
        END IF;

        IF GREGPCCONSUM.TIPOCALCIPI = 'T2' THEN
          VNVLIPI := ROUND(VNVLIPI * 100) / 100;
        ELSIF GREGPCCONSUM.TIPOCALCIPI = 'A2' THEN
          VNVLIPI := ROUND(VNVLIPI, 2);
        ELSIF GREGPCCONSUM.TIPOCALCIPI = 'PV' THEN
          VNVLIPI := ROUND(VNVLIPI, GREGPCCONSUM.NUMCASASDECVENDA);
        END IF;
      END IF;

      VNBASE01 := VNPVENDASEMIMP;
      VNBASE02 := VNPVENDASEMIMP;

      IF GREGPCCONSUM.CALCULARSTCOMIPI = 'S' THEN
        VNBASE01 := VNPVENDASEMIMP + VNVLIPI;
      END IF;

      IF P_REGPRECOS.PERCBASEREDST = 0 THEN
        VNPERCBASEREDST := 100;
      ELSE
        VNPERCBASEREDST := P_REGPRECOS.PERCBASEREDST;
      END IF;

      IF P_REGPRECOS.PERCREDPVENDASIMPLESNAC = 0 THEN
        VNPERCREDPVENDASIMPLESNAC := 100;
      ELSE
        VNPERCREDPVENDASIMPLESNAC := P_REGPRECOS.PERCREDPVENDASIMPLESNAC;
      END IF;

      IF P_REGPRECOS.PAUTA = 0 THEN
        VNST1  := ((VNBASE01 * (1 + (((P_REGPRECOS.IVA / 100) *
                  (VNPERCREDPVENDASIMPLESNAC / 100))))) *
                  (VNPERCBASEREDST / 100)) * (P_REGPRECOS.ALIQICMS1 / 100);
        VNBCST := ((VNPVENDASEMIMP) *
                  (1 + (((P_REGPRECOS.IVA / 100) *
                  (VNPERCREDPVENDASIMPLESNAC / 100))))) *
                  (VNPERCBASEREDST / 100);
      ELSE
        VNST1  := P_REGPRECOS.PAUTA * (P_REGPRECOS.ALIQICMS1 / 100);
        VNBCST := (P_REGPRECOS.PAUTA * (VNPERCBASEREDST / 100));
      END IF;

      VNST2 := (VNBASE02 * (P_REGPRECOS.ALIQICMS2 / 100));
      VNST := VNST1 - VNST2;
      --Calcular ST - Truncar com 2 casas decimais
      IF GREGPCCONSUM.TIPOCALCST = 'T2' THEN
        VNST := TRUNC((VNST) * 100) / 100;
      ELSIF GREGPCCONSUM.TIPOCALCST = 'A2' THEN
        VNST := ROUND((VNST) * 100) / 100;
      ELSIF GREGPCCONSUM.TIPOCALCST = 'PV' THEN
        VNST := ROUND(VNST, GREGPCCONSUM.NUMCASASDECVENDA);
      END IF;

      IF VNST < 0 THEN
        VNST := 0;
      END IF;

      VNNOVOPVENDASIMPNASC := VNPVENDASEMIMP + VNST;

      IF VSCALCULARIPIVENDA = 'S' THEN
        VNNOVOPVENDASIMPNASC := VNNOVOPVENDASIMPNASC + VNVLIPI;
      END IF;

      VNNOVOPVENDASIMPNASC := ROUND(VNNOVOPVENDASIMPNASC, GREGPCCONSUM.NUMCASASDECVENDA);
    END IF;

    SELECT NVL(P_REGPRECOS.IVA, 0) *
           (DECODE(NVL(VNPERCREDPVENDASIMPLESNAC, 0), 0, 100, VNPERCREDPVENDASIMPLESNAC) / 100)
      INTO VNIVA
      FROM DUAL;

    RETURN(VNNOVOPVENDASIMPNASC);
  END FUNC_CALCULANOVOPVENDA;


  PROCEDURE PROC_ENCONTRAPVENDA(P_REGITEM    IN OUT T_ITEMPED,
                                P_REGPEDIDO  IN T_CABPED,
                                P_REGCLIENTE IN T_CLIENTEPEDIDO,
                                P_REGREGIAO  IN T_REGIAOCLIENTE,
                                P_REGRCA     IN T_RCA,
                                P_REGPRODUTO IN OUT T_PRODUTO,
                                P_REGPRECOS  IN OUT T_PRECOSETRIBUTACAO,
                                P_STPTABELA  OUT NUMBER, --usado para calculo de reducao do simples quando usa desc comercial
                                P_PERCDIF    OUT NUMBER, --diferença entre pvenda e ptabela
                                P_PERCDIF2   OUT NUMBER, --diferença entre ptabela e pbaserca
                                P_MENSAGEM   OUT VARCHAR2) IS

    VNPVENDASEMIMPOSTO        NUMBER;
    VSMENSAGEMPRECOSEMIMPOSTO VARCHAR2(1000);
    VSUFFILIAL                PCFILIAL.UF%TYPE;
    VBCALCULAPRECOSEMIMPOSTO  BOOLEAN;
    VNPBASERCA                PCPEDI.PBASERCA%TYPE;
    VNVLIPI                   PCPEDI.VLIPI%TYPE;
    VNPERCIPI                 PCPEDI.PERCIPI%TYPE;
    VSUFFILIALNF              PCFILIAL.UF%TYPE;
    VSCALCULARIPIVENDA        PCFILIAL.CALCULARIPIVENDA%TYPE;
    VNBASEICST                PCPEDI.BASEICST%TYPE;
    VNVLDIF                   NUMBER;
    VNPERCDIF                 NUMBER;
    VNPVENDA                  PCPEDI.PVENDA%TYPE;
    VNPTABELA                 PCPEDI.PTABELA%TYPE;
    VNPTABELASEMIMPOSTO       NUMBER;
    VNIVA                     PCPEDI.IVA%TYPE;
    VNPBASERCASEMIMPOSTO      NUMBER;
    VNVLDIF2                  NUMBER;
    VNPERCDIF2                NUMBER;
    VNNOVOPVENDA              NUMBER;
    VNNOVOPTABELA             NUMBER;
    VNNOVOPBASERCA            NUMBER;
    VNST                      PCPEDI.ST%TYPE;
    VNPERCBASEREDST           PCPEDI.PERCBASEREDST%TYPE;
  BEGIN
    IF P_REGPRECOS.MOSTRARPVENDASEMST = 'N' THEN
      VNPVENDA   := P_REGITEM.PVENDA;
      VNPTABELA  := P_REGPRODUTO.PTABELA;
      VNPBASERCA := P_REGITEM.PBASERCA;

      SELECT UF, PCFILIAL.CALCULARIPIVENDA
        INTO VSUFFILIAL, VSCALCULARIPIVENDA
        FROM PCFILIAL
       WHERE CODIGO = P_REGPEDIDO.CODFILIAL;

      SELECT UF
        INTO VSUFFILIALNF
        FROM PCFILIAL
       WHERE CODIGO = NVL(P_REGCLIENTE.CODFILIALNF, P_REGPEDIDO.CODFILIAL);

      VNIVA := P_REGPRECOS.IVA;
      VNVLDIF   := 0;
      VNPERCDIF := 0;

      IF NVL(P_REGITEM.PVENDASEMIMPOSTO, 'N') = 'N' THEN
        --Retirar impostos do preço de venda
        VBCALCULAPRECOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(P_REGPRODUTO.PERCIPIVENDA,0),
                                                                             P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                             P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                             VNPVENDA,
                                                                             P_REGPRECOS.PAUTA,
                                                                             P_REGPRODUTO.PESOBRUTO,
                                                                             P_REGPRECOS.PERCDIFALIQUOTAS,
                                                                             P_REGPRODUTO.PERCIPIVENDA,
                                                                             P_REGPRECOS.VALORULTENT,
                                                                             VNIVA,
                                                                             P_REGPRECOS.PERCBASEREDST,
                                                                             P_REGPRECOS.ALIQICMS1,
                                                                             P_REGPRECOS.ALIQICMS2,
                                                                             P_REGPRECOS.USAVALORULTENTBASEST,
                                                                             P_REGPRECOS.USAVALORULTENTBASEST2,
                                                                             VSUFFILIAL,
                                                                             P_REGCLIENTE.ESTENT,
                                                                             VNPVENDASEMIMPOSTO,
                                                                             VSMENSAGEMPRECOSEMIMPOSTO,
                                                                             P_REGPRECOS.USAPMCBASEST,
                                                                             P_REGPRODUTO.PRECOMAXCONSUM,
                                                                             P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                             P_REGPRECOS.VLULTENTMES);
        IF VSMENSAGEMPRECOSEMIMPOSTO IS NOT NULL THEN
          PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                           P_REGPEDIDO.NUMPEDINT,
                           P_REGITEM.CODPROD,
                           P_REGITEM.CODAUXILIAR,
                           P_REGITEM.NUMSEQORIG,
                           P_REGPEDIDO.CODCLI,
                           P_REGPEDIDO.CODUSUR,
                           NULL,
                           NULL,
                           P_REGPEDIDO.INTEGRADORA,
                           82,
                           '3',
                           'Erro ao calcular preço sem imposto' ||
                           VSMENSAGEMPRECOSEMIMPOSTO,
                           NULL);
        END IF;

        VNPVENDASEMIMPOSTO := ROUND(VNPVENDASEMIMPOSTO, GREGPCCONSUM.NUMCASASDECVENDA);
        --Retirar impostos do preço de tabela
        VBCALCULAPRECOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(P_REGPRODUTO.PERCIPIVENDA,0),
                                                                             P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                             P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                             VNPTABELA,
                                                                             P_REGPRECOS.PAUTA,
                                                                             P_REGPRODUTO.PESOBRUTO,
                                                                             P_REGPRECOS.PERCDIFALIQUOTAS,
                                                                             P_REGPRODUTO.PERCIPIVENDA,
                                                                             P_REGPRECOS.VALORULTENT,
                                                                             VNIVA,
                                                                             P_REGPRECOS.PERCBASEREDST,
                                                                             P_REGPRECOS.ALIQICMS1,
                                                                             P_REGPRECOS.ALIQICMS2,
                                                                             P_REGPRECOS.USAVALORULTENTBASEST,
                                                                             P_REGPRECOS.USAVALORULTENTBASEST2,
                                                                             VSUFFILIAL,
                                                                             P_REGCLIENTE.ESTENT,
                                                                             VNPTABELASEMIMPOSTO,
                                                                             VSMENSAGEMPRECOSEMIMPOSTO,
                                                                             P_REGPRECOS.USAPMCBASEST,
                                                                             P_REGPRODUTO.PRECOMAXCONSUM,
                                                                             P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                             P_REGPRECOS.VLULTENTMES);
        IF VSMENSAGEMPRECOSEMIMPOSTO IS NOT NULL THEN
          PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                           P_REGPEDIDO.NUMPEDINT,
                           P_REGITEM.CODPROD,
                           P_REGITEM.CODAUXILIAR,
                           P_REGITEM.NUMSEQORIG,
                           P_REGPEDIDO.CODCLI,
                           P_REGPEDIDO.CODUSUR,
                           NULL,
                           NULL,
                           P_REGPEDIDO.INTEGRADORA,
                           82,
                           '3',
                           'Erro ao calcular preço sem imposto' ||
                           VSMENSAGEMPRECOSEMIMPOSTO,
                           NULL);
        END IF;

        VNPTABELASEMIMPOSTO := ROUND(VNPTABELASEMIMPOSTO, GREGPCCONSUM.NUMCASASDECVENDA);
        --Retirar impostos do preço base para calculo de deb/cred de rca
        VBCALCULAPRECOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(P_REGPRODUTO.PERCIPIVENDA, 0),
                                                                             P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                                             P_REGPRODUTO.VLIPIPORKGVENDA,
                                                                             VNPBASERCA,
                                                                             P_REGPRECOS.PAUTA,
                                                                             P_REGPRODUTO.PESOBRUTO,
                                                                             P_REGPRECOS.PERCDIFALIQUOTAS,
                                                                             P_REGPRODUTO.PERCIPIVENDA,
                                                                             P_REGPRECOS.VALORULTENT,
                                                                             VNIVA,
                                                                             P_REGPRECOS.PERCBASEREDST,
                                                                             P_REGPRECOS.ALIQICMS1,
                                                                             P_REGPRECOS.ALIQICMS2,
                                                                             P_REGPRECOS.USAVALORULTENTBASEST,
                                                                             P_REGPRECOS.USAVALORULTENTBASEST2,
                                                                             VSUFFILIAL,
                                                                             P_REGCLIENTE.ESTENT,
                                                                             VNPBASERCASEMIMPOSTO,
                                                                             VSMENSAGEMPRECOSEMIMPOSTO,
                                                                             P_REGPRECOS.USAPMCBASEST,
                                                                             P_REGPRODUTO.PRECOMAXCONSUM,
                                                                             P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                             P_REGPRECOS.VLULTENTMES);
        IF VSMENSAGEMPRECOSEMIMPOSTO IS NOT NULL THEN
          PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                           P_REGPEDIDO.NUMPEDINT,
                           P_REGITEM.CODPROD,
                           P_REGITEM.CODAUXILIAR,
                           P_REGITEM.NUMSEQORIG,
                           P_REGPEDIDO.CODCLI,
                           P_REGPEDIDO.CODUSUR,
                           NULL,
                           NULL,
                           P_REGPEDIDO.INTEGRADORA,
                           82,
                           '3',
                           'Erro ao calcular preço sem imposto' ||
                           VSMENSAGEMPRECOSEMIMPOSTO,
                           NULL);
        END IF;

        VNPBASERCASEMIMPOSTO := ROUND(VNPBASERCASEMIMPOSTO, GREGPCCONSUM.NUMCASASDECVENDA);
      ELSE
        VNPVENDASEMIMPOSTO   := VNPVENDA;
        VNPTABELASEMIMPOSTO  := VNPTABELA;
        VNPBASERCASEMIMPOSTO := VNPBASERCA;
      END IF;

      --diferença pvenda com ptabela
      VNVLDIF := VNPTABELASEMIMPOSTO - VNPVENDASEMIMPOSTO;
      
      VNPERCDIF := 0;
      IF NVL(VNPTABELASEMIMPOSTO,0) <> 0 THEN
      VNPERCDIF := (VNVLDIF * 100) / VNPTABELASEMIMPOSTO;
      END IF;
      --diferença ptabela com pbaserca
      VNVLDIF2 := VNPTABELASEMIMPOSTO - VNPBASERCASEMIMPOSTO;
      
      VNPERCDIF2 := 0;
      IF NVL(VNPTABELASEMIMPOSTO,0) <> 0 THEN
         VNPERCDIF2 := (VNVLDIF2 * 100) / VNPTABELASEMIMPOSTO;
      END IF;

      --Calcular novo st para pvenda
      IF P_REGCLIENTE.SIMPLESNACIONAL = 'S' THEN
        IF P_REGPRECOS.PAUTA > 0 OR NVL(P_REGPRECOS.IVA, 0) > 0 OR
           (P_REGPRECOS.ALIQICMS1 > 0 OR P_REGPRECOS.ALIQICMS2 > 0) THEN
          VNNOVOPVENDA := FUNC_CALCULANOVOPVENDA(VNPVENDASEMIMPOSTO,
                                                 P_REGPEDIDO,
                                                 P_REGPRODUTO,
                                                 P_REGPRECOS,
                                                 VNST,
                                                 VNVLIPI,
                                                 VNIVA,
                                                 VNBASEICST,
                                                 VNPERCBASEREDST,
                                                 VNPERCIPI);
        END IF;
      END IF;
      --somar novo st ao pvenda
      P_REGITEM.PVENDA        := NVL(VNNOVOPVENDA, VNPVENDASEMIMPOSTO);
      P_REGITEM.ST            := NVL(VNST, 0);
      P_REGITEM.VLIPI         := NVL(VNVLIPI, 0);
      P_REGITEM.IVA           := NVL(VNIVA, 0);
      P_REGITEM.BASEICST      := NVL(VNBASEICST, 0);
      P_REGITEM.PERCBASEREDST := NVL(VNPERCBASEREDST, 0);
      P_REGITEM.PERCIPI       := NVL(VNPERCIPI, 0);

      VNIVA := P_REGPRECOS.IVA;
      --Calcular novo st para ptabela
      IF P_REGCLIENTE.SIMPLESNACIONAL = 'S' THEN
        IF P_REGPRECOS.PAUTA > 0 OR NVL(P_REGPRECOS.IVA, 0) > 0 OR
           (P_REGPRECOS.ALIQICMS1 > 0 OR P_REGPRECOS.ALIQICMS2 > 0) THEN
          VNNOVOPTABELA := FUNC_CALCULANOVOPVENDA(VNPTABELASEMIMPOSTO,
                                                  P_REGPEDIDO,
                                                  P_REGPRODUTO,
                                                  P_REGPRECOS,
                                                  VNST,
                                                  VNVLIPI,
                                                  VNIVA,
                                                  VNBASEICST,
                                                  VNPERCBASEREDST,
                                                  VNPERCIPI);
        END IF;
      END IF;
      --somar novo st ao ptabela
      P_REGPRODUTO.PTABELA := NVL(VNNOVOPTABELA, VNPTABELASEMIMPOSTO);
      P_STPTABELA          := VNST;
      VNIVA      := P_REGPRECOS.IVA;
      VNBASEICST := 0;
      --Calcular novo st para pbaserca
      IF P_REGCLIENTE.SIMPLESNACIONAL = 'S' THEN
        IF P_REGPRECOS.PAUTA > 0 OR NVL(P_REGPRECOS.IVA, 0) > 0 OR
           (P_REGPRECOS.ALIQICMS1 > 0 OR P_REGPRECOS.ALIQICMS2 > 0) THEN
          VNNOVOPBASERCA := FUNC_CALCULANOVOPVENDA(VNPBASERCASEMIMPOSTO,
                                                   P_REGPEDIDO,
                                                   P_REGPRODUTO,
                                                   P_REGPRECOS,
                                                   VNST,
                                                   VNVLIPI,
                                                   VNIVA,
                                                   VNBASEICST,
                                                   VNPERCBASEREDST,
                                                   VNPERCIPI);
        END IF;
      END IF;
      --somar novo st ao ptabela
      P_REGITEM.PBASERCA := NVL(VNNOVOPBASERCA, VNPBASERCASEMIMPOSTO);
    ELSE
      VNVLDIF   := 0;
      VNPERCDIF := 0;
      --diferença pvenda com ptabela
      VNVLDIF := P_REGPRODUTO.PTABELA - P_REGITEM.PVENDA;
      VNPERCDIF := 0;
      IF NVL(P_REGPRODUTO.PTABELA,0) <> 0 THEN
         VNPERCDIF := (VNVLDIF * 100) / P_REGPRODUTO.PTABELA;
      END IF;
      --diferença ptabela com pbaserca
      VNVLDIF2 := P_REGPRODUTO.PTABELA - P_REGITEM.PBASERCA;
      VNPERCDIF2 := 0;
      IF NVL(P_REGPRODUTO.PTABELA,0) <> 0 THEN
         VNPERCDIF2 := (VNVLDIF2 * 100) / P_REGPRODUTO.PTABELA;
      END IF;
    END IF;

    P_PERCDIF  := VNPERCDIF;
    P_PERCDIF2 := VNPERCDIF2;
  EXCEPTION
    WHEN OTHERS THEN
      P_MENSAGEM := 'Erro ao encontrar pvenda :' || SQLCODE || '-' || SQLERRM;
  END PROC_ENCONTRAPVENDA;


  PROCEDURE PROC_ENCONTRACMVCOMRED(P_REGITEM              IN OUT T_ITEMPED,
                                   P_REGPEDIDO            IN T_CABPED,
                                   P_REGCLIENTE           IN T_CLIENTEPEDIDO,
                                   P_REGREGIAO            IN T_REGIAOCLIENTE,
                                   P_REGRCA               IN T_RCA,
                                   P_REGFILIAL            IN T_FILIAL,
                                   P_REGPLPAG             IN T_PLANODEPAGAMENTO,
                                   P_REGPRODUTO           IN OUT T_PRODUTO,
                                   P_REGPRECOS            IN OUT T_PRECOSETRIBUTACAO,
                                   P_VLCUSTOFIMSEMIMPOSTO OUT NUMBER,
                                   P_MENSAGEM             OUT VARCHAR2) IS

    VSUFFILIAL              PCFILIAL.UF%TYPE;
    VSMENSAGEMREDSIMPLESNAC VARCHAR2(1000);
    VBCALCULAREDSIMPLESNAC  BOOLEAN;
    VBCALCULASTVALIDO       BOOLEAN;
    VNPBASERCA              PCPEDI.PBASERCA%TYPE;
    VNVLIPI                 PCPEDI.VLIPI%TYPE;
    VNPERCIPI               PCPEDI.PERCIPI%TYPE;
    VSUFFILIALNF            PCFILIAL.UF%TYPE;
    VSCALCULARIPIVENDA      PCFILIAL.CALCULARIPIVENDA%TYPE;
    VSMENSAGEM_ST           VARCHAR2(1000);
    VNSTPVENDA              PCPEDI.ST%TYPE;
    VNBASEICST              PCPEDI.BASEICST%TYPE;
    VNVLDIF                 NUMBER;
    VNPERCDIF               NUMBER;
    VNPVENDA                PCPEDI.PVENDA%TYPE;
    VNPTABELA               PCPEDI.PTABELA%TYPE;
    VNIVA                   PCPEDI.IVA%TYPE;
    VNPERDESC               NUMBER;
    VNPERLUC                NUMBER;
    VBCODICMTABPF           BOOLEAN;
    VSMENSAGEM_COMISS       VARCHAR2(1000);
    VNPERFRETECMV           PCPEDI.PERFRETECMV%TYPE;
    VNCUSTOFINEST           PCPEDI.CUSTOFINEST%TYPE;
    VNTXVENDA               PCPEDI.TXVENDA%TYPE;
    VNPERDESCCUSTO          PCPEDI.PERDESCCUSTO%TYPE;
    VNCODICMTAB             PCPEDI.CODICMTAB%TYPE;
    VNVLCUSTOREAL           PCPEDI.VLCUSTOREAL%TYPE;
    VNVLCUSTOFIN            PCPEDI.VLCUSTOFIN%TYPE;
    VNVLDESCCUSTOCMV        PCPEDI.VLDESCCUSTOCMV%TYPE;
    VNPERCOM                PCPEDI.PERCOM%TYPE;
    VSLETRACOMISS           PCPEDI.LETRACOMISS%TYPE;
    VNVLREDPVENDASIMPLESNA  NUMBER;
    VICONT                  NUMBER;
    VBUSAPCTABCOMISS        BOOLEAN;
    VBUSAPCCOMISSAOUSUR     BOOLEAN;
    VBUSAPCCOMISSAOPLPAG    BOOLEAN;
    VBUSAPCCOMISSAOREGIAO   BOOLEAN;
    VBUSAPCCOMISSAOFILIAL   BOOLEAN;
    VNCODCOMISS             PCORIGEMCOMIS.CODCOMIS%TYPE;
    VNCODROTINACOMISS       PCORIGEMCOMIS.CODROTINACOMIS%TYPE;

  BEGIN
    VNPVENDA   := P_REGITEM.PVENDA;
    VNPTABELA  := P_REGPRODUTO.PTABELA;
    VNPBASERCA := P_REGITEM.PBASERCA;

    SELECT UF, PCFILIAL.CALCULARIPIVENDA
      INTO VSUFFILIAL, VSCALCULARIPIVENDA
      FROM PCFILIAL
     WHERE CODIGO = P_REGPEDIDO.CODFILIAL;

    SELECT UF
      INTO VSUFFILIALNF
      FROM PCFILIAL
     WHERE CODIGO = NVL(P_REGCLIENTE.CODFILIALNF, P_REGPEDIDO.CODFILIAL);

    IF NVL(P_REGPRECOS.CODICMTABPF,0) = 0 THEN
      VBCODICMTABPF := TRUE;
    ELSE
      VBCODICMTABPF := FALSE;
    END IF;

    VNVLDIF := VNPTABELA - VNPVENDA;
    VNPERCDIF := 0;
    IF NVL(VNPTABELA,0) <> 0 THEN
       VNPERCDIF := (VNVLDIF * 100) / VNPTABELA;
    END IF;

    VBCALCULAREDSIMPLESNAC := FUNCOESVENDAS.CALCULARREDSIMPLESNAC(P_REGPRECOS.CUSTOFIN,
                                                                  P_REGPRECOS.CUSTONFSEMST,
                                                                  P_REGPRECOS.CUSTONFSEMSTGUIAULTENT,
                                                                  P_REGPRECOS.IVAULTENT,
                                                                  P_REGPRECOS.ALIQICMS1ULTENT,
                                                                  P_REGPRECOS.ALIQICMS2ULTENT,
                                                                  P_REGPRECOS.REDBASEIVAULTENT,
                                                                  P_REGPRECOS.PERCICMSFRETEFOBSTULTENT,
                                                                  P_REGPRECOS.VLFRETECONHECULTENT,
                                                                  P_REGPRECOS.PERCALIQEXTGUIAULTENT,
                                                                  P_REGPRECOS.VLSTULTENT,
                                                                  P_REGPRECOS.BASEICMSULTENT,
                                                                  P_REGPRECOS.VLSTGUIAULTENT,
                                                                  P_REGPRECOS.PERCREDPVENDASIMPLESNAC,
                                                                  GREGPCCONSUM.NUMCASASDECVENDA,
                                                                  NULL,
                                                                  NULL,
                                                                  NULL,
                                                                  NULL,
                                                                  VSMENSAGEMREDSIMPLESNAC,
                                                                  VNVLREDPVENDASIMPLESNA);

    VNPVENDA  := ROUND(VNPVENDA - NVL(VNVLREDPVENDASIMPLESNA, 0), GREGPCCONSUM.NUMCASASDECVENDA);
    VNPTABELA := ROUND(VNPTABELA - NVL(VNVLREDPVENDASIMPLESNA, 0), GREGPCCONSUM.NUMCASASDECVENDA);

    IF VNPERCDIF <> 0 THEN
      VNPVENDA := VNPTABELA - (VNPTABELA * (VNPERCDIF / 100));
    END IF;

    VNIVA := P_REGPRECOS.IVA;
    --Calcular novo st para pvenda
    --50 parametros
    VBCALCULASTVALIDO := FUNCOESVENDAS.CALCULARIMPOSTOS(VNPVENDA,
                                                        VNPTABELA,
                                                        VNPBASERCA,
                                                        VNVLIPI,
                                                        VNPERCIPI,
                                                        NVL(P_REGPRODUTO.PERCIPIVENDA, 0),
                                                        P_REGPEDIDO.PERCVENDA,
                                                        GREGPCCONSUM.TIPOCALCST,
                                                        GREGPCCONSUM.CALCSTPF,
                                                        P_REGPRECOS.MOSTRARPVENDASEMST,
                                                        GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                        P_REGCLIENTE.CALCULAST,
                                                        P_REGCLIENTE.IEENT,
                                                        P_REGCLIENTE.TIPOFJ,
                                                        P_REGPRECOS.PAUTA,
                                                        VNIVA,
                                                        P_REGPRECOS.ALIQICMS1,
                                                        P_REGPRECOS.ALIQICMS2,
                                                        P_REGPRECOS.PERCBASEREDST,
                                                        GREGPCCONSUM.NUMCASASDECVENDA,
                                                        0,
                                                        VSUFFILIAL,
                                                        P_REGCLIENTE.ESTENT,
                                                        NVL(P_REGPRECOS.USAVALORULTENTBASEST, 'N'),
                                                        NVL(P_REGPRECOS.USAVALORULTENTBASEST2,'N'),
                                                        P_REGPRECOS.VALORULTENT,
                                                        P_REGCLIENTE.ISENTOIPI,
                                                        0,
                                                        GREGPCCONSUM.CALCULARSTCOMIPI,
                                                        GREGPCCONSUM.TIPOCALCIPI,
                                                        P_REGCLIENTE.CODFILIALNF,
                                                        P_REGPEDIDO.CONDVENDA,
                                                        P_REGCLIENTE.CONTRIBUINTE,
                                                        VSUFFILIALNF,
                                                        P_REGPRODUTO.IMPORTADO,
                                                        VSCALCULARIPIVENDA,
                                                        P_REGPRODUTO.PERCIPIVENDATAB,
                                                        P_REGPRODUTO.VLPAUTAIPIVENDA,
                                                        P_REGPRODUTO.VLPAUTAIPIVENDATAB,
                                                        P_REGPRODUTO.VLIPIPORKGVENDA,
                                                        P_REGPRODUTO.VLIPIPORKGVENDATAB,
                                                        P_REGPRODUTO.PESOBRUTO,
                                                        P_REGPRECOS.TIPOCALCULOGNRE,
                                                        P_REGCLIENTE.SIMPLESNACIONAL,
                                                        P_REGPRECOS.PERCREDPVENDASIMPLESNAC,
                                                        'N',
                                                        NULL,
                                                        VSMENSAGEM_ST,
                                                        VNSTPVENDA,
                                                        VNBASEICST,
                                                        GREGPCCONSUM.ACEITAPFCONTRIBUINTE,
                                                        P_REGPRECOS.CUSTONFSEMST,
                                                        P_REGPRECOS.USAPMCBASEST,
                                                        P_REGPRODUTO.PRECOMAXCONSUM,
                                                        P_REGCLIENTE.CONSUMIDORFINAL,
                                                        'N',
                                                        P_REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                        P_REGPRECOS.VLULTENTMES);
    --calcular cmv do preço de venda reduzido
    -- calcula o percentual de desconto
    VNPERDESC := FUNC_CALCULARPERDESCITEM(VNPTABELA, VNPVENDA, P_REGPEDIDO.INTEGRADORA);

    FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                              GREGPCCONSUM.APLICARINDICECMV,
                              GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                              NVL(GREGPCCONSUM.TXVENDA, 0),
                              P_REGCLIENTE.TIPOFJ,
                              P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                              P_REGCLIENTE.IEENT,
                              P_REGPRODUTO.FRETEESPECIAL,
                              P_REGREGIAO.PERFRETETERCEIROS,
                              P_REGREGIAO.PERFRETEESPECIAL,
                              P_REGPRECOS.CUSTOFIN,
                              P_REGPRECOS.CUSTOREAL,
                              P_REGPRECOS.PERDESCCUSTO,
                              P_REGPRECOS.CODICMTAB,
                              VBCODICMTABPF,
                              P_REGPRECOS.CODICMTABPF,
                              P_REGPEDIDO.PERCVENDA,
                              VNPVENDA,
                              0,
                              VNSTPVENDA,
                              P_REGITEM.VLIPI,
                              0,
                              P_REGCLIENTE.CONTRIBUINTE,
                              0,
                              0,
                              P_REGCLIENTE.CONSUMIDORFINAL,
                              NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                              VNPERFRETECMV,
                              VNCUSTOFINEST,
                              VNTXVENDA,
                              VNPERDESCCUSTO,
                              VNCODICMTAB,
                              VNVLCUSTOREAL,
                              VNVLCUSTOFIN,
                              VNVLDESCCUSTOCMV);
    VNPERLUC := 0;
    IF NVL(VNPVENDA,0) <> 0 THEN
       VNPERLUC := ((VNPVENDA - VNVLCUSTOFIN) / VNPVENDA) * 100;
    END IF;

    -- busca percentual de comissao
    VSMENSAGEM_COMISS := NULL;

    SELECT COUNT(*) INTO VICONT FROM PCTABCOMISS P;

    IF VICONT <> 0 THEN
      VBUSAPCTABCOMISS := TRUE;
    ELSE
      VBUSAPCTABCOMISS := FALSE;
    END IF;

    SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOUSUR P;

    IF VICONT <> 0 THEN
      VBUSAPCCOMISSAOUSUR := TRUE;
    ELSE
      VBUSAPCCOMISSAOUSUR := FALSE;
    END IF;

    SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOPLPAG P;

    IF VICONT <> 0 THEN
      VBUSAPCCOMISSAOPLPAG := TRUE;
    ELSE
      VBUSAPCCOMISSAOPLPAG := FALSE;
    END IF;

    SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOREGIAO P;

    IF VICONT <> 0 THEN
      VBUSAPCCOMISSAOREGIAO := TRUE;
    ELSE
      VBUSAPCCOMISSAOREGIAO := FALSE;
    END IF;

    IF P_REGFILIAL.BROKER = 'S' THEN
      VBUSAPCCOMISSAOFILIAL := TRUE;
    ELSE
      VBUSAPCCOMISSAOFILIAL := FALSE;
    END IF;

    BEGIN
      VNPERCOM := FUNCOESVENDAS.DEFINIR_COMISSAO_ITEM_VENDIDO(P_REGREGIAO.NUMREGIAO,
                                                              VNPERLUC,
                                                              VNPERDESC,
                                                              VBUSAPCTABCOMISS,
                                                              VBUSAPCCOMISSAOUSUR,
                                                              VBUSAPCCOMISSAOPLPAG,
                                                              VBUSAPCCOMISSAOREGIAO,
                                                              VBUSAPCCOMISSAOFILIAL,
                                                              GREGPCCONSUM.USACOMISSAOPORRCA,
                                                              GREGPCCONSUM.ORDEMAVALIACAOCOMISSAORCA,
                                                              GREGPCCONSUM.USACOMISSAOPORCLIENTE,
                                                              GREGPCCONSUM.USACOMISSAOPORLINHAPROD,
                                                              GREGPCCONSUM.COMISSAORCATIPOVENDA,
                                                              P_REGRCA.TIPOVEND,
                                                              P_REGRCA.PERCENT,
                                                              P_REGRCA.PERCENT2,
                                                              P_REGPRODUTO.CODPROD,
                                                              P_REGPRODUTO.PCOMINT1,
                                                              P_REGPRODUTO.PCOMEXT1,
                                                              P_REGPRODUTO.PCOMREP1,
                                                              P_REGPRODUTO.CODLINHAPROD,
                                                              P_REGPRODUTO.TIPOCOMISSAO,
                                                              P_REGPRODUTO.CODEPTO,
                                                              P_REGPRODUTO.CODSEC,
                                                              P_REGPRODUTO.CLASSE,
                                                              P_REGPLPAG.TIPOVENDA,
                                                              P_REGPLPAG.CODPLPAG,
                                                              P_REGPEDIDO.DATA,
                                                              P_REGPEDIDO.CODFILIAL,
                                                              P_REGPEDIDO.CODUSUR,
                                                              P_REGFILIAL.CONSIDERARCOMISSAOZERO,
                                                              P_REGFILIAL.TIPOAVALIACAOCOMISSAO,
                                                              P_REGCLIENTE.PERCOMCLI,
                                                              P_REGCLIENTE.CODCLI,
                                                              P_REGITEM.CODDESCONTO,
                                                              VNCODCOMISS,
                                                              VNCODROTINACOMISS,
                                                              VSLETRACOMISS,
                                                              VSMENSAGEM_COMISS,
                                                              P_REGITEM.CODAUXILIAR,
                                                              P_REGPRECOS.PCOMINT1_EMB,
                                                              P_REGPRECOS.PCOMEXT1_EMB,
                                                              P_REGPRECOS.PCOMREP1_EMB,
                                                              P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM);
    EXCEPTION
      WHEN OTHERS THEN
        PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                         P_REGPEDIDO.NUMPEDINT,
                         P_REGITEM.CODPROD,
                         P_REGITEM.CODAUXILIAR,
                         P_REGITEM.NUMSEQORIG,
                         P_REGPEDIDO.CODCLI,
                         P_REGPEDIDO.CODUSUR,
                         NULL,
                         NULL,
                         P_REGPEDIDO.INTEGRADORA,
                         94,
                         '3',
                         'Erro ao calcular comissão. ' || SQLCODE || ' ' ||
                         SQLERRM,
                         NULL);
    END;

    IF VSMENSAGEM_COMISS IS NOT NULL THEN
      PROC_REGISTRALOG(P_REGPEDIDO.NUMPED,
                       P_REGPEDIDO.NUMPEDINT,
                       P_REGITEM.CODPROD,
                       P_REGITEM.CODAUXILIAR,
                       P_REGITEM.NUMSEQORIG,
                       P_REGPEDIDO.CODCLI,
                       P_REGPEDIDO.CODUSUR,
                       NULL,
                       NULL,
                       P_REGPEDIDO.INTEGRADORA,
                       94,
                       '3',
                       'Erro20:' || VSMENSAGEM_COMISS,
                       NULL);
    END IF;

    FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                              GREGPCCONSUM.APLICARINDICECMV,
                              GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                              NVL(GREGPCCONSUM.TXVENDA, 0),
                              P_REGCLIENTE.TIPOFJ,
                              P_REGCLIENTE.UTILIZAIESIMPLIFICADA,
                              P_REGCLIENTE.IEENT,
                              P_REGPRODUTO.FRETEESPECIAL,
                              P_REGREGIAO.PERFRETETERCEIROS,
                              P_REGREGIAO.PERFRETEESPECIAL,
                              P_REGPRECOS.CUSTOFIN,
                              P_REGPRECOS.CUSTOREAL,
                              P_REGPRECOS.PERDESCCUSTO,
                              P_REGPRECOS.CODICMTAB,
                              VBCODICMTABPF,
                              P_REGPRECOS.CODICMTABPF,
                              P_REGPEDIDO.PERCVENDA,
                              VNPVENDA,
                              VNPERCOM,
                              VNSTPVENDA,
                              0,
                              0,
                              P_REGCLIENTE.CONTRIBUINTE,
                              0,
                              0,
                              P_REGCLIENTE.CONSUMIDORFINAL,
                              NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                              VNPERFRETECMV,
                              VNCUSTOFINEST,
                              VNTXVENDA,
                              VNPERDESCCUSTO,
                              VNCODICMTAB,
                              VNVLCUSTOREAL,
                              VNVLCUSTOFIN,
                              VNVLDESCCUSTOCMV);

    -- fim calcular cmv do preço de venda sem impostos
    P_VLCUSTOFIMSEMIMPOSTO := VNVLCUSTOFIN;
  EXCEPTION
    WHEN OTHERS THEN
      P_MENSAGEM := 'Erro ao encontrar pvenda :' || SQLCODE || '-' || SQLERRM;
      P_REGITEM.CODRETORNOS := P_REGITEM.CODRETORNOS || ';' || 116;
  END PROC_ENCONTRACMVCOMRED;


  PROCEDURE PROC_REBAIXARCMV(P_NUMPED    IN NUMBER,
                             P_DATA      IN DATE,
                             P_CODFILIAL IN VARCHAR2) IS
    VBUTILIZOUVERBA BOOLEAN;
  BEGIN
    FOR REG_ITENS IN (SELECT PCPEDI.CODPROD, PCPEDI.QT, PCPEDI.NUMSEQ
                        FROM PCPEDI
                       WHERE NUMPED = P_NUMPED) LOOP

      VBUTILIZOUVERBA := FALSE;

      FOR REG IN (SELECT PCVERBA.NUMVERBA,
                         PCVERBA.DTEMISSAO,
                         PCVERBA.DTVENC,
                         PCVERBA.CODCONTA,
                         (SELECT SUM((NVL(PCPEDI.VLVERBACMV, 0) * NVL(PCPEDI.QT, 0)))
                            FROM PCPEDI, PCPEDC
                           WHERE PCPEDC.DATA BETWEEN
                                 PCAPLICVERBAI.DTINICIOVIGENCIA AND
                                 PCAPLICVERBAI.DTFIMVIGENCIA
                             AND PCPEDC.DTCANCEL IS NULL
                             AND PCPEDC.CONDVENDA <> 4
                             AND PCPEDC.POSICAO <> 'C'
                             AND PCPEDC.POSICAO NOT IN ('P', 'B', 'C')
                             AND PCPEDI.NUMPED = PCPEDC.NUMPED
                             AND PCPEDI.NUMVERBAREBCMV = PCVERBA.NUMVERBA
                             AND PCPEDI.CODPROD = PCAPLICVERBAI.CODPROD) VLVERBAUTILIZ,
                         PCAPLICVERBAI.VLAPLIC,
                         DECODE(NVL(PCAPLICVERBAI.VLAPLICUNITARIO,0), 0,
                                (DECODE(NVL(PCAPLICVERBAI.QTVENDA,0), 0, 0, NVL(PCAPLICVERBAI.VLAPLIC,0) / PCAPLICVERBAI.QTVENDA)),
                                PCAPLICVERBAI.VLAPLICUNITARIO) VLVERBA_ITEM,
                         PCAPLICVERBAI.VLAPLICUNITARIO
                    FROM PCVERBA, PCAPLICVERBAI
                   WHERE P_DATA BETWEEN PCAPLICVERBAI.DTINICIOVIGENCIA AND
                         PCAPLICVERBAI.DTFIMVIGENCIA
                     AND PCVERBA.NUMVERBA = PCAPLICVERBAI.NUMVERBA
                     AND PCAPLICVERBAI.CODPROD = REG_ITENS.CODPROD
                     AND PCAPLICVERBAI.CODFILIAL = P_CODFILIAL
                     AND PCVERBA.DTAPURACAO IS NULL) LOOP

        IF NVL(REG.NUMVERBA, 0) <> 0 AND VBUTILIZOUVERBA = FALSE THEN
          --Verba a apurar
          IF REG.CODCONTA = GREGPCCONSUM.CODCONTAREBAIXACMVAAPURAR THEN
            UPDATE PCPEDI
               SET VLCUSTOFIN     = NVL(VLCUSTOFIN, 0) - NVL(REG.VLAPLICUNITARIO, 0),
                   VLCUSTOREAL    = NVL(VLCUSTOREAL, 0) - NVL(REG.VLAPLICUNITARIO, 0),
                   VLVERBACMV     = NVL(REG.VLAPLICUNITARIO, 0),
                   NUMVERBAREBCMV = REG.NUMVERBA
             WHERE NUMPED = P_NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;

            VBUTILIZOUVERBA := TRUE;
            -- Verba valor definido
          ELSIF REG.CODCONTA = GREGPCCONSUM.CODCONTAREBAIXACMV THEN
            IF ROUND(NVL(REG.VLVERBAUTILIZ, 0), 2) <
               ROUND(NVL(REG.VLAPLIC, 0), 2) THEN
              FOR REG_VERBA IN (SELECT NUMVERBA
                                  FROM PCAPLICVERBAI
                                 WHERE NUMVERBA = REG.NUMVERBA
                                   FOR UPDATE) LOOP
                EXIT;
              END LOOP;

              IF ROUND((REG_ITENS.QT * NVL(REG.VLVERBA_ITEM, 0)), 2) < ROUND((NVL(REG.VLAPLIC, 0) - NVL(REG.VLVERBAUTILIZ, 0)), 2) THEN
                UPDATE PCPEDI
                   SET VLCUSTOREAL    = NVL(VLCUSTOREAL, 0) - NVL(REG.VLVERBA_ITEM, 0),
                       VLCUSTOFIN     = NVL(VLCUSTOFIN, 0) - NVL(REG.VLVERBA_ITEM, 0),
                       VLVERBACMV     = NVL(REG.VLVERBA_ITEM, 0),
                       NUMVERBAREBCMV = REG.NUMVERBA
                 WHERE NUMPED = P_NUMPED
                   AND CODPROD = REG_ITENS.CODPROD
                   AND NUMSEQ = REG_ITENS.NUMSEQ;

                VBUTILIZOUVERBA := TRUE;
              ELSE
                REG.VLVERBA_ITEM := 0;
                IF NVL(REG_ITENS.QT,0) <> 0 THEN
                   REG.VLVERBA_ITEM := ROUND((ROUND((NVL(REG.VLAPLIC, 0) - NVL(REG.VLVERBAUTILIZ, 0)), 2) / REG_ITENS.QT), 2);
                END IF;  

                UPDATE PCPEDI
                   SET VLCUSTOREAL    = NVL(VLCUSTOREAL, 0) - NVL(REG.VLVERBA_ITEM, 0),
                       VLCUSTOFIN     = NVL(VLCUSTOFIN, 0) - NVL(REG.VLVERBA_ITEM, 0),
                       VLVERBACMV     = NVL(REG.VLVERBA_ITEM, 0),
                       NUMVERBAREBCMV = REG.NUMVERBA
                 WHERE NUMPED = P_NUMPED
                   AND CODPROD = REG_ITENS.CODPROD
                   AND NUMSEQ = REG_ITENS.NUMSEQ;

                VBUTILIZOUVERBA := TRUE;
              END IF;
            END IF;
          END IF;
        END IF;
      END LOOP;
    END LOOP;
  END PROC_REBAIXARCMV;


  PROCEDURE PROC_DIVIDE_NUMITENSNFE(P_NUMPED         IN PCPEDC.NUMPED%TYPE,
                                    P_TIPOINTEGRACAO IN PCPEDCTEMP.TIPOINTEGRACAO%TYPE,
                                    P_NUMPEDINT      IN PCPEDC.NUMPEDRCA%TYPE,
                                    P_CODUSUR        IN PCPEDC.CODUSUR%TYPE,
                                    P_CODCLI         IN PCPEDC.CODCLI%TYPE,
                                    REGFILIAL        IN T_FILIAL,
                                    P_MENSAGEM       OUT VARCHAR2,
                                    P_VALIDO         OUT BOOLEAN
                                    ) IS
    VNPROXNUMPED     PCUSUARI.PROXNUMPED%TYPE;
    VNNUMSEQNOVOPED  NUMBER;
    VNVLTABELA       PCPEDC.VLTABELA%TYPE;
    VNVLATEND        PCPEDC.VLATEND%TYPE;
    VNVLTOTAL        PCPEDC.VLTOTAL%TYPE;
    VNVLCUSTOFIN     PCPEDC.VLCUSTOFIN%TYPE;
    VNVLCUSTOREAL    PCPEDC.VLCUSTOREAL%TYPE;
    VNVLCUSTOREP     PCPEDC.VLCUSTOREP%TYPE;
    VNVLCUSTOCONT    PCPEDC.VLCUSTOCONT%TYPE;
    VNTOTPESO        PCPEDC.TOTPESO%TYPE;
    VNTOTVOLUME      PCPEDC.TOTVOLUME%TYPE;
    VNNUMITENS       PCPEDC.NUMITENS%TYPE;
    VNNUMPED         PCPEDC.NUMPED%TYPE;
    VNPERDESCPED     NUMBER;
    VIAUX            NUMBER;
    VBVALIDO         BOOLEAN;
  BEGIN
    P_VALIDO := FALSE;

    VNNUMSEQNOVOPED := 0;

    FOR REG_PED IN (SELECT NUMPED,
                           NUMITENS,
                           NVL(REGFILIAL.NUMMAXITENSNFE, 400) NUMMAXITENSNFE
                      FROM PCPEDC
                     WHERE P_TIPOINTEGRACAO = 'R'
                       AND NUMPEDRCA = P_NUMPEDINT
                       AND PCPEDC.CODUSUR = P_CODUSUR
                       AND PCPEDC.CODCLI = P_CODCLI
                       AND PCPEDC.DATA = TRUNC(SYSDATE)
                       AND PCPEDC.NUMITENS >
                           NVL(REGFILIAL.NUMMAXITENSNFE, 400)
                    UNION
                    SELECT NUMPED,
                           NUMITENS,
                           NVL(REGFILIAL.NUMMAXITENSNFE, 400) NUMMAXITENSNFE
                      FROM PCPEDC
                     WHERE P_TIPOINTEGRACAO = 'W'
                       AND NUMPEDWEB = P_NUMPEDINT
                       AND PCPEDC.CODUSUR = P_CODUSUR
                       AND PCPEDC.CODCLI = P_CODCLI
                       AND PCPEDC.DATA = TRUNC(SYSDATE)
                       AND PCPEDC.NUMITENS >
                           NVL(REGFILIAL.NUMMAXITENSNFE, 400)
                    UNION
                    SELECT NUMPED,
                           NUMITENS,
                           NVL(REGFILIAL.NUMMAXITENSNFE, 400) NUMMAXITENSNFE
                      FROM PCPEDC
                     WHERE P_TIPOINTEGRACAO = 'C'
                       AND NUMPEDCLI = P_NUMPEDINT
                       AND PCPEDC.CODUSUR = P_CODUSUR
                       AND PCPEDC.CODCLI = P_CODCLI
                       AND PCPEDC.DATA = TRUNC(SYSDATE)
                       AND PCPEDC.NUMITENS >
                           NVL(REGFILIAL.NUMMAXITENSNFE, 400)) LOOP
      BEGIN
         VNPROXNUMPED := IMPORTAR_PEDIDO_PROXNUMPED(P_CODUSUR);
      END;

      VIAUX           := 0;
      VNNUMSEQNOVOPED := 0;

      FOR REG_ITENS IN (SELECT CODPROD, CODAUXILIAR, NUMSEQ
                          FROM PCPEDI
                         WHERE NUMPED = REG_PED.NUMPED) LOOP
        VIAUX    := VIAUX + 1;
        VBVALIDO := TRUE;

        IF VIAUX > REG_PED.NUMMAXITENSNFE THEN
          --insere no novo pedido
          VNNUMSEQNOVOPED := VNNUMSEQNOVOPED + 1;

          BEGIN
            INSERT INTO PCPEDI
              (CODCLI, --1
               CODICMTAB, --2
               CODPROD, --3
               CODST, --4
               CODUSUR, --5
               DATA, --6
               NUMPED, --7
               NUMSEQ, --8
               PERCOM, --9
               PERDESC, --10
               POSICAO, --11
               PTABELA, --12
               PVENDA, --13
               QT, --14
               QTFALTA, --15
               ST, --16
               STCLIENTEGNRE, --17
               VLCUSTOCONT, --18
               VLCUSTOFIN, --19
               VLCUSTOREAL, --20
               VLCUSTOREP, --21
               PBASERCA, --22
               PVENDABASE, --23
               IVA, --24
               PAUTA, --25
               ALIQICMS1, --26
               ALIQICMS2, --27
               PERCBASEREDST, --28
               PERCBASEREDSTFONTE, --29
               BASEICST, --30
               PERFRETECMV, --31
               CUSTOFINEST, --32
               TXVENDA, --33
               PERDESCCUSTO, --34
               VLDESCCUSTOCMV, --35
               LETRACOMISS, --36
               VLIPI, --37
               PERCIPI, --38
               VLDESCSUFRAMA, --39
               VLDESCICMISENCAO, --40
               PERDESCISENTOICMS, --41
               VLVERBACMV, --42
               PVENDA1, --43
               PERCDESCPIS, --44
               PERCDESCCOFINS, --45
               VLDESCREDUCAOPIS, --46
               VLDESCREDUCAOCOFINS, --47
               CODAUXILIAR, --48
               QTPECAS, --49
               QTCX, --50
               VLREPASSE, --51
               VLBONIFIC, --52
               PERBONIFIC, --53
               VLOUTROS, --54
               PERDESCCOM, --55
               VLDESCCOM, --56
               QTUNITEMB, --57
               VLREDPVENDASIMPLESNA, --58
               VLREDCMVSIMPLESNAC, --59
               CODFILIALRETIRA, --60
               PORIGINAL, --61
               PRECOMAXCONSUM, --62
               DESCPRECOFAB, --63
               POLITICAPRIORITARIA, --64
               CODCOMBO, --65
               MOVIMENTACONTACORRENTERCA, --66
               PVENDAANTERIOR, --67
               ROTINALANC, --68
               CODDESCONTO, --69
               PERCDESCABATIMENTO, --70
               GERAGNRE_CNPJCLIENTE, --71
               SUGESTAO, --72
               TIPOENTREGA, --73
               PERCOM2, --74
               PERCOM3, --75
               PERCOM4, --76
               NUMCAR, --77
               PERCDIFALIQUOTAS, --78
               BASEDIFALIQUOTAS, --79
               VLDIFALIQUOTAS, --80
               NUMAPLIC, --81
               IDVENDA --82
              ,VLFECP --33
              ,VLBASEFCPST --34
              ,ALIQFCP -- 35
              ,ALIQICMSFECP -- 36
              ,UTILIZOUMOTORCALCULO --37
               )
              SELECT CODCLI, --1
                     CODICMTAB, --2
                     CODPROD, --3
                     CODST, --4
                     CODUSUR, --5
                     DATA, --6
                     VNPROXNUMPED, --7
                     VNNUMSEQNOVOPED, --8
                     PERCOM, --9
                     PERDESC, --10
                     POSICAO, --11
                     PTABELA, --12
                     PVENDA, --13
                     QT, --14
                     QTFALTA, --15
                     ST, --16
                     STCLIENTEGNRE, --17
                     VLCUSTOCONT, --18
                     VLCUSTOFIN, --19
                     VLCUSTOREAL, --20
                     VLCUSTOREP, --21
                     PBASERCA, --22
                     PVENDABASE, --23
                     IVA, --24
                     PAUTA, --25
                     ALIQICMS1, --26
                     ALIQICMS2, --27
                     PERCBASEREDST, --28
                     PERCBASEREDSTFONTE, --29
                     BASEICST, --30
                     PERFRETECMV, --31
                     CUSTOFINEST, --32
                     TXVENDA, --33
                     PERDESCCUSTO, --34
                     VLDESCCUSTOCMV, --35
                     LETRACOMISS, --36
                     VLIPI, --37
                     PERCIPI, --38
                     VLDESCSUFRAMA, --39
                     VLDESCICMISENCAO, --40
                     PERDESCISENTOICMS, --41
                     VLVERBACMV, --42
                     PVENDA1, --43
                     PERCDESCPIS, --44
                     PERCDESCCOFINS, --45
                     VLDESCREDUCAOPIS, --46
                     VLDESCREDUCAOCOFINS, --47
                     CODAUXILIAR, --48
                     QTPECAS, --49
                     QTCX, --50
                     VLREPASSE, --51
                     VLBONIFIC, --52
                     PERBONIFIC, --53
                     VLOUTROS, --54
                     PERDESCCOM, --55
                     VLDESCCOM, --56
                     QTUNITEMB, --57
                     VLREDPVENDASIMPLESNA, --58
                     VLREDCMVSIMPLESNAC, --59
                     CODFILIALRETIRA, --60
                     PORIGINAL, --61
                     PRECOMAXCONSUM, --62
                     DESCPRECOFAB, --63
                     POLITICAPRIORITARIA, --64
                     CODCOMBO, --65
                     MOVIMENTACONTACORRENTERCA, --66
                     PVENDAANTERIOR, --67
                     ROTINALANC, --68
                     CODDESCONTO, --69
                     PERCDESCABATIMENTO, --70
                     GERAGNRE_CNPJCLIENTE, --71
                     SUGESTAO, --72
                     TIPOENTREGA, --73
                     PERCOM2, --74
                     PERCOM3, --75
                     PERCOM4, --76
                     NUMCAR, --77
                     PERCDIFALIQUOTAS, --78
                     BASEDIFALIQUOTAS, --79
                     VLDIFALIQUOTAS, --80
                     NUMAPLIC, --81
                     IDVENDA --82
                    ,VLFECP --33
                    ,VLBASEFCPST --34 
                    ,ALIQFCP --35
                    ,ALIQICMSFECP --36
                    ,UTILIZOUMOTORCALCULO --37
                FROM PCPEDI
               WHERE NUMPED = REG_PED.NUMPED
                 AND CODPROD = REG_ITENS.CODPROD
                 AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao inserir item do novo pedido na pcpedi : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            INSERT INTO PCORIGEMPRECO
              (NUMPED, --1
               TIPOBROKER, --2
               CODPROD, --3
               NUMSEQ, --4
               USATRIBUTPORUF, --5
               ORIGEMPRECO, --6
               COLUNAPRECO, --7
               TIPOFRETE, --8
               PERCFRETE, --9
               CODAUTORIZACAO, --10
               PERCDESCAUTOR, --11
               PERCACRESCPF, --12
               PERCRAMOATIV, --13
               TIPODESCFLEX, --14
               CODDESCFLEX, --15
               CODDESCVOLUME, --16
               PERCDESCVOLUME, --17
               CODDESCPTABELA, --18
               CODDESCVOLPTABELA, --19
               PERCDESCPTABELA, --20
               PERCDESCFLEX, --21
               CODPRECOFIXO, --22
               FATORPRECO, --23
               PORIGINAL, --24
               DTINICIOAUTOR, --25
               DTFIMAUTOR, --26
               DTINICIODESCFLEX, --27
               DTFIMDESCFLEX, --28
               DTINICIODESCVOLUME, --29
               DTFIMDESCVOLUME, --30
               DTINICIODESCPTABELA, --31
               DTFIMDESCPTABELA, --32
               DTINICIOOFERTA, --33
               DTFIMOFERTA, --34
               PERCPLPAG, --35
               PERCACRESCBALCAO, --36
               QTMINATACADO, --37
               VLST, --38
               VLIPI, --39
               VLSUFRAMA, --40
               VLDESCICMS, --41
               ORIGEMPED, --42
               INICIOINTERVALO, --43
               FIMINTERVALO, --44
               DATA, --45
               CODEMITENTE, --46
               CODFILIAL, --47
               CODFILIALNF, --48
               INICIOINTERVALOAUTORI, --49
               FIMINTERVALOAUTORI, --50
               NUMREGIAO, --51
               PERCDESCPIS, --52
               PERCDESCCOFINS, --53
               VLDESCREDUCAOPIS, --54
               VLDESCREDUCAOCOFINS --55
               ,VLFECP --56
               )
              SELECT VNPROXNUMPED, --1
                     TIPOBROKER, --2
                     CODPROD, --3
                     VNNUMSEQNOVOPED, --4
                     USATRIBUTPORUF, --5
                     ORIGEMPRECO, --6
                     COLUNAPRECO, --7
                     TIPOFRETE, --8
                     PERCFRETE, --9
                     CODAUTORIZACAO, --10
                     PERCDESCAUTOR, --11
                     PERCACRESCPF, --12
                     PERCRAMOATIV, --13
                     TIPODESCFLEX, --14
                     CODDESCFLEX, --15
                     CODDESCVOLUME, --16
                     PERCDESCVOLUME, --17
                     CODDESCPTABELA, --18
                     CODDESCVOLPTABELA, --19
                     PERCDESCPTABELA, --20
                     PERCDESCFLEX, --21
                     CODPRECOFIXO, --22
                     FATORPRECO, --23
                     PORIGINAL, --24
                     DTINICIOAUTOR, --25
                     DTFIMAUTOR, --26
                     DTINICIODESCFLEX, --27
                     DTFIMDESCFLEX, --28
                     DTINICIODESCVOLUME, --29
                     DTFIMDESCVOLUME, --30
                     DTINICIODESCPTABELA, --31
                     DTFIMDESCPTABELA, --32
                     DTINICIOOFERTA, --33
                     DTFIMOFERTA, --34
                     PERCPLPAG, --35
                     PERCACRESCBALCAO, --36
                     QTMINATACADO, --37
                     VLST, --38
                     VLIPI, --39
                     VLSUFRAMA, --40
                     VLDESCICMS, --41
                     ORIGEMPED, --42
                     INICIOINTERVALO, --43
                     FIMINTERVALO, --44
                     DATA, --45
                     CODEMITENTE, --46
                     CODFILIAL, --47
                     CODFILIALNF, --48
                     INICIOINTERVALOAUTORI, --49
                     FIMINTERVALOAUTORI, --50
                     NUMREGIAO, --51
                     PERCDESCPIS, --52
                     PERCDESCCOFINS, --53
                     VLDESCREDUCAOPIS, --54
                     VLDESCREDUCAOCOFINS --55
                     ,VLFECP --56
                FROM PCORIGEMPRECO P
               WHERE NUMPED = REG_PED.NUMPED
                 AND CODPROD = REG_ITENS.CODPROD
                 AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao inserir item do novo pedido na pcorigempreco : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            INSERT INTO PCORIGEMCOMIS
              (NUMPED, -- 1
               ORIGEMPED, -- 2
               CODPROD, -- 3
               CODAUXILIAR, -- 4
               NUMSEQ, -- 5
               CODFILIAL, -- 6
               NUMREGIAO, -- 7
               PERCOM, -- 8
               PERDESC, -- 9
               CODUSUR, -- 10
               CODCLI, -- 11
               CODCOB, -- 12
               CODPLPAG, -- 13
               CODROTINACOMIS, -- 14
               CODCOMIS, -- 15
               TIPOCOMISSAO, -- 16
               TIPOVEND, -- 17
               TIPOVENDA, -- 18
               CODLINHAPROD, -- 19
               TIPOAVALIACAOCOMISSAO, -- 20
               ORDEMAVALIACAOCOMISSAORCA, -- 21
               USACOMISSAOPORRCA, -- 22
               USACOMISSAOPORCLIENTE, -- 23
               USACOMISSAOPORLINHAPROD, -- 24
               COMISSAORCATIPOVENDA, -- 25
               CONSIDERARCOMISSAOZERO -- 26
               )
              SELECT VNPROXNUMPED, -- 1
                     ORIGEMPED, -- 2
                     CODPROD, -- 3
                     CODAUXILIAR, -- 4
                     VNNUMSEQNOVOPED, -- 5
                     CODFILIAL, -- 6
                     NUMREGIAO, -- 7
                     PERCOM, -- 8
                     PERDESC, -- 9
                     CODUSUR, -- 10
                     CODCLI, -- 11
                     CODCOB, -- 12
                     CODPLPAG, -- 13
                     CODROTINACOMIS, -- 14
                     CODCOMIS, -- 15
                     TIPOCOMISSAO, -- 16
                     TIPOVEND, -- 17
                     TIPOVENDA, -- 18
                     CODLINHAPROD, -- 19
                     TIPOAVALIACAOCOMISSAO, -- 20
                     ORDEMAVALIACAOCOMISSAORCA, -- 21
                     USACOMISSAOPORRCA, -- 22
                     USACOMISSAOPORCLIENTE, -- 23
                     USACOMISSAOPORLINHAPROD, -- 24
                     COMISSAORCATIPOVENDA, -- 25
                     CONSIDERARCOMISSAOZERO -- 26
                FROM PCORIGEMCOMIS
               WHERE NUMPED = REG_PED.NUMPED
                 AND CODPROD = REG_ITENS.CODPROD
                 AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao inserir item do novo pedido na pcorigemcomis : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            INSERT INTO PCORIGEMDESC
              (NUMPED, --1
               ORIGEMPED, --2
               CODPROD, --3
               CODAUXILIAR, --4
               NUMSEQ, --5
               PTABELA, --6
               PEMBALAGEM, --7
               PERDESC, --8
               PERCBASERCA, --9
               PERCDESCPCATIVI, --10
               PERTXFIM, --11
               PERACRESPF, --12
               TIPODESC, --13
               CODROTINADESC, --14
               CODPOLITICADESC, --15
               CODROTINABASERCA, --16
               CODPOLITICABASERCA, --17
               BASEDEBCREDRCA, --18
               CREDITASOBREPOLITICABASERCA, --19
               PRIORITARIA, --20
               PRIORITARIAGERAL, --21
               ALTERAPTABELA, --22
               VALIDARPOLITICASDESCCLIBLOQ, --23
               PRECOFIXO --24
               )
              SELECT VNPROXNUMPED, --1
                     ORIGEMPED, --2
                     CODPROD, --3
                     CODAUXILIAR, --4
                     VNNUMSEQNOVOPED, --5
                     PTABELA, --6
                     PEMBALAGEM, --7
                     PERDESC, --8
                     PERCBASERCA, --9
                     PERCDESCPCATIVI, --10
                     PERTXFIM, --11
                     PERACRESPF, --12
                     TIPODESC, --13
                     CODROTINADESC, --14
                     CODPOLITICADESC, --15
                     CODROTINABASERCA, --16
                     CODPOLITICABASERCA, --17
                     BASEDEBCREDRCA, --18
                     CREDITASOBREPOLITICABASERCA, --19
                     PRIORITARIA, --20
                     PRIORITARIAGERAL, --21
                     ALTERAPTABELA, --22
                     VALIDARPOLITICASDESCCLIBLOQ, --23
                     PRECOFIXO --24
                FROM PCORIGEMDESC
               WHERE NUMPED = REG_PED.NUMPED
                 AND CODPROD = REG_ITENS.CODPROD
                 AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao inserir item do novo pedido na pcorigemdesc: ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            INSERT INTO PCFALTA
              (NUMPED,
               DATA,
               CODPROD,
               CODUSUR,
               CODCLI,
               QT,
               PVENDA,
               CODFILIAL,
               NUMSEQ)
              (SELECT VNPROXNUMPED,
                      DATA,
                      CODPROD,
                      CODUSUR,
                      CODCLI,
                      QT,
                      PVENDA,
                      CODFILIAL,
                      VNNUMSEQNOVOPED
                 FROM PCFALTA
                WHERE NUMPED = REG_PED.NUMPED
                  AND CODPROD = REG_ITENS.CODPROD
                  AND NUMSEQ = REG_ITENS.NUMSEQ);
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao inserir item do novo pedido na pcpedi : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            DELETE FROM PCPEDI
             WHERE NUMPED = REG_PED.NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao excluir item do novo pedido da pcpedi : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            DELETE FROM PCFALTA
             WHERE NUMPED = REG_PED.NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao excluir item do novo pedido da pcfalta : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            DELETE FROM PCORIGEMPRECO
             WHERE NUMPED = REG_PED.NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao excluir item do novo pedido da pcorigempreco : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            DELETE FROM PCORIGEMCOMIS
             WHERE NUMPED = REG_PED.NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao excluir item do novo pedido da pcorigemcomis: ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;

          BEGIN
            DELETE FROM PCORIGEMDESC
             WHERE NUMPED = REG_PED.NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := 'Erro ao excluir item do novo pedido da pcorigemdesc : ' || SQLCODE || '-' || SQLERRM;
              VBVALIDO := FALSE;
          END;
        END IF;
      END LOOP;

      IF VBVALIDO = TRUE THEN
        --recalcular pedido
        SELECT SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PTABELA, 0)) VLTABELA,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PVENDA, 0)) VLATEND,
               SUM((NVL(PCPEDI.QT, 0) + NVL(PCPEDI.QTFALTA, 0)) * NVL(PCPEDI.PVENDA, 0)) VLTOTAL,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOFIN, 0)) VLCUSTOFIN,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOREAL, 0)) VLCUSTOREAL,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOREP, 0)) VLCUSTOREP,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOCONT, 0)) VLCUSTOCONT,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.PESOLIQ, 0)) TOTPESO,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.VOLUME, 0)) TOTVOLUME,
               COUNT(*) NUMITENS
          INTO VNVLTABELA,
               VNVLATEND,
               VNVLTOTAL,
               VNVLCUSTOFIN,
               VNVLCUSTOREAL,
               VNVLCUSTOREP,
               VNVLCUSTOCONT,
               VNTOTPESO,
               VNTOTVOLUME,
               VNNUMITENS
          FROM PCPEDI, PCPRODUT
         WHERE PCPEDI.NUMPED = REG_PED.NUMPED
           AND PCPEDI.CODPROD = PCPRODUT.CODPROD;

        UPDATE PCPEDC
           SET PCPEDC.VLTABELA    = VNVLTABELA,
               PCPEDC.VLATEND     = VNVLATEND,
               PCPEDC.VLTOTAL     = NVL(VNVLTOTAL, 0),
               PCPEDC.VLCUSTOFIN  = VNVLCUSTOFIN,
               PCPEDC.VLCUSTOREAL = VNVLCUSTOREAL,
               PCPEDC.VLCUSTOREP  = VNVLCUSTOREP,
               PCPEDC.VLCUSTOCONT = VNVLCUSTOCONT,
               PCPEDC.TOTPESO     = VNTOTPESO,
               PCPEDC.TOTVOLUME   = VNTOTVOLUME,
               PCPEDC.NUMITENS    = VNNUMITENS
         WHERE PCPEDC.NUMPED = REG_PED.NUMPED;

        VNNUMPED := REG_PED.NUMPED;
        --gravar novo pedido
        SELECT SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PTABELA, 0)) VLTABELA,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PVENDA, 0)) VLATEND,
               SUM((NVL(PCPEDI.QT, 0) + NVL(PCPEDI.QTFALTA, 0)) * NVL(PCPEDI.PVENDA, 0)) VLTOTAL,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOFIN, 0)) VLCUSTOFIN,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOREAL, 0)) VLCUSTOREAL,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOREP, 0)) VLCUSTOREP,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOCONT, 0)) VLCUSTOCONT,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.PESOLIQ, 0)) TOTPESO,
               SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.VOLUME, 0)) TOTVOLUME,
               COUNT(*) NUMITENS
          INTO VNVLTABELA,
               VNVLATEND,
               VNVLTOTAL,
               VNVLCUSTOFIN,
               VNVLCUSTOREAL,
               VNVLCUSTOREP,
               VNVLCUSTOCONT,
               VNTOTPESO,
               VNTOTVOLUME,
               VNNUMITENS
          FROM PCPEDI, PCPRODUT
         WHERE PCPEDI.NUMPED = VNPROXNUMPED
           AND PCPEDI.CODPROD = PCPRODUT.CODPROD;

        VNPERDESCPED := 0;
        IF NVL(VNVLTABELA,0) <> 0 THEN
           VNPERDESCPED := ROUND((((VNVLTABELA - VNVLTOTAL) / VNVLTABELA) * 100), GREGPCCONSUM.NUMCASASDECVENDA);
        END IF;

        INSERT INTO PCPEDC
          (CODCLI, --1
           CODCOB, --2
           CODDISTRIB, --3
           CODEMITENTE, --4
           CODFILIAL, --5
           CODFILIALNF, --6
           CODPLPAG, --7
           CODPRACA, --8
           CODSUPERVISOR, --9
           CODUSUR, --10
           CONDVENDA, --11
           DATA, --12
           DTENTREGA, --13
           HORA, --14
           MINUTO, --15
           NUMCAR, --16
           NUMITENS, --17
           NUMPED, --18
           NUMPEDCLI, --19
           NUMPEDRCA, --20
           OBS1, --21
           OBS2, --22
           OBSENTREGA1, --23
           OBSENTREGA2, --24
           OPERACAO, --25
           ORIGEMPED, --26
           PERCVENDA, --27
           PERDESC, --28
           POSICAO, --29
           PRAZO1, --30
           PRAZO2, --31
           PRAZO3, --32
           PRAZO4, --33
           PRAZO5, --34
           PRAZO6, --35
           PRAZO7, --36
           PRAZO8, --37
           PRAZO9, --38
           PRAZO10, --39
           PRAZO11, --40
           PRAZO12, --41
           PRAZOMEDIO, --42
           TIPOVENDA, --43
           TOTPESO, --44
           TOTVOLUME, --45
           VLATEND, --46
           VLCUSTOCONT, --47
           VLCUSTOFIN, --48
           VLCUSTOREAL, --49
           VLCUSTOREP, --50
           VLTABELA, --51
           VLTOTAL, --52
           DTABERTURAPEDPALM, --53
           DTFECHAMENTOPEDPALM, --54
           NUMREGIAO, --55
           USAINTEGRACAOWMS, --56
           USACREDRCA, --57
           USADEBCREDRCA, --58
           BONIFICALTDEBCREDRCA, --59
           TROCAALTDEBCREDRCA, --60
           CRMALTDEBCREDRCA, --61
           BROKERALTDEBCREDRCA, --62
           TIPOMOVCCRCA, --63
           VLFRETE, --64
           CODFORNECFRETE, --65
           FRETEDESPACHO, --66
           FRETEREDESPACHO, --67
           BROKER, --68
           TIPODOCUMENTO, --69
           CODCLINF, --70
           CONTAORDEM, --71
           CODMOTIVO, --72
           MOTIVOPOSICAO, --73
           LOG, --74
           CODCLITV8, --75
           CODPLPAGETICO, --76
           CODPLPAGGENERICO, --77
           TIPOPRIORIDADEENTREGA, --78
           LOCALDESEMBARACO, --79
           UFDESEMBARACO, --80
           NUMPEDTV1, --81
           AGRUPAMENTO, --82
           CODBNF, --83
           CUSTOBONIFICACAO, --84
           CODFORNECBONIFIC, --85
           TURNOENTREGA, --86
           CODENDENT, --87
           VLENTRADA, --88
           CODENDENTCLI, --89
           VLDESCABATIMENTO, --90
           CODESTABELECIMENTO, --91
           NUMTABELA, --92
           OBSENTREGA3, --93
           OBSENTREGA4, --94
           CODMOTBLOQUEIO, --95
           UTILIZAVENDAPOREMBALAGEM, --96
           CODUSUR2, --97
           CODUSUR3, --98
           CODUSUR4, --99
           NUMPEDWEB, --100
           CODAUTORIZACAOTEF, --101
           NSUTEF, --102
           CODADMCARTAO, --103
           USASALDOCONTACORRENTEDESCFIN, --104
           PERDESCFIN, --105
           INTEGRADORA, --106
           EANENTREGA, --107
           EANCOBRANCA, --108
           CODTRANSP, --109
           CODAUTORIZACAOTEFWEB, --110
           VLOUTRASDESP, --111
           TIPOCONTACORRENTE, --112
           CNPJINTERMEDIADOR, --113
           DESCINTERMEDIADOR --114
           )
          SELECT CODCLI, --1
                 CODCOB, --2
                 CODDISTRIB, --3
                 CODEMITENTE, --4
                 CODFILIAL, --5
                 CODFILIALNF, --6
                 CODPLPAG, --7
                 CODPRACA, --8
                 CODSUPERVISOR, --9
                 CODUSUR, --10
                 CONDVENDA, --11
                 DATA, --12
                 DTENTREGA, --13
                 HORA, --14
                 MINUTO, --15
                 NUMCAR, --16
                 VNNUMITENS, --17
                 VNPROXNUMPED, --18
                 NUMPEDCLI, --19
                 NUMPEDRCA, --20
                 OBS1, --21
                 OBS2, --22
                 OBSENTREGA1, --23
                 OBSENTREGA2, --24
                 OPERACAO, --25
                 ORIGEMPED, --26
                 PERCVENDA, --27
                 VNPERDESCPED, --28
                 POSICAO, --29
                 PRAZO1, --30
                 PRAZO2, --31
                 PRAZO3, --32
                 PRAZO4, --33
                 PRAZO5, --34
                 PRAZO6, --35
                 PRAZO7, --36
                 PRAZO8, --37
                 PRAZO9, --38
                 PRAZO10, --39
                 PRAZO11, --40
                 PRAZO12, --41
                 PRAZOMEDIO, --42
                 TIPOVENDA, --43
                 VNTOTPESO, --44
                 VNTOTVOLUME, --45
                 VNVLATEND, --46
                 VNVLCUSTOCONT, --47
                 VNVLCUSTOFIN, --48
                 VNVLCUSTOREAL, --49
                 VNVLCUSTOREP, --50
                 VNVLTABELA, --51
                 VNVLTOTAL, --52
                 DTABERTURAPEDPALM, --53
                 DTFECHAMENTOPEDPALM, --54
                 NUMREGIAO, --55
                 USAINTEGRACAOWMS, --56
                 USACREDRCA, --57
                 USADEBCREDRCA, --58
                 BONIFICALTDEBCREDRCA, --59
                 TROCAALTDEBCREDRCA, --60
                 CRMALTDEBCREDRCA, --61
                 BROKERALTDEBCREDRCA, --62
                 TIPOMOVCCRCA, --63
                 VLFRETE, --64
                 CODFORNECFRETE, --65
                 FRETEDESPACHO, --66
                 FRETEREDESPACHO, --67
                 BROKER, --68
                 TIPODOCUMENTO, --69
                 CODCLINF, --70
                 CONTAORDEM, --71
                 CODMOTIVO, --72
                 MOTIVOPOSICAO, --73
                 LOG, --74
                 CODCLITV8, --75
                 CODPLPAGETICO, --76
                 CODPLPAGGENERICO, --77
                 TIPOPRIORIDADEENTREGA, --78
                 LOCALDESEMBARACO, --79
                 UFDESEMBARACO, --80
                 NUMPEDTV1, --81
                 AGRUPAMENTO, --82
                 CODBNF, --83
                 CUSTOBONIFICACAO, --84
                 CODFORNECBONIFIC, --85
                 TURNOENTREGA, --86
                 CODENDENT, --87
                 VLENTRADA, --88
                 CODENDENTCLI, --89
                 VLDESCABATIMENTO, --90
                 CODESTABELECIMENTO, --91
                 NUMTABELA, --92
                 OBSENTREGA3, --93
                 OBSENTREGA4, --94
                 CODMOTBLOQUEIO, --95
                 UTILIZAVENDAPOREMBALAGEM, --96
                 CODUSUR2, --97
                 CODUSUR3, --98
                 CODUSUR4, --99
                 NUMPEDWEB, --100
                 CODAUTORIZACAOTEF, --101
                 NSUTEF, --102
                 CODADMCARTAO, --103
                 USASALDOCONTACORRENTEDESCFIN, --104
                 PERDESCFIN, --105
                 INTEGRADORA, --106
                 EANENTREGA, --107
                 EANCOBRANCA, --108
                 CODTRANSP, --109
                 CODAUTORIZACAOTEFWEB, --110
                 VLOUTRASDESP, --111
                 TIPOCONTACORRENTE, --112
                 CNPJINTERMEDIADOR, --113
                 DESCINTERMEDIADOR --114
            FROM PCPEDC
           WHERE NUMPED = REG_PED.NUMPED;

        P_MENSAGEM := 'Gerado Pedido : ' || VNPROXNUMPED || ' com itens que ultrapassaram maximo de linhas';
        P_VALIDO := TRUE;
      END IF;
    END LOOP;
  END;

PROCEDURE PROC_PROCESSARPEDIDOS(P_EXISTERRO IN OUT BOOLEAN) IS
    REGCLIENTE         T_CLIENTEPEDIDO;
    REGRCA             T_RCA;
    REGREGIAO          T_REGIAOCLIENTE;
    REGPLPAG           T_PLANODEPAGAMENTO;
    REGPRODUTO         T_PRODUTO;
    REGPRECOS          T_PRECOSETRIBUTACAO;
    REGCOB             T_PCCOB;
    REGFILIAL          T_FILIAL;
    VNCONTPED          NUMBER;
    VNCONTITEM         NUMBER;
    VNCONTITENSVALIDOS NUMBER;
    VNVLTOTPED         NUMBER;
    VNVLTOTTAB         NUMBER;
    VNVLTOTBASERCA     NUMBER;
    VNTOTPESOPED       NUMBER;
    VNTOTVOLUMEPED     NUMBER;
    VNVLCUSTOCONTPED   NUMBER;
    VNVLCUSTOFINPED    NUMBER;
    VNVLCUSTOREALPED   NUMBER;
    VNVLCUSTOREPPED    NUMBER;
    VNCONTITEMATUAL    NUMBER;
    VNNUMSEQ           NUMBER;
    VET_REGITEM        TB_ITEMPEDATUAL;
    VSMENSAGEM_COMISS  VARCHAR2(1000);
    VSMENSAGEM_ST      VARCHAR2(1000);
    VBCALCULASTVALIDO  BOOLEAN := FALSE;
    VSCODDISTRIB       PCPRODUT.CODDISTRIB%TYPE;
    VNSTFONTE          NUMBER;
    VSMENSAGEM_STFONTE VARCHAR2(1000);
    VBCODICMTABPF      BOOLEAN;
    VNPERLUC           NUMBER;
    VSUFFILIALNF       PCFILIAL.UF%TYPE;
    VNVLDESCSUFRAMA     PCPEDI.VLDESCSUFRAMA%TYPE;
    VNPERDESCISENTOICMS PCPEDI.PERDESCISENTOICMS%TYPE;
    VBVALIDOVERBACMV    BOOLEAN;
    VSMENSAGEMVERBACMV  VARCHAR2(1000);
    VNPERCVERBACMV      NUMBER;
    VNBASEICST          PCPEDI.BASEICST%TYPE;
    VSAUXPEDIDO         PCPEDC.NUMPED%TYPE;
    VSMENSAGEM          VARCHAR2(300);
    VNVLSALDOPED        NUMBER;
    VNVLDISPONIVEL      NUMBER;
    VBSALDORCA          BOOLEAN;
    VNCODMOTIVO         PCPEDC.CODMOTIVO%TYPE;
    VBCALCULAPRECOSEMIMPOSTO  BOOLEAN;
    VNPRECOSEMIMPOSTO         NUMBER;
    VSMENSAGEMPRECOSEMIMPOSTO VARCHAR2(300);
    VNPRECOVENDAAUX         NUMBER;
    VNPRECOTABELAAUX        NUMBER;
    VNPRECOBASERCAAUX       NUMBER;
    VNPRECOVENDA            NUMBER;
    VNPRECOTABELA           NUMBER;
    VNPRECOBASERCA          NUMBER;
    VNDIFPVENDA             NUMBER;
    VNDIFPTABELA            NUMBER;
    VNDIFPBASERCA           NUMBER;
    VNSALDO_ANT             NUMBER;
    VNVLTOTPED_ANT          NUMBER;
    VNVLTOTBASERCA_ANT      NUMBER;
    VNVLTOTTAB_ANT          NUMBER;
    VNMAXNUMSEQ             NUMBER;
    VNQTINICIAL             NUMBER;
    VBUSAPCTABCOMISS        BOOLEAN;
    VBUSAPCCOMISSAOUSUR     BOOLEAN;
    VBUSAPCCOMISSAOPLPAG    BOOLEAN;
    VBUSAPCCOMISSAOREGIAO   BOOLEAN;
    VICONT                  NUMBER;
    VBUSAPCCOMISSAOFILIAL   BOOLEAN;
    VNVLREDCMVSIMPLESNAC    PCPEDI.VLREDCMVSIMPLESNAC%TYPE;
    VNPTABELA               PCPEDI.PTABELA%TYPE;
    VSMENSAGEMPVENDA        VARCHAR2(1000);
    VSMENSAGEMREDSIMPLESNAC VARCHAR2(1000);
    VBCALCULAREDSIMPLESNAC  BOOLEAN;
    VNPERLUCSEMRED          NUMBER;
    VNVLCUSTOFIN            NUMBER;
    VNPERCDIF               NUMBER;
    VSMENSAGEMPERLUC        NUMBER;
    VNVLCUSTOFINSEMRED      NUMBER;
    VNPVENDAINICIO          NUMBER;
    VNVLCUSTOFINSEMIMPOSTOS NUMBER;
    VSMENSAGEMCUSTOFIN      VARCHAR2(1000);
    VNPERCDESCCOM           NUMBER;
    VNPERCDESCRCA           NUMBER;
    VIEXISTEBRINDE          NUMBER;
    VNNUMPEDBRINDE          PCPEDC.NUMPED%TYPE;
    VSMENSAGEMBRINDE        VARCHAR2(3000);
    VSGEROUBRINDE           VARCHAR2(1);
    VIEXISTEREST            NUMBER;
    VIEXISTERESTREF         NUMBER;
    VSMENSAGEMRESTST        VARCHAR2(1000);
    VNPEDIDORESTST          PCPEDC.NUMPED%TYPE;
    VSMENSAGEMPEDIDOTV8     VARCHAR2(1000);
    VNNUMPEDTV8             PCPEDC.NUMPED%TYPE;
    VSPOSICAOTV8            PCPEDC.POSICAO%TYPE;
    VNMOTIVOTV8             VARCHAR2(1000);
    VNVLREDPVENDASIMPLESNA  PCPEDI.VLREDPVENDASIMPLESNA%TYPE;
    VNPVENDA                PCPEDI.PVENDA%TYPE;
    VNPTABELA_SEMRED        PCPEDI.PTABELA%TYPE;
    VNPBASERCA              PCPEDI.PBASERCA%TYPE;
    VNVLIPI                 PCPEDI.VLIPI%TYPE;
    VNPERCIPI               PCPEDI.PERCIPI%TYPE;
    VNST_SEMRED             PCPEDI.ST%TYPE;
    VNBASEICST_SEMRED       PCPEDI.BASEICST%TYPE;
    VNSTPTABELA             PCPEDI.ST%TYPE;
    VICONTADOR              NUMBER;
    VSMENSAGEMDIVIDENFE     VARCHAR2(300);
    V_VALIDARCAMPANHABRINDE VARCHAR2(1);
    V_MSG_MULT_PLANO        VARCHAR2(300);
    VSMOTIVO                PCMOTBLOQUEIO.DESCRICAO%TYPE;
    VSPOSICAO               PCBLOQUEIOSPEDIDO.STATUS%TYPE;
    VNPTABELASEMIMPOSTOTEMP NUMBER;
    VNPDESCONTOITEMTEMP     NUMBER;
    vnCALCULAR_PVENDA_SEM_IMPOSTO PCPEDI.PVENDA%TYPE;
    vPVENDACOMIMPOSTO PCPEDI.PVENDA%TYPE;
	VST NUMBER(18,6);
    vVLFECP PCPEDI.VLFECP%TYPE;
BEGIN
   VNCONTPED := GVET_REGPEDIDO.COUNT;

   IF VNCONTPED > 0 THEN
      FOR I IN 1 .. VNCONTPED 
      LOOP
         VSCODDISTRIB := NULL;

         BEGIN
            PROC_VALIDARCABPED(GVET_REGPEDIDO(I),
                               REGCLIENTE,
                               REGRCA,
                               REGREGIAO,
                               REGPLPAG,
                               REGCOB,
                               REGFILIAL);

            IF GVET_REGPEDIDO(I).VALIDO = TRUE THEN
               VNCONTITEM         := GVET_REGITEM.COUNT;
               VNCONTITEMATUAL    := 0;
               VNNUMSEQ           := 0;
               VNCONTITENSVALIDOS := 0;
               VNVLTOTPED         := 0;
               VNVLTOTTAB         := 0;
               VNVLTOTBASERCA     := 0;
               VNTOTPESOPED       := 0;
               VNTOTVOLUMEPED     := 0;
               VNVLCUSTOCONTPED   := 0;
               VNVLCUSTOFINPED    := 0;
               VNVLCUSTOREALPED   := 0;
               VNVLCUSTOREPPED    := 0;
               VNMAXNUMSEQ        := 0;
               VNQTINICIAL        := 0;

               IF NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) <> 0 THEN
                  SELECT SUM(PCPEDI.QT * PCPEDI.PVENDA),
                         SUM(PCPEDI.QT * PCPEDI.PTABELA),
                         SUM(PCPEDI.QT * PCPEDI.PBASERCA),
                         MAX(NUMSEQ),
                         COUNT(*)
                  INTO VNVLTOTPED_ANT,
                       VNVLTOTTAB_ANT,
                       VNVLTOTBASERCA_ANT,
                       VNNUMSEQ,
                       VNQTINICIAL
                  FROM PCPEDI
                  WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                  VNSALDO_ANT := VNVLTOTPED_ANT - NVL(VNVLTOTBASERCA_ANT, VNVLTOTTAB_ANT);
                  VNNUMSEQ    := NVL(VNNUMSEQ, 0);
                  VNMAXNUMSEQ := NVL(VNNUMSEQ, 0);
               END IF;

               FOR J IN 1 .. VNCONTITEM 
               LOOP
                  VNPERCDESCCOM := 0;
                  VNPERCDESCRCA := 0;
                  vPVENDACOMIMPOSTO := GVET_REGITEM(J).PVENDA;

                  BEGIN
                     IF (GVET_REGPEDIDO(I).NUMPEDINT = GVET_REGITEM(J).NUMPEDINT AND GVET_REGPEDIDO(I).INTEGRADORA = GVET_REGITEM(J).INTEGRADORA AND
                         (NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) = 0 OR 
                          (NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) <> 0 AND (GVET_REGPEDIDO(I).NUMPEDORIG = GVET_REGITEM(J).NUMPEDORIG)))) THEN
                        PROC_VALIDARITEMPED(GVET_REGITEM(J),
                                      GVET_REGPEDIDO(I),
                                      REGCLIENTE,
                                      REGRCA,
                                      REGREGIAO,
                                      REGPLPAG,
                                      REGFILIAL,
                                      GVET_REGORIGEMPRECO(J),
                                      GVET_REGORIGEMCOMISS(J),
                                      GVET_REGORIGEMDESC(J),
                                      REGPRODUTO,
                                      REGPRECOS,
                                      VET_REGITEM,
                                      VSCODDISTRIB);

                        IF GVET_REGITEM(J).VALIDO = TRUE THEN
                           GVET_REGITEM(J).ST := 0;
                           GVET_REGITEM(J).VLIPI := 0;
                           GVET_REGITEM(J).IVA := REGPRECOS.IVA;
                           GVET_REGITEM(J).PAUTA := REGPRECOS.PAUTA;
                           GVET_REGITEM(J).ALIQICMS1 := REGPRECOS.ALIQICMS1;
                           GVET_REGITEM(J).ALIQICMS2 := REGPRECOS.ALIQICMS2;
                           GVET_REGITEM(J).PERCBASEREDST := REGPRECOS.PERCBASEREDST;
                           VNVLREDPVENDASIMPLESNA := 0;
                           GVET_REGITEM(J).VLREDPVENDASIMPLESNA := 0;
                           GVET_REGITEM(J).VLREDCMVSIMPLESNAC := 0;

                           IF (REGPRECOS.USAALIQICMSSIMPLESNACIONAL = 'S') AND
                              (REGFILIAL.UF = REGCLIENTE.ESTENT) AND (REGCLIENTE.SIMPLESNACIONAL = 'S') AND
                              (REGPRODUTO.REVENDA = 'S') AND (REGPRECOS.ALIQSTSIMPLESNACIONAL > 0) THEN
                              REGPRECOS.ALIQICMS2 := REGPRECOS.ALIQSTSIMPLESNACIONAL;
                           END IF;

                           IF REGPLPAG.FORMAPARCELAMENTO = 'V' AND GVET_REGPEDIDO(I).NUMPEDORIG = 0 THEN
                              IF GVET_REGPEDIDO(I).PERCPLPAG IS NOT NULL THEN
                                 GVET_REGITEM(J).PVENDA := ROUND(GVET_REGITEM(J).PVENDA * (1 + (GVET_REGPEDIDO(I).PERCPLPAG / 100)), GREGPCCONSUM.NUMCASASDECVENDA);
                                 REGPRODUTO.PTABELA := ROUND(REGPRODUTO.PTABELA * (1 + (GVET_REGPEDIDO(I).PERCPLPAG / 100)), GREGPCCONSUM.NUMCASASDECVENDA);
                                 GVET_REGITEM(J).PBASERCA := ROUND(GVET_REGITEM(J).PBASERCA * (1 + (GVET_REGPEDIDO(I).PERCPLPAG / 100)), GREGPCCONSUM.NUMCASASDECVENDA);
                              END IF;
                           END IF;

                           IF VSCODDISTRIB IS NULL THEN
                              VSCODDISTRIB := REGPRODUTO.CODDISTRIB;
                           END IF;

                           VNCONTITEMATUAL := VNCONTITEMATUAL + 1;
                           VET_REGITEM(VNCONTITEMATUAL).PVENDA := GVET_REGITEM(J).PVENDA;
                           VET_REGITEM(VNCONTITEMATUAL).PTABELA := REGPRODUTO.PTABELA;
                           VET_REGITEM(VNCONTITEMATUAL).PBASERCA := GVET_REGITEM(J).PBASERCA;
                           VET_REGITEM(VNCONTITEMATUAL).QT := GVET_REGITEM(J).QT;

                           BEGIN
                              SELECT PCFILIAL.UF
                              INTO VSUFFILIALNF
                              FROM PCFILIAL
                              WHERE PCFILIAL.CODIGO = NVL(GVET_REGPEDIDO(I).CODFILIALNF, REGCLIENTE.CODFILIALNF);
                           EXCEPTION WHEN OTHERS THEN
                              VSUFFILIALNF := NULL;
                           END;

                           IF REGCLIENTE.SIMPLESNACIONAL = 'S' AND
                              REGPRECOS.PERCREDPVENDASIMPLESNAC <> 0 AND GVET_REGITEM(J).APLICADESCONTOSIMPLES = 'S' THEN
                              --só atualiza caso não tenha impostos
                              IF (REGPRECOS.ALIQICMS1 <= REGPRECOS.ALIQICMS2) AND REGPRECOS.PAUTA = 0 AND REGPRECOS.IVA = 0 THEN
                                 --encontrar perluc antes dos calculos de redução do simples nacional
                                 VNPVENDAINICIO := GVET_REGITEM(J).PVENDA;

                                 PROC_ENCONTRAPERLUC(GVET_REGITEM(J),
                                                     GVET_REGPEDIDO(I),
                                                     REGCLIENTE,
                                                     REGPRODUTO,
                                                     REGPRECOS,
                                                     REGRCA,
                                                     REGREGIAO,
                                                     REGFILIAL,
                                                     REGPLPAG,
                                                     VNPERLUCSEMRED,
                                                     VNVLCUSTOFINSEMRED,
                                                     VSMENSAGEMPERLUC);
                              END IF;
                           END IF;
                           --Encontrar pvenda correto para o simples nacional
                           IF REGCLIENTE.SIMPLESNACIONAL = 'S' AND
                              REGPRECOS.PERCREDPVENDASIMPLESNAC <> 0 AND GVET_REGITEM(J).APLICADESCONTOSIMPLES = 'S' THEN
                              PROC_ENCONTRACMVCOMRED(GVET_REGITEM(J),
                                                     GVET_REGPEDIDO(I),
                                                     REGCLIENTE,
                                                     REGREGIAO,
                                                     REGRCA,
                                                     REGFILIAL,
                                                     REGPLPAG,
                                                     REGPRODUTO,
                                                     REGPRECOS,
                                                     VNVLCUSTOFINSEMIMPOSTOS,
                                                     VSMENSAGEMCUSTOFIN);

                              IF VSMENSAGEMCUSTOFIN IS NOT NULL THEN
                                 PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                         GVET_REGPEDIDO(I).NUMPEDINT,
                                         GVET_REGITEM(J).CODPROD,
                                         GVET_REGITEM(J).CODAUXILIAR,
                                         GVET_REGITEM(J).NUMSEQORIG,
                                         GVET_REGPEDIDO(I).CODCLI,
                                         GVET_REGPEDIDO(I).CODUSUR,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).INTEGRADORA,
                                         NULL,
                                         '3',
                                         'Erro21:' || VSMENSAGEMCUSTOFIN,
                                         NULL);
                              END IF;

                              IF (REGPRECOS.PAUTA > 0 OR NVL(REGPRECOS.IVA, 0) > 0 OR NVL(REGPRECOS.ALIQICMS1, 0) > 0 OR
                                 NVL(REGPRECOS.ALIQICMS2, 0) > 0) OR GVET_REGITEM(J).PVENDA <> REGPRODUTO.PTABELA THEN
                                 --calcula st sem redução para caso de aliq1 > aliq2
                                 VNPVENDA          := GVET_REGITEM(J).PVENDA;
                                 VNPTABELA_SEMRED  := REGPRODUTO.PTABELA;
                                 VNPBASERCA        := GVET_REGITEM(J).PBASERCA;
                                 VNVLIPI           := GVET_REGITEM(J).VLIPI;
                                 VNPERCIPI         := GVET_REGITEM(J).PERCIPI;
                                 VNST_SEMRED       := 0;
                                 VNBASEICST_SEMRED := 0;

                                 VBCALCULASTVALIDO := FUNCOESVENDAS.CALCULARIMPOSTOS(VNPTABELA_SEMRED,
                                                                                     VNPTABELA_SEMRED,
                                                                                     VNPBASERCA,
                                                                                     VNVLIPI,
                                                                                     VNPERCIPI,
                                                                                     NVL(REGPRODUTO.PERCIPIVENDA,0),
                                                                                     GVET_REGPEDIDO(I).PERCVENDA,
                                                                                     GREGPCCONSUM.TIPOCALCST,
                                                                                     GREGPCCONSUM.CALCSTPF,
                                                                                     REGPRECOS.MOSTRARPVENDASEMST,
                                                                                     GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
                                                                                     REGCLIENTE.CALCULAST,
                                                                                     REGCLIENTE.IEENT,
                                                                                     REGCLIENTE.TIPOFJ,
                                                                                     REGPRECOS.PAUTA,
                                                                                     REGPRECOS.IVA,
                                                                                     REGPRECOS.ALIQICMS1,
                                                                                     REGPRECOS.ALIQICMS2,
                                                                                     REGPRECOS.PERCBASEREDST,
                                                                                     GREGPCCONSUM.NUMCASASDECVENDA,
                                                                                     0,
                                                                                     REGFILIAL.UF,
                                                                                     REGCLIENTE.ESTENT,
                                                                                     NVL(REGPRECOS.USAVALORULTENTBASEST,'N'),
                                                                                     NVL(REGPRECOS.USAVALORULTENTBASEST2,'N'),
                                                                                     REGPRECOS.VALORULTENT,
                                                                                     REGCLIENTE.ISENTOIPI,
                                                                                     REGCLIENTE.SUFRAMA,
                                                                                     GREGPCCONSUM.CALCULARSTCOMIPI,
                                                                                     GREGPCCONSUM.TIPOCALCIPI,
                                                                                     GVET_REGPEDIDO(I).CODFILIALNF,
                                                                                     GVET_REGPEDIDO(I).CONDVENDA,
                                                                                     REGCLIENTE.CONTRIBUINTE,
                                                                                     VSUFFILIALNF,
                                                                                     REGPRODUTO.IMPORTADO,
                                                                                     REGFILIAL.CALCULARIPIVENDA,
                                                                                     REGPRODUTO.PERCIPIVENDATAB,
                                                                                     REGPRODUTO.VLPAUTAIPIVENDA,
                                                                                     REGPRODUTO.VLPAUTAIPIVENDATAB,
                                                                                     REGPRODUTO.VLIPIPORKGVENDA,
                                                                                     REGPRODUTO.VLIPIPORKGVENDATAB,
                                                                                     REGPRODUTO.PESOBRUTO,
                                                                                     REGPRECOS.TIPOCALCULOGNRE,
                                                                                     'N', --regcliente.simplesnacional,
                                                                                     0, --regprecos.percredpvendasimplesnac,
                                                                                     'S',
                                                                                     REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                                                                     VSMENSAGEM_ST,
                                                                                     VNST_SEMRED,
                                                                                     VNBASEICST_SEMRED,
                                                                                     GREGPCCONSUM.ACEITAPFCONTRIBUINTE,
                                                                                     REGPRECOS.CUSTONFSEMST,
                                                                                     REGPRECOS.USAPMCBASEST,
                                                                                     REGPRODUTO.PRECOMAXCONSUM,
                                                                                     REGCLIENTE.CONSUMIDORFINAL,
                                                                                     GVET_REGITEM(J).RETIRAIMP,
                                                                                     NVL(GVET_REGITEM(J).PVENDASEMIMPOSTO,'N'),
                                                                                     REGPRECOS.AGREGARIPICALCULOST,
                                                                                     REGCLIENTE.UTILIZACALCULOSTMT,
                                                                                     REGCLIENTE.MARGEMMVA,
                                                                                     REGCLIENTE.PERCARGATRIBMEDIA,
                                                                                     REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                                     REGPRECOS.VLULTENTMES,
                                                                                     REGPRECOS.PERCBASESTRJ);
                                 PROC_ENCONTRAPVENDA(GVET_REGITEM(J),
                                                     GVET_REGPEDIDO(I),
                                                     REGCLIENTE,
                                                     REGREGIAO,
                                                     REGRCA,
                                                     REGPRODUTO,
                                                     REGPRECOS,
                                                     VNSTPTABELA,
                                                     VNPERCDESCCOM,
                                                     VNPERCDESCRCA,
                                                     VSMENSAGEMPVENDA);

                                 IF VNST_SEMRED > 0 THEN
                                    IF GVET_REGITEM(J).PVENDA <> REGPRODUTO.PTABELA THEN
                                       GVET_REGITEM(J).VLREDPVENDASIMPLESNA := VNST_SEMRED - VNSTPTABELA;
                                    ELSE
                                       GVET_REGITEM(J).VLREDPVENDASIMPLESNA := VNST_SEMRED - GVET_REGITEM(J).ST;
                                    END IF;

                                    VNVLREDCMVSIMPLESNAC := 0;
                                 END IF;

                                 IF VSMENSAGEMPVENDA IS NOT NULL THEN
                                    PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                     GVET_REGPEDIDO(I).NUMPEDINT,
                                                     GVET_REGITEM(J).CODPROD,
                                                     GVET_REGITEM(J).CODAUXILIAR,
                                                     GVET_REGITEM(J).NUMSEQORIG,
                                                     GVET_REGPEDIDO(I).CODCLI,
                                                     GVET_REGPEDIDO(I).CODUSUR,
                                                     NULL,
                                                     NULL,
                                                     GVET_REGPEDIDO(I).INTEGRADORA,
                                                     NULL,
                                                     '3',
                                                     'Erro22:' || VSMENSAGEMPVENDA,
                                                     NULL);
                                 END IF;
                              END IF;
                           END IF;

                           GVET_REGITEM(J).BASEDIFALIQUOTAS := 0;
                           GVET_REGITEM(J).VLDIFALIQUOTAS := 0;
                           GVET_REGITEM(J).PERCDIFALIQUOTAS := 0;

                           IF (REGCLIENTE.ISENTODIFALIQUOTAS = 'N') AND (REGPRECOS.PERCDIFALIQUOTAS <> 0) THEN
                              VBCALCULAPRECOSEMIMPOSTO := FUNCOESVENDAS.CALCULO_PRECO_SEM_IMPOSTOS(NVL(REGPRODUTO.PERCIPIVENDA, 0),
                                                                                                   REGPRODUTO.VLPAUTAIPIVENDA,
                                                                                                   REGPRODUTO.VLIPIPORKGVENDA,
                                                                                                   GVET_REGITEM(J).PVENDA,
                                                                                                   REGPRECOS.PAUTA,
                                                                                                   REGPRODUTO.PESOBRUTO,
                                                                                                   REGPRECOS.PERCDIFALIQUOTAS,
                                                                                                   REGPRODUTO.PERCIPIVENDA,
                                                                                                   REGPRECOS.VALORULTENT,
                                                                                                   REGPRECOS.IVA,
                                                                                                   REGPRECOS.PERCBASEREDST,
                                                                                                   REGPRECOS.ALIQICMS1,
                                                                                                   REGPRECOS.ALIQICMS2,
                                                                                                   REGPRECOS.USAVALORULTENTBASEST,
                                                                                                   REGPRECOS.USAVALORULTENTBASEST2,
                                                                                                   REGFILIAL.UF,
                                                                                                   REGCLIENTE.ESTENT,
                                                                                                   VNPRECOSEMIMPOSTO,
                                                                                                   VSMENSAGEMPRECOSEMIMPOSTO,
                                                                                                   REGPRECOS.USAPMCBASEST,
                                                                                                   REGPRODUTO.PRECOMAXCONSUM,
                                                                                                   REGPRECOS.USAVLULTENTMEDIOBASEST,
                                                                                                   REGPRECOS.VLULTENTMES);
                              IF VSMENSAGEMPRECOSEMIMPOSTO IS NOT NULL THEN
                                 PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                  GVET_REGPEDIDO(I).NUMPEDINT,
                                                  GVET_REGITEM(J).CODPROD,
                                                  GVET_REGITEM(J).CODAUXILIAR,
                                                  GVET_REGITEM(J).NUMSEQORIG,
                                                  GVET_REGPEDIDO(I).CODCLI,
                                                  GVET_REGPEDIDO(I).CODUSUR,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).INTEGRADORA,
                                                  117,
                                                  '3',
                                                  'Erro ao calcular preço sem imposto' ||
                                                  VSMENSAGEMPRECOSEMIMPOSTO,
                                                  NULL);
                              END IF;

                              IF VBCALCULAPRECOSEMIMPOSTO = TRUE THEN
                                 GVET_REGITEM(J).PERCDIFALIQUOTAS := REGPRECOS.PERCDIFALIQUOTAS;
                                 GVET_REGITEM(J).BASEDIFALIQUOTAS := VNPRECOSEMIMPOSTO;
                                 GVET_REGITEM(J).VLDIFALIQUOTAS := ROUND((GVET_REGITEM(J).BASEDIFALIQUOTAS * (GVET_REGITEM(J).PERCDIFALIQUOTAS / 100)),
                                                                         GREGPCCONSUM.NUMCASASDECVENDA);
                              END IF;
                           END IF;

                           VNPRECOVENDAAUX   := (GVET_REGITEM(J).PVENDA - GVET_REGITEM(J).VLDIFALIQUOTAS);
                           VNPRECOTABELAAUX  := (REGPRODUTO.PTABELA - GVET_REGITEM(J).VLDIFALIQUOTAS);
                           VNPRECOBASERCAAUX := (GVET_REGITEM(J).PBASERCA - GVET_REGITEM(J).VLDIFALIQUOTAS);
                           VNPRECOVENDA   := VNPRECOVENDAAUX;
                           VNPRECOTABELA  := VNPRECOTABELAAUX;
                           VNPRECOBASERCA := VNPRECOBASERCAAUX;

						   IF GVET_REGPEDIDO(I).INTEGRADORA = 23 THEN
						       vnCALCULAR_PVENDA_SEM_IMPOSTO := GVET_REGITEM(J).PVENDA;   						
						   ELSE	   
							   BEGIN
								  SELECT NVL(VALORSEMIMPOSTO,0) VALORSEMIMPOSTO
								  INTO vnCALCULAR_PVENDA_SEM_IMPOSTO
								  FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(GVET_REGPEDIDO(I).CODFILIAL,
																						NVL(GVET_REGPEDIDO(I).CODFILIALNF, 
																						REGCLIENTE.CODFILIALNF),
																						GVET_REGITEM(J).CODFILIALRETIRA,
																						NVL(GVET_REGPEDIDO(I).CODCLI,REGCLIENTE.CODCLI),
																						NVL(GVET_REGPEDIDO(I).CODPLPAG,REGCLIENTE.CODPLPAG),
																						GVET_REGITEM(J).CODPROD,
																						GVET_REGITEM(J).CODAUXILIAR,
																						NVL(GVET_REGPEDIDO(I).CONDVENDA, 1),
																						'N',
																						0,
																						0,
																						vPVENDACOMIMPOSTO));
							   EXCEPTION WHEN OTHERS THEN
								  vnCALCULAR_PVENDA_SEM_IMPOSTO := GVET_REGITEM(J).PVENDA;
							   END;							   
                           END IF;						   
													
                           BEGIN
                              SELECT BASEST,ST,VLRFECP,BASEFECP,ALIQFECP
                              INTO GVET_REGITEM(J).BASEICST,
                                   VST,
                                   vVLFECP,
                                   GVET_REGITEM(J).BASEFECP,
                                   GVET_REGITEM(J).ALIQFECP   
							  FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(GVET_REGPEDIDO(I).CODFILIAL,
																  NVL(GVET_REGPEDIDO(I).CODFILIALNF, 
                                                                  REGCLIENTE.CODFILIALNF), 
																  GVET_REGITEM(J).CODFILIALRETIRA,
																  NVL(GVET_REGPEDIDO(I).CODCLI,REGCLIENTE.CODCLI), 
																  NVL(GVET_REGPEDIDO(I).CODPLPAG,REGCLIENTE.CODPLPAG),
																  GVET_REGITEM(J).CODPROD,
                                                                  GVET_REGITEM(J).CODAUXILIAR,
																  NVL(GVET_REGPEDIDO(I).CONDVENDA, 1),
																  'N', 
																  vnCALCULAR_PVENDA_SEM_IMPOSTO,
															      0,
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
																  0,
																  NULL,
																  'I',
																  NULL,
																  GREGPEDIDO.CODENDENTCLI));	
																  															  																											  
                              GVET_REGITEM(J).BASEICST := 0;
                              VST := 0;
                              vVLFECP := 0;
                              GVET_REGITEM(J).BASEFECP := 0;
                              GVET_REGITEM(J).ALIQFECP := 0;
                           END;
						   
						   GVET_REGITEM(J).ST := VST;
						   GVET_REGITEM(J).VLRFECP := vVLFECP;

               BEGIN
                SELECT VALORIPI, PERCENTUAL_IPI
                  INTO GVET_REGITEM(J).VLIPI, GVET_REGITEM(J).PERCIPI
                  FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(GVET_REGPEDIDO(I).CODFILIAL,
                                                         GVET_REGPEDIDO(I).CODFILIALNF,
                                                         GVET_REGPEDIDO(I).CODFILIAL,
                                                         NVL(GVET_REGPEDIDO(I).CODCLI, REGCLIENTE.CODCLI),
                                                         GVET_REGITEM(J).CODPROD,
                                                         GVET_REGITEM(J).CODAUXILIAR,
                                                         NVL(GVET_REGPEDIDO(I).CONDVENDA, 1),
                                                         'N',
                                                         vnCALCULAR_PVENDA_SEM_IMPOSTO,
                                                         'N',
                                                         GVET_REGPEDIDO(I).CODENDENTCLI,
                                                         'N', --transferencia
                                                         'N', --transferenciaVirtual
                                                         'N',
                                                         'F',
                                                         NULL,
                                                         'I',
                                                         0,
                                                         'S',
                                                         'N'
                                                         ));
              EXCEPTION
                WHEN OTHERS THEN
                  GVET_REGITEM(J).VLIPI := 0;
              END;
						   						   
                           IF NVL(REGPRODUTO.PTABELASEMIMPOSTO, 0) > 0 THEN
                              REGPRODUTO.PTABELA := (REGPRODUTO.PTABELA + VST + vVLFECP);
                           END IF;

                           IF GVET_REGPEDIDO(I).INTEGRADORA = 23 THEN        
                              IF REGCLIENTE.CALCULAST = 'N' THEN
                                 BEGIN
                                    SELECT P.PTABELA
                                    INTO VNPTABELASEMIMPOSTOTEMP
                                    FROM PCPEDITEMP P
                                    WHERE P.CODPROD = REGPRODUTO.CODPROD
                                      AND P.NUMPEDCLI = GVET_REGPEDIDO(I).NUMPEDCLI
                                      AND P.INTEGRADORA = GVET_REGPEDIDO(I).INTEGRADORA;
                                 EXCEPTION WHEN OTHERS THEN
                                    VNPTABELASEMIMPOSTOTEMP := 0;
                                 END;
                          
                                 IF VNPTABELASEMIMPOSTOTEMP > 0 THEN
                                    REGPRODUTO.PTABELA := VNPTABELASEMIMPOSTOTEMP;      
                                 ELSE 
                                    REGPRODUTO.PTABELA := REGPRODUTO.PTABELA;
                                 END IF; 
                              ELSE
                                 GVET_REGITEM(J).PVENDA := GVET_REGITEM(J).PVENDA + VST + vVLFECP;
                                 
                                 IF REGPLPAG.NUMPR = 1 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA1;
                                 ELSIF REGPLPAG.NUMPR = 2 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA2;
                                 ELSIF REGPLPAG.NUMPR = 3 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA3;
                                 ELSIF REGPLPAG.NUMPR = 4 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA4;
                                 ELSIF REGPLPAG.NUMPR = 5 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA5;
                                 ELSIF REGPLPAG.NUMPR = 6 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA6;
                                 ELSIF REGPLPAG.NUMPR = 7 THEN
                                    REGPRODUTO.PTABELA := REGPRECOS.PVENDA7;
                                 END IF;          
                              END IF;  
           
                              BEGIN
                                 SELECT P.PERDESC
                                 INTO VNPDESCONTOITEMTEMP
                                 FROM PCPEDITEMP P
                                 WHERE P.CODPROD = REGPRODUTO.CODPROD
                                   AND P.NUMPEDCLI = GVET_REGPEDIDO(I).NUMPEDCLI
                                   AND P.INTEGRADORA = GVET_REGPEDIDO(I).INTEGRADORA;
                              EXCEPTION WHEN OTHERS THEN
                                 VNPDESCONTOITEMTEMP := 0;
                              END;               

                              IF VNPDESCONTOITEMTEMP > 0 AND REGCLIENTE.CALCULAST = 'S' THEN
                                 GVET_REGITEM(J).PVENDA := GVET_REGITEM(J).PVENDA - ((VNPDESCONTOITEMTEMP * GVET_REGITEM(J).PVENDA) / 100);
                              END IF;               
                           END IF;   

                           VNDIFPVENDA   := VNPRECOVENDAAUX - VNPRECOVENDA;
                           VNDIFPTABELA  := VNPRECOTABELAAUX - VNPRECOTABELA;
                           VNDIFPBASERCA := VNPRECOBASERCAAUX - VNPRECOBASERCA;

                           IF NOT (GVET_REGITEM(J).TIPOINTEGRACAO = 'W') THEN
                              GVET_REGITEM(J).PVENDA := (GVET_REGITEM(J).PVENDA + VNDIFPVENDA);
                              REGPRODUTO.PTABELA := (REGPRODUTO.PTABELA + VNDIFPTABELA);
                           END IF;

                           GVET_REGITEM(J).PBASERCA := (GVET_REGITEM(J).PBASERCA + VNDIFPBASERCA);
                           GVET_REGORIGEMPRECO(J).VLST := GVET_REGITEM(J).ST;
					
                           IF GVET_REGPEDIDO(I).INTEGRADORA = 23 THEN 
                              REGPRODUTO.PTABELA := ROUND(REGPRODUTO.PTABELA,2);
                              GVET_REGITEM(J).PVENDA := ROUND(GVET_REGITEM(J).PVENDA,2);					  
                              -- remover a diferença de um centavo quando o round ocorre com PTABELA E PVENDA iguais porem com o PTABELA com casa decimal acima de dois.
                              IF (GVET_REGITEM(J).PVENDA = (REGPRODUTO.PTABELA - 0.01)) THEN
                                 REGPRODUTO.PTABELA := GVET_REGITEM(J).PVENDA;
                              END IF;
                           END IF; 					

                           IF GVET_REGITEM(J).PVENDASEMIMPOSTO = 'S' THEN
                              IF GVET_REGPEDIDO(I).INTEGRADORA <> 23 THEN 
                                 GVET_REGITEM(J).PVENDA := GVET_REGITEM(J).PVENDA + NVL(GVET_REGITEM(J).ST,0) + NVL(GVET_REGITEM(J).VLRFECP,0);
                              END IF; 
					  
                              GVET_REGITEM(J).PVENDASEMIMPOSTO := 'N';
                           END IF;                           
                           -- Cálculo da Base do RCA
                           IF NVL(GVET_REGITEM(J).MOVIMENTACONTACORRENTERCA,'N') = 'S' THEN
                              IF GVET_REGPEDIDO(I).USADEBCREDRCA = 'S' THEN
                                 GVET_REGITEM(J).PBASERCA := REGPRODUTO.PTABELA;
                              ELSE
                                 GVET_REGITEM(J).PBASERCA := GVET_REGITEM(J).PVENDA;
                              END IF;
                           END IF;
                           
                           IF (NVL(GVET_REGITEM(J).MOVIMENTACONTACORRENTERCA,'N') = 'N') OR (NVL(GVET_REGITEM(J).PBASERCA,0) = 0) THEN
                              GVET_REGPEDIDO(I).USADEBCREDRCA := 'N';
                              GVET_REGPEDIDO(I).USACREDRCA := 'N';
                           END IF;
                           -- FIM => Cálculo da Base do RCA
                           ----------------------------------------------------------
                           -- calcula o percentual de desconto
                           GVET_REGITEM(J).PERDESC := FUNC_CALCULARPERDESCITEM(REGPRODUTO.PTABELA, GVET_REGITEM(J).PVENDA, GVET_REGITEM(J).INTEGRADORA);
                           GVET_REGITEM(J).VLREDPVENDASIMPLESNA := NULL;

                           IF REGCLIENTE.SIMPLESNACIONAL = 'S' AND
                              REGPRECOS.PERCREDPVENDASIMPLESNAC <> 0 AND GVET_REGITEM(J).APLICADESCONTOSIMPLES = 'S' THEN
                              --só atualiza caso não tenha impostos
                              IF (REGPRECOS.ALIQICMS1 <= REGPRECOS.ALIQICMS2) AND REGPRECOS.PAUTA = 0 AND REGPRECOS.IVA = 0 THEN
                                 VBCALCULAREDSIMPLESNAC := FUNCOESVENDAS.CALCULARREDSIMPLESNAC(REGPRECOS.CUSTOFIN,
                                                                                               REGPRECOS.CUSTONFSEMST,
                                                                                               REGPRECOS.CUSTONFSEMSTGUIAULTENT,
                                                                                               REGPRECOS.IVAULTENT,
                                                                                               REGPRECOS.ALIQICMS1ULTENT,
                                                                                               REGPRECOS.ALIQICMS2ULTENT,
                                                                                               REGPRECOS.REDBASEIVAULTENT,
                                                                                               REGPRECOS.PERCICMSFRETEFOBSTULTENT,
                                                                                               REGPRECOS.VLFRETECONHECULTENT,
                                                                                               REGPRECOS.PERCALIQEXTGUIAULTENT,
                                                                                               REGPRECOS.VLSTULTENT,
                                                                                               REGPRECOS.BASEICMSULTENT,
                                                                                               REGPRECOS.VLSTGUIAULTENT,
                                                                                               REGPRECOS.PERCREDPVENDASIMPLESNAC,
                                                                                               GREGPCCONSUM.NUMCASASDECVENDA,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               VSMENSAGEMREDSIMPLESNAC,
                                                                                               GVET_REGITEM(J).VLREDPVENDASIMPLESNA);
                                 IF VSMENSAGEMREDSIMPLESNAC IS NOT NULL THEN
                                    PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                     GVET_REGPEDIDO(I).NUMPEDINT,
                                                     GVET_REGITEM(J).CODPROD,
                                                     GVET_REGITEM(J).CODAUXILIAR,
                                                     GVET_REGITEM(J).NUMSEQORIG,
                                                     GVET_REGPEDIDO(I).CODCLI,
                                                     GVET_REGPEDIDO(I).CODUSUR,
                                                     NULL,
                                                     NULL,
                                                     GVET_REGPEDIDO(I).INTEGRADORA,
                                                     93,
                                                     '3',
                                                     'Erro25:' ||
                                                     VSMENSAGEMREDSIMPLESNAC,
                                                     NULL);

                                    GVET_REGITEM(J).CODRETORNOS := GVET_REGITEM(J).CODRETORNOS || ';' || 93;
                                 END IF;
                              END IF;
                           END IF;

                           GVET_REGITEM(J).PERCDESCPIS := 0;
                           GVET_REGITEM(J).VLDESCREDUCAOPIS := 0;
                           GVET_REGITEM(J).PERCDESCCOFINS := 0;
                           GVET_REGITEM(J).VLDESCREDUCAOCOFINS := 0;

                           GVET_REGORIGEMPRECO(J).PERCDESCPIS := 0;
                           GVET_REGORIGEMPRECO(J).VLDESCREDUCAOPIS := 0;
                           GVET_REGORIGEMPRECO(J).PERCDESCCOFINS := 0;
                           GVET_REGORIGEMPRECO(J).VLDESCREDUCAOCOFINS := 0;

                           IF (REGCLIENTE.ORGAOPUB = 'S') OR (REGCLIENTE.ORGAOPUBFEDERAL = 'S') THEN
                              IF REGCLIENTE.ISENCAOSUFRAMA <> 'P' THEN
                                 -- PIS
                                 GVET_REGITEM(J).VLDESCREDUCAOPIS := ((GVET_REGITEM(J).PVENDA - NVL(GVET_REGITEM(J).ST, 0) - NVL(GVET_REGITEM(J).VLIPI, 0))) *
                                                                     (NVL(REGPRECOS.PERCDESCPIS, 0) / 100);
                                 GVET_REGITEM(J).VLDESCREDUCAOPIS := ROUND(GVET_REGITEM(J).VLDESCREDUCAOPIS, GREGPCCONSUM.NUMCASASDECVENDA);
                                 GVET_REGITEM(J).PERCDESCPIS := REGPRECOS.PERCDESCPIS;
                                 -- Cofins
                                 GVET_REGITEM(J).VLDESCREDUCAOCOFINS := ((GVET_REGITEM(J).PVENDA - NVL(GVET_REGITEM(J).ST,0) - NVL(GVET_REGITEM(J).VLIPI, 0))) * 
                                                                        (NVL(REGPRECOS.PERCDESCCOFINS,0) / 100);
                                 GVET_REGITEM(J).VLDESCREDUCAOCOFINS := ROUND(GVET_REGITEM(J).VLDESCREDUCAOCOFINS, GREGPCCONSUM.NUMCASASDECVENDA);
                                 GVET_REGITEM(J).PERCDESCCOFINS := REGPRECOS.PERCDESCCOFINS;
                                 GVET_REGORIGEMPRECO(J).PERCDESCPIS := GVET_REGITEM(J).PERCDESCPIS;
                                 GVET_REGORIGEMPRECO(J).VLDESCREDUCAOPIS := GVET_REGITEM(J).VLDESCREDUCAOPIS;
                                 GVET_REGORIGEMPRECO(J).PERCDESCCOFINS := GVET_REGITEM(J).PERCDESCCOFINS;
                                 GVET_REGORIGEMPRECO(J).VLDESCREDUCAOCOFINS := GVET_REGITEM(J).VLDESCREDUCAOCOFINS;
                              END IF;
                           END IF;
                           --Cálculo do %Desc. Suframa
                           GVET_REGITEM(J).VLDESCSUFRAMA := 0;
                           VNVLDESCSUFRAMA := 0;

                           IF TRIM(REGCLIENTE.SUFRAMA) IS NOT NULL THEN
                              VNVLDESCSUFRAMA := ((GVET_REGITEM(J).PVENDA - GVET_REGITEM(J).ST - 0) * (GVET_REGPEDIDO(I).PERCVENDA / 100)) * 
                                                 (NVL(REGPRECOS.PERDESCSUFRAMA, 0) / 100);

                              IF GREGPCCONSUM.TIPOCALCSULFRAMA = 'T2' THEN
                                 --Calcular ST - Truncar com 2 casas decimais
                                 VNVLDESCSUFRAMA := TRUNC((VNVLDESCSUFRAMA) * 100) / 100;
                              ELSIF GREGPCCONSUM.TIPOCALCSULFRAMA = 'A2' THEN
                                 --Calcular ST - Arredondar com 2 casas decimais
                                 VNVLDESCSUFRAMA := ROUND((VNVLDESCSUFRAMA) * 100) / 100;
                              ELSIF GREGPCCONSUM.TIPOCALCSULFRAMA = 'PV' THEN
                                 --Calcular ST - Conf. Casas Dec. Venda
                                 VNVLDESCSUFRAMA := ROUND(VNVLDESCSUFRAMA, GREGPCCONSUM.NUMCASASDECVENDA);
                              END IF;

                              GVET_REGITEM(J).VLDESCSUFRAMA := VNVLDESCSUFRAMA;
                              GVET_REGORIGEMPRECO(J).VLSUFRAMA := GVET_REGITEM(J).VLDESCSUFRAMA;
                              GVET_REGITEM(J).PVENDA := ROUND(GVET_REGITEM(J).PVENDA - GVET_REGITEM(J).VLDESCSUFRAMA, GREGPCCONSUM.NUMCASASDECVENDA);
                              REGPRODUTO.PTABELA := ROUND(REGPRODUTO.PTABELA - GVET_REGITEM(J).VLDESCSUFRAMA, GREGPCCONSUM.NUMCASASDECVENDA);
                              GVET_REGITEM(J).PBASERCA := ROUND(GVET_REGITEM(J).PBASERCA - GVET_REGITEM(J).VLDESCSUFRAMA, GREGPCCONSUM.NUMCASASDECVENDA);
                           END IF;

                           IF REGCLIENTE.TIPODESCISENCAO = 'C' THEN
                              VNPERDESCISENTOICMS := REGCLIENTE.PERDESCISENTOICMS;
                           ELSIF REGCLIENTE.TIPODESCISENCAO = 'T' THEN
                              VNPERDESCISENTOICMS := REGPRECOS.PERDESCICMISENCAO;
                           ELSE
                              VNPERDESCISENTOICMS := 0;
                           END IF;

                           IF (REGCLIENTE.ORGAOPUB = 'S') OR (REGCLIENTE.USADESCONTOICMS = 'S') OR
                              (REGCLIENTE.ORGAOPUBFEDERAL = 'S') OR TRIM(REGCLIENTE.SUFRAMA) IS NOT NULL THEN
                              IF REGCLIENTE.ISENCAOSUFRAMA = 'I' THEN
                                 VNPERDESCISENTOICMS := 0;
                                 GVET_REGITEM(J).VLDESCICMISENCAO := 0;
                              END IF;
                           END IF;

                           IF GVET_REGPEDIDO(I).PRAZOMEDIO > 0 THEN
                              IF REGPRECOS.USAISENCAOICMSVP = 'N' THEN
                                 VNPERDESCISENTOICMS := 0;
                                 GVET_REGITEM(J).VLDESCICMISENCAO := 0;
                              END IF;
                           END IF;

                           IF NVL(VNPERDESCISENTOICMS, 0) > 0 THEN
                              GVET_REGITEM(J).VLDESCICMISENCAO := ((GVET_REGITEM(J).PVENDA - GVET_REGITEM(J).ST - 0) * (GVET_REGPEDIDO(I).PERCVENDA / 100)) *
                                                                  (VNPERDESCISENTOICMS / 100);
                              GVET_REGITEM(J).PVENDA := ROUND(GVET_REGITEM(J).PVENDA - GVET_REGITEM(J).VLDESCICMISENCAO, GREGPCCONSUM.NUMCASASDECVENDA);
                              REGPRODUTO.PTABELA := ROUND(REGPRODUTO.PTABELA - GVET_REGITEM(J).VLDESCICMISENCAO, GREGPCCONSUM.NUMCASASDECVENDA);
                              GVET_REGITEM(J).PBASERCA := ROUND(GVET_REGITEM(J).PBASERCA - GVET_REGITEM(J).VLDESCICMISENCAO, GREGPCCONSUM.NUMCASASDECVENDA);
                           END IF;

                           GVET_REGITEM(J).PERDESCISENTOICMS := NVL(VNPERDESCISENTOICMS, 0);
                           GVET_REGORIGEMPRECO(J).VLDESCICMS := GVET_REGITEM(J).VLDESCICMISENCAO;
                           GVET_REGORIGEMPRECO(J).VLIPI := GVET_REGITEM(J).VLIPI;

                           IF NVL(REGPRECOS.CODICMTABPF,0) = 0 THEN
                              VBCODICMTABPF := TRUE;
                           ELSE
                              VBCODICMTABPF := FALSE;
                           END IF;
                           -- CMV sem comissao
                           FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                                                     GREGPCCONSUM.APLICARINDICECMV,
                                                     GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                                                     NVL(GREGPCCONSUM.TXVENDA, 0),
                                                     REGCLIENTE.TIPOFJ,
                                                     REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                                     REGCLIENTE.IEENT,
                                                     REGPRODUTO.FRETEESPECIAL,
                                                     REGREGIAO.PERFRETETERCEIROS,
                                                     REGREGIAO.PERFRETEESPECIAL,
                                                     REGPRECOS.CUSTOFIN,
                                                     REGPRECOS.CUSTOREAL,
                                                     REGPRECOS.PERDESCCUSTO,
                                                     REGPRECOS.CODICMTAB,
                                                     VBCODICMTABPF,
                                                     REGPRECOS.CODICMTABPF,
                                                     GVET_REGPEDIDO(I).PERCVENDA,
                                                     GVET_REGITEM(J).PVENDA,
                                                     0,
                                                     GVET_REGITEM(J).ST, --20
                                                     0,
                                                     GVET_REGITEM(J).VLIPI,
                                                     0,
                                                     REGCLIENTE.CONTRIBUINTE,
                                                     0,
                                                     NVL(VNVLREDPVENDASIMPLESNA, 0),
                                                     REGCLIENTE.CONSUMIDORFINAL,
                                                     NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,'N'),
                                                     GVET_REGITEM(J).PERFRETECMV,
                                                     GVET_REGITEM(J).CUSTOFINEST, --30
                                                     GVET_REGITEM(J).TXVENDA,
                                                     GVET_REGITEM(J).PERDESCCUSTO,
                                                     GVET_REGITEM(J).CODICMTAB,
                                                     GVET_REGITEM(J).VLCUSTOREAL,
                                                     GVET_REGITEM(J).VLCUSTOFIN,
                                                     GVET_REGITEM(J).VLDESCCUSTOCMV,
                                                     REGCLIENTE.CODCLI,
                                                     0,
                                                     FALSE,
                                                     FALSE, --40
                                                     0,
                                                     0,
                                                     0,
                                                     0,
                                                     REGFILIAL.CODIGO,
                                                     0,
                                                     0,
                                                     0,
                                                     0,
                                                     0);
                           VNPERLUC := 0;
                           IF NVL(GVET_REGITEM(J).PVENDA,0) <> 0 THEN
                              VNPERLUC := ((GVET_REGITEM(J).PVENDA - GVET_REGITEM(J).VLCUSTOFIN) / GVET_REGITEM(J).PVENDA) * 100;
                           END IF;
                           -- busca percentual de comissao
                           VSMENSAGEM_COMISS := NULL;

                           SELECT COUNT(*) INTO VICONT FROM PCTABCOMISS P;

                           IF VICONT <> 0 THEN
                              VBUSAPCTABCOMISS := TRUE;
                           ELSE
                              VBUSAPCTABCOMISS := FALSE;
                           END IF;

                           SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOUSUR P;

                           IF VICONT <> 0 THEN
                              VBUSAPCCOMISSAOUSUR := TRUE;
                           ELSE
                              VBUSAPCCOMISSAOUSUR := FALSE;
                           END IF;

                           SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOPLPAG P;
                           
                           IF VICONT <> 0 THEN
                              VBUSAPCCOMISSAOPLPAG := TRUE;
                           ELSE
                              VBUSAPCCOMISSAOPLPAG := FALSE;
                           END IF;

                           SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOREGIAO P;

                           IF VICONT <> 0 THEN
                              VBUSAPCCOMISSAOREGIAO := TRUE;
                           ELSE
                              VBUSAPCCOMISSAOREGIAO := FALSE;
                           END IF;

                           IF REGFILIAL.BROKER = 'S' THEN
                              VBUSAPCCOMISSAOFILIAL := TRUE;
                           ELSE
                              VBUSAPCCOMISSAOFILIAL := FALSE;
                           END IF;

                           GVET_REGITEM(J).PERCOM := FUNCOESVENDAS.DEFINIR_COMISSAO_ITEM_VENDIDO(REGREGIAO.NUMREGIAO,
                                                                                                 VNPERLUC,
                                                                                                 GVET_REGITEM(J).PERDESC,
                                                                                                 VBUSAPCTABCOMISS,
                                                                                                 VBUSAPCCOMISSAOUSUR,
                                                                                                 VBUSAPCCOMISSAOPLPAG,
                                                                                                 VBUSAPCCOMISSAOREGIAO,
                                                                                                 VBUSAPCCOMISSAOFILIAL,
                                                                                                 GREGPCCONSUM.USACOMISSAOPORRCA,
                                                                                                 GREGPCCONSUM.ORDEMAVALIACAOCOMISSAORCA,
                                                                                                 GREGPCCONSUM.USACOMISSAOPORCLIENTE,
                                                                                                 GREGPCCONSUM.USACOMISSAOPORLINHAPROD,
                                                                                                 GREGPCCONSUM.COMISSAORCATIPOVENDA,
                                                                                                 REGRCA.TIPOVEND,
                                                                                                 REGRCA.PERCENT,
                                                                                                 REGRCA.PERCENT2,
                                                                                                 REGPRODUTO.CODPROD,
                                                                                                 REGPRODUTO.PCOMINT1,
                                                                                                 REGPRODUTO.PCOMEXT1,
                                                                                                 REGPRODUTO.PCOMREP1,
                                                                                                 REGPRODUTO.CODLINHAPROD,
                                                                                                 REGPRODUTO.TIPOCOMISSAO,
                                                                                                 REGPRODUTO.CODEPTO,
                                                                                                 REGPRODUTO.CODSEC,
                                                                                                 REGPRODUTO.CLASSE,
                                                                                                 REGPLPAG.TIPOVENDA,
                                                                                                 GVET_REGPEDIDO(I).CODPLPAG,
                                                                                                 GVET_REGPEDIDO(I).DATA,
                                                                                                 GVET_REGPEDIDO(I).CODFILIAL,
                                                                                                 GVET_REGPEDIDO(I).CODUSUR,
                                                                                                 REGFILIAL.CONSIDERARCOMISSAOZERO,
                                                                                                 REGFILIAL.TIPOAVALIACAOCOMISSAO,
                                                                                                 REGCLIENTE.PERCOMCLI,
                                                                                                 REGCLIENTE.CODCLI,
                                                                                                 GVET_REGITEM(J).CODDESCONTO,
                                                                                                 GVET_REGORIGEMCOMISS(J).CODCOMIS,
                                                                                                 GVET_REGORIGEMCOMISS(J).CODROTINACOMIS,
                                                                                                 GVET_REGITEM(J).LETRACOMISS,
                                                                                                 VSMENSAGEM_COMISS,
                                                                                                 GVET_REGITEM(J).CODAUXILIAR,
                                                                                                 REGPRECOS.PCOMINT1_EMB,
                                                                                                 REGPRECOS.PCOMEXT1_EMB,
                                                                                                 REGPRECOS.PCOMREP1_EMB,
                                                                                                 REGFILIAL.UTILIZAVENDAPOREMBALAGEM);
                           GVET_REGORIGEMCOMISS(J).PERCOM := GVET_REGITEM(J).PERCOM;
                           GVET_REGORIGEMCOMISS(J).PERDESC := GVET_REGITEM(J).PERDESC;
                           GVET_REGORIGEMCOMISS(J).TIPOCOMISSAO := REGPRODUTO.TIPOCOMISSAO;
                           GVET_REGORIGEMCOMISS(J).CODLINHAPROD := REGPRODUTO.CODLINHAPROD;
                           GVET_REGORIGEMCOMISS(J).ORDEMAVALIACAOCOMISSAORCA := GREGPCCONSUM.ORDEMAVALIACAOCOMISSAORCA;
                           GVET_REGORIGEMCOMISS(J).USACOMISSAOPORRCA := GREGPCCONSUM.USACOMISSAOPORRCA;
                           GVET_REGORIGEMCOMISS(J).USACOMISSAOPORCLIENTE := GREGPCCONSUM.USACOMISSAOPORCLIENTE;
                           GVET_REGORIGEMCOMISS(J).USACOMISSAOPORLINHAPROD := GREGPCCONSUM.USACOMISSAOPORLINHAPROD;
                           GVET_REGORIGEMCOMISS(J).COMISSAORCATIPOVENDA := GREGPCCONSUM.COMISSAORCATIPOVENDA;

                           IF VSMENSAGEM_COMISS IS NOT NULL THEN
                              PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                               GVET_REGPEDIDO(I).NUMPEDINT,
                                               GVET_REGITEM(J).CODPROD,
                                               GVET_REGITEM(J).CODAUXILIAR,
                                               GVET_REGITEM(J).NUMSEQORIG,
                                               GVET_REGPEDIDO(I).CODCLI,
                                               GVET_REGPEDIDO(I).CODUSUR,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).INTEGRADORA,
                                               94,
                                               '3',
                                               'Erro26:' || VSMENSAGEM_COMISS,
                                               NULL);
                           END IF;

                           IF GVET_REGPEDIDO(I).CONDVENDA = 20 THEN
                              GVET_REGITEM(J).PERCOM := 0;
                           END IF;

                           FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
                                                     GREGPCCONSUM.APLICARINDICECMV,
                                                     GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
                                                     NVL(GREGPCCONSUM.TXVENDA, 0),
                                                     REGCLIENTE.TIPOFJ,
                                                     REGCLIENTE.UTILIZAIESIMPLIFICADA,
                                                     REGCLIENTE.IEENT,
                                                     REGPRODUTO.FRETEESPECIAL,
                                                     REGREGIAO.PERFRETETERCEIROS,
                                                     REGREGIAO.PERFRETEESPECIAL,
                                                     REGPRECOS.CUSTOFIN,
                                                     REGPRECOS.CUSTOREAL,
                                                     REGPRECOS.PERDESCCUSTO,
                                                     REGPRECOS.CODICMTAB,
                                                     VBCODICMTABPF,
                                                     REGPRECOS.CODICMTABPF,
                                                     GVET_REGPEDIDO(I).PERCVENDA,
                                                     GVET_REGITEM(J).PVENDA,
                                                     GVET_REGITEM(J).PERCOM,
                                                     GVET_REGITEM(J).ST, -- 20
                                                     0,
                                                     GVET_REGITEM(J).VLIPI,
                                                     0,
                                                     REGCLIENTE.CONTRIBUINTE,
                                                     0,
                                                     NVL(GVET_REGITEM(J).VLREDPVENDASIMPLESNA, 0),
                                                     REGCLIENTE.CONSUMIDORFINAL,
                                                     NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
                                                     GVET_REGITEM(J).PERFRETECMV,
                                                     GVET_REGITEM(J).CUSTOFINEST,
                                                     GVET_REGITEM(J).TXVENDA,
                                                     GVET_REGITEM(J).PERDESCCUSTO,
                                                     GVET_REGITEM(J).CODICMTAB,
                                                     GVET_REGITEM(J).VLCUSTOREAL,
                                                     GVET_REGITEM(J).VLCUSTOFIN,
                                                     GVET_REGITEM(J).VLDESCCUSTOCMV,
                                                     REGCLIENTE.CODCLI,
                                                     0,
                                                     FALSE,
                                                     FALSE, --40
                                                     0,
                                                     0,
                                                     0,
                                                     0,
                                                     REGFILIAL.CODIGO,
                                                     0,
                                                     0,
                                                     0,
                                                     0,
                                                     0);

                           IF REGCLIENTE.SIMPLESNACIONAL = 'S' AND
                              REGPRECOS.PERCREDPVENDASIMPLESNAC <> 0 AND GVET_REGITEM(J).APLICADESCONTOSIMPLES = 'S' THEN
                              --só atualiza caso não tenha impostos
                              IF (REGPRECOS.ALIQICMS1 <= REGPRECOS.ALIQICMS2) AND REGPRECOS.PAUTA = 0 AND REGPRECOS.IVA = 0 THEN
                                 VNPTABELA := REGPRODUTO.PTABELA;

                                 GVET_REGITEM(J).PVENDA := ROUND(REGPRODUTO.PTABELA - NVL(GVET_REGITEM(J).VLREDPVENDASIMPLESNA, 0), GREGPCCONSUM.NUMCASASDECVENDA);
                                 GVET_REGITEM(J).PBASERCA := ROUND(REGPRODUTO.PTABELA - NVL(GVET_REGITEM(J).VLREDPVENDASIMPLESNA, 0), GREGPCCONSUM.NUMCASASDECVENDA);
                                 --preço de venda precisa ser recalculado, por que o desconto comercial
                                 --tem que ser efetuado depois da redução do simples nacional
                                 IF VNPERCDESCCOM <> 0 THEN
                                    GVET_REGITEM(J).PVENDA := ROUND(GVET_REGITEM(J).PVENDA - (GVET_REGITEM(J).PVENDA * (VNPERCDESCCOM / 100)), GREGPCCONSUM.NUMCASASDECVENDA);
                                 END IF;

                                 IF VNPERCDESCRCA <> 0 THEN
                                    GVET_REGITEM(J).PBASERCA := ROUND(GVET_REGITEM(J).PBASERCA - (GVET_REGITEM(J).PBASERCA * (VNPERCDESCRCA / 100)), GREGPCCONSUM.NUMCASASDECVENDA);
                                 END IF;

                                 REGPRODUTO.PTABELA := ROUND(REGPRODUTO.PTABELA - NVL(GVET_REGITEM(J).VLREDPVENDASIMPLESNA, 0), GREGPCCONSUM.NUMCASASDECVENDA);
                                 --recalcular vlcustofin para que o percentual de lucratividade seja o mesmo se não tivesse tido redução de simples
                                 VNVLCUSTOFIN := GVET_REGITEM(J).PVENDA - ((VNPERLUCSEMRED / 100) * GVET_REGITEM(J).PVENDA);
                                 GVET_REGITEM(J).VLREDCMVSIMPLESNAC := VNVLCUSTOFINSEMIMPOSTOS - VNVLCUSTOFIN;
                                 --calculando o percentual de diferença para retirar o vlcustoreal
                                 VNPERCDIF := 0;
                                 IF NVL(GVET_REGITEM(J).VLCUSTOFIN,0) <> 0 THEN
                                    VNPERCDIF := ((VNVLCUSTOFIN * 100) / GVET_REGITEM(J).VLCUSTOFIN) - 100;
                                 END IF;

                                 GVET_REGITEM(J).VLCUSTOFIN := VNVLCUSTOFIN;
                                 GVET_REGITEM(J).VLCUSTOREAL := GVET_REGITEM(J).VLCUSTOREAL + (GVET_REGITEM(J).VLCUSTOREAL * (VNPERCDIF / 100));
                              END IF;
                           END IF;

                           VNPERCVERBACMV := NULL;
                           VBVALIDOVERBACMV := FUNCOESVENDAS.CALCULARPERCVERBACMV(GVET_REGITEM(J).CODPROD,
                                                                                  REGPRODUTO.CODSEC,
                                                                                  REGPRODUTO.CODEPTO,
                                                                                  GVET_REGPEDIDO(I).DATA,
                                                                                  GVET_REGPEDIDO(I).CODCLI,
                                                                                  GREGPCCONSUM.NUMCASASDECVENDA,
                                                                                  VSMENSAGEMVERBACMV,
                                                                                  VNPERCVERBACMV);
                           IF VSMENSAGEMVERBACMV IS NOT NULL AND SUBSTR(VSMENSAGEMVERBACMV, 1, 1) NOT IN ('S', 'N') THEN
                              PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                               GVET_REGPEDIDO(I).NUMPEDINT,
                                               GVET_REGITEM(J).CODPROD,
                                               GVET_REGITEM(J).CODAUXILIAR,
                                               GVET_REGITEM(J).NUMSEQORIG,
                                               GVET_REGPEDIDO(I).CODCLI,
                                               GVET_REGPEDIDO(I).CODUSUR,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).INTEGRADORA,
                                               95,
                                               '2',
                                               'Erro27:' || VSMENSAGEMVERBACMV,
                                               NULL);
                           END IF;

                           IF NVL(VNPERCVERBACMV, 0) <> 0 THEN
                              GVET_REGITEM(J).VLVERBACMV := GVET_REGITEM(J).PVENDA * (VNPERCVERBACMV / 100);
                              GVET_REGITEM(J).VLCUSTOFIN := GVET_REGITEM(J).VLCUSTOFIN + GVET_REGITEM(J).VLVERBACMV;
                              GVET_REGITEM(J).VLCUSTOREAL := GVET_REGITEM(J).VLCUSTOREAL + GVET_REGITEM(J).VLVERBACMV;
                           END IF;

                           IF GVET_REGITEM(J).VALIDO = TRUE THEN
                              -- insere item do pedido
                              VNNUMSEQ := VNNUMSEQ + 1;
                              GVET_REGITEM(J).NUMSEQ := VNNUMSEQ;
                              GVET_REGORIGEMPRECO(J).NUMSEQ := VNNUMSEQ;
                              GVET_REGORIGEMCOMISS(J).NUMSEQ := VNNUMSEQ;
                              GVET_REGORIGEMDESC(J).NUMSEQ := VNNUMSEQ;

                              VNTOTPESOPED := VNTOTPESOPED + (REGPRODUTO.PESOBRUTO * GVET_REGITEM(J).QT);
                              VNTOTVOLUMEPED := VNTOTVOLUMEPED + (REGPRODUTO.VOLUME * GVET_REGITEM(J).QT);
                              GVET_REGITEM(J).VALIDO := FUNC_INSERIRITEMPEDIDO(GVET_REGPEDIDO(I),
                                                                               GVET_REGITEM(J),
                                                                               REGPRECOS,
                                                                               REGPRODUTO,
                                                                               REGRCA,
                                                                               REGPLPAG,
                                                                               REGCLIENTE,
                                                                               REGREGIAO,
                                                                               REGFILIAL,
                                                                               GVET_REGORIGEMPRECO(J),
                                                                               GVET_REGORIGEMCOMISS(J),
                                                                               GVET_REGORIGEMDESC(J));
                           END IF;
                        END IF;
                     END IF;
                  EXCEPTION WHEN OTHERS THEN
                     GVET_REGPEDIDO(I).VALIDO := FALSE;
                     
                     PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                      GVET_REGPEDIDO(I).NUMPEDINT,
                                      GVET_REGITEM(J).CODPROD,
                                      GVET_REGITEM(J).CODAUXILIAR,
                                      GVET_REGITEM(J).NUMSEQORIG,
                                      GVET_REGPEDIDO(I).CODCLI,
                                      GVET_REGPEDIDO(I).CODUSUR,
                                      NULL,
                                      NULL,
                                      GVET_REGPEDIDO(I).INTEGRADORA,
                                      NULL,
                                      '2',
                                      'Erro28:' || SQLCODE || '-' || SQLERRM || ';',
                                      NULL);
                     EXIT;
                  END;
               END LOOP; -- FOR j IN 1 .. vncontitem

               -- verifica se ha itens no pedido
               SELECT COUNT(*),
                      SUM(PCPEDI.QT * PCPEDI.PVENDA),
                      SUM(PCPEDI.QT * PCPEDI.PTABELA),
                      SUM(PCPEDI.QT * PCPEDI.PBASERCA),
                      SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT),
                      SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN),
                      SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL),
                      SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP)
               INTO VNCONTITENSVALIDOS,
                    VNVLTOTPED,
                    VNVLTOTTAB,
                    VNVLTOTBASERCA,
                    VNVLCUSTOCONTPED,
                    VNVLCUSTOFINPED,
                    VNVLCUSTOREALPED,
                    VNVLCUSTOREPPED
               FROM PCPEDI
               WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

               IF VNCONTITENSVALIDOS <> 0 THEN
                  IF REGFILIAL.BROKER = 'N' THEN
                     IF GVET_REGPEDIDO(I).CONDVENDA <> 7 THEN
                        PROC_VERIFICAESTOQUE(GVET_REGPEDIDO(I), REGFILIAL, REGCLIENTE, VNMAXNUMSEQ);
                     END IF;
                  END IF;

                  IF GVET_REGPEDIDO(I).USASALDOCONTACORRENTEDESCFIN = 'N' THEN
                     VNVLSALDOPED := 0;

                     FOR REG_ITENS IN (SELECT CODPROD,
                                              NUMSEQ,
                                              QT,
                                              NUMAPLIC NUMSEQORIG,
                                              CODAUXILIAR,
                                              PC_PKG_CONTROLARSALDORCA.CCRCA_SALDO_ITEM(GREGPCCONSUM.USACREDRCA,
                                                                                        GVET_REGPEDIDO(I).USADEBCREDRCA,
                                                                                        'N',
                                                                                        GVET_REGPEDIDO(I).ORIGEMPED,
                                                                                        GREGPCCONSUM.BONIFICALTDEBCREDRCA,
                                                                                        GREGPCCONSUM.TROCAALTDEBCREDRCA,
                                                                                        GREGPCCONSUM.CRMALTDEBCREDRCA,
                                                                                        GREGPCCONSUM.BROKERALTDEBCREDRCA,
                                                                                        GREGPCCONSUM.TIPOMOVCCRCA,
                                                                                        GVET_REGPEDIDO(I).CONDVENDA,
                                                                                        'N',
                                                                                        GVET_REGPEDIDO(I).CODUSUR,
                                                                                        'V',
                                                                                        PCPEDI.PVENDA,
                                                                                        PCPEDI.PTABELA,
                                                                                        PCPEDI.PBASERCA,
                                                                                        (PCPEDI.QT - DECODE(GVET_REGPEDIDO(I).POSICAO, 'B', 0, NVL(PCPEDI.QTFALTA, 0)))
                                                                                       ) SALDO
                                       FROM PCPEDI
                                       WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED
                                         AND NVL(MOVIMENTACONTACORRENTERCA,'N') = 'S'
                                       ORDER BY SALDO DESC) 
                     LOOP
                        VNVLDISPONIVEL := PC_PKG_CONTROLARSALDORCA.CCRCA_CHECAR_DISPONIVEL_ATUAL(GVET_REGPEDIDO(I).CODUSUR);

                        IF (VNVLDISPONIVEL + REG_ITENS.SALDO + VNVLSALDOPED < 0) AND REG_ITENS.SALDO < 0 THEN
                           PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                            GVET_REGPEDIDO(I).NUMPEDINT,
                                            REG_ITENS.CODPROD,
                                            REG_ITENS.CODAUXILIAR,
                                            REG_ITENS.NUMSEQORIG,
                                            GVET_REGPEDIDO(I).CODCLI,
                                            GVET_REGPEDIDO(I).CODUSUR,
                                            NULL,
                                            NULL,
                                            GVET_REGPEDIDO(I).INTEGRADORA,
                                            96,
                                            '3',
                                            'Rca sem credito disponivel' || ';',
                                            NULL);

                           IF REGFILIAL.TIPOIMPORTACAOVENDA = 'RI' THEN
                              DELETE FROM PCPEDI
                              WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED
                                AND CODPROD = REG_ITENS.CODPROD
                                AND NUMSEQ = REG_ITENS.NUMSEQ;
                           ELSIF REGFILIAL.TIPOIMPORTACAOVENDA = 'RP' THEN
                              GVET_REGPEDIDO(I).VALIDO := FALSE;

                              PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                               GVET_REGPEDIDO(I).NUMPEDINT,
                                               NULL,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).CODCLI,
                                               GVET_REGPEDIDO(I).CODUSUR,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).INTEGRADORA,
                                               96,
                                               '2',
                                               'Rca sem credito disponivel' || ';',
                                               NULL);
                           ELSIF REGFILIAL.TIPOIMPORTACAOVENDA = 'BP' THEN
                              GVET_REGPEDIDO(I).POSICAO := 'B';
                              GVET_REGPEDIDO(I).MOTIVOPOSICAO := 'Rca sem credito disopnivel';
 
                              IF GVET_REGPEDIDO(I).POSICAO = 'B' THEN
                                 PROC_BLOQUEIA_PEDIDO(GVET_REGPEDIDO(I).NUMPED, GVET_REGPEDIDO(I).MOTIVOPOSICAO);
                              END IF;
                           END IF;
                        ELSE
                           VNVLSALDOPED := VNVLSALDOPED + REG_ITENS.SALDO;
                        END IF;
                     END LOOP;
                  END IF;
               END IF;

               SELECT COUNT(*),
                   SUM(PCPEDI.QT * PCPEDI.PVENDA),
                   SUM(PCPEDI.QT * PCPEDI.PTABELA),
                   SUM(PCPEDI.QT * PCPEDI.PBASERCA),
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT),
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN),
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL),
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP)
               INTO VNCONTITENSVALIDOS,
                   VNVLTOTPED,
                   VNVLTOTTAB,
                   VNVLTOTBASERCA,
                   VNVLCUSTOCONTPED,
                   VNVLCUSTOFINPED,
                   VNVLCUSTOREALPED,
                   VNVLCUSTOREPPED
               FROM PCPEDI
               WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

               IF VNCONTITENSVALIDOS > 0 THEN
                  FOR REG_BLOQ IN (SELECT DISTINCT PCMOTBLOQUEIO.CODMOTIVO
                                         ,PCMOTBLOQUEIO.DESCRICAO
                                         ,PCBLOQUEIO.CODMOTBLOQUEIO
                                   FROM PCMOTBLOQUEIO
                                       ,PCBLOQUEIO
                                   WHERE PCBLOQUEIO.CODMOTIVO = PCMOTBLOQUEIO.CODMOTIVO
                                     AND PCBLOQUEIO.CODMOTIVO IS NOT NULL
                                     AND (PCBLOQUEIO.ORIGEMPED = GVET_REGPEDIDO(I).ORIGEMPED)
                                     AND (PCBLOQUEIO.CONDVENDA = GVET_REGPEDIDO(I).CONDVENDA OR PCBLOQUEIO.CONDVENDA IS NULL)
                                     AND (PCBLOQUEIO.CODCOB = GVET_REGPEDIDO(I).CODCOB OR PCBLOQUEIO.CODCOB IS NULL)
									 AND (PCBLOQUEIO.MATRICULAEMPR = GVET_REGPEDIDO(I).CODEMITENTE OR PCBLOQUEIO.CODEMITENTE IS NULL))
                  LOOP
                     PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(GVET_REGPEDIDO(I).NUMPED,
                                                     REG_BLOQ.CODMOTIVO,
                                                     SUBSTR(REG_BLOQ.DESCRICAO,1,60),
                                                     'C',
                                                     null);
                     BEGIN
                        SELECT NVL(CODMOTIVO, PCBLOQUEIOSPEDIDO.CODMOTBLOQUEIO) CODMOTIVO,
                               MOTIVO,
                               STATUS
                        INTO VNCODMOTIVO,
                             VSMOTIVO,
                             VSPOSICAO
                        FROM PCBLOQUEIOSPEDIDO
                        WHERE PCBLOQUEIOSPEDIDO.NUMPED = GVET_REGPEDIDO(I).NUMPED
                          AND STATUS = 'B'
                          AND ROWNUM = 1;
                     EXCEPTION WHEN NO_DATA_FOUND THEN
                        vncodmotivo := 0;
                        VSPOSICAO   := UPPER(TRIM(GVET_REGPEDIDO(I).POSICAO));
                     END;

                     IF VSPOSICAO = 'B' THEN
                        GVET_REGPEDIDO(I).POSICAO := VSPOSICAO;--'B';
                        GVET_REGPEDIDO(I).CODMOTIVO := REG_BLOQ.CODMOTIVO;
                        GVET_REGPEDIDO(I).CODMOTBLOQUEIO := REG_BLOQ.CODMOTBLOQUEIO;
                        GVET_REGPEDIDO(I).MOTIVOPOSICAO := SUBSTR(REG_BLOQ.DESCRICAO,1,60);
                        GVET_REGPEDIDO(I).LOG := GVET_REGPEDIDO(I).LOG || CHR(13) ||REG_BLOQ.DESCRICAO;
                     END IF;
                  END LOOP;

                  IF GVET_REGPEDIDO(I).CONDVENDA < 4 OR
                     ((NVL(GREGPCCONSUM.BONIFICALTDEBCREDRCA,'N') = 'S') AND GVET_REGPEDIDO(I).CONDVENDA IN (5,6,11,12)) THEN
                     IF NVL(REGFILIAL.BROKER,'N') = 'N' THEN
                        -- faz validacao final do cabecalho
                        PROC_VALIDACAOFINALCAB(GVET_REGPEDIDO(I),
                                               REGCLIENTE,
                                               REGPLPAG,
                                               REGCOB,
                                               REGFILIAL,
                                               REGRCA,
                                               VNCONTITENSVALIDOS,
                                               VNVLTOTPED,
                                               VNVLTOTPED_ANT,
                                               VNVLTOTTAB,
                                               VNVLCUSTOFINPED);
                     END IF;

                     IF REGPLPAG.FORMAPARCELAMENTO = 'V' AND GVET_REGPEDIDO(I).PERCPLPAG IS NOT NULL THEN
                        UPDATE PCPEDI
                        SET PVENDA   = ROUND(PVENDA * (1 + (GVET_REGPEDIDO(I).PERCPLPAG / 100)), GREGPCCONSUM.NUMCASASDECVENDA),
                            PTABELA  = ROUND(PTABELA * (1 + (GVET_REGPEDIDO(I).PERCPLPAG / 100)), GREGPCCONSUM.NUMCASASDECVENDA),
                            PBASERCA = ROUND(PBASERCA * (1 + (GVET_REGPEDIDO(I).PERCPLPAG / 100)), GREGPCCONSUM.NUMCASASDECVENDA)
                        WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;
                          END IF;
                  END IF;
               ELSE
                  GVET_REGPEDIDO(I).VALIDO := FALSE;
                  PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                   GVET_REGPEDIDO(I).NUMPEDINT,
                                   NULL,
                                   NULL,
                                   NULL,
                                   GVET_REGPEDIDO(I).CODCLI,
                                   GVET_REGPEDIDO(I).CODUSUR,
                                   NULL,
                                   NULL,
                                   GVET_REGPEDIDO(I).INTEGRADORA,
                                   59,
                                   '2',
                                   'Nenhum item gravado;',
                                   NULL);
               END IF;

               IF GVET_REGPEDIDO(I).VALIDO = TRUE THEN
                  GVET_REGPEDIDO(I).VALIDO := FUNC_INSERIRCABPEDIDO(GVET_REGPEDIDO(I),
                                                                    REGPLPAG,
                                                                    REGRCA,
                                                                    REGCLIENTE,
                                                                    REGREGIAO,
                                                                    REGFILIAL,
                                                                    VNCONTITENSVALIDOS,
                                                                    VNVLTOTPED,
                                                                    VNVLTOTTAB,
                                                                    VNTOTPESOPED,
                                                                    VNTOTVOLUMEPED,
                                                                    VNVLCUSTOCONTPED,
                                                                    VNVLCUSTOFINPED,
                                                                    VNVLCUSTOREALPED,
                                                                    VNVLCUSTOREPPED,
                                                                    VSCODDISTRIB);
                  IF GVET_REGPEDIDO(I).TIPOINTEGRACAO = 'R' THEN
                     IF importarvendasmultipag.FUNC_VALIDAR_MULT_PLANOS_RCA(GVET_REGPEDIDO(I).NUMPEDRCA
                                                                           ,GVET_REGPEDIDO(I).CODUSUR
                                                                           ,GVET_REGPEDIDO(I).INTEGRADORA
                                                                           ,GVET_REGPEDIDO(I).NUMPED
                                                                           ,V_MSG_MULT_PLANO ) = FALSE THEN
                        GVET_REGPEDIDO(I).VALIDO := FALSE;

                        PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                         GVET_REGPEDIDO(I).NUMPEDINT,
                                         NULL,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).CODCLI,
                                         GVET_REGPEDIDO(I).CODUSUR,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).INTEGRADORA,
                                         96,
                                         '2',
                                         V_MSG_MULT_PLANO || ';',
                                         NULL);
                     END IF;
                  END IF;

                  IF GVET_REGPEDIDO(I).TIPOINTEGRACAO = 'C' THEN
                     IF importarvendasmultipag.FUNC_VALIDAR_MULT_PLANOS_CLI(GVET_REGPEDIDO(I).NUMPEDCLI
                                                                           ,GVET_REGPEDIDO(I).CODUSUR
                                                                           ,GVET_REGPEDIDO(I).INTEGRADORA
                                                                           ,GVET_REGPEDIDO(I).NUMPED
                                                                           ,V_MSG_MULT_PLANO ) = FALSE THEN
                        GVET_REGPEDIDO(I).VALIDO := FALSE;

                        PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                         GVET_REGPEDIDO(I).NUMPEDINT,
                                         NULL,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).CODCLI,
                                         GVET_REGPEDIDO(I).CODUSUR,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).INTEGRADORA,
                                         96,
                                         '2',
                                         V_MSG_MULT_PLANO || ';',
                                         NULL);
                     END IF;
                  END IF;

                  IF GVET_REGPEDIDO(I).TIPOINTEGRACAO = 'W' THEN
                     IF importarvendasmultipag.FUNC_VALIDAR_MULT_PLANOS_WEB(GVET_REGPEDIDO(I).NUMPEDWEB
                                                                           ,GVET_REGPEDIDO(I).CODUSUR
                                                                           ,GVET_REGPEDIDO(I).INTEGRADORA
                                                                           ,GVET_REGPEDIDO(I).NUMPED
                                                                           ,V_MSG_MULT_PLANO ) = FALSE THEN
                        GVET_REGPEDIDO(I).VALIDO := FALSE;

                        PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                         GVET_REGPEDIDO(I).NUMPEDINT,
                                         NULL,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).CODCLI,
                                         GVET_REGPEDIDO(I).CODUSUR,
                                         NULL,
                                         NULL,
                                         GVET_REGPEDIDO(I).INTEGRADORA,
                                         96,
                                         '2',
                                         V_MSG_MULT_PLANO || ';',
                                         NULL);
                     END IF;
                  END IF;

                  IF GVET_REGPEDIDO(I).POSICAO = 'B' THEN
                     PROC_BLOQUEIA_PEDIDO(GVET_REGPEDIDO(I).NUMPED, GVET_REGPEDIDO(I).MOTIVOPOSICAO);

                     UPDATE PCPEDC
                     SET POSICAO = GVET_REGPEDIDO(I).POSICAO,
                         CODMOTBLOQUEIO = GVET_REGPEDIDO(I).CODMOTBLOQUEIO,
                         CODMOTIVO = GVET_REGPEDIDO(I).CODMOTIVO,
                         MOTIVOPOSICAO = GVET_REGPEDIDO(I).MOTIVOPOSICAO
                     WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;
                  END IF;

                  IF GVET_REGPEDIDO(I).VALIDO = TRUE THEN
                     IF REGFILIAL.BROKER = 'N' THEN
                        IF GVET_REGPEDIDO(I).CONDVENDA <> 7 THEN
                           -- gravar estoque pendente/reservado
                           PROC_GRAVAESTOQUE(GVET_REGPEDIDO(I),
                                             REGFILIAL,
                                             REGRCA,
                                             REGPLPAG,
                                             REGCLIENTE,
                                             VNMAXNUMSEQ,
                                             VNVLTOTPED);
                        END IF;
                     END IF;

                  IF GVET_REGPEDIDO(I).VALIDO = TRUE THEN
                     IF GVET_REGPEDIDO(I).CONDVENDA NOT IN (5, 6, 10, 11, 12, 20) AND NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) = 0 THEN
                        IF REGFILIAL.BROKER = 'N' THEN
                           SELECT NVL(PCCLIENT.VALIDARCAMPANHABRINDE,'S') AS VALIDARCAMPANHABRINDE
                           INTO V_VALIDARCAMPANHABRINDE
                           FROM PCCLIENT
                           WHERE PCCLIENT.CODCLI = REGCLIENTE.CODCLI;

                           IF V_VALIDARCAMPANHABRINDE = 'S' THEN
                              -- apuracao de brindes.
                              APURARCAMPANHASBRINDES.PROC_APURARCAMPANHA(GVET_REGPEDIDO(I).NUMPED,
                                                                         NULL,
                                                                         NULL,
                                                                         VNNUMSEQ,
                                                                         'N',
                                                                         VSMENSAGEMBRINDE,
                                                                         VSGEROUBRINDE);
                              IF VSMENSAGEMBRINDE IS NOT NULL THEN
                                 PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                  GVET_REGPEDIDO(I).NUMPEDINT,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).CODCLI,
                                                  GVET_REGPEDIDO(I).CODUSUR,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).INTEGRADORA,
                                                  138,
                                                  '2',
                                                  'Erro29:' || VSMENSAGEMBRINDE,
                                                  NULL);

                                 GVET_REGPEDIDO(I).CODRETORNOS := GVET_REGPEDIDO(I).CODRETORNOS || ';' || 138;
                              END IF;
                           ELSE
                              PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                               GVET_REGPEDIDO(I).NUMPEDINT,
                                               NULL,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).CODCLI,
                                               GVET_REGPEDIDO(I).CODUSUR,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).INTEGRADORA,
                                               138,
                                               '2',
                                               'Não apura campanha de brinde',
                                               NULL);
                           END IF;
                        END IF;
                     END IF;

                     IF GVET_REGPEDIDO(I).USASALDOCONTACORRENTEDESCFIN = 'N' THEN
                        FOR REG_ITENS IN (SELECT CODPROD,
                                                 NUMSEQ,
                                                 QT,
                                                 PC_PKG_CONTROLARSALDORCA.CCRCA_SALDO_ITEM(GREGPCCONSUM.USACREDRCA,
                                                                                           GVET_REGPEDIDO(I).USADEBCREDRCA,
                                                                                           'N',
                                                                                           GVET_REGPEDIDO(I).ORIGEMPED,
                                                                                           GREGPCCONSUM.BONIFICALTDEBCREDRCA,
                                                                                           GREGPCCONSUM.TROCAALTDEBCREDRCA,
                                                                                           GREGPCCONSUM.CRMALTDEBCREDRCA,
                                                                                           GREGPCCONSUM.BROKERALTDEBCREDRCA,
                                                                                           GREGPCCONSUM.TIPOMOVCCRCA,
                                                                                           GVET_REGPEDIDO(I).CONDVENDA,
                                                                                           'N',
                                                                                           GVET_REGPEDIDO(I).CODUSUR,
                                                                                           'V',
                                                                                           PCPEDI.PVENDA,
                                                                                           PCPEDI.PTABELA,
                                                                                           PCPEDI.PBASERCA,
                                                                                           (PCPEDI.QT - DECODE(GVET_REGPEDIDO(I).POSICAO, 'B', 0, NVL(PCPEDI.QTFALTA, 0)))
                                                                                          ) SALDO
                                          FROM PCPEDI
                                          WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED
                                            AND NVL(MOVIMENTACONTACORRENTERCA,'N') = 'S'
                                          ORDER BY SALDO DESC) 
                        LOOP
                           VBSALDORCA := PC_PKG_CONTROLARSALDORCA.CCRCA_INCLUIR_ITEM_PEDIDO(GVET_REGPEDIDO(I).CODEMITENTE,
                                                                                            2513,
                                                                                            GVET_REGPEDIDO(I).CODUSUR,
                                                                                            GVET_REGPEDIDO(I).NUMPED,
                                                                                            REG_ITENS.CODPROD,
                                                                                            REG_ITENS.NUMSEQ);
                        END LOOP;
                     ELSE
                        PROC_VALIDADESCONTOFINACEIRO(GVET_REGPEDIDO(I).NUMPED,
                                                     GVET_REGPEDIDO(I).VALIDO,
                                                     GVET_REGPEDIDO(I).CODRETORNOS);
                     END IF;

                     IF GREGPCCONSUM.CODCONTAREBAIXACMV IS NOT NULL OR GREGPCCONSUM.CODCONTAREBAIXACMVAAPURAR IS NOT NULL THEN
                        PROC_REBAIXARCMV(GVET_REGPEDIDO(I).NUMPED,
                                         GVET_REGPEDIDO(I).DATA,
                                         GVET_REGPEDIDO(I).CODFILIAL);

                        SELECT SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN),
                               SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL)
                        INTO VNVLCUSTOFINPED, VNVLCUSTOREALPED
                        FROM PCPEDI
                        WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        BEGIN
                           UPDATE PCPEDC
                           SET VLCUSTOFIN  = DECODE(GVET_REGPEDIDO(I).CONDVENDA, 20, 0, VNVLCUSTOFINPED),
                               VLCUSTOREAL = DECODE(GVET_REGPEDIDO(I).CONDVENDA, 20, 0, VNVLCUSTOREALPED)
                           WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;
                        EXCEPTION WHEN OTHERS THEN
                           PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                            GVET_REGPEDIDO(I).NUMPEDINT,
                                            NULL,
                                            NULL,
                                            NULL,
                                            GVET_REGPEDIDO(I).CODCLI,
                                            GVET_REGPEDIDO(I).CODUSUR,
                                            NULL,
                                            NULL,
                                            GVET_REGPEDIDO(I).INTEGRADORA,
                                            150,
                                            '2',
                                            'Erro ao atualizar pedido apos rebaixa de cmv :' ||
                                            SQLCODE || '-' || SQLERRM,
                                            NULL);
                           GVET_REGPEDIDO(I).CODRETORNOS := GVET_REGPEDIDO(I).CODRETORNOS || ';' || 150;
                        END;
                     END IF;

                     COMMIT;
                     --verifica se teve pedido de brinde gerado
                     SELECT COUNT(*)
                     INTO VIEXISTEBRINDE
                     FROM PCPEDC
                     WHERE NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDRCA
                       AND BRINDE = 'S';

                     IF VIEXISTEBRINDE = 1 THEN
                        SELECT NUMPED
                        INTO VNNUMPEDBRINDE
                        FROM PCPEDC
                        WHERE NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDRCA
                          AND BRINDE = 'S';
                        --rebaixar cmv para itens do pedido de brinde
                        IF GREGPCCONSUM.CODCONTAREBAIXACMV IS NOT NULL THEN
                           PROC_REBAIXARCMV(VNNUMPEDBRINDE,
                                            GVET_REGPEDIDO(I).DATA,
                                            GVET_REGPEDIDO(I).CODFILIAL);

                           SELECT SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN),
                                  SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL)
                           INTO VNVLCUSTOFINPED, VNVLCUSTOREALPED
                           FROM PCPEDI
                           WHERE PCPEDI.NUMPED = VNNUMPEDBRINDE;

                           BEGIN
                              UPDATE PCPEDC
                              SET VLCUSTOFIN  = VNVLCUSTOFINPED,
                                  VLCUSTOREAL = VNVLCUSTOREALPED
                              WHERE NUMPED = VNNUMPEDBRINDE;
                           EXCEPTION WHEN OTHERS THEN
                              PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                               GVET_REGPEDIDO(I).NUMPEDINT,
                                               NULL,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).CODCLI,
                                               GVET_REGPEDIDO(I).CODUSUR,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).INTEGRADORA,
                                               150,
                                               '2',
                                               'Erro ao atualizar pedido apos rebaixa de cmv para pedido de brinde :' ||
                                               SQLCODE || '-' || SQLERRM,
                                               NULL);
                              GVET_REGPEDIDO(I).CODRETORNOS := GVET_REGPEDIDO(I).CODRETORNOS || ';' || 150;
                           END;
                        END IF;
                     END IF;

                     COMMIT;

                     IF GVET_REGPEDIDO(I).VALIDO = TRUE THEN
                        IF REGFILIAL.SEPARARPRODCOMRESTRICAOTRANSP = 'S' AND
                           GVET_REGPEDIDO(I).CONDVENDA NOT IN (7) THEN
                           PRC_GERARPEDIDORESTRICAOTRANSP(GVET_REGPEDIDO(I).NUMPED, VSAUXPEDIDO, VSMENSAGEM);

                           IF VSMENSAGEM IS NOT NULL THEN
                              IF INSTR(UPPER(VSMENSAGEM), 'ERRO') > 0 THEN
                                 GVET_REGPEDIDO(I).CODRETORNOS := GVET_REGPEDIDO(I).CODRETORNOS || ';' || 61;
                              ELSE
                                 GVET_REGPEDIDO(I).CODRETORNOS := GVET_REGPEDIDO(I).CODRETORNOS || ';' || 60;
                              END IF;

                              PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                               GVET_REGPEDIDO(I).NUMPEDINT,
                                               NULL,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).CODCLI,
                                               GVET_REGPEDIDO(I).CODUSUR,
                                               NULL,
                                               NULL,
                                               GVET_REGPEDIDO(I).INTEGRADORA,
                                               GVET_REGPEDIDO(I).CODRETORNOS,
                                               '2',
                                               'Erro30:' || VSMENSAGEM,
                                               NULL);
                           END IF;

                           COMMIT;
                        ELSE
                           SELECT COUNT(*)
                           INTO VIEXISTEREST
                           FROM PCPEDI, PCPRODUT
                           WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED
                             AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                             AND NVL(PCPRODUT.RESTRICAOTRANSP, 'N') = 'S';

                           SELECT COUNT(*)
                           INTO VIEXISTERESTREF
                           FROM PCPEDI, PCPRODUT
                           WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED
                             AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                             AND NVL(PCPRODUT.RESTRICAOTRANSP, 'N') = 'R';

                           IF VIEXISTERESTREF > 0 THEN
                              UPDATE PCPEDC
                              SET PCPEDC.RESTRICAOTRANSP = 'R'
                              WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;
                           ELSE
                              IF VIEXISTEREST > 0 THEN
                                 UPDATE PCPEDC
                                 SET PCPEDC.RESTRICAOTRANSP = 'S'
                                 WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;
                              END IF;
                           END IF;

                           COMMIT;
                        END IF;

                        IF REGFILIAL.SEPARARPRODCOMST = 'S' THEN
                           IF GVET_REGPEDIDO(I).NUMPEDORIG = 0 AND GVET_REGPEDIDO(I).CONDVENDA NOT IN (7) THEN
                              FOR REG IN (SELECT NUMPED
                                          FROM PCPEDC P
                                          WHERE P.NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDRCA
                                            AND P.DTABERTURAPEDPALM = GVET_REGPEDIDO(I).DTABERTURAPEDPALM
                                            AND P.CODUSUR = GVET_REGPEDIDO(I).CODUSUR
                                            AND P.CODCLI = GVET_REGPEDIDO(I).CODCLI) 
                              LOOP
                                 PRC_GERARPEDIDOITEMCOMST(REG.NUMPED, VNPEDIDORESTST, VSMENSAGEMRESTST);

                                 IF VSMENSAGEMRESTST IS NOT NULL THEN
                                    PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                     GVET_REGPEDIDO(I).NUMPEDINT,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     GVET_REGPEDIDO(I).CODCLI,
                                                     GVET_REGPEDIDO(I).CODUSUR,
                                                     NULL,
                                                     NULL,
                                                     GVET_REGPEDIDO(I).INTEGRADORA,
                                                     NULL,
                                                     '2',
                                                     'Erro31:' || VSMENSAGEMRESTST || ';',
                                                     NULL);
                                 END IF;
                              END LOOP;

                              COMMIT;
                           END IF;
                        END IF;

                        IF GVET_REGPEDIDO(I).CONDVENDA = 7 AND GVET_REGPEDIDO(I).NUMPEDORIG = 0 THEN
                           IF REGFILIAL.RESERVARESTOQUETV7 = 'S' THEN
                              PRC_GERARPEDTV8(GVET_REGPEDIDO(I).NUMPED,
                                              VSMENSAGEMPEDIDOTV8,
                                              VNNUMPEDTV8,
                                              VSPOSICAOTV8,
                                              VNMOTIVOTV8);

                              IF TRIM(VSMENSAGEMPEDIDOTV8) IS NOT NULL THEN
                                 PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                  GVET_REGPEDIDO(I).NUMPEDINT,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).CODCLI,
                                                  GVET_REGPEDIDO(I).CODUSUR,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).INTEGRADORA,
                                                  NULL,
                                                  '2',
                                                  'Erro32:' || VSMENSAGEMPEDIDOTV8 || ';',
                                                  NULL);
                              ELSE
                                 PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                  GVET_REGPEDIDO(I).NUMPEDINT,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).CODCLI,
                                                  GVET_REGPEDIDO(I).CODUSUR,
                                                  NULL,
                                                  NULL,
                                                  GVET_REGPEDIDO(I).INTEGRADORA,
                                                  NULL,
                                                  '2',
                                                  'Pedido TV8 gerado : ' ||
                                                  VNNUMPEDTV8 || ' na posicao : ' ||
                                                  VSPOSICAOTV8 || ';',
                                                  NULL);
                              END IF;
                           END IF;
                        END IF;
                        -- Carregamento de Pedido Balcao Reserva
                        IF (GVET_REGPEDIDO(I).ORIGEMPED = 'R') THEN
                           GERARCARREGBALCAORESERVA(GVET_REGPEDIDO(I));
                        END IF;

                        IF NVL(REGFILIAL.NUMMAXITENSNFE, 0) > 0 AND GVET_REGPEDIDO(I).CONDVENDA <> 7 THEN
                           VICONTADOR := 1;

                           WHILE VICONTADOR > 0 LOOP
                              -- Verifica se tem algum pedido com numero de itens superior ao parametrizado na pcparamfilial.nummaxitensnfe
                              IF GVET_REGPEDIDO(I).TIPOINTEGRACAO = 'R' THEN
                                 SELECT COUNT(*)
                                 INTO VICONTADOR
                                 FROM PCPEDC
                                 WHERE NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDINT
                                   AND PCPEDC.CODUSUR = GVET_REGPEDIDO(I).CODUSUR
                                   AND PCPEDC.CODCLI = GVET_REGPEDIDO(I).CODCLI
                                   AND PCPEDC.DATA = TRUNC(SYSDATE)
                                   AND PCPEDC.NUMITENS > NVL(REGFILIAL.NUMMAXITENSNFE, 0);
                              ELSIF GVET_REGPEDIDO(I).TIPOINTEGRACAO = 'C' THEN
                                 SELECT COUNT(*)
                                 INTO VICONTADOR
                                 FROM PCPEDC
                                 WHERE NUMPEDCLI = GVET_REGPEDIDO(I).NUMPEDINT
                                   AND PCPEDC.CODUSUR = GVET_REGPEDIDO(I).CODUSUR
                                   AND PCPEDC.CODCLI = GVET_REGPEDIDO(I).CODCLI
                                   AND PCPEDC.DATA = TRUNC(SYSDATE)
                                   AND PCPEDC.NUMITENS > NVL(REGFILIAL.NUMMAXITENSNFE, 0);
                              ELSIF GVET_REGPEDIDO(I).TIPOINTEGRACAO = 'W' THEN
                                 SELECT COUNT(*)
                                 INTO VICONTADOR
                                 FROM PCPEDC
                                 WHERE NUMPEDWEB = GVET_REGPEDIDO(I).NUMPEDINT
                                   AND PCPEDC.CODUSUR = GVET_REGPEDIDO(I).CODUSUR
                                   AND PCPEDC.CODCLI = GVET_REGPEDIDO(I).CODCLI
                                   AND PCPEDC.DATA = TRUNC(SYSDATE)
                                   AND PCPEDC.NUMITENS > NVL(REGFILIAL.NUMMAXITENSNFE, 0);
                              END IF;

                              IF VICONTADOR > 0 THEN
                                 PROC_DIVIDE_NUMITENSNFE(GVET_REGPEDIDO(I).NUMPED,
                                                         GVET_REGPEDIDO(I).TIPOINTEGRACAO,
                                                         GVET_REGPEDIDO(I).NUMPEDINT,
                                                         GVET_REGPEDIDO(I).CODUSUR,
                                                         GVET_REGPEDIDO(I).CODCLI,
                                                         REGFILIAL,
                                                         VSMENSAGEMDIVIDENFE,
                                                         GVET_REGPEDIDO(I).PEDIDODIVIDIDONFE);

                                 IF VSMENSAGEMDIVIDENFE IS NOT NULL THEN
                                    PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                                                     GVET_REGPEDIDO(I).NUMPEDINT,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     GVET_REGPEDIDO(I).CODCLI,
                                                     GVET_REGPEDIDO(I).CODUSUR,
                                                     NULL,
                                                     NULL,
                                                     GVET_REGPEDIDO(I).INTEGRADORA,
                                                     NULL,
                                                     '2',
                                                     'Erro33:' ||
                                                     VSMENSAGEMDIVIDENFE || ';',
                                                     NULL);
                                 END IF;
                              END IF;
                           END LOOP;
                        END IF;

                        COMMIT;
                     END IF;
                  ELSE
                     ROLLBACK;

                     IF NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) = 0 THEN
                        DELETE FROM PCPEDI
                        WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        DELETE FROM PCORIGEMPRECO
                        WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        DELETE FROM PCPEDC
                        WHERE PCPEDC.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        COMMIT;
                     END IF;
                  END IF;
                  ELSE
                     ROLLBACK;

                     IF NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) = 0 THEN
                        DELETE FROM PCPEDI
                        WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        DELETE FROM PCORIGEMPRECO
                        WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        DELETE FROM PCPEDC
                        WHERE PCPEDC.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                        COMMIT;
                     END IF;
                  END IF;
               ELSE
                  -- rejeitado na validacao final do cabecalho
                  ROLLBACK;

                  IF NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) = 0 THEN
                     DELETE FROM PCPEDI
                     WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

                     DELETE FROM PCORIGEMPRECO
                     WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;

                     COMMIT;
                  END IF;
               END IF;
            END IF; -- pedido valido (gvet_regpedido (i).valido)
            ----------------------------------------------------
            ----------------------------------------------------
            -- Caso exista registro na tabela PCBLOQUEIOSPEDIDO e o campo POSICAO (PCPEDC e PCPEDI), estiver diferente de "B" (Bloqueado), deverá colocar como "B".
            IF GVET_REGPEDIDO(I).POSICAO <> 'B' THEN
               PROC_VALIDAR_BLOQUEIO(GVET_REGPEDIDO(I).NUMPED, GVET_REGPEDIDO(I).POSICAO);
            END IF;
            ----------------------------------------------------
            ----------------------------------------------------
         EXCEPTION WHEN OTHERS THEN
            GVET_REGPEDIDO(I).VALIDO := FALSE;
            PROC_REGISTRALOG(GVET_REGPEDIDO(I).NUMPED,
                             GVET_REGPEDIDO(I).NUMPEDINT,
                             NULL,
                             NULL,
                             NULL,
                             GVET_REGPEDIDO(I).CODCLI,
                             GVET_REGPEDIDO(I).CODUSUR,
                             NULL,
                             NULL,
                             GVET_REGPEDIDO(I).INTEGRADORA,
                             NULL,
                             '2',
                             'Erro34:' || SQLCODE || '-' || SQLERRM || ';',
                             NULL);
            ROLLBACK;
            IF NVL(GVET_REGPEDIDO(I).NUMPEDORIG, 0) = 0 THEN
               DELETE FROM PCPEDI
               WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED;

               DELETE FROM PCORIGEMPRECO
               WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;

               DELETE FROM PCPEDC
               WHERE PCPEDC.NUMPED = GVET_REGPEDIDO(I).NUMPED;

               COMMIT;
            END IF;
            
            EXIT;
         END;
      END LOOP; -- FOR i IN 1 .. vncontped
   END IF; -- vncontped > 0
END PROC_PROCESSARPEDIDOS;


PROCEDURE PROC_PROCESSARETORNOTAB(P_EXISTERRO IN BOOLEAN) IS
    VNCONTLOG           NUMBER;
    VNCONTPED           NUMBER;
    VICONTADOR          NUMBER;
    VNQTATEND           PCPEDI.QT%TYPE;
    VSOBSERVACAOPEDCAB  VARCHAR2(32767);
    VSOBSERVACAOPEDCORP VARCHAR2(32767);
    VSCODRETORNOPED     VARCHAR2(100);
    VSCODRETORNOITEM    VARCHAR2(100);
  BEGIN
    -- Retorna erros genericos tiporeg = 1
    IF P_EXISTERRO = TRUE THEN
      VNCONTLOG := GVETREGISTRALOG.COUNT;

      FOR I IN 1 .. VNCONTLOG LOOP
        IF GVETREGISTRALOG(I).TIPOREG = 1 THEN
          -- Gravar log de processamento de pedidos
          BEGIN
            INSERT INTO PCLOGFV
              (ARQUIVO,
               CODCLI,
               DATA,
               MOTIVO,
               NUMPED,
               NUMPEDCLI,
               NUMPEDRCA,
               NUMPEDWEB,
               STATUS)
            VALUES
              ('PCPEDCTEMP/PCPEDITEMP',
               NULL,
               SYSDATE,
               SUBSTR(REPLACE(GVETREGISTRALOG(I).ERRO, '#', ' '), 1, 100),
               NULL,
               NULL,
               NULL,
               NULL,
               'N');

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END IF;
      END LOOP;
    END IF;

   -- Retorna pedidos gravados com sucesso
   VNCONTPED := GVET_REGPEDIDO.COUNT;

   FOR I IN 1 .. VNCONTPED LOOP
      IF GVET_REGPEDIDO(I).VALIDO = TRUE THEN
         -- recupera critica do cabecalho.
         VNCONTLOG          := GVETREGISTRALOG.COUNT;
         VSOBSERVACAOPEDCAB := '';
         VSCODRETORNOPED    := NULL;

         FOR J IN 1 .. VNCONTLOG LOOP
            IF (GVETREGISTRALOG(J).TIPOREG = 2) AND
               (GVETREGISTRALOG(J).NUMPED = GVET_REGPEDIDO(I).NUMPED) AND
               (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDINT) THEN
               IF LENGTH(VSOBSERVACAOPEDCAB) <= 300 OR
                  VSOBSERVACAOPEDCAB IS NULL THEN
                  IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
                     VSOBSERVACAOPEDCAB := VSOBSERVACAOPEDCAB || REPLACE(GVETREGISTRALOG(J).ERRO, '#', ' ');

                     IF GVETREGISTRALOG(J).CODRETORNOS IS NOT NULL THEN
                        VSCODRETORNOPED := GVETREGISTRALOG(J).CODRETORNOS;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END LOOP;

         BEGIN
            IF INSTR(VSCODRETORNOPED, 78) > 0 THEN
               VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '78;', '');
            END IF;

            IF INSTR(VSCODRETORNOPED, 80) > 0 THEN
               VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '80;', '');
            END IF;

            IF INSTR(VSCODRETORNOPED, 81) > 0 THEN
               VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '81;', '');
            END IF;

            IF INSTR(VSCODRETORNOPED, 145) > 0 THEN
               VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '145;', '');
            END IF;

            IF INSTR(VSCODRETORNOPED, 146) > 0 THEN
               VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '146;', '');
            END IF;
            --- atualiza cabecalho do pedido.
            UPDATE PCPEDCTEMP
            SET IMPORTADO     = 'S',
                NUMPED        = GVET_REGPEDIDO(I).NUMPED,
                OBSERVACAO_PC = SUBSTR(VSOBSERVACAOPEDCAB, 1, 3000),
                CODRETORNOS   = SUBSTR(VSCODRETORNOPED, 2, 30)
            WHERE DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R',NUMPEDRCA, 'W', NUMPEDWEB) = GVET_REGPEDIDO(I).NUMPEDINT
              AND NVL(INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0);

            COMMIT;
         EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
         END;

         -- Gravar log de processamento de pedidos
         BEGIN
            INSERT INTO PCLOGFV(ARQUIVO,
                                CODCLI,
                                DATA,
                                MOTIVO,
                                NUMPED,
                                NUMPEDCLI,
                                NUMPEDRCA,
                                NUMPEDWEB,
                                STATUS)
                         VALUES('PCPEDCTEMP/PCPEDITEMP',
                                GVET_REGPEDIDO(I).CODCLI,
                                SYSDATE,
                                SUBSTR(VSOBSERVACAOPEDCAB, 1, 100),
                                GVET_REGPEDIDO(I).NUMPED,
                                GVET_REGPEDIDO(I).NUMPEDCLI,
                                GVET_REGPEDIDO(I).NUMPEDRCA,
                                GVET_REGPEDIDO(I).NUMPEDWEB,
                                GVET_REGPEDIDO(I).POSICAO);

            COMMIT;
         EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
         END;

         FOR CR_PEDCORP IN (SELECT P.CODPROD CODIGO_PRODUTO,
                                  P.NUMSEQ,
                                  NVL(P.CODAUXILIAR, T.CODAUXILIAR) CODAUXILIAR
                             FROM PCPEDITEMP P, PCPRODUT T
                            WHERE DECODE(P.TIPOINTEGRACAO, 'C',
                                         NUMPEDCLI, 'R',
                                         NUMPEDRCA, 'W', NUMPEDWEB) = GVET_REGPEDIDO(I).NUMPEDINT
                              AND DECODE(P.TIPOINTEGRACAO, 'C',
                                         CODCLI, 'R',
                                         CODUSUR, 'W', CODCLI) = DECODE(P.TIPOINTEGRACAO, 'C',
                                                                        GVET_REGPEDIDO(I).CODCLI, 'R',
                                                                        GVET_REGPEDIDO(I).CODUSUR, 'W',
                                                                        GVET_REGPEDIDO(I).CODCLI)
                              AND NVL(P.INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0)
                              AND P.CODPROD = T.CODPROD) LOOP
            -- recupera critica do item
            VNCONTLOG           := GVETREGISTRALOG.COUNT;
            VSOBSERVACAOPEDCORP := '';
            VSCODRETORNOITEM    := NULL;

            FOR J IN 1 .. VNCONTLOG LOOP
               IF (GVETREGISTRALOG(J).TIPOREG = 3) AND
                  ((GVETREGISTRALOG(J).NUMPED = GVET_REGPEDIDO(I).NUMPED) OR
                   (GVETREGISTRALOG(J).NUMPED IS NULL)) AND
                  (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDINT) AND
                  (GVETREGISTRALOG(J).CODPROD = CR_PEDCORP.CODIGO_PRODUTO) AND
                  (GVETREGISTRALOG(J).NUMSEQORIG = CR_PEDCORP.NUMSEQ) AND
                  (GVETREGISTRALOG(J).CODAUXILIAR IS NULL OR GVETREGISTRALOG(J).CODAUXILIAR = 0 OR 
                   GVETREGISTRALOG(J).CODAUXILIAR = CR_PEDCORP.CODAUXILIAR) THEN
                  IF LENGTH(VSOBSERVACAOPEDCORP) <= 300 OR
                     VSOBSERVACAOPEDCORP IS NULL THEN
                     IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
                        VSOBSERVACAOPEDCORP := VSOBSERVACAOPEDCORP || REPLACE(GVETREGISTRALOG(J).ERRO, '#', ' ');

                        IF GVETREGISTRALOG(J).CODRETORNOS IS NOT NULL THEN
                           VSCODRETORNOITEM := GVETREGISTRALOG(J).CODRETORNOS;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END LOOP;

            VNQTATEND := 0;

            SELECT COUNT(*)
            INTO VICONTADOR
            FROM PCPEDI
            WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED
              AND PCPEDI.CODPROD = CR_PEDCORP.CODIGO_PRODUTO
              AND PCPEDI.NUMAPLIC = CR_PEDCORP.NUMSEQ
              AND (PCPEDI.CODAUXILIAR = CR_PEDCORP.CODAUXILIAR 
               OR  CODAUXILIAR IS NULL);

            IF VICONTADOR > 0 THEN
               SELECT QT / DECODE(NVL(PCPEDI.QTUNITEMB,0), 0, 1, PCPEDI.QTUNITEMB)
               INTO VNQTATEND
               FROM PCPEDI
               WHERE PCPEDI.NUMPED = GVET_REGPEDIDO(I).NUMPED
                 AND PCPEDI.CODPROD = CR_PEDCORP.CODIGO_PRODUTO
                 AND PCPEDI.NUMAPLIC = CR_PEDCORP.NUMSEQ
                 AND (PCPEDI.CODAUXILIAR = CR_PEDCORP.CODAUXILIAR 
                  OR  CODAUXILIAR IS NULL);
            END IF;

            BEGIN
               UPDATE PCPEDITEMP
               SET OBSERVACAO_PC = SUBSTR(VSOBSERVACAOPEDCORP, 1, 300),
                   QT_FATURADA   = VNQTATEND,
                   CODRETORNOS   = SUBSTR(VSCODRETORNOITEM, 2, 30)
               WHERE DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA, 'W', NUMPEDWEB) = GVET_REGPEDIDO(I).NUMPEDINT
                 AND DECODE(TIPOINTEGRACAO, 'C', CODCLI, 'R',
                          CODUSUR, 'W', CODCLI) =  DECODE(TIPOINTEGRACAO, 'C',
                                                          GVET_REGPEDIDO(I).CODCLI, 'R',
                                                          GVET_REGPEDIDO(I).CODUSUR, 'W',
                                                          GVET_REGPEDIDO(I).CODCLI)
                 AND CODPROD = CR_PEDCORP.CODIGO_PRODUTO
                 AND NUMSEQ = CR_PEDCORP.NUMSEQ
                 AND NVL(INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0)
                 AND (CODAUXILIAR = CR_PEDCORP.CODAUXILIAR 
                  OR  CODAUXILIAR IS NULL);

            COMMIT;
            EXCEPTION WHEN OTHERS THEN
               ROLLBACK;
            END;
         END LOOP;
      END IF;
      --retirar valor gravado na tabela pcpedi para armazenas numseq lido na tabela pcpeditemp
      UPDATE PCPEDI
         SET NUMAPLIC = NULL
       WHERE NUMPED = GVET_REGPEDIDO(I).NUMPED;

      COMMIT;
   END LOOP;
   -- Retorna pedidos nao gravados
   VNCONTPED := GVET_REGPEDIDO.COUNT;

   FOR I IN 1 .. VNCONTPED LOOP
      IF GVET_REGPEDIDO(I).VALIDO = FALSE THEN
         -- recupera critica do cabecalho.
         VNCONTLOG          := GVETREGISTRALOG.COUNT;
         VSOBSERVACAOPEDCAB := '';
         VSCODRETORNOPED    := NULL;

         FOR J IN 1 .. VNCONTLOG LOOP
            IF (GVETREGISTRALOG(J).TIPOREG = 2) AND
               ((GVETREGISTRALOG(J).NUMPED = GVET_REGPEDIDO(I).NUMPED) OR
                (GVETREGISTRALOG(J).NUMPED IS NULL)) AND
               (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDINT) THEN
               IF LENGTH(VSOBSERVACAOPEDCAB) <= 300 OR
                  VSOBSERVACAOPEDCAB IS NULL THEN
                  
                  IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
                     VSOBSERVACAOPEDCAB := VSOBSERVACAOPEDCAB || REPLACE(GVETREGISTRALOG(J).ERRO, '#', ' ');

                     IF GVETREGISTRALOG(J).CODRETORNOS IS NOT NULL THEN
                        VSCODRETORNOPED := GVETREGISTRALOG(J).CODRETORNOS;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END LOOP;

         IF INSTR(VSCODRETORNOPED, 78) > 0 THEN
            VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '78;', '');
         END IF;

         IF INSTR(VSCODRETORNOPED, 80) > 0 THEN
            VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '80;', '');
         END IF;

         IF INSTR(VSCODRETORNOPED, 81) > 0 THEN
            VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '81;', '');
         END IF;

         IF INSTR(VSCODRETORNOPED, 145) > 0 THEN
            VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '145;', '');
         END IF;

         IF INSTR(VSCODRETORNOPED, 146) > 0 THEN
            VSCODRETORNOPED := REPLACE(VSCODRETORNOPED, '146;', '');
         END IF;

         BEGIN
            --- atualiza cabecalho do pedido.
            UPDATE PCPEDCTEMP
            SET IMPORTADO     = 'N',
                NUMPED        = NULL,
                OBSERVACAO_PC = SUBSTR(VSOBSERVACAOPEDCAB, 1, 3000),
                CODRETORNOS   = SUBSTR(VSCODRETORNOPED, 2, 30)
            WHERE DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA, 'W', NUMPEDWEB) = GVET_REGPEDIDO(I).NUMPEDINT
              AND DECODE(TIPOINTEGRACAO, 'C', CODCLI, 'R',
                         CODUSUR,'W', CODCLI) = DECODE(TIPOINTEGRACAO, 'C',
                                                       GVET_REGPEDIDO(I).CODCLI, 'R',
                                                       GVET_REGPEDIDO(I).CODUSUR, 'W',
                                                       GVET_REGPEDIDO(I).CODCLI)
              AND NVL(INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0);

          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
         END;

         -- Gravar log de processamento de pedidos
         BEGIN
            INSERT INTO PCLOGFV(ARQUIVO,
                                CODCLI,
                                DATA,
                                MOTIVO,
                                NUMPED,
                                NUMPEDCLI,
                                NUMPEDRCA,
                                NUMPEDWEB,
                                STATUS)
                         VALUES('PCPEDCTEMP/PCPEDITEMP',
                                GVET_REGPEDIDO(I).CODCLI,
                                SYSDATE,
                                SUBSTR(VSOBSERVACAOPEDCAB, 1, 100),
                                GVET_REGPEDIDO(I).NUMPED,
                                GVET_REGPEDIDO(I).NUMPEDCLI,
                                GVET_REGPEDIDO(I).NUMPEDRCA,
                                GVET_REGPEDIDO(I).NUMPEDWEB,
                                'R');

            COMMIT;
         EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
         END;

         FOR CR_PEDCORP IN (SELECT P.CODPROD CODIGO_PRODUTO,
                                   P.NUMSEQ,
                                   NVL(P.CODAUXILIAR, T.CODAUXILIAR) CODAUXILIAR
                            FROM PCPEDITEMP P, PCPRODUT T
                            WHERE DECODE(P.TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA, 'W', NUMPEDWEB) = GVET_REGPEDIDO(I).NUMPEDINT
                              AND DECODE(P.TIPOINTEGRACAO, 'C', CODCLI, 'R',
                                         CODUSUR, 'W', CODCLI) = DECODE(P.TIPOINTEGRACAO, 'C',
                                                                        GVET_REGPEDIDO(I).CODCLI, 'R',
                                                                        GVET_REGPEDIDO(I).CODUSUR, 'W',
                                                                        GVET_REGPEDIDO(I).CODCLI)
                              AND NVL(P.INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0)
                              AND P.CODPROD = T.CODPROD) 
         LOOP
            -- recupera critica do item
            VNCONTLOG           := GVETREGISTRALOG.COUNT;
            VSOBSERVACAOPEDCORP := '';
            VSCODRETORNOITEM    := NULL;

            FOR J IN 1 .. VNCONTLOG LOOP
               IF (GVETREGISTRALOG(J).TIPOREG = 3) AND
                  ((GVETREGISTRALOG(J).NUMPED = GVET_REGPEDIDO(I).NUMPED) OR
                   (GVETREGISTRALOG(J).NUMPED IS NULL)) AND
                  (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGPEDIDO(I).NUMPEDINT) AND
                  (GVETREGISTRALOG(J).CODPROD = CR_PEDCORP.CODIGO_PRODUTO) AND
                  (GVETREGISTRALOG(J).NUMSEQORIG = CR_PEDCORP.NUMSEQ) AND
                  (GVETREGISTRALOG(J).CODAUXILIAR IS NULL OR GVETREGISTRALOG(J).CODAUXILIAR = 0 OR 
                   GVETREGISTRALOG(J).CODAUXILIAR = CR_PEDCORP.CODAUXILIAR) THEN
                  IF LENGTH(VSOBSERVACAOPEDCORP) <= 300 OR
                     VSOBSERVACAOPEDCORP IS NULL THEN
                     IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
                        VSOBSERVACAOPEDCORP := VSOBSERVACAOPEDCORP || REPLACE(GVETREGISTRALOG(J).ERRO, '#', ' ');
                     END IF;

                     IF GVETREGISTRALOG(J).CODRETORNOS IS NOT NULL THEN
                        VSCODRETORNOITEM := GVETREGISTRALOG(J).CODRETORNOS;
                     END IF;
                  END IF;
               END IF;
            END LOOP;

            BEGIN
               UPDATE PCPEDITEMP
               SET OBSERVACAO_PC = SUBSTR(VSOBSERVACAOPEDCORP, 1, 300),
                   CODRETORNOS   = SUBSTR(VSCODRETORNOITEM, 2, 30)
               WHERE DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA, 'W', NUMPEDWEB) = GVET_REGPEDIDO(I).NUMPEDINT
                 AND DECODE(TIPOINTEGRACAO, 'C', CODCLI, 'R',
                          CODUSUR, 'W', CODCLI) = DECODE(TIPOINTEGRACAO, 'C',
                                                         GVET_REGPEDIDO(I).CODCLI, 'R',
                                                         GVET_REGPEDIDO(I).CODUSUR, 'W',
                                                         GVET_REGPEDIDO(I).CODCLI)
                 AND CODPROD = CR_PEDCORP.CODIGO_PRODUTO
                 AND NUMSEQ = CR_PEDCORP.NUMSEQ
                 AND NVL(INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0)
                 AND (CODAUXILIAR = CR_PEDCORP.CODAUXILIAR OR CODAUXILIAR IS NULL);

               COMMIT;
            EXCEPTION WHEN OTHERS THEN
               ROLLBACK;
            END;
         END LOOP;
      END IF;
   END LOOP;

   -- Retorna pedidos rejeitados durante a leitura
   VNCONTLOG := GVETREGISTRALOG.COUNT;

   FOR I IN 1 .. VNCONTLOG LOOP
      IF (GVETREGISTRALOG(I).TIPOREG = 2) AND
         (GVETREGISTRALOG(I).LINHAREG IS NOT NULL) THEN
         BEGIN
            --- atualiza cabecalho do pedido.
            UPDATE PCPEDCTEMP
            SET IMPORTADO     = 'N',
                NUMPED        = NULL,
                OBSERVACAO_PC = SUBSTR(REPLACE(GVETREGISTRALOG(I).ERRO, '#', ' '), 1, 3000),
                CODRETORNOS   = 54
            WHERE DECODE(TIPOINTEGRACAO, 'C', NUMPEDCLI, 'R', NUMPEDRCA, 'W', NUMPEDWEB) = GVETREGISTRALOG(I).NUMPEDRCA
              AND DECODE(TIPOINTEGRACAO, 'C', CODCLI, 'R',
                         CODUSUR, 'W', CODCLI) = DECODE(TIPOINTEGRACAO, 'C',
                                                        GVETREGISTRALOG(I).CODCLI, 'R',
                                                        GVETREGISTRALOG(I).CODUSUR, 'W',
                                                        GVETREGISTRALOG(I).CODCLI)
              AND NVL(INTEGRADORA, 0) = NVL(GVET_REGPEDIDO(I).INTEGRADORA, 0);

            COMMIT;
         EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
         END;

         -- Gravar log de processamento de pedidos
         BEGIN
            INSERT INTO PCLOGFV(ARQUIVO,
                                CODCLI,
                                DATA,
                                MOTIVO,
                                NUMPED,
                                NUMPEDCLI,
                                NUMPEDRCA,
                                NUMPEDWEB,
                                STATUS)
                         VALUES('PCPEDCTEMP/PCPEDITEMP',
                                GVET_REGPEDIDO(I).CODCLI,
                                SYSDATE,
                                SUBSTR(REPLACE(GVETREGISTRALOG(I).ERRO, '#', ' '), 1, 100),
                                GVET_REGPEDIDO(I).NUMPED,
                                GVET_REGPEDIDO(I).NUMPEDCLI,
                                GVET_REGPEDIDO(I).NUMPEDRCA,
                                GVET_REGPEDIDO(I).NUMPEDWEB,
                                'N');

            COMMIT;
         EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
         END;
      END IF;
   END LOOP;
EXCEPTION WHEN OTHERS THEN
   NULL;
END PROC_PROCESSARETORNOTAB;


PROCEDURE IMPORTAR_PEDIDO_WEB(PNUMPEDWEB IN NUMBER, PINTEGRADORA IN NUMBER, PCODUSUR IN NUMBER)
IS
BEGIN
   IMPORTARVENDASCOMPLE.IMPORTAR_PEDIDO_WEB(PNUMPEDWEB, PINTEGRADORA, PCODUSUR);
END IMPORTAR_PEDIDO_WEB;


PROCEDURE IMPORTARPEDIDOWEB(P_NUMPEDWEB IN NUMBER, P_CODUSUR IN NUMBER) 
IS
   VBEXISTERRO BOOLEAN;
BEGIN
   -- Remove todos os elementos das tabelas.
   GVETREGISTRALOG.DELETE;
   GVET_REGPEDIDO.DELETE;
   GVET_REGITEM.DELETE;
   GVETREGISTRALOG.DELETE;
   GVET_REGORIGEMCOMISS.DELETE;
   GVET_REGORIGEMDESC.DELETE;

   VNGCONTADOR := 0;
   VBEXISTERRO := FALSE;
   VSGARQUIVO1 := NULL;
   VSGARQUIVO2 := NULL;
   -- leitura dos parametros do sistema (PCCONSUM).
   IF NOT VBEXISTERRO THEN
      PROC_LERPARAMETROS(VBEXISTERRO);
   END IF;
   -- leitura dos pedidos
   IF NOT VBEXISTERRO THEN
      -- leitura de tabelas contendo os pedidos.
      PROC_PROCESSARLEITURAPEDWEB(P_NUMPEDWEB, P_CODUSUR, VBEXISTERRO);
   END IF;

   IF NOT VBEXISTERRO THEN
      -- processamento dos pedidos.
      PROC_PROCESSARPEDIDOS(VBEXISTERRO);
   END IF;

   PROC_PROCESSARETORNOTAB(VBEXISTERRO);
   -- Remove todos os elementos das tabelas.
   GVETREGISTRALOG.DELETE;
   GVET_REGPEDIDO.DELETE;
   GVET_REGITEM.DELETE;
   GVETREGISTRALOG.DELETE;
   GVET_REGORIGEMCOMISS.DELETE;
   GVET_REGORIGEMDESC.DELETE;
END IMPORTARPEDIDOWEB;


PROCEDURE IMPORTARPEDIDO 
IS
   VBEXISTERRO BOOLEAN;
BEGIN
   -- Remove todos os elementos das tabelas.
   GVETREGISTRALOG.DELETE;
   GVET_REGPEDIDO.DELETE;
   GVET_REGITEM.DELETE;
   GVET_REGORIGEMCOMISS.DELETE;
   GVET_REGORIGEMDESC.DELETE;

   GVETREGISTRALOG.DELETE;
   VNGCONTADOR := 0;
   VBEXISTERRO := FALSE;
   VSGARQUIVO1 := NULL;
   VSGARQUIVO2 := NULL;
   -- leitura dos parametros do sistema (PCCONSUM).
   IF NOT VBEXISTERRO THEN
      PROC_LERPARAMETROS(VBEXISTERRO);
   END IF;
   -- leitura dos pedidos
   IF NOT VBEXISTERRO THEN
      -- leitura de tabelas contendo os pedidos.
      PROC_PROCESSARLEITURAPEDIDOS(VBEXISTERRO);
   END IF;

   IF NOT VBEXISTERRO THEN
      -- processamento dos pedidos.
      PROC_PROCESSARPEDIDOS(VBEXISTERRO);
   END IF;

   PROC_PROCESSARETORNOTAB(VBEXISTERRO);
   -- Remove todos os elementos das tabelas.
   GVETREGISTRALOG.DELETE;
   GVET_REGPEDIDO.DELETE;
   GVET_REGITEM.DELETE;
   GVETREGISTRALOG.DELETE;
   GVET_REGORIGEMCOMISS.DELETE;
   GVET_REGORIGEMDESC.DELETE;
END IMPORTARPEDIDO;


END IMPORTARVENDAS;
