CREATE OR REPLACE PROCEDURE PRC_AUX_DESD_TITULOS (p_numcar IN NUMBER, pmensagem OUT VARCHAR2)
IS
   CURSOR c_pcprest
   IS
      SELECT   pcprest.numtransvenda, pcprest.duplic, pcprest.codfilial,
               pcprest.codcli, pcprest.codusur, pcprest.codsupervisor,
               pcprest.numcheckout, pcprest.codfunccheckout,
               pcpedc.numserieequip, pcpedc.numped, MAX (pcprest.prest)
                                                                       prest
          FROM pcprest, pcnfsaid, pcpedc
         WHERE pcprest.numcar = p_numcar
           AND pcprest.numtransvenda = pcnfsaid.numtransvenda
           AND pcnfsaid.numped = pcpedc.numped
      GROUP BY pcprest.numtransvenda,
               pcprest.duplic,
               pcprest.codfilial,
               pcprest.codcli,
               pcprest.codusur,
               pcprest.codsupervisor,
               pcprest.numcheckout,
               pcprest.codfunccheckout,
               pcpedc.numserieequip,
               pcpedc.numped;

   vicontador   NUMBER;
BEGIN
   pmensagem := '';

   FOR reg_pcprest IN c_pcprest
   LOOP
      --Verificar se títulos já não foram desdobrados
      SELECT COUNT (*) contador
        INTO vicontador
        FROM pcprest
       WHERE numtransvenda = reg_pcprest.numtransvenda AND codcob = 'DESD';

      --Só desdobrar o que nunca foi desdobrado
      IF vicontador = 0
      THEN
         UPDATE pcprest
            SET codcob = 'DESD',
                vpago = valor,
                dtpag = dtemissao
          WHERE numtransvenda = reg_pcprest.numtransvenda;
      END IF;

      vicontador := reg_pcprest.prest;

      FOR c_pcprestecf IN (SELECT valor, codcob, dtvenc, dtvencorig,
                                  valororig, codcoborig, dtemissao
                             FROM pcprestecf
                            WHERE pcprestecf.duplic = reg_pcprest.duplic
                              AND pcprestecf.numcheckout =
                                                       reg_pcprest.numcheckout
                              AND pcprestecf.numserieequip =
                                                     reg_pcprest.numserieequip)
      LOOP
         vicontador := vicontador + 1;

         INSERT INTO pcprest
                     (codfilial, codcli,
                      codusur, prest, duplic,
                      valor, codcob,
                      dtvenc, dtvencorig,
                      dtemissao, operacao, boleto, status, numcar,
                      codsupervisor, numtransvenda,
                      vltxboleto, valororig, codcoborig,
                      codfilialnf, numcheckout,
                      codfunccheckout, codbarra, numbanco, numagencia,
                      numcheque, numcontacorrente
                     )
              VALUES (reg_pcprest.codfilial, reg_pcprest.codcli,
                      reg_pcprest.codusur, vicontador, reg_pcprest.duplic,
                      c_pcprestecf.valor, c_pcprestecf.codcob,
                      c_pcprestecf.dtvenc, c_pcprestecf.dtvencorig,
                      c_pcprestecf.dtemissao, 'N', 'N', 'A', p_numcar,
                      reg_pcprest.codsupervisor, reg_pcprest.numtransvenda,
                      0, c_pcprestecf.valororig, c_pcprestecf.codcoborig,
                      reg_pcprest.codfilial, reg_pcprest.numcheckout,
                      reg_pcprest.codfunccheckout, '', 0, 0,
                      0, 0
                     );

         UPDATE pcprestecf
            SET importado = 'S',
                numcar = p_numcar,
                numtransvenda = reg_pcprest.numtransvenda,
                numped = reg_pcprest.numped
          WHERE pcprestecf.duplic = reg_pcprest.duplic
            AND pcprestecf.numcheckout = reg_pcprest.numcheckout
            AND pcprestecf.numserieequip = reg_pcprest.numserieequip;
      END LOOP;
   END LOOP;

   COMMIT;
   pmensagem := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      pmensagem := 'ERRO AO DESD. TITULOS:' || SQLCODE || ' ' || SQLERRM;
END;
