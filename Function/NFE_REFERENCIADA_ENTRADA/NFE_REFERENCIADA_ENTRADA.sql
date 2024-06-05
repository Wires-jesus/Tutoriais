CREATE OR REPLACE FUNCTION NFE_REFERENCIADA_ENTRADA(P_TRANSACAO NUMBER)
  RETURN TABELA_NFE_NFREFERENCIADA IS

  --VARIAVEL EXCEPTION
  V_NOTA_REFERENCIADA_NAO_EXISTE EXCEPTION;

  V_TIPODESCARGA   PCNFENT.TIPODESCARGA%TYPE;
  V_FINALIDADENFE  PCNFENT.FINALIDADENFE%TYPE;
  V_NUMTRANSORIGEM PCNFENT.NUMTRANSORIGEM%TYPE;
  V_CODPRODUTORRURAL PCFORNEC.CODPRODUTORRURAL%TYPE;
  V_NUMTRANSVENDAORIGEM PCNFENT.NUMTRANSVENDAORIG%TYPE;
  V_MOTESTORNONFE      PCNFENT.MOTESTORNONFE%TYPE;
  V_QTDREGDOCREF NUMBER;

  NUMERO_TRANSACAO NUMBER;

  RETORNO TABELA_NFE_NFREFERENCIADA;

