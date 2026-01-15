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

  FUNCTION obter_seqloteestoque RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_DEPARAPRODLOTE.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
  END;

  FUNCTION obter_seqcenariocondicao RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_CCTCENCOND.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
  END;

  FUNCTION obter_seqcenariocondicaoitem RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_CCTCENCONDITEM.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
  END;

  FUNCTION obter_seqcodigotributacao RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_CCTCODTRIBUTARIO.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
  END;  

  FUNCTION obter_seqcenarioimposto RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_CCTCENARIOIMPOSTO.NEXTVAL FROM DUAL';
    
    EXECUTE IMMEDIATE VSQL INTO vSeq;
    RETURN vSeq;
  END;  

  FUNCTION obter_seqaliquota RETURN NUMBER IS
   vSeq NUMBER := 0;
   VSQL VARCHAR2(2000);
  BEGIN
    VSQL := 'SELECT DFSEQ_INT_C5_CCTALIQUOTA.NEXTVAL FROM DUAL';
    
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
      WHERE NVL(s.NOME,'-') <> NVL(b.NOME,'-')
	       OR NVL(s.APELIDO,'-') <> NVL(b.APELIDO,'-')
         OR NVL(s.SENHA, 0) <> NVL(b.SENHA, 0)
		     OR NVL(s.SEQPESSOA,0) <> NVL(b.SEQPESSOA,0)
		     OR NVL(s.NIVEL,0) <> NVL(b.NIVEL,0)
         OR NVL(s.DTAEXPIRAR,TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(b.DTAEXPIRAR,TO_DATE('01-01-1994','DD-MM-YYYY'))
         OR NVL(s.PERCDESCMAXIMO,0) <> NVL(b.PERCDESCMAXIMO,0)
         OR NVL(s.ATIVO,'-') <> NVL(b.ATIVO,'-')

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
       WHERE NVL(s.nomerazao,'-') <> NVL(b.nomerazao,'-')
          OR NVL(s.nomefantasia,'-') <> NVL(b.nomefantasia,'-')
          OR NVL(s.fisicajuridica,'-') <> NVL(b.fisicajuridica,'-')
          OR NVL(s.cnpjcpf,'-') <> NVL(b.cnpjcpf,'-')
          OR NVL(s.inscrestadualrg,'-') <> NVL(b.inscrestadualrg,'-')
          OR NVL(s.dtanascimento, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(b.dtanascimento, TO_DATE('01-01-1994','DD-MM-YYYY'))
          OR NVL(s.contribuinteicms,'-') <> NVL(b.contribuinteicms,'-')
          OR NVL(s.orgexp,'-') <> NVL(b.orgexp,'-')
          OR NVL(s.sexo,'-') <> NVL(b.sexo,'-')
          OR NVL(s.email,'-') <> NVL(b.email,'-')
          OR NVL(s.ativo,'-') <> NVL(b.ativo,'-')
		  
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
	  WHERE NVL(s.ativo,'-') <> NVL(b.ATIVO,'-')
         OR NVL(s.segmento,'-') <> NVL(b.SEGMENTO,'-')

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
	  WHERE NVL(t.seqpessoa,0) <> NVL(s.seqpessoa,0)
         OR NVL(t.nrodivisao,0) <> NVL(s.nrodivisao,0)
         OR NVL(t.nomereduzido,'-') <> NVL(s.nomereduzido,'-')
         OR NVL(t.nroempresamatriz,0) <> NVL(s.nroempresamatriz,0)
         OR NVL(t.nroempresaseguranca,0) <> NVL(s.nroempresaseguranca,0)
         OR NVL(t.ativo,0) <> NVL(s.ativo,0)
		 
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

    
    UPDATE monitorpdvmiddle.tb_empresa t
	   SET t.ATIVO = CASE WHEN t.NROEMPRESA in (SELECT C5.CODFILIALINTEGRACAO FROM VW_INT_C5_OBTER_FILIAIS_C5 C5) THEN 'S' ELSE 'N' END;

	
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
      WHERE NVL(s.vlrlimiteglobal,0) <> NVL(b.vlrlimiteglobal,0)
         OR NVL(s.prazomaximo,0) <> NVL(b.prazomaximo,0)
         OR NVL(s.dtahorultrestricao, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(b.dtahorultrestricao, TO_DATE('01-01-1994','DD-MM-YYYY'))
         OR NVL(s.observacao,'-') <> NVL(b.observacao,'-')
         OR NVL(s.situacaocredito,'-') <> NVL(b.situacaocredito,'-')
         OR NVL(s.situacaocomercial, '-') <> NVL(b.situacaocomercial,'-')
         OR NVL(s.ativo, '-') <> NVL(b.ativo,'-')
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
      UPDATE SET
             s.ativo    = b.ativo,
             s.nrocarga = b.nrocarga
	   WHERE NVL(s.ativo,'-') <> NVL(b.ativo,'-')
          OR NVL(s.nrocarga,0) <> NVL(b.nrocarga,0)
		  
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

    UPDATE monitorpdvmiddle.tb_empresasegmento t
	   SET t.ATIVO = CASE WHEN t.NROEMPRESA in (SELECT C5.CODFILIALINTEGRACAO FROM VW_INT_C5_OBTER_FILIAIS_C5 C5) THEN 'S' ELSE 'N' END;
	 
	 
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
                      P.percglp,
                      p.percgnn,
                      p.percgni,                     
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
                 s.codanp          = b.codanp,
                 s.descanp         = b.descanp_prod,
                 s.percglp         = b.percglp,
                 s.percgnn         = b.percgnn,
                 s.percgni         = b.percgni,
                 s.codproduto      = b.codproduto
                -- s.idref           = b.idref
     WHERE NVL(s.descreduzida, '-') <> NVL(b.DESCREDUZIDA, '-')
          OR NVL(s.desccompleta, '-') <> NVL(b.DESCCOMPLETA, '-')
          OR NVL(s.ativo, '-') <> NVL(b.ATIVO, '-')
          OR NVL(s.produtocomposto, '-') <> NVL(b.PRODUTOCOMPOSTO, '-')
          OR NVL(s.seqfamilia, 0) <> NVL(b.SEQFAMILIA, 0)          
          OR NVL(s.codanp, 0) <> NVL(b.codanp,0)
          OR NVL(s.descanp, 0) <> NVL(b.descanp_prod,0)
          OR NVL(s.percglp, 0) <> NVL(b.percglp, 0)
          OR NVL(s.percgnn, 0) <> NVL(b.percgnn, 0)
          OR NVL(s.percgni, 0) <> NVL(b.percgni, 0)
          OR NVL(s.codproduto, 0) <> NVL(b.codproduto, 0)   
      WHEN NOT MATCHED THEN
        INSERT
            (s.SEQPRODUTO,
             s.DESCREDUZIDA,
             s.DESCCOMPLETA,
             s.ATIVO,
             s.PRODUTOCOMPOSTO,
             s.SEQFAMILIA,
             s.codanp,
             s.descanp,
             s.percglp,
             s.percgnn,
             s.percgni,             
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
             b.codanp,
             b.descanp_prod,
             b.percglp,
             b.percgnn,  
             b.percgni,                  
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
    UPDATE MONITORPDVMIDDLE.TB_PRODCOMPOSTO SET ATIVO = 'N';
       
    MERGE INTO monitorpdvmiddle.tb_prodcomposto s
        USING (
               SELECT P.SEQPRODCOMPOSTO,
                      P.SEQPRODUTO,
                      P.QTDEMBALAGEM,
                      P.QUANTIDADE,
                      MIN(P.PRECO) PRECO,
                      P.ATIVO
                      
        FROM VW_INT_C5_PRODCOMPOSTO P
        GROUP BY P.SEQPRODCOMPOSTO, P.SEQPRODUTO, P.QTDEMBALAGEM, P.QUANTIDADE, P.ATIVO
       ) b

      ON (s.seqproduto = b.SEQPRODUTO and s.qtdembalagem = b.qtdembalagem and s.SEQPRODCOMPOSTO = b.SEQPRODCOMPOSTO)
      WHEN MATCHED THEN
      UPDATE
             SET s.QUANTIDADE  = b.QUANTIDADE,
                 s.PRECO       = b.PRECO,
                 s.ATIVO       = b.ATIVO
	   WHERE NVL(s.QUANTIDADE, 0) <> NVL(b.QUANTIDADE, 0)
          OR NVL(s.PRECO, 0) <> NVL(b.PRECO, 0)
          OR NVL(s.ATIVO, '-') <> NVL(b.ATIVO, '-')
		  
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

    /*DESATIVA CESTAS QUE FORAM EXCLUIDAS DA PCFORMPROD OU QUE TIVERAM ALTERAÇÃO DO TIPOMERC NAO SENDO MAIS "CB" OU ""KT*/
    UPDATE MONITORPDVMIDDLE.TB_PRODCOMPOSTO P SET P.ATIVO = 'N'
    WHERE ATIVO = 'S'
    AND NOT EXISTS(SELECT 1
                   FROM PCFORMPROD F, PCDEPARAPRODC5 C, PCPRODUT PROD
                   WHERE C.CODPROD = F.CODPRODACAB
                   AND   C.SEQPRODUTO = P.SEQPRODCOMPOSTO
                   AND   PROD.CODPROD = F.CODPRODACAB
                   AND   PROD.CODPROD = C.CODPROD
                   AND   C.ATIVO = 'S'
                   AND   PROD.TIPOMERC IN ('CB', 'KT')
                  );
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
      UPDATE SET s.grupofamilia = b.grupofamilia,
                 s.ativo        = b.ativo,
                 s.nrocarga     = b.nrocarga
	   WHERE NVL(s.grupofamilia, '-') <> NVL(b.grupofamilia, '-')
          OR NVL(s.ativo, '-') <> NVL(b.ativo, '-')
          OR NVL(s.nrocarga, 0) <> NVL(b.nrocarga, 0)
		  
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
	   WHERE NVL(s.marca, '-') <> NVL(b.marca, '-')
          OR NVL(s.ativo, '-') <> NVL(b.ativo, '-')
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
                    NVL(
						CASE
							WHEN (SELECT VALOR FROM PCPARAMETROS2651 WHERE NOME = 'UTILIZAR_FNC_REMOVE_CHAR_ESP_V2') = 'S' THEN
								fnc_remove_char_esp_v2(v.familia)
							ELSE
								fnc_remove_char_esp(v.familia)
						END,
						'-'
					) AS familia,
                    v.permitedecimal,
                    v.codncmsh,
                    --v.codcest,
                    /*(SELECT nvl(CODCEST, 0) codcest
                     FROM PCCEST INNER JOIN PCCESTPRODUTO ON PCCEST.CODIGO = PCCESTPRODUTO.CODSEQCEST
                     WHERE PCCESTPRODUTO.CODPROD = v.codprod
                     AND ROWNUM = 1
                    )*/ v.codcest,
                      CASE
                        WHEN (SELECT Count(DISTINCT tipoembalagem)
                              FROM   pcembalagem e1
                              WHERE  e1.codprod = v.codprod
                                    AND E1.codauxiliar = CASE WHEN v.origem = 'D' THEN v.codauxiliar ELSE e1.codauxiliar END
                                    AND tipoembalagem IN ( 'P' )) = 1 
                          THEN 
                            'S'
                        WHEN (SELECT Count(DISTINCT tipoembalagem)
                              FROM   pcembalagem e1
                              WHERE  e1.codprod = v.codprod
                                    AND e1.codauxiliar = CASE WHEN v.origem = 'D' THEN v.codauxiliar ELSE e1.codauxiliar END
                                    AND tipoembalagem IN ( 'U', 'P' )) > 1 
                          THEN
                            'N'
                          ELSE 
                            'N'
                      END PESAVEL,
          CASE 
            WHEN (SELECT COUNT(DISTINCT TIPOEMBALAGEM)
                    FROM PCEMBALAGEM e1
                   WHERE e1.codprod = v.codprod
                    AND e1.CODAUXILIAR = CASE WHEN v.ORIGEM = 'D' THEN v.CODAUXILIAR ELSE e1.CODAUXILIAR END
                    AND tipoembalagem IN ('U', 'P')) > 1 THEN
            'S'
            ELSE
            'N'
          END PERMITEMULTIPLICACAO, 
                    v.ativo,
                    v.seqmarca,
                    v.seqfamgrupo,
                    v.indescala,
                    v.cnpjfabricante,
                    v.eantrib,
                    v.codprod idref,
                    v.estoqueporlote,
					v.checapesoetiqueta,
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
                    END)  PERCBASECOFINS,
          (CASE
            WHEN V.PESAVEL = 'S' THEN
              'S'
            ELSE 
              'N'
            END) VENDAFRACAO

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
                        VW_INT_C5_EMBPROD_MAT E
                                                
                        /*(SELECT S.ULTIMAEXECUCAO
                         FROM PCCONTROLECONSINCO S
                         WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA'
                        ) DATAPADRAO */
                   WHERE R.CODTRIBPISCOFINS = T.CODTRIBPISCOFINS 
                   AND   E.CODPROD = R.CODPROD
                   AND   R.CODTRIBPISCOFINS IS NOT NULL
                   AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') <> 'S'
                   AND   R.NUMREGIAO = ( SELECT VALOR
                                         FROM PCPARAMFILIAL
                                         WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                                         AND VALOR <> '99'
                                         AND VALOR IS NOT NULL
                                         AND ROWNUM = 1)-- somente os dados de 1 região
                   /*AND  (NVL(T.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao OR
                         NVL(R.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao)*/

                   UNION ALL

                   SELECT R.CODPROD, 
                          T.SITTRIBUT, 
                          T.PERCPIS, 
                          T.PERCCOFINS, 
                          T.EXCLUIRICMSBASEPISCOFINS
                   FROM PCTABTRIB R, 
                        PCTRIBPISCOFINS T,
                        VW_INT_C5_EMBPROD_MAT E,
                        (SELECT * FROM VW_INT_C5_OBTER_FILIAIS_C5 WHERE ROWNUM = 1) C5
                                                
                        /*(SELECT S.ULTIMAEXECUCAO
                         FROM PCCONTROLECONSINCO S
                         WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FAMILIA'
                        ) DATAPADRAO */
                   WHERE R.CODTRIBPISCOFINS = T.CODTRIBPISCOFINS 
                   AND   R.CODFILIALNF = C5.CODFILIAL
				   AND   R.CODFILIALNF = E.CODFILIAL
				   AND   R.CODPROD = E.CODPROD
				   AND   E.CODFILIAL = C5.CODFILIAL
                   AND   R.CODTRIBPISCOFINS IS NOT NULL
                   AND   FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF', '99', 'N') = 'S'
                   AND   R.UFDESTINO = (SELECT F.UF
                                        FROM PCFILIAL F
                                        WHERE F.UF IS NOT NULL
                                        AND   ROWNUM = 1)
                   /*AND  (NVL(T.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao OR
                         NVL(R.dtalterc5, DATAPADRAO.ultimaexecucao) >= DATAPADRAO.ultimaexecucao)      */
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
                     S.percbasepis = B.PERCBASEPIS,
                     S.percbasecofins = B.PERCBASECOFINS,
                     S.percpis = B.PERCPIS,
                     S.perccofins = B.PERCCOFINS,
                     S.indescala = B.indescala,
                     S.cnpjfabricante = B.cnpjfabricante,
                     S.eantrib = B.eantrib,
                     --S.seqfamiliaprinc = B.seqfamiliaprinc,
                     S.LOTEESTOQUE = B.estoqueporlote,
                     S.gerareducaobasepiscofins = B.gerareducaobasepiscofins,
                     S.idref = B.idref,
                     S.MEDICAMENTO = B.estoqueporlote,
					 S.VENDAFRACAO = B.VENDAFRACAO,
					 S.CHECAPESOETIQUETA = B.checapesoetiqueta 
		WHERE NVL(S.familia, '-') <> NVL(B.familia, '-')
           OR NVL(S.permitedecimal, '-') <> NVL(B.permitedecimal, '-')
           OR NVL(S.permitemultiplicacao, '-') <> NVL(B.permitemultiplicacao, '-')
           OR NVL(S.codnbmsh, '-') <> NVL(B.codncmsh, '-')
           OR NVL(S.codcest, 0) <> NVL(B.codcest, 0)
           OR NVL(S.ativo, '-') <> NVL(B.ativo, '-')
           OR NVL(S.seqmarca, 0) <> NVL(B.seqmarca, 0)
           OR NVL(S.seqfamgrupo, 0) <> NVL(B.seqfamgrupo, 0)
           OR NVL(S.pesavel, '-') <> NVL(B.pesavel, '-')                      
           OR NVL(S.situacaopis, 0) <> NVL(B.SITUACAOPIS, 0)
           OR NVL(S.situacaocofins, 0) <> NVL(B.SITUACAOCOFINS, 0)
           OR NVL(S.percbasepis, 0) <> NVL(B.PERCBASEPIS, 0)
           OR NVL(S.percbasecofins, 0) <> NVL(B.PERCBASECOFINS, 0)
           OR NVL(S.percpis, 0) <> NVL(B.PERCPIS, 0)
           OR NVL(S.perccofins, 0) <> NVL(B.PERCCOFINS, 0)
           OR NVL(S.indescala, '-') <> NVL(B.indescala, '-')
           OR NVL(S.cnpjfabricante, '-') <> NVL(B.cnpjfabricante, '-')
           OR NVL(S.eantrib, 0) <> NVL(B.eantrib, 0)
           OR NVL(S.gerareducaobasepiscofins, '-') <> NVL(B.gerareducaobasepiscofins, '-')
           OR NVL(S.idref, 0) <> NVL(B.idref, 0)
           OR NVL(S.LOTEESTOQUE, '-') <> NVL(B.estoqueporlote, '-')
           OR NVL(S.MEDICAMENTO, '-') <> NVL(B.estoqueporlote, '-')
		   OR NVL(S.VENDAFRACAO,'-') <> NVL(B.VENDAFRACAO, '-')
		   OR NVL(S.CHECAPESOETIQUETA,'-') <> NVL(B.CHECAPESOETIQUETA, '-')
		   
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
                     S.idref,
                     S.LOTEESTOQUE,
                     S.MEDICAMENTO,
					 S.VENDAFRACAO,
					 S.CHECAPESOETIQUETA)
                     VALUES
                     (B.familia,
                      B.permitedecimal,
                      B.permitemultiplicacao,
                      b.codncmsh,
                      B.codcest,
                      B.ativo,
                      B.seqmarca,
                      B.seqfamgrupo,
                      B.seqfamilia,
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
                      B.idref,
                      B.estoqueporlote,
                      B.estoqueporlote,
					  B.VENDAFRACAO,
					  B.CHECAPESOETIQUETA);

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
		WHERE NVL(s.descricao, '-') <> NVL(b.descricao, '-')
           OR NVL(s.ativo, '-') <> NVL(b.ativo, '-')
           OR NVL(s.nrocarga, 0) <> NVL(b.nrocarga, 0)
		   
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
      UPDATE SET s.ativo = b.ativo
	   WHERE NVL(s.ativo, '-') <> NVL(b.ativo, '-')
	   
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
			   WHEN (f.especie = 'CART') or ((f.especie = 'O') and (f.codcob = 'C')) THEN
                'N'			   
               WHEN (f.especie = 'CNV') or ((f.especie = 'O') and (f.codcob = 'CONV')) THEN
                'V'
               WHEN f.especie = 'CRE' THEN
                'I'
			   WHEN (f.especie = 'GTC') or ((f.especie = 'O') and (f.CODCOB = 'GIFT')) THEN
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
		WHERE NVL(s.especie, '-') <> NVL(b.especie, '-')
           OR NVL(s.formapagto, '-') <> NVL(b.formapagto, '-')
           OR NVL(s.idref, 0) <> NVL(b.codfilial, 0)
           OR NVL(s.ativo, '-') <> NVL(b.ativo, '-')
           OR NVL(s.nrocarga, 0) <> NVL(b.nrocarga, 0)
		   
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
               s.VLRMINIMOPARCELA = b.VLRMINIMOPARCELA,
  			   s.NROMAXIMOPARCELA = b.QTMAXPARCELAS,
               s.CONTROLELIMITE   = b.CONTROLELIMITE
	  WHERE NVL(s.percjuromensal, 0)       <> NVL(b.percjuromensal, 0)
         OR NVL(s.perctaxaadm ,0)        <> NVL(b.perctaxaadm, 0)
         OR NVL(s.nrodiasvencto, 0)      <> NVL(b.nrodiasvencto, 0)
         OR NVL(s.solicitavencto, '-')   <> NVL(b.solicitavencto, '-')
         OR NVL(s.permitetroco, '-')     <> NVL(b.permitetroco, '-')
         OR NVL(s.vlrminimo, 0)          <> NVL(b.vlrminimo, 0)
         OR NVL(s.vlrmaximo, 0)          <> NVL(b.vlrmaximo, 0)
         OR NVL(s.gerasangria, '-')      <> NVL(b.gerasangria, '-')
         OR NVL(s.prazomaximo, 0)        <> NVL(b.prazomaximo, 0)
         OR NVL(s.usatef, '-')           <> NVL(b.usatef, '-')
         OR NVL(s.tipocalculojuros, '-') <> NVL(b.tipocalculojuros, '-')
         OR NVL(s.emitevaletroco, '-')   <> NVL(b.emitevaletroco, '-')
         OR NVL(s.emitecomprovante, '-') <> NVL(b.emitecomprovante, '-')
         OR NVL(s.abregaveta, '-')       <> NVL(b.abregaveta, '-')
         OR NVL(s.alternativa, '-')      <> NVL(b.alternativa, '-')
         OR NVL(s.faturamento, '-')      <> NVL(b.faturamento, '-')
         OR NVL(s.idref, 0)            <> NVL(b.codCob, 0)
         OR NVL(s.ativo, '-')            <> NVL(b.ativo, '-')
         OR NVL(s.nroParcelaJuro, 0)     <> NVL(b.nroParcelaJuro, 0)
         OR NVL(s.VLRMINIMOPARCELA, 0)   <> NVL(b.VLRMINIMOPARCELA, 0)
  		   OR NVL(s.NROMAXIMOPARCELA, 0)   <> NVL(b.QTMAXPARCELAS, 0)
         OR NVL(s.CONTROLELIMITE, '-')   <> NVL(b.CONTROLELIMITE, '-')
		 
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
             s.VLRMINIMOPARCELA,
			       s.NROMAXIMOPARCELA,
             s.CONTROLELIMITE
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
             b.VLRMINIMOPARCELA,
			       b.QTMAXPARCELAS,
             b.CONTROLELIMITE);
    
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
	   WHERE NVL(s.seqcategoriapai, 0)   <> NVL(b.seqcategoriapai, 0)
          OR NVL(s.categoria, '-')     <> NVL(b.categoria, '-')
          OR NVL(s.tipo, '-')          <> NVL(b.tipo, '-')
          OR NVL(s.ativo, '-')         <> NVL(b.ativo, '-')
          OR NVL(s.lerpeso, '-')       <> NVL(b.lerpeso, '-')
          OR NVL(s.NIVELHIERARQUIA, 0) <> NVL(b.nivelhierarquia, 0)
          OR NVL(s.idref, 0)         <> NVL(b.idref, 0)
		  
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
	   WHERE NVL(s.ativo, '-') <> NVL(b.ativo, '-')
          OR NVL(s.idref, 0) <> NVL(b.idref, 0)
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
  
    UPDATE monitorpdvmiddle.tb_famdivisaocategoria f
     set f.idref = f.idref
   where (f.SEQCATEGORIA, f.NRODIVISAO, f.SEQFAMILIA)
      IN (SELECT v.SEQCATEGORIA, v.NRODIVISAO, v.SEQFAMILIA 
            FROM VW_INT_C5_FAMDIVISAOCATEGORIA v);
  
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
        s.estqloja = b.estqloja,
        s.ativo    = b.ativo,
        s.idref    = b.idref
		  WHERE NVL(s.estqloja, 0) <> NVL(b.estqloja, 0)
         OR NVL(s.ativo, '-')  <> NVL(b.ativo, '-')
         OR NVL(s.idref, 0)  <> NVL(b.idref, 0)
		   
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
                    e.pesoliquido,
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
	  WHERE NVL(s.embalagem, '-') <> NVL(b.embalagem, '-')
		 OR NVL(s.pesoaferido, 0)   <> NVL(b.pesoaferido, 0)
		 OR NVL(s.pesobruto, 0)     <> NVL(b.pesobruto, 0)
		 OR NVL(s.pesoliquido, 0)   <> NVL(b.pesoliquido, 0)
		 OR NVL(s.ativo, '-')       <> NVL(b.ativo, '-')
		 OR NVL(s.nrocarga, 0)      <> NVL(b.nrocarga, 0)

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

    COMMIT;              

    /*Carga das embalagens dos produtos filhos para seus reespectivos pais(CODPRODPRINC)*/              

    MERGE INTO monitorpdvmiddle.tb_famembalagem s
      USING (SELECT DISTINCT e.seqfamilia,
                    e.qtdembalagem,
                    e.embalagem,
                    e.pesoaferido,
                    e.ativo,
                    e.pesobruto,
                    e.pesoliquido,
                    0 nrocarga
      FROM VW_INT_C5_EMBFAMILIA e) b

    ON (s.seqfamilia = b.seqfamilia and s.QTDEMBALAGEM = b.QTDEMBALAGEM)
    WHEN MATCHED THEN
    UPDATE SET
      s.embalagem = b.embalagem,
      s.pesoaferido = b.pesoaferido,
      s.pesobruto = b.pesobruto,
      s.pesoliquido = b.pesoliquido,
      s.ativo = b.ativo,
      s.nrocarga = b.nrocarga
	  WHERE NVL(s.embalagem, '-') <> NVL(b.embalagem, '-')
       OR NVL(s.pesoaferido, 0) <> NVL(b.pesoaferido, 0)
       OR NVL(s.pesobruto, 0)   <> NVL(b.pesobruto, 0)
       OR NVL(s.pesoliquido, 0) <> NVL(b.pesoliquido, 0)
       OR NVL(s.ativo, '-')     <> NVL(b.ativo, '-')
       OR NVL(s.nrocarga, 0)    <> NVL(b.nrocarga, 0)

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
		WHERE NVL(s.seqproduto, 0)   <> NVL(b.seqproduto, 0)
		   OR NVL(s.qtdembalagem, 0) <> NVL(b.qtdembalagem, 0)
		   OR NVL(s.tipo, '-')       <> NVL(b.tipo, '-')
		   OR NVL(s.ativo, '-')      <> NVL(b.ativo, '-')
		   
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
    -- VOLTANDO PRECO NORMAL CASO ENCERRE VIGENCIA - 357 
    UPDATE MONITORPDVMIDDLE.TB_PRODPRECO TB_PRODPRECO SET
        PRECO = PRECONORMAL,
        PROMOCAO = 'N',
        PRECONORMAL = NULL,
        IDREF = TRIM(replace(IDREF, 'P357-', ''))
    WHERE TB_PRODPRECO.PROMOCAO = 'S'
    AND (TB_PRODPRECO.PRECONORMAL IS NOT NULL OR TB_PRODPRECO.PRECONORMAL > 0)
    AND TB_PRODPRECO.ATIVO = 'S'	
    AND IDREF LIKE '%P357%'
    AND NOT EXISTS(SELECT 1
                       FROM PCPRECOPROM PF,
                            PCDEPARAPRODC5 P,
                            VW_INT_C5_OBTER_FILIAIS_C5 C5
                       WHERE PF.CODPROD = P.CODPROD
                       AND   P.ATIVO = 'S'
                       AND   P.SEQPRODUTO = TB_PRODPRECO.SEQPRODUTO
                       AND   PF.CODFILIAL = C5.CODFILIAL
                       AND   TB_PRODPRECO.NROEMPRESA = C5.CODFILIALINTEGRACAO
                       AND   PF.DTINICIOVIGENCIA IS NOT NULL
                       AND   PF.DTFIMVIGENCIA IS NOT NULL
                       AND   TRUNC(SYSDATE) BETWEEN PF.DTINICIOVIGENCIA AND PF.DTFIMVIGENCIA
                       AND   PF.FRENTECX = 'S'
                       );
	
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
	    WHERE (NVL(TB_PRODPRECO_C5.ativo, '-')     <> NVL(VIEW_TB_PRODPRECO.ativo, '-')
         OR NVL(TB_PRODPRECO_C5.promocao, '-')  <> NVL(VIEW_TB_PRODPRECO.promocao, '-')
         OR NVL(TB_PRODPRECO_C5.preco, 0)       <> NVL(VIEW_TB_PRODPRECO.preco, 0)
         OR NVL(TB_PRODPRECO_C5.PRECONORMAL, 0) <> NVL(VIEW_TB_PRODPRECO.PRECONORMAL, 0))
         AND ((TB_PRODPRECO_C5.idref not like '%P357%') AND (TB_PRODPRECO_C5.promocao <> 'S'))
		 
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
      USING (SELECT 
				   MIN(v.idref) idref,
				   v.seqproduto,
				   v.nroempresa,
				   v.qtdembalagem,
				   v.nrosegmento,
				   MIN(v.preco) preco,
				   MIN(v.promocao) promocao,
				   MIN(v.ativo) ativo,
				   MIN(v.preconormal) preconormal
			 FROM vw_int_c5_promocoes_vigentes v, 
                  monitorpdvmiddle.tb_prodempresa e,
                  VW_INT_C5_OBTER_FILIAIS_C5 C5
			 WHERE V.NROEMPRESA = E.NROEMPRESA
             AND V.SEQPRODUTO = E.SEQPRODUTO
			 AND v.PRIORIDADE = (SELECT min(PRIORIDADE)
								 FROM VW_INT_C5_PROMOCOES_VIGENTES vw
							     WHERE vw.seqproduto = v.SEQPRODUTO
								 AND vw.nroempresa = v.NROEMPRESA
								 AND vw.qtdembalagem = v.QTDEMBALAGEM)
			 AND v.NROEMPRESA = C5.CODFILIALINTEGRACAO
             AND E.NROEMPRESA = C5.CODFILIALINTEGRACAO
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
	  WHERE (NVL(TB_PRODPRECO_C5.ativo, '-')     <> NVL(VW_INT_C5_PROMOCOES_VIGENTES.ativo, '-')
       OR NVL(TB_PRODPRECO_C5.promocao, '-')  <> NVL(VW_INT_C5_PROMOCOES_VIGENTES.promocao, '-')
       OR NVL(TB_PRODPRECO_C5.preco, 0)       <> NVL(VW_INT_C5_PROMOCOES_VIGENTES.preco, 0)
       OR NVL(TB_PRODPRECO_C5.PRECONORMAL, 0) <> NVL(VW_INT_C5_PROMOCOES_VIGENTES.PRECONORMAL, 0)
       OR NVL(TB_PRODPRECO_C5.idref, 0)     <> NVL(VW_INT_C5_PROMOCOES_VIGENTES.idref, 0))
	   AND ((TB_PRODPRECO_C5.idref not like '%P357%') OR (VW_INT_C5_PROMOCOES_VIGENTES.idref LIKE '%P357%'))

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
    WHERE TB_PRODPRECO.PROMOCAO = 'S'
    AND (TB_PRODPRECO.PRECONORMAL IS NOT NULL OR TB_PRODPRECO.PRECONORMAL > 0)
    AND TB_PRODPRECO.ATIVO = 'S'
	AND IDREF not like '%P357%'
    AND NOT EXISTS(SELECT 1
                     FROM VW_INT_C5_PROMOCOES_VIGENTES P
                     WHERE P.SEQPRODUTO = TB_PRODPRECO.SEQPRODUTO
                     AND   P.QTDEMBALAGEM = TB_PRODPRECO.QTDEMBALAGEM
                     AND   P.NROEMPRESA = TB_PRODPRECO.NROEMPRESA
                     );
		
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco', 'carrega_tb_prodpreco', 'carrega_tb_prodpreco OK', SYSDATE, CURRENT_TIMESTAMP);

  COMMIT;

  /*Atualização do cabeçalho da cesta básica e kit */
    MERGE INTO monitorpdvmiddle.tb_prodpreco TB_PRODPRECO_C5
      USING (SELECT * FROM VW_INT_C5_CAB_CESTA) VIEW_TB_PRODPRECO
    on(TB_PRODPRECO_C5.seqproduto = VIEW_TB_PRODPRECO.seqproduto AND TB_PRODPRECO_C5.nroempresa = VIEW_TB_PRODPRECO.nroempresa)
      WHEN MATCHED THEN
      UPDATE SET TB_PRODPRECO_C5.preco = VIEW_TB_PRODPRECO.preco;

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
	    WHERE NVL(s.tributacao, '-')    <> NVL(b.tributacao, '-')
         OR NVL(s.descaplicacao, '-') <> NVL(b.descaplicacao, '-')
         OR NVL(s.ativo, '-')         <> NVL(b.ativo, '-')
		 
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
				e.situacaosimples,
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
			 s.situacaosimples       = b.situacaosimples, 
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
	    WHERE NVL(s.percaliquota, 0)       <> NVL(b.percaliquota, 0)
         OR NVL(s.situacaotributacao, '-') <> NVL(b.situacaotributacao, '-')
		 OR NVL(s.situacaosimples, '-')    <> NVL(b.situacaosimples, '-')
         OR NVL(s.percisento, 0)           <> NVL(b.percisento, 0)
         OR NVL(s.perctributado, 0)        <> NVL(b.perctributado, 0)
         OR NVL(s.percoutro, 0)            <> NVL(b.percoutro, 0)
         OR NVL(s.percacrescst, 0)         <> NVL(b.percacrescst, 0)
         OR NVL(s.percisentost, 0)         <> NVL(b.percisentost, 0)
         OR NVL(s.tipocalcfcp, '-')        <> NVL(b.tipocalcfcp, '-')
         OR NVL(s.percbasefcpicms, 0)      <> NVL(b.percbasefcpicms, 0)
         OR NVL(s.percaliqfcpicms, 0)      <> NVL(b.percaliqfcpicms, 0)
         OR NVL(s.reducaobasest, '-')      <> NVL(b.reducaobasest, '-')
         OR NVL(s.tiporeducaoicmscalcst, '-') <> NVL(b.tiporeducaoicmscalcst, '-')
         OR NVL(s.perctributst, 0)         <> NVL(b.perctributst, 0)
         OR NVL(s.ativo, '-')              <> NVL(b.ativo, '-')
         OR NVL(s.percbasefcpst, 0)        <> NVL(b.percbasefcpst, 0)
         OR NVL(s.percaliqfcpst, 0)        <> NVL(b.percaliqfcpst, 0)
         OR NVL(s.CALCICMSDESON, '-')      <> NVL(b.CALCICMSDESON, '-')
         OR NVL(s.PERCALIQICMSDESON, 0)    <> NVL(b.PERCALIQICMSDESON, 0)         
         OR NVL(s.MOTIVODESONICMS, 0)      <> NVL(b.MOTIVODESONICMS, 0) 
         OR NVL(s.CODBENEFICIODESONICMS, '-') <> NVL(b.CODBENEFICIODESONICMS, '-')
         OR NVL(s.codobservacao, '-')      <> NVL(b.codobservacao, '-')
         OR NVL(s.idref, 0)              <> NVL(b.idref, 0)
		 
      WHEN NOT MATCHED THEN
        INSERT (s.nrotributacao,
                s.uforigem,
                s.ufdestino,
                s.tipotributacao,
                s.nroregtributacao,
                s.percaliquota,
                s.situacaotributacao,
				s.situacaosimples,
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
				 b.situacaosimples,
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
        WHERE NVL(s.perctributo, 0)           <> NVL(b.perctributos, 0)
           OR NVL(s.perctributoimportado, 0)  <> NVL(b.perctributoimportado, 0)
           OR NVL(s.perctributonacfederal, 0) <> NVL(b.perctributonacfederal, 0)
           OR NVL(s.perctributoimpfederal, 0) <> NVL(b.perctributoimpfederal, 0)
           OR NVL(s.perctributoestadual, 0)   <> NVL(b.perctributoestadual, 0)
           OR NVL(s.perctributomunicipal, 0)  <> NVL(b.perctributomunicipal, 0)
           OR NVL(s.ativo, '-')               <> NVL(b.ativo, '-')
		   
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
	     WHERE NVL(s.DESCRICAO, '-')     <> NVL(b.DESCRICAO, '-')
          OR NVL(s.APLICACAO, '-')     <> NVL(b.APLICACAO, '-')
          OR NVL(s.Cfopestado, 0)      <> NVL(b.CFOPESTADO, 0)
          OR NVL(s.CFOPFORAESTADO, 0)  <> NVL(b.CFOPFORAESTADO, 0)
          OR NVL(s.CALCULAICMSST, '-') <> NVL(b.CALCULAICMSST, '-')
          OR NVL(s.GERAREDUCAOBASEST, '-') <> NVL(b.GERAREDUCAOBASEST, '-')
          OR NVL(s.CALCULAIPI, '-')      <> NVL(b.CALCULAIPI, '-')
          OR NVL(s.TIPOCALCULOIPI, '-')  <> NVL(b.TIPOCALCULOIPI, '-')
          OR NVL(s.CALCULAFECP, '-')     <> NVL(b.CALCULAFECP, '-')
          OR NVL(s.TIPOFATURAMENTO, '-') <> NVL(b.TIPOFATURAMENTO, '-')
          OR NVL(s.ATIVO, '-')           <> NVL(b.ATIVO, '-')
          OR NVL(s.CONSUMIDORFINAL, '-') <> NVL(b.CONSUMIDORFINAL, '-')
          OR NVL(s.VENDAPRESENCIAL, '-') <> NVL(b.VENDAPRESENCIAL, '-')
          OR NVL(s.TIPOTRIBUTACAO, '-')  <> NVL(b.TIPOTRIBUTACAO, '-')
                  
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
      WHERE NVL(s.CFOPESTADO, 0)     <> NVL(b.CFOPESTADO, 0)
         OR NVL(s.cfopforaestado, 0) <> NVL(b.cfopforaestado, 0)
         OR NVL(s.ATIVO, '-')        <> NVL(b.ATIVO, '-')
		 
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
	    WHERE NVL(s.NROTRIBUTACAO, 0)  <> NVL(b.NROTRIBUTACAO, 0) 
          OR NVL(s.CONTRIBICMS, '-') <> NVL(b.CONTRIBICMS, '-') 
          OR NVL(s.UFORIGEM, '-')    <> NVL(b.UFORIGEM, '-')
          OR NVL(s.UFDESTINO, '-')   <> NVL(b.UFDESTINO, '-')
          OR NVL(s.CFOPESTADO, 0)    <> NVL(b.CFOPESTADO, 0)
          OR NVL(s.ATIVO, '-')       <> NVL(b.ATIVO, '-')
		  
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
    --UPDATE monitorpdvmiddle.tb_enderecoalternativo SET ativo = 'N';

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
	    WHERE NVL(TB_ENDERECOALTERNATIVO.tipo, '-')          <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.tipo, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.logradouro, '-')    <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.logradouro, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.nrologradouro, '-') <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.nrologradouro, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.bairro, '-')        <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.bairro, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.complemento, '-')   <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.complemento, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.cidade, '-')        <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.cidade, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.uf, '-')            <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.uf, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.cep, 0)             <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.cep, 0)
         OR NVL(TB_ENDERECOALTERNATIVO.ativo, '-')         <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.ativo, '-')
         OR NVL(TB_ENDERECOALTERNATIVO.codibge, 0)         <> NVL(VW_INT_C5_ENDERECO_ALTERNATIVO.codibge, 0)
		 
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
		 
	    UPDATE MONITORPDVMIDDLE.TB_ENDERECOALTERNATIVO E
       SET ATIVO = 'N'
