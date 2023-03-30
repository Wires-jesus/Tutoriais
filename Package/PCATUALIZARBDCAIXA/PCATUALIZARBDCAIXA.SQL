CREATE OR REPLACE PACKAGE PCATUALIZARBDCAIXA  is

   -- Criar database link
   PROCEDURE pCriarDatabaseLink (p_SeqCaixa        IN PCCAIXA.NUMCAIXA%TYPE
                                ,p_StringConCaixa  IN VARCHAR2
                                ,p_Usuario         IN VARCHAR2
                                ,p_Senha           IN VARCHAR2);
   -- Apagar database link
   PROCEDURE pApagarDatabaseLink (p_SeqCaixa        IN PCCAIXA.NUMCAIXA%TYPE);

   -- Atualizar tabela PCCAIXA
   PROCEDURE pAtualizarCaixa (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCCLIENT
   PROCEDURE pAtualizarCliente (p_DbLink          IN VARCHAR2
                               ,p_DataInicial     IN PCCLIENT.DTCADASTRO%TYPE DEFAULT NULL
                               ,p_DataFinal       IN PCCLIENT.DTCADASTRO%TYPE DEFAULT NULL
                               ,p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T');
   PROCEDURE pAtualizarCliente (p_DbLink          IN VARCHAR2
                               ,p_IdSequencial    IN PCCLIENT.NUMSEQATU%TYPE);
   -- Atualizar tabela PCCIDADE
   PROCEDURE pAtualizarCidade (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCCOB
   PROCEDURE pAtualizarCobranca (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCMARCA
   PROCEDURE pAtualizarMarca (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCINDICEECF
   PROCEDURE pAtualizarIndiceEcf (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCPLPAGCLI
   PROCEDURE pAtualizarPlanoPagtoCliente (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCTABTRIB
   PROCEDURE pAtualizarTributacaoPorUf (p_DbLink          IN VARCHAR2,
                                        p_CodFilial       IN VARCHAR2,
                                        p_CodProd         IN PCTABTRIB.CODPROD%TYPE,
                                        p_DataInicial     IN PCTABTRIB.DTULTALTER%TYPE DEFAULT NULL,
                                        p_DataFinal       IN PCTABTRIB.DTULTALTER%TYPE DEFAULT NULL,
                                        p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T');
   -- Atualizar tabela PCDESCQUANT
   PROCEDURE pAtualizarDescontoQuantidade (p_DbLink       IN VARCHAR2,
                                           p_CodProd      IN PCDESCQUANT.CODPROD%TYPE);
   -- Atualizar tabela PCDESCONTO
   PROCEDURE pAtualizarPoliticaDesconto (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCPRODFILIAL
   PROCEDURE pAtualizarProdutoFilial (p_DbLink          IN VARCHAR2,
                                      p_CodFilial       IN VARCHAR2,
                                      p_CodProd         IN PCPRODFILIAL.CODPROD%TYPE);
   -- Atualizar tabela PCBANCO
   PROCEDURE pAtualizarBanco (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCCONTATO
   PROCEDURE pAtualizarContato (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCOPERADORACARTAO
   PROCEDURE pAtualizarOperadoraCartao (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCOPERADORACARTAOBIN
   PROCEDURE pAtualizarOperadoraCartaoBin (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCMENSAGEMROTINA
   PROCEDURE pAtualizarMensagemRotina (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCCONSUM
   PROCEDURE pAtualizarParametros (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCEMBALAGEM
   PROCEDURE pAtualizarEmbalagem (p_DbLink          IN VARCHAR2
                                 ,p_NumRegiao       IN PCTABPR.NUMREGIAO%TYPE DEFAULT 1
                                 ,p_DataInicial     IN PCEMBALAGEM.DTULTALTPVENDA%TYPE DEFAULT NULL
                                 ,p_DataFinal       IN PCEMBALAGEM.DTULTALTPVENDA%TYPE DEFAULT NULL
                                 ,p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T'
                                 ,p_CodProd         IN PCEMBALAGEM.CODPROD%TYPE);
   PROCEDURE pAtualizarEmbalagem (p_DbLink          IN VARCHAR2
                                 ,p_IdSequencial    IN PCEMBALAGEM.NUMSEQATU%TYPE);
   -- Atualizar tabela PCEMPR
   PROCEDURE pAtualizarFuncionarios (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCEST
   PROCEDURE pAtualizarEstoque (p_DbLink          IN VARCHAR2
                               ,p_CodFilial       IN PCEST.CODFILIAL%TYPE DEFAULT '1'
                               ,p_CodProd         IN PCEST.CODPROD%TYPE
                               ,p_NumRegiao       IN PCTABPR.NUMREGIAO%TYPE DEFAULT 1
                               ,p_DataInicial     IN PCEST.DTULTENT%TYPE DEFAULT NULL
                               ,p_DataFinal       IN PCEST.DTULTENT%TYPE DEFAULT NULL
                               ,p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T');
   -- Atualizar tabela PCPLPAG
   PROCEDURE pAtualizarPlanoPag (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCPRACA
   PROCEDURE pAtualizarPraca (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCTABPR
   PROCEDURE pAtualizarPrecos (p_DbLink          IN VARCHAR2
                              ,p_NumRegiao       IN PCTABPR.NUMREGIAO%TYPE DEFAULT 1
                              ,p_DataInicial     IN PCTABPR.DTULTALTPVENDA%TYPE DEFAULT NULL
                              ,p_DataFinal       IN PCTABPR.DTULTALTPVENDA%TYPE DEFAULT NULL
                              ,p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T'
                              ,p_CodProd         IN PCTABPR.CODPROD%TYPE);
   PROCEDURE pAtualizarPrecos (p_DbLink          IN VARCHAR2
                              ,p_IdSequencial    IN PCCLIENT.NUMSEQATU%TYPE);
   -- Atualizar tabela PCTRIBUT
   PROCEDURE pAtualizarTributacao (p_DbLink          IN VARCHAR2);
   PROCEDURE pAtualizarTributacao (p_DbLink          IN VARCHAR2
                                  ,p_IdSequencial    IN PCCLIENT.NUMSEQATU%TYPE);
   -- Atualizar tabela PCPRECOPROM
   PROCEDURE pAtualizarPrecoPromo (p_DbLink          IN VARCHAR2
                                   ,p_CodProd         IN PCPRECOPROM.CODPROD%TYPE);
   -- Atualizar tabela PCCONTROI
   PROCEDURE pAtualizarControI (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCLIB
   PROCEDURE pAtualizarPcLib (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCFORMPROD
   PROCEDURE pAtualizarCompCestaBasica (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCFILIAL
   PROCEDURE pAtualizarFilial (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCATIVI
   PROCEDURE pAtualizarRamosAtividade (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCREGIAO
   PROCEDURE pAtualizarRegiao (p_DbLink          IN VARCHAR2);
   -- Atualizar tabela PCPRODUT
   PROCEDURE pAtualizarProduto (p_DbLink          IN VARCHAR2
                               ,p_NumRegiao       IN PCTABPR.NUMREGIAO%TYPE DEFAULT 1
                               ,p_DataInicial     IN DATE DEFAULT NULL
                               ,p_DataFinal       IN DATE DEFAULT NULL
                               ,p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T'
                               ,p_CodProd         IN PCPRODUT.CODPROD%TYPE);
   PROCEDURE pAtualizarProduto (p_DbLink          IN VARCHAR2
                               ,p_IdSequencial    IN PCPRODUT.NUMSEQATU%TYPE);
   -- Atualizar tabela PCAUTORI
   PROCEDURE pAtualizarAutorizacao (p_DbLink          IN VARCHAR2
                                   ,p_NumCaixa        IN PCCAIXA.NUMCAIXA%TYPE
                                   ,p_DataInicial     IN DATE DEFAULT NULL
                                   ,p_DataFinal       IN DATE DEFAULT NULL
                                   ,p_TipoAtualizacao IN VARCHAR2 DEFAULT 'T'
                                   ,p_CodProd         IN PCAUTORI.CODPROD%TYPE);
   -- Atualizar tabela PCUSUARI
   PROCEDURE pAtualizarUsuario (p_DbLink          IN VARCHAR2);

   -- Atualizar cabeçalho de preço fixo de cesta básica
   PROCEDURE pAtualizarPcPrecoCestaC (p_DbLink IN VARCHAR2);

   -- Atualizar itens de preço fixo de cesta básica
   PROCEDURE pAtualizarPcPrecoCestaI (p_DbLink In VARCHAR2);

   -- Atualizar tabela PCCONSUM, campo DTATUALIZACAOBD.
   PROCEDURE pAtualizarParamDtAtualizacaoBD (p_DbLink          IN VARCHAR2);

   -- Atualizar tabelas que sofreram alteração no servidor através de job,
   -- sem a intervenção manual.
   PROCEDURE pAtualizarParcialJob;

END PCAtualizarBDCaixa ;
