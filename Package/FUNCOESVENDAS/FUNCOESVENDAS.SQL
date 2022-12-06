CREATE OR REPLACE PACKAGE FUNCOESVENDAS IS

  /*
    Funções utilizadas em Rotinas de Vendas

   ***************************Histórico**********************************
   Data        Responsável      Tarefa          Comentário
   17/07/2006  Andréa            29637          Agrupar funções utilizadas em rotinas de vendas
   26/07/2006  Andréa                           Alteração na validação da Politica de desconto
   23/10/2006  Andréa           34176           Alterar para colocar mais uma procedure validardescontoquantidade para validar a coluna pcdescquant.perdescmax
   08/03/2007  Andréa           40181           Alterar verificação de comissões acrescentando comissões por plano de pagamento
   14/03/2007  Andréa           40443           Acrescentar verificação do parâmetro PCCONSUM.TRATARRESTRICAOACRESCIMO na politica de desconto e acrescentar a politica de desconto para verifica apenas acrescimos
   28/03/2007  Andréa           40925           Acrescentar comissões por região
   28/03/2007  Andréa           41489           Acrescentar comissão por margem de lucro
   11/05/2007  Andréa           42360           Acrescentar procedure validarpoliticadedesconto e validarpoliticasdesconto_acres para acrescentar parâmetro codplpag
   13/06/2007  Andréa           45790           Incluir outra procedure calcularst para calcular baseicst
   15/06/2007  Andréa           45842           Acrescentar calculo cmv e inclusão da informação pcclient.contribuinte para identificar cliente pessoa Fisica
   06/07/2007  Andréa           47117           Alterar função validarpolicaprecofixo para utilizar o menor preço fixo, caso tenha mais de um.
   03/08/2007  Andréa           48466           Inclusão da function BUSCARDADOSPRODUTOS
   07/08/2007  Andréa                           Acrescentar nvl para parâmetros pnperdesc e pnpvendamax
   08/08/2007  Andréa           48074           Alterar para que verifique parâmetro pcconsum.ordemavaliacaocomissaorca ao calcular a comissao
   09/08/2007  Andréa           48074           Corrigir parâmetro para executar politicasdesconto
   16/08/2007  Andréa           48721           Criar função para verificar restrição de venda
   21/08/2007  Andréa           49768           Incluir função calcularimpostos que já calcula o st e ipi
   28/08/2007  Andréa           50234           Corrigir arredondamento de st
   05/09/2007  Andréa           50691           Corrigir cálculo de st
   05/09/2007  Andréa           50731           Retornar alteração no cálculo de st e criar nova função calcularstfonte com mais parâmetros
   12/09/2007  Andréa           49781           Alterar calculo da função buscarprecocestabasica
   20/09/2007  Andréa           51575           Somar IPI ao pbaserca
   20/09/2007  Andréa           50761           Acrescentar pcdescquant.codplpagmax
   28/09/2007  Andréa           51275           Acrescentar numero do lote como parâmetro na procedure buscardadosprodutos para utilizar na politica de preço fixo
   01/10/2007  Andréa           51275           Alterar pvenda caso tenha precofixo - procedure buscardadosprodutos
   04/10/2007  Andréa           52392           Corrigir politicas de preco fixo para atualizar o ptabela mesmo que o preço fixo seja menor que o ptabela
   04/10/2007  Andréa           52426           Acrescentar nvl para calculo do custofin na funcao calcularcmv
   10/10/2007  Andréa           52681           Corrigir para não retirar IPI e ST do ptabela e pvenda
   17/10/2007  Andréa           52969           Zerar baseicst caso o valor de st seja zero
   24/10/2007  Andréa           53294           Zerar baseicst caso os seguintes parâmetros estejam nulos ou iguais a zero : iva(fonte),pauta,aliqicms1(fonte),aliqicms2(fonte)
   08/11/2007  Andréa           53895           Incluir procedure de calculo de verba de cmv
   19/11/2007  Aracelia         54331           Tratamento de nvl no retorno do Resultado vnpercom da Função
   27/11/2007  Aracelia         54549           Tratamento de um novo tipo de Comissão - Plano de Pagamento e Classe de Produto
   30/11/2007  Aracelia         54982           Criação de mais uma função para verificar Restrições de Venda por Depto/Seção e Fornecedor
   05/12/2007  Andréa           54695           Criação de mais 2 funções : validarpoliticasdesconto e validardescontoquantidade para verificar parâmetros
                                                pcdesconto.creditasobrepolitica,pcdescquant.creditasobreptabela
    21/12/2007  Andréa                          Corrigir para não retirar st do pvenda
    03/01/2008  Andréa           56190          Acrescentar outra procedure de cálculo de cmv para verificar parâmetro pcconsum.INCLUIRCOMISSAOSUGPVENDACMV
    04/01/2008  Aracélia         55590
    16/01/2008  Andréa           56600          Acrescentar a função para validar autorização de venda
    27/01/2008  Sabrina          57394          Nova funcao calcularstfonte com mais dois parametros
                                                Novas funcoes calculartodosimpostos, buscartributacao..etc
    29/01/2008  Andréa                           Correção no calculo de st
    08/02/2008  Andréa           57990           Alterar calculo de stfonte e st
    19/02/2008  Andréa           58544           Acrescentar vnl no cálculo do ptabela com desconto por quantidade
    25/03/2008  Andréa           60171           Acrescentar função de restrição de venda, adicionando parâmetros supervisor
    26/03/2008  Andréa           60402           Alteração nas procedures validarpoliticasdesconto
    01/04/2008  Andréa           60782           Corrigir cálculo de stfonte
    29/04/2008  Andréa           62051           Alterar cálculo da comissão, incluindo outra procedure. Alterando cadastro de comissão por região
    07/05/2008  Andréa           62525           Acrescentar na validação de restrição de venda o tipo ( F ou J)
    12/05/2008  Andréa           62823           Ajustes em mensagem de procedure de autorizacao de venda
    16/05/2008  Andréa           62525           Acrescentar na validação de restrição de venda do codepto e codsec
    27/05/2008  Andréa                           Acerto no cálculo de comissão
    29/05/2008  Andréa           62760           Acrescentar tipos de cálculo de comissão por RCA
    04/06/2008  Andréa           62661           Implementação de novo cálculo de comissão, conforme projeto 62162
    06/06/2008  Andréa           62661           Correção no cálculo de comissão
    24/07/2008  Sabrina          66005           Tratar pctribut.usavalorultentbasest2
    25/08/2008  Aracelia         67085           Retirar Valor de IPI do Preco de Venda ao calcular o diferencial de aliquotas no Calculo de ST Fonte
    08/09/2008  Andréa           55934           Acrescentar politica de preço fixo para, adicionando o parâmetro origemped
    10/09/2008  Andréa           63229           Alterações para enviar mensagens com detalhes de politicas
    16/10/2008  Andréa           70971           Não zerar ipi caso o cliente tenha suframa e o produto seja importado(S ou D)
    21/10/2008  Andréa           71118           Acerto no calculo de st para verificar parâmetro mostrarpvendasemst do item
    24/10/2008  Andréa           71575           Ajustes ao enviar mensagem para gravar origempreco
    31/10/2008  Andréa           71556           Correção no cálculo de st com IPI
    11/11/2008  Andréa           70574           Incluir regras do projeto 69444- Pauta de IPI na venda e IPI por filial
    10/12/2008  Andréa           73399           Incluir regras do projeto 70115- diferenciação de IVA para ST Fonte
    16/12/2008  Andréa           74194           Corrigir variável de politica de desconto ( acrescimo)
    20/03/2009  Andréa           80546           Retirar para não somar st no ptabela e pbaserca, no calculo de st, quando o parâmetro mostrarpvendasemst estiver marcado
    07/04/2009  Andréa           81820           Acrescentar função de cálculo de comissão para incluir comissão progressiva por plano de pagamento
    27/04/2009  Andréa           82893           Acrescentar area de atuacao do rca como parâmetro para verificar descontos da 561
    19/05/2009  Andréa           83954           Acrescentar nvls na validação de valor maximo de venda para pessoa fisica
    23/05/2009  Andréa           84770           Incluiro parâmetro regiao na verificação de cota por cliente e por rca
    29/05/2009  Andréa           85926           Corrigir erro de st
    15/06/2009  Andréa           82478           Incluir procedures para cálculo de comissão de acordo com projeto 80292
    19/06/2009  Andréa           86854           Incluir function para verificar bloqueio da 307
    03/07/2009  Andréa           68394           Projeto 63185 - Projeto Politica de desconto prioritaria
    13/07/2009  Andréa           88894           Correção na politica de desconto por quantidade para retornar o maior percentual de desconto
    16/07/2009  Andréa           88284           Acrescentar coluna clientemonitorado para verificação de bloqueio
    25/08/2009  Andréa           89929           Acrescentar função que valida campanha de desconto verificacampanhasdesconto - projeto 84891
    25/09/2009  Andréa           93480           Corrigir calculo de IPI para gnre = 'C'
    06/10/2009  Andréa           92051           Acrescentada mais uma função de  cálculo de preço fixo, acrescentando parÂmetro codigo da atividade
    26/10/2009  Andréa           93626: Gravar motivos de bloqueio da rotina 307- Conforme projeto 90090 - Melhorias E-Commerce IKEDA
    06/11/2009  Andréa                           Correção em cálculo de st
    30/11/2009  Andréa           96945           Correção em calculo de st
    18/01/2010  Andréa           98741  Incluir  nova procedure de cálculo de cmv para projeto de Diferencial de Aliquotas
    23/02/2010  Andréa          101745  Corrigir retorno de valor de comissão
   31/03/2010  Andréa          104684  Incluir procedure que define comissão pela Pcdesconto e nova procedure
                                       Definir_comissao_item_vendido   para chamar a nova procedure e passar parâmetro p_coddesconto
   05/04/2010  Andréa                  Correções em verificação de comissões
   30/04/2010  Andréa          106875  Correção em cálculo de st
   10/06/2010  Andréa          107766  Correção em mensagem de cota de rca
   21/06/2010  Andréa          109891  Corrigir procedures validarpoliticaprecofixo para verificar parâmetro p_codsupervisor
   28/06/2010  Andréa          109383  Alteração para corrigir procedure validarpoliticasdesconto   c/ 22 parametros para retornar corretamente a coluna alteraptabela
   22/07/2010  Andréa          109776  Incluir função que valida desconto por quantidade, utilizando o conceito de desconto por familia de produtos
   22/07/2010  Andréa          109811  Incluir procedure que valida politica de desconto (561), incluindo opção de retornar percentual para atualização
   23/07/2010  Andréa          111935  Correção na verificação de comissão por lucratividade                                    da base de deb/cred de rca
   28/07/2010  Pablo           112330  Alteração na função CALCULO_PRECO_SEM_IMPOSTOS para corrigir quando não existe IPI no preço
   17/08/2010  Andréa          111711  Criar novas funcoes de verificação de cota por rca e por cliente, retornando a quantidade disponivel da cota
   24/08/2010  Andréa          114245  Correção na função verificacampanhasdesconto para evitar erro ORA-1422
   14/09/2010  Andréa          114903  Incluir nova procedure calcularimpostos com 50 parametros para atender Nova legislação de ST (SC), conforme decreto 3467 que faz menção a clientes optantes pelo simples nacional
                                       Incluir nova procedure calcularcmv com 35 parâmetros para atender  Nova legislação de ST (SC), conforme decreto 3467 que faz menção a clientes optantes pelo simples nacional
                                       Incluir função calcularredsimplesnac com 21 parâmetros para atender  Nova legislação de ST (SC), conforme decreto 3467 que faz menção a clientes optantes pelo simples nacional
   16/09/2010  Andréa                  Correção no cálculo de redução do simples nacional
   23/09/2010  Andréa           116198 Corrigir processo de verificação de desconto de combo
   27/09/2010  Andréa                  Corrigir calculo de redução de simples nacional, acrescentando nvl
   18/10/2010  Andréa           117416 Alterações em campanhas de combo para fazer validações mesmo quando não tem restrições
   21/10/2010  Andréa           118690 Alterar para retornar valor de redução de simples nacional zerada, caso são tenha valor para o campo pctribut.PERCREDPVENDASIMPLESNAC
   22/10/2010  Andréa           118793 Corrigir e acrescentar mensagens na campanha de combos
   12/11/2010  Andréa           119830 Correção na politica de desconto prioritaria e acrescimo de outra function validarpoliticadedesconto para valdiar prioritaria e retornar
                                          percentual de deb/cred de rca
   18/11/2010 Andréa          	   120380 Correção na redução do iva
   24/11/2010 Andréa          	   120718 Correção nas procedure validarpoliticadedesconto que retornam percentual para alterar o pbaserca, para que o parâmetro cretisobrepolitica acompanhe o pbaserca
   25/11/2010 Andréa          	   121131 Incluir nova function calcularst com 27 parâmetros para enviar parâmetro pcclient.utilizaiesimplificada e alterar critérios de verificação de pessoa fisica.
								   		Alterar calcularimpostos ( 50 parâmetros) para verificar parâmetro pcclient.utilizaiesimpificada e pcconsum.aceitapfcontribuinte
   08/12/2010 Andréa          	   121869 Alterar procedure validarpoliticasdesconto ( 20 parÂmetro) para valida coluna pcdesconto.aplicadescsimplesnacional
   16/12/2010  Andréa         	   119626 Criar procedure validarpoliticasdesconto com 25 parÂmetros para retornar o percentual de atualização da base de deb/cred de rca
								   		para acréscimos e também retornar o campo alteraptabela
   21/12/2010  Andréa         	   121932 Alterar function verificacampanhasdesconto para verificar produtos por codigo de campanha
   03/01/2011  Andréa         	   123757 Corrigir politica de desconto para quando tem politica prioritaria, mas a opção é de usar uma que não é prioritaria
   05/01/2011  Andréa         	          Corrigir para retornar parâmetro alteraptabela na validarpoliticasdesconto
   05/04/2011  Andréa         	   129753 Acrescentar nvl para o campo pcest.valorultent
   18/05/2011  Andréa         	   124877 Incluir nova função e validação de desconto por quantidade com 20 parâmetros para retornar se a politica alterar ou não a base de cred/deb de rca
   23/05/2011  Andréa         	   124877 Incluir nova função e validação de desconto por quantidade com 20 parâmetros para retornar se a politica alterar ou não a base de cred/deb de rca
								   		e qual o percentual que será utilizado para alterar a base do rca
   30/05/2011  Andrea         	   133508 Corrigir cálculo de st para retirar impostos do preço de venda, quando estiver parametrizado mostrarpvendasemst = 'S'
   08/06/2011  Thiago Melo    	   132417 Alterar function calculo_preco_sem_imposto para receber mais 2 parÂmetros
   08/06/2011  Andréa         	   134209 Corrigr cálculo de st fonte, retirando verificação do parâmetro pcclient.calculast
   13/06/2011  Andréa         	   133171 Calcular a ST com base no PMC (Preço Máximo ao Consumidor) do produto. Alteração das functions calcualast ,calcularst fonte e calcularimpostos
   21/06/2011  Andréa         	   135428 Corrigir calculo de stfonte e st para utilizar valorultent quando não tiver custonfsemst
   06/07/2011  Andrea         	   136169 Corrigir calculo de st para retirar st do preço de venda, preço de tabela e pbaserca. Quando parâmetro mostrarpvendasemst = 'S' e cliente isento de st
   13/07/2011  Andréa         	   129117      Verificar parÂmetro 'NAOUSARAUTDEBCREDPOLDESC' da pcparamfilial. Caso esteja 'N' ou nulo, a verificação do percentual para
								   			cálculo do pbaserca permanece como está atualmente. Caso esteja 'S', o percentual para cálculo do pbaserca será o percentual
								   			da politica utilizar , permanecendo as regras de verificação dos parÂmetros basecreddebrca e
								   				creditasobrepolitica da 561. Lembrando que a verificação deste parâmetro é apenas para a 561.
   14/07/2011  Andréa         	   137208 Acrescentar verificação da coluna codred no calculo de percentual de verba de cmv
   19/07/2011  Andréa         	   134565 Alterar verificação de restrição de venda acrescentando os campos codfilial, condvenda,origemped e fretedespacho.
   30/07/2011  Andréa         	   138426 Corrigir politica de desconto da 561
   01/08/2011  Andréa         	   138426 Correção em calculo de st
   18/08/2011  Andréa         	   139490 Alteração em processo de retirar impostos de preço ( parâmetro mostrarpvendasemst = 'S')
   22/08/2011  Andréa         	   134512 Incluir colunas codrede e codmarca na verificação de politica de desconto 561
   22/08/2011  Andréa         	   138760 Acrescentar parâmetro codauxiliar na verificação da restrição de venda
   19/09/2011  Andréa         	   141861 Acrescentar 2 novas funções : validardescontoporquantidade e validarpolitica de desconto. Com as opção de politicas prioritarias
   22/09/2011  Andrea         	   144322 Acrescentar regra para que se o cálculo para retirar os impostos do preço for maior que o preço, utilizar o preço inicial
   27/09/2011  Andréa         	   144457 Correção em processo de comissao que utiliza PCCOMISSAOUSUR
   03/10/2011  Andréa         	   139798 Alterar função que valida preço fixo, acrescentando parâmetro codfilial
   12/10/2011  Andréa         	   146618 Verificar parâmetro tipocalculognre em conjunto com mostrarpvendasemst
   14/10/2011  Andréa         	   146866 Corrigir validação de preço fixo com novo parÂmetro codfilial
   21/10/2011  Andréa         	   147430 Corrigir parâmetro de mensagem da politica de desconto por quantidade
   26/10/2011  Andréa         	   147480 Corrigir validação de politica de preco fixo
   31/10/2011  Andréa         	   148087 Acrescentar nvl para o parâmetro p_naousarautdebcredpoldesc para 'N'
   04/11/2011  Andréa         	   148084 Alterar para não arredondar stfonte, caso o parâmetro tipocalcst esteja = 'CT'
   16/11/2011  Andréa         	   145197 Incluir nova função que valida a tabela PCPLPAGRESTRICAO
   21/11/2011  Andréa         	          Ajuste em select da pcdesconto utilizando coluna errada
   21/11/2011  Andrea         	   149744 Alterar forma de verificar PCPLPAGRESTRICAO
   23/11/2011  Andréa         	          Alterar forma de verificar PCPLPAGRESTRICAO
   02/12/2011  Andréa         	   150891 Ajuste para não zerar aliquotas de stfonte quando usar preço maximo ao consumidor, mesmo ivafonte estando zero
   07/12/2011  Andréa         	   148981 Incluir no processo de desconto do combo o tipo MIQ e verificar a data com horario
   19/12/2011  Andréa         	   147507 Incluir procedure validarpoliticadesconto_med com desconto financeiro para medicamentos
   05/01/2012  Andréa         	   151557 Incluir verificação do codrede na validação de preço fixo
   20/01/2012  Andréa         	   149677 Incluir na verificação de restrição de venda (pcrestricaovenda) os campos :codcob e codplpag
   26/01/2012  Andréa         	   154886 Alterar forma de identificação de pessoa fisica no calculo de cmv
   27/01/2012  Andréa         	   148142 Incluir validação de restrições para desconto por quantidade(pcgruposcampanhac e pcgruposcampanhai)
   06/02/2012  Andréa         	   133659 Incluir restrição por classevenda ( pcclient) para politicas de desconto por quantidade e preço fixo
   07/02/2012  Andréa         	   143646 Incluir validação de politica prioritaria geral na 561
   07/02/2012  Andréa         	   150045 Incluir validação do parâmetro pcusuari.VISUALIZARPRODDPTOSEC caso esteja 'S' e tenha registro na tabela PCUSURDEPSEC
								   		para o rca do pedido, validar se item pertence ao departamento e seção cadastrados
   27/02/2012  Andréa         	   152144 Incluir verificação restricao do plano de pagamento (pcplpagrestricao) por categoria e subcategoria
   07/03/2012  Andréa         	          Altera nome da coluna  pcusuari.VISUALIZARPRODDPTOSEC para VISUALIZARPRODDEPTOSEC
   28/03/2012  Andréa         	   158600 Incluir nova procedure DEfinir_comissao_item_vendido para retornar codigo da comissao, rotina e mensagens de rejeição .
								   		Incluir novas funcoes : validarpoliticadesconto e validardescontoquantidade para retornar codigo da politica do percentual de pbaserca
   30/03/2012  Andréa         	   159918 Corrigir calculo de redução do simples nacional
   27/04/2012  Andréa         	   160454 Acrescentar validação da coluna apenasplpagamx da pcdesconto
   11/05/2012  Marcos         	   162850 Inclusão de função de retornar limite de credito de cliente BUSCARLIMITE
   06/06/2012  Marcos         	   164790 Juste retornar saldo cliente
   14/06/2012  Andréa         	   165439 Correção no calculo de st para usar o custo da ultima entrada quando o parametro usavalorultentbasest2 estiver marcado
   05/07/2012  Andréa         	   165417 Incluir validação de politica de desconto por quantidade por Filial
   16/07/2012  Andréa         	          Correção em parâmetro apenasplpagmax da pcdesconto
   18/07/2012  Andréa         	   165466 Correção para envio da data final de velidade da politica
   19/07/2012  Andréa         	   167828 Correção em politica a 561
   05/10/2012  Andréa         	          Tonar públicas as procedures :definir_comiss_pccomissaousur e validarpccomissaoregiao
   01/10/2012  Andréa         	   176084 Gravar percipi na pcpedi apenas se ipi for calculado utilizando percipivenda
   28/11/2012  Andréa         	   182166 Acrescentar nvl no campo utilizacodprodprinc na validação da pcdescontoc
   04/12/2012  Andréa         	   183141 Corrigir campanhas de combo tipo 'MIQ' para validar faixas de quantidade
   27/12/2012  Andréa         	   185302 Corrigir validação de politica de desconto (561) com plano de pagamento
   04/01/2013  Andréa         	   185984 Corrigir validacao de politica de desconto (561) sem plano de pagamento
   06/01/2013  Andréa         	   189039 Corrigir procedure que validar valor de venda de pessoa fisica, acrescentando  para validar se PCCLIENT.VALIDAMAXVENDAPF está marcado nos selects gerais
   15/02/2013  Andréa         	   189802 Corrigir para verificar se comissão da tabela pcclientfilial está preenchida
   28/02/2013  Andréa         	   191089 Atualizar calculo de impostos com a 316
   19/03/2013  Andréa         	   192724 Correção em processo de desconto combo
   02/04/2013  Andréa         	   193805 Alterar para não utilizar valor enviado pela função que retira impostos se o valor que ela retornar for maior que o valor de venda
   05/04/2013  Andréa         	   194469 Correção em combo para validar codprod além do codcombo para campanha tipo MIQ
   10/04/2013  Andréa         	   194321 Incluir função de calculo de st para clientes do estado MT
   18/04/2013  Andréa         	   195951 Alterar gravação do codigo do combo no campo codpromocao
   30/04/2013  Andréa         	   197134 corrigir definição do campo suframa para ser do mesmo tipo do campo na tabela pcclient
   17/05/2013  Andréa         	   199436 Corrigr calcularimpostos com 46 para usar preço sem impostos corretamente
   12/06/2013  Andréa         	   202108 Alterar valor defult de parametro retiraimp, utilizado para identificar se deve ou não retirar o imposto do preço
   25/06/2013  Andréa         	   185261 Acrescentar comissao por embalagem
   03/07/2013  Andréa         	   178683 Incluir opção de utilizar venda e preço por emebalagem nos itens da cesta
   05/07/2013  Andréa         	   204123 Comentar alteração da tarefa 178683
   29/07/2013  Andréa         	   201665 Atualizar função  que retorna preços sem impostos para igualar com a 316
   15/08/2013  Andréa         	   207034 Incluir procedure de cálculo de comissão por profissional
   16/08/2013  Andréa         	   207714 Atualizar regra de utilização do preço fixo
   23/08/2013  Andrea         	   179985 Incluir restricao por plano de pagamento na validação de combo
								   		                    Incluir validação do codauxiliar no preço fixo, caso esteja parametrizado precoporembalagem

   02/09/2013  Andréa         	   209291 Corrigir validação de preço fixo
   06/09/2013  Andréa         	   210098 Corrigr gravação de percipi
   11/10/2013  Andréa         	   213666 Ajustes em politicade desconto da 387 para não arredondar preços para o Myshop
   23/10/2013  Andréa         	   3559.000578.2013  correção em validação de plano de pagamento em politica da 561 de Medicamentos
   29/10/2013  Andréa         	   HIS.00045.2013    Inclusão de regra de st para clientes de MG ( legislação)
   27/12/2013  Andréa         	   1475.022216.2013  Alterar para permitir calcular stfonte mesmo que tenha aliquota de st normal
   10/01/2014  Andréa         	   HIS.01194.2013    Incluir calculo de st do RJ
   25/02/2014  Andréa         	   HIS.00404.2014    Incluir calculo de st do RJ com pauta
   25/02/2014  Andréa         	   HIS.00433.2014    Incluir calculo de st do RJ para fonte
   09/05/2014  Luciano Lima   	   1612.044186.2014  Correção do calculo do st rj.
   24/06/2014  Luciano Lima   	   1880.068073.2014 Ajuste no cálculo do simples nacional (alterado também na INTEGRADORA)
   26/06/2014  Luciano Lima   	   2466.060256.2014  Ajuste na validação das políticas de desconto da 357 e 201
   04/07/2014  Luciano Lima   	   1612.064252.2014  Ajuste na passagem de parametro para o cálculo do st rj (revisado em 04/07/2014 por Rafael Soares)
   04/07/2014  Rafael Braga        HIS.02177.2014    Adicionado outras regras de cálculo de ST RJ.
   15/09/2014 Marcos Garcia   	   2701.098818.2014    Ajustado o problema do desconto de simples nacional que não estava sendo validado.
   01/12/2014  Luciano Lima   	   2984.133630.2014  criada a variavel base2 para o calculo do vnSTf2 do ST na funcao calcularstfonte.
   11/02/2015  Leandro/Marcos 	   3717.016212.2015  Checar parâmetro 2210 para antes de fazer o cálculo de IPI.
   01/06/2015  Guilherme Freitas   HIS.01849.2015	Ajustado para tratar o cálculo do ST de acordo com parâmetrização no produto e no ramo de atividade.
   17/07/2015  Rafael Braga        0.080679.2015  Ajustado para tratar o parâmetro p_abaterimpostoscomissaorca conforme rotina 316 na função calcularcmv.
   18/08/2015  Guilherme Freitas   HIS.02023.2015  Incluso 2 metódos que estavam na integradora. Diana estava aparecendo.
   01/10/2015  Leandro Bastos      1020.110056.2015 Ajuste buscar preço fixo corretamente
   26/11/2015  Iran Junior         HIS.05177.2014  Adicionado parametros cmv para calculo diferenciado para itens bonificado.
   22/12/2015  Rafael Braga        HIS.04531.2015   Implementado cálculo do CMV do ICMS Partilha
   08/03/2016  Rafael Soares       630.026348.2016 Ajustado erro no plano de pagamento com restrição
   05/05/2016  Rafael Braga        5574.040724.2016 Ajustado para arredondar desconto em 2 casas no cálculo da comissão ValidarPCComissaoRegiao, pois na rotina 363 de cadastro só permite 2 casas.
   19/07/2018  Marcos Garcia      WT300-166          Implementado o calculo do cmv para receber o vlfecp para abater no calculo    
  */
  TYPE t_parametros IS RECORD(
    utilizapercbaseredpf     pcconsum.utilizapercbaseredpf%TYPE,
    tipocalcst               pcconsum.tipocalcst%TYPE,
    calcstpf                 pcconsum.calcstpf%TYPE,
    mostrarpvendasemst       pcconsum.mostrarpvendasemst%TYPE,
    consideraisentoscomopf   pcconsum.consideraisentoscomopf%TYPE,
    numcasasdecvenda         pcconsum.numcasasdecvenda%TYPE,
    calcularstcomipi         pcconsum.calcularstcomipi%TYPE,
    tipocalcipi              pcconsum.tipocalcipi%TYPE,
    tipocalcsulframa         pcconsum.tipocalcsulframa%TYPE,
    usartributacaotransftv10 pcconsum.usartributacaotransftv10%TYPE);

  FUNCTION buscarparametros --2 parametros
  (p_regparametros IN OUT t_parametros, p_mensagem OUT VARCHAR2)
    RETURN BOOLEAN;

  TYPE t_filial IS RECORD(
    codigo pcfilial.codigo%TYPE,
    uf     pcfilial.uf%TYPE);

  FUNCTION buscarfilial --3 parametros
  (p_codfilial IN NUMBER,
   p_regfilial IN OUT t_filial,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN;

  type t_produto is record(
    codprod      pcprodut.codprod%type,
    tipomerc     pcprodut.tipomerc%type,
    percipivenda pcprodut.percipivenda%type);

  FUNCTION buscarproduto --3 parametros
  (p_codprod    in number,
   p_regproduto in out t_produto,
   p_mensagem   out varchar2) return boolean;

  type t_cliente is record(
    codcli                  pcclient.codcli%type,
    tipofj                  pcclient.tipofj%type,
    isentoipi               pcclient.isentoipi%type,
    estent                  pcclient.estent%type,
    ieent                   pcclient.ieent%type,
    sulframa                pcclient.sulframa%type,
    calcularst              pcclient.calculast%type,
    contribuinte            pcclient.contribuinte%type,
    clientefontest          pcclient.clientefontest%type,
    isentoicms              pcclient.isentoicms%type,
    consumidorfinal         pcclient.consumidorfinal%type,
    utilizaiesimplificada   pcclient.utilizaiesimplificada%type,
    tipoempresa             pcclient.tipoempresa%type,
    tipodescisencao         pcclient.tipodescisencao%type,
    perdescisentoicms       pcclient.perdescisentoicms%type,
    usaivafontediferenciado pcclient.usaivafontediferenciado%type,
    ivafonte                pcclient.ivafonte%type);

  function buscarcliente --3 parametros
  (p_codcli     in pcclient.codcli%type,
   p_regcliente in out t_cliente,
   p_mensagem   out varchar2) return boolean;

  TYPE t_tributacao IS RECORD(
    codst pctribut.codst%TYPE,
    -- Parametros
    tipocalculognre      pctribut.tipocalculognre%TYPE,
    utilizapercbaseredpf pctribut.utilizapercbaseredpf%TYPE,
    usavalorultentbasest pctribut.usavalorultentbasest%TYPE,
    -- ST
    iva           pctribut.iva%TYPE,
    pauta         pctribut.pauta%TYPE,
    aliqicms1     pctribut.aliqicms1%TYPE,
    aliqicms      pctribut.aliqicms2%TYPE,
    percbaseredst pctribut.percbaseredst%TYPE,
    -- ST Fonte
    ivafonte              pctribut.ivafonte%TYPE,
    aliqicms1fonte        pctribut.aliqicms1fonte%TYPE,
    aliqicms2fonte        pctribut.aliqicms2fonte%TYPE,
    percbaseredstfonte    pctribut.percbaseredstfonte%TYPE,
    perbaserednrpa        pctribut.perbaserednrpa%TYPE,
    percbaseredconsumidor pctribut.percbaseredconsumidor%TYPE,
    -- ST Transferência
    ivatransf           pctribut.ivatransf%TYPE,
    pautatransf         pctribut.pautatransf%TYPE,
    aliqicms1transf     pctribut.aliqicms1transf%TYPE,
    aliqicms2transf     pctribut.aliqicms2transf%TYPE,
    percbaseredsttransf pctribut.percbaseredsttransf%TYPE,
    -- Suframa
    perdescsuframa pctribut.perdescsuframa%TYPE,
    -- Isencao de ICMS
    perdescicmisencao pctribut.perdescicmisencao%TYPE,
    -- ISS
    aliqiss pctribut.aliqiss%TYPE);

  FUNCTION buscartributacao --3 parametros
  (p_codst         IN NUMBER,
   p_regtributacao IN OUT t_tributacao,
   p_mensagem      OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticaprecofixo --18 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION validardescontoquantidade --10 parametros
  (p_tipoteste        IN NUMBER,
   p_codprod          IN NUMBER,
   p_qtde             IN NUMBER,
   p_numregiao        IN NUMBER,
   p_ptabela          IN NUMBER,
   p_codpraca         IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_ptabeladesc      OUT NUMBER) RETURN BOOLEAN;

  FUNCTION validardescontoquantidade --11 parametros
  (p_tipoteste        IN NUMBER,
   p_codprod          IN NUMBER,
   p_qtde             IN NUMBER,
   p_numregiao        IN NUMBER,
   p_ptabela          IN NUMBER,
   p_pvenda1          IN NUMBER,
   p_codpraca         IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_ptabeladesc      OUT NUMBER) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto --13 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto_acres --13 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto --14 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_codplpag         IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto_acres --14 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_codplpag         IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto --18 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER) RETURN BOOLEAN;

  FUNCTION validarpoliticaprecofixo --19 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION verificarcotarca --4 parametros
  (p_codprod  IN NUMBER,
   p_codusur  IN NUMBER,
   p_qtpedida IN NUMBER,
   p_mensagem OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION verificarcotacliente --4 parametros
  (p_codprod  IN NUMBER,
   p_codcli   IN NUMBER,
   p_qtpedida IN NUMBER,
   p_mensagem OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION verificarestoquecontabil --7 parametros
  (p_codprod             IN NUMBER,
   p_codfilial           IN VARCHAR2,
   p_condvenda           IN INTEGER,
   p_qtpedida            IN NUMBER,
   p_verificaestoquecont IN VARCHAR2,
   p_mensagem            OUT VARCHAR2,
   p_qtestdisp           OUT NUMBER) RETURN BOOLEAN;

  FUNCTION verificarvalormaximovendapf --12 parametros
  (p_codcli                 IN NUMBER,
   p_vladicional            IN NUMBER,
   p_vlpedoriginal          IN NUMBER,
   p_percvenda              IN NUMBER,
   p_aceitavendapf          IN VARCHAR2,
   p_verificarlimvendapf    IN VARCHAR2,
   p_vlmaxvendapf           IN NUMBER,
   p_perlimvendapf          IN NUMBER,
   p_vlmaxpedidopf          IN NUMBER,
   p_consideraisentoscomopf IN VARCHAR2,
   p_codfilial              IN VARCHAR2,
   p_mensagem               OUT VARCHAR2) RETURN BOOLEAN;

  PROCEDURE buscarprecocestabasica --13 parametros ( sendo 7 obrigatórios)
  (p_numped    NUMBER,
   p_codprod   NUMBER,
   p_numregiao NUMBER,
   p_numpr     NUMBER,
   p_ecesta    OUT BOOLEAN,
   p_preco     OUT NUMBER,
   p_mensagem  OUT VARCHAR2,
   p_utilizavendaporembalagem in varchar2 default 'N',
   p_utilizaprecoporembalagem in varchar2 default 'N',
   p_tipoprecificacao         in varchar2 default 'A',
   p_codfilial                in varchar2 default '1',
   p_qt                       in number   default 1,
   p_comimposto               in varchar2 default 'S',

   p_codfilialnf              in varchar2 default '',
   p_codcli                   in number default 0,
   p_codplpag                 in number default 0,
   p_condvenda                in number default 1,
   p_codcliprinc              IN NUMBER DEFAULT 0  );


  FUNCTION calcularst --19 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularst --24 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularst -- 26 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_contribuinte           IN VARCHAR2,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularstfonte --26 parametros
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN NUMBER,
   p_aliqicms1fonte            IN NUMBER,
   p_aliqicms2fonte            IN NUMBER,
   p_percbasered               IN NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER;

  FUNCTION buscapercomissao --18 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER;

  FUNCTION buscapercomissao --21 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_codsec                  IN pcprodut.codsec%TYPE,
   p_codepto                 IN pcprodut.codepto%TYPE,
   p_codprod                 IN pcprodut.codprod%TYPE,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER;

  FUNCTION buscapercomissao --22 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_codsec                  IN pcprodut.codsec%TYPE,
   p_codepto                 IN pcprodut.codepto%TYPE,
   p_codprod                 IN pcprodut.codprod%TYPE,
   p_perluc                  IN NUMBER,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER;

  PROCEDURE calcularcmv --30 parametros
  (p_abaterimpostoscomissaorca IN VARCHAR2,
   p_aplicarindicecmv          IN VARCHAR2,
   p_txvenda                   IN NUMBER,
   p_tipofj                    IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_freteespecial             IN VARCHAR2,
   p_perfreteterceiros         IN NUMBER,
   p_perfreteespecial          IN NUMBER,
   p_custofin                  IN NUMBER,
   p_custoreal                 IN NUMBER,
   p_perdesccusto              IN NUMBER,
   p_codicmtab                 IN NUMBER,
   p_codicmtabpf_enulo         IN BOOLEAN,
   p_codicmtabpf               IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_pvenda                    IN NUMBER,
   p_percom                    IN NUMBER,
   p_st                        IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_vliss                     IN NUMBER,
   p_contribuinte              IN VARCHAR2,
   p_perfretecmv               OUT NUMBER,
   p_custofinest               OUT NUMBER,
   p_txvenda_item              OUT NUMBER,
   p_perdesccusto_item         OUT NUMBER,
   p_codicmtab_item            OUT NUMBER,
   p_vlcustoreal               OUT NUMBER,
   p_vlcustofin                OUT NUMBER,
   p_vldesccustocmv            OUT NUMBER,
   p_aplicaredTribut           IN BOOLEAN DEFAULT FALSE,
   p_bonific                   IN BOOLEAN DEFAULT FALSE,
   p_codst                     IN NUMBER DEFAULT 0);

  FUNCTION buscapercomissao --23 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_codsec                  IN pcprodut.codsec%TYPE,
   p_codepto                 IN pcprodut.codepto%TYPE,
   p_codprod                 IN pcprodut.codprod%TYPE,
   p_perluc                  IN NUMBER,
   p_letracomiss             OUT VARCHAR2,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER;

  FUNCTION buscapercomissao --24 parametros
  (p_tipovend                  IN VARCHAR2,
   p_pcomint1                  IN NUMBER,
   p_pcomext1                  IN NUMBER,
   p_pcomrep1                  IN NUMBER,
   p_usacomissaoporcliente     IN VARCHAR2,
   p_percomcli                 IN NUMBER,
   p_usacomissaoporrca         IN VARCHAR2,
   p_comissaorcatipovenda      IN VARCHAR2,
   p_tipovenda                 IN VARCHAR2,
   p_percent                   IN NUMBER,
   p_percent2                  IN NUMBER,
   p_usacomissaoporlinhaprod   IN VARCHAR2,
   p_codplpag                  IN NUMBER,
   p_codlinhaprod              IN NUMBER,
   p_perdesc                   IN NUMBER,
   p_codusur                   IN NUMBER,
   p_numregiao                 IN NUMBER,
   p_codsec                    IN pcprodut.codsec%TYPE,
   p_codepto                   IN pcprodut.codepto%TYPE,
   p_codprod                   IN pcprodut.codprod%TYPE,
   p_perluc                    IN NUMBER,
   p_ordemavaliacaocomissaorca IN NUMBER,
   p_letracomiss               OUT VARCHAR2,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER;

  FUNCTION buscardadosprodutos -- 115 parametros
  (pnnumped                    IN pcpedc.numped%TYPE,
   pscodfilial                 IN pcpedc.codfilial%TYPE,
   pscodfilialnf               IN pcpedc.codfilialnf%TYPE, ----observacao pode ser filial do PCTABPRCLI
   psorigemped                 IN pcpedc.origemped%TYPE,
   psfretedespacho             IN pcpedc.fretedespacho%TYPE,
   pncondvenda                 IN pcpedc.condvenda%TYPE,
   pnpercvenda                 IN pcpedc.percvenda%TYPE,
   pncodplpag                  IN pcpedc.codplpag%TYPE,
   pncodcli                    IN pcpedc.codcli%TYPE,
   pncodusur                   IN pcpedc.codusur%TYPE,
   pddata                      IN pcpedc.data%TYPE,
   pncodsupervisor             IN pcusuari.codsupervisor%TYPE,
   pstipovend                  IN pcusuari.tipovend%TYPE,
   pnpercent                   IN pcusuari.percent%TYPE,
   pnpercent2                  IN pcusuari.percent2%TYPE,
   psfilialuf                  IN pcfilial.uf%TYPE,
   psfilialnfuf                IN pcfilial.uf%TYPE,
   pncodfunc                   IN pcempr.matricula%TYPE,
   pnperfreteterceiros         IN pcregiao.perfreteterceiros%TYPE,
   pnperfreteespecial          IN pcregiao.perfreteespecial%TYPE,
   psestent                    IN pcclient.estent%TYPE,
   psieent                     IN pcclient.ieent%TYPE,
   pstipofj                    IN pcclient.tipofj%TYPE,
   pscontribuinte              IN pcclient.contribuinte%TYPE,
   psclassevenda               IN pcclient.classevenda%TYPE,
   pncodcliprinc               IN pcclient.codcliprinc%TYPE,
   pncodpraca                  IN pcclient.codpraca%TYPE,
   pstipocustotransf           IN pcclient.tipocustotransf%TYPE,
   psisentoipi                 IN pcclient.isentoipi%TYPE,
   pssulframa                  IN pcclient.sulframa%TYPE,
   pscalculast                 IN pcclient.calculast%TYPE,
   pnperdesccli                IN pcclient.perdesc%TYPE,
   pnpercomcli                 IN pcclient.percomcli%TYPE,
   psutilizaiesimplificada     IN pcclient.utilizaiesimplificada%TYPE,
   psclientefontest            IN pcclient.clientefontest%TYPE,
   psisentoicms                IN pcclient.isentoicms%TYPE,
   psconsumidorfinal           IN pcclient.consumidorfinal%TYPE,
   pstipoempresa               IN pcclient.tipoempresa%TYPE,
   pnperdescativ               IN pcativi.percdesc%TYPE,
   pncodprod                   IN pcprodut.codprod%TYPE,
   pncodauxiliar               IN pcprodut.codauxiliar%TYPE,
   pnnumregiao                 IN pcregiao.numregiao%TYPE, --observacao pode ser regiao do PCTABPRCLI ou do broker
   pnperfrete                  IN pcregiao.perfrete%TYPE, --observacao pode ser frete da regiao do PCTABPRCLI ou do broker
   psutilizavendaporembalagem  IN pcconsum.utilizavendaporembalagem%TYPE,
   psprecoporembalagem         IN pcconsum.precoporembalagem%TYPE,
   psusatributacaoporuf        IN pcconsum.usatributacaoporuf%TYPE,
   psabatefretevendabalcao     IN pcconsum.abatefretevendabalcao%TYPE,
   pnnumcasasdecvenda          IN pcconsum.numcasasdecvenda%TYPE,
   psusartributacaotransftv10  IN pcconsum.usartributacaotransftv10%TYPE,
   pnpercacrescimobalcao       IN pcconsum.percacrescimobalcao%TYPE,
   psaplicaacrescpftv3         IN pcconsum.aplicaacrescpftv3%TYPE,
   psacrescimopfcomie          IN pcconsum.acrescimopfcomie%TYPE,
   psusadescporlinhaprod       IN pcconsum.usadescporlinhaprod%TYPE,
   pstratarrestricaoacrescimo  IN pcconsum.tratarrestricaoacrescimo%TYPE,
   psvalidapvendabonific       IN pcconsum.validapvendabonific%TYPE,
   psutilizapercfinprecoprom   IN pcconsum.utilizapercfinprecoprom%TYPE,
   pscalcularstcomipi          IN pcconsum.calcularstcomipi%TYPE,
   psmostrarpvendasemst        IN pcconsum.mostrarpvendasemst%TYPE,
   pstipocalcst                IN pcconsum.tipocalcst%TYPE,
   pscalcstpf                  IN pcconsum.calcstpf%TYPE,
   psconsideraisentoscomopf    IN pcconsum.consideraisentoscomopf%TYPE,
   pnpermaxvenda               IN pcconsum.permaxvenda%TYPE,
   pstipocalcsulframa          IN pcconsum.tipocalcsulframa%TYPE,
   psusacomissaoporcliente     IN pcconsum.usacomissaoporcliente%TYPE,
   psusacomissaoporrca         IN pcconsum.usacomissaoporrca%TYPE,
   pscomissaorcatipovenda      IN pcconsum.comissaorcatipovenda%TYPE,
   psusacomissaoporlinhaprod   IN pcconsum.usacomissaoporlinhaprod%TYPE,
   psabaterimpostoscomissaorca IN pcconsum.abaterimpostoscomissaorca%TYPE,
   psaplicarindicecmv          IN pcconsum.aplicarindicecmv%TYPE,
   pntxvenda                   IN pcconsum.txvenda%TYPE,
   psutilizapercbaseredpf      IN pcconsum.utilizapercbaseredpf%TYPE,
   pnordemavaliacaocomissaorca IN pcconsum.ordemavaliacaocomissaorca%TYPE,
   pstipocalcipi               IN pcconsum.tipocalcipi%TYPE,
   pbusapoliticadescontos      IN BOOLEAN,
   pbusaprecofixo              IN BOOLEAN,
   pnnumpr                     IN pcplpag.numpr%TYPE,
   pnpertxfim                  IN pcplpag.pertxfim%TYPE,
   pnnumdias                   IN pcplpag.numdias%TYPE,
   pstipovenda                 IN pcplpag.tipovenda%TYPE,
   pnpvenda                    IN OUT pcpedi.pvenda%TYPE,
   pnqtvendida                 IN pcpedi.qt%TYPE,
   psnumlote                   IN VARCHAR2,
   pnptabela                   OUT pcpedi.ptabela%TYPE,
   pnpbaserca                  OUT pcpedi.pbaserca%TYPE,
   pnpvendabase                OUT pcpedi.pvendabase%TYPE,
   pnporiginal                 OUT pcpedi.poriginal%TYPE,
   pncodst                     OUT pcpedi.codst%TYPE,
   pnst                        OUT pcpedi.st%TYPE,
   pnbaseicst                  OUT pcpedi.baseicst%TYPE,
   pniva                       OUT pcpedi.iva%TYPE,
   pnpauta                     OUT pcpedi.pauta%TYPE,
   pnaliqicms1                 OUT pcpedi.aliqicms1%TYPE,
   pnaliqicms2                 OUT pcpedi.aliqicms1%TYPE,
   pnvlipi                     OUT pcpedi.vlipi%TYPE,
   pnvliss                     OUT pcpedi.vliss%TYPE,
   pnpercom                    OUT pcpedi.percom%TYPE,
   pnperfretecmv               OUT pcpedi.perfretecmv%TYPE,
   pncustofinest               OUT pcpedi.custofinest%TYPE,
   pntxvenda_item              OUT pcpedi.txvenda%TYPE,
   pnperdesccusto_item         OUT pcpedi.perdesccusto%TYPE,
   pncodicmtab_item            OUT pcpedi.codicmtab%TYPE,
   pnvlcustoreal               OUT pcpedi.vlcustoreal%TYPE,
   pnvlcustofin                OUT pcpedi.vlcustofin%TYPE,
   pnvldesccustocmv            OUT pcpedi.vldesccustocmv%TYPE,
   pnstclientegnre             OUT pcpedi.stclientegnre%TYPE,
   pnpercbaseredst             OUT pcpedi.percbaseredst%TYPE,
   pnpercbaseredstfonte        OUT pcpedi.percbaseredstfonte%TYPE,
   pnpercipi                   OUT pcpedi.percipi%TYPE,
   pnvldescsuframa             OUT pcpedi.vldescsuframa%TYPE,
   pnperciss                   OUT pcpedi.perciss%TYPE,
   pnperdesc                   OUT pcpedi.perdesc%TYPE,
   pnletracomiss               OUT pcpedi.letracomiss%TYPE,
   pnpvendamin                 OUT NUMBER,
   pnpvendamax                 OUT NUMBER,
   psmensagem                  OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarrestricaovenda -- 9 parametros
  (p_codprod       IN NUMBER,
   p_numregiao     IN NUMBER,
   p_codcli        IN NUMBER,
   p_codusur       IN NUMBER,
   p_codfornec     IN NUMBER,
   p_codpraca      IN NUMBER,
   p_classeproduto IN pcprodut.classe%TYPE,
   p_codativ       IN pcclient.codatv1%TYPE,
   p_mensagem      OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarrestricaovenda -- 19 parametros (pode ser usada para chamada com 10 parâmetros)
  (p_codprod       IN NUMBER,
   p_numregiao     IN NUMBER,
   p_codcli        IN NUMBER,
   p_codusur       IN NUMBER,
   p_codfornec     IN NUMBER,
   p_codpraca      IN NUMBER,
   p_classeproduto IN pcprodut.classe%TYPE,
   p_codativ       IN pcclient.codatv1%TYPE,
   p_codsupervisor in number,
   p_mensagem      OUT VARCHAR2,
   p_codfilial     in  varchar2 default '0',
   p_condvenda     in  number  default 0,
   p_fretedespacho in  varchar2 default ' ',
   p_origemped     in  varchar2 default ' ',
   p_codauxiliar   in  number default null,
   p_codplpag      in  number default 0,
   p_codcob        in  varchar2 default ' ',
   p_codmarca      in  number default 0,
   p_vlatend       in  number default 0) RETURN BOOLEAN;

  FUNCTION validarrestricaodeptosecforn -- 5 parametros
  (p_codsec    IN NUMBER,
   p_codepto   IN NUMBER,
   p_codusur   IN NUMBER,
   p_codfornec IN NUMBER,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION calcularimpostos --35 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularstfonte --31 parametros
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN NUMBER,
   p_aliqicms1fonte            IN NUMBER,
   p_aliqicms2fonte            IN NUMBER,
   p_percbasered               IN NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_uffilial                  IN VARCHAR2,
   p_estent                    IN VARCHAR2,
   p_usavalorultentbasest      IN VARCHAR2,
   p_valorultent               IN NUMBER,
   p_baseicst                  OUT NUMBER,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER;

  -- Sabrina em 27/01/2008
  FUNCTION calcularstfonte --33 parametros
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN OUT NUMBER,
   p_aliqicms1fonte            IN OUT NUMBER,
   p_aliqicms2fonte            IN OUT NUMBER,
   p_percbaseredstfonte        IN OUT NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_uffilial                  IN VARCHAR2,
   p_estent                    IN VARCHAR2,
   p_usavalorultentbasest      IN VARCHAR2,
   p_valorultent               IN NUMBER,
   p_usaivafontediferenciado   IN VARCHAR2,
   p_ivafonte_cli              IN NUMBER,
   p_baseicst                  IN OUT NUMBER,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER;

  FUNCTION validardescontoquantidade --12 parametros
  (p_tipoteste        IN NUMBER,
   p_codprod          IN NUMBER,
   p_qtde             IN NUMBER,
   p_numregiao        IN NUMBER,
   p_ptabela          IN NUMBER,
   p_pvenda1          IN NUMBER,
   p_codpraca         IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_numdias          IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_ptabeladesc      OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularimpostos --36 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularimpostos --37 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  -- Sabrina 27/01/2008
  FUNCTION calculartodosimpostos -- 27 parametros
  (p_codfilial   IN pcpedc.codfilial%TYPE,
   p_codfilialnf IN pcpedc.codfilialnf%TYPE,
   p_codcli      IN pcpedc.codcli%TYPE,
   p_condvenda   IN pcpedc.condvenda%TYPE,
   p_percvenda   IN pcpedc.percvenda%TYPE,
   p_codprod     IN pcpedi.codprod%TYPE,
   p_codst       IN pcpedi.codst%TYPE,
   -- Precos
   p_pvenda   IN OUT pcpedi.pvenda%TYPE,
   p_ptabela  IN OUT pcpedi.ptabela%TYPE,
   p_pbaserca IN OUT pcpedi.pbaserca%TYPE,
   -- ST/ST Fonte
   p_baseicst           IN OUT pcpedi.baseicst%TYPE,
   p_st                 IN OUT pcpedi.st%TYPE,
   p_iva                IN OUT pcpedi.iva%TYPE,
   p_pauta              IN OUT pcpedi.pauta%TYPE,
   p_aliqicms1          IN OUT pcpedi.aliqicms1%TYPE,
   p_aliqicms2          IN OUT pcpedi.aliqicms2%TYPE,
   p_percbaseredst      IN OUT pcpedi.percbaseredst%TYPE,
   p_percbaseredstfonte IN OUT pcpedi.percbaseredstfonte%TYPE,
   -- IPI
   p_vlipi   IN OUT pcpedi.vlipi%TYPE,
   p_percipi IN OUT pcpedi.percipi%TYPE,
   -- ST Cliente GNRE
   p_stclientegnre IN OUT pcpedi.stclientegnre%TYPE,
   -- Suframa
   p_vldescsuframa IN OUT pcpedi.vldescsuframa%TYPE,
   -- Isencao de ICMS
   p_perdescisentoicms IN OUT pcpedi.perdescisentoicms%TYPE,
   p_vldescicmisencao  IN OUT pcpedi.vldescicmisencao%TYPE,
   -- ISS
   p_perciss  IN OUT pcpedi.perciss%TYPE,
   p_vliss    IN OUT pcpedi.vliss%TYPE,
   p_mensagem OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticaprecofixo --20 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_numlote                 IN VARCHAR2,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularpercverbacmv -- 8 parametros
  (p_codprod          IN NUMBER,
   p_codsec           IN NUMBER,
   p_codepto          IN NUMBER,
   p_data             IN DATE,
   p_codcli           IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_mensagem         OUT VARCHAR2,
   p_percverba        OUT NUMBER,
   p_codrede          IN NUMBER DEFAULT 0
   ) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto --19 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER) RETURN BOOLEAN;

  FUNCTION validardescontoquantidade --15 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_dtfim               OUT DATE,
   p_mensagem            OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER) RETURN BOOLEAN;

  PROCEDURE calcularcmv -- 31 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE,
   p_codst                       IN NUMBER DEFAULT 0);

   FUNCTION validarautorizacaovenda -- 16 parametros
  (p_numped                   IN pcpedc.numped%TYPE,
   p_codcli                   IN pcpedc.codcli%TYPE,
   p_codusur                  IN pcpedc.codusur%TYPE,
   p_codplpag                 IN pcpedc.codplpag%TYPE,
   p_codfunc                  IN pcpedc.codemitente%TYPE,
   p_codprod                  IN pcpedi.codprod%TYPE,
   p_ptabelaant               IN pcpedi.ptabela%TYPE,
   p_ptabela                  IN pcpedi.ptabela%TYPE,
   p_pvenda                   IN pcpedi.pvenda%TYPE,
   p_codauxiliar              IN pcpedi.codauxiliar%TYPE,
   p_permaxdesc               IN NUMBER,
   p_numcasasdecvenda         IN pcconsum.numcasasdecvenda%TYPE,
   p_utilizavendaporembalagem IN pcconsum.utilizavendaporembalagem%TYPE,
   p_pbaserca                 IN OUT pcpedi.pbaserca%TYPE,
   p_pvendamin                IN OUT pcpedi.pvenda%TYPE,
   p_mensagem                 OUT VARCHAR2) RETURN BOOLEAN;


  FUNCTION validarautorizacaovenda -- 17 parametros
  (p_numped                   IN pcpedc.numped%TYPE,
   p_codcli                   IN pcpedc.codcli%TYPE,
   p_codusur                  IN pcpedc.codusur%TYPE,
   p_codplpag                 IN pcpedc.codplpag%TYPE,
   p_codfunc                  IN pcpedc.codemitente%TYPE,
   p_codprod                  IN pcpedi.codprod%TYPE,
   p_ptabelaant               IN pcpedi.ptabela%TYPE,
   p_ptabela                  IN pcpedi.ptabela%TYPE,
   p_pvenda                   IN pcpedi.pvenda%TYPE,
   p_codauxiliar              IN pcpedi.codauxiliar%TYPE,
   p_permaxdesc               IN NUMBER,
   p_numcasasdecvenda         IN pcconsum.numcasasdecvenda%TYPE,
   p_utilizavendaporembalagem IN pcconsum.utilizavendaporembalagem%TYPE,
   p_pbaserca                 IN OUT pcpedi.pbaserca%TYPE,
   p_pvendamin                IN OUT pcpedi.pvenda%TYPE,
   p_percomAutorizacao        IN OUT pcautori.percom%TYPE,   
   p_mensagem                 OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto( -- 15 parametros
                                    p_codprod          IN NUMBER,
                                    p_data             IN DATE,
                                    p_codfilial        IN VARCHAR2,
                                    p_numregiao        IN NUMBER,
                                    p_codcli           IN NUMBER,
                                    p_codusur          IN NUMBER,
                                    p_origempedido     IN VARCHAR2,
                                    p_codprodprinc     IN NUMBER,
                                    p_numcasasdecvenda IN NUMBER,
                                    p_codplpag         IN NUMBER,
                                    p_tipo             in varchar2,
                                    p_dtfim            OUT DATE,
                                    p_mensagem         OUT VARCHAR2,
                                    p_perdesc          OUT NUMBER,
                                    p_basecreddebrca   OUT VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION buscapercomissao -- 26 parametros
  (p_tipovend                  IN VARCHAR2,
   p_pcomint1                  IN NUMBER,
   p_pcomext1                  IN NUMBER,
   p_pcomrep1                  IN NUMBER,
   p_usacomissaoporcliente     IN VARCHAR2,
   p_percomcli                 IN NUMBER,
   p_usacomissaoporrca         IN VARCHAR2,
   p_comissaorcatipovenda      IN VARCHAR2,
   p_tipovenda                 IN VARCHAR2,
   p_percent                   IN NUMBER,
   p_percent2                  IN NUMBER,
   p_usacomissaoporlinhaprod   IN VARCHAR2,
   p_codplpag                  IN NUMBER,
   p_codlinhaprod              IN NUMBER,
   p_perdesc                   IN NUMBER,
   p_codusur                   IN NUMBER,
   p_numregiao                 IN NUMBER,
   p_codsec                    IN pcprodut.codsec%TYPE,
   p_codepto                   IN pcprodut.codepto%TYPE,
   p_codprod                   IN pcprodut.codprod%TYPE,
   p_perluc                    IN NUMBER,
   p_ordemavaliacaocomissaorca IN NUMBER,
   p_codfilial                 IN VARCHAR2,
   p_data                      in date,
   p_letracomiss               OUT VARCHAR2,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER;

  PROCEDURE Definir_Comissao_por_PCProdut(p_tipovend               in pcusuari.tipovend%type,
                                          p_pcomint1               in pcprodut.pcomint1%type,
                                          P_PCOMEXT1               in pcprodut.pcomext1%type,
                                          P_PCOMREP1               in pcprodut.pcomrep1%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number);

  procedure Definir_Comissao_por_PCClient(p_usacomissaoporcliente  in pcconsum.usacomissaoporcliente%type,
                                          p_percomcli              in pcclient.percomcli%type,
                                          p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                          p_PerCom                 out number);

  procedure Definir_Comissao_por_PCUsuari(P_USACOMISSAOPORRCA      IN pcconsum.usacomissaoporrca%type,
                                          P_TIPOVENDA              IN pcplpag.tipovenda%type,
                                          P_PERCENT                IN pcusuari.percent%type,
                                          P_PERCENT2               IN pcusuari.percent2%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_comissaorcatipovenda   in pcconsum.comissaorcatipovenda%type,
                                          p_percom                 out number);

  procedure Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD in pcconsum.usacomissaoporlinhaprod%type,
                                          p_ConsiderarComissaoZero  in pcfilial.considerarcomissaozero%type,
                                          p_codplpag                in pcplpag.codplpag%type,
                                          p_codlinhaprod            in pcprodut.codlinhaprod%type,
                                          p_percom                  out number);

  procedure Definir_Comissao_por_LUCRO(--7 Parâmetros
                                       p_perluc                 in number,
                                       p_perdesc                in number,
                                       p_tipovend               pcusuari.tipovend%type,
                                       p_tipocomissao           pcprodut.tipocomissao%type,
                                       p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                       p_percom                 out number,
                                       p_letracomiss            out pcpedi.letracomiss%type);

  procedure Definir_Comissao_por_LUCRO(--8 Parâmetros
                                       p_perluc                 in number,
                                       p_perdesc                in number,
                                       p_tipovend               pcusuari.tipovend%type,
                                       p_tipocomissao           pcprodut.tipocomissao%type,
                                       p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                       p_percom                 out number,
                                       p_letracomiss            out pcpedi.letracomiss%type,
                                       p_codfaixa               out number);

  procedure Definir_Comis_PCCOMISSAOUSUR(p_perdesc                in number,
                                         p_codusur                in number,
                                         p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                         p_codepto                in pcprodut.codepto%type,
                                         p_codsec                 in pcprodut.codsec%type,
                                         p_codprod                in pcprodut.codprod%type,
                                         p_percom                 out number,
                                         p_letracomiss            out varchar2);


  procedure ValidarPCComissaoRegiao(p_numregiao              in pcregiao.numregiao%type,
                                    p_codfilial              in pcfilial.codigo%type,
                                    p_perdesc                in number,
                                    p_data                   in date,
                                    p_codprod                in pcprodut.codprod%type,
                                    p_codsec                 in pcprodut.codsec%type,
                                    p_codepto                in pcprodut.codepto%type,
                                    p_tipovend               in pcusuari.tipovend%type,
                                    p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                    p_percom                 out number,
                                    p_letracomiss            out varchar2);

  procedure ValidarPCCOMISSAOPLPAG(--12 Parâmetros
                                   p_tipovend               in pcusuari.tipovend%type,
                                   p_codplpag               in pcplpag.codplpag%type,
                                   p_perdesc                in number,
                                   p_codprod                in pcprodut.codprod%type,
                                   p_codepto                in pcprodut.codepto%type,
                                   p_codsec                 in pcprodut.codsec%type,
                                   p_classeproduto          in pcprodut.classe%type,
                                   p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                   p_percom                 out number,
                                   p_letracomiss            out varchar2,
                                   p_codcomiss              out number,
                                   p_mensagem               out varchar2);

  procedure ValidarPCCOMISSAOPLPAG(--10 Parâmetros
                                   p_tipovend               in pcusuari.tipovend%type,
                                   p_codplpag               in pcplpag.codplpag%type,
                                   p_perdesc                in number,
                                   p_codprod                in pcprodut.codprod%type,
                                   p_codepto                in pcprodut.codepto%type,
                                   p_codsec                 in pcprodut.codsec%type,
                                   p_classeproduto          in pcprodut.classe%type,
                                   p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                   p_percom                 out number,
                                   p_letracomiss            out varchar2);

  FUNCTION Definir_Comissao_Item_Vendido(--34 Parâmetros
                                         p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2)
    RETURN NUMBER;

  FUNCTION validarpoliticaprecofixo --21 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_numlote                 IN VARCHAR2,
   p_origemped               IN VARCHAR2,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularimpostos --38 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_importado              in pcprodut.importado%type,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularimpostos --46 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_importado              in pcprodut.importado%type,
   P_CALCULARIPIVENDA       IN PCFILIAL.CALCULARIPIVENDA%TYPE,
   P_PERCIPIVENDATAB        IN PCPRODUT.PERCIPIVENDATAB%TYPE,
   P_VLPAUTAIPIVENDA        IN PCPRODUT.VLPAUTAIPIVENDA%type,
   P_VLPAUTAIPIVENDATAB     IN PCPRODUT.VLPAUTAIPIVENDATAB%TYPE,
   P_VLIPIPORKGVENDA        IN PCPRODUT.VLIPIPORKGVENDA%TYPE,
   P_VLIPIPORKGVENDATAB     IN PCPRODUT.VLIPIPORKGVENDATAB%TYPE,
   P_PESOBRUTO              IN PCPRODUT.PESOBRUTO%type,
   P_TIPOCALCULOGNRE        IN PCTRIBUT.Tipocalculognre%type,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN;

  FUNCTION calcularstfonte --45 parametros ( mas pode ser usada pode packages que utilizam a de 38 parÂmetros)
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN OUT NUMBER,
   p_aliqicms1fonte            IN OUT NUMBER,
   p_aliqicms2fonte            IN OUT NUMBER,
   p_percbaseredstfonte        IN OUT NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_uffilial                  IN VARCHAR2,
   p_estent                    IN VARCHAR2,
   p_usavalorultentbasest      IN VARCHAR2,
   p_valorultent               IN NUMBER,
   p_usaivafontediferenciado   IN VARCHAR2,
   p_ivafonte_cli              IN NUMBER,
   p_AceitaPFContribuinte      IN VARCHAR,
   p_ALIQICMS1                 IN NUMBER,
   p_ALIQICMS2                 IN NUMBER,
   p_contribuinte              IN VARCHAR2,
   p_numcasasdecvenda          in NUMBER,
   p_baseicst                  IN OUT NUMBER,
   p_mensagem                  OUT VARCHAR2,
   P_CUSTONFSEMST              in pcest.custonfsemst%type default 0,
   p_usavalorultentbasest2     in pctribut.usavalorultentbasest2%type default 'N',
   p_usapmcbasest              in pctribut.usapmcbasest%type default 'N' ,
   p_precomaxconsum            in pcprodut.precomaxconsum%type default 0,
   p_importado                 in pcprodut.importado%type default 'N',
   p_percbasestrj              in pctribut.percbasestrj%type default 0,
   p_AGREGARIPICALCULOST       in pctribut.agregaripicalculost%type default 'N'  ) RETURN NUMBER ;


  FUNCTION buscapercomissao -- 27 parametros
  (p_tipovend                  IN VARCHAR2,
   p_pcomint1                  IN NUMBER,
   p_pcomext1                  IN NUMBER,
   p_pcomrep1                  IN NUMBER,
   p_usacomissaoporcliente     IN VARCHAR2,
   p_percomcli                 IN NUMBER,
   p_usacomissaoporrca         IN VARCHAR2,
   p_comissaorcatipovenda      IN VARCHAR2,
   p_tipovenda                 IN VARCHAR2,
   p_percent                   IN NUMBER,
   p_percent2                  IN NUMBER,
   p_usacomissaoporlinhaprod   IN VARCHAR2,
   p_codplpag                  IN NUMBER,
   p_codlinhaprod              IN NUMBER,
   p_perdesc                   IN NUMBER,
   p_codusur                   IN NUMBER,
   p_numregiao                 IN NUMBER,
   p_codsec                    IN pcprodut.codsec%TYPE,
   p_codepto                   IN pcprodut.codepto%TYPE,
   p_codprod                   IN pcprodut.codprod%TYPE,
   p_perluc                    IN NUMBER,
   p_ordemavaliacaocomissaorca IN NUMBER,
   p_codfilial                 IN VARCHAR2,
   p_data                      in date,
   p_classeproduto             in pcprodut.classe%type,
   p_letracomiss               OUT VARCHAR2,
   p_mensagem                  OUT VARCHAR2) return number;

  FUNCTION verificarcotarca -- 5 parametros
  (p_codprod   IN NUMBER,
   p_codusur   IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_mensagem  OUT VARCHAR2

   ) RETURN BOOLEAN;

  FUNCTION verificarcotacliente -- 5 parametros
  (p_codprod   IN NUMBER,
   p_codcli    IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN;

  -- 6 parâmetros
  procedure Definir_Comissao_por_PCClient(p_usacomissaoporcliente  in pcconsum.usacomissaoporcliente%type,
                                          p_percomcli              in pcclient.percomcli%type,
                                          p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                          p_codcli                 in pcclient.codcli%type,
                                          p_codfilial              in pcfilial.codigo%type,
                                          p_PerCom                 out number);

  -- 8 parâmetros
  PROCEDURE Definir_Comissao_por_PCProdut(p_tipovend               in pcusuari.tipovend%type,
                                          p_pcomint1               in pcprodut.pcomint1%type,
                                          P_PCOMEXT1               in pcprodut.pcomext1%type,
                                          P_PCOMREP1               in pcprodut.pcomrep1%type,
                                          p_codprod                in pcprodut.codprod%type,
                                          p_codfilial              in pcfilial.codigo%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number);

  -- 3 parâmetros
  procedure Definir_Comissao_por_Filial(p_codfilial              in pcfilial.codigo%type,
                                        p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                        p_percom                 out number);

  FUNCTION Definir_Comissao_Item_Vendido(--36 parâmetros
                                         p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_UsaPCComissaoFilial       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_codcli                    in pcclient.codcli%type,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2)
    RETURN NUMBER;

  function verificabloqueio(p_numped            in pcpedc.numped%type,
                            p_codcli            in pcclient.codcli%type,
                            p_codpraca          in pcclient.codpraca%type,
                            p_condvenda         in pcpedc.condvenda%type,
                            p_Codplpag          in pcpedc.codplpag%type,
                            p_Codcob            in pcpedc.codcob%type,
                            p_clientemonitorado in pcclient.clientemonitorado%type,
                            p_Codmotivo         out pcbloqueio.codmotivo%type,
                            p_Codmotbloqueio    out pcbloqueio.codmotbloqueio%type,
                            p_log               out pcpedc.log%type)
    return boolean;

  FUNCTION validarpoliticasdesconto -- 21 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2) RETURN BOOLEAN;

  FUNCTION validardescontoquantidade -- 17 parametros
  (p_tipoteste            IN NUMBER,
   p_codprod              IN NUMBER,
   p_qtde                 IN NUMBER,
   p_numregiao            IN NUMBER,
   p_ptabela              IN NUMBER,
   p_pvenda1              IN NUMBER,
   p_codpraca             IN NUMBER,
   p_numcasasdecvenda     IN NUMBER,
   p_numdias              IN NUMBER,
   p_tipodesconto         IN VARCHAR2,
   p_dtfim                OUT DATE,
   p_mensagem             OUT VARCHAR2,
   p_ptabeladesc          OUT NUMBER,
   p_creditasobreptabela  OUT VARCHAR2,
   p_perdescflex          OUT NUMBER,
   p_prioritaria          out varchar2,
   p_questionaprioritaria out varchar2) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto -- 22 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_alteraptabela            out varchar2) RETURN BOOLEAN;

  FUNCTION verificacampanhasdesconto(p_numped        in pcpedc.numped%type,
                                     p_codfilial     in pcpedc.codfilial%type,
                                     p_numregiao     in pcpedc.numregiao%type,
                                     p_codcli        in pcpedc.codcli%type,
                                     p_codativ       in pcclient.codatv1%type,
                                     p_codcliprinc   in pcclient.codcliprinc%type,
                                     p_codusur       in pcpedc.codusur%type,
                                     p_codsupervisor in pcpedc.codsupervisor%type,
                                     p_coddistrib    in pcpedc.coddistrib%type,
                                     p_pertxfim      in pcplpag.pertxfim%type,
                                     p_codcombo      in pcdescontoc.codigo%type,
                                     p_mensagem      out varchar2,
                                     p_codplpag      in pcpedc.codplpag%type default 0)
    return boolean;

  FUNCTION validarpoliticaprecofixo -- 23 parametros ou mais
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_numlote                 IN VARCHAR2,
   p_origemped               IN VARCHAR2,
   p_codativ                 in pcclient.codatv1%type,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER,
   p_codfilial               in pcfilial.codigo%type default '',
   p_validarprecovendatv20   in varchar2  default 'S',
   p_broker                  in varchar2  default 'N',
   p_utilizavendaporfilial   in varchar2 default 'N',
   p_precoporfilial          in varchar2 default 'N',
   p_codauxiliar             in varchar2 default null ) RETURN BOOLEAN;

   FUNCTION validarpoliticaprecofixo -- 29 parametros ou mais
   (p_codprod                  IN NUMBER,
    p_data                     IN DATE,
    p_numregiao                IN NUMBER,
    p_codcli                   IN NUMBER,
    p_condvenda                IN NUMBER,
    p_codplpag                 IN NUMBER,
    p_ptabela                  IN NUMBER,
    p_validapvendabonific      IN VARCHAR2,
    p_utilizapercfinprecoprom  IN VARCHAR2,
    p_pertxfim                 IN NUMBER,
    p_numdias                  IN NUMBER,
    p_codcliprinc              IN NUMBER,
    p_codprodprinc             IN NUMBER,
    p_codpraca                 IN NUMBER,
    p_codusur                  IN NUMBER,
    p_codsupervisor            IN NUMBER,
    p_numlote                  IN VARCHAR2,
    p_origemped                IN VARCHAR2,
    p_codativ                  in pcclient.codatv1%type,
    p_dtfim                    OUT DATE,
    p_mensagem                 OUT VARCHAR2,
    p_precofixo                OUT NUMBER,
    p_codfilial                in pcfilial.codigo%type default '',
    p_validarprecovendatv20    in varchar2  default 'S',
    p_broker                   in varchar2  default 'N',
    p_utilizavendaporfilial    in varchar2 default 'N',
    p_precoporfilial           in varchar2 default 'N',
    p_codauxiliar              in varchar2 default NULL,
    p_consideraprecosemimposto out varchar2) RETURN BOOLEAN;

  function calculo_preco_sem_impostos -- 22 parametros
  (percipivenda           in number,
   vlpautaipivenda        in number,
   vlipiporkgvenda        in number,
   pvenda                 in number,
   pauta                  in number,
   pesobruto              in number,
   percdifaliquotas       in number,
   percipi                in out number,
   valorultent            in number,
   iva                    in number,
   percbaseredst          in out number,
   aliqicms1              in number,
   aliqicms2              in number,
   usavalorultentbasest   in varchar,
   usavalorultentbasest2  in varchar,
   uf_pcfilial            in varchar,
   pcclient_estent        in varchar,
   preco_sem_impostos     out number,
   p_mensagem             out varchar2,
   usapmcbasest           IN VARCHAR2 := 'N',
   precomaxconsumidor     IN number := 0,
   considerarIpiAliqicms2 IN VARCHAR2 default 'N',
   usavlultentmediobasest in varchar2 default 'N',
   vlultentmes            in number default 0,
   p_percbasestrj            in pctribut.percbasestrj%type default 0,
   p_percredaliqipi          IN NUMBER DEFAULT 0) RETURN BOOLEAN;

  PROCEDURE calcularcmv -- 32 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE,
   p_codst                       IN NUMBER DEFAULT 0);

  -- 37 parâmetros
  FUNCTION Definir_Comissao_Item_Vendido(p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_UsaPCComissaoFilial       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_codcli                    in pcclient.codcli%type,
                                         p_coddesconto               in pcdesconto.coddesconto%type,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2)
    RETURN NUMBER;

  FUNCTION validarpoliticasdesconto -- 20 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_pbaserca                 OUT NUMBER) RETURN BOOLEAN;

  FUNCTION validardescontoquantidade -- 16 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_dtfim               OUT DATE,
   p_mensagem            OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER) RETURN BOOLEAN;

  FUNCTION verificarcotarca -- 6 parametros
  (p_codprod   IN NUMBER,
   p_codusur   IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_qtdisp    OUT NUMBER,
   p_mensagem  OUT VARCHAR2

   ) RETURN BOOLEAN;

  FUNCTION verificarcotacliente -- 6 parametros
  (p_codprod   IN NUMBER,
   p_codcli    IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_qtdisp    OUT NUMBER,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN;

  FUNCTION calcularimpostos --69 parametros ( pode ser usada por packages que utilizam a de 50 parÂmetros)
  (p_pvenda                  IN OUT NUMBER,
   p_ptabela                 IN OUT NUMBER,
   p_pbaserca                IN OUT NUMBER,
   p_vlipi                   IN OUT NUMBER,
   p_percipi                 IN OUT NUMBER,
   p_percipivenda            IN NUMBER,
   p_percvenda               IN NUMBER,
   p_tipocalcst              IN VARCHAR2,
   p_calcstpf                IN VARCHAR2,
   p_mostrarpvendasemst      IN VARCHAR2,--10
   p_consideraisentoscomopf  IN VARCHAR2,
   p_calculast               IN VARCHAR2,
   p_ieent                   IN VARCHAR2,
   p_tipofj                  IN VARCHAR2,
   p_pauta                   IN NUMBER,
   p_iva                     IN OUT NUMBER,
   p_aliqicms1               IN NUMBER,
   p_aliqicms2               IN NUMBER,
   p_percbaseredst           IN OUT NUMBER,
   p_numcasasdecvenda        IN NUMBER,--20
   p_tipocalculo             IN NUMBER,
   p_uffilial                IN VARCHAR2,
   p_estent                  IN VARCHAR2,
   p_usavalorultentbasest    IN VARCHAR2,
   p_usavalorultentbasest2   IN VARCHAR2,
   p_valorultent             IN NUMBER,
   p_isentoipi               IN VARCHAR2,
   p_suframa                 IN pcclient.sulframa%type,
   p_calcularstcomipi        IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi             IN pcconsum.tipocalcipi%TYPE,--30
   p_filialnf                IN pcpedc.codfilialnf%TYPE,
   p_condvenda               IN pcpedc.condvenda%TYPE,
   p_contribuinte            IN pcclient.contribuinte%TYPE,
   p_uffilialnf              IN pcfilial.uf%TYPE,
   p_importado               in pcprodut.importado%type,
   P_CALCULARIPIVENDA        IN PCFILIAL.CALCULARIPIVENDA%TYPE,
   P_PERCIPIVENDATAB         IN PCPRODUT.PERCIPIVENDATAB%TYPE,
   P_VLPAUTAIPIVENDA         IN PCPRODUT.VLPAUTAIPIVENDA%type,
   P_VLPAUTAIPIVENDATAB      IN PCPRODUT.VLPAUTAIPIVENDATAB%TYPE,
   P_VLIPIPORKGVENDA         IN PCPRODUT.VLIPIPORKGVENDA%TYPE,--40
   P_VLIPIPORKGVENDATAB      IN PCPRODUT.VLIPIPORKGVENDATAB%TYPE,
   P_PESOBRUTO               IN PCPRODUT.PESOBRUTO%type,
   P_TIPOCALCULOGNRE         IN PCTRIBUT.Tipocalculognre%type,
   p_SIMPLESNACIONAL         IN PCCLIENT.SIMPLESNACIONAL%type,
   p_PERCREDPVENDASIMPLESNAC IN pctribut.PERCREDPVENDASIMPLESNAC%type,
   p_reduziva                IN varchar2, --utilizado pelo fv para fazer um calculo sem redução do iva mesmo que o cliente seja simples nacional
   p_utilizaiesimplificada   IN pcclient.utilizaiesimplificada%type,
   p_mensagem                OUT VARCHAR2,
   p_st                      OUT NUMBER,
   p_baseicst                OUT NUMBER,--50
   p_aceitapfcontribuinte    IN pcconsum.aceitapfcontribuinte%type default 'N',
   p_custonfsemst            IN pcest.custonfsemst%type default 0,
   p_usapmcbasest            IN pctribut.usapmcbasest%type default 'N',
   p_precomaxconsum          IN pcprodut.precomaxconsum%type default 0,
   p_consumidorfinal         IN pcclient.consumidorfinal%type default 'N',
   p_retiraimp               IN VARCHAR2 default 'S',
   p_novoprocesso            IN VARCHAR2 default 'N',
   p_agregaripicalculost in varchar2 default 'N',
   p_utilizacalculostmt      IN pcclient.utilizacalculostmt%type default 'N',
   p_margemmva               IN pccnae.margemmva%type default 0,--60
   p_percargatribmedia       IN pccnae.percargatribmedia%type default 0,
   p_usavlultentmediobasest  in pctribut.usavlultentmediobasest%type default 'N',
   p_vlultentmes             in pctabpr.vlultentmes%type default 0,
   p_percbasestrj            in pctribut.percbasestrj%type default 0,
   p_vlstPrecificacao        in pctabpr.vlst%type default 1 ,
   p_tipoPreco               in varchar2 default 'N',
   p_foiprecificadocomIpi    in varchar2 default 'S',
   p_percredaliqipi          IN NUMBER DEFAULT 0,
   p_calcularSTRamoAtiv      IN VARCHAR DEFAULT 'S'
  ) RETURN BOOLEAN ;



    PROCEDURE calcularcmv -- 46 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,--30
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE,
   p_codst                       IN NUMBER DEFAULT 0, --40
   p_vlicmspartilha              IN NUMBER DEFAULT 0,
   p_codicmstabsn                IN NUMBER DEFAULT 0,
   p_vlrebaixacmv                in NUMBER DEFAULT 0,
   p_codfilial                   in pcfilial.codigo%type DEFAULT '',
   p_codicmtab_diferenciado      in NUMBER DEFAULT 0,
   p_custosemST                  in NUMBER DEFAULT 0
   );

    PROCEDURE calcularcmv -- 50 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlfecp                      IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER, --30
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE, --40
   p_codst                       IN NUMBER DEFAULT 0,
   p_vlicmspartilha              IN NUMBER DEFAULT 0,
   p_codicmstabsn                IN NUMBER DEFAULT 0,
   p_vlrebaixacmv                in NUMBER DEFAULT 0,
   p_codfilial                   in pcfilial.codigo%type DEFAULT '',
   p_codicmtab_diferenciado      in NUMBER DEFAULT 0,
   p_custosemST                  in NUMBER DEFAULT 0,
   p_VLDESCREDUCAOPIS            in NUMBER DEFAULT 0,
   p_DESCREDUCAOCOFINS           in NUMBER DEFAULT 0,
   p_DESCICMISENCAO              in NUMBER DEFAULT 0
   );

    PROCEDURE calcularcmv -- 53 parametros (usando a 50 como base)
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlfecp                      IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER, --30
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE, --40
   p_codst                       IN NUMBER DEFAULT 0,
   p_vlicmspartilha              IN NUMBER DEFAULT 0,
   p_codicmstabsn                IN NUMBER DEFAULT 0,
   p_vlrebaixacmv                in NUMBER DEFAULT 0,
   p_codfilial                   in pcfilial.codigo%type DEFAULT '',
   p_codicmtab_diferenciado      in NUMBER DEFAULT 0,
   p_custosemST                  in NUMBER DEFAULT 0,
   p_VLDESCREDUCAOPIS            in NUMBER DEFAULT 0,
   p_DESCREDUCAOCOFINS           in NUMBER DEFAULT 0,
   p_DESCICMISENCAO              in NUMBER DEFAULT 0,
   p_NUMPED                      in NUMBER,
   p_NUMSEQ                      in NUMBER,
   p_CODPROD                     in NUMBER
   );

