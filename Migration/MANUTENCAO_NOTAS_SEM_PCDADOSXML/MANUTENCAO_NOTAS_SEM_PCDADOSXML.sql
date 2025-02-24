declare
  v_numtransitem pcmovcomple.numtransitem%type;

  procedure grava_pcmovcomple(p_numtransitem number,
                              p_produto varchar2,
                              p_rownum number,
                              p_unidade_comercial varchar2,
                              p_quantidade_comercial number,
                              p_quantidade_tributavel number) is
  begin
    update pcmovcomple
       set pcmovcomple.descricaonfe     = p_produto,
           pcmovcomple.nitemxml         = p_rownum,
           pcmovcomple.unidadecomercial = p_unidade_comercial,
           pcmovcomple.xml_qcom         = p_quantidade_comercial,
           pcmovcomple.xml_qtrib        = p_quantidade_tributavel
     where numtransitem = p_numtransitem;
  end;

  procedure atualiza_grava_pcdadosxml(p_numtransitem       number,
                                     p_valor_Produtos     number,
                                     p_valor_tributavel   number,
                                     p_valor_desconto     number,
                                     p_base_Icms          number,
                                     p_valor_Icms         number,
                                     p_base_St            number,
                                     p_valor_St           number,
                                     p_valoricmsdif       number,
                                     p_ean                varchar2,
                                     p_ean_Unidade        varchar2,
                                     p_valor_outros       number,
                                     p_vlicmsdesoneracao  number,
                                     p_valor_Ii           number,
                                     p_valor_frete        number,
                                     p_valor_seguro       number) is
  begin
    UPDATE pcdadosxml
       SET vprod      = p_valor_Produtos,
           vuntrib    = p_valor_tributavel,
           vdesc      = p_valor_desconto,
           vbc        = p_base_Icms,
           vicms      = p_valor_Icms,
           vbcst      = p_base_St,
           vicmsst    = p_valor_St,
           vicmsdif   = p_valoricmsdif,
           cean       = p_ean,
           ceantrib   = p_ean_Unidade,
           voutro     = p_valor_outros,
           vicmsdeson = p_vlicmsdesoneracao,
           vii        = p_valor_Ii,
           vfrete     = p_valor_frete,
           vseg       = p_valor_seguro
     WHERE numtransitem = p_numtransitem;

    if sql%rowcount = 0 then
      insert into pcdadosxml
        (numtransitem,
         vprod,
         vuntrib,
         vdesc,
         vbc,
         vicms,
         vbcst,
         vicmsst,
         vicmsdif,
         cean,
         ceantrib,
         voutro,
         vicmsdeson,
         vii,
         vfrete,
         vseg)
      values
        (p_numtransitem,
         p_valor_Produtos,
         p_valor_tributavel,
         p_valor_desconto,
         p_base_Icms,
         p_valor_Icms,
         p_base_St,
         p_valor_St,
         p_valoricmsdif,
         p_ean,
         p_ean_Unidade,
         p_valor_outros,
         p_vlicmsdesoneracao,
         p_valor_Ii,
         p_valor_frete,
         p_valor_seguro);
    end if;
  end;
begin
  dbms_output.put_line('inicio saidas');
  --saidas
  for notas in (select numtransvenda, dtsaida
                  from pcnfsaid
                 where situacaonfe = 100
                   and especie = 'NF'
           and dtcancel is null
                   and nvl(pcnfsaid.docemissao, 'x') not in ('CE','SF', 'MF', 'CF')
                   and dtsaida between trunc(sysdate - 120) and trunc(sysdate)
                   and (select count(*)
                          from pcmov
                         where pcmov.numtransvenda = pcnfsaid.numtransvenda) <>
                       (select count(*)
                          from pcdadosxml
                         where numtransitem in
                               (select numtransitem
                                  from pcmov
                                 where pcmov.numtransvenda =
                                       pcnfsaid.numtransvenda))) loop
