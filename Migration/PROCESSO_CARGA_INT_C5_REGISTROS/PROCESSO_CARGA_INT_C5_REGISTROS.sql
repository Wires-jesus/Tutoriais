/* Popular tabela PCTIPOCONTROLECONSINCO */

delete from pccontroleconsinco

\

delete from pctipoprocessoconsinco

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (1, 'tb_pessoa')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (2, 'tb_cliente')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (3, 'tb_segmento')

\

Insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (4, 'tb_empresa')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (5, 'tb_empresasegmento')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (6, 'tb_famgrupo')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (7, 'tb_marca')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (8, 'tb_familia')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (9, 'tb_produto')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (10, 'tb_formapagtoespecie')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (11, 'tb_clientesegmento')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (12, 'tb_formapagto')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (13, 'tb_formapagtoempresa')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (14, 'tb_famsegmento')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (15, 'tb_divisao')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (16, 'tb_categoria')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (17, 'tb_famdivisaocategoria')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (18, 'tb_prodempresa')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (19, 'tb_famembalagem')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (20, 'tb_prodcodigo')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (21, 'tb_prodpreco')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (22, 'tb_tributacao')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (23, 'tb_tributacaouf')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (24, 'tb_enderecoalternativo')

\

insert into pctipoprocessoconsinco (ID, DESCRICAO)
values (25, 'tb_famdivisao')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (26, 'tb_cargatributaria')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (27, 'tb_condicaopagto')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (28, 'tb_codgeraloper')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (29, 'tb_codgeralopercfop')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (30, 'tb_regraincentivo')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (31, 'tb_regraincentperiodo')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (32, 'tb_regraproduto')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (33, 'tb_regrafamilia')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (34, 'tb_regracliente')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (35, 'tb_regracategoria')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (36, 'tb_combo')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (37, 'tb_comboempresa')

\

insert into pctipoprocessoconsinco(ID, DESCRICAO)
values (38, 'tb_comboitem')

/* Popular tabela PCCONTROLECONSINCO */

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (1, 1, 'Sincronização de tabela TB_PESSOA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_pessoa', 1, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (2, 2, 'Sincronização de tabela TB_CLIENTE', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_cliente', 2, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (3, 3, 'Sincronização de tabela TB_SEGMENTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_segmento', 3, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (4, 4, 'Sincronização de tabela TB_EMPRESA',  TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_empresa', 6, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (5, 5, 'Sincronização de tabela TB_EMPRESASEGMENTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_empresasegmento', 7, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (6, 6, 'Sincronização de tabela TB_FAMGRUPO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_famgrupo', 8, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (7, 7, 'Sincronização de tabela TB_MARCA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_marca', 9, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (8, 8, 'Sincronização de tabela TB_FAMILIA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_familia', 10, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (9, 9, 'Sincronização de tabela TB_PRODUTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_produto', 12, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (10, 10, 'Sincronização de tabela TB_FORMAPAGTOESPECIE', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_formapagtoespecie', 17, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (11, 11, 'Sincronização de tabela TB_CLIENTESEGMENTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_clientesegmento', 4, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (12, 12, 'Sincronização de tabela TB_FORMAPAGTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_formapagto', 18, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (13, 13, 'Sincronização de tabela TB_FORMAPAGTOEMPRESA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_formapagtoempresa', 19, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (14, 14, 'Sincronização de tabela TB_FAMSEGMENTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_famsegmento', 16, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (15, 15, 'Sincronização de tabela TB_DIVISAO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_divisao', 5, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (16, 16, 'Sincronização de tabela TB_CATEGORIA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_categoria', 20, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (17, 17, 'Sincronização de tabela TB_FAMDIVISAOCATEGORIA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_famdivisaocategoria', 21, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (18, 18, 'Sincronização de tabela TB_PRODEMPRESA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_prodempresa', 13, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (19, 19, 'Sincronização de tabela TB_FAMEMBALAGEM', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_famembalagem', 11, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (20, 20, 'Sincronização de tabela TB_PRODCODIGO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_prodcodigo', 14, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (21, 21, 'Sincronização de tabela TB_PRODPRECO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_prodpreco', 15, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (22, 22, 'Sincronização de tabela TB_TRIBUTACAO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_tributacao', 22, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (23, 23, 'Sincronização de tabela TB_TRIBUTACAOUF', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_tributacaouf', 23, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (24, 24, 'Sincronização de tabela TB_ENDERECOALTERNATIVO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_enderecoalternativo', 24, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco (ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (25, 25, 'Sincronização de tabela TB_FAMDIVISAO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_famdivisao', 25, 'A', TRUNC(SYSDATE), TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (26, 26, 'Sincronização de tabela TB_CARGATRIBUTARIA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_cargatributaria',  26,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE))

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (27, 27, 'Sincronização de tabela TB_CONDICAOPAGTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_condicaopagto',  27,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (28, 28, 'Sincronização de tabela TB_CODGERALOPER', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_codgeraloper',  28,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (29, 29, 'Sincronização de tabela TB_CODGERALOPERCFOP', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_codgeralopercfop',  29,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (30, 30, 'Sincronização de tabela TB_REGRAINCENTIVO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_regraincentivo',  30,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (31, 31, 'Sincronização de tabela TB_INCENTIVOPERIODO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_regraincentperiodo',  31,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (32, 32, 'Sincronização de tabela TB_REGRAPRODUTO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_regraproduto',  32,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (33, 33, 'Sincronização de tabela TB_REGRAFAMILIA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_regrafamilia',  33,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (34, 34, 'Sincronização de tabela TB_REGRACLIENTE', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_regracliente',  34,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (35, 35, 'Sincronização de tabela TB_REGRACATEGORIA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_regracategoria',  35,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (36, 36, 'Sincronização de tabela TB_COMBO', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_combo',  36,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (37, 37, 'Sincronização de tabela TB_COMBOEMPRESA', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_comboempresa',  37,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )

\

insert into pccontroleconsinco(ID, CODPROCESSO, DESCRICAO, ULTIMAEXECUCAO, TIPO, OBJETOREFERENCIA, PRECEDENCIA, ATIVO, DTCRIACAO, DTALTERACAO)
values (38, 38, 'Sincronização de tabela TB_COMBOITEM', TRUNC(SYSDATE), 'D', 'pkg_sinc_PDV_Consinco.carrega_tb_comboitem',  38,  'A',  TRUNC(SYSDATE),  TRUNC(SYSDATE) )