FUNCTION calcularredsimplesnac --43 parametros
    (p_custofin                 in pcest.custofin%type,
     p_custonfsemst             in pcest.custonfsemst%type,
     p_custonfsemstguiaultent   in pcest.custonfsemstguiaultent%type,
     p_ivaultent                in pcest.ivaultent%type,
     p_aliqicms1ultent          in pcest.aliqicms1ultent%type,
     p_aliqicms2ultent          in pcest.aliqicms2ultent%type,
     p_redbaseivaultent         in pcest.redbaseivaultent%type,
     p_percicmsfretefobstultent in pcest.percicmsfretefobstultent%type,
     p_vlfreteconhecultent      in pcest.vlfreteconhecultent%type,
     p_percaliqextguiaultent    in pcest.percaliqextguiaultent%type,
     p_vlstultent               in pcest.vlstultent%type,
     p_baseicmsultent           in pcest.baseicmsultent%type,
     p_vlstguiaultent           in pcest.vlstguiaultent%type,
     P_PERCREDPVENDASIMPLESNAC  in number,
     p_numcasasdecvenda         in pcconsum.numcasasdecvenda%type,
     p_param1                   in number,
     p_param2                   in number,
     p_param3                   in number,
     p_param4                   in number,
     p_PVenda                  in number,
     p_PERCIPIVENDA            in number,
     p_vlpautaipivenda         in number,
     p_vlipiporkgvenda         in number,
     p_PAUTA_tribut            in number,
     p_pesobruto               in number,
     p_percdifaliquotas        in number,
     p_valorultent             in number,
     p_iva                     in number,
     p_percbaseredst           in number,
     p_aliqicms1               in number,
     p_aliqicms2               in number,
     p_calcularstcomipi        in pcconsum.calcularstcomipi%TYPE,
     p_tipocalcst              in pcconsum.tipocalcst%TYPE,
     p_tipocalcipi             in pcconsum.tipocalcipi%TYPE,
     p_usavalorultentbasest    in pctribut.usavalorultentbasest%TYPE,
     p_usavalorultentbasest2   in pctribut.usavalorultentbasest2%TYPE,
     p_CALCULARIPIVENDA        in VARCHAR2,
     p_uffilial                in VARCHAR2,
     p_estent                  in VARCHAR2,
     p_CODFILIAL               in VARCHAR2,
     p_mensagem                 out varchar2,
     p_vlreducao                out number,
     p_AlteraFatorAjusteIVASN   IN  pctribut.alterafatorajusteivasn%TYPE DEFAULT 'N'
     ) RETURN BOOLEAN;

  FUNCTION calcularredsimplesnac --21 parametros
  (p_custofin                 in pcest.custofin%type,
   p_custonfsemst             in pcest.custonfsemst%type,
   p_custonfsemstguiaultent   in pcest.custonfsemstguiaultent%type,
   p_ivaultent                in pcest.ivaultent%type,
   p_aliqicms1ultent          in pcest.aliqicms1ultent%type,
   p_aliqicms2ultent          in pcest.aliqicms2ultent%type,
   p_redbaseivaultent         in pcest.redbaseivaultent%type,
   p_percicmsfretefobstultent in pcest.percicmsfretefobstultent%type,
   p_vlfreteconhecultent      in pcest.vlfreteconhecultent%type,
   p_percaliqextguiaultent    in pcest.percaliqextguiaultent%type,
   p_vlstultent               in pcest.vlstultent%type,
   p_baseicmsultent           in pcest.baseicmsultent%type,
   p_vlstguiaultent           in pcest.vlstguiaultent%type,
   P_PERCREDPVENDASIMPLESNAC  in number,
   p_numcasasdecvenda         in pcconsum.numcasasdecvenda%type,
   p_param1                   in number,
   p_param2                   in number,
   p_param3                   in number,
   p_param4                   in number,
   p_mensagem                 out varchar2,
   p_vlreducao                out number) RETURN BOOLEAN;

  --Tem a politica prioritaria e também retorna qual percentual irá utilizar para deb/cred de rca
  FUNCTION validarpoliticasdesconto -- 23 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_alteraptabela            out varchar2,
   p_pbaserca                 out number) RETURN BOOLEAN;

  FUNCTION calcularst --37 parametros ( pode ser usado por package que chamam esta function com 27 parÂmetros)
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_contribuinte           IN VARCHAR2,
   p_utilizaiesimplificada  IN VARCHAR2,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER,
   p_aceitapfcontribuinte   IN pcconsum.aceitapfcontribuinte%type default 'S',
   p_usapmcbasest           IN pctribut.usapmcbasest%type default 'N',
   p_precomaxconsum         IN pcprodut.precomaxconsum%type default 0,
   p_custonfsemst           IN pcest.custonfsemst%type default 0,
   p_consumidorfinal        IN pcclient.consumidorfinal%type default 'N'    ,
   p_consideraripialiqicms2 in varchar2 default 'N',
   p_usavlultentmediobasest in pctribut.usavlultentmediobasest%type default 'N',
   p_vlultentmes            in pctabpr.vlultentmes%type default 0,
   p_percbasestrj           in pctribut.PERCBASESTRJ%type default 0,
   p_calculaStRamoAtiv      IN pcativi.CALCULAST%TYPE DEFAULT 'S'
   ) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto -- 25 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_param1                   IN number,
   p_param2                   IN number) RETURN BOOLEAN;

  FUNCTION validardescontoquantidade -- 21 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_codcli              IN NUMBER default 0,
   p_codusur             IN NUMBER default 0,
   p_dtfim               OUT DATE,
   p_mensagem            OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER,
   p_basedebcredrca      OUT VARCHAR2,
   p_percbaserca         OUT NUMBER,
   p_codfilial           in varchar2 default ' ') RETURN BOOLEAN;

  --possui verificação do simplenacional, retorna percentual de base deb/cred de rca, retorna altera ptabela,politica prioritaria
  FUNCTION validarpoliticasdesconto -- 27 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    in NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_param1                   IN number,
   p_param2                   IN number) RETURN BOOLEAN ;


