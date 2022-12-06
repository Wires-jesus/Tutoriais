CREATE OR REPLACE PACKAGE BODY PC_PKG_CONTROLASALDORCAFORNEC IS

PROCEDURE PRC_MOVIMENTASALDORCAFORNEC(P_CODUSUR IN
                                                         NUMBER,
                                                         P_NUMPED IN NUMBER,
                                                         P_CODROTINA IN
                                                         PCROTINA.CODIGO%TYPE,
                                                         P_CODFUNC IN
                                                         PCEMPR.MATRICULA%TYPE,
                                                         P_CODFILIAL IN
                                                         VARCHAR2,
                                                         P_MENSAGEM OUT
                                                         VARCHAR2) IS
  /******************************************************************************************************
   29/01/2013 Marcos Garcia e Thiago Melo - Criação
   ******************************************************************************************************/
  VSMENSAGEM VARCHAR2(3000);
  VICONT      NUMBER;
  VNDIF       NUMBER;
  VNLANC      NUMBER;
  VNRESTO     NUMBER;
  VNDISP      NUMBER;
  VNCODPROD   NUMBER;
  VNNUMSEQ    NUMBER;
  VSPOSICAO   VARCHAR2(1);
  VNNUMPEDBNF NUMBER;
  vnCont   NUMBER;
  vs_movest             varchar2(4000);
  msgest               varchar2(4000);
  VBMOVIMENTOVALIDO Boolean;
