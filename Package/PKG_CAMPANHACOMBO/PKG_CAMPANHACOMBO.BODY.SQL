CREATE OR REPLACE PACKAGE BODY PKG_CAMPANHACOMBO IS
  /*--------------------------------------------------------------------------------------------------------------------
  AUTOR                SOLICITAÇÃO        DATA         DESCRIÇÃO
  Iran Junior          HIS.03255.2016    19/12/2016   Criação da nova package para operações logísticas(Mód-011).

  --------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE InserirComboCli(pCODFILIAL     IN VARCHAR2,
                            pNUMPED        IN VARCHAR2,
                            pCODPROD       IN NUMBER,
                            pCODCLI        IN NUMBER,
                            pPERDESC       IN NUMBER,
                            pCODCOMBO      IN NUMBER,
                            pCODGRUPOCOMBO IN NUMBER,
                            pNUMSEQ        IN NUMBER,
                            pQT            IN NUMBER,
                            pCODAUXILIAR   IN NUMBER) IS
  BEGIN
    INSERT INTO PCCOMBOCLI
      (CODIGO,
       PERDESC,
       CODPROD,
       CODCLI,
       CODCOMBO,
       CODFILIAL,
       DATA,
       NUMSEQ,
       NUMPED,
       QT,
       CODGRUPOCOMBO,
       CODAUXILIAR)
    VALUES
      (SEQ_PCCOMBOCLI.NEXTVAL,
       pPERDESC,
       pCODPROD,
       pCODCLI,
       pCODCOMBO,
       pCODFILIAL,
       SYSDATE,
       pNUMSEQ,
       pNUMPED,
       pQT,
       pCODGRUPOCOMBO,
       pCODAUXILIAR);
  exception
    when others then
      Raise_application_error(-20000, 'Erro ao inserir PCComboCli');
  end;

  FUNCTION BuscaDescontoCampanha(pCODFILIAL   IN VARCHAR2,
                                 pCODPROD     IN NUMBER,
                                 pCODCLI      IN NUMBER,
                                 pCODAUXILIAR IN NUMBER,
                                 pCODIGOCAMPANHADESCONTO OUT NUMBER) RETURN NUMBER is
    vnPerdesc   Number;
    vnCODGRUPOCAMPANHA NUMBER;
    vsVendaEmb  VARCHAR2(1) := 'N';
  begin
    vnCODGRUPOCAMPANHA := 0;
    vsVendaEmb := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM'
                                                    ,pCODFILIAL
                                                    ,'N');

    --Select busca descontos em campanhas em caracter continuo

    select max(NVL(PCDESCONTOCPRODRELAC.perdesc, 0)) perdesc
      INTO vnPerdesc
      from PCDESCONTOCPRODRELAC
     where codprod = pCODPROD
       and codigocampanha in
           (select pcdescontoc.codigo
              from pcdescontoc
             where pcdescontoc.codigo = PCDESCONTOCPRODRELAC.CODIGOCAMPANHA
               and pcdescontoc.dtfim >= TRUNC(sysdate)
               and rownum = 1)
       and codigocampanha in
             (select codcombo
              from pccombocli, pcpedc
             where pccombocli.codfilial = pCODFILIAL
               and pccombocli.codcli = pCODCLI
               and pccombocli.codcombo = PCDESCONTOCPRODRELAC.Codigocampanha
               and pccombocli.numped = pcpedc.numped
               and pcpedc.posicao <> 'C')
       AND DECODE(VSVENDAEMB, 'S', NVL(CODAUXILIAR, -1), -1) =
           DECODE(VSVENDAEMB, 'S', NVL(pCODAUXILIAR, -1), -1);

    begin
	  select codigocampanha codigocampanha
        INTO vnCODGRUPOCAMPANHA
        from PCDESCONTOCPRODRELAC
       where codprod = pCODPROD
         and codigocampanha in
             (select pcdescontoc.codigo
                from pcdescontoc
               where pcdescontoc.codigo = PCDESCONTOCPRODRELAC.CODIGOCAMPANHA
                 and pcdescontoc.dtfim >= TRUNC(sysdate)
                 and rownum = 1)
         and codigocampanha in
               (select codcombo
                from pccombocli, pcpedc
               where pccombocli.codfilial = pCODFILIAL
                 and pccombocli.codcli = pCODCLI
                 and pccombocli.codcombo = PCDESCONTOCPRODRELAC.Codigocampanha
                 and pccombocli.numped = pcpedc.numped
                 and pcpedc.posicao <> 'C')
         AND DECODE(VSVENDAEMB, 'S', NVL(CODAUXILIAR, -1), -1) =
             DECODE(VSVENDAEMB, 'S', NVL(pCODAUXILIAR, -1), -1)
         AND NVL(PCDESCONTOCPRODRELAC.perdesc, 0) = vnPerdesc
         AND ROWNUM = 1;
	exception
      when no_data_found then
        vnCODGRUPOCAMPANHA := 0;
	end;

    pCODIGOCAMPANHADESCONTO := vnCODGRUPOCAMPANHA;
    RETURN vnPerdesc;

  exception
    when no_data_found then
      RETURN 0;
  end;



  FUNCTION BuscaDescontoSQP(pNUMPED IN NUMBER, pCODCOMBO IN NUMBER, pMSG OUT VARCHAR2, pCODIGOCOMBOSQP OUT NUMBER,
                            pCODFILIAL  IN VARCHAR2 DEFAULT NULL, pTIPOVALOR IN NUMBER DEFAULT NULL,
                            pSEQ IN NUMBER DEFAULT NULL) RETURN NUMBER is
    vnPercDesc                 NUMBER := 0;
    vnQTPCPEDIFAIXA            NUMBER;
    vnQTUNIDADES               NUMBER;
    vsUNIDADE                  VARCHAR2(2);
    vnFAIXA                    NUMBER;
    P_CODFILIAL               VARCHAR2(4);

  BEGIN
    vnQTUNIDADES              := 0;
    vsUNIDADE                 := '';
	  pCODIGOCOMBOSQP           := 0;

    BEGIN

      BEGIN
        SELECT COUNT(E.UNIDADE), MAX(E.UNIDADE)
          INTO vnQTUNIDADES, vsUNIDADE
          FROM PCPEDI I, PCEMBALAGEM E
         WHERE I.NUMPED = PNUMPED
           AND I.CODCOMBO = PCODCOMBO
           AND I.CODPROD = E.CODPROD
           AND I.CODFILIALRETIRA = E.CODFILIAL
           AND I.CODAUXILIAR = E.CODAUXILIAR;
      EXCEPTION
        WHEN OTHERS THEN
          vnQTUNIDADES := 0;
          vsUNIDADE    := '';
      END;

      /*
      Validação inserida para que a campanha por Grupo de Produtos seja validada
      pela filial de venda e não a filial retira do produto,
      o que inibe validações incorretas caso ambas sejam diferentes
      e equipara o comportamento da rotina 316.
      */
      BEGIN
        SELECT NVL(pCODFILIAL, CODFILIALVENDA)
          INTO P_CODFILIAL
          FROM(SELECT NVL(CODFILIALNF, CODFILIAL) CODFILIALVENDA
                 FROM PCPEDC
                WHERE NUMPED = pNUMPED);
      EXCEPTION
        WHEN OTHERS THEN
          P_CODFILIAL := pCODFILIAL;
      END;

      FOR FAIXAS IN (SELECT *
                       FROM
                        (SELECT C.*
                         FROM PCDESCONTOCATEGORIA C INNER JOIN PCDESCONTOC D
                                                            ON D.CODIGO = C.CODIGO
                        WHERE D.CODIGO = pCODCOMBO
                          AND SYSDATE BETWEEN D.DTINICIO AND D.DTFIM
                          AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vsUNIDADE, 'XX') = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(C.UNIDADE_EMBALAGEM, vsUNIDADE), 'XX')
                          AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vnQTUNIDADES, -1) = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(vnQTUNIDADES,1), -1)
                          AND NVL(pTIPOVALOR, C.TIPOVALOR) = C.TIPOVALOR
                          AND NVL(pSEQ, C.SEQ) = C.SEQ
                        	ORDER BY PERCDESC DESC)
                   WHERE ROWNUM = 1) LOOP

       SELECT SUM(QT)
         INTO vnQTPCPEDIFAIXA
         FROM (SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I
                WHERE I.CODPROD = FAIXAS.TIPOVALOR
                  AND 'P - Produto' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE P.Codfornec = FAIXAS.TIPOVALOR
                  AND P.CODPROD = I.CODPROD
                  AND 'F - Fornecedor' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE P.CODEPTO = FAIXAS.TIPOVALOR
                  AND P.CODPROD = I.CODPROD
                  AND 'D - Departamento' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE P.CODSEC = FAIXAS.TIPOVALOR
                  AND P.CODPROD = I.CODPROD
                  AND 'S - Seção' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE P.CODCATEGORIA = FAIXAS.TIPOVALOR
                  AND P.CODPROD = I.CODPROD
                  AND 'C - Categoria' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE P.CODSUBCATEGORIA = FAIXAS.TIPOVALOR
                  AND P.CODPROD = I.CODPROD
                  AND 'SC - Sub-Categoria' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE P.CODLINHAPROD = FAIXAS.TIPOVALOR
                  AND P.CODPROD = I.CODPROD
                  AND 'LP - Linha de Produtos' = FAIXAS.TIPO
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
               UNION ALL
               SELECT SUM(QT/((CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
                                  (SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = I.CODFILIALRETIRA
                                     AND E.CODAUXILIAR = I.CODAUXILIAR)
                                ELSE
                                  1
                                END))) QT
                 FROM PCPEDI I, PCPRODUT P
                WHERE 'GP - Grupo de Produtos' = FAIXAS.TIPO
                  AND P.CODPROD = I.CODPROD
                  AND I.CODCOMBO = FAIXAS.CODIGO
                  AND I.NUMPED = pNUMPED
                  AND I.CODCOMBO = pCODCOMBO
                  AND EXISTS (SELECT 1
                                FROM PCGRUPOSCAMPANHAC GC, PCGRUPOSCAMPANHAI GI
                               WHERE GC.CODGRUPO = GI.CODGRUPO
                                 AND GC.CODGRUPO = FAIXAS.TIPOVALOR
                                 AND GI.CODGRUPO = FAIXAS.TIPOVALOR
                                 AND GC.TIPO = 'GP'
                                 AND GI.CODITEM = P.CODPROD
                                 AND GI.DTEXCLUSAO IS NULL
                                 AND GC.CODFILIAL = NVL(P_CODFILIAL, I.CODFILIALRETIRA)) ) T;

        IF (vnQTPCPEDIFAIXA BETWEEN FAIXAS.INICIOINTERVALO AND FAIXAS.FIMINTERVALO)
          AND FAIXAS.PERCDESC > vnPercDesc THEN

            vnPercDesc := FAIXAS.PERCDESC;
            vnFAIXA := FAIXAS.SEQ;

        END IF;

      END LOOP;

      if vnPercDesc <> 0 THEN
	    pCODIGOCOMBOSQP := pCODCOMBO;
	  END IF;
      RETURN vnPercDesc;

    EXCEPTION
      WHEN OTHERS THEN
        pMSG := 'Campanha de combo Cód: ' || pCODCOMBO || ', não localizada ou inexistente no pedido!';
        return 0;
    END;

  END;