WHERE NOT EXISTS(SELECT 1
                 FROM PCFILIAL F, VW_INT_C5_OBTER_FILIAIS_C5 C5
                 WHERE F.CODIGO = C5.CODFILIAL
                 AND   E.SEQLOGRADOURO = F.CODCLI||C5.CODFILIALINTEGRACAO
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
    vCount number;
  BEGIN
    /*Tratativa para atualizar a view materializada FAMDIVISAO na primeira carga*/
    SELECT COUNT(*) into vCount FROM MONITORPDVMIDDLE.TB_FAMDIVISAO;
    
    IF vCount = 0 THEN
      begin DBMS_MVIEW.REFRESH('VW_INT_C5_FAMDIV_MAT'); END;
      carrega_tb_produto(12);
    END IF;
    
    MERGE INTO monitorpdvmiddle.tb_famdivisao s
        USING (SELECT distinct 
                     E.seqfamilia,
                     E.nrodivisao,
                     E.nrotributacao,
                     E.codorigemtrib,
                     E.ativo
               FROM VW_INT_C5_FAMDIV_MAT E,
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
	    WHERE NVL(s.nrotributacao, 0) <> NVL(b.nrotributacao, 0)
         OR NVL(s.codorigemtrib, 0) <> NVL(b.codorigemtrib, 0)
         OR NVL(s.ativo, '-') <> NVL(b.ativo, '-')
		 
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
      WHERE NVL(s.CONDICAOPAGTO, '-') <> NVL(b.CONDICAOPAGTO, '-')
         OR NVL(s.PERCACRESCIMO, 0) <> NVL(b.PERCACRESCIMO, 0)
         OR NVL(s.NROMAXIMOPARCELA, 0) <> NVL(b.NROMAXIMOPARCELA, 0)
         OR NVL(s.NRODIASVENCTO, 0) <> NVL(b.NRODIASVENCTO, 0)
         OR NVL(s.ATIVO, '-') <> NVL(b.ATIVO, '-')
         OR NVL(s.idref, 0) <> NVL(b.idref, 0)
		 
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
	  
	  UPDATE monitorpdvmiddle.TB_REGRAINCENTIVO SET ATIVO = 'N'
      WHERE ATIVO = 'S'
      AND   REGRA LIKE '%PRECO FIXO%';
      
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
       WHERE NVL(tb_regraincentivo_C5.REGRA, '-')      <> NVL(VIEW_C5_INCENTIVO.REGRA, '-')
          OR NVL(tb_regraincentivo_C5.SEQTIPOCREDITO, 0) <> NVL(VIEW_C5_INCENTIVO.SEQTIPOCREDITO, 0)
          OR NVL(tb_regraincentivo_C5.ATIVO, '-')      <> NVL(VIEW_C5_INCENTIVO.ATIVO, '-')
          OR NVL(tb_regraincentivo_C5.TIPOREGRA, '-')  <> NVL(VIEW_C5_INCENTIVO.TIPOREGRA, '-')
          OR NVL(tb_regraincentivo_C5.CUMULATIVO, '-') <> NVL(VIEW_C5_INCENTIVO.CUMULATIVO, '-')
          OR NVL(tb_regraincentivo_C5.idref, 0)      <> NVL(VIEW_C5_INCENTIVO.idref, 0)
          
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
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA)
      OR IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
	                FROM PCDESCONTOFIDELIDADE P
				   WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE));
   
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
        USING (SELECT distinct seqregra, dtahorinicio, dtahorfim, idref, ATIVO FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
      on(
             tb_regraincentivoperiodo_c5.SEQREGRA     = VIEW_C5_INCENTIVO.SEQREGRA 
        AND  tb_regraincentivoperiodo_c5.DTAHORINICIO = VIEW_C5_INCENTIVO.DTAHORINICIO
        AND  tb_regraincentivoperiodo_c5.DTAHORFIM    = VIEW_C5_INCENTIVO.DTAHORFIM
        AND  tb_regraincentivoperiodo_c5.IDREF        = VIEW_C5_INCENTIVO.IDREF

        
      )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraincentivoperiodo_c5.ATIVO           = VIEW_C5_INCENTIVO.ATIVO
        WHERE NVL(tb_regraincentivoperiodo_c5.ATIVO, '-') <> NVL(VIEW_C5_INCENTIVO.ATIVO, '-')
		
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
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM
					UNION ALL
    				SELECT D.CODFILIAL||561||D.CODDESCONTO 
                      FROM PCDESCONTO D
                     WHERE D.DTFIM < TRUNC(SYSDATE) )
       OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA)
	   OR IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
	                FROM PCDESCONTOFIDELIDADE P
				   WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE));

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
        USING (SELECT DISTINCT I.SEQREGRA, I.NROEMPRESA, I.ATIVO, I.IDREF
                 FROM VW_INT_C5_REGRAINCENTIVO I
               WHERE I.NROEMPRESA <> '99'
                UNION ALL
              SELECT DISTINCT R.SEQREGRA, C5.CODFILIALINTEGRACAO, R.ATIVO, R.IDREF
                 FROM VW_INT_C5_REGRAINCENTIVO R, VW_INT_C5_OBTER_FILIAIS_C5 C5
                WHERE NROEMPRESA = 99) VIEW_C5_INCENTIVO
      on(tb_regraempresa_c5.SEQREGRA     = VIEW_C5_INCENTIVO.SEQREGRA AND
         tb_regraempresa_c5.NROEMPRESA   = VIEW_C5_INCENTIVO.NROEMPRESA
        )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regraempresa_c5.ATIVO  = VIEW_C5_INCENTIVO.ATIVO,
		  tb_regraempresa_c5.IDREF  = VIEW_C5_INCENTIVO.IDREF
		WHERE NVL(tb_regraempresa_c5.ATIVO, '-') <> NVL(VIEW_C5_INCENTIVO.ATIVO, '-')
          
       WHEN NOT MATCHED THEN
        INSERT(
          tb_regraempresa_c5.SEQREGRA,
          tb_regraempresa_c5.NROEMPRESA,
          tb_regraempresa_c5.ATIVO,
		  tb_regraempresa_c5.IDREF
        ) 
        VALUES(
          VIEW_C5_INCENTIVO.SEQREGRA,
          VIEW_C5_INCENTIVO.NROEMPRESA,
          VIEW_C5_INCENTIVO.ATIVO,
		  VIEW_C5_INCENTIVO.IDREF
        );
		
   UPDATE MONITORPDVMIDDLE.tb_regraempresa SET ATIVO = 'N'
   WHERE IDREF IN (SELECT NVL(L.CODFILIAL, '99')||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM);
      
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
        USING (SELECT distinct  seqregra,ativo FROM VW_INT_C5_REGRAINCENTIVO) VIEW_C5_INCENTIVO
        on(tb_regrasegmento_c5.SEQREGRA      = VIEW_C5_INCENTIVO.SEQREGRA AND
           tb_regrasegmento_c5.NROSEGMENTO   = 1
          )
       WHEN MATCHED THEN
        UPDATE SET
          tb_regrasegmento_c5.ATIVO  = VIEW_C5_INCENTIVO.ATIVO
        WHERE NVL(tb_regrasegmento_c5.ATIVO, '-')  <> NVL(VIEW_C5_INCENTIVO.ATIVO, '-')
		
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
               SELECT DISTINCT SEQREGRA, SEQPRODUTO, QTDEMBALAGEM, PERCDESCONTO, PRECO, ATIVO, IDREF  
               FROM VW_INT_C5_DESC561PRODUTO
               /*UNION ALL
               SELECT DISTINCT SEQREGRA, SEQPRODUTO, QTDEMBALAGEM, PERCDESCONTO, PRECO, ATIVO, IDREF 
               FROM VW_INT_C5_PRECOFIXO_R357*/
			   UNION ALL 
			   SELECT DISTINCT SEQREGRA, SEQPRODUTO, QTDEMBALAGEM, PERCDESCONTO, PRECO, ATIVO, IDREF 
               FROM VW_INT_C5_DESC2048PRODUTO
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
        WHERE NVL(tb_regraproduto_c5.PERCDESCONTO, 0) <> NVL(vw_int_c5_regraproduto.PERCDESCONTO, 0)
           OR NVL(tb_regraproduto_c5.PRECO, 0)        <> NVL(vw_int_c5_regraproduto.PRECO, 0)
           OR NVL(tb_regraproduto_c5.ATIVO, '-')      <> NVL(vw_int_c5_regraproduto.ATIVO, '-')
           OR NVL(tb_regraproduto_c5.idref, 0)      <> NVL(vw_int_c5_regraproduto.idref, 0)
		   
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
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM
					UNION ALL
    				SELECT D.CODFILIAL||561||D.CODDESCONTO 
                      FROM PCDESCONTO D
                     WHERE D.DTFIM < TRUNC(SYSDATE) )
       OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA)
	   OR IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
	                FROM PCDESCONTOFIDELIDADE P
				   WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE));

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
    USING (SELECT DISTINCT C.SEQPESSOA,
                  C.SEQREGRA,
				  C.PERCDESCONTO,
                  C.ATIVO,
				  C.IDREF
				  FROM VW_INT_C5_DESC561CLIENTE C
				  UNION ALL
				  SELECT DISTINCT F.SEQPESSOA,
                  F.SEQREGRA,
				  F.PERCDESCONTO,
                  F.ATIVO,
				  F.IDREF
				  FROM VW_INT_C5_DESC2048CLIENTE F) S 
    ON    ( D.SEQPESSOA = S.SEQPESSOA AND D.SEQREGRA = S.SEQREGRA)
  WHEN MATCHED THEN
       UPDATE SET
          D.PERCDESCONTO    = S.PERCDESCONTO,
          D.ATIVO           = S.ATIVO,
          D.IDREF           = S.IDREF 
       WHERE NVL(D.PERCDESCONTO, 0) <> NVL(S.PERCDESCONTO, 0)
          OR NVL(D.ATIVO, '-')      <> NVL(S.ATIVO, '-')
          OR NVL(D.idref, 0)      <> NVL(S.idref, 0)
		  
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
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM
					UNION ALL
    				SELECT D.CODFILIAL||561||D.CODDESCONTO 
                      FROM PCDESCONTO D
                     WHERE D.DTFIM < TRUNC(SYSDATE) )
       OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA)
	   OR IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
	                FROM PCDESCONTOFIDELIDADE P
				   WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE));
  
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
          D.ATIVO           = S.ATIVO,
		  D.IDREF           = S.IDREF
       WHERE NVL(D.PERCDESCONTO, 0) <> NVL(S.PERCDESCONTO, 0)
          OR NVL(D.ATIVO, '-')      <> NVL(S.ATIVO, '-')
		  
  WHEN NOT MATCHED THEN
        INSERT(
          D.SEQREGRA,
          D.NRODIVISAO,
          D.SEQCATEGORIA,
          D.PERCDESCONTO,
          D.ATIVO,
		  D.IDREF) 
        VALUES(
          S.SEQREGRA,
          S.NRODIVISAO,
          S.SEQCATEGORIA,
          S.PERCDESCONTO,
          S.ATIVO,
		  S.IDREF);

   UPDATE MONITORPDVMIDDLE.tb_regracategoria SET ATIVO = 'N'
    WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM
					UNION ALL
    				SELECT D.CODFILIAL||561||D.CODDESCONTO 
                      FROM PCDESCONTO D
                     WHERE D.DTFIM < TRUNC(SYSDATE) )
       OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA)
	   OR IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
	                FROM PCDESCONTOFIDELIDADE P
				   WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE));
  
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