BEGIN
  BEGIN
    SELECT PCNFENT.TIPODESCARGA
          ,PCNFENT.FINALIDADENFE
          ,PCNFENT.NUMTRANSORIGEM
          ,PCFORNEC.CODPRODUTORRURAL
          ,PCNFENT.NUMTRANSVENDAORIG
          ,PCNFENT.MOTESTORNONFE
          ,DOCREFERENCIADO.QTDREG
    INTO   V_TIPODESCARGA
          ,V_FINALIDADENFE
          ,V_NUMTRANSORIGEM
          ,V_CODPRODUTORRURAL
          ,V_NUMTRANSVENDAORIGEM
          ,V_MOTESTORNONFE
          ,V_QTDREGDOCREF
    FROM   PCNFENT,
           PCCONSUM,
           PCFORNEC,
           (SELECT PCDOCREFERENCIADO.NUMTRANSACAO,
                   COUNT(PCDOCREFERENCIADO.NUMTRANSACAO) AS QTDREG
            FROM PCDOCREFERENCIADO
            WHERE 1=1
              AND PCDOCREFERENCIADO.TIPO = 'E'
              GROUP BY PCDOCREFERENCIADO.NUMTRANSACAO) DOCREFERENCIADO
    WHERE  NUMTRANSENT = P_TRANSACAO
    AND    PCNFENT.ESPECIE IN ('NE','NF','EI')
    AND    PCNFENT.CODFORNEC = PCFORNEC.CODFORNEC(+)
    AND    PCNFENT.NUMTRANSENT = DOCREFERENCIADO.NUMTRANSACAO(+)

    AND    ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       RAISE V_NOTA_REFERENCIADA_NAO_EXISTE;
    WHEN OTHERS THEN
       raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END;

  RETORNO := TABELA_NFE_NFREFERENCIADA();

  IF (V_QTDREGDOCREF > 0) THEN
    FOR NOTA IN (SELECT CASE 
                           WHEN (NVL(PCDOCREFERENCIADO.TIPODOCREF, -1) = 1) THEN     
                                PCDOCREFERENCIADO.CHAVECTEREF
                           WHEN (NVL(PCDOCREFERENCIADO.TIPODOCREF, -1) IN (6, 7)) THEN
                                PCDOCREFERENCIADO.CHAVENFCESATREF
                           ELSE 
                                PCDOCREFERENCIADO.CHAVENFEREF          
                        END AS CHAVE_ACESSO
                       ,PCDOCREFERENCIADO.CNPJEMITREF AS CNPJ_E
                       ,PCDOCREFERENCIADO.IEPRODRURAL AS IE
                       ,PCDOCREFERENCIADO.UFEMITREF AS SIGLA_UF
                       ,PCDOCREFERENCIADO.SERIEREF AS SERIE
                       ,PCDOCREFERENCIADO.MODELOREF AS MODELO
                       ,PCDOCREFERENCIADO.DTEMISSAOREF AS DATA_EMISSAO
                       ,DECODE(NVL(PCDOCREFERENCIADO.NUMNOTAREF,0),0,PCDOCREFERENCIADO.COOECFREF,NVL(PCDOCREFERENCIADO.NUMNOTAREF,0)) AS NUMERO_NOTA
                       ,PCDOCREFERENCIADO.TIPODOCREF AS DOCREF
                       ,PCDOCREFERENCIADO.NUMSEQECFREF AS NUMSEQECFREF
                       ,'N' PREFATURAMENTO
                       ,NULL DATACONSOLIDACAOPREFAT
                 FROM PCDOCREFERENCIADO
                 WHERE 1=1
                   AND PCDOCREFERENCIADO.NUMTRANSACAO = P_TRANSACAO)
    LOOP
          RETORNO.EXTEND;

          RETORNO(RETORNO.COUNT) := TIPO_NFE_NFREFERENCIADA(CHAVE_ACESSO => NULL,
                                                            CNPJ_E       => NULL,
                                                            IE           => NULL,
                                                            SIGLA_UF     => NULL,
                                                            SERIE        => NULL,
                                                            MODELO       => NULL,
                                                            DATA_EMISSAO => NULL,
                                                            NUMERO_NOTA  => NULL,
                                                            TIPO         => NULL,
                                                            DOCREF       => NULL,
                                                            NUMSEQECF    => NULL,
                                                            DATACONSOLIDACAOPREFAT => NULL,
                                                            PREFATURAMENTO => NULL
                                                            );

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E       := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE           := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF     := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE        := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO       := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA  := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO         := 0;
          RETORNO(RETORNO.COUNT).DOCREF       := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF    := NOTA.NUMSEQECFREF;
          RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
          RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;
    END LOOP;

    RETURN RETORNO;

  ELSE

    --  Nota de devolução
    IF (V_TIPODESCARGA IN ('6', '8', 'T', 'C') AND (NVL(V_FINALIDADENFE,'X') <> 'C')) THEN

      SELECT NVL((SELECT NVL(PCESTCOM.NUMTRANSVENDA,
                            0)
                 FROM   PCESTCOM
                 WHERE  PCESTCOM.NUMTRANSENT = P_TRANSACAO
                 AND    ROWNUM = 1),
                 0)
      INTO   NUMERO_TRANSACAO
      FROM   DUAL;

      FOR NOTA IN (SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFSAID.DTSAIDA AS DATA_EMISSAO
                         ,NVL(PCNFSAID.CHAVENFE, PCNFSAID.CHAVESAT) AS CHAVE_ACESSO 
                         ,PCNFSAID.IE
                         ,CASE
                            WHEN PCNFSAID.SERIE IN ('CF', 'CP') THEN
                             '2D'
                            ELSE
                             DECODE(NVL(PCNFSAID.CHAVENFE, DECODE(NVL(PCNFSAID.CHAVESAT, ''), '', 01)) , '01', '01', DECODE(NVL(PCNFSAID.CHAVENFE, ''), '', '59', 55))
                          END MODELO
                         ,DECODE(NVL(PCNFSAID.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFSAID.SERIE) AS SERIE
                         ,PCNFSAID.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFSAID.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                          ,LPAD(NVL(PCNFSAID.NUMCAIXAFISCAL,PCCAIXA.NUMCAIXAFISCAL), 3, '0') NUMSEQECF
                          ,'N' PREFATURAMENTO
                          ,PCNFSAID.DATACONSOLIDACAOPREFAT
                   FROM   PCNFSAID
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                         ,PCCAIXA
                   WHERE  NVL(PCNFSAID.CODFILIALNF,
                              PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFSAID.ESPECIE IN ('NF',
                                               'NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFSAID.NUMTRANSVENDA = NUMERO_TRANSACAO
                   AND    PCNFSAID.CAIXA = PCCAIXA.NUMCAIXA(+)
                   AND    NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCCAIXA.CODFILIAL(+)
                   UNION ALL
                   SELECT PCNFSAIDPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFSAIDPREFAT.DTSAIDA AS DATA_EMISSAO
                         ,NVL(PCNFSAIDPREFAT.CHAVENFE, PCNFSAIDPREFAT.CHAVESAT) AS CHAVE_ACESSO 
                         ,PCNFSAIDPREFAT.IE
                         ,CASE
                            WHEN PCNFSAIDPREFAT.SERIE IN ('CF', 'CP') THEN
                             '2D'
                            ELSE
                             DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE, DECODE(NVL(PCNFSAIDPREFAT.CHAVESAT, ''), '', 01)) , '01', '01', DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE, ''), '', '59', 55))
                          END MODELO
                         ,DECODE(NVL(PCNFSAIDPREFAT.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFSAIDPREFAT.SERIE) AS SERIE
                         ,PCNFSAIDPREFAT.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFSAIDPREFAT.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                          ,LPAD(NVL(PCNFSAIDPREFAT.NUMCAIXAFISCAL,PCCAIXA.NUMCAIXAFISCAL), 3, '0') NUMSEQECF
                          ,'S' PREFATURAMENTO
                          ,PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT
                   FROM   PCNFSAIDPREFAT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                         ,PCCAIXA
                   WHERE  NVL(PCNFSAIDPREFAT.CODFILIALNF,
                              PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFSAIDPREFAT.ESPECIE IN ('NF',
                                               'NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFSAIDPREFAT.NUMTRANSVENDA = NUMERO_TRANSACAO
                   AND    PCNFSAIDPREFAT.CAIXA = PCCAIXA.NUMCAIXA(+)
                   AND    NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) = PCCAIXA.CODFILIAL(+)
                   AND    PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                   )

      LOOP
        IF (NOTA.NUM_TRANSACAO > 0) THEN

          RETORNO.EXTEND;

          RETORNO(RETORNO.COUNT) := TIPO_NFE_NFREFERENCIADA(CHAVE_ACESSO => NULL,
                                                            CNPJ_E       => NULL,
                                                            IE           => NULL,
                                                            SIGLA_UF     => NULL,
                                                            SERIE        => NULL,
                                                            MODELO       => NULL,
                                                            DATA_EMISSAO => NULL,
                                                            NUMERO_NOTA  => NULL,
                                                            TIPO         => NULL,
                                                            DOCREF       => NULL,
                                                            NUMSEQECF    => NULL,
                                                            DATACONSOLIDACAOPREFAT => NULL,
                                                            PREFATURAMENTO => NULL
                                                            );

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E       := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE           := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF     := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE        := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO       := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA  := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO         := 0;
          RETORNO(RETORNO.COUNT).DOCREF       := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF    := NOTA.NUMSEQECF;
          RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
          RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

        END IF;
      END LOOP;

      RETURN RETORNO;
    END IF;

    -- Nota de produtor rural
    IF (V_CODPRODUTORRURAL IS NOT NULL) THEN

      FOR NOTA IN (SELECT PCNFENT.NUMTRANSENT AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(PCNFENT.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFENT.DTEMISSAOPRODRURAL AS DATA_EMISSAO
                         ,PCNFENT.CHAVENFEPRODRURAL AS CHAVE_ACESSO
                         ,NVL(PCFORNEC.CODPRODUTORRURAL, EMITENTE.CODPRODUTORRURAL) AS IE
                         ,DECODE(LPAD(NVL(PCNFENT.MODELOPRODRURAL,'04'),2,'0'),
                                 '01',
                                 '01',
                                 '04') AS MODELO
                         ,DECODE(NVL(PCNFENT.SERIEPRODRURAL,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFENT.SERIEPRODRURAL) AS SERIE
                         ,PCNFENT.NUMNOTAPRODRURAL AS NUMERO_NOTA
                         ,4 DOCREF
                         ,'0' NUMSEQECF
                         ,'N' PREFATURAMENTO
                         ,NULL DATACONSOLIDACAOPREFAT 
                   FROM   PCNFENT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL PF
                         ,PCFORNEC
                   WHERE  PF.CODFORNEC = EMITENTE.CODFORNEC
                   AND    NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PF.CODIGO
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFENT.ESPECIE IN ('NF', 'NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    NVL(PCNFENT.NUMNOTAPRODRURAL,0) > 0
                   AND    PCNFENT.CODFORNEC = PCFORNEC.CODFORNEC
                   AND    PCNFENT.NUMTRANSENT = P_TRANSACAO)

      LOOP
        IF (NOTA.NUM_TRANSACAO > 0) THEN

          RETORNO.EXTEND;

          RETORNO(RETORNO.COUNT) := TIPO_NFE_NFREFERENCIADA(CHAVE_ACESSO => NULL,
                                                            CNPJ_E       => NULL,
                                                            IE           => NULL,
                                                            SIGLA_UF     => NULL,
                                                            SERIE        => NULL,
                                                            MODELO       => NULL,
                                                            DATA_EMISSAO => NULL,
                                                            NUMERO_NOTA  => NULL,
                                                            TIPO         => NULL,
                                                            DOCREF       => NULL,
                                                            NUMSEQECF    => NULL,
                                                            DATACONSOLIDACAOPREFAT => NULL,
                                                            PREFATURAMENTO => NULL
                                                            );

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E       := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE           := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF     := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE        := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO       := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA  := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO         := 0;
          RETORNO(RETORNO.COUNT).DOCREF       := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF    := NOTA.NUMSEQECF;
          RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
          RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

        END IF;
      END LOOP;

      RETURN RETORNO;
    END IF;

    --  Nota de estorno de devolução 
    IF (V_MOTESTORNONFE IS NOT NULL) THEN

      NUMERO_TRANSACAO := V_NUMTRANSVENDAORIGEM;

      FOR NOTA IN (SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFSAID.DTSAIDA AS DATA_EMISSAO
                         ,PCNFSAID.CHAVENFE AS CHAVE_ACESSO
                         ,PCNFSAID.IE
                         ,DECODE(NVL(PCNFSAID.CHAVENFE,
                                     '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO
                         ,DECODE(NVL(PCNFSAID.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFSAID.SERIE) AS SERIE
                         ,PCNFSAID.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFSAID.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                          ,LPAD(NVL(PCNFSAID.NUMCAIXAFISCAL,PCNFSAID.CAIXA), 3, '0') NUMSEQECF
                          ,'N' PREFATURAMENTO
                          ,PCNFSAID.DATACONSOLIDACAOPREFAT
                   FROM   PCNFSAID
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFSAID.ESPECIE IN ('NF','NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFSAID.NUMTRANSVENDA = NUMERO_TRANSACAO
                   UNION ALL
                   SELECT PCNFSAIDPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFSAIDPREFAT.DTSAIDA AS DATA_EMISSAO
                         ,PCNFSAIDPREFAT.CHAVENFE AS CHAVE_ACESSO
                         ,PCNFSAIDPREFAT.IE
                         ,DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE,
                                     '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO
                         ,DECODE(NVL(PCNFSAIDPREFAT.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFSAIDPREFAT.SERIE) AS SERIE
                         ,PCNFSAIDPREFAT.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFSAIDPREFAT.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                          ,LPAD(NVL(PCNFSAIDPREFAT.NUMCAIXAFISCAL,PCNFSAIDPREFAT.CAIXA), 3, '0') NUMSEQECF
                          ,'S' PREFATURAMENTO
                          ,PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT
                   FROM   PCNFSAIDPREFAT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFSAIDPREFAT.ESPECIE IN ('NF','NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFSAIDPREFAT.NUMTRANSVENDA = NUMERO_TRANSACAO
                   AND    PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                   )

      LOOP
        IF (NOTA.NUM_TRANSACAO > 0) THEN

          RETORNO.EXTEND;
          RETORNO(RETORNO.COUNT) := TIPO_NFE_NFREFERENCIADA(CHAVE_ACESSO => NOTA.CHAVE_ACESSO,
                                                            CNPJ_E       => NOTA.CNPJ_E,
                                                            IE           => NOTA.IE,
                                                            SIGLA_UF     => NOTA.SIGLA_UF,
                                                            SERIE        => NOTA.SERIE,
                                                            MODELO       => NOTA.MODELO,
                                                            DATA_EMISSAO => NOTA.DATA_EMISSAO,
                                                            NUMERO_NOTA  => NOTA.NUMERO_NOTA,
                                                            TIPO         => 0,
                                                            DOCREF       => NOTA.DOCREF,
                                                            NUMSEQECF    => NOTA.NUMSEQECF,
                                                            DATACONSOLIDACAOPREFAT => NOTA.DATACONSOLIDACAOPREFAT,
                                                            PREFATURAMENTO => NOTA.PREFATURAMENTO);

        END IF;
      END LOOP;

      RETURN RETORNO;
    END IF;


    -- Nota complementar e ajuste
    IF (V_FINALIDADENFE IN ('C', 'A')) THEN

      NUMERO_TRANSACAO := V_NUMTRANSORIGEM;

      FOR NOTA IN (------------------------ENTRADA
                   SELECT PCNFENT.NUMTRANSENT AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFENT.DTENT AS DATA_EMISSAO
                         ,PCNFENT.CHAVENFE AS CHAVE_ACESSO
                         ,PCNFENT.IE
                         ,DECODE(NVL(PCNFENT.CHAVENFE,
                                     '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO
                         ,DECODE(NVL(PCNFENT.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFENT.SERIE) AS SERIE
                         ,PCNFENT.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFENT.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                         ,'0' NUMSEQECF
                         ,'N' PREFATURAMENTO
                         ,NULL DATACONSOLIDACAOPREFAT 
                   FROM   PCNFENT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFENT.CODFILIALNF,
                              PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFENT.ESPECIE IN ('NF',
                                              'NE','EI')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFENT.NUMTRANSENT = NUMERO_TRANSACAO
                   -------------------------
                   UNION
                   -------------------------SAIDA
                   SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFSAID.DTSAIDA AS DATA_EMISSAO
                         ,PCNFSAID.CHAVENFE AS CHAVE_ACESSO
                         ,PCNFSAID.IE
                         ,DECODE(NVL(PCNFSAID.CHAVENFE,
                                     '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO
                         ,DECODE(NVL(PCNFSAID.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFSAID.SERIE) AS SERIE
                         ,PCNFSAID.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFSAID.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                          ,LPAD(NVL(PCNFSAID.NUMCAIXAFISCAL,PCNFSAID.CAIXA), 3, '0') NUMSEQECF
                          ,'N' PREFATURAMENTO
                          ,PCNFSAID.DATACONSOLIDACAOPREFAT
                   FROM   PCNFSAID
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFSAID.CODFILIALNF,
                              PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFSAID.ESPECIE IN ('NF',
                                              'NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFSAID.NUMTRANSVENDA = NUMERO_TRANSACAO
                   AND    NOT EXISTS (SELECT COUNT(*) FROM   PCNFENT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFENT.CODFILIALNF,
                              PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFENT.ESPECIE IN ('NF',
                                              'NE','EI')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFENT.NUMTRANSENT = NUMERO_TRANSACAO)                   
                   ----------------------------                   
                   UNION
                   -------------------------SAIDA PREFAT
                   SELECT PCNFSAIDPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO
                         ,UF_E.UF AS SIGLA_UF
                         ,REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                  '.',
                                                  ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E
                         ,PCNFSAIDPREFAT.DTSAIDA AS DATA_EMISSAO
                         ,PCNFSAIDPREFAT.CHAVENFE AS CHAVE_ACESSO
                         ,PCNFSAIDPREFAT.IE
                         ,DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE,
                                     '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO
                         ,DECODE(NVL(PCNFSAIDPREFAT.SERIE,
                                     'U'),
                                 'U',
                                 '0',
                                 PCNFSAIDPREFAT.SERIE) AS SERIE
                         ,PCNFSAIDPREFAT.NUMNOTA AS NUMERO_NOTA
                         ,CASE WHEN LENGTH(PCNFSAIDPREFAT.CHAVENFE) = 44
                               THEN 1
                               ELSE 3
                          END DOCREF
                          ,LPAD(NVL(PCNFSAIDPREFAT.NUMCAIXAFISCAL,PCNFSAIDPREFAT.CAIXA), 3, '0') NUMSEQECF
                          ,'S' PREFATURAMENTO
                          ,PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT
                   FROM   PCNFSAIDPREFAT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFSAIDPREFAT.CODFILIALNF,
                              PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFSAIDPREFAT.ESPECIE IN ('NF',
                                              'NE')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFSAIDPREFAT.NUMTRANSVENDA = NUMERO_TRANSACAO
                   AND    NOT EXISTS (SELECT COUNT(*) FROM   PCNFENT
                         ,PCFORNEC EMITENTE
                         ,PCESTADO UF_E
                         ,PCCIDADE CIDADE_E
                         ,PCFILIAL
                   WHERE  NVL(PCNFENT.CODFILIALNF,
                              PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
                   AND    PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                   AND    EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                   AND    PCNFENT.ESPECIE IN ('NF',
                                              'NE','EI')
                   AND    CIDADE_E.UF = UF_E.UF
                   AND    PCNFENT.NUMTRANSENT = NUMERO_TRANSACAO)
                   AND    PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                   -------------------------
                   )

      LOOP
        IF (NOTA.NUM_TRANSACAO > 0) THEN

          RETORNO.EXTEND;

          RETORNO(RETORNO.COUNT) := TIPO_NFE_NFREFERENCIADA(CHAVE_ACESSO => NULL,
                                                            CNPJ_E       => NULL,
                                                            IE           => NULL,
                                                            SIGLA_UF     => NULL,
                                                            SERIE        => NULL,
                                                            MODELO       => NULL,
                                                            DATA_EMISSAO => NULL,
                                                            NUMERO_NOTA  => NULL,
                                                            TIPO         => NULL,
                                                            DOCREF       => NULL,
                                                            NUMSEQECF    => NULL,
                                                            DATACONSOLIDACAOPREFAT => NULL,
                                                            PREFATURAMENTO => NULL
                                                            );

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E       := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE           := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF     := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE        := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO       := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA  := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO         := 1;
          RETORNO(RETORNO.COUNT).DOCREF       := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF    := NOTA.NUMSEQECF;
          RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
          RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

        END IF;
      END LOOP;

      RETURN RETORNO;
    END IF;



    RETURN RETORNO;
  END IF;

EXCEPTION
  WHEN V_NOTA_REFERENCIADA_NAO_EXISTE THEN
    RETURN NULL;
  WHEN OTHERS THEN
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END; 
