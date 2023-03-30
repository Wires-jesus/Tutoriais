CREATE OR REPLACE TRIGGER TRG_INT_TROCAMANIF
 AFTER UPDATE OF NUMNOTA
 ON PCINDC
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

/*
    Trigger criada para atualizar registros de troca da tabela PCTROCAFVMANIF
      quando ocorrem devoluções pela rotina 1203, vinculadas à uma indenização
      importada do força de vendas

    ----------------     Historico     ----------------
    Data        Responsável           Tarefa     Comentario
    25/10/2012  Unilson Nascimento    179219     Versão Inicial
    15/02/2013  Unilson Nascimento               Inclusão do campo NUMNOTA
*/

begin
     if updating

     then
         if :new.numnota is not null and :new.numnota <> 0

         then
             begin
                  update pctrocafvmanif
                     set dtdevol = :new.dtdevol,
                         motivo  = (select motivo
                                      from pctabdev a, pcnfent b
                                     where b.coddevol = a.coddevol
                                       and b.numnota = :new.numnota),
                         numnota = :new.numnota
                   where :new.numindeniz = pctrocafvmanif.numindeniz;

              exception when no_data_found then
              null;

              end;

         end if;

     end if;

end;
