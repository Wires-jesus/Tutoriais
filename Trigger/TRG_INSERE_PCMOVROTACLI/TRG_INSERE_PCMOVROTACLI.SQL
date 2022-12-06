CREATE OR REPLACE TRIGGER TRG_INSERE_PCMOVROTACLI
   BEFORE INSERT OR UPDATE
   ON PCROTACLI
   REFERENCING OLD AS OLD NEW AS NEW
   FOR EACH ROW


/*********************************************************************************************************************
                         Historico de Alteracoes
----------------------------------------------------------------------------------------------------------------------
  Data         Responsavel    Tarefa    Alteracao
------------  -------------  --------  -------------------------------------------------------------------------------
 25/04/2012    Luciano        158671    Replicar registros da tabela PCROTACLI para a tabela PCMOVROTACLI
 23/05/2012    Luciano        158671    Alteracao para considerar filial 99, conforme solicitado.
 03/07/2013    Unilson        203802    Alteracao para verificar se o registro alterado na PCROTACLI pelo usuario,
                                          via rotina 354, foi ou nao atualizado por importacao de registros do forca
                                          de vendas ou se a visita ainda nao foi realizada.
 08/10/2015    Fabrício Lima  HIS.01774.2015    Trigger não valida mais o parâmetro "Atualiza rota na venda"
 21/10/2015    Leandro Bastos 1378.118423.2015  Trigger tentava inserir na PCMOVROTACLI m registro já existente, violando a chave
 19/07/2016    Deyvid Costa   0.079908.2016  Refatorado a trigger para melhor validação e entendimento. Correção da gravação do campo PCMOVROTACLI.DTPROXVISITA
**********************************************************************************************************************/

DECLARE
  vUTILIZAROTEIRIZACAO VARCHAR2(1);
  --  vATUALIZAROTANOMOMENTOVENDA VARCHAR2(1);
  vCODROTA           NUMBER(13);
  vnCOUNT            NUMBER(2);
  vnCODROTA          PCMOVROTACLI.CODROTA%TYPE;
  VDDTPROXVISITAANT  DATE;
  VDDTPROXVISITANOVA DATE;
  ROWPCMOVROTACLI    PCMOVROTACLI%ROWTYPE;

  -- Deyvid Costa - Preenche o rowtype PCMOVROTACLI com os novos dados comuns entre o insert e o update
  PROCEDURE PREENCHEROWTYPE IS
  BEGIN
    ROWPCMOVROTACLI.CODUSUR       := :NEW.CODUSUR;
    ROWPCMOVROTACLI.DIASEMANA     := :NEW.DIASEMANA;
    ROWPCMOVROTACLI.CODCLI        := :NEW.CODCLI;
    ROWPCMOVROTACLI.SEQUENCIA     := :NEW.SEQUENCIA;
    ROWPCMOVROTACLI.PERIODICIDADE := :NEW.PERIODICIDADE;
    ROWPCMOVROTACLI.NUMSEMANA     := :NEW.NUMSEMANA;
    ROWPCMOVROTACLI.VLMETAVENDA   := :NEW.VLMETAVENDA;
    ROWPCMOVROTACLI.OBS           := :NEW.OBS;
    ROWPCMOVROTACLI.CICLOVISITA   := :NEW.CICLOVISITA;
    ROWPCMOVROTACLI.HORAVISITA    := :NEW.HORAVISITA;
    ROWPCMOVROTACLI.MINUTOVISITA  := :NEW.MINUTOVISITA;
    ROWPCMOVROTACLI.SEQ1          := :NEW.SEQ1;
    ROWPCMOVROTACLI.SEQ2          := :NEW.SEQ2;
    ROWPCMOVROTACLI.SEQ3          := :NEW.SEQ3;
    ROWPCMOVROTACLI.DATAREF       := :NEW.DATAREF;
    ROWPCMOVROTACLI.NUMZONA       := :NEW.NUMZONA;
    ROWPCMOVROTACLI.DTFINAL       := :NEW.DTFINAL;
    ROWPCMOVROTACLI.DTINICIO      := :NEW.DTINICIO;
  END;

