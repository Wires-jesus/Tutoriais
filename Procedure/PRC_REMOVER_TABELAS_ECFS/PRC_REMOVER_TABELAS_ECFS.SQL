CREATE OR REPLACE PROCEDURE prc_remover_tabelas_ecfs
IS
   c_dias_retencao CONSTANT PLS_INTEGER := 90;
   c_tamanho_lote  CONSTANT PLS_INTEGER := 500;

   l_habilitado VARCHAR2(1)
      := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('HABILITAR_PRC_REMOVER_TABELAS_ECFS', '99', 'S');

   l_data_limite pcpedcecf.data%TYPE;

   TYPE r_tabela_dependente IS RECORD (
      nm_tabela        VARCHAR2(30),
      cl_numpedecf     VARCHAR2(30),
      cl_codfunccx     VARCHAR2(30),
      cl_numserieequip VARCHAR2(30),
      cl_numcaixa      VARCHAR2(30)
   );

   TYPE t_tabelas_dependentes IS TABLE OF r_tabela_dependente;

   l_tabelas t_tabelas_dependentes;

   TYPE t_numpedecf     IS TABLE OF pcpedcecf.numpedecf%TYPE;
   TYPE t_codfunccx     IS TABLE OF pcpedcecf.codfunccx%TYPE;
   TYPE t_numserieequip IS TABLE OF pcpedcecf.numserieequip%TYPE;
   TYPE t_numcaixa      IS TABLE OF pcpedcecf.numcaixa%TYPE;

   l_numpedecf     t_numpedecf;
   l_codfunccx     t_codfunccx;
   l_numserieequip t_numserieequip;
   l_numcaixa      t_numcaixa;

   CURSOR cur_vendas IS
      SELECT numpedecf, codfunccx, numserieequip, numcaixa
        FROM pcpedcecf
       WHERE data < l_data_limite;

   PROCEDURE gravar_log_erro (p_mensagem IN VARCHAR2) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO pclogjob (modulo, funcao, tipo_log, data_log, ds_job, parametros)
           VALUES ('REMOVER_TABELAS_ECFS', 'ECF', 'N', SYSDATE, p_mensagem, NULL);

      COMMIT;
   END gravar_log_erro;

   FUNCTION regra (p_tabela         IN VARCHAR2,
                    p_numpedecf     IN VARCHAR2 DEFAULT 'numpedecf',
                    p_codfunccx     IN VARCHAR2 DEFAULT 'codfunccx',
                    p_numserieequip IN VARCHAR2 DEFAULT 'numserieequip',
                    p_numcaixa      IN VARCHAR2 DEFAULT 'numcaixa')
      RETURN r_tabela_dependente
   IS
      l_regra r_tabela_dependente;
   BEGIN
      l_regra.nm_tabela        := p_tabela;
      l_regra.cl_numpedecf     := p_numpedecf;
      l_regra.cl_codfunccx     := p_codfunccx;
      l_regra.cl_numserieequip := p_numserieequip;
      l_regra.cl_numcaixa      := p_numcaixa;
      RETURN l_regra;
   END regra;
BEGIN
   IF l_habilitado = 'N' THEN
      RETURN;
   END IF;

   l_tabelas := t_tabelas_dependentes(
      regra('pcpediecf'),
      regra('pcpediecfcesta'),
      regra('pcprestecf', p_codfunccx => 'codfunccheckout', p_numcaixa => 'numcheckout'),
      regra('pcautoriecf', p_numserieequip => 'serieequip'),
      regra('pcvendaconsumecf'),
      regra('pcorigemprecoecf'),
      regra('pcpedcecf')
   );

   l_data_limite := TRUNC(SYSDATE) - c_dias_retencao;

   OPEN cur_vendas;

   LOOP
      FETCH cur_vendas BULK COLLECT INTO l_numpedecf, l_codfunccx, l_numserieequip, l_numcaixa
         LIMIT c_tamanho_lote;

      EXIT WHEN l_numpedecf.COUNT = 0;

      FOR t IN 1 .. l_tabelas.COUNT LOOP
         FORALL i IN 1 .. l_numpedecf.COUNT
            EXECUTE IMMEDIATE
                  'DELETE FROM ' || l_tabelas(t).nm_tabela
               || ' WHERE '      || l_tabelas(t).cl_numpedecf     || ' = :1'
               || '   AND '      || l_tabelas(t).cl_codfunccx     || ' = :2'
               || '   AND '      || l_tabelas(t).cl_numserieequip || ' = :3'
               || '   AND '      || l_tabelas(t).cl_numcaixa      || ' = :4'
            USING l_numpedecf(i), l_codfunccx(i), l_numserieequip(i), l_numcaixa(i);
      END LOOP;

      COMMIT;
   END LOOP;

   CLOSE cur_vendas;
EXCEPTION
   WHEN OTHERS THEN
      IF cur_vendas%ISOPEN THEN
         CLOSE cur_vendas;
      END IF;

      ROLLBACK;
      gravar_log_erro(SUBSTR(DBMS_UTILITY.format_error_stack || CHR(10) ||
                              DBMS_UTILITY.format_error_backtrace, 1, 4000));
END prc_remover_tabelas_ecfs;