--Tem retorno do percetual de deb/cred de rca e prioritaria
FUNCTION validardescontoquantidade -- 22 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_codcli              IN NUMBER default 0,
   p_codusur             IN NUMBER default 0,
   p_dtfim               OUT DATE,
   p_mensagem            IN OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER,
   p_basedebcredrca      OUT VARCHAR2,
   p_percbaserca         OUT NUMBER,
   p_prioritaria          out varchar2,
   p_questionaprioritaria out varchar2,
   p_codfilial            in  varchar2 default ' ') RETURN BOOLEAN ;


 FUNCTION validarPCPLPAGRESTRICAO
  (p_codplpag      IN NUMBER,
   p_codprod       IN NUMBER,
   p_codcli        IN NUMBER,
   p_codativ       IN NUMBER,
   p_codfornec     IN NUMBER,
   p_coddepto      IN NUMBER,
   p_origemped     IN varchar2,
   p_codsec        IN NUMBER,
   p_codfilial     IN VARCHAR2,
   p_numregiao     IN NUMBER,
   p_condvenda     IN number,
   p_mensagem      OUT VARCHAR2,
   p_codcategoria     IN number default 0,
   p_codsubcategoria  IN number default 0


 ) RETURN BOOLEAN;

FUNCTION validarpoliticasdesconto_med -- 28 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_perdescfin               OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_usadescfinseparadodesccom IN varchar2,
   p_param2                   IN number) RETURN BOOLEAN ;

  -- 44 parametros, mas serve para a de 39 parâmetros
  FUNCTION Definir_Comissao_Item_Vendido(p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_UsaPCComissaoFilial       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_codcli                    in pcclient.codcli%type,
                                         p_coddesconto               in pcdesconto.coddesconto%type,
                                         p_codcomissao               out number,
                                         p_rotinacomissao            out varchar2,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2,
                                         p_codauxiliar               in pcembalagem.codauxiliar%type default null,
                                         p_pcomint1_emb              in pcembalagem.pcomint1%type default null,
                                         P_PCOMEXT1_emb              in pcembalagem.pcomext1%type default null,
                                         P_PCOMREP1_emb              in pcembalagem.pcomrep1%type default null,
                                         p_utilizavendaporembalagem  in pcconsum.utilizavendaporembalagem%type default 'N',
                                         p_tabela                 in number default 0,
                                         p_venda                  in number default 0,
                                         p_numcasasdecvenda       in number default 2
)
    RETURN NUMBER;

  FUNCTION Definir_Comissao_Item_Vendido(P_NUMTRANSENT     IN NUMBER
                                      ,P_CODPROD         IN NUMBER DEFAULT 0
                                      ,P_NUMSEQ          IN NUMBER DEFAULT 0

                                      ,P_CODCOMISSAO     OUT NUMBER
                                      ,P_ROTINACOMISSAO  OUT VARCHAR2
                                      ,P_LETRACOMISS     OUT VARCHAR2
                                      ,P_MENSAGEM        OUT VARCHAR2)
    RETURN NUMBER;

