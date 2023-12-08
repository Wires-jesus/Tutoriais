CREATE OR REPLACE FUNCTION CTE_EXPEDIDOR(P_CODIGO_EXPEDIDOR NUMBER, P_CODIGO_FILIAL VARCHAR2, P_NUM_TRANSACAO INTEGER DEFAULT 0)
   RETURN TABELA_CTE_EXPEDIDOR IS
L_TIPOSERVICOCTE  PCNFSAID.CODFORNECFRETECTEREF%TYPE;
   CURSOR CR_EXPEDIDOR IS
      SELECT EXPEDIDOR.CGC AS CNPJ
            ,CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE' ,P_CODIGO_FILIAL) ,'H') = 'P' THEN EXPEDIDOR.FORNECEDOR
             ELSE 'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL' END  AS RAZAO_SOCIAL
            ,EXPEDIDOR.FANTASIA AS NOME_FANTASIA
            ,EXPEDIDOR.ENDER AS LOGRADOURO
            ,NVL(EXPEDIDOR.NUMEROEND
                ,'S\N') AS NUMERO
            ,'' AS COMPLEMENTO
            ,EXPEDIDOR.BAIRRO AS BAIRRO
            ,NVL(CIDADE_E.CODIBGE
                ,0) AS CODIGO_MUNICIPIO
            ,CIDADE_E.NOMECIDADE AS NOME_MUNICIPIO
            ,UF_E.UF AS SIGLA_UF
            ,NVL(PAIS_E.CODPAIS
                ,0) AS CODIGO_PAIS
            ,PAIS_E.DESCRICAO AS NOME_PAIS
            ,EXPEDIDOR.CEP AS CEP
            ,EXPEDIDOR.TELFAB AS TELEFONE
            ,EXPEDIDOR.IE AS INSCRICAO_ESTADUAL
            ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SERIALCERTIFICADO',
                                         P_CODIGO_FILIAL),
           '') AS SERIALCERTIFICADO
      ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PINCERTIFICADO',
                                         P_CODIGO_FILIAL),
           '') AS PINCERTIFICADO
      ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PROVIDERCERTIFICADOA3',
                                         P_CODIGO_FILIAL),
           'SafeSign Standard Cryptographic Service Provider') AS PROVIDERCERTIFICADOA3
      ,NVL(PARAMFILIAL.OBTERCOMONUMBER('TIPOPROVIDERA3',
                                         P_CODIGO_FILIAL),
           1) AS TIPOPROVIDERA3, 
             NVL(EXPEDIDOR.contribuinteicms,'N') contribuinte
      FROM   PCFORNEC EXPEDIDOR
            ,PCCIDADE CIDADE_E
            ,PCESTADO UF_E
            ,PCPAIS PAIS_E
      WHERE  EXPEDIDOR.CODCIDADE = CIDADE_E.CODCIDADE(+)
             AND CIDADE_E.UF = UF_E.UF(+)
             AND UF_E.CODPAIS = PAIS_E.CODPAIS(+)
             AND EXPEDIDOR.CODFORNEC = P_CODIGO_EXPEDIDOR
             AND EXPEDIDOR.CODFORNEC > 0;

   RETORNO TABELA_CTE_EXPEDIDOR;
BEGIN
 IF NVL(P_NUM_TRANSACAO, 0) <> 0 THEN
   SELECT NVL(CODFORNECFRETECTEREF, 0)
     INTO L_TIPOSERVICOCTE
      FROM PCNFSAID
     WHERE NUMTRANSVENDA = P_NUM_TRANSACAO; 
 END IF;     
 IF NVL(L_TIPOSERVICOCTE, 0) <> 0 THEN
   RETORNO := TABELA_CTE_EXPEDIDOR();
   FOR EXPEDIDOR IN CR_EXPEDIDOR LOOP
      RETORNO.EXTEND;
      
      RETORNO(RETORNO.COUNT) := TIPO_CTE_EXPEDIDOR( CNPJ                  => NULL
                                                   ,INSCRICAO_ESTADUAL    => NULL
                                                   ,RAZAO_SOCIAL          => NULL
                                                   ,NOME_FANTASIA         => NULL
                                                   ,LOGRADOURO            => NULL
                                                   ,NUMERO                => NULL
                                                   ,COMPLEMENTO           => NULL
                                                   ,BAIRRO                => NULL
                                                   ,CODIGO_MUNICIPIO      => NULL
                                                   ,NOME_MUNICIPIO        => NULL
                                                   ,CEP                   => NULL
                                                   ,SIGLA_UF              => NULL
                                                   ,CODIGO_PAIS           => NULL
                                                   ,NOME_PAIS             => NULL
                                                   ,TELEFONE              => NULL
                                                   ,SERIALCERTIFICADO     => NULL
                                                   ,PINCERTIFICADO        => NULL
                                                   ,PROVIDERCERTIFICADOA3 => NULL
                                                   ,TIPOPROVIDERA3        => NULL
                                                   ,CONTRIBUINTE          => NULL);
      
      RETORNO(RETORNO.COUNT).CNPJ                  := EXPEDIDOR.CNPJ;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL    := EXPEDIDOR.INSCRICAO_ESTADUAL;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL          := EXPEDIDOR.RAZAO_SOCIAL;
      RETORNO(RETORNO.COUNT).NOME_FANTASIA         := EXPEDIDOR.NOME_FANTASIA;
      RETORNO(RETORNO.COUNT).LOGRADOURO            := EXPEDIDOR.LOGRADOURO;
      RETORNO(RETORNO.COUNT).NUMERO                := EXPEDIDOR.NUMERO;
      RETORNO(RETORNO.COUNT).COMPLEMENTO           := EXPEDIDOR.COMPLEMENTO;
      RETORNO(RETORNO.COUNT).BAIRRO                := EXPEDIDOR.BAIRRO;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO      := EXPEDIDOR.CODIGO_MUNICIPIO;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO        := EXPEDIDOR.NOME_MUNICIPIO;
      RETORNO(RETORNO.COUNT).CEP                   := EXPEDIDOR.CEP;
      RETORNO(RETORNO.COUNT).SIGLA_UF              := EXPEDIDOR.SIGLA_UF;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS           := EXPEDIDOR.CODIGO_PAIS;
      RETORNO(RETORNO.COUNT).NOME_PAIS             := EXPEDIDOR.NOME_PAIS;
      RETORNO(RETORNO.COUNT).TELEFONE              := EXPEDIDOR.TELEFONE;
      RETORNO(RETORNO.COUNT).SERIALCERTIFICADO     := EXPEDIDOR.SERIALCERTIFICADO;
      RETORNO(RETORNO.COUNT).PINCERTIFICADO        := EXPEDIDOR.PINCERTIFICADO;
      RETORNO(RETORNO.COUNT).PROVIDERCERTIFICADOA3 := EXPEDIDOR.PROVIDERCERTIFICADOA3;
      RETORNO(RETORNO.COUNT).TIPOPROVIDERA3        := EXPEDIDOR.TIPOPROVIDERA3;
      RETORNO(RETORNO.COUNT).CONTRIBUINTE          := EXPEDIDOR.CONTRIBUINTE;
      
      
   END LOOP;
   END IF;
   RETURN RETORNO;
EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;