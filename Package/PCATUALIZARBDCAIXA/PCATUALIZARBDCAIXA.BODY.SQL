

CREATE OR REPLACE PACKAGE BODY PCATUALIZARBDCAIXA
IS
/*------------------------------------------------------------------------------------
| Procedimento: pCriarDatabaseLink
| Objetivo    : Criar database link a partir das informações passadas como parâmetro.
| Parametros  :
|   p_SeqCaixa: Número de sequência do caixa que fará parte do nome do database link.
|   p_StringConCaixa: String de conexão para o banco de dados do Caixa.
|                   Formato da String de Conexão=
|                   (description=(address=(protocol=tcp)(host=IP_CAIXA)(port=1521))(connect_data=(service_name=XE)))
|   p_Usuario: Usuário do banco de dados do caixa.
|   p_Senha: Senha do usuário do banco de dados do caixa.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------  -----------   ------------------------------------------------------
| Augusto Cesar  18/07/2006    Criação da procedure para criar o database link.
|***********************************************************************************/
   PROCEDURE pcriardatabaselink (
      p_seqcaixa         IN   pccaixa.numcaixa%TYPE,
      p_stringconcaixa   IN   VARCHAR2,
      p_usuario          IN   VARCHAR2,
      p_senha            IN   VARCHAR2
   )
   AS
      v_sql   VARCHAR2 (300);
   BEGIN
      v_sql :=
            'CREATE DATABASE LINK DBLCAIXA'
         || p_seqcaixa
         || ' CONNECT TO '
         || p_usuario
         || ' IDENTIFIED BY '
         || p_senha
         || ' USING '''
         || p_stringconcaixa
         || '''';

      EXECUTE IMMEDIATE v_sql;
   END pcriardatabaselink;

/*------------------------------------------------------------------------------------
| Procedimento: pApagarDatabaseLink
| Objetivo    : Apagar database link a partir das informações passadas como parâmetro.
| Parametros  :
|   p_SeqCaixa: Número de sequência do caixa que fará parte do nome do database link
|               que será apagado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------  -----------   ------------------------------------------------------
| Augusto Cesar  18/07/2006    Criação da procedure para criar o database link.
|***********************************************************************************/
   PROCEDURE papagardatabaselink (p_seqcaixa IN pccaixa.numcaixa%TYPE)
   AS
      v_sql   VARCHAR2 (300);
   BEGIN
      v_sql := 'DROP DATABASE LINK DBLCAIXA' || p_seqcaixa;

      EXECUTE IMMEDIATE v_sql;
   END papagardatabaselink;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCaixa
| Objetivo    : Atualizar tabela PCCAIXA
| Parametros  :
|   p_DbLink  : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar    18/07/2006    Criação da procedure para atualizar a tabela PCCAIXA.
| Juliana Teixeira 20/11/2006    Acrescentado campo PCCAIXA.MSGCUPOMFISCAL.
| Juliana Teixeira 20/11/2006    Retirada validação do campo PCTABPR.PVENDA para que as embalagens
seja exportadas mesmo não tenho preço cadastrado no pctabpr, pois a maioria dos clientes do auto-
serviço utilizam preço por embalagem não por produto. Contendo essa validação o cadastro de emba-
lagens estava imcompleto.
| Juliana Teixeira 22/11/2006    Acrescentado campo PCCAIXA.TIPOBALANCA.
| Juliana Teixeira 04/06/2007    Acrescentado campo PCCAIXA.NUMCAIXAFISCAL.
| Juliana Teixeira 08/07/2007    Acrescentado campo PCCAIXA.MODELO.
| Juliana Teixeira 03/10/2007    Acrescentado campos contendo dados de configuração do novo TEF:
|                                (IPSERVIDORSITEF, CODEMPRESASITEF, TERMINALSITEF)
| Juliana Teixeira 16/09/2008    Acrescentado campo PCCAIXA.SALTARLINHATEF.
| Juliana Teixeira 22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira 25/03/2009    Tarefa N.80127 - Acrescentados campos para configurar msg tef e leitor serial;
|***********************************************************************************/
   PROCEDURE patualizarcaixa (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCCAIXA@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCCAIXA@'
         || p_dblink
         || '(NUMCAIXA,DESCRICAO,POSICAO,CODFUNCCX,TIPOIMPRESSORA'
         || ',PORTAIMPRESSORA,NUMSERIEEQUIP,PORTALEITOR,VERSAOIMPRESSORA'
         || ',PERMITEABRIRGAVETA,GAVETAACOPLADA,TIPOTEF,DTINICIO,DTFIM'
         || ',VALIDACH,NUMREGIAO,CODFILIAL,TIPOIMPRESSORACHEQUE'
         || ',VERSAOIMPRESSORACHEQUE,PORTAIMPRESSORACHEQUE,PORTALEITORCH'
         || ',NUMCUPOMABERTO,NUMCUPOMFECHADO,DEGUSTACAO,MSGCUPOMFISCAL'
         || ',TIPOBALANCA,NUMCAIXAFISCAL,MODELO,IPSERVIDORSITEF,CODEMPRESASITEF'
         || ',TERMINALSITEF, SALTARLINHATEF, DIRATUALIZACAO, BITSPORSEGUNDOLEITOR'
         || ',BITSDEDADOSLEITOR, PARIDADELEITOR, RESPSITEFTECLADO, TIPOTECLADO,CODBANCO,USAINDICEECF ) '
         || 'SELECT NUMCAIXA, DESCRICAO, POSICAO, CODFUNCCX '
         || ',TIPOIMPRESSORA,PORTAIMPRESSORA,NUMSERIEEQUIP '
         || ',PORTALEITOR, VERSAOIMPRESSORA,PERMITEABRIRGAVETA '
         || ',GAVETAACOPLADA, TIPOTEF, DTINICIO, DTFIM '
         || ',VALIDACH,NUMREGIAO, CODFILIAL,TIPOIMPRESSORACHEQUE '
         || ',VERSAOIMPRESSORACHEQUE,PORTAIMPRESSORACHEQUE,PORTALEITORCH '
         || ',NUMCUPOMABERTO, NUMCUPOMFECHADO,DEGUSTACAO,MSGCUPOMFISCAL '
         || ',TIPOBALANCA,NUMCAIXAFISCAL,MODELO,IPSERVIDORSITEF '
         || ',CODEMPRESASITEF,TERMINALSITEF, SALTARLINHATEF, DIRATUALIZACAO '
         || ',BITSPORSEGUNDOLEITOR,BITSDEDADOSLEITOR, PARIDADELEITOR, RESPSITEFTECLADO, TIPOTECLADO,CODBANCO,USAINDICEECF '
         || 'FROM PCCAIXA';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarcaixa;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCliente
| Objetivo    : Atualizar a tabela PCCLIENT.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_DtAtualizacaoBD : Data utilizada para informar a partir de qual data a tabela
|                       PCCLIENT será atualizada.
|   p_TipoAtualizacao : Tipo de atualização: P = Parcial ou T = Total.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     18/07/2006    Criação da procedure para atualizar a tabela PCCLIENT.
| -------------    -----------   ------------------------------------------------------
| Juliana Teixeira  22/01/2007    Tarefa N.37918 Acrescentada coluna aceitavendafracao
                                  para ser utilizada no pcaux2075 corretamente.
| Juliana Teixeira  21/01/2008    Tarefa N.56819 Acrescentada coluna codusur1;
| Juliana Teixeira  09/06/2008    Tarefa N.63756/62911 - Processo exportando codigo da
|                                 cidade e email para rotina 2075;
| Juliana Teixeira  31/07/2008    Tarefa N.66646 Acrescentada coluna vip para ser exibida
|                                 pesquisa de clientes da rotina 2075;
| Juliana Teixeira  02/09/2008    Tarefa N.68356-Alterada carga parcial para retirar laco e evitar melhor performance.
| Juliana Teixeira  17/09/2008    Tarefa N.69098-Ajuste na carga parcial dos dados;
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  20/04/2009    Tarefa N.81068 - Acrescentada gravaco do campo pcclient.dtvalidadeconv;
|***********************************************************************************/
   PROCEDURE patualizarcliente (
      p_dblink            IN   VARCHAR2,
      p_datainicial       IN   pcclient.dtcadastro%TYPE DEFAULT NULL,
      p_datafinal         IN   pcclient.dtcadastro%TYPE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T'
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      IF p_tipoatualizacao = 'T'
      THEN
         v_sql := 'DELETE FROM PCCLIENT@' || p_dblink;

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCCLIENT@'
            || p_dblink
            || '(CODCLI, CLIENTE, CODCOB, LIMCRED, BLOQUEIO,CGCENT, ENDERENT, DTCADASTRO, DTEXCLUSAO '
            || ',BAIRROENT, MUNICENT, ESTENT, CODPRACA, CEPENT, CODPLPAG, CNPJ '
            || ',PLPAGNEG, TELENT, CODATV1, CLIENTEFONTEST, CALCULAST, IEENT '
            || ',TIPOFJ, ISENTOICMS, CONSUMIDORFINAL, UTILIZAIESIMPLIFICADA '
            || ',TIPOEMPRESA, VLPEDPENDENTE, ACEITACHTERCEIROS, ACEITAVENDAFRACAO '
            || ',CODUSUR1, CODCIDADE, EMAIL, VIP, CONTRIBUINTE, USAIVAFONTEDIFERENCIADO, IVAFONTE, DTVALIDADECONV, RG, SENHACONVECF) '
            || 'SELECT CODCLI, CLIENTE, CODCOB, LIMCRED '
            || ',BLOQUEIO,CGCENT, ENDERENT, DTCADASTRO, DTEXCLUSAO, BAIRROENT '
            || ',MUNICENT, ESTENT, CODPRACA, CEPENT '
            || ',CODPLPAG, REPLACE(REPLACE(REPLACE(REPLACE(CGCENT,''.'',''''),'','',''''),''-'',''''),''/'','''') '
            || ',PLPAGNEG ,TELENT, CODATV1,CLIENTEFONTEST, CALCULAST '
            || ',IEENT, TIPOFJ, ISENTOICMS, CONSUMIDORFINAL '
            || ',UTILIZAIESIMPLIFICADA,TIPOEMPRESA, 0 '
            || ',ACEITACHTERCEIROS, ACEITAVENDAFRACAO, CODUSUR1, CODCIDADE, EMAIL, VIP, CONTRIBUINTE, USAIVAFONTEDIFERENCIADO, IVAFONTE, DTVALIDADECONV, RG, SENHACONVECF FROM PCCLIENT ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO pcclient@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT codcli, cliente, codcob, limcred, bloqueio, telent, plpagneg, '
            || ' codatv1, cgcent, enderent, bairroent, municent, estent, '
            || '              codpraca, cepent, codplpag, clientefontest, calculast, ieent, '
            || '           tipofj, isentoicms, consumidorfinal, utilizaiesimplificada, '
            || '        tipoempresa, aceitachterceiros, dtcadastro, dtexclusao, dtultalter, '
            || '     dtultaltercliesp, dtexclusao, aceitavendafracao, codusur1, '
            || '  codcidade, email, dtvalidadeconv, rg, SENHACONVECF '
            || '            FROM pcclient '
            || '        WHERE (pcclient.dtcadastro '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                        || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '           OR (pcclient.dtultalter '
            || '               BETWEEN TRUNC (TO_DATE ( '''||  TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                   || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'') ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || '                                    || '' 23:59:59'',''DD/MM/RRRR HH24:MI:SS'' ) ) ) '

            || '           OR (TRUNC(pcclient.dtultaltersrvprc) '
            || '               BETWEEN TRUNC (TO_DATE ( '''||  TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                   || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'') ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || '                                    || '' 23:59:59'',''DD/MM/RRRR HH24:MI:SS'' ) ) ) '

            || '           OR (pcclient.dtexclusao '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                           || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'' ) ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || ' || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS''))) )) tabela_origem '
            || '    ON (tabela_origem.codcli = tabela_destino.codcli) '
            || '    WHEN MATCHED THEN '
            || '       UPDATE '
            || '          SET tabela_destino.cliente = tabela_origem.cliente, '
            || '              tabela_destino.codcob = tabela_origem.codcob, '
            || '              tabela_destino.limcred = tabela_origem.limcred, '
            || '              tabela_destino.bloqueio = tabela_origem.bloqueio, '
            || '              tabela_destino.telent = tabela_origem.telent, '
            || '              tabela_destino.plpagneg = tabela_origem.plpagneg, '
            || '              tabela_destino.codatv1 = tabela_origem.codatv1, '
            || '              tabela_destino.cgcent = tabela_origem.cgcent, '
            || '              tabela_destino.enderent = tabela_origem.enderent, '
            || '              tabela_destino.bairroent = tabela_origem.bairroent, '
            || '              tabela_destino.municent = tabela_origem.municent, '
            || '              tabela_destino.estent = tabela_origem.estent, '
            || '          tabela_destino.codpraca = tabela_origem.codpraca, '
            || '      tabela_destino.cepent = tabela_origem.cepent, '
            || '              tabela_destino.codplpag = tabela_origem.codplpag, '
            || '          tabela_destino.clientefontest = tabela_origem.clientefontest, '
            || '      tabela_destino.calculast = tabela_origem.calculast, '
            || '  tabela_destino.ieent = tabela_origem.ieent, '
            || '              tabela_destino.tipofj = tabela_origem.tipofj, '
            || '          tabela_destino.isentoicms = tabela_origem.isentoicms, '
            || '      tabela_destino.consumidorfinal = tabela_origem.consumidorfinal, '
            || '              tabela_destino.utilizaiesimplificada = tabela_origem.utilizaiesimplificada, '
            || '          tabela_destino.tipoempresa = tabela_origem.tipoempresa, '
            || '      tabela_destino.aceitachterceiros = tabela_origem.aceitachterceiros, '
            || '              tabela_destino.dtcadastro = tabela_origem.dtcadastro, '
            || '              tabela_destino.dtexclusao = tabela_origem.dtexclusao, '
            || '          tabela_destino.dtultalter = tabela_origem.dtultalter, '
            || '      tabela_destino.dtultaltercliesp = tabela_origem.dtultaltercliesp, '
            || '  tabela_destino.dtexclusao = tabela_origem.dtexclusao, '
            || '              tabela_destino.aceitavendafracao = tabela_origem.aceitavendafracao, '
            || '          tabela_destino.codusur1 = tabela_origem.codusur1, '
            || '      tabela_destino.codcidade = tabela_origem.codcidade, '
            || '  tabela_destino.email = tabela_origem.email, '
            || '  tabela_destino.dtvalidadeconv = tabela_origem.dtvalidadeconv, '
            || '  tabela_destino.rg = tabela_origem.rg, '
            || '  tabela_destino.SENHACONVECF = tabela_origem.SENHACONVECF '
            || '    WHEN NOT MATCHED THEN '
            || '   INSERT (codcli, cliente, codcob, limcred, bloqueio, telent, plpagneg, '
            || '       codatv1, cgcent, enderent, bairroent, municent, estent, '
            || '               codpraca, cepent, codplpag, clientefontest, calculast, ieent, '
            || '           tipofj, isentoicms, consumidorfinal, utilizaiesimplificada, '
            || '       tipoempresa, aceitachterceiros, dtcadastro, dtexclusao, dtultalter, '
            || '               dtultaltercliesp, dtexclusao, aceitavendafracao, codusur1, '
            || '           codcidade, email, dtvalidadeconv, rg, SENHACONVECF) '
            || '       VALUES (tabela_origem.codcli, tabela_origem.cliente, '
            || '           tabela_origem.codcob, tabela_origem.limcred, '
            || '       tabela_origem.bloqueio, tabela_origem.telent, '
            || '   tabela_origem.plpagneg, tabela_origem.codatv1, '
            || '               tabela_origem.cgcent, tabela_origem.enderent,  '
            || '           tabela_origem.bairroent, tabela_origem.municent, '
            || '       tabela_origem.estent, tabela_origem.codpraca, '
            || '   tabela_origem.cepent, tabela_origem.codplpag, '
            || '               tabela_origem.clientefontest, tabela_origem.calculast, '
            || '           tabela_origem.ieent, tabela_origem.tipofj, '
            || '       tabela_origem.isentoicms, tabela_origem.consumidorfinal, '
            || '   tabela_origem.utilizaiesimplificada, tabela_origem.tipoempresa, '
            || '               tabela_origem.aceitachterceiros, tabela_origem.dtcadastro, '
            || '          tabela_origem.dtexclusao, tabela_origem.dtultalter, tabela_origem.dtultaltercliesp, '
            || '       tabela_origem.dtexclusao, tabela_origem.aceitavendafracao, '
            || '   tabela_origem.codusur1, tabela_origem.codcidade, '
            || '               tabela_origem.email, tabela_origem.dtvalidadeconv, tabela_origem.rg, tabela_origem.SENHACONVECF)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'DELETE FROM PCCLIENT@'
            || p_dblink
            || ' WHERE DTEXCLUSAO IS NOT NULL';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizarcliente;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCliente
