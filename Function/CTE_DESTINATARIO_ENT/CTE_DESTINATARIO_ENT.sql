CREATE OR REPLACE FUNCTION CTE_DESTINATARIO_ENT(P_TRANSACAO_CONHECIMENTO NUMBER)
  RETURN TABELA_CTE_DESTINATARIO_ENT IS
 
  CURSOR CR_CLIENTE IS    
    SELECT DESTINATARIO.CGCENT,
           DESTINATARIO.IEENT,
           DESTINATARIO.SULFRAMA,
           CASE
             WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE',
                                                    NVL(PCNFSAID.CODFILIALNF,
                                                        PCNFSAID.CODFILIAL)),
                      'H') = 'P' THEN
              DESTINATARIO.CLIENTE
             ELSE
              'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'
           END AS CLIENTE,
           DESTINATARIO.ENDERENT,
           NVL(DESTINATARIO.NUMEROENT, 'S/N') AS NUMEROENT,
           DESTINATARIO.COMPLEMENTOENT,
           DESTINATARIO.BAIRROENT,
           CIDADE_E.CODIBGE,
           CIDADE_E.NOMECIDADE,
           DESTINATARIO.CEPENT,
           CIDADE_E.UF,
           PCNFSAID.CODPAIS AS CODPAIS,
           PCNFSAID.DESCPAIS AS DESCRICAO,
           DESTINATARIO.TELENT
      FROM PCCLIENT DESTINATARIO,
           PCCIDADE CIDADE_E,
           PCESTADO UF_E,
           PCPAIS PAIS_E,
           PCNFSAID
     WHERE PCNFSAID.CODDESTINATARIOFRETE = DESTINATARIO.CODCLI
       AND DESTINATARIO.CODCIDADE = CIDADE_E.CODCIDADE(+)
       AND CIDADE_E.UF = UF_E.UF(+)
       AND UF_E.CODPAIS = PAIS_E.CODPAIS(+)
       AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO_CONHECIMENTO;

  RETORNO TABELA_CTE_DESTINATARIO_ENT;
  V_CODENDENTCLI INTEGER;
BEGIN
  RETORNO := TABELA_CTE_DESTINATARIO_ENT();
  BEGIN
    SELECT MAX(NVL(PD.CODENDENTCLI, PD.CODENDENT)) CODENDENTCLI
        INTO V_CODENDENTCLI
      FROM PCNFSAID CT, PCNFSAID NF, PCPEDC PD 
     WHERE CT.NUMTRANSVENDA = NF.NUMTRANSVENDACONHEC 
       AND NF.NUMPED = PD.NUMPED
       AND NF.CODCLI = CT.CODCLI       
       AND NF.ESPECIE = 'NF'
       AND CT.NUMTRANSVENDA = P_TRANSACAO_CONHECIMENTO;
  EXCEPTION  
    WHEN OTHERS THEN
      V_CODENDENTCLI := 0;    
    END;   
   
  IF NVL(V_CODENDENTCLI, 0) > 0 THEN
   FOR CLIENTE IN (
    SELECT DESTINATARIO.CGCENT,
           DESTINATARIO.IEENT,
           DESTINATARIO.SULFRAMA,
           CASE
             WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE',
                                                    NVL(PCNFSAID.CODFILIALNF,
                                                        PCNFSAID.CODFILIAL)),
                      'H') = 'P' THEN
              DESTINATARIO.CLIENTE
             ELSE
              'CT-E EMITIDO EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'
           END AS CLIENTE,
           ENDE.ENDERENT,
           NVL(ENDE.NUMEROENT, 'S/N') AS NUMEROENT,
           ENDE.COMPLEMENTOENT,
           ENDE.BAIRROENT,
           CIDADE_E.CODIBGE,
           ENDE.MUNICENT, NOMECIDADE,
           ENDE.CEPENT,
           ENDE.ESTENT UF,
           PCNFSAID.CODPAIS AS CODPAIS,
           PCNFSAID.DESCPAIS AS DESCRICAO,
           DESTINATARIO.TELENT
      FROM PCCLIENT DESTINATARIO,
           PCCIDADE CIDADE_E,
           PCESTADO UF_E,
           PCPAIS PAIS_E,
           PCNFSAID,
           PCCLIENTENDENT ENDE
     WHERE PCNFSAID.CODDESTINATARIOFRETE = DESTINATARIO.CODCLI
       AND ENDE.CODCIDADE = CIDADE_E.CODCIDADE(+)
       AND CIDADE_E.UF = UF_E.UF(+)
       AND UF_E.CODPAIS = PAIS_E.CODPAIS(+)
       AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO_CONHECIMENTO
       AND ENDE.CODENDENTCLI = V_CODENDENTCLI   ) LOOP  
  
    RETORNO.EXTEND;
    
    RETORNO(RETORNO.COUNT) := TIPO_CTE_DESTINATARIO_ENT(NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                                                    
                                                    
      RETORNO(RETORNO.COUNT).CNPJ_CPF           := CLIENTE.CGCENT;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL := CLIENTE.IEENT;
      RETORNO(RETORNO.COUNT).INSCRICAO_SUFRAMA  := CLIENTE.SULFRAMA;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL       := CLIENTE.CLIENTE;
      RETORNO(RETORNO.COUNT).LOGRADOURO         := CLIENTE.ENDERENT;
      RETORNO(RETORNO.COUNT).NUMERO             := CLIENTE.NUMEROENT;
      RETORNO(RETORNO.COUNT).COMPLEMENTO        := CLIENTE.COMPLEMENTOENT;
      RETORNO(RETORNO.COUNT).BAIRRO             := CLIENTE.BAIRROENT;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO   := CLIENTE.CODIBGE;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO     := CLIENTE.NOMECIDADE;
      RETORNO(RETORNO.COUNT).CEP                := CLIENTE.CEPENT;
      RETORNO(RETORNO.COUNT).SIGLA_UF           := CLIENTE.UF;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS        := CLIENTE.CODPAIS;
      RETORNO(RETORNO.COUNT).NOME_PAIS          := CLIENTE.DESCRICAO;
      RETORNO(RETORNO.COUNT).TELEFONE           := CLIENTE.TELENT;
   
      
  END LOOP;    
  END IF;  
  RETURN RETORNO;
EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;