CREATE OR REPLACE TRIGGER TRG_ATUALIZA_PCLOTE
   BEFORE INSERT OR DELETE OR UPDATE OF QTAVARIA, QTCONT, QT, QTBLOQUEADA
   ON PCMOV
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
   /************************************************************************************************************************
   PROPOSITO: ATUALIZAÇÃO DO LOTE (PCLOTE) TODA VEZ QUE HOUVER MOVIMENTAÇÃO (PCMOV) COM PRODUTO QUE TEM CONTROLE POR ESTOQUE.
   ROTINA: PACOTE
   UTILIZADA POR: ROTINAS QUE FAZEM INCLUSÃO, ALTERAÇÃO OU DELETE NA PCMOV
   *************************************************************************************************************************/
DECLARE
  VSESTOQUEPORLOTE        VARCHAR2(1) := '';
  VSNUMLOTE               PCMOV.NUMLOTE%TYPE := '';
  VNQTBLOQUEADA           PCMOV.QTBLOQUEADA%TYPE := 0;
  VNQTINDENIZ             PCMOV.QTAVARIA%TYPE := 0;
  VNQTRESERV              PCMOV.QT%TYPE := 0;
  VNNOVAQTBLOQUEADA       PCMOV.QTBLOQUEADA%TYPE := 0;
  VNNOVAQTINDENIZ         PCMOV.QTAVARIA%TYPE := 0;
  VNNOVAQTRESERV          PCMOV.QT%TYPE;
  VNQTDEESTOQUE           PCMOV.QT%TYPE := 0;
  VNQTINDUSTRIA           PCMOVCOMPLE.QTINDUSTRIA%TYPE := 0;
  VNNOVAQTINDUSTRIA       PCMOVCOMPLE.QTINDUSTRIA%TYPE := 0;
  VNQTINDUSTRIAMOV        PCMOVCOMPLE.QTINDUSTRIA%TYPE := 0;
  VNNOTAENTREGAFUT        PCNFSAID.NUMNOTA%TYPE := 0;
  VNNOTAENTRADAENTREGAFUT PCNFENT.NUMNOTA%TYPE := 0;
  VELOTEOBRIGATORIO       EXCEPTION;
  VNCONDVENDA                PCPEDC.CONDVENDA%TYPE;
  VICONTADOR                 NUMBER;
  VNEXISTELOTECLI            NUMBER;
  VNVOLTAESTOQUEFILIALRETIRA VARCHAR2(1) := '';
  VNVOLTAESTOQUEFILIALVIRTUAL VARCHAR2(1) := '';
  VNPOSICAOPEDIDO            VARCHAR2(1) := ''; --> TAREFA: 3559.000916.2014
  VNCANCELAPEDIDO            BOOLEAN := FALSE; --> TAREFA: 3559.000916.2014
  VNNUMNOTACONSIG            PCPEDC.NUMNOTACONSIG%TYPE := 0;
  VNNUMTRANSVENDAORIG        PCMOV.NUMTRANSVENDA%TYPE := 0;
  VSPROGRAMA                 PCMOV.ROTINACAD%TYPE := '';
  VNTRANSFERENCIASAIDA         NUMBER;
  VDDATAFABRICACAO           PCLOTE.DATAFABRICACAO%TYPE := NULL;
  VDDTVALIDADE               PCLOTE.DTVALIDADE%TYPE := NULL;
  VDDTCANCELOP               PCOPC.DTCANCEL%TYPE;
  VSPOSICAOOP                PCOPC.POSICAO%TYPE;
  VDEVSIMBOLICA              PCNFENT.DEVSIMBOLICA%TYPE := 'N';
  VSUSACENTRALFATURAMENTO    VARCHAR2(1) := 'N';
  VSFILIALRESERVALOTE        PCFILIAL.CODIGO%TYPE := '';