BEGIN
  VSMENSAGEM := 'OK';
  VBMOVIMENTOVALIDO := True;
  BEGIN
    FOR C_BLOQUEIASALDO IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                   PCSALDORCAFORNEC.CODFORNEC,
                                   PCSALDORCAFORNEC.VLLIMCRED
                              FROM PCSALDORCAFORNEC
                             WHERE PCSALDORCAFORNEC.CODUSUR = P_CODUSUR
                               AND TRUNC(SYSDATE) BETWEEN
                                   PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                   PCSALDORCAFORNEC.DTFIMVIGENCIA
                               AND ((PCSALDORCAFORNEC.CODFORNEC IN
                                   (SELECT PCPRODUT.CODFORNEC
                                        FROM PCPEDI, PCPRODUT
                                       WHERE PCPEDI.NUMPED = P_NUMPED
                                         AND PCPEDI.CODPROD =
                                             PCPRODUT.CODPROD)) OR
                                   (PCSALDORCAFORNEC.CODFORNEC = 9999))
                               FOR UPDATE) LOOP
      EXIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
     VBMOVIMENTOVALIDO:= False;
      VSMENSAGEM := 'ERRO AO LOCAR VERBA RCA-FORNECEDOR: ' || SQLCODE ||
                    ' - ' || SQLERRM;
      RAISE;
  END;

  IF VSMENSAGEM = 'OK' THEN
    BEGIN
      BEGIN
        -- LACO DOS CREDITOS
        FOR C_ITENS IN (SELECT PCPRODUT.CODFORNEC,
                               PCPEDI.CODPROD,
                               PCPEDI.PVENDA,
                               PCPEDI.PBASERCA,
                               PCPEDI.PTABELA,
                               PCPEDI.QT,
                               PCPEDI.NUMSEQ,
                               --HIS.03314.2016: Movimentar o código do fornecedor do produto caso o parametro CREDITARSALDOESTVERBA seja igual a sim
                               DECODE(NVL(PCFORNEC.CREDITARSALDOESTVERBA,
                                          'N'),
                                      'S',
                                      PCFORNEC.CODFORNEC,
                                      9999) CODFORNECMOVIMENTO
                          FROM PCPEDI, PCPRODUT, PCFORNEC
                         WHERE PCPEDI.NUMPED = P_NUMPED
                           AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC
                           AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                           AND NVL(PCPEDI.PVENDA, 0) -
                               NVL(PCPEDI.PBASERCA, NVL(PCPEDI.PTABELA, 0)) > 0
                         ORDER BY PCPRODUT.CODFORNEC, PCPEDI.CODPROD) LOOP
          BEGIN
            VNDIF   := (NVL(C_ITENS.PVENDA, 0) -
                       NVL(C_ITENS.PBASERCA, C_ITENS.PTABELA)) *
                       NVL(C_ITENS.QT, 0);
            VNRESTO := VNDIF;

            IF VNRESTO <> 0 THEN
              BEGIN
                SELECT COUNT(*)
                  INTO vnCont
                  FROM PCSALDORCAFORNEC
                 WHERE PCSALDORCAFORNEC.CODFORNEC in
                       (C_ITENS.CODFORNECMOVIMENTO); --HIS.03314.2016

              EXCEPTION
                WHEN OTHERS THEN
                  vnCont := 0;
              END;

              IF vnCont = 0 THEN
                VBMOVIMENTOVALIDO := False;
                VSMENSAGEM        := 'NÃO EXISTE CADASTRO DE SALDO PARA O FORNECEDOR 9999 PARA LANÇAR CRÉDITO OU NÃO ESTÁ DENTRO DO PERÍODO DE VIGÊNCIA.';
              END IF;
            END IF;
            IF ((vnCont <> 0) or (VNRESTO = 0)) THEN
              FOR C_VERBA9999 IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                         PCSALDORCAFORNEC.CODFORNEC,
                                         NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                         PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                         SUM(NVL(MOVIMENTACOES.VALORLANC,
                                                 0)) VALORLANC
                                    FROM PCSALDORCAFORNEC,
                                         (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                                 PCMOVSALDORCAFORNEC.VALORLANC
                                            FROM PCMOVSALDORCAFORNEC
                                           WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                                   WHERE PCSALDORCAFORNEC.CODUSUR =
                                         P_CODUSUR
                                     AND TRUNC(SYSDATE) BETWEEN
                                         PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                         PCSALDORCAFORNEC.DTFIMVIGENCIA
                                     AND PCSALDORCAFORNEC.CODFORNEC =
                                         C_ITENS.CODFORNECMOVIMENTO --HIS.03314.2016
                                     AND MOVIMENTACOES.CODIGO(+) =
                                         PCSALDORCAFORNEC.CODIGO
                                   GROUP BY PCSALDORCAFORNEC.CODIGO,
                                            PCSALDORCAFORNEC.CODFORNEC,
                                            NVL(PCSALDORCAFORNEC.VLLIMCRED,
                                                0),
                                            PCSALDORCAFORNEC.DTFIMVIGENCIA
                                   ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
                VNLANC  := VNDIF;
                VNRESTO := 0;
                INSERT INTO PCMOVSALDORCAFORNEC
                  (CODIGO,
                   CODUSUR,
                   CODFORNEC,
                   DTLANC,
                   CODFUNCLANC,
                   ROTINALANC,
                   NUMPED,
                   CODPROD,
                   VALORLANC,
                   NUMSEQ)
                VALUES
                  (C_VERBA9999.CODIGO,
                   P_CODUSUR,
                   C_VERBA9999.CODFORNEC,
                   SYSDATE,
                   P_CODFUNC,
                   P_CODROTINA,
                   P_NUMPED,
                   C_ITENS.CODPROD,
                   VNLANC,
                   C_ITENS.NUMSEQ);
                -- NAO HA MAIS O QUE LANCAR
                IF VNRESTO = 0 THEN
                  EXIT;
                END IF;
              END LOOP;

              IF VNRESTO <> 0 THEN
                VBMOVIMENTOVALIDO := False;
                VSMENSAGEM        := 'RCA SEM CRÉDITO PARA LIBERAR O ITEM COM CREDITO OU O SALDO DO FORNECEDOR ' ||
                                     C_ITENS.CODFORNECMOVIMENTO ||
                                     ' DO RCA NÃO ESTÁ DENTRO DO PERÍODO DE VIGÊNCIA.';
                VNCODPROD         := C_ITENS.CODPROD;
                VNNUMSEQ          := C_ITENS.NUMSEQ;
              END IF;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              VBMOVIMENTOVALIDO := False;
              VSMENSAGEM        := 'ERRO AO SELECIONAR VERBAS 9999 PARA O ITEM CREDITO.' ||
                                   SQLCODE || '-' || SQLERRM;
              VNCODPROD         := C_ITENS.CODPROD;
              VNNUMSEQ          := C_ITENS.NUMSEQ;
          END;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          VSMENSAGEM := 'ERRO AO SELECIONAR ITENS DO PEDIDO CREDITO.' ||
                        SQLCODE || '-' || SQLERRM;
      END;

      -- LACO DOS DEBITOS
      BEGIN
        FOR C_ITENS IN (SELECT PCPRODUT.CODFORNEC,
                               PCPEDI.CODPROD,
                               PCPEDI.PVENDA,
                               PCPEDI.PBASERCA,
                               PCPEDI.PTABELA,
                               PCPEDI.QT,
                               PCPEDI.NUMSEQ
                          FROM PCPEDI, PCPRODUT
                         WHERE PCPEDI.NUMPED = P_NUMPED
                           AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                           AND NVL(PCPEDI.PVENDA, 0) -
                               NVL(PCPEDI.PBASERCA, NVL(PCPEDI.PTABELA, 0)) < 0
                         ORDER BY PCPRODUT.CODFORNEC, PCPEDI.CODPROD) LOOP
          BEGIN
            VNDIF   := (NVL(C_ITENS.PVENDA, 0) -
                       NVL(C_ITENS.PBASERCA, C_ITENS.PTABELA)) *
                       NVL(C_ITENS.QT, 0);
            VNRESTO := VNDIF;
            FOR C_VERBAFORNECEDOR IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                             PCSALDORCAFORNEC.CODFORNEC,
                                             NVL(PCSALDORCAFORNEC.VLLIMCRED,
                                                 0) VLLIMCRED,
                                             PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                             SUM(NVL(MOVIMENTACOES.VALORLANC,
                                                     0)) VALORLANC
                                        FROM PCSALDORCAFORNEC,
                                             (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                                     PCMOVSALDORCAFORNEC.VALORLANC
                                                FROM PCMOVSALDORCAFORNEC
                                               WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                                       WHERE PCSALDORCAFORNEC.CODUSUR =
                                             P_CODUSUR
                                         AND TRUNC(SYSDATE) BETWEEN
                                             PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                             PCSALDORCAFORNEC.DTFIMVIGENCIA
                                         AND PCSALDORCAFORNEC.CODFORNEC =
                                             C_ITENS.CODFORNEC
                                         AND MOVIMENTACOES.CODIGO(+) =
                                             PCSALDORCAFORNEC.CODIGO
                                       GROUP BY PCSALDORCAFORNEC.CODIGO,
                                                PCSALDORCAFORNEC.CODFORNEC,
                                                PCSALDORCAFORNEC.VLLIMCRED,
                                                PCSALDORCAFORNEC.DTFIMVIGENCIA
                                      HAVING NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) + SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) > 0
                                       ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
              VNDISP := NVL(C_VERBAFORNECEDOR.VLLIMCRED, 0) +
                        NVL(C_VERBAFORNECEDOR.VALORLANC, 0);
              IF VNDISP < 0 THEN
                VNDISP := 0;
              END IF;
              IF VNDISP >= ABS(VNRESTO) THEN
                VNLANC := VNRESTO;
              ELSE
                VNLANC := (-1) * VNDISP; --AJUSTE SABRINA (O DISPONIVEL EH SEMPRE POSITIVO, MAS O LANCAMENTO EH DEBITO)
              END IF;
              VNRESTO := VNRESTO - VNLANC;
              INSERT INTO PCMOVSALDORCAFORNEC
                (CODIGO,
                 CODUSUR,
                 CODFORNEC,
                 DTLANC,
                 CODFUNCLANC,
                 ROTINALANC,
                 NUMPED,
                 CODPROD,
                 VALORLANC,
                 NUMSEQ)
              VALUES
                (C_VERBAFORNECEDOR.CODIGO,
                 P_CODUSUR,
                 C_VERBAFORNECEDOR.CODFORNEC,
                 SYSDATE,
                 P_CODFUNC,
                 P_CODROTINA,
                 P_NUMPED,
                 C_ITENS.CODPROD,
                 VNLANC,
                 C_ITENS.NUMSEQ);
              -- NAO HA MAIS O QUE LANCAR
              IF VNRESTO = 0 THEN
                EXIT;
              END IF;
            END LOOP;

            IF VNRESTO <> 0 THEN
              FOR C_VERBA9999 IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                         PCSALDORCAFORNEC.CODFORNEC,
                                         NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                         PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                         SUM(NVL(MOVIMENTACOES.VALORLANC,
                                                 0)) VALORLANC
                                    FROM PCSALDORCAFORNEC,
                                         (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                                 PCMOVSALDORCAFORNEC.VALORLANC
                                            FROM PCMOVSALDORCAFORNEC
                                           WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                                   WHERE PCSALDORCAFORNEC.CODUSUR =
                                         P_CODUSUR
                                     AND TRUNC(SYSDATE) BETWEEN
                                         PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                         PCSALDORCAFORNEC.DTFIMVIGENCIA
                                     AND PCSALDORCAFORNEC.CODFORNEC = 9999
                                     AND MOVIMENTACOES.CODIGO(+) =
                                         PCSALDORCAFORNEC.CODIGO
                                   GROUP BY PCSALDORCAFORNEC.CODIGO,
                                            PCSALDORCAFORNEC.CODFORNEC,
                                            PCSALDORCAFORNEC.VLLIMCRED,
                                            PCSALDORCAFORNEC.DTFIMVIGENCIA
                                  HAVING NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) + SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) > 0
                                   ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
                VNDISP := NVL(C_VERBA9999.VLLIMCRED, 0) +
                          NVL(C_VERBA9999.VALORLANC, 0);
                IF VNDISP < 0 THEN
                  VNDISP := 0;
                END IF;
                IF VNDISP >= ABS(VNRESTO) THEN
                  VNLANC := VNRESTO;
                ELSE
                  VNLANC := (-1) * VNDISP; --AJUSTE SABRINA (O DISPONIVEL EH SEMPRE POSITIVO, MAS O LANCAMENTO EH DEBITO)
                END IF;
                VNRESTO := VNRESTO - VNLANC;
                INSERT INTO PCMOVSALDORCAFORNEC
                  (CODIGO,
                   CODUSUR,
                   CODFORNEC,
                   DTLANC,
                   CODFUNCLANC,
                   ROTINALANC,
                   NUMPED,
                   CODPROD,
                   VALORLANC,
                   NUMSEQ)
                VALUES
                  (C_VERBA9999.CODIGO,
                   P_CODUSUR,
                   C_VERBA9999.CODFORNEC,
                   SYSDATE,
                   P_CODFUNC,
                   P_CODROTINA,
                   P_NUMPED,
                   C_ITENS.CODPROD,
                   VNLANC,
                   C_ITENS.NUMSEQ);
                -- NAO HA MAIS O QUE LANCAR
                IF VNRESTO = 0 THEN
                  EXIT;
                END IF;
              END LOOP;
            END IF;

            IF VNRESTO <> 0 THEN
              VBMOVIMENTOVALIDO := False;
              VSMENSAGEM        := 'RCA SEM CRÉDITO PARA LIBERAR O ITEM COM DESCONTO.';
              VNCODPROD         := C_ITENS.CODPROD;
              VNNUMSEQ          := C_ITENS.NUMSEQ;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              VBMOVIMENTOVALIDO := False;
              VSMENSAGEM        := 'ERRO AO SELECIONAR VERBAS PARA O ITEM DEBITO .' ||
                                   SQLCODE || '-' || SQLERRM;
              VNCODPROD         := C_ITENS.CODPROD;
              VNNUMSEQ          := C_ITENS.NUMSEQ;
          END;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          VSMENSAGEM := 'ERRO AO SELECIONAR ITENS DO PEDIDO DEBITO.' ||
                        SQLCODE || '-' || SQLERRM;
      END;

      IF NOT VBMOVIMENTOVALIDO THEN
        --ROLLBACK;
        BEGIN
          BEGIN
            SELECT POSICAO, NUMPEDBNF
              INTO VSPOSICAO, VNNUMPEDBNF
              FROM PCPEDC
             WHERE NUMPED = P_NUMPED;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VSPOSICAO   := NULL;
              VNNUMPEDBNF := NULL;
          END;

          IF VSPOSICAO IN ('L', 'M') THEN

            UPDATE PCPEDC SET POSICAO = 'B' WHERE NUMPED = P_NUMPED;
            UPDATE PCPEDI SET POSICAO = 'B' WHERE NUMPED = P_NUMPED;

            FOR C_ESTOQUE IN (SELECT PCPEDI.CODPROD,
                                     PCPEDI.QT,
                                     PCPEDI.NUMPED,
                                     PCPEDI.NUMSEQ
                                FROM PCPEDI, PCEST
                               WHERE PCPEDI.NUMPED = P_NUMPED
                                 AND PCPEDI.CODPROD = PCEST.CODPROD
                                 AND PCEST.CODFILIAL = P_CODFILIAL
                                 FOR UPDATE) LOOP

              UPDATE PCPEDI
                 SET NOMECONCORRENTE = SUBSTR(VSMENSAGEM, 1, 60)
               WHERE NUMPED = P_NUMPED
                 AND CODPROD = VNCODPROD
                 AND NUMSEQ = VNNUMSEQ;

            END LOOP;
          END IF;

          -- TAREFA 45495: TRATAR PEDIDO BONIFICADO
          IF NVL(VNNUMPEDBNF, 0) <> 0 THEN
            BEGIN
              SELECT POSICAO
                INTO VSPOSICAO
                FROM PCPEDC
               WHERE NUMPED = VNNUMPEDBNF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                VSPOSICAO := NULL;
            END;

            UPDATE PCPEDC SET POSICAO = 'B' WHERE NUMPED = VNNUMPEDBNF;
            UPDATE PCPEDI SET POSICAO = 'B' WHERE NUMPED = VNNUMPEDBNF;

          END IF;

          --2759.144897.2014
          --COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            --2759.144897.2014
            --ROLLBACK;
            VSMENSAGEM := 'ERRO AO GERAR MOVIMENTACAO DE ESTOQUE. ERRO: ' ||
                          SQLCODE || ' - ' || SQLERRM;
        END;
      END IF;
      P_MENSAGEM := VSMENSAGEM;
    EXCEPTION
      WHEN OTHERS THEN
        --2759.144897.2014
        --ROLLBACK;
        VSMENSAGEM := 'ERRO AO SELECIONAR ITENS DO PEDIDO DEBITO.' ||
                      SQLCODE || '-' || SQLERRM;
        P_MENSAGEM := VSMENSAGEM;
    END;
  END IF;

