create or replace package body IMPORTARINDENIZACOES is

  /*

    Package de Integracao do Winthor com Sistemas de Forca de Vendas para importar Indenizações

    ----------------     Historico     ----------------
    Data        Responsável    Tarefa          Comentario
    03/10/2013  Andréa         212669           Primeira Versao - (alteracoes iniciais)
    16/01/2014  Andréa         HIS.00043.2014   Gravar no historico da tabela pccrecli o número da indenização
  */

  procedure proc_registralog(p_numped        in pcpedc.numped%type,
                             p_numpedrca     in pcpedc.numpedrca%type,
                             p_codprod       in pcprodut.codprod%type,
                             p_codauxiliar   in pcpedi.codauxiliar%type,
                             p_cgcent        in pcclient.cgcent%type,
                             p_codigocotacao in pccota.codcotacao%type,
                             p_numrecadofv   in pcrecfunc.numrecadofv%type,
                             p_numcontagem   in pcgondolac.numcontagem%type,
                             p_codusur       in pcpedc.codusur%type,
                             p_data          in date,
                             p_cancelada     in varchar2,
                             p_tiporeg       in varchar2,
                            -- 1 = generico / -1 = Clientes /2 = cabecalho / 3 = itens /4 = Contatos
                             p_erro     in varchar2,
                             p_linhareg in number) is
  begin
    vngcontador := vngcontador + 1;
    gvetregistralog(vngcontador).numped        := p_numped;
    gvetregistralog(vngcontador).numpedrca     := p_numpedrca;
    gvetregistralog(vngcontador).codprod       := p_codprod;
    gvetregistralog(vngcontador).codauxiliar   := p_codauxiliar;
    gvetregistralog(vngcontador).cgcent        := p_cgcent;
    gvetregistralog(vngcontador).codigocotacao := p_codigocotacao;
    gvetregistralog(vngcontador).numrecadofv   := p_numrecadofv;
    gvetregistralog(vngcontador).numcontagem   := p_numcontagem;
    gvetregistralog(vngcontador).codusur       := p_codusur;
    gvetregistralog(vngcontador).data          := p_data;
    gvetregistralog(vngcontador).cancelada     := p_cancelada;
    gvetregistralog(vngcontador).tiporeg       := p_tiporeg;
    gvetregistralog(vngcontador).erro          := p_erro;
    gvetregistralog(vngcontador).linhareg      := p_linhareg;

  end proc_registralog;

  procedure proc_lerparametros(p_existerro in out boolean) is
    vsdirimportacaofv pcconsum.dirimportacaofv%type;
  begin
    select * into gregpcconsum from pcconsum;
    gregpcconsum.codfilialfv      := NVL(gregpcconsum.codfilialfv, '1');
    gregpcconsum.numcasasdecvenda := NVL(gregpcconsum.numcasasdecvenda, 2);


  exception
    when others then
      p_existerro := true;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '1',
                       'Erro ao ler parametros#;' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
  end proc_lerparametros;


