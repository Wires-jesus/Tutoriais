CREATE OR REPLACE FUNCTION NFE_CABECALHO_SAIDA(P_TIPO                 NUMBER DEFAULT 1,
                                               P_QUANTIDADE_DIAS      NUMBER DEFAULT NULL,
                                               P_QUANTIDADE_REGISTROS NUMBER DEFAULT NULL,
                                               P_TRANSACOES           VARCHAR2 DEFAULT NULL,
                                               P_FILIAIS              VARCHAR2 DEFAULT NULL)
  RETURN TABELA_NFE_CABECALHO IS

  CURSOR CR_CABECALHOS_DANFE(PC_TRANSACAO NUMBER, PC_FILIAIS VARCHAR2) IS
    SELECT *
      FROM SQL_NFE_CABECALHO_SAIDA CABECALHO
     WHERE CABECALHO.NUM_TRANSACAO = PC_TRANSACAO
       AND (NVL(P_FILIAIS, 'X') = 'X' OR + CABECALHO.CODIGO_FILIAL IN
           (PC_FILIAIS))
       AND ((CABECALHO.NUMTRANSENTORIGCONSIG IS NULL) OR
           ((((CABECALHO.NUMTRANSENTORIGCONSIG IS NOT NULL) AND
           ((SELECT COUNT(1)
                   FROM PCNFENT, PCNFSAID, PCESTCOM
                  WHERE 1 = 1
                    AND PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT
                    AND PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
                    AND PCNFSAID.CONDVENDA = 20
                    AND ((NVL(PCNFENT.CONSUMIUNUMNFE, 'N') = 'S') OR
                        ((NVL(PCNFENT.GERANFVENDA, 'N') = 'N') AND
                        ((NVL(PCNFENT.GERANFDEVCLI, 'N')) = 'N')))
                    AND PCNFENT.NUMTRANSENT = CABECALHO.NUMTRANSENTORIGCONSIG
                 
                 ) > 0))) OR
           ((SELECT COUNT(*)
                 FROM PCESTCOM
                WHERE NUMTRANSENT = CABECALHO.NUMTRANSENTORIGCONSIG) = 0)))
       ---------------------------------------------------------------------
       -----------------validação de dados retroativos----------------------
       ------não mexer sem alinhar com eddy. critico------------------------
       AND NVL((SELECT CASE
                        WHEN ( SELECT MAX(VERSAO) AS VERSAO
                                 FROM (SELECT VERSAO, SNAPSHOTID, NOME
                                         FROM PCWTASNAPSHOTUPDATE
                                       UNION ALL
                                       SELECT VERSAO, SNAPSHOTID, NOME
                                         FROM PCWTASNAPSHOTSTATE
                                        WHERE NOME NOT IN
                                              (SELECT NOME
                                                 FROM PCWTASNAPSHOTUPDATE
                                                WHERE SNAPSHOTID = PCWTASNAPSHOTSTATE.SNAPSHOTID))
                                WHERE SNAPSHOTID =
                                      (SELECT ID
                                         FROM (SELECT ID FROM PCWTASNAPSHOT ORDER BY DATACRIACAO DESC)
                                        WHERE ROWNUM = 1)
                                  AND LOWER(NOME) = LOWER('WINTHOR-FER-0820')
                              ) = '1.5.6.10' THEN
                        
                         CASE
                           WHEN (SELECT CODFILIAL
                                   FROM TABLE(ATUALIZACAO_DIARIA.TEM_DADOS_RETROATIVOS(CABECALHO.CODIGO_FILIAL))) IS NOT NULL THEN
                            'S'
                         ELSE
                            'N'
                         END                  
                       ELSE
                         'N'
                       END
                 FROM DUAL),
               'N') = 'N'
       ---------------------------------------------------------------------
       ---------------------------------------------------------------------
    ;

  RETORNO     TABELA_NFE_CABECALHO;
  NOVO_NUMERO NUMBER;
  V_UTILIZANFE VARCHAR2(1);
  V_UTILIZASRVTERCEIROS VARCHAR2(1);  
  L_CURSOR    SYS_REFCURSOR;
  L_CURSOR_TERCEIROS    SYS_REFCURSOR;  