END PRC_MOVIMENTASALDORCAFORNEC;

/*#QUEBRA*/
PROCEDURE PRC_VALIDAITEMSALDORCAFORNEC(P_CODUSUR   IN NUMBER,
                                 P_NUMPED    IN NUMBER,
                                 P_CODFORNEC IN NUMBER,
                                 P_CODPROD   IN NUMBER,
                                 P_NUMSEQ    IN NUMBER,
                                 P_NUMSEQANT IN NUMBER,
                                 P_PVENDA    IN NUMBER,
                                 P_PBASERCA  IN NUMBER,
                                 P_QT        IN NUMBER,
                                 P_CODROTINA IN PCROTINA.CODIGO%TYPE,
                                 P_CODFUNC   IN PCEMPR.MATRICULA%TYPE,
                                 P_CODFILIAL IN VARCHAR2,
                                 P_MENSAGEM  OUT VARCHAR2) IS
/******************************************************************************************************
                                            HISTORICO
    DATA       RESPONSAVEL      ALTERACAO
    ---------- ---------------- -------------------------------------------------------------------------

  ******************************************************************************************************/
  VSMENSAGEM VARCHAR2(3000);
  VICONT     NUMBER;
  VNDIF      NUMBER;
  VNLANC     NUMBER;
  VNRESTO    NUMBER;
  VNDISP     NUMBER;
  VSCREDITARSALDOESTVERBA VARCHAR2(1);