PROCEDURE proc_processarleitura(p_existerro   IN OUT BOOLEAN,
                                p_tipoleitura IN NUMBER,
                                p_datainicial IN DATE,
                                p_datafinal   IN DATE,
                                p_codfilial   IN VARCHAR2,
                                p_tiporeg     IN NUMBER,
                                p_codusur     IN NUMBER default null,
                                p_numpedrca   IN NUMBER default null) IS
    vblerindcok       boolean;
    vblerindiok       boolean;
    vncontorigempreco integer;
    vncontindc        integer;
    vncontindi        integer;

    vddatainicial     date;
    vddatafinal       date;

  BEGIN
    /*
       Campo IMPORTADO:
       Valor 0 = registro bloqueado.
       Valor 1 = registro liberado para leitura.
       Valor 2 = registro lido.
       Valor 3 = registro liberado para leitura novamente (rejeitado anteriormente).
    */

    -- Ajusta a faixa de datas conforme parametro.
    IF p_tipoleitura = 1
    THEN
      vddatainicial := TRUNC(SYSDATE) - 365;
      vddatafinal   := TRUNC(SYSDATE);
    ELSE
      vddatainicial := p_datainicial;
      vddatafinal   := p_datafinal;
    END IF;

    vncontorigempreco := 0;
    vncontindc        := 0;
    vncontindi        := 0;


    vngdatainicio     := vddatainicial;
    vngdatafim        := vddatafinal;



   -- indenizacoes
 if p_tiporeg is null or p_tiporeg = 6 then

    FOR cr_indc IN (SELECT codindeniz,
                           data          ,
                           cgccli        ,
                           codfilial     ,
                           numpedrca     ,
                           tipoindeniz   ,
                           codusur       ,
                           obs           ,
                           codcli        ,
                           rownum as linha
                        FROM pcindcfv
                       WHERE importado = p_tipoleitura
                         AND (NVL(trunc(dtinclusao),TRUNC(SYSDATE)) BETWEEN vddatainicial AND vddatafinal)
                         AND ((nvl(codfilial,'99') = nvl(p_codfilial,'99') or nvl(codfilial,'99') = '99') or (p_codfilial = '99'))
                         AND  (codusur = p_codusur or p_codusur is null)) LOOP
      BEGIN

        vblerindcok                     := FALSE;

        gregindenizacao.codindeniz      := cr_indc.codindeniz;
        gregindenizacao.data            := cr_indc.data;
        gregindenizacao.cgccli          := cr_indc.cgccli;
        gregindenizacao.codfilial       := cr_indc.codfilial;
        gregindenizacao.numpedrca       := cr_indc.numpedrca;
        gregindenizacao.tipoindeniz     := cr_indc.tipoindeniz;
        gregindenizacao.codusur         := cr_indc.codusur;
        gregindenizacao.obs             := cr_indc.obs;
        gregindenizacao.codcli          := cr_indc.codcli;


        vblerindcok := func_lockindenizacao(cr_indc.numpedrca, cr_indc.codusur, cr_indc.data, cr_indc.cgccli, p_tipoleitura);

        IF vblerindcok = TRUE
        THEN
          vncontindc := vncontindc + 1;
          gvet_regindenizacao(vncontindc) := gregindenizacao;
        END IF;

        IF vblerindcok = TRUE
        THEN
          FOR cr_indi IN (SELECT codindeniz,
                                 codprod,
                                 qt,
                                 pvenda,
                                 obs,
                                 recolher,
                                 rownum as linha
                               FROM pcindifv
                              WHERE codindeniz = cr_indc.codindeniz) LOOP
            BEGIN
              vblerindiok                    := FALSE;
              gregitemindenizacao.codindeniz := cr_indi.codindeniz;
              gregitemindenizacao.codprod    := cr_indi.codprod;
              gregitemindenizacao.qt         := cr_indi.qt;
              gregitemindenizacao.pvenda     := cr_indi.pvenda;
              gregitemindenizacao.obs        := cr_indi.obs;
              gregitemindenizacao.recolher   := cr_indi.recolher;

              vblerindiok                := TRUE;

              IF vblerindiok = TRUE
              THEN
                vncontindi := vncontindi + 1;
                gvet_regitemindenizacao(vncontindi) := gregitemindenizacao;

                -- incrementar contador de itens da indenizacao atual
                gvet_regindenizacao(vncontindc).numitens := NVL(gvet_regindenizacao(vncontindc).numitens,0) + 1;


              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                proc_registralog(NULL,
                                 cr_indi.codindeniz,
                                 cr_indi.codprod,
                                 null,
                                 null,
                                 NULL,
                                 NULL,
                                 null,
                                 null,
                                 null,
                                 null,
                                 '10',
                                 'ERRO AO LER ITEM DA INDENIZACAO#' || SQLCODE || '-' ||';'||
                                 SQLERRM || ';',
                                 cr_indi.linha);
            END;
          END LOOP;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           cr_indc.codindeniz,
                           null,
                           null,
                           null,
                           NULL,
                           NULL,
                           null,
                           null,
                           null,
                           null,
                           '9',
                           'ERRO AO LER INDENIZACAO#' || SQLCODE || '-' || SQLERRM || ';',
                           cr_indc.linha);
      END;
    END LOOP;
   --fim indenizacoes
  end if;



  EXCEPTION
    WHEN OTHERS THEN
      p_existerro := TRUE;
      proc_registralog(NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       null,
                       null,
                       null,
                       null,
                       '1',
                       'ERRO AO LER INDENIZACOES;' || SQLCODE || '-' || SQLERRM || ';',
                       NULL);
  END proc_processarleitura;

    
  function func_inseririndenizacao(p_regindenizacao in t_indenizacao,
                                   p_regfilial      in t_filial)
    return boolean is

    vsmensagem    varchar2(30) := null;
    vicont        number := 0;
    vnvltotal     number := 0;
    vnpesototal   number;
    vnvolumetotal number;
    vnnumitens    number;
    vicontrecolher number;
    vbgeracredito  boolean;
    vbvalido       boolean;
    vnvalor        number;
    vnProxNumLanc  pcconsum.proxnumlanc%type;

  begin
    begin

      select count(*)
        into vicont
        from pcindi
       where numindeniz = p_regindenizacao.numindeniz;
    exception
      when others then
        vicont := 0;
    end;

    if vicont <> 0 then
    
     vbgeracredito := false;
     vbvalido      := true;
    
        begin
    
          select count(*)
            into vicontrecolher
            from pcindi
           where numindeniz = p_regindenizacao.numindeniz
           and   nvl(recolher,'N') = 'N';
        exception
          when others then
            vicontrecolher := 0;
        end;
       
       
       if p_regindenizacao.tipoindeniz = 'I' then
       
          if vicontrecolher > 0 and p_regfilial.gerarcreditoindenizfv = 'S' then
    
              if nvl(p_regfilial.codcontadespindeniz,0) = 0 then
              
                  proc_registralog(null,
                               p_regindenizacao.codindeniz,
                               null,
                               null,
                               null,
                               null,
                               null,
                               null,
                               null,
                               null,
                               null,
                               '9',
                               ';ERRO AO GRAVAR INDENIZACAO#; CONTA INVALIDA PARA GERACAO DE CREDITO DE INDENIZACAO',
                               null);
              
                 vbgeracredito := false;
                 vbvalido      := false;
                 
               else

                  select sum(pcindi.pvenda * pcindi.qt)
                    into vnvalor
                    from pcindi,pcprodut
                   where numindeniz = p_regindenizacao.numindeniz
                   and   pcindi.codprod = pcprodut.codprod
                   and   nvl(pcindi.recolher, 'N') = 'N';
           
                vbgeracredito := true;    

                 
              end if;
           end if;   
         end if;
        
        
        if vbvalido = true then
        
                  select sum(pcindi.pvenda * pcindi.qt),
                         sum(pcprodut.pesobruto * pcindi.qt),
                         sum(pcprodut.volume * pcindi.qt),
                         count(*)
                    into vnvltotal,
                         vnpesototal,
                         vnvolumetotal,
                         vnnumitens
                    from pcindi,pcprodut
                   where numindeniz = p_regindenizacao.numindeniz
                   and   pcindi.codprod = pcprodut.codprod;
            
                  insert into pcindc
                    (numindeniz, --1
                     data,       --2
                     vltotal,    --3
                     codcli,     --4
                     codfilial,  --5
                     totpeso,    --6
                     totvolume,  --7
                     numitens,   --8
                     codemitente, --9
                     posicao,     --10
                     numped,      --11
                     codusur,     --12
                     obs,         --13
                     tipoindeniz  --14
                     )
                  values
                    (p_regindenizacao.numindeniz, --1
                     p_regindenizacao.data,       --2
                     round(vnvltotal, gregpcconsum.numcasasdecvenda),   --3
                     p_regindenizacao.codcli,     --4
                     p_regindenizacao.codfilial,   --5
                     vnpesototal,     --6
                     vnvolumetotal,   --7
                     vnnumitens,    --8
                     p_regindenizacao.codemitente, --9
                     'A',--decode(p_regindenizacao.posicao,'P','A','B','A','L','A',p_regindenizacao.posicao),     --10
                     p_regindenizacao.numped,      --11
                     p_regindenizacao.codusur,     --12
                     p_regindenizacao.obs,           --13
                     p_regindenizacao.tipoindeniz     --14
                     );
                     
                   if vbgeracredito = true then
                   
                     insert into pccrecli(codcli,      --1
                                          dtlanc,      --2
                                          codfilial,   --3
                                          valor,       --4
                                          hora,        --5
                                          minuto,      --6
                                          origem,      --7
                                          historico,   --8
                                          codfunclanc, --9
                                          numped,      --10
                                          codrotina,   --11
                                          numindeniz,       --12
                                          numnota,       --13
                                          numtransvenda  --14
                                          )
                     values (p_regindenizacao.codcli,      --1
                             trunc(sysdate),               --2
                             p_regindenizacao.codfilial,   --3
                             vnvalor,                      --4
                             to_char(sysdate,'hh24'),      --5
                             to_char(sysdate,'mi'),        --6
                             'I',                          --7
                             'Indenizacao N.:'||p_regindenizacao.numindeniz,   --8
                             8888,                         --9
                             p_regindenizacao.numped,      --10
                             2596,                         --11
                             p_regindenizacao.numindeniz,   --12
                             p_regindenizacao.numnota,      --13
                             p_regindenizacao.numtransvenda  --14  
                             );
             
             
                              SELECT NVL(PCConsum.ProxNumLanc,1)
                               INTO vnProxNumLanc
                               FROM PCConsum
                              WHERE ROWNUM = 1
                             FOR UPDATE;
                        
                             UPDATE PCConsum
                                SET ProxNumLanc = NVL(PCConsum.ProxNumLanc,1) + 1
                             WHERE ROWNUM = 1;
        
        
                            insert into pclanc(
                              RECNUM,         --1
                              DTLANC,         --2
                              CODCONTA,       --3
                              CODFORNEC,      --4
                              HISTORICO,      --5
                              NUMNOTA,        --6
                              VALOR,          --7
                              DTVENC,         --8
                              CODFILIAL,      --9
                              INDICE,         --10
                              dtpagto,        --11
                              vpago,          --12
                              tipoparceiro,   --13
                              nomefunc,       --14
                              moeda,          --15
                              duplic          --16
                              ) 
                            values (vnproxnumlanc,           --1
                                    trunc(sysdate),          --2
                                    p_regfilial.codcontadespindeniz,  --3        
                                    p_regindenizacao.codcli,     --4
                                    '1',--p_regindenizacao.historico,  --5
                                    0,                       --6
                                    vnvalor,                 --7
                                    trunc(sysdate),          --8
                                    p_regindenizacao.codfilial,  --9
                                    'A',                         --10
                                    trunc(sysdate),              --11
                                    vnvalor,                     --12
                                    'C',                         --13
                                    'FORCA DE VENDAS',           --14
                                    'R',                         --15
                                    1                            --16
                                    );                               
        
                   
                   end if;
                     
            
                  return true;

          else
          
            return false;
                  
           end if;
           
           
        
          
    else
      proc_registralog(null,
                       p_regindenizacao.codindeniz,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '9',
                       ';ERRO AO GRAVAR INDENIZACAO#; NAO POSSUI ITENS',
                       null);
      return false;
    end if;

  exception
    when others then
      proc_registralog(null,
                       p_regindenizacao.codindeniz,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '9',
                       'ERRO AO GRAVAR INDENIZACAO#;' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;
  end func_inseririndenizacao;

  function func_inseriritemindenizacao(p_regitemindeniz in t_itemindenizacao,
                                       p_regindeniz     in t_indenizacao)
    return boolean is
  begin

    insert into pcindi
      (numindeniz,    --1
       codprod,       --2
       qt,            --3
       pvenda,        --4
       perdesc,       --5
       ptabela,       --6
       obs,            --7
       recolher        --8
       )
    values
      (p_regindeniz.numindeniz,  --1
       p_regitemindeniz.codprod, --2
       p_regitemindeniz.qt,      --3
       ROUND(p_regitemindeniz.pvenda, gregpcconsum.numcasasdecvenda), --4
       p_regitemindeniz.perdesc,    --5
       ROUND(p_regitemindeniz.ptabela, gregpcconsum.numcasasdecvenda), --6
       p_regitemindeniz.obs,                --7
       p_regitemindeniz.recolher             --8
       );

    return true;
  exception
    when others then

      proc_registralog(null,
                       p_regitemindeniz.codindeniz,
                       p_regitemindeniz.codprod,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '10',
                       'ERRO AO GRAVAR ITEM INDENIZACAO#;' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;
  end func_inseriritemindenizacao;

 

 procedure proc_pcparamfilial (p_codfilial in pcfilial.codigo%type,
                              p_nome       in pcparamfilial.nome%type,
                              p_padrao     in pcparamfilial.valor%type,   
                              p_valor      out pcparamfilial.valor%type) is
                              
  vsnome      pcparamfilial.nome%type;                           
                                
 begin

   vsnome := upper(trim(p_nome));
 
 
      begin
      select nvl(p.valor,p_padrao)
      into p_valor
      from pcparamfilial p
      where upper(trim(p.nome)) = vsnome
      and  p.codfilial = p_codfilial;
      exception

      when no_Data_found then

        BEGIN

          select nvl(p.valor,p_padrao)
          into p_valor
          from pcparamfilial p
          where upper(trim(p.nome)) = vsnome
          and  p.codfilial = '99';
        exception
          when no_data_found then

             p_valor := p_padrao;

        end;

      when others then
       p_valor  := p_padrao;

      end;

    
 
 end proc_pcparamfilial ;                             

 procedure proc_parametros ( p_codfilial in pcfilial.codigo%type,
                             p_regfilial in out t_filial) is
 
 begin 
 
         select codigo,
               uf,
               permitirvendainterestadualpf,
               permitirvendaestadualpfcomie,
               permitirvendaestadualpfsemie,
               nvl(pcfilial.calcestdispcomqtminautoserv, 'N'),
               nvl(pcfilial.usaintegracaowms, 'N'),
               ' ',
               pcfilial.calcularipivenda,
               'N',
               'N',
               'N',
               'N',
               'P',
               'N',
               'N',
               'N',
               pcfilial.origemcustofilialretira,
               'N',
               'N',
               'N',
                nvl(pcfilial.tipoavaliacaocomissao,1),
                pcfilial.considerarcomissaozero,
                'N',
                'RI',
                'N',
                'S',
                'N' ,
                'N',
                'S',
                0,
                'N',
                0,
                'N',
                'S',
                'N',
                 0,
                'N',
                'N' ,
                'S',
                 0,
                 'S',
                 0,
                 'B',
                 'N',
                 'N',
                 null,
                 0,
                 0,
                'S',
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                0
          into p_regfilial
          from pcfilial
         where codigo = p_codfilial;

     --tarefa 170701
     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_BROKER',
                        'N',
                         p_regfilial.broker);
     

     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_TIPOBROKER',
                        ' ',
                         p_regfilial.tipobroker);
     
      --tarefa 130781
     proc_pcparamfilial(p_regfilial.codigo,
                        'UTILIZACONTROLEMEDICAMENTOS',
                        'N',
                         p_regfilial.utilizacontrolemedicamentos);




      --tarefa 131429
     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_UTILIZAVENDAPOREMBALAGEM',
                        'N',
                         p_regfilial.utilizavendaporembalagem);


     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_PRECOPOREMBALAGEM',
                        'N',
                         p_regfilial.precoporembalagem);


     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_TIPOPRECIFICACAO',
                        'P',
                         p_regfilial.tipoprecificacao);



      --tarefa 133185

     proc_pcparamfilial(p_regfilial.codigo,
                        'VALIDAALVARAPORITEM',
                        'N',
                         p_regfilial.validaalvaraporitem);

   --tarefa 133319
     proc_pcparamfilial(p_regfilial.codigo,
                        'ARREDONDAQTEMBALFRIOS',
                        'N',
                         p_regfilial.arredondaqtembalfrios);



      --tarefa 134170

     proc_pcparamfilial(p_regfilial.codigo,
                        'ACEITAVENDASEMESTFV',
                        'N',
                         p_regfilial.aceitavendasemestfv);


      --tarefa 129117
     proc_pcparamfilial(p_regfilial.codigo,
                        'NAOUSARAUTDEBCREDPOLDESC',
                        'N',
                         p_regfilial.naousarautdebcredpoldesc);


      --tarefa 135986

     proc_pcparamfilial(p_regfilial.codigo,
                        'ACEITADESCTMKFV',
                        'N',
                         p_regfilial.aceitadesctmkfv);

     proc_pcparamfilial(p_regfilial.codigo,
                        'ACEITAVENDARCASEMSALDOFV',
                        'N',
                         p_regfilial.aceitavendarcasemsaldofv);


      --tarefa 137320
     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_BLOQUEARPEDIDOSABAIXOVLMINIMO',
                        'N',
                         p_regfilial.bloquearpedidosabaixovlminimo);


     --tarefa 138958

     proc_pcparamfilial(p_regfilial.codigo,
                        'TIPOIMPORTACAOVENDA',
                        'RI',
                         p_regfilial.tipoimportacaovenda);


     --tarefa 134500

     proc_pcparamfilial(p_regfilial.codigo,
                        'SOMACREDITOCLIPRINCIPAL',
                        'N',
                         p_regfilial.somacreditocliprincipal);


     --tarefa 134487
     proc_pcparamfilial(p_regfilial.codigo,
                        'USABNFLIMITECREDITO',
                        'S',
                         p_regfilial.usabnflimitecredito);


     --146855
     proc_pcparamfilial(p_regfilial.codigo,
                        'ACEITAVENDAAVISTACLIBLOQ',
                        'N',
                         p_regfilial.aceitavendaavistaclibloq);


     proc_pcparamfilial(p_regfilial.codigo,
                        'VALIDARPOLITICASDESCCLIBLOQ',
                        'N',
                         p_regfilial.validarpoliticasdescclibloq);


   --147390

     proc_pcparamfilial(p_regfilial.codigo,
                        'VERIFICABLOQUEIOSEFAZ',
                        'S',
                         p_regfilial.verificabloqueiosefaz);



   --148819

     proc_pcparamfilial(p_regfilial.codigo,
                        'VLMAXVENDABONIFICMES',
                        0,
                         p_regfilial.vlmaxvendabonificmes);


   --154566

     proc_pcparamfilial(p_regfilial.codigo,
                        'ACEITAVENDASEMDTVENCFV',
                        'N',
                         p_regfilial.aceitavendasemdtvencfv);


   --142808

     proc_pcparamfilial(p_regfilial.codigo,
                        'PERMAXDESCVENDA',
                        0,
                         p_regfilial.permaxdescvenda);

    --157620
     proc_pcparamfilial(p_regfilial.codigo,
                        'OBRIGATORIOVINCULARTV5COMTV1',
                        'N',
                         p_regfilial.obrigatoriovinculartv5comtv1);


 --158774
     proc_pcparamfilial(p_regfilial.codigo,
                        'SEPARARPRODCOMRESTRICAOTRANSP',
                        'S',
                         p_regfilial.separarprodcomrestricaotransp);


 --155722

     proc_pcparamfilial(p_regfilial.codigo,
                        'USAABATIMENTO',
                        'N',
                         p_regfilial.usaabatimento);


 --155722

     proc_pcparamfilial(p_regfilial.codigo,
                        'PERCMAXABATIMENTO',
                        0,
                         p_regfilial.percmaxabatimento);


 -- tarefa 158674

     proc_pcparamfilial(p_regfilial.codigo,
                        'UTILIZAROTEIRIZACAO',
                        'N',
                         p_regfilial.utilizaroteirizacao);

     proc_pcparamfilial(p_regfilial.codigo,
                        'ATUALIZAROTANOMOMENTOVENDA',
                        'N',
                         p_regfilial.atualizarotanomomentovenda);


 --tarefa 162789

     proc_pcparamfilial(p_regfilial.codigo,
                        'VALIDARPRECOVENDATV20',
                        'N',
                         p_regfilial.validarprecovendatv20);

      