begin
    for itens in (select rownum,
                       codprod,
                         nvl(p.base_Icms, 0) as base_Icms,
                         nvl(p.valor_Icms, 0) as valor_Icms,
                         nvl(p.base_St, 0) as base_St,
                         nvl(p.valor_St, 0) as valor_St,
                         nvl(p.valoricmsdif, 0) as valoricmsdif,
                         nvl(p.vlicmsdesoneracao, 0) as vlicmsdesoneracao,
                         nvl(p.valor_Ii, 0) as valor_Ii,
                         nvl(p.quantidade_comercial, 0) as quantidade_comercial,
                         nvl(p.quantidade_tributavel, 0) as quantidade_tributavel,
                         p.unidade_comercial,
                         p.produto,
                         nvl(p.valor_desconto, 0) as valor_desconto,
                         nvl(p.valor_tributavel, 0) as valor_tributavel,
                         p.ean,
                         p.ean_Unidade,
                         nvl(p.valor_outros, 0) as valor_outros,
                         nvl(p.valor_frete, 0) as valor_frete,
                         nvl(p.valor_seguro, 0) as valor_seguro,
                         nvl(p.valor_Produtos, 0) as valor_Produtos,
                         p.codigo_produto,
                         p.numero_sequencia
                    from table(cast(nfe_produto_saida(notas.numtransvenda) as tabela_nfe_produto)) p) loop

      select numtransitem
        into v_numtransitem
        from pcmov
       where numtransvenda = notas.numtransvenda
         and codprod = itens.codprod
         and numseq = itens.numero_sequencia
         and dtmov = trunc(notas.dtsaida)
         and rownum = 1;

       grava_pcmovcomple(v_numtransitem,
                         itens.produto,
                         itens.rownum,
                         itens.unidade_comercial,
                         itens.quantidade_comercial,
                         itens.quantidade_tributavel);

      atualiza_grava_pcdadosxml(v_numtransitem,
                               itens.valor_Produtos,
                               itens.valor_tributavel,
                               itens.valor_desconto,
                               itens.base_Icms,
                               itens.valor_Icms,
                               itens.base_St,
                               itens.valor_St,
                               itens.valoricmsdif,
                               itens.ean,
                               itens.ean_Unidade,
                               itens.valor_outros,
                               itens.vlicmsdesoneracao,
                               itens.valor_Ii,
                               itens.valor_frete,
                               itens.valor_seguro);
    end loop;
    exception
      when others then
      null;
  end loop;
  dbms_output.put_line('fim saidas');
  dbms_output.put_line('inicio entradas');
  --entradas
  for notas in (select numtransent, dtent
                  from pcnfent
                 where situacaonfe = 100
                   and especie = 'NF'
                   and dtcancel is null
                   and dtent between trunc(sysdate - 120) and trunc(sysdate)
                   and (select count(*)
                          from pcmov
                         where pcmov.numtransent = pcnfent.numtransent) <>
                       (select count(*)
                          from pcdadosxml
                         where numtransitem in
                               (select numtransitem
                                  from pcmov
                                 where pcmov.numtransent = pcnfent.numtransent))) loop

begin
  dbms_output.put_line('nota: ' || notas.numtransent);
    for itens in (select rownum,
             codprod,
                         nvl(p.base_Icms, 0) as base_Icms,
                         nvl(p.valor_Icms, 0) as valor_Icms,
                         nvl(p.base_St, 0) as base_St,
                         nvl(p.valor_St, 0) as valor_St,
                         nvl(p.valoricmsdif, 0) as valoricmsdif,
                         nvl(p.vlicmsdesoneracao, 0) as vlicmsdesoneracao,
                         nvl(p.valor_Ii, 0) as valor_Ii,
                         nvl(p.quantidade_comercial, 0) as quantidade_comercial,
                         nvl(p.quantidade_tributavel, 0) as quantidade_tributavel,
                         p.unidade_comercial,
                         p.produto,
                         nvl(p.valor_desconto, 0) as valor_desconto,
                         nvl(p.valor_tributavel, 0) as valor_tributavel,
                         p.ean,
                         p.ean_Unidade,
                         nvl(p.valor_outros, 0) as valor_outros,
                         nvl(p.valor_frete, 0) as valor_frete,
                         nvl(p.valor_seguro, 0) as valor_seguro,
                         nvl(p.valor_Produtos, 0) as valor_Produtos,
                         p.codigo_produto,
                         p.numero_sequencia
                    from table(cast(nfe_produto_entrada(notas.numtransent) as tabela_nfe_produto)) p) loop

      select numtransitem
        into v_numtransitem
        from pcmov
       where numtransent = notas.numtransent
         and codprod = itens.codprod
         and nvl(pcmov.numseqadicao, pcmov.numseq) = itens.numero_sequencia
         and dtmov = trunc(notas.dtent)
         and rownum = 1;

      grava_pcmovcomple(v_numtransitem,
                 itens.produto,
                 itens.rownum,
                 itens.unidade_comercial,
                 itens.quantidade_comercial,
                 itens.quantidade_tributavel);

      atualiza_grava_pcdadosxml(v_numtransitem,
                               itens.valor_Produtos,
                               itens.valor_tributavel,
                               itens.valor_desconto,
                               itens.base_Icms,
                               itens.valor_Icms,
                               itens.base_St,
                               itens.valor_St,
                               itens.valoricmsdif,
                               itens.ean,
                               itens.ean_Unidade,
                               itens.valor_outros,
                               itens.vlicmsdesoneracao,
                               itens.valor_Ii,
                               itens.valor_frete,
                               itens.valor_seguro);
    end loop;
  end loop;
  dbms_output.put_line('fim entradas');
  commit;
end loop;
end loop;
end;