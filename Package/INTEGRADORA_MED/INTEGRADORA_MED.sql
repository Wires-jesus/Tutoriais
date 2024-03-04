CREATE OR REPLACE package INTEGRADORA_MED
IS PRAGMA SERIALLY_REUSABLE;

  /*..
    #VERSAO20210204A
    #VERSAO20210316A
    --++++++++++++++++
    #VERSAO20200601A #VERSAO20203010A #VERSAO20201209A #VERSAO20201218A #VERSAO20210125A 
    #VERSAO20210319A
    #VERSAO20210325A
    #VERSAO20210319A
    #VERSAO20210325A
    #VERSAO20210319A
    #VERSAO20210325A
    #VERSAO20210319A
    #VERSAO20210325A
    #VERSAO20210319A
    #VERSAO20210325A
    #VERSAO20210405A
    -----------------------------------------------------------------------------------------------

    Package de Integracao do Winthor com Sistemas de Forca de Vendas
+++++++++++++++++++++++++++++++++++++++++++++++++++++++
    04/02/2021  Anderson Silva DDMEDICA-5511 - Restrição da Condição
    16/03/2020  Anderson Silva DDMEDICA-5980 - Promoção de Makup na Integração SERVCON
    ----------------     Historico     ----------------
    Data        Responsável    Tarefa     Comentario
    23/08/2010  Andréa         113171      Primeira Versao - (alteracoes iniciais)
    25/01/2011  Andréa         125446      Correções em retorno de mensagens de rejeição
      28/01/2011  Henrique                   Alterada utilização da tabela PCGONDOLACFV para PCGONDOLAFV
    02/02/2011  Andréa         125149      Incluir importação de Pronta Entrega ( venda manifesto) e venda tipo 13. Sendo a venda tipo 13 na mesma tabela de pedidos
    03/02/2011  Andréa         122803      Incluir processo de pedido complementar
    11/03/2011  Andréa         128340      Implementar processo de frios onde a quantidade enviada na tabela pcpedifv será sempre em kilos.
    25/03/2011  Andréa                     Correção em datas para retorno
    15/04/2011  Andréa         130416      Verificar apenas regiões ativas
    25/04/2011  Andréa         128039      Gravar prazomedio na pcpedc, verificando diafixo e diascarencia (utilizando procedure da package de faturamento)
    26/04/2011  Andréa         131147      Utilizar filialnf do cadastro do cliente, caso não seja enviado pelo força de vendas (pcpedcfv.codfilialnf)
    27/04/2011  Andréa         130108      Alterar campanha de brinde por valor total para verificar valor maximo para conceder os brinde, evitando assim que ganhe brindes de campanhas
                                             que distinguem apenas pelo valor minimo de venda
    29/04/2011  Andréa         130781      Implementar processo de medicamento (repasse)
    03/05/2011  Andréa                     Correção em processo de pedido complementar
    05/05/2011  Andréa         131238      Incluir processo de broker
    09/05/2011  Andréa         131429      Implementar processo de venda por embalagem e preço por embalagem, ambos opcionais
    16/05/2011  Andréa         132020      Incluir importação dos campos da pcpedcfv : tipodocumento e codclinf. Validar se codclinf existe na pcclient, caso não exista gravar nulo
    23/05/2011  Andréa         129865      Atualizar chamada da função de desconto por quantidade ( 20 parâmetros) para receber informação se o desconto altera ou não o valor base
                                              para rca e qual é este percentual
    24/05/2011  Andréa         133185      Alterar para verificar parÂmetro validaalvaraporitem da pcparamfilial ao invés de verificar da pcconsum
    27/05/2011  Andréa         132437       Alterar processo de frios para receber a informação da unidade de venda
    03/06/2011  Andréa         133908      Alterar para gravar posição da Indenização 'A', caso o pedido indenizado esteja bloqueado ou Pendente
                                           Gravar preços dos produtos e brinde e validar se preço é válido
                                           Modificar forma de verificar estoque disponivel contábil, igualando com a 316
                                           Ajuste no cálculo de st, buscando parâmetro mostrarpvendasemst da pctribut
    06/06/2011  Andréa         128635      Implementar processo de cesta básica, utilizando também o processo atualizado de preço fixo da cesta básica
    13/06/2011  Andréa         133171      Alterar chamada das functions calcularst ,calcularst fonte e calcularimpostos para Calcular a ST com base no PMC (Preço Máximo ao Consumidor) do produto.
    21/06/2011  Andréa         133319      Incluir importação de venda futura (TV7)
                                           Verificar parâmetros pcconsum.vlmaxvendabnf e pcconsum.vlminvendabnf para pedidos bonificados
                                           Alterar para verificar parâmetro arredondaqtembalfrios da pcparamfilial
                                           Corrigir verificação de brindes
    28/06/2011  Andréa         134170      Implementar processo de simples nacional
                                           Validar múltiplo de venda
                                           Validar pcautorc para permitir aumentar limite de crédido de cliente
     29/06/2011  Andréa         135797     Implementar processo de filial retira . Utilizando primeiro a filial retira da pcpedifv, caso esta esteja nula,
                                             utilizar a da pcpedcfv, caso esteja nula , utilizar da pcprodut, caso esteja nula utilizar a filial de venda
    30/06/2011  Andréa         135931      Correção para enviar mensagem de invalidação quando o parÂmetro numautomaticcli estiver desabilitado.
    06/07/2011  Andréa         136444      Utilizar para verificação de tributação por uf, a filialnf da pcpedcfv, caso esteja nula, utilizar a filialnf do cadastro
                                              do cliente, caso este também esteja nula, utilizar a filial do pedido. Mas caso a filialnf da pcpedcfv estiver nula
                                               será gravada pcpedc.codfilialnf nula.
    11/07/2011  Andréa         136444      Utilizar para verificação da pctabprcli a mesma regra acima, que é utilizada para tributação por estado
    12/07/2011  Andréa         136817      Correção em valor de brinde zerado
    13/07/2011  Andréa         129117      Verificar parÂmetro 'NAOUSARAUTDEBCREDPOLDESC' da pcparamfilial. Caso esteja 'N' ou nulo, a verificação do percentual para
                                            cálculo do pbaserca permanece como está atualmente. Caso esteja 'S', o percentual para cálculo do pbaserca será o percentual
                                            da politica utilizar ( ou seja a maior entre 561 e 201), permanecendo as regras de verificação dos parÂmetros basecreddebrca e
                                             creditasobrepolitica da 561. Lembrando que a verificação deste parâmetro é apenas para a 561.
    14/07/2011  Andréa         136331      Acrescentar verificação de bloqueios da 307 e gravar motivobloqueio e codmotivo na pcpedc para bloqueios fixos na package
    14/07/2011  Andréa         137208      Acrescentar verificação do campo codrede para politica de verba de cmv.
                                           Deduzir o % da verba do conta corrente do RCA quando a opção "Deduzir % do conta corrente do RCA" estiver marcada na rotina 330.
    15/07/2011  Andréa         135986      Utilizar 2 novos parâmetros da pcparmfilial :aceitadesctmkfv e aceitavendarcasemsaldofv.
                                           Caso o aceitadesctmkfv esteja 'S' e o item estiver com desconto acima do permitido o pedido será gravado bloqueado
                                           Caso o aceitavendarcasemsaldofv esteja 'S' e o rca estiver sem saldo suficiente para dar o desconto, gravar o pedido bloqueado
    19/07/2011  Andréa          136584     Gravar campos na pcpedi : precomaxconsum, poriginal e descprecofab conforme regras da tarefa
    19/07/2011  Andréa          134565     Alterar verificação de restrição de venda acrescentando os campos codfilial, condvenda,origemped e fretedespacho.
                                           Caso apenas o codfilial esteja preenchido rejeitar o pedido.
    19/07/2011  Andréa          136941     Incluir campo codcli nas tabelas : pcclientfv, pcvisitafv,pccontatofv,pcgondolafv,pcpedcfv,pcindcfv,pcpedcfvmanif.
                                           Estes campso serão utilizados para empresas que permitem cadastrar mais de um cliente por cnpj. Ele só será utilizado na situação
                                             de encontrar mais de um cliente para o cnpj enviado. Neste caso utiliza o codcli para identificar o cliente corretamente
    19/07/2011  Andréa          136776     Inclir importação e validação do campo codclitv8 em pedido TV7
    19/07/2011  Andréa          137083     Incluir verificação do parâmetro pcclient.validarcampanhabrinde para verificar ou não os possiveis brindes do pedido
    20/07/2011  Andréa          137257     Atualizar validação de comissão para o processo mais completo
    25/07/2011  Andréa          137398     Utilizar codauxiliar da pcprodut para atualizar campo qt_Faturada da pcpedifv, quando na pcpedifv não for enviado codauxiliar.
    25/07/2011  Andréa          137320     Validar parâmetro BLOQUEARPEDIDOSABAIXOVLMINIMO da pcparamfilial, caso esteja 'S' e valor do pedido estiver menor que pcplpag.vlminpedido,
                                            Gravar pedido bloqueado.
    27/07/2011  Andréa          125968     Validar tabela pccobplpag, caso tenha registro para o plano de pagamento ou ocbrança do pedido, o pedido só é aceito se a tiver o relacionamento
                                             codplpag e codcob iguais aos cadastrado na tabela.
    29/07/2011  Andréa          138422     Alterar processo de repasse para somar o valor do repasse ao ptabela e pbaserca
    03/08/2011  Andréa          138694     Corrigir para não calcular  descprecofab quando o poriginal (pcprodut.custorep) estiver nulo ou zero
    11/08/2011  Andréa          138275     Ler, validar e gravar planos de pagamento para medicamentos Eticos e Genericos, de acordo com regras da tarefa
    11/08/2011  Andréa          139349     Colocar nvl no campo pcfilial.tipoavaliacaocomisso para 1
    15/08/2011  Andréa          139425     Correção em calculo de preço de venda para simples nacional
    17/08/2011  Andréa          138958     Acrescentar verificação do parâmetro tipoimportacaovenda da pcparamfilial para evitar rejeições
    18/08/2011  Andréa          139490     Alterar para aplicar descontos em preço sem st para produtos marcados ( mostrarpvendasemst = 'S')
    20/08/2011  Andréa          139855     Incluir importação do campo PCPEDCFVMANIF.DATA para pcpedc.data para venda manifesto
    22/08/2011  Andréa          138760     Acrescentar parâmetro codauxiliar na verificação da restrição de venda
    22/08/2011  Andréa          134500     Acrescentar verificação do parâmetro SOMACREDITOCLIPRINCIPAL para somar o credito disponivel do cliente,
                                           utilizando toda sua rede de clientes
    24/08/2011  Andréa          139855     Não validar data da tv14 com tv13, validar apenas se produto da tv14 existe na tv13
    25/08/2011  Andréa                     Alterar para buscar parâmetro PCPARAMFILIAL.VALIDAALVARAPORITEM para filial = filial do pedido ou 99
    26/08/2011  Andréa                     Verificar parÂmetro tipoimportacaovenda para validação de data de vencimento de alvara

    30/08/2011  Andréa          141380     Validar tamanho da varivael que armazena mensagens de erro para evitar problema de enviar retorno
    05/09/2011  Andréa                     Correção em variavel de mensagens de retorno
    06/09/2011  Andréa          142285     Não armazenar mensagens de invalidação de data dos itens na pcpedc.log
    08/09/2011  Andréa          141864     Incluir rebaixa de cmv
    08/09/2011  Andréa          141267     Retirar verificação de restrição de venda para brinde
    09/09/2011  Andréa                     Gravar pcpedi.pvenda1 em produto cesta/kit
    12/09/2011  Andréa                     Correção em numeração de pedido quando tem rejeição, mensagem de rejeição de item
    14/09/2011  Andréa          141795     Correção feita em processo do simples nacional
    19/09/2011  Andréa          141861     Inclusão de processo de politica prioritaria e processo de combo
    19/09/2011  Andréa          143845     Incluir nvl para pcpedcfvmanif.data
    26/09/2011  Andréa          145065     Gravar custos dos produtos que são kits, como sendo a somatória do custos do itens da cesta
    26/09/2011  Andréa          139405     Verificar se existe registro para cliente na pccobcli. Caso exista só será aceita cobrança que está cadastrada nesta tabela.
    28/09/2011  Andréa          134487     Validar novo parâmetro (USABNFLIMITECREDITO) que possibilitará que nas vendas que possuam o tipo de cobrança "BONIF" o limite de crédito do cliente seja utilizado ou não .
    05/10/2011  Andréa                     Transformada em INTEGRADORA_MED
    17/10/2011  Andréa                     Rejeitar item pedido OL e PE com erro ao encontrar o desconto
    20/10/2011  Andréa          146668     Gravar motivos de rejeição de item e pedido na coluna codmotivonaoatend na pcpedcfv e pcpedifv
    21/10/2011  Andréa                     Corrigr validação de plano de pagamento de medicamento
    27/10/2011  Andréa                     Incluir envio da informação do limite de credito disponivel do cliente
    11/11/2011  Andréa          148959     Incluidas alterações feitas na Integradora no periodo que a INTEGRADORA_MED estava sendo validada :
                                                 145783     Corrigir gravação da quantidade de brinde
                                                 146391     Correção em validação de brinde com erro ORA-00979
                                                 146618     Verificar parâmetro tipocalculognre em conjunto com mostrarpvendasemst
                                                 145214     Validar processo de multiplas filiais por plano de pagamento
                                                 146800     Correção em identificação de estoque para brinde
                                                 146550     Correção em validação da 561
                                                 146080     Incluir leitura e gravacao dos campos : codcob, codplpag,emailnfe da tabela pcclientfv
                                                 146254     Incluir para verificar cobranca cartao (pccob.cartao = 'S'), quando for validar o parametro VERIFICALIMCREDCODCOBD
                                                 146184     Ler e gravar campo tipoprioridadeentrega da tabela pcpedcfv
                                                 145246     Caso esteja parametrizado  utilizavendaporembalagem = 'S' , validar o codauxiliar enviado
                                                            Correção em validação de plano de pagamento
                                                            Verificar preço por embalagem ( mesmo com parâmetro marcado) apenas se o parâmetro utilizavendaporembalagem estiver 'S'
                                                 148066     Correção para verificar se apos a validação do multiplo o item ficou com quantidade válida.
                                                 148099     Correção em validação do desconto permitido
                                                 148084     Correção em calculo de stfonte com ipi, utilizar preco de venda sem ipi
                                           Acrescentar regra para utilização de preço fabrica (custorep e cusrepzfm) para clientes que não precificam medicamentos na 201
    17/11/2011  Andréa          145153     Gravar campos localdesembaraco e ufdesembaraco da pcpedcfv na pcpedc.
    17/11/2011  Andréa          148103     Validar parâmetro pcconsum.liberarpedidopendente, caso esteja 'N' ou nulo e o parâmetro pcparamfilial.aceitavendasemestfv estiver = 'S' e o
                                            item não tiver estoque suficiente, gravar o pedido Pendente.
    22/11/2011  Andréa          148160     Incluir  validação de campanhas de brinde : Valor total e Quantidade Obrigatoria (VO) e Valor Total com Restricoes (VR)
    23/11/2011  Andréa          148590     Incluir verificação dos parâmetros : ACEITADESCPRECOFIXO e ACEITAACRESCIMOPRECOFIXO para permitir dar desconto ou acrescimo sobre o valor do preço fixo.
                                           Incluir validação da coluna pcprecoprom.APLICADESCONTOSIMPLES para permitir ou não dar o desconto do simples nacional sobre o preço fixo
    23/11/2011  Andréa          148819     Validar parâmetro VLMAXVENDABONIFICMES que informa valor maximo de vendas bonificadas no mês.
    28/11/2011  Andréa          147989     Acrescentar regras de plano de pagamento com forma de parcelamento variavel
    30/11/2011  Andrea          150630     Corrigir para utilizar codcli como codcliprinc quando este estiver nulo
    01/12/2011  Andréa                     Corrigir cáculo de prazo médio para pedidos com plano de pagamento cuja forma de parcelamento é variável
    01/12/2011  Andréa          150817     Alterar regra para que pedidos OL e PE sempre utilizem o preço fabrica
    09/12/2011  Andréa          150323     Incluir validação do parâmetro PEREXCEDELIMCRED para valida limite de credito do cliente.
    09/12/2011  Andréa          150598     Verificar parâmetro bloquearpedbonific, caso esteja 'S', gravar pedidos de brinde bloqueado, caso esteja 'N' gravar  na mesma posição do pedido original
    16/12/2011  Andréa                     Correção em validação do parâmetro liberarpedidopendente. Caso o parâmetro aceitavendasemest = 'S' and liberarpedidopendente = 'N' o pedido será gravado
                                            Pendente. Nem será verificado estoque para este caso.
    19/12/2011  Andréa          147507     Implementar desconto financeiro em pedidos que não sejam OL e PE
    21/12/2011  Andréa          152455      Alterar o nvl pcprodut.multiplo para 0
    29/12/2011  Andréa          152992      Gravar pcpedi.poriginal com o preço de tabela da 201 aplicando a taxa do plano de pagamento e desc/acre por ramo de atividade
    03/01/2012  Andréa                      Correções em desconto financeiro
    04/01/2012  Andréa          153277      Corrigir para gravar mensagem de falta de estoque para todos os itens do pedido que estejam com falta
    05/01/2012  Andréa          153405      Alterar Cálculo do Repasse para considerar novo parâmetro que define a base de cálculo do acréscimo de repasse - preço bruto ou preço líquido.
                                            Alterar a regra de refaz o desconto bonificação e comercial quando é acatado o desconto do arquivo em Pedidos Eletrônicos.
    06/01/2012  Andréa          153405      Ajustes feitos pelo Anderson Silva
    10/01/2012  Andréa          152994      Implementar utilização da pctabprcli, tributacao por estado e atualizar politicas de desconto para pedido Pronta Entrega
    12/01/2012  Andréa          153237      Gravar pcpedcfv.posicao_atual = 'R' quando o pedido for rejeitado
    20/01/2012  Andréa          149677      Incluir parâmetro codplpag e codcob na validação de restrição de venda (pcrestricaovenda)
    25/01/2012  Andréa                      Corrigir variavel que está atrapalhando quando parâmetro aceitadescprecofixo está 'S'
    26/01/2012  Andrea          154599      Implementar venda tipo 10
    27/01/2012  Andréa          155026      Alterar forma de identificação de pessoa fisica no calculo de cmv
    27/01/2012  Andréa          148142      Alterar chamada da validação de politica de desconto por quantidade  para incluir validação de restrições (pcgruposcampanhac e pcgruposcampanhai)
    27/01/2012  Andréa          153899      Alterar para criticar o Desconto Máximo da Indústria nos Pedidos de OL.
                                            Validar parâmetro da Integradora gerapedbloq para pedidos OL e PE, caso estja 'S' gravar o pedido bloqueado
    27/01/2012  Andréa          154566      Validar parâmetro aceitavendasemdtvencfv da pcparamfilial, caso esteja 'N' e não tenha dados do pedido na tabela pcpedcvctofv, rejeitar pedido
    30/01/2012  Andréa          142808      Validar parâmetro pcparamfilial.permaxdescvenda, caso esteja nulo validar o pcconsum.permaxdescvenda. Caso o perdesc do pedido esteja superior a estes,
                                               rejeitar o pedido.
    31/01/2012  Andréa          154896      Atualizar rebaixa de cmv para possibilitar verificar várias verbas vigentes para o mesmo produto.
                                            Incluir processo de rebaixa para itens de pedido de brinde
    31/01/2012  Andréa                      Alterar codigo de invalidacao do item com critica de desconto da industria para 902
    02/02/2012  Andréa          154920      Separar apuração de campanha em outra package, incluir chamada desta nova package.
                                            Incluir registros de brinde ( cabeçalho e itens) nas tabelas: pcretornoctv5fv,pcretornoitv5fv.
                                            Atualizar o campo pcpedcfv.geroubrinde com a informação de geração ou não de brinde.
    07/02/2012  Andréa          143646      Utilizar regra da politica de desconto prioritariaa geral ( 561). Caso tenha uma politica cadastrada como prioritaria geral,
                                              ela irá sobrepor as demais politicas que tenha na 561 e também desconto por quantidade e preço fixo
    07/02/2012  Anderson        155824      Permitir TV10 no OL
                                            Correção Linha de Prazo
    13/02/2012  Andréa          154935      Gravar informação no campos pcpedcfv.atendido. Valor P para caso tenha corte de item ou de quantidade de algum item e T para atendido Total
    13/02/2012  Andréa          156260      Corrigir para retirar espaço dos campos que contem a informação do cnpj/cpf do cliente
    23/02/2012  Anderson        156777      Adicionar na Validação de Pedido Duplicado o Critério da Quebra de Pedidos gerada pelo parâmetro FIL_NUMMAXITENSNFE
    27/02/2012  Andréa          152144      Incluir validação de restricao por plano de pagamento (pcplpagrestricao)
    28/02/2012  Andréa          152983      Calcular percentual de desconto de isencao de impostos do produto de acordo com a parametrizacao do campo "%Desc.Isencao(Suframa)" do cadastro do cliente
    28/02/2012  Andréa          151307      Validar o parâmetro "Utiliza %Desc Isencao ICMS para vendas a prazo"
    29/02/2012  Anderson        157402      Não realizar o Incremento de PROXNUMPEDFORCA quando Pedidos OL/PE. Esse Incremento é realizado na própria Rotina de Importação de Pedidos
    02/03/2012  Andréa          157355      Incluir verificação e alteração de saldo de rca para venda 14
    05/03/2012  Andréa          152496      Zerar st e baseicst nas Vendas para Clientes que são Órgãos Públicos e para os Produtos que estão Tributados com Isenção de ST para Órgãos
                                             Públicos.
    07/03/2012  Andréa          157985      Caso exista cadastro do cliente na pcplpagcli para o plano de pagamento da venda, não validar prazo com o plano do cadastro do cliente
    07/03/2012  Anderson        158047      Somente rejeitar itens em Pedidos do TipoFv = PE se a diferença for superior a 2 centavos
    15/03/2012  Andréa          158518      Incluir processo de conversão de estoque do produto master
    15/03/2012  Anderson        158742      Considerar o NUMPEDCLI E CODIGOPROJETO na Validação de Pedido já Importado em Pedidos SevenPDV
    16/03/2012  Andréa          158745      Utilizar pcembalagem.fatorpreco para compor o preco de tabela para venda por embalagem
    23/03/2012  Andréa          157883      Incluir importação de Cotações ( pccotafv)
    23/03/2012  Andréa          157620      Incluir validação do parâmetro obrigatoriovinculartv5comtv1 para venda bonificada
    26/03/2012  Andréa          158774      Inlcuir validação do parâmetro separarprodcomrestricaotransp para separação de pedido com itens com restrição de transporte
    26/03/2012  Andréa          159551      Correção no processo do simples nacional para calculo do pbaserca
    27/03/2012  Anderson        159858      Validação Duplicidade para Layout Running
                                            Tornar o procedimento que calcula os descontos MED publica
    28/03/2012  Andréa          158600      Incluir gravação de PCORIGEMCOMIS e PCORIGEMDESC
    29/03/2012  Andréa          159881      Retirar regra em que para pedidos bonificados o ptabela fique igual ao pvenda
    02/04/2012  Andréa          159918      Correção em processo do simples nacional
    03/04/2012  Andréa          159599      Acrescentar novos campos de importação de clientes
    03/04/2012  Andréa          159606      Acrescentar importação de Referencias comerciais de clientes ( PCCLIREFFV)
    16/04/2012  Andréa                      Incluir envio de mensagem da procedure PRC_CONVERSAO_ESTOQUE_PACOTE
    18/04/2012  Andréa          161194      Aplicar percentual de juros para pedidos com plano de pagamento variavel antes dos calculos de cmv, st, e comissão
    20/04/2012  Andréa                      Alterar nome da coluna envionfeemailcom da pcclientfv para envionfemailcom
    20/04/2012  Andréa          161534      Correção na verificação de parâmetro da pcparamfilial
    23/04/2012  Andréa          161610      Corrigir para que quando fatorpreco da pcembalagem estiver 0, transformá-lo em 1
    26/04/2012  Andréa          160801      Atualizar dtultcomp da tabela pcclient quando importar algum pedido  e gravar pcpedi.geragnre_cnpjcliente
    27/04/2012  Andréa          160454      Atualizar chamada da funcoesvendas.validarpoliticadesconto (561) para acrescentar parâmetro numdias
    02/05/2012  Andréa          162132       Correção em processo de corte de estoque de frios
    11/05/2012  Andréa          161396      Alterar procedure PRC_VEN_OBTEM_DESC_CONDVENDA deixando-a publica e acrescentar alterações feitas por Anderson SIlva
    14/05/2012  Andréa          162975      Gravar posição da Indenização = 'A' quando o pedido original estiver Liberado
    15/05/2012  Andréa          159345      GRavar informação de agrupamento nos pedidos
    23/05/2012  Andréa          162789      Implementar venda TV20
    24/05/2012  Andréa          163133      Inverter gravação dos campos de enderecos enviados nos campos final "ent" com os campos final "com"
    25/05/2012  Andréa          163938      Corrigir para não dividir preço de venda de itens que são embalagem quando usa o preço por embalagem
    29/05/2012  Andréa          164145      Correção para reserva de estoque de item de pedido complementar sem estoque quando o pedido original está Liberado
    30/05/2012  Andréa          164317      Incluir validação da pctabprcli na importação de indenizações
    31/05/2012  Andréa          164317      Acrescentar nvl na verificação da filialnf a ser utilizada na busca da pctabprcli das indenizações
    01/06/2012  Andréa          164522      Correção em processo de preço por embalagem para dividir preço de venda e preço de tabela (pcembalagem) pelo qtunit
    04/06/2012  Andréa          164482      Alterar para verificar parâmetro FIL_BLOQUEARPEDIDOSABAIXOVLMINIMO ao inves de BLOQUEARPEDIDOSABAIXOVLMINIMO
    11/06/2012  Andréa          164877      Acrescentar nvl no campo pcest.valorultent
    12/06/2012  Andréa          165063      Retirar validação de cod_cadrca na pcsuperv
    20/06/2012  Andréa          165788      Correção para não atribuir codcobinicial e codplpaginicial para alteração de cadastro de clientes
    26/06/2012  Andréa          156566      Incluir validação do parâmetro VLMINVENDABKFILIAL que sobrepoe o VLMINVENDABK
    27/06/2012  Andréa          164047      Incluir processo de tipo de bonificação
    06/07/2012  Andréa          164694      Separar a parte cadastral em uma nova package
    16/07/2012  Andréa          167578      Correção em validação da politica 561
    18/07/2012  Andréa          165466      Atualizar gravação da pcorigempreco
    19/07/2012  Andréa          167828      Corrigir validação de 561 com 387 automática
    20/07/2012  Andréa          168116      Corrigir validação de percentual de indenização ( truncando) para evitar rejeições
    23/07/2012  Andréa          164660      Incluir validações do valor do pedido pos corte
    27/07/2012  Andréa          168591      Alterar para retirar st do item com preço fixo na validação quando este possuir preço fixo
    01/08/2012  Andrea          169083      Alterar para aplicar taxa do plano de pagamento e acrescimo pessoa fisica no produto cesta e nos itens
    09/08/2012  Andrea          169695      Incluir regra de validacao de plano de pagamento com vencimento variavel, para validar pelo prazo medio quando tiver uma unica parcela
    13/08/2012  Andrea          170071      Arredondar preco minimo de venda da 201 para comparar com o preco de venda enviado
    16/08/2012  Andréa          169666      Separar processo de pronta entrega em outra package
    22/08/2012  Andrea          171461      Na venda broker, nao validar se cobranca do cliente esta cadastrada como broker
    27/08/2012  Andrea          171602      Validar novo parametro para bloquear ou rejeitar pedido de cliente sem limite de credito
    27/08/2012  Andrea          171439      Caso nao seja enviado fretedespacho na pcpedcfv, gravar o fretedespacho do cadastro do cliente
    31/08/2012  Andrea          172814      Corrigir para validar se o pedido TV1 enviado como referencia no pedido TV5 esta com o campo contaordem nulo
    01/10/2012  Andréa          176263      Correção em corte quando produto é multiplo
    02/10/2012  Andréa          176377      Correção em forma de identificar pessoa fisica
    18/10/2012  Andréa          177943      Incluir gravação de valor de entrada no pedido
    22/10/2012  Andréa          177956      Validar redes de clientes
    24/10/2012  Andréa          178874      Utilizar plano de pagamento de acordo com tipo de medicamento para validação de preço de OL e PE
    24/10/2012  Andréa          178900      Para produtos retinoicos, validar data de vencimento de alvara para retinoicos
    24/10/2012  Andréa          178865      Retirar validação de parametro aceitavendabloq quando o pedido ou parcela não atingir o valor minimo para boleto
    24/10/2012  Andréa          177935      Retornar mais informações sobre estoque quando o pedido for gravado Pendente
    25/10/2012  Andréa          179131      Incluir verificação de tributação por estado nas indenizações
    07/11/2012  Andréa          180375      (180181) Arredondar o preço da 201 antes de retirar os impostos, igualando ao processo da 316
    08/11/2012  Andréa          180375      (180181) Caso a função de retornar preço sem impostos retorne um valor cuja diferença com o valor original seja menor ou igual a R$0.01
                                             utilizar o valor original
    08/11/20121 Andréa          180116      Incluir validação do parâmetro pcintegradora.origempreco para identificar se o preço utilizado será o de tabela ou de Fábrica
    12/11/2012  Andréa          180667       Corrigir aplicação de percentual de desconto de produto cesta, nos itens da cesta
    19/11/2012  Andréa          181169       Corrigir atualização de pbaserca para politica de credito da 561
    20/11/2012  Andréa          180114       Ler e gravar campo recolher nos itens de indenizacao
    21/11/2012  Andréa          181659       Caso o parâmetro separarprodcomrestricaotransp esteja desmarcado, verificar se existe algum item do pedido com restricao de
                                                 transporte ou restricao de transporte refrigerado. O pedido deve ser marcado com a restrição. Se houver itens com os 2 tipos
                                                 de restrição, marcar o pedido como Refrigerado
    21/11/2012  Andréa          181620       Não converter estoque de embalagens para pedidos OL e PE, mesmo que o parâmetro para converter esteja marcado
    26/11/2012  Andréa          181847       Incluir importação de Orçamentos
    28/11/2012  Andréa          182222       Acrescentar a identificação do produto (codprod) na mensagem da procedure de conversão de estoque
    12/12/2012  Anderson Silva  184043       Novo parâmetro para cálculo do desconto financeiro do item (vldescboleto)
    26/12/2012  Andréa          181875       Corrigir para não gravar pbaserca nulo
    04/01/2013  Andréa          186003       Corrigir validação do parametro permitirvendainterestadual para pessoa fisica
    08/01/2013  Andréa          185767       Incluir utilizacao da regiao para venda balcão, cadastrada na 132 ( FIL_NUMREGIAOBALCAOINTER)
    09/01/2013  Andréa          185765       Incluir validação dos novos parametro vlminvendafv e vlminvendabnffv. Caso estes estejam nulos ou com valor zero,
                                              serão validados os parâmetros vlminvenda e vlminvendabnf respectivamente.
                                             Verificar parâmetro VALIDAVLMINVENDABALCAO para validar ou não valor minimo para venda Balcão.
    10/01/2013  Andréa          185763       Validar valor RP para parametro aceitavendasemestfv, com este valor, rejeitar pedido, caso tenha algum item com falta de estoque
    14/01/2013  Andréa          186801       Correção em calculo de pcfalta quando estoque disponivel está negativo
    15/01/2013  Andrea          187031       Atualizacao no processo de preco por embalagem
    17/01/2013  Andréa          187259       Corrigir calculo de pbaserca, caso tenha politica automática e flexivel
    24/01/2013  Andréa          187817       Gravar novo campo na pcpedc NUMPEDVANXML
    06/02/2013  Andréa          189080       Incluir validação de quantidade maxima de determinado produto no pedido (pcprodfilial.qtmaxpedvenda)
    07/02/2013  Andréa          189075       Incluir validação de codigo de endereço de entrega de cliente
    06/03/2013  Andréa          191680       Corrigir gravação do codicmtab para pessoa fisica
    19/03/2013  Andréa          192724       Alterar para gravar poriginal na pcpedi, antes de acrescentar a taxa do plano de pagamento ao preço de tabela para não afetar o processo de combo
    20/03/2013  Andréa          193097       Permitir gravar orçamento para venda 13
    21/03/2013  Andréa          193249       Incluir validação de cotas de clientes e rcas (pcprodusur)
    22/03/2013  Andréa          193130       Incluir gravação/validação de cliente recebedor e cliente autorizador
    23/03/2013  Andréa          193104       Validar margem de lucratividade do pedido se esta está acima da margem minima do plano de pagamento
    25/03/2013  Andréa          193274       Ajustar regras de isenção de icms
    27/03/2013  Andréa          193622       Corrigir para que ao gravar valor na coluna log da pcpedc, verifique antes se não estourou o limite. Problema causado por rejeição de vários itens do pedido e este
                                              sendo gravado bloqueado ao invés de rejeitar itens
    04/04/2013  Andréa          194417       Só validar margem minima para plano de pagamento se esta tiver valor maior que zero
    05/04/2013  Andréa          194424       corrigir variável que indica quantidade falta antes da validação de saldo disponivel do rca
    05/04/2013  Andréa          194424       Alterar para lançar os créditos antes dos débitos na conta corrente do rca. Este procedimento já é feito para verificar saldo disponível, precisou ser feito
                                             no lançamento também, por causa de uma constraint no cliente que não deixa atualizar o vlcorrente negativo.
    08/04/2013  Andréa          194518       Incluir chamada da procedure PRC_GERARPEDIDOITEMCOMST para separar pedido com item que tenha st
    17/04/2013  Andréa          155964       Para venda com plano de pagamento que exige entrada, validar parametro para descontar o valor da entrada ao verificar o limite de credito
    24/04/2013  Andréa          196485       Não deixar complementar pedido se o processo de WMS tiver sido iniciado
    22/05/2013  Andréa          199699       Acrescentar regras de broker para escolha da região,gravação de campos no pedido e cutos dos itens
    28/05/2013  Andréa          199697       Alterar validação de alguns parâmetros do produto para a pcprodfilial e acrescentar processo de venda fracionada
    04/06/2013  Andréa          200970       Corrigir validacao do parametro verificarclientesrede
    05/06/2013  Andréa          200970       Gravar no campo motivoposicao a mensagem de bloqueio da rede de clientes
    18/06/2013  Andréa          190488       Alterar para verificar parametro verificaestoquecont da pcparamfilial
    18/06/2013  Andréa          195136       Quando utilizar preço por embalagem, se o preço a ser utilizado for o de atacado e este estiver nulo ou zero, utilizar o preço de varejo
    19/06/2013  Andréa          195136       Incluir validação do parametro com o tipo de repasse
    19/06/2013  Andréa          196394       Incluir validacao do parametro bloqueiavendaestpendente para que a quantidade em estoque pendente entre ou não no calculo do estoque disponivel
    21/06/2013  Andréa          196383       Permitir indenizacao/troca de produtos proibidos para venda ou fora de linha
    24/06/2013  Andréa          196064       Acrescentar validação do percentual maximo de acrescimo para fv
    24/06/2013  Andréa          199999       Gravar campo codmotbloqueio na pcpedc
    25/06/2013  Andréa          185261       Acrescentar comissao por embalagem
                                             Gravar campo utilizavendaporembalagem na pcpedc
    01/07/2013  Andréa          203309       Corrigir utilização de calculo de verba por preço liquido
    03/07/2013  Andréa          178683       Incluir opção de utilizar venda e preço por emebalagem nos itens da cesta
    05/07/2013  Andréa          204123       Comentar alteração da tarefa 178683
    15/07/2013  Andréa          204861       Corrigir para aplicar a taxa do plano de pagamento para itens de medicamento, mas apenas para pedidos de FV
    16/07/2013  Andréa          190868       Acrescentar a opção de rejeitar todo o pedido, caso tenha algum item com desconto acima do permitido
    17/07/2013  Andréa          204407       Corrigir gravação de cmv para produto cesta  e atualizar processo de comissão dos itens da cesta
    18/07/2013  Andréa          204784       Incluir validação de horário permitido para importação de pedidos
    18/07/2013  Andréa          205205       Corrigir gravação do campo coddesconto na pcpedi
    30/07/2013  Andréa          202676       Alterar validação do parametro verificarbloqueiosefaz e inclur validação do parâmetro validaclisefaz
    30/07/2013  Andréa          206049       Corrigir corte indevido no estoque quando utilizado parametro bloqueiavendaestpendente
    02/08/2013  Andréa          205746       Incluir chamada da procedure que gerar o pedido TV8
    07/08/2013  Andréa          206837       Incluir procedure que faz a verificação dos parametros da pcparamfilial
    08/08/2013  Andréa          207036       Incluir validação de parâmetro para bloquear ou rejeitar pedido abaixo da margem minima.
    09/08/2013  Andréa          207010       Incluir validação da nova coluna  usadebredrca da pcclient
    09/08/2013  Andréa          207032       Gravar utilizavendaporembalagem na pcpedc
    15/08/2013  Andréa          207034       Acrescentar processo de comissão por profissionais
    16/08/2013  Andréa          207714       Acrescentar parametro na chamada da procedure de preço Fixo da funcoesvendas
    20/08/2013  Andréa          207733       Validar pccobplpag apenas se existir registro da cobrança do pedido
    23/08/2013  Andrea          179985       Incluir restricao por plano de pagamento na validação de combo
                                             Incluir validação do codauxiliar no preço fixo, caso esteja parametrizado precoporembalagem
    28/08/2013  Andréa          208504       Corrigir gravação do campo corte na pcpedifv
    03/09/2013  Andréa          209703       Corrigir para gravar mensagem de retorno da procedure de conversão de estoque nos itens ao inves do cabeçalho
    09/09/2013  Andréa          209906       Valor valor minimo do pedido por rca
    09/09/2013  Andréa          209912       Ignorar processo de frios quando trabalhar com venda por embalagem
    20/09/2013  Andréa          211577       Corrigir para aplicar o percentual de desconto quando tiver 2 politicas automáticas na 561, sendo uma de acrescimo e outra de desconto
    20/09/2013  Andréa          211581       Validar numero de itens minimo por plano de pagamento após os cortes
    23/09/2013  Andréa          211580       Incluir as seguintes validações: Valor maximo para pedido e diferença entre fretedescpacho enviado e o do cadastro do cliente.
                                             Alterar validações para ao inves de rejeitar, bloquear o pedido de acordo com parametro aceitavendabloq :
                                               - Valor do pedido abaixo do minimo para rca, cobrança, filial, prazo medio, boleto, margem e alvara vencido.
    27/09/2013  Andréa          212262       Corrigir retirada de valor de isenção de cofins
    02/10/2013  Andréa          212397       Corrigir aplicação de politica automática da 387
    07/10/2013  Andréa          212669       Retirar processo de indenização
    08/10/2013  Andréa          213286       Corrigir validação de comissão nula
    10/10/2013  Andréa          213380       Merge de alterações feitas pelo Anderson Silva ( 06/06/2013  Anderson Silva  201059  ParticipaGiro
                                                                                              23/08/2013  Anderson Silva  208417  Desconto Quant. no OLePE)
    11/10/2013  Andréa          213379       Alterar para que a comissão do produto cesta na pcpedi, seja a média das comissões da pcpedicesta
    17/10/2013  Andréa          213977       Corrigir baixa de estoque para pedidos com mesmo produto em filiais retira diferentes e sem codauxiliar
    18/10/2013  Andréa          211577       Corrigir regra da tarefa 211577
    23/10/2013  Andréa          3559.000578.2013  Correção para ignorar valor de repasse no preço de venda em validações para calculo do pbaserca
    29/10/2013  Andréa          HIS.00045.2013    Inclusão de regra de st para clientes de MG ( legislação)
    19/11/2013  Andréa          211878       Incluir validação da coluna origempreco da pcclient para conceder bonificação
    16/01/2014  Andréa          HIS.00192.2014 Incluir parâmetros para execução da package : codigo do rca, codigo da filial e numero do pedido no palm
    27/02/2014  Anderson        2343.021461.2014 - No layout hypermarcas usar também o numpedcli na pesquisa de duplicidade
    30/04/2014  Anderson        HIS.01334.2014 Nova Validação de Alvará
    30/04/2014  Anderson                       Acordo Parceria
    01/05/2014  Anderson                       Merge novas Regras ST Fonte MED
    12/05/2014  Anderson                       Pedido de OL e PE não baixar c/c e gravar transportadora do cliente
    14/05/2014  Anderson                       Desconto Financeiro no OL
    02/06/2014  Anderson        HIS.00752.2013 Baixa Pedido Compra OL; Gera Despesas
    06/06/2014  Anderson        HIS.02198.2014 ST última Entrada
    06/06/2014  Anderson        HIS.01779.2014 Cortar somente a quantidade excedida Alvará
    26/06/2014  Anderson        HIS.02658.2014 ST última Entrada não poder ir para Consumidor Final; Merge Farmácia Popular;
    30/06/2014  Franklin        HIS.02655.2014 Integradora Tributação Cliente Filial
    01/07/2014  Franklin        HIS.00490.2014 Comissão Integradora OL
    02/07/2014  Franklin        HIS.02613.2014 Isenção de ICMS para produtos usados no tratamento do câncer
    16/08/2014  Anderson        4663.087543.2014 Acréscimo na Venda na Integradora; Aplicar Desconto Tributação no Preço Tabela
    18/12/2014  Anderson                         Força de Vendas com Promoção de Desconto Automático
    27/08/2014  Anderson        HIS.03151.2014   ST Pelo Preço Tabela
    17/08/2014  Anderson        HIS.03889.2014   OL e PE utilizar o novo conceito de Promoção
    17/12/2014  Anderson        4663.138555.2014 Retirar Restrição de Cliente em Negociação para usar nova Proc. de Promoção
    28/01/2014  Anderson Silva  CAT CMED [HIS.00021.2015]
                                Regime Isenção [HIS.04991.2014]
    05/02/2015  Anderson Silva  Promoção no Força de Vendas
    28/02/2015  Anderson Silva  HIS.05019.2014 - Novo Modelo de Restrição
    13/03/2015  Anderson Silva  HIS.00301.2015 - Regra de Faturamento Integral
    16/04/2015  Anderson Silva  4663.042206.2015 Somente Validar a Restrição de Venda se encontrou o Produto pra não ocorrer erro internamente e bloquear o pedido -
    24/04/2015  Anderson Silva  NO FV gravar também a Transportadora do Cliente se não vier no Pedido
    06/05/2015  Rubens Junior   Utilizar a nova função validarrestricaovendamed para pedidos de origem PE e OL.
    01/07/2015  Anderson Silva  HIS.01858.2015 - Somar ST no PVENDA no Pedido de OL em clientes Não Fonte
    06/08/2015  Anderson Silva  HIS.02854.2015 - Pedido Eccomerce
    16/09/2015  Anderson Silva  HIS.03394.2015 - Promoção no Força de Vendas
    17/09/2015  Anderson Silva  HIS.03394.2015 - Comissão Promoção no Força de Vendas
    23/09/2015  Anderson Silva  Log Rejeição Preço Força Vendas
    29/09/2015  Anderson Silva  Regra MichaelSoft - Força de Vendas para usar o Plano enviado no Palm como Plano Genérico (O Ético permanece o do Cliente)
    21/10/2015  Anderson Silva  2956.117152.2015 - Restrição por Marca
    22/10/2015  Anderson Silva  HIS.03472.2015 - Tipo Critica da Integradora para Cliente Bloqueado
    04/11/2015  Anderson Silva  meddifaceiteprecominimofv
    19/11/2015  Anderson Silva  4180.124820.2015 - Validar Psico. e Retin. sem condições adicionais
    23/11/2015  Anderson Silva  MERGE: RESTRIÇÃO DE PREÇO
    27/11/2015  Anderson Silva  Regra Etico Generico MichaelSoft.
    28/12/2015  Anderson Silva  HIS.04408.2015 - Preço Fábrica/PMC por UF
    30/12/2015  Anderson Silva  HIS.04557.2015 - ICMS Partilha
    10/01/2016  Anderson Silva  FocoPDV
    14/01/2016  Anderson Silva  Perbonific preencher se Origem = Tabela de Preços
    20/01/2016  Anderson Silva  Procedure para cálculo do Repasse (FocoPDV)
    21/01/2016  Anderson Silva  Observar TIPOCONFIGDEBCREDRCAPROMOMED no FV
    02/02/2016  Anderson Silva  Motivo 24 - CRF; Gerar Motivos na Integração ArtNew e FocoPdv
    03/02/2016  Anderson Silva  Priorização Promoção Item do Pedido
    17/02/2016  Anderson Silva  HIS.00211.2016 - Repasse STBCR
    15/02/2016  Anderson Silva  Gravação CODDESCONTO; Comissão Promoção FV
    19/02/2016  Anderson Silva  0.01 Dif Arredondamento
    25/02/2016  Anderson Silva  Regra Específica Importação FV - Manter Desconto da Promoção de Desconto
    22/03/2016  Anderson Silva  Não Debitar/Creditar - considerar na validação o PTABELA - %Desc.C/C (TIPOCONFIGDEBCREDRCAPROMOMED = 1 ou 2) ; Promoção Cabeçalho a partir dos Itens
    22/03/2016  Anderson Silva  HIS.00182.2016 - MEDAPLICARDESCOMCLIPTABELA
    22/03/2016  Anderson Silva  PERTXFIM e MEDAPLICARDESCOMCLIPTABELA no PE; restringirpromocaomed; gravar pcpedi.percdescbaserca
    03/04/2016  Anderson Silva  HIS.01025.2015 - Separar Origem - FocoPDV
    03/04/2016  Anderson Silva  CRF no OL/PE - Não gerar aviso porque não bloqueia
    07/04/2016  Anderson Silva  Operador Logístico não possui crítica de margem mínima (Descontos da Industria); TIPOCOMISSAOMED; Promo Cab. 999999999
    19/04/2016  Anderson Silva  Tratamento Desconto >= 100%; TIPOCOMISSAOMED
    27/04/2016  Anderson Silva  2881.043813.2016 - Repasse para TV5
    29/04/2016  Anderson Silva  5047.047570.2016 - Prioriza Comissão da Promoção
    09/05/2016  Anderson Silva  HIS.00365.2016 - Tetos Desconto
    30/05/2016  Anderson Silva  5666.058584.2016 - Valor Mínimo Pós Corte
    07/06/2016  Anderson Silva  Regra Usa St Fonte na Precificação
    23/06/2016  Anderson Silva  somente executar proc_encontrapvenda Somente se a Filial não Utilizar Desconto Simples Nacional
    25/06/2016  Anderson Silva  LOG IMPOSTOS
    26/06/2016  Anderson Silva  validarpoliticasdesconto_med na FUNCOES_MED
    29/05/2016  Anderson Silva  4493.064633.2016 - Tratamento Divisão por Zero
    28/07/2016  Anderson Silva  5685.084449.2016 - Gravar o Motivo Desconto Inválido
    04/08/2016  Anderson Silva  5685.084449.2016 - Restringir Promoção do Item
    01/09/2016  Anderson Silva  HIS.02194.2016 - Integração Pharmalink - Preço
    09/09/2016  Anderson Silva  4493.094840.2016 - Revalidar Pedido Duplicado
    24/10/2016 - HIS.03080.2016 - Anderson Silva - Importar Promoção Preço - OL e PE
    28/10/2016  Anderson Silva  2438.122391.2016 - OL e PE - Verificar no Inicio do Processo se Pedido existe na PCPEDC
    30/10/2016  Anderson Silva  4180.122638.2016 - Revalidação do Custo do Produto - OL e PE
    07/11/2016  Anderson Silva  HIS.03261.2016 - ICMS PARTILHA por CFOP
    07/06/2016  Anderson Silva  HIS.02787.2016 - Origem Nacional/Importado no CMV
    19/12/2016  Anderson Silva  HIS.01765.2016 - Validação do Preço Máximo do Consumidor
    02/01/2017  Anderson Silva  HIS.03249.2016 - Sem comissão nos Tipos de Venda [4, 5, 8, 9, 10, 13, 11, 20] igual na 2316; Tipo 5 Gravar PMC
    06/02/2017 Anderson Silva   4415.012539.2017 - RCA por Linha de Prazo
    23/02/2017  Anderson Silva  2438.022821.2017 - Pedido já existe
    07/03/2017  Anderson Silva  0.021126.2017 - Melhorar mensagem Cobrança
    07/03/2017  Anderson Silva  OLePE - PMC Liberados
    19/04/2017  Anderson Silva  - HIS.03536.2016 - Processamento de Combos
    07/03/2017  Anderson Silva  5047.045589.2017 - Regra Específica para revalidar Valor Minimo por causa do corte por conta corrente rca
    27/04/2017  Anderson Silva  HIS.01115.2017 - Atualizar o Código Motivo Bloqueio após o Corte
    27/04/2017  Anderson Silva  4415.043506.2017 - Validação Saldo RCA - Observar Regra do Tipo de Bonificação
    13/06/2017  Frank - 4493.069339.2017 - Não parar o Processamento de Pedidos 'OL' e 'PE' se houver erro no Saldo do Conta Corrente
    14/06/2017  Anderson Silva 5666.060720.2017 - Multiplo do Produto por Produto/Filial
    09/09/2017  Anderson Silva HIS.02738.2017 - HIS.02738.2017 - Combos
    19/09/2017  Anderson Silva HIS.03377.2017 - ST Relevante e Não Relevante
    15/01/2018  Anderson Silva 4954.149614.2017 - Atualização de Corte dos Pedidos FV que foram Processados
    06/02/2018  Anderson Silva 4954.013038.2018 - Igualar a 2316, abatendo o Desconto da Promoção no PBASERCA TV5
    09/02/2018  Anderson Silva HIS.00262.2018 - Acréscimo OL
    15/02/2018  MERGE: 31/07/2017  Anderson Silva Acordo Preço Pedido Eletrônico
    15/02/2018  MERGE: 30/07/2017  Anderson Silva HIS.03831.2017 - Taxa Acordo Parceria
    15/02/2018  MERGE: 13/10/2017  C/C Rca com Pedido de Promoção sem escolher Promoção no Item
    15/02/2018  MERGE: 24/10/2017  Parâmetro CODDESCONTO na Procedure prc_med_validacao_final_prod
    27/02/2018  Anderson Silva  MED-869 - Validação Planos MED no pós Corte
    28/02/2018  Anderson Silva  MED-820 - Revalidação Duplicidade Pedido OL/PE pós Corte
    16/04/2018  Anderson Silva  MED-1070 - Merge Específica Múltiplo IGNORAMULTIPLOPRODFV
    21/06/2018  Anderson Silva  MED-1299 - Tratamento FV para NUMPED com Transação Autônoma
    28/05/2018  Anderson Silva  MED-861 - TIPOIMPORTACAOVENDA Vendas por Integradora
    06/08/2018  Anderson Silva  MED-1456 - E-Commerce não conflitar com a Máxima
    14/08/2018  Anderson Silva  MED-1510 - IPI Somado no Preço de Venda
    28/08/2018  Anderson Silva  MED-1554 - Faixa de Quantidade na 561
    29/08/2018  Anderson Silva  MED-1600 - Semáforo para Importação de Pedidos do Força de Vendas
    29/08/2018  Anderson Silva  MED-1566 - Promoção Preço Fixo sem Desc. Simples Nacional
    05/09/2018  Anderson Silva  MED-1645 - Desconto Financeiro da 561
    02/09/2018  Anderson Silva  Taxa Frete.
    14/09/2018  Anderson Silva  Tratamento Lock Estoque
    19/09/2018  Anderson Silva  Correção Importar Cadastros
    01/10/2018  Anderson Silva  MED-1719 - Controle sobre a Package de Campanha
    10/10/2018  Anderson Silva  MED-1230 - Endereço do Cliente
    09/11/2018  Anderson Silva  MED-1895  Log Limite Crédito
    13/11/2018  Anderson Silva  MED-1499  Melhora Mensagens
    20/11/2018  Anderson Silva  MED-1822 - Política Verba CMV E-Commerce
    21/11/2018  Anderson Silva  Merge - Rejeitar Itens Fora de Linha sem Estoque Gerencial
    28/11/2018  Anderson Silva  MED-1964 - Alteração Select Refatoração de Estoque
    05/01/2019  Anderson Silva  MED-2079   Validação Margem Mínima
    09/01/2018  Anderson Silva  MED-1613 - Aplicação da Taxa do Plano nos OLs
    24/01/2019  Anderson Silva  MED-2161 - Alteração forma gravar os motivos
    15/03/2019  Anderson Silva  MED-2349 - Validação Saldo RCA parâmetro ACEITAVENDARCASEMSALDOFV
    22/03/2019  Anderson Silva  MED-2270   Cálculo Custo pela própria integradora
    22/03/2019  Anderson Silva  MED-2362 - Parâmetro BLOQPEDLIMCRED Geral
    31/03/2019  Anderson Silva  MED-2263 - Fora de Linha
    02/04/2019  Anderson Silva  MED-2371 - Região Diferenciada da Integradora
    13/05/2019  Anderson Silva  MED-2567 - Alteração Validação Pedido Ja Existente FV
    14/05/2019  Anderson Silva MED-2572 - Gravação Campo Usa Crédito RCA
    14/05/2019  Anderson Silva MED-2532 - Validar Mínimo sem ST requer opção para ignorar parâmetro 2548
    14/05/2019  Anderson Silva MED-2574   Ignorar Parâmetro Desconto Máximo da 132
    19/05/2019  Anderson Silva 4493.055952.2019 - Promoção de Markup
    19/05/2019  Anderson Silva MED-2521 - Isenção ST BNF
    10/06/2019  Anderson Silva MED-2453 - Igualar Rebaixa CMV Cliente à 2316
    04/07/2019  Anderson Silva DDMEDICA-198 - Item Bonificado
    29/07/2019  Anderson Silva  DDMEDICA-380 - Não limpar o NUMED da PCPEDRETORNO se o Pedido existir na PCPEDC
    05/08/2019  Anderson Silva DDMEDICA-468 - Regra Específica para COMBOS da 3306 não movimentarem Conta-Corrente do RCA
    12/08/2019  Anderson Silva DDMEDICA-482 - Log Validação Conta-Corrente
    16/08/2019  Anderson Silva DDMEDICA-585 - Chamada Especial para Importar Pedido da Rotina 2302
    29/08/2019  Anderson Silva DDMEDICA-675 Função para validação restrição de filial no plano
    12/09/20019 Anderson Silva DDMEDICA-706 Otimização Obter Desconto Integradora
    02/12/2019  Marcos Levi    DDMEDICA-1114
    04/12/2019  Anderson Silva DDMEDICA-1495 Promoção por Lote
    23/12/2019  Anderson Silva DDMEDICA-1654 Procedimento para retornar a transportadora da frequência de entrega
    20/01/2019  Anderson Silva DDMEDICA-1835 Grupo de Comissão na Integradora
    31/01/2019  Anderson Silva DDMEDICA-2025 Conflito NUMPEDRCA Força de Vendas C2
    04/02/2019  Anderson Silva DDMEDICA-2063 - Avaliar pedidos OL cancelados na PCPEDC ao validar pedido existente
    06/03/2020  Anderson Silva DDMEDICA-2314 - Arredondamento SUFRAMA
    11/03/2020  Anderson Silva DDMEDICA-2349 - Recálculo ST Bonificações Brinde Express
    27/04/2020  Anderson Silva DDMEDICA-2742 - Motivos de Bloqueio
    30/04/2020  Anderson Silva DDMEDICA-2777 - Não permitir venda servcon sem condição comercial
    05/05/2020  Anderson Silva DDMEDICA-2827 - Atualização da Transportadora da Frequência de Entrega se vier zero do Força de Vendas
    15/05/2020  Anderson Silva DDMEDICA-2832 - Regra Específica para Cálculo ST Pacote
    06/03/2020  Anderson Silva DDMEDICA-2961 - Arredondamento DESONERAÇÃO
    28/05/2020  Anderson Silva DDMEDICA-3017 - Parâmetro para não validar prazo médio do pedido no OL e PE
    05/06/2020  Anderson Silva DDMEDICA-3001 - Opção para Desconsiderar Repasse na Base do Desconto Isenção ICMS
    02/07/2020  Anderson Silva DDMEDICA-3238 - CloseUp validar duplicidade pelo NUMPEDVAN + NUMPEDCLI
    22/07/2020  Jorge Humberto DDMEDICA-3382 - Correção na integradora_med para que a validação de restrição também ocorra para as origens de venda "F","W" e o valor atendido do pedido
    29/07/2020  Anderson Silva DDMEDICA-3464 - Restrição por Valor Mínimo 391
    31/07/2020  Anderson Silva DDMEDICA-3511 - NVL no Repasse ST Maranhão
    04/08/2020  Anderson Silva DDMEDICA-3542 - Restrição por Valor Mínimo 391 por item MED
    05/08/2020  Anderson Silva DDMEDICA-3551 - Log do Limite de Crédito
    17/08/2020  Anderson Silva DDMEDICA-3639 - Simples Nacional ST Fonte na Integradora
    21/08/2020  Anderson Silva DDMEDICA-3727 - ST Bonificações não recalcular se Tributação Pacote
    15/09/2020  Anderson Silva DDMEDICA-4013 - Filtro de Tipo de Venda e Multi-seleção na Rebaixa de CMV
    29/09/2020  Jorge Humberto DDMEDICA-4173 - Utilizar código do emitente para importações de pedidos E-Commerce regras de excessão med
    29/09/2020  Anderson Silva DDMEDICA-4177 - Replicar o campo BONIFIC para a PCPEDI
    01/10/2020  Anderson Silva DDMEDICA-4225 - Controle de Versionamento - 30.1.1
    01/10/2020  Anderson Silva DDMEDICA-4170 - Gravação do STPBASERCA em processo específico Cliente Pacote - 30.1.2
    02/10/2020  Anderson Silva DDMEDICA-4240 - RCA por Linha do E-Commerce - 30.1.3
    07/10/2020  Anderson Silva DDMEDICA-4289 - Isenção ST não participa da Regra de Arredondamento do ICMS Isenção - 30.1.4
    16/10/2020  Anderson Silva DDMEDICA-4418 - Agregar o Desconto de Bonifioação da Linha da Condição de Venda com a Promoção de Preço Fixo - 30.1.5
    30/10/2020  Anderson Silva DDMEDICA-4614 - TRIM() no NUMPEDCLI e NUMPEDVANXML na PCPEDC - 30.1.6
    30/10/2020  Anderson Silva DDMEDICA-4610 - Correção Conversão Numérico Parâmetro PERMAXDESCVENDA - 30.1.7
    08/12/2020  Anderson Silva DDMEDICA-5009 - Ler Verba Rebaixa CMV da Promoção
    18/12/2020  Anderson Silva DDMEDICA-5086 - Gravar campo Classe Venda do Produto - 30.1.8
    25/01/2021  Anderson Silva DDMEDICA-5411 - Limitar o NUMPEDVANXML a 15 Digitos na PCPEDC - 30.1.9
    19/03/2021  Anderson Silva DDMEDICA-6036 - Limite Sazonal da Rotina 3321 e garantir Código da Distribuição do Pedido conforme Produto - 30.1.10
    25/03/2021  Anderson Silva DDMEDICA-6049 - Arredondamento diferenciado com ST na Precificação - 30.1.11

    04/05/2021  Anderson Silva DDMEDICA-6201 - Intermediador na NFe - 30.1.12

    06/05/2021  Anderson Silva DDMEDICA-6249 - Plano de Pagamento do Item na Validação da Promoção com Grupo Faturamento
    06/05/2021  Anderson Silva DDMEDICA-6533 - Faturamento Integral no Layout Customizado
    25/05/2020  Anderson Silva DDMEDICA-6666   Recalculo ST Itens Bonificados inseridos pelo Brinde Express na INTEGRADORA_MED    
    15/06/2021  Anderson Silva DDMEDICA-6841 - Cálculo Promoção Markup por Faixa de Quantidade e Preço Fixo no Força de Vendas
    21/06/2021  Anderson Silva DDMEDICA-6837 - Promoção de Markup por Faixa de Quantidade e Preço Fixo no OL e PE
    29/06/2021  Anderson Silva DDMEDICA-6900 - Opção de Custo da Promoção de Markup
    01/07/2021  Anderson Silva DDMEDICA-6929   Ignorar Acréscimo Pessoa Fiscica da Tributação
    30/07/2021  Anderson Silva DDMEDICA-7182 - Gravar o Plano de Pagamento da Linha de Prazo na PCPEDI
    10/08/2021  Anderson Silva DDMEDICA-7302 - Não permitir percom nulo na pcorcavendai
    20/08/2021  Jorge Humberto DDMEDICA-7385 - Correção na integradora_med para que a validação de restrição também ocorra para as origens de venda "F","W" e o valor atendido do pedido
    01/09/2021  Anderson Silva - DDMEDICA-7478 - Filtro pelo coddesconto selecionado do FV
    17/09/2021  Anderson Silva DDMEDICA-7609 - Correção da Soma de ST do PBASERCA
    22/09/2021  Andersom Silva DDMEDICA-7584 - Removido Arredondamento do Desconto de Redução PIS e COFINS para ficar igual à 2316
    28/08/2021  Anderson Silva DDMEDICA-7688 - Não permitir vender acima do preço fábrica
    30/09/2021  Anderson Silva DDMEDICA-7697   ST Recolhido anteriormente
    14/10/2021  Anderson Silva DDVENDAS-31111 - Inclusão Tipo 9 nos Tipos de Venda Válidos
    18/10/2021  Anderson Silva DDVENDAS-31163 - Garantir a atualização da Posição do Pedido
    21/10/2021  Anderson Silva DDVENDAS-31316  ST Antecipado não somar ao CMV
    29/10/2021  Anderson Silva DDVENDAS-31504 - Parametrizações do SERVCON
    05/11/2021  Anderson Silva DDVENDAS-31641 - Correção Validação Preço Acima do Fábrica
    12/11/2021  Anderson Silva DDVENDAS-31792 - Adequação Multi-Seleção da 307
    09/02/2022  Anderson Silva DDVENDAS-33476 - Pesquisa da 561 por Grupo de Produto
    21/02/2022  Anderson Silva DDVENDAS-33718 - Utilizar Endereço Entrega
    17/02/2022  Anderson Silva DDVENDAS-33713 - Conversão Preço conforme Parâmetro da Integradora
    09/03/2022  Anderson Silva DDVENDAS-33961 - Importação Ofertas Hypera
    07/04/2022  Anderson Silva DDVENDAS-34832 - Log da Posição do Pedido
    19/04/2022  Anderson Silva DDVENDAS-35050 - Ajuste para melhorar as dependências da 2300 centralização alguns procedimentos na PKG_MEDICAMENTOS
    25/04/2022  Anderson Silva DDVENDAS-35125 - Inclusão de Dependências para Melhoria Referências Externas
    05/05/2022  Anderson Silva DDVENDAS-35272 - Priorização da Promoção da Oferta
    25/05/2022  Anderson Silva DDVENDAS-35620 - Correção Validação Promoção de Desconto ao receber a Promoção no Item
    30/05/2022  Anderson Silva DDVENDAS-35778  Regra de Alteração do Desconto
    02/06/2022  Cassio Pardim  DDVENDAS-35581 - Utilização do campo PERDESCBOLETO sem a necessidade de gerar um CODPROMOCAOMED para o item do pedido
    02/06/2022  Anderson Silva DDVENDAS-35830 - Exceções ABCFARMA/CMED
	20/06/2022  Cassio Pardim  DDVENDAS-36173 - Ajuste para validar o campo PERDESCBOLETO
    18/08/2022  Anderson Silva DDVENDAS-37313 - Sobreposição do Bloqueio por Alvará Vencido
    29/09/2022  Cleber Vicente DDVENDAS-37499 - Bloquear Pedidos Duplicados Durante um Determinado Tempo(dia/hora/mint)	
    01/11/2022  Anderson Silva DDVENDAS-38483 - Quebra de Pedidos do Força de Vendas
    02/03/2022  Anderson Silva DDVENDAS-40171 - Grupo de Comissão no SERVCON
  */
  -- Registro referente ao cabecalho do pedido.
  type t_cabped is record(
    codcli                     pcclient.codcli%type,
    cgccli                     pcclient.cgcent%type,
    codcob                     pcpedc.codcob%type,
    codfilial                  pcpedc.codfilial%type,
    codplpag                   pcpedc.codplpag%type,
    codusur                    pcpedc.codusur%type,
    condvenda                  pcpedc.condvenda%type,
    DATA                       pcpedc.DATA%type,
    dtentrega                  pcpedc.dtentrega%type,
    dtfat                      pcpedc.dtfat%type,
    numcar                     pcpedc.numcar%type,
    numitens                   pcpedc.numitens%type,
    numped                     pcpedc.numped%type,
    numpedcli                  pcpedc.numpedcli%type,
    numpedrca                  pcpedc.numpedrca%type,
    obs                        pcpedc.obs%type,
    obs1                       pcpedc.obs1%type,
    obs2                       pcpedc.obs2%type,
    obsentrega1                pcpedc.obsentrega1%type,
    obsentrega2                pcpedc.obsentrega2%type,
    obsentrega3                pcpedc.obsentrega3%type,
    obsentrega4                pcpedc.obsentrega4%type,
    percvenda                  pcpedc.percvenda%type,
    posicao                    pcpedc.posicao%type,
    origemped                  pcpedc.origemped%type,
    dtaberturapedpalm          pcpedc.dtaberturapedpalm%type,
    dtfechamentopedpalm        pcpedc.dtfechamentopedpalm%type,
    codfilialnf                pcpedc.codfilialnf%type,
    numpedorig                 pcpedc.numped%type,
    pedcomp                    varchar2(1),
    multquantidade             number,
    usacredrca                 pcpedc.usacredrca%type,
    usadebcredrca              pcpedc.usadebcredrca%type,
    bonificaltdebcredrca       pcpedc.bonificaltdebcredrca%type,
    trocaaltdebcredrca         pcpedc.trocaaltdebcredrca%type,
    crmaltdebcredrca           pcpedc.crmaltdebcredrca%type,
    brokeraltdebcredrca        pcpedc.brokeraltdebcredrca%type,
    tipomovccrca               pcpedc.tipomovccrca%type,
    codfilialretira            pcpedc.codfilial%type,
    vlfrete                    pcpedc.vlfrete%type,
    fretedespacho              pcpedc.fretedespacho%type,
    freteredespacho            pcpedc.freteredespacho%type,
    codfornecfrete             pcpedc.codfornecfrete%type,
    parcela1                   pcplpag.prazo1%type,
    parcela2                   pcplpag.prazo2%type,
    parcela3                   pcplpag.prazo3%type,
    parcela4                   pcplpag.prazo4%type,
    parcela5                   pcplpag.prazo5%type,
    parcela6                   pcplpag.prazo6%type,
    parcela7                   pcplpag.prazo7%type,
    parcela8                   pcplpag.prazo8%type,
    parcela9                   pcplpag.prazo9%type,
    parcela10                  pcplpag.prazo10%type,
    parcela11                  pcplpag.prazo11%type,
    parcela12                  pcplpag.prazo12%type,
    prazomedio                 pcpedc.prazomedio%type,
    codclinf                   pcpedc.codclinf%type,
    tipodocumento              pcpedc.tipodocumento%type,
    contaordem                 pcpedc.contaordem%type,
    codmotivo                  pcpedc.codmotivo%type,
    motivoposicao              pcpedc.motivoposicao%type,
    log                        pcpedc.log%type,
    codclitv8                  pcpedc.codclitv8%type,
    codplpagetico              pcpedc.codplpagetico%type,
    codplpaggenerico           pcpedc.codplpaggenerico%type,
    tipofv                     pcpedcfv.tipofv%type,
    integradora                pcpedretorno.integradora%type,
    codcondicaovenda           pcpedretorno.codcondicaovenda%type,
    numpedvan                  pcpedretorno.numpedvan%type,
    tipovalidadescedimaior     pcintegradora.tipovalidadescedimaior%type,
    tipovalidadescedimenor     pcintegradora.tipovalidadescedimenor%type,
    tipovalidaprecoedimaior    pcintegradora.tipovalidaprecoedimaior%type,
    tipovalidaprecoedimenor    pcintegradora.tipovalidaprecoedimenor%type,
    utilizaregradesc100        pcintegradora.utilizaregradesc100%type,
    codmotivonaoatend          pcpedcfv.codmotivonaoatend%type,
    vlsaldodisponivelcli       pcpedretorno.vllimitecredcli%type,
    tipoprioridadeentrega      pcpedc.tipoprioridadeentrega%type,
    localdesembaraco           pcpedc.localdesembaraco%type,
    ufdesembaraco              pcpedc.ufdesembaraco%type,
    percplpag                  number,
    gerapedbloq                pcintegradora.gerapedbloq%type,
    geroubrinde                pcpedcfv.geroubrinde%type,
    numpedtv1                  pcpedcfv.numpedtv1%type,
    numquebra                  pcpedretorno.numquebra%type, -- 156777
    layout                     pcintegradora.layout%type, -- 158742
    codigoprojeto              pcpedretorno.codigoprojeto%type, -- 158742
    vlmaxaceitedifpreco        number(18,6), -- 158047
    agrupamento                varchar2(1),
    codbnf                     pcpedc.codbnf%type,
    custobonificacao           pcpedc.custobonificacao%type,
    codfornecbonific           pcpedc.codfornecbonific%type,
    vlentrada                  pcpedc.vlentrada%type,
    origempreco                pcintegradora.origempreco%type,
    orcamento                  varchar2(1),
    numpedvanxml               pcpedc.numpedvanxml%type,
    codendentcli               pcpedc.codendentcli%type,
    codclirecebedor            pcpedc.codclirecebedor%type,
    numregiaobroker            pcpedcfv.numregiaobroker%type,
    numtabela                  pcpedc.numtabela%type,
    vbexisteitemcomdesc        boolean,
    codusur2                   pcpedc.codusur2%type,
    codusur3                   pcpedc.codusur3%type,
    codusur4                   pcpedc.codusur4%type,
    consideracalcgiromedic     pcintegradora.consideracalcgiromedic%type, --201059
    valido                     boolean,
    codacordoparceria          pcpedc.codacordoparceria%type,
    geracp                     pcpedc.geracp%type,
    usacomissaointegradora     pcintegradora.usacomissaointegradora%type, --HIS.00490.2014
    percom                     pcintegradora.percom%type,
    aplicaracrescimopolitica   pcintegradora.aplicaracrescimopolitica%type,
    aplicardescptabelatribut   pcintegradora.aplicardescptabelatribut%type,
    integracaopedoperlog       varchar2(1),
    faturamentointegral        pcpedretorno.faturamentointegral%type,
    somastpvenda               pcintegradora.somastpvenda%type,
    pedidoecommerce            varchar2(1),
    codpromocaomed             pcpedcfv.codpromocaomed%type,
    gravarpedidocomobloqueado  pcpedcfv.gravarpedidocomobloqueado%type,
    tipocriticaclientebloqmed  pcintegradora.tipocriticaclientebloqmed%type, -- HIS.03472.2015
    aplicataxaplpagprecofv     varchar(1),
    -- INICIO: HIS.04557.2015 - ICMS Partilha
    precocompartilha           pcpedcfv.precocompartilha%TYPE,
    -- FIM: HIS.04557.2015 - ICMS Partilha
    usabcrultent               pcintegradora.usabcrultent%TYPE, -- HIS.00211.2016
    restringirpromocaomed      pcpedcfv.restringirpromocaomed%TYPE,
    tipodeforigempedidooperlog varchar2(1), -- HIS.01025.2015
    origempedidooperlog        varchar2(1), -- HIS.01025.2015
    pedidoJaExistente          varchar2(1), -- 2438.022821.2017
    msgPedidoJaExistente       varchar2(200), -- 2438.022821.2017
    arquivoped                 pcpedretorno.arquivoped%type, -- MED-1468
    prazo_pcpedretorno         pcpedretorno.prazo%type, -- MED-1503
    tipoprazo_pcpedretorno     pcpedretorno.tipoprazo%type, -- MED-1503
    codigoprazo_pcpedretorno   pcpedretorno.codprazo%type, -- MED-1503
    codcli_pcpedretorno        pcpedretorno.codcli%type, -- MED-1503
    logprocmed                 CLOB, -- MED-1499
    jsonprocmed                varchar2(32000), -- MED-1499
    vlfreteoutrasdesp          number,
    errolockestoque            varchar2(1),
    margempedido               number,          -- MED-2079
    margemminaplicada          number,          -- MED-2079
    existemprodutosrepetidos   varchar2(1),      -- DDMEDICA-198
    aplicarperredcomiss        PCPEDCFV.APLICARPERREDCOMISS%type,
    codvendedorpedol           PCPEDRETORNO.CODVENDEDORPEDOL%type,
    codemitente                PCPEDCFV.CODEMITENTE%TYPE --DDMEDICA-4173
   ,descintermediador          PCPEDCFV.DESCINTERMEDIADOR%TYPE -- DDMEDICA-6201  
   ,cnpjintermediador          PCPEDCFV.CNPJINTERMEDIADOR%TYPE -- DDMEDICA-6201  
   ,totunidades                number -- DDMEDICA-6533
    );

  type t_itemped is record(
    codprod                    pcpedi.codprod%type,
    numpedrca                  pcpedc.numpedrca%type,
    numseq                     pcpedi.numseq%type,
    percom                     pcpedi.percom%type,
    perdesc                    pcpedi.perdesc%type,
    pvenda                     number, -- DDMEDICA-6049 -- pcpedi.pvenda%type,
    qt                         pcpedi.qt%type,
    st                         pcpedi.st%type,
    stclientegnre              pcpedi.stclientegnre%type,
    vlcustocont                pcpedi.vlcustocont%type,
    vlcustofin                 pcpedi.vlcustofin%type,
    vlcustoreal                pcpedi.vlcustoreal%type,
    vlcustorep                 pcpedi.vlcustorep%type,
    pbaserca                   number, -- DDMEDICA-6049 -- pcpedi.pbaserca%type,
    pvendabase                 pcpedi.pvendabase%type,
    iva                        pcpedi.iva%type,
    pauta                      pcpedi.pauta%type,
    aliqicms1                  pcpedi.aliqicms1%type,
    aliqicms2                  pcpedi.aliqicms2%type,
    percbaseredst              pcpedi.percbaseredst%type,
    percbaseredstfonte         pcpedi.percbaseredstfonte%type,
    baseicst                   pcpedi.baseicst%type,
    perfretecmv                pcpedi.perfretecmv%type,
    custofinest                pcpedi.custofinest%type,
    txvenda                    pcpedi.txvenda%type,
    perdesccusto               pcpedi.perdesccusto%type,
    codicmtab                  pcpedi.codicmtab%type,
    vldesccustocmv             pcpedi.vldesccustocmv%type,
    letracomiss                pcpedi.letracomiss%type,
    vlipi                      pcpedi.vlipi%type,
    percipi                    pcpedi.percipi%type,
    vldescsuframa              pcpedi.vldescsuframa%type,
    vldescicmisencao           pcpedi.vldescicmisencao%type,
    perdescisentoicms          pcpedi.perdescisentoicms%type,
    vlverbacmv                 pcpedi.vlverbacmv%type,
    vlverbacmvcli              pcpedi.vlverbacmvcli%type, -- MED-1822
    numpedorig                 pcpedc.numped%type,
    pvenda1                    pcpedi.pvenda1%type,
    codauxiliar                pcpedi.codauxiliar%type,
    percdescpis                pcpedi.percdescpis%type,
    percdesccofins             pcpedi.percdesccofins%type,
    vldescreducaopis           pcpedi.vldescreducaopis%type,
    vldescreducaocofins        pcpedi.vldescreducaocofins%type,
    cgccli                     pcclient.cgcent%type,
    codcli                     pcclient.codcli%type,
    codusur                    pcpedi.codusur%type,
    dtaberturapedpalm          pcpedc.dtaberturapedpalm%type,
    codfilialretira            pcpedi.codfilialretira%type,
    qtpecas                    pcpedi.qtpecas%type,
    qtcx                       pcpedi.qtcx%type,
    vlrepasse                  pcpedi.vlrepasse%type,
    vloutros                   pcpedi.vloutros%type,
    vlbonific                  pcpedi.vlbonific%type,
    perbonific                 pcpedi.perbonific%type,
    perdesccom                 pcpedi.perdesccom%type,
    vldesccom                  pcpedi.vldesccom%type,
    unidadevenda               varchar2(2),
    cesta                      varchar2(1),
    vlredpvendasimplesna       pcpedi.vlredpvendasimplesna%type,
    vlredcmvsimplesnac         pcpedi.vlredcmvsimplesnac%type,
    poriginal                  pcpedi.poriginal%type,
    precomaxconsum             pcpedi.precomaxconsum%type,
    descprecofab               pcpedi.descprecofab%type,
    codplpag                   pcplpag.codplpag%type,
    tipovenda                  pcplpag.tipovenda%type,
    pertxfim                   pcplpag.pertxfim%type,
    numdias                    pcplpag.numdias%type,
    numpr                      pcplpag.numpr%type,
    tiporestricao              pcplpag.tiporestricao%type,
    codrestricao               pcplpag.codrestricao%type,
    prioritaria                varchar2(1),
    politicaprioritaria        pcpedi.politicaprioritaria%type,
    codcombo                   pcpedi.codcombo%type,
    valido                     boolean,
    pvendaanterior             pcpedi.pvendaanterior%type,
    perdescboleto              pcpedi.perdescboleto%type,
    perdescfin                 pcpedi.perdescfin%type,
    percdescedi                pcpedi.percdescindustria%type,
    percdescindustria          pcpedi.percdescindustria%type,
    precoedi                   pcpedifv.pvenda%type,
    codmotivonaoatend          pcpedcfv.codmotivonaoatend%type,
    APLICADESCONTOSIMPLES      pcprecoprom.aplicadescontosimples%type,
    percdescboleto             pcpedi.perdescboleto%type,
    vldescboleto               pcpedi.vldescboleto%type,
    coddesconto                pcdesconto.coddesconto%type ,
    geragnre_cnpjcliente       pcpedi.geragnre_cnpjcliente%type,
    percom2                    pcpedi.percom2%type,
    percom3                    pcpedi.percom3%type,
    percom4                    pcpedi.percom4%type,
    aplicoupromocao            varchar2(1),
    codpromocaomed             pcpedi.codpromocaomed%type,
    iniciointervalodescquant   pcpedi.iniciointervalodescquant%type,
    regimeespisenstfonte       pcpedi.regimeespisenstfonte%type,
    somoustptabela             varchar2(1),
    -- INICIO: HIS.04557.2015 - ICMS Partilha
    VLBASEPARTDEST             pcpedifv.VLBASEPARTDEST%TYPE,
    ALIQFCP                    pcpedifv.aliqfcp%type,
    ALIQINTERNADEST            pcpedifv.ALIQINTERNADEST%type,
    VLFCPPART                    pcpedifv.VLFCPPART%type,
    VLICMSPARTDEST             pcpedifv.VLICMSPARTDEST%type,
    VLICMSPART                 pcpedifv.VLICMSPART%type,
    VLICMSDIFALIQPART          pcpedifv.VLICMSDIFALIQPART%type,
    PERCBASEREDPART            pcpedifv.PERCBASEREDPART%type,
    PERCPROVPART                       pcpedifv.PERCPROVPART%type,
    vlicmspartrem              pcpedifv.vlicmspartrem%type,
    -- FIM: HIS.04557.2015 - ICMS Partilha
    logprocmed                 CLOB,
    percdescbaserca            pcpedi.percdescbaserca%type,
    tipocomissaomed            pcpedi.tipocomissaomed%type, -- 5047.047570.2016
    percdescsimplesnac         number, -- PCNIL - Para uso no cálculo da redução do CMV no final do processo
    valordescsimplesnac        number, -- PCNIL - Para gravação na PCPEDI no final do processo
    codfiscal                  pcpedi.codfiscal%type, -- HIS.03261.2016
    sittribut                  pcpedi.sittribut%type, -- HIS.03261.2016
    prodimportadopeps          pcpedi.prodimportadopeps%type, -- HIS.02787.2016
    numtransentpeps            pcpedi.numtransentpeps%type,   -- HIS.02787.2016
    codlinhaprazo              pcpedi.codlinhaprazo%type, -- 4415.012539.2017
    codplpagLinhaPrazo         pcpedi.codplpag%type,      -- 4415.012539.2017
    codusurLinhaPrazo          pcpedi.codusur%type,       -- 4415.012539.2017
    observacaostfonte          pcpedi.observacaostfonte%type,  -- HIS.03377.2017
    indescalarelevante         pcpedi.indescalarelevante%type, -- HIS.03377.2017
    cnpjfabricante             pcpedi.cnpjfabricante%type,     -- HIS.03377.2017
    fabricante                 pcpedi.fabricante%type,         -- HIS.03377.2017
    percacrescoperlog          pcpedi.percacrescoperlog%type,  -- HIS.00262.2018
    vlacrescoperlog            pcpedi.vlacrescoperlog%type,    -- HIS.00262.2018
    codacordosistoperlog       pcpedi.codacordosistoperlog%type,
    -- HIS.01889.2017 - Atualização da Variável de Priorização de Comissão do Acordo de Parceria
    priorizacomissacordoparceria varchar2(1),
    percomacordoparceria         number,
    jsonprocmed                  varchar2(32000), -- MED-1499
    VLBASEFCPICMS                PCPEDI.VLBASEFCPICMS%TYPE,      -- HIS.04200.2017
    VLBASEFCPST                  PCPEDI.VLBASEFCPST%TYPE,        -- HIS.04200.2017
    VLBCFCPSTRET                 PCPEDI.VLBCFCPSTRET%TYPE,       -- HIS.04200.2017
    PERFCPSTRET                  PCPEDI.PERFCPSTRET%TYPE,        -- HIS.04200.2017
    VLFCPSTRET                   PCPEDI.VLFCPSTRET%TYPE,         -- HIS.04200.2017
    PERFCPSN                     PCPEDI.PERFCPSN%TYPE,           -- HIS.04200.2017
    VLFECP                       PCPEDI.VLFECP%TYPE,             -- HIS.04200.2017
    VLACRESCIMOFUNCEP            PCPEDI.VLACRESCIMOFUNCEP%TYPE,  -- HIS.04200.2017
    PERACRESCIMOFUNCEP           PCPEDI.PERACRESCIMOFUNCEP%TYPE, -- HIS.04200.2017
    ALIQICMSFECP                 PCPEDI.ALIQICMSFECP%TYPE,       -- HIS.04200.2017
    VLCREDFCPICMSSN              PCPEDI.VLCREDFCPICMSSN%TYPE,    -- HIS.04200.2017
    CODCONFIGFUNCEPMED           PCPEDI.CODCONFIGFUNCEPMED%TYPE, -- HIS.04200.2017
    percverbacmvcli              number, -- MED-1822
    bonific                      PCPEDI.BONIFIC%TYPE, -- MED-2521
    numseqifv                    PCPEDIFV.NUMSEQ%TYPE, -- DDMEDICA-198
    PVENDA1BASEPROMOMARKUP       NUMBER, -- DDMEDICA-683
    PERREDCOMISS                 PCPEDIFV.PERREDCOMISS%TYPE,
    numlotepromocaomed           PCPEDIFV.NUMLOTEPROMOCAOMED%TYPE,
    codusurlinha                 PCPEDI.CODUSUR%TYPE,
    codmotivoposicaomed          PCPEDI.CODMOTIVOPOSICAOMED%TYPE, -- DDMEDICA-2742
    motivoposicaomed             PCPEDI.MOTIVOPOSICAOMED%TYPE,    -- DDMEDICA-2742
    codmotivoposicaomed2         PCPEDI.CODMOTIVOPOSICAOMED%TYPE, -- DDMEDICA-2742
    motivoposicaomed2            PCPEDI.MOTIVOPOSICAOMED%TYPE,    -- DDMEDICA-2742
    codmotivoposicaomed3         PCPEDI.CODMOTIVOPOSICAOMED%TYPE, -- DDMEDICA-2742
    motivoposicaomed3            PCPEDI.MOTIVOPOSICAOMED%TYPE,    -- DDMEDICA-2742
    codmotivoposicaomed4         PCPEDI.CODMOTIVOPOSICAOMED%TYPE, -- DDMEDICA-2742
    motivoposicaomed4            PCPEDI.MOTIVOPOSICAOMED%TYPE,    -- DDMEDICA-2742
    tiporedsimplesnac            VARCHAR2(255),                   -- DDMEDICA-2742
    numverbacampanha             PCPEDI.NUMVERBACAMPANHA%TYPE,    -- DDMEDICA-5009
    perccustfornec               PCPEDI.PERCCUSTFORNEC%TYPE,      -- DDMEDICA-5009
    vldesccmvpromocaomed         PCPEDI.VLDESCCMVPROMOCAOMED%TYPE,-- DDMEDICA-5009
    classevenda                  PCPEDI.CLASSEVENDA%type,
    percmarkupmed                NUMBER,                          -- DDMEDICA-6900
    tipocustomarkupmed           VARCHAR2(255),                   -- DDMEDICA-6900
    customarkupmed               NUMBER,                          -- DDMEDICA-6900
    coddescontomed               NUMBER,                          -- DDMEDICA-7478
    bcstretanterior              PCPEDI.BCSTRETANTERIOR%TYPE,          -- DDMEDICA-7697
    vlicmssubstitutoanterior     PCPEDI.VLICMSSUBSTITUTOANTERIOR%TYPE, -- DDMEDICA-7697
    vlicmsstretanterior          PCPEDI.VLICMSSTRETANTERIOR%TYPE,      -- DDMEDICA-7697
    pmpfmedicamento              PCPEDI.PMPFMEDICAMENTO%TYPE,          -- DDMEDICA-7697
    restringirpromocaomed        VARCHAR2(1),                           -- DDVENDAS-33961
   	usacashback                  PCPEDI.USACASHBACK%TYPE,    ---DDVENDAS-35840
    numitemped                   PCPEDI.NUMITEMPED%TYPE -- DDVENDAS-44985
    );

  -- HIS.03536.2016
  type t_comboped is record(
    numpedrca                  pcpedcombopromocaomedfv.numpedrca%type,
    dtaberturapedpalm          pcpedcombopromocaomedfv.dtaberturapedpalm%type,
    cgccli                     pcpedcombopromocaomedfv.cgccli%type,
    codusur                    pcpedcombopromocaomedfv.codusur%type,
    codpromocaomed             pcpedcombopromocaomedfv.codpromocaomed%type,
    qtcombo                    pcpedcombopromocaomedfv.qtcombo%type,
    rejeitapedcomboinvalido    pcpedcombopromocaomedfv.rejeitapedcomboinvalido%type,
    observacao_pc              pcpedcombopromocaomedfv.observacao_pc%type
    );

  type t_clientepedido is record(
    bloqueio                   pcclient.bloqueio%type,
    calculast                  pcclient.calculast%type,
    cliente                    pcclient.cliente%type,
    codcli                     pcclient.codcli%type,
    codcliprinc                pcclient.codcliprinc%type,
    codcob                     pcclient.codcob%type,
    codfilialnf                pcclient.codfilialnf%type,
    codplpag                   pcclient.codplpag%type,
    codpraca                   pcclient.codpraca%type,
    condvenda1                 pcclient.condvenda1%type,
    condvenda2                 pcclient.condvenda2%type,
    condvenda3                 pcclient.condvenda3%type,
    condvenda4                 pcclient.condvenda4%type,
    condvenda5                 pcclient.condvenda5%type,
    condvenda6                 pcclient.condvenda6%type,
    condvenda10                pcclient.condvenda10%type,
    descproduto                pcclient.descproduto%type,
    estent                     pcclient.estent%type,
    ieent                      pcclient.ieent%type,
    limcred                    pcclient.limcred%type,
    numdias                    pcplpag.numdias%type,
    percomcli                  pcclient.percomcli%type,
    perdesc                    pcclient.perdesc%type,
    prazoadicional             pcclient.prazoadicional%type,
    tipofj                     pcclient.tipofj%type,
    numregiao                  pcpraca.numregiao%type,
    codatv1                    pcclient.codatv1%type,
    validamaxvendapf           pcclient.validamaxvendapf%type,
    consumidorfinal            pcclient.consumidorfinal%type,
    clientefontest             pcclient.clientefontest%type,
    isentoicms                 pcclient.isentoicms%type,
    utilizaiesimplificada      pcclient.utilizaiesimplificada%type,
    tipoempresa                pcclient.tipoempresa%type,
    contribuinte               pcclient.contribuinte%type,
    classevenda                pcclient.classevenda%type,
    isentoipi                  pcclient.isentoipi%type,
    suframa                    pcclient.sulframa%type,
    tipodescisencao            pcclient.tipodescisencao%type,
    perdescisentoicms          pcclient.perdescisentoicms%type,
    usaivafontediferenciado    pcclient.usaivafontediferenciado%type,
    ivafonte                   pcclient.ivafonte%type,
    orgaopub                   pcclient.orgaopub%type,
    orgaopubfederal            pcclient.orgaopubfederal%type,
    cepent                     pcclient.cepent%type,
    municent                   pcclient.municent%type,
    enderent                   pcclient.enderent%type,
    cgcent                     pcclient.cgcent%type,
    origempreco                pcclient.origempreco%type,
    repasse                    pcclient.repasse%type,
    dtvencalvara               pcclient.dtvencalvara%type,
    dtvencalvarafunc           pcclient.dtvencalvarafunc%type,
    dtvencalvaraanvisa         pcclient.dtvencalvaraanvisa%type,
    dtvenccrf                  pcclient.dtvenccrf%type ,
    simplesnacional            pcclient.simplesnacional%type,
    validarmultiplovenda       pcclient.validarmultiplovenda%type,
    clientemonitorado          pcclient.clientemonitorado%type,
    codrede                    pcclient.codrede%type ,
    validarcampanhabrinde      pcclient.validarcampanhabrinde%type,
    utilizaplpagmedicamento    pcclient.utilizaplpagmedicamento%type,
    codplpagetico              pcclient.codplpagetico%type,
    codplpaggenerico           pcclient.codplpaggenerico%type,
    usadescfinseparadodesccom  pcclient.usadescfinseparadodesccom%type,
    tipocustotransf            pcclient.tipocustotransf%type,
    peracrestransf             pcclient.peracrestransf%type,
    isencaosuframa             pcclient.isencaosuframa%type,
    tipoclimed                 pcclient.tipoclimed%type ,
    fretedespacho              pcclient.fretedespacho%type ,
    dtvencalvararetinoico      pcclient.dtvencalvararetinoico%type,
    numcrf                     pcclient.numcrf%type,
    numalvara                  pcclient.numalvara%type,
    numalvaraanvisa            pcclient.numalvaraanvisa%type,
    numalvarafunc              pcclient.numalvarafunc%type,
    numalvararetinoico         pcclient.numalvararetinoico%type,
    usadescontoicms            pcclient.usadescontoicms%type,
    aceitavendafracao          pcclient.aceitavendafracao%type,
    bloqueiosefaz              pcclient.bloqueiosefaz%type,
    usadebcredrca              pcclient.usadebcredrca%type,
    codfornecfrete             pcclient.codfornecfrete%type,
    participafarmaciapopular   pcclient.participafarmaciapopular%type
    );


  type t_rca is record(
    bloqueio                   pcusuari.bloqueio%type,
    coddistrib                 pcusuari.coddistrib%type,
    codsupervisor              pcusuari.codsupervisor%type,
    codusur                    pcusuari.codusur%type,
    nome                       pcusuari.nome%type,
    percent2                   pcusuari.percent2%type,
    PERCENT                    pcusuari.PERCENT%type,
    proxnumped                 pcusuari.proxnumped%type,
    tipovend                   pcusuari.tipovend%type,
    permaxvenda                pcusuari.permaxvenda%type,
    usadebcredrca              pcusuari.usadebcredrca%type,
    vlvendaminped              pcusuari.vlvendaminped%type,
    percacresfv                pcusuari.percacresfv%type);

  type t_planodepagamento is record(
    codplpag                   pcplpag.codplpag%type,
    numdias                    pcplpag.numdias%type,
    numitensminimo             pcplpag.numitensminimo%type,
    numpr                      pcplpag.numpr%type,
    obs                        pcplpag.obs%type,
    pertxfim                   pcplpag.pertxfim%type,
    prazo1                     pcplpag.prazo1%type,
    prazo2                     pcplpag.prazo2%type,
    prazo3                     pcplpag.prazo3%type,
    prazo4                     pcplpag.prazo4%type,
    prazo5                     pcplpag.prazo5%type,
    prazo6                     pcplpag.prazo6%type,
    prazo7                     pcplpag.prazo7%type,
    prazo8                     pcplpag.prazo8%type,
    prazo9                     pcplpag.prazo9%type,
    prazo10                    pcplpag.prazo10%type,
    prazo11                    pcplpag.prazo11%type,
    prazo12                    pcplpag.prazo12%type,
    tipoprazo                  pcplpag.tipoprazo%type,
    tipovenda                  pcplpag.tipovenda%type,
    vlminpedido                pcplpag.vlminpedido%type,
    vendabk                    pcplpag.vendabk%type,
    tiporestricao              pcplpag.tiporestricao%type,
    codrestricao               pcplpag.codrestricao%type,
    codfilial                  pcplpag.codfilial%type,
    formaparcelamento          pcplpag.formaparcelamento%type,
    usamultifilial             pcplpag.usamultifilial%type,
    diasminparcela             pcplpag.diasminparcela%type,
    diasmaxparcela             pcplpag.diasmaxparcela%type,
    vlminparcela               pcplpag.vlminparcela%type,
    numparcelas                pcplpag.numparcelas%type,
    tipoentrada                pcplpag.tipoentrada%type,
    margemmin                  pcplpag.margemmin%type,
    descentlimcredcli          pcplpag.descentlimcredcli%type);



  type t_plpagetico is record(
    codplpag                   pcplpag.codplpag%type,
    numdias                    pcplpag.numdias%type,
    numitensminimo             pcplpag.numitensminimo%type,
    numpr                      pcplpag.numpr%type,
    obs                        pcplpag.obs%type,
    pertxfim                   pcplpag.pertxfim%type,
    prazo1                     pcplpag.prazo1%type,
    prazo2                     pcplpag.prazo2%type,
    prazo3                     pcplpag.prazo3%type,
    prazo4                     pcplpag.prazo4%type,
    prazo5                     pcplpag.prazo5%type,
    prazo6                     pcplpag.prazo6%type,
    prazo7                     pcplpag.prazo7%type,
    prazo8                     pcplpag.prazo8%type,
    prazo9                     pcplpag.prazo9%type,
    prazo10                    pcplpag.prazo10%type,
    prazo11                    pcplpag.prazo11%type,
    prazo12                    pcplpag.prazo12%type,
    tipoprazo                  pcplpag.tipoprazo%type,
    tipovenda                  pcplpag.tipovenda%type,
    vlminpedido                pcplpag.vlminpedido%type,
    vendabk                    pcplpag.vendabk%type,
    tiporestricao              pcplpag.tiporestricao%type,
    codrestricao               pcplpag.codrestricao%type,
    codfilial                  pcplpag.codfilial%type,
    formaparcelamento          pcplpag.formaparcelamento%type

    );

  type t_plpaggenerico is record(
    codplpag                   pcplpag.codplpag%type,
    numdias                    pcplpag.numdias%type,
    numitensminimo             pcplpag.numitensminimo%type,
    numpr                      pcplpag.numpr%type,
    obs                        pcplpag.obs%type,
    pertxfim                   pcplpag.pertxfim%type,
    prazo1                     pcplpag.prazo1%type,
    prazo2                     pcplpag.prazo2%type,
    prazo3                     pcplpag.prazo3%type,
    prazo4                     pcplpag.prazo4%type,
    prazo5                     pcplpag.prazo5%type,
    prazo6                     pcplpag.prazo6%type,
    prazo7                     pcplpag.prazo7%type,
    prazo8                     pcplpag.prazo8%type,
    prazo9                     pcplpag.prazo9%type,
    prazo10                    pcplpag.prazo10%type,
    prazo11                    pcplpag.prazo11%type,
    prazo12                    pcplpag.prazo12%type,
    tipoprazo                  pcplpag.tipoprazo%type,
    tipovenda                  pcplpag.tipovenda%type,
    vlminpedido                pcplpag.vlminpedido%type,
    vendabk                    pcplpag.vendabk%type,
    tiporestricao              pcplpag.tiporestricao%type,
    codrestricao               pcplpag.codrestricao%type,
    codfilial                  pcplpag.codfilial%type,
    formaparcelamento          pcplpag.formaparcelamento%type
    );


  type t_regiaocliente is record(
    numregiao                  pcregiao.numregiao%type,
    perfrete                   pcregiao.perfrete%type,
    perfreteterceiros          pcregiao.perfreteterceiros%type,
    perfreteespecial           pcregiao.perfreteespecial%type,
    codestabelecimento         pcregiao.codestabelecimento%type);

  type t_produto is record(
    codcategoria               pcprodut.codcategoria%type,
    codepto                    pcprodut.codepto%type,
    codfornec                  pcprodut.codfornec%type,
    codprod                    pcprodut.codprod%type,
    codsec                     pcprodut.codsec%type,
    descricao                  pcprodut.descricao%type,
    embalagem                  pcprodut.embalagem%type,
    obs                        pcprodut.obs%type,
    obs2                       pcprodut.obs2%type,
    pcomext1                   pcprodut.pcomext1%type,
    pcomint1                   pcprodut.pcomint1%type,
    pcomrep1                   pcprodut.pcomrep1%type,
    pesobruto                  pcprodut.pesobruto%type,
    ptabela                    number,
    qtunit                     pcprodut.qtunit%type,
    volume                     pcprodut.volume%type,
    codprodprinc               pcprodut.codprodprinc%type,
    perindeniz                 pcprodut.perindeniz%type,
    codlinhaprod               pcprodut.codlinhaprod%type,
    coddistrib                 pcprodut.coddistrib%type,
    freteespecial              pcprodut.freteespecial%type,
    classe                     pcprodut.classe%type,
    percipivenda               pcprodut.percipivenda%type,
    prazomediovenda            pcprodut.prazomediovenda%type,
    importado                  pcprodut.importado%type,
    percipivendatab            pcprodut.percipivendatab%type,
    vlpautaipivenda            pcprodut.vlpautaipivenda%type,
    vlpautaipivendatab         pcprodut.vlpautaipivendatab%type,
    vlipiporkgvenda            pcprodut.vlipiporkgvenda%type,
    vlipiporkgvendatab         pcprodut.vlipiporkgvendatab%type,
    prazomaxindenizacao        pcprodut.prazomaxindenizacao%type,
    pesobrutomaster            pcprodut.pesobrutomaster%type,
    pesopeca                   pcprodut.pesopeca%type,
    tipoestoque                pcprodut.tipoestoque%type,
    tipomerc                   pcprodut.tipomerc%type,
    custorep                   pcprodut.custorep%type,
    psicotropico               pcprodut.psicotropico%type,
    percbonificvenda           pcprodut.percbonificvenda%type,
    utilizaprecomaxconsumidor  pcprodut.utilizaprecomaxconsumidor%type,
    precomaxconsum             pcprodut.precomaxconsum%type,
    unidademaster              pcprodut.unidademaster%type,
    multiplo                   pcprodut.multiplo%type,
    checarmultiplovendabnf     pcprodut.checarmultiplovendabnf%type,
    codfilialretira            pcprodut.codfilialretira%type ,
    tipocomissao               pcprodut.tipocomissao%type,
    grupofaturamento            pcprodut.grupofaturamento%type,
    codlinhaprazo              pcprodut.codlinhaprazo%type,
    codsubcategoria            pcprodut.codsubcategoria%type,
    retinoico                  pcprodut.retinoico%type,
    aceitavendafracao          pcprodut.aceitavendafracao%type,
    farmaciapopular            pcprodut.farmaciapopular%type,
    codmarca                   pcprodut.codmarca%type,
    utilizaprecofabrica        pcprodut.utilizaprecofabrica%type,
    classevenda                pcprodut.classevenda%type
   );


  type t_precosetributacao is record(
    aliqicms1                  pctribut.aliqicms1%type,
    aliqicms2                  pctribut.aliqicms2%type,
    codicmtab                  pctribut.codicmtab%type,
    codst                      pctabpr.codst%type,
    custocont                  pcest.custocont%type,
    custofin                   pcest.custofin%type,
    custoreal                  pcest.custoreal%type,
    custorep                   pcest.custorep%type,
    custoultent                pcest.custoultent%type,
    excluido                   pctabpr.excluido%type,
    iva                        pctribut.iva%type,
    pauta                      pctribut.pauta%type,
    peracrescismopf            pctribut.peracrescismopf%type,
    perdescautor               pctabpr.perdescautor%type,
    perdesccusto               pctribut.perdesccusto%type,
    perdescmax                 pctabpr.perdescmax%type,
    perdescmaxesp              pctabpr.perdescmaxesp%type,
    perdesctab                 pctribut.perdestab%type,
    precominimovenda           pctabpr.precominimovenda%type,
    pvenda                     pctabpr.pvenda%type,
    pvenda1                    pctabpr.pvenda1%type,
    pvenda2                    pctabpr.pvenda2%type,
    pvenda3                    pctabpr.pvenda3%type,
    pvenda4                    pctabpr.pvenda4%type,
    pvenda5                    pctabpr.pvenda5%type,
    pvenda6                    pctabpr.pvenda6%type,
    pvenda7                    pctabpr.pvenda7%type,
    qtdescautor                pctabpr.qtdescautor%type,
    aplicaacrescpjisenta       pctribut.aplicaacrescpjisenta%type,
    percbaseredst              pctribut.percbaseredst%type,
    tipocalculognre            pctribut.tipocalculognre%type,
    ivafonte                   pctribut.ivafonte%type,
    aliqicms1fonte             pctribut.aliqicms1fonte%type,
    aliqicms2fonte             pctribut.aliqicms2fonte%type,
    percbaseredstfonte         pctribut.percbaseredstfonte%type,
    percbasered                pctribut.percbasered%type,
    perbaserednrpa             pctribut.perbaserednrpa%type,
    percbaseredconsumidor      pctribut.percbaseredconsumidor%type,
    utilizapercbaseredpf       pctribut.utilizapercbaseredpf%type,
    valorultent                pcest.valorultent%type,
    usavalorultentbasest       pctribut.usavalorultentbasest%type,
    usavalorultentbasest2      pctribut.usavalorultentbasest2%type,
    codicmtabpf                pctribut.codicmtabpf%type,
    perdescsuframa             pctribut.perdescsuframa%type,
    perdescicmisencao          pctribut.perdescicmisencao%type,
    descontafrete              pctabpr.descontafrete%type,
    percdescpis                pctribut.percdescpis%type,
    percdesccofins             pctribut.percdesccofins%type,
    perdescrepasse             pctribut.perdescrepasse%type,
    precomaxconsum             pctabpr.precomaxconsum%type,
    qtunit                     pcembalagem.qtunit%type,
    fatorpreco                 pcembalagem.fatorpreco%TYPE,
    qtminimaatacado            pcembalagem.qtminimaatacado%TYPE,
    pvendaatac                 pcembalagem.pvendaatac%TYPE,
    pvendaemb                  pcembalagem.pvenda%TYPE,
    poferta                    pcembalagem.poferta%TYPE,
    pvendaatac1                pctabpr.pvendaatac1%TYPE,
    pvendaatac2                pctabpr.pvendaatac2%TYPE,
    pvendaatac3                pctabpr.pvendaatac3%TYPE,
    pvendaatac4                pctabpr.pvendaatac4%TYPE,
    pvendaatac5                pctabpr.pvendaatac5%TYPE,
    pvendaatac6                pctabpr.pvendaatac6%TYPE,
    pvendaatac7                pctabpr.pvendaatac7%TYPE,
    dtofertaini                pcembalagem.dtofertaini%TYPE,
    dtofertafim                pcembalagem.dtofertafim%TYPE,
    dtofertaatacini            pcembalagem.dtofertaatacini%TYPE,
    dtofertaatacfim            pcembalagem.dtofertaatacfim%TYPE,
    pofertaatac                pcembalagem.pofertaatac%TYPE,
    mostrarpvendasemst         pctribut.mostrarpvendasemst%type,
    usapmcbasest               pctribut.usapmcbasest%type,
    custonfsemst               pcest.custonfsemst%type,
    percredpvendasimplesnac    pctribut.percredpvendasimplesnac%type,
    vlstultent            pcest.vlstultent%type,
    percdifaliquotas      pctribut.percdifaliquotas%type,
    custonfsemstguiaultent   pcest.custonfsemstguiaultent%type,
    ivaultent                pcest.ivaultent%type,
    aliqicms1ultent          pcest.aliqicms1ultent%type,
    aliqicms2ultent          pcest.aliqicms2ultent%type,
    redbaseivaultent         pcest.redbaseivaultent%type,
    percicmsfretefobstultent pcest.percicmsfretefobstultent%type,
    vlfreteconhecultent      pcest.vlfreteconhecultent%type,
    percaliqextguiaultent    pcest.percaliqextguiaultent%type,
    baseicmsultent           pcest.baseicmsultent%type,
    vlstguiaultent           pcest.vlstguiaultent%type,
    usaisencaoicmsvp         pctribut.usaisencaoicmsvp%type,
    isencaostorgaopub        pctribut.isencaostorgaopub%type,
    pagtonomedocliente       pctribut.pagtonomedocliente%type,
    perdescmaxbalcao         pctabpr.perdescmaxbalcao%type,
    precofab                 pctabpr.precofab%type,
    pcomint1_emb             pcembalagem.pcomint1%type,
    PCOMEXT1_emb             pcembalagem.pcomext1%type,
    PCOMREP1_emb             pcembalagem.pcomrep1%type,
    usavlultentmediobasest   pctribut.usavlultentmediobasest%type,
    vlultentmes              pctabpr.vlultentmes%type,
    usabaseicmsreduzida      pctribut.usabaseicmsreduzida%type,
    usabcrultent             pctribut.usabcrultent%type,
    basebcr                  pcest.basebcr%type,
    stbcr                    pcest.stbcr%type,
    pautafonte               pctribut.pautafonte%type,
    aplicadescisencaomed     pctribut.aplicadescisencaomed%type, --HIS.02613.2014
    usaptabelabasest         pctribut.usaptabelabasest%type,
    RegimeEspIsenStFonte     pctribut.regimeespisenstfonte%type,
    percdescsimplesnac       pctabpr.percdescsimplesnac%type,
    codicmtabinternac        pctribut.codicmtabinternac%type, --HIS.02613.2014
    vlst                     pctabpr.vlst%type, -- MED-1510
    vlipi                    pctabpr.vlipi%type, -- MED-1510
    destacdescicmisencaocomercial pctribut.destacdescicmisencaocomercial%type -- DDMEDICA-3065
  );




  type t_registralog is record(
    numped                     pcpedc.numped%type,
    numpedrca                  pcpedc.numpedrca%type,
    codprod                    pcprodut.codprod%type,
    codauxiliar                pcpedi.codauxiliar%type,
    cgcent                     pcclient.cgcent%type,
    codigocotacao              pccota.codcotacao%type,
    numrecadofv                pcrecfunc.numrecadofv%type,
    numcontagem                pcgondolac.numcontagem%type,
    codusur                    pcpedc.codusur%type,
    data                       date,
    cancelada                  varchar2(1), -- utilizado pela pronta entrega
    tiporeg                    varchar2(2),
    -- 1 = generico / -1 = Clientes /2 = cabecalho / 3 = itens /4 = Contatos/5= PCRECFUN/6 = gondolac/7- gondolai/ 8= Visitas/9 = indenizacao/10= item idenizacao
    -- 11 = pronta entrega /12 = intes pronta entrega
    erro                       varchar2(32767),
    linhareg                   number,
    numseqifv                  number); -- DDMEDICA-198

  type t_registrabloqueio is record(
    numpedrca                  pcpedcfv.numpedrca%type,
    codusur                    pcpedcfv.codusur%type,
    cgccli                     pcpedcfv.cgccli%type,
    dtaberturapedpalm          pcpedcfv.dtaberturapedpalm%type,
    codmotivo                  pcbloqueiospedido.codmotivo%type,
    codmotbloqueio             pcbloqueiospedido.codmotivo%type,
    motivo                     pcbloqueiospedido.motivo%type);

  type t_pccob is record(
    nivelvenda                 pccob.nivelvenda%type,
    prazomaximovenda           pccob.prazomaximovenda%type,
    boleto                     pccob.boleto%type,
    codfilial                  pccob.codfilial%type,
    cartao                     pccob.cartao%type);

  type t_filial is record(
    codigo                       pcfilial.codigo%type,
    uf                           pcfilial.uf%type,
    permitirvendainterestadualpf pcfilial.permitirvendainterestadualpf%type,
    permitirvendaestadualpfcomie pcfilial.permitirvendaestadualpfcomie%type,
    permitirvendaestadualpfsemie pcfilial.permitirvendaestadualpfsemie%type,
    calcestdispcomqtminautoserv  pcfilial.calcestdispcomqtminautoserv%type,
    usaintegracaowms             pcfilial.usaintegracaowms%type,
    tipobroker                   pcfilial.tipobroker%type,
    calcularipivenda             pcfilial.calcularipivenda%type,
    utilizacontrolemedicamentos  varchar2(1),
    broker                       pcfilial.broker%type,
    utilizavendaporembalagem     varchar2(1),
    precoporembalagem            varchar2(1),
    tipoprecificacao             varchar2(1),
    validaalvaraporitem          varchar2(1),
    arredondaqtembalfrios        varchar2(1),
    aceitavendasemestfv          varchar2(1),
    origemcustofilialretira      pcfilial.origemcustofilialretira%type,
    naousarautdebcredpoldesc     varchar2(1),
    aceitadesctmkfv              varchar2(2),
    aceitavendarcasemsaldofv     varchar2(1),
    tipoavaliacaocomissao        pcfilial.tipoavaliacaocomissao%type,
    considerarcomissaozero       pcfilial.considerarcomissaozero%type,
    bloquearpedidosabaixovlminimo varchar2(1),
    tipoimportacaovenda           varchar2(2),
    somacreditocliprincipal       varchar2(1),
    usabnflimitecredito           varchar2(1),
    tipoprazomedicam              varchar2(1),
    vlmaxvendabonificmes          number,
    TipoAplicRepasseFilial        varchar2(2), -- Tarefa 153405
    aceitavendasemdtvencfv        varchar2(2),
    permaxdescvenda               number,
    obrigatoriovinculartv5comtv1  varchar2(1),
    separarprodcomrestricaotransp varchar2(1),
    validarprecovendatv20         varchar2(1),
    vlminvendabkfilial            number(18,6),
    vlminvenda                    number(18,6),
    bloqpedlimcred                varchar2(1),
    numregiaobalcaointer          pcregiao.numregiao%type,
    vlminvendafv                  number(18,6),
    vlminvendabnffv               number(18,6),
    validavlminvendabalcao        varchar2(1),
    basecalcdescfinmed            varchar2(2), -- Tarefa 184043
    informarecebedorvenda         varchar2(1),
    utilizanfe                    varchar2(1),
    usacodclivenda                varchar2(1),
    separarprodcomst              varchar2(1),
    verificaestoquecont           varchar2(1),
    verificabloqueiosefaz         varchar2(1),
    validarclisefaz               varchar2(2),
    reservarestoquetv7            varchar2(2),
    bloqpedabaixomargemfv         varchar2(1),
    validalvaraportipoctlven      varchar2(1), -- HIS.01334.2014
    utilizapmcuf                  varchar2(1),
    utilizapercbonifivendaregiao  varchar2(1),
    calcstpautafarmaciapopular    varchar2(1),
    tipocriticarestricaovendamed  varchar2(2),  -- HIS.05019.2014
    meddifaceiteprecominimofv     number(12,6),
    tipoconfigdebcredrcapromomed  varchar2(1),  -- DESC_BASE_RCA_PRM
    usaregramanterdscpromodescfv  varchar2(1),
    medaplicardescomcliptabela    varchar2(1),  -- HIS.00182.2016
    usadescsimplesnac             varchar2(1),  -- PCNIL
    restringirpromocaofvmed       varchar2(1),  -- 5685.084449.2016
    tributsaidaorigemnacimp       varchar2(1),  -- HIS.02787.2016
    usaracrescdescacordoparceria  varchar2(1),
    r_tipocriticarestricaovendamed number,      -- MED-1499
    ignpoliticaverbacmvecommerce  varchar2(1),  -- MED-1822
    somarrepasseprecoeccommerce   varchar2(1),  -- MED-1822
    tipocalcstfonte               varchar2(1),  -- MED-1822
    usaregraigualarstpbase        varchar2(1),  -- MED-1822
    rejeitaritensforalinhasemest  varchar2(1),
    r_tipoimportacaovenda         number,
    validarmargemminimaolpe       varchar2(200), -- MED-2079
    percmargemminvendamed         varchar2(200), -- MED-2079
    tipovalidmargemminvendamed    varchar2(200), -- MED-2079
    aplicartaxaplpagpedidosol     varchar2(200), -- MED-1613
    regiaodiferenciadatabpr       number,        -- MED-2371
    ignorarpermaxdescvenda        varchar2(200), -- MED-2574
    precosemrepassefv             varchar2(200),
    rejeitarpedpromoinvalidafv    varchar2(200),
    con_utilizacontrolemedicamen  varchar2(200), -- DDMEDICA-2790
    utilizacalculostpacote        varchar2(200),
    ignorarprazomediocliente      varchar2(200), -- DDMEDICA-3017
    medpermitedistribdifrca       varchar2(200), -- DDMEDICA-6036
    usararredondamentodifprecost  varchar2(200), -- DDMEDICA-6049
    gerarbrindepedbonific         varchar2(200), -- DDMEDICA-6666
    custo_prom_markup_st          varchar2(200), -- DDMEDICA-6900
    ignoraracrescimopftribut      varchar2(200), -- DDMEDICA-6929
    permitevendacimapf            varchar2(200), -- DDMEDICA-7688
    utilizatribendent             varchar2(200), -- DDVENDAS-33718    
    vendaporembalagemintegradora  varchar2(200), -- DDVENDAS-33713
    concedenteferta               varchar2(200), -- DDVENDAS-33961
    sobreposicaobloqueioalvara    varchar2(200), -- DDVENDAS-37313
    usarcaclientelinhaporfilialmed varchar2(200)
    );


  type t_origempreco is record(
    numped                     pcorigempreco.numped%type,
    tipobroker                 pcorigempreco.tipobroker%type,
    codprod                    pcorigempreco.codprod%type,
    numseq                     pcorigempreco.numseq%type,
    usatributporuf             pcorigempreco.usatributporuf%type,
    origempreco                pcorigempreco.origempreco%type,
    colunapreco                pcorigempreco.colunapreco%type,
    tipofrete                  pcorigempreco.tipofrete%type,
    percfrete                  pcorigempreco.percfrete%type,
    codautorizacao             pcorigempreco.codautorizacao%type,
    percdescautor              pcorigempreco.percdescautor%type,
    percacrescpf               pcorigempreco.percacrescpf%type,
    percramoativ               pcorigempreco.percramoativ%type,
    tipodescflex               pcorigempreco.tipodescflex%type,
    coddescflex                pcorigempreco.coddescflex%type,
    coddescvolume              pcorigempreco.coddescvolume%type,
    percdescvolume             pcorigempreco.percdescvolume%type,
    coddescptabela             pcorigempreco.coddescptabela%type,
    coddescvolptabela          pcorigempreco.coddescvolptabela%type,
    percdescptabela            pcorigempreco.percdescptabela%type,
    percdescflex               pcorigempreco.percdescflex%type,
    codprecofixo               pcorigempreco.codprecofixo%type,
    fatorpreco                 pcorigempreco.fatorpreco%type,
    poriginal                  pcorigempreco.poriginal%type,
    dtinicioautor              pcorigempreco.dtinicioautor%type,
    dtfimautor                 pcorigempreco.dtfimautor%type,
    dtiniciodescflex           pcorigempreco.dtiniciodescflex%type,
    dtfimdescflex              pcorigempreco.dtfimdescflex%type,
    dtiniciodescvolume         pcorigempreco.dtiniciodescvolume%type,
    dtfimdescvolume            pcorigempreco.dtfimdescvolume%type,
    dtiniciodescptabela        pcorigempreco.dtiniciodescptabela%type,
    dtfimdescptabela           pcorigempreco.dtfimdescptabela%type,
    dtiniciooferta             pcorigempreco.dtiniciooferta%type,
    dtfimoferta                pcorigempreco.dtfimoferta%type,
    percplpag                  pcorigempreco.percplpag%type,
    percacrescbalcao           pcorigempreco.percacrescbalcao%type,
    qtminatacado               pcorigempreco.qtminatacado%type,
    vlst                       pcorigempreco.vlst%type,
    vlipi                      pcorigempreco.vlipi%type,
    vlsuframa                  pcorigempreco.vlsuframa%type,
    vldescicms                 pcorigempreco.vldescicms%type,
    origemped                  pcorigempreco.origemped%type,
    iniciointervalo            pcorigempreco.iniciointervalo%type,
    fimintervalo               pcorigempreco.fimintervalo%type,
    data                       pcorigempreco.data%type,
    codemitente                pcorigempreco.codemitente%type,
    codfilial                  pcorigempreco.codfilial%type,
    codfilialnf                pcorigempreco.codfilialnf%type,
    iniciointervaloautori      pcorigempreco.iniciointervaloautori%type,
    fimintervaloautori         pcorigempreco.fimintervaloautori%type,
    numregiao                  pcorigempreco.numregiao%type,
    percdescpis                pcorigempreco.percdescpis%type,
    percdesccofins             pcorigempreco.percdesccofins%type,
    vldescreducaopis           pcorigempreco.vldescreducaopis%type,
    vldescreducaocofins        pcorigempreco.vldescreducaocofins%type,
    -- INICIO: HIS.04557.2015 - ICMS Partilha
      vlicmspart                 pcorigempreco.vlicmspartilha%type,
    -- FIM: HIS.04557.2015 - ICMS Partilha
    -- HIS.01889.2017 - Atualização da Variável de Priorização de Comissão do Acordo de Parceria
    codacordoparceria          number,
    percdescacordoparceria     number,
    --
    VLFECP                     number,
    -- DDMEDICA-7719
    vlicmsstretanterior        pcorigempreco.vlicmsstretanterior%TYPE,
    --
    valido                     boolean
    );