--possui verificação do simplenacional, retorna percentual de base deb/cred de rca, retorna altera ptabela,politica prioritaria
  FUNCTION validarpoliticasdesconto -- 28 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_numdias                  in NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_param1                   IN number,
   p_param2                   IN number,
   p_codpolbaserca            out number,
   p_tipo                     in varchar2 default null
) RETURN BOOLEAN ;

FUNCTION validardescontoquantidade -- 24 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_codcli              IN NUMBER,
   p_codusur             IN NUMBER,
   p_dtfim               OUT DATE,
   p_mensagem            IN OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER,
   p_basedebcredrca      OUT VARCHAR2,
   p_percbaserca         OUT NUMBER,
   p_prioritaria          out varchar2,
   p_questionaprioritaria out varchar2,
   p_codfilial            in  varchar2 default ' ',
   p_codpolpbaserca       out number,
   p_coddesconto          out number,
   p_apenasvalida         in varchar2 default 'N') RETURN BOOLEAN;

FUNCTION validarpoliticasdesconto_med -- 29 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_numdias                  IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_perdescfin               OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_usadescfinseparadodesccom IN varchar2,
   p_param2                   IN number,
   p_codpolbaserca            out number ) RETURN BOOLEAN;

FUNCTION BUSCARLIMCREDCLI
  (pcodcli   IN PCCLIENT.Codcli%type,
   pcodusur  IN PCUSUARI.Codusur%type,
   ptipolim  IN VARCHAR2,
   p_UsarLimiteExtra IN VARCHAR2 DEFAULT 'S')
  RETURN NUMBER;

