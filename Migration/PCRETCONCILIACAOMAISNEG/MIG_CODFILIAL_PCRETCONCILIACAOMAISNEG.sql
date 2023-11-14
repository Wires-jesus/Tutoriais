alter table PCRETCONCILIACAOMAISNEG add bkp_codfilial number(2)
\
update PCRETCONCILIACAOMAISNEG set bkp_codfilial = codfilial
\
alter table PCRETCONCILIACAOMAISNEG drop column codfilial
\
alter table PCRETCONCILIACAOMAISNEG add codfilial varchar(2)
\
update PCRETCONCILIACAOMAISNEG set codfilial = bkp_codfilial
\
alter table PCRETCONCILIACAOMAISNEG drop column bkp_codfilial