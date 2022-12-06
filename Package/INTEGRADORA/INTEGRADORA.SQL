CREATE OR REPLACE PACKAGE INTEGRADORA IS

---------------------------------------
--vsVersao varchar(100) := 'v28.0.3.27'; [[MOVIDO PARA A INTEGRADORA_COMPLE]]
---------------------------------------

  /*
    Package de Integracao do Winthor com Sistemas de Forca

    Versão: 28.0.3.27

    ----------------     Historico     ----------------
    Data           Responsável        Solicitação     Comentario
    ----------  -----------------  -----------------  ------------------------------------------------------------
    24/05/2014  Rodrigo Santos     0                  Ajustes relacionados a decisão de qual tipo de ST usar, aplicação do
                                                      simples nacional com o parâmetro "USADESCSIMPLESNAC" igual a "Sim".
    30/05/2014  Rodrigo Santos     0                  Ajuste referente a corte de produtos devido a "PRECO ZERADO",
                                                      o problema ocorria quando o "pcprodut.percipivenda" estava nulo.
    11/06/2014  Luciano Lima       3285.064279.2014   Ajuste referente ao calculo do preço fixo do item, que passava
                                                      o valor incorreto para validacao da campanha do desconto.
    24/06/2014  Luciano Lima       1880.068073.2014   Ajuste no cálculo do simples nacional (alterado também na FUNCOESVENDAS)
    26/06/2014  Luciano Lima       2466.060256.2014   Ajuste na validação das políticas de desconto da 357 e 201
    01/07/2014  Luciano Lima       1519.070585.2014   Ajuste no cálculo do preço sem imposto qdo utilizado fator preço
    02/07/2014  Rodrigo Santos     2517.070988.2014   Ajuste na composição do PBASERCA quando utilizar a rotina 201 antiga.
    03/07/2014  Rodrigo Santos     0                  Implementação de ajustes diversos feitos para a Nilo Tozzo (em visita).
    03/07/2014  Luciano Lima       0                  Correção do Calculo do Preço Fixo.
    04/07/2014  Luciano Lima        907.070315.2014   Ajuste na validação do percentual maximo de desconto
    08/07/2014  Luciano/Rodrigo     907.070315.2014   Ajuste na validação do preço mínimo (sem imposto)
    09/07/2014  Luciano            1880.069909.2014   Ajuste na passagem dos parametros para a função validarautorizacaovenda.
    10/07/2014  Luciano Lima       2517.069055.2014   Correção da passagem de parametros da 357 para do deb/cred rca.
    11/07/2014  Luciano Lima       1092.068963.2014   Ajuste na validação do calculo do pbaserca qdo aplica taxa financeira do plano de pagamento.
    14/07/2014  Rodrigo Santos     2701.053726.2014   Ajuste na chamada da função de calcular CMV, para usar a função mais recente(com 36 parâmetros).
    18/07/2014  Luciano Lima       1092.074979.2014   Ajuste para gravar o percentual do plano de pagamento na pcorigempreco
    18/07/2014  Rodrigo Santos     2517.073717.2014   Invertida ordem de validação dos relacionamentos da 587 e 505. A partir de agora fica sendo
                                                      validado primeiramente os relacionamentos da 505 e só em seguida os relacionamentos da 587.
    24/07/2014  Luciano Lima       1337.080054.2014   O resultado do calculo do stfonte foi separado para o pvenda, ptabela e pbaserca
    05/08/2014  Luciano Lima       2701.080290.2014   Correção no calculo da reducao do simples nacional
    06/08/2014  Luciano Lima       3492.085336.2014   Correção no calculo do pbaserca no caso de st rj
    12/08/2014  Luciano Lima       2517.086192.2014   Ajuste na aplicação dos descontos da 387 e da 561 no caso de ter desconto automatico
    20/08/2014  Luciano Lima        632.090090.2014   Ajuste na aplicação do fator preço aos preços de tabela, venda e base rca.
    03/09/2014  Rafael Braga        1092.09786.2014   Correção no pbaserca, que não recebia a taxa de plano de pagamento.
    03/09/2014  Marcos Garcia      1092.097332.2014   Não estava validando politica de desconto
    08/09/2014  Marcos Garcia      1972.080193.2014   Corrigido o problema do parametro 1303 marcado como "Sim" e o cliente não tinha limite de cretido o pedido estava gravando bloqueado porem estava reservando o estoque.
    10/09/2014  Rafael Braga       1628.100901.2014   Ajustado desconto automático sem alterar preço de tabela; estava rejeitando os pedidos pois não reconhecia
                                                      como desconto máximo.
    15/09/2014  Marcos Garcia      2701.098818.2014   Ajustado o problema do desconto de simples nacional que não estava sendo validado.
    18/09/2014  Rafael Braga       1366.104483.2014   Alterado a ordem de cálculo dos STs Fontes. Passado para calcular o ST do PVENDA por último,
                                                      para que a base de ST não seja alterada. Antes a base de ST assumia a base do último ST calculado, que era o PBASERCA.
    22/09/2014  Marcos Garcia      3218.101565.2014   Problema do pbaserca com preço fixo quando o parâmetro para debitar na conta corrente mesmo quando não der desconto.
    22/09/2014  Marcos Garcia      2337.098165.2014   Ajustada rotina para validar o parâmetro "percacrescimobalcao"
    23/09/2014  Marcos Garcia      1519.102280.2014   Ajustado o problema da multiplicação do fator de preço que estava movimentando
    26/09/2014  MArcos Garcia      2482.099190.2014   Ajustado o calculo de retirar imposto onde não estava considerando se o cliente calcula st ou não
    03/10/2014  Luciano Lima       1033.109699.2014   Ajuste no calculo do pbaserca e na verificação sobre credita/debita da cta corrente do rca.
    07/10/2014  Marcos Garcia      1475.109021.2014   Ajustada problema onde os itens estava sendo cortado por mostra preço de acima do permitido'
    08/10/2014  Luciano Lima       1937.112646.2014   Corrigida a validação do preço no desconto por quantidade
    17/10/2014  Marcos Garcia      1581.107411.2014   Ajustado o retorno da integradora quando o pedido de item de restrição de transporte
    19/11/2014  Luciano Lima       663.123945.2014    Inclusao dos vlbonific no insert da pcpedc e pbonific no insert da pcpedi qdo pedido bonificado
    19/01/2015  Leandro/Marcos     1242.003943.2015   Ajustado vltotal do PCPEDC quando necessário desconto de abatimento
    20/01/2015  Rafael Braga       4346.127564.2014   Caso o campo PCTABPR.CUSTOPRECIFIC esteja preenchido, então ele é usado ao invés do tradicional CUSTOFIN para cálculo do CMV.
    20/01/2015  Leandro/Marcos     1242.003943.2015   Ajustado enviarmensagensrca_int quando mens1 é null.
    22/01/2015  Leandro/Marcos     4992.004775.2015   Redução da margem para ignorar preço mínimo.
    30/01/2015  Rafael Braga       0.009498.2015      Adicionado para gravar ROTINALANC com INTEGRADORA vXX.XX.XX
    05/02/2015  Guilherme Freitas  0                  Ajuste para não gravar 'S' e sim 'F' quando for um item bonificado no pedido TV1.
    06/02/2015  Marcos Garcia       632.012720.2015    Ajustado para não tratar estoque contábil para produto do tipo "CB".
    12/02/2015  Guilherme Freitas  0.015514.2015      Ajustado para não permitir comissão para itens bonificados no pedido TV1.
    13/02/2015  Guilherme Freitas  0.014840.2015      Ajustando para gravar valores ref. a bonificação quando gerando item no mesmo pedido.
    27/02/2015  Leandro Bastos     630.020043.2015    Ajuste PVENDA zerado na importação de orçamentos
    28/02/2015  Leandro Bastos     0.019959.2015      Ajuste de cálculo de IPI
    09/03/2015  Rafael braga       0.025756.2015      Ajuste para validar regiões de FILIAL NF nos cálculos de impostos.
    16/03/2015  Leandro Bastos     0.024365.2015      Não aceitar orçamentos com itens bonificados
    08/04/2015  Leandro Bastos     1020.031354.2015   Comentado parte do código por alterar a posição do pedido indevidamente
    22/04/2015  Leandro Bastos     0.047841.2015      Ajuste no cálculo ST GNRE
    20/05/2015  Leandro Bastos     0.056799.2015      Ajuste redução de IPI do preço de venda PACKAGE INTEGRADORA
    02/06/2015  Leandro Bastos     0.064162.2015      Integradora não informa linha que ocorre erro
    09/06/2015  Leandro Bastos     3407.056514.2015   A rotina 2596 esta validando indevidamente a restrição da rotina 391.
    09/06/2015  Leandro Bastos     0.065460.2015      Criação de FLAG para Integradora
    12/06/2015  Leandro Bastos     0.065222.2015      Rotina não vende Cesta com criação automatica
    15/06/2015  Leandro Bastos     1532.066862.2015   Ajuste VlTotal estava sendo recalculado após o corte
    16/06/2015  Leandro Bastos     907.058478.2015    Verificar restrição de transporte após complementação de pedido
    17/06/2015  Leandro Bastos     3285.069467.2015   Pedido estava sendo importado em duplicidade
    20/07/2015  Rafael Braga       0.080679.2015      Ajustado cálculo do CMV para abater impostos da comissão respeitando o parâmetro p_abaterimpostoscomissaorca da mesma forma que a 316.
    28/07/2015  Leandro Bastos     3013.083960.2015   Ajuste importação de produtos com peso variável
     20/08/2015  Guilherme Freitas  HIS.02023.2015     Implementado validação da procedure OBTERPRECOUTILIZADONFE do fiscal, para definir qual o preço que será utilizado para calcular o
                                                      desconto de PIS, COFINS e SUFRAMA.
    26/08/2015  Rafael Soares      HIS.02215.2015     Criado o campo venda assistida na PCPEDCFV, e este campo é replicado para a tabela PCPEDC
    03/09/2015  Leandro Bastos     1592.100160.2015   Ajuste para diversos codfilialretira em um mesmo pedido
    18/09/2015  Guilherme Freitas  HIS.01014.2015     Implementação para agregar na primera parte do cálculo do ST, os descontos comercial, de pis/cofins, suframa e ICMS conforme parametrização.
    11/01/2016  Guilherme Freitas                      Implementação ICMS partilha
    12/02/2016  Guilherme Freitas                     Implementação dos campos da PCOrigemPreco V2.
  30/08/2016  Rafael Braga    0.095672.2016     Reimplementação da PKG_MOTIVOBLOQUEIO
    13/10/2016  Rafael Braga       907.101980.2016    Ajustado para rejeitar pedido caso não tenha saldo RCA disponível e o parâmetro TIPOIMPORTACAOVENDA seja = 'RP'
    19/07/2018  Marcos Garcia      WT300-166          Implementado o calculo do cmv para receber o vlfecp para abater no calculo
    --------------------------------------------------------------------------------------------------------------
  */
  -- Registro referente ao cabecalho do pedido.
  -- As procedures devem ser habilitadas conforme a empresa prestadora.
  PROCEDURE IMPORTARPEDIDO
  (
    p_tipoleitura IN NUMBER DEFAULT 1,
    p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
    p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE),
    p_codfilial   IN VARCHAR2 DEFAULT '99',
    p_tiporeg     IN NUMBER DEFAULT NULL,
    p_codusur     IN NUMBER DEFAULT NULL,
    p_numpedrca   IN NUMBER DEFAULT NULL
  );

  PROCEDURE PROC_VALIDARITEMPED
  (
    p_apenasvalida     IN VARCHAR2,
    p_regitem          IN OUT integradora_comple.t_itemped,
    p_regorigempreco   IN OUT integradora_comple.t_origempreco,
    p_regorigemcomiss  IN OUT integradora_comple.t_origemcomiss,
    p_regorigemdesc    IN OUT integradora_comple.t_origemdesc,
    p_regpedido        IN OUT integradora_comple.t_cabped,
    p_regcliente       IN integradora_comple.t_clientepedido,
    p_regrca           IN integradora_comple.t_rca,
    p_regregiao        IN integradora_comple.t_regiaocliente,
    p_regplpag         IN integradora_comple.t_planodepagamento,
    p_regplpagetico    IN integradora_comple.t_plpagetico,
    p_regplpaggenerico IN integradora_comple.t_plpaggenerico,
    p_regfilial        IN integradora_comple.t_filial,
    p_regproduto       OUT integradora_comple.t_produto,
    p_regprecos        OUT integradora_comple.t_precosetributacao,
    vscoddistrib       IN pcprodut.coddistrib%TYPE,
    p_mensagem         OUT VARCHAR2,
    p_permaxdesc       OUT pcpedi.perdesc%TYPE,
	vsMultiplicouPeso  OUT VARCHAR2
  );

  --   {FIM ALT}
  -- Exceções Globais
    ERRO_VALIDARPRECONULOOUZERADO  EXCEPTION;