PROCEDURE carrega_tb_regrapessoagrupo(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regrapessoagrupo D
    USING (SELECT C.PERCDESCONTO,
	              C.SEQREGRA,
				  C.SEQGRUPOPESSOA,
				  C.ATIVO,
				  C.IDREF
    	     FROM VW_INT_C5_DESC2048GRUPOPESSOA C) S 
    ON    ( D.SEQGRUPOPESSOA = S.SEQGRUPOPESSOA AND D.SEQREGRA = S.SEQREGRA)
  WHEN MATCHED THEN
       UPDATE SET
          D.PERCDESCONTO    = S.PERCDESCONTO,
          D.ATIVO           = S.ATIVO,
		      D.IDREF           = S.IDREF
       WHERE NVL(D.PERCDESCONTO, 0) <> NVL(S.PERCDESCONTO, 0)
          OR NVL(D.ATIVO, '-')      <> NVL(S.ATIVO, '-')
		  
  WHEN NOT MATCHED THEN
        INSERT(
          D.SEQREGRA,
          D.SEQGRUPOPESSOA,
          D.IDREF,
          D.PERCDESCONTO,
          D.ATIVO) 
        VALUES(
          S.SEQREGRA,
          S.SEQGRUPOPESSOA,
          S.IDREF,
          S.PERCDESCONTO,
          S.ATIVO);

  UPDATE MONITORPDVMIDDLE.tb_regrapessoagrupo G SET ATIVO = 'N'
    WHERE IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
                  FROM PCDESCONTOFIDELIDADE P
           WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE))
    OR NOT EXISTS (SELECT 1 
                     FROM PCGRUPOFIDELIDADEDESCONTO F
                    INNER JOIN PCGRUPOFIDELIDADE G1
                          ON (G1.CODGRUPOFIDELIDADE = F.CODGRUPOFIDELIDADE)
                     WHERE F.CODGRUPOFIDELIDADE = G.SEQGRUPOPESSOA ) ;

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regrapessoagrupo', 'carrega_tb_regrapessoagrupo OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_regrapessoagrupo',
           'carrega_tb_regrapessoagrupo ALERTA',
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
           'carrega_tb_regrapessoagrupo',
           'carrega_tb_regrapessoagrupo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_regradestino(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regradestino D
    USING (SELECT C.SEQDESTINO,
	              C.SEQREGRA,
				  C.ATIVO,
				  C.IDREF
    	     FROM VW_INT_C5_REGRADESTINO C) S 
    ON     (D.SEQDESTINO = S.SEQDESTINO AND D.SEQREGRA = S.SEQREGRA)
  WHEN MATCHED THEN
       UPDATE SET
          D.ATIVO           = S.ATIVO,
		  D.IDREF           = S.IDREF
       WHERE NVL(D.ATIVO, '-')      <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
        INSERT(
		  D.SEQDESTINO,
          D.SEQREGRA,
          D.IDREF,
          D.ATIVO) 
        VALUES(
		  S.SEQDESTINO,
          S.SEQREGRA,
          S.IDREF,
          S.ATIVO);

   UPDATE MONITORPDVMIDDLE.tb_regradestino SET ATIVO = 'N'
    WHERE IDREF IN (SELECT L.CODFILIAL||561||L.CODDESCONTO  
                       FROM PCDESCONTOLOG L 
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIO AND L.DTFIM
					UNION ALL
    				SELECT D.CODFILIAL||561||D.CODDESCONTO 
                      FROM PCDESCONTO D
                     WHERE D.DTFIM < TRUNC(SYSDATE) )
       OR IDREF IN (SELECT L.CODFILIAL||357||L.CODPRECOPROM  
                       FROM PCPRECOPROMLOG L
                       WHERE TRUNC(SYSDATE) BETWEEN L.DTINICIOVIGENCIA AND L.DTFIMVIGENCIA)
	   OR IDREF IN (SELECT P.CODFILIAL||2048||P.CODFIDELIDADE
	                FROM PCDESCONTOFIDELIDADE P
				   WHERE P.DTEXCLUSAO IS NOT NULL
                      OR P.DTFINAL < TRUNC(SYSDATE));


  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regradestino', 'carrega_tb_regradestino OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_regradestino',
           'carrega_tb_regradestino ALERTA',
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
           'carrega_tb_regradestino',
           'carrega_tb_regradestino ERRO',
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
        WHERE NVL(tb_prodprecoapartir_c5.NROSEGMENTO, 0) <> NVL(vw_int_c5_prodprecoapartir.NROSEGMENTO, 0)
           OR NVL(tb_prodprecoapartir_c5.SEQFAMILIA, 0)  <> NVL(vw_int_c5_prodprecoapartir.SEQFAMILIA, 0)
           OR NVL(tb_prodprecoapartir_c5.SEQPRODUTO, 0)  <> NVL(vw_int_c5_prodprecoapartir.SEQPRODUTO, 0)
           OR NVL(tb_prodprecoapartir_c5.QTDE, 0)        <> NVL(vw_int_c5_prodprecoapartir.QTDE, 0)
           OR NVL(tb_prodprecoapartir_c5.PERCDESCONTO, 0)<> NVL(vw_int_c5_prodprecoapartir.PERCDESCONTO, 0)
           OR NVL(tb_prodprecoapartir_c5.PRECO, 0)       <> NVL(vw_int_c5_prodprecoapartir.PRECO, 0)
           OR NVL(tb_prodprecoapartir_c5.DTAINICIO, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(vw_int_c5_prodprecoapartir.DTAINICIO, TO_DATE('01-01-1994','DD-MM-YYYY'))
           OR NVL(tb_prodprecoapartir_c5.DTAFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))    <> NVL(vw_int_c5_prodprecoapartir.DTAFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))
           OR NVL(tb_prodprecoapartir_c5.ATIVO, '-')     <> NVL(vw_int_c5_prodprecoapartir.ATIVO, '-')
           OR NVL(tb_prodprecoapartir_c5.idref, 0)     <> NVL(vw_int_c5_prodprecoapartir.idref, 0)
          
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
       WHERE NVL(TB_COMBO.COMBO, '-')   <> NVL(VIEW_BRINDE_CABECALHO.DESCRICAO, '-')
          OR NVL(TB_COMBO.DTAINICIO, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(VIEW_BRINDE_CABECALHO.DTAINICIO, TO_DATE('01-01-1994','DD-MM-YYYY'))
          OR NVL(TB_COMBO.DTAFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))    <> NVL(VIEW_BRINDE_CABECALHO.DTAFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))
          OR NVL(TB_COMBO.TIPO, 0)      <> NVL(VIEW_BRINDE_CABECALHO.TIPO, 0)
          OR NVL(TB_COMBO.ATIVO, '-')   <> NVL(VIEW_BRINDE_CABECALHO.ATIVO, '-')
           
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
       WHERE NVL(TB_COMBOEMPRESA.ATIVO, '-') <> NVL(VIEW_BRINDE_CABECALHO.ATIVO, '-')
	   
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
	 WHERE NVL(TB_COMBOITEM.SEQPRODUTO, 0)   <> NVL(VIEW_BRINDE_ITENS.SEQPRODUTO, 0)
      OR NVL(TB_COMBOITEM.ATIVO, '-')      <> NVL(VIEW_BRINDE_ITENS.ATIVO, '-')
      OR NVL(TB_COMBOITEM.QTDE, 0)         <> NVL(VIEW_BRINDE_ITENS.QTDE, 0)
	    OR NVL(TB_COMBOITEM.QTDEMBALAGEM, 0) <> NVL(VIEW_BRINDE_ITENS.QTDEMBALAGEM, 0)
      OR NVL(TB_COMBOITEM.PRECO, 0)        <> NVL(VIEW_BRINDE_ITENS.PRECO, 0)
      OR NVL(TB_COMBOITEM.PERCDESCONTO, 0) <> NVL(VIEW_BRINDE_ITENS.PERCDESCONTO, 0)
      OR NVL(TB_COMBOITEM.SEQFAMILIA, 0)   <> NVL(VIEW_BRINDE_ITENS.SEQFAMILIA, 0)
      OR NVL(TB_COMBOITEM.idref, 0)      <> NVL(VIEW_BRINDE_ITENS.idref, 0)
      OR NVL(TB_COMBOITEM.TIPOITEM, '-')   <> NVL(VIEW_BRINDE_ITENS.TIPOITEM, '-')
      OR NVL(TB_COMBOITEM.SEQGRUPO, 0)     <> NVL(VIEW_BRINDE_ITENS.SEQGRUPO, 0)
            
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
  WHERE NVL(T.QTDE, 0)    <> NVL(V.QTDE, 0)
     OR NVL(T.GRUPO, '-') <> NVL(V.GRUPO, '-')
     OR NVL(T.ATIVO, '-') <> NVL(V.ATIVO, '-')
     OR NVL(T.idref, 0) <> NVL(V.idref, 0)
	 
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
       WHERE NVL(T.DESCRICAO, '-') <> NVL(S.DESCRICAO, '-')
          OR NVL(T.TIPO, '-')      <> NVL(S.TIPO, '-')
          OR NVL(T.ATIVO, '-')     <> NVL(S.ATIVO, '-')   
		  
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
       WHERE NVL(T.ATIVO, '-') <> NVL(S.ATIVO,'-')
	   
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
       WHERE NVL(T.ATIVO, '-') <> NVL(S.ATIVO, '-')
	   
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
       WHERE NVL(T.NROMAXIMOPARCELA, 0) <> NVL(S.NROMAXIMOPARCELA, 0)
          OR NVL(T.ATIVO, '-')          <> NVL(S.ATIVO, '-')   
		  
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
      WHERE NVL(s.NOME, '-')     <> NVL(b.NOMEGRUPO, '-')
         OR NVL(s.PERCDESCMAXIMO, 0) <> NVL(b.PERCDESCMAX, 0)
         OR NVL(s.ATIVO, '-')    <> NVL(b.ATIVO, '-')
		 
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
	WHERE NVL(s.ATIVO, '-') <> NVL(b.ATIVO, '-')
	
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
      WHERE NVL(TB_PROMSURPRESA.DESCRICAO, '-')    <> NVL(VW_INT_C5_BRINDE_CABECALHO_AUT.DESCRICAO, '-')
         OR NVL(TB_PROMSURPRESA.TIPOSURPRESA, '-') <> NVL(VW_INT_C5_BRINDE_CABECALHO_AUT.TIPOSURPRESA, '-')
         OR NVL(TB_PROMSURPRESA.ATIVO, '-')        <> NVL(VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO, '-')
		     OR NVL(TB_PROMSURPRESA.CUMULATIVO, '-')   <> NVL(VW_INT_C5_BRINDE_CABECALHO_AUT.CUMULATIVO, '-')
		 
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
      WHERE NVL(TB_PROMSURPRESAEMPRESA.ATIVO, '-') <> NVL(VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO, '-')
	  
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
      WHERE NVL(TB_PROMSURPRESAEMPRESAPERIODO.ATIVO, '-') <> NVL(VW_INT_C5_BRINDE_CABECALHO_AUT.ATIVO, '-')
	  
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
	    WHERE NVL(TB_PROMSURPRESAITEM.SEQGRUPO, 0)     <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.SEQGRUPO, 0)
         OR NVL(TB_PROMSURPRESAITEM.QTDE, 0)         <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.QTDE, 0)
         OR NVL(TB_PROMSURPRESAITEM.SEQPRODUTO, 0)   <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.SEQPRODUTO, 0)
         OR NVL(TB_PROMSURPRESAITEM.TIPOITEM, '-')   <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.TIPOITEM, '-')
         OR NVL(TB_PROMSURPRESAITEM.QTDEMBALAGEM, 0) <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.QTDEMBALAGEM, 0)
         OR NVL(TB_PROMSURPRESAITEM.ATIVO, '-')      <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.ATIVO, '-')
         OR NVL(TB_PROMSURPRESAITEM.SEQFAMILIA, 0)   <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.SEQFAMILIA, 0)
         OR NVL(TB_PROMSURPRESAITEM.idref, 0)      <> NVL(VW_INT_C5_BRINDE_ITENS_AUT.idref, 0)
      
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
  WHERE NVL(T.QTDE, 0)  <> NVL(V.QTDE, 0)
     OR NVL(T.GRUPO, '-') <> NVL(V.GRUPO, '-')
     OR NVL(T.ATIVO, '-') <> NVL(V.ATIVO, '-')
     OR NVL(T.idref, 0) <> NVL(V.idref, 0)

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
       WHERE NVL(T.INFORMADOTRIBUF, '-')   <> NVL(S.INFORMADOTRIBUF, '-')
          OR NVL(T.GERACBENEFFAMTRIB, '-') <> NVL(S.GERACBENEFFAMTRIB, '-')
          OR NVL(T.ATIVO, '-')             <> NVL(S.ATIVO, '-')
		  
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
       WHERE NVL(T.CODOBSERVACAO, 0)    <> NVL(S.CODOBSERVACAO, 0)
          OR NVL(T.CODAJUSTEEFD, '')    <> NVL(S.CODAJUSTEEFD, '')
          OR NVL(T.USACODAJUSTENFE, '') <> NVL(S.USACODAJUSTENFE, '')
          OR NVL(T.REGISTRO, '')        <> NVL(S.REGISTRO, '')
          OR NVL(T.ATIVO, '')           <> NVL(S.ATIVO, '') 
		  
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
       WHERE NVL(T.CODAJUSTEEFD, '-') <> NVL(S.CODAJUSTEEFD, '-')
          OR NVL(T.ATIVO, '-')        <> NVL(S.ATIVO, '-')   
		  
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
    USING (SELECT 'CRED' CODESPECIE, 'CRÉDITO DE CLIENTE' DESCRICAO, 'S' ATIVO, CODFILIALINTEGRACAO NROEMPRESA FROM VW_INT_C5_OBTER_FILIAIS_C5) T
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

