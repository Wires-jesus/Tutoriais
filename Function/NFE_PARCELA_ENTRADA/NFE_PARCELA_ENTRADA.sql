CREATE OR REPLACE FUNCTION NFE_PARCELA_ENTRADA(P_TRANSACAO NUMBER)
  RETURN TABELA_NFE_PARCELA IS

--Antes de aprovar, porque não pode existir a pcparcelanfe (Servidor NFe)
  CURSOR CR_PARCELAS IS
   SELECT NUM_TRANSACAO,
          PRESTACAO,
          DTVENC,
          VALOR,
          CODCOB,
          VALORDESC,
          DUPLICATA,
          NUMPREST,
          CODCOBSEFAZ,
          CNPJ_CRED_CARTAO,
          NUMAUTOR_CARTAO,
          BANDEIRA_CARTAO,
          TP_INTEGRA,
          INDPAG
    FROM (
           SELECT NUM_TRANSACAO,
                  PRESTACAO,
                  DTVENC,
                  VALOR,
                  CODCOB,
                  VALORDESC,
                  NUMNOTA DUPLICATA,
                  DUPLIC NUMPREST,
                  CODCOBSEFAZ,
                  CNPJ_CRED_CARTAO,
                  NUMAUTOR_CARTAO,
                  BANDEIRA_CARTAO,
                  NULL AS TP_INTEGRA,
                  INDPAG
             FROM SQL_NFE_PARCELA_ENTRADA PARCELA
            WHERE PARCELA.NUM_TRANSACAO = P_TRANSACAO
              AND NOT EXISTS (SELECT 1
                                FROM PCLANCNF
                               WHERE PCLANCNF.NUMTRANSENT = P_TRANSACAO)
               
         UNION
         --nova tabela gravada pelo compras
           SELECT P.NUMTRANSENT NUM_TRANSACAO,
                  TO_CHAR(P.NUMNOTA) || ' - ' || TO_CHAR(P.DUPLIC) PRESTACAO,
                  P.DTVENC DTVENC,
                  P.VALOR VALOR,
                  '' AS CODCOB,
                  0 AS VALORDESC,
                  P.NUMNOTA AS DUPLICATA,
                  P.DUPLIC AS NUMPREST,
                  P.CODCOBSEFAZ AS CODCOBSEFAZ,
                  P.CNPJCREDENCCARTAO AS CNPJ_CRED_CARTAO,
                  P.NSUTEF AS NUMAUTOR_CARTAO,
                  TO_NUMBER(P.BANDEIRACARTAO) AS BANDEIRA_CARTAO,
                  P.TP_INTEGRA AS TP_INTEGRA,
                  NVL(P.INDPAG, 0) AS INDPAG
             FROM PCLANCNF P
            WHERE P.NUMTRANSENT = P_TRANSACAO ) PARCELA       
       
     WHERE NOT EXISTS
      (SELECT 1
               FROM PCPARCELANFE
              WHERE PCPARCELANFE.NUMTRANSACAO = P_TRANSACAO
                AND TO_CHAR(PCPARCELANFE.DUPLIC) || ' - ' ||
                    PCPARCELANFE.PREST = PARCELA.PRESTACAO
                AND NVL(PCPARCELANFE.TIPOMOV, 'X') = 'E');
          
--Depois da nota aprovada, pois necessita de ter a tabela pcparcelanfe gravada (rotina 1452)          
    CURSOR CR_PARCELAS_DANFE IS
      SELECT P.NUMTRANSACAO NUM_TRANSACAO,
              --TO_CHAR(P.DUPLIC) || ' - ' || TO_CHAR(P.PREST) PRESTACAO,
              P.PREST PRESTACAO,
              P.DTVENC DTVENC,
              P.VALOR VALOR,
              (SELECT PCPREST.CODCOB
                 FROM PCPREST
                WHERE PCPREST.NUMTRANSENT = P.NUMTRANSACAO
                  AND PCPREST.PREST = P.PREST
                  AND ROWNUM = 1) CODCOB,
              (SELECT NVL(PCPREST.VALORDESC, 0)
                 FROM PCPREST
                WHERE PCPREST.NUMTRANSENT = P.NUMTRANSACAO
                  AND PCPREST.PREST = P.PREST
                  AND ROWNUM = 1) VALORDESC,
              P.DUPLIC AS DUPLICATA,
              P.PREST AS NUMPREST,
              NULL AS CODCOBSEFAZ,
              NULL AS CNPJ_CRED_CARTAO,
              NULL AS NUMAUTOR_CARTAO,
              NULL AS BANDEIRA_CARTAO,
              NULL AS TP_INTEGRA,
              0 AS INDPAG
         FROM PCPARCELANFE P
        WHERE P.NUMTRANSACAO = P_TRANSACAO
          AND NVL(P.TIPOMOV, 'X') = 'E';          

  RETORNO        TABELA_NFE_PARCELA;
  VENVIACOBRANCA PCFILIAL.ENVIACONTASPAGARNFE%TYPE;
  VTIPODESCARGA  VARCHAR2(1);
  VSITUACAONFE    PCNFENT.SITUACAONFE%TYPE;
