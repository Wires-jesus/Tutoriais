/******************************************************************************************
 -> PROCEDURE UTILIZADA PELA ROTINA 2075 PARA EXECUTAR PROCESSO DE FATURAMENTO DA VENDA ASSISTIDA;
 -> PARA EXECUTAR A PROCEDURE FATURA_PEDIDO (PACOTE) VIA DBLSERVIDOR É NECESSÁRIO REPASSAR O PARAMETRO
 -> DE SAIDA pvc2menssagen CONFORME PROCEDURE P_FATURA_AUTOSERVICO;
 -> Versao : Pacote
 -> Criada em 21/07/2008 - Sabrina Feitosa/Juliana Teixeira - Tarefa N.63244/63246;
*************************************************************************************************************/

CREATE OR REPLACE PROCEDURE p_fatura_autoservico(pddataemicao         IN DATE,
                                pvc2emitente         IN VARCHAR2,
                                pncaregamento        IN NUMBER,
                                pvncodigocobranca    IN VARCHAR2,
                                pddatasaidaproduto   IN DATE,
                                pddataentregaproduto IN DATE,
                                pcodmotorista        IN NUMBER,
                                pcodveiculo          IN NUMBER,
                                pvc2codigofilial     IN VARCHAR2,
                                pnnumnotafiscal      IN NUMBER,
                                pnnumselonf          IN NUMBER) IS
pvc2menssagen varchar2 (2000);
BEGIN
  pvc2menssagen := '';
  faturamento.faturarpedido(pddataemicao,
                            pvc2emitente,
                            pncaregamento,
                            pvncodigocobranca,
                            pddatasaidaproduto,
                            pddataentregaproduto,
                            pcodmotorista,
                            pcodveiculo,
                            pvc2codigofilial,
                            pnnumnotafiscal,
                            pnnumselonf,
                            pvc2menssagen);

update pccarreg set obsfatur = substr(pvc2menssagen, 1, 254) where numcar = pncaregamento;
commit;

END p_fatura_autoservico;
