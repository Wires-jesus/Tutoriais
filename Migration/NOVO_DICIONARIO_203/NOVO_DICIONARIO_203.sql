DECLARE
  --steps principais
  V_STEP_1 CONSTANT VARCHAR2(50) := '01-Informações Gerais';
  V_STEP_2 CONSTANT VARCHAR2(50) := '02-Compra/Venda';
  V_STEP_3 CONSTANT VARCHAR2(50) := '03-Tributos';
  V_STEP_4 CONSTANT VARCHAR2(50) := '04-Logística';
  --step de todos campos modificados pelo cliente
  V_STEP_5 CONSTANT VARCHAR2(50) := '05-Customizados ';
  --steps de todos os campos que não são principais

  V_STEP_8  CONSTANT VARCHAR2(50) := '08-Medicamentos';
  V_STEP_9  CONSTANT VARCHAR2(50) := '09-Autopeças';
  V_STEP_10 CONSTANT VARCHAR2(50) := '10-Integração ecommerce';



  V_CODIGOROTINA CONSTANT PCDICIONARIOITEMROT.CODROTINA%TYPE := 203;
  V_OBJETO       CONSTANT PCDICIONARIOITEMROT.NOMEOBJETO%TYPE := 'PCPRODUT';
  V_CONTADOR NUMBER(10) := 1;

  TYPE ARRAY_CAMPOS IS VARRAY(100) OF VARCHAR2(100);
  V_LISTA_CAMPOS ARRAY_CAMPOS;

  PROCEDURE ATUALIZASECAODICIONARIO(PSECAO      IN VARCHAR2,
                                    POBJETO     IN VARCHAR2,
                                    PCODROTINA  IN NUMBER,
                                    PLISTACAMPO IN ARRAY_CAMPOS,
                                    PCAMPOVISIVEL IN VARCHAR) IS
  BEGIN
    FOR I IN 1 .. PLISTACAMPO.COUNT
    LOOP
      UPDATE PCDICIONARIOITEMROT
         SET PCDICIONARIOITEMROT.SECAO    = PSECAO
            ,PCDICIONARIOITEMROT.ORDEMCAD = I
            ,PCDICIONARIOITEMROT.VISIVEL  = PCAMPOVISIVEL
       WHERE PCDICIONARIOITEMROT.NOMECAMPO = PLISTACAMPO(I)
         AND PCDICIONARIOITEMROT.NOMEOBJETO = POBJETO
         AND PCDICIONARIOITEMROT.CODROTINA = PCODROTINA;
    END LOOP;
  END;

  PROCEDURE ATUALIZACAMPOS_NAOOBRIGATORIOS IS
  BEGIN
    V_LISTA_CAMPOS := ARRAY_CAMPOS('ACEITAVENDAFRACAO', 'CODCATEGORIA',
                                   'CODFAB', 'CODPRODPRINC', 'CODTABLIT',
                                   'CODGRULIT', 'CODPRODFORNEC', 'CODFILIAL',
                                   'CODINFNUTRI', 'CODPRODANTUTICAD',
                                   'CODVASILHAME', 'CODPRODMASTER', 'CODCOR',
                                   'DADOSTECNICOS', 'DTINICODPRODANTUTICAD',
                                   'DTPRIMOVNOVCODPROD',
                                   'DESTAQUEFICHATECNICA', 'DIRFOTOPROD',
                                   'CODFILIALRETIRA', 'OBS2', 'CODGRADE',
                                   'INFORMACOESTECNICAS', 'SEQPAGINA',
                                   'CODLINHAPROD', 'CODMARCA', 'MULTIPLO',
                                   'NATUREZAPRODUTO', 'OBS', 'PAISORIGEM',
                                   'UTILIZARVASILHAME', 'QTUNITCX',
                                   'QTDEMAXSEPARPEDIDO', 'QTUNIT', 'REVENDA',
                                   'SEQTABPRECO', 'STATUS', 'CODSUBCATEGORIA',
                                   'COLUNAGRADE', 'TIPOMERC', 'UNIDADE',
                                   'UNIDADEMASTER', 'USAWMS',
                                   'USACLASSIFICACAO', 'VLMAODEOBRA');
  
    ATUALIZASECAODICIONARIO(V_STEP_1 || '\07-Informações adicionais',
                            V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('DESCRICAO1', 'DESCRICAO2', 'DESCRICAO3',
                                   'DESCRICAO4', 'DESCRICAO5', 'DESCRICAO6',
                                   'DESCRICAO7');
  
    ATUALIZASECAODICIONARIO(V_STEP_1 || '\08-Especificação do produto',
                            V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('REGISTROPECA',
                                   'DTFINUTICODPRODANTUTICAD', 'IDEMBALAGEM',
                                   'DSCPRODANTUTICAD');
  
    ATUALIZASECAODICIONARIO(V_STEP_1 || '\09-Outras informações', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('DV', 'NUMORIGINAL', 'CODSUBMARCA',
                                   'UNIDADEPADRAO');
  
    ATUALIZASECAODICIONARIO(V_STEP_1 || '\10-Capa', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('CODFUNCCADASTRO', 'CODFUNCULTALTER',
                                   'CODFUNCULTALTCAD', 'DTEXCLUSAO',
                                   'DTULTALTCOM', 'DTULTALTER', 'DTULTALTCAD',
                                   'DTCADASTRO');
  
    ATUALIZASECAODICIONARIO(V_STEP_1 || '\11-Dados do Sistema', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('CLASSEMC');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\06-Capa', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PASSELIVRE', 'CAMPANHA',
                                   'CODPASSEFISCAL', 'CONTROLAPATRIMONIO',
                                   'CONTROLADOIBAMA');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\07-Condições de venda', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('IDDESTAQUE');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 ||
                            '\08-Tributação entrada Importação', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('VERIFCRAMOATIVCALCST');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\09-Tributação Outros', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('NUMPAG', 'LETRAPAGINA');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\10-Tributação Outros', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('MOEDA', 'PRECOFABRICA', 'PRECOFIXO',
                                   'PRECOMAXCONSUM', 'PRECOMAXCONSUMTAB',
                                   'SUGVENDA', 'PRECIFICESTRANGEIRA');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\11-Precificação', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('MARGEMMIN', 'CLASSE', 'CLASSEVENDA',
                                   'DIASCONSECENT', 'ENVIARFORCAVENDAS',
                                   'PRAZOMAXINDENIZACAO');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\12-Vendas/Geral', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PCOMREP1', 'PCOMEXT1', 'PCOMINT1',
                                   'CLASSECOMISSAO', 'TIPOCOMISSAO');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\13-Comissão de venda', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PERCBONIFICVENDA', 'PERMITIRBROKERTV5',
                                   'CHECARMULTIPLOVENDABNF');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\14-Bonificação de Venda',
                            V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PERCBON', 'PERCBONOUTRAS', 'PERCDESC1',
                                   'PERCDESC2', 'PERCDESC3', 'PERCDESC4',
                                   'PERCDESC5', 'PERCDESC6', 'PERCDESC7',
                                   'PERCDESC8', 'PERCDESC9', 'PERCDESC10',
                                   'CLASSECOMPRA', 'CONCILIAIMPORTACAO',
                                   'DTDOLAR', 'MULTIPLOCOMPRAS',
                                   'CODPRAZOENT', 'CUSTOREPTAB', 'IMPORTADO',
                                   'QTMINSUGCOMPRA', 'ANTIDUMPING',
                                   'TEMREPOS', 'TIPOEMBARQUEIMP',
                                   'COMPRACONSIGNADO', 'USALICENCAIMPORTACAO',
                                   'CUSTOREP', 'VLBONIFIC');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\15-Geral/Compra', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('CODFORMATOPAPEL', 'GRAMATURA');
  
    ATUALIZASECAODICIONARIO(V_STEP_2 || '\16-Papelaria', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PERCALIQEXT', 'PERCALIQINT',
                                   'PERCPRODEIC', 'PERCOFINS',
                                   'LICITPERCDESONERACAP',
                                   'LICITPERCDESONERAICM', 'PERCFRETE',
                                   'PERCFRETEFOB', 'PERICM',
                                   'PERICMSANTECIPADO', 'PERCICMRED',
                                   'PERCIPI', 'PERCIVA', 'PERCOUTRASDESP',
                                   'PERPIS', 'PERCDESPADICIONAL', 'PERCVENDA',
                                   'PERCSUFRAMA', 'ALIQUOTATCIF',
                                   'ICMSRESSARC', 'IVARESSARC',
                                   'PISCOFINSRETIDO', 'VPART', 'VLPAUTA');
  
    ATUALIZASECAODICIONARIO(V_STEP_3 || '\04-Alíquotas', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('OBSCONTXCAMPO', 'OBSFISCOXCAMPO',
                                   'CESTABASICALEGIS', 'CLASSIFICFISCAL',
                                   'CODUNIDMEDIDANF', 'CODAGREGACAO',
                                   'CODINTERNO', 'LICITCONVENIOISENCAOICMS',
                                   'DESCANP', 'ENVIAINFTECNICANFE', 'EXTIPI',
                                   'FATORCONVTRIB', 'FATORCONVTRIBEX',
                                   'FUNDAPIANO', 'IMUNETRIB', 'PERINDENIZ',
                                   'ISENTOSTCOZINHAINDUSTRIAL', 'ISENTOTCIF',
                                   'PREDOMINANCIA', 'OBSCONTXTEXTO',
                                   'OBSFISCOXTEXTO', 'PERCDESC',
                                   'UNIDADETRIB', 'UNIDADETRIBEX',
                                   'LICITUSARCAP', 'LICITUSARDESONERAICM',
                                   'UTILIZASELO', 'USACODAGREGACAO');
  
    ATUALIZASECAODICIONARIO(V_STEP_3 || '\05-Geral', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('BLOQUEIOACORDOPARCERIA',
                                   'CODCLASSETERAPEUTSNGPC',
                                   'CODSAZONALIDADEMED', 'CODLINHAPRAZO',
                                   'ANVISA', 'SIMPRO', 'GRAMATURALICIT',
                                   'GRUPOFATURAMENTO', 'CODMOTISENCAOANVISA',
                                   'REGISTROMSMED', 'PMPFMEDICAMENTO',
                                   'CODPRINCIPATIVO', 'CODPRINCIPATIVO2',
                                   'FARMACIAPOPULAR', 'PSICOTROPICO',
                                   'RETINOICO', 'TIPOCUSTOTRANSF',
                                   'TIPOMEDICAMENTO', 'TIPOTRIBUTMEDIC',
                                   'USOPROLONGADOSNGPC',
                                   'UTILIZAPRECOFABRICA',
                                   'UTILIZAPRECOMAXCONSUMIDOR');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('DENSIDADE', 'DESCPAPEL', 'CONCENTRACAO',
                                   'CODPRODSINTEGRA');
  
    ATUALIZASECAODICIONARIO(V_STEP_3 || '\06-Informações adicionais',
                            V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('COMODATO');
  
    ATUALIZASECAODICIONARIO(V_STEP_3 || '\07-Especificação do produto',
                            V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('NUMREGAGRMAP');
  
    ATUALIZASECAODICIONARIO(V_STEP_3 || '\08-Outras informações', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('CODPRODENGRADADO', 'PRODUSAENGRADADO',
                                   'FATCONVPRODENGRAD', 'PROXNUMLOTE');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\05-Vasilhame', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PROXNUMLOTE', 'PREFIXOLOTE', 'INDUZLOTE');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\06-Lote', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('NORMAFORNECEDOR');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\07-Palete', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PERMITEMULTIPLICACAOPDV', 'PESOMINIMO',
                                   'PESOLIQDI', 'PESOMAXIMO', 'CODRISCO',
                                   'PERCDIFERENCAKGFRIO', 'PERCPERDAKG',
                                   'FATORCONVERSAOKG', 'PESOBRUTO',
                                   'PESOBRUTOFRETE', 'PESOEMBALAGEM',
                                   'PESOPECA', 'PESOLIQ', 'PESOBRUTOMASTER',
                                   'PESOVARIAVEL', 'VALORTARAPORPECA',
                                   'TARAPORPECA');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\08-Peso', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('CODONU', 'DTVENC', 'CODACONDICIONAMENTO');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\09-Armazenagem', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('TAMANHOPECA');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\10-Dimensões', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('TAMANHOPECA');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\11-Dimensões', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PRAZOMAXVALIDADE', 'PRAZOMINVALIDADE',
                                   'CONTROLAVALIDADEDOLOTE', 'DTINICONTLOTE',
                                   'NUMLISTAINVENTROT', 'NUMLOTE',
                                   'NUMSEQINVENTROT', 'ESTOQUEPORLOTE');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\12-Lote', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('ALTURAPAL', 'ALTURATOTAL', 'APTO',
                                   'CLASSEESTOQUE', 'DIAMETROEXTERNO',
                                   'DIAMETROINTERNO', 'CODPRODEMBALAGEM',
                                   'EMBALAGEM', 'EMBALAGEMMASTER',
                                   'LASTROPAL', 'LITRAGEM', 'MODULO',
                                   'NUMERO', 'TIPOPROD', 'QTTOTPAL',
                                   'QTMETROS', 'RUA', 'TIPOESTOQUE',
                                   'TIPOALTURAPALETE', 'CODAUXILIAR2',
                                   'CODAUXILIAR', 'VOLUME');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\13-Armazenagem', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('EXPORTABALANCA', 'TIPOVOLUMEDESCARGA',
                                   'CODAGRUPMAPASEP');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\14-Separação/Checkout', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PRAZOMEDIOVENDA');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\15-Condições de venda', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('TIPODESCARGA', 'FRETEESPECIAL',
                                   'NUMDIASVALIDADEMIN', 'PRAZOMAXVENDA',
                                   'PRAZOGARANTIA');
  
    ATUALIZASECAODICIONARIO(V_STEP_4 || '\16-Geral', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('FORMAESTERILIZACAO', 'CODSALMED',
                                   'CONVENIOISENCAOICMSMED',
                                   'BLOQUEIOACORDOPARCERIA',
                                   'CODCLASSETERAPEUTSNGPC',
                                   'CODSAZONALIDADEMED', 'CODLINHAPRAZO',
                                   'ANVISA', 'SIMPRO', 'GRAMATURALICIT',
                                   'GRUPOFATURAMENTO', 'CODMOTISENCAOANVISA',
                                   'REGISTROMSMED', 'PMPFMEDICAMENTO',
                                   'CODPRINCIPATIVO', 'CODPRINCIPATIVO2',
                                   'FARMACIAPOPULAR', 'PSICOTROPICO',
                                   'RETINOICO', 'TIPOCUSTOTRANSF',
                                   'TIPOMEDICAMENTO', 'TIPOTRIBUTMEDIC',
                                   'USOPROLONGADOSNGPC',
                                   'UTILIZAPRECOFABRICA',
                                   'UTILIZAPRECOMAXCONSUMIDOR',
                                   'FORMAESTERILIZACAO', 'CODSALMED',
                                   'CONVENIOISENCAOICMSMED');
  
    ATUALIZASECAODICIONARIO(V_STEP_8 || '\01-Geral', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('ACEITATROCAINSERVIVEL', 'CARCACABATERIA',
                                   'CODINSERVIVEL', 'STATUSSUCATA');
  
    ATUALIZASECAODICIONARIO(V_STEP_9 || '\01-Inservível', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('PGNI', 'PGNN', 'PGLP');
  
    ATUALIZASECAODICIONARIO(V_STEP_9 || '\02-GPL', V_OBJETO, V_CODIGOROTINA,
                            V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('ANP');
  
    ATUALIZASECAODICIONARIO(V_STEP_9 || '\03-ANP', V_OBJETO, V_CODIGOROTINA,
                            V_LISTA_CAMPOS,'N');
  
    V_LISTA_CAMPOS := ARRAY_CAMPOS('SUBTITULOECOMMERCE', 'CODCAMPLOMADEE',
                                   'CODADWORDS', 'DIRETORIOFOTOS', 'MYFROTA',
                                   'EXIBESEMESTOQUEECOMMERCE',
                                   'FATORCONVERSAOBIONEXO', 'NOMEECOMMERCE',
                                   'EMBVENDAECOMMERCEUNILEVER',
                                   'TIPOINTEGRACAOB2B', 'TITULOECOMMERCE',
                                   'LINKID', 'USAECOMMERCEUNILEVER',
                                   'UTILIZAINTEGRACAOKIBON', 'ENVIAECOMMERCE');
  
    ATUALIZASECAODICIONARIO(V_STEP_10 || '\01-Integrações', V_OBJETO,
                            V_CODIGOROTINA, V_LISTA_CAMPOS,'N');
  
  END;

BEGIN
  UPDATE PCDICIONARIOITEMROT
     SET VISIVEL = 'N'
   WHERE NOMEOBJETO = V_OBJETO
     AND CODROTINA = V_CODIGOROTINA;

  ATUALIZACAMPOS_NAOOBRIGATORIOS;

  V_LISTA_CAMPOS := ARRAY_CAMPOS('CODPROD', 'DESCRICAO', 'CODFORNEC',
                                 'CODEPTO', 'CODSEC', 'CODMARCA',
                                 'CODCATEGORIA', 'CODLINHAPROD', 'TIPOMERC',
                                 'NATUREZAPRODUTO');

  ATUALIZASECAODICIONARIO(V_STEP_1 || '\01-Descrição do Produto', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('EMBALAGEM', 'UNIDADE', 'QTUNIT',
                                 'EMBALAGEMMASTER', 'UNIDADEMASTER',
                                 'QTUNITCX');

  ATUALIZASECAODICIONARIO(V_STEP_1 || '\02-Informações da Embalagem',
                          V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('PESOLIQ', 'PESOBRUTO');

  ATUALIZASECAODICIONARIO(V_STEP_1 || '\03-Informações de Peso', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('CODNCMEX', 'NBM', 'EXTIPI');

  ATUALIZASECAODICIONARIO(V_STEP_1 || '\04-Tributos', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('CODAUXILIARTRIB', 'GTINCODAUXILIARTRIB',
                                 'GTINCODAUXILIAR', 'CODAUXILIAR',
                                 'GTINCODAUXILIAR2', 'CODAUXILIAR2');

  ATUALIZASECAODICIONARIO(V_STEP_1 ||
                          '\05-Informações de Código de Barras', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('CODFAB', 'CODPRODMASTER', 'CODPRODPRINC',
                                 'ENVIAINFTECNICANFE', 'INFORMACOESTECNICAS',
                                 'DADOSTECNICOS');

  ATUALIZASECAODICIONARIO(V_STEP_1 || '\06-Informações Adicionais',
                          V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  --Segundo Step                           
  V_LISTA_CAMPOS := ARRAY_CAMPOS('CHECARMULTIPLOVENDABNF',
                                 'ENVIARFORCAVENDAS', 'ACEITAVENDAFRACAO',
                                 'PERCBONIFICVENDA', 'CLASSEVENDA', 'CLASSE',
                                 'MARGEMMIN', 'PRECOFIXO',
                                 'PRECOMAXCONSUMTAB', 'PRECOMAXCONSUM',
                                 'MULTIPLO');

  ATUALIZASECAODICIONARIO(V_STEP_2 || '\01-Informações da venda', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('PCOMEXT1', 'PCOMINT1', 'PCOMREP1',
                                 'TIPOCOMISSAO');

  ATUALIZASECAODICIONARIO(V_STEP_2 || '\02-Informações de vendedor',
                          V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('VLBONIFIC', 'CODPRAZOENT', 'CUSTOREP',
                                 'CUSTOREPTAB', 'MULTIPLOCOMPRAS',
                                 'PERCBONOUTRAS', 'TEMREPOS',
                                 'QTMINSUGCOMPRA', 'DESTAQUEFICHATECNICA',
                                 'SUGVENDA', 'CODFILIAL');

  ATUALIZASECAODICIONARIO(V_STEP_2 || '\03-Informações da compra', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('CONCILIAIMPORTACAO', 'IMPORTADO',
                                 'USALICENCAIMPORTACAO', 'MOEDA', 'PERCDESC1',
                                 'PERCDESC2', 'PERCDESC3', 'PERCDESC4',
                                 'PERCDESC5', 'PERCDESC6', 'PERCDESC7',
                                 'PERCDESC8', 'PERCDESC9', 'PERCDESC10',
                                 'TIPOEMBARQUEIMP');

  ATUALIZASECAODICIONARIO(V_STEP_2 || '\04-Informações da importação',
                          V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('PERCFRETE', 'PERCFRETEFOB');

  ATUALIZASECAODICIONARIO(V_STEP_2 || '\05-Frete de compra', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  --Terceiro Step                           
  V_LISTA_CAMPOS := ARRAY_CAMPOS('UNIDADETRIB', 'CESTABASICALEGIS');

  ATUALIZASECAODICIONARIO(V_STEP_3 ||
                          '\01-Informações Adicionais de tributos', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('UNIDADETRIBEX', 'FATORCONVTRIB',
                                 'FATORCONVTRIBEX', 'ISENTOTCIF');

  ATUALIZASECAODICIONARIO(V_STEP_3 || '\02-Tributos exterior', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('LICITUSARDESONERAICM',
                                 'LICITPERCDESONERAICM');

  ATUALIZASECAODICIONARIO(V_STEP_3 || '\03-Desoneração de ICMS', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  --Quarto Step                           
  V_LISTA_CAMPOS := ARRAY_CAMPOS('PAISORIGEM', 'CODDISTRIB', 'USAWMS',
                                 'CONFERENOCHECKOUT', 'RESTRICAOTRANSP',
                                 'EXPORTABALANCA', 'PRAZOVAL');

  ATUALIZASECAODICIONARIO(V_STEP_4 || '\01-Informações de logística',
                          V_OBJETO, V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('TIPOESTOQUE', 'APTO', 'MODULO',
                                 'LASTROPAL');

  ATUALIZASECAODICIONARIO(V_STEP_4 || '\02-Informações de lote', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('TIPOPROD', 'TIPOVOLUMEDESCARGA', 'VOLUME',
                                 'ALTURA');

  ATUALIZASECAODICIONARIO(V_STEP_4 || '\03-Armazenagem', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  V_LISTA_CAMPOS := ARRAY_CAMPOS('PESOBRUTOMASTER', 'PESOEMBALAGEM',
                                 'PESOPECA', 'PESOVARIAVEL', 'PERCPERDAKG',
                                 'PERCDIFERENCAKGFRIO', 'FATORCONVERSAOKG');

  ATUALIZASECAODICIONARIO(V_STEP_4 || '\04-Informações de peso', V_OBJETO,
                          V_CODIGOROTINA, V_LISTA_CAMPOS,'S');

  FOR CUSTOMIZADOS IN (SELECT PCDICIONARIOITEMROTCUST.*
                             ,PCDICIONARIOITEMROTCUST.ROWID AS R_ID
                         FROM PCDICIONARIOITEMROTCUST
                        WHERE PCDICIONARIOITEMROTCUST.CODROTINA =
                              V_CODIGOROTINA
                          AND PCDICIONARIOITEMROTCUST.NOMEOBJETO = V_OBJETO
                        ORDER BY PCDICIONARIOITEMROTCUST.SECAO
                                ,PCDICIONARIOITEMROTCUST.ORDEMCAD)
  LOOP
  
    UPDATE PCDICIONARIOITEMROTCUST
       SET PCDICIONARIOITEMROTCUST.SECAO    = V_STEP_5
          ,PCDICIONARIOITEMROTCUST.ORDEMCAD = V_CONTADOR
     WHERE PCDICIONARIOITEMROTCUST.ROWID = CUSTOMIZADOS.R_ID;
  
    V_CONTADOR := V_CONTADOR + 1;
  END LOOP;

  UPDATE PCDICIONARIO
     SET DESCRICAO = 'Produto'
   WHERE NOMEOBJETO = 'PCPRODUT';

  COMMIT;

END;
