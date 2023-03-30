
CREATE OR REPLACE PACKAGE BODY CONTROLE_PERMANENTE IS
  /* INICIO PACKAGE BODY */

  /* INICIO METODO RECALCULARCUSTOS */
  FUNCTION RECALCULARCUSTOS(P_CODFILIAL VARCHAR2,
                            DTINICIAL   DATE,
                            DTFINAL     DATE) RETURN VARCHAR2 IS
    ULTIMOMOVDIA    NUMBER(16, 6);
    VMSGERRO        VARCHAR2(4000);
    VCUSTOINDUSTRIA PCCONSUM.CUSTOINDUSTRIA%TYPE;
  BEGIN
    VMSGERRO := '';

    /* NOVOS VALORES DE CUSTOS SERÃO ATUALIZADOS CONFORME O VALOR DO PARÂMETRO DO CUSTO DA INDÚSTRIA */
    SELECT CUSTOINDUSTRIA INTO VCUSTOINDUSTRIA FROM PCCONSUM;

    FOR REG IN (SELECT CODPROD, CODFILIAL
                  FROM PCCUSTOPRODUCAOMENSAL
                 WHERE CODFILIAL = P_CODFILIAL
                   AND TO_CHAR(DATA,'MM/YYYY') = TO_CHAR(DTINICIAL,'MM/YYYY')) LOOP

      IF VMSGERRO IS NULL THEN
        VMSGERRO := ATUALIZARCUSTOINICIALOPMES(P_CODFILIAL,
                                               REG.CODPROD,
                                               DTINICIAL,
                                               DTFINAL);
      END IF;

      IF VMSGERRO IS NULL THEN
        /* PROCESSAR E INSERIR O NOVO CUSTO NA PCCONTROLEPERMANENTE */
        VMSGERRO := PROCESSAR(P_CODFILIAL, DTINICIAL, DTFINAL, REG.CODPROD);
      END IF;

      IF VMSGERRO IS NULL THEN
        FOR REG2 IN (SELECT VLCUSTO, ROWID_PCMOV
                       FROM PCCONTROLEPERMANENTE
                      WHERE CODFILIAL = P_CODFILIAL
                        AND CODPROD = REG.CODPROD
                        AND DATA BETWEEN DTINICIAL AND DTFINAL) LOOP
          /* ATUALIZAR AS MOVIMENTACOES COM O NOVO CUSTO DE ACORDO COM O CUSTO DA INDÚSTRIA */
          IF VCUSTOINDUSTRIA = 'C' THEN
            UPDATE PCMOV
               SET CUSTOCONT = REG2.VLCUSTO
             WHERE ROWID = REG2.ROWID_PCMOV AND TIPOMERC = 'PA';
          ELSIF VCUSTOINDUSTRIA = 'F' THEN
            UPDATE PCMOV
               SET CUSTOFIN = REG2.VLCUSTO
             WHERE ROWID = REG2.ROWID_PCMOV AND TIPOMERC = 'PA';
          ELSIF VCUSTOINDUSTRIA = 'I' THEN
            UPDATE PCMOV
               SET CUSTOREP = REG2.VLCUSTO
             WHERE ROWID = REG2.ROWID_PCMOV AND TIPOMERC = 'PA';
          ELSIF VCUSTOINDUSTRIA = 'R' THEN
            UPDATE PCMOV
               SET CUSTOREAL = REG2.VLCUSTO
             WHERE ROWID = REG2.ROWID_PCMOV AND TIPOMERC = 'PA';
          ELSIF VCUSTOINDUSTRIA = 'U' THEN
            UPDATE PCMOV
               SET CUSTOULTENT = REG2.VLCUSTO
             WHERE ROWID = REG2.ROWID_PCMOV AND TIPOMERC = 'PA';
          END IF;
          UPDATE PCMOV
               SET PUNIT = REG2.VLCUSTO, PUNITCONT = REG2.VLCUSTO
             WHERE ROWID = REG2.ROWID_PCMOV AND CODOPER = 'EP' AND TIPOMERC = 'PA';

        COMMIT;
        END LOOP;

        /* RECALCULAR O HISTORICO DAS MOVIMENTACOES */
        FOR REG3 IN (SELECT DATA, MAX(ORDEM) ORDEM
                       FROM PCCONTROLEPERMANENTE
                      WHERE CODPROD = REG.CODPROD
                        AND CODFILIAL = P_CODFILIAL
                        AND DATA BETWEEN DTINICIAL AND DTFINAL
                      GROUP BY DATA
                      ORDER BY DATA) LOOP
          SELECT VLCUSTO
            INTO ULTIMOMOVDIA
            FROM PCCONTROLEPERMANENTE
           WHERE DATA = REG3.DATA
             AND CODFILIAL = P_CODFILIAL
             AND CODPROD = REG.CODPROD
             AND ORDEM = REG3.ORDEM;

          /* ATUALIZAR OS HISTÓRICOS DE ESTOQUE COM O NOVO CUSTO DE ACORDO COM O CUSTO DA INDÚSTRIA */
          IF VCUSTOINDUSTRIA = 'C' THEN
            UPDATE PCHISTEST
               SET CUSTOCONT = ULTIMOMOVDIA
             WHERE CODPROD = REG.CODPROD
               AND DATA >= REG3.DATA
               AND CODFILIAL = P_CODFILIAL
               AND DATA <= DTFINAL;
          ELSIF VCUSTOINDUSTRIA = 'F' THEN
            UPDATE PCHISTEST
               SET CUSTOFIN = ULTIMOMOVDIA
             WHERE CODPROD = REG.CODPROD
               AND DATA >= REG3.DATA
               AND CODFILIAL = P_CODFILIAL
               AND DATA <= DTFINAL;
          ELSIF VCUSTOINDUSTRIA = 'I' THEN
            UPDATE PCHISTEST
               SET CUSTOREP = ULTIMOMOVDIA
             WHERE CODPROD = REG.CODPROD
               AND DATA >= REG3.DATA
               AND CODFILIAL = P_CODFILIAL
               AND DATA <= DTFINAL;
          ELSIF VCUSTOINDUSTRIA = 'R' THEN
            UPDATE PCHISTEST
               SET CUSTOREAL = ULTIMOMOVDIA
             WHERE CODPROD = REG.CODPROD
               AND DATA >= REG3.DATA
               AND CODFILIAL = P_CODFILIAL
               AND DATA <= DTFINAL;
          ELSIF VCUSTOINDUSTRIA = 'U' THEN
            UPDATE PCHISTEST
               SET CUSTOULTENT = ULTIMOMOVDIA
             WHERE CODPROD = REG.CODPROD
               AND DATA >= REG3.DATA
               AND CODFILIAL = P_CODFILIAL
               AND DATA <= DTFINAL;
          END IF;
        END LOOP;
      END IF;
      COMMIT;
    END LOOP;

    RETURN VMSGERRO;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        IF VMSGERRO IS NULL THEN
          RETURN 'ERRO AO RECALCULAR CUSTOS. DETALHES DO ERRO: ' || SQLERRM;
        ELSE
          RETURN VMSGERRO || ' ERRO AO RECALCULAR CUSTOS. DETALHES DO ERRO: ' || SQLERRM;
        END IF;
      END;
  END;
  /* FIM METODO RECALCULARCUSTOS */

  FUNCTION ESTOQUEDIA(P_CODPROD INTEGER, P_CODFILIAL VARCHAR2, P_DATA DATE)
    RETURN PCHISTEST%ROWTYPE IS
    HIST  PCHISTEST%ROWTYPE;
    VDATA DATE;
  BEGIN
    SELECT MAX(DATA)
      INTO VDATA
      FROM PCHISTEST
     WHERE CODPROD = P_CODPROD
       AND CODFILIAL = P_CODFILIAL
       AND DATA < P_DATA;

    SELECT *
      INTO HIST
      FROM PCHISTEST
     WHERE CODPROD = P_CODPROD
       AND CODFILIAL = P_CODFILIAL
       AND DATA = VDATA;

    RETURN HIST;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN HIST;
  END;

  FUNCTION OBTERNOVOCUSTO(PCODPROD   INTEGER,
                          PCODFILIAL VARCHAR2,
                          DTINICIAL  DATE) RETURN NUMBER IS
    VCUSTO NUMBER(16, 6);
  BEGIN

    SELECT VLCUSTOULT
      INTO VCUSTO
      FROM PCCUSTOPRODUCAOMENSAL P
     WHERE CODPROD = PCODPROD
       AND CODFILIAL = PCODFILIAL
       AND TO_CHAR(DATA,'MM/YYYY') = TO_CHAR(DTINICIAL, 'MM/YYYY')
     GROUP BY VLCUSTOULT;

    RETURN VCUSTO;
  END;

  FUNCTION OBTERCUSTO(PRECO         NUMBER,
                      DESCONTO      NUMBER,
                      FRETE         NUMBER,
                      IPI           NUMBER,
                      OUTRASDESP    NUMBER,
                      ST            NUMBER,
                      SEGURO        NUMBER,
                      CREDITOICMS   NUMBER,
                      CREDITOCOFINS NUMBER,
                      CREDITOPIS    NUMBER,
                      REGIMEFISCAL  VARCHAR2) RETURN NUMBER IS
    VCREDITOPIS    NUMBER DEFAULT CREDITOPIS;
    VCREDITOCOFINS NUMBER DEFAULT CREDITOCOFINS;
    VCREDITOICMS   NUMBER DEFAULT CREDITOICMS;
    VCUSTO         NUMBER(16, 6);
  BEGIN

    IF (REGIMEFISCAL = 'SP') THEN
      VCREDITOICMS   := 0;
      VCREDITOPIS    := 0;
      VCREDITOCOFINS := 0;
    END IF;

    IF (REGIMEFISCAL = 'LP') THEN
      VCREDITOPIS    := 0;
      VCREDITOCOFINS := 0;
    END IF;

    VCUSTO := NVL(PRECO, 0) - NVL(DESCONTO, 0) + NVL(SEGURO, 0) +
              NVL(OUTRASDESP, 0) + NVL(FRETE, 0) + NVL(ST, 0) + NVL(IPI, 0) -
              NVL(VCREDITOICMS, 0) - NVL(VCREDITOPIS, 0) -
              NVL(VCREDITOCOFINS, 0);

    RETURN VCUSTO;
  END;

  FUNCTION CUSTOMEDIOCONTABIL(PRECO            NUMBER,
                              DESCONTO         NUMBER,
                              FRETE            NUMBER,
                              IPI              NUMBER,
                              OUTRASDESP       NUMBER,
                              ST               NUMBER,
                              SEGURO           NUMBER,
                              CREDITOICMS      NUMBER,
                              CREDITOCOFINS    NUMBER,
                              CREDITOPIS       NUMBER,
                              QTENTRADA        NUMBER,
                              QTESTOQUE        NUMBER,
                              CUSTOCONTESTOQUE NUMBER,
                              REGIMEFISCAL     VARCHAR2) RETURN NUMBER IS
    VCUSTOCONTABIL      NUMBER(16, 6);
    VQTESTOQUE          NUMBER(16, 6);
    VCUSTOMEDIOCONTABIL NUMBER(16, 6);
  BEGIN
    VQTESTOQUE     := GREATEST(NVL(QTESTOQUE, 0));
    VCUSTOCONTABIL := OBTERCUSTO(PRECO,
                                 DESCONTO,
                                 IPI,
                                 ST,
                                 FRETE,
                                 OUTRASDESP,
                                 SEGURO,
                                 CREDITOICMS,
                                 CREDITOCOFINS,
                                 CREDITOPIS,
                                 REGIMEFISCAL);

    IF NVL(QTENTRADA, 0) + VQTESTOQUE = 0 THEN
      RETURN VCUSTOCONTABIL;
    END IF;

    VCUSTOMEDIOCONTABIL := ((VQTESTOQUE * NVL(CUSTOCONTESTOQUE, 0)) +
                           (NVL(QTENTRADA, 0) * VCUSTOCONTABIL)) /
                           (NVL(QTENTRADA, 0) + VQTESTOQUE);

    RETURN VCUSTOMEDIOCONTABIL;
  END;

  FUNCTION ATUALIZARCUSTOINICIALOPMES(P_CODFILIAL VARCHAR2,
                                      PCODPROD    INTEGER,
                                      DTINICIAL   DATE,
                                      DTFINAL     DATE) RETURN VARCHAR2 IS
    V_NOVOCUSTO NUMBER(16, 6);
  BEGIN
    V_NOVOCUSTO := OBTERNOVOCUSTO(PCODPROD, P_CODFILIAL, DTINICIAL);

    IF V_NOVOCUSTO > 0 THEN
      UPDATE PCMOV
         SET PUNITCONT = CASE WHEN PCMOV.CODOPER = 'S' THEN PUNITCONT ELSE V_NOVOCUSTO END
           , CUSTOULTENT = V_NOVOCUSTO
       WHERE PCMOV.CODPROD = PCODPROD
         AND ((PCMOV.STATUS = 'A')
           OR (PCMOV.STATUS = 'AB'))
         AND PCMOV.DTMOV BETWEEN DTINICIAL AND DTFINAL
         AND PCMOV.CODOPER in ('EP','S')
         AND PCMOV.TIPOMERC = 'PA'
         AND PCMOV.CODFILIAL = P_CODFILIAL;
    END IF;
    COMMIT;
    RETURN NULL;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        RETURN 'ERRO AO ATUALIZAR CUSTO INICIAL OP MES. DETALHES DO ERRO: ' || SQLERRM;
      END;
  END;

  FUNCTION PROCESSAR(P_CODFILIAL VARCHAR2,
                     DTINICIAL   DATE,
                     DTFINAL     DATE,
                     PCODPROD    INTEGER) RETURN VARCHAR2 IS
    CPP PCCONTROLEPERMANENTE%ROWTYPE;
    NFS PCNFSAID%ROWTYPE;
    NFE PCNFENT%ROWTYPE;
    HIS PCHISTEST%ROWTYPE;

    I              INTEGER;
    V_REGIMEFISCAL VARCHAR2(2);
    VCUSTOINDUSTRIA VARCHAR2(1);
    V_CUSTOANT     NUMBER(16, 6);
    V_QTDEANTERIOR NUMBER(16, 6);
  BEGIN
    DELETE FROM PCCONTROLEPERMANENTE
     WHERE CODFILIAL = P_CODFILIAL
       AND DATA BETWEEN DTINICIAL AND DTFINAL
       AND CODPROD = PCODPROD;

    V_REGIMEFISCAL := 'LR';
    HIS            := ESTOQUEDIA(PCODPROD, P_CODFILIAL, DTINICIAL);
    CPP.QTESTOQUE  := HIS.QTEST;    
    SELECT CUSTOINDUSTRIA INTO VCUSTOINDUSTRIA FROM PCCONSUM;
    IF VCUSTOINDUSTRIA='R' THEN
    CPP.VLCUSTO    := HIS.CUSTOREAL;    
    ELSIF  VCUSTOINDUSTRIA='F' THEN
    CPP.VLCUSTO    := HIS.CUSTOFIN;
    ELSIF  VCUSTOINDUSTRIA='C' THEN
    CPP.VLCUSTO    := HIS.CUSTOCONT;
    ELSIF  VCUSTOINDUSTRIA='U' THEN
    CPP.VLCUSTO    := HIS.CUSTOULTENT;  
    ELSIF  VCUSTOINDUSTRIA='I' THEN
    CPP.VLCUSTO    := HIS.CUSTOREP;    
    END IF;
    

    CPP.ORDEM := 0;

    FOR REG IN (SELECT PCMOV.CODPROD,
                       PCMOV.NUMNOTA,
                       DECODE(NVL(PCMOV.QTCONT, 0), 0, PCMOV.QT, PCMOV.QTCONT) QTCONT,
                       PCMOV.PUNITCONT,
                       PCMOV.CUSTOCONT,
                       PCMOV.CODOPER,
                       PCMOV.DTMOV,
                       PCMOV.CODFISCAL,
                       PCMOV.NUMTRANSVENDA,
                       PCMOV.NUMTRANSENT,
                       PCMOV.VLIPI,
                       PCMOV.VLDESCONTO,
                       PCMOV.VLFRETE,
                       PCMOV.VLOUTROS,
                       PCMOV.ST,
                       PCMOV.VLSEGURO,
                       PCMOV.VLCREDICMS,
                       PCMOV.VLCREDCOFINS,
                       PCMOV.VLCREDPIS,
                       PCMOV.NUMOP,
                       PCMOV.DTCANCEL,
                       PCMOV.ROWID
                  FROM PCMOV
                 WHERE PCMOV.CODFILIAL = P_CODFILIAL
                   AND ((PCMOV.STATUS = 'A')
                     OR (PCMOV.STATUS = 'AB'))
                   AND PCMOV.CODPROD = PCODPROD
                   AND PCMOV.DTMOV BETWEEN DTINICIAL AND DTFINAL
                   AND PCMOV.CODOPER NOT IN ('EI', 'SI')
                 ORDER BY PCMOV.DTMOV, PCMOV.SEQMOV)
    LOOP
      CPP.ORDEM       := CPP.ORDEM + 1;
      CPP.CODFILIAL   := P_CODFILIAL;
      CPP.CODPROD     := REG.CODPROD;
      CPP.NUMNOTA     := REG.NUMNOTA;
      CPP.DATA        := REG.DTMOV;
      CPP.CODFISCAL   := REG.CODFISCAL;
      CPP.VLIPI       := REG.VLIPI;
      CPP.QTENTRADA   := 0;
      CPP.QTSAIDA     := 0;
      CPP.VLENTRADA   := 0;
      CPP.VLSAIDA     := 0;
      CPP.SERIE       := NULL;
      CPP.CODCONTABIL := NULL;
      CPP.CODFISCAL   := NULL;
      CPP.OBS         := NULL;
      CPP.VLCUSTOANT  := CPP.VLCUSTO;

      BEGIN
        IF SUBSTR(REG.CODOPER, 1, 1) = 'S' THEN
          SELECT COUNT(PCNFSAID.ROWID)
            INTO I
            FROM PCNFSAID
           WHERE NUMTRANSVENDA = REG.NUMTRANSVENDA;
          IF I > 0 THEN
            SELECT PCNFSAID.*
              INTO NFS
              FROM PCNFSAID
             WHERE NUMTRANSVENDA = REG.NUMTRANSVENDA;

            CPP.ESPECIE     := NFS.ESPECIE;
            CPP.SERIE       := NFS.SERIE;
            CPP.CODCONTABIL := NFS.CODCONT;
            CPP.OBS         := NFS.OBS;
          END IF;

          IF REG.QTCONT > 0 THEN
            CPP.QTSAIDA   := REG.QTCONT;
            CPP.VLSAIDA   := CPP.VLCUSTO * CPP.QTSAIDA;
            CPP.QTESTOQUE := CPP.QTESTOQUE - REG.QTCONT;
            CPP.OBS       := '';
          ELSE
            CPP.QTENTRADA := ABS(REG.QTCONT);
            CPP.VLENTRADA := CPP.VLCUSTO;
            CPP.QTESTOQUE := CPP.QTESTOQUE + CPP.QTENTRADA;
          END IF;
        ELSE
          SELECT COUNT(PCNFENT.ROWID)
            INTO I
            FROM PCNFENT
           WHERE NUMTRANSENT = REG.NUMTRANSENT;

          IF REG.CODOPER = 'EP' THEN
            CPP.NUMNOTA := REG.NUMOP;
            CPP.ESPECIE := 'OP';
            CPP.OBS     := 'ENTRADA DE PRODUÇÃO';
          END IF;

          IF I > 0 THEN
            SELECT PCNFENT.*
              INTO NFE
              FROM PCNFENT
             WHERE NUMTRANSENT = REG.NUMTRANSENT;

            CPP.ESPECIE     := NFE.ESPECIE;
            CPP.SERIE       := NFE.SERIE;
            CPP.CODCONTABIL := NFE.CODCONT;
            CPP.OBS         := NFE.OBS;
          END IF;

          CPP.QTENTRADA := REG.QTCONT;

          IF REG.CODOPER = 'ED' THEN
            CPP.VLENTRADA := CPP.VLCUSTO;
            CPP.OBS       := 'DEVOLUCAO DE VENDA';
          ELSE
            CPP.VLENTRADA  := OBTERCUSTO(REG.PUNITCONT,
                                         REG.VLDESCONTO,
                                         REG.VLFRETE,
                                         REG.VLIPI,
                                         REG.VLOUTROS,
                                         REG.ST,
                                         REG.VLSEGURO,
                                         REG.VLCREDICMS,
                                         REG.VLCREDCOFINS,
                                         REG.VLCREDPIS,
                                         V_REGIMEFISCAL);
            V_CUSTOANT     := CPP.VLCUSTOANT;
            CPP.VLCUSTO    := CUSTOMEDIOCONTABIL(REG.PUNITCONT,
                                                 REG.VLDESCONTO,
                                                 REG.VLFRETE,
                                                 REG.VLIPI,
                                                 REG.VLOUTROS,
                                                 REG.ST,
                                                 REG.VLSEGURO,
                                                 REG.VLCREDICMS,
                                                 REG.VLCREDCOFINS,
                                                 REG.VLCREDPIS,
                                                 REG.QTCONT,
                                                 CPP.QTESTOQUE,
                                                 CPP.VLCUSTO,
                                                 V_REGIMEFISCAL);
            V_QTDEANTERIOR := REG.QTCONT;
          END IF;

          CPP.QTESTOQUE := CPP.QTESTOQUE + REG.QTCONT;
        END IF;

        CPP.VLESTOQUE := CPP.QTESTOQUE * CPP.VLCUSTO;

      EXCEPTION
        WHEN OTHERS THEN
          CPP.OBS := 'ERRO: ' || SQLERRM;
      END;

      CPP.ROWID_PCMOV := REG.ROWID;

      INSERT INTO PCCONTROLEPERMANENTE VALUES CPP;
    END LOOP;
    
    IF (NVL(CPP.CODPROD, 0) = 0) AND (NVL(CPP.VLCUSTO, 0) > 0) THEN
    
      INSERT INTO PCCONTROLEPERMANENTE
        (CODFILIAL, CODPROD, VLCUSTO, DATA, ORDEM)
      VALUES
        (HIS.CODFILIAL, HIS.CODPROD, CPP.VLCUSTO, DTINICIAL, 0);
    
    END IF;

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        RETURN 'ERRO AO INSERIR DADOS NA PCCONTROLEPERMANENTE. DETALHES DO ERRO: ' || SQLERRM;
      END;
  END;
END; /* FIM PACKAGE BODY */
