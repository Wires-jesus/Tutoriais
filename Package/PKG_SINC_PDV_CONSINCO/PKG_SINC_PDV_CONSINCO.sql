CREATE OR REPLACE PACKAGE PKG_SINC_PDV_CONSINCO IS

  g_final_execucao  TIMESTAMP;
  g_inicio_execucao TIMESTAMP;

  PROCEDURE set_final_execucao(p_final_execucao IN TIMESTAMP);

  PROCEDURE set_inicio_execucao(p_id IN pccontroleconsinco.id%TYPE);

  FUNCTION get_final_execucao RETURN TIMESTAMP;

  FUNCTION get_inicio_execucao RETURN TIMESTAMP;

  PROCEDURE atualiza_sinc_processo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_pessoa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_usuario(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_segmento(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_empresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_cliente(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_empresasegmento(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_produto(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_famgrupo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_marca(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_familia(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_formapagtoespecie(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_clientesegmento(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_formapagto(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_formapagtoempresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_famsegmento(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_divisao(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_categoria(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_famdivisaocategoria(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_prodempresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_famembalagem(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_prodcodigo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_prodpreco(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_tributacao(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_tributacaouf(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_cargatributaria(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_enderecoalternativo(p_id IN pccontroleconsinco.id%TYPE);

  --PROCEDURE carrega_tb_prodprecoapartir;

  PROCEDURE carrega_tb_famdivisao(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE exec_sinc;

  --PROCEDURE exec_sinc_PRECO;

END PKG_SINC_PDV_CONSINCO;