BEGIN
  ---------- INÍCIO ----------
  VDDTPROXVISITAANT  := NVL(:OLD.DTPROXVISITA, TRUNC(SYSDATE));
  VDDTPROXVISITANOVA := NVL(TRUNC(:NEW.DTPROXVISITA), TRUNC(SYSDATE));
  --

  BEGIN
    SELECT NVL(VALOR, 'S')
      INTO vUTILIZAROTEIRIZACAO
      FROM PCPARAMFILIAL
     WHERE NOME = 'UTILIZAROTEIRIZACAO'
       AND CODFILIAL = '99'
       AND ROWNUM = 1;
  EXCEPTION
    WHEN OTHERS THEN
      vUTILIZAROTEIRIZACAO := 'S';
  END;

  IF vUTILIZAROTEIRIZACAO = 'S' THEN
    BEGIN
      SELECT CODROTA, COUNT(*)
        INTO vnCODROTA, vnCOUNT
        FROM PCMOVROTACLI
       WHERE CODUSUR = :NEW.CODUSUR
         AND DIASEMANA = :NEW.DIASEMANA
         AND CODCLI = :NEW.CODCLI
         AND NUMSEMANA = :NEW.NUMSEMANA
         AND DTVISITAPROG = :NEW.DTPROXVISITA
            --AND DTPEDIDO IS NULL   -- 1378.118423.2015
            --AND DTJUSTIFIC IS NULL -- 1378.118423.2015
         AND ROWNUM = 1
       GROUP BY CODROTA;
    EXCEPTION
      WHEN OTHERS THEN
        vnCOUNT := 0;
    END;

    IF vnCOUNT > 0 THEN
      SELECT R.*
        INTO ROWPCMOVROTACLI
        FROM PCMOVROTACLI R
       WHERE CODROTA = vnCODROTA
         AND ROWNUM = 1;
      ----------------
      PREENCHEROWTYPE;
      ----------------
      ROWPCMOVROTACLI.CODROTA      := vnCODROTA;


        BEGIN
          SELECT COUNT(*)
            INTO vnCOUNT
            FROM PCMOVROTACLI
           WHERE CODUSUR = ROWPCMOVROTACLI.CODUSUR
             AND DIASEMANA = ROWPCMOVROTACLI.DIASEMANA
             AND CODCLI = ROWPCMOVROTACLI.CODCLI
             AND NUMSEMANA = ROWPCMOVROTACLI.NUMSEMANA
             AND DTVISITAPROG = VDDTPROXVISITAANT -- DATA ANTERIOR
             AND ROWNUM = 1
           GROUP BY CODROTA;
        EXCEPTION
          WHEN OTHERS THEN
            vnCOUNT := 0;
        END;

      IF vnCOUNT = 0 THEN
         ROWPCMOVROTACLI.DTVISITAPROG := VDDTPROXVISITAANT;
      END IF;

      IF TRUNC(VDDTPROXVISITAANT) <> TRUNC(VDDTPROXVISITANOVA) THEN
--        ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITAANT;
        ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITANOVA;
        ROWPCMOVROTACLI.DTVISITAPROG := VDDTPROXVISITANOVA;
      END IF;
      -----------------------------------------------
      BEGIN
        UPDATE PCMOVROTACLI
           SET ROW = ROWPCMOVROTACLI
         WHERE CODROTA = vnCODROTA;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  ' CODUSUR = ' || ROWPCMOVROTACLI.CODUSUR ||
                                  CHR(13) || ' DIASEMANA = ' ||
                                  ROWPCMOVROTACLI.DIASEMANA || CHR(13) ||
                                  ' CODCLI = ' || ROWPCMOVROTACLI.CODCLI ||
                                  CHR(13) || ' NUMSEMANA = ' ||
                                  ROWPCMOVROTACLI.NUMSEMANA || CHR(13) ||
                                  ' DTVISITAPROG = ' ||
                                  ROWPCMOVROTACLI.DTVISITAPROG);
      END;
      -----------------------------------------------
    ELSE
      -- SE NÃO ENCONTRAR REGISTRO NA PCMOVROTACLI
      ----------------
      PREENCHEROWTYPE;
      ----------------
      ROWPCMOVROTACLI.DTVISITAPROG := VDDTPROXVISITAANT; --:NEW.DTPROXVISITA;

      IF TRUNC(VDDTPROXVISITAANT) <> TRUNC(VDDTPROXVISITANOVA) THEN
        ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITANOVA;