BEGIN
  BEGIN
    SELECT NVL(ESTOQUEPORLOTE, 'N')
      INTO VSESTOQUEPORLOTE
      FROM PCPRODUT
     WHERE PCPRODUT.CODPROD = NVL(:NEW.CODPROD, :OLD.CODPROD);

    IF VSESTOQUEPORLOTE = 'S' THEN
      VSPROGRAMA := NVL(:NEW.ROTINACAD,SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 80));

      IF TRIM(VSPROGRAMA) IS NULL THEN
         VSPROGRAMA := 'SEM PROGRAMA';

      END IF;

      IF (SUBSTR(:NEW.CODOPER, 1, 1)) <> 'E' THEN
        /* VERIFICAR SE A NOTA É TIPO 7, POIS ESTA NÃO DEVE SER CONSIDERADA */
        BEGIN
          VNNOTAENTREGAFUT := 0;

          IF NVL(:OLD.NUMTRANSVENDA, :NEW.NUMTRANSVENDA) > 0 THEN
            SELECT COUNT(1)
              INTO VNNOTAENTREGAFUT
              FROM PCNFSAID
             WHERE NUMTRANSVENDA = NVL(:OLD.NUMTRANSVENDA, :NEW.NUMTRANSVENDA)
               AND CONDVENDA = 7;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            VNNOTAENTREGAFUT := 0;
        END;
      END IF;

      /* VERIFICAR SE HÁ ENTRADA DE ENTREGA FUTURA, CASO AFIRMATIVO NÃO HAVERÁ VALIDAÇÃO DE LOTES */
      BEGIN
        VNNOTAENTRADAENTREGAFUT := 0;

        IF NVL(:OLD.NUMTRANSENT, :NEW.NUMTRANSENT) > 0 THEN
          SELECT COUNT(1)
            INTO VNNOTAENTRADAENTREGAFUT
            FROM PCNFENT
           WHERE NUMTRANSENT = NVL(:OLD.NUMTRANSENT, :NEW.NUMTRANSENT)
             AND PCNFENT.NFENTREGAFUTURA = 'S'
             AND PCNFENT.TIPODESCARGA = '2';
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          VNNOTAENTRADAENTREGAFUT := 0;
      END;
      /* VALIDANDO PARÂMETRO PARA VOLTAR ESTOQUE NA DEVOLUÇÃO */
      BEGIN
        SELECT NVL(PCPARAMFILIAL.VALOR, 'N')
          INTO VNVOLTAESTOQUEFILIALRETIRA
          FROM PCPARAMFILIAL
         WHERE PCPARAMFILIAL.CODFILIAL = :NEW.CODFILIAL
           AND PCPARAMFILIAL.NOME LIKE '%VOLTARESTOQUEFILIALRETIRA%';
      EXCEPTION
        WHEN OTHERS THEN
          VNVOLTAESTOQUEFILIALRETIRA := 'N';
      END;

      /* VALIDANDO PARÂMETRO PARA VOLTAR ESTOQUE FILIAL VIRTUAL NA DEVOLUÇÃO */
      BEGIN
        SELECT NVL(PCPARAMFILIAL.VALOR, 'N')
          INTO VNVOLTAESTOQUEFILIALVIRTUAL
          FROM PCPARAMFILIAL
         WHERE PCPARAMFILIAL.CODFILIAL = :NEW.CODFILIAL
           AND PCPARAMFILIAL.NOME LIKE '%VOLTARESTOQUEFILIALVIRTUAL%';
      EXCEPTION
        WHEN OTHERS THEN
          VNVOLTAESTOQUEFILIALVIRTUAL := 'N';
      END;
      /* VALIDANDO O TIPO DA MOVIMENTAÇÃO E A POSIÇÃO */
      --TAREFA 120787
      VNCONDVENDA     := 0;
      VICONTADOR      := 0;
      VNPOSICAOPEDIDO := ''; --> TAREFA: 3559.000916.2014
      VNCANCELAPEDIDO := FALSE; --> TAREFA: 3559.000916.2014
      VNTRANSFERENCIASAIDA := 0; ---> TAREFA: LOG-1913 (HUGO AQUINO)

      IF NVL(:NEW.CODOPER, :OLD.CODOPER) <> 'E' AND :NEW.ROTINACAD NOT LIKE '%1124%' THEN
        SELECT COUNT(PCPEDC.NUMPED)
          INTO VICONTADOR
          FROM PCPEDC
         WHERE PCPEDC.NUMPED = NVL(:OLD.NUMPED, :NEW.NUMPED);

        IF VICONTADOR > 0 THEN
          SELECT PCPEDC.CONDVENDA, 
                 PCPEDC.POSICAO, 
                 FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZACENTRALFATURAMENTO',PCPEDC.CODFILIAL,'N')          
            INTO VNCONDVENDA, VNPOSICAOPEDIDO, VSUSACENTRALFATURAMENTO 
            FROM PCPEDC
           WHERE PCPEDC.NUMPED = NVL(:OLD.NUMPED, :NEW.NUMPED);
           
          --CASO SEJA SAIDA DE TRANSFERENCIA E UTILIZE CENTRAL DE FATURAMENTO ENTÃO BUSCA QUAL A FILIAL PARA RESERVAR O LOTE
          IF (VSUSACENTRALFATURAMENTO = 'S') AND (:NEW.CODOPER = 'ST') THEN
            SELECT DECODE(PCPEDI.POSICAOCFAT
                          ,NULL, NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)
                          ,'AFA', NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)
                          ,'ERE', NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)
                          ,'EVE', PCPEDC.CODFILIAL
                          ,'EVI', NVL(PCPEDC.CODFILIALNF, PCPEDC.CODFILIAL)
                          ,NULL) CODFILIAL
              INTO VSFILIALRESERVALOTE
              FROM PCPEDI, PCPEDC
             WHERE PCPEDI.NUMPED = PCPEDC.NUMPED
                   AND PCPEDI.NUMPED = NVL(:NEW.NUMPED, 0)
                   AND PCPEDI.CODPROD = :NEW.CODPROD
                   AND PCPEDI.NUMLOTE = :NEW.NUMLOTE
                   AND PCPEDI.NUMSEQ = NVL(:NEW.NUMSEQ, 1);  
          END IF;          
           
        END IF;

        --> TAREFA: 3559.000916.2014
        IF (VICONTADOR > 0) AND (VNPOSICAOPEDIDO = 'C') THEN
          VNCANCELAPEDIDO := TRUE;
        END IF;
      END IF;

      IF (INSERTING) AND (NVL(:NEW.QT, 0) > 0) THEN
        IF :NEW.CODOPER = 'ET' THEN
          BEGIN
            SELECT PCLOTE.DATAFABRICACAO, PCLOTE.DTVALIDADE
              INTO VDDATAFABRICACAO, VDDTVALIDADE
             FROM PCMOV MOVSAIDA, PCLOTE
            WHERE MOVSAIDA.CODOPER = 'ST'
              AND MOVSAIDA.NUMNOTA = :NEW.NUMNOTA
              AND MOVSAIDA.CODPROD = :NEW.CODPROD
              AND MOVSAIDA.NUMLOTE = :NEW.NUMLOTE
              AND PCLOTE.CODFILIAL = MOVSAIDA.CODFILIAL
              AND PCLOTE.CODPROD = MOVSAIDA.CODPROD
              AND PCLOTE.NUMLOTE = MOVSAIDA.NUMLOTE
              AND ROWNUM = 1;
           EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VDDATAFABRICACAO := NULL;
              VDDTVALIDADE     := NULL;
          END;
        ELSIF SUBSTR(:NEW.CODOPER, 1, 1) = 'E' THEN
          IF :NEW.NUMLOTE IS NOT NULL THEN
            VDDATAFABRICACAO := :NEW.DATAFABRICACAO;
            VDDTVALIDADE     := :NEW.DATAVALIDADE;
          ELSE
            VDDATAFABRICACAO := NULL;
            VDDTVALIDADE     := NULL;
          END IF;
        END IF;

         BEGIN
           BEGIN
           SELECT NVL(PCPEDIDO.NUMTRANSVENDA, 0)
             INTO VNNUMTRANSVENDAORIG
             FROM PCPEDIDO
            WHERE PCPEDIDO.NUMPED = NVL(:NEW.NUMPED, 0);
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
            VNNUMTRANSVENDAORIG := 0;
           END;

        IF VNNUMTRANSVENDAORIG > 0 THEN
          SELECT PCPEDC.CONDVENDA, PCPEDC.POSICAO
            INTO VNCONDVENDA, VNPOSICAOPEDIDO
            FROM PCPEDC
           WHERE PCPEDC.NUMPED =
                 (SELECT NUMPED
                    FROM PCNFSAID
                   WHERE NUMTRANSVENDA = VNNUMTRANSVENDAORIG);
           END IF;
          END;
        END IF;

      IF NVL(:NEW.NUMPED, 0) > 0 AND :NEW.CODOPER <> 'E' THEN
        BEGIN
          SELECT NVL(NUMNOTACONSIG, 0)
            INTO VNNUMNOTACONSIG
            FROM PCPEDC
           WHERE PCPEDC.NUMPED = :NEW.NUMPED;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VNNUMNOTACONSIG := 0;
        END;
      END IF;

      IF :NEW.CODOPER IN ('S', 'SR', 'SB') THEN  ---> TAREFA: LOG-1913 (HUGO AQUINO)
        BEGIN
          SELECT COUNT(*)
            INTO VNTRANSFERENCIASAIDA
          FROM PCTRANSFDEP
          WHERE NUMTRANSVENDA = :NEW.NUMTRANSVENDA
                AND CODPROD = :NEW.CODPROD
                AND (NVL(NUMTRANSTRANSFSAIDA, 0) > 0
                OR NVL(NUMTRANSTRANSFENT, 0) > 0);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VNTRANSFERENCIASAIDA := 0;
        END;
      END IF;

      IF :NEW.CODOPER = 'EN' THEN  ---> DDESTOQUE-7769 (HUGO AQUINO)
        VDEVSIMBOLICA := NVL(:NEW.DEVSIMBOLICA, 'N');
      END IF;
      
      -------------------------------------------- PROCESSAMENTO --------------------------------------------------------------
      IF NOT ((NVL(:NEW.CODOPER, 'X') IN ('ST', 'ET')) AND (VNCONDVENDA IN (1, 5, 9, 8)) AND (:NEW.QT < 0)) /*FERNANDES*/
        AND (VNNOTAENTREGAFUT = 0) AND (VNCONDVENDA <> 7) AND (VNNOTAENTRADAENTREGAFUT = 0) AND 
        (NVL(:OLD.STATUS, :NEW.STATUS) <> 'A') THEN
        ------------------------------------------- CASO ESTEJA INSERIDO OS DADOS -----------------------------------------------
        IF INSERTING THEN

          IF :NEW.NUMLOTE IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                                        'ERRO: O produto é controlado por lote e não existe lote informado para esta transação.!' ||
                                        CHR(13) ||
                                        'Favor informar o número do lote e tentar novamente.');
          END IF;
              /*INICIO DO PROCESSO PARA DEVOLUCAO COM FILIAL VIRTUAL*/
          IF ((:NEW.CODOPER IN ('ED', 'S')) AND
             (NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL) <> :NEW.CODFILIAL) AND
             ((VNNUMNOTACONSIG = 0))) THEN

            SELECT NVL((SELECT NVL(NUMLOTE, 'X') --VERIFICA SE EXISTE O LOTE NA FILIAL DE DESTINO
                         FROM PCLOTE
                        WHERE NUMLOTE = :NEW.NUMLOTE
                          AND CODPROD = :NEW.CODPROD
                          AND CODFILIAL =
                              NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)),
                       'X')
              INTO VSNUMLOTE
              FROM DUAL;

            IF VSNUMLOTE = 'X' THEN
              ---CASO O LOTE NÃO EXISTA FAZ A INSERÇÃO DO MESMO.
              BEGIN

                BEGIN
                  SELECT PCLOTE.DATAFABRICACAO, PCLOTE.DTVALIDADE
                    INTO VDDATAFABRICACAO, VDDTVALIDADE
                    FROM PCLOTE
                   WHERE 1=1
                     AND PCLOTE.CODFILIAL = :NEW.CODFILIAL
                     AND PCLOTE.CODPROD = :NEW.CODPROD
                     AND PCLOTE.NUMLOTE = :NEW.NUMLOTE
                     AND ROWNUM = 1;
                EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   VDDATAFABRICACAO := NULL;
                   VDDTVALIDADE     := NULL;
                 END;

                INSERT INTO PCLOTE
                  (CODFILIAL, CODPROD, NUMLOTE, QT, QTEST, DATAFABRICACAO, DTVALIDADE)
                VALUES
                  (NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL),
                   :NEW.CODPROD,
                   :NEW.NUMLOTE,
                   NVL(:NEW.QT, 0),
                   NVL(:NEW.QTCONT, 0),
                   VDDATAFABRICACAO,
                   VDDTVALIDADE);

              EXCEPTION
                WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20002,
                                          'ERRO: Não foi possível inserir o novo LOTE - ' ||
                                          SQLERRM);
              END;
            END IF;
          END IF;
          /*FIM DO PROCESSO PARA DEVOLUCAO COM FILIAL VIRTUAL*/

          BEGIN
            ----- SAÍDA -----
            IF SUBSTR(:NEW.CODOPER, 1, 1) IN ('S', 'R') THEN
              BEGIN
                IF ((VNNUMNOTACONSIG = 0)) THEN
                  IF (((:NEW.CODOPER IN ('S', 'SB', 'ST', 'SC', 'SP', 'RA', 'SR'))
                    AND ((NVL(:NEW.NUMPED, 0) <> 0) OR (NVL(:NEW.NUMOP, 0) <> 0) OR (NVL(:NEW.NUMTRANSAVULSA, 0) <> 0)))
                    AND (NVL(:NEW.QT, 0) > 0))
                    AND (NOT VNCANCELAPEDIDO) THEN
                    BEGIN
                      UPDATE PCLOTE
                         SET QTRESERV    = CASE WHEN ((NVL(:NEW.NUMTRANSAVULSA, 0) <> 0) AND (:NEW.CODOPER = 'SP')) THEN NVL(QTRESERV, 0)
                                                WHEN ((:NEW.CODOPER = 'ST') AND (VNCONDVENDA IN (1, 5, 9, 8)) AND (:NEW.STATUS = 'B') 
                                                       AND ((:NEW.NUMTRANSDEV IS NOT NULL) OR (:NEW.NUMTRANSDEVFOR IS NOT NULL))) THEN
                                                       NVL(QTRESERV, 0)
                                                ELSE GREATEST((NVL(QTRESERV, 0) - NVL(:NEW.QT, 0)), 0) END,
                             DTULTMOVSAI = TRUNC(SYSDATE)
                       WHERE NUMLOTE = :NEW.NUMLOTE
                         AND CODPROD = :NEW.CODPROD
                         AND CODFILIAL = (CASE /*HUGO AQUINO*/
                              WHEN ((:NEW.CODOPER IN ('S') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :NEW.CODOPER IN ('ED')) THEN
                                DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :NEW.CODFILIAL, NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                              WHEN (VNCONDVENDA = 10) OR (:NEW.CODOPER IN ('S', 'SR') AND NVL(:NEW.QT, 0) > 0) OR
                                (VNCONDVENDA = 1 AND :NEW.CODOPER IN ('ST') AND NVL(:NEW.QT, 0) > 0)  THEN
                                  NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                              ELSE
                                NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
                    EXCEPTION
                      WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20002,
                                                'ERRO: Não foi possível atualizar o estoque reservado do LOTE - ' ||
                                                SQLERRM);
                    END;
                  END IF;

                  IF (((:NEW.CODOPER IN ('S', 'SB', 'ST', 'SC', 'SP', 'RA', 'SR')) AND
                     ((NVL(:NEW.NUMPED, 0) <> 0) OR
                     (NVL(:NEW.NUMOP, 0) <> 0) OR
                     (NVL(:NEW.NUMTRANSAVULSA, 0) <> 0))) AND
                     (NVL(:NEW.QT, 0) < 0)) AND (NOT VNCANCELAPEDIDO) THEN
                    BEGIN

                      BEGIN
                        SELECT NVL(PCOPC.DTCANCEL, NULL)
                             , NVL(PCOPC.POSICAO,'')
                        INTO VDDTCANCELOP
                             , VSPOSICAOOP
                         FROM PCOPC
                         WHERE NVL(PCOPC.NUMOP,0) = NVL(:NEW.NUMOP,0);
                      EXCEPTION
                        WHEN OTHERS THEN
                          VDDTCANCELOP := NULL;
                          VSPOSICAOOP := '';
                      END;

                      UPDATE PCLOTE
                         SET QTRESERV    = (CASE 
                                            WHEN ((:NEW.CODOPER = 'SP') AND (NVL(:NEW.NUMOP, 0) <> 0) AND (NVL(:NEW.NUMTRANSAVULSA, 0) = 0)) THEN
                                              (CASE WHEN (VDDTCANCELOP IS NOT NULL AND VSPOSICAOOP = 'C') THEN
                                                    NVL(QTRESERV, 0)
                                                    ELSE GREATEST((NVL(QTRESERV, 0) - NVL(:NEW.QT, 0)), 0) END)
                                            WHEN ((:NEW.CODOPER = 'ST') AND (VNCONDVENDA IN (1, 5, 9, 8)) AND (:NEW.STATUS = 'B') AND (:NEW.NUMTRANSDEV IS NOT NULL)) THEN
                                                    NVL(QTRESERV, 0)     
                                            ELSE GREATEST(((NVL(QTRESERV, 0) + NVL(:OLD.QT, 0)) - NVL(:NEW.QT, 0)), 0) END),
                                            
                             DTULTMOVSAI = TRUNC(SYSDATE)
                       WHERE NUMLOTE = :NEW.NUMLOTE
                         AND CODPROD = :NEW.CODPROD
                         AND CODFILIAL = (CASE /*HUGO AQUINO*/
                              WHEN ((:NEW.CODOPER IN ('S') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :NEW.CODOPER IN ('ED')) THEN
                              DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :NEW.CODFILIAL, NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                              WHEN VNCONDVENDA IN (10) OR :NEW.CODOPER IN ('SR') THEN
                              NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                              ELSE
                              NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
                    EXCEPTION
                      WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20002,
                                                'ERRO: Não foi possível atualizar o estoque reservado do LOTE - ' ||
                                                SQLERRM);
                    END;
                  END IF;

                  IF (:NEW.CODOPER = 'SC') THEN
                    BEGIN

                      SELECT COUNT(1)
                        INTO VNEXISTELOTECLI
                        FROM PCLOTECLI T
                       WHERE T.CODCLI = :NEW.CODCLI
                         AND T.CODPROD = :NEW.CODPROD
                         AND T.NUMLOTE = :NEW.NUMLOTE;

                      IF (VNEXISTELOTECLI) > 0 THEN
                        UPDATE PCLOTECLI
                           SET QTLOTE = NVL(QTLOTE, 0) + (NVL(:NEW.QT, 0) - NVL(:OLD.QT, 0))
                         WHERE CODCLI = :NEW.CODCLI
                           AND CODPROD = :NEW.CODPROD
                           AND NUMLOTE = :NEW.NUMLOTE;
                      ELSE
                        INSERT INTO PCLOTECLI
                          (CODCLI, CODPROD, NUMLOTE, QTLOTE)
                        VALUES
                          (:NEW.CODCLI,
                           :NEW.CODPROD,
                           :NEW.NUMLOTE,
                           NVL(:NEW.QT, 0));
                      END IF;

                    EXCEPTION
                      WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20009,
                                                'ERRO: Ao atualizar o lote consignado (pclotecli) - ' ||
                                                SQLERRM);
                    END;
                  END IF;

                  UPDATE PCLOTE
                     SET QT          = NVL(QT, 0) - NVL(:NEW.QT, 0),
                         QTEST       = NVL(QTEST, 0) - NVL(:NEW.QTCONT, 0),
                         QTBLOQUEADA = GREATEST( GREATEST((NVL(QTBLOQUEADA, 0) - NVL(:NEW.QTBLOQUEADA, 0)), 0), GREATEST((NVL(QTINDENIZ, 0) - NVL(:NEW.QTAVARIA, 0)), 0) ),
                         QTINDENIZ   = GREATEST((NVL(QTINDENIZ, 0) - NVL(:NEW.QTAVARIA, 0)), 0),
                         QTINDUSTRIA = GREATEST((NVL(QTINDUSTRIA, 0) - NVL(:NEW.QTINDUSTRIA, 0)), 0)
                   WHERE NUMLOTE = :NEW.NUMLOTE
                     AND CODPROD = :NEW.CODPROD
                     AND CODFILIAL = (CASE /*HUGO AQUINO*/
                          WHEN ((:NEW.CODOPER IN ('S', 'SR', 'SB') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0)) THEN
                            DECODE(VNVOLTAESTOQUEFILIALRETIRA,
                                   'N',
                                   :NEW.CODFILIAL,
                                   NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                          WHEN (VNCONDVENDA = 10) OR (:NEW.CODOPER IN ('S', 'SR', 'SB') AND NVL(:NEW.QT, 0) > 0) OR
                            (VNCONDVENDA = 1 AND :NEW.CODOPER IN ('ST') AND NVL(:NEW.QT, 0) > 0)  THEN
                              NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                          ELSE
                            NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
                          
                  ----RESERVA LOTE CASO USE CFAT E SEJA SAIDA DE TRANSFERENCIA        
                  IF (VSUSACENTRALFATURAMENTO = 'S') AND (:NEW.CODOPER = 'ST') AND (VSFILIALRESERVALOTE <> '') THEN
                    UPDATE PCLOTE
                       SET QTRESERV = NVL(QTRESERV, 0) + NVL(:NEW.QT, 0)
                    WHERE CODPROD = :NEW.CODPROD
                          AND NUMLOTE = :NEW.NUMLOTE
                          AND CODFILIAL = VSFILIALRESERVALOTE;   
                  END IF;  
                        
                ELSIF ((VNNUMNOTACONSIG > 0)) THEN
                  --HUGO AQUINO - RETIRA ESTOQUE PCLOTECLI DE FATURAMENTO PELA 1437 SOLICITAÇÃO: 7064.020845.2017
                  BEGIN

                    SELECT COUNT(1)
                      INTO VNEXISTELOTECLI
                      FROM PCLOTECLI T
                     WHERE T.CODCLI = :NEW.CODCLI
                       AND T.CODPROD = :NEW.CODPROD
                       AND T.NUMLOTE = :NEW.NUMLOTE;

                    IF (VNEXISTELOTECLI) > 0 THEN
                      UPDATE PCLOTECLI
                         SET QTLOTE = NVL(QTLOTE, 0) - NVL(:NEW.QT, 0)
                       WHERE CODCLI = :NEW.CODCLI
                         AND CODPROD = :NEW.CODPROD
                         AND NUMLOTE = :NEW.NUMLOTE;
                    ELSE
                      INSERT INTO PCLOTECLI
                        (CODCLI, CODPROD, NUMLOTE, QTLOTE)
                      VALUES
                        (:NEW.CODCLI,
                         :NEW.CODPROD,
                         :NEW.NUMLOTE,
                         NVL(:NEW.QT, 0));
                    END IF;

                  EXCEPTION
                    WHEN OTHERS THEN
                      RAISE_APPLICATION_ERROR(-20009,
                                              'ERRO: Ao atualizar o lote consignado (pclotecli) - ' ||
                                              SQLERRM);
                  END;

                END IF;
              EXCEPTION
                WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20003,
                                          'ERRO: Ao atualizar o estoque do LOTE - ' ||
                                          SQLERRM);
              END;

              ----- ENTRADA -----
            ELSIF SUBSTR(:NEW.CODOPER, 1, 1) = 'E' THEN
              BEGIN
                IF (VNNUMNOTACONSIG = 0) AND (NVL(VDEVSIMBOLICA,'N') <> 'S') THEN

                  IF (:NEW.CODOPER = 'EN') THEN
                    --IMPLEMENTADA PARA RETORNOR O LOTE NA DEVOLUÇÃO DE VENDA CONSIGNADA.
                    BEGIN

                      SELECT COUNT(1)
                        INTO VNEXISTELOTECLI
                        FROM PCLOTECLI T
                       WHERE T.CODCLI = :NEW.CODCLI
                         AND T.CODPROD = :NEW.CODPROD
                         AND T.NUMLOTE = :NEW.NUMLOTE;

                      IF (VNEXISTELOTECLI) > 0 THEN
                        UPDATE PCLOTECLI
                           SET QTLOTE = NVL(QTLOTE, 0) - NVL(:NEW.QT, 0)
                         WHERE CODCLI = :NEW.CODCLI
                           AND CODPROD = :NEW.CODPROD
                           AND NUMLOTE = :NEW.NUMLOTE;
                        /*2350.061224.2015
                        UPDATE PCESTCLI
                           SET QTESTGER = QTESTGER -
                                          (NVL(:NEW.QT, 0) - NVL(:OLD.QT, 0))
                         WHERE CODCLI = :NEW.CODCLI
                           AND CODPROD = :NEW.CODPROD;*/
                      END IF;

                    EXCEPTION
                      WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20009,
                                                'ERRO: Ao atualizar o lote consignado (pclotecli) - ' ||
                                                SQLERRM);
                    END;
                  END IF;
                  
                  
                  -- Separado o update do QTBLOQUEADO e QTINDENIZ para atender o processo de Devolução de venda com Filial Retira
                  UPDATE PCLOTE
                     SET QT          = NVL(QT, 0) + NVL(:NEW.QT, 0),
                         QTEST       = NVL(QTEST, 0) + NVL(:NEW.QTCONT, 0),
                      --   QTBLOQUEADA = GREATEST( GREATEST((NVL(QTBLOQUEADA, 0) + NVL(:NEW.QTBLOQUEADA, 0)), 0), GREATEST((NVL(QTINDENIZ, 0) + NVL(:NEW.QTAVARIA, 0)), 0) ),
                      --   QTINDENIZ   = GREATEST((NVL(QTINDENIZ, 0) + NVL(:NEW.QTAVARIA, 0)), 0),
                         QTINDUSTRIA = GREATEST((NVL(QTINDUSTRIA, 0) + NVL(:NEW.QTINDUSTRIA, 0)), 0),
                         QTRESERV    = CASE 
                                         WHEN ((:NEW.CODOPER = 'EX') AND (NVL(:NEW.NUMOP, 0) <> 0)) THEN 
                                            GREATEST((NVL(QTRESERV, 0) + NVL(:NEW.QT, 0)), 0)
                                         WHEN ((:NEW.CODOPER = 'ET') AND (VNCONDVENDA IN (1, 5, 9, 8)) AND (:NEW.STATUS = 'B') AND (:NEW.NUMTRANSDEV IS NULL)) THEN
                                            GREATEST((NVL(QTRESERV, 0) + NVL(:NEW.QT, 0)), 0)                                             
                                         ELSE NVL(QTRESERV, 0) END,
                         DATAFABRICACAO = CASE WHEN VDDATAFABRICACAO IS NULL THEN DATAFABRICACAO ELSE VDDATAFABRICACAO END,
                         DTVALIDADE     = CASE WHEN VDDTVALIDADE IS NULL THEN DTVALIDADE ELSE VDDTVALIDADE END
                   WHERE NUMLOTE = :NEW.NUMLOTE
                     AND CODPROD = :NEW.CODPROD
                     AND CODFILIAL = (CASE /*HUGO AQUINO*/
                          WHEN ((:NEW.CODOPER IN ('ED') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0)) THEN
                          DECODE(VNVOLTAESTOQUEFILIALRETIRA,
                                 'N',
                                 :NEW.CODFILIAL,
                                 NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                          
                          WHEN (:NEW.CODOPER IN ('ED') AND NVL(:NEW.QT, 0) > 0) THEN NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                                 
                          WHEN VNCONDVENDA = 10 THEN
                          NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                          WHEN (:NEW.CODOPER IN ('EN') AND NVL(:NEW.QT, 0) <> 0) THEN
                            DECODE(VNVOLTAESTOQUEFILIALVIRTUAL,
                                 'N',
                                 NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL),
                                 NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL))
                          ELSE
                          NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
                    
                  IF( NVL(:NEW.QTBLOQUEADA, 0) <> 0 or NVL(:NEW.QTAVARIA, 0) <> 0) THEN
                  
                      UPDATE PCLOTE
                         SET QTBLOQUEADA = GREATEST( GREATEST((NVL(QTBLOQUEADA, 0) + NVL(:NEW.QTBLOQUEADA, 0)), 0), GREATEST((NVL(QTINDENIZ, 0) + NVL(:NEW.QTAVARIA, 0)), 0) ),
                             QTINDENIZ   = GREATEST((NVL(QTINDENIZ, 0) + NVL(:NEW.QTAVARIA, 0)), 0)
                       WHERE NUMLOTE = :NEW.NUMLOTE
                         AND CODPROD = :NEW.CODPROD
                         AND CODFILIAL = (CASE /*HUGO AQUINO*/
                              WHEN (:NEW.CODOPER IN ('ED')) THEN
                              DECODE(VNVOLTAESTOQUEFILIALRETIRA,
                                     'N',
                                     :NEW.CODFILIAL,
                                     NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                                     
                              WHEN VNCONDVENDA = 10 THEN
                              NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                              WHEN (:NEW.CODOPER IN ('EN') AND NVL(:NEW.QT, 0) <> 0) THEN
                                DECODE(VNVOLTAESTOQUEFILIALVIRTUAL,
                                     'N',
                                     NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL),
                                     NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL))
                              ELSE
                              NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
                   
                   END IF; 
                   
          IF SQL%ROWCOUNT = 0 THEN
          INSERT INTO PCLOTE
                (NUMLOTE
                 , CODPROD
                 , CODFILIAL
                 , QT
                 , QTEST
                 , QTBLOQUEADA
                 , QTINDENIZ
                 , QTINDUSTRIA
                 , QTRESERV
                 , DATAFABRICACAO
                 , DTVALIDADE
                 , NUMTRANSENT)
             VALUES (:NEW.NUMLOTE
                 , :NEW.CODPROD
                 , (CASE
                   WHEN VNCONDVENDA = 10
                    THEN NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                   ELSE NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL)
                  END)
                 , NVL(:NEW.QT, 0)
                 , NVL(:NEW.QTCONT, 0)
                 , GREATEST( NVL(:NEW.QTBLOQUEADA, 0), NVL(:NEW.QTAVARIA, 0) )
                 , GREATEST(NVL(:NEW.QTAVARIA, 0), 0)
                 , GREATEST(NVL(:NEW.QTINDUSTRIA, 0), 0)
                 , (CASE WHEN ((:NEW.CODOPER = 'EX') AND (NVL(:NEW.NUMOP, 0) <> 0)) THEN NVL(:NEW.QT, 0) ELSE 0 END)
                 , (CASE WHEN VDDATAFABRICACAO IS NULL THEN NULL ELSE VDDATAFABRICACAO END)
                 , (CASE WHEN VDDTVALIDADE IS NULL THEN NULL ELSE VDDTVALIDADE END)
                 , :NEW.NUMTRANSENT);
                  END IF;
                END IF;
              EXCEPTION
                WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20003,
                                          'ERRO: Ao atualizar o estoque do LOTE - ' ||
                                          SQLERRM);
              END;
            ELSE
              RAISE_APPLICATION_ERROR(-20004,
                                      'ERRO: Código de operação inválido - ' ||
                                      SQLERRM);
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20005,
                                      'ERRO: Número de LOTE informado não existe!');
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20006,
                                      'ERRO: Ao pesquisar o lote! - ' ||
                                      SQLERRM);
          END;
        END IF;

        ------------------------------------------ CASO ESTEJA ALTERANDO OS DADOS ----------------------------------------------
        IF (UPDATING) AND
           ((NVL(:OLD.QTAVARIA, 0) <> NVL(:NEW.QTAVARIA, 0)) OR (NVL(:OLD.QTCONT, 0) <> NVL(:NEW.QTCONT, 0)) OR
           (NVL(:OLD.QT, 0) <> NVL(:NEW.QT, 0)) OR (NVL(:OLD.QTBLOQUEADA, 0) <> NVL(:NEW.QTBLOQUEADA, 0))) AND
           ((VNNUMNOTACONSIG = 0)) THEN

           IF :NEW.NUMLOTE IS NULL THEN
             RAISE_APPLICATION_ERROR(-20001,
                                     'ERRO: O produto é controlado por lote e não existe lote informado para esta transação.!' ||
                                     CHR(13) ||
                                     'Favor informar o número do lote e tentar novamente.');
           END IF;

           BEGIN
             ----- SAÍDA -----
             IF SUBSTR(:NEW.CODOPER, 1, 1) IN ('S', 'R') THEN
               BEGIN
                 UPDATE PCLOTE
                    SET QT          = (NVL(QT, 0) + NVL(:OLD.QT, 0)) - NVL(:NEW.QT, 0),
                        QTEST       = (NVL(QTEST, 0) + NVL(:OLD.QTCONT, 0)) - NVL(:NEW.QTCONT, 0),
                        QTBLOQUEADA = GREATEST( GREATEST(((NVL(QTBLOQUEADA, 0) + NVL(:OLD.QTBLOQUEADA, 0)) - NVL(:NEW.QTBLOQUEADA, 0)), 0), GREATEST(((NVL(QTINDENIZ, 0) + NVL(:OLD.QTAVARIA, 0)) - NVL(:NEW.QTAVARIA, 0)), 0) ),
                        QTINDENIZ   = GREATEST(((NVL(QTINDENIZ, 0) + NVL(:OLD.QTAVARIA, 0)) - NVL(:NEW.QTAVARIA, 0)), 0),
                        QTINDUSTRIA = GREATEST(((NVL(QTINDUSTRIA, 0) + NVL(:OLD.QTINDUSTRIA, 0))), 0)
                  WHERE NUMLOTE = :NEW.NUMLOTE
                    AND CODPROD = :NEW.CODPROD
                    AND CODFILIAL = (CASE /*HUGO AQUINO*/
                         WHEN ((:NEW.CODOPER IN ('S') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :NEW.CODOPER IN ('ED')) THEN
                         DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :NEW.CODFILIAL, NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                         WHEN VNCONDVENDA = 10 THEN
                         NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                         ELSE
                         NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);

                 IF (((:NEW.CODOPER IN ('S', 'SB', 'ST', 'SC', 'SP', 'RA')) AND
                    ((NVL(:NEW.NUMPED, 0) <> 0) OR
                    (NVL(:NEW.NUMOP, 0) <> 0) OR
                    (NVL(:NEW.NUMTRANSAVULSA, 0) <> 0))) AND
                    (NVL(:NEW.QT, 0) > 0)) THEN
                   BEGIN
                     UPDATE PCLOTE
                        SET QTRESERV    = GREATEST(((NVL(QTRESERV, 0) + NVL(:OLD.QT, 0)) - NVL(:NEW.QT, 0)), 0),
                            DTULTMOVSAI = TRUNC(SYSDATE)
                      WHERE NUMLOTE = :NEW.NUMLOTE
                        AND CODPROD = :NEW.CODPROD
                        AND CODFILIAL = (CASE /*HUGO AQUINO*/
                             WHEN ((:NEW.CODOPER IN ('S') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :NEW.CODOPER IN ('ED')) THEN
                             DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :NEW.CODFILIAL, NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                             WHEN VNCONDVENDA = 10 THEN
                             NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                             ELSE
                             NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
                   EXCEPTION
                     WHEN OTHERS THEN
                       RAISE_APPLICATION_ERROR(-20002,
                                               'ERRO: Não foi possível atualizar o estoque reservado do LOTE - ' ||
                                               SQLERRM);
                   END;
                 END IF;

                 IF (:NEW.CODOPER = 'SC') THEN
                   BEGIN

                     SELECT COUNT(1)
                       INTO VNEXISTELOTECLI
                       FROM PCLOTECLI T
                      WHERE T.CODCLI = :NEW.CODCLI
                        AND T.CODPROD = :NEW.CODPROD
                        AND T.NUMLOTE = :NEW.NUMLOTE;

                     IF (VNEXISTELOTECLI) > 0 THEN
                       UPDATE PCLOTECLI
                          SET QTLOTE = NVL(QTLOTE, 0) +
                                       (NVL(:NEW.QT, 0) - NVL(:OLD.QT, 0))
                        WHERE CODCLI = :NEW.CODCLI
                          AND CODPROD = :NEW.CODPROD
                          AND NUMLOTE = :NEW.NUMLOTE;
                       /*2350.061224.2015
                       UPDATE PCESTCLI
                          SET QTESTGER = QTESTGER +
                                         (NVL(:NEW.QT, 0) - NVL(:OLD.QT, 0))
                        WHERE CODCLI = :NEW.CODCLI
                          AND CODPROD = :NEW.CODPROD;*/
                     ELSE
                       INSERT INTO PCLOTECLI
                         (CODCLI, CODPROD, NUMLOTE, QTLOTE)
                       VALUES
                         (:NEW.CODCLI,
                          :NEW.CODPROD,
                          :NEW.NUMLOTE,
                          NVL(:NEW.QT, 0));
                     END IF;

                   EXCEPTION
                     WHEN OTHERS THEN
                       RAISE_APPLICATION_ERROR(-20009,
                                               'ERRO: AO ATUALIZAR O LOTE CONSIGNADO (PCLOTECLI)- ' ||
                                               SQLERRM);
                   END;
                 END IF;

               EXCEPTION
                 WHEN OTHERS THEN
                   RAISE_APPLICATION_ERROR(-20002,
                                           'ERRO AO ATUALIZAR O LOTE - ' ||
                                           SQLERRM);
               END;

               ----- ENTRADA -----
             ELSIF SUBSTR(:NEW.CODOPER, 1, 1) = 'E' THEN
               BEGIN
                 UPDATE PCLOTE
                    SET QT          = (NVL(QT, 0) - NVL(:OLD.QT, 0)) + NVL(:NEW.QT, 0),
                        QTEST       = (NVL(QTEST, 0) - NVL(:OLD.QTCONT, 0)) + NVL(:NEW.QTCONT, 0),
                        QTBLOQUEADA = GREATEST( GREATEST(((NVL(QTBLOQUEADA, 0) - NVL(:OLD.QTBLOQUEADA, 0)) + NVL(:NEW.QTBLOQUEADA, 0)), 0), GREATEST(((NVL(QTINDENIZ, 0) - NVL(:OLD.QTAVARIA, 0)) + NVL(:NEW.QTAVARIA, 0)), 0) ),
                        QTINDENIZ   = GREATEST(((NVL(QTINDENIZ, 0) - NVL(:OLD.QTAVARIA, 0)) + NVL(:NEW.QTAVARIA, 0)), 0),
                        QTINDUSTRIA = GREATEST(((NVL(QTINDUSTRIA, 0) - NVL(:OLD.QTINDUSTRIA, 0))), 0)
                  WHERE NUMLOTE = :NEW.NUMLOTE
                    AND CODPROD = :NEW.CODPROD
                    AND CODFILIAL = (CASE /*HUGO AQUINO*/
                         WHEN ((:NEW.CODOPER IN ('S') AND NVL(:NEW.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :NEW.CODOPER IN ('ED')) THEN
                         DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :NEW.CODFILIAL, NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL))
                         WHEN VNCONDVENDA = 10 THEN
                         NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                         WHEN (:NEW.CODOPER IN ('EN') AND NVL(:NEW.QT, 0) <> 0) THEN
                            DECODE(VNVOLTAESTOQUEFILIALVIRTUAL,
                                 'N',
                                 NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL),
                                 NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL))
                         ELSE
                         NVL(:NEW.CODFILIALRETIRA, :NEW.CODFILIAL) END);
               EXCEPTION
                 WHEN OTHERS THEN
                   RAISE_APPLICATION_ERROR(-20003,
                                           'ERRO AO ATUALIZAR O LOTE - ' ||
                                           SQLERRM);
               END;
             ELSE
               RAISE_APPLICATION_ERROR(-20004,
                                       'CODIGO DE OPERACAO INVALIDO - ' ||
                                       SQLERRM);
             END IF;

             IF (:NEW.CODOPER = 'EN') THEN
               --IMPLEMENTADA PARA RETORNOR O LOTE NA DEVOLUÇÃO DE VENDA CONSIGNADA.
               BEGIN

                 SELECT COUNT(1)
                   INTO VNEXISTELOTECLI
                   FROM PCLOTECLI T
                  WHERE T.CODCLI = :NEW.CODCLI
                    AND T.CODPROD = :NEW.CODPROD
                    AND T.NUMLOTE = :NEW.NUMLOTE;

                 IF (VNEXISTELOTECLI) > 0 THEN
                   UPDATE PCLOTECLI
                      SET QTLOTE = NVL(QTLOTE, 0) - (NVL(:NEW.QT, 0) - NVL(:OLD.QT, 0))
                    WHERE CODCLI = :NEW.CODCLI
                      AND CODPROD = :NEW.CODPROD
                      AND NUMLOTE = :NEW.NUMLOTE;
                   /*2350.061224.2015
                   UPDATE PCESTCLI
                      SET QTESTGER = QTESTGER -
                                     (NVL(:NEW.QT, 0) - NVL(:OLD.QT, 0))
                    WHERE CODCLI = :NEW.CODCLI
                      AND CODPROD = :NEW.CODPROD;*/
                 END IF;

               EXCEPTION
                 WHEN OTHERS THEN
                   RAISE_APPLICATION_ERROR(-20009,
                                           'ERRO: Ao atualizar o lote consignado (pclotecli) - ' ||
                                           SQLERRM);
               END;
             END IF;

           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               RAISE_APPLICATION_ERROR(-20005,
                                       'ERRO: LOTE DO PRODUTO NAO EXISTE !');
             WHEN OTHERS THEN
               RAISE_APPLICATION_ERROR(-20006,
                                       'ERRO AO PESQUISAR O LOTE ! - ' ||
                                       SQLERRM);
           END;
        END IF;

        ----------------------------------------- CASO ESTEJA DELETANDO OS DADOS --------------------------------------------
        IF (DELETING) AND ((VNNUMNOTACONSIG = 0)) THEN

          IF VSESTOQUEPORLOTE = 'S' THEN
            IF :OLD.NUMLOTE IS NULL THEN
              RAISE_APPLICATION_ERROR(-20001,
                                      'ERRO: LOTE E OBRIGATORIO NO ITEM !');
            END IF;

            BEGIN
              ----- SAÍDA -----
              IF SUBSTR(:OLD.CODOPER, 1, 1) IN ('S', 'R') THEN
                BEGIN
                  UPDATE PCLOTE
                     SET QT          = NVL(QT, 0) + NVL(:OLD.QT, 0),
                         QTEST       = NVL(QTEST, 0) + NVL(:OLD.QTCONT, 0),
                         QTBLOQUEADA = GREATEST( GREATEST((NVL(QTBLOQUEADA, 0) + NVL(:OLD.QTBLOQUEADA, 0)), 0), GREATEST((NVL(QTINDENIZ, 0) + NVL(:OLD.QTAVARIA, 0)), 0) ),
                         QTINDENIZ   = GREATEST((NVL(QTINDENIZ, 0) + NVL(:OLD.QTAVARIA, 0)), 0),
                         QTINDUSTRIA = GREATEST((NVL(QTINDUSTRIA, 0) + NVL(:OLD.QTINDUSTRIA, 0)), 0)
                   WHERE NUMLOTE = :OLD.NUMLOTE
                     AND CODPROD = :OLD.CODPROD
                     AND CODFILIAL = (CASE /*HUGO AQUINO*/
                          WHEN ((:OLD.CODOPER IN ('S') AND NVL(:OLD.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :OLD.CODOPER IN ('ED')) THEN
                          DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :OLD.CODFILIAL, NVL(:OLD.CODFILIALRETIRA, :OLD.CODFILIAL))
                          WHEN VNCONDVENDA = 10 THEN
                          NVL(:OLD.CODFILIALNF, :OLD.CODFILIAL)
                          ELSE
                          NVL(:OLD.CODFILIALRETIRA, :OLD.CODFILIAL) END);

                  IF (((:OLD.CODOPER IN ('S', 'SB', 'ST', 'SC', 'SP', 'RA')) AND
                     ((NVL(:OLD.NUMPED, 0) <> 0) OR
                     (NVL(:OLD.NUMOP, 0) <> 0) OR
                     (NVL(:OLD.NUMTRANSAVULSA, 0) <> 0))) AND
                     (NVL(:OLD.QT, 0) > 0)) THEN
                    BEGIN
                      -- VNNOVAQTRESERV := GREATEST((VNQTRESERV + NVL(:OLD.QT, 0)), 0);

                      UPDATE PCLOTE
                         SET QTRESERV    = GREATEST((NVL(QTRESERV, 0) + NVL(:OLD.QT, 0)), 0),
                             DTULTMOVSAI = TRUNC(SYSDATE)
                       WHERE NUMLOTE = :OLD.NUMLOTE
                         AND CODPROD = :OLD.CODPROD
                         AND CODFILIAL = (CASE /*HUGO AQUINO*/
                              WHEN ((:OLD.CODOPER IN ('S') AND NVL(:OLD.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :OLD.CODOPER IN ('ED')) THEN
                              DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :OLD.CODFILIAL, NVL(:OLD.CODFILIALRETIRA, :OLD.CODFILIAL))
                              WHEN VNCONDVENDA = 10 THEN
                              NVL(:OLD.CODFILIALNF, :OLD.CODFILIAL)
                              ELSE
                              NVL(:OLD.CODFILIALRETIRA, :OLD.CODFILIAL) END);
                    EXCEPTION
                      WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20002,
                                                'ERRO AO ATUALIZAR O LOTE (QTRESERV)- ' ||
                                                SQLERRM);
                    END;
                  END IF;

                  IF (:OLD.CODOPER = 'SC') THEN
                    BEGIN

                      SELECT COUNT(1)
                        INTO VNEXISTELOTECLI
                        FROM PCLOTECLI T
                       WHERE T.CODCLI = :OLD.CODCLI
                         AND T.CODPROD = :OLD.CODPROD
                         AND T.NUMLOTE = :OLD.NUMLOTE;

                      IF (VNEXISTELOTECLI) > 0 THEN
                        UPDATE PCLOTECLI
                           SET QTLOTE = NVL(QTLOTE, 0) - NVL(:OLD.QT, 0)
                         WHERE CODCLI = :OLD.CODCLI
                           AND CODPROD = :OLD.CODPROD
                           AND NUMLOTE = :OLD.NUMLOTE;
                        /*2350.061224.2015
                        UPDATE PCESTCLI
                           SET QTESTGER = QTESTGER - NVL(:OLD.QT, 0)
                         WHERE CODCLI = :OLD.CODCLI
                           AND CODPROD = :OLD.CODPROD;*/
                      END IF;

                    EXCEPTION
                      WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20009,
                                                'ERRO AO ATUALIZAR O LOTE CONSIGNADO (PCLOTECLI)- ' ||
                                                SQLERRM);
                    END;
                  END IF;

                EXCEPTION
                  WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20002,
                                            'ERRO AO ATUALIZAR O LOTE - ' ||
                                            SQLERRM);
                END;

                ----- ENTRADA -----
              ELSIF SUBSTR(:OLD.CODOPER, 1, 1) = 'E' THEN
                BEGIN
                  UPDATE PCLOTE
                     SET QT          = NVL(QT, 0) - NVL(:OLD.QT, 0),
                         QTEST       = NVL(QTEST, 0) - NVL(:OLD.QTCONT, 0),
                         QTBLOQUEADA = GREATEST( GREATEST((NVL(QTBLOQUEADA, 0) - NVL(:OLD.QTBLOQUEADA, 0)), 0), GREATEST((NVL(QTINDENIZ, 0) - NVL(:OLD.QTAVARIA, 0)), 0) ),
                         QTINDENIZ   = GREATEST((NVL(QTINDENIZ, 0) - NVL(:OLD.QTAVARIA, 0)), 0),
                         QTINDUSTRIA = GREATEST((NVL(QTINDUSTRIA, 0) - NVL(:OLD.QTINDUSTRIA, 0)), 0)
                   WHERE NUMLOTE = :OLD.NUMLOTE
                     AND CODPROD = :OLD.CODPROD
                     AND CODFILIAL = (CASE /*HUGO AQUINO*/
                          WHEN ((:OLD.CODOPER IN ('S') AND NVL(:OLD.QT, 0) < 0 AND VNTRANSFERENCIASAIDA > 0) OR :OLD.CODOPER IN ('ED')) THEN
                          DECODE(VNVOLTAESTOQUEFILIALRETIRA, 'N', :OLD.CODFILIAL, NVL(:OLD.CODFILIALRETIRA, :OLD.CODFILIAL))
                          WHEN VNCONDVENDA = 10 THEN
                          NVL(:OLD.CODFILIALNF, :OLD.CODFILIAL)
                          ELSE
                          NVL(:OLD.CODFILIALRETIRA, :OLD.CODFILIAL) END);
                EXCEPTION
                  WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20003,
                                            'ERRO AO ATUALIZAR O LOTE - ' ||
                                            SQLERRM);
                END;
              ELSE
                RAISE_APPLICATION_ERROR(-20004,
                                        'CODIGO DE OPERACAO INVALIDO - ' ||
                                        SQLERRM);
              END IF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20005,
                                        'ERRO: LOTE DO PRODUTO NAO EXISTE !');
              WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20006,
                                        'ERRO AO PESQUISAR O LOTE ! - ' ||
                                        SQLERRM);
            END;
          END IF;
        END IF;
      END IF;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20007, 'ERRO: PRODUTO NAO CADASTRADO !');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20008,'ERRO AO PESQUISAR O PRODUTO ! - ' || SQLERRM);
  END;
END TRG_ATUALIZA_PCLOTE;
