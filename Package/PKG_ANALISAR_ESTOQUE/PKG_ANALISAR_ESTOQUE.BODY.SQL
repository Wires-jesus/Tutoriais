CREATE OR REPLACE PACKAGE BODY PKG_ANALISAR_ESTOQUE
  IS

  TYPE TP_INTERNOS IS RECORD (
    CODFILIAL         PCMOV.CODFILIAL%TYPE
   ,CODPROD           PCMOV.CODPROD%TYPE
   ,NUMLOTE           PCMOV.NUMLOTE%TYPE
   ,DTATUAL           PCMOV.DTMOV%TYPE
   ,DTINICIAL         PCMOV.DTMOV%TYPE
   ,DTFINAL           PCMOV.DTMOV%TYPE
   ,DTBASE            PCMOV.DTMOV%TYPE
   ,DTLIMITE          PCMOV.DTMOV%TYPE DEFAULT NULL
   ,SALDO             PCMOV.QTCONT%TYPE
   ,CONTPCMOV         NUMBER
   ,TIPOCHAMADA       VARCHAR2(50) DEFAULT NULL
   ,ID_LISTA          VARCHAR2(50) DEFAULT NULL
   ,GERAR_LOG         VARCHAR2(1) DEFAULT 'N'
   ,USA_FUNCAO_1070   VARCHAR2(1) DEFAULT 'N'); 

  -- Type para armazenar os dados
  TYPE T_DADOS IS RECORD
    (QTDE          PCPEDI.QT%TYPE
    ,CODFILIAL     PCFILIAL.CODIGO%TYPE
    ,CODPROD       PCPRODUT.CODPROD%TYPE
    ,CODDEPOSITO   PCESTOQUEDEPOSITO.CODDEPOSITO%TYPE
    ,NUMLOTE       PCLOTE.NUMLOTE%TYPE);

  /***********************************************************************************************************************/
  -- Variaveis globais */
  /***********************************************************************************************************************/
  vtPRODUTO                       PCPRODUT%ROWTYPE;
  vtHIST_EST                      PCHISTEST%ROWTYPE;
  vtHIST_LOTE                     PCHISTESTLOTE%ROWTYPE;
  vtLOG                           PCLOGRECEST%ROWTYPE;
  P_INTERNOS                      TP_INTERNOS;
  vrDADOS                         TR_MOVIMENTACOES;
  vSQL                            VARCHAR2(5000);
  vSQLFILIALRETIRA                VARCHAR2(500);
  vDATAFIN                        DATE;
  vDATAPEDPENDENTE                DATE;
  vDATAPEDPENDENTERETIRA          DATE;
  vDATAPEDRESERVADA               DATE;
  vDATAPEDRESERVADARETIRA         DATE;
  vUTILIZAESTOQUEPORDEPOSITO      VARCHAR2(1);
  vUTILIZACENTRALFATURAMENTO      VARCHAR2(1);
  vRECALCULAR_RESERVADO_DEPOSITO  VARCHAR2(1);
  vRECALCULAR_RESERVADO_LOTE      VARCHAR2(1);
  vRECALCULAR_RESERVADO           VARCHAR2(1);
  vnCONTPCMOV                     NUMBER;
  vnCONTADOR                      NUMBER;
  vsFUNCAO_EXECUTADA              VARCHAR2(100);
  vsRETORNO                       VARCHAR2(30000);
  vsCREATE                        VARCHAR2(30000);
  vsINSERT                        VARCHAR2(30000);
  vsDELETE                        VARCHAR2(30000);
  vsALTERAR                       VARCHAR2(30000);
  vsSQL                           VARCHAR2(30000);
  vnREGISTRO                      PCEST.QTESTGER%TYPE;
  vdDTCADASTRO                    PCPRODUT.DTCADASTRO%TYPE;
  vdMAIOR_DATA                    PCHISTEST.DATA%TYPE;

  -- Versão da package */
  FUNCTION VERSAO RETURN VARCHAR2
  IS
  BEGIN
    RETURN 'VSVERSAOPACKAGE_REPLACE';
  END;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  01/09/2017     Fernandes Brito                       Criada procedure para unificar codigo de inserção de mensagem de alerta de erro
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRIV_INS_MSG_MONITOR (ptMSG_MON IN TR_MSG_MON)
  IS
    -- Variaveis de uso interno
    vsMSG_ASSUNTO VARCHAR2(1500);
    vsMSG_CORPO   VARCHAR2(6000);
    vsCONTADOR    NUMBER;
  BEGIN
  -- Caso a mensagem seja para um usuário do sistema
  IF ptMSG_MON.DESTINO <> 'TOTVS' THEN
    -- Mensagem do assunto
    vsMSG_ASSUNTO :=
    CASE
      WHEN ptMSG_MON.MSG_ASSUNTO_2 IS NULL THEN
        ptMSG_MON.COD_MSG||ptMSG_MON.MSG_ASSUNTO_1||' '||ptMSG_MON.CODPROD
    ELSE
      ptMSG_MON.COD_MSG||ptMSG_MON.MSG_ASSUNTO_1||' '||ptMSG_MON.CODPROD||' '||ptMSG_MON.MSG_ASSUNTO_2
    END;

    -- Mensagem do corpo
    vsMSG_CORPO   :=
    CASE
      -- Caso tenha apenas 1 mensagem no corpo do recado
      WHEN ptMSG_MON.MSG_CORPO_2 IS NULL THEN
         ptMSG_MON.MSG_CORPO_1||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
        'Código da filial............................................: '||ptMSG_MON.CODFILIAL||CHR(13)||CHR(10)||
        'Código do produto...........................................: '||ptMSG_MON.CODPROD||CHR(13)||CHR(10)||
        'Produto excluído............................................: '||ptMSG_MON.EXCLUIDO||CHR(13)||CHR(10)||
        CASE
          WHEN ptMSG_MON.DATA_ANTES IS NULL THEN
            'No dia '||ptMSG_MON.DTINICIAL||' não existe saldo gravado...................: '
        ELSE
          'No dia '||ptMSG_MON.DATA_ANTES||' o saldo era de.....................: '
        END||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_ANTES_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_ANTES_CONT||CHR(13)||CHR(10)
        END||
        CASE
          WHEN ptMSG_MON.DATA_ATUAL IS NULL THEN
            'No dia '||ptMSG_MON.DTFINAL||' o sistema movimentou a quantidade de.......: '
        ELSE
          'No dia '||ptMSG_MON.DATA_ATUAL||' o sistema movimentou a quantidade de.......: '
        END||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_GER_MOVIMENTADA||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_CONT_MOVIMENTADA||CHR(13)||CHR(10)
        END||
        CASE
          WHEN ptMSG_MON.DATA_ATUAL IS NULL THEN
            'O sistema não gravou saldo final para este dia.....: '
        ELSE
          'O sistema gravou como saldo final deste dia a quantidade de : '
        END||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_ATUAL_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_ATUAL_CONT||CHR(13)||CHR(10)
        END||
        'O correto a ser gravado seria a quantidade de...............: '||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_CORRETA_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_CORRETA_CONT||CHR(13)||CHR(10)
        END||
        'Logo para este produto existe uma diferença de..............: '||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_DIF_GER||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_DIF_CONT||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        END||
        CASE
          WHEN ptMSG_MON.MSG_MOTIVO_2 IS NULL THEN
            'Possível Motivo: '||ptMSG_MON.MSG_MOTIVO_1||CHR(13)||CHR(10)||CHR(13)||CHR(10)
          WHEN ptMSG_MON.MSG_MOTIVO_3 IS NULL THEN
            'Possível Motivo: '||ptMSG_MON.MSG_MOTIVO_1||CHR(13)||CHR(10)||
            ptMSG_MON.MSG_MOTIVO_2||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        ELSE
          'Possível Motivo: '||ptMSG_MON.MSG_MOTIVO_1||CHR(13)||CHR(10)||
          ptMSG_MON.MSG_MOTIVO_2||CHR(13)||CHR(10)||
          ptMSG_MON.MSG_MOTIVO_3||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        END||
        CASE
          WHEN ptMSG_MON.MSG_SOLUCAO_2 IS NULL THEN
            'Possível Solução: '||ptMSG_MON.MSG_SOLUCAO_1||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        ELSE
          'Possível Solução: '||ptMSG_MON.MSG_SOLUCAO_1||CHR(13)||CHR(10)||
          ptMSG_MON.MSG_SOLUCAO_2||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        END
      -- Caso tenha 2 mensagens no corpo do recado
      WHEN ptMSG_MON.MSG_CORPO_3 IS NULL THEN
         ptMSG_MON.MSG_CORPO_1||CHR(13)||CHR(10)||
         ptMSG_MON.MSG_CORPO_2||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
        'Código da filial............................................: '||ptMSG_MON.CODFILIAL||CHR(13)||CHR(10)||
        'Código do produto...........................................: '||ptMSG_MON.CODPROD||CHR(13)||CHR(10)||
        'Produto excluído............................................: '||ptMSG_MON.EXCLUIDO||CHR(13)||CHR(10)||
        CASE
          WHEN ptMSG_MON.DATA_ANTES IS NULL THEN
            'No dia '||ptMSG_MON.DTINICIAL||' não existe saldo gravado...................: '
        ELSE
          'No dia '||ptMSG_MON.DATA_ANTES||' o saldo era de.....................: '
        END||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_ANTES_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_ANTES_CONT||CHR(13)||CHR(10)
        END||
        CASE
          WHEN ptMSG_MON.DATA_ATUAL IS NULL THEN
            'No dia '||ptMSG_MON.DTFINAL||' o sistema movimentou a quantidade de.......: '
        ELSE
          'No dia '||ptMSG_MON.DATA_ATUAL||' o sistema movimentou a quantidade de.......: '
        END||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_SALDO_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_SALDO_CONT||CHR(13)||CHR(10)
        END||
        'O sistema gravou como saldo final deste dia a quantidade de : '||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_ATUAL_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_ATUAL_CONT||CHR(13)||CHR(10)
        END||
        'O correto a ser gravado seria a quantidade de...............: '||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_CORRETA_GER||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_CORRETA_CONT||CHR(13)||CHR(10)
        END||
        'Logo para este produto existe uma diferença de..............: '||
        CASE
          WHEN ptMSG_MON.ID = 'GERENCIAL' THEN
            ptMSG_MON.QTDE_DIF_GER||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        ELSE
          ptMSG_MON.QTDE_DIF_CONT||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        END||
        CASE
          WHEN ptMSG_MON.MSG_MOTIVO_2 IS NULL THEN
            'Possível Motivo: '||ptMSG_MON.MSG_MOTIVO_1||CHR(13)||CHR(10)||CHR(13)||CHR(10)
          WHEN ptMSG_MON.MSG_MOTIVO_3 IS NULL THEN
            'Possível Motivo: '||ptMSG_MON.MSG_MOTIVO_1||CHR(13)||CHR(10)||
            ptMSG_MON.MSG_MOTIVO_2||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        ELSE
          'Possível Motivo: '||ptMSG_MON.MSG_MOTIVO_1||CHR(13)||CHR(10)||
          ptMSG_MON.MSG_MOTIVO_2||CHR(13)||CHR(10)||
          ptMSG_MON.MSG_MOTIVO_3||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        END||
         CASE
          WHEN ptMSG_MON.MSG_SOLUCAO_2 IS NULL THEN
            'Possível Solução: '||ptMSG_MON.MSG_SOLUCAO_1||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        ELSE
          'Possível Solução: '||ptMSG_MON.MSG_SOLUCAO_1||CHR(13)||CHR(10)||
          ptMSG_MON.MSG_SOLUCAO_2||CHR(13)||CHR(10)||CHR(13)||CHR(10)
        END
      END;
      -- Criar mensagem para ser enviada para Luciana
      INSERT INTO PCRECFUNC
            (CODFUNCAB                 -- 1
            ,DTAB                      -- 2
            ,CODSETORORIG              -- 3
            ,CODSETORDEST              -- 4
            ,CODFUNCDEST               -- 5
            ,ASSUNTO                   -- 6
            ,TEXTORECADO               -- 7
            ,NUMRECADO)                -- 8
     VALUES (1                         -- 1
            ,SYSDATE                   -- 2
            ,1                         -- 3
            ,1                         -- 4
            ,ptMSG_MON.CODUSUARIO      -- 5
            ,vsMSG_ASSUNTO             -- 6
            ,vsMSG_CORPO               -- 7
            ,DFSEQ_PCRECFUNC.NEXTVAL); -- 8
    -- Caso a mensagem seja para a TOTVS
    ELSE
      
      vsCONTADOR := 0;
      
      SELECT COUNT(1)
        INTO vsCONTADOR
        FROM PCMENSAGEMLOGFALHA
       WHERE PCMENSAGEMLOGFALHA.CODIGO_ASSUNTO = ptMSG_MON.COD_MSG
         AND TRUNC(PCMENSAGEMLOGFALHA.DTREGISTRO) = TRUNC(SYSDATE)
         AND PCMENSAGEMLOGFALHA.LITERAL_1 = ptMSG_MON.CODFILIAL
         AND PCMENSAGEMLOGFALHA.EXCLUIDO = 'N';
      
      IF vsCONTADOR = 0 THEN  
        -- Criar mensagem para ser enviada via e-mail
        INSERT
          INTO PCMENSAGEMLOGFALHA
              (CODMENS                                -- 1
              ,DTREGISTRO                             -- 2
              ,CODIGO_ASSUNTO                         -- 3
              ,ASSUNTO                                -- 4
              ,MENSAGEM                               -- 5
              ,LITERAL_1                              -- 6 Código da filial
              ,NUMERICO_1                             -- 7 Qtde. produtos cadastrados na filial (PCEST)
              ,NUMERICO_2                             -- 8 Qtde. produtos com estoque na filial (PCEST)
              ,NUMERICO_3                             -- 9 Qtde. produtos excluídos (PCPRODUT)
              ,NUMERICO_4                             -- 9 Qtde. produtos com problemas na filial (MENSAGEMLOGFALHA)
              ,EXCLUIDO                               -- 10
              )
       VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
              ,SYSDATE                                -- 2
              ,ptMSG_MON.COD_MSG                      -- 3
              ,vsMSG_ASSUNTO                          -- 4
              ,vsMSG_CORPO                            -- 5
              ,ptMSG_MON.CODFILIAL                    -- 6
              ,(SELECT COUNT(1)
                  FROM PCEST
                 WHERE CODFILIAL = ptMSG_MON.CODFILIAL)-- 7
              ,(SELECT COUNT(1) TOTAL
                  FROM PCEST
                 WHERE PCEST.CODFILIAL = ptMSG_MON.CODFILIAL
                   AND (NVL(PCEST.QTEST, 0) <> 0 OR
                        NVL(PCEST.QTESTGER, 0) <> 0 OR
                        NVL(PCEST.QTTRANSITO, 0) <> 0 OR
                        NVL(PCEST.QTTRANSITOTV13, 0) <> 0))-- 8
              ,(SELECT COUNT(1)
                  FROM PCPRODUT
                 WHERE DTEXCLUSAO IS NOT NULL)-- 9
              ,1                                      -- 10
              ,'N');                                  -- 11
      ELSE
        UPDATE PCMENSAGEMLOGFALHA
           SET NUMERICO_4 = NUMERICO_4 + 1
         WHERE CODIGO_ASSUNTO = ptMSG_MON.COD_MSG
           AND TRUNC(DTREGISTRO) = TRUNC(SYSDATE)
           AND LITERAL_1 = ptMSG_MON.CODFILIAL;
      END IF;
                             
    END IF;
  -- Procedure
  END PRIV_INS_MSG_MONITOR;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  01/09/2017     Fernandes Brito                       Criada procedure para unificar codigo de inserção de mensagem
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRIV_MSG_MONITOR (ptMSG_MONITOR IN OUT TR_MSG_MON)
  IS
    -- Variaveis de uso interno
  BEGIN
    -- Criar mensagem para ser enviada para o usuário
    IF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-1' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': Não existe histórico GERENCIAL do produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'para a data de ANTES DE ONTEM';
      ptMSG_MONITOR.MSG_CORPO_1   := 'Não existe histórico para a data de antes de ontem conforme os dados abaixo (PCHISTEST): ';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do histórico do produto através da rotina 504/820!';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Executar a rotina 1192 opção "Recomposição de dados históricos de estoque".';
      ptMSG_MONITOR.MSG_SOLUCAO_2 := 'Em caso de duvidas sobre o uso da rotina 1192, abra uma solicitação junto a TOTVS.';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-2' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': Não existe histórico CONTABIL do produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'para a data de ANTES DE ONTEM';
      ptMSG_MONITOR.MSG_CORPO_1   := 'Não existe histórico para a data de antes de ontem conforme os dados abaixo (PCHISTEST): ';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do histórico do produto através da rotina 504/820!';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Executar a rotina 1192 opção "Recomposição de dados históricos de estoque".';
      ptMSG_MONITOR.MSG_SOLUCAO_2 := 'Em caso de duvidas sobre o uso da rotina 1192, abra uma solicitação junto a TOTVS.';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-3' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': Não existe histórico GERENCIAL do produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'para a data de ONTEM';
      ptMSG_MONITOR.MSG_CORPO_1   := 'Não existe histórico para a data de ontem conforme os dados abaixo (PCHISTEST): ';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do histórico do produto através da rotina 504/820!';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Executar a rotina 1192 opção "Recomposição de dados históricos de estoque".';
      ptMSG_MONITOR.MSG_SOLUCAO_2 := 'Em caso de duvidas sobre o uso da rotina 1192, abra uma solicitação junto a TOTVS.';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-4' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': Não existe histórico CONTABIL do produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'para a data de ONTEM';
      ptMSG_MONITOR.MSG_CORPO_1   := 'Não existe histórico para a data de ontem conforme os dados abaixo (PCHISTEST): ';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do histórico do produto através da rotina 504/820!';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Executar a rotina 1192 opção "Recomposição de dados históricos de estoque".';
      ptMSG_MONITOR.MSG_SOLUCAO_2 := 'Em caso de duvidas sobre o uso da rotina 1192, abra uma solicitação junto a TOTVS.';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-5' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': O produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'esta com problemas no estoque GERENCIAL';
      ptMSG_MONITOR.MSG_CORPO_1   := 'O estoque GERENCIAL foi movimentado ou teve seu histórico gravado de forma errada para os seguintes dados:';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do estoque em algumas de suas aplicações!';
      ptMSG_MONITOR.MSG_MOTIVO_2  := 'Analise os dados das tabelas PCMOV, PCLOGPKG_ESTOQUE e PCLOGESTOQUE ou peça ajuda a TOTVS';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Não identificada!';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-6' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': O produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'esta com problemas no estoque CONTABIL';
      ptMSG_MONITOR.MSG_CORPO_1   := 'O estoque CONTABIL foi movimentado ou teve seu histórico gravado de forma errada para os seguintes dados:';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do estoque em algumas de suas aplicações!';
      ptMSG_MONITOR.MSG_MOTIVO_2  := 'Analise os dados das tabelas PCMOV, PCLOGPKG_ESTOQUE e PCLOGESTOQUE ou peça ajuda a TOTVS';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Não identificada!';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-7' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': O produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'teve movimentação GERENCIAL e porém não gravou histórico';
      ptMSG_MONITOR.MSG_CORPO_1   := 'O estoque GERENCIAL foi movimentado (PCMOV) e não houve gravação do histórico para os seguintes dados:';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do histórico do produto através da rotina 504/820!';
      ptMSG_MONITOR.MSG_MOTIVO_2  := 'Verifique se todas as notas geradas para este produto foram aprovadas pelo SEFAZ.';
      ptMSG_MONITOR.MSG_MOTIVO_3  := 'Analise os dados na tabela PCMOV, PCLOGPKG_ESTOQUE e PCLOGESTOQUE ou peça ajuda a TOTVS';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Executar a rotina 1192 opção "Recomposição de dados históricos de estoque".';
      ptMSG_MONITOR.MSG_SOLUCAO_2 := 'Em caso de duvidas sobre o uso da rotina 1192, abra uma solicitação junto a TOTVS.';

    -- Criar mensagem para ser enviada para o usuário
    ELSIF ptMSG_MONITOR.COD_MSG = 'DDESTOQUE-MSG-8' THEN
      ptMSG_MONITOR.MSG_ASSUNTO_1 := ': O produto';
      ptMSG_MONITOR.MSG_ASSUNTO_2 := 'teve movimentação CONTABIL e porém não gravou histórico';
      ptMSG_MONITOR.MSG_CORPO_1   := 'O estoque CONTABIL foi movimentado (PCMOV) e não houve gravação do histórico para os seguintes dados:';
      ptMSG_MONITOR.MSG_MOTIVO_1  := 'É possível que o sistema tenha falhado na movimentação do histórico do produto através da rotina 504/820!';
      ptMSG_MONITOR.MSG_MOTIVO_2  := 'Verifique se todas as notas geradas para este produto foram aprovadas pelo SEFAZ.';
      ptMSG_MONITOR.MSG_MOTIVO_3  := 'Analise os dados na tabela PCMOV, PCLOGPKG_ESTOQUE e PCLOGESTOQUE ou peça ajuda a TOTVS';
      ptMSG_MONITOR.MSG_SOLUCAO_1 := 'Executar a rotina 1192 opção "Recomposição de dados históricos de estoque".';
      ptMSG_MONITOR.MSG_SOLUCAO_2 := 'Em caso de duvidas sobre o uso da rotina 1192, abra uma solicitação junto a TOTVS.';

    END IF;

                     
  -- Procedure
  END PRIV_MSG_MONITOR;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  02/09/2017     Fernandes Brito                       Procedure criada para validar os estoque gerencial e contábil para o monitoramento do estoque
  16/11/2020     Fernandes Brito                       Ajustada a procedure para gravar dados na PCMENSAGEMLOGFALHA de forma mais detalhada.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRIV_VERIFICAR_ERROS (ptMSG_MONITOR IN OUT TR_MSG_MON)
  IS-- Variaveis de uso interno
  BEGIN
    -- Caso não exista histórico para "Antes de ontem" gerencial
    IF (ptMSG_MONITOR.DATA_ANTES IS NULL AND
        ptMSG_MONITOR.DATA_ATUAL IS NOT NULL AND
        ptMSG_MONITOR.QTDE_SALDO_GER <> ptMSG_MONITOR.QTDE_ATUAL_GER) THEN
      -- Tipo de mensagem
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-1';
    -- Caso não exista histórico para "Antes de ontem" contábil
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NOT NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NULL AND
           ptMSG_MONITOR.QTDE_SALDO_CONT <> ptMSG_MONITOR.QTDE_ATUAL_CONT) THEN
      -- Tipo de mensagem
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-2';
    -- Caso não exista histórico para "Ontem" gerencial
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NOT NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NULL AND
           ptMSG_MONITOR.QTDE_SALDO_GER <> ptMSG_MONITOR.QTDE_ATUAL_GER) THEN
      -- Tipo de mensagem
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-3';
    -- Caso não exista histórico para "Ontem" contabil
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NOT NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NULL AND
           ptMSG_MONITOR.QTDE_SALDO_CONT <> ptMSG_MONITOR.QTDE_ATUAL_CONT) THEN
      -- Tipo de mensagem
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-4';
    -- Caso exista divergência dos saldos gerencial
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NOT NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NOT NULL AND
           ptMSG_MONITOR.QTDE_SALDO_GER <> ptMSG_MONITOR.QTDE_ATUAL_GER) THEN
      -- Tipo de mensagem
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-5';
    -- Caso exista divergência dos saldos contabil
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NOT NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NOT NULL AND
           ptMSG_MONITOR.QTDE_SALDO_CONT <> ptMSG_MONITOR.QTDE_ATUAL_CONT) THEN
      -- Tipo de mensagem
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-6';
    -- Caso exista movimentação por não houve gravação do PCHISTEST gerencial
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NULL AND
           ptMSG_MONITOR.QTDE_GER_MOVIMENTADA <> 0) THEN
      -- Tipo de mensagem */
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-7';
    -- Caso exista movimentação por não houve gravação do PCHISTEST contabil
    ELSIF (ptMSG_MONITOR.DATA_ANTES IS NULL AND
           ptMSG_MONITOR.DATA_ATUAL IS NULL AND
           ptMSG_MONITOR.QTDE_CONT_MOVIMENTADA <> 0) THEN
      -- Tipo de mensagem */
      ptMSG_MONITOR.COD_MSG := 'DDESTOQUE-MSG-8';
    -- Envio
    END IF;
    -- Criando mensagem para inserção
    IF ptMSG_MONITOR.COD_MSG IS NOT NULL AND ptMSG_MONITOR.DESTINO <> 'TOTVS' THEN
      -- Executar inserção da mensagem
      PRIV_MSG_MONITOR (ptMSG_MONITOR);
      PRIV_INS_MSG_MONITOR (ptMSG_MONITOR);
    ELSIF ptMSG_MONITOR.COD_MSG IS NOT NULL AND ptMSG_MONITOR.DESTINO = 'TOTVS' THEN
      PRIV_INS_MSG_MONITOR (ptMSG_MONITOR);
    END IF;
  -- Procedure
  END PRIV_VERIFICAR_ERROS;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar função para analisar problemas de estoque
  /***********************************************************************************************************************/
  FUNCTION F_ANALISAR_ESTOQUE (psCODFILIAL   IN PCFILIAL.CODIGO%TYPE
                              ,pnCODPRODUTO  IN PCPRODUT.CODPROD%TYPE)
    RETURN TB_ANALISAR_ESTOQUE
    PIPELINED
  IS-- Variáveis internas
    vrDADOS                  T_ANALISAR_ESTOQUE;
    vnQTDE_DEPOSITO          PCESTOQUEDEPOSITOPROD.QTESTOQUE%TYPE;
    vnQTRESERV_DEPOSITO      PCESTOQUEDEPOSITOPROD.QTRESERVADA%TYPE;
    vnQTPENDENTE_DEPOSITO    PCESTOQUEDEPOSITOPROD.QTPENDENTE%TYPE;
    vnQTBLOQ_DEPOSITO        PCESTOQUEDEPOSITOPROD.QTBLOQUEADA%TYPE;
    vnQTINDENIZ_DEPOSITO     PCESTOQUEDEPOSITOPROD.QTINDENIZADA%TYPE;
    vnQTDE_RESERVADA         PCPEDI.QT%TYPE;
    vnQTDE_PENDENTE          PCPEDI.QT%TYPE;
  BEGIN
    -- Lista estoque
    FOR ESTOQUE IN (SELECT PCEST.CODFILIAL
                          ,PCEST.CODPROD
                          ,NVL(PCEST.QTESTGER,0) QTESTOQUE
                          ,NVL(PCEST.QTRESERV,0) QTRESERVADA
                          ,NVL(PCEST.QTPENDENTE,0) QTPENDENTE
                          ,NVL(PCEST.QTBLOQUEADA,0) QTBLOQUEADA
                          ,NVL(PCEST.QTINDENIZ,0) QTINDENIZADA
                      FROM PCEST
                     WHERE (psCODFILIAL IS NULL OR CODFILIAL = psCODFILIAL)
                       AND (pnCODPRODUTO IS NULL OR CODPROD = pnCODPRODUTO))
    LOOP

      /********************************************************************
             Comparando estoque atual com total do estoque do depósito
      ********************************************************************/

      -- Qtde deposito para o produto na filial
      SELECT SUM(NVL(PCESTOQUEDEPOSITOPROD.QTESTOQUE,0))
            ,SUM(NVL(PCESTOQUEDEPOSITOPROD.QTRESERVADA,0))
            ,SUM(NVL(PCESTOQUEDEPOSITOPROD.QTPENDENTE,0))
            ,SUM(NVL(PCESTOQUEDEPOSITOPROD.QTBLOQUEADA,0))
            ,SUM(NVL(PCESTOQUEDEPOSITOPROD.QTINDENIZADA,0))
        INTO vnQTDE_DEPOSITO
            ,vnQTRESERV_DEPOSITO
            ,vnQTPENDENTE_DEPOSITO
            ,vnQTBLOQ_DEPOSITO
            ,vnQTINDENIZ_DEPOSITO
        FROM PCESTOQUEDEPOSITOPROD
       WHERE PCESTOQUEDEPOSITOPROD.CODFILIAL = ESTOQUE.CODFILIAL
         AND PCESTOQUEDEPOSITOPROD.CODPROD = ESTOQUE.CODPROD;
      -- Tem problemas de quantidade?
      IF ESTOQUE.QTESTOQUE <> vnQTDE_DEPOSITO THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre "ESTOQUE ATUAL" e "ESTOQUE DO DEPOSITO"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.ESTOQUE_ATUAL        := ESTOQUE.QTESTOQUE;
        vrDADOS.ESTOQUE_DEPOSITO     := vnQTDE_DEPOSITO;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      -- Tem problemas de estoque reservado?
      ELSIF ESTOQUE.QTRESERVADA <> vnQTRESERV_DEPOSITO THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "RESERVADO ATUAL" e "RESERVADO DO DEPOSITO"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.QTRESERVADA_ATUAL    := ESTOQUE.QTRESERVADA;
        vrDADOS.QTRESERVADA_DEPOSITO := vnQTRESERV_DEPOSITO;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      -- Tem problemas de estoque pendente?
      ELSIF ESTOQUE.QTPENDENTE <> vnQTPENDENTE_DEPOSITO THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "PENDENTE ATUAL" e "PENDENTE DO DEPOSITO"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.QTPENDENTE_ATUAL     := ESTOQUE.QTPENDENTE;
        vrDADOS.QTPENDENTE_DEPOSITO  := vnQTPENDENTE_DEPOSITO;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      -- Tem problemas de estoque bloqueado?
      ELSIF ESTOQUE.QTBLOQUEADA <> vnQTBLOQ_DEPOSITO THEN
        NULL;
      -- Tem problemas de estoque avariado?
      ELSIF ESTOQUE.QTINDENIZADA <> vnQTINDENIZ_DEPOSITO THEN
        NULL;
      END IF;

      /********************************************************************
      Comparando estoque reservado atual com total registrados nos pedidos
      ********************************************************************/

      -- Qtde reservada nos pedidos/requisições/ordem de produção
      SELECT SUM(NVL(QTDE,0))
        INTO vnQTDE_RESERVADA
        FROM (SELECT SUM(PCPEDI.QT) QTDE
                FROM PCPEDI, PCPEDC
               WHERE PCPEDI.NUMPED = PCPEDC.NUMPED
                 AND NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL) = ESTOQUE.CODFILIAL
                 AND PCPEDI.CODPROD = ESTOQUE.CODPROD
                 AND DECODE(NVL(PCPEDC.VENDAASSISTIDA, 'N'),'S',NVL(PCPEDI.POSICAO, PCPEDC.POSICAO),PCPEDC.POSICAO) IN ('L', 'M')
                 AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(NVL(PCPEDI.CODFILIALRETIRA,PCPEDC.CODFILIAL),PCPEDI.CODPROD) = 'N'
                 AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
                 AND NVL(PCPEDI.QT, 0) > 0
                 AND PCPEDC.NUMOS IS NULL
                 AND PCPEDC.DATA >= (SELECT MIN(C.DATA)
                                       FROM PCPEDC C
                                           ,PCPEDI I
                                      WHERE C.NUMPED = I.NUMPED
                                        AND C.POSICAO IN ('L', 'M')
                                        AND NVL(I.CODFILIALRETIRA,C.CODFILIAL) = NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL))
               
               UNION
              SELECT SUM(MOVPRE.QT) QTDE
                FROM PCNFSAIDPREFAT NFPRE, PCMOVPREFAT MOVPRE
               WHERE NFPRE.NUMTRANSVENDA = MOVPRE.NUMTRANSVENDA 
                 AND NVL(MOVPRE.CODFILIALRETIRA, MOVPRE.CODFILIAL) = ESTOQUE.CODFILIAL
                 AND MOVPRE.CODPROD = ESTOQUE.CODPROD
                 AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(NVL(MOVPRE.CODFILIALRETIRA,NFPRE.CODFILIAL),MOVPRE.CODPROD) = 'N'
                 AND NVL(MOVPRE.QT, 0) > 0
                 AND MOVPRE.DTCANCEL IS NULL
                 AND NFPRE.CONDVENDA NOT IN (4, 7, 14)
                 AND NFPRE.NUMOS IS NULL
                 AND NFPRE.DTCANCEL IS NULL
                 AND NFPRE.SITUACAONFE NOT IN (110, 205, 301, 302, 303)
                 AND NFPRE.DTSAIDA >= (SELECT MIN(C.DATA)
                                         FROM PCPEDC C
                                             ,PCPEDI I
                                        WHERE C.NUMPED = I.NUMPED
                                          AND C.POSICAO IN ('L', 'M')
                                          AND NVL(I.CODFILIALRETIRA,C.CODFILIAL) = NVL(MOVPRE.CODFILIALRETIRA, MOVPRE.CODFILIAL))
                 AND NOT EXISTS (SELECT PCNFSAID.NUMTRANSVENDA
                                   FROM PCNFSAID
                                  WHERE PCNFSAID.NUMTRANSVENDA = NFPRE.NUMTRANSVENDA)
               UNION
              SELECT NVL(SUM(RI.QT), 0) QTDE
                FROM PCPREREQMATCONSUMOI RI
                    ,PCPREREQMATCONSUMOC RC
               WHERE RI.NUMPREREQUISICAO = RC.NUMPREREQUISICAO
                 AND RC.CODFILIAL = ESTOQUE.CODFILIAL
                 AND RI.CODPROD = ESTOQUE.CODPROD
                 AND RI.CODOPER = 'SM'
                 AND RC.SITUACAO = 'L'
                 AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(RC.CODFILIAL, RI.CODPROD) = 'N'
               UNION
              SELECT SUM(ROUND(QT, 6)) QTDE
                FROM (SELECT CODPROD,
                             NUMLOTE,
                             CODFILIAL,
                             FINALIZAPRODUCAO,
                             QTPRODUZIR,
                             QTPRODUZIDA,
                             CODDEPOSITO,
                             CASE
                               WHEN (QTPRODUZIR >= QTRESTANTE) AND (QTRESTANTE > 0) AND
                                    (FINALIZAPRODUCAO <> 'X') THEN
                                (QTRESTANTE * QTFORMULA)
                               WHEN (QTPRODUZIR >= QTRESTANTE) AND (QTRESTANTE <= 0) AND
                                    (FINALIZAPRODUCAO <> 'X') THEN
                                (0)
                               WHEN (QTPRODUZIR < QTRESTANTE) AND (QTRESTANTE > 0) AND
                                    (FINALIZAPRODUCAO = 'N') THEN
                                (QTPRODUZIR * QTFORMULA)
                               WHEN (QTPRODUZIR < QTRESTANTE) AND (QTRESTANTE > 0) AND
                                    (FINALIZAPRODUCAO = 'S') THEN
                                (QTRESTANTE * QTFORMULA)
                             END QT
                        FROM (SELECT C.CODFILIAL,
                                     I.CODPROD,
                                     L.NUMLOTE,
                                     NVL(C.QTPRODUZIR, 0) QTPRODUZIR,
                                     NVL(C.QTPRODUZIDA, 0) QTPRODUZIDA,
                                     (NVL(C.QTPRODUZIR, 0) - NVL(C.QTPRODUZIDA, 0)) QTRESTANTE,
                                     DECODE(NVL(L.QT, 0), 0, I.QTNECESSIDADE, L.QT) AS QTTOTAL,
                                     (DECODE(NVL(L.QT, 0), 0, I.QTNECESSIDADE, L.QT) /
                                     C.QTPRODUZIR) AS QTFORMULA,
                                     NVL(FINALIZAPRODUCAO, 'N') FINALIZAPRODUCAO,
                                     NVL(I.CODDEPOSITO, 0) AS CODDEPOSITO
                                FROM PCOPI I, PCOPILOTE L, PCOPC C
                               WHERE I.NUMOP = C.NUMOP
                                 AND I.NUMOP = L.NUMOP(+)
                                 AND I.CODPROD = L.CODPROD(+)
                                 AND C.CODFILIAL = ESTOQUE.CODFILIAL
                                 AND I.CODPROD = ESTOQUE.CODPROD
                                 AND I.NUMOP > 0
                                 AND C.POSICAO = 'P'
                                 AND NVL(FINALIZAPRODUCAO, 'N') = 'N'
                                 AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(C.CODFILIAL,I.CODPROD) = 'N'))
              UNION
              SELECT SUM(ROUND(R.QT, 6)) QTDE
                FROM PCREQUISICAODEPOSITO R
               WHERE R.POSICAO = 'A'
                 AND R.NOME_TABELA = 'PCREQUISICAODEPOSITO'
                 AND R.CODFILIAL = ESTOQUE.CODFILIAL
                 AND R.CODPROD = ESTOQUE.CODPROD);
      -- Tem problemas de reserva nos pedidos/requisições/ordem de produção?
      IF ESTOQUE.QTRESERVADA <> vnQTDE_RESERVADA THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "RESERVADO ATUAL" e o saldo dos pedidos na posição "RESERVADA"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.QTRESERVADA_ATUAL    := ESTOQUE.QTRESERVADA;
        vrDADOS.QTRESERVADA_PEDIDOS  := vnQTDE_RESERVADA;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      END IF;
      -- Tem problemas de reserva nos pedidos/requisições/ordem de produção?
      IF vnQTRESERV_DEPOSITO <> vnQTDE_RESERVADA THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "RESERVADO DO DEPOSITO" e o saldo dos pedidos na posição "RESERVADA"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.QTRESERVADA_DEPOSITO := vnQTRESERV_DEPOSITO;
        vrDADOS.QTRESERVADA_PEDIDOS  := vnQTDE_RESERVADA;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      END IF;

      /********************************************************************
       Comparando estoque pendente atual com total registrados nos pedidos
      ********************************************************************/
      -- Qtde de pedidos pendentes
      SELECT SUM(NVL(QTDE,0))
        INTO vnQTDE_PENDENTE
        FROM (SELECT SUM(PCPEDI.QT) QTDE
                FROM PCPEDI, PCPEDC
               WHERE PCPEDI.NUMPED = PCPEDC.NUMPED
                 AND NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL) = ESTOQUE.CODFILIAL
                 AND PCPEDI.CODPROD = ESTOQUE.CODPROD
                 AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
                 AND NVL(PCPEDI.QT, 0) > 0
                 AND PCPEDC.NUMOS IS NULL
                 AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(NVL(PCPEDI.CODFILIALRETIRA,PCPEDC.CODFILIAL),PCPEDI.CODPROD) = 'N'
                 AND DECODE(NVL(PCPEDC.VENDAASSISTIDA, 'N'),'S',NVL(PCPEDI.POSICAO, PCPEDC.POSICAO),PCPEDC.POSICAO) IN ('B', 'P')
                 AND PCPEDC.DATA >= (SELECT MIN(C.DATA)
                                       FROM PCPEDC C
                                           ,PCPEDI I
                                      WHERE C.NUMPED = I.NUMPED
                                        AND C.POSICAO IN ('P', 'B')
                                        AND NVL(I.CODFILIALRETIRA,C.CODFILIAL) = NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)));
      -- Tem problemas de pendencia nos pedidos de venda?
      IF ESTOQUE.QTPENDENTE <> vnQTDE_PENDENTE THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "PENDENTE ATUAL" e o saldo dos pedidos na posição "PENDENTE"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.QTPENDENTE_ATUAL     := ESTOQUE.QTPENDENTE;
        vrDADOS.QTPENDENTE_PEDIDOS   := vnQTDE_PENDENTE;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      END IF;
      -- Tem problemas de pendencia nos pedidos de venda?
      IF vnQTPENDENTE_DEPOSITO <> vnQTDE_PENDENTE THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "PENDENTE DO DEPÓSITO" e o saldo dos pedidos na posição "PENDENTE"';
        vrDADOS.CODFILIAL            := ESTOQUE.CODFILIAL;
        vrDADOS.CODPROD              := ESTOQUE.CODPROD;
        vrDADOS.QTPENDENTE_DEPOSITO  := vnQTPENDENTE_DEPOSITO;
        vrDADOS.QTPENDENTE_PEDIDOS   := vnQTDE_PENDENTE;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      END IF;
    -- Lista de estoque
    END LOOP;
  -- Analisar estoque
  END F_ANALISAR_ESTOQUE;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  28/02/2020     Fernandes Brito     0                   Criar função para analisar dados de venda assistida
  /***********************************************************************************************************************/
  FUNCTION F_ANALISAR_VENDA_ASSISTIDA (psCODFILIAL     IN PCFILIAL.CODIGO%TYPE
                                      ,pdDATAINICIAL   IN PCPEDI.DATA%TYPE
                                      ,pdDATAFINAL     IN PCPEDI.DATA%TYPE)
    RETURN TB_ANALISAR_VENDA_ASSISTIDA
    PIPELINED
  IS-- Variáveis internas
    vrDADOS                  T_ANALISAR_VENDA_ASSISTIDA;
    vnQTDE_TV8               NUMBER;
  BEGIN
    FOR DADOS_TV7 IN (SELECT PCPEDI.NUMPED
                            ,PCPEDC.CODFILIAL
                            ,PCPEDI.CODPROD
                            ,PCPEDI.POSICAO
                            ,SUM(PCPEDI.QT) QTDE
                        FROM PCPEDC
                            ,PCPEDI
                       WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
                         AND PCPEDC.DATA BETWEEN pdDATAINICIAL AND pdDATAFINAL
                         AND PCPEDC.CONDVENDA = 7
                         AND PCPEDC.CODFILIAL = psCODFILIAL
                    GROUP BY PCPEDI.NUMPED
                            ,PCPEDC.CODFILIAL
                            ,PCPEDI.CODPROD
                            ,PCPEDI.POSICAO)
    LOOP
      -- Soma as TV8 do produto
      BEGIN
        SELECT SUM(PCPEDI.QT) QT
          INTO vnQTDE_TV8           
          FROM PCPEDC
              ,PCPEDI
         WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
           AND PCPEDC.NUMPEDENTFUT = DADOS_TV7.NUMPED
           AND PCPEDI.CODPROD = DADOS_TV7.CODPROD
           AND PCPEDI.POSICAO = DADOS_TV7.POSICAO
           AND PCPEDC.CONDVENDA = 8;
      EXCEPTION
        WHEN OTHERS THEN
          vnQTDE_TV8 := 0;
      END;
      -- Tem diferença da TV7 para a TV8?
      IF vnQTDE_TV8 <> DADOS_TV7.QTDE THEN
        -- Atualizar dados
        vrDADOS.PROBLEMA             := 'Divergencia entre estoque "PENDENTE DO DEPÓSITO" e o saldo dos pedidos na posição "PENDENTE"';
        vrDADOS.CODFILIAL            := DADOS_TV7.CODFILIAL;
        vrDADOS.CODPROD              := DADOS_TV7.CODPROD;
        vrDADOS.NUMPED_TV7           := DADOS_TV7.NUMPED;
        vrDADOS.QTDE_VENDA_TV7       := DADOS_TV7.QTDE;
        vrDADOS.QTDE_VENDA_TV8       := vnQTDE_TV8;
        -- Retornando os dados para o PIPELINED
        PIPE ROW (vrDADOS);
      -- Tem dif. TV7 para TV8
      END IF;
    -- Lista de itens TV7
    END LOOP;
  -- Função
  END F_ANALISAR_VENDA_ASSISTIDA;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  19/02/2018    Fernandes Brito    0                   Função criada para buscar a data base para inicio do recalculo
  /**********************************************************************************************************************************************************/
  FUNCTION F_BUSCAR_DTBASE RETURN DATE
  IS
    -- Declaração das variáveis internas */
  BEGIN
    -- Peencher variaveis para a pesquisa da PCHISTEST
    vdMAIOR_DATA := F_CONS_HIST('MAIOR');
    -- Select para lozalizar a data do cadastro */
    IF (vdMAIOR_DATA IS NULL AND P_INTERNOS.TIPOCHAMADA <> 'EXTERNA') THEN
      -- Valida se existe PCMOV para o dia de referencia
      BEGIN
        SELECT COUNT(*)
          INTO P_INTERNOS.CONTPCMOV
          FROM PCMOV
         WHERE NVL(CODFILIALNF,CODFILIAL) = P_INTERNOS.CODFILIAL
           AND CODPROD = P_INTERNOS.CODPROD
           AND DTMOV <= P_INTERNOS.DTBASE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          P_INTERNOS.CONTPCMOV := 0;
      END;
    -- Fim busca de cadastro */
    END IF;
    -- Validar data antes de começar
    IF vtPRODUTO.DTCADASTRO < P_INTERNOS.DTBASE THEN
      vdMAIOR_DATA := P_INTERNOS.DTBASE;
    ELSIF vtPRODUTO.DTCADASTRO >= P_INTERNOS.DTBASE THEN
      vdMAIOR_DATA := (vtPRODUTO.DTCADASTRO - 1);
    END IF;
    -- Retorno
    RETURN vdMAIOR_DATA;
  END;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  22/08/2017    Fernandes Brito    0                   Consultar informações do histórico do produto na PCHISTEST
  /**********************************************************************************************************************************************************/
  FUNCTION F_CONS_HIST (psOPERACAO IN VARCHAR2) RETURN VARCHAR2
  IS-- Declaração das variáveis internas
  BEGIN
    -- Contar quantos registros existem
    IF psOPERACAO = 'CONTAR' THEN
      -- Contar
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM PCHISTEST
       WHERE PCHISTEST.CODFILIAL = P_INTERNOS.CODFILIAL
         AND PCHISTEST.CODPROD = P_INTERNOS.CODPROD
         AND PCHISTEST.DATA = P_INTERNOS.DTBASE;
      -- Retornando valor
      RETURN TO_CHAR(vnCONTADOR);
    -- Maior data
    ELSIF psOPERACAO = 'MAIOR' THEN
      -- Buscar maior data
      vsSQL := 'SELECT MAX(DATA)
                  FROM PCHISTEST
                 WHERE CODFILIAL = '||CHR(39)||P_INTERNOS.CODFILIAL||CHR(39)||'
                   AND CODPROD = '||P_INTERNOS.CODPROD;
    IF P_INTERNOS.DTLIMITE IS NOT NULL THEN
      vsSQL := vsSQL||'   AND DATA BETWEEN '||CHR(39)||P_INTERNOS.DTLIMITE||CHR(39)||'AND '||CHR(39)||P_INTERNOS.DTBASE||CHR(39);
    ELSE
      vsSQL := vsSQL||'   AND DATA <= '||CHR(39)||P_INTERNOS.DTBASE||CHR(39);
    END IF;
      EXECUTE IMMEDIATE vsSQL INTO vdMAIOR_DATA;
      -- Retornando valor
      RETURN TO_CHAR(vdMAIOR_DATA);
    -- Dados da PCHISTEST para o monitoramento
    ELSIF psOPERACAO = 'MONITORAMENTO' THEN
      -- Buscar dados do PCHISTEST
        BEGIN
          SELECT PCHISTEST.CODFILIAL
                ,PCHISTEST.CODPROD
                ,PCHISTEST.DATA
                ,PCHISTEST.QTESTGER
                ,PCHISTEST.QTEST
            INTO vtHIST_EST.CODFILIAL
                ,vtHIST_EST.CODPROD
                ,vtHIST_EST.DATA
                ,vtHIST_EST.QTESTGER
                ,vtHIST_EST.QTEST
            FROM PCHISTEST
           WHERE PCHISTEST.CODFILIAL = P_INTERNOS.CODFILIAL
             AND PCHISTEST.CODPROD = P_INTERNOS.CODPROD
             AND PCHISTEST.DATA = P_INTERNOS.DTBASE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vtHIST_EST.CODFILIAL := P_INTERNOS.CODFILIAL;
            vtHIST_EST.CODPROD   := P_INTERNOS.CODPROD;
            vtHIST_EST.DATA      := NULL;
            vtHIST_EST.QTESTGER  := 0;
            vtHIST_EST.QTEST     := 0;
        END;
      -- Retornando valor
      RETURN 'MONITORAMENTO';
    -- Buscar dados
    ELSE
      -- Buscar toda pchistest
      BEGIN
        SELECT PCHISTEST.CODFILIAL
              ,PCHISTEST.CODPROD
              ,PCHISTEST.DATA
              ,PCHISTEST.DTGERACAO
              ,PCHISTEST.QTESTGER
              ,PCHISTEST.QTEST
          INTO vtHIST_EST.CODFILIAL
              ,vtHIST_EST.CODPROD
              ,vtHIST_EST.DATA
              ,vtHIST_EST.DTGERACAO
              ,vtHIST_EST.QTESTGER
              ,vtHIST_EST.QTEST 
          FROM PCHISTEST
         WHERE PCHISTEST.CODFILIAL = P_INTERNOS.CODFILIAL
           AND PCHISTEST.CODPROD = P_INTERNOS.CODPROD
           AND PCHISTEST.DATA = P_INTERNOS.DTBASE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vtHIST_EST.CODFILIAL := P_INTERNOS.CODFILIAL;
          vtHIST_EST.CODPROD   := P_INTERNOS.CODPROD;
          vtHIST_EST.DATA      := P_INTERNOS.DTBASE;
          vtHIST_EST.DTGERACAO := SYSDATE;
          vtHIST_EST.QTESTGER  := 0;
          vtHIST_EST.QTEST     := 0;
      END;
      -- Retornando valor
      RETURN 'TUDO';
    -- Definição da busca
    END IF;
  -- Função
  END F_CONS_HIST;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  22/08/2017    Fernandes Brito    0                   Consultar informações do histórico do produto na PCHISTEST
  /**********************************************************************************************************************************************************/
  FUNCTION F_CONS_HIST_LOTE (psOPERACAO IN VARCHAR2) RETURN VARCHAR2
  IS
    -- Declaração das variáveis internas */
  BEGIN
    -- Contar quantos registros existem */
    IF psOPERACAO = 'CONTAR' THEN
      -- Contar */
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM PCHISTESTLOTE
       WHERE PCHISTESTLOTE.CODFILIAL = P_INTERNOS.CODFILIAL
         AND PCHISTESTLOTE.CODPROD = P_INTERNOS.CODPROD
         AND PCHISTESTLOTE.DATA = P_INTERNOS.DTBASE
         AND PCHISTESTLOTE.NUMLOTE = P_INTERNOS.NUMLOTE;
      -- Retornando valor */
      RETURN TO_CHAR(vnCONTADOR);
    -- Buscar maior data da PCHISTEST */
    ELSIF psOPERACAO = 'MAIOR' THEN
      -- Buscar maior data da PCHISTEST */
      SELECT MAX(DATA)
        INTO vdMAIOR_DATA
        FROM PCHISTESTLOTE
       WHERE PCHISTESTLOTE.CODFILIAL = P_INTERNOS.CODFILIAL
         AND PCHISTESTLOTE.CODPROD = P_INTERNOS.CODPROD
         AND PCHISTESTLOTE.DATA <= P_INTERNOS.DTBASE
         AND PCHISTESTLOTE.NUMLOTE = P_INTERNOS.NUMLOTE;
      -- Retornando valor */
      RETURN TO_CHAR(vdMAIOR_DATA);
    -- Buscar toda PCHISTEST para o monitoramento */
    ELSIF psOPERACAO = 'MONITORAMENTO' THEN
      -- Consultando se a ordem de produção é valida */
        BEGIN
          SELECT PCHISTESTLOTE.CODFILIAL
                ,PCHISTESTLOTE.CODPROD
                ,PCHISTESTLOTE.NUMLOTE
                ,PCHISTESTLOTE.DATA
                ,PCHISTESTLOTE.QT
            INTO vtHIST_LOTE.CODFILIAL
                ,vtHIST_LOTE.CODPROD
                ,vtHIST_LOTE.NUMLOTE
                ,vtHIST_LOTE.DATA
                ,vtHIST_LOTE.QT
            FROM PCHISTESTLOTE
           WHERE PCHISTESTLOTE.CODFILIAL = P_INTERNOS.CODFILIAL
             AND PCHISTESTLOTE.CODPROD = P_INTERNOS.CODPROD
             AND PCHISTESTLOTE.DATA = P_INTERNOS.DTBASE
             AND PCHISTESTLOTE.NUMLOTE = P_INTERNOS.NUMLOTE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vtHIST_LOTE.CODFILIAL := P_INTERNOS.CODFILIAL;
            vtHIST_LOTE.CODPROD   := P_INTERNOS.CODPROD;
            vtHIST_LOTE.NUMLOTE   := P_INTERNOS.NUMLOTE;
            vtHIST_LOTE.DATA      := NULL;
            vtHIST_LOTE.QT        := 0;
        END;
      -- Retornando valor */
      RETURN 'MONITORAMENTO';
    -- Buscar dados */
    ELSE
      -- Consultando se a ordem de produção é valida */
      BEGIN
        SELECT PCHISTESTLOTE.CODFILIAL
              ,PCHISTESTLOTE.CODPROD
              ,PCHISTESTLOTE.NUMLOTE
              ,PCHISTESTLOTE.DTGERACAO
              ,PCHISTESTLOTE.DATA
              ,PCHISTESTLOTE.QT
          INTO vtHIST_LOTE.CODFILIAL
              ,vtHIST_LOTE.CODPROD
              ,vtHIST_LOTE.NUMLOTE
              ,vtHIST_LOTE.DTGERACAO
              ,vtHIST_LOTE.DATA
              ,vtHIST_LOTE.QT
          FROM PCHISTESTLOTE
         WHERE PCHISTESTLOTE.CODFILIAL = P_INTERNOS.CODFILIAL
           AND PCHISTESTLOTE.CODPROD = P_INTERNOS.CODPROD
           AND PCHISTESTLOTE.DATA = P_INTERNOS.DTBASE
           AND PCHISTESTLOTE.NUMLOTE = P_INTERNOS.NUMLOTE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vtHIST_LOTE.CODFILIAL := P_INTERNOS.CODFILIAL;
          vtHIST_LOTE.CODPROD   := P_INTERNOS.CODPROD;
          vtHIST_LOTE.NUMLOTE   := P_INTERNOS.NUMLOTE;
          vtHIST_LOTE.DATA      := P_INTERNOS.DTBASE;
          vtHIST_LOTE.DTGERACAO := SYSDATE;
          vtHIST_LOTE.QT        := 0;
      END;
      -- Retornando valor */
      RETURN 'TUDO';
    -- Fim da definição da busca */
    END IF;
  -- Fim da função */
  END F_CONS_HIST_LOTE;

 /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  02/09/2017    Fernandes Brito    0                   Criada função para consultar o histórico do produto no WMS
  /**********************************************************************************************************************************************************/
  FUNCTION F_CONS_HIST_WMS (psOPERACAO IN VARCHAR2) RETURN VARCHAR2
  IS
    -- Declaração das variáveis internas */
  BEGIN
    -- Contar quantos registros existem */
    IF psOPERACAO = 'CONTAR' THEN
      -- Contar */
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM PCMOVEND
       WHERE PCMOVEND.DATA = P_INTERNOS.DTBASE
         AND PCMOVEND.CODFILIAL = P_INTERNOS.CODFILIAL
         AND PCMOVEND.CODPROD = P_INTERNOS.CODPROD
         AND PCMOVEND.CODOPER = 'T';
      -- Retornando valor */
      RETURN TO_CHAR(vnCONTADOR);
    -- Contar quantos registros existem do lote */
    ELSIF psOPERACAO = 'CONTAR_LOTE' THEN
      -- Contar */
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM PCMOVEND
       WHERE PCMOVEND.DATA = P_INTERNOS.DTBASE
         AND PCMOVEND.CODFILIAL = P_INTERNOS.CODFILIAL
         AND PCMOVEND.CODPROD = P_INTERNOS.CODPROD
         AND PCMOVEND.CODOPER = 'T';
    -- Buscar maior data da PCHISTEST */
    ELSIF psOPERACAO = 'MAIOR' THEN
      -- Buscar maior data da PCHISTEST */
      NULL;
      -- Retornando valor */
      RETURN TO_CHAR(vdMAIOR_DATA);
    -- Buscar toda PCHISTEST para o monitoramento */
    ELSIF psOPERACAO = 'MONITORAMENTO' THEN
      -- Consultando se a ordem de produção é valida */
      NULL;
      -- Retornando valor */
      RETURN 'MONITORAMENTO';
    -- Buscar dados */
    ELSE
      -- Consultando se a ordem de produção é valida */
      NULL;
      -- Retornando valor */
      RETURN 'TUDO';
    -- Fim da definição da busca */
    END IF;
  -- Fim da função */
  END F_CONS_HIST_WMS;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  21/08/2017    Fernandes Brito    0                   Consultar informações e parâmetros do produto
  /**********************************************************************************************************************************************************/
  FUNCTION F_CONS_PRODUTO (psOPERACAO IN VARCHAR2) RETURN VARCHAR2
  IS-- Declaração das variáveis internas
  BEGIN
    IF psOPERACAO = 'CONTAR' THEN
      -- Consultando se a ordem de produção é valida
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM PCPRODUT
       WHERE PCPRODUT.CODPROD = P_INTERNOS.CODPROD;
      -- Retornando valores
      RETURN TO_CHAR(vnCONTADOR);
    ELSE
      -- Consultando se a ordem de produção é valida
      SELECT PCPRODUT.CODPROD
            ,PCPRODUT.DTCADASTRO
            ,PCPRODUT.DTEXCLUSAO
            ,PCPRODUT.ESTOQUEPORLOTE
        INTO vtPRODUTO.CODPROD
            ,vtPRODUTO.DTCADASTRO
            ,vtPRODUTO.DTEXCLUSAO
            ,vtPRODUTO.ESTOQUEPORLOTE
        FROM PCPRODUT
       WHERE PCPRODUT.CODPROD = P_INTERNOS.CODPROD;
      -- Retornando valores
      RETURN 'TUDO';
    END IF;
  -- Função
  END F_CONS_PRODUTO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  21/05/2015     Fernandes Brito                       Criada a Função para buscar dados da PCHISTEST do dia anterior a data informada
  --------------------------------------------------------------------------------------------------------------------------------------*/
  FUNCTION F_RETIRA (pnCODPROD IN PCMOV.CODPROD%TYPE
                    ,pnNUMPED  IN PCMOV.NUMPED%TYPE)
    RETURN TB_RETIRA
    PIPELINED
  IS
    -- Variaveis de uso interno
    vrDADOS                TR_RETIRA;
    vnNUMTRANSFSAIDA       PCTRANSFDEP.NUMTRANSTRANSFSAIDA%TYPE;
    vnNUMTRANSFENT         PCTRANSFDEP.NUMTRANSTRANSFENT%TYPE;
    vnNUMDEVOLTRANSFSAIDA  PCTRANSFDEPDEVOL.NUMTRANSTRANSFSAIDA%TYPE;
    vnNUMDEVOLTRANSFENT    PCTRANSFDEPDEVOL.NUMTRANSTRANSFSAIDA%TYPE;
  BEGIN
    -- Localizando a nota fiscal gerada pela 1436 para enviar o estoque contábil
    SELECT NUMTRANSTRANSFSAIDA
          ,NUMTRANSTRANSFENT
      INTO vnNUMTRANSFSAIDA
          ,vnNUMTRANSFENT
      FROM PCTRANSFDEP
     WHERE CODPROD = pnCODPROD
       AND NUMTRANSVENDA IN (SELECT NUMTRANSVENDA
                               FROM PCMOV
                              WHERE NUMPED = pnNUMPED
                                AND CODOPER = 'S');
    -- Localizando a nota fiscal gerada pela 1436 para devolver o estoque contábil
    SELECT NUMTRANSTRANSFSAIDA
          ,NUMTRANSTRANSFENT
      INTO vnNUMDEVOLTRANSFSAIDA
          ,vnNUMDEVOLTRANSFENT
      FROM PCTRANSFDEPDEVOL
     WHERE CODPROD = pnCODPROD
       AND NUMTRANSENT IN (SELECT NUMTRANSENT
                               FROM PCMOV
                              WHERE NUMPED = pnNUMPED
                                AND CODOPER = 'ED');
    -- Lista de dados para analise
    FOR NOTAS IN (SELECT V.CODPROD
                        ,V.DTMOV
                        ,V.DTMOVLOG
                        ,V.ROTINACAD
                        ,V.ROTINALANC
                        ,V.CODOPER
                        ,V.STATUS
                        ,V.QT
                        ,V.QTCONT
                        ,V.CODFILIALNF
                        ,V.CODFILIAL
                        ,V.CODFILIALRETIRA
                        ,(DECODE(VENDAS.TIPO_TRANSFERENCIA(V.CODFILIAL,V.CODFILIALRETIRA,V.CODFILIALNF),'V','VIRTUAL','R','RETIRA','VR','VIT E RET','NORMAL')) TIPO
                        ,V.NUMPED
                        ,V.NUMTRANSVENDA
                        ,V.NUMNOTA
                        ,V.NUMTRANSENT
                        ,S.CONDVENDA
                        ,S.NUMCUPOM
                        ,V.DTCANCEL
                        ,S.TIPOVENDA
                        ,(SELECT MATRICULA||' - '||NOME_GUERRA FROM PCEMPR WHERE MATRICULA = S.CODEMITENTE) EMITENTE
                        ,S.FINALIDADENFE
                    FROM PCMOV V,
                         PCNFSAID S,
                         PCNFENT E
                   WHERE V.NUMTRANSVENDA = S.NUMTRANSVENDA(+)
                     AND V.NUMTRANSENT = E.NUMTRANSENT(+)
                     AND V.CODPROD = pnCODPROD
                     AND (V.NUMPED = pnNUMPED OR
                          V.NUMTRANSVENDA IN (vnNUMTRANSFSAIDA, vnNUMDEVOLTRANSFSAIDA) OR
                          V.NUMTRANSENT IN (vnNUMTRANSFENT, vnNUMDEVOLTRANSFENT))
                  ORDER BY V.DTMOVLOG) LOOP
      -- Atualização das variaveis de insert
      vrDADOS.CODPROD        := NOTAS.CODPROD;
      vrDADOS.DTMOV          := NOTAS.DTMOV;
      vrDADOS.DTMOVLOG       := NOTAS.DTMOVLOG;
      vrDADOS.ROTINACAD      := NOTAS.ROTINACAD;
      vrDADOS.ROTINALANC     := NOTAS.ROTINALANC;
      vrDADOS.CODOPER        := NOTAS.CODOPER;
      vrDADOS.STATUS         := NOTAS.STATUS;
      vrDADOS.QT             := NOTAS.QT;
      vrDADOS.QTCONT         := NOTAS.QTCONT;
      vrDADOS.FIL_NF         := NOTAS.CODFILIALNF;
      vrDADOS.FILIAL         := NOTAS.CODFILIAL;
      vrDADOS.FIL_RET        := NOTAS.CODFILIALRETIRA;
      vrDADOS.TIPO_TRANSF    := NOTAS.TIPO;
      vrDADOS.NUMPED         := NOTAS.NUMPED;
      vrDADOS.NUMTRANSVENDA  := NOTAS.NUMTRANSVENDA;
      vrDADOS.NUMNOTA        := NOTAS.NUMNOTA;
      vrDADOS.NUMTRANSENT    := NOTAS.NUMTRANSENT;
      vrDADOS.CONDVENDA      := NOTAS.CONDVENDA;
      vrDADOS.NUMCUPOM       := NOTAS.NUMCUPOM;
      vrDADOS.DTCANCEL       := NOTAS.DTCANCEL;
      vrDADOS.TIPOVENDA      := NOTAS.TIPOVENDA;
      vrDADOS.EMITENTE       := NOTAS.EMITENTE;
      vrDADOS.FINALIDADENFE  := NOTAS.FINALIDADENFE;
      -- Retornando os dados do select para o PIPELINED
      PIPE ROW (vrDADOS);
    -- Fim da lista de dados para analise
    END LOOP;
  -- Inserindo Retorno
  RETURN;
  -- Função F_PROCESSO_RETIRA
  END F_RETIRA;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  02/09/2017     Fernandes Brito                       Procedure criada para validar os LOTES para o monitoramento do estoque
  --------------------------------------------------------------------------------------------------------------------------------------*/
  /*  FUNCTION F_VAL_LOTE ()
  RETURN BOOLEAN
  IS
    -- Variaveis de uso interno
  BEGIN
    NULL;
  END F_VAL_LOTE;*/

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  02/09/2017     Fernandes Brito                       Procedure criada para validar o LOTE no WMS para o monitoramento do estoque
  --------------------------------------------------------------------------------------------------------------------------------------*/
  /*  FUNCTION F_VAL_LOTE_WMS ()
  RETURN BOOLEAN
  IS
    -- Variaveis de uso interno
  BEGIN
    NULL;
  END F_VAL_LOTE_WMS;*/

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  02/09/2017     Fernandes Brito                       Procedure criada para validar os estoque no WMS para o monitoramento do estoque
  --------------------------------------------------------------------------------------------------------------------------------------*/
  /*  FUNCTION F_VAL_WMS ()
  RETURN BOOLEAN
  IS
    -- Variaveis de uso interno
  BEGIN
    NULL;
  END F_VAL_WMS;*/

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  20/07/2015     Fernandes Brito                       Criada a Função localizar o utimo inventário do produto
  --------------------------------------------------------------------------------------------------------------------------------------*/
  FUNCTION F_VALIDAR_PERIODO (psCODFILIAL IN PCFILIAL.CODIGO%TYPE
                             ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                             ,pdDATA      IN PCMOV.DTMOV%TYPE DEFAULT NULL)
    RETURN TB_VALIDAR_PERIODO
    PIPELINED
  IS
    -- Variaveis de uso interno
     vrDADOS                   TR_VALIDAR_PERIODO;
     vdDTULTINVENTARIO         PCEST.DTULTINVENT%TYPE;
     vdDATA                    VARCHAR2(10);
     vsANOATUAL                VARCHAR2(4);
     vsANOREF                  VARCHAR2(4);
  BEGIN
    -- Iniciando a variável
    vrDADOS.OBS := 'OK';
    -- Valida se o time de chamada é INTERNA
    IF (pdDATA IS NULL AND pnCODPROD IS NOT NULL) THEN
      -- Localizar data do ultimo inventário
      SELECT TRUNC(PCEST.DTULTINVENT)
        INTO vdDTULTINVENTARIO
        FROM PCEST
       WHERE PCEST.CODPROD = pnCODPROD
         AND PCEST.CODFILIAL = psCODFILIAL;
    ELSE
      vdDTULTINVENTARIO := pdDATA;
    END IF;
    -- Atualizando variavel de data
    vdDATA := '01/'||TO_CHAR(vdDTULTINVENTARIO,'MM/YYYY');
    -- Atualizando o ano de referencia
    vsANOREF := TO_CHAR(vdDTULTINVENTARIO,'YYYY');
    -- Atualizando o ano atual (que estamos)
    vsANOATUAL := TO_CHAR(SYSDATE,'YYYY');
    --Validando se o ano do ultimo inventário esta no mesmo ano atual (com três meses de carencia)
    IF ((TRUNC(SYSDATE) > '31/MAR/'||vsANOATUAL) AND (vsANOREF = vsANOATUAL)) OR
       ((TRUNC(SYSDATE) <= '31/MAR/'||vsANOATUAL) AND (vsANOREF IN (vsANOATUAL,(vsANOATUAL-1)))) THEN
      -- Buscando os meses fechados no fiscal para o período do recalculo
      FOR PERIODO IN (SELECT ANO
                            ,TO_CHAR(TO_DATE('01-'||TO_CHAR(MES)||'-2000','DD/MM/YYYY'),'MONTH','NLS_DATE_LANGUAGE =''BRAZILIAN PORTUGUESE''') AS MES_DESC
                            ,CASE WHEN ANO < TO_NUMBER(PARAMFILIAL.OBTERCOMOVARCHAR2('ANOINICIALFECHAM')) THEN
                              'SIM'
                             ELSE
                               DECODE(ENCERRADO, 'N', DECODE((SELECT COUNT(*)
                                                                FROM PCCONTROLEITEMLIVROFISCAL
                                                               WHERE ENCERRADO = 'S'
                                                                 AND MES = PCCONTROLELIVROFISCAL.MES
                                                                 AND ANO = vsANOREF
                        
                                                                 AND CODFILIAL = psCODFILIAL), 0, 'NÃO', 'PARCIAL'), 'SIM')
                             END  ENCERRADO
                            ,TO_DATE(TO_CHAR(MES)||'/'||TO_CHAR(ANO),'MM/YYYY') DATA
                       FROM PCCONTROLELIVROFISCAL
                       WHERE CODFILIAL = psCODFILIAL
                         AND TO_DATE(TO_CHAR(MES)||'/'||TO_CHAR(ANO),'MM/YYYY') >= TO_DATE(vdDATA,'DD/MM/YYYY')
                    ORDER BY ANO DESC
                            ,MES DESC)
      LOOP
        -- Caso exista algum mês fechado no fiscal
        IF PERIODO.ENCERRADO = 'SIM' THEN
          vrDADOS.DTULTINVENTARIO := vdDTULTINVENTARIO;
          vrDADOS.OBS             := 'O mês de '||PERIODO.MES_DESC||' do ano '||PERIODO.ANO||' esta fechado no fiscal!'||CHR(13)||
                                    ' Para continuar reabra TODOS os meses a serem recalculados através da rotina 1000';
          -- Rertona as informações e sai da função
          PIPE ROW (vrDADOS);
          RETURN;
        -- Fim da validação do mês fechado
        END IF;
      -- Fim da lista de meses dos anos
      END LOOP;
      -- É para verificar se existe PCHISTEST ou movimentações?
      IF pdDATA IS NULL THEN
        -- Peencher variaveis para a pesquisa da PCHISTEST
        P_INTERNOS.CODFILIAL := psCODFILIAL;
        P_INTERNOS.CODPROD   := pnCODPROD;
        P_INTERNOS.DTBASE    := vdDTULTINVENTARIO;
        -- Se existir PCHISTEST para o dia do inventário
        IF F_CONS_HIST('CONTAR') <> '0' THEN
          vrDADOS.DTULTINVENTARIO := vdDTULTINVENTARIO;
        ELSE
          -- Valida se existe PCMOV para o dia de referencia
          BEGIN
            SELECT COUNT(*)
              INTO vnCONTPCMOV
              FROM PCMOV
             WHERE NVL(CODFILIALNF,CODFILIAL) = psCODFILIAL
               AND CODPROD = pnCODPROD
               AND DTMOV = vdDTULTINVENTARIO;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnCONTPCMOV := 0;
          END;
          -- Se existe PCMOV para o dia de referencia
          IF vnCONTPCMOV > 0 THEN
            vrDADOS.DTULTINVENTARIO := vdDTULTINVENTARIO;
            vrDADOS.OBS             := 'No dia do ultimo inventário não existe dados consolidados (PCHISTEST)!'||CHR(13)||
                                      ' Obs.: Existem movimentações para o produto!';
          -- Se não existir PCHISTEST para o dia do inventário
          ELSE
            vrDADOS.DTULTINVENTARIO := vdDTULTINVENTARIO;
            vrDADOS.OBS             := 'No dia do ultimo inventário não existe dados consolidados (PCHISTEST)!'||CHR(13)||
                                       'Para consolidar os dados deste dias use a opção "Recomposição de dados históricos de estoque"';
          END IF;
        END IF;
      -- Fim da validação se existe PCHISTEST ou movimentações.
      END IF;
    -- Caso o inventário não esteja dentro do mesmo ano atual
    ELSE
      -- Caso a chamada seja pela rotina 507
      IF pdDATA IS NULL THEN
        vrDADOS.OBS             := 'A data do ultimo inventário não esta dentro de um período valido para recalculo!'||CHR(13)||
                                  ' A rotina não pode recalcular dados de anos anteriores de forma automática!'||CHR(13)||
                                  ' Este recalculo deve ser autorizado pelos contadores da empresa!';
      ELSE
        vrDADOS.OBS             := 'A data do incial informada não esta dentro de um período valido para recalculo!'||CHR(13)||
                                  ' A rotina não pode recalcular dados de anos anteriores de forma automática!'||CHR(13)||
                                  ' Este recalculo deve ser autorizado pelos contadores da empresa.';
      END IF;
    END IF;
    -- Retornando os dados do select para o PIPELINED
    PIPE ROW (vrDADOS);
    -- Inserindo Retorno
    RETURN;
  -- Fim da função F_VALIDAR_PERIODO
  END F_VALIDAR_PERIODO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  02/04/2020     Fernandes Brito   0                   Criada procedure para recalcular o histórico do estoque de produtos da tabela PCRECALCULOPROD
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_EXECUTAR_LISTA (P_ENTRADA IN TP_ENTRADA)
  IS-- Variáveis de uso interno
    vnCODFILIAL_ANTERIOR     PCRECALCULOPROD.CODFILIAL%TYPE;
    vnCODPROD_ANTERIOR       PCRECALCULOPROD.CODPROD%TYPE;
    vnDTRECALCULO_ANTERIOR   PCRECALCULOPROD.DTRECALCULO%TYPE;

    vnULTIMA_ITERACAO        NUMBER(30);
    vnITERACAO_ATUAL         NUMBER(30);   
  BEGIN
    -- QUANTIDADE DE REGISTROS A SEREM PROCESSADOS
    SELECT 
      COUNT(*) QTD_REGISTROS 
      INTO vnULTIMA_ITERACAO
  	FROM PCRECALCULOPROD      
    -- FILTRO DE REGISTROS A SEREM PROCESSADOS      
    WHERE (P_ENTRADA.CODFILIAL IS NULL OR PCRECALCULOPROD.CODFILIAL = P_ENTRADA.CODFILIAL);    
  
    vnITERACAO_ATUAL := 1;    
    -- Lista de produtos
    FOR DADOS IN (SELECT PCRECALCULOPROD.CODFILIAL
                        ,PCRECALCULOPROD.CODPROD
                        ,PCRECALCULOPROD.DTRECALCULO
                        ,PCRECALCULOPROD.NUMTRANSVENDA
                        ,NVL(PCRECALCULOPROD.QT,0) QTDE
                        ,PCRECALCULOPROD.TIPOREGISTRO
                        ,PCRECALCULOPROD.DTINCLUSAO
                        ,ROWID ID_LINHA
                    FROM PCRECALCULOPROD
                  -- FILTRO DE REGISTROS A SEREM PROCESSADOS
                  WHERE (P_ENTRADA.CODFILIAL IS NULL OR PCRECALCULOPROD.CODFILIAL = P_ENTRADA.CODFILIAL)
                  ORDER BY CODFILIAL, DTRECALCULO, CODPROD)
    LOOP
          
      insert into PCLOG_RECALCULOPROD
      (
        CODFILIAL,
        CODPROD,
        DTLOG,
        DTRECALCULO,
        NUMTRANSVENDA,
        QT,
        DTINCLUSAO
      )
      values
      (
        DADOS.CODFILIAL,
        DADOS.CODPROD,
        SYSDATE,
        DADOS.DTRECALCULO,
        DADOS.NUMTRANSVENDA,
        DADOS.QTDE,
        DADOS.DTINCLUSAO
      );

      -- Corrigir histórico do produto
      UPDATE PCHISTEST
         SET QTESTGER = QTESTGER - DADOS.QTDE
            ,QTEST = QTEST - DADOS.QTDE
       WHERE CODFILIAL = DADOS.CODFILIAL
         AND CODPROD = DADOS.CODPROD
         AND DATA >= DADOS.DTRECALCULO
         AND DATA < TRUNC(DADOS.DTINCLUSAO);

      IF vnITERACAO_ATUAL = 1 THEN
        -- ALIMENTANDO O REGISTRO ANTERIOR PARA A PRIMEIRA ITERAÇÃO
        vnCODFILIAL_ANTERIOR := DADOS.CODFILIAL;
        vnCODPROD_ANTERIOR := DADOS.CODPROD;
        vnDTRECALCULO_ANTERIOR := DADOS.DTRECALCULO;
      END IF;      
	  
      -- REALIZAR CHAMADA DO FINANCEIRO APENAS QUANDO OS REGISTROS FOREM DIFERENTES
      -- UM REGISTRO É DIFERENTE QUANDO QUALQUER UM DE SEUS DADOS DE FILIAL/DATA/PRODUTO MUDAR
      -- O QUE SIGNIFICA QUE TODOS OS REGISTROS REPETIDOS DAQUELA INFORMAÇÃO TIVERAM SEU PROCESSAMENTO FINALIZADO                  
      IF ((vnCODFILIAL_ANTERIOR <> DADOS.CODFILIAL) OR 
         (vnCODPROD_ANTERIOR <> DADOS.CODPROD) OR 
         (vnDTRECALCULO_ANTERIOR <> DADOS.DTRECALCULO))
      THEN
    	  P_RECALCULA_PCFINANC_ESTOQUE(vnDTRECALCULO_ANTERIOR, vnCODFILIAL_ANTERIOR, vnCODPROD_ANTERIOR);             
      END IF;    
    
    	-- O ULTIMO REGISTRO DEVERÁ SER EXECUTADO COM O REGISTO ATUAL QUE ACABOU DE SER ATUALIZADO POIS SERÁ A ULTIMA ITERAÇÃO DO LOOP      
      IF (vnITERACAO_ATUAL = vnULTIMA_ITERACAO) THEN
  	    P_RECALCULA_PCFINANC_ESTOQUE(DADOS.DTRECALCULO, DADOS.CODFILIAL, DADOS.CODPROD);              
      END IF;  
      	  
      -- Marcar registro atualizado
      DELETE PCRECALCULOPROD
      WHERE ROWID = DADOS.ID_LINHA;

      -- DEFININDO REGISTRO ANTERIOR COMO O REGISTRO QUE ACABOU DE SER PROCESSADO
      vnCODFILIAL_ANTERIOR := DADOS.CODFILIAL;  
      vnCODPROD_ANTERIOR := DADOS.CODPROD;  
      vnDTRECALCULO_ANTERIOR := DADOS.DTRECALCULO;    
      	   
      -- Incrementando iteração dos itens filtrados em processamento
      vnITERACAO_ATUAL := vnITERACAO_ATUAL + 1;  	   
	  
    -- Listsa de produtos
    END LOOP;
  -- Procedure
  END PRC_EXECUTAR_LISTA;

 PROCEDURE VALIDA_DTPRIMERIAMOVIMENTACAO(PCODFILIAL IN VARCHAR2)
  IS
    vsVALORPARAMETRO  VARCHAR2(1000);
  BEGIN
    BEGIN
      IF PARAMFILIAL.OBTERCOMODATE('DATAPRIMERIAMOVIMENTACAO', PCODFILIAL) IS NULL THEN
        UPDATE PCPARAMFILIAL SET
          PCPARAMFILIAL.VALOR = (SELECT TO_CHAR(MIN(DTMOV), 'DD/MM/YYYY')
                                 FROM PCMOV
                                WHERE CODFILIAL = PCODFILIAL)
         WHERE PCPARAMFILIAL.NOME = 'DATAPRIMERIAMOVIMENTACAO'
           AND PCPARAMFILIAL.CODFILIAL = PCODFILIAL;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        vsVALORPARAMETRO := '';
    END;
  END;

  /************************************************************************************************************
  ---------------------------------- Historico ----------------------------------------------------------------
      Data        Responsavel    Comentarios
  ------------  ---------------  ------------------------------------------------------------------------------
   10/11/2017   Fernandes Brito  Criada procedure para gravar PCHISTEST com base nos dados da tabela PCHISTESTFILA
  *************************************************************************************************************/
  PROCEDURE PRC_ARMAZENARSALDOSESTOQUE(psCODFILIAL IN PCMOV.CODFILIAL%TYPE DEFAULT NULL)
  IS
    -- Declaração do cursor usado na gravação do PCHISTEST */
    CURSOR vcCURSOR_PRODUTOS IS
      SELECT * FROM PCHISTESTFILA
       WHERE PCHISTESTFILA.CODFILIAL <> '99'
         AND (DECODE(psCODFILIAL,'99',NULL,psCODFILIAL) IS NULL
          OR PCHISTESTFILA.CODFILIAL = psCODFILIAL)
		  ORDER BY CODFILIAL, DATA;
    -- Variáveis internas */
    TYPE TROW_TYPE IS TABLE OF vcCURSOR_PRODUTOS%ROWTYPE;
    TROW               TROW_TYPE;
    vsCODFILIAL         PCFILIAL.CODIGO%TYPE;
  vdDATA_ATUALIZADA   DATE;
  BEGIN
    VALIDA_DTPRIMERIAMOVIMENTACAO(psCODFILIAL);
    -- Abrindo curso */
    OPEN vcCURSOR_PRODUTOS;
    LOOP
      -- Buscando as próximas 500 linhas */
      FETCH vcCURSOR_PRODUTOS BULK COLLECT
        INTO TROW LIMIT 5000;
      -- Vá até o fim do cursor */
      EXIT WHEN TROW.COUNT = 0;
      -- Insira os dados do cursor na PCHISTEST */
      FOR NX IN 1 .. TROW.COUNT LOOP

      IF (vdDATA_ATUALIZADA IS NULL OR
            vdDATA_ATUALIZADA <> TROW(NX).DATA OR
            vsCODFILIAL IS NULL OR
            vsCODFILIAL <> TROW(NX).CODFILIAL) THEN

          DELETE
            FROM PCHISTEST
           WHERE DATA = TROW(NX).DATA
             AND CODFILIAL = TROW(NX).CODFILIAL;

          vdDATA_ATUALIZADA := TROW(NX).DATA;
          vsCODFILIAL       := TROW(NX).CODFILIAL;
        END IF;

        INSERT INTO PCHISTEST
          (CODFILIAL,
           CODPROD,
           NBM,
           DESCRICAO,
           CLASSIFICFISCAL,
           UNIDADE,
           DATA,
           QTEST,
           QTESTGER,
           QTRESERV,
           QTBLOQUEADA,
           QTPENDENTE,
           QTULTENT,
           QTINDENIZ,
           CUSTOCONT,
           CUSTOREAL,
           CUSTOFIN,
           CUSTOREP,
           CUSTOULTENT,
           VALORULTENT,
           CUSTODOLAR,
           CUSTOREALSEMST,
           CUSTOULTENTMED,
           CUSTOULTPEDCOMPRA,
           CUSTOFORNEC,
           VALORULTENTMED,
           DTGERACAO,
           QTTRANSITO,
           QTFRENTELOJA,
           CUSTOFINSEMST,
           CUSTOULTENTFINSEMST,
           CUSTOULTENTSEMST,
           CUSTOFORNECSEMST,
           CUSTONFSEMSTGUIAULTENT,
           CUSTONFSEMST,
           CUSTONFSEMSTGUIAULTENTTAB,
           CUSTONFSEMSTTAB,
           CUSTOPROXIMACOMPRA,
           CUSTOPROXIMACOMPRASEMST,
           CUSTOREALLIQ,
           CUSTOULTENTANT,
           CUSTOULTENTCONT,
           CUSTOULTENTFIN,
           CUSTOULTENTLIQ,
           DTULTENT,
           VLCUSTODIAFIN,
           VLCUSTODIAREAL,
           VLCUSTOMESFIN,
           VLCUSTOMESFINANT,
           VLCUSTOMESREAL,
           VLCUSTOMESREALANT,
           VLFRETECONHECULTENT,
           VLFRETECONHECULTENTTAB,
           VLIMPORTACAOFCI,
           VLPARCELAIMPFCI,
           VLSTGUIAULTENT,
           VLSTGUIAULTENTTAB,
           VLSTULTENT,
           VLSTULTENTTAB,
           VLULTENTCONTSEMST,
           VLULTPCOMPRA,
           BASEBCR,
           STBCR,
           VLIPIULTENT,
           BASEIPIULTENT,
           PERCIPIULTENT,
           QTTRANSITOTV13,
           DV,
           CODAUXILIAR,
           CODPRODSINTEGRA,
           EMBALAGEM,
           DTEXCLUSAOPROD,
           TIPOMERC,
           TIPOMERCDEPTO,
           CODGENEROFISCAL,
           PERCST,
           PISCOFINSRETIDO,
           PERPIS,
           PERCOFINS,
           CODINTERNO,
           ALIQICMSVIGENTE,
           SITTRIBUT,
           CODICM,
           CODCEST,
           QTESTOQUEEMTERCEIRO,
           QTESTOQUEDETERCEIRO,
           QTTRANSITOTV10,
           CUSTOFISCAL,
           CUSTOULTENTFISCAL)
        VALUES
          (TROW(NX).CODFILIAL,
           TROW(NX).CODPROD,
           TROW(NX).NBM,
           SUBSTR(TROW(NX).DESCRICAO, 0, 40),
           TROW(NX).CLASSIFICFISCAL,
           TROW(NX).UNIDADE,
           TROW(NX).DATA,
           TROW(NX).QTEST,
           TROW(NX).QTESTGER,
           TROW(NX).QTRESERV,
           TROW(NX).QTBLOQUEADA,
           TROW(NX).QTPENDENTE,
           TROW(NX).QTULTENT,
           TROW(NX).QTINDENIZ,
           TROW(NX).CUSTOCONT,
           TROW(NX).CUSTOREAL,
           TROW(NX).CUSTOFIN,
           TROW(NX).CUSTOREP,
           TROW(NX).CUSTOULTENT,
           TROW(NX).VALORULTENT,
           TROW(NX).CUSTODOLAR,
           TROW(NX).CUSTOREALSEMST,
           TROW(NX).CUSTOULTENTMED,
           TROW(NX).CUSTOULTPEDCOMPRA,
           TROW(NX).CUSTOFORNEC,
           TROW(NX).VALORULTENTMED,
           TROW(NX).DTGERACAO,
           TROW(NX).QTTRANSITO,
           TROW(NX).QTFRENTELOJA,
           TROW(NX).CUSTOFINSEMST,
           TROW(NX).CUSTOULTENTFINSEMST,
           TROW(NX).CUSTOULTENTSEMST,
           TROW(NX).CUSTOFORNECSEMST,
           TROW(NX).CUSTONFSEMSTGUIAULTENT,
           TROW(NX).CUSTONFSEMST,
           TROW(NX).CUSTONFSEMSTGUIAULTENTTAB,
           TROW(NX).CUSTONFSEMSTTAB,
           TROW(NX).CUSTOPROXIMACOMPRA,
           TROW(NX).CUSTOPROXIMACOMPRASEMST,
           TROW(NX).CUSTOREALLIQ,
           TROW(NX).CUSTOULTENTANT,
           TROW(NX).CUSTOULTENTCONT,
           TROW(NX).CUSTOULTENTFIN,
           TROW(NX).CUSTOULTENTLIQ,
           TROW(NX).DTULTENT,
           TROW(NX).VLCUSTODIAFIN,
           TROW(NX).VLCUSTODIAREAL,
           TROW(NX).VLCUSTOMESFIN,
           TROW(NX).VLCUSTOMESFINANT,
           TROW(NX).VLCUSTOMESREAL,
           TROW(NX).VLCUSTOMESREALANT,
           TROW(NX).VLFRETECONHECULTENT,
           TROW(NX).VLFRETECONHECULTENTTAB,
           TROW(NX).VLIMPORTACAOFCI,
           TROW(NX).VLPARCELAIMPFCI,
           TROW(NX).VLSTGUIAULTENT,
           TROW(NX).VLSTGUIAULTENTTAB,
           TROW(NX).VLSTULTENT,
           TROW(NX).VLSTULTENTTAB,
           TROW(NX).VLULTENTCONTSEMST,
           TROW(NX).VLULTPCOMPRA,
           TROW(NX).BASEBCR,
           TROW(NX).STBCR,
           TROW(NX).VLIPIULTENT,
           TROW(NX).BASEIPIULTENT,
           TROW(NX).PERCIPIULTENT,
           TROW(NX).QTTRANSITOTV13,
           TROW(NX).DV,
           TROW(NX).CODAUXILIAR,
           TROW(NX).CODPRODSINTEGRA,
           TROW(NX).EMBALAGEM,
           TROW(NX).DTEXCLUSAOPROD,
           TROW(NX).TIPOMERC,
           TROW(NX).TIPOMERCDEPTO,
           TROW(NX).CODGENEROFISCAL,
           TROW(NX).PERCST,
           TROW(NX).PISCOFINSRETIDO,
           TROW(NX).PERPIS,
           TROW(NX).PERCOFINS,
           TROW(NX).CODINTERNO,
           TROW(NX).ALIQICMSVIGENTE,
           TROW(NX).SITTRIBUT,
           TROW(NX).CODICM,
           TROW(NX).CODCEST,
           TROW(NX).QTESTOQUEEMTERCEIRO,
           TROW(NX).QTESTOQUEDETERCEIRO,
           TROW(NX).QTTRANSITOTV10,
           TROW(NX).CUSTOFISCAL,
           TROW(NX).CUSTOULTENTFISCAL);
      -- DELETA A FILA PARA NÃO OCORRER ERRO DE CHAVE PRIMÁRIA
      DELETE
        FROM PCHISTESTFILA
       WHERE DATA = TROW(NX).DATA
         AND CODFILIAL = TROW(NX).CODFILIAL
         AND CODPROD = TROW(NX).CODPROD;
      -- Fim da lista do cursor */
        COMMIT WORK;
	  END LOOP;
      -- Confirmando os registros */
      COMMIT WORK;
    -- Fim do cursor */
    END LOOP;
    -- Fechar cursor */
    CLOSE vcCURSOR_PRODUTOS;
    -- Confirmando registros */
    COMMIT;
  -- Fim da procedure */
  END PRC_ARMAZENARSALDOSESTOQUE;
  
  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  28/06/2024     Davi Bernado        DDESTOQUE-18448     Criar procedure para criar pchistest pela rotina 504
  /***********************************************************************************************************************/
  PROCEDURE PRC_ARMAZENARSALDOSESTOQUE_504
  IS
    -- Declaração do cursor usado na gravação do PCHISTEST */
    CURSOR vcCURSOR_PRODUTOS IS
      SELECT * FROM PCHISTESTFILA
       WHERE PCHISTESTFILA.CODFILIAL <> '99'
	   ORDER BY CODFILIAL, DATA;
    -- Variáveis internas */
    TYPE TROW_TYPE IS TABLE OF vcCURSOR_PRODUTOS%ROWTYPE;
    TROW               TROW_TYPE;
    vsCODFILIAL         PCFILIAL.CODIGO%TYPE;
  vdDATA_ATUALIZADA   DATE;
  BEGIN
    -- Abrindo curso */
    OPEN vcCURSOR_PRODUTOS;
    LOOP
      -- Buscando as próximas 500 linhas */
      FETCH vcCURSOR_PRODUTOS BULK COLLECT
        INTO TROW LIMIT 5000;
      -- Vá até o fim do cursor */
      EXIT WHEN TROW.COUNT = 0;
      -- Insira os dados do cursor na PCHISTEST */
      FOR NX IN 1 .. TROW.COUNT LOOP

      IF (vdDATA_ATUALIZADA IS NULL OR
            vdDATA_ATUALIZADA <> TROW(NX).DATA OR
            vsCODFILIAL IS NULL OR
            vsCODFILIAL <> TROW(NX).CODFILIAL) THEN

          DELETE
            FROM PCHISTEST
           WHERE DATA = TROW(NX).DATA
             AND CODFILIAL = TROW(NX).CODFILIAL;

          vdDATA_ATUALIZADA := TROW(NX).DATA;
          vsCODFILIAL       := TROW(NX).CODFILIAL;

        END IF;

        INSERT INTO PCHISTEST
          (CODFILIAL,
           CODPROD,
           NBM,
           DESCRICAO,
           CLASSIFICFISCAL,
           UNIDADE,
           DATA,
           QTEST,
           QTESTGER,
           QTRESERV,
           QTBLOQUEADA,
           QTPENDENTE,
           QTULTENT,
           QTINDENIZ,
           CUSTOCONT,
           CUSTOREAL,
           CUSTOFIN,
           CUSTOREP,
           CUSTOULTENT,
           VALORULTENT,
           CUSTODOLAR,
           CUSTOREALSEMST,
           CUSTOULTENTMED,
           CUSTOULTPEDCOMPRA,
           CUSTOFORNEC,
           VALORULTENTMED,
           DTGERACAO,
           QTTRANSITO,
           QTFRENTELOJA,
           CUSTOFINSEMST,
           CUSTOULTENTFINSEMST,
           CUSTOULTENTSEMST,
           CUSTOFORNECSEMST,
           CUSTONFSEMSTGUIAULTENT,
           CUSTONFSEMST,
           CUSTONFSEMSTGUIAULTENTTAB,
           CUSTONFSEMSTTAB,
           CUSTOPROXIMACOMPRA,
           CUSTOPROXIMACOMPRASEMST,
           CUSTOREALLIQ,
           CUSTOULTENTANT,
           CUSTOULTENTCONT,
           CUSTOULTENTFIN,
           CUSTOULTENTLIQ,
           DTULTENT,
           VLCUSTODIAFIN,
           VLCUSTODIAREAL,
           VLCUSTOMESFIN,
           VLCUSTOMESFINANT,
           VLCUSTOMESREAL,
           VLCUSTOMESREALANT,
           VLFRETECONHECULTENT,
           VLFRETECONHECULTENTTAB,
           VLIMPORTACAOFCI,
           VLPARCELAIMPFCI,
           VLSTGUIAULTENT,
           VLSTGUIAULTENTTAB,
           VLSTULTENT,
           VLSTULTENTTAB,
           VLULTENTCONTSEMST,
           VLULTPCOMPRA,
           BASEBCR,
           STBCR,
           VLIPIULTENT,
           BASEIPIULTENT,
           PERCIPIULTENT,
           QTTRANSITOTV13,
           DV,
           CODAUXILIAR,
           CODPRODSINTEGRA,
           EMBALAGEM,
           DTEXCLUSAOPROD,
           TIPOMERC,
           TIPOMERCDEPTO,
           CODGENEROFISCAL,
           PERCST,
           PISCOFINSRETIDO,
           PERPIS,
           PERCOFINS,
           CODINTERNO,
           ALIQICMSVIGENTE,
           SITTRIBUT,
           CODICM,
           CODCEST,
           QTESTOQUEEMTERCEIRO,
           QTESTOQUEDETERCEIRO,
           QTTRANSITOTV10,
           CUSTOFISCAL,
           CUSTOULTENTFISCAL)
        VALUES
          (TROW(NX).CODFILIAL,
           TROW(NX).CODPROD,
           TROW(NX).NBM,
           SUBSTR(TROW(NX).DESCRICAO, 0, 40),
           TROW(NX).CLASSIFICFISCAL,
           TROW(NX).UNIDADE,
           TROW(NX).DATA,
           TROW(NX).QTEST,
           TROW(NX).QTESTGER,
           TROW(NX).QTRESERV,
           TROW(NX).QTBLOQUEADA,
           TROW(NX).QTPENDENTE,
           TROW(NX).QTULTENT,
           TROW(NX).QTINDENIZ,
           TROW(NX).CUSTOCONT,
           TROW(NX).CUSTOREAL,
           TROW(NX).CUSTOFIN,
           TROW(NX).CUSTOREP,
           TROW(NX).CUSTOULTENT,
           TROW(NX).VALORULTENT,
           TROW(NX).CUSTODOLAR,
           TROW(NX).CUSTOREALSEMST,
           TROW(NX).CUSTOULTENTMED,
           TROW(NX).CUSTOULTPEDCOMPRA,
           TROW(NX).CUSTOFORNEC,
           TROW(NX).VALORULTENTMED,
           TROW(NX).DTGERACAO,
           TROW(NX).QTTRANSITO,
           TROW(NX).QTFRENTELOJA,
           TROW(NX).CUSTOFINSEMST,
           TROW(NX).CUSTOULTENTFINSEMST,
           TROW(NX).CUSTOULTENTSEMST,
           TROW(NX).CUSTOFORNECSEMST,
           TROW(NX).CUSTONFSEMSTGUIAULTENT,
           TROW(NX).CUSTONFSEMST,
           TROW(NX).CUSTONFSEMSTGUIAULTENTTAB,
           TROW(NX).CUSTONFSEMSTTAB,
           TROW(NX).CUSTOPROXIMACOMPRA,
           TROW(NX).CUSTOPROXIMACOMPRASEMST,
           TROW(NX).CUSTOREALLIQ,
           TROW(NX).CUSTOULTENTANT,
           TROW(NX).CUSTOULTENTCONT,
           TROW(NX).CUSTOULTENTFIN,
           TROW(NX).CUSTOULTENTLIQ,
           TROW(NX).DTULTENT,
           TROW(NX).VLCUSTODIAFIN,
           TROW(NX).VLCUSTODIAREAL,
           TROW(NX).VLCUSTOMESFIN,
           TROW(NX).VLCUSTOMESFINANT,
           TROW(NX).VLCUSTOMESREAL,
           TROW(NX).VLCUSTOMESREALANT,
           TROW(NX).VLFRETECONHECULTENT,
           TROW(NX).VLFRETECONHECULTENTTAB,
           TROW(NX).VLIMPORTACAOFCI,
           TROW(NX).VLPARCELAIMPFCI,
           TROW(NX).VLSTGUIAULTENT,
           TROW(NX).VLSTGUIAULTENTTAB,
           TROW(NX).VLSTULTENT,
           TROW(NX).VLSTULTENTTAB,
           TROW(NX).VLULTENTCONTSEMST,
           TROW(NX).VLULTPCOMPRA,
           TROW(NX).BASEBCR,
           TROW(NX).STBCR,
           TROW(NX).VLIPIULTENT,
           TROW(NX).BASEIPIULTENT,
           TROW(NX).PERCIPIULTENT,
           TROW(NX).QTTRANSITOTV13,
           TROW(NX).DV,
           TROW(NX).CODAUXILIAR,
           TROW(NX).CODPRODSINTEGRA,
           TROW(NX).EMBALAGEM,
           TROW(NX).DTEXCLUSAOPROD,
           TROW(NX).TIPOMERC,
           TROW(NX).TIPOMERCDEPTO,
           TROW(NX).CODGENEROFISCAL,
           TROW(NX).PERCST,
           TROW(NX).PISCOFINSRETIDO,
           TROW(NX).PERPIS,
           TROW(NX).PERCOFINS,
           TROW(NX).CODINTERNO,
           TROW(NX).ALIQICMSVIGENTE,
           TROW(NX).SITTRIBUT,
           TROW(NX).CODICM,
           TROW(NX).CODCEST,
           TROW(NX).QTESTOQUEEMTERCEIRO,
           TROW(NX).QTESTOQUEDETERCEIRO,
           TROW(NX).QTTRANSITOTV10,
           TROW(NX).CUSTOFISCAL,
           TROW(NX).CUSTOULTENTFISCAL);
      -- Fim da lista do cursor */
      END LOOP;
      -- Confirmando os registros */
      COMMIT WORK;
    -- Fim do cursor */
    END LOOP;
    -- Fechar cursor */
    CLOSE vcCURSOR_PRODUTOS;
    -- Confirmando registros */
    COMMIT;
  -- Fim da procedure */
  END PRC_ARMAZENARSALDOSESTOQUE_504;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para atualizar dados da ordem de produção
  /***********************************************************************************************************************/
  PROCEDURE PRC_ATUALIZAR_ORDEM_PRODUCAO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
  BEGIN
    -- Atualiza dados das ordem de produção dos produtos
    vSQL :='BEGIN
              FOR REGISTROS IN (SELECT NUMOP
                                      ,CODPROD
                                  FROM PCOPI
                                 WHERE NUMOP IN (SELECT NUMOP
                                                   FROM PCOPC
                                                  WHERE POSICAO = ''P''
                                                    AND CODFILIAL = ' ||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||')';
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL||' AND PCOPI.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL||' AND PCOPI.CODPROD IN ('||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL ||'GROUP BY NUMOP, CODPROD)
      LOOP
        UPDATE PCOPI
           SET QTRESERVATUAL = QTNECESSIDADE
              ,QTREQUISITADO = 0
         WHERE CODPROD = REGISTROS.CODPROD
           AND NUMOP = REGISTROS.NUMOP;
      END LOOP;
    END;';
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Executar Sql
    EXECUTE IMMEDIATE TRANSLATE(vSQL, CHR(10)||CHR(13),'  ');
    -- Atualiza QTRESERVATUAL dos ordens de produção dos produtos
    vSQL :='BEGIN
              FOR REGISTROS IN (SELECT NUMOP, CODPROD
                                      ,SUM(CASE
                                             WHEN (NVL(QTPRODUZIDA,0)<=NVL(QTPRODUZIR,0)) THEN
                                              (qtproduzida * qtformula)
                                           ELSE
                                             (qtproduzir * qtformula)
                                           END) AS qtrequisitado
                                  FROM (SELECT PCOPC.NUMOP,
                                               PCOPI.CODPROD,
                                               PCOPC.QTPRODUZIR,
                                               PCOPC.QTPRODUZIDA,
                                               PCOPI.QTNECESSIDADE,
                                               (PCOPI.QTNECESSIDADE / PCOPC.QTPRODUZIR) QTFORMULA
                                          FROM PCOPC, PCOPI
                                         WHERE PCOPC.NUMOP = PCOPI.NUMOP
                                           AND PCOPC.CODFILIAL = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||'
                                           AND PCOPC.POSICAO = ''P'''||CHR(13);
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL||' AND PCOPI.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL||' AND PCOPI.CODPROD IN ('||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    END IF;
    
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||' AND PCOPI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL ||') GROUP BY NUMOP, CODPROD)
      LOOP
        UPDATE PCOPI
           SET QTREQUISITADO = ROUND(NVL (QTREQUISITADO, 0) + REGISTROS.QTREQUISITADO,6)
              ,QTRESERVATUAL = ROUND(NVL(QTRESERVATUAL,0)- NVL(REGISTROS.QTREQUISITADO,0),6)
         WHERE CODPROD = REGISTROS.CODPROD
           AND NUMOP = REGISTROS.NUMOP;
      END LOOP;
    END;';
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL,CODREGRA) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Executar Sql
    EXECUTE IMMEDIATE TRANSLATE(VSQL, CHR(10)||CHR(13),'  ');
  -- Atualizar ordem_producao
  END PRC_ATUALIZAR_ORDEM_PRODUCAO;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar parâmetros.
  /***********************************************************************************************************************/
  PROCEDURE PRC_BUSCAR_PARAMETROS (pENTRADA IN TP_ENTRADA)
  IS
  BEGIN
    -- Buscar menor data
    BEGIN
      SELECT MIN(PCFINANC.DATA)
        INTO vDATAFIN
        FROM PCFINANC;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vDATAFIN := TRUNC(SYSDATE);
    END;
    -- Validar data
    IF vDATAFIN IS NULL THEN
      vDATAFIN := TRUNC(SYSDATE);
    END IF;
    -- Buscar menor data
    BEGIN
      SELECT MIN(PCPEDC.DATA)
        INTO vDATAPEDRESERVADA
        FROM PCPEDC,
             PCPEDI
       WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
         AND PCPEDC.POSICAO IN ('L', 'M')
         AND PCPEDC.CODFILIAL = pENTRADA.CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vDATAPEDRESERVADA := trunc(SYSDATE);
    END;
    -- Validar data
    IF vDATAPEDRESERVADA IS NULL THEN
      vDATAPEDRESERVADA := TRUNC(SYSDATE);
    END IF;
    -- Buscar menor data
    BEGIN
      SELECT MIN(PCPEDC.DATA)
        INTO vDATAPEDRESERVADARETIRA
        FROM PCPEDC,
             PCPEDI
       WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
         AND PCPEDC.POSICAO IN ('L', 'M')
         AND NVL(PCPEDI.CODFILIALRETIRA,PCPEDC.CODFILIAL) = pENTRADA.CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vDATAPEDRESERVADARETIRA := trunc(SYSDATE);
    END;
    -- Validar data
    IF vDATAPEDRESERVADARETIRA IS NULL THEN
      vDATAPEDRESERVADARETIRA := TRUNC(SYSDATE);
    END IF;
    -- Validar data
    IF vDATAPEDRESERVADARETIRA < vDATAPEDRESERVADA THEN
      vDATAPEDRESERVADA := vDATAPEDRESERVADARETIRA;
    END IF;
    -- Buscar menor data
    BEGIN
      SELECT MIN(PCPEDC.DATA)
        INTO vDATAPEDPENDENTE
        FROM PCPEDC,
             PCPEDI
       WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
         AND PCPEDC.POSICAO IN ('B', 'P')
         AND PCPEDC.CODFILIAL = pENTRADA.CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vDATAPEDPENDENTE := trunc(SYSDATE);
    END;
    -- Validar data
    IF vDATAPEDPENDENTE IS NULL THEN
      vDATAPEDPENDENTE := TRUNC(SYSDATE);
    END IF;
    -- Buscar menor data
    BEGIN
      SELECT MIN(PCPEDC.DATA)
        INTO vDATAPEDPENDENTERETIRA
        FROM PCPEDC,
             PCPEDI
       WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
         AND PCPEDC.POSICAO IN ('B', 'P')
         AND NVL(PCPEDI.CODFILIALRETIRA,PCPEDC.CODFILIAL) = pENTRADA.CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vDATAPEDPENDENTERETIRA := trunc(SYSDATE);
    END;
    -- Validar data
    IF vDATAPEDPENDENTERETIRA IS NULL THEN
      vDATAPEDPENDENTERETIRA := TRUNC(SYSDATE);
    END IF;
    -- Validar data
    IF vDATAPEDPENDENTERETIRA < vDATAPEDPENDENTE THEN
      vDATAPEDPENDENTE := vDATAPEDPENDENTERETIRA;
    END IF;
    -- Utiliza central de faturamento?
    BEGIN
      SELECT NVL(VALOR, 'N')
        INTO vUTILIZACENTRALFATURAMENTO
        FROM PCPARAMFILIAL
       WHERE NOME = 'UTILIZACENTRALFATURAMENTO';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20000,'Parâmetro: '||'UTILIZACENTRALFATURAMENTO'||' não cadastrado.');
    END;
    -- Utiliza estoque por depósito?
    BEGIN
      SELECT NVL(VALOR, 'N')
        INTO vUTILIZAESTOQUEPORDEPOSITO
        FROM PCPARAMFILIAL
       WHERE UPPER(NOME) = 'UTILIZAESTOQUEDEPOSITO'
         AND CODFILIAL = pENTRADA.CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20000,'Parâmetro: '||'UTILIZAESTOQUEDEPOSITO'||' não cadastrado.');
    END;
  -- Buscar parametros
  END PRC_BUSCAR_PARAMETROS;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  19/01/2015     Fernandes Brito                       Recalcular estoque
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure buscar as movimentações sem usar a função F_TODAS_MOVIMENTACOES
                                                       e buscar os saldos anteriores sem usar a função F_DADOS_HISTEST_ANTERIOR
  08/09/2016     Fernandes Brito                       Incluida a função CLOSE para fechar as variáveis vcCURSOR_EXT e vrDADOS e assim
                                                       evitar problemas com lixo no cursor
  22/08/2016     Fernandes Brito                       Alterada para validar o tipo de chamada ao alterar a data final. Caso o tipo de chamada
                                                       seja 'ATUALIZACAO_DIARIA' não é necessário alterar a data final.
  03/04/2020     Fernandes Brito                       Alterada a procedure para retirar as validações referentes ao tipo de chamada 'ATUALIZACAO_DIARIA'
                                                       Estes recursos estavam em descontinuados.
  Observações:
  Para saber mais sobre o parâmetro "psTIPOCHAMADA" veja cabeçalho da procedure PRC_RECALCULO
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_CORRIGIR_PCHISTEST (P_ENTRADA IN TP_ENTRADA)
  IS
    -- Variaveis de uso interno
    vdDTFINAL           PCHISTEST.DATA%TYPE;
    vrPCHISTEST         PCHISTEST%ROWTYPE;
    vcCURSOR            SYS_REFCURSOR;
    vsTEM_MOV_PERIODO   VARCHAR2(1) := 'N';
  BEGIN
    /*Assinando chamada*/
    IF vsFUNCAO_EXECUTADA IS NULL THEN
      vsFUNCAO_EXECUTADA := 'PRC_CORRIGIR_PCHISTEST';
    END IF;
    -- Preencher parametros internos
    P_INTERNOS.CODFILIAL       := P_ENTRADA.CODFILIAL;
    P_INTERNOS.CODPROD         := P_ENTRADA.CODPROD;
    P_INTERNOS.DTINICIAL       := P_ENTRADA.DTINICIAL;
    P_INTERNOS.DTFINAL         := P_ENTRADA.DTFINAL;
    P_INTERNOS.DTLIMITE        := P_ENTRADA.DTLIMITE;
    P_INTERNOS.DTBASE          := (P_ENTRADA.DTINICIAL - 1);
    P_INTERNOS.TIPOCHAMADA     := P_ENTRADA.TIPOCHAMADA;
    P_INTERNOS.USA_FUNCAO_1070 := P_ENTRADA.USA_FUNCAO_1070;
    -- Verificando se a data final é valida
    IF (P_INTERNOS.DTFINAL >= TRUNC(SYSDATE) AND P_INTERNOS.TIPOCHAMADA <> 'EXTERNA') THEN
      vdDTFINAL := (TRUNC(SYSDATE)-1);
    ELSE
      vdDTFINAL := P_INTERNOS.DTFINAL;
    END IF;
    -- Atualizando dados para consultar cadastro
    vtPRODUTO.DTCADASTRO := NULL;
    vsRETORNO            := F_CONS_PRODUTO(NULL);

    -- Limpar as tabelas
    PRC_LIMPAR_SALDOS;
    -- Inserir lista de dias
    PRC_INS_LISTA_DIAS (P_INTERNOS.DTBASE,P_INTERNOS.DTFINAL);
    -- Verifica se faz atualizações gerenciais e contábeis
    IF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') = 'CONTABIL' THEN
      -- Inserir saldo das movimentações contabeis
      PRC_MOV_CONT (P_INTERNOS.CODFILIAL,P_INTERNOS.CODPROD,P_INTERNOS.DTBASE,P_INTERNOS.DTFINAL,P_INTERNOS.TIPOCHAMADA);
    ELSIF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') = 'GERENCIAL' THEN
      -- Inserir saldo das movimentações contabeis
      PRC_MOV_GER (P_INTERNOS.CODFILIAL,P_INTERNOS.CODPROD,P_INTERNOS.DTBASE,P_INTERNOS.DTFINAL);
    ELSE
      -- Inserir saldo das movimentações gerenciais e contabeis
      PRC_MOV_CONT (P_INTERNOS.CODFILIAL,P_INTERNOS.CODPROD,P_INTERNOS.DTBASE,P_INTERNOS.DTFINAL,P_INTERNOS.TIPOCHAMADA);
      PRC_MOV_GER (P_INTERNOS.CODFILIAL,P_INTERNOS.CODPROD,P_INTERNOS.DTBASE,P_INTERNOS.DTFINAL);
    END IF;
    -- Se existir movimentação antes da data de cadastro */
    IF P_INTERNOS.CONTPCMOV > 0 THEN
      -- Insere motivo pelo qual não recalculou o produto */
      vsSQL := 'INSERT
                  INTO PCPRODNAORECALCULADO (FUNCAO,DTGERACAO,DTINICIAL,DTFINAL,CODFILIAL,CODPROD,TIPOCHAMADA,OBSERVACAO)
                VALUES (''PRC_CORRIGIR_PCHISTEST''
                        ,SYSDATE
                        ,'||CHR(39)||TO_CHAR(P_INTERNOS.DTINICIAL,'DD-MON-RRRR')||CHR(39)||'
                        ,'||CHR(39)||TO_CHAR(P_INTERNOS.DTFINAL,'DD-MON-RRRR')||CHR(39)||'
                        ,'||CHR(39)||P_INTERNOS.CODFILIAL||CHR(39)||'
                        ,'||P_INTERNOS.CODPROD||'
                        ,'||CHR(39)||P_INTERNOS.TIPOCHAMADA||CHR(39)||'
                        ,''Este produto não pode ser recalculado com os dados informados!'||CHR(13)||
                         'Motivo: Não existe histórico antes da data base informada porem existe movimentação deste produto antes desta data.'')';
      EXECUTE IMMEDIATE vsSQL;
    -- Veririca se existe PCHISTEST no dia anterior e chamada do tipo externa
    ELSIF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') IN ('EXTERNA','CONTABIL') THEN
      -- Somar todas as vendas e entradas que movimentaram o estoque até o dia de ontem
      vsSQL := 'SELECT PCLISTADIAS.ID
                      ,PCLISTADIAS.DATA DTMOV
                      ,DADOS.CODFILIAL
                      ,DADOS.CODPROD
                      ,NULL NUMLOTE
                      ,NVL(DADOS.SALDO,0) SALDO
                 FROM (SELECT PCSALDOMOVGERENCIAIS.ID
                             ,PCSALDOMOVGERENCIAIS.DTMOV
                             ,PCSALDOMOVGERENCIAIS.CODFILIAL
                             ,PCSALDOMOVGERENCIAIS.CODPROD
                             ,PCSALDOMOVGERENCIAIS.SALDO
                         FROM PCSALDOMOVGERENCIAIS
                       UNION ALL
                       SELECT PCSALDOMOVCONTABEIS.ID
                             ,PCSALDOMOVCONTABEIS.DTMOV
                             ,PCSALDOMOVCONTABEIS.CODFILIAL
                             ,PCSALDOMOVCONTABEIS.CODPROD
                             ,PCSALDOMOVCONTABEIS.SALDO
                         FROM PCSALDOMOVCONTABEIS) DADOS
                      ,PCLISTADIAS
                 WHERE PCLISTADIAS.DATA = DADOS.DTMOV(+)
                   AND PCLISTADIAS.ID = DADOS.ID(+)
                   AND PCLISTADIAS.ID IN (''GERENCIAL'',''CONTABIL'')
                   AND PCLISTADIAS.DATA BETWEEN '||CHR(39)||TO_CHAR((P_INTERNOS.DTBASE+1),'DD-MON-RRRR')||CHR(39)||' AND '
                                                 ||CHR(39)||TO_CHAR(vdDTFINAL,'DD-MON-RRRR')||CHR(39)||'
                ORDER BY PCLISTADIAS.DATA
                      ,PCLISTADIAS.ID
                      ,DADOS.CODFILIAL
                      ,DADOS.CODPROD';
      -- Abrindo o cursor com base no sql
      OPEN vcCURSOR FOR vsSQL;
      -- Buscando os dados da primeira linha do cursor
      FETCH vcCURSOR INTO vrDADOS;
      -- Enquanto não chegar no final das linhas faça
      WHILE NOT vcCURSOR%NOTFOUND LOOP
        /*Atualiza log do recalculo*/
        IF vsFUNCAO_EXECUTADA = 'PRC_CORRIGIR_PCHISTEST' THEN
           vtLOG.CODFILIAL    := P_INTERNOS.CODFILIAL;
           vtLOG.CODPROD      := P_INTERNOS.CODPROD;
           vtLOG.DATA         := SYSDATE;
           vtLOG.TIPOMOV      := vrDADOS.ID;
           vtLOG.DTINICIOREC  := P_INTERNOS.DTINICIAL;
           vtLOG.OBS          := 'PRC_CORRIGIR_PCHISTEST('||CHR(39)||TO_CHAR(P_INTERNOS.DTFINAL,'DD-MON-RRRR')||CHR(39)||
                                                       ','||NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL')||
                                                       ','||CHR(39)||TO_CHAR(P_INTERNOS.DTLIMITE,'DD-MON-RRRR')||CHR(39)||')';
        END IF;
        -- Identifica que existe movimentação para o período
        vsTEM_MOV_PERIODO   := 'S';
        -- Atualizar variáveis
        P_INTERNOS.DTATUAL  := vrDADOS.DTMOV;
        P_INTERNOS.ID_LISTA := vrDADOS.ID;
        P_INTERNOS.SALDO    := NVL(vrDADOS.SALDO,0);
        -- Criar registro PCHISTEST para o dia
        PRC_INS_PCHISTEST;
        /*Atualiza log do recalculo*/
        IF (vsFUNCAO_EXECUTADA = 'PRC_CORRIGIR_PCHISTEST' AND P_INTERNOS.GERAR_LOG = 'S') THEN
          PRC_INS_LOG (vtLOG);
        END IF;
        -- Indo para a proxima linha do cursor
        FETCH vcCURSOR INTO vrDADOS;
      -- Fim da lista de movimentações
      END LOOP;
      -- Fechando cursor
      CLOSE vcCURSOR;
      -- Caso não tenha movimentação */
      IF (vsTEM_MOV_PERIODO = 'N') THEN
        -- Lista de dias para gerar o PCHISTEST */
        vsSQL := 'SELECT DISTINCT NULL ID
                        ,PCLISTADIAS.DATA DTMOV
                        ,NULL CODFILIAL
                        ,0 CODPROD
                        ,NULL NUMLOTE
                        ,0 SALDO
                    FROM PCLISTADIAS
                   WHERE PCLISTADIAS.DATA > '||CHR(39)||TO_CHAR(P_INTERNOS.DTBASE,'DD-MON-RRRR')||CHR(39)||'
                ORDER BY PCLISTADIAS.DATA';
        -- Abrindo o cursor com base no sql
        OPEN vcCURSOR FOR vsSQL;
        -- Buscando os dados da primeira linha do cursor
        FETCH vcCURSOR INTO vrDADOS;
        -- Enquanto não chegar no final das linhas faça
        WHILE NOT vcCURSOR%NOTFOUND LOOP
          -- Busca PCHISTEST base */
          BEGIN
            SELECT *
              INTO vrPCHISTEST
              FROM PCHISTEST
             WHERE CODFILIAL = P_INTERNOS.CODFILIAL
               AND CODPROD = P_INTERNOS.CODPROD
               AND DATA = (vrDADOS.DTMOV - 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            vrPCHISTEST.DATA      := vrDADOS.DTMOV;
            vrPCHISTEST.DTGERACAO := SYSDATE;
            vrPCHISTEST.CODFILIAL := P_INTERNOS.CODFILIAL;
            vrPCHISTEST.CODPROD   := P_INTERNOS.CODPROD;
            vrPCHISTEST.QTESTGER  := 0;
            vrPCHISTEST.QTEST     := 0;
          END;
          -- Insert no pchistest a partir dos dados colhidos anteriormente
          INSERT INTO PCHISTEST VALUES vrPCHISTEST;
          -- Indo para a proxima linha do cursor
          FETCH vcCURSOR INTO vrDADOS;
        -- Fim da lista de dias */
        END LOOP;
        -- Fechando cursor
        CLOSE vcCURSOR;
      -- Fim inserção de historico */
      END IF;
    -- Caso exista PCHISTEST para o dia anterior
    ELSIF F_CONS_HIST('CONTAR') > '0' THEN
      -- Lista de movimentacoes dia a dia com base na data inicial
      vsSQL := 'SELECT PCLISTADIAS.ID
                      ,PCLISTADIAS.DATA DTMOV
                      ,DADOS.CODFILIAL
                      ,DADOS.CODPROD
                      ,NULL NUMLOTE
                      ,NVL(DADOS.SALDO,0) SALDO
                 FROM (SELECT PCSALDOMOVGERENCIAIS.ID
                             ,PCSALDOMOVGERENCIAIS.DTMOV
                             ,PCSALDOMOVGERENCIAIS.CODFILIAL
                             ,PCSALDOMOVGERENCIAIS.CODPROD
                             ,PCSALDOMOVGERENCIAIS.SALDO
                         FROM PCSALDOMOVGERENCIAIS
                       UNION ALL
                       SELECT PCSALDOMOVCONTABEIS.ID
                             ,PCSALDOMOVCONTABEIS.DTMOV
                             ,PCSALDOMOVCONTABEIS.CODFILIAL
                             ,PCSALDOMOVCONTABEIS.CODPROD
                             ,PCSALDOMOVCONTABEIS.SALDO
                         FROM PCSALDOMOVCONTABEIS) DADOS
                      ,PCLISTADIAS
                 WHERE PCLISTADIAS.DATA = DADOS.DTMOV(+)
                   AND PCLISTADIAS.ID = DADOS.ID(+)
                   AND PCLISTADIAS.ID IN (''GERENCIAL'',''CONTABIL'')
                   AND PCLISTADIAS.DATA BETWEEN '||CHR(39)||TO_CHAR(P_INTERNOS.DTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '
                                                 ||CHR(39)||TO_CHAR(vdDTFINAL,'DD-MON-RRRR')||CHR(39)||'
                ORDER BY PCLISTADIAS.DATA
                      ,PCLISTADIAS.ID
                      ,DADOS.CODFILIAL
                      ,DADOS.CODPROD';
      -- Abrindo o cursor com base no sql
      OPEN vcCURSOR FOR vsSQL;
      -- Buscando os dados da primeira linha do cursor
      FETCH vcCURSOR INTO vrDADOS;
      -- Enquanto não chegar no final das linhas faça
      WHILE NOT vcCURSOR%NOTFOUND LOOP
        /*Atualiza log do recalculo*/
        IF vsFUNCAO_EXECUTADA = 'PRC_CORRIGIR_PCHISTEST' THEN
           vtLOG.CODFILIAL    := P_INTERNOS.CODFILIAL;
           vtLOG.CODPROD      := P_INTERNOS.CODPROD;
           vtLOG.DATA         := SYSDATE;
           vtLOG.TIPOMOV      := vrDADOS.ID;
           vtLOG.DTINICIOREC  := P_INTERNOS.DTINICIAL;
           vtLOG.OBS          := 'PRC_CORRIGIR_PCHISTEST('||CHR(39)||TO_CHAR(P_INTERNOS.DTFINAL,'DD-MON-RRRR')||CHR(39)||
                                                       ','||NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL')||
                                                       ','||CHR(39)||TO_CHAR(P_INTERNOS.DTLIMITE,'DD-MON-RRRR')||CHR(39)||')';
        END IF;
        -- Identifica que existe movimentação para o período
        vsTEM_MOV_PERIODO   := 'S';
        -- Atualizar variáveis
        P_INTERNOS.DTATUAL  := vrDADOS.DTMOV;
        P_INTERNOS.ID_LISTA := vrDADOS.ID;
        P_INTERNOS.SALDO    := NVL(vrDADOS.SALDO,0);
        -- Criar registro PCHISTEST para o dia
        PRC_INS_PCHISTEST;
        -- Atualiza log do recalculo
        IF (vsFUNCAO_EXECUTADA = 'PRC_CORRIGIR_PCHISTEST' AND P_INTERNOS.GERAR_LOG = 'S') THEN
          PRC_INS_LOG (vtLOG);
        END IF;
        -- Indo para a proxima linha do cursor
        FETCH vcCURSOR INTO vrDADOS;
      -- Fim da lista de movimentacoes
      END LOOP;
      -- Caso não tenha movimentação */
      IF (vsTEM_MOV_PERIODO = 'N' and P_INTERNOS.DTINICIAL <= vdDTFINAL) THEN
        -- Insere motivo pelo qual não recalculou o produto */
        vsSQL := 'INSERT
                    INTO PCPRODNAORECALCULADO (FUNCAO,DTGERACAO,DTINICIAL,DTFINAL,CODFILIAL,CODPROD,TIPOCHAMADA,OBSERVACAO)
                  VALUES (''PRC_CORRIGIR_PCHISTEST''
                          ,SYSDATE
                          ,'||CHR(39)||TO_CHAR(P_INTERNOS.DTINICIAL,'DD-MON-RRRR')||CHR(39)||'
                          ,'||CHR(39)||TO_CHAR(P_INTERNOS.DTFINAL,'DD-MON-RRRR')||CHR(39)||'
                          ,'||CHR(39)||P_INTERNOS.CODFILIAL||CHR(39)||'
                          ,'||P_INTERNOS.CODPROD||'
                          ,'||CHR(39)||P_INTERNOS.TIPOCHAMADA||CHR(39)||'
                          ,''Este produto não pode ser recalculado com os dados informados!'||CHR(13)||
                           'Motivo: Não existe movimentação deste produto no período informado ('||TO_CHAR(P_INTERNOS.DTINICIAL,'DD-MON-RRRR')||' à '||TO_CHAR(P_INTERNOS.DTFINAL,'DD-MON-RRRR')||') logo não é necessário reconstruir os histórico deste produto neste perído!'')';
        EXECUTE IMMEDIATE vsSQL;
      -- Fim da inserção do motivo */
      END IF;
      -- Fechando cursor
      CLOSE vcCURSOR;
    -- Inserir dados do produto não recalculado
    ELSE
      vsSQL := 'INSERT
                  INTO PCPRODNAORECALCULADO (FUNCAO,DTGERACAO,DTINICIAL,DTFINAL,CODFILIAL,CODPROD,TIPOCHAMADA,OBSERVACAO)
                VALUES (''PRC_CORRIGIR_PCHISTEST''
                        ,SYSDATE
                        ,'||CHR(39)||TO_CHAR(P_INTERNOS.DTINICIAL,'DD-MON-RRRR')||CHR(39)||'
                        ,'||CHR(39)||TO_CHAR(P_INTERNOS.DTFINAL,'DD-MON-RRRR')||CHR(39)||'
                        ,'||CHR(39)||P_INTERNOS.CODFILIAL||CHR(39)||'
                        ,'||P_INTERNOS.CODPROD||'
                        ,'||CHR(39)||P_INTERNOS.TIPOCHAMADA||CHR(39)||'
                        ,''Este produto não pode ser recalculado com os dados informados!'||CHR(13)||
                         'Motivo: Não existe histórico na data informada como base ('||TO_CHAR(P_INTERNOS.DTBASE,'DD-MON-RRRR')||') para o produto e a filial, para este tipo de chamada não podemos recalcular histórico sem um saldo inicial!'')';
      EXECUTE IMMEDIATE vsSQL;
    -- Se não existe PCHISTEST no dia base não será possível reconstruir os demais para o produto
    END IF;
  -- Fim da procedure
  END PRC_CORRIGIR_PCHISTEST;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  30/06/2017     Fernandes Brito                       Criada procedure para Recalcular os históricos do PCLOTE
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_CORRIGIR_HIST_LOTE (P_ENTRADA IN OUT TP_ENTRADA)
  IS-- Variaveis de uso interno
    vnCONTADOR          NUMBER(10);
    vdDTBASEHISTEST     PCHISTESTLOTE.DATA%TYPE;
    vdDTFINAL           PCHISTESTLOTE.DATA%TYPE;
    vrPCHISTESTLOTE     PCHISTESTLOTE%ROWTYPE;
    vcCURSOR_INT        SYS_REFCURSOR;
  BEGIN
    -- Zerar contador
    vnCONTADOR  := 0;
    -- Atualizar variável de data inicial
    vdDTBASEHISTEST := (P_ENTRADA.DTINICIAL - 1);
    -- Verificando se a data final é valida
    IF P_ENTRADA.DTFINAL >= TRUNC(SYSDATE) THEN
      vdDTFINAL := (TRUNC(SYSDATE)-1);
    ELSE
      vdDTFINAL := P_ENTRADA.DTFINAL;
    END IF;
    -- Contador do PCHISTEST
    SELECT COUNT(*)
      INTO vnCONTADOR
      FROM PCHISTESTLOTE
     WHERE CODFILIAL = P_ENTRADA.CODFILIAL
       AND CODPROD = P_ENTRADA.CODPROD
       AND NUMLOTE = P_ENTRADA.NUMLOTE
       AND DATA = vdDTBASEHISTEST;
    -- Select para localizar a data base
    SELECT MAX(DATA)
      INTO vdMAIOR_DATA
      FROM PCHISTESTLOTE
     WHERE DATA <= vdDTBASEHISTEST
       AND CODPROD = P_ENTRADA.CODPROD
       AND NUMLOTE = P_ENTRADA.NUMLOTE
       AND CODFILIAL = P_ENTRADA.CODFILIAL;
    -- Select para lozalizar a data do cadastro
    IF vdMAIOR_DATA IS NULL THEN
      BEGIN
        SELECT DTCADASTRO
          INTO vdDTCADASTRO
          FROM PCPRODUT
         WHERE CODPROD = P_ENTRADA.CODPROD;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vdMAIOR_DATA := vdDTBASEHISTEST;
      END;
    END IF;
    -- Validar data antes de começar
    IF vdDTCADASTRO < vdDTBASEHISTEST THEN
      vdMAIOR_DATA := vdDTBASEHISTEST;
    ELSIF vdDTCADASTRO >= vdDTBASEHISTEST THEN
      vdMAIOR_DATA := (vdDTCADASTRO - 1);
    END IF;
    -- Limpar as tabelas
    PRC_LIMPAR_SALDOS;
    -- Inserir lista de dias
    PRC_INS_LISTA_DIAS (vdMAIOR_DATA, P_ENTRADA.DTFINAL);
    -- Inserir saldo dos lotes
    PRC_MOV_LOTE (P_ENTRADA.CODFILIAL, P_ENTRADA.CODPROD, P_ENTRADA.NUMLOTE, vdMAIOR_DATA, P_ENTRADA.DTFINAL);
    -- Caso exista PCHISTEST para o dia anterior
    IF vnCONTADOR > 0 THEN
      -- Lista de movimentacoes dia a dia com base na data inicial
      vsSQL := 'SELECT PCLISTADIAS.ID
                      ,PCLISTADIAS.DATA DTMOV
                      ,PCSALDOMOVLOTE.CODFILIAL
                      ,PCSALDOMOVLOTE.CODPROD
                      ,PCSALDOMOVLOTE.NUMLOTE
                      ,NVL(PCSALDOMOVLOTE.SALDO,0) SALDO
                  FROM PCSALDOMOVLOTE
                      ,PCLISTADIAS
                 WHERE PCLISTADIAS.DATA = PCSALDOMOVLOTE.DTMOV(+)
                   AND PCLISTADIAS.ID = PCSALDOMOVLOTE.ID(+)
                   AND PCLISTADIAS.ID IN (''LOTE'')
                   AND PCLISTADIAS.DATA BETWEEN '||CHR(39)||TO_CHAR(P_ENTRADA.DTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '
                                                 ||CHR(39)||TO_CHAR(vdDTFINAL,'DD-MON-RRRR')||CHR(39)||'
                ORDER BY PCLISTADIAS.DATA
                      ,PCLISTADIAS.ID
                      ,PCSALDOMOVLOTE.CODFILIAL
                      ,PCSALDOMOVLOTE.CODPROD
                      ,PCSALDOMOVLOTE.NUMLOTE';
      -- Abrindo o cursor com base no sql
      OPEN vcCURSOR_INT FOR vsSQL;
      -- Buscando os dados da primeira linha do cursor
      FETCH vcCURSOR_INT INTO vrDADOS;
      -- Enquanto não chegar no final das linhas faça
      WHILE NOT vcCURSOR_INT%NOTFOUND LOOP
        -- Zerando variaveis
        vnCONTADOR  := 0;
        -- Verificar se ja existe registro na tabela PCHISTEST para o dia
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM PCHISTESTLOTE
         WHERE CODFILIAL = P_ENTRADA.CODFILIAL
           AND CODPROD = P_ENTRADA.CODPROD
           AND NUMLOTE = P_ENTRADA.NUMLOTE
           AND DATA = vrDADOS.DTMOV;
        -- Buscando os dados do dia anterior para inserir no dia listado
        BEGIN
          SELECT *
            INTO vrPCHISTESTLOTE
            FROM PCHISTESTLOTE
           WHERE CODFILIAL = P_ENTRADA.CODFILIAL
             AND CODPROD = P_ENTRADA.CODPROD
             AND NUMLOTE = P_ENTRADA.NUMLOTE
             AND DATA = (vrDADOS.DTMOV - 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrPCHISTESTLOTE.DATA      := (vrDADOS.DTMOV - 1);
            vrPCHISTESTLOTE.DTGERACAO := SYSDATE;
            vrPCHISTESTLOTE.CODFILIAL := P_ENTRADA.CODFILIAL;
            vrPCHISTESTLOTE.CODPROD   := P_ENTRADA.CODPROD;
            vrPCHISTESTLOTE.NUMLOTE   := P_ENTRADA.NUMLOTE;
            vrPCHISTESTLOTE.QT        := 0;
        END;
        -- Criar registro caso o mesmo nao exista para o dia
        IF vnCONTADOR = 0 THEN
          -- Alterando a data do ultimo PCHISTEST para a data da lista
          vrPCHISTESTLOTE.DATA := vrDADOS.DTMOV;
          -- Atualizar dados para insersão no pchistest que não existe
          vrPCHISTESTLOTE.QT := vrPCHISTESTLOTE.QT + NVL(vrDADOS.SALDO,0);
          -- Inserindo os dados recalculados na PCHISTEST
          INSERT INTO PCHISTESTLOTE VALUES vrPCHISTESTLOTE;
        -- Caso já exista PCHISTEST para o dia
        ELSE
          -- Atualizando os valores da PCHISTEST do dia
          UPDATE PCHISTESTLOTE
             SET QT = (vrPCHISTESTLOTE.QT + NVL(vrDADOS.SALDO,0))
           WHERE CODFILIAL = P_ENTRADA.CODFILIAL
             AND CODPROD = P_ENTRADA.CODPROD
             AND NUMLOTE = P_ENTRADA.NUMLOTE
             AND DATA = vrDADOS.DTMOV;
        -- Fim da atualização da PCHISTEST
        END IF;
        -- Indo para a proxima linha do cursor
        FETCH vcCURSOR_INT INTO vrDADOS;
      -- Fim da lista de movimentacoes
      END LOOP;
      -- Fechando cursor
      CLOSE vcCURSOR_INT;
    -- Inserir dados do produto não recalculado
    ELSE
      vsSQL := 'INSERT
                  INTO PCPRODNAORECALCULADO (FUNCAO,DTGERACAO,DTINICIAL,DTFINAL,CODFILIAL,CODPROD,NUMLOTE,TIPOCHAMADA,OBSERVACAO)
                VALUES (''PRC_CORRIGIR_HIST_LOTE''
                        ,SYSDATE
                        ,'||CHR(39)||TO_CHAR(P_ENTRADA.DTINICIAL,'DD-MON-RRRR')||CHR(39)||'
                        ,'||CHR(39)||TO_CHAR(P_ENTRADA.DTFINAL,'DD-MON-RRRR')||CHR(39)||'
                        ,'||CHR(39)||P_ENTRADA.CODFILIAL||CHR(39)||'
                        ,'||P_ENTRADA.CODPROD||'
                        ,'||CHR(39)||P_ENTRADA.NUMLOTE||CHR(39)||'
                        ,''Nulo''
                        ,''Este produto não pode ser recalculado com os dados informados!'||CHR(13)||
                         ' Verifique se na data informada como base existe dados histórico para o produto, lote e filial.'||CHR(13)||
                         ' Não podemos recalcular histórico sem um saldo inicial!'')';
      EXECUTE IMMEDIATE vsSQL;
    -- Se não existe PCHISTEST no dia base não será possível reconstruir os demais para o produto
    END IF;
  -- Fim da procedure
  END PRC_CORRIGIR_HIST_LOTE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  25/10/2017     Fernandes Brito                       Procedure criada para separar a opção de limpar da opção de criar a tabela PCANALISEDOESTOQUE.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_CRIAR_ANALISEDOESTOQUE
  IS
    -- Variaveis de uso interno
  BEGIN
    --Verificar se existe a tabela
    BEGIN
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM USER_TABLES
       WHERE TABLE_NAME = 'PCANALISEDOESTOQUE';
    EXCEPTION
      WHEN OTHERS THEN
        vnCONTADOR := 0;
    END;
    -- Criando a tabela para armazenar das movimentações contábeis
    IF vnCONTADOR = 0 THEN
      vsCREATE := 'CREATE TABLE PCANALISEDOESTOQUE (
                      TIPOMOVIMENTACAO      VARCHAR2(100)
                     ,CODPROD               NUMBER(6)
                     ,CODFILIAL             VARCHAR2(2)
                     ,DTANTERIOR            DATE
                     ,QTANTERIOR            NUMBER(18,6)
                     ,QTMOVIMETADA          NUMBER(18,6)
                     ,QTESTOQUEATUAL        NUMBER(18,6)
                     ,QTCORRETA             NUMBER(18,6)
                     ,QTDIF                 NUMBER(18,6)
                     ,OBSERVACAO            VARCHAR2(2000)) NOLOGGING';
      EXECUTE IMMEDIATE vsCREATE;
    END IF;
    -- Alterar a tabela para inserir novos campos */
    vsALTERAR := 'ALTER TABLE PCANALISEDOESTOQUE NOLOGGING';
    EXECUTE IMMEDIATE vsALTERAR;
  -- Fim da procedure */
  END PRC_CRIAR_ANALISEDOESTOQUE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  20/12/2017     Fernandes Brito                       Procedure criada para validar a extrutura da tabela
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_CRIAR_LOGRECEST
  IS
    -- Variaveis de uso interno
  BEGIN
    --Verificar se existe a tabela
    BEGIN
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM USER_TABLES
       WHERE TABLE_NAME = 'PCLOGRECEST';
    EXCEPTION
      WHEN OTHERS THEN
        vnCONTADOR := 0;
    END;
    -- Criando a tabela para armazenar das movimentações contábeis
    IF vnCONTADOR = 0 THEN
      vsCREATE := 'CREATE TABLE PCLOGRECEST(
                      NUMRECEST    NUMBER(10)
                     ,CODPROD      NUMBER(6)
                     ,CODFILIAL    VARCHAR2(2)
                     ,DATA         DATE
                     ,QT_ANT       NUMBER(18,6)
                     ,DTINICIOREC  DATE
                     ,TIPOMOV      VARCHAR2(100)
                     ,QTINICIALREC NUMBER(18,6)
                     ,TOT_MOV      NUMBER(18,6)
                     ,QT_FINAL     NUMBER(18,6)
                     ,OBS          VARCHAR2(2000)
                     ,CODFUNC      NUMBER(8)
                     ,DTFIMPROC    DATE) NOLOGGING';
      EXECUTE IMMEDIATE vsCREATE;
    END IF;
    -- Alterar a tabela para inserir novos campos */
    vsALTERAR := 'ALTER TABLE PCLOGRECEST NOLOGGING';
    EXECUTE IMMEDIATE vsALTERAR;
  -- Fim da procedure */
  END PRC_CRIAR_LOGRECEST;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  25/10/2017     Fernandes Brito                       Procedure criada para separar a opção de limpar da opção de criar a tabela PCPRODNAORECALCULADO.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_CRIAR_PRODNAORECALCULADO
  IS
    -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    --Verificar se existe a tabela
    BEGIN
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM USER_TABLES
       WHERE TABLE_NAME = 'PCPRODNAORECALCULADO';
    EXCEPTION
      WHEN OTHERS THEN
        vnCONTADOR := 0;
    END;
    -- */
    IF vnCONTADOR > 0 THEN
      vsDELETE := 'DROP TABLE PCPRODNAORECALCULADO';
      EXECUTE IMMEDIATE vsDELETE;
    END IF;
    -- Criando a tabela para armazenar das movimentações contábeis */
    vsCREATE := 'CREATE TABLE PCPRODNAORECALCULADO (
                         FUNCAO             VARCHAR2(300)
                        ,DTGERACAO          DATE
                        ,DTBASE             DATE
                        ,DTINICIAL          DATE
                        ,DTFINAL            DATE
                        ,CODFILIAL          VARCHAR2(2)
                        ,CODPROD            NUMBER(6)
                        ,NUMLOTE            VARCHAR2(15)
                        ,TIPOCHAMADA        VARCHAR2(300)
                        ,OBSERVACAO         VARCHAR2(3000)) NOLOGGING';
    EXECUTE IMMEDIATE vsCREATE;
    -- Confirmando a alteração */
    COMMIT;
  -- Fim da procedure */
  END PRC_CRIAR_PRODNAORECALCULADO;

  -------------------------------------------------------------------------------------------------------------------------
  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  10/02/2020     Fernandes Brito     0                   Criar procedure para atualizar os dados pendencias na tabela do depósito (PCESTOQUEDEPOSITOPROD)
  /***********************************************************************************************************************/
  PROCEDURE PRC_DEPOSITO_PENDENTE (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCodDeposito PCESTOQUEDEPOSITOPROD.CODDEPOSITO%TYPE;
  BEGIN
    -- Buscar depósito padrão de venda
    IF pENTRADA.CODDEPOSITO = 0 THEN
      BEGIN
        SELECT CODDEPOSITO
          into vCodDeposito
          FROM PCESTOQUEDEPOSITO
         WHERE CODFILIAL = pENTRADA.CODFILIAL
           AND PADRAOVENDA = 'S';
      EXCEPTION
        WHEN OTHERS THEN
          IF SQLCODE = -02290 THEN
            RAISE_APPLICATION_ERROR(-20507,'O parâmetro "Estoque da filial controlado por depósito" esta marcado como "Sim".'||CHR(13)||
                                       'Para este processo funcionar é necessário que exista um depósito informado como padrão para venda/armazenagem e não existe nenhum!'||CHR(13)||
                                       'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                       'MSG Original.: '||SQLERRM);
          ELSE
            RAISE;
          END IF;
      END;
    ELSE
      vCodDeposito := pENTRADA.CODDEPOSITO;
    -- Buscar depósito
    END IF;
    -- Atualizar estoque reservado
    UPDATE PCESTOQUEDEPOSITOPROD E
       SET E.QTPENDENTE = TRUNC((COALESCE(E.QTPENDENTE,0) + COALESCE(pENTRADA.QUANTIDADE,0)),6)
     WHERE E.CODFILIAL = pENTRADA.CODFILIAL
       AND E.CODPROD = pENTRADA.CODPROD
       AND E.CODDEPOSITO = vCodDeposito;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -02290 THEN
        RAISE_APPLICATION_ERROR(-20507,'Não foi possível atualizar o estoque pendente do depósito.'||CHR(13)||
                                     'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                     'Cód. Produto.: '||TO_CHAR(pENTRADA.CODPROD)||CHR(13)||
                                     'Cód. Depósito: '||TO_CHAR(vCodDeposito)||CHR(13)||
                                     'MSG Original.: '||SQLERRM);
      ELSE
        RAISE;
      END IF;
  -- Deposito pendente
  END PRC_DEPOSITO_PENDENTE;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para atualizar os dados reservados na tabela do depósito (PCESTOQUEDEPOSITOPROD)
  /***********************************************************************************************************************/
  PROCEDURE PRC_DEPOSITO_RESERVADO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCodDeposito PCESTOQUEDEPOSITOPROD.CODDEPOSITO%TYPE;
  BEGIN
    -- Buscar depósito padrão de venda
    IF pENTRADA.CODDEPOSITO = 0 THEN
      BEGIN
        SELECT CODDEPOSITO
          into vCodDeposito
          FROM PCESTOQUEDEPOSITO
         WHERE CODFILIAL = pENTRADA.CODFILIAL
           AND PADRAOVENDA = 'S';
      EXCEPTION
        WHEN OTHERS THEN
          IF SQLCODE = -02290 THEN
            RAISE_APPLICATION_ERROR(-20507,'O parâmetro "Estoque da filial controlado por depósito" esta marcado como "Sim".'||CHR(13)||
                                       'Para este processo funcionar é necessário que exista um depósito informado como padrão para venda/armazenagem e não existe nenhum!'||CHR(13)||
                                       'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                       'MSG Original.: '||SQLERRM);
          ELSE
            RAISE;
          END IF;
      END;
    ELSE
      vCodDeposito := pENTRADA.CODDEPOSITO;
    -- Buscar depósito
    END IF;
    -- Atualizar estoque reservado
    UPDATE PCESTOQUEDEPOSITOPROD E
       SET E.QTRESERVADA = TRUNC((COALESCE(E.QTRESERVADA,0) + COALESCE(pENTRADA.QUANTIDADE,0)),6)
     WHERE E.CODFILIAL = pENTRADA.CODFILIAL
       AND E.CODPROD = pENTRADA.CODPROD
       AND E.CODDEPOSITO = vCodDeposito;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -02290 THEN
        RAISE_APPLICATION_ERROR(-20507,'Não foi possível atualizar o estoque reservado do depósito.'||CHR(13)||
                                     'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                     'Cód. Produto.: '||TO_CHAR(pENTRADA.CODPROD)||CHR(13)||
                                     'Cód. Depósito: '||TO_CHAR(vCodDeposito)||CHR(13)||
                                     'MSG Original.: '||SQLERRM);
      ELSE
        RAISE;

      END IF;
  -- Deposito reservado
  END PRC_DEPOSITO_RESERVADO;
  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para atualizar os dados em pendencia na tabela de estoque (PCEST)
  /***********************************************************************************************************************/
  PROCEDURE PRC_ESTOQUE_PENDENTE (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
  BEGIN
    -- Atualizar estoque pendente
    UPDATE PCEST E
       SET E.QTPENDENTE = TRUNC((COALESCE(E.QTPENDENTE,0) + COALESCE(pENTRADA.QUANTIDADE,0)),6)
     WHERE E.CODFILIAL = pENTRADA.CODFILIAL
       AND E.CODPROD = pENTRADA.CODPROD;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -02290 THEN
        RAISE_APPLICATION_ERROR(-20507,'Não foi possível atualizar o estoque pendente.'||CHR(13)||
                                     'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                     'Cód. Produto.: '||TO_CHAR(pENTRADA.CODPROD)||CHR(13)||
                                     'MSG Original.: '||SQLERRM);
      ELSE
        RAISE;
      END IF;
  -- Estoque pendente
  END PRC_ESTOQUE_PENDENTE;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para atualizar os dados reservado na tabela de estoque (PCEST)
  /***********************************************************************************************************************/
  PROCEDURE PRC_ESTOQUE_RESERVADO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
  BEGIN
    -- Atualizar estoque reservado
    UPDATE PCEST E
       SET E.QTRESERV = TRUNC((COALESCE(E.QTRESERV,0) + COALESCE(pENTRADA.QUANTIDADE,0)),6)
     WHERE E.CODFILIAL = pENTRADA.CODFILIAL
       AND E.CODPROD = pENTRADA.CODPROD;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -02290 THEN
        RAISE_APPLICATION_ERROR(-20507,'Não foi possível atualizar o estoque reservado.'||CHR(13)||
                                     'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                     'Cód. Produto.: '||TO_CHAR(pENTRADA.CODPROD)||CHR(13)||
                                     'MSG Original.: '||SQLERRM);
      ELSE
        RAISE;
      END IF;
  -- Estoque reservado
  END PRC_ESTOQUE_RESERVADO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  20/07/2015     Fernandes Brito                       Criada a Função para listar os dias
  29/09/2015     Fernandes Brito                       Alterada a Função para Procedure para criar uma tabela fisica no lugar do PIPELINED
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure para sempre deletar os dados da tabela PCLISTADIAS e incluida
                                                       a função PRAGMA AUTONOMOUS_TRANSACTION para acegurar que o update executado será
                                                       apenas na tabela PCLISTADIAS
  14/02/2017     Fernandes Brito                       Alterada para retirar a criação da tabela e colocar na procedure PRC_LIMPAR_SALDOS
  23/08/2017     Fernandes Brito                       Alterada para incluir a criação dos IDs LOTE e ENDERECO, para controle do lote de
                                                       do endereço da mercadoria no WMS.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_INS_LISTA_DIAS (pdDTINICIAL IN PCMOV.DTMOV%TYPE
                               ,pdDTFINAL   IN PCMOV.DTMOV%TYPE)
  IS
    -- Variaveis de uso interno
    vdDATAMANIPULADA    PCMOV.DTMOV%TYPE := pdDTINICIAL;
    -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- Enquanto a data manipulada seja menor ou igual a data final, faça insert na lista de dias
    WHILE vdDATAMANIPULADA <= pdDTFINAL LOOP
      vsINSERT := 'INSERT INTO PCLISTADIAS (ID, DATA) VALUES (''LOTE'','||CHR(39)||vdDATAMANIPULADA||CHR(39)||')';
      EXECUTE IMMEDIATE vsINSERT;
      vsINSERT := 'INSERT INTO PCLISTADIAS (ID, DATA) VALUES (''ENDERECOLOTE'','||CHR(39)||vdDATAMANIPULADA||CHR(39)||')';
      EXECUTE IMMEDIATE vsINSERT;
      vsINSERT := 'INSERT INTO PCLISTADIAS (ID, DATA) VALUES (''ENDERECO'','||CHR(39)||vdDATAMANIPULADA||CHR(39)||')';
      EXECUTE IMMEDIATE vsINSERT;
      vsINSERT := 'INSERT INTO PCLISTADIAS (ID, DATA) VALUES (''CONTABIL'','||CHR(39)||vdDATAMANIPULADA||CHR(39)||')';
      EXECUTE IMMEDIATE vsINSERT;
      vsINSERT := 'INSERT INTO PCLISTADIAS (ID, DATA) VALUES (''GERENCIAL'','||CHR(39)||vdDATAMANIPULADA||CHR(39)||')';
      EXECUTE IMMEDIATE vsINSERT;
      vdDATAMANIPULADA := vdDATAMANIPULADA + 1;
    END LOOP;
    -- Confirmando os dados desta transação
    COMMIT;
  -- Fim da procedure
  END PRC_INS_LISTA_DIAS;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  20/12/2017    Fernandes Brito    0                   Criada a procedure para inserir os LOGs de execução do recalculo
  ************************************************************************************************************************/
  PROCEDURE PRC_INS_LOG (ptLOG IN PCLOGRECEST%ROWTYPE)
  IS
    -- Declaração das variáveis internas */
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    /*Inserindo log de execurção*/
    INSERT
      INTO PCLOGRECEST
          (NUMRECEST            -- 1
          ,DATA                 -- 2
          ,CODPROD              -- 3
          ,CODFILIAL            -- 4
          ,TIPOMOV              -- 5
          ,QT_ANT               -- 6
          ,DTINICIOREC          -- 7
          ,QTINICIALREC         -- 8
          ,TOT_MOV              -- 9
          ,QT_FINAL             -- 10
          ,OBS                  -- 11
          ,CODFUNC              -- 12
          ,DTFIMPROC            -- 13
           )
    VALUES
         ((SELECT (NVL(MAX(NUMRECEST),0) + 1)
             FROM PCLOGRECEST)        -- 1
          ,ptLOG.DATA                 -- 2
          ,ptLOG.CODPROD              -- 3
          ,ptLOG.CODFILIAL            -- 4
          ,ptLOG.TIPOMOV              -- 5
          ,ptLOG.QT_ANT               -- 6
          ,ptLOG.DTINICIOREC          -- 7
          ,ptLOG.QTINICIALREC         -- 8
          ,ptLOG.TOT_MOV              -- 9
          ,ptLOG.QT_FINAL             -- 10
          ,ptLOG.OBS                  -- 11
          ,ptLOG.CODFUNC              -- 12
          ,SYSDATE                    -- 13
           );
    /*Confirmar atualização*/
    COMMIT;
  /*Fim da procedure*/
  END PRC_INS_LOG;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  10/09/2018     Fernandes Brito                       Procedure criada para unificar código de criação da PCHISTEST.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_INS_PCHISTEST
  IS
    vrPCHISTEST         PCHISTEST%ROWTYPE;
  BEGIN
    -- Buscando os dados do dia anterior para inserir no dia listado
    BEGIN
      SELECT *
        INTO vrPCHISTEST
        FROM PCHISTEST
       WHERE CODFILIAL = P_INTERNOS.CODFILIAL
         AND CODPROD = P_INTERNOS.CODPROD
         AND DATA = (P_INTERNOS.DTATUAL - 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Tipo de chamada
        IF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') IN ('EXTERNA','CONTABIL') THEN
          -- Caso não exista PCHISTEST, Buscar movimentações gerencias para fazer o PCHISTEST
          BEGIN
            vsSQL := 'SELECT NVL(DADOS.SALDO,0)
                        FROM PCSALDOMOVGERENCIAIS DADOS
                            ,PCLISTADIAS
                       WHERE PCLISTADIAS.DATA = DADOS.DTMOV(+)
                         AND PCLISTADIAS.ID = DADOS.ID(+)
                         AND PCLISTADIAS.DATA = ('||CHR(39)||TO_CHAR((P_INTERNOS.DTATUAL - 1),'DD-MON-RRRR')||CHR(39)||')
                         AND (PCLISTADIAS.ID = ''GERENCIAL'' AND NVL('||CHR(39)||P_INTERNOS.TIPOCHAMADA||CHR(39)||',''NORMAL'') <> ''CONTABIL'')';
            -- Executando select para extrar dados
            EXECUTE IMMEDIATE vsSQL INTO vrPCHISTEST.QTESTGER;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrPCHISTEST.QTESTGER  := 0;
          END;
          -- Caso não exista PCHISTEST, Buscar movimentações contabeis para fazer o PCHISTEST
          BEGIN
            vsSQL := 'SELECT NVL(DADOS.SALDO,0)
                        FROM PCSALDOMOVCONTABEIS DADOS
                            ,PCLISTADIAS
                       WHERE PCLISTADIAS.DATA = DADOS.DTMOV(+)
                         AND PCLISTADIAS.ID = DADOS.ID(+)
                         AND PCLISTADIAS.DATA = ('||CHR(39)||TO_CHAR((P_INTERNOS.DTATUAL - 1),'DD-MON-RRRR')||CHR(39)||')
            
                         AND (PCLISTADIAS.ID = ''CONTABIL'' AND NVL('||CHR(39)||P_INTERNOS.TIPOCHAMADA||CHR(39)||',''NORMAL'') <> ''GERENCIAL'')';
            EXECUTE IMMEDIATE vsSQL INTO vrPCHISTEST.QTEST;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN 
              vrPCHISTEST.QTEST     := 0;
          END;
          -- Atualizar demais variáveis
          vrPCHISTEST.DATA      := (P_INTERNOS.DTATUAL - 1);
          vrPCHISTEST.DTGERACAO := SYSDATE;
          vrPCHISTEST.CODFILIAL := P_INTERNOS.CODFILIAL;
          vrPCHISTEST.CODPROD   := P_INTERNOS.CODPROD;
          -- Insert no pchistest a partir dos dados colhidos anteriormente
          INSERT INTO PCHISTEST VALUES vrPCHISTEST;
        -- Tipo de chamada
        ELSE
          vrPCHISTEST.DATA      := (P_INTERNOS.DTATUAL - 1);
          vrPCHISTEST.DTGERACAO := SYSDATE;
          vrPCHISTEST.CODFILIAL := P_INTERNOS.CODFILIAL;
          vrPCHISTEST.CODPROD   := P_INTERNOS.CODPROD;
          vrPCHISTEST.QTESTGER  := 0;
          vrPCHISTEST.QTEST     := 0;
        -- Fim tipo chamada
        END IF;
    -- Fim exeção
    END;
    -- Peencher variaveis para a pesquisa da PCHISTEST
    P_INTERNOS.DTBASE := P_INTERNOS.DTATUAL;
    -- Criar registro caso o mesmo nao exista para o dia
    IF F_CONS_HIST('CONTAR') = '0' THEN
      -- Alterando a data do ultimo PCHISTEST para a data da lista
      vrPCHISTEST.DATA      := P_INTERNOS.DTATUAL;
      vrPCHISTEST.DTGERACAO := SYSDATE;
      -- Atualizar dados para insersão no pchistest que não existe
      IF P_INTERNOS.ID_LISTA = 'GERENCIAL' THEN
        IF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') <> 'CONTABIL' THEN
          vrPCHISTEST.QTESTGER := vrPCHISTEST.QTESTGER + NVL(P_INTERNOS.SALDO,0);
        END IF;
      ELSIF P_INTERNOS.ID_LISTA = 'CONTABIL' THEN
        IF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') <> 'GERENCIAL' THEN
          vrPCHISTEST.QTEST    := vrPCHISTEST.QTEST + NVL(P_INTERNOS.SALDO,0);
        END IF;
      END IF;
      -- Inserindo os dados recalculados na PCHISTEST
      INSERT INTO PCHISTEST VALUES vrPCHISTEST;
    -- Caso já exista PCHISTEST para o dia
    ELSE
      -- Atualizando os valores da PCHISTEST do dia
      IF P_INTERNOS.ID_LISTA = 'GERENCIAL' THEN
        IF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') <> 'CONTABIL' THEN
          UPDATE PCHISTEST
             SET QTESTGER = (vrPCHISTEST.QTESTGER + NVL(P_INTERNOS.SALDO,0))
           WHERE CODFILIAL = P_INTERNOS.CODFILIAL
             AND CODPROD = P_INTERNOS.CODPROD
             AND DATA = P_INTERNOS.DTATUAL;
        END IF;
      ELSIF P_INTERNOS.ID_LISTA = 'CONTABIL' THEN
        IF NVL(P_INTERNOS.TIPOCHAMADA,'NORMAL') <> 'GERENCIAL' THEN
          UPDATE PCHISTEST
             SET QTEST = (vrPCHISTEST.QTEST + NVL(P_INTERNOS.SALDO,0))
           WHERE CODFILIAL = P_INTERNOS.CODFILIAL
             AND CODPROD = P_INTERNOS.CODPROD
             AND DATA = P_INTERNOS.DTATUAL;
        END IF;
      -- Fim da atualização da PCHISTEST
      END IF;
    -- Fim da atualização da PCHISTEST
    END IF;
  -- Fim procedure
  END ;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  27/06/2016     Fernandes Brito                       Procedure criada para limpar dados da tabela PCANALISEDOESTOQUE. Isso se faz
                                                       necessário porque a analise é feita com dados atuais do produto, logo se passado
                                                       vários dias não faz mais sentido analisar tais dados.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_LIMPAR_ANALISEDOESTOQUE
  IS
    -- Variaveis de uso interno
  BEGIN
    -- Criar a tabela */
    PRC_CRIAR_ANALISEDOESTOQUE;
    -- Sempe deleta a tabela PCANALISEDOESTOQUE
    BEGIN
      vsDELETE := 'TRUNCATE TABLE PCANALISEDOESTOQUE'; --aqui
      EXECUTE IMMEDIATE vsDELETE;
    -- Caso apresente erro ao tentar deletar tabela */
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de analise de estoque'||CHR(13)||
                               ' Erro: '||SQLERRM||CHR(13)||
                               ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END;
  -- Fim da procedure PRC_LIMPAR_ANALISEDOESTOQUE
  END PRC_LIMPAR_ANALISEDOESTOQUE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  
  24/04/2017     Fernandes Brito                       Procedure criada para limpar dados da tabela PCPRODNAORECALCULADO. Afim de documentar
                                                       quais os produtos não foram recalculados durante a execução do recalculo o da recostrução do PCHISTEST
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_LIMPAR_PRODNAORECALCULADO
  IS
    -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- Criar a tabela caso não exista */
    PRC_CRIAR_PRODNAORECALCULADO;
    -- Sempe deleta a tabela PCSALDOMOVCONTABEIS
    BEGIN
      vsDELETE := 'TRUNCATE TABLE PCPRODNAORECALCULADO'; --aqui
      EXECUTE IMMEDIATE vsDELETE;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de produtos não recalculados'||CHR(13)||
                               ' Erro: '||SQLERRM||CHR(13)||
                               ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END;
  -- Fim da criação da tabela de movimentações contabeis
  END PRC_LIMPAR_PRODNAORECALCULADO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  14/02/2017     Fernandes Brito                       Procedure criada para limpar dados das tabelas PCSALDOMOVCONTABEIS,
                                                       PCSALDOMOVGERENCIAS e PCLISTADIAS
  22/08/2017     Fernandes Brito                       Alterada a procedure para incluir a opção de limpar/criar a tabela PCSALDOMOVLOTE
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_LIMPAR_SALDOS
  IS
    -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    /*=================================================================================
                               Criação da tabela da lista de dias
    =================================================================================*/
    BEGIN
      -- Verificar se existe a tabela
      BEGIN
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM USER_TABLES
         WHERE TABLE_NAME = 'PCLISTADIAS';
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;
      -- Criando a tabela para armazenar os dias
      IF vnCONTADOR = 0 THEN
        vsCREATE := 'CREATE TABLE PCLISTADIAS (ID VARCHAR2(20), DATA DATE) NOLOGGING';
        EXECUTE IMMEDIATE vsCREATE;
        COMMIT;
      END IF;
      -- Sempe deleta a tabela PCLISTADIAS
      BEGIN
        vsDELETE := 'TRUNCATE TABLE PCLISTADIAS';
        EXECUTE IMMEDIATE vsDELETE;
        COMMIT;
        vsALTERAR := 'ALTER TABLE PCLISTADIAS NOLOGGING';
        EXECUTE IMMEDIATE vsALTERAR;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de dias'||CHR(13)||
                                  'Erro: '||SQLERRM||CHR(13)||
                                  'Linha: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
    -- Fim da criação da tabela da lista de dias
    END;

    /*=================================================================================
                        Criação da tabela de movimentações contabeis
    =================================================================================*/
    BEGIN
      --Verificar se existe a tabela
      BEGIN
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM USER_TABLES
         WHERE TABLE_NAME = 'PCSALDOMOVCONTABEIS';
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;
      -- Criando a tabela para armazenar das movimentações contábeis
      IF vnCONTADOR = 0 THEN
        vsCREATE := 'CREATE TABLE PCSALDOMOVCONTABEIS (
                       ID                 VARCHAR2(20)
                      ,DTMOV              DATE
                      ,CODFILIAL          VARCHAR2(2)
                      ,CODPROD            NUMBER(6)
                      ,SALDO              NUMBER(20,6)) NOLOGGING';
        EXECUTE IMMEDIATE vsCREATE;
        COMMIT;
      END IF;
      -- Sempe deleta a tabela PCSALDOMOVCONTABEIS
      BEGIN
        vsDELETE := 'TRUNCATE TABLE PCSALDOMOVCONTABEIS'; --aqui
        EXECUTE IMMEDIATE vsDELETE;
        COMMIT;
        vsALTERAR := 'ALTER TABLE PCSALDOMOVCONTABEIS NOLOGGING';
        EXECUTE IMMEDIATE vsALTERAR;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de saldos contábeis'||CHR(13)||
                                 ' Erro: '||SQLERRM||CHR(13)||
                                 ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
    -- Fim da criação da tabela de movimentações contabeis
    END;

    /*=================================================================================
                       Criação da tabela de movimentações gerenciais
    =================================================================================*/
    BEGIN
      --Verificar se existe a tabela
      BEGIN
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM USER_TABLES
         WHERE TABLE_NAME = 'PCSALDOMOVGERENCIAIS';
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;
      -- Criando a tabela para armazenar das movimentações gerenciais
      IF vnCONTADOR = 0 THEN
        vsCREATE := 'CREATE TABLE PCSALDOMOVGERENCIAIS (
                           ID                 VARCHAR2(20)
                          ,DTMOV              DATE
                          ,CODFILIAL          VARCHAR2(2)
                          ,CODPROD            NUMBER(6)
                          ,SALDO              NUMBER(20,6)) NOLOGGING';
        EXECUTE IMMEDIATE vsCREATE;
        COMMIT;
      END IF;
      -- Sempe deleta a tabela PCSALDOMOVGERENCIAIS
      BEGIN
        vsDELETE := 'TRUNCATE TABLE PCSALDOMOVGERENCIAIS';
        EXECUTE IMMEDIATE vsDELETE;
        COMMIT;
        vsALTERAR := 'ALTER TABLE PCSALDOMOVGERENCIAIS NOLOGGING';
        EXECUTE IMMEDIATE vsALTERAR;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de saldos gerenciais'||CHR(13)||
                                 ' Erro: '||SQLERRM||CHR(13)||
                                 ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
    -- Fim da criação da tabela de movimentações gerenciais
    END;

    /*=================================================================================
                       Criação da tabela de movimentações LOTE
    =================================================================================*/
    BEGIN
      -- Verificar se existe a tabela
      BEGIN
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM USER_TABLES
         WHERE TABLE_NAME = 'PCSALDOMOVLOTE';
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;
      -- Criando a tabela para armazenar das movimentações do lote
      IF vnCONTADOR = 0 THEN
        vsCREATE := 'CREATE TABLE PCSALDOMOVLOTE (
                            ID                 VARCHAR2(20)
                           ,DTMOV              DATE
                           ,CODFILIAL          VARCHAR2(2)
                           ,CODPROD            NUMBER(6)
                           ,NUMLOTE            VARCHAR2(15)
                           ,SALDO              NUMBER(20,6)) NOLOGGING';
        EXECUTE IMMEDIATE vsCREATE;
        COMMIT;
      END IF;
      -- Sempe deleta a tabela PCSALDOMOVLOTE
      BEGIN
        vsDELETE := 'TRUNCATE TABLE PCSALDOMOVLOTE';
        EXECUTE IMMEDIATE vsDELETE;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de saldos LOTE '||CHR(13)||
                                 ' Erro: '||SQLERRM||CHR(13)||
                                 ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
    -- Fim da criação da tabela de movimentações do lote
    END;

    /*=================================================================================
                     Criação da tabela de movimentações do endereço
    =================================================================================*/
    BEGIN
      -- Verificar se existe a tabela
      BEGIN
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM USER_TABLES
         WHERE TABLE_NAME = 'PCSALDOMOVENDERECO';
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;
      -- Criando a tabela para armazenar das movimentações do endereço (WMS)
      IF vnCONTADOR = 0 THEN
        vsCREATE := 'CREATE TABLE PCSALDOMOVENDERECO (
                            ID                 VARCHAR2(20)
                           ,DTMOV              DATE
                           ,CODFILIAL          VARCHAR2(2)
                           ,CODPROD            NUMBER(6)
                           ,SALDO              NUMBER(20,6)) NOLOGGING';
        EXECUTE IMMEDIATE vsCREATE;
        COMMIT;
      END IF;
      -- Sempe deleta a tabela PCSALDOMOVENDERECO
      BEGIN
        vsDELETE := 'TRUNCATE TABLE PCSALDOMOVENDERECO';
        EXECUTE IMMEDIATE vsDELETE;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de saldos LOTE '||CHR(13)||
                                 ' Erro: '||SQLERRM||CHR(13)||
                                 ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
    -- Fim da criação da tabela de movimentações do ENDEREÇO (WMS)
    END;

    /*=================================================================================
                  Criação da tabela de movimentações do endereço do lote
    =================================================================================*/
    BEGIN
      -- Verificar se existe a tabela
      BEGIN
        SELECT COUNT(*)
          INTO vnCONTADOR
          FROM USER_TABLES
         WHERE TABLE_NAME = 'PCSALDOMOVENDERECOLOTE';
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;
      -- Criando a tabela para armazenar das movimentações do endereço do lote (WMS)
      IF vnCONTADOR = 0 THEN
        vsCREATE := 'CREATE TABLE PCSALDOMOVENDERECOLOTE (
                            ID                 VARCHAR2(20)
                           ,DTMOV              DATE
                           ,CODFILIAL          VARCHAR2(2)
                           ,CODPROD            NUMBER(6)
                           ,NUMLOTE            VARCHAR2(15)
                           ,SALDO              NUMBER(20,6)) NOLOGGING';
        EXECUTE IMMEDIATE vsCREATE;
        COMMIT;
      END IF;
      -- Sempe deleta a tabela PCSALDOMOVENDERECO
      BEGIN
        vsDELETE := 'TRUNCATE TABLE PCSALDOMOVENDERECOLOTE';
        EXECUTE IMMEDIATE vsDELETE;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001,'Erro ao limpar a tabela de saldos LOTE '||CHR(13)||
                                 ' Erro: '||SQLERRM||CHR(13)||
                                 ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
    -- Fim da criação da tabela de movimentações do ENDEREÇO (WMS)
    END;
    -- Confirma
    COMMIT;
  -- Fim da procedure PRC_LIMPAR_SALDOS
  END PRC_LIMPAR_SALDOS;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para atualizar os dados reservado do lote (PCLOTE)
  /***********************************************************************************************************************/
  PROCEDURE PRC_LOTE_RESERVADO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
  BEGIN
    -- Atualizar lote reservado
    UPDATE PCLOTE E
       SET E.QTRESERV = TRUNC((COALESCE(E.QTRESERV,0) + COALESCE(pENTRADA.QUANTIDADE,0)),6)
     WHERE E.CODFILIAL = pENTRADA.CODFILIAL
       AND E.CODPROD = pENTRADA.CODPROD
       AND E.NUMLOTE = pENTRADA.NUMLOTE;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -02290 THEN
        RAISE_APPLICATION_ERROR(-20507,'Não foi possível atualizar o estoque reservado do lote.'||CHR(13)||
                                     'Cód. Filial..: '||pENTRADA.CODFILIAL||CHR(13)||
                                     'Cód. Produto.: '||TO_CHAR(pENTRADA.CODPROD)||CHR(13)||
                                     'Núm. Lote....: '||pENTRADA.NUMLOTE||CHR(13)||
                                     'MSG Original.: '||SQLERRM);
      ELSE
        RAISE;
      END IF;
  -- Lote reservado
  END PRC_LOTE_RESERVADO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  19/01/2015     Fernandes Brito                       Procedure criada para avaliar se o estoque apresentou algum tipo de
                                                       problema de antes de ontem para ontem.
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure buscar as movimentações sem usar a função F_TODAS_MOVIMENTACOES
                                                       e buscar os saldos anteriores sem usar a função F_DADOS_HISTEST_ANTERIOR
  08/09/2016     Fernandes Brito                       Incluida a função CLOSE para fechar a variável vcCURSOR_MON e assim
                                                       evitar problemas com lixo no cursor
  16/11/2020     Fernandes Brito                       Ajustada a procedure para gravar dados na PCMENSAGEMLOGFALHA de forma mais detalhada.

  Observações:
  Para saber mais sobre o parâmetro "psTIPOCHAMADA" veja cabeçalho da procedure PRC_RECALCULO
  CORRETO: Busca apenas notas fiscais que são reconhecidas pelo SEFAZ.
  Qualquer outro: Busca todas as notas fiscal geradas pelo sistema, mesmo que ela não seja reconhecida como nota no SEFAZ
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MONITORAR_ESTOQUE (ptENTRADA_MONITOR IN OUT TR_ENTRADA_MONITOR_ESTOQUE)
  IS-- Variaveis de uso interno
    vt_MSG_MON               TR_MSG_MON;
    vdDTBASE                 PCHISTEST.DATA%TYPE := TRUNC(SYSDATE)-2;
    
    vdDTMOVIMENTACAO         PCHISTEST.DATA%TYPE := TRUNC(SYSDATE)-1;
  BEGIN
    -- Limpar as tabelas
    PRC_LIMPAR_SALDOS;
    P_INTERNOS.USA_FUNCAO_1070 := 'S';
    -- Lista de filiais e produtos
    FOR DADOS IN (SELECT PCEST.CODFILIAL
                        ,PCEST.CODPROD
                    FROM PCEST
                        ,PCFILIAL
                   WHERE PCEST.CODFILIAL = PCFILIAL.CODIGO
                     AND NVL(PCFILIAL.GERARPCHISTEST,'N') = 'S'
                     AND (ptENTRADA_MONITOR.CODFILIAL IS NULL OR PCEST.CODFILIAL = ptENTRADA_MONITOR.CODFILIAL)
                     AND (ptENTRADA_MONITOR.CODPROD IS NULL OR PCEST.CODPROD = ptENTRADA_MONITOR.CODPROD)
                     AND PCEST.CODFILIAL NOT IN ('99')
                ORDER BY PCEST.CODFILIAL
                        ,PCEST.CODPROD)
    LOOP
      -- Inserir lista de dias
      PRC_INS_LISTA_DIAS (vdDTMOVIMENTACAO,vdDTMOVIMENTACAO);
      -- Inserir saldos das movimentações contábeis
      PRC_MOV_CONT (DADOS.CODFILIAL,DADOS.CODPROD,vdDTMOVIMENTACAO,vdDTMOVIMENTACAO,'CORRETO');
      -- Inserir saldos das movimentações gerenciais
      PRC_MOV_GER (DADOS.CODFILIAL,DADOS.CODPROD,vdDTMOVIMENTACAO,vdDTMOVIMENTACAO);
      -- Atualizando dados para pesquisar o cadastro do produto
      P_INTERNOS.CODPROD             := DADOS.CODPROD;
      vtPRODUTO.DTEXCLUSAO           := NULL;
      -- Pesquisando os dados do produto
      vsRETORNO                      := F_CONS_PRODUTO(NULL);
      -- Peencher variaveis para a pesquisa da PCHISTEST de antes de ontem
      P_INTERNOS.CODFILIAL           := DADOS.CODFILIAL;
      P_INTERNOS.DTBASE              := vdDTBASE;
      -- Pesquisando os dados de antes de ontem
      vsRETORNO                      := F_CONS_HIST('MONITORAMENTO');
      -- Atualizando os dados de antes de ontem
      vt_MSG_MON.DATA_ANTES          := vtHIST_EST.DATA;
      vt_MSG_MON.QTDE_ANTES_GER      := vtHIST_EST.QTESTGER;
      vt_MSG_MON.QTDE_ANTES_CONT     := vtHIST_EST.QTEST;
      -- Prencher variaveis para a pesquisa da PCHISTEST de ontem
      P_INTERNOS.DTBASE              := vdDTMOVIMENTACAO;
      -- Pesquisando os dados de ontem
      vsRETORNO                      := F_CONS_HIST('MONITORAMENTO');
      -- Atualizando os dados de ontem
      vt_MSG_MON.DATA_ATUAL          := vtHIST_EST.DATA;
      vt_MSG_MON.QTDE_ATUAL_GER      := vtHIST_EST.QTESTGER;
      vt_MSG_MON.QTDE_ATUAL_CONT     := vtHIST_EST.QTEST;
      -- Prencher variáveis com parâmetros
      vt_MSG_MON.DESTINO             := ptENTRADA_MONITOR.DESTINO;
      vt_MSG_MON.CODUSUARIO          := ptENTRADA_MONITOR.CODUSUARIO;
      vt_MSG_MON.DTINICIAL           := vdDTBASE;
      vt_MSG_MON.DTFINAL             := vdDTMOVIMENTACAO;
      vt_MSG_MON.CODFILIAL           := DADOS.CODFILIAL;
      vt_MSG_MON.CODPROD             := DADOS.CODPROD;
      vt_MSG_MON.PROB_NO_HISTORICO   := FALSE;
      IF vtPRODUTO.DTEXCLUSAO IS NULL THEN
        vt_MSG_MON.EXCLUIDO          := 'Nao';
      ELSE
        vt_MSG_MON.EXCLUIDO          := 'Sim';
      END IF;
      -- Lista de movimentacos no dia de ontem
      FOR MOV IN (SELECT MOVIMENTACOES.ID ID
                        ,MOVIMENTACOES.DTMOV
                        ,MOVIMENTACOES.CODFILIAL
                        ,MOVIMENTACOES.CODPROD
                        ,MOVIMENTACOES.SALDO
                   FROM (SELECT ID, DTMOV, CODFILIAL, CODPROD, SALDO FROM PCSALDOMOVGERENCIAIS
                         UNION ALL
                         SELECT ID, DTMOV, CODFILIAL, CODPROD, SALDO FROM PCSALDOMOVCONTABEIS) MOVIMENTACOES
                   WHERE MOVIMENTACOES.CODFILIAL = DADOS.CODFILIAL
                     AND MOVIMENTACOES.CODPROD = DADOS.CODPROD
                ORDER BY MOVIMENTACOES.DTMOV
                        ,MOVIMENTACOES.CODFILIAL
                        ,MOVIMENTACOES.CODPROD
                        ,MOVIMENTACOES.ID)
      LOOP
        vt_MSG_MON.ID := MOV.ID;
        -- Saldo do sistema
        IF MOV.ID = 'GERENCIAL' THEN
          vt_MSG_MON.QTDE_GER_MOVIMENTADA := NVL(MOV.SALDO,0);
          vt_MSG_MON.QTDE_SALDO_GER := (NVL(vt_MSG_MON.QTDE_ANTES_GER,0) + NVL(MOV.SALDO,0));
          vt_MSG_MON.QTDE_CORRETA_GER := vt_MSG_MON.QTDE_SALDO_GER;
          vt_MSG_MON.QTDE_DIF_GER := (vt_MSG_MON.QTDE_ATUAL_GER - vt_MSG_MON.QTDE_CORRETA_GER);
        ELSIF MOV.ID = 'CONTABIL' THEN
          vt_MSG_MON.QTDE_CONT_MOVIMENTADA := NVL(MOV.SALDO,0);
          vt_MSG_MON.QTDE_SALDO_CONT := (NVL(vt_MSG_MON.QTDE_ANTES_CONT,0) + NVL(MOV.SALDO,0));
          vt_MSG_MON.QTDE_CORRETA_CONT := vt_MSG_MON.QTDE_SALDO_CONT;
          vt_MSG_MON.QTDE_DIF_CONT := (vt_MSG_MON.QTDE_ATUAL_CONT - vt_MSG_MON.QTDE_CORRETA_CONT);
        END IF;
        -- Validar dados
        PRIV_VERIFICAR_ERROS (vt_MSG_MON);
      -- Lista dos produtos
      END LOOP;
    -- Lista de produtos cadastrados
    END LOOP;
    -- Commit
    COMMIT;
  -- Procedure
  END PRC_MONITORAR_ESTOQUE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  22/08/2017     Fernandes Brito                       Procedure criada para monitorar o estoque do lote
  17/11/2020     Fernandes Brito                       Ajustada a procedure para usar TYPE nos parâmetros de entrada
    --------------------------------------------------------------------------------------------------------------------------------------*/
  
  PROCEDURE PRC_MONITORAR_LOTE (ptENTRADA_MONITOR IN OUT TR_ENTRADA_MONITOR_ESTOQUE)
  IS-- Variaveis de uso interno
    vnQTLOTE_ANTS_ONTEM      PCHISTEST.QTESTGER%TYPE;
    vnQTLOTE_ONTEM           PCHISTEST.QTESTGER%TYPE;
    vnQTLOTE                 PCHISTEST.QTESTGER%TYPE;
    vnSALDO_LOTE             PCHISTEST.QTEST%TYPE;
    vdDT_LOTE_ONTEM          PCHISTEST.DATA%TYPE;
    vdDT_LOTE_ANTS_ONTEM     PCHISTEST.DATA%TYPE;
    vdDTEXCLUSAO             PCPRODUT.DTEXCLUSAO%TYPE;
    vnCONTREGISTROS          NUMBER;
    vcCURSOR_LOTE            SYS_REFCURSOR;
    pdDTBASE                 PCHISTEST.DATA%TYPE := TRUNC(SYSDATE)-2;
    pdDTMOVIMENTACAO         PCHISTEST.DATA%TYPE := TRUNC(SYSDATE)-1;
  BEGIN
    -- Limpar as tabelas
    PRC_LIMPAR_SALDOS;
    -- Inserir lista de dias
    PRC_INS_LISTA_DIAS (pdDTMOVIMENTACAO,pdDTMOVIMENTACAO);
    -- Verifica se faz atualizações gerenciais e contábeis
    PRC_MOV_LOTE (NULL,NULL,NULL,pdDTMOVIMENTACAO,pdDTMOVIMENTACAO);
    -- Lista de produtos cadastrados
    FOR PRODUTOS IN (SELECT CODFILIAL
                           ,CODPROD
                           ,NUMLOTE
                       FROM PCLOTE
                      WHERE (ptENTRADA_MONITOR.CODFILIAL IS NULL OR PCLOTE.CODFILIAL = ptENTRADA_MONITOR.CODFILIAL)
                        AND (ptENTRADA_MONITOR.CODPROD IS NULL OR PCLOTE.CODPROD = ptENTRADA_MONITOR.CODPROD)
                        AND (ptENTRADA_MONITOR.NUMLOTE IS NULL OR PCLOTE.NUMLOTE = ptENTRADA_MONITOR.NUMLOTE))
    LOOP
      -- Zera contador de registros e limpar as variáveis
      vnCONTREGISTROS     := 0;
      vnQTLOTE            := NULL;
      vnSALDO_LOTE        := NULL;
      vdDTEXCLUSAO        := NULL;
      -- Prencher variaveis para a pesquisa da PCHISTEST
      P_INTERNOS.CODFILIAL := PRODUTOS.CODFILIAL;
      P_INTERNOS.CODPROD   := PRODUTOS.CODPROD;
      P_INTERNOS.NUMLOTE   := PRODUTOS.NUMLOTE;
      P_INTERNOS.DTBASE    := pdDTBASE;
      -- Buscar dados de antes de ontem
      vsRETORNO            := F_CONS_HIST_LOTE ('MONITORAMENTO');
      vdDT_LOTE_ANTS_ONTEM := vtHIST_LOTE.DATA;
      vnQTLOTE_ANTS_ONTEM  := vtHIST_LOTE.QT;
      -- Prencher variaveis para a pesquisa da PCHISTEST
      vtHIST_LOTE.DATA := pdDTMOVIMENTACAO;
      -- Buscar dados de antes de ontem
      vsRETORNO            := F_CONS_HIST_LOTE ('MONITORAMENTO');
      vdDT_LOTE_ONTEM      := vtHIST_LOTE.DATA;
      vnQTLOTE_ONTEM       := vtHIST_LOTE.QT;
      -- Atualizando dados para consultar cadastro
      P_INTERNOS.CODPROD       := PRODUTOS.CODPROD;
      vtPRODUTO.ESTOQUEPORLOTE := NULL;
      vtPRODUTO.DTEXCLUSAO     := NULL;
      -- Excutar consulta do produto
      vsRETORNO := F_CONS_PRODUTO (NULL);
      -- Lista de produtos movimentados no dia de ontem
      vsSQL := 'SELECT PCLISTADIAS.ID
                      ,PCLISTADIAS.DATA DTMOV
                      ,PCSALDOMOVLOTE.CODFILIAL
                      ,PCSALDOMOVLOTE.CODPROD
                      ,PCSALDOMOVLOTE.NUMLOTE
                      ,NVL(PCSALDOMOVLOTE.SALDO,0) SALDO
                  FROM PCSALDOMOVLOTE
                      ,PCLISTADIAS
                 WHERE PCLISTADIAS.DATA = PCSALDOMOVLOTE.DTMOV(+)
                   AND PCLISTADIAS.ID = PCSALDOMOVLOTE.ID(+)
                   AND PCLISTADIAS.ID IN (''LOTE'')
                   AND PCSALDOMOVLOTE.CODPROD = '||PRODUTOS.CODPROD||'
                   AND PCSALDOMOVLOTE.CODFILIAL = '||CHR(39)||PRODUTOS.CODFILIAL||CHR(39)||'
                   AND PCSALDOMOVLOTE.NUMLOTE = '||CHR(39)||PRODUTOS.NUMLOTE||CHR(39)||'
                   AND PCSALDOMOVLOTE.SALDO <> 0
              ORDER BY PCLISTADIAS.DATA
                      ,PCSALDOMOVLOTE.CODFILIAL
                      ,PCSALDOMOVLOTE.CODPROD
                      ,PCSALDOMOVLOTE.NUMLOTE
                      ,PCLISTADIAS.ID DESC';
      /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsSQL, 1);
      COMMIT; --*/
      -- Abrindo o cursor com base no sql
      OPEN vcCURSOR_LOTE FOR vsSQL;
      -- Buscando os dados da primeira linha do cursor
      FETCH vcCURSOR_LOTE INTO vrDADOS;
      -- Enquanto não chegar no final das linhas faça
      WHILE NOT vcCURSOR_LOTE%NOTFOUND LOOP
        -- Atualizar contador de registros
        vnCONTREGISTROS := vnCONTREGISTROS + 1;
        -- Fazendo a conta do saldo do sistema
        vnQTLOTE  := NVL((NVL(vnQTLOTE_ANTS_ONTEM,0) + NVL(vrDADOS.SALDO,0)),0);
        vnSALDO_LOTE  := NVL(vrDADOS.SALDO,0);
        /*############################################
            Caso a mensagem seja para o funcionário
        ############################################*/
        IF ptENTRADA_MONITOR.DESTINO <> 'TOTVS' THEN
          -- Caso não exista histórico antes de ontem
          IF (--vsPROB_NO_HISTORICO = FALSE AND
              vdDT_LOTE_ANTS_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
            
              vdDT_LOTE_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vnSALDO_LOTE <> vnQTLOTE_ONTEM) THEN
            -- Criar mensagem para ser enviada para Luciana
            INSERT  INTO PCRECFUNC
                  (CODFUNCAB                                                      -- 1
                  ,DTAB                                                           -- 2
                  ,CODSETORORIG                                                   -- 3
                  ,CODSETORDEST                                                   -- 4
                  ,CODFUNCDEST                                                    -- 5
                  ,ASSUNTO                                                        -- 6
                  ,TEXTORECADO                                                    -- 7
                  ,NUMRECADO                                                      -- 8
                  )
           VALUES (1                                                              -- 1
                  ,SYSDATE                                                        -- 2
                  ,1                                                              -- 3
                  ,1                                                              -- 4
                  ,ptENTRADA_MONITOR.CODUSUARIO                                                   -- 5
                  ,'MSN-1: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de antes de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para antes de ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que não condizem com o histórico gravado para ontem (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||vrDADOS.DTMOV||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,DFSEQ_PCRECFUNC.NEXTVAL
                  );
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          ELSIF ( --vsPROB_NO_HISTORICO = FALSE AND
                  vdDT_LOTE_ANTS_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                  vdDT_LOTE_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                ((vnQTLOTE_ANTS_ONTEM + vnSALDO_LOTE) <> 0)) THEN
            -- Criar mensagem para ser enviada para Luciana
            INSERT INTO PCRECFUNC
                  (CODFUNCAB                                                      -- 1
                  ,DTAB                                                           -- 2
                  ,CODSETORORIG                                                   -- 3
                  ,CODSETORDEST                                                   -- 4
                  ,CODFUNCDEST                                                    -- 5
                  ,ASSUNTO                                                        -- 6
                  ,TEXTORECADO                                                    -- 7
                  ,NUMRECADO                                                      -- 8
                  )
           VALUES (1                                                              -- 1
                  ,SYSDATE                                                        -- 2
                  ,1                                                              -- 3
                  ,1                                                              -- 4
                  ,ptENTRADA_MONITOR.CODUSUARIO                                                   -- 5
                  ,'MSN-2: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que apontam a necessidade de ter histórico gravado (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||vrDADOS.DTMOV||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,DFSEQ_PCRECFUNC.NEXTVAL
                  );
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Caso exista histório
          ELSIF (--(vsPROB_NO_HISTORICO = FALSE) AND
                 (vnQTLOTE <> vnQTLOTE_ONTEM)) THEN
              -- Criar mensagem para ser enviada para Luciana
              INSERT INTO PCRECFUNC
                    (CODFUNCAB                                                      -- 1
                    ,DTAB                                                           -- 2
                    ,CODSETORORIG                                                   -- 3
                    ,CODSETORDEST                                                   -- 4
                    ,CODFUNCDEST                                                    -- 5
                    ,ASSUNTO                                                        -- 6
                    ,TEXTORECADO                                                    -- 7
                    ,NUMRECADO                                                      -- 8
                    )
             VALUES (1                                                              -- 1
                    ,SYSDATE                                                        -- 2
                    ,1                                                              -- 3
                    ,1                                                              -- 4
                    ,ptENTRADA_MONITOR.CODUSUARIO                                                   -- 5
                    ,'MSN-3: O produto '|| PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' esta com problemas na filial '||PRODUTOS.CODFILIAL  -- 6
                    ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                     'O lote foi movimentado de forma errada para os dados abaixo: '||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                     'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                     'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                     'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                     'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                     'No dia '||vrDADOS.DTMOV||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                     'O sistema gravaou na PCHISTESTLOTE de ontem............: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                     'O correto a ser gravado seria..........................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                     'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                     'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                     'Possível Motivo: É possível que o sistema tenha falhado na movimentação do estoque!'||CHR(13)||CHR(10)||
                     'Verifique na PCLOTELOG ou peça ajuda a TOTVS'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                     'Possivel solução: Não identificada!'
                    ,DFSEQ_PCRECFUNC.NEXTVAL
                    );
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Fim da validação da data de geração do PCHISTEST anterior
          END IF;
        /*############################################
        Caso a mensagem seja para a TOTVS
        ############################################*/
        ELSE
          -- Caso não exista histórico antes de ontem
          IF (--vsPROB_NO_HISTORICO = FALSE AND
              vdDT_LOTE_ANTS_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vdDT_LOTE_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vnSALDO_LOTE <> vnQTLOTE_ONTEM) THEN
            -- Criar mensagem para ser enviada via e-mail
            INSERT
              INTO PCMENSAGEMLOGFALHA
                  (CODMENS                                -- 1
                  ,DTREGISTRO                             -- 2
                  ,ASSUNTO                                -- 3
                  ,MENSAGEM                               -- 4
                  ,EXCLUIDO                               -- 5
                  )
                  
           VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
                  ,SYSDATE                                -- 2
                  ,'MSN-4: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de antes de ontem'  -- 6
                   ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para antes de ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que não condizem com o histórico gravado para ontem (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||vrDADOS.DTMOV||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,'N');
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Caso não exista PCHISTEST para ontem e tenha movimentações */
          ELSIF ( --vsPROB_NO_HISTORICO = FALSE AND
                  vdDT_LOTE_ANTS_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                  vdDT_LOTE_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                ((vnQTLOTE_ANTS_ONTEM + vnSALDO_LOTE) <> 0)) THEN
            -- Criar mensagem para ser enviada via e-mail
            INSERT
              INTO PCMENSAGEMLOGFALHA
                  (CODMENS                                -- 1
                  ,DTREGISTRO                             -- 2
                  ,ASSUNTO                                -- 3
                  ,MENSAGEM                               -- 4
                  ,EXCLUIDO                               -- 5
                  )
           VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
                  ,SYSDATE                                -- 2
                  ,'MSN-5: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que apontam a necessidade de ter histórico gravado (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||vrDADOS.DTMOV||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,'N');
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Caso exista divergência do saldo anterior + saldo movimentado
          -- com relação ao saldo atual será gerada uma mensagem para os envolvidos
          ELSIF (--(vsPROB_NO_HISTORICO = FALSE) AND
                 (vnQTLOTE <> vnQTLOTE_ONTEM)) THEN
            -- Criar mensagem para ser enviada via e-mail
            INSERT
              INTO PCMENSAGEMLOGFALHA
                  (CODMENS                                -- 1
                  ,DTREGISTRO                             -- 2
                  ,ASSUNTO                                -- 3
                  ,MENSAGEM                               -- 4
                  ,EXCLUIDO                               -- 5
                  )
                  
           VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
                  ,SYSDATE                                -- 2
                  ,'MSN-6: O produto '|| PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' esta com problemas na filial '||PRODUTOS.CODFILIAL  -- 6
                   ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'O lote foi movimentado de forma errada para os dados abaixo: '||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||vrDADOS.DTMOV||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE de ontem............: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'O correto a ser gravado seria..........................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: É possível que o sistema tenha falhado na movimentação do estoque!'||CHR(13)||CHR(10)||
                   'Verifique na PCLOTELOG ou peça ajuda a TOTVS'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Não identificada!'
                  ,'N');                                -- 5
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          END IF;
        -- Fim da definição da mensagem
        END IF;
        -- Indo para a proxima linha do cursor
        FETCH vcCURSOR_LOTE INTO vrDADOS;
      -- Fim da lista dos produtos
      END LOOP;
      -- Fechando cursor
      CLOSE vcCURSOR_LOTE;
      -- Se não existir movimentações
      IF vnCONTREGISTROS = 0 THEN
        -- Atualiza variavel
        vnQTLOTE  := NVL(vnQTLOTE_ANTS_ONTEM,0);
        /*############################################
           Caso a mensagem seja para o usuário
        ############################################*/
        IF ptENTRADA_MONITOR.DESTINO <> 'TOTVS' THEN
          -- Caso não exista histórico antes de ontem
          IF (--vsPROB_NO_HISTORICO = FALSE AND
              vdDT_LOTE_ANTS_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vdDT_LOTE_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vnQTLOTE_ONTEM <> 0) THEN
            -- Criar mensagem para ser enviada para Luciana
            INSERT
              INTO PCRECFUNC
                  (CODFUNCAB                                                      -- 1
                  ,DTAB                                                           -- 2
                  ,CODSETORORIG                                                   -- 3
                  ,CODSETORDEST                                                   -- 4
                  ,CODFUNCDEST                                                    -- 5
                  ,ASSUNTO                                                        -- 6
                  ,TEXTORECADO                                                    -- 7
                  ,NUMRECADO                                                      -- 8
                  )
           VALUES (1                                                              -- 1
                  ,SYSDATE                                                        -- 2
                  ,1                                                              -- 3
                  ,1                                                              -- 4
                  ,ptENTRADA_MONITOR.CODUSUARIO                                                   -- 5
                  ,'MSN-7: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de antes de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para antes de ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que não condizem com o histórico gravado para ontem (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTMOVIMENTACAO,vdDT_LOTE_ONTEM)||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||                   
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,DFSEQ_PCRECFUNC.NEXTVAL
                  );
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;

          ELSIF (--vsPROB_NO_HISTORICO = FALSE AND
                 vdDT_LOTE_ANTS_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                 vdDT_LOTE_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                 vnQTLOTE_ANTS_ONTEM <> 0) THEN
            -- Criar mensagem para ser enviada para Luciana
            INSERT INTO PCRECFUNC
                  (CODFUNCAB                                                      -- 1
                  ,DTAB                                                           -- 2
                  ,CODSETORORIG                                                   -- 3
                  ,CODSETORDEST                                                   -- 4
                  ,CODFUNCDEST                                                    -- 5
                  ,ASSUNTO                                                        -- 6
                  ,TEXTORECADO                                                    -- 7
                  ,NUMRECADO                                                      -- 8
                  )
           VALUES (1                                                              -- 1
                  ,SYSDATE                                                        -- 2
                  ,1                                                              -- 3
                  ,1                                                              -- 4
                  ,ptENTRADA_MONITOR.CODUSUARIO                                                   -- 5
                  ,'MSN-8: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que apontam a necessidade de ter histórico gravado (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTMOVIMENTACAO,vdDT_LOTE_ONTEM)||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,DFSEQ_PCRECFUNC.NEXTVAL
                  );
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Caso exista histório
          ELSIF (--(vsPROB_NO_HISTORICO = FALSE) AND
                 (vnQTLOTE_ONTEM <> 0)) THEN
              -- Criar mensagem para ser enviada para Luciana
              INSERT INTO PCRECFUNC
                    (CODFUNCAB                                                      -- 1
                    ,DTAB                                                           -- 2
                    ,CODSETORORIG                                                   -- 3
                    ,CODSETORDEST                                                   -- 4
                    ,CODFUNCDEST                                                    -- 5
                    ,ASSUNTO                                                        -- 6
                    ,TEXTORECADO                                                    -- 7
                    ,NUMRECADO                                                      -- 8
                    )
             VALUES (1                                                              -- 1
                    ,SYSDATE                                                        -- 2
                    ,1                                                              -- 3
                    ,1                                                              -- 4
                    ,ptENTRADA_MONITOR.CODUSUARIO                                                   -- 5
                    ,'MSN-9: O produto '|| PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' esta com problemas na filial '||PRODUTOS.CODFILIAL  -- 6
                    ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                     'O lote foi movimentado de forma errada para os dados abaixo: '||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                     'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                     'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                     'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                     'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                     'No dia '||DECODE(vdDT_LOTE_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTMOVIMENTACAO,vdDT_LOTE_ONTEM)||
                     'O sistema gravaou na PCHISTESTLOTE de ontem............: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                     'O correto a ser gravado seria..........................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                     'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                     'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                     'Possível Motivo: É possível que o sistema tenha falhado na movimentação do estoque!'||CHR(13)||CHR(10)||
                     'Verifique na PCLOTELOG ou peça ajuda a TOTVS'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                     'Possivel solução: Não identificada!'
                    ,DFSEQ_PCRECFUNC.NEXTVAL
                    );
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          END IF;
        /*############################################
           Caso a mensagem seja para a TOTVS
        ############################################*/
        ELSE
          -- Caso não exista histórico antes de ontem
          IF (--vsPROB_NO_HISTORICO = FALSE AND
              vdDT_LOTE_ANTS_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vdDT_LOTE_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
              vnQTLOTE_ONTEM <> 0) THEN
            -- Criar mensagem para ser enviada via e-mail
            INSERT
              INTO PCMENSAGEMLOGFALHA
                  (CODMENS                                -- 1
                  ,DTREGISTRO                             -- 2
                  ,ASSUNTO                                -- 3
                  ,MENSAGEM                               -- 4
                  ,EXCLUIDO                               -- 5
                  )
           VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
                  ,SYSDATE                                -- 2
                  ,'MSN-10: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de antes de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para antes de ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que não condizem com o histórico gravado para ontem (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTMOVIMENTACAO,vdDT_LOTE_ONTEM)||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,'N');
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Caso não exista PCHISTEST para ontem e tenha movimentações */
          ELSIF (--vsPROB_NO_HISTORICO = FALSE AND
                 vdDT_LOTE_ANTS_ONTEM <> TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                 vdDT_LOTE_ONTEM = TO_DATE('30/DEC/1899','DD/MM/YYYY') AND
                 vnQTLOTE_ANTS_ONTEM <> 0) THEN
            -- Criar mensagem para ser enviada via e-mail
            INSERT
              INTO PCMENSAGEMLOGFALHA
                  (CODMENS                                -- 1
                  ,DTREGISTRO                             -- 2
                  ,ASSUNTO                                -- 3
                  ,MENSAGEM                               -- 4
                  ,EXCLUIDO                               -- 5
                  )
           VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1       
                  ,SYSDATE                                -- 2
                  ,'MSN-11: Não existe histórico do produto '||PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' na data de ontem'  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'Não existe histórico para ontem (PCHISTESTLOTE)'||CHR(13)||CHR(10)||
                   'Porem existe movimentações que apontam a necessidade de ter histórico gravado (veja dados abaixo):'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTMOVIMENTACAO,vdDT_LOTE_ONTEM)||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE.....................: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'Quando deveria gravar..................................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: A rotina 504 não foi executada de forma correta!'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Executar a opção 22, "Consolidação de Dados Histórico - Diária" localizada na aba "Outros" da rotina 507.'
                  ,'N');
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          -- Caso exista divergência do saldo anterior + saldo movimentado
          -- com relação ao saldo atual será gerada uma mensagem para os envolvidos
          ELSIF (--(vsPROB_NO_HISTORICO = FALSE) AND
                 (vnQTLOTE_ONTEM <> 0)) THEN
            -- Criar mensagem para ser enviada via e-mail
            INSERT
              INTO PCMENSAGEMLOGFALHA
                  (CODMENS                                -- 1
                  ,DTREGISTRO                             -- 2
                  ,ASSUNTO                                -- 3
                  ,MENSAGEM                               -- 4
                  ,EXCLUIDO                               -- 5
                  )
           VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
                  ,SYSDATE                                -- 2
                  ,'MSN-12: O produto '|| PRODUTOS.CODPROD||' lote '||PRODUTOS.NUMLOTE||' esta com problemas na filial '||PRODUTOS.CODFILIAL  -- 6
                  ,'Erro de Sistema: '||CHR(13)||CHR(10)||
                   'O lote foi movimentado de forma errada para os dados abaixo: '||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Código da filial.......................................: '||PRODUTOS.CODFILIAL||CHR(13)||CHR(10)||
                   'Código do produto......................................: '||PRODUTOS.CODPROD||CHR(13)||CHR(10)||
                   'Numero de Lote.........................................: '||PRODUTOS.NUMLOTE||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ANTS_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTBASE,vdDT_LOTE_ANTS_ONTEM)||' o saldo do lote era de................: '||NVL(vnQTLOTE_ANTS_ONTEM,0)||CHR(13)||CHR(10)||
                   'No dia '||DECODE(vdDT_LOTE_ONTEM,TO_DATE('30/DEC/1899','DD/MM/YYYY'),pdDTMOVIMENTACAO,vdDT_LOTE_ONTEM)||' foi movimentado.......................: '||NVL(vnSALDO_LOTE,0)||CHR(13)||CHR(10)||
                   'O sistema gravaou na PCHISTESTLOTE de ontem............: '||NVL(vnQTLOTE_ONTEM,0)||CHR(13)||CHR(10)||
                   'O correto a ser gravado seria..........................: '||NVL(vnQTLOTE,0)||CHR(13)||CHR(10)||
                   'Logo para este dia existiu uma diferença de............: '||(NVL(vnQTLOTE,0) - NVL(vnQTLOTE_ONTEM,0))||CHR(13)||CHR(10)||
                   'Produto excluído.......................................: '||DECODE(vtPRODUTO.DTEXCLUSAO,null,'Não','Sim')||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possível Motivo: É possível que o sistema tenha falhado na movimentação do estoque!'||CHR(13)||CHR(10)||
                   'Verifique na PCLOTELOG ou peça ajuda a TOTVS'||CHR(13)||CHR(10)||CHR(13)||CHR(10)||
                   'Possivel solução: Não identificada!'
                  ,'N');                                -- 5
            -- Atualizar variável para não repetir validação
            --vsPROB_NO_HISTORICO := TRUE;
          END IF;
        -- Mensagem
        END IF;
      -- Produtos sem movimentações
      END IF;
    -- Lista de produtos
    END LOOP;
    -- Commit
    COMMIT;
  -- Procedure
  END PRC_MONITORAR_LOTE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  18/09/2015     Fernandes Brito                       Criada a PROCEDURE para monitorar o estoque reservado
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure para incluida a função PRAGMA AUTONOMOUS_TRANSACTION para
                                                       assegurar que o update executado será apenas na tabela PCMENSAGEMLOGFALHA
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MON_RESERV
  IS
    -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- Lista de produtos com problema de reserva
    FOR DADOS IN (SELECT * FROM TABLE(F_ANALISAR_ESTOQUE(NULL,NULL)))
    LOOP
      -- Insert na tabela de log para envio do e-mail
      INSERT
        INTO PCMENSAGEMLOGFALHA
            (CODMENS                                -- 1
            ,DTREGISTRO                             -- 2
            ,ASSUNTO                                -- 3
            ,MENSAGEM                               -- 4
            ,EXCLUIDO                               -- 5
            )
     VALUES (DFSEQ_PCMENSAGEMLOGFALHA.NEXTVAL       -- 1
            ,SYSDATE                                -- 2
            ,'ANALISAR ESTOQUE RESERVADO DO PRODUTO '||DADOS.CODPROD
            ,'O produto '||DADOS.CODPROD||' esta com divegência na filial '||DADOS.CODFILIAL||CHR(13)||
             'Dados para analise previa: '||CHR(13)||
             'Cód Filial........: '||DADOS.CODFILIAL||CHR(13)||
             'Cód Produto.......: '||DADOS.CODPROD||CHR(13)||
             'Qtde Gerencial....: '||DADOS.ESTOQUE_ATUAL||CHR(13)||
             'Qtde Reserv. Atual: '||DADOS.QTRESERVADA_ATUAL||CHR(13)||
             'Qtde Reserv. Ped..: '||DADOS.QTRESERVADA_PEDIDOS||CHR(13)||
             'Qtde Pend. Atual..: '||DADOS.QTPENDENTE_ATUAL||CHR(13)||
             'Qtde Pend. Ped....: '||DADOS.QTPENDENTE_PEDIDOS||CHR(13)
            ,'N');                                  -- 5
      -- Confirmando os dados desta transação
      COMMIT;
    -- Fim da lista de produtos com problemas
    END LOOP;
  -- Fim da procedure
  END PRC_MON_RESERV;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  21/05/2015     Fernandes Brito                       Criada a função para unificar a busca dos dados CONTABEIS na PCMOV
  29/09/2015     Fernandes Brito                       Alterada a Função para Procedure para criar uma tabela fisica no lugar do PIPELINED
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure para sempre deletar os dados da tabela PCSALDOMOVCONTABEIS e
                                                       incluida a função PRAGMA AUTONOMOUS_TRANSACTION para acegurar que o update executado
                                                       será apenas na tabela PCSALDOMOVCONTABEIS
  08/09/2016     Fernandes Brito                       Incluida a função CLOSE para fechar a variável vcCURSOR_CONT e assim
                                                       evitar problemas com lixo no cursor
  14/02/2017     Fernandes Brito                       Alterada para retirar a criação da tabela e colocar na procedure PRC_LIMPAR_SALDOS
  06/04/2017     Fernandes Brito                       Alterada a função para usar a data da movimentação (PCMOV.DTMOV). Isso se faz necessário
                                                       para formar o histórico da forma correta, caso a nota fiscal seja de um dia e o
                                                       cancelamento da mesma tenha ocorrido no dia seguinte.
  03/07/2017     Fábio Figueiredo                      Corrigido o select para não listar as notas tipo F.  --aqui
  16/11/2020     Fernandes Brito                       Ajustada a procedure para gravar os dados contábeis já levando em conta a lista de dias.

  Observações:
  Para saber mais sobre o parâmetro "psTIPOCHAMADA" veja cabeçalho da procedure PRC_RECALCULO
  CORRETO: Busca apenas notas fiscais que são reconhecidas pelo SEFAZ.
  Qualquer outro: Busca todas as notas fiscal geradas pelo sistema, mesmo que ela não seja reconhecida como nota no SEFAZ
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MOV_CONT (psCODFILIAL       IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                         ,pnCODPROD         IN PCMOV.CODPROD%TYPE DEFAULT NULL
                         ,pdDTINICIAL       IN PCMOV.DTMOV%TYPE
                         ,pdDTFINAL         IN PCMOV.DTMOV%TYPE
                         ,psTIPOCHAMADA     IN VARCHAR2 DEFAULT NULL)
IS
    -- Variaveis de uso interno
    vcCURSOR_CONT          SYS_REFCURSOR;
    -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- Se usar função da rotina 1070
    IF P_INTERNOS.USA_FUNCAO_1070 = 'S' THEN
      -- Buscar dados da função
      FOR DADOS IN (SELECT PCLISTADIAS.ID
                          ,PCLISTADIAS.DATA DTMOV
                          ,NVL(DADOS.CODFILIAL,psCODFILIAL) CODFILIAL
                          ,NVL(DADOS.CODPROD,pnCODPROD) CODPROD
                          ,NULL LOTE
                          ,SUM(QTENTRADA - QTSAIDA) SALDO
                      FROM PCLISTADIAS
                          ,(TABLE(F_CONTROLE_PRODUCAO(psCODFILIAL----------------------------- CODFILIAL
                                                     ,pdDTINICIAL----------------------------- DATA1
                                                     ,pdDTFINAL------------------------------- DATA2
                                                     ,NULL------------------------------------ DATA ESTQOUE (PCHISTEST)
                                                     ,0--------------------------------------- TIPO DE CUSTO
                                                     ,'S'------------------------------------- INCLUIR PROD_SEM_MOV
                                                     ,'N'------------------------------------- UTILIZA MET PEPS
                                                     ,'N'------------------------------------- UTILIZA PREÇO NOTA
                                                     ,3--------------------------------------- CASAS DEC QT
                                                     ,6--------------------------------------- CASAS DEC PUNIT
                                                     ,2--------------------------------------- CASAS DEC VLTOTAL
                                                     ,'N'------------------------------------- USO E CONSUMO
                                                     ,'N'------------------------------------- ATIV.IMOBILIZADO
                                                     ,'S'------------------------------------- GERA CANC. DE PRODUÇÃO
                                                     ,'N'------------------------------------- GERA COD.OPER KARDEX
                                                     ,pnCODPROD------------------------------- COD PROD 1
                                                     ,pnCODPROD------------------------------- COD PROD 2
                                                     ,'N'------------------------------------- VENDA MANIF TV14
                                                     ,'N'------------------------------------- GERA SM KARDEX CANC
                                                     ,'S'------------------------------------- GERA NF ENTRADA CANCELADA
                                                     ,'S'------------------------------------- GERA NF SAIDA CANCELADA
                                                     ,'N'------------------------------------- DESCONSIDERA NF TRASNF DEPOSITO
                                                     ,'N'------------------------------------- UTILIZA PROCEDURE
                                                     ,'S'------------------------------------- DESCONS.NF DENEGADA
                                                     ,'S'------------------------------------- MOSTRAR CUSTOS DE IMPORTAÇÃO
                                                     ,'N'------------------------------------- ORDERNAR PELO DTMOVLOG
                                                     ,'N'------------------------------------- GERAR NUMOP NA OBSERVAÇÃO
                                                     ,'N'------------------------------------- CONSIDERA CUSTO NA BONIFICAÇÃO
                                                     ,'N'------------------------------------- DESCONSIDERA CALCULO MÉDIO DEV CLI
                                                     ,'S'------------------------------------- DESCONSIDERA ENT ER TV20
                                                     ,'S')------------------------------------ DESCONSIDERA CALCULO MÉDIO DEV CLI
                           )) DADOS
                     WHERE PCLISTADIAS.DATA = DADOS.DATA(+)
                       AND PCLISTADIAS.ID = 'CONTABIL'
                       AND DADOS.TIPO NOT IN ('EP','EF','ES','ER')
                  GROUP BY PCLISTADIAS.ID
                          ,PCLISTADIAS.DATA
                          ,NVL(DADOS.CODFILIAL,psCODFILIAL)
                          ,NVL(DADOS.CODPROD,pnCODPROD)
                  ORDER BY PCLISTADIAS.DATA
                          ,NVL(DADOS.CODFILIAL,psCODFILIAL)
                          ,NVL(DADOS.CODPROD,pnCODPROD))
      -- Enquanto não chegar no final das linhas faça
      LOOP
        -- Preparando o insert na tabela de saldo de movimentações contábies
        vsINSERT := 'INSERT
                       INTO PCSALDOMOVCONTABEIS
                           (ID
                           ,DTMOV
                           ,CODFILIAL
                           ,CODPROD
                           ,SALDO)
                   VALUES ('||CHR(39)||DADOS.ID||CHR(39)||'
                          ,'||CHR(39)||DADOS.DTMOV||CHR(39)||'
                          ,'||CHR(39)||DADOS.CODFILIAL||CHR(39)||'
                          ,'||DADOS.CODPROD||'
                          ,'||CHR(39)||DADOS.SALDO||CHR(39)||')';
        -- Executando o Insert
        EXECUTE IMMEDIATE vsINSERT;
      -- Fim da lista de movimentações
      END LOOP;
   -- Usar select
   ELSE
      -- Montar selects para os dados Contábies
      vsSQL:=' SELECT PCLISTADIAS.ID
                     ,PCLISTADIAS.DATA DTMOV
                     ,NVL(DADOS.CODFILIAL,'||CHR(39)||psCODFILIAL||CHR(39)||') CODFILIAL
                     ,NVL(DADOS.CODPROD,'||pnCODPROD||') CODPROD
                     ,NULL LOTE
                     ,NVL(SUM(DADOS.SALDO),0) SALDO
                FROM PCLISTADIAS
                    ,(-- Notas Fiscais de Entrada Normal */
                      SELECT PCNFENT.DTENT DTMOV
                            ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                            ,PCMOV.CODPROD
                            ,NVL(SUM(CASE
                                       WHEN SUBSTR(PCMOV.CODOPER, 1, 1) = ''E'' THEN
                                       DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                              0,
                                              ROUND(PCMOV.QTCONT, 6),
                                              ROUND(PCMOVCOMPLE.QTRETORNOTV13, 6))
                                       ELSE
                                        0
                                     END),
                                 0) SALDO
                        FROM PCNFENT
                            ,PCMOV
                            ,PCMOVCOMPLE
                       WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                         AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                         AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                         AND PCNFENT.DTENT BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND CODPROD = '||pnCODPROD||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                         AND PCMOV.QTCONT > 0
                         AND PCNFENT.TIPODESCARGA NOT IN (''F'', ''P'', ''H'',''G'')'||CHR(13);
     IF psTIPOCHAMADA = 'CORRETO' THEN
       vsSQL := vsSQL||'                         AND PCNFENT.ESPECIE IN (''NF'',''OE'')'||CHR(13);

     ELSE
       vsSQL := vsSQL||'                         AND PCNFENT.ESPECIE IN (''NF'',''OE'',''NP'',''NE'',''TP'')'||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND PCMOV.STATUS IN (''A'', ''AB'')
                         AND NVL(PCNFENT.FINALIDADENFE, ''O'') <> ''C''
                    GROUP BY PCNFENT.DTENT,
                             NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                             PCMOV.CODPROD
                       ---------------------------------------------------------
                       UNION ALL
                       ---------------------------------------------------------
                      -- Notas Fiscais de Entrada Canceladas */
                      SELECT TRUNC(PCMOV.DTCANCEL) DTMOV
                            ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                            ,PCMOV.CODPROD
                            ,NVL(SUM(CASE
                                       WHEN SUBSTR(PCMOV.CODOPER, 1, 1) = ''E'' THEN
                                       DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                              0,
                                              ROUND(PCMOV.QTCONT, 6),
                                              ROUND(PCMOVCOMPLE.QTRETORNOTV13, 6))
                                       ELSE
                                        0
                                     END),
                                 0) SALDO
                        FROM PCNFENT
                            ,PCMOV
                            ,PCMOVCOMPLE
                       WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                         AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                         AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                         AND PCMOV.DTCANCEL BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND CODPROD = '||pnCODPROD||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                         AND PCMOV.DTCANCEL IS NOT NULL
                         AND PCMOV.QTCONT < 0
                         AND PCNFENT.TIPODESCARGA NOT IN (''F'', ''P'', ''H'',''G'')'||CHR(13);
     IF psTIPOCHAMADA = 'CORRETO' THEN
       vsSQL := vsSQL||'                         AND PCNFENT.ESPECIE IN (''NF'',''OE'')'||CHR(13);

     ELSE
       vsSQL := vsSQL||'                         AND PCNFENT.ESPECIE IN (''NF'',''OE'',''NP'',''NE'',''TP'')'||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND PCMOV.STATUS IN (''A'', ''AB'')
                         AND NVL(PCNFENT.FINALIDADENFE, ''O'') <> ''C''
                    GROUP BY PCMOV.DTCANCEL,
                             NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                             PCMOV.CODPROD
                       ---------------------------------------------------------
                       UNION ALL
                       ---------------------------------------------------------
                      -- Notas Fiscais de Saída Normal */
                      SELECT PCNFSAID.DTSAIDA DTMOV
                            ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                            ,PCMOV.CODPROD
                            ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''S'', (ROUND(PCMOV.QTCONT, ''6'') * (-1)), 0)), 0) SALDO
                        FROM PCNFSAID
                            ,PCMOV
                            ,PCMOVCOMPLE
                       WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                         AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                         AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                         AND PCNFSAID.DTSAIDA BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND CODPROD = '||pnCODPROD||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND (NVL(PCNFSAID.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 14) OR (NVL(PCNFSAID.CONDVENDA, 0) = 7 AND NVL(PCNFSAID.FORNECENTREGA, ''N'') = ''S''))
                         AND PCMOV.QTCONT > 0
                         AND NVL(PCMOVCOMPLE.MOVEST,''S'') = ''S''
                         AND PCMOV.CODFISCAL NOT IN (5929, 6929)'||CHR(13);
     IF psTIPOCHAMADA = 'CORRETO' THEN
       vsSQL := vsSQL||'                         AND PCNFSAID.ESPECIE IN (''NF'', ''CF'',''CP'')'||CHR(13);
     ELSE
       vsSQL := vsSQL||'                         AND PCNFSAID.ESPECIE IN (''NF'', ''CF'',''NP'', ''CP'',''NE'')'||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND PCMOV.STATUS IN (''A'', ''AB'')
                         AND NVL(PCNFSAID.FINALIDADENFE, ''O'') <> ''C''
                         AND PCNFSAID.TIPOVENDA <> ''SE''
                    GROUP BY PCNFSAID.DTSAIDA,
                             NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                             PCMOV.CODPROD
                      ---------------------------------------------------------
                      UNION ALL
                      ---------------------------------------------------------
                      -- Notas Fiscais de Saída Canceladas */
                      SELECT TRUNC(PCMOV.DTCANCEL) DTMOV
                            ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                            ,PCMOV.CODPROD
                            ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''S'', (ROUND(PCMOV.QTCONT, ''6'') * (-1)), 0)), 0) SALDO
                        FROM PCNFSAID
                            ,PCMOV
                            ,PCMOVCOMPLE
                       WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                         AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                         AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                         AND PCMOV.DTCANCEL BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND CODPROD = '||pnCODPROD||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND (NVL(PCNFSAID.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 14) OR (NVL(PCNFSAID.CONDVENDA, 0) = 7 AND NVL(PCNFSAID.FORNECENTREGA, ''N'') = ''S''))
                         AND PCMOV.DTCANCEL IS NOT NULL
                         AND PCMOV.QTCONT < 0
                         AND NVL(PCMOVCOMPLE.MOVEST,''S'') = ''S''
                         AND PCMOV.CODFISCAL NOT IN (5929, 6929)'||CHR(13);
     IF psTIPOCHAMADA = 'CORRETO' THEN
       vsSQL := vsSQL||'                         AND PCNFSAID.ESPECIE IN (''NF'', ''CF'',''CP'')'||CHR(13);
     ELSE
       vsSQL := vsSQL||'                         AND PCNFSAID.ESPECIE IN (''NF'', ''CF'',''NP'', ''CP'',''NE'')'||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND PCMOV.STATUS IN (''A'', ''AB'')
                         AND NVL(PCNFSAID.FINALIDADENFE, ''O'') <> ''C''
                         AND PCNFSAID.TIPOVENDA <> ''SE''
                    GROUP BY PCMOV.DTCANCEL,
                             NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                             PCMOV.CODPROD
                      ---------------------------------------------------------
                      UNION ALL
                      ---------------------------------------------------------
                      -- Movimentações sem NFs */
                      SELECT PCMOV.DTMOV
                            ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                            ,PCMOV.CODPROD
                            ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', ROUND(PCMOV.QTCONT, 6), (ROUND(PCMOV.QTCONT, 6) * (-1)))), 0) QTENTRADA
                        FROM PCMOV
                       WHERE PCMOV.DTMOV BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN       
       vsSQL := vsSQL||'                         AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND CODPROD = '||pnCODPROD||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND PCMOV.CODOPER IN (''EP'', ''SP'', ''EA'', ''SA'', ''EX'', ''RA'')
                         AND NOT EXISTS (SELECT 1
                                           FROM PCNFSAID
                                          WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                            AND PCNFSAID.ESPECIE IN (''NF'', ''CF'',''NP'', ''CP'',''NE'')'||CHR(13);
IF psCODFILIAL IS NOT NULL THEN
  vsSQL := vsSQL||'                         AND NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
END IF;                        
  vsSQL := vsSQL||'                         AND PCNFSAID.VLTOTAL > 0)
                         AND PCMOV.STATUS IN (''A'', ''AB'')
                    GROUP BY PCMOV.DTMOV,
                             NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                             PCMOV.CODPROD) DADOS
              WHERE PCLISTADIAS.DATA = DADOS.DTMOV (+)
                AND PCLISTADIAS.ID = ''CONTABIL''
           GROUP BY PCLISTADIAS.ID
                   ,PCLISTADIAS.DATA
                   ,NVL(DADOS.CODFILIAL,'||CHR(39)||psCODFILIAL||CHR(39)||')
                   ,NVL(DADOS.CODPROD,'||pnCODPROD||')
           ORDER BY NVL(DADOS.CODFILIAL,'||CHR(39)||psCODFILIAL||CHR(39)||')
                   ,NVL(DADOS.CODPROD,'||pnCODPROD||')';
      /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsSQL, 1);
      COMMIT; --*/
      -- Abrindo o cursor com base no sql
      OPEN vcCURSOR_CONT FOR vsSQL;
      -- Buscando os dados da primeira linha do cursor
      FETCH vcCURSOR_CONT INTO vrDADOS;
      -- Enquanto não chegar no final das linhas faça
      WHILE NOT vcCURSOR_CONT%NOTFOUND LOOP
        -- Preparando o insert na tabela de saldo de movimentações contábies
        vsINSERT := 'INSERT
                       INTO PCSALDOMOVCONTABEIS
                           (ID
                           ,DTMOV
                           ,CODFILIAL
                           ,CODPROD
                           ,SALDO)
                   VALUES ('||CHR(39)||vrDADOS.ID||CHR(39)||'
                          ,'||CHR(39)||vrDADOS.DTMOV||CHR(39)||'
                          ,'||CHR(39)||vrDADOS.CODFILIAL||CHR(39)||'
                          ,'||vrDADOS.CODPROD||'
                          ,'||CHR(39)||vrDADOS.SALDO||CHR(39)||')';
        -- Executando o Insert
        EXECUTE IMMEDIATE vsINSERT;
        -- Indo para a proxima linha do cursor
        FETCH vcCURSOR_CONT INTO vrDADOS;
      -- Fim da lista de movimentações
      END LOOP;
      -- Fechando o curso
      CLOSE vcCURSOR_CONT;
    -- Fim valida função
    END IF;
    -- Confirmando os dados desta transação
    COMMIT;
  -- Fim da procedure
  END PRC_MOV_CONT;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  24/08/2015     Fernandes Brito                       Criada procedure para listar as movimentações dos endereços (WMS)
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MOV_END (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                        ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                        ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                        ,pdDTFINAL   IN PCMOV.DTMOV%TYPE)
  IS
    -- Variaveis de uso interno
    vcCURSOR_ENDERECO      SYS_REFCURSOR;
   -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     vsSQL := 'SELECT ''ENDERECO'' ID
                       ,DATA DTMOV
                       ,CODFILIAL
                       ,CODPROD
                       ,NULL NUMLOTE
                       ,SUM(DECODE(SUBSTR(CODOPER,1,1),''E'',QT,(QT * (-1)))) SALDO
                 FROM (SELECT PCMOVENDPEND.DATA,
                              NVL(PCMOVENDPEND.CODFILIAL, PCENDERECO.CODFILIAL) CODFILIAL,
                              PCMOVENDPEND.CODPROD,
                              PCMOVENDPEND.CODOPER,
                              PCMOVENDPEND.QT
                         FROM PCMOVENDPEND, PCPRODUT, PCENDERECO
                        WHERE PCMOVENDPEND.CODPROD = PCPRODUT.CODPROD
                          AND PCMOVENDPEND.NUMTRANSWMS IS NOT NULL
                          AND PCMOVENDPEND.CODENDERECO = PCENDERECO.CODENDERECO
                          AND PCENDERECO.STATUS <> ''A''
                          AND PCMOVENDPEND.POSICAO IN (''C'')
                          AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''N''
                          AND PCMOVENDPEND.DATA BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
      IF psCODFILIAL IS NOT NULL THEN
        vsSQL := vsSQL||'                          AND NVL(PCMOVENDPEND.CODFILIAL, PCENDERECO.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
      END IF;
      IF pnCODPROD IS NOT NULL THEN
        vsSQL := vsSQL||'                          AND PCPRODUT.CODPROD = '||pnCODPROD||CHR(13);
      END IF;
        vsSQL := vsSQL||'                          AND NOT EXISTS (SELECT 1
                                            FROM PCBLOQUEIOEST
                                           WHERE PCBLOQUEIOEST.NUMTRANSWMS = PCMOVENDPEND.NUMTRANSWMS
                                             AND PCBLOQUEIOEST.CODPROD = PCMOVENDPEND.CODPROD
                                             AND PCMOVENDPEND.CODOPER <> ''E''
                                             AND PCBLOQUEIOEST.NUMTRANSWMS IS NOT NULL)
                        UNION ALL
                       SELECT TRUNC(PCBLOQUEIOEST.DTLANC) DATA,
                              NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) CODFILIAL,
                              PCBLOQUEIOEST.CODPROD,
                              PCBLOQUEIOEST.CODOPER,
                              PCMOVENDPEND.QT
                         FROM PCBLOQUEIOEST, PCPRODUT, PCMOVENDPEND, PCENDERECO
                        WHERE PCBLOQUEIOEST.CODPROD = PCPRODUT.CODPROD
                          AND PCENDERECO.CODENDERECO = PCBLOQUEIOEST.CODENDERECO
                          AND PCMOVENDPEND.CODENDERECO = PCBLOQUEIOEST.CODENDERECO
                          AND PCBLOQUEIOEST.NUMTRANSWMS = PCMOVENDPEND.NUMTRANSWMS
                          AND PCMOVENDPEND.CODPROD = PCPRODUT.CODPROD
                          AND PCBLOQUEIOEST.NUMTRANSWMS IS NOT NULL
                          AND PCMOVENDPEND.POSICAO IN (''C'')
                          AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''N''
                          AND TRUNC(PCBLOQUEIOEST.DTLANC) BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
      IF psCODFILIAL IS NOT NULL THEN
        vsSQL := vsSQL||'                          AND NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
      END IF;
      IF pnCODPROD IS NOT NULL THEN
        vsSQL := vsSQL||'                          AND PCPRODUT.CODPROD = '||pnCODPROD||CHR(13);
      END IF;
      vsSQL := vsSQL||'                        UNION ALL
                       SELECT *
                         FROM (SELECT TRUNC(PCBLOQUEIOEST.DTLANC) DATA,
                                      NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL),
                                      PCBLOQUEIOEST.CODPROD,
                                      CASE
                                        WHEN PCBLOQUEIOEST.CODOPER = ''EV'' AND
                                             NVL(PCBLOQUEIOEST.CODENDERECOORIG, 0) > 0 THEN
                                         ''SV''
                                        WHEN PCBLOQUEIOEST.CODOPER = ''ER'' AND
                                             NVL(PCBLOQUEIOEST.CODENDERECOORIG, 0) > 0 THEN
                                         ''SR''
                                        ELSE
                                         PCBLOQUEIOEST.CODOPER
                                      END CODOPER,
                                      PCMOVENDPEND.QT
                                 FROM PCBLOQUEIOEST, PCPRODUT, PCMOVENDPEND, PCENDERECO
                                WHERE PCBLOQUEIOEST.CODPROD = PCPRODUT.CODPROD
                                  AND PCMOVENDPEND.CODPROD = PCPRODUT.CODPROD
                                  AND PCMOVENDPEND.CODENDERECO = PCENDERECO.CODENDERECO
                                  AND PCBLOQUEIOEST.NUMTRANSWMS = PCMOVENDPEND.NUMTRANSWMS
                                  AND PCBLOQUEIOEST.CODENDERECOORIG = PCENDERECO.CODENDERECO
                                  AND PCBLOQUEIOEST.NUMTRANSWMS IS NOT NULL
                                  AND PCMOVENDPEND.POSICAO IN (''C'')
                                  AND PCBLOQUEIOEST.CODOPER NOT IN (''SR'', ''ER'')
                                  AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''N''
                                  AND TRUNC(PCBLOQUEIOEST.DTLANC) BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
              IF psCODFILIAL IS NOT NULL THEN
                vsSQL := vsSQL||'                                  AND NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
              END IF;
              IF pnCODPROD IS NOT NULL THEN
                vsSQL := vsSQL||'                                  AND PCPRODUT.CODPROD = '||pnCODPROD||CHR(13);
              END IF;
           vsSQL := vsSQL||'                             ORDER BY TRUNC(PCBLOQUEIOEST.DTLANC)
                                     ,NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL)
                                     ,CODPROD
                                     ,CODOPER) TAB)
                    GROUP BY DATA
                            ,CODFILIAL
                            ,CODPROD
                            ,CODOPER';
    /*INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsSQL, 1);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vcCURSOR_ENDERECO FOR vsSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vcCURSOR_ENDERECO INTO vrDADOS;
     
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vcCURSOR_ENDERECO%NOTFOUND LOOP
      -- Preparando o insert na tabela de saldo de movimentações contábies
         vsINSERT := 'INSERT
                INTO PCSALDOMOVENDERECO
                         (ID
                         ,DTMOV
                         ,CODFILIAL
                         ,CODPROD
                         ,SALDO)
                 VALUES ('||CHR(39)||vrDADOS.ID||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.DTMOV||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.CODFILIAL||CHR(39)||'
                        ,'||vrDADOS.CODPROD||'
                        ,'||CHR(39)||vrDADOS.SALDO||CHR(39)||')';
      -- Executando o Insert
      EXECUTE IMMEDIATE vsINSERT;
      -- Indo para a proxima linha do cursor
      FETCH vcCURSOR_ENDERECO INTO vrDADOS;
    -- Fim da lista de movimentações
    END LOOP;
    -- Fechando o curso
    CLOSE vcCURSOR_ENDERECO;
    -- Confirmando os dados desta transação
    COMMIT;
  -- Fim da procedure
  END PRC_MOV_END;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  24/08/2015     Fernandes Brito                       Criada procedure para listar as movimentações dos endereços (WMS)
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MOV_END_LOTE (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                             ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                             ,psNUMLOTE   IN PCMOV.NUMLOTE%TYPE DEFAULT NULL
                             ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                             ,pdDTFINAL   IN PCMOV.DTMOV%TYPE)
  IS
    -- Variaveis de uso interno
    vcCURSOR_ENDERECO      SYS_REFCURSOR;
   -- Criação de uma nova transação no oracle para comitar no final
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     vsSQL := 'SELECT ''ENDERECOLOTE'' ID
                      ,DATA DTMOV
                      ,CODFILIAL
                      ,CODPROD
                      ,NUMLOTE
                      ,SUM(DECODE(SUBSTR(CODOPER,1,1),''E'',QT,(QT * (-1)))) SALDO
                FROM (SELECT PCMOVENDPEND.DATA,
                             NVL(PCMOVENDPEND.CODFILIAL, PCENDERECO.CODFILIAL) CODFILIAL,
                             PCMOVENDPEND.CODPROD,
                             PCMOVENDPEND.NUMLOTE,
                             CODOPER,
                             PCMOVENDPEND.QT
                        FROM PCMOVENDPEND, PCPRODUT, PCENDERECO
                       WHERE PCMOVENDPEND.CODPROD = PCPRODUT.CODPROD
                         AND PCMOVENDPEND.CODENDERECO = PCENDERECO.CODENDERECO
                         AND PCENDERECO.STATUS <> ''A''
                         AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''S''
                         AND PCMOVENDPEND.NUMTRANSWMS IS NOT NULL
                         AND PCMOVENDPEND.POSICAO IN (''C'')
                         AND PCMOVENDPEND.DATA BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND NVL(PCMOVENDPEND.CODFILIAL, PCENDERECO.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND PCPRODUT.CODPROD = '||pnCODPROD||CHR(13);
     END IF;
     IF psNUMLOTE IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND PCMOVENDPEND.NUMLOTE = '||CHR(39)||psNUMLOTE||CHR(39)||CHR(13);
     END IF;
       vsSQL := vsSQL||'                         AND NOT EXISTS (SELECT 1
                                           FROM PCBLOQUEIOEST
                                          WHERE PCBLOQUEIOEST.NUMTRANSWMS = PCMOVENDPEND.NUMTRANSWMS
                                            AND PCBLOQUEIOEST.CODPROD = PCMOVENDPEND.CODPROD
                                            AND PCMOVENDPEND.CODOPER <> ''E''
                                            AND PCBLOQUEIOEST.NUMTRANSWMS IS NOT NULL)
                       UNION ALL
                      SELECT TRUNC(PCBLOQUEIOEST.DTLANC) DATA,
                             NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) CODFILIAL,
                             PCBLOQUEIOEST.CODPROD,
                             PCMOVENDPEND.NUMLOTE,
                             PCBLOQUEIOEST.CODOPER,
                             PCMOVENDPEND.QT
                        FROM PCBLOQUEIOEST, PCPRODUT, PCMOVENDPEND, PCENDERECO
                       WHERE PCBLOQUEIOEST.CODPROD = PCPRODUT.CODPROD
                         AND PCENDERECO.CODENDERECO = PCBLOQUEIOEST.CODENDERECO
                         AND PCMOVENDPEND.CODENDERECO = PCBLOQUEIOEST.CODENDERECO
                         AND PCBLOQUEIOEST.NUMTRANSWMS = PCMOVENDPEND.NUMTRANSWMS
                         AND PCMOVENDPEND.CODPROD = PCPRODUT.CODPROD
                         AND PCBLOQUEIOEST.NUMTRANSWMS IS NOT NULL
                         AND PCBLOQUEIOEST.CODOPER IN (''SR'', ''ER'')
                         AND PCMOVENDPEND.POSICAO IN (''C'')
                         AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''S''
                         AND TRUNC(PCBLOQUEIOEST.DTLANC) BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
     IF psCODFILIAL IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
     END IF;
     IF pnCODPROD IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND PCPRODUT.CODPROD = '||pnCODPROD||CHR(13);
     END IF;
     IF psNUMLOTE IS NOT NULL THEN
       vsSQL := vsSQL||'                         AND PCMOVENDPEND.NUMLOTE = '||CHR(39)||psNUMLOTE||CHR(39)||CHR(13);
     END IF;
     vsSQL := vsSQL||'                       UNION ALL
                      SELECT *
                        FROM (SELECT TRUNC(PCBLOQUEIOEST.DTLANC) DATA,
                                     NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) CODFILIAL,
                                     PCBLOQUEIOEST.CODPROD,
                                     PCMOVENDPEND.NUMLOTE,
                                     CASE
                                       WHEN PCBLOQUEIOEST.CODOPER = ''EV'' AND
                                            NVL(PCBLOQUEIOEST.CODENDERECOORIG, 0) > 0 THEN
                                        ''SV''
                                       WHEN PCBLOQUEIOEST.CODOPER = ''ER'' AND
                                            NVL(PCBLOQUEIOEST.CODENDERECOORIG, 0) > 0 THEN
                                        ''SR''
                                       ELSE
                                        PCBLOQUEIOEST.CODOPER
                                     END CODOPER,
                                     PCMOVENDPEND.QT
                                FROM PCBLOQUEIOEST, PCPRODUT, PCMOVENDPEND, PCENDERECO
                               WHERE PCBLOQUEIOEST.CODPROD = PCPRODUT.CODPROD
                                 AND PCMOVENDPEND.CODPROD = PCPRODUT.CODPROD
                                 AND PCMOVENDPEND.CODENDERECO = PCENDERECO.CODENDERECO
                                 AND PCBLOQUEIOEST.NUMTRANSWMS = PCMOVENDPEND.NUMTRANSWMS
                                 AND PCBLOQUEIOEST.CODENDERECOORIG = PCENDERECO.CODENDERECO
                                 AND PCBLOQUEIOEST.NUMTRANSWMS IS NOT NULL
                                 AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''S''
                                 AND PCMOVENDPEND.POSICAO IN (''C'')
                                 AND PCBLOQUEIOEST.CODOPER NOT IN (''SR'', ''ER'')
                                 AND TRUNC(PCBLOQUEIOEST.DTLANC) BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
             IF psCODFILIAL IS NOT NULL THEN
               vsSQL := vsSQL||'                                 AND NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
             END IF;
             IF pnCODPROD IS NOT NULL THEN
               vsSQL := vsSQL||'                                 AND PCPRODUT.CODPROD = '||pnCODPROD||CHR(13);
             END IF;
             IF psNUMLOTE IS NOT NULL THEN
               vsSQL := vsSQL||'                                 AND PCMOVENDPEND.NUMLOTE = '||CHR(39)||psNUMLOTE||CHR(39)||CHR(13);
             END IF;
          vsSQL := vsSQL||'                            ORDER BY TRUNC(PCBLOQUEIOEST.DTLANC)
                                    ,NVL(PCBLOQUEIOEST.CODFILIAL,PCENDERECO.CODFILIAL)
                                    ,CODPROD
                                    ,NUMLOTE
                                    ,CODOPER) TAB)
                       GROUP BY DATA
                               ,CODFILIAL
                               ,CODPROD
                               ,NUMLOTE
                               ,CODOPER';
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsSQL, 1);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vcCURSOR_ENDERECO FOR vsSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vcCURSOR_ENDERECO INTO vrDADOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vcCURSOR_ENDERECO%NOTFOUND LOOP
      -- Preparando o insert na tabela de saldo de movimentações contábies
      vsINSERT := 'INSERT
                     INTO PCSALDOMOVENDERECOLOTE
                         (ID
                         ,DTMOV
                         ,CODFILIAL
                         ,CODPROD
                         ,NUMLOTE
                         ,SALDO)
                 VALUES ('||CHR(39)||vrDADOS.ID||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.DTMOV||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.CODFILIAL||CHR(39)||'
                        ,'||vrDADOS.CODPROD||'
                        ,'||CHR(39)||vrDADOS.NUMLOTE||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.SALDO||CHR(39)||')';
      -- Executando o Insert
      EXECUTE IMMEDIATE vsINSERT;
      -- Indo para a proxima linha do cursor
      FETCH vcCURSOR_ENDERECO INTO vrDADOS;
    -- Fim da lista de movimentações
    END LOOP;
    -- Fechando o curso
    CLOSE vcCURSOR_ENDERECO;
    -- Confirmando os dados desta transação
    COMMIT;
  -- Fim da procedure
  END PRC_MOV_END_LOTE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  21/05/2015     Fernandes Brito                       Criada a função para unificar a busca dos dados GERENCIAIS na PCMOV
  29/09/2015     Fernandes Brito                       Alterada a Função para Procedure para criar uma tabela fisica no lugar do PIPELINED
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure para sempre deletar os dados da tabela PCSALDOMOVGERENCIAIS e
                                                       incluida a função PRAGMA AUTONOMOUS_TRANSACTION para acegurar que o update executado
                                                       será apenas na tabela PCSALDOMOVGERENCIAIS
  08/09/2016     Fernandes Brito                       Incluida a função CLOSE para fechar a variável vcCURSOR_GER e assim
                                                       evitar problemas com lixo no cursor
  14/02/2017     Fernandes Brito                       Alterada para retirar a criação da tabela e colocar na procedure PRC_LIMPAR_SALDOS
  03/07/2017     Fábio Figueiredo                      Retirada a Clausula que excluia os inventários com numero de lote.
  16/11/2020     Fernandes Brito                       Ajustada a procedure para gravar os dados contábeis já levando em conta a lista de dias.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MOV_GER (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                        ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                        ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                        ,pdDTFINAL   IN PCMOV.DTMOV%TYPE)
  IS-- Variaveis de uso interno
    vcCURSOR_GER           SYS_REFCURSOR;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
  -- Montar selects para os dados Gerenciais
    vsSQL :='
                  SELECT PCLISTADIAS.ID
                        ,PCLISTADIAS.DATA DTMOV
                        ,NVL(MOV.CODFILIAL,'||CHR(39)||psCODFILIAL||CHR(39)||') CODFILIAL
                        ,NVL(MOV.CODPROD,'||pnCODPROD||') CODPROD
                        ,NULL NUMLOTE
                        ,NVL(MOV.SALDO,0) SALDO
                    FROM PCLISTADIAS
                        ,(/* Notas Fiscais Normais */
                         SELECT PCMOV.DTMOV
                               ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                               ,PCMOV.CODPROD
                               ,NVL(SUM(CASE
                                           WHEN (SUBSTR(PCMOV.CODOPER, 1, 1) = ''E'') OR
                                                (SUBSTR(PCMOV.CODOPER, 1, 1) = ''D'') THEN
                                            CASE
                                           WHEN DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                                       0,
                                                       NVL(PCMOV.QT, 0),
                                                       PCMOVCOMPLE.QTRETORNOTV13) > 0 THEN
                                            DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                                   0,
                                                   NVL(PCMOV.QT, 0),
                                                   PCMOVCOMPLE.QTRETORNOTV13)
                                         END ELSE CASE
                                           WHEN DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                                       0,
                                                       NVL(PCMOV.QT, 0),
                                                       PCMOVCOMPLE.QTRETORNOTV13) < 0 THEN
                                            DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                                   0,
                                                   (NVL(PCMOV.QT, 0) * (-1)),
                                                   (PCMOVCOMPLE.QTRETORNOTV13 * (-1)))
                                         END END),
                                     0) + NVL(SUM(CASE
                                                    WHEN (SUBSTR(PCMOV.CODOPER, 1, 1) = ''S'') OR
                                                         (SUBSTR(PCMOV.CODOPER, 1, 1) = ''R'') THEN
                                                     CASE
                                                    WHEN (PCMOV.QT > 0) THEN
                                                     NVL(PCMOV.QT * (-1), 0)
                                                  END ELSE CASE
                                                    WHEN (PCMOV.QT < 0) THEN
                                                     NVL(PCMOV.QT, 0)
                                                  END END),
                                              0) SALDO
                           FROM PCMOV
                               ,PCMOVCOMPLE
  
                          WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                            AND PCMOV.DTMOV BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
IF psCODFILIAL IS NOT NULL THEN
  vsSQL := vsSQL||'                           AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
END IF;
IF pnCODPROD IS NOT NULL THEN
  vsSQL := vsSQL||'                           AND CODPROD = '||pnCODPROD||CHR(13);
END IF;
  vsSQL := vsSQL||'                           AND ABS(NVL(PCMOV.QT,0)) > 0
                            AND PCMOV.STATUS IN (''B'', ''AB'')
                            AND (NOT EXISTS (SELECT NUMPED
                                               FROM PCPEDC
                                              WHERE NUMPED = DECODE(PCMOV.CODOPER, ''EP'', -1, ''SP'',-1, PCMOV.NUMPED)'||CHR(13);                        
IF psCODFILIAL IS NOT NULL THEN
  vsSQL := vsSQL||'                             AND PCPEDC.CODFILIAL = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
END IF;                        
  vsSQL := vsSQL||'                             AND CONDVENDA = 7) OR (SUBSTR(PCMOV.CODOPER,1,1) = ''E''))
                            AND NOT (PCMOV.CODOPER IN (''EA'',''SA'') AND PCMOVCOMPLE.NUMINVENT IS NOT NULL)
                            AND NVL(PCMOVCOMPLE.MOVEST,''S'') = ''S''
                            AND NOT (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA(''DEVOLVESIMPLESREMTV13TOTAL'',PCMOV.CODFILIAL,''N'') = ''S'' AND PCMOV.ROTINACAD LIKE ''%1332%'' AND NVL(PCMOVCOMPLE.QTRETORNOTV13,0) = 0)
                            AND NOT EXISTS (SELECT NUMNOTA FROM PCNFSAID WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA '||CHR(13);
IF psCODFILIAL IS NOT NULL THEN
  vsSQL := vsSQL||'         AND NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
END IF;                        
  vsSQL := vsSQL||'     AND SITUACAONFE IN (110,205,301,302,303))
                            AND NOT EXISTS (SELECT DISTINCT (PCNFSAID.NUMTRANSVENDA)
                                              FROM PCNFSAID
                                                  ,PCPRODUT
                                             WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                               AND PCNFSAID.CODFILIAL = PCMOV.CODFILIAL'||CHR(13);
IF psCODFILIAL IS NOT NULL THEN
  vsSQL := vsSQL||'                            AND NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
END IF;                        
  vsSQL := vsSQL||'                            AND PCMOV.CODOPER = ''S''
                                               AND PCNFSAID.CONDVENDA IN (4, 7, 14)
                                               AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                               AND PCPRODUT.TIPOMERC = ''CB'')
                       GROUP BY PCMOV.DTMOV,
                                NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                                PCMOV.CODPROD) MOV
                  WHERE PCLISTADIAS.DATA = MOV.DTMOV (+)
                    AND PCLISTADIAS.ID = ''GERENCIAL''';
    /*INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsSQL, 1);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vcCURSOR_GER FOR vsSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vcCURSOR_GER INTO vrDADOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vcCURSOR_GER%NOTFOUND LOOP
      -- Preparando o insert na tabela de saldo de movimentações gerenciais
      vsINSERT := 'INSERT
                     INTO PCSALDOMOVGERENCIAIS
                         (ID
                         ,DTMOV
                         ,CODFILIAL
                         ,CODPROD
                         ,SALDO)
                 VALUES ('||CHR(39)||vrDADOS.ID||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.DTMOV||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.CODFILIAL||CHR(39)||'
                        ,'||vrDADOS.CODPROD||'
                        ,'||CHR(39)||vrDADOS.SALDO||CHR(39)||')';
      -- Executando o Insert
      EXECUTE IMMEDIATE vsINSERT;
      -- Indo para a proxima linha do cursor
      FETCH vcCURSOR_GER INTO vrDADOS;
    END LOOP;
    -- Fechando cursor
    CLOSE vcCURSOR_GER;
    -- Confirmando os dados desta transação.
    COMMIT;
  -- Fim da procedure
  END PRC_MOV_GER;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  30/06/2017     Fernandes Brito                       Criada a função para busca dados do LOTE na PCMOV
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_MOV_LOTE (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE
                         ,pnCODPROD   IN PCMOV.CODPROD%TYPE
                         ,psNUMLOTE   IN PCMOV.NUMLOTE%TYPE
                         ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                         ,pdDTFINAL   IN PCMOV.DTMOV%TYPE)
  IS
    -- Variaveis de uso interno
    vcCURSOR_LOTE           SYS_REFCURSOR;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     -- Montar selects para os dados do lote
     vsSQL := 'SELECT ''LOTE'' ID
                      ,MOV.DTMOV
                      ,MOV.CODFILIAL
                      ,MOV.CODPROD
                      ,MOV.NUMLOTE
                      ,NVL(MOV.SALDO,0) SALDO
                 FROM (SELECT PCMOV.DTMOV
                             ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                             ,PCMOV.CODPROD
                             ,PCMOV.NUMLOTE
                             ,NVL(SUM (CASE WHEN (SUBSTR(PCMOV.CODOPER, 1, 1) = ''E'') OR (SUBSTR(PCMOV.CODOPER, 1, 1) = ''D'') THEN CASE WHEN (PCMOV.QT > 0) THEN NVL(PCMOV.QT, 0) END ELSE CASE WHEN (PCMOV.QT < 0) THEN NVL((PCMOV.QT * (-1)), 0) END END),0) +
                              NVL(SUM (CASE WHEN (SUBSTR(PCMOV.CODOPER, 1, 1) = ''S'') OR (SUBSTR(PCMOV.CODOPER, 1, 1) = ''R'') THEN CASE WHEN (PCMOV.QT > 0) THEN NVL(PCMOV.QT * (-1), 0) END ELSE CASE WHEN (PCMOV.QT < 0) THEN NVL(PCMOV.QT, 0) END END),0) SALDO
                         FROM PCMOV
                             ,PCPRODUT
                             ,PCMOVCOMPLE
                        WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                          AND PCMOV.CODPROD = PCPRODUT.CODPROD
                          AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''S''
                          AND PCMOV.DTMOV BETWEEN '||CHR(39)||TO_CHAR(pdDTINICIAL,'DD-MON-RRRR')||CHR(39)||' AND '||CHR(39)||TO_CHAR(pdDTFINAL,'DD-MON-RRRR')||CHR(39)||CHR(13);
      IF psCODFILIAL IS NOT NULL THEN
        vsSQL := vsSQL||' AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = '||CHR(39)||psCODFILIAL||CHR(39)||CHR(13);
      END IF;
      IF pnCODPROD IS NOT NULL THEN
        vsSQL := vsSQL||' AND PCMOV.CODPROD = '||pnCODPROD||CHR(13);
      END IF;
      IF psNUMLOTE IS NOT NULL THEN
        vsSQL := vsSQL||' AND PCMOV.NUMLOTE = '||CHR(39)||psNUMLOTE||CHR(39)||CHR(13);
      END IF;
        vsSQL := vsSQL||' AND ABS(NVL(PCMOV.QT,0)) > 0
                          AND NVL(PCMOVCOMPLE.MOVEST, ''S'') = ''S''
                          AND PCMOV.STATUS IN (''B'', ''AB'')
                          AND NOT (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA(''DEVOLVESIMPLESREMTV13TOTAL'',PCMOV.CODFILIAL,''N'') = ''S'' AND PCMOV.ROTINACAD LIKE ''%1332%'' AND NVL(PCMOVCOMPLE.QTRETORNOTV13,0) = 0)
                          AND NOT EXISTS (SELECT NUMNOTA FROM PCNFSAID
                                           WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                             AND SITUACAONFE IN (110,205,301,302,303))
                          AND (NOT EXISTS (SELECT NUMPED
                                             FROM PCPEDC
                                            WHERE NUMPED = DECODE(PCMOV.CODOPER, ''EP'', -1, ''SP'',-1, PCMOV.NUMPED)
                                              AND CONDVENDA = 7) OR (SUBSTR(PCMOV.CODOPER,1,1) = ''E''))
                          AND NOT EXISTS (SELECT DISTINCT (PCNFSAID.NUMTRANSVENDA)
                                            FROM PCNFSAID
                                                ,PCPRODUT
                                           WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                             AND PCNFSAID.CODFILIAL = PCMOV.CODFILIAL
                                             AND NVL(PCPRODUT.ESTOQUEPORLOTE,''N'') = ''S''
                                             AND PCMOV.CODOPER = ''S''
                                             AND PCNFSAID.CONDVENDA IN (4, 7, 14)
                                             AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                             AND PCPRODUT.TIPOMERC = ''CB'')
                     GROUP BY PCMOV.DTMOV
                             ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL)
                             ,PCMOV.CODPROD
                             ,PCMOV.NUMLOTE) MOV';
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vsSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vcCURSOR_LOTE FOR vsSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vcCURSOR_LOTE INTO vrDADOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vcCURSOR_LOTE%NOTFOUND LOOP
      -- Preparando o insert na tabela de saldo de movimentações do lote
      vsINSERT := 'INSERT
                     INTO PCSALDOMOVLOTE
                         (ID
                         ,DTMOV
                         ,CODFILIAL
                         ,CODPROD
                         ,NUMLOTE
                         ,SALDO)
                 VALUES ('||CHR(39)||vrDADOS.ID||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.DTMOV||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.CODFILIAL||CHR(39)||'
                        ,'||vrDADOS.CODPROD||'
                        ,'||CHR(39)||vrDADOS.NUMLOTE||CHR(39)||'
                        ,'||CHR(39)||vrDADOS.SALDO||CHR(39)||')';
      -- Executando o Insert
      EXECUTE IMMEDIATE vsINSERT;
      -- Indo para a proxima linha do cursor
      FETCH vcCURSOR_LOTE INTO vrDADOS;
    END LOOP;
    -- Fechando cursor
    CLOSE vcCURSOR_LOTE;
    -- Confirmando os dados desta transação.
    COMMIT;
  -- Fim da procedure
  END PRC_MOV_LOTE;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados pre requisição de consumo
  /***********************************************************************************************************************/
  PROCEDURE PRC_ORDEM_PRODUCAO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
  
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Atualiza QTRESERV dos produtos que tenham ordem de produção
    vSQL := 'SELECT SUM(ROUND((CASE
                               WHEN QTRESERVADA_LOTE <> 0 THEN
                                 QTRESERVADA_LOTE
                              ELSE
                                QTRESERVADA_ESTOQUE
                              END),6)) QTDE
                   ,CODFILIAL
                   ,CODPROD '||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL || ',CODDEPOSITO '||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS CODDEPOSITO '||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',NUMLOTE '||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS NUMLOTE '||CHR(13);
    END IF;
    -- Complemento SQL
      vSQL := vSQL || ' FROM (SELECT C.CODFILIAL
                                    ,C.NUMOP
                                    ,I.CODPROD
                                    ,L.NUMLOTE
                                    ,(NVL(I.QTNECESSIDADE,0) - NVL(I.QTREQUISITADO,0)) QTRESERVADA_ESTOQUE
                                    ,(NVL(L.QT,0) - NVL(L.QTREQUISITADO,0)) QTRESERVADA_LOTE
                                    ,NVL(FINALIZAPRODUCAO,''N'') FINALIZAPRODUCAO
                                    ,NVL(I.CODDEPOSITO,0) AS CODDEPOSITO
                                FROM PCOPI I
                                  ,PCOPILOTE L
                                  ,PCOPC C
                             WHERE I.NUMOP > 0
                               AND I.NUMOP = C.NUMOP
                               AND I.NUMOP = L.NUMOP(+)
                               AND I.CODPROD = L.CODPROD(+)
                               AND C.POSICAO = ''P''
                               AND NVL(FINALIZAPRODUCAO,''N'') = ''N''
                               AND C.CODFILIAL = ' ||CHR(39)||pENTRADA.CODFILIAL||CHR(39)|| '
                               AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(C.CODFILIAL, I.CODPROD) = ''N'' '||CHR(13);
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL ||' AND I.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS <> '0' THEN
      VSQL := VSQL ||' AND I.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    ELSE
      vSQL := vSQL ||' AND I.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = I.CODPROD AND F.OBS2 = ''FL'') '||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS <> '0' THEN
      vSQL := vSQL ||' AND I.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES <> '0' THEN
      vSQL := vSQL ||' AND I.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES <> '0' THEN
      vSQL := vSQL ||' AND I.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS <> '0' THEN
      vSQL := vSQL ||' AND I.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS <> '0' THEN
      vSQL := vSQL ||' AND I.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS <> '0' THEN
      vSQL := vSQL ||' AND I.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
  
   IF pENTRADA.LISTA_DE_LOTES > '0' THEN
      vSQL := vSQL||' AND L.NUMLOTE IN ('||pENTRADA.LISTA_DE_LOTES||')'||CHR(13);
    END IF;
  
  
    -- Complemento SQL
    vSQL := vSQL || ') GROUP BY CODFILIAL
                              ,CODPROD '||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL ||' ,CODDEPOSITO '||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL ||' ,NUMLOTE '||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL ||' ORDER BY CODFILIAL
                             ,CODPROD '||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL ||' ,CODDEPOSITO'||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL ||' ,NUMLOTE'||CHR(13);
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      vCHAMADA.NUMLOTE     := vTYPE_PEDIDOS.NUMLOTE;
      -- Atualizar reservas
      PRC_ESTOQUE_RESERVADO(vCHAMADA);
      -- Utiliza estoque por depósito?
      IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
        -- Atualizar reservas
        PRC_DEPOSITO_RESERVADO(vCHAMADA);
      -- Estoque por depósito
      END IF;
      -- Utiliza estoque por lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        -- Reserva lote
        PRC_LOTE_RESERVADO(vCHAMADA);
      -- Estoque por lote
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
  -- Ordem_producao
  END PRC_ORDEM_PRODUCAO;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados ordem de produção avulso
  /***********************************************************************************************************************/
  PROCEDURE PRC_ORDEM_PRODUCAO_AVULSA (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Buscar dados das Requisições Avulsas
    vSQL := 'SELECT NVL(SUM(A.QT),0) QTDE
                   ,A.CODFILIAL
                   ,A.CODPROD '||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL || ',NVL(A.CODDEPOSITO,0) AS CODDEPOSITO'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS CODDEPOSITO '||CHR(13);
    END IF;
  vSQL := vSQL || ',A.NUMLOTE AS NUMLOTE '||CHR(13);
    -- Complemento SQL
    vSQL := vSQL || ' FROM PCAVULSA A
                     WHERE A.DTBAIXA IS NULL
                       AND A.DTCANCEL IS NULL
                       AND A.CODFILIAL = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||'
                       AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(A.CODFILIAL, A.CODPROD) = ''N'' ';--HIS.00015.2014
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL ||' AND A.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      VSQL := VSQL ||' AND A.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')';
    ELSE
      vSQL := vSQL ||' AND A.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = A.CODPROD AND F.OBS2 = ''FL'') '||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||'AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )';
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||'AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )';
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||'AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )';
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )';
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )';
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||'AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )';
    END IF;
    -- Complemento SQL
    vSQL := vSQL || ' AND A.CODOPER in (''S'',''P'')
                 GROUP BY A.CODFILIAL
                         ,A.CODPROD '||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL || ',NVL(A.CODDEPOSITO,0)'||CHR(13);
    END IF;
  vSQL := vSQL || ',A.NUMLOTE'||CHR(13);
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      -- Atualizar reservas
      PRC_ESTOQUE_RESERVADO(vCHAMADA);
      -- Utiliza estoque por depósito?
      IF vUtilizaEstoquePorDeposito = 'S' THEN
        -- Atualizar reservas
        PRC_DEPOSITO_RESERVADO(vCHAMADA);
      -- Estoque por depósito
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
  -- Ordem producao avulsa
  END PRC_ORDEM_PRODUCAO_AVULSA;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados ordem de produção
  /***********************************************************************************************************************/
  PROCEDURE PRC_ORDEM_SERVICO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Buscar dados ordem de serviço (manutenção)
    vSQL := 'SELECT NVL(SUM(A.QTDE),0) AS QTDE
                   ,A.CODFILIALRETIRA AS CODFILIAL
                   ,A.CODPROD '||CHR(13);
    -- Utiliza estoque por depósito?
    IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
      vSQL := vSQL || ',NVL(A.CODDEPOSITO,0) AS CODDEPOSITO'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS CODDEPOSITO '||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',A.NUMLOTE'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS NUMLOTE '||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL || ' FROM PCITEMSERVICO A
                          ,PCORDEMSERVICO O
                          ,PCORDEMSERVICOI I
                          ,PCTIPOORDEMSERVICO T
                          ,PCCONSUM
                     WHERE O.NUMOS = I.NUMOS
                       AND O.NUMTRANSVENDAPROD IS NULL
                       AND (A.CODFILIALRETIRA IS NULL OR
                            A.CODFILIALRETIRA = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||')
                       AND I.NUMOSSERVICO = A.NUMOSSERVICO
                       AND O.TIPOOS = T.CODTIPO(+)
                       AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE(NVL(A.CODFILIALRETIRA, '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||'), A.CODPROD) = ''N'' ';
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL||' AND A.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de lote
    IF pENTRADA.LISTA_DE_LOTES > '0' THEN
      vSQL := vSQL||' AND A.NUMLOTE IN ('||pENTRADA.LISTA_DE_LOTES||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')';
    ELSE
      vSQL := vSQL ||' AND A.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = A.CODPROD AND F.OBS2 = ''FL'') '||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )';
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )';
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )';
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )';
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )';
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||' AND A.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )';
    END IF;
    -- Complemento SQL
    vSQL := vSQL || ' AND NVL (A.DEMONSTRACAO, ''N'') = ''N''
                      AND ((NVL(T.OSCOMODATO, ''N'') = ''N''
                        AND NVL(PCCONSUM.OSRESERVANAEXECUCAO, ''N'') = ''S''
                        AND NVL(T.GERARCONTRECEBERPRODUTO, ''N'') = ''S''
                        AND O.SITUACAO IN (2, 4))
                          OR (NVL (T.OSCOMODATO, ''N'') = ''N''
                              AND NVL (PCCONSUM.OSRESERVANAEXECUCAO, ''N'') = ''N''
                              AND NVL (T.GERARCONTRECEBERPRODUTO, ''N'') = ''S''
                              AND O.SITUACAO IN (1, 2, 4))
                          OR (NVL (T.OSCOMODATO, ''N'') = ''S''
                              AND NVL (PCCONSUM.OSRESERVANAEXECUCAO, ''N'') = ''N''
                              AND O.SITUACAO IN (1, 2))
                          OR (NVL (T.OSCOMODATO, ''N'') = ''S''
                              AND NVL (PCCONSUM.OSRESERVANAEXECUCAO, ''N'') = ''S''
                              AND O.SITUACAO IN (2))
                          OR (NVL (PCCONSUM.OSRESERVANAEXECUCAO, ''N'') = ''S''
                              AND NVL (A.DEMONSTRACAO, ''N'') = ''N''
                              AND O.SITUACAO IN (2)
                              AND NVL (T.GERARCONTRECEBERPRODUTO, ''N'') = ''N'')
                          OR (NVL (PCCONSUM.OSRESERVANAEXECUCAO, ''N'') = ''N''
                              AND NVL (A.DEMONSTRACAO, ''N'') = ''N''
                              AND O.SITUACAO IN (1, 2)
                              AND NVL (T.GERARCONTRECEBERPRODUTO, ''N'') = ''N''))
                 GROUP BY A.CODFILIALRETIRA
                 ,A.CODPROD'||CHR(13);
    -- Utiliza estoque por depósito?
    IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
      vSQL := vSQL || ',NVL(A.CODDEPOSITO,0)'||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',A.NUMLOTE'||CHR(13);
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      -- Atualizar reservas ou pendencias?
      IF vRECALCULAR_RESERVADO = 'S' THEN
        -- Reserva estoque
        PRC_ESTOQUE_RESERVADO(vCHAMADA);
        -- Utiliza estoque por depósito?
        IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
          -- Reserva deposito
          PRC_DEPOSITO_RESERVADO(vCHAMADA);
        -- Estoque por depósito
        END IF;
      ELSE
        -- Pendente estoque
        PRC_ESTOQUE_PENDENTE(vCHAMADA);
        -- Utiliza estoque por depósito?
        IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
          -- Pendente deposito
          PRC_DEPOSITO_PENDENTE(vCHAMADA);
        -- Estoque por depósito
        END IF;
      -- Reservas ou pendencias
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
  -- Ordem servico
  END PRC_ORDEM_SERVICO;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados dos pedidos reservados
  /***********************************************************************************************************************/
  PROCEDURE PRC_PEDIDOS_DE_VENDA (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Definir qual filial retira utilizar nos selects de pedido de venda
    IF vUTILIZACENTRALFATURAMENTO = 'N' THEN
      vSQLFILIALRETIRA := 'NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)';
    ELSE
      vSQLFILIALRETIRA := 'PKG_ESTOQUE.VALIDA_CODFILIAL_CEFAT(PCPEDI.NUMPED, PCPEDI.CODPROD, PCPEDI.NUMSEQ)';
    END IF;
    -- Buscar dados dos pedidos de venda
    vSQL := 'SELECT SUM(PCPEDI.QT) QTDE'||CHR(13);
    -- Busar reservas ou pendencias?
    IF vRECALCULAR_RESERVADO = 'S' THEN
      vSQL := vSQL ||','||vSQLFILIALRETIRA||' CODFILIAL'||CHR(13);
    ELSE
      vSQL :=   vSQL  ||',NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL) CODFILIAL'||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL :=   vSQL  ||',PCPEDI.CODPROD'||CHR(13);
    -- Utiliza estoque por depósito?
    IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
      vSQL := vSQL || ',NVL(PCPEDI.CODDEPOSITO,0) AS CODDEPOSITO'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS CODDEPOSITO '||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',PCPEDI.NUMLOTE'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS NUMLOTE '||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL||'FROM PCPEDI, PCPEDC
                  WHERE PCPEDI.NUMPED = PCPEDC.NUMPED
    
                    AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
                    AND NVL(PCPEDI.QT, 0) > 0 '||CHR(13);
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de lotes
    IF pENTRADA.LISTA_DE_LOTES > '0' THEN
      vSQL := vSQL||' AND PCPEDI.NUMLOTE IN ('||pENTRADA.LISTA_DE_LOTES||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    ELSE
      vSQL := vSQL||' AND PCPEDI.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = PCPEDI.CODPROD AND F.OBS2 = ''FL'')'||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL||' AND PCPEDI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
    -- Lista dados do pré faturamento
    IF vUTILIZACENTRALFATURAMENTO = 'S' THEN
      vSQL := vSQL||' AND NVL(PCPEDI.POSICAOCFAT, ''AFA'') IN (''AFA'', ''EVE'', ''ERE'', ''EVI'')'||CHR(13);
    END IF;
    -- Busar reservas ou pendencias?
    IF vRECALCULAR_RESERVADO = 'S' THEN
      vSQL := vSQL||' AND PCPEDC.NUMOS IS NULL'||CHR(13)||'
            AND DECODE(NVL(PCPEDC.VENDAASSISTIDA,''N''),''S'',NVL(PCPEDI.POSICAO, PCPEDC.POSICAO),PCPEDC.POSICAO) IN (''L'', ''M'')'||CHR(13)||'
            AND PCPEDC.DATA >= '||CHR(39)||TO_CHAR(vDATAPEDRESERVADA)||CHR(39)||CHR(13)||'
      AND PCPEDI.DATA >= '||CHR(39)||TO_CHAR(vDATAPEDRESERVADA)||CHR(39)||CHR(13)||'
            AND '||vSQLFILIALRETIRA||' = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||CHR(13)||'
       GROUP BY '||vSQLFILIALRETIRA||'
               ,CODPROD'||CHR(13);
      -- Utiliza estoque por depósito?
      IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
        vSQL := vSQL || ',NVL(PCPEDI.CODDEPOSITO,0)'||CHR(13);
      END IF;
      -- Utiliza estoque por Lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        vSQL := vSQL || ',PCPEDI.NUMLOTE'||CHR(13);
      END IF;
    ELSE
      vSQL := vSQL||' AND PCPEDC.NUMOS IS NULL'||CHR(13)||'
                  AND DECODE(NVL(PCPEDC.VENDAASSISTIDA,''N''),''S'',NVL(PCPEDI.POSICAO, PCPEDC.POSICAO),PCPEDC.POSICAO) IN (''P'', ''B'')'||CHR(13)||'
                  AND PCPEDC.DATA >= '||CHR(39)||TO_CHAR(vDATAPEDPENDENTE)||CHR(39)||CHR(13)||'
          AND PCPEDI.DATA >= '||CHR(39)||TO_CHAR(vDATAPEDPENDENTE)||CHR(39)||CHR(13)||'
                  AND NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL) = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||CHR(13)||'
             GROUP BY NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)
                     ,CODPROD'||CHR(13);
      -- Utiliza estoque por depósito?
      IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
        vSQL := vSQL || ',NVL(PCPEDI.CODDEPOSITO,0)'||CHR(13);
      END IF;
    -- Reservas ou pendencias
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      vCHAMADA.NUMLOTE     := vTYPE_PEDIDOS.NUMLOTE;
      -- Atualizar reservas ou pendencias?
      IF vRECALCULAR_RESERVADO = 'S' THEN
        -- Reserva estoque
        PRC_ESTOQUE_RESERVADO(vCHAMADA);
        -- Utiliza estoque por depósito?
        IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
          -- Reserva deposito
          PRC_DEPOSITO_RESERVADO(vCHAMADA);
        -- Estoque por depósito
        END IF;
        -- Utiliza estoque por lote?
        IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
          -- Reserva lote
          PRC_LOTE_RESERVADO(vCHAMADA);
        -- Estoque por lote
        END IF;
      ELSE
        -- Pendente estoque
        PRC_ESTOQUE_PENDENTE(vCHAMADA);
        -- Utiliza estoque por depósito?
        IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
          -- Pendente deposito
          PRC_DEPOSITO_PENDENTE(vCHAMADA);
        -- Estoque por depósito
        END IF;
      -- Reservas ou pendencias
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
  -- Pedidos de venda
  END PRC_PEDIDOS_DE_VENDA;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados do pré faturamento dos pedidos
  /***********************************************************************************************************************/
  PROCEDURE PRC_PREFAT (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Definir qual filial retira utilizar nos selects de pre faturamento
    IF vUTILIZACENTRALFATURAMENTO = 'N' THEN
      vSQLFILIALRETIRA := 'NVL(MOVPRE.CODFILIALRETIRA, NFPRE.CODFILIAL)';
    ELSE
      vSQLFILIALRETIRA := 'NVL(NFPRE.CODFILIALNF, NFPRE.CODFILIAL)';
    END IF;
    -- Atualiza QTRESERV dos produtos que tenham pré faturamento
    vSQL := 'SELECT SUM(MOVPRE.QT) QTDE
                   ,'||vSQLFILIALRETIRA||' CODFILIAL
                   ,MOVPRE.CODPROD'||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL || ',NVL(MOVPRE.CODDEPOSITO,0) AS CODDEPOSITO'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS CODDEPOSITO '||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',MOVPRE.NUMLOTE'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS NUMLOTE '||CHR(13);
    END IF;
    vSQL := vSQL||'FROM PCNFSAIDPREFAT NFPRE, PCMOVPREFAT MOVPRE, PCPEDC
                  WHERE NFPRE.NUMTRANSVENDA = MOVPRE.NUMTRANSVENDA
                    AND NFPRE.CONDVENDA NOT IN (4, 7, 14)
                    AND NFPRE.NUMOS IS NULL
                    AND NFPRE.DTCANCEL IS NULL
                    AND NFPRE.SITUACAONFE NOT IN (110, 205, 301, 302, 303)
                    AND NFPRE.DTSAIDA >= '||CHR(39)||TO_CHAR(vDATAPEDRESERVADA)||CHR(39)||'
                    AND NVL(MOVPRE.QT, 0) > 0
                    AND MOVPRE.DTCANCEL IS NULL
                    AND PCPEDC.NUMPED = NFPRE.NUMPED
                    AND PCPEDC.POSICAO <> ''C''                     
                    AND NOT EXISTS (SELECT PCNFSAID.NUMTRANSVENDA
                                      FROM PCNFSAID
                                     WHERE PCNFSAID.NUMTRANSVENDA = NFPRE.NUMTRANSVENDA )';
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de lote
    IF pENTRADA.LISTA_DE_LOTES > '0' THEN
      vSQL := vSQL||'AND MOVPRE.NUMLOTE IN ('||pENTRADA.LISTA_DE_LOTES||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN ('||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    ELSE
      vSQL := vSQL||' AND MOVPRE.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = MOVPRE.CODPROD AND F.OBS2 = ''FL'') '||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL||'AND MOVPRE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL||'AND '||vSQLFILIALRETIRA||' = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||CHR(13)||'
                  AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE('||vSQLFILIALRETIRA||', MOVPRE.CODPROD) = ''N''
             GROUP BY '||vSQLFILIALRETIRA||'
                      ,CODPROD'||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL || ',NVL(MOVPRE.CODDEPOSITO,0)'||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',MOVPRE.NUMLOTE'||CHR(13);
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      vCHAMADA.NUMLOTE     := vTYPE_PEDIDOS.NUMLOTE;
      -- Atualizar reservas
      PRC_ESTOQUE_RESERVADO(vCHAMADA);
      -- Utiliza estoque por depósito?
      IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
        -- Atualizar reservas
        PRC_DEPOSITO_RESERVADO(vCHAMADA);
      -- Estoque por depósito
      END IF;
      -- Utiliza estoque por lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        -- Reserva lote
        PRC_LOTE_RESERVADO(vCHAMADA);
      -- Estoque por lote
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
  END;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados pre requisição de consumo
  /***********************************************************************************************************************/
  PROCEDURE PRC_PREREQUISICAO_CONSUMO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Atualiza QTRESERV dos produtos que tenham Requisições de consumo
    vSQL := 'SELECT NVL(SUM(RI.QT), 0) QTDE
                   ,RC.CODFILIAL
                   ,RI.CODPROD'||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL ||',NVL(RI.CODDEPOSITO,0) AS CODDEPOSITO'||CHR(13);
    ELSE
      vSQL := vSQL ||',NULL AS CODDEPOSITO'||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',RI.NUMLOTE'||CHR(13);
    ELSE
      vSQL := vSQL || ',NULL AS NUMLOTE '||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL ||'FROM PCPREREQMATCONSUMOI RI
                        ,PCPREREQMATCONSUMOC RC
                   WHERE RI.NUMPREREQUISICAO = RC.NUMPREREQUISICAO
                     AND RI.CODOPER = ''SM''
                     AND RC.CODFILIAL = ' ||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||CHR(13)||'
                     AND RC.SITUACAO = ''L''
                     AND CONTROLANUMEROSERIE.FUNC_CONTROLA_NUMERO_SERIE('||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||', RI.CODPROD) = ''N'''||CHR(13);
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL||' AND RI.CODDEPOSITO IN ('||pENTRADA.LISTA_DE_DEPOSITOS||')'||CHR(13);
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL||'AND RI.CODPROD IN ('||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    ELSE
      vSQL := vSQL||' AND RI.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = RI.CODPROD AND F.OBS2 = ''FL'') '||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||'AND RI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||'AND RI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||'AND RI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND RI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND RI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||'AND RI.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
    -- Complemento SQL
    vSQL := vSQL || '  GROUP BY RC.CODFILIAL
                               ,RI.CODPROD'||CHR(13);
    -- Utiliza estoque por depósito?
    IF vUtilizaEstoquePorDeposito = 'S' THEN
      vSQL := vSQL ||',NVL(RI.CODDEPOSITO,0)'||CHR(13);
    END IF;
    -- Utiliza estoque por Lote?
    IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
      vSQL := vSQL || ',RI.NUMLOTE'||CHR(13);
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      vCHAMADA.NUMLOTE     := vTYPE_PEDIDOS.NUMLOTE;
      -- Atualizar reservas
      PRC_ESTOQUE_RESERVADO(vCHAMADA);
      -- Utiliza estoque por depósito?
      IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
        -- Atualizar reservas
        PRC_DEPOSITO_RESERVADO(vCHAMADA);
      -- Estoque por depósito
      END IF;
      -- Utiliza estoque por lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        -- Reserva lote
        PRC_LOTE_RESERVADO(vCHAMADA);
      -- Estoque por lote
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
  -- Prerequisicao de consumo
  END PRC_PREREQUISICAO_CONSUMO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  19/01/2015     Fernandes Brito                       Recalcular estoque
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure buscar as movimentações sem usar a função F_TODAS_MOVIMENTACOES
                                                       e buscar os saldos anteriores sem usar a função F_DADOS_HISTEST_ANTERIOR
  08/09/2016     Fernandes Brito                       Incluida a função CLOSE para fechar a variável vcCURSOR_REC e assim
                                                       evitar problemas com lixo no cursor
  05/04/2017     Fernandes Brito/Thiago Pinheiro       Criada a opção "CORRETO" para trazer apenas notas fiscal validas ao recalcular.
                                                       Retirada a opção de "MONITORAMENTO", pois agora vamos recalcular conforme o WinThor
                                                       faz atualmente

  Observações:
  Caso o parâmetro "psTIPOCHAMADA" seja igual à:
  CONTABIL..........: Faz o recalculo apenas contábil, sem validar se existe inventário no ano.
  GERENCIAL.........: Faz o recalculo apenas gerencial, sem validar se existe inventário no ano.
  Obs.: Caso escolha uma destas opções o não escolhido ficará com o histórico errado.

  CORRETO...........: Faz o recalculo gerencial e contábil, buscando um hitórico valido (PCHISTEST) em qualquer dada e não valida a data (se existe inventário no ano), porem só traz notas validas (não traz notas NE, NP, etc...).
  EXTERNA...........: Faz o recalculo gerencial e contábil, buscando um hitórico valido (PCHISTEST) em qualquer dada, caso não tenha usa data do cadastro e não valida a data (se existe inventário no ano).
  INTERNA...........: Faz o recalculo gerencial e contábil, validando se existe inventário, histórico (PCHISTEST) e se o mês esta fechado no fiscal para a data informada (uso da rotina 507).
  NULO (NULL).......: Faz o recalculo gerencial e contábil, buscando o hitórico (PCHISTEST) da data informda, sem validar a data (se existe inventário no ano).
  MONITORAMENTO.....: Lista as informações formatando para monitorar
  ATUALIZACAO_DIARIA: Formata os dados para recalcular o histórico de movimentações do Autosserviço.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_RECALCULO (P_ENTRADA IN OUT TP_ENTRADA)
  IS
    -- Variaveis de uso interno
    vnCONTADOR          NUMBER;
    vnQTESTGERHIST      PCEST.QTESTGER%TYPE;
    vnQTESTHIST         PCEST.QTEST%TYPE;
    vnQTESTGER          PCEST.QTESTGER%TYPE;
    vnQTEST             PCEST.QTEST%TYPE;
    vrDADOS_REC         TR_SOMA_MOV;
    vcCURSOR_REC        SYS_REFCURSOR;
  BEGIN
    -- Validar parâmetros de entrada
    IF (P_ENTRADA.CODPROD IS NOT NULL AND
        P_ENTRADA.CODFILIAL IS NOT NULL AND
        P_ENTRADA.DTINICIAL IS NOT NULL) THEN
      /*Assinando chamada*/
      vsFUNCAO_EXECUTADA := 'PRC_RECALCULO';
      /*Atualiza log do recalculo*/
      vtLOG.CODFILIAL    := P_ENTRADA.CODFILIAL;
      vtLOG.DATA         := SYSDATE;
      vtLOG.DTINICIOREC  := P_ENTRADA.DTINICIAL;
      vtLOG.OBS          := 'PRC_RECALCULO('||NVL(P_ENTRADA.TIPOCHAMADA,'NORMAL')||')';
      -- Atualizando datas
      P_ENTRADA.DTINICIAL        := (P_ENTRADA.DTINICIAL + 1);
      P_ENTRADA.DTFINAL          := TRUNC(SYSDATE);
      P_INTERNOS.GERAR_LOG       := P_ENTRADA.GERAR_LOG;
      P_INTERNOS.USA_FUNCAO_1070 := P_ENTRADA.USA_FUNCAO_1070;
      -- Executar correção da PCHISTEST do produto listado
      PRC_CORRIGIR_PCHISTEST(P_ENTRADA);
      -- Bloqueando estoque do produto para fazer as alterações
      BEGIN
        SELECT QTESTGER
          INTO vnREGISTRO
          FROM PCEST
         WHERE CODPROD = P_ENTRADA.CODPROD
           AND CODFILIAL = P_ENTRADA.CODFILIAL
        FOR UPDATE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnREGISTRO := 0;
      END;
      -- Buscar dados do dia anterior
      BEGIN
        SELECT QTESTGER
              ,QTEST
          INTO vnQTESTGERHIST
              ,vnQTESTHIST
          FROM PCHISTEST
         WHERE CODFILIAL = P_ENTRADA.CODFILIAL
           AND CODPROD = P_ENTRADA.CODPROD
           AND DATA = (TRUNC(SYSDATE) -1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnQTESTGERHIST := 0;
          vnQTESTHIST    := 0;
      END;
      -- Atualizando as variaveis de saldo
      vnQTESTGER := NVL(vnQTESTGERHIST,0);
      vnQTEST    := NVL(vnQTESTHIST,0);
      -- Verifica se o recalculo da PCHISTEST foi executado
      vsSQL := 'SELECT COUNT(*)
                  FROM PCPRODNAORECALCULADO
                 WHERE CODFILIAL = '||CHR(39)||P_ENTRADA.CODFILIAL||CHR(39)||'
                   AND CODPROD = '||P_ENTRADA.CODPROD;
      /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsSQL, 1);
      COMMIT; --*/
      -- Alimenta a variavel com o valor da contagem
      EXECUTE IMMEDIATE vsSQL INTO vnCONTADOR;
      -- Inicio da verificação do PCHISTEST
      IF vnCONTADOR = 0 THEN
        -- Lista de movimentações do periodo
        vsSQL := 'SELECT PCLISTADIAS.ID
                        ,DADOS.CODFILIAL
                        ,DADOS.CODPROD
                        ,SUM(NVL(DADOS.SALDO,0)) SALDO
                   FROM (SELECT PCSALDOMOVGERENCIAIS.ID
                               ,PCSALDOMOVGERENCIAIS.DTMOV
                               ,PCSALDOMOVGERENCIAIS.CODFILIAL
                               ,PCSALDOMOVGERENCIAIS.CODPROD
                               ,PCSALDOMOVGERENCIAIS.SALDO
                           FROM PCSALDOMOVGERENCIAIS
                         UNION ALL
                         SELECT PCSALDOMOVCONTABEIS.ID
                               ,PCSALDOMOVCONTABEIS.DTMOV
                               ,PCSALDOMOVCONTABEIS.CODFILIAL
                               ,PCSALDOMOVCONTABEIS.CODPROD
                               ,PCSALDOMOVCONTABEIS.SALDO
                           FROM PCSALDOMOVCONTABEIS) DADOS
                        ,PCLISTADIAS
                   WHERE PCLISTADIAS.DATA = DADOS.DTMOV(+)
                     AND PCLISTADIAS.ID = DADOS.ID(+)
                     AND PCLISTADIAS.ID IN (''GERENCIAL'',''CONTABIL'')
                     AND PCLISTADIAS.DATA ='||CHR(39)||TO_CHAR(TRUNC(SYSDATE),'DD-MON-RRRR')||CHR(39)||'
                GROUP BY PCLISTADIAS.ID
                        ,DADOS.CODFILIAL
                        ,DADOS.CODPROD';
        -- Abrindo o cursor com base no sql
        OPEN vcCURSOR_REC FOR vsSQL;
        -- Buscando os dados da primeira linha do cursor
        FETCH vcCURSOR_REC INTO vrDADOS_REC;
        -- Enquanto não chegar no final das linhas faça
        WHILE NOT vcCURSOR_REC%NOTFOUND LOOP
          -- Atualizando variável gerencias
          IF vrDADOS_REC.ID = 'GERENCIAL' THEN
             vnQTESTGER := (vnQTESTGER + vrDADOS_REC.SALDO);
          -- Atualizando variável contabeis
          ELSIF vrDADOS_REC.ID = 'CONTABIL' THEN
             vnQTEST := (vnQTEST + vrDADOS_REC.SALDO);
          END IF;
          -- Indo para a proxima linha do cursor
          FETCH vcCURSOR_REC INTO vrDADOS_REC;
        -- Fim da lista de movimentações
        END LOOP;
        -- Fechando cursor
        CLOSE vcCURSOR_REC;
      -- Fim da verificação da PCHISTEST
      END IF;
      -- Caso seja atualização apenas gerencial
      IF NVL(P_ENTRADA.TIPOCHAMADA,'NORMAL') = 'GERENCIAL' THEN
        -- Atualizando dados na PCEST
        UPDATE PCEST
           SET QTESTGER = vnQTESTGER
         WHERE CODPROD = P_ENTRADA.CODPROD
           AND CODFILIAL = P_ENTRADA.CODFILIAL;
      -- Caso seja atualização apenas contabil
      ELSIF NVL(P_ENTRADA.TIPOCHAMADA,'NORMAL') = 'CONTABIL' THEN
        -- Atualizando dados na PCEST
        UPDATE PCEST
           SET QTEST = vnQTEST
         WHERE CODPROD = P_ENTRADA.CODPROD
           AND CODFILIAL = P_ENTRADA.CODFILIAL;
      -- Qualquer outro valor diferente de GERENCIAL e CONTABIL
      ELSE
        -- Atualizando dados na PCEST
        UPDATE PCEST
           SET QTESTGER = vnQTESTGER
              ,QTEST = vnQTEST
         WHERE CODPROD = P_ENTRADA.CODPROD
           AND CODFILIAL = P_ENTRADA.CODFILIAL;
      -- Fim tipo de chamada
      END IF;
      /*Atualiza log do recalculo*/
      IF (vsFUNCAO_EXECUTADA = 'PRC_RECALCULO' AND P_INTERNOS.GERAR_LOG = 'S') THEN
        vtLOG.CODPROD := P_ENTRADA.CODPROD;
        PRC_INS_LOG (vtLOG);
      END IF;
      -- Salvando alterações
      COMMIT WORK;
    -- Mensagem de erro
    ELSE
      -- Mensagem de erro
      DBMS_OUTPUT.PUT_LINE('Não foi informada a filial e a data inicial.'||CHR(13)||
                           'Não se pode fazer um recalculo sem que se informe estes dados!');
      RAISE_APPLICATION_ERROR(-20001,'Não foi informada a filial e a data inicial.'||CHR(13)||
                              'Não se pode fazer um recalculo sem que se informe estes dados!');
    -- Fim da validação parametros de entrada
    END IF;
  -- Fim da procedure
  END PRC_RECALCULO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  30/06/2017     Fernandes Brito                       Criada procedure para Recalcular o PCLOTE
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_REC_LOTE (P_ENTRADA IN OUT TP_ENTRADA)
  IS-- Variaveis de uso interno
    vnSALDOLOTE         PCLOTE.QT%TYPE;
    vnQTLOTE            PCLOTE.QT%TYPE;
    vnCONTADOR          NUMBER;
    vrDADOS_REC         TR_SOMA_MOV_LOTE;
    vcCURSOR_REC        SYS_REFCURSOR;
  BEGIN
    -- Bloqueando estoque para fazer as alterações
    BEGIN
      SELECT QT
        INTO vnREGISTRO
        FROM PCLOTE
       WHERE CODPROD = P_ENTRADA.CODPROD
         AND NUMLOTE = P_ENTRADA.NUMLOTE
         AND CODFILIAL = P_ENTRADA.CODFILIAL
      FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnREGISTRO := 0;
    END;
    -- Executar correção da PCHISTEST do produto listado
    PRC_CORRIGIR_HIST_LOTE (P_ENTRADA);
    -- Buscar dados do dia anterior
    BEGIN
      SELECT QT
        INTO vnQTLOTE
        FROM PCHISTESTLOTE
       WHERE CODFILIAL = P_ENTRADA.CODFILIAL
         AND CODPROD = P_ENTRADA.CODPROD
         AND NUMLOTE = P_ENTRADA.NUMLOTE
         AND DATA = (TRUNC(SYSDATE) -1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnQTLOTE := 0;
    END;
    -- Atualizando as variaveis de saldo
    vnSALDOLOTE := NVL(vnQTLOTE,0);
    -- Verifica se o recalculo da PCHISTEST foi executado
    vsSQL := 'SELECT COUNT(*)
                FROM PCPRODNAORECALCULADO
               WHERE CODFILIAL = '||CHR(39)||P_ENTRADA.CODFILIAL||CHR(39)||'
                 AND CODPROD = '||P_ENTRADA.CODPROD||'
                 AND NUMLOTE = '||CHR(39)||P_ENTRADA.NUMLOTE||CHR(39);
    -- Alimenta a variavel com o valor da contagem
    EXECUTE IMMEDIATE vsSQL INTO vnCONTADOR;
    -- Inicio da verificação do PCHISTEST
    IF vnCONTADOR = 0 THEN
      -- Lista de movimentações do periodo
      vsSQL := 'SELECT PCLISTADIAS.ID
                      ,PCSALDOMOVLOTE.CODFILIAL
                      ,PCSALDOMOVLOTE.CODPROD
                      ,PCSALDOMOVLOTE.NUMLOTE
                      ,SUM(NVL(PCSALDOMOVLOTE.SALDO,0)) SALDO
                 FROM  PCSALDOMOVLOTE
                      ,PCLISTADIAS
                 WHERE PCLISTADIAS.DATA = PCSALDOMOVLOTE.DTMOV(+)
                   AND PCLISTADIAS.ID = PCSALDOMOVLOTE.ID(+)
                   AND PCLISTADIAS.ID IN (''LOTE'')
                   AND PCLISTADIAS.DATA ='||CHR(39)||TRUNC(SYSDATE)||CHR(39)||'
              GROUP BY PCLISTADIAS.ID
                      ,PCSALDOMOVLOTE.CODFILIAL
                      ,PCSALDOMOVLOTE.CODPROD
                      ,PCSALDOMOVLOTE.NUMLOTE';
      -- Abrindo o cursor com base no sql
      OPEN vcCURSOR_REC FOR vsSQL;
      -- Buscando os dados da primeira linha do cursor
      FETCH vcCURSOR_REC INTO vrDADOS_REC;
      -- Enquanto não chegar no final das linhas faça
      WHILE NOT vcCURSOR_REC%NOTFOUND LOOP
        -- Atualizando variável gerencias
        vnSALDOLOTE := (vnSALDOLOTE + vrDADOS_REC.SALDO);
        -- Indo para a proxima linha do cursor
        FETCH vcCURSOR_REC INTO vrDADOS_REC;
      -- Fim da lista de movimentações
      END LOOP;
      -- Fechando cursor
         
      CLOSE vcCURSOR_REC;
      -- Atualizando dados na PCEST
      UPDATE PCLOTE
         SET QT = vnSALDOLOTE
       WHERE CODPROD = P_ENTRADA.CODPROD
         AND NUMLOTE = P_ENTRADA.NUMLOTE
         AND CODFILIAL = P_ENTRADA.CODFILIAL;
    -- Fim da verificação da PCHISTEST
    END IF;
    -- Salvando alterações
    COMMIT WORK;
  -- Fim da procedure
  END PRC_REC_LOTE;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  25/04/2017     Fernandes Brito                       Criada a procedure para recalcular as tabelas PCFINANC e PCFINANC2 que representam
                                                       o PL (patrimonio Liquido) na rotina 117.
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_REC_PAT_LIQ (pnCODROTINA IN NUMBER
                            ,pnCODFUNC   IN NUMBER
                            ,psCODFILIAL IN VARCHAR2
                            ,pdDATA      IN DATE)
  IS
    -- Type para registros
    TYPE REGISTRO IS RECORD(
      DATA      DATE,
      CODIGON   NUMBER(10),
      CODIGOA   VARCHAR2(4),
      VALOR     NUMBER(16, 2),
      CODROTINA NUMBER(4),
      CODFUNC   NUMBER(10));
    -- Variaveis internas
    VSALDOCPMANUAL NUMBER(20,4);
    V_COUNT        NUMBER(5);
    L_CURSOR       SYS_REFCURSOR;
    REG            REGISTRO;
  -- Inicio
  BEGIN
    -- Zera variaveis
    vnCONTADOR := 0;
    -- Verificar se existe PCFINANC2
    vsSQL := 'SELECT COUNT(CODIGON)
                FROM PCFINANC2
               WHERE DATA = :DATA
                 AND CODFILIAL IN('''||psCODFILIAL||''')
                 AND TIPODADO = ''ESTOQUE''';
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vsSQL);
    COMMIT; --*/
    --Executarndo select
    EXECUTE IMMEDIATE vsSQL INTO vnCONTADOR USING pdDATA;
    -- Verifica se já existe PCFINANC2
    IF vnCONTADOR > 0 THEN
      -- Monta select para muscar dados
      vsSQL := 'SELECT SYSDATE DATA
                      ,PCPRODUT.CODEPTO CODIGON
                      ,''0'' CODIGOA
                      ,SUM(NVL(PCHISTEST.QTESTGER, 0) * NVL(PCHISTEST.CUSTOREP,0)) VALOR
                      ,'||pnCODROTINA||' CODROTINA
                      ,'||pnCODFUNC||' CODFUNC
                  FROM PCHISTEST, PCPRODUT, PCDEPTO, PCFORNEC, PCFILIAL
                 WHERE (PCHISTEST.CODPROD = PCPRODUT.CODPROD)
                   AND (PCPRODUT.CODEPTO = PCDEPTO.CODEPTO)
                   AND (PCHISTEST.CODFILIAL = PCFILIAL.CODIGO)
                   AND (PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC)
                   AND (PCDEPTO.TIPOMERC NOT IN (''IM'', ''CI''))
                   AND PCHISTEST.CODFILIAL IN('''||psCODFILIAL||''')
                   AND PCHISTEST.DATA = '''||pdDATA||'''
              GROUP BY PCPRODUT.CODEPTO
                HAVING SUM(NVL(PCHISTEST.QTESTGER, 0) * NVL(PCHISTEST.CUSTOREP, 0)) <> 0';
      -- Abrir cursor com o select acima
      OPEN L_CURSOR FOR vsSQL;
      -- Incio da regra de validação
      BEGIN
        LOOP
          -- Insere os registro da linha no TYPE
          FETCH L_CURSOR INTO REG;
          -- Enquanto não chegar ao fim da lista de dados
          EXIT WHEN L_CURSOR%NOTFOUND;
          -- Montando update na PCFINANC2
          vsSQL := 'UPDATE PCFINANC2 P
                       SET P.DTGERACAO = :DATA
                          ,P.VALOR = '||REG.VALOR||'
                          ,P.CODROTINA = '||REG.CODROTINA||'
                          ,P.CODFUNC = '||REG.CODFUNC||'
                     WHERE P.DATA = :DATA1
                       AND CODFILIAL = '''||psCODFILIAL||'''
                       AND P.CODIGON = '||REG.CODIGON||'
                       AND P.CODIGOA = '''||REG.CODIGOA||'''
                       AND TIPODADO  = ''ESTOQUE'' ';
          -- Execute o update acima
          EXECUTE IMMEDIATE vsSQL USING REG.DATA, pdDATA;
        -- Fim da lista de dados
        END LOOP;
      -- Caso apresente erros
      EXCEPTION
        WHEN INVALID_CURSOR THEN
          RAISE_APPLICATION_ERROR(-20043, 'ALTERAÇÃO PCFINANC2 Estoque.');
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20043, 'ALTERAÇÃO PCFINANC2 Estoque.');
      END;
    -- Caso não exista PCFINANC2
    ELSE
      vsSQL := 'INSERT
                  INTO PCFINANC2 (DTGERACAO,
                                  CODIGON,
                                  CODIGOA,
                                  VALOR,
                                  CODROTINA,
                                  CODFUNC,
                                  CODFILIAL,
                                  DATA,
                                  TIPODADO)
                          (SELECT SYSDATE
                                 ,PCPRODUT.CODEPTO
                                 ,''0''
                                 ,SUM(NVL(PCHISTEST.QTESTGER, 0) * NVL(PCHISTEST.CUSTOREP, 0)) VALOR
                                 ,'||pnCODROTINA||'
                                 ,'||pnCODFUNC||'
                                 ,'''||psCODFILIAL||'''
                                 ,:DATA
                                 ,''ESTOQUE''
                            FROM PCHISTEST, PCPRODUT, PCDEPTO, PCFORNEC, PCFILIAL
                           WHERE (PCHISTEST.CODPROD = PCPRODUT.CODPROD)
                             AND (PCPRODUT.CODEPTO = PCDEPTO.CODEPTO)
                             AND (PCHISTEST.CODFILIAL = PCFILIAL.CODIGO)
                             AND (PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC)
                             AND (PCDEPTO.TIPOMERC NOT IN (''IM'', ''CI''))
                             AND PCHISTEST.CODFILIAL IN('''||psCODFILIAL||''')
                        GROUP BY PCPRODUT.CODEPTO
                          HAVING SUM(NVL(PCHISTEST.QTESTGER, 0) * NVL(PCHISTEST.CUSTOREP, 0)) <> 0)';
      -- Executae o select acima
      EXECUTE IMMEDIATE vsSQL USING pdDATA;
    -- Fim da validação da PCFINANC2
    END IF;

    BEGIN
      -- Apagando registros gerados pela rotina 117
      DELETE PCFINANC
       WHERE PCFINANC.CODFILIAL IN (psCODFILIAL)
        AND PCFINANC.CODROTINA = 117;
      -- Conta a quantidade de registro na PCFINANC para o dia em questão
      SELECT COUNT(1)
        INTO V_COUNT
        FROM PCFINANC
       WHERE PCFINANC.DATA = pdDATA
         AND PCFINANC.CODFILIAL = psCODFILIAL;
      -- Incluindo registro Zerado
      IF V_COUNT <= 0 THEN
        INSERT INTO PCFINANC( DATA,  CODFILIAL,  SALDOEMPRESTATIVO, SALDOCX, SALDOINVESTATIVO, SALDOCRFOR, SALDOCTRANS, SALDOCP, SALDOEMPRESTPASSIVO, SALDOBCO, SALDOINVESTPASSIVO, SALDOCREDCLI, SALDOVALE, SALDOESTREAL, SALDOCR, CODROTINA,  CODFUNC, DTGERACAO, SALDOESTFIN, SALDOADIANTFOR)
             VALUES         ( pdDATA, psCODFILIAL, 0,                 0,       0,                0,          0,           0,       0,                   0,        0,                  0,            0,         0,            0,       pnCODROTINA, pnCODFUNC, SYSDATE,  0,           0);
      END IF;
      -- Atualizando registro
      FOR FINANC2 IN (SELECT SUM(NVL(PCFINANC2.VALOR, 0)) VALOR
                           , PCFINANC2.DATA
                           , PCFINANC2.CODFILIAL
                           , PCFINANC2.TIPODADO
                        FROM PCFINANC2
                       WHERE PCFINANC2.DATA = pdDATA
                         AND PCFINANC2.CODFILIAL = psCODFILIAL
                         AND PCFINANC2.TIPODADO = 'ESTOQUE'
                    GROUP BY PCFINANC2.DATA
                           , PCFINANC2.CODFILIAL
                           , PCFINANC2.TIPODADO)
      LOOP
        /*Atualizando saldos da PCFINANC*/
        UPDATE PCFINANC
           SET PCFINANC.SALDOESTREAL        = DECODE (Trim(FINANC2.TIPODADO), 'ESTOQUE'  , FINANC2.VALOR, PCFINANC.SALDOESTREAL)
              ,PCFINANC.SALDOESTFIN         = DECODE (Trim(FINANC2.TIPODADO), 'ESTOQUE'  , FINANC2.VALOR, PCFINANC.SALDOESTFIN)
         WHERE PCFINANC.DATA                = FINANC2.DATA
           AND PCFINANC.CODFILIAL           = FINANC2.CODFILIAL;
      END LOOP;
      -- Buscando os valores do contas a receber
      SELECT NVL(SUM(NVL(PCLANC.VALOR,0) -
                     NVL(PCLANC.DESCONTOFIN,0) +
                     NVL(PCLANC.TXPERM,0) -
                     NVL(PCLANC.VALORDEV,0)),0) SALDOCPMANUAL
       INTO VSALDOCPMANUAL
       FROM PCLANC
          , PCCONSUM
      WHERE PCLANC.DTPAGTO is null
        AND PCLANC.CODCONTA <> PCCONSUM.CODCONTAJUSTEEST
        AND PCLANC.CODCONTA <> PCCONSUM.CODCONTRECJUR
        AND PCLANC.CODCONTA <> PCCONSUM.CODCONTPAGJUR
        AND PCLANC.CODCONTA <> PCCONSUM.CODCONTANTPAG
        AND PCLANC.CODFILIAL IN (psCODFILIAL);
      -- Atualizando colunas de acumuladores
      UPDATE PCFINANC
         SET PCFINANC.SALDOREAL     = PCFINANC.SALDOCX               /*Caixa*/
                                    + PCFINANC.SALDOBCO              /*Banco*/
                                    + PCFINANC.SALDOVALE             /*Vales*/
                                    + PCFINANC.SALDOEMPRESTATIVO     /*Emprest. Ativo*/
                                    + PCFINANC.SALDOCTRANS           /*Contas Transitorias*/
                                    + PCFINANC.SALDOCR               /*Contas a Receber*/
                                    + PCFINANC.SALDOCRFOR            /*Contas a Receber de Fornecedor*/
                                    + PCFINANC.SALDOESTFIN           /*Vl. Estoque*/
                                    + PCFINANC.SALDOINVESTATIVO      /*Invest. Ativo*/
                                    + PCFINANC.SALDOADIANTFOR        /*Adiant. de Fornec.*/
                                    - PCFINANC.SALDOCP               /*Contas a Pagar*/
                                    - PCFINANC.SALDOEMPRESTPASSIVO   /*Emp. Passivo*/
                                    - PCFINANC.SALDOCREDCLI          /*Credito de Cliente*/
                                    - PCFINANC.SALDOINVESTPASSIVO    /*Invest. Passivo*/
                                    - PCFINANC.SALDOTITULOVENDOR     /*Títulos Descontador/Vendor*/
                                    - PCFINANC.SALDOCPOUTROS         /*Contas a pagar outros fornecedores*/

           , PCFINANC.SALDOFIN      = PCFINANC.SALDOCX               /*Caixa*/
                                    + PCFINANC.SALDOBCO              /*Banco*/
                                    + PCFINANC.SALDOVALE             /*Vales*/
                                    + PCFINANC.SALDOEMPRESTATIVO     /*Emprest. Ativo*/
                                    + PCFINANC.SALDOCTRANS           /*Contas Transitorias*/
                                    + PCFINANC.SALDOCR               /*Contas a Receber*/
                                    + PCFINANC.SALDOCRFOR            /*Contas a Receber de Fornecedor*/
                                    + PCFINANC.SALDOESTFIN           /*Vl. Estoque*/
                                    + PCFINANC.SALDOINVESTATIVO      /*Invest. Ativo*/
                                    + PCFINANC.SALDOADIANTFOR        /*Adiant. de Fornec.*/
                                    - PCFINANC.SALDOCP               /*Contas a Pagar*/
                                    - PCFINANC.SALDOEMPRESTPASSIVO   /*Emp. Passivo*/
                                    - PCFINANC.SALDOCREDCLI          /*Credito de Cliente*/
                                    - PCFINANC.SALDOINVESTPASSIVO    /*Invest. Passivo*/
                                    - PCFINANC.SALDOTITULOVENDOR     /*Títulos Descontador/Vendor*/
                                    - PCFINANC.SALDOCPOUTROS         /*Contas a pagar outros fornecedores*/

           , PCFINANC.SALDOCPMANUAL = VSALDOCPMANUAL - PCFINANC.SALDOCP
       WHERE PCFINANC.DATA          = pdDATA
         AND PCFINANC.CODFILIAL     = psCODFILIAL;
    -- Fim função de atualização da PCFINANC
    END;
  -- Fim da procedure
  END PRC_REC_PAT_LIQ;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  09/05/2017     Fernandes Brito                       Criada a procedure para recalcular a quantidade em transito das vendas manifesto
  31/08/2018     Thiago Pinheiro                       Alterada a função para buscar o saldo inicial da PCHISTEST
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_REC_TRANSITO_TV13(psCODFILIAL IN PCMOV.CODFILIAL%TYPE DEFAULT NULL
                                 ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                                 ,pdDATAINI   IN PCMOV.DTMOV%TYPE)
  IS-- Criar variaveis
    vnCOUNT           NUMBER;
    vnSALDODIA        NUMBER(18, 5) := 0;
    vnQTSALDO         NUMBER(18, 5) := 0;
    vnSALDOANTERIOR   NUMBER(18, 5) := 0;
    vnEXISTEPCHISTEST NUMBER(1)     := 0;
    vdDATATESTE       DATE;
  -- Inicio da procedure
  BEGIN
    -- Lista de produtos
    FOR PRODUTOS IN (SELECT CODPROD
                       FROM PCEST
                      WHERE CODFILIAL <> '99'
                        AND (DECODE(psCODFILIAL,'99',NULL,psCODFILIAL) IS NULL OR CODFILIAL = psCODFILIAL)
                        AND (pnCODPROD IS NULL OR CODPROD = pnCODPROD)) LOOP
      -- Buscar saldo das vendas de manifesto
      BEGIN
        SELECT (TV13.QT - (TV14.QT + DEVTV13.QT)) QTSALDO
          INTO vnQTSALDO
          FROM (SELECT NVL(SUM(DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                      0,
                                      PCMOV.QT,
                                      PCMOVCOMPLE.QTRETORNOTV13)),
                           0) QT
                  FROM PCMOV, PCNFSAID, PCMOVCOMPLE
                 WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                   AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                   AND PCNFSAID.CONDVENDA = 13
                   AND PCMOV.CODOPER IS NOT NULL
                   AND PCMOV.DTMOV BETWEEN pdDATAINI AND TRUNC(SYSDATE)
                   AND PCMOV.CODFILIAL = psCODFILIAL
                   AND CODPROD = PRODUTOS.CODPROD) TV13,
               (SELECT NVL(SUM(DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                      0,
                                      PCMOV.QT,
                                      PCMOVCOMPLE.QTRETORNOTV13)),
                           0) QT
                  FROM PCMOV, PCNFSAID, PCMOVCOMPLE
                 WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                   AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                   AND PCNFSAID.CONDVENDA = 14
                   AND PCMOV.DTMOV BETWEEN pdDATAINI AND TRUNC(SYSDATE)
                   AND PCMOV.CODOPER = 'S'
                   AND PCMOV.CODFILIAL = psCODFILIAL
                   AND CODPROD = PRODUTOS.CODPROD) TV14,
               (SELECT NVL(SUM(CASE
                                 WHEN (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('DEVOLVESIMPLESREMTV13TOTAL',
                                                                          NVL(PCMOV.CODFILIALNF,
                                                                              PCMOV.CODFILIAL),
                                                                          'N') = 'S' AND
                                      PCMOV.ROTINACAD LIKE '%1332%') THEN
                                        
                                  NVL(PCMOVCOMPLE.QTRETORNOTV13, 0)
                                 ELSE
                                  DECODE(NVL(PCMOV.QTCONT, 0),
                                         0,
                                         NVL(PCMOV.QT, 0),
                                         NVL(PCMOV.QTCONT, 0))
                               END),
                           0) QT
                  FROM PCNFENT, PCMOV, PCESTCOM, PCNFSAID, PCMOVCOMPLE
                 WHERE PCNFENT.NUMTRANSENT = PCMOV.NUMTRANSENT
                   AND PCESTCOM.NUMTRANSENT = PCNFENT.NUMTRANSENT
                   AND PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
                   AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                   AND PCESTCOM.NUMTRANSVENDA > 0
                   AND PCNFSAID.CONDVENDA = 13
                   AND PCMOV.CODOPER = 'ED'
                   AND PCMOV.DTMOV BETWEEN pdDATAINI AND TRUNC(SYSDATE)
                   AND PCNFENT.CODFILIAL = psCODFILIAL
                   AND PCMOV.CODPROD = PRODUTOS.CODPROD) DEVTV13;
        -- Caso não exista vendas manifesto neste periodo
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnQTSALDO := 0;
      END;
      -- Bloqueando estoque para fazer as alterações
      BEGIN
        SELECT QTESTGER
          INTO VNREGISTRO
          FROM PCEST
         WHERE CODPROD = PRODUTOS.CODPROD
           AND CODFILIAL = psCODFILIAL
           FOR UPDATE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          VNREGISTRO := 0;
      END;
      -- Busca Saldo Tv13 inicial
      BEGIN
        SELECT NVL(PCHISTEST.QTTRANSITOTV13, 0)
          INTO vnSALDOANTERIOR
          FROM PCHISTEST
         WHERE PCHISTEST.CODFILIAL = psCODFILIAL
           AND PCHISTEST.CODPROD = PRODUTOS.CODPROD
           AND PCHISTEST.DATA = pdDATAINI - 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnSALDOANTERIOR := 0;
      END;
      -- Atualiza o estoque atual
      UPDATE PCEST
         SET QTTRANSITOTV13 = vnQTSALDO + vnSALDOANTERIOR
       WHERE CODPROD = PRODUTOS.CODPROD
         AND CODFILIAL = psCODFILIAL;
      -- Lista de dias (de hoje até o dia informado como inicial)
      FOR PERIODO IN (SELECT (pdDATAINI + ROWNUM - 1) DATA
                        FROM DUAL
                      CONNECT BY LEVEL <= TRUNC(SYSDATE) - pdDATAINI + 1
                       ORDER BY (pdDATAINI + ROWNUM - 1)) LOOP
        vnSALDODIA  := 0;
        vdDATATESTE := PERIODO.DATA; -- Variavel para teste de debug
        -- Validar dada
        -- Verifica se existe PCHISTEST.
        BEGIN
          SELECT 1
            INTO vnEXISTEPCHISTEST
            FROM PCHISTEST
           WHERE PCHISTEST.CODFILIAL = psCODFILIAL
             AND PCHISTEST.CODPROD = PRODUTOS.CODPROD
             AND PCHISTEST.DATA = PERIODO.DATA;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnEXISTEPCHISTEST := 0;
        END;
        --
        IF (PERIODO.DATA <> TRUNC(SYSDATE) AND vnEXISTEPCHISTEST = 1) THEN
          -- Buscar saldo das vendas de manifesto para atualizar saldos anteriores
          BEGIN
            SELECT (TV13.QT - (TV14.QT + DEVTV13.QT)) QTSALDO
              INTO vnSALDODIA
              FROM (SELECT NVL(SUM(DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                          0,
                                          PCMOV.QT,
                                          PCMOVCOMPLE.QTRETORNOTV13)),
                               0) QT
                      FROM PCMOV, PCNFSAID, PCMOVCOMPLE
                     WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                       AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                       AND PCNFSAID.CONDVENDA = 13
                       AND PCMOV.CODOPER IS NOT NULL
                       AND PCMOV.DTMOV BETWEEN pdDATAINI AND PERIODO.DATA
                       AND PCMOV.CODFILIAL = psCODFILIAL
                       AND CODPROD = PRODUTOS.CODPROD) TV13,
                   (SELECT NVL(SUM(DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0),
                                          0,
                                          PCMOV.QT,
                                          PCMOVCOMPLE.QTRETORNOTV13)),
                               0) QT
                      FROM PCMOV, PCNFSAID, PCMOVCOMPLE
                     WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                       AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                       AND PCNFSAID.CONDVENDA = 14
                       AND PCMOV.DTMOV BETWEEN pdDATAINI AND PERIODO.DATA
                       AND PCMOV.CODOPER = 'S'
                       AND PCMOV.CODFILIAL = psCODFILIAL
                       AND CODPROD = PRODUTOS.CODPROD) TV14,
                   (SELECT NVL(SUM(CASE
                                     WHEN (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('DEVOLVESIMPLESREMTV13TOTAL',
                                                                              NVL(PCMOV.CODFILIALNF,
                                                                                  PCMOV.CODFILIAL),
                                                                              'N') = 'S' AND
                                          PCMOV.ROTINACAD LIKE '%1332%') THEN
                                      NVL(PCMOVCOMPLE.QTRETORNOTV13, 0)
                                   ELSE   
                                      DECODE(NVL(PCMOV.QTCONT, 0), 0, NVL(PCMOV.QT, 0), NVL(PCMOV.QTCONT, 0))
                                   END),
                               0) QT
                      FROM PCNFENT, PCMOV, PCESTCOM, PCNFSAID, PCMOVCOMPLE
                     WHERE PCNFENT.NUMTRANSENT = PCMOV.NUMTRANSENT
                       AND PCESTCOM.NUMTRANSENT = PCNFENT.NUMTRANSENT
                       AND PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
                       AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                       AND PCESTCOM.NUMTRANSVENDA > 0
                       AND PCNFSAID.CONDVENDA = 13
                       AND PCMOV.CODOPER = 'ED'
                       AND PCMOV.DTMOV BETWEEN pdDATAINI AND PERIODO.DATA
                       AND PCNFENT.CODFILIAL = psCODFILIAL
                       AND PCMOV.CODPROD = PRODUTOS.CODPROD) DEVTV13;
            -- Caso não exista vendas manifesto antes da data inicial
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnSALDODIA := 0;
          END;
          -- Bloqueando HISTORICO para fazer as alterações
          BEGIN
            SELECT NVL(QTTRANSITOTV13, 0)
              INTO vnCOUNT
              FROM PCHISTEST
             WHERE DATA = PERIODO.DATA
               AND CODPROD = PRODUTOS.CODPROD
               AND CODFILIAL = psCODFILIAL
               FOR UPDATE;
            -- Caso não exista pchistest nesse dia.
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnCOUNT := 0;
          END;
          /***
           --- Modificado por Thiago. => Não é para criar pchistest.
           -- A quantidade tv13 deve ser atualizada apenas para a pchistest que existir.
          EXCEPTION
            -- Caso não exista chame a função para criar
          WHEN NO_DATA_FOUND THEN
              PKG_ANALISAR_ESTOQUE.PRC_CORRIGIR_PCHISTEST(psCODFILIAL,
                                                          PRODUTOS.CODPROD,
                                                          PERIODO.DATA,
                                                          PERIODO.DATA,
                                                          '');
          END;   ***/

          -- Atualizar a PCHISTEST com o resultado atribuido as variaveis
          UPDATE PCHISTEST
             SET QTTRANSITOTV13 = vnSALDODIA + vnSALDOANTERIOR
           WHERE DATA = PERIODO.DATA
             AND CODPROD = PRODUTOS.CODPROD
             AND CODFILIAL = psCODFILIAL;
          -- Fim da validação da data de hoje
        END IF;
        -- Fim da lista de dias
      END LOOP;
      -- Confirmando alteração do produto
      COMMIT WORK;
      -- Fim da lista de produtos
    END LOOP;
    -- Fim da procedure
  END PRC_REC_TRANSITO_TV13;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para buscar dados pre requisição de consumo
  /***********************************************************************************************************************/
  PROCEDURE PRC_REQUISICAO_DEPOSITO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vCURSOR_PEDIDOS SYS_REFCURSOR;
    vTYPE_PEDIDOS   T_DADOS;
    vCHAMADA        TP_ENTRADA;
  BEGIN
    -- Utiliza Estoque por Depósito?
    IF vRECALCULAR_RESERVADO_DEPOSITO = 'S' THEN
      --Atualizar PCEST.QTRESERV conforme as requisições de transf. entre depósitos (rotina 1108)
      vSQL := 'SELECT SUM(R.QT) AS QTDE
                     ,R.CODFILIAL
                     ,R.CODPROD
                     ,R.CODDEPOSITOORIG AS CODDEPOSITO'||CHR(13);
      -- Utiliza estoque por Lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        vSQL := vSQL || ',R.NUMLOTEORIG NUMLOTE'||CHR(13);
      ELSE
        vSQL := vSQL || ',NULL AS NUMLOTE '||CHR(13);
      END IF;
      -- Complemento SQL
      vSQL := vSQL || '  FROM PCREQUISICAODEPOSITO R
                        WHERE R.POSICAO = ''A''
                          AND R.NOME_TABELA = ''PCREQUISICAODEPOSITO''
                          AND R.CODFILIAL = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39)||CHR(13);
      -- Incluir filtro de produto
      IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
      ELSE
        vSQL := vSQL ||' AND R.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = R.CODPROD AND F.OBS2 = ''FL'') '||CHR(13);
      END IF;
      -- Incluir filtro de departamento
      IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
      END IF;
      -- Incluir filtro de fornecedor
      IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
      END IF;
      -- Incluir filtro de seção
      IF pENTRADA.LISTA_DE_SECOES > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
      END IF;
      -- Incluir filtro de categoria
      IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
      END IF;
      -- Incluir filtro de subcategoria
      IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
      END IF;
      -- Incluir filtro de marca
      IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
        vSQL := vSQL ||' AND R.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
      END IF;
      -- Complemento SQL
      vSQL := vSQL || 'GROUP BY R.CODFILIAL
                               ,R.CODPROD
                               ,R.CODDEPOSITOORIG'||CHR(13);
      -- Utiliza estoque por Lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        vSQL := vSQL || ',R.NUMLOTEORIG'||CHR(13);
      END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Abrindo o cursor com base no sql
    OPEN vCURSOR_PEDIDOS FOR vSQL;
    -- Buscando os dados da primeira linha do cursor
    FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Enquanto não chegar no final das linhas faça
    WHILE NOT vCURSOR_PEDIDOS%NOTFOUND
    LOOP
      vCHAMADA.QUANTIDADE  := vTYPE_PEDIDOS.QTDE;
      vCHAMADA.CODFILIAL   := vTYPE_PEDIDOS.CODFILIAL;
      vCHAMADA.CODPROD     := vTYPE_PEDIDOS.CODPROD;
      vCHAMADA.CODDEPOSITO := vTYPE_PEDIDOS.CODDEPOSITO;
      vCHAMADA.NUMLOTE     := vTYPE_PEDIDOS.NUMLOTE;
      -- Atualizar reservas
      PRC_ESTOQUE_RESERVADO(vCHAMADA);
      PRC_DEPOSITO_RESERVADO(vCHAMADA);
      -- Utiliza estoque por lote?
      IF vRECALCULAR_RESERVADO_LOTE = 'S' THEN
        -- Reserva lote
        PRC_LOTE_RESERVADO(vCHAMADA);
      -- Estoque por lote
      END IF;
      -- Indo para a proxima linha do cursor
      FETCH vCURSOR_PEDIDOS INTO vTYPE_PEDIDOS;
    -- Lista dos produtos
    END LOOP;
    -- Usa multe depósitos
    END IF;
  -- Requisicao Deposito
  END PRC_REQUISICAO_DEPOSITO;

  /***************************************************************************************************************************************
  -------------------------- Alterações --------------------------------------------------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  ----------------------------------------------------------------------------------------------------------------------------------------
  19/01/2015     Fernandes Brito                       Função criada para validar estoque de forma geral
  05/10/2015     Fernandes Brito                       Alterada a Função para Procedure para criar uma tabela fisica no lugar do PIPELINED
  10/06/2016     Fernandes Brito/Rodrigo Santos        Alterada a procedure buscar as movimentações sem usar a função F_TODAS_MOVIMENTACOES
                                                       e buscar os saldos anteriores sem usar a função F_DADOS_HISTEST_ANTERIOR
  08/09/2016     Fernandes Brito                       Incluida a função CLOSE para fechar a variável vcCURSOR_GERAL e assim
                                                       evitar problemas com lixo no cursor

  Observações:
  Para saber mais sobre o parâmetro "psTIPOCHAMADA" veja cabeçalho da procedure PRC_RECALCULO
  --------------------------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE PRC_VALIDAR_ESTOQUE_GERAL (psCODFILIAL   IN PCMOV.CODFILIAL%TYPE
                                      ,pnCODPROD     IN PCMOV.CODPROD%TYPE DEFAULT NULL
                                      ,pdDATA        IN PCMOV.DTMOV%TYPE DEFAULT NULL
                                      ,psTIPOCHAMADA IN VARCHAR2) -- EXTERNA ou INTERNA
  IS
    -- Variaveis de uso interno
    vnQTESTGERANT          PCHISTEST.QTESTGER%TYPE;
    vnQTESTGER             PCHISTEST.QTESTGER%TYPE;
    vnDIF_GER              PCMOV.QT%TYPE;
    vnQTESTANT             PCHISTEST.QTEST%TYPE;
    vnQTEST                PCHISTEST.QTEST%TYPE;
    vnDIF_CONT             PCMOV.QT%TYPE;
    vdDATAULTINVENT        PCHISTEST.DATA%TYPE;
    vdDATAANTERIOR         PCHISTEST.DATA%TYPE;
    vsOBS                  VARCHAR2(2000);
    vrDADOS_GERAL          TR_VALIDA_MOV;
    vcCURSOR_GERAL         SYS_REFCURSOR;
    vdMAIORDATA            PCHISTEST.DATA%TYPE;
  BEGIN
    -- Lista de produtos a serem analisados
    FOR PRODUTOS IN (SELECT CODPROD
                       FROM PCPRODUT
                      WHERE CODPROD = pnCODPROD OR pnCODPROD IS NULL)
    LOOP
      -- Verificando se a chamada é externa
      IF NVL(psTIPOCHAMADA,'NORMAL') = 'INTERNA' THEN
        -- Buscando informações sobre a data do ultimo inventário
        SELECT DTULTINVENTARIO
              ,OBS
          INTO vdDATAULTINVENT
              ,vsOBS
          FROM TABLE(F_VALIDAR_PERIODO(psCODFILIAL,PRODUTOS.CODPROD,NULL));
      ELSE
        vsOBS           := 'OK';
        vdDATAULTINVENT := pdDATA;
      END IF;
      -- Caso a data de inventário seja valida.
      IF vsOBS = 'OK' THEN
        -- Zerando as variáveis para evitar problemas
        vnQTESTGERANT := NULL;
        vnQTESTGER    := NULL;
        vnDIF_GER     := NULL;
        vnDIF_CONT    := NULL;
        vnQTESTANT    := NULL;
        vnQTEST       := NULL;
        -- Localizar a data base
        SELECT MAX(DATA)
          INTO vdMAIORDATA
          FROM PCHISTEST
         WHERE DATA <= vdDATAULTINVENT
           AND CODPROD = pnCODPROD
           AND CODFILIAL = psCODFILIAL;
        -- Caso não exista PCHISEST para o produto
        IF vdMAIORDATA IS NULL THEN
          -- Busca a data de cadastro do produto
          BEGIN
            SELECT DTCADASTRO
              INTO vdDTCADASTRO
              FROM PCPRODUT
             WHERE CODPROD = pnCODPROD;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vdDTCADASTRO := vdDATAULTINVENT;
          END;
          -- Validar data antes de começar
          IF vdDTCADASTRO > vdDATAULTINVENT THEN
            -- Buscar o menor PCHISTEST na data de cadastro
            SELECT MIN(DATA)
              INTO vdMAIORDATA
              FROM PCHISTEST
             WHERE DATA BETWEEN vdDTCADASTRO AND TRUNC(SYSDATE)
               AND CODPROD = pnCODPROD
               AND CODFILIAL = psCODFILIAL;
            -- Caso não exista PCHISTEST para o produto
            IF vdMAIORDATA IS NOT NULL THEN
              vdDATAULTINVENT := vdMAIORDATA;
            END IF;
          -- Fim validação da data de cadastro
          END IF;
        -- Fim validação do PCHISTEST
        END IF;
        -- Buscar dados do dia anterior
        BEGIN
          SELECT DATA
                ,QTESTGER
                ,QTEST
            INTO vdDATAANTERIOR
                ,vnQTESTGERANT
                ,vnQTESTANT
            FROM PCHISTEST
           WHERE CODFILIAL = psCODFILIAL
             AND CODPROD = PRODUTOS.CODPROD
             AND DATA = vdDATAULTINVENT;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vdDATAANTERIOR := NULL;
            vnQTESTGERANT  := 0;
            vnQTESTANT     := 0;
          WHEN OTHERS THEN
            raise_application_error(-20001, 'Erro ao processar o produto : '||PRODUTOS.CODPROD||CHR(13)||
                                   ' Erro: '||SQLERRM||CHR(13)||
                                   ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END;
        -- Valida se existe dados para do dia anterior
        IF NVL(vdDATAANTERIOR,TO_DATE('30/DEC/1899','DD/MM/YYYY')) <> TO_DATE('30/DEC/1899','DD/MM/YYYY') THEN
          -- Buscar dados do estoque atualmente
          BEGIN
            SELECT C.QTESTGER
                  ,C.QTEST
              INTO vnQTESTGER
                  ,vnQTEST
              FROM PCEST C
             WHERE C.CODPROD = PRODUTOS.CODPROD
               AND C.CODFILIAL = psCODFILIAL;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnQTESTGER := 0;
              vnQTEST    := 0;
          END;
          -- Limpar as tabelas
          PRC_LIMPAR_SALDOS;
          -- Inserir lista de dias
          PRC_INS_LISTA_DIAS ((vdDATAULTINVENT + 1), TRUNC(SYSDATE));
          -- Inserir saldo das movimentações contabeis
          PRC_MOV_CONT (psCODFILIAL,PRODUTOS.CODPROD,(vdDATAULTINVENT + 1),TRUNC(SYSDATE),psTIPOCHAMADA);
          -- Inserir saldo das movimentações contabeis
          PRC_MOV_GER (psCODFILIAL,PRODUTOS.CODPROD,(vdDATAULTINVENT + 1),TRUNC(SYSDATE));
          -- Zerando o contador
          vnCONTADOR := 0;
          -- Preparando select para validar as movimentações do produto
          vsSQL :='SELECT COUNT(*)
                     FROM (SELECT PCSALDOMOVGERENCIAIS.ID
                                 ,PCSALDOMOVGERENCIAIS.DTMOV
                                 ,PCSALDOMOVGERENCIAIS.CODFILIAL
                                 ,PCSALDOMOVGERENCIAIS.CODPROD
                                 ,PCSALDOMOVGERENCIAIS.SALDO
                             FROM PCSALDOMOVGERENCIAIS
                           UNION ALL
                           SELECT PCSALDOMOVCONTABEIS.ID
                                 ,PCSALDOMOVCONTABEIS.DTMOV
                                 ,PCSALDOMOVCONTABEIS.CODFILIAL
                                 ,PCSALDOMOVCONTABEIS.CODPROD
                                 ,PCSALDOMOVCONTABEIS.SALDO
                             FROM PCSALDOMOVCONTABEIS) DADOS
                         ,PCLISTADIAS
                    WHERE PCLISTADIAS.DATA = DADOS.DTMOV(+)
                      AND PCLISTADIAS.ID = DADOS.ID(+)
                      AND PCLISTADIAS.ID IN (''GERENCIAL'',''CONTABIL'')
                      AND DADOS.CODFILIAL = '||CHR(39)||psCODFILIAL||CHR(39)||'
                      AND DADOS.CODPROD = '||PRODUTOS.CODPROD;
          -- Executando select para validar movimentações
          EXECUTE IMMEDIATE vsSQL INTO vnCONTADOR;
          -- Caso tenha movimentação para o produto
          IF vnCONTADOR > 0 THEN
            -- Lista de dias do período e todas as movimentações
            vsSQL := 'SELECT DADOS.ID
                            ,SUM(NVL(DADOS.SALDO,0)) SALDO
                        FROM (SELECT PCSALDOMOVGERENCIAIS.ID
                                    ,PCSALDOMOVGERENCIAIS.DTMOV
                                    ,PCSALDOMOVGERENCIAIS.CODFILIAL
                                    ,PCSALDOMOVGERENCIAIS.CODPROD
                                    ,PCSALDOMOVGERENCIAIS.SALDO
                                FROM PCSALDOMOVGERENCIAIS
                              UNION ALL
                              SELECT PCSALDOMOVCONTABEIS.ID
                                    ,PCSALDOMOVCONTABEIS.DTMOV
                                    ,PCSALDOMOVCONTABEIS.CODFILIAL
                                    ,PCSALDOMOVCONTABEIS.CODPROD
                                    ,PCSALDOMOVCONTABEIS.SALDO
                                FROM PCSALDOMOVCONTABEIS) DADOS
                            ,PCLISTADIAS
                       WHERE PCLISTADIAS.DATA = DADOS.DTMOV
                         AND PCLISTADIAS.ID = DADOS.ID
                         AND PCLISTADIAS.ID IN (''GERENCIAL'',''CONTABIL'')
                         AND DADOS.CODFILIAL = '||CHR(39)||psCODFILIAL||CHR(39)||'
                         AND DADOS.CODPROD = '||PRODUTOS.CODPROD||'
                      GROUP BY DADOS.ID';
            -- Abrindo o cursor com base no sql
            OPEN vcCURSOR_GERAL FOR vsSQL;
            -- Buscando os dados da primeira linha do cursor
            FETCH vcCURSOR_GERAL INTO vrDADOS_GERAL;
            -- Enquanto não chegar no final das linhas faça
            WHILE NOT vcCURSOR_GERAL%NOTFOUND LOOP
              -- Retornando os dados para registros gerenciais
              IF vrDADOS_GERAL.ID = 'GERENCIAL' THEN
                -- Preparando insert na PCANALISEDOESTOQUE
                vsINSERT := 'INSERT
                               INTO PCANALISEDOESTOQUE (
                                    TIPOMOVIMENTACAO
                                   ,CODPROD
                                   ,CODFILIAL
                                   ,DTANTERIOR
                                   ,QTANTERIOR
                                   ,QTMOVIMETADA
                                   ,QTESTOQUEATUAL
                                   ,QTCORRETA
                                   ,QTDIF
                                   ,OBSERVACAO)
                            VALUES (''GERENCIAL''
                                   ,'||PRODUTOS.CODPROD||'
                                   ,'||CHR(39)||psCODFILIAL||CHR(39)||'
                                   ,'||CHR(39)||vdDATAANTERIOR||CHR(39)||'
                                   ,'||CHR(39)||vnQTESTGERANT||CHR(39)||'
                                   ,'||CHR(39)||vrDADOS_GERAL.SALDO||CHR(39)||'
                                   ,'||CHR(39)||vnQTESTGER||CHR(39)||'
                                   ,'||CHR(39)||(vnQTESTGERANT + vrDADOS_GERAL.SALDO)||CHR(39)||'
                                   ,'||CHR(39)||((vnQTESTGERANT + vrDADOS_GERAL.SALDO) - vnQTESTGER)||CHR(39)||'
                                   ,'||CHR(39)||vsOBS||CHR(39)||')';
                -- Executando insert na PCANALISEDOESTOQUE
                EXECUTE IMMEDIATE vsINSERT;
              -- Retornando os dados para registros contabeis
              ELSIF vrDADOS_GERAL.ID = 'CONTABIL' THEN
                -- Preparando insert na PCANALISEDOESTOQUE
                vsINSERT := 'INSERT
                               INTO PCANALISEDOESTOQUE (
                                    TIPOMOVIMENTACAO
                                   ,CODPROD
                                   ,CODFILIAL
                                   ,DTANTERIOR
                                   ,QTANTERIOR
                                   ,QTMOVIMETADA
                                   ,QTESTOQUEATUAL
                                   ,QTCORRETA
                                   ,QTDIF
                                   ,OBSERVACAO)
                            VALUES (''CONTABIL''
                                   ,'||PRODUTOS.CODPROD||'
                                   ,'||CHR(39)||psCODFILIAL||CHR(39)||'
                                   ,'||CHR(39)||vdDATAANTERIOR||CHR(39)||'
                                   ,'||CHR(39)||vnQTESTANT||CHR(39)||'
                                   ,'||CHR(39)||vrDADOS_GERAL.SALDO||CHR(39)||'
                                   ,'||CHR(39)||vnQTEST||CHR(39)||'
                                   ,'||CHR(39)||(vnQTESTANT + vrDADOS_GERAL.SALDO)||CHR(39)||'
                                   ,'||CHR(39)||((vnQTESTANT + vrDADOS_GERAL.SALDO) - vnQTEST)||CHR(39)||'
                                   ,'||CHR(39)||vsOBS||CHR(39)||')';
                -- Executando insert na PCANALISEDOESTOQUE
                EXECUTE IMMEDIATE vsINSERT;
              -- Fim do insert na PCANALISEDOESTOQUE
              END IF;
              -- Indo para a proxima linha do cursor
              FETCH vcCURSOR_GERAL INTO vrDADOS_GERAL;
            -- Fim da lista de movimentações
            END LOOP;
            -- Fechando curos
            CLOSE vcCURSOR_GERAL;
          -- Caso não tenha movimentação para o produto
          ELSE
            -- Preparando insert na PCANALISEDOESTOQUE
            vsINSERT := 'INSERT
                           INTO PCANALISEDOESTOQUE (
                                TIPOMOVIMENTACAO
                               ,CODPROD
                               ,CODFILIAL
                               ,DTANTERIOR
                               ,QTANTERIOR
                               ,QTMOVIMETADA
                               ,QTESTOQUEATUAL
                               ,QTCORRETA
                               ,QTDIF
                               ,OBSERVACAO)
                        VALUES (''CONTABIL''
                               ,'||PRODUTOS.CODPROD||'
                               ,'||CHR(39)||psCODFILIAL||CHR(39)||'
                               ,'||CHR(39)||vdDATAANTERIOR||CHR(39)||'
                               ,'||CHR(39)||vnQTESTANT||CHR(39)||'
                               ,0
                               ,'||CHR(39)||vnQTEST||CHR(39)||'
                               ,'||CHR(39)||vnQTESTANT||CHR(39)||'
                               ,'||CHR(39)||(vnQTESTANT - vnQTEST)||CHR(39)||'
                               ,'||CHR(39)||vsOBS||CHR(39)||')';
            -- Executando insert na PCANALISEDOESTOQUE
            EXECUTE IMMEDIATE vsINSERT;
            -- Preparando insert na PCANALISEDOESTOQUE
            vsINSERT := 'INSERT
                           INTO PCANALISEDOESTOQUE (
                                TIPOMOVIMENTACAO
                               ,CODPROD
                               ,CODFILIAL
                               ,DTANTERIOR
                               ,QTANTERIOR
                               ,QTMOVIMETADA
                               ,QTESTOQUEATUAL
                               ,QTCORRETA
                               ,QTDIF
                               ,OBSERVACAO)
                        VALUES (''GERENCIAL''
                               ,'||PRODUTOS.CODPROD||'
                               ,'||CHR(39)||psCODFILIAL||CHR(39)||'
                               ,'||CHR(39)||vdDATAANTERIOR||CHR(39)||'
                               ,'||CHR(39)||vnQTESTGERANT||CHR(39)||'
                               ,0
                               ,'||CHR(39)||vnQTESTGER||CHR(39)||'
                               ,'||CHR(39)||vnQTESTGERANT||CHR(39)||'
                               ,'||CHR(39)||(vnQTESTGERANT - vnQTESTGER)||CHR(39)||'
                               ,'||CHR(39)||vsOBS||CHR(39)||')';
            -- Executando insert na PCANALISEDOESTOQUE
            EXECUTE IMMEDIATE vsINSERT;
          -- Fim da validação das movimentações
          END IF;
          -- Confirmando os dados
          COMMIT;
        -- Caso não exista PCHISTEST para o dia pesquisado
        ELSE
          -- Inserindo mensagem
          vsOBS := 'Não existe dados consolidados (PCHISTEST) para a data informada!';
          -- Preparando insert na PCANALISEDOESTOQUE
          vsINSERT := 'INSERT
                         INTO PCANALISEDOESTOQUE (
                              TIPOMOVIMENTACAO
                             ,CODPROD
                             ,CODFILIAL
                             ,DTANTERIOR
                             ,QTANTERIOR
                             ,QTMOVIMETADA
                             ,QTESTOQUEATUAL
                             ,QTCORRETA
                             ,QTDIF
                             ,OBSERVACAO)
                      VALUES (''NENHUM''
                             ,'||PRODUTOS.CODPROD||'
                             ,'||CHR(39)||psCODFILIAL||CHR(39)||'
                             ,'||CHR(39)||vdDATAANTERIOR||CHR(39)||'
                             ,0
                             ,0
                             ,0
                             ,0
                             ,0
                             ,'||CHR(39)||vsOBS||CHR(39)||')';
          -- Executando insert na PCANALISEDOESTOQUE
          EXECUTE IMMEDIATE vsINSERT;
        -- Fim da validação do PCHISTEST
        END IF;
      -- Caso a data de inventário NÃO seja valida.
      ELSE
        -- Preparando insert na PCANALISEDOESTOQUE
        vsINSERT := 'INSERT
                       INTO PCANALISEDOESTOQUE (
                            TIPOMOVIMENTACAO
                           ,CODPROD
                           ,CODFILIAL
                           ,DTANTERIOR
                           ,QTANTERIOR
                           ,QTMOVIMETADA
                           ,QTESTOQUEATUAL
                           ,QTCORRETA
                           ,QTDIF
                           ,OBSERVACAO)
                    VALUES (''NENHUM''
                           ,'||PRODUTOS.CODPROD||'
                           ,'||CHR(39)||psCODFILIAL||CHR(39)||'
                           ,'||CHR(39)||vdDATAULTINVENT||CHR(39)||'
                           ,0
                           ,0
                           ,0
                           ,0
                           ,0
                           ,'||CHR(39)||vsOBS||CHR(39)||')';
        -- Executando insert na PCANALISEDOESTOQUE
        EXECUTE IMMEDIATE vsINSERT;
      -- Fim da validação da data do inventário
      END IF;
    -- Fim da lista de produtos
    END LOOP;
  -- Fim da procedure validando se existe erros
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,'Erro na procedure'||CHR(13)||
                             ' Erro: '||SQLERRM||CHR(13)||
                             ' Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END PRC_VALIDAR_ESTOQUE_GERAL;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para zerar valores das quantidade reservada e pendente
  /***********************************************************************************************************************/
  PROCEDURE PRC_ZERAR_SALDOS (pENTRADA IN TP_ENTRADA)
  IS
  BEGIN
    /******************************************************************************************************
                             Zerando o QTRESERV e QTPENDENTE do estoque (tabela PCEST)
    ******************************************************************************************************/
    vSQL := 'UPDATE PCEST
                SET QTRESERV = 0
                   ,QTPENDENTE = 0
              WHERE CODFILIAL = '||CHR(39)|| pENTRADA.CODFILIAL ||CHR(39);
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')'||CHR(13);
    ELSE
      vSQL := vSQL||' AND PCEST.CODPROD NOT IN (SELECT F.CODPROD FROM PCPRODUT F  WHERE F.CODPROD = PCEST.CODPROD AND F.OBS2 = ''FL'')'||CHR(13);
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )'||CHR(13);
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )'||CHR(13);
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||'AND PCEST.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )'||CHR(13);
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Executar Sql
    EXECUTE IMMEDIATE vsql;

    /******************************************************************************************************
                             Zerando o QTRESERVADA do estoque do lote (tabela PCLOTE)
    ******************************************************************************************************/
    vSQL := 'UPDATE PCLOTE
                SET PCLOTE.QTRESERV = 0
              WHERE PCLOTE.CODFILIAL = '||CHR(39)||pENTRADA.CODFILIAL||CHR(39);
     
      -- Incluir filtro de produto
      IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')';
      END IF;
      -- Incluir filtro de departamento
      IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )';
      END IF;
      -- Incluir filtro de fornecedor
      IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )';
      END IF;
      -- Incluir filtro de seção
      IF pENTRADA.LISTA_DE_SECOES > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )';
      END IF;
      -- Incluir filtro de categoria
      IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )';
      END IF;
      -- Incluir filtro de subcategoria
      IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )';
      END IF;
      -- Incluir filtro de marca
      IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
        vSQL := vSQL ||'AND PCLOTE.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )';
      END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Executar Sql
    EXECUTE IMMEDIATE vsql;

    /******************************************************************************************************
            Zerando o QTRESERVADA e o QTPENDENTE do estoque do depósito (tabela PCESTOQUEDEPOSITOPROD)
    ******************************************************************************************************/
    vSQL := 'UPDATE PCESTOQUEDEPOSITOPROD
                SET QTRESERVADA = 0
                   ,QTPENDENTE = 0
              WHERE PCESTOQUEDEPOSITOPROD.CODFILIAL = '||CHR(39)|| pENTRADA.CODFILIAL ||CHR(39);
    -- Incluir filtro de depósito
    IF pENTRADA.LISTA_DE_DEPOSITOS > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODDEPOSITO IN ( '||pENTRADA.LISTA_DE_DEPOSITOS||')';
    END IF;
    -- Incluir filtro de produto
    IF pENTRADA.LISTA_DE_PRODUTOS > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN ( '||pENTRADA.LISTA_DE_PRODUTOS||')';
    END IF;
    -- Incluir filtro de departamento
    IF pENTRADA.LISTA_DE_DEPARTAMENTOS > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODEPTO IN ('||pENTRADA.LISTA_DE_DEPARTAMENTOS||') )';
    END IF;
    -- Incluir filtro de fornecedor
    IF pENTRADA.LISTA_DE_FORNECEDORES > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODFORNEC IN ('||pENTRADA.LISTA_DE_FORNECEDORES||') )';
    END IF;
    -- Incluir filtro de seção
    IF pENTRADA.LISTA_DE_SECOES > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSEC IN ('||pENTRADA.LISTA_DE_SECOES||') )';
    END IF;
    -- Incluir filtro de categoria
    IF pENTRADA.LISTA_DE_CATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODCATEGORIA IN ('||pENTRADA.LISTA_DE_CATEGORIAS||') )';
    END IF;
    -- Incluir filtro de subcategoria
    IF pENTRADA.LISTA_DE_SUBCATEGORIAS > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODSUBCATEGORIA IN ('||pENTRADA.LISTA_DE_SUBCATEGORIAS||') )';
    END IF;
    -- Incluir filtro de marca
    IF pENTRADA.LISTA_DE_MARCAS > '0' THEN
      vSQL := vSQL ||'AND PCESTOQUEDEPOSITOPROD.CODPROD IN (SELECT CODPROD FROM PCPRODUT WHERE CODMARCA IN ('||pENTRADA.LISTA_DE_MARCAS||') )';
    END IF;
    -- Gerar log
    /*INSERT INTO SQL_GERADO(DATA, TEXTO_SQL) VALUES (SYSDATE, vSQL);
    COMMIT; --*/
    -- Executar Sql
    EXECUTE IMMEDIATE vsql;
  -- Zerar saldos
  END PRC_ZERAR_SALDOS;

  /************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor               Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  10/02/2020     Fernandes Brito     0                   Criar procedure para orquestrar as procedures de recalculo do reservado
  /***********************************************************************************************************************/
  PROCEDURE PRC_RESERVADO (pENTRADA IN TP_ENTRADA)
  IS-- Variáveis internas
    vENTRADA TP_ENTRADA;
  BEGIN
    -- Atualizar variáveis
    vENTRADA.CODFILIAL              := pENTRADA.CODFILIAL;
    vENTRADA.LISTA_DE_DEPOSITOS     := pENTRADA.LISTA_DE_DEPOSITOS;
    vENTRADA.LISTA_DE_PRODUTOS      := pENTRADA.LISTA_DE_PRODUTOS;
    vENTRADA.LISTA_DE_DEPARTAMENTOS := pENTRADA.LISTA_DE_DEPARTAMENTOS;
    vENTRADA.LISTA_DE_FORNECEDORES  := pENTRADA.LISTA_DE_FORNECEDORES;
    vENTRADA.LISTA_DE_SECOES        := pENTRADA.LISTA_DE_SECOES;
    vENTRADA.LISTA_DE_CATEGORIAS    := pENTRADA.LISTA_DE_CATEGORIAS;
    vENTRADA.LISTA_DE_SUBCATEGORIAS := pENTRADA.LISTA_DE_SUBCATEGORIAS;
    vENTRADA.LISTA_DE_MARCAS        := pENTRADA.LISTA_DE_MARCAS;
    -- Buscar parâmetros
    PRC_BUSCAR_PARAMETROS(vENTRADA);
    -- Zerar saldos
    PRC_ZERAR_SALDOS(vENTRADA);
    /***************************************************
            Atualizar dados do estoque reservado
    ****************************************************/
    vRECALCULAR_RESERVADO          := 'S';
    vRECALCULAR_RESERVADO_DEPOSITO := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZAESTOQUEDEPOSITO',vENTRADA.CODFILIAL ,'N');
    vRECALCULAR_RESERVADO_LOTE     := 'S';
    -- Atualizar Reservado usando pedidos
    PRC_PEDIDOS_DE_VENDA(vENTRADA);
    -- Atualizar Reservado usando pré faturamento
    PRC_PREFAT(vENTRADA);
    -- Atualizar Reservado usando pré requisição de consumo
    PRC_PREREQUISICAO_CONSUMO(vENTRADA);
    -- Atualizar Reservado usando ordem de produção    
    PRC_ORDEM_PRODUCAO(vENTRADA);
    -- Atualizar Ordem de serviço
    PRC_ORDEM_SERVICO(vENTRADA);
  --Atualizar Reservado usando Ordem de Produção Avulsa
    PRC_ORDEM_PRODUCAO_AVULSA(vENTRADA);
    -- Atualizar Reservado usando requisição de transferência entre depósitos
    PRC_REQUISICAO_DEPOSITO(vENTRADA);

    /***************************************************
             Atualizar dados do estoque pendente
    ****************************************************/
    vRECALCULAR_RESERVADO          := 'N';
    vRECALCULAR_RESERVADO_LOTE     := 'N';
    -- Atualizar Pendente usando pedidos
    PRC_PEDIDOS_DE_VENDA(vENTRADA);
  -- Reservado
  END PRC_RESERVADO;
  
  PROCEDURE PRC_RECRIAR_PCHISTEST (pscodfilial  IN varchar2
                                                    ,pdDATA_BASE  IN DATE
                                                    ,pdDTINICIAL  IN date
                                                    ,pdDTFINAL    IN date)
  IS
  
    CURSOR HISTEST_BASE (psCODFILIAL  IN VARCHAR2
                        ,pdDATA_BASE  IN DATE)
    IS
  select *
    from pchistest
     
      WHERE DATA = pdDATA_BASE
        AND CODFILIAL = psCODFILIAL;
  
    CURSOR MOV_CONTABIL (vdDTINICIAL IN DATE
                        ,vdDTFINAL   IN DATE)
     IS
          -- Cursor para movimentações
         (SELECT 'CONTABIL' ID
                 ,DADOS.DTMOV
                 ,DADOS.CODFILIAL
                 ,DADOS.CODPROD
                 ,SUM(DADOS.SALDO) SALDO
            FROM (/* Notas Fiscais de Entrada Normal */
                  SELECT PCNFENT.DTENT DTMOV
                        ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                        ,PCMOV.CODPROD
                        ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', ROUND(PCMOV.QTCONT, 6), 0)),0) SALDO
                    FROM PCNFENT
                        ,PCMOV
                   WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                     AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                     AND PCNFENT.DTENT BETWEEN vdDTINICIAL AND vdDTFINAL
                     AND PCNFENT.DTENT = PCMOV.DTMOV
                     AND NVL(PCNFENT.CODFILIALNF,PCNFENT.CODFILIAL) = NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL)
                     AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                     AND PCMOV.QTCONT > 0
                     AND PCNFENT.TIPODESCARGA NOT IN ('F', 'P', 'H','G')
                     AND PCNFENT.ESPECIE IN ('NF','OE','NP','NE','TP')
                     AND PCMOV.STATUS IN ('A', 'AB')
                     AND NVL(PCNFENT.FINALIDADENFE, 'O') <> 'C'
                GROUP BY PCNFENT.DTENT,
                         NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                         PCMOV.CODPROD
                   ---------------------------------------------------------
                   UNION ALL
                   ---------------------------------------------------------
                  /* Notas Fiscais de Entrada Canceladas */
                  SELECT TRUNC(PCMOV.DTCANCEL) DTMOV
                        ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                        ,PCMOV.CODPROD
                        ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', ROUND(PCMOV.QTCONT, 6), 0)),0) SALDO
                    FROM PCNFENT
                        ,PCMOV
                   WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                     AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                     AND TRUNC(PCMOV.DTCANCEL) BETWEEN vdDTINICIAL AND vdDTFINAL
                     AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                     AND NVL(PCNFENT.CODFILIALNF,PCNFENT.CODFILIAL) = NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL)
                     AND PCMOV.DTCANCEL IS NOT NULL
                     AND PCMOV.QTCONT < 0
                     AND PCNFENT.TIPODESCARGA NOT IN ('F', 'P', 'H','G')
                     AND PCNFENT.ESPECIE IN ('NF','OE','NP','NE','TP')
                     AND PCMOV.STATUS IN ('A', 'AB')
                     AND NVL(PCNFENT.FINALIDADENFE, 'O') <> 'C'
                GROUP BY TRUNC(PCMOV.DTCANCEL),
                         NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                         PCMOV.CODPROD
                   ---------------------------------------------------------
                   UNION ALL
                   ---------------------------------------------------------
                  /* Notas Fiscais de Saída Normal */
                  SELECT PCNFSAID.DTSAIDA DTMOV
                        ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                        ,PCMOV.CODPROD
                        ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'S', (ROUND(PCMOV.QTCONT, '6') * (-1)), 0)), 0) SALDO
                    FROM PCNFSAID
                        ,PCMOV
                        ,PCMOVCOMPLE
                   WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                     AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                     AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                     AND PCNFSAID.DTSAIDA BETWEEN vdDTINICIAL AND vdDTFINAL
                     AND PCNFSAID.DTSAIDA = PCMOV.DTMOV
                     AND (NVL(PCNFSAID.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 14) OR (NVL(PCNFSAID.CONDVENDA, 0) = 7 AND NVL(PCNFSAID.FORNECENTREGA, 'N') = 'S'))
                     AND PCMOV.QTCONT > 0
                     AND NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL)
                     AND NVL(PCMOVCOMPLE.MOVEST,'S') = 'S'
                     AND PCMOV.CODFISCAL NOT IN (5929, 6929)
                     AND PCNFSAID.ESPECIE IN ('NF', 'CF','NP', 'CP','NE')
                     AND PCMOV.STATUS IN ('A', 'AB')
                     AND NVL(PCNFSAID.FINALIDADENFE, 'O') <> 'C'
                     AND PCNFSAID.TIPOVENDA <> 'SE'
                GROUP BY PCNFSAID.DTSAIDA,
                         NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                         PCMOV.CODPROD
                  ---------------------------------------------------------
                  UNION ALL
                  ---------------------------------------------------------
                  /* Notas Fiscais de Saída Canceladas */
                  SELECT TRUNC(PCMOV.DTCANCEL) DTMOV
                        ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                        ,PCMOV.CODPROD
                        ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'S', (ROUND(PCMOV.QTCONT, '6') * (-1)), 0)), 0) SALDO
                    FROM PCNFSAID
                        ,PCMOV
                        ,PCMOVCOMPLE
                   WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                     AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                     AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                     AND TRUNC(PCMOV.DTCANCEL) BETWEEN vdDTINICIAL AND vdDTFINAL
                     AND (NVL(PCNFSAID.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 14) OR (NVL(PCNFSAID.CONDVENDA, 0) = 7 AND NVL(PCNFSAID.FORNECENTREGA, 'N') = 'S'))
                     AND PCMOV.DTCANCEL IS NOT NULL
                     AND PCMOV.QTCONT < 0
                     AND NVL(PCMOVCOMPLE.MOVEST,'S') = 'S'
                     AND NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL)
                     AND PCMOV.CODFISCAL NOT IN (5929, 6929)
                     AND PCNFSAID.ESPECIE IN ('NF', 'CF','NP', 'CP','NE')
                     AND PCMOV.STATUS IN ('A', 'AB')
                     AND NVL(PCNFSAID.FINALIDADENFE, 'O') <> 'C'
                     AND PCNFSAID.TIPOVENDA <> 'SE'
                GROUP BY PCMOV.DTCANCEL,
                         NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                         PCMOV.CODPROD
                  ---------------------------------------------------------
                  UNION ALL
                  ---------------------------------------------------------
                  /* Movimentações sem NFs */
                  SELECT PCMOV.DTMOV
                        ,NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) CODFILIAL
                        ,PCMOV.CODPROD
                        ,NVL(SUM(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', ROUND(PCMOV.QTCONT, 6), (ROUND(PCMOV.QTCONT, 6) * (-1)))), 0) QTENTRADA
                    FROM PCMOV
                   WHERE PCMOV.DTMOV BETWEEN vdDTINICIAL AND vdDTFINAL
                     AND PCMOV.CODOPER IN ('EP', 'SP', 'EA', 'SA', 'EX', 'RA')
                     AND NOT EXISTS (SELECT 1
                                       FROM PCNFSAID
                                      WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                        AND NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL)
                                        AND PCNFSAID.DTSAIDA = PCMOV.DTMOV
                                        AND PCNFSAID.ESPECIE IN ('NF', 'CF','NP', 'CP','NE')
                                        AND PCNFSAID.VLTOTAL > 0)
                     AND PCMOV.STATUS IN ('A', 'AB')
                GROUP BY PCMOV.DTMOV,
                         NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL),
                         PCMOV.CODPROD) DADOS
       GROUP BY DADOS.DTMOV
               ,DADOS.CODFILIAL
               ,DADOS.CODPROD);
  
    CURSOR MOV_GERENCIAL (vdDTINICIAL IN DATE
                         ,vdDTFINAL   IN DATE)
      IS
          (SELECT 'GERENCIAL' ID
                 , PCMOV.DTMOV
                 , NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) CODFILIAL
                 , PCMOV.CODPROD
                 ,   NVL
                        (SUM
                            (CASE
                                WHEN (SUBSTR(PCMOV.CODOPER, 1, 1) = 'E') OR(SUBSTR(PCMOV.CODOPER, 1, 1) = 'D')
                                   THEN CASE
                                          WHEN DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0)
                                                    , 0, NVL(PCMOV.QT, 0)
                                                    , PCMOVCOMPLE.QTRETORNOTV13) > 0
                                             THEN DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0)
                                                       , 0, NVL(PCMOV.QT, 0)
                                                       , PCMOVCOMPLE.QTRETORNOTV13)
                                       END
                                ELSE CASE
                                WHEN DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0)
                                          , 0, NVL(PCMOV.QT, 0)
                                          , PCMOVCOMPLE.QTRETORNOTV13) < 0
                                   THEN DECODE(NVL(PCMOVCOMPLE.QTRETORNOTV13, 0)
                                             , 0,(NVL(PCMOV.QT, 0) *(-1))
                       
                                             , (PCMOVCOMPLE.QTRETORNOTV13 *(-1)))
                             END
                             END)
                          , 0)
                   + NVL(SUM(CASE
                                WHEN (SUBSTR(PCMOV.CODOPER, 1, 1) = 'S') OR(SUBSTR(PCMOV.CODOPER, 1, 1) = 'R')
                                   THEN CASE
                                          WHEN(PCMOV.QT > 0)
                                             THEN NVL(PCMOV.QT *(-1), 0)
                                       END
                                ELSE CASE
                                WHEN(PCMOV.QT < 0)
                                   THEN NVL(PCMOV.QT, 0)
                             END
                             END)
                       , 0) SALDO
              FROM PCMOV
                 , PCMOVCOMPLE
             WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
               AND PCMOV.DTMOV BETWEEN vdDTINICIAL AND vdDTFINAL
               AND ABS(NVL(PCMOV.QT, 0)) > 0
               AND PCMOV.STATUS IN('B', 'AB')
               AND (   NOT EXISTS(
                          SELECT NUMPED
                            FROM PCPEDC
                           WHERE NUMPED = DECODE(PCMOV.CODOPER, 'EP', -1, 'SP', -1, PCMOV.NUMPED)
                             AND CONDVENDA = 7)
                    OR (SUBSTR(PCMOV.CODOPER, 1, 1) = 'E'))
               AND NOT(PCMOV.CODOPER IN('EA', 'SA') AND PCMOVCOMPLE.NUMINVENT IS NOT NULL)
               AND NVL(PCMOVCOMPLE.MOVEST, 'S') = 'S'
               AND NOT(    FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('DEVOLVESIMPLESREMTV13TOTAL'
                                                            , PCMOV.CODFILIAL
                                                            , 'N') = 'S'
                       AND PCMOV.ROTINACAD LIKE '%1332%'
                       AND NVL(PCMOVCOMPLE.QTRETORNOTV13, 0) = 0)
               AND NOT EXISTS(
                         SELECT NUMNOTA
                           FROM PCNFSAID
                          WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                AND SITUACAONFE IN(110, 205, 301, 302, 303))
               AND NOT EXISTS(
                      SELECT DISTINCT (PCNFSAID.NUMTRANSVENDA)
                                 FROM PCNFSAID
                                    , PCPRODUT
                                WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                  AND PCNFSAID.CODFILIAL = PCMOV.CODFILIAL
                                  AND PCMOV.CODOPER = 'S'
                                  AND PCNFSAID.CONDVENDA IN(4, 7, 14)
                                  AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                  AND PCPRODUT.TIPOMERC = 'CB')
          GROUP BY PCMOV.DTMOV
                 , NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)
                 , PCMOV.CODPROD);
    -- Variáveis internas
    TYPE TROW_HISTEST IS TABLE OF HISTEST_BASE%ROWTYPE;
    TYPE TROW_MOV_CONTABIL IS TABLE OF MOV_CONTABIL%ROWTYPE;
    TYPE TROW_MOV_GERENCIAL IS TABLE OF MOV_GERENCIAL%ROWTYPE;
  
    vtREGISTROS     TROW_HISTEST;
    vtMOV_GERENCIAL TROW_MOV_GERENCIAL;
    vtMOV_CONTABIL  TROW_MOV_CONTABIL;
  
  BEGIN
    FOR DADOS IN (SELECT DISTINCT H.CODFILIAL
                    FROM PCHISTEST H
                   WHERE H.DATA = pdDATA_BASE
                     AND (pscodfilial IS NULL OR H.CODFILIAL = pscodfilial))
    LOOP
      -- Aqui tem que ter um laço para pegar as filiais automaticamente
      DELETE
        FROM PCHISTEST
       WHERE CODFILIAL = DADOS.CODFILIAL
         AND DATA BETWEEN pdDTINICIAL AND pdDTFINAL;
  
      FOR DIAS IN (SELECT TO_DATE(pdDTINICIAL,'DD-MM-RRRR')+(LEVEL-1) DIA
                    FROM DUAL
                 CONNECT BY LEVEL <= ((TO_DATE(pdDTFINAL,'DD-MM-RRRR')-TO_DATE(pdDTINICIAL,'DD-MM-RRRR')) + 1))
      LOOP
        -- Abrindo curso
        OPEN HISTEST_BASE (DADOS.CODFILIAL,pdDATA_BASE);
        LOOP
          FETCH HISTEST_BASE BULK COLLECT INTO vtREGISTROS LIMIT 10000;
            -- Insira os dados do cursor na PCHISTEST
            FOR I IN 1 ..vtREGISTROS.COUNT
      LOOP
        vtREGISTROS(I).DATA := DIAS.DIA;
              -- Confirmando os registros
              INSERT INTO PCHISTEST VALUES vtREGISTROS(I);
              COMMIT;
      END LOOP;
          EXIT WHEN HISTEST_BASE%NOTFOUND;
        -- Cursor
        END LOOP;
        -- Fechar cursor
        CLOSE HISTEST_BASE;
      END LOOP;
      -- Aqui tem que ter um laço para pegar as filiais automaticamente
      PKG_ANALISAR_ESTOQUE.PRC_LIMPAR_SALDOS;
      -- Gerar dias
      PKG_ANALISAR_ESTOQUE.PRC_INS_LISTA_DIAS (pdDTINICIAL,pdDTFINAL);
      -- Abrindo curso
      OPEN MOV_CONTABIL (pdDTINICIAL,pdDTFINAL);
      LOOP
        FETCH MOV_CONTABIL BULK COLLECT INTO vtMOV_CONTABIL LIMIT 10000;
          -- Insira os dados do cursor na PCHISTEST
          FORALL I IN 1 ..vtMOV_CONTABIL.COUNT
            -- Confirmando os registros
            INSERT INTO PCSALDOMOVCONTABEIS VALUES vtMOV_CONTABIL(I);
        EXIT WHEN MOV_CONTABIL%NOTFOUND;
      -- Cursor
      END LOOP;
      -- Fechar cursor
      CLOSE MOV_CONTABIL;

      -- Abrindo curso
      OPEN MOV_GERENCIAL (pdDTINICIAL,pdDTFINAL);
      LOOP
        FETCH MOV_GERENCIAL BULK COLLECT INTO vtMOV_GERENCIAL LIMIT 10000;
          -- Insira os dados do cursor na PCHISTEST
          FORALL I IN 1 ..vtMOV_GERENCIAL.COUNT
            -- Confirmando os registros
            INSERT INTO PCSALDOMOVGERENCIAIS VALUES vtMOV_GERENCIAL(I);
        EXIT WHEN MOV_GERENCIAL%NOTFOUND;
      -- Cursor
      END LOOP;
      -- Fechar cursor
      CLOSE MOV_GERENCIAL;
  
      FOR DADOS IN  (SELECT  DADOS.DTMOV
                            ,DADOS.ID
                            ,DADOS.CODFILIAL
                            ,DADOS.CODPROD
                            ,NVL(DADOS.SALDO,0) SALDO
                       FROM (SELECT PCSALDOMOVGERENCIAIS.ID
                                   ,PCSALDOMOVGERENCIAIS.DTMOV
                                   ,PCSALDOMOVGERENCIAIS.CODFILIAL
                                   ,PCSALDOMOVGERENCIAIS.CODPROD
                                   ,PCSALDOMOVGERENCIAIS.SALDO
                               FROM PCSALDOMOVGERENCIAIS
                             UNION ALL
                             SELECT PCSALDOMOVCONTABEIS.ID
                                   ,PCSALDOMOVCONTABEIS.DTMOV
                                   ,PCSALDOMOVCONTABEIS.CODFILIAL
                                   ,PCSALDOMOVCONTABEIS.CODPROD
                                   ,PCSALDOMOVCONTABEIS.SALDO
                               FROM PCSALDOMOVCONTABEIS) DADOS
                       WHERE (pscodfilial IS NULL OR DADOS.CODFILIAL = pscodfilial)
                    ORDER BY DADOS.DTMOV
                            ,DADOS.ID
                            ,DADOS.CODFILIAL
                            ,DADOS.CODPROD)
      LOOP
  
        IF (DADOS.ID = 'CONTABIL') THEN
          UPDATE PCHISTEST H
             SET H.QTEST = H.QTEST + DADOS.SALDO
           WHERE H.CODFILIAL = DADOS.CODFILIAL
             AND H.CODPROD   = DADOS.CODPROD
             AND H.DATA      = DADOS.DTMOV;
  
        ELSIF (DADOS.ID = 'GERENCIAL') THEN
          UPDATE PCHISTEST H
             SET H.QTESTGER = H.QTESTGER + DADOS.SALDO
           WHERE H.CODFILIAL = DADOS.CODFILIAL
             AND H.CODPROD   = DADOS.CODPROD
             AND H.DATA      = DADOS.DTMOV;
        END IF;
  
      END LOOP;
    END LOOP;
    -- Confirmando registros
    COMMIT;
  -- Procedure
  END;
-- Pakager PKG_ANALISAR_ESTOQUE
END PKG_ANALISAR_ESTOQUE;
