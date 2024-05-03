CREATE OR REPLACE FUNCTION NFE_PARCELA_SAIDA(P_TRANSACAO NUMBER)
  RETURN TABELA_NFE_PARCELA IS
  CURSOR CR_PARCELAS(PC_TRANSACAO NUMBER) IS
    SELECT NUM_TRANSACAO,
           PRESTACAO,
           DTVENC,
           VALOR,
           CODCOB,
           NVL(VALORDESC, 0) VALORDESC,
           DUPLICATA,
           NUMPREST,
           CODCOBSEFAZ,
           CNPJ_CRED_CARTAO,
           NUMAUTOR_CARTAO,
           BANDEIRA_CARTAO,
           TP_INTEGRA,
           DATACONSOLIDACAOPREFAT,
           PREFATURAMENTO,
           INDPAG,
		   CNPJPAG,
		   UFPAG,
		   CNPJRECEB,
		   IDTERMPAG
      FROM ( ------Esta primeira parte do union serve para as notas que estão sendo aprovadas (ainda não existe pcparcelanfe)
            --Estes select leem as prestações da pcprest, inclusive a de ST
            SELECT *
              FROM (SELECT NUM_TRANSACAO,
                            PRESTACAO,
                            DTVENC,
                            VALOR,
                            CODCOB,
                            VALORDESC,
                            TO_CHAR(DUPLIC) DUPLICATA,
                            PREST NUMPREST,
                            CODCOBSEFAZ,
                            CNPJ_CRED_CARTAO,
                            NUMAUTOR_CARTAO,
                            BANDEIRA_CARTAO,
                            TP_INTEGRA,
                            DATACONSOLIDACAOPREFAT,
                            PREFATURAMENTO,
                            INDPAG,
				            CNPJPAG,
				            UFPAG,
				            CNPJRECEB,
				            IDTERMPAG
                       FROM SQL_NFE_PARCELA_SAIDA_NORMAL
                      WHERE NUM_TRANSACAO = PC_TRANSACAO
                     UNION ALL
                     SELECT NUM_TRANSACAO,
                            PRESTACAO,
                            DTVENC,
                            VALOR,
                            CODCOB,
                            VALORDESC,
                            TO_CHAR(DUPLIC) DUPLICATA,
                            PREST NUMPREST,
                            CODCOBSEFAZ,
                            CNPJ_CRED_CARTAO,
                            NUMAUTOR_CARTAO,
                            BANDEIRA_CARTAO,
                            TP_INTEGRA,
                            DATACONSOLIDACAOPREFAT,
                            PREFATURAMENTO,
                            INDPAG,
				            CNPJPAG,
				            UFPAG,
				            CNPJRECEB,
				            IDTERMPAG
                       FROM SQL_NFE_PARCELA_SAIDA_ST
                      WHERE NUM_TRANSACAO = PC_TRANSACAO
                     UNION
                     SELECT NUM_TRANSACAO,
                            PRESTACAO,
                            DTVENC,
                            VALOR,
                            CODCOB,
                            VALORDESC,
                            TO_CHAR(DUPLIC) DUPLICATA,
                            PREST NUMPREST,
                            CODCOBSEFAZ,
                            CNPJ_CRED_CARTAO,
                            NUMAUTOR_CARTAO,
                            BANDEIRA_CARTAO,
                            TP_INTEGRA,
                            DATACONSOLIDACAOPREFAT,
                            PREFATURAMENTO,
                            INDPAG,
				            CNPJPAG,
				            UFPAG,
				            CNPJRECEB,
				            IDTERMPAG
                       FROM SQL_NFE_PARCELA_SAIDA_DIN
                      WHERE NUM_TRANSACAO = PC_TRANSACAO
                     UNION
                     SELECT NUM_TRANSACAO,
                            PRESTACAO,
                            DTVENC,
                            VALOR,
                            CODCOB,
                            VALORDESC,
                            TO_CHAR(DUPLIC) DUPLICATA,
                            PREST NUMPREST,
                            CODCOBSEFAZ,
                            CNPJ_CRED_CARTAO,
                            NUMAUTOR_CARTAO,
                            BANDEIRA_CARTAO,
                            TP_INTEGRA,
                            DATACONSOLIDACAOPREFAT,
                            PREFATURAMENTO,
                            INDPAG,
				            CNPJPAG,
				            UFPAG,
				            CNPJRECEB,
				            IDTERMPAG
                       FROM SQL_NFE_PARCELA_SAIDA_TROCO
                      WHERE NUM_TRANSACAO = PC_TRANSACAO
                     UNION
                     SELECT NUM_TRANSACAO,
                            PRESTACAO,
                            DTVENC,
                            VALOR,
                            CODCOB,
                            VALORDESC,
                            TO_CHAR(DUPLIC) DUPLICATA,
                            PREST NUMPREST,
                            CODCOBSEFAZ,
                            CNPJ_CRED_CARTAO,
                            NUMAUTOR_CARTAO,
                            BANDEIRA_CARTAO,
                            TP_INTEGRA,
                            DATACONSOLIDACAOPREFAT,
                            PREFATURAMENTO,
                            INDPAG,
				            CNPJPAG,
				            UFPAG,
				            CNPJRECEB,
				            IDTERMPAG
                       FROM SQL_NFE_PARCELA_SAIDA_CARTAO
                      WHERE NUM_TRANSACAO = PC_TRANSACAO) TITULOS
             WHERE NOT EXISTS (SELECT 1
                                 FROM PCPARCELANFE B, 
                                      PCPREST P,
                                      PCNFSAID S
                                WHERE B.NUMTRANSACAO = P.NUMTRANSVENDA
                                  AND B.PREST = P.PREST
                                  AND S.NUMTRANSVENDA = P.NUMTRANSVENDA
                                  AND S.SITUACAONFE IN (100,150)
                                  AND B.NUMTRANSACAO = PC_TRANSACAO))
     WHERE NOT CODCOB IS NULL
     ORDER BY LPAD(NUMPREST, 3,'0');--antigo DTVENC, PRESTACAO;

  CURSOR CR_PARCELAS_DANFE(PC_TRANSACAO NUMBER) IS
    SELECT NUM_TRANSACAO,
           PRESTACAO,
           DTVENC,
           VALOR,
           CODCOB,
           NVL(VALORDESC, 0) VALORDESC,
           DUPLICATA,
           NUMPREST,
           --NÃO NECESSÁRIO PARA DANFE
           NULL                   AS CODCOBSEFAZ,
           NULL                   AS CNPJ_CRED_CARTAO,
           NULL                   AS NUMAUTOR_CARTAO,
           NULL                   AS BANDEIRA_CARTAO,
           NULL                   AS TP_INTEGRA,
           DATACONSOLIDACAOPREFAT,
           PREFATURAMENTO,
           0 AS INDPAG,
		   NULL AS CNPJPAG,
		   NULL AS UFPAG,
		   NULL AS CNPJRECEB,
		   NULL AS IDTERMPAG
      FROM (SELECT P.NUMTRANSACAO NUM_TRANSACAO,
                      --TO_CHAR(P.DUPLIC) || ' - ' || P.PREST PRESTACAO,
                      P.PREST PRESTACAO,
                      P.DTVENC DTVENC,
                      P.VALOR VALOR,
                      (SELECT PCPREST.CODCOB
                         FROM PCPREST
                        WHERE PCPREST.NUMTRANSVENDA = P.NUMTRANSACAO
                          AND PCPREST.PREST = P.PREST
                          AND ROWNUM = 1
                     UNION ALL
                       SELECT PCPRESTPREFAT.CODCOB
                         FROM PCPRESTPREFAT
                        WHERE PCPRESTPREFAT.NUMTRANSVENDA = P.NUMTRANSACAO
                          AND PCPRESTPREFAT.PREST = P.PREST
                          AND PCPRESTPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                          AND ROWNUM = 1) CODCOB,
                    (SELECT NVL(PCPREST.VALORDESC, 0)
                       FROM PCPREST
                      WHERE PCPREST.NUMTRANSVENDA = P.NUMTRANSACAO
                        AND PCPREST.PREST = P.PREST
                        AND ROWNUM = 1
                     UNION ALL
                     SELECT NVL(PCPRESTPREFAT.VALORDESC, 0)
                       FROM PCPRESTPREFAT
                      WHERE PCPRESTPREFAT.NUMTRANSVENDA = P.NUMTRANSACAO
                        AND PCPRESTPREFAT.PREST = P.PREST
                        AND PCPRESTPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                        AND ROWNUM = 1) VALORDESC,
                   TO_CHAR(P.DUPLIC) AS DUPLICATA,
                   P.PREST AS NUMPREST,
                   NULL DATACONSOLIDACAOPREFAT,
                   NULL PREFATURAMENTO
              FROM PCPARCELANFE P
             WHERE P.NUMTRANSACAO = PC_TRANSACAO
               AND NVL(P.TIPOMOV, 'X') = 'S')
     ORDER BY LPAD(NUMPREST, 3,'0');--antigo DTVENC, PRESTACAO;

  RETORNO           TABELA_NFE_PARCELA;
  VENVIACOBRANCA    PCFILIAL.ENVIACONTASRECEBERNFE%TYPE;
  VFINALIDADENFE    PCNFSAID.FINALIDADENFE%TYPE;
  VSITUACAONFE      PCNFSAID.SITUACAONFE%TYPE;
  VNOTADECUPOM      VARCHAR2(1);
  V_CONT_NOTA_SAIDA number(18, 0);
  V_PREFATURAMENTO  NUMBER;