--        ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITAANT;
        /*      ELSE
        IF INSERTING THEN
           ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITANOVA;
        END IF;     */
      END IF;

      IF ROWPCMOVROTACLI.DTPROXVISITA IS NULL THEN
        ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITANOVA;
        ROWPCMOVROTACLI.DTVISITAPROG := VDDTPROXVISITANOVA;
--        ROWPCMOVROTACLI.DTPROXVISITA := VDDTPROXVISITANOVA;
      END IF;

      BEGIN
        SELECT CODROTA, COUNT(*)
          INTO vnCODROTA, vnCOUNT
          FROM PCMOVROTACLI
         WHERE CODUSUR = ROWPCMOVROTACLI.CODUSUR
           AND DIASEMANA = ROWPCMOVROTACLI.DIASEMANA
           AND CODCLI = ROWPCMOVROTACLI.CODCLI
           AND NUMSEMANA = ROWPCMOVROTACLI.NUMSEMANA
           AND DTVISITAPROG = ROWPCMOVROTACLI.DTVISITAPROG
           AND ROWNUM = 1
         GROUP BY CODROTA;
      EXCEPTION
        WHEN OTHERS THEN
          vnCOUNT := 0;
      END;

      BEGIN
        IF vnCOUNT > 0 THEN
          ------------------------------------------------
          ROWPCMOVROTACLI.NUMSEMANA := ROWPCMOVROTACLI.NUMSEMANA || 00 ||
                                    ROUND((DBMS_RANDOM.VALUE(1, 2)), 2);
          UPDATE PCMOVROTACLI
             SET CODUSUR      = ROWPCMOVROTACLI.CODUSUR * -1,
                 DIASEMANA    = ROWPCMOVROTACLI.DIASEMANA,
                 CODCLI       = ROWPCMOVROTACLI.CODCLI * -1,
                 NUMSEMANA    = ROWPCMOVROTACLI.NUMSEMANA,
                 DTVISITAPROG = ROWPCMOVROTACLI.DTVISITAPROG
           WHERE CODROTA = vnCODROTA;
          ------------------------------------------------

          SELECT DFSEQ_PCMOVROTACLI.NEXTVAL INTO vCODROTA FROM DUAL;
          ROWPCMOVROTACLI.CODROTA := vCODROTA;
          ------------------------------------------------
          INSERT INTO PCMOVROTACLI VALUES ROWPCMOVROTACLI;
          ------------------------------------------------
        ELSE
          SELECT DFSEQ_PCMOVROTACLI.NEXTVAL INTO vCODROTA FROM DUAL;
          ROWPCMOVROTACLI.CODROTA := vCODROTA;
          ------------------------------------------------
          INSERT INTO PCMOVROTACLI VALUES ROWPCMOVROTACLI;
          ------------------------------------------------

        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  ' CODUSUR = ' || ROWPCMOVROTACLI.CODUSUR ||
                                  CHR(13) || ' DIASEMANA = ' ||
                                  ROWPCMOVROTACLI.DIASEMANA || CHR(13) ||
                                  ' CODCLI = ' || ROWPCMOVROTACLI.CODCLI ||
                                  CHR(13) || ' NUMSEMANA = ' ||
                                  ROWPCMOVROTACLI.NUMSEMANA || CHR(13) ||
                                  ' DTVISITAPROG = ' ||
                                  ROWPCMOVROTACLI.DTVISITAPROG);
      END;

    END IF;

  END IF;

END;

