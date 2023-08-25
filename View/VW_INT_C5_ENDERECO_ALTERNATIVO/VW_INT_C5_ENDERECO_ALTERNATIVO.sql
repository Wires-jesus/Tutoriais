CREATE OR REPLACE VIEW VW_INT_C5_ENDERECO_ALTERNATIVO AS(
  SELECT
    f.codigo codfilial,
    f.codcli seqpessoa,
    f.codcli || f.codigo seqlogradouro,
    'P' tipo,
    UPPER(
      SUBSTR(
        NVL(NVL(c.numeroent, c.numerocob), f.numero2)
        ,1
        ,10)
    ) nrologradouro,
    UPPER(
      SUBSTR(
        NVL(NVL(c.enderent,c.endercob),f.endereco)
        ,1
        ,60)
    ) logradouro,
    UPPER(
    SUBSTR(
      NVL(NVL(c.bairroent,c.bairrocob),f.bairro)
        ,1
        ,50)
    ) bairro,
    UPPER(
      SUBSTR(
        NVL(NVL(c.complementoent,c.complementocob),f.complementoendereco)
        ,1
        ,60)
    ) complemento,
    UPPER(
      SUBSTR(
        NVL(NVL(c.municent,c.municcob),f.cidade)
        ,1
        ,60)
    ) cidade,
    UPPER(
      SUBSTR(
        NVL(NVL(c.estent,c.estcob),f.uf)
        ,1
        ,2)
    ) uf,
    TO_NUMBER(REPLACE(nvl(nvl(c.cepent, c.cepcob), f.cep), '-', '')) cep,
    (CASE WHEN c.dtexclusao IS NOT NULL THEN 'N' ELSE 'S' END) ativo,
    UPPER(NVL(c.codmunicipio,f.codmun)) codibge
  FROM  pcfilial f
  INNER JOIN pcclient c
  ON (c.CODCLI = f.CODCLI AND c.CODCLI > 0)
  WHERE 
    (nvl(c.dtalterc5,PKG_SINC_PDV_CONSINCO.get_inicio_execucao ) between PKG_SINC_PDV_CONSINCO.get_inicio_execucao and PKG_SINC_PDV_CONSINCO.get_final_execucao)
    and (nvl(f.dtalterc5,PKG_SINC_PDV_CONSINCO.get_inicio_execucao ) between PKG_SINC_PDV_CONSINCO.get_inicio_execucao and PKG_SINC_PDV_CONSINCO.get_final_execucao)
  	and LENGTH(TRIM(TRANSLATE(f.codigo, '0123456789',' '))) IS null
)