BEGIN
  VSMENSAGEM := 'OK';
  BEGIN
    FOR C_BLOQUEIASALDO IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                   PCSALDORCAFORNEC.CODFORNEC,
                                   PCSALDORCAFORNEC.VLLIMCRED
                              FROM PCSALDORCAFORNEC
                             WHERE PCSALDORCAFORNEC.CODUSUR = P_CODUSUR
                               AND TRUNC(SYSDATE) BETWEEN
                                   PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                   PCSALDORCAFORNEC.DTFIMVIGENCIA
                               AND PCSALDORCAFORNEC.CODFORNEC IN
                                   (P_CODFORNEC, 9999)
                               FOR UPDATE) LOOP
      EXIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      VSMENSAGEM := 'ERRO AO LOCAR VERBA RCA-FORNECEDOR: ' || SQLCODE ||
                    ' - ' || SQLERRM;
      RAISE;
  END;

  IF VSMENSAGEM = 'OK' THEN
    -- ESTORNAR MOVIMENTACAO COM VALORES ANTERIORES
    INSERT INTO PCMOVSALDORCAFORNEC
      (CODIGO,
       CODUSUR,
       CODFORNEC,
       DTLANC,
       CODFUNCLANC,
       ROTINALANC,
       VALORLANC,
       DTCANCEL,
       CODFUNCCANCEL,
       ROTINACANCEL,
       NUMPED,
       CODPROD,
       NUMSEQ)
      SELECT CODIGO,
             CODUSUR,
             CODFORNEC,
             SYSDATE,
             P_CODFUNC,
             P_CODROTINA,
             ((-1) * VALORLANC),
             SYSDATE,
             P_CODFUNC,
             P_CODROTINA,
             NUMPED,
             CODPROD,
             NUMSEQ
        FROM PCMOVSALDORCAFORNEC
       WHERE NUMPED = P_NUMPED
         AND CODPROD = P_CODPROD
         AND NVL(NUMSEQ, 0) = P_NUMSEQANT;

    UPDATE PCMOVSALDORCAFORNEC
       SET DTCANCEL      = SYSDATE,
           CODFUNCCANCEL = P_CODFUNC,
           ROTINACANCEL  = P_CODROTINA
     WHERE NUMPED = P_NUMPED
       AND CODPROD = P_CODPROD
       AND NVL(NUMSEQ, 0) = P_NUMSEQANT
       AND DTCANCEL IS NULL;

    begin
      select CREDITARSALDOESTVERBA
        into VSCREDITARSALDOESTVERBA
        from pcfornec
       where codfornec = p_codfornec;
    exception
      when others then
        VSCREDITARSALDOESTVERBA := 'N';
    end;

    -- LANCAR MOVIMENTACAO BASEADA NOS VALORES ATUAIS
    VNDIF := (NVL(P_PVENDA, 0) - NVL(P_PBASERCA, 0)) * NVL(P_QT, 0);
    IF VNDIF > 0 THEN
      VNRESTO := VNDIF;
      FOR C_VERBA9999 IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                 PCSALDORCAFORNEC.CODFORNEC,
                                 NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                 PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                 SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) VALORLANC
                            FROM PCSALDORCAFORNEC,
                                 (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                         PCMOVSALDORCAFORNEC.VALORLANC
                                    FROM PCMOVSALDORCAFORNEC
                                   WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                           WHERE PCSALDORCAFORNEC.CODUSUR = P_CODUSUR
                             AND TRUNC(SYSDATE) BETWEEN
                                 PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                 PCSALDORCAFORNEC.DTFIMVIGENCIA
                             AND PCSALDORCAFORNEC.CODFORNEC =  decode(VSCREDITARSALDOESTVERBA, 'S', P_CODFORNEC, 9999)
                             AND MOVIMENTACOES.CODIGO(+) =
                                 PCSALDORCAFORNEC.CODIGO
                           GROUP BY PCSALDORCAFORNEC.CODIGO,
                                    PCSALDORCAFORNEC.CODFORNEC,
                                    NVL(PCSALDORCAFORNEC.VLLIMCRED, 0),
                                    PCSALDORCAFORNEC.DTFIMVIGENCIA
                           ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
        VNLANC  := VNDIF;
        VNRESTO := 0;
        INSERT INTO PCMOVSALDORCAFORNEC
          (CODIGO,
           CODUSUR,
           CODFORNEC,
           DTLANC,
           CODFUNCLANC,
           ROTINALANC,
           NUMPED,
           CODPROD,
           VALORLANC,
           NUMSEQ)
        VALUES
          (C_VERBA9999.CODIGO,
           P_CODUSUR,
           C_VERBA9999.CODFORNEC,
           SYSDATE,
           P_CODFUNC,
           P_CODROTINA,
           P_NUMPED,
           P_CODPROD,
           VNLANC,
           P_NUMSEQ);
        -- NAO HA MAIS O QUE LANCAR
        IF VNRESTO = 0 THEN
          EXIT;
        END IF;
      END LOOP;
      IF VNRESTO <> 0 THEN
        VSMENSAGEM := 'RCA SEM CRÉDITO PARA LIBERAR O ITEM COM CREDITO.';
      END IF;
    ELSE
      VNRESTO := VNDIF;
      FOR C_VERBAFORNECEDOR IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                       PCSALDORCAFORNEC.CODFORNEC,
                                       NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                       PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                       SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) VALORLANC
                                  FROM PCSALDORCAFORNEC,
                                       (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                               PCMOVSALDORCAFORNEC.VALORLANC
                                          FROM PCMOVSALDORCAFORNEC
                                         WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL
                                            AND NOT (PCMOVSALDORCAFORNEC.NUMPED =  P_NUMPED
                                            AND CODPROD = P_CODPROD)) MOVIMENTACOES
                                 WHERE PCSALDORCAFORNEC.CODUSUR = P_CODUSUR
                                   AND TRUNC(SYSDATE) BETWEEN
                                       PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                       PCSALDORCAFORNEC.DTFIMVIGENCIA
                                   AND PCSALDORCAFORNEC.CODFORNEC = P_CODFORNEC
                                   AND MOVIMENTACOES.CODIGO(+) =
                                       PCSALDORCAFORNEC.CODIGO
                                 GROUP BY PCSALDORCAFORNEC.CODIGO,
                                          PCSALDORCAFORNEC.CODFORNEC,
                                          PCSALDORCAFORNEC.VLLIMCRED,
                                          PCSALDORCAFORNEC.DTFIMVIGENCIA
                                HAVING NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) + SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) > 0
                                 ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
        VNDISP := NVL(C_VERBAFORNECEDOR.VLLIMCRED, 0) +
                  NVL(C_VERBAFORNECEDOR.VALORLANC, 0);
        IF VNDISP < 0 THEN
          VNDISP := 0;
        END IF;
        IF VNDISP >= ABS(VNRESTO) THEN
          VNLANC := VNRESTO;
        ELSE
          VNLANC := (-1) * VNDISP; --AJUSTE SABRINA (O DISPONIVEL EH SEMPRE POSITIVO, MAS O LANCAMENTO EH DEBITO)
        END IF;
        VNRESTO := VNRESTO - VNLANC;
        INSERT INTO PCMOVSALDORCAFORNEC
          (CODIGO,
           CODUSUR,
           CODFORNEC,
           DTLANC,
           CODFUNCLANC,
           ROTINALANC,
           NUMPED,
           CODPROD,
           VALORLANC,
           NUMSEQ)
        VALUES
          (C_VERBAFORNECEDOR.CODIGO,
           P_CODUSUR,
           C_VERBAFORNECEDOR.CODFORNEC,
           SYSDATE,
           P_CODFUNC,
           P_CODROTINA,
           P_NUMPED,
           P_CODPROD,
           VNLANC,
           P_NUMSEQ);
        -- NAO HA MAIS O QUE LANCAR
        IF VNRESTO = 0 THEN
          EXIT;
        END IF;
      END LOOP;

      IF VNRESTO <> 0 THEN
        FOR C_VERBA9999 IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                   PCSALDORCAFORNEC.CODFORNEC,
                                   NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                   PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                   SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) VALORLANC
                              FROM PCSALDORCAFORNEC,
                                   (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                           PCMOVSALDORCAFORNEC.VALORLANC
                                      FROM PCMOVSALDORCAFORNEC
                                     WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL
                                        AND NOT (PCMOVSALDORCAFORNEC.NUMPED =  P_NUMPED
                                        AND CODPROD = P_CODPROD)) MOVIMENTACOES
                             WHERE PCSALDORCAFORNEC.CODUSUR = P_CODUSUR
                               AND TRUNC(SYSDATE) BETWEEN
                                   PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                   PCSALDORCAFORNEC.DTFIMVIGENCIA
                               AND PCSALDORCAFORNEC.CODFORNEC = 9999
                               AND MOVIMENTACOES.CODIGO(+) =
                                   PCSALDORCAFORNEC.CODIGO
                             GROUP BY PCSALDORCAFORNEC.CODIGO,
                                      PCSALDORCAFORNEC.CODFORNEC,
                                      PCSALDORCAFORNEC.VLLIMCRED,
                                      PCSALDORCAFORNEC.DTFIMVIGENCIA
                            HAVING NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) + SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) > 0
                             ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
          VNDISP := NVL(C_VERBA9999.VLLIMCRED, 0) +
                    NVL(C_VERBA9999.VALORLANC, 0);
          IF VNDISP < 0 THEN
            VNDISP := 0;
          END IF;
          IF VNDISP >= ABS(VNRESTO) THEN
            VNLANC := VNRESTO;
          ELSE
            VNLANC := (-1) * VNDISP; --AJUSTE SABRINA (O DISPONIVEL EH SEMPRE POSITIVO, MAS O LANCAMENTO EH DEBITO)
          END IF;
          VNRESTO := VNRESTO - VNLANC;
          INSERT INTO PCMOVSALDORCAFORNEC
            (CODIGO,
             CODUSUR,
             CODFORNEC,
             DTLANC,
             CODFUNCLANC,
             ROTINALANC,
             NUMPED,
             CODPROD,
             VALORLANC,
             NUMSEQ)
          VALUES
            (C_VERBA9999.CODIGO,
             P_CODUSUR,
             C_VERBA9999.CODFORNEC,
             SYSDATE,
             P_CODFUNC,
             P_CODROTINA,
             P_NUMPED,
             P_CODPROD,
             VNLANC,
             P_NUMSEQ);
          -- NAO HA MAIS O QUE LANCAR
          IF VNRESTO = 0 THEN
            EXIT;
          END IF;
        END LOOP;
      END IF;

      IF VNRESTO <> 0 THEN
        VSMENSAGEM := 'RCA SEM CRÉDITO PARA LIBERAR O ITEM COM DESCONTO.';
      END IF;
    END IF;
  END IF;

