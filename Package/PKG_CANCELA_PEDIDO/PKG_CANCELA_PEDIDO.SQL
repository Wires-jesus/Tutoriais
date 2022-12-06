create or replace package Pkg_cancela_pedido
is
/*  Package de cancelamento de pedido

    ----------------     Historico     ----------------
    Data        Responsável    Tarefa     Comentario
    03/05/2013  Andréa         197752     Primeira Versao - (alteracoes iniciais)
    23/05/2013  Andréa         199829     Incluir parâmetro de retorno que informa se pedido foi cancelado ou não
    10/10/2013  Andréa         213377     Retirar commit e rollback  
    13/11/2013  Andréa                    Incluir cancelamento de pedidos TV7 e TV8     
*/

 gregpcconsum  pcconsum%rowtype;
  procedure prc_cancela ( p_numped   in pcpedc.numped%type,
                          p_codfunc  in pcempr.matricula%type,
                          p_motivo   in varchar2,
                          p_codmotivo in number,
                          p_mensagem out varchar2,
                          p_cancelado out varchar2) ;
end ;--pkg_cancela_pedido;
