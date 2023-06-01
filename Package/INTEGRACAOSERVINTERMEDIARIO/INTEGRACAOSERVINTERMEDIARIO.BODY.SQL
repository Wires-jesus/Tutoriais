
CREATE OR REPLACE PACKAGE BODY INTEGRACAOSERVINTERMEDIARIO
IS
   FUNCTION gerar_arquivo_log (
      pscodfilial     IN   VARCHAR2,
      psnomearquivo   IN   VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vsmsg              VARCHAR2 (1000);
      vsdirectory_path   VARCHAR2 (200);
   BEGIN
      SELECT vw_autoserv_directories.directory_path
        INTO vsdirectory_path
        FROM vw_autoserv_directories
       WHERE vw_autoserv_directories.directory_name LIKE 'AUTOSERV_BAD_DIR%';

      BEGIN
         -- Abre arquivo de log (.out)
         vgarqlog :=
            UTL_FILE.fopen (vsdirectory_path,
                            psnomearquivo || '.out',
                            'w',
                            32000
                           );
         RETURN TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            vsmsg := 'Erro :' || SQLCODE || ' - ' || SQLERRM;
            RETURN FALSE;
      END;
   END gerar_arquivo_log;

   FUNCTION destruir_instancia_exportacao (
      pscodfilial    IN       VARCHAR2,
      psnometabela   IN       VARCHAR2,
      psmensagem     OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql         VARCHAR2 (2000);
      vncontador    NUMBER;
      vsmensagem    VARCHAR2 (1000);
      vbresultado   BOOLEAN;
   BEGIN
      vsmensagem := '';
      vbresultado := TRUE;

      SELECT COUNT (*)
        INTO vncontador
        FROM user_tables
       WHERE LOWER (table_name) LIKE 'exp_' || psnometabela || '%';

      IF vncontador > 0
      THEN
         BEGIN
            v_sql := 'DROP TABLE exp_' || psnometabela;

            EXECUTE IMMEDIATE v_sql;
         EXCEPTION
            WHEN OTHERS
            THEN
               vbresultado := FALSE;
               vsmensagem :=
                     'Erro ao dropar tabela externa exp_'
                  || psnometabela
                  || '. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
         END;
      END IF;

      psmensagem := vsmensagem;
      RETURN vbresultado;
   END destruir_instancia_exportacao;

   FUNCTION destruir_arquivo_exportacao (
      pscodfilial    IN       VARCHAR2,
      psnometabela   IN       VARCHAR2,
      psmensagem     OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vsdirectory_path   VARCHAR2 (200);
      vsnomearquivo      VARCHAR2 (100);
      vbfexists          BOOLEAN;
      vnfile_length      NUMBER;
      vnblock_size       NUMBER;
      vbresultado        BOOLEAN;
      vsmensagem         VARCHAR2 (1000);
   BEGIN
      vbresultado := TRUE;
      vsmensagem := '';
      vsnomearquivo := psnometabela || '_' || pscodfilial || '.dat';

      SELECT vw_autoserv_directories.directory_path
        INTO vsdirectory_path
        FROM vw_autoserv_directories
       WHERE vw_autoserv_directories.directory_name LIKE 'AUTOSERV_DAT_DIR%';

      UTL_FILE.fgetattr (vsdirectory_path,
                         vsnomearquivo,
                         vbfexists,
                         vnfile_length,
                         vnblock_size
                        );

      IF vbfexists
      THEN
         BEGIN
            UTL_FILE.fremove (vsdirectory_path, vsnomearquivo);
         EXCEPTION
            WHEN OTHERS
            THEN
               vsmensagem :=
                     'Erro ao excluir arquivo '
                  || vsnomearquivo
                  || '. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               vbresultado := FALSE;
         END;
      END IF;

      psmensagem := vsmensagem;
      RETURN vbresultado;
   END destruir_arquivo_exportacao;

   FUNCTION checar_arquivo_exportacao (
      pscodfilial    IN   VARCHAR2,
      psnometabela   IN   VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vsdirectory_path   VARCHAR2 (200);
      vsnomearquivo      VARCHAR2 (100);
      vbfexists          BOOLEAN;
      vnfile_length      NUMBER;
      vnblock_size       NUMBER;
   BEGIN
      vsnomearquivo := psnometabela || '_' || pscodfilial || '.dat';

      SELECT vw_autoserv_directories.directory_path
        INTO vsdirectory_path
        FROM vw_autoserv_directories
       WHERE vw_autoserv_directories.directory_name LIKE 'AUTOSERV_DAT_DIR%';

      UTL_FILE.fgetattr (vsdirectory_path,
                         vsnomearquivo,
                         vbfexists,
                         vnfile_length,
                         vnblock_size
                        );

      IF vbfexists
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END checar_arquivo_exportacao;

   FUNCTION checar_arquivo_importacao (
      pscodfilial    IN   VARCHAR2,
      psnometabela   IN   VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vsdirectory_path   VARCHAR2 (200);
      vsnomearquivo      VARCHAR2 (100);
      vbfexists          BOOLEAN;
      vnfile_length      NUMBER;
      vnblock_size       NUMBER;
   BEGIN
      vsnomearquivo := psnometabela || '_' || pscodfilial || '.exp';

      SELECT vw_autoserv_directories.directory_path
        INTO vsdirectory_path
        FROM vw_autoserv_directories
       WHERE vw_autoserv_directories.directory_name LIKE 'AUTOSERV_DAT_DIR%';

      UTL_FILE.fgetattr (vsdirectory_path,
                         vsnomearquivo,
                         vbfexists,
                         vnfile_length,
                         vnblock_size
                        );

      IF vbfexists
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END checar_arquivo_importacao;

   FUNCTION destruir_instancia_importacao (
      pscodfilial    IN       VARCHAR2,
      psnometabela   IN       VARCHAR2,
      psmensagem     OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql           VARCHAR2 (2000);
      vncontador      NUMBER;
      vbresultado     BOOLEAN;
      vbfexists       BOOLEAN;
      vnfile_length   NUMBER;
      vnblock_size    NUMBER;
      vsmensagem      VARCHAR2 (1000);
   BEGIN
      vsmensagem := '';
      vbresultado := TRUE;

      SELECT COUNT (*)
        INTO vncontador
        FROM user_tables
       WHERE LOWER (table_name) LIKE 'imp_' || psnometabela || '%';

      IF vncontador > 0
      THEN
         BEGIN
            v_sql := 'DROP TABLE imp_' || psnometabela;

            EXECUTE IMMEDIATE v_sql;
         EXCEPTION
            WHEN OTHERS
            THEN
               vbresultado := FALSE;
               vsmensagem :=
                     'Erro ao dropar tabela externa imp_'
                  || psnometabela
                  || '. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
         END;
      END IF;

      psmensagem := vsmensagem;
      RETURN vbresultado;
   END destruir_instancia_importacao;

   FUNCTION importar_pcativi (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcativi';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codativ            NUMBER(6,0), '
         || '  ramo               VARCHAR2(40), '
         || '  percdesc           NUMBER(5,2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codativ = s.codativ) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.ramo = s.ramo, d.percdesc = s.percdesc '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codativ, ramo, percdesc) '
            || ' VALUES (s.codativ, s.ramo, s.percdesc)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcativi;

   FUNCTION importar_pcautori (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcautori';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (nrautorizacao                     NUMBER(10,0),'
         || '  dataautorizacao                   DATE,'
         || '  codusur                           NUMBER(4,0),'
         || '  codcli                            NUMBER(6,0),'
         || '  codprod                           NUMBER(10,0),'
         || '  codplpag                          NUMBER(4,0),'
         || '  percdescautor                     NUMBER(18,6),'
         || '  data_utilizacao                   DATE,'
         || '  codfuncutiliz                     NUMBER(8,0),'
         || '  statusutiliz                      VARCHAR2(1),'
         || '  pvendaatual                       NUMBER(18,6),'
         || '  numped                            NUMBER(10,0),'
         || '  pvendido                          NUMBER(12,3),'
         || '  excedecota                        VARCHAR2(1),'
         || '  codfunccadastro                   NUMBER(8,0),'
         || '  numregiao                         NUMBER(4,0),'
         || '  codfilial                         VARCHAR2(2),'
         || '  geradebrca                        VARCHAR2(1),'
         || '  iniciointervalo                   NUMBER(10,4),'
         || '  fimintervalo                      NUMBER(10,4),'
         || '  numcaixa                          NUMBER(4,0),'
         || '  numcupom                          NUMBER(10,0),'
         || '  serieequip                        VARCHAR2(30),'
         || '  basecreddebrca                    VARCHAR2(1),'
         || '  obs                               VARCHAR2(80),'
         || '  qtvendaecf                        NUMBER(20,6),'
         || '  afetaperdesc                      VARCHAR2(1),'
         || '  codauxiliar                       NUMBER(16,0)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.nrautorizacao = s.nrautorizacao) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.dataautorizacao = s.dataautorizacao,'
            || '     d.codusur = s.codusur,'
            || '     d.codcli = s.codcli,'
            || '     d.codprod = s.codprod,'
            || '     d.codplpag = s.codplpag,'
            || '     d.percdescautor = s.percdescautor,'
            || '     d.data_utilizacao = s.data_utilizacao,'
            || '     d.codfuncutiliz = s.codfuncutiliz,'
            || '     d.statusutiliz = s.statusutiliz,'
            || '     d.pvendaatual = s.pvendaatual,'
            || '     d.numped = s.numped,'
            || '     d.pvendido = s.pvendido,'
            || '     d.excedecota = s.excedecota,'
            || '     d.codfunccadastro = s.codfunccadastro,'
            || '     d.numregiao = s.numregiao,'
            || '     d.codfilial = s.codfilial,'
            || '     d.geradebrca = s.geradebrca,'
            || '     d.iniciointervalo = s.iniciointervalo,'
            || '     d.fimintervalo = s.fimintervalo,'
            || '     d.numcaixa = s.numcaixa,'
            || '     d.numcupom = s.numcupom,'
            || '     d.serieequip = s.serieequip,'
            || '     d.basecreddebrca = s.basecreddebrca,'
            || '     d.obs = s.obs,'
            || '     d.qtvendaecf = s.qtvendaecf,'
            || '     d.afetaperdesc = s.afetaperdesc,'
            || '     d.codauxiliar = s.codauxiliar'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (nrautorizacao, dataautorizacao, codusur, codcli, codprod,'
            || '         codplpag, percdescautor, data_utilizacao, codfuncutiliz,'
            || '         statusutiliz, pvendaatual, numped, pvendido, excedecota,'
            || '         codfunccadastro, numregiao, codfilial, geradebrca,'
            || '         iniciointervalo, fimintervalo, numcaixa, numcupom, serieequip,'
            || '         basecreddebrca, obs, qtvendaecf, afetaperdesc, codauxiliar ) '
            || ' VALUES (s.nrautorizacao, s.dataautorizacao, s.codusur, s.codcli, s.codprod,'
            || '         s.codplpag, s.percdescautor, s.data_utilizacao, s.codfuncutiliz,'
            || '         s.statusutiliz, s.pvendaatual, s.numped, s.pvendido, s.excedecota,'
            || '         s.codfunccadastro, s.numregiao, s.codfilial, s.geradebrca,'
            || '         s.iniciointervalo, s.fimintervalo, s.numcaixa, s.numcupom, s.serieequip,'
            || '         s.basecreddebrca, s.obs, s.qtvendaecf, s.afetaperdesc, s.codauxiliar )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcautori;

   FUNCTION importar_pcbanco (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcbanco';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codbanco                   NUMBER(4,0),'
         || '  nome                       VARCHAR2(30),'
         || '  numbanco                   NUMBER(4,0),'
         || '  agencia                    VARCHAR2(6),'
         || '  conta                      VARCHAR2(10),'
         || '  proxnumch                  NUMBER(6,0),'
         || '  codcontabil                NUMBER(10,0),'
         || '  proxnumremessa             NUMBER(7,0),'
         || '  tipocxbco                  VARCHAR2(1),'
         || '  proxnossonumbco            NUMBER(10,0),'
         || '  numcarteira                VARCHAR2(2),'
         || '  numconvenio                NUMBER(10,0),'
         || '  fluxocx                    VARCHAR2(1),'
         || '  contapagmagnetico          VARCHAR2(10),'
         || '  codfilial                  VARCHAR2(2),'
         || '  numcarteira3               VARCHAR2(3),'
         || '  proxnumcustodia            NUMBER(6,0),'
         || '  faixaini                   NUMBER(15,0),'
         || '  faixafim                   NUMBER(15,0),'
         || '  tipocob                    VARCHAR2(2),'
         || '  variacao                   NUMBER(3,0),'
         || '  nomertm                    VARCHAR2(4),'
         || '  agenciaentrega             VARCHAR2(6),'
         || '  numconveniocustodia        NUMBER(10,0),'
         || '  proxnumpagto               NUMBER(10,0),'
         || '  numconveniopagto           NUMBER(10,0),'
         || '  numseqcustodia             NUMBER(5,0),'
         || '  codclientenobanco          VARCHAR2(20),'
         || '  codcontabildni             NUMBER(10,0),'
         || '  codcontabilcobs            NUMBER(10,0),'
         || '  codcontabilchdv            NUMBER(10,0),'
         || '  gerarboleto                VARCHAR2(1),'
         || '  agenciacorrespondente      VARCHAR2(10),'
         || '  numcolsvendor              NUMBER(6,0),'
         || '  numdiasprotesto            VARCHAR2(2),'
         || '  nossonumbcopreimpr         NUMBER(30,0),'
         || '  anoremessa                 NUMBER(4,0),'
         || '  baixatitulonaoacertado     VARCHAR2(1),'
         || '  baixajurosmenorcm          VARCHAR2(1),'
         || '  naobaixajurosmenorcm       VARCHAR2(1),'
         || '  baixatitulosdescfincm      VARCHAR2(1),'
         || '  vltarifabancaria           NUMBER(8,2),'
         || '  usatarifabancariaporbanco  VARCHAR2(1),'
         || '  numcodlayoutcustodia       NUMBER(5,0),'
         || '  codcedente                 VARCHAR2(20),'
         || '  cgcremessa                 VARCHAR2(14),'
         || '  proxnossonumbcoecf         NUMBER(10,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      -- atencao proxnossonumbco = proxnossonumbcoecf
      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codbanco = s.codbanco) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || '    SET d.nome = s.nome,'
            || '        d.numbanco = s.numbanco,'
            || '        d.agencia = s.agencia,'
            || '        d.conta = s.conta,'
            || '        d.proxnumch = s.proxnumch,'
            || '        d.codcontabil = s.codcontabil,'
            || '        d.proxnumremessa = s.proxnumremessa,'
            || '        d.tipocxbco = s.tipocxbco,'
            || '        d.proxnossonumbco = GREATEST(nvl(d.proxnossonumbco,0), nvl(s.proxnossonumbcoecf,0)),'
            || '        d.numcarteira = s.numcarteira,'
            || '        d.numconvenio = s.numconvenio,'
            || '        d.fluxocx = s.fluxocx,'
            || '        d.contapagmagnetico = s.contapagmagnetico,'
            || '        d.codfilial = s.codfilial,'
            || '        d.numcarteira3 = s.numcarteira3,'
            || '        d.proxnumcustodia = s.proxnumcustodia,'
            || '        d.faixaini = s.faixaini,'
            || '        d.faixafim = s.faixafim,'
            || '        d.tipocob = s.tipocob,'
            || '        d.variacao = s.variacao,'
            || '        d.nomertm = s.nomertm,'
            || '        d.agenciaentrega = s.agenciaentrega,'
            || '        d.numconveniocustodia = s.numconveniocustodia,'
            || '        d.proxnumpagto = s.proxnumpagto,'
            || '        d.numconveniopagto = s.numconveniopagto,'
            || '        d.numseqcustodia = s.numseqcustodia,'
            || '        d.codclientenobanco = s.codclientenobanco,'
            || '        d.codcontabildni = s.codcontabildni,'
            || '        d.codcontabilcobs = s.codcontabilcobs,'
            || '        d.codcontabilchdv = s.codcontabilchdv,'
            || '        d.gerarboleto = s.gerarboleto,'
            || '        d.agenciacorrespondente = s.agenciacorrespondente,'
            || '        d.numcolsvendor = s.numcolsvendor,'
            || '        d.numdiasprotesto = s.numdiasprotesto,'
            || '        d.nossonumbcopreimpr = s.nossonumbcopreimpr,'
            || '        d.anoremessa = s.anoremessa,'
            || '        d.baixatitulonaoacertado = s.baixatitulonaoacertado,'
            || '        d.baixajurosmenorcm = s.baixajurosmenorcm,'
            || '        d.naobaixajurosmenorcm = s.naobaixajurosmenorcm,'
            || '        d.baixatitulosdescfincm = s.baixatitulosdescfincm,'
            || '        d.vltarifabancaria = s.vltarifabancaria,'
            || '        d.usatarifabancariaporbanco = s.usatarifabancariaporbanco,'
            || '        d.numcodlayoutcustodia = s.numcodlayoutcustodia,'
            || '        d.codcedente = s.codcedente,'
            || '        d.cgcremessa = s.cgcremessa,'
            || '        d.proxnossonumbcoecf = GREATEST(nvl(d.proxnossonumbco,0), nvl(s.proxnossonumbcoecf,0)) '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT ( codbanco, nome, numbanco, agencia, conta, proxnumch, codcontabil,'
            || '          proxnumremessa, tipocxbco, proxnossonumbco, numcarteira, numconvenio,'
            || '          fluxocx, contapagmagnetico, codfilial, numcarteira3, proxnumcustodia,'
            || '          faixaini, faixafim, tipocob, variacao, nomertm, agenciaentrega,'
            || '          numconveniocustodia, proxnumpagto, numconveniopagto, numseqcustodia,'
            || '          codclientenobanco, codcontabildni, codcontabilcobs, codcontabilchdv,'
            || '          gerarboleto, agenciacorrespondente, numcolsvendor, numdiasprotesto,'
            || '          nossonumbcopreimpr, anoremessa, baixatitulonaoacertado,'
            || '          baixajurosmenorcm, naobaixajurosmenorcm, baixatitulosdescfincm,'
            || '          vltarifabancaria, usatarifabancariaporbanco, numcodlayoutcustodia,'
            || '          codcedente, cgcremessa, proxnossonumbcoecf) '
            || ' VALUES ( s.codbanco, s.nome, s.numbanco, s.agencia, s.conta, s.proxnumch, s.codcontabil,'
            || '          s.proxnumremessa, s.tipocxbco, s.proxnossonumbcoecf, s.numcarteira, s.numconvenio,'
            || '          s.fluxocx, s.contapagmagnetico, s.codfilial, s.numcarteira3, s.proxnumcustodia,'
            || '          s.faixaini, s.faixafim, s.tipocob, s.variacao, s.nomertm, s.agenciaentrega,'
            || '          s.numconveniocustodia, s.proxnumpagto, s.numconveniopagto, s.numseqcustodia,'
            || '          s.codclientenobanco, s.codcontabildni, s.codcontabilcobs, s.codcontabilchdv,'
            || '          s.gerarboleto, s.agenciacorrespondente, s.numcolsvendor, s.numdiasprotesto,'
            || '          s.nossonumbcopreimpr, s.anoremessa, s.baixatitulonaoacertado,'
            || '          s.baixajurosmenorcm, s.naobaixajurosmenorcm, s.baixatitulosdescfincm,'
            || '          s.vltarifabancaria, s.usatarifabancariaporbanco, s.numcodlayoutcustodia,'
            || '          s.codcedente, s.cgcremessa, s.proxnossonumbcoecf)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcbanco;

   FUNCTION importar_pcconsum (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (32767);
      vncontador          NUMBER;
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcconsum';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || '(abastcorretivoautomat VARCHAR2(1),'
         || ' abatefreteprecominimo VARCHAR2(1),'
         || ' abatefretevendabalcao VARCHAR2(1),'
         || ' abaterdescfincomissaorca VARCHAR2(1),'
         || ' abaterimpostoscomissaorca VARCHAR2(1),'
         || ' abaterimpostosdescfin VARCHAR2(1),'
         || ' aceitabktv3 VARCHAR2(1),'
         || ' aceitacnpjexclusivofornec VARCHAR2(1),'
         || ' aceitadescflexprodmonitorado VARCHAR2(1),'
         || ' aceitadescprecofixo VARCHAR2(1),'
         || ' aceitadesctmk VARCHAR2(1),'
         || ' aceitadesdconsumidoroutroscli VARCHAR2(1),'
         || ' aceitapfcontribuinte VARCHAR2(1),'
         || ' aceitavendaaltusur VARCHAR2(1),'
         || ' aceitavendabalcaoestneg VARCHAR2(1),'
         || ' aceitavendabloq VARCHAR2(1),'
         || ' aceitavendapf VARCHAR2(1),'
         || ' aceitavendasemest VARCHAR2(1),'
         || ' acrescimopfcomie VARCHAR2(1),'
         || ' agregarstprodsintegra VARCHAR2(1),'
         || ' aliqicminteroutrasdesp NUMBER(4,2),'
         || ' aliqicmoutrasdesp NUMBER(4,2),'
         || ' alterarcontaajusteest VARCHAR2(1),'
         || ' alterarfilialentpa VARCHAR2(1),'
         || ' alterarnumseqpedido VARCHAR2(2),'
         || ' alterarprecoplpagamento VARCHAR2(1),'
         || ' apenasmiudezachekoutcarreg VARCHAR2(1),'
         || ' aplicaacrescpftv3 VARCHAR2(1),'
         || ' aplicarepassepercbonific VARCHAR2(1),'
         || ' aplicarindicecmv VARCHAR2(1),'
         || ' aplicatxfimautorizacao VARCHAR2(1),'
         || ' areadeapanha VARCHAR2(1),'
         || ' atualizacliultalter1203 VARCHAR2(1),'
         || ' atualizacondcompedcompra VARCHAR2(1),'
         || ' atualizacustoultentransf VARCHAR2(1),'
         || ' atualizaent1122 VARCHAR2(1),'
         || ' atualizaestcontconvembalagem VARCHAR2(1),'
         || ' atualizarpcprodutbonific VARCHAR2(1),'
         || ' autenticaracertocx VARCHAR2(1),'
         || ' autenticardoc VARCHAR2(1),'
         || ' avisafaltaest VARCHAR2(1),'
         || ' baixampnaentpa VARCHAR2(1),'
         || ' basecreddebrcaautori VARCHAR2(1),'
         || ' biometriaparticipasorteiobiro VARCHAR2(1),'
         || ' bloqaplicpercmanutinv VARCHAR2(1),'
         || ' bloqconsistenummapa VARCHAR2(1),'
         || ' bloqdespvlrorc VARCHAR2(1),'
         || ' bloqdevcli VARCHAR2(1),'
         || ' bloqestoquetransf VARCHAR2(1),'
         || ' bloqfornecverbasvencidas VARCHAR2(1),'
         || ' bloqf6pedvendabalcao VARCHAR2(1),'
         || ' bloqitenscorte936 VARCHAR2(1),'
         || ' bloqlibpedcomdesconto VARCHAR2(1),'
         || ' bloqlibpedmargemneg VARCHAR2(1),'
         || ' bloqpedlimcred VARCHAR2(1),'
         || ' bloqprazomdvenda VARCHAR2(1),'
         || ' bloqueaprodent VARCHAR2(1),'
         || ' bloquearendinvent VARCHAR2(1),'
         || ' bloquearentpa VARCHAR2(1),'
         || ' bloquearpedbonific VARCHAR2(1),'
         || ' bloqueiavendaestpendente VARCHAR2(1),'
         || ' bloqueio VARCHAR2(1),'
         || ' bloqvendatp1tpf VARCHAR2(1),'
         || ' bonificaltdebcredrca VARCHAR2(1),'
         || ' calccredicms VARCHAR2(1),'
         || ' calccredpiscofins VARCHAR2(1),'
         || ' calcfreteporitem VARCHAR2(1),'
         || ' calcicmsfomezero VARCHAR2(1),'
         || ' calciofvendorcomposto VARCHAR2(1),'
         || ' calcjurosdesd VARCHAR2(1),'
         || ' calcstpf VARCHAR2(1),'
         || ' calculacustoentpa VARCHAR2(1),'
         || ' calculagirotransf VARCHAR2(1),'
         || ' calcularstcomipi VARCHAR2(1),'
         || ' caminhodir VARCHAR2(30),'
         || ' cartaoparticipasorteiobiro VARCHAR2(1),'
         || ' cep VARCHAR2(9),'
         || ' cfop5929isento VARCHAR2(1),'
         || ' cgc VARCHAR2(20),'
         || ' cgccliexclusivo VARCHAR2(1),'
         || ' checardiasuteistitpgnlib VARCHAR2(1),'
         || ' checkoutmapaemitido VARCHAR2(1),'
         || ' cidade VARCHAR2(15),'
         || ' cobrarvltarifaparc1 VARCHAR2(1),'
         || ' codcliconsumidor NUMBER(6,0),'
         || ' codcobinicial VARCHAR2(4),'
         || ' codcobrancadescfinanceiro VARCHAR2(4),'
         || ' codcontaadiantfor NUMBER(10,0),'
         || ' codcontaamostras NUMBER(10,0),'
         || ' codcontabenefic NUMBER(10,0),'
         || ' codcontabilcf VARCHAR2(10),'
         || ' codcontacomissao NUMBER(10,0),'
         || ' codcontacomissao3 NUMBER(10,0),'
         || ' codcontacustoscartorio NUMBER(10,0),'
         || ' codcontadesccr NUMBER(10,0),'
         || ' codcontadesenvolvimento NUMBER(10,0),'
         || ' codcontadespesaproducao NUMBER(10,0),'
         || ' codcontafaltacaixa NUMBER(10,0),'
         || ' codcontaguiast NUMBER(10,0),'
         || ' codcontajusteest NUMBER(10,0),'
         || ' codcontalp NUMBER(10,0),'
         || ' codcontamanutcusto NUMBER(10,0),'
         || ' codcontantpag NUMBER(10,0),'
         || ' codcontaperda NUMBER(10,0),'
         || ' codcontaperdaestoque NUMBER(10,0),'
         || ' codcontaproducao NUMBER(10,0),'
         || ' codcontaqualidade NUMBER(10,0),'
         || ' codcontarebaixacmv NUMBER(10,0),'
         || ' codcontarebaixacusto NUMBER(10,0),'
         || ' codcontarecdescarga NUMBER(10,0),'
         || ' codcontareqmp NUMBER(10,0),'
         || ' codcontarestcli NUMBER(10,0),'
         || ' codcontarestrca NUMBER(10,0),'
         || ' codcontasobraacerto NUMBER(10,0),'
         || ' codcontasobracaixa NUMBER(10,0),'
         || ' codcontasobramerc NUMBER(10,0),'
         || ' codcontatransftv10 NUMBER(10,0),'
         || ' codcontaverbacmv NUMBER(10,0),'
         || ' codcontaverbafornec NUMBER(10,0),'
         || ' codcontcli NUMBER(10,0),'
         || ' codcontdebv NUMBER(10,0),'
         || ' codcontdescconc NUMBER(10,0),'
         || ' codcontdevcli NUMBER(10,0),'
         || ' codcontemprest NUMBER(10,0),'
         || ' codcontfor NUMBER(10,0),'
         || ' codcontfre NUMBER(10,0),'
         || ' codconticmsantecip NUMBER(10,0),'
         || ' codcontout NUMBER(10,0),'
         || ' codcontpagdiaria NUMBER(10,0),'
         || ' codcontpagjur NUMBER(10,0),'
         || ' codcontrecjur NUMBER(10,0),'
         || ' codfilialcx VARCHAR2(2),'
         || ' codfilialfv VARCHAR2(2),'
         || ' codfiscaldevoutrasdesp NUMBER(8,0),'
         || ' codfiscalfrete NUMBER(6,0),'
         || ' codfiscalfreteent NUMBER(6,0),'
         || ' codfiscalinterdevoutrasdesp NUMBER(8,0),'
         || ' codfiscalinterfrete NUMBER(6,0),'
         || ' codfiscalinterfreteent NUMBER(6,0),'
         || ' codfiscalinteroutrasdesp NUMBER(4,0),'
         || ' codfiscaloutrasdesp NUMBER(4,0),'
         || ' codhistadicomis NUMBER(4,0),'
         || ' codhistfechcomis NUMBER(4,0),'
         || ' codhistfechcomisneg NUMBER(4,0),'
         || ' codmotvisitapadraocallcenter NUMBER(6,0),'
         || ' codplpaginicial NUMBER(4,0),'
         || ' codpracaautomatic VARCHAR2(1),'
         || ' codsetorcallcenter NUMBER(6,0),'
         || ' codsetorcomprador NUMBER(6,0),'
         || ' codsetordiretoria NUMBER(4,2),'
         || ' codsetordiretorio NUMBER(6,0),'
         || ' codsetorembalador NUMBER(6,0),'
         || ' codsetorexped NUMBER(6,0),'
         || ' codsetorfiscalcx NUMBER(6,0),'
         || ' codsetormotorista NUMBER(6,0),'
         || ' codsetoropercx NUMBER(6,0),'
         || ' codusurautomatic VARCHAR2(1),'
         || ' colunafluxocxcr1 VARCHAR2(8),'
         || ' colunafluxocxcr2 VARCHAR2(8),'
         || ' colunafluxocxcr3 VARCHAR2(8),'
         || ' colunafluxocxcr4 VARCHAR2(8),'
         || ' colunafluxocxcr5 VARCHAR2(8),'
         || ' comissaorcatipovenda VARCHAR2(1),'
         || ' condvenda1 VARCHAR2(1),'
         || ' condvenda10 VARCHAR2(1),'
         || ' condvenda11 VARCHAR2(1),'
         || ' condvenda12 VARCHAR2(1),'
         || ' condvenda13 VARCHAR2(1),'
         || ' condvenda14 VARCHAR2(1),'
         || ' condvenda2 VARCHAR2(1),'
         || ' condvenda20 VARCHAR2(1),'
         || ' condvenda3 VARCHAR2(1),'
         || ' condvenda4 VARCHAR2(1),'
         || ' condvenda5 VARCHAR2(1),'
         || ' condvenda6 VARCHAR2(1),'
         || ' condvenda7 VARCHAR2(1),'
         || ' condvenda8 VARCHAR2(1),'
         || ' condvenda9 VARCHAR2(1),'
         || ' consideracmvdevolucao VARCHAR2(1),'
         || ' consideraisentoscomopf VARCHAR2(1),'
         || ' consideraricmsantecipcusto VARCHAR2(1),'
         || ' consolidando VARCHAR2(1),'
         || ' consqtreservrebaixacusto VARCHAR2(1),'
         || ' contalancperda NUMBER(10,0),'
         || ' controlaedicaopedidocompra VARCHAR2(1),'
         || ' controlaprodutivsep VARCHAR2(1),'
         || ' credencialparticipasorteiobiro VARCHAR2(1),'
         || ' custoindustria VARCHAR2(2),'
         || ' deduziravariaestcomdevcli VARCHAR2(1),'
         || ' definirloteop VARCHAR2(1),'
         || ' depositovirtual NUMBER(3,0),'
         || ' desbloqclibxtitulo VARCHAR2(1),'
         || ' desbloquearprodfimos VARCHAR2(1),'
         || ' descvenda VARCHAR2(1),'
         || ' desdcartaofechcarga VARCHAR2(1),'
         || ' desdobrarcadiferente VARCHAR2(1),'
         || ' diasbloqfornecverbasvencidas NUMBER(4,0),'
         || ' dirarquivointegracao VARCHAR2(80),'
         || ' direxportacaofv VARCHAR2(100),'
         || ' dirimportacaofv VARCHAR2(100),'
         || ' dirimportacaofv2 VARCHAR2(100),'
         || ' dirop VARCHAR2(3),'
         || ' dirwinthor VARCHAR2(40),'
         || ' dirwinthorremoto VARCHAR2(40),'
         || ' divideprzadicionalparcelas VARCHAR2(1),'
         || ' dtatualizacaobd DATE,'
         || ' dtexpiracaowinthor DATE,'
         || ' dtprocessamento DATE,'
         || ' dtproxatu DATE,'
         || ' dtproxfechames DATE,'
         || ' dtultimageracaoserasa DATE,'
         || ' dtvalidasefaz DATE,'
         || ' dtvencantdesd VARCHAR2(1),'
         || ' dtvenctk DATE,'
         || ' dtvenctt DATE,'
         || ' dtviradawms DATE,'
         || ' dvobrigatorio VARCHAR2(1),'
         || ' emitepedidovenda VARCHAR2(2),'
         || ' emitindomapa VARCHAR2(1),'
         || ' empresa VARCHAR2(40),'
         || ' enderecacombonusaberto VARCHAR2(1),'
         || ' endereco VARCHAR2(40),'
         || ' enderecoapanhafilial VARCHAR2(1),'
         || ' entrega_futura VARCHAR2(1),'
         || ' enviamensrcalibest VARCHAR2(1),'
         || ' enviarmsgrcacorte VARCHAR2(1),'
         || ' estado VARCHAR2(2),'
         || ' exibirpvenda VARCHAR2(1),'
         || ' exigedtvalidadebonusrm VARCHAR2(1),'
         || ' expedepaletefechadodiretobox VARCHAR2(1),'
         || ' exportandodados VARCHAR2(1),'
         || ' faixafimteor NUMBER(6,2),'
         || ' faixainiteor NUMBER(6,2),'
         || ' faturafilialbroker VARCHAR2(1),'
         || ' fax VARCHAR2(13),'
         || ' fazerinsertpcembalagem VARCHAR2(1),'
         || ' fechabonusemrecibodesc VARCHAR2(1),'
         || ' fechacarregautvendabalcao VARCHAR2(1),'
         || ' formmapa NUMBER(2,0),'
         || ' ftp_conexaopassiva VARCHAR2(1),'
         || ' ftp_ip VARCHAR2(40),'
         || ' ftp_porta NUMBER(6,0),'
         || ' geracontaspagardevcli VARCHAR2(1),'
         || ' gerandomapa VARCHAR2(1),'
         || ' geranftipo8 VARCHAR2(1),'
         || ' geranumloteautomatico CHAR(1),'
         || ' geraparcelamentotef VARCHAR2(1),'
         || ' gerarbrindepedbonific VARCHAR2(1),'
         || ' gerarcreclidevcli VARCHAR2(1),'
         || ' gerardadosreducaoz VARCHAR2(1),'
         || ' gerarnumloteautomaticpa VARCHAR2(1),'
         || ' gerarpcauxlancontasorcam VARCHAR2(1),'
         || ' gerarpcfrete VARCHAR2(1),'
         || ' gerarpclancicmsantecip VARCHAR2(1),'
         || ' gerartrococobdin VARCHAR2(1),'
         || ' geravalercadevmanif VARCHAR2(1),'
         || ' gravapcmensaltcadcli VARCHAR2(1),'
         || ' gravarcotacao VARCHAR2(1),'
         || ' gravarobsclientenopedido VARCHAR2(1),'
         || ' habilitarlanctodadosfrota VARCHAR2(1),'
         || ' histfor VARCHAR2(40),'
         || ' histfre VARCHAR2(40),'
         || ' histout VARCHAR2(40),'
         || ' ie VARCHAR2(20),'
         || ' iecliexclusiva VARCHAR2(1),'
         || ' impcartacobjuros VARCHAR2(1),'
         || ' importandopedidos VARCHAR2(1),'
         || ' impqtbonus VARCHAR2(1),'
         || ' impressaoautomatica VARCHAR2(1),'
         || ' imprimedescontocf VARCHAR2(1),'
         || ' imprimirespelhoentmerc VARCHAR2(1),'
         || ' incdupjurosdesd VARCHAR2(1),'
         || ' incluidesprodapenf VARCHAR2(1),'
         || ' incluircomissaosugpvendacmv VARCHAR2(1),'
         || ' indespelho VARCHAR2(1),'
         || ' indicecustotransf NUMBER(8,4),'
         || ' infnumverbapedbonific VARCHAR2(1),'
         || ' informarecebedorvenda VARCHAR2(1),'
         || ' iniciaropsemem VARCHAR2(1),'
         || ' inserircupom VARCHAR2(1),'
         || ' inserirmapa VARCHAR2(1),'
         || ' inserirreducaoz VARCHAR2(1),'
         || ' iptabpreco VARCHAR2(15),'
         || ' lancardespvendorautomatico VARCHAR2(1),'
         || ' lancarstapenasparc1 VARCHAR2(1),'
         || ' leiturach VARCHAR2(1),'
         || ' liberaestentmerc VARCHAR2(1),'
         || ' liberaestfechbonus VARCHAR2(1),'
         || ' liberarpedidopendente VARCHAR2(1),'
         || ' limcredinicial NUMBER(15,2),'
         || ' limcredinicialpf NUMBER(15,2),'
         || ' limitearredondamento NUMBER(6,2),'
         || ' limparbasecalcentrada VARCHAR2(1),'
         || ' limparobsnfdevol VARCHAR2(1),'
         || ' mantemnossonumbco1210 VARCHAR2(1),'
         || ' mantemnossonumbco402 VARCHAR2(1),'
         || ' margemmin NUMBER(4,2),'
         || ' margemprev NUMBER(6,2),'
         || ' maxdiassemvenda NUMBER(6,0),'
         || ' maxprzmediodesdcp NUMBER(3,0),'
         || ' mensagem1nf VARCHAR2(80),'
         || ' mensagem2nf VARCHAR2(80),'
         || ' mercadoalvo VARCHAR2(6),'
         || ' montando VARCHAR2(1),'
         || ' mostrarpvendasemst VARCHAR2(1),'
         || ' mudacobcliente VARCHAR2(1),'
         || ' mudacobclientedias NUMBER(4,0),'
         || ' naousaenderecomisto VARCHAR2(1),'
         || ' naousarpickingcx VARCHAR2(1),'
         || ' ndiasexpirasenha NUMBER(4,0),'
         || ' numautomaticcli VARCHAR2(1),'
         || ' numautomaticfor VARCHAR2(1),'
         || ' numautomaticprod VARCHAR2(1),'
         || ' numcasasdeccusto NUMBER(2,0),'
         || ' numcasasdecestoque NUMBER(2,0),'
         || ' numcasasdecinventario NUMBER(2,0),'
         || ' numcasasdecproducao NUMBER(2,0),'
         || ' numcasasdecvenda NUMBER(2,0),'
         || ' numcustodiaautomatic VARCHAR2(1),'
         || ' numdiasaltdtentrega NUMBER(4,0),'
         || ' numdiasalteralivro NUMBER(3,0),'
         || ' numdiasatu NUMBER(2,0),'
         || ' numdiasbloqautomatic NUMBER(4,0),'
         || ' numdiasbloqchp NUMBER(2,0),'
         || ' numdiascadclibloqchdv NUMBER(4,0),'
         || ' numdiaschdvbloqcli NUMBER(4,0),'
         || ' numdiascliinativ NUMBER(4,0),'
         || ' numdiasmaxacertarcarga NUMBER(4,0),'
         || ' numdiasmaxbaixarecibo NUMBER(3,0),'
         || ' numdiasmaxcancbordero NUMBER(3,0),'
         || ' numdiasmaxcancnfent NUMBER(2,0),'
         || ' numdiasmaxcancnfsaida NUMBER(2,0),'
         || ' numdiasmaxdesd1210 NUMBER(4,0),'
         || ' numdiasmaxdesd402 NUMBER(4,0),'
         || ' numdiasmaxemissaocp NUMBER(4,0),'
         || ' numdiasmaxemissaonf NUMBER(3,0),'
         || ' numdiasmaxfatura NUMBER(4,0),'
         || ' numdiasmaxprorrog NUMBER(4,0),'
         || ' numdiasmaxvendacliinadimplente NUMBER(6,0),'
         || ' numdiasmindesppag NUMBER(4,0),'
         || ' numdiasminvendabk NUMBER(2,0),'
         || ' numdiaspagchqcancel NUMBER(3,0),'
         || ' numdiaspagtoretro NUMBER(3,0),'
         || ' numdiasuteissemana NUMBER(4,0),'
         || ' numdiasuteistrimestre NUMBER(4,0),'
         || ' numitensos NUMBER(4,0),'
         || ' nummaxnftransf NUMBER(3,0),'
         || ' nummaxtitulosporrecibo NUMBER(3,0),'
         || ' numordabas NUMBER(10,0),'
         || ' numregiaopadrao NUMBER(4,0),'
         || ' numviasfichacp NUMBER(4,0),'
         || ' numviasmapasep NUMBER(2,0),'
         || ' obterpreferenciacliecf VARCHAR2(1),'
         || ' ordemavaliacaocomissaorca NUMBER(2,0),'
         || ' ordemmapa NUMBER(2,0),'
         || ' padraocallcenter VARCHAR2(1),'
         || ' pckabastecido VARCHAR2(1),'
         || ' pedidocompraporpalete VARCHAR2(1),'
         || ' pedidopordistrib VARCHAR2(1),'
         || ' pedvendadepto VARCHAR2(1),'
         || ' perbaseredoutrasdesp NUMBER(8,4),'
         || ' perbasevend NUMBER(6,2),'
         || ' percacrescimobalcao NUMBER(10,6),'
         || ' percacrescimocustofin NUMBER(10,6),'
         || ' percacrescimocustoreal NUMBER(10,6),'
         || ' percapanha NUMBER(6,2),'
         || ' percdifqtent NUMBER(3,0),'
         || ' percicmfrete NUMBER(4,2),'
         || ' percicmfreteent NUMBER(4,2),'
         || ' percicminterfrete NUMBER(4,2),'
         || ' percicminterfreteent NUMBER(4,2),'
         || ' percjurosmora NUMBER(8,4),'
         || ' perclanccredcli NUMBER(8,4),'
         || ' percmaxdesccr NUMBER(5,2),'
         || ' percmaxdescdesd NUMBER(4,2),'
         || ' percmaxjurosmora NUMBER(8,4),'
         || ' percmaxlibestoque NUMBER(12,4),'
         || ' percminjurosmora NUMBER(8,4),'
         || ' perctoleranciaimpureza NUMBER(6,3),'
         || ' perctoleranciainteiro NUMBER(6,3),'
         || ' perctoleranciaquebrado NUMBER(6,3),'
         || ' perctoleranciaumidade NUMBER(6,3),'
         || ' perctoleranciavermelho NUMBER(6,3),'
         || ' perdescmaxbalcao NUMBER(5,2),'
         || ' perdescmediovenda NUMBER(5,2),'
         || ' perdescprom NUMBER(5,2),'
         || ' perexcedelimcred NUMBER(6,2),'
         || ' perguntarsomaqtpedvenda VARCHAR2(1),'
         || ' perlimvendapf NUMBER(8,4),'
         || ' permaxdescautor NUMBER(18,6),'
         || ' permaxdescitemcf NUMBER(5,2),'
         || ' permaxdescvenda NUMBER(5,2),'
         || ' permaxdifentrada NUMBER(5,2),'
         || ' permaxindenizpedido NUMBER(8,4),'
         || ' permaxpcompra NUMBER(5,2),'
         || ' permaxrodape NUMBER(5,2),'
         || ' permaxrodapecheckout NUMBER(8,4),'
         || ' permaxvenda NUMBER(18,6),'
         || ' permindifentrada NUMBER(5,2),'
         || ' permitealtcodcobvenda VARCHAR2(1),'
         || ' permitealtdtvencentmerc VARCHAR2(1),'
         || ' permitealtplpagvenda VARCHAR2(1),'
         || ' permitecodbarraduplicado VARCHAR2(1),'
         || ' permitecomprafornecbloq VARCHAR2(1),'
         || ' permitecrdevfornec VARCHAR2(1),'
         || ' permitedesccr VARCHAR2(1),'
         || ' permitedevolreqnormal VARCHAR2(1),'
         || ' permiteiniciaropsemmp VARCHAR2(1),'
         || ' permitepedcompramultiplo VARCHAR2(1),'
         || ' permitepedcompraunidmaster VARCHAR2(1),'
         || ' permiteplpagtosuperior VARCHAR2(1),'
         || ' permitevariospedidosorcamento VARCHAR2(1),'
         || ' permitevendaecf402 VARCHAR2(1),'
         || ' permitirdescrodapecheckout VARCHAR2(1),'
         || ' permitirdesddevcli VARCHAR2(1),'
         || ' permitirdesdtitvencsemjuros VARCHAR2(1),'
         || ' permitirdivnfduplic VARCHAR2(1),'
         || ' pervendapf NUMBER(8,4),'
         || ' pesomaxpalete NUMBER(10,2),'
         || ' pesosuppalete NUMBER(4,0),'
         || ' pesotransf NUMBER(6,2),'
         || ' prazoadicionalmax NUMBER(5,0),'
         || ' prazoedicaopedidocompra NUMBER(3,0),'
         || ' prazoentrega NUMBER(4,0),'
         || ' prazofatalmed NUMBER(4,0),'
         || ' prazomaxdtentrega NUMBER(3,0),'
         || ' prazomaxvalidade NUMBER(5,2),'
         || ' prazominvalidade NUMBER(5,2),'
         || ' prazovalidadeorcamento NUMBER(4,0),'
         || ' prazovalidadepedbalcao NUMBER(4,0),'
         || ' precoporembalagem VARCHAR2(1),'
         || ' procnumlista NUMBER(6,0),'
         || ' proxcodpraca NUMBER(4,0),'
         || ' proxcodusur NUMBER(4,0),'
         || ' proxnumaplic NUMBER(8,0),'
         || ' proxnumbonus NUMBER(6,0),'
         || ' proxnumbordero NUMBER(10,0),'
         || ' proxnumborderocr NUMBER(10,0),'
         || ' proxnumcar NUMBER(6,0),'
         || ' proxnumcli NUMBER(6,0),'
         || ' proxnumcodbarralote NUMBER(8,0),'
         || ' proxnumconhec NUMBER(8,0),'
         || ' proxnumcontrato NUMBER(6,0),'
         || ' proxnumcustodia NUMBER(6,0),'
         || ' proxnumfornec NUMBER(6,0),'
         || ' proxnumindeniz NUMBER(10,0),'
         || ' proxnuminventrot NUMBER(8,0),'
         || ' proxnumlanc NUMBER(8,0),'
         || ' proxnumlote NUMBER(6,0),'
         || ' proxnumlotecustodia NUMBER(8,0),'
         || ' proxnumloteem NUMBER(6,0),'
         || ' proxnumlotemp NUMBER(6,0),'
         || ' proxnumlotereagente NUMBER(6,0),'
         || ' proxnumlotesa NUMBER(8,0),'
         || ' proxnummanif NUMBER(8,0),'
         || ' proxnumneg NUMBER(10,0),'
         || ' proxnumop NUMBER(8,0),'
         || ' proxnumopi NUMBER(10,0),'
         || ' proxnumorc NUMBER(10,0),'
         || ' proxnumordemtransf NUMBER(6,0),'
         || ' proxnumpcp NUMBER(10,0),'
         || ' proxnumped NUMBER(6,0),'
         || ' proxnumpedtlmk NUMBER(8,0),'
         || ' proxnumpesquisa NUMBER(10,0),'
         || ' proxnumprodut NUMBER(6,0),'
         || ' proxnumrca NUMBER(8,0),'
         || ' proxnumrpa NUMBER(8,0),'
         || ' proxnumsimulacaopcp NUMBER(10,0),'
         || ' proxnumtira NUMBER(8,0),'
         || ' proxnumtrans NUMBER(10,0),'
         || ' proxnumtransavulsa NUMBER(10,0),'
         || ' proxnumtranscrfor NUMBER(8,0),'
         || ' proxnumtransent NUMBER(10,0),'
         || ' proxnumtransop NUMBER(10,0),'
         || ' proxnumtransvenda NUMBER(10,0),'
         || ' proxnumtransvendor NUMBER(8,0),'
         || ' proxnumtranswms NUMBER(10,0),'
         || ' proxnumtroca NUMBER(6,0),'
         || ' proxnumvale NUMBER(6,0),'
         || ' proxnumverba NUMBER(8,0),'
         || ' qtchdvbloqcli NUMBER(4,0),'
         || ' qtdegerlivro NUMBER(2,0),'
         || ' qtdeminimausoasterisco936 NUMBER(6,0),'
         || ' qtmaxunidadepf NUMBER(4,0),'
         || ' qtmesesclassestrelas NUMBER(2,0),'
         || ' qtmesesclassgrupocartao NUMBER(2,0),'
         || ' qtmesesgrupos NUMBER(2,0),'
         || ' rateiodescbaixacr VARCHAR2(1),'
         || ' rebaixacustocomdescfin VARCHAR2(1),'
         || ' rebaixacustoultent VARCHAR2(1),'
         || ' reducaobcisenta VARCHAR2(1),'
         || ' replicarprecoporembalagem VARCHAR2(1),'
         || ' restringenumitensnf VARCHAR2(1),'
         || ' restringenumviasnf VARCHAR2(1),'
         || ' restringenumviaspu VARCHAR2(1),'
         || ' saltarpaginarua VARCHAR2(1),'
         || ' segmentoserasa NUMBER(3,0),'
         || ' senhalogon VARCHAR2(32),'
         || ' separacaoflowrack VARCHAR2(1),'
         || ' siglaespecie VARCHAR2(3),'
         || ' siglaserie VARCHAR2(3),'
         || ' somacomissaocmv VARCHAR2(1),'
         || ' somacompraprevfluxocx VARCHAR2(1),'
         || ' somadescclidescprod VARCHAR2(1),'
         || ' somadespfinitemcf VARCHAR2(1),'
         || ' somaicmsantecipduplic VARCHAR2(1),'
         || ' somaimpostostransf VARCHAR2(1),'
         || ' somaqtpedvenda VARCHAR2(1),'
         || ' somatarifabancduplic VARCHAR2(1),'
         || ' somatarifabancnf VARCHAR2(1),'
         || ' somavltarifaitensnf VARCHAR2(1),'
         || ' somentecodbarrasbonus VARCHAR2(1),'
         || ' somentecodbarrasconfped VARCHAR2(1),'
         || ' sugvenda NUMBER(2,0),'
         || ' tarjamagneticaobrigatoria VARCHAR2(1),'
         || ' taxatabpr VARCHAR2(1),'
         || ' taxa0 NUMBER(8,4),'
         || ' taxa14 NUMBER(8,4),'
         || ' taxa21 NUMBER(8,4),'
         || ' taxa28 NUMBER(8,4),'
         || ' taxa35 NUMBER(8,4),'
         || ' taxa42 NUMBER(8,4),'
         || ' taxa7 NUMBER(8,4),'
         || ' telefone VARCHAR2(13),'
         || ' tempmenflow NUMBER(10,0),'
         || ' tempomaxcancel VARCHAR2(5),'
         || ' temrepos NUMBER(4,0),'
         || ' tipoabasprev VARCHAR2(2),'
         || ' tipoaliqoutrasdesp VARCHAR2(1),'
         || ' tipoaplicindice VARCHAR2(2),'
         || ' tipoaplicrepasse VARCHAR2(2),'
         || ' tipobaixacobmag NUMBER(2,0),'
         || ' tipocalcdescargapal VARCHAR2(1),'
         || ' tipocalcgirodia VARCHAR2(1),'
         || ' tipocalcipi VARCHAR2(2),'
         || ' tipocalcst VARCHAR2(2),'
         || ' tipocalcsulframa VARCHAR2(2),'
         || ' tipocustoajuste VARCHAR2(1),'
         || ' tipocustotransf VARCHAR2(1),'
         || ' tipocusto1322 VARCHAR2(1),'
         || ' tipoembalagem VARCHAR2(1),'
         || ' tipoenderecamento VARCHAR2(1),'
         || ' tipoentregapadraocallcenter VARCHAR2(1),'
         || ' tipogeracaodadospcauxpro VARCHAR2(1),'
         || ' tipomapawmsvendabalcao VARCHAR2(1),'
         || ' tipomascaraenderwms NUMBER(2,0),'
         || ' tiponumnfentrada VARCHAR2(1),'
         || ' tipoordenacaonfsaida VARCHAR2(2),'
         || ' tipoperiodogirodia VARCHAR2(1),'
         || ' tiporelmapa VARCHAR2(1),'
         || ' tipotaxavendor VARCHAR2(1),'
         || ' tipotxboleto VARCHAR2(1),'
         || ' tipovalorgirodia VARCHAR2(1),'
         || ' tipovlminvendabk VARCHAR2(2),'
         || ' tratarrestricaoacrescimo VARCHAR2(1),'
         || ' travavendapf VARCHAR2(1),'
         || ' trocaaltdebcredrca VARCHAR2(1),'
         || ' tx NUMBER(8,6),'
         || ' txiof NUMBER(12,4),'
         || ' txvenda NUMBER(8,6),'
         || ' txvendorcli NUMBER(14,6),'
         || ' updateautmenu VARCHAR2(32),'
         || ' usabcrent VARCHAR2(1),'
         || ' usacancelamentoautomaticoecf VARCHAR2(1),'
         || ' usacategoria VARCHAR2(1),'
         || ' usacestabasicacf VARCHAR2(1),'
         || ' usachavetriplapcpedi VARCHAR2(1),'
         || ' usacomissaoecf VARCHAR2(1),'
         || ' usacomissaoporcliente VARCHAR2(1),'
         || ' usacomissaoporlinhaprod VARCHAR2(1),'
         || ' usacomissaoporrca VARCHAR2(1),'
         || ' usacontrolederecibos VARCHAR2(1),'
         || ' usacontroleemissaonf VARCHAR2(1),'
         || ' usacontrolefornecpedcompra VARCHAR2(1),'
         || ' usaconversaoembalagem VARCHAR2(1),'
         || ' usacreclivendabalcao VARCHAR2(1),'
         || ' usacredrca VARCHAR2(1),'
         || ' usadescporlinhaprod VARCHAR2(1),'
         || ' usadescporquant VARCHAR2(1),'
         || ' usadtdesbloqueiobloqcliinativ VARCHAR2(1),'
         || ' usadvproduto VARCHAR2(1),'
         || ' usaestoquedepfechado VARCHAR2(1),'
         || ' usafechamentocxcego VARCHAR2(1),'
         || ' usaicmsantecippvenda VARCHAR2(1),'
         || ' usamapseprua VARCHAR2(1),'
         || ' usanegfornec VARCHAR2(1),'
         || ' usanfcomplementarbk VARCHAR2(1),'
         || ' usanumcarvendabalcao VARCHAR2(1),'
         || ' usanumnfdevcli VARCHAR2(1),'
         || ' usaoutrasmoedas VARCHAR2(1),'
         || ' usapercdifqtent VARCHAR2(1),'
         || ' usaprecifmenormargemm VARCHAR2(1),'
         || ' usaprodfracunitario VARCHAR2(1),'
         || ' usaprzadicionalvenda VARCHAR2(1),'
         || ' usaptabelacomobase VARCHAR2(1),'
         || ' usardescontovendacodbarra VARCHAR2(1),'
         || ' usareducaocomissaorca VARCHAR2(1),'
         || ' usarenderfornec VARCHAR2(1),'
         || ' usarmovimentahorizontal VARCHAR2(1),'
         || ' usarsenhaexpirada VARCHAR2(1),'
         || ' usartributacaotransftv10 VARCHAR2(1),'
         || ' usasaldocontacorrentedescfin VARCHAR2(1),'
         || ' usaseparacaocxfechada VARCHAR2(1),'
         || ' usatecladogertec VARCHAR2(1),'
         || ' usatribentporuf VARCHAR2(1),'
         || ' usatributacaoporuf VARCHAR2(1),'
         || ' usatrocacomprecovenda VARCHAR2(1),'
         || ' usavalormedioentrada VARCHAR2(1),'
         || ' usawms VARCHAR2(1),'
         || ' usuariologon VARCHAR2(10),'
         || ' utilizaautorcpagar VARCHAR2(1),'
         || ' utilizaboletopreimpr VARCHAR2(1),'
         || ' utilizacheckout936 VARCHAR2(1),'
         || ' utilizacontrolelote VARCHAR2(1),'
         || ' utilizacontrolemedicamentos VARCHAR2(1),'
         || ' utilizaembmaster VARCHAR2(1),'
         || ' utilizaendporfilial VARCHAR2(1),'
         || ' utilizafilialregiaocx VARCHAR2(1),'
         || ' utilizaguiaproprianfent VARCHAR2(1),'
         || ' utilizaliberacaopedcompra VARCHAR2(1),'
         || ' utilizaorcvenda VARCHAR2(1),'
         || ' utilizapcusurfornec VARCHAR2(1),'
         || ' utilizapercbaseredpf VARCHAR2(1),'
         || ' utilizapercfinprecoprom VARCHAR2(1),'
         || ' utilizaqtfracionadaconf VARCHAR2(1),'
         || ' utilizarateiodespesas VARCHAR2(1),'
         || ' utilizarembunitsintegra VARCHAR2(1),'
         || ' utilizavendaporembalagem VARCHAR2(1),'
         || ' validadvcodbarra VARCHAR2(1),'
         || ' validaestoquemapasep VARCHAR2(1),'
         || ' validanumserieequipecf VARCHAR2(1),'
         || ' validaprecominimo VARCHAR2(1),'
         || ' validapvendabonific VARCHAR2(1),'
         || ' validarestricoesvendaporrca VARCHAR2(1),'
         || ' validarieconsumidorfinal VARCHAR2(1),'
         || ' validaruffilial VARCHAR2(1),'
         || ' validarvlminvendaaposcorte VARCHAR2(1),'
         || ' validavlminvendabalcao VARCHAR2(1),'
         || ' valor_frete_padrao NUMBER(10,2),'
         || ' valormaxfaltacaixa NUMBER(12,2),'
         || ' valorsangria1 NUMBER(12,2),'
         || ' valorsangria2 NUMBER(12,2),'
         || ' vercobrancabloqcli504_16_17 VARCHAR2(1),'
         || ' verificadatahoraecf VARCHAR2(1),'
         || ' verificadescfinbaixacm VARCHAR2(1),'
         || ' verificaestoquecont VARCHAR2(1),'
         || ' verificalimcredcodcobd VARCHAR2(1),'
         || ' verificamargemlibpedido VARCHAR2(1),'
         || ' verificanivelvenda402 VARCHAR2(1),'
         || ' verificapedbonificentnormal VARCHAR2(1),'
         || ' verificapesomaxpalete VARCHAR2(1),'
         || ' verificapickingarm VARCHAR2(1),'
         || ' verificarclientesrede VARCHAR2(1),'
         || ' verificarenderocupado VARCHAR2(1),'
         || ' verificarlimvendapf VARCHAR2(1),'
         || ' verifpermissaocobrnodesdobr402 VARCHAR2(1),'
         || ' verlanctobcochq VARCHAR2(1),'
         || ' vlbloqchd3 NUMBER(12,2),'
         || ' vldiferenca NUMBER(10,2),'
         || ' vlmaxpedidopf NUMBER(18,2),'
         || ' vlmaxtarifabanc NUMBER(14,2),'
         || ' vlmaxvenda NUMBER(16,3),'
         || ' vlmaxvendapf NUMBER(16,3),'
         || ' vlmaxvendatlmkcodcobd NUMBER(12,2),'
         || ' vlmincanccupom NUMBER(18,6),'
         || ' vlmincancitemcupom NUMBER(18,6),'
         || ' vlmintarifabanc NUMBER(10,2),'
         || ' vlminvenda NUMBER(12,2),'
         || ' vlminvendabk NUMBER(12,2),'
         || ' vlminvendatv3 NUMBER(18,6),'
         || ' vlpaletedescarg NUMBER(10,2),'
         || ' vlpesodescarga NUMBER(10,2),'
         || ' vlpesodescargapal NUMBER(10,2),'
         || ' vlremontedescarga NUMBER(12,6),'
         || ' vltarifa NUMBER(8,2),'
         || ' vlvoldescarga NUMBER(10,2),'
         || ' vlvolumedescargafd NUMBER(10,2),'
         || ' volumepalete NUMBER(6,0),'
         || ' volumetransf NUMBER(6,2),'
         || ' zeralimcredbloqautomatic VARCHAR2(1))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         SELECT COUNT (*)
           INTO vncontador
           FROM pcconsum;

         IF vncontador = 0
         THEN
            v_sql :=
                  'INSERT INTO '
               || vstabela
               || ' (empresa) '
               || 'SELECT s.empresa FROM IMP_'
               || vstabela
               || ' s ';

            EXECUTE IMMEDIATE v_sql;
         END IF;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET abatefretevendabalcao = (SELECT s.abatefretevendabalcao FROM IMP_'
            || vstabela
            || ' s),'
            || '     abaterdescfincomissaorca = (SELECT s.abaterdescfincomissaorca FROM IMP_'
            || vstabela
            || ' s),'
            || '     abaterimpostoscomissaorca = (SELECT s.abaterimpostoscomissaorca FROM IMP_'
            || vstabela
            || ' s),'
            || '     abaterimpostosdescfin = (SELECT s.abaterimpostosdescfin FROM IMP_'
            || vstabela
            || ' s),'
            || '     aceitadescprecofixo = (SELECT s.aceitadescprecofixo FROM IMP_'
            || vstabela
            || ' s),'
            || '     aceitapfcontribuinte = (SELECT s.aceitapfcontribuinte FROM IMP_'
            || vstabela
            || ' s),'
            || '     aceitavendabalcaoestneg = (SELECT s.aceitavendabalcaoestneg FROM IMP_'
            || vstabela
            || ' s),'
            || '     aceitavendapf = (SELECT s.aceitavendapf FROM IMP_'
            || vstabela
            || ' s),'
            || '     acrescimopfcomie = (SELECT s.acrescimopfcomie FROM IMP_'
            || vstabela
            || ' s),'
            || '     aliqicminteroutrasdesp = (SELECT s.aliqicminteroutrasdesp FROM IMP_'
            || vstabela
            || ' s),'
            || '     aliqicmoutrasdesp = (SELECT s.aliqicmoutrasdesp FROM IMP_'
            || vstabela
            || ' s),'
            || '     aplicatxfimautorizacao = (SELECT s.aplicatxfimautorizacao FROM IMP_'
            || vstabela
            || ' s),'
            || '     atualizaestcontconvembalagem = (SELECT s.atualizaestcontconvembalagem FROM IMP_'
            || vstabela
            || ' s),'
            || '     autenticaracertocx = (SELECT s.autenticaracertocx FROM IMP_'
            || vstabela
            || ' s),'
            || '     autenticardoc = (SELECT s.autenticardoc FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET bloqprazomdvenda = (SELECT s.bloqprazomdvenda FROM IMP_'
            || vstabela
            || ' s),'
            || '     bloqvendatp1tpf = (SELECT s.bloqvendatp1tpf FROM IMP_'
            || vstabela
            || ' s),'
            || '     calccredicms = (SELECT s.calccredicms FROM IMP_'
            || vstabela
            || ' s),'
            || '     calccredpiscofins = (SELECT s.calccredpiscofins FROM IMP_'
            || vstabela
            || ' s),'
            || '     calcfreteporitem = (SELECT s.calcfreteporitem FROM IMP_'
            || vstabela
            || ' s),'
            || '     calcstpf = (SELECT s.calcstpf FROM IMP_'
            || vstabela
            || ' s),'
            || '     calcularstcomipi = (SELECT s.calcularstcomipi FROM IMP_'
            || vstabela
            || ' s),'
            || '     caminhodir = (SELECT s.caminhodir FROM IMP_'
            || vstabela
            || ' s),'
            || '     cep = (SELECT s.cep FROM IMP_'
            || vstabela
            || ' s),'
            || '     cgc = (SELECT s.cgc FROM IMP_'
            || vstabela
            || ' s),'
            || '     cidade = (SELECT s.cidade FROM IMP_'
            || vstabela
            || ' s),'
            || '     codcliconsumidor = (SELECT s.codcliconsumidor FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET codcontafaltacaixa = (SELECT s.codcontafaltacaixa FROM IMP_'
            || vstabela
            || ' s),'
            || '     codcontasobraacerto = (SELECT s.codcontasobraacerto FROM IMP_'
            || vstabela
            || ' s),'
            || '     codcontasobracaixa = (SELECT s.codcontasobracaixa FROM IMP_'
            || vstabela
            || ' s),'
            || '     codcontcli = (SELECT s.codcontcli FROM IMP_'
            || vstabela
            || ' s),'
            || '     codfilialcx = (SELECT s.codfilialcx FROM IMP_'
            || vstabela
            || ' s),'
            || '     codfiscalfrete = (SELECT s.codfiscalfrete FROM IMP_'
            || vstabela
            || ' s),'
            || '     codfiscalinterfrete = (SELECT s.codfiscalinterfrete FROM IMP_'
            || vstabela
            || ' s),'
            || '     codfiscalinteroutrasdesp = (SELECT s.codfiscalinteroutrasdesp FROM IMP_'
            || vstabela
            || ' s),'
            || '     codfiscaloutrasdesp = (SELECT s.codfiscaloutrasdesp FROM IMP_'
            || vstabela
            || ' s),'
            || '     codsetorfiscalcx = (SELECT s.codsetorfiscalcx FROM IMP_'
            || vstabela
            || ' s),'
            || '     codsetormotorista = (SELECT s.codsetormotorista FROM IMP_'
            || vstabela
            || ' s),'
            || '     codsetoropercx = (SELECT s.codsetoropercx FROM IMP_'
            || vstabela
            || ' s),'
            || '     comissaorcatipovenda = (SELECT s.comissaorcatipovenda FROM IMP_'
            || vstabela
            || ' s),'
            || '     consideraisentoscomopf = (SELECT s.consideraisentoscomopf FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET dirwinthor = (SELECT s.dirwinthor FROM IMP_'
            || vstabela
            || ' s),'
            || '     dtatualizacaobd = (SELECT s.dtatualizacaobd FROM IMP_'
            || vstabela
            || ' s),'
            || '     dtexpiracaowinthor = (SELECT s.dtexpiracaowinthor FROM IMP_'
            || vstabela
            || ' s),'
            || '     dtprocessamento = (SELECT s.dtprocessamento FROM IMP_'
            || vstabela
            || ' s),'
            || '     dtproxatu = (SELECT s.dtproxatu FROM IMP_'
            || vstabela
            || ' s),'
            || '     dtproxfechames = (SELECT s.dtproxfechames FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET empresa = (SELECT s.empresa FROM IMP_'
            || vstabela
            || ' s),'
            || '     endereco = (SELECT s.endereco FROM IMP_'
            || vstabela
            || ' s),'
            || '     estado = (SELECT s.estado FROM IMP_'
            || vstabela
            || ' s),'
            || '     fax = (SELECT s.fax FROM IMP_'
            || vstabela
            || ' s),'
            || '     geraparcelamentotef = (SELECT s.geraparcelamentotef FROM IMP_'
            || vstabela
            || ' s),'
            || '     gerardadosreducaoz = (SELECT s.gerardadosreducaoz FROM IMP_'
            || vstabela
            || ' s),'
            || '     gerartrococobdin = (SELECT s.gerartrococobdin FROM IMP_'
            || vstabela
            || ' s),'
            || '     ie = (SELECT s.ie FROM IMP_'
            || vstabela
            || ' s),'
            || '     iecliexclusiva = (SELECT s.iecliexclusiva FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET impressaoautomatica = (SELECT s.impressaoautomatica FROM IMP_'
            || vstabela
            || ' s),'
            || '     imprimedescontocf = (SELECT s.imprimedescontocf FROM IMP_'
            || vstabela
            || ' s),'
            || '     incluidesprodapenf = (SELECT s.incluidesprodapenf FROM IMP_'
            || vstabela
            || ' s),'
            || '     inserircupom = (SELECT s.inserircupom FROM IMP_'
            || vstabela
            || ' s),'
            || '     inserirmapa = (SELECT s.inserirmapa FROM IMP_'
            || vstabela
            || ' s),'
            || '     inserirreducaoz = (SELECT s.inserirreducaoz FROM IMP_'
            || vstabela
            || ' s),'
            || '     leiturach = (SELECT s.leiturach FROM IMP_'
            || vstabela
            || ' s),'
            || '     mantemnossonumbco1210 = (SELECT s.mantemnossonumbco1210 FROM IMP_'
            || vstabela
            || ' s),'
            || '     mantemnossonumbco402 = (SELECT s.mantemnossonumbco402 FROM IMP_'
            || vstabela
            || ' s),'
            || '     mensagem1nf = (SELECT s.mensagem1nf FROM IMP_'
            || vstabela
            || ' s),'
            || '     mensagem2nf = (SELECT s.mensagem2nf FROM IMP_'
            || vstabela
            || ' s),'
            || '     mostrarpvendasemst = (SELECT s.mostrarpvendasemst FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET ndiasexpirasenha = (SELECT s.ndiasexpirasenha FROM IMP_'
            || vstabela
            || ' s),'
            || '     numcasasdeccusto = (SELECT s.numcasasdeccusto FROM IMP_'
            || vstabela
            || ' s),'
            || '     numcasasdecestoque = (SELECT s.numcasasdecestoque FROM IMP_'
            || vstabela
            || ' s),'
            || '     numcasasdecvenda = (SELECT s.numcasasdecvenda FROM IMP_'
            || vstabela
            || ' s),'
            || '     numdiasatu = (SELECT s.numdiasatu FROM IMP_'
            || vstabela
            || ' s),'
            || '     numdiasmaxcancnfsaida = (SELECT s.numdiasmaxcancnfsaida FROM IMP_'
            || vstabela
            || ' s),'
            || '     numdiasmaxemissaocp = (SELECT s.numdiasmaxemissaocp FROM IMP_'
            || vstabela
            || ' s),'
            || '     numdiasmaxemissaonf = (SELECT s.numdiasmaxemissaonf FROM IMP_'
            || vstabela
            || ' s),'
            || '     numregiaopadrao = (SELECT s.numregiaopadrao FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET obterpreferenciacliecf = (SELECT s.obterpreferenciacliecf FROM IMP_'
            || vstabela
            || ' s),'
            || '     ordemavaliacaocomissaorca = (SELECT s.ordemavaliacaocomissaorca FROM IMP_'
            || vstabela
            || ' s),'
            || '     perbaseredoutrasdesp = (SELECT s.perbaseredoutrasdesp FROM IMP_'
            || vstabela
            || ' s),'
            || '     percicmfrete = (SELECT s.percicmfrete FROM IMP_'
            || vstabela
            || ' s),'
            || '     percicminterfrete = (SELECT s.percicminterfrete FROM IMP_'
            || vstabela
            || ' s),'
            || '     percjurosmora = (SELECT s.percjurosmora FROM IMP_'
            || vstabela
            || ' s),'
            || '     perdescmediovenda = (SELECT s.perdescmediovenda FROM IMP_'
            || vstabela
            || ' s),'
            || '     perlimvendapf = (SELECT s.perlimvendapf FROM IMP_'
            || vstabela
            || ' s),'
            || '     permaxdescautor = (SELECT s.permaxdescautor FROM IMP_'
            || vstabela
            || ' s),'
            || '     permaxdescitemcf = (SELECT s.permaxdescitemcf FROM IMP_'
            || vstabela
            || ' s),'
            || '     permaxdescvenda = (SELECT s.permaxdescvenda FROM IMP_'
            || vstabela
            || ' s),'
            || '     permaxrodapecheckout = (SELECT s.permaxrodapecheckout FROM IMP_'
            || vstabela
            || ' s),'
            || '     permitecodbarraduplicado = (SELECT s.permitecodbarraduplicado FROM IMP_'
            || vstabela
            || ' s),'
            || '     permitevariospedidosorcamento = (SELECT s.permitevariospedidosorcamento FROM IMP_'
            || vstabela
            || ' s),'
            || '     permitirdescrodapecheckout = (SELECT s.permitirdescrodapecheckout FROM IMP_'
            || vstabela
            || ' s),'
            || '     pervendapf = (SELECT s.pervendapf FROM IMP_'
            || vstabela
            || ' s),'
            || '     prazovalidadeorcamento = (SELECT s.prazovalidadeorcamento FROM IMP_'
            || vstabela
            || ' s),'
            || '     precoporembalagem = (SELECT s.precoporembalagem FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET restringenumitensnf = (SELECT s.restringenumitensnf FROM IMP_'
            || vstabela
            || ' s),'
            || '     restringenumviasnf = (SELECT s.restringenumviasnf FROM IMP_'
            || vstabela
            || ' s),'
            || '     senhalogon = (SELECT s.senhalogon FROM IMP_'
            || vstabela
            || ' s),'
            || '     somacomissaocmv = (SELECT s.somacomissaocmv FROM IMP_'
            || vstabela
            || ' s),'
            || '     somadespfinitemcf = (SELECT s.somadespfinitemcf FROM IMP_'
            || vstabela
            || ' s),'
            || '     somaicmsantecipduplic = (SELECT s.somaicmsantecipduplic FROM IMP_'
            || vstabela
            || ' s),'
            || '     somatarifabancduplic = (SELECT s.somatarifabancduplic FROM IMP_'
            || vstabela
            || ' s),'
            || '     somavltarifaitensnf = (SELECT s.somavltarifaitensnf FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET telefone = (SELECT s.telefone FROM IMP_'
            || vstabela
            || ' s),'
            || '     tipoaliqoutrasdesp = (SELECT s.tipoaliqoutrasdesp FROM IMP_'
            || vstabela
            || ' s),'
            || '     tipocalcipi = (SELECT s.tipocalcipi FROM IMP_'
            || vstabela
            || ' s),'
            || '     tipocalcst = (SELECT s.tipocalcst FROM IMP_'
            || vstabela
            || ' s),'
            || '     tipocalcsulframa = (SELECT s.tipocalcsulframa FROM IMP_'
            || vstabela
            || ' s),'
            || '     tipoordenacaonfsaida = (SELECT s.tipoordenacaonfsaida FROM IMP_'
            || vstabela
            || ' s),'
            || '     tipotxboleto = (SELECT s.tipotxboleto FROM IMP_'
            || vstabela
            || ' s),'
            || '     travavendapf = (SELECT s.travavendapf FROM IMP_'
            || vstabela
            || ' s),'
            || '     tx = (SELECT s.tx FROM IMP_'
            || vstabela
            || ' s),'
            || '     txvenda = (SELECT s.txvenda FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET usacancelamentoautomaticoecf = (SELECT s.usacancelamentoautomaticoecf FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacategoria = (SELECT s.usacategoria FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacestabasicacf = (SELECT s.usacestabasicacf FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacomissaoecf = (SELECT s.usacomissaoecf FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacomissaoporcliente = (SELECT s.usacomissaoporcliente FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacomissaoporlinhaprod = (SELECT s.usacomissaoporlinhaprod FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacomissaoporrca = (SELECT s.usacomissaoporrca FROM IMP_'
            || vstabela
            || ' s),'
            || '     usacontroleemissaonf = (SELECT s.usacontroleemissaonf FROM IMP_'
            || vstabela
            || ' s),'
            || '     usaconversaoembalagem = (SELECT s.usaconversaoembalagem FROM IMP_'
            || vstabela
            || ' s),'
            || '     usadescporquant = (SELECT s.usadescporquant FROM IMP_'
            || vstabela
            || ' s),'
            || '     usadvproduto = (SELECT s.usadvproduto FROM IMP_'
            || vstabela
            || ' s),'
            || '     usafechamentocxcego = (SELECT s.usafechamentocxcego FROM IMP_'
            || vstabela
            || ' s),'
            || '     usanumcarvendabalcao = (SELECT s.usanumcarvendabalcao FROM IMP_'
            || vstabela
            || ' s),'
            || '     usaprodfracunitario = (SELECT s.usaprodfracunitario FROM IMP_'
            || vstabela
            || ' s),'
            || '     usarsenhaexpirada = (SELECT s.usarsenhaexpirada FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET usatecladogertec = (SELECT s.usatecladogertec FROM IMP_'
            || vstabela
            || ' s),'
            || '     usatributacaoporuf = (SELECT s.usatributacaoporuf FROM IMP_'
            || vstabela
            || ' s),'
            || '     usawms = (SELECT s.usawms FROM IMP_'
            || vstabela
            || ' s),'
            || '     usuariologon = (SELECT s.usuariologon FROM IMP_'
            || vstabela
            || ' s),'
            || '     utilizafilialregiaocx = (SELECT s.utilizafilialregiaocx FROM IMP_'
            || vstabela
            || ' s),'
            || '     utilizaorcvenda = (SELECT s.utilizaorcvenda FROM IMP_'
            || vstabela
            || ' s),'
            || '     utilizapercbaseredpf = (SELECT s.utilizapercbaseredpf FROM IMP_'
            || vstabela
            || ' s),'
            || '     utilizapercfinprecoprom = (SELECT s.utilizapercfinprecoprom FROM IMP_'
            || vstabela
            || ' s),'
            || '     utilizavendaporembalagem = (SELECT s.utilizavendaporembalagem FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         v_sql :=
               'UPDATE '
            || vstabela
            || ' SET validadvcodbarra = (SELECT s.validadvcodbarra FROM IMP_'
            || vstabela
            || ' s),'
            || '     validanumserieequipecf = (SELECT s.validanumserieequipecf FROM IMP_'
            || vstabela
            || ' s),'
            || '     validarieconsumidorfinal = (SELECT s.validarieconsumidorfinal FROM IMP_'
            || vstabela
            || ' s),'
            || '     validaruffilial = (SELECT s.validaruffilial FROM IMP_'
            || vstabela
            || ' s),'
            || '     valormaxfaltacaixa = (SELECT s.valormaxfaltacaixa FROM IMP_'
            || vstabela
            || ' s),'
            || '     valorsangria1 = (SELECT s.valorsangria1 FROM IMP_'
            || vstabela
            || ' s),'
            || '     valorsangria2 = (SELECT s.valorsangria2 FROM IMP_'
            || vstabela
            || ' s),'
            || '     verificadatahoraecf = (SELECT s.verificadatahoraecf FROM IMP_'
            || vstabela
            || ' s),'
            || '     verificaestoquecont = (SELECT s.verificaestoquecont FROM IMP_'
            || vstabela
            || ' s),'
            || '     verificalimcredcodcobd = (SELECT s.verificalimcredcodcobd FROM IMP_'
            || vstabela
            || ' s),'
            || '     verificarclientesrede = (SELECT s.verificarclientesrede FROM IMP_'
            || vstabela
            || ' s),'
            || '     verificarlimvendapf = (SELECT s.verificarlimvendapf FROM IMP_'
            || vstabela
            || ' s),'
            || '     vldiferenca = (SELECT s.vldiferenca FROM IMP_'
            || vstabela
            || ' s),'
            || '     vlmaxpedidopf = (SELECT s.vlmaxpedidopf FROM IMP_'
            || vstabela
            || ' s),'
            || '     vlmaxtarifabanc = (SELECT s.vlmaxtarifabanc FROM IMP_'
            || vstabela
            || ' s),'
            || '     vlmincanccupom = (SELECT s.vlmincanccupom FROM IMP_'
            || vstabela
            || ' s),'
            || '     vlmincancitemcupom = (SELECT s.vlmincancitemcupom FROM IMP_'
            || vstabela
            || ' s),'
            || '     vlmintarifabanc = (SELECT s.vlmintarifabanc FROM IMP_'
            || vstabela
            || ' s),'
            || '     vltarifa = (SELECT s.vltarifa FROM IMP_'
            || vstabela
            || ' s)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcconsum;

   FUNCTION importar_pcfilial (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcfilial';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (aceitavendasemest VARCHAR2(1),'
         || ' aliqicminteroutrasdesp NUMBER(4,2),'
         || ' aliqicmoutrasdesp NUMBER(4,2),'
         || ' aliquotafreteest NUMBER(2,0),'
         || ' areavenda NUMBER(10,4),'
         || ' atacadista VARCHAR2(1),'
         || ' atividade VARCHAR2(50),'
         || ' autoservico VARCHAR2(1),'
         || ' bairro VARCHAR2(20),'
         || ' broker VARCHAR2(1),'
         || ' cae VARCHAR2(30),'
         || ' calccredicmcustocont CHAR(1),'
         || ' calccredicms VARCHAR2(1),'
         || ' calccredipi VARCHAR2(1),'
         || ' calccredpiscofins VARCHAR2(1),'
         || ' calccredpiscustocont CHAR(1),'
         || ' calcredpisfrete VARCHAR2(1),'
         || ' calcredpisfretecont VARCHAR2(1),'
         || ' calcularcomissaopvenda1 VARCHAR2(1),'
         || ' cep VARCHAR2(11),'
         || ' cgc VARCHAR2(14),'
         || ' cgctransp VARCHAR2(20),'
         || ' cidade VARCHAR2(30),'
         || ' cidadetransp VARCHAR2(20),'
         || ' codcli NUMBER(6,0),'
         || ' codcliconsumidor NUMBER(6,0),'
         || ' codcontador NUMBER(5,0),'
         || ' codcontaentimportacao NUMBER(10,0),'
         || ' coddocdevfornec NUMBER(8,0),'
         || ' coddocdevol NUMBER(8,0),'
         || ' coddocentradamerc NUMBER(8,0),'
         || ' coddocnf NUMBER(8,0),'
         || ' coddocnfc NUMBER(8,0),'
         || ' coddocsr NUMBER(8,0),'
         || ' coddocss NUMBER(8,0),'
         || ' coddoctransf NUMBER(8,0),'
         || ' codestado NUMBER(2,0),'
         || ' codfilialprefestbalcao VARCHAR2(2),'
         || ' codfilialprefesttlmk VARCHAR2(2),'
         || ' codfilialproducao VARCHAR2(2),'
         || ' codfiscaldevoutrasdesp NUMBER(10,0),'
         || ' codfiscalinterdevoutrasdesp NUMBER(10,0),'
         || ' codfiscalinteroutrasdesp NUMBER(4,0),'
         || ' codfiscaloutrasdesp NUMBER(4,0),'
         || ' codfornec NUMBER(6,0),'
         || ' codgrupo VARCHAR2(2),'
         || ' codgrupofilial NUMBER(5,0),'
         || ' codigo VARCHAR2(2),'
         || ' codmun NUMBER(10,0),'
         || ' codpais NUMBER(4,0),'
         || ' codregistro VARCHAR2(20),'
         || ' codsocio NUMBER(5,0),'
         || ' consideraricmsantecipcusto VARCHAR2(1),'
         || ' contato VARCHAR2(30),'
         || ' dtfimatividade DATE,'
         || ' dtiniatividade DATE,'
         || ' dtregistro DATE,'
         || ' eanemissor NUMBER(14,0),'
         || ' email VARCHAR2(100),'
         || ' endereco VARCHAR2(40),'
         || ' endtransp VARCHAR2(40),'
         || ' exigiremissaomapabalcao VARCHAR2(1),'
         || ' fantasia VARCHAR2(25),'
         || ' fax VARCHAR2(18),'
         || ' gerarnsu VARCHAR2(1),'
         || ' gerarnumloteautomaticpa VARCHAR2(1),'
         || ' ie VARCHAR2(20),'
         || ' iesubsttrib VARCHAR2(15),'
         || ' ietransp VARCHAR2(20),'
         || ' im VARCHAR2(20),'
         || ' incluiritempcembalagem VARCHAR2(1),'
         || ' industria VARCHAR2(1),'
         || ' ipisomentevlcont VARCHAR2(1),'
         || ' limparbasecalcentrada VARCHAR2(1),'
         || ' mensnf VARCHAR2(60),'
         || ' montando VARCHAR2(1),'
         || ' nomepais VARCHAR2(40),'
         || ' numcontratocorreio NUMBER(8,0),'
         || ' numdiasvencfrete NUMBER(4,0),'
         || ' numero NUMBER(6,0),'
         || ' numero2 VARCHAR2(6),'
         || ' numidf VARCHAR2(30),'
         || ' numidfdevcli VARCHAR2(30),'
         || ' numproxvend NUMBER(10,0),'
         || ' numregiao NUMBER(4,0),'
         || ' numregiaopadrao NUMBER(4,0),'
         || ' numseqentr NUMBER(4,0),'
         || ' operadorlogistico VARCHAR2(1),'
         || ' opisentosicmsaltocusto VARCHAR2(1),'
         || ' orgao VARCHAR2(20),'
         || ' perbaseredoutrasdesp NUMBER(8,4),'
         || ' percaltercustoent NUMBER(8,4),'
         || ' percdespadm NUMBER(10,4),'
         || ' perfreteconhec NUMBER(8,4),'
         || ' permitecredicmcomst VARCHAR2(1),'
         || ' permitirvendaestadualpfcomie VARCHAR2(1),'
         || ' permitirvendaestadualpfsemie VARCHAR2(1),'
         || ' permitirvendainterestadualpf VARCHAR2(1),'
         || ' pervendapf NUMBER(8,4),'
         || ' precoporembalagem VARCHAR2(1),'
         || ' prodporetapa CHAR(1),'
         || ' proxnsu NUMBER(10,0),'
         || ' proxnumaverbacao NUMBER(10,0),'
         || ' proxnumcarecf NUMBER(10,0),'
         || ' proxnumconhec NUMBER(10,0),'
         || ' proxnumentmex NUMBER(10,0),'
         || ' proxnumeroorcamento NUMBER(8,0),'
         || ' proxnumetapa NUMBER(10,0),'
         || ' proxnumlote NUMBER(4,0),'
         || ' proxnumnfdevcli NUMBER(10,0),'
         || ' proxnumnota NUMBER(10,0),'
         || ' proxnumnotad NUMBER(10,0),'
         || ' proxnumnotaecf NUMBER(10,0),'
         || ' proxnumnotatransf NUMBER(10,0),'
         || ' proxnumorc NUMBER(10,0),'
         || ' proxnumorcafilial NUMBER(10,0),'
         || ' proxnumprevenda NUMBER(10,0),'
         || ' proxnumtransconhec NUMBER(10,0),'
         || ' proxnumtransvendaecf NUMBER(10,0),'
         || ' razaosocial VARCHAR2(40),'
         || ' razaotransp VARCHAR2(40),'
         || ' somatarifabancduplic VARCHAR2(1),'
         || ' taxa0 NUMBER(8,4),'
         || ' taxa14 NUMBER(8,4),'
         || ' taxa21 NUMBER(8,4),'
         || ' taxa28 NUMBER(8,4),'
         || ' taxa35 NUMBER(8,4),'
         || ' taxa42 NUMBER(8,4),'
         || ' taxa7 NUMBER(8,4),'
         || ' telefone VARCHAR2(18),'
         || ' tipobroker VARCHAR2(3),'
         || ' tiponummapa VARCHAR2(1),'
         || ' tiponumnfentrada VARCHAR2(1),'
         || ' uf VARCHAR2(2),'
         || ' uftransp VARCHAR2(2),'
         || ' usacontrolelocalizacaoveiculo VARCHAR2(1),'
         || ' usadistrib VARCHAR2(1),'
         || ' usaenderecofilial VARCHAR2(1),'
         || ' usaestoquedepfechado VARCHAR2(1),'
         || ' usaprecoetiqprodpesado VARCHAR2(1),'
         || ' usanumnfdevcli VARCHAR2(1),'
         || ' usanumnotaecf VARCHAR2(1),'
         || ' usaservintermediario VARCHAR2(1),'
         || ' usawms VARCHAR2(1),'
         || ' utilizapercbaseredoutrasdesppf VARCHAR2(1),'
         || ' utilizavendaporembalagem VARCHAR2(1),'
         || ' validaendpickingpedcompra VARCHAR2(1),'
         || ' validavlmaxisencaostpf VARCHAR2(1),'
         || ' valorcapital NUMBER(10,2),'
         || ' vlmaxisencaostpf NUMBER(12,2),'
         || ' vlmaxtarifabanc NUMBER(14,2),'
         || ' vlmintarifabanc NUMBER(10,2),'
         || ' vltarifa NUMBER(8,2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      -- Atencao proxnumnota = proxnumnotaecf
      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codigo = s.codigo) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET  '
            || ' d.aceitavendasemest = s.aceitavendasemest ,'
            || ' d.aliqicminteroutrasdesp = s.aliqicminteroutrasdesp ,'
            || ' d.aliqicmoutrasdesp = s.aliqicmoutrasdesp ,'
            || ' d.aliquotafreteest = s.aliquotafreteest ,'
            || ' d.areavenda = s.areavenda ,'
            || ' d.atacadista = s.atacadista ,'
            || ' d.atividade = s.atividade ,'
            || ' d.autoservico = s.autoservico ,'
            || ' d.bairro = s.bairro ,'
            || ' d.broker = s.broker ,'
            || ' d.cae = s.cae ,'
            || ' d.calccredicmcustocont = s.calccredicmcustocont ,'
            || ' d.calccredicms = s.calccredicms ,'
            || ' d.calccredipi = s.calccredipi ,'
            || ' d.calccredpiscofins = s.calccredpiscofins ,'
            || ' d.calccredpiscustocont = s.calccredpiscustocont ,'
            || ' d.calcredpisfrete = s.calcredpisfrete ,'
            || ' d.calcredpisfretecont = s.calcredpisfretecont ,'
            || ' d.calcularcomissaopvenda1 = s.calcularcomissaopvenda1 ,'
            || ' d.cep = s.cep ,'
            || ' d.cgc = s.cgc ,'
            || ' d.cgctransp = s.cgctransp ,'
            || ' d.cidade = s.cidade ,'
            || ' d.cidadetransp = s.cidadetransp ,'
            || ' d.codcli = s.codcli ,'
            || ' d.codcliconsumidor = s.codcliconsumidor ,'
            || ' d.codcontador = s.codcontador ,'
            || ' d.codcontaentimportacao = s.codcontaentimportacao ,'
            || ' d.coddocdevfornec = s.coddocdevfornec ,'
            || ' d.coddocdevol = s.coddocdevol ,'
            || ' d.coddocentradamerc = s.coddocentradamerc ,'
            || ' d.coddocnf = s.coddocnf ,'
            || ' d.coddocnfc = s.coddocnfc ,'
            || ' d.coddocsr = s.coddocsr ,'
            || ' d.coddocss = s.coddocss ,'
            || ' d.coddoctransf = s.coddoctransf ,'
            || ' d.codestado = s.codestado ,'
            || ' d.codfilialprefestbalcao = s.codfilialprefestbalcao ,'
            || ' d.codfilialprefesttlmk = s.codfilialprefesttlmk ,'
            || ' d.codfilialproducao = s.codfilialproducao ,'
            || ' d.codfiscaldevoutrasdesp = s.codfiscaldevoutrasdesp ,'
            || ' d.codfiscalinterdevoutrasdesp = s.codfiscalinterdevoutrasdesp ,'
            || ' d.codfiscalinteroutrasdesp = s.codfiscalinteroutrasdesp ,'
            || ' d.codfiscaloutrasdesp = s.codfiscaloutrasdesp ,'
            || ' d.codfornec = s.codfornec ,'
            || ' d.codgrupo = s.codgrupo ,'
            || ' d.codgrupofilial = s.codgrupofilial ,'
            || ' d.codmun = s.codmun ,'
            || ' d.codpais = s.codpais ,'
            || ' d.codregistro = s.codregistro ,'
            || ' d.codsocio = s.codsocio ,'
            || ' d.consideraricmsantecipcusto = s.consideraricmsantecipcusto ,'
            || ' d.contato = s.contato ,'
            || ' d.dtfimatividade = s.dtfimatividade ,'
            || ' d.dtiniatividade = s.dtiniatividade ,'
            || ' d.dtregistro = s.dtregistro ,'
            || ' d.eanemissor = s.eanemissor ,'
            || ' d.email = s.email ,'
            || ' d.endereco = s.endereco ,'
            || ' d.endtransp = s.endtransp ,'
            || ' d.exigiremissaomapabalcao = s.exigiremissaomapabalcao ,'
            || ' d.fantasia = s.fantasia ,'
            || ' d.fax = s.fax ,'
            || ' d.gerarnsu = s.gerarnsu ,'
            || ' d.gerarnumloteautomaticpa = s.gerarnumloteautomaticpa ,'
            || ' d.ie = s.ie ,'
            || ' d.iesubsttrib = s.iesubsttrib ,'
            || ' d.ietransp = s.ietransp ,'
            || ' d.im = s.im ,'
            || ' d.incluiritempcembalagem = s.incluiritempcembalagem ,'
            || ' d.industria = s.industria ,'
            || ' d.ipisomentevlcont = s.ipisomentevlcont ,'
            || ' d.limparbasecalcentrada = s.limparbasecalcentrada ,'
            || ' d.mensnf = s.mensnf ,'
            || ' d.montando = s.montando ,'
            || ' d.nomepais = s.nomepais ,'
            || ' d.numcontratocorreio = s.numcontratocorreio ,'
            || ' d.numdiasvencfrete = s.numdiasvencfrete ,'
            || ' d.numero = s.numero ,'
            || ' d.numero2 = s.numero2 ,'
            || ' d.numidf = s.numidf ,'
            || ' d.numidfdevcli = s.numidfdevcli ,'
            || ' d.numproxvend = s.numproxvend ,'
            || ' d.numregiao = s.numregiao ,'
            || ' d.numregiaopadrao = s.numregiaopadrao ,'
            || ' d.numseqentr = s.numseqentr ,'
            || ' d.operadorlogistico = s.operadorlogistico ,'
            || ' d.opisentosicmsaltocusto = s.opisentosicmsaltocusto ,'
            || ' d.orgao = s.orgao ,'
            || ' d.perbaseredoutrasdesp = s.perbaseredoutrasdesp ,'
            || ' d.percaltercustoent = s.percaltercustoent ,'
            || ' d.percdespadm = s.percdespadm ,'
            || ' d.perfreteconhec = s.perfreteconhec ,'
            || ' d.permitecredicmcomst = s.permitecredicmcomst ,'
            || ' d.permitirvendaestadualpfcomie = s.permitirvendaestadualpfcomie ,'
            || ' d.permitirvendaestadualpfsemie = s.permitirvendaestadualpfsemie ,'
            || ' d.permitirvendainterestadualpf = s.permitirvendainterestadualpf ,'
            || ' d.pervendapf = s.pervendapf ,'
            || ' d.precoporembalagem = s.precoporembalagem ,'
            || ' d.prodporetapa = s.prodporetapa ,'
            || ' d.proxnsu = s.proxnsu ,'
            || ' d.proxnumaverbacao = s.proxnumaverbacao ,'
            -- Atencao: pegar o maior entre o atual e o do arquivo importado
            || ' d.proxnumcarecf = GREATEST(nvl(d.proxnumcarecf,0), nvl(s.proxnumcarecf,0)) ,'
            || ' d.proxnumconhec = s.proxnumconhec ,'
            || ' d.proxnumentmex = s.proxnumentmex ,'
            || ' d.proxnumeroorcamento = s.proxnumeroorcamento ,'
            || ' d.proxnumetapa = s.proxnumetapa ,'
            || ' d.proxnumlote = s.proxnumlote ,'
            || ' d.proxnumnfdevcli = s.proxnumnfdevcli ,'
            -- Atencao: pegar o maior entre o atual e o do arquivo importado
            || ' d.proxnumnota = GREATEST(nvl(d.proxnumnota,0), nvl(s.proxnumnotaecf,0)),'
            || ' d.proxnumnotad = s.proxnumnotad ,'
            -- Atencao: pegar o maior entre o atual e o do arquivo importado
            || ' d.proxnumnotaecf = GREATEST(nvl(d.proxnumnota,0), nvl(s.proxnumnotaecf,0)),'
            || ' d.proxnumnotatransf = s.proxnumnotatransf ,'
            || ' d.proxnumorc = s.proxnumorc ,'
            || ' d.proxnumorcafilial = s.proxnumorcafilial ,'
            || ' d.proxnumprevenda = s.proxnumprevenda ,'
            || ' d.proxnumtransconhec = s.proxnumtransconhec ,'
            || ' d.proxnumtransvendaecf = GREATEST(nvl(d.proxnumtransvendaecf,0), nvl(s.proxnumtransvendaecf,0)) ,'
            || ' d.razaosocial = s.razaosocial ,'
            || ' d.razaotransp = s.razaotransp ,'
            || ' d.somatarifabancduplic = s.somatarifabancduplic ,'
            || ' d.taxa0 = s.taxa0 ,'
            || ' d.taxa14 = s.taxa14 ,'
            || ' d.taxa21 = s.taxa21 ,'
            || ' d.taxa28 = s.taxa28 ,'
            || ' d.taxa35 = s.taxa35 ,'
            || ' d.taxa42 = s.taxa42 ,'
            || ' d.taxa7 = s.taxa7 ,'
            || ' d.telefone = s.telefone ,'
            || ' d.tipobroker = s.tipobroker ,'
            || ' d.tiponummapa = s.tiponummapa ,'
            || ' d.tiponumnfentrada = s.tiponumnfentrada ,'
            || ' d.uf = s.uf ,'
            || ' d.uftransp = s.uftransp ,'
            || ' d.usacontrolelocalizacaoveiculo = s.usacontrolelocalizacaoveiculo ,'
            || ' d.usadistrib = s.usadistrib ,'
            || ' d.usaenderecofilial = s.usaenderecofilial ,'
            || ' d.usaestoquedepfechado = s.usaestoquedepfechado ,'
            || ' d.usaprecoetiqprodpesado = s.usaprecoetiqprodpesado,'
            || ' d.usanumnfdevcli = s.usanumnfdevcli ,'
            || ' d.usanumnotaecf = s.usanumnotaecf ,'
            || ' d.usaservintermediario = s.usaservintermediario ,'
            || ' d.usawms = s.usawms ,'
            || ' d.utilizapercbaseredoutrasdesppf = s.utilizapercbaseredoutrasdesppf ,'
            || ' d.utilizavendaporembalagem = s.utilizavendaporembalagem ,'
            || ' d.validaendpickingpedcompra = s.validaendpickingpedcompra ,'
            || ' d.validavlmaxisencaostpf = s.validavlmaxisencaostpf ,'
            || ' d.valorcapital = s.valorcapital ,'
            || ' d.vlmaxisencaostpf = s.vlmaxisencaostpf ,'
            || ' d.vlmaxtarifabanc = s.vlmaxtarifabanc ,'
            || ' d.vlmintarifabanc = s.vlmintarifabanc ,'
            || ' d.vltarifa = s.vltarifa '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT ( aceitavendasemest,'
            || ' aliqicminteroutrasdesp,'
            || ' aliqicmoutrasdesp,'
            || ' aliquotafreteest,'
            || ' areavenda,'
            || ' atacadista,'
            || ' atividade,'
            || ' autoservico,'
            || ' bairro,'
            || ' broker,'
            || ' cae,'
            || ' calccredicmcustocont,'
            || ' calccredicms,'
            || ' calccredipi,'
            || ' calccredpiscofins,'
            || ' calccredpiscustocont,'
            || ' calcredpisfrete,'
            || ' calcredpisfretecont,'
            || ' calcularcomissaopvenda1,'
            || ' cep,'
            || ' cgc,'
            || ' cgctransp,'
            || ' cidade,'
            || ' cidadetransp,'
            || ' codcli,'
            || ' codcliconsumidor,'
            || ' codcontador,'
            || ' codcontaentimportacao,'
            || ' coddocdevfornec,'
            || ' coddocdevol,'
            || ' coddocentradamerc,'
            || ' coddocnf,'
            || ' coddocnfc,'
            || ' coddocsr,'
            || ' coddocss,'
            || ' coddoctransf,'
            || ' codestado,'
            || ' codfilialprefestbalcao,'
            || ' codfilialprefesttlmk,'
            || ' codfilialproducao,'
            || ' codfiscaldevoutrasdesp,'
            || ' codfiscalinterdevoutrasdesp,'
            || ' codfiscalinteroutrasdesp,'
            || ' codfiscaloutrasdesp,'
            || ' codfornec,'
            || ' codgrupo,'
            || ' codgrupofilial,'
            || ' codigo,'
            || ' codmun,'
            || ' codpais,'
            || ' codregistro,'
            || ' codsocio,'
            || ' consideraricmsantecipcusto,'
            || ' contato,'
            || ' dtfimatividade,'
            || ' dtiniatividade,'
            || ' dtregistro,'
            || ' eanemissor,'
            || ' email,'
            || ' endereco,'
            || ' endtransp,'
            || ' exigiremissaomapabalcao,'
            || ' fantasia,'
            || ' fax,'
            || ' gerarnsu,'
            || ' gerarnumloteautomaticpa,'
            || ' ie,'
            || ' iesubsttrib,'
            || ' ietransp,'
            || ' im,'
            || ' incluiritempcembalagem,'
            || ' industria,'
            || ' ipisomentevlcont,'
            || ' limparbasecalcentrada,'
            || ' mensnf,'
            || ' montando,'
            || ' nomepais,'
            || ' numcontratocorreio,'
            || ' numdiasvencfrete,'
            || ' numero,'
            || ' numero2,'
            || ' numidf,'
            || ' numidfdevcli,'
            || ' numproxvend,'
            || ' numregiao,'
            || ' numregiaopadrao,'
            || ' numseqentr,'
            || ' operadorlogistico,'
            || ' opisentosicmsaltocusto,'
            || ' orgao,'
            || ' perbaseredoutrasdesp,'
            || ' percaltercustoent,'
            || ' percdespadm,'
            || ' perfreteconhec,'
            || ' permitecredicmcomst,'
            || ' permitirvendaestadualpfcomie,'
            || ' permitirvendaestadualpfsemie,'
            || ' permitirvendainterestadualpf,'
            || ' pervendapf,'
            || ' precoporembalagem,'
            || ' prodporetapa,'
            || ' proxnsu,'
            || ' proxnumaverbacao,'
            || ' proxnumcarecf,'
            || ' proxnumconhec,'
            || ' proxnumentmex,'
            || ' proxnumeroorcamento,'
            || ' proxnumetapa,'
            || ' proxnumlote,'
            || ' proxnumnfdevcli,'
            || ' proxnumnota,'
            || ' proxnumnotad,'
            || ' proxnumnotaecf,'
            || ' proxnumnotatransf,'
            || ' proxnumorc,'
            || ' proxnumorcafilial,'
            || ' proxnumprevenda,'
            || ' proxnumtransconhec,'
            || ' proxnumtransvendaecf,'
            || ' razaosocial,'
            || ' razaotransp,'
            || ' somatarifabancduplic,'
            || ' taxa0,'
            || ' taxa14,'
            || ' taxa21,'
            || ' taxa28,'
            || ' taxa35,'
            || ' taxa42,'
            || ' taxa7,'
            || ' telefone,'
            || ' tipobroker,'
            || ' tiponummapa,'
            || ' tiponumnfentrada,'
            || ' uf,'
            || ' uftransp,'
            || ' usacontrolelocalizacaoveiculo,'
            || ' usadistrib,'
            || ' usaenderecofilial,'
            || ' usaestoquedepfechado,'
            || ' usaprecoetiqprodpesado,'
            || ' usanumnfdevcli,'
            || ' usanumnotaecf,'
            || ' usaservintermediario,'
            || ' usawms,'
            || ' utilizapercbaseredoutrasdesppf,'
            || ' utilizavendaporembalagem,'
            || ' validaendpickingpedcompra,'
            || ' validavlmaxisencaostpf,'
            || ' valorcapital,'
            || ' vlmaxisencaostpf,'
            || ' vlmaxtarifabanc,'
            || ' vlmintarifabanc,'
            || ' vltarifa ) '
            || ' VALUES ( s.aceitavendasemest,'
            || ' s.aliqicminteroutrasdesp,'
            || ' s.aliqicmoutrasdesp,'
            || ' s.aliquotafreteest,'
            || ' s.areavenda,'
            || ' s.atacadista,'
            || ' s.atividade,'
            || ' s.autoservico,'
            || ' s.bairro,'
            || ' s.broker,'
            || ' s.cae,'
            || ' s.calccredicmcustocont,'
            || ' s.calccredicms,'
            || ' s.calccredipi,'
            || ' s.calccredpiscofins,'
            || ' s.calccredpiscustocont,'
            || ' s.calcredpisfrete,'
            || ' s.calcredpisfretecont,'
            || ' s.calcularcomissaopvenda1,'
            || ' s.cep,'
            || ' s.cgc,'
            || ' s.cgctransp,'
            || ' s.cidade,'
            || ' s.cidadetransp,'
            || ' s.codcli,'
            || ' s.codcliconsumidor,'
            || ' s.codcontador,'
            || ' s.codcontaentimportacao,'
            || ' s.coddocdevfornec,'
            || ' s.coddocdevol,'
            || ' s.coddocentradamerc,'
            || ' s.coddocnf,'
            || ' s.coddocnfc,'
            || ' s.coddocsr,'
            || ' s.coddocss,'
            || ' s.coddoctransf,'
            || ' s.codestado,'
            || ' s.codfilialprefestbalcao,'
            || ' s.codfilialprefesttlmk,'
            || ' s.codfilialproducao,'
            || ' s.codfiscaldevoutrasdesp,'
            || ' s.codfiscalinterdevoutrasdesp,'
            || ' s.codfiscalinteroutrasdesp,'
            || ' s.codfiscaloutrasdesp,'
            || ' s.codfornec,'
            || ' s.codgrupo,'
            || ' s.codgrupofilial,'
            || ' s.codigo,'
            || ' s.codmun,'
            || ' s.codpais,'
            || ' s.codregistro,'
            || ' s.codsocio,'
            || ' s.consideraricmsantecipcusto,'
            || ' s.contato,'
            || ' s.dtfimatividade,'
            || ' s.dtiniatividade,'
            || ' s.dtregistro,'
            || ' s.eanemissor,'
            || ' s.email,'
            || ' s.endereco,'
            || ' s.endtransp,'
            || ' s.exigiremissaomapabalcao,'
            || ' s.fantasia,'
            || ' s.fax,'
            || ' s.gerarnsu,'
            || ' s.gerarnumloteautomaticpa,'
            || ' s.ie,'
            || ' s.iesubsttrib,'
            || ' s.ietransp,'
            || ' s.im,'
            || ' s.incluiritempcembalagem,'
            || ' s.industria,'
            || ' s.ipisomentevlcont,'
            || ' s.limparbasecalcentrada,'
            || ' s.mensnf,'
            || ' s.montando,'
            || ' s.nomepais,'
            || ' s.numcontratocorreio,'
            || ' s.numdiasvencfrete,'
            || ' s.numero,'
            || ' s.numero2,'
            || ' s.numidf,'
            || ' s.numidfdevcli,'
            || ' s.numproxvend,'
            || ' s.numregiao,'
            || ' s.numregiaopadrao,'
            || ' s.numseqentr,'
            || ' s.operadorlogistico,'
            || ' s.opisentosicmsaltocusto,'
            || ' s.orgao,'
            || ' s.perbaseredoutrasdesp,'
            || ' s.percaltercustoent,'
            || ' s.percdespadm,'
            || ' s.perfreteconhec,'
            || ' s.permitecredicmcomst,'
            || ' s.permitirvendaestadualpfcomie,'
            || ' s.permitirvendaestadualpfsemie,'
            || ' s.permitirvendainterestadualpf,'
            || ' s.pervendapf,'
            || ' s.precoporembalagem,'
            || ' s.prodporetapa,'
            || ' s.proxnsu,'
            || ' s.proxnumaverbacao,'
            || ' s.proxnumcarecf,'
            || ' s.proxnumconhec,'
            || ' s.proxnumentmex,'
            || ' s.proxnumeroorcamento,'
            || ' s.proxnumetapa,'
            || ' s.proxnumlote,'
            || ' s.proxnumnfdevcli,'
            || ' s.proxnumnotaecf,'
            || ' s.proxnumnotad,'
            || ' s.proxnumnotaecf,'
            || ' s.proxnumnotatransf,'
            || ' s.proxnumorc,'
            || ' s.proxnumorcafilial,'
            || ' s.proxnumprevenda,'
            || ' s.proxnumtransconhec,'
            || ' s.proxnumtransvendaecf,'
            || ' s.razaosocial,'
            || ' s.razaotransp,'
            || ' s.somatarifabancduplic,'
            || ' s.taxa0,'
            || ' s.taxa14,'
            || ' s.taxa21,'
            || ' s.taxa28,'
            || ' s.taxa35,'
            || ' s.taxa42,'
            || ' s.taxa7,'
            || ' s.telefone,'
            || ' s.tipobroker,'
            || ' s.tiponummapa,'
            || ' s.tiponumnfentrada,'
            || ' s.uf,'
            || ' s.uftransp,'
            || ' s.usacontrolelocalizacaoveiculo,'
            || ' s.usadistrib,'
            || ' s.usaenderecofilial,'
            || ' s.usaestoquedepfechado,'
            || ' s.usaprecoetiqprodpesado,'
            || ' s.usanumnfdevcli,'
            || ' s.usanumnotaecf,'
            || ' s.usaservintermediario,'
            || ' s.usawms,'
            || ' s.utilizapercbaseredoutrasdesppf,'
            || ' s.utilizavendaporembalagem,'
            || ' s.validaendpickingpedcompra,'
            || ' s.validavlmaxisencaostpf,'
            || ' s.valorcapital,'
            || ' s.vlmaxisencaostpf,'
            || ' s.vlmaxtarifabanc,'
            || ' s.vlmintarifabanc,'
            || ' s.vltarifa )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcfilial;

   FUNCTION importar_pccaixa (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccaixa';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (numcaixa number(4,0),'
         || '  descricao varchar2(40),'
         || '  posicao varchar2(1),'
         || '  codfunccx number(8,0),'
         || '  dtinicio date,'
         || '  dtfim date,'
         || '  tipoimpressora varchar2(1),'
         || '  portaimpressora number(2,0),'
         || '  numserieequip varchar2(30),'
         || '  portaleitor number(2,0),'
         || '  versaoimpressora varchar2(5),'
         || '  permiteabrirgaveta varchar2(1),'
         || '  gavetaacoplada varchar2(1),'
         || '  tipotef varchar2(4),'
         || '  portaleitorch number(2,0),'
         || '  validach varchar2(1),'
         || '  numregiao number(4,0),'
         || '  codfilial varchar2(2),'
         || '  numopcx number(2,0),'
         || '  tipoimpressoracheque varchar2(1),'
         || '  versaoimpressoracheque varchar2(5),'
         || '  portaimpressoracheque number(2,0),'
         || '  numcupomaberto number(10,0),'
         || '  numcupomfechado number(10,0),'
         || '  diratualizacao varchar2(200),'
         || '  degustacao varchar2(1),'
         || '  tipoteclado varchar2(1),'
         || '  tipobalanca varchar2(1),'
         || '  saltarlinhatef varchar2(1),'
         || '  msgcupomfiscal varchar2(40),'
         || '  numcaixafiscal number(4,0),'
         || '  admissao date,'
         || '  modelo varchar2(10),'
         || '  ipservidorsitef varchar2(20),'
         || '  codempresasitef varchar2(20),'
         || '  terminalsitef varchar2(20),'
         || '  atualizacestabasica varchar2(1),'
         || '  atualizaplano varchar2(1),'
         || '  atualizaformapg varchar2(1),'
         || '  atualizaempregado varchar2(1),'
         || '  atualizalayout varchar2(1),'
         || '  atualizasetor varchar2(1),'
         || '  atualizatributacao varchar2(1),'
         || '  atualizacliente varchar2(1),'
         || '  atualizaclientedtini date,'
         || '  atualizaclientedtfim date,'
         || '  atualizacfo varchar2(1),'
         || '  atualizaproduto varchar2(1),'
         || '  atualizaprodutodtini date,'
         || '  atualizaprodutodtfim date,'
         || '  atualizaprecoembalagem varchar2(1),'
         || '  atualizaprecoembalagemdtini date,'
         || '  atualizaprecoembalagemdtfim date,'
         || '  atualizaprecoregiao varchar2(1),'
         || '  atualizaprecoregiaodtini date,'
         || '  atualizaprecoregiaodtfim date)'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.numcaixa = s.numcaixa) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.descricao = s.descricao,'
            || '     d.posicao = s.posicao,'
            || '     d.codfunccx = s.codfunccx,'
            || '     d.dtinicio = s.dtinicio,'
            || '     d.dtfim = s.dtfim,'
            || '     d.tipoimpressora = s.tipoimpressora,'
            || '     d.portaimpressora = s.portaimpressora,'
            || '     d.numserieequip = s.numserieequip,'
            || '     d.portaleitor = s.portaleitor,'
            || '     d.versaoimpressora = s.versaoimpressora,'
            || '     d.permiteabrirgaveta = s.permiteabrirgaveta,'
            || '     d.gavetaacoplada = s.gavetaacoplada,'
            || '     d.tipotef = s.tipotef,'
            || '     d.portaleitorch = s.portaleitorch,'
            || '     d.validach = s.validach,'
            || '     d.numregiao = s.numregiao,'
            || '     d.codfilial = s.codfilial,'
            || '     d.numopcx = s.numopcx,'
            || '     d.tipoimpressoracheque = s.tipoimpressoracheque,'
            || '     d.versaoimpressoracheque = s.versaoimpressoracheque,'
            || '     d.portaimpressoracheque = s.portaimpressoracheque,'
            || '     d.numcupomaberto = s.numcupomaberto,'
            || '     d.numcupomfechado = s.numcupomfechado,'
            || '     d.diratualizacao = s.diratualizacao,'
            || '     d.degustacao = s.degustacao,'
            || '     d.tipoteclado = s.tipoteclado,'
            || '     d.tipobalanca = s.tipobalanca,'
            || '     d.saltarlinhatef = s.saltarlinhatef,'
            || '     d.msgcupomfiscal = s.msgcupomfiscal,'
            || '     d.numcaixafiscal = s.numcaixafiscal,'
            || '     d.admissao = s.admissao,'
            || '     d.modelo = s.modelo,'
            || '     d.ipservidorsitef = s.ipservidorsitef,'
            || '     d.codempresasitef = s.codempresasitef,'
            || '     d.terminalsitef = s.terminalsitef,'
            || '     d.atualizacestabasica = s.atualizacestabasica,'
            || '     d.atualizaplano = s.atualizaplano,'
            || '     d.atualizaformapg = s.atualizaformapg,'
            || '     d.atualizaempregado = s.atualizaempregado,'
            || '     d.atualizalayout = s.atualizalayout,'
            || '     d.atualizasetor = s.atualizasetor,'
            || '     d.atualizatributacao = s.atualizatributacao,'
            || '     d.atualizacliente = s.atualizacliente,'
            || '     d.atualizaclientedtini = s.atualizaclientedtini,'
            || '     d.atualizaclientedtfim = s.atualizaclientedtfim,'
            || '     d.atualizacfo = s.atualizacfo,'
            || '     d.atualizaproduto = s.atualizaproduto,'
            || '     d.atualizaprodutodtini = s.atualizaprodutodtini,'
            || '     d.atualizaprodutodtfim = s.atualizaprodutodtfim,'
            || '     d.atualizaprecoembalagem = s.atualizaprecoembalagem,'
            || '     d.atualizaprecoembalagemdtini = s.atualizaprecoembalagemdtini,'
            || '     d.atualizaprecoembalagemdtfim = s.atualizaprecoembalagemdtfim,'
            || '     d.atualizaprecoregiao = s.atualizaprecoregiao,'
            || '     d.atualizaprecoregiaodtini = s.atualizaprecoregiaodtini,'
            || '     d.atualizaprecoregiaodtfim = s.atualizaprecoregiaodtfim'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (numcaixa, descricao, posicao, codfunccx, dtinicio, dtfim, tipoimpressora,'
            || '         portaimpressora, numserieequip, portaleitor, versaoimpressora, permiteabrirgaveta,'
            || '         gavetaacoplada, tipotef, portaleitorch, validach, numregiao, codfilial, numopcx,'
            || '         tipoimpressoracheque, versaoimpressoracheque, portaimpressoracheque, numcupomaberto,'
            || '         numcupomfechado, diratualizacao, degustacao, tipoteclado, tipobalanca, saltarlinhatef,'
            || '         msgcupomfiscal, numcaixafiscal, admissao, modelo, ipservidorsitef, codempresasitef,'
            || '         terminalsitef, atualizacestabasica, atualizaplano, atualizaformapg, atualizaempregado,'
            || '         atualizalayout, atualizasetor, atualizatributacao, atualizacliente, atualizaclientedtini,'
            || '         atualizaclientedtfim, atualizacfo, atualizaproduto, atualizaprodutodtini, atualizaprodutodtfim,'
            || '         atualizaprecoembalagem, atualizaprecoembalagemdtini, atualizaprecoembalagemdtfim,'
            || '         atualizaprecoregiao, atualizaprecoregiaodtini, atualizaprecoregiaodtfim) '
            || ' VALUES (s.numcaixa, s.descricao, s.posicao, s.codfunccx, s.dtinicio, s.dtfim,'
            || '         s.tipoimpressora, s.portaimpressora, s.numserieequip, s.portaleitor,'
            || '         s.versaoimpressora, s.permiteabrirgaveta, s.gavetaacoplada, s.tipotef,'
            || '         s.portaleitorch, s.validach, s.numregiao, s.codfilial, s.numopcx,'
            || '         s.tipoimpressoracheque, s.versaoimpressoracheque, s.portaimpressoracheque,'
            || '         s.numcupomaberto, s.numcupomfechado, s.diratualizacao, s.degustacao,'
            || '         s.tipoteclado, s.tipobalanca, s.saltarlinhatef, s.msgcupomfiscal,'
            || '         s.numcaixafiscal, s.admissao, s.modelo, s.ipservidorsitef, s.codempresasitef,'
            || '         s.terminalsitef, s.atualizacestabasica, s.atualizaplano, s.atualizaformapg,'
            || '         s.atualizaempregado, s.atualizalayout, s.atualizasetor, s.atualizatributacao,'
            || '         s.atualizacliente, s.atualizaclientedtini, s.atualizaclientedtfim,'
            || '         s.atualizacfo, s.atualizaproduto, s.atualizaprodutodtini,'
            || '         s.atualizaprodutodtfim, s.atualizaprecoembalagem, s.atualizaprecoembalagemdtini,'
            || '         s.atualizaprecoembalagemdtfim, s.atualizaprecoregiao,'
            || '         s.atualizaprecoregiaodtini, s.atualizaprecoregiaodtfim)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pccaixa;

   FUNCTION importar_pcclient (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcclient';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (aceitachterceiros VARCHAR2(1),'
         || ' aceitatrocanegativa VARCHAR2(1),'
         || ' aceitavendafracao VARCHAR2(1),'
         || ' aliqicms1 NUMBER(8,4),'
         || ' analisecred VARCHAR2(1),'
         || ' aplicadescnf VARCHAR2(1),'
         || ' bairrocob VARCHAR2(40),'
         || ' bairrocom VARCHAR2(40),'
         || ' bairroent VARCHAR2(40),'
         || ' bloqueio VARCHAR2(1),'
         || ' bloqueiosefaz VARCHAR2(1),'
         || ' cacex VARCHAR2(15),'
         || ' caixapostal NUMBER(5,0),'
         || ' calculast VARCHAR2(1),'
         || ' capitalsocial NUMBER(14,2),'
         || ' cargo VARCHAR2(30),'
         || ' cargoconjuge VARCHAR2(30),'
         || ' cepcob VARCHAR2(9),'
         || ' cepcom VARCHAR2(9),'
         || ' cepcxpostal NUMBER(8,0),'
         || ' cepent VARCHAR2(9),'
         || ' cgcent VARCHAR2(18),'
         || ' cgcentrega VARCHAR2(18),'
         || ' cgeentaux VARCHAR2(18),'
         || ' classecomercial VARCHAR2(1),'
         || ' classemc VARCHAR2(1),'
         || ' classevenda VARCHAR2(1),'
         || ' cliente VARCHAR2(40),'
         || ' clientedan VARCHAR2(1),'
         || ' clienteeletro VARCHAR2(1),'
         || ' clientefontest VARCHAR2(1),'
         || ' clientemonitorado VARCHAR2(1),'
         || ' cliente2 VARCHAR2(100),'
         || ' clientprotesto VARCHAR2(1),'
         || ' codatv1 NUMBER(6,0),'
         || ' codbarra NUMBER(14,0),'
         || ' codbarracob NUMBER(14,0),'
         || ' codbarraent NUMBER(14,0),'
         || ' codcanal NUMBER(6,0),'
         || ' codcidade NUMBER(6,0),'
         || ' codcli NUMBER(6,0),'
         || ' codclipalm NUMBER(6,0),'
         || ' codcliprinc NUMBER(6,0),'
         || ' codcob VARCHAR2(4),'
         || ' codcondicaovenda NUMBER(6,0),'
         || ' codfilialestoque VARCHAR2(1),'
         || ' codfilialnf VARCHAR2(2),'
         || ' codfunccad NUMBER(8,0),'
         || ' codfunccadastro NUMBER(8,0),'
         || ' codfunclancpotenciallimcred NUMBER(8,0),'
         || ' codfuncultalter NUMBER(8,0),'
         || ' codfuncultaltercliesp NUMBER(8,0),'
         || ' codfuncultcontatocob NUMBER(8,0),'
         || ' codmunicipio NUMBER(10,0),'
         || ' codnilsen VARCHAR2(4),'
         || ' codplpag NUMBER(4,0),'
         || ' codplpagpadrao NUMBER(4,0),'
         || ' codplpag2 NUMBER(4,0),'
         || ' codpraca NUMBER(6,0),'
         || ' codstatuscob NUMBER(4,0),'
         || ' codsuframa VARCHAR2(30),'
         || ' codusur1 NUMBER(4,0),'
         || ' codusur2 NUMBER(4,0),'
         || ' codusur3 NUMBER(4,0),'
         || ' complementoent VARCHAR2(80),'
         || ' condvenda1 VARCHAR2(1),'
         || ' condvenda10 VARCHAR2(1),'
         || ' condvenda11 VARCHAR2(1),'
         || ' condvenda12 VARCHAR2(1),'
         || ' condvenda13 VARCHAR2(1),'
         || ' condvenda14 VARCHAR2(1),'
         || ' condvenda2 VARCHAR2(1),'
         || ' condvenda20 VARCHAR2(1),'
         || ' condvenda3 VARCHAR2(1),'
         || ' condvenda4 VARCHAR2(1),'
         || ' condvenda5 VARCHAR2(1),'
         || ' condvenda6 VARCHAR2(1),'
         || ' condvenda7 VARCHAR2(1),'
         || ' condvenda8 VARCHAR2(1),'
         || ' condvenda9 VARCHAR2(1),'
         || ' condvenda98 VARCHAR2(1),'
         || ' condvenda99 VARCHAR2(1),'
         || ' consumidorfinal VARCHAR2(1),'
         || ' contribuinte VARCHAR2(1),'
         || ' cpfconjuge VARCHAR2(15),'
         || ' dddinternacional NUMBER(3,0),'
         || ' descproduto VARCHAR2(1),'
         || ' destacafrete VARCHAR2(1),'
         || ' diasemana VARCHAR2(10),'
         || ' digagencia1 VARCHAR2(1),'
         || ' digagencia2 VARCHAR2(1),'
         || ' diretoriocliente VARCHAR2(100),'
         || ' dtabertcc1 DATE,'
         || ' dtabertcc2 DATE,'
         || ' dtadmissao DATE,'
         || ' dtadmissaoconjuge DATE,'
         || ' dtbloq DATE,'
         || ' dtcadastro DATE,'
         || ' dtcapitalsocial DATE,'
         || ' dtclassificaestrela DATE,'
         || ' dtclassificagrupo DATE,'
         || ' dtdesbloqueio DATE,'
         || ' dtenquadramentomicroempresa DATE,'
         || ' dtexclusao DATE,'
         || ' dtlancpotenciallimcred DATE,'
         || ' dtnasc DATE,'
         || ' dtnascconj DATE,'
         || ' dtprimcompra DATE,'
         || ' dtproxcontatocob DATE,'
         || ' dtreglim DATE,'
         || ' dtultalter DATE,'
         || ' dtultaltercliesp DATE,'
         || ' dtultcomp DATE,'
         || ' dtultcompnestle DATE,'
         || ' dtultconsultasci DATE,'
         || ' dtultconsultaserasa DATE,'
         || ' dtultconsultasintegra DATE,'
         || ' dtultcontatocob DATE,'
         || ' dtultvisita DATE,'
         || ' dtvalidasefaz DATE,'
         || ' dtvencalvara DATE,'
         || ' dtvencalvarafunc DATE,'
         || ' dtvenclimcred DATE,'
         || ' dtvencprazoadicional DATE,'
         || ' dtvencsuframa DATE,'
         || ' eancobranca NUMBER(14,0),'
         || ' eanentrega NUMBER(14,0),'
         || ' edocob VARCHAR2(3),'
         || ' edocom VARCHAR2(3),'
         || ' edoent VARCHAR2(3),'
         || ' email VARCHAR2(100),'
         || ' emitedae VARCHAR2(1),'
         || ' emitedup VARCHAR2(1),'
         || ' emitentech VARCHAR2(40),'
         || ' emitentech2 VARCHAR2(40),'
         || ' empfixa VARCHAR2(1),'
         || ' empresa VARCHAR2(40),'
         || ' empresaconjuge VARCHAR2(40),'
         || ' endercob VARCHAR2(40),'
         || ' endercom VARCHAR2(40),'
         || ' enderconjuge VARCHAR2(40),'
         || ' enderempr VARCHAR2(40),'
         || ' enderent VARCHAR2(40),'
         || ' enviadadosserasa VARCHAR2(1),'
         || ' estcob VARCHAR2(2),'
         || ' estcom VARCHAR2(2),'
         || ' estconjuge VARCHAR2(2),'
         || ' estempr VARCHAR2(2),'
         || ' estent VARCHAR2(2),'
         || ' exportardadosims VARCHAR2(1),'
         || ' fantasia VARCHAR2(40),'
         || ' faxcli VARCHAR2(15),'
         || ' faxcom VARCHAR2(15),'
         || ' filiacaomae VARCHAR2(40),'
         || ' filiacaomaeconj VARCHAR2(40),'
         || ' filiacaopai VARCHAR2(40),'
         || ' filiacaopaiconj VARCHAR2(40),'
         || ' freqdiavisita NUMBER(4,0),'
         || ' freqvisita NUMBER(1,0),'
         || ' gerenciamento VARCHAR2(1),'
         || ' gruporamoativi VARCHAR2(2),'
         || ' horaproxcontato NUMBER(2,0),'
         || ' horarioreceb VARCHAR2(5),'
         || ' icmsantecip VARCHAR2(1),'
         || ' ieent VARCHAR2(15),'
         || ' ieps NUMBER(8,4),'
         || ' iest VARCHAR2(15),'
         || ' iment VARCHAR2(15),'
         || ' incluinoarqsci VARCHAR2(1),'
         || ' inicioativ DATE,'
         || ' inscestadual VARCHAR2(20),'
         || ' isentajuros VARCHAR2(1),'
         || ' isentoicms VARCHAR2(1),'
         || ' isentoipi VARCHAR2(1),'
         || ' isentotxboleto VARCHAR2(1),'
         || ' iva NUMBER(8,4),'
         || ' ivafonte NUMBER(8,4),'
         || ' limcred NUMBER(12,2),'
         || ' limiteautori VARCHAR2(40),'
         || ' listaplpag VARCHAR2(20),'
         || ' medcodfunclibtribut NUMBER(8,0),'
         || ' meddtlibtribut DATE,'
         || ' microempresa VARCHAR2(2),'
         || ' minutoproxcontato NUMBER(2,0),'
         || ' motivoexclusao VARCHAR2(40),'
         || ' municcob VARCHAR2(15),'
         || ' municcob2 VARCHAR2(100),'
         || ' municcom VARCHAR2(15),'
         || ' municcom2 VARCHAR2(100),'
         || ' municconjuge VARCHAR2(15),'
         || ' municempr VARCHAR2(15),'
         || ' municent VARCHAR2(15),'
         || ' municent2 VARCHAR2(100),'
         || ' municipiosefaz VARCHAR2(60),'
         || ' nomeconjuge VARCHAR2(40),'
         || ' numagencia1 NUMBER(6,0),'
         || ' numagencia2 NUMBER(6,0),'
         || ' numalvara VARCHAR2(30),'
         || ' numalvarafunc VARCHAR2(30),'
         || ' numbanco1 NUMBER(3,0),'
         || ' numbanco2 NUMBER(3,0),'
         || ' numccorrente1 VARCHAR2(15),'
         || ' numccorrente2 VARCHAR2(15),'
         || ' numconcessao VARCHAR2(12),'
         || ' numregiaocli NUMBER(4,0),'
         || ' numseq NUMBER(10,0),'
         || ' numseqatu NUMBER,'
         || ' numseqrotarca NUMBER(4,0),'
         || ' numtare VARCHAR2(20),'
         || ' numtransvendadesc NUMBER(12,0),'
         || ' obs VARCHAR2(40),'
         || ' obscallcenter VARCHAR2(4000),'
         || ' obscredito VARCHAR2(30),'
         || ' obsentrega1 VARCHAR2(75),'
         || ' obsentrega2 VARCHAR2(75),'
         || ' obsentrega3 VARCHAR2(75),'
         || ' observacao VARCHAR2(2000),'
         || ' obsgerencial1 VARCHAR2(80),'
         || ' obsgerencial2 VARCHAR2(80),'
         || ' obsgerencial3 VARCHAR2(80),'
         || ' obsrecepcao VARCHAR2(4000),'
         || ' obstesouraria VARCHAR2(4000),'
         || ' obs2 VARCHAR2(40),'
         || ' obs3 VARCHAR2(60),'
         || ' obs4 VARCHAR2(60),'
         || ' obs5 VARCHAR2(60),'
         || ' orgaopub VARCHAR2(1),'
         || ' orgaorg VARCHAR2(4),'
         || ' orgaorgconj VARCHAR2(4),'
         || ' origempreco VARCHAR2(1),'
         || ' paisent VARCHAR2(18),'
         || ' paraibasim VARCHAR2(1),'
         || ' peracrestransf NUMBER(4,2),'
         || ' perbasevend NUMBER(5,2),'
         || ' percbasevendqt NUMBER(5,2),'
         || ' percbonific NUMBER(5,2),'
         || ' percomcli NUMBER(5,2),'
         || ' perdesc NUMBER(6,2),'
         || ' perdescfin NUMBER(4,2),'
         || ' perdescisentoicms NUMBER(4,2),'
         || ' perdesc2 NUMBER(6,2),'
         || ' perdesc3 NUMBER(6,2),'
         || ' perdesc4 NUMBER(6,2),'
         || ' perdesc5 NUMBER(6,2),'
         || ' plpagneg VARCHAR2(1),'
         || ' plpagneg2 VARCHAR2(1),'
         || ' pontorefer VARCHAR2(40),'
         || ' prazoadicional NUMBER(4,0),'
         || ' prazoadicional2 NUMBER(4,0),'
         || ' prazoadicional3 NUMBER(4,0),'
         || ' prazoadicional4 NUMBER(4,0),'
         || ' prazoadicional5 NUMBER(4,0),'
         || ' prazoadicional6 NUMBER(4,0),'
         || ' prazoadicional7 NUMBER(4,0),'
         || ' prazomaxvalidade NUMBER(6,0),'
         || ' prazovalidade NUMBER(4,0),'
         || ' prazovenda NUMBER(4,0),'
         || ' predioproprio VARCHAR2(1),'
         || ' qtcheckout NUMBER(8,0),'
         || ' qtestrela NUMBER(2,0),'
         || ' ratingsci VARCHAR2(1),'
         || ' ratingsci1 VARCHAR2(1),'
         || ' ratingsci2 VARCHAR2(1),'
         || ' regjuntacomercial VARCHAR2(15),'
         || ' rendamensal NUMBER(14,2),'
         || ' rendamensalconjuge NUMBER(14,2),'
         || ' repasse VARCHAR2(1),'
         || ' ressarcimentost VARCHAR2(1),'
         || ' rfc VARCHAR2(20),'
         || ' rg VARCHAR2(20),'
         || ' rgconj VARCHAR2(20),'
         || ' roteiromasterfoods VARCHAR2(20),'
         || ' senha_web VARCHAR2(18),'
         || ' sexo VARCHAR2(1),'
         || ' sigladec VARCHAR2(5),'
         || ' site VARCHAR2(80),'
         || ' sulframa VARCHAR2(15),'
         || ' suprimido VARCHAR2(1),'
         || ' telcelent VARCHAR2(13),'
         || ' telcob VARCHAR2(13),'
         || ' telcom VARCHAR2(13),'
         || ' telconjuge VARCHAR2(13),'
         || ' telempr VARCHAR2(13),'
         || ' telent VARCHAR2(13),'
         || ' telent1 VARCHAR2(13),'
         || ' tipoclimed VARCHAR2(2),'
         || ' tipoconversaotv4 VARCHAR2(2),'
         || ' tipocustotransf VARCHAR2(1),'
         || ' tipodescisencao VARCHAR2(1),'
         || ' tipoempresa VARCHAR2(4),'
         || ' tipofj VARCHAR2(1),'
         || ' tipoultalter VARCHAR2(1),'
         || ' ufrg VARCHAR2(2),'
         || ' ultcodplpag NUMBER(4,0),'
         || ' usabkcnpjcodcliprinc VARCHAR2(1),'
         || ' usacross VARCHAR2(1),'
         || ' usaivafontediferenciado VARCHAR2(1),'
         || ' usavlminvendabk VARCHAR2(1),'
         || ' utilizaiesimplificada VARCHAR2(1),'
         || ' validamaxvendapf VARCHAR2(1),'
         || ' validarcampanhabrinde VARCHAR2(1),'
         || ' validarmultiplovenda VARCHAR2(1),'
         || ' valoraluguel NUMBER(14,2),'
         || ' vip VARCHAR2(1),'
         || ' vlestoque NUMBER(14,2),'
         || ' vlmediacompramesfornec NUMBER(14,2),'
         || ' vloutrasrendas NUMBER(14,2),'
         || ' vlpotenciallimcred NUMBER(14,2))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codcli = s.codcli) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE'
            || ' SET d.aceitachterceiros = s.aceitachterceiros ,'
            || ' d.aceitatrocanegativa = s.aceitatrocanegativa ,'
            || ' d.aceitavendafracao = s.aceitavendafracao ,'
            || ' d.aliqicms1 = s.aliqicms1 ,'
            || ' d.analisecred = s.analisecred ,'
            || ' d.aplicadescnf = s.aplicadescnf ,'
            || ' d.bairrocob = s.bairrocob ,'
            || ' d.bairrocom = s.bairrocom ,'
            || ' d.bairroent = s.bairroent ,'
            || ' d.bloqueio = s.bloqueio ,'
            || ' d.bloqueiosefaz = s.bloqueiosefaz ,'
            || ' d.cacex = s.cacex ,'
            || ' d.caixapostal = s.caixapostal ,'
            || ' d.calculast = s.calculast ,'
            || ' d.capitalsocial = s.capitalsocial ,'
            || ' d.cargo = s.cargo ,'
            || ' d.cargoconjuge = s.cargoconjuge ,'
            || ' d.cepcob = s.cepcob ,'
            || ' d.cepcom = s.cepcom ,'
            || ' d.cepcxpostal = s.cepcxpostal ,'
            || ' d.cepent = s.cepent ,'
            || ' d.cgcent = s.cgcent ,'
            || ' d.cgcentrega = s.cgcentrega ,'
            || ' d.cgeentaux = s.cgeentaux ,'
            || ' d.classecomercial = s.classecomercial ,'
            || ' d.classemc = s.classemc ,'
            || ' d.classevenda = s.classevenda ,'
            || ' d.cliente = s.cliente ,'
            || ' d.clientedan = s.clientedan ,'
            || ' d.clienteeletro = s.clienteeletro ,'
            || ' d.clientefontest = s.clientefontest ,'
            || ' d.clientemonitorado = s.clientemonitorado ,'
            || ' d.cliente2 = s.cliente2 ,'
            || ' d.clientprotesto = s.clientprotesto ,'
            || ' d.codatv1 = s.codatv1 ,'
            || ' d.codbarra = s.codbarra ,'
            || ' d.codbarracob = s.codbarracob ,'
            || ' d.codbarraent = s.codbarraent ,'
            || ' d.codcanal = s.codcanal ,'
            || ' d.codcidade = s.codcidade ,'
            || ' d.codclipalm = s.codclipalm ,'
            || ' d.codcliprinc = s.codcliprinc ,'
            || ' d.codcob = s.codcob ,'
            || ' d.codcondicaovenda = s.codcondicaovenda ,'
            || ' d.codfilialestoque = s.codfilialestoque ,'
            || ' d.codfilialnf = s.codfilialnf ,'
            || ' d.codfunccad = s.codfunccad ,'
            || ' d.codfunccadastro = s.codfunccadastro ,'
            || ' d.codfunclancpotenciallimcred = s.codfunclancpotenciallimcred ,'
            || ' d.codfuncultalter = s.codfuncultalter ,'
            || ' d.codfuncultaltercliesp = s.codfuncultaltercliesp ,'
            || ' d.codfuncultcontatocob = s.codfuncultcontatocob ,'
            || ' d.codmunicipio = s.codmunicipio ,'
            || ' d.codnilsen = s.codnilsen ,'
            || ' d.codplpag = s.codplpag ,'
            || ' d.codplpagpadrao = s.codplpagpadrao ,'
            || ' d.codplpag2 = s.codplpag2 ,'
            || ' d.codpraca = s.codpraca ,'
            || ' d.codstatuscob = s.codstatuscob ,'
            || ' d.codsuframa = s.codsuframa ,'
            || ' d.codusur1 = s.codusur1 ,'
            || ' d.codusur2 = s.codusur2 ,'
            || ' d.codusur3 = s.codusur3 ,'
            || ' d.complementoent = s.complementoent ,'
            || ' d.condvenda1 = s.condvenda1 ,'
            || ' d.condvenda10 = s.condvenda10 ,'
            || ' d.condvenda11 = s.condvenda11 ,'
            || ' d.condvenda12 = s.condvenda12 ,'
            || ' d.condvenda13 = s.condvenda13 ,'
            || ' d.condvenda14 = s.condvenda14 ,'
            || ' d.condvenda2 = s.condvenda2 ,'
            || ' d.condvenda20 = s.condvenda20 ,'
            || ' d.condvenda3 = s.condvenda3 ,'
            || ' d.condvenda4 = s.condvenda4 ,'
            || ' d.condvenda5 = s.condvenda5 ,'
            || ' d.condvenda6 = s.condvenda6 ,'
            || ' d.condvenda7 = s.condvenda7 ,'
            || ' d.condvenda8 = s.condvenda8 ,'
            || ' d.condvenda9 = s.condvenda9 ,'
            || ' d.condvenda98 = s.condvenda98 ,'
            || ' d.condvenda99 = s.condvenda99 ,'
            || ' d.consumidorfinal = s.consumidorfinal ,'
            || ' d.contribuinte = s.contribuinte ,'
            || ' d.cpfconjuge = s.cpfconjuge ,'
            || ' d.dddinternacional = s.dddinternacional ,'
            || ' d.descproduto = s.descproduto ,'
            || ' d.destacafrete = s.destacafrete ,'
            || ' d.diasemana = s.diasemana ,'
            || ' d.digagencia1 = s.digagencia1 ,'
            || ' d.digagencia2 = s.digagencia2 ,'
            || ' d.diretoriocliente = s.diretoriocliente ,'
            || ' d.dtabertcc1 = s.dtabertcc1 ,'
            || ' d.dtabertcc2 = s.dtabertcc2 ,'
            || ' d.dtadmissao = s.dtadmissao ,'
            || ' d.dtadmissaoconjuge = s.dtadmissaoconjuge ,'
            || ' d.dtbloq = s.dtbloq ,'
            || ' d.dtcadastro = s.dtcadastro ,'
            || ' d.dtcapitalsocial = s.dtcapitalsocial ,'
            || ' d.dtclassificaestrela = s.dtclassificaestrela ,'
            || ' d.dtclassificagrupo = s.dtclassificagrupo ,'
            || ' d.dtdesbloqueio = s.dtdesbloqueio ,'
            || ' d.dtenquadramentomicroempresa = s.dtenquadramentomicroempresa ,'
            || ' d.dtexclusao = s.dtexclusao ,'
            || ' d.dtlancpotenciallimcred = s.dtlancpotenciallimcred ,'
            || ' d.dtnasc = s.dtnasc ,'
            || ' d.dtnascconj = s.dtnascconj ,'
            || ' d.dtprimcompra = s.dtprimcompra ,'
            || ' d.dtproxcontatocob = s.dtproxcontatocob ,'
            || ' d.dtreglim = s.dtreglim ,'
            || ' d.dtultalter = s.dtultalter ,'
            || ' d.dtultaltercliesp = s.dtultaltercliesp ,'
            || ' d.dtultcomp = s.dtultcomp ,'
            || ' d.dtultcompnestle = s.dtultcompnestle ,'
            || ' d.dtultconsultasci = s.dtultconsultasci ,'
            || ' d.dtultconsultaserasa = s.dtultconsultaserasa ,'
            || ' d.dtultconsultasintegra = s.dtultconsultasintegra ,'
            || ' d.dtultcontatocob = s.dtultcontatocob ,'
            || ' d.dtultvisita = s.dtultvisita ,'
            || ' d.dtvalidasefaz = s.dtvalidasefaz ,'
            || ' d.dtvencalvara = s.dtvencalvara ,'
            || ' d.dtvencalvarafunc = s.dtvencalvarafunc ,'
            || ' d.dtvenclimcred = s.dtvenclimcred ,'
            || ' d.dtvencprazoadicional = s.dtvencprazoadicional ,'
            || ' d.dtvencsuframa = s.dtvencsuframa ,'
            || ' d.eancobranca = s.eancobranca ,'
            || ' d.eanentrega = s.eanentrega ,'
            || ' d.edocob = s.edocob ,'
            || ' d.edocom = s.edocom ,'
            || ' d.edoent = s.edoent ,'
            || ' d.email = s.email ,'
            || ' d.emitedae = s.emitedae ,'
            || ' d.emitedup = s.emitedup ,'
            || ' d.emitentech = s.emitentech ,'
            || ' d.emitentech2 = s.emitentech2 ,'
            || ' d.empfixa = s.empfixa ,'
            || ' d.empresa = s.empresa ,'
            || ' d.empresaconjuge = s.empresaconjuge ,'
            || ' d.endercob = s.endercob ,'
            || ' d.endercom = s.endercom ,'
            || ' d.enderconjuge = s.enderconjuge ,'
            || ' d.enderempr = s.enderempr ,'
            || ' d.enderent = s.enderent ,'
            || ' d.enviadadosserasa = s.enviadadosserasa ,'
            || ' d.estcob = s.estcob ,'
            || ' d.estcom = s.estcom ,'
            || ' d.estconjuge = s.estconjuge ,'
            || ' d.estempr = s.estempr ,'
            || ' d.estent = s.estent ,'
            || ' d.exportardadosims = s.exportardadosims ,'
            || ' d.fantasia = s.fantasia ,'
            || ' d.faxcli = s.faxcli ,'
            || ' d.faxcom = s.faxcom ,'
            || ' d.filiacaomae = s.filiacaomae ,'
            || ' d.filiacaomaeconj = s.filiacaomaeconj ,'
            || ' d.filiacaopai = s.filiacaopai ,'
            || ' d.filiacaopaiconj = s.filiacaopaiconj ,'
            || ' d.freqdiavisita = s.freqdiavisita ,'
            || ' d.freqvisita = s.freqvisita ,'
            || ' d.gerenciamento = s.gerenciamento ,'
            || ' d.gruporamoativi = s.gruporamoativi ,'
            || ' d.horaproxcontato = s.horaproxcontato ,'
            || ' d.horarioreceb = s.horarioreceb ,'
            || ' d.icmsantecip = s.icmsantecip ,'
            || ' d.ieent = s.ieent ,'
            || ' d.ieps = s.ieps ,'
            || ' d.iest = s.iest ,'
            || ' d.iment = s.iment ,'
            || ' d.incluinoarqsci = s.incluinoarqsci ,'
            || ' d.inicioativ = s.inicioativ ,'
            || ' d.inscestadual = s.inscestadual ,'
            || ' d.isentajuros = s.isentajuros ,'
            || ' d.isentoicms = s.isentoicms ,'
            || ' d.isentoipi = s.isentoipi ,'
            || ' d.isentotxboleto = s.isentotxboleto ,'
            || ' d.iva = s.iva ,'
            || ' d.ivafonte = s.ivafonte ,'
            || ' d.limcred = s.limcred ,'
            || ' d.limiteautori = s.limiteautori ,'
            || ' d.listaplpag = s.listaplpag ,'
            || ' d.medcodfunclibtribut = s.medcodfunclibtribut ,'
            || ' d.meddtlibtribut = s.meddtlibtribut ,'
            || ' d.microempresa = s.microempresa ,'
            || ' d.minutoproxcontato = s.minutoproxcontato ,'
            || ' d.motivoexclusao = s.motivoexclusao ,'
            || ' d.municcob = s.municcob ,'
            || ' d.municcob2 = s.municcob2 ,'
            || ' d.municcom = s.municcom ,'
            || ' d.municcom2 = s.municcom2 ,'
            || ' d.municconjuge = s.municconjuge ,'
            || ' d.municempr = s.municempr ,'
            || ' d.municent = s.municent ,'
            || ' d.municent2 = s.municent2 ,'
            || ' d.municipiosefaz = s.municipiosefaz ,'
            || ' d.nomeconjuge = s.nomeconjuge ,'
            || ' d.numagencia1 = s.numagencia1 ,'
            || ' d.numagencia2 = s.numagencia2 ,'
            || ' d.numalvara = s.numalvara ,'
            || ' d.numalvarafunc = s.numalvarafunc ,'
            || ' d.numbanco1 = s.numbanco1 ,'
            || ' d.numbanco2 = s.numbanco2 ,'
            || ' d.numccorrente1 = s.numccorrente1 ,'
            || ' d.numccorrente2 = s.numccorrente2 ,'
            || ' d.numconcessao = s.numconcessao ,'
            || ' d.numregiaocli = s.numregiaocli ,'
            || ' d.numseq = s.numseq ,'
            || ' d.numseqatu = s.numseqatu ,'
            || ' d.numseqrotarca = s.numseqrotarca ,'
            || ' d.numtare = s.numtare ,'
            || ' d.numtransvendadesc = s.numtransvendadesc ,'
            || ' d.obs = s.obs ,'
            || ' d.obscallcenter = s.obscallcenter ,'
            || ' d.obscredito = s.obscredito ,'
            || ' d.obsentrega1 = s.obsentrega1 ,'
            || ' d.obsentrega2 = s.obsentrega2 ,'
            || ' d.obsentrega3 = s.obsentrega3 ,'
            || ' d.observacao = s.observacao ,'
            || ' d.obsgerencial1 = s.obsgerencial1 ,'
            || ' d.obsgerencial2 = s.obsgerencial2 ,'
            || ' d.obsgerencial3 = s.obsgerencial3 ,'
            || ' d.obsrecepcao = s.obsrecepcao ,'
            || ' d.obstesouraria = s.obstesouraria ,'
            || ' d.obs2 = s.obs2 ,'
            || ' d.obs3 = s.obs3 ,'
            || ' d.obs4 = s.obs4 ,'
            || ' d.obs5 = s.obs5 ,'
            || ' d.orgaopub = s.orgaopub ,'
            || ' d.orgaorg = s.orgaorg ,'
            || ' d.orgaorgconj = s.orgaorgconj ,'
            || ' d.origempreco = s.origempreco ,'
            || ' d.paisent = s.paisent ,'
            || ' d.paraibasim = s.paraibasim ,'
            || ' d.peracrestransf = s.peracrestransf ,'
            || ' d.perbasevend = s.perbasevend ,'
            || ' d.percbasevendqt = s.percbasevendqt ,'
            || ' d.percbonific = s.percbonific ,'
            || ' d.percomcli = s.percomcli ,'
            || ' d.perdesc = s.perdesc ,'
            || ' d.perdescfin = s.perdescfin ,'
            || ' d.perdescisentoicms = s.perdescisentoicms ,'
            || ' d.perdesc2 = s.perdesc2 ,'
            || ' d.perdesc3 = s.perdesc3 ,'
            || ' d.perdesc4 = s.perdesc4 ,'
            || ' d.perdesc5 = s.perdesc5 ,'
            || ' d.plpagneg = s.plpagneg ,'
            || ' d.plpagneg2 = s.plpagneg2 ,'
            || ' d.pontorefer = s.pontorefer ,'
            || ' d.prazoadicional = s.prazoadicional ,'
            || ' d.prazoadicional2 = s.prazoadicional2 ,'
            || ' d.prazoadicional3 = s.prazoadicional3 ,'
            || ' d.prazoadicional4 = s.prazoadicional4 ,'
            || ' d.prazoadicional5 = s.prazoadicional5 ,'
            || ' d.prazoadicional6 = s.prazoadicional6 ,'
            || ' d.prazoadicional7 = s.prazoadicional7 ,'
            || ' d.prazomaxvalidade = s.prazomaxvalidade ,'
            || ' d.prazovalidade = s.prazovalidade ,'
            || ' d.prazovenda = s.prazovenda ,'
            || ' d.predioproprio = s.predioproprio ,'
            || ' d.qtcheckout = s.qtcheckout ,'
            || ' d.qtestrela = s.qtestrela ,'
            || ' d.ratingsci = s.ratingsci ,'
            || ' d.ratingsci1 = s.ratingsci1 ,'
            || ' d.ratingsci2 = s.ratingsci2 ,'
            || ' d.regjuntacomercial = s.regjuntacomercial ,'
            || ' d.rendamensal = s.rendamensal ,'
            || ' d.rendamensalconjuge = s.rendamensalconjuge ,'
            || ' d.repasse = s.repasse ,'
            || ' d.ressarcimentost = s.ressarcimentost ,'
            || ' d.rfc = s.rfc ,'
            || ' d.rg = s.rg ,'
            || ' d.rgconj = s.rgconj ,'
            || ' d.roteiromasterfoods = s.roteiromasterfoods ,'
            || ' d.senha_web = s.senha_web ,'
            || ' d.sexo = s.sexo ,'
            || ' d.sigladec = s.sigladec ,'
            || ' d.site = s.site ,'
            || ' d.sulframa = s.sulframa ,'
            || ' d.suprimido = s.suprimido ,'
            || ' d.telcelent = s.telcelent ,'
            || ' d.telcob = s.telcob ,'
            || ' d.telcom = s.telcom ,'
            || ' d.telconjuge = s.telconjuge ,'
            || ' d.telempr = s.telempr ,'
            || ' d.telent = s.telent ,'
            || ' d.telent1 = s.telent1 ,'
            || ' d.tipoclimed = s.tipoclimed ,'
            || ' d.tipoconversaotv4 = s.tipoconversaotv4 ,'
            || ' d.tipocustotransf = s.tipocustotransf ,'
            || ' d.tipodescisencao = s.tipodescisencao ,'
            || ' d.tipoempresa = s.tipoempresa ,'
            || ' d.tipofj = s.tipofj ,'
            || ' d.tipoultalter = s.tipoultalter ,'
            || ' d.ufrg = s.ufrg ,'
            || ' d.ultcodplpag = s.ultcodplpag ,'
            || ' d.usabkcnpjcodcliprinc = s.usabkcnpjcodcliprinc ,'
            || ' d.usacross = s.usacross ,'
            || ' d.usaivafontediferenciado = s.usaivafontediferenciado ,'
            || ' d.usavlminvendabk = s.usavlminvendabk ,'
            || ' d.utilizaiesimplificada = s.utilizaiesimplificada ,'
            || ' d.validamaxvendapf = s.validamaxvendapf ,'
            || ' d.validarcampanhabrinde = s.validarcampanhabrinde ,'
            || ' d.validarmultiplovenda = s.validarmultiplovenda ,'
            || ' d.valoraluguel = s.valoraluguel ,'
            || ' d.vip = s.vip ,'
            || ' d.vlestoque = s.vlestoque ,'
            || ' d.vlmediacompramesfornec = s.vlmediacompramesfornec ,'
            || ' d.vloutrasrendas = s.vloutrasrendas ,'
            || ' d.vlpotenciallimcred = s.vlpotenciallimcred '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (aceitachterceiros,'
            || ' aceitatrocanegativa,'
            || ' aceitavendafracao,'
            || ' aliqicms1,'
            || ' analisecred,'
            || ' aplicadescnf,'
            || ' bairrocob,'
            || ' bairrocom,'
            || ' bairroent,'
            || ' bloqueio,'
            || ' bloqueiosefaz,'
            || ' cacex,'
            || ' caixapostal,'
            || ' calculast,'
            || ' capitalsocial,'
            || ' cargo,'
            || ' cargoconjuge,'
            || ' cepcob,'
            || ' cepcom,'
            || ' cepcxpostal,'
            || ' cepent,'
            || ' cgcent,'
            || ' cgcentrega,'
            || ' cgeentaux,'
            || ' classecomercial,'
            || ' classemc,'
            || ' classevenda,'
            || ' cliente,'
            || ' clientedan,'
            || ' clienteeletro,'
            || ' clientefontest,'
            || ' clientemonitorado,'
            || ' cliente2,'
            || ' clientprotesto,'
            || ' codatv1,'
            || ' codbarra,'
            || ' codbarracob,'
            || ' codbarraent,'
            || ' codcanal,'
            || ' codcidade,'
            || ' codcli,'
            || ' codclipalm,'
            || ' codcliprinc,'
            || ' codcob,'
            || ' codcondicaovenda,'
            || ' codfilialestoque,'
            || ' codfilialnf,'
            || ' codfunccad,'
            || ' codfunccadastro,'
            || ' codfunclancpotenciallimcred,'
            || ' codfuncultalter,'
            || ' codfuncultaltercliesp,'
            || ' codfuncultcontatocob,'
            || ' codmunicipio,'
            || ' codnilsen,'
            || ' codplpag,'
            || ' codplpagpadrao,'
            || ' codplpag2,'
            || ' codpraca,'
            || ' codstatuscob,'
            || ' codsuframa,'
            || ' codusur1,'
            || ' codusur2,'
            || ' codusur3,'
            || ' complementoent,'
            || ' condvenda1,'
            || ' condvenda10,'
            || ' condvenda11,'
            || ' condvenda12,'
            || ' condvenda13,'
            || ' condvenda14,'
            || ' condvenda2,'
            || ' condvenda20,'
            || ' condvenda3,'
            || ' condvenda4,'
            || ' condvenda5,'
            || ' condvenda6,'
            || ' condvenda7,'
            || ' condvenda8,'
            || ' condvenda9,'
            || ' condvenda98,'
            || ' condvenda99,'
            || ' consumidorfinal,'
            || ' contribuinte,'
            || ' cpfconjuge,'
            || ' dddinternacional,'
            || ' descproduto,'
            || ' destacafrete,'
            || ' diasemana,'
            || ' digagencia1,'
            || ' digagencia2,'
            || ' diretoriocliente,'
            || ' dtabertcc1,'
            || ' dtabertcc2,'
            || ' dtadmissao,'
            || ' dtadmissaoconjuge,'
            || ' dtbloq,'
            || ' dtcadastro,'
            || ' dtcapitalsocial,'
            || ' dtclassificaestrela,'
            || ' dtclassificagrupo,'
            || ' dtdesbloqueio,'
            || ' dtenquadramentomicroempresa,'
            || ' dtexclusao,'
            || ' dtlancpotenciallimcred,'
            || ' dtnasc,'
            || ' dtnascconj,'
            || ' dtprimcompra,'
            || ' dtproxcontatocob,'
            || ' dtreglim,'
            || ' dtultalter,'
            || ' dtultaltercliesp,'
            || ' dtultcomp,'
            || ' dtultcompnestle,'
            || ' dtultconsultasci,'
            || ' dtultconsultaserasa,'
            || ' dtultconsultasintegra,'
            || ' dtultcontatocob,'
            || ' dtultvisita,'
            || ' dtvalidasefaz,'
            || ' dtvencalvara,'
            || ' dtvencalvarafunc,'
            || ' dtvenclimcred,'
            || ' dtvencprazoadicional,'
            || ' dtvencsuframa,'
            || ' eancobranca,'
            || ' eanentrega,'
            || ' edocob,'
            || ' edocom,'
            || ' edoent,'
            || ' email,'
            || ' emitedae,'
            || ' emitedup,'
            || ' emitentech,'
            || ' emitentech2,'
            || ' empfixa,'
            || ' empresa,'
            || ' empresaconjuge,'
            || ' endercob,'
            || ' endercom,'
            || ' enderconjuge,'
            || ' enderempr,'
            || ' enderent,'
            || ' enviadadosserasa,'
            || ' estcob,'
            || ' estcom,'
            || ' estconjuge,'
            || ' estempr,'
            || ' estent,'
            || ' exportardadosims,'
            || ' fantasia,'
            || ' faxcli,'
            || ' faxcom,'
            || ' filiacaomae,'
            || ' filiacaomaeconj,'
            || ' filiacaopai,'
            || ' filiacaopaiconj,'
            || ' freqdiavisita,'
            || ' freqvisita,'
            || ' gerenciamento,'
            || ' gruporamoativi,'
            || ' horaproxcontato,'
            || ' horarioreceb,'
            || ' icmsantecip,'
            || ' ieent,'
            || ' ieps,'
            || ' iest,'
            || ' iment,'
            || ' incluinoarqsci,'
            || ' inicioativ,'
            || ' inscestadual,'
            || ' isentajuros,'
            || ' isentoicms,'
            || ' isentoipi,'
            || ' isentotxboleto,'
            || ' iva,'
            || ' ivafonte,'
            || ' limcred,'
            || ' limiteautori,'
            || ' listaplpag,'
            || ' medcodfunclibtribut,'
            || ' meddtlibtribut,'
            || ' microempresa,'
            || ' minutoproxcontato,'
            || ' motivoexclusao,'
            || ' municcob,'
            || ' municcob2,'
            || ' municcom,'
            || ' municcom2,'
            || ' municconjuge,'
            || ' municempr,'
            || ' municent,'
            || ' municent2,'
            || ' municipiosefaz,'
            || ' nomeconjuge,'
            || ' numagencia1,'
            || ' numagencia2,'
            || ' numalvara,'
            || ' numalvarafunc,'
            || ' numbanco1,'
            || ' numbanco2,'
            || ' numccorrente1,'
            || ' numccorrente2,'
            || ' numconcessao,'
            || ' numregiaocli,'
            || ' numseq,'
            || ' numseqatu,'
            || ' numseqrotarca,'
            || ' numtare,'
            || ' numtransvendadesc,'
            || ' obs,'
            || ' obscallcenter,'
            || ' obscredito,'
            || ' obsentrega1,'
            || ' obsentrega2,'
            || ' obsentrega3,'
            || ' observacao,'
            || ' obsgerencial1,'
            || ' obsgerencial2,'
            || ' obsgerencial3,'
            || ' obsrecepcao,'
            || ' obstesouraria,'
            || ' obs2,'
            || ' obs3,'
            || ' obs4,'
            || ' obs5,'
            || ' orgaopub,'
            || ' orgaorg,'
            || ' orgaorgconj,'
            || ' origempreco,'
            || ' paisent,'
            || ' paraibasim,'
            || ' peracrestransf,'
            || ' perbasevend,'
            || ' percbasevendqt,'
            || ' percbonific,'
            || ' percomcli,'
            || ' perdesc,'
            || ' perdescfin,'
            || ' perdescisentoicms,'
            || ' perdesc2,'
            || ' perdesc3,'
            || ' perdesc4,'
            || ' perdesc5,'
            || ' plpagneg,'
            || ' plpagneg2,'
            || ' pontorefer,'
            || ' prazoadicional,'
            || ' prazoadicional2,'
            || ' prazoadicional3,'
            || ' prazoadicional4,'
            || ' prazoadicional5,'
            || ' prazoadicional6,'
            || ' prazoadicional7,'
            || ' prazomaxvalidade,'
            || ' prazovalidade,'
            || ' prazovenda,'
            || ' predioproprio,'
            || ' qtcheckout,'
            || ' qtestrela,'
            || ' ratingsci,'
            || ' ratingsci1,'
            || ' ratingsci2,'
            || ' regjuntacomercial,'
            || ' rendamensal,'
            || ' rendamensalconjuge,'
            || ' repasse,'
            || ' ressarcimentost,'
            || ' rfc,'
            || ' rg,'
            || ' rgconj,'
            || ' roteiromasterfoods,'
            || ' senha_web,'
            || ' sexo,'
            || ' sigladec,'
            || ' site,'
            || ' sulframa,'
            || ' suprimido,'
            || ' telcelent,'
            || ' telcob,'
            || ' telcom,'
            || ' telconjuge,'
            || ' telempr,'
            || ' telent,'
            || ' telent1,'
            || ' tipoclimed,'
            || ' tipoconversaotv4,'
            || ' tipocustotransf,'
            || ' tipodescisencao,'
            || ' tipoempresa,'
            || ' tipofj,'
            || ' tipoultalter,'
            || ' ufrg,'
            || ' ultcodplpag,'
            || ' usabkcnpjcodcliprinc,'
            || ' usacross,'
            || ' usaivafontediferenciado,'
            || ' usavlminvendabk,'
            || ' utilizaiesimplificada,'
            || ' validamaxvendapf,'
            || ' validarcampanhabrinde,'
            || ' validarmultiplovenda,'
            || ' valoraluguel,'
            || ' vip,'
            || ' vlestoque,'
            || ' vlmediacompramesfornec,'
            || ' vloutrasrendas,'
            || ' vlpotenciallimcred) '
            || ' VALUES (s.aceitachterceiros,'
            || ' s.aceitatrocanegativa,'
            || ' s.aceitavendafracao,'
            || ' s.aliqicms1,'
            || ' s.analisecred,'
            || ' s.aplicadescnf,'
            || ' s.bairrocob,'
            || ' s.bairrocom,'
            || ' s.bairroent,'
            || ' s.bloqueio,'
            || ' s.bloqueiosefaz,'
            || ' s.cacex,'
            || ' s.caixapostal,'
            || ' s.calculast,'
            || ' s.capitalsocial,'
            || ' s.cargo,'
            || ' s.cargoconjuge,'
            || ' s.cepcob,'
            || ' s.cepcom,'
            || ' s.cepcxpostal,'
            || ' s.cepent,'
            || ' s.cgcent,'
            || ' s.cgcentrega,'
            || ' s.cgeentaux,'
            || ' s.classecomercial,'
            || ' s.classemc,'
            || ' s.classevenda,'
            || ' s.cliente,'
            || ' s.clientedan,'
            || ' s.clienteeletro,'
            || ' s.clientefontest,'
            || ' s.clientemonitorado,'
            || ' s.cliente2,'
            || ' s.clientprotesto,'
            || ' s.codatv1,'
            || ' s.codbarra,'
            || ' s.codbarracob,'
            || ' s.codbarraent,'
            || ' s.codcanal,'
            || ' s.codcidade,'
            || ' s.codcli,'
            || ' s.codclipalm,'
            || ' s.codcliprinc,'
            || ' s.codcob,'
            || ' s.codcondicaovenda,'
            || ' s.codfilialestoque,'
            || ' s.codfilialnf,'
            || ' s.codfunccad,'
            || ' s.codfunccadastro,'
            || ' s.codfunclancpotenciallimcred,'
            || ' s.codfuncultalter,'
            || ' s.codfuncultaltercliesp,'
            || ' s.codfuncultcontatocob,'
            || ' s.codmunicipio,'
            || ' s.codnilsen,'
            || ' s.codplpag,'
            || ' s.codplpagpadrao,'
            || ' s.codplpag2,'
            || ' s.codpraca,'
            || ' s.codstatuscob,'
            || ' s.codsuframa,'
            || ' s.codusur1,'
            || ' s.codusur2,'
            || ' s.codusur3,'
            || ' s.complementoent,'
            || ' s.condvenda1,'
            || ' s.condvenda10,'
            || ' s.condvenda11,'
            || ' s.condvenda12,'
            || ' s.condvenda13,'
            || ' s.condvenda14,'
            || ' s.condvenda2,'
            || ' s.condvenda20,'
            || ' s.condvenda3,'
            || ' s.condvenda4,'
            || ' s.condvenda5,'
            || ' s.condvenda6,'
            || ' s.condvenda7,'
            || ' s.condvenda8,'
            || ' s.condvenda9,'
            || ' s.condvenda98,'
            || ' s.condvenda99,'
            || ' s.consumidorfinal,'
            || ' s.contribuinte,'
            || ' s.cpfconjuge,'
            || ' s.dddinternacional,'
            || ' s.descproduto,'
            || ' s.destacafrete,'
            || ' s.diasemana,'
            || ' s.digagencia1,'
            || ' s.digagencia2,'
            || ' s.diretoriocliente,'
            || ' s.dtabertcc1,'
            || ' s.dtabertcc2,'
            || ' s.dtadmissao,'
            || ' s.dtadmissaoconjuge,'
            || ' s.dtbloq,'
            || ' s.dtcadastro,'
            || ' s.dtcapitalsocial,'
            || ' s.dtclassificaestrela,'
            || ' s.dtclassificagrupo,'
            || ' s.dtdesbloqueio,'
            || ' s.dtenquadramentomicroempresa,'
            || ' s.dtexclusao,'
            || ' s.dtlancpotenciallimcred,'
            || ' s.dtnasc,'
            || ' s.dtnascconj,'
            || ' s.dtprimcompra,'
            || ' s.dtproxcontatocob,'
            || ' s.dtreglim,'
            || ' s.dtultalter,'
            || ' s.dtultaltercliesp,'
            || ' s.dtultcomp,'
            || ' s.dtultcompnestle,'
            || ' s.dtultconsultasci,'
            || ' s.dtultconsultaserasa,'
            || ' s.dtultconsultasintegra,'
            || ' s.dtultcontatocob,'
            || ' s.dtultvisita,'
            || ' s.dtvalidasefaz,'
            || ' s.dtvencalvara,'
            || ' s.dtvencalvarafunc,'
            || ' s.dtvenclimcred,'
            || ' s.dtvencprazoadicional,'
            || ' s.dtvencsuframa,'
            || ' s.eancobranca,'
            || ' s.eanentrega,'
            || ' s.edocob,'
            || ' s.edocom,'
            || ' s.edoent,'
            || ' s.email,'
            || ' s.emitedae,'
            || ' s.emitedup,'
            || ' s.emitentech,'
            || ' s.emitentech2,'
            || ' s.empfixa,'
            || ' s.empresa,'
            || ' s.empresaconjuge,'
            || ' s.endercob,'
            || ' s.endercom,'
            || ' s.enderconjuge,'
            || ' s.enderempr,'
            || ' s.enderent,'
            || ' s.enviadadosserasa,'
            || ' s.estcob,'
            || ' s.estcom,'
            || ' s.estconjuge,'
            || ' s.estempr,'
            || ' s.estent,'
            || ' s.exportardadosims,'
            || ' s.fantasia,'
            || ' s.faxcli,'
            || ' s.faxcom,'
            || ' s.filiacaomae,'
            || ' s.filiacaomaeconj,'
            || ' s.filiacaopai,'
            || ' s.filiacaopaiconj,'
            || ' s.freqdiavisita,'
            || ' s.freqvisita,'
            || ' s.gerenciamento,'
            || ' s.gruporamoativi,'
            || ' s.horaproxcontato,'
            || ' s.horarioreceb,'
            || ' s.icmsantecip,'
            || ' s.ieent,'
            || ' s.ieps,'
            || ' s.iest,'
            || ' s.iment,'
            || ' s.incluinoarqsci,'
            || ' s.inicioativ,'
            || ' s.inscestadual,'
            || ' s.isentajuros,'
            || ' s.isentoicms,'
            || ' s.isentoipi,'
            || ' s.isentotxboleto,'
            || ' s.iva,'
            || ' s.ivafonte,'
            || ' s.limcred,'
            || ' s.limiteautori,'
            || ' s.listaplpag,'
            || ' s.medcodfunclibtribut,'
            || ' s.meddtlibtribut,'
            || ' s.microempresa,'
            || ' s.minutoproxcontato,'
            || ' s.motivoexclusao,'
            || ' s.municcob,'
            || ' s.municcob2,'
            || ' s.municcom,'
            || ' s.municcom2,'
            || ' s.municconjuge,'
            || ' s.municempr,'
            || ' s.municent,'
            || ' s.municent2,'
            || ' s.municipiosefaz,'
            || ' s.nomeconjuge,'
            || ' s.numagencia1,'
            || ' s.numagencia2,'
            || ' s.numalvara,'
            || ' s.numalvarafunc,'
            || ' s.numbanco1,'
            || ' s.numbanco2,'
            || ' s.numccorrente1,'
            || ' s.numccorrente2,'
            || ' s.numconcessao,'
            || ' s.numregiaocli,'
            || ' s.numseq,'
            || ' s.numseqatu,'
            || ' s.numseqrotarca,'
            || ' s.numtare,'
            || ' s.numtransvendadesc,'
            || ' s.obs,'
            || ' s.obscallcenter,'
            || ' s.obscredito,'
            || ' s.obsentrega1,'
            || ' s.obsentrega2,'
            || ' s.obsentrega3,'
            || ' s.observacao,'
            || ' s.obsgerencial1,'
            || ' s.obsgerencial2,'
            || ' s.obsgerencial3,'
            || ' s.obsrecepcao,'
            || ' s.obstesouraria,'
            || ' s.obs2,'
            || ' s.obs3,'
            || ' s.obs4,'
            || ' s.obs5,'
            || ' s.orgaopub,'
            || ' s.orgaorg,'
            || ' s.orgaorgconj,'
            || ' s.origempreco,'
            || ' s.paisent,'
            || ' s.paraibasim,'
            || ' s.peracrestransf,'
            || ' s.perbasevend,'
            || ' s.percbasevendqt,'
            || ' s.percbonific,'
            || ' s.percomcli,'
            || ' s.perdesc,'
            || ' s.perdescfin,'
            || ' s.perdescisentoicms,'
            || ' s.perdesc2,'
            || ' s.perdesc3,'
            || ' s.perdesc4,'
            || ' s.perdesc5,'
            || ' s.plpagneg,'
            || ' s.plpagneg2,'
            || ' s.pontorefer,'
            || ' s.prazoadicional,'
            || ' s.prazoadicional2,'
            || ' s.prazoadicional3,'
            || ' s.prazoadicional4,'
            || ' s.prazoadicional5,'
            || ' s.prazoadicional6,'
            || ' s.prazoadicional7,'
            || ' s.prazomaxvalidade,'
            || ' s.prazovalidade,'
            || ' s.prazovenda,'
            || ' s.predioproprio,'
            || ' s.qtcheckout,'
            || ' s.qtestrela,'
            || ' s.ratingsci,'
            || ' s.ratingsci1,'
            || ' s.ratingsci2,'
            || ' s.regjuntacomercial,'
            || ' s.rendamensal,'
            || ' s.rendamensalconjuge,'
            || ' s.repasse,'
            || ' s.ressarcimentost,'
            || ' s.rfc,'
            || ' s.rg,'
            || ' s.rgconj,'
            || ' s.roteiromasterfoods,'
            || ' s.senha_web,'
            || ' s.sexo,'
            || ' s.sigladec,'
            || ' s.site,'
            || ' s.sulframa,'
            || ' s.suprimido,'
            || ' s.telcelent,'
            || ' s.telcob,'
            || ' s.telcom,'
            || ' s.telconjuge,'
            || ' s.telempr,'
            || ' s.telent,'
            || ' s.telent1,'
            || ' s.tipoclimed,'
            || ' s.tipoconversaotv4,'
            || ' s.tipocustotransf,'
            || ' s.tipodescisencao,'
            || ' s.tipoempresa,'
            || ' s.tipofj,'
            || ' s.tipoultalter,'
            || ' s.ufrg,'
            || ' s.ultcodplpag,'
            || ' s.usabkcnpjcodcliprinc,'
            || ' s.usacross,'
            || ' s.usaivafontediferenciado,'
            || ' s.usavlminvendabk,'
            || ' s.utilizaiesimplificada,'
            || ' s.validamaxvendapf,'
            || ' s.validarcampanhabrinde,'
            || ' s.validarmultiplovenda,'
            || ' s.valoraluguel,'
            || ' s.vip,'
            || ' s.vlestoque,'
            || ' s.vlmediacompramesfornec,'
            || ' s.vloutrasrendas,'
            || ' s.vlpotenciallimcred)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcclient;

   FUNCTION importar_pccob (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccob';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codcob varchar2(4),'
         || '  cobranca varchar2(30),'
         || '  pagcomissao varchar2(1),'
         || '  txjuros number(6,2),'
         || '  codmoeda varchar2(4),'
         || '  baixacxbanco varchar2(1),'
         || '  nivelvenda number(2,0),'
         || '  fluxocx varchar2(1),'
         || '  colunafluxocx number(2,0),'
         || '  numdiasvencfluxocx number(2,0),'
         || '  bloqautomatico varchar2(1),'
         || '  numdiasbloqautomatic number(4,0),'
         || '  exibircxmot varchar2(1),'
         || '  exibirbk varchar2(1),'
         || '  percacresvenda number(6,2),'
         || '  prazomaximovenda number(4,0),'
         || '  letracob varchar2(2),'
         || '  boleto varchar2(1),'
         || '  custodia varchar2(1),'
         || '  permitealtcobdesd varchar2(1),'
         || '  percom number(6,2),'
         || '  vltarifa number(14,2),'
         || '  codecf varchar2(6),'
         || '  cartao varchar2(1),'
         || '  obsnf varchar2(100),'
         || '  numdiasliberacaocredito number(2,0),'
         || '  codclicc number(6,0),'
         || '  prazocc number(4,0),'
         || '  perctxadmincc number(5,2),'
         || '  codcontacc number(10,0),'
         || '  codcobcc varchar2(4),'
         || '  enviacobrancafv varchar2(1),'
         || '  validalimcredecf varchar2(1),'
         || '  diascarencia number(4,0),'
         || '  acertoautocxmot varchar2(1),'
         || '  numdiasprotesto varchar2(2),'
         || '  codparaprotesto varchar2(2),'
         || '  envioparaprotesto varchar2(1),'
         || '  numbanco number(4,0),'
         || '  permitedescdevcli varchar2(1),'
         || '  percommot number(5,2),'
         || '  cobrancabroker varchar2(1),'
         || '  vlminpedido number(12,2),'
         || '  tipocomissao varchar2(1),'
         || '  codbancotarifa number(4,0),'
         || '  depositobancario varchar2(1),'
         || '  codfilial varchar2(2),'
         || '  exportarecf varchar2(1),'
         || '  codbanco number(4,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codcob = s.codcob) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.cobranca= s.cobranca,'
            || '     d.pagcomissao= s.pagcomissao,'
            || '     d.txjuros= s.txjuros,'
            || '     d.codmoeda= s.codmoeda,'
            || '     d.baixacxbanco= s.baixacxbanco,'
            || '     d.nivelvenda= s.nivelvenda,'
            || '     d.fluxocx= s.fluxocx,'
            || '     d.colunafluxocx= s.colunafluxocx,'
            || '     d.numdiasvencfluxocx= s.numdiasvencfluxocx,'
            || '     d.bloqautomatico= s.bloqautomatico,'
            || '     d.numdiasbloqautomatic= s.numdiasbloqautomatic,'
            || '     d.exibircxmot= s.exibircxmot,'
            || '     d.exibirbk= s.exibirbk,'
            || '     d.percacresvenda= s.percacresvenda,'
            || '     d.prazomaximovenda= s.prazomaximovenda,'
            || '     d.letracob= s.letracob,'
            || '     d.boleto= s.boleto,'
            || '     d.custodia= s.custodia,'
            || '     d.permitealtcobdesd= s.permitealtcobdesd,'
            || '     d.percom= s.percom,'
            || '     d.vltarifa= s.vltarifa,'
            || '     d.codecf= s.codecf,'
            || '     d.cartao= s.cartao,'
            || '     d.obsnf= s.obsnf,'
            || '     d.numdiasliberacaocredito= s.numdiasliberacaocredito,'
            || '     d.codclicc= s.codclicc,'
            || '     d.prazocc= s.prazocc,'
            || '     d.perctxadmincc= s.perctxadmincc,'
            || '     d.codcontacc= s.codcontacc,'
            || '     d.codcobcc= s.codcobcc,'
            || '     d.enviacobrancafv= s.enviacobrancafv,'
            || '     d.validalimcredecf= s.validalimcredecf,'
            || '     d.diascarencia= s.diascarencia,'
            || '     d.acertoautocxmot= s.acertoautocxmot,'
            || '     d.numdiasprotesto= s.numdiasprotesto,'
            || '     d.codparaprotesto= s.codparaprotesto,'
            || '     d.envioparaprotesto= s.envioparaprotesto,'
            || '     d.numbanco= s.numbanco,'
            || '     d.permitedescdevcli= s.permitedescdevcli,'
            || '     d.percommot= s.percommot,'
            || '     d.cobrancabroker= s.cobrancabroker,'
            || '     d.vlminpedido= s.vlminpedido,'
            || '     d.tipocomissao= s.tipocomissao,'
            || '     d.codbancotarifa= s.codbancotarifa,'
            || '     d.depositobancario= s.depositobancario,'
            || '     d.codfilial= s.codfilial,'
            || '     d.exportarecf= s.exportarecf,'
            || '     d.codbanco= s.codbanco'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codcob, cobranca, pagcomissao, txjuros, codmoeda, baixacxbanco, nivelvenda, fluxocx, colunafluxocx,'
            || '         numdiasvencfluxocx, bloqautomatico, numdiasbloqautomatic, exibircxmot, exibirbk, percacresvenda,'
            || '         prazomaximovenda, letracob, boleto, custodia, permitealtcobdesd, percom, vltarifa, codecf, cartao,'
            || '         obsnf, numdiasliberacaocredito, codclicc, prazocc, perctxadmincc, codcontacc, codcobcc,'
            || '         enviacobrancafv, validalimcredecf, diascarencia, acertoautocxmot, numdiasprotesto, codparaprotesto,'
            || '         envioparaprotesto, numbanco, permitedescdevcli, percommot, cobrancabroker, vlminpedido, tipocomissao,'
            || '         codbancotarifa, depositobancario, codfilial, exportarecf, codbanco) '
            || ' VALUES (s.codcob, s.cobranca, s.pagcomissao, s.txjuros, s.codmoeda, s.baixacxbanco, s.nivelvenda,'
            || '         s.fluxocx, s.colunafluxocx, s.numdiasvencfluxocx, s.bloqautomatico, s.numdiasbloqautomatic,'
            || '         s.exibircxmot, s.exibirbk, s.percacresvenda, s.prazomaximovenda, s.letracob, s.boleto,'
            || '         s.custodia, s.permitealtcobdesd, s.percom, s.vltarifa, s.codecf, s.cartao, s.obsnf,'
            || '         s.numdiasliberacaocredito, s.codclicc, s.prazocc, s.perctxadmincc, s.codcontacc,'
            || '         s.codcobcc, s.enviacobrancafv, s.validalimcredecf, s.diascarencia, s.acertoautocxmot,'
            || '         s.numdiasprotesto, s.codparaprotesto, s.envioparaprotesto, s.numbanco, s.permitedescdevcli,'
            || '         s.percommot, s.cobrancabroker, s.vlminpedido, s.tipocomissao, s.codbancotarifa, '
            || '         s.depositobancario, s.codfilial, s.exportarecf, s.codbanco)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pccob;

   FUNCTION importar_pccontro (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccontro';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codusuario number(8,0),'
         || '  codrotina number(6,0),'
         || '  acesso varchar2(1),'
         || '  codbanco number(4,0),'
         || '  codmoeda varchar2(4),'
         || '  codepto number(6,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codusuario = s.codusuario and'
            || '     d.codrotina  = s.codrotina) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.acesso = s.acesso,'
            || '     d.codbanco = s.codbanco,'
            || '     d.codmoeda = s.codmoeda,'
            || '     d.codepto = s.codepto'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codusuario, codrotina, acesso, codbanco, codmoeda, codepto)'
            || ' VALUES (s.codusuario, s.codrotina, s.acesso, s.codbanco, s.codmoeda, s.codepto)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pccontro;

   FUNCTION importar_pccontroi (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccontroi';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codrotina number(6,0),'
         || '  codcontrole number(6,0),'
         || '  codusuario number(8,0),'
         || '  acesso varchar2(1))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codrotina = s.codrotina and'
            || '     d.codcontrole = s.codcontrole and '
            || '     d.codusuario = s.codusuario) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.acesso = s.acesso'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codrotina, codcontrole, codusuario, acesso) '
            || ' VALUES (s.codrotina, s.codcontrole, s.codusuario, s.acesso)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pccontroi;

   FUNCTION importar_pcdepto (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcdepto';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codepto number(6,0),'
         || '  descricao varchar2(25),'
         || '  percpartvendaprev number(8,4),'
         || '  percmargemprev number(8,4),'
         || '  tipomerc varchar2(2),'
         || '  emiteqtunit varchar2(1),'
         || '  atualizainvgeral varchar2(1))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codepto = s.codepto) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.descricao = s.descricao,'
            || '     d.percpartvendaprev = s.percpartvendaprev,'
            || '     d.percmargemprev = s.percmargemprev,'
            || '     d.tipomerc = s.tipomerc,'
            || '     d.emiteqtunit = s.emiteqtunit,'
            || '     d.atualizainvgeral = s.atualizainvgeral'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codepto, descricao, percpartvendaprev, percmargemprev, tipomerc, emiteqtunit, atualizainvgeral) '
            || ' VALUES (s.codepto, s.descricao, s.percpartvendaprev, s.percmargemprev, s.tipomerc, s.emiteqtunit, s.atualizainvgeral)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcdepto;

   FUNCTION importar_pccobecf (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccobecf';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codcob VARCHAR2(4),'
         || ' parcela NUMBER(4,0),'
         || ' perjuros NUMBER(6,2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codcob = s.codcob) AND (d.parcela = s.parcela)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.perjuros = s.perjuros '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codcob, parcela, perjuros ) '
            || ' VALUES (s.codcob, s.parcela, s.perjuros )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pccobecf;

   FUNCTION importar_pcservintercancel (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vstabela := 'pcservintercancel';

      IF checar_arquivo_importacao (pscodfilial, vstabela)
      THEN
         vbresultado := FALSE;
         --> .exp principal -> intermediario
         vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem := vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         -- Importacao
         v_sql :=
               'CREATE TABLE imp_'
            || vstabela
            || ' ( codfilial VARCHAR2(2),'
            || ' codfunccx NUMBER(8,0),'
            || ' data DATE,'
            || ' dtexportacao DATE,'
            || ' dtimportacao DATE,'
            || ' itens_exp_pcmov NUMBER(8,0),'
            || ' itens_exp_pcnfcan NUMBER(8,0),'
            || ' itens_exp_pcnfcanitem NUMBER(8,0),'
            || ' itens_exp_pcnfsaid NUMBER(8,0),'
            || ' itens_exp_pcpedc NUMBER(8,0),'
            || ' itens_exp_pcpedccancecf NUMBER(8,0),'
            || ' itens_exp_pcpedi NUMBER(8,0),'
            || ' itens_exp_pcpedicancecf NUMBER(8,0),'
            || ' itens_imp_pcmov NUMBER(8,0),'
            || ' itens_imp_pcnfcan NUMBER(8,0),'
            || ' itens_imp_pcnfcanitem NUMBER(8,0),'
            || ' itens_imp_pcnfsaid NUMBER(8,0),'
            || ' itens_imp_pcpedc NUMBER(8,0),'
            || ' itens_imp_pcpedccancecf NUMBER(8,0),'
            || ' itens_imp_pcpedi NUMBER(8,0),'
            || ' itens_imp_pcpedicancecf NUMBER(8,0),'
            || ' numcaixa NUMBER(4,0),'
            || ' numped NUMBER(10,0),'
            || ' numpedecf NUMBER(10,0),'
            || ' numserieequip VARCHAR2(30),'
            || ' numtransvendaecf NUMBER(10,0),'
            || ' numtransvendawinthor NUMBER(10,0),'
            || ' serieecf VARCHAR2(2),'
            || ' status VARCHAR2(1),'
            || ' tipo VARCHAR2(1) ) '
            || ' ORGANIZATION EXTERNAL '
            || ' ( TYPE oracle_datapump '
            || ' DEFAULT DIRECTORY autoserv_dat_dir '
            || ' ACCESS PARAMETERS '
            || ' ( LOGFILE autoserv_log_dir: '''
            || vsnomearquivo
            || '%a_%p.log'' )'
            || ' LOCATION ('''
            || vsnomearquivo
            || '''))'
            || ' REJECT LIMIT UNLIMITED ';

         EXECUTE IMMEDIATE v_sql;

         BEGIN
            v_sql :=
                  ' MERGE INTO '
               || vstabela
               || ' d USING (SELECT * '
               || ' FROM imp_'
               || vstabela
               || ') s '
               || ' ON ( (d.codfilial = s.codfilial)'
               || '  AND (d.data = s.data)'
               || '  AND (d.serieecf = s.serieecf)'
               || '  AND (d.numpedecf = s.numpedecf)'
               || '  AND (d.numcaixa = s.numcaixa)'
               || '  AND (d.codfunccx = s.codfunccx)'
               || '  AND (d.numserieequip = s.numserieequip))'
               || ' WHEN MATCHED THEN '
               || ' UPDATE SET d.dtexportacao = s.dtexportacao ,'
               || ' d.dtimportacao = s.dtimportacao ,'
               || ' d.itens_exp_pcmov = s.itens_exp_pcmov ,'
               || ' d.itens_exp_pcnfcan = s.itens_exp_pcnfcan ,'
               || ' d.itens_exp_pcnfcanitem = s.itens_exp_pcnfcanitem ,'
               || ' d.itens_exp_pcnfsaid = s.itens_exp_pcnfsaid ,'
               || ' d.itens_exp_pcpedc = s.itens_exp_pcpedc ,'
               || ' d.itens_exp_pcpedccancecf = s.itens_exp_pcpedccancecf ,'
               || ' d.itens_exp_pcpedi = s.itens_exp_pcpedi ,'
               || ' d.itens_exp_pcpedicancecf = s.itens_exp_pcpedicancecf ,'
               || ' d.itens_imp_pcmov = s.itens_imp_pcmov ,'
               || ' d.itens_imp_pcnfcan = s.itens_imp_pcnfcan ,'
               || ' d.itens_imp_pcnfcanitem = s.itens_imp_pcnfcanitem ,'
               || ' d.itens_imp_pcnfsaid = s.itens_imp_pcnfsaid ,'
               || ' d.itens_imp_pcpedc = s.itens_imp_pcpedc ,'
               || ' d.itens_imp_pcpedccancecf = s.itens_imp_pcpedccancecf ,'
               || ' d.itens_imp_pcpedi = s.itens_imp_pcpedi ,'
               || ' d.itens_imp_pcpedicancecf = s.itens_imp_pcpedicancecf ,'
               || ' d.numped = s.numped ,'
               || ' d.numtransvendaecf = s.numtransvendaecf ,'
               || ' d.numtransvendawinthor = s.numtransvendawinthor ,'
               || ' d.status = decode(s.status, ''X'', ''R'', ''Y'', ''N'', s.status), '
               || ' d.tipo = s.tipo '
               || ' WHEN NOT MATCHED THEN '
               || ' INSERT ( codfilial,'
               || ' codfunccx,'
               || ' data,'
               || ' dtexportacao,'
               || ' dtimportacao,'
               || ' itens_exp_pcmov,'
               || ' itens_exp_pcnfcan,'
               || ' itens_exp_pcnfcanitem,'
               || ' itens_exp_pcnfsaid,'
               || ' itens_exp_pcpedc,'
               || ' itens_exp_pcpedccancecf,'
               || ' itens_exp_pcpedi,'
               || ' itens_exp_pcpedicancecf,'
               || ' itens_imp_pcmov,'
               || ' itens_imp_pcnfcan,'
               || ' itens_imp_pcnfcanitem,'
               || ' itens_imp_pcnfsaid,'
               || ' itens_imp_pcpedc,'
               || ' itens_imp_pcpedccancecf,'
               || ' itens_imp_pcpedi,'
               || ' itens_imp_pcpedicancecf,'
               || ' numcaixa,'
               || ' numped,'
               || ' numpedecf,'
               || ' numserieequip,'
               || ' numtransvendaecf,'
               || ' numtransvendawinthor,'
               || ' serieecf,'
               || ' status,'
               || ' tipo ) '
               || ' VALUES ( s.codfilial,'
               || ' s.codfunccx,'
               || ' s.data,'
               || ' s.dtexportacao,'
               || ' s.dtimportacao,'
               || ' s.itens_exp_pcmov,'
               || ' s.itens_exp_pcnfcan,'
               || ' s.itens_exp_pcnfcanitem,'
               || ' s.itens_exp_pcnfsaid,'
               || ' s.itens_exp_pcpedc,'
               || ' s.itens_exp_pcpedccancecf,'
               || ' s.itens_exp_pcpedi,'
               || ' s.itens_exp_pcpedicancecf,'
               || ' s.itens_imp_pcmov,'
               || ' s.itens_imp_pcnfcan,'
               || ' s.itens_imp_pcnfcanitem,'
               || ' s.itens_imp_pcnfsaid,'
               || ' s.itens_imp_pcpedc,'
               || ' s.itens_imp_pcpedccancecf,'
               || ' s.itens_imp_pcpedi,'
               || ' s.itens_imp_pcpedicancecf,'
               || ' s.numcaixa,'
               || ' s.numped,'
               || ' s.numpedecf,'
               || ' s.numserieequip,'
               || ' s.numtransvendaecf,'
               || ' s.numtransvendawinthor,'
               || ' s.serieecf,'
               || ' s.status,'
               || ' s.tipo )';

            EXECUTE IMMEDIATE v_sql;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               vbresultado := FALSE;
               vsmensagem :=
                     'Erro ao gravar log em '
                  || vstabela
                  || '. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;
      END IF;                                   --checar existencia de arquivo

      vbresultado := TRUE;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcservintercancel;

   FUNCTION importar_pcservintersangria (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vstabela := 'pcservintersangria';

      IF checar_arquivo_importacao (pscodfilial, vstabela)
      THEN
         vbresultado := FALSE;
         --> .exp principal -> intermediario
         vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem := vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         -- Importacao
         v_sql :=
               'CREATE TABLE imp_'
            || vstabela
            || ' ( codbanco NUMBER(4,0),'
            || ' codcob VARCHAR2(4),'
            || ' codfilial VARCHAR2(2),'
            || ' codfunc NUMBER(8,0),'
            || ' dtexportacao DATE,'
            || ' dtlanc DATE,'
            || ' itens_exp_pcmovcr NUMBER(8,0),'
            || ' itens_exp_pcvalecx NUMBER(8,0),'
            || ' numcaixa NUMBER(4,0),'
            || ' numserieequip VARCHAR2(30),'
            || ' numtransecf NUMBER(10,0),'
            || ' numvaleecf NUMBER(10,0),'
            || ' numvaleinter NUMBER(10,0),'
            || ' status VARCHAR2(1) ) '
            || ' ORGANIZATION EXTERNAL '
            || ' ( TYPE oracle_datapump '
            || ' DEFAULT DIRECTORY autoserv_dat_dir '
            || ' ACCESS PARAMETERS '
            || ' ( LOGFILE autoserv_log_dir: '''
            || vsnomearquivo
            || '%a_%p.log'' )'
            || ' LOCATION ('''
            || vsnomearquivo
            || '''))'
            || ' REJECT LIMIT UNLIMITED ';

         EXECUTE IMMEDIATE v_sql;

         BEGIN
            v_sql :=
                  ' MERGE INTO '
               || vstabela
               || ' d USING (SELECT * '
               || ' FROM imp_'
               || vstabela
               || ') s '
               || ' ON ( (d.codfilial = s.codfilial)'
               || '  AND (d.numvaleecf = s.numvaleecf)'
               || '  AND (d.dtlanc = s.dtlanc)'
               || '  AND (d.codfunc = s.codfunc)'
               || '  AND (d.numcaixa = s.numcaixa))'
               || ' WHEN MATCHED THEN '
               || ' UPDATE SET d.codbanco = s.codbanco ,'
               || ' d.codcob = s.codcob ,'
               || ' d.dtexportacao = s.dtexportacao ,'
               || ' d.itens_exp_pcmovcr = s.itens_exp_pcmovcr ,'
               || ' d.itens_exp_pcvalecx = s.itens_exp_pcvalecx ,'
               || ' d.numserieequip = s.numserieequip ,'
               || ' d.numtransecf = s.numtransecf ,'
               || ' d.numvaleinter = s.numvaleinter, '
               || ' d.status = decode(s.status, ''X'', ''R'', ''Y'', ''N'', s.status) '
               || ' WHEN NOT MATCHED THEN '
               || ' INSERT ( codbanco,'
               || ' codcob,'
               || ' codfilial,'
               || ' codfunc,'
               || ' dtexportacao,'
               || ' dtlanc,'
               || ' itens_exp_pcmovcr,'
               || ' itens_exp_pcvalecx,'
               || ' numcaixa,'
               || ' numserieequip,'
               || ' numtransecf,'
               || ' numvaleecf,'
               || ' numvaleinter,'
               || ' status ) '
               || ' VALUES ( s.codbanco,'
               || ' s.codcob,'
               || ' s.codfilial,'
               || ' s.codfunc,'
               || ' s.dtexportacao,'
               || ' s.dtlanc,'
               || ' s.itens_exp_pcmovcr,'
               || ' s.itens_exp_pcvalecx,'
               || ' s.numcaixa,'
               || ' s.numserieequip,'
               || ' s.numtransecf,'
               || ' s.numvaleecf,'
               || ' s.numvaleinter,'
               || ' s.status )';

            EXECUTE IMMEDIATE v_sql;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               vbresultado := FALSE;
               vsmensagem :=
                     'Erro ao gravar log em '
                  || vstabela
                  || '. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;
      END IF;

      vbresultado := TRUE;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcservintersangria;

   FUNCTION importar_pcservintervendas (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vstabela := 'pcservintervendas';

      IF checar_arquivo_importacao (pscodfilial, vstabela)
      THEN
         vbresultado := FALSE;
         --> .exp principal -> intermediario
         vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem := vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         -- Importacao
         v_sql :=
               'CREATE TABLE imp_'
            || vstabela
            || ' ( codfilial VARCHAR2(2),'
            || ' codfunccx NUMBER(8,0),'
            || ' data DATE,'
            || ' dtexportacao DATE,'
            || ' dtimportacao DATE,'
            || ' itens_exp_pcautori NUMBER(8,0),'
            || ' itens_exp_pcmov NUMBER(8,0),'
            || ' itens_exp_pcnfbase NUMBER(8,0),'
            || ' itens_exp_pcnfsaid NUMBER(8,0),'
            || ' itens_exp_pcpedc NUMBER(8,0),'
            || ' itens_exp_pcpedi NUMBER(8,0),'
            || ' itens_exp_pcprest NUMBER(8,0),'
            || ' itens_exp_pcvendaconsum NUMBER(8,0),'
            || ' itens_imp_pcautori NUMBER(8,0),'
            || ' itens_imp_pcmov NUMBER(8,0),'
            || ' itens_imp_pcnfbase NUMBER(8,0),'
            || ' itens_imp_pcnfsaid NUMBER(8,0),'
            || ' itens_imp_pcpedc NUMBER(8,0),'
            || ' itens_imp_pcpedi NUMBER(8,0),'
            || ' itens_imp_pcprest NUMBER(8,0),'
            || ' itens_imp_pcvendaconsum NUMBER(8,0),'
            || ' numcaixa NUMBER(4,0),'
            || ' numped NUMBER(10,0),'
            || ' numpedecf NUMBER(10,0),'
            || ' numserieequip VARCHAR2(30),'
            || ' numtransvendaecf NUMBER(10,0),'
            || ' numtransvendawinthor NUMBER(10,0),'
            || ' serieecf VARCHAR2(2),'
            || ' status VARCHAR2(1) ) '
            || ' ORGANIZATION EXTERNAL '
            || ' ( TYPE oracle_datapump '
            || ' DEFAULT DIRECTORY autoserv_dat_dir '
            || ' ACCESS PARAMETERS '
            || ' ( LOGFILE autoserv_log_dir: '''
            || vsnomearquivo
            || '%a_%p.log'' )'
            || ' LOCATION ('''
            || vsnomearquivo
            || '''))'
            || ' REJECT LIMIT UNLIMITED ';

         EXECUTE IMMEDIATE v_sql;

         BEGIN
            v_sql :=
                  ' MERGE INTO '
               || vstabela
               || ' d USING (SELECT * '
               || ' FROM imp_'
               || vstabela
               || ') s '
               || ' ON ((d.codfilial = s.codfilial) AND (d.numtransvendaecf = s.numtransvendaecf))'
               || ' WHEN MATCHED THEN '
               || ' UPDATE SET d.codfunccx = s.codfunccx ,'
               || ' d.data = s.data ,'
               || ' d.dtexportacao = s.dtexportacao ,'
               || ' d.dtimportacao = s.dtimportacao ,'
               || ' d.itens_exp_pcautori = s.itens_exp_pcautori ,'
               || ' d.itens_exp_pcmov = s.itens_exp_pcmov ,'
               || ' d.itens_exp_pcnfbase = s.itens_exp_pcnfbase ,'
               || ' d.itens_exp_pcnfsaid = s.itens_exp_pcnfsaid ,'
               || ' d.itens_exp_pcpedc = s.itens_exp_pcpedc ,'
               || ' d.itens_exp_pcpedi = s.itens_exp_pcpedi ,'
               || ' d.itens_exp_pcprest = s.itens_exp_pcprest ,'
               || ' d.itens_exp_pcvendaconsum = s.itens_exp_pcvendaconsum ,'
               || ' d.numcaixa = s.numcaixa ,'
               || ' d.numped = s.numped ,'
               || ' d.numpedecf = s.numpedecf ,'
               || ' d.numserieequip = s.numserieequip ,'
               || ' d.serieecf = s.serieecf, '
               || ' d.status = decode(s.status, ''X'', ''R'', ''Y'', ''N'', s.status) '
               || ' WHEN NOT MATCHED THEN '
               || ' INSERT (codfilial,'
               || ' codfunccx,'
               || ' data,'
               || ' dtexportacao,'
               || ' dtimportacao,'
               || ' itens_exp_pcautori,'
               || ' itens_exp_pcmov,'
               || ' itens_exp_pcnfbase,'
               || ' itens_exp_pcnfsaid,'
               || ' itens_exp_pcpedc,'
               || ' itens_exp_pcpedi,'
               || ' itens_exp_pcprest,'
               || ' itens_exp_pcvendaconsum,'
               || ' numcaixa,'
               || ' numped,'
               || ' numpedecf,'
               || ' numserieequip,'
               || ' numtransvendaecf,'
               || ' serieecf,'
               || ' status) '
               || ' VALUES ( s.codfilial,'
               || ' s.codfunccx,'
               || ' s.data,'
               || ' s.dtexportacao,'
               || ' s.dtimportacao,'
               || ' s.itens_exp_pcautori,'
               || ' s.itens_exp_pcmov,'
               || ' s.itens_exp_pcnfbase,'
               || ' s.itens_exp_pcnfsaid,'
               || ' s.itens_exp_pcpedc,'
               || ' s.itens_exp_pcpedi,'
               || ' s.itens_exp_pcprest,'
               || ' s.itens_exp_pcvendaconsum,'
               || ' s.numcaixa,'
               || ' s.numped,'
               || ' s.numpedecf,'
               || ' s.numserieequip,'
               || ' s.numtransvendaecf,'
               || ' s.serieecf,'
               || ' s.status )';

            EXECUTE IMMEDIATE v_sql;

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               vbresultado := FALSE;
               vsmensagem :=
                     'Erro ao gravar log em '
                  || vstabela
                  || '. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;
      END IF;

      vbresultado := TRUE;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcservintervendas;

   FUNCTION importar_pcsetor (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcsetor';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( codsetor  NUMBER(22,6),'
         || '   descricao VARCHAR2(30)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codsetor = s.codsetor) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.descricao = s.descricao '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codsetor, descricao ) '
            || ' VALUES (s.codsetor, s.descricao )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcsetor;

   FUNCTION importar_pccfo (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccfo';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (cfopinverso NUMBER(8,0),'
         || ' codfiscal NUMBER(8,0),'
         || ' codfiscalmaster NUMBER(8,0),'
         || ' codoper VARCHAR2(2),'
         || ' desccfo VARCHAR2(60),'
         || ' descsintegra VARCHAR2(200),'
         || ' obscfo VARCHAR2(100)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codfiscal = s.codfiscal) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.cfopinverso = s.cfopinverso ,'
            || '     d.codfiscalmaster = s.codfiscalmaster ,'
            || '     d.codoper = s.codoper ,'
            || '     d.desccfo = s.desccfo ,'
            || '     d.descsintegra = s.descsintegra ,'
            || '     d.obscfo = s.obscfo '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (cfopinverso, codfiscal, codfiscalmaster, codoper, desccfo, descsintegra, obscfo ) '
            || ' VALUES (s.cfopinverso, s.codfiscal, s.codfiscalmaster, s.codoper, s.desccfo, s.descsintegra, s.obscfo )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pccfo;

   FUNCTION importar_pcriscoacondicionamen (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcriscoacondicionamento';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( codtipo VARCHAR2(4),'
         || '   mensagem VARCHAR2(200)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codtipo = s.codtipo) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.mensagem = s.mensagem '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codtipo, mensagem ) '
            || ' VALUES (s.codtipo, s.mensagem )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcriscoacondicionamen;

   FUNCTION importar_pcrotina (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcrotina';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (acao VARCHAR2(40),'
         || ' ajuda VARCHAR2(1000),'
         || ' autmenu NUMBER(10,0),'
         || ' codfuncultutil NUMBER(8,0),'
         || ' codigo NUMBER(6,0),'
         || ' codmodulo NUMBER(4,0),'
         || ' codsubmodulo NUMBER(4,0),'
         || ' dataexe DATE,'
         || ' dtpriutilizacao DATE,'
         || ' dtultutilizacao DATE,'
         || ' dtultversao DATE,'
         || ' exibirmenu VARCHAR2(1),'
         || ' log VARCHAR2(1),'
         || ' nivel NUMBER(2,0),'
         || ' nomerotina VARCHAR2(40),'
         || ' numseq NUMBER(4,0),'
         || ' numultversao NUMBER(4,2),'
         || ' qtutilizacao NUMBER(10,0),'
         || ' status VARCHAR2(1)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codigo = s.codigo) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.acao = s.acao ,'
            || ' d.ajuda = s.ajuda ,'
            || ' d.autmenu = s.autmenu ,'
            || ' d.codfuncultutil = s.codfuncultutil ,'
            || ' d.codmodulo = s.codmodulo ,'
            || ' d.codsubmodulo = s.codsubmodulo ,'
            || ' d.dataexe = s.dataexe ,'
            || ' d.dtpriutilizacao = s.dtpriutilizacao ,'
            || ' d.dtultutilizacao = s.dtultutilizacao ,'
            || ' d.dtultversao = s.dtultversao ,'
            || ' d.exibirmenu = s.exibirmenu ,'
            || ' d.log = s.log ,'
            || ' d.nivel = s.nivel ,'
            || ' d.nomerotina = s.nomerotina ,'
            || ' d.numseq = s.numseq ,'
            || ' d.numultversao = s.numultversao ,'
            || ' d.qtutilizacao = s.qtutilizacao ,'
            || ' d.status = s.status '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (acao,'
            || ' ajuda,'
            || ' autmenu,'
            || ' codfuncultutil,'
            || ' codigo,'
            || ' codmodulo,'
            || ' codsubmodulo,'
            || ' dataexe,'
            || ' dtpriutilizacao,'
            || ' dtultutilizacao,'
            || ' dtultversao,'
            || ' exibirmenu,'
            || ' log,'
            || ' nivel,'
            || ' nomerotina,'
            || ' numseq,'
            || ' numultversao,'
            || ' qtutilizacao,'
            || ' status) '
            || ' VALUES (s.acao,'
            || ' s.ajuda,'
            || ' s.autmenu,'
            || ' s.codfuncultutil,'
            || ' s.codigo,'
            || ' s.codmodulo,'
            || ' s.codsubmodulo,'
            || ' s.dataexe,'
            || ' s.dtpriutilizacao,'
            || ' s.dtultutilizacao,'
            || ' s.dtultversao,'
            || ' s.exibirmenu,'
            || ' s.log,'
            || ' s.nivel,'
            || ' s.nomerotina,'
            || ' s.numseq,'
            || ' s.numultversao,'
            || ' s.qtutilizacao,'
            || ' s.status)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcrotina;

   FUNCTION importar_pcrotinai (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcrotinai';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codcontrole NUMBER(6,0),'
         || ' codrotina NUMBER(6,0),'
         || ' descricao VARCHAR2(60)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codcontrole = s.codcontrole) AND (d.codrotina = s.codrotina)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET  d.descricao = s.descricao '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codcontrole,'
            || ' codrotina,'
            || ' descricao) '
            || ' VALUES (s.codcontrole,'
            || ' s.codrotina,'
            || ' s.descricao)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcrotinai;

   FUNCTION importar_pcsecao (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcsecao';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( codepto NUMBER(22,6),'
         || ' codsec NUMBER(22,6),'
         || ' codsecnestle NUMBER(22,6),'
         || ' descricao VARCHAR2(40),'
         || ' qtmax NUMBER(22,10),'
         || ' tipo VARCHAR2(1)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codepto = s.codepto) AND (d.codsec = s.codsec)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.codsecnestle = s.codsecnestle ,'
            || '     d.descricao = s.descricao ,'
            || '     d.qtmax = s.qtmax ,'
            || '     d.tipo = s.tipo '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codepto, codsec, codsecnestle, descricao, qtmax, tipo ) '
            || ' VALUES (s.codepto, s.codsec, s.codsecnestle, s.descricao, s.qtmax, s.tipo )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcsecao;

   FUNCTION importar_pcdescquant (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcdescquant';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codprod number(6,0),'
         || '  iniciointervalo number(10,4),'
         || '  fimintervalo number(10,4),'
         || '  percdesc number(6,2),'
         || '  numregiao number(4,0),'
         || '  dtinicio date,'
         || '  dtfim date,'
         || '  codpraca number(4,0),'
         || '  percdescvrj number(6,2),'
         || '  percdescvp number(10,4),'
         || '  percdescfinvv number(10,4),'
         || '  percdescfinvp number(10,4),'
         || '  perdescmax number(10,2),'
         || '  tipodesconto varchar2(1),'
         || '  codplpagmax number(4,0),'
         || '  creditasobreptabela varchar2(1)'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codprod = s.codprod and'
            || '     d.iniciointervalo = s.iniciointerval and'
            || '     d.fimintervalo = s.fimintervalo)'
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.percdesc = s.percdesc,'
            || '     d.numregiao = s.numregiao,'
            || '     d.dtinicio = s.dtinicio,'
            || '     d.dtfim = s.dtfim,'
            || '     d.codpraca = s.codpraca,'
            || '     d.percdescvrj = s.percdescvrj,'
            || '     d.percdescvp = s.percdescvp,'
            || '     d.percdescfinvv = s.percdescfinvv,'
            || '     d.percdescfinvp = s.percdescfinvp,'
            || '     d.perdescmax = s.perdescmax,'
            || '     d.tipodesconto = s.tipodesconto,'
            || '     d.codplpagmax = s.codplpagmax,'
            || '     d.creditasobreptabela = s.creditasobreptabela,'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codprod, iniciointervalo, fimintervalo, percdesc, numregiao, dtinicio, dtfim, codpraca,'
            || '         percdescvrj, percdescvp, percdescfinvv, percdescfinvp, perdescmax, tipodesconto,'
            || '         codplpagmax, creditasobreptabela) '
            || ' VALUES (s.codprod, s.iniciointervalo, s.fimintervalo, s.percdesc, s.numregiao, s.dtinicio,'
            || '         s.dtfim, s.codpraca, s.percdescvrj, s.percdescvp, s.percdescfinvv, s.percdescfinvp,'
            || '         s.perdescmax, s.tipodesconto, s.codplpagmax, s.creditasobreptabela)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcdescquant;

   FUNCTION importar_pcdocc (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcdocc';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codfiscal varchar2(6),'
         || '  operacao varchar2(40),'
         || '  numlinhas number(4,0),'
         || '  letra varchar2(1),'
         || '  espacamento varchar2(1),'
         || '  serie varchar2(2),'
         || '  qtmaxitens number(2,0),'
         || '  tipopreco varchar2(1),'
         || '  impressora varchar2(15),'
         || '  tipodoc varchar2(3),'
         || '  coddoc number(8,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.tipodoc = s.tipodoc) and'
            || '     (d.codfiscal = s.codfiscal)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.operacao = s.operacao,'
            || '     d.numlinhas = s.numlinhas,'
            || '     d.letra = s.letra,'
            || '     d.espacamento = s.espacamento,'
            || '     d.serie = s.serie,'
            || '     d.qtmaxitens = s.qtmaxitens,'
            || '     d.tipopreco = s.tipopreco,'
            || '     d.impressora = s.impressora,'
            || '     d.coddoc = s.coddoc'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codfiscal, operacao, numlinhas, letra, espacamento, serie, qtmaxitens, tipopreco,'
            || '         impressora, tipodoc, coddoc)'
            || ' VALUES (s.codfiscal, s.operacao, s.numlinhas, s.letra, s.espacamento, s.serie, s.qtmaxitens,'
            || '         s.tipopreco, s.impressora, s.tipodoc, s.coddoc)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcdocc;

   FUNCTION importar_pcdoci (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcdoci';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codfiscal varchar2(6),'
         || '  secao varchar2(1),'
         || '  linha number(4,0),'
         || '  coluna number(4,0),'
         || '  tipocampo varchar2(1),'
         || '  tamanho number(4,0),'
         || '  decimais number(2,0),'
         || '  texto varchar2(75),'
         || '  tipodoc varchar2(3),'
         || '  coddoc number(8,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.tipodoc = s.tipodoc) and'
            || '     (d.codfiscal = s.codfiscal) and'
            || '     (d.secao = s.secao) and'
            || '     (d.linha = s.linha) and'
            || '     (d.coluna = s.coluna)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.tipocampo = s.tipocampo,'
            || '     d.tamanho = s.tamanho,'
            || '     d.decimais = s.decimais,'
            || '     d.texto = s.texto,'
            || '     d.coddoc = s.coddoc'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codfiscal, secao, linha, coluna, tipocampo, tamanho, decimais, texto, tipodoc, coddoc) '
            || ' VALUES (s.codfiscal, s.secao, s.linha, s.coluna, s.tipocampo, s.tamanho, s.decimais, s.texto,'
            || '         s.tipodoc, s.coddoc)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcdoci;

   FUNCTION importar_pcfornec (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcfornec';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( aceitaentregaancecip VARCHAR2(1),'
         || ' adm_bairro VARCHAR2(40),'
         || ' adm_cep NUMBER(8,0),'
         || ' adm_cidade VARCHAR2(40),'
         || ' adm_contato VARCHAR2(40),'
         || ' adm_dtaniversario DATE,'
         || ' adm_endereco VARCHAR2(40),'
         || ' adm_uf VARCHAR2(2),'
         || ' bairro VARCHAR2(20),'
         || ' bairrocob VARCHAR2(40),'
         || ' bloqueio VARCHAR2(1),'
         || ' calcipicomdesc VARCHAR2(1),'
         || ' calcipicomfretenf VARCHAR2(1),'
         || ' calcsuframasobrepliquido VARCHAR2(1),'
         || ' calculapiscofinscomipi VARCHAR2(1),'
         || ' centralizacao VARCHAR2(1),'
         || ' cep VARCHAR2(9),'
         || ' cepcob VARCHAR2(9),'
         || ' cgc VARCHAR2(18),'
         || ' cidade VARCHAR2(15),'
         || ' classecompra VARCHAR2(1),'
         || ' classeestoque VARCHAR2(1),'
         || ' classemc VARCHAR2(1),'
         || ' classevenda VARCHAR2(1),'
         || ' cobertura NUMBER(4,0),'
         || ' codcidade NUMBER(6,0),'
         || ' codcli NUMBER(6,0),'
         || ' codcomprador NUMBER(8,0),'
         || ' codcontab NUMBER(10,0),'
         || ' codcontalancfrete NUMBER(6,0),'
         || ' coddepto NUMBER(6,0),'
         || ' coddistrib VARCHAR2(4),'
         || ' codfornec NUMBER(6,0),'
         || ' codfornecprinc NUMBER(6,0),'
         || ' codfuncultcontatocob NUMBER(8,0),'
         || ' codmunicipio NUMBER(10,0),'
         || ' codprodutorrural VARCHAR2(20),'
         || ' com_bairro VARCHAR2(40),'
         || ' com_celular VARCHAR2(20),'
         || ' com_cep NUMBER(8,0),'
         || ' com_cidade VARCHAR2(40),'
         || ' com_contato VARCHAR2(40),'
         || ' com_dtaniversario DATE,'
         || ' com_email VARCHAR2(100),'
         || ' com_endereco VARCHAR2(40),'
         || ' com_uf VARCHAR2(2),'
         || ' consipicalcbasecrepres VARCHAR2(1),'
         || ' consipicalcbasest VARCHAR2(1),'
         || ' contato VARCHAR2(40),'
         || ' contatoadm VARCHAR2(40),'
         || ' contatocom VARCHAR2(40),'
         || ' contatoverba VARCHAR2(40),'
         || ' cpfcontatoverba VARCHAR2(18),'
         || ' deduzirsuframabcstaliq1 VARCHAR2(1),'
         || ' deduzirsuframacalccredicm VARCHAR2(1),'
         || ' deduzirsuframacalccredpis VARCHAR2(1),'
         || ' descpagtodup VARCHAR2(1),'
         || ' destacaselonf VARCHAR2(1),'
         || ' diasemanaatend NUMBER(2,0),'
         || ' distrib VARCHAR2(1),'
         || ' dtbloqueio DATE,'
         || ' dtcadastro DATE,'
         || ' dtexclusao DATE,'
         || ' dtproxatend DATE,'
         || ' dtproxcontatocob DATE,'
         || ' dtultcontatocob DATE,'
         || ' dtvalidade DATE,'
         || ' dvag VARCHAR2(2),'
         || ' dvcc VARCHAR2(2),'
         || ' email VARCHAR2(100),'
         || ' ender VARCHAR2(40),'
         || ' endercob VARCHAR2(40),'
         || ' estado VARCHAR2(2),'
         || ' estcob VARCHAR2(2),'
         || ' estrategico VARCHAR2(1),'
         || ' excluido VARCHAR2(1),'
         || ' fantasia VARCHAR2(40),'
         || ' faxfab VARCHAR2(15),'
         || ' faxrep VARCHAR2(15),'
         || ' fornecedor VARCHAR2(40),'
         || ' gatilho NUMBER(12,4),'
         || ' grupocampanha NUMBER(6,0),'
         || ' icmssobretxminima VARCHAR2(1),'
         || ' ie VARCHAR2(15),'
         || ' industrialocal VARCHAR2(1),'
         || ' inscestrangeira NUMBER(15,0),'
         || ' ledtime NUMBER(4,0),'
         || ' localizacao VARCHAR2(20),'
         || ' municob VARCHAR2(40),'
         || ' numagenciadoc NUMBER(6,0),'
         || ' numbancodoc NUMBER(4,0),'
         || ' numccorrentedoc VARCHAR2(15),'
         || ' numdepirrf NUMBER(4,0),'
         || ' obs VARCHAR2(20),'
         || ' observacao VARCHAR2(2000),'
         || ' obs2 VARCHAR2(35),'
         || ' percbondin NUMBER(12,2),'
         || ' percbonmerc NUMBER(12,2),'
         || ' percbonoutras NUMBER(12,2),'
         || ' perccomissao NUMBER(12,2),'
         || ' percdescfin NUMBER(12,4),'
         || ' percdespfin NUMBER(12,4),'
         || ' percfluvial NUMBER(6,4),'
         || ' percmaxbonific NUMBER(5,2),'
         || ' percoutroscustosfrete NUMBER(5,2),'
         || ' percpisred NUMBER(5,2),'
         || ' pergris NUMBER(8,4),'
         || ' periocidadeatend NUMBER(4,0),'
         || ' prazoentrega NUMBER(4,0),'
         || ' prazomin NUMBER(4,0),'
         || ' prazo1 NUMBER(4,0),'
         || ' prazo2 NUMBER(4,0),'
         || ' prazo3 NUMBER(4,0),'
         || ' prazo4 NUMBER(4,0),'
         || ' prazo5 NUMBER(4,0),'
         || ' prazo6 NUMBER(4,0),'
         || ' regional VARCHAR2(1),'
         || ' rep_bairro VARCHAR2(13),'
         || ' rep_cep NUMBER(8,0),'
         || ' rep_cidade VARCHAR2(15),'
         || ' rep_contato VARCHAR2(10),'
         || ' rep_dtaniversario DATE,'
         || ' rep_email VARCHAR2(100),'
         || ' rep_endereco VARCHAR2(23),'
         || ' repres VARCHAR2(40),'
         || ' rep_uf VARCHAR2(2),'
         || ' revenda VARCHAR2(1),'
         || ' rg VARCHAR2(20),'
         || ' rgcontatoverba VARCHAR2(20),'
         || ' somafretefobnostforanf VARCHAR2(1),'
         || ' suframa VARCHAR2(1),'
         || ' sup_celular VARCHAR2(20),'
         || ' sup_email VARCHAR2(100),'
         || ' supervisorverba VARCHAR2(40),'
         || ' taxa0 NUMBER(8,4),'
         || ' taxa14 NUMBER(8,4),'
         || ' taxa21 NUMBER(8,4),'
         || ' taxa28 NUMBER(8,4),'
         || ' taxa35 NUMBER(8,4),'
         || ' taxa42 NUMBER(8,4),'
         || ' taxa7 NUMBER(8,4),'
         || ' telcob VARCHAR2(13),'
         || ' telefoneadm VARCHAR2(18),'
         || ' telefonecom VARCHAR2(18),'
         || ' telexfab VARCHAR2(20),'
         || ' telexrep VARCHAR2(20),'
         || ' telfab VARCHAR2(13),'
         || ' telrep VARCHAR2(13),'
         || ' tipocalcfrete NUMBER(2,0),'
         || ' tipoembalagempedido VARCHAR2(1),'
         || ' tipofornec VARCHAR2(1),'
         || ' tipofreteciffob VARCHAR2(1),'
         || ' transporteproprio VARCHAR2(1),'
         || ' utilizadesccalcicms VARCHAR2(1),'
         || ' utilizadesccalcipi VARCHAR2(1),'
         || ' utilizadesccalcst VARCHAR2(1),'
         || ' utilizafretecalcicms VARCHAR2(1),'
         || ' utilizafretecalcipi VARCHAR2(1),'
         || ' utilizaoutrasdespcalcicms VARCHAR2(1),'
         || ' utilizaoutrasdespcalcipi VARCHAR2(1),'
         || ' utilizapercbon VARCHAR2(1),'
         || ' valordeducaoirrf NUMBER(14,2),'
         || ' vlfretekg NUMBER(12,4),'
         || ' vllimitefretemin NUMBER(18,6),'
         || ' vlminpedcompra NUMBER(10,2),'
         || ' vlpedagio NUMBER(12,2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codfornec = s.codfornec) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.aceitaentregaancecip = s.aceitaentregaancecip ,'
            || ' d.adm_bairro = s.adm_bairro ,'
            || ' d.adm_cep = s.adm_cep ,'
            || ' d.adm_cidade = s.adm_cidade ,'
            || ' d.adm_contato = s.adm_contato ,'
            || ' d.adm_dtaniversario = s.adm_dtaniversario ,'
            || ' d.adm_endereco = s.adm_endereco ,'
            || ' d.adm_uf = s.adm_uf ,'
            || ' d.bairro = s.bairro ,'
            || ' d.bairrocob = s.bairrocob ,'
            || ' d.bloqueio = s.bloqueio ,'
            || ' d.calcipicomdesc = s.calcipicomdesc ,'
            || ' d.calcipicomfretenf = s.calcipicomfretenf ,'
            || ' d.calcsuframasobrepliquido = s.calcsuframasobrepliquido ,'
            || ' d.calculapiscofinscomipi = s.calculapiscofinscomipi ,'
            || ' d.centralizacao = s.centralizacao ,'
            || ' d.cep = s.cep ,'
            || ' d.cepcob = s.cepcob ,'
            || ' d.cgc = s.cgc ,'
            || ' d.cidade = s.cidade ,'
            || ' d.classecompra = s.classecompra ,'
            || ' d.classeestoque = s.classeestoque ,'
            || ' d.classemc = s.classemc ,'
            || ' d.classevenda = s.classevenda ,'
            || ' d.cobertura = s.cobertura ,'
            || ' d.codcidade = s.codcidade ,'
            || ' d.codcli = s.codcli ,'
            || ' d.codcomprador = s.codcomprador ,'
            || ' d.codcontab = s.codcontab ,'
            || ' d.codcontalancfrete = s.codcontalancfrete ,'
            || ' d.coddepto = s.coddepto ,'
            || ' d.coddistrib = s.coddistrib ,'
            || ' d.codfornecprinc = s.codfornecprinc ,'
            || ' d.codfuncultcontatocob = s.codfuncultcontatocob ,'
            || ' d.codmunicipio = s.codmunicipio ,'
            || ' d.codprodutorrural = s.codprodutorrural ,'
            || ' d.com_bairro = s.com_bairro ,'
            || ' d.com_celular = s.com_celular ,'
            || ' d.com_cep = s.com_cep ,'
            || ' d.com_cidade = s.com_cidade ,'
            || ' d.com_contato = s.com_contato ,'
            || ' d.com_dtaniversario = s.com_dtaniversario ,'
            || ' d.com_email = s.com_email ,'
            || ' d.com_endereco = s.com_endereco ,'
            || ' d.com_uf = s.com_uf ,'
            || ' d.consipicalcbasecrepres = s.consipicalcbasecrepres ,'
            || ' d.consipicalcbasest = s.consipicalcbasest ,'
            || ' d.contato = s.contato ,'
            || ' d.contatoadm = s.contatoadm ,'
            || ' d.contatocom = s.contatocom ,'
            || ' d.contatoverba = s.contatoverba ,'
            || ' d.cpfcontatoverba = s.cpfcontatoverba ,'
            || ' d.deduzirsuframabcstaliq1 = s.deduzirsuframabcstaliq1 ,'
            || ' d.deduzirsuframacalccredicm = s.deduzirsuframacalccredicm ,'
            || ' d.deduzirsuframacalccredpis = s.deduzirsuframacalccredpis ,'
            || ' d.descpagtodup = s.descpagtodup ,'
            || ' d.destacaselonf = s.destacaselonf ,'
            || ' d.diasemanaatend = s.diasemanaatend ,'
            || ' d.distrib = s.distrib ,'
            || ' d.dtbloqueio = s.dtbloqueio ,'
            || ' d.dtcadastro = s.dtcadastro ,'
            || ' d.dtexclusao = s.dtexclusao ,'
            || ' d.dtproxatend = s.dtproxatend ,'
            || ' d.dtproxcontatocob = s.dtproxcontatocob ,'
            || ' d.dtultcontatocob = s.dtultcontatocob ,'
            || ' d.dtvalidade = s.dtvalidade ,'
            || ' d.dvag = s.dvag ,'
            || ' d.dvcc = s.dvcc ,'
            || ' d.email = s.email ,'
            || ' d.ender = s.ender ,'
            || ' d.endercob = s.endercob ,'
            || ' d.estado = s.estado ,'
            || ' d.estcob = s.estcob ,'
            || ' d.estrategico = s.estrategico ,'
            || ' d.excluido = s.excluido ,'
            || ' d.fantasia = s.fantasia ,'
            || ' d.faxfab = s.faxfab ,'
            || ' d.faxrep = s.faxrep ,'
            || ' d.fornecedor = s.fornecedor ,'
            || ' d.gatilho = s.gatilho ,'
            || ' d.grupocampanha = s.grupocampanha ,'
            || ' d.icmssobretxminima = s.icmssobretxminima ,'
            || ' d.ie = s.ie ,'
            || ' d.industrialocal = s.industrialocal ,'
            || ' d.inscestrangeira = s.inscestrangeira ,'
            || ' d.ledtime = s.ledtime ,'
            || ' d.localizacao = s.localizacao ,'
            || ' d.municob = s.municob ,'
            || ' d.numagenciadoc = s.numagenciadoc ,'
            || ' d.numbancodoc = s.numbancodoc ,'
            || ' d.numccorrentedoc = s.numccorrentedoc ,'
            || ' d.numdepirrf = s.numdepirrf ,'
            || ' d.obs = s.obs ,'
            || ' d.observacao = s.observacao ,'
            || ' d.obs2 = s.obs2 ,'
            || ' d.percbondin = s.percbondin ,'
            || ' d.percbonmerc = s.percbonmerc ,'
            || ' d.percbonoutras = s.percbonoutras ,'
            || ' d.perccomissao = s.perccomissao ,'
            || ' d.percdescfin = s.percdescfin ,'
            || ' d.percdespfin = s.percdespfin ,'
            || ' d.percfluvial = s.percfluvial ,'
            || ' d.percmaxbonific = s.percmaxbonific ,'
            || ' d.percoutroscustosfrete = s.percoutroscustosfrete ,'
            || ' d.percpisred = s.percpisred ,'
            || ' d.pergris = s.pergris ,'
            || ' d.periocidadeatend = s.periocidadeatend ,'
            || ' d.prazoentrega = s.prazoentrega ,'
            || ' d.prazomin = s.prazomin ,'
            || ' d.prazo1 = s.prazo1 ,'
            || ' d.prazo2 = s.prazo2 ,'
            || ' d.prazo3 = s.prazo3 ,'
            || ' d.prazo4 = s.prazo4 ,'
            || ' d.prazo5 = s.prazo5 ,'
            || ' d.prazo6 = s.prazo6 ,'
            || ' d.regional = s.regional ,'
            || ' d.rep_bairro = s.rep_bairro ,'
            || ' d.rep_cep = s.rep_cep ,'
            || ' d.rep_cidade = s.rep_cidade ,'
            || ' d.rep_contato = s.rep_contato ,'
            || ' d.rep_dtaniversario = s.rep_dtaniversario ,'
            || ' d.rep_email = s.rep_email ,'
            || ' d.rep_endereco = s.rep_endereco ,'
            || ' d.repres = s.repres ,'
            || ' d.rep_uf = s.rep_uf ,'
            || ' d.revenda = s.revenda ,'
            || ' d.rg = s.rg ,'
            || ' d.rgcontatoverba = s.rgcontatoverba ,'
            || ' d.somafretefobnostforanf = s.somafretefobnostforanf ,'
            || ' d.suframa = s.suframa ,'
            || ' d.sup_celular = s.sup_celular ,'
            || ' d.sup_email = s.sup_email ,'
            || ' d.supervisorverba = s.supervisorverba ,'
            || ' d.taxa0 = s.taxa0 ,'
            || ' d.taxa14 = s.taxa14 ,'
            || ' d.taxa21 = s.taxa21 ,'
            || ' d.taxa28 = s.taxa28 ,'
            || ' d.taxa35 = s.taxa35 ,'
            || ' d.taxa42 = s.taxa42 ,'
            || ' d.taxa7 = s.taxa7 ,'
            || ' d.telcob = s.telcob ,'
            || ' d.telefoneadm = s.telefoneadm ,'
            || ' d.telefonecom = s.telefonecom ,'
            || ' d.telexfab = s.telexfab ,'
            || ' d.telexrep = s.telexrep ,'
            || ' d.telfab = s.telfab ,'
            || ' d.telrep = s.telrep ,'
            || ' d.tipocalcfrete = s.tipocalcfrete ,'
            || ' d.tipoembalagempedido = s.tipoembalagempedido ,'
            || ' d.tipofornec = s.tipofornec ,'
            || ' d.tipofreteciffob = s.tipofreteciffob ,'
            || ' d.transporteproprio = s.transporteproprio ,'
            || ' d.utilizadesccalcicms = s.utilizadesccalcicms ,'
            || ' d.utilizadesccalcipi = s.utilizadesccalcipi ,'
            || ' d.utilizadesccalcst = s.utilizadesccalcst ,'
            || ' d.utilizafretecalcicms = s.utilizafretecalcicms ,'
            || ' d.utilizafretecalcipi = s.utilizafretecalcipi ,'
            || ' d.utilizaoutrasdespcalcicms = s.utilizaoutrasdespcalcicms ,'
            || ' d.utilizaoutrasdespcalcipi = s.utilizaoutrasdespcalcipi ,'
            || ' d.utilizapercbon = s.utilizapercbon ,'
            || ' d.valordeducaoirrf = s.valordeducaoirrf ,'
            || ' d.vlfretekg = s.vlfretekg ,'
            || ' d.vllimitefretemin = s.vllimitefretemin ,'
            || ' d.vlminpedcompra = s.vlminpedcompra ,'
            || ' d.vlpedagio = s.vlpedagio '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (aceitaentregaancecip,'
            || ' adm_bairro,'
            || ' adm_cep,'
            || ' adm_cidade,'
            || ' adm_contato,'
            || ' adm_dtaniversario,'
            || ' adm_endereco,'
            || ' adm_uf,'
            || ' bairro,'
            || ' bairrocob,'
            || ' bloqueio,'
            || ' calcipicomdesc,'
            || ' calcipicomfretenf,'
            || ' calcsuframasobrepliquido,'
            || ' calculapiscofinscomipi,'
            || ' centralizacao,'
            || ' cep,'
            || ' cepcob,'
            || ' cgc,'
            || ' cidade,'
            || ' classecompra,'
            || ' classeestoque,'
            || ' classemc,'
            || ' classevenda,'
            || ' cobertura,'
            || ' codcidade,'
            || ' codcli,'
            || ' codcomprador,'
            || ' codcontab,'
            || ' codcontalancfrete,'
            || ' coddepto,'
            || ' coddistrib,'
            || ' codfornec,'
            || ' codfornecprinc,'
            || ' codfuncultcontatocob,'
            || ' codmunicipio,'
            || ' codprodutorrural,'
            || ' com_bairro,'
            || ' com_celular,'
            || ' com_cep,'
            || ' com_cidade,'
            || ' com_contato,'
            || ' com_dtaniversario,'
            || ' com_email,'
            || ' com_endereco,'
            || ' com_uf,'
            || ' consipicalcbasecrepres,'
            || ' consipicalcbasest,'
            || ' contato,'
            || ' contatoadm,'
            || ' contatocom,'
            || ' contatoverba,'
            || ' cpfcontatoverba,'
            || ' deduzirsuframabcstaliq1,'
            || ' deduzirsuframacalccredicm,'
            || ' deduzirsuframacalccredpis,'
            || ' descpagtodup,'
            || ' destacaselonf,'
            || ' diasemanaatend,'
            || ' distrib,'
            || ' dtbloqueio,'
            || ' dtcadastro,'
            || ' dtexclusao,'
            || ' dtproxatend,'
            || ' dtproxcontatocob,'
            || ' dtultcontatocob,'
            || ' dtvalidade,'
            || ' dvag,'
            || ' dvcc,'
            || ' email,'
            || ' ender,'
            || ' endercob,'
            || ' estado,'
            || ' estcob,'
            || ' estrategico,'
            || ' excluido,'
            || ' fantasia,'
            || ' faxfab,'
            || ' faxrep,'
            || ' fornecedor,'
            || ' gatilho,'
            || ' grupocampanha,'
            || ' icmssobretxminima,'
            || ' ie,'
            || ' industrialocal,'
            || ' inscestrangeira,'
            || ' ledtime,'
            || ' localizacao,'
            || ' municob,'
            || ' numagenciadoc,'
            || ' numbancodoc,'
            || ' numccorrentedoc,'
            || ' numdepirrf,'
            || ' obs,'
            || ' observacao,'
            || ' obs2,'
            || ' percbondin,'
            || ' percbonmerc,'
            || ' percbonoutras,'
            || ' perccomissao,'
            || ' percdescfin,'
            || ' percdespfin,'
            || ' percfluvial,'
            || ' percmaxbonific,'
            || ' percoutroscustosfrete,'
            || ' percpisred,'
            || ' pergris,'
            || ' periocidadeatend,'
            || ' prazoentrega,'
            || ' prazomin,'
            || ' prazo1,'
            || ' prazo2,'
            || ' prazo3,'
            || ' prazo4,'
            || ' prazo5,'
            || ' prazo6,'
            || ' regional,'
            || ' rep_bairro,'
            || ' rep_cep,'
            || ' rep_cidade,'
            || ' rep_contato,'
            || ' rep_dtaniversario,'
            || ' rep_email,'
            || ' rep_endereco,'
            || ' repres,'
            || ' rep_uf,'
            || ' revenda,'
            || ' rg,'
            || ' rgcontatoverba,'
            || ' somafretefobnostforanf,'
            || ' suframa,'
            || ' sup_celular,'
            || ' sup_email,'
            || ' supervisorverba,'
            || ' taxa0,'
            || ' taxa14,'
            || ' taxa21,'
            || ' taxa28,'
            || ' taxa35,'
            || ' taxa42,'
            || ' taxa7,'
            || ' telcob,'
            || ' telefoneadm,'
            || ' telefonecom,'
            || ' telexfab,'
            || ' telexrep,'
            || ' telfab,'
            || ' telrep,'
            || ' tipocalcfrete,'
            || ' tipoembalagempedido,'
            || ' tipofornec,'
            || ' tipofreteciffob,'
            || ' transporteproprio,'
            || ' utilizadesccalcicms,'
            || ' utilizadesccalcipi,'
            || ' utilizadesccalcst,'
            || ' utilizafretecalcicms,'
            || ' utilizafretecalcipi,'
            || ' utilizaoutrasdespcalcicms,'
            || ' utilizaoutrasdespcalcipi,'
            || ' utilizapercbon,'
            || ' valordeducaoirrf,'
            || ' vlfretekg,'
            || ' vllimitefretemin,'
            || ' vlminpedcompra,'
            || ' vlpedagio ) '
            || ' VALUES ( s.aceitaentregaancecip,'
            || ' s.adm_bairro,'
            || ' s.adm_cep,'
            || ' s.adm_cidade,'
            || ' s.adm_contato,'
            || ' s.adm_dtaniversario,'
            || ' s.adm_endereco,'
            || ' s.adm_uf,'
            || ' s.bairro,'
            || ' s.bairrocob,'
            || ' s.bloqueio,'
            || ' s.calcipicomdesc,'
            || ' s.calcipicomfretenf,'
            || ' s.calcsuframasobrepliquido,'
            || ' s.calculapiscofinscomipi,'
            || ' s.centralizacao,'
            || ' s.cep,'
            || ' s.cepcob,'
            || ' s.cgc,'
            || ' s.cidade,'
            || ' s.classecompra,'
            || ' s.classeestoque,'
            || ' s.classemc,'
            || ' s.classevenda,'
            || ' s.cobertura,'
            || ' s.codcidade,'
            || ' s.codcli,'
            || ' s.codcomprador,'
            || ' s.codcontab,'
            || ' s.codcontalancfrete,'
            || ' s.coddepto,'
            || ' s.coddistrib,'
            || ' s.codfornec,'
            || ' s.codfornecprinc,'
            || ' s.codfuncultcontatocob,'
            || ' s.codmunicipio,'
            || ' s.codprodutorrural,'
            || ' s.com_bairro,'
            || ' s.com_celular,'
            || ' s.com_cep,'
            || ' s.com_cidade,'
            || ' s.com_contato,'
            || ' s.com_dtaniversario,'
            || ' s.com_email,'
            || ' s.com_endereco,'
            || ' s.com_uf,'
            || ' s.consipicalcbasecrepres,'
            || ' s.consipicalcbasest,'
            || ' s.contato,'
            || ' s.contatoadm,'
            || ' s.contatocom,'
            || ' s.contatoverba,'
            || ' s.cpfcontatoverba,'
            || ' s.deduzirsuframabcstaliq1,'
            || ' s.deduzirsuframacalccredicm,'
            || ' s.deduzirsuframacalccredpis,'
            || ' s.descpagtodup,'
            || ' s.destacaselonf,'
            || ' s.diasemanaatend,'
            || ' s.distrib,'
            || ' s.dtbloqueio,'
            || ' s.dtcadastro,'
            || ' s.dtexclusao,'
            || ' s.dtproxatend,'
            || ' s.dtproxcontatocob,'
            || ' s.dtultcontatocob,'
            || ' s.dtvalidade,'
            || ' s.dvag,'
            || ' s.dvcc,'
            || ' s.email,'
            || ' s.ender,'
            || ' s.endercob,'
            || ' s.estado,'
            || ' s.estcob,'
            || ' s.estrategico,'
            || ' s.excluido,'
            || ' s.fantasia,'
            || ' s.faxfab,'
            || ' s.faxrep,'
            || ' s.fornecedor,'
            || ' s.gatilho,'
            || ' s.grupocampanha,'
            || ' s.icmssobretxminima,'
            || ' s.ie,'
            || ' s.industrialocal,'
            || ' s.inscestrangeira,'
            || ' s.ledtime,'
            || ' s.localizacao,'
            || ' s.municob,'
            || ' s.numagenciadoc,'
            || ' s.numbancodoc,'
            || ' s.numccorrentedoc,'
            || ' s.numdepirrf,'
            || ' s.obs,'
            || ' s.observacao,'
            || ' s.obs2,'
            || ' s.percbondin,'
            || ' s.percbonmerc,'
            || ' s.percbonoutras,'
            || ' s.perccomissao,'
            || ' s.percdescfin,'
            || ' s.percdespfin,'
            || ' s.percfluvial,'
            || ' s.percmaxbonific,'
            || ' s.percoutroscustosfrete,'
            || ' s.percpisred,'
            || ' s.pergris,'
            || ' s.periocidadeatend,'
            || ' s.prazoentrega,'
            || ' s.prazomin,'
            || ' s.prazo1,'
            || ' s.prazo2,'
            || ' s.prazo3,'
            || ' s.prazo4,'
            || ' s.prazo5,'
            || ' s.prazo6,'
            || ' s.regional,'
            || ' s.rep_bairro,'
            || ' s.rep_cep,'
            || ' s.rep_cidade,'
            || ' s.rep_contato,'
            || ' s.rep_dtaniversario,'
            || ' s.rep_email,'
            || ' s.rep_endereco,'
            || ' s.repres,'
            || ' s.rep_uf,'
            || ' s.revenda,'
            || ' s.rg,'
            || ' s.rgcontatoverba,'
            || ' s.somafretefobnostforanf,'
            || ' s.suframa,'
            || ' s.sup_celular,'
            || ' s.sup_email,'
            || ' s.supervisorverba,'
            || ' s.taxa0,'
            || ' s.taxa14,'
            || ' s.taxa21,'
            || ' s.taxa28,'
            || ' s.taxa35,'
            || ' s.taxa42,'
            || ' s.taxa7,'
            || ' s.telcob,'
            || ' s.telefoneadm,'
            || ' s.telefonecom,'
            || ' s.telexfab,'
            || ' s.telexrep,'
            || ' s.telfab,'
            || ' s.telrep,'
            || ' s.tipocalcfrete,'
            || ' s.tipoembalagempedido,'
            || ' s.tipofornec,'
            || ' s.tipofreteciffob,'
            || ' s.transporteproprio,'
            || ' s.utilizadesccalcicms,'
            || ' s.utilizadesccalcipi,'
            || ' s.utilizadesccalcst,'
            || ' s.utilizafretecalcicms,'
            || ' s.utilizafretecalcipi,'
            || ' s.utilizaoutrasdespcalcicms,'
            || ' s.utilizaoutrasdespcalcipi,'
            || ' s.utilizapercbon,'
            || ' s.valordeducaoirrf,'
            || ' s.vlfretekg,'
            || ' s.vllimitefretemin,'
            || ' s.vlminpedcompra,'
            || ' s.vlpedagio )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcfornec;

   FUNCTION importar_pcveicul (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcveicul';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( altura NUMBER(10,3),'
         || ' chassi VARCHAR2(25),'
         || ' codfilial VARCHAR2(2),'
         || ' codfuncaltsit NUMBER(8,0),'
         || ' codlocalizacao NUMBER(8,0),'
         || ' codveiculo NUMBER(4,0),'
         || ' comprimento NUMBER(10,3),'
         || ' cor VARCHAR2(20),'
         || ' descricao VARCHAR2(40),'
         || ' kmatual NUMBER(12,2),'
         || ' kminicial NUMBER(12,2),'
         || ' largura NUMBER(10,3),'
         || ' marca VARCHAR2(20),'
         || ' mediakm NUMBER(12,2),'
         || ' obs VARCHAR2(50),'
         || ' obs2 VARCHAR2(120),'
         || ' pesocargakg NUMBER(10,2),'
         || ' pesocargakg2 NUMBER(10,2),'
         || ' placa VARCHAR2(10),'
         || ' proprio VARCHAR2(1),'
         || ' qteixos NUMBER(2,0),'
         || ' qtlitros NUMBER(6,2),'
         || ' qtpalete NUMBER(4,0),'
         || ' qtrodas NUMBER(2,0),'
         || ' qttanques NUMBER(2,0),'
         || ' rastreado VARCHAR2(1),'
         || ' situacao VARCHAR2(1),'
         || ' tipoveiculo VARCHAR2(1),'
         || ' ultviagem NUMBER(6,0),'
         || ' valorkmrodado NUMBER(10,4),'
         || ' vldiaria NUMBER(10,2),'
         || ' volume NUMBER(10,4)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codveiculo = s.codveiculo) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.altura = s.altura ,'
            || ' d.chassi = s.chassi ,'
            || ' d.codfilial = s.codfilial ,'
            || ' d.codfuncaltsit = s.codfuncaltsit ,'
            || ' d.codlocalizacao = s.codlocalizacao ,'
            || ' d.comprimento = s.comprimento ,'
            || ' d.cor = s.cor ,'
            || ' d.descricao = s.descricao ,'
            || ' d.kmatual = s.kmatual ,'
            || ' d.kminicial = s.kminicial ,'
            || ' d.largura = s.largura ,'
            || ' d.marca = s.marca ,'
            || ' d.mediakm = s.mediakm ,'
            || ' d.obs = s.obs ,'
            || ' d.obs2 = s.obs2 ,'
            || ' d.pesocargakg = s.pesocargakg ,'
            || ' d.pesocargakg2 = s.pesocargakg2 ,'
            || ' d.placa = s.placa ,'
            || ' d.proprio = s.proprio ,'
            || ' d.qteixos = s.qteixos ,'
            || ' d.qtlitros = s.qtlitros ,'
            || ' d.qtpalete = s.qtpalete ,'
            || ' d.qtrodas = s.qtrodas ,'
            || ' d.qttanques = s.qttanques ,'
            || ' d.rastreado = s.rastreado ,'
            || ' d.situacao = s.situacao ,'
            || ' d.tipoveiculo = s.tipoveiculo ,'
            || ' d.ultviagem = s.ultviagem ,'
            || ' d.valorkmrodado = s.valorkmrodado ,'
            || ' d.vldiaria = s.vldiaria ,'
            || ' d.volume = s.volume '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (altura,'
            || ' chassi,'
            || ' codfilial,'
            || ' codfuncaltsit,'
            || ' codlocalizacao,'
            || ' codveiculo,'
            || ' comprimento,'
            || ' cor,'
            || ' descricao,'
            || ' kmatual,'
            || ' kminicial,'
            || ' largura,'
            || ' marca,'
            || ' mediakm,'
            || ' obs,'
            || ' obs2,'
            || ' pesocargakg,'
            || ' pesocargakg2,'
            || ' placa,'
            || ' proprio,'
            || ' qteixos,'
            || ' qtlitros,'
            || ' qtpalete,'
            || ' qtrodas,'
            || ' qttanques,'
            || ' rastreado,'
            || ' situacao,'
            || ' tipoveiculo,'
            || ' ultviagem,'
            || ' valorkmrodado,'
            || ' vldiaria,'
            || ' volume ) '
            || ' VALUES ( s.altura,'
            || ' s.chassi,'
            || ' s.codfilial,'
            || ' s.codfuncaltsit,'
            || ' s.codlocalizacao,'
            || ' s.codveiculo,'
            || ' s.comprimento,'
            || ' s.cor,'
            || ' s.descricao,'
            || ' s.kmatual,'
            || ' s.kminicial,'
            || ' s.largura,'
            || ' s.marca,'
            || ' s.mediakm,'
            || ' s.obs,'
            || ' s.obs2,'
            || ' s.pesocargakg,'
            || ' s.pesocargakg2,'
            || ' s.placa,'
            || ' s.proprio,'
            || ' s.qteixos,'
            || ' s.qtlitros,'
            || ' s.qtpalete,'
            || ' s.qtrodas,'
            || ' s.qttanques,'
            || ' s.rastreado,'
            || ' s.situacao,'
            || ' s.tipoveiculo,'
            || ' s.ultviagem,'
            || ' s.valorkmrodado,'
            || ' s.vldiaria,'
            || ' s.volume )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcveicul;

   FUNCTION importar_pcembalagem (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcembalagem';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codauxiliar number(16,0),'
         || '  codprod number(6,0),'
         || '  embalagem varchar2(12),'
         || '  unidade varchar2(2),'
         || '  qtunit number(18,6),'
         || '  ptabela number(12,3),'
         || '  pvenda number(12,3),'
         || '  dtultaltptabela date,'
         || '  dtultaltpvenda date,'
         || '  codfuncaltptabela number(8,0),'
         || '  codfuncaltpvenda number(8,0),'
         || '  qtmingondola number(6,0),'
         || '  qtmaxgondola number(6,0),'
         || '  qtmaxvenda number(18,6),'
         || '  margem_esp number(6,2),'
         || '  margem number(6,2),'
         || '  exportacampo varchar2(1),'
         || '  prazoval number(4,0),'
         || '  codfilial varchar2(2),'
         || '  poferta number(12,2),'
         || '  dtofertaini date,'
         || '  dtofertafim date,'
         || '  dtultaltcom date,'
         || '  excluido varchar2(1),'
         || '  permitemultiplicacao varchar2(1),'
         || '  usabalancatoledo varchar2(1),'
         || '  tipoembalagem varchar2(1),'
         || '  dtemissaoetiq date,'
         || '  numseqatu number,'
         || '  fatorpreco number(20,8),'
         || '  qtminimaatacado number(18,6),'
         || '  qtminimaatacadof number(18,6),'
         || '  enviafv varchar2(1),'
         || '  margematac_esp number(6,2),'
         || '  dtultaltptabelaatac date,'
         || '  dtultaltpvendaatac date,'
         || '  margematac number(6,2),'
         || '  obs varchar2(2),'
         || '  precoanterioratac number(12,3),'
         || '  pvendaatac number(12,3),'
         || '  ptabelaatac number(12,3),'
         || '  precoanterior number(12,3),'
         || '  margemidealatac number(6,2),'
         || '  dtofertaatacfim date,'
         || '  dtofertaatacini date,'
         || '  pofertaatac number(12,3),'
         || '  pesobruto number(20,8),'
         || '  pesoliq number(20,8),'
         || '  qtmultipla number(6,0),'         
         || '  enviabalanca varchar2(1))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codfilial = s.codfilial) and'
            || '     (d.codauxiliar = s.codauxiliar)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.codprod = s.codprod,'
            || '     d.embalagem = s.embalagem,'
            || '     d.unidade = s.unidade,'
            || '     d.qtunit = s.qtunit,'
            || '     d.ptabela = s.ptabela,'
            || '     d.pvenda = s.pvenda,'
            || '     d.dtultaltptabela = s.dtultaltptabela,'
            || '     d.dtultaltpvenda = s.dtultaltpvenda,'
            || '     d.codfuncaltptabela = s.codfuncaltptabela,'
            || '     d.codfuncaltpvenda = s.codfuncaltpvenda,'
            || '     d.qtmingondola = s.qtmingondola,'
            || '     d.qtmaxgondola = s.qtmaxgondola,'
            || '     d.qtmaxvenda = s.qtmaxvenda,'
            || '     d.margem_esp = s.margem_esp,'
            || '     d.margem = s.margem,'
            || '     d.exportacampo = s.exportacampo,'
            || '     d.prazoval = s.prazoval,'
            || '     d.poferta = s.poferta,'
            || '     d.dtofertaini = s.dtofertaini,'
            || '     d.dtofertafim = s.dtofertafim,'
            || '     d.dtultaltcom = s.dtultaltcom,'
            || '     d.excluido = s.excluido,'
            || '     d.permitemultiplicacao = s.permitemultiplicacao,'
            || '     d.usabalancatoledo = s.usabalancatoledo,'
            || '     d.tipoembalagem = s.tipoembalagem,'
            || '     d.dtemissaoetiq = s.dtemissaoetiq,'
            || '     d.numseqatu = s.numseqatu,'
            || '     d.fatorpreco = s.fatorpreco,'
            || '     d.qtminimaatacado = s.qtminimaatacado,'
            || '     d.qtminimaatacadof = s.qtminimaatacadof,'
            || '     d.enviafv = s.enviafv,'
            || '     d.margematac_esp = s.margematac_esp,'
            || '     d.dtultaltptabelaatac = s.dtultaltptabelaatac,'
            || '     d.dtultaltpvendaatac = s.dtultaltpvendaatac,'
            || '     d.margematac = s.margematac,'
            || '     d.obs = s.obs,'
            || '     d.precoanterioratac = s.precoanterioratac,'
            || '     d.pvendaatac = s.pvendaatac,'
            || '     d.ptabelaatac = s.ptabelaatac,'
            || '     d.precoanterior = s.precoanterior,'
            || '     d.margemidealatac = s.margemidealatac,'
            || '     d.dtofertaatacfim = s.dtofertaatacfim,'
            || '     d.dtofertaatacini = s.dtofertaatacini,'
            || '     d.pofertaatac = s.pofertaatac,'
            || '     d.pesobruto = s.pesobruto,'
            || '     d.pesoliq = s.pesoliq,'
            || '     d.qtmultipla = s.qtmultipla,'            
            || '     d.enviabalanca = s.enviabalanca'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codauxiliar, codprod, embalagem, unidade, qtunit, ptabela, pvenda, dtultaltptabela, dtultaltpvenda,'
            || '         codfuncaltptabela, codfuncaltpvenda, qtmingondola, qtmaxgondola, qtmaxvenda, margem_esp, margem,'
            || '         exportacampo, prazoval, codfilial, poferta, dtofertaini, dtofertafim, dtultaltcom, excluido,'
            || '         permitemultiplicacao, usabalancatoledo, tipoembalagem, dtemissaoetiq, numseqatu, fatorpreco,'
            || '         qtminimaatacado, qtminimaatacadof, enviafv, margematac_esp, dtultaltptabelaatac, dtultaltpvendaatac,'
            || '         margematac, obs, precoanterioratac, pvendaatac, ptabelaatac, precoanterior, margemidealatac,'
            || '         dtofertaatacfim, dtofertaatacini, pofertaatac, pesobruto, pesoliq, qtmultipla, enviabalanca) '
            || ' VALUES (s.codauxiliar, s.codprod, s.embalagem, s.unidade, s.qtunit, s.ptabela, s.pvenda,'
            || '         s.dtultaltptabela, s.dtultaltpvenda, s.codfuncaltptabela, s.codfuncaltpvenda,'
            || '         s.qtmingondola, s.qtmaxgondola, s.qtmaxvenda, s.margem_esp, s.margem, s.exportacampo,'
            || '         s.prazoval, s.codfilial, s.poferta, s.dtofertaini, s.dtofertafim, s.dtultaltcom,'
            || '         s.excluido, s.permitemultiplicacao, s.usabalancatoledo, s.tipoembalagem,'
            || '         s.dtemissaoetiq, s.numseqatu, s.fatorpreco, s.qtminimaatacado, s.qtminimaatacadof,'
            || '         s.enviafv, s.margematac_esp, s.dtultaltptabelaatac, s.dtultaltpvendaatac, s.margematac,'
            || '         s.obs, s.precoanterioratac, s.pvendaatac, s.ptabelaatac, s.precoanterior,'
            || '         s.margemidealatac, s.dtofertaatacfim, s.dtofertaatacini, s.pofertaatac, s.pesobruto,'
            || '         s.pesoliq, s.qtmultipla, s.enviabalanca)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcembalagem;

   FUNCTION importar_pcempr (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcempr';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (tipomotorista varchar2(1),'
         || '  sexo varchar2(1),'
         || '  dtnasc date,'
         || '  dtvalidadecnh date,'
         || '  orgaoemissorrg varchar2(20),'
         || '  nacionalidade varchar2(40),'
         || '  estadocivil varchar2(25),'
         || '  profissao varchar2(30),'
         || '  usuariologado varchar2(1),'
         || '  numdvagencia varchar2(2),'
         || '  numconexoes number(4,0),'
         || '  numconexoesatual number(4,0),'
         || '  grupoemail varchar2(10),'
         || '  nomeemail varchar2(40),'
         || '  percminjurosmora number(8,4),'
         || '  percmaxjurosmora number(8,4),'
         || '  codidioma varchar2(6),'
         || '  percexclimcred number(8,4),'
         || '  enviafv varchar2(1),'
         || '  percreduzcomisrca number(6,2),'
         || '  vlsaldolimaltcredito number(14,2),'
         || '  grupoos number(15,0),'
         || '  dtinicio date,'
         || '  tipoatende varchar2(1),'
         || '  iprf varchar2(14),'
         || '  codbarra varchar2(20),'
         || '  obsinativo varchar2(100),'
         || '  numdiaspagtoretroativo number(3,0),'
         || '  vendaassistida varchar2(1),'
         || '  matricula number(8,0),'
         || '  nome varchar2(40),'
         || '  dt_exclusao date,'
         || '  nome_guerra varchar2(15),'
         || '  admissao date,'
         || '  endereco varchar2(40),'
         || '  bairro varchar2(20),'
         || '  cidade varchar2(20),'
         || '  estado varchar2(2),'
         || '  cep number(8,0),'
         || '  fone varchar2(13),'
         || '  codsetor number(6,0),'
         || '  usuariobd varchar2(15),'
         || '  senhabd varchar2(32),'
         || '  situacao varchar2(1),'
         || '  cpf varchar2(20),'
         || '  tipovenda varchar2(1),'
         || '  codfilial varchar2(2),'
         || '  codusur number(4,0),'
         || '  celular varchar2(13),'
         || '  numbanco number(3,0),'
         || '  numagencia number(4,0),'
         || '  numccorrente varchar2(15),'
         || '  numcentralpa number(4,0),'
         || '  numcentraltel varchar2(20),'
         || '  permitealtjurosbx varchar2(1),'
         || '  vlaumentolimcred number(14,2),'
         || '  tipo varchar2(1),'
         || '  rg varchar2(20),'
         || '  ctps varchar2(20),'
         || '  pis varchar2(20),'
         || '  funcao varchar2(30),'
         || '  email varchar2(50),'
         || '  fatorcomissao number(5,2),'
         || '  dtexpirasenha date,'
         || '  vlcomisston number(14,2),'
         || '  vlcomissent number(14,2),'
         || '  vllimcredcompra number(14,2),'
         || '  dtiniciolimcredcompra date,'
         || '  dtfimlimcredcompra date,'
         || '  codconferente number(8,0),'
         || '  codfuncao number(4,0),'
         || '  seriectps varchar2(15),'
         || '  geracccard varchar2(1),'
         || '  matriculacccard number(10,0),'
         || '  vlsalcarteira number(10,2),'
         || '  vlsalario number(10,2),'
         || '  rescisao date,'
         || '  numfilhos number(2,0),'
         || '  complemento varchar2(40),'
         || '  observacao varchar2(100),'
         || '  percvt number(5,2),'
         || '  vlplanosaude number(10,2),'
         || '  vlsalfamilia number(10,2),'
         || '  percinss number(5,2),'
         || '  vlpensaoalimenticia number(10,2),'
         || '  vladicional number(10,2),'
         || '  vlvales number(10,2),'
         || '  vlmaxlibpedido number(16,3),'
         || '  cnh varchar2(15),'
         || '  ufcnh varchar2(2),'
         || '  tipoenvio varchar2(1),'
         || '  codfornec number(6,0),'
         || '  percommot number(5,2),'
         || '  vlfreteentrega number(10,4),'
         || '  codveiculo number(4,0),'
         || '  permitealtdescbx varchar2(1),'
         || '  referenciapessoal varchar2(100),'
         || '  dddtel number(3,0),'
         || '  nomepai varchar2(60),'
         || '  nomemae varchar2(60),'
         || '  categoriacnh varchar2(3))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.matricula = s.matricula) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.tipomotorista = s.tipomotorista,'
            || '     d.sexo = s.sexo,'
            || '     d.dtnasc = s.dtnasc,'
            || '     d.dtvalidadecnh = s.dtvalidadecnh,'
            || '     d.orgaoemissorrg = s.orgaoemissorrg,'
            || '     d.nacionalidade = s.nacionalidade,'
            || '     d.estadocivil = s.estadocivil,'
            || '     d.profissao = s.profissao,'
            || '     d.usuariologado = s.usuariologado,'
            || '     d.numdvagencia = s.numdvagencia,'
            || '     d.numconexoes = s.numconexoes,'
            || '     d.numconexoesatual = s.numconexoesatual,'
            || '     d.grupoemail = s.grupoemail,'
            || '     d.nomeemail = s.nomeemail,'
            || '     d.percminjurosmora = s.percminjurosmora,'
            || '     d.percmaxjurosmora = s.percmaxjurosmora,'
            || '     d.codidioma = s.codidioma,'
            || '     d.percexclimcred = s.percexclimcred,'
            || '     d.enviafv = s.enviafv,'
            || '     d.percreduzcomisrca = s.percreduzcomisrca,'
            || '     d.vlsaldolimaltcredito = s.vlsaldolimaltcredito,'
            || '     d.grupoos = s.grupoos,'
            || '     d.dtinicio = s.dtinicio,'
            || '     d.tipoatende = s.tipoatende,'
            || '     d.iprf = s.iprf,'
            || '     d.codbarra = s.codbarra,'
            || '     d.obsinativo = s.obsinativo,'
            || '     d.numdiaspagtoretroativo = s.numdiaspagtoretroativo,'
            || '     d.vendaassistida = s.vendaassistida,'
            || '     d.nome = s.nome,'
            || '     d.dt_exclusao = s.dt_exclusao,'
            || '     d.nome_guerra = s.nome_guerra,'
            || '     d.admissao = s.admissao,'
            || '     d.endereco = s.endereco,'
            || '     d.bairro = s.bairro,'
            || '     d.cidade = s.cidade,'
            || '     d.estado = s.estado,'
            || '     d.cep = s.cep,'
            || '     d.fone = s.fone,'
            || '     d.codsetor = s.codsetor,'
            || '     d.usuariobd = s.usuariobd,'
            || '     d.senhabd = s.senhabd,'
            || '     d.situacao = s.situacao,'
            || '     d.cpf = s.cpf,'
            || '     d.tipovenda = s.tipovenda,'
            || '     d.codfilial = s.codfilial,'
            || '     d.codusur = s.codusur,'
            || '     d.celular = s.celular,'
            || '     d.numbanco = s.numbanco,'
            || '     d.numagencia = s.numagencia,'
            || '     d.numccorrente = s.numccorrente,'
            || '     d.numcentralpa = s.numcentralpa,'
            || '     d.numcentraltel = s.numcentraltel,'
            || '     d.permitealtjurosbx = s.permitealtjurosbx,'
            || '     d.vlaumentolimcred = s.vlaumentolimcred,'
            || '     d.tipo = s.tipo,'
            || '     d.rg = s.rg,'
            || '     d.ctps = s.ctps,'
            || '     d.pis = s.pis,'
            || '     d.funcao = s.funcao,'
            || '     d.email = s.email,'
            || '     d.fatorcomissao = s.fatorcomissao,'
            || '     d.dtexpirasenha = s.dtexpirasenha,'
            || '     d.vlcomisston = s.vlcomisston,'
            || '     d.vlcomissent = s.vlcomissent,'
            || '     d.vllimcredcompra = s.vllimcredcompra,'
            || '     d.dtiniciolimcredcompra = s.dtiniciolimcredcompra,'
            || '     d.dtfimlimcredcompra = s.dtfimlimcredcompra,'
            || '     d.codconferente = s.codconferente,'
            || '     d.codfuncao = s.codfuncao,'
            || '     d.seriectps = s.seriectps,'
            || '     d.geracccard = s.geracccard,'
            || '     d.matriculacccard = s.matriculacccard,'
            || '     d.vlsalcarteira = s.vlsalcarteira,'
            || '     d.vlsalario = s.vlsalario,'
            || '     d.rescisao = s.rescisao,'
            || '     d.numfilhos = s.numfilhos,'
            || '     d.complemento = s.complemento,'
            || '     d.observacao = s.observacao,'
            || '     d.percvt = s.percvt,'
            || '     d.vlplanosaude = s.vlplanosaude,'
            || '     d.vlsalfamilia = s.vlsalfamilia,'
            || '     d.percinss = s.percinss,'
            || '     d.vlpensaoalimenticia = s.vlpensaoalimenticia,'
            || '     d.vladicional = s.vladicional,'
            || '     d.vlvales = s.vlvales,'
            || '     d.vlmaxlibpedido = s.vlmaxlibpedido,'
            || '     d.cnh = s.cnh,'
            || '     d.ufcnh = s.ufcnh,'
            || '     d.tipoenvio = s.tipoenvio,'
            || '     d.codfornec = s.codfornec,'
            || '     d.percommot = s.percommot,'
            || '     d.vlfreteentrega = s.vlfreteentrega,'
            || '     d.codveiculo = s.codveiculo,'
            || '     d.permitealtdescbx = s.permitealtdescbx,'
            || '     d.referenciapessoal = s.referenciapessoal,'
            || '     d.dddtel = s.dddtel,'
            || '     d.nomepai = s.nomepai,'
            || '     d.nomemae = s.nomemae,'
            || '     d.categoriacnh = s.categoriacnh'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (tipomotorista, sexo, dtnasc, dtvalidadecnh, orgaoemissorrg, nacionalidade, estadocivil, profissao,'
            || '         usuariologado, numdvagencia, numconexoes, numconexoesatual, grupoemail, nomeemail, percminjurosmora,'
            || '         percmaxjurosmora, codidioma, percexclimcred, enviafv, percreduzcomisrca, vlsaldolimaltcredito,'
            || '         grupoos, dtinicio, tipoatende, iprf, codbarra, obsinativo, numdiaspagtoretroativo, vendaassistida,'
            || '         matricula, nome, dt_exclusao, nome_guerra, admissao, endereco, bairro, cidade, estado, cep, fone,'
            || '         codsetor, usuariobd, senhabd, situacao, cpf, tipovenda, codfilial, codusur, celular, numbanco,'
            || '         numagencia, numccorrente, numcentralpa, numcentraltel, permitealtjurosbx, vlaumentolimcred,'
            || '         tipo, rg, ctps, pis, funcao, email, fatorcomissao, dtexpirasenha, vlcomisston, vlcomissent,'
            || '         vllimcredcompra, dtiniciolimcredcompra, dtfimlimcredcompra, codconferente, codfuncao,seriectps,'
            || '         geracccard, matriculacccard, vlsalcarteira, vlsalario, rescisao, numfilhos, complemento,'
            || '         observacao, percvt, vlplanosaude, vlsalfamilia, percinss, vlpensaoalimenticia, vladicional,'
            || '         vlvales, vlmaxlibpedido, cnh, ufcnh, tipoenvio, codfornec, percommot, vlfreteentrega, codveiculo,'
            || '         permitealtdescbx, referenciapessoal, dddtel, nomepai, nomemae, categoriacnh) '
            || ' VALUES (s.tipomotorista, s.sexo, s.dtnasc, s.dtvalidadecnh, s.orgaoemissorrg, s.nacionalidade,'
            || '        s.estadocivil, s.profissao, s.usuariologado, s.numdvagencia, s.numconexoes, s.numconexoesatual,'
            || '        s.grupoemail, s.nomeemail, s.percminjurosmora, s.percmaxjurosmora, s.codidioma, s.percexclimcred,'
            || '        s.enviafv, s.percreduzcomisrca, s.vlsaldolimaltcredito, s.grupoos, s.dtinicio, s.tipoatende,'
            || '        s.iprf, s.codbarra, s.obsinativo, s.numdiaspagtoretroativo, s.vendaassistida, s.matricula,'
            || '        s.nome, s.dt_exclusao, s.nome_guerra, s.admissao, s.endereco, s.bairro, s.cidade, s.estado,'
            || '        s.cep, s.fone, s.codsetor, s.usuariobd, s.senhabd, s.situacao, s.cpf, s.tipovenda, s.codfilial,'
            || '        s.codusur, s.celular, s.numbanco, s.numagencia, s.numccorrente, s.numcentralpa, s.numcentraltel,'
            || '        s.permitealtjurosbx, s.vlaumentolimcred, s.tipo, s.rg, s.ctps, s.pis, s.funcao, s.email,'
            || '        s.fatorcomissao, s.dtexpirasenha, s.vlcomisston, s.vlcomissent, s.vllimcredcompra,'
            || '        s.dtiniciolimcredcompra, s.dtfimlimcredcompra, s.codconferente, s.codfuncao, s.seriectps,'
            || '        s.geracccard, s.matriculacccard, s.vlsalcarteira, s.vlsalario, s.rescisao, s.numfilhos,'
            || '        s.complemento, s.observacao, s.percvt, s.vlplanosaude, s.vlsalfamilia, s.percinss,'
            || '        s.vlpensaoalimenticia, s.vladicional, s.vlvales, s.vlmaxlibpedido, s.cnh, s.ufcnh,'
            || '        s.tipoenvio, s.codfornec, s.percommot, s.vlfreteentrega, s.codveiculo, s.permitealtdescbx,'
            || '        s.referenciapessoal, s.dddtel, s.nomepai, s.nomemae, s.categoriacnh)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcempr;

   FUNCTION importar_pctribut (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pctribut';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( aliqicms1 NUMBER(8,4),'
         || ' aliqicms1fonte NUMBER(8,4),'
         || ' aliqicms1tab NUMBER(8,4),'
         || ' aliqicms1transf NUMBER(8,4),'
         || ' aliqicms2 NUMBER(8,4),'
         || ' aliqicms2fonte NUMBER(8,4),'
         || ' aliqicms2tab NUMBER(8,4),'
         || ' aliqicms2transf NUMBER(8,4),'
         || ' aliqiss NUMBER(8,4),'
         || ' aliqstsaida NUMBER(8,4),'
         || ' aliqstsaidapf NUMBER(8,4),'
         || ' aplicaacrescpjisenta VARCHAR2(1),'
         || ' calcbaseredicmstransf VARCHAR2(1),'
         || ' calcbcicmsnf VARCHAR2(1),'
         || ' calcsttransf VARCHAR2(1),'
         || ' codecf VARCHAR2(4),'
         || ' codfiscal NUMBER(8,0),'
         || ' codfiscalbonific NUMBER(8,0),'
         || ' codfiscalbonificinter NUMBER(8,0),'
         || ' codfiscalbonificinternasc NUMBER(8,0),'
         || ' codfiscaldevcli NUMBER(8,0),'
         || ' codfiscaldevclibonific NUMBER(8,0),'
         || ' codfiscaldevclibonificinter NUMBER(8,0),'
         || ' codfiscaldevcliboninternasc NUMBER(8,0),'
         || ' codfiscaldevcliinter NUMBER(8,0),'
         || ' codfiscaldevcliinternasc NUMBER(8,0),'
         || ' codfiscaldevcliproentinternasc NUMBER(8,0),'
         || ' codfiscaldevcliprontaent NUMBER(8,0),'
         || ' codfiscaldevcliprontaentinter NUMBER(8,0),'
         || ' codfiscaldevisentost NUMBER(8,0),'
         || ' codfiscaldevisentostinter NUMBER(8,0),'
         || ' codfiscaldevisentostinternasc NUMBER(8,0),'
         || ' codfiscaldevmercconsig NUMBER(8,0),'
         || ' codfiscaldevmercconsiginter NUMBER(8,0),'
         || ' codfiscaldevtransf NUMBER(8,0),'
         || ' codfiscaldevtransfinter NUMBER(8,0),'
         || ' codfiscalinter NUMBER(8,0),'
         || ' codfiscalinternasc NUMBER(8,0),'
         || ' codfiscalinternascpf NUMBER(8,0),'
         || ' codfiscalinterpf NUMBER(8,0),'
         || ' codfiscalisentost NUMBER(8,0),'
         || ' codfiscalisentostinter NUMBER(8,0),'
         || ' codfiscalisentostinternasc NUMBER(8,0),'
         || ' codfiscalmercconsig NUMBER(8,0),'
         || ' codfiscalmercconsiginter NUMBER(8,0),'
         || ' codfiscalmercconsiginternasc NUMBER(8,0),'
         || ' codfiscalpf NUMBER(8,0),'
         || ' codfiscalprontaent NUMBER(8,0),'
         || ' codfiscalprontaentinter NUMBER(8,0),'
         || ' codfiscalprontaentinternasc NUMBER(8,0),'
         || ' codfiscalsimpentfut NUMBER(8,0),'
         || ' codfiscalsimpentfutinter NUMBER(8,0),'
         || ' codfiscalsrestsr NUMBER(8,0),'
         || ' codfiscalsrext NUMBER(8,0),'
         || ' codfiscalsrinte NUMBER(8,0),'
         || ' codfiscaltransf NUMBER(8,0),'
         || ' codfiscaltransfent NUMBER(8,0),'
         || ' codfiscaltransfentinter NUMBER(8,0),'
         || ' codfiscaltransfinter NUMBER(8,0),'
         || ' codfiscaltransfinternasc NUMBER(8,0),'
         || ' codfiscaltroca NUMBER(8,0),'
         || ' codfiscaltrocainter NUMBER(8,0),'
         || ' codfiscaltrocainternasc NUMBER(8,0),'
         || ' codfiscalvendaconsig NUMBER(10,0),'
         || ' codfiscalvendaconsiginter NUMBER(10,0),'
         || ' codfiscalvendaconsiginternasc NUMBER(10,0),'
         || ' codfiscalvendaentfut NUMBER(8,0),'
         || ' codfiscalvendaentfutinter NUMBER(8,0),'
         || ' codfiscalvendaprontaent NUMBER(8,0),'
         || ' codfiscalvendaprontaentinter NUMBER(8,0),'
         || ' codfuncultalter NUMBER(8,0),'
         || ' codicm NUMBER(8,4),'
         || ' codicmantecipado NUMBER(8,4),'
         || ' codicmconsumidor NUMBER(8,2),'
         || ' codicmnrpa NUMBER(8,4),'
         || ' codicmpf NUMBER(8,4),'
         || ' codicmprodrural NUMBER(10,4),'
         || ' codicmtab NUMBER(8,4),'
         || ' codicmtabnrpa NUMBER(8,4),'
         || ' codicmtabpf NUMBER(8,4),'
         || ' codicmtransf NUMBER(8,4),'
         || ' codst NUMBER(4,0),'
         || ' descicmsreduzbaseicms VARCHAR2(1),'
         || ' dtultalter DATE,'
         || ' indicest NUMBER(8,4),'
         || ' iva NUMBER(8,4),'
         || ' ivafonte NUMBER(8,4),'
         || ' ivatab NUMBER(8,4),'
         || ' ivatransf NUMBER(8,4),'
         || ' mensagem VARCHAR2(40),'
         || ' mensagemnrpa VARCHAR2(100),'
         || ' numseqatu NUMBER,'
         || ' obs VARCHAR2(100),'
         || ' obspf VARCHAR2(100),'
         || ' obspf2 VARCHAR2(100),'
         || ' obstransf VARCHAR2(100),'
         || ' obs2 VARCHAR2(100),'
         || ' pauta NUMBER(8,4),'
         || ' pautatab NUMBER(8,4),'
         || ' pautatransf NUMBER(8,4),'
         || ' peracrescimonrpa NUMBER(8,4),'
         || ' peracrescismopf NUMBER(8,4),'
         || ' perbaserednrpa NUMBER(8,4),'
         || ' perbaseredtransfent NUMBER(8,4),'
         || ' percacrescbasepfest NUMBER(8,4),'
         || ' percagregadorst NUMBER(8,4),'
         || ' percbasecalcrepasse NUMBER(18,6),'
         || ' percbasered NUMBER(8,4),'
         || ' percbaseredadicional NUMBER(18,6),'
         || ' percbaseredadicionalinter NUMBER(18,6),'
         || ' percbaseredconsumidor NUMBER(8,4),'
         || ' percbaseredst NUMBER(8,4),'
         || ' percbaseredstfonte NUMBER(8,4),'
         || ' percbaseredsttransf NUMBER(8,4),'
         || ' percbaseredtranfsaid NUMBER(8,4),'
         || ' percivamex NUMBER(8,4),'
         || ' perdesccusto NUMBER(8,4),'
         || ' perdescicmisencao NUMBER(8,4),'
         || ' perdescpissuframa NUMBER(8,4),'
         || ' perdescrepasse NUMBER(8,4),'
         || ' perdescsuframa NUMBER(8,4),'
         || ' perdestab NUMBER(8,4),'
         || ' perpautaicms NUMBER(18,6),'
         || ' perpautaicmsinter NUMBER(18,6),'
         || ' sittribut VARCHAR2(2),'
         || ' sittributisentost VARCHAR2(2),'
         || ' sittributnrpa VARCHAR2(2),'
         || ' sittributpf VARCHAR2(3),'
         || ' sittributtransf VARCHAR2(3),'
         || ' sittributtransfent VARCHAR2(2),'
         || ' tipocalculognre VARCHAR2(1),'
         || ' tipocalculognretab VARCHAR2(1),'
         || ' usapercbaseredassoc VARCHAR2(1),'
         || ' usapercbasereddist VARCHAR2(1),'
         || ' usapercbaseredfarma VARCHAR2(1),'
         || ' usapercbaseredhosp VARCHAR2(1),'
         || ' usapercbaseredmedico VARCHAR2(1),'
         || ' usapercbaseredope VARCHAR2(1),'
         || ' usapercbaseredopf VARCHAR2(1),'
         || ' usapercbaseredopm VARCHAR2(1),'
         || ' usaredbaseicmsfontest VARCHAR2(1),'
         || ' usavalorultentbasest VARCHAR2(1),'
         || ' utilizapercbaseredpf VARCHAR2(1)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codst = s.codst) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.aliqicms1 = s.aliqicms1 ,'
            || ' d.aliqicms1fonte = s.aliqicms1fonte ,'
            || ' d.aliqicms1tab = s.aliqicms1tab ,'
            || ' d.aliqicms1transf = s.aliqicms1transf ,'
            || ' d.aliqicms2 = s.aliqicms2 ,'
            || ' d.aliqicms2fonte = s.aliqicms2fonte ,'
            || ' d.aliqicms2tab = s.aliqicms2tab ,'
            || ' d.aliqicms2transf = s.aliqicms2transf ,'
            || ' d.aliqiss = s.aliqiss ,'
            || ' d.aliqstsaida = s.aliqstsaida ,'
            || ' d.aliqstsaidapf = s.aliqstsaidapf ,'
            || ' d.aplicaacrescpjisenta = s.aplicaacrescpjisenta ,'
            || ' d.calcbaseredicmstransf = s.calcbaseredicmstransf ,'
            || ' d.calcbcicmsnf = s.calcbcicmsnf ,'
            || ' d.calcsttransf = s.calcsttransf ,'
            || ' d.codecf = s.codecf ,'
            || ' d.codfiscal = s.codfiscal ,'
            || ' d.codfiscalbonific = s.codfiscalbonific ,'
            || ' d.codfiscalbonificinter = s.codfiscalbonificinter ,'
            || ' d.codfiscalbonificinternasc = s.codfiscalbonificinternasc ,'
            || ' d.codfiscaldevcli = s.codfiscaldevcli ,'
            || ' d.codfiscaldevclibonific = s.codfiscaldevclibonific ,'
            || ' d.codfiscaldevclibonificinter = s.codfiscaldevclibonificinter ,'
            || ' d.codfiscaldevcliboninternasc = s.codfiscaldevcliboninternasc ,'
            || ' d.codfiscaldevcliinter = s.codfiscaldevcliinter ,'
            || ' d.codfiscaldevcliinternasc = s.codfiscaldevcliinternasc ,'
            || ' d.codfiscaldevcliproentinternasc = s.codfiscaldevcliproentinternasc ,'
            || ' d.codfiscaldevcliprontaent = s.codfiscaldevcliprontaent ,'
            || ' d.codfiscaldevcliprontaentinter = s.codfiscaldevcliprontaentinter ,'
            || ' d.codfiscaldevisentost = s.codfiscaldevisentost ,'
            || ' d.codfiscaldevisentostinter = s.codfiscaldevisentostinter ,'
            || ' d.codfiscaldevisentostinternasc = s.codfiscaldevisentostinternasc ,'
            || ' d.codfiscaldevmercconsig = s.codfiscaldevmercconsig ,'
            || ' d.codfiscaldevmercconsiginter = s.codfiscaldevmercconsiginter ,'
            || ' d.codfiscaldevtransf = s.codfiscaldevtransf ,'
            || ' d.codfiscaldevtransfinter = s.codfiscaldevtransfinter ,'
            || ' d.codfiscalinter = s.codfiscalinter ,'
            || ' d.codfiscalinternasc = s.codfiscalinternasc ,'
            || ' d.codfiscalinternascpf = s.codfiscalinternascpf ,'
            || ' d.codfiscalinterpf = s.codfiscalinterpf ,'
            || ' d.codfiscalisentost = s.codfiscalisentost ,'
            || ' d.codfiscalisentostinter = s.codfiscalisentostinter ,'
            || ' d.codfiscalisentostinternasc = s.codfiscalisentostinternasc ,'
            || ' d.codfiscalmercconsig = s.codfiscalmercconsig ,'
            || ' d.codfiscalmercconsiginter = s.codfiscalmercconsiginter ,'
            || ' d.codfiscalmercconsiginternasc = s.codfiscalmercconsiginternasc ,'
            || ' d.codfiscalpf = s.codfiscalpf ,'
            || ' d.codfiscalprontaent = s.codfiscalprontaent ,'
            || ' d.codfiscalprontaentinter = s.codfiscalprontaentinter ,'
            || ' d.codfiscalprontaentinternasc = s.codfiscalprontaentinternasc ,'
            || ' d.codfiscalsimpentfut = s.codfiscalsimpentfut ,'
            || ' d.codfiscalsimpentfutinter = s.codfiscalsimpentfutinter ,'
            || ' d.codfiscalsrestsr = s.codfiscalsrestsr ,'
            || ' d.codfiscalsrext = s.codfiscalsrext ,'
            || ' d.codfiscalsrinte = s.codfiscalsrinte ,'
            || ' d.codfiscaltransf = s.codfiscaltransf ,'
            || ' d.codfiscaltransfent = s.codfiscaltransfent ,'
            || ' d.codfiscaltransfentinter = s.codfiscaltransfentinter ,'
            || ' d.codfiscaltransfinter = s.codfiscaltransfinter ,'
            || ' d.codfiscaltransfinternasc = s.codfiscaltransfinternasc ,'
            || ' d.codfiscaltroca = s.codfiscaltroca ,'
            || ' d.codfiscaltrocainter = s.codfiscaltrocainter ,'
            || ' d.codfiscaltrocainternasc = s.codfiscaltrocainternasc ,'
            || ' d.codfiscalvendaconsig = s.codfiscalvendaconsig ,'
            || ' d.codfiscalvendaconsiginter = s.codfiscalvendaconsiginter ,'
            || ' d.codfiscalvendaconsiginternasc = s.codfiscalvendaconsiginternasc ,'
            || ' d.codfiscalvendaentfut = s.codfiscalvendaentfut ,'
            || ' d.codfiscalvendaentfutinter = s.codfiscalvendaentfutinter ,'
            || ' d.codfiscalvendaprontaent = s.codfiscalvendaprontaent ,'
            || ' d.codfiscalvendaprontaentinter = s.codfiscalvendaprontaentinter ,'
            || ' d.codfuncultalter = s.codfuncultalter ,'
            || ' d.codicm = s.codicm ,'
            || ' d.codicmantecipado = s.codicmantecipado ,'
            || ' d.codicmconsumidor = s.codicmconsumidor ,'
            || ' d.codicmnrpa = s.codicmnrpa ,'
            || ' d.codicmpf = s.codicmpf ,'
            || ' d.codicmprodrural = s.codicmprodrural ,'
            || ' d.codicmtab = s.codicmtab ,'
            || ' d.codicmtabnrpa = s.codicmtabnrpa ,'
            || ' d.codicmtabpf = s.codicmtabpf ,'
            || ' d.codicmtransf = s.codicmtransf ,'
            || ' d.descicmsreduzbaseicms = s.descicmsreduzbaseicms ,'
            || ' d.dtultalter = s.dtultalter ,'
            || ' d.indicest = s.indicest ,'
            || ' d.iva = s.iva ,'
            || ' d.ivafonte = s.ivafonte ,'
            || ' d.ivatab = s.ivatab ,'
            || ' d.ivatransf = s.ivatransf ,'
            || ' d.mensagem = s.mensagem ,'
            || ' d.mensagemnrpa = s.mensagemnrpa ,'
            || ' d.numseqatu = s.numseqatu ,'
            || ' d.obs = s.obs ,'
            || ' d.obspf = s.obspf ,'
            || ' d.obspf2 = s.obspf2 ,'
            || ' d.obstransf = s.obstransf ,'
            || ' d.obs2 = s.obs2 ,'
            || ' d.pauta = s.pauta ,'
            || ' d.pautatab = s.pautatab ,'
            || ' d.pautatransf = s.pautatransf ,'
            || ' d.peracrescimonrpa = s.peracrescimonrpa ,'
            || ' d.peracrescismopf = s.peracrescismopf ,'
            || ' d.perbaserednrpa = s.perbaserednrpa ,'
            || ' d.perbaseredtransfent = s.perbaseredtransfent ,'
            || ' d.percacrescbasepfest = s.percacrescbasepfest ,'
            || ' d.percagregadorst = s.percagregadorst ,'
            || ' d.percbasecalcrepasse = s.percbasecalcrepasse ,'
            || ' d.percbasered = s.percbasered ,'
            || ' d.percbaseredadicional = s.percbaseredadicional ,'
            || ' d.percbaseredadicionalinter = s.percbaseredadicionalinter ,'
            || ' d.percbaseredconsumidor = s.percbaseredconsumidor ,'
            || ' d.percbaseredst = s.percbaseredst ,'
            || ' d.percbaseredstfonte = s.percbaseredstfonte ,'
            || ' d.percbaseredsttransf = s.percbaseredsttransf ,'
            || ' d.percbaseredtranfsaid = s.percbaseredtranfsaid ,'
            || ' d.percivamex = s.percivamex ,'
            || ' d.perdesccusto = s.perdesccusto ,'
            || ' d.perdescicmisencao = s.perdescicmisencao ,'
            || ' d.perdescpissuframa = s.perdescpissuframa ,'
            || ' d.perdescrepasse = s.perdescrepasse ,'
            || ' d.perdescsuframa = s.perdescsuframa ,'
            || ' d.perdestab = s.perdestab ,'
            || ' d.perpautaicms = s.perpautaicms ,'
            || ' d.perpautaicmsinter = s.perpautaicmsinter ,'
            || ' d.sittribut = s.sittribut ,'
            || ' d.sittributisentost = s.sittributisentost ,'
            || ' d.sittributnrpa = s.sittributnrpa ,'
            || ' d.sittributpf = s.sittributpf ,'
            || ' d.sittributtransf = s.sittributtransf ,'
            || ' d.sittributtransfent = s.sittributtransfent ,'
            || ' d.tipocalculognre = s.tipocalculognre ,'
            || ' d.tipocalculognretab = s.tipocalculognretab ,'
            || ' d.usapercbaseredassoc = s.usapercbaseredassoc ,'
            || ' d.usapercbasereddist = s.usapercbasereddist ,'
            || ' d.usapercbaseredfarma = s.usapercbaseredfarma ,'
            || ' d.usapercbaseredhosp = s.usapercbaseredhosp ,'
            || ' d.usapercbaseredmedico = s.usapercbaseredmedico ,'
            || ' d.usapercbaseredope = s.usapercbaseredope ,'
            || ' d.usapercbaseredopf = s.usapercbaseredopf ,'
            || ' d.usapercbaseredopm = s.usapercbaseredopm ,'
            || ' d.usaredbaseicmsfontest = s.usaredbaseicmsfontest ,'
            || ' d.usavalorultentbasest = s.usavalorultentbasest ,'
            || ' d.utilizapercbaseredpf = s.utilizapercbaseredpf '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (aliqicms1,'
            || ' aliqicms1fonte,'
            || ' aliqicms1tab,'
            || ' aliqicms1transf,'
            || ' aliqicms2,'
            || ' aliqicms2fonte,'
            || ' aliqicms2tab,'
            || ' aliqicms2transf,'
            || ' aliqiss,'
            || ' aliqstsaida,'
            || ' aliqstsaidapf,'
            || ' aplicaacrescpjisenta,'
            || ' calcbaseredicmstransf,'
            || ' calcbcicmsnf,'
            || ' calcsttransf,'
            || ' codecf,'
            || ' codfiscal,'
            || ' codfiscalbonific,'
            || ' codfiscalbonificinter,'
            || ' codfiscalbonificinternasc,'
            || ' codfiscaldevcli,'
            || ' codfiscaldevclibonific,'
            || ' codfiscaldevclibonificinter,'
            || ' codfiscaldevcliboninternasc,'
            || ' codfiscaldevcliinter,'
            || ' codfiscaldevcliinternasc,'
            || ' codfiscaldevcliproentinternasc,'
            || ' codfiscaldevcliprontaent,'
            || ' codfiscaldevcliprontaentinter,'
            || ' codfiscaldevisentost,'
            || ' codfiscaldevisentostinter,'
            || ' codfiscaldevisentostinternasc,'
            || ' codfiscaldevmercconsig,'
            || ' codfiscaldevmercconsiginter,'
            || ' codfiscaldevtransf,'
            || ' codfiscaldevtransfinter,'
            || ' codfiscalinter,'
            || ' codfiscalinternasc,'
            || ' codfiscalinternascpf,'
            || ' codfiscalinterpf,'
            || ' codfiscalisentost,'
            || ' codfiscalisentostinter,'
            || ' codfiscalisentostinternasc,'
            || ' codfiscalmercconsig,'
            || ' codfiscalmercconsiginter,'
            || ' codfiscalmercconsiginternasc,'
            || ' codfiscalpf,'
            || ' codfiscalprontaent,'
            || ' codfiscalprontaentinter,'
            || ' codfiscalprontaentinternasc,'
            || ' codfiscalsimpentfut,'
            || ' codfiscalsimpentfutinter,'
            || ' codfiscalsrestsr,'
            || ' codfiscalsrext,'
            || ' codfiscalsrinte,'
            || ' codfiscaltransf,'
            || ' codfiscaltransfent,'
            || ' codfiscaltransfentinter,'
            || ' codfiscaltransfinter,'
            || ' codfiscaltransfinternasc,'
            || ' codfiscaltroca,'
            || ' codfiscaltrocainter,'
            || ' codfiscaltrocainternasc,'
            || ' codfiscalvendaconsig,'
            || ' codfiscalvendaconsiginter,'
            || ' codfiscalvendaconsiginternasc,'
            || ' codfiscalvendaentfut,'
            || ' codfiscalvendaentfutinter,'
            || ' codfiscalvendaprontaent,'
            || ' codfiscalvendaprontaentinter,'
            || ' codfuncultalter,'
            || ' codicm,'
            || ' codicmantecipado,'
            || ' codicmconsumidor,'
            || ' codicmnrpa,'
            || ' codicmpf,'
            || ' codicmprodrural,'
            || ' codicmtab,'
            || ' codicmtabnrpa,'
            || ' codicmtabpf,'
            || ' codicmtransf,'
            || ' codst,'
            || ' descicmsreduzbaseicms,'
            || ' dtultalter,'
            || ' indicest,'
            || ' iva,'
            || ' ivafonte,'
            || ' ivatab,'
            || ' ivatransf,'
            || ' mensagem,'
            || ' mensagemnrpa,'
            || ' numseqatu,'
            || ' obs,'
            || ' obspf,'
            || ' obspf2,'
            || ' obstransf,'
            || ' obs2,'
            || ' pauta,'
            || ' pautatab,'
            || ' pautatransf,'
            || ' peracrescimonrpa,'
            || ' peracrescismopf,'
            || ' perbaserednrpa,'
            || ' perbaseredtransfent,'
            || ' percacrescbasepfest,'
            || ' percagregadorst,'
            || ' percbasecalcrepasse,'
            || ' percbasered,'
            || ' percbaseredadicional,'
            || ' percbaseredadicionalinter,'
            || ' percbaseredconsumidor,'
            || ' percbaseredst,'
            || ' percbaseredstfonte,'
            || ' percbaseredsttransf,'
            || ' percbaseredtranfsaid,'
            || ' percivamex,'
            || ' perdesccusto,'
            || ' perdescicmisencao,'
            || ' perdescpissuframa,'
            || ' perdescrepasse,'
            || ' perdescsuframa,'
            || ' perdestab,'
            || ' perpautaicms,'
            || ' perpautaicmsinter,'
            || ' sittribut,'
            || ' sittributisentost,'
            || ' sittributnrpa,'
            || ' sittributpf,'
            || ' sittributtransf,'
            || ' sittributtransfent,'
            || ' tipocalculognre,'
            || ' tipocalculognretab,'
            || ' usapercbaseredassoc,'
            || ' usapercbasereddist,'
            || ' usapercbaseredfarma,'
            || ' usapercbaseredhosp,'
            || ' usapercbaseredmedico,'
            || ' usapercbaseredope,'
            || ' usapercbaseredopf,'
            || ' usapercbaseredopm,'
            || ' usaredbaseicmsfontest,'
            || ' usavalorultentbasest,'
            || ' utilizapercbaseredpf ) '
            || ' VALUES ( s.aliqicms1,'
            || ' s.aliqicms1fonte,'
            || ' s.aliqicms1tab,'
            || ' s.aliqicms1transf,'
            || ' s.aliqicms2,'
            || ' s.aliqicms2fonte,'
            || ' s.aliqicms2tab,'
            || ' s.aliqicms2transf,'
            || ' s.aliqiss,'
            || ' s.aliqstsaida,'
            || ' s.aliqstsaidapf,'
            || ' s.aplicaacrescpjisenta,'
            || ' s.calcbaseredicmstransf,'
            || ' s.calcbcicmsnf,'
            || ' s.calcsttransf,'
            || ' s.codecf,'
            || ' s.codfiscal,'
            || ' s.codfiscalbonific,'
            || ' s.codfiscalbonificinter,'
            || ' s.codfiscalbonificinternasc,'
            || ' s.codfiscaldevcli,'
            || ' s.codfiscaldevclibonific,'
            || ' s.codfiscaldevclibonificinter,'
            || ' s.codfiscaldevcliboninternasc,'
            || ' s.codfiscaldevcliinter,'
            || ' s.codfiscaldevcliinternasc,'
            || ' s.codfiscaldevcliproentinternasc,'
            || ' s.codfiscaldevcliprontaent,'
            || ' s.codfiscaldevcliprontaentinter,'
            || ' s.codfiscaldevisentost,'
            || ' s.codfiscaldevisentostinter,'
            || ' s.codfiscaldevisentostinternasc,'
            || ' s.codfiscaldevmercconsig,'
            || ' s.codfiscaldevmercconsiginter,'
            || ' s.codfiscaldevtransf,'
            || ' s.codfiscaldevtransfinter,'
            || ' s.codfiscalinter,'
            || ' s.codfiscalinternasc,'
            || ' s.codfiscalinternascpf,'
            || ' s.codfiscalinterpf,'
            || ' s.codfiscalisentost,'
            || ' s.codfiscalisentostinter,'
            || ' s.codfiscalisentostinternasc,'
            || ' s.codfiscalmercconsig,'
            || ' s.codfiscalmercconsiginter,'
            || ' s.codfiscalmercconsiginternasc,'
            || ' s.codfiscalpf,'
            || ' s.codfiscalprontaent,'
            || ' s.codfiscalprontaentinter,'
            || ' s.codfiscalprontaentinternasc,'
            || ' s.codfiscalsimpentfut,'
            || ' s.codfiscalsimpentfutinter,'
            || ' s.codfiscalsrestsr,'
            || ' s.codfiscalsrext,'
            || ' s.codfiscalsrinte,'
            || ' s.codfiscaltransf,'
            || ' s.codfiscaltransfent,'
            || ' s.codfiscaltransfentinter,'
            || ' s.codfiscaltransfinter,'
            || ' s.codfiscaltransfinternasc,'
            || ' s.codfiscaltroca,'
            || ' s.codfiscaltrocainter,'
            || ' s.codfiscaltrocainternasc,'
            || ' s.codfiscalvendaconsig,'
            || ' s.codfiscalvendaconsiginter,'
            || ' s.codfiscalvendaconsiginternasc,'
            || ' s.codfiscalvendaentfut,'
            || ' s.codfiscalvendaentfutinter,'
            || ' s.codfiscalvendaprontaent,'
            || ' s.codfiscalvendaprontaentinter,'
            || ' s.codfuncultalter,'
            || ' s.codicm,'
            || ' s.codicmantecipado,'
            || ' s.codicmconsumidor,'
            || ' s.codicmnrpa,'
            || ' s.codicmpf,'
            || ' s.codicmprodrural,'
            || ' s.codicmtab,'
            || ' s.codicmtabnrpa,'
            || ' s.codicmtabpf,'
            || ' s.codicmtransf,'
            || ' s.codst,'
            || ' s.descicmsreduzbaseicms,'
            || ' s.dtultalter,'
            || ' s.indicest,'
            || ' s.iva,'
            || ' s.ivafonte,'
            || ' s.ivatab,'
            || ' s.ivatransf,'
            || ' s.mensagem,'
            || ' s.mensagemnrpa,'
            || ' s.numseqatu,'
            || ' s.obs,'
            || ' s.obspf,'
            || ' s.obspf2,'
            || ' s.obstransf,'
            || ' s.obs2,'
            || ' s.pauta,'
            || ' s.pautatab,'
            || ' s.pautatransf,'
            || ' s.peracrescimonrpa,'
            || ' s.peracrescismopf,'
            || ' s.perbaserednrpa,'
            || ' s.perbaseredtransfent,'
            || ' s.percacrescbasepfest,'
            || ' s.percagregadorst,'
            || ' s.percbasecalcrepasse,'
            || ' s.percbasered,'
            || ' s.percbaseredadicional,'
            || ' s.percbaseredadicionalinter,'
            || ' s.percbaseredconsumidor,'
            || ' s.percbaseredst,'
            || ' s.percbaseredstfonte,'
            || ' s.percbaseredsttransf,'
            || ' s.percbaseredtranfsaid,'
            || ' s.percivamex,'
            || ' s.perdesccusto,'
            || ' s.perdescicmisencao,'
            || ' s.perdescpissuframa,'
            || ' s.perdescrepasse,'
            || ' s.perdescsuframa,'
            || ' s.perdestab,'
            || ' s.perpautaicms,'
            || ' s.perpautaicmsinter,'
            || ' s.sittribut,'
            || ' s.sittributisentost,'
            || ' s.sittributnrpa,'
            || ' s.sittributpf,'
            || ' s.sittributtransf,'
            || ' s.sittributtransfent,'
            || ' s.tipocalculognre,'
            || ' s.tipocalculognretab,'
            || ' s.usapercbaseredassoc,'
            || ' s.usapercbasereddist,'
            || ' s.usapercbaseredfarma,'
            || ' s.usapercbaseredhosp,'
            || ' s.usapercbaseredmedico,'
            || ' s.usapercbaseredope,'
            || ' s.usapercbaseredopf,'
            || ' s.usapercbaseredopm,'
            || ' s.usaredbaseicmsfontest,'
            || ' s.usavalorultentbasest,'
            || ' s.utilizapercbaseredpf )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pctribut;

   FUNCTION importar_pctriboutros (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pctriboutros';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (aliqicmfreteent NUMBER(4,2),'
         || ' aliqicmoutrasdesp NUMBER(4,2),'
         || ' aliqicmoutrasdespent NUMBER(4,2),'
         || ' aliqicmoutrasdesppf NUMBER(4,2),'
         || ' codfilialnf VARCHAR2(2),'
         || ' codfiscaldevoutrasdesp NUMBER(8,0),'
         || ' codfiscaldevoutrasdesppf NUMBER(8,0),'
         || ' codfiscalfrete NUMBER(6,0),'
         || ' codfiscalfreteent NUMBER(4,0),'
         || ' codfiscaloutrasdesp NUMBER(4,0),'
         || ' codfiscaloutrasdespent NUMBER(4,0),'
         || ' codfiscaloutrasdesppf NUMBER(4,0),'
         || ' perbaseredoutrasdesp NUMBER(8,4),'
         || ' percicmfrete NUMBER(4,2),'
         || ' percicmfretepf NUMBER(4,2),'
         || ' ufdestino VARCHAR2(2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codfilialnf = s.codfilialnf) AND (d.ufdestino = s.ufdestino)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET  d.aliqicmfreteent = s.aliqicmfreteent ,'
            || ' d.aliqicmoutrasdesp = s.aliqicmoutrasdesp ,'
            || ' d.aliqicmoutrasdespent = s.aliqicmoutrasdespent ,'
            || ' d.aliqicmoutrasdesppf = s.aliqicmoutrasdesppf ,'
            || ' d.codfiscaldevoutrasdesp = s.codfiscaldevoutrasdesp ,'
            || ' d.codfiscaldevoutrasdesppf = s.codfiscaldevoutrasdesppf ,'
            || ' d.codfiscalfrete = s.codfiscalfrete ,'
            || ' d.codfiscalfreteent = s.codfiscalfreteent ,'
            || ' d.codfiscaloutrasdesp = s.codfiscaloutrasdesp ,'
            || ' d.codfiscaloutrasdespent = s.codfiscaloutrasdespent ,'
            || ' d.codfiscaloutrasdesppf = s.codfiscaloutrasdesppf ,'
            || ' d.perbaseredoutrasdesp = s.perbaseredoutrasdesp ,'
            || ' d.percicmfrete = s.percicmfrete ,'
            || ' d.percicmfretepf = s.percicmfretepf'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (aliqicmfreteent,'
            || ' aliqicmoutrasdesp,'
            || ' aliqicmoutrasdespent,'
            || ' aliqicmoutrasdesppf,'
            || ' codfilialnf,'
            || ' codfiscaldevoutrasdesp,'
            || ' codfiscaldevoutrasdesppf,'
            || ' codfiscalfrete,'
            || ' codfiscalfreteent,'
            || ' codfiscaloutrasdesp,'
            || ' codfiscaloutrasdespent,'
            || ' codfiscaloutrasdesppf,'
            || ' perbaseredoutrasdesp,'
            || ' percicmfrete,'
            || ' percicmfretepf,'
            || ' ufdestino ) '
            || ' VALUES ( s.aliqicmfreteent,'
            || ' s.aliqicmoutrasdesp,'
            || ' s.aliqicmoutrasdespent,'
            || ' s.aliqicmoutrasdesppf,'
            || ' s.codfilialnf,'
            || ' s.codfiscaldevoutrasdesp,'
            || ' s.codfiscaldevoutrasdesppf,'
            || ' s.codfiscalfrete,'
            || ' s.codfiscalfreteent,'
            || ' s.codfiscaloutrasdesp,'
            || ' s.codfiscaloutrasdespent,'
            || ' s.codfiscaloutrasdesppf,'
            || ' s.perbaseredoutrasdesp,'
            || ' s.percicmfrete,'
            || ' s.percicmfretepf,'
            || ' s.ufdestino )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pctriboutros;

   FUNCTION importar_pcusuari (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcusuari';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (areaatuacao VARCHAR2(1),'
         || ' bairro VARCHAR2(15),'
         || ' bip VARCHAR2(20),'
         || ' bloqcomis VARCHAR2(1),'
         || ' bloqueio VARCHAR2(1),'
         || ' bloqvendatlmk VARCHAR2(1),'
         || ' ccorrente VARCHAR2(1),'
         || ' cep VARCHAR2(9),'
         || ' cgc VARCHAR2(20),'
         || ' ci VARCHAR2(20),'
         || ' cidade VARCHAR2(15),'
         || ' codcomocliente NUMBER(6,0),'
         || ' coddistrib VARCHAR2(4),'
         || ' codequipe NUMBER(4,0),'
         || ' codfilial VARCHAR2(2),'
         || ' codoperacao VARCHAR2(3),'
         || ' codsupervisor NUMBER(4,0),'
         || ' codusur NUMBER(4,0),'
         || ' conjuge VARCHAR2(40),'
         || ' cpf VARCHAR2(20),'
         || ' direnvioftp VARCHAR2(50),'
         || ' dirrecepcaoftp VARCHAR2(50),'
         || ' dtentregadoc DATE,'
         || ' dtexclusao DATE,'
         || ' dtinformatiza DATE,'
         || ' dtinicio DATE,'
         || ' dtlimentregadoc DATE,'
         || ' dtnasc DATE,'
         || ' dtnasconjuge DATE,'
         || ' dttermino DATE,'
         || ' dtultalteracao DATE,'
         || ' dtultpagconselho DATE,'
         || ' dtultvenda DATE,'
         || ' email VARCHAR2(100),'
         || ' email2 VARCHAR2(100),'
         || ' endereco VARCHAR2(40),'
         || ' endereco2 VARCHAR2(40),'
         || ' estado VARCHAR2(2),'
         || ' exportadados VARCHAR2(1),'
         || ' fax VARCHAR2(13),'
         || ' firma VARCHAR2(40),'
         || ' horafimconexaopalm NUMBER(2,0),'
         || ' horainiconexaopalm NUMBER(2,0),'
         || ' indicecpfechcomissao VARCHAR2(1),'
         || ' inscmunicipal VARCHAR2(15),'
         || ' inss NUMBER(12,0),'
         || ' maskpreposto VARCHAR2(8),'
         || ' mens1 VARCHAR2(60),'
         || ' mens2 VARCHAR2(60),'
         || ' mens3 VARCHAR2(60),'
         || ' mens4 VARCHAR2(60),'
         || ' minutofimconexaopalm NUMBER(2,0),'
         || ' minutoiniconexaopalm NUMBER(2,0),'
         || ' motivo VARCHAR2(40),'
         || ' nome VARCHAR2(40),'
         || ' numagencia NUMBER(4,0),'
         || ' numagenciapoup NUMBER(4,0),'
         || ' numbanco NUMBER(3,0),'
         || ' numbancopoup NUMBER(3,0),'
         || ' numccorrente NUMBER(10,0),'
         || ' numccorrentepoup NUMBER(10,0),'
         || ' numconselho VARCHAR2(20),'
         || ' numdep NUMBER(2,0),'
         || ' numdvagencia VARCHAR2(1),'
         || ' numdvagenciapoup VARCHAR2(1),'
         || ' numdvccorrente VARCHAR2(2),'
         || ' numdvccorrentepoup VARCHAR2(2),'
         || ' numpedecf NUMBER(10,0),'
         || ' numserieequip NUMBER(10,0),'
         || ' numserieequip2 VARCHAR2(15),'
         || ' obsbloq VARCHAR2(30),'
         || ' obs1 VARCHAR2(80),'
         || ' obs2 VARCHAR2(80),'
         || ' percacrescimovenda NUMBER(5,2),'
         || ' percacresfv NUMBER(8,2),'
         || ' percent NUMBER(4,2),'
         || ' percent2 NUMBER(6,2),'
         || ' percmetadepto NUMBER(10,2),'
         || ' perdescmax NUMBER(5,2),'
         || ' permeta NUMBER(10,2),'
         || ' permetametro NUMBER(10,2),'
         || ' permiteadiantcomissao VARCHAR2(1),'
         || ' praca1 VARCHAR2(80),'
         || ' praca2 VARCHAR2(80),'
         || ' proxcodclipalm NUMBER(6,0),'
         || ' proxnumped NUMBER(14,2),'
         || ' proxnumpedforca NUMBER(10,0),'
         || ' proxnumpedweb NUMBER(10,0),'
         || ' qtitenspedprev NUMBER(6,0),'
         || ' qtpedprev NUMBER(6,0),'
         || ' rotamasterfoods VARCHAR2(20),'
         || ' senha VARCHAR2(10),'
         || ' senhadialup VARCHAR2(12),'
         || ' senhaftp VARCHAR2(10),'
         || ' senhalogin VARCHAR2(10),'
         || ' senhapop VARCHAR2(10),'
         || ' servftp VARCHAR2(50),'
         || ' servpop VARCHAR2(30),'
         || ' servsmtp VARCHAR2(30),'
         || ' telefone1 VARCHAR2(13),'
         || ' telefone2 VARCHAR2(13),'
         || ' telprovedor VARCHAR2(15),'
         || ' tipocomissao VARCHAR2(1),'
         || ' tipofirma VARCHAR2(1),'
         || ' tipopessoa VARCHAR2(1),'
         || ' tipovend VARCHAR2(2),'
         || ' ultnumped NUMBER(10,0),'
         || ' usadebcredrca VARCHAR2(1),'
         || ' usurdialup VARCHAR2(40),'
         || ' usurdirfv VARCHAR2(50),'
         || ' usurftp VARCHAR2(40),'
         || ' usurlogin VARCHAR2(40),'
         || ' usurpop VARCHAR2(40),'
         || ' vendedorqk VARCHAR2(1),'
         || ' vlcorrente NUMBER(10,2),'
         || ' vllimcred NUMBER(10,2),'
         || ' vlvendaminped NUMBER(12,2),'
         || ' vlvendaprev NUMBER(12,2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''')) '
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codusur = s.codusur) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.areaatuacao = s.areaatuacao ,'
            || ' d.bairro = s.bairro ,'
            || ' d.bip = s.bip ,'
            || ' d.bloqcomis = s.bloqcomis ,'
            || ' d.bloqueio = s.bloqueio ,'
            || ' d.bloqvendatlmk = s.bloqvendatlmk ,'
            || ' d.ccorrente = s.ccorrente ,'
            || ' d.cep = s.cep ,'
            || ' d.cgc = s.cgc ,'
            || ' d.ci = s.ci ,'
            || ' d.cidade = s.cidade ,'
            || ' d.codcomocliente = s.codcomocliente ,'
            || ' d.coddistrib = s.coddistrib ,'
            || ' d.codequipe = s.codequipe ,'
            || ' d.codfilial = s.codfilial ,'
            || ' d.codoperacao = s.codoperacao ,'
            || ' d.codsupervisor = s.codsupervisor ,'
            || ' d.conjuge = s.conjuge ,'
            || ' d.cpf = s.cpf ,'
            || ' d.direnvioftp = s.direnvioftp ,'
            || ' d.dirrecepcaoftp = s.dirrecepcaoftp ,'
            || ' d.dtentregadoc = s.dtentregadoc ,'
            || ' d.dtexclusao = s.dtexclusao ,'
            || ' d.dtinformatiza = s.dtinformatiza ,'
            || ' d.dtinicio = s.dtinicio ,'
            || ' d.dtlimentregadoc = s.dtlimentregadoc ,'
            || ' d.dtnasc = s.dtnasc ,'
            || ' d.dtnasconjuge = s.dtnasconjuge ,'
            || ' d.dttermino = s.dttermino ,'
            || ' d.dtultalteracao = s.dtultalteracao ,'
            || ' d.dtultpagconselho = s.dtultpagconselho ,'
            || ' d.dtultvenda = s.dtultvenda ,'
            || ' d.email = s.email ,'
            || ' d.email2 = s.email2 ,'
            || ' d.endereco = s.endereco ,'
            || ' d.endereco2 = s.endereco2 ,'
            || ' d.estado = s.estado ,'
            || ' d.exportadados = s.exportadados ,'
            || ' d.fax = s.fax ,'
            || ' d.firma = s.firma ,'
            || ' d.horafimconexaopalm = s.horafimconexaopalm ,'
            || ' d.horainiconexaopalm = s.horainiconexaopalm ,'
            || ' d.indicecpfechcomissao = s.indicecpfechcomissao ,'
            || ' d.inscmunicipal = s.inscmunicipal ,'
            || ' d.inss = s.inss ,'
            || ' d.maskpreposto = s.maskpreposto ,'
            || ' d.mens1 = s.mens1 ,'
            || ' d.mens2 = s.mens2 ,'
            || ' d.mens3 = s.mens3 ,'
            || ' d.mens4 = s.mens4 ,'
            || ' d.minutofimconexaopalm = s.minutofimconexaopalm ,'
            || ' d.minutoiniconexaopalm = s.minutoiniconexaopalm ,'
            || ' d.motivo = s.motivo ,'
            || ' d.nome = s.nome ,'
            || ' d.numagencia = s.numagencia ,'
            || ' d.numagenciapoup = s.numagenciapoup ,'
            || ' d.numbanco = s.numbanco ,'
            || ' d.numbancopoup = s.numbancopoup ,'
            || ' d.numccorrente = s.numccorrente ,'
            || ' d.numccorrentepoup = s.numccorrentepoup ,'
            || ' d.numconselho = s.numconselho ,'
            || ' d.numdep = s.numdep ,'
            || ' d.numdvagencia = s.numdvagencia ,'
            || ' d.numdvagenciapoup = s.numdvagenciapoup ,'
            || ' d.numdvccorrente = s.numdvccorrente ,'
            || ' d.numdvccorrentepoup = s.numdvccorrentepoup ,'
            || ' d.numpedecf = s.numpedecf ,'
            || ' d.numserieequip = s.numserieequip ,'
            || ' d.numserieequip2 = s.numserieequip2 ,'
            || ' d.obsbloq = s.obsbloq ,'
            || ' d.obs1 = s.obs1 ,'
            || ' d.obs2 = s.obs2 ,'
            || ' d.percacrescimovenda = s.percacrescimovenda ,'
            || ' d.percacresfv = s.percacresfv ,'
            || ' d.percent = s.percent ,'
            || ' d.percent2 = s.percent2 ,'
            || ' d.percmetadepto = s.percmetadepto ,'
            || ' d.perdescmax = s.perdescmax ,'
            || ' d.permeta = s.permeta ,'
            || ' d.permetametro = s.permetametro ,'
            || ' d.permiteadiantcomissao = s.permiteadiantcomissao ,'
            || ' d.praca1 = s.praca1 ,'
            || ' d.praca2 = s.praca2 ,'
            || ' d.proxcodclipalm = s.proxcodclipalm ,'
            || ' d.proxnumped = greatest(d.proxnumped, s.proxnumped),'
            || ' d.proxnumpedforca = s.proxnumpedforca ,'
            || ' d.proxnumpedweb = s.proxnumpedweb ,'
            || ' d.qtitenspedprev = s.qtitenspedprev ,'
            || ' d.qtpedprev = s.qtpedprev ,'
            || ' d.rotamasterfoods = s.rotamasterfoods ,'
            || ' d.senha = s.senha ,'
            || ' d.senhadialup = s.senhadialup ,'
            || ' d.senhaftp = s.senhaftp ,'
            || ' d.senhalogin = s.senhalogin ,'
            || ' d.senhapop = s.senhapop ,'
            || ' d.servftp = s.servftp ,'
            || ' d.servpop = s.servpop ,'
            || ' d.servsmtp = s.servsmtp ,'
            || ' d.telefone1 = s.telefone1 ,'
            || ' d.telefone2 = s.telefone2 ,'
            || ' d.telprovedor = s.telprovedor ,'
            || ' d.tipocomissao = s.tipocomissao ,'
            || ' d.tipofirma = s.tipofirma ,'
            || ' d.tipopessoa = s.tipopessoa ,'
            || ' d.tipovend = s.tipovend ,'
            || ' d.ultnumped = s.ultnumped ,'
            || ' d.usadebcredrca = s.usadebcredrca ,'
            || ' d.usurdialup = s.usurdialup ,'
            || ' d.usurdirfv = s.usurdirfv ,'
            || ' d.usurftp = s.usurftp ,'
            || ' d.usurlogin = s.usurlogin ,'
            || ' d.usurpop = s.usurpop ,'
            || ' d.vendedorqk = s.vendedorqk ,'
            || ' d.vlcorrente = s.vlcorrente ,'
            || ' d.vllimcred = s.vllimcred ,'
            || ' d.vlvendaminped = s.vlvendaminped ,'
            || ' d.vlvendaprev = s.vlvendaprev '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (areaatuacao,'
            || ' bairro,'
            || ' bip,'
            || ' bloqcomis,'
            || ' bloqueio,'
            || ' bloqvendatlmk,'
            || ' ccorrente,'
            || ' cep,'
            || ' cgc,'
            || ' ci,'
            || ' cidade,'
            || ' codcomocliente,'
            || ' coddistrib,'
            || ' codequipe,'
            || ' codfilial,'
            || ' codoperacao,'
            || ' codsupervisor,'
            || ' codusur,'
            || ' conjuge,'
            || ' cpf,'
            || ' direnvioftp,'
            || ' dirrecepcaoftp,'
            || ' dtentregadoc,'
            || ' dtexclusao,'
            || ' dtinformatiza,'
            || ' dtinicio,'
            || ' dtlimentregadoc,'
            || ' dtnasc,'
            || ' dtnasconjuge,'
            || ' dttermino,'
            || ' dtultalteracao,'
            || ' dtultpagconselho,'
            || ' dtultvenda,'
            || ' email,'
            || ' email2,'
            || ' endereco,'
            || ' endereco2,'
            || ' estado,'
            || ' exportadados,'
            || ' fax,'
            || ' firma,'
            || ' horafimconexaopalm,'
            || ' horainiconexaopalm,'
            || ' indicecpfechcomissao,'
            || ' inscmunicipal,'
            || ' inss,'
            || ' maskpreposto,'
            || ' mens1,'
            || ' mens2,'
            || ' mens3,'
            || ' mens4,'
            || ' minutofimconexaopalm,'
            || ' minutoiniconexaopalm,'
            || ' motivo,'
            || ' nome,'
            || ' numagencia,'
            || ' numagenciapoup,'
            || ' numbanco,'
            || ' numbancopoup,'
            || ' numccorrente,'
            || ' numccorrentepoup,'
            || ' numconselho,'
            || ' numdep,'
            || ' numdvagencia,'
            || ' numdvagenciapoup,'
            || ' numdvccorrente,'
            || ' numdvccorrentepoup,'
            || ' numpedecf,'
            || ' numserieequip,'
            || ' numserieequip2,'
            || ' obsbloq,'
            || ' obs1,'
            || ' obs2,'
            || ' percacrescimovenda,'
            || ' percacresfv,'
            || ' percent,'
            || ' percent2,'
            || ' percmetadepto,'
            || ' perdescmax,'
            || ' permeta,'
            || ' permetametro,'
            || ' permiteadiantcomissao,'
            || ' praca1,'
            || ' praca2,'
            || ' proxcodclipalm,'
            || ' proxnumped,'
            || ' proxnumpedforca,'
            || ' proxnumpedweb,'
            || ' qtitenspedprev,'
            || ' qtpedprev,'
            || ' rotamasterfoods,'
            || ' senha,'
            || ' senhadialup,'
            || ' senhaftp,'
            || ' senhalogin,'
            || ' senhapop,'
            || ' servftp,'
            || ' servpop,'
            || ' servsmtp,'
            || ' telefone1,'
            || ' telefone2,'
            || ' telprovedor,'
            || ' tipocomissao,'
            || ' tipofirma,'
            || ' tipopessoa,'
            || ' tipovend,'
            || ' ultnumped,'
            || ' usadebcredrca,'
            || ' usurdialup,'
            || ' usurdirfv,'
            || ' usurftp,'
            || ' usurlogin,'
            || ' usurpop,'
            || ' vendedorqk,'
            || ' vlcorrente,'
            || ' vllimcred,'
            || ' vlvendaminped,'
            || ' vlvendaprev ) '
            || ' VALUES ( s.areaatuacao,'
            || ' s.bairro,'
            || ' s.bip,'
            || ' s.bloqcomis,'
            || ' s.bloqueio,'
            || ' s.bloqvendatlmk,'
            || ' s.ccorrente,'
            || ' s.cep,'
            || ' s.cgc,'
            || ' s.ci,'
            || ' s.cidade,'
            || ' s.codcomocliente,'
            || ' s.coddistrib,'
            || ' s.codequipe,'
            || ' s.codfilial,'
            || ' s.codoperacao,'
            || ' s.codsupervisor,'
            || ' s.codusur,'
            || ' s.conjuge,'
            || ' s.cpf,'
            || ' s.direnvioftp,'
            || ' s.dirrecepcaoftp,'
            || ' s.dtentregadoc,'
            || ' s.dtexclusao,'
            || ' s.dtinformatiza,'
            || ' s.dtinicio,'
            || ' s.dtlimentregadoc,'
            || ' s.dtnasc,'
            || ' s.dtnasconjuge,'
            || ' s.dttermino,'
            || ' s.dtultalteracao,'
            || ' s.dtultpagconselho,'
            || ' s.dtultvenda,'
            || ' s.email,'
            || ' s.email2,'
            || ' s.endereco,'
            || ' s.endereco2,'
            || ' s.estado,'
            || ' s.exportadados,'
            || ' s.fax,'
            || ' s.firma,'
            || ' s.horafimconexaopalm,'
            || ' s.horainiconexaopalm,'
            || ' s.indicecpfechcomissao,'
            || ' s.inscmunicipal,'
            || ' s.inss,'
            || ' s.maskpreposto,'
            || ' s.mens1,'
            || ' s.mens2,'
            || ' s.mens3,'
            || ' s.mens4,'
            || ' s.minutofimconexaopalm,'
            || ' s.minutoiniconexaopalm,'
            || ' s.motivo,'
            || ' s.nome,'
            || ' s.numagencia,'
            || ' s.numagenciapoup,'
            || ' s.numbanco,'
            || ' s.numbancopoup,'
            || ' s.numccorrente,'
            || ' s.numccorrentepoup,'
            || ' s.numconselho,'
            || ' s.numdep,'
            || ' s.numdvagencia,'
            || ' s.numdvagenciapoup,'
            || ' s.numdvccorrente,'
            || ' s.numdvccorrentepoup,'
            || ' s.numpedecf,'
            || ' s.numserieequip,'
            || ' s.numserieequip2,'
            || ' s.obsbloq,'
            || ' s.obs1,'
            || ' s.obs2,'
            || ' s.percacrescimovenda,'
            || ' s.percacresfv,'
            || ' s.percent,'
            || ' s.percent2,'
            || ' s.percmetadepto,'
            || ' s.perdescmax,'
            || ' s.permeta,'
            || ' s.permetametro,'
            || ' s.permiteadiantcomissao,'
            || ' s.praca1,'
            || ' s.praca2,'
            || ' s.proxcodclipalm,'
            || ' s.proxnumped,'
            || ' s.proxnumpedforca,'
            || ' s.proxnumpedweb,'
            || ' s.qtitenspedprev,'
            || ' s.qtpedprev,'
            || ' s.rotamasterfoods,'
            || ' s.senha,'
            || ' s.senhadialup,'
            || ' s.senhaftp,'
            || ' s.senhalogin,'
            || ' s.senhapop,'
            || ' s.servftp,'
            || ' s.servpop,'
            || ' s.servsmtp,'
            || ' s.telefone1,'
            || ' s.telefone2,'
            || ' s.telprovedor,'
            || ' s.tipocomissao,'
            || ' s.tipofirma,'
            || ' s.tipopessoa,'
            || ' s.tipovend,'
            || ' s.ultnumped,'
            || ' s.usadebcredrca,'
            || ' s.usurdialup,'
            || ' s.usurdirfv,'
            || ' s.usurftp,'
            || ' s.usurlogin,'
            || ' s.usurpop,'
            || ' s.vendedorqk,'
            || ' s.vlcorrente,'
            || ' s.vllimcred,'
            || ' s.vlvendaminped,'
            || ' s.vlvendaprev )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcusuari;

   FUNCTION importar_pcsuperv (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcsuperv';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( cod_cadrca NUMBER(4,0),'
         || ' codgerente NUMBER(4,0),'
         || ' codsupervisor NUMBER(4,0),'
         || ' cpf VARCHAR2(20),'
         || ' dtadmissao DATE,'
         || ' dtdemissao DATE,'
         || ' nome VARCHAR2(40),'
         || ' percmargemprev NUMBER(8,4),'
         || ' percomissao NUMBER(4,2),'
         || ' percpartvendaprev NUMBER(8,4),'
         || ' posicao VARCHAR2(1),'
         || ' regional NUMBER(2,0),'
         || ' tiposupervisor VARCHAR2(1) ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''')) '
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codsupervisor = s.codsupervisor) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.cod_cadrca = s.cod_cadrca ,'
            || ' d.codgerente = s.codgerente ,'
            || ' d.cpf = s.cpf ,'
            || ' d.dtadmissao = s.dtadmissao ,'
            || ' d.dtdemissao = s.dtdemissao ,'
            || ' d.nome = s.nome ,'
            || ' d.percmargemprev = s.percmargemprev ,'
            || ' d.percomissao = s.percomissao ,'
            || ' d.percpartvendaprev = s.percpartvendaprev ,'
            || ' d.posicao = s.posicao ,'
            || ' d.regional = s.regional ,'
            || ' d.tiposupervisor = s.tiposupervisor '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT ( cod_cadrca,'
            || ' codgerente,'
            || ' codsupervisor,'
            || ' cpf,'
            || ' dtadmissao,'
            || ' dtdemissao,'
            || ' nome,'
            || ' percmargemprev,'
            || ' percomissao,'
            || ' percpartvendaprev,'
            || ' posicao,'
            || ' regional,'
            || ' tiposupervisor ) '
            || ' VALUES ( s.cod_cadrca,'
            || ' s.codgerente,'
            || ' s.codsupervisor,'
            || ' s.cpf,'
            || ' s.dtadmissao,'
            || ' s.dtdemissao,'
            || ' s.nome,'
            || ' s.percmargemprev,'
            || ' s.percomissao,'
            || ' s.percpartvendaprev,'
            || ' s.posicao,'
            || ' s.regional,'
            || ' s.tiposupervisor )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcsuperv;

   FUNCTION importar_pcest (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcest';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codfilial varchar2(2),'
         || '  codprod number(6,0),'
         || '  qtest number(22,8),'
         || '  estmin number(16,3),'
         || '  dtultent date,'
         || '  dtultsaida date,'
         || '  qtvendmes number(16,3),'
         || '  qtvendmes1 number(16,3),'
         || '  qtvendmes2 number(16,3),'
         || '  qtvendmes3 number(16,3),'
         || '  qtperdadia number(16,3),'
         || '  qtperdames number(16,3),'
         || '  vlvendmes number(12,2),'
         || '  qtvenddia number(16,3),'
         || '  vlvenddia number(12,2),'
         || '  qtpedida number(16,3),'
         || '  vlcustodiareal number(12,2),'
         || '  vlcustomesreal number(12,2),'
         || '  vlcustodiafin number(12,2),'
         || '  vlcustomesfin number(12,2),'
         || '  qtestant number(16,3),'
         || '  pcustoant number(18,6),'
         || '  qtreserv number(22,8),'
         || '  qtultent number(16,3),'
         || '  custoultent number(18,6),'
         || '  qtestger number(22,8),'
         || '  qtentdia number(16,3),'
         || '  qtentmes number(16,3),'
         || '  vlvenddiareal number(12,2),'
         || '  vlvendmesreal number(12,2),'
         || '  custocont number(18,6),'
         || '  qtbloqueada number(20,6),'
         || '  fimestoque varchar2(1),'
         || '  qtindeniz number(20,6),'
         || '  qtultinvent number(16,3),'
         || '  qtvendaperdida number(16,3),'
         || '  custoreal number(18,6),'
         || '  custofin number(18,6),'
         || '  custorep number(18,6),'
         || '  valorultent number(18,6),'
         || '  qtbloqtransf number(16,3),'
         || '  qtpendente number(16,3),'
         || '  qtvendsemana number(16,3),'
         || '  qtvendsemana1 number(16,3),'
         || '  qtvendsemana2 number(16,3),'
         || '  qtvendsemana3 number(16,3),'
         || '  qtgirodia number(16,3),'
         || '  percevolucaovenda number(12,4),'
         || '  vlvendmesant number(14,2),'
         || '  vlcustomesfinant number(14,2),'
         || '  vlcustomesrealant number(14,2),'
         || '  numnotaultent number(10,0),'
         || '  pcompraultent number(18,6),'
         || '  vlstultent number(18,6),'
         || '  modulo number(2,0),'
         || '  rua number(4,0),'
         || '  numero number(6,2),'
         || '  apto number(2,0),'
         || '  dtultinvent date,'
         || '  custodolar number(18,6),'
         || '  custoultentmed number(18,6),'
         || '  valorultentmed number(18,6),'
         || '  qtreservmed number(16,3),'
         || '  qtrequisicao number(16,3),'
         || '  custorealsemst number(18,6),'
         || '  dtultpedcompra date,'
         || '  custoultpedcompra number(18,6),'
         || '  custoultentfin number(18,6),'
         || '  dtultdesdobra date,'
         || '  corredor number(4,0),'
         || '  qtloja number(20,8),'
         || '  basebcr number(18,6),'
         || '  stbcr number(18,6),'
         || '  custoproximacompra number(18,6),'
         || '  numtransentultent number(10,0),'
         || '  custoultentant number(18,6),'
         || '  motivobloqestoque varchar2(80),'
         || '  coddevol number(4,0),'
         || '  qtdevolmes number(16,3),'
         || '  qtdevolmes1 number(16,3),'
         || '  qtdevolmes2 number(16,3),'
         || '  qtdevolmes3 number(16,3),'
         || '  estmax number(16,3))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codfilial = s.codfilial) and'
            || '     (d.codprod = s.codprod)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.qtest = s.qtest,'
            || '     d.estmin = s.estmin,'
            || '     d.dtultent = s.dtultent,'
            || '     d.dtultsaida = s.dtultsaida,'
            || '     d.qtvendmes = s.qtvendmes,'
            || '     d.qtvendmes1 = s.qtvendmes1,'
            || '     d.qtvendmes2 = s.qtvendmes2,'
            || '     d.qtvendmes3 = s.qtvendmes3,'
            || '     d.qtperdadia = s.qtperdadia,'
            || '     d.qtperdames = s.qtperdames,'
            || '     d.vlvendmes = s.vlvendmes,'
            || '     d.qtvenddia = s.qtvenddia,'
            || '     d.vlvenddia = s.vlvenddia,'
            || '     d.qtpedida = s.qtpedida,'
            || '     d.vlcustodiareal = s.vlcustodiareal,'
            || '     d.vlcustomesreal = s.vlcustomesreal,'
            || '     d.vlcustodiafin = s.vlcustodiafin,'
            || '     d.vlcustomesfin = s.vlcustomesfin,'
            || '     d.qtestant = s.qtestant,'
            || '     d.pcustoant = s.pcustoant,'
            || '     d.qtreserv = s.qtreserv,'
            || '     d.qtultent = s.qtultent,'
            || '     d.custoultent = s.custoultent,'
            || '     d.qtestger = s.qtestger,'
            || '     d.qtentdia = s.qtentdia,'
            || '     d.qtentmes = s.qtentmes,'
            || '     d.vlvenddiareal = s.vlvenddiareal,'
            || '     d.vlvendmesreal = s.vlvendmesreal,'
            || '     d.custocont = s.custocont,'
            || '     d.qtbloqueada = s.qtbloqueada,'
            || '     d.fimestoque = s.fimestoque,'
            || '     d.qtindeniz = s.qtindeniz,'
            || '     d.qtultinvent = s.qtultinvent,'
            || '     d.qtvendaperdida = s.qtvendaperdida,'
            || '     d.custoreal = s.custoreal,'
            || '     d.custofin = s.custofin,'
            || '     d.custorep = s.custorep,'
            || '     d.valorultent = s.valorultent,'
            || '     d.qtbloqtransf = s.qtbloqtransf,'
            || '     d.qtpendente = s.qtpendente,'
            || '     d.qtvendsemana = s.qtvendsemana,'
            || '     d.qtvendsemana1 = s.qtvendsemana1,'
            || '     d.qtvendsemana2 = s.qtvendsemana2,'
            || '     d.qtvendsemana3 = s.qtvendsemana3,'
            || '     d.qtgirodia = s.qtgirodia,'
            || '     d.percevolucaovenda = s.percevolucaovenda,'
            || '     d.vlvendmesant = s.vlvendmesant,'
            || '     d.vlcustomesfinant = s.vlcustomesfinant,'
            || '     d.vlcustomesrealant = s.vlcustomesrealant,'
            || '     d.numnotaultent = s.numnotaultent,'
            || '     d.pcompraultent = s.pcompraultent,'
            || '     d.vlstultent = s.vlstultent,'
            || '     d.modulo = s.modulo,'
            || '     d.rua = s.rua,'
            || '     d.numero = s.numero,'
            || '     d.apto = s.apto,'
            || '     d.dtultinvent = s.dtultinvent,'
            || '     d.custodolar = s.custodolar,'
            || '     d.custoultentmed = s.custoultentmed,'
            || '     d.valorultentmed = s.valorultentmed,'
            || '     d.qtreservmed = s.qtreservmed,'
            || '     d.qtrequisicao = s.qtrequisicao,'
            || '     d.custorealsemst = s.custorealsemst,'
            || '     d.dtultpedcompra = s.dtultpedcompra,'
            || '     d.custoultpedcompra = s.custoultpedcompra,'
            || '     d.custoultentfin = s.custoultentfin,'
            || '     d.dtultdesdobra = s.dtultdesdobra,'
            || '     d.corredor = s.corredor,'
            || '     d.qtloja = s.qtloja,'
            || '     d.basebcr = s.basebcr,'
            || '     d.stbcr = s.stbcr,'
            || '     d.custoproximacompra = s.custoproximacompra,'
            || '     d.numtransentultent = s.numtransentultent,'
            || '     d.custoultentant = s.custoultentant,'
            || '     d.motivobloqestoque = s.motivobloqestoque,'
            || '     d.coddevol = s.coddevol,'
            || '     d.qtdevolmes = s.qtdevolmes,'
            || '     d.qtdevolmes1 = s.qtdevolmes1,'
            || '     d.qtdevolmes2 = s.qtdevolmes2,'
            || '     d.qtdevolmes3 = s.qtdevolmes3,'
            || '     d.estmax = s.estmax'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codfilial, codprod, qtest, estmin, dtultent, dtultsaida, qtvendmes, qtvendmes1, qtvendmes2,'
            || '         qtvendmes3, qtperdadia, qtperdames, vlvendmes, qtvenddia, vlvenddia, qtpedida, vlcustodiareal,'
            || '         vlcustomesreal, vlcustodiafin, vlcustomesfin, qtestant, pcustoant, qtreserv, qtultent,'
            || '         custoultent, qtestger, qtentdia, qtentmes, vlvenddiareal, vlvendmesreal, custocont,'
            || '         qtbloqueada, fimestoque, qtindeniz, qtultinvent, qtvendaperdida, custoreal, custofin,'
            || '         custorep, valorultent, qtbloqtransf, qtpendente, qtvendsemana, qtvendsemana1, qtvendsemana2,'
            || '         qtvendsemana3, qtgirodia, percevolucaovenda, vlvendmesant, vlcustomesfinant, vlcustomesrealant,'
            || '         numnotaultent, pcompraultent, vlstultent, modulo, rua, numero, apto, dtultinvent, custodolar,'
            || '         custoultentmed, valorultentmed, qtreservmed, qtrequisicao, custorealsemst, dtultpedcompra,'
            || '         custoultpedcompra, custoultentfin, dtultdesdobra, corredor, qtloja, basebcr, stbcr,'
            || '         custoproximacompra, numtransentultent, custoultentant, motivobloqestoque, coddevol,'
            || '         qtdevolmes, qtdevolmes1, qtdevolmes2, qtdevolmes3, estmax) '
            || ' VALUES (s.codfilial, s.codprod, s.qtest, s.estmin, s.dtultent, s.dtultsaida, s.qtvendmes,'
            || '         s.qtvendmes1, s.qtvendmes2, s.qtvendmes3, s.qtperdadia, s.qtperdames, s.vlvendmes,'
            || '         s.qtvenddia, s.vlvenddia, s.qtpedida, s.vlcustodiareal, s.vlcustomesreal, s.vlcustodiafin,'
            || '         s.vlcustomesfin, s.qtestant, s.pcustoant, s.qtreserv, s.qtultent, s.custoultent,'
            || '         s.qtestger, s.qtentdia, s.qtentmes, s.vlvenddiareal, s.vlvendmesreal, s.custocont,'
            || '         s.qtbloqueada, s.fimestoque, s.qtindeniz, s.qtultinvent, s.qtvendaperdida, s.custoreal,'
            || '         s.custofin, s.custorep, s.valorultent, s.qtbloqtransf, s.qtpendente, s.qtvendsemana,'
            || '         s.qtvendsemana1, s.qtvendsemana2, s.qtvendsemana3, s.qtgirodia, s.percevolucaovenda,'
            || '         s.vlvendmesant, s.vlcustomesfinant, s.vlcustomesrealant, s.numnotaultent, s.pcompraultent,'
            || '         s.vlstultent, s.modulo, s.rua, s.numero, s.apto, s.dtultinvent, s.custodolar, s.custoultentmed,'
            || '         s.valorultentmed, s.qtreservmed, s.qtrequisicao, s.custorealsemst, s.dtultpedcompra,'
            || '         s.custoultpedcompra, s.custoultentfin, s.dtultdesdobra, s.corredor, s.qtloja, s.basebcr,'
            || '         s.stbcr, s.custoproximacompra, s.numtransentultent, s.custoultentant, s.motivobloqestoque,'
            || '         s.coddevol, s.qtdevolmes, s.qtdevolmes1, s.qtdevolmes2, s.qtdevolmes3, s.estmax)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcest;

   FUNCTION importar_pcformprod (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcformprod';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codprodacab number(6,0),'
         || '  codprodmp number(6,0),'
         || '  qtprodacab number(12,6),'
         || '  qtprodmp number(12,6),'
         || '  codoper varchar2(1),'
         || '  aceitafracao varchar2(1),'
         || '  baixaestoque varchar2(1),'
         || '  codfilial varchar2(2),'
         || '  qtrenda number(12,6),'
         || '  custoproduto number(12,6),'
         || '  custokg number(12,6),'
         || '  customp number(12,6),'
         || '  qtdempporkg number(12,6),'
         || '  custoporkg number(12,6),'
         || '  qtmpbaixar number(12,6),'
         || '  qtproducao number(12,6),'
         || '  vlcustomontagem number(10,6),'
         || '  geraetiqueta varchar2(1))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codprodacab = s.codprodacab and'
            || '     d.codprodmp = s.codprodmp) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.codoper = s.codoper,'
            || '     d.aceitafracao = s.aceitafracao,'
            || '     d.baixaestoque = s.baixaestoque,'
            || '     d.codfilial = s.codfilial,'
            || '     d.qtrenda = s.qtrenda,'
            || '     d.custoproduto = s.custoproduto,'
            || '     d.custokg = s.custokg,'
            || '     d.customp = s.customp,'
            || '     d.qtdempporkg = s.qtdempporkg,'
            || '     d.custoporkg = s.custoporkg,'
            || '     d.qtmpbaixar = s.qtmpbaixar,'
            || '     d.qtproducao = s.qtproducao,'
            || '     d.vlcustomontagem = s.vlcustomontagem,'
            || '     d.geraetiqueta = s.geraetiqueta'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codprodacab, codprodmp, qtprodacab, qtprodmp, codoper, aceitafracao, baixaestoque, codfilial,'
            || '         qtrenda, custoproduto, custokg, customp, qtdempporkg, custoporkg, qtmpbaixar, qtproducao,'
            || '         vlcustomontagem, geraetiqueta) '
            || ' VALUES (s.codprodacab, s.codprodmp, s.qtprodacab, s.qtprodmp, s.codoper, s.aceitafracao,'
            || '         s.baixaestoque, s.codfilial, s.qtrenda, s.custoproduto, s.custokg, s.customp,'
            || '         s.qtdempporkg, s.custoporkg, s.qtmpbaixar, s.qtproducao, s.vlcustomontagem,'
            || '         s.geraetiqueta)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcformprod;

   FUNCTION importar_pclib (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pclib';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( codfunc NUMBER(8,0),'
         || ' codfunc_lib NUMBER(8,0),'
         || ' codigoa VARCHAR2(10),'
         || ' codigon NUMBER(10,0),'
         || ' codtabela NUMBER(4,0),'
         || ' data_lib DATE ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ( (d.codfunc = s.codfunc)'
            || '  AND (d.codtabela = s.codtabela)'
            || '  AND (d.codigoa = s.codigoa)'
            || '  AND (d.codigon = s.codigon)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.codfunc_lib = s.codfunc_lib ,'
            || ' d.data_lib = s.data_lib '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT ( codfunc,'
            || ' codfunc_lib,'
            || ' codigoa,'
            || ' codigon,'
            || ' codtabela,'
            || ' data_lib ) '
            || ' VALUES ( s.codfunc,'
            || ' s.codfunc_lib,'
            || ' s.codigoa,'
            || ' s.codigon,'
            || ' s.codtabela,'
            || ' s.data_lib )';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pclib;

   FUNCTION importar_pcmodulo (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcmodulo';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (autmenu NUMBER(10,0),'
         || ' codmodulo NUMBER(4,0),'
         || ' dtultversao DATE,'
         || ' exibirmenu VARCHAR2(1),'
         || ' modulo VARCHAR2(40),'
         || ' numversao NUMBER(4,2)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codmodulo = s.codmodulo) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.autmenu = s.autmenu ,'
            || ' d.dtultversao = s.dtultversao ,'
            || ' d.exibirmenu = s.exibirmenu ,'
            || ' d.modulo = s.modulo ,'
            || ' d.numversao = s.numversao '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (autmenu,'
            || ' codmodulo,'
            || ' dtultversao,'
            || ' exibirmenu,'
            || ' modulo,'
            || ' numversao) '
            || ' VALUES (s.autmenu,'
            || ' s.codmodulo,'
            || ' s.dtultversao,'
            || ' s.exibirmenu,'
            || ' s.modulo,'
            || ' s.numversao)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcmodulo;

   FUNCTION importar_pcmoeda (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcmoeda';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' ( codmoeda VARCHAR2(4),'
         || ' moeda VARCHAR2(40) ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codmoeda = s.codmoeda) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.moeda = s.moeda'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codmoeda, moeda) '
            || ' VALUES (s.codmoeda, s.moeda)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcmoeda;

   FUNCTION importar_pcocorbc (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcocorbc';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (baixa VARCHAR2(1),'
         || ' codocorrencia VARCHAR2(2),'
         || ' numbanco NUMBER(4,0),'
         || ' ocorcartorio VARCHAR2(1),'
         || ' ocorrencia VARCHAR2(100),'
         || ' tarifa NUMBER(16,3)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.numbanco = s.numbanco) AND (d.codocorrencia = s.codocorrencia)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.baixa = s.baixa ,'
            || ' d.ocorcartorio = s.ocorcartorio ,'
            || ' d.ocorrencia = s.ocorrencia ,'
            || ' d.tarifa = s.tarifa'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (baixa,'
            || ' codocorrencia,'
            || ' numbanco,'
            || ' ocorcartorio,'
            || ' ocorrencia,'
            || ' tarifa) '
            || ' VALUES (s.baixa,'
            || ' s.codocorrencia,'
            || ' s.numbanco,'
            || ' s.ocorcartorio,'
            || ' s.ocorrencia,'
            || ' s.tarifa)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcocorbc;

   FUNCTION importar_pcplpag (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcplpag';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codplpag number(4,0),'
         || '  descricao varchar2(20),'
         || '  numdias number(4,0),'
         || '  tipoprazo varchar2(1),'
         || '  prazo1 number(4,0),'
         || '  prazo2 number(4,0),'
         || '  prazo3 number(4,0),'
         || '  dtvenc1 date,'
         || '  dtvenc2 date,'
         || '  dtvenc3 date,'
         || '  numpr number(6,2),'
         || '  tipovenda varchar2(2),'
         || '  pertxfim number(8,4),'
         || '  obs varchar2(2),'
         || '  oferta varchar2(1),'
         || '  prazo4 number(4,0),'
         || '  prazo5 number(4,0),'
         || '  prazo6 number(4,0),'
         || '  prazo7 number(4,0),'
         || '  prazo8 number(4,0),'
         || '  prazo9 number(4,0),'
         || '  prazo10 number(4,0),'
         || '  prazo11 number(4,0),'
         || '  prazo12 number(4,0),'
         || '  vendabk varchar2(1),'
         || '  vlminpedido number(12,2),'
         || '  codcob varchar2(4),'
         || '  tipoentrada number(1,0),'
         || '  letraplpag varchar2(2),'
         || '  margemmin number(5,2),'
         || '  numitensminimo number(4,0),'
         || '  obsplpag varchar2(100),'
         || '  pertxfimpalm number(8,4),'
         || '  codequipe number(4,0),'
         || '  tiporestricao varchar2(2),'
         || '  codrestricao number(8,0),'
         || '  codplpagkraft varchar2(3),'
         || '  enviaplanofv varchar2(1),'
         || '  prazoponderado varchar2(1),'
         || '  usaplpagautoservico varchar2(1),'
         || '  usadesclinhaprod varchar2(1),'
         || '  entrada varchar2(1),'
         || '  formaparcelamento varchar2(1),'
         || '  numparcelas number(2,0),'
         || '  numdiascarencia number(4,0),'
         || '  numdiascartao number(4,0),'
         || '  codfilial varchar2(2))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codplpag = s.codplpag) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.descricao = s.descricao,'
            || '     d.numdias = s.numdias,'
            || '     d.tipoprazo = s.tipoprazo,'
            || '     d.prazo1 = s.prazo1,'
            || '     d.prazo2 = s.prazo2,'
            || '     d.prazo3 = s.prazo3,'
            || '     d.dtvenc1 = s.dtvenc1,'
            || '     d.dtvenc2 = s.dtvenc2,'
            || '     d.dtvenc3 = s.dtvenc3,'
            || '     d.numpr = s.numpr,'
            || '     d.tipovenda = s.tipovenda,'
            || '     d.pertxfim = s.pertxfim,'
            || '     d.obs = s.obs,'
            || '     d.oferta = s.oferta,'
            || '     d.prazo4 = s.prazo4,'
            || '     d.prazo5 = s.prazo5,'
            || '     d.prazo6 = s.prazo6,'
            || '     d.prazo7 = s.prazo7,'
            || '     d.prazo8 = s.prazo8,'
            || '     d.prazo9 = s.prazo9,'
            || '     d.prazo10 = s.prazo10,'
            || '     d.prazo11 = s.prazo11,'
            || '     d.prazo12 = s.prazo12,'
            || '     d.vendabk = s.vendabk,'
            || '     d.vlminpedido = s.vlminpedido,'
            || '     d.codcob = s.codcob,'
            || '     d.tipoentrada = s.tipoentrada,'
            || '     d.letraplpag = s.letraplpag,'
            || '     d.margemmin = s.margemmin,'
            || '     d.numitensminimo = s.numitensminimo,'
            || '     d.obsplpag = s.obsplpag,'
            || '     d.pertxfimpalm = s.pertxfimpalm,'
            || '     d.codequipe = s.codequipe,'
            || '     d.tiporestricao = s.tiporestricao,'
            || '     d.codrestricao = s.codrestricao,'
            || '     d.codplpagkraft = s.codplpagkraft,'
            || '     d.enviaplanofv = s.enviaplanofv,'
            || '     d.prazoponderado = s.prazoponderado,'
            || '     d.usaplpagautoservico = s.usaplpagautoservico,'
            || '     d.usadesclinhaprod = s.usadesclinhaprod,'
            || '     d.entrada = s.entrada,'
            || '     d.formaparcelamento = s.formaparcelamento,'
            || '     d.numparcelas = s.numparcelas,'
            || '     d.numdiascarencia = s.numdiascarencia,'
            || '     d.numdiascartao = s.numdiascartao,'
            || '     d.codfilial = s.codfilial'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codplpag, descricao, numdias, tipoprazo, prazo1, prazo2, prazo3, dtvenc1, dtvenc2, dtvenc3, numpr,'
            || '         tipovenda, pertxfim, obs, oferta, prazo4, prazo5, prazo6, prazo7, prazo8, prazo9, prazo10, prazo11,'
            || '         prazo12, vendabk, vlminpedido, codcob, tipoentrada, letraplpag, margemmin, numitensminimo, obsplpag,'
            || '         pertxfimpalm, codequipe, tiporestricao, codrestricao, codplpagkraft, enviaplanofv, prazoponderado,'
            || '         usaplpagautoservico, usadesclinhaprod, entrada, formaparcelamento, numparcelas, numdiascarencia,'
            || '         numdiascartao, codfilial) '
            || ' VALUES (s.codplpag, s.descricao, s.numdias, s.tipoprazo, s.prazo1, s.prazo2, s.prazo3, s.dtvenc1,'
            || '         s.dtvenc2, s.dtvenc3, s.numpr, s.tipovenda, s.pertxfim, s.obs, s.oferta, s.prazo4, s.prazo5,'
            || '         s.prazo6, s.prazo7, s.prazo8, s.prazo9, s.prazo10, s.prazo11, s.prazo12, s.vendabk, s.vlminpedido,'
            || '         s.codcob, s.tipoentrada, s.letraplpag, s.margemmin, s.numitensminimo, s.obsplpag, s.pertxfimpalm,'
            || '         s.codequipe, s.tiporestricao, s.codrestricao, s.codplpagkraft, s.enviaplanofv, s.prazoponderado,'
            || '         s.usaplpagautoservico, s.usadesclinhaprod, s.entrada, s.formaparcelamento, s.numparcelas,'
            || '         s.numdiascarencia, s.numdiascartao, s.codfilial)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcplpag;

   FUNCTION importar_pcpraca (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcpraca';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codpraca number(4,0),'
         || '  praca varchar2(25),'
         || '  numregiao number(4,0),'
         || '  rota number(4,0),'
         || '  seqrota number(4,0),'
         || '  populacao number(14,0),'
         || '  perfreteprogress number(8,4),'
         || '  codpracaorig number(6,0),'
         || '  distancia number(12,2),'
         || '  vlpautafrete number(12,2),'
         || '  codpracaorig2 number(6,0),'
         || '  codpracaorig3 number(6,0),'
         || '  codpracaorig4 number(6,0),'
         || '  codmunic number(8,0),'
         || '  situacao varchar2(1),'
         || '  numregiao2 number(4,0),'
         || '  dtcadastro date,'
         || '  cepinicial varchar2(9),'
         || '  cepfinal varchar2(9))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codpraca = s.codpraca) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.praca = s.praca,'
            || '     d.numregiao = s.numregiao,'
            || '     d.rota = s.rota,'
            || '     d.seqrota = s.seqrota,'
            || '     d.populacao = s.populacao,'
            || '     d.perfreteprogress = s.perfreteprogress,'
            || '     d.codpracaorig = s.codpracaorig,'
            || '     d.distancia = s.distancia,'
            || '     d.vlpautafrete = s.vlpautafrete,'
            || '     d.codpracaorig2 = s.codpracaorig2,'
            || '     d.codpracaorig3 = s.codpracaorig3,'
            || '     d.codpracaorig4 = s.codpracaorig4,'
            || '     d.codmunic = s.codmunic,'
            || '     d.situacao = s.situacao,'
            || '     d.numregiao2 = s.numregiao2,'
            || '     d.dtcadastro = s.dtcadastro,'
            || '     d.cepinicial = s.cepinicial,'
            || '     d.cepfinal = s.cepfinal'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codpraca, praca, numregiao, rota, seqrota, populacao, perfreteprogress, codpracaorig, distancia,'
            || '         vlpautafrete, codpracaorig2, codpracaorig3, codpracaorig4, codmunic, situacao, numregiao2,'
            || '         dtcadastro, cepinicial, cepfinal) '
            || ' VALUES (s.codpraca, s.praca, s.numregiao, s.rota, s.seqrota, s.populacao, s.perfreteprogress,'
            || '         s.codpracaorig, s.distancia, s.vlpautafrete, s.codpracaorig2, s.codpracaorig3,s.codpracaorig4,'
            || '         s.codmunic, s.situacao, s.numregiao2, s.dtcadastro, s.cepinicial, s.cepfinal)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcpraca;

   FUNCTION importar_pcprecoprom (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcprecoprom';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (frentecx varchar2(1),'
         || '  consideracalcgiro varchar2(1),'
         || '  utilizaprecofixorede varchar2(1),'
         || '  utilizaprecofixofamilia varchar2(1),'
         || '  codusur number(4,0),'
         || '  codpraca number(4,0),'
         || '  codfuncultalter number(8,0),'
         || '  apenasplpagmax varchar2(1),'
         || '  enviafv varchar2(1),'
         || '  codsupervisor number(4,0),'
         || '  numlote varchar2(15),'
         || '  codprod number(6,0),'
         || '  numregiao number(4,0),'
         || '  precofixo number(12,3),'
         || '  codplpagmax number(4,0),'
         || '  dtiniciovigencia date,'
         || '  dtfimvigencia date,'
         || '  codcli number(6,0),'
         || '  codprecoprom number(6,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codprecoprom = s.codprecoprom) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.frentecx = s.frentecx,'
            || '     d.consideracalcgiro = s.consideracalcgiro,'
            || '     d.utilizaprecofixorede = s.utilizaprecofixorede,'
            || '     d.utilizaprecofixofamilia = s.utilizaprecofixofamilia,'
            || '     d.codusur = s.codusur,'
            || '     d.codpraca = s.codpraca,'
            || '     d.codfuncultalter = s.codfuncultalter,'
            || '     d.apenasplpagmax = s.apenasplpagmax,'
            || '     d.enviafv = s.enviafv,'
            || '     d.codsupervisor = s.codsupervisor,'
            || '     d.numlote = s.numlote,'
            || '     d.codprod = s.codprod,'
            || '     d.numregiao = s.numregiao,'
            || '     d.precofixo = s.precofixo,'
            || '     d.codplpagmax = s.codplpagmax,'
            || '     d.dtiniciovigencia = s.dtiniciovigencia,'
            || '     d.dtfimvigencia = s.dtfimvigencia,'
            || '     d.codcli = s.codcli'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (frentecx, consideracalcgiro, utilizaprecofixorede, utilizaprecofixofamilia, codusur, codpraca,'
            || '         codfuncultalter, apenasplpagmax, enviafv, codsupervisor, numlote, codprod, numregiao, precofixo,'
            || '         codplpagmax, dtiniciovigencia, dtfimvigencia, codcli, codprecoprom) '
            || ' VALUES (s.frentecx, s.consideracalcgiro, s.utilizaprecofixorede, s.utilizaprecofixofamilia,'
            || '         s.codusur, s.codpraca, s.codfuncultalter, s.apenasplpagmax, s.enviafv,'
            || '         s.codsupervisor, s.numlote, s.codprod, s.numregiao, s.precofixo, s.codplpagmax,'
            || '         s.dtiniciovigencia, s.dtfimvigencia, s.codcli, s.codprecoprom)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcprecoprom;

   FUNCTION importar_pcprodut (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcprodut';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (anvisacapinstal number(11,0),'
         || '  anvisaconcen number(8,0),'
         || '  anvisaundosag varchar2(3),'
         || '  anvisanumprincat number(4,0),'
         || '  anvisadescprincat1 varchar2(100),'
         || '  anvisadescprincat2 varchar2(100),'
         || '  anvisadescprincat3 varchar2(100),'
         || '  anvisadescprincat4 varchar2(100),'
         || '  anvisacoeftec varchar2(20),'
         || '  anvisauncoeftec varchar2(3),'
         || '  paisorigem varchar2(40),'
         || '  tipoembalagemnestle number(2,0),'
         || '  codenderecoap number(10,0),'
         || '  codenderecocx number(10,0),'
         || '  custorepzfm number(18,6),'
         || '  custorepzfmtab number(18,6),'
         || '  precomaxconsumzfm number(18,6),'
         || '  precomaxconsumzfmtab number(18,6),'
         || '  mexiva number(10,6),'
         || '  mexieps number(10,6),'
         || '  mexfpgc number(10,6),'
         || '  usacross varchar2(1),'
         || '  usawms varchar2(1),'
         || '  codgenerofiscal number(6,0),'
         || '  qtmaxgondula number(6,0),'
         || '  qtmingondula number(6,0),'
         || '  utilizarvasilhame varchar2(1),'
         || '  codvasilhame number(6,0),'
         || '  numseqatu number,'
         || '  tipoembalage varchar2(2),'
         || '  tipocarga number(4,0),'
         || '  aliqavulsadare number(5,2),'
         || '  percbaseredent number(10,4),'
         || '  perccredicmpresumido number(12,4),'
         || '  custorepant number(18,6),'
         || '  estoqueporlote varchar2(1),'
         || '  proxnumlote number(8,0),'
         || '  controlavalidadedolote varchar2(1),'
         || '  prefixolote varchar2(5),'
         || '  prazomediovenda number(5,0),'
         || '  validarlote varchar2(1),'
         || '  codgrade number(10,0),'
         || '  codcor number(10,0),'
         || '  colunagrade number(2,0),'
         || '  isentoregms varchar2(2),'
         || '  regms varchar2(20),'
         || '  codfiscalbonific number(10,0),'
         || '  codfiscalsr number(10,0),'
         || '  codprazoent varchar2(4),'
         || '  qtmetros number(18,6),'
         || '  tipocomissao varchar2(1),'
         || '  tipoestoque varchar2(2),'
         || '  pesopeca number(10,3),'
         || '  restricaotransp varchar2(1),'
         || '  comissaoporlucratividade varchar2(1),'
         || '  vlipipeso number(12,4),'
         || '  vlipiporkg number(18,6),'
         || '  tipopiscofinsretido number(2,0),'
         || '  especificoatividadepr varchar2(1),'
         || '  codrotinaultalter number(6,0),'
         || '  pesopalete number(10,6),'
         || '  codenderecoal number(10,0),'
         || '  pontoreposicaoal number(8,2),'
         || '  capacidadepickingal number(8,2),'
         || '  percbonoutras number(12,2),'
         || '  percimportacao number(8,2),'
         || '  percofinsimp number(8,2),'
         || '  perpisimp number(8,2),'
         || '  redbaseiva number(18,6),'
         || '  redbasealiqext number(18,6),'
         || '  qtminimaatacado number(6,0),'
         || '  qtminimaatacadof number(6,0),'
         || '  conciliaimportacao varchar2(1),'
         || '  vlmaodeobra number(12,6),'
         || '  tiponorma varchar2(1),'
         || '  recminarm number(4,0),'
         || '  normapalete varchar2(1),'
         || '  dtvalidade date,'
         || '  conferenocheckout varchar2(1),'
         || '  pcomprof1 number(6,2),'
         || '  codrisco varchar2(4),'
         || '  codacondicionamento varchar2(4),'
         || '  codagrupmapasep varchar2(2),'
         || '  vlcalorico varchar2(100),'
         || '  proteina varchar2(100),'
         || '  lipideo varchar2(100),'
         || '  umidade varchar2(100),'
         || '  col95 varchar2(100),'
         || '  salmonela varchar2(100),'
         || '  boloresleveduras varchar2(100),'
         || '  estfaureaus varchar2(100),'
         || '  mofado varchar2(100),'
         || '  totdefeito varchar2(100),'
         || '  percperdakg number(12,4),'
         || '  aproveitacredicms varchar2(1),'
         || '  tipoprod number(2,0),'
         || '  tipopal number(2,0),'
         || '  tipoarm number(2,0),'
         || '  capacidadepicking number(8,2),'
         || '  codcaracprod number(3,0),'
         || '  codtipoestrutura number(3,0),'
         || '  restricaoblocado number(3,0),'
         || '  pontoreposicao number(8,2),'
         || '  tipopalpul number(2,0),'
         || '  codtipoestruturapul number(3,0),'
         || '  codprodmaster number(6,0),'
         || '  qtunitct number(6,2),'
         || '  ruact number(4,0),'
         || '  numeroct number(6,2),'
         || '  aptoct number(2,0),'
         || '  moduloct number(2,0),'
         || '  ruacx number(4,0),'
         || '  numerocx number(6,2),'
         || '  aptocx number(2,0),'
         || '  modulocx number(2,0),'
         || '  unidadect varchar2(2),'
         || '  vlpauta number(18,6),'
         || '  vlpautaipi number(18,6),'
         || '  embalagemmaster varchar2(12),'
         || '  embalagemct varchar2(12),'
         || '  numdiasmaxvenda number(3,0),'
         || '  usaaliqcredicmsdifer varchar2(1),'
         || '  percaliqcredicmsdiferest number(5,2),'
         || '  percaliqcredicmsdiferinter number(5,2),'
         || '  psicotropico varchar2(1),'
         || '  codlinhaprod number(6,0),'
         || '  custoreptab number(18,6),'
         || '  precomaxconsum number(18,6),'
         || '  precomaxconsumtab number(18,6),'
         || '  percdesc5 number(12,4),'
         || '  numlistainventrot number(6,0),'
         || '  numseqinventrot number(6,0),'
         || '  medicamentohospitalar varchar2(1),'
         || '  percbonificvenda number(5,2),'
         || '  principioativo varchar2(100),'
         || '  tipotributmedic varchar2(2),'
         || '  deposito number(3,0),'
         || '  predio number(3,0),'
         || '  nivel number(3,0),'
         || '  codequipe number(4,0),'
         || '  percsuframa number(12,4),'
         || '  exportabalanca varchar2(1),'
         || '  codinfnutri number(14,0),'
         || '  somentetv3 varchar2(1),'
         || '  pcomtlmkt number(6,2),'
         || '  seqtabpreco number(4,0),'
         || '  qtpontopedido number(20,8),'
         || '  qtminproduzir number(20,8),'
         || '  prazomedioproducao number(5,0),'
         || '  nomecomercial varchar2(100),'
         || '  fracaoseparacao number(20,8),'
         || '  fatortransf number(18,6),'
         || '  tamanholotefab number(18,6),'
         || '  velocidadeesp number(18,6),'
         || '  velocidadeoperacional number(18,6),'
         || '  eficienciaoperacional number(10,2),'
         || '  codfilialprodutora varchar2(2),'
         || '  fatorunfarm number(10,0),'
         || '  volumerec number(20,8),'
         || '  prazo number(4,0),'
         || '  prazoentr number(3,0),'
         || '  codprincipativo number(10,0),'
         || '  codprodsintegra varchar2(20),'
         || '  tiporestricaomed varchar2(2),'
         || '  informacoestecnicas varchar2(500),'
         || '  freteespecial varchar2(1),'
         || '  dirfotoprod varchar2(100),'
         || '  custorepmc number(18,6),'
         || '  tipomp varchar2(2),'
         || '  pesobrutomaster number(10,3),'
         || '  pesoliqmaster number(10,3),'
         || '  pckrotativo varchar2(1),'
         || '  prazoexpurgo number(3,0),'
         || '  numultexpurgo number(10,0),'
         || '  dtultexpurgo date,'
         || '  dtproxexpurgo date,'
         || '  percdesc6 number(12,4),'
         || '  percdesc7 number(12,4),'
         || '  percdesc8 number(12,4),'
         || '  percdesc9 number(12,4),'
         || '  percdesc10 number(12,4),'
         || '  numoriginal varchar2(20),'
         || '  depositocx number(3,0),'
         || '  prediocx number(3,0),'
         || '  nivelcx number(3,0),'
         || '  pontoreposicaocx number(8,2),'
         || '  capacidadepickingcx number(8,2),'
         || '  denominacaocomunbrasileira varchar2(10),'
         || '  perctoleranciaval number(6,3),'
         || '  descricao5 varchar2(45),'
         || '  descricao6 varchar2(45),'
         || '  descricao7 varchar2(45),'
         || '  custoproximacompra number(18,6),'
         || '  coddistrib varchar2(4),'
         || '  abastepalete varchar2(1),'
         || '  abastepaletecx varchar2(1),'
         || '  fracionado varchar2(1),'
         || '  medcodfunclibvenda number(8,0),'
         || '  meddtlibvenda date,'
         || '  codnestleterceiros varchar2(15),'
         || '  fatorconversaonestle number(10,6),'
         || '  percvenda number(5,2),'
         || '  confaz varchar2(1),'
         || '  multiplo2 number(18,6),'
         || '  anvisanumregmed varchar2(20),'
         || '  anvisaqtembalagem number(5,0),'
         || '  anvisaformafarm varchar2(20),'
         || '  anvisaviaadm varchar2(20),'
         || '  anvisaclasterapeutica varchar2(40),'
         || '  anvisausocontinuo varchar2(1),'
         || '  codfornec number(6,0),'
         || '  dtcadastro date,'
         || '  volume number(20,8),'
         || '  codauxiliar number(20,0),'
         || '  classe varchar2(1),'
         || '  lastropal number(10,4),'
         || '  alturapal number(10,4),'
         || '  qttotpal number(8,2),'
         || '  prazoval number(4,0),'
         || '  qtunitcx number(8,2),'
         || '  revenda varchar2(1),'
         || '  importado varchar2(1),'
         || '  folharosto varchar2(1),'
         || '  dtexclusao date,'
         || '  modulo number(2,0),'
         || '  rua number(4,0),'
         || '  numero number(6,2),'
         || '  apto number(4,0),'
         || '  dtultaltcom date,'
         || '  campanha varchar2(1),'
         || '  codprodprinc number(6,0),'
         || '  obs2 varchar2(2),'
         || '  percipi number(12,4),'
         || '  unidademaster varchar2(2),'
         || '  corredor varchar2(4),'
         || '  larguram3 number(10,6),'
         || '  alturam3 number(10,6),'
         || '  comprimentom3 number(10,6),'
         || '  tiporestricao varchar2(1),'
         || '  qttotpalfrac number(6,2),'
         || '  dv number(1,0),'
         || '  classevenda varchar2(1),'
         || '  classemc varchar2(1),'
         || '  classeestoque varchar2(1),'
         || '  classecompra varchar2(1),'
         || '  pericm number(10,2),'
         || '  percdesc number(12,4),'
         || '  percst number(12,4),'
         || '  percbon number(12,4),'
         || '  percfrete number(12,4),'
         || '  moeda varchar2(1),'
         || '  dtdolar varchar2(1),'
         || '  descricao1 varchar2(45),'
         || '  descricao2 varchar2(45),'
         || '  descricao3 varchar2(45),'
         || '  descricao4 varchar2(45),'
         || '  classificfiscal varchar2(20),'
         || '  custorep number(18,6),'
         || '  dtultaltcustorep date,'
         || '  nbm varchar2(15),'
         || '  codfab varchar2(15),'
         || '  tribfederal varchar2(15),'
         || '  percipivenda number(10,2),'
         || '  percdesc1 number(12,4),'
         || '  percdesc2 number(12,4),'
         || '  percdesc3 number(12,4),'
         || '  percdesc4 number(12,4),'
         || '  pericmsantecipado number(12,4),'
         || '  codprodsimilar number(6,0),'
         || '  codcategoria number(6,0),'
         || '  codsubcategoria number(6,0),'
         || '  codfilial varchar2(2),'
         || '  tipodescarga varchar2(1),'
         || '  status varchar2(1),'
         || '  percoutrasdesp number(12,4),'
         || '  percfretefob number(12,4),'
         || '  percdespadicional number(12,4),'
         || '  percdespfin number(12,4),'
         || '  vlbonific number(18,6),'
         || '  precofixo varchar2(1),'
         || '  piscofinsretido varchar2(1),'
         || '  perccommot number(8,2),'
         || '  ivaressarc number(10,2),'
         || '  icmsressarc number(10,2),'
         || '  tipovolumedescarga varchar2(2),'
         || '  comissaofixa varchar2(1),'
         || '  usaclassificacao varchar2(1),'
         || '  percivaicmantecip number(10,2),'
         || '  percaliqinticmantecip number(12,4),'
         || '  percaliqexticmantecip number(12,4),'
         || '  percicmred number(12,4),'
         || '  perciva number(12,4),'
         || '  percaliqint number(12,4),'
         || '  percaliqext number(12,4),'
         || '  codauxiliar2 number(14,0),'
         || '  vendadireta varchar2(1),'
         || '  passelivre varchar2(1),'
         || '  modulo2 number(2,0),'
         || '  rua2 number(4,0),'
         || '  numero2 number(6,2),'
         || '  apto2 number(2,0),'
         || '  codpassefiscal number(8,0),'
         || '  tipoalturapalete number(2,0),'
         || '  numlote varchar2(20),'
         || '  dtvenc date,'
         || '  perindeniz number(5,2),'
         || '  perpis number(6,2),'
         || '  multiplo number(8,2),'
         || '  vlvendatemp number(16,2),'
         || '  tipomerc varchar2(2),'
         || '  normafornecedor varchar2(10),'
         || '  tipocalcst varchar2(1),'
         || '  pericmfrete number(6,2),'
         || '  lotemincompra number(14,2),'
         || '  tiposugcompra varchar2(2),'
         || '  loteinccompra number(14,2),'
         || '  loteproducao number(14,2),'
         || '  autorizatipo4 varchar2(1),'
         || '  aceitavendafracao varchar2(1),'
         || '  codfunccadastro number(8,0),'
         || '  codfuncultalter number(8,0),'
         || '  codfiscal number(10,0),'
         || '  sittribut varchar2(2),'
         || '  margemmin number(4,2),'
         || '  flags varchar2(1),'
         || '  flag0 varchar2(2),'
         || '  flag1 varchar2(2),'
         || '  flag2 varchar2(2),'
         || '  larguraarm number(10,6),'
         || '  comprimentoarm number(10,6),'
         || '  alturaarm number(10,6),'
         || '  volumearm number(20,8),'
         || '  camapapal number(10,4),'
         || '  codprod number(6,0),'
         || '  descricao varchar2(40),'
         || '  embalagem varchar2(12),'
         || '  unidade varchar2(2),'
         || '  pesoliq number(12,6),'
         || '  pesobruto number(12,6),'
         || '  codepto number(6,0),'
         || '  codsec number(6,0),'
         || '  pcomint1 number(6,2),'
         || '  temrepos number(4,0),'
         || '  qtunit number(6,2),'
         || '  obs varchar2(2),'
         || '  pcomrep1 number(6,2),'
         || '  pcomext1 number(6,2))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codprod = s.codprod) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.anvisacapinstal = s.anvisacapinstal,'
            || '     d.anvisaconcen = s.anvisaconcen,'
            || '     d.anvisaundosag = s.anvisaundosag,'
            || '     d.anvisanumprincat = s.anvisanumprincat,'
            || '     d.anvisadescprincat1 = s.anvisadescprincat1,'
            || '     d.anvisadescprincat2 = s.anvisadescprincat2,'
            || '     d.anvisadescprincat3 = s.anvisadescprincat3,'
            || '     d.anvisadescprincat4 = s.anvisadescprincat4,'
            || '     d.anvisacoeftec = s.anvisacoeftec,'
            || '     d.anvisauncoeftec = s.anvisauncoeftec,'
            || '     d.paisorigem = s.paisorigem,'
            || '     d.tipoembalagemnestle = s.tipoembalagemnestle,'
            || '     d.codenderecoap = s.codenderecoap,'
            || '     d.codenderecocx = s.codenderecocx,'
            || '     d.custorepzfm = s.custorepzfm,'
            || '     d.custorepzfmtab = s.custorepzfmtab,'
            || '     d.precomaxconsumzfm = s.precomaxconsumzfm,'
            || '     d.precomaxconsumzfmtab = s.precomaxconsumzfmtab,'
            || '     d.mexiva = s.mexiva,'
            || '     d.mexieps = s.mexieps,'
            || '     d.mexfpgc = s.mexfpgc,'
            || '     d.usacross = s.usacross,'
            || '     d.usawms = s.usawms,'
            || '     d.codgenerofiscal = s.codgenerofiscal,'
            || '     d.qtmaxgondula = s.qtmaxgondula,'
            || '     d.qtmingondula = s.qtmingondula,'
            || '     d.utilizarvasilhame = s.utilizarvasilhame,'
            || '     d.codvasilhame = s.codvasilhame,'
            || '     d.numseqatu = s.numseqatu,'
            || '     d.tipoembalage = s.tipoembalage,'
            || '     d.tipocarga = s.tipocarga,'
            || '     d.aliqavulsadare = s.aliqavulsadare,'
            || '     d.percbaseredent = s.percbaseredent,'
            || '     d.perccredicmpresumido = s.perccredicmpresumido,'
            || '     d.custorepant = s.custorepant,'
            || '     d.estoqueporlote = s.estoqueporlote,'
            || '     d.proxnumlote = s.proxnumlote,'
            || '     d.controlavalidadedolote = s.controlavalidadedolote,'
            || '     d.prefixolote = s.prefixolote,'
            || '     d.prazomediovenda = s.prazomediovenda,'
            || '     d.validarlote = s.validarlote,'
            || '     d.codgrade = s.codgrade,'
            || '     d.codcor = s.codcor,'
            || '     d.colunagrade = s.colunagrade,'
            || '     d.isentoregms = s.isentoregms,'
            || '     d.regms = s.regms,'
            || '     d.codfiscalbonific = s.codfiscalbonific,'
            || '     d.codfiscalsr = s.codfiscalsr,'
            || '     d.codprazoent = s.codprazoent,'
            || '     d.qtmetros = s.qtmetros,'
            || '     d.tipocomissao = s.tipocomissao,'
            || '     d.tipoestoque = s.tipoestoque,'
            || '     d.pesopeca = s.pesopeca,'
            || '     d.restricaotransp = s.restricaotransp,'
            || '     d.comissaoporlucratividade = s.comissaoporlucratividade,'
            || '     d.vlipipeso = s.vlipipeso,'
            || '     d.vlipiporkg = s.vlipiporkg,'
            || '     d.tipopiscofinsretido = s.tipopiscofinsretido,'
            || '     d.especificoatividadepr = s.especificoatividadepr,'
            || '     d.codrotinaultalter = s.codrotinaultalter,'
            || '     d.pesopalete = s.pesopalete,'
            || '     d.codenderecoal = s.codenderecoal,'
            || '     d.pontoreposicaoal = s.pontoreposicaoal,'
            || '     d.capacidadepickingal = s.capacidadepickingal,'
            || '     d.percbonoutras = s.percbonoutras,'
            || '     d.percimportacao = s.percimportacao,'
            || '     d.percofinsimp = s.percofinsimp,'
            || '     d.perpisimp = s.perpisimp,'
            || '     d.redbaseiva = s.redbaseiva,'
            || '     d.redbasealiqext = s.redbasealiqext,'
            || '     d.qtminimaatacado = s.qtminimaatacado,'
            || '     d.qtminimaatacadof = s.qtminimaatacadof,'
            || '     d.conciliaimportacao = s.conciliaimportacao,'
            || '     d.vlmaodeobra = s.vlmaodeobra,'
            || '     d.tiponorma = s.tiponorma,'
            || '     d.recminarm = s.recminarm,'
            || '     d.normapalete = s.normapalete,'
            || '     d.dtvalidade = s.dtvalidade,'
            || '     d.conferenocheckout = s.conferenocheckout,'
            || '     d.pcomprof1 = s.pcomprof1,'
            || '     d.codrisco = s.codrisco,'
            || '     d.codacondicionamento = s.codacondicionamento,'
            || '     d.codagrupmapasep = s.codagrupmapasep,'
            || '     d.vlcalorico = s.vlcalorico,'
            || '     d.proteina = s.proteina,'
            || '     d.lipideo = s.lipideo,'
            || '     d.umidade = s.umidade,'
            || '     d.col95 = s.col95,'
            || '     d.salmonela = s.salmonela,'
            || '     d.boloresleveduras = s.boloresleveduras,'
            || '     d.estfaureaus = s.estfaureaus,'
            || '     d.mofado = s.mofado,'
            || '     d.totdefeito = s.totdefeito,'
            || '     d.percperdakg = s.percperdakg,'
            || '     d.aproveitacredicms = s.aproveitacredicms,'
            || '     d.tipoprod = s.tipoprod,'
            || '     d.tipopal = s.tipopal,'
            || '     d.tipoarm = s.tipoarm,'
            || '     d.capacidadepicking = s.capacidadepicking,'
            || '     d.codcaracprod = s.codcaracprod,'
            || '     d.codtipoestrutura = s.codtipoestrutura,'
            || '     d.restricaoblocado = s.restricaoblocado,'
            || '     d.pontoreposicao = s.pontoreposicao,'
            || '     d.tipopalpul = s.tipopalpul,'
            || '     d.codtipoestruturapul = s.codtipoestruturapul,'
            || '     d.codprodmaster = s.codprodmaster,'
            || '     d.qtunitct = s.qtunitct,'
            || '     d.ruact = s.ruact,'
            || '     d.numeroct = s.numeroct,'
            || '     d.aptoct = s.aptoct,'
            || '     d.moduloct = s.moduloct,'
            || '     d.ruacx = s.ruacx,'
            || '     d.numerocx = s.numerocx,'
            || '     d.aptocx = s.aptocx,'
            || '     d.modulocx = s.modulocx,'
            || '     d.unidadect = s.unidadect,'
            || '     d.vlpauta = s.vlpauta,'
            || '     d.vlpautaipi = s.vlpautaipi,'
            || '     d.embalagemmaster = s.embalagemmaster,'
            || '     d.embalagemct = s.embalagemct,'
            || '     d.numdiasmaxvenda = s.numdiasmaxvenda,'
            || '     d.usaaliqcredicmsdifer = s.usaaliqcredicmsdifer,'
            || '     d.percaliqcredicmsdiferest = s.percaliqcredicmsdiferest,'
            || '     d.percaliqcredicmsdiferinter = s.percaliqcredicmsdiferinter,'
            || '     d.psicotropico = s.psicotropico,'
            || '     d.codlinhaprod = s.codlinhaprod,'
            || '     d.custoreptab = s.custoreptab,'
            || '     d.precomaxconsum = s.precomaxconsum,'
            || '     d.precomaxconsumtab = s.precomaxconsumtab,'
            || '     d.percdesc5 = s.percdesc5,'
            || '     d.numlistainventrot = s.numlistainventrot,'
            || '     d.numseqinventrot = s.numseqinventrot,'
            || '     d.medicamentohospitalar = s.medicamentohospitalar,'
            || '     d.percbonificvenda = s.percbonificvenda,'
            || '     d.principioativo = s.principioativo,'
            || '     d.tipotributmedic = s.tipotributmedic,'
            || '     d.deposito = s.deposito,'
            || '     d.predio = s.predio,'
            || '     d.nivel = s.nivel,'
            || '     d.codequipe = s.codequipe,'
            || '     d.percsuframa = s.percsuframa,'
            || '     d.exportabalanca = s.exportabalanca,'
            || '     d.codinfnutri = s.codinfnutri,'
            || '     d.somentetv3 = s.somentetv3,'
            || '     d.pcomtlmkt = s.pcomtlmkt,'
            || '     d.seqtabpreco = s.seqtabpreco,'
            || '     d.qtpontopedido = s.qtpontopedido,'
            || '     d.qtminproduzir = s.qtminproduzir,'
            || '     d.prazomedioproducao = s.prazomedioproducao,'
            || '     d.nomecomercial = s.nomecomercial,'
            || '     d.fracaoseparacao = s.fracaoseparacao,'
            || '     d.fatortransf = s.fatortransf,'
            || '     d.tamanholotefab = s.tamanholotefab,'
            || '     d.velocidadeesp = s.velocidadeesp,'
            || '     d.velocidadeoperacional = s.velocidadeoperacional,'
            || '     d.eficienciaoperacional = s.eficienciaoperacional,'
            || '     d.codfilialprodutora = s.codfilialprodutora,'
            || '     d.fatorunfarm = s.fatorunfarm,'
            || '     d.volumerec = s.volumerec,'
            || '     d.prazo = s.prazo,'
            || '     d.prazoentr = s.prazoentr,'
            || '     d.codprincipativo = s.codprincipativo,'
            || '     d.codprodsintegra = s.codprodsintegra,'
            || '     d.tiporestricaomed = s.tiporestricaomed,'
            || '     d.informacoestecnicas = s.informacoestecnicas,'
            || '     d.freteespecial = s.freteespecial,'
            || '     d.dirfotoprod = s.dirfotoprod,'
            || '     d.custorepmc = s.custorepmc,'
            || '     d.tipomp = s.tipomp,'
            || '     d.pesobrutomaster = s.pesobrutomaster,'
            || '     d.pesoliqmaster = s.pesoliqmaster,'
            || '     d.pckrotativo = s.pckrotativo,'
            || '     d.prazoexpurgo = s.prazoexpurgo,'
            || '     d.numultexpurgo = s.numultexpurgo,'
            || '     d.dtultexpurgo = s.dtultexpurgo,'
            || '     d.dtproxexpurgo = s.dtproxexpurgo,'
            || '     d.percdesc6 = s.percdesc6,'
            || '     d.percdesc7 = s.percdesc7,'
            || '     d.percdesc8 = s.percdesc8,'
            || '     d.percdesc9 = s.percdesc9,'
            || '     d.percdesc10 = s.percdesc10,'
            || '     d.numoriginal = s.numoriginal,'
            || '     d.depositocx = s.depositocx,'
            || '     d.prediocx = s.prediocx,'
            || '     d.nivelcx = s.nivelcx,'
            || '     d.pontoreposicaocx = s.pontoreposicaocx,'
            || '     d.capacidadepickingcx = s.capacidadepickingcx,'
            || '     d.denominacaocomunbrasileira = s.denominacaocomunbrasileira,'
            || '     d.perctoleranciaval = s.perctoleranciaval,'
            || '     d.descricao5 = s.descricao5,'
            || '     d.descricao6 = s.descricao6,'
            || '     d.descricao7 = s.descricao7,'
            || '     d.custoproximacompra = s.custoproximacompra,'
            || '     d.coddistrib = s.coddistrib,'
            || '     d.abastepalete = s.abastepalete,'
            || '     d.abastepaletecx = s.abastepaletecx,'
            || '     d.fracionado = s.fracionado,'
            || '     d.medcodfunclibvenda = s.medcodfunclibvenda,'
            || '     d.meddtlibvenda = s.meddtlibvenda,'
            || '     d.codnestleterceiros = s.codnestleterceiros,'
            || '     d.fatorconversaonestle = s.fatorconversaonestle,'
            || '     d.percvenda = s.percvenda,'
            || '     d.confaz = s.confaz,'
            || '     d.multiplo2 = s.multiplo2,'
            || '     d.anvisanumregmed = s.anvisanumregmed,'
            || '     d.anvisaqtembalagem = s.anvisaqtembalagem,'
            || '     d.anvisaformafarm = s.anvisaformafarm,'
            || '     d.anvisaviaadm = s.anvisaviaadm,'
            || '     d.anvisaclasterapeutica = s.anvisaclasterapeutica,'
            || '     d.anvisausocontinuo = s.anvisausocontinuo,'
            || '     d.codfornec = s.codfornec,'
            || '     d.dtcadastro = s.dtcadastro,'
            || '     d.volume = s.volume,'
            || '     d.codauxiliar = s.codauxiliar,'
            || '     d.classe = s.classe,'
            || '     d.lastropal = s.lastropal,'
            || '     d.alturapal = s.alturapal,'
            || '     d.qttotpal = s.qttotpal,'
            || '     d.prazoval = s.prazoval,'
            || '     d.qtunitcx = s.qtunitcx,'
            || '     d.revenda = s.revenda,'
            || '     d.importado = s.importado,'
            || '     d.folharosto = s.folharosto,'
            || '     d.dtexclusao = s.dtexclusao,'
            || '     d.modulo = s.modulo,'
            || '     d.rua = s.rua,'
            || '     d.numero = s.numero,'
            || '     d.apto = s.apto,'
            || '     d.dtultaltcom = s.dtultaltcom,'
            || '     d.campanha = s.campanha,'
            || '     d.codprodprinc = s.codprodprinc,'
            || '     d.obs2 = s.obs2,'
            || '     d.percipi = s.percipi,'
            || '     d.unidademaster = s.unidademaster,'
            || '     d.corredor = s.corredor,'
            || '     d.larguram3 = s.larguram3,'
            || '     d.alturam3 = s.alturam3,'
            || '     d.comprimentom3 = s.comprimentom3,'
            || '     d.tiporestricao = s.tiporestricao,'
            || '     d.qttotpalfrac = s.qttotpalfrac,'
            || '     d.dv = s.dv,'
            || '     d.classevenda = s.classevenda,'
            || '     d.classemc = s.classemc,'
            || '     d.classeestoque = s.classeestoque,'
            || '     d.classecompra = s.classecompra,'
            || '     d.pericm = s.pericm,'
            || '     d.percdesc = s.percdesc,'
            || '     d.percst = s.percst,'
            || '     d.percbon = s.percbon,'
            || '     d.percfrete = s.percfrete,'
            || '     d.moeda = s.moeda,'
            || '     d.dtdolar = s.dtdolar,'
            || '     d.descricao1 = s.descricao1,'
            || '     d.descricao2 = s.descricao2,'
            || '     d.descricao3 = s.descricao3,'
            || '     d.descricao4 = s.descricao4,'
            || '     d.classificfiscal = s.classificfiscal,'
            || '     d.custorep = s.custorep,'
            || '     d.dtultaltcustorep = s.dtultaltcustorep,'
            || '     d.nbm = s.nbm,'
            || '     d.codfab = s.codfab,'
            || '     d.tribfederal = s.tribfederal,'
            || '     d.percipivenda = s.percipivenda,'
            || '     d.percdesc1 = s.percdesc1,'
            || '     d.percdesc2 = s.percdesc2,'
            || '     d.percdesc3 = s.percdesc3,'
            || '     d.percdesc4 = s.percdesc4,'
            || '     d.pericmsantecipado = s.pericmsantecipado,'
            || '     d.codprodsimilar = s.codprodsimilar,'
            || '     d.codcategoria = s.codcategoria,'
            || '     d.codsubcategoria = s.codsubcategoria,'
            || '     d.codfilial = s.codfilial,'
            || '     d.tipodescarga = s.tipodescarga,'
            || '     d.status = s.status,'
            || '     d.percoutrasdesp = s.percoutrasdesp,'
            || '     d.percfretefob = s.percfretefob,'
            || '     d.percdespadicional = s.percdespadicional,'
            || '     d.percdespfin = s.percdespfin,'
            || '     d.vlbonific = s.vlbonific,'
            || '     d.precofixo = s.precofixo,'
            || '     d.piscofinsretido = s.piscofinsretido,'
            || '     d.perccommot = s.perccommot,'
            || '     d.ivaressarc = s.ivaressarc,'
            || '     d.icmsressarc = s.icmsressarc,'
            || '     d.tipovolumedescarga = s.tipovolumedescarga,'
            || '     d.comissaofixa = s.comissaofixa,'
            || '     d.usaclassificacao = s.usaclassificacao,'
            || '     d.percivaicmantecip = s.percivaicmantecip,'
            || '     d.percaliqinticmantecip = s.percaliqinticmantecip,'
            || '     d.percaliqexticmantecip = s.percaliqexticmantecip,'
            || '     d.percicmred = s.percicmred,'
            || '     d.perciva = s.perciva,'
            || '     d.percaliqint = s.percaliqint,'
            || '     d.percaliqext = s.percaliqext,'
            || '     d.codauxiliar2 = s.codauxiliar2,'
            || '     d.vendadireta = s.vendadireta,'
            || '     d.passelivre = s.passelivre,'
            || '     d.modulo2 = s.modulo2,'
            || '     d.rua2 = s.rua2,'
            || '     d.numero2 = s.numero2,'
            || '     d.apto2 = s.apto2,'
            || '     d.codpassefiscal = s.codpassefiscal,'
            || '     d.tipoalturapalete = s.tipoalturapalete,'
            || '     d.numlote = s.numlote,'
            || '     d.dtvenc = s.dtvenc,'
            || '     d.perindeniz = s.perindeniz,'
            || '     d.perpis = s.perpis,'
            || '     d.multiplo = s.multiplo,'
            || '     d.vlvendatemp = s.vlvendatemp,'
            || '     d.tipomerc = s.tipomerc,'
            || '     d.normafornecedor = s.normafornecedor,'
            || '     d.tipocalcst = s.tipocalcst,'
            || '     d.pericmfrete = s.pericmfrete,'
            || '     d.lotemincompra = s.lotemincompra,'
            || '     d.tiposugcompra = s.tiposugcompra,'
            || '     d.loteinccompra = s.loteinccompra,'
            || '     d.loteproducao = s.loteproducao,'
            || '     d.autorizatipo4 = s.autorizatipo4,'
            || '     d.aceitavendafracao = s.aceitavendafracao,'
            || '     d.codfunccadastro = s.codfunccadastro,'
            || '     d.codfuncultalter = s.codfuncultalter,'
            || '     d.codfiscal = s.codfiscal,'
            || '     d.sittribut = s.sittribut,'
            || '     d.margemmin = s.margemmin,'
            || '     d.flags = s.flags,'
            || '     d.flag0 = s.flag0,'
            || '     d.flag1 = s.flag1,'
            || '     d.flag2 = s.flag2,'
            || '     d.larguraarm = s.larguraarm,'
            || '     d.comprimentoarm = s.comprimentoarm,'
            || '     d.alturaarm = s.alturaarm,'
            || '     d.volumearm = s.volumearm,'
            || '     d.camapapal = s.camapapal,'
            || '     d.descricao = s.descricao,'
            || '     d.embalagem = s.embalagem,'
            || '     d.unidade = s.unidade,'
            || '     d.pesoliq = s.pesoliq,'
            || '     d.pesobruto = s.pesobruto,'
            || '     d.codepto = s.codepto,'
            || '     d.codsec = s.codsec,'
            || '     d.pcomint1 = s.pcomint1,'
            || '     d.temrepos = s.temrepos,'
            || '     d.qtunit = s.qtunit,'
            || '     d.obs = s.obs,'
            || '     d.pcomrep1 = s.pcomrep1,'
            || '     d.pcomext1 = s.pcomext1'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (anvisacapinstal, anvisaconcen, anvisaundosag, anvisanumprincat, anvisadescprincat1, '
            || '         anvisadescprincat2, anvisadescprincat3, anvisadescprincat4, anvisacoeftec, anvisauncoeftec,'
            || '         paisorigem, tipoembalagemnestle, codenderecoap, codenderecocx, custorepzfm, custorepzfmtab,'
            || '         precomaxconsumzfm, precomaxconsumzfmtab, mexiva, mexieps, mexfpgc, usacross, usawms,'
            || '         codgenerofiscal, qtmaxgondula, qtmingondula, utilizarvasilhame, codvasilhame, numseqatu,'
            || '         tipoembalage, tipocarga, aliqavulsadare, percbaseredent, perccredicmpresumido, custorepant,'
            || '         estoqueporlote, proxnumlote, controlavalidadedolote, prefixolote, prazomediovenda, validarlote,'
            || '         codgrade, codcor, colunagrade, isentoregms, regms, codfiscalbonific, codfiscalsr, codprazoent,'
            || '         qtmetros, tipocomissao, tipoestoque, pesopeca, restricaotransp, comissaoporlucratividade,'
            || '         vlipipeso, vlipiporkg, tipopiscofinsretido, especificoatividadepr, codrotinaultalter,'
            || '         pesopalete, codenderecoal, pontoreposicaoal, capacidadepickingal, percbonoutras,'
            || '         percimportacao, percofinsimp, perpisimp, redbaseiva, redbasealiqext, qtminimaatacado,'
            || '         qtminimaatacadof, conciliaimportacao, vlmaodeobra, tiponorma, recminarm, normapalete,'
            || '         dtvalidade, conferenocheckout, pcomprof1, codrisco, codacondicionamento, codagrupmapasep,'
            || '         vlcalorico, proteina, lipideo, umidade, col95, salmonela, boloresleveduras, estfaureaus,'
            || '         mofado, totdefeito, percperdakg, aproveitacredicms, tipoprod, tipopal, tipoarm,'
            || '         capacidadepicking, codcaracprod, codtipoestrutura, restricaoblocado, pontoreposicao,'
            || '         tipopalpul, codtipoestruturapul, codprodmaster, qtunitct, ruact, numeroct, aptoct, moduloct,'
            || '         ruacx, numerocx, aptocx, modulocx, unidadect, vlpauta, vlpautaipi, embalagemmaster, embalagemct,'
            || '         numdiasmaxvenda, usaaliqcredicmsdifer, percaliqcredicmsdiferest, percaliqcredicmsdiferinter,'
            || '         psicotropico, codlinhaprod, custoreptab, precomaxconsum, precomaxconsumtab, percdesc5,'
            || '         numlistainventrot, numseqinventrot, medicamentohospitalar, percbonificvenda, principioativo,'
            || '         tipotributmedic, deposito, predio, nivel, codequipe, percsuframa, exportabalanca, codinfnutri,'
            || '         somentetv3, pcomtlmkt, seqtabpreco, qtpontopedido, qtminproduzir, prazomedioproducao, '
            || '         nomecomercial, fracaoseparacao, fatortransf, tamanholotefab, velocidadeesp, velocidadeoperacional,'
            || '         eficienciaoperacional, codfilialprodutora, fatorunfarm, volumerec, prazo, prazoentr, codprincipativo,'
            || '         codprodsintegra, tiporestricaomed, informacoestecnicas, freteespecial, dirfotoprod, custorepmc,'
            || '         tipomp, pesobrutomaster, pesoliqmaster, pckrotativo, prazoexpurgo, numultexpurgo, dtultexpurgo,'
            || '         dtproxexpurgo, percdesc6, percdesc7, percdesc8, percdesc9, percdesc10, numoriginal, depositocx,'
            || '         prediocx, nivelcx, pontoreposicaocx, capacidadepickingcx, denominacaocomunbrasileira,'
            || '         perctoleranciaval, descricao5, descricao6, descricao7, custoproximacompra, coddistrib,'
            || '         abastepalete, abastepaletecx, fracionado, medcodfunclibvenda, meddtlibvenda, codnestleterceiros,'
            || '         fatorconversaonestle, percvenda, confaz, multiplo2, anvisanumregmed, anvisaqtembalagem,'
            || '         anvisaformafarm, anvisaviaadm, anvisaclasterapeutica, anvisausocontinuo, codfornec,'
            || '         dtcadastro, volume, codauxiliar, classe, lastropal, alturapal, qttotpal, prazoval, qtunitcx,'
            || '         revenda, importado, folharosto, dtexclusao, modulo, rua, numero, apto, dtultaltcom, campanha,'
            || '         codprodprinc, obs2, percipi, unidademaster, corredor, larguram3, alturam3, comprimentom3,'
            || '         tiporestricao, qttotpalfrac, dv, classevenda, classemc, classeestoque, classecompra,'
            || '         pericm, percdesc, percst, percbon, percfrete, moeda, dtdolar, descricao1, descricao2,'
            || '         descricao3, descricao4, classificfiscal, custorep, dtultaltcustorep, nbm, codfab, tribfederal,'
            || '         percipivenda, percdesc1, percdesc2, percdesc3, percdesc4, pericmsantecipado, codprodsimilar,'
            || '         codcategoria, codsubcategoria, codfilial, tipodescarga, status, percoutrasdesp, percfretefob,'
            || '         percdespadicional, percdespfin, vlbonific, precofixo, piscofinsretido, perccommot, ivaressarc,'
            || '         icmsressarc, tipovolumedescarga, comissaofixa, usaclassificacao, percivaicmantecip,'
            || '         percaliqinticmantecip, percaliqexticmantecip, percicmred, perciva, percaliqint, percaliqext,'
            || '         codauxiliar2, vendadireta, passelivre, modulo2, rua2, numero2, apto2, codpassefiscal,'
            || '         tipoalturapalete, numlote, dtvenc, perindeniz, perpis, multiplo, vlvendatemp, tipomerc,'
            || '         normafornecedor, tipocalcst, pericmfrete, lotemincompra, tiposugcompra, loteinccompra,'
            || '         loteproducao, autorizatipo4, aceitavendafracao, codfunccadastro, codfuncultalter,'
            || '         codfiscal, sittribut, margemmin, flags, flag0, flag1, flag2, larguraarm, comprimentoarm,'
            || '         alturaarm, volumearm, camapapal, codprod, descricao, embalagem, unidade, pesoliq,'
            || '         pesobruto, codepto, codsec, pcomint1, temrepos, qtunit, obs, pcomrep1, pcomext1) '
            || ' VALUES (s.anvisacapinstal, s.anvisaconcen, s.anvisaundosag, s.anvisanumprincat, '
            || '         s.anvisadescprincat1, s.anvisadescprincat2, s.anvisadescprincat3, '
            || '         s.anvisadescprincat4, s.anvisacoeftec, s.anvisauncoeftec, s.paisorigem, '
            || '         s.tipoembalagemnestle, s.codenderecoap, s.codenderecocx, s.custorepzfm,'
            || '         s.custorepzfmtab, s.precomaxconsumzfm, s.precomaxconsumzfmtab, s.mexiva,'
            || '         s.mexieps, s.mexfpgc, s.usacross, s.usawms, s.codgenerofiscal, s.qtmaxgondula,'
            || '         s.qtmingondula, s.utilizarvasilhame, s.codvasilhame, s.numseqatu, s.tipoembalage,'
            || '         s.tipocarga, s.aliqavulsadare, s.percbaseredent, s.perccredicmpresumido,'
            || '         s.custorepant, s.estoqueporlote, s.proxnumlote, s.controlavalidadedolote,'
            || '         s.prefixolote, s.prazomediovenda, s.validarlote, s.codgrade, s.codcor,'
            || '         s.colunagrade, s.isentoregms, s.regms, s.codfiscalbonific, s.codfiscalsr,'
            || '         s.codprazoent, s.qtmetros, s.tipocomissao, s.tipoestoque, s.pesopeca,'
            || '         s.restricaotransp, s.comissaoporlucratividade, s.vlipipeso, s.vlipiporkg,'
            || '         s.tipopiscofinsretido, s.especificoatividadepr, s.codrotinaultalter, s.pesopalete,'
            || '         s.codenderecoal, s.pontoreposicaoal, s.capacidadepickingal, s.percbonoutras,'
            || '         s.percimportacao, s.percofinsimp, s.perpisimp, s.redbaseiva, s.redbasealiqext,'
            || '         s.qtminimaatacado, s.qtminimaatacadof, s.conciliaimportacao, s.vlmaodeobra,'
            || '         s.tiponorma, s.recminarm, s.normapalete, s.dtvalidade, s.conferenocheckout,'
            || '         s.pcomprof1, s.codrisco, s.codacondicionamento, s.codagrupmapasep, s.vlcalorico,'
            || '         s.proteina, s.lipideo, s.umidade, s.col95, s.salmonela, s.boloresleveduras,'
            || '         s.estfaureaus, s.mofado, s.totdefeito, s.percperdakg, s.aproveitacredicms,'
            || '         s.tipoprod, s.tipopal, s.tipoarm, s.capacidadepicking, s.codcaracprod,'
            || '         s.codtipoestrutura, s.restricaoblocado, s.pontoreposicao, s.tipopalpul,'
            || '         s.codtipoestruturapul, s.codprodmaster, s.qtunitct, s.ruact, s.numeroct,'
            || '         s.aptoct, s.moduloct, s.ruacx, s.numerocx, s.aptocx, s.modulocx, s.unidadect,'
            || '         s.vlpauta, s.vlpautaipi, s.embalagemmaster, s.embalagemct, s.numdiasmaxvenda,'
            || '         s.usaaliqcredicmsdifer, s.percaliqcredicmsdiferest, s.percaliqcredicmsdiferinter,'
            || '         s.psicotropico, s.codlinhaprod, s.custoreptab, s.precomaxconsum, s.precomaxconsumtab,'
            || '         s.percdesc5, s.numlistainventrot, s.numseqinventrot, s.medicamentohospitalar,'
            || '         s.percbonificvenda, s.principioativo, s.tipotributmedic, s.deposito, s.predio,'
            || '         s.nivel, s.codequipe, s.percsuframa, s.exportabalanca, s.codinfnutri, s.somentetv3,'
            || '         s.pcomtlmkt, s.seqtabpreco, s.qtpontopedido, s.qtminproduzir, s.prazomedioproducao,'
            || '         s.nomecomercial, s.fracaoseparacao, s.fatortransf, s.tamanholotefab, s.velocidadeesp,'
            || '         s.velocidadeoperacional, s.eficienciaoperacional, s.codfilialprodutora, s.fatorunfarm,'
            || '         s.volumerec, s.prazo, s.prazoentr, s.codprincipativo, s.codprodsintegra, s.tiporestricaomed,'
            || '         s.informacoestecnicas, s.freteespecial, s.dirfotoprod, s.custorepmc, s.tipomp,'
            || '         s.pesobrutomaster, s.pesoliqmaster, s.pckrotativo, s.prazoexpurgo, s.numultexpurgo,'
            || '         s.dtultexpurgo, s.dtproxexpurgo, s.percdesc6, s.percdesc7, s.percdesc8, s.percdesc9,'
            || '         s.percdesc10, s.numoriginal, s.depositocx, s.prediocx, s.nivelcx, s.pontoreposicaocx,'
            || '         s.capacidadepickingcx, s.denominacaocomunbrasileira, s.perctoleranciaval, s.descricao5,'
            || '         s.descricao6, s.descricao7, s.custoproximacompra, s.coddistrib, s.abastepalete,'
            || '         s.abastepaletecx, s.fracionado, s.medcodfunclibvenda, s.meddtlibvenda, '
            || '         s.codnestleterceiros, s.fatorconversaonestle, s.percvenda, s.confaz, s.multiplo2,'
            || '         s.anvisanumregmed, s.anvisaqtembalagem, s.anvisaformafarm, s.anvisaviaadm,'
            || '         s.anvisaclasterapeutica, s.anvisausocontinuo, s.codfornec, s.dtcadastro,'
            || '         s.volume, s.codauxiliar, s.classe, s.lastropal, s.alturapal, s.qttotpal, s.prazoval,'
            || '         s.qtunitcx, s.revenda, s.importado, s.folharosto, s.dtexclusao, s.modulo, s.rua,'
            || '         s.numero, s.apto, s.dtultaltcom, s.campanha, s.codprodprinc, s.obs2, s.percipi,'
            || '         s.unidademaster, s.corredor, s.larguram3, s.alturam3, s.comprimentom3, s.tiporestricao,'
            || '         s.qttotpalfrac, s.dv, s.classevenda, s.classemc, s.classeestoque, s.classecompra,'
            || '         s.pericm, s.percdesc, s.percst, s.percbon, s.percfrete, s.moeda, s.dtdolar, s.descricao1,'
            || '         s.descricao2, s.descricao3, s.descricao4, s.classificfiscal, s.custorep, s.dtultaltcustorep,'
            || '         s.nbm, s.codfab, s.tribfederal, s.percipivenda, s.percdesc1, s.percdesc2, s.percdesc3,'
            || '         s.percdesc4, s.pericmsantecipado, s.codprodsimilar, s.codcategoria, s.codsubcategoria,'
            || '         s.codfilial, s.tipodescarga, s.status, s.percoutrasdesp, s.percfretefob, s.percdespadicional,'
            || '         s.percdespfin, s.vlbonific, s.precofixo, s.piscofinsretido, s.perccommot, s.ivaressarc,'
            || '         s.icmsressarc, s.tipovolumedescarga, s.comissaofixa, s.usaclassificacao, s.percivaicmantecip,'
            || '         s.percaliqinticmantecip, s.percaliqexticmantecip, s.percicmred, s.perciva, s.percaliqint,'
            || '         s.percaliqext, s.codauxiliar2, s.vendadireta, s.passelivre, s.modulo2, s.rua2, s.numero2,'
            || '         s.apto2, s.codpassefiscal, s.tipoalturapalete, s.numlote, s.dtvenc, s.perindeniz,'
            || '         s.perpis, s.multiplo, s.vlvendatemp, s.tipomerc, s.normafornecedor, s.tipocalcst,'
            || '         s.pericmfrete, s.lotemincompra, s.tiposugcompra, s.loteinccompra, s.loteproducao,'
            || '         s.autorizatipo4, s.aceitavendafracao, s.codfunccadastro, s.codfuncultalter, '
            || '         s.codfiscal, s.sittribut, s.margemmin, s.flags, s.flag0, s.flag1, s.flag2, '
            || '         s.larguraarm, s.comprimentoarm, s.alturaarm, s.volumearm, s.camapapal, s.codprod,'
            || '         s.descricao, s.embalagem, s.unidade, s.pesoliq, s.pesobruto, s.codepto, s.codsec,'
            || '         s.pcomint1, s.temrepos, s.qtunit, s.obs, s.pcomrep1, s.pcomext1)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcprodut;

   FUNCTION importar_pcregiao (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcregiao';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (numregiao number(4,0),'
         || '  regiao varchar2(40),'
         || '  perfrete number(8,4),'
         || '  uf varchar2(2),'
         || '  vlfretekg number(10,4),'
         || '  codfilial varchar2(2),'
         || '  segmento varchar2(1),'
         || '  perfreteterceiros number(8,4),'
         || '  perfreteespecial number(8,4),'
         || '  status varchar2(1),'
         || '  tarepf varchar2(1),'
         || '  regiaozfm varchar2(1),'
         || '  perfreteconhec number(8,4),'
         || '  vlminfatbk number(14,6),'
         || '  vlminfatch number(14,6),'
         || '  exportafv number(1,0),'
         || '  numtabela varchar2(20),'
         || '  codestabelecimento varchar2(3),'
         || '  atualizaf11 varchar2(1),'
         || '  obs varchar2(60))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.numregiao = s.numregiao) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.regiao = s.regiao,'
            || '     d.perfrete = s.perfrete,'
            || '     d.uf = s.uf,'
            || '     d.vlfretekg = s.vlfretekg,'
            || '     d.codfilial = s.codfilial,'
            || '     d.segmento = s.segmento,'
            || '     d.perfreteterceiros = s.perfreteterceiros,'
            || '     d.perfreteespecial = s.perfreteespecial,'
            || '     d.status = s.status,'
            || '     d.tarepf = s.tarepf,'
            || '     d.regiaozfm = s.regiaozfm,'
            || '     d.perfreteconhec = s.perfreteconhec,'
            || '     d.vlminfatbk = s.vlminfatbk,'
            || '     d.vlminfatch = s.vlminfatch,'
            || '     d.exportafv = s.exportafv,'
            || '     d.numtabela = s.numtabela,'
            || '     d.codestabelecimento = s.codestabelecimento,'
            || '     d.atualizaf11 = s.atualizaf11,'
            || '     d.obs = s.obs'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (numregiao, regiao, perfrete, uf, vlfretekg, codfilial, segmento, perfreteterceiros,'
            || '         perfreteespecial, status, tarepf, regiaozfm, perfreteconhec, vlminfatbk, vlminfatch,'
            || '         exportafv, numtabela, codestabelecimento, atualizaf11, obs) '
            || ' VALUES (s.numregiao, s.regiao, s.perfrete, s.uf, s.vlfretekg, s.codfilial, s.segmento,'
            || '         s.perfreteterceiros, s.perfreteespecial, s.status, s.tarepf, s.regiaozfm,'
            || '         s.perfreteconhec, s.vlminfatbk, s.vlminfatch, s.exportafv, s.numtabela,'
            || '         s.codestabelecimento, s.atualizaf11, s.obs)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcregiao;

   FUNCTION importar_pcsubmodulo (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcsubmodulo';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (autmenu NUMBER(10,0),'
         || ' codmodulo NUMBER(4,0),'
         || ' codsubmodulo NUMBER(4,0),'
         || ' exibirmenu VARCHAR2(1),'
         || ' submodulo VARCHAR2(40)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codmodulo = s.codmodulo) AND (d.codsubmodulo = s.codsubmodulo)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.autmenu = s.autmenu ,'
            || ' d.exibirmenu = s.exibirmenu ,'
            || ' d.submodulo = s.submodulo '
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (autmenu,'
            || ' codmodulo,'
            || ' codsubmodulo,'
            || ' exibirmenu,'
            || ' submodulo) '
            || ' VALUES (s.autmenu,'
            || ' s.codmodulo,'
            || ' s.codsubmodulo,'
            || ' s.exibirmenu,'
            || ' s.submodulo)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pcsubmodulo;

   FUNCTION importar_pctabpr (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pctabpr';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codprod number(6,0),'
         || '  numregiao number(4,0),'
         || '  ptabela number(18,6),'
         || '  pvenda number(18,6),'
         || '  perdescmax number(10,2),'
         || '  perdescmaxtab number(10,2),'
         || '  poferta number(12,3),'
         || '  pofertatab number(12,3),'
         || '  margem number(6,2),'
         || '  dtultaltpvenda date,'
         || '  excluido varchar2(1),'
         || '  ptabela1 number(18,6),'
         || '  ptabela2 number(18,6),'
         || '  ptabela3 number(18,6),'
         || '  ptabela4 number(18,6),'
         || '  ptabela5 number(18,6),'
         || '  ptabela6 number(18,6),'
         || '  ptabela7 number(18,6),'
         || '  pvenda1 number(18,6),'
         || '  pvenda2 number(18,6),'
         || '  pvenda3 number(18,6),'
         || '  pvenda4 number(18,6),'
         || '  pvenda5 number(18,6),'
         || '  pvenda6 number(18,6),'
         || '  pvenda7 number(18,6),'
         || '  codst number(4,0),'
         || '  margem_esp number(6,2),'
         || '  pfrete number(10,4),'
         || '  tabelaemitida varchar2(1),'
         || '  perdescmaxesp number(6,3),'
         || '  perdescautor number(6,3),'
         || '  cotaitem number(6,0),'
         || '  qtdescautor number(6,0),'
         || '  pofertaaux number(12,3),'
         || '  perdescautortab number(6,3),'
         || '  cotaitemtab number(6,0),'
         || '  qtdescautortab number(6,0),'
         || '  perdescmaxbalcao number(10,2),'
         || '  perdescmaxtabbalcao number(10,2),'
         || '  precominimotabela number(12,3),'
         || '  precominimovenda number(12,3),'
         || '  perdescfob number(5,2),'
         || '  descontafrete varchar2(1),'
         || '  dtinicioptabela date,'
         || '  ptabelafuturo number(12,3),'
         || '  dtultaltptabelafuturo date,'
         || '  dtultaltptabela date,'
         || '  pcomrep1 number(6,2),'
         || '  pcomrep2 number(6,2),'
         || '  pcomrep3 number(6,2),'
         || '  percacrescimofrete number(8,2),'
         || '  dtemissaoetiq date,'
         || '  numseqatu number,'
         || '  precofab number(18,6),'
         || '  atualizar varchar2(1),'
         || '  vlacresfretekg number(12,6),'
         || '  ptabelaatac number(18,6),'
         || '  ptabelaatac1 number(18,6),'
         || '  ptabelaatac2 number(18,6),'
         || '  ptabelaatac3 number(18,6),'
         || '  ptabelaatac4 number(18,6),'
         || '  ptabelaatac5 number(18,6),'
         || '  ptabelaatac6 number(18,6),'
         || '  ptabelaatac7 number(18,6),'
         || '  pvendaatac number(18,6),'
         || '  pvendaatac1 number(18,6),'
         || '  pvendaatac2 number(18,6),'
         || '  pvendaatac3 number(18,6),'
         || '  pvendaatac4 number(18,6),'
         || '  pvendaatac5 number(18,6),'
         || '  pvendaatac6 number(18,6),'
         || '  pvendaatac7 number(18,6),'
         || '  precoanterioratac number(18,6),'
         || '  dtiniciovalidade date,'
         || '  dtfimvalidade date)'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.numregiao = s.numregiao and'
            || '     d.codprod = s.codprod) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.ptabela = s.ptabela,'
            || '     d.pvenda = s.pvenda,'
            || '     d.perdescmax = s.perdescmax,'
            || '     d.perdescmaxtab = s.perdescmaxtab,'
            || '     d.poferta = s.poferta,'
            || '     d.pofertatab = s.pofertatab,'
            || '     d.margem = s.margem,'
            || '     d.dtultaltpvenda = s.dtultaltpvenda,'
            || '     d.excluido = s.excluido,'
            || '     d.ptabela1 = s.ptabela1,'
            || '     d.ptabela2 = s.ptabela2,'
            || '     d.ptabela3 = s.ptabela3,'
            || '     d.ptabela4 = s.ptabela4,'
            || '     d.ptabela5 = s.ptabela5,'
            || '     d.ptabela6 = s.ptabela6,'
            || '     d.ptabela7 = s.ptabela7,'
            || '     d.pvenda1 = s.pvenda1,'
            || '     d.pvenda2 = s.pvenda2,'
            || '     d.pvenda3 = s.pvenda3,'
            || '     d.pvenda4 = s.pvenda4,'
            || '     d.pvenda5 = s.pvenda5,'
            || '     d.pvenda6 = s.pvenda6,'
            || '     d.pvenda7 = s.pvenda7,'
            || '     d.codst = s.codst,'
            || '     d.margem_esp = s.margem_esp,'
            || '     d.pfrete = s.pfrete,'
            || '     d.tabelaemitida = s.tabelaemitida,'
            || '     d.perdescmaxesp = s.perdescmaxesp,'
            || '     d.perdescautor = s.perdescautor,'
            || '     d.cotaitem = s.cotaitem,'
            || '     d.qtdescautor = s.qtdescautor,'
            || '     d.pofertaaux = s.pofertaaux,'
            || '     d.perdescautortab = s.perdescautortab,'
            || '     d.cotaitemtab = s.cotaitemtab,'
            || '     d.qtdescautortab = s.qtdescautortab,'
            || '     d.perdescmaxbalcao = s.perdescmaxbalcao,'
            || '     d.perdescmaxtabbalcao = s.perdescmaxtabbalcao,'
            || '     d.precominimotabela = s.precominimotabela,'
            || '     d.precominimovenda = s.precominimovenda,'
            || '     d.perdescfob = s.perdescfob,'
            || '     d.descontafrete = s.descontafrete,'
            || '     d.dtinicioptabela = s.dtinicioptabela,'
            || '     d.ptabelafuturo = s.ptabelafuturo,'
            || '     d.dtultaltptabelafuturo = s.dtultaltptabelafuturo,'
            || '     d.dtultaltptabela = s.dtultaltptabela,'
            || '     d.pcomrep1 = s.pcomrep1,'
            || '     d.pcomrep2 = s.pcomrep2,'
            || '     d.pcomrep3 = s.pcomrep3,'
            || '     d.percacrescimofrete = s.percacrescimofrete,'
            || '     d.dtemissaoetiq = s.dtemissaoetiq,'
            || '     d.numseqatu = s.numseqatu,'
            || '     d.precofab = s.precofab,'
            || '     d.atualizar = s.atualizar,'
            || '     d.vlacresfretekg = s.vlacresfretekg,'
            || '     d.ptabelaatac = s.ptabelaatac,'
            || '     d.ptabelaatac1 = s.ptabelaatac1,'
            || '     d.ptabelaatac2 = s.ptabelaatac2,'
            || '     d.ptabelaatac3 = s.ptabelaatac3,'
            || '     d.ptabelaatac4 = s.ptabelaatac4,'
            || '     d.ptabelaatac5 = s.ptabelaatac5,'
            || '     d.ptabelaatac6 = s.ptabelaatac6,'
            || '     d.ptabelaatac7 = s.ptabelaatac7,'
            || '     d.pvendaatac = s.pvendaatac,'
            || '     d.pvendaatac1 = s.pvendaatac1,'
            || '     d.pvendaatac2 = s.pvendaatac2,'
            || '     d.pvendaatac3 = s.pvendaatac3,'
            || '     d.pvendaatac4 = s.pvendaatac4,'
            || '     d.pvendaatac5 = s.pvendaatac5,'
            || '     d.pvendaatac6 = s.pvendaatac6,'
            || '     d.pvendaatac7 = s.pvendaatac7,'
            || '     d.precoanterioratac = s.precoanterioratac,'
            || '     d.dtiniciovalidade = s.dtiniciovalidade,'
            || '     d.dtfimvalidade = s.dtfimvalidade'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codprod, numregiao, ptabela, pvenda, perdescmax, perdescmaxtab, poferta, pofertatab,'
            || '         margem, dtultaltpvenda, excluido, ptabela1, ptabela2, ptabela3, ptabela4, ptabela5,'
            || '         ptabela6, ptabela7, pvenda1, pvenda2, pvenda3, pvenda4, pvenda5, pvenda6, pvenda7,'
            || '         codst, margem_esp, pfrete, tabelaemitida, perdescmaxesp, perdescautor, cotaitem,'
            || '         qtdescautor, pofertaaux, perdescautortab, cotaitemtab, qtdescautortab, perdescmaxbalcao,'
            || '         perdescmaxtabbalcao, precominimotabela, precominimovenda, perdescfob,'
            || '         descontafrete, dtinicioptabela, ptabelafuturo, dtultaltptabelafuturo,'
            || '         dtultaltptabela, pcomrep1, pcomrep2, pcomrep3, percacrescimofrete, dtemissaoetiq,'
            || '         numseqatu, precofab, atualizar, vlacresfretekg, ptabelaatac, ptabelaatac1, ptabelaatac2,'
            || '         ptabelaatac3, ptabelaatac4, ptabelaatac5, ptabelaatac6, ptabelaatac7, pvendaatac,'
            || '         pvendaatac1, pvendaatac2, pvendaatac3, pvendaatac4, pvendaatac5, pvendaatac6,'
            || '         pvendaatac7, precoanterioratac, dtiniciovalidade, dtfimvalidade) '
            || ' VALUES (s.codprod, s.numregiao, s.ptabela, s.pvenda, s.perdescmax, s.perdescmaxtab,'
            || '         s.poferta, s.pofertatab, s.margem, s.dtultaltpvenda, s.excluido, s.ptabela1,'
            || '         s.ptabela2, s.ptabela3, s.ptabela4, s.ptabela5, s.ptabela6, s.ptabela7, s.pvenda1,'
            || '         s.pvenda2, s.pvenda3, s.pvenda4, s.pvenda5, s.pvenda6, s.pvenda7, s.codst, s.margem_esp,'
            || '         s.pfrete, s.tabelaemitida, s.perdescmaxesp, s.perdescautor, s.cotaitem, s.qtdescautor,'
            || '         s.pofertaaux, s.perdescautortab, s.cotaitemtab, s.qtdescautortab, s.perdescmaxbalcao,'
            || '         s.perdescmaxtabbalcao, s.precominimotabela, s.precominimovenda, s.perdescfob, s.descontafrete, '
            || '         s.dtinicioptabela, s.ptabelafuturo, s.dtultaltptabelafuturo, s.dtultaltptabela, '
            || '         s.pcomrep1, s.pcomrep2, s.pcomrep3, s.percacrescimofrete, s.dtemissaoetiq,'
            || '         s.numseqatu, s.precofab, s.atualizar, s.vlacresfretekg, s.ptabelaatac,'
            || '         s.ptabelaatac1, s.ptabelaatac2, s.ptabelaatac3, s.ptabelaatac4, s.ptabelaatac5,'
            || '         s.ptabelaatac6, s.ptabelaatac7, s.pvendaatac, s.pvendaatac1, s.pvendaatac2, '
            || '         s.pvendaatac3, s.pvendaatac4, s.pvendaatac5, s.pvendaatac6, s.pvendaatac7,'
            || '         s.precoanterioratac, s.dtiniciovalidade, s.dtfimvalidade)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pctabpr;

   FUNCTION importar_pctabtrib (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pctabtrib';
      vsnomearquivo := vstabela || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codprod number(6,0),'
         || '  codfilialnf varchar2(2),'
         || '  ufdestino varchar2(2),'
         || '  codst number(4,0))'
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON ((d.codprod = s.codprod) AND (d.codfilialnf = s.codfilialnf) AND (d.ufdestino = s.ufdestino)) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET d.codst = s.codst'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codprod, codfilialnf, ufdestino, codst) '
            || ' VALUES (s.codprod, s.codfilialnf, s.ufdestino, s.codst)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_pctabtrib;

   FUNCTION importar_vw_credito (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      v_sql               VARCHAR2 (30000);
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccreditoclienteecf';
      vsnomearquivo := 'vw_credito_cliente' || '_' || pscodfilial || '.exp';

      IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      -- Importacao
      v_sql :=
            'CREATE TABLE imp_'
         || vstabela
         || ' (codcli NUMBER(6,0),'
         || ' total_receber NUMBER(20,6)) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || '''))'
         || ' REJECT LIMIT UNLIMITED ';

      EXECUTE IMMEDIATE v_sql;

      BEGIN
         v_sql :=
               'MERGE INTO '
            || vstabela
            || ' d'
            || '  USING (SELECT * '
            || '         FROM imp_'
            || vstabela
            || ') s '
            || ' ON (d.codcli = s.codcli) '
            || ' WHEN MATCHED THEN '
            || ' UPDATE '
            || ' SET  d.total_receber = s.total_receber'
            || ' WHEN NOT MATCHED THEN '
            || ' INSERT (codcli, total_receber) '
            || ' VALUES (s.codcli, s.total_receber)';

         EXECUTE IMMEDIATE v_sql;

         COMMIT;

         IF NOT destruir_instancia_importacao (pscodfilial, vstabela, vsmsg)
         THEN
            vsmensagem :=
                  'Erro ao finalizar importacao da tabela '
               || vstabela
               || '. Erro: '
               || vsmsg;
            RAISE exc_geracao_dados;
         END IF;

         vbresultado := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem := SQLCODE || ' - ' || SQLERRM;
            RAISE;
      END;

      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
      WHEN OTHERS
      THEN
         psmensagem := vsmensagem;
         RETURN vbresultado;
   END importar_vw_credito;

   PROCEDURE retorno_cancelamentos (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
   IS
      vblog        BOOLEAN;
      vsmensagem   VARCHAR2 (2000);
      vsmsg        VARCHAR2 (2000);
   BEGIN
      vblog :=
         gerar_arquivo_log (pscodfilial,
                               'ret_cancelamentos_'
                            || pscodfilial
                            || TO_CHAR (SYSDATE, 'ddmmyyyyhh24mi')
                           );

      BEGIN
         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line
               (vgarqlog,
                '**------------- MARCAR PARA NOVA EXPORTACAO ----------------**'
               );
         END IF;

         -- Marcar para nova exportacao registros que
         -- nao foram importados no servidor principal
         FOR c_nao_importados IN (SELECT codfilial, numpedecf, codfunccx,
                                         numcaixa, numserieequip, numped,
                                         numtransvendaecf
                                    FROM pcservintercancel
                                   WHERE codfilial = pscodfilial
                                     AND status = 'N')
         LOOP
            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Filial: '
                                  || c_nao_importados.codfilial
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Pedido ECF: '
                                  || c_nao_importados.numpedecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Cód. Func. Caixa: '
                                  || c_nao_importados.codfunccx
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Caixa: ' || c_nao_importados.numcaixa
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Serie Equip.: '
                                  || c_nao_importados.numserieequip
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Pedido: ' || c_nao_importados.numped
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Trans. Venda ECF: '
                                  || c_nao_importados.numtransvendaecf
                                 );
            END IF;

            BEGIN
               UPDATE pcpedccancecf
                  SET exportadoservint = 'N'
                WHERE numpedecf = c_nao_importados.numpedecf
                  AND codfilial = c_nao_importados.codfilial
                  AND codfunccx = c_nao_importados.codfunccx
                  AND numcaixa = c_nao_importados.numcaixa
                  AND numserieequip = c_nao_importados.numserieequip;

               UPDATE pcpedicancecf
                  SET exportadoservint = 'N'
                WHERE numpedecf = c_nao_importados.numpedecf
                  AND codfunccx = c_nao_importados.codfunccx
                  AND numcaixa = c_nao_importados.numcaixa
                  AND numserieequip = c_nao_importados.numserieequip;

               IF NOT c_nao_importados.numped IS NOT NULL
               THEN
                  UPDATE pcpedc
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  UPDATE pcpedi
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  UPDATE pcnfcan
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  UPDATE pcnfcanitem
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  IF NOT c_nao_importados.numtransvendaecf IS NOT NULL
                  THEN
                     UPDATE pcnfsaid
                        SET exportadoservint = 'N'
                      WHERE numtransvenda = c_nao_importados.numtransvendaecf;

                     UPDATE pcmov
                        SET exportadoservint = 'N'
                      WHERE numtransvenda = c_nao_importados.numtransvendaecf;
                  END IF;
               END IF;

               COMMIT;

               IF vblog
               THEN
                  UTL_FILE.put_line (vgarqlog, 'FINALIZADO COM SUCESSO!!!');
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  vsmensagem :=
                        'Erro ao remarcar cancelamento para nova exportacao. Erro: '
                     || SQLCODE
                     || ' - '
                     || SQLERRM;

                  IF vblog
                  THEN
                     UTL_FILE.put_line (vgarqlog, vsmensagem);
                  END IF;
            END;
         END LOOP;

         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line
                  (vgarqlog,
                   '**------------- EXCLUSAO DE REGISTROS ----------------**'
                  );
         END IF;

         -- Excluir registros que
         -- foram importados no servidor principal
         FOR c_importados IN (SELECT codfilial, numpedecf, codfunccx,
                                     numcaixa, numserieequip, numped,
                                     numtransvendaecf
                                FROM pcservintercancel
                               WHERE codfilial = pscodfilial AND status = 'R')
         LOOP
            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Filial: ' || c_importados.codfilial
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Pedido ECF: '
                                  || c_importados.numpedecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Cód. Func. Caixa: '
                                  || c_importados.codfunccx
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Caixa: ' || c_importados.numcaixa
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Serie Equip.: '
                                  || c_importados.numserieequip
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Pedido: ' || c_importados.numped
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Trans. Venda ECF: '
                                  || c_importados.numtransvendaecf
                                 );
            END IF;

            BEGIN
               DELETE FROM pcpedccancecf
                     WHERE numpedecf = c_importados.numpedecf
                       AND codfilial = c_importados.codfilial
                       AND codfunccx = c_importados.codfunccx
                       AND numcaixa = c_importados.numcaixa
                       AND numserieequip = c_importados.numserieequip;

               DELETE FROM pcpedicancecf
                     WHERE numpedecf = c_importados.numpedecf
                       AND codfunccx = c_importados.codfunccx
                       AND numcaixa = c_importados.numcaixa
                       AND numserieequip = c_importados.numserieequip;

               IF NOT c_importados.numped IS NOT NULL
               THEN
                  DELETE FROM pcpedc
                        WHERE numped = c_importados.numped;

                  DELETE FROM pcpedi
                        WHERE numped = c_importados.numped;

                  DELETE FROM pcnfcan
                        WHERE numped = c_importados.numped;

                  DELETE FROM pcnfcanitem
                        WHERE numped = c_importados.numped;

                  IF NOT c_importados.numtransvendaecf IS NOT NULL
                  THEN
                     DELETE FROM pcnfsaid
                           WHERE numtransvenda =
                                                c_importados.numtransvendaecf;

                     DELETE FROM pcmov
                           WHERE numtransvenda =
                                                c_importados.numtransvendaecf;
                  END IF;
               END IF;

               UPDATE pcservintercancel
                  SET status = 'C'
                WHERE numpedecf = c_importados.numpedecf
                  AND codfilial = c_importados.codfilial
                  AND codfunccx = c_importados.codfunccx
                  AND numcaixa = c_importados.numcaixa
                  AND numserieequip = c_importados.numserieequip;

               COMMIT;

               IF vblog
               THEN
                  UTL_FILE.put_line (vgarqlog, 'FINALIZADO COM SUCESSO!!!');
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  vsmensagem :=
                        'Erro ao excluir do servidor intermediario. Erro: '
                     || SQLCODE
                     || ' - '
                     || SQLERRM;

                  IF vblog
                  THEN
                     UTL_FILE.put_line (vgarqlog, vsmensagem);
                  END IF;
            END;
         END LOOP;

         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line (vgarqlog, vsmensagem);
            UTL_FILE.fclose (vgarqlog);
         END IF;

         psmensagem := vsmensagem;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;

            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog, vsmensagem);
               UTL_FILE.fclose (vgarqlog);
            END IF;
      END;
   END retorno_cancelamentos;

   PROCEDURE retorno_sangrias (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vblog        BOOLEAN;
      vsmensagem   VARCHAR2 (2000);
      vsmsg        VARCHAR2 (2000);
   BEGIN
      vblog :=
         gerar_arquivo_log (pscodfilial,
                               'ret_sangrias_'
                            || pscodfilial
                            || TO_CHAR (SYSDATE, 'ddmmyyyyhh24mi')
                           );

      BEGIN
         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line
               (vgarqlog,
                '**------------- MARCAR PARA NOVA EXPORTACAO ----------------**'
               );
         END IF;

         -- Marcar para nova exportacao registros que
         -- nao foram importados no servidor principal
         FOR c_nao_importados IN (SELECT codfilial, numvaleecf, codfunc,
                                         numcaixa, dtlanc
                                    FROM pcservintersangria
                                   WHERE codfilial = pscodfilial
                                     AND status = 'N')
         LOOP
            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Filial: '
                                  || c_nao_importados.codfilial
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Vale ECF: '
                                  || c_nao_importados.numvaleecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Cód. Func. Caixa: '
                                  || c_nao_importados.codfunc
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Caixa: ' || c_nao_importados.numcaixa
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Data: '
                                  || TO_CHAR (c_nao_importados.dtlanc,
                                              'dd/mm/yyyy'
                                             )
                                 );
            END IF;

            BEGIN
               UPDATE pcvalecx
                  SET exportadoservint = 'N'
                WHERE numvaleecf = c_nao_importados.numvaleecf
                  AND codfunc = c_nao_importados.codfunc
                  AND numcx = c_nao_importados.numcaixa
                  AND dtlanc = c_nao_importados.dtlanc;

               UPDATE pcmovcr
                  SET exportadoservint = 'N'
                WHERE numvaleecf = c_nao_importados.numvaleecf
                  AND codfunc = c_nao_importados.codfunc
                  AND numcx = c_nao_importados.numcaixa
                  AND DATA = c_nao_importados.dtlanc;

               COMMIT;

               IF vblog
               THEN
                  UTL_FILE.put_line (vgarqlog, 'FINALIZADO COM SUCESSO!!!');
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  vsmensagem :=
                        'Erro ao remarcar sangria para nova exportacao. Erro: '
                     || SQLCODE
                     || ' - '
                     || SQLERRM;

                  IF vblog
                  THEN
                     UTL_FILE.put_line (vgarqlog, vsmensagem);
                  END IF;
            END;
         END LOOP;

         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line
                  (vgarqlog,
                   '**------------- EXCLUSAO DE REGISTROS ----------------**'
                  );
         END IF;

         -- Excluir registros que
         -- foram importados no servidor principal
         FOR c_importados IN (SELECT codfilial, numvaleecf, codfunc, numcaixa,
                                     dtlanc
                                FROM pcservintersangria
                               WHERE codfilial = pscodfilial AND status = 'R')
         LOOP
            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Filial: ' || c_importados.codfilial
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Vale ECF: ' || c_importados.numvaleecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Func. Caixa: ' || c_importados.codfunc
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Caixa: ' || c_importados.numcaixa
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Data: '
                                  || TO_CHAR (c_importados.dtlanc,
                                              'dd/mm/yyyy'
                                             )
                                 );
            END IF;

            BEGIN
               DELETE FROM pcvalecx
                     WHERE numvaleecf = c_importados.numvaleecf
                       AND codfunc = c_importados.codfunc
                       AND numcx = c_importados.numcaixa
                       AND dtlanc = c_importados.dtlanc;

               DELETE FROM pcmovcr
                     WHERE numvaleecf = c_importados.numvaleecf
                       AND codfunc = c_importados.codfunc
                       AND numcx = c_importados.numcaixa
                       AND DATA = c_importados.dtlanc;

               UPDATE pcservintersangria
                  SET status = 'C'
                WHERE numvaleecf = c_importados.numvaleecf
                  AND codfunc = c_importados.codfunc
                  AND numcaixa = c_importados.numcaixa
                  AND dtlanc = c_importados.dtlanc;

               COMMIT;

               IF vblog
               THEN
                  UTL_FILE.put_line (vgarqlog, 'FINALIZADO COM SUCESSO!!!');
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  vsmensagem :=
                        'Erro ao excluir do servidor intermediario. Erro: '
                     || SQLCODE
                     || ' - '
                     || SQLERRM;

                  IF vblog
                  THEN
                     UTL_FILE.put_line (vgarqlog, vsmensagem);
                  END IF;
            END;
         END LOOP;

         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line (vgarqlog, vsmensagem);
            UTL_FILE.fclose (vgarqlog);
         END IF;

         psmensagem := vsmensagem;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;

            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog, vsmensagem);
               UTL_FILE.fclose (vgarqlog);
            END IF;
      END;
   END retorno_sangrias;

   PROCEDURE retorno_vendas (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vblog        BOOLEAN;
      vsmensagem   VARCHAR2 (2000);
      vsmsg        VARCHAR2 (2000);
   BEGIN
      vblog :=
         gerar_arquivo_log (pscodfilial,
                               'ret_vendas_'
                            || pscodfilial
                            || TO_CHAR (SYSDATE, 'ddmmyyyyhh24mi')
                           );

      BEGIN
         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line
               (vgarqlog,
                '**------------- MARCAR PARA NOVA EXPORTACAO ----------------**'
               );
         END IF;

         -- Marcar para nova exportacao registros que
         -- nao foram importados no servidor principal
         FOR c_nao_importados IN (SELECT codfilial, numtransvendaecf, numped,
                                         numpedecf, numcaixa, codfunccx,
                                         numserieequip
                                    FROM pcservintervendas
                                   WHERE codfilial = pscodfilial
                                     AND status = 'N')
         LOOP
            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Filial: '
                                  || c_nao_importados.codfilial
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Trans. Venda ECF: '
                                  || c_nao_importados.numtransvendaecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Pedido: ' || c_nao_importados.numped
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Pedido ECF: '
                                  || c_nao_importados.numpedecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Cód. Func. Caixa: '
                                  || c_nao_importados.codfunccx
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Caixa: ' || c_nao_importados.numcaixa
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Serie Equip.: '
                                  || c_nao_importados.numserieequip
                                 );
            END IF;

            BEGIN
               UPDATE pcnfsaid
                  SET exportadoservint = 'N'
                WHERE numtransvenda = c_nao_importados.numtransvendaecf;

               UPDATE pcmov
                  SET exportadoservint = 'N'
                WHERE numtransvenda = c_nao_importados.numtransvendaecf;

               UPDATE pcprest
                  SET exportadoservint = 'N'
                WHERE numtransvenda = c_nao_importados.numtransvendaecf;

               UPDATE pcnfbase
                  SET exportadoservint = 'N'
                WHERE numtransvenda = c_nao_importados.numtransvendaecf;

               IF NOT c_nao_importados.numped IS NOT NULL
               THEN
                  UPDATE pcpedc
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  UPDATE pcpedi
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  UPDATE pcautori
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;

                  UPDATE pcvendaconsum
                     SET exportadoservint = 'N'
                   WHERE numped = c_nao_importados.numped;
               END IF;

               COMMIT;

               IF vblog
               THEN
                  UTL_FILE.put_line (vgarqlog, 'FINALIZADO COM SUCESSO!!!');
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  vsmensagem :=
                        'Erro ao remarcar venda para nova exportacao. Erro: '
                     || SQLCODE
                     || ' - '
                     || SQLERRM;

                  IF vblog
                  THEN
                     UTL_FILE.put_line (vgarqlog, vsmensagem);
                  END IF;
            END;
         END LOOP;

         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line
                  (vgarqlog,
                   '**------------- EXCLUSAO DE REGISTROS ----------------**'
                  );
         END IF;

         -- Excluir registros que
         -- foram importados no servidor principal
         FOR c_importados IN (SELECT codfilial, numtransvendaecf, numped,
                                     numpedecf, numcaixa, codfunccx,
                                     numserieequip
                                FROM pcservintervendas
                               WHERE codfilial = pscodfilial AND status = 'R')
         LOOP
            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog,
                                  'Cód. Filial: ' || c_importados.codfilial
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Trans. Venda ECF: '
                                  || c_importados.numtransvendaecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Pedido: ' || c_importados.numped
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Pedido ECF: '
                                  || c_importados.numpedecf
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Cód. Func. Caixa: '
                                  || c_importados.codfunccx
                                 );
               UTL_FILE.put_line (vgarqlog,
                                  'Num. Caixa: ' || c_importados.numcaixa
                                 );
               UTL_FILE.put_line (vgarqlog,
                                     'Num. Serie Equip.: '
                                  || c_importados.numserieequip
                                 );
            END IF;

            BEGIN
               DELETE FROM pcnfsaid
                     WHERE numtransvenda = c_importados.numtransvendaecf;

               DELETE FROM pcmov
                     WHERE numtransvenda = c_importados.numtransvendaecf;

               DELETE FROM pcprest
                     WHERE numtransvenda = c_importados.numtransvendaecf;

               DELETE FROM pcnfbase
                     WHERE numtransvenda = c_importados.numtransvendaecf;

               IF NOT c_importados.numped IS NOT NULL
               THEN
                  DELETE FROM pcpedc
                        WHERE numped = c_importados.numped;

                  DELETE FROM pcpedi
                        WHERE numped = c_importados.numped;

                  DELETE FROM pcautori
                        WHERE numped = c_importados.numped;

                  DELETE FROM pcvendaconsum
                        WHERE numped = c_importados.numped;
               END IF;

               UPDATE pcservintervendas
                  SET status = 'C'
                WHERE numtransvendaecf = c_importados.numtransvendaecf
                  AND codfilial = c_importados.codfilial;

               COMMIT;

               IF vblog
               THEN
                  UTL_FILE.put_line (vgarqlog, 'FINALIZADO COM SUCESSO!!!');
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  vsmensagem :=
                        'Erro ao excluir venda do intermediario. Erro: '
                     || SQLCODE
                     || ' - '
                     || SQLERRM;

                  IF vblog
                  THEN
                     UTL_FILE.put_line (vgarqlog, vsmensagem);
                  END IF;
            END;
         END LOOP;

         IF vblog
         THEN
            UTL_FILE.new_line (vgarqlog);
            UTL_FILE.put_line (vgarqlog, vsmensagem);
            UTL_FILE.fclose (vgarqlog);
         END IF;

         psmensagem := vsmensagem;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;

            IF vblog
            THEN
               UTL_FILE.new_line (vgarqlog);
               UTL_FILE.put_line (vgarqlog, vsmensagem);
               UTL_FILE.fclose (vgarqlog);
            END IF;
      END;
   END retorno_vendas;

   PROCEDURE executar_retorno (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vsmensagem   VARCHAR2 (30000);
      vsmsg        VARCHAR2 (30000);
   BEGIN
      vsmsg := '';
      vsmensagem := '';

      -- Retornos
      IF NOT importar_pcservintercancel (pscodfilial, vsmsg)
      THEN
         vsmensagem :=
                      vsmensagem || '; importar_pcservintercancel: ' || vsmsg;
      END IF;

      retorno_cancelamentos (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ''
      THEN
         vsmensagem := vsmensagem || '; retorno_cancelamentos: ' || vsmsg;
      END IF;

      IF NOT importar_pcservintersangria (pscodfilial, vsmsg)
      THEN
         vsmensagem :=
                     vsmensagem || '; importar_pcservintersangria: ' || vsmsg;
      END IF;

      retorno_sangrias (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ''
      THEN
         vsmensagem := vsmensagem || '; retorno_sangrias: ' || vsmsg;
      END IF;

      IF NOT importar_pcservintervendas (pscodfilial, vsmsg)
      THEN
         vsmensagem :=
                      vsmensagem || '; importar_pcservintervendas: ' || vsmsg;
      END IF;

      retorno_vendas (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ''
      THEN
         vsmensagem := vsmensagem || '; retorno_vendas: ' || vsmsg;
      END IF;

      IF NVL (vsmensagem, ' ') = ' '
      THEN
         vsmensagem := 'OK';
      END IF;

      psmensagem := vsmensagem;
   END;

   PROCEDURE executar_importacao (pscodfilial VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vsmensagem   VARCHAR2 (20000);
      vsmsg        VARCHAR2 (1000);
   BEGIN
      vsmsg := '';
      vsmensagem := '';

      IF NOT importar_pcativi (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcativi: ' || vsmsg;
      END IF;

      IF NOT importar_pcautori (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcautori: ' || vsmsg;
      END IF;

      IF NOT importar_pcbanco (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcbanco: ' || vsmsg;
      END IF;

      IF NOT importar_pccaixa (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pccaixa: ' || vsmsg;
      END IF;

      IF NOT importar_pccfo (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pccfo: ' || vsmsg;
      END IF;

      IF NOT importar_pcclient (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcclient: ' || vsmsg;
      END IF;

      IF NOT importar_pccob (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pccob: ' || vsmsg;
      END IF;

      IF NOT importar_pccobecf (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pccobecf: ' || vsmsg;
      END IF;

      IF NOT importar_pcconsum (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcconsum: ' || vsmsg;
      END IF;

      IF NOT importar_pccontro (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pccontro: ' || vsmsg;
      END IF;

      IF NOT importar_pccontroi (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pccontroi: ' || vsmsg;
      END IF;

      IF NOT importar_pcdepto (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcdepto: ' || vsmsg;
      END IF;

      IF NOT importar_pcdescquant (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcdescquant: ' || vsmsg;
      END IF;

      IF NOT importar_pcdocc (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcdocc: ' || vsmsg;
      END IF;

      IF NOT importar_pcdoci (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcdoci: ' || vsmsg;
      END IF;

      IF NOT importar_pcembalagem (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcembalagem: ' || vsmsg;
      END IF;

      IF NOT importar_pcempr (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcempr: ' || vsmsg;
      END IF;

      IF NOT importar_pcest (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcest: ' || vsmsg;
      END IF;

      IF NOT importar_pcfilial (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcfilial: ' || vsmsg;
      END IF;

      IF NOT importar_pcformprod (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcformprod: ' || vsmsg;
      END IF;

      IF NOT importar_pcfornec (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcfornec: ' || vsmsg;
      END IF;

      IF NOT importar_pclib (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pclib: ' || vsmsg;
      END IF;

      IF NOT importar_pcmodulo (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcmodulo: ' || vsmsg;
      END IF;

      IF NOT importar_pcmoeda (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcmoeda: ' || vsmsg;
      END IF;

      IF NOT importar_pcocorbc (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcocorbc: ' || vsmsg;
      END IF;

      IF NOT importar_pcplpag (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcplpag: ' || vsmsg;
      END IF;

      IF NOT importar_pcpraca (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcpraca: ' || vsmsg;
      END IF;

      IF NOT importar_pcprecoprom (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcprecoprom: ' || vsmsg;
      END IF;

      IF NOT importar_pcprodut (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcprodut: ' || vsmsg;
      END IF;

      IF NOT importar_pcregiao (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcregiao: ' || vsmsg;
      END IF;

      IF NOT importar_pcriscoacondicionamen (pscodfilial, vsmsg)
      THEN
         vsmensagem :=
                  vsmensagem || '; importar_pcriscoacondicionamen: ' || vsmsg;
      END IF;

      IF NOT importar_pcrotina (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcrotina: ' || vsmsg;
      END IF;

      IF NOT importar_pcrotinai (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcrotinai: ' || vsmsg;
      END IF;

      IF NOT importar_pcsecao (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcsecao: ' || vsmsg;
      END IF;

      IF NOT importar_pcsetor (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcsetor: ' || vsmsg;
      END IF;

      IF NOT importar_pcsubmodulo (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcsubmodulo: ' || vsmsg;
      END IF;

      IF NOT importar_pcsuperv (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcsuperv: ' || vsmsg;
      END IF;

      IF NOT importar_pctabpr (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pctabpr: ' || vsmsg;
      END IF;

      IF NOT importar_pctabtrib (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pctabtrib: ' || vsmsg;
      END IF;

      IF NOT importar_pctriboutros (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pctriboutros: ' || vsmsg;
      END IF;

      IF NOT importar_pctribut (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pctribut: ' || vsmsg;
      END IF;

      IF NOT importar_pcusuari (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcusuari: ' || vsmsg;
      END IF;

      IF NOT importar_pcveicul (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_pcveicul: ' || vsmsg;
      END IF;

      IF NOT importar_vw_credito (pscodfilial, vsmsg)
      THEN
         vsmensagem := vsmensagem || '; importar_vw_credito: ' || vsmsg;
      END IF;

      BEGIN
         UPDATE pcconsum
            SET proxnumtransvenda =
                   GREATEST ((SELECT proxnumtransvendaecf
                                FROM pcfilial
                               WHERE codigo = pscodfilial), proxnumtransvenda),
                proxnumcar =
                           GREATEST ((SELECT proxnumcarecf
                                        FROM pcfilial
                                       WHERE codigo = pscodfilial),
                                     proxnumcar)
          WHERE ROWNUM = 1;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem :=
                  'ABORTAR_OPERACAO. Erro ao atualizar pcconsum. Erro: '
               || SQLCODE
               || ' - '
               || SQLERRM;
      END;

      executar_retorno (pscodfilial, vsmsg);

      IF (NVL (vsmsg, ' ') <> ' ') AND (NVL (vsmsg, ' ') <> 'OK')
      THEN
         vsmensagem := vsmensagem || '; executar_retorno: ' || vsmsg;
      END IF;

      IF NVL (vsmensagem, ' ') = ' '
      THEN
         vsmensagem := 'OK';
      END IF;

      psmensagem := vsmensagem;
   END;

   -- Vendas
   FUNCTION exportar_pcnfsaid (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vsmsg := '';
      vbresultado := FALSE;
      vstabela := 'pcnfsaid';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( apresentoucupompromocao,'
         || ' bcst,'
         || ' bcstgnre,'
         || ' broker,'
         || ' caixa,'
         || ' codcli,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcont,'
         || ' codcontrato,'
         || ' coddevol,'
         || ' coddoc,'
         || ' codemitente,'
         || ' codepto,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfiscal,'
         || ' codfornec,'
         || ' codfornecfrete,'
         || ' codfunccancel,'
         || ' codfunclanc,'
         || ' codfunclibent,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' comissao,'
         || ' comissaosup,'
         || ' comissao2,'
         || ' comissao3,'
         || ' condvenda,'
         || ' dtcancel,'
         || ' dtcanhoto,'
         || ' dtdevol,'
         || ' dtemissaonffornec,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dthorachegada,'
         || ' dthorasaida,'
         || ' dtimportacaoservprinc,'
         || ' dtlibent,'
         || ' dtnsu,'
         || ' dtpgtocampanha,'
         || ' dtsaida,'
         || ' dtwms,'
         || ' equiplanc,'
         || ' especie,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' funclanc,'
         || ' geracaorazaoauxiliar,'
         || ' geracp,'
         || ' horalanc,'
         || ' icmsretido,'
         || ' icmsretidognre,'
         || ' importadoservprinc,'
         || ' kmfinalentrega,'
         || ' minutolanc,'
         || ' nffornec,'
         || ' nsu,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcupom,'
         || ' numecf,'
         || ' numformulario,'
         || ' numidf,'
         || ' numitens,'
         || ' numlanccp,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numped,'
         || ' numprevenda,'
         || ' numregiao,'
         || ' numregiaofrete,'
         || ' numselonf,'
         || ' numseq,'
         || ' numseqmontagem,'
         || ' numserieequip,'
         || ' numtab,'
         || ' numtransvenda,'
         || ' numtransvendadestino,'
         || ' numtransvendaecf,'
         || ' numtransvendaorigem,'
         || ' numvias,'
         || ' numviaspu,'
         || ' numvolume,'
         || ' obs,'
         || ' perbaseredoutrasdesp,'
         || ' percfrete,'
         || ' perdescfin,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' reservaritenstv7,'
         || ' rotinalanc,'
         || ' serie,'
         || ' serieecf,'
         || ' stribut,'
         || ' tipodevol,'
         || ' tipofrete,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' uf,'
         || ' vlbase,'
         || ' vlbaseipi,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesconto,'
         || ' vldescprom,'
         || ' vldevolucao,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicms,'
         || ' vlicmsantecipado,'
         || ' vlipi,'
         || ' vlir,'
         || ' vlisentas,'
         || ' vliss,'
         || ' vloutras,'
         || ' vloutrasdesp,'
         || ' vlpis,'
         || ' vlrecebidoboleto,'
         || ' vlrecebidocartao,'
         || ' vlrecebidoch,'
         || ' vlrecebidodin,'
         || ' vltabela,'
         || ' vltotal,'
         || ' vltotalnf,'
         || ' vltotger,'
         || ' vltroco,'
         || ' vlverbacmvcli ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT apresentoucupompromocao,'
         || ' bcst,'
         || ' bcstgnre,'
         || ' broker,'
         || ' caixa,'
         || ' codcli,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcont,'
         || ' codcontrato,'
         || ' coddevol,'
         || ' coddoc,'
         || ' codemitente,'
         || ' codepto,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfiscal,'
         || ' codfornec,'
         || ' codfornecfrete,'
         || ' codfunccancel,'
         || ' codfunclanc,'
         || ' codfunclibent,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' comissao,'
         || ' comissaosup,'
         || ' comissao2,'
         || ' comissao3,'
         || ' condvenda,'
         || ' dtcancel,'
         || ' dtcanhoto,'
         || ' dtdevol,'
         || ' dtemissaonffornec,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dthorachegada,'
         || ' dthorasaida,'
         || ' dtimportacaoservprinc,'
         || ' dtlibent,'
         || ' dtnsu,'
         || ' dtpgtocampanha,'
         || ' dtsaida,'
         || ' dtwms,'
         || ' equiplanc,'
         || ' especie,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' funclanc,'
         || ' geracaorazaoauxiliar,'
         || ' geracp,'
         || ' horalanc,'
         || ' icmsretido,'
         || ' icmsretidognre,'
         || ' importadoservprinc,'
         || ' kmfinalentrega,'
         || ' minutolanc,'
         || ' nffornec,'
         || ' nsu,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcupom,'
         || ' numecf,'
         || ' numformulario,'
         || ' numidf,'
         || ' numitens,'
         || ' numlanccp,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numped,'
         || ' numprevenda,'
         || ' numregiao,'
         || ' numregiaofrete,'
         || ' numselonf,'
         || ' numseq,'
         || ' numseqmontagem,'
         || ' numserieequip,'
         || ' numtab,'
         || ' numtransvenda,'
         || ' numtransvendadestino,'
         || ' numtransvendaecf,'
         || ' numtransvendaorigem,'
         || ' numvias,'
         || ' numviaspu,'
         || ' numvolume,'
         || ' obs,'
         || ' perbaseredoutrasdesp,'
         || ' percfrete,'
         || ' perdescfin,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' reservaritenstv7,'
         || ' rotinalanc,'
         || ' serie,'
         || ' serieecf,'
         || ' stribut,'
         || ' tipodevol,'
         || ' tipofrete,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' uf,'
         || ' vlbase,'
         || ' vlbaseipi,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesconto,'
         || ' vldescprom,'
         || ' vldevolucao,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicms,'
         || ' vlicmsantecipado,'
         || ' vlipi,'
         || ' vlir,'
         || ' vlisentas,'
         || ' vliss,'
         || ' vloutras,'
         || ' vloutrasdesp,'
         || ' vlpis,'
         || ' vlrecebidoboleto,'
         || ' vlrecebidocartao,'
         || ' vlrecebidoch,'
         || ' vlrecebidodin,'
         || ' vltabela,'
         || ' vltotal,'
         || ' vltotalnf,'
         || ' vltotger,'
         || ' vltroco,'
         || ' vlverbacmvcli '
         || ' FROM pcnfsaid '
         || ' WHERE numtransvenda IN ('
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcnfsaid;

   FUNCTION exportar_pcmov (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcmov';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( aliqicmfreteent,'
         || ' aliqicmoutrasdespent,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' aliqicst,'
         || ' aliqstsaida,'
         || ' aliquotatis,'
         || ' aproveitacredicms,'
         || ' baseacrescimopf,'
         || ' basebcr,'
         || ' baseicms,'
         || ' baseicmsadicional,'
         || ' baseicmsbcr,'
         || ' baseicms2,'
         || ' baseicst,'
         || ' baseivamex,'
         || ' basestsaida,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddevol,'
         || ' codecf,'
         || ' codepto,'
         || ' codequipamento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfilialretira,'
         || ' codfiscal,'
         || ' codfiscalfreteent,'
         || ' codfiscaloutrasdespent,'
         || ' codfornec,'
         || ' codfunclanc,'
         || ' codfuncquarentena,'
         || ' codfuncreq,'
         || ' codicmtab,'
         || ' codmotorista,'
         || ' codoper,'
         || ' codplpag,'
         || ' codprod,'
         || ' codprodprinc,'
         || ' codpromocao,'
         || ' codsec,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' custocont,'
         || ' custocontant,'
         || ' custofin,'
         || ' custofinant,'
         || ' custofinest,'
         || ' custoreal,'
         || ' custorealant,'
         || ' custorealsemst,'
         || ' custorealsemstant,'
         || ' custorep,'
         || ' custorepant,'
         || ' custoultent,'
         || ' custoultentant,'
         || ' custoultentant2,'
         || ' custoultentfin,'
         || ' custoultentfinant,'
         || ' custoultentmed,'
         || ' custoultentmedant,'
         || ' datafabricacao,'
         || ' datalibquarentena,'
         || ' datavalidade,'
         || ' dtcancel,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' dtmov,'
         || ' dtmovlog,'
         || ' dtultentant,'
         || ' equiplanc,'
         || ' estoquedesbloqueado,'
         || ' exportadoservint,'
         || ' fatorcustonatransf,'
         || ' funclanc,'
         || ' horalanc,'
         || ' horaproducao,'
         || ' importadoservprinc,'
         || ' indlocal,'
         || ' itemdivergente,'
         || ' iva,'
         || ' localizacao,'
         || ' minutolanc,'
         || ' numbono,'
         || ' numbonus,'
         || ' numcar,'
         || ' numformulario,'
         || ' numformulario2,'
         || ' numidf,'
         || ' numlanccp,'
         || ' numlote,'
         || ' numnegociacao,'
         || ' numnota,'
         || ' numnotadev,'
         || ' numop,'
         || ' numped,'
         || ' numregiao,'
         || ' numseq,'
         || ' numseqped,'
         || ' numtransavulsa,'
         || ' numtransdev,'
         || ' numtransdevfor,'
         || ' numtransent,'
         || ' numtransentultent,'
         || ' numtransentultentant,'
         || ' numtransop,'
         || ' numtransvenda,'
         || ' numverbaoutras,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' peracrescimopf,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percaliqext2,'
         || ' percaliqint2,'
         || ' percbasered,'
         || ' percbaseredadicional,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percbon,'
         || ' percbonoutras,'
         || ' perccredicmpresumido,'
         || ' percdesc,'
         || ' percdescfin,'
         || ' percdespadicional,'
         || ' percdespfin,'
         || ' percfrete,'
         || ' percfretefob,'
         || ' percicm,'
         || ' percicmcp,'
         || ' percicmoriginal,'
         || ' percicmred,'
         || ' percicm2,'
         || ' percimportacao,'
         || ' percimpureza,'
         || ' percinteiro,'
         || ' percipi,'
         || ' perciss,'
         || ' perciva,'
         || ' percivamex,'
         || ' perciva2,'
         || ' percmexfpgc,'
         || ' percmexieps,'
         || ' percmexiva,'
         || ' percofins,'
         || ' percom,'
         || ' percomsup,'
         || ' percom2,'
         || ' percom3,'
         || ' percoutrasdesp,'
         || ' percoutroscustos,'
         || ' percquebrado,'
         || ' percst,'
         || ' percsuframa,'
         || ' percumidade,'
         || ' percvenda,'
         || ' percvermelho,'
         || ' percvlbonific,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perfretecmv,'
         || ' pericmfrete,'
         || ' pericmguiapropria,'
         || ' pericmsantecipado,'
         || ' perpis,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' pliqped,'
         || ' prazomedio,'
         || ' precopauta,'
         || ' prodbonificado,'
         || ' promocaobiro,'
         || ' ptabela,'
         || ' ptabela2,'
         || ' punit,'
         || ' punitcont,'
         || ' punitnf,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtavaria,'
         || ' qtbloqueada,'
         || ' qtcont,'
         || ' qtcx,'
         || ' qtdevol,'
         || ' qtembalagem,'
         || ' qtestant,'
         || ' qtestgerant,'
         || ' qthoras,'
         || ' qtpecas,'
         || ' qtsaldoest,'
         || ' qtsaldoestger,'
         || ' qtultentant,'
         || ' qtvendaemb,'
         || ' qualdivergencia,'
         || ' redbasealiqext,'
         || ' redbaseiva,'
         || ' refcor,'
         || ' rotinalanc,'
         || ' sittribut,'
         || ' st,'
         || ' status,'
         || ' stbcr,'
         || ' stclientegnre,'
         || ' stsaida,'
         || ' tipodescaplicado,'
         || ' tipoitem,'
         || ' tipotis,'
         || ' txvenda,'
         || ' valorultent,'
         || ' valorultentant,'
         || ' valorultentmed,'
         || ' valorultentmedant,'
         || ' vlacrescimopf,'
         || ' vlacrescrodape,'
         || ' vladicionalbcst,'
         || ' vladuaneira,'
         || ' vlbasegnre,'
         || ' vlbaseipi,'
         || ' vlbasestforanf,'
         || ' vlbonific,'
         || ' vlbonificoutras,'
         || ' vlcredcofins,'
         || ' vlcredicms,'
         || ' vlcredicmsfrete,'
         || ' vlcredpis,'
         || ' vlcredpresumido,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescicmisencao,'
         || ' vldesconto,'
         || ' vldescpissuframa,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vldespadicional,'
         || ' vldespfin,'
         || ' vlfrete,'
         || ' vlfreteconhec,'
         || ' vlfreteporkg,'
         || ' vlicmsbcr,'
         || ' vlimportacao,'
         || ' vlindeniz,'
         || ' vlipi,'
         || ' vliss,'
         || ' vlivamex,'
         || ' vlmexfpgc,'
         || ' vlmexieps,'
         || ' vlmexiva,'
         || ' vloutrasdesp,'
         || ' vloutrasdespimp,'
         || ' vloutros,'
         || ' vlpauta2,'
         || ' vlpercbon,'
         || ' vlpis,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlsiscomex,'
         || ' vlsuframa,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT aliqicmfreteent,'
         || ' aliqicmoutrasdespent,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' aliqicst,'
         || ' aliqstsaida,'
         || ' aliquotatis,'
         || ' aproveitacredicms,'
         || ' baseacrescimopf,'
         || ' basebcr,'
         || ' baseicms,'
         || ' baseicmsadicional,'
         || ' baseicmsbcr,'
         || ' baseicms2,'
         || ' baseicst,'
         || ' baseivamex,'
         || ' basestsaida,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddevol,'
         || ' codecf,'
         || ' codepto,'
         || ' codequipamento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfilialretira,'
         || ' codfiscal,'
         || ' codfiscalfreteent,'
         || ' codfiscaloutrasdespent,'
         || ' codfornec,'
         || ' codfunclanc,'
         || ' codfuncquarentena,'
         || ' codfuncreq,'
         || ' codicmtab,'
         || ' codmotorista,'
         || ' codoper,'
         || ' codplpag,'
         || ' codprod,'
         || ' codprodprinc,'
         || ' codpromocao,'
         || ' codsec,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' custocont,'
         || ' custocontant,'
         || ' custofin,'
         || ' custofinant,'
         || ' custofinest,'
         || ' custoreal,'
         || ' custorealant,'
         || ' custorealsemst,'
         || ' custorealsemstant,'
         || ' custorep,'
         || ' custorepant,'
         || ' custoultent,'
         || ' custoultentant,'
         || ' custoultentant2,'
         || ' custoultentfin,'
         || ' custoultentfinant,'
         || ' custoultentmed,'
         || ' custoultentmedant,'
         || ' datafabricacao,'
         || ' datalibquarentena,'
         || ' datavalidade,'
         || ' dtcancel,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' dtmov,'
         || ' dtmovlog,'
         || ' dtultentant,'
         || ' equiplanc,'
         || ' estoquedesbloqueado,'
         || ' exportadoservint,'
         || ' fatorcustonatransf,'
         || ' funclanc,'
         || ' horalanc,'
         || ' horaproducao,'
         || ' importadoservprinc,'
         || ' indlocal,'
         || ' itemdivergente,'
         || ' iva,'
         || ' localizacao,'
         || ' minutolanc,'
         || ' numbono,'
         || ' numbonus,'
         || ' numcar,'
         || ' numformulario,'
         || ' numformulario2,'
         || ' numidf,'
         || ' numlanccp,'
         || ' numlote,'
         || ' numnegociacao,'
         || ' numnota,'
         || ' numnotadev,'
         || ' numop,'
         || ' numped,'
         || ' numregiao,'
         || ' numseq,'
         || ' numseqped,'
         || ' numtransavulsa,'
         || ' numtransdev,'
         || ' numtransdevfor,'
         || ' numtransent,'
         || ' numtransentultent,'
         || ' numtransentultentant,'
         || ' numtransop,'
         || ' numtransvenda,'
         || ' numverbaoutras,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' peracrescimopf,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percaliqext2,'
         || ' percaliqint2,'
         || ' percbasered,'
         || ' percbaseredadicional,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percbon,'
         || ' percbonoutras,'
         || ' perccredicmpresumido,'
         || ' percdesc,'
         || ' percdescfin,'
         || ' percdespadicional,'
         || ' percdespfin,'
         || ' percfrete,'
         || ' percfretefob,'
         || ' percicm,'
         || ' percicmcp,'
         || ' percicmoriginal,'
         || ' percicmred,'
         || ' percicm2,'
         || ' percimportacao,'
         || ' percimpureza,'
         || ' percinteiro,'
         || ' percipi,'
         || ' perciss,'
         || ' perciva,'
         || ' percivamex,'
         || ' perciva2,'
         || ' percmexfpgc,'
         || ' percmexieps,'
         || ' percmexiva,'
         || ' percofins,'
         || ' percom,'
         || ' percomsup,'
         || ' percom2,'
         || ' percom3,'
         || ' percoutrasdesp,'
         || ' percoutroscustos,'
         || ' percquebrado,'
         || ' percst,'
         || ' percsuframa,'
         || ' percumidade,'
         || ' percvenda,'
         || ' percvermelho,'
         || ' percvlbonific,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perfretecmv,'
         || ' pericmfrete,'
         || ' pericmguiapropria,'
         || ' pericmsantecipado,'
         || ' perpis,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' pliqped,'
         || ' prazomedio,'
         || ' precopauta,'
         || ' prodbonificado,'
         || ' promocaobiro,'
         || ' ptabela,'
         || ' ptabela2,'
         || ' punit,'
         || ' punitcont,'
         || ' punitnf,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtavaria,'
         || ' qtbloqueada,'
         || ' qtcont,'
         || ' qtcx,'
         || ' qtdevol,'
         || ' qtembalagem,'
         || ' qtestant,'
         || ' qtestgerant,'
         || ' qthoras,'
         || ' qtpecas,'
         || ' qtsaldoest,'
         || ' qtsaldoestger,'
         || ' qtultentant,'
         || ' qtvendaemb,'
         || ' qualdivergencia,'
         || ' redbasealiqext,'
         || ' redbaseiva,'
         || ' refcor,'
         || ' rotinalanc,'
         || ' sittribut,'
         || ' st,'
         || ' status,'
         || ' stbcr,'
         || ' stclientegnre,'
         || ' stsaida,'
         || ' tipodescaplicado,'
         || ' tipoitem,'
         || ' tipotis,'
         || ' txvenda,'
         || ' valorultent,'
         || ' valorultentant,'
         || ' valorultentmed,'
         || ' valorultentmedant,'
         || ' vlacrescimopf,'
         || ' vlacrescrodape,'
         || ' vladicionalbcst,'
         || ' vladuaneira,'
         || ' vlbasegnre,'
         || ' vlbaseipi,'
         || ' vlbasestforanf,'
         || ' vlbonific,'
         || ' vlbonificoutras,'
         || ' vlcredcofins,'
         || ' vlcredicms,'
         || ' vlcredicmsfrete,'
         || ' vlcredpis,'
         || ' vlcredpresumido,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescicmisencao,'
         || ' vldesconto,'
         || ' vldescpissuframa,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vldespadicional,'
         || ' vldespfin,'
         || ' vlfrete,'
         || ' vlfreteconhec,'
         || ' vlfreteporkg,'
         || ' vlicmsbcr,'
         || ' vlimportacao,'
         || ' vlindeniz,'
         || ' vlipi,'
         || ' vliss,'
         || ' vlivamex,'
         || ' vlmexfpgc,'
         || ' vlmexieps,'
         || ' vlmexiva,'
         || ' vloutrasdesp,'
         || ' vloutrasdespimp,'
         || ' vloutros,'
         || ' vlpauta2,'
         || ' vlpercbon,'
         || ' vlpis,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlsiscomex,'
         || ' vlsuframa,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli '
         || ' FROM pcmov '
         || ' WHERE numtransvenda IN ('
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcmov;

   FUNCTION exportar_pcprest (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcprest';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( alinea,'
         || ' boleto,'
         || ' cartorio,'
         || ' cgccpfch,'
         || ' codbaixa,'
         || ' codbanco,'
         || ' codbancocm,'
         || ' codbancocustodia,'
         || ' codbancovendor,'
         || ' codbarra,'
         || ' codbloco,'
         || ' codcli,'
         || ' codcob,'
         || ' codcobbanco,'
         || ' codcoborig,'
         || ' codcobrador,'
         || ' codepto,'
         || ' codestabelecimento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfuncbordero,'
         || ' codfunccheckout,'
         || ' codfunccxmot,'
         || ' codfuncdesd,'
         || ' codfuncdesd1,'
         || ' codfuncestorno,'
         || ' codfuncfecha,'
         || ' codfuncinc,'
         || ' codfuncultalter,'
         || ' codfuncvale,'
         || ' codfuncvend,'
         || ' codhistvale,'
         || ' codmotorista,'
         || ' codocorrbaixa,'
         || ' codportador,'
         || ' codsupervisor,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' compensacaobco,'
         || ' contratovendor,'
         || ' digitao,'
         || ' dtbaixa,'
         || ' dtborder,'
         || ' dtbordero,'
         || ' dtcancel,'
         || ' dtcustodia,'
         || ' dtcxmot,'
         || ' dtdesc,'
         || ' dtdesd,'
         || ' dtdevol,'
         || ' dtemissao,'
         || ' dtestorno,'
         || ' dtexportacaoservint,'
         || ' dtfecha,'
         || ' dtfechavendor,'
         || ' dtimportacaoservprinc,'
         || ' dtinclusao,'
         || ' dtlancch,'
         || ' dtlancprorrog,'
         || ' dtpag,'
         || ' dtpagcomissao,'
         || ' dtregcarteira,'
         || ' dtremvendor,'
         || ' dtsaida,'
         || ' dtultalter,'
         || ' dtultestorno,'
         || ' dtvenc,'
         || ' dtvencorig,'
         || ' dtvencvale,'
         || ' dtvendor,'
         || ' duplic,'
         || ' dvagencia,'
         || ' dvcheque,'
         || ' dvcob,'
         || ' dvconta,'
         || ' exportadoservint,'
         || ' geracaorazaoauxiliar,'
         || ' horadesd,'
         || ' horafecha,'
         || ' importadoservprinc,'
         || ' linhadig,'
         || ' minutodesd,'
         || ' minutofecha,'
         || ' nossonumbco,'
         || ' nossonumbco2,'
         || ' nsutef,'
         || ' numagencia,'
         || ' numbanco,'
         || ' numbordero,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcheckout,'
         || ' numcheque,'
         || ' numcontacorrente,'
         || ' numcustodia,'
         || ' numdiascarencia,'
         || ' numdiasprazoprotesto,'
         || ' numecf,'
         || ' numlotecustodia,'
         || ' numnegociacao,'
         || ' numped,'
         || ' numrecibo,'
         || ' numtrans,'
         || ' numtransentdevcli,'
         || ' numtransvenda,'
         || ' numtransvendor,'
         || ' obs,'
         || ' obsfinanc,'
         || ' obs2,'
         || ' operacao,'
         || ' percom,'
         || ' percomsup,'
         || ' percom2,'
         || ' percom3,'
         || ' perdesc,'
         || ' prest,'
         || ' rotdesd,'
         || ' status,'
         || ' tipo,'
         || ' tipoestorno,'
         || ' tipoportador,'
         || ' tipoprorrog,'
         || ' txperm,'
         || ' txvendorbco,'
         || ' txvendorcli,'
         || ' valor,'
         || ' valordesc,'
         || ' valordescorig,'
         || ' valorliqcom,'
         || ' valorliqcomsup,'
         || ' valororig,'
         || ' vlcontratovendor,'
         || ' vlcustodocvendor,'
         || ' vldevol,'
         || ' vltxboleto,'
         || ' vltxiof,'
         || ' vltxvendor,'
         || ' vpago ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT alinea,'
         || ' boleto,'
         || ' cartorio,'
         || ' cgccpfch,'
         || ' codbaixa,'
         || ' codbanco,'
         || ' codbancocm,'
         || ' codbancocustodia,'
         || ' codbancovendor,'
         || ' codbarra,'
         || ' codbloco,'
         || ' codcli,'
         || ' codcob,'
         || ' codcobbanco,'
         || ' codcoborig,'
         || ' codcobrador,'
         || ' codepto,'
         || ' codestabelecimento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfuncbordero,'
         || ' codfunccheckout,'
         || ' codfunccxmot,'
         || ' codfuncdesd,'
         || ' codfuncdesd1,'
         || ' codfuncestorno,'
         || ' codfuncfecha,'
         || ' codfuncinc,'
         || ' codfuncultalter,'
         || ' codfuncvale,'
         || ' codfuncvend,'
         || ' codhistvale,'
         || ' codmotorista,'
         || ' codocorrbaixa,'
         || ' codportador,'
         || ' codsupervisor,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' compensacaobco,'
         || ' contratovendor,'
         || ' digitao,'
         || ' dtbaixa,'
         || ' dtborder,'
         || ' dtbordero,'
         || ' dtcancel,'
         || ' dtcustodia,'
         || ' dtcxmot,'
         || ' dtdesc,'
         || ' dtdesd,'
         || ' dtdevol,'
         || ' dtemissao,'
         || ' dtestorno,'
         || ' dtexportacaoservint,'
         || ' dtfecha,'
         || ' dtfechavendor,'
         || ' dtimportacaoservprinc,'
         || ' dtinclusao,'
         || ' dtlancch,'
         || ' dtlancprorrog,'
         || ' dtpag,'
         || ' dtpagcomissao,'
         || ' dtregcarteira,'
         || ' dtremvendor,'
         || ' dtsaida,'
         || ' dtultalter,'
         || ' dtultestorno,'
         || ' dtvenc,'
         || ' dtvencorig,'
         || ' dtvencvale,'
         || ' dtvendor,'
         || ' duplic,'
         || ' dvagencia,'
         || ' dvcheque,'
         || ' dvcob,'
         || ' dvconta,'
         || ' exportadoservint,'
         || ' geracaorazaoauxiliar,'
         || ' horadesd,'
         || ' horafecha,'
         || ' importadoservprinc,'
         || ' linhadig,'
         || ' minutodesd,'
         || ' minutofecha,'
         || ' nossonumbco,'
         || ' nossonumbco2,'
         || ' nsutef,'
         || ' numagencia,'
         || ' numbanco,'
         || ' numbordero,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcheckout,'
         || ' numcheque,'
         || ' numcontacorrente,'
         || ' numcustodia,'
         || ' numdiascarencia,'
         || ' numdiasprazoprotesto,'
         || ' numecf,'
         || ' numlotecustodia,'
         || ' numnegociacao,'
         || ' numped,'
         || ' numrecibo,'
         || ' numtrans,'
         || ' numtransentdevcli,'
         || ' numtransvenda,'
         || ' numtransvendor,'
         || ' obs,'
         || ' obsfinanc,'
         || ' obs2,'
         || ' operacao,'
         || ' percom,'
         || ' percomsup,'
         || ' percom2,'
         || ' percom3,'
         || ' perdesc,'
         || ' prest,'
         || ' rotdesd,'
         || ' status,'
         || ' tipo,'
         || ' tipoestorno,'
         || ' tipoportador,'
         || ' tipoprorrog,'
         || ' txperm,'
         || ' txvendorbco,'
         || ' txvendorcli,'
         || ' valor,'
         || ' valordesc,'
         || ' valordescorig,'
         || ' valorliqcom,'
         || ' valorliqcomsup,'
         || ' valororig,'
         || ' vlcontratovendor,'
         || ' vlcustodocvendor,'
         || ' vldevol,'
         || ' vltxboleto,'
         || ' vltxiof,'
         || ' vltxvendor,'
         || ' vpago '
         || ' FROM pcprest '
         || ' WHERE numtransvenda IN ('
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcprest;

   FUNCTION exportar_pcnfbase (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcnfbase';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( aliquota,'
         || ' codcont,'
         || ' codfiscal,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' numtransent,'
         || ' numtransvenda,'
         || ' tipo,'
         || ' vlbase,'
         || ' vlbasenf,'
         || ' vlicms,'
         || ' vlisentas ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT aliquota,'
         || ' codcont,'
         || ' codfiscal,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' numtransent,'
         || ' numtransvenda,'
         || ' tipo,'
         || ' vlbase,'
         || ' vlbasenf,'
         || ' vlicms,'
         || ' vlisentas '
         || ' FROM pcnfbase '
         || ' WHERE numtransvenda IN ('
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcnfbase;

   FUNCTION exportar_pcpedc (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcpedc';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( aliqicmsfretenf,'
         || ' baixaestcli,'
         || ' baseicmsfretenf,'
         || ' broker,'
         || ' campanha,'
         || ' codatendimento,'
         || ' codcli,'
         || ' codcliconsignacao,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcontrato,'
         || ' coddistrib,'
         || ' codemitente,'
         || ' codepto,'
         || ' codestabelecimento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfornecfrete,'
         || ' codfornecvdireto,'
         || ' codfunccalcfrete,'
         || ' codfunccancel,'
         || ' codfuncconf,'
         || ' codfunccx,'
         || ' codfuncembalador,'
         || ' codfuncemissaomapa,'
         || ' codfuncexparqol,'
         || ' codfunclibera,'
         || ' codfuncprotocolo,'
         || ' codmotbloqueio,'
         || ' codmotcancel,'
         || ' codmotorista,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codprofissional,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' codveiculo,'
         || ' conciliaimportacao,'
         || ' condvenda,'
         || ' conferindopedido,'
         || ' custoentrega,'
         || ' data,'
         || ' dataexparqol,'
         || ' datapedcli,'
         || ' dataprotocolo,'
         || ' dtaberturapedpalm,'
         || ' dtagendaentrega,'
         || ' dtcalcfrete,'
         || ' dtcancel,'
         || ' dtemissaomapa,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dtexportado,'
         || ' dtfat,'
         || ' dtfechamentopedpalm,'
         || ' dtfinalcheckout,'
         || ' dtimportacaoservprinc,'
         || ' dtimportado,'
         || ' dtinicialcheckout,'
         || ' dtlibera,'
         || ' dtnftransf,'
         || ' dtvalidade,'
         || ' dtvenc1,'
         || ' dtvenc2,'
         || ' dtvenc3,'
         || ' dtwms,'
         || ' eancobranca,'
         || ' eancomprador,'
         || ' eanentrega,'
         || ' eanlocalentrega,'
         || ' especiemanif,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' geracp,'
         || ' hora,'
         || ' horaemissaomapa,'
         || ' horafat,'
         || ' horafinalsep,'
         || ' horainicialsep,'
         || ' horalibera,'
         || ' horaprotocolo,'
         || ' importacupom,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' minuto,'
         || ' minutoemissaomapa,'
         || ' minutofat,'
         || ' minutofinalsep,'
         || ' minutoinicialsep,'
         || ' minutolibera,'
         || ' minutoprotocolo,'
         || ' montando,'
         || ' motivoposicao,'
         || ' negociado,'
         || ' numcaixa,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numcarfab,'
         || ' numcarmanif,'
         || ' numcontratocorreio,'
         || ' numcupom,'
         || ' numecf,'
         || ' numempenho,'
         || ' numfonterecurso,'
         || ' numitens,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numnotaconsig,'
         || ' numnotamanif,'
         || ' numnotatransfdep,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numordemcarga,'
         || ' numped,'
         || ' numpedbnf,'
         || ' numpedcli,'
         || ' numpedecf,'
         || ' numpedentfut,'
         || ' numpedorigem,'
         || ' numpedrca,'
         || ' numpedtv3,'
         || ' numpedvale,'
         || ' numpedweb,'
         || ' numprevenda,'
         || ' numprocesso,'
         || ' numregiao,'
         || ' numseqcorreio,'
         || ' numseqentr,'
         || ' numseqentrega,'
         || ' numseqmontagem,'
         || ' numseqrota,'
         || ' numserieequip,'
         || ' numtabela,'
         || ' numtransvenda,'
         || ' numtranswms,'
         || ' numviasmapasep,'
         || ' numviaspedido,'
         || ' numvolume,'
         || ' obs,'
         || ' obsentrega1,'
         || ' obsentrega2,'
         || ' obsentrega3,'
         || ' obsfretenf1,'
         || ' obsfretenf2,'
         || ' obsfretenf3,'
         || ' obs1,'
         || ' obs2,'
         || ' operacao,'
         || ' origemped,'
         || ' pagtoantecipado,'
         || ' pedidoembalado,'
         || ' percdescabc,'
         || ' percdesccanal,'
         || ' percdesccli,'
         || ' percdescneg,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdescfin,'
         || ' posicao,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' prazo1,'
         || ' prazo10,'
         || ' prazo11,'
         || ' prazo12,'
         || ' prazo2,'
         || ' prazo3,'
         || ' prazo4,'
         || ' prazo5,'
         || ' prazo6,'
         || ' prazo7,'
         || ' prazo8,'
         || ' prazo9,'
         || ' prontaentrega,'
         || ' reservaritenstv7,'
         || ' restricaotransp,'
         || ' serieecf,'
         || ' seriemanif,'
         || ' tipocarga,'
         || ' tipocfoptv4,'
         || ' tipoembalagem,'
         || ' tipoformularionf,'
         || ' tipooper,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' tributaporregiaofilial,'
         || ' vlatend,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldescneg,'
         || ' vldesconto,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicmsfretenf,'
         || ' vloutrasdesp,'
         || ' vltabela,'
         || ' vltotal ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT aliqicmsfretenf,'
         || ' baixaestcli,'
         || ' baseicmsfretenf,'
         || ' broker,'
         || ' campanha,'
         || ' codatendimento,'
         || ' codcli,'
         || ' codcliconsignacao,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcontrato,'
         || ' coddistrib,'
         || ' codemitente,'
         || ' codepto,'
         || ' codestabelecimento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfornecfrete,'
         || ' codfornecvdireto,'
         || ' codfunccalcfrete,'
         || ' codfunccancel,'
         || ' codfuncconf,'
         || ' codfunccx,'
         || ' codfuncembalador,'
         || ' codfuncemissaomapa,'
         || ' codfuncexparqol,'
         || ' codfunclibera,'
         || ' codfuncprotocolo,'
         || ' codmotbloqueio,'
         || ' codmotcancel,'
         || ' codmotorista,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codprofissional,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' codveiculo,'
         || ' conciliaimportacao,'
         || ' condvenda,'
         || ' conferindopedido,'
         || ' custoentrega,'
         || ' data,'
         || ' dataexparqol,'
         || ' datapedcli,'
         || ' dataprotocolo,'
         || ' dtaberturapedpalm,'
         || ' dtagendaentrega,'
         || ' dtcalcfrete,'
         || ' dtcancel,'
         || ' dtemissaomapa,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dtexportado,'
         || ' dtfat,'
         || ' dtfechamentopedpalm,'
         || ' dtfinalcheckout,'
         || ' dtimportacaoservprinc,'
         || ' dtimportado,'
         || ' dtinicialcheckout,'
         || ' dtlibera,'
         || ' dtnftransf,'
         || ' dtvalidade,'
         || ' dtvenc1,'
         || ' dtvenc2,'
         || ' dtvenc3,'
         || ' dtwms,'
         || ' eancobranca,'
         || ' eancomprador,'
         || ' eanentrega,'
         || ' eanlocalentrega,'
         || ' especiemanif,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' geracp,'
         || ' hora,'
         || ' horaemissaomapa,'
         || ' horafat,'
         || ' horafinalsep,'
         || ' horainicialsep,'
         || ' horalibera,'
         || ' horaprotocolo,'
         || ' importacupom,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' minuto,'
         || ' minutoemissaomapa,'
         || ' minutofat,'
         || ' minutofinalsep,'
         || ' minutoinicialsep,'
         || ' minutolibera,'
         || ' minutoprotocolo,'
         || ' montando,'
         || ' motivoposicao,'
         || ' negociado,'
         || ' numcaixa,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numcarfab,'
         || ' numcarmanif,'
         || ' numcontratocorreio,'
         || ' numcupom,'
         || ' numecf,'
         || ' numempenho,'
         || ' numfonterecurso,'
         || ' numitens,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numnotaconsig,'
         || ' numnotamanif,'
         || ' numnotatransfdep,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numordemcarga,'
         || ' numped,'
         || ' numpedbnf,'
         || ' numpedcli,'
         || ' numpedecf,'
         || ' numpedentfut,'
         || ' numpedorigem,'
         || ' numpedrca,'
         || ' numpedtv3,'
         || ' numpedvale,'
         || ' numpedweb,'
         || ' numprevenda,'
         || ' numprocesso,'
         || ' numregiao,'
         || ' numseqcorreio,'
         || ' numseqentr,'
         || ' numseqentrega,'
         || ' numseqmontagem,'
         || ' numseqrota,'
         || ' numserieequip,'
         || ' numtabela,'
         || ' numtransvenda,'
         || ' numtranswms,'
         || ' numviasmapasep,'
         || ' numviaspedido,'
         || ' numvolume,'
         || ' obs,'
         || ' obsentrega1,'
         || ' obsentrega2,'
         || ' obsentrega3,'
         || ' obsfretenf1,'
         || ' obsfretenf2,'
         || ' obsfretenf3,'
         || ' obs1,'
         || ' obs2,'
         || ' operacao,'
         || ' origemped,'
         || ' pagtoantecipado,'
         || ' pedidoembalado,'
         || ' percdescabc,'
         || ' percdesccanal,'
         || ' percdesccli,'
         || ' percdescneg,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdescfin,'
         || ' posicao,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' prazo1,'
         || ' prazo10,'
         || ' prazo11,'
         || ' prazo12,'
         || ' prazo2,'
         || ' prazo3,'
         || ' prazo4,'
         || ' prazo5,'
         || ' prazo6,'
         || ' prazo7,'
         || ' prazo8,'
         || ' prazo9,'
         || ' prontaentrega,'
         || ' reservaritenstv7,'
         || ' restricaotransp,'
         || ' serieecf,'
         || ' seriemanif,'
         || ' tipocarga,'
         || ' tipocfoptv4,'
         || ' tipoembalagem,'
         || ' tipoformularionf,'
         || ' tipooper,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' tributaporregiaofilial,'
         || ' vlatend,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldescneg,'
         || ' vldesconto,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicmsfretenf,'
         || ' vloutrasdesp,'
         || ' vltabela,'
         || ' vltotal '
         || ' FROM pcpedc '
         || ' WHERE numped IN ('
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcpedc;

   FUNCTION exportar_pcpedi (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcpedi';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( abastecido,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' baseicst,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddegustacao,'
         || ' codecf,'
         || ' codfilialretira,'
         || ' codfuncconf,'
         || ' codfuncsep,'
         || ' codicmtab,'
         || ' codmotnaocompra,'
         || ' codplpag,'
         || ' codprod,'
         || ' codpromocao,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' condvenda,'
         || ' custofinest,'
         || ' data,'
         || ' dataconf,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' eancodprod,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' imprime,'
         || ' iva,'
         || ' letracomiss,'
         || ' localizacao,'
         || ' nomeconcorrente,'
         || ' numaplic,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numconferencia,'
         || ' numlote,'
         || ' numop,'
         || ' numped,'
         || ' numseq,'
         || ' numtira,'
         || ' numtranswms,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percbasered,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percipi,'
         || ' perciss,'
         || ' percom,'
         || ' percomprof,'
         || ' percomsup,'
         || ' percomtab,'
         || ' percom2,'
         || ' percom3,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perdesctab,'
         || ' perfretecmv,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' poriginal,'
         || ' posicao,'
         || ' prazo,'
         || ' prazomedio,'
         || ' preco,'
         || ' ptabela,'
         || ' pvenda,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtapanha,'
         || ' qtcx,'
         || ' qtembalagem,'
         || ' qtfalta,'
         || ' qtlocalizada,'
         || ' qtnaocompra,'
         || ' qtorig,'
         || ' qtoriginal,'
         || ' qtpecas,'
         || ' qtseparada,'
         || ' qtsepararcx,'
         || ' qtsepararun,'
         || ' qtvendaemb,'
         || ' refcor,'
         || ' st,'
         || ' stclientegnre,'
         || ' tipodescaplicado,'
         || ' tipopeso,'
         || ' txvenda,'
         || ' vlacrescrodape,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescfornec,'
         || ' vldescicmisencao,'
         || ' vldescpissuframa,'
         || ' vldescrepasse,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vlfrete,'
         || ' vlipi,'
         || ' vliss,'
         || ' vloutrasdesp,'
         || ' vloutros,'
         || ' vlrebaixacmv,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT abastecido,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' baseicst,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddegustacao,'
         || ' codecf,'
         || ' codfilialretira,'
         || ' codfuncconf,'
         || ' codfuncsep,'
         || ' codicmtab,'
         || ' codmotnaocompra,'
         || ' codplpag,'
         || ' codprod,'
         || ' codpromocao,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' condvenda,'
         || ' custofinest,'
         || ' data,'
         || ' dataconf,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' eancodprod,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' imprime,'
         || ' iva,'
         || ' letracomiss,'
         || ' localizacao,'
         || ' nomeconcorrente,'
         || ' numaplic,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numconferencia,'
         || ' numlote,'
         || ' numop,'
         || ' numped,'
         || ' numseq,'
         || ' numtira,'
         || ' numtranswms,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percbasered,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percipi,'
         || ' perciss,'
         || ' percom,'
         || ' percomprof,'
         || ' percomsup,'
         || ' percomtab,'
         || ' percom2,'
         || ' percom3,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perdesctab,'
         || ' perfretecmv,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' poriginal,'
         || ' posicao,'
         || ' prazo,'
         || ' prazomedio,'
         || ' preco,'
         || ' ptabela,'
         || ' pvenda,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtapanha,'
         || ' qtcx,'
         || ' qtembalagem,'
         || ' qtfalta,'
         || ' qtlocalizada,'
         || ' qtnaocompra,'
         || ' qtorig,'
         || ' qtoriginal,'
         || ' qtpecas,'
         || ' qtseparada,'
         || ' qtsepararcx,'
         || ' qtsepararun,'
         || ' qtvendaemb,'
         || ' refcor,'
         || ' st,'
         || ' stclientegnre,'
         || ' tipodescaplicado,'
         || ' tipopeso,'
         || ' txvenda,'
         || ' vlacrescrodape,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescfornec,'
         || ' vldescicmisencao,'
         || ' vldescpissuframa,'
         || ' vldescrepasse,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vlfrete,'
         || ' vlipi,'
         || ' vliss,'
         || ' vloutrasdesp,'
         || ' vloutros,'
         || ' vlrebaixacmv,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli '
         || ' FROM pcpedi '
         || ' WHERE numped IN ('
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcpedi;

   FUNCTION exportar_pcautori (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcautori';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( afetaperdesc,'
         || ' basecreddebrca,'
         || ' codauxiliar,'
         || ' codcli,'
         || ' codfilial,'
         || ' codfunccadastro,'
         || ' codfuncutiliz,'
         || ' codplpag,'
         || ' codprod,'
         || ' codusur,'
         || ' dataautorizacao,'
         || ' data_utilizacao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' excedecota,'
         || ' exportadoservint,'
         || ' fimintervalo,'
         || ' geradebrca,'
         || ' importadoservprinc,'
         || ' iniciointervalo,'
         || ' nrautorizacao,'
         || ' numcaixa,'
         || ' numcupom,'
         || ' numped,'
         || ' numregiao,'
         || ' obs,'
         || ' percdescautor,'
         || ' pvendaatual,'
         || ' pvendido,'
         || ' qtvendaecf,'
         || ' serieequip,'
         || ' statusutiliz ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT afetaperdesc,'
         || ' basecreddebrca,'
         || ' codauxiliar,'
         || ' codcli,'
         || ' codfilial,'
         || ' codfunccadastro,'
         || ' codfuncutiliz,'
         || ' codplpag,'
         || ' codprod,'
         || ' codusur,'
         || ' dataautorizacao,'
         || ' data_utilizacao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' excedecota,'
         || ' exportadoservint,'
         || ' fimintervalo,'
         || ' geradebrca,'
         || ' importadoservprinc,'
         || ' iniciointervalo,'
         || ' nrautorizacao,'
         || ' numcaixa,'
         || ' numcupom,'
         || ' numped,'
         || ' numregiao,'
         || ' obs,'
         || ' percdescautor,'
         || ' pvendaatual,'
         || ' pvendido,'
         || ' qtvendaecf,'
         || ' serieequip,'
         || ' statusutiliz '
         || ' FROM pcautori '
         || ' WHERE numped IN ('
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcautori;

   FUNCTION exportar_pcvendaconsum (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcvendaconsum';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( bairroent,'
         || ' cepent,'
         || ' cgcent,'
         || ' cliente,'
         || ' codcidade,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' enderent,'
         || ' estent,'
         || ' exportadoservint,'
         || ' ieent,'
         || ' importadoservprinc,'
         || ' municent,'
         || ' nomecontato,'
         || ' numped,'
         || ' obs,'
         || ' obscontato,'
         || ' telefonecontato,'
         || ' telent ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT bairroent,'
         || ' cepent,'
         || ' cgcent,'
         || ' cliente,'
         || ' codcidade,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' enderent,'
         || ' estent,'
         || ' exportadoservint,'
         || ' ieent,'
         || ' importadoservprinc,'
         || ' municent,'
         || ' nomecontato,'
         || ' numped,'
         || ' obs,'
         || ' obscontato,'
         || ' telefonecontato,'
         || ' telent '
         || ' FROM pcvendaconsum '
         || ' WHERE numped IN ('
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.numped'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcvendaconsum;

   FUNCTION exportar_pcservintervendas (
      pscodfilial   IN       VARCHAR2,
      psmsg         OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcservintervendas';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      --> .dat intermediario -> principal
      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codfilial,'
         || ' codfunccx,'
         || ' data,'
         || ' dtexportacao,'
         || ' dtimportacao,'
         || ' itens_exp_pcautori,'
         || ' itens_exp_pcmov,'
         || ' itens_exp_pcnfbase,'
         || ' itens_exp_pcnfsaid,'
         || ' itens_exp_pcpedc,'
         || ' itens_exp_pcpedi,'
         || ' itens_exp_pcprest,'
         || ' itens_exp_pcvendaconsum,'
         || ' itens_imp_pcautori,'
         || ' itens_imp_pcmov,'
         || ' itens_imp_pcnfbase,'
         || ' itens_imp_pcnfsaid,'
         || ' itens_imp_pcpedc,'
         || ' itens_imp_pcpedi,'
         || ' itens_imp_pcprest,'
         || ' itens_imp_pcvendaconsum,'
         || ' numcaixa,'
         || ' numped,'
         || ' numpedecf,'
         || ' numserieequip,'
         || ' numtransvendaecf,'
         || ' numtransvendawinthor,'
         || ' serieecf,'
         || ' status ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codfilial,'
         || ' codfunccx,'
         || ' data,'
         || ' dtexportacao,'
         || ' dtimportacao,'
         || ' itens_exp_pcautori,'
         || ' itens_exp_pcmov,'
         || ' itens_exp_pcnfbase,'
         || ' itens_exp_pcnfsaid,'
         || ' itens_exp_pcpedc,'
         || ' itens_exp_pcpedi,'
         || ' itens_exp_pcprest,'
         || ' itens_exp_pcvendaconsum,'
         || ' itens_imp_pcautori,'
         || ' itens_imp_pcmov,'
         || ' itens_imp_pcnfbase,'
         || ' itens_imp_pcnfsaid,'
         || ' itens_imp_pcpedc,'
         || ' itens_imp_pcpedi,'
         || ' itens_imp_pcprest,'
         || ' itens_imp_pcvendaconsum,'
         || ' numcaixa,'
         || ' numped,'
         || ' numpedecf,'
         || ' numserieequip,'
         || ' numtransvendaecf,'
         || ' numtransvendawinthor,'
         || ' serieecf,'
         || ' status '
         || ' FROM pcservintervendas '
         || ' WHERE (codfilial, numtransvendaecf) IN ('
         || '  SELECT n.codfilial, n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND ((n.codcob <> ''BK'') AND (NVL (c.boleto, ''N'') = ''N''))'
         || '   UNION'
         || '  SELECT n.codfilial, n.numtransvenda'
         || '    FROM pcnfsaid n, pccob c'
         || '   WHERE n.dtsaida >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '     AND n.codfilial = '''
         || pscodfilial
         || ''''
         || '     AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '     AND n.dtcancel IS NULL'
         || '     AND n.codcob = c.codcob'
         || '     AND (    (   (n.codcob = ''BK'')'
         || '         OR (NVL (c.boleto, ''N'') = ''S''))'
         || '     AND NOT EXISTS ('
         || '       SELECT *'
         || '         FROM pcprest pr'
         || '        WHERE pr.numtransvenda = n.numtransvenda'
         || '          AND pr.dtpag IS NULL'
         || '          AND pr.codcob NOT IN'
         || '                 (''DESD'', ''DEVP'', ''DEVT'')'
         || '          AND pr.codbarra IS NULL)))';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcservintervendas;

   PROCEDURE executar_exportacao (pscodfilial VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vsmsg        VARCHAR2 (1000);
      vsmensagem   VARCHAR2 (1000);
   BEGIN
      vsmensagem := ' ';
      exportar_vendas (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ' '
      THEN
         vsmensagem := vsmensagem || '; exportar_vendas: ' || vsmsg;
      END IF;

      exportar_cancelamentos (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ' '
      THEN
         vsmensagem := vsmensagem || '; exportar_cancelamentos: ' || vsmsg;
      END IF;

      exportar_sangrias (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ' '
      THEN
         vsmensagem := vsmensagem || '; exportar_sangrias: ' || vsmsg;
      END IF;

      exportar_reducoes (pscodfilial, vsmsg);

      IF NVL (vsmsg, ' ') <> ' '
      THEN
         vsmensagem := vsmensagem || '; exportar_reducoes: ' || vsmsg;
      END IF;

      IF NVL (vsmensagem, ' ') = ' '
      THEN
         vsmensagem := 'OK';
      END IF;

      psmensagem := vsmensagem;
   END executar_exportacao;

   PROCEDURE exportar_vendas (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vnnumtransvenda    NUMBER;
      vnnumped           NUMBER;
      vsmensagem         VARCHAR2 (2000);
      vsmsg              VARCHAR2 (2000);
      exc_geracaodados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vsmsg := '';

      BEGIN
         BEGIN
            -- Marcar como X as NFs nao exportadas
            UPDATE pcnfsaid
               SET exportadoservint = 'X'
             WHERE numtransvenda IN (
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'N'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'N'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar itens das NFs a serem exportadas
            UPDATE pcmov
               SET exportadoservint = 'X'
             WHERE numtransvenda IN (
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar base de icms de nfs a serem exportadas
            UPDATE pcnfbase
               SET exportadoservint = 'X'
             WHERE numtransvenda IN (
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar contas a receber de nfs a serem exportadas
            UPDATE pcprest
               SET exportadoservint = 'X'
             WHERE numtransvenda IN (
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numtransvenda
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar pedidos a serem exportados
            UPDATE pcpedc
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar itens de pedidos a serem exportados
            UPDATE pcpedi
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar autorizações a serem exportadas
            UPDATE pcautori
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));

            -- Marcar dados de consumidor final a serem exportados
            UPDATE pcvendaconsum
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- Nao e boleto
                         AND (    (n.codcob <> 'BK')
                              AND (NVL (c.boleto, 'N') = 'N')
                             )
                      UNION
                      SELECT n.numped
                        FROM pcnfsaid n, pccob c
                       WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                         AND n.codfilial = pscodfilial
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NULL
                         AND n.codcob = c.codcob
                         -- E boleto e ja foi emitido
                         AND (    (   (n.codcob = 'BK')
                                   OR (NVL (c.boleto, 'N') = 'S')
                                  )
                              AND NOT EXISTS (
                                     SELECT *
                                       FROM pcprest pr
                                      WHERE pr.numtransvenda = n.numtransvenda
                                        AND pr.dtpag IS NULL
                                        AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                        AND pr.codbarra IS NULL)
                             ));
         EXCEPTION
            WHEN OTHERS
            THEN
               vsmensagem :=
                     'Nao foi possivel marcar registros de vendas para exportacao. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;

         IF NOT exportar_pcnfsaid (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                      'Não foi possível exportar o PCNFSAID. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcmov (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                         'Não foi possível exportar o PCMOV. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcprest (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                       'Não foi possível exportar o PCPREST. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcnfbase (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                      'Não foi possível exportar o PCNFBASE. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcpedc (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                        'Não foi possível exportar o PCPEDC. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcpedi (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                        'Não foi possível exportar o PCPEDI. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcautori (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                      'Não foi possível exportar o PCAUTORI. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcvendaconsum (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                 'Não foi possível exportar o PCVENDACONSUM. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         -- Gerar dados do log e exportá-lo
         BEGIN
            MERGE INTO pcservintervendas d
               USING (SELECT pcnfsaid.codfilial, pcnfsaid.numtransvenda,
                             pcnfsaid.dtsaida, pcpedc.serieecf,
                             (SELECT pcpedcecf.numpedecf
                                FROM pcpedcecf
                               WHERE numped = pcnfsaid.numped
                                 AND numcaixa = pcpedc.numcaixa
                                 AND codfunccx = pcpedc.codfunccx
                                 AND numserieequip = pcpedc.numserieequip
                                 AND codfilial = pcpedc.codfilial
                                 AND ROWNUM = 1) numpedecf,
                             pcpedc.numcaixa, pcpedc.codfunccx,
                             pcpedc.numserieequip, pcpedc.numped,
                             SYSDATE dtexportacao, 'E' status,
                             1 itens_exp_pcnfsaid,
                             (SELECT COUNT (*)
                                FROM pcmov
                               WHERE numtransvenda =
                                        pcnfsaid.numtransvenda)
                                                             itens_exp_pcmov,
                             (SELECT COUNT (*)
                                FROM pcprest
                               WHERE numtransvenda =
                                        pcnfsaid.numtransvenda)
                                                           itens_exp_pcprest,
                             (SELECT COUNT (*)
                                FROM pcnfbase
                               WHERE numtransvenda =
                                        pcnfsaid.numtransvenda)
                                                          itens_exp_pcnfbase,
                             1 itens_exp_pcpedc,
                             (SELECT COUNT (*)
                                FROM pcpedi
                               WHERE numped =
                                             pcnfsaid.numped)
                                                            itens_exp_pcpedi,
                             (SELECT COUNT (*)
                                FROM pcautori
                               WHERE numped =
                                           pcnfsaid.numped)
                                                          itens_exp_pcautori,
                             (SELECT COUNT (*)
                                FROM pcvendaconsum
                               WHERE numped =
                                        pcnfsaid.numped)
                                                     itens_exp_pcvendaconsum
                        FROM pcnfsaid, pcpedc
                       WHERE pcnfsaid.numped = pcpedc.numped
                         AND pcnfsaid.numtransvenda IN (
                                SELECT n.numtransvenda
                                  FROM pcnfsaid n, pccob c
                                 WHERE n.dtsaida >= TRUNC (SYSDATE)
                                                    - vgnumdias
                                   AND n.codfilial = pscodfilial
                                   AND NVL (n.exportadoservint, 'N') = 'X'
                                   AND n.dtcancel IS NULL
                                   AND n.codcob = c.codcob
                                   -- Nao e boleto
                                   AND (    (n.codcob <> 'BK')
                                        AND (NVL (c.boleto, 'N') = 'N')
                                       )
                                UNION
                                SELECT n.numtransvenda
                                  FROM pcnfsaid n, pccob c
                                 WHERE n.dtsaida >= TRUNC (SYSDATE)
                                                    - vgnumdias
                                   AND n.codfilial = pscodfilial
                                   AND NVL (n.exportadoservint, 'N') = 'X'
                                   AND n.dtcancel IS NULL
                                   AND n.codcob = c.codcob
                                   -- E boleto e ja foi emitido
                                   AND (    (   (n.codcob = 'BK')
                                             OR (NVL (c.boleto, 'N') = 'S')
                                            )
                                        AND NOT EXISTS (
                                               SELECT *
                                                 FROM pcprest pr
                                                WHERE pr.numtransvenda =
                                                               n.numtransvenda
                                                  AND pr.dtpag IS NULL
                                                  AND pr.codcob NOT IN
                                                         ('DESD',
                                                          'DEVP',
                                                          'DEVT'
                                                         )
                                                  AND pr.codbarra IS NULL)
                                       ))) s
               ON (    (d.codfilial = s.codfilial)
                   AND (d.numtransvendaecf = s.numtransvenda))
               WHEN MATCHED THEN
                  UPDATE
                     SET d.DATA = s.dtsaida, d.serieecf = s.serieecf,
                         d.numpedecf = s.numpedecf, d.numcaixa = s.numcaixa,
                         d.codfunccx = s.codfunccx,
                         d.numserieequip = s.numserieequip,
                         d.numped = s.numped, d.dtexportacao = s.dtexportacao,
                         d.status = s.status,
                         d.itens_exp_pcnfsaid = s.itens_exp_pcnfsaid,
                         d.itens_exp_pcmov = s.itens_exp_pcmov,
                         d.itens_exp_pcprest = s.itens_exp_pcprest,
                         d.itens_exp_pcnfbase = s.itens_exp_pcnfbase,
                         d.itens_exp_pcpedc = s.itens_exp_pcpedc,
                         d.itens_exp_pcpedi = s.itens_exp_pcpedi,
                         d.itens_exp_pcautori = s.itens_exp_pcautori,
                         d.itens_exp_pcvendaconsum = s.itens_exp_pcvendaconsum
               WHEN NOT MATCHED THEN
                  INSERT (codfilial, numtransvendaecf, DATA, serieecf,
                          numpedecf, numcaixa, codfunccx, numserieequip,
                          numped, dtexportacao, status, itens_exp_pcnfsaid,
                          itens_exp_pcmov, itens_exp_pcprest,
                          itens_exp_pcnfbase, itens_exp_pcpedc,
                          itens_exp_pcpedi, itens_exp_pcautori,
                          itens_exp_pcvendaconsum)
                  VALUES (s.codfilial, s.numtransvenda, s.dtsaida, s.serieecf,
                          s.numpedecf, s.numcaixa, s.codfunccx,
                          s.numserieequip, s.numped, s.dtexportacao, s.status,
                          s.itens_exp_pcnfsaid, s.itens_exp_pcmov,
                          s.itens_exp_pcprest, s.itens_exp_pcnfbase,
                          s.itens_exp_pcpedc, s.itens_exp_pcpedi,
                          s.itens_exp_pcautori, s.itens_exp_pcvendaconsum);
         EXCEPTION
            WHEN OTHERS
            THEN
               vsmensagem :=
                     'ABORTAR_OPERACAO '
                  || 'Erro na geração do log de exportação de vendas. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;

         IF NOT exportar_pcservintervendas (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                  'Não foi possível exportar o PCSERVINTERVENDAS. Erro: '
               || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         UPDATE pcmov
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numtransvenda IN (
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcnfbase
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numtransvenda IN (
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcprest
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numtransvenda IN (
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcpedc
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcpedi
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcautori
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcvendaconsum
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numped
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         UPDATE pcnfsaid
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numtransvenda IN (
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- Nao e boleto
                      AND ((n.codcob <> 'BK') AND (NVL (c.boleto, 'N') = 'N')
                          )
                   UNION
                   SELECT n.numtransvenda
                     FROM pcnfsaid n, pccob c
                    WHERE n.dtsaida >= TRUNC (SYSDATE) - vgnumdias
                      AND n.codfilial = pscodfilial
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NULL
                      AND n.codcob = c.codcob
                      -- E boleto e ja foi emitido
                      AND (    (   (n.codcob = 'BK')
                                OR (NVL (c.boleto, 'N') = 'S')
                               )
                           AND NOT EXISTS (
                                  SELECT *
                                    FROM pcprest pr
                                   WHERE pr.numtransvenda = n.numtransvenda
                                     AND pr.dtpag IS NULL
                                     AND pr.codcob NOT IN
                                                     ('DESD', 'DEVP', 'DEVT')
                                     AND pr.codbarra IS NULL)
                          ));

         COMMIT;
         psmensagem := vsmensagem;
      EXCEPTION
         WHEN exc_geracaodados
         THEN
            ROLLBACK;
            psmensagem := 'ABORTAR_OPERACAO ' || vsmensagem;
         WHEN OTHERS
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;
      END;
   END exportar_vendas;

   FUNCTION exportar_pcpedccancecf (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcpedccancecf';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codcli,'
         || ' codcob,'
         || ' codemitente,'
         || ' codfilial,'
         || ' codfunccancel,'
         || ' codfunccancelecf,'
         || ' codfunccx,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codsupervisor,'
         || ' codusur,'
         || ' condvenda,'
         || ' data,'
         || ' dtcancel,'
         || ' dtcancelecf,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dtfat,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' hora,'
         || ' horafat,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' minuto,'
         || ' minutofat,'
         || ' numcaixa,'
         || ' numcar,'
         || ' numcupom,'
         || ' numecf,'
         || ' numitens,'
         || ' numped,'
         || ' numpedecf,'
         || ' numserieequip,'
         || ' numtransvenda,'
         || ' numviasmapasep,'
         || ' operacao,'
         || ' percvenda,'
         || ' posicaopedido,'
         || ' posicaoretorno,'
         || ' prazomedio,'
         || ' prazo1,'
         || ' prazo10,'
         || ' prazo11,'
         || ' prazo12,'
         || ' prazo2,'
         || ' prazo3,'
         || ' prazo4,'
         || ' prazo5,'
         || ' prazo6,'
         || ' prazo7,'
         || ' prazo8,'
         || ' prazo9,'
         || ' serieecf,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvolume,'
         || ' vlatend,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesconto,'
         || ' vloutrasdesp,'
         || ' vltabela,'
         || ' vltotal ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codcli,'
         || ' codcob,'
         || ' codemitente,'
         || ' codfilial,'
         || ' codfunccancel,'
         || ' codfunccancelecf,'
         || ' codfunccx,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codsupervisor,'
         || ' codusur,'
         || ' condvenda,'
         || ' data,'
         || ' dtcancel,'
         || ' dtcancelecf,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dtfat,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' hora,'
         || ' horafat,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' minuto,'
         || ' minutofat,'
         || ' numcaixa,'
         || ' numcar,'
         || ' numcupom,'
         || ' numecf,'
         || ' numitens,'
         || ' numped,'
         || ' numpedecf,'
         || ' numserieequip,'
         || ' numtransvenda,'
         || ' numviasmapasep,'
         || ' operacao,'
         || ' percvenda,'
         || ' posicaopedido,'
         || ' posicaoretorno,'
         || ' prazomedio,'
         || ' prazo1,'
         || ' prazo10,'
         || ' prazo11,'
         || ' prazo12,'
         || ' prazo2,'
         || ' prazo3,'
         || ' prazo4,'
         || ' prazo5,'
         || ' prazo6,'
         || ' prazo7,'
         || ' prazo8,'
         || ' prazo9,'
         || ' serieecf,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvolume,'
         || ' vlatend,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesconto,'
         || ' vloutrasdesp,'
         || ' vltabela,'
         || ' vltotal '
         || ' FROM pcpedccancecf'
         || ' WHERE DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || ' AND NVL (exportadoservint, ''N'') = ''X''';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcpedccancecf;

   FUNCTION exportar_pcpedicancecf (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcpedicancecf';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codauxiliar,'
         || ' codcli,'
         || ' codfilial,'
         || ' codfunccancel,'
         || ' codfunccancelecf,'
         || ' codfunccx,'
         || ' codprod,'
         || ' codst,'
         || ' codusur,'
         || ' data,'
         || ' dtcancel,'
         || ' dtcancelecf,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' numcaixa,'
         || ' numcar,'
         || ' numped,'
         || ' numpedecf,'
         || ' numseq,'
         || ' numserieequip,'
         || ' percbasered,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percicm,'
         || ' percipi,'
         || ' percom,'
         || ' perdesc,'
         || ' perfretecmv,'
         || ' poriginal,'
         || ' posicaoretorno,'
         || ' ptabela,'
         || ' pvenda,'
         || ' qt,'
         || ' qtfalta,'
         || ' st,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vlipi ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codauxiliar,'
         || ' codcli,'
         || ' codfilial,'
         || ' codfunccancel,'
         || ' codfunccancelecf,'
         || ' codfunccx,'
         || ' codprod,'
         || ' codst,'
         || ' codusur,'
         || ' data,'
         || ' dtcancel,'
         || ' dtcancelecf,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' numcaixa,'
         || ' numcar,'
         || ' numped,'
         || ' numpedecf,'
         || ' numseq,'
         || ' numserieequip,'
         || ' percbasered,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percicm,'
         || ' percipi,'
         || ' percom,'
         || ' perdesc,'
         || ' perfretecmv,'
         || ' poriginal,'
         || ' posicaoretorno,'
         || ' ptabela,'
         || ' pvenda,'
         || ' qt,'
         || ' qtfalta,'
         || ' st,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vlipi '
         || ' FROM pcpedicancecf '
         || ' WHERE (numpedecf, codfunccx, numcaixa, numserieequip) IN ('
         || '      SELECT c.numpedecf, c.codfunccx, c.numcaixa,'
         || '             c.numserieequip'
         || '        FROM pcpedccancecf c'
         || '       WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '         AND NVL (c.exportadoservint, ''N'') = ''X'')';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcpedicancecf;

   FUNCTION exportar_pcnfcan (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcnfcan';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codcli,'
         || ' codcob,'
         || ' codfilial,'
         || ' codfornec,'
         || ' codfunccanc,'
         || ' codfuncemite,'
         || ' codplpag,'
         || ' codrotina,'
         || ' codusur,'
         || ' condvenda,'
         || ' datacanc,'
         || ' dataemissao,'
         || ' descricao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' motivo,'
         || ' numcar,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numped,'
         || ' numpedcompra,'
         || ' numpedrca,'
         || ' numtransent,'
         || ' numtransvenda,'
         || ' numtransvendaecf,'
         || ' origemped,'
         || ' totpeso,'
         || ' totvolume,'
         || ' vltotal ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codcli,'
         || ' codcob,'
         || ' codfilial,'
         || ' codfornec,'
         || ' codfunccanc,'
         || ' codfuncemite,'
         || ' codplpag,'
         || ' codrotina,'
         || ' codusur,'
         || ' condvenda,'
         || ' datacanc,'
         || ' dataemissao,'
         || ' descricao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' motivo,'
         || ' numcar,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numped,'
         || ' numpedcompra,'
         || ' numpedrca,'
         || ' numtransent,'
         || ' numtransvenda,'
         || ' numtransvendaecf,'
         || ' origemped,'
         || ' totpeso,'
         || ' totvolume,'
         || ' vltotal'
         || '   FROM pcnfcan '
         || '  WHERE numped IN ('
         || '    SELECT p.numped'
         || '      FROM pcpedc p'
         || '     WHERE (p.codfilial,'
         || '            p.DATA,'
         || '            p.numpedecf,'
         || '            p.serieecf,'
         || '            p.codfunccx,'
         || '            p.numcaixa,'
         || '            p.numserieequip ) IN ('
         || '      SELECT c.codfilial, c.DATA, c.numpedecf,'
         || '             c.serieecf, c.codfunccx, c.numcaixa,'
         || '             c.numserieequip'
         || '        FROM pcpedccancecf c'
         || '       WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '         AND NVL (c.exportadoservint, ''N'') = ''X'')'
         || '       AND NVL (p.exportadoservint, ''N'') = ''X'''
         || '       AND p.posicao = ''C'')';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcnfcan;

   FUNCTION exportar_pcnfcanitem (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcnfcanitem';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codcli,'
         || ' codfornec,'
         || ' codfunccanc,'
         || ' codfuncemite,'
         || ' codprod,'
         || ' codrotina,'
         || ' codusur,'
         || ' datacanc,'
         || ' dataemissao,'
         || ' descricao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' motivo,'
         || ' numcar,'
         || ' numorca,'
         || ' numped,'
         || ' numpedcompra,'
         || ' numseq,'
         || ' numtransent,'
         || ' numtransvenda,'
         || ' pbaserca,'
         || ' ptabela,'
         || ' pvenda,'
         || ' qt ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codcli,'
         || ' codfornec,'
         || ' codfunccanc,'
         || ' codfuncemite,'
         || ' codprod,'
         || ' codrotina,'
         || ' codusur,'
         || ' datacanc,'
         || ' dataemissao,'
         || ' descricao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' motivo,'
         || ' numcar,'
         || ' numorca,'
         || ' numped,'
         || ' numpedcompra,'
         || ' numseq,'
         || ' numtransent,'
         || ' numtransvenda,'
         || ' pbaserca,'
         || ' ptabela,'
         || ' pvenda,'
         || ' qt'
         || '   FROM pcnfcanitem '
         || '  WHERE numped IN ('
         || '    SELECT p.numped'
         || '      FROM pcpedc p'
         || '     WHERE (p.codfilial,'
         || '            p.DATA,'
         || '            p.numpedecf,'
         || '            p.serieecf,'
         || '            p.codfunccx,'
         || '            p.numcaixa,'
         || '            p.numserieequip ) IN ('
         || '      SELECT c.codfilial, c.DATA, c.numpedecf,'
         || '             c.serieecf, c.codfunccx, c.numcaixa,'
         || '             c.numserieequip'
         || '        FROM pcpedccancecf c'
         || '       WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '         AND NVL (c.exportadoservint, ''N'') = ''X'')'
         || '       AND NVL (p.exportadoservint, ''N'') = ''X'''
         || '       AND p.posicao = ''C'')';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcnfcanitem;

   FUNCTION exportar_can_pcpedc (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'can_pcpedc';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( aliqicmsfretenf,'
         || ' baixaestcli,'
         || ' baseicmsfretenf,'
         || ' broker,'
         || ' campanha,'
         || ' codatendimento,'
         || ' codcli,'
         || ' codcliconsignacao,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcontrato,'
         || ' coddistrib,'
         || ' codemitente,'
         || ' codepto,'
         || ' codestabelecimento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfornecfrete,'
         || ' codfornecvdireto,'
         || ' codfunccalcfrete,'
         || ' codfunccancel,'
         || ' codfuncconf,'
         || ' codfunccx,'
         || ' codfuncembalador,'
         || ' codfuncemissaomapa,'
         || ' codfuncexparqol,'
         || ' codfunclibera,'
         || ' codfuncprotocolo,'
         || ' codmotbloqueio,'
         || ' codmotcancel,'
         || ' codmotorista,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codprofissional,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' codveiculo,'
         || ' conciliaimportacao,'
         || ' condvenda,'
         || ' conferindopedido,'
         || ' custoentrega,'
         || ' data,'
         || ' dataexparqol,'
         || ' datapedcli,'
         || ' dataprotocolo,'
         || ' dtaberturapedpalm,'
         || ' dtagendaentrega,'
         || ' dtcalcfrete,'
         || ' dtcancel,'
         || ' dtemissaomapa,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dtexportado,'
         || ' dtfat,'
         || ' dtfechamentopedpalm,'
         || ' dtfinalcheckout,'
         || ' dtimportacaoservprinc,'
         || ' dtimportado,'
         || ' dtinicialcheckout,'
         || ' dtlibera,'
         || ' dtnftransf,'
         || ' dtvalidade,'
         || ' dtvenc1,'
         || ' dtvenc2,'
         || ' dtvenc3,'
         || ' dtwms,'
         || ' eancobranca,'
         || ' eancomprador,'
         || ' eanentrega,'
         || ' eanlocalentrega,'
         || ' especiemanif,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' geracp,'
         || ' hora,'
         || ' horaemissaomapa,'
         || ' horafat,'
         || ' horafinalsep,'
         || ' horainicialsep,'
         || ' horalibera,'
         || ' horaprotocolo,'
         || ' importacupom,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' minuto,'
         || ' minutoemissaomapa,'
         || ' minutofat,'
         || ' minutofinalsep,'
         || ' minutoinicialsep,'
         || ' minutolibera,'
         || ' minutoprotocolo,'
         || ' montando,'
         || ' motivoposicao,'
         || ' negociado,'
         || ' numcaixa,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numcarfab,'
         || ' numcarmanif,'
         || ' numcontratocorreio,'
         || ' numcupom,'
         || ' numecf,'
         || ' numempenho,'
         || ' numfonterecurso,'
         || ' numitens,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numnotaconsig,'
         || ' numnotamanif,'
         || ' numnotatransfdep,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numordemcarga,'
         || ' numped,'
         || ' numpedbnf,'
         || ' numpedcli,'
         || ' numpedecf,'
         || ' numpedentfut,'
         || ' numpedorigem,'
         || ' numpedrca,'
         || ' numpedtv3,'
         || ' numpedvale,'
         || ' numpedweb,'
         || ' numprevenda,'
         || ' numprocesso,'
         || ' numregiao,'
         || ' numseqcorreio,'
         || ' numseqentr,'
         || ' numseqentrega,'
         || ' numseqmontagem,'
         || ' numseqrota,'
         || ' numserieequip,'
         || ' numtabela,'
         || ' numtransvenda,'
         || ' numtranswms,'
         || ' numviasmapasep,'
         || ' numviaspedido,'
         || ' numvolume,'
         || ' obs,'
         || ' obsentrega1,'
         || ' obsentrega2,'
         || ' obsentrega3,'
         || ' obsfretenf1,'
         || ' obsfretenf2,'
         || ' obsfretenf3,'
         || ' obs1,'
         || ' obs2,'
         || ' operacao,'
         || ' origemped,'
         || ' pagtoantecipado,'
         || ' pedidoembalado,'
         || ' percdescabc,'
         || ' percdesccanal,'
         || ' percdesccli,'
         || ' percdescneg,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdescfin,'
         || ' posicao,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' prazo1,'
         || ' prazo10,'
         || ' prazo11,'
         || ' prazo12,'
         || ' prazo2,'
         || ' prazo3,'
         || ' prazo4,'
         || ' prazo5,'
         || ' prazo6,'
         || ' prazo7,'
         || ' prazo8,'
         || ' prazo9,'
         || ' prontaentrega,'
         || ' reservaritenstv7,'
         || ' restricaotransp,'
         || ' serieecf,'
         || ' seriemanif,'
         || ' tipocarga,'
         || ' tipocfoptv4,'
         || ' tipoembalagem,'
         || ' tipoformularionf,'
         || ' tipooper,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' tributaporregiaofilial,'
         || ' vlatend,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldescneg,'
         || ' vldesconto,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicmsfretenf,'
         || ' vloutrasdesp,'
         || ' vltabela,'
         || ' vltotal ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT aliqicmsfretenf,'
         || ' baixaestcli,'
         || ' baseicmsfretenf,'
         || ' broker,'
         || ' campanha,'
         || ' codatendimento,'
         || ' codcli,'
         || ' codcliconsignacao,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcontrato,'
         || ' coddistrib,'
         || ' codemitente,'
         || ' codepto,'
         || ' codestabelecimento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfornecfrete,'
         || ' codfornecvdireto,'
         || ' codfunccalcfrete,'
         || ' codfunccancel,'
         || ' codfuncconf,'
         || ' codfunccx,'
         || ' codfuncembalador,'
         || ' codfuncemissaomapa,'
         || ' codfuncexparqol,'
         || ' codfunclibera,'
         || ' codfuncprotocolo,'
         || ' codmotbloqueio,'
         || ' codmotcancel,'
         || ' codmotorista,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codprofissional,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' codveiculo,'
         || ' conciliaimportacao,'
         || ' condvenda,'
         || ' conferindopedido,'
         || ' custoentrega,'
         || ' data,'
         || ' dataexparqol,'
         || ' datapedcli,'
         || ' dataprotocolo,'
         || ' dtaberturapedpalm,'
         || ' dtagendaentrega,'
         || ' dtcalcfrete,'
         || ' dtcancel,'
         || ' dtemissaomapa,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dtexportado,'
         || ' dtfat,'
         || ' dtfechamentopedpalm,'
         || ' dtfinalcheckout,'
         || ' dtimportacaoservprinc,'
         || ' dtimportado,'
         || ' dtinicialcheckout,'
         || ' dtlibera,'
         || ' dtnftransf,'
         || ' dtvalidade,'
         || ' dtvenc1,'
         || ' dtvenc2,'
         || ' dtvenc3,'
         || ' dtwms,'
         || ' eancobranca,'
         || ' eancomprador,'
         || ' eanentrega,'
         || ' eanlocalentrega,'
         || ' especiemanif,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' geracp,'
         || ' hora,'
         || ' horaemissaomapa,'
         || ' horafat,'
         || ' horafinalsep,'
         || ' horainicialsep,'
         || ' horalibera,'
         || ' horaprotocolo,'
         || ' importacupom,'
         || ' importado,'
         || ' importadoservprinc,'
         || ' minuto,'
         || ' minutoemissaomapa,'
         || ' minutofat,'
         || ' minutofinalsep,'
         || ' minutoinicialsep,'
         || ' minutolibera,'
         || ' minutoprotocolo,'
         || ' montando,'
         || ' motivoposicao,'
         || ' negociado,'
         || ' numcaixa,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numcarfab,'
         || ' numcarmanif,'
         || ' numcontratocorreio,'
         || ' numcupom,'
         || ' numecf,'
         || ' numempenho,'
         || ' numfonterecurso,'
         || ' numitens,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numnotaconsig,'
         || ' numnotamanif,'
         || ' numnotatransfdep,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numordemcarga,'
         || ' numped,'
         || ' numpedbnf,'
         || ' numpedcli,'
         || ' numpedecf,'
         || ' numpedentfut,'
         || ' numpedorigem,'
         || ' numpedrca,'
         || ' numpedtv3,'
         || ' numpedvale,'
         || ' numpedweb,'
         || ' numprevenda,'
         || ' numprocesso,'
         || ' numregiao,'
         || ' numseqcorreio,'
         || ' numseqentr,'
         || ' numseqentrega,'
         || ' numseqmontagem,'
         || ' numseqrota,'
         || ' numserieequip,'
         || ' numtabela,'
         || ' numtransvenda,'
         || ' numtranswms,'
         || ' numviasmapasep,'
         || ' numviaspedido,'
         || ' numvolume,'
         || ' obs,'
         || ' obsentrega1,'
         || ' obsentrega2,'
         || ' obsentrega3,'
         || ' obsfretenf1,'
         || ' obsfretenf2,'
         || ' obsfretenf3,'
         || ' obs1,'
         || ' obs2,'
         || ' operacao,'
         || ' origemped,'
         || ' pagtoantecipado,'
         || ' pedidoembalado,'
         || ' percdescabc,'
         || ' percdesccanal,'
         || ' percdesccli,'
         || ' percdescneg,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdescfin,'
         || ' posicao,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' prazo1,'
         || ' prazo10,'
         || ' prazo11,'
         || ' prazo12,'
         || ' prazo2,'
         || ' prazo3,'
         || ' prazo4,'
         || ' prazo5,'
         || ' prazo6,'
         || ' prazo7,'
         || ' prazo8,'
         || ' prazo9,'
         || ' prontaentrega,'
         || ' reservaritenstv7,'
         || ' restricaotransp,'
         || ' serieecf,'
         || ' seriemanif,'
         || ' tipocarga,'
         || ' tipocfoptv4,'
         || ' tipoembalagem,'
         || ' tipoformularionf,'
         || ' tipooper,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' tributaporregiaofilial,'
         || ' vlatend,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldescneg,'
         || ' vldesconto,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicmsfretenf,'
         || ' vloutrasdesp,'
         || ' vltabela,'
         || ' vltotal '
         || ' FROM pcpedc '
         || ' WHERE (codfilial, data, numpedecf, serieecf, codfunccx, numcaixa,numserieequip)'
         || ' IN (SELECT c.codfilial, c.DATA, c.numpedecf, c.serieecf, c.codfunccx, c.numcaixa, c.numserieequip '
         || '       FROM pcpedccancecf c '
         || '      WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '        AND NVL (c.exportadoservint, ''N'') = ''X'')'
         || ' AND NVL (exportadoservint, ''N'') = ''X'''
         || ' AND posicao = ''C''';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_can_pcpedc;

   FUNCTION exportar_can_pcpedi (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'can_pcpedi';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( abastecido,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' baseicst,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddegustacao,'
         || ' codecf,'
         || ' codfilialretira,'
         || ' codfuncconf,'
         || ' codfuncsep,'
         || ' codicmtab,'
         || ' codmotnaocompra,'
         || ' codplpag,'
         || ' codprod,'
         || ' codpromocao,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' condvenda,'
         || ' custofinest,'
         || ' data,'
         || ' dataconf,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' eancodprod,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' imprime,'
         || ' iva,'
         || ' letracomiss,'
         || ' localizacao,'
         || ' nomeconcorrente,'
         || ' numaplic,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numconferencia,'
         || ' numlote,'
         || ' numop,'
         || ' numped,'
         || ' numseq,'
         || ' numtira,'
         || ' numtranswms,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percbasered,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percipi,'
         || ' perciss,'
         || ' percom,'
         || ' percomprof,'
         || ' percomsup,'
         || ' percomtab,'
         || ' percom2,'
         || ' percom3,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perdesctab,'
         || ' perfretecmv,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' poriginal,'
         || ' posicao,'
         || ' prazo,'
         || ' prazomedio,'
         || ' preco,'
         || ' ptabela,'
         || ' pvenda,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtapanha,'
         || ' qtcx,'
         || ' qtembalagem,'
         || ' qtfalta,'
         || ' qtlocalizada,'
         || ' qtnaocompra,'
         || ' qtorig,'
         || ' qtoriginal,'
         || ' qtpecas,'
         || ' qtseparada,'
         || ' qtsepararcx,'
         || ' qtsepararun,'
         || ' qtvendaemb,'
         || ' refcor,'
         || ' st,'
         || ' stclientegnre,'
         || ' tipodescaplicado,'
         || ' tipopeso,'
         || ' txvenda,'
         || ' vlacrescrodape,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescfornec,'
         || ' vldescicmisencao,'
         || ' vldescpissuframa,'
         || ' vldescrepasse,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vlfrete,'
         || ' vlipi,'
         || ' vliss,'
         || ' vloutrasdesp,'
         || ' vloutros,'
         || ' vlrebaixacmv,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT abastecido,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' baseicst,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddegustacao,'
         || ' codecf,'
         || ' codfilialretira,'
         || ' codfuncconf,'
         || ' codfuncsep,'
         || ' codicmtab,'
         || ' codmotnaocompra,'
         || ' codplpag,'
         || ' codprod,'
         || ' codpromocao,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' condvenda,'
         || ' custofinest,'
         || ' data,'
         || ' dataconf,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' eancodprod,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' imprime,'
         || ' iva,'
         || ' letracomiss,'
         || ' localizacao,'
         || ' nomeconcorrente,'
         || ' numaplic,'
         || ' numcar,'
         || ' numcaraux,'
         || ' numconferencia,'
         || ' numlote,'
         || ' numop,'
         || ' numped,'
         || ' numseq,'
         || ' numtira,'
         || ' numtranswms,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percbasered,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percipi,'
         || ' perciss,'
         || ' percom,'
         || ' percomprof,'
         || ' percomsup,'
         || ' percomtab,'
         || ' percom2,'
         || ' percom3,'
         || ' percvenda,'
         || ' perdesc,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perdesctab,'
         || ' perfretecmv,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' poriginal,'
         || ' posicao,'
         || ' prazo,'
         || ' prazomedio,'
         || ' preco,'
         || ' ptabela,'
         || ' pvenda,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtapanha,'
         || ' qtcx,'
         || ' qtembalagem,'
         || ' qtfalta,'
         || ' qtlocalizada,'
         || ' qtnaocompra,'
         || ' qtorig,'
         || ' qtoriginal,'
         || ' qtpecas,'
         || ' qtseparada,'
         || ' qtsepararcx,'
         || ' qtsepararun,'
         || ' qtvendaemb,'
         || ' refcor,'
         || ' st,'
         || ' stclientegnre,'
         || ' tipodescaplicado,'
         || ' tipopeso,'
         || ' txvenda,'
         || ' vlacrescrodape,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescfornec,'
         || ' vldescicmisencao,'
         || ' vldescpissuframa,'
         || ' vldescrepasse,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vlfrete,'
         || ' vlipi,'
         || ' vliss,'
         || ' vloutrasdesp,'
         || ' vloutros,'
         || ' vlrebaixacmv,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli '
         || ' FROM pcpedi '
         || ' WHERE numped IN ( '
         || '   SELECT p.numped '
         || '     FROM pcpedc p '
         || '    WHERE (p.codfilial, '
         || '           p.DATA,'
         || '           p.numpedecf,'
         || '           p.serieecf,'
         || '           p.codfunccx,'
         || '           p.numcaixa,'
         || '           p.numserieequip) IN ('
         || '              SELECT c.codfilial, c.DATA, c.numpedecf,'
         || '                     c.serieecf, c.codfunccx, c.numcaixa,'
         || '                     c.numserieequip'
         || '                FROM pcpedccancecf c'
         || '               WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '                 AND NVL (c.exportadoservint, ''N'') = ''X'')'
         || '      AND NVL (p.exportadoservint, ''N'') = ''X'''
         || '      AND p.posicao = ''C'')';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_can_pcpedi;

   FUNCTION exportar_can_pcnfsaid (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'can_pcnfsaid';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( apresentoucupompromocao,'
         || ' bcst,'
         || ' bcstgnre,'
         || ' broker,'
         || ' caixa,'
         || ' codcli,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcont,'
         || ' codcontrato,'
         || ' coddevol,'
         || ' coddoc,'
         || ' codemitente,'
         || ' codepto,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfiscal,'
         || ' codfornec,'
         || ' codfornecfrete,'
         || ' codfunccancel,'
         || ' codfunclanc,'
         || ' codfunclibent,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' comissao,'
         || ' comissaosup,'
         || ' comissao2,'
         || ' comissao3,'
         || ' condvenda,'
         || ' dtcancel,'
         || ' dtcanhoto,'
         || ' dtdevol,'
         || ' dtemissaonffornec,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dthorachegada,'
         || ' dthorasaida,'
         || ' dtimportacaoservprinc,'
         || ' dtlibent,'
         || ' dtnsu,'
         || ' dtpgtocampanha,'
         || ' dtsaida,'
         || ' dtwms,'
         || ' equiplanc,'
         || ' especie,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' funclanc,'
         || ' geracaorazaoauxiliar,'
         || ' geracp,'
         || ' horalanc,'
         || ' icmsretido,'
         || ' icmsretidognre,'
         || ' importadoservprinc,'
         || ' kmfinalentrega,'
         || ' minutolanc,'
         || ' nffornec,'
         || ' nsu,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcupom,'
         || ' numecf,'
         || ' numformulario,'
         || ' numidf,'
         || ' numitens,'
         || ' numlanccp,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numped,'
         || ' numprevenda,'
         || ' numregiao,'
         || ' numregiaofrete,'
         || ' numselonf,'
         || ' numseq,'
         || ' numseqmontagem,'
         || ' numserieequip,'
         || ' numtab,'
         || ' numtransvenda,'
         || ' numtransvendadestino,'
         || ' numtransvendaecf,'
         || ' numtransvendaorigem,'
         || ' numvias,'
         || ' numviaspu,'
         || ' numvolume,'
         || ' obs,'
         || ' perbaseredoutrasdesp,'
         || ' percfrete,'
         || ' perdescfin,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' reservaritenstv7,'
         || ' rotinalanc,'
         || ' serie,'
         || ' serieecf,'
         || ' stribut,'
         || ' tipodevol,'
         || ' tipofrete,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' uf,'
         || ' vlbase,'
         || ' vlbaseipi,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesconto,'
         || ' vldescprom,'
         || ' vldevolucao,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicms,'
         || ' vlicmsantecipado,'
         || ' vlipi,'
         || ' vlir,'
         || ' vlisentas,'
         || ' vliss,'
         || ' vloutras,'
         || ' vloutrasdesp,'
         || ' vlpis,'
         || ' vlrecebidoboleto,'
         || ' vlrecebidocartao,'
         || ' vlrecebidoch,'
         || ' vlrecebidodin,'
         || ' vltabela,'
         || ' vltotal,'
         || ' vltotalnf,'
         || ' vltotger,'
         || ' vltroco,'
         || ' vlverbacmvcli ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT apresentoucupompromocao,'
         || ' bcst,'
         || ' bcstgnre,'
         || ' broker,'
         || ' caixa,'
         || ' codcli,'
         || ' codclinf,'
         || ' codclirecebedor,'
         || ' codcob,'
         || ' codcondicaovenda,'
         || ' codcont,'
         || ' codcontrato,'
         || ' coddevol,'
         || ' coddoc,'
         || ' codemitente,'
         || ' codepto,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfiscal,'
         || ' codfornec,'
         || ' codfornecfrete,'
         || ' codfunccancel,'
         || ' codfunclanc,'
         || ' codfunclibent,'
         || ' codplpag,'
         || ' codpraca,'
         || ' codsupervisor,'
         || ' codsupervisor2,'
         || ' codsupervisor3,'
         || ' codusur,'
         || ' codusur2,'
         || ' codusur3,'
         || ' comissao,'
         || ' comissaosup,'
         || ' comissao2,'
         || ' comissao3,'
         || ' condvenda,'
         || ' dtcancel,'
         || ' dtcanhoto,'
         || ' dtdevol,'
         || ' dtemissaonffornec,'
         || ' dtentrega,'
         || ' dtexportacaoservint,'
         || ' dthorachegada,'
         || ' dthorasaida,'
         || ' dtimportacaoservprinc,'
         || ' dtlibent,'
         || ' dtnsu,'
         || ' dtpgtocampanha,'
         || ' dtsaida,'
         || ' dtwms,'
         || ' equiplanc,'
         || ' especie,'
         || ' exportadoservint,'
         || ' fretedespacho,'
         || ' freteredespacho,'
         || ' funclanc,'
         || ' geracaorazaoauxiliar,'
         || ' geracp,'
         || ' horalanc,'
         || ' icmsretido,'
         || ' icmsretidognre,'
         || ' importadoservprinc,'
         || ' kmfinalentrega,'
         || ' minutolanc,'
         || ' nffornec,'
         || ' nsu,'
         || ' numcaixafiscal,'
         || ' numcar,'
         || ' numcupom,'
         || ' numecf,'
         || ' numformulario,'
         || ' numidf,'
         || ' numitens,'
         || ' numlanccp,'
         || ' numnftransf,'
         || ' numnota,'
         || ' numorca,'
         || ' numorcafilial,'
         || ' numped,'
         || ' numprevenda,'
         || ' numregiao,'
         || ' numregiaofrete,'
         || ' numselonf,'
         || ' numseq,'
         || ' numseqmontagem,'
         || ' numserieequip,'
         || ' numtab,'
         || ' numtransvenda,'
         || ' numtransvendadestino,'
         || ' numtransvendaecf,'
         || ' numtransvendaorigem,'
         || ' numvias,'
         || ' numviaspu,'
         || ' numvolume,'
         || ' obs,'
         || ' perbaseredoutrasdesp,'
         || ' percfrete,'
         || ' perdescfin,'
         || ' prazoadicional,'
         || ' prazomedio,'
         || ' prazoponderado,'
         || ' reservaritenstv7,'
         || ' rotinalanc,'
         || ' serie,'
         || ' serieecf,'
         || ' stribut,'
         || ' tipodevol,'
         || ' tipofrete,'
         || ' tipovenda,'
         || ' totpeso,'
         || ' totvlbonific,'
         || ' totvldesccom,'
         || ' totvldescfin,'
         || ' totvldescflex,'
         || ' totvlredcomiss,'
         || ' totvlredcomisssup,'
         || ' totvolume,'
         || ' uf,'
         || ' vlbase,'
         || ' vlbaseipi,'
         || ' vlbonific,'
         || ' vlcustocont,'
         || ' vlcustofin,'
         || ' vlcustoreal,'
         || ' vlcustorep,'
         || ' vldesconto,'
         || ' vldescprom,'
         || ' vldevolucao,'
         || ' vlfrete,'
         || ' vlfretenf,'
         || ' vlicms,'
         || ' vlicmsantecipado,'
         || ' vlipi,'
         || ' vlir,'
         || ' vlisentas,'
         || ' vliss,'
         || ' vloutras,'
         || ' vloutrasdesp,'
         || ' vlpis,'
         || ' vlrecebidoboleto,'
         || ' vlrecebidocartao,'
         || ' vlrecebidoch,'
         || ' vlrecebidodin,'
         || ' vltabela,'
         || ' vltotal,'
         || ' vltotalnf,'
         || ' vltotger,'
         || ' vltroco,'
         || ' vlverbacmvcli'
         || '   FROM pcnfsaid '
         || '  WHERE numped IN ('
         || '   SELECT p.numped'
         || '     FROM pcpedc p'
         || '    WHERE (p.codfilial,'
         || '           p.DATA,'
         || '           p.numpedecf,'
         || '           p.serieecf,'
         || '           p.codfunccx,'
         || '           p.numcaixa,'
         || '           p.numserieequip ) IN ('
         || '       SELECT c.codfilial, c.DATA, c.numpedecf,'
         || '              c.serieecf, c.codfunccx, c.numcaixa,'
         || '              c.numserieequip'
         || '         FROM pcpedccancecf c'
         || '        WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '          AND NVL (c.exportadoservint, ''N'') = ''X'')'
         || '      AND NVL (p.exportadoservint, ''N'') = ''X'''
         || '      AND p.posicao = ''C'')'
         || '    AND NVL (exportadoservint, ''N'') = ''X'''
         || '    AND dtcancel IS NOT NULL';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_can_pcnfsaid;

   FUNCTION exportar_can_pcmov (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'can_pcmov';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( aliqicmfreteent,'
         || ' aliqicmoutrasdespent,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' aliqicst,'
         || ' aliqstsaida,'
         || ' aliquotatis,'
         || ' aproveitacredicms,'
         || ' baseacrescimopf,'
         || ' basebcr,'
         || ' baseicms,'
         || ' baseicmsadicional,'
         || ' baseicmsbcr,'
         || ' baseicms2,'
         || ' baseicst,'
         || ' baseivamex,'
         || ' basestsaida,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddevol,'
         || ' codecf,'
         || ' codepto,'
         || ' codequipamento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfilialretira,'
         || ' codfiscal,'
         || ' codfiscalfreteent,'
         || ' codfiscaloutrasdespent,'
         || ' codfornec,'
         || ' codfunclanc,'
         || ' codfuncquarentena,'
         || ' codfuncreq,'
         || ' codicmtab,'
         || ' codmotorista,'
         || ' codoper,'
         || ' codplpag,'
         || ' codprod,'
         || ' codprodprinc,'
         || ' codpromocao,'
         || ' codsec,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' custocont,'
         || ' custocontant,'
         || ' custofin,'
         || ' custofinant,'
         || ' custofinest,'
         || ' custoreal,'
         || ' custorealant,'
         || ' custorealsemst,'
         || ' custorealsemstant,'
         || ' custorep,'
         || ' custorepant,'
         || ' custoultent,'
         || ' custoultentant,'
         || ' custoultentant2,'
         || ' custoultentfin,'
         || ' custoultentfinant,'
         || ' custoultentmed,'
         || ' custoultentmedant,'
         || ' datafabricacao,'
         || ' datalibquarentena,'
         || ' datavalidade,'
         || ' dtcancel,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' dtmov,'
         || ' dtmovlog,'
         || ' dtultentant,'
         || ' equiplanc,'
         || ' estoquedesbloqueado,'
         || ' exportadoservint,'
         || ' fatorcustonatransf,'
         || ' funclanc,'
         || ' horalanc,'
         || ' horaproducao,'
         || ' importadoservprinc,'
         || ' indlocal,'
         || ' itemdivergente,'
         || ' iva,'
         || ' localizacao,'
         || ' minutolanc,'
         || ' numbono,'
         || ' numbonus,'
         || ' numcar,'
         || ' numformulario,'
         || ' numformulario2,'
         || ' numidf,'
         || ' numlanccp,'
         || ' numlote,'
         || ' numnegociacao,'
         || ' numnota,'
         || ' numnotadev,'
         || ' numop,'
         || ' numped,'
         || ' numregiao,'
         || ' numseq,'
         || ' numseqped,'
         || ' numtransavulsa,'
         || ' numtransdev,'
         || ' numtransdevfor,'
         || ' numtransent,'
         || ' numtransentultent,'
         || ' numtransentultentant,'
         || ' numtransop,'
         || ' numtransvenda,'
         || ' numverbaoutras,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' peracrescimopf,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percaliqext2,'
         || ' percaliqint2,'
         || ' percbasered,'
         || ' percbaseredadicional,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percbon,'
         || ' percbonoutras,'
         || ' perccredicmpresumido,'
         || ' percdesc,'
         || ' percdescfin,'
         || ' percdespadicional,'
         || ' percdespfin,'
         || ' percfrete,'
         || ' percfretefob,'
         || ' percicm,'
         || ' percicmcp,'
         || ' percicmoriginal,'
         || ' percicmred,'
         || ' percicm2,'
         || ' percimportacao,'
         || ' percimpureza,'
         || ' percinteiro,'
         || ' percipi,'
         || ' perciss,'
         || ' perciva,'
         || ' percivamex,'
         || ' perciva2,'
         || ' percmexfpgc,'
         || ' percmexieps,'
         || ' percmexiva,'
         || ' percofins,'
         || ' percom,'
         || ' percomsup,'
         || ' percom2,'
         || ' percom3,'
         || ' percoutrasdesp,'
         || ' percoutroscustos,'
         || ' percquebrado,'
         || ' percst,'
         || ' percsuframa,'
         || ' percumidade,'
         || ' percvenda,'
         || ' percvermelho,'
         || ' percvlbonific,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perfretecmv,'
         || ' pericmfrete,'
         || ' pericmguiapropria,'
         || ' pericmsantecipado,'
         || ' perpis,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' pliqped,'
         || ' prazomedio,'
         || ' precopauta,'
         || ' prodbonificado,'
         || ' promocaobiro,'
         || ' ptabela,'
         || ' ptabela2,'
         || ' punit,'
         || ' punitcont,'
         || ' punitnf,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtavaria,'
         || ' qtbloqueada,'
         || ' qtcont,'
         || ' qtcx,'
         || ' qtdevol,'
         || ' qtembalagem,'
         || ' qtestant,'
         || ' qtestgerant,'
         || ' qthoras,'
         || ' qtpecas,'
         || ' qtsaldoest,'
         || ' qtsaldoestger,'
         || ' qtultentant,'
         || ' qtvendaemb,'
         || ' qualdivergencia,'
         || ' redbasealiqext,'
         || ' redbaseiva,'
         || ' refcor,'
         || ' rotinalanc,'
         || ' sittribut,'
         || ' st,'
         || ' status,'
         || ' stbcr,'
         || ' stclientegnre,'
         || ' stsaida,'
         || ' tipodescaplicado,'
         || ' tipoitem,'
         || ' tipotis,'
         || ' txvenda,'
         || ' valorultent,'
         || ' valorultentant,'
         || ' valorultentmed,'
         || ' valorultentmedant,'
         || ' vlacrescimopf,'
         || ' vlacrescrodape,'
         || ' vladicionalbcst,'
         || ' vladuaneira,'
         || ' vlbasegnre,'
         || ' vlbaseipi,'
         || ' vlbasestforanf,'
         || ' vlbonific,'
         || ' vlbonificoutras,'
         || ' vlcredcofins,'
         || ' vlcredicms,'
         || ' vlcredicmsfrete,'
         || ' vlcredpis,'
         || ' vlcredpresumido,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescicmisencao,'
         || ' vldesconto,'
         || ' vldescpissuframa,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vldespadicional,'
         || ' vldespfin,'
         || ' vlfrete,'
         || ' vlfreteconhec,'
         || ' vlfreteporkg,'
         || ' vlicmsbcr,'
         || ' vlimportacao,'
         || ' vlindeniz,'
         || ' vlipi,'
         || ' vliss,'
         || ' vlivamex,'
         || ' vlmexfpgc,'
         || ' vlmexieps,'
         || ' vlmexiva,'
         || ' vloutrasdesp,'
         || ' vloutrasdespimp,'
         || ' vloutros,'
         || ' vlpauta2,'
         || ' vlpercbon,'
         || ' vlpis,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlsiscomex,'
         || ' vlsuframa,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT aliqicmfreteent,'
         || ' aliqicmoutrasdespent,'
         || ' aliqicms1,'
         || ' aliqicms2,'
         || ' aliqicst,'
         || ' aliqstsaida,'
         || ' aliquotatis,'
         || ' aproveitacredicms,'
         || ' baseacrescimopf,'
         || ' basebcr,'
         || ' baseicms,'
         || ' baseicmsadicional,'
         || ' baseicmsbcr,'
         || ' baseicms2,'
         || ' baseicst,'
         || ' baseivamex,'
         || ' basestsaida,'
         || ' brinde,'
         || ' codauxiliar,'
         || ' codcertific,'
         || ' codcli,'
         || ' coddevol,'
         || ' codecf,'
         || ' codepto,'
         || ' codequipamento,'
         || ' codfilial,'
         || ' codfilialnf,'
         || ' codfilialretira,'
         || ' codfiscal,'
         || ' codfiscalfreteent,'
         || ' codfiscaloutrasdespent,'
         || ' codfornec,'
         || ' codfunclanc,'
         || ' codfuncquarentena,'
         || ' codfuncreq,'
         || ' codicmtab,'
         || ' codmotorista,'
         || ' codoper,'
         || ' codplpag,'
         || ' codprod,'
         || ' codprodprinc,'
         || ' codpromocao,'
         || ' codsec,'
         || ' codst,'
         || ' codusur,'
         || ' complemento,'
         || ' custocont,'
         || ' custocontant,'
         || ' custofin,'
         || ' custofinant,'
         || ' custofinest,'
         || ' custoreal,'
         || ' custorealant,'
         || ' custorealsemst,'
         || ' custorealsemstant,'
         || ' custorep,'
         || ' custorepant,'
         || ' custoultent,'
         || ' custoultentant,'
         || ' custoultentant2,'
         || ' custoultentfin,'
         || ' custoultentfinant,'
         || ' custoultentmed,'
         || ' custoultentmedant,'
         || ' datafabricacao,'
         || ' datalibquarentena,'
         || ' datavalidade,'
         || ' dtcancel,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' dtmov,'
         || ' dtmovlog,'
         || ' dtultentant,'
         || ' equiplanc,'
         || ' estoquedesbloqueado,'
         || ' exportadoservint,'
         || ' fatorcustonatransf,'
         || ' funclanc,'
         || ' horalanc,'
         || ' horaproducao,'
         || ' importadoservprinc,'
         || ' indlocal,'
         || ' itemdivergente,'
         || ' iva,'
         || ' localizacao,'
         || ' minutolanc,'
         || ' numbono,'
         || ' numbonus,'
         || ' numcar,'
         || ' numformulario,'
         || ' numformulario2,'
         || ' numidf,'
         || ' numlanccp,'
         || ' numlote,'
         || ' numnegociacao,'
         || ' numnota,'
         || ' numnotadev,'
         || ' numop,'
         || ' numped,'
         || ' numregiao,'
         || ' numseq,'
         || ' numseqped,'
         || ' numtransavulsa,'
         || ' numtransdev,'
         || ' numtransdevfor,'
         || ' numtransent,'
         || ' numtransentultent,'
         || ' numtransentultentant,'
         || ' numtransop,'
         || ' numtransvenda,'
         || ' numverbaoutras,'
         || ' numverbarebcmv,'
         || ' pauta,'
         || ' pbaserca,'
         || ' pbonific,'
         || ' peracrescimopf,'
         || ' perbonific,'
         || ' percagregadorst,'
         || ' percaliqext2,'
         || ' percaliqint2,'
         || ' percbasered,'
         || ' percbaseredadicional,'
         || ' percbaseredst,'
         || ' percbaseredstfonte,'
         || ' percbon,'
         || ' percbonoutras,'
         || ' perccredicmpresumido,'
         || ' percdesc,'
         || ' percdescfin,'
         || ' percdespadicional,'
         || ' percdespfin,'
         || ' percfrete,'
         || ' percfretefob,'
         || ' percicm,'
         || ' percicmcp,'
         || ' percicmoriginal,'
         || ' percicmred,'
         || ' percicm2,'
         || ' percimportacao,'
         || ' percimpureza,'
         || ' percinteiro,'
         || ' percipi,'
         || ' perciss,'
         || ' perciva,'
         || ' percivamex,'
         || ' perciva2,'
         || ' percmexfpgc,'
         || ' percmexieps,'
         || ' percmexiva,'
         || ' percofins,'
         || ' percom,'
         || ' percomsup,'
         || ' percom2,'
         || ' percom3,'
         || ' percoutrasdesp,'
         || ' percoutroscustos,'
         || ' percquebrado,'
         || ' percst,'
         || ' percsuframa,'
         || ' percumidade,'
         || ' percvenda,'
         || ' percvermelho,'
         || ' percvlbonific,'
         || ' perdesccom,'
         || ' perdesccusto,'
         || ' perdescfin,'
         || ' perdescflex,'
         || ' perdescisentoicms,'
         || ' perfretecmv,'
         || ' pericmfrete,'
         || ' pericmguiapropria,'
         || ' pericmsantecipado,'
         || ' perpis,'
         || ' perredcomiss,'
         || ' perredcomisssup,'
         || ' pesobruto,'
         || ' pliqped,'
         || ' prazomedio,'
         || ' precopauta,'
         || ' prodbonificado,'
         || ' promocaobiro,'
         || ' ptabela,'
         || ' ptabela2,'
         || ' punit,'
         || ' punitcont,'
         || ' punitnf,'
         || ' pvendabase,'
         || ' pvendaemb,'
         || ' pvendaembalagem,'
         || ' pvenda1,'
         || ' qt,'
         || ' qtavaria,'
         || ' qtbloqueada,'
         || ' qtcont,'
         || ' qtcx,'
         || ' qtdevol,'
         || ' qtembalagem,'
         || ' qtestant,'
         || ' qtestgerant,'
         || ' qthoras,'
         || ' qtpecas,'
         || ' qtsaldoest,'
         || ' qtsaldoestger,'
         || ' qtultentant,'
         || ' qtvendaemb,'
         || ' qualdivergencia,'
         || ' redbasealiqext,'
         || ' redbaseiva,'
         || ' refcor,'
         || ' rotinalanc,'
         || ' sittribut,'
         || ' st,'
         || ' status,'
         || ' stbcr,'
         || ' stclientegnre,'
         || ' stsaida,'
         || ' tipodescaplicado,'
         || ' tipoitem,'
         || ' tipotis,'
         || ' txvenda,'
         || ' valorultent,'
         || ' valorultentant,'
         || ' valorultentmed,'
         || ' valorultentmedant,'
         || ' vlacrescimopf,'
         || ' vlacrescrodape,'
         || ' vladicionalbcst,'
         || ' vladuaneira,'
         || ' vlbasegnre,'
         || ' vlbaseipi,'
         || ' vlbasestforanf,'
         || ' vlbonific,'
         || ' vlbonificoutras,'
         || ' vlcredcofins,'
         || ' vlcredicms,'
         || ' vlcredicmsfrete,'
         || ' vlcredpis,'
         || ' vlcredpresumido,'
         || ' vldesccom,'
         || ' vldesccustocmv,'
         || ' vldescfin,'
         || ' vldescflex,'
         || ' vldescicmisencao,'
         || ' vldesconto,'
         || ' vldescpissuframa,'
         || ' vldescrodape,'
         || ' vldescsuframa,'
         || ' vldespadicional,'
         || ' vldespfin,'
         || ' vlfrete,'
         || ' vlfreteconhec,'
         || ' vlfreteporkg,'
         || ' vlicmsbcr,'
         || ' vlimportacao,'
         || ' vlindeniz,'
         || ' vlipi,'
         || ' vliss,'
         || ' vlivamex,'
         || ' vlmexfpgc,'
         || ' vlmexieps,'
         || ' vlmexiva,'
         || ' vloutrasdesp,'
         || ' vloutrasdespimp,'
         || ' vloutros,'
         || ' vlpauta2,'
         || ' vlpercbon,'
         || ' vlpis,'
         || ' vlredcomiss,'
         || ' vlredcomisssup,'
         || ' vlrepasse,'
         || ' vlsiscomex,'
         || ' vlsuframa,'
         || ' vlverbacmv,'
         || ' vlverbacmvcli'
         || '   FROM pcmov'
         || '  WHERE numtransvenda IN ('
         || '    SELECT n.numtransvenda'
         || '      FROM pcnfsaid n'
         || '     WHERE n.numped IN ('
         || '       SELECT p.numped'
         || '         FROM pcpedc p'
         || '        WHERE (p.codfilial,'
         || '               p.DATA,'
         || '               p.numpedecf,'
         || '               p.serieecf,'
         || '               p.codfunccx,'
         || '               p.numcaixa,'
         || '               p.numserieequip) IN ('
         || '          SELECT c.codfilial, c.DATA,'
         || '                 c.numpedecf, c.serieecf,'
         || '                 c.codfunccx, c.numcaixa,'
         || '                 c.numserieequip'
         || '            FROM pcpedccancecf c'
         || '           WHERE c.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '             AND NVL (c.exportadoservint, ''N'') = ''X'''
         || '          AND NVL (p.exportadoservint, ''N'') = ''X'')'
         || '          AND p.posicao = ''C'')'
         || '       AND NVL (n.exportadoservint, ''N'') = ''X'''
         || '       AND n.dtcancel IS NOT NULL)';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_can_pcmov;

   FUNCTION exportar_pcservintercancel (
      pscodfilial   IN       VARCHAR2,
      psmsg         OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcservintercancel';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      --> .dat intermediario -> principal
      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codfilial,'
         || ' codfunccx,'
         || ' data,'
         || ' dtexportacao,'
         || ' dtimportacao,'
         || ' itens_exp_pcmov,'
         || ' itens_exp_pcnfcan,'
         || ' itens_exp_pcnfcanitem,'
         || ' itens_exp_pcnfsaid,'
         || ' itens_exp_pcpedc,'
         || ' itens_exp_pcpedccancecf,'
         || ' itens_exp_pcpedi,'
         || ' itens_exp_pcpedicancecf,'
         || ' itens_imp_pcmov,'
         || ' itens_imp_pcnfcan,'
         || ' itens_imp_pcnfcanitem,'
         || ' itens_imp_pcnfsaid,'
         || ' itens_imp_pcpedc,'
         || ' itens_imp_pcpedccancecf,'
         || ' itens_imp_pcpedi,'
         || ' itens_imp_pcpedicancecf,'
         || ' numcaixa,'
         || ' numped,'
         || ' numpedecf,'
         || ' numserieequip,'
         || ' numtransvendaecf,'
         || ' numtransvendawinthor,'
         || ' serieecf,'
         || ' status,'
         || ' tipo ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT d.codfilial,'
         || ' d.codfunccx,'
         || ' d.data,'
         || ' d.dtexportacao,'
         || ' d.dtimportacao,'
         || ' d.itens_exp_pcmov,'
         || ' d.itens_exp_pcnfcan,'
         || ' d.itens_exp_pcnfcanitem,'
         || ' d.itens_exp_pcnfsaid,'
         || ' d.itens_exp_pcpedc,'
         || ' d.itens_exp_pcpedccancecf,'
         || ' d.itens_exp_pcpedi,'
         || ' d.itens_exp_pcpedicancecf,'
         || ' d.itens_imp_pcmov,'
         || ' d.itens_imp_pcnfcan,'
         || ' d.itens_imp_pcnfcanitem,'
         || ' d.itens_imp_pcnfsaid,'
         || ' d.itens_imp_pcpedc,'
         || ' d.itens_imp_pcpedccancecf,'
         || ' d.itens_imp_pcpedi,'
         || ' d.itens_imp_pcpedicancecf,'
         || ' d.numcaixa,'
         || ' d.numped,'
         || ' d.numpedecf,'
         || ' d.numserieequip,'
         || ' d.numtransvendaecf,'
         || ' d.numtransvendawinthor,'
         || ' d.serieecf,'
         || ' d.status,'
         || ' d.tipo '
         || '   FROM pcservintercancel d, pcpedccancecf s'
         || '  WHERE s.DATA >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '    AND NVL (s.exportadoservint, ''N'') = ''X'''
         || '    AND d.codfilial = s.codfilial'
         || '    AND d.DATA = s.DATA'
         || '    AND d.serieecf = s.serieecf'
         || '    AND d.numpedecf = s.numpedecf'
         || '    AND d.numcaixa = s.numcaixa'
         || '    AND d.codfunccx = s.codfunccx'
         || '    AND d.numserieequip = s.numserieequip';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcservintercancel;

   PROCEDURE exportar_cancelamentos (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
   IS
      vsmensagem         VARCHAR2 (2000);
      vsmsg              VARCHAR2 (2000);
      exc_geracaodados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vsmsg := '';

      BEGIN
         BEGIN
            UPDATE pcpedccancecf
               SET exportadoservint = 'X'
             WHERE DATA >= TRUNC (SYSDATE) - vgnumdias
               AND NVL (exportadoservint, 'N') = 'N';

            UPDATE pcpedicancecf
               SET exportadoservint = 'X'
             WHERE (numpedecf, codfunccx, numcaixa, numserieequip) IN (
                      SELECT c.numpedecf, c.codfunccx, c.numcaixa,
                             c.numserieequip
                        FROM pcpedccancecf c
                       WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                         AND NVL (c.exportadoservint, 'N') = 'X');

            UPDATE pcpedc
               SET exportadoservint = 'X'
             WHERE (codfilial,
                    DATA,
                    numpedecf,
                    serieecf,
                    codfunccx,
                    numcaixa,
                    numserieequip
                   ) IN (
                      SELECT c.codfilial, c.DATA, c.numpedecf, c.serieecf,
                             c.codfunccx, c.numcaixa, c.numserieequip
                        FROM pcpedccancecf c
                       WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                         AND NVL (c.exportadoservint, 'N') = 'X')
               AND NVL (exportadoservint, 'N') = 'N'
               AND posicao = 'C';

            UPDATE pcpedi
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT p.numped
                        FROM pcpedc p
                       WHERE (p.codfilial,
                              p.DATA,
                              p.numpedecf,
                              p.serieecf,
                              p.codfunccx,
                              p.numcaixa,
                              p.numserieequip
                             ) IN (
                                SELECT c.codfilial, c.DATA, c.numpedecf,
                                       c.serieecf, c.codfunccx, c.numcaixa,
                                       c.numserieequip
                                  FROM pcpedccancecf c
                                 WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                   AND NVL (c.exportadoservint, 'N') = 'X')
                         AND NVL (p.exportadoservint, 'N') = 'X'
                         AND p.posicao = 'C');

            UPDATE pcnfsaid
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT p.numped
                        FROM pcpedc p
                       WHERE (p.codfilial,
                              p.DATA,
                              p.numpedecf,
                              p.serieecf,
                              p.codfunccx,
                              p.numcaixa,
                              p.numserieequip
                             ) IN (
                                SELECT c.codfilial, c.DATA, c.numpedecf,
                                       c.serieecf, c.codfunccx, c.numcaixa,
                                       c.numserieequip
                                  FROM pcpedccancecf c
                                 WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                   AND NVL (c.exportadoservint, 'N') = 'X')
                         AND NVL (p.exportadoservint, 'N') = 'X'
                         AND p.posicao = 'C')
               AND NVL (exportadoservint, 'N') = 'N'
               AND dtcancel IS NOT NULL;

            UPDATE pcmov
               SET exportadoservint = 'X'
             WHERE numtransvenda IN (
                      SELECT n.numtransvenda
                        FROM pcnfsaid n
                       WHERE n.numped IN (
                                SELECT p.numped
                                  FROM pcpedc p
                                 WHERE (p.codfilial,
                                        p.DATA,
                                        p.numpedecf,
                                        p.serieecf,
                                        p.codfunccx,
                                        p.numcaixa,
                                        p.numserieequip
                                       ) IN (
                                          SELECT c.codfilial, c.DATA,
                                                 c.numpedecf, c.serieecf,
                                                 c.codfunccx, c.numcaixa,
                                                 c.numserieequip
                                            FROM pcpedccancecf c
                                           WHERE c.DATA >=
                                                    TRUNC (SYSDATE)
                                                    - vgnumdias
                                             AND NVL (c.exportadoservint, 'N') =
                                                                           'X')
                                   AND NVL (p.exportadoservint, 'N') = 'X'
                                   AND p.posicao = 'C')
                         AND NVL (n.exportadoservint, 'N') = 'X'
                         AND n.dtcancel IS NOT NULL);

            UPDATE pcnfcan
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT p.numped
                        FROM pcpedc p
                       WHERE (p.codfilial,
                              p.DATA,
                              p.numpedecf,
                              p.serieecf,
                              p.codfunccx,
                              p.numcaixa,
                              p.numserieequip
                             ) IN (
                                SELECT c.codfilial, c.DATA, c.numpedecf,
                                       c.serieecf, c.codfunccx, c.numcaixa,
                                       c.numserieequip
                                  FROM pcpedccancecf c
                                 WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                   AND NVL (c.exportadoservint, 'N') = 'X')
                         AND NVL (p.exportadoservint, 'N') = 'X'
                         AND p.posicao = 'C');

            UPDATE pcnfcanitem
               SET exportadoservint = 'X'
             WHERE numped IN (
                      SELECT p.numped
                        FROM pcpedc p
                       WHERE (p.codfilial,
                              p.DATA,
                              p.numpedecf,
                              p.serieecf,
                              p.codfunccx,
                              p.numcaixa,
                              p.numserieequip
                             ) IN (
                                SELECT c.codfilial, c.DATA, c.numpedecf,
                                       c.serieecf, c.codfunccx, c.numcaixa,
                                       c.numserieequip
                                  FROM pcpedccancecf c
                                 WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                   AND NVL (c.exportadoservint, 'N') = 'X')
                         AND NVL (p.exportadoservint, 'N') = 'X'
                         AND p.posicao = 'C');
         EXCEPTION
            WHEN OTHERS
            THEN
               vsmensagem :=
                     'Erro ao marcar registros de cancelamento para exportacao. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;

         IF NOT exportar_pcpedccancecf (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                 'Não foi possível exportar o PCPEDCCANCECF. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcpedicancecf (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                 'Não foi possível exportar o PCPEDICANCECF. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_can_pcpedc (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
               'Não foi possível exportar o PCPEDC cancelado. Erro: '
               || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_can_pcpedi (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
               'Não foi possível exportar o PCPEDI cancelado. Erro: '
               || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_can_pcnfsaid (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                  'Não foi possível exportar o PCNFSAID cancelado. Erro: '
               || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_can_pcmov (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
               'Não foi possível exportar o PCMOV cancelado. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcnfcan (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                       'Não foi possível exportar o PCNFCAN. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcnfcanitem (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                   'Não foi possível exportar o PCNFCANITEM. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         -- Gerar log
         MERGE INTO pcservintercancel d
            USING (SELECT pcpedccancecf.codfilial, pcpedccancecf.DATA,
                          pcpedccancecf.serieecf, pcpedccancecf.numpedecf,
                          pcpedccancecf.numcaixa, pcpedccancecf.codfunccx,
                          pcpedccancecf.numserieequip, pcpedccancecf.numped,
                          DECODE (pcpedcecf.numped, NULL, 'C', 'N') tipo,
                          (SELECT numtransvenda
                             FROM pcnfsaid
                            WHERE numped =
                                     pcpedccancecf.numped)
                                                          AS numtransvendaecf,
                          SYSDATE AS dtexportacao, 'E' AS status,
                          1 AS itens_exp_pcpedccancecf,
                          (SELECT COUNT (*)
                             FROM pcpedicancecf
                            WHERE pcpedicancecf.numpedecf =
                                     pcpedccancecf.numpedecf
                              AND pcpedicancecf.codfunccx =
                                                       pcpedccancecf.codfunccx
                              AND pcpedicancecf.numcaixa =
                                                        pcpedccancecf.numcaixa
                              AND pcpedicancecf.numserieequip =
                                                   pcpedccancecf.numserieequip)
                                                      itens_exp_pcpedicancecf,
                          (SELECT COUNT (*)
                             FROM pcnfcan
                            WHERE numped =
                                       pcpedccancecf.numped)
                                                            itens_exp_pcnfcan,
                          (SELECT COUNT (*)
                             FROM pcnfcanitem
                            WHERE numped =
                                     pcpedccancecf.numped)
                                                        itens_exp_pcnfcanitem,
                          (SELECT COUNT (*)
                             FROM pcnfsaid
                            WHERE numped =
                                      pcpedccancecf.numped)
                                                           itens_exp_pcnfsaid,
                          (SELECT COUNT (*)
                             FROM pcmov i, pcnfsaid n
                            WHERE i.numtransvenda =
                                              n.numtransvenda
                              AND n.numped = pcpedccancecf.numped)
                                                              itens_exp_pcmov,
                          (SELECT COUNT (*)
                             FROM pcpedc
                            WHERE numped =
                                        pcpedccancecf.numped)
                                                             itens_exp_pcpedc,
                          (SELECT COUNT (*)
                             FROM pcpedi
                            WHERE numped =
                                        pcpedccancecf.numped)
                                                             itens_exp_pcpedi
                     FROM pcpedccancecf, pcpedcecf
                    WHERE pcpedccancecf.DATA >= TRUNC (SYSDATE) - vgnumdias
                      AND NVL (pcpedccancecf.exportadoservint, 'N') = 'X'
                      AND pcpedcecf.numpedecf(+) = pcpedccancecf.numpedecf
                      AND pcpedcecf.numserieequip(+) =
                                                   pcpedccancecf.numserieequip
                      AND pcpedcecf.codfunccx(+) = pcpedccancecf.codfunccx
                      AND pcpedcecf.numcaixa(+) = pcpedccancecf.numcaixa) s
            ON (    (d.codfilial = s.codfilial)
                AND (d.DATA = s.DATA)
                AND (d.serieecf = s.serieecf)
                AND (d.numpedecf = s.numpedecf)
                AND (d.numcaixa = s.numcaixa)
                AND (d.codfunccx = s.codfunccx)
                AND (d.numserieequip = s.numserieequip))
            WHEN MATCHED THEN
               UPDATE
                  SET d.numped = s.numped, d.tipo = s.tipo,
                      d.numtransvendaecf = s.numtransvendaecf,
                      d.dtexportacao = s.dtexportacao, d.status = s.status,
                      d.itens_exp_pcpedccancecf = s.itens_exp_pcpedccancecf,
                      d.itens_exp_pcpedicancecf = s.itens_exp_pcpedicancecf,
                      d.itens_exp_pcnfcan = s.itens_exp_pcnfcan,
                      d.itens_exp_pcnfcanitem = s.itens_exp_pcnfcanitem,
                      d.itens_exp_pcnfsaid = s.itens_exp_pcnfsaid,
                      d.itens_exp_pcmov = s.itens_exp_pcmov,
                      d.itens_exp_pcpedc = s.itens_exp_pcpedc,
                      d.itens_exp_pcpedi = s.itens_exp_pcpedi
            WHEN NOT MATCHED THEN
               INSERT (codfilial, DATA, serieecf, numpedecf, numcaixa,
                       codfunccx, numserieequip, numped, tipo,
                       numtransvendaecf, dtexportacao, status,
                       itens_exp_pcpedccancecf, itens_exp_pcpedicancecf,
                       itens_exp_pcnfcan, itens_exp_pcnfcanitem,
                       itens_exp_pcnfsaid, itens_exp_pcmov, itens_exp_pcpedc,
                       itens_exp_pcpedi)
               VALUES (s.codfilial, s.DATA, s.serieecf, s.numpedecf,
                       s.numcaixa, s.codfunccx, s.numserieequip, s.numped,
                       s.tipo, s.numtransvendaecf, s.dtexportacao, s.status,
                       s.itens_exp_pcpedccancecf, s.itens_exp_pcpedicancecf,
                       s.itens_exp_pcnfcan, s.itens_exp_pcnfcanitem,
                       s.itens_exp_pcnfsaid, s.itens_exp_pcmov,
                       s.itens_exp_pcpedc, s.itens_exp_pcpedi);

         -- Exportar log
         IF NOT exportar_pcservintercancel (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                  'Não foi possível exportar o PCSERVINTERCANCEL. Erro: '
               || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         -- Marcar registros como exportados
         UPDATE pcmov
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numtransvenda IN (
                   SELECT n.numtransvenda
                     FROM pcnfsaid n
                    WHERE n.numped IN (
                             SELECT p.numped
                               FROM pcpedc p
                              WHERE (p.codfilial,
                                     p.DATA,
                                     p.numpedecf,
                                     p.serieecf,
                                     p.codfunccx,
                                     p.numcaixa,
                                     p.numserieequip
                                    ) IN (
                                       SELECT c.codfilial, c.DATA,
                                              c.numpedecf, c.serieecf,
                                              c.codfunccx, c.numcaixa,
                                              c.numserieequip
                                         FROM pcpedccancecf c
                                        WHERE c.DATA >=
                                                    TRUNC (SYSDATE)
                                                    - vgnumdias
                                          AND NVL (c.exportadoservint, 'N') =
                                                                           'X')
                                AND NVL (p.exportadoservint, 'N') = 'X'
                                AND p.posicao = 'C')
                      AND NVL (n.exportadoservint, 'N') = 'X'
                      AND n.dtcancel IS NOT NULL);

         UPDATE pcnfsaid
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT p.numped
                     FROM pcpedc p
                    WHERE (p.codfilial,
                           p.DATA,
                           p.numpedecf,
                           p.serieecf,
                           p.codfunccx,
                           p.numcaixa,
                           p.numserieequip
                          ) IN (
                             SELECT c.codfilial, c.DATA, c.numpedecf,
                                    c.serieecf, c.codfunccx, c.numcaixa,
                                    c.numserieequip
                               FROM pcpedccancecf c
                              WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                AND NVL (c.exportadoservint, 'N') = 'X')
                      AND NVL (p.exportadoservint, 'N') = 'X'
                      AND p.posicao = 'C')
            AND NVL (exportadoservint, 'N') = 'X'
            AND dtcancel IS NOT NULL;

         UPDATE pcnfcanitem
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT p.numped
                     FROM pcpedc p
                    WHERE (p.codfilial,
                           p.DATA,
                           p.numpedecf,
                           p.serieecf,
                           p.codfunccx,
                           p.numcaixa,
                           p.numserieequip
                          ) IN (
                             SELECT c.codfilial, c.DATA, c.numpedecf,
                                    c.serieecf, c.codfunccx, c.numcaixa,
                                    c.numserieequip
                               FROM pcpedccancecf c
                              WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                AND NVL (c.exportadoservint, 'N') = 'X')
                      AND NVL (p.exportadoservint, 'N') = 'X'
                      AND p.posicao = 'C');

         UPDATE pcnfcan
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT p.numped
                     FROM pcpedc p
                    WHERE (p.codfilial,
                           p.DATA,
                           p.numpedecf,
                           p.serieecf,
                           p.codfunccx,
                           p.numcaixa,
                           p.numserieequip
                          ) IN (
                             SELECT c.codfilial, c.DATA, c.numpedecf,
                                    c.serieecf, c.codfunccx, c.numcaixa,
                                    c.numserieequip
                               FROM pcpedccancecf c
                              WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                AND NVL (c.exportadoservint, 'N') = 'X')
                      AND NVL (p.exportadoservint, 'N') = 'X'
                      AND p.posicao = 'C');

         UPDATE pcpedi
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE numped IN (
                   SELECT p.numped
                     FROM pcpedc p
                    WHERE (p.codfilial,
                           p.DATA,
                           p.numpedecf,
                           p.serieecf,
                           p.codfunccx,
                           p.numcaixa,
                           p.numserieequip
                          ) IN (
                             SELECT c.codfilial, c.DATA, c.numpedecf,
                                    c.serieecf, c.codfunccx, c.numcaixa,
                                    c.numserieequip
                               FROM pcpedccancecf c
                              WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                                AND NVL (c.exportadoservint, 'N') = 'X')
                      AND NVL (p.exportadoservint, 'N') = 'X'
                      AND p.posicao = 'C');

         UPDATE pcpedc
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE (codfilial,
                 DATA,
                 numpedecf,
                 serieecf,
                 codfunccx,
                 numcaixa,
                 numserieequip
                ) IN (
                   SELECT c.codfilial, c.DATA, c.numpedecf, c.serieecf,
                          c.codfunccx, c.numcaixa, c.numserieequip
                     FROM pcpedccancecf c
                    WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                      AND NVL (c.exportadoservint, 'N') = 'X')
            AND NVL (exportadoservint, 'N') = 'X'
            AND posicao = 'C';

         UPDATE pcpedicancecf
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE (numpedecf, codfunccx, numcaixa, numserieequip) IN (
                   SELECT c.numpedecf, c.codfunccx, c.numcaixa,
                          c.numserieequip
                     FROM pcpedccancecf c
                    WHERE c.DATA >= TRUNC (SYSDATE) - vgnumdias
                      AND NVL (c.exportadoservint, 'N') = 'X');

         UPDATE pcpedccancecf
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE DATA >= TRUNC (SYSDATE) - vgnumdias
            AND NVL (exportadoservint, 'N') = 'X';

         COMMIT;
         psmensagem := vsmensagem;
      EXCEPTION
         WHEN exc_geracaodados
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;
         WHEN OTHERS
         THEN
            vsmensagem :=
                  'Erro ao marcar registros de cancelamento para exportacao. Erro: '
               || SQLCODE
               || ' - '
               || SQLERRM;
            ROLLBACK;
            psmensagem := vsmensagem;
      END;
   END;

   FUNCTION exportar_pcvalecx (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcvalecx';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codbanco,'
         || ' codcob,'
         || ' codfunc,'
         || ' codfuncfecha,'
         || ' dtexportacaoservint,'
         || ' dtfecha,'
         || ' dtimportacaoservprinc,'
         || ' dtlanc,'
         || ' exportadoservint,'
         || ' historico,'
         || ' horalanc,'
         || ' importadoservprinc,'
         || ' minutolanc,'
         || ' numcx,'
         || ' numserieequip,'
         || ' numvale,'
         || ' numvaleecf,'
         || ' numvaleintermediario,'
         || ' tipo,'
         || ' valor ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codbanco,'
         || ' codcob,'
         || ' codfunc,'
         || ' codfuncfecha,'
         || ' dtexportacaoservint,'
         || ' dtfecha,'
         || ' dtimportacaoservprinc,'
         || ' dtlanc,'
         || ' exportadoservint,'
         || ' historico,'
         || ' horalanc,'
         || ' importadoservprinc,'
         || ' minutolanc,'
         || ' numcx,'
         || ' numserieequip,'
         || ' numvale,'
         || ' numvaleecf,'
         || ' numvaleintermediario,'
         || ' tipo,'
         || ' valor '
         || ' FROM pcvalecx '
         || ' WHERE NVL(exportadoservint,''N'') = ''X'''
         || '   AND dtlanc >= TRUNC (SYSDATE) - '
         || vgnumdias;

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcvalecx;

   FUNCTION exportar_pcmovcr (pscodfilial IN VARCHAR2, psmsg OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcmovcr';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codbanco,'
         || ' codcob,'
         || ' codcontacred,'
         || ' codcontadeb,'
         || ' codfunc,'
         || ' codfuncconcil,'
         || ' codfuncestornoconcil,'
         || ' codrotinalanc,'
         || ' conciliacao,'
         || ' data,'
         || ' dtconcil,'
         || ' dtestorno,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' dtvenctickt,'
         || ' estorno,'
         || ' exportadoservint,'
         || ' historico,'
         || ' historico2,'
         || ' hora,'
         || ' importadoservprinc,'
         || ' indice,'
         || ' minuto,'
         || ' numcarr,'
         || ' numcarreg,'
         || ' numcheque,'
         || ' numcx,'
         || ' numlanc,'
         || ' numtrans,'
         || ' numtransecf,'
         || ' numtransest,'
         || ' numvaleecf,'
         || ' operacao,'
         || ' saldotmp,'
         || ' tipo,'
         || ' valor,'
         || ' vlsaldo,'
         || ' vlsaldoconcil ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codbanco,'
         || ' codcob,'
         || ' codcontacred,'
         || ' codcontadeb,'
         || ' codfunc,'
         || ' codfuncconcil,'
         || ' codfuncestornoconcil,'
         || ' codrotinalanc,'
         || ' conciliacao,'
         || ' data,'
         || ' dtconcil,'
         || ' dtestorno,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' dtvenctickt,'
         || ' estorno,'
         || ' exportadoservint,'
         || ' historico,'
         || ' historico2,'
         || ' hora,'
         || ' importadoservprinc,'
         || ' indice,'
         || ' minuto,'
         || ' numcarr,'
         || ' numcarreg,'
         || ' numcheque,'
         || ' numcx,'
         || ' numlanc,'
         || ' numtrans,'
         || ' numtransecf,'
         || ' numtransest,'
         || ' numvaleecf,'
         || ' operacao,'
         || ' saldotmp,'
         || ' tipo,'
         || ' valor,'
         || ' vlsaldo,'
         || ' vlsaldoconcil '
         || ' FROM pcmovcr '
         || ' WHERE (numvaleecf, DATA, codfunc, numcx) IN ('
         || '                SELECT numvaleecf, dtlanc, codfunc, numcx'
         || '                  FROM pcvalecx'
         || '                 WHERE NVL (pcvalecx.exportadoservint, ''N'') = ''X'''
         || '                   AND pcvalecx.dtlanc >= TRUNC (SYSDATE) - '
         || vgnumdias
         || ')';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcmovcr;

   FUNCTION exportar_pcservintersangria (
      pscodfilial   IN       VARCHAR2,
      psmsg         OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pcservintersangria';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      --> .dat intermediario -> principal
      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codfilial,'
         || '   numvaleecf,'
         || '   dtlanc,'
         || '   codfunc,'
         || '   numcaixa,'
         || '   codcob,'
         || '   codbanco,'
         || '   numserieequip,'
         || '   numvaleinter,'
         || '   numtransecf,'
         || '   dtexportacao,'
         || '   status,'
         || '   itens_exp_pcvalecx,'
         || '   itens_exp_pcmovcr ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT s.codfilial, s.numvaleecf, s.dtlanc, s.codfunc, s.numcaixa, s.codcob,'
         || '       s.codbanco, s.numserieequip, s.numvaleinter, s.numtransecf,'
         || '       s.dtexportacao, s.status, s.itens_exp_pcvalecx, s.itens_exp_pcmovcr'
         || '  FROM pcservintersangria s, pcvalecx v'
         || ' WHERE NVL (v.exportadoservint, ''N'') = ''X'''
         || '   AND v.dtlanc >= TRUNC (SYSDATE) - '
         || vgnumdias
         || '   AND s.numvaleecf = v.numvaleecf'
         || '   AND s.dtlanc = v.dtlanc'
         || '   AND s.codfunc = v.codfunc'
         || '   AND s.numcaixa = v.numcx';

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pcservintersangria;

   PROCEDURE exportar_sangrias (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   )
   IS
      vnnumtransvenda    NUMBER;
      vnnumped           NUMBER;
      vsmensagem         VARCHAR2 (2000);
      vsmsg              VARCHAR2 (2000);
      exc_geracaodados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vsmsg := '';

      BEGIN
         -- Marcar como X as Sangrias nao exportadas
         UPDATE pcvalecx
            SET exportadoservint = 'X'
          WHERE NVL (pcvalecx.exportadoservint, 'N') = 'N'
            AND pcvalecx.dtlanc >= TRUNC (SYSDATE) - vgnumdias;

         -- Marcar movimentação de caixa a serem exportadas
         UPDATE pcmovcr
            SET exportadoservint = 'X'
          WHERE (numvaleecf, DATA, codfunc, numcx) IN (
                   SELECT numvaleecf, dtlanc, codfunc, numcx
                     FROM pcvalecx
                    WHERE NVL (pcvalecx.exportadoservint, 'N') = 'X'
                      AND pcvalecx.dtlanc >= TRUNC (SYSDATE) - vgnumdias);
      EXCEPTION
         WHEN OTHERS
         THEN
            vsmensagem :=
                  'Nao foi possivel marcar registros para exportacao. Erro: '
               || SQLCODE
               || ' - '
               || SQLERRM;
            ROLLBACK;
            RAISE;
      END;

      BEGIN
         -- Gerar arquivos
         IF NOT exportar_pcvalecx (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                      'Não foi possível exportar o PCVALECX. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pcmovcr (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                       'Não foi possível exportar o PCMOVCR. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         -- Gerar dados do log e exportá-lo
         MERGE INTO pcservintersangria d
            USING (SELECT   pscodfilial AS codfilial,
                            NVL (pcvalecx.numvaleecf,
                                 pcvalecx.numvale
                                ) numvaleecf,
                            pcvalecx.dtlanc, pcvalecx.codfunc, pcvalecx.numcx,
                            MAX (pcvalecx.codcob) codcob,
                            MAX (pcvalecx.codbanco) codbanco,
                            MAX (pcvalecx.numserieequip) numserieequip,
                            MAX (pcvalecx.numvale) numvale,
                            MAX (SYSDATE) AS dtexportacao, MAX ('E') status,
                            MAX (1) itens_exp_pcvalecx,
                            MAX (pcmovcr.numtrans) AS numtrans,
                            SUM (DECODE (pcmovcr.numtrans, NULL, 0, 1)
                                ) itens_exp_pcmovcr
                       FROM pcvalecx, pcmovcr
                      WHERE NVL (pcvalecx.exportadoservint, 'N') = 'X'
                        AND pcvalecx.dtlanc >= TRUNC (SYSDATE) - vgnumdias
                        AND pcvalecx.numvaleecf = pcmovcr.numvaleecf(+)
                        AND pcvalecx.dtlanc = pcmovcr.DATA(+)
                        AND pcvalecx.codfunc = pcmovcr.codfunc(+)
                        AND pcvalecx.numcx = pcmovcr.numcx(+)
                   GROUP BY pscodfilial,
                            NVL (pcvalecx.numvaleecf, pcvalecx.numvale),
                            pcvalecx.dtlanc,
                            pcvalecx.codfunc,
                            pcvalecx.numcx) s
            ON (    (d.codfilial = s.codfilial)
                AND (d.numvaleecf = s.numvaleecf)
                AND (d.dtlanc = s.dtlanc)
                AND (d.codfunc = s.codfunc)
                AND (d.numcaixa = s.numcx))
            WHEN MATCHED THEN
               UPDATE
                  SET d.codcob = s.codcob, d.codbanco = s.codbanco,
                      d.numserieequip = s.numserieequip,
                      d.numvaleinter = s.numvale, d.numtransecf = s.numtrans,
                      d.dtexportacao = s.dtexportacao, d.status = s.status,
                      d.itens_exp_pcvalecx = s.itens_exp_pcvalecx,
                      d.itens_exp_pcmovcr = s.itens_exp_pcmovcr
            WHEN NOT MATCHED THEN
               INSERT (codfilial, numvaleecf, dtlanc, codfunc, numcaixa,
                       codcob, codbanco, numserieequip, numvaleinter,
                       numtransecf, dtexportacao, status, itens_exp_pcvalecx,
                       itens_exp_pcmovcr)
               VALUES (s.codfilial, s.numvaleecf, s.dtlanc, s.codfunc,
                       s.numcx, s.codcob, s.codbanco, s.numserieequip,
                       s.numvale, s.numtrans, s.dtexportacao, s.status,
                       s.itens_exp_pcvalecx, s.itens_exp_pcmovcr);

         IF NOT exportar_pcservintersangria (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                  'Não foi possível exportar o PCSERVINTERSANGRIA. Erro: '
               || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         -- Marcar registros como exportados
         UPDATE pcmovcr
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE (numvaleecf, DATA, codfunc, numcx) IN (
                   SELECT numvaleecf, dtlanc, codfunc, numcx
                     FROM pcvalecx
                    WHERE NVL (pcvalecx.exportadoservint, 'N') = 'X'
                      AND pcvalecx.dtlanc >= TRUNC (SYSDATE) - vgnumdias);

         UPDATE pcvalecx
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE NVL (exportadoservint, 'N') = 'X'
            AND dtlanc >= TRUNC (SYSDATE) - vgnumdias;

         COMMIT;
         psmensagem := vsmensagem;
      EXCEPTION
         WHEN exc_geracaodados
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;
         WHEN OTHERS
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;
      END;
   END;

   FUNCTION exportar_pccupomfiscalx (
      pscodfilial   IN       VARCHAR2,
      psmsg         OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccupomfiscalx';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codfilial,'
         || ' codigo,'
         || ' data,'
         || ' dtexportacao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' numcaixafiscal,'
         || ' numecf,'
         || ' sittribut,'
         || ' valor ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codfilial,'
         || ' codigo,'
         || ' data,'
         || ' dtexportacao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' importadoservprinc,'
         || ' numcaixafiscal,'
         || ' numecf,'
         || ' sittribut,'
         || ' valor '
         || ' FROM pccupomfiscalx '
         || ' WHERE codfilial = '''
         || pscodfilial
         || ''' AND NVL(exportadoservint,''N'') = ''X'''
         || '   AND data >= TRUNC(SYSDATE) - '
         || vgnumdias;

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pccupomfiscalx;

   FUNCTION exportar_pccupomfiscalz (
      pscodfilial   IN       VARCHAR2,
      psmsg         OUT      VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vstabela            VARCHAR2 (100);
      vsnomearquivo       VARCHAR2 (100);
      vsmensagem          VARCHAR2 (30000);
      v_sql               VARCHAR2 (30000);
      vbresultado         BOOLEAN;
      vsmsg               VARCHAR2 (30000);
      exc_geracao_dados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vbresultado := FALSE;
      vstabela := 'pccupomfiscalz';

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      IF NOT destruir_arquivo_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vsnomearquivo := vstabela || '_' || pscodfilial || '.dat';
      v_sql :=
            'CREATE TABLE exp_'
         || vstabela
         || ' ( codfilial,'
         || ' dtemissao,'
         || ' dtexportacao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' gtfinal,'
         || ' gtinicio,'
         || ' importadoservprinc,'
         || ' modelo,'
         || ' numcaixafiscal,'
         || ' numcupomfim,'
         || ' numcupominicio,'
         || ' numecf,'
         || ' nummapa,'
         || ' numreducaoz,'
         || ' numreinicio,'
         || ' numserie,'
         || ' vlcontabil ) '
         || ' ORGANIZATION EXTERNAL '
         || ' ( TYPE oracle_datapump '
         || ' DEFAULT DIRECTORY autoserv_dat_dir '
         || ' ACCESS PARAMETERS '
         || ' ( LOGFILE autoserv_log_dir: '''
         || vsnomearquivo
         || '%a_%p.log'' )'
         || ' LOCATION ('''
         || vsnomearquivo
         || ''' ) ) '
         || ' PARALLEL AS '
         || ' SELECT codfilial,'
         || ' dtemissao,'
         || ' dtexportacao,'
         || ' dtexportacaoservint,'
         || ' dtimportacaoservprinc,'
         || ' exportado,'
         || ' exportadoservint,'
         || ' gtfinal,'
         || ' gtinicio,'
         || ' importadoservprinc,'
         || ' modelo,'
         || ' numcaixafiscal,'
         || ' numcupomfim,'
         || ' numcupominicio,'
         || ' numecf,'
         || ' nummapa,'
         || ' numreducaoz,'
         || ' numreinicio,'
         || ' numserie,'
         || ' vlcontabil '
         || ' FROM pccupomfiscalz '
         || ' WHERE codfilial = '''
         || pscodfilial
         || ''' AND NVL(exportadoservint,''N'') = ''X'''
         || '   AND dtemissao >= TRUNC(SYSDATE) - '
         || vgnumdias;

      EXECUTE IMMEDIATE v_sql;

      IF NOT destruir_instancia_exportacao (pscodfilial, vstabela, vsmsg)
      THEN
         vsmensagem := vsmsg;
         RAISE exc_geracao_dados;
      END IF;

      vbresultado := TRUE;
      psmsg := vsmensagem;
      RETURN vbresultado;
   EXCEPTION
      WHEN exc_geracao_dados
      THEN
         psmsg := vsmensagem;
         RETURN FALSE;
      WHEN OTHERS
      THEN
         vsmensagem := SQLCODE || ' - ' || SQLERRM;
         psmsg := vsmensagem;
         RETURN FALSE;
   END exportar_pccupomfiscalz;

   PROCEDURE exportar_reducoes (pscodfilial VARCHAR2, psmensagem OUT VARCHAR2)
   IS
      vsmensagem         VARCHAR2 (2000);
      vsmsg              VARCHAR2 (2000);
      exc_geracaodados   EXCEPTION;
   BEGIN
      vsmensagem := '';
      vsmsg := '';

      BEGIN
         BEGIN
            UPDATE pccupomfiscalx
               SET exportadoservint = 'X'
             WHERE NVL (exportadoservint, 'N') = 'N'
                   AND codfilial = pscodfilial;

            UPDATE pccupomfiscalz
               SET exportadoservint = 'X'
             WHERE NVL (exportadoservint, 'N') = 'N'
                   AND codfilial = pscodfilial;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               vsmensagem :=
                     'Erro ao marcar reducoes para exportacao. Erro: '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               RAISE;
         END;

         IF NOT exportar_pccupomfiscalx (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                'Não foi possível exportar o PCCUPOMFISCALX. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         IF NOT exportar_pccupomfiscalz (pscodfilial, vsmsg)
         THEN
            vsmensagem :=
                'Não foi possível exportar o PCCUPOMFISCALZ. Erro: ' || vsmsg;
            RAISE exc_geracaodados;
         END IF;

         UPDATE pccupomfiscalx
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE NVL (exportadoservint, 'N') = 'X' AND codfilial = pscodfilial;

         UPDATE pccupomfiscalz
            SET exportadoservint = 'S',
                dtexportacaoservint = SYSDATE
          WHERE NVL (exportadoservint, 'N') = 'X' AND codfilial = pscodfilial;

         COMMIT;
         psmensagem := vsmensagem;
      EXCEPTION
         WHEN exc_geracaodados
         THEN
            ROLLBACK;
            psmensagem := vsmensagem;
         WHEN OTHERS
         THEN
            ROLLBACK;
            vsmensagem :=
                  'Erro ao marcar reducoes como exportadas. Erro: '
               || SQLCODE
               || ' - '
               || SQLERRM;
            psmensagem := vsmensagem;
      END;
   END;
END;
