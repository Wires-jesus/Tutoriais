/******************************************************************************************
 -> WIEW UTILIZADA PELA ROTINA 2075 PARA BAIXAR CRÉDITO AUTOMÁTICO DE CLIENTE
 -> Versao : Pacote
 -> Criada em 20/06/2008 - Juliana Teixeira
 -> Tarefa N.65550 - Reinaldo Pereira - Retirado NVL do campo valor contido no select dos dados da VIEW
                                        para permitir a alteração dos dados nesta coluna;
 -> Tarefa N.65693 - Juliana Teixeira - Ajuste na view para correcao de erro retirado todos os nvl para aceitar
                                        insert no banco de dados.
 -> Tarefa N.72720 - Juliana Teixeira - Ajuste na view para acrescentar gravação do campo historico;
 -> Tarefa N.81652 - Juliana Teixeira - Acrescentado campo numcupom para ser utilizado no estorno do credito na rotina 2075;
 -> Tarefa N.81068 - Juliana Teixeira - Acrescentado campos: nsutef, codadmcartao, hora, minuto para ser utilizado na operacao
                                        do SisCred gerada na rotina 2075;
*************************************************************************************************************/

CREATE OR REPLACE VIEW vw_pccrecli (
   codcli,
   dtlanc,
   codfilial,
   origem,
   numnota,
   numtransvenda,
   numtransentdevcli,
   valor,
   numtrans,
   numlanc,
   serie,
   dtdesconto,
   numped,
   situacao,
   codfilialdesc,
   numnotadesc,
   seriedesc,
   codfunc,
   hora,
   minuto,
   numtransvendadesc,
   numpedecf,
   numserieequip,
   numcaixa,
   historico,
   numcupom,
   nsutef,
   codadmcartao,
   codigo,
   codfunccx,
   bin )
AS
SELECT    codcli,
          dtlanc,
          codfilial,
          origem,
          numnota,
          numtransvenda,
          numtransentdevcli,
          valor,
          numtrans,
          numlanc,
          serie,
          dtdesconto,
          numped,
          situacao,
          codfilialdesc,
          numnotadesc,
          seriedesc,
          codfunc,
          hora,
          minuto,
          numtransvendadesc,
          numpedecf,
          numserieequip,
          numcaixa,
          historico,
          numcupom,
          nsutef,
          codadmcartao,
          codigo,
          codfunccx,
          bin
     FROM pccrecli