PROCEDURE CARREGA_TB_GRUPOPESSOA(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  MERGE INTO MONITORPDVMIDDLE.TB_GRUPOPESSOA TB_GRUPOPESSOA
    USING (SELECT DISTINCT SEQGRUPOPESSOA, DESCRICAO, ATIVO FROM VW_INT_C5_GRUPOPESSOA) T
    ON (TB_GRUPOPESSOA.SEQGRUPOPESSOA = T.SEQGRUPOPESSOA)
  WHEN MATCHED THEN
    UPDATE SET
	  TB_GRUPOPESSOA.DESCRICAO = T.DESCRICAO,
      TB_GRUPOPESSOA.ATIVO = T.ATIVO
    WHERE NVL(TB_GRUPOPESSOA.DESCRICAO, '-') <> NVL(T.DESCRICAO, '-')
       OR NVL(TB_GRUPOPESSOA.ATIVO, '-') <> NVL(T.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT(
      TB_GRUPOPESSOA.SEQGRUPOPESSOA,
      TB_GRUPOPESSOA.DESCRICAO,
      TB_GRUPOPESSOA.ATIVO
    )
    VALUES(
      T.SEQGRUPOPESSOA,
      T.DESCRICAO,
      T.ATIVO
    );

     UPDATE MONITORPDVMIDDLE.TB_GRUPOPESSOA G
       SET ATIVO = 'N'
       WHERE NOT EXISTS (SELECT 1 
                           FROM PCGRUPOFIDELIDADE F
                          WHERE F.CODGRUPOFIDELIDADE = G.SEQGRUPOPESSOA);
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'CARREGA_TB_GRUPOPESSOA', 'TB_GRUPOPESSOA OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'CARREGA_TB_GRUPOPESSOA',
           'CARREGA_TB_GRUPOPESSOA ALERTA',
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
           'CARREGA_TB_GRUPOPESSOA',
           'CARREGA_TB_GRUPOPESSOA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE CARREGA_TB_PESSOAGRUPO(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  MERGE INTO MONITORPDVMIDDLE.TB_PESSOAGRUPO TB_PESSOAGRUPO
    USING (SELECT DISTINCT SEQGRUPOPESSOA, SEQPESSOA, ATIVO FROM VW_INT_C5_PESSOAGRUPO) T
    ON (TB_PESSOAGRUPO.SEQGRUPOPESSOA = T.SEQGRUPOPESSOA AND TB_PESSOAGRUPO.SEQPESSOA = T.SEQPESSOA )
  WHEN MATCHED THEN
    UPDATE SET
      TB_PESSOAGRUPO.ATIVO = T.ATIVO
    WHERE NVL(TB_PESSOAGRUPO.ATIVO, '-') <> NVL(T.ATIVO, '-')
	
  WHEN NOT MATCHED THEN
    INSERT(
      TB_PESSOAGRUPO.SEQGRUPOPESSOA,
      TB_PESSOAGRUPO.SEQPESSOA,
      TB_PESSOAGRUPO.ATIVO
    )
    VALUES(
      T.SEQGRUPOPESSOA,
      T.SEQPESSOA,
      T.ATIVO
    );

  UPDATE MONITORPDVMIDDLE.TB_PESSOAGRUPO G
    SET ATIVO = 'N'
  WHERE NOT EXISTS (SELECT 1 
                    FROM PCGRUPOFIDELIDADECLIENTE P
					INNER JOIN PCGRUPOFIDELIDADE F
					  ON (F.CODGRUPOFIDELIDADE = P.CODGRUPOFIDELIDADE)
                    WHERE P.CODGRUPOFIDELIDADE = G.SEQGRUPOPESSOA
                    AND P.CODCLI = G.SEQPESSOA)	;
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'CARREGA_TB_PESSOAGRUPO', 'TB_PESSOAGRUPO OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'CARREGA_TB_PESSOAGRUPO',
           'CARREGA_TB_PESSOAGRUPO ALERTA',
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
           'CARREGA_TB_PESSOAGRUPO',
           'CARREGA_TB_PESSOAGRUPO ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE CARREGA_TB_PRECOAPARTIR(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  UPDATE MONITORPDVMIDDLE.TB_PRECOAPARTIR T SET 
    T.ATIVO = 'N'
  WHERE 
    T.ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIR TB_PRECOAPARTIR
    USING (SELECT DISTINCT SEQPRECOAPARTIR, DESCRICAO, ATIVO FROM VW_INT_C5_PRECOAPARTIR) T
    ON (TB_PRECOAPARTIR.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIR.DESCRICAO = T.DESCRICAO,
      TB_PRECOAPARTIR.ATIVO = T.ATIVO
    WHERE NVL(TB_PRECOAPARTIR.DESCRICAO, '-') <> NVL(T.DESCRICAO, '-')
       OR NVL(TB_PRECOAPARTIR.ATIVO, '-') <> NVL(T.ATIVO, '-')
	   
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


PROCEDURE CARREGA_TB_PRECOAPARTIRPESSOA(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  /*UPDATE MONITORPDVMIDDLE.TB_PRECOAPARTIRPESSOA T SET 
    T.ATIVO = 'N'
  WHERE 
    T.ATIVO = 'S';*/

  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIRPESSOA TB_PRECOAPARTIRPESSOA
    USING (SELECT DISTINCT SEQPRECOAPARTIR, SEQPESSOA, ATIVO FROM VW_INT_C5_PRECOAPARTIRPESSOA) T
    ON (TB_PRECOAPARTIRPESSOA.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR and TB_PRECOAPARTIRPESSOA.SEQPESSOA = T.SEQPESSOA)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIRPESSOA.ATIVO = T.ATIVO
    WHERE NVL(TB_PRECOAPARTIRPESSOA.ATIVO, '-') <> NVL(T.ATIVO, '-')
	
  WHEN NOT MATCHED THEN
    INSERT(
      TB_PRECOAPARTIRPESSOA.SEQPRECOAPARTIR,
      TB_PRECOAPARTIRPESSOA.SEQPESSOA,
      TB_PRECOAPARTIRPESSOA.ATIVO
    )
    VALUES(
      T.SEQPRECOAPARTIR,
      T.SEQPESSOA,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_PRECOAPARTIRPESSOA', 'TB_PRECOAPARTIRPESSOA OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_PRECOAPARTIRPESSOA',
           'carrega_TB_PRECOAPARTIRPESSOA ALERTA',
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
           'carrega_TB_PRECOAPARTIRPESSOA',
           'carrega_TB_PRECOAPARTIRPESSOA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE CARREGA_TB_PRECOAPARTIREMPRESA(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  UPDATE MONITORPDVMIDDLE.TB_PRECOAPARTIREMPRESA 
  SET ATIVO = 'N'
  WHERE 
   ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIREMPRESA TB_PRECOAPARTIREMPRESA
    USING (SELECT SEQPRECOAPARTIR, NROEMPRESA, ATIVO FROM VW_INT_C5_PRECOAPARTIR) T
    ON (TB_PRECOAPARTIREMPRESA.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR and TB_PRECOAPARTIREMPRESA.NROEMPRESA = T.NROEMPRESA)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIREMPRESA.ATIVO = T.ATIVO
    WHERE NVL(TB_PRECOAPARTIREMPRESA.ATIVO, '-') <> NVL(T.ATIVO, '-')
	
  WHEN NOT MATCHED THEN
    INSERT(
      TB_PRECOAPARTIREMPRESA.SEQPRECOAPARTIR,
      TB_PRECOAPARTIREMPRESA.NROEMPRESA,
      TB_PRECOAPARTIREMPRESA.ATIVO
    )
    VALUES(
      T.SEQPRECOAPARTIR,
      T.NROEMPRESA,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_PRECOAPARTIREMPRESA', 'TB_PRECOAPARTIREMPRESA OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_PRECOAPARTIREMPRESA',
           'carrega_TB_PRECOAPARTIREMPRESA ALERTA',
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
           'carrega_TB_PRECOAPARTIREMPRESA',
           'carrega_TB_PRECOAPARTIREMPRESA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;


PROCEDURE CARREGA_TB_PRECOAPARTIRSEGMENT(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  UPDATE MONITORPDVMIDDLE.TB_PRECOAPARTIRSEGMENTO 
  SET ATIVO = 'N'
  WHERE 
    ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIRSEGMENTO TB_PRECOAPARTIRSEGMENTO
    USING (SELECT DISTINCT SEQPRECOAPARTIR, NROSEGMENTO, ATIVO FROM VW_INT_C5_PRECOAPARTIR) T
    ON (TB_PRECOAPARTIRSEGMENTO.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR AND TB_PRECOAPARTIRSEGMENTO.NROSEGMENTO = T.NROSEGMENTO)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIRSEGMENTO.ATIVO = T.ATIVO
    WHERE NVL(TB_PRECOAPARTIRSEGMENTO.ATIVO, '-') <> NVL(T.ATIVO, '-')
	
  WHEN NOT MATCHED THEN
    INSERT(
      TB_PRECOAPARTIRSEGMENTO.SEQPRECOAPARTIR,
      TB_PRECOAPARTIRSEGMENTO.NROSEGMENTO,
      TB_PRECOAPARTIRSEGMENTO.ATIVO
    )
    VALUES(
      T.SEQPRECOAPARTIR,
      T.NROSEGMENTO,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_PRECOAPARTIRSEGMENTO', 'TB_PRECOAPARTIRSEGMENTO OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_PRECOAPARTIRSEGMENTO',
           'carrega_TB_PRECOAPARTIRSEGMENTO ALERTA',
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
           'carrega_TB_PRECOAPARTIRSEGMENTO',
           'carrega_TB_PRECOAPARTIRSEGMENTO ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE CARREGA_TB_PRECOAPARTIRPERIODO(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  UPDATE MONITORPDVMIDDLE.TB_PRECOAPARTIRPERIODO
  SET
    ATIVO = 'N'
  WHERE
    ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIRPERIODO TB_PRECOAPARTIRPERIODO
    USING (SELECT DISTINCT SEQPRECOAPARTIR, DTAHORINICIO, DTAHORFIM, ATIVO FROM VW_INT_C5_PRECOAPARTIR) T
    ON (TB_PRECOAPARTIRPERIODO.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIRPERIODO.DTAHORINICIO = T.DTAHORINICIO, 
      TB_PRECOAPARTIRPERIODO.DTAHORFIM = T.DTAHORFIM,
      TB_PRECOAPARTIRPERIODO.ATIVO = T.ATIVO
    WHERE NVL(TB_PRECOAPARTIRPERIODO.DTAHORINICIO, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(T.DTAHORINICIO, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(TB_PRECOAPARTIRPERIODO.DTAHORFIM, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(T.DTAHORFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(TB_PRECOAPARTIRPERIODO.ATIVO, '-') <> NVL(T.ATIVO, '-')
	   
  WHEN NOT MATCHED THEN
    INSERT(
      TB_PRECOAPARTIRPERIODO.SEQPRECOAPARTIR,
      TB_PRECOAPARTIRPERIODO.DTAHORINICIO,
      TB_PRECOAPARTIRPERIODO.DTAHORFIM,
      TB_PRECOAPARTIRPERIODO.ATIVO
    )
    VALUES(
      T.SEQPRECOAPARTIR,
      T.DTAHORINICIO,
      T.DTAHORFIM,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_PRECOAPARTIRPERIODO', 'TB_PRECOAPARTIRPERIODO OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_PRECOAPARTIRPERIODO',
           'carrega_TB_PRECOAPARTIRPERIODO ALERTA',
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
           'carrega_TB_PRECOAPARTIRPERIODO',
           'carrega_TB_PRECOAPARTIRPERIODO ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;



PROCEDURE CARREGA_TB_PRECOAPARTIRPRODUTO(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  UPDATE MONITORPDVMIDDLE.TB_PRECOAPARTIRPRODUTO 
  SET ATIVO = 'N'
  WHERE
    ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_PRECOAPARTIRPRODUTO TB_PRECOAPARTIRPRODUTO
    USING (SELECT SEQPRECOAPARTIR, SEQPRODUTO, PRECO, PERCDESCONTO, QTDE, ATIVO FROM VW_INT_C5_PRECOAPARTIRPRODUTO) T
    ON (TB_PRECOAPARTIRPRODUTO.SEQPRECOAPARTIR = T.SEQPRECOAPARTIR AND TB_PRECOAPARTIRPRODUTO.SEQPRODUTO = T.SEQPRODUTO AND TB_PRECOAPARTIRPRODUTO.QTDE = T.QTDE)
  WHEN MATCHED THEN
    UPDATE SET
      TB_PRECOAPARTIRPRODUTO.PRECO = T.PRECO, 
      TB_PRECOAPARTIRPRODUTO.PERCDESCONTO = T.PERCDESCONTO,
      TB_PRECOAPARTIRPRODUTO.ATIVO = T.ATIVO
	  WHERE NVL(TB_PRECOAPARTIRPRODUTO.PRECO, 0) <> NVL(T.PRECO, 0)
       OR NVL(TB_PRECOAPARTIRPRODUTO.PERCDESCONTO, 0) <> NVL(T.PERCDESCONTO, 0)
       OR NVL(TB_PRECOAPARTIRPRODUTO.ATIVO, '-') <> NVL(T.ATIVO, '-')

  WHEN NOT MATCHED THEN
    INSERT(
      TB_PRECOAPARTIRPRODUTO.SEQPRECOAPARTIR,
      TB_PRECOAPARTIRPRODUTO.SEQPRODUTO,
      TB_PRECOAPARTIRPRODUTO.PRECO,
      TB_PRECOAPARTIRPRODUTO.PERCDESCONTO,
      TB_PRECOAPARTIRPRODUTO.QTDE,
      TB_PRECOAPARTIRPRODUTO.ATIVO
    )
    VALUES(
      T.SEQPRECOAPARTIR,
      T.SEQPRODUTO,
      T.PRECO,
      T.PERCDESCONTO,
      T.QTDE,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_PRECOAPARTIRPRODUTO', 'TB_PRECOAPARTIRPRODUTO OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_PRECOAPARTIRPRODUTO',
           'carrega_TB_PRECOAPARTIRPRODUTO ALERTA',
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
           'carrega_TB_PRECOAPARTIRPRODUTO',
           'carrega_TB_PRECOAPARTIRPRODUTO ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_limitevenda(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN

  MERGE INTO MONITORPDVMIDDLE.TB_LIMITEVENDA TB_LIMITEVENDA
    USING (SELECT SEQLIMITEVENDA , DESCRICAO , ATIVO  FROM VW_INT_C5_LIMITEVENDA WHERE ROWNUM = 1 ) T
    ON (TB_LIMITEVENDA.SEQLIMITEVENDA = T.SEQLIMITEVENDA)
  WHEN MATCHED THEN
    UPDATE SET
      TB_LIMITEVENDA.DESCRICAO = T.DESCRICAO,
      TB_LIMITEVENDA.ATIVO = T.ATIVO
	  WHERE NVL(TB_LIMITEVENDA.DESCRICAO, '-') <> NVL(T.DESCRICAO, '-')
       OR NVL(TB_LIMITEVENDA.ATIVO, '-') <> NVL(T.ATIVO, '-')

  WHEN NOT MATCHED THEN
    INSERT(
      TB_LIMITEVENDA.SEQLIMITEVENDA,
      TB_LIMITEVENDA.DESCRICAO,
      TB_LIMITEVENDA.ATIVO
    )
    VALUES(
      T.SEQLIMITEVENDA,
      T.DESCRICAO,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_LIMITEVENDA', 'TB_LIMITEVENDA OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_LIMITEVENDA',
           'carrega_TB_LIMITEVENDA ALERTA',
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
           'carrega_TB_LIMITEVENDA',
           'carrega_TB_LIMITEVENDA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_limitevendaperiodo(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN

  MERGE INTO MONITORPDVMIDDLE.TB_LIMITEVENDAPERIODO TB_LIMITEVENDAPERIODO
    USING (SELECT SEQLIMITEVENDA , DTAHORINICIO , DTAHORFIM ,ATIVO  FROM VW_INT_C5_LIMITEVENDA WHERE ROWNUM = 1) T
    ON (TB_LIMITEVENDAPERIODO.SEQLIMITEVENDA = T.SEQLIMITEVENDA)
  WHEN MATCHED THEN
    UPDATE SET
      TB_LIMITEVENDAPERIODO.DTAHORINICIO = T.DTAHORINICIO, 
      TB_LIMITEVENDAPERIODO.DTAHORFIM = T.DTAHORFIM,
      TB_LIMITEVENDAPERIODO.ATIVO = T.ATIVO
    WHERE NVL(TB_LIMITEVENDAPERIODO.DTAHORINICIO, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(T.DTAHORINICIO, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(TB_LIMITEVENDAPERIODO.DTAHORFIM, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(T.DTAHORFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(TB_LIMITEVENDAPERIODO.ATIVO, '-') <> NVL(T.ATIVO, '-')
	   
  WHEN NOT MATCHED THEN
    INSERT(
      TB_LIMITEVENDAPERIODO.SEQLIMITEVENDA,
      TB_LIMITEVENDAPERIODO.DTAHORINICIO,
      TB_LIMITEVENDAPERIODO.DTAHORFIM,
      TB_LIMITEVENDAPERIODO.ATIVO
    )
    VALUES(
      T.SEQLIMITEVENDA,
      T.DTAHORINICIO,
      T.DTAHORFIM,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_LIMITEVENDAPERIODO', 'TB_LIMITEVENDAPERIODO OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_LIMITEVENDAPERIODO',
           'carrega_TB_LIMITEVENDAPERIODO ALERTA',
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
           'carrega_TB_LIMITEVENDAPERIODO',
           'carrega_TB_LIMITEVENDAPERIODO ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_limitevendaempresa(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN
  
  
  UPDATE MONITORPDVMIDDLE.TB_LIMITEVENDAEMPRESA
  SET ATIVO = 'N'
  WHERE ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_LIMITEVENDAEMPRESA TB_LIMITEVENDAEMPRESA
    USING (SELECT SEQLIMITEVENDA , NROEMPRESA ,ATIVO  FROM VW_INT_C5_LIMITEVENDA) T
    ON (TB_LIMITEVENDAEMPRESA.SEQLIMITEVENDA = T.SEQLIMITEVENDA AND TB_LIMITEVENDAEMPRESA.NROEMPRESA = T.NROEMPRESA)
  WHEN MATCHED THEN
    UPDATE SET 
      TB_LIMITEVENDAEMPRESA.ATIVO = T.ATIVO
    WHERE NVL(TB_LIMITEVENDAEMPRESA.ATIVO, '-') <> NVL(T.ATIVO, '-')
	
  WHEN NOT MATCHED THEN
    INSERT(
      TB_LIMITEVENDAEMPRESA.SEQLIMITEVENDA,
      TB_LIMITEVENDAEMPRESA.NROEMPRESA,
      TB_LIMITEVENDAEMPRESA.ATIVO
    )
    VALUES(
      T.SEQLIMITEVENDA,
      T.NROEMPRESA,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_LIMITEVENDAEMPRESA', 'TB_LIMITEVENDAEMPRESA OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_LIMITEVENDAEMPRESA',
           'carrega_TB_LIMITEVENDAEMPRESA ALERTA',
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
           'carrega_TB_LIMITEVENDAEMPRESA',
           'carrega_TB_LIMITEVENDAEMPRESA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_limitevendafamilia(P_ID IN PCCONTROLECONSINCO.ID%TYPE) AS
BEGIN

 UPDATE MONITORPDVMIDDLE.TB_LIMITEVENDAFAMILIA
  SET ATIVO = 'N'
  WHERE ATIVO = 'S';

  MERGE INTO MONITORPDVMIDDLE.TB_LIMITEVENDAFAMILIA TB_LIMITEVENDAFAMILIA
    USING (SELECT L.SEQFAMILIA,
				   MIN(L.SEQLIMITEVENDA) SEQLIMITEVENDA,
				   (NVL(MIN(L.QTMAXVENDA), 0) * NVL(MIN(L.QTUNIT), 1)) QTDLIMITE, 
				   CASE
					 WHEN (NVL(MIN(L.QTMAXVENDA), 0) * NVL(MIN(L.QTUNIT), 1)) > 0 THEN
					  'S'
					 ELSE
					  'N'
				   END ATIVO
			FROM VW_INT_C5_LIMITEVENDAFAMILIA L
			WHERE L.PRIORIDADE = (SELECT MIN(LI.PRIORIDADE)
								  FROM VW_INT_C5_LIMITEVENDAFAMILIA LI
								  WHERE LI.SEQFAMILIA = L.SEQFAMILIA
								  AND LI.SEQLIMITEVENDA = L.SEQLIMITEVENDA )
						          GROUP BY L.SEQFAMILIA) T
    ON (TB_LIMITEVENDAFAMILIA.SEQLIMITEVENDA = T.SEQLIMITEVENDA AND TB_LIMITEVENDAFAMILIA.SEQFAMILIA = T.SEQFAMILIA)
  WHEN MATCHED THEN
    UPDATE SET
      TB_LIMITEVENDAFAMILIA.QTDLIMITE = T.QTDLIMITE, 
      TB_LIMITEVENDAFAMILIA.ATIVO = T.ATIVO
    WHERE NVL(TB_LIMITEVENDAFAMILIA.QTDLIMITE, 0) <> NVL(T.QTDLIMITE, 0) 
       OR NVL(TB_LIMITEVENDAFAMILIA.ATIVO, '-') <> NVL(T.ATIVO, '-')
	   
  WHEN NOT MATCHED THEN
    INSERT(
      TB_LIMITEVENDAFAMILIA.SEQLIMITEVENDA,
      TB_LIMITEVENDAFAMILIA.SEQFAMILIA,
      TB_LIMITEVENDAFAMILIA.QTDLIMITE,
      TB_LIMITEVENDAFAMILIA.ATIVO
    )
    VALUES(
      T.SEQLIMITEVENDA,
      T.SEQFAMILIA,
      T.QTDLIMITE,
      T.ATIVO
    );
   
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_TB_LIMITEVENDAFAMILIA', 'TB_LIMITEVENDAFAMILIA OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_TB_LIMITEVENDAFAMILIA',
           'carrega_TB_LIMITEVENDAFAMILIA ALERTA',
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
           'carrega_TB_LIMITEVENDAFAMILIA',
           'carrega_TB_LIMITEVENDAFAMILIA ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_clientecredito(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_clientecredito T
    USING (SELECT * FROM VW_INT_C5_LIM_CRED_CLIENTE) S 
    ON    (T.SEQPESSOA = S.SEQPESSOA AND T.NROFORMAPAGTO = S.NROFORMAPAGTO)
  WHEN MATCHED THEN
       UPDATE SET
          T.VLRLIMITE       = S.VLRLIMITE,
          T.VLRUTILIZADO    = S.VLRUTILIZADO,
          T.SITUACAOCREDITO = S.SITUACAOCREDITO,
          T.COBRATAXA       = S.COBRATAXA,
          T.ATIVO           = S.ATIVO,
          T.VLRLIMITEPARCELADO = S.VLRLIMITEPARCELADO
       WHERE NVL(T.VLRLIMITE, 0)          <> NVL(S.VLRLIMITE, 0) 
       OR    NVL(T.VLRUTILIZADO, 0)       <> NVL(S.VLRUTILIZADO , 0) 
       OR    NVL(T.SITUACAOCREDITO, '-')  <> NVL(S.SITUACAOCREDITO, '-')
       OR    NVL(T.COBRATAXA, '-')        <> NVL(S.COBRATAXA, '-')
       OR    NVL(T.ATIVO, '-')            <> NVL(S.ATIVO, '-')
       OR    NVL(T.VLRLIMITEPARCELADO, 0) <> NVL(S.VLRLIMITEPARCELADO, 0)
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.SEQPESSOA,
          T.NROFORMAPAGTO,
          T.VLRLIMITE,
          T.VLRUTILIZADO,
          T.SITUACAOCREDITO,
          T.COBRATAXA,
          T.ATIVO,
          T.VLRLIMITEPARCELADO
          ) 
        VALUES(
          S.SEQPESSOA,
          S.NROFORMAPAGTO,
          S.VLRLIMITE,
          S.VLRUTILIZADO,
          S.SITUACAOCREDITO,
          S.COBRATAXA,
          S.ATIVO,
          S.VLRLIMITEPARCELADO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_clientecredito', 'carrega_tb_clientecredito OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_clientecredito',
           'carrega_tb_clientecredito ALERTA',
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
           'carrega_tb_clientecredito',
           'carrega_tb_clientecredito ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_clientecartao(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  /*UPDATE MONITORPDVMIDDLE.tb_clientecartao SET ATIVO = 'N'
  WHERE ATIVO = 'S';*/
  
  MERGE INTO monitorpdvmiddle.tb_clientecartao T
    USING (SELECT * FROM VW_INT_C5_CLI_CONV) S 
    ON    (T.NROCARTAO = S.NROCARTAO AND T.NROFORMAPAGTO = S.NROFORMAPAGTO)
  WHEN MATCHED THEN
       UPDATE SET
          T.SEQPESSOAPORTADOR = S.SEQPESSOAPORTADOR,
          T.SEQPESSOATITULAR  = S.SEQPESSOATITULAR,
          T.DTAVALIDADE       = S.DTAVALIDADE,
          T.ATIVO             = S.ATIVO
       WHERE NVL(T.SEQPESSOAPORTADOR, 0) <> NVL(S.SEQPESSOAPORTADOR, 0) 
       OR    NVL(T.SEQPESSOATITULAR, 0)  <> NVL(S.SEQPESSOATITULAR, 0)  
       OR    NVL(T.DTAVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR    NVL(T.ATIVO, '-')           <> NVL(S.ATIVO, '-')
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.NROCARTAO,
          T.NROFORMAPAGTO,
          T.SEQPESSOAPORTADOR,
          T.SEQPESSOATITULAR,
          T.DTAVALIDADE,
          T.ATIVO
          ) 
        VALUES(
          S.NROCARTAO,
          S.NROFORMAPAGTO,
          S.SEQPESSOAPORTADOR,
          S.SEQPESSOATITULAR,
          S.DTAVALIDADE,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_clientecartao', 'carrega_tb_clientecartao OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_clientecartao',
           'carrega_tb_clientecartao ALERTA',
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
           'carrega_tb_clientecartao',
           'carrega_tb_clientecartao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_convenioperiodo(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  UPDATE monitorpdvmiddle.tb_convenioperiodo S SET S.ATIVO = 'N'
  WHERE S.ATIVO = 'S';
    
  MERGE INTO monitorpdvmiddle.tb_convenioperiodo T
    USING (SELECT * FROM VW_INT_C5_CLI_CONV_PERIODO) S 
    ON    (T.NROFORMAPAGTO = S.NROFORMAPAGTO AND T.SEQPERIODO = S.SEQPERIODO)
  WHEN MATCHED THEN
       UPDATE SET
          T.DTAINICIO  = S.DTAINICIO,
          T.DTAFIM     = S.DTAFIM,
          T.DTAVENCTO  = S.DTAVENCTO,
          T.ATIVO      = S.ATIVO
       WHERE NVL(T.DTAINICIO, TO_DATE('01-01-1994','DD-MM-YYYY'))  <> NVL(S.DTAINICIO, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR    NVL(T.DTAFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))     <> NVL(S.DTAFIM, TO_DATE('01-01-1994','DD-MM-YYYY'))  
       OR    NVL(T.DTAVENCTO, TO_DATE('01-01-1994','DD-MM-YYYY'))  <> NVL(S.DTAVENCTO, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR    NVL(T.ATIVO, '-') <> NVL(S.ATIVO, '-')
          
  WHEN NOT MATCHED THEN
        INSERT(
          T.NROFORMAPAGTO,
          T.SEQPERIODO,
          T.DTAINICIO,
          T.DTAFIM,
          T.DTAVENCTO,
          T.ATIVO
          ) 
        VALUES(
          S.NROFORMAPAGTO,
          S.SEQPERIODO,
          S.DTAINICIO,
          S.DTAFIM,
          S.DTAVENCTO,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_convenioperiodo', 'carrega_tb_convenioperiodo OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_convenioperiodo',
           'carrega_tb_convenioperiodo ALERTA',
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
           'carrega_tb_convenioperiodo',
           'carrega_tb_convenioperiodo ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;


PROCEDURE carrega_tb_bincartao(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
	/* INVATIVANDO REGISTRO SEM VINCULO*/
	UPDATE monitorpdvmiddle.tb_bincartao SET ATIVO = 'N'  
	WHERE ATIVO = 'S';    
	
    MERGE INTO monitorpdvmiddle.tb_bincartao s
        USING (SELECT *
               FROM VW_INT_C5_BINCARTAO c
               ) b

		ON (s.seqbincartao = b.seqbincartao)
		WHEN MATCHED THEN
		UPDATE SET
               s.nrobininicial	= b.nrobininicial,
               s.nrobinfinal    = b.nrobinfinal,
               s.codrede   		= b.codrede,
               s.codbandeira    = b.codbandeira,
               s.tipo  			= b.tipo,
               s.ativo    		= b.ativo
		WHEN NOT MATCHED THEN
		INSERT (s.seqbincartao,
                s.nrobininicial,
				s.nrobinfinal,
                s.codrede,
                s.codbandeira,
                s.tipo,
                s.ativo)
                VALUES
                  (b.seqbincartao,
                   b.nrobininicial,
                   b.nrobinfinal,
                   b.codrede,
                   b.codbandeira,
                   b.tipo,
                   b.ativo);
    
    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_bincartao',
       'carrega_tb_bincartao OK',
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
           'carrega_tb_bincartao',
           'carrega_tb_bincartao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
END;
  

PROCEDURE carrega_tb_formapagtobincartao(p_id IN pccontroleconsinco.id%TYPE) as
BEGIN
	UPDATE monitorpdvmiddle.tb_formapagtobincartao b SET b.ATIVO = 'N'  
	WHERE exists (select 1 
	                from pcfinalizadora f 
				   where f.codfinalizadora = b.NROFORMAPAGTO 
				     and (f.numbincartao is null OR f.dtinativacao is not null));
	
	MERGE INTO monitorpdvmiddle.tb_formapagtobincartao s
		USING (SELECT V.NROFORMAPAGTO, 
                      V.NROBINCARTAOTEF,
                      V.ATIVO
               FROM VW_INT_C5_FORMAPAGTOBINCARTAO V,
			        MONITORPDVMIDDLE.TB_FORMAPAGTO F
			   WHERE F.NROFORMAPAGTO = V.NROFORMAPAGTO
               ) b
	ON (s.NROFORMAPAGTO = b.NROFORMAPAGTO)
	WHEN MATCHED THEN
	UPDATE SET		   
		   s.NROBINCARTAOTEF = b.NROBINCARTAOTEF,
		   s.ativo    	  = b.ativo  			   
    WHEN NOT MATCHED THEN
		INSERT (s.NROFORMAPAGTO,
				s.NROBINCARTAOTEF,
				s.ativo)
        VALUES
			  (b.NROFORMAPAGTO,
			   b.NROBINCARTAOTEF,
			   b.ativo);

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
       'carrega_tb_formapagtobincartao',
       'carrega_tb_formapagtobincartao OK',
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
           'carrega_tb_formapagtobincartao',
           'carrega_tb_formapagtobincartao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
END;

PROCEDURE carrega_tb_regraformapagto(p_id IN pccontroleconsinco.id%TYPE) as
begin
    MERGE INTO MONITORPDVMIDDLE.TB_REGRAFORMAPAGTO T
    USING (SELECT * FROM VW_INT_C5_PRIVATELABEL) S
    ON (S.SEQREGRA = T.SEQREGRA AND S.NROFORMAPAGTO = T.NROFORMAPAGTO)
    WHEN MATCHED THEN 
      UPDATE SET  
        T.ATIVO = S.ATIVO,
        T.PERCDESCONTO = S.PERCDESCONTO
    WHEN NOT MATCHED THEN 
      INSERT (
        T.SEQREGRA,
        T.NROFORMAPAGTO,
        T.ATIVO,
        T.PERCDESCONTO
      )
      VALUES (
        S.SEQREGRA,
        S.NROFORMAPAGTO,
        S.ATIVO,
        S.PERCDESCONTO
      );

    INSERT INTO PCDEVLOGCONSINCO
      (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
    VALUES
      ('pkg_sinc_PDV_Consinco',
      'CARREGA_TB_REGRAFORMAPAGTO',
      'CARREGA_TB_REGRAFORMAPAGTO OK',
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
           'CARREGA_TB_REGRAFORMAPAGTO',
           'CARREGA_TB_REGRAFORMAPAGTO ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
      END;
end;

PROCEDURE carrega_tb_cartaopresente(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cartaopresente T
    USING (SELECT * FROM VW_INT_C5_CARTAOPRESENTE) S 
    ON    (T.NROCARTAO = S.NROCARTAO)
  WHEN MATCHED THEN
       UPDATE SET
          T.VALOR  = S.VALOR,
          T.STATUS = S.STATUS,
          T.ATIVO  = S.ATIVO
       WHERE T.VALOR  <> S.VALOR 
       OR    T.STATUS <> S.STATUS
       OR    T.ATIVO  <> S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
		  T.NROCARTAO,
          T.VALOR,
          T.STATUS,
          T.ATIVO
          ) 
        VALUES(
          S.NROCARTAO,
          S.VALOR,
          S.STATUS,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cartaopresente', 'carrega_tb_cartaopresente OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cartaopresente',
           'carrega_tb_cartaopresente ALERTA',
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
           'carrega_tb_cartaopresente',
           'carrega_tb_cartaopresente ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_local(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_local T
    USING (SELECT DISTINCT NROEMPRESA, SEQLOCAL, LOCAL_RAZAO, TIPO, ATIVO_FILIAL ATIVO 
           FROM VW_INT_C5_PRODLOTE
          ) S 
    ON    (T.NROEMPRESA = S.NROEMPRESA AND T.SEQLOCAL = S.SEQLOCAL)
  WHEN MATCHED THEN
       UPDATE SET
             T.LOCAL  = S.LOCAL_RAZAO,
             T.TIPO   = S.TIPO,
             T.ATIVO  = S.ATIVO
       WHERE T.LOCAL  <> S.LOCAL_RAZAO 
       OR    T.TIPO   <> S.TIPO
       OR    T.ATIVO  <> S.ATIVO
          
  WHEN NOT MATCHED THEN
        INSERT(
		      T.NROEMPRESA,
          T.SEQLOCAL,
          T.LOCAL,
          T.TIPO,
          T.ATIVO
          ) 
        VALUES(
          S.NROEMPRESA,
          S.SEQLOCAL,
          S.LOCAL_RAZAO,
          S.TIPO,
          S.ATIVO);
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_local', 'carrega_tb_local OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_local',
           'carrega_tb_local ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_loteestoque(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_loteestoque T
    USING (SELECT NROEMPRESA, 
                  SEQLOTEESTOQUE, 
                  SEQLOCAL, 
                  SEQPRODUTO, 
                  ESTQLOTE, 
                  NROLOTEESTOQUE, 
                  DTAFABRICACAO, 
                  DTAVALIDADE, 
                  DTAENTRADA, 
                  ATIVO_LOTE ATIVO,
                  IDREF  
           FROM VW_INT_C5_PRODLOTE
           WHERE SEQLOTEESTOQUE IS NOT NULL /*registros com seqloteestoque "null" indica que a tabela DEPARA não foi preenchida*/
          ) S 
    ON    (T.NROEMPRESA = S.NROEMPRESA AND T.NROLOTEESTOQUE = S.NROLOTEESTOQUE AND T.SEQPRODUTO = S.SEQPRODUTO)
  WHEN MATCHED THEN
       UPDATE SET
             T.SEQLOCAL  = S.SEQLOCAL,
             T.SEQLOTEESTOQUE  = S.SEQLOTEESTOQUE,
             T.DTAFABRICACAO  = S.DTAFABRICACAO,
             T.DTAVALIDADE  = S.DTAVALIDADE,
             T.DTAENTRADA  = S.DTAENTRADA,
             T.ESTQLOTE  = S.ESTQLOTE,
             T.ATIVO  = S.ATIVO
       WHERE T.SEQLOCAL  <> S.SEQLOCAL 
       OR    T.SEQLOTEESTOQUE  <> S.SEQLOTEESTOQUE
       OR    T.DTAFABRICACAO  <> S.DTAFABRICACAO
       OR    T.DTAVALIDADE  <> S.DTAVALIDADE
       OR    T.DTAENTRADA  <> S.DTAENTRADA
       OR    T.ESTQLOTE  <> S.ESTQLOTE
       OR    T.ATIVO  <> S.ATIVO
       OR    T.IDREF  <> S.IDREF
          
  WHEN NOT MATCHED THEN
        INSERT(
		      T.NROEMPRESA,
          T.SEQLOTEESTOQUE,
          T.SEQLOCAL,
          T.SEQPRODUTO,
          T.NROLOTEESTOQUE,
          T.DTAFABRICACAO,
          T.DTAVALIDADE,
          T.DTAENTRADA,
          T.ESTQLOTE,
          T.ATIVO,
          T.IDREF
          ) 
        VALUES(
          S.NROEMPRESA,
          (PKG_SINC_PDV_CONSINCO.obter_seqloteestoque), 
          S.SEQLOCAL,
          S.SEQPRODUTO,
          S.NROLOTEESTOQUE,
          S.DTAFABRICACAO,
          S.DTAVALIDADE,
          S.DTAENTRADA,
          S.ESTQLOTE,
          S.ATIVO,
          S.IDREF);

  UPDATE MONITORPDVMIDDLE.tb_loteestoque E
       SET ATIVO = 'N'
  WHERE NOT EXISTS(SELECT 1
                   FROM PCLOTE L, VW_INT_C5_OBTER_FILIAIS_C5 C5
                   WHERE L.CODFILIAL = C5.CODFILIAL
                   AND   C5.CODFILIALINTEGRACAO = E.NROEMPRESA
                   AND   L.NUMLOTE = E.NROLOTEESTOQUE
                   AND   L.CODPROD = E.IDREF
                   );        
    
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_estoquelote', 'carrega_tb_estoquelote OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_estoquelote',
           'carrega_tb_estoquelote ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcenario(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcenario T
    USING (SELECT
             SEQCENARIO,
             DESCRICAO,
             ORIENTACAO,
             DTAINICIALVALIDADE,
             DTAFINALVALIDADE,
             TOTALPONTOS,
             ATIVO,
             SEQIMPOSTO,
             IDREF
           FROM VW_INT_C5_CCTCENARIO) S
    ON (T.SEQCENARIO = S.SEQCENARIO)
  WHEN MATCHED THEN
    UPDATE SET 
      T.DESCRICAO = S.DESCRICAO,
      T.ORIENTACAO = S.ORIENTACAO,
      T.DTAINICIALVALIDADE = S.DTAINICIALVALIDADE,
      T.DTAFINALVALIDADE = S.DTAFINALVALIDADE,
      T.PONTOSBUSCA = S.TOTALPONTOS,
      T.ATIVO = S.ATIVO,
      T.IDREF = S.IDREF
    WHERE NVL(T.DESCRICAO, '-') <> NVL(S.DESCRICAO, '-')
     OR NVL(T.ORIENTACAO, '-') <> NVL(S.ORIENTACAO, '-')
     OR NVL(T.DTAINICIALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAINICIALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
     OR NVL(T.DTAFINALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAFINALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
     OR NVL(T.PONTOSBUSCA, -1) <> NVL(S.TOTALPONTOS, -1)
     OR NVL(T.ATIVO, '-') <> NVL(S.ATIVO, '-')
     OR NVL(T.IDREF, -1) <> NVL(S.IDREF, -1)
    WHEN NOT MATCHED THEN
        INSERT(
          T.SEQCENARIO,
          T.DESCRICAO,
          T.ORIENTACAO,
          T.DTAINICIALVALIDADE,
          T.DTAFINALVALIDADE,
          T.PONTOSBUSCA,
          T.ATIVO,
          T.SEQIMPOSTO,
          T.IDREF) 
        VALUES(
          S.SEQCENARIO,
          S.DESCRICAO,
          S.ORIENTACAO,
          S.DTAINICIALVALIDADE,
          S.DTAFINALVALIDADE,
          S.TOTALPONTOS,
          S.ATIVO,
          S.SEQIMPOSTO,
          S.IDREF);

  UPDATE MONITORPDVMIDDLE.TB_CCTCENARIO CCT
     SET CCT.ATIVO = 'N'
  WHERE CCT.ATIVO = 'S'
    AND (SYSDATE > CCT.DTAFINALVALIDADE);

  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcenario', 'carrega_tb_cctcenario OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctcenario',
           'carrega_tb_cctcenario ALERTA',
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
           'carrega_tb_cctcenario',
           'carrega_tb_cctcenario ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcondicao(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcondicao t
  USING (
    SELECT 
      d.SEQCONDICAO, 
      d.IDENTIFICADOR, 
      d.PESOBUSCA, 
      d.ATIVO
    FROM VW_INT_C5_CCTCONDICAO d
  ) s
  ON (t.SEQCONDICAO = s.SEQCONDICAO)
  WHEN MATCHED THEN
    UPDATE SET 
      t.IDENTIFICADOR = s.IDENTIFICADOR,
      t.PESOBUSCA = s.PESOBUSCA,
      t.ATIVO = s.ATIVO
  WHEN NOT MATCHED THEN
    INSERT (SEQCONDICAO, IDENTIFICADOR, PESOBUSCA, ATIVO)
    VALUES (s.SEQCONDICAO, s.IDENTIFICADOR, s.PESOBUSCA, s.ATIVO );
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcondicao', 'carrega_tb_cctcondicao OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctcondicao',
           'carrega_tb_cctcondicao ALERTA',
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
           'carrega_tb_cctcondicao',
           'carrega_tb_cctcondicao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcenariocondicao(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcenariocondicao CC 
  USING (
    SELECT
      SEQCENARIO,
      SEQCONDICAO,
      PONTOSBUSCA,
      ATIVO
    FROM VW_INT_C5_CCTCENARIOCONDICAO
  ) S
  ON (CC.SEQCENARIO = S.SEQCENARIO AND CC.SEQCONDICAO = S.SEQCONDICAO)
  WHEN MATCHED THEN
    UPDATE 
    SET CC.ATIVO = S.ATIVO,
        CC.PONTOSBUSCA = S.PONTOSBUSCA
    WHERE NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
       OR NVL(CC.PONTOSBUSCA, -1) <> NVL(S.PONTOSBUSCA, -1)  
  WHEN NOT MATCHED THEN
    INSERT 
    ( SEQCENARIOCONDICAO,
      SEQCENARIO,
      SEQCONDICAO,
      PONTOSBUSCA,
      ATIVO
    )
    VALUES
    ( (PKG_SINC_PDV_CONSINCO.obter_seqcenariocondicao),
       S.SEQCENARIO,
       S.SEQCONDICAO,
       S.PONTOSBUSCA,
       S.ATIVO
    );

  UPDATE MONITORPDVMIDDLE.TB_CCTCENARIO C
  SET PONTOSBUSCA = (SELECT NVL(SUM(PONTOSBUSCA), 101) FROM MONITORPDVMIDDLE.tb_cctcenariocondicao CC WHERE CC.SEQCENARIO = C.SEQCENARIO AND CC.SEQCONDICAO IN (1, 3, 8) AND CC.PONTOSBUSCA <> 1);

  INSERT INTO PCDEVLOGCONSINCO (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcenariocondicao', 'carrega_tb_cctcenariocondicao OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctcenariocondicao',
           'carrega_tb_cctcenariocondicao ALERTA',
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
           'carrega_tb_cctcenariocondicao',
           'carrega_tb_cctcenariocondicao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcenconditem(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcenariocondicaoitem CC 
  USING (
    SELECT
      SEQCENARIOCONDICAOITEM,
      SEQCENARIOCONDICAO,
      VALOR,
      INDTIPOIDENTIDADE,
      IDENTIFICADOR,
      SEQCENARIO,
      ATIVO,
      IDREF
    FROM VW_INT_C5_CCTCENCONDITEM
  ) S
  ON (CC.SEQCENARIOCONDICAOITEM = S.SEQCENARIOCONDICAOITEM)
  WHEN MATCHED THEN
    UPDATE
    SET CC.IDENTIFICADOR = S.IDENTIFICADOR,
        CC.ATIVO = S.ATIVO
    WHERE NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
       OR NVL(CC.IDENTIFICADOR, '-') <> NVL(S.IDENTIFICADOR, '-')
  WHEN NOT MATCHED THEN
    INSERT
    ( SEQCENARIOCONDICAOITEM,
      SEQCENARIOCONDICAO,
      VALOR,
      INDTIPOENTIDADE,
      IDENTIFICADOR,
      SEQCENARIO,
      ATIVO,
      IDREF
    )
    VALUES
    ( (PKG_SINC_PDV_CONSINCO.obter_seqcenariocondicaoitem),
      S.SEQCENARIOCONDICAO,
      S.VALOR,
      S.INDTIPOIDENTIDADE,
      S.IDENTIFICADOR,
      S.SEQCENARIO,
      S.ATIVO,
      S.IDREF
    );

  UPDATE MONITORPDVMIDDLE.TB_CCTCENARIOCONDICAOITEM CCT
  SET CCT.ATIVO = 'N'
  WHERE CCT.ATIVO = 'S'
    AND (( CCT.IDENTIFICADOR = 'PRODUTO'
            AND (
                  EXISTS (
                  SELECT 1
                      FROM PCDEPARAPRODC5 DEPARA
                    WHERE TO_CHAR(DEPARA.SEQPRODUTO) = CCT.VALOR
                      AND DEPARA.ATIVO = 'N'
                  )
                  OR
                  NOT EXISTS (
                    SELECT 1
                    FROM PCTRIBUTACAO_FILTRO_PRODUTO T,
	                     PCDEPARAPRODC5 DEPARA
                    WHERE T.CODIGO_TRIBUTACAO = CCT.IDREF
                      AND T.CODPROD = DEPARA.CODPROD 
                      AND DEPARA.SEQPRODUTO  = CCT.VALOR
                      AND T.DTEXCLUSAO IS NULL
                  )
          ))
          OR
          ( CCT.IDENTIFICADOR = 'UFORIGEM'
            AND EXISTS (
                  SELECT 1
                    FROM PCTRIBUTACAO TRIB
                    WHERE TRIB.CODIGO_TRIBUTACAO = CCT.IDREF
                      AND TRIB.DTINATIVACAO IS NULL
                      AND (CASE
                            WHEN TRIB.TIPO_LOCAL_CONSUMO = 'G'
                              THEN TO_CHAR(NVL(TRIB.LOCAL_CONSUMO_GERAL, 'BR'))
                            ELSE TO_CHAR(TRIB.LOCAL_CONSUMO_MUNICIPIO)
                          END) <> CCT.VALOR
          ))
          OR ( CCT.IDENTIFICADOR = 'NCM'
                AND NOT EXISTS (
                  SELECT 1
                    FROM PCTRIBUTACAO_FILTRO_NCM T
                    WHERE T.CODIGO_TRIBUTACAO = CCT.IDREF
                      AND T.NCM = CCT.VALOR
                      AND T.DTEXCLUSAO IS NULL
                )
        ));

  UPDATE MONITORPDVMIDDLE.TB_CCTCENARIOCONDICAOITEM CCT
  SET CCT.ATIVO = 'S'
  WHERE CCT.ATIVO = 'N'
    AND CCT.VALOR = '0'
    AND EXISTS (SELECT 1 FROM PCTRIBUTACAO T WHERE T.CODIGO_TRIBUTACAO = CCT.IDREF AND T.DTEXCLUSAO IS NULL)    
    AND (( CCT.IDENTIFICADOR = 'PRODUTO'
            AND (
                  NOT EXISTS (
                    SELECT 1
                    FROM PCTRIBUTACAO_FILTRO_PRODUTO T
                    WHERE T.CODIGO_TRIBUTACAO = CCT.IDREF
                      AND T.DTEXCLUSAO IS NULL
                  )
          ))
          OR ( CCT.IDENTIFICADOR = 'NCM'
                AND NOT EXISTS (
                  SELECT 1
                    FROM PCTRIBUTACAO_FILTRO_NCM T
                    WHERE T.CODIGO_TRIBUTACAO = CCT.IDREF
                      AND T.DTEXCLUSAO IS NULL
                )
        )
  		);

  INSERT INTO PCDEVLOGCONSINCO (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcenconditem', 'carrega_tb_cctcenconditem OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctcenconditem',
           'carrega_tb_cctcenconditem ALERTA',
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
           'carrega_tb_cctcenconditem',
           'carrega_tb_cctcenconditem ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctimposto(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctimposto CC
  USING (
    SELECT 
      SEQIMPOSTO, 
      DESCRICAO, 
      ATIVO
    FROM VW_INT_C5_CCTIMPOSTO 
  ) S
  ON (CC.SEQIMPOSTO = S.SEQIMPOSTO)
  WHEN MATCHED THEN
    UPDATE SET 
      CC.DESCRICAO = S.DESCRICAO,
      CC.ATIVO = S.ATIVO
    WHERE NVL(CC.DESCRICAO, '-') <> NVL(S.DESCRICAO, '-')
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT (SEQIMPOSTO, DESCRICAO, ATIVO)
    VALUES (S.SEQIMPOSTO, S.DESCRICAO, S.ATIVO);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctimposto', 'carrega_tb_cctimposto OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctimposto',
           'carrega_tb_cctimposto ALERTA',
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
           'carrega_tb_cctimposto',
           'carrega_tb_cctimposto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctformula(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctformula CC
  USING (
    SELECT 
      SEQFORMULA, 
      DESCRICAO,
      BASE, 
      ALIQUOTA,
      INDTIPOFORMULA,
      ATIVO
    FROM VW_INT_C5_CCTFORMULA 
  ) S
  ON (CC.SEQFORMULA = S.SEQFORMULA)
  WHEN MATCHED THEN
    UPDATE SET 
      CC.DESCRICAO = S.DESCRICAO,
      CC.BASE = S.BASE,
      CC.ALIQUOTA = S.ALIQUOTA,
      CC.INDTIPOFORMULA = S.INDTIPOFORMULA,
      CC.ATIVO = S.ATIVO
    WHERE NVL(CC.DESCRICAO, '-') <> NVL(S.DESCRICAO, '-')
       OR NVL(CC.BASE, '-') <> NVL(S.BASE, '-')
       OR NVL(CC.ALIQUOTA, '-') <> NVL(S.ALIQUOTA, '-')
       OR NVL(CC.INDTIPOFORMULA, '-') <> NVL(S.INDTIPOFORMULA, '-')
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT (SEQFORMULA, DESCRICAO, BASE, ALIQUOTA, INDTIPOFORMULA, ATIVO)
    VALUES (S.SEQFORMULA, S.DESCRICAO, S.BASE, S.ALIQUOTA, S.INDTIPOFORMULA, S.ATIVO);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctformula', 'carrega_tb_cctformula OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctformula',
           'carrega_tb_cctformula ALERTA',
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
           'carrega_tb_cctformula',
           'carrega_tb_cctformula ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcodigotributario(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcodigotributario CC 
  USING (
    SELECT
      SEQCODIGOTRIBUTARIO,
      CODIGO,
      DESCRICAO,
      INDTIPOCODIGO,
      CODIGOPAI,
      DTAINICIALVALIDADE,
      DTAFINALVALIDADE,
      PERALIQREDCBS,
      PERALIQREDIBS,
      ATIVO,
      IDREF
    FROM VW_INT_C5_CCTCODIGOTRIBUTARIO
  ) S
  ON (CC.IDREF = S.IDREF AND CC.CODIGO = S.CODIGO)
  WHEN MATCHED THEN
    UPDATE
    SET CC.DESCRICAO = S.DESCRICAO,
        CC.ATIVO = S.ATIVO,
        CC.INDTIPOCODIGO = S.INDTIPOCODIGO,
        CC.CODIGOPAI = S.CODIGOPAI,
        CC.DTAINICIALVALIDADE = S.DTAINICIALVALIDADE,
        CC.DTAFINALVALIDADE = S.DTAFINALVALIDADE,
        CC.PERALIQREDCBS = S.PERALIQREDCBS,
        CC.PERALIQREDIBS = S.PERALIQREDIBS
    WHERE NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
       OR NVL(CC.DESCRICAO, '-') <> NVL(S.DESCRICAO, '-')
       OR NVL(CC.INDTIPOCODIGO, -1) <> NVL(S.INDTIPOCODIGO, -1)
       OR NVL(CC.CODIGOPAI, '-') <> NVL(S.CODIGOPAI, '-')
       OR NVL(CC.DTAINICIALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAINICIALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(CC.DTAFINALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAFINALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(CC.PERALIQREDCBS, -1) <> NVL(S.PERALIQREDCBS, -1)
       OR NVL(CC.PERALIQREDIBS, -1) <> NVL(S.PERALIQREDIBS, -1)

  WHEN NOT MATCHED THEN
    INSERT
    ( SEQCODIGOTRIBUTARIO,
      CODIGO,
      DESCRICAO,
      INDTIPOCODIGO,
      CODIGOPAI,
      DTAINICIALVALIDADE,
      DTAFINALVALIDADE,
      PERALIQREDCBS,
      PERALIQREDIBS,
      ATIVO,
      IDREF
    )
    VALUES
    ( (PKG_SINC_PDV_CONSINCO.obter_seqcodigotributacao),
      S.CODIGO,
      S.DESCRICAO,
      S.INDTIPOCODIGO,
      S.CODIGOPAI,
      S.DTAINICIALVALIDADE,
      S.DTAFINALVALIDADE,
      S.PERALIQREDCBS,
      S.PERALIQREDIBS,
      S.ATIVO,
      S.IDREF
    );

  UPDATE MONITORPDVMIDDLE.TB_CCTCODIGOTRIBUTARIO CCT
  SET CCT.ATIVO = 'N'
  WHERE NOT EXISTS (
    SELECT 1 FROM PCTRIBUTACAO T WHERE T.CODIGO_TRIBUTACAO = CCT.IDREF AND ((CCT.CODIGO = T.CST) OR (CCT.CODIGO = T.CCLASSTRIB))
  )
    AND CCT.ATIVO = 'S'; 

  INSERT INTO PCDEVLOGCONSINCO (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcodigotributario', 'carrega_tb_cctcodigotributario OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctcodigotributario',
           'carrega_tb_cctcodigotributario ALERTA',
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
           'carrega_tb_cctcodigotributario',
           'carrega_tb_cctcodigotributario ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcenarioimposto(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcenarioimposto CC 
  USING (SELECT * FROM VW_INT_C5_CCTCENARIOIMPOSTO) S
  ON (    CC.SEQCENARIO = S.SEQCENARIO
      AND CC.SEQIMPOSTO = S.SEQIMPOSTO
  )
  WHEN MATCHED THEN
    UPDATE
    SET CC.SEQCODTRIBCST    = S.SEQCODTRIBCST,
        CC.SEQCODTRIBCCLASTRIB = S.SEQCODTRIBCCLASTRIB,
        CC.PERALIQ = S.PERALIQ,
        CC.PERALIQRED = S.PERALIQRED,
        CC.PERALIQMUN = S.PERALIQMUN,
        CC.SEQFORMULA = S.SEQFORMULA,
        CC.ATIVO = S.ATIVO,
        CC.IDREF = S.IDREF,
		CC.CODIGOCST = S.CODIGOCST,
		CC.CODIGOCCLASSTRIB = S.CODIGOCCLASSTRIB
    WHERE NVL(CC.SEQCODTRIBCST, -1) <> NVL(S.SEQCODTRIBCST, -1)
       OR NVL(CC.SEQCODTRIBCCLASTRIB, -1) <> NVL(S.SEQCODTRIBCCLASTRIB, -1)
       OR NVL(CC.PERALIQ, -1) <> NVL(S.PERALIQ, -1)
       OR NVL(CC.PERALIQRED, -1) <> NVL(S.PERALIQRED, -1)
       OR NVL(CC.PERALIQMUN, -1) <> NVL(S.PERALIQMUN, -1)
       OR NVL(CC.SEQFORMULA, -1) <> NVL(S.SEQFORMULA, 1)
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
       OR NVL(CC.IDREF, '-') <> NVL(S.IDREF, '-')
	   OR NVL(CC.CODIGOCST, '-') <> NVL(S.CODIGOCST, '-')
	   OR NVL(CC.CODIGOCCLASSTRIB, '-') <> NVL(S.CODIGOCCLASSTRIB, '-')

  WHEN NOT MATCHED THEN
    INSERT
    ( CC.SEQCENARIOIMPOSTO,
      CC.SEQCENARIO,
      CC.SEQIMPOSTO,
      CC.SEQCODTRIBCST,
      CC.SEQCODTRIBCCLASTRIB,
      CC.PERALIQ,
      CC.PERALIQRED,
      CC.PERALIQMUN,
      CC.SEQFORMULA,
      CC.ATIVO,
      CC.IDREF,
	  CC.CODIGOCST,
	  CC.CODIGOCCLASSTRIB
    )
    VALUES
    ( (PKG_SINC_PDV_CONSINCO.obter_seqcenarioimposto),
      S.SEQCENARIO,
      S.SEQIMPOSTO,
      S.SEQCODTRIBCST,
      S.SEQCODTRIBCCLASTRIB,
      S.PERALIQ,
      S.PERALIQRED,
      S.PERALIQMUN,
      S.SEQFORMULA,
      S.ATIVO,
      S.IDREF,
	  S.CODIGOCST,
	  S.CODIGOCCLASSTRIB
    );

  INSERT INTO PCDEVLOGCONSINCO (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcenarioimposto', 'carrega_tb_cctcenarioimposto OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctcenarioimposto',
           'carrega_tb_cctcenarioimposto ALERTA',
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
           'carrega_tb_cctcenarioimposto',
           'carrega_tb_cctcenarioimposto ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctconfiguracao(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctconfiguracao CC
  USING (
    SELECT 
      SEQCONFIGURACAO, 
      INDTIPOAMBIENTE,
      ATIVO
    FROM VW_INT_C5_CCTCONFIGURACAO
  ) S
  ON (CC.SEQCONFIGURACAO = S.SEQCONFIGURACAO)
  WHEN MATCHED THEN
    UPDATE SET 
      CC.INDTIPOAMBIENTE = S.INDTIPOAMBIENTE,
      CC.ATIVO = S.ATIVO
    WHERE NVL(CC.INDTIPOAMBIENTE, '-') <> NVL(S.INDTIPOAMBIENTE, '-')
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT (SEQCONFIGURACAO, INDTIPOAMBIENTE, ATIVO)
    VALUES (S.SEQCONFIGURACAO, S.INDTIPOAMBIENTE, S.ATIVO);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctconfiguracao', 'carrega_tb_cctconfiguracao OK', SYSDATE, CURRENT_TIMESTAMP);

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
           'carrega_tb_cctconfiguracao',
           'carrega_tb_cctconfiguracao ALERTA',
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
           'carrega_tb_cctconfiguracao',
           'carrega_tb_cctconfiguracao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctaliquota(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctaliquota CC
  USING (
    SELECT 
      SEQIMPOSTO,
      DTAINICIALVALIDADE,
      DTAFINALVALIDADE,
      PERALIQ,
      UF,
      CODIBGE,
      ATIVO,
      IDREF
    FROM VW_INT_C5_CCTALIQUOTA
  ) S
  ON (CC.SEQIMPOSTO = S.SEQIMPOSTO AND CC.IDREF = S.IDREF)
  WHEN MATCHED THEN
    UPDATE SET 
      CC.DTAINICIALVALIDADE = S.DTAINICIALVALIDADE,
      CC.DTAFINALVALIDADE = S.DTAFINALVALIDADE,
      CC.PERALIQ = S.PERALIQ,
      CC.UF = S.UF,
      CC.CODIBGE = S.CODIBGE,
      CC.ATIVO = S.ATIVO
    WHERE NVL(CC.DTAINICIALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAINICIALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(CC.DTAFINALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY')) <> NVL(S.DTAFINALVALIDADE, TO_DATE('01-01-1994','DD-MM-YYYY'))
       OR NVL(CC.PERALIQ, -1) <> NVL(S.PERALIQ, -1)
       OR NVL(CC.UF, '-') <> NVL(S.UF, '-')
       OR NVL(CC.CODIBGE, -1) <> NVL(S.CODIBGE, -1)
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT (SEQALIQUOTA, SEQIMPOSTO, DTAINICIALVALIDADE, DTAFINALVALIDADE, PERALIQ, UF, CODIBGE, ATIVO, IDREF)
    VALUES ((PKG_SINC_PDV_CONSINCO.obter_seqaliquota), S.SEQIMPOSTO, S.DTAINICIALVALIDADE, S.DTAFINALVALIDADE, S.PERALIQ, S.UF, S.CODIBGE, S.ATIVO, S.IDREF);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctaliquota', 'carrega_tb_cctaliquota OK', SYSDATE, CURRENT_TIMESTAMP);
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
           'carrega_tb_cctaliquota',
           'carrega_tb_cctaliquota ALERTA',
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
           'carrega_tb_cctaliquota',
           'carrega_tb_cctaliquota ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_regiao(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_regiao CC
  USING (
    SELECT * FROM VW_INT_C5_BAIRRODELIVERY
  ) S
  ON (CC.NROEMPRESA = S.NROEMPRESA AND CC.SEQREGIAO = S.SEQREGIAO)
  WHEN MATCHED THEN
    UPDATE SET 
      CC.REGIAO = S.REGIAO,
      CC.PRECOFRETE = S.PRECOFRETE,
      CC.ATIVO = S.ATIVO
    WHERE NVL(CC.REGIAO, '-') <> NVL(S.REGIAO, '-')
       OR NVL(CC.PRECOFRETE, -1) <> NVL(S.PRECOFRETE, -1)
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT (NROEMPRESA, SEQREGIAO, REGIAO, PRECOFRETE, ATIVO)
    VALUES (S.NROEMPRESA, S.SEQREGIAO, S.REGIAO, S.PRECOFRETE, S.ATIVO);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_regiao', 'carrega_tb_regiao OK', SYSDATE, CURRENT_TIMESTAMP);

	UPDATE MONITORPDVMIDDLE.TB_REGIAO R
  SET R.ATIVO = 'N'
  WHERE NOT EXISTS (
    SELECT 1 FROM PCBAIRRODELIV B WHERE R.NROEMPRESA = B.CODFILIAL AND R.SEQREGIAO = B.CODIGO
  )
    AND R.ATIVO = 'S'; 

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
           'carrega_tb_regiao',
           'carrega_tb_regiao ALERTA',
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
           'carrega_tb_regiao',
           'carrega_tb_regiao ERRO',
           SYSDATE,
           CURRENT_TIMESTAMP);
        COMMIT;
        RAISE;
  END;
END;

PROCEDURE carrega_tb_cctcenarioitem(p_id IN pccontroleconsinco.id%TYPE) AS
BEGIN
  MERGE INTO monitorpdvmiddle.tb_cctcenarioitem CC
  USING (
    SELECT 
      *
    FROM VW_INT_C5_CCTCENARIOITEM
  ) S
  ON (
  	CC.SEQCENARIO = S.SEQCENARIO
  	AND CC.PRODUTO = S.PRODUTO
  	AND CC.NCM = S.NCM
  	AND CC.FAMILIA = S.FAMILIA
  	AND CC.CGO = S.CGO
	AND CC.ORIGEM = S.ORIGEM
	AND CC.DESTINO = S.DESTINO
	AND CC.INDTIPOENTIDADEORIGEM = S.INDTIPOENTIDADEORIGEM
	AND CC.INDTIPOENTIDADEDESTINO = S.INDTIPOENTIDADEDESTINO
	AND CC.NBS = S.NBS
  )
  WHEN MATCHED THEN
    UPDATE SET 
      CC.IDREF = S.IDREF,
      CC.ATIVO = S.ATIVO
    WHERE NVL(CC.IDREF, -1) <> NVL(S.IDREF, -1)
       OR NVL(CC.ATIVO, '-') <> NVL(S.ATIVO, '-')
  WHEN NOT MATCHED THEN
    INSERT (SEQCENARIO, PRODUTO, NCM, FAMILIA, CGO, ORIGEM, DESTINO, INDTIPOENTIDADEORIGEM, INDTIPOENTIDADEDESTINO, NBS, ATIVO, IDREF)
    VALUES (S.SEQCENARIO, S.PRODUTO, S.NCM, S.FAMILIA, S.CGO, S.ORIGEM, S.DESTINO, S.INDTIPOENTIDADEORIGEM, S.INDTIPOENTIDADEDESTINO, S.NBS, S.ATIVO, S.IDREF);
  
  INSERT INTO PCDEVLOGCONSINCO  (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
  VALUES ('pkg_sinc_PDV_Consinco', 'carrega_tb_cctcenarioitem', 'carrega_tb_cctcenarioitem OK', SYSDATE, CURRENT_TIMESTAMP);
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
           'carrega_tb_cctcenarioitem',
           'carrega_tb_cctcenarioitem ALERTA',
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
           'carrega_tb_cctcenarioitem',
           'carrega_tb_cctcenarioitem ERRO',
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
