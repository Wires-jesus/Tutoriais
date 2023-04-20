CREATE OR REPLACE PACKAGE PC_PKG_CONTROLARSALDORCA IS
  /*
    Package criada para controlar conta corrente de RCA
    -----------------------------------------------------------------------------------------------
    #VERSAO20210125A #VERSAO20210408A
    -----------------------------------------------------------------------------------------------
   ***********************************Histórico ***************************************
   Data         Responsável       Tarefa      Comentário
   19/05/2009   Andréa            73271       Projeto 71133
   01/07/2009   Andréa/Sabrina                Ajustes
   06/07/2009   Sabrina                       ccrca_alterar_rca e ccrca_retorna_saldo_item_pedido sao publicas
   08/07/2009   Sabrina                       Gravacao de historico de pclogrca e tratar pcusuari.usadebcredrca nulo
   09/07/2009   Sabrina                       A package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
                                              Ajuste na função de troca de RCA
   10/07/2009   Sabrina                       Correcao na inicializacao das variaveis booleanas
   16/07/2009   Sabrina                       Incluido novo procedimento ccrca_alterar_preco
   21/08/2009   Andréa                        Correção no saldo do item caso seja pedido bonificado
   03/09/2009   Andréa           89939        Projeto 85387 Conta Corrente RCa e Roteirização
   17/11/2009   Andréa           95731        Projeto 90992 Melhoria no desconto financeiro e saldo de conta corrente de rca
   30/11/2009   Andréa                        Correção no projeto para gravar dtfechaccrca na pcnfsaid
   03/12/2009   Andréa                        Corrigir para na ccfincrca_fatura_pedido para verificar 'FF' e 'VV'
   08/12/2009   Sabrina                       Correcao na declaracao das procedures:
                                              ccfinrca_lanca_movimento_carga e ccrca_lancar_movimento_carga
                                              que tambem sao publicas assim como:
                                              ccfinrca_lanca_movimento_caixa e ccrca_lancar_movimento_caixa
                                              Correcao na funcao ccrca_verificar_fechamento que estava sem valor de retorno
   09/12/2009   Andréa                        Correção na ccfincrca_excluir_item_pedido
   10/12/2009   Sabrina                       Correcao na ccfinrca_alterar_preco_qt
   11/12/2009   Sabrina                       Correcao na ccfinrca_devolve_notafiscal
                                              Correcao na ccfinrca_cancela_devolucao
   15/12/2009   Andréa           98438        Correção na ccrca_saldo_item ( acrescentado nvl no parâmetro usadebcredrca)
   16/12/2009   Andréa           98514        Correção para evitar erro de divisor zero  e selects retornando mais de um registro
   16/12/2009   Andréa           98514        Correção no calculo do valor ccfincrca_devolve_notafiscal
   16/12/2009   Andréa                        Alterar  ccfinrca_fatura_pedido para retornar TRUE quando for tipo 'VA'
   17/12/2009   Pablo                         Alterada  ccfinrca_fatura_pedido para retornar TRUE quando for tipo 'VA' e 'VF'
                                              como tinha sido customizado
   22/12/2009   Andréa           98953        Alteração em function ccfinrca_cancela_notafiscal                                              
   23/12/2009   Pablo            98963        Alteração em ccfinrca_cancela_notafiscal para o tipo VA
   11/01/2010   Thiago           99461        Caso o Numtransent seja menor que zero não realizar a chamada da função ccrca_retornar_saldo_item_dev
   11/01/2010   Andréa           99600        Ajuste na function ccfinrca_cancela_notafiscal, para verificar o saldo antes de lançar o débito   
   20/01/2010   Pablo            99976        Alteração para não retornar valor FALSE nas funções que validam Des. Financ. quando a venda for
                                              TV4, TV5 , TV8, TV11, TV13 ou TV20   
   23/02/2010   Pablo           102070        Caso o desconto financeiro seja gravado por valor  pcfilial.gravarvalordescfin = 'S' na 
                                              1) inclusão de itens individuais ccfinrca_incluir_item_pedido, 
                                              2) alteração de preco\qt         ccfinrca_alterar_preco_qt
                                              3) exclusão de item              ccfinrca_excluir_item_pedido
                                              não será realizado lancamento (o mesmo já foi realizado na digitação do pedido)                                              
   16/03/2010  Pablo            103974        Alteração para tratar venda TV5 na função ccrca_incluir_item_nf                                           
   19/03/2010  Pablo            100601        Alteração na função ccrca_saldo_item para validar na venda TV5 se o brinde vai mov D/C do RCA.
   19/03/2010  Pablo            103882        Correção da função vbvalido ccfinrca_altera_descfin_pedido
   06/04/2010  Pablo            105173        Correção da função ccfinrca_excluir_item_pedido
   07/04/2010  Pablo            105260        Alteração para criar as funções ccrca_retorna_saldo_anterior e ccrca_saldo_item com variação
                                              da chamada conforme o nr. de parametros
   13/04/2010 Thiago            105225        Erros homologação Fernandes             
   16/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.10 
   19/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.11  
   19/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.12  
   28/04/2010 Thiago            106838        Alteração na função ccfinrca_cancela_notafiscal caso não exista percentual de desconto financeiro
                                              retorna true para a função para permitir o cancelamento via rotina 1409 v.15.0.3.13                                       
   12/05/2010 Thiago            107825        Correção da função ccrca_excluir_item_dev                                              
   07/06/2010 Thiago            109141        Incluído o condvenda 20 na função ccrca_incluir_iten_nf para consideração do campo punitcont conforem solicitado                                     
   07/06/2010 Andréa            107526        Incluir verificação de combo (movimentacontacorrenterca)
                                              Foi incluida novas procedures com novo parâmetro : ccrc_saldo_item,ccrca_retorna_saldo_anterior
   09/08/2010 Thiago            113031        Alterada a chamada do procedimento "ccrca_validar_acerto_nf" para deduzir a quantidade devolvida                                                                                        
   03/09/2010 Pablo             114710        Tratar a função ccrca_incluir_item_nf para venda TV11 que não possui PCMOV.PUNIT somente PCMOV.PunitCont 
   29/10/2010 Thiago            119128        Alterada função "ccrca_incluir_item_nf" para validar o tipo de venda 13
   15/04/2011 Thiago            128693        Alterada package para no ato de alguma devolução ou cancelamento não estornar o saldo caso o mesmo não tenho sido
                                              movimentado para itens do tipo combo através do campo "movimentacontacorrenterca"

   -------------------------------- Específico -----------------------------------------------------------------------------
   16/09/2011 Pablo             143071        Alteração para controlar o saldo do RCA sem considerar o ST do preço de venda e preço base
                                              (PCPEDI.ST, PCPEDI.STPBASERCA) 
   28/11/2015 Anderson Silva                  Log dos Preços utilizados na Movimentação.
   25/03/2015 Anderson Silva   HIS.00632.2016 C/C RCA Televendas; STPBASERCA da Devolução pesquisar na PCPEDI
   05/05/2016 Anderson Silva   2956.050067.2016 - Merge Pacote função CONTROLASALDORCA
   05/05/2016 Anderson Silva   HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
   24/08/2016 Anderson Silva                  Merge: Rateio C/C RCA com o Supervisor
   24/08/2016 Anderson Silva                  Rateio C/C RCA com o Supervisor - Liquidez
   28/09/2016 Anderson Silva                  Limite Crédito Flexível
   13/10/2016 Anderson Silva   HIS.02933.2016 Rateio C/C RCA com a Empresa
   05/01/2016 Anderson Silva   4954.001502.2017 - Cancelamentos Limite por Liquidez
   20/01/2016 Anderson Silva                  Merge: Transferido o Rateio para o Faturamento por causa dos Locks
   06/02/2016 Anderson Silva                  Correção Condição LL no Faturamento
   30/05/2017 Anderson Silva   4493.058352.2017 Merge novos parametros CONTROLASALDORCA
   06/09/2017 Anderson Silva   HIS.00052.2017   Movimentação Faturamento por Pedido
   23/05/2018 Anderson Silva   HIS.00065.2018   Regra Específica para usar o saldo c/c somente no Peiddo e não acumular no RCA
   23/05/2018 Anderson Silva   Merge CC_ITEMBNF Item Bonificado em TV1
   01/07/2018 Anderson Silva   Mergem Regra Específica TIPOSALDORESERVADOPEDIDOFAT
   05/09/2018 Anderson Silva   Tratamento C/C Televendas com TIPOSALDORESERVADOPEDIDOFAT
   19/09/2018 Anderson Silva   Tratamento PREFAT
   23/04/2018 Anderson Silva   WT2300-157 - CC Televendas Call Center
   04/02/2019 Anderson Silva   MED-2073 - Compatibilidade com INTEGRADORA pacote
   22/03/2019 Anderson Silva   MED-2359 - Alteração Fechamento Carregamento para atender a PREFAT
   02/07/2019 Anderson Silva   DDMEDICA-146 - Cancelamento NF sem Prefat
   31/01/2020 Marcos Levi      DDMEDICA-2019 Não movimentar Saldo conta corrente ao cancelar Venda
   22/01/2020 Anderson Silva   DDMEDICA-5403 - Usar o PBASERCA com o parâmetro USAPBASERCACOMOBASE
   14/04/2023 Anderson Silva   DDVENDAS-41579 - Correção opção movimentar saldo rca brinde
   *************************************************************************************************************************
                                                                                         */
  FUNCTION buscarversao RETURN NUMBER;

  FUNCTION CONTROLASALDORCA(pnumped IN NUMBER, vmsg    OUT VARCHAR2,
                            pcodprod in number default 0,
                            pnumseq in number default 0) RETURN VARCHAR2;  
							
  FUNCTION CONTROLASALDORCA(psUsaCredRCAPCCONSUM      IN VARCHAR2,
                            psUsaDebCredRCA           IN VARCHAR2,
                            psBrinde                  IN VARCHAR2,
                            psBonificaAltDebCredRCA   IN VARCHAR2,
                            psTrocaAltDebCredRCA      IN VARCHAR2,
                            psBroker                  IN VARCHAR2,
                            psBrokerAltDebCredRCA     IN VARCHAR2,
                            psOrigemPed               IN VARCHAR2,
                            psCRMAltDebCredRCA        IN VARCHAR2,
                            psUsaDebCredRCACliente    IN VARCHAR2,
                            piCondVenda               IN NUMBER,
                            psBonificacaoMovimentaCC  IN VARCHAR2,
                            piVersaoIntegradora       IN NUMBER   DEFAULT 0) RETURN VARCHAR2;							

  PROCEDURE proc_lerparametros(vsmensagem OUT VARCHAR2);

  -- HIS.00632.2016 -- Objetivo: Função para Retornar o RCA do Conta-Corrente
  FUNCTION ObterRcaContaCorrente(pi_nCodUsur  IN NUMBER,
                                 pi_nNumPed   IN NUMBER)
  RETURN NUMBER;

  FUNCTION ccfinrca_saldorcamenosdescfin(pcodusur   IN NUMBER,
                                         pcodfilial IN VARCHAR2)
    RETURN NUMBER;

  --RNG26
  FUNCTION ccrca_checar_limite_credito(p_codusur pcusuari.codusur%TYPE)
    RETURN NUMBER;

  -- RNG01
  FUNCTION ccrca_checar_saldo_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER;

  -- RNG02
  FUNCTION ccrca_checar_disponivel_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER;

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 17 parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            p_pvenda               IN pcpedi.pvenda%TYPE,
                            p_ptabela              IN pcpedi.ptabela%TYPE,
                            p_pbaserca             IN pcpedi.pbaserca%TYPE,
                            p_qt                   IN pcpedi.qt%TYPE)
    RETURN NUMBER;

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 18 parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            p_pvenda               IN pcpedi.pvenda%TYPE,
                            p_ptabela              IN pcpedi.ptabela%TYPE,
                            p_pbaserca             IN pcpedi.pbaserca%TYPE,
                            p_qt                   IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind   IN pcpedi.usadebcredrcabrind%TYPE -- Tarefa 100601
                            ) RETURN NUMBER;

  -- Sabrina este procedimento passa a só ser acessado pelo próprio programa :
  -- A chamada publica eh por ccrca_excluir_item_pedido
  --RNG08
  --function ccrca_estorna_item_pedido (p_codfunclanc  in pclogrca.codfunc%type,
  --                                        p_rotinalanc   in pclogrca.rotina%type,
  --                                        p_codusur      in pcpedc.codusur%type,
  --                                        p_numped       in pcpedc.numped%type,
  --                                        p_codprod      in pcpedi.codprod%type,
  --                                        p_numseq       in pcpedi.numseq%type,
  --                                        p_qt           in pcpedi.qt%type)
  -- return boolean;

  -- RNG07
  FUNCTION ccrca_retorna_saldo_itempedido(p_numped  IN pcpedc.numped%TYPE,
                                          p_codusur IN pcpedc.codusur%TYPE,
                                          p_codprod IN pcpedi.codprod%TYPE,
                                          p_numseq  IN pcpedi.numseq%TYPE,
                                          p_qt      IN pcpedi.qt%TYPE,
                                          p_tipo    IN VARCHAR,
                                          -- tipo de operação I - Inclusao e E - Exclusao
                                          p_rotina                      IN pclogrca.rotina%TYPE DEFAULT 0,
                                          p_percrateiocredrcasupervisor IN pclogrca.percrateiocredrcasupervisor%TYPE DEFAULT 0
                                          ) RETURN NUMBER;

  --RNG09
  FUNCTION ccrca_incluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN;

  --RNG10
  FUNCTION ccrca_excluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qtanterior  IN NUMBER) RETURN BOOLEAN;

  --RNG11
  FUNCTION ccrca_alterar_preco_qt(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_numped      IN pcpedc.numped%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE,
                                  p_qtanterior  IN NUMBER) RETURN BOOLEAN;

  FUNCTION ccrca_alterar_preco(p_codfunclanc      IN pclogrca.codfunc%TYPE,
                               p_rotinalanc       IN pclogrca.rotina%TYPE,
                               p_codusur          IN pcpedc.codusur%TYPE,
                               p_numped           IN pcpedc.numped%TYPE,
                               p_codprod          IN pcpedi.codprod%TYPE,
                               p_numseq           IN pcpedi.numseq%TYPE,
                               p_qtanterior       IN NUMBER,
                               p_pvendaanterior   IN NUMBER,
                               p_pbasercaanterior IN NUMBER,
                               p_ptabelaanterior  IN NUMBER) RETURN BOOLEAN;

  --RNG14
  FUNCTION ccrca_incluir_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                 p_rotinalanc    IN pclogrca.rotina%TYPE,
                                 p_codusur       IN pcpedc.codusur%TYPE,
                                 p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                 p_codprod       IN pcpedi.codprod%TYPE,
                                 p_numseq        IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN;

  --RNG15
  FUNCTION ccrca_excluir_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                 p_rotinalanc    IN pclogrca.rotina%TYPE,
                                 p_codusur       IN pcpedc.codusur%TYPE,
                                 p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                 p_codprod       IN pcpedi.codprod%TYPE,
                                 p_numseq        IN pcpedi.numseq%TYPE,
                                 p_qtanterior    IN NUMBER) RETURN BOOLEAN;

  --RNG18
  FUNCTION ccrca_incluir_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_numtransent IN pcnfent.numtransent%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN;

  --RNG19
  FUNCTION ccrca_excluir_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_numtransent IN pcnfent.numtransent%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN;

  --RNG24
  FUNCTION ccrca_buscar_saldo_venda(p_numped  IN pcpedc.numped%TYPE,
                                    p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER;

  --RNG25
  FUNCTION ccrca_checar_alterar_rca(p_codusurorig    pcusuari.codusur%TYPE,
                                    p_codusurdestino pcusuari.codusur%TYPE,
                                    p_codfunclanc    pclogrca.codfunc%TYPE,
                                    p_rotinalanc     pclogrca.rotina%TYPE,
                                    p_numped         pcpedc.numped%TYPE)
    RETURN BOOLEAN;

  -- RNG20
  FUNCTION ccrca_alterar_rca(p_codusurorig    pcusuari.codusur%TYPE,
                             p_codusurdestino pcusuari.codusur%TYPE,
                             p_codfunclanc    pclogrca.codfunc%TYPE,
                             p_rotinalanc     pclogrca.rotina%TYPE,
                             p_numped         pcpedc.numped%TYPE)
    RETURN BOOLEAN;

  FUNCTION ccrca_verificar_fechamento(p_numtransvenda IN PCNFSAIDPREFAT.numtransvenda%TYPE)
    RETURN BOOLEAN;

  PROCEDURE ccrca_lancar_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc      IN pclogrca.rotina%TYPE,
                                         p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                         p_codfunccheckout IN PCNFSAIDPREFAT.codfunclanc%TYPE,
                                         p_dataemissao     IN DATE,
                                         p_mensagem        OUT VARCHAR2);

  PROCEDURE ccrca_lancar_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc          IN pclogrca.rotina%TYPE,
                                         p_numcar              IN PCNFSAIDPREFAT.numcar%TYPE,
                                         p_dataemissao_inicial IN DATE,
                                         p_dataemissao_final   IN DATE,
                                         p_mensagem            OUT VARCHAR2);

  PROCEDURE ccrca_validar_acerto_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                    p_rotinalanc    IN pclogrca.rotina%TYPE,
                                    p_numtransvenda IN PCNFSAIDPREFAT.numtransvenda%TYPE);

  FUNCTION ccfinrca_incluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc  IN pclogrca.rotina%TYPE,
                                        p_codusur     IN pcpedc.codusur%TYPE,
                                        p_numped      IN pcpedc.numped%TYPE,
                                        p_codprod     IN pcpedi.codprod%TYPE,
                                        p_numseq      IN pcpedi.numseq%TYPE,
                                        p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION ccfinrca_excluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc  IN pclogrca.rotina%TYPE,
                                        p_codusur     IN pcpedc.codusur%TYPE,
                                        p_numped      IN pcpedc.numped%TYPE,
                                        p_codprod     IN pcpedi.codprod%TYPE,
                                        p_numseq      IN pcpedi.numseq%TYPE,
                                        p_qtnova      IN pcpedi.qt%TYPE,
                                        p_preconovo   IN pcpedi.pvenda%TYPE,
                                        p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION ccfinrca_alterar_preco_qt(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qtnova      IN pcpedi.qt%TYPE,
                                     p_pvendanovo  IN pcpedi.pvenda%TYPE,
                                     p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION ccfinrca_altera_descfin_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                          p_rotinalanc  IN pclogrca.rotina%TYPE,
                                          p_codusur     IN pcpedc.codusur%TYPE,
                                          p_numped      IN pcpedc.numped%TYPE,
                                          p_novodescfin IN NUMBER,
                                          p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION ccfinrca_fatura_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_numped      IN pcpedc.numped%TYPE,
                                  p_mensagem    OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION ccfinrca_cancela_notafiscal(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                       p_rotinalanc    IN pclogrca.rotina%TYPE,
                                       p_codusur       IN pcpedc.codusur%TYPE,
                                       p_numtransvenda IN PCNFSAIDPREFAT.numtransvenda%TYPE,
                                       p_cancelapedido IN VARCHAR2,
                                       p_mensagem      OUT VARCHAR2)
    RETURN BOOLEAN;

  --Projeto 90992 - RBD15
  FUNCTION ccfinrca_devolve_notafiscal(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                       p_rotinalanc  IN pclogrca.rotina%TYPE,
                                       p_codusur     IN pcnfent.codusurdevol%TYPE,
                                       p_numtransent IN pcnfent.numtransent%TYPE,
                                       p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN;

  --Projeto 90992 - RBD16
  FUNCTION ccfinrca_cancela_devolucao(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                      p_rotinalanc  IN pclogrca.rotina%TYPE,
                                      p_codusur     IN pcnfent.codusurdevol%TYPE,
                                      p_numtransent IN pcnfent.numtransent%TYPE,
                                      p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN;

  PROCEDURE ccfinrca_lanca_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc      IN pclogrca.rotina%TYPE,
                                           p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                           p_codfunccheckout IN PCNFSAIDPREFAT.codfunclanc%TYPE,
                                           p_dataemissao     IN DATE,
                                           p_mensagem        OUT VARCHAR2);

  PROCEDURE ccfinrca_lanca_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc          IN pclogrca.rotina%TYPE,
                                           p_numcar              IN PCNFSAIDPREFAT.numcar%TYPE,
                                           p_dataemissao_inicial IN DATE,
                                           p_dataemissao_final   IN DATE,
                                           p_mensagem            OUT VARCHAR2);

  FUNCTION ccrca_saldo_item( -- 19 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda                    IN pcpedi.pvenda%TYPE,
                            p_ptabela                   IN pcpedi.ptabela%TYPE,
                            p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                            p_qt                        IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind        IN pcpedi.usadebcredrcabrind%TYPE, -- Tarefa 100601
                            p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type,
                            p_prodBonific               IN pcpedi.BONIFIC%TYPE DEFAULT 'N') -- MED-2073
    return number;
    
  FUNCTION ccrca_saldo_item( -- 22 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda                    IN pcpedi.pvenda%TYPE,
                            p_ptabela                   IN pcpedi.ptabela%TYPE,
                            p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                            p_qt                        IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind        IN pcpedi.usadebcredrcabrind%TYPE, -- Tarefa 100601
                            p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type,
                            p_stpvenda                  IN pcpedi.st%TYPE,
                            p_stptabela                 IN pcpedi.stptabela%TYPE,
                            p_stpbaserca                IN pcpedi.stpbaserca%TYPE,
                            p_prodBonific               IN pcpedi.BONIFIC%TYPE DEFAULT 'N' -- CC_ITEMBNF
                            )
    return number;    

  -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
  FUNCTION ccrca_incluir_titulo(p_numped        pcpedc.numped%TYPE,
                                p_numtransvenda PCPRESTPREFAT.numtransvenda%TYPE,
                                p_prest         PCPRESTPREFAT.prest%TYPE,
                                p_valorprest    PCPRESTPREFAT.valor%TYPE,
                                p_codfunclanc   pclogrca.codfunc%TYPE,
                                p_rotinalanc    pclogrca.rotina%TYPE)
  RETURN VARCHAR2;
  
  -- Procedimento para Controlar a Edição do Pedido (INICIO)
  PROCEDURE ccrca_inicio_edicao_pedido(p_numped      pcpedc.numped%TYPE,
                                       p_codfunclanc pclogrca.codfunc%TYPE,
                                       p_rotinalanc  pclogrca.rotina%TYPE);

  -- Procedimento para Controlar a Edição do Pedido (FIM)
  PROCEDURE ccrca_fim_edicao_pedido(p_numped      pcpedc.numped%TYPE,
                                    p_codfunclanc pclogrca.codfunc%TYPE,
                                    p_rotinalanc  pclogrca.rotina%TYPE);
        
  -- Função para retornar se o Rateio de C/C RCA está ativado na Empresa
  FUNCTION F_RATEIOCREDRCASUPERV_ATIVO 
  RETURN BOOLEAN;                            

  -- HIS.00052.2017
  FUNCTION ObterSaldoRcaPedidosNaoFat(pi_vTipoChamada IN VARCHAR2,
                                      pi_nCodUsur     IN NUMBER,
                                      pi_nNumPed      IN NUMBER)
  RETURN NUMBER;                                      
                                              
  TYPE t_pcconsum IS RECORD(
    usacredrca                   pcconsum.usacredrca%TYPE,
    bonificaltdebcredrca         pcconsum.bonificaltdebcredrca%TYPE,
    trocaaltdebcredrca           pcconsum.trocaaltdebcredrca%TYPE,
    brokeraltdebcredrca          pcconsum.brokeraltdebcredrca%TYPE,
    crmaltdebcredrca             pcconsum.crmaltdebcredrca%TYPE,
    tipomovccrca                 pcconsum.tipomovccrca%TYPE,
    usasaldocontacorrentedescfin pcconsum.usasaldocontacorrentedescfin%TYPE);

  gregpcconsum t_pcconsum;
  
  -- INICIO: MED-2073 ----------
  FUNCTION ccger_checar_disponivel_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER;
  FUNCTION ccsup_checar_disponivel_atual(p_codsupervisor IN pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER;

  FUNCTION ccger_checar_limite_credito(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER;
  FUNCTION ccsup_checar_limite_credito(p_codsupervisor pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER;

  FUNCTION ccger_checar_saldo_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER;
  FUNCTION ccsup_checar_saldo_atual(p_codsupervisor pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER;
  -- FIM: MED-2073 ----------
  
  PROCEDURE ccrca_bloquear_registro_rca(p_codusur IN PCUSUARI.CODUSUR%TYPE);

END; --PC_PKG_CONTROLARSALDORCA