--  IF VSMENSAGEM <> 'OK' THEN
--    ROLLBACK;
--  END IF;

  P_MENSAGEM := VSMENSAGEM;

END PRC_VALIDAITEMSALDORCAFORNEC;
/*QUEBRA*/
PROCEDURE PRC_ATUALIZA_MOVSALDORCAFORNEC(P_DATA_INICIO IN DATE) IS
  VBVALIDO               BOOLEAN;
  VNDIF                  NUMBER;
  VNRESTO                NUMBER;
  VNLANC                 NUMBER;
  VSMENSAGEM             VARCHAR2(3000);
  VNCOUNTITENS           NUMBER;
  VNDISP                 NUMBER;
  VICONT                 NUMBER;
  VNCODIGOVERBA          NUMBER;
  VSBONIFICALTDEBCREDRCA PCCONSUM.BONIFICALTDEBCREDRCA%TYPE;

  TYPE T_ITENS IS RECORD(
    NUMPED   PCPEDC.NUMPED%TYPE,
    CODPROD  PCPEDI.CODPROD%TYPE,
    NUMSEQ   PCPEDI.NUMSEQ%TYPE,
    MENSAGEM VARCHAR2(3000));

  TYPE TB_ITENS IS TABLE OF T_ITENS INDEX BY BINARY_INTEGER;

  GVET_REGITENS TB_ITENS;

