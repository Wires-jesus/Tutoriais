CREATE OR REPLACE PACKAGE BODY PKG_SINC_PDV_CONSINCO IS
  
  E_FK_VIOLATION EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FK_VIOLATION, -2291);
  
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
  
  FUNCTION obter_seqapartirde RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_PRODPRECOAPARTIR.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
  END;

  FUNCTION obter_seqregraincentivo RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_REGRAINCENTIVO.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
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
    /*INATIVANDO USUARIOS SEM GRUPO */
    UPDATE MONITORPDVMIDDLE.TB_USUARIO SET ATIVO = 'N'
    WHERE ATIVO = 'S'
    AND SEQUSUARIO IN (
      SELECT 
        SEQUSUARIO 
      FROM MONITORPDVMIDDLE.TB_GRUPOUSUARIO T
        LEFT JOIN VW_INT_C5_USUARIO_GRUPO V
        ON (V.CODGRUPO = T.SEQGRUPO AND T.ATIVO = 'S')
      WHERE V.CODGRUPO IS NULL
      UNION
      SELECT
        P.MATRICULA
      FROM
        PCEMPR P
        LEFT JOIN MONITORPDVMIDDLE.TB_GRUPOUSUARIO GU
        ON (GU.SEQGRUPO = P.CODSETOR)
        INNER JOIN MONITORPDVMIDDLE.TB_USUARIO U
        ON(U.SEQUSUARIO = P.MATRICULA)
      WHERE
        GU.SEQUSUARIO IS NULL
      );

    MERGE INTO monitorpdvmiddle.tb_usuario s
        USING (SELECT * FROM VW_INT_C5_USUARIO) b

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
               FROM VW_INT_C5_CLIPESSOA C,
                 MONITORPDVMIDDLE.TB_PESSOA T
               WHERE T.SEQPESSOA = C.SEQPESSOA    
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
                     -- p.idref
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
                -- s.idref           = b.idref
      WHEN NOT MATCHED THEN
        INSERT
            (s.SEQPRODUTO,
             s.DESCREDUZIDA,
             s.DESCCOMPLETA,
             s.ATIVO,
             s.PRODUTOCOMPOSTO,
             s.SEQFAMILIA,
             s.codproduto
            -- s.idref
             )
          VALUES
            (b.SEQPRODUTO,
             NVL(b.DESCREDUZIDA, '-'),
             NVL(b.DESCCOMPLETA, '-'),
             b.ATIVO,
             b.PRODUTOCOMPOSTO,
             b.SEQFAMILIA,
             b.codproduto
             --b.idref
             );

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
		ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_produto',
           'carrega_tb_produto ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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

  PROCEDURE carrega_tb_prodcomposto(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    UPDATE MONITORPDVMIDDLE.TB_PRODCOMPOSTO SET ATIVO = 'N'
    WHERE SEQPRODCOMPOSTO IN (SELECT SEQPRODCOMPOSTO FROM VW_INT_C5_PRODCOMPOSTO);
    
    MERGE INTO monitorpdvmiddle.tb_prodcomposto s
        USING (
               SELECT P.SEQPRODCOMPOSTO,
                      P.SEQPRODUTO,
                      P.QTDEMBALAGEM,
                      P.QUANTIDADE,
                      P.PRECO,
                      P.ATIVO
                      
        FROM VW_INT_C5_PRODCOMPOSTO P
        where P.SEQPRODCOMPOSTO not in (select VW.SEQPRODCOMPOSTO from VW_INT_C5_PRODCOMPOSTO vw where nvl(VW.PRECO, 0) = 0)
       ) b

      ON (s.seqproduto = b.SEQPRODUTO and s.qtdembalagem = b.qtdembalagem and s.SEQPRODCOMPOSTO = b.SEQPRODCOMPOSTO)
      WHEN MATCHED THEN
      UPDATE
             SET s.QUANTIDADE  = b.QUANTIDADE,
                 s.PRECO       = b.PRECO,
                 s.ATIVO       = b.ATIVO
      WHEN NOT MATCHED THEN
        INSERT
            (s.SEQPRODCOMPOSTO,
             s.SEQPRODUTO,
             s.QTDEMBALAGEM,
             s.QUANTIDADE,
             s.PRECO,
             s.ATIVO
             )
          VALUES
            (b.SEQPRODCOMPOSTO,
             b.SEQPRODUTO,
             b.QTDEMBALAGEM,
             b.QUANTIDADE,
             b.PRECO,
             b.ATIVO
             );

    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
		ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_prodcomposto',
           'carrega_tb_prodcomposto ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_prodcomposto',
           'carrega_tb_prodcomposto ERRO',
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
  MERGE INTO monitorpdvmiddle.tb_familia S
        USING (
             SELECT DISTINCT     
                    v.seqfamilia,
                    NVL(fnc_remove_char_esp(v.familia), '-') familia,
                    v.permitedecimal,
                    'N' as permitemultiplicacao,
                    v.codncmsh,
                    --v.codcest,
                    /*(SELECT nvl(CODCEST, 0) codcest
                     FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST
                     WHERE PCCESTPRODUTO.CODPROD = v.codprod
                     AND ROWNUM = 1
                    )*/ v.codcest,

                    v.ativo,
                    v.seqmarca,
                    v.seqfamgrupo,
                    v.pesavel,
                    v.indescala,
                    v.cnpjfabricante,
                    v.eantrib,
                    v.codprod idref,
                    NVL(PRODPISCOFINS.EXCLUIRICMSBASEPISCOFINS, 'N') gerareducaobasepiscofins,
                    --NVL(v.seqfamiliaprinc, v.seqfamilia) seqfamiliaprinc,
                    NVL(PRODPISCOFINS.SITTRIBUT, 0) SITUACAOPIS,
                    NVL(PRODPISCOFINS.SITTRIBUT, 0) SITUACAOCOFINS,
                    NVL(PRODPISCOFINS.PERCPIS, 0)PERCPIS,
                    NVL(PRODPISCOFINS.PERCCOFINS, 0)PERCCOFINS,
                    (CASE  
                      WHEN NVL(PRODPISCOFINS.EXCLUIRICMSBASEPISCOFINS, 'N') = 'S' THEN
                           0
                      ELSE 100 
                    END)  PERCBASEPIS,

                    (CASE  
                      WHEN NVL(PRODPISCOFINS.EXCLUIRICMSBASEPISCOFINS, 'N') = 'S' THEN
                           0
                      ELSE 100 
                    END)  PERCBASECOFINS

             FROM VW_INT_C5_FAMILIA v, 
                  
                  /*Para contemplar as alterações do pis/cofins na carga foi necessário
                    que as triggers da PCTABPR e PCTRIBPISCOFINS passassem a atualizar o
                    campo DTALTERC5 da PCPRODUT, pois a mesma é a base para alimentar
                    a TB_REGRAFAMILIA.
                   */
                  (SELECT R.CODPROD, 
                          T.SITTRIBUT, 
                          T.PERCPIS, 
                          T.PERCCOFINS, 
                          T.EXCLUIRICMSBASEPISCOFINS
                   FROM PCTABPR R, 
                        PCTRIBPISCOFINS T,
                                                
                        (SELECT S.ULTIMAEXECUCAO
                         FROM PCCONTROLECONSINCO S
                         WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA'
                        ) DATAPADRAO 
                   WHERE R.CODTRIBPISCOFINS = T.CODTRIBPISCOFINS 
                   AND   R.CODTRIBPISCOFINS IS NOT NULL
                   AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
                   AND   R.NUMREGIAO = ( SELECT VALOR
                                         FROM PCPARAMFILIAL
                                         WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                                         AND VALOR <> '99'
                                         AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                                         AND VALOR IS NOT NULL
                                         AND ROWNUM = 1)-- somente os dados de 1 região
                   AND  (NVL(T.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao OR
                         NVL(R.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao)

                   UNION ALL

                   SELECT R.CODPROD, 
                          T.SITTRIBUT, 
                          T.PERCPIS, 
                          T.PERCCOFINS, 
                          T.EXCLUIRICMSBASEPISCOFINS
                   FROM PCTABTRIB R, 
                        PCTRIBPISCOFINS T,
                        VW_INT_C5_OBTER_FILIAIS_C5 C5,
                                                
                        (SELECT S.ULTIMAEXECUCAO
                         FROM PCCONTROLECONSINCO S
                         WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA'
                        ) DATAPADRAO 
                   WHERE R.CODTRIBPISCOFINS = T.CODTRIBPISCOFINS 
                   AND   R.CODFILIALNF = C5.CODFILIAL
                   AND   R.CODTRIBPISCOFINS IS NOT NULL
                   AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S'
                   AND   R.UFDESTINO = (SELECT F.UF
                                        FROM PCFILIAL F
                                        WHERE F.UF IS NOT NULL
                                        AND   ROWNUM = 1)
                   AND  (NVL(T.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao OR
                         NVL(R.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao)      
                  ) PRODPISCOFINS --vinculo do produto com os dados de pis e cofins
             WHERE v.codprod = PRODPISCOFINS.CODPROD(+)
                
      ) B

      ON (S.seqfamilia = B.seqfamilia)
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
                     S.pesavel = B.pesavel,
                     S.situacaopis = B.SITUACAOPIS,
                     S.situacaocofins = B.SITUACAOCOFINS,
                     S.percbasepis = PERCBASEPIS,
                     S.percbasecofins = PERCBASECOFINS,
                     S.percpis = B.PERCPIS,
                     S.perccofins = B.PERCCOFINS,
                     S.indescala = B.indescala,
                     S.cnpjfabricante = B.cnpjfabricante,
                     S.eantrib = B.eantrib,
                     --S.seqfamiliaprinc = B.seqfamiliaprinc,
                     S.gerareducaobasepiscofins = B.gerareducaobasepiscofins,
                     S.idref = B.idref
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
                     S.pesavel,
                     S.situacaopis,
                     S.situacaocofins,
                     S.percbasepis,
                     S.percbasecofins,
                     S.percpis,
                     S.perccofins,
                     S.indescala,
                     S.cnpjfabricante,
                     S.eantrib,
                     --S.seqfamiliaprinc,
                     S.gerareducaobasepiscofins,
                     S.idref)
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
                      B.situacaopis,
                      B.situacaocofins,
                      B.percbasepis,
                      B.percbasecofins,
                      B.percpis,
                      B.perccofins,
                      B.indescala,
                      B.cnpjfabricante,
                      B.eantrib,
                      --B.seqfamiliaprinc,
                      B.gerareducaobasepiscofins,
                      B.idref);

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
        ('pkg_sinc_PDV_Consinco', 'c_tb_familia', 'c_tb_familia ERRO', SYSDATE, CURRENT_TIMESTAMP);
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
               FROM VW_INT_C5_CLIPESSOA C,
                MONITORPDVMIDDLE.TB_PESSOA T
               WHERE T.SEQPESSOA = C.SEQPESSOA
               ) b

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
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_clientesegmento',
           'carrega_tb_clientesegmento ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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
               (select min(s.ultimaexecucao) ultimaexecucao
                from pccontroleconsinco s
                where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FORMAPAGTOEMPRESA')
                or    (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FORMAPAGTO')
               ) D
          WHERE f.especie = vef.winthor(+)
          AND   F.CODFILIAL = E.codigo
		      --AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USAINTEGRACAOCONSINCO', E.CODIGO, 'N')= 'S'
          AND  ((FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USAINTEGRACAOCONSINCO', E.CODIGO, 'N')= 'S') OR (F.CODFILIAL = '99'))
          AND   f.codcob = c.codcob(+)
          AND   E.codigo >= '0'
          --AND   E.codigo < '99'
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
               s.ativo            = b.ativo,
               s.nroParcelaJuro   = b.nroParcelaJuro,
               s.VLRMINIMOPARCELA = b.VLRMINIMOPARCELA
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
             s.ativo,
             s.nroParcelaJuro,
             s.VLRMINIMOPARCELA
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
             b.ativo,
             b.nroParcelaJuro,
             b.VLRMINIMOPARCELA);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_formapagtoempresa',
           'carrega_tb_formapagtoempresa ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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
    vRegProcessados number;
  BEGIN
  MERGE INTO monitorpdvmiddle.tb_famdivisaocategoria s
        USING (SELECT  
                      SD.seqfamilia, 
                      SD.seqcategoria, 
                      SD.nrodivisao, 
                      SD.ativo,
                      SD.idref
               FROM VW_INT_C5_FAMDIVISAOCATEGORIA SD) b

      ON (s.SEQCATEGORIA = b.SEQCATEGORIA AND s.NRODIVISAO = b.NRODIVISAO  AND s.SEQFAMILIA = b.seqfamilia )
      WHEN MATCHED THEN
      UPDATE SET
        s.ativo = b.ativo,
        s.idref = b.idref
      WHEN NOT MATCHED THEN
        INSERT (s.seqfamilia,
                s.seqcategoria,
                s.nrodivisao,
                s.ativo,
                s.idref)
                VALUES
                (b.seqfamilia,
                 b.seqcategoria,
                 b.nrodivisao,
                 b.ativo,
                 b.idref);
  
  vRegProcessados := SQL%ROWCOUNT;
  
  pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

  COMMIT;
  
  IF (vRegProcessados > 0) THEN
    UPDATE MONITORPDVMIDDLE.tb_famdivisaocategoria D SET
           ATIVO = 'N'
    WHERE ATIVO = 'S'
    AND   D.SEQCATEGORIA||D.SEQFAMILIA||NRODIVISAO in 
                                         (SELECT
                                              TAB_FAMCATEGORIA.SEQCATEGORIA||TAB_FAMCATEGORIA.SEQFAMILIA||TAB_FAMCATEGORIA.NRODIVISAO FAMCATEGORIA
                                          FROM(
                                               SELECT
                                                  ROW_NUMBER() OVER(partition by F.SEQFAMILIA,
                                                         F.NRODIVISAO
                                                  ORDER BY  F.DTAHORALTERACAO DESC
                                                  ) SEQUENCIA,
                                                  F.SEQFAMILIA,
                                                  F.SEQCATEGORIA,
                                                  F.NRODIVISAO

                                                FROM MONITORPDVMIDDLE.tb_famdivisaocategoria F
                                                WHERE F.ATIVO = 'S'
                                               ) TAB_FAMCATEGORIA
                                          WHERE TAB_FAMCATEGORIA.SEQUENCIA > 1
                                          AND   TAB_FAMCATEGORIA.SEQFAMILIA = D.SEQFAMILIA
                                          AND   TAB_FAMCATEGORIA.NRODIVISAO = D.NRODIVISAO);
  END IF;                         
  
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
                      Ep.idref,
                      Ep.nroempresa,
                      0 estqloja,
                      0 PERCALIQISS,
                      'S' ativo
         FROM VW_INT_C5_PRODEMPRESA ep) b

      ON (s.seqproduto = b.seqproduto and s.nroempresa  = b.nroempresa)
      WHEN MATCHED THEN
      UPDATE SET
        estqloja = b.estqloja,
        ativo    = b.ativo,
        idref    = b.idref
      WHEN NOT MATCHED THEN
        INSERT (s.seqproduto,
                s.nroempresa,
                s.estqloja,
                s.PERCALIQISS,
                s.ativo,
                s.idref)
                VALUES
                (b.seqproduto,
                 b.nroempresa,
                 b.estqloja,
                 b.percaliqiss,
                 b.ativo,
                 b.idref);
    
    pkg_sinc_PDV_Consinco.set_final_execucao(CURRENT_TIMESTAMP);

    COMMIT;

  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'c_tb_prodempresa',
           'c_tb_prodempresa ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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
	  WHEN E_FK_VIOLATION THEN
	    BEGIN
	      PRC_RECORD_ALERTA(p_id);
          ROLLBACK;
          INSERT INTO PCDEVLOGCONSINCO
            (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
          VALUES
            ('pkg_sinc_PDV_Consinco', 'carrega_tb_famembalagem', 'carrega_tb_famembalagem ALERTA', SYSDATE, CURRENT_TIMESTAMP);
          COMMIT;
	    END;
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
	  WHEN E_FK_VIOLATION THEN
	    BEGIN
	      PRC_RECORD_ALERTA(p_id);
          ROLLBACK;
          INSERT INTO PCDEVLOGCONSINCO
            (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
          VALUES
            ('pkg_sinc_PDV_Consinco', 'c_tb_prodcodigo', 'c_tb_prodcodigo ALERTA', SYSDATE, CURRENT_TIMESTAMP);
          COMMIT;
	    END;
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
  BEGIN
    --Preco
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
        TB_PRODPRECO_C5.ativo      = VIEW_TB_PRODPRECO.ativo,
        TB_PRODPRECO_C5.promocao   = VIEW_TB_PRODPRECO.promocao,
        TB_PRODPRECO_C5.preco      = VIEW_TB_PRODPRECO.preco,
        TB_PRODPRECO_C5.PRECONORMAL= VIEW_TB_PRODPRECO.PRECONORMAL,
        TB_PRODPRECO_C5.idref      = VIEW_TB_PRODPRECO.idref
      WHEN NOT MATCHED THEN
      INSERT(
        TB_PRODPRECO_C5.seqproduto,
        TB_PRODPRECO_C5.qtdembalagem,
        TB_PRODPRECO_C5.nrosegmento,
        TB_PRODPRECO_C5.nroempresa,
        TB_PRODPRECO_C5.ativo,
        TB_PRODPRECO_C5.promocao,
        TB_PRODPRECO_C5.preco,
        TB_PRODPRECO_C5.PRECONORMAL,
        TB_PRODPRECO_C5.idref
      ) 
      VALUES(
        VIEW_TB_PRODPRECO.seqproduto,
        VIEW_TB_PRODPRECO.qtdembalagem,
        VIEW_TB_PRODPRECO.nrosegmento,
        VIEW_TB_PRODPRECO.nroempresa,
        VIEW_TB_PRODPRECO.ativo,
        VIEW_TB_PRODPRECO.promocao,
        VIEW_TB_PRODPRECO.preco,
        VIEW_TB_PRODPRECO.PRECONORMAL,
        VIEW_TB_PRODPRECO.idref
      );

    --Controle promoções
    MERGE INTO monitorpdvmiddle.tb_prodpreco TB_PRODPRECO_C5
      USING (SELECT MIN(v.idref) idref,
				   v.seqproduto,
				   v.nroempresa,
				   v.qtdembalagem,
				   v.nrosegmento,
				   MIN(v.preco) preco,
				   MIN(v.promocao) promocao,
				   MIN(v.ativo) ativo,
				   MIN(v.preconormal) preconormal
			  FROM vw_int_c5_promocoes_vigentes v
			 WHERE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM',v.NROEMPRESA,'N') = 'S'
			   AND v.PRIORIDADE = (SELECT min(PRIORIDADE)
								   FROM VW_INT_C5_PROMOCOES_VIGENTES vw
								  WHERE vw.seqproduto = v.SEQPRODUTO
									AND vw.nroempresa = v.NROEMPRESA
									AND vw.qtdembalagem = v.QTDEMBALAGEM)
			 GROUP BY v.seqproduto, v.nroempresa, v.qtdembalagem, v.nrosegmento           
    ) VW_INT_C5_PROMOCOES_VIGENTES 
    on(
      TB_PRODPRECO_C5.seqproduto       = VW_INT_C5_PROMOCOES_VIGENTES.seqproduto 
      AND TB_PRODPRECO_C5.qtdembalagem = VW_INT_C5_PROMOCOES_VIGENTES.qtdembalagem 
      AND TB_PRODPRECO_C5.nrosegmento  = VW_INT_C5_PROMOCOES_VIGENTES.nrosegmento 
      AND TB_PRODPRECO_C5.nroempresa   = VW_INT_C5_PROMOCOES_VIGENTES.nroempresa
    )
    WHEN MATCHED THEN
    UPDATE SET
      TB_PRODPRECO_C5.ativo      = VW_INT_C5_PROMOCOES_VIGENTES.ativo,
      TB_PRODPRECO_C5.promocao   = VW_INT_C5_PROMOCOES_VIGENTES.promocao,
      TB_PRODPRECO_C5.preco      = VW_INT_C5_PROMOCOES_VIGENTES.preco,
      TB_PRODPRECO_C5.PRECONORMAL= VW_INT_C5_PROMOCOES_VIGENTES.PRECONORMAL,
      TB_PRODPRECO_C5.idref      = VW_INT_C5_PROMOCOES_VIGENTES.idref
    WHEN NOT MATCHED THEN
    INSERT(
      TB_PRODPRECO_C5.seqproduto,
      TB_PRODPRECO_C5.qtdembalagem,
      TB_PRODPRECO_C5.nrosegmento,
      TB_PRODPRECO_C5.nroempresa,
      TB_PRODPRECO_C5.ativo,
      TB_PRODPRECO_C5.promocao,
      TB_PRODPRECO_C5.preco,
      TB_PRODPRECO_C5.PRECONORMAL,
      TB_PRODPRECO_C5.idref
    ) 
    VALUES(
      VW_INT_C5_PROMOCOES_VIGENTES.seqproduto,
      VW_INT_C5_PROMOCOES_VIGENTES.qtdembalagem,
      VW_INT_C5_PROMOCOES_VIGENTES.nrosegmento,
      VW_INT_C5_PROMOCOES_VIGENTES.nroempresa,
      VW_INT_C5_PROMOCOES_VIGENTES.ativo,
      VW_INT_C5_PROMOCOES_VIGENTES.promocao,
      VW_INT_C5_PROMOCOES_VIGENTES.preco,
      VW_INT_C5_PROMOCOES_VIGENTES.PRECONORMAL,
      VW_INT_C5_PROMOCOES_VIGENTES.idref
    );

      --VOLTANDO PRECO NORMAL QUANDO SAIR DE VIGENCIA
    UPDATE MONITORPDVMIDDLE.TB_PRODPRECO TB_PRODPRECO SET 
      PRECO = PRECONORMAL,
      PROMOCAO = 'N',
      PRECONORMAL = NULL
    WHERE (SEQPRODUTO, QTDEMBALAGEM, NROEMPRESA) IN (
      SELECT
        TB_PRODPRECO.SEQPRODUTO,
        TB_PRODPRECO.QTDEMBALAGEM,
        TB_PRODPRECO.NROEMPRESA
      FROM
        MONITORPDVMIDDLE.TB_PRODPRECO TB_PRODPRECO
        LEFT JOIN VW_INT_C5_PROMOCOES_VIGENTES
        ON (TO_NUMBER(VW_INT_C5_PROMOCOES_VIGENTES.SEQPRODUTO) = TB_PRODPRECO.SEQPRODUTO
        AND VW_INT_C5_PROMOCOES_VIGENTES.QTDEMBALAGEM = TB_PRODPRECO.QTDEMBALAGEM
        AND VW_INT_C5_PROMOCOES_VIGENTES.NROEMPRESA = TB_PRODPRECO.NROEMPRESA)
      WHERE
        TB_PRODPRECO.PROMOCAO = 'S'
        AND TB_PRODPRECO.PRECONORMAL IS NOT NULL
        AND TB_PRODPRECO.ATIVO = 'S'
        AND VW_INT_C5_PROMOCOES_VIGENTES.SEQPRODUTO IS NULL
    );

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco', 'carrega_tb_prodpreco', 'carrega_tb_prodpreco OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  EXCEPTION
   WHEN E_FK_VIOLATION THEN
	BEGIN
	  PRC_RECORD_ALERTA(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco',
          'carrega_tb_prodpreco',
          'carrega_tb_prodpreco ALERTA',
          SYSDATE,
          CURRENT_TIMESTAMP);
      COMMIT;
	END;
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

    /*CURSOR c_tb_tributacaouf IS
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
    END;*/
  BEGIN
    MERGE INTO monitorpdvmiddle.tb_tributacaouf s
        USING (SELECT DISTINCT 
                  e.nrotributacao,
                e.uforigem,
                e.ufdestino,
                e.tipotributacao,
                e.nroregtributacao,
                e.percaliquota,
                e.situacaotributacao,
                e.percisento,
                e.perctributado,
                e.percoutro,
                e.percacrescst,
                e.percisentost,
                e.tipocalcfcp,
                e.percbasefcpicms,
                e.percaliqfcpicms,
                e.reducaobasest,
                e.tiporeducaoicmscalcst,
                e.perctributst,
                e.ativo,
                e.percbasefcpst,
                e.percaliqfcpst,
                e.CALCICMSDESON,
                e.PERCALIQICMSDESON,
                e.MOTIVODESONICMS,
                e.CODBENEFICIODESONICMS,
                e.codobservacao,
                e.IDREF
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
             s.percbasefcpst         = b.percbasefcpst,
             s.percaliqfcpst         = b.percaliqfcpst,
             s.CALCICMSDESON         = b.CALCICMSDESON,
             s.PERCALIQICMSDESON     = b.PERCALIQICMSDESON,
             s.MOTIVODESONICMS       = b.MOTIVODESONICMS,
             s.CODBENEFICIODESONICMS = b.CODBENEFICIODESONICMS,
             s.codobservacao         = b.codobservacao,
             s.IDREF                 = b.IDREF
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
                s.percbasefcpst,
                s.percaliqfcpst,
                s.CALCICMSDESON,
                s.PERCALIQICMSDESON,
                s.MOTIVODESONICMS,
                s.CODBENEFICIODESONICMS,
                s.codobservacao,
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
                 b.percbasefcpst,
                 b.percaliqfcpst,
                 b.CALCICMSDESON,
                 b.PERCALIQICMSDESON,
                 b.MOTIVODESONICMS,
                 b.CODBENEFICIODESONICMS,
                 b.codobservacao,
                 b.IDREF);
    
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

    MERGE INTO monitorpdvmiddle.tb_enderecoalternativo TB_ENDERECOALTERNATIVO
    USING(SELECT * FROM VW_INT_C5_ENDERECO_ALTERNATIVO) VW_INT_C5_ENDERECO_ALTERNATIVO
    ON (TB_ENDERECOALTERNATIVO.seqpessoa = VW_INT_C5_ENDERECO_ALTERNATIVO.seqpessoa and TB_ENDERECOALTERNATIVO.seqlogradouro = VW_INT_C5_ENDERECO_ALTERNATIVO.SEQLOGRADOURO)
    WHEN MATCHED THEN
      UPDATE SET 
        TB_ENDERECOALTERNATIVO.tipo          = VW_INT_C5_ENDERECO_ALTERNATIVO.tipo,
        TB_ENDERECOALTERNATIVO.logradouro    = VW_INT_C5_ENDERECO_ALTERNATIVO.logradouro,
        TB_ENDERECOALTERNATIVO.nrologradouro = VW_INT_C5_ENDERECO_ALTERNATIVO.nrologradouro,
        TB_ENDERECOALTERNATIVO.bairro        = VW_INT_C5_ENDERECO_ALTERNATIVO.bairro,
        TB_ENDERECOALTERNATIVO.complemento   = VW_INT_C5_ENDERECO_ALTERNATIVO.complemento,
        TB_ENDERECOALTERNATIVO.cidade        = VW_INT_C5_ENDERECO_ALTERNATIVO.cidade,
        TB_ENDERECOALTERNATIVO.uf            = VW_INT_C5_ENDERECO_ALTERNATIVO.uf,
        TB_ENDERECOALTERNATIVO.cep           = VW_INT_C5_ENDERECO_ALTERNATIVO.cep,
        TB_ENDERECOALTERNATIVO.ativo         = VW_INT_C5_ENDERECO_ALTERNATIVO.ativo,
        TB_ENDERECOALTERNATIVO.codibge       = VW_INT_C5_ENDERECO_ALTERNATIVO.codibge
      WHEN NOT MATCHED THEN
        INSERT  
        (
	        TB_ENDERECOALTERNATIVO.seqpessoa,
	        TB_ENDERECOALTERNATIVO.seqlogradouro,
	        TB_ENDERECOALTERNATIVO.tipo,
	        TB_ENDERECOALTERNATIVO.logradouro,
	        TB_ENDERECOALTERNATIVO.nrologradouro,
	        TB_ENDERECOALTERNATIVO.bairro,
	        TB_ENDERECOALTERNATIVO.complemento,
	        TB_ENDERECOALTERNATIVO.cidade,
	        TB_ENDERECOALTERNATIVO.uf,
	        TB_ENDERECOALTERNATIVO.cep,
	        TB_ENDERECOALTERNATIVO.ativo,
	        TB_ENDERECOALTERNATIVO.codibge
        )
        VALUES
        (
          VW_INT_C5_ENDERECO_ALTERNATIVO.seqpessoa,
          VW_INT_C5_ENDERECO_ALTERNATIVO.seqlogradouro,
          VW_INT_C5_ENDERECO_ALTERNATIVO.tipo,
          VW_INT_C5_ENDERECO_ALTERNATIVO.logradouro,
          VW_INT_C5_ENDERECO_ALTERNATIVO.nrologradouro,
          VW_INT_C5_ENDERECO_ALTERNATIVO.bairro,
          VW_INT_C5_ENDERECO_ALTERNATIVO.complemento,
          VW_INT_C5_ENDERECO_ALTERNATIVO.cidade,
          VW_INT_C5_ENDERECO_ALTERNATIVO.uf,
          VW_INT_C5_ENDERECO_ALTERNATIVO.cep,
          VW_INT_C5_ENDERECO_ALTERNATIVO.ativo,
          VW_INT_C5_ENDERECO_ALTERNATIVO.codibge
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
        USING (SELECT distinct 
                     E.seqfamilia,
                     E.nrodivisao,
                     E.nrotributacao,
                     E.codorigemtrib,
                     E.ativo
               FROM VW_INT_C5_FAMDIVISAO E,
                    PCPRODFILIAL F,
                    VW_INT_C5_OBTER_FILIAIS_C5 c5
               WHERE E.CODPROD = F.CODPROD
               AND   C5.CODFILIAL = F.CODFILIAL) b

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
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_famdivisao',
           'carrega_tb_famdivisao ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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
              s.ATIVO = b.ATIVO,
              s.IDREF = b.IDREF

      WHEN NOT MATCHED THEN
        INSERT (s.NROCONDICAOPAGTO,
                s.CONDICAOPAGTO,
                s.PERCACRESCIMO,
                s.NROMAXIMOPARCELA,
                s.NRODIASVENCTO,
                s.ATIVO,
                s.IDREF
                )
                VALUES
                  (b.NROCONDICAOPAGTO,
                   b.CONDICAOPAGTO,
                   b.PERCACRESCIMO,
                   b.NROMAXIMOPARCELA,
                   b.NRODIASVENCTO,
                   b.ATIVO,
                   b.IDREF
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
      UPDATE monitorpdvmiddle.TB_REGRAINCENTIVO SET ATIVO = 'N'
      WHERE ATIVO = 'S'
      AND   SUBSTR(IDREF, LENGTH(IDREF) -3, LENGTH(IDREF))  = '2017';
      
      MERGE INTO monitorpdvmiddle.tb_regraincentivo tb_regraincentivo_C5
        USING (SELECT DISTINCT * FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
      on(
        tb_regraincentivo_C5.SEQREGRA         = VIEW_C5_INCENTIVO.SEQREGRA 
      )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraincentivo_C5.REGRA          = VIEW_C5_INCENTIVO.REGRA,
          tb_regraincentivo_C5.SEQTIPOCREDITO = VIEW_C5_INCENTIVO.SEQTIPOCREDITO,
          tb_regraincentivo_C5.ATIVO          = VIEW_C5_INCENTIVO.ATIVO,
          tb_regraincentivo_C5.TIPOREGRA      = VIEW_C5_INCENTIVO.TIPOREGRA,
          tb_regraincentivo_C5.CUMULATIVO     = VIEW_C5_INCENTIVO.CUMULATIVO,
          tb_regraincentivo_C5.IDREF          = VIEW_C5_INCENTIVO.IDREF          
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraincentivo_C5.SEQREGRA,
          tb_regraincentivo_C5.REGRA,
          tb_regraincentivo_C5.SEQTIPOCREDITO,
          tb_regraincentivo_C5.ATIVO,
          tb_regraincentivo_C5.TIPOREGRA,
          tb_regraincentivo_C5.CUMULATIVO, 
          tb_regraincentivo_C5.IDREF         
        ) 
        VALUES(
          --VIEW_C5_INCENTIVO.SEQREGRA,
          (PKG_SINC_PDV_CONSINCO.obter_seqregraincentivo),
          VIEW_C5_INCENTIVO.REGRA,
          VIEW_C5_INCENTIVO.SEQTIPOCREDITO,
          VIEW_C5_INCENTIVO.ATIVO,
          VIEW_C5_INCENTIVO.TIPOREGRA,
          VIEW_C5_INCENTIVO.CUMULATIVO,
          VIEW_C5_INCENTIVO.IDREF
        );

   UPDATE MONITORPDVMIDDLE.tb_regraincentivo SET ATIVO = 'N'
   WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM)
      OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA);
   
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraincentivo', 'carrega_tb_regraincentivo OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
    EXCEPTION
	WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraincentivo',
           'carrega_tb_regraincentivo ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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
      UPDATE monitorpdvmiddle.TB_REGRAINCENTIVOPERIODO SET ATIVO = 'N'
      WHERE ATIVO = 'S'
      --AND   IDREF = '2017';
      AND   SUBSTR(IDREF, LENGTH(IDREF) -3, LENGTH(IDREF))  = '2017';
      
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
    WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM)
       OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA);

    UPDATE MONITORPDVMIDDLE.tb_REGRAINCENTIVOPERIODO r SET ATIVO = 'N'
      WHERE NOT EXISTS (
                        SELECT C.CODOFERTA
                        FROM PCOFERTAPROGRAMADAC C 
                        WHERE (CASE
                                  WHEN C.HORAINICIAL IS NOT NULL THEN
                                     TO_CHAR(C.HORAINICIAL, 'DD-MM-YYYY HH24:MI:SS')
                                  ELSE
                                    TO_CHAR(C.DTINICIAL, 'DD-MM-YYYY') || ' 00:00:01'
                                END) =  TO_CHAR(R.DTAHORINICIO, 'DD-MM-YYYY HH24:MI:SS')
                          AND 
                          (CASE 
                              WHEN HORAFINAL IS NOT NULL THEN
                                  TO_CHAR(C.HORAFINAL, 'DD-MM-YYYY HH24:MI:SS')
                                ELSE
                                  TO_CHAR(C.DTFINAL, 'DD-MM-YYYY') || ' 23:59:59' 
                            END) =  TO_CHAR(R.DTAHORFIM, 'DD-MM-YYYY HH24:MI:SS')
                        AND  R.IDREF = C.codfilial||C.codoferta||2011
                       )
      --AND IDREF = 2011;
      AND   SUBSTR(IDREF, LENGTH(IDREF) -3, LENGTH(IDREF))  = '2011';
    
    INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraincentperiodo', 'carrega_tb_regraincentperiodo OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
    EXCEPTION
	WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraincentperiodo',
           'carrega_tb_regraincentperiodo ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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

PROCEDURE carrega_tb_regraempresa(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regraempresa tb_regraempresa_c5
        USING (SELECT * FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
      on(tb_regraempresa_c5.SEQREGRA     = VIEW_C5_INCENTIVO.SEQREGRA AND
         tb_regraempresa_c5.NROEMPRESA   = VIEW_C5_INCENTIVO.NROEMPRESA
        )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraempresa_c5.ATIVO  = VIEW_C5_INCENTIVO.ATIVO
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraempresa_c5.SEQREGRA,
          tb_regraempresa_c5.NROEMPRESA,
          tb_regraempresa_c5.ATIVO
        ) 
        VALUES(
          VIEW_C5_INCENTIVO.SEQREGRA,
          VIEW_C5_INCENTIVO.NROEMPRESA,
          VIEW_C5_INCENTIVO.ATIVO
        );
      
  INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraempresa', 'carrega_tb_regraempresa OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
		ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraempresa',
           'carrega_tb_regraempresa ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraempresa',
           'carrega_tb_regraempresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_regrasegmento(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regrasegmento tb_regrasegmento_c5
        USING (SELECT * FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
        on(tb_regrasegmento_c5.SEQREGRA      = VIEW_C5_INCENTIVO.SEQREGRA AND
           tb_regrasegmento_c5.NROSEGMENTO   = 1
          )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regrasegmento_c5.ATIVO  = VIEW_C5_INCENTIVO.ATIVO
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regrasegmento_c5.SEQREGRA,
          tb_regrasegmento_c5.NROSEGMENTO,
          tb_regrasegmento_c5.ATIVO
          
        ) 
        VALUES
        (
          VIEW_C5_INCENTIVO.SEQREGRA,
          1,
          VIEW_C5_INCENTIVO.ATIVO
        );
      
  INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regrasegmento', 'carrega_tb_regrsegmento OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;

  EXCEPTION
     WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regrasegmento',
           'carrega_tb_regrasegmento ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
      BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regrasegmento',
           'carrega_tb_regrasegmento ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_regraproduto(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
      MERGE INTO monitorpdvmiddle.tb_regraproduto tb_regraproduto_c5
        USING 
             (
               SELECT SEQREGRA, SEQPRODUTO, QTDEMBALAGEM, PERCDESCONTO, PRECO, ATIVO, IDREF  
               FROM VW_INT_C5_DESC561PRODUTO
               UNION ALL
               SELECT SEQREGRA, SEQPRODUTO, QTDEMBALAGEM, PERCDESCONTO, PRECO, ATIVO, IDREF 
               FROM VW_INT_C5_PRECOFIXO_R357 
              ) vw_int_c5_regraproduto
      on(
            tb_regraproduto_c5.SEQPRODUTO    = vw_int_c5_regraproduto.SEQPRODUTO        
        AND tb_regraproduto_c5.QTDEMBALAGEM  = vw_int_c5_regraproduto.QTDEMBALAGEM
        AND tb_regraproduto_c5.SEQREGRA      = vw_int_c5_regraproduto.SEQREGRA        
      )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraproduto_c5.PERCDESCONTO    = vw_int_c5_regraproduto.PERCDESCONTO,
          tb_regraproduto_c5.PRECO           = vw_int_c5_regraproduto.PRECO,
          tb_regraproduto_c5.ATIVO           = vw_int_c5_regraproduto.ATIVO,
          tb_regraproduto_c5.IDREF           = vw_int_c5_regraproduto.IDREF  
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraproduto_c5.SEQREGRA,
          tb_regraproduto_c5.SEQPRODUTO,
          tb_regraproduto_c5.QTDEMBALAGEM,
          tb_regraproduto_c5.PERCDESCONTO,
          tb_regraproduto_c5.PRECO,          
          tb_regraproduto_c5.ATIVO,
          tb_regraproduto_c5.IDREF          
        ) 
        VALUES(
          vw_int_c5_regraproduto.SEQREGRA,
          vw_int_c5_regraproduto.SEQPRODUTO,
          vw_int_c5_regraproduto.QTDEMBALAGEM,
          vw_int_c5_regraproduto.PERCDESCONTO,
          vw_int_c5_regraproduto.PRECO,
          vw_int_c5_regraproduto.ATIVO,
          vw_int_c5_regraproduto.IDREF
        );

      UPDATE MONITORPDVMIDDLE.tb_regraproduto SET ATIVO = 'N'
      WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM)
      OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA);

      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_regraproduto', 'carrega_tb_regraproduto OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
    EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regraproduto',
           'carrega_tb_regraproduto ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;	
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
  WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regracliente', 'carrega_tb_regracliente OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regracliente',
           'carrega_tb_regracliente ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;	
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
  WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regracategoria', 'carrega_tb_regracategoria OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_regracategoria',
           'carrega_tb_regracategoria ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;  
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

PROCEDURE carrega_tb_prodprecoapartir(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_prodprecoapartir R SET  R.ATIVO = 'N'
  WHERE TRUNC(SYSDATE) BETWEEN R.DTAINICIO AND R.DTAFIM
  AND R.ATIVO = 'S';
  
  /*UPDATE monitorpdvmiddle.tb_prodprecoapartir R SET R.IDREF = '0', R.ATIVO = 'N'
  WHERE TRUNC(SYSDATE) BETWEEN R.DTAINICIO AND R.DTAFIM
  AND R.ATIVO = 'S';*/
  
  MERGE INTO monitorpdvmiddle.tb_prodprecoapartir tb_prodprecoapartir_c5
        USING (SELECT * FROM VW_INT_C5_PRODPRECOAPARTIR) vw_int_c5_prodprecoapartir
  ON   (
            tb_prodprecoapartir_c5.NROEMPRESA    = vw_int_c5_prodprecoapartir.NROEMPRESA        
        AND tb_prodprecoapartir_c5.SEQAPARTIRDE  = vw_int_c5_prodprecoapartir.Seqapartirde
       )
       WHEN MATCHED THEN
        UPDATE SET
          tb_prodprecoapartir_c5.NROSEGMENTO     = vw_int_c5_prodprecoapartir.NROSEGMENTO,
          tb_prodprecoapartir_c5.SEQFAMILIA      = vw_int_c5_prodprecoapartir.SEQFAMILIA,
          tb_prodprecoapartir_c5.SEQPRODUTO      = vw_int_c5_prodprecoapartir.SEQPRODUTO,
          tb_prodprecoapartir_c5.QTDE            = vw_int_c5_prodprecoapartir.QTDE,
          tb_prodprecoapartir_c5.PERCDESCONTO    = vw_int_c5_prodprecoapartir.PERCDESCONTO,
          tb_prodprecoapartir_c5.PRECO           = vw_int_c5_prodprecoapartir.PRECO,
          tb_prodprecoapartir_c5.DTAINICIO       = vw_int_c5_prodprecoapartir.DTAINICIO,
          tb_prodprecoapartir_c5.DTAFIM          = vw_int_c5_prodprecoapartir.DTAFIM,
          tb_prodprecoapartir_c5.ATIVO           = vw_int_c5_prodprecoapartir.ATIVO,
          tb_prodprecoapartir_c5.IDREF           = vw_int_c5_prodprecoapartir.IDREF
         /* tb_prodprecoapartir_c5.IDREF           = DECODE(vw_int_c5_prodprecoapartir.ATIVO, 'N', 
                                                          'INATIVADO',
                                                          vw_int_c5_prodprecoapartir.IDREF) */
          
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_prodprecoapartir_c5.NROEMPRESA,
          tb_prodprecoapartir_c5.SEQAPARTIRDE,
          tb_prodprecoapartir_c5.NROSEGMENTO,
          tb_prodprecoapartir_c5.SEQFAMILIA,
          tb_prodprecoapartir_c5.SEQPRODUTO,
          tb_prodprecoapartir_c5.QTDE,
          tb_prodprecoapartir_c5.PRECO,          
          tb_prodprecoapartir_c5.PERCDESCONTO,
          tb_prodprecoapartir_c5.DTAINICIO,
          tb_prodprecoapartir_c5.DTAFIM,
          tb_prodprecoapartir_c5.ATIVO,
          tb_prodprecoapartir_c5.IDREF          
        ) 
        VALUES(
          vw_int_c5_prodprecoapartir.NROEMPRESA,
          (PKG_SINC_PDV_CONSINCO.obter_seqapartirde), 
          vw_int_c5_prodprecoapartir.NROSEGMENTO,
          vw_int_c5_prodprecoapartir.SEQFAMILIA,
          vw_int_c5_prodprecoapartir.SEQPRODUTO,
          vw_int_c5_prodprecoapartir.QTDE,
          vw_int_c5_prodprecoapartir.PRECO,          
          vw_int_c5_prodprecoapartir.PERCDESCONTO,
          vw_int_c5_prodprecoapartir.DTAINICIO,
          vw_int_c5_prodprecoapartir.DTAFIM,
          vw_int_c5_prodprecoapartir.ATIVO,
          vw_int_c5_prodprecoapartir.IDREF          
        );

      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco', 'carrega_tb_prodprecoapartir', 'carrega_tb_prodprecoapartir OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_prodprecoapartir',
           'carrega_tb_prodprecoapartir ERRO',
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
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_comboempresa',
           'carrega_tb_comboempresa ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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
  MERGE INTO monitorpdvmiddle.tb_comboitem TB_COMBOITEM
    USING ( SELECT * FROM VW_INT_C5_BRINDE_ITENS) VIEW_BRINDE_ITENS
    --ON (TB_COMBOITEM.SEQCOMBO = VIEW_BRINDE_ITENS.SEQCOMBO and TB_COMBOITEM.IDREF = VIEW_BRINDE_ITENS.IDREF AND VIEW_BRINDE_ITENS.TIPOITEM = TB_COMBOITEM.TIPOITEM)
    ON (TB_COMBOITEM.SEQCOMBO = VIEW_BRINDE_ITENS.SEQCOMBO and TB_COMBOITEM.SEQITEM = VIEW_BRINDE_ITENS.SEQITEM)

  WHEN MATCHED THEN
    UPDATE SET
      TB_COMBOITEM.SEQPRODUTO = VIEW_BRINDE_ITENS.SEQPRODUTO,
      TB_COMBOITEM.ATIVO = VIEW_BRINDE_ITENS.ATIVO,
      TB_COMBOITEM.QTDE = VIEW_BRINDE_ITENS.QTDE,
	    TB_COMBOITEM.QTDEMBALAGEM = VIEW_BRINDE_ITENS.QTDEMBALAGEM,
      TB_COMBOITEM.PRECO = VIEW_BRINDE_ITENS.PRECO,
      TB_COMBOITEM.PERCDESCONTO = VIEW_BRINDE_ITENS.PERCDESCONTO,
      TB_COMBOITEM.SEQFAMILIA = VIEW_BRINDE_ITENS.SEQFAMILIA,
      --TB_COMBOITEM.SEQITEM = VIEW_BRINDE_ITENS.SEQITEM,
      TB_COMBOITEM.IDREF = VIEW_BRINDE_ITENS.IDREF,
      TB_COMBOITEM.TIPOITEM = VIEW_BRINDE_ITENS.TIPOITEM,
      TB_COMBOITEM.SEQGRUPO = VIEW_BRINDE_ITENS.SEQGRUPO
            
  WHEN NOT MATCHED THEN
    INSERT(
      TB_COMBOITEM.SEQCOMBO,
      TB_COMBOITEM.SEQITEM,
      TB_COMBOITEM.SEQPRODUTO,
      TB_COMBOITEM.TIPOITEM,
      TB_COMBOITEM.ATIVO,
      TB_COMBOITEM.QTDE,
	    TB_COMBOITEM.QTDEMBALAGEM,
      TB_COMBOITEM.PRECO,
      TB_COMBOITEM.PERCDESCONTO,
      TB_COMBOITEM.SEQFAMILIA,
      TB_COMBOITEM.IDREF,
      TB_COMBOITEM.SEQGRUPO
    )
    VALUES(
      VIEW_BRINDE_ITENS.SEQCOMBO,
      VIEW_BRINDE_ITENS.SEQITEM,
      VIEW_BRINDE_ITENS.SEQPRODUTO,
      VIEW_BRINDE_ITENS.TIPOITEM,
      VIEW_BRINDE_ITENS.ATIVO,
      VIEW_BRINDE_ITENS.QTDE,
	    VIEW_BRINDE_ITENS.QTDEMBALAGEM,
      VIEW_BRINDE_ITENS.PRECO,
      VIEW_BRINDE_ITENS.PERCDESCONTO,
      VIEW_BRINDE_ITENS.SEQFAMILIA,
      VIEW_BRINDE_ITENS.IDREF,
      VIEW_BRINDE_ITENS.SEQGRUPO
    );



  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_comboitem', 'carrega_tb_comboitem OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_comboitem',
           'carrega_tb_comboitem ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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

PROCEDURE carrega_tb_combogrupo(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN

  UPDATE MONITORPDVMIDDLE.TB_COMBOGRUPO SET ATIVO = 'N' WHERE SEQCOMBO IN (SELECT SEQCOMBO FROM VW_INT_C5_BRINDE_ITENS);

  MERGE INTO MONITORPDVMIDDLE.TB_COMBOGRUPO T
  USING(SELECT * FROM VW_INT_C5_BRINDE_ITEM_GRUPO) V

  ON (T.SEQCOMBO = V.SEQCOMBO AND T.SEQGRUPO = V.SEQGRUPO)
  WHEN MATCHED THEN
  UPDATE SET
    T.QTDE = V.QTDE,
    T.GRUPO = V.GRUPO,
    T.ATIVO = V.ATIVO,
    T.IDREF = V.IDREF

  WHEN NOT MATCHED THEN 
  INSERT (
    T.SEQCOMBO,
    T.SEQGRUPO,
    T.QTDE,
    T.GRUPO,
    T.ATIVO,
    T.IDREF
  )VALUES(
    V.SEQCOMBO,
    V.SEQGRUPO,
    V.QTDE,
    V.GRUPO,
    V.ATIVO,
    V.IDREF
  );

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_combogrupo', 'carrega_tb_combogrupo OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_combogrupo',
           'carrega_tb_combogrupo ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_combogrupo',
           'carrega_tb_combogrupo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_parcelamento(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_parcelamento P SET P.ATIVO = 'N'
  WHERE P.ATIVO = 'S';
  
  MERGE INTO monitorpdvmiddle.tb_parcelamento T
    USING (SELECT DISTINCT SEQPARCELA, DESCRICAO, TIPO, ATIVO FROM VW_INT_C5_PARCELDEPTO) S 
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
  UPDATE monitorpdvmiddle.tb_parcempresa P SET P.ATIVO = 'N'
  WHERE P.ATIVO = 'S';
  
  MERGE INTO monitorpdvmiddle.tb_parcempresa T
    USING (SELECT DISTINCT SEQPARCELA, NROEMPRESA, ATIVO FROM VW_INT_C5_PARCELDEPTO) S 
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
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
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
	  END;
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
  UPDATE monitorpdvmiddle.tb_parcperiodo P SET P.ATIVO = 'N'
  WHERE P.ATIVO = 'S';
  
  MERGE INTO monitorpdvmiddle.tb_parcperiodo T
    USING (SELECT DISTINCT SEQPARCELA, DTAHORINICIAL, DTAHORFINAL, ATIVO FROM VW_INT_C5_PARCELDEPTO) S 
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
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_parcperiodo',
           'carrega_tb_parcperiodo ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
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

PROCEDURE carrega_tb_parcfamformapagto(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_parcfamformapagto P SET P.ATIVO = 'N'
  WHERE P.ATIVO = 'S';
  
  MERGE INTO monitorpdvmiddle.tb_parcfamformapagto T
    USING (SELECT DISTINCT 
               SEQPARCELA,
               SEQFAMILIA,
               NROFORMAPAGTO,
               NROMAXIMOPARCELA,
               ATIVO
           FROM VW_INT_C5_PARCELDEPTO) S 
    ON    (T.SEQPARCELA = S.SEQPARCELA AND
           T.SEQFAMILIA = S.SEQFAMILIA AND
           T.NROFORMAPAGTO = S.NROFORMAPAGTO)
  WHEN MATCHED THEN
       UPDATE SET
          T.NROMAXIMOPARCELA = S.NROMAXIMOPARCELA,
          T.ATIVO            = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQPARCELA,
          T.SEQFAMILIA,
          T.NROFORMAPAGTO,
          T.NROMAXIMOPARCELA,
          T.ATIVO) 
        VALUES(
          S.SEQPARCELA,
          S.SEQFAMILIA,
          S.NROFORMAPAGTO,
          S.NROMAXIMOPARCELA,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_parcfamformapagto', 'carrega_parcfamformapagto OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_parcfamformapagto',
           'carrega_parcfamformapagto ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_parcfamformapagto',
           'carrega_parcfamformapagto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

  PROCEDURE carrega_tb_grupo(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    UPDATE MONITORPDVMIDDLE.TB_GRUPO SET ATIVO = 'N';

    MERGE INTO monitorpdvmiddle.tb_grupo s
        USING (SELECT * FROM VW_INT_C5_USUARIO_GRUPO) b

      ON (s.SEQGRUPO = b.CODGRUPO)
      WHEN MATCHED THEN
      UPDATE SET
               s.NOME           = b.NOMEGRUPO,
               s.PERCDESCMAXIMO = b.PERCDESCMAX,
               s.ATIVO          = b.ATIVO

      WHEN NOT MATCHED THEN
        INSERT (s.SEQGRUPO,
                s.NOME,
                s.PERCDESCMAXIMO,
                s.ATIVO)
                VALUES
                  (b.CODGRUPO,
                   b.NOMEGRUPO,
                   b.PERCDESCMAX,
                   b.ATIVO);

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_grupo',
       'carrega_tb_grupo OK',
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
           'carrega_tb_grupo',
           'carrega_tb_grupo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_grupousuario(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN

    /*ATIVANDO USUARIOS COM GRUPO*/
    UPDATE MONITORPDVMIDDLE.TB_GRUPOUSUARIO SET ATIVO = 'S'
    WHERE ATIVO = 'N'
    AND SEQGRUPO IN (SELECT CODGRUPO FROM VW_INT_C5_USUARIO_GRUPO);

    /*INATIVANDO USUARIOS SEM GRUPO*/
    UPDATE MONITORPDVMIDDLE.TB_GRUPOUSUARIO SET ATIVO = 'N'
    WHERE ATIVO = 'S'
    AND SEQGRUPO NOT IN (SELECT CODGRUPO FROM VW_INT_C5_USUARIO_GRUPO)
    OR SEQUSUARIO IN (SELECT
                        P.MATRICULA
                      FROM
                        PCEMPR P
                        LEFT JOIN MONITORPDVMIDDLE.TB_GRUPOUSUARIO GU
                        ON (GU.SEQGRUPO = P.CODSETOR)
                        INNER JOIN MONITORPDVMIDDLE.TB_USUARIO U
                        ON(U.SEQUSUARIO = P.MATRICULA)
                      WHERE
                        GU.SEQUSUARIO IS NULL);

    /* MERGE GRUPO USUARIO E USUARIO*/
    MERGE INTO monitorpdvmiddle.tb_grupousuario s
      USING (SELECT * FROM VW_INT_C5_USUARIO) b
    ON (s.SEQGRUPO = b.CODGRUPO and s.SEQUSUARIO = b.SEQUSUARIO)
    WHEN MATCHED THEN
    UPDATE SET
      s.ATIVO = b.ATIVO
    WHEN NOT MATCHED THEN
      INSERT (
        s.SEQGRUPO,
        s.SEQUSUARIO,
        s.ATIVO
      )
      VALUES
      (
        b.CODGRUPO,
        b.SEQUSUARIO,
        b.ATIVO
      );

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_grupousuario',
       'carrega_tb_grupousuario OK',
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
           'carrega_tb_grupousuario',
           'carrega_tb_grupousuario ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
  END;

  PROCEDURE carrega_tb_promsurpresa(p_id IN pccontroleconsinco.id%TYPE) AS
  BEGIN
    UPDATE MONITORPDVMIDDLE.tb_promsurpresa SET ATIVO = 'N' WHERE ATIVO = 'S';
    
    MERGE INTO monitorpdvmiddle.tb_promsurpresa TB_PROMSURPRESA
      USING (SELECT * FROM VW_INT_C5_BRINDE_CABECALHO_AUT) VW_INT_C5_BRINDE_CABECALHO_AUT
      ON  (TB_PROMSURPRESA.SEQPROMSURPRESA = VW_INT_C5_BRINDE_CABECALHO_AUT.SEQPROMSURPRESA)

    WHEN MATCHED THEN
      UPDATE SET
        TB_PROMSURPRESA.DESCRICAO     = VW_INT_C5_BRINDE_CABECALHO_AUT.DESCRICAO,
        TB_PROMSURPRESA.TIPOSURPRESA  = VW_INT_C5_BRINDE_CABECALHO_AUT.TIPOSURPRESA,
        TB_PROMSURPRESA.ATIVO         = VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO,
		TB_PROMSURPRESA.CUMULATIVO    = VW_INT_C5_BRINDE_CABECALHO_AUT.CUMULATIVO
      
    WHEN NOT MATCHED THEN
      INSERT(
        TB_PROMSURPRESA.SEQPROMSURPRESA,
        TB_PROMSURPRESA.DESCRICAO,
        TB_PROMSURPRESA.TIPOSURPRESA,
        TB_PROMSURPRESA.ATIVO,
		TB_PROMSURPRESA.CUMULATIVO
        --TB_PROMSURPRESA.IDREF
      )
      VALUES(
        VW_INT_C5_BRINDE_CABECALHO_AUT.SEQPROMSURPRESA,
        VW_INT_C5_BRINDE_CABECALHO_AUT.DESCRICAO,
        VW_INT_C5_BRINDE_CABECALHO_AUT.TIPOSURPRESA,
        VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO,
		VW_INT_C5_BRINDE_CABECALHO_AUT.CUMULATIVO
       -- VW_INT_C5_BRINDE_CABECALHO_AUT.IDREF
      );

    INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_promsurpresa', 'carrega_tb_promsurpresa OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_promsurpresa',
           'carrega_tb_promsurpresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
    END;      
  END;

  PROCEDURE carrega_tb_promsurpresaempresa(p_id IN pccontroleconsinco.id%TYPE)AS
  BEGIN
    UPDATE MONITORPDVMIDDLE.tb_promsurpresaempresa SET ATIVO = 'N' WHERE ATIVO = 'S';
    
    MERGE INTO monitorpdvmiddle.tb_promsurpresaempresa TB_PROMSURPRESAEMPRESA
      USING (SELECT * FROM VW_INT_C5_BRINDE_CABECALHO_AUT) VW_INT_C5_BRINDE_CABECALHO_AUT
      ON  (TB_PROMSURPRESAEMPRESA.SEQPROMSURPRESA = VW_INT_C5_BRINDE_CABECALHO_AUT.SEQPROMSURPRESA
           AND TB_PROMSURPRESAEMPRESA.NROEMPRESA = VW_INT_C5_BRINDE_CABECALHO_AUT.NROEMPRESA)

    WHEN MATCHED THEN
      UPDATE SET
        TB_PROMSURPRESAEMPRESA.ATIVO = VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO  
      
    WHEN NOT MATCHED THEN
      INSERT(
        TB_PROMSURPRESAEMPRESA.SEQPROMSURPRESA,
        TB_PROMSURPRESAEMPRESA.NROEMPRESA,
        TB_PROMSURPRESAEMPRESA.ATIVO
      )
      VALUES(
        VW_INT_C5_BRINDE_CABECALHO_AUT.SEQPROMSURPRESA,
        VW_INT_C5_BRINDE_CABECALHO_AUT.NROEMPRESA,
        VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO
      );

    INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_promsurpresaempresa', 'carrega_tb_promsurpresaempresa OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
  
    EXCEPTION
	WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_promsurpresaempresa',
           'carrega_tb_promsurpresaempresa ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_promsurpresaempresa',
           'carrega_tb_promsurpresaempresa ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
    END;    
  END;

  PROCEDURE carrega_tb_promsurpresaperiodo(p_id IN pccontroleconsinco.id%TYPE)AS
  BEGIN
    UPDATE MONITORPDVMIDDLE.tb_promsurpresaperiodo SET ATIVO = 'N' WHERE ATIVO = 'S';
    
    MERGE INTO monitorpdvmiddle.tb_promsurpresaperiodo TB_PROMSURPRESAEMPRESAPERIODO
      USING (SELECT * FROM VW_INT_C5_BRINDE_CABECALHO_AUT) VW_INT_C5_BRINDE_CABECALHO_AUT
      ON  (TB_PROMSURPRESAEMPRESAPERIODO.SEQPROMSURPRESA = VW_INT_C5_BRINDE_CABECALHO_AUT.SEQPROMSURPRESA
        AND TB_PROMSURPRESAEMPRESAPERIODO.DTAHORINICIO = VW_INT_C5_BRINDE_CABECALHO_AUT.DTAHORINICIO 
        AND TB_PROMSURPRESAEMPRESAPERIODO.DTAHORFIM = VW_INT_C5_BRINDE_CABECALHO_AUT.DTAHORFIM)

    WHEN MATCHED THEN
      UPDATE SET
        TB_PROMSURPRESAEMPRESAPERIODO.ATIVO        = VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO  
      
    WHEN NOT MATCHED THEN
      INSERT(
        TB_PROMSURPRESAEMPRESAPERIODO.SEQPROMSURPRESA,
        TB_PROMSURPRESAEMPRESAPERIODO.DTAHORINICIO,
        TB_PROMSURPRESAEMPRESAPERIODO.DTAHORFIM,
        TB_PROMSURPRESAEMPRESAPERIODO.ATIVO
      )
      VALUES(
        VW_INT_C5_BRINDE_CABECALHO_AUT.SEQPROMSURPRESA,
        VW_INT_C5_BRINDE_CABECALHO_AUT.DTAHORINICIO,
        VW_INT_C5_BRINDE_CABECALHO_AUT.DTAHORFIM,
        VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO
      );

    INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_promsurpresaperiodo', 'carrega_tb_promsurpresaperiodo OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
  
    EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_promsurpresaperiodo',
           'carrega_tb_promsurpresaperiodo ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_promsurpresaperiodo',
           'carrega_tb_promsurpresaperiodo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
    END;   
  END;

  PROCEDURE carrega_tb_promsurpresaitem(p_id IN pccontroleconsinco.id%TYPE)AS
  BEGIN
    UPDATE MONITORPDVMIDDLE.TB_PROMSURPRESAITEM SET ATIVO = 'N' WHERE ATIVO = 'S';
    
    /*UPDATE MONITORPDVMIDDLE.TB_PROMSURPRESAITEM SET ATIVO = 'N'
    WHERE ROWID IN (
      SELECT 
        T.rowid
      FROM 
        monitorpdvmiddle.tb_promsurpresaitem T,
        VW_INT_C5_BRINDE_ITENS_AUT V           
      WHERE
        T.SEQPROMSURPRESA = V.SEQPROMSURPRESA(+) 
        AND T.SEQITEM = V.SEQITEM(+)
        AND V.IDREF IS NULL 
        AND T.SEQPROMSURPRESA IN (SELECT SEQPROMSURPRESA FROM VW_INT_C5_BRINDE_ITENS_AUT)
        AND T.ATIVO = 'S'
    );*/

    MERGE INTO monitorpdvmiddle.tb_promsurpresaitem TB_PROMSURPRESAITEM
      USING (SELECT * FROM VW_INT_C5_BRINDE_ITENS_AUT) VW_INT_C5_BRINDE_ITENS_AUT
      ON (TB_PROMSURPRESAITEM.SEQPROMSURPRESA = VW_INT_C5_BRINDE_ITENS_AUT.SEQPROMSURPRESA
          AND TB_PROMSURPRESAITEM.SEQITEM = VW_INT_C5_BRINDE_ITENS_AUT.SEQITEM)

    WHEN MATCHED THEN
      UPDATE SET
        TB_PROMSURPRESAITEM.SEQGRUPO     = VW_INT_C5_BRINDE_ITENS_AUT.SEQGRUPO,
        TB_PROMSURPRESAITEM.QTDE         = VW_INT_C5_BRINDE_ITENS_AUT.QTDE,
        TB_PROMSURPRESAITEM.SEQPRODUTO   = VW_INT_C5_BRINDE_ITENS_AUT.SEQPRODUTO,
        TB_PROMSURPRESAITEM.TIPOITEM     = VW_INT_C5_BRINDE_ITENS_AUT.TIPOITEM,
        TB_PROMSURPRESAITEM.QTDEMBALAGEM = VW_INT_C5_BRINDE_ITENS_AUT.QTDEMBALAGEM,
        TB_PROMSURPRESAITEM.ATIVO        = VW_INT_C5_BRINDE_ITENS_AUT.ATIVO,
        TB_PROMSURPRESAITEM.SEQFAMILIA   = VW_INT_C5_BRINDE_ITENS_AUT.SEQFAMILIA,
        TB_PROMSURPRESAITEM.IDREF        = VW_INT_C5_BRINDE_ITENS_AUT.IDREF
      
    WHEN NOT MATCHED THEN
      INSERT(
        TB_PROMSURPRESAITEM.SEQPROMSURPRESA,
        TB_PROMSURPRESAITEM.SEQITEM,
        TB_PROMSURPRESAITEM.SEQGRUPO,
        TB_PROMSURPRESAITEM.QTDE,
        TB_PROMSURPRESAITEM.SEQPRODUTO,
        TB_PROMSURPRESAITEM.TIPOITEM,
        TB_PROMSURPRESAITEM.QTDEMBALAGEM,
        TB_PROMSURPRESAITEM.ATIVO,
        TB_PROMSURPRESAITEM.SEQFAMILIA,
        TB_PROMSURPRESAITEM.IDREF
      )
      VALUES(
        VW_INT_C5_BRINDE_ITENS_AUT.SEQPROMSURPRESA,
        VW_INT_C5_BRINDE_ITENS_AUT.SEQITEM,
        VW_INT_C5_BRINDE_ITENS_AUT.SEQGRUPO,
        VW_INT_C5_BRINDE_ITENS_AUT.QTDE,
        VW_INT_C5_BRINDE_ITENS_AUT.SEQPRODUTO,
        VW_INT_C5_BRINDE_ITENS_AUT.TIPOITEM,
        VW_INT_C5_BRINDE_ITENS_AUT.QTDEMBALAGEM,
        VW_INT_C5_BRINDE_ITENS_AUT.ATIVO,
        VW_INT_C5_BRINDE_ITENS_AUT.SEQFAMILIA,
        VW_INT_C5_BRINDE_ITENS_AUT.IDREF
      );

    INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_promsurpresaitem', 'carrega_tb_promsurpresaitem OK', SYSDATE, CURRENT_TIMESTAMP);

    COMMIT;
  
    EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco',
          'carrega_tb_promsurpresaitem',
          'carrega_tb_promsurpresaitem ALERTA',
          SYSDATE,
          CURRENT_TIMESTAMP);
      COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
      prc_record_error(p_id);
      ROLLBACK;
      INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
      VALUES
        ('pkg_sinc_PDV_Consinco',
          'carrega_tb_promsurpresaitem',
          'carrega_tb_promsurpresaitem ERRO',
          SYSDATE,
          CURRENT_TIMESTAMP);
      COMMIT;
      RAISE;
    END;   
  END;

PROCEDURE carrega_tb_promsurpresagrupo(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN

  --UPDATE MONITORPDVMIDDLE.tb_promsurpresagrupo SET ATIVO = 'N' WHERE SEQPROMSURPRESA IN (SELECT SEQPROMSURPRESA FROM VW_INT_C5_BRINDE_ITENS_AUT);
  UPDATE MONITORPDVMIDDLE.tb_promsurpresagrupo SET ATIVO = 'N' WHERE ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.tb_promsurpresagrupo T
  USING(SELECT * FROM VW_INT_C5_BRINDE_GRUPO_AUT) V

  ON (T.SEQPROMSURPRESA = V.SEQPROMSURPRESA AND T.SEQGRUPO = V.SEQGRUPO)
  WHEN MATCHED THEN
  UPDATE SET
    T.QTDE = V.QTDE,
    T.GRUPO = V.GRUPO,
    T.ATIVO = V.ATIVO,
    T.IDREF = V.IDREF

  WHEN NOT MATCHED THEN 
  INSERT (
    T.SEQPROMSURPRESA,
    T.SEQGRUPO,
    T.QTDE,
    T.GRUPO,
    T.ATIVO,
    T.IDREF
  )VALUES(
    V.SEQPROMSURPRESA,
    V.SEQGRUPO,
    V.QTDE,
    V.GRUPO,
    V.ATIVO,
    V.IDREF
  );

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_promsurpresagrupo', 'carrega_tb_promsurpresagrupo OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_promsurpresagrupo',
           'carrega_tb_promsurpresagrupo ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_promsurpresagrupo',
           'carrega_tb_promsurpresagrupo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;

        RAISE;
  END;
END;

PROCEDURE carrega_tb_cadobs(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_cadobs S SET S.ATIVO = 'N'
  WHERE S.ATIVO = 'S'
  AND EXISTS (SELECT C.CODOBSERVACAO 
              FROM VW_INT_C5_CADOBS C
              WHERE C.CODOBSERVACAO = S.CODOBSERVACAO);
  
  MERGE INTO monitorpdvmiddle.tb_cadobs T
    USING (SELECT * FROM VW_INT_C5_CADOBS) S 
    ON    (T.CODOBSERVACAO = S.CODOBSERVACAO)
  WHEN MATCHED THEN
       UPDATE SET
          T.INFORMADOTRIBUF   = S.INFORMADOTRIBUF,
          T.GERACBENEFFAMTRIB = S.GERACBENEFFAMTRIB,
          T.ATIVO             = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.CODOBSERVACAO,
          T.INFORMADOTRIBUF,
          T.GERACBENEFFAMTRIB,
          T.ATIVO) 
        VALUES(
          S.CODOBSERVACAO,
          S.INFORMADOTRIBUF,
          S.GERACBENEFFAMTRIB,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cadobs', 'carrega_tb_cadobs OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cadobs',
           'carrega_tb_cadobs ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cadobssped(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_cadobssped S SET S.ATIVO = 'N'
  WHERE S.ATIVO = 'S'
  AND EXISTS (SELECT C.SEQOBSSPED 
              FROM VW_INT_C5_CADOBSSPED C
              WHERE C.SEQOBSSPED = S.SEQOBSSPED);
  
  MERGE INTO monitorpdvmiddle.tb_cadobssped T
    USING (SELECT * FROM VW_INT_C5_CADOBSSPED) S 
    ON    (T.SEQOBSSPED = S.SEQOBSSPED)
  WHEN MATCHED THEN
       UPDATE SET
          T.CODOBSERVACAO    = S.CODOBSERVACAO,
          T.CODAJUSTEEFD     = S.CODAJUSTEEFD,
          T.USACODAJUSTENFE  = S.USACODAJUSTENFE,
          T.REGISTRO         = S.REGISTRO,
          T.ATIVO            = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQOBSSPED,
          T.CODOBSERVACAO,
          T.CODAJUSTEEFD,
          T.USACODAJUSTENFE,
          T.REGISTRO,
          T.ATIVO) 
        VALUES(
          S.SEQOBSSPED,
          S.CODOBSERVACAO,
          S.CODAJUSTEEFD,
          S.USACODAJUSTENFE,
          S.REGISTRO,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cadobssped', 'carrega_tb_cadobssped OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_cadobssped',
           'carrega_tb_cadobssped ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_cadobssped',
           'carrega_tb_cadobssped ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cadobsspedfamilia(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_cadobsspedfamilia S SET S.ATIVO = 'N'
  WHERE S.ATIVO = 'S';

  /*UPDATE monitorpdvmiddle.tb_cadobsspedfamilia S SET S.ATIVO = 'N'
  WHERE S.ATIVO = 'S'
  AND EXISTS (SELECT C.SEQOBSSPED 
              FROM VW_INT_C5_CADOBSSPEDFAMILIA C
              WHERE C.SEQFAMILIA = S.SEQFAMILIA
              AND   C.SEQOBSSPED = S.SEQOBSSPED
              AND   C.UF         = S.UF);*/
  
  MERGE INTO monitorpdvmiddle.tb_cadobsspedfamilia T
    USING (SELECT * FROM VW_INT_C5_CADOBSSPEDFAMILIA) S 
    ON    (T.SEQFAMILIA = S.SEQFAMILIA AND
           T.SEQOBSSPED = S.SEQOBSSPED AND
           T.UF         = S.UF)
  WHEN MATCHED THEN
       UPDATE SET
          T.CODAJUSTEEFD    = S.CODAJUSTEEFD,
          T.ATIVO           = S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQFAMILIA,
          T.SEQOBSSPED,
          T.UF,
          T.CODAJUSTEEFD,
          T.ATIVO) 
        VALUES(
          S.SEQFAMILIA,
          S.SEQOBSSPED,
          S.UF,
          S.CODAJUSTEEFD,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cadobsspedfamilia', 'carrega_tb_cadobsspedfamilia OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_cadobsspedfamilia',
           'carrega_tb_cadobsspedfamilia ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_tb_cadobsspedfamilia',
           'carrega_tb_cadobsspedfamilia ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE CARREGA_TB_ESPECIEFINANCEIRA(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  MERGE INTO MONITORPDVMIDDLE.TB_ESPECIEFINANCEIRA TB_ESPECIEFINANCEIRA
    USING (SELECT 'CRED' CODESPECIE, 'CRÉDITO DE CLIENTE' DESCRICAO, 'S' ATIVO, CODFILIAL NROEMPRESA FROM VW_INT_C5_OBTER_FILIAIS_C5) T
    ON (TB_ESPECIEFINANCEIRA.NROEMPRESAMAE = T.NROEMPRESA)
  WHEN NOT MATCHED THEN
    INSERT(
     TB_ESPECIEFINANCEIRA.CODESPECIE,
     TB_ESPECIEFINANCEIRA.DESCRICAO,
     TB_ESPECIEFINANCEIRA.ATIVO,
     TB_ESPECIEFINANCEIRA.NROEMPRESAMAE
    )
    VALUES(
      T.CODESPECIE,
      T.DESCRICAO,
      T.ATIVO,
      T.NROEMPRESA
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_ESPECIEFINANCEIRA', 'TB_ESPECIEFINANCEIRA OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_TB_ESPECIEFINANCEIRA',
           'carrega_TB_ESPECIEFINANCEIRA ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_TB_ESPECIEFINANCEIRA',
           'carrega_TB_ESPECIEFINANCEIRA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE CARREGA_TB_PRECOAPARTIR(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIR TB_PRECOAPARTIR
    USING (SELECT SEQPRECOAPARTIR, DESCRICAO, ATIVO FROM VW_INT_C5_PRECOAPARTIR) T
    ON (TB_PRECOAPARTIR.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIR.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR,
      TB_PRECOAPARTIR.DESCRICAO = T.DESCRICAO,
      TB_PRECOAPARTIR.ATIVO = T.ATIVO

  WHEN NOT MATCHED THEN
    INSERT(
      TB_PRECOAPARTIR.SEQPRECOAPARTIR,
      TB_PRECOAPARTIR.DESCRICAO,
      TB_PRECOAPARTIR.ATIVO
    )
    VALUES(
      T.SEQPRECOAPARTIR,
      T.DESCRICAO,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_PRECOAPARTIR', 'TB_PRECOAPARTIR OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;
  
  EXCEPTION
    WHEN E_FK_VIOLATION THEN
	  BEGIN
	    PRC_RECORD_ALERTA(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_TB_PRECOAPARTIR',
           'carrega_TB_PRECOAPARTIR ALERTA',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
	  END;
    WHEN OTHERS THEN
    BEGIN
        prc_record_error(p_id);
        ROLLBACK;
        INSERT INTO PCDEVLOGCONSINCO
          (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
        VALUES
          ('pkg_sinc_PDV_Consinco',
           'carrega_TB_PRECOAPARTIR',
           'carrega_TB_PRECOAPARTIR ERRO',
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
	
  FUNCTION EXISTE_ALERTA(p_id IN pccontroleconsinco.id%TYPE) RETURN BOOLEAN IS
	vCONT NUMBER;
  BEGIN
    SELECT COUNT(1)
	INTO vCONT
	FROM PCERRORLOGCONSINCO
	WHERE id_processo = p_id
	AND tipo_erro = 'A';
	
	RETURN (vCONT > 0); 
  END;
  
  
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
		 
		 
      IF NOT EXISTE_ALERTA(r_processo.id) THEN
	       pkg_sinc_PDV_Consinco.atualiza_sinc_processo(r_processo.id);
	    END IF;
      

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

END PKG_SINC_PDV_CONSINCO;   