--156566

     proc_pcparamfilial(p_regfilial.codigo,
                        'VLMINVENDABKFILIAL',
                        0,
                         p_regfilial.vlminvendabkfilial);

     
 --tarefa 165544

     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_MONTARKITAUTOMATICAMENTE',
                        'N',
                         p_regfilial.montarkitautomaticamente);

      
      
   --164660

     proc_pcparamfilial(p_regfilial.codigo,
                        'VLMINVENDA',
                        0,
                         p_regfilial.vlminvenda);

      
     --tarefa 171612

     proc_pcparamfilial(p_regfilial.codigo,
                        'BLOQPEDLIMCRED',
                        'N',
                         p_regfilial.bloqpedlimcred);

      
--173578

     proc_pcparamfilial(p_regfilial.codigo,
                        'ABATIMENTODEBITARCCRCA',
                        'N',
                         p_regfilial.abatimentodebitarccrca);

      
      
      --185289
     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_NUMREGIAOBALCAOINTER',
                        null,
                        p_regfilial.numregiaobalcaointer);


   --185764

     proc_pcparamfilial(p_regfilial.codigo,
                        'VLMINVENDAFV',
                        0,
                         p_regfilial.vlminvendafv);


   if p_regfilial.vlminvendafv = 0 and nvl(p_regfilial.vlminvenda,0) > 0 then
   
      p_regfilial.vlminvendafv := p_regfilial.vlminvenda;
   
   end if;


     proc_pcparamfilial(p_regfilial.codigo,
                        'VLMINVENDABNFFV',
                         0,
                         p_regfilial.vlminvendabnffv);

      
   if p_regfilial.vlminvendabnffv = 0 and nvl(gregpcconsum.vlminvendabnf,0) > 0 then
   
      p_regfilial.vlminvendabnffv := nvl(gregpcconsum.vlminvendabnf,0);
   
   end if;


     proc_pcparamfilial(p_regfilial.codigo,
                        'VALIDAVLMINVENDABALCAO',
                        'S',
                         p_regfilial.validavlminvendabalcao);

 
   -- 193128
     proc_pcparamfilial(p_regfilial.codigo,
                        'CON_INFORMARECEBEDORVENDA',
                        'N',
                         p_regfilial.informarecebedorvenda);

     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_UTILIZANFE',
                        'N',
                         p_regfilial.utilizanfe);

     proc_pcparamfilial(p_regfilial.codigo,
                        'FIL_USACODCLIVENDA',
                        'N',
                         p_regfilial.usacodclivenda);

     proc_pcparamfilial(p_regfilial.codigo,
                        'SEPARARPRODCOMST',
                        'N',
                         p_regfilial.separarprodcomst);

     proc_pcparamfilial(p_regfilial.codigo,
                        'VERIFICAESTOQUECONT',
                        'N',
                         p_regfilial.verificaestoquecont);

     proc_pcparamfilial(p_regfilial.codigo,
                        'VALIDARCLISEFAZ',
                        'N',
                         p_regfilial.validarclisefaz);

     proc_pcparamfilial(p_regfilial.codigo,
                        'RESERVARESTOQUETV7',
                        'N',
                         p_regfilial.reservarestoquetv7);

     --207036
     proc_pcparamfilial(p_regfilial.codigo,
                        'BLOQPEDABAIXOMARGEMFV',
                        'N',
                         p_regfilial.bloqpedabaixomargemfv  );
     
     --211582
     proc_pcparamfilial(p_regfilial.codigo,
                        'GERARCREDITOINDENIZFV',
                        'N',
                         p_regfilial.gerarcreditoindenizfv  );

     --211582
     proc_pcparamfilial(p_regfilial.codigo,
                        'CODCONTADESPINDENIZ',
                        0,
                         p_regfilial.codcontadespindeniz );

 
 end proc_parametros;


   procedure proc_validarindenizacao(p_regindenizacao in out t_indenizacao,
                                    p_regcliente     in out t_clientepedido,
                                    p_regplpagpedido out    t_planodepagamento,
                                    p_regfilial      in out t_filial) is

    p_regregiao         t_regiaocliente;
    vsmensagem          varchar2(32767):= null;
    vschar              varchar2(1) default '#';
    vicontador          number;
    vnnumped            pcpedc.numped%type;
    vncodplpag          pcpedc.codplpag%type;
    vsposicao           pcpedc.posicao%type;
    vnproxnumindeniz    pcconsum.proxnumindeniz%type;
    vnproxnumtransvenda pcconsum.proxnumtransvenda%type;
    vnvlpedidoorig      pcpedc.vltotal%type;
    vncondvenda         pcpedc.condvenda%type;
    vddata              pcpedc.data%type;
    vscodfilialnf       pcpedc.codfilialnf%type;
    vsnumregiao         pcregiao.numregiao%type;
    vnnumregiao         pcregiao.numregiao%type;
    vstipoprazo         pcplpag.tipoprazo%type;
    vscodcob            pcpedc.codcob%type;
    vscodfilial         pcpedc.codfilial%type;


  begin

    p_regindenizacao.valido := true;
    vsmensagem              := null;


     --01. Verificar se o Cliente esta Cadastrado
      select count(*)
        into vicontador
        from pcclient
       where  trim(replace(replace(replace(replace(replace(replace(cgcent,' ',''), '.', ''),
                                                    ',',
                                                    ''),
                                            '-',
                                            ''),
                                    '/',
                                    ''),
                            '\',
                            '')) =  trim(replace(replace(replace(replace(replace(replace(p_regindenizacao.cgccli,' ',''), '.', ''),
                                                    ',',
                                                    ''),
                                            '-',
                                            ''),
                                    '/',
                                    ''),
                            '\',
                            ''))
      and dtexclusao is null ;

      if vicontador = 0 then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem           := vsmensagem || vschar ||
                                'CLIENTE NAO CADASTRADO OU EXCLUIDO;';
        p_regindenizacao.valido := false;

      elsif vicontador = 1 then


          select codcli
            into p_regindenizacao.codcli
            from pcclient
           where  trim(replace(replace(replace(replace(replace(replace(cgcent,' ',''), '.', ''),
                                                        ',',
                                                        ''),
                                                '-',
                                                ''),
                                        '/',
                                        ''),
                                '\',
                                '')) =  trim(replace(replace(replace(replace(replace(replace(p_regindenizacao.cgccli,' ',''), '.', ''),
                                                        ',',
                                                        ''),
                                                '-',
                                                ''),
                                        '/',
                                        ''),
                                '\',
                                ''))
          and dtexclusao is  null    ;


      else

        if p_regindenizacao.codcli is null then

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;
            vsmensagem           := vsmensagem || vschar ||
                                    'ENCONTRADO MAIS DE UM CLIENTE PARA ESTE CNPJ/CPF;';
            p_regindenizacao.valido := false;

         else

             begin

              select codcli
                into p_regindenizacao.codcli
                from pcclient
               where  trim(replace(replace(replace(replace(replace(replace(cgcent,' ',''),'.', ''),
                                                            ',',
                                                            ''),
                                                    '-',
                                                    ''),
                                            '/',
                                            ''),
                                    '\',
                                    '')) =  trim(replace(replace(replace(replace(replace(replace(p_regindenizacao.cgccli,' ',''), '.', ''),
                                                            ',',
                                                            ''),
                                                    '-',
                                                    ''),
                                            '/',
                                            ''),
                                    '\',
                                    ''))
              and dtexclusao is  null
              and pcclient.codcli = p_regindenizacao.codcli   ;
          exception when others then

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;
            vsmensagem           := vsmensagem || vschar ||
                                    'ERRO AO BUSCAR CLIENTE DA INDENIZACAO;';
            p_regindenizacao.valido := false;

          end;


         end if;


      end if;



    --02. Verificar se pedido existe
    select count(*)
      into vicontador
      from pcpedc
     where numpedrca = p_regindenizacao.numpedrca
       and codusur   = p_regindenizacao.codusur
       and codcli    = p_regindenizacao.codcli
       and numpedorigem is null
       and decode(condvenda,14,'N',nvl(brinde,'N')) = 'N' ;

    if vicontador = 0 then
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem              := vsmensagem || vschar ||
                                 'PEDIDO INEXISTENTE;';
      p_regindenizacao.valido := false;

    else
      -- Buscar dados do pedido
      select numped, codplpag, posicao, vlatend,condvenda,data,codfilialnf,numregiao,codfilial
        into vnnumped,
             vncodplpag,
             vsposicao,
             vnvlpedidoorig,
             vncondvenda,
             vddata,
             vscodfilialnf,
             vnnumregiao,
             vscodfilial
        from pcpedc
       where numpedrca = p_regindenizacao.numpedrca
         and codusur   = p_regindenizacao.codusur
         and codcli    = p_regindenizacao.codcli
         and numpedorigem is null
         and decode(condvenda,14,'N',nvl(brinde,'N')) = 'N' ;


            p_regindenizacao.numregiao := vnnumregiao;
            p_regindenizacao.codfilialnf := vscodfilialnf;
            p_regindenizacao.codfilial := vscodfilial;


      proc_parametros ( p_regindenizacao.codfilial,
                        p_regfilial);

      --03. Verificar se ja nao existe indenizacao para o pedido
      select count(*)
      into vicontador
      from pcindc
      where numped = vnnumped;

      if vicontador > 0 then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem              := vsmensagem || vschar ||
                                   'JA EXISTE INDENIZACAO PARA O PEDIDO;';
        p_regindenizacao.valido := false;


      else

             --para tipoindeniz = T (TROCA) o pedido enviado precisa ser bonificado
         if p_regindenizacao.tipoindeniz = 'T' then
         
            begin
             select pcplpag.tipoprazo
             into vstipoprazo
             from pcplpag
             where codplpag = vncodplpag;
             exception when others then
              vstipoprazo := null;
             end;
         
         
             if vncondvenda <> 5 then
             
               if vncondvenda in (13,14) then
                   if (vstipoprazo <> 'B' or vscodcob <> 'BNF') then

                    if vsmensagem is not null then
                      vschar := '#';
                    else
                      vschar := null;
                    end if;

                    vsmensagem              := vsmensagem || vschar ||
                                               'PARA TROCA, PEDIDO MANIFESTO ENVIADO PRECISA SER BONFICADO;';
                    p_regindenizacao.valido := false;
                  end if  ;
                    
                else    
                    if vsmensagem is not null then
                      vschar := '#';
                    else
                      vschar := null;
                    end if;

                    vsmensagem              := vsmensagem || vschar ||
                                               'PARA TROCA, PEDIDO ENVIADO PRECISA SER BONFICADO;';
                    p_regindenizacao.valido := false;


                end if;
             end if; 

         end if;
      end if;

    if p_regindenizacao.valido = true then

      --04. Verificar dados do cliente

        select NVL(pcclient.bloqueio, 'N') bloqueio,
               NVL(pcclient.calculast, 'S'),
               pcclient.cliente,
               pcclient.codcli,
               pcclient.codcliprinc,
               pcclient.codcob,
               pcclient.codfilialnf,
               pcclient.codplpag,
               pcclient.codpraca,
               pcclient.condvenda1,
               pcclient.condvenda2,
               pcclient.condvenda3,
               pcclient.condvenda4,
               pcclient.condvenda5,
               pcclient.condvenda6,
               pcclient.condvenda10,
               NVL(pcclient.descproduto, 'N') descproduto,
               pcclient.estent,
               pcclient.ieent,
               NVL(pcclient.limcred, 0) limcred,
               NVL(pcplpag.numdias, 0) numdias,
               pcclient.percomcli,
               NVL(pcclient.perdesc, 0) perdesc,
               NVL(pcclient.prazoadicional, 0) prazoadicional,
               pcclient.tipofj,
               pcpraca.numregiao,
               pcclient.codatv1,
               pcclient.validamaxvendapf,
               pcclient.consumidorfinal,
               nvl(pcclient.clientefontest, 'N'),
               nvl(pcclient.isentoicms, 'N'),
               nvl(pcclient.utilizaiesimplificada, 'N'),
               tipoempresa,
               nvl(pcclient.contribuinte, 'S'),
               pcclient.classevenda,
               nvl(pcclient.isentoipi, 'N'),
               pcclient.sulframa,
               nvl(pcclient.tipodescisencao, 'N'),
               nvl(perdescisentoicms, 0),
               nvl(pcclient.usaivafontediferenciado, 'N'),
               nvl(ivafonte, 0),
               nvl(pcclient.orgaopub, 'N'),
               nvl(pcclient.orgaopubfederal, 'N'),
               pcclient.cepent,
               pcclient.municent,
               pcclient.enderent,
               pcclient.cgcent,
               pcclient.origempreco,
               pcclient.repasse,
               pcclient.dtvencalvara,
               pcclient.dtvencalvarafunc,
               pcclient.dtvencalvaraanvisa,
               pcclient.dtvenccrf,
               nvl(pcclient.simplesnacional,'N'),
               pcclient.validarmultiplovenda,
               pcclient.clientemonitorado ,
               pcclient.codrede ,
               pcclient.validarcampanhabrinde,
               pcclient.utilizaplpagmedicamento,
               pcclient.codplpagetico,
               pcclient.codplpaggenerico,
               pcclient.bloqueiosefaz,
               nvl(pcclient.tipocustotransf,'R'),
               nvl(pcclient.peracrestransf,0),
               pcclient.registroibama,
               pcclient.dtvalidadeibama,
               nvl(pcclient.isencaosuframa,'T'),
               pcclient.fretedespacho,
               pcclient.turnoentrega,
               pcclient.telent,
               pcclient.bairroent,
               nvl(pcclient.usadescontoicms,'N'),
               nvl(pcclient.utilizacalculostmt,'N'),
               nvl(pccnae.percargatribmedia,0),
               nvl(pccnae.margemmva,0),
               pcclient.aceitavendafracao,
               pcclient.obsentrega1,
               pcclient.obsentrega2,                   
               pcclient.obsentrega3,                   
               pcclient.obsentrega4,
               pcclient.usadebcredrca                  
          into p_regcliente
          from pcclient, pcplpag, pcpraca,pccnae
         where pcclient.codcli = p_regindenizacao.codcli
           and pcclient.codpraca = pcpraca.codpraca
           and pcclient.codplpag = pcplpag.codplpag(+)
           and pcclient.codcnae  = pccnae.codcnae(+);

      begin
        select numregiao
          into vsnumregiao
          from pctabprcli
         where codcli = p_regindenizacao.codcli
           and codfilialnf = nvl(vscodfilialnf,nvl(p_regcliente.codfilialnf,p_regindenizacao.codfilial));
      exception
        when others then
          vsnumregiao             := null;
        
      end;

      -- 06 Verifica se cliente tem acesso a várias tabelas de preço
      if vsnumregiao is not null then
        p_regcliente.numregiao := vsnumregiao;
      end if;           
           
      
      if p_regindenizacao.numregiao is null then
         p_regindenizacao.numregiao := p_regcliente.numregiao;
      end if;     
           
        -- 05. Verificar se a Praca do Cliente esta Cadastrada
        --Buscar regiao da praca do cliente
        select count(*)
          into vicontador
          from pcpraca, pcregiao
         where pcpraca.numregiao = pcregiao.numregiao
           and pcpraca.codpraca = p_regcliente.codpraca
          and   pcregiao.status = 'A';
    
        if vicontador = 0 then
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem              := vsmensagem || vschar || ';PRACA ' ||
                                     TO_CHAR(p_regcliente.codpraca) ||
                                     ' NAO CADASTRADA;';
          p_regindenizacao.valido := false;
        end if;

        -- Buscar o Numero da Regiao do Cliente
        if vicontador > 0 then

          select pcregiao.numregiao,
                 pcregiao.perfrete,
                 nvl(pcregiao.perfreteespecial, 0),
                 nvl(pcregiao.perfreteterceiros, 0),
                 nvl(pcregiao.regiaozfm,'N'),
                 pcregiao.codestabelecimento
            into p_regregiao
            from pcregiao
           where pcregiao.numregiao = p_regcliente.numregiao
             and pcregiao.status = 'A';



        end if;



      --06. Plano de Pagamento do Pedido
      select count(*)
        into vicontador
        from pcplpag
       where codplpag = vncodplpag;

      if vicontador = 0 then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem              := vsmensagem || vschar ||
                                   ';PLANO DE PAGAMENTO ' || vncodplpag ||
                                   ' NAO CADASTRADO.';
        p_regindenizacao.valido := false;
      end if;

      if vicontador > 0 then

        select codplpag,
               numdias,
               numitensminimo,
               numpr,
               obs,
               NVL(pertxfim, 0),
               prazo1,
               prazo2,
               prazo3,
               prazo4,
               prazo5,
               prazo6,
               prazo7,
               prazo8,
               prazo9,
               prazo10,
               prazo11,
               prazo12,
               tipoprazo,
               tipovenda,
               NVL(vlminpedido, 0),
               vendabk,
               NVL(tiporestricao, 'NR'),
               codrestricao,
               trim(codfilial),
               pcplpag.formaparcelamento,
               nvl(pcplpag.usamultifilial,'N'),
               nvl(pcplpag.diasminparcela,0),
               nvl(pcplpag.diasmaxparcela,0),
               nvl(pcplpag.vlminparcela,0),
               pcplpag.numparcelas,
               pcplpag.tipoentrada,
               nvl(pcplpag.margemmin,0),
               nvl(pcplpag.descentlimcredcli,'N')
          into p_regplpagpedido
          from pcplpag
         where codplpag = vncodplpag;
      end if;


    if p_regplpagpedido.codfilial is not null and
       p_regplpagpedido.codfilial <> p_regindenizacao.codfilial and
       p_regplpagpedido.codfilial <> '99' then
      IF vsmensagem IS NOT NULL THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem              := vsmensagem || vschar ||
                                 'PLANO DE PAGAMENTO ' || vncodplpag ||
                                 ' NAO EXISTE PARA A FILIAL ' ||
                                 p_regindenizacao.codfilial || ';';
      p_regindenizacao.valido := FALSE;
    end if;

    --07. Numeracao da indenizacao
    if p_regindenizacao.valido = true then
      begin
        select NVL(proxnumindeniz, 0),nvl(proxnumtransvenda,0)
          into vnproxnumindeniz,vnproxnumtransvenda
          from pcconsum
           for update;

        update pcconsum
           set proxnumindeniz    = NVL(proxnumindeniz, 0) + 1,
               proxnumtransvenda = NVL(proxnumtransvenda, 0) + 1;

        p_regindenizacao.numindeniz    := vnproxnumindeniz;
        p_regindenizacao.numnota       := vnproxnumtransvenda;
        p_regindenizacao.numtransvenda  := vnproxnumtransvenda;        
        p_regindenizacao.numped        := vnnumped;
        p_regindenizacao.DATA          := TRUNC(sysdate);
        p_regindenizacao.codemitente   := 8888;
        p_regindenizacao.posicao       := vsposicao;
        p_regindenizacao.vltotal       := 0;
        p_regindenizacao.vltotalpedido := vnvlpedidoorig;
        p_regindenizacao.totpeso       := 0;
        p_regindenizacao.totvolume     := 0;
        p_regindenizacao.numitens      := 0;
        p_regindenizacao.datapedido    := vddata;

      exception
        when others then

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem              := vsmensagem || vschar ||
                                     'NAO FOI POSSIVEL BUSCAR PROX. NUMERO DE INDENIZACAO;';
          p_regindenizacao.valido := false;
      end;

    end if;
    end if;
    end if;
    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       p_regindenizacao.codindeniz,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '9',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then
      p_regindenizacao.valido := false;
      proc_registralog(null,
                       p_regindenizacao.codindeniz,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '9',
                       sqlcode || '-' || sqlerrm||';',
                       null);
  end proc_validarindenizacao;

  procedure proc_validaritemindenizacao(p_regitemindenizacao in out t_itemindenizacao,
                                        p_regindenizacao     in     t_indenizacao,
                                        p_regcliente         in t_clientepedido,
                                        p_regplpag           in t_planodepagamento) is
    p_regproduto  t_produto;
    p_regprecos   t_precosetributacao;
    vsmensagem    varchar2(32767):= null;
    vschar        varchar2(1) default '#';
    vicontador    number;
    vnperdesc     number;
    vnptabelaunit number;
    vscodfilialnf pcpedc.codfilialnf%type;
    vncodst       pcpedi.codst%type;
    vnperdescativ pcativi.percdesc%type;
  begin
    p_regitemindenizacao.valido := true;
    vsmensagem                  := null;
    vnperdesc                   := 0;

    -- 01. Verificar se o Produto esta Cadastrado
    select count(*)
      into vicontador
      from pcprodut
     where codprod = p_regitemindenizacao.codprod;

    if vicontador = 0 then
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem                  := vsmensagem || vschar ||
                                     'PRODUTO NAO CADASTRADO;';
      p_regitemindenizacao.valido := false;
    else

      select codcategoria,
             codepto,
             codfornec,
             pcprodut.codprod,
             codsec,
             descricao,
             embalagem,
             pcprodut.obs,
             pcprodut.obs2,
             NVL(pcomext1, 0),
             NVL(pcomint1, 0),
             NVL(pcomrep1, 0),
             NVL(pesobruto, 0),
             0,
             NVL(qtunit, 1),
             NVL(volume, 0),
             codprodprinc,
             --               NVL (qtunitct, 1),
             --             NVL (qtunitcx, 1),
             NVL(perindeniz, 0),
             codlinhaprod,
             coddistrib,
             pcprodut.freteespecial,
             pcprodut.classe,
             pcprodut.percipivenda,
             nvl(pcprodut.prazomediovenda, 0),
             pcprodut.importado,
             nvl(PCPRODUT.PERCIPIVENDATAB, 0),
             nvl(PCPRODUT.VLPAUTAIPIVENDA, 0),
             nvl(PCPRODUT.VLPAUTAIPIVENDATAB, 0),
             nvl(PCPRODUT.VLIPIPORKGVENDA, 0),
             nvl(PCPRODUT.VLIPIPORKGVENDATAB, 0),
             nvl(pcprodut.prazomaxindenizacao,0),
             pcprodut.pesobrutomaster,
             pcprodut.pesopeca,
             pcprodut.tipoestoque,
             pcprodut.tipomerc,
             nvl(pcprodut.custorep,0),
             nvl(pcprodut.custorepzfm,0),
             pcprodut.psicotropico,
             nvl(pcprodut.percbonificvenda,0),
             pcprodut.utilizaprecomaxconsumidor,
             nvl(pcprodut.precomaxconsum,0),
             pcprodut.unidademaster,
             nvl(pcprodut.multiplo,0),
             pcprodut.checarmultiplovendabnf,
             pcprodut.codfilialretira,
             pcprodut.tipocomissao,
             nvl(pcprodut.grupofaturamento,'N'),
             pcprodut.codsubcategoria,
             nvl(pcprodut.controladoibama,'N'),
             pcprodut.revenda,
             pcprodut.aceitavendafracao,
             pcprodut.restricaotransp
        into p_regproduto
        from pcprodut
       where codprod = p_regitemindenizacao.codprod;


  --tributacao por estado
              if nvl(gregpcconsum.usatributacaoporuf, 'N') = 'S' then


                if p_regindenizacao.codfilialnf is null then

                   if p_regcliente.codfilialnf is null then

                      vscodfilialnf := p_regindenizacao.codfilial;
                   else

                      vscodfilialnf := p_regcliente.codfilialnf;
                   end if;
                else

                  vscodfilialnf := p_regindenizacao.codfilialnf;
                end if;


                select count(*)
                  into vicontador
                  from pctabtrib p
                 where p.codprod = p_regitemindenizacao.codprod
                   and p.codfilialnf = vscodfilialnf
                   and p.ufdestino = p_Regcliente.estent;

                if vicontador = 0 then
                  if vsmensagem is not null then
                    vschar := '#';
                  else
                    vschar := null;
                  end if;
                  vsmensagem              := vsmensagem || vschar ||
                                             'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

                  p_regitemindenizacao.valido        := false;


                else

                  select p.codst
                    into vncodst
                    from pctabtrib p
                   where p.codprod = p_regitemindenizacao.codprod
                     and p.codfilialnf = vscodfilialnf
                     and p.ufdestino = p_Regcliente.estent
                     and rownum = 1;


                   begin

                    select NVL(pctribut.aliqicms1, 0),
                           NVL(pctribut.aliqicms2, 0),
                           NVL(pctribut.codicmtab, 0),
                           pctribut.codst,
                           NVL(pcest.custocont, 0),
                           NVL(pcest.custofin, 0),
                           NVL(pcest.custoreal, 0),
                           NVL(pcest.custorep, 0),
                           NVL(pcest.custoultent, 0),
                           NVL(pctabpr.excluido, 'N'),
                           NVL(pctribut.iva, 0),
                           NVL(pctribut.pauta, 0),
                           NVL(pctribut.peracrescismopf, 0),
                           NVL(pctabpr.perdescautor, 0),
                           NVL(pctribut.perdesccusto, 0),
                           NVL(pctabpr.perdescmax, 0),
                           NVL(pctabpr.perdescmaxesp, 0),
                           pctribut.perdestab,
                           NVL(pctabpr.precominimovenda, 0),
                           NVL(pctabpr.pvenda, 0),
                           NVL(pctabpr.pvenda1, 0),
                           NVL(pctabpr.pvenda2, 0),
                           NVL(pctabpr.pvenda3, 0),
                           NVL(pctabpr.pvenda4, 0),
                           NVL(pctabpr.pvenda5, 0),
                           NVL(pctabpr.pvenda6, 0),
                           NVL(pctabpr.pvenda7, 0),
                           NVL(pctabpr.qtdescautor, 0),
                           NVL(pctribut.aplicaacrescpjisenta, 'N'),
                           nvl(pctribut.percbaseredst, 0),
                           nvl(pctribut.tipocalculognre, 'P'),
                           NVL(pctribut.ivafonte, 0),
                           NVL(pctribut.aliqicms1fonte, 0),
                           NVL(pctribut.aliqicms2fonte, 0),
                           NVL(pctribut.percbaseredstfonte, 0),
                           nvl(pctribut.percbasered, 0),
                           nvl(pctribut.perbaserednrpa, 0),
                           nvl(pctribut.percbaseredconsumidor, 0),
                           nvl(utilizapercbaseredpf, 'N'),
                           nvl(pcest.valorultent,0),
                           nvl(pctribut.usavalorultentbasest, 'N'),
                           nvl(pctribut.usavalorultentbasest2, 'N'),
                           NVL(pctribut.codicmtabpf, 0),
                           nvl(pctribut.perdescsuframa, 0),
                           nvl(pctribut.perdescicmisencao, 0),
                           pctabpr.descontafrete,
                           nvl(pctribut.percdescpis, 0),
                           nvl(pctribut.percdesccofins, 0),
                           nvl(pctribut.perdescrepasse,0) ,
                           nvl(pctabpr.precomaxconsum,0),
                           1 ,
                           1,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           null,
                           null,
                           null,
                           null,
                           0  ,
                           nvl(pctribut.mostrarpvendasemst,gregpcconsum.mostrarpvendasemst),
                           nvl(pctribut.usapmcbasest,'N'),
                           nvl(pcest.custonfsemst,nvl(pcest.valorultent,0)),
                           nvl(pctribut.percredpvendasimplesnac,0),
                           nvl(pcest.vlstultent,0),
                           nvl(pctribut.percdifaliquotas,0),
                           nvl(pcest.custonfsemstguiaultent,0),
                           nvl(pcest.ivaultent,0),
                           nvl(pcest.aliqicms1ultent,0),
                           nvl(pcest.aliqicms2ultent,0),
                           nvl(pcest.redbaseivaultent,100),
                           nvl(pcest.percicmsfretefobstultent,0),
                           nvl(pcest.vlfreteconhecultent,0),
                           nvl(pcest.percaliqextguiaultent,0),
                           nvl(pcest.baseicmsultent,0),
                           nvl(pcest.vlstguiaultent,0),
                           nvl(pctribut.usaisencaoicmsvp,'S') ,
                           pctribut.pagtonomedocliente,
                           nvl(pctabpr.perdescmaxbalcao,0),
                           nvl(pctribut.usaaliqicmssimplesnacional,'N'),
                           nvl(pctribut.aliqstsimplesnacional,0) ,
                           nvl(pctribut.agregaripicalculost,'N'),
                           pctabpr.precofab,
                           null,
                           null,
                           null         
                      into p_regprecos
                      from pctabpr, pctribut, pcest
                     where pctribut.codst = vncodst
                       and pctabpr.codprod = p_regitemindenizacao.codprod
                       and pcest.codprod = p_regitemindenizacao.codprod
                       and pcest.codfilial = p_regindenizacao.codfilial
                       and pctabpr.numregiao = p_regindenizacao.numregiao;
                       exception when others then
                       
                       if vsmensagem is not null then
                        vschar := '#';
                      else
                        vschar := null;
                      end if;
                      vsmensagem              := vsmensagem || vschar ||
                                                 'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
                                                 sqlcode || '-' || sqlerrm || ';';
                      p_regitemindenizacao.valido        := false;
                       
                       end;
                       
                       
                       
               end if;   
                       
           else
           
            begin
             select NVL(pctribut.aliqicms1, 0),
             NVL(pctribut.aliqicms2, 0),
             NVL(pctribut.codicmtab, 0),
             pctabpr.codst,
             NVL(pcest.custocont, 0),
             NVL(pcest.custofin, 0),
             NVL(pcest.custoreal, 0),
             NVL(pcest.custorep, 0),
             NVL(pcest.custoultent, 0),
             NVL(pctabpr.excluido, 'N'),
             NVL(pctribut.iva, 0),
             NVL(pctribut.pauta, 0),
             NVL(pctribut.peracrescismopf, 0),
             NVL(pctabpr.perdescautor, 0),
             NVL(pctribut.perdesccusto, 0),
             NVL(pctabpr.perdescmax, 0),
             NVL(pctabpr.perdescmaxesp, 0),
             pctribut.perdestab,
             NVL(pctabpr.precominimovenda, 0),
             NVL(pctabpr.pvenda, 0),
             NVL(pctabpr.pvenda1, 0),
             NVL(pctabpr.pvenda2, 0),
             NVL(pctabpr.pvenda3, 0),
             NVL(pctabpr.pvenda4, 0),
             NVL(pctabpr.pvenda5, 0),
             NVL(pctabpr.pvenda6, 0),
             NVL(pctabpr.pvenda7, 0),
             NVL(pctabpr.qtdescautor, 0),
             NVL(pctribut.aplicaacrescpjisenta, 'N'),
             nvl(pctribut.percbaseredst, 0),
             nvl(pctribut.tipocalculognre, 'P'),
             NVL(pctribut.ivafonte, 0),
             NVL(pctribut.aliqicms1fonte, 0),
             NVL(pctribut.aliqicms2fonte, 0),
             NVL(pctribut.percbaseredstfonte, 0),
             nvl(pctribut.percbasered, 0),
             nvl(pctribut.perbaserednrpa, 0),
             nvl(pctribut.percbaseredconsumidor, 0),
             nvl(utilizapercbaseredpf, 'N'),
             nvl(pcest.valorultent,0),
             nvl(pctribut.usavalorultentbasest, 'N'),
             nvl(pctribut.usavalorultentbasest2, 'N'),
             NVL(pctribut.codicmtabpf, 0),
             nvl(pctribut.perdescsuframa, 0),
             nvl(pctribut.perdescicmisencao, 0),
             pctabpr.descontafrete,
             nvl(pctribut.percdescpis, 0),
             nvl(pctribut.percdesccofins, 0),
             nvl(pctribut.perdescrepasse,0) ,
             nvl(pctabpr.precomaxconsum,0),
             1 ,
             1,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             null,
             null,
             null,
             null,
             0  ,
             nvl(pctribut.mostrarpvendasemst,gregpcconsum.mostrarpvendasemst),
             nvl(pctribut.usapmcbasest,'N'),
             nvl(pcest.custonfsemst,nvl(pcest.valorultent,0)),
             nvl(pctribut.percredpvendasimplesnac,0),
             nvl(pcest.vlstultent,0),
             nvl(pctribut.percdifaliquotas,0),
             nvl(pcest.custonfsemstguiaultent,0),
             nvl(pcest.ivaultent,0),
             nvl(pcest.aliqicms1ultent,0),
             nvl(pcest.aliqicms2ultent,0),
             nvl(pcest.redbaseivaultent,100),
             nvl(pcest.percicmsfretefobstultent,0),
             nvl(pcest.vlfreteconhecultent,0),
             nvl(pcest.percaliqextguiaultent,0),
             nvl(pcest.baseicmsultent,0),
             nvl(pcest.vlstguiaultent,0),
             nvl(pctribut.usaisencaoicmsvp,'S') ,
             pctribut.pagtonomedocliente,
             nvl(pctabpr.perdescmaxbalcao,0),
             nvl(pctribut.usaaliqicmssimplesnacional,'N'),
             nvl(pctribut.aliqstsimplesnacional,0) ,
             nvl(pctribut.agregaripicalculost,'N'),
             pctabpr.precofab,
             null,
             null,
             null    
        into p_regprecos
        from pctabpr, pctribut, pcest
       where pctabpr.codst = pctribut.codst
         and pctabpr.codprod = p_regitemindenizacao.codprod
         and pcest.codprod = p_regitemindenizacao.codprod
         and pcest.codfilial = p_regindenizacao.codfilial
         and pctabpr.numregiao = p_regindenizacao.numregiao;
         exception when others then

                   if vsmensagem is not null then
                        vschar := '#';
                      else
                        vschar := null;
                      end if;
                      vsmensagem              := vsmensagem || vschar ||
                                                 'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
                                                 sqlcode || '-' || sqlerrm || ';';
                      p_regitemindenizacao.valido        := false;
         
         end;
         

           
           
           end if;            

      -- 03. verifica se produto esta excluido na regiao
      if p_regprecos.excluido = 'S' then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem                  := vsmensagem || vschar ||
                                       'PRODUTO VENDA PROIBIDA NA REGIAO : ' ||
                                       p_regcliente.numregiao||';';
        p_regitemindenizacao.valido := false;

      end if;

      -- 04. Verifica produto com preco 0 (zero)
      if (p_regprecos.pvenda <= 0) or (p_regprecos.pvenda1 <= 0) or
         (p_regprecos.pvenda2 <= 0) or (p_regprecos.pvenda3 <= 0) or
         (p_regprecos.pvenda4 <= 0) or (p_regprecos.pvenda5 <= 0) or
         (p_regprecos.pvenda6 <= 0) or (p_regprecos.pvenda7 <= 0) then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem                  := vsmensagem || vschar ||
                                       'PRODUTO PRECO ZERADO NA REGIAO : ' ||
                                       p_regcliente.numregiao||';';

        p_regitemindenizacao.valido := false;

      end if;

      --05. Verifica se produto pode ser indenizado
      if p_regproduto.perindeniz <= 0 then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem                  := vsmensagem || vschar ||
                                       'PRODUTO NAO PODE SER INDENIZADO. %INDENIZ. : ' ||
                                       p_regproduto.perindeniz||';';
        p_regitemindenizacao.valido := false;

      end if;

      --06. Verificar Qt. Unit do Produto
      if p_regproduto.qtunit = 0 then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem                  := vsmensagem || vschar ||
                                       'PRODUTO NAO PODE SER INDENIZADO. QT. UNIT. : ' ||
                                       p_regproduto.qtunit||';';
        p_regitemindenizacao.valido := false;

      end if;

      --07. Checar preco e quantidade pedida
      if (p_regitemindenizacao.qt <= 0) or
         (p_regitemindenizacao.pvenda <= 0) then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem                  := vsmensagem || vschar ||
                                       'PRODUTO NAO PODE SER INDENIZADO. QTDE : ' ||
                                       p_regitemindenizacao.qt || '#' ||
                                       ' PRECO: ' ||
                                       p_regitemindenizacao.pvenda;

        p_regitemindenizacao.valido := false;

      end if;

      --08. Se o item for valido verifica %Indeniz.
      if p_regitemindenizacao.valido = true then
        if p_regplpag.numpr = 1 then
          p_regproduto.ptabela := p_regprecos.pvenda1;
        elsif p_regplpag.numpr = 2 then
          p_regproduto.ptabela := p_regprecos.pvenda2;
        elsif p_regplpag.numpr = 3 then
          p_regproduto.ptabela := p_regprecos.pvenda3;
        elsif p_regplpag.numpr = 4 then
          p_regproduto.ptabela := p_regprecos.pvenda4;
        elsif p_regplpag.numpr = 5 then
          p_regproduto.ptabela := p_regprecos.pvenda5;
        elsif p_regplpag.numpr = 6 then
          p_regproduto.ptabela := p_regprecos.pvenda6;
        elsif p_regplpag.numpr = 7 then
          p_regproduto.ptabela := p_regprecos.pvenda7;
        end if;

        --VEN-3575
        --Tulio Sousa
        --Inserir desconto por atividade no preço de tabela da indenização
        ---------------------------------------------------DESCONTO POR ATIVIDADE---------------------------------------------------
        BEGIN
          SELECT NVL(pcativi.percdesc, 0)
            INTO vnperdescativ
            FROM pcativi, pcclient
           WHERE pcclient.codcli = p_regcliente.codcli
             AND pcclient.codatv1 = p_regcliente.codatv1;
        EXCEPTION
          WHEN OTHERS THEN
            vnperdescativ := 0;
        END;

        IF (vnperdescativ <> 0) THEN
          p_regproduto.ptabela := (p_regproduto.ptabela +
                                  (p_regproduto.ptabela * vnperdescativ / 100));
        END IF;
        ---------------------------------------------------FIM DESCONTO POR ATIVIDADE---------------------------------------------------

        if p_regproduto.qtunit <> 0 then
          vnptabelaunit := p_regproduto.ptabela / p_regproduto.qtunit;
        else
          vnptabelaunit := p_regproduto.ptabela;
        end if;

        if TO_NUMBER(NVL(vnptabelaunit, 0)) <> 0 then
          vnperdesc := trunc((ROUND(TO_NUMBER(p_regitemindenizacao.pvenda), gregpcconsum.numcasasdecvenda) /
                       ROUND(TO_NUMBER(vnptabelaunit), gregpcconsum.numcasasdecvenda)) * 100);
        else
          vnperdesc := 100;
        end if;

        if vnperdesc > p_regproduto.perindeniz then
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem                  := vsmensagem || vschar ||
                                         '%INDENIZ. MAIOR DO QUE O %INDENIZAÇÃO PERMITIDO PARA O PRODUTO;';
          p_regitemindenizacao.valido := false;

        end if;

        if p_regitemindenizacao.valido = true then
          p_regitemindenizacao.perdesc := vnperdesc;
          p_regitemindenizacao.ptabela := vnptabelaunit;
        end if;

        --verifica prazo maximo para indenizacao
        if p_regindenizacao.datapedido + p_regproduto.prazomaxindenizacao < trunc(sysdate) then
        if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem                  := vsmensagem || vschar ||
                                         'ULTRAPASSADO PRAZO MAXIMO PERMITIDO PARA INDENIZACAO DO PRODUTO;';
          p_regitemindenizacao.valido := false;

        end if;

      end if;

    end if; --produto existe;

    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       p_regitemindenizacao.codindeniz,
                       p_regitemindenizacao.codprod,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '10',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then

      p_regitemindenizacao.valido := false;
      proc_registralog(null,
                       p_regitemindenizacao.codindeniz,
                       p_regitemindenizacao.codprod,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '10',
                       sqlcode || '-' || sqlerrm,
                       null);

  end proc_validaritemindenizacao;

        
  procedure proc_processarlinhaindenizacao is

    vncontindeniz     number;
    vncontitemindeniz number;
    p_regcliente      t_clientepedido;
    p_regplpag        t_planodepagamento;
    p_regfilial       t_filial;

  begin

    vncontindeniz := gvet_regindenizacao.count;

    if vncontindeniz > 0 then

      for i in 1 .. vncontindeniz loop
        proc_validarindenizacao(gvet_regindenizacao(i),
                                p_regcliente,
                                p_regplpag,
                                p_regfilial);

        if gvet_regindenizacao(i).valido = true then
          vncontitemindeniz := gvet_regitemindenizacao.count;

          if vncontitemindeniz > 0 then

            for j in 1 .. vncontitemindeniz loop

              if gvet_regindenizacao(i).codindeniz = gvet_regitemindenizacao(j).codindeniz then

                proc_validaritemindenizacao(gvet_regitemindenizacao(j),
                                            gvet_regindenizacao(i),
                                            p_regcliente,
                                            p_regplpag);

                if gvet_regitemindenizacao(j).valido = true then
                  gvet_regitemindenizacao(j).valido := func_inseriritemindenizacao(gvet_regitemindenizacao(j),
                                                                                   gvet_regindenizacao(i));
                end if;
              end if;
            end loop;
          end if;

          gvet_regindenizacao(i).valido := func_inseririndenizacao(gvet_regindenizacao(i),
                                                                   p_regfilial);

          if gvet_regindenizacao(i).valido = true then
            commit;
          else
            rollback;
          end if;

        end if;

      end loop;

    end if;

  end proc_processarlinhaindenizacao;

  
  

  PROCEDURE proc_processaretornotab(p_existerro IN BOOLEAN) IS

    vncontlog                   number;

    vicontador                  number;
    vncontindenizacao           number;
    vncontitemindenizacao       number;
    vncontcotacao               number;
    vncontcliref                number;
    vnqtatend                   pcpedi.qt%type;
    vsobservacaoindenizacao     varchar2(32767) := null;
    vsobservacaoitemindenizacao varchar2(32767) := null;

    vnnumped                    pcpedc.numped%type;
    vnnumpedrca                 pcpedc.numpedrca%type;
    vncodcli                    pcpedc.codcli%type;
    vscliente                   pcclient.cliente%type;
    vnvltotal                   number;
    vnvlatend                   number;
    vnqtatendped                number;
    vnqtpedida                  number;
    vsobsfinalpedido            varchar2(1000);
    
    viconttroca                number;
    
   
     BEGIN
    -- Retorna erros genericos tiporeg = 1
    IF p_existerro = TRUE
    THEN
      vncontlog := gvetregistralog.COUNT;


      FOR i IN 1 .. vncontlog LOOP
        IF gvetregistralog(i).tiporeg = 1
        THEN
          -- Gravar log de processamento de pedidos
          BEGIN
            INSERT INTO pclogfv
              (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
            VALUES
              ('PCINDCFV/PCINDIFV',
               NULL,
               SYSDATE,
               SUBSTR(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13)), 1, 100),
               NULL,
               NULL,
               NULL,
               'N');

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END IF;
      END LOOP;
    END IF;

    

      ----------------- INICIO INDENIZACOES -----------------------------

      -- Retorna INDENIZACOES gravadas com sucesso

    vncontindenizacao := gvet_regindenizacao.COUNT;


    FOR i IN 1 .. vncontindenizacao LOOP
      IF  gvet_regindenizacao(i).valido = TRUE
      THEN
        -- recupera critica do cabecalho.
        vncontlog          := gvetregistralog.COUNT;
        vsobservacaoindenizacao := '';

        FOR j IN 1 .. vncontlog LOOP
          IF (gvetregistralog(j).tiporeg = 9) AND
             (gvetregistralog(j).numpedrca =  gvet_regindenizacao(i).codindeniz)

          THEN
            vsobservacaoindenizacao := vsobservacaoindenizacao ||
                                  replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
          END IF;
        END LOOP;

        BEGIN
          --- atualiza cabecalho do pedido.
          UPDATE pcindcfv
             SET importado        = 2,
                 numindeniz       = gvet_regindenizacao(i).numindeniz,
                 retorno          = 2,
                 observacao_pc    = 'INDENIZACAO GRAVADA COM SUCESSO !'
           WHERE codindeniz       = gvet_regindenizacao(i).codindeniz ;


           select count(*)
           into viconttroca
           from pctrocafvmanif p
           where p.numpedrca = gvet_regindenizacao(i).numpedrca
           and   p.codusur   = gvet_regindenizacao(i).codusur
           and   p.codcli    = gvet_regindenizacao(i).codcli;
           
           if viconttroca > 0 then
           
              update pctrocafvmanif p
              set numindeniz = gvet_regindenizacao(i).numindeniz
              where p.numpedrca = gvet_regindenizacao(i).numpedrca
              and   p.codusur   = gvet_regindenizacao(i).codusur
              and   p.codcli    = gvet_regindenizacao(i).codcli;
              
           
           end if;

          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
        END;


        FOR cr_indi IN (SELECT codprod
                             FROM pcindifv
                            WHERE codindeniz  =  gvet_regindenizacao(i).codindeniz ) LOOP

          -- recupera critica do item
          vncontlog           := gvetregistralog.COUNT;
          vsobservacaoitemindenizacao := '';

          FOR j IN 1 .. vncontlog LOOP
            IF (gvetregistralog(j).tiporeg = 10) AND
               (gvetregistralog(j).numpedrca  =  gvet_regindenizacao(i).codindeniz) AND
               (gvetregistralog(j).codprod    =  cr_indi.codprod)

            THEN
            if trim(gvetregistralog(j).erro) <> ';' then
              vsobservacaoitemindenizacao := vsobservacaoitemindenizacao ||
                                     replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
             end if;
            END IF;

          END LOOP;


          BEGIN
            UPDATE pcindifv
               SET observacao_pc          = SUBSTR(vsobservacaoitemindenizacao, 1, 4000)
             WHERE codindeniz             = gvet_regindenizacao(i).codindeniz
               AND codprod                = cr_indi.codprod;

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END LOOP;
      END IF;
    END LOOP;

    -- Retorna INDENIZACOES nao gravadss
    vncontindenizacao :=  gvet_regindenizacao.COUNT;


    FOR i IN 1 .. vncontindenizacao LOOP
      IF  gvet_regindenizacao(i).valido = FALSE
      THEN
        -- recupera critica do cabecalho.
        vncontlog          := gvetregistralog.COUNT;
        vsobservacaoindenizacao := '';

        FOR j IN 1 .. vncontlog LOOP
          IF (gvetregistralog(j).tiporeg = 9) AND
             (gvetregistralog(j).numpedrca   =  gvet_regindenizacao(i).codindeniz)

          THEN

          if trim(gvetregistralog(j).erro) <> ';' then
            vsobservacaoindenizacao := vsobservacaoindenizacao ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
           end if;
          END IF;
        END LOOP;

        BEGIN
          --- atualiza cabecalho do pedido.
          UPDATE pcindcfv
             SET importado        = 3,
                 retorno          = 2,
                 observacao_pc    = SUBSTR(vsobservacaoindenizacao, 1, 4000)
             WHERE codindeniz    = gvet_regindenizacao(i).codindeniz ;


          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
        END;


        FOR cr_gondi IN (SELECT codprod
                             FROM pcindifv
                            WHERE codindeniz  =  gvet_regindenizacao(i).codindeniz ) LOOP

          -- recupera critica do item
          vncontlog           := gvetregistralog.COUNT;
          vsobservacaoitemindenizacao := '';

          FOR j IN 1 .. vncontlog LOOP
            IF (gvetregistralog(j).tiporeg = 10) AND
             (gvetregistralog(j).numpedrca   =  gvet_regindenizacao(i).codindeniz) AND
             (gvetregistralog(j).codprod = cr_gondi.codprod)
            THEN
            if trim(gvetregistralog(j).erro) <> ';' then
              vsobservacaoitemindenizacao := vsobservacaoitemindenizacao ||
                                     replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
            end if;
            END IF;
          END LOOP;

          BEGIN
            UPDATE pcindifv
               SET observacao_pc = SUBSTR(vsobservacaoitemindenizacao, 1, 4000)
             WHERE codindeniz    = gvet_regindenizacao(i).codindeniz
               AND codprod       = cr_gondi.codprod;

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END LOOP;
      END IF;
    END LOOP;

    -- Retorna INDENIZACOES rejeitadas durante a leitura
    vncontlog := gvetregistralog.COUNT;


    FOR i IN 1 .. vncontlog LOOP
      IF (gvetregistralog(i).tiporeg = 9) AND (gvetregistralog(i).linhareg IS NOT NULL)
      THEN
        BEGIN
          --- atualiza cabecalho do pedido.
          UPDATE pcindcfv
             SET importado        = 3,
                 observacao_pc    = SUBSTR(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13)),
                                           1,
                                           4000),
                 retorno          = 2                          
           WHERE codindeniz  = gvetregistralog(i).numpedrca   ;

          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
        END;

      END IF;
    END LOOP;



      ----------------- FIM INDENIZACOES --------------------------------
 

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END proc_processaretornotab;

  

  PROCEDURE importarpedido(p_tipoleitura IN NUMBER DEFAULT 1,
                           p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
                           p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE),
                           p_codfilial   IN VARCHAR2 DEFAULT '99',
                           p_tiporeg     IN number default null,
                           p_codusur     IN NUMBER default null
                           ) IS
    vbexisterro     boolean;
    vddatafinal     date;
    vddatainicial   date;
    vicontcancelada number;
    vscodfilial     pcfilial.codigo%type;



  begin
    -- Remove todos os elementos das tabelas.
    gvetregistralog.delete;
   gvet_regindenizacao.delete;
    gvet_regitemindenizacao.delete;
 

    vscodfilial := nvl(p_codfilial,'99');

    vngcontador := 0;

    vngtipoleitura := p_tipoleitura;
    vngtiporeg     := p_tiporeg;

    vbexisterro := false;


    -- leitura dos parametros do sistema (PCCONSUM).
    if not vbexisterro then
      proc_lerparametros(vbexisterro);
    end if;


        -- leitura dos pedidos
    if not vbexisterro
    then
      -- leitura de tabelas contendo os pedidos.
      proc_processarleitura(vbexisterro
                           ,p_tipoleitura
                           ,p_datainicial
                           ,p_datafinal
                           ,vscodfilial
                           ,p_tiporeg
                           ,p_codusur
                           );
    end if;


    if p_tipoleitura = 1
    then
      vddatainicial := TRUNC(sysdate) - 365;
      vddatafinal   := TRUNC(sysdate);
    else
      vddatainicial := p_datainicial;
      vddatafinal   := p_datafinal;
    end if;

    

    if not vbexisterro then
      -- processamento de indenizacoes
      proc_processarlinhaindenizacao;
    end if;
    

    -- processamento do retorno.
    proc_processaretornotab(vbexisterro);
    -- Remove todos os elementos das tabelas.
    gvetregistralog.delete;
    gvet_regindenizacao.delete;
    gvet_regitemindenizacao.delete;



  end importarpedido;