type t_itenscesta is record(
    numped                     pcpedi.numped%type,
    codprodcesta               pcpedicesta.codprod%type,
    codprodmp                  pcpedicesta.codprodmp%type,
    pvenda                     pcpedicesta.pvenda%type,
    ptabela                    pcpedicesta.ptabela%type,
    qt                         pcpedicesta.qtmp%type,
    iva                        pctribut.iva%type,
    pauta                      pctribut.pauta%type,
    aliqicms1                  pctribut.aliqicms1%type,
    aliqicms2                  pctribut.aliqicms2%type,
    vlcustofin                 pcpedi.vlcustofin%type,
    vlcustoreal                pcpedi.vlcustoreal%type,
    st                         pcpedicesta.st%type,
    ivafonte                   pctribut.ivafonte%type,
    aliqicms1fonte             pctribut.aliqicms1fonte%type,
    aliqicms2fonte             pctribut.aliqicms2fonte%type,
    percbaseredst              pctribut.percbaseredst%type,
    percbasered                pctribut.percbasered%type,
    usavalorultentbasest       pctribut.usavalorultentbasest%type,
    usavalorultentbasest2      pctribut.usavalorultentbasest2%type,
    valorultent                pcest.valorultent%type,
    perbaserednrpa             pctribut.perbaserednrpa%type,
    baseicst                   pcpedi.baseicst%type,
    percbaseredconsumidor      pctribut.percbaseredconsumidor%type,
    utilizapercbaseredpf       pctribut.utilizapercbaseredpf%type,
    PERCBASEREDSTFONTE         pctribut.percbaseredstfonte%type,
    codst                      pctribut.codst%type,
    perdesccusto               pctribut.perdesccusto%type,
    custocont                  pcest.custocont%type,
    custorep                   pcest.custorep%type,
    codicmtab                  pctribut.codicmtab%type,
    pcomint1                   pcprodut.pcomint1%type,
    pcomext1                   pcprodut.pcomext1%type,
    pcomrep1                   pcprodut.pcomrep1%type,
    codlinhaprod               pcprodut.codlinhaprod%type,
    codsec                     pcprodut.codsec%type,
    codepto                    pcprodut.codepto%type,
    percom                     pcpedicesta.percom%type,
    codicmtabpf                pctribut.codicmtabpf%type,
    freteespecial              pcprodut.freteespecial%type,
    custofinest                pcpedicesta.custofinest%type,
    perfretecmv                pcpedicesta.perfretecmv%type,
    txvenda                    pcpedicesta.txvenda%type,
    vldesccustocmv             pcpedicesta.vldesccustocmv%type,
    mostrarpvendasemst         pctribut.mostrarpvendasemst%type,
    usapmcbasest               pctribut.usapmcbasest%type,
    precomaxconsum             pcprodut.precomaxconsum%type,
    custonfsemst               pcest.custonfsemst%type,
    isencaostorgaopub          pctribut.isencaostorgaopub%type,
    codauxiliar                pcpedicesta.codauxiliar%type,
    tipocomissao               pcprodut.tipocomissao%type,
    classe                     pcprodut.classe%type,
    usavlultentmediobasest     pctribut.usavlultentmediobasest%type,
    vlultentmes                pctabpr.vlultentmes%type,
    importado                  pcprodut.importado%type,
    AGREGARIPICALCULOST        pctribut.agregaripicalculost%type,
    usabaseicmsreduzida        pctribut.usabaseicmsreduzida%type,
    usabcrultent               pctribut.usabcrultent%type,
    basebcr                    pcest.basebcr%type,
    stbcr                      pcest.stbcr%type,
    pautafonte                 pctribut.pautafonte%type,
    farmaciapopular            pcprodut.farmaciapopular%type,
    usaptabelabasest           pctribut.usaptabelabasest%type,
    RegimeEspIsenStFonte       pctribut.regimeespisenstfonte%type,
    somoustptabela             varchar2(1),
    codmarca                   pcprodut.codmarca%type,
    utilizaprecofabrica        pcprodut.utilizaprecofabrica%type,
    codicmtabinternac          pctribut.codicmtabinternac%type,-- HIS.02613.2014
    prodimportadopeps          pcpedi.prodimportadopeps%type,  -- HIS.02787.2016
    numtransentpeps            pcpedi.numtransentpeps%type,    -- HIS.02787.2016
    observacaostfonte          pcpedi.observacaostfonte%type,  -- HIS.03377.2017
    indescalarelevante         pcpedi.indescalarelevante%type, -- HIS.03377.2017
    cnpjfabricante             pcpedi.cnpjfabricante%type,     -- HIS.03377.2017
    fabricante                 pcpedi.fabricante%type          -- HIS.03377.2017
   /*
    vlbasepartdest             pcpedicesta.vlbasepartdest%type,
    aliqfcp                    pcpedicesta.aliqfcp%type,
    aliqinternadest            pcpedicesta.aliqinternadest%type,
    vlfcppart                  pcpedicesta.vlfcppart%type,
    vlicmspartdest             pcpedicesta.vlicmspartdest%type,
    vlicmspart                 pcpedicesta.vlicmspart%type,
    VLICMSDIFALIQPART          pcpedicesta.VLICMSDIFALIQPART%type,
    PERCBASEREDPART            pcpedicesta.PERCBASEREDPART%type,
    PERCPROVPART                 pcpedicesta.PERCPROVPART%type,
    vlicmspartrem              pcpedicesta.vlicmspartrem%type
    */
);


