CREATE OR REPLACE FUNCTION NFE_REFERENCIADA_SAIDA(P_TRANSACAO NUMBER)
  RETURN TABELA_NFE_NFREFERENCIADA IS

  --VARIAVEL EXCEPTION
  V_NOTA_REFERENCIADA_NAO_EXISTE EXCEPTION;

  V_FINALIDADENFE      PCNFSAID.FINALIDADENFE%TYPE;
  V_NUMTRANSORIGEM     PCNFSAID.NUMTRANSVENDAORIGEM%TYPE;
  V_TIPOVENDA          PCNFSAID.TIPOVENDA%TYPE;
  V_QTDREGDOCREF NUMBER;
  
  NUMERO_TRANSACAO NUMBER;

  RETORNO TABELA_NFE_NFREFERENCIADA;
  V_CONT_NOTA_SAIDA number(18,0);
  V_PREFATURAMENTO varchar2(1);

BEGIN
  BEGIN
    V_CONT_NOTA_SAIDA := 0;
    
    FOR NOTA_SAIDA IN (
      SELECT PCNFSAID.TIPOVENDA,
             PCNFSAID.FINALIDADENFE,
             PCNFSAID.NUMTRANSVENDAORIGEM,
             DOCREFERENCIADO.QTDREG,
             'N' PREFATURAMENTO
        FROM PCNFSAID,
         (SELECT PCDOCREFERENCIADO.NUMTRANSACAO,
                     COUNT(PCDOCREFERENCIADO.NUMTRANSACAO) AS QTDREG
              FROM PCDOCREFERENCIADO
              WHERE 1=1
                AND PCDOCREFERENCIADO.TIPO = 'S'
                GROUP BY PCDOCREFERENCIADO.NUMTRANSACAO) DOCREFERENCIADO
       WHERE PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
         AND PCNFSAID.NUMTRANSVENDA = DOCREFERENCIADO.NUMTRANSACAO(+)
         AND ROWNUM = 1
      UNION ALL
      SELECT PCNFSAIDPREFAT.TIPOVENDA,
             PCNFSAIDPREFAT.FINALIDADENFE,
             PCNFSAIDPREFAT.NUMTRANSVENDAORIGEM,
             DOCREFERENCIADO.QTDREG,
             'S' PREFATURAMENTO
        FROM PCNFSAIDPREFAT,
         (SELECT PCDOCREFERENCIADO.NUMTRANSACAO,
                     COUNT(PCDOCREFERENCIADO.NUMTRANSACAO) AS QTDREG
              FROM PCDOCREFERENCIADO
              WHERE 1=1
                AND PCDOCREFERENCIADO.TIPO = 'S'
                GROUP BY PCDOCREFERENCIADO.NUMTRANSACAO) DOCREFERENCIADO
       WHERE PCNFSAIDPREFAT.NUMTRANSVENDA = P_TRANSACAO
         AND PCNFSAIDPREFAT.NUMTRANSVENDA = DOCREFERENCIADO.NUMTRANSACAO(+)
         AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
         AND ROWNUM = 1
      ) Loop
          V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;
          V_TIPOVENDA       := NOTA_SAIDA.TIPOVENDA;
          V_FINALIDADENFE   := NOTA_SAIDA.FINALIDADENFE;
          V_NUMTRANSORIGEM  := NOTA_SAIDA.NUMTRANSVENDAORIGEM;
          V_QTDREGDOCREF    := NOTA_SAIDA.QTDREG;
          V_PREFATURAMENTO  := NOTA_SAIDA.PREFATURAMENTO;
      end Loop;
      
      if (V_CONT_NOTA_SAIDA <= 0) then
        raise NO_DATA_FOUND;
      end if;
      
      if (V_CONT_NOTA_SAIDA > 1) then
        raise_application_error(-20001,
                              'Erro motivo: Registro na tabela PCNFSAID com este número de transação está duplicado na PCNFSAIDPREFAT. Transação: ' ||
                              P_TRANSACAO);
      end if;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE V_NOTA_REFERENCIADA_NAO_EXISTE;
    WHEN OTHERS THEN
      raise_application_error(-20001,
                              'Erro motivo: ' || SQLERRM || '. Linha: ' ||
                              DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END;

  RETORNO := TABELA_NFE_NFREFERENCIADA();

  IF (V_QTDREGDOCREF > 0) THEN
    FOR NOTA IN (SELECT CASE 
                           WHEN (NVL(PCDOCREFERENCIADO.TIPODOCREF, -1) = 1) THEN     
                                PCDOCREFERENCIADO.CHAVECTEREF
                           WHEN (NVL(PCDOCREFERENCIADO.TIPODOCREF, -1) IN (6, 7, 8)) THEN
                                PCDOCREFERENCIADO.CHAVENFCESATREF
                           ELSE 
                                PCDOCREFERENCIADO.CHAVENFEREF          
                        END AS CHAVE_ACESSO,
                        PCDOCREFERENCIADO.CNPJEMITREF AS CNPJ_E,
                        PCDOCREFERENCIADO.IEPRODRURAL AS IE,
                        PCDOCREFERENCIADO.UFEMITREF AS SIGLA_UF,
                        PCDOCREFERENCIADO.SERIEREF AS SERIE,
                        PCDOCREFERENCIADO.MODELOREF AS MODELO,
                        PCDOCREFERENCIADO.DTEMISSAOREF AS DATA_EMISSAO,
                        DECODE(NVL(PCDOCREFERENCIADO.NUMNOTAREF, 0),0,PCDOCREFERENCIADO.COOECFREF,NVL(PCDOCREFERENCIADO.NUMNOTAREF, 0)) AS NUMERO_NOTA,
                        PCDOCREFERENCIADO.TIPODOCREF AS DOCREF,
                        PCDOCREFERENCIADO.NUMSEQECFREF AS NUMSEQECFREF,
                        NULL DATACONSOLIDACAOPREFAT,
                        NULL PREFATURAMENTO
                   FROM PCDOCREFERENCIADO
                  WHERE 1 = 1
                    AND PCDOCREFERENCIADO.NUMTRANSACAO = P_TRANSACAO) LOOP
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
                                                        PREFATURAMENTO => NULL);

      RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
      RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
      RETORNO(RETORNO.COUNT).IE := NOTA.IE;
      RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
      RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
      RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
      RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
      RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
      RETORNO(RETORNO.COUNT).TIPO := 0;
      RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
      RETORNO(RETORNO.COUNT).NUMSEQECF := NOTA.NUMSEQECFREF;
      RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
      RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;
    END LOOP;

    RETURN RETORNO;

  ELSE
    BEGIN
      for PEDIDO IN (SELECT NVL(NUMTRANSVENDA, 0) AS NUMTRANSVENDA
                       FROM PCPEDC
                      WHERE PCPEDC.NUMCAR IN
                            (SELECT PCPEDC.NUMCARMANIF
                               FROM PCPEDC
                              WHERE NUMPED IN
                                    (SELECT C.NUMPED
                                       FROM PCNFSAID C
                                      WHERE C.NUMTRANSVENDA = P_TRANSACAO
                                     UNION ALL
                                     SELECT C.NUMPED
                                       FROM PCNFSAIDPREFAT C
                                      WHERE C.NUMTRANSVENDA = P_TRANSACAO
                                        AND C.DATACONSOLIDACAOPREFAT IS NULL
                                     )
                                AND PCPEDC.NUMCARMANIF > 0)
                        AND PCPEDC.CONDVENDA = 13) loop
        IF (PEDIDO.NUMTRANSVENDA IS NOT NULL) THEN
          BEGIN
            NUMERO_TRANSACAO := PEDIDO.NUMTRANSVENDA;

            FOR NOTA IN (SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO,
                                UF_E.UF AS SIGLA_UF,
                                REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                        '.',
                                                        ''),
                                                '/',
                                                ''),
                                        '-',
                                        '') AS CNPJ_E,
                                PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                                PCNFSAID.CHAVENFE AS CHAVE_ACESSO,
                                PCNFSAID.IE,
                                DECODE(NVL(PCNFSAID.CHAVENFE, '01'),
                                       '01',
                                       '01',
                                       '55') AS MODELO,
                                DECODE(NVL(PCNFSAID.SERIE, 'U'),
                                       'U',
                                       '0',
                                       PCNFSAID.SERIE) AS SERIE,
                                PCNFSAID.NUMNOTA AS NUMERO_NOTA,
                                CASE
                                  WHEN LENGTH(PCNFSAID.CHAVENFE) = 44 THEN
                                   1
                                  ELSE
                                   3
                                END DOCREF,
                                'N' PREFATURAMENTO,
                                PCNFSAID.DATACONSOLIDACAOPREFAT
                           FROM PCNFSAID,
                                PCFORNEC EMITENTE,
                                PCESTADO UF_E,
                                PCCIDADE CIDADE_E,
                                PCFILIAL
                          WHERE NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                                PCFILIAL.CODIGO
                            AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                            AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                            AND PCNFSAID.SERIE <> 'CF'
                            AND PCNFSAID.ESPECIE IN ('NF', 'NE')
                            AND CIDADE_E.UF = UF_E.UF
                            AND PCNFSAID.NUMTRANSVENDA = NUMERO_TRANSACAO
                         UNION ALL
                         SELECT PCNFSAIDPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO,
                                UF_E.UF AS SIGLA_UF,
                                REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                        '.',
                                                        ''),
                                                '/',
                                                ''),
                                        '-',
                                        '') AS CNPJ_E,
                                PCNFSAIDPREFAT.DTSAIDA AS DATA_EMISSAO,
                                PCNFSAIDPREFAT.CHAVENFE AS CHAVE_ACESSO,
                                PCNFSAIDPREFAT.IE,
                                DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE, '01'),
                                       '01',
                                       '01',
                                       '55') AS MODELO,
                                DECODE(NVL(PCNFSAIDPREFAT.SERIE, 'U'),
                                       'U',
                                       '0',
                                       PCNFSAIDPREFAT.SERIE) AS SERIE,
                                PCNFSAIDPREFAT.NUMNOTA AS NUMERO_NOTA,
                                CASE
                                  WHEN LENGTH(PCNFSAIDPREFAT.CHAVENFE) = 44 THEN
                                   1
                                  ELSE
                                   3
                                END DOCREF,
                                'S' PREFATURAMENTO,
                                PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT
                           FROM PCNFSAIDPREFAT,
                                PCFORNEC EMITENTE,
                                PCESTADO UF_E,
                                PCCIDADE CIDADE_E,
                                PCFILIAL
                          WHERE NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) =
                                PCFILIAL.CODIGO
                            AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                            AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                            AND PCNFSAIDPREFAT.SERIE <> 'CF'
                            AND PCNFSAIDPREFAT.ESPECIE IN ('NF', 'NE')
                            AND CIDADE_E.UF = UF_E.UF
                            AND PCNFSAIDPREFAT.NUMTRANSVENDA = NUMERO_TRANSACAO
                            AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
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
                                                                  PREFATURAMENTO => NULL);

                RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
                RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
                RETORNO(RETORNO.COUNT).IE := NOTA.IE;
                RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
                RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
                RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
                RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
                RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
                RETORNO(RETORNO.COUNT).TIPO := 1;
                RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
                RETORNO(RETORNO.COUNT).NUMSEQECF := NULL;
                RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
                RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

              END IF;
            END LOOP;
          END;
        END IF;
      end loop;
    END;

    -- Chave referenciada TV20 HIS.05355.2014
    BEGIN
      for PEDIDO IN (SELECT NVL(NUMTRANSVENDA, 0) AS NUMTRANSVENDA
                       FROM PCNFSAID
                      WHERE NUMNOTA =
                            (SELECT PCPEDC.NUMNOTACONSIG
                               FROM PCPEDC

                              WHERE PCPEDC.NUMTRANSVENDA = P_TRANSACAO
                                AND ROWNUM = 1)
                        AND PCNFSAID.CONDVENDA = 20
                     UNION ALL
                     SELECT NVL(NUMTRANSVENDA, 0) AS NUMTRANSVENDA
                       FROM PCNFSAIDPREFAT
                      WHERE NUMNOTA =
                            (SELECT PCPEDC.NUMNOTACONSIG
                               FROM PCPEDC

                              WHERE PCPEDC.NUMTRANSVENDA = P_TRANSACAO
                                AND ROWNUM = 1)
                        AND PCNFSAIDPREFAT.CONDVENDA = 20
                        AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                        ) loop
        IF (PEDIDO.NUMTRANSVENDA IS NOT NULL) THEN
          BEGIN
            NUMERO_TRANSACAO := PEDIDO.NUMTRANSVENDA;

            FOR NOTA IN (SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO,
                                UF_E.UF AS SIGLA_UF,
                                REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                        '.',
                                                        ''),
                                                '/',
                                                ''),
                                        '-',
                                        '') AS CNPJ_E,
                                PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                                PCNFSAID.CHAVENFE AS CHAVE_ACESSO,
                                PCNFSAID.IE,
                                DECODE(NVL(PCNFSAID.CHAVENFE, '01'),
                                       '01',
                                       '01',
                                       '55') AS MODELO,
                                DECODE(NVL(PCNFSAID.SERIE, 'U'),
                                       'U',
                                       '0',
                                       PCNFSAID.SERIE) AS SERIE,
                                PCNFSAID.NUMNOTA AS NUMERO_NOTA,
                                CASE
                                  WHEN LENGTH(PCNFSAID.CHAVENFE) = 44 THEN
                                   1
                                  ELSE
                                   3
                                END DOCREF,
                                'N' PREFATURAMENTO,
                                PCNFSAID.DATACONSOLIDACAOPREFAT
                           FROM PCNFSAID,
                                PCFORNEC EMITENTE,
                                PCESTADO UF_E,
                                PCCIDADE CIDADE_E,
                                PCFILIAL
                          WHERE NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                                PCFILIAL.CODIGO
                            AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                            AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                            AND PCNFSAID.SERIE <> 'CF'
                            AND PCNFSAID.ESPECIE IN ('NF', 'NE')
                            AND CIDADE_E.UF = UF_E.UF
                            AND PCNFSAID.NUMTRANSVENDA = NUMERO_TRANSACAO
                         UNION ALL
                         SELECT PCNFSAIDPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO,
                                UF_E.UF AS SIGLA_UF,
                                REPLACE(REPLACE(REPLACE(EMITENTE.CGC,
                                                        '.',
                                                        ''),
                                                '/',
                                                ''),
                                        '-',
                                        '') AS CNPJ_E,
                                PCNFSAIDPREFAT.DTSAIDA AS DATA_EMISSAO,
                                PCNFSAIDPREFAT.CHAVENFE AS CHAVE_ACESSO,
                                PCNFSAIDPREFAT.IE,
                                DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE, '01'),
                                       '01',
                                       '01',
                                       '55') AS MODELO,
                                DECODE(NVL(PCNFSAIDPREFAT.SERIE, 'U'),
                                       'U',
                                       '0',
                                       PCNFSAIDPREFAT.SERIE) AS SERIE,
                                PCNFSAIDPREFAT.NUMNOTA AS NUMERO_NOTA,
                                CASE
                                  WHEN LENGTH(PCNFSAIDPREFAT.CHAVENFE) = 44 THEN
                                   1
                                  ELSE
                                   3
                                END DOCREF,
                                'S' PREFATURAMENTO,
                                PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT
                           FROM PCNFSAIDPREFAT,
                                PCFORNEC EMITENTE,
                                PCESTADO UF_E,
                                PCCIDADE CIDADE_E,
                                PCFILIAL
                          WHERE NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) =
                                PCFILIAL.CODIGO
                            AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                            AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                            AND PCNFSAIDPREFAT.SERIE <> 'CF'
                            AND PCNFSAIDPREFAT.ESPECIE IN ('NF', 'NE')
                            AND CIDADE_E.UF = UF_E.UF
                            AND PCNFSAIDPREFAT.NUMTRANSVENDA = NUMERO_TRANSACAO
                            AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
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
                                                                  PREFATURAMENTO => NULL);

                RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
                RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
                RETORNO(RETORNO.COUNT).IE := NOTA.IE;
                RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
                RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
                RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
                RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
                RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
                RETORNO(RETORNO.COUNT).TIPO := 1;
                RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
                RETORNO(RETORNO.COUNT).NUMSEQECF := NULL;
                RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
                RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

              END IF;
            END LOOP;
          END;
        END IF;
      end loop;
    END;

    IF (V_TIPOVENDA IN ('DF')) THEN

      begin
        select NUMTRANSACAO NUMTRANSACAO
          into NUMERO_TRANSACAO
          from (select PCDEVFORNEC.NUMTRANSENT as NUMTRANSACAO
                  from PCDEVFORNEC
                 where PCDEVFORNEC.NUMTRANSVENDA = P_TRANSACAO
                   and ROWNUM = 1

                union all

                select MAX(PCMOV.NUMTRANSDEV) as NUMTRANSACAO
                  from PCMOV
                 where PCMOV.NUMTRANSVENDA = P_TRANSACAO

                union all

                select MAX(PCMOVPREFAT.NUMTRANSDEV) as NUMTRANSACAO
                  from PCMOVPREFAT
                 where PCMOVPREFAT.NUMTRANSVENDA = P_TRANSACAO
                   and PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                 )
         WHERE ROWNUM = 1;

      exception
        when others then
          NUMERO_TRANSACAO := 0;
      end;

      FOR NOTA IN (SELECT PCNFENT.NUMTRANSENT AS NUM_TRANSACAO,
                          UF_E.UF AS SIGLA_UF,
                          REPLACE(REPLACE(REPLACE(EMITENTE.CGC, '.', ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E,
                          PCNFENT.DTENT AS DATA_EMISSAO,
                          PCNFENT.CHAVENFE AS CHAVE_ACESSO,
                          PCNFENT.IE,
                          DECODE(NVL(PCNFENT.CHAVENFE, '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO,
                          DECODE(NVL(PCNFENT.SERIE, 'U'),
                                 'U',
                                 '0',
                                 PCNFENT.SERIE) AS SERIE,
                          PCNFENT.NUMNOTA AS NUMERO_NOTA,
                          CASE
                            WHEN LENGTH(PCNFENT.CHAVENFE) = 44 THEN
                             1
                            ELSE
                             3
                          END DOCREF,
                          'N' PREFATURAMENTO,
                          NULL DATACONSOLIDACAOPREFAT
                     FROM PCNFENT,
                          PCFORNEC EMITENTE,
                          PCESTADO UF_E,
                          PCCIDADE CIDADE_E,
                          PCFILIAL
                    WHERE NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) =
                          PCFILIAL.CODIGO
                      AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                      AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                      AND PCNFENT.SERIE <> 'CF'
                      AND PCNFENT.ESPECIE IN ('NF', 'NE')
                      AND CIDADE_E.UF = UF_E.UF
                      AND PCNFENT.NUMTRANSENT = NUMERO_TRANSACAO)

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
                                                            PREFATURAMENTO => NULL);

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO := 0;
          RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF := NULL;
          RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
          RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

        END IF;
      END LOOP;

      IF NUMERO_TRANSACAO = 0 THEN
         FOR NOTA IN (SELECT  0 AS NUM_TRANSACAO,
                              (SELECT PCCIDADE.UF FROM PCCIDADE WHERE PCCIDADE.CODIBGE = PCDEVAVULSO.CODMUN AND ROWNUM = 1) AS SIGLA_UF,
                              REPLACE(REPLACE(REPLACE(PCDEVAVULSO.CNPJCPFFORNEC, '.', ''),
                                              '/',
                                              ''),
                                      '-',
                                      '') AS CNPJ_E,
                              PCDEVAVULSO.DTEMISSAO AS DATA_EMISSAO,
                              PCDEVAVULSO.CHAVENFE AS CHAVE_ACESSO,
                              PCDEVAVULSO.INSCESTADUAL AS IE,
                              NVL(PCDEVAVULSO.MODELO,
                                  DECODE(NVL(PCDEVAVULSO.CHAVENFE, '01'),
                                         '01',
                                         '01',
                                         '55')) AS MODELO,
                              DECODE(NVL(PCDEVAVULSO.SERIE, 'U'),
                                     'U',
                                     '0',
                                     PCDEVAVULSO.SERIE) AS SERIE,
                              PCDEVAVULSO.NUMNOTA AS NUMERO_NOTA,
                              CASE
                                WHEN LENGTH(PCDEVAVULSO.CHAVENFE) = 44 THEN
                                 1
                                ELSE
                                 --CASO SEJA PRODUTOR RURAL, ESTE CAMPO DEVE SER 4 PARA GERAR A TAG CORRETA NO SERVIDOR NFE 
                                 DECODE(TRIM(PCFORNEC.CODPRODUTORRURAL), NULL, 3, 4)
                              END DOCREF,
                              'N' PREFATURAMENTO,
                               NULL DATACONSOLIDACAOPREFAT 
                        FROM PCDEVAVULSO,
                             PCFORNEC
                       WHERE 1=1     
                         AND PCDEVAVULSO.CODFORNEC = PCFORNEC.CODFORNEC(+)                               
                         AND PCDEVAVULSO.NUMTRANSVENDA = P_TRANSACAO)

           LOOP
            --NESTE CASO SE TRATA DE UMA NOTA DE DEVOLUÇÃO AVULSA, REFERENCIANDO UMA NOTA QUE NÃO EXISTE NO SISTEMA
            IF (NOTA.NUM_TRANSACAO = 0) THEN

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
                                                                PREFATURAMENTO => NULL);

              RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
              RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
              RETORNO(RETORNO.COUNT).IE := NOTA.IE;
              RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
              RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
              RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
              RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
              RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
              RETORNO(RETORNO.COUNT).TIPO := 0;
              RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
              RETORNO(RETORNO.COUNT).NUMSEQECF := NULL;
              RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
              RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

            END IF;
        END LOOP;

        RETURN RETORNO;

      END IF;
    END IF;

    IF (V_FINALIDADENFE IN ('C', 'A')) THEN

      NUMERO_TRANSACAO := V_NUMTRANSORIGEM;

      FOR NOTA IN (SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO,
                          UF_E.UF AS SIGLA_UF,
                          REPLACE(REPLACE(REPLACE(EMITENTE.CGC, '.', ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E,
                          PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                          PCNFSAID.CHAVENFE AS CHAVE_ACESSO,
                          PCNFSAID.IE,
                          DECODE(NVL(PCNFSAID.CHAVENFE, '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO,
                          DECODE(NVL(PCNFSAID.SERIE, 'U'),
                                 'U',
                                 '0',
                                 PCNFSAID.SERIE) AS SERIE,
                          PCNFSAID.NUMNOTA AS NUMERO_NOTA,
                          CASE
                            WHEN LENGTH(PCNFSAID.CHAVENFE) = 44 THEN
                             1
                            ELSE
                             3
                          END DOCREF,
                          'N' PREFATURAMENTO,
                          PCNFSAID.DATACONSOLIDACAOPREFAT
                     FROM PCNFSAID,
                          PCFORNEC EMITENTE,
                          PCESTADO UF_E,
                          PCCIDADE CIDADE_E,
                          PCFILIAL
                    WHERE NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                          PCFILIAL.CODIGO
                      AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                      AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                      AND PCNFSAID.SERIE <> 'CF'
                      AND PCNFSAID.ESPECIE IN ('NF', 'NE')
                      AND CIDADE_E.UF = UF_E.UF
                      AND PCNFSAID.NUMTRANSVENDA = NUMERO_TRANSACAO
                   UNION ALL
                   SELECT PCNFSAIDPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO,
                          UF_E.UF AS SIGLA_UF,
                          REPLACE(REPLACE(REPLACE(EMITENTE.CGC, '.', ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E,
                          PCNFSAIDPREFAT.DTSAIDA AS DATA_EMISSAO,
                          PCNFSAIDPREFAT.CHAVENFE AS CHAVE_ACESSO,
                          PCNFSAIDPREFAT.IE,
                          DECODE(NVL(PCNFSAIDPREFAT.CHAVENFE, '01'),
                                 '01',
                                 '01',
                                 '55') AS MODELO,
                          DECODE(NVL(PCNFSAIDPREFAT.SERIE, 'U'),
                                 'U',
                                 '0',
                                 PCNFSAIDPREFAT.SERIE) AS SERIE,
                          PCNFSAIDPREFAT.NUMNOTA AS NUMERO_NOTA,
                          CASE
                            WHEN LENGTH(PCNFSAIDPREFAT.CHAVENFE) = 44 THEN
                             1
                            ELSE
                             3
                          END DOCREF,
                          'S' PREFATURAMENTO,
                          PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT
                     FROM PCNFSAIDPREFAT,
                          PCFORNEC EMITENTE,
                          PCESTADO UF_E,
                          PCCIDADE CIDADE_E,
                          PCFILIAL
                    WHERE NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) =
                          PCFILIAL.CODIGO
                      AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                      AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                      AND PCNFSAIDPREFAT.SERIE <> 'CF'
                      AND PCNFSAIDPREFAT.ESPECIE IN ('NF', 'NE')
                      AND CIDADE_E.UF = UF_E.UF
                      AND PCNFSAIDPREFAT.NUMTRANSVENDA = NUMERO_TRANSACAO
                      AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
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
                                                            PREFATURAMENTO => NULL);

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO := CASE
                                           WHEN V_FINALIDADENFE = 'C' THEN
                                            1
                                           ELSE
                                            3
                                         END;
          RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF := NULL;
          RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT := NOTA.DATACONSOLIDACAOPREFAT;
          RETORNO(RETORNO.COUNT).PREFATURAMENTO := NOTA.PREFATURAMENTO;

        END IF;
      END LOOP;

      RETURN RETORNO;
    END IF;

    IF (V_NUMTRANSORIGEM IS NOT NULL) THEN
      --Cupom Fiscal
      FOR NOTA IN (SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO,
                          UF_E.UF AS SIGLA_UF,
                          REPLACE(REPLACE(REPLACE(EMITENTE.CGC, '.', ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E,
                          PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                          PCNFSAID.CHAVENFE AS CHAVE_ACESSO,
                          PCNFSAID.IE,
                          '2D' AS MODELO,
                          DECODE(NVL(PCNFSAID.SERIE, 'U'),
                                 'U',
                                 '0',
                                 PCNFSAID.SERIE) AS SERIE,
                          PCNFSAID.NUMNOTA AS NUMERO_NOTA,
                          CASE
                            WHEN LENGTH(PCNFSAID.CHAVENFE) = 44 THEN
                             1
                            ELSE
                             3
                          END DOCREF,
                          LPAD(NVL(PCNFSAID.NUMCAIXAFISCAL,PCCAIXA.NUMCAIXAFISCAL), 3, '0') NUMSEQECF,
                          'N' PREFATURAMENTO,
                          NULL DATACONSOLIDACAOPREFAT
                     FROM PCNFSAID,
                          PCFORNEC EMITENTE,
                          PCESTADO UF_E,
                          PCCIDADE CIDADE_E,
                          PCFILIAL,
                          PCCAIXA
                    WHERE NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                          PCFILIAL.CODIGO
                      AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                      AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                      AND PCNFSAID.ESPECIE IN ('NF', 'NE')
                      AND PCNFSAID.SERIE IN ('CF', 'CP')
                      AND CIDADE_E.UF = UF_E.UF
                      AND PCNFSAID.NUMTRANSVENDA = V_NUMTRANSORIGEM
                      AND PCCAIXA.NUMCAIXA(+) = PCNFSAID.CAIXA
                    
                    UNION
                   --parte para SAT   
                   SELECT PCNFSAID.NUMTRANSVENDA AS NUM_TRANSACAO,
                          UF_E.UF AS SIGLA_UF,
                          REPLACE(REPLACE(REPLACE(EMITENTE.CGC, '.', ''),
                                          '/',
                                          ''),
                                  '-',
                                  '') AS CNPJ_E,
                          PCNFSAID.DTSAIDA AS DATA_EMISSAO,
                          NVL(PCNFSAID.chavesat , PCNFSAID.CHAVENFE) AS CHAVE_ACESSO,
                          PCNFSAID.IE,
                          '2D' AS MODELO,
                          DECODE(NVL(PCNFSAID.SERIE, 'U'),
                                 'U',
                                 '0',
                                 PCNFSAID.SERIE) AS SERIE,
                          PCNFSAID.NUMNOTA AS NUMERO_NOTA,
                          CASE
                            WHEN LENGTH(PCNFSAID.CHAVENFE) = 44 THEN
                             1
                            ELSE
                             3
                          END DOCREF,
                          LPAD(NVL(PCNFSAID.NUMCAIXAFISCAL,PCCAIXA.NUMCAIXAFISCAL), 3, '0') NUMSEQECF,
                          'N' PREFATURAMENTO,
                          NULL DATACONSOLIDACAOPREFAT
                     FROM PCNFSAID,
                          PCFORNEC EMITENTE,
                          PCESTADO UF_E,
                          PCCIDADE CIDADE_E,
                          PCFILIAL,
                          PCCAIXA
                    WHERE NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                          PCFILIAL.CODIGO
                      AND PCFILIAL.CODFORNEC = EMITENTE.CODFORNEC
                      AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
                      AND PCNFSAID.ESPECIE IN ('NF', 'NE')
                      AND PCNFSAID.SERIE = 'SF'
                      AND SUBSTR(NVL(PCNFSAID.chavesat , PCNFSAID.CHAVENFE), 21,2) = '59'
                      AND CIDADE_E.UF = UF_E.UF
                      AND PCNFSAID.NUMTRANSVENDA = V_NUMTRANSORIGEM
                      AND PCCAIXA.NUMCAIXA(+) = PCNFSAID.CAIXA                    
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
                                                            PREFATURAMENTO => NULL);

          RETORNO(RETORNO.COUNT).CHAVE_ACESSO := NOTA.CHAVE_ACESSO;
          RETORNO(RETORNO.COUNT).CNPJ_E := NOTA.CNPJ_E;
          RETORNO(RETORNO.COUNT).IE := NOTA.IE;
          RETORNO(RETORNO.COUNT).SIGLA_UF := NOTA.SIGLA_UF;
          RETORNO(RETORNO.COUNT).SERIE := NOTA.SERIE;
          RETORNO(RETORNO.COUNT).MODELO := NOTA.MODELO;
          RETORNO(RETORNO.COUNT).DATA_EMISSAO := NOTA.DATA_EMISSAO;
          RETORNO(RETORNO.COUNT).NUMERO_NOTA := NOTA.NUMERO_NOTA;
          RETORNO(RETORNO.COUNT).TIPO := 0;
          RETORNO(RETORNO.COUNT).DOCREF := NOTA.DOCREF;
          RETORNO(RETORNO.COUNT).NUMSEQECF := NOTA.NUMSEQECF;
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
    raise_application_error(-20001,
                            'Erro motivo: ' || SQLERRM || '. Linha: ' ||
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END; 