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
                             '' CNPJ,
                             PCNFSAID.CHAVENFE,
                             '' AS PIN_SUFRAMA,
                             'NF' AS DESCRICAO_OUTROS,
                             PCNFSAID.NUMNOTA AS NUMERO_DOCUMENTO,
                             PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                             PCNFSAID.VLTOTAL AS VALOR_DOCUMENTO,
                             PCNFSAID.SERIE SERIE,
                             PCNFSAID.CLIENTE CLIENTE,
                             PCNFSAID.ENDERECO ENDERECO
                        FROM PCNFSAID, PCNFSAID FRETE
                       WHERE PCNFSAID.NUMTRANSVENDACONHEC = FRETE.NUMTRANSVENDA
                         AND PCNFSAID.NUMTRANSVENDACONHEC = P_TRANSACAO
                         AND NOT PCNFSAID.ESPECIE IN ('CE', 'CO')
                         AND NVL(PCNFSAID.TIPOEMISSAOCTE, 0) = 0
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
                             PCNFSAID.ENDERECO ENDERECO
                        FROM PCNFSAID, PCCONHECIMENTOFRETEI, PCCLIENT
                       WHERE PCNFSAID.NUMTRANSVENDA = PCCONHECIMENTOFRETEI.NUMTRANSCONHEC
                         AND PCNFSAID.CODREMETENTEFRETE = PCCLIENT.CODCLI
                         AND PCCONHECIMENTOFRETEI.NUMTRANSCONHEC = P_TRANSACAO
                         AND NVL(TIPOEMISSAOCTE, 0) = 0
                      --------------
                      UNION ALL
                      --------------CTE COMPLEMENTAR
                      SELECT CASE
                             WHEN PCNFSAID.CHAVENFE IS NULL THEN
                             3
                             ELSE
                             2 END DOCUMENTO_ORIGINARIO,
                             '' CNPJ,
                             PCNFSAID.CHAVECTE,
                             '' AS PIN_SUFRAMA,
                             'CT' AS DESCRICAO_OUTROS,
                             PCNFSAID.NUMNOTA AS NUMERO_DOCUMENTO,
                             PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                             PCNFSAID.VLTOTAL AS VALOR_DOCUMENTO,
                             PCNFSAID.SERIE SERIE,
                             '' AS CLIENTE,
                             '' AS ENDERECO
                        FROM PCNFSAID, PCNFSAID ORIG
                       WHERE PCNFSAID.NUMTRANSVENDA = ORIG.NUMTRANSVENDAORIGEM
                         AND ORIG.NUMTRANSVENDA = P_TRANSACAO
                         AND PCNFSAID.ESPECIE IN ('CE', 'CO')
                         AND NVL(PCNFSAID.TIPOEMISSAOCTE, 0) = 0)            
           LOOP
                RETORNO.EXTEND;
                RETORNO(RETORNO.COUNT) := TIPO_CTE_INFO_NOTA(DOCUMENTO_ORIGINARIO => NULL
                                                            ,PIN_SUFRAMA          => NULL
                                                            ,CHAVENFE             => NULL
                                                            ,DESCRICAO_OUTROS     => NULL
                                                            ,NUMERO_DOCUMENTO     => NULL
                                                            ,DATA_EMISSAO         => NULL
                                                            ,VALOR_DOCUMENTO      => NULL
                                                            ,CNPJ                 => NULL
                                                            ,SERIE                => NULL
                                                            ,CLIENTE              => NULL
                                                            ,ENDERECO             => NULL
                                                             );       
                                                                      
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
             END LOOP;
   RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;