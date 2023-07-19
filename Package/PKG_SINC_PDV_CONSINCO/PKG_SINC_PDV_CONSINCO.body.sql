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
        USING (
        /*SELECT f.codigo nroempresa,
               1 nrosegmento,
               (CASE
                 WHEN f.dtexclusao IS NULL THEN
                   'S'
                 ELSE
                   'N'
                END) ativo,
                0 nrocarga
        FROM pcfilial f,
             (SELECT LEAST(A.ultimaexecucao, B.ultimaexecucao, C.ultimaexecucao) ULTIMAEXECUCAO
              FROM (SELECT s.ultimaexecucao FROM pccontroleconsinco s
              WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESA') A,
              (SELECT s.ultimaexecucao
               FROM pccontroleconsinco s
               WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_SEGMENTO') B,
              (SELECT s.ultimaexecucao
              FROM pccontroleconsinco s
              WHERE UPPER(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_EMPRESASEGMENTO') C) DTPADRAO
       where NVL(F.Dtalterc5, DTPADRAO.ULTIMAEXECUCAO)  >= DTPADRAO.ULTIMAEXECUCAO*/
       SELECT DISTINCT E.nroempresa, 1 nrosegmento, 'S' ativo, 0 nrocarga FROM VW_INT_C5_EMPRESA E
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
                    v.seqmarca,
                    v.seqfamgrupo,
                    v.pesavel
      FROM VW_INT_C5_FAMILIA v
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
                     s.pesavel = B.pesavel
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
                     s.pesavel)
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
                      B.pesavel);

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
             f.descricao formapagto,
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
          AND   E.codigo >= 0
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
        USING (SELECT distinct f.nroempresa,
                      f.nrosegmento,
                      f.nroformapagto,
                      f.percjuromensal,
                      f.perctaxaadm,
                      f.nrodiasvencto,
                      f.solicitavencto,
                      f.permitetroco,
                      f.vlrminimo,
                      f.vlrmaximo,
                      f.gerasangria,
                      f.prazomaximo,
                      f.usatef,
                      f.TIPOCALCULOJUROS,
                      f.emitevaletroco,
                      f.emitecomprovante,
                      f.abregaveta,
                      f.alternativa,
                      f.faturamento,
                      f.ativo
        FROM VW_INT_C5_FORMAPAGTOEMPRESA f
       WHERE F.NROEMPRESA NOT IN('2A') ) b

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
               s.faturamento      = b.faturamento
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
             s.nroempresa
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
             b.nroempresa);
    
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
        /*USING (SELECT
                 1 nrodivisao,
                 'VAREJO' divisao,
                 'V' tipo,
                 'S' ativo,
                 0 nrocarga
               FROM dual) b*/
        USING (SELECT
                 NUMREGIAO nrodivisao,
                 SUBSTR(REGIAO, 1, 19) divisao,
                 'V' tipo,
                 'S' ativo,
                 0 nrocarga
               FROM PCREGIAO) b

      ON (s.nrodivisao = b.nrodivisao)
      WHEN MATCHED THEN
      UPDATE SET
        s.tipo     = b.tipo,
        s.ativo    = b.ativo,
        s.nrocarga = b.nrocarga,
        s.divisao  = b.divisao
      WHEN NOT MATCHED THEN
        INSERT (s.tipo,
                s.ativo,
                s.nrocarga,
                s.nrodivisao,
                s.divisao)
                VALUES
                (b.tipo,
                 b.ativo,
                 b.nrocarga,
                 b.nrodivisao,
                 b.divisao);

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
               s.NIVELHIERARQUIA = b.nivelhierarquia
      WHEN NOT MATCHED THEN
        INSERT (s.seqcategoriapai,
                s.categoria,
                s.tipo,
                s.ativo,
                s.lerpeso,
                s.seqcategoria,
                s.nrodivisao,
                s.NIVELHIERARQUIA)
                VALUES
                (b.seqcategoriapai,
                 b.categoria,
                 b.tipo,
                 b.ativo,
                 b.lerpeso,
                 b.seqcategoria,
                 b.nrodivisao,
                 b.nivelhierarquia);

    
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

  PROCEDURE carrega_tb_famembalagem(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
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


  PROCEDURE carrega_tb_prodpreco(p_id IN pccontroleconsinco.id%TYPE) AS
    TYPE ARRAY IS TABLE OF VW_TB_PRODPRECO_NEW%ROWTYPE INDEX BY PLS_INTEGER;
    listaDados ARRAY;

    CURSOR c_tb_prodpreco IS
         SELECT
                    /*DISTINCT E.seqproduto,*/
                    E.seqproduto,
                    E.nroempresa,
                    E.nrosegmento,
                    E.qtdembalagem,
                    E.promocao,
                    1 preco,
                    E.ativo,
                    E.dtultalter_prod,
                    E.dtcadastro_prod,
                    E.dtcadastroemb,
                    E.dtulalterintegra,
                    E.dtultaltpvenda,
                    E.codauxiliar
      FROM VW_TB_PRODPRECO_NEW E/*, MONITORPDVMIDDLE.TB_PRODEMPRESA TBE
     WHERE E.SEQPRODUTO = TBE.SEQPRODUTO
       AND E.NROEMPRESA = TBE.NROEMPRESA*/;


    r_tb_prodpreco VW_TB_PRODPRECO_NEW%ROWTYPE;
    vNumRegiao     NUMBER := 0;
  BEGIN
    -- for i IN 1 .. listaDados.COUNT loop
    /*OPEN c_tb_prodpreco;
    LOOP
      FETCH c_tb_prodpreco BULK COLLECT
        INTO listaDados LIMIT 1000;
      BEGIN

        FOR i IN 1 .. listaDados.COUNT LOOP
          -- if vNumRegiao = 0 then
          vNumRegiao := ferramentas.F_BUSCARPARAMETRO_NUM('NUMREGIAOPADRAOVAREJO',
                                                                 listaDados(i).nroempresa,
                                                                 1);
          --end if;
          BEGIN
            listaDados(i).preco := coluna_preco(buscaprecos_consinco(listaDados(i).nroempresa,
                                                                                   vNumRegiao,
                                                                                   listaDados(i).codauxiliar,
                                                                                   TRUNC(SYSDATE),
                                                                                   0,
                                                                                   0,
                                                                                   0,
                                                                                   0,
                                                                                   0),
                                                       'PVENDA');

          EXCEPTION
            WHEN OTHERS THEN
              listadados(i).preco := 0;
          END;

        END LOOP;

        FORALL i IN 1 .. listaDados.COUNT
          MERGE INTO monitorpdvmiddle.tb_prodpreco s
          USING (SELECT listaDados(i).preco AS preco,
                        listaDados(i).promocao AS promocao,
                        listaDados(i).ativo AS ativo,
                        listaDados(i).seqproduto AS seqproduto,
                        listaDados(i).qtdembalagem AS qtdembalagem,
                        listaDados(i).nrosegmento AS nrosegmento,
                        listaDados(i).nroempresa AS nroempresa
                   FROM dual) mrg
          ON (s.seqproduto = mrg.seqproduto AND s.qtdembalagem = mrg.qtdembalagem AND s.nrosegmento = mrg.nrosegmento AND s.nroempresa = mrg.nroempresa)
          WHEN MATCHED THEN
            UPDATE
               SET preco    = mrg.preco,
                   promocao = mrg.promocao,
                   ativo    = mrg.ativo
            --WHERE s.seqproduto = mrg.seqproduto AND s.qtdembalagem = mrg.qtdembalagem AND s.nrosegmento = mrg.nrosegmento AND s.nroempresa = mrg.nroempresa

          WHEN NOT MATCHED THEN
            INSERT
              (preco,
               promocao,
               ativo,
               seqproduto,
               qtdembalagem,
               nrosegmento,
               nroempresa)
            VALUES
              (mrg.preco,
               mrg.promocao,
               mrg.ativo,
               mrg.seqproduto,
               mrg.qtdembalagem,
               mrg.nrosegmento,
               mrg.nroempresa);

        COMMIT;

      EXCEPTION
        WHEN OTHERS THEN
          INSERT INTO error_log s
            (ERROR_CODE,
             ERROR_MESSAGE,
             BACKTRACE,
             CALLSTACK,
             CREATED_ON,
             CREATED_BY)
          VALUES
            ('400',
             'carrega_tb_prodpreco ERROR',
             to_clob(dbms_utility.format_error_backtrace ||
                     dbms_Utility.format_error_stack),
             to_clob('Detalhes do erro: ' || CHR(10) || ' seqproduto =>' ||
                     r_tb_prodpreco.seqproduto || ' qtdembalagem => ' ||
                     r_tb_prodpreco.qtdembalagem || ' nrosegmento => ' ||
                     r_tb_prodpreco.nrosegmento || ' nroempresa =>  ' ||
                     r_tb_prodpreco.nroempresa || ' - ' || CHR(10) ||
                     dbms_utility.format_call_stack),
             SYSDATE,
             'INTERMEDIARIO');

      END;

      EXIT WHEN c_tb_prodpreco%NOTFOUND;
    END LOOP;

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_prodpreco',
       'carrega_tb_prodpreco OK',
       SYSDATE,
       CURRENT_TIMESTAMP);

    COMMIT;

    CLOSE c_tb_prodpreco;*/
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
               FROM VW_INT_C5_LEITRANSP b
              ) b
         
      ON (s.codnbmsh = b.codnbmsh)
      WHEN MATCHED THEN
      UPDATE SET
               s.idref                 = b.codfilial,
               s.ufdestino             = b.ufdestino,
               s.perctributoimportado  = b.perctributoimportado,
               s.perctributonacfederal = b.perctributonacfederal,
               s.perctributoimpfederal = b.perctributoimpfederal,
               s.perctributoestadual   = b.perctributoestadual,
               s.perctributomunicipal  = b.perctributomunicipal,
               s.ex                    = b.ex,
               s.ativo                 = b.ativo
        
      WHEN NOT MATCHED THEN
        INSERT (s.codnbmsh,
                s.idref,
                s.ufdestino,
                s.perctributoimportado,
                s.perctributonacfederal,
                s.perctributoimpfederal,
                s.perctributoestadual,
                s.perctributomunicipal,
                s.ex,
                s.ativo)
                VALUES
                  (b.codnbmsh,
                   b.codfilial,
                   b.ufdestino,
                   b.perctributoimportado,
                   b.perctributonacfederal,
                   b.perctributoimpfederal,
                   b.perctributoestadual,
                   b.perctributomunicipal,
                   b.ex,
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


  PROCEDURE carrega_tb_enderecoalternativo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN 
    MERGE INTO monitorpdvmiddle.tb_enderecoalternativo EnderecoAlternativoC5
    USING(SELECT * FROM VW_INT_C5_ENDERECO_ALTERNATIVO) ViewEnderecoAlt
    ON (EnderecoAlternativoC5.seqpessoa = ViewEnderecoAlt.seqpessoa and EnderecoAlternativoC5.seqlogradouro = ViewEnderecoAlt.SEQLOGRADOURO)
    WHEN MATCHED THEN
      UPDATE SET 
        EnderecoAlternativoC5.tipo = ViewEnderecoAlt.tipo,
        EnderecoAlternativoC5.logradouro = ViewEnderecoAlt.logradouro,
        EnderecoAlternativoC5.nrologradouro = ViewEnderecoAlt.nrologradouro,
        EnderecoAlternativoC5.bairro = ViewEnderecoAlt.bairro,
        EnderecoAlternativoC5.complemento = ViewEnderecoAlt.complemento,
        EnderecoAlternativoC5.cidade = ViewEnderecoAlt.cidade,
        EnderecoAlternativoC5.uf = ViewEnderecoAlt.uf,
        EnderecoAlternativoC5.cep = ViewEnderecoAlt.cep,
        EnderecoAlternativoC5.ativo = ViewEnderecoAlt.ativo,
        EnderecoAlternativoC5.codibge = ViewEnderecoAlt.codibge
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
        USING (SELECT DISTINCT E.seqfamilia,
             e.nrodivisao,
             E.nrotributacao,
             E.codorigemtrib,
             E.ativo
        --FROM vw_tb_famdivisao E,
        FROM VW_INT_C5_FAMDIVISAO E/*,
             MONITORPDVMIDDLE.TB_DIVISAO TBD,
             MONITORPDVMIDDLE.TB_TRIBUTACAO TBT,
             MONITORPDVMIDDLE.TB_FAMILIA TBF
       WHERE E.SEQFAMILIA = TBF.SEQFAMILIA
         AND E.NRODIVISAO = TBD.NRODIVISAO
         AND E.NROTRIBUTACAO = TBT.NROTRIBUTACAO*/
       ) b

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