BEGIN
  RETORNO := TABELA_NFE_CABECALHO();

  IF P_TIPO = 1 THEN

    OPEN L_CURSOR FOR
     SELECT NUMTRANSVENDA,
            UTILIZANFE,
            UTILIZASRVTERCEIROS
     FROM(
      SELECT DISTINCT NUMTRANSVENDA,
              TIPOEMISSAO,
              ORDEM,
              UTILIZANFE,
              UTILIZASRVTERCEIROS 
        FROM (SELECT PCNFSAID.NUMTRANSVENDA,
                     PCNFSAID.NUMNOTA,
                     PCNFSAID.TIPOEMISSAO,
                     DECODE(PCNFSAID.CONDVENDA, 14, 0, 1) ORDEM,
                     nvl(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) CODFILIAL,
                     NVL(PCFILIAL.UTILIZANFE, 'N') UTILIZANFE,
                     'N' UTILIZASRVTERCEIROS,
                     NVL(PCNFSAID.QTDEREPROCNFE, 0) QTDEREPROCNFE
                FROM PCNFSAID, PCFILIAL
               WHERE 1=1
                 AND ((PCNFSAID.ESPECIE = 'NE') OR
                      ((PCNFSAID.ESPECIE = 'NF') AND 
                       ((PCNFSAID.TIPOEMISSAO IN ('2', '5')) )))
                 AND PCNFSAID.DTCANCEL IS NULL
                 AND PCNFSAID.DTSAIDA BETWEEN
                     TRUNC(SYSDATE) - nvl(P_QUANTIDADE_DIAS,1) AND TRUNC(SYSDATE)
                 AND PCNFSAID.SITUACAONFE IN (0, 124)
                 AND NVL(PCNFSAID.DOCEMISSAO, 'X') NOT IN ('CE','SF', 'MF', 'CF')  
                 AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
                 AND (COALESCE(PCFILIAL.UTILIZANFE, 'N') = 'S')
                 AND (NVL(PCNFSAID.USASRVTERCEIROS, 'N') = 'N')
              UNION ALL
              SELECT PCNFSAIDPREFAT.NUMTRANSVENDA,
                     PCNFSAIDPREFAT.NUMNOTA,
                     PCNFSAIDPREFAT.TIPOEMISSAO,
                     DECODE(PCNFSAIDPREFAT.CONDVENDA, 14, 0, 1) ORDEM,
                     nvl(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) CODFILIAL,
                     NVL(PCFILIAL.UTILIZANFE, 'N') UTILIZANFE,
                     'N' UTILIZASRVTERCEIROS,
                     NVL(PCNFSAIDPREFAT.QTDEREPROCNFE, 0) QTDEREPROCNFE
                FROM PCNFSAIDPREFAT, PCFILIAL
               WHERE 1=1
                 AND ((PCNFSAIDPREFAT.ESPECIE = 'NE') OR
                      ((PCNFSAIDPREFAT.ESPECIE = 'NF') AND 
                       ((PCNFSAIDPREFAT.TIPOEMISSAO IN ('2', '5')))))
                 AND PCNFSAIDPREFAT.DTCANCEL IS NULL
                 AND PCNFSAIDPREFAT.DTSAIDA BETWEEN
                     TRUNC(SYSDATE) - nvl(P_QUANTIDADE_DIAS,1) AND TRUNC(SYSDATE)
                 AND PCNFSAIDPREFAT.SITUACAONFE IN (0, 124)
                 AND NVL(PCNFSAIDPREFAT.DOCEMISSAO, 'X') NOT IN ('CE','SF', 'MF', 'CF')  
                 AND NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                 AND (COALESCE(PCFILIAL.UTILIZANFE, 'N') = 'S')
                 AND (NVL(PCNFSAIDPREFAT.USASRVTERCEIROS, 'N') = 'N')
                 AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
               ORDER BY QTDEREPROCNFE, NUMTRANSVENDA
               ) NOTA
               WHERE ROWNUM <= NVL(P_QUANTIDADE_REGISTROS,1)
               ORDER BY NOTA.TIPOEMISSAO, NOTA.ORDEM, NOTA.NUMTRANSVENDA
               );
               
    OPEN L_CURSOR_TERCEIROS FOR           
      SELECT NUMTRANSVENDA, 
             UTILIZANFE, 
             UTILIZASRVTERCEIROS
        FROM (SELECT DISTINCT NUMTRANSVENDA,
                              TIPOEMISSAO,
                              ORDEM,
                              UTILIZANFE,
                              UTILIZASRVTERCEIROS
                FROM (SELECT PCNFSAIDPREFAT.NUMTRANSVENDA,
                             PCNFSAIDPREFAT.NUMNOTA,
                             PCNFSAIDPREFAT.TIPOEMISSAO,
                             DECODE(PCNFSAIDPREFAT.CONDVENDA, 14, 0, 1) ORDEM,
                             NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) CODFILIAL,
                             'N' UTILIZANFE,
                             NVL(PCNFSAIDPREFAT.USASRVTERCEIROS,
                                 PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZASRVTERCEIROS', PCFILIAL.CODIGO)) UTILIZASRVTERCEIROS
                        FROM PCNFSAIDPREFAT, PCFILIAL
                       WHERE 1 = 1
                         AND ((PCNFSAIDPREFAT.ESPECIE = 'NF') AND
                             (NVL(PCNFSAIDPREFAT.USASRVTERCEIROS,
                                   PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZASRVTERCEIROS',
                                                                 NVL(PCNFSAIDPREFAT.CODFILIALNF,
                                                                     PCNFSAIDPREFAT.CODFILIAL))) = 'S'))
                         AND PCNFSAIDPREFAT.DTCANCEL IS NULL
                         AND PCNFSAIDPREFAT.DTSAIDA BETWEEN TRUNC(SYSDATE) - NVL(P_QUANTIDADE_DIAS, 1) AND TRUNC(SYSDATE)
                         AND PCNFSAIDPREFAT.SITUACAONFE IN (0, 124)
                         AND NVL(PCNFSAIDPREFAT.DOCEMISSAO, 'X') NOT IN ('CE', 'SF', 'MF', 'CF')
                         AND NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                         AND (NVL(PCNFSAIDPREFAT.USASRVTERCEIROS,
                                  PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZASRVTERCEIROS', PCFILIAL.CODIGO)) = 'S')
                         AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                       ORDER BY PCNFSAIDPREFAT.NUMTRANSVENDA) NOTA
               WHERE ROWNUM <= NVL(P_QUANTIDADE_REGISTROS, 1)
               ORDER BY NOTA.TIPOEMISSAO, NOTA.ORDEM, NOTA.NUMTRANSVENDA);

  ELSE
    IF P_TRANSACOES IS NULL THEN
      OPEN L_CURSOR FOR SELECT 0 NUMTRANSVENDA, 'S' UTILIZANFE, 'S' UTILIZASRVTERCEIROS  FROM DUAL UNION SELECT 0 NUMTRANSVENDA, 'S' UTILIZANFE, 'S' UTILIZASRVTERCEIROS FROM DUAL;
    ELSE
      OPEN L_CURSOR FOR 'SELECT ' || REPLACE(P_TRANSACOES,
                                             ',',
                                             ' NUMTRANSVENDA, ''S'' UTILIZANFE, ''S'' UTILIZASRVTERCEIROS FROM DUAL UNION SELECT ') ||
                                             ' NUMTRANSVENDA, ''S'' UTILIZANFE, ''S'' UTILIZASRVTERCEIROS FROM DUAL';
    END IF;
  END IF;

  LOOP
    FETCH L_CURSOR
      INTO NOVO_NUMERO, V_UTILIZANFE, V_UTILIZASRVTERCEIROS;

    --CASO O CURSOR DE NOTAS NORMAIS NÃO TENHA RESULTADOS, PROCESSA NOTAS DE TERCEIROS
    IF ((L_CURSOR%NOTFOUND) AND (P_TIPO = 1)) THEN
      FETCH L_CURSOR_TERCEIROS
            INTO NOVO_NUMERO, V_UTILIZANFE, V_UTILIZASRVTERCEIROS;
    END IF;
    
    --CODIGO PARA SAIR DA FUNÇÃO QUANDO NÃO EXISTIR REGISTRO EM NENHUM CURSOR
    IF ((L_CURSOR%NOTFOUND) AND ((L_CURSOR_TERCEIROS IS NULL) OR (L_CURSOR_TERCEIROS%NOTFOUND))) THEN
       EXIT;
    END IF;

    IF ((V_UTILIZANFE = 'S') OR (V_UTILIZASRVTERCEIROS = 'S')) THEN
    FOR FILIAIS IN (SELECT VALOR
               FROM TABLE(CAST(LISTA_DE_STRINGS(P_FILIAIS) AS TABELA_STRING))) LOOP
      FOR CABECALHO IN CR_CABECALHOS_DANFE(NOVO_NUMERO, FILIAIS.VALOR) LOOP
        RETORNO.EXTEND;

         RETORNO(RETORNO.COUNT) := TIPO_NFE_CABECALHO(AMBIENTE               => NULL,
                                                     BAIRRO_D               => NULL,
                                                     BAIRRO_E               => NULL,
                                                     CEP_D                  => NULL,
                                                     CEP_E                  => NULL,
                                                     CHAVENFE               => NULL,
                                                     CNAE_E                 => NULL,
                                                     CNPJ_CPF_D             => NULL,
                                                     CNPJ_E                 => NULL,
                                                     CODCONT                => NULL,
                                                     CODDOC                 => NULL,
                                                     CODIGO_CLI             => NULL,
                                                     CODIGO_EXPORTADOR      => NULL,
                                                     CODIGO_FABRICANTE_EX   => NULL,
                                                     CODIGO_FILIAL          => NULL,
                                                     CODIGO_FISCAL          => NULL,
                                                     CODIGO_MUNICIPIO_D     => NULL,
                                                     CODIGO_MUNICIPIO_E     => NULL,
                                                     CODIGO_PAIS_D          => NULL,
                                                     CODIGO_PAIS_E          => NULL,
                                                     COMPLEMENTO_D          => NULL,
                                                     COMPLEMENTO_E          => NULL,
                                                     CONDVENDA              => NULL,
                                                     CONSUMIDOR_FINAL       => NULL,
                                                     CRT                    => NULL,
                                                     TIPODESCARGA           => NULL,
                                                     DATA_DESEMBARACO       => NULL,
                                                     DATA_EMISSAO           => NULL,
                                                     DATA_SAIDA             => NULL,
                                                     DATA_SAIDA_DANFE       => NULL,
                                                     DATA_ENTREGA           => NULL,
                                                     DESTINOCARGA           => NULL,
                                                     DTHORA_AUTORIZACAO     => NULL,
                                                     DTHORA_CONTINGENCIA    => NULL,
                                                     EMAIL_D                => NULL,
                                                     EMAIL_E                => NULL,
                                                     ENDERECO               => NULL,
                                                     ESPECIE                => NULL,
                                                     FAX_E                  => NULL,
                                                     FINALIDADE             => NULL,
                                                     HORA                   => NULL,
                                                     INSCRICAO_ESTADUAL_D   => NULL,
                                                     INSCRICAO_ESTADUAL_E   => NULL,
                                                     INSCRICAO_MUNICIPAL_E  => NULL,
                                                     INSCRICAO_SUBSTITUTO_E => NULL,
                                                     INSCRICAO_SUFRAMA_D    => NULL,
                                                     JUSTIFICATIVA          => NULL,
                                                     LOCAL_DESEMBARACO      => NULL,
                                                     LOGRADOURO_D           => NULL,
                                                     LOGRADOURO_E           => NULL,
                                                     MOVIMENTO              => NULL,
                                                     NATUREZA_OP            => NULL,
                                                     NOME_FANTASIA_E        => NULL,
                                                     NOME_MUNICIPIO_D       => NULL,
                                                     NOME_MUNICIPIO_E       => NULL,
                                                     NOME_FANTASIA_D        => NULL,
                                                     NUM_DOC_IMPORTACAO     => NULL,
                                                     NUM_IMPRESSAO          => NULL,
                                                     NUM_PEDIDO             => NULL,
                                                     NUM_PEDIDO_CLI         => NULL,
                                                     NUM_TRANSACAO          => NULL,
                                                     NUM_TRANSACAO_DEV      => NULL,
                                                     NUM_TRANSACAO_ORIG     => NULL,
                                                     NUMERO_CAR             => NULL,
                                                     NUMERO_D               => NULL,
                                                     NUMERO_E               => NULL,
                                                     NUMERO_NOTA            => NULL,
                                                     ORGAO_PUBLICO          => NULL,
                                                     PAIS_E                 => NULL,
                                                     PAIS_D                 => NULL,
                                                     PINCERTIFICADO         => NULL,
                                                     PROVIDERCERTIFICADOA3  => NULL,
                                                     PROTOCOLONFE           => NULL,
                                                     RAZAO_SOCIAL_D         => NULL,
                                                     RAZAO_SOCIAL_E         => NULL,
                                                     RCA                    => NULL,
                                                     SERIALCERTIFICADO      => NULL,
                                                     SERIE                  => NULL,
                                                     SERIE_SCAN             => NULL,
                                                     SIGLA_UF_D             => NULL,
                                                     SIGLA_UF_DESEMBARACO   => NULL,
                                                     SIGLA_UF_E             => NULL,
                                                     SITUACAONFE            => NULL,
                                                     TELEFONE_D             => NULL,
                                                     TELEFONE_E             => NULL,
                                                     TIPO_COBRANCA          => NULL,
                                                     TIPO_DANFE             => NULL,
                                                     TIPO_EMISSAO           => NULL,
                                                     TIPO_EMPRESA           => NULL,
                                                     TIPO_PESSOA            => NULL,
                                                     TIPO_PGTO              => NULL,
                                                     TIPOPROVIDERA3         => NULL,
                                                     NUMPEDRCA              => NULL,
                                                     CNPJ_CPF_ENT           => NULL,
                                                     LOGRADOURO_ENT         => NULL,
                                                     NUMERO_ENT             => NULL,
                                                     COMPLEMENTO_ENT        => NULL,
                                                     BAIRRO_ENT             => NULL,
                                                     NOME_MUNICIPIO_ENT     => NULL,
                                                     CODIGO_MUNICIPIO_ENT   => NULL,
                                                     SIGLA_UF_ENT           => NULL,
                                                     MOT_ESTORNONFE         => NULL,
                                                     SITUACAO_NFE_EPEC      => NULL,
                                                     INDICADOR_PRESENCA     => NULL,
                                                     TIPOVENDA              => NULL,
                                                     INTEGRADORA            => NULL,
                                                     CONTRIBUINTE           => NULL,
                                                     QTD_REPROCESSAMENTO_NFE => NULL,
                                                     HORASAIDA               => NULL,
                                                     UIDREGISTRO             => NULL,
                                                     IDPARCEIRO             => NULL,
                                                     ASSINATURA             => NULL,
                                                     DATA_PEDIDO            => NULL,
                                                     CODCOBSEFAZ            => NULL,
                                                     DATACONSOLIDACAOPREFAT => NULL,
                                                     PREFATURAMENTO         => NULL,
                                                     NUMEMPENHO             => NULL,
                                                     CEP_ENT                => NULL,
                                                     INSCRICAO_ESTADUAL_ENT => NULL,
                                                     TELEFONE_ENT           => NULL,
                                                     CODIGO_PAIS_ENT        => NULL,
                                                     RAZAO_SOCIAL_REC_ENT   => NULL,
                                                     EMAIL_ENT              => NULL,
                                                     PAIS_ENT               => NULL,
                                                     UTILIZASRVTERCEIROS    => NULL,
                                                     ENVIADASEMRESPOSTA     => NULL,
                                                     IDESTRANGEIRO          => NULL,
                                                     CHAVEGERADATV14        => NULL,
                                                     CHAVENFETV14           => NULL,
                                                     CNPJ_CPF_RET           => NULL,
                                                     LOGRADOURO_RET         => NULL,
                                                     NUMERO_RET             => NULL,
                                                     COMPLEMENTO_RET        => NULL,
                                                     BAIRRO_RET             => NULL,
                                                     CODIGO_MUNICIPIO_RET   => NULL,
                                                     NOME_MUNICIPIO_RET     => NULL,
                                                     SIGLA_UF_RET           => NULL,
                                                     CEP_RET                => NULL,
                                                     INSCRICAO_ESTADUAL_RET => NULL,
                                                     TELEFONE_RET           => NULL,
                                                     CODIGO_PAIS_RET        => NULL, 
                                                     RAZAO_SOCIAL_RET       => NULL,
                                                     EMAIL_RET              => NULL,
                                                     PAIS_RET               => NULL,
                                                     CODIGO_NUMERICO_CHAVE  => NULL,
                                                     DESCINTERMEDIADOR      => NULL,
                                                     CNPJINTERMEDIADOR      => NULL);
                                                     
        RETORNO(RETORNO.COUNT).AMBIENTE               := CABECALHO.AMBIENTE;
        RETORNO(RETORNO.COUNT).BAIRRO_D               := CABECALHO.BAIRRO_D;
        RETORNO(RETORNO.COUNT).BAIRRO_E               := CABECALHO.BAIRRO_E;
        RETORNO(RETORNO.COUNT).CEP_D                  := CABECALHO.CEP_D;
        RETORNO(RETORNO.COUNT).CEP_E                  := CABECALHO.CEP_E;
        RETORNO(RETORNO.COUNT).CHAVENFE               := CABECALHO.CHAVENFE;
        RETORNO(RETORNO.COUNT).CNAE_E                 := CABECALHO.CNAE_E;
        RETORNO(RETORNO.COUNT).CNPJ_CPF_D             := CABECALHO.CNPJ_CPF_D;
        RETORNO(RETORNO.COUNT).CNPJ_E                 := CABECALHO.CNPJ_E;
        RETORNO(RETORNO.COUNT).CODCONT                := CABECALHO.CODCONT;
        RETORNO(RETORNO.COUNT).CODDOC                 := CABECALHO.CODDOC;
        RETORNO(RETORNO.COUNT).CODIGO_CLI             := CABECALHO.CODIGO_CLI;
        RETORNO(RETORNO.COUNT).CODIGO_EXPORTADOR      := CABECALHO.CODIGO_EXPORTADOR;
        RETORNO(RETORNO.COUNT).CODIGO_FABRICANTE_EX   := CABECALHO.CODIGO_FABRICANTE_EX;
        RETORNO(RETORNO.COUNT).CODIGO_FILIAL          := CABECALHO.CODIGO_FILIAL;
        RETORNO(RETORNO.COUNT).CODIGO_FISCAL          := CABECALHO.CODIGO_FISCAL;
        RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO_D     := CABECALHO.CODIGO_MUNICIPIO_D;
        RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO_E     := CABECALHO.CODIGO_MUNICIPIO_E;
        RETORNO(RETORNO.COUNT).CODIGO_PAIS_D          := CABECALHO.CODIGO_PAIS_D;
        RETORNO(RETORNO.COUNT).CODIGO_PAIS_E          := CABECALHO.CODIGO_PAIS_E;
        RETORNO(RETORNO.COUNT).COMPLEMENTO_D          := CABECALHO.COMPLEMENTO_D;
        RETORNO(RETORNO.COUNT).COMPLEMENTO_E          := CABECALHO.COMPLEMENTO_E;
        RETORNO(RETORNO.COUNT).CONDVENDA              := CABECALHO.CONDVENDA;
        RETORNO(RETORNO.COUNT).CONSUMIDOR_FINAL       := CABECALHO.CONSUMIDOR_FINAL;
        RETORNO(RETORNO.COUNT).CRT                    := CABECALHO.CRT;
        RETORNO(RETORNO.COUNT).TIPODESCARGA           := CABECALHO.TIPODESCARGA;
        RETORNO(RETORNO.COUNT).DATA_DESEMBARACO       := CABECALHO.DATA_DESEMBARACO;
        RETORNO(RETORNO.COUNT).DATA_EMISSAO           := CABECALHO.DATA_EMISSAO;
        RETORNO(RETORNO.COUNT).DATA_SAIDA             := CABECALHO.DATA_SAIDA;
        RETORNO(RETORNO.COUNT).DATA_SAIDA_DANFE       := CABECALHO.DATA_SAIDA_DANFE;
        RETORNO(RETORNO.COUNT).DATA_ENTREGA           := CABECALHO.DATA_ENTREGA;
        RETORNO(RETORNO.COUNT).DESTINOCARGA           := CABECALHO.DESTINOCARGA;
        RETORNO(RETORNO.COUNT).DTHORA_AUTORIZACAO     := CABECALHO.DTHORA_AUTORIZACAO;
        RETORNO(RETORNO.COUNT).DTHORA_CONTINGENCIA    := CABECALHO.DTHORA_CONTINGENCIA;
        RETORNO(RETORNO.COUNT).EMAIL_D                := CABECALHO.EMAIL_D;
        RETORNO(RETORNO.COUNT).EMAIL_E                := CABECALHO.EMAIL_E;
        RETORNO(RETORNO.COUNT).ENDERECO               := CABECALHO.ENDERECO;
        RETORNO(RETORNO.COUNT).ESPECIE                := CABECALHO.ESPECIE;
        RETORNO(RETORNO.COUNT).FAX_E                  := CABECALHO.FAX_E;
        RETORNO(RETORNO.COUNT).FINALIDADE             := CABECALHO.FINALIDADE;
        RETORNO(RETORNO.COUNT).HORA                   := CABECALHO.HORA;
        RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_D   := CABECALHO.INSCRICAO_ESTADUAL_D;
        RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_E   := CABECALHO.INSCRICAO_ESTADUAL_E;
        RETORNO(RETORNO.COUNT).INSCRICAO_MUNICIPAL_E  := CABECALHO.INSCRICAO_MUNICIPAL_E;
        RETORNO(RETORNO.COUNT).INSCRICAO_SUBSTITUTO_E := CABECALHO.INSCRICAO_SUBSTITUTO_E;
        RETORNO(RETORNO.COUNT).INSCRICAO_SUFRAMA_D    := CABECALHO.INSCRICAO_SUFRAMA_D;
        RETORNO(RETORNO.COUNT).JUSTIFICATIVA          := CABECALHO.JUSTIFICATIVA;
        RETORNO(RETORNO.COUNT).LOCAL_DESEMBARACO      := CABECALHO.LOCAL_DESEMBARACO;
        RETORNO(RETORNO.COUNT).LOGRADOURO_D           := CABECALHO.LOGRADOURO_D;
        RETORNO(RETORNO.COUNT).LOGRADOURO_E           := CABECALHO.LOGRADOURO_E;
        RETORNO(RETORNO.COUNT).MOVIMENTO              := CABECALHO.MOVIMENTO;
        RETORNO(RETORNO.COUNT).NATUREZA_OP            := CABECALHO.NATUREZA_OP;
        RETORNO(RETORNO.COUNT).NOME_FANTASIA_E        := CABECALHO.NOME_FANTASIA_E;
        RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_D       := CABECALHO.NOME_MUNICIPIO_D;
        RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_E       := CABECALHO.NOME_MUNICIPIO_E;
        RETORNO(RETORNO.COUNT).NOME_FANTASIA_D        := CABECALHO.NOME_FANTASIA_D;
        RETORNO(RETORNO.COUNT).NUM_DOC_IMPORTACAO     := CABECALHO.NUM_DOC_IMPORTACAO;
        RETORNO(RETORNO.COUNT).NUM_IMPRESSAO          := CABECALHO.NUM_IMPRESSAO;
        RETORNO(RETORNO.COUNT).NUM_PEDIDO             := CABECALHO.NUM_PEDIDO;
        RETORNO(RETORNO.COUNT).NUM_PEDIDO_CLI         := CABECALHO.NUM_PEDIDO_CLI;
        RETORNO(RETORNO.COUNT).NUM_TRANSACAO          := CABECALHO.NUM_TRANSACAO;
        RETORNO(RETORNO.COUNT).NUM_TRANSACAO_DEV      := CABECALHO.NUM_TRANSACAO_DEV;
        RETORNO(RETORNO.COUNT).NUM_TRANSACAO_ORIG     := CABECALHO.NUM_TRANSACAO_ORIG;
        RETORNO(RETORNO.COUNT).NUMERO_CAR             := CABECALHO.NUMERO_CAR;
        RETORNO(RETORNO.COUNT).NUMERO_D               := CABECALHO.NUMERO_D;
        RETORNO(RETORNO.COUNT).NUMERO_E               := CABECALHO.NUMERO_E;
        RETORNO(RETORNO.COUNT).NUMERO_NOTA            := CABECALHO.NUMERO_NOTA;
        RETORNO(RETORNO.COUNT).ORGAO_PUBLICO          := CABECALHO.ORGAO_PUBLICO;
        RETORNO(RETORNO.COUNT).PAIS_E                 := CABECALHO.PAIS_E;
        RETORNO(RETORNO.COUNT).PAIS_D                 := CABECALHO.PAIS_D;
        RETORNO(RETORNO.COUNT).PINCERTIFICADO         := CABECALHO.PINCERTIFICADO;
        RETORNO(RETORNO.COUNT).PROVIDERCERTIFICADOA3  := CABECALHO.PROVIDERCERTIFICADOA3;
        RETORNO(RETORNO.COUNT).PROTOCOLONFE           := CABECALHO.PROTOCOLONFE;
        RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_D         := CABECALHO.RAZAO_SOCIAL_D;
        RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_E         := CABECALHO.RAZAO_SOCIAL_E;
        RETORNO(RETORNO.COUNT).RCA                    := CABECALHO.RCA;
        RETORNO(RETORNO.COUNT).SERIALCERTIFICADO      := CABECALHO.SERIALCERTIFICADO;
        RETORNO(RETORNO.COUNT).SERIE                  := SUBSTR(CABECALHO.SERIE,1,3);
        RETORNO(RETORNO.COUNT).SERIE_SCAN             := CABECALHO.SERIE_SCAN;
        RETORNO(RETORNO.COUNT).SIGLA_UF_D             := CABECALHO.SIGLA_UF_D;
        RETORNO(RETORNO.COUNT).SIGLA_UF_DESEMBARACO   := CABECALHO.SIGLA_UF_DESEMBARACO;
        RETORNO(RETORNO.COUNT).SIGLA_UF_E             := CABECALHO.SIGLA_UF_E;
        RETORNO(RETORNO.COUNT).SITUACAONFE            := CABECALHO.SITUACAONFE;
        RETORNO(RETORNO.COUNT).TELEFONE_D             := CABECALHO.TELEFONE_D;
        RETORNO(RETORNO.COUNT).TELEFONE_E             := CABECALHO.TELEFONE_E;
        RETORNO(RETORNO.COUNT).TIPO_COBRANCA          := CABECALHO.TIPO_COBRANCA;
        RETORNO(RETORNO.COUNT).TIPO_DANFE             := CABECALHO.TIPO_DANFE;
        RETORNO(RETORNO.COUNT).TIPO_EMISSAO           := CABECALHO.TIPO_EMISSAO;
        RETORNO(RETORNO.COUNT).TIPO_EMPRESA           := CABECALHO.TIPO_EMPRESA;
        RETORNO(RETORNO.COUNT).TIPO_PESSOA            := CABECALHO.TIPO_PESSOA;
        RETORNO(RETORNO.COUNT).TIPO_PGTO              := CABECALHO.TIPO_PGTO;
        RETORNO(RETORNO.COUNT).TIPOPROVIDERA3         := CABECALHO.TIPOPROVIDERA3;
        RETORNO(RETORNO.COUNT).NUMPEDRCA              := CABECALHO.NUMPEDRCA;
        RETORNO(RETORNO.COUNT).CNPJ_CPF_ENT           := CABECALHO.CNPJ_CPF_ENT;
        RETORNO(RETORNO.COUNT).LOGRADOURO_ENT         := CABECALHO.LOGRADOURO_ENT;
        RETORNO(RETORNO.COUNT).NUMERO_ENT             := CABECALHO.NUMERO_ENT;
        RETORNO(RETORNO.COUNT).COMPLEMENTO_ENT        := CABECALHO.COMPLEMENTO_ENT;
        RETORNO(RETORNO.COUNT).BAIRRO_ENT             := CABECALHO.BAIRRO_ENT;
        RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_ENT     := CABECALHO.NOME_MUNICIPIO_ENT;
        RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO_ENT   := CABECALHO.CODIGO_MUNICIPIO_ENT;
        RETORNO(RETORNO.COUNT).SIGLA_UF_ENT           := CABECALHO.SIGLA_UF_ENT;
        RETORNO(RETORNO.COUNT).MOT_ESTORNONFE         := CABECALHO.MOT_ESTORNONFE;
        RETORNO(RETORNO.COUNT).SITUACAO_NFE_EPEC      := CABECALHO.SITUACAO_NFE_EPEC;
        RETORNO(RETORNO.COUNT).INDICADOR_PRESENCA     := CABECALHO.INDICADOR_PRESENCA;
        RETORNO(RETORNO.COUNT).TIPOVENDA              := CABECALHO.TIPOVENDA;
        RETORNO(RETORNO.COUNT).INTEGRADORA            := CABECALHO.INTEGRADORA;
        RETORNO(RETORNO.COUNT).CONTRIBUINTE           := CABECALHO.CONTRIBUINTE;
        RETORNO(RETORNO.COUNT).QTD_REPROCESSAMENTO_NFE:= CABECALHO.QTD_REPROCESSAMENTO_NFE;
        RETORNO(RETORNO.COUNT).HORASAIDA             := CABECALHO.HORASAIDA;
        RETORNO(RETORNO.COUNT).UIDREGISTRO           := CABECALHO.UIDREGISTRO;
        RETORNO(RETORNO.COUNT).IDPARCEIRO            := CABECALHO.IDPARCEIRO;
        RETORNO(RETORNO.COUNT).ASSINATURA            := CABECALHO.ASSINATURA;
        RETORNO(RETORNO.COUNT).DATA_PEDIDO           := CABECALHO.DATA_PEDIDO;
        RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT  := CABECALHO.DATACONSOLIDACAOPREFAT;
        RETORNO(RETORNO.COUNT).PREFATURAMENTO        := CABECALHO.PREFATURAMENTO;
        RETORNO(RETORNO.COUNT).NUMEMPENHO            := CABECALHO.NUMEMPENHO;
        RETORNO(RETORNO.COUNT).CEP_ENT               := CABECALHO.CEP_ENT;
        RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_ENT  := CABECALHO.INSCRICAO_ESTADUAL_ENT;
        RETORNO(RETORNO.COUNT).TELEFONE_ENT            := CABECALHO.TELEFONE_ENT;
        RETORNO(RETORNO.COUNT).CODIGO_PAIS_ENT         := CABECALHO.CODIGO_PAIS_ENT;
        RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_REC_ENT    := CABECALHO.RAZAO_SOCIAL_REC_ENT;
        RETORNO(RETORNO.COUNT).EMAIL_ENT               := CABECALHO.EMAIL_ENT;
        RETORNO(RETORNO.COUNT).PAIS_ENT                := CABECALHO.PAIS_ENT;
        RETORNO(RETORNO.COUNT).UTILIZASRVTERCEIROS     := CABECALHO.UTILIZASRVTERCEIROS;
        RETORNO(RETORNO.COUNT).ENVIADASEMRESPOSTA      := CABECALHO.ENVIADASEMRESPOSTA;
        RETORNO(RETORNO.COUNT).IDESTRANGEIRO           := CABECALHO.IDESTRANGEIRO;
        RETORNO(RETORNO.COUNT).CHAVEGERADATV14         := CABECALHO.CHAVEGERADATV14;
        RETORNO(RETORNO.COUNT).CHAVENFETV14            := CABECALHO.CHAVENFETV14;
        RETORNO(RETORNO.COUNT).CNPJ_CPF_RET            := NULL;
        RETORNO(RETORNO.COUNT).LOGRADOURO_RET          := NULL;
        RETORNO(RETORNO.COUNT).NUMERO_RET              := NULL;
        RETORNO(RETORNO.COUNT).COMPLEMENTO_RET         := NULL;
        RETORNO(RETORNO.COUNT).BAIRRO_RET              := NULL;
        RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO_RET    := NULL;
        RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_RET      := NULL;
        RETORNO(RETORNO.COUNT).SIGLA_UF_RET            := NULL;
        RETORNO(RETORNO.COUNT).CEP_RET                 := NULL;
        RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_RET  := NULL;
        RETORNO(RETORNO.COUNT).TELEFONE_RET            := NULL;
        RETORNO(RETORNO.COUNT).CODIGO_PAIS_RET         := NULL;
        RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_RET        := NULL;
        RETORNO(RETORNO.COUNT).EMAIL_RET               := NULL;
        RETORNO(RETORNO.COUNT).PAIS_RET                := NULL;
        RETORNO(RETORNO.COUNT).CODIGO_NUMERICO_CHAVE   := CABECALHO.CODIGO_NUMERICO_CHAVE;
        RETORNO(RETORNO.COUNT).DESCINTERMEDIADOR   := CABECALHO.DESCINTERMEDIADOR;
        RETORNO(RETORNO.COUNT).CNPJINTERMEDIADOR   := CABECALHO.CNPJINTERMEDIADOR;        
      END LOOP;
     END LOOP;
    END IF;
  END LOOP;

  CLOSE L_CURSOR;

  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;