type t_prodconvestoque is record(
    condvenda pcpedc.condvenda%type,
    numped    pcpedc.numped%type,
    codfilial pcpedc.codfilial%type,
    codprod   pcpedi.codprod%type,
    unidade   pcprodut.unidade%type,
    qtpedida  number,
    qtestger  pcest.qtestger%type,
    codauxiliar pcpedi.codauxiliar%type,
    numseq      pcpedi.numseq%type,
    qtunitemb   pcpedi.qtunitemb%type,
    qtoriginal  pcpedi.qt%type);



   type t_origemcomiss is record(
    numped                     pcorigemcomis.numped%type,
    origemped                  pcorigemcomis.origemped%type,
    codprod                    pcorigemcomis.codprod%type,
    codauxiliar                pcorigemcomis.codauxiliar%type,
    numseq                     pcorigemcomis.numseq%type,
    codfilial                  pcorigemcomis.codfilial%type,
    numregiao                  pcorigemcomis.numregiao%type,
    percom                     pcorigemcomis.percom%type,
    perdesc                    pcorigemcomis.perdesc%type,
    codusur                    pcorigemcomis.codusur%type,
    codcli                     pcorigemcomis.codcli%type,
    codcob                     pcorigemcomis.codcob%type,
    codplpag                   pcorigemcomis.codplpag%type,
    codrotinacomis            pcorigemcomis.codrotinacomis%type,
    codcomis                   pcorigemcomis.codcomis%type,
    tipocomissao               pcorigemcomis.tipocomissao%type,
    tipovend                   pcorigemcomis.tipovend%type,
    tipovenda                  pcorigemcomis.tipovenda%type,
    codlinhaprod               pcorigemcomis.codlinhaprod%type,
    tipoavaliacaocomissao      pcorigemcomis.tipoavaliacaocomissao%type,
    ordemavaliacaocomissaorca  pcorigemcomis.ordemavaliacaocomissaorca%type,
    usacomissaoporrca          pcorigemcomis.usacomissaoporrca%type,
    usacomissaoporcliente      pcorigemcomis.usacomissaoporcliente%type,
    usacomissaoporlinhaprod    pcorigemcomis.usacomissaoporlinhaprod%type,
    comissaorcatipovenda       pcorigemcomis.comissaorcatipovenda%type,
    considerarcomissaozero     pcorigemcomis.considerarcomissaozero%type

   );

   type t_origemdesc is record (
    numped                      pcorigemdesc.numped%type,
    origemped                   pcorigemdesc.origemped%type,
    codprod                     pcorigemdesc.codprod%type,
    codauxiliar                 pcorigemdesc.codauxiliar%type,
    numseq                      pcorigemdesc.numseq%type,
    ptabela                     pcorigemdesc.ptabela%type,
    pembalagem                  pcorigemdesc.pembalagem%type,
    perdesc                     pcorigemdesc.perdesc%type,
    percbaserca                 pcorigemdesc.percbaserca%type,
    percdescpcativi             pcorigemdesc.percdescpcativi%type,
    pertxfim                    pcorigemdesc.pertxfim%type,
    peracrespf                  pcorigemdesc.peracrespf%type,
    tipodesc                    pcorigemdesc.tipodesc%type,
    codrotinadesc               pcorigemdesc.codrotinadesc%type,
    codpoliticadesc             pcorigemdesc.codpoliticadesc%type,
    codrotinabaserca            pcorigemdesc.codrotinabaserca%type,
    codpoliticabaserca          pcorigemdesc.codpoliticabaserca%type,
    basedebcredrca              pcorigemdesc.basedebcredrca%type,
    creditasobrepoliticabaserca pcorigemdesc.creditasobrepoliticabaserca%type,
    prioritaria                 pcorigemdesc.prioritaria%type,
    prioritariageral            pcorigemdesc.prioritariageral%type,
    alteraptabela               pcorigemdesc.alteraptabela%type,
    validarpoliticasdescclibloq pcorigemdesc.validarpoliticasdescclibloq%type,
    PRECOFIXO                   pcorigemdesc.precofixo%type
    );




  type tb_registralog is table of t_registralog index by binary_integer;

  type tb_registrabloqueio is table of t_registrabloqueio index by binary_integer;

  type tb_cabped is table of t_cabped index by binary_integer;

  type tb_itemped is table of t_itemped index by binary_integer;

  type tb_comboped is table of t_comboped index by binary_integer; -- HIS.03536.2016

  type tb_origempreco is table of t_origempreco index by binary_integer;

  TYPE tb_itenscesta IS TABLE OF t_itenscesta INDEX BY BINARY_INTEGER;

  type tb_prodconvestoque is table of t_prodconvestoque index by binary_integer;

  type tb_origemcomiss is table of t_origemcomiss index by binary_integer;

  type tb_origemdesc is table of t_origemdesc index by binary_integer;


  -- As procedures devem ser habilitadas conforme a empresa prestadora.
