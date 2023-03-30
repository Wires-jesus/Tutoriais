CREATE OR REPLACE PACKAGE IMPORTARVENDASCIASHOP IS
/*
Versão 28
     ----------------     Historico     ----------------
     Data                 Responsável                   Tarefa                  Comentario
     27/11/2018           Fabrício Lima                 INT-1711                Package passou a gravar o campo PCPEDC.USACORTECIASHOP a partir de PCPEDCTEMP.USACORTECIASHOP
     13/11/2018           Fabrício Lima                 INT-1040                Buscar dados do cliente na tabela PCCLIENTCIASHOP pelo número do pedido web (PCPEDC.NUMPEDWEB) e replicar este registro para a tabela PCVENDACONSUM. Gravar número de pedido WinThor (PCPEDC.NUMPED).
     23/10/2018           Fabrício Lima                 INT-1045                Package ImportarVendasCiashpo passou a validar o motivo de bloqueio nas rotina 398 e 307.
     01/10/2018           Fabrício Lima                 INT-1063                Package ImportarVendaCiaShop passou a gravar o campo NUMPEDMKTPLACE
     23/08/2018           Fabrício Lima                 INT-1356                Package ImportarVendaCiaShop passou a validar fundo de pobreza
     20/08/2018           Fabrício Lima                 INT-1404                Package ImportarVendasComple passou a gravar os campos pcpedi.vlbasefcpst, pcpedi.aliqfcp
     06/09/2017           Fabrício Lima                 Sem Tarefa              Package ImportarVendasCiashop
     31/08/2017           Fabrício Lima                 Sem Tarefa              Package ImportarVendasCiashop

*/
  -- Registro referente ao cabecalho do pedido.
  PROCEDURE IMPORTAR_PEDIDO_WEB(PNUMPEDWEB IN NUMBER ,PINTEGRADORA IN NUMBER ,PCODUSUR IN NUMBER, PCODFILIAL IN VARCHAR2);
END;
