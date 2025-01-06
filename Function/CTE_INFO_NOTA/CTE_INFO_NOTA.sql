CREATE OR REPLACE FUNCTION CTE_INFO_NOTA(P_TRANSACAO NUMBER)
   RETURN TABELA_CTE_INFO_NOTA IS

   V_TIPOEMISSAOCTE  PCNFSAID.TIPOEMISSAOCTE%TYPE;
   V_NUMTRANSVENDAORIGEM PCNFSAID.NUMTRANSVENDAORIGEM%TYPE;

   RETORNO TABELA_CTE_INFO_NOTA;

BEGIN
   RETORNO := TABELA_CTE_INFO_NOTA();

    SELECT NVL(PCNFSAID.TIPOEMISSAOCTE,0),
    PCNFSAID.NUMTRANSVENDAORIGEM
    INTO   V_TIPOEMISSAOCTE
          ,V_NUMTRANSVENDAORIGEM
    FROM   PCNFSAID
    WHERE  NUMTRANSVENDA = P_TRANSACAO;

           FOR NOTA IN (--------------NORMAL (NFE)
                         SELECT CASE
                             WHEN PCNFSAID.CHAVENFE IS NULL THEN
                             3
                             ELSE
                             2 END DOCUMENTO_ORIGINARIO,
                             PCNFSAID.CGC AS CNPJ,
                             PCNFSAID.CHAVENFE,
                             '' AS PIN_SUFRAMA,
                             'NF' AS DESCRICAO_OUTROS,
                             PCNFSAID.NUMNOTA AS NUMERO_DOCUMENTO,
                             PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                             PCNFSAID.VLTOTAL AS VALOR_DOCUMENTO,
                             PCNFSAID.SERIE SERIE,
                             PCNFSAID.CLIENTE CLIENTE,
                             PCNFSAID.ENDERECO ENDERECO,
                             '' AS CNPJEMIT,
                             CIDADE_E.UF UFORIG,
                             CIDADE_E.CODIBGE CODMUNINICTE,
                             CIDADE_E.NOMECIDADE NOMEMUNINICTE,
                             '' AS CNPJDEST,
                             CIDADE_D.UF UFDEST,
                             CIDADE_D.CODIBGE CODMUNFIMCTE,
                             CIDADE_D.NOMECIDADE NOMEMUNFIMCTE,
                             FRETE.VLFRETETRANSPORTARNF VALORFRETE
                        FROM PCNFSAID, PCNFSAID FRETE, PCCLIENT DESTINATARIO, PCCIDADE CIDADE_D,
                             PCCLIENT REMETENTE, PCCIDADE CIDADE_E
                       WHERE PCNFSAID.NUMTRANSVENDACONHEC = FRETE.NUMTRANSVENDA
                         AND FRETE.CODDESTINATARIOFRETE = DESTINATARIO.CODCLI
                         AND FRETE.CODREMETENTEFRETE = REMETENTE.CODCLI
                         AND PCNFSAID.NUMTRANSVENDACONHEC = P_TRANSACAO
                         AND NOT PCNFSAID.ESPECIE IN ('CE', 'CO')
                         AND NVL(PCNFSAID.TIPOEMISSAOCTE, 0) IN (0, 5)
                         AND REMETENTE.CODCIDADE = CIDADE_E.CODCIDADE(+)
                         AND DESTINATARIO.CODCIDADE = CIDADE_D.CODCIDADE(+)
                      --------------
                      UNION ALL
                      --------------OUTROS (NF)
                      SELECT CASE
                             WHEN PCCONHECIMENTOFRETEI.CHAVENFE IS NULL THEN
                             3
                             ELSE
                             2 END DOCUMENTO_ORIGINARIO,
                             PCCLIENT.CGCENT CNPJ,
                             NVL(PCCONHECIMENTOFRETEI.CHAVENFE, PCNFSAID.CHAVENFE) AS CHAVENFE,
                             '' AS PIN_SUFRAMA,
                             'OUTROS' AS DESCRICAO_OUTROS,
                             NVL(PCCONHECIMENTOFRETEI.NUMNOTA, PCNFSAID.NUMNOTA) AS NUMERO_DOCUMENTO,
                             PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                             NVL(PCCONHECIMENTOFRETEI.VLTOTAL, PCNFSAID.VLTOTAL) AS VALOR_DOCUMENTO,
                             NVL(PCCONHECIMENTOFRETEI.SERIE, PCNFSAID.SERIE) AS SERIE,
                             PCNFSAID.CLIENTE CLIENTE,
                             PCNFSAID.ENDERECO ENDERECO,
                             PCCONHECIMENTOFRETEI.CNPJEMIT,
                             PCCONHECIMENTOFRETEI.UFORIG,
                             PCCONHECIMENTOFRETEI.CODMUNINICTE,
                             CIDADE_E.NOMECIDADE NOMEMUNINICTE,
                             PCCONHECIMENTOFRETEI.CNPJDEST,
                             PCCONHECIMENTOFRETEI.UFDEST,
                             PCCONHECIMENTOFRETEI.CODMUNFIMCTE,
                             CIDADE_D.NOMECIDADE NOMEMUNFIMCTE,
                             PCCONHECIMENTOFRETEI.VLFRETE VALORFRETE
                        FROM PCNFSAID, PCCONHECIMENTOFRETEI, PCCLIENT,
                             PCCIDADE CIDADE_E, PCCIDADE CIDADE_D
                       WHERE PCNFSAID.NUMTRANSVENDA = PCCONHECIMENTOFRETEI.NUMTRANSCONHEC
                         AND PCNFSAID.CODREMETENTEFRETE = PCCLIENT.CODCLI
                         AND PCCONHECIMENTOFRETEI.NUMTRANSCONHEC = P_TRANSACAO
                         AND PCCONHECIMENTOFRETEI.CODMUNINICTE = CIDADE_E.CODIBGE(+)
                         AND PCCONHECIMENTOFRETEI.CODMUNFIMCTE = CIDADE_D.CODIBGE(+)
                         AND NVL(PCNFSAID.TIPOEMISSAOCTE, 0) IN (0, 5)
                      --------------
                      UNION ALL
                      --------------CTE COMPLEMENTAR
                      SELECT CASE
                             WHEN PCNFSAID.CHAVENFE IS NULL THEN
                             3
                             ELSE
                             2 END DOCUMENTO_ORIGINARIO,
                             PCNFSAID.CGC AS CNPJ,
                             PCNFSAID.CHAVECTE,
                             '' AS PIN_SUFRAMA,
                             'CT' AS DESCRICAO_OUTROS,
                             PCNFSAID.NUMNOTA AS NUMERO_DOCUMENTO,
                             PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                             PCNFSAID.VLTOTAL AS VALOR_DOCUMENTO,
                             PCNFSAID.SERIE SERIE,
                             '' AS CLIENTE,
                             '' AS ENDERECO,
                             '' AS CNPJEMIT,
                             '' AS UFORIG,
                             NULL AS CODMUNINICTE,
                             '' AS NOMEMUNINICTE,
                             '' AS CNPJDEST,
                             '' AS UFDEST,
                             NULL AS CODMUNFIMCTE,
                             '' AS NOMEMUNFIMCTE,
                             PCNFSAID.VLFRETETRANSPORTARNF VALORFRETE
                        FROM PCNFSAID, PCNFSAID ORIG
                       WHERE PCNFSAID.NUMTRANSVENDA = ORIG.NUMTRANSVENDAORIGEM
                         AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                         AND PCNFSAID.ESPECIE IN ('CE', 'CO')
                         AND NVL(PCNFSAID.TIPOEMISSAOCTE, 0) = 0)            
           LOOP
                RETORNO.EXTEND;
                RETORNO(RETORNO.COUNT) := TIPO_CTE_INFO_NOTA();                                                                            
                RETORNO(RETORNO.COUNT).DOCUMENTO_ORIGINARIO := NOTA.DOCUMENTO_ORIGINARIO;
                RETORNO(RETORNO.COUNT).PIN_SUFRAMA          := NOTA.PIN_SUFRAMA;
                RETORNO(RETORNO.COUNT).CHAVENFE             := NOTA.CHAVENFE;
                RETORNO(RETORNO.COUNT).DESCRICAO_OUTROS     := NOTA.DESCRICAO_OUTROS;
                RETORNO(RETORNO.COUNT).NUMERO_DOCUMENTO     := NOTA.NUMERO_DOCUMENTO;
                RETORNO(RETORNO.COUNT).DATA_EMISSAO         := NOTA.DATA_EMISSAO;
                RETORNO(RETORNO.COUNT).VALOR_DOCUMENTO      := NOTA.VALOR_DOCUMENTO;
                RETORNO(RETORNO.COUNT).CNPJ                 := NOTA.CNPJ;
                RETORNO(RETORNO.COUNT).SERIE                := NOTA.SERIE;
                RETORNO(RETORNO.COUNT).CLIENTE              := NOTA.CLIENTE;
                RETORNO(RETORNO.COUNT).ENDERECO             := NOTA.ENDERECO;       
                RETORNO(RETORNO.COUNT).CNPJEMIT             := NOTA.CNPJEMIT;
                RETORNO(RETORNO.COUNT).UFORIG               := NOTA.UFORIG;
                RETORNO(RETORNO.COUNT).CODMUNINICTE         := NOTA.CODMUNINICTE;
                RETORNO(RETORNO.COUNT).NOMEMUNINICTE        := NOTA.NOMEMUNINICTE;
                RETORNO(RETORNO.COUNT).CNPJDEST             := NOTA.CNPJDEST;
                RETORNO(RETORNO.COUNT).UFDEST               := NOTA.UFDEST;
                RETORNO(RETORNO.COUNT).CODMUNFIMCTE         := NOTA.CODMUNFIMCTE;
                RETORNO(RETORNO.COUNT).NOMEMUNFIMCTE        := NOTA.NOMEMUNFIMCTE;
                RETORNO(RETORNO.COUNT).VALORFRETE           := NOTA.VALORFRETE;
             END LOOP;
   RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