BEGIN
  SELECT PCCONSUM.BONIFICALTDEBCREDRCA
    INTO VSBONIFICALTDEBCREDRCA
    FROM PCCONSUM;
  FOR REG_PEDIDOS IN (SELECT NUMPED,
                             CODFILIAL,
                             CODUSUR,
                             DATA,
                             CODEMITENTE,
                             NUMPEDRCA
                        FROM PCPEDC
                       WHERE DATA >= P_DATA_INICIO
                         AND DTLIBERA IS NULL
                         AND PCPEDC.CONDVENDA NOT IN
                             (4, DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 5),
                              DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 6),
                              DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 11),
                              DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 12))
                         AND PCPEDC.POSICAO NOT IN ('P', 'B', 'C')
                         AND DTCANCEL IS NULL
                      UNION
                      SELECT NUMPED,
                             CODFILIAL,
                             CODUSUR,
                             DTLIBERA DATA,
                             CODEMITENTE,
                             NUMPEDRCA
                        FROM PCPEDC
                       WHERE DTLIBERA >= P_DATA_INICIO
                         AND DTLIBERA IS NOT NULL
                         AND PCPEDC.CONDVENDA NOT IN
                             (4, DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 5),
                              DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 6),
                              DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 11),
                              DECODE(VSBONIFICALTDEBCREDRCA, 'S', 0, 12))
                         AND PCPEDC.POSICAO NOT IN ('P', 'B', 'C')
                         AND DTCANCEL IS NULL
                       ORDER BY 4) LOOP
    VBVALIDO     := TRUE;
    VSMENSAGEM   := NULL;
    VNCOUNTITENS := 0;
    GVET_REGITENS.DELETE;

    --DEBITOS
    BEGIN
      -- LACO DOS DEBITOS
      FOR C_ITENS IN (SELECT PCPRODUT.CODFORNEC,
                             PCPEDI.CODPROD,
                             PCPEDI.PVENDA,
                             PCPEDI.PBASERCA,
                             PCPEDI.PTABELA,
                             PCPEDI.QT,
                             PCPEDI.NUMSEQ
                        FROM PCPEDI, PCPRODUT
                       WHERE PCPEDI.NUMPED = REG_PEDIDOS.NUMPED
                         AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                         AND NVL(PCPEDI.PVENDA, 0) -
                             NVL(PCPEDI.PBASERCA, NVL(PCPEDI.PTABELA, 0)) < 0
                       ORDER BY PCPRODUT.CODFORNEC, PCPEDI.CODPROD) LOOP
        BEGIN
          VNDIF   := (NVL(C_ITENS.PVENDA, 0) -
                     NVL(C_ITENS.PBASERCA, C_ITENS.PTABELA)) *
                     NVL(C_ITENS.QT, 0);
          VNRESTO := VNDIF;
          FOR C_VERBAFORNECEDOR IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                           PCSALDORCAFORNEC.CODFORNEC,
                                           NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                           PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                           SUM(NVL(MOVIMENTACOES.VALORLANC,
                                                   0)) VALORLANC
                                      FROM PCSALDORCAFORNEC,
                                           (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                                   PCMOVSALDORCAFORNEC.VALORLANC
                                              FROM PCMOVSALDORCAFORNEC
                                             WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                                     WHERE PCSALDORCAFORNEC.CODUSUR =
                                           REG_PEDIDOS.CODUSUR
                                       AND REG_PEDIDOS.DATA BETWEEN
                                           PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                           PCSALDORCAFORNEC.DTFIMVIGENCIA
                                       AND PCSALDORCAFORNEC.CODFORNEC =
                                           C_ITENS.CODFORNEC
                                       AND MOVIMENTACOES.CODIGO(+) =
                                           PCSALDORCAFORNEC.CODIGO
                                     GROUP BY PCSALDORCAFORNEC.CODIGO,
                                              PCSALDORCAFORNEC.CODFORNEC,
                                              PCSALDORCAFORNEC.VLLIMCRED,
                                              PCSALDORCAFORNEC.DTFIMVIGENCIA
                                    HAVING NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) + SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) > 0
                                     ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
            VNDISP := NVL(C_VERBAFORNECEDOR.VLLIMCRED, 0) +
                      NVL(C_VERBAFORNECEDOR.VALORLANC, 0);
            IF VNDISP < 0 THEN
              VNDISP := 0;
            END IF;
            IF VNDISP >= ABS(VNRESTO) THEN
              VNLANC := VNRESTO;
            ELSE
              VNLANC := (-1) * VNDISP; --AJUSTE SABRINA (O DISPONIVEL EH SEMPRE POSITIVO, MAS O LANCAMENTO EH DEBITO)
            END IF;
            VNRESTO := VNRESTO - VNLANC;
            INSERT INTO PCMOVSALDORCAFORNEC
              (CODIGO,
               CODUSUR,
               CODFORNEC,
               DTLANC,
               CODFUNCLANC,
               ROTINALANC,
               NUMPED,
               CODPROD,
               VALORLANC,
               NUMSEQ)
            VALUES
              (C_VERBAFORNECEDOR.CODIGO,
               REG_PEDIDOS.CODUSUR,
               C_VERBAFORNECEDOR.CODFORNEC,
               SYSDATE,
               REG_PEDIDOS.CODEMITENTE,
               DECODE(REG_PEDIDOS.CODEMITENTE,
                      '8888',
                      DECODE(REG_PEDIDOS.NUMPEDRCA, NULL, 2521, 567),
                      316),
               REG_PEDIDOS.NUMPED,
               C_ITENS.CODPROD,
               VNLANC,
               C_ITENS.NUMSEQ);
            -- NAO HA MAIS O QUE LANCAR
            IF VNRESTO = 0 THEN
              EXIT;
            END IF;
          END LOOP;
          IF VNRESTO <> 0 THEN
            SELECT COUNT(*)
              INTO VICONT
              FROM PCSALDORCAFORNEC, PCMOVSALDORCAFORNEC
             WHERE PCSALDORCAFORNEC.CODUSUR = REG_PEDIDOS.CODUSUR
               AND REG_PEDIDOS.DATA BETWEEN PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                   PCSALDORCAFORNEC.DTFIMVIGENCIA
               AND PCSALDORCAFORNEC.CODFORNEC = 9999
               AND PCMOVSALDORCAFORNEC.CODIGO(+) = PCSALDORCAFORNEC.CODIGO;
            IF VICONT = 0 THEN
              SELECT MAX(CODIGO) + 1 INTO VNCODIGOVERBA FROM PCSALDORCAFORNEC;
              INSERT INTO PCSALDORCAFORNEC
                (CODIGO,
                 CODUSUR,
                 CODFORNEC,
                 DTALT,
                 VLLIMCRED,
                 DTINICIOVIGENCIA,
                 DTFIMVIGENCIA,
                 CODFUNCCAD)
              VALUES
                (VNCODIGOVERBA,
                 REG_PEDIDOS.CODUSUR,
                 9999,
                 TRUNC(SYSDATE),
                 0,
                 REG_PEDIDOS.DATA,
                 REG_PEDIDOS.DATA,
                 1);
            END IF;
            FOR C_VERBA9999 IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                       PCSALDORCAFORNEC.CODFORNEC,
                                       NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                       PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                       SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) VALORLANC
                                  FROM PCSALDORCAFORNEC,
                                       (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                               PCMOVSALDORCAFORNEC.VALORLANC
                                          FROM PCMOVSALDORCAFORNEC
                                         WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                                 WHERE PCSALDORCAFORNEC.CODUSUR =
                                       REG_PEDIDOS.CODUSUR
                                   AND REG_PEDIDOS.DATA BETWEEN
                                       PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                       PCSALDORCAFORNEC.DTFIMVIGENCIA
                                   AND PCSALDORCAFORNEC.CODFORNEC = 9999
                                   AND MOVIMENTACOES.CODIGO(+) =
                                       PCSALDORCAFORNEC.CODIGO
                                 GROUP BY PCSALDORCAFORNEC.CODIGO,
                                          PCSALDORCAFORNEC.CODFORNEC,
                                          PCSALDORCAFORNEC.VLLIMCRED,
                                          PCSALDORCAFORNEC.DTFIMVIGENCIA
                                -- HAVING NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) + SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) > 0
                                 ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
              VNDISP := NVL(C_VERBA9999.VLLIMCRED, 0) +
                        NVL(C_VERBA9999.VALORLANC, 0);
              VNLANC := VNRESTO;
              VNRESTO := VNRESTO - VNLANC;
              INSERT INTO PCMOVSALDORCAFORNEC
                (CODIGO,
                 CODUSUR,
                 CODFORNEC,
                 DTLANC,
                 CODFUNCLANC,
                 ROTINALANC,
                 NUMPED,
                 CODPROD,
                 VALORLANC,
                 NUMSEQ)
              VALUES
                (C_VERBA9999.CODIGO,
                 REG_PEDIDOS.CODUSUR,
                 C_VERBA9999.CODFORNEC,
                 SYSDATE,
                 REG_PEDIDOS.CODEMITENTE,
                 DECODE(REG_PEDIDOS.CODEMITENTE,
                        '8888',
                        DECODE(REG_PEDIDOS.NUMPEDRCA, NULL, 2521, 567),
                        316),
                 REG_PEDIDOS.NUMPED,
                 C_ITENS.CODPROD,
                 VNLANC,
                 C_ITENS.NUMSEQ);
              -- NAO HA MAIS O QUE LANCAR
              IF VNRESTO = 0 THEN
                EXIT;
              END IF;
            END LOOP;
          END IF;
          IF VNRESTO <> 0 THEN
            VBVALIDO := FALSE;
            VNCOUNTITENS := VNCOUNTITENS + 1;
            GVET_REGITENS(VNCOUNTITENS).NUMPED := REG_PEDIDOS.NUMPED;
            GVET_REGITENS(VNCOUNTITENS).CODPROD := C_ITENS.CODPROD;
            GVET_REGITENS(VNCOUNTITENS).NUMSEQ := C_ITENS.NUMSEQ;
            GVET_REGITENS(VNCOUNTITENS).MENSAGEM := 'RCA SEM CRÉDITO PARA LIBERAR O ITEM COM DESCONTO.';
            EXIT;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            VBVALIDO := FALSE;
            VNCOUNTITENS := VNCOUNTITENS + 1;
            GVET_REGITENS(VNCOUNTITENS).NUMPED := REG_PEDIDOS.NUMPED;
            GVET_REGITENS(VNCOUNTITENS).CODPROD := C_ITENS.CODPROD;
            GVET_REGITENS(VNCOUNTITENS).NUMSEQ := C_ITENS.NUMSEQ;
            GVET_REGITENS(VNCOUNTITENS).MENSAGEM := 'ERRO AO SELECIONAR VERBAS PARA O ITEM DEBITO .' ||
                                                    SQLCODE || '-' ||
                                                    SQLERRM;
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        VBVALIDO := FALSE;
        VNCOUNTITENS := VNCOUNTITENS + 1;
        GVET_REGITENS(VNCOUNTITENS).NUMPED := REG_PEDIDOS.NUMPED;
        GVET_REGITENS(VNCOUNTITENS).CODPROD := NULL;
        GVET_REGITENS(VNCOUNTITENS).NUMSEQ := NULL;
        GVET_REGITENS(VNCOUNTITENS).MENSAGEM := 'ERRO AO SELECIONAR ITENS DO PEDIDO DEBITO.' ||
                                                SQLCODE || '-' || SQLERRM;
    END;

    -- CREDITOS
    BEGIN
      -- LACO DOS CREDITOS
      FOR C_ITENS IN (SELECT PCPRODUT.CODFORNEC,
                             PCPEDI.CODPROD,
                             PCPEDI.PVENDA,
                             PCPEDI.PBASERCA,
                             PCPEDI.PTABELA,
                             PCPEDI.QT,
                             PCPEDI.NUMSEQ
                        FROM PCPEDI, PCPRODUT
                       WHERE PCPEDI.NUMPED = REG_PEDIDOS.NUMPED
                         AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                         AND NVL(PCPEDI.PVENDA, 0) -
                             NVL(PCPEDI.PBASERCA, NVL(PCPEDI.PTABELA, 0)) > 0
                       ORDER BY PCPRODUT.CODFORNEC, PCPEDI.CODPROD) LOOP
        BEGIN
          VNDIF   := (NVL(C_ITENS.PVENDA, 0) -
                     NVL(C_ITENS.PBASERCA, C_ITENS.PTABELA)) *
                     NVL(C_ITENS.QT, 0);
          VNRESTO := VNDIF;
          SELECT COUNT(*)
            INTO VICONT
            FROM PCSALDORCAFORNEC, PCMOVSALDORCAFORNEC
           WHERE PCSALDORCAFORNEC.CODUSUR = REG_PEDIDOS.CODUSUR
             AND REG_PEDIDOS.DATA BETWEEN PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                 PCSALDORCAFORNEC.DTFIMVIGENCIA
             AND PCSALDORCAFORNEC.CODFORNEC = 9999
             AND PCMOVSALDORCAFORNEC.CODIGO(+) = PCSALDORCAFORNEC.CODIGO;
          IF VICONT = 0 THEN
            SELECT MAX(CODIGO) + 1 INTO VNCODIGOVERBA FROM PCSALDORCAFORNEC;
            INSERT INTO PCSALDORCAFORNEC
              (CODIGO,
               CODUSUR,
               CODFORNEC,
               DTALT,
               VLLIMCRED,
               DTINICIOVIGENCIA,
               DTFIMVIGENCIA,
               CODFUNCCAD)
            VALUES
              (VNCODIGOVERBA,
               REG_PEDIDOS.CODUSUR,
               9999,
               TRUNC(SYSDATE),
               0,
               REG_PEDIDOS.DATA,
               REG_PEDIDOS.DATA,
               1);
          END IF;
          FOR C_VERBA9999 IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                     PCSALDORCAFORNEC.CODFORNEC,
                                     NVL(PCSALDORCAFORNEC.VLLIMCRED, 0) VLLIMCRED,
                                     PCSALDORCAFORNEC.DTFIMVIGENCIA,
                                     SUM(NVL(MOVIMENTACOES.VALORLANC, 0)) VALORLANC
                                FROM PCSALDORCAFORNEC,
                                     (SELECT PCMOVSALDORCAFORNEC.CODIGO,
                                             PCMOVSALDORCAFORNEC.VALORLANC
                                        FROM PCMOVSALDORCAFORNEC
                                       WHERE PCMOVSALDORCAFORNEC.DTCANCEL IS NULL) MOVIMENTACOES
                               WHERE PCSALDORCAFORNEC.CODUSUR =
                                     REG_PEDIDOS.CODUSUR
                                 AND REG_PEDIDOS.DATA BETWEEN
                                     PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                     PCSALDORCAFORNEC.DTFIMVIGENCIA
                                 AND PCSALDORCAFORNEC.CODFORNEC = 9999
                                 AND MOVIMENTACOES.CODIGO(+) =
                                     PCSALDORCAFORNEC.CODIGO
                               GROUP BY PCSALDORCAFORNEC.CODIGO,
                                        PCSALDORCAFORNEC.CODFORNEC,
                                        NVL(PCSALDORCAFORNEC.VLLIMCRED, 0),
                                        PCSALDORCAFORNEC.DTFIMVIGENCIA
                               ORDER BY PCSALDORCAFORNEC.DTFIMVIGENCIA DESC) LOOP
            VNLANC  := VNDIF;
            VNRESTO := 0;
            INSERT INTO PCMOVSALDORCAFORNEC
              (CODIGO,
               CODUSUR,
               CODFORNEC,
               DTLANC,
               CODFUNCLANC,
               ROTINALANC,
               NUMPED,
               CODPROD,
               VALORLANC,
               NUMSEQ)
            VALUES
              (C_VERBA9999.CODIGO,
               REG_PEDIDOS.CODUSUR,
               C_VERBA9999.CODFORNEC,
               SYSDATE,
               REG_PEDIDOS.CODEMITENTE,
               DECODE(REG_PEDIDOS.CODEMITENTE,
                      '8888',
                      DECODE(REG_PEDIDOS.NUMPEDRCA, NULL, 2521, 567),
                      316),
               REG_PEDIDOS.NUMPED,
               C_ITENS.CODPROD,
               VNLANC,
               C_ITENS.NUMSEQ);
            -- NAO HA MAIS O QUE LANCAR
            IF VNRESTO = 0 THEN
              EXIT;
            END IF;
          END LOOP;
          IF VNRESTO <> 0 THEN
            VBVALIDO := FALSE;
            VNCOUNTITENS := VNCOUNTITENS + 1;
            GVET_REGITENS(VNCOUNTITENS).NUMPED := REG_PEDIDOS.NUMPED;
            GVET_REGITENS(VNCOUNTITENS).CODPROD := C_ITENS.CODPROD;
            GVET_REGITENS(VNCOUNTITENS).NUMSEQ := C_ITENS.NUMSEQ;
            GVET_REGITENS(VNCOUNTITENS).MENSAGEM := 'RCA SEM CRÉDITO PARA LIBERAR O ITEM COM CREDITO.';
            EXIT;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            VBVALIDO := FALSE;
            VNCOUNTITENS := VNCOUNTITENS + 1;
            GVET_REGITENS(VNCOUNTITENS).NUMPED := REG_PEDIDOS.NUMPED;
            GVET_REGITENS(VNCOUNTITENS).CODPROD := C_ITENS.CODPROD;
            GVET_REGITENS(VNCOUNTITENS).NUMSEQ := C_ITENS.NUMSEQ;
            GVET_REGITENS(VNCOUNTITENS).MENSAGEM := 'ERRO AO SELECIONAR VERBAS 9999 PARA O ITEM CREDITO.' ||
                                                    SQLCODE || '-' ||
                                                    SQLERRM;
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        VBVALIDO := FALSE;
        VNCOUNTITENS := VNCOUNTITENS + 1;
        GVET_REGITENS(VNCOUNTITENS).NUMPED := REG_PEDIDOS.NUMPED;
        GVET_REGITENS(VNCOUNTITENS).CODPROD := NULL;
        GVET_REGITENS(VNCOUNTITENS).NUMSEQ := NULL;
        GVET_REGITENS(VNCOUNTITENS).MENSAGEM := 'ERRO AO SELECIONAR ITENS DO PEDIDO CREDITO.' ||
                                                SQLCODE || '-' || SQLERRM;
    END;