| Objetivo    : Atualizar a tabela PCCLIENT. Esta atualição será disparada por um job
|               que obterá os registros através da tabela de fila de atualização PCFILAATTUALIZACX.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_IdSequencial : Identificar sequencial do registros que está armazenado na
|                    tabela PCFILAATTUALIZACX
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     13/09/2006    Criação da procedure para atualizar a tabela PCCLIENT.
| -------------    -----------   ------------------------------------------------------
| Juliana Teixeira  22/01/2007    Tarefa N.37918 Acrescentada coluna aceitavendafracao
|                                 para ser utilizada no pcaux2075 corretamente.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarcliente (
      p_dblink         IN   VARCHAR2,
      p_idsequencial   IN   pcclient.numseqatu%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      FOR c_cliente IN
         (SELECT codcli, cliente, codcob, limcred, bloqueio, telent,
                 plpagneg, codatv1, cgcent, enderent, bairroent, municent,
                 estent, codpraca, cepent, codplpag, clientefontest,
                 calculast, ieent, tipofj, isentoicms, consumidorfinal,
                 utilizaiesimplificada, tipoempresa, aceitachterceiros,
                 REPLACE (REPLACE (REPLACE (REPLACE (cgcent, '.', ''), ',',
                                            ''),
                                   '-',
                                   ''
                                  ),
                          '/',
                          ''
                         ) cnpj,
                 dtcadastro, dtexclusao, dtultalter, dtultaltercliesp, 
                 aceitavendafracao, dtvalidadeconv, rg, SENHACONVECF
            FROM pcclient
           WHERE numseqatu = p_idsequencial)
      LOOP
         v_sql :=
               'SELECT COUNT(*) CONTADOR '
            || 'FROM PCCLIENT@'
            || p_dblink
            || ' WHERE PCCLIENT.CODCLI = :CODCLI '
            || 'AND ROWNUM = 1';

         EXECUTE IMMEDIATE v_sql
                      INTO v_totalregistros
                     USING c_cliente.codcli;

         -- Verificar se o cliente está cadastrado no caixa.
         IF v_totalregistros = 0
         THEN
            -- Caso o cliente não esteja cadastrado no caixa e não foi excluído,
            -- deverá ser incluído no caixa.
            v_sql :=
                  'INSERT INTO PCCLIENT@'
               || p_dblink
               || '(CODCLI, CLIENTE, CODCOB, LIMCRED, BLOQUEIO '
               || ',CGCENT, ENDERENT, BAIRROENT, MUNICENT, ESTENT '
               || ',CODPRACA, CEPENT,CODPLPAG, CNPJ, PLPAGNEG '
               || ',TELENT, CODATV1, CLIENTEFONTEST, CALCULAST '
               || ',IEENT, TIPOFJ, ISENTOICMS, CONSUMIDORFINAL '
               || ',UTILIZAIESIMPLIFICADA, TIPOEMPRESA, VLPEDPENDENTE '
               || ',ACEITACHTERCEIROS, ACEITAVENDAFRACAO, DTVALIDADECONV, RG, SENHACONVECF)  '
               || 'VALUES (:CODCLI, :CLIENTE, :CODCOB, :LIMCRED, :BLOQUEIO '
               || ',:CGCENT, :ENDERENT, :BAIRROENT, :MUNICENT, :ESTENT '
               || ',:CODPRACA,:CEPENT, :CODPLPAG, :CNPJ, :PLPAGNEG '
               || ',:TELENT, :CODATV1, :CLIENTEFONTEST, :CALCULAST '
               || ',:IEENT, :TIPOFJ, :ISENTOICMS, :CONSUMIDORFINAL '
               || ',:UTILIZAIESIMPLIFICADA, :TIPOEMPRESA, :VLPEDPENDENTE '
               || ', :ACEITACHTERCEIROS, :ACEITAVENDAFRACAO, :DTVALIDADECONV, :RG, :SENHACONVECF)';

            EXECUTE IMMEDIATE v_sql
                        USING c_cliente.codcli,
                              c_cliente.cliente,
                              c_cliente.codcob,
                              c_cliente.limcred,
                              c_cliente.bloqueio,
                              c_cliente.cgcent,
                              c_cliente.enderent,
                              c_cliente.bairroent,
                              c_cliente.municent,
                              c_cliente.estent,
                              c_cliente.codpraca,
                              c_cliente.cepent,
                              c_cliente.codplpag,
                              c_cliente.cnpj,
                              c_cliente.plpagneg,
                              c_cliente.telent,
                              c_cliente.codatv1,
                              c_cliente.clientefontest,
                              c_cliente.calculast,
                              c_cliente.ieent,
                              c_cliente.tipofj,
                              c_cliente.isentoicms,
                              c_cliente.consumidorfinal,
                              c_cliente.utilizaiesimplificada,
                              c_cliente.tipoempresa,
                              0,
                              c_cliente.aceitachterceiros,
                              c_cliente.aceitavendafracao,
                              c_cliente.dtvalidadeconv,
                              c_cliente.rg,
                              c_cliente.senhaconvecf;
         ELSE
            v_sql :=
                  'UPDATE PCCLIENT@'
               || p_dblink
               || ' SET CLIENTE = :CLIENTE, CODCOB = :CODCOB, LIMCRED = :LIMCRED '
               || ',BLOQUEIO = :BLOQUEIO, CGCENT = :CGCENT, ENDERENT = :ENDERENT '
               || ',BAIRROENT = :BAIRROENT, MUNICENT = :MUNICENT, ESTENT = :ESTENT '
               || ',CODPRACA = :CODPRACA, CEPENT = :CEPENT, CODPLPAG = :CODPLPAG '
               || ',CNPJ = :CNPJ, PLPAGNEG = :PLPAGNEG, TELENT = :TELENT, CODATV1 = :CODATV1 '
               || ',CLIENTEFONTEST = :CLIENTEFONTEST,CALCULAST = :CALCULAST, IEENT = :IEENT '
               || ',TIPOFJ = :TIPOFJ, ISENTOICMS = :ISENTOICMS, CONSUMIDORFINAL = :CONSUMIDORFINAL '
               || ',UTILIZAIESIMPLIFICADA = :UTILIZAIESIMPLIFICADA, TIPOEMPRESA = :TIPOEMPRESA '
               || ',VLPEDPENDENTE = :VLPEDPENDENTE, ACEITACHTERCEIROS = :ACEITACHTERCEIROS '
               || ',ACEITAVENDAFRACAO = :ACEITAVENDAFRACAO, DTVALIDADECONV = :DTVALIDADECONV, RG = :RG, SENHACONVECF = :SENHACONVECF'
               || 'WHERE CODCLI = :CODCLI ';

            EXECUTE IMMEDIATE v_sql
                        USING c_cliente.cliente,
                              c_cliente.codcob,
                              c_cliente.limcred,
                              c_cliente.bloqueio,
                              c_cliente.cgcent,
                              c_cliente.enderent,
                              c_cliente.bairroent,
                              c_cliente.municent,
                              c_cliente.estent,
                              c_cliente.codpraca,
                              c_cliente.cepent,
                              c_cliente.codplpag,
                              c_cliente.cnpj,
                              c_cliente.plpagneg,
                              c_cliente.telent,
                              c_cliente.codatv1,
                              c_cliente.clientefontest,
                              c_cliente.calculast,
                              c_cliente.ieent,
                              c_cliente.tipofj,
                              c_cliente.isentoicms,
                              c_cliente.consumidorfinal,
                              c_cliente.utilizaiesimplificada,
                              c_cliente.tipoempresa,
                              0,
                              c_cliente.aceitachterceiros,
                              c_cliente.codcli,
                              c_cliente.aceitavendafracao,
                              c_cliente.dtvalidadeconv,
                              c_cliente.rg,
                              c_cliente.SENHACONVECF;
         END IF;
      END LOOP;
      COMMIT;
   END patualizarcliente;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCidade
| Objetivo    : Atualizar a tabela PCCIDADE
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data         Comentário
| -------------     -----------  ------------------------------------------------------
| Juliana Teixeira  09/06/2008   Tarefa N.63756/62911-Exportação de dados da cidade para
|                                ser utilizado na rotina 2075 na tela de consumidor final;
| Juliana Teixeira 22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarcidade (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCCIDADE@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCCIDADE@'
         || p_dblink
         || '(CODCIDADE, NOMECIDADE, CODIBGE, UF) '
         || 'SELECT CODCIDADE, NOMECIDADE, CODIBGE, UF'
         || ' FROM PCCIDADE';
      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarcidade;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCobranca
| Objetivo    : Atualizar a tabela PCCOB
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar     19/07/2006    Criação da procedure para atualizar a tabela PCCOB.
| Juliana Teixeira  20/12/2007    Tarefa N.55465-Acrescentado campo exportarecf para enviar
|                                 apenas algumas cobranças para o 2075.
| Juliana Teixeira  16/05/2008    Tarefa N.57533-Acrescentado campo nivelvenda;
| Joata Pinheiro    24/06/2008    Tarefa N.64824 - Gravação dos campos CODOPERADORACARTAO, TIPOOPERACAOTEF
|                                                  para serem utilizados no processo de chamada automatica da cobrança tef dll.
| Juliana Teixeira  17/11/2008    Tarefa N.72935-Acrescentado campo prazocc;
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  24/03/2009    Tarefa N.73796-Acrescentado campo PCCOB.NUMMAXPARCELAS;
|***********************************************************************************/
   PROCEDURE patualizarcobranca (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCCOB@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCCOB@'
         || p_dblink
         || '(CODCOB, COBRANCA, CODECF, CARTAO, BOLETO, VALIDALIMCREDECF, EXPORTARECF '
         || ',NIVELVENDA, CODOPERADORACARTAO, TIPOOPERACAOTEF, PRAZOCC, NUMMAXPARCELAS, TIPOPAGTOECF)  '
         || 'SELECT CODCOB, COBRANCA, CODECF, CARTAO, BOLETO, VALIDALIMCREDECF, EXPORTARECF'
         || ',NIVELVENDA, CODOPERADORACARTAO, TIPOOPERACAOTEF, PRAZOCC, NUMMAXPARCELAS, TIPOPAGTOECF '
         || ' FROM PCCOB WHERE EXPORTARECF = ''S'' ';
      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarcobranca;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarMarca
| Objetivo    : Atualizar a tabela PCMARCA
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Juliana Teixeira  30/06/2009    Cliente Sodine - Enviando dados da marca;
|***********************************************************************************/
   PROCEDURE patualizarmarca (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCMARCA@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCMARCA@'
         || p_dblink
         || '(codmarca, marca, ativo)  '
         || 'SELECT codmarca, marca, ativo '
         || ' FROM PCMARCA ';
      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarmarca;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCobranca
| Objetivo    : Atualizar a tabela PCINDICEECF
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Juliana Teixeira  29/04/2009    Tarefa N.82764 - Criada tabela pcindicecf;
|***********************************************************************************/
   PROCEDURE patualizarIndiceEcf (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCINDICEECF@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCINDICEECF@'
         || p_dblink
         || '(NUMCAIXA, INDICE, CODECF)  '
         || 'SELECT NUMCAIXA, INDICE, CODECF FROM PCINDICEECF';
      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarIndiceEcf;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPlanoPagamentoCliente
| Objetivo    : Atualizar a tabela PCPLPAGCLI
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Juliana Teixeira  16/05/2008    Tarefa N.64913 - Criação da tabela para politica de
|                                 tratamento diferenciada na rotina 2075;
| Juliana Teixeira 22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarplanopagtocliente (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCPLPAGCLI@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCPLPAGCLI@'
         || p_dblink
         || '(CODPLPAG, CODCLI)  '
         || 'SELECT PCPLPAGCLI.CODPLPAG, PCPLPAGCLI.CODCLI '
         || ' FROM PCPLPAGCLI, PCPLPAG '
         || ' WHERE PCPLPAGCLI.CODPLPAG = PCPLPAG.CODPLPAG'
         || ' AND PCPLPAG.USAPLPAGAUTOSERVICO = ''S''';
      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarplanopagtocliente;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarTributacaoPorUf
| Objetivo    : Atualizar a tabela PCTABTRIB
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Juliana Teixeira  20/12/2007    Tarefa N.55781-Criação da procedure para atualizar a tabela PCTABTRIB.
| Juliana Teixeira  01/07/2008    Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira  21/10/2008    Tarefa N.71288-Ajuste para melhoria da performance virada Lojas Livia;
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizartributacaoporuf (
      p_dblink      IN   VARCHAR2,
      p_codfilial   IN   VARCHAR2,
      p_codprod     IN   pctabtrib.codprod%TYPE,
      p_datainicial       IN   pctabtrib.dtultalter%TYPE DEFAULT NULL,
      p_datafinal         IN   pctabtrib.dtultalter%TYPE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T'
   )
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      -- Carga Total
      IF p_tipoatualizacao = 'T'
      THEN
        IF (p_codprod = 0)
        THEN
           FOR C_ESTADOS IN (SELECT UFDESTINO FROM PCTABTRIB WHERE CODFILIALNF = p_codfilial GROUP BY UFDESTINO)
           LOOP
              v_sql :=
                   'DELETE FROM PCTABTRIB@'
                || p_dblink
                || ' WHERE PCTABTRIB.CODFILIALNF = :CODFILIAL AND PCTABTRIB.UFDESTINO = :UFDESTINO';

               EXECUTE IMMEDIATE v_sql USING p_codfilial, C_ESTADOS.UFDESTINO;
           END LOOP;

           COMMIT;

           FOR C_ESTADOS IN (SELECT UFDESTINO FROM PCTABTRIB WHERE CODFILIALNF = p_codfilial GROUP BY UFDESTINO)
           LOOP
              v_sql :=
                   'INSERT /*+ APPEND */ INTO PCTABTRIB@'
                || p_dblink
                || '(PCTABTRIB.CODPROD, PCTABTRIB.CODFILIALNF, PCTABTRIB.UFDESTINO, PCTABTRIB.CODST) '
                || 'SELECT PCTABTRIB.CODPROD, PCTABTRIB.CODFILIALNF, PCTABTRIB.UFDESTINO, PCTABTRIB.CODST '
                || ' FROM PCTABTRIB WHERE PCTABTRIB.CODFILIALNF = :CODFILIAL AND PCTABTRIB.UFDESTINO = :UFDESTINO';

               EXECUTE IMMEDIATE v_sql USING p_codfilial, C_ESTADOS.UFDESTINO;
           END LOOP;

           COMMIT;
        ELSE
           v_sql :=
                 'DELETE FROM PCTABTRIB@'
              || p_dblink
              || ' WHERE CODPROD = :CODPROD '
              || ' AND CODFILIALNF = :CODFILIAL';

           EXECUTE IMMEDIATE v_sql USING p_codfilial, p_codprod;

           v_sql :=
                 'INSERT /*+ APPEND */ INTO PCTABTRIB@'
              || p_dblink
              || '(PCTABTRIB.CODPROD, PCTABTRIB.CODFILIALNF, PCTABTRIB.UFDESTINO, PCTABTRIB.CODST) '
              || 'SELECT PCTABTRIB.CODPROD, PCTABTRIB.CODFILIALNF, PCTABTRIB.UFDESTINO, PCTABTRIB.CODST '
              || ' FROM PCTABTRIB WHERE PCTABTRIB.CODFILIALNF = :CODFILIAL'
              || ' AND PCTABTRIB.CODPROD = :CODPROD ';

           EXECUTE IMMEDIATE v_sql USING p_codfilial, p_codprod;

           COMMIT;
        END IF;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO PCTABTRIB@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT CODPROD, CODFILIALNF, UFDESTINO, CODST'
            || ' FROM PCTABTRIB '
            || '        WHERE (    TRUNC(PCTABTRIB.DTULTALTER) '
            || '                   BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                        || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '                              AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || ' )) tabela_origem '
            || ' ON (tabela_origem.CODPROD = tabela_destino.CODPROD AND '
            || '     tabela_origem.UFDESTINO = tabela_destino.UFDESTINO AND '
            || '     tabela_origem.CODFILIALNF = tabela_destino.CODFILIALNF) '
            || ' WHEN MATCHED THEN '
            || '  UPDATE '
            || ' SET tabela_destino.CODST = tabela_origem.CODST '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (CODPROD, CODFILIALNF, UFDESTINO, CODST) '
            || ' VALUES (tabela_origem.CODPROD, tabela_origem.CODFILIALNF, '
            || ' tabela_origem.UFDESTINO, tabela_origem.CODST) ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizartributacaoporuf;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarDescontoQuantidade
| Objetivo    : Atualizar a tabela PCDESCQUANT
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data        Comentário
| -------------     ----------   ------------------------------------------------------
| Juliana Teixeira  11/09/2007   Criação da procedure para atualizar a tabela PCDESCQUANT.
| Juliana Teixeira  01/07/2008   Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizardescontoquantidade (
      p_dblink    IN   VARCHAR2,
      p_codprod   IN   pcdescquant.codprod%TYPE
   )
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      -- Carga Sempre Total
      IF (p_codprod = 0)
      THEN
         v_sql := 'DELETE FROM PCDESCQUANT@' || p_dblink;

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCDESCQUANT@'
            || p_dblink
            || '(PCDESCQUANT.CODPROD, PCDESCQUANT.INICIOINTERVALO, PCDESCQUANT.FIMINTERVALO '
            || ',PCDESCQUANT.PERCDESC, PCDESCQUANT.NUMREGIAO, PCDESCQUANT.DTINICIO '
            || ',PCDESCQUANT.DTFIM, PCDESCQUANT.CODPRACA, PCDESCQUANT.PERCDESCVRJ '
            || ',PCDESCQUANT.PERCDESCVP, PCDESCQUANT.PERCDESCFINVV ,PCDESCQUANT.PERCDESCFINVP '
            || ',PCDESCQUANT.PERDESCMAX, PCDESCQUANT.TIPODESCONTO, PCDESCQUANT.CODPLPAGMAX) '
            || 'SELECT PCDESCQUANT.CODPROD, PCDESCQUANT.INICIOINTERVALO, PCDESCQUANT.FIMINTERVALO '
            || ',PCDESCQUANT.PERCDESC, PCDESCQUANT.NUMREGIAO, PCDESCQUANT.DTINICIO '
            || ',PCDESCQUANT.DTFIM, PCDESCQUANT.CODPRACA, PCDESCQUANT.PERCDESCVRJ '
            || ',PCDESCQUANT.PERCDESCVP, PCDESCQUANT.PERCDESCFINVV, PCDESCQUANT.PERCDESCFINVP '
            || ',PCDESCQUANT.PERDESCMAX, PCDESCQUANT.TIPODESCONTO, PCDESCQUANT.CODPLPAGMAX '
            || 'FROM PCDESCQUANT ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         v_sql :=
               'DELETE FROM PCDESCQUANT@'
            || p_dblink
            || ' WHERE CODPROD = :CODPROD';

         EXECUTE IMMEDIATE v_sql
                     USING p_codprod;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCDESCQUANT@'
            || p_dblink
            || '(PCDESCQUANT.CODPROD, PCDESCQUANT.INICIOINTERVALO, PCDESCQUANT.FIMINTERVALO '
            || ',PCDESCQUANT.PERCDESC, PCDESCQUANT.NUMREGIAO, PCDESCQUANT.DTINICIO '
            || ',PCDESCQUANT.DTFIM, PCDESCQUANT.CODPRACA, PCDESCQUANT.PERCDESCVRJ '
            || ',PCDESCQUANT.PERCDESCVP, PCDESCQUANT.PERCDESCFINVV ,PCDESCQUANT.PERCDESCFINVP '
            || ',PCDESCQUANT.PERDESCMAX, PCDESCQUANT.TIPODESCONTO, PCDESCQUANT.CODPLPAGMAX) '
            || 'SELECT PCDESCQUANT.CODPROD, PCDESCQUANT.INICIOINTERVALO, PCDESCQUANT.FIMINTERVALO '
            || ',PCDESCQUANT.PERCDESC, PCDESCQUANT.NUMREGIAO, PCDESCQUANT.DTINICIO '
            || ',PCDESCQUANT.DTFIM, PCDESCQUANT.CODPRACA, PCDESCQUANT.PERCDESCVRJ '
            || ',PCDESCQUANT.PERCDESCVP, PCDESCQUANT.PERCDESCFINVV, PCDESCQUANT.PERCDESCFINVP '
            || ',PCDESCQUANT.PERDESCMAX, PCDESCQUANT.TIPODESCONTO, PCDESCQUANT.CODPLPAGMAX '
            || 'FROM PCDESCQUANT WHERE PCDESCQUANT.CODPROD = :CODPROD';

         EXECUTE IMMEDIATE v_sql USING p_codprod;
         COMMIT;
      END IF;
   END patualizardescontoquantidade;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPoliticaDesconto
| Objetivo    : Atualizar a tabela PCDESCONTO
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data        Comentário
| -------------     ----------   ------------------------------------------------------
| Juliana Teixeira  25/04/2009   Criação da procedure para atualizar a tabela PCDESCONTO.
|***********************************************************************************/
   PROCEDURE patualizarpoliticadesconto (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCDESCONTO@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCDESCONTO@'
         || p_dblink
         || '(coddesconto, codcli, codepto, codsec, codcategoria, codprod,'
         || 'percdesc, dtinicio, dtfim, codusur, codplpag, basecreddebrca,'
         || 'utilizadescrede, codfornec, codsupervisor, tipovenda,'
         || 'numregiao, codfunclanc, datalanc, codfuncultalter,'
         || 'dataultalter, uf, codativ, origemped, codpraca,'
         || 'codprodprinc, numorca, classevenda, aplicadesconto,'
         || 'tipocarga, creditasobrepolitica, tipo, percdescfin,'
         || 'alteraptabela, tipoaplicdescontocb, codprodcb,'
         || 'perccomprofissionalminimo, percdescfornec,'
         || 'prioritaria, questionausoprioritaria)'
         || 'SELECT coddesconto, codcli, codepto, codsec, codcategoria, codprod,'
         || 'percdesc, dtinicio, dtfim, codusur, codplpag, basecreddebrca,'
         || 'utilizadescrede, codfornec, codsupervisor, tipovenda,'
         || 'numregiao, codfunclanc, datalanc, codfuncultalter,'
         || 'dataultalter, uf, codativ, origemped, codpraca,'
         || 'codprodprinc, numorca, classevenda, aplicadesconto,'
         || 'tipocarga, creditasobrepolitica, tipo, percdescfin,'
         || 'alteraptabela, tipoaplicdescontocb, codprodcb,'
         || 'perccomprofissionalminimo, percdescfornec,'
         || 'prioritaria, questionausoprioritaria FROM PCDESCONTO';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarpoliticadesconto;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarTributacaoProdutoporFilial
| Objetivo    : Atualizar a tabela pAtualizarProdutoFilial
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Juliana Teixeira  29/08/2008    Tarefa N.67951-Rotina 2075 contemplando produtos por filial
|                                 quando o parametro venda por embalagem estiver diferente 'S'.
| Juliana Teixeira  02/10/2008    Tarefa N.70077-Ajuste sintaxe insert;
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarprodutofilial (
      p_dblink      IN   VARCHAR2,
      p_codfilial   IN   VARCHAR2,
      p_codprod     IN   pcprodfilial.codprod%TYPE
   )
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      -- Carga Sempre Total
      IF (p_codprod = 0)
      THEN
         v_sql := 'DELETE FROM PCPRODFILIAL@' || p_dblink;

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCPRODFILIAL@'
            || p_dblink
            || '(codprod, codfilial, codcomprador, proibidavenda, foralinha, revenda '
            || ',estoqueideal, multiplo, checarmultiplovendabnf, aceitavendafracao '
            || ',ativo, coddispestrutura, qtminautoserv, qtminimaatacado, qtminimaatacadof '
            || ',utilizaqtdesupmultipla, piscofinsretido, perpis, percofins, calccredipi '
            || ',classevenda, classe, classeestoque) '
            || 'SELECT codprod, codfilial, codcomprador, proibidavenda, foralinha, revenda '
            || ',estoqueideal, multiplo, checarmultiplovendabnf, aceitavendafracao '
            || ',ativo, coddispestrutura, qtminautoserv, qtminimaatacado, qtminimaatacadof '
            || ',utilizaqtdesupmultipla, piscofinsretido, perpis, percofins, calccredipi '
            || ',classevenda, classe, classeestoque FROM PCPRODFILIAL WHERE CODFILIAL = :CODFILIAL';

         EXECUTE IMMEDIATE v_sql USING p_codfilial;
         COMMIT;
      ELSE
         v_sql :=
               'DELETE FROM PCPRODFILIAL@'
            || p_dblink
            || ' WHERE CODPROD = :CODPROD '
            || ' AND CODFILIAL = :CODFILIAL';

         EXECUTE IMMEDIATE v_sql
                     USING p_codfilial, p_codprod;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCPRODFILIAL@'
            || p_dblink
            || '(codprod, codfilial, codcomprador, proibidavenda, foralinha, revenda '
            || ',estoqueideal, multiplo, checarmultiplovendabnf, aceitavendafracao '
            || ',ativo, coddispestrutura, qtminautoserv, qtminimaatacado, qtminimaatacadof '
            || ',utilizaqtdesupmultipla, piscofinsretido, perpis, percofins, calccredipi '
            || ',classevenda, classe, classeestoque) '
            || 'SELECT codprod, codfilial, codcomprador, proibidavenda, foralinha, revenda '
            || ',estoqueideal, multiplo, checarmultiplovendabnf, aceitavendafracao '
            || ',ativo, coddispestrutura, qtminautoserv, qtminimaatacado, qtminimaatacadof '
            || ',utilizaqtdesupmultipla, piscofinsretido, perpis, percofins, calccredipi '
            || ',classevenda, classe, classeestoque FROM PCPRODFILIAL '
            || 'WHERE codfilial = :codfilial AND codprod = :codprod ';

         EXECUTE IMMEDIATE v_sql USING p_codfilial, p_codprod;
         COMMIT;
      END IF;
   END patualizarprodutofilial;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarContato
| Objetivo    : Atualizar a tabela PCCONTATO
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------      -----------   ------------------------------------------------------
| Juliana Teixeira   13/04/2009    Criação da procedure para atualizar a tabela PCCONTATO.
|******************** ***************************************************************/
   PROCEDURE patualizarContato (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCCONTATO@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCCONTATO@'
         || p_dblink
         || '(codcli, nomecontato, tipocontato, cgccpf, dtnascimento,'
         || 'hobbie, time, nomeconjuge, dtnascconjuge, endereco,'
         || 'bairro, cidade, cep, cargo, telefone, celular, email,'
         || 'autorch, estado, doc, codcontato, participsocio, dtsociedade,'
         || 'obs) '
         || 'SELECT codcli, nomecontato, tipocontato, cgccpf, dtnascimento,'
         || 'hobbie, time, nomeconjuge, dtnascconjuge, endereco,'
         || 'bairro, cidade, cep, cargo, telefone, celular, email,'
         || 'autorch, estado, doc, codcontato, participsocio, dtsociedade,'
         || 'obs FROM PCCONTATO ';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarContato;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarbanco
| Objetivo    : Atualizar a tabela PCBANCO
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------      -----------   ------------------------------------------------------
| Juliana Teixeira   29/12/2006    Criação da procedure para atualizar a tabela PCBANCO.
| Juliana Teixeira   15/01/2007    Criação de nova coluna na tabela PCBANCO.
| Juliana Teixeira   22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                  que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|******************** ***************************************************************/
   PROCEDURE patualizarbanco (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCBANCO@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCBANCO@'
         || p_dblink
         || '(CODBANCO, NOME, TIPOCXBCO) '
         || 'SELECT CODBANCO, NOME, TIPOCXBCO '
         || ' FROM PCBANCO';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarbanco;

/*------------------------------------------------------------------------------------
| Procedimento: patualizaroperadoracartao
| Objetivo    : Atualizar a tabela PCOPERADORACARTAO
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------      -----------   ------------------------------------------------------
| Juliana Teixeira   03/04/2009    Tarefa N.81068 Criação da procedure para atualizar a
|                                  tabela PCOPERADORACARTAO.
|******************** ***************************************************************/
   PROCEDURE patualizaroperadoracartao (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCOPERADORACARTAO@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCOPERADORACARTAO@'
         || p_dblink
         || '(CODIGO, OPERADORA, PERCDESC, CODLAYOUTIMP, CODCLI) '
         || 'SELECT CODIGO, OPERADORA, PERCDESC, CODLAYOUTIMP, CODCLI '
         || ' FROM PCOPERADORACARTAO';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizaroperadoracartao;

/*------------------------------------------------------------------------------------
| Procedimento: patualizaroperadoracartao
| Objetivo    : Atualizar a tabela PCOPERADORACARTAOBIN
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------      -----------   ------------------------------------------------------
| Juliana Teixeira   09/04/2009    Tarefa N.81068 Criação da procedure para atualizar a
|                                  tabela PCOPERADORACARTAOBIN.
|******************** ***************************************************************/
   PROCEDURE patualizaroperadoracartaobin (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCOPERADORACARTAOBIN@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCOPERADORACARTAOBIN@'
         || p_dblink
         || '(CODOPERADORA, BIN) '
         || 'SELECT CODOPERADORA, BIN '
         || ' FROM PCOPERADORACARTAOBIN';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizaroperadoracartaobin;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarmensagemrotina
| Objetivo    : Atualizar a tabela PCMENSAGEMROTINA
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel         Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Cleber Junior     07/10/2008    Criação da procedure para atualizar a tabela PCMENSAGEMROTINA.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarmensagemrotina (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCMENSAGEMROTINA@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCMENSAGEMROTINA@'
         || p_dblink
         || '(codigo, titulo, descricaocurta, descricaocompleta, codrotina) '
         || 'SELECT codigo, titulo, descricaocurta, descricaocompleta, codrotina '
         || ' FROM PCMENSAGEMROTINA';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarmensagemrotina;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarParametros
| Objetivo    : Atualizar a tabela PCCONSUM
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel           Data      Comentário
| -------------      ----------   ------------------------------------------------------
| Augusto Cesar      19/07/2006   Criação da procedure para atualizar a tabela PCCONSUM.
| Juliana Teixeira   13/12/2006   Acrescentado campo PCCONSUM.CODSETOROPERCX.
| Sângelles          21/12/2006   Acrescentado campo PCCONSUM.NDIASEXPIRASENHA.
| Juliana Teixeira   14/05/2007   Acrescentado campo PCCONSUM.USAPRODFRACUNITARIO.
| Juliana Teixeira   06/06/2007   Acrescentado campo PCCONSUM.USACESTABASICACF.
| Juliana Teixeira   27/06/2007   Acrescentado campo PCCONSUM.GERARTROCOCOBDIN.
| Juliana Teixeira   27/07/2007   Acrescentado campo PCCONSUM.PERMITIRDESCRODAPECHECKOUT e
|                                 PCCONSUM.PERMAXRODAPECHECKOUT.
| Sângelles Sousa    12/09/2007   PCCONSUM.USADESCPORQUANT
| Juliana Teixeira   20/12/2007   Acrescentado campo PCCONSUM.USACOMISSAOECF (Tarefa N.53245) e
|                                 PCCONSUM.USATRIBUTACAOPORUF (Tarefa N.55581).
| Juliana Teixeira   14/01/2008   Acrescentado campo PCCONSUM.USAFECHAMENTOCXCEGO (Tarefa N.48101);
| Juliana Teixeira   26/02/2008   Acrescentado campo PCCONSUM.PERMITEVENDAPRODUTOPV (Tarefa N.58438);
| Cleber Junior      08/09/2008   Acrescentado campo PCCONSUM.validarestoqueautoservico (Tarefa N.68649);
| Juliana Teixeira   10/09/2008   Acrescentado campo PCCONSUM.INCLUIRCOMISSAOCMVVENDA (Tarefa N.68200);
| Juliana Teixeira   22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarparametros (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCCONSUM@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      -- Carga Sempre Total
      v_sql :=
            'INSERT /*+ APPEND */ INTO PCCONSUM@'
         || p_dblink
         || '(DIRWINTHOR, TXVENDA, EMPRESA, CIDADE,CODSETORFISCALCX '
         || ',CODFILIALCX, NUMREGIAOPADRAO, UTILIZAPERCFINPRECOPROM '
         || ',PROXNUMTRANSVENDA, UTILIZAFILIALREGIAOCX, SOMADESPFINITEMCF '
         || ',PRECOPOREMBALAGEM,TIPOCALCST, CALCSTPF, UTILIZAPERCBASEREDPF '
         || ',CONSIDERAISENTOSCOMOPF,GERAPARCELAMENTOTEF, VALIDARUFFILIAL '
         || ',VLMINCANCITEMCUPOM, VLMINCANCCUPOM,IMPRIMEDESCONTOCF, USATECLADOGERTEC '
         || ',VALIDANUMSERIEEQUIPECF, NUMCASASDECVENDA,GERARDADOSREDUCAOZ '
         || ',PERMAXDESCITEMCF, OBTERPREFERENCIACLIECF, VERIFICADATAHORAECF '
         || ',CODSETOROPERCX, NDIASEXPIRASENHA, USAPRODFRACUNITARIO, USACESTABASICACF '
         || ',GERARTROCOCOBDIN, PERMITIRDESCRODAPECHECKOUT, PERMAXRODAPECHECKOUT '
         || ',USADESCPORQUANT, USACOMISSAOECF, USATRIBUTACAOPORUF, USAFECHAMENTOCXCEGO '
         || ',PERMITEVENDAPRODUTOPV, VALIDARESTOQUEAUTOSERVICO, INCLUIRCOMISSAOCMVVENDA) '
         || 'SELECT DIRWINTHOR, TXVENDA, EMPRESA, CIDADE,CODSETORFISCALCX '
         || ',CODFILIALCX, NUMREGIAOPADRAO, UTILIZAPERCFINPRECOPROM '
         || ',PROXNUMTRANSVENDA, UTILIZAFILIALREGIAOCX, SOMADESPFINITEMCF '
         || ',PRECOPOREMBALAGEM,TIPOCALCST, CALCSTPF, UTILIZAPERCBASEREDPF '
         || ',CONSIDERAISENTOSCOMOPF,GERAPARCELAMENTOTEF, VALIDARUFFILIAL '
         || ',VLMINCANCITEMCUPOM, VLMINCANCCUPOM,IMPRIMEDESCONTOCF '
         || ',USATECLADOGERTEC, VALIDANUMSERIEEQUIPECF, NUMCASASDECVENDA '
         || ',GERARDADOSREDUCAOZ, PERMAXDESCITEMCF, OBTERPREFERENCIACLIECF'
         || ',VERIFICADATAHORAECF, CODSETOROPERCX, NDIASEXPIRASENHA'
         || ',USAPRODFRACUNITARIO, USACESTABASICACF, GERARTROCOCOBDIN'
         || ',PERMITIRDESCRODAPECHECKOUT, PERMAXRODAPECHECKOUT'
         || ',USADESCPORQUANT, USACOMISSAOECF, USATRIBUTACAOPORUF'
         || ',USAFECHAMENTOCXCEGO, PERMITEVENDAPRODUTOPV, VALIDARESTOQUEAUTOSERVICO'
         || ',INCLUIRCOMISSAOCMVVENDA FROM PCCONSUM';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarparametros;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarEmbalagem
| Objetivo    : Atualizar a tabela PCEMBALAGEM
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_NumRegiao : Código de região que será utilizada para atualização.
|   p_DtAtualizacaoBD : Data utilizada para informar a partir de qual data a tabela
|                       PCEMBALAGEM será atualizada.
|   p_TipoAtualizacao : Tipo de atualização: P = Parcial ou T = Total.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data                       Comentário
| -------------      ----------   ------------------------------------------------------
| Augusto Cesar      20/07/2006    Criação da procedure para atualizar a tabela PCEMBALAGEM.
| Juliana Teixeira   17/04/2007    Tarefa N.42485 - Acrescentado os campos pvendaatac, ptabelaatac,
|                                  precoanterioratac, qtminimaatacado e qtminimaatacadof.
| Juliana Teixeira   09/05/2007    Tarefa N.42985 - Acrescentado o campo fatorpreco para
|                                  ser utilizado na rotina 2075 (precoporembalagem=N).
| Juliana Teixeira   08/06/2007    Tarefa N.44672 - Acrescentado o campo OBS para validar obs do
|                                  plano de pagamento na venda da rotina 2075.
|                                  Incluso a exportação dos campos DTOFERTAATACINI, DTOFERTAATACFIM e
|                                  POFERTAATAC
| Juliana Teixeira   11/03/2008    Tarefa N.5911 - Acrescentada exportação do campo QTMULTIPLA;
| Juliana Teixeira   31/03/2008    Tarefa N.60783 - Acrescentada exportação do campo DESCRICAOECF;
| Juliana Teixeira   01/07/2008    Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira   02/09/2008    Tarefa N.68356-Alterada carga parcial para retirar laco e evitar melhor performance.
| Juliana Teixeira   17/09/2008    Tarefa N.69098-Ajuste na carga parcial dos dados;
| Juliana Teixeira   22/12/2008    Tarefa N.75204-Acrescentado commit para cada procedimento para evitar que os dados fiquem
|                                  na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarembalagem (
      p_dblink            IN   VARCHAR2,
      p_numregiao         IN   pctabpr.numregiao%TYPE DEFAULT 1,
      p_datainicial       IN   pcembalagem.dtultaltpvenda%TYPE DEFAULT NULL,
      p_datafinal         IN   pcembalagem.dtultaltpvenda%TYPE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T',
      p_codprod           IN   pcembalagem.codprod%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      IF p_tipoatualizacao = 'T'
      THEN
         IF (p_codprod = 0)
         THEN
            v_sql := 'DELETE FROM PCEMBALAGEM@' || p_dblink;

            EXECUTE IMMEDIATE v_sql;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCEMBALAGEM@'
               || p_dblink
               || '(CODAUXILIAR, CODFILIAL, CODPROD,QTUNIT, PVENDA, UNIDADE'
               || ',EMBALAGEM, QTMAXVENDA, TIPOEMBALAGEM,POFERTA, DTOFERTAINI'
               || ', DTOFERTAFIM, PTABELAATAC, PVENDAATAC, PRECOANTERIORATAC'
               || ', QTMINIMAATACADO, QTMINIMAATACADOF, FATORPRECO, PERVARIACAOPTABELA, OBS,POFERTAATAC'
               || ',DTOFERTAATACINI,DTOFERTAATACFIM, PESOBRUTO, QTMULTIPLA, DESCRICAOECF) '
               || 'SELECT PCEMBALAGEM.CODAUXILIAR, PCEMBALAGEM.CODFILIAL,PCEMBALAGEM.CODPROD'
               || ',PCEMBALAGEM.QTUNIT, NVL(PCEMBALAGEM.PVENDA,0) PVENDA,PCEMBALAGEM.UNIDADE,PCEMBALAGEM.EMBALAGEM'
               || ',PCEMBALAGEM.QTMAXVENDA,PCEMBALAGEM.TIPOEMBALAGEM, PCEMBALAGEM.POFERTA'
               || ',PCEMBALAGEM.DTOFERTAINI,PCEMBALAGEM.DTOFERTAFIM,PCEMBALAGEM.PTABELAATAC'
               || ',PCEMBALAGEM.PVENDAATAC, PCEMBALAGEM.PRECOANTERIORATAC, PCEMBALAGEM.QTMINIMAATACADO'
               || ',PCEMBALAGEM.QTMINIMAATACADOF, PCEMBALAGEM.FATORPRECO, PCEMBALAGEM.PERVARIACAOPTABELA, PCEMBALAGEM.OBS,POFERTAATAC'
               || ',DTOFERTAATACINI,DTOFERTAATACFIM, PCEMBALAGEM.PESOBRUTO, PCEMBALAGEM.QTMULTIPLA'
               || ',PCEMBALAGEM.DESCRICAOECF'
               || ' FROM PCEMBALAGEM, PCPRODUT, PCTABPR'
               || ' WHERE PCEMBALAGEM.CODPROD = PCPRODUT.CODPROD'
               || '   AND PCEMBALAGEM.CODPROD = PCTABPR.CODPROD'
               || '   AND PCTABPR.NUMREGIAO = :NUMREGIAO';

            EXECUTE IMMEDIATE v_sql
                        USING p_numregiao;
            COMMIT;
         ELSE
            v_sql :=
                  'DELETE FROM PCEMBALAGEM@'
               || p_dblink
               || ' WHERE CODPROD = :CODPROD';

            EXECUTE IMMEDIATE v_sql
                        USING p_codprod;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCEMBALAGEM@'
               || p_dblink
               || '(CODAUXILIAR, CODFILIAL, CODPROD,QTUNIT, PVENDA, UNIDADE'
               || ',EMBALAGEM, QTMAXVENDA, TIPOEMBALAGEM,POFERTA, DTOFERTAINI'
               || ', DTOFERTAFIM, PTABELAATAC, PVENDAATAC, PRECOANTERIORATAC'
               || ', QTMINIMAATACADO, QTMINIMAATACADOF, FATORPRECO, PERVARIACAOPTABELA, OBS,POFERTAATAC'
               || ',DTOFERTAATACINI,DTOFERTAATACFIM, PESOBRUTO, QTMULTIPLA, DESCRICAOECF) '
               || 'SELECT PCEMBALAGEM.CODAUXILIAR, PCEMBALAGEM.CODFILIAL,PCEMBALAGEM.CODPROD'
               || ',PCEMBALAGEM.QTUNIT, PCEMBALAGEM.PVENDA,PCEMBALAGEM.UNIDADE,PCEMBALAGEM.EMBALAGEM'
               || ',PCEMBALAGEM.QTMAXVENDA,PCEMBALAGEM.TIPOEMBALAGEM, PCEMBALAGEM.POFERTA'
               || ',PCEMBALAGEM.DTOFERTAINI,PCEMBALAGEM.DTOFERTAFIM,PCEMBALAGEM.PTABELAATAC'
               || ',PCEMBALAGEM.PVENDAATAC, PCEMBALAGEM.PRECOANTERIORATAC, PCEMBALAGEM.QTMINIMAATACADO'
               || ',PCEMBALAGEM.QTMINIMAATACADOF, PCEMBALAGEM.FATORPRECO, PCEMBALAGEM.PERVARIACAOPTABELA, PCEMBALAGEM.OBS,POFERTAATAC'
               || ',DTOFERTAATACINI,DTOFERTAATACFIM, PCEMBALAGEM.PESOBRUTO, PCEMBALAGEM.QTMULTIPLA'
               || ',PCEMBALAGEM.DESCRICAOECF'
               || ' FROM PCEMBALAGEM, PCPRODUT, PCTABPR'
               || ' WHERE PCEMBALAGEM.CODPROD = PCPRODUT.CODPROD'
               || '   AND PCEMBALAGEM.CODPROD = PCTABPR.CODPROD'
               || '   AND PCTABPR.NUMREGIAO = :NUMREGIAO'
               || '   AND PCEMBALAGEM.CODPROD = :CODPROD';

            EXECUTE IMMEDIATE v_sql USING p_numregiao, p_codprod;
            COMMIT;
         END IF;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO PCEMBALAGEM@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT CODAUXILIAR, CODFILIAL, CODPROD, QTUNIT, '
            || ' PVENDA, UNIDADE, EMBALAGEM, QTMAXVENDA, TIPOEMBALAGEM, '
            || ' POFERTA, DTOFERTAINI, DTOFERTAFIM, PTABELAATAC, PVENDAATAC, '
            || ' PRECOANTERIORATAC, QTMINIMAATACADO, QTMINIMAATACADOF, FATORPRECO, PERVARIACAOPTABELA,'
            || ' OBS, POFERTAATAC, DTOFERTAATACINI, DTOFERTAATACFIM, '
            || ' PESOBRUTO, QTMULTIPLA, DESCRICAOECF '
            || ' FROM PCEMBALAGEM'
            || '        WHERE (PCEMBALAGEM.DTULTALTPVENDA '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                        || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '


            || '           OR (TRUNC(PCEMBALAGEM.DTULTALTERSRVPRC) '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                           || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'' ) ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || ' || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS''))) )) tabela_origem '
            || ' ON (tabela_origem.CODAUXILIAR = tabela_destino.CODAUXILIAR AND '
            || '     tabela_origem.CODFILIAL = tabela_destino.CODFILIAL) '
            || ' WHEN MATCHED THEN '
            || '  UPDATE '
            || ' SET tabela_destino.CODPROD = tabela_origem.CODPROD, '
            || '  tabela_destino.QTUNIT = tabela_origem.QTUNIT, '
            || '  tabela_destino.PVENDA = tabela_origem.PVENDA, '
            || '  tabela_destino.UNIDADE = tabela_origem.UNIDADE, '
            || '  tabela_destino.EMBALAGEM = tabela_origem.EMBALAGEM, '
            || '  tabela_destino.QTMAXVENDA = tabela_origem.QTMAXVENDA, '
            || '  tabela_destino.TIPOEMBALAGEM = tabela_origem.TIPOEMBALAGEM, '
            || '  tabela_destino.POFERTA = tabela_origem.POFERTA, '
            || '  tabela_destino.DTOFERTAINI = tabela_origem.DTOFERTAINI, '
            || '  tabela_destino.DTOFERTAFIM = tabela_origem.DTOFERTAFIM, '
            || '  tabela_destino.PTABELAATAC = tabela_origem.PTABELAATAC, '
            || '  tabela_destino.PVENDAATAC = tabela_origem.PVENDAATAC, '
            || '  tabela_destino.PRECOANTERIORATAC = tabela_origem.PRECOANTERIORATAC, '
            || '  tabela_destino.QTMINIMAATACADO = tabela_origem.QTMINIMAATACADO, '
            || '  tabela_destino.QTMINIMAATACADOF = tabela_origem.QTMINIMAATACADOF, '
            || '  tabela_destino.FATORPRECO = tabela_origem.FATORPRECO, '
            || '  tabela_destino.PERVARIACAOPTABELA = tabela_origem.PERVARIACAOPTABELA, '
            || '  tabela_destino.OBS = tabela_origem.OBS, '
            || '  tabela_destino.POFERTAATAC = tabela_origem.POFERTAATAC, '
            || '  tabela_destino.DTOFERTAATACINI = tabela_origem.DTOFERTAATACINI, '
            || '  tabela_destino.DTOFERTAATACFIM = tabela_origem.DTOFERTAATACFIM, '
            || '  tabela_destino.PESOBRUTO = tabela_origem.PESOBRUTO, '
            || '  tabela_destino.QTMULTIPLA = tabela_origem.QTMULTIPLA, '
            || '  tabela_destino.DESCRICAOECF = tabela_origem.DESCRICAOECF '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (CODAUXILIAR, CODFILIAL, CODPROD, QTUNIT, '
            || ' PVENDA, UNIDADE, EMBALAGEM, QTMAXVENDA, TIPOEMBALAGEM, '
            || ' POFERTA, DTOFERTAINI, DTOFERTAFIM, PTABELAATAC, PVENDAATAC, '
            || ' PRECOANTERIORATAC, QTMINIMAATACADO, QTMINIMAATACADOF, FATORPRECO, PERVARIACAOPTABELA,'
            || ' OBS, POFERTAATAC, DTOFERTAATACINI, DTOFERTAATACFIM, '
            || ' PESOBRUTO, QTMULTIPLA, DESCRICAOECF) '
            || ' VALUES (tabela_origem.CODAUXILIAR, tabela_origem.CODFILIAL, '
            || ' tabela_origem.CODPROD, tabela_origem.QTUNIT, tabela_origem.PVENDA, '
            || ' tabela_origem.UNIDADE, tabela_origem.EMBALAGEM, tabela_origem.QTMAXVENDA, '
            || ' tabela_origem.TIPOEMBALAGEM, tabela_origem.POFERTA, tabela_origem.DTOFERTAINI, '
            || ' tabela_origem.DTOFERTAFIM, tabela_origem.PTABELAATAC, tabela_origem.PVENDAATAC, '
            || ' tabela_origem.PRECOANTERIORATAC, tabela_origem.QTMINIMAATACADO, '
            || ' tabela_origem.QTMINIMAATACADOF, tabela_origem.FATORPRECO, tabela_origem.PERVARIACAOPTABELA, '
            || ' tabela_origem.OBS, tabela_origem.POFERTAATAC, tabela_origem.DTOFERTAATACINI, '
            || ' tabela_origem.DTOFERTAATACFIM, tabela_origem.PESOBRUTO, tabela_origem.QTMULTIPLA, '
            || ' tabela_origem.DESCRICAOECF) ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizarembalagem;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarEmbalagem
| Objetivo    : Atualizar a tabela PCEMBALAGEM. Esta atualição será disparada por um job
|               que obterá os registros através da tabela de fila de atualização PCFILAATTUALIZACX.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_IdSequencial : Identificar sequencial do registros que está armazenado na
|                    tabela PCFILAATTUALIZACX
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel           Data                       Comentário
| -------------      ----------   ------------------------------------------------------
| Augusto Cesar      13/09/2006    Criação da procedure para atualizar a tabela PCEMBALAGEM.
| Juliana Teixeira   17/04/2007    Tarefa N.42485 - Acrescentado os campos pvendaatac, ptabelaatac,
|                                  precoanterioratac, qtminimaatacado e qtminimaatacadof.
| Juliana Teixeira   09/05/2007    Tarefa N.42985 - Acrescentado o campo fatorpreco para
|                                  ser utilizado na rotina 2075 (precoporembalagem=N).
| Juliana Teixeira   08/06/2007    Tarefa N.44672 - Acrescentado o campo OBS para validar obs do
|                                  plano de pagamento na venda da rotina 2075.
| Juliana Teixeira   22/12/2008    Tarefa N.75204-Acrescentado commit para cada procedimento para evitar que os dados fiquem
|                                  na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarembalagem (
      p_dblink         IN   VARCHAR2,
      p_idsequencial   IN   pcembalagem.numseqatu%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      FOR c_embalagem IN (SELECT pcembalagem.codauxiliar,
                                 pcembalagem.codfilial, pcembalagem.codprod,
                                 pcembalagem.qtunit, pcembalagem.pvenda,
                                 pcembalagem.embalagem, pcembalagem.unidade,
                                 pcembalagem.qtmaxvenda,
                                 pcembalagem.tipoembalagem,
                                 pcembalagem.poferta,
                                 pcembalagem.dtofertaini,
                                 pcembalagem.dtofertafim,
                                 pcembalagem.ptabelaatac,
                                 pcembalagem.pvendaatac,
                                 pcembalagem.precoanterioratac,
                                 pcembalagem.qtminimaatacado,
                                 pcembalagem.qtminimaatacadof,
                                 pcembalagem.fatorpreco,
                                 pcembalagem.PERVARIACAOPTABELA,
                                 pcembalagem.obs
                            FROM pcembalagem
                           WHERE pcembalagem.numseqatu = p_idsequencial)
      LOOP
         v_sql :=
               'SELECT COUNT(*) CONTADOR FROM PCEMBALAGEM@'
            || p_dblink
            || ' WHERE PCEMBALAGEM.CODAUXILIAR = :CODAUXILIAR '
            || ' AND PCEMBALAGEM.CODFILIAL = :CODFILIAL '
            || ' AND ROWNUM = 1';

         EXECUTE IMMEDIATE v_sql
                      INTO v_totalregistros
                     USING c_embalagem.codauxiliar, c_embalagem.codfilial;

         IF v_totalregistros = 0
         THEN
            v_sql :=
                  'INSERT INTO PCEMBALAGEM@'
               || p_dblink
               || '(CODAUXILIAR, CODFILIAL, CODPROD, QTUNIT, PVENDA '
               || ', UNIDADE, EMBALAGEM, QTMAXVENDA, TIPOEMBALAGEM '
               || ', POFERTA, DTOFERTAINI, DTOFERTAFIM, PTABELAATAC '
               || ', PVENDAATAC, PRECOANTERIORATAC, QTMINIMAATACADO '
               || ', QTMINIMAATACADOF, FATORPRECO, PERVARIACAOPTABELA,OBS) '
               || 'VALUES (:CODAUXILIAR, :CODFILIAL, :CODPROD, :QTUNIT, :PVENDA '
               || ',:UNIDADE, :EMBALAGEM, :QTMAXVENDA, :TIPOEMBALAGEM '
               || ',:POFERTA, :DTOFERTAINI, :DTOFERTAFIM, :PTABELAATAC '
               || ',:PVENDAATAC, :PRECOANTERIORATAC, :QTMINIMAATACADO '
               || ',:QTMINIMAATACADOF, :FATORPRECO, :PERVARIACAOPTABELA, :OBS) ';

            EXECUTE IMMEDIATE v_sql
                        USING c_embalagem.codauxiliar,
                              c_embalagem.codfilial,
                              c_embalagem.codprod,
                              c_embalagem.qtunit,
                              c_embalagem.pvenda,
                              c_embalagem.unidade,
                              c_embalagem.embalagem,
                              c_embalagem.qtmaxvenda,
                              c_embalagem.tipoembalagem,
                              c_embalagem.poferta,
                              c_embalagem.dtofertaini,
                              c_embalagem.dtofertafim,
                              c_embalagem.ptabelaatac,
                              c_embalagem.pvendaatac,
                              c_embalagem.precoanterioratac,
                              c_embalagem.qtminimaatacado,
                              c_embalagem.qtminimaatacadof,
                              c_embalagem.fatorpreco,
                              c_embalagem.PERVARIACAOPTABELA,
                              c_embalagem.obs;
         ELSE
            v_sql :=
                  'UPDATE PCEMBALAGEM@'
               || p_dblink
               || ' SET CODPROD = :CODPROD, QTUNIT = :QTUNIT '
               || ', PVENDA = :PVENDA, UNIDADE = :UNIDADE, EMBALAGEM = :EMBALAGEM '
               || ', QTMAXVENDA = :QTMAXVENDA, TIPOEMBALAGEM = :TIPOEMBALAGEM '
               || ', POFERTA = :POFERTA, DTOFERTAINI = :DTOFERTAINI, DTOFERTAFIM = :DTOFERTAFIM  '
               || ', PTABELAATAC = :PTABELAATAC, PVENDAATAC = :PVENDAATAC, PRECOANTERIORATAC = :PRECOANTERIORATAC  '
               || ', QTMINIMAATACADO = :QTMINIMAATACADO, QTMINIMAATACADOF = :QTMINIMAATACADOF '
               || ', FATORPRECO = :FATORPRECO, PERVARIACAOPTABELA = :PERVARIACAOPTABELA, OBS = :OBS '
               || 'WHERE CODAUXILIAR = :CODAUXILIAR '
               || 'AND CODFILIAL = :CODFILIAL';

            EXECUTE IMMEDIATE v_sql
                        USING c_embalagem.codprod,
                              c_embalagem.qtunit,
                              c_embalagem.pvenda,
                              c_embalagem.unidade,
                              c_embalagem.embalagem,
                              c_embalagem.qtmaxvenda,
                              c_embalagem.tipoembalagem,
                              c_embalagem.poferta,
                              c_embalagem.dtofertaini,
                              c_embalagem.dtofertafim,
                              c_embalagem.codauxiliar,
                              c_embalagem.codfilial,
                              c_embalagem.ptabelaatac,
                              c_embalagem.pvendaatac,
                              c_embalagem.precoanterioratac,
                              c_embalagem.qtminimaatacado,
                              c_embalagem.qtminimaatacadof,
                              c_embalagem.fatorpreco,
                              c_embalagem.PERVARIACAOPTABELA,
                              c_embalagem.obs;
         END IF;
      END LOOP;
      COMMIT;
   END patualizarembalagem;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarFuncionarios
| Objetivo    : Atualizar a tabela PCCLIENT. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel         Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCEMPR.
| Juliana Teixeira  28/12/2006    Tarefa N.37062 - Acrescentada novas colunas responsável
|                                 em validar logim corretamente login do usuário na rotina
|                                 PCAUX2075.
| Sângelles Sousa   25/01/2007    Tarefa: 38224 - Coloquei o campo NUMCONEXOES, inserir o where para filtrar os funcionarios
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarfuncionarios (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCEMPR@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCEMPR@'
         || p_dblink
         || '(CODSETOR, MATRICULA, NOME, CODUSUR, SITUACAO '
         || ',USUARIOBD, SENHABD, CODIDIOMA, NOME_GUERRA '
         || ',NUMCONEXOESATUAL, USUARIOLOGADO, DTEXPIRASENHA, NUMCONEXOES, NUMIDENTIFICADORECF) '
         || 'SELECT CODSETOR, MATRICULA, NOME, CODUSUR, SITUACAO '
         || ',USUARIOBD, SENHABD, CODIDIOMA, NOME_GUERRA '
         || ',NUMCONEXOESATUAL, USUARIOLOGADO, DTEXPIRASENHA,NUMCONEXOES, NUMIDENTIFICADORECF '
         || ' FROM PCEMPR  WHERE PCEMPR.SITUACAO <> ''I'' AND '
         || ' PCEMPR.CODSETOR in ((SELECT codsetorfiscalcx FROM PCCONSUM), '
         || ' (SELECT codsetoropercx FROM PCCONSUM)) ';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarfuncionarios;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarEstoque
| Objetivo    : Atualizar a tabela PCEST. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar      20/07/2006    Criação da procedure para atualizar a tabela PCEST.
| Juliana Teixeira   01/07/2008    Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira   17/09/2008    Tarefa N.69098-Ajuste na carga parcial dos dados;
| Juliana Teixeira   22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                  que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira   20/02/2009    Tarefa N.78912 - Correcao na ordem de envio dos parametros no comando delete;
|***********************************************************************************/
   PROCEDURE patualizarestoque (
      p_dblink            IN   VARCHAR2,
      p_codfilial         IN   pcest.codfilial%TYPE DEFAULT '1',
      p_codprod           IN   pcest.codprod%TYPE,
      p_numregiao         IN   pctabpr.numregiao%TYPE DEFAULT 1,
      p_datainicial       IN   pcest.dtultent%TYPE DEFAULT NULL,
      p_datafinal         IN   pcest.dtultent%TYPE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T'
   )
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      IF p_tipoatualizacao = 'T'
      THEN
         IF (p_codprod = 0)
         THEN
            v_sql := 'DELETE FROM PCEST@' || p_dblink;

            EXECUTE IMMEDIATE v_sql;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCEST@'
               || p_dblink
               || '(PCEST.CODPROD, PCEST.CODFILIAL, PCEST.QTESTGER, PCEST.CUSTOREAL '
               || ',PCEST.CUSTOREP, PCEST.CUSTOFIN, PCEST.CUSTOCONT, PCEST.VALORULTENT) '
               || 'SELECT PCEST.CODPROD, PCEST.CODFILIAL, PCEST.QTESTGER, PCEST.CUSTOREAL '
               || ',PCEST.CUSTOREP, PCEST.CUSTOFIN, PCEST.CUSTOCONT, PCEST.VALORULTENT '
               || 'FROM PCEST, PCPRODUT, PCTABPR '
               || 'WHERE PCEST.CODFILIAL = :CODFILIAL '
               || 'AND PCTABPR.NUMREGIAO = :NUMREGIAO '
               || 'AND PCEST.CODPROD = PCPRODUT.CODPROD '
               || 'AND PCEST.CODPROD = PCTABPR.CODPROD';

            EXECUTE IMMEDIATE v_sql USING p_codfilial, p_numregiao;
            COMMIT;
         ELSE
            v_sql :=
                  'DELETE FROM PCEST@'
               || p_dblink
               || ' WHERE CODPROD = :CODPROD '
               || ' AND CODFILIAL = :CODFILIAL';

            EXECUTE IMMEDIATE v_sql USING p_codprod, p_codfilial;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCEST@'
               || p_dblink
               || '(PCEST.CODPROD, PCEST.CODFILIAL, PCEST.QTESTGER, PCEST.CUSTOREAL '
               || ',PCEST.CUSTOREP, PCEST.CUSTOFIN, PCEST.CUSTOCONT, PCEST.VALORULTENT) '
               || 'SELECT PCEST.CODPROD, PCEST.CODFILIAL, PCEST.QTESTGER, PCEST.CUSTOREAL '
               || ',PCEST.CUSTOREP, PCEST.CUSTOFIN, PCEST.CUSTOCONT, PCEST.VALORULTENT '
               || 'FROM PCEST, PCPRODUT, PCTABPR '
               || 'WHERE PCEST.CODFILIAL = :CODFILIAL '
               || 'AND PCTABPR.NUMREGIAO = :NUMREGIAO '
               || 'AND PCEST.CODPROD = PCPRODUT.CODPROD '
               || 'AND PCEST.CODPROD = PCTABPR.CODPROD '
               || 'AND PCEST.CODPROD = :CODPROD';

            EXECUTE IMMEDIATE v_sql USING p_codfilial, p_numregiao, p_codprod;
            COMMIT;
         END IF;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO PCEST@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT CODPROD, CODFILIAL, QTESTGER, CUSTOREAL, '
            || ' CUSTOREP, CUSTOFIN, CUSTOCONT, VALORULTENT '
            || ' FROM PCEST '
            || '        WHERE (PCEST.DTULTENT '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                        || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '

            || '           OR (TRUNC(PCEST.DTULTALTERSRVPRC) '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                           || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'' ) ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || ' || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS''))) )) tabela_origem '
            || ' ON (tabela_origem.CODPROD = tabela_destino.CODPROD AND '
            || '     tabela_origem.CODFILIAL = tabela_destino.CODFILIAL) '
            || ' WHEN MATCHED THEN '
            || '  UPDATE '
            || ' SET tabela_destino.QTESTGER = tabela_origem.QTESTGER, '
            || '  tabela_destino.CUSTOREAL = tabela_origem.CUSTOREAL, '
            || '  tabela_destino.CUSTOREP = tabela_origem.CUSTOREP, '
            || '  tabela_destino.CUSTOFIN = tabela_origem.CUSTOFIN, '
            || '  tabela_destino.CUSTOCONT = tabela_origem.CUSTOCONT, '
            || '  tabela_destino.VALORULTENT = tabela_origem.VALORULTENT '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (CODPROD, CODFILIAL, QTESTGER, CUSTOREAL, CUSTOREP, '
            || ' CUSTOFIN, CUSTOCONT, VALORULTENT) '
            || ' VALUES (tabela_origem.CODPROD, tabela_origem.CODFILIAL, '
            || ' tabela_origem.QTESTGER, tabela_origem.CUSTOREAL, '
            || ' tabela_origem.CUSTOREP, tabela_origem.CUSTOFIN, '
            || ' tabela_origem.CUSTOCONT, tabela_origem.VALORULTENT) ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizarestoque;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPlanoPag
| Objetivo    : Atualizar a tabela PCPLPAG. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCPLPAG.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarplanopag (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCPLPAG@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCPLPAG@'
         || p_dblink
         || '(CODPLPAG, DESCRICAO, PRAZO1, PRAZO2, PRAZO3, PRAZO4, PRAZO5, PRAZO6 '
         || ',PRAZO7, PRAZO8, PRAZO9, PRAZO10, PRAZO11, PRAZO12, PERTXFIM, TIPOPRAZO '
         || ',OBS, NUMDIAS, NUMPR, USAPLPAGAUTOSERVICO, DTVENC1, DTVENC2, DTVENC3) '
         || 'SELECT CODPLPAG, DESCRICAO, PRAZO1, PRAZO2, PRAZO3,PRAZO4, PRAZO5, PRAZO6 '
         || ',PRAZO7, PRAZO8, PRAZO9, PRAZO10, PRAZO11, PRAZO12, PERTXFIM, TIPOPRAZO '
         || ',OBS ,NUMDIAS, NUMPR, USAPLPAGAUTOSERVICO, DTVENC1, DTVENC2, DTVENC3  '
         || ' FROM PCPLPAG';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarplanopag;

/*------------------------------------------------------------------------------------
| Procedimento: HabilitarSessao
| Objetivo    : Atualizar a tabela PCPRACA. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink  : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCPRACA.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarpraca (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCPRACA@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCPRACA@'
         || p_dblink
         || '(CODPRACA, PRACA, NUMREGIAO) '
         || 'SELECT CODPRACA, PRACA, NUMREGIAO FROM PCPRACA';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
END patualizarpraca;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPrecos
| Objetivo    : Atualizar a tabela PCTABPR. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_NumRegiao : Código de região que será utilizada para atualização.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     ----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCTABPR.
| Juliana Teixeira  11/09/2007    Ajuste na procedure para exportar preço de venda por atacado.
| Juliana Teixeira  01/07/2008    Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira  02/09/2008    Tarefa N.68356-Alterada carga parcial para retirar laco e evitar melhor performance.
| Juliana Teixeira  17/09/2008    Tarefa N.69098-Ajuste na carga parcial dos dados;
| Juliana Teixeira  17/11/2008    Tarefa N.72346 - Para emissão da nota fiscal na rotina 2075 implementado ajuste
|                                 para listar a tributação conforme a região do cliente selecionada no momento da
|                                 venda, este filtro foi retirado para que as tribuções de todas as regiões sejam
|                                 exportadas.
| Juliana Teixeira  09/12/2008    Ajuste para filtrar corretamente o numero da regiao para exportar os precos;
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  27/01/2009    Tarefa N.75903 - Retirada condicao para exportar dados que esteja marcados
|                                 como excluidos para evitar registracao no auto servico;
|***********************************************************************************/
   PROCEDURE patualizarprecos (
      p_dblink            IN   VARCHAR2,
      p_numregiao         IN   pctabpr.numregiao%TYPE DEFAULT 1,
      p_datainicial       IN   pctabpr.dtultaltpvenda%TYPE DEFAULT NULL,
      p_datafinal         IN   pctabpr.dtultaltpvenda%TYPE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T',
      p_codprod           IN   pctabpr.codprod%TYPE
   )
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      IF p_tipoatualizacao = 'T'
      THEN
         IF (p_codprod = 0)
         THEN
            v_sql := 'DELETE FROM PCTABPR@' || p_dblink;

            EXECUTE IMMEDIATE v_sql;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCTABPR@'
               || p_dblink
               || '(CODPROD, NUMREGIAO, CODST, PVENDA1, PVENDA2,PVENDA3, PVENDA4 '
               || ',PVENDA5, PVENDA6, PVENDA7, COTAITEM, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3 '
               || ',PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7) '
               || 'SELECT PCTABPR.CODPROD, PCTABPR.NUMREGIAO, PCTABPR.CODST,PCTABPR.PVENDA1 '
               || ',PCTABPR.PVENDA2, PCTABPR.PVENDA3, PCTABPR.PVENDA4,PCTABPR.PVENDA5 '
               || ',PCTABPR.PVENDA6, PCTABPR.PVENDA7, PCTABPR.COTAITEM,PCTABPR.PVENDAATAC1 '
               || ',PCTABPR.PVENDAATAC2, PCTABPR.PVENDAATAC3, PCTABPR.PVENDAATAC4 '
               || ',PCTABPR.PVENDAATAC5, PCTABPR.PVENDAATAC6, PCTABPR.PVENDAATAC7 '
               || ' FROM PCTABPR, PCPRODUT '
               || ' WHERE PCTABPR.CODPROD = PCPRODUT.CODPROD '
               || '   AND PCTABPR.NUMREGIAO = :NUMREGIAO ';
             --|| '   AND NVL(PCTABPR.EXCLUIDO,''N'') = ''N''';

            EXECUTE IMMEDIATE v_sql USING p_numregiao;
            COMMIT;
         ELSE
            v_sql :=
                  'DELETE FROM PCTABPR@'
               || p_dblink
               || ' WHERE CODPROD = :CODPROD';

            EXECUTE IMMEDIATE v_sql USING p_codprod;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCTABPR@'
               || p_dblink
               || '(CODPROD, NUMREGIAO, CODST, PVENDA1, PVENDA2,PVENDA3, PVENDA4 '
               || ',PVENDA5, PVENDA6, PVENDA7, COTAITEM, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3 '
               || ',PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7) '
               || 'SELECT PCTABPR.CODPROD, PCTABPR.NUMREGIAO, PCTABPR.CODST,PCTABPR.PVENDA1 '
               || ',PCTABPR.PVENDA2, PCTABPR.PVENDA3, PCTABPR.PVENDA4,PCTABPR.PVENDA5 '
               || ',PCTABPR.PVENDA6, PCTABPR.PVENDA7, PCTABPR.COTAITEM,PCTABPR.PVENDAATAC1 '
               || ',PCTABPR.PVENDAATAC2, PCTABPR.PVENDAATAC3, PCTABPR.PVENDAATAC4 '
               || ',PCTABPR.PVENDAATAC5, PCTABPR.PVENDAATAC6, PCTABPR.PVENDAATAC7 '
               || ' FROM PCTABPR, PCPRODUT '
               || ' WHERE PCTABPR.CODPROD = PCPRODUT.CODPROD '
               || '   AND PCTABPR.NUMREGIAO = :NUMREGIAO '
               || '   AND PCTABPR.CODPROD = :CODPROD '
               || '   AND NVL(PCTABPR.EXCLUIDO,''N'') = ''N''';

            EXECUTE IMMEDIATE v_sql USING p_numregiao, p_codprod;
            COMMIT;
         END IF;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO PCTABPR@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT CODPROD, NUMREGIAO, CODST, PVENDA1, PVENDA2,PVENDA3, PVENDA4, '
            || ' PVENDA5, PVENDA6, PVENDA7, COTAITEM, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3 '
            || ',PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7 '
            || ' FROM PCTABPR '
            || '        WHERE (PCTABPR.DTULTALTPVENDA '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                        || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '


            || '           OR (TRUNC(PCTABPR.DTULTALTERSRVPRC) '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                           || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'' ) ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || ' || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS''))) )) tabela_origem '
            || ' ON (tabela_origem.CODPROD = tabela_destino.CODPROD AND '
            || '     tabela_origem.NUMREGIAO = tabela_destino.NUMREGIAO) '
            || ' WHEN MATCHED THEN '
            || '  UPDATE '
            || ' SET tabela_destino.CODST = tabela_origem.CODST, '
            || '  tabela_destino.PVENDA1 = tabela_origem.PVENDA1, '
            || '  tabela_destino.PVENDA2 = tabela_origem.PVENDA2, '
            || '  tabela_destino.PVENDA3 = tabela_origem.PVENDA3, '
            || '  tabela_destino.PVENDA4 = tabela_origem.PVENDA4, '
            || '  tabela_destino.PVENDA5 = tabela_origem.PVENDA5, '
            || '  tabela_destino.PVENDA6 = tabela_origem.PVENDA6, '
            || '  tabela_destino.PVENDA7 = tabela_origem.PVENDA7, '
            || '  tabela_destino.COTAITEM = tabela_origem.COTAITEM, '
            || '  tabela_destino.PVENDAATAC1 = tabela_origem.PVENDAATAC1, '
            || '  tabela_destino.PVENDAATAC2 = tabela_origem.PVENDAATAC2, '
            || '  tabela_destino.PVENDAATAC3 = tabela_origem.PVENDAATAC3, '
            || '  tabela_destino.PVENDAATAC4 = tabela_origem.PVENDAATAC4, '
            || '  tabela_destino.PVENDAATAC5 = tabela_origem.PVENDAATAC5, '
            || '  tabela_destino.PVENDAATAC6 = tabela_origem.PVENDAATAC6, '
            || '  tabela_destino.PVENDAATAC7 = tabela_origem.PVENDAATAC7 '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (CODPROD, NUMREGIAO, CODST, PVENDA1, PVENDA2,PVENDA3, PVENDA4, '
            || ' PVENDA5, PVENDA6, PVENDA7, COTAITEM, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3 '
            || ',PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7) '
            || ' VALUES (tabela_origem.CODPROD, tabela_origem.NUMREGIAO, tabela_origem.CODST, '
            || ' tabela_origem.PVENDA1, tabela_origem.PVENDA2, tabela_origem.PVENDA3, tabela_origem.PVENDA4, '
            || ' tabela_origem.PVENDA5, tabela_origem.PVENDA6, tabela_origem.PVENDA7, tabela_origem.COTAITEM, '
            || ' tabela_origem.PVENDAATAC1, tabela_origem.PVENDAATAC2, tabela_origem.PVENDAATAC3, tabela_origem.PVENDAATAC4, '
            || ' tabela_origem.PVENDAATAC5, tabela_origem.PVENDAATAC6, tabela_origem.PVENDAATAC7) ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizarprecos;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPrecos
| Objetivo    : Atualizar a tabela PCTABPR. Esta atualição será disparada por um job
|               que obterá os registros através da tabela de fila de atualização PCFILAATTUALIZACX.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_IdSequencial : Identificar sequencial do registros que está armazenado na
|                    tabela PCFILAATTUALIZACX
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     ----------   -----------------------------------------------------
| Augusto Cesar     20/07/2006   Criação da procedure para atualizar a tabela PCTABPR.
| Juliana Teixeira  11/09/2007   Ajuste na procedure para exportar preço de venda por atacado.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarprecos (
      p_dblink         IN   VARCHAR2,
      p_idsequencial   IN   pcclient.numseqatu%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      FOR c_precos IN (SELECT pctabpr.codprod, pctabpr.numregiao,
                              pctabpr.codst, pctabpr.pvenda1,
                              pctabpr.pvenda2, pctabpr.pvenda3,
                              pctabpr.pvenda4, pctabpr.pvenda5,
                              pctabpr.pvenda6, pctabpr.pvenda7,
                              pctabpr.cotaitem, pctabpr.pvendaatac1,
                              pctabpr.pvendaatac2, pctabpr.pvendaatac3,
                              pctabpr.pvendaatac4, pctabpr.pvendaatac5,
                              pctabpr.pvendaatac6, pctabpr.pvendaatac7
                         FROM pctabpr
                        WHERE numseqatu = p_idsequencial)
      LOOP
         v_sql :=
               'SELECT COUNT(*) CONTADOR FROM PCTABPR@'
            || p_dblink
            || ' WHERE PCTABPR.NUMREGIAO = :NUMREGIAO '
            || ' AND PCTABPR.CODPROD = :CODPROD '
            || ' AND ROWNUM = 1';

         EXECUTE IMMEDIATE v_sql
                      INTO v_totalregistros
                     USING c_precos.numregiao, c_precos.codprod;

         -- Verificar se o preço está cadastrado no caixa.
         IF v_totalregistros = 0
         THEN
            -- Caso o preço não esteja cadastrado no caixa deverá ser incluído .
            v_sql :=
                  'INSERT  INTO PCTABPR@'
               || p_dblink
               || '(CODPROD, NUMREGIAO, CODST, PVENDA1, PVENDA2, PVENDA3, PVENDA4 '
               || ',PVENDA5, PVENDA6, PVENDA7, COTAITEM, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3 '
               || ',PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7)  '
               || 'VALUES (:CODPROD, :NUMREGIAO, :CODST, :PVENDA1, :PVENDA2, :PVENDA3, :PVENDA4 '
               || ',:PVENDA5, :PVENDA6, :PVENDA7, :COTAITEM, :PVENDAATAC1, :PVENDAATAC2, :PVENDAATAC3 '
               || ',:PVENDAATAC4, :PVENDAATAC5, :PVENDAATAC6, :PVENDAATAC7)';

            EXECUTE IMMEDIATE v_sql
                        USING c_precos.codprod,
                              c_precos.numregiao,
                              c_precos.codst,
                              c_precos.pvenda1,
                              c_precos.pvenda2,
                              c_precos.pvenda3,
                              c_precos.pvenda4,
                              c_precos.pvenda5,
                              c_precos.pvenda6,
                              c_precos.pvenda7,
                              c_precos.cotaitem,
                              c_precos.pvendaatac1,
                              c_precos.pvendaatac2,
                              c_precos.pvendaatac3,
                              c_precos.pvendaatac4,
                              c_precos.pvendaatac5,
                              c_precos.pvendaatac6,
                              c_precos.pvendaatac7;
         ELSE
            v_sql :=
                  'UPDATE PCTABPR@'
               || p_dblink
               || ' SET CODST = :CODST, PVENDA1 = :PVENDA1, PVENDA2 = :PVENDA2, PVENDA3 = :PVENDA3 '
               || ',PVENDA4 = :PVENDA4, PVENDA5 = :PVENDA5, PVENDA6 = :PVENDA6, PVENDA7 = :PVENDA7 '
               || ',COTITEM = :COTAITEM, PVENDAATCAC1 = :PVENDAATAC1, PVENDAATCAC2 = :PVENDAATAC2 '
               || ',PVENDAATCAC3 = :PVENDAATAC3, PVENDAATCAC4 = :PVENDAATAC4, PVENDAATCAC5 = :PVENDAATAC5 '
               || ',PVENDAATCAC6 = :PVENDAATAC6, PVENDAATCAC7 = :PVENDAATAC7 '
               || ' WHERE CODPROD = :CODPROD '
               || '   AND NUMREGIAO = :NUMREGIAO';

            EXECUTE IMMEDIATE v_sql
                        USING c_precos.codst,
                              c_precos.pvenda1,
                              c_precos.pvenda2,
                              c_precos.pvenda3,
                              c_precos.pvenda4,
                              c_precos.pvenda5,
                              c_precos.pvenda6,
                              c_precos.pvenda7,
                              c_precos.cotaitem,
                              c_precos.codprod,
                              c_precos.numregiao,
                              c_precos.pvendaatac1,
                              c_precos.pvendaatac2,
                              c_precos.pvendaatac3,
                              c_precos.pvendaatac4,
                              c_precos.pvendaatac5,
                              c_precos.pvendaatac6,
                              c_precos.pvendaatac7;
         END IF;
      END LOOP;
      COMMIT;
   END patualizarprecos;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarTributacao
| Objetivo    : Atualizar a tabela PCTRIBUT. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data      Comentário
| -------------     -----------  ------------------------------------------------------
| Augusto Cesar     20/07/2006   Criação da procedure para atualizar a tabela PCTRIBUT.
| Sangelles         29/10/2007   Alteracao para Exportar campo PERCIVAMEX Opcao do Mexico.
| Sangelles         23/11/2007   Retirado PERCIVAMEX pois foi criado PCMEX2000
| Juliana Teixeira  24/11/2008   Tarefa N.73325 - Acrescentado campo PCTRIBUT para projeto aplicar
|                                acrescimo no preco de venda para clientes nao contribuinte.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizartributacao (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCTRIBUT@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCTRIBUT@'
         || p_dblink
         || '(CODST, CODICMTAB, PERDESCCUSTO, CODICM, SITTRIBUT,OBS, IVA '
         || ',ALIQICMS1, ALIQICMS2, PAUTA, CODICMPF, CODFISCAL,CODFISCALINTER '
         || ',CODFISCALPF, CODFISCALINTERPF, CODECF,OBSPF, SITTRIBUTPF '
         || ',PERCBASERED, CALCBCICMSNF,ALIQICMS1FONTE, ALIQICMS2FONTE, IVAFONTE '
         || ',PERCBASEREDSTFONTE, PERBASEREDNRPA, PERCBASEREDCONSUMIDOR '
         || ',UTILIZAPERCBASEREDPF, PERCBASEREDST, USAVALORULTENTBASEST, USAVALORULTENTBASEST2, CODICMTABPF '
         || ',PERACRESCIMOPF) '
         || 'SELECT CODST, CODICMTAB, PERDESCCUSTO, CODICM, SITTRIBUT,OBS, IVA '
         || ',ALIQICMS1, ALIQICMS2, PAUTA, CODICMPF, CODFISCAL,CODFISCALINTER '
         || ',CODFISCALPF, CODFISCALINTERPF, CODECF,OBSPF, SITTRIBUTPF '
         || ',PERCBASERED, CALCBCICMSNF,ALIQICMS1FONTE, ALIQICMS2FONTE, IVAFONTE '
         || ',PERCBASEREDSTFONTE, PERBASEREDNRPA, PERCBASEREDCONSUMIDOR '
         || ',UTILIZAPERCBASEREDPF, PERCBASEREDST, USAVALORULTENTBASEST, USAVALORULTENTBASEST2, CODICMTABPF '
         || ',PERACRESCISMOPF '
         || ' FROM PCTRIBUT';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizartributacao;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarTributacao
| Objetivo    : Atualizar a tabela PCTRIBUT. Esta atualição será disparada por um job
|               que obterá os registros através da tabela de fila de atualização PCFILAATTUALIZACX.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_IdSequencial : Identificar sequencial do registros que está armazenado na
|                    tabela PCFILAATTUALIZACX
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCTRIBUT.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizartributacao (
      p_dblink         IN   VARCHAR2,
      p_idsequencial   IN   pcclient.numseqatu%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      FOR c_tributacao IN (SELECT codst, codicmtab, perdesccusto, codicm,
                                  sittribut, obs, iva, aliqicms1, aliqicms2,
                                  pauta, codicmpf, codfiscal, codfiscalinter,
                                  codfiscalpf, codfiscalinterpf, codecf,
                                  obspf, sittributpf, percbasered,
                                  calcbcicmsnf, aliqicms1fonte,
                                  aliqicms2fonte, ivafonte,
                                  percbaseredstfonte, perbaserednrpa,
                                  percbaseredconsumidor,
                                  utilizapercbaseredpf, percbaseredst
                             FROM pctribut
                            WHERE numseqatu = p_idsequencial)
      LOOP
         v_sql :=
               'SELECT COUNT(*) CONTADOR FROM PCTRIBUT@'
            || p_dblink
            || ' WHERE PCTRIBUT.CODST = :CODST '
            || ' AND ROWNUM = 1';

         EXECUTE IMMEDIATE v_sql
                      INTO v_totalregistros
                     USING c_tributacao.codst;

         -- Verificar se o preço está cadastrado no caixa.
         IF v_totalregistros = 0
         THEN
            -- Caso o preço não esteja cadastrado no caixa deverá ser incluído .
            v_sql :=
                  'INSERT  INTO PCTRIBUT@'
               || p_dblink
               || '(CODST, CODICMTAB, PERDESCCUSTO, CODICM, SITTRIBUT, OBS, IVA '
               || ',ALIQICMS1, ALIQICMS2, PAUTA, CODICMPF, CODFISCAL,CODFISCALINTER '
               || ',CODFISCALPF, CODFISCALINTERPF, CODECF, OBSPF, SITTRIBUTPF '
               || ',PERCBASERED, CALCBCICMSNF, ALIQICMS1FONTE, ALIQICMS2FONTE, IVAFONTE '
               || ',PERCBASEREDSTFONTE, PERBASEREDNRPA, PERCBASEREDCONSUMIDOR '
               || ',UTILIZAPERCBASEREDPF, PERCBASEREDST) '
               || 'VALUES (:CODST, :CODICMTAB, :PERDESCCUSTO, :CODICM, :SITTRIBUT, :OBS, :IVA '
               || ',:ALIQICMS1, :ALIQICMS2, :PAUTA, :CODICMPF, :CODFISCAL, :CODFISCALINTER '
               || ',:CODFISCALPF, :CODFISCALINTERPF, :CODECF, :OBSPF, :SITTRIBUTPF '
               || ',:PERCBASERED, :CALCBCICMSNF, :ALIQICMS1FONTE, :ALIQICMS2FONTE, :IVAFONTE '
               || ',:PERCBASEREDSTFONTE, :PERBASEREDNRPA, :PERCBASEREDCONSUMIDOR '
               || ',:UTILIZAPERCBASEREDPF, :PERCBASEREDST)';

            EXECUTE IMMEDIATE v_sql
                        USING c_tributacao.codst,
                              c_tributacao.codicmtab,
                              c_tributacao.perdesccusto,
                              c_tributacao.codicm,
                              c_tributacao.sittribut,
                              c_tributacao.obs,
                              c_tributacao.iva,
                              c_tributacao.aliqicms1,
                              c_tributacao.aliqicms2,
                              c_tributacao.pauta,
                              c_tributacao.codicmpf,
                              c_tributacao.codfiscal,
                              c_tributacao.codfiscalinter,
                              c_tributacao.codfiscalpf,
                              c_tributacao.codfiscalinterpf,
                              c_tributacao.codecf,
                              c_tributacao.obspf,
                              c_tributacao.sittributpf,
                              c_tributacao.percbasered,
                              c_tributacao.calcbcicmsnf,
                              c_tributacao.aliqicms1fonte,
                              c_tributacao.aliqicms2fonte,
                              c_tributacao.ivafonte,
                              c_tributacao.percbaseredstfonte,
                              c_tributacao.perbaserednrpa,
                              c_tributacao.percbaseredconsumidor,
                              c_tributacao.utilizapercbaseredpf,
                              c_tributacao.percbaseredst;
         ELSE
            v_sql :=
                  'UPDATE PCTRIBUT@'
               || p_dblink
               || 'SET CODICMTAB = :CODICMTAB, PERDESCCUSTO = :PERDESCCUSTO, CODICM = :CODICM, '
               || ' SITTRIBUT = :SITTRIBUT, OBS = :OBS, IVA = :IVA '
               || ',ALIQICMS1 = :ALIQICMS1, ALIQICMS2 = :ALIQICMS2, PAUTA = :PAUTA, CODICMPF = :CODICMPF, CODFISCAL = :CODFISCAL,CODFISCALINTER = :CODFISCALINTER '
               || ',CODFISCALPF = :CODFISCALPF, CODFISCALINTERPF = :CODFISCALINTERPF, CODECF = :CODECF, OBSPF = :OBSPF, SITTRIBUTPF = :SITTRIBUTPF '
               || ',PERCBASERED = :PERCBASERED, CALCBCICMSNF = :CALCBCICMSNF, ALIQICMS1FONTE = :ALIQICMS1FONTE, ALIQICMS2FONTE = :ALIQICMS2FONTE, IVAFONTE = :IVAFONTE '
               || ',PERCBASEREDSTFONTE = :PERCBASEREDSTFONTE, PERBASEREDNRPA = :PERBASEREDNRPA, PERCBASEREDCONSUMIDOR = :PERCBASEREDCONSUMIDOR '
               || ',UTILIZAPERCBASEREDPF = :UTILIZAPERCBASEREDPF, PERCBASEREDST = :PERCBASEREDST '
               || 'WHERE CODST = :CODST';

            EXECUTE IMMEDIATE v_sql
                        USING c_tributacao.codicmtab,
                              c_tributacao.perdesccusto,
                              c_tributacao.codicm,
                              c_tributacao.sittribut,
                              c_tributacao.obs,
                              c_tributacao.iva,
                              c_tributacao.aliqicms1,
                              c_tributacao.aliqicms2,
                              c_tributacao.pauta,
                              c_tributacao.codicmpf,
                              c_tributacao.codfiscal,
                              c_tributacao.codfiscalinter,
                              c_tributacao.codfiscalpf,
                              c_tributacao.codfiscalinterpf,
                              c_tributacao.codecf,
                              c_tributacao.obspf,
                              c_tributacao.sittributpf,
                              c_tributacao.percbasered,
                              c_tributacao.calcbcicmsnf,
                              c_tributacao.aliqicms1fonte,
                              c_tributacao.aliqicms2fonte,
                              c_tributacao.ivafonte,
                              c_tributacao.percbaseredstfonte,
                              c_tributacao.perbaserednrpa,
                              c_tributacao.percbaseredconsumidor,
                              c_tributacao.utilizapercbaseredpf,
                              c_tributacao.percbaseredst,
                              c_tributacao.codst;
         END IF;
      END LOOP;
      COMMIT;
   END patualizartributacao;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPrecoPromo
| Objetivo    : Atualizar a tabela PCPRECOPROM. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data            Comentário
| -------------    -----------    ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCPRECOPROM.
| Juliana Teixeira  01/07/2008    Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  19/03/2009    Tarefa N.80403-Acrescentado pcprecoprom.codusur.
|***********************************************************************************/
   PROCEDURE patualizarprecopromo (
      p_dblink    IN   VARCHAR2,
      p_codprod   IN   pcprecoprom.codprod%TYPE
   )
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      IF (p_codprod = 0)
      THEN
         v_sql := 'DELETE FROM PCPRECOPROM@' || p_dblink;

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCPRECOPROM@'
            || p_dblink
            || '(CODPRECOPROM, CODPROD, CODCLI, NUMREGIAO, FRENTECX, DTINICIOVIGENCIA '
            || ',DTFIMVIGENCIA, PRECOFIXO, CODPLPAGMAX, CODUSUR) '
            || 'SELECT CODPRECOPROM, CODPROD, CODCLI, NUMREGIAO, FRENTECX, DTINICIOVIGENCIA '
            || ',DTFIMVIGENCIA, PRECOFIXO, CODPLPAGMAX, CODUSUR '
            || ' FROM PCPRECOPROM '
            || ' WHERE FRENTECX = ''S'' '
            || ' AND ((TRUNC(SYSDATE) BETWEEN DTINICIOVIGENCIA AND DTFIMVIGENCIA) '
            || ' OR ((DTINICIOVIGENCIA IS NULL) AND (DTFIMVIGENCIA IS NULL)))';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         v_sql :=
               'DELETE FROM PCPRECOPROM@'
            || p_dblink
            || ' WHERE CODPROD = :CODPROD';

         EXECUTE IMMEDIATE v_sql
                     USING p_codprod;

         v_sql :=
               'INSERT /*+ APPEND */ INTO PCPRECOPROM@'
            || p_dblink
            || '(CODPRECOPROM, CODPROD, CODCLI, NUMREGIAO, FRENTECX, DTINICIOVIGENCIA '
            || ',DTFIMVIGENCIA, PRECOFIXO, CODPLPAGMAX) '
            || 'SELECT PCPRECOPROM.CODPRECOPROM, PCPRECOPROM.CODPROD, PCPRECOPROM.CODCLI '
            || ',PCPRECOPROM.NUMREGIAO, PCPRECOPROM.FRENTECX, PCPRECOPROM.DTINICIOVIGENCIA '
            || ',PCPRECOPROM.DTFIMVIGENCIA, PCPRECOPROM.PRECOFIXO, PCPRECOPROM.CODPLPAGMAX '
            || ' FROM PCPRECOPROM '
            || ' WHERE PCPRECOPROM.FRENTECX = ''S'' '
            || ' AND ((TRUNC(SYSDATE) BETWEEN PCPRECOPROM.DTINICIOVIGENCIA AND PCPRECOPROM.DTFIMVIGENCIA) '
            || ' OR ((PCPRECOPROM.DTINICIOVIGENCIA IS NULL) AND (PCPRECOPROM.DTFIMVIGENCIA IS NULL))) '
            || ' AND PCPRECOPROM.CODPROD = :CODPROD';

         EXECUTE IMMEDIATE v_sql USING p_codprod;
         COMMIT;
      END IF;
   END patualizarprecopromo;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarControI
| Objetivo    : Atualizar a tabela PCCONTROI. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006    Criação da procedure para atualizar a tabela PCCONTROI.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarcontroi (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCCONTROI@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCCONTROI@'
         || p_dblink
         || '(CODROTINA, CODCONTROLE, CODUSUARIO, ACESSO) '
         || 'SELECT CODROTINA, CODCONTROLE, CODUSUARIO, ACESSO FROM PCCONTROI';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarcontroi;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPcLib
| Objetivo    : Atualizar a tabela PCLIB. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Juliana Teixeira  22/12/2008    Tarefa N.77074 - Acrescentar validacao de controle de acesso
|                                 para caixas e bancos na tela de sangria da rotina 2075;
|***********************************************************************************/
   PROCEDURE patualizarPclib (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCLIB@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCLIB@'
         || p_dblink
         || '(CODFUNC, CODTABELA, CODIGOA, CODIGON, CODFUNC_LIB, DATA_LIB) '
         || 'SELECT CODFUNC, CODTABELA, CODIGOA, CODIGON, CODFUNC_LIB, DATA_LIB FROM PCLIB';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarPclib;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarCompCestaBasica
| Objetivo    : Atualizar a tabela PCFORMPROD. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel         Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006   Criação da procedure para atualizar a tabela PCFORMPROD.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarcompcestabasica (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCFORMPROD@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCFORMPROD@'
         || p_dblink
         || '(CODPRODACAB, CODPRODMP, QTPRODACAB, QTPRODMP, CODOPER '
         || ',ACEITAFRACAO, BAIXAESTOQUE) '
         || 'SELECT CODPRODACAB, CODPRODMP, QTPRODACAB, QTPRODMP, CODOPER '
         || ',ACEITAFRACAO, BAIXAESTOQUE '
         || ' FROM PCFORMPROD';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarcompcestabasica;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarFilial
| Objetivo    : Atualizar a tabela PCFILIAL. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data      Comentário
| -------------     ----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006   Criação da procedure para atualizar a tabela PCFILIAL.
| Juliana Teixeira  26/02/2008   Acrescentado campo PCFILIAL.USAPRECOETIQPRODPESADO - Tarefa N.58913
|                                Obter da etiqueta dos produtos pesados o preço de venda e não a quantidade
|                                como é padrão da rotina 2075);
| Juliana Teixeira  02/04/2008   Tarefa N.59487 - Acrescentada exportação do campo UTILIZANFE para validar
|                                emissão da nota fiscal na rotina 2075.
| Juliana Teixeira  17/06/2008   Acrescentado campo PCFILIAL.UTILIZAVENDAASSISTIDA.
| Juliana Teixeira  13/08/2008   Tarefa N.57865 - Acrescentado campo PCFILIAL.UTILIZAVENDAPOREMBALAGEM.
| Juliana Teixeira  30/09/2008   Tarefa N.70089 - Acrescentado campo PCFILIAL.TIPOPRECIFICACAO.
| Juliana Teixeira  15/10/2008   Tarefa N.70532 - Acrescentado campo PCFILIAL.PRAZOMAXIMPPEDPENDECF.
| Juliana Teixeira  30/10/2008   Tarefa N.71082/71084 - Acrescentado campo PCFILIAL..
| Juliana Teixeira  24/11/2008   Tarefa N.73325 - Acrescentado campo PCFILIAL para projeto aplicar
|                                acrescimo no preco de venda para clientes nao contribuinte.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  15/01/2009   Tarefa N.76491/76580 - Acrescentado campo PCFILIAL.REGRAARREDONDAMENTOECF.
| Juliana Teixeira  20/01/2009   Tarefa N.76845 - Acrescentado campo PCFILIAL.USACODBARRAEMBALAGEM.
| Juliana Teixeira  04/03/2009   Tarefa N.79540 - Acrescentado campo PCFILIAL.PRECOPOREMBALAGEM.
|***********************************************************************************/
   PROCEDURE patualizarfilial (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCFILIAL@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCFILIAL@'
         || p_dblink
         || '(CODIGO, UF, RAZAOSOCIAL, CIDADE, CODCLICONSUMIDOR, CGC, ENDERECO, BAIRRO '
         || ',USAENDERECOFILIAL, USAPRECOETIQPRODPESADO, USASERVINTERMEDIARIO, UTILIZANFE '
         || ',UTILIZAVENDAASSISTIDA, UTILIZAVENDAPOREMBALAGEM, TIPOIDENTIFICACAOECF, TIPOPRECIFICACAO '
         || ',PRAZOMAXIMPPEDPENDECF, QTMULTIPLAINICIALECF, APLICAPERCVARNAOCONTRIB, APLICAPERCATACNAOCONTRIB '
         || ',USACONSULTACHEQUE, REGRAARREDONDAMENTOECF, USACODBARRAEMBALAGEM, PRECOPOREMBALAGEM, TIPOEXPORTACAO) '
         || 'SELECT CODIGO, UF, RAZAOSOCIAL, CIDADE, CODCLICONSUMIDOR, CGC, ENDERECO, BAIRRO '
         || ',USAENDERECOFILIAL, USAPRECOETIQPRODPESADO, USASERVINTERMEDIARIO, UTILIZANFE '
         || ',UTILIZAVENDAASSISTIDA, UTILIZAVENDAPOREMBALAGEM, TIPOIDENTIFICACAOECF, TIPOPRECIFICACAO '
         || ',PRAZOMAXIMPPEDPENDECF, QTMULTIPLAINICIALECF, APLICAPERCVARNAOCONTRIB, APLICAPERCATACNAOCONTRIB '
         || ',USACONSULTACHEQUE, REGRAARREDONDAMENTOECF, USACODBARRAEMBALAGEM, PRECOPOREMBALAGEM, TIPOEXPORTACAO '
         || 'FROM PCFILIAL';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarfilial;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarRamosAtividade
| Objetivo    : Atualizar a tabela PCATIVI. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     20/07/2006   Criação da procedure para atualizar a tabela PCATIVI.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarramosatividade (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCATIVI@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCATIVI@'
         || p_dblink
         || '(CODATIV, PERCDESC) '
         || 'SELECT CODATIV, PERCDESC '
         || 'FROM PCATIVI';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarramosatividade;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarRegiao
| Objetivo    : Atualizar a tabela PCREGIAO. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel         Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     21/07/2006   Criação da procedure para atualizar a tabela PCREGIAO.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarregiao (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCREGIAO@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCREGIAO@'
         || p_dblink
         || '(NUMREGIAO, REGIAO, PERFRETE, UF, VLFRETEKG, CODFILIAL, SEGMENTO '
         || ',PERFRETETERCEIROS, PERFRETEESPECIAL) '
         || 'SELECT NUMREGIAO, REGIAO, PERFRETE, UF, VLFRETEKG, CODFILIAL, SEGMENTO '
         || ',PERFRETETERCEIROS, PERFRETEESPECIAL '
         || ' FROM PCREGIAO ';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarregiao;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarProduto
| Objetivo    : Atualizar a tabela PCPRODUT.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_NumRegiao : Código de região que será utilizada para atualização.
|   p_DtAtualizacaoBD : Data utilizada para informar a partir de qual data a tabela
|                       PCPRODUT será atualizada.
|   p_TipoAtualizacao : Tipo de atualização: P = Parcial ou T = Total.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     21/07/2006    Criação da procedure para atualizar a tabela PCPRODUT.
| -------------    -----------   ------------------------------------------------------
| Juliana Teixeira  22/01/2007    Tarefa N.37918 Acrescentada coluna aceitavendafracao
|                                 para ser utilizada no pcaux2075 corretamente.
| Juliana Teixeira  11/09/2007    Tarefa N.50027 Acrescentada coluna QTMINIMAATACADO
|                                 para ser utilizada no pcaux2075 corretamente.
| Sângelles Sousa   13/11/2007    Retirado a clausula PCPRODUT.DTEXCLUSAO NOT IS NULL
|                                 Pois estava impossibiltando a venda de mercadoria.
| Juliana Teixeira  01/07/2008    Tarefa N.64471-Acrescentado filtro por um determinado produto (Carga total).
| Juliana Teixeira  17/09/2008    Tarefa N.69098-Ajuste na carga parcial dos dados;
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  30/06/2009    Cliente Sodine - Enviando pcprodut.codmarca;
|***********************************************************************************/
   PROCEDURE patualizarproduto (
      p_dblink            IN   VARCHAR2,
      p_numregiao         IN   pctabpr.numregiao%TYPE DEFAULT 1,
      p_datainicial       IN   DATE DEFAULT NULL,
      p_datafinal         IN   DATE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T',
      p_codprod           IN   pcprodut.codprod%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      IF p_tipoatualizacao = 'T'
      THEN
         IF (p_codprod = 0)
         THEN
            v_sql := 'DELETE FROM PCPRODUT@' || p_dblink;

            EXECUTE IMMEDIATE v_sql;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCPRODUT@'
               || p_dblink
               || '(CODPROD, DESCRICAO, EMBALAGEM, UNIDADE ,PCOMREP1, PESOBRUTO, VOLUME '
               || ',DESCRICAO1 ,CODAUXILIAR, DIRFOTOPROD, PERCIPIVENDA ,OBS, FRETEESPECIAL '
               || ',ACEITAVENDAFRACAO, TIPOMERC, QTMINIMAATACADO, CODMARCA, CODEPTO, CODSEC, CODCATEGORIA) '
               || 'SELECT PCPRODUT.CODPROD, PCPRODUT.DESCRICAO, PCPRODUT.EMBALAGEM, PCPRODUT.UNIDADE '
               || ',PCPRODUT.PCOMREP1, PCPRODUT.PESOBRUTO, PCPRODUT.VOLUME, PCPRODUT.DESCRICAO1 '
               || ',PCPRODUT.CODAUXILIAR, PCPRODUT.DIRFOTOPROD, PCPRODUT.PERCIPIVENDA '
               || ',PCPRODUT.OBS, PCPRODUT.FRETEESPECIAL, PCPRODUT.ACEITAVENDAFRACAO, PCPRODUT.TIPOMERC '
               || ',PCPRODUT.QTMINIMAATACADO, PCPRODUT.CODMARCA,PCPRODUT.CODEPTO, PCPRODUT.CODSEC, PCPRODUT.CODCATEGORIA '
               || ' FROM PCPRODUT, PCTABPR '
               || ' WHERE PCTABPR.NUMREGIAO = :NUMREGIAO '
               || ' AND PCPRODUT.CODPROD = PCTABPR.CODPROD ';

            EXECUTE IMMEDIATE v_sql USING p_numregiao;
            COMMIT;
         ELSE
            v_sql :=
                  'DELETE FROM PCPRODUT@'
               || p_dblink
               || ' WHERE CODPROD = :CODPROD';

            EXECUTE IMMEDIATE v_sql USING p_codprod;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCPRODUT@'
               || p_dblink
               || '(CODPROD, DESCRICAO, EMBALAGEM, UNIDADE ,PCOMREP1, PESOBRUTO, VOLUME '
               || ',DESCRICAO1 ,CODAUXILIAR, DIRFOTOPROD, PERCIPIVENDA ,OBS, FRETEESPECIAL '
               || ',ACEITAVENDAFRACAO, TIPOMERC, QTMINIMAATACADO, CODMARCA, CODEPTO, CODSEC, CODCATEGORIA) '
               || 'SELECT PCPRODUT.CODPROD, PCPRODUT.DESCRICAO, PCPRODUT.EMBALAGEM, PCPRODUT.UNIDADE '
               || ',PCPRODUT.PCOMREP1, PCPRODUT.PESOBRUTO, PCPRODUT.VOLUME, PCPRODUT.DESCRICAO1 '
               || ',PCPRODUT.CODAUXILIAR, PCPRODUT.DIRFOTOPROD, PCPRODUT.PERCIPIVENDA '
               || ',PCPRODUT.OBS, PCPRODUT.FRETEESPECIAL, PCPRODUT.ACEITAVENDAFRACAO, PCPRODUT.TIPOMERC '
               || ',PCPRODUT.QTMINIMAATACADO, PCPRODUT.CODMARCA,PCPRODUT.CODEPTO, PCPRODUT.CODSEC, PCPRODUT.CODCATEGORIA '
               || ' FROM PCPRODUT, PCTABPR '
               || ' WHERE PCTABPR.NUMREGIAO = :NUMREGIAO '
               || ' AND PCTABPR.CODPROD = :CODPROD '
               || ' AND PCPRODUT.CODPROD = PCTABPR.CODPROD ';

            EXECUTE IMMEDIATE v_sql USING p_numregiao, p_codprod;
            COMMIT;
         END IF;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO PCPRODUT@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT CODPROD, DESCRICAO, EMBALAGEM, UNIDADE, PCOMREP1, '
            || ' PESOBRUTO, VOLUME, DESCRICAO1, CODAUXILIAR, DIRFOTOPROD, PERCIPIVENDA, '
            || ' OBS, FRETEESPECIAL, ACEITAVENDAFRACAO, TIPOMERC, QTMINIMAATACADO, CODMARCA, '
            || ' CODEPTO, CODSEC, CODCATEGORIA '
            || ' FROM PCPRODUT '
            || '        WHERE (PCPRODUT.dtcadastro '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                      || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '           OR (PCPRODUT.DTULTALTCOM '
            || '               BETWEEN TRUNC (TO_DATE ( '''||  TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                   || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'') ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || '                                    || '' 23:59:59'',''DD/MM/RRRR HH24:MI:SS'' ) ) ) '

            || '           OR (PCPRODUT.DTULTALTERSRVPRC '
            || '               BETWEEN TRUNC (TO_DATE ( '''||  TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                   || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'') ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || '                                    || '' 23:59:59'',''DD/MM/RRRR HH24:MI:SS'' ) ) ) '

            || '           OR (PCPRODUT.dtexclusao '
            || '               BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR' ) ||''''
            || '                                           || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'' ) ) '
            || '               AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR') ||''''
            || ' || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS''))) )) tabela_origem '
            || ' ON (tabela_origem.CODPROD = tabela_destino.CODPROD) '
            || ' WHEN MATCHED THEN '
            || '  UPDATE '
            || ' SET tabela_destino.DESCRICAO = tabela_origem.DESCRICAO, '
            || '  tabela_destino.EMBALAGEM = tabela_origem.EMBALAGEM, '
            || '  tabela_destino.UNIDADE = tabela_origem.UNIDADE, '
            || '  tabela_destino.PCOMREP1 = tabela_origem.PCOMREP1, '
            || '  tabela_destino.PESOBRUTO = tabela_origem.PESOBRUTO, '
            || '  tabela_destino.VOLUME = tabela_origem.VOLUME, '
            || '  tabela_destino.DESCRICAO1 = tabela_origem.DESCRICAO1, '
            || '  tabela_destino.CODAUXILIAR = tabela_origem.CODAUXILIAR, '
            || '  tabela_destino.DIRFOTOPROD = tabela_origem.DIRFOTOPROD, '
            || '  tabela_destino.PERCIPIVENDA = tabela_origem.PERCIPIVENDA, '
            || '  tabela_destino.OBS = tabela_origem.OBS, '
            || '  tabela_destino.FRETEESPECIAL = tabela_origem.FRETEESPECIAL, '
            || '  tabela_destino.ACEITAVENDAFRACAO = tabela_origem.ACEITAVENDAFRACAO, '
            || '  tabela_destino.TIPOMERC = tabela_origem.TIPOMERC, '
            || '  tabela_destino.QTMINIMAATACADO = tabela_origem.QTMINIMAATACADO, '
            || '  tabela_destino.CODMARCA = tabela_origem.CODMARCA, '
            || '  tabela_destino.CODSEC = tabela_origem.CODSEC, '
            || '  tabela_destino.CODEPTO = tabela_origem.CODEPTO, '
            || '  tabela_destino.CODCATEGORIA = tabela_origem.CODCATEGORIA'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (CODPROD, DESCRICAO, EMBALAGEM, UNIDADE, PCOMREP1, '
            || ' PESOBRUTO, VOLUME, DESCRICAO1, CODAUXILIAR, DIRFOTOPROD, PERCIPIVENDA, '
            || ' OBS, FRETEESPECIAL, ACEITAVENDAFRACAO, TIPOMERC, QTMINIMAATACADO, CODMARCA,CODSEC, CODEPTO, CODCATEGORIA) '
            || ' VALUES (tabela_origem.CODPROD, tabela_origem.DESCRICAO, tabela_origem.EMBALAGEM, '
            || ' tabela_origem.UNIDADE, tabela_origem.PCOMREP1, tabela_origem.PESOBRUTO, '
            || ' tabela_origem.VOLUME, tabela_origem.DESCRICAO1, tabela_origem.CODAUXILIAR, '
            || ' tabela_origem.DIRFOTOPROD, tabela_origem.PERCIPIVENDA, tabela_origem.OBS, '
            || ' tabela_origem.FRETEESPECIAL, tabela_origem.ACEITAVENDAFRACAO, tabela_origem.TIPOMERC, '
            || ' tabela_origem.QTMINIMAATACADO, tabela_origem.CODMARCA, '
            || ' tabela_origem.CODSEC, tabela_origem.CODEPTO, tabela_origem.CODCATEGORIA) ';


         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'DELETE FROM PCPRODUT@'
            || p_dblink
            || ' WHERE DTEXCLUSAO IS NOT NULL';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizarproduto;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarProduto
| Objetivo    : Atualizar a tabela PCPRODUT.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|   p_NumRegiao : Código de região que será utilizada para atualização.
|   p_DtAtualizacaoBD : Data utilizada para informar a partir de qual data a tabela
|                       PCPRODUT será atualizada.
|   p_TipoAtualizacao : Tipo de atualização: P = Parcial ou T = Total.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     21/07/2006    Criação da procedure para atualizar a tabela PCPRODUT.
| -------------    -----------   ------------------------------------------------------
| Juliana Teixeira  22/01/2007    Tarefa N.37918 Acrescentada coluna aceitavendafracao
|                                 para ser utilizada no pcaux2075 corretamente.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
| Juliana Teixeira  30/06/2009    Cliente Sodine - Enviando dados da marca;
|***********************************************************************************/
   PROCEDURE patualizarproduto (
      p_dblink         IN   VARCHAR2,
      p_idsequencial   IN   pcprodut.numseqatu%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      FOR c_produto IN (SELECT pcprodut.codprod, pcprodut.descricao,
                               pcprodut.embalagem, pcprodut.unidade,
                               pcprodut.pcomrep1, pcprodut.pesobruto,
                               pcprodut.volume, pcprodut.descricao1,
                               pcprodut.codauxiliar, pcprodut.dirfotoprod,
                               pcprodut.percipivenda, pcprodut.obs,
                               pcprodut.freteespecial, pcprodut.dtcadastro, 
                               pcprodut.dtultaltcom, pcprodut.dtexclusao,
                               pcprodut.aceitavendafracao, pcprodut.tipomerc,
                               pcprodut.codmarca, pcprodut.codepto, 
                               pcprodut.codsec, pcprodut.codcategoria
                          FROM pcprodut
                         WHERE numseqatu = p_idsequencial)
      LOOP
         v_sql :=
               'SELECT COUNT(*) CONTADOR FROM PCPRODUT@'
            || p_dblink
            || ' WHERE PCPRODUT.CODPROD = :CODPROD '
            || '  AND ROWNUM = 1';

         EXECUTE IMMEDIATE v_sql
                      INTO v_totalregistros
                     USING c_produto.codprod;

         IF v_totalregistros = 0
         THEN
            v_sql :=
                  'INSERT INTO PCPRODUT@'
               || p_dblink
               || '(CODPROD, DESCRICAO, EMBALAGEM, UNIDADE, OBS '
               || ',FRETEESPECIAL, PCOMREP1, PESOBRUTO, VOLUME '
               || ',DESCRICAO1, CODAUXILIAR, DIRFOTOPROD, PERCIPIVENDA '
               || ',ACEITAVENDAFRACAO, TIPOMERC, CODMARCA, CODEPTO,CODSEC, CODCATEGORIA) '
               || 'VALUES (:CODPROD, :DESCRICAO, :EMBALAGEM, :UNIDADE, :OBS '
               || ',:FRETEESPECIAL, :PCOMREP1 , :PESOBRUTO, :VOLUME '
               || ',:DESCRICAO1 ,:CODAUXILIAR, :DIRFOTOPROD, :PERCIPIVENDA '
               || ',:ACEITAVENDAFRACAO, :TIPOMERC, :CODMARCA, :CODEPTO, :CODSEC, :CODCATEGORIA )';

            EXECUTE IMMEDIATE v_sql
                        USING c_produto.codprod,
                              c_produto.descricao,
                              c_produto.embalagem,
                              c_produto.unidade,
                              c_produto.obs,
                              c_produto.freteespecial,
                              c_produto.pcomrep1,
                              c_produto.pesobruto,
                              c_produto.volume,
                              c_produto.descricao1,
                              c_produto.codauxiliar,
                              c_produto.dirfotoprod,
                              c_produto.percipivenda,
                              c_produto.aceitavendafracao,
                              c_produto.tipomerc,
                              c_produto.codmarca,
                              c_produto.codepto,
                              c_produto.codsec,
                              c_produto.codcategoria ;
         ELSE
            v_sql :=
                  'UPDATE PCPRODUT@'
               || p_dblink
               || ' SET DESCRICAO = :DESCRICAO, EMBALAGEM = :EMBALAGEM, UNIDADE = :UNIDADE '
               || ',OBS = :OBS , FRETEESPECIAL = :FRETEESPECIAL, PCOMREP1 = :PCOMREP1 '
               || ',PESOBRUTO = :PESOBRUTO ,VOLUME = :VOLUME, DESCRICAO1 = :DESCRICAO1 '
               || ',CODAUXILIAR = :CODAUXILIAR ,DIRFOTOPROD = :DIRFOTOPROD '
               || ',PERCIPIVENDA = :PERCIPIVENDA, ACEITAVENDAFRACAO = :ACEITAVENDAFRACAO '
               || ',TIPOMERC = :TIPOMERC, CODMARCA = :CODMARCA, CODEPTO = :CODEPTO '
               || ',CODSEC = :CODSEC, CODCATEGORIA = :CODCATEGORIA '
               || 'WHERE CODPROD  = :CODPROD';

            EXECUTE IMMEDIATE v_sql
                        USING c_produto.descricao,
                              c_produto.embalagem,
                              c_produto.unidade,
                              c_produto.obs,
                              c_produto.freteespecial,
                              c_produto.pcomrep1,
                              c_produto.pesobruto,
                              c_produto.volume,
                              c_produto.descricao1,
                              c_produto.codauxiliar,
                              c_produto.dirfotoprod,
                              c_produto.percipivenda,
                              c_produto.codprod,
                              c_produto.aceitavendafracao,
                              c_produto.tipomerc,
                              c_produto.codmarca,
                              c_produto.codepto,
                              c_produto.codsec,
                              c_produto.codcategoria;
         END IF;
      END LOOP;
      COMMIT;
   END patualizarproduto;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarAutorizacao
| Objetivo    : Atualizar a tabela PCAUTORIECF. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar     21/07/2006    Criação da procedure para atualizar a tabela PCAUTORIECF.
| Juliana Teixeira  02/09/2008    Tarefa N.68356-Alterada carga parcial para retirar laco e evitar melhor performance.
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarautorizacao (
      p_dblink            IN   VARCHAR2,
      p_numcaixa          IN   pccaixa.numcaixa%TYPE,
      p_datainicial       IN   DATE DEFAULT NULL,
      p_datafinal         IN   DATE DEFAULT NULL,
      p_tipoatualizacao   IN   VARCHAR2 DEFAULT 'T',
      p_codprod           IN   pcautori.codprod%TYPE
   )
   AS
      v_sql              VARCHAR2 (32767);
      v_totalregistros   NUMBER;
   BEGIN
      IF p_tipoatualizacao = 'T'
      THEN
         IF (p_codprod = 0)
         THEN
            v_sql :=
                  'DELETE FROM PCAUTORI@'
               || p_dblink
               || ' WHERE DATA_UTILIZACAO IS NULL';

            EXECUTE IMMEDIATE v_sql;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCAUTORI@'
               || p_dblink
               || '(NRAUTORIZACAO, DATAAUTORIZACAO, CODUSUR, CODCLI '
               || ',CODPROD, CODPLPAG, PERCDESCAUTOR, DATA_UTILIZACAO '
               || ',CODFUNCUTILIZ, STATUSUTILIZ, PVENDAATUAL, NUMPED '
               || ',PVENDIDO, EXCEDECOTA, CODFUNCCADASTRO, NUMREGIAO '
               || ',CODFILIAL, GERADEBRCA, INICIOINTERVALO, FIMINTERVALO '
               || ',NUMCAIXA, NUMCUPOM, SERIEEQUIP, OBS, QTVENDAECF) '
               || 'SELECT NRAUTORIZACAO, DATAAUTORIZACAO, CODUSUR, CODCLI, '
               || 'CODPROD, CODPLPAG, PERCDESCAUTOR, DATA_UTILIZACAO, '
               || 'CODFUNCUTILIZ, STATUSUTILIZ, PVENDAATUAL, NUMPED, '
               || 'PVENDIDO, EXCEDECOTA, CODFUNCCADASTRO, NUMREGIAO, '
               || 'CODFILIAL, GERADEBRCA, INICIOINTERVALO, FIMINTERVALO, '
               || 'NUMCAIXA, NUMCUPOM, SERIEEQUIP, OBS, QTVENDAECF '
               || 'FROM PCAUTORI '
               || 'WHERE DATA_UTILIZACAO IS NULL '
               || '  AND NUMCAIXA = :NUMCAIXA'||
                  ' AND NOT EXISTS ( SELECT NRAUTORIZACAO FROM PCAUTORI@'||p_Dblink||
                                         ')';
            EXECUTE IMMEDIATE v_sql USING p_numcaixa;
            COMMIT;
         ELSE
            v_sql :=
                  'DELETE FROM PCAUTORI@'
               || p_dblink
               || ' AND CODPROD = :CODPROD '
               || ' WHERE DATA_UTILIZACAO IS NULL';

            EXECUTE IMMEDIATE v_sql USING p_codprod;

            v_sql :=
                  'INSERT /*+ APPEND */ INTO PCAUTORI@'
               || p_dblink
               || '(NRAUTORIZACAO, DATAAUTORIZACAO, CODUSUR, CODCLI '
               || ',CODPROD, CODPLPAG, PERCDESCAUTOR, DATA_UTILIZACAO '
               || ',CODFUNCUTILIZ, STATUSUTILIZ, PVENDAATUAL, NUMPED '
               || ',PVENDIDO, EXCEDECOTA, CODFUNCCADASTRO, NUMREGIAO '
               || ',CODFILIAL, GERADEBRCA, INICIOINTERVALO, FIMINTERVALO '
               || ',NUMCAIXA, NUMCUPOM, SERIEEQUIP, OBS, QTVENDAECF) '
               || 'SELECT NRAUTORIZACAO, DATAAUTORIZACAO, CODUSUR, CODCLI, '
               || 'CODPROD, CODPLPAG, PERCDESCAUTOR, DATA_UTILIZACAO, '
               || 'CODFUNCUTILIZ, STATUSUTILIZ, PVENDAATUAL, NUMPED, '
               || 'PVENDIDO, EXCEDECOTA, CODFUNCCADASTRO, NUMREGIAO, '
               || 'CODFILIAL, GERADEBRCA, INICIOINTERVALO, FIMINTERVALO, '
               || 'NUMCAIXA, NUMCUPOM, SERIEEQUIP, OBS, QTVENDAECF '
               || 'FROM PCAUTORI '
               || 'WHERE DATA_UTILIZACAO IS NULL '
               || '  AND NUMCAIXA = :NUMCAIXA'
               || '  AND CODPROD = :CODPROD';

            EXECUTE IMMEDIATE v_sql USING p_numcaixa, p_codprod;
            COMMIT;
         END IF;
      ELSIF p_tipoatualizacao = 'P'
      THEN
         v_sql :=
               'MERGE INTO PCAUTORI@'
            || p_dblink
            || ' tabela_destino '
            || ' USING (SELECT NRAUTORIZACAO, DATAAUTORIZACAO, CODUSUR, CODCLI, '
            || ' CODPROD, CODPLPAG, PERCDESCAUTOR, DATA_UTILIZACAO, '
            || ' CODFUNCUTILIZ, STATUSUTILIZ, PVENDAATUAL, NUMPED, '
            || ' PVENDIDO, EXCEDECOTA, CODFUNCCADASTRO, NUMREGIAO, '
            || ' CODFILIAL, GERADEBRCA, INICIOINTERVALO, FIMINTERVALO, '
            || ' NUMCAIXA, NUMCUPOM, SERIEEQUIP, OBS, QTVENDAECF '
            || ' FROM PCAUTORI '
            || '        WHERE (    PCAUTORI.DATAAUTORIZACAO '
            || '                   BETWEEN TRUNC (TO_DATE (  '''|| TO_CHAR (p_datainicial, 'DD/MM/RRRR') ||''''
            || '                                        || '' 00:00:00'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || '                              AND TRUNC (TO_DATE (  '''|| TO_CHAR (p_datafinal, 'DD/MM/RRRR' ) ||''''
            || '                                              || '' 23:59:59'', ''DD/MM/RRRR HH24:MI:SS'')) '
            || ' )) tabela_origem '
            || ' ON (tabela_origem.NRAUTORIZACAO = tabela_destino.NRAUTORIZACAO) '
            || ' WHEN MATCHED THEN '
            || '  UPDATE '
            || ' SET tabela_destino.DATAAUTORIZACAO = tabela_origem.DATAAUTORIZACAO, '
            || '  tabela_destino.CODUSUR = tabela_origem.CODUSUR, '
            || '  tabela_destino.CODCLI = tabela_origem.CODCLI, '
            || '  tabela_destino.CODPROD = tabela_origem.CODPROD, '
            || '  tabela_destino.CODPLPAG = tabela_origem.CODPLPAG, '
            || '  tabela_destino.PERCDESCAUTOR = tabela_origem.PERCDESCAUTOR, '
            || '  tabela_destino.DATA_UTILIZACAO = tabela_origem.DATA_UTILIZACAO, '
            || '  tabela_destino.CODFUNCUTILIZ = tabela_origem.CODFUNCUTILIZ, '
            || '  tabela_destino.STATUSUTILIZ = tabela_origem.STATUSUTILIZ, '
            || '  tabela_destino.PVENDAATUAL = tabela_origem.PVENDAATUAL, '
            || '  tabela_destino.NUMPED = tabela_origem.NUMPED, '
            || '  tabela_destino.PVENDIDO = tabela_origem.PVENDIDO, '
            || '  tabela_destino.EXCEDECOTA = tabela_origem.EXCEDECOTA, '
            || '  tabela_destino.CODFUNCCADASTRO = tabela_origem.CODFUNCCADASTRO, '
            || '  tabela_destino.NUMREGIAO = tabela_origem.NUMREGIAO, '
            || '  tabela_destino.CODFILIAL = tabela_origem.CODFILIAL, '
            || '  tabela_destino.GERADEBRCA = tabela_origem.GERADEBRCA, '
            || '  tabela_destino.INICIOINTERVALO = tabela_origem.INICIOINTERVALO, '
            || '  tabela_destino.FIMINTERVALO = tabela_origem.FIMINTERVALO, '
            || '  tabela_destino.NUMCAIXA = tabela_origem.NUMCAIXA, '
            || '  tabela_destino.NUMCUPOM = tabela_origem.NUMCUPOM, '
            || '  tabela_destino.SERIEEQUIP = tabela_origem.SERIEEQUIP, '
            || '  tabela_destino.OBS = tabela_origem.OBS, '
            || '  tabela_destino.QTVENDAECF = tabela_origem.QTVENDAECF '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (NRAUTORIZACAO, DATAAUTORIZACAO, CODUSUR, CODCLI, '
            || ' CODPROD, CODPLPAG, PERCDESCAUTOR, DATA_UTILIZACAO, '
            || ' CODFUNCUTILIZ, STATUSUTILIZ, PVENDAATUAL, NUMPED, '
            || ' PVENDIDO, EXCEDECOTA, CODFUNCCADASTRO, NUMREGIAO, '
            || ' CODFILIAL, GERADEBRCA, INICIOINTERVALO, FIMINTERVALO, '
            || ' NUMCAIXA, NUMCUPOM, SERIEEQUIP, OBS, QTVENDAECF) '
            || ' VALUES (tabela_origem.NRAUTORIZACAO, tabela_origem.DATAAUTORIZACAO, '
            || ' tabela_origem.CODUSUR, tabela_origem.CODCLI, tabela_origem.CODPROD, '
            || ' tabela_origem.CODPLPAG, tabela_origem.PERCDESCAUTOR, tabela_origem.DATA_UTILIZACAO, '
            || ' tabela_origem.CODFUNCUTILIZ, tabela_origem.STATUSUTILIZ, tabela_origem.PVENDAATUAL, '
            || ' tabela_origem.NUMPED, tabela_origem.PVENDIDO, tabela_origem.EXCEDECOTA, '
            || ' tabela_origem.CODFUNCCADASTRO, tabela_origem.NUMREGIAO, tabela_origem.CODFILIAL, '
            || ' tabela_origem.GERADEBRCA, tabela_origem.INICIOINTERVALO, tabela_origem.FIMINTERVALO, '
            || ' tabela_origem.NUMCAIXA, tabela_origem.NUMCUPOM, tabela_origem.SERIEEQUIP, '
            || ' tabela_origem.OBS, tabela_origem.QTVENDAECF) ';

         EXECUTE IMMEDIATE v_sql;
         COMMIT;
      ELSE
         raise_application_error
               (-2001,
                'O tipo de atualização informada não é válida, verifique!\\$'
               );
      END IF;
   END patualizarautorizacao;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarUsuario
| Objetivo    : Atualizar a tabela PCUSUARI. Atualização desta tabela sempre TOTAL.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------     -----------   ------------------------------------------------------
| Augusto Cesar     21/07/2006    Criação da procedure para atualizar a tabela PCUSUARI.
| Sabrina D.        09/09/2006    Ajuste no Insert que estava passando um parametro a mais
| Juliana Teixeira  22/12/2008    Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                 que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarusuario (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCUSUARI@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCUSUARI@'
         || p_dblink
         || ' (CODUSUR, NOME, CODSUPERVISOR, CODFILIAL) '
         || 'SELECT CODUSUR '
         || ',NOME '
         || ',CODSUPERVISOR '
         || ',CODFILIAL '
         || ' FROM PCUSUARI '
         || ' WHERE PCUSUARI.DTTERMINO IS NULL '
         || ' AND NVL(PCUSUARI.AREAATUACAO,''V'')=''V'' ';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarusuario;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarParamDtAtualizacaoBD
| Objetivo    : Atualizar a tabela PCCONSUM.DTATUALIZACAOBD. Após a execução da procedure
|               de carga de todas as tabelas informadas, será atualizado o campo DTATUALIZACAOBD
|               para sinalizar que a carga foi concluída com sucesso.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data          Comentário
| -------------    -----------   ------------------------------------------------------
| Augusto Cesar     21/07/2006   Criação da procedure para atualizar a tabela PCCONSUM.DTATUALIZACAOBD.
| Juliana Teixeira  22/12/2008   Tarefa N.75204 - Acrescentado commit para cada procedimento para evitar
|                                que os dados fiquem na memoria ocasionando lentidao no banco de dados.
|***********************************************************************************/
   PROCEDURE patualizarparamdtatualizacaobd (p_dblink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql :=
           'UPDATE PCCONSUM@' || p_dblink || ' SET DTATUALIZACAOBD = SYSDATE';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END patualizarparamdtatualizacaobd;
/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPcPrecoCestaC
| Objetivo    : Atualizar a tabela PCPRECOCESTAC
| Parametros  :
| p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data         Comentário
| -------------     -----------  ------------------------------------------------------
| Fabricio Cunha     09/09/2009   Tarefa N.85723 - Exportação de preço fixo de cesta básica
|***********************************************************************************/

   PROCEDURE pAtualizarPcPrecoCestaC (p_DbLink IN VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCPRECOCESTAC@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCPRECOCESTAC@'
         || p_dblink
         || '(CODPRECOCESTA, CODPRODACAB, CODFILIAL, NUMREGIAO, CODPLPAG, DTINICIO, DTFIM,'
         || ',DTEXCLUSAO, CODFUNCEXCLUSAO, CODCLI, UTILIZAPRECOFIXOREDE, CODFUNCCADASTRO,'
         || ',DTCADASTRO, CODFUNCULTALTER, DTULTALTER)'

         || 'SELECT CODPRECOCESTA, CODPRODACAB, CODFILIAL, NUMREGIAO, CODPLPAG, DTINICIO, DTFIM'
         || ',DTEXCLUSAO, CODFUNCEXCLUSAO, CODCLI, UTILIZAPRECOFIXOREDE, CODFUNCCADASTRO'
         || ',DTCADASTRO, CODFUNCULTALTER, DTULTALTER FROM PCPRECOCESTAC';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END pAtualizarPcPrecoCestaC;

   /*------------------------------------------------------------------------------------
| Procedimento: pAtualizarPcPrecoCestaI
| Objetivo    : Atualizar a tabela PCPRECOCESTAI
| Parametros  :
| p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel          Data         Comentário
| -------------     -----------  ------------------------------------------------------
| Fabricio Cunha     09/09/2009   Tarefa N.85723 - Exportação de preço fixo de cesta básica ITENS
|***********************************************************************************/

   PROCEDURE pAtualizarPcPrecoCestaI (p_DbLink In VARCHAR2)
   AS
      v_sql   VARCHAR2 (32767);
   BEGIN
      v_sql := 'DELETE FROM PCPRECOCESTAI@' || p_dblink;

      EXECUTE IMMEDIATE v_sql;

      v_sql :=
            'INSERT /*+ APPEND */ INTO PCPRECOCESTAI@'
         || p_dblink
         || '(CODPRECOCESTA, CODPRODACAB, CODPRODMP,PRECOFIXO)'
         || 'SELECT CODPRECOCESTA, CODPRODACAB, CODPRODMP,PRECOFIXO';

      EXECUTE IMMEDIATE v_sql;
      COMMIT;
   END pAtualizarPcPrecoCestaI;

/*------------------------------------------------------------------------------------
| Procedimento: pAtualizarParcialJob
| Objetivo    : Atualizar as tabelas PCCLIENT, PCEMBALAGEM, PCPRODUT, PCTABPR e PCTRIBUT
|               automaticamente a cada execução do job. Estas tabelas serão atualizadas
|               sem a intervenção do usuário, programada através de um job.
| Parametros  :
|   p_DbLink : Nome do database link. Indicará qual o caixa será atualizado.
|------------------------------------------------------------------------------------
|                                Histórico
|------------------------------------------------------------------------------------
| Responsavel        Data          Comentário
| -------------  -----------   ------------------------------------------------------
| Augusto Cesar  21/07/2006    Criação da procedure para atualizar a tabela PCCONSUM.DTATUALIZACAOBD.
|***********************************************************************************/
   PROCEDURE patualizarparcialjob
   AS
      v_totalregistros   NUMBER (1)       := 0;
      v_retorno          VARCHAR2 (32767) := NULL;
      v_sql              VARCHAR2 (200)   := NULL;
   BEGIN
      -- Buscar os caixas que estão cadastrados e que possuem database link criados.
      FOR c_caixa IN (SELECT *
                        FROM pccaixa
                       WHERE EXISTS (
                                SELECT 1
                                  FROM all_db_links
                                 WHERE owner = USER
                                   AND db_link =
                                                'DBLCAIXA' || pccaixa.numcaixa))
      LOOP
         -- Esta consulta é utilizada para verificar se o database link está ativo e comunicável.
         -- As próximas rotinas só serão executadas caso não haja retorno negativo quanto a comunicação com o caixa.
         BEGIN
            v_sql :=
                  'SELECT COUNT(1) '
               || 'FROM PCCONSUM@DBLCAIXA'
               || c_caixa.numcaixa
               || ' WHERE ROWNUM <= 1';

            EXECUTE IMMEDIATE v_sql
                         INTO v_totalregistros;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_retorno :=
                     'Não foi possível estabelecer conexão com o caixa '
                  || c_caixa.numcaixa
                  || ', verifique!'
                  || CHR (13)
                  || SQLERRM;
         END;

         -- Verificar se a variável v_Retorno é NULL.
         -- Caso seja diferente de NULL é porque ocorreu algum erro ao tentar estabelecer
         -- comunicação através do database link.
         IF v_retorno IS NULL
         THEN
            -- Buscar as atualizações dos caixas selecionados.
            FOR c_atualizacao IN (SELECT pcfilaatualizacx.*
                                    FROM pcfilaatualizacx
                                   WHERE indratualizado = 'N'
                                     AND numcaixa = c_caixa.numcaixa)
            LOOP
               -- Verificar qual o nome da tabela para saber qual procedure executar
               -- para atualizar os caixas.
               IF c_atualizacao.nometabela = 'PCCLIENT'
               THEN
                  BEGIN
                     -- Atualizar tabela PCCLIENT
                     pcatualizarbdcaixa.patualizarcliente
                                    (p_dblink            =>    'DBLCAIXA'
                                                            || c_caixa.numcaixa,
                                     p_idsequencial      => c_atualizacao.valorseq
                                    );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_retorno :=
                            v_retorno || 'PCCLIENT - ' || SQLERRM || CHR (13);
                  END;
               ELSIF c_atualizacao.nometabela = 'PCEMBALAGEM'
               THEN
                  BEGIN
                     -- Atualizar tabela PCEMBALAGEM
                     pcatualizarbdcaixa.patualizarembalagem
                                    (p_dblink            =>    'DBLCAIXA'
                                                            || c_caixa.numcaixa,
                                     p_idsequencial      => c_atualizacao.valorseq
                                    );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_retorno :=
                           v_retorno || 'PCEMBALAGEM - ' || SQLERRM
                           || CHR (13);
                  END;
               ELSIF c_atualizacao.nometabela = 'PCPRODUT'
               THEN
                  BEGIN
                     -- Atualizar tabela PCPRODUT
                     pcatualizarbdcaixa.patualizarproduto
                                    (p_dblink            =>    'DBLCAIXA'
                                                            || c_caixa.numcaixa,
                                     p_idsequencial      => c_atualizacao.valorseq
                                    );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_retorno :=
                            v_retorno || 'PCPRODUT - ' || SQLERRM || CHR (13);
                  END;
               ELSIF c_atualizacao.nometabela = 'PCTABPR'
               THEN
                  BEGIN
                     -- Atualizar tabela PCTABPR
                     pcatualizarbdcaixa.patualizarprecos
                                    (p_dblink            =>    'DBLCAIXA'
                                                            || c_caixa.numcaixa,
                                     p_idsequencial      => c_atualizacao.valorseq
                                    );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_retorno :=
                             v_retorno || 'PCTABPR - ' || SQLERRM || CHR (13);
                  END;
               ELSIF c_atualizacao.nometabela = 'PCTRIBUT'
               THEN
                  BEGIN
                     -- Atualizar tabela PCTRIBUT
                     pcatualizarbdcaixa.patualizartributacao
                                    (p_dblink            =>    'DBLCAIXA'
                                                            || c_caixa.numcaixa,
                                     p_idsequencial      => c_atualizacao.valorseq
                                    );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_retorno :=
                            v_retorno || 'PCTRIBUT - ' || SQLERRM || CHR (13);
                  END;
               END IF;

               -- Verificar se a variável v_Retorno é NULL. Se for NULL, é porque foi possível
               -- executar a atualização da tabela sem nenhum erro e neste caso é alterado o
               -- status da tabela de fila para atualizado. Caso seja diferente de NULL, é feito rollback na transação
               -- e a variável v_Retorno será "esvaziada". É neste ponto que deverá ser incluído, se
               -- necessário, o processo de gravação de log de gravação do registro.
               IF v_retorno IS NULL
               THEN
                  UPDATE pcfilaatualizacx
                     SET indratualizado = 'S'
                   WHERE ID = c_atualizacao.ID;

                  COMMIT;
               ELSE
                  v_retorno := NULL;
                  ROLLBACK;
               END IF;
            END LOOP;

            -- Alterar sessão pra fechar database link aberto.
            BEGIN
               v_sql :=
                     'ALTER SESSION CLOSE DATABASE LINK DBLCAIXA'
                  || c_caixa.numcaixa;

               EXECUTE IMMEDIATE v_sql;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         ELSE
            -- Se for preciso, gravar neste ponto na tabela de LOG os possíveis erros
            -- que ocorrerem em função da tentativa de conexão com o database link.
            v_retorno := NULL;
         END IF;
      END LOOP;

      DELETE FROM pcfilaatualizacx
            WHERE indratualizado = 'S';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         raise_application_error
            (-2001,
                'ERRO NA EXECUÇÃO DA PROCEDURE PCATUALIZARBDCAIXA.PATUALIZARPARCIALJOB'
             || CHR (13)
             || SQLERRM
            );
   END patualizarparcialjob;
END pcatualizarbdcaixa;