FUNCTION func_HoraDigitacaoPedido(P_CODFILIAL IN VARCHAR2,
                                  p_mensagem  OUT VARCHAR2) RETURN BOOLEAN;

 ---------------DADOS CMV------------------
  TYPE T_CALCULOCMV IS RECORD(
    CODICMTAB        NUMBER(18,6),
    CREDPRESUMIDO    NUMBER(18,6),
    ICMSNORMAL       NUMBER(18,6)
    );

  TYPE TB_CALCULOCMV IS TABLE OF T_CALCULOCMV;

  FUNCTION CALCULAR_CMV(pNumped                IN NUMBER,
                        pCodProd               IN NUMBER,
                        pNumseq                IN NUMBER,
                        pAliquotaInterna       IN NUMBER,
                        pPrecoVenda            IN NUMBER,
                        pFORMULACMV            IN VARCHAR2
                   ) RETURN TB_CALCULOCMV
  PIPELINED;
  ------------------------------------------

--10 parametros
procedure Definir_Comis_PCCOMISSAOUSUR(p_perdesc                in number,
                                         p_codusur                in number,
                                         p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                         p_codepto                in pcprodut.codepto%type,
                                         p_codsec                 in pcprodut.codsec%type,
                                         p_codprod                in pcprodut.codprod%type,
                                         p_percom                 out number,
                                         p_letracomiss            out varchar2,
                                         p_codcomiss              out number,
                                         p_mensagem               out varchar2) ;


 --13 parametros
  procedure ValidarPCComissaoRegiao(p_numregiao              in pcregiao.numregiao%type,
                                    p_codfilial              in pcfilial.codigo%type,
                                    p_perdesc                in number,
                                    p_data                   in date,
                                    p_codprod                in pcprodut.codprod%type,
                                    p_codsec                 in pcprodut.codsec%type,
                                    p_codepto                in pcprodut.codepto%type,
                                    p_tipovend               in pcusuari.tipovend%type,
                                    p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                    p_percom                 out number,
                                    p_letracomiss            out varchar2,
                                    p_codcomiss              out number,
                                    p_mensagem               out varchar2) ;


