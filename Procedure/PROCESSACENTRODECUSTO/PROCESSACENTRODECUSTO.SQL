CREATE OR REPLACE PROCEDURE PROCESSACENTRODECUSTO (
    p_codFilial   IN VARCHAR2,
    p_codConta    IN VARCHAR2,
    p_tlLancto    IN VARCHAR2,
    p_numeroLancamento IN NUMBER
) AS
  -- Variáveis Locais
  v_utilizaCentroCusto_2663 VARCHAR2(1);
  v_contaTrabalhaCentroCusto VARCHAR2(1);
  v_valorLancamento NUMBER(12,2);
  v_totalRateado NUMBER(12,2);
  v_diferenca NUMBER(12,2);

  CURSOR curCentrosCusto IS
    SELECT NVL(CO.CODIGOCENTROCUSTO, CO.CODCENTROCUSTO) CODIGOCENTROCUSTO,
           CC.DESCRICAO DESCCENTROCUSTO,
           CO.PERCRATEIO
    FROM PCCONTACENTROCUSTO CO
         JOIN PCCENTROCUSTO CC
         ON NVL(CO.CODIGOCENTROCUSTO, CO.CODCENTROCUSTO) = NVL(CC.CODIGOCENTROCUSTO, CC.CODCENTROCUSTO)
    WHERE CO.CODCONTA = p_codConta
      AND NVL(CC.ATIVO, 'S') = 'S'
      AND NVL(CC.RECEBE_LANCTO, 'S') = 'S'
    ORDER BY NVL(CO.CODIGOCENTROCUSTO, CO.CODCENTROCUSTO);

  FUNCTION ContaTrabalhaCentroCusto (
    p_codFilial IN VARCHAR2,
    p_codConta  IN VARCHAR2
  ) RETURN VARCHAR2 IS
    v_utilizaCentroCusto_2663 VARCHAR2(1);
    v_contaTrabalha VARCHAR2(1);
  BEGIN
    IF p_codFilial IS NULL OR p_codConta IS NULL THEN
      RETURN 'N';
    END IF;

    BEGIN
      SELECT NVL(VALOR, 'N')
      INTO v_utilizaCentroCusto_2663
      FROM PCPARAMFILIAL
      WHERE CODFILIAL = '1';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_utilizaCentroCusto_2663 := 'N';
    END;

    IF v_utilizaCentroCusto_2663 = 'N' THEN
      RETURN 'N';
    END IF;

    SELECT DECODE(COUNT(1), 0, 'N', 'S')
    INTO v_contaTrabalha
    FROM PCCONTA
    WHERE NVL(USARATEIOCENTROCUSTO, 'N') = 'S'
      AND CODCONTA = p_codConta;

    RETURN v_contaTrabalha;
  END;

BEGIN
  -- Verifica se a conta trabalha com centro de custo
  v_contaTrabalhaCentroCusto := ContaTrabalhaCentroCusto(p_codFilial, p_codConta);

  --Se a conta Trabalha com centro de custo e o tipo de Lançamento é Financeiro, continua no processamento
  IF (v_contaTrabalhaCentroCusto = 'S') AND (p_tlLancto = 'FINANCEIRO') THEN
    SELECT VALOR INTO v_valorLancamento FROM PCLANC WHERE RECNUM = p_numeroLancamento;
    v_totalRateado := 0;

    FOR rec IN curCentrosCusto LOOP
      INSERT INTO PCRATEIOCENTROCUSTO (
        CODFILIAL, CODCONTA, VALOR, PERCRATEIO, DTLANC, CODIGOCENTROCUSTO, CONTRAPARTIDA, RECNUM
      ) VALUES (
        p_codFilial, p_codConta, (v_valorLancamento * (rec.PERCRATEIO / 100)), rec.PERCRATEIO, SYSDATE, rec.CODIGOCENTROCUSTO, 'N', p_numeroLancamento
      );

      v_totalRateado := v_totalRateado + (v_valorLancamento * (rec.PERCRATEIO / 100));
    END LOOP;

    -- Calcula diferença do lançamento com a soma dos valores rateados e atualiza o último registro
    v_diferenca := v_valorLancamento - v_totalRateado;

    IF v_diferenca <> 0 THEN
      UPDATE PCRATEIOCENTROCUSTO
      SET VALOR = VALOR + v_diferenca
      WHERE RECNUM = p_numeroLancamento
        AND ROWNUM = 1
        AND CODIGOCENTROCUSTO = (
          SELECT CODIGOCENTROCUSTO FROM (
            SELECT CODIGOCENTROCUSTO
            FROM PCRATEIOCENTROCUSTO
            WHERE RECNUM = p_numeroLancamento
            ORDER BY DTLANC DESC
          ) WHERE ROWNUM = 1
        );
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro ao processar centro de custo: ' || SQLERRM);
END PROCESSACENTRODECUSTO;
