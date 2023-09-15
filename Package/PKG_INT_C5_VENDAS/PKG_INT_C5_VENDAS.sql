CREATE OR REPLACE PACKAGE PKG_INT_C5_VENDAS IS
/*
Título: Package de busca de vendas da Consinco
Versão: 02.00

                            Historico de Alteracoes
  --------------------------------------------------------------
    Data            Responsavel         Alteracao
  -----------      -----------          ------------------------------------------------------
    23/09/2022      Deyvid Costa        Criacao da package
    02/08/2023      Rodrigo Ribeiro     Refatoracao a partir da alteracao das cargas do WinThor

 */

    TYPE tr_dados_pcfilamensagem IS RECORD(rowpcfilamensagem pcfilamensagem%ROWTYPE);
    TYPE tb_dados_pcfilamensagem IS TABLE OF tr_dados_pcfilamensagem;

    PROCEDURE processar_sangria(p_seqdocto NUMBER DEFAULT 0);
    PROCEDURE processar_suprimento(p_seqdocto NUMBER DEFAULT 0);
    PROCEDURE processar_venda(p_seqdocto    NUMBER DEFAULT 0,
                              p_nrocheckout NUMBER DEFAULT 0,
                              p_nroempresa  NUMBER DEFAULT 0);
    PROCEDURE processar_movimento_caixa(p_seqdocto NUMBER DEFAULT 0);
    PROCEDURE processar_inutilizacao_nota(p_seqdocto NUMBER DEFAULT 0);
    PROCEDURE processar_cancelamento(p_seqdocto NUMBER DEFAULT 0);

END PKG_INT_C5_VENDAS;