procedure proc_calculastMT (p_pvenda                 in out pcpedi.pvenda%type,
                             p_ptabela               in out pcpedi.ptabela%type,
                             p_pbaserca              in out pcpedi.pbaserca%type,
                             p_percipi                in out pcpedi.percipi%type,
                             p_percbaseredst          in out pctribut.percbaseredst%type,
                             p_mostrarpvendasemst     in pctribut.mostrarpvendasemst%type,
                             p_tipofj                 in pcclient.tipofj%type,
                             p_utilizaiesimplificada  in pcclient.utilizaiesimplificada%type,
                             p_consumidorfinal        in pcclient.consumidorfinal%type,
                             p_ieent                  in pcclient.ieent%type,
                             p_contribuinte           in pcclient.contribuinte%type,
                             p_calculast              in pcclient.calculast%type,
                             p_estent                 in pcclient.estent%type,
                             p_consideraisentoscomopf in pcconsum.consideraisentoscomopf%type,
                             p_tipocalcst             in pcconsum.tipocalcst%type,
                             p_calcstpf               in pcconsum.calcstpf%type,
                             p_numcasasdecvenda       in pcconsum.numcasasdecvenda%type,
                             p_aceitapfcontribuinte   in pcconsum.aceitapfcontribuinte%type,
                             p_vlipi                  in pcpedi.vlipi%type,
                             p_vlipiptabela           in pcpedi.vlipi%type,
                             p_vlipipbaserca          in pcpedi.vlipi%type,
                             p_pauta                  in pctribut.pauta%type,
                             p_iva                    in pctribut.iva%type,
                             p_aliqicms1              in pctribut.aliqicms1%type,
                             p_aliqicms2              in pctribut.aliqicms2%type,
                             p_margemmva              in pccnae.margemmva%type,
                             p_percargatribmedia      in pccnae.percargatribmedia%type,
                             p_uffilial               in pcfilial.uf%type,
                             p_st                     out pcpedi.st%type,
                             p_baseicst               out pcpedi.baseicst%type,
                             p_mensagem               out varchar2

                             ) ;


