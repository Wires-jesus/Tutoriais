CREATE OR REPLACE FUNCTION NFE_CABECALHO_ENTRADA(P_TIPO                 NUMBER DEFAULT 1,
                                                 P_QUANTIDADE_DIAS      NUMBER DEFAULT NULL,
                                                 P_QUANTIDADE_REGISTROS NUMBER DEFAULT NULL,
                                                 P_TRANSACOES           VARCHAR2 DEFAULT NULL,
                                                 P_FILIAIS              VARCHAR2 DEFAULT NULL)
  RETURN TABELA_NFE_CABECALHO IS
  CURSOR CR_CABECALHOS_NORMAL(PC_TRANSACAO NUMBER, P_CODFILIAL IN VARCHAR2) IS
        SELECT *
          FROM SQL_NFE_CABECALHO_ENTRADA CABECALHO
         WHERE CABECALHO.NUM_TRANSACAO = PC_TRANSACAO
           AND (P_CODFILIAL IS NULL OR
               CABECALHO.CODIGO_FILIAL = P_CODFILIAL)
       ---------------------------------------------------------------------
       -----------------validação de dados retroativos----------------------
       ------não mexer sem alinhar com eddy. critico------------------------
       AND NVL((SELECT CASE
                        WHEN (SELECT MAX(VERSAO) AS VERSAO
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
                                  AND LOWER(NOME) = LOWER('WINTHOR-FER-0820')) = '1.5.6.10' THEN
                        
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
       ORDER BY CABECALHO.NUMERO_NOTA
    ;

  CURSOR CR_CABECALHOS_DEV(PC_TRANSACAO NUMBER, P_CODFILIAL IN VARCHAR2) IS
    SELECT *
      FROM SQL_NFE_CABECALHO_ENTRADA_DEV CABECALHO
     WHERE CABECALHO.NUM_TRANSACAO = PC_TRANSACAO
       AND (P_CODFILIAL IS NULL OR
           CABECALHO.CODIGO_FILIAL = P_CODFILIAL)
       ---------------------------------------------------------------------
       -----------------validação de dados retroativos----------------------
       ------não mexer sem alinhar com eddy. critico------------------------
       AND NVL((SELECT CASE
                        WHEN (SELECT VERSAO
                                FROM PCWTASNAPSHOTSTATE
                               WHERE UPPER(NOME) = 'WINTHOR-FER-0820'
                                 AND SNAPSHOTID =
                                     (SELECT ID
                                        FROM (SELECT ID
                                                FROM PCWTASNAPSHOT
                                               ORDER BY DATACRIACAO DESC)
                                       WHERE ROWNUM = 1)) = '1.5.6.10' THEN
                        
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
       ORDER BY CABECALHO.NUMERO_NOTA
    ;
     
  RETORNO     TABELA_NFE_CABECALHO;
  NOVO_NUMERO NUMBER;
  L_CURSOR    SYS_REFCURSOR;
  VFILIAL  VARCHAR2(10);
BEGIN
  RETORNO := TABELA_NFE_CABECALHO();
  IF P_TIPO = 1 THEN
    OPEN L_CURSOR FOR
      SELECT *
        FROM (SELECT PCNFENT.NUMTRANSENT AS NUM_TRANSACAO
                FROM PCNFENT, PCFILIAL, PCFORNEC EMITENTE
               WHERE EMITENTE.CODFORNEC = PCFILIAL.CODFORNEC
                 AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCFILIAL.CODIGO           
                 AND (COALESCE(PCFILIAL.UTILIZANFE, 'N') = 'S')           
                 AND ((PCNFENT.ESPECIE = 'NE') OR 
                      ((PCNFENT.ESPECIE = 'NF') AND
                       ((PCNFENT.TIPOEMISSAO IN ('2', '5')))))
                 AND NVL(PCNFENT.ENVIADA, 'N') = 'N'
                 AND NVL(PCNFENT.OBS, ' ') <> 'NF CANCELADA'
                 AND (NVL(PCNFENT.GERANFVENDA, 'N') = 'S' OR NVL(PCNFENT.GERANFDEVCLI, 'N') = 'S')
                 AND TRUNC(PCNFENT.DTEMISSAO) BETWEEN
                     TRUNC(SYSDATE) - P_QUANTIDADE_DIAS AND TRUNC(SYSDATE)
                 AND PCNFENT.SITUACAONFE IN (0, 124)
               ORDER BY NVL(PCNFENT.QTDEREPROCNFE, 0), PCNFENT.TIPOEMISSAO, PCNFENT.NUMTRANSENT ) TB
       WHERE 1 = 1
         AND ROWNUM <= P_QUANTIDADE_REGISTROS;
  ELSE
    OPEN L_CURSOR FOR 'SELECT ' || REPLACE(P_TRANSACOES,
                                           ',',
                                           ' FROM DUAL UNION SELECT ') || ' FROM DUAL';
  END IF;
  LOOP
    FETCH L_CURSOR
      INTO NOVO_NUMERO;
    EXIT WHEN L_CURSOR%NOTFOUND;
     for dados in (select valor as codfilial from table(lista_DE_strings(DECODE(p_filiais,NULL,'SEMFILIAL',p_filiais))))
      loop
      
      IF dados.codfilial = 'SEMFILIAL' THEN
        VFILIAL := NULL;
      ELSE
        VFILIAL := dados.codfilial;
      END IF;
      
    FOR CABECALHO IN CR_CABECALHOS_NORMAL(NOVO_NUMERO, VFILIAL) LOOP
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
                                                   NOME_FANTASIA_D        => NULL,
                                                   NOME_MUNICIPIO_D       => NULL,
                                                   NOME_MUNICIPIO_E       => NULL,
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
                                                   HORASAIDA              => NULL,
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
      RETORNO(RETORNO.COUNT).NOME_FANTASIA_D        := CABECALHO.NOME_FANTASIA_D;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_D       := CABECALHO.NOME_MUNICIPIO_D;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_E       := CABECALHO.NOME_MUNICIPIO_E;
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
      RETORNO(RETORNO.COUNT).SERIE                  := CABECALHO.SERIE;
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
      RETORNO(RETORNO.COUNT).TIPOVENDA              := 'X';
      RETORNO(RETORNO.COUNT).TIPOVENDA              := 'X';
      RETORNO(RETORNO.COUNT).CONTRIBUINTE           := CABECALHO.CONTRIBUINTE;
      RETORNO(RETORNO.COUNT).QTD_REPROCESSAMENTO_NFE:= CABECALHO.QTD_REPROCESSAMENTO_NFE;
      RETORNO(RETORNO.COUNT).HORASAIDA              := CABECALHO.HORA;
      RETORNO(RETORNO.COUNT).CODCOBSEFAZ            := CABECALHO.CODCOBSEFAZ;
      RETORNO(RETORNO.COUNT).NUMEMPENHO             := CABECALHO.NUMEMPENHO;
      RETORNO(RETORNO.COUNT).CEP_ENT                := NULL;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_ENT  := NULL;
      RETORNO(RETORNO.COUNT).TELEFONE_ENT            := NULL;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS_ENT         := NULL;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_REC_ENT    := NULL;
      RETORNO(RETORNO.COUNT).EMAIL_ENT               := NULL;
      RETORNO(RETORNO.COUNT).PAIS_ENT                := NULL;
      RETORNO(RETORNO.COUNT).UTILIZASRVTERCEIROS     := NULL;
      RETORNO(RETORNO.COUNT).ENVIADASEMRESPOSTA      := CABECALHO.ENVIADASEMRESPOSTA;  
      RETORNO(RETORNO.COUNT).IDESTRANGEIRO           := NULL;               
      RETORNO(RETORNO.COUNT).CHAVEGERADATV14         := NULL;
      RETORNO(RETORNO.COUNT).CHAVENFETV14            := NULL;
      RETORNO(RETORNO.COUNT).CNPJ_CPF_RET            := CABECALHO.CNPJ_CPF_RET;
      RETORNO(RETORNO.COUNT).LOGRADOURO_RET          := CABECALHO.LOGRADOURO_RET;
      RETORNO(RETORNO.COUNT).NUMERO_RET              := CABECALHO.NUMERO_RET;
      RETORNO(RETORNO.COUNT).COMPLEMENTO_RET         := CABECALHO.COMPLEMENTO_RET;
      RETORNO(RETORNO.COUNT).BAIRRO_RET              := CABECALHO.BAIRRO_RET;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO_RET    := CABECALHO.CODIGO_MUNICIPIO_RET;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_RET      := CABECALHO.NOME_MUNICIPIO_RET;
      RETORNO(RETORNO.COUNT).SIGLA_UF_RET            := CABECALHO.SIGLA_UF_RET;
      RETORNO(RETORNO.COUNT).CEP_RET                 := CABECALHO.CEP_RET;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_RET  := CABECALHO.INSCRICAO_ESTADUAL_RET;
      RETORNO(RETORNO.COUNT).TELEFONE_RET            := CABECALHO.TELEFONE_RET;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS_RET         := CABECALHO.CODIGO_PAIS_RET;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_RET        := CABECALHO.RAZAO_SOCIAL_RET;
      RETORNO(RETORNO.COUNT).EMAIL_RET               := CABECALHO.EMAIL_RET;
      RETORNO(RETORNO.COUNT).PAIS_RET                := CABECALHO.PAIS_RET;
      RETORNO(RETORNO.COUNT).CODIGO_NUMERICO_CHAVE   := CABECALHO.CODIGO_NUMERICO_CHAVE;
      RETORNO(RETORNO.COUNT).DESCINTERMEDIADOR   := CABECALHO.DESCINTERMEDIADOR;
      RETORNO(RETORNO.COUNT).CNPJINTERMEDIADOR   := CABECALHO.CNPJINTERMEDIADOR;
      
    END LOOP;
    end loop;
  END LOOP;
  CLOSE L_CURSOR;
  IF P_TIPO = 1 THEN
    OPEN L_CURSOR FOR
      SELECT PCNFENT.NUMTRANSENT AS NUM_TRANSACAO
        FROM PCNFENT, PCFILIAL, PCFORNEC EMITENTE, PCCLIENT DESTINATARIO
       WHERE EMITENTE.CODFORNEC = PCFILIAL.CODFORNEC
         AND DESTINATARIO.CODCLI = PCNFENT.CODFORNEC
         AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
         AND NVL(PCFILIAL.UTILIZANFE, 'N') = 'S'
         AND ((PCNFENT.ESPECIE = 'NE') OR
             (PCNFENT.ESPECIE = 'NF' AND PCNFENT.TIPOEMISSAO IN ('2', '5') AND
             NVL(PCNFENT.ENVIADA, 'N') = 'N'))
         AND NVL(PCNFENT.OBS, ' ') <> 'NF CANCELADA'
         AND NVL(PCNFENT.GERANFDEVCLI, 'N') = 'S'
         AND (TRUNC(PCNFENT.DTEMISSAO) BETWEEN
             TRUNC(SYSDATE - P_QUANTIDADE_DIAS) AND TRUNC(SYSDATE))
         AND PCNFENT.SITUACAONFE IN (0,124)
         AND ROWNUM <= P_QUANTIDADE_REGISTROS
       ORDER BY NUM_TRANSACAO;
  ELSE
    OPEN L_CURSOR FOR 'SELECT ' || REPLACE(P_TRANSACOES,
                                           ',',
                                           ' FROM DUAL UNION SELECT ') || ' FROM DUAL';
  END IF;
  LOOP
    FETCH L_CURSOR
      INTO NOVO_NUMERO;
    EXIT WHEN L_CURSOR%NOTFOUND;
     for dados in (select valor as codfilial from table(lista_DE_strings(DECODE(p_filiais,NULL,'SEMFILIAL',p_filiais))))
      loop
      
       IF dados.codfilial = 'SEMFILIAL' THEN
        VFILIAL := NULL;
       ELSE
        VFILIAL := dados.codfilial;
       END IF;
      
    FOR CABECALHO IN CR_CABECALHOS_DEV(NOVO_NUMERO, VFILIAL) LOOP
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
                                                   NOME_FANTASIA_D        => NULL,
                                                   NOME_MUNICIPIO_D       => NULL,
                                                   NOME_MUNICIPIO_E       => NULL,
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
                                                   HORASAIDA              => NULL,
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
      RETORNO(RETORNO.COUNT).NOME_FANTASIA_D        := CABECALHO.NOME_FANTASIA_D;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_D       := CABECALHO.NOME_MUNICIPIO_D;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_E       := CABECALHO.NOME_MUNICIPIO_E;
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
      RETORNO(RETORNO.COUNT).SERIE                  := CABECALHO.SERIE;
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
      RETORNO(RETORNO.COUNT).TIPOVENDA              := 'X';
      RETORNO(RETORNO.COUNT).CONTRIBUINTE           := CABECALHO.CONTRIBUINTE;     
      RETORNO(RETORNO.COUNT).QTD_REPROCESSAMENTO_NFE:= CABECALHO.QTD_REPROCESSAMENTO_NFE; 
      RETORNO(RETORNO.COUNT).HORASAIDA              := CABECALHO.HORA;   
      RETORNO(RETORNO.COUNT).CODCOBSEFAZ            := CABECALHO.CODCOBSEFAZ; 
      RETORNO(RETORNO.COUNT).NUMEMPENHO             := CABECALHO.NUMEMPENHO;
      RETORNO(RETORNO.COUNT).CEP_ENT                := NULL;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_ENT  := NULL;
      RETORNO(RETORNO.COUNT).TELEFONE_ENT            := NULL;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS_ENT         := NULL;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_REC_ENT    := NULL;
      RETORNO(RETORNO.COUNT).EMAIL_ENT               := NULL;
      RETORNO(RETORNO.COUNT).PAIS_ENT                := NULL;
      RETORNO(RETORNO.COUNT).UTILIZASRVTERCEIROS     := NULL;
      RETORNO(RETORNO.COUNT).ENVIADASEMRESPOSTA      := CABECALHO.ENVIADASEMRESPOSTA; 
      RETORNO(RETORNO.COUNT).IDESTRANGEIRO           := CABECALHO.IDESTRANGEIRO;    
      RETORNO(RETORNO.COUNT).CHAVEGERADATV14         := NULL;
      RETORNO(RETORNO.COUNT).CHAVENFETV14            := NULL;
      RETORNO(RETORNO.COUNT).CNPJ_CPF_RET            := CABECALHO.CNPJ_CPF_RET;
      RETORNO(RETORNO.COUNT).LOGRADOURO_RET          := CABECALHO.LOGRADOURO_RET;
      RETORNO(RETORNO.COUNT).NUMERO_RET              := CABECALHO.NUMERO_RET;
      RETORNO(RETORNO.COUNT).COMPLEMENTO_RET         := CABECALHO.COMPLEMENTO_RET;
      RETORNO(RETORNO.COUNT).BAIRRO_RET              := CABECALHO.BAIRRO_RET;
      RETORNO(RETORNO.COUNT).CODIGO_MUNICIPIO_RET    := CABECALHO.CODIGO_MUNICIPIO_RET;
      RETORNO(RETORNO.COUNT).NOME_MUNICIPIO_RET      := CABECALHO.NOME_MUNICIPIO_RET;
      RETORNO(RETORNO.COUNT).SIGLA_UF_RET            := CABECALHO.SIGLA_UF_RET;
      RETORNO(RETORNO.COUNT).CEP_RET                 := CABECALHO.CEP_RET;
      RETORNO(RETORNO.COUNT).INSCRICAO_ESTADUAL_RET  := CABECALHO.INSCRICAO_ESTADUAL_RET;
      RETORNO(RETORNO.COUNT).TELEFONE_RET            := CABECALHO.TELEFONE_RET;
      RETORNO(RETORNO.COUNT).CODIGO_PAIS_RET         := CABECALHO.CODIGO_PAIS_RET;
      RETORNO(RETORNO.COUNT).RAZAO_SOCIAL_RET        := CABECALHO.RAZAO_SOCIAL_RET;
      RETORNO(RETORNO.COUNT).EMAIL_RET               := CABECALHO.EMAIL_RET;
      RETORNO(RETORNO.COUNT).PAIS_RET                := CABECALHO.PAIS_RET;  
      RETORNO(RETORNO.COUNT).CODIGO_NUMERICO_CHAVE   := CABECALHO.CODIGO_NUMERICO_CHAVE;
      RETORNO(RETORNO.COUNT).DESCINTERMEDIADOR   := CABECALHO.DESCINTERMEDIADOR;
      RETORNO(RETORNO.COUNT).CNPJINTERMEDIADOR   := CABECALHO.CNPJINTERMEDIADOR;      
      
    END LOOP;
    end loop;
  END LOOP;
  CLOSE L_CURSOR;
  RETURN RETORNO;
EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;