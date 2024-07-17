CREATE OR REPLACE PACKAGE PKG_SINC_PDV_CONSINCO IS

  g_final_execucao  TIMESTAMP;
  g_inicio_execucao TIMESTAMP;

  PROCEDURE set_final_execucao(p_final_execucao IN TIMESTAMP);

  PROCEDURE set_inicio_execucao(p_id IN pccontroleconsinco.id%TYPE);

  FUNCTION get_final_execucao RETURN TIMESTAMP;

  FUNCTION get_inicio_execucao RETURN TIMESTAMP;

  FUNCTION obter_seqapartirde RETURN NUMBER;

  FUNCTION obter_seqregraincentivo RETURN NUMBER;

  PROCEDURE atualiza_sinc_processo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_pessoa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_usuario(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_grupo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_grupousuario(p_id IN pccontroleconsinco.id%TYPE);

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

  PROCEDURE carrega_tb_codgeraloper(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_codgeralopercfop(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_codgeralopercfopuf(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_enderecoalternativo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_prodprecoapartir(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_famdivisao(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_condicaopagto(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_regraincentivo(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_regraincentperiodo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_regraempresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_regrasegmento(p_id IN pccontroleconsinco.id%TYPE);

  --PROCEDURE carrega_tb_regrafamilia(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_regracliente(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_regracategoria(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_regraproduto(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_combo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_comboempresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_comboitem(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_combogrupo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_parcelamento(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_parcempresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_parcperiodo(p_id IN pccontroleconsinco.id%TYPE);

  --PROCEDURE carrega_tb_parccategformapagto(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_parcfamformapagto(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_promsurpresa(p_id IN pccontroleconsinco.id%TYPE);
  
  PROCEDURE carrega_tb_promsurpresaempresa(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_promsurpresaperiodo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_promsurpresaitem(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_promsurpresagrupo(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_cadobs(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_cadobssped(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_cadobsspedfamilia(p_id IN pccontroleconsinco.id%TYPE);

  PROCEDURE carrega_tb_especiefinanceira(p_id in pccontroleconsinco.id%TYPE);  

  PROCEDURE carrega_tb_prodcomposto(p_id IN pccontroleconsinco.id%TYPE);

  procedure carrega_tb_precoapartir(p_id in pccontroleconsinco.id%type);
    
  procedure carrega_tb_precoapartirpessoa(p_id in pccontroleconsinco.id%type);
  
  procedure carrega_tb_precoapartirempresa(p_id in pccontroleconsinco.id%type);

  procedure carrega_tb_precoapartirsegmento(p_id in pccontroleconsinco.id%type);

  procedure carrega_tb_precoapartirperiodo(p_id in pccontroleconsinco.id%type);

  PROCEDURE exec_sinc;

  --PROCEDURE exec_sinc_PRECO;

END PKG_SINC_PDV_CONSINCO;