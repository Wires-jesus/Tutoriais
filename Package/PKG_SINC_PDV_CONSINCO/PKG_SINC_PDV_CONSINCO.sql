CREATE OR REPLACE PACKAGE PKG_SINC_PDV_CONSINCO IS

  g_final_execucao  TIMESTAMP;
  g_inicio_execucao TIMESTAMP;

  PROCEDURE set_final_execucao(p_final_execucao IN TIMESTAMP);

  PROCEDURE set_inicio_execucao(p_id IN intermediario.pccontroleconsinco.id%TYPE);

  FUNCTION get_final_execucao RETURN TIMESTAMP;

  FUNCTION get_inicio_execucao RETURN TIMESTAMP;

  PROCEDURE atualiza_sinc_processo(p_id IN intermediario.pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_pessoa;

  PROCEDURE carrega_tb_usuario;

  PROCEDURE carrega_tb_segmento;

  PROCEDURE carrega_tb_empresa;

  PROCEDURE carrega_tb_cliente;

  PROCEDURE carrega_tb_empresasegmento;

  PROCEDURE carrega_tb_produto;

  PROCEDURE carrega_tb_famgrupo;

  PROCEDURE carrega_tb_marca;

  PROCEDURE carrega_tb_familia;

  PROCEDURE carrega_tb_formapagtoespecie;

  PROCEDURE carrega_tb_clientesegmento;

  PROCEDURE carrega_tb_formapagto;

  PROCEDURE carrega_tb_formapagtoempresa;

  PROCEDURE carrega_tb_famsegmento;

  PROCEDURE carrega_tb_divisao;

  PROCEDURE carrega_tb_categoria;

  PROCEDURE carrega_tb_famdivisaocategoria;

  PROCEDURE carrega_tb_prodempresa;

  PROCEDURE carrega_tb_famembalagem;

  PROCEDURE carrega_tb_prodcodigo;

  PROCEDURE carrega_tb_prodpreco;

  PROCEDURE carrega_tb_tributacao;

  PROCEDURE carrega_tb_tributacaouf;

  PROCEDURE carrega_tb_enderecoalternativo;

  --PROCEDURE carrega_tb_prodprecoapartir;

  PROCEDURE carrega_tb_famdivisao;

  PROCEDURE exec_sinc;

  PROCEDURE exec_sinc_PRECO;

END PKG_SINC_PDV_CONSINCO;