/*
      ----------------     Historico Antigo    ----------------
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
    27/05/2011  Andréa         132437      Alterar processo de frios para receber a informação da unidade de venda
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
    29/06/2011  Andréa         135797      Implementar processo de filial retira . Utilizando primeiro a filial retira da pcpedifv, caso esta esteja nula,
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
    19/07/2011  Andréa          136776     Incluir importação e validação do campo codclitv8 em pedido TV7
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
    22/08/2011  Andréa          139855     Incluir importação do campo PCPEDCFVMANIF.DATA para pcpedc.data para venda manifesto
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
    03/10/2011  Andréa          145783     Corrigir gravação da quantidade de brinde
    07/10/2011  Andréa          146391     Correção em validação de brinde com erro ORA-00979
    12/10/2011  Andréa          146618     Verificar parâmetro tipocalculognre em conjunto com mostrarpvendasemst
    12/10/2011  Andrea          145214     Validar processo de multiplas filiais por plano de pagamento
    14/10/2011  Andréa          146800     Correção em identificação de estoque para brinde
    17/10/2011  Andréa          146550     Correção em validação da 561
    18/10/2011  Andrea          146080     Incluir leitura e gravacao dos campos : codcob, codplpag,emailnfe da tabela pcclientfv
    18/10/2011  Andrea          146254     Incluir para verificar cobranca cartao (pccob.cartao = 'S'), quando for validar o parametro VERIFICALIMCREDCODCOBD
    18/10/2011  Andrea          146184     Ler e gravar campo tipoprioridadeentrega da tabela pcpedcfv
    18/10/2011  Andrea          145246     Caso esteja parametrizado  utilizavendaporembalagem = 'S' , validar o codauxiliar enviado
    21/10/2011  Andrea                     Correção em validação de plano de pagamento
    27/10/2011  Andrea                     Verificar preço por embalagem ( mesmo com parâmetro marcado) apenas se o parâmetro utilizavendaporembalagem estiver 'S'
    02/11/2011  Andréa          148066     Correção para verificar se apos a validação do multiplo o item ficou com quantidade válida.
    04/11/2011  Andréa          148099     Correção em validação do desconto permitido
    04/11/2011  Andréa          148084     Correção em calculo de stfonte com ipi, utilizar preco de venda sem ipi
    08/11/2011  Andréa          146855     Validar parâmetro ACEITAVENDAAVISTACLIBLOQ, caso esteja 'S',o cliente bloqueado e a venda a vista, permite gravar o pedido liberado.
                                           Validar parâmetro VALIDARPOLITICASDESCCLIBLOQ, caso esteja 'N' e cliente bloqueado, não é permitido aplicar descontos da 561 e 387.
    08/11/2011  Andréa          146949     Implementar projeto 121602 - Limitar estoque para Brindes
    09/11/2011  Andréa          147390     Validar parâmetro verificabloqueiosefaz, caso o cliente esteja bloqueado no sefaz
    09/11/2011  Andréa          147483     Incluir parâmetro codfilial para executar pedidos por filiais separadas
    10/11/2011  Andréa          148101     Ler codauxiliar na pcpedifvmanif e utilizar processo de venda por embalagem para a buscado preço
    10/11/2011  Andréa          148121     Gravar para pedidos de pronta entrega ( Tv14) o codfornecfrete do pedido tv13
    11/11/2011  Andréa          148957     Alteração para buscar registros da pcpedcfv apenas com tipofv nulo ou iguais a 'FV'
    17/11/2011  Andréa          145153     Gravar campos localdesembaraco e ufdesembaraco da pcpedcfv na pcpedc.
    17/11/2011  Andréa          148103     Validar parâmetro pcconsum.liberarpedidopendente, caso esteja 'N' ou nulo e o parâmetro pcparamfilial.aceitavendasemestfv estiver = 'S' e o
                                            item não tiver estoque suficiente, gravar o pedido Pendente.
    22/11/2011  Andréa          148160     Incluir  validação de campanhas de brinde : Valor total e Quantidade Obrigatoria (VO) e Valor Total com Restricoes (VR)
    23/11/2011  Andréa          148590     Incluir verificação dos parâmetros : ACEITADESCPRECOFIXO e ACEITAACRESCIMOPRECOFIXO para permitir dar desconto ou acrescimo sobre o valor do preço fixo.
                                           Incluir validação da coluna pcprecoprom.APLICADESCONTOSIMPLES para permitir ou não dar o desconto do simples nacional sobre o preço fixo
    23/11/2011  Andréa          149968     Corrigir para fazer a validação de multiplo depois da validação da embalagem
    23/11/2011  Andréa          148819     Validar parâmetro VLMAXVENDABONIFICMES que informa valor maximo de vendas bonificadas no mês.
    28/11/2011  Andréa          147989     Acrescentar regras de plano de pagamento com forma de parcelamento variavel
    30/11/2011  Andrea          150630     Corrigir para utilizar codcli como codcliprinc quando este estiver nulo
    01/12/2011  Andréa                     Corrigir cáculo de prazo médio para pedidos com plano de pagamento cuja forma de parcelamento é variável
    08/12/2011  Andréa          151094     Acrescentar parâmetro para possibilitar executar a package para importar apenas um tipo especifico de registro.
    09/12/2011  Andréa          150323     Incluir validação do parâmetro PEREXCEDELIMCRED para valida limite de credito do cliente.
                                           Retirar obrigatoriedade do campo codmotivo na PCVISITAFV
    09/12/2011  Andréa          150598     Verificar parâmetro bloquearpedbonific, caso esteja 'S', gravar pedidos de brinde bloqueado, caso esteja 'N' gravar  na mesma posição do pedido original
    12/12/2011  Andréa                     Corrigir para acrescentar default no quinto parÂmetro p_tiporeg para null
    13/12/2011  Andréa          151626     Alterar para aplicar taxa de juros para plano de pagamento variavel, antes de validar valor minimo de parcelas e pedido
    13/12/2011  Andréa          151434     Acrescenta mais uma verificação de existência do pedido pronta entrega no momento de inserir na pcpedc
    16/12/2011  Andréa                     Correção em validação do parâmetro liberarpedidopendente. Caso o parâmetro aceitavendasemest = 'S' and liberarpedidopendente = 'N' o pedido será gravado
                                           Pendente. Nem será verificado estoque para este caso.
    21/12/2011  Andréa          152455     Alterar o nvl pcprodut.multiplo para 0
    29/12/2011  Andréa          152992     Gravar pcpedi.poriginal com o preço de tabela da 201 aplicando a taxa do plano de pagamento e desc/acre por ramo de atividade
    04/01/2012  Andréa          153277     Corrigir para gravar mensagem de falta de estoque para todos os itens do pedido que estejam com falta
    05/01/2012  Andréa                     Corrigir para não gerar vencimentos para plano de pagamento variavel com pedido for complementar
    10/01/2012  Andréa          152994     Implementar utilização da pctabprcli, tributacao por estado e atualizar politicas de desconto para pedido Pronta Entrega
                                           Gravar campo pcpedi.rotinalanc = '2596'
    12/01/2012  Andréa          153237     Gravar pcpedcfv.posicao_atual = 'R' quando o pedido for rejeitado
    20/01/2012  Andréa          149677     Incluir parâmetro codplpag e codcob na validação de restrição de venda (pcrestricaovenda)
    25/01/2012  Andréa                     Corrigir variavel que está atrapalhando quando parâmetro aceitadescprecofixo está 'S'
    26/01/2012  Andréa          154599     Implementar venda tipo 10
    27/01/2012  Andréa          155026     Alterar forma de identificação de pessoa fisica no calculo de cmv
    27/01/2012  Andréa          148142     Alterar chamada da validação de politica de desconto por quantidade  para incluir validação de restrições (pcgruposcampanhac e pcgruposcampanhai)
    27/01/2012  Andréa          154566     Validar parâmetro aceitavendasemdtvencfv da pcparamfilial, caso esteja 'N' e não tenha dados do pedido na tabela pcpedcvctofv, rejeitar pedido
    30/01/2012  Andréa          142808     Validar parâmetro pcparamfilial.permaxdescvenda, caso esteja nulo validar o pcconsum.permaxdescvenda. Caso o perdesc do pedido esteja superior a estes,
                                            rejeitar o pedido.
    31/01/2012  Andréa          154896     Atualizar rebaixa de cmv para possibilitar verificar várias verbas vigentes para o mesmo produto.
                                           Incluir processo de rebaixa para itens de pedido de brinde
    02/02/2012  Andréa          154920     Separar apuração de campanha em outra package, incluir chamada desta nova package.
                                           Incluir registros de brinde ( cabeçalho e itens) nas tabelas: pcretornoctv5fv,pcretornoitv5fv.
                                           Atualizar o campo pcpedcfv.geroubrinde com a informação de geração ou não de brinde.
    07/02/2012  Andréa          143646     Utilizar regra da politica de desconto prioritariaa geral ( 561). Caso tenha uma politica cadastrada como prioritaria geral,
                                            ela irá sobrepor as demais politicas que tenha na 561 e também desconto por quantidade e preço fixo
    13/02/2012  Andréa          154935     Gravar informação no campos pcpedcfv.atendido. Valor P para caso tenha corte de item ou de quantidade de algum item e T para atendido Total
    13/02/2012  Andréa          156260     Corrigir para retirar espaço dos campos que contem a informação do cnpj/cpf do cliente
    24/02/2012  Andréa          155979     Gravar informação se teve corte no item pcpedifv.corte
    27/02/2012  Andréa          152144     Incluir validação de restricao por plano de pagamento (pcplpagrestricao)
    27/02/2012  Andréa          153495     Validar se produto é controlado pelo IBAMA e caso seja validar se cliente tem registro e se registro está vigente
    28/02/2012  Andréa          152983     Calcular percentual de desconto de isencao de impostos do produto de acordo com a parametrizacao do campo "%Desc.Isencao(Suframa)" do cadastro do cliente
    28/02/2012  Andréa          151307     Validar o parâmetro "Utiliza %Desc Isencao ICMS para vendas a prazo"
    01/03/2012  Andréa          155543     Incluir validação de recebimentos feitos no palm
    02/03/2012  Andréa          157355     Incluir verificação e alteração de saldo de rca para venda 14
    07/03/2012  Andréa          157985     Caso exista cadastro do cliente na pcplpagcli para o plano de pagamento da venda, não validar prazo com o plano do cadastro do cliente
    15/03/2012  Andréa          158518     Incluir processo de conversão de estoque do produto master
    16/03/2012  Andréa          158745     Utilizar pcembalagem.fatorpreco para compor o preco de tabela para venda por embalagem
    23/03/2012  Andréa          157883     Incluir importação de Cotações ( pccotafv)
    23/03/2012  Andréa          157620     Incluir validação do parâmetro obrigatoriovinculartv5comtv1 para venda bonificada
    26/03/2012  Andréa          158774     Inlcuir validação do parâmetro separarprodcomrestricaotransp para separação de pedido com itens com restrição de transporte
    26/03/2012  Andréa          159551     Correção no processo do simples nacional para calculo do pbaserca
    28/03/2012  Andréa          158600     Incluir gravação de PCORIGEMCOMIS e PCORIGEMDESC
    29/03/2012  Andréa          159152     Atualizar regras para venda TV14
    29/03/2012  Andréa          159881     Retirar regra em que para pedidos bonificados o ptabela fique igual ao pvenda
    02/04/2012  Andréa          159918     Correção em processo do simples nacional
    03/04/2012  Andréa          159599     Acrescentar novos campos de importação de clientes
    03/04/2012  Andréa          159606     Acrescentar importação de Referencias comerciais de clientes ( PCCLIREFFV)
    05/04/2012  Andréa          155722     Incluir processo de abatimento
    16/04/2012  Andréa                     Incluir envio de mensagem da procedure PRC_CONVERSAO_ESTOQUE_PACOTE
    17/04/2012  Andréa                     Validar se tem percentual de desconto de abatimento
    18/04/2012  Andréa          161194     Aplicar percentual de juros para pedidos com plano de pagamento variavel antes dos calculos de cmv, st, e comissão
    18/04/2012  Andréa                     Alterar para gravar percentual de desconto de abatimento na pcpedi e não na pcpedc
    20/04/2012  Andréa                     Alterar nome da coluna envionfeemailcom da pcclientfv para envionfemailcom
    20/04/2012  Andréa          161534     Correção na verificação de parâmetro da pcparamfilial
    23/04/2012  Andréa          161610     Corrigir para que quando fatorpreco da pcembalagem estiver 0, transformá-lo em 1
    26/04/2012  Andréa          160801     Atualizar dtultcomp da tabela pcclient quando importar algum pedido  e gravar pcpedi.geragnre_cnpjcliente
    26/04/2012  Andréa          161781     Inverter valor utilizado do parâmetro VALIDARPOLITICASDESCCLIBLOQ para 'S' quando for para não aceitar validação de politica de desconto para cliente bloqueado
    27/04/2012  Andréa          160454     Atualizar chamada da funcoesvendas.validarpoliticadesconto (561) para acrescentar parâmetro numdias
    02/05/2012  Andréa          162132     Correção em processo de corte de estoque de frios
    10/05/2012  Andréa          158674     Acrescentar chamada da procedure de Atualização de rota
    14/05/2012  Andréa          162975     Gravar posição da Indenização = 'A' quando o pedido original estiver Liberado
    15/05/2012  Andréa          159345     Gravar informação de agrupamento nos pedidos
    18/05/2012  Andréa          163419     Inibir gravação de <enter> no inicio das mensagens de rejeição
    18/05/2012  Andréa          163416     Corrigir aplicação de desconto por quantidade, quando para a campanha tiver informado desconto maximo sobre preço a vista
    23/05/2012  Andréa          162789     Implementar venda TV20
    24/05/2012  Andréa          163133     Inverter gravação dos campos de enderecos enviados nos campos final "ent" com os campos final "com"
    25/05/2012  Andréa          163938     Corrigir para não dividir preço de venda de itens que são embalagem quando usa o preço por embalagem
    29/05/2012  Andréa          164145     Correção para reserva de estoque de item de pedido complementar sem estoque quando o pedido original está Liberado
    30/05/2012  Andréa          164317     Incluir validação da pctabprcli na importação de indenizações
    31/05/2012  Andréa          164317     Acrescentar nvl na verificação da filialnf a ser utilizada na busca da pctabprcli das indenizações
    01/06/2012  Andréa          164522     Correção em processo de preço por embalagem para dividir preço de venda e preço de tabela (pcembalagem) pelo qtunit
    04/06/2012  Andréa          164482     Alterar para verificar parâmetro FIL_BLOQUEARPEDIDOSABAIXOVLMINIMO ao inves de BLOQUEARPEDIDOSABAIXOVLMINIMO
    11/06/2012  Andréa          164877     Acrescentar nvl no campo pcest.valorultent
    12/06/2012  Andréa          165063     Retirar validação de cod_cadrca na pcsuperv
    19/06/2012  Andréa          165633     Correção em validação de quantidade de item de pronta entrega, alterar variavel para aceitar decimal
    20/06/2012  Andréa          165788     Correção para não atribuir codcobinicial e codplpaginicial para alteração de cadastro de clientes
    21/06/2012  Andréa          165822     Alteração para verificar pctabpr de produto cesta, deixando opcional ter ou não este cadastro
    22/06/2012  Andréa          166009     Alterar para gravar origmepd = R para pedido TV14
    26/06/2012  Andréa          156566     Incluir validação do parâmetro VLMINVENDABKFILIAL que sobrepoe o VLMINVENDABK
    27/06/2012  Andréa          164047     Incluir processo de tipo de bonificação
    28/06/2012  Andréa          166417     Alterar para não validar quantidade do produto na TV14 se a nota for de cancelamento
    04/07/2012  Andréa          166649     Corrigir gravação dos campos localdesembaraco e ufdesembaraco
    06/07/2012  Andréa          164694     Separar a parte cadastral em uma nova package
    06/07/2012  Andréa          165544     Incluir processo de montagem de kit
    16/07/2012  Andréa          167578     Correção em validação da politica 561
    18/07/2012  Andréa          165466     Atualizar gravação da pcorigempreco
    19/07/2012  Andréa          167828     Corrigir validação de 561 com 387 automática
    20/07/2012  Andréa          168116     Corrigir validação de percentual de indenização ( truncando) para evitar rejeições
    23/07/2012  Andréa          164660     Incluir validações do valor do pedido pos corte
    24/07/2012  Andréa          168256     Validar parâmetros : UTILIZAROTEIRIZACAO e ATUALIZAROTANOMOMENTOVENDA utilizado para o processo de roteirização, primeiro para a filial '99',
                                            caso não encontre verificar para a filial de venda ou filial do rca para visitas
    24/07/2012  Andréa          165829     Incluir novo processo de DANFE na pronta entrega
    27/07/2012  Andréa          168591     Alterar para retirar st do item com preço fixo na validação quando este possuir preço fixo
    01/08/2012  Andrea          169083     Alterar para aplicar taxa do plano de pagamento e acrescimo pessoa fisica no produto cesta e nos itens
    09/08/2012  Andrea          169695     Incluir regra de validacao de plano de pagamento com vencimento variavel, para validar pelo prazo medio quando tiver uma unica parcela
    13/08/2012  Andrea          170071     Arredondar preco minimo de venda da 201 para comparar com o preco de venda enviado
    15/08/2012  Andréa          170701     Acrescentar regras de venda para Broker Melitta
    16/08/2012  Andréa          169666     Separar processo de pronta entrega em outra package
    22/08/2012  Andrea          171461     Na venda broker, nao validar se cobranca do cliente esta cadastrada como broker
    27/08/2012  Andrea          171602     Validar novo parametro para bloquear ou rejeitar pedido de cliente sem limite de credito
    27/08/2012  Andrea          171439     Caso nao seja enviado fretedespacho na pcpedcfv, gravar o fretedespacho do cadastro do cliente
    29/08/2012  Andrea          171941     Gravar campo sugestao na pcpedi, buscando da pcpedifv para venda normal e pcpedifv para venda pronta entrega
    31/08/2012  Andrea          172814     Corrigir para validar se o pedido TV1 enviado como referencia no pedido TV5 esta com o campo contaordem nulo
    12/09/2012  Andréa          173634     Incluir gravação do turno de entrega no pedido
    13/09/2012  Andréa          173578     Incluir verificação do parâmetro ABATIMENTODEBITARCCRCA para identificar se o desconto de abatimento
                                            vai ou não abater no saldo de conta corrente do rca
    17/09/2012  Andréa          173597     Alteração para legislação do simples nacional para usar novo campo ALIQSTSIMPLESNACIONAL
    20/09/2012  Andréa          174865     Incluir parâmetros codusur (para todos os registros que tenha codusur na tabela) e
                                            numpedrca ( apenas para os pedidos de venda normal) para disparar a package
    01/10/2012  Andréa          176263     Correção em corte quando produto é multiplo
    02/10/2012  Andréa                     Correção e validação do parâmetro verificabloqueiosefaz
    04/10/2012  Andréa          176377     Correção em forma de identificar pessoa fisica
    04/10/2012  Andréa          176749     Ler pcpedcfv.codendent, pcpedifv.tipoentrega e gravar em pcpedc.codendent e pcpedi.tipoentrega
    17/10/2012  Andréa          178005     Incluir procedure RETORNARPRECO que retorna preço de venda para ser utilizada pelo Myshop
    18/10/2012  Andréa          177940     Incluir gravação de valor de entrada no pedido
    22/10/2012  Andréa          177953     Validar redes de clientes
    24/10/2012  Andréa          178865     Retirar validação de parametro aceitavendabloq quando o pedido ou parcela não atingir o valor minimo para boleto
    24/10/2012  Andréa          177935     Retornar mais informações sobre estoque quando o pedido for gravado Pendente
    25/10/2012  Andréa          179131     Incluir verificação de tributação por estado nas indenizações
    06/11/2012  Andréa          178909     Incluir importação de Orçamentos
    07/11/2012  Andréa          180376     (180181) Arredondar o preço da 201 antes de retirar os impostos, igualando ao processo da 316
    08/11/2012  Andréa          180376     (180181) Caso a função de retornar preço sem impostos retorne um valor cuja diferença com o valor original seja menor ou igual a R$0.01
                                            utilizar o valor original
    12/11/2012  Andréa          180667     Corrigir aplicação de percentual de desconto de produto cesta, nos itens da cesta
    13/11/2012  Andréa          180106     Validar troca de pedido de venda manifesto bonificada.
    16/11/2012  Andréa          181028     Corrigir para mostrar a posição atual correta na pcpedcfv quando o pedido for montado pela package
    19/11/2012  Andréa          181169     Corrigir atualização de pbaserca para politica de credito da 561
    20/11/2012  Andréa          180114     Ler e gravar campo recolher nos itens de indenizacao
    21/11/2012  Andréa          181658     Caso o parâmetro separarprodcomrestricaotransp esteja desmarcado, verificar se existe algum item do pedido com restricao de
                                            transporte ou restricao de porte refrigerado. O pedido deve ser marcado com a restrição. Se houver itens com os 2 tipos
                                            de restrição, marcar o pedido como Refrigerado
    28/11/2012  Andréa          182222     Acrescentar a identificação do produto (codprod) na mensagem da procedure de conversão de estoque
    26/12/2012  Andréa          181875     Corrigir para não gravar pbaserca nulo
    04/01/2013  Andréa          186003     Corrigir validação do parametro permitirvendainterestadual para pessoa fisica
    07/01/2013  Andréa          186126     Corrigir chamada da package importarprontaentrega
    08/01/2013  Andréa          185766     Incluir utilizacao da regiao para venda balcão, cadastrada na 132 ( FIL_NUMREGIAOBALCAOINTER)
    09/01/2013  Andréa          185764     Incluir validação dos novos parametro vlminvendafv e vlminvendabnffv. Caso estes estejam nulos ou com valor zero,
                                            serão validados os parâmetros vlminvenda e vlminvendabnf respectivamente.
                                           Verificar parâmetro VALIDAVLMINVENDABALCAO para validar ou não valor minimo para venda Balcão.
    10/01/2013  Andréa          185762     Validar valor RP para parametro aceitavendasemestfv, com este valor, rejeitar pedido, caso tenha algum item com falta de estoque
    14/01/2013  Andréa          186801     Correção em calculo de pcfalta quando estoque disponivel está negativo
    15/01/2013  Andrea          187030     Atualizacao no processo de preco por embalagem
    17/01/2013  Andréa          187259     Corrigir calculo de pbaserca, caso tenha politica automática e flexivel
    24/01/2013  Andréa          180108     Gravar numindeniz na pcindcfv
    30/01/2013  Andréa          180108     Aceitar indenizacao de pedido TV14 bonificado, marcado como brinde
    31/01/2013  Andréa          180108     Apos importar indenizacao, verificar se foi pedido de troca e gravar numindeniz
    06/02/2013  Andréa          189079     Incluir validação de quantidade maxima de determinado produto no pedido (pcprodfilial.qtmaxpedvenda)
    07/02/2013  Andréa          189075     Incluir validação de codigo de endereço de entrega de cliente
    15/02/2013  Andréa          189896     Gravar indenizacao sempre na posição A
    28/02/2013  Andréa          191089     Atualizar calculo de impostos com a 316
    06/03/2013  Andréa          191680     Corrigir gravação do codicmtab para pessoa fisica
    12/03/2013  Andréa          192085     Corrigir gravação do vlanted para pedido complementar
    14/03/2013  Andréa          192368     Ajustes no cálculo de simples nacional, após as alterações de st
    19/03/2013  Andréa          192724     Alterar para gravar poriginal na pcpedi, antes de acrescentar a taxa do plano de pagamento ao preço de tabela para não afetar o processo de combo
    20/03/2013  Andréa          193097     Permitir gravar orçamento para venda 13
    21/03/2013  Andréa          193247     Incluir validação de cotas de clientes e rcas (pcprodusur)
    22/03/2013  Andréa          193128     Incluir gravação/validação de cliente recebedor e cliente autorizador
    22/03/2013  Andréa          193240     Alterar para que a procedure retornapreco (utilizada pelo Myshop) retorne preços da embalagem (quando trabalhar com venda por embalagem)
    22/03/2013  Andréa          192340     Alterar retorno p_valido para number ao inves de boolean
    23/03/2013  Andréa          193101     Validar margem de lucratividade do pedido se esta está acima da margem minima do plano de pagamento
    25/03/2013  Andréa          193209     Ajustar regras de isenção de icms
    27/03/2013  Andréa          193622     Corrigir para que ao gravar valor na coluna log da pcpedc, verifique antes se não estourou o limite. Problema causado por rejeição de vários itens do pedido e este
                                            sendo gravado bloqueado ao invés de rejeitar itens
    05/04/2013  Andréa          194171     Alterar processo de abatimento, incluindo possibilidade de informar valor de desconto
    05/04/2013  Andréa          194424     Corrigir variável que indica quantidade falta antes da validação de saldo disponivel do rca
    05/04/2013  Andréa          194424     Alterar para lançar os créditos antes dos débitos na conta corrente do rca. Este procedimento já é feito para verificar saldo disponível, precisou ser feito
                                            no lançamento também, por caus de uma constraint no cliente que não deixa atualizar o vlcorrente negativo.
    08/04/2013  Andréa          194518     Incluir chamada da procedure PRC_GERARPEDIDOITEMCOMST para separar pedido com item que tenha st
    10/04/2013  Andréa          194321     Incluir regras e validação para st diferenciado para cliente do estado MT
    17/04/2013  Andréa          155964     Para venda com plano de pagamento que exige entrada, validar parametro para descontar o valor da entrada ao verificar o limite de credito
    18/04/2013  Andréa          195951     Retirar gravação do codigo do combo no campo codpromocao
    24/04/2013  Andréa          196485     Não deixar complementar pedido se o processo de WMS tiver sido iniciado
    22/05/2013  Andréa          199698     Acrescentar regras de broker para escolha da região,gravação de campos no pedido e cutos dos itens
    28/05/2013  Andréa          199697     Alterar validação de alguns parâmetros do produto para a pcprodfilial e acrescentar processo de venda fracionada
    04/06/2013  Andréa          200970     Corrigir validacao do parametro verificarclientesrede
    05/06/2013  Andréa          200970     Gravar no campo motivoposicao a mensagem de bloqueio da rede de clientes
    11/06/2013  Andréa          201157     Altera para não barrar, caso a package tenha retirado impostos antes da validação de preço e a diferença entre o preço de venda e o valor minimo de venda seja <= 0,01
    13/06/2013  Andréa          192011     Caso não sejam enviadas observações de entrega no pedido, gravar as observacoes de entrega do cadastro do cliente
    13/06/2013  Andréa          202216     Corrigir para não aplicar desconto 2 vezes no pbaserca quando tem desconto automatico na 387
    18/06/2013  Andréa          190488     Alterar para verificar parametro verificaestoquecont da pcparamfilial
    18/06/2013  Andréa          195136     Quando utilizar preço por embalagem, se o preço a ser utilizado for o de atacado e este estiver nulo ou zero, utilizar o preço de varejo
    19/06/2013  Andréa          196394     Incluir validacao do parametro bloqueiavendaestpendente para que a quantidade em estoque pendente entre ou não no calculo do estoque disponivel
    21/06/2013  Andréa          196383     Permitir indenizacao/troca de produtos proibidos para venda ou fora de linha
    24/06/2013  Andréa          196064     Acrescentar validação do percentual maximo de acrescimo para fv
    24/06/2013  Andréa          199999     Gravar campo codmotbloqueio na pcpedc
    25/06/2013  Andréa          185261     Acrescentar comissao por embalagem
                                           Gravar campo utilizavendaporembalagem na pcpedc
    01/07/2013  Andréa          203791     Quando estiver parametrizado para mostrar o preço sem impostos ou estiver usando o novo processo de enviar o pvenda sem imposto pelo palm. Retirar também do preço minimo de venda
    03/07/2013  Andréa          178683     Incluir opção de utilizar venda e preço por embalagem nos itens da cesta
    05/07/2013  Andréa          204123     Comentar alteração da tarefa 178683
    16/07/2013  Andréa          190868     Acrescentar a opção de rejeitar todo o pedido, caso tenha algum item com desconto acima do permitido
    17/07/2013  Andréa          204407     Corrigir gravação de cmv para produto cesta  e atualizar processo de comissão dos itens da cesta
    18/07/2013  Andréa          204784     Incluir validação de horário permitido para importação de pedidos
    18/07/2013  Andréa          205205     Corrigir gravação do campo coddesconto na pcpedi
    26/07/2013  Andréa          203907     Alterar retorno dos pedidos para que mostre os dados dos pedidos gerados com restricao de transporte. Gravar numped e restricaotransp na pcpedifv
    30/07/2013  Andréa          202676     Alterar validação do parametro verificarbloqueiosefaz e inclur validação do parâmetro validaclisefaz
    30/07/2013  Andréa          206049     Corrigir corte indevido no estoque quando utilizado parametro bloqueiavendaestpendente
    02/08/2013  Andréa          205746     Incluir chamada da procedure que gerar o pedido TV8
    07/08/2013  Andréa          206837     Incluir procedure que faz a verificação dos parametros da pcparamfilial
    08/08/2013  Andréa          207036     Incluir validação de parâmetro para bloquear ou rejeitar pedido abaixo da margem minima.
    09/08/2013  Andréa          207010     Incluir validação da nova coluna  usadebredrca da pcclient
    09/08/2013  Andréa          207032     Gravar utilizavendaporembalagem na pcpedc
    15/08/2013  Andréa          207153     Acrescentar nvl nos campos numpr e pertxfin da pcplpag para retorno de preço do myshop
    15/08/2013  Andréa          207034     Acrescentar processo de comissão por profissionais
    16/08/2013  Andréa          207714     Acrescentar parametro na chamada da procedure de preço Fixo da funcoesvendas
    19/08/2013  Andréa          207702     Acrescentar colunas de retorno para MyShop
    20/08/2013  Andréa          207733     Validar pccobplpag apenas se existir registro da cobrança do pedido
    23/08/2013  Andrea          179985     Incluir restricao por plano de pagamento na validação de combo
                                           Incluir validação do codauxiliar no preço fixo, caso esteja parametrizado precoporembalagem
    03/09/2013  Andréa          209703     Corrigir para gravar mensagem de retorno da procedure de conversão de estoque nos itens ao inves do cabeçalho
    09/09/2013  Andréa          209906     Validar valor minimo do pedido por rca
    09/09/2013  Andréa          209912     Ignorar processo de frios quando trabalhar com venda por embalagem
    20/09/2013  Andréa          211577     Corrigir para aplicar o percentual de desconto quando tiver 2 politicas automáticas na 561, sendo uma de acrescimo e outra de desconto
    20/09/2013  Andréa          211581     Validar numero de itens minimo por plano de pagamento após os cortes
    23/09/2013  Andréa          211580     Incluir as seguintes validações: Valor maximo para pedido e diferença entre fretedescpacho enviado e o do cadastro do cliente.
                                           Alterar validações para ao inves de rejeitar, bloquear o pedido de acordo com parametro aceitavendabloq :
                                           - Valor do pedido abaixo do minimo para rca, cobrança, plano de pagamento, filial, prazo medio, boleto, margem e alvara vencido.
    25/09/2013  Andréa          211582     Incluir processo de geração de crédito para indenizações
    27/09/2013  Andréa          212262     Corrigir retirada de valor de isenção de cofins
    07/10/2013  Andréa          212669     Retirar processo de indenização e Myshop
    08/10/2013  Andréa                     Corrigr aplicação de taxa financeira no plano para parametros do MyShop
    08/10/2013  Andréa          213286     Corrigir validação de comissão nula
    11/10/2013  Andréa          213379     Alterar para que a comissão do produto cesta na pcpedi, seja a média das comissões da pcpedicesta
    11/10/2013  Andréa          213666     Ajustes para não arredondar preços para o Myshop
    15/10/2013  Andréa          213835     Correções Myshop
    17/10/2013  Andréa          213977     Corrigir baixa de estoque para pedidos com mesmo produto em filiais retira diferentes e sem codauxiliar
    18/10/2013  Andréa          211577     Corrigir regra da tarefa 211577
    28/10/2013  Andréa          755103     Corrigir para gravar valor total de abatimento quando o pedido tiver itens sem estoque, mas for gravado Pendente ou Bloqueado
    29/10/2013  Andréa          HIS.00045.2013    Inclusão de regra de st para clientes de MG ( legislação)
    19/11/2013  Andréa          HIS.00204.2013    Incluir a opção de utilizar o parâmetro numpedrca para importar o pedido de pronta entrega, quando enviar o parametro p_tiporeg = 9
    04/12/2013  Andréa          2311.013790.2013  Corrigir validação de parâmetro de roteirização para verificar primeiro o valor para a filial 99
    10/01/2014  Andréa          HIS.01194.2013    Incluir calculo de st do RJ e alterar calculo de st para utilizar preços sem impostos da 201
    20/01/2014  Andréa          3019.004583.2014  Gravar numcar = 0 na pcpedi
    20/01/2014  Andréa          HIS.01194.2013    Corrigir para conseguir retirar impostos utilizando a função antiga quando a 201 não estiver atualizada
    21/01/2014  Andréa          HIS.00045.2014    Incluir processo de separação de pedidos com numeros de itens maior que o parametrizado para emissão de NFE
    22/01/2014  Andréa          1020.006353.2014  Corrigir processo de retirada de impostos para não retirar 2 vezes
    22/01/2014  Andréa          1020.006353.2014  Gravar poriginal com preço com imposto
    10/02/2014  Andréa          2933.014861.2014  Corrigir alteração de preço de produto cesta com preço fixo
    13/02/2014  Andréa          HIS.00492.2014    Utilizar o parâmetro con_verificaestoquecont em conjunto com o verificaestoquecont da pcparamfilial.
                                                  Se algum deles estiver 'S' irá verificar o estoque contábil
    17/02/2014  Andréa          1972.017825.2014  Corrigir retirada de impostos quando usa o processo de st do RJ
    25/02/2014  Andréa          HIS.00404.2014    Incluir calculo de st do RJ com pauta
    25/02/2014  Andréa          HIS.00433.2014    Incluir calculo de st do RJ para fonte
    26/02/2014  Andréa          1638.019620.2014  Correção retirada de impostos de venda com preço fixo e desconto para st RJ
    06/03/2014  Andréa          1592.025151.2014  Correção em atualização de retorno para pedido complementar
    03/04/2014  Unilson         632.037400.2014   Correção de aplicação do fator preço da embalagem ao preço sem imposto
    28/04/2014  Unilson         HIS.01679.2014    Incluir regra de tipo de bonificação padrão e saldo flex da rotina 3329.
    09/05/2014  Luciano Lima    1612.044186.2014  Correção do calculo do st rj.
    11/06/2014  Luciano Lima       3285.064279.2014   Ajuste referente ao calculo do preço fixo do item, que passava
                                                      o valor incorreto para validacao da campanha do desconto.
    24/06/2014  Luciano Lima    1880.068073.2014 Ajuste no cálculo do simples nacional (alterado também na FUNCOESVENDAS)
    26/06/2014  Luciano Lima       2466.060256.2014   Ajuste na validação das políticas de desconto da 357 e 201
    01/07/2014  Luciano Lima    1519.070585.2014            Ajuste no cálculo do preço sem imposto qdo utilizado fator preço
    05/08/2014  Luciano Lima       2701.080290.2014   Correção no calculo da reducao do simples nacional
    03/10/2014  Luciano Lima       1033.109699.2014   Ajuste no calculo do pbaserca e na verificação sobre credita/debita da cta corrente do rca.
    08/10/2014  Luciano Lima       1937.112646.2014   Corrigida a validação do preço no desconto por quantidade
    */

END; -- INTEGRADORA