--    IF VBVALIDO = TRUE THEN
--      COMMIT;
  --  ELSE
  --    ROLLBACK;
      FOR I IN 1 .. VNCOUNTITENS LOOP
        INSERT INTO PCLOGSALDORCAFORNEC
          (NUMPED, CODPROD, NUMSEQ, MENSAGEM)
        VALUES
          (GVET_REGITENS(I).NUMPED,
           GVET_REGITENS(I).CODPROD,
           GVET_REGITENS(I).NUMSEQ,
           GVET_REGITENS(I).MENSAGEM);
--        COMMIT;
      END LOOP;
  --  END IF;
  END LOOP;
END PRC_ATUALIZA_MOVSALDORCAFORNEC;

/******************************************************************************************************
                                            HISTORICO
    DATA       RESPONSAVEL      ALTERACAO
    ---------- ---------------- -------------------------------------------------------------------------
    28/03/2014 Rafael Braga     Criação da procedure, usada na 329 no cancelamento de itens e pedido (com loop).
  ******************************************************************************************************/

PROCEDURE PRC_CANCELARITEM(P_CODUSUR   IN NUMBER,
                           P_NUMPED    IN NUMBER,
                           P_CODFORNEC IN NUMBER,
                           P_CODPROD   IN NUMBER,
                           P_NUMSEQ    IN NUMBER,
                           P_CODROTINA IN PCROTINA.CODIGO%TYPE,
                           P_CODFUNC   IN PCEMPR.MATRICULA%TYPE,
                           P_MENSAGEM  OUT VARCHAR2) IS

  VSMENSAGEM VARCHAR2(3000);