FUNCTION func_lockindenizacao(P_NUMPEDRCA   IN NUMBER,
                           P_CODUSUR     IN NUMBER,
                           P_DATA        IN DATE,
                           P_CGCCLI      IN VARCHAR,
                           P_TIPOLEITURA IN NUMBER) RETURN BOOLEAN IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    VNBLOQUEADO NUMBER := 0;

  BEGIN

    -- Lock do registro para evitar que dois processamentos capturem o pedido
    SELECT 1
      INTO VNBLOQUEADO
      FROM PCINDCFV
     WHERE NUMPEDRCA = P_NUMPEDRCA
       AND CODUSUR = P_CODUSUR
       AND DATA = P_DATA
       AND CGCCLI = P_CGCCLI
       AND IMPORTADO = P_TIPOLEITURA
       FOR UPDATE;

    IF VNBLOQUEADO > 0 THEN
      -- BLOQUEIA O REGISTRO AUTORIZANDO A IMPORTAÇÃO

      UPDATE PCINDCFV
         SET IMPORTADO = 4
       WHERE NUMPEDRCA = P_NUMPEDRCA
         AND CODUSUR = P_CODUSUR
         AND DATA = P_DATA
         AND CGCCLI = P_CGCCLI;

      COMMIT;
      RETURN TRUE;
    END IF;

    -- PEDIDO JÁ ESTÁ EM PROCESSAMENTO, REJEITA A IMPORTAÇÃO
    ROLLBACK;
    RETURN FALSE;

  EXCEPTION
    WHEN OTHERS THEN
          --  p_regitemindenizacao.valido := false;
      proc_registralog(null,
                       P_NUMPEDRCA,
                       P_CODUSUR,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '10',
                       sqlcode || '-' || sqlerrm,
                       null);
      ROLLBACK;
      RETURN FALSE;
  END func_lockindenizacao;
  
end; -- IMPORTARINDENIZACOES
