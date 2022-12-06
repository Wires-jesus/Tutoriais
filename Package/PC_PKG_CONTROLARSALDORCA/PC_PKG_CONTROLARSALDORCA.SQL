CREATE OR REPLACE PACKAGE PC_PKG_CONTROLARSALDORCA IS
  /*
    Package criada para controlar conta corrente de RCA

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
   15/04/2011 Thiago           128693 Alterada package para no ato de alguma devolução ou cancelamento não estornar o saldo caso o mesmo não tenho sido
  movimentado para itens do tipo combo através do campo "movimentacontacorrenterca"
   24/11/2011 Pablo             150203        Alteração para tratar a função ccrca_incluir_item_nf, pois estava gerando erro ao faturar venda TV5
   12/12/2012 Rodrigo Santos    183663        Ajuste para evitar erro "NO_DATA_FOUND" ocasionado pela desordenação do NUMSEQ causado na manipulação do pedido pelo Auto-Serviço.
   11/08/2014 Silvomar gomes    4040.086913.2014 ajuste para tratar excessão no método estornar para evitar duplicidade lançamento
   01/09/2014 Rodrigo Santos    HIS.03429.2014  Ajustada a package para considerar como bonificação as vendas TV14 onde no item estiver assinalado como brinde(PCPEDI.BRINDE = 'S').
   11/11/2014 silvomar gomes    3111.121405.2014 - Ajustado para tipo 5 faturado estornar o saldo. decode no condvenda para pegar punitcont na bnf.
   11/02/2015 Marcos Garcia     3285.013567.2015 Ajustado o estorno do conta corrente quando pedido bonificado.
   01/09/2015 Guilherme Freitas HIS.02580.2015  Alterações para contemplar processo de item bonificado na nota TV1.
   24/05/2016 Rafael Braga      2466.055888.2016 Na transferência de RCA, verificar se o pedido existe na PCMOV;PCMOVCOMPLE para evitar erro NO_DATA_FOUND.
   16/08/2016 Rafael Braga      2330.089655.2016 No caso de geração de brinde incluindo no mesmo pedido, o campo PCPEDC.BRINDE é não, mas PCPEDI.BRINDE é 'S'; ajustado para validar do item primeiro, para depois validar do pedido.
   */

  vrPARAMETROS PCLOGERRORCA%ROWTYPE;

  FUNCTION buscarversao RETURN NUMBER;

  FUNCTION CONTROLASALDORCA(pnumped IN  NUMBER,
                            vmsg    OUT VARCHAR2,
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

  FUNCTION CONTROLASALDORCA(pnumped IN  NUMBER) RETURN VARCHAR2;

  PROCEDURE proc_lerparametros(vsmensagem OUT VARCHAR2);

  FUNCTION ccfinrca_saldorcamenosdescfin(pcodusur   IN NUMBER,
                                         pcodfilial IN VARCHAR2)
    RETURN NUMBER;

  --RNG26
  FUNCTION ccrca_checar_limite_credito(p_codusur pcusuari.codusur%TYPE)
    RETURN NUMBER;
  FUNCTION ccger_checar_limite_credito(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER;
  FUNCTION ccsup_checar_limite_credito(p_codsupervisor pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER;

  -- RNG01
  FUNCTION ccrca_checar_saldo_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER;
  FUNCTION ccger_checar_saldo_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER;
  FUNCTION ccsup_checar_saldo_atual(p_codsupervisor pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER;

  -- RNG02
  FUNCTION ccrca_checar_disponivel_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER;
  FUNCTION ccger_checar_disponivel_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER;
  FUNCTION ccsup_checar_disponivel_atual(p_codsupervisor IN pcsuperv.codsupervisor%TYPE)
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
                                          p_tipo    IN VARCHAR
                                          -- tipo de operação I - Inclusao e E - Exclusao
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

  FUNCTION ccrca_verificar_fechamento(p_numtransvenda IN pcnfsaid.numtransvenda%TYPE)
    RETURN BOOLEAN;

  PROCEDURE ccrca_lancar_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc      IN pclogrca.rotina%TYPE,
                                         p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                         p_codfunccheckout IN pcnfsaid.codfunclanc%TYPE,
                                         p_dataemissao     IN DATE,
                                         p_mensagem        OUT VARCHAR2);

  PROCEDURE ccrca_lancar_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc          IN pclogrca.rotina%TYPE,
                                         p_numcar              IN pcnfsaid.numcar%TYPE,
                                         p_dataemissao_inicial IN DATE,
                                         p_dataemissao_final   IN DATE,
                                         p_mensagem            OUT VARCHAR2);

  PROCEDURE ccrca_validar_acerto_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                    p_rotinalanc    IN pclogrca.rotina%TYPE,
                                    p_numtransvenda IN pcnfsaid.numtransvenda%TYPE);

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
                                       p_numtransvenda IN pcnfsaid.numtransvenda%TYPE,
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
                                           p_codfunccheckout IN pcnfsaid.codfunclanc%TYPE,
                                           p_dataemissao     IN DATE,
                                           p_mensagem        OUT VARCHAR2);

  PROCEDURE ccfinrca_lanca_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc          IN pclogrca.rotina%TYPE,
                                           p_numcar              IN pcnfsaid.numcar%TYPE,
                                           p_dataemissao_inicial IN DATE,
                                           p_dataemissao_final   IN DATE,
                                           p_mensagem            OUT VARCHAR2);

  FUNCTION ccrca_saldo_item( -- 20 Parametros
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
                            p_prodBonific               IN pcpedi.BONIFIC%TYPE DEFAULT 'N')
    return number;

  PROCEDURE ccrca_bloquear_registro_rca(p_codusur IN PCUSUARI.CODUSUR%TYPE);

  TYPE t_pcconsum IS RECORD(
    usacredrca                   pcconsum.usacredrca%TYPE,
    bonificaltdebcredrca         pcconsum.bonificaltdebcredrca%TYPE,
    trocaaltdebcredrca           pcconsum.trocaaltdebcredrca%TYPE,
    brokeraltdebcredrca          pcconsum.brokeraltdebcredrca%TYPE,
    crmaltdebcredrca             pcconsum.crmaltdebcredrca%TYPE,
    tipomovccrca                 pcconsum.tipomovccrca%TYPE,
    usasaldocontacorrentedescfin pcconsum.usasaldocontacorrentedescfin%TYPE,
	usaptabelacomobase           pcconsum.usaptabelacomobase%type,
    usacredgerente               pcparamfilial.valor%TYPE,
    usacredsupervisor            pcparamfilial.valor%TYPE,
    tipomovccgerente             pcparamfilial.valor%TYPE,
    tipomovccsupervisor          pcparamfilial.valor%TYPE
    );


  gregpcconsum t_pcconsum;
END; --PC_PKG_CONTROLARSALDORCA
