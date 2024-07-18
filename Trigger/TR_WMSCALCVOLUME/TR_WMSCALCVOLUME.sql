CREATE OR REPLACE trigger TR_WMSCALCVOLUME
  before update of posicao on pcpedc
  referencing new as new old as old
  for each row
declare
  vQtVolTipo13  integer;
  vQtVolTipo20  integer;
  vQtVolTipo22  integer;
  vQtVolRest    integer;
  vQtTotalVolID integer;
  vQtRegistros  integer;
  vQtProdSemWMS integer;
  vQtProdFrios  integer;

  vPercTotVolume number(8, 2);

  vUsaWMS                 char(1);
  vAlterarVolumePorPedido char(1);
  vUtilizaPreFat          char(1);

  vLancEmbalagensPesoVar pcparametrowms.valor%type;
  vUsaIntegracaoWMS      pcparametrowms.valor%type;
  vTipoVolumePedidoVenda pcparametrowms.valor%type;

  vScript varchar2(1000);

begin
  /* Início das validações de parâmetros */
  /* Valida se a filial do pedido utiliza WMS */
  select nvl(usawms, 'N')
      into vUsaWMS
      from pcfilial
     where codigo = :old.codfilial;

    /* Somente executa os cálculos e validações abaixo caso a filial use WMS */
    if (vUsaWMS = 'S') then
      if :new.numvolume is null then
      :new.numvolume := 0;
    end if;
  end if;
  /* A trigger só será executada caso a nova posicao do pedido seja 'F' */
  if :new.posicao = 'F' then

    /* Somente executa os cálculos e validações abaixo caso a filial use WMS */
    if (vUsaWMS = 'S') then

      /* Validações dos parâmetros do WMS */
      select nvl(max(decode(nome, 'ALTERARVOLUMEPORPEDIDO', nvl(valor, 'N'))),
                 'N'),
             nvl(max(decode(nome, 'INTEGRACAOWMS', nvl(valor, 'N'))), 'N'),
             nvl(max(decode(nome, 'TIPOVOLUMEPEDIDOVENDA', nvl(valor, 'O'))),
                 'O'),
             nvl(max(decode(nome,
                            'PERCTOLERANCIAVOLUMEPESOVARIAVEL',
                            nvl(valor, 'N'))),
                 '50'),
             nvl(max(decode(nome, 'LANCEMBALAGENSPESOVAR', nvl(valor, 'N'))),
                 'D')
        into vAlterarVolumePorPedido,
             vUsaIntegracaoWMS,
             vTipoVolumePedidoVenda,
             vPercTotVolume,
             vLancEmbalagensPesoVar
        from pcparametrowms
       where codfilial = :old.codfilial
         and nome in ('ALTERARVOLUMEPORPEDIDO',
                      'INTEGRACAOWMS',
                      'TIPOVOLUMEPEDIDOVENDA',
                      'PERCTOLERANCIAVOLUMEPESOVARIAVEL',
                      'LANCEMBALAGENSPESOVAR');

      /* Valida se existe algum dos produtos do pedido que não utiliza WMS */
      select sum(decode(nvl(pcprodut.usawms, 'N'), 'S', 0, 1))
        into vQtProdSemWMS
        from pcpedi, pcprodut
       where pcpedi.codprod = pcprodut.codprod
         and pcpedi.numped = :old.numped;

      /* Fim das validações de parâmetros */

      /* Caso utilize o padrão de volumes por OS */
      if (vTipoVolumePedidoVenda <> 'I') then

        /* Resumo do if abaixo:
          1: Caso a nova posicao do pedido seja 'F'
          2: A filial usa WMS
          3: Não hajam produtos que não usem WMS
          4:  WMS utiliza integração = 'N'
        */
        if :new.posicao = 'F' and vUsaWMS = 'S' and vQtProdSemWMS = 0 and vUsaIntegracaoWMS = 'N' then
           --(vAlterarVolumePorPedido = 'N' or vUsaIntegracaoWMS = 'S') then

          /* Verifica se existem produtos frios no pedido */
          select count(1)
            into vQtProdFrios
            from pcprodut, pcprodfilial, pcpedi
           where pcprodfilial.codprod = pcprodut.codprod
             and pcpedi.codprod = pcprodut.codprod
             and pcprodfilial.codfilial = :new.codfilial
             and pcpedi.numped = :new.numped
             and pcprodut.tipoEstoque = 'FR';

          /* Somente irá realizar os updates abaixo caso algum dos produtos seja do tipo frios */
          if nvl(vQtProdFrios,0) > 0 then

            /* Verifica se a filial utiliza o processo de pré faturamento */
            select nvl(valor, 'N')
              into vUtilizaPreFat
              from pcparamfilial
             where nome = 'USARPREFATURAMENTOMATCON'
               and codfilial = :new.codfilial;

            if :new.rotina = '4116' then
              vUtilizaPreFat := 'S';
            end if;   

            /* Monta a massa de dados dos produtos frios para update de suas quantidades */
            for reg in (select p.codProd,
                               nvl(f.usarqtosun, 'N') usarQtOSUn,
                               nvl(p.pesovariavel, 'N') pesoVariavel,
                               case
                                 when (nvl(case
                                             when nvl(f.usarQtOSUn, 'N') = 'S' then
                                              0
                                             else
                                              (case
                                                when p.tipoEstoque = 'FR' then
                                                 p.pesoBrutoMaster
                                                else
                                                 p.qtUnitCx
                                              end)
                                           end,
                                           0)) = 0 then
                                  0
                                 else
                                  (case
                                    when p.tipoEstoque = 'FR' then
                                     p.pesoBrutoMaster
                                    else
                                     p.qtUnitCx
                                  end)
                               end qtUnitCx,
                               case
                                 when p.tipoEstoque = 'FR' then
                                  p.pesoPeca
                                 else
                                  1
                               end qtUn,
                               p.pesoPeca
                          from pcprodut p, pcprodfilial f, pcpedi i
                         where p.codprod = f.codprod
                           and p.codprod = i.codprod
                           and i.numped = :new.numped
                           and f.codfilial = :new.codfilial
                           and p.tipoEstoque = 'FR') loop

              wms_atualizaQuantidadesMov(:new.numped,
                                         reg.codprod,
                                         vUtilizaPreFat,
                                         vLancEmbalagensPesoVar,
                                         reg.pesovariavel,
                                         reg.qtUnitCx,
                                         reg.pesoPeca);

            end loop;

          end if;

          /* Continuação para os tipo OS do WMS */

          /* Verifica se existem o.s. tipo 13 para cálculo */
          select count(1)
            into vQtVolTipo13
            from pcmovendpend
           where numped = :new.numped
             and tipoOS = 13
             and dtEstorno is null;

          /* Caso exista alguma, entra na seção de cálculos do tipo 13 e zera a contagem para o cálculo conforme parâmetros */
          if nvl(vQtVolTipo13,0) > 0 then
            vQtVolTipo13 := 0;

            /* Caso o parâmetro de lançamento de embalagens seja 'D', realiza o cálculo dentro do if abaixo */
            if (vLancEmbalagensPesoVar = 'D') then

              select nvl(sum(nvl(vol, 0)), 0)
                into vQtVolTipo13
                from (select case
                               when (sum(nvl(pcmovendpend.qtPecas, 0)) > 0 and
                                    sum(nvl(pcmovendpend.qtCx, 0)) > 0) then
                                sum(trunc(pcmovendpend.qt / pcprodut.pesoBrutoMaster) + case
                                      when (mod(pcmovendpend.qt, pcprodut.pesoBrutoMaster) >
                                           (trunc(mod(pcmovendpend.qt, pcprodut.pesoBrutoMaster) /
                                                   pcprodut.pesoPeca) * pcprodut.pesoPeca) +
                                           (pcprodut.pesoPeca * vPercTotVolume / 100)) then
                                       ceil(mod(pcmovendpend.qt, pcprodut.pesoBrutoMaster) / pcprodut.pesoPeca)
                                      else
                                       trunc(mod(pcmovendpend.qt, pcprodut.pesoBrutoMaster) / pcprodut.pesoPeca)
                                    end)
                               else
                                sum(case
                                      when (pcmovendpend.qt > (trunc(pcmovendpend.qt / case
                                                                       when nvl(pcmovendpend.qtPecas, 0) > 0 then
                                                                        pcprodut.pesoPeca
                                                                       else
                                                                        pcprodut.pesoBrutoMaster
                                                                     end) * case
                                             when nvl(pcmovendpend.qtPecas, 0) > 0 then
                                              pcprodut.pesoPeca
                                             else
                                              pcprodut.pesoBrutoMaster
                                           end) + (case
                                             when nvl(pcmovendpend.qtPecas, 0) > 0 then
                                              pcprodut.pesoPeca
                                             else
                                              pcprodut.pesoBrutoMaster
                                           end * vPercTotVolume / 100)) then
                                       ceil(pcmovendpend.qt / case
                                              when nvl(pcmovendpend.qtPecas, 0) > 0 then
                                               pcprodut.pesoPeca
                                              else
                                               pcprodut.pesoBrutoMaster
                                            end)
                                      else
                                       trunc(pcmovendpend.qt / case
                                               when nvl(pcmovendpend.qtPecas, 0) > 0 then
                                                pcprodut.pesoPeca
                                               else
                                                pcprodut.pesoBrutoMaster
                                             end)
                                    end)
                             end vol
                        from pcmovendpend, pcprodut
                       WHERE pcmovendpend.numped = :NEW.numped
                         and pcmovendpend.tipoos = 13
                         and nvl(pcprodut.pesovariavel, 'N') = 'S'
                         and pcmovendpend.codprod = pcprodut.codprod
                         and pcmovendpend.dtestorno is null
                       GROUP BY pcmovendpend.numos);
            end if;

            /* Caso não tenha obtido nenhum volume no cálculo acima, continua a calcular */
            if (nvl(vQtVolTipo13,0) = 0) then
              /* Obtem o máximo dos volumes que constam na PCMOVENDPEND dos produtos não variam peso e não sejam frios */
              select nvl(sum(nvl(vol, 0)), 0)
                into vQtVolTipo13
                from (select max(pcmovendpend.numVol) vol
                        from pcmovendpend, pcprodut
                       where pcmovendpend.numped = :new.numped
                         and pcmovendpend.tipoOS = 13
                         and pcmovendpend.dtEstorno is null
                         and pcmovendpend.codProd = pcprodut.codProd
                         and (nvl(pcprodut.pesoVariavel, 'N') <> 'S' or
                             pcprodut.tipoEstoque <> 'FR')
                       group by numos);
            end if;

            /* Caso não tenha obtido nenhum volume no cálculo acima, continua a calcular */
            if (nvl(vQtVolTipo13,0) = 0) then
              /* Soma os volumes calculados no select abaixo baseado no peso (para frios) ou caixa, dos produtos que não variam peso */
              select nvl(sum(nvl(vol, 0)), 0)
                into vQtVolTipo13
                from (select ROUND(sum(case
                                        when pcprodut.tipoEstoque = 'FR' then
                                         pcmovendpend.qt / pcprodut.pesoBrutoMaster
                                        else
                                         pcmovendpend.qt / pcprodut.qtUnitCx
                                      end)) vol
                        from pcmovendpend, pcprodut
                       where pcmovendpend.numped = :new.numped
                         and pcmovendpend.tipoOS = 13
                         and nvl(pcprodut.pesoVariavel, 'N') <> 'S'
                         and pcmovendpend.codProd = pcprodut.codProd
                         and pcmovendpend.dtEstorno is null
                       group by pcmovendpend.numos);

              /* E caso nenhum dos cálculos acima tenha obtido sucesso, é verificado se o lançamento de embalagens está definido como 'S' */
              if ((vLancEmbalagensPesoVar = 'S') and (nvl(vQtVolTipo13,0) = 0)) then
                select nvl(sum(nvl(vol, 0)), 0)
                  into vQtVolTipo13
                  from (select (select sum(nvl(i.qtCx, 0) + nvl(i.qtPecas, 0) +
                                           nvl(i.qtUn, 0))
                                  from pcpedi i
                                 where i.numped = :new.numped
                                   and i.codProd = pcmovendpend.codProd) vol
                          from pcmovendpend, pcprodut
                         where pcmovendpend.numped = :new.numped
                           and pcmovendpend.tipoOS = 13
                           and pcmovendpend.codProd = pcprodut.codProd
                           and pcmovendpend.dtEstorno is null
                           and pcprodut.tipoEstoque = 'FR'
                           and nvl(pcprodut.pesoVariavel, 'N') = 'S'
                         group by pcmovendpend.numos, pcmovendpend.codProd);
              end if;

            end if;

            /* Fim do cálculo dos tipoOS 13 */
          end if;

          /* Início dos cálculos de volume para o tipo 20 */
          /* Verifica se existe alguma OS para o tipo 20 antes de iniciar os cálculos */
          select count(1)
            into vQtVolTipo20
            from pcmovendpend
           where numped = :new.numped
             and tipoOS = 20
             and dtEstorno is null;

          /* Início dos cálculos do tipo 20 */
          if (nvl(vQtVolTipo20,0) > 0) then
            /* Por padrão, são somados os volumes que constam na pcmovendpend */
            select sum(nvl(numVol, 0))
              into vQtVolTipo20
              from pcmovendpend
             where numped = :new.numped
               and tipoOS = 20
               and dtEstorno is null;

            /* Caso não tenha obtido nenhum volume com a soma, calcula com base no peso dos produtos que geraram no tipo 20 */
            if (nvl(vQtVolTipo20,0) = 0) then
              select sum(nvl(vol, 0))
                into vQtVolTipo20
                from (select ROUND(sum(case
                                        when tipoEstoque = 'FR' then
                                         pcmovendpend.qt / pcprodut.pesoBrutoMaster
                                        else
                                         pcmovendpend.qt / pcprodut.qtUnitCx
                                      end)) vol
                        from pcmovendpend, pcprodut
                       where pcmovendpend.numped = :new.numped
                         and pcmovendpend.tipoOS = 20
                         and pcmovendpend.codProd = pcprodut.codProd
                         and nvl(pcprodut.pesoVariavel, 'N') <> 'S'
                         and pcmovendpend.dtEstorno is null
                       group by pcmovendpend.numos);
            end if;
            /* Fim do cálculo do tipo 20 */
          end if;

          /* Início dos cálculos do tipo 22 */
          select count(1)
            into vQtVolTipo22
            from pcmovendpend
           where numped = :new.numped
             and tipoOS = 22
             and dtEstorno is null;

          /* Caso tenha encontrado alguma OS, realiza o cálculo abaixo */
          if (nvl(vQtVolTipo22,0) > 0) then
            /* O cálculo é feito pela soma dos maiores números de volume do tipo 22 */
            select sum(nvl(vol, 0))
              into vQtVolTipo22
              from (select max(pcmovendpend.numVol) vol
                      from pcmovendpend
                     where pcmovendpend.numped = :new.numped
                       and pcmovendpend.tipoOS = 22
                       and pcmovendpend.dtEstorno is null
                     group by pcmovendpend.numos);

            /* Fim do cálculo do tipo 22 */
          end if;

          /* Calcula o restante dos volumes baseado em suas quantidades de caixa e/ou peso */
          select nvl(sum(nvl(qt, 0)), 0)
            into vQtVolRest
            from (select ceil((sum(pcpedi.qt) -
                              nvl((select sum(qt)
                                     from pcmovendpend
                                    where numped = :new.numped
                                      and tipoOS in (13, 20, 22)
                                      and codProd = pcpedi.codProd
                                      and dtEstorno is null),
                                   0)) / (case
                                when tipoEstoque = 'FR' then
                                 pcprodut.pesoBrutoMaster
                                else
                                 pcprodut.qtUnitCx
                              end)) qt
                    from pcpedi, pcprodut
                   where pcpedi.numped = :new.numped
                     and pcpedi.codProd = pcprodut.codProd
                     and nvl(pcprodut.pesoVariavel, 'N') <> 'S'
					 and pcprodut.tipomerc not in ('PA', 'MP')
                   group by pcpedi.codProd,
                            pcprodut.qtUnitCx,
                            pcprodut.pesoBrutoMaster,
                            pcprodut.tipoEstoque);
          /* Fim do cálculo dos volumes restantes */

          /* Atribui o novo número de volumes a coluna da pcpedc.numvolume */
          :new.numVolume := NVL(vQtVolTipo13,0) + NVL(vQtVolTipo20,0) + NVL(vQtVolTipo22,0) +
                            NVL(vQtVolRest,0);

          /* Fim do cálculo dos volumes por O.S. */
        end if;

      else
        /* Caso utilize o padrão de volumes por ID */
        /* Volumes induzidos e agrupados */

        /* Calcula a quantidade de volumes que não estão cortados na PCVOLUMEOS */
        select count(distinct(nvl(s.numVol, 0)))
          into vQtTotalVolID
          from pcmovendpend m, pcvolumeos s
         where s.numos in (SELECT DISTINCT NUMOS FROM PCMOVENDPEND WHERE NUMPED = :new.numped)
           and m.numped = :new.numped
           and m.tipoOS in (13, 17, 18, 20, 22)
           and m.dtEstorno is null
           and nvl(s.volumeCortado, 'N') = 'N';

        /* Realiza o cácculo dos volumes restantes que não foram obtidos no select acima */
        select nvl(sum(nvl(qt, 0)), 0)
          into vQtVolRest
          from (select ceil((sum(pcpedi.qt) -
                            nvl((select sum(qt)
                                   from pcmovendpend
                                  where numped = :new.numped
                                    and tipoOS in (13, 17, 18, 20, 22)
                                    and codProd = pcpedi.codProd
                                    and dtEstorno is null),
                                 0)) / (case
                              when tipoEstoque = 'FR' then
                               pcprodut.pesoBrutoMaster
                              else
                               pcprodut.qtUnitCx
                            end)) qt
                  from pcpedi, pcprodut
                 where numped = :new.numped
                   and pcpedi.codProd = pcprodut.codProd
                   and nvl(pcprodut.pesoVariavel, 'N') <> 'S'
                 group by pcpedi.codProd,
                          pcprodut.qtUnitCx,
                          pcprodut.pesoBrutoMaster,
                          pcprodut.tipoEstoque);

        /* Atribui o novo número de volumes a coluna da pcpedc.numvolume */
        :new.numVolume := NVL(vQtTotalVolID,0) + NVL(vQtVolRest,0);

        /* Fim do cálculo dos volumes por ID */
      end if;

      /* Realiza update na PCNFSAID (NumVolume e TotVolume) conforme foi calculado para os tipos de OS */
      update pcnfsaid
         set numVolume = :new.numVolume,
             totVolume = :new.numVolume
       where numTransVenda = :new.numTransVenda;

      /* Verifica se existe a tabela PCNFSAIDPREFAT, pois caso a tenha, significa que o update acima não foi bem sucedido
	  e tenta realizar o update nela, pois posteriormente, será replicado aos novos registros da PCNFSAID */
      select count(1)
        into vQtRegistros
        from user_tables
       where table_name = 'PCNFSAIDPREFAT';

      if (vQtRegistros > 0) then
        vScript := 'update pcnfsaidprefat  ' ||
                   '   set numVolume     = ' || nvl(:new.numVolume, 0) ||
                   '     , totVolume     = ' || nvl(:new.numVolume, 0) ||
                   ' where numTransVenda = ' || nvl(:new.numTransVenda, 0);

        execute immediate vScript;

      end if;

      /* Final do if caso a filial use WMS */
    end if;

    /* Final do if caso o pedido esteja sendo faturado */
  end if;

  /* Fim da execução da trigger */
end;