PROCEDURE Definir_Comissao_por_Embalagem( p_tipovend               in pcusuari.tipovend%type,
                                          p_pcomint1               in pcembalagem.pcomint1%type,
                                          P_PCOMEXT1               in pcembalagem.pcomext1%type,
                                          P_PCOMREP1               in pcembalagem.pcomrep1%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number) ;

procedure Definir_Comissao_PROFISSIONAL(p_codprod                in pcprodut.codprod%type,
                                        p_codcli                 in pcclient.codcli%type,
                                        p_codusur                in pcusuari.codusur%type,
                                        p_tipovenda              in pcplpag.tipovenda%type,
                                        p_codfilial              in pcfilial.codigo%type,
                                        p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                        p_comissaorcatipovenda   in pcconsum.comissaorcatipovenda%type,
                                        p_percom                 out number
                                        ) ;

PROCEDURE proc_pcparamfilial(p_codfilial IN pcfilial.codigo%TYPE,
                             p_nome      IN pcparamfilial.nome%TYPE,
                             p_padrao    IN pcparamfilial.valor%TYPE,
                             p_valor     OUT pcparamfilial.valor%TYPE);

FUNCTION RETORNARPRECOTABELASEMIMPOSTO(PNNUMPED  IN NUMBER,
                                                         PNCODPROD IN NUMBER,
                                                         PNNUMSEQ  IN NUMBER)
RETURN NUMBER;


END; -- Package spec
