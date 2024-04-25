delete from pcvariavellayoutbancario where CODVARIAVEL in (select codigo from pcvariavelbancaria where nome = 'SEGMENTO')
\
delete from pcvariavelbancaria where nome = 'SEGMENTO'