PROCEDURE importarpedido(p_tipoleitura IN NUMBER DEFAULT 1,
                         p_tipofv      IN VARCHAR2 DEFAULT 'FV' ,
                         p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
                         p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE),
                         p_numpedrca   IN NUMBER default null ,
                         p_codusur     IN NUMBER default null,
                         p_codfilial   IN VARCHAR2 DEFAULT '99') ;

  -- DDMEDICA-585 - Chamada Especial para Importar Pedido da Rotina 2302
  PROCEDURE importarpedidos2302(p_tipoleitura IN NUMBER,
                                p_tipofv      IN VARCHAR2,
                                p_integradora IN NUMBER,
                                p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
                                p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE));
                                
  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2;                                

  --   {FIM ALT}
  gregpcconsum pcconsum%rowtype; -- parametros do sistema
  vngcontador  integer default 0;


  gvetregistralog         tb_registralog;

  gvetregistrabloqueio    tb_registrabloqueio;

  gregpedido              t_cabped;
  gvet_regpedido          tb_cabped;

  gregitem                t_itemped;
  gvet_regitem            tb_itemped;

  -- HIS.03536.2016
  gregcombo               t_comboped;
  gvet_regcombo           tb_comboped;

  gregorigempreco         t_origempreco;
  gvet_regorigempreco     tb_origempreco;


  gvet_regitenscesta    tb_itenscesta;

  gregprodconvestoque       t_prodconvestoque;
  gvet_regprodconvestoque   tb_prodconvestoque;

  gregorigemcomiss         t_origemcomiss;
  gvet_regorigemcomiss     tb_origemcomiss;

  gregorigemdesc           t_origemdesc;
  gvet_regorigemdesc       tb_origemdesc;

  vngtipoleitura          number(2);
  vsgtipofv               varchar2(2);
  vngdatainicio           date;
  vngdatafim              date;

--Variáveis para CLIENTEFONTEST e REPASSE [HIS.02655.2014]
 vvAchouClienteFilialMed varchar2(1);
 vvClienteFonteST        pcclientfilialmed.clientefontest%type;
 vvRepasse               pcclientfilialmed.repasse%type;
 vvCodCob                pcclientfilialmed.codcob%type;

end;