CREATE OR REPLACE PROCEDURE PCExecutarAtualiBdCaixa (p_Tabelas          IN VARCHAR2
                                                    ,p_NumCaixa         IN NUMBER
                                                    ,p_TipoAtualizacao  IN VARCHAR2
                                                    ,p_DataInicial      IN DATE DEFAULT NULL
                                                    ,p_DataFinal        IN DATE DEFAULT NULL
                                                    ,p_NumRegiao        IN NUMBER DEFAULT 1
                                                    ,p_CodFilial        IN VARCHAR2 DEFAULT '1'
                                                    ,p_CodProd          IN NUMBER DEFAULT 0
                                                    ,p_MensRetorno      OUT VARCHAR2)
is
   v_Retorno                                         VARCHAR2(32767) := NULL;
   v_Sql                                             VARCHAR2(200);
   v_Contador                                        NUMBER;
   v_TipoAtualizacao                                 VARCHAR2(1) := p_TipoAtualizacao;
   v_DbLink                                          VARCHAR2(100) := 'DBLCAIXA'||p_NumCaixa;
begin
   -- Alterar sessão pra desconsiderar nome de database link com a extensão do DOMAIN_NAME
   -- do SQLNET.ORA
   v_Sql := 'ALTER SESSION SET GLOBAL_NAMES = FALSE';
   EXECUTE IMMEDIATE v_Sql;

   -- Alterar sessão pra considerar a data no format dd/mm/rrrr
   v_Sql := 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/RRRR''';
   EXECUTE IMMEDIATE v_Sql;

   -- Obter a data da última atualização do BD do Caixa. Esta consulta é utilizada também
   -- para verificar se o database link está ativo e comunicável. As próximas rotinas só
   -- serão executadas caso não haja retorno negativo quanto a comunicação com o caixa. 
   BEGIN
      v_Sql := 'SELECT COUNT(DTATUALIZACAOBD) '||
                 'FROM PCCONSUM@'||v_DbLink||
                 ' WHERE ROWNUM <= 1';
      EXECUTE IMMEDIATE v_Sql INTO v_Contador;
      -- Se não houver valor na data de atualização ou não houver registros na tabela,
      -- o banco de dados do caixa ainda não foi atualizado. Neste caso será feita
      -- atualização TOTAL (T).
      IF v_Contador = 0 THEN
         v_TipoAtualizacao := 'T';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN 
         v_Retorno := 'Não foi possível estabelecer conexão com o caixa especificado, verifique!'
                      ||chr(13)||SQLERRM;
   END;
   
   -- Verificar se não houve erro na tentativa de comunicação com o database link.
   -- Caso não haja erro, serão executadas as rotinas de atualização das tabelas informadas.
   IF v_Retorno IS NULL THEN
   
      -- Atualizar tabela PCCAIXA. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCCAIXA|%' THEN
         BEGIN
            PCAtualizarBDCaixa.pAtualizarCaixa(p_DbLink => v_DbLink);
            COMMIT;
         EXCEPTION 
            WHEN OTHERS THEN 
               v_Retorno := v_Retorno||' Tabela PCCAIXA - Erro: '||SQLERRM||chr(13);
               ROLLBACK;
         END;
      END IF;

      -- Atualizar tabela PCCLIENT. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCCLIENT|%' THEN
         BEGIN
            PCAtualizarBDCaixa.pAtualizarCliente (p_DbLink => v_DbLink
                                                 ,p_TipoAtualizacao => v_TipoAtualizacao
                                                 ,p_DataInicial => p_DataInicial
                                                 ,p_DataFinal => p_DataFinal);
            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               v_Retorno := v_Retorno||' Tabela PCCLIENT - Erro:  '||SQLERRM||chr(13);
               ROLLBACK;
         END;
      END IF;
      -- Atualizar tabela PCPRECOCESTAC - Cabeçalho de preço fixo da cesta básica
      IF p_Tabelas LIKE '%|PCPRECOCESTAC|%' THEN
         BEGIN
            PCAtualizarBDCaixa.pAtualizarPcPrecoCestaC (p_DbLink => v_DbLink);
            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               v_Retorno := v_Retorno||' Tabela PCPRECOCESTAC - Erro:  '||SQLERRM||chr(13);
               ROLLBACK;
         END;
      END IF;

      -- Atualizar tabela PCPRECOCESTAI - Itens de preço fixo da cesta básica
      IF p_Tabelas LIKE '%|PCPRECOCESTAI|%' THEN
         BEGIN
            PCAtualizarBDCaixa.pAtualizarPcPrecoCestaI (p_DbLink => v_DbLink);
            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               v_Retorno := v_Retorno||' Tabela PCPRECOCESTAI - Erro:  '||SQLERRM||chr(13);
               ROLLBACK;
         END;
      END IF;

      -- Atualizar tabela PCCIDADE. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCCIDADE|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarCidade(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCCIDADE - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCPLPAGCLI. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCPLPAGCLI|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPlanoPagtoCliente(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCPLPAGCLI - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCCOB. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCCOB|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarCobranca(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCCOB - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCMARCA. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCMARCA|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarMarca(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCMARCA - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCINDICEECF. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCINDICEECF|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarIndiceEcf(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCINDICEECF - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Tarefa N.55781 - Juliana Teixeira - 20/12/2007;
      -- Atualizar tabela PCTABTRIB. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCTABTRIB|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarTributacaoPorUf(p_DbLink => v_DbLink,
                                                        p_CodFilial => p_CodFilial,
                                                        p_CodProd => p_CodProd,
                                                        p_TipoAtualizacao => v_TipoAtualizacao,
                                                        p_DataInicial => p_DataInicial,
                                                        p_DataFinal => p_DataFinal);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCTABTRIB - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Tarefa N.49573 - Juliana Teixeira - 11/09/2007;
      -- Atualizar tabela PCDESCQUANT. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCDESCQUANT|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarDescontoQuantidade(p_DbLink => v_DbLink, p_CodProd => p_CodProd);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCDESCQUANT - Erro:'||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Tarefa N.67951 - Juliana Teixeira - 29/08/2007;
      -- Atualizar tabela PCPRODFILIAL. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCPRODFILIAL|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarProdutoFilial(p_DbLink => v_DbLink, p_CodFilial => p_CodFilial, p_CodProd => p_CodProd);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCPRODFILIAL - Erro:'||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- 29/12/2006 - Juliana
      -- Atualizar tabela PCBANCO.
      IF p_Tabelas LIKE '%|PCBANCO|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarBanco(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCBANCO - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- 25/04/2009 - Juliana
      -- Atualizar tabela PCDESCONTO.
      IF p_Tabelas LIKE '%|PCDESCONTO|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPoliticaDesconto(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCDESCONTO - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;


      -- 13/04/2009 - Juliana
      -- Atualizar tabela PCCONTATO.
      IF p_Tabelas LIKE '%|PCCONTATO|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarContato(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCCONTATO - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- 03/04/2009 - Juliana
      -- Atualizar tabela PCOPERADORACARTAO.
      IF p_Tabelas LIKE '%|PCOPERADORACARTAO|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizaroperadoracartao(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCOPERADORACARTAO - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      IF p_Tabelas LIKE '%|PCOPERADORACARTAOBIN|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizaroperadoracartaobin(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCOPERADORACARTAOBIN - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- 07/10/2008 - Juliana
      -- Atualizar tabela PCMENSAGEMROTINA.
      IF p_Tabelas LIKE '%|PCMENSAGEMROTINA|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarMensagemRotina(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCMENSAGEMROTINA - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCCONSUM. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCCONSUM|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarParametros(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCCONSUM - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCEMBALAGEM. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCEMBALAGEM|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarEmbalagem(p_DbLink => v_DbLink
                                                 ,p_TipoAtualizacao => v_TipoAtualizacao
                                                 ,p_DataInicial => p_DataInicial
                                                 ,p_DataFinal => p_DataFinal
                                                 ,p_NumRegiao => p_NumRegiao
                                                 ,p_CodProd => p_CodProd);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCEMBALAGEM - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCEMPR. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCEMPR|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarFuncionarios(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCEMPR - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCEST. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCEST|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarEstoque(p_DbLink => v_DbLink
                                               ,p_CodFilial => p_CodFilial
                                               ,p_NumRegiao => p_NumRegiao
                                               ,p_CodProd => p_CodProd
                                               ,p_TipoAtualizacao => v_TipoAtualizacao
                                               ,p_DataInicial => p_DataInicial
                                               ,p_DataFinal => p_DataFinal);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCEST - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCPLPAG. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCPLPAG|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPlanoPag(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCPLPAG - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCPRACA. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCPRACA|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPraca(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCPRACA - Erro:'||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCTABPR. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCTABPR|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPrecos(p_DbLink => v_DbLink
                                              ,p_NumRegiao => p_NumRegiao
                                              ,p_CodProd => p_CodProd
                                              ,p_TipoAtualizacao => v_TipoAtualizacao
                                              ,p_DataInicial => p_DataInicial
                                              ,p_DataFinal => p_DataFinal);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||' Tabela PCTABPR - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCTRIBUT. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCTRIBUT|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarTributacao(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION 
           WHEN OTHERS THEN 
              v_Retorno := v_Retorno||' Tabela PCTRIBUT -Erro:  '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;
      
      -- Atualizar tabela PCPRECOPROM. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCPRECOPROM|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPrecoPromo(p_DbLink => v_DbLink, p_CodProd => p_CodProd);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCPRECOPROM - '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCCONTROI. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCCONTROI|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarControI(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCCONTROI - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCLIB. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCLIB|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarPcLib(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCLIB - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCFORMPROD. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCFORMPROD|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarCompCestaBasica(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCFORMPROD - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCFILIAL. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCFILIAL|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarFilial(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCFILIAL - Erro:'||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCATIVI. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCATIVI|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarRamosAtividade(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCATIVI - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCREGIAO. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCREGIAO|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarRegiao(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCREGIAO - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCPRODUT. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCPRODUT|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarProduto(p_DbLink => v_DbLink
                                               ,p_TipoAtualizacao => v_TipoAtualizacao
                                               ,p_DataInicial => p_DataInicial
                                               ,p_DataFinal => p_DataFinal
                                               ,p_NumRegiao => p_NumRegiao
                                               ,p_CodProd => p_CodProd);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCPRODUT - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCAUTORI. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCAUTORI|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarAutorizacao(p_DbLink => v_Dblink
                                                   ,p_NumCaixa => p_NumCaixa
                                                   ,p_TipoAtualizacao => v_TipoAtualizacao
                                                   ,p_DataInicial => p_DataInicial
                                                   ,p_DataFinal => p_DataFinal
                                                   ,p_CodProd => p_CodProd);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCAUTORI - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;

      -- Atualizar tabela PCUSUARI. A atualização de cada tabela será tratada como uma transação
      -- em separado pois será permitido a atualização parcial dos banco de dados dos caixas.
      IF p_Tabelas LIKE '%|PCUSUARI|%' THEN
        BEGIN
           PCAtualizarBDCaixa.pAtualizarUsuario(p_DbLink => v_DbLink);
           COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              v_Retorno := v_Retorno||'Tabela PCUSUARI - Erro: '||SQLERRM||chr(13);
              ROLLBACK;
        END;
      END IF;


      -- Verificar se não existe nenhuma mensagem de retorno <Esta parte ainda será validada>.
      -- Caso não exista, atualizar data de atualização do banco de dados do caixa
      -- na tabela PCCONSUM para a data atual (SYSDATE).
      BEGIN
         PCAtualizarBDCaixa.pAtualizarParamDtAtualizacaoBD(p_DbLink => v_DbLink);
         COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
           v_Retorno := v_Retorno||'Campo PCCONSUM.DTATUALIZACAOBD - Erro: '||SQLERRM||chr(13);
           ROLLBACK;
      END;

      -- Alterar sessão pra fechar database link aberto.
      BEGIN
         v_Sql := 'ALTER SESSION CLOSE DATABASE LINK '||v_DbLink;
         EXECUTE IMMEDIATE v_Sql;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

   END IF;

   p_MensRetorno := NVL(v_Retorno,'OK');

end PCExecutarAtualiBdCaixa;
