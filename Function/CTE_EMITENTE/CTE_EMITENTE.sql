  CREATE OR REPLACE FUNCTION CTE_EMITENTE(P_CODIGO_FILIAL VARCHAR2)
   RETURN TABELA_CTE_EMITENTE IS

   CURSOR CR_EMITENTE IS
      SELECT EMITENTE.CGC AS CNPJ
            ,CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE' ,PCFILIAL.CODIGO) ,'H') = 'P' THEN EMITENTE.FORNECEDOR
             ELSE 'CTE EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL' END  AS RAZAO_SOCIAL
            ,EMITENTE.FANTASIA AS NOME_FANTASIA
            ,EMITENTE.ENDER AS LOGRADOURO
            ,NVL(EMITENTE.NUMEROEND
                ,'S\N') AS NUMERO
            ,'' AS COMPLEMENTO
            ,EMITENTE.BAIRRO AS BAIRRO
            ,NVL(CIDADE_E.CODIBGE
                ,0) AS CODIGO_MUNICIPIO
            ,CIDADE_E.NOMECIDADE AS NOME_MUNICIPIO
            ,UF_E.UF AS SIGLA_UF
            ,NVL(PAIS_E.CODPAIS
                ,0) AS CODIGO_PAIS
            ,PAIS_E.DESCRICAO AS NOME_PAIS
            ,EMITENTE.CEP AS CEP
            ,EMITENTE.TELFAB AS TELEFONE
            ,EMITENTE.IE AS INSCRICAO_ESTADUAL
            ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SERIALCERTIFICADO',
                                         PCFILIAL.CODIGO),
           '') AS SERIALCERTIFICADO
      ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PINCERTIFICADO',
                                         PCFILIAL.CODIGO),
           '') AS PINCERTIFICADO
      ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PROVIDERCERTIFICADOA3',
                                         PCFILIAL.CODIGO),
           'SafeSign Standard Cryptographic Service Provider') AS PROVIDERCERTIFICADOA3
      ,NVL(PARAMFILIAL.OBTERCOMONUMBER('TIPOPROVIDERA3',
                                       PCFILIAL.CODIGO),
           1) AS TIPOPROVIDERA3
      FROM   PCFORNEC EMITENTE
            ,PCFILIAL
            ,PCCIDADE CIDADE_E
            ,PCESTADO UF_E
            ,PCPAIS PAIS_E
      WHERE  PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC AND
             EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE(+) AND
             CIDADE_E.UF = UF_E.UF(+) AND UF_E.CODPAIS = PAIS_E.CODPAIS(+) AND
             PCFILIAL.CODIGO = P_CODIGO_FILIAL;

   RETORNO TABELA_CTE_EMITENTE;
BEGIN
   RETORNO := TABELA_CTE_EMITENTE();

   FOR EMITENTE IN CR_EMITENTE LOOP
      RETORNO.EXTEND;
      
      RETORNO(RETORNO.COUNT) := TIPO_CTE_EMITENTE(CNPJ                  => NULL
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
                                                 ,TIPOPROVIDERA3        => NULL);
      
      RETORNO(RETORNO.COUNT).CNPJ                  := EMITENTE.CNPJ;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL    := EMITENTE.INSCRICAO_ESTADUAL;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL          := EMITENTE.RAZAO_SOCIAL;
      RETORNO(RETORNO.COUNT).NOME_FANTASIA         := EMITENTE.NOME_FANTASIA;
      RETORNO(RETORNO.COUNT).LOGRADOURO            := EMITENTE.LOGRADOURO;
      RETORNO(RETORNO.COUNT).NUMERO                := EMITENTE.NUMERO;
      RETORNO(RETORNO.COUNT).COMPLEMENTO           := EMITENTE.COMPLEMENTO;
      RETORNO(RETORNO.COUNT).BAIRRO                := EMITENTE.BAIRRO;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO      := EMITENTE.CODIGO_MUNICIPIO;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO        := EMITENTE.NOME_MUNICIPIO;
      RETORNO(RETORNO.COUNT).CEP                   := EMITENTE.CEP;
      RETORNO(RETORNO.COUNT).SIGLA_UF              := EMITENTE.SIGLA_UF;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS           := EMITENTE.CODIGO_PAIS;
      RETORNO(RETORNO.COUNT).NOME_PAIS             := EMITENTE.NOME_PAIS;
      RETORNO(RETORNO.COUNT).TELEFONE              := EMITENTE.TELEFONE;
      RETORNO(RETORNO.COUNT).SERIALCERTIFICADO     := EMITENTE.SERIALCERTIFICADO;
      RETORNO(RETORNO.COUNT).PINCERTIFICADO        := EMITENTE.PINCERTIFICADO;
      RETORNO(RETORNO.COUNT).PROVIDERCERTIFICADOA3 := EMITENTE.PROVIDERCERTIFICADOA3;
      RETORNO(RETORNO.COUNT).TIPOPROVIDERA3        := EMITENTE.TIPOPROVIDERA3;
   END LOOP;
   
   RETURN RETORNO;
EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;