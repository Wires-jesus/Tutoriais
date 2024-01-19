CREATE OR REPLACE FUNCTION CTE_RECEBEDOR(P_NUM_TRANSACAO INTEGER)
   RETURN TABELA_CTE_RECEBEDOR IS  
   L_TIPOSERVICOCTE VARCHAR2(1);
CURSOR CR_RECEBEDOR IS    
SELECT    RECEBEDOR.CGCENT AS CNPJ
            ,CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE',
                                                    NVL(PCNFSAID.CODFILIALNF,
                                                        PCNFSAID.CODFILIAL)),
                      'H') = 'P' THEN
               RECEBEDOR.CLIENTE
             ELSE
              'CTE EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'
             END AS RAZAO_SOCIAL
            ,REPLACE(RECEBEDOR.FANTASIA, '&', '') AS NOME_FANTASIA
            ,RECEBEDOR.ENDERENT AS LOGRADOURO
            ,NVL(RECEBEDOR.NUMEROENT, 'S\N') AS NUMERO            
            ,'' AS COMPLEMENTO
            ,RECEBEDOR.BAIRROENT AS BAIRRO
            ,CIDADE_E.CODIBGE AS CODIGO_MUNICIPIO
            ,CIDADE_E.NOMECIDADE AS NOME_MUNICIPIO
            ,UF_E.UF AS SIGLA_UF
            ,NVL(PAIS_E.CODPAIS, 0) AS CODIGO_PAIS
            ,PAIS_E.DESCRICAO AS NOME_PAIS 
            ,RECEBEDOR.CEPENT AS CEP
            ,RECEBEDOR.TELENT AS TELEFONE
            ,RECEBEDOR.IEENT AS INSCRICAO_ESTADUAL    
            ,NVL(PCNFSAID.CONTRIBUINTE,RECEBEDOR.CONTRIBUINTE) CONTRIBUINTE        
        FROM PCCLIENT RECEBEDOR
            ,PCCIDADE CIDADE_E
            ,PCESTADO UF_E
            ,PCPAIS PAIS_E
            ,PCNFSAID
       WHERE PCNFSAID.CODRECEBFRETECTEREF = RECEBEDOR.CODCLI
         AND RECEBEDOR.CODCIDADE = CIDADE_E.CODCIDADE(+)
         AND CIDADE_E.UF = UF_E.UF(+)
         AND UF_E.CODPAIS = PAIS_E.CODPAIS(+)
         AND PCNFSAID.NUMTRANSVENDA = P_NUM_TRANSACAO;                         
         RETORNO TABELA_CTE_RECEBEDOR;
BEGIN
 L_TIPOSERVICOCTE := 0; 
 IF L_TIPOSERVICOCTE = 0 THEN
   RETORNO := TABELA_CTE_RECEBEDOR();
   FOR RECEBEDOR IN CR_RECEBEDOR LOOP
      RETORNO.EXTEND;
      
      RETORNO(RETORNO.COUNT) := TIPO_CTE_RECEBEDOR(CNPJ_CPF           => NULL
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
      
      RETORNO(RETORNO.COUNT).CNPJ_CPF           := RECEBEDOR.CNPJ;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL := RECEBEDOR.INSCRICAO_ESTADUAL;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL       := RECEBEDOR.RAZAO_SOCIAL;
      RETORNO(RETORNO.COUNT).NOME_FANTASIA      := RECEBEDOR.NOME_FANTASIA;
      RETORNO(RETORNO.COUNT).LOGRADOURO         := RECEBEDOR.LOGRADOURO;
      RETORNO(RETORNO.COUNT).NUMERO             := RECEBEDOR.NUMERO;
      RETORNO(RETORNO.COUNT).COMPLEMENTO        := RECEBEDOR.COMPLEMENTO;
      RETORNO(RETORNO.COUNT).BAIRRO             := RECEBEDOR.BAIRRO;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO   := RECEBEDOR.CODIGO_MUNICIPIO;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO     := RECEBEDOR.NOME_MUNICIPIO;
      RETORNO(RETORNO.COUNT).CEP                := RECEBEDOR.CEP;
      RETORNO(RETORNO.COUNT).SIGLA_UF           := RECEBEDOR.SIGLA_UF;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS        := RECEBEDOR.CODIGO_PAIS;
      RETORNO(RETORNO.COUNT).NOME_PAIS          := RECEBEDOR.NOME_PAIS;
      RETORNO(RETORNO.COUNT).TELEFONE           := RECEBEDOR.TELEFONE;   
      RETORNO(RETORNO.COUNT).CONTRIBUINTE       := RECEBEDOR.CONTRIBUINTE;
   END LOOP;
   END IF;                                                   
   RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
--Bruno 04/06/2014