BEGIN
  VSMENSAGEM := 'OK';
  BEGIN
    FOR C_BLOQUEIASALDO IN (SELECT PCSALDORCAFORNEC.CODIGO,
                                   PCSALDORCAFORNEC.CODFORNEC,
                                   PCSALDORCAFORNEC.VLLIMCRED
                              FROM PCSALDORCAFORNEC
                             WHERE PCSALDORCAFORNEC.CODUSUR = P_CODUSUR
                               AND TRUNC(SYSDATE) BETWEEN
                                   PCSALDORCAFORNEC.DTINICIOVIGENCIA AND
                                   PCSALDORCAFORNEC.DTFIMVIGENCIA
                               AND PCSALDORCAFORNEC.CODFORNEC IN
                                   (P_CODFORNEC, 9999)
                               FOR UPDATE) LOOP
      EXIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      VSMENSAGEM := 'ERRO AO LOCAR VERBA RCA-FORNECEDOR: ' || SQLCODE ||
                    ' - ' || SQLERRM;
      RAISE;
  END;

  IF VSMENSAGEM = 'OK' THEN
    -- ESTORNAR MOVIMENTACAO COM VALORES ANTERIORES
    INSERT INTO PCMOVSALDORCAFORNEC
      (CODIGO,
       CODUSUR,
       CODFORNEC,
       DTLANC,
       CODFUNCLANC,
       ROTINALANC,
       VALORLANC,
       DTCANCEL,
       CODFUNCCANCEL,
       ROTINACANCEL,
       NUMPED,
       CODPROD,
       NUMSEQ)
      SELECT CODIGO,
             CODUSUR,
             CODFORNEC,
             SYSDATE,
             P_CODFUNC,
             P_CODROTINA,
             ((-1) * VALORLANC),
             SYSDATE,
             P_CODFUNC,
             P_CODROTINA,
             NUMPED,
             CODPROD,
             NUMSEQ
        FROM PCMOVSALDORCAFORNEC
       WHERE NUMPED = P_NUMPED
         AND CODPROD = P_CODPROD
         AND NVL(NUMSEQ, 0) = P_NUMSEQ;

    UPDATE PCMOVSALDORCAFORNEC
       SET DTCANCEL      = SYSDATE,
           CODFUNCCANCEL = P_CODFUNC,
           ROTINACANCEL  = P_CODROTINA
     WHERE NUMPED = P_NUMPED
       AND CODPROD = P_CODPROD
       AND NVL(NUMSEQ, 0) = P_NUMSEQ
       AND DTCANCEL IS NULL;

  END IF;

  P_MENSAGEM := VSMENSAGEM;
END PRC_CANCELARITEM;

END;