FUNCTION BuscaDescontoGrupoCombo(pCODFILIAL     IN VARCHAR2,
                                 pCODPROD       IN NUMBER,
                                 pCODCLI        IN NUMBER,
                                 pNUMPED        IN NUMBER,
                                 pCODAUXILIAR   IN NUMBER,
                                 pInclusaoCombo IN VARCHAR2,
                                 pCODIGOCOMBODESCONTO OUT NUMBER) RETURN NUMBER is
    vnPerdesc      Number;
    vnPerDescTemp  Number;
    vnQT           NUMBER;
    vnQTCOMBOS     NUMBER;
    vsVendaEmb     VARCHAR2(1) := 'N';
    vnCODGRUPOCOMBO NUMBER;
    vnCODGRUPOCOMBOTEMP  NUMBER;

  begin
    vnPerdesc := 0;
    vnCODGRUPOCOMBO := 0;
	pCODIGOCOMBODESCONTO := 0;

    vsVendaEmb := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM'
                                                    ,pCODFILIAL
                                                    ,'N');
    --Loop buscando todas os grupos de campanhas
    FOR CAB IN (SELECT * FROM PCGRUPOCOMBOCLIC WHERE CODFILIAL = pCODFILIAL) LOOP
      --Variavel que armazena desconto encontrado para a campanha
      vnPerDescTemp := 0;
      vnCODGRUPOCOMBOTEMP := 0;
      --Loop buscando todos as campanhas que compoem esse grupo
      FOR ITEM IN (SELECT *
                     FROM PCGRUPOCOMBOCLII
                    WHERE CODGRUPOCOMBOCLIC = CAB.CODIGO) LOOP

        --quantidadede do combo vendida
        SELECT NVL(MIN(TRUNC(C.QT / DECODE(D.QTMINIMA, 0, 1, D.QTMINIMA))),
                   0) QT_COMBO
          INTO VNQT
          FROM PCCOMBOCLI C, PCDESCONTOI D
         WHERE C.CODCOMBO = D.CODIGO
           AND C.CODPROD = D.CODPROD
           AND DECODE(VSVENDAEMB, 'S', NVL(C.CODAUXILIAR, -1), -1) =
               DECODE(VSVENDAEMB, 'S', NVL(D.CODAUXILIAR, -1), -1)
           AND C.CODFILIAL = PCODFILIAL
           AND C.CODCLI = PCODCLI
           AND C.CODCOMBO = ITEM.CODIGOCAMPANHA
           AND C.CODPROD IN
               (SELECT CODPROD
                  FROM PCDESCONTOI
                 WHERE PCDESCONTOI.CODIGO IN
                       (SELECT CODIGOCAMPANHA
                          FROM PCGRUPOCOMBOCLII
                         WHERE CODGRUPOCOMBOCLIC = CAB.CODIGO))
           AND C.NUMPED = PNUMPED;

        --totalizando quantidade de combos inclusos no pedid.
        IF (NVL(pInclusaoCombo, 'N') = 'S') OR (CAB.TIPO = 'L') THEN
          SELECT NVL(COUNT(*), 0)
            INTO vnQTCOMBOS
            FROM (SELECT DISTINCT C.CODCOMBO
                    FROM PCCOMBOCLI C, PCDESCONTOI D
                   WHERE C.CODCOMBO = D.CODIGO
                     AND C.CODPROD = D.CODPROD
                     AND DECODE(VSVENDAEMB, 'S', NVL(C.CODAUXILIAR, -1), -1) =
                         DECODE(VSVENDAEMB, 'S', NVL(D.CODAUXILIAR, -1), -1)
                     AND C.CODFILIAL = pCodFilial
                     AND C.CODCLI = pCodCli
                     AND C.CODPROD IN (SELECT CODPROD
                                         FROM PCDESCONTOI
                                        WHERE PCDESCONTOI.CODIGO IN
                                              (SELECT CODIGOCAMPANHA
                                                 FROM PCGRUPOCOMBOCLII
                                                WHERE CODGRUPOCOMBOCLIC = CAB.CODIGO))
                     AND C.NUMPED = pNUMPED);
        END IF;
     --   END IF;

        IF (CAB.TIPO = 'C') THEN
            /*--Verifica se existe venda nesse mes utilizando a campanha
          select COUNT(1)
            INTO vnQT
            from PCCOMBOCLI
           where PCCOMBOCLI.codfilial = Pcodfilial
             and PCCOMBOCLI.codcli = Pcodcli
             AND PCCOMBOCLI.Codcombo = ITEM.CODIGOCAMPANHA
             AND PCCOMBOCLI.codprod in
                 (select codprod
                    FROM PCDESCONTOI
                   where PCDESCONTOI.CODIGO IN
                         (SELECT CODIGOCAMPANHA
                            FROM PCGRUPOCOMBOCLII
                           WHERE CODGRUPOCOMBOCLIC = CAB.CODIGO))
             AND PCCOMBOCLI.NUMPED = pNUMPED;
          --and PCCOMBOCLI.Codcombo = PCDESCONTOCPRODRELAC.codigocampanha;

          IF NVL(pInclusaoCombo, 'N') = 'S' THEN
            select COUNT(1)
             INTO vnQTOUTROCOMBO
             from PCCOMBOCLI
            where PCCOMBOCLI.codfilial = Pcodfilial
              and PCCOMBOCLI.codcli = Pcodcli
              AND PCCOMBOCLI.Codcombo <> ITEM.CODIGOCAMPANHA
              AND PCCOMBOCLI.codprod in
                  (select codprod
                     FROM PCDESCONTOI
                    where PCDESCONTOI.CODIGO IN
                          (SELECT CODIGOCAMPANHA
                             FROM PCGRUPOCOMBOCLII
                            WHERE CODGRUPOCOMBOCLIC = CAB.CODIGO))
              AND PCCOMBOCLI.NUMPED = pNUMPED;
          END IF;              */

          FOR camp IN (SELECT *
                         FROM PCDESCONTOI A
                        WHERE A.CODIGO = ITEM.CODIGOCAMPANHA)
          LOOP
            IF (CAMP.CODPROD = pCodProd) and
               (CAMP.CODAUXILIAR = pCodAuxiliar)
            THEN
              IF ((vnQT >= ITEM.QT) AND
                  (vnQTCOMBOS >= CAB.QTMINCOMBO))
              THEN
                -- verifica se o desconto é fixo(C) ou sobre uma lista(L)
                IF (vnPerdesc < ITEM.PERDESC) THEN
                  BEGIN
                    SELECT MAX(PCGRUPOCOMBOCLII.PERDESC), MAX(PCGRUPOCOMBOCLII.CODGRUPOCOMBOCLIC)
                      INTO VNPERDESCTEMP, vnCODGRUPOCOMBOTEMP
                      FROM PCGRUPOCOMBOCLII, PCGRUPOCOMBOCLIC, PCDESCONTOI
                     WHERE PCGRUPOCOMBOCLII.CODGRUPOCOMBOCLIC = PCGRUPOCOMBOCLIC.CODIGO
                       AND PCDESCONTOI.CODIGO = PCGRUPOCOMBOCLII.CODIGOCAMPANHA
                       AND TRUNC(SYSDATE) BETWEEN PCGRUPOCOMBOCLIC.DATAINI AND
                                                  PCGRUPOCOMBOCLIC.DATAFIM
                       AND PCDESCONTOI.CODPROD = PCODPROD
                       AND DECODE(VSVENDAEMB, 'S', NVL(PCDESCONTOI.CODAUXILIAR, -1), -1) =
                           DECODE(VSVENDAEMB, 'S', NVL(pCODAUXILIAR, -1), -1)
                       AND PCGRUPOCOMBOCLIC.CODFILIAL = PCODFILIAL;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      VNPERDESCTEMP := 0;
                      vnCODGRUPOCOMBOTEMP := 0;
                  END;
                END IF;
              END IF;
            END IF;
          END LOOP;


          /*--Se a quantidade de combos vendidos for maior ou igual a minima
          IF ((vnQT >= ITEM.QT) AND
              (vnQTCOMBOS >= CAB.QTMINCOMBO))
          THEN
            -- verifica se o desconto é fixo(C) ou sobre uma lista(L)
            IF (vnPerdesc < ITEM.PERDESC) THEN
              BEGIN
                SELECT MAX(PCGRUPOCOMBOCLII.PERDESC)
                  INTO VNPERDESCTEMP
                  FROM PCGRUPOCOMBOCLII, PCGRUPOCOMBOCLIC, PCDESCONTOI
                 WHERE PCGRUPOCOMBOCLII.CODGRUPOCOMBOCLIC =
                       PCGRUPOCOMBOCLIC.CODIGO
                   AND PCDESCONTOI.CODIGO = PCGRUPOCOMBOCLII.CODIGOCAMPANHA
                   AND TRUNC(SYSDATE) BETWEEN PCGRUPOCOMBOCLIC.DATAINI AND
                       PCGRUPOCOMBOCLIC.DATAFIM
                   AND PCDESCONTOI.CODPROD = PCODPROD
                   AND PCGRUPOCOMBOCLIC.CODFILIAL = PCODFILIAL;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  VNPERDESCTEMP := 0;
              END;
            END IF;
          ELSE
            vnPerDescTemp := 0;
      --      EXIT;
          END IF; */
        ELSE
          IF (CAB.TIPO = 'L') THEN
            select COUNT(1)
              INTO vnQT
              from PCDESCONTOCPRODRELAC
             where CODPROD = pCODPROD
               AND PCDESCONTOCPRODRELAC.Codigogrupocombo = ITEM.CODGRUPOCOMBOCLIC
               and ITEM.CODIGOCAMPANHA in
                   (select codcombo
                      from pccombocli
                     where codfilial = pCODFILIAL
                       and codcli = pCODCLI
                       and codcombo = ITEM.CODIGOCAMPANHA
                       AND NUMPED = pNUMPED
                       and data between trunc(sysdate, 'mm') and sysdate);
            --Se a quantidade de combos vendidos for maior ou igual a minima
            IF ((vnQT >= ITEM.QT) AND
                (vnQTCOMBOS >= CAB.QTMINCOMBO))
            THEN
              BEGIN

                --Busca desconto informado atravez de uma lista gravado an tabela PCDESCONTOCPRODRELAC
                SELECT PERDESC, Codigogrupocombo
                  into vnPerDescTemp, vnCODGRUPOCOMBOtemp
                  FROM PCDESCONTOCPRODRELAC
                 WHERE CODIGOGRUPOCOMBO = CAB.CODIGO
                   AND PCDESCONTOCPRODRELAC.CODPROD = pCODPROD
                   AND DECODE(VSVENDAEMB, 'S', NVL(PCDESCONTOCPRODRELAC.CODAUXILIAR, -1), -1) =
                       DECODE(VSVENDAEMB, 'S', NVL(pCODAUXILIAR, -1), -1)
                   AND ROWNUM = 1
                 ORDER BY PERDESC DESC;
              exception
                when no_data_found then
                  vnPerDescTemp := 0;
                  vnCODGRUPOCOMBOtemp :=0;
              END;
            ELSE
               if  (vnQTCOMBOS < CAB.QTMINCOMBO) then
                vnPerDescTemp := 0;
                vnCODGRUPOCOMBOtemp :=0;
              end if;
            --  EXIT;
            END IF;
          END IF;
        END IF;
      END LOOP;
      --Verifica se o desconto encontrado da campanha é a maior ate o momento

      IF NVL(VNPERDESCTEMP,-1) > NVL(VNPERDESC,-1) THEN
         IF (VNPERDESCTEMP > 0) THEN
           VNPERDESC := VNPERDESCTEMP;
           VNCODGRUPOCOMBO := VNCODGRUPOCOMBOTEMP;
         END IF;
      END IF;

      --vnPerdesc := GREATEST(nvl(vnPerDescTemp, -1), nvl(vnPerdesc, -1), 0);

    END LOOP;

    IF (VNCODGRUPOCOMBO > 0) THEN
      UPDATE PCCOMBOCLI SET  Codgrupocombo = VNCODGRUPOCOMBO
      WHERE NUMPED = pNUMPED AND
            CODCOMBO IN ( SELECT PCCOMBOCLI.CODCOMBO
                            FROM PCGRUPOCOMBOCLII, PCCOMBOCLI
                           WHERE PCGRUPOCOMBOCLII.CODIGOCAMPANHA = PCCOMBOCLI.CODCOMBO
                             AND CODGRUPOCOMBOCLIC = VNCODGRUPOCOMBO);
    END IF;
	
	pCODIGOCOMBODESCONTO := VNCODGRUPOCOMBO;

    --Retorna o maior desconto encontrado
    RETURN vnPerdesc;
  end;

  FUNCTION BuscaDesconto(pCODFILIAL     IN VARCHAR2,
                         pCODPROD       IN NUMBER,
                         pCODCLI        IN NUMBER,
                         pNUMPED        IN NUMBER,
                         pCODAUXILIAR   IN NUMBER,
                         pInclusaoCombo IN VARCHAR2 DEFAULT 'N',
                         pCODCOMBO      IN NUMBER DEFAULT 0) RETURN NUMBER is
	vnCodigoGrupoCombo   Number;
    vnCodigoCampanha     Number;
  begin
    RETURN BuscaCampanhaDesconto(pCODFILIAL,
                                 pCODPROD,
                                 pCODCLI,
                                 pNUMPED,
                                 pCODAUXILIAR,
                                 pInclusaoCombo,
                                 vnCodigoGrupoCombo,
                                 vnCodigoCampanha);
  END;
  
  FUNCTION BuscaCampanhaDesconto(pCODFILIAL     IN VARCHAR2,
                                 pCODPROD       IN NUMBER,
                                 pCODCLI        IN NUMBER,
                                 pNUMPED        IN NUMBER,
                                 pCODAUXILIAR   IN NUMBER,
                                 pInclusaoCombo IN VARCHAR2,
                                 pCODCOMBO      IN OUT NUMBER,
                                 pCODCAMPANHA   IN OUT NUMBER) RETURN NUMBER is
    vnPerdescGrupoCombo  Number;
    vnPerdescCampanha    Number;
    vnPerdescCampanhaSQP Number;
    vMSG                 Varchar2(4000);
	vnCodigoGrupoCombo   Number;
    vnCodigoCampanha     Number;
    vnCodigoCampanhaSQP  Number;
	vnPerdescRetorno     Number;
  begin

    pCODCOMBO    := NVL(pCODCOMBO, 0);
    pCODCAMPANHA := 0;
								 
    vnPerdescGrupoCombo := BuscaDescontoGrupoCombo(pCODFILIAL,
                                                   pCODPROD,
                                                   pCODCLI,
                                                   pNUMPED,
                                                   pCODAUXILIAR,
                                                   pInclusaoCombo,
                                                   vnCodigoGrupoCombo);

    vnPerdescCampanha   := BuscaDescontoCampanha(pCODFILIAL,
                                                 pCODPROD,
                                                 pCODCLI,
                                                 pCODAUXILIAR,
                                                 vnCodigoCampanha);

    vnPerdescCampanhaSQP := BuscaDescontoSQP(pNUMPED,
                                             pCODCOMBO,
                                             vMSG,
											 vnCodigoCampanhaSQP);
    --Retorna o maior desconto ou 0
    vnPerdescRetorno :=  GREATEST(nvl(vnPerdescCampanha, -1),
                         NVL(vnPerdescGrupoCombo, -1),
                         NVL(vnPerdescCampanhaSQP, -1),
                         0);
    IF (vnPerdescRetorno = nvl(vnPerdescCampanha, -1)) AND ((pCODCOMBO = 0) OR (pCODCOMBO IS NULL)) THEN
	  pCODCAMPANHA := vnCodigoCampanha;
    ELSIF (vnPerdescRetorno = nvl(vnPerdescGrupoCombo, -1)) AND ((pCODCOMBO = 0) OR (pCODCOMBO IS NULL)) THEN
	  pCODCOMBO := vnCodigoGrupoCombo;
	ELSIF (vnPerdescRetorno = nvl(vnPerdescCampanhaSQP, -1)) AND ((pCODCOMBO = 0) OR (pCODCOMBO IS NULL)) THEN
	  pCODCOMBO := pCODCOMBO;
	END IF;
					
    RETURN vnPerdescRetorno;
  END;

  FUNCTION VerificaCampanhaSQP(p_numped        in pcpedc.numped%type,
                               p_codfilial     in pcpedc.codfilial%type,
                               p_numregiao     in pcpedc.numregiao%type,
                               p_codcli        in pcpedc.codcli%type,
                               p_codativ       in pcclient.codatv1%type,
                               p_codusur       in pcpedc.codusur%type,
                               p_codsupervisor in pcpedc.codsupervisor%type,
                               p_coddistrib    in pcpedc.coddistrib%type,
                               p_codcombo      in pcdescontoc.codigo%type,
                               p_codplpag      in pcpedc.codplpag%type,
                               p_mensagem      out varchar2)
    RETURN BOOLEAN IS

    regpcconsum          pcconsum%rowtype;
    vicontador           number;
    vbvalido             boolean;
    vicontrestvalidas    number;
    vnMAXDESC            NUMBER;
    vnDESCONTO           NUMBER;
    vnPerDescTabela      NUMBER;
    vnPvendaVenda        NUMBER;
    vFatorPrecoMinimo    NUMBER;
    vsVendaEmbalagem     VARCHAR2(3);
    vnCodCampanhaSQP     NUMBER;
    vnQTUNIDADES         NUMBER;
    vsUNIDADE            VARCHAR2(100);
    vListaItensFaixa     VARCHAR2(32767);
    pMSGRetorno          VARCHAR2(32767);
    vSQL                 VARCHAR2(32767);
    vtCURSOR             SYS_REFCURSOR;
    vrTempDadosPedido    TR_DADOS_ITENSPEDIDO;
    vnContFaixasAtendidas    INTEGER := 0;
    vnContFaixasNaoAtendidas INTEGER := 0;
    vnCONTITENS_PEDIDO       INTEGER := 0;
    vsFaixasNaoAtendidas     VARCHAR2(1000);
    vbEncontrouDadosFaixa    BOOLEAN;
    vbProdutoValidouFaixa    BOOLEAN;
    vsListaItensNaoEncontrados  VARCHAR2(1000);
    vbItemExisteNaFaixaEncontrada BOOLEAN;
    VNCONTADOR                    INTEGER := 0;

  BEGIN

    select * into regpcconsum from pcconsum;

    vsVendaEmbalagem            := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',
                                                                      p_CodFilial,
                                                                      FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZAVENDAPOREMBALAGEM',
                                                                                                         '99',
                                                                                                         'N'));

    --verificar restrições para esta campanha
    select count(*)
      into vicontador
      from pcdescontorestricao r
     where r.codigo = p_Codcombo;

    if vicontador > 0 then

        -- Verificar se existem restrições cadastradas
        select count(*)
          into vicontrestvalidas
          from pcdescontorestricao r
         where r.codigo = p_Codcombo
           and r.codigoa = (case when r.tipo = 1 then p_codfilial
                                 when r.tipo = 7 then p_coddistrib
                                 else '0' end)
           and r.codigon =
               (case
                when r.tipo = 2 then p_numregiao
                when r.tipo = 3 then p_codativ
                when r.tipo = 4 then p_codsupervisor
                when r.tipo = 5 then p_codusur
                when r.tipo = 6 then p_Codcli
                when r.tipo = 8 then p_codplpag
                WHEN r.tipo = 9 THEN (SELECT CODREDE
                                        FROM PCCLIENT
                                       WHERE CODCLI = P_CODCLI)
                else 0 end);

        if vicontrestvalidas > 0 then
          vbvalido := true;

        else
          p_mensagem := 'Pedido não atende restrições da campanha de desconto do combo';
          vbvalido   := false;
        end if;

      else
        vbvalido := true;
      end if;

      IF vbvalido THEN
        IF vsVendaEmbalagem = 'S'
        THEN
          BEGIN
          SELECT COUNT(1)
            INTO vicontador
            FROM PCPEDI I, PCDESCONTOCATEGORIA DC
           WHERE I.NUMPED  = P_NUMPED
             AND I.CODCOMBO = P_CODCOMBO
             AND DC.CODIGO = I.CODCOMBO
             AND NOT EXISTS (SELECT 1
                              FROM PCEMBALAGEM E
                              WHERE E.CODPROD = I.CODPROD
                                AND E.CODAUXILIAR = I.CODAUXILIAR
                                AND E.CODFILIAL = I.CODFILIALRETIRA
                                AND CASE
                                      WHEN DC.EMBALAGEM_UNICA = 'S' THEN
                                        NVL(DC.UNIDADE_EMBALAGEM, E.UNIDADE)
                                      ELSE
                                        E.UNIDADE
                                      END = E.UNIDADE
                                    );
          EXCEPTION
            WHEN OTHERS THEN
              vicontador := 0;
          END;
          IF vicontador > 0 THEN
            p_mensagem := 'Pedido com itens de combo que foram digitados com unidade de venda diferente da definida para campanha SQP.';
            vbvalido   := false;
            RETURN FALSE;
          END IF;
        END IF;
      END IF;

      BEGIN
        SELECT COUNT(E.UNIDADE), MAX(E.UNIDADE)
          INTO vnQTUNIDADES, vsUNIDADE
          FROM PCPEDI I, PCEMBALAGEM E
         WHERE I.NUMPED = P_NUMPED
           AND I.CODCOMBO = P_CODCOMBO
           AND I.CODPROD = E.CODPROD
           AND I.CODFILIALRETIRA = E.CODFILIAL
           AND I.CODAUXILIAR = E.CODAUXILIAR;
      EXCEPTION
        WHEN OTHERS THEN
          vnQTUNIDADES := 0;
          vsUNIDADE    := '';
      END;

      BEGIN
        SELECT COUNT(CODPROD)
          INTO vnCONTITENS_PEDIDO
          FROM PCPEDI I
         WHERE I.NUMPED = P_NUMPED
           AND I.CODCOMBO = P_CODCOMBO;
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTITENS_PEDIDO := 0;
      END;

    IF vnCONTITENS_PEDIDO > 0 THEN
      FOR ITENS_PEDIDO IN(
        SELECT CODPROD
          FROM PCPEDI
         WHERE NUMPED = P_NUMPED
           AND CODCOMBO = P_CODCOMBO)

        LOOP

        vbEncontrouDadosFaixa    := False;
        vbProdutoValidouFaixa    := False;
        vnDESCONTO               := 0;
        vnContFaixasNaoAtendidas := 0;
        vsFaixasNaoAtendidas     := 0;

        FOR DADOS_FAIXAS IN(
           SELECT *
             FROM (
             SELECT C.*
               FROM PCDESCONTOCATEGORIA C INNER JOIN PCDESCONTOC D
                                                  ON D.CODIGO = C.CODIGO
              WHERE D.CODIGO = P_CODCOMBO
                AND SYSDATE BETWEEN D.DTINICIO AND D.DTFIM
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vsUNIDADE, 'XX') = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(C.UNIDADE_EMBALAGEM, vsUNIDADE), 'XX')
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vnQTUNIDADES, -1) = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(vnQTUNIDADES,1), -1)
                AND NVL(ITENS_PEDIDO.CODPROD, C.TIPOVALOR) = C.TIPOVALOR
              UNION
             SELECT C.*
               FROM PCDESCONTOCATEGORIA C INNER JOIN PCDESCONTOC D
                                                  ON D.CODIGO = C.CODIGO
              WHERE D.CODIGO = P_CODCOMBO
                AND SYSDATE BETWEEN D.DTINICIO AND D.DTFIM
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vsUNIDADE, 'XX') = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(C.UNIDADE_EMBALAGEM, vsUNIDADE), 'XX')
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vnQTUNIDADES, -1) = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(vnQTUNIDADES,1), -1)
                )
           ORDER BY PERCDESC DESC)

            LOOP

          vbEncontrouDadosFaixa := True;

          IF NOT(vbProdutoValidouFaixa) THEN
            vnDESCONTO := BuscaDescontoSQP(p_numped, p_codcombo, p_mensagem, vnCodCampanhaSQP, p_codfilial, DADOS_FAIXAS.TIPOVALOR,
                                           DADOS_FAIXAS.SEQ);

            IF NOT VBVALIDO THEN
              RETURN FALSE;
            ELSIF vnDESCONTO <= 0 THEN
              vnContFaixasNaoAtendidas := vnContFaixasNaoAtendidas + 1;

              IF vsFaixasNaoAtendidas IS NULL
                THEN
                  vsFaixasNaoAtendidas     := DADOS_FAIXAS.SEQ;
              ELSE
                  vsFaixasNaoAtendidas     := vsFaixasNaoAtendidas || ',' || DADOS_FAIXAS.SEQ;
              END IF;
            ELSE
              vListaItensFaixa := BuscaItensFaixaSQP(p_numped, p_codcombo, p_codfilial, DADOS_FAIXAS.TIPOVALOR, DADOS_FAIXAS.TIPO,
                                                     pMSGRetorno);

              IF vListaItensFaixa IS NOT NULL THEN

                BEGIN
                  vSQL := ' SELECT COUNT(*) CONTADOR
                              FROM PCPEDI
                             WHERE NUMPED = ' || p_NUMPED || '
                               AND CODCOMBO = ' || p_CODCOMBO || '
                               AND CODPROD IN(' || vListaItensFaixa || ')
                               AND CODPROD IN(' || ITENS_PEDIDO.CODPROD || ')
                             ORDER BY PCPEDI.CODPROD';
                  EXECUTE IMMEDIATE vSQL INTO VNCONTADOR;
                EXCEPTION
                  WHEN OTHERS THEN
                    VNCONTADOR := 0;
                END;
              END IF;

                vbItemExisteNaFaixaEncontrada := VNCONTADOR > 0;

                IF vListaItensFaixa IS NOT NULL
                  AND vbItemExisteNaFaixaEncontrada THEN
                BEGIN
                  vSQL := ' SELECT PTABELA, PVENDA, CODPROD, PERDESC
                              FROM PCPEDI
                             WHERE NUMPED = ' || p_NUMPED || '
                               AND CODCOMBO = ' || p_CODCOMBO || '
                               AND CODPROD IN(' || vListaItensFaixa || ')
                               AND CODPROD IN(' || ITENS_PEDIDO.CODPROD || ')
                             ORDER BY PCPEDI.CODPROD ';

                  OPEN vtCURSOR FOR vSQL;
                  FETCH vtCURSOR INTO vrTempDadosPedido;

                  WHILE vtCURSOR%FOUND
                    LOOP

                      IF NOT (vbProdutoValidouFaixa) THEN

                        vnPerDescTabela := vrTempDadosPedido.PTABELA-(vrTempDadosPedido.PTABELA*(vnDESCONTO/100));
                        vnPerDescTabela := ROUND((vnPerDescTabela),regpcconsum.numcasasdecvenda);
                        vnPvendaVenda     := ROUND(vrTempDadosPedido.PVENDA,regpcconsum.numcasasdecvenda);

                        if regpcconsum.numcasasdecvenda <= 3 then
                           vFatorPrecoMinimo := (1/(power(10, regpcconsum.numcasasdecvenda)));
                        else
                          vFatorPrecoMinimo := (3/(power(10, regpcconsum.numcasasdecvenda)));
                        end if;

                        if vnPerDescTabela > (vnPvendaVenda + vFatorPrecoMinimo) then
                          p_mensagem := 'Desconto acima do atendido pelo combo: ' || chr(13) ||
                                        ' Produto : ' || vrTempDadosPedido.CODPROD || ' Cod.Campanha : ' || p_CODCOMBO || chr(13) ||
                                        ' Preco de Tabela(sem desconto): ' || vrTempDadosPedido.PTABELA || chr(13) ||
                                        ' Preco de Tabela com Desconto: ' || vnPerDescTabela || chr(13) ||
                                        ' Preco de Venda(com desconto): ' || vrTempDadosPedido.PVENDA || chr(13) ||
                                        ' %Desc.Max. Campanha : ' || vnDESCONTO || chr(13) ||
                                        ' %Desc. Aplicado: ' || vrTempDadosPedido.PERDESC || chr(13) ||
                                        ' Fator de Decimais: ' || vFatorPrecoMinimo;
                          return false;
                        end if;

                        vnContFaixasAtendidas := vnContFaixasAtendidas + 1;
                        vbProdutoValidouFaixa := True;

                      END IF;

                    FETCH vtCURSOR INTO vrTempDadosPedido;

                  END LOOP;
                EXCEPTION
                  WHEN OTHERS THEN
                    p_mensagem := SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';';
                END;
              ELSIF NOT(vbItemExisteNaFaixaEncontrada)
                THEN NULL;
              ELSE
                p_mensagem := 'Lista de itens da Campanha SQP não localizada. ';
                return false;

              END IF ;
            END IF;
          END IF;

        END LOOP;

        IF NOT(vbEncontrouDadosFaixa)
          THEN
            IF vsListaItensNaoEncontrados IS NULL
              THEN
                vsListaItensNaoEncontrados := ITENS_PEDIDO.CODPROD;
            ELSE
              vsListaItensNaoEncontrados := vsListaItensNaoEncontrados || ';' || ITENS_PEDIDO.CODPROD;
            END IF;
        END IF;

        IF NOT (vbProdutoValidouFaixa) THEN
          p_mensagem := 'Item ' || ITENS_PEDIDO.CODPROD ||' não atende a(s) faixa(s) de desconto da campanha: ' || P_CODCOMBO;
          return false;
        END IF;

      END LOOP;

      IF vnCONTITENS_PEDIDO <= vnContFaixasAtendidas THEN
        IF vnContFaixasNaoAtendidas > 0
          THEN
            IF vnContFaixasAtendidas = vnCONTITENS_PEDIDO THEN
                return true;
            ELSE
               p_mensagem := 'Pedido não atende a(s) faixa(s) de desconto ' || vsFaixasNaoAtendidas ||' da campanha: ' || P_CODCOMBO;
               return false;
            END IF;
        ELSE
          return true;
        END IF;
      ELSE
        p_mensagem := 'Item(ns) ' || vsListaItensNaoEncontrados || ' do pedido não atende(m) a(s) faixa(s) de desconto da campanha: ' || P_CODCOMBO;
        return false;
      END IF;
    ELSE
      p_mensagem := 'Lista de itens da Campanha SQP não localizada no pedido. ';
      return false;
    END IF;

  END;

  FUNCTION VerificaCampanhasDesconto(p_numped        in pcpedc.numped%type,
                                     p_codfilial     in pcpedc.codfilial%type,
                                     p_numregiao     in pcpedc.numregiao%type,
                                     p_codcli        in pcpedc.codcli%type,
                                     p_codativ       in pcclient.codatv1%type,
                                     p_codusur       in pcpedc.codusur%type,
                                     p_codsupervisor in pcpedc.codsupervisor%type,
                                     p_coddistrib    in pcpedc.coddistrib%type,
                                     p_codcombo      in pcdescontoc.codigo%type,
                                     p_mensagem      out varchar2,
                                     p_codplpag      in pcpedc.codplpag%type default 0)
    return boolean is

    vicont               number;
    vicontador           number;
    vsutilizacodcliprinc pcdescontoc.utilizacodcliprinc%type;
    viexisteped          number;
    vbvalido             boolean;
    vnqt                 number;
    vnporiginal          number;
    vnpvendaanterior     number;
    regpcconsum          pcconsum%rowtype;
    vicontrestvalidas    number;
    vncodprodprinc       number;
    vddata               date;
    viexisteseqatende    number;
    vnseqatende          number;
    vscodplpag           varchar2(10);
    vsVendaEmbalagem     VARCHAR2(3);
    VNPTABELA            number;
    vsTIPOCAMPANHA       PCDESCONTOC.TIPOCAMPANHA%TYPE;
    pmaxdesc             number;
    vFatorPrecoMinimo    number(18,6);

  begin

    vbvalido   := true;
    p_mensagem := null;

    vddata := sysdate;

    vsVendaEmbalagem            := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',
                                                                      p_CodFilial,
                                                                      FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZAVENDAPOREMBALAGEM',
                                                                                                         '99',
                                                                                                         'N'));


    if p_codplpag = 0 then
       vscodplpag := null;
    else
       vscodplpag := p_codplpag;
    end if;

    select * into regpcconsum from pcconsum;

    if regpcconsum.numcasasdecvenda <= 3 then
      vFatorPrecoMinimo := (1/(power(10, regpcconsum.numcasasdecvenda)));
    else
      vFatorPrecoMinimo := (3/(power(10, regpcconsum.numcasasdecvenda)));
    end if;

    --verifica se campanha está ativa
    select count(*)
      into vicont
      from pcdescontoc c
     where c.tipocampanha in ('MQT','MIQ','SQP')
       and decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(c.dtinicio),c.dtinicio) <= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
       and decode(to_char(c.dtfim,'hh24:mi:ss'),'00:00:00',trunc(c.dtfim),c.dtfim) >= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
       and c.codigo = p_codcombo;

       /*AND (((vsVendaEmbalagem = 'S') AND (C.CODFILIAL IS NOT NULL)) OR  --632.096792.2016
            ((vsVendaEmbalagem = 'N') AND ((C.CODFILIAL = p_CodFilial) OR (C.CODFILIAL IS NULL))))*/

    if vicont > 0 then
      select c.utilizacodcliprinc
        into vsutilizacodcliprinc
        from pcdescontoc c
       where c.tipocampanha in ('MQT','MIQ', 'SQP')
       and decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(c.dtinicio),c.dtinicio) <= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
       and decode(to_char(c.dtfim,'hh24:mi:ss'),'00:00:00',trunc(c.dtfim),c.dtfim) >= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
         and c.codigo = p_codcombo;
    else
      p_mensagem := 'Campanha informada no combo esta inativa !';
      vbvalido   := false;
    end if;

    -- Verificar CAMPANHASQP Primeiro
    BEGIN
      SELECT C.TIPOCAMPANHA INTO vsTIPOCAMPANHA
        FROM PCDESCONTOC C
       WHERE C.CODIGO = p_codcombo;

      IF vsTIPOCAMPANHA = 'SQP' THEN
        Return VerificaCampanhaSQP(p_numped,
                                   p_codfilial,
                                   p_numregiao,
                                   p_codcli,
                                   p_codativ,
                                   p_codusur,
                                   p_codsupervisor,
                                   p_coddistrib,
                                   p_codcombo,
                                   vscodplpag,
                                   p_mensagem);
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    ---------------------------------

    if vicont > 0 then

      --verificar restrições para esta campanha
      select count(*)
        into vicontador
        from pcdescontorestricao r
       where r.codigo = p_Codcombo;

      if vicontador > 0 then

        select count(*)
          into vicontrestvalidas
          from pcdescontorestricao r
         where r.codigo = p_Codcombo
           and r.codigoa = (case when r.tipo = 1 then p_codfilial
                                 when r.tipo = 7 then p_coddistrib
                                 else '0' end)
           and r.codigon =
               (case
                when r.tipo = 2 then p_numregiao
                when r.tipo = 3 then p_codativ
                when r.tipo = 4 then p_codsupervisor
                when r.tipo = 5 then p_codusur
                when r.tipo = 6 then p_Codcli
                when r.tipo = 8 then to_number(vscodplpag)
                WHEN r.tipo = 9 THEN (SELECT CODREDE
                                        FROM PCCLIENT
                                       WHERE CODCLI = P_CODCLI)
                else 0 end);

        --dados do pedido atendem as restrições
        if vicontrestvalidas > 0 then

          --verifica se todos os itens do combo estão no pedido de venda
          -- e com quantidade e preço igual ao superior a estipulada na campanha

          vbvalido := true;

          for regitens in (select c.codigo,
                                  i.qtminima,
                                  i.perdesc,
                                  i.codprod,
                                  nvl(c.utilizacodprodprinc,'N') utilizacodprodprinc,
                                  i.qtmaxima,
                                  c.tipocampanha,
                                  i.sequencia
                             from pcdescontoc c, pcdescontoi i
                            where c.tipocampanha in ('MQT','MIQ')
                              and decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(c.dtinicio),c.dtinicio) <= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
                              and decode(to_char(c.dtfim,'hh24:mi:ss'),'00:00:00',trunc(c.dtfim),c.dtfim) >= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
                              and c.codigo = p_codcombo
                              and c.codigo = i.codigo) loop

            if vbvalido = true then

              select count(*)
                into viexisteped
                from pcpedi, pcprodut
               where pcpedi.numped = p_numped
                 and pcpedi.codprod = pcprodut.codprod
                 and (pcprodut.codprod = regitens.codprod or
                       (regitens.utilizacodprodprinc = 'S' and
                       pcprodut.codprodprinc = regitens.codprod))
                 and pcpedi.codcombo = p_codcombo;

              --produto existe no pedido
              if viexisteped > 0 then

                select sum(case
                              when (vsVendaEmbalagem = 'S')  then  qt
                              else  qt end)
                  into vnqt
                  from pcpedi, pcprodut
                 where pcpedi.numped = p_numped
                   and pcpedi.codprod = pcprodut.codprod
                   and (pcprodut.codprod = regitens.codprod or
                       (regitens.utilizacodprodprinc = 'S' and
                       pcprodut.codprodprinc = regitens.codprod))
                   and pcpedi.codcombo = p_codcombo;

                  vnseqatende := null;
                  viexisteseqatende := 0;
                  pmaxdesc          := 0;

                  if regitens.tipocampanha = 'MIQ' then

                     -- VEN-9453: Ajustada a select para não buscar mais de 1 registro por faixa. Assim, prevalecerá o maior desconto.
                      BEGIN
                        select B.* into viexisteseqatende
                          from(select count(*)
                      --  into viexisteseqatende
                                    from pcdescontoi p
                                   where p.codigo = p_codcombo
                                     and p.codprod = regitens.codprod
                                     and vnqt >= p.qtminima
                                     and vnqt <= p.qtmaxima
                                   group by p.sequencia
                                   order by max(p.perdesc) desc) B
                           where ROWNUM = 1;
                        EXCEPTION
                          WHEN NO_DATA_FOUND then
                          viexisteseqatende := 0;
                       END;

                       if viexisteseqatende = 0 and
                         regitens.tipocampanha = 'MIQ' then
                        vnqt := 0;
                       -- Se não localizar a faixa pelo processo normal, valida na divisão pela qtunitemb.
                        select sum(case
                                     when (vsVendaEmbalagem = 'S') then
                                      qt / nvl(qtunitemb, 1)
                                     else
                                      qt
                                   end)
                          into vnqt
                          from pcpedi, pcprodut
                         where pcpedi.numped = p_numped
                           and pcpedi.codprod = pcprodut.codprod
                           and (pcprodut.codprod = regitens.codprod or
                               (regitens.utilizacodprodprinc = 'S' and
                               pcprodut.codprodprinc = regitens.codprod))
                           and pcpedi.codcombo = p_codcombo;

                        vnseqatende       := null;
                        viexisteseqatende := 0;
                        pmaxdesc          := 0;

                        if regitens.tipocampanha = 'MIQ' then

                          -- VEN-9453: Ajustada a select para não buscar mais de 1 registro por faixa. Assim, prevalecerá o maior desconto.
                          BEGIN
                            select B.*
                              into viexisteseqatende
                              from (select count(*)
                                    --  into viexisteseqatende
                                      from pcdescontoi p
                                     where p.codigo = p_codcombo
                                       and p.codprod = regitens.codprod
                                       and vnqt >= p.qtminima
                                       and vnqt <= p.qtmaxima
                                     group by p.sequencia
                                     order by max(p.perdesc) desc) B
                             where ROWNUM = 1;
                          EXCEPTION
                            WHEN NO_DATA_FOUND then
                              viexisteseqatende := 0;
                          END;
                        end if;
                       end if;

                      if viexisteseqatende > 0 then

                       -- VEN-9453: Ajustada a select para não buscar mais de 1 registro por faixa. Assim, prevalecerá o maior desconto.
                        BEGIN
                        select A.* into vnseqatende, pmaxdesc
                          from (select p.sequencia, max(nvl(p.perdesc,0))
                                --  into vnseqatende
                                  from pcdescontoi p
                                 where p.codigo = p_codcombo
                                   and p.codprod = regitens.codprod
                                   and vnqt >= p.qtminima
                                   and vnqt <= p.qtmaxima
                                 group by p.sequencia
                                 order by max(p.perdesc) desc) A
                         where ROWNUM = 1;
                       EXCEPTION
                          WHEN NO_DATA_FOUND then
                            vnseqatende := 0;
                            pmaxdesc    := 0;
                       END;

                      end if;

                   end if;

               if viexisteseqatende = 0 and regitens.tipocampanha = 'MIQ' then

                   p_mensagem := 'Produto : ' || regitens.codprod ||
                                      ' não atende a nenhuma das faixas de quantidade cadastradas no combo';
                   vbvalido   := false;

                   exit;

               else

                --quantidade vendida é superior a minima da campanha
                if vnqt >= regitens.qtminima then

                --quantidade vendida é inferior a maxima da campanha
                  if (vnqt <= regitens.qtmaxima and regitens.tipocampanha = 'MIQ' ) or regitens.tipocampanha = 'MQT' then


                        select --sum(pcpedi.poriginal * (1 + (p_pertxfim / 100))),
                               --sum(pcpedi.ptabela * (1 + (p_pertxfim / 100))),   -- 1067.089664.2016 - neste ponto, o percentual de acrésc./Desc por plano pgto, já foi aplicado
                               sum(pcpedi.poriginal),
                               sum(pcpedi.pvenda),
                               SUM(pcpedi.ptabela)
                          into vnporiginal, vnpvendaanterior, vnptabela
                          from pcpedi, pcprodut
                         where pcpedi.numped = p_numped
                           and pcpedi.codprod = pcprodut.codprod
                           and (pcprodut.codprod = regitens.codprod or
                               (regitens.utilizacodprodprinc = 'S' and
                               pcprodut.codprodprinc = regitens.codprod))
                           and pcpedi.codcombo = p_codcombo;

                        if round(vnpvendaanterior, regpcconsum.numcasasdecvenda) <
                           round((vnporiginal * (1 - regitens.perdesc / 100)),
                                 regpcconsum.numcasasdecvenda) then

                          for reg in (select pcpedi.codprod,
                                             --round((pcpedi.poriginal *
                                             -- 1067.089664.2016 - neste ponto, o percentual de acrésc./Desc por plano pgto, já foi aplicado
                                             --round((pcpedi.ptabela * (1 + (p_pertxfim / 100))), regpcconsum.numcasasdecvenda) poriginal,
                                             pcpedi.poriginal,
                                             pcpedi.pvenda as pvendaanterior
                                        from pcpedi, pcprodut
                                       where pcpedi.numped = p_numped
                                         and pcpedi.codprod = pcprodut.codprod
                                         and (pcprodut.codprod = regitens.codprod or
                                             (regitens.utilizacodprodprinc = 'S' and
                                             pcprodut.codprodprinc = regitens.codprod))
                                         and pcpedi.codcombo = p_codcombo) loop

                            if round(reg.pvendaanterior,
                                     regpcconsum.numcasasdecvenda) + vFatorPrecoMinimo <
                               round((reg.poriginal *
                                     (1 - regitens.perdesc / 100)),
                                     regpcconsum.numcasasdecvenda) then

                              vbvalido := false;

                              p_mensagem := 'Produto : ' || reg.codprod ||
                                            ' preco de venda menor que minimo estipulado no combo #' ||
                                            'Preco venda enviado pelo palm :' ||
                                            round(reg.pvendaanterior,
                                                  regpcconsum.numcasasdecvenda) || '#' ||
                                            'Preco original :' || reg.poriginal || '#' ||
                                            'Perc Desc combo :' ||
                                            regitens.perdesc || '#' ||
                                            'Preco original com desconto :' ||
                                            round((reg.poriginal *
                                                  (1 - regitens.perdesc / 100)),
                                                  regpcconsum.numcasasdecvenda);
                            end if;

                          end loop;

                        end if;

                   else


                         if (regitens.sequencia = vnseqatende and regitens.tipocampanha = 'MIQ') or (regitens.tipocampanha = 'MQT') then

                            p_mensagem := 'Produto : ' || regitens.codprod ||
                                        ' não atende a quantidade maxima estipulada no combo';
                            vbvalido   := false;
                         end if;


                   end if;

                else
                  if (regitens.sequencia = vnseqatende and regitens.tipocampanha = 'MIQ') or (regitens.tipocampanha = 'MQT') then

                     p_mensagem := 'Produto : ' || regitens.codprod ||
                                ' não atende a quantidade minima estipulada no combo';
                      vbvalido   := false;
                  end if;

                end if;
              end if;

              else

                vbvalido   := false;
                p_mensagem := 'Produto : ' || regitens.codprod ||
                              ' compõe o combo e não existe no pedido';

              end if;

            end if;


          end loop;

        else
          p_mensagem := 'Pedido não atende restrições da campanha de desconto do combo';
          vbvalido   := false;
        end if;

        --validações para pedidos de combo sem restrições
      else

        --verifica se todos os itens do combo estão no pedido de venda
        -- e com quantidade e preço igual ao superior a estipulada na campanha

        vbvalido := true;

        for regitens in (select c.codigo,
                                i.qtminima,
                                i.perdesc,
                                i.codprod,
                                nvl(c.utilizacodprodprinc,'N') utilizacodprodprinc,
                                i.qtmaxima,
                                c.tipocampanha,
                                i.sequencia
                           from pcdescontoc c, pcdescontoi i
                          where c.tipocampanha in ('MQT','MIQ')
                            and decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(c.dtinicio),c.dtinicio) <= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
                            and decode(to_char(c.dtfim,'hh24:mi:ss'),'00:00:00',trunc(c.dtfim),c.dtfim) >= decode(to_char(c.dtinicio,'hh24:mi:ss'),'00:00:00',trunc(vddata),vddata)
                            and c.codigo = p_codcombo
                            and c.codigo = i.codigo) loop

          if vbvalido = true then

            select codprodprinc
              into vncodprodprinc
              from pcprodut
             where codprod = regitens.codprod;

            select count(*)
              into viexisteped
              from pcpedi, pcprodut
             where pcpedi.numped = p_numped
               and pcpedi.codprod = pcprodut.codprod
               and (pcprodut.codprod = regitens.codprod or
                   (regitens.utilizacodprodprinc = 'S' and
                   pcprodut.codprodprinc = regitens.codprod))
               and pcpedi.codcombo = p_codcombo;

            --produto existe no pedido
            if viexisteped > 0 then

              select sum(case
                              when (vsVendaEmbalagem = 'S')  then  qt
                              else  qt end)
                into vnqt
                from pcpedi, pcprodut
               where pcpedi.numped = p_numped
                 and pcpedi.codprod = pcprodut.codprod
                 and (pcprodut.codprod = regitens.codprod or
                     (regitens.utilizacodprodprinc = 'S' and
                     pcprodut.codprodprinc = regitens.codprod))
                 and pcpedi.codcombo = p_codcombo;

                  vnseqatende := null;
                  viexisteseqatende := 0;

                  if regitens.tipocampanha = 'MIQ' then

                      select count(*)
                      into viexisteseqatende
                      from  pcdescontoi p
                      where p.codigo = p_codcombo
                      and   p.codprod = regitens.codprod
                      and   p.qtminima <= vnqt
                      and   p.qtmaxima >= vnqt;

                  if viexisteseqatende = 0 then
                    vnqt:= 0;
                  -- Se não localizar a faixa pelo processo normal, valida na divisão pela qtunitemb.
                    select sum(case
                              when (vsVendaEmbalagem = 'S')  then  qt / nvl(qtunitemb,1)
                              else  qt end)
                    into vnqt
                    from pcpedi, pcprodut
                    where pcpedi.numped = p_numped
                     and pcpedi.codprod = pcprodut.codprod
                     and (pcprodut.codprod = regitens.codprod or
                         (regitens.utilizacodprodprinc = 'S' and
                         pcprodut.codprodprinc = regitens.codprod))
                     and pcpedi.codcombo = p_codcombo;

                      vnseqatende := null;
                      viexisteseqatende := 0;

                    if regitens.tipocampanha = 'MIQ' then

                      select count(*)
                      into viexisteseqatende
                      from  pcdescontoi p
                      where p.codigo = p_codcombo
                      and   p.codprod = regitens.codprod
                      and   p.qtminima <= vnqt
                      and   p.qtmaxima >= vnqt;

                    end if;
                  end if;

                  if viexisteseqatende > 0 then

                    select p.sequencia
                    into vnseqatende
                    from  pcdescontoi p
                    where p.codigo = p_codcombo
                    and   p.codprod = regitens.codprod
                    and   p.qtminima <= vnqt
                    and   p.qtmaxima >= vnqt;

                  end if;

               end if;

               if viexisteseqatende = 0 and regitens.tipocampanha = 'MIQ' then

                   p_mensagem := 'Produto : ' || regitens.codprod ||
                                      ' não atende a nenhuma das faixas de quantidade cadastradas no combo';
                   vbvalido   := false;

                   exit;

               else


              --quantidade vendida é superior a minima da campanha
              if vnqt >= regitens.qtminima then


                if (vnqt <= regitens.qtmaxima and regitens.tipocampanha = 'MIQ') or regitens.tipocampanha = 'MQT' then

                    select --sum(pcpedi.poriginal * (1 + (p_pertxfim / 100))),
                           -- 1067.089664.2016 - neste ponto, o percentual de acrésc./Desc por plano pgto, já foi aplicado
                           --sum(pcpedi.ptabela * (1 + (p_pertxfim / 100))),
                           sum(pcpedi.poriginal),
                           sum(pcpedi.pvenda),
                           sum(pcpedi.ptabela)
                      into vnporiginal, vnpvendaanterior, vnptabela
                      from pcpedi, pcprodut
                     where pcpedi.numped = p_numped
                       and pcpedi.codprod = pcprodut.codprod
                       and (pcprodut.codprod = regitens.codprod or
                           (regitens.utilizacodprodprinc = 'S' and
                           pcprodut.codprodprinc = regitens.codprod))
                       and pcpedi.codcombo = p_codcombo;



                    if round(vnpvendaanterior, regpcconsum.numcasasdecvenda) + vFatorPrecoMinimo <
                       round((vnporiginal * (1 - regitens.perdesc / 100)),
                             regpcconsum.numcasasdecvenda) then

                      for reg in (select pcpedi.codprod,
                                         --round((pcpedi.poriginal *
                                         -- 1067.089664.2016 - neste ponto, o percentual de acrésc./Desc por plano pgto, já foi aplicado
                                         --round((pcpedi.ptabela * (1 + (p_pertxfim / 100))), regpcconsum.numcasasdecvenda) poriginal,
                                         pcpedi.poriginal,
                                         pcpedi.pvenda as pvendaanterior
                                    from pcpedi, pcprodut
                                   where pcpedi.numped = p_numped
                                     and pcpedi.codprod = pcprodut.codprod
                                     and (pcprodut.codprod = regitens.codprod or
                                         (regitens.utilizacodprodprinc = 'S' and
                                         pcprodut.codprodprinc = regitens.codprod))
                                     and pcpedi.codcombo = p_codcombo) loop

                        if round(reg.pvendaanterior,
                                 regpcconsum.numcasasdecvenda) + vFatorPrecoMinimo <
                           round((reg.poriginal * (1 - regitens.perdesc / 100)),
                                 regpcconsum.numcasasdecvenda) then

                          vbvalido := false;

                          p_mensagem := 'Produto : ' || reg.codprod ||
                                        ' preco de venda menor que minimo estipulado no combo #' ||
                                        'Preco venda enviado pelo palm :' ||
                                        round(reg.pvendaanterior,
                                              regpcconsum.numcasasdecvenda) || '#' ||
                                        'Preco original :' || reg.poriginal || '#' ||
                                        'Perc Desc combo :' || regitens.perdesc || '#' ||
                                        'Preco original com desconto :' ||
                                        round((reg.poriginal *
                                              (1 - regitens.perdesc / 100)),
                                              regpcconsum.numcasasdecvenda);
                        end if;

                      end loop;

                    end if;

                 else

                       if (regitens.sequencia = vnseqatende and regitens.tipocampanha = 'MIQ') or (regitens.tipocampanha = 'MQT') then

                          p_mensagem := 'Produto : ' || regitens.codprod ||
                                        ' não atende a quantidade maxima estipulada no combo';
                          vbvalido   := false;

                        end if;

                end if;


              else

                if (regitens.sequencia = vnseqatende and regitens.tipocampanha = 'MIQ') or (regitens.tipocampanha = 'MQT') then

                  p_mensagem := 'Produto : ' || regitens.codprod ||
                              ' não atende a quantidade minima estipulada no combo';
                  vbvalido   := false;

                end if;
              end if;

            end if;

            else

              vbvalido   := false;
              p_mensagem := 'Produto : ' || regitens.codprod ||
                            ' compõe o combo e não existe no pedido';

            end if;

          end if;

        end loop;

      end if;

    end if;

    return vbvalido;

  END verificacampanhasdesconto;


  FUNCTION BuscaItensFaixaSQP(pNUMPED       IN NUMBER,
                              pCODCOMBO     IN NUMBER,
                              pCODFILIAL    IN VARCHAR2 DEFAULT NULL,
                              pCODFAIXA     IN NUMBER DEFAULT NULL,
                              pTIPOCAMPANHA IN VARCHAR2 DEFAULT NULL,
                              pMSG          OUT VARCHAR2) RETURN VARCHAR2 is

  vsListaProdutos VARCHAR2(4000);

  BEGIN
    vsListaProdutos := '';

    FOR DADOS_CODPROD IN (SELECT I.CODPROD
                            FROM PCPEDI I
                           WHERE I.CODPROD = pCODFAIXA
                             AND 'P - Produto' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPED = pNUMPED
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE P.Codfornec = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'F - Fornecedor' = pTIPOCAMPANHA
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE P.CODEPTO = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'D - Departamento' = pTIPOCAMPANHA
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE P.CODSEC = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'S - Seção' = pTIPOCAMPANHA
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE P.CODCATEGORIA = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'C - Categoria' = pTIPOCAMPANHA
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE P.CODSUBCATEGORIA = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'SC - Sub-Categoria' = pTIPOCAMPANHA
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE P.CODLINHAPROD = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'LP - Linha de Produtos' = pTIPOCAMPANHA
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDI I, PCPRODUT P
                           WHERE 'GP - Grupo de Produtos' = pTIPOCAMPANHA
                             AND P.CODPROD = I.CODPROD
                             AND I.NUMPED = pNUMPED
                             AND I.CODCOMBO = pCODCOMBO
                             AND EXISTS
                           (SELECT 1
                                    FROM PCGRUPOSCAMPANHAC GC,
                                         PCGRUPOSCAMPANHAI GI
                                   WHERE GC.CODGRUPO = GI.CODGRUPO
                                     AND GC.CODGRUPO = pCODFAIXA
                                     AND GI.CODGRUPO = pCODFAIXA
                                     AND GC.TIPO = 'GP'
                                     AND GI.CODITEM = P.CODPROD
                                     AND GI.DTEXCLUSAO IS NULL
                                     AND GC.CODFILIAL =
                                         NVL(pCODFILIAL, I.CODFILIALRETIRA)))

     LOOP
      IF SQL%ROWCOUNT > 0 THEN
        IF vsListaProdutos IS NULL THEN
          vsListaProdutos := DADOS_CODPROD.CODPROD;
        ELSE
          vsListaProdutos := vsListaProdutos || ',' || DADOS_CODPROD.CODPROD;
        END IF;
      END IF;

    END LOOP;

    if vsListaProdutos IS NOT NULL THEN
      pMSG := 'Produtos da faixa ' || pCODFAIXA ||
              ', da campanha combo Cód: ' || pCODCOMBO ||
              ' validado(s) com sucesso!';
    END IF;
    RETURN vsListaProdutos;

  EXCEPTION
    WHEN OTHERS THEN
      pMSG := 'Produtos da faixa ' || pCODFAIXA ||
              ', da campanha combo Cód: ' || pCODCOMBO ||
              ', não localizado(s) ou inexistente(s) no pedido!';
      return '0';
  END;

END PKG_CAMPANHACOMBO;
