CREATE OR REPLACE TRIGGER TRG_INATIVACAOPCEMBALAGEM_C5 BEFORE
  INSERT OR UPDATE ON PCEMBALAGEM REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE
  VSEQPRODUTO PCDEPARAEMBALAGENSC5.SEQPRODUTO%TYPE;
BEGIN
  IF FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USAINTEGRACAOCONSINCO', :OLD.CODFILIAL, 'N') = 'S' THEN
    BEGIN
      SELECT
        SEQPRODUTO INTO VSEQPRODUTO
      FROM
        PCDEPARAEMBALAGENSC5
      WHERE
        CODAUXILIAR = :OLD.CODAUXILIAR;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
        VSEQPRODUTO := NULL;
    END;

    IF VSEQPRODUTO IS NOT NULL THEN
      IF (NVL(:NEW.QTUNIT, 0) <> NVL(:OLD.QTUNIT, 0)) THEN
        MERGE INTO PCINATIVACAOEMBALAGEMC5 P USING (
            SELECT
              :OLD.CODFILIAL                         NROEMPRESA,
              1                                      NROSEGMENTO,
              VSEQPRODUTO                            SEQPRODUTO,
              LEAST(NVL(:OLD.QTUNIT, 1), 999999.999) QTDEMBALAGEM
            FROM
              DUAL
          ) T 
        ON ( P.NROEMPRESA = T.NROEMPRESA
          AND P.NROSEGMENTO = T.NROSEGMENTO
          AND P.SEQPRODUTO = T.SEQPRODUTO
          AND P.QTDEMBALAGEM = T.QTDEMBALAGEM 
        )
        WHEN NOT MATCHED THEN
          INSERT (
            P.NROEMPRESA,
            P.NROSEGMENTO,
            P.SEQPRODUTO,
            P.QTDEMBALAGEM
          ) VALUES (
            T.NROEMPRESA,
            T.NROSEGMENTO,
            T.SEQPRODUTO,
            T.QTDEMBALAGEM
          );
        END IF;

        IF (NVL(:NEW.QTMINIMAATACADO, 0) <> NVL(:OLD.QTMINIMAATACADO, 0)) THEN
          MERGE INTO PCINATIVACAOEMBALAGEMC5 P 
          USING (
              SELECT
                :OLD.CODFILIAL                                  NROEMPRESA,
                1                                               NROSEGMENTO,
                VSEQPRODUTO                                     SEQPRODUTO,
                LEAST(NVL(:OLD.QTMINIMAATACADO, 1), 999999.999) QTDEMBALAGEM
              FROM
                DUAL
          ) T 
          ON ( P.NROEMPRESA = T.NROEMPRESA
            AND P.NROSEGMENTO = T.NROSEGMENTO
            AND P.SEQPRODUTO = T.SEQPRODUTO
            AND P.QTDEMBALAGEM = T.QTDEMBALAGEM 
          ) 
          WHEN NOT MATCHED THEN
            INSERT (
              P.NROEMPRESA,
              P.NROSEGMENTO,
              P.SEQPRODUTO,
              P.QTDEMBALAGEM
            ) VALUES (
              T.NROEMPRESA,
              T.NROSEGMENTO,
              T.SEQPRODUTO,
              T.QTDEMBALAGEM
            );
          END IF;
        END IF;
      END IF;
    END;