BEGIN
  RETORNO           := TABELA_NFE_PARCELA();
  V_CONT_NOTA_SAIDA := 0;
  V_PREFATURAMENTO  := 0;

  SELECT COUNT(*)
    INTO V_PREFATURAMENTO
    FROM PCNFSAIDPREFAT
   WHERE NUMTRANSVENDA = P_TRANSACAO;

  IF V_PREFATURAMENTO > 0 THEN
  
    FOR NOTA_SAIDA IN (SELECT NVL(PCFILIAL.ENVIACONTASRECEBERNFE, 'S') ENVIACONTASRECEBERNFE,
                              NVL(PCNFSAIDPREFAT.FINALIDADENFE, 'N') AS FINALIDADE,
                              NVL(SITUACAONFE, 0) AS SITUACAONFE,
                              NVL((SELECT DECODE(NVL(ORIG.DOCEMISSAO, 'X'), 'CE', 'S', 'N') 
                                     FROM PCNFSAID ORIG 
                                    WHERE ORIG.NUMTRANSVENDA = PCNFSAIDPREFAT.NUMTRANSVENDAORIGEM), 'N') AS NOTADECUPOM
                         FROM PCFILIAL, PCNFSAIDPREFAT
                        WHERE PCFILIAL.CODIGO =
                              NVL(PCNFSAIDPREFAT.CODFILIALNF,
                                  PCNFSAIDPREFAT.CODFILIAL)
                          AND PCNFSAIDPREFAT.NUMTRANSVENDA = P_TRANSACAO) LOOP
      V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;
      VENVIACOBRANCA    := NOTA_SAIDA.ENVIACONTASRECEBERNFE;
      VFINALIDADENFE    := NOTA_SAIDA.FINALIDADE;
      VSITUACAONFE      := NOTA_SAIDA.SITUACAONFE;
      VNOTADECUPOM      := NOTA_SAIDA.NOTADECUPOM;
    END LOOP;
  ELSE
    FOR NOTA_SAIDA IN (SELECT NVL(PCFILIAL.ENVIACONTASRECEBERNFE, 'S') ENVIACONTASRECEBERNFE,
                              NVL(PCNFSAID.FINALIDADENFE, 'N') AS FINALIDADE,
                              NVL(SITUACAONFE, 0) AS SITUACAONFE,
                              NVL((SELECT CASE WHEN NVL(ORIG.DOCEMISSAO, 'X') = 'CE' THEN
                                      'S'
                                      WHEN SERIE IN ('CF', 'CP') THEN
                                      'S'
                                      ELSE
                                      'N'
                                      END
                               FROM PCNFSAID ORIG 
                               WHERE ORIG.NUMTRANSVENDA =  PCNFSAID.NUMTRANSVENDAORIGEM), 'N')  AS NOTADECUPOM
                         FROM PCFILIAL, PCNFSAID
                        WHERE PCFILIAL.CODIGO =
                              NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL)
                          AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO) LOOP
      V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;
      VENVIACOBRANCA    := NOTA_SAIDA.ENVIACONTASRECEBERNFE;
      VFINALIDADENFE    := NOTA_SAIDA.FINALIDADE;
      VSITUACAONFE      := NOTA_SAIDA.SITUACAONFE;
      VNOTADECUPOM      := NOTA_SAIDA.NOTADECUPOM;
    END LOOP;
  
  END IF;

  IF (V_CONT_NOTA_SAIDA > 1) THEN
    raise_application_error(-20001,
                            'Erro motivo: transação ' || P_TRANSACAO ||
                            ' duplicada na tabela PCNFSAID e PCNFSAIDPREFAT. Linha: ' ||
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END IF;

  IF ((VENVIACOBRANCA = 'S') AND (VFINALIDADENFE NOT IN ('A')) AND (VSITUACAONFE <> 100)) THEN
    FOR PARCELA IN CR_PARCELAS(P_TRANSACAO) LOOP
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
                                                 INDPAG                 => NULL,
												 CNPJPAG                => NULL,
												 UFPAG                  => NULL,
												 CNPJRECEB              => NULL,
												 IDTERMPAG              => NULL);
    
      RETORNO(RETORNO.COUNT).DTVENC := PARCELA.DTVENC;
      RETORNO(RETORNO.COUNT).PREST := PARCELA.PRESTACAO;
      RETORNO(RETORNO.COUNT).VALOR := PARCELA.VALOR;
      RETORNO(RETORNO.COUNT).CODCOB := PARCELA.CODCOB;
      RETORNO(RETORNO.COUNT).VALORDESC := PARCELA.VALORDESC;
      RETORNO(RETORNO.COUNT).DUPLICATA := PARCELA.DUPLICATA;
      RETORNO(RETORNO.COUNT).NUMPREST := PARCELA.NUMPREST;
      RETORNO(RETORNO.COUNT).CODCOBSEFAZ := PARCELA.CODCOBSEFAZ;
      RETORNO(RETORNO.COUNT).CNPJ_CRED_CARTAO := PARCELA.CNPJ_CRED_CARTAO;
      RETORNO(RETORNO.COUNT).NUMAUTOR_CARTAO := PARCELA.NUMAUTOR_CARTAO;
      RETORNO(RETORNO.COUNT).BANDEIRA_CARTAO := PARCELA.BANDEIRA_CARTAO;
      RETORNO(RETORNO.COUNT).TP_INTEGRA := PARCELA.TP_INTEGRA;
      RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := PARCELA.DATACONSOLIDACAOPREFAT;
      RETORNO(RETORNO.COUNT).PREFATURAMENTO := PARCELA.PREFATURAMENTO;
      RETORNO(RETORNO.COUNT).INDPAG := PARCELA.INDPAG;
	  RETORNO(RETORNO.COUNT).CNPJPAG := PARCELA.CNPJPAG;
      RETORNO(RETORNO.COUNT).UFPAG := PARCELA.UFPAG;
      RETORNO(RETORNO.COUNT).CNPJRECEB := PARCELA.CNPJRECEB;
      RETORNO(RETORNO.COUNT).IDTERMPAG := PARCELA.IDTERMPAG;
    
    END LOOP;
  ELSIF (VSITUACAONFE = 100) THEN
    FOR PARCELA IN CR_PARCELAS_DANFE(P_TRANSACAO) LOOP
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
                                                 INDPAG                 => NULL,
												 CNPJPAG                => NULL,
												 UFPAG                  => NULL,
												 CNPJRECEB              => NULL,
												 IDTERMPAG              => NULL);
    
      RETORNO(RETORNO.COUNT).DTVENC := PARCELA.DTVENC;
      RETORNO(RETORNO.COUNT).PREST := PARCELA.PRESTACAO;
      RETORNO(RETORNO.COUNT).VALOR := PARCELA.VALOR;
      RETORNO(RETORNO.COUNT).CODCOB := PARCELA.CODCOB;
      RETORNO(RETORNO.COUNT).VALORDESC := PARCELA.VALORDESC;
      RETORNO(RETORNO.COUNT).DUPLICATA := PARCELA.DUPLICATA;
      RETORNO(RETORNO.COUNT).NUMPREST := PARCELA.NUMPREST;
      RETORNO(RETORNO.COUNT).CODCOBSEFAZ := PARCELA.CODCOBSEFAZ;
      RETORNO(RETORNO.COUNT).CNPJ_CRED_CARTAO := PARCELA.CNPJ_CRED_CARTAO;
      RETORNO(RETORNO.COUNT).NUMAUTOR_CARTAO := PARCELA.NUMAUTOR_CARTAO;
      RETORNO(RETORNO.COUNT).BANDEIRA_CARTAO := PARCELA.BANDEIRA_CARTAO;
      RETORNO(RETORNO.COUNT).TP_INTEGRA := PARCELA.TP_INTEGRA;
      RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := PARCELA.DATACONSOLIDACAOPREFAT;
      RETORNO(RETORNO.COUNT).PREFATURAMENTO := PARCELA.PREFATURAMENTO;
      RETORNO(RETORNO.COUNT).INDPAG := PARCELA.INDPAG;
	  RETORNO(RETORNO.COUNT).CNPJPAG := PARCELA.CNPJPAG;
      RETORNO(RETORNO.COUNT).UFPAG := PARCELA.UFPAG;
      RETORNO(RETORNO.COUNT).CNPJRECEB := PARCELA.CNPJRECEB;
      RETORNO(RETORNO.COUNT).IDTERMPAG := PARCELA.IDTERMPAG;
    END LOOP;
  END IF;
  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001,
                            'Erro motivo: ' || SQLERRM || '. Linha: ' ||
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END; 