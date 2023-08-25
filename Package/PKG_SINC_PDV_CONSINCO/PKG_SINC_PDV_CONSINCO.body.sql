CREATE OR REPLACE PACKAGE BODY PKG_SINC_PDV_CONSINCO IS

  PROCEDURE set_final_execucao(p_final_execucao IN TIMESTAMP) AS
  BEGIN
    g_final_execucao := p_final_execucao;
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'set_final_execucao',
       'SET g_final_execucao OK: ' ||
       TO_CHAR(g_final_execucao, 'DD-MON-YYYY HH24:MI:SSxFF'),
       SYSDATE,
       CURRENT_TIMESTAMP);
    COMMIT;
  END;

  PROCEDURE set_inicio_execucao(p_id IN pccontroleconsinco.id%TYPE) AS
    l_ultima_execucao pccontroleconsinco.ultimaexecucao%TYPE;
  BEGIN
    SELECT ultimaexecucao
      INTO l_ultima_execucao
      FROM pccontroleconsinco
     WHERE id = p_id;

    g_inicio_execucao := l_ultima_execucao;

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'set_inicio_execucao',
       'SET g_inicio_execucao OK: ' ||
       TO_CHAR(g_inicio_execucao, 'DD-MON-YYYY HH24:MI:SSxFF'),
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'set_inicio_execucao',
           'SET g_inicio_execucao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  FUNCTION get_final_execucao RETURN TIMESTAMP IS
  BEGIN
    RETURN g_final_execucao;
  END;

  FUNCTION get_inicio_execucao RETURN TIMESTAMP IS
  BEGIN
    RETURN g_inicio_execucao;
  END;

  PROCEDURE gravar_log_erro(pErroMessage VARCHAR2,
                            pBACKTRACE   CLOB,
                            pCALLSTACK   CLOB) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO PCERRORLOGCONSINCO s
      (ERROR_CODE,
       ERROR_MESSAGE,
       BACKTRACE,
       CALLSTACK,
       CREATED_ON,
       CREATED_BY)
    VALUES
      ('400',
       pErroMessage || ' ERRO',
       pBACKTRACE,
       pCALLSTACK,
       SYSDATE,
       'INTERMEDIARIO');
    COMMIT;
  END;

  PROCEDURE atualiza_sinc_processo(p_id IN pccontroleconsinco.id%TYPE) AS 
  BEGIN

    UPDATE pccontroleconsinco
       SET ultimaexecucao = pkg_sinc_PDV_consinco.get_final_execucao,
           dtalteracao    = CURRENT_TIMESTAMP
     WHERE id = p_id;

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'atualiza_sinc_processo',
       'UPDATE pccontroleconsinco OK: ' || TO_CHAR(p_id),
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      prc_record_error(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco',
         'atualiza_sinc_processo',
         'UPDATE pccontroleconsinco ERRO',
         SYSDATE,
         CURRENT_TIMESTAMP);
      COMMIT;
      RAISE;
  END;

  PROCEDURE carrega_tb_usuario(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_usuario s
        USING (SELECT *
               FROM VW_INT_C5_USUARIO c
              ) b

      ON (s.sequsuario = b.sequsuario)
      WHEN MATCHED THEN
      UPDATE SET
               s.NOME       = b.NOME,
               s.APELIDO    = b.APELIDO,
               s.SENHA      = b.SENHA,
               s.SEQPESSOA  = b.SEQPESSOA,
               s.NIVEL      = b.NIVEL,
               s.DTAEXPIRAR = b.DTAEXPIRAR,
               s.PERCDESCMAXIMO = b.PERCDESCMAXIMO,
               s.ATIVO = b.ATIVO

      WHEN NOT MATCHED THEN
        INSERT (s.sequsuario,
                s.NOME,
                s.APELIDO,
                s.SENHA,
                s.SEQPESSOA,
                s.NIVEL,
                s.DTAEXPIRAR,
                s.PERCDESCMAXIMO,
                s.ATIVO)
                VALUES
                  (b.sequsuario,
                   b.NOME,
                   b.APELIDO,
                   b.SENHA,
                   b.SEQPESSOA,
                   b.NIVEL,
                   b.DTAEXPIRAR,
                   b.PERCDESCMAXIMO,
                   b.ATIVO);

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_usuario',
       'carrega_tb_usuario OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_usuario',
           'carrega_tb_usuario ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_pessoa(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_pessoa s
        USING (SELECT *
               FROM VW_INT_C5_CLIPESSOA c
               ) b

      ON (s.seqpessoa = b.seqpessoa)
      WHEN MATCHED THEN
      UPDATE SET
               s.nomerazao        = b.nomerazao,
               s.nomefantasia     = b.nomefantasia,
               s.fisicajuridica   = b.fisicajuridica,
               s.cnpjcpf          = b.cnpjcpf,
               s.inscrestadualrg  = b.inscrestadualrg,
               s.dtanascimento    = b.dtanascimento,
               s.contribuinteicms = b.contribuinteicms,
               s.orgexp           = b.orgexp,
               s.sexo             = b.sexo,
               s.email            = b.email,
               s.ativo            = b.ativo

      WHEN NOT MATCHED THEN
        INSERT (s.seqpessoa,
                s.nomerazao,
                s.nomefantasia,
                s.fisicajuridica,
                s.cnpjcpf,
                s.inscrestadualrg,
                s.dtanascimento,
                s.contribuinteicms,
                s.orgexp,
                s.sexo,
                s.email,
                s.ativo)
                VALUES
                  (b.seqpessoa,
                   b.nomerazao,
                   b.nomefantasia,
                   b.fisicajuridica,
                   b.cnpjcpf,
                   b.inscrestadualrg,
                   b.dtanascimento,
                   b.contribuinteicms,
                   b.orgexp,
                   b.sexo,
                   b.email,
                   b.ativo);
    
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_pessoa',
       'carrega_tb_pessoa OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_pessoa',
           'carrega_tb_pessoa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_segmento(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_segmento s
        USING (SELECT 1 nrosegmento, 'VAREJO' segmento, 'S' ativo FROM DUAL) b

      ON (s.nrosegmento = b.NROSEGMENTO)
      WHEN MATCHED THEN
      UPDATE SET
        s.ativo    = b.ATIVO,
        s.segmento = b.SEGMENTO

      WHEN NOT MATCHED THEN
        INSERT (s.ativo,
                s.nrosegmento,
                s.segmento)
                VALUES
                  (b.ATIVO,
                   b.NROSEGMENTO,
                   b.SEGMENTO);

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_segmento',
           'carrega_tb_segmento ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_empresa(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_empresa t
    USING (SELECT DISTINCT * FROM VW_INT_C5_EMPRESA) s
    ON (t.nroempresa = s.nroempresa)
    WHEN MATCHED THEN
      UPDATE SET
        t.seqpessoa           = s.seqpessoa,
        t.nrodivisao          = s.nrodivisao,
        t.nomereduzido        = s.nomereduzido,
        t.nroempresamatriz    = s.nroempresamatriz,
        t.nroempresaseguranca = s.nroempresaseguranca,
        t.ativo               = s.ativo
    WHEN NOT MATCHED THEN
      INSERT (t.nroempresa,
              t.seqpessoa,
              t.nrodivisao,
              t.nomereduzido,
              t.nroempresamatriz,
              t.nroempresaseguranca,
              t.ativo
             )
      VALUES (s.nroempresa,
              s.seqpessoa,
              s.nrodivisao,
              s.nomereduzido,
              s.nroempresamatriz,
              s.nroempresaseguranca,
              s.ativo
             );

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_empresa',
           'carrega_tb_empresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;


  PROCEDURE carrega_tb_cliente(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_cliente s
        USING (SELECT C.*
               FROM VW_INT_C5_CLIPESSOA C
               ) b

      ON (s.seqpessoa = b.seqpessoa)
      WHEN MATCHED THEN
      UPDATE SET
        s.vlrlimiteglobal    = b.vlrlimiteglobal,
        s.prazomaximo        = b.prazomaximo,
        s.dtahorultrestricao = b.dtahorultrestricao,
        s.observacao         = b.observacao,
        s.situacaocredito    = b.situacaocredito,
        s.situacaocomercial  = b.situacaocomercial,
        s.ativo              = b.ativo

      WHEN NOT MATCHED THEN
        INSERT (s.seqpessoa,
                s.vlrlimiteglobal,
                s.prazomaximo,
                s.dtahorultrestricao,
                s.observacao,
                s.situacaocredito,
                s.situacaocomercial,
                s.ativo)
                VALUES
                  (b.seqpessoa,
                   b.vlrlimiteglobal,
                   b.prazomaximo,
                   b.dtahorultrestricao,
                   b.observacao,
                   b.situacaocredito,
                   b.situacaocomercial,
                   b.ativo);

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_cliente',
           'carrega_tb_cliente ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_empresasegmento(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_empresasegmento s
        USING (SELECT DISTINCT E.nroempresa, 1 nrosegmento, 'S' ativo, 0 nrocarga FROM VW_INT_C5_EMPRESA E
       ) b

      ON (s.nroempresa = b.nroempresa and s.nrosegmento = b.NROSEGMENTO)
      WHEN MATCHED THEN
      UPDATE
             SET s.ativo    = b.ativo,
                 s.nrocarga = b.nrocarga
      WHEN NOT MATCHED THEN
        INSERT
            (s.nroempresa,
             s.nrosegmento,
             s.nrocarga
             )
          VALUES
            (b.nroempresa,
             b.nrosegmento,
             b.nrocarga);

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_empresasegmento',
           'carrega_tb_empresasegmento ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;


  PROCEDURE carrega_tb_produto(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_produto s
        USING (
               SELECT P.seqproduto,
                      P.desccompleta,
                      P.descreduzida,
                      P.produtocomposto,
                      P.seqfamilia,
                      P.QTDDIAVALIDADE,
                      P.codanp,
                      P.descanp_prod,
                      P.ativo,
                      P.codproduto
        FROM VW_INT_C5_PRODUTO P
       ) b

      ON (s.seqproduto = b.SEQPRODUTO)
      WHEN MATCHED THEN
      UPDATE
             SET s.descreduzida    = NVL(b.DESCREDUZIDA, '-'),
                 s.desccompleta    = NVL(b.DESCCOMPLETA, '-'),
                 s.ativo           = b.ATIVO,
                 s.produtocomposto = b.PRODUTOCOMPOSTO,
                 s.seqfamilia      = b.SEQFAMILIA,
                 s.codproduto      = b.codproduto
      WHEN NOT MATCHED THEN
        INSERT
            (s.SEQPRODUTO,
             s.DESCREDUZIDA,
             s.DESCCOMPLETA,
             s.ATIVO,
             s.PRODUTOCOMPOSTO,
             s.SEQFAMILIA,
             s.codproduto
             )
          VALUES
            (b.SEQPRODUTO,
             NVL(b.DESCREDUZIDA, '-'),
             NVL(b.DESCCOMPLETA, '-'),
             b.ATIVO,
             b.PRODUTOCOMPOSTO,
             b.SEQFAMILIA,
             b.codproduto);

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_produto',
           'carrega_tb_produto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_famgrupo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_famgrupo s
        USING (SELECT 1 seqfamgrupo, 'VAREJO' grupofamilia, 'S' ativo, 0 nrocarga FROM dual ) b

      ON (s.seqfamgrupo = b.seqfamgrupo)
      WHEN MATCHED THEN
      UPDATE
             SET s.grupofamilia = b.grupofamilia,
                 s.ativo        = b.ativo,
                 s.nrocarga     = b.nrocarga
      WHEN NOT MATCHED THEN
        INSERT
            (s.grupofamilia,
             s.ativo,
             s.nrocarga,
             s.seqfamgrupo
             )
          VALUES
            (b.grupofamilia,
             b.ativo,
             b.nrocarga,
             b.seqfamgrupo);


    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_famgrupoo',
           'carrega_tb_famgrupo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_marca(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_marca s
        USING (SELECT * FROM VW_INT_C5_MARCA M ) b

      ON (s.seqmarca = b.seqmarca)
      WHEN MATCHED THEN
      UPDATE
             SET s.marca = b.marca,
                 s.ativo = b.ativo
      WHEN NOT MATCHED THEN
        INSERT
            (s.marca,
             s.ativo,
             s.seqmarca
             )
          VALUES
            (b.marca,
             b.ativo,
             b.seqmarca);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_marca',
           'carrega_tb_marca ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_familia(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
  MERGE INTO monitorpdvmiddle.tb_familia s
        USING (
             SELECT v.seqfamilia,
                    NVL(fnc_remove_char_esp(v.familia), '-') familia,
                    v.permitedecimal,
                    v.permitemultiplicacao,
                    v.codncmsh,
                    v.codcest,
                    v.ativo,
                    NVL(v.seqmarca, PARAM.VALOR) seqmarca,
                    v.seqfamgrupo,
                    v.pesavel,
                    PRODPISCOFINS.SITTRIBUT,
                    NVL(PRODPISCOFINS.PERCPIS, 0)PERCPIS,
                    NVL(PRODPISCOFINS.PERCCOFINS, 0)PERCCOFINS
             FROM VW_INT_C5_FAMILIA v,
                  
                  (SELECT R.CODPROD, T.SITTRIBUT, T.PERCPIS, T.PERCCOFINS 
                   FROM PCTABPR R, PCTRIBPISCOFINS T 
                   WHERE R.CODTRIBPISCOFINS = T.CODTRIBPISCOFINS 
                   AND   R.CODTRIBPISCOFINS IS NOT NULL
                   AND   R.NUMREGIAO = (SELECT VALOR
                                         FROM PCPARAMFILIAL
                                         WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                                         AND VALOR <> '99'
                                         AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                                         AND VALOR IS NOT NULL
                                         AND ROWNUM = 1)-- somente os dados de 1 região
                  ) PRODPISCOFINS, --vinculo do produto com os dados de pis e cofins
                  
                  (SELECT VALOR 
                   FROM PCPARAMFILIAL 
                   WHERE NOME = 'MARCAINTEGRACAOCONSINCO'
                  ) PARAM --valor padrao caso a marca esteja sem valor 
             WHERE V.seqfamilia = PRODPISCOFINS.CODPROD(+)
                
      ) b

      ON (s.seqfamilia = B.seqfamilia)
      WHEN MATCHED THEN
              UPDATE SET
                     S.familia = B.familia,
                     S.permitedecimal = B.permitedecimal,
                     S.permitemultiplicacao = B.permitemultiplicacao,
                     S.codnbmsh = B.codncmsh,
                     S.codcest = B.codcest,
                     S.ativo = B.ativo,
                     S.seqmarca = B.seqmarca,
                     S.seqfamgrupo = B.seqfamgrupo,
                     s.pesavel = B.pesavel,
                     s.situacaopis = B.sittribut,
                     s.situacaocofins = B.sittribut,
                     s.percbasepis = 100,
                     s.percbasecofins = 100,
                     s.percpis = B.percpis,
                     s.perccofins = B.perccofins
      WHEN NOT MATCHED THEN
              INSERT(S.familia,
                     S.permitedecimal,
                     S.permitemultiplicacao,
                     S.codnbmsh,
                     S.codcest,
                     S.ativo,
                     S.seqmarca,
                     S.seqfamgrupo,
                     S.seqfamilia,
                     s.pesavel,
                     s.situacaopis,
                     s.situacaocofins,
                     s.percbasepis,
                     s.percbasecofins,
                     s.percpis,
                     s.perccofins)
                     VALUES
                     (B.familia,
                      B.permitedecimal,
                      B.permitemultiplicacao,
                      b.codncmsh,
                      B.codcest,
                      B.ativo,
                      B.seqmarca,
                      B.seqfamgrupo,
                      NVL(B.seqfamilia,0),
                      B.pesavel,
                      B.sittribut,
                      B.sittribut,
                      100,
                      100,
                      B.percpis,
                      B.perccofins);

  pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
  
  COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      prc_record_error(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'c_tb_prodempresa', 'c_tb_prodempresa ERRO', SYSDATE, CURRENT_TIMESTAMP);
      COMMIT;
      RAISE;
    END;
  END carrega_tb_familia;

  PROCEDURE carrega_tb_formapagtoespecie(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_formapagtoespecie s
        USING (SELECT DISTINCT v.especie,
                      v.descricao,
                      'S' ativo,
                      0 nrocarga
               FROM VW_INT_C5_ESPECIE_FORMAPGTO v ) b

      ON (s.especie = b.especie)
      WHEN MATCHED THEN
      UPDATE
             SET s.descricao = b.descricao,
                 s.ativo     = b.ativo,
                 s.nrocarga  = b.nrocarga
      WHEN NOT MATCHED THEN
        INSERT
            (s.descricao,
             s.ativo,
             s.nrocarga,
             s.especie
             )
          VALUES
            (b.descricao,
             b.ativo,
             b.nrocarga,
             b.especie);

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_formapagtoespecie',
           'carrega_tb_formapagtoespecie ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_clientesegmento(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_clientesegmento s
        USING (SELECT c.seqpessoa,
                      c.nrosegmento,
                      c.ativo
               FROM VW_INT_C5_CLIPESSOA C) b

      ON (s.seqpessoa = b.seqpessoa and s.nrosegmento = b.nrosegmento)
      WHEN MATCHED THEN
      UPDATE
             SET s.ativo = b.ativo
      WHEN NOT MATCHED THEN
        INSERT
            (s.nrosegmento,
             s.ativo,
             s.seqpessoa
             )
          VALUES
            (b.nrosegmento,
             b.ativo,
             b.seqpessoa);
             
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_clientesegmento',
           'carrega_tb_clientesegmento ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_formapagto(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_formapagto s
        USING(
          SELECT f.codfinalizadora nroformapagto,
             (CASE
               WHEN f.especie = 'D' THEN
                'D'
               WHEN f.especie = 'BK' THEN
                'B'
               WHEN f.especie IN ('CHP', 'CHV') THEN
                'C'
               WHEN f.especie = 'CTD' THEN
                'E'
               WHEN f.especie IN ('CTC', 'DIG') THEN
                'R'
               WHEN f.especie LIKE ('POS%') THEN
                'S'
               WHEN f.especie = 'CNV' THEN
                'V'
               WHEN f.especie = 'CRE' THEN
                'I'
               WHEN COALESCE(c.carteiradigital, 'N') = 'S' THEN
                'G'
               ELSE
                'D'
             END) especie,
             SUBSTR(f.descricao, 1, 40) formapagto,
             f.codfilial,
             (CASE
               WHEN f.dtinativacao IS NULL THEN
                'S'
               ELSE
                'N'
             END) ativo,
             0 nrocarga
          FROM VW_INT_C5_ESPECIE_FORMAPGTO vef,
               pcfilial e,
               pcfinalizadora              f,
               pccob                       c,
               (SELECT s.ultimaexecucao
                FROM pccontroleconsinco s
                WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FORMAPAGTO') D
          WHERE f.especie = vef.winthor(+)
          AND   F.CODFILIAL = E.codigo
          AND   f.codcob = c.codcob(+)
          AND   E.codigo >= '0'
          AND   E.codigo < '99'
          AND  (NVL(f.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao OR
                NVL(c.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao or
                NVL(e.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao))b

      ON (s.nroformapagto = b.nroformapagto)
      WHEN MATCHED THEN
      UPDATE
             SET s.especie    = b.especie,
                 s.formapagto = b.formapagto,
                 s.idref      = b.codfilial,
                 s.ativo      = b.ativo,
                 s.nrocarga   = b.nrocarga
      WHEN NOT MATCHED THEN
        INSERT
            (s.especie,
             s.formapagto,
             s.ativo,
             s.nrocarga,
             s.nroformapagto,
             s.idref
             )
          VALUES
            (b.especie,
             b.formapagto,
             b.ativo,
             b.nrocarga,
             b.nroformapagto,
             b.codfilial);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_formapagto',
           'carrega_tb_formapagto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;


  PROCEDURE carrega_tb_formapagtoempresa(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_formapagtoempresa s
        USING (SELECT distinct * FROM VW_INT_C5_FORMAPAGTOEMPRESA) b

      ON (s.nroformapagto = b.nroformapagto  AND s.nrosegmento = b.nrosegmento  AND s.nroempresa = b.nroempresa)
      WHEN MATCHED THEN
      UPDATE
             SET
               s.percjuromensal   = b.percjuromensal,
               s.perctaxaadm      = b.perctaxaadm,
               s.nrodiasvencto    = b.nrodiasvencto,
               s.solicitavencto   = b.solicitavencto,
               s.permitetroco     = b.permitetroco,
               s.vlrminimo        = b.vlrminimo,
               s.vlrmaximo        = b.vlrmaximo,
               s.gerasangria      = b.gerasangria,
               s.prazomaximo      = b.prazomaximo,
               s.usatef           = b.usatef,
               s.tipocalculojuros = b.tipocalculojuros,
               s.emitevaletroco   = b.emitevaletroco,
               s.emitecomprovante = b.emitecomprovante,
               s.abregaveta       = b.abregaveta,
               s.alternativa      = b.alternativa,
               s.faturamento      = b.faturamento,
               s.idref            = b.codCob,
               s.nroParcelaJuro   = b.nroParcelaJuro
      WHEN NOT MATCHED THEN
        INSERT
            (s.percjuromensal,
             s.perctaxaadm,
             s.nrodiasvencto,
             s.solicitavencto,
             s.permitetroco,
             s.vlrminimo,
             s.vlrmaximo,
             s.gerasangria,
             s.prazomaximo,
             s.usatef,
             s.tipocalculojuros,
             s.emitevaletroco,
             s.emitecomprovante,
             s.abregaveta,
             s.alternativa,
             s.faturamento,
             s.nroformapagto,
             s.nrosegmento,
             s.nroempresa,
             s.idref,
             s.nroParcelaJuro
             )
          VALUES
            (b.percjuromensal,
             b.perctaxaadm,
             b.nrodiasvencto,
             b.solicitavencto,
             b.permitetroco,
             b.vlrminimo,
             b.vlrmaximo,
             b.gerasangria,
             b.prazomaximo,
             b.usatef,
             b.tipocalculojuros,
             b.emitevaletroco,
             b.emitecomprovante,
             b.abregaveta,
             b.alternativa,
             b.faturamento,
             b.nroformapagto,
             b.nrosegmento,
             b.nroempresa,
             b.codCob,
             b.nroParcelaJuro);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_formapagtoempresa',
           'carrega_tb_formapagtoempresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_famsegmento(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_famsegmento s
        USING (SELECT DISTINCT e.seqfamilia, e.nrosegmento, e.ativo
               FROM VW_INT_C5_FAMSEGMENTO e) b

      ON (s.seqfamilia = b.seqfamilia and s.nrosegmento = b.nrosegmento)
      WHEN MATCHED THEN
      UPDATE SET
        s.ativo = b.ativo
      WHEN NOT MATCHED THEN
        INSERT (s.ativo,
                s.seqfamilia,
                s.nrosegmento)
        VALUES
               (b.ativo,
                b.seqfamilia,
                b.nrosegmento);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_famsegmento',
           'carrega_tb_famsegmento ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_divisao(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_divisao s
        USING (SELECT
                 *
               FROM VW_INT_C5_DIVISAO) b

      ON (s.nrodivisao = b.nrodivisao)
      WHEN MATCHED THEN
      UPDATE SET
        s.tipo     = b.tipo,
        s.ativo    = b.ativo,
        s.divisao  = SUBSTR(b.divisao, 1, 19),
        s.idref    = b.idref
      WHEN NOT MATCHED THEN
        INSERT (s.tipo,
                s.ativo,
                s.nrodivisao,
                s.divisao,
                s.idref)
                VALUES
                (b.tipo,
                 b.ativo,
                 b.nrodivisao,
                 SUBSTR(b.divisao, 1, 19),
                 b.idref);

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_divisao',
           'carrega_tb_divisao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_categoria(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_categoria s
        USING (SELECT DISTINCT *
               FROM VW_INT_C5_CATEGORIA S) b

      ON (s.seqcategoria = b.seqcategoria AND s.nrodivisao = b.nrodivisao)
      WHEN MATCHED THEN
      UPDATE SET
               s.seqcategoriapai = b.seqcategoriapai,
               s.categoria       = b.categoria,
               s.tipo            = b.tipo,
               s.ativo           = b.ativo,
               s.lerpeso         = b.lerpeso,
               s.NIVELHIERARQUIA = b.nivelhierarquia,
               s.idref           = b.idref
      WHEN NOT MATCHED THEN
        INSERT (s.seqcategoriapai,
                s.categoria,
                s.tipo,
                s.ativo,
                s.lerpeso,
                s.seqcategoria,
                s.nrodivisao,
                s.NIVELHIERARQUIA,
                s.idref)
                VALUES
                (b.seqcategoriapai,
                 b.categoria,
                 b.tipo,
                 b.ativo,
                 b.lerpeso,
                 b.seqcategoria,
                 b.nrodivisao,
                 b.nivelhierarquia,
                 b.idref);

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_categoria',
           'carrega_tb_categoria ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_famdivisaocategoria(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
  MERGE INTO monitorpdvmiddle.tb_famdivisaocategoria s
        USING (SELECT DISTINCT SD.seqfamilia, SD.seqcategoria, SD.nrodivisao, SD.ativo
               FROM VW_INT_C5_FAMDIVISAOCATEGORIA sd) b

      ON (s.SEQCATEGORIA = b.SEQCATEGORIA AND s.NRODIVISAO = b.NRODIVISAO  AND s.SEQFAMILIA = b.seqfamilia )
      WHEN MATCHED THEN
      UPDATE SET
        s.ativo = b.ativo
      WHEN NOT MATCHED THEN
        INSERT (s.seqfamilia,
                s.seqcategoria,
                s.nrodivisao,
                s.ativo)
                VALUES
                (b.seqfamilia,
                 b.seqcategoria,
                 b.nrodivisao,
                 b.ativo);

  
  pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

  COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      prc_record_error(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_famdivisaocategoria', 'carrega_tb_famdivisaocategoria ERRO', SYSDATE, CURRENT_TIMESTAMP);
      COMMIT;
      RAISE;
    END;
  END carrega_tb_famdivisaocategoria;

  PROCEDURE carrega_tb_prodempresa(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_prodempresa s
        USING (SELECT DISTINCT
                      Ep.seqproduto,
                      Ep.nroempresa,
                      0 estqloja,
                      0 PERCALIQISS,
                      'S' ativo
         FROM VW_INT_C5_PRODEMPRESA ep) b

      ON (s.seqproduto = b.seqproduto and s.nroempresa  = b.nroempresa)
      WHEN MATCHED THEN
      UPDATE SET
        estqloja = b.estqloja,
        ativo    = b.ativo
      WHEN NOT MATCHED THEN
        INSERT (s.seqproduto,
                s.nroempresa,
                s.estqloja,
                s.PERCALIQISS,
                s.ativo)
                VALUES
                (b.seqproduto,
                 b.nroempresa,
                 b.estqloja,
                 b.percaliqiss,
                 b.ativo);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'c_tb_prodempresa',
           'c_tb_prodempresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END carrega_tb_prodempresa;

  PROCEDURE carrega_tb_famembalagem(p_id IN pccontroleconsinco.id%TYPE) IS
    bPrimeriaCarga number;
  BEGIN
    select count(*) into bPrimeriaCarga from MONITORPDVMIDDLE.TB_FAMEMBALAGEM where rownum = 1;
   
    MERGE INTO monitorpdvmiddle.tb_famembalagem s
      USING (SELECT DISTINCT e.seqfamilia,
                    e.qtdembalagem,
                    e.embalagem,
                    e.pesoaferido,
                    e.ativo,
                    e.pesobruto,
                    e.pesoliq pesoliquido,
                    0 nrocarga
      FROM VW_INT_C5_FAMEMBALAGEM e) b

    ON (s.seqfamilia = b.seqfamilia and s.QTDEMBALAGEM = b.QTDEMBALAGEM)
    WHEN MATCHED THEN
    UPDATE SET
      s.embalagem = b.embalagem,
      s.pesoaferido = b.pesoaferido,
      s.pesobruto = b.pesobruto,
      s.pesoliquido = b.pesoliquido,
      s.ativo = b.ativo,
      s.nrocarga = b.nrocarga

    WHEN NOT MATCHED THEN
      INSERT (s.seqfamilia,
                  s.qtdembalagem,
                  s.embalagem,
                  s.pesoaferido,
                  s.pesobruto,
                  s.pesoliquido,
                  s.ativo,
                  s.nrocarga)
              VALUES
                (b.seqfamilia,
                  b.qtdembalagem,
                  b.embalagem,
                  b.pesoaferido,
                  b.pesobruto,
                  b.pesoliquido,
                  b.ativo,
                  b.nrocarga);

    /*INATIVANDO REGISTROS COM QTDEMBALAGEM DIFERENTES DO WINTHOR*/
    --Não executar inativação na primeira carga
    IF bPrimeriaCarga <> 0 THEN
      UPDATE monitorpdvmiddle.tb_famembalagem SET ATIVO = 'N'
      WHERE TB_FAMEMBALAGEM.rowid IN (
        select 
          TB_FAMEMBALAGEM.rowid
        from monitorpdvmiddle.TB_FAMEMBALAGEM  TB_FAMEMBALAGEM
        left JOIN
        (
          SELECT 
            CODPROD SEQFAMILIA,  
            QTUNIT QTDEMBALAGEM 
          FROM VW_INT_C5_EMBPROD
          WHERE QTUNIT > 0
          
          UNION 
          
          SELECT 
            CODPROD SEQFAMILIA, 
            QTMINIMAATACADO QTDEMBALAGEM 
          FROM VW_INT_C5_EMBPROD
          WHERE QTMINIMAATACADO > 0
        ) EMBALAGEM
        on (TB_FAMEMBALAGEM.SEQFAMILIA  = EMBALAGEM.SEQFAMILIA and TB_FAMEMBALAGEM.qtdembalagem = EMBALAGEM.QTDEMBALAGEM)
        WHERE 
          EMBALAGEM.QTDEMBALAGEM IS NULL	
          AND ATIVO = 'S'
      );
    END IF;

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          prc_record_error(p_id);
          ROLLBACK;
          INSERT INTO PCDEVLOGCONSINCO
            (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
          VALUES
            ('pkg_sinc_PDV_Consinco', 'carrega_tb_famembalagem', 'carrega_tb_famembalagem ERRO', SYSDATE, CURRENT_TIMESTAMP);
          COMMIT;
          RAISE;
        END;
  END carrega_tb_famembalagem;

  PROCEDURE carrega_tb_prodcodigo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
      MERGE INTO monitorpdvmiddle.tb_prodcodigo s
        USING (SELECT DISTINCT e.nroempresa,
                      e.codacesso,
                      e.seqproduto,
                      e.qtdembalagem,
                      e.tipo,
                      e.ativo
         FROM VW_INT_C5_PRODCODIGO e
         ) b

      ON (s.nroempresa = b.nroempresa AND s.codacesso = b.codacesso)
      WHEN MATCHED THEN
      UPDATE SET
        s.seqproduto = b.seqproduto,
        s.qtdembalagem = b.qtdembalagem,
        s.tipo = b.tipo,
        s.ativo = b.ativo
      WHEN NOT MATCHED THEN
        INSERT (s.nroempresa,
                   s.codacesso,
                   s.seqproduto,
                   s.qtdembalagem,
                   s.tipo,
                   s.ativo)
                VALUES
                  (b.nroempresa,
                   b.codacesso,
                   b.seqproduto,
                   b.qtdembalagem,
                   b.tipo,
                   b.ativo);
  
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'c_tb_prodcodigo', 'c_tb_prodcodigo OK', SYSDATE, CURRENT_TIMESTAMP);

      COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          prc_record_error(p_id);
          ROLLBACK;
          INSERT INTO PCDEVLOGCONSINCO
            (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
          VALUES
            ('pkg_sinc_PDV_Consinco', 'c_tb_prodcodigo', 'c_tb_prodcodigo ERRO', SYSDATE, CURRENT_TIMESTAMP);
          COMMIT;
          RAISE;
        END;
    END carrega_tb_prodcodigo;


  PROCEDURE carrega_tb_prodpreco(p_id IN pccontroleconsinco.id%TYPE) IS
    bPrimeriaCarga number;
  BEGIN
    SELECT count(*) INTO bPrimeriaCarga FROM MONITORPDVMIDDLE.tb_prodpreco where rownum = 1;

    MERGE INTO monitorpdvmiddle.tb_prodpreco TB_PRODPRECO_C5
      USING (SELECT * FROM VW_INT_C5_PRODPRECO) VIEW_TB_PRODPRECO
    on(
      TB_PRODPRECO_C5.seqproduto       = VIEW_TB_PRODPRECO.seqproduto 
      AND TB_PRODPRECO_C5.qtdembalagem = VIEW_TB_PRODPRECO.qtdembalagem 
      AND TB_PRODPRECO_C5.nrosegmento  = VIEW_TB_PRODPRECO.nrosegmento 
      AND TB_PRODPRECO_C5.nroempresa   = VIEW_TB_PRODPRECO.nroempresa
    )
      WHEN MATCHED THEN
      UPDATE SET
        TB_PRODPRECO_C5.ativo    = VIEW_TB_PRODPRECO.ativo,
        TB_PRODPRECO_C5.promocao = VIEW_TB_PRODPRECO.promocao,
        TB_PRODPRECO_C5.preco    = VIEW_TB_PRODPRECO.preco
      WHEN NOT MATCHED THEN
      INSERT(
        TB_PRODPRECO_C5.seqproduto,
        TB_PRODPRECO_C5.qtdembalagem,
        TB_PRODPRECO_C5.nrosegmento,
        TB_PRODPRECO_C5.nroempresa,
        TB_PRODPRECO_C5.ativo,
        TB_PRODPRECO_C5.promocao,
        TB_PRODPRECO_C5.preco
      ) 
      VALUES(
        VIEW_TB_PRODPRECO.seqproduto,
        VIEW_TB_PRODPRECO.qtdembalagem,
        VIEW_TB_PRODPRECO.nrosegmento,
        VIEW_TB_PRODPRECO.nroempresa,
        VIEW_TB_PRODPRECO.ativo,
        VIEW_TB_PRODPRECO.promocao,
        VIEW_TB_PRODPRECO.preco
      );

    /*INATIVANDO REGISTROS COM QTDEMBALAGEM DIFERENTES DO QTUNIT DO WINTHOR*/
     --Se for a primeira carga, não executar update
    IF bPrimeriaCarga <> 0 THEN
      UPDATE monitorpdvmiddle.tb_prodpreco SET ATIVO = 'N'
      WHERE tb_prodpreco.rowid IN (
        select 
          tb_prodpreco.rowid
        from monitorpdvmiddle.tb_prodpreco tb_prodpreco
        left JOIN
        (
          SELECT 
            TO_NUMBER(CODAUXILIAR || CODFILIAL)  SEQPRODUTO, 
            QTUNIT QTDEMBALAGEM 
          FROM VW_INT_C5_EMBPROD
          WHERE QTUNIT > 0
          
          UNION 
          
          SELECT 
            TO_NUMBER(CODAUXILIAR || CODFILIAL)  SEQPRODUTO, 
            QTMINIMAATACADO QTDEMBALAGEM 
          FROM VW_INT_C5_EMBPROD
          WHERE QTMINIMAATACADO > 0
          
        ) EMBALAGEM
        on (tb_prodpreco.SEQPRODUTO  = EMBALAGEM.SEQPRODUTO and tb_prodpreco.qtdembalagem = EMBALAGEM.QTDEMBALAGEM)
        WHERE 
          EMBALAGEM.QTDEMBALAGEM IS NULL	
          AND ATIVO = 'S'
      );
    END IF;

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco', 'carrega_tb_prodpreco', 'carrega_tb_prodpreco OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      prc_record_error(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco',
          'carrega_tb_prodpreco',
          'carrega_tb_prodpreco ERRO',
          SYSDATE,
          CURRENT_TIMESTAMP);
      COMMIT;
      RAISE;
    END;
  END;

  PROCEDURE carrega_tb_tributacao(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_tributacao s
    USING (SELECT DISTINCT NROTRIBUTACAO,
                      CODST,
                      SUBSTR(COALESCE(TRIBUTACAO,
                                      'TRIBUTACAO ' || NROTRIBUTACAO),
                             1,
                             40) TRIBUTACAO,
                      DESCAPLICACAO,
                      ATIVO
        FROM VW_TB_TRIBUTACAO_CONSOLIDADA) b
    ON (s.nrotributacao = b.nrotributacao)
    WHEN MATCHED THEN
      UPDATE SET
        s.tributacao    = b.tributacao,
        s.descaplicacao = b.descaplicacao,
        s.ativo         = b.ativo
    WHEN NOT MATCHED THEN
      INSERT (s.nrotributacao,
              s.tributacao,
              s.descaplicacao,
              s.ativo
             )
      VALUES (b.nrotributacao,
              b.tributacao,
              b.descaplicacao,
              b.ativo
             );

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_tributacao',
           'carrega_tb_tributacao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;


  PROCEDURE carrega_tb_tributacaouf(p_id IN pccontroleconsinco.id%TYPE) AS

    CURSOR c_tb_tributacaouf IS
      SELECT DISTINCT E.*
        FROM VW_INT_C5_TRIB_UF_CONSOLIDADA E;

    get_records SYS_REFCURSOR;
    r_tb_tributacaouf c_tb_tributacaouf%ROWTYPE;
    countReg          NUMBER := 0;

    PROCEDURE inserir IS
    BEGIN
      INSERT INTO monitorpdvmiddle.tb_tributacaouf
        (nrotributacao,
         uforigem,
         ufdestino,
         tipotributacao,
         nroregtributacao,
         percaliquota,
         situacaotributacao,
         percisento,
         perctributado,
         percacrescst,
         percisentost,
         tipocalcfcp,
         percbasefcpicms,
         percaliqfcpicms,
         reducaobasest,
         tiporeducaoicmscalcst,
         perctributst,
         ativo,
         situacaopis,
         situacaocofins,
         percpis,
         perccofins,
         percbasefcpst,
         percaliqfcpst,
         CALCICMSDESON,
         PERCALIQICMSDESON,
         MOTIVODESONICMS,
         CODBENEFICIODESONICMS,
         IDREF)

      VALUES
        (r_tb_tributacaouf.nrotributacao,
         r_tb_tributacaouf.uforigem,
         r_tb_tributacaouf.ufdestino,
         r_tb_tributacaouf.tipotributacao,
         r_tb_tributacaouf.nroregtributacao,
         r_tb_tributacaouf.percaliquota,
         r_tb_tributacaouf.situacaotributacao,
         r_tb_tributacaouf.percisento,
         r_tb_tributacaouf.perctributado,
         r_tb_tributacaouf.percacrescst,
         r_tb_tributacaouf.percisentost,
         r_tb_tributacaouf.tipocalcfcp,
         r_tb_tributacaouf.percbasefcpicms,
         r_tb_tributacaouf.percaliqfcpicms,
         r_tb_tributacaouf.reducaobasest,
         r_tb_tributacaouf.tiporeducaoicmscalcst,
         r_tb_tributacaouf.perctributst,
         r_tb_tributacaouf.ativo,
         r_tb_tributacaouf.situacaopis,
         r_tb_tributacaouf.situacaocofins,
         r_tb_tributacaouf.percpis,
         r_tb_tributacaouf.perccofins,
         r_tb_tributacaouf.percbasefcpst,
         r_tb_tributacaouf.percaliqfcpst,
         r_tb_tributacaouf.CALCICMSDESON,
         r_tb_tributacaouf.PERCALIQICMSDESON,
         r_tb_tributacaouf.MOTIVODESONICMS,
         r_tb_tributacaouf.CODBENEFICIODESONICMS,
         r_tb_tributacaouf.CODST);
    END;

    PROCEDURE atualizar IS
    BEGIN
      UPDATE monitorpdvmiddle.tb_tributacaouf
         SET percaliquota          = r_tb_tributacaouf.percaliquota,
             situacaotributacao    = r_tb_tributacaouf.situacaotributacao,
             percisento            = r_tb_tributacaouf.percisento,
             perctributado         = r_tb_tributacaouf.perctributado,
             percacrescst          = r_tb_tributacaouf.percacrescst,
             percisentost          = r_tb_tributacaouf.percisentost,
             tipocalcfcp           = r_tb_tributacaouf.tipocalcfcp,
             percbasefcpicms       = r_tb_tributacaouf.percbasefcpicms,
             percaliqfcpicms       = r_tb_tributacaouf.percaliqfcpicms,
             reducaobasest         = r_tb_tributacaouf.reducaobasest,
             tiporeducaoicmscalcst = r_tb_tributacaouf.tiporeducaoicmscalcst,
             perctributst          = r_tb_tributacaouf.perctributst,
             ativo                 = r_tb_tributacaouf.ativo,
             situacaopis           = r_tb_tributacaouf.situacaopis,
             situacaocofins        = r_tb_tributacaouf.situacaocofins,
             percpis               = r_tb_tributacaouf.percpis,
             perccofins            = r_tb_tributacaouf.perccofins,
             percbasefcpst         = r_tb_tributacaouf.percbasefcpst,
             percaliqfcpst         = r_tb_tributacaouf.percaliqfcpst,
             CALCICMSDESON         = r_tb_tributacaouf.CALCICMSDESON,
             PERCALIQICMSDESON     = r_tb_tributacaouf.PERCALIQICMSDESON,
             MOTIVODESONICMS       = r_tb_tributacaouf.MOTIVODESONICMS,
             CODBENEFICIODESONICMS = r_tb_tributacaouf.CODBENEFICIODESONICMS,
             IDREF                 = r_tb_tributacaouf.CODST
       WHERE uforigem = r_tb_tributacaouf.uforigem
         AND ufdestino = r_tb_tributacaouf.ufdestino
         AND tipotributacao = r_tb_tributacaouf.tipotributacao
         AND nrotributacao = r_tb_tributacaouf.nrotributacao
         AND nroregtributacao = r_tb_tributacaouf.nroregtributacao;
    END;
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_tributacaouf s
        USING (SELECT DISTINCT E.*
               FROM VW_INT_C5_TRIB_UF_CONSOLIDADA E) b
      ON (s.uforigem = b.uforigem
         AND s.ufdestino = b.ufdestino
         AND s.tipotributacao = b.tipotributacao
         AND s.nrotributacao = b.nrotributacao
         AND s.nroregtributacao = b.nroregtributacao)
      WHEN MATCHED THEN
      UPDATE SET
             s.percaliquota          = b.percaliquota,
             s.situacaotributacao    = b.situacaotributacao,
             s.percisento            = b.percisento,
             s.perctributado         = b.perctributado,
             s.percoutro             = b.percoutro,
             s.percacrescst          = b.percacrescst,
             s.percisentost          = b.percisentost,
             s.tipocalcfcp           = b.tipocalcfcp,
             s.percbasefcpicms       = b.percbasefcpicms,
             s.percaliqfcpicms       = b.percaliqfcpicms,
             s.reducaobasest         = b.reducaobasest,
             s.tiporeducaoicmscalcst = b.tiporeducaoicmscalcst,
             s.perctributst          = b.perctributst,
             s.ativo                 = b.ativo,
             s.situacaopis           = b.situacaopis,
             s.situacaocofins        = b.situacaocofins,
             s.percpis               = b.percpis,
             s.perccofins            = b.perccofins,
             s.percbasefcpst         = b.percbasefcpst,
             s.percaliqfcpst         = b.percaliqfcpst,
             s.CALCICMSDESON         = b.CALCICMSDESON,
             s.PERCALIQICMSDESON     = b.PERCALIQICMSDESON,
             s.MOTIVODESONICMS       = b.MOTIVODESONICMS,
             s.CODBENEFICIODESONICMS = b.CODBENEFICIODESONICMS,
             s.IDREF                 = b.CODST
      WHEN NOT MATCHED THEN
        INSERT (s.nrotributacao,
                s.uforigem,
                s.ufdestino,
                s.tipotributacao,
                s.nroregtributacao,
                s.percaliquota,
                s.situacaotributacao,
                s.percisento,
                s.perctributado,
                s.percoutro,
                s.percacrescst,
                s.percisentost,
                s.tipocalcfcp,
                s.percbasefcpicms,
                s.percaliqfcpicms,
                s.reducaobasest,
                s.tiporeducaoicmscalcst,
                s.perctributst,
                s.ativo,
                s.situacaopis,
                s.situacaocofins,
                s.percpis,
                s.perccofins,
                s.percbasefcpst,
                s.percaliqfcpst,
                s.CALCICMSDESON,
                s.PERCALIQICMSDESON,
                s.MOTIVODESONICMS,
                s.CODBENEFICIODESONICMS,
                s.IDREF)
            VALUES
                (b.nrotributacao,
                 b.uforigem,
                 b.ufdestino,
                 b.tipotributacao,
                 b.nroregtributacao,
                 b.percaliquota,
                 b.situacaotributacao,
                 b.percisento,
                 b.perctributado,
                 b.percoutro,
                 b.percacrescst,
                 b.percisentost,
                 b.tipocalcfcp,
                 b.percbasefcpicms,
                 b.percaliqfcpicms,
                 b.reducaobasest,
                 b.tiporeducaoicmscalcst,
                 b.perctributst,
                 b.ativo,
                 b.situacaopis,
                 b.situacaocofins,
                 b.percpis,
                 b.perccofins,
                 b.percbasefcpst,
                 b.percaliqfcpst,
                 b.CALCICMSDESON,
                 b.PERCALIQICMSDESON,
                 b.MOTIVODESONICMS,
                 b.CODBENEFICIODESONICMS,
                 b.CODST);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    commit;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_tributacaouf',
           'carrega_tb_tributacaouf ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_cargatributaria(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_cargatributaria s
        USING (SELECT *
               FROM VW_INT_C5_LEITRANSP
              ) b
         
      ON (s.codnbmsh = b.codncmsh and s.ufdestino = b.ufdestino and s.ex = b.ex)
      WHEN MATCHED THEN
      UPDATE SET
               s.perctributo           = b.perctributos, 
               s.perctributoimportado  = b.perctributoimportado, 
               s.perctributonacfederal = b.perctributonacfederal, 
               s.perctributoimpfederal = b.perctributoimpfederal,
               s.perctributoestadual   = b.perctributoestadual, 
               s.perctributomunicipal  = b.perctributomunicipal,
               s.ativo                 = b.ativo
        
      WHEN NOT MATCHED THEN
        INSERT (s.codnbmsh,
                s.ufdestino,
                s.ex,
                s.perctributo,
                s.perctributoimportado,
                s.perctributonacfederal,
                s.perctributoimpfederal,
                s.perctributoestadual,
                s.perctributomunicipal,
                s.ativo)
                VALUES
                  (b.codncmsh,
                   b.ufdestino,
                   b.ex,
                   b.perctributos,
                   b.perctributoimportado,
                   b.perctributonacfederal, 
                   b.perctributoimpfederal,
                   b.perctributoestadual,
                   b.perctributomunicipal, 
                   b.ativo);
    
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_cargatributaria',
       'carrega_tb_cargatributaria OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_cargatributaria',
           'carrega_tb_cargatributaria ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_codgeraloper(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_codgeraloper s
        USING (SELECT * FROM VW_INT_C5_CODGERALOPER) b
      ON (s.CODGERALOPER = b.CODGERALOPER)
      WHEN MATCHED THEN
      UPDATE SET
               s.DESCRICAO           = b.DESCRICAO,
               s.APLICACAO           = b.APLICACAO,
               s.Cfopestado          = b.CFOPESTADO,
               s.CFOPFORAESTADO      = b.CFOPFORAESTADO,
               s.CALCULAICMSST       = b.CALCULAICMSST,
               s.GERAREDUCAOBASEST   = b.GERAREDUCAOBASEST,
               s.CALCULAIPI          = b.CALCULAIPI,
               s.TIPOCALCULOIPI      = b.TIPOCALCULOIPI,
               s.CALCULAFECP         = b.CALCULAFECP,
               s.TIPOFATURAMENTO     = b.TIPOFATURAMENTO,
               s.ATIVO               = b.ATIVO,
               s.CONSUMIDORFINAL     = b.CONSUMIDORFINAL,
               s.VENDAPRESENCIAL     = b.VENDAPRESENCIAL,
               s.TIPOTRIBUTACAO      = b.TIPOTRIBUTACAO
                  
      WHEN NOT MATCHED THEN
        INSERT (s.CODGERALOPER,
                s.DESCRICAO,
                s.APLICACAO,
                s.Cfopestado,        
                s.CFOPFORAESTADO,
                s.CALCULAICMSST,
                s.GERAREDUCAOBASEST,
                s.CALCULAIPI,
                s.TIPOCALCULOIPI,
                s.CALCULAFECP,
                s.TIPOFATURAMENTO,
                s.ATIVO,
                s.CONSUMIDORFINAL,
                s.VENDAPRESENCIAL,
                s.TIPOTRIBUTACAO
                )
                VALUES
                 (b.CODGERALOPER,
                  b.DESCRICAO,
                  b.APLICACAO,
                  b.Cfopestado,        
                  b.CFOPFORAESTADO,
                  b.CALCULAICMSST,
                  b.GERAREDUCAOBASEST,
                  b.CALCULAIPI,
                  b.TIPOCALCULOIPI,
                  b.CALCULAFECP,
                  b.TIPOFATURAMENTO,
                  b.ATIVO,
                  b.CONSUMIDORFINAL,
                  b.VENDAPRESENCIAL,
                  b.TIPOTRIBUTACAO);

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_codgeraloper',
       'carrega_tb_codgeraloper OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_codgeraloper',
           'carrega_tb_codgeraloper ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;
  
  PROCEDURE carrega_tb_codgeralopercfop(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_codgeralopercfop s
        USING ( SELECT * FROM VW_INT_C5_CODGERALOPERCFOP) b
      ON (S.CODGERALOPER = B.CODGERALOPER AND S.NROTRIBUTACAO = B.NROTRIBUTACAO AND S.CONTRIBICMS = B.CONTRIBICMS)
      WHEN MATCHED THEN
      UPDATE SET
               s.CFOPESTADO     = b.CFOPESTADO,
               s.cfopforaestado = b.cfopforaestado,
               s.ATIVO          = b.ATIVO
 
      WHEN NOT MATCHED THEN
         INSERT (s.CODGERALOPER,
                 s.NROTRIBUTACAO,
                 s.CONTRIBICMS,   
                 s.CFOPESTADO,
                 s.cfopforaestado,     
                 s.ATIVO)
                VALUES
                  (b.CODGERALOPER,
                   b.NROTRIBUTACAO,
                   b.CONTRIBICMS,   
                   b.CFOPESTADO,  
                   b.cfopforaestado,   
                   b.ATIVO);

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'tb_codgeralopercfop',
       'tb_codgeralopercfop OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'tb_codgeralopercfop',
           'tb_codgeralopercfop ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;
  
  PROCEDURE carrega_tb_codgeralopercfopuf(p_id IN pccontroleconsinco.id%TYPE) AS
    BEGIN
      
    DELETE from monitorpdvmiddle.TB_CODGERALOPERCFOPUF;
    MERGE INTO monitorpdvmiddle.TB_CODGERALOPERCFOPUF s
        USING (
                SELECT*FROM
                  (
                    SELECT CODGERALOPER,
                           NROTRIBUTACAO,   
                           CONTRIBICMS,     
                           UFORIGEM,
                           UFDESTINO,
                           CFOPESTADO,
                           ATIVO,
                           NROREGTRIBUTACAO,
                           DTALTERC5,
                           (SELECT MIN(S.ULTIMAEXECUCAO) 
                                    FROM PCCONTROLECONSINCO S 
                             WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CODGERALOPERCFOPUF') AS ULTIMAEXECAUCAO
                       FROM VW_INT_C5_CFOP                     
                     ) WHERE NVL(DTALTERC5, ULTIMAEXECAUCAO) >= ULTIMAEXECAUCAO
                 ) b
         
      ON (s.CODGERALOPER = b.CODGERALOPER)
      WHEN MATCHED THEN
      UPDATE SET
               s.NROTRIBUTACAO = b.NROTRIBUTACAO ,
               s.CONTRIBICMS   = b.CONTRIBICMS ,
               s.UFORIGEM      = b.UFORIGEM,
               s.UFDESTINO     = b.UFDESTINO,
               s.CFOPESTADO    = b.CFOPESTADO,
               s.ATIVO         = b.ATIVO 
      WHEN NOT MATCHED THEN
        INSERT ( s.CODGERALOPER,
                 s.NROTRIBUTACAO,   
                 s.CONTRIBICMS,     
                 s.UFORIGEM,
                 s.UFDESTINO,
                 s.CFOPESTADO,
                 s.ATIVO,
                 s.NROREGTRIBUTACAO)
                VALUES
                  (b.CODGERALOPER,
                   b.NROTRIBUTACAO,   
                   b.CONTRIBICMS,     
                   b.UFORIGEM,
                   b.UFDESTINO,
                   b.CFOPESTADO,
                   b.ATIVO,
                   0);

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'tb_codgeralopercfopuf',
       'tb_codgeralopercfopuf OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'tb_codgeralopercfopuf',
           'tb_codgeralopercfopuf ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;



  PROCEDURE carrega_tb_enderecoalternativo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN 
    UPDATE monitorpdvmiddle.tb_enderecoalternativo SET ativo = 'N';

    MERGE INTO monitorpdvmiddle.tb_enderecoalternativo EnderecoAlternativoC5
    USING(SELECT * FROM VW_INT_C5_ENDERECO_ALTERNATIVO) ViewEnderecoAlt
    ON (EnderecoAlternativoC5.seqpessoa = ViewEnderecoAlt.seqpessoa and EnderecoAlternativoC5.seqlogradouro = ViewEnderecoAlt.SEQLOGRADOURO)
    WHEN MATCHED THEN
      UPDATE SET 
        EnderecoAlternativoC5.tipo          = ViewEnderecoAlt.tipo,
        EnderecoAlternativoC5.logradouro    = ViewEnderecoAlt.logradouro,
        EnderecoAlternativoC5.nrologradouro = ViewEnderecoAlt.nrologradouro,
        EnderecoAlternativoC5.bairro        = ViewEnderecoAlt.bairro,
        EnderecoAlternativoC5.complemento   = ViewEnderecoAlt.complemento,
        EnderecoAlternativoC5.cidade        = ViewEnderecoAlt.cidade,
        EnderecoAlternativoC5.uf            = ViewEnderecoAlt.uf,
        EnderecoAlternativoC5.cep           = ViewEnderecoAlt.cep,
        EnderecoAlternativoC5.ativo         = ViewEnderecoAlt.ativo,
        EnderecoAlternativoC5.codibge       = ViewEnderecoAlt.codibge
      WHEN NOT MATCHED THEN
        INSERT  
        (
	        EnderecoAlternativoC5.seqpessoa,
	        EnderecoAlternativoC5.seqlogradouro,
	        EnderecoAlternativoC5.tipo,
	        EnderecoAlternativoC5.logradouro,
	        EnderecoAlternativoC5.nrologradouro,
	        EnderecoAlternativoC5.bairro,
	        EnderecoAlternativoC5.complemento,
	        EnderecoAlternativoC5.cidade,
	        EnderecoAlternativoC5.uf,
	        EnderecoAlternativoC5.cep,
	        EnderecoAlternativoC5.ativo,
	        EnderecoAlternativoC5.codibge
        )
        VALUES
        (
          ViewEnderecoAlt.seqpessoa,
          ViewEnderecoAlt.seqlogradouro,
          ViewEnderecoAlt.tipo,
          ViewEnderecoAlt.logradouro,
          ViewEnderecoAlt.nrologradouro,
          ViewEnderecoAlt.bairro,
          ViewEnderecoAlt.complemento,
          ViewEnderecoAlt.cidade,
          ViewEnderecoAlt.uf,
          ViewEnderecoAlt.cep,
          ViewEnderecoAlt.ativo,
          ViewEnderecoAlt.codibge
         );
         
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_enderecoalternativo',
       'carrega_tb_enderecoalternativo OK',
       SYSDATE,
       CURRENT_TIMESTAMP);
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_enderecoalternativo',
           'carrega_tb_enderecoalternativo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;
  
  PROCEDURE carrega_tb_famdivisao(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_famdivisao s
        USING (SELECT DISTINCT 
                     E.seqfamilia,
                     E.nrodivisao,
                     E.nrotributacao,
                     E.codorigemtrib,
                     E.ativo
               FROM VW_INT_C5_FAMDIVISAO E) b

      ON (s.seqfamilia = b.seqfamilia AND s.nrodivisao = b.nrodivisao)
      WHEN MATCHED THEN
      UPDATE SET
        s.nrotributacao = b.nrotributacao,
        s.codorigemtrib = b.codorigemtrib,
        s.ativo = b.ativo
      WHEN NOT MATCHED THEN
        INSERT (s.seqfamilia,
                s.nrodivisao,
                s.nrotributacao,
                s.codorigemtrib,
                s.ativo)
                VALUES
                (b.seqfamilia,
                 b.nrodivisao,
                 b.nrotributacao,
                 b.codorigemtrib,
                 b.ativo);

    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_famdivisao',
           'carrega_tb_famdivisao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END carrega_tb_famdivisao;
  
  PROCEDURE carrega_tb_condicaopagto(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    MERGE INTO monitorpdvmiddle.TB_CONDICAOPAGTO s
        USING (SELECT *
               FROM vw_int_c5_plpag c
               ) b

      ON (s.nrocondicaopagto = b.nrocondicaopagto)
      WHEN MATCHED THEN
      UPDATE SET
              s.CONDICAOPAGTO = b.CONDICAOPAGTO,
              s.PERCACRESCIMO = b.PERCACRESCIMO,
              s.NROMAXIMOPARCELA = b.NROMAXIMOPARCELA,
              s.NRODIASVENCTO = b.NRODIASVENCTO,
              s.ATIVO = b.ATIVO


      WHEN NOT MATCHED THEN
        INSERT (s.NROCONDICAOPAGTO,
                s.CONDICAOPAGTO,
                s.PERCACRESCIMO,
                s.NROMAXIMOPARCELA,
                s.NRODIASVENCTO,
                s.ATIVO
                )
                VALUES
                  (b.NROCONDICAOPAGTO,
                   b.CONDICAOPAGTO,
                   b.PERCACRESCIMO,
                   b.NROMAXIMOPARCELA,
                   b.NRODIASVENCTO,
                   b.ATIVO
                   );
    
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_condicaopagto',
       'carrega_tb_condicaopagto OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_condicaopagto',
           'carrega_tb_condicaopagto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

PROCEDURE carrega_tb_regraincentivo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
      MERGE INTO monitorpdvmiddle.tb_regraincentivo tb_regraincentivo_C5
        USING (SELECT * FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
      on(
        tb_regraincentivo_C5.SEQREGRA         = VIEW_C5_INCENTIVO.SEQREGRA 
      )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraincentivo_C5.REGRA          = VIEW_C5_INCENTIVO.REGRA,
          tb_regraincentivo_C5.SEQTIPOCREDITO = VIEW_C5_INCENTIVO.SEQTIPOCREDITO,
          tb_regraincentivo_C5.ATIVO          = VIEW_C5_INCENTIVO.ATIVO,
          tb_regraincentivo_C5.TIPOREGRA      = VIEW_C5_INCENTIVO.TIPOREGRA,
          tb_regraincentivo_C5.CUMULATIVO     = VIEW_C5_INCENTIVO.CUMULATIVO          
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraincentivo_C5.SEQREGRA,
          tb_regraincentivo_C5.REGRA,
          tb_regraincentivo_C5.SEQTIPOCREDITO,
          tb_regraincentivo_C5.ATIVO,
          tb_regraincentivo_C5.TIPOREGRA,
          tb_regraincentivo_C5.CUMULATIVO          
        ) 
        VALUES(
          VIEW_C5_INCENTIVO.SEQREGRA,
          VIEW_C5_INCENTIVO.REGRA,
          VIEW_C5_INCENTIVO.SEQTIPOCREDITO,
          VIEW_C5_INCENTIVO.ATIVO,
          VIEW_C5_INCENTIVO.TIPOREGRA,
          VIEW_C5_INCENTIVO.CUMULATIVO
        );

   UPDATE MONITORPDVMIDDLE.tb_regraincentivo SET ATIVO = 'N'
   WHERE SEQREGRA IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM)
      OR SEQREGRA IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA);

      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraincentivo', 'carrega_tb_regraincentivo OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraincentivo',
           'carrega_tb_regraincentivo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

PROCEDURE carrega_tb_regraincentperiodo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
      MERGE INTO monitorpdvmiddle.tb_regraincentivoperiodo tb_regraincentivoperiodo_c5
        USING (SELECT * FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
      on(
             tb_regraincentivoperiodo_c5.SEQREGRA     = VIEW_C5_INCENTIVO.SEQREGRA 
        AND  tb_regraincentivoperiodo_c5.DTAHORINICIO = VIEW_C5_INCENTIVO.DTAHORINICIO
        AND  tb_regraincentivoperiodo_c5.DTAHORFIM    = VIEW_C5_INCENTIVO.DTAHORFIM
        AND  tb_regraincentivoperiodo_c5.IDREF        = VIEW_C5_INCENTIVO.IDREF

        
      )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraincentivoperiodo_c5.ATIVO           = VIEW_C5_INCENTIVO.ATIVO
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraincentivoperiodo_c5.SEQREGRA,
          tb_regraincentivoperiodo_c5.DTAHORINICIO,
          tb_regraincentivoperiodo_c5.DTAHORFIM,
          tb_regraincentivoperiodo_c5.ATIVO,
          tb_regraincentivoperiodo_c5.IDREF
        ) 
        VALUES(
          VIEW_C5_INCENTIVO.SEQREGRA,
          VIEW_C5_INCENTIVO.DTAHORINICIO,
          VIEW_C5_INCENTIVO.DTAHORFIM,
          VIEW_C5_INCENTIVO.ATIVO,
          VIEW_C5_INCENTIVO.IDREF
        );

    UPDATE MONITORPDVMIDDLE.tb_regraincentivoperiodo SET ATIVO = 'N'
    WHERE SEQREGRA IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM)
       OR SEQREGRA IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA);

    UPDATE MONITORPDVMIDDLE.tb_REGRAINCENTIVOPERIODO r SET ATIVO = 'N'
      WHERE NOT EXISTS (SELECT C.CODOFERTA
                        FROM PCOFERTAPROGRAMADAC C 
                        WHERE C.DTINICIAL = R.DTAHORINICIO 
                        AND  c.dtfinal = r.dtahorfim
                        AND  R.SEQREGRA = C.codfilial||2011||C.codoferta
                       )
      AND IDREF = 2011;
    
    INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraincentperiodo', 'carrega_tb_regraincentperiodo OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraincentperiodo',
           'carrega_tb_regraincentperiodo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

PROCEDURE carrega_tb_regraproduto(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
      MERGE INTO monitorpdvmiddle.tb_regraproduto tb_regraproduto_c5
        USING (SELECT * FROM VW_INT_C5_PRODUTO_R2011) vw_int_c5_regraproduto_2011
      on(
            tb_regraproduto_c5.SEQPRODUTO    = vw_int_c5_regraproduto_2011.SEQPRODUTO        
        AND tb_regraproduto_c5.QTDEMBALAGEM  = vw_int_c5_regraproduto_2011.QTDEMBALAGEM
        AND tb_regraproduto_c5.SEQREGRA      = vw_int_c5_regraproduto_2011.SEQREGRA        
      )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraproduto_c5.PERCDESCONTO    = vw_int_c5_regraproduto_2011.PERCDESCONTO,
          tb_regraproduto_c5.PRECO           = vw_int_c5_regraproduto_2011.PRECO,
          tb_regraproduto_c5.ATIVO           = vw_int_c5_regraproduto_2011.ATIVO 
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraproduto_c5.SEQREGRA,
          tb_regraproduto_c5.SEQPRODUTO,
          tb_regraproduto_c5.QTDEMBALAGEM,
          tb_regraproduto_c5.PERCDESCONTO,
          tb_regraproduto_c5.PRECO,          
          tb_regraproduto_c5.ATIVO          
        ) 
        VALUES(
          vw_int_c5_regraproduto_2011.SEQREGRA,
          vw_int_c5_regraproduto_2011.SEQPRODUTO,
          vw_int_c5_regraproduto_2011.QTDEMBALAGEM,
          vw_int_c5_regraproduto_2011.PERCDESCONTO,
          vw_int_c5_regraproduto_2011.PRECO,
          vw_int_c5_regraproduto_2011.ATIVO
        );

      UPDATE MONITORPDVMIDDLE.tb_regraproduto r SET ATIVO = 'N'
      WHERE  EXISTS  (SELECT C.CODOFERTA
                      FROM PCOFERTAPROGRAMADAC C 
                      WHERE C.DTINICIAL = R.DTAHORINICIO 
                      AND   c.dtfinal = r.dtahorfim
                      AND   R.SEQREGRA = C.codfilial||2011||C.codoferta
                      AND   C.DTCANCEL IS NOT NULL
                      )
      AND IDREF = 2011;  

      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraproduto', 'carrega_tb_regraproduto OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraproduto',
           'carrega_tb_regraproduto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

PROCEDURE carrega_tb_regrafamilia(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regrafamilia D
    USING (/*Rotina 357*/
           SELECT 
              SEQREGRA,
              SEQFAMILIA,
              QTDEMBALAGEM,
              PERCDESCONTO,
              PRECO,          
              ATIVO,
              IDREF  
           FROM VW_INT_C5_PRECOFIXO_R357 
           UNION ALL
           /*Rotina 561*/
           SELECT 
              SEQREGRA,
              SEQFAMILIA,
              QTDEMBALAGEM,
              PERCDESCONTO,
              0 PRECO,          
              ATIVO,
              IDREF    
           FROM VW_INT_C5_DESC561FAMILIA) S 
  
    ON    ( D.SEQFAMILIA = S.SEQFAMILIA AND D.QTDEMBALAGEM = S.QTDEMBALAGEM AND D.SEQREGRA = S.SEQREGRA)
  WHEN MATCHED THEN
       UPDATE SET
          D.PERCDESCONTO    = S.PERCDESCONTO,
          D.PRECO           = 0,
          D.ATIVO           = S.ATIVO,
          D.IDREF           = S.IDREF 
          
  WHEN NOT MATCHED THEN
        INSERT(
          D.SEQREGRA,
          D.SEQFAMILIA,
          D.QTDEMBALAGEM,
          D.PERCDESCONTO,
          D.PRECO,          
          D.ATIVO,
          D.IDREF) 
        VALUES(
          S.SEQREGRA,
          S.SEQFAMILIA,
          S.QTDEMBALAGEM,
          S.PERCDESCONTO,
          S.PRECO,
          S.ATIVO,
          S.IDREF);

  UPDATE MONITORPDVMIDDLE.tb_regrafamilia SET ATIVO = 'N'
  WHERE SEQREGRA IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM)
     OR SEQREGRA IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regrafamilia', 'carrega_tb_regrafamilia OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regrafamilia',
           'carrega_tb_regrafamilia ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_regracliente(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regracliente D
    USING (SELECT * FROM VW_INT_C5_DESC561CLIENTE) S 
    ON    ( D.SEQPESSOA = S.SEQPESSOA AND D.SEQREGRA = S.SEQREGRA)
  WHEN MATCHED THEN
       UPDATE SET
          D.PERCDESCONTO    = S.PERCDESCONTO,
          D.ATIVO           = S.ATIVO,
          D.IDREF           = S.IDREF 
          
  WHEN NOT MATCHED THEN
        INSERT(
          D.SEQREGRA,
          D.SEQPESSOA,
          D.PERCDESCONTO,
          D.ATIVO,
          D.IDREF) 
        VALUES(
          S.SEQREGRA,
          S.SEQPESSOA,
          S.PERCDESCONTO,
          S.ATIVO,
          S.IDREF);

  UPDATE MONITORPDVMIDDLE.tb_regracliente SET ATIVO = 'N'
  WHERE SEQREGRA IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regracliente', 'carrega_tb_regracliente OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regracliente',
           'carrega_tb_regracliente ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_regracategoria(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regracategoria D
    USING (SELECT * FROM VW_INT_C5_DESC561CATEGORIA) S 
    ON    ( D.SEQCATEGORIA = S.SEQCATEGORIA AND D.NRODIVISAO = S.NRODIVISAO AND D.SEQREGRA = S.SEQREGRA)
  WHEN MATCHED THEN
       UPDATE SET
          D.PERCDESCONTO    = S.PERCDESCONTO,
          D.ATIVO           = S.ATIVO
           
  WHEN NOT MATCHED THEN
        INSERT(
          D.SEQREGRA,
          D.NRODIVISAO,
          D.SEQCATEGORIA,
          D.PERCDESCONTO,
          D.ATIVO) 
        VALUES(
          S.SEQREGRA,
          S.NRODIVISAO,
          S.SEQCATEGORIA,
          S.PERCDESCONTO,
          S.ATIVO);

  UPDATE MONITORPDVMIDDLE.tb_regracategoria SET ATIVO = 'N'
  WHERE SEQREGRA IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regracategoria', 'carrega_tb_regracategoria OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regracategoria',
           'carrega_tb_regracategoria ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_combo(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_combo TB_COMBO
    USING (SELECT * FROM VW_INT_C5_BRINDE_CABECALHO) VIEW_BRINDE_CABECALHO 
    ON  (TB_COMBO.SEQCOMBO = VIEW_BRINDE_CABECALHO.SEQCOMBO)
  WHEN MATCHED THEN
       UPDATE SET
          TB_COMBO.COMBO     = VIEW_BRINDE_CABECALHO.DESCRICAO,
          TB_COMBO.DTAINICIO = VIEW_BRINDE_CABECALHO.DTAINICIO,
          TB_COMBO.DTAFIM    = VIEW_BRINDE_CABECALHO.DTAFIM,
          TB_COMBO.TIPO      = VIEW_BRINDE_CABECALHO.TIPO,
          TB_COMBO.ATIVO     = VIEW_BRINDE_CABECALHO.ATIVO
           
  WHEN NOT MATCHED THEN
        INSERT(
          TB_COMBO.SEQCOMBO,
          TB_COMBO.COMBO,
          TB_COMBO.DTAINICIO,
          TB_COMBO.DTAFIM,
          TB_COMBO.TIPO,
          TB_COMBO.ATIVO) 
        VALUES(
          VIEW_BRINDE_CABECALHO.SEQCOMBO,
          VIEW_BRINDE_CABECALHO.DESCRICAO,
          VIEW_BRINDE_CABECALHO.DTAINICIO,
          VIEW_BRINDE_CABECALHO.DTAFIM,
          VIEW_BRINDE_CABECALHO.TIPO,
          VIEW_BRINDE_CABECALHO.ATIVO);

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_combo', 'carrega_tb_combo OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_combo',
           'carrega_tb_combo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_comboempresa(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_comboempresa TB_COMBOEMPRESA
    USING (SELECT * FROM VW_INT_C5_BRINDE_CABECALHO) VIEW_BRINDE_CABECALHO 
    ON  (TB_COMBOEMPRESA.SEQCOMBO = VIEW_BRINDE_CABECALHO.SEQCOMBO and  TB_COMBOEMPRESA.NROEMPRESA = VIEW_BRINDE_CABECALHO.NROEMPRESA)
  WHEN MATCHED THEN
       UPDATE SET
          TB_COMBOEMPRESA.ATIVO = VIEW_BRINDE_CABECALHO.ATIVO
           
  WHEN NOT MATCHED THEN
        INSERT(
          TB_COMBOEMPRESA.SEQCOMBO,
          TB_COMBOEMPRESA.NROEMPRESA,
          TB_COMBOEMPRESA.ATIVO) 
        VALUES(
          VIEW_BRINDE_CABECALHO.SEQCOMBO,
          VIEW_BRINDE_CABECALHO.NROEMPRESA,
          VIEW_BRINDE_CABECALHO.ATIVO);

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_comboempresa', 'carrega_tb_comboempresa OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_comboempresa',
           'carrega_tb_comboempresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_comboitem(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN

  UPDATE monitorpdvmiddle.TB_COMBOITEM TB_COMBOITEM SET ATIVO = 'N'
  WHERE TB_COMBOITEM.rowid IN (
    SELECT 
      TB_COMBOITEM.rowid
    FROM monitorpdvmiddle.tb_comboitem TB_COMBOITEM
    LEFT JOIN PCPROMI
    ON (pcpromi.CODIGO = TB_COMBOITEM.SEQCOMBO 
      AND TO_NUMBER(PCPROMI.CODPROD || PCPROMI.CODIGO || PCPROMI.QT ) = TB_COMBOITEM.SEQITEM 
      AND pcpromi.QT = TB_COMBOITEM.QTDE )
    WHERE PCPROMI.CODIGO IS null
    AND TB_COMBOITEM.ATIVO = 'S'
  );

  MERGE INTO monitorpdvmiddle.tb_comboitem TB_COMBOITEM
    USING (SELECT * FROM VW_INT_C5_BRINDE_ITENS) VIEW_BRINDE_ITENS
    ON  (TB_COMBOITEM.SEQCOMBO = VIEW_BRINDE_ITENS.SEQCOMBO and TB_COMBOITEM.SEQITEM = VIEW_BRINDE_ITENS.SEQITEM)

  WHEN MATCHED THEN
    UPDATE SET
      TB_COMBOITEM.SEQPRODUTO = VIEW_BRINDE_ITENS.SEQPRODUTO,
      TB_COMBOITEM.TIPOITEM = VIEW_BRINDE_ITENS.TIPOITEM,
      TB_COMBOITEM.ATIVO = VIEW_BRINDE_ITENS.ATIVO,
      TB_COMBOITEM.QTDE = VIEW_BRINDE_ITENS.QTDE,
      TB_COMBOITEM.PRECO = VIEW_BRINDE_ITENS.PRECO,
      TB_COMBOITEM.PERCDESCONTO = VIEW_BRINDE_ITENS.PERCDESCONTO
      
  WHEN NOT MATCHED THEN
    INSERT(
      TB_COMBOITEM.SEQCOMBO,
      TB_COMBOITEM.SEQITEM,
      TB_COMBOITEM.SEQPRODUTO,
      TB_COMBOITEM.TIPOITEM,
      TB_COMBOITEM.ATIVO,
      TB_COMBOITEM.QTDE,
      TB_COMBOITEM.PRECO,
      TB_COMBOITEM.PERCDESCONTO
    )
    VALUES(
      VIEW_BRINDE_ITENS.SEQCOMBO,
      VIEW_BRINDE_ITENS.SEQITEM,
      VIEW_BRINDE_ITENS.SEQPRODUTO,
      VIEW_BRINDE_ITENS.TIPOITEM,
      VIEW_BRINDE_ITENS.ATIVO,
      VIEW_BRINDE_ITENS.QTDE,
      VIEW_BRINDE_ITENS.PRECO,
      VIEW_BRINDE_ITENS.PERCDESCONTO
    );

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_comboitem', 'carrega_tb_comboitem OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_comboitem',
           'carrega_tb_comboitem ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_parcelamento(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_parcelamento T
    USING (SELECT * FROM VW_INT_C5_PARCELDEPTO) S 
    ON    (T.SEQPARCELA = S.SEQPARCELA)
  WHEN MATCHED THEN
       UPDATE SET
          T.DESCRICAO = S.DESCRICAO,
          T.TIPO      = S.TIPO,
          T.ATIVO     = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQPARCELA,
          T.DESCRICAO,
          T.TIPO,
          T.ATIVO) 
        VALUES(
          S.SEQPARCELA,
          S.DESCRICAO,
          S.TIPO,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_parcelamento', 'carrega_tb_parcelamento OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_parcelamento',
           'carrega_tb_parcelamento ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_parcempresa(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_parcempresa T
    USING (SELECT * FROM VW_INT_C5_PARCELDEPTO) S 
    ON    (T.SEQPARCELA = S.SEQPARCELA AND T.NROEMPRESA = S.NROEMPRESA)
  WHEN MATCHED THEN
       UPDATE SET
          T.ATIVO = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQPARCELA,
          T.NROEMPRESA,
          T.ATIVO) 
        VALUES(
          S.SEQPARCELA,
          S.NROEMPRESA,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_parcempresa', 'carrega_tb_parcempresa OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_parcempresa',
           'carrega_tb_parcempresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_parcperiodo(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_parcperiodo T
    USING (SELECT * FROM VW_INT_C5_PARCELDEPTO) S 
    ON    (T.SEQPARCELA = S.SEQPARCELA AND 
           T.DTAHORINICIAL = S.DTAHORINICIAL AND 
           T.DTAHORFINAL = S.DTAHORFINAL)
  WHEN MATCHED THEN
       UPDATE SET
          T.ATIVO = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQPARCELA,
          T.DTAHORINICIAL,
          T.DTAHORFINAL,
          T.ATIVO) 
        VALUES(
          S.SEQPARCELA,
          S.DTAHORINICIAL,
          S.DTAHORFINAL,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_parcperiodo', 'carrega_tb_parcperiodo OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_parcperiodo',
           'carrega_tb_parcperiodo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_parccategformapagto(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_parccategformapagto T
    USING (SELECT * FROM VW_INT_C5_PARCELDEPTO) S 
    ON    (T.SEQPARCELA = S.SEQPARCELA AND
           T.SEQCATEGORIA = S.SEQCATEGORIA AND
           T.NROFORMAPAGTO = S.NROFORMAPAGTO AND
           T.NRODIVISAO = S.NRODIVISAO)
  WHEN MATCHED THEN
       UPDATE SET
          T.NROMAXIMOPARCELA = S.NROMAXIMOPARCELA,
          T.ATIVO            = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQPARCELA,
          T.SEQCATEGORIA,
          T.NROFORMAPAGTO,
          T.NRODIVISAO,
          T.NROMAXIMOPARCELA,
          T.ATIVO) 
        VALUES(
          S.SEQPARCELA,
          S.SEQCATEGORIA,
          S.NROFORMAPAGTO,
          S.NRODIVISAO,
          S.NROMAXIMOPARCELA,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_parccategformapagto', 'carrega_parccategformapagto OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_parccategformapagto',
           'carrega_parccategformapagto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE exec_sinc AS

    CURSOR c_processo IS
      SELECT id, codprocesso, ultimaexecucao, tipo, objetoreferencia
        FROM pccontroleconsinco
       WHERE ativo = 'A'
       ORDER BY precedencia ASC;

    r_processo c_processo%ROWTYPE;

    text_to_run VARCHAR2(200);
    countReg    NUMBER := 0;

  BEGIN
    EXECUTE IMMEDIATE ('BEGIN delete from PCERRORLOGCONSINCO; end;');
    EXECUTE IMMEDIATE ('BEGIN update pccontroleconsinco set processando = ''S''; end;');

    OPEN c_processo;

    LOOP

      FETCH c_processo
        INTO r_processo;
      EXIT WHEN c_processo%NOTFOUND;

      -- Seta os timestamps par?metros INICIO e FINAL de execucao para o processo

      pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

      pkg_sinc_PDV_Consinco.set_inicio_execucao(r_processo.id);

      text_to_run := r_processo.objetoreferencia;

      EXECUTE IMMEDIATE ('BEGIN ' || text_to_run ||'('||r_processo.id ||')'||'; END;');

      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco',
         'exec_sinc',
         'EXECUTE IMMEDIATE OK: ' || text_to_run,
         SYSDATE,
         CURRENT_TIMESTAMP);

      pkg_sinc_PDV_Consinco.atualiza_sinc_processo(r_processo.id);

      EXECUTE IMMEDIATE ('BEGIN update pccontroleconsinco set processando = ''N'' where id = '|| r_processo.id ||'; end;');

    END LOOP;

    CLOSE c_processo;

  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(r_processo.id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'exec_sinc',
           'EXECUTE IMMEDIATE ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  /*PROCEDURE atualizarProdPreco AS
    MSG        VARCHAR2(232);
    vPreco     NUMBER;
    vnumregiao NUMBER;
  BEGIN

    FOR DADOS IN (SELECT (SELECT NVL(E.CODAUXILIAR, 0)
                          FROM PCEMBALAGEM E
                         WHERE E.CODPROD = A.CODPROD
                           AND E.CODFILIAL = A.nroempresa
                           AND E.QTUNIT = A.QTDEMBALAGEM
                           AND ROWNUM = 1) seqapartirde,
                       A.*
                  FROM (SELECT s.*,
                               (SELECT codproduto
                                  FROM monitorpdvmiddle.tb_produto a
                                 WHERE a.seqproduto = s.seqproduto) codprod

                          FROM monitorpdvmiddle.tb_prodpreco s) a
                 WHERE NVL(A.QTDEMBALAGEM, 0) NOT IN
                       (SELECT NVL(E.QTMINIMAATACADO, 0)
                          FROM PCEMBALAGEM E
                         WHERE E.CODPROD = A.CODPROD
                           AND E.CODFILIAL = A.nroempresa)) LOOP
      BEGIN
        vnumregiao := ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO',
                                                               dados.nroempresa,
                                                               1);
        vPreco     := coluna_preco(buscaprecos_consinco(DADOS.NROEMPRESA,
                                                                      vnumregiao,
                                                                      DADOS.SEQAPARTIRDE,
                                                                      TRUNC(SYSDATE),
                                                                      0,
                                                                      0,
                                                                      0,
                                                                      0,
                                                                      0),
                                          'PVENDA');

        UPDATE monitorpdvmiddle.tb_prodpreco a
           SET a.preco = vPreco
         WHERE SEQPRODUTO = DADOS.SEQPRODUTO
           AND QTDEMBALAGEM = DADOS.QTDEMBALAGEM
           AND NROSEGMENTO = 1
           AND NROEMPRESA = DADOS.NROEMPRESA;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          NULL;
          -- MSG := DBMS_UTILITY.format_error_backtrace;
      END;
      --dbms_output.put_line(vPrecoAtac || ' - ' || MSG);
    END LOOP;

  END;*/

/*PROCEDURE atualizarPrecoAtac AS

  MSG        VARCHAR2(232);
  vPrecoAtac NUMBER;
  vnumregiao NUMBER;
BEGIN

  FOR DADOS IN (SELECT (SELECT  NVL(E.CODAUXILIAR, 0)
                          FROM PCEMBALAGEM E
                         WHERE E.CODPROD = A.CODPROD
                           AND E.CODFILIAL = A.nroempresa
                           AND NVL(E.QTMINIMAATACADO, 0) = A.QTDEMBALAGEM
                           AND NVL(E.QTUNIT, 0) = 1
                           AND ROWNUM = 1) seqapartirde,
                        (SELECT NVL(E.QTMINIMAATACADO, 0)
                                  FROM PCEMBALAGEM E
                                 WHERE E.CODPROD = A.CODPROD
                                   AND E.CODFILIAL = A.nroempresa
                                   AND NVL(E.QTMINIMAATACADO, 0) = A.QTDEMBALAGEM
                                   AND NVL(E.QTUNIT, 0) = 1
                            AND ROWNUM = 1) QTMINIMAATACADO,
                       A.*
                  FROM (SELECT s.*,
                               (SELECT codproduto
                                  FROM monitorpdvmiddle.tb_produto a
                                 WHERE a.seqproduto = s.seqproduto) codprod

                          FROM monitorpdvmiddle.tb_prodpreco s) a
                 WHERE NVL(A.QTDEMBALAGEM, 0) IN
                       (SELECT NVL(E.QTMINIMAATACADO, 0)
                          FROM PCEMBALAGEM E
                         WHERE E.CODPROD = A.CODPROD
                           AND E.CODFILIAL = A.nroempresa)) LOOP
    BEGIN
      vnumregiao := ferramentas.f_buscarparametro_num('NUMREGIAOPADRAOVAREJO',
                                                             dados.nroempresa,
                                                             1);

      vPrecoAtac := coluna_preco(buscaprecos_atac(dados.nroempresa,
                                                                vnumregiao,
                                                                dados.seqapartirde,
                                                                trunc(SYSDATE)),
                                        'PVENDAATAC');

      UPDATE monitorpdvmiddle.tb_prodpreco a
         SET a.preco = vPrecoAtac * DADOS.QTMINIMAATACADO
       WHERE SEQPRODUTO = DADOS.SEQPRODUTO
         AND QTDEMBALAGEM = DADOS.QTDEMBALAGEM
         AND NROSEGMENTO = 1
         AND NROEMPRESA = DADOS.NROEMPRESA;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        NULL;
        -- MSG := DBMS_UTILITY.format_error_backtrace;
    END;
    --dbms_output.put_line(vPrecoAtac || ' - ' || MSG);
  END LOOP;

END;
exec_sinc_PRECO*/
  /*PROCEDURE  AS
    p_final_execucao TIMESTAMP;
  BEGIN
    atualizarProdPreco;
    atualizarPrecoAtac;

    p_final_execucao := SYSDATE;
    BEGIN
      UPDATE pccontroleconsinco s
         SET s.ultimaexecucao = p_final_execucao
       WHERE ID IN (21, 25)
         AND s.ativo = 'A';
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

  END;*/ 

END PKG_SINC_PDV_CONSINCO;   