BEGIN
  RETORNO := TABELA_NFE_PARCELA();

  SELECT NVL(PCFILIAL.ENVIACONTASPAGARNFE, 'S')
        ,DECODE(PCNFENT.TIPODESCARGA, '6', 'N',
                                        '8', 'N',
                                        'T', 'N', 'S')
        ,NVL(SITUACAONFE, 0)                                
  INTO   VENVIACOBRANCA,
         VTIPODESCARGA,
         VSITUACAONFE
  FROM   PCFILIAL,
         PCNFENT
  WHERE  PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF,
                               PCNFENT.CODFILIAL)
  AND    PCNFENT.NUMTRANSENT = P_TRANSACAO
  AND    ROWNUM = 1;


  IF (VENVIACOBRANCA = 'S') AND (VSITUACAONFE NOT IN (100, 150)) THEN
    FOR PARCELA IN CR_PARCELAS
    LOOP
      RETORNO.EXTEND;

      RETORNO(RETORNO.COUNT) := TIPO_NFE_PARCELA(DTVENC                 => NULL,
                                                 PREST                  => NULL,
                                                 VALOR                  => NULL,
                                                 CODCOB                 => NULL,
                                                 VALORDESC              => NULL,
                                                 DUPLICATA              => NULL,
                                                 NUMPREST               => NULL,
                                                 CODCOBSEFAZ            => NULL,
                                                 CNPJ_CRED_CARTAO       => NULL,
                                                 NUMAUTOR_CARTAO        => NULL,
                                                 BANDEIRA_CARTAO        => NULL,
                                                 TP_INTEGRA             => NULL,
                                                 DATACONSOLIDACAOPREFAT => NULL,
                                                 PREFATURAMENTO         => NULL,
                                                 INDPAG                 => NULL
                                                 );

      RETORNO(RETORNO.COUNT).DTVENC    := PARCELA.DTVENC;
      RETORNO(RETORNO.COUNT).PREST     := PARCELA.PRESTACAO;
      RETORNO(RETORNO.COUNT).VALOR     := PARCELA.VALOR;
      RETORNO(RETORNO.COUNT).CODCOB    := PARCELA.CODCOB;
      RETORNO(RETORNO.COUNT).VALORDESC := PARCELA.VALORDESC;
      RETORNO(RETORNO.COUNT).DUPLICATA := PARCELA.DUPLICATA;
      RETORNO(RETORNO.COUNT).NUMPREST  := PARCELA.NUMPREST;
      RETORNO(RETORNO.COUNT).CODCOBSEFAZ      := PARCELA.CODCOBSEFAZ;
      RETORNO(RETORNO.COUNT).CNPJ_CRED_CARTAO := PARCELA.CNPJ_CRED_CARTAO;
      RETORNO(RETORNO.COUNT).NUMAUTOR_CARTAO  := PARCELA.NUMAUTOR_CARTAO;
      RETORNO(RETORNO.COUNT).BANDEIRA_CARTAO  := PARCELA.BANDEIRA_CARTAO;
      RETORNO(RETORNO.COUNT).TP_INTEGRA       := PARCELA.TP_INTEGRA;
      RETORNO(RETORNO.COUNT).INDPAG           := PARCELA.INDPAG;

    END LOOP;

  ELSIF VSITUACAONFE IN (100, 150) THEN
    FOR PARCELA IN CR_PARCELAS_DANFE
    LOOP
      RETORNO.EXTEND;

      RETORNO(RETORNO.COUNT) := TIPO_NFE_PARCELA(DTVENC                 => NULL,
                                                 PREST                  => NULL,
                                                 VALOR                  => NULL,
                                                 CODCOB                 => NULL,
                                                 VALORDESC              => NULL,
                                                 DUPLICATA              => NULL,
                                                 NUMPREST               => NULL,
                                                 CODCOBSEFAZ            => NULL,
                                                 CNPJ_CRED_CARTAO       => NULL,
                                                 NUMAUTOR_CARTAO        => NULL,
                                                 BANDEIRA_CARTAO        => NULL,
                                                 TP_INTEGRA             => NULL,
                                                 DATACONSOLIDACAOPREFAT => NULL,
                                                 PREFATURAMENTO         => NULL,
                                                 INDPAG                 => NULL
                                                 );

      RETORNO(RETORNO.COUNT).DTVENC    := PARCELA.DTVENC;
      RETORNO(RETORNO.COUNT).PREST     := PARCELA.PRESTACAO;
      RETORNO(RETORNO.COUNT).VALOR     := PARCELA.VALOR;
      RETORNO(RETORNO.COUNT).CODCOB    := PARCELA.CODCOB;
      RETORNO(RETORNO.COUNT).VALORDESC := PARCELA.VALORDESC;
      RETORNO(RETORNO.COUNT).DUPLICATA := PARCELA.DUPLICATA;
      RETORNO(RETORNO.COUNT).NUMPREST  := PARCELA.NUMPREST;
      RETORNO(RETORNO.COUNT).CODCOBSEFAZ      := PARCELA.CODCOBSEFAZ;
      RETORNO(RETORNO.COUNT).CNPJ_CRED_CARTAO := PARCELA.CNPJ_CRED_CARTAO;
      RETORNO(RETORNO.COUNT).NUMAUTOR_CARTAO  := PARCELA.NUMAUTOR_CARTAO;
      RETORNO(RETORNO.COUNT).BANDEIRA_CARTAO  := PARCELA.BANDEIRA_CARTAO;
      RETORNO(RETORNO.COUNT).TP_INTEGRA       := PARCELA.TP_INTEGRA;
      RETORNO(RETORNO.COUNT).INDPAG           := PARCELA.INDPAG;
      END LOOP;

  END IF;
  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END; 