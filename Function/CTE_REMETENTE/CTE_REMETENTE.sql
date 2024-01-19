CREATE OR REPLACE FUNCTION CTE_REMETENTE(P_NUM_TRANSACAO INTEGER)
   RETURN TABELA_CTE_REMETENTE IS


   CURSOR CR_REMETENTE IS
      SELECT       REMETENTE.CGCENT AS CNPJ
            ,CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE',
                                                    NVL(PCNFSAID.CODFILIALNF,
                                                        PCNFSAID.CODFILIAL)),
                      'H') = 'P' THEN
              REMETENTE.CLIENTE
             ELSE
              'CTE EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'
             END AS RAZAO_SOCIAL
            ,REMETENTE.FANTASIA AS NOME_FANTASIA
            ,REMETENTE.ENDERENT AS LOGRADOURO
            ,NVL(REMETENTE.NUMEROENT
                ,'S\N') AS NUMERO
            ,'' AS COMPLEMENTO
            ,REMETENTE.BAIRROENT AS BAIRRO
            ,NVL(CIDADE_E.CODIBGE
                ,0) AS CODIGO_MUNICIPIO
            ,CIDADE_E.NOMECIDADE AS NOME_MUNICIPIO
            ,UF_E.UF AS SIGLA_UF
            ,NVL(PAIS_E.CODPAIS
                ,0) AS CODIGO_PAIS
            ,PAIS_E.DESCRICAO AS NOME_PAIS
            ,REMETENTE.CEPENT AS CEP
            ,REMETENTE.TELENT AS TELEFONE
            ,REMETENTE.IEENT AS INSCRICAO_ESTADUAL
            ,case when (NVL(PCNFSAID.TOMADORCTE,
                 CASE WHEN (TIPOSERVICOCTE = '1' AND TIPOSUBCONTRATACAOCTE = '1') THEN
                           4
                      WHEN (TIPOSERVICOCTE = '2' AND TIPOSUBCONTRATACAOCTE = '0') THEN
                           1
                 ELSE
                   DECODE(NVL(PCNFSAID.TIPOFRETE,'C') ,'C' ,0 ,'G' ,0 ,3)
                 END)) = '0' then 
                 NVL(REMETENTE.CONTRIBUINTE, PCNFSAID.CONTRIBUINTE)
              else
                 NVL(PCNFSAID.CONTRIBUINTE, REMETENTE.CONTRIBUINTE)   
              end CONTRIBUINTE
        FROM PCCLIENT REMETENTE
            ,PCCIDADE CIDADE_E
            ,PCESTADO UF_E
            ,PCPAIS PAIS_E
            ,PCNFSAID 
       WHERE PCNFSAID.CODREMETENTEFRETE = REMETENTE.CODCLI
         AND REMETENTE.CODCIDADE = CIDADE_E.CODCIDADE
         AND CIDADE_E.UF = UF_E.UF(+)
         AND UF_E.CODPAIS = PAIS_E.CODPAIS(+)
         AND PCNFSAID.NUMTRANSVENDA = P_NUM_TRANSACAO;

   RETORNO TABELA_CTE_REMETENTE;

BEGIN
   RETORNO := TABELA_CTE_REMETENTE();

   FOR REMETENTE IN CR_REMETENTE LOOP
      RETORNO.EXTEND;
      
      RETORNO(RETORNO.COUNT) := TIPO_CTE_REMETENTE(CNPJ_CPF           => NULL
                                                  ,INSCRICAO_ESTADUAL => NULL
                                                  ,RAZAO_SOCIAL       => NULL
                                                  ,NOME_FANTASIA      => NULL
                                                  ,LOGRADOURO         => NULL
                                                  ,NUMERO             => NULL
                                                  ,COMPLEMENTO        => NULL
                                                  ,BAIRRO             => NULL
                                                  ,CODIGO_MUNICIPIO   => NULL
                                                  ,NOME_MUNICIPIO     => NULL
                                                  ,CEP                => NULL
                                                  ,SIGLA_UF           => NULL
                                                  ,CODIGO_PAIS        => NULL
                                                  ,NOME_PAIS          => NULL
                                                  ,TELEFONE           => NULL
                                                  ,CONTRIBUINTE       => NULL );
      
      RETORNO(RETORNO.COUNT).CNPJ_CPF           := REMETENTE.CNPJ;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL := REMETENTE.INSCRICAO_ESTADUAL;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL       := REMETENTE.RAZAO_SOCIAL;
      RETORNO(RETORNO.COUNT).NOME_FANTASIA      := REMETENTE.NOME_FANTASIA;
      RETORNO(RETORNO.COUNT).LOGRADOURO         := REMETENTE.LOGRADOURO;
      RETORNO(RETORNO.COUNT).NUMERO             := REMETENTE.NUMERO;
      RETORNO(RETORNO.COUNT).COMPLEMENTO        := REMETENTE.COMPLEMENTO;
      RETORNO(RETORNO.COUNT).BAIRRO             := REMETENTE.BAIRRO;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO   := REMETENTE.CODIGO_MUNICIPIO;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO     := REMETENTE.NOME_MUNICIPIO;
      RETORNO(RETORNO.COUNT).CEP                := REMETENTE.CEP;
      RETORNO(RETORNO.COUNT).SIGLA_UF           := REMETENTE.SIGLA_UF;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS        := REMETENTE.CODIGO_PAIS;
      RETORNO(RETORNO.COUNT).NOME_PAIS          := REMETENTE.NOME_PAIS;
      RETORNO(RETORNO.COUNT).TELEFONE           := REMETENTE.TELEFONE;
      RETORNO(RETORNO.COUNT).CONTRIBUINTE       := REMETENTE.CONTRIBUINTE;
   END LOOP;
   RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;