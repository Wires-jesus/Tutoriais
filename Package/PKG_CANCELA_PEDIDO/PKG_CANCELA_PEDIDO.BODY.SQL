CREATE OR REPLACE Package body Pkg_Cancela_pedido is
/*  Package de cancelamento de pedido
    ----------------     Historico     ----------------
    Data        Responsável    Tarefa     Comentario
    03/05/2013  Andréa         197752     Primeira Versao - (alteracoes iniciais)
    23/05/2013  Andréa         199829     Incluir parâmetro de retorno que informa se pedido foi cancelado ou não
    10/10/2013  Andréa         213377     Retirar commit e rollback    
    13/11/2013  Andréa                    Incluir cancelamento de pedidos TV7 e TV8
*/
   function func_controle_acesso (p_codfunc in pcempr.matricula%type,
                                  p_controle in pccontroi.codcontrole%type
                                  ) return boolean is
                            
   vsresult  pccontroi.acesso%type;
   
   begin
       
       begin
        SELECT NVL(PCCONTROI.ACESSO,'N') ACESSO 
        into vsresult
        FROM PCCONTROI 
        WHERE PCCONTROI.CODROTINA = 329 
        AND PCCONTROI.CODCONTROLE = p_controle
        AND PCCONTROI.CODUSUARIO = p_codfunc;
       exception when others then
         vsresult := 'N'; 
       end ; 
    
     if vsresult = 'S' then
         return true;
     else
         return false;
     end if;      
         
   end func_controle_acesso;                              
 
  
  procedure prc_insere_item (p_numpedorig     pcpedc.numped%type,
                             p_numpeddest     pcpedc.numped%type,
                             p_codprod        pcpedi.codprod%type,
                             p_numseq         pcpedi.numseq%type,
                             p_mensagem       out varchar2,
                             p_valido         in out boolean) is
  
  begin
  
      BEGIN
      INSERT INTO pcpedi
        (codprod,
         qt,
         pvenda,
         numped,
         DATA,
         codcli,
         codusur,
         numcar,
         posicao,
         st,
         vlcustoreal,
         vlcustofin,
         ptabela,
         percom,
         perdesc,
         qtfalta,
         numseq,
         vldesccustocmv,
         vlcustocont,
         vlcustorep,
         vldescsuframa,
         codst,
         vldescfin,
         pvendabase,
         vlipi,
         percipi,
         poriginal,
         iva,
         pauta,
         aliqicms1,
         aliqicms2,
         stclientegnre,
         percbasered,
         percbaseredst,
         percbaseredstfonte,
         perfretecmv,
         custofinest,
         perciss,
         vliss,
         complemento,
         pbaserca,
         vlverbacmv,
         numverbarebcmv,
         brinde,
         baseicst,
         qtcx,
         qtpecas,
         letracomiss,
         codauxiliar,
         txvenda,
         codicmtab,
         perdesccusto,
         codfilialretira,
         eancodprod,
         vldescicmisencao,
         perdescisentoicms,
         vlverbacmvcli,
         pvenda1,
         tipoentrega,
         rotinalanc,
         percom2,
         percom3,
         percom4,
         ALTERNATIVO --OS CAMPOS APARTIR DAQUI SAO DO TINTOMETRICO TAREFA 108396
        ,
         SIGLAQUALIDADE,
         VOLUMEDESEJADO,
         CODBASE,
         CODFORMULA --FIM TAREFA 108396 ACIMA CITADA
        ,
         DTENTREGA --TAREFA  ENTREGA FUTURA
         )
        (SELECT codprod,
                qt,
                pvenda,
                p_numpeddest, --NUM DO PEDIDO
                DATA,
                codcli,
                codusur,
                numcar,
                posicao, --POSIÇÃO
                st,
                vlcustoreal,
                vlcustofin,
                ptabela,
                percom,
                perdesc,
                qtfalta,
                numseq,
                vldesccustocmv,
                vlcustocont,
                vlcustorep,
                vldescsuframa,
                codst,
                vldescfin,
                pvendabase,
                vlipi,
                percipi,
                poriginal,
                iva,
                pauta,
                aliqicms1,
                aliqicms2,
                stclientegnre,
                percbasered,
                percbaseredst,
                percbaseredstfonte,
                perfretecmv,
                custofinest,
                perciss,
                vliss,
                complemento,
                pbaserca,
                vlverbacmv,
                numverbarebcmv,
                brinde,
                baseicst,
                qtcx,
                qtpecas,
                letracomiss,
                codauxiliar,
                txvenda,
                codicmtab,
                perdesccusto,
                codfilialretira,
                eancodprod,
                vldescicmisencao,
                perdescisentoicms,
                vlverbacmvcli,
                pvenda1,
                tipoentrega,
                rotinalanc,
                percom2,
                percom3,
                percom4,
                ALTERNATIVO --OS CAMPOS APARTIR DAQUI SAO DO TINTOMETRICO TAREFA 108396
               ,
                SIGLAQUALIDADE,
                VOLUMEDESEJADO,
                CODBASE,
                CODFORMULA --FIM TAREFA 108396 ACIMA CITADA
               ,
                DTENTREGA --TAREFA   ENTREGA FUTURA ENCOMENDA
           FROM pcpedi
          WHERE numped = p_numpedorig
          and   codprod = p_codprod
          and   numseq = p_numseq);
    EXCEPTION
      WHEN OTHERS THEN
        p_mensagem := 'Erro ao gerar os itens do pedido tipo 8 :'||SQLCODE || ' - ' || SQLERRM ;
        p_valido := false;
        RAISE;
    END;
  
    BEGIN
      --Tarefa 152211
      INSERT INTO PCPEDICESTA
        (NUMPED,
         CODPROD,
         NUMSEQ,
         CODAUXILIAR,
         CODPRODMP,
         QTMP,
         PVENDA,
         PTABELA,
         PBASERCA,
         BASEICST,
         ST,
         STCLIENTEGNRE,
         PERCIPI,
         VLIPI,
         PERCISS,
         VLISS,
         VLDESCSUFRAMA,
         VLCUSTOFIN,
         VLCUSTOREAL,
         VLCUSTOREP,
         VLCUSTOCONT,
         VLDESCCUSTOCMV,
         CODST,
         PERCOM,
         PERDESCTAB,
         IVA,
         ALIQICMS1,
         ALIQICMS2,
         PAUTA,
         PERCBASERED,
         CUSTOFINEST,
         PERCBASEREDSTFONTE,
         PERCBASEREDST,
         PERDESCCUSTO,
         CODICMTAB,
         TXVENDA,
         PERFRETECMV,
         PERCDIFALIQUOTAS,
         BASEDIFALIQUOTAS,
         VLDIFALIQUOTAS)
        SELECT p_numpeddest,
               CODPROD,
               NUMSEQ,
               CODAUXILIAR,
               CODPRODMP,
               QTMP,
               pvenda,
               PTABELA,
               PBASERCA,
               BASEICST,
               ST,
               STCLIENTEGNRE,
               percipi,
               vlipi,
               PERCISS,
               VLISS,
               VLDESCSUFRAMA,
               VLCUSTOFIN,
               VLCUSTOREAL,
               VLCUSTOREP,
               VLCUSTOCONT,
               VLDESCCUSTOCMV,
               CODST,
               PERCOM,
               PERDESCTAB,
               IVA,
               ALIQICMS1,
               ALIQICMS2,
               PAUTA,
               PERCBASERED,
               CUSTOFINEST,
               PERCBASEREDSTFONTE,
               PERCBASEREDST,
               PERDESCCUSTO,
               CODICMTAB,
               TXVENDA,
               PERFRETECMV,
               PERCDIFALIQUOTAS,
               BASEDIFALIQUOTAS,
               VLDIFALIQUOTAS
          FROM PCPEDICESTA
         WHERE NUMPED = p_numpedorig
         and   pcpedicesta.codprod = p_codprod
         and   pcpedicesta.numseq = p_numseq;
    
    EXCEPTION
      WHEN OTHERS THEN
        p_mensagem := 'Erro ao gerar os itens da cesta do pedido tipo 8 : '||SQLCODE || ' - ' || SQLERRM;
        p_valido   := false;
        RAISE;
    END;

  
  
  end prc_insere_item;
  
  
  procedure prc_insere_pedido (p_numped     in pcpedc.numped%type,
                               p_numpednovo in pcpedc.numped%type,
                               p_mensagem   out varchar2,
                               p_valido     in out boolean) is 
  
  begin
   
   BEGIN
     INSERT INTO pcpedc
        (numped,
         DATA,
         codusur,
         codcli,
         numitens,
         vlatend,
         codpraca,
         posicao,
         numcar,
         codsupervisor,
         codfilial,
         vltotal,
         vltabela,
         vlcustoreal,
         vlcustofin,
         totpeso,
         totvolume,
         codemitente,
         operacao,
         tipovenda,
         obs,
         codcob,
         hora,
         minuto,
         codplpag,
         numpedcli,
         percvenda,
         perdesc,
         vldesconto,
         vlfrete,
         vloutrasdesp,
         obs1,
         obs2,
         condvenda,
         dtentrega,
         numpedrca,
         fretedespacho,
         freteredespacho,
         codfornecfrete,
         codfornecredespacho,
         tipocarga,
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
         prazomedio,
         obsentrega1,
         obsentrega2,
         obsentrega3,
         tipoembalagem,
         codepto,
         campanha,
         coddistrib,
         vlcustocont,
         vlcustorep,
         numnotamanif,
         seriemanif,
         origemped,
         especiemanif,
         numpedentfut,
         codfilialnf,
         numcarmanif,
         numorca,
         codcontrato,
         datapedcli,
         numpedbnf,
         broker,
         codestabelecimento,
         numtabela,
         motivoposicao,
         dtagendaentrega,
         tipooper,
         codmotbloqueio,
         serieecf,
         numcupom,
         codclirecebedor,
         conciliaimportacao,
         numregiao,
         numnota,
         perdescfin,
         restricaotransp,
         geracp,
         usaintegracaowms,
         vendaassistida,
         codusur2,
         codusur3,
         codusur4,
         reservaestoquetv7,
         contaordem)
        (SELECT p_numpednovo, --NUM DO PEDIDO
                DATA,
                codusur,
                nvl(codclitv8, codcli),
                numitens,
                0,
                codpraca,
                posicao, --POSIÇÃO
                numcar,
                codsupervisor,
                codfilial,
                vltotal,
                0,
                0,
                0,
                totpeso,
                totvolume,
                codemitente,
                operacao,
                tipovenda,
                obs,
                codcob,
                hora,
                minuto,
                codplpag,
                numpedcli,
                percvenda,
                perdesc,
                vldesconto,
                vlfrete,
                vloutrasdesp,
                obs1,
                obs2,
                8, --TIPO DE VENDA
                dtentrega,
                numpedrca,
                fretedespacho,
                freteredespacho,
                codfornecfrete,
                codfornecredespacho,
                tipocarga,
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
                prazomedio,
                obsentrega1,
                obsentrega2,
                obsentrega3,
                tipoembalagem,
                codepto,
                campanha,
                coddistrib,
                0,
                0,
                numnotamanif,
                seriemanif,
                origemped,
                especiemanif,
                numpedentfut, --NUM DO PEDIDO TIPO 7
                codfilialnf,
                numcarmanif,
                numorca,
                codcontrato,
                datapedcli,
                numpedbnf,
                broker,
                codestabelecimento,
                numtabela,
                motivoposicao,
                dtagendaentrega,
                tipooper,
                codmotbloqueio,
                serieecf,
                numcupom,
                nvl(codclitv8, codclirecebedor),
                conciliaimportacao,
                numregiao,
                numnota,
                perdescfin,
                restricaotransp,
                geracp,
                usaintegracaowms,
                vendaassistida,
                codusur2,
                codusur3,
                codusur4,
                'S',
                contaordem
           FROM pcpedc
          WHERE numped = p_numped);
    
      -- Tarefa 79111
      INSERT INTO pcvendaconsum
        (numped,
         cliente,
         cgcent,
         enderent,
         bairroent,
         telent,
         municent,
         estent,
         cepent,
         ieent)
        SELECT p_numpednovo,
               cliente,
               cgcent,
               enderent,
               bairroent,
               telent,
               municent,
               estent,
               cepent,
               ieent
          FROM pcvendaconsum
         WHERE numped = p_numped;
      -- Fim tarefa 79111
    EXCEPTION
      WHEN OTHERS THEN
        p_mensagem :=  'Erro ao gerar pedido tipo 8 :'||SQLCODE || ' - ' || SQLERRM ;
        RAISE;
    END;

  end prc_insere_pedido;
  
  procedure prc_validacoes (p_numped   in pcpedc.numped%type,
                            p_codfunc  in pcempr.matricula%type,
                            p_motivo   in varchar2,
                            p_codmotivo in number,
                            p_mensagem out varchar2,
                            p_valido   out boolean) is
                            
  vicont                      number;
  vsmensagem                  varchar2(1000);
  vbvalido                    boolean;
  vsposicao                   pcpedc.posicao%type;
  vddtwms                     pcpedc.dtwms%type;
  vnnumviasmapasep            pcpedc.numviasmapasep%type;
  gregpcconsum                pcconsum%rowtype; -- parametros do sistema
  vscodfilial                 pcpedc.codfilial%type;
  vncodusur                   pcpedc.codusur%type;
  vnvlcorrente                pcusuari.vlcorrente%type;
  vncondvenda                 pcpedc.condvenda%type;
  vnnumpedentfut              pcpedc.numpedentfut%type;
  vnnumcarmanif               pcpedc.numcarmanif%type;
  vsbloqueioedicao            pcpedc.bloqueioedicao%type;
  vncodfuncconf               pcpedc.codfuncconf%type;
  vnnumpedbnf                 pcpedc.numpedbnf%type;
  vsbroker                    pcpedc.broker%type;
  vsimportado                 pcpedc.importado%type;
  vsvendaassistida            pcpedc.vendaassistida%type;
  vsorigemped                 pcpedc.origemped%type;
  vddtexportacao              pcpedc.dtexportacao%type;
  vddtimportacao              pcpedc.dtimportacao%type;
  vddtfinalcheckout           pcpedc.dtfinalcheckout%type;
  vsusacredrca                pcpedc.usacredrca%type;
  vsusadebcredrca             pcpedc.usadebcredrca%type;
  vsmapagerado                pcwms.mapagerado%type;  
  viexistetv8                 number;     
  viexistetv5                 number;
  viexistetv14                number;
  viexistetv14bnf             number;
  viexistepedbnf              number;
  viexisteitemcomlote         number;
  viexisteindeniz             number;
  vsacesso                    pccontroi.acesso%type;
  vnsaldodisponivel           number;
  vnsaldovenda                number;
  vscancelapedidoretornadowms pcfilial.cancelapedidoretornadowms%type;
  vbsaldorca                  boolean;
  vsreservaestoquetv7         pcpedc.reservaestoquetv7%type;


  begin

  vsmensagem := null;
  vbvalido   := true;
  
  
    if trim(p_motivo) is null then
      vsmensagem := 'É necessário colocar o motivo do cancelamento';
      vbvalido := false;
    
    else
      
      if length(trim(p_motivo)) < 2 then
          vsmensagem := 'É necessário colocar o motivo de cancelamento válido';
          vbvalido := false;

      end if;  
    
    end if;    
  
   --verifica se Codigo do funcionario existe
   select count(*)
   into vicont
   from pcempr p
   where p.matricula = p_codfunc
   and   p.dt_exclusao is null;
   
   if vicont = 0 then
      vsmensagem := 'Codigo de Funcionário não encontrado ou excluido !';
      vbvalido   := false;
     
   end if; 
  
   if vbvalido = true then
     --verifica se pedido existe
     select count(*)
     into vicont
     from pcpedc p
     where p.numped = p_numped;

     if vicont = 0 then

        vsmensagem := 'Pedido não encontrado !';
        vbvalido   := false;

     else


        begin
            select posicao,dtwms,numviasmapasep,codfilial,codusur,condvenda,numcarmanif,p.bloqueioedicao,p.codfuncconf,
                   p.numpedbnf,p.broker,p.importado,p.vendaassistida,p.origemped,p.usacredrca,p.usadebcredrca,
                   p.dtexportacao,p.dtimportacao,p.dtfinalcheckout,p.reservaestoquetv7
            into vsposicao,vddtwms,vnnumviasmapasep,vscodfilial,vncodusur,vncondvenda,vnnumcarmanif,vsbloqueioedicao,
                 vncodfuncconf,vnnumpedbnf,vsbroker,vsimportado,vsvendaassistida,vsorigemped,vsusacredrca,vsusadebcredrca,
                 vddtexportacao,vddtimportacao,vddtfinalcheckout,vsreservaestoquetv7
            from pcpedc p
            where numped = p_numped;
         exception when others then
             
           vsmensagem := 'Erro ao selecionar dados do pedido : '||SQLCODE||'-'||SQLERRM; 
           vbvalido := false;   
           
         end; 

        begin
            
          select p.cancelapedidoretornadowms
          into vscancelapedidoretornadowms
          from pcfilial p
          where codigo = vscodfilial;
          exception when others then
            vsmensagem := 'Erro ao selecionar filial do pedido : '||SQLCODE||'-'||SQLERRM;
            vbvalido := false;
        end;
        

        -- verifica se tem pedidos TV5 dependentes
        select count(*)
        into viexistetv5
        from pcpedc
        where pcpedc.numpedtv1 = p_numped
        and   posicao <> 'C'
        and   condvenda = 5;
          
        if vnnumcarmanif is not null then
          -- verifica se tem pedidos TV14 dependentes
          select count(*)
          into viexistetv14
          from pcpedc
          where pcpedc.numcarmanif = vnnumcarmanif
          and   posicao <> 'C'
          and   condvenda = 14;
        end if;      

        -- verifica se tem pedidos TV14 bonificados dependentes
        select count(*)
        into viexistetv14bnf
        from pcpedc
        where pcpedc.numpedtv14 = p_numped
        and   posicao <> 'C'
        and   condvenda = 14;




       if vncondvenda in (13,14) then
          vsmensagem := 'Pedido dos tipos : 13, 14 não serão cancelados por esta package. Faça o cancelamento pela rotina 329';
          vbvalido   := false;  
           
       end if; 

        
       if vsorigemped = 'C' and nvl(p_codmotivo,0) = 0 then
          vsmensagem := 'Parametro codmotivo é obrigatório para pedido com origemped Call Center';
          vbvalido   := false;  
         
       end if;  
       
       
       --TV8
       if vncondvenda = 8 and vsreservaestoquetv7 = 'S' then
          vsmensagem := 'Pedido TV8 marcado para reservar estoque do pedido TV7 não pode ser cancelado';
          vbvalido   := false;  
       
       end if;

       --verifica se usuario tem permissao de cancelamento de pedido
       if not func_controle_acesso(p_codfunc,4) then
          vsmensagem := 'Usuario sem permissao para cancelar pedido';
          vbvalido   := false;
                    
       end if;

        --valida posição do pedido
        if vsposicao not in ( 'B','P','L','M')  then

           vsmensagem := 'Pedido na posicao : '|| vsposicao ||'não pode ser cancelado ! ';
           vbvalido   := false;

        end if;
        
        if viexisteindeniz > 0 then
           vsmensagem := 'Existe indenizacao para este pedido, cancele-a primeiro.';
           vbvalido := false;         
        
        end if;
        
        
        
        
   end if;     
        

      if  vbvalido = true and vsposicao = 'M' then

            if vsorigemped in ('F','T') then
               vsmensagem := 'Pedido Montado e com origemped : '||vsorigemped ||' nao pode ser cancelado. Cancele na 904 primeiro !';
               vbvalido   := false;

            elsif not func_controle_acesso(p_codfunc,1) then
               vsmensagem := 'Pedido Montado e usuario sem permissao de cancelamento nesta posicao !';
               vbvalido   := false;

            end if;   

      end if;
          
    --valida se está sendo montado
     if vbvalido = true and gregpcconsum.montando = 'S'  and vsposicao = 'L' then
        vsmensagem := 'Sistema winthor esta alocado para montagem de carga. Nao pode ter cancelamento de pedido.';
        vbvalido   := false;

      end if;
      
    --valida se foi emitido mapa de separacao
     if vbvalido = true and nvl(vnnumviasmapasep,0) > 0 and not func_controle_acesso(p_codfunc, 1) then
        vsmensagem := 'Pedido com mapa de separacao emitido nao pode ser cancelado !';
        vbvalido   := false;
        
     end if;   


   --verifica se tem indenizacao para o pedido
   if vbvalido = true then
     
      select count(*)
      into viexisteindeniz
      from pcindc p
      where p.numped = p.numped
      and   p.dtexclusao is null;
   
   end if;

     --verifica se pedido tem bloqueio de edicao      
    if vbvalido = true and vsbloqueioedicao = 'S' and not func_controle_acesso(p_codfunc, 7)   then
       vsmensagem := 'Pedido em edicao e usuario sem permissao para cancelar neste modo';
       vbvalido   := false;
       
     end if;  

                     
     --verifica se pedido está em conferencia                    
     if vbvalido = true and vncodfuncconf is not null and not func_controle_acesso(p_codfunc,2) then
       vsmensagem := 'Pedido em conferencia nao pode ser cancelado';
       vbvalido   := false;
       
     end if;  
                         
     -- verifica se pedido tem pedido bonificado amarrado a ele                         
     if vbvalido = true and  nvl(vnnumpedbnf,0) > 0 then

        --verifica se tem pedidos bonificados
        select count(*)
        into viexistepedbnf
        from pcpedc
        where numped = vnnumpedbnf
        and   posicao <> 'C';

        if viexistepedbnf > 0 then                         
            vsmensagem := 'Pedido com pedido bonificado valido nao pode se cancelado. Cancele o pedido bonificado primeiro !';
            vbvalido   := false;
        end if;    
     end if;   
                           

     -- veriifca se tem pedido bonificado                           
     if vbvalido = true and viexistetv5 > 0 then
        vsmensagem := 'Pedido com pedido bonificado valido nao pode se cancelado';
        vbvalido   := false;
        
     end if;   
                           

     --valida pedido Broker                             
      if vbvalido = true and vsbroker = 'S' and vsimportado = 'S' then
          vsmensagem := 'Pedido Broker que ja foi importado nao pode se cancelado';
          vbvalido   := false;
          
       end if;   
  
     --valida venda assistida            
     if vbvalido = true and vncondvenda = 8 and vsvendaassistida = 'S' then
        vsmensagem := 'Pedido venda assistida nao pode se cancelado';
        vbvalido   := false;
                           
     end if;            

                                   
     if vbvalido = true and vddtwms is not null then
       
        if not func_controle_acesso(p_codfunc,8) then
           vsmensagem := 'Pedido marcado pelo WMS nao pode se cancelado';
           vbvalido   := false;
                                    
        else 
          
           if vscancelapedidoretornadowms = 'N' then
              vsmensagem := 'Pedido marcado pelo WMS e filial marcada para nao permitir cancelamento destes pedidos';
              vbvalido   := false;
                                     
           else

              if vddtexportacao is not null then 
                
                if vddtimportacao is null then
                   vsmensagem := 'Pedido marcado pelo WMS e ainda não liberado !';
                   vbvalido   := false;
 
                else

                   if vddtfinalcheckout is null then                     

                     select count(*)
                     into viexisteitemcomlote
                     FROM pcpedi 
                     WHERE numped = p_numped 
                     AND   qt > 0 
                     AND   posicao <> 'C' 
                     AND   numlote IS NOT NULL; 
      
                     if viexisteitemcomlote > 0 then
                        vsmensagem := 'Pedido passou pela conferencia e tem itens com lote associados a eles';
                        vbvalido   := false;
                       
                     else
                       
                       begin
                       select nvl(mapagerado,'N') mapagerado 
                       into vsmapagerado
                       from pcwms where numped = p_numped 
                       and dtcancel is null;
                       exception when others then
                         
                         vsmensagem := 'Erro ao selecionar pedido na tabela pcwms : '||sqlcode|| '-'|| sqlerrm;
                         vbvalido := false;
                       
                       end;
                     
                        if vsmapagerado = 'S' then
                           vsmensagem := 'Pedido com mapa de separacao gerado nao pode ser cancelado !';
                           vbvalido := false;  
                        
                        end if;
                     
                     end if;
                 end if;
                end if;
               end if;
           end if;
         end if;       
       end if;         
                                   
    --valida saldo de rca
    if vbvalido = true and vsusacredrca = 'S' and vsusadebcredrca = 'S' then
                                      
       select pc_pkg_controlarsaldorca.ccrca_checar_disponivel_atual( vncodusur ) 
       into vnsaldodisponivel 
       from dual;
                                       
       select pc_pkg_controlarsaldorca.ccrca_buscar_saldo_venda(p_numped, vncodusur) 
       into vnsaldovenda 
       from dual;
                                       
      if vnsaldodisponivel - vnsaldovenda < 0 and not func_controle_acesso(p_codfunc,10) then
         vsmensagem := 'Rca sem saldo para que seja feito cancelamento deste pedido';
         vbvalido   := false;
                                          
      end if;
                         
   end if;
                                     
end if;

  p_mensagem := vsmensagem;
  p_valido   := vbvalido;
  end prc_validacoes;


  procedure prc_cancela_tv8 (p_numped        in  pcpedc.numped%type,
                             p_numpedentfut  in  pcpedc.numped%type,
                             p_codusur       in  pcpedc.codusur%type,
                             p_novopedido    out pcpedc.numped%type,
                             p_mensagem      out varchar2,
                             p_valido        in out boolean)  is
                             
                             
   viconttv8                       number;
   vicontitemtv8                   number;
   vnnumpedtv8                     pcpedc.numped%type;
   vnproxnumped                    pcpedc.numped%type;
   vsmensageminsereitem            varchar2(1000);
   vsmensageminserepedido          varchar2(1000);  
   vnvltotal                       pcpedc.vltotal%type;
   vntotpeso                       pcpedc.totpeso%type;
   vntotvolume                     pcpedc.totvolume%type;
   vnnumitens                      pcpedc.numitens%type;

    
                             
  begin
  
  p_novopedido := null;

                  
                     --verifica se existe outro pedido tv8 com reserva de estoque
                     select count(*)
                     into viconttv8
                     from pcpedc
                     where numpedentfut = p_numpedentfut
                     and   condvenda = 8
                     and   reservaestoquetv7 = 'S'
                     and   numped <> p_numped;
                     
                     --existe pedido TV8 com reserva de estoque
                     if viconttv8 > 0  then

                         select numped
                         into vnnumpedtv8
                         from pcpedc
                         where numpedentfut = p_numpedentfut
                         and   condvenda = 8
                         and   reservaestoquetv7 = 'S'
                         and   numped <> p_numped
                         and    rownum = 1;
                         
                         
                         for regitens in ( select codprod,numseq,qt
                                           from pcpedi
                                           where numped = p_numped) loop
                     
                            --verifica se existe o item no pedido tv8 com reserva 
                            select count(*)
                            into vicontitemtv8
                            from pcpedi 
                            where numped  = vnnumpedtv8
                            and   codprod = regitens.codprod;
                        
                            --existem item igual no pedido tv8 com reserva de estoque
                            if vicontitemtv8  > 0 then                     
                         
                               update pcpedi
                               set qt = qt + regitens.qt
                               where numped = vnnumpedtv8
                               and   codprod = regitens.codprod
                               and   rownum  = 1; 
                         
                            else
                            
                              prc_insere_item(p_numped,
                                              vnnumpedtv8,
                                              regitens.codprod,
                                              regitens.numseq,
                                              vsmensageminsereitem,
                                              p_valido);
                                              
                                if vsmensageminsereitem is not null then
                                
                                   p_mensagem := vsmensageminsereitem;
                                   p_valido := false;

                                
                                end if;              
                            
                            end if;
                        end loop;    
                     
                     
                         select sum((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *  NVL(pcpedi.pvenda, 0)) vltotal,
                                sum(NVL(pcpedi.qt, 0) * NVL(pcprodut.pesobruto, 0)) totpeso,
                                sum(NVL(pcpedi.qt, 0) * NVL(pcprodut.volume, 0)) totvolume,
                                count(*) numitens
                        into vnvltotal,
                             vntotpeso,
                             vntotvolume,
                             vnnumitens
                        from pcpedi, pcprodut
                       where pcpedi.numped = vnnumpedtv8
                         and pcpedi.codprod = pcprodut.codprod;
                         
                         update pcpedc
                         set vltotal = vnvltotal,
                             numitens = vnnumitens,
                             totpeso  = vntotpeso,
                             totvolume  = vntotvolume
                         where numped = vnnumpedtv8;    
                         

                     
                     
                     --nao existe pedido tv8 com reserva de estoque
                     else

                         if vnproxnumped is null then
                          begin
                              select proxnumped
                                into vnproxnumped
                                from pcusuari
                               where codusur = p_codusur
                                 for update;
                  
                 
                              update pcusuari
                                 set proxnumped  = proxnumped + 1
                               where codusur     = p_codusur;
                  
                            exception
                              when others then
                                 p_mensagem         := 'ERRO AO BUSCAR NUMERO PEDIDO : ' ||
                                                      sqlcode || '-' || sqlerrm ;
                                 p_valido := false;
                  
                            end;
                          end if;
                          
                          if p_valido = true then
                          
                              p_novopedido := vnproxnumped;
                            
                             for regitens in ( select codprod,numseq
                                               from pcpedi
                                               where numped = p_numped) loop
                            
                              prc_insere_item(p_numped,
                                              vnproxnumped,
                                              regitens.codprod,
                                              regitens.numseq,
                                              vsmensageminsereitem,
                                              p_valido);
    
                                if vsmensageminsereitem is not null then
                                
                                   p_mensagem := vsmensageminsereitem;
                                
                                end if;              
                           end loop;
                       
                            prc_insere_pedido(p_numped,
                                              vnproxnumped,
                                              vsmensageminserepedido,
                                              p_valido);
                                              
                                if vsmensageminserepedido is not null then
                                
                                   p_mensagem := vsmensageminserepedido;
                                
                                end if;              
                                              
                                              
                       
                          end if;
                       
                     
                     end if;
                   
                  
  end;


  procedure prc_cancela ( p_numped   in pcpedc.numped%type,
                          p_codfunc  in pcempr.matricula%type,
                          p_motivo   in varchar2,
                          p_codmotivo in number,
                          p_mensagem out varchar2, 
                          p_cancelado out varchar2) is
                
  
         cursor cr_estoque(p_numped    pcpedc.numped%type,
                           p_codfilial pcpedc.codfilial%type) is
      select *
        from pcest
       where exists (select pcpedi.codprod
                     from pcpedi
                      where pcpedi.numped = p_numped
                       and pcpedi.codprod = pcest.codprod
                       and pcest.codfilial = nvl(pcpedi.codfilialretira,p_codfilial));


   vsmensagem                      varchar2(1000);
   vsposicao                       pcpedc.posicao%type;
   vscodfilial                     pcpedc.codfilial%type;
   vncodusur                       pcpedc.codusur%type;
   vncondvenda                     pcpedc.condvenda%type;
   vsusasaldocontacorrentedescfin  pcpedc.usasaldocontacorrentedescfin%type;
   vsbroker                        pcpedc.broker%type;
   vsusaintegracaowms              pcpedc.usaintegracaowms%type;
   vddtimportacao                  pcpedc.dtimportacao%type;
   vddtexportacao                  pcpedc.dtexportacao%type;
   vnnumcar                        pcpedc.numcar%type;
   vncodemitente                   pcpedc.codemitente%type;
   vddata                          pcpedc.data%type;
   vncodcli                        pcpedc.codcli%type;
   vnvlatend                       pcpedc.vlatend%type;
   vnnumpedrca                     pcpedc.numpedrca%type;
   vscodcob                        pcpedc.codcob%type;
   vncodplpag                      pcpedc.codplpag%type;
   vntotpeso                       pcpedc.totpeso%type;
   vntotvolume                     pcpedc.totvolume%type;
   vsorigemped                     pcpedc.origemped%type;
   vscliente                       pcclient.cliente%type;
   vnvlcorrente                    pcusuari.vlcorrente%type;
   vsestoqueporlote                pcprodut.estoqueporlote%type;
   vnpesobruto                     pcprodut.pesobruto%type;
   vbpedidovalido                  boolean;
   vbvalido                        boolean;
   vbsaldorca                      boolean;
   vnqtestger                      pcest.qtestger%type;
   vnqtreserv                      pcest.qtreserv%type;
   vsfimestoque                    pcest.fimestoque%type;
   vsintegracaowms                 varchar2(1);
   vicontveic                      number;
   vncontpedcar                    number;
   vncodveiculo                    pccarreg.codveiculo%type;
   vsreservaestoquetv7             pcpedc.reservaestoquetv7%type;
   vnnumpedentfut                  pcpedc.numpedentfut%type;
   vsmensagemtv8                   varchar2(1000);
   vnnovopedidogerado              pcpedc.numped%type;
   vs_movest                       varchar2(100);
   msgest                          varchar2(1000);
   ERRO_BAIXA_ESTOQUE              EXCEPTION;
   
  begin

      begin
        select *
        into gregpcconsum
        from pcconsum ;
       exception when others then
         
         vsmensagem := 'Erro ao selecionar dados da pcconsum : '||SQLCODE||'-'||SQLERRM;    
       
       end;


    
   prc_validacoes(p_numped,
                  p_codfunc,
                  p_motivo,
                  p_codmotivo,
                  vsmensagem,
                  vbpedidovalido);
                  
    if vbpedidovalido = false then
      
      p_mensagem := vsmensagem;
    
    else              
    
      vbvalido := true;
    
       begin
          select p.posicao,p.codfilial,p.codusur,p.condvenda,p.usasaldocontacorrentedescfin,p.usaintegracaowms,p.dtimportacao,
                 p.numcar,p.codemitente,p.data,p.codcli,p.vlatend,c.cliente,p.dtexportacao,p.numpedrca,p.codcob,p.codplpag,
                 p.totpeso,p.totvolume,p.origemped,p.reservaestoquetv7,p.numpedentfut
          into vsposicao,vscodfilial,vncodusur,vncondvenda,vsusasaldocontacorrentedescfin,vsusaintegracaowms,vddtimportacao,
                vnnumcar,vncodemitente,vddata,vncodcli,vnvlatend,vscliente,vddtexportacao,vnnumpedrca,vscodcob,vncodplpag,
                vntotpeso,vntotvolume,vsorigemped,vsreservaestoquetv7,vnnumpedentfut
          from pcpedc p,pcclient c
          where p.numped = p_numped
          and   p.codcli = c.codcli;
       exception when others then
         
         vsmensagem := 'Erro ao selecionar dados do pedido : '||SQLCODE||'-'||SQLERRM;    
         vbvalido := false;
       
       end; 

  
       if vbvalido = true then
  
             --bloqueia o rca
           begin
               
             select vlcorrente
             into vnvlcorrente
             from pcusuari
             where codusur = vncodusur
             for update;
           exception when others then
             vsmensagem := 'Erro ao selecionar dados do rca : '||SQLCODE||'-'||SQLERRM;
             vbvalido := false;
           end ;
       
             if vbvalido = true then


               if vncondvenda = 8 then
               
                  prc_cancela_tv8(p_numped,
                                  vnnumpedentfut,
                                  vncodusur,
                                  vnnovopedidogerado,
                                  vsmensagemtv8,
                                  vbvalido);
                                  
                   if vsmensagemtv8 is not null then               
                   
                     vsmensagem := vsmensagemtv8;
                   
                   end if;
                                  
               
               end if;

              
           for regpedido in ( select p.numped,p.posicao,p.codfilial,p.codusur,p.condvenda,p.usasaldocontacorrentedescfin,p.usaintegracaowms,p.dtimportacao,
                                     p.numcar,p.codemitente,p.data,p.codcli,p.vlatend,c.cliente,p.dtexportacao,p.numpedrca,p.codcob,p.codplpag,
                                     p.totpeso,p.totvolume,p.origemped,p.reservaestoquetv7,p.numpedentfut,broker
                              from pcpedc p,pcclient c
                              where numped   = p_numped
                              and   p.codcli = c.codcli
                              union
                              select p.numped,p.posicao,p.codfilial,p.codusur,p.condvenda,p.usasaldocontacorrentedescfin,p.usaintegracaowms,p.dtimportacao,
                                     p.numcar,p.codemitente,p.data,p.codcli,p.vlatend,c.cliente,p.dtexportacao,p.numpedrca,p.codcob,p.codplpag,
                                     p.totpeso,p.totvolume,p.origemped,p.reservaestoquetv7,p.numpedentfut,broker
                              from pcpedc p, pcclient c
                              where  p.numpedentfut      = p_numped 
                              and    p.reservaestoquetv7 = 'S'
                              and    p.numped            <> nvl(vnnovopedidogerado,0)
                              and    p.posicao           <> 'C'
                              and    p.codcli            = c.codcli )loop
                                    

              for cr_pcest in cr_estoque(regpedido.numped,regpedido.codfilial) loop

               for reg_itens in (select pcpedi.codprod,pcpedi.numseq,pcpedi.qt,pcpedi.posicao,pcpedi.pvenda,pcpedi.ptabela,pcpedi.pbaserca,
                                        pcpedi.numlote,pcpedi.codcertific,pcpedi.pesobruto,pcpedi.codauxiliar
                                 from pcpedi
                                 where pcpedi.numped  = regpedido.numped
                                 and   pcpedi.codprod = cr_pcest.codprod
                                  ) loop

                  if nvl(vsusasaldocontacorrentedescfin,'N') = 'S' then
                    begin
                      vbsaldorca := pc_pkg_controlarsaldorca.ccfinrca_excluir_item_pedido(p_codfunc, 2596, regpedido.codusur, regpedido.numped, reg_itens.codprod, reg_itens.numseq, reg_itens.qt, reg_itens.pvenda, vsmensagem);
                    exception when others then
                      vsmensagem := 'Erro ao excluir item do saldo de rca com desc financeiro : '||SQLCODE||'-'||SQLERRM;
                      vbvalido := false;
                      exit;
                    end; 
                    
                  else
                    begin
                      vbsaldorca := pc_pkg_controlarsaldorca.ccrca_excluir_item_pedido(p_codfunc,2596 , regpedido.codusur, regpedido.numped, reg_itens.codprod, reg_itens.numseq, reg_itens.qt);
                     exception when others then
                      vsmensagem := 'Erro ao excluir item do saldo de rca : '||SQLCODE||'-'||SQLERRM;
                      vbvalido := false;
                      exit;
                    end; 

                  end if;                    

                       begin
                        select pcprodut.estoqueporlote,pesobruto
                        into vsestoqueporlote,vnpesobruto
                        from pcprodut
                        where codprod = reg_itens.codprod;
                       exception when others then
                          vsmensagem := 'Erro ao selecionar dados do produto : '||SQLCODE||'-'||SQLERRM;
                          vbvalido := false;
                          exit;
                       end; 


                  if (regpedido.condvenda not in (4,7,14,8) or (regpedido.condvenda = 8 and regpedido.reservaestoquetv7 = 'S'))
                      and nvl(regpedido.broker,'N') <> 'S' then

                     if gregpcconsum.utilizacontrolelote = 'S' then
                       
                       begin
                        update pclote 
                        set qtreserv = greatest( ( nvl(qtreserv,0) - reg_itens.qt ) ,0) 
                        where numlote = reg_itens.numlote 
                        and codprod   = reg_itens.codprod;
                       exception when others then
                         vsmensagem := 'Erro ao atualizar a pclote : '||SQLCODE||'-'||SQLERRM;
                          vbvalido := false;
                        exit;
                       end; 
 
                     
                     end if; 
                     

                       if reg_itens.posicao in ('L','M') then

                           if nvl(regpedido.usaintegracaowms,'N') = 'S' and regpedido.dtimportacao is not null then

                               begin
                                update pcest
                                set qtbloqueada = greatest((nvl(qtbloqueada,0) + reg_itens.qt),0)
                                where codfilial = cr_pcest.codfilial
                                and   codprod   = cr_pcest.codprod;
                              exception when others then
                                 vsmensagem := 'Erro ao atualizar a quantidade bloqueada na pcest : '||SQLCODE||'-'||SQLERRM;
                                 vbvalido := false;
                                 exit;
                                end; 


                                 
                           end if;

                          begin

                            vs_movest := pkg_estoque.RESERVA_BAIXAR(regpedido.numped, reg_itens.codprod, reg_itens.numseq,  'BQ', msgest);

                            if vs_movest = 'N' THEN
                              RAISE ERRO_BAIXA_ESTOQUE;
                            END IF;

                          exception
                          when ERRO_BAIXA_ESTOQUE then
                            vsmensagem := 'Erro ao baixar estoque: '||SQLCODE||'-'||SQLERRM||' - '||msgest;
                            vbvalido := false;
                            exit;
                          when others then
                            vsmensagem := 'Erro ao atualizar a quantidade reservada na pcest : '||SQLCODE||'-'||SQLERRM||' - '||msgest;
                            vbvalido := false;
                            exit;
                          end;
 
                         
                       else
                         begin
                          vs_movest := pkg_estoque.PENDENTE_BAIXAR(regpedido.numped, reg_itens.codprod, reg_itens.numseq,  'BQ', msgest);

                          if vs_movest = 'N' THEN
                            RAISE ERRO_BAIXA_ESTOQUE;
                          END IF;

                         exception
                         when ERRO_BAIXA_ESTOQUE then
                          vsmensagem := 'Erro ao baixar estoque: '||SQLCODE||'-'||SQLERRM||' - '||msgest;
                          vbvalido := false;
                          exit;
                         when others then
                            vsmensagem := 'Erro ao atualizar a quantidade pendente na pcest : '||SQLCODE||'-'||SQLERRM||' - '||msgest;
                            vbvalido := false;
                            exit;
                         end; 


                       end if;
                       
                        begin
                         select qtestger,qtreserv,fimestoque
                         into vnqtestger,vnqtreserv,vsfimestoque
                         from pcest
                         where codfilial = cr_pcest.codfilial
                         and   codprod   = cr_pcest.codprod;
                       exception when others then
                          vsmensagem := 'Erro ao validar fim de estoque na pcest : '||SQLCODE||'-'||SQLERRM;
                          vbvalido := false;
                          exit;
                       end; 


                         if vnqtestger > vnqtreserv and vsfimestoque = 'S'then

                           begin
                             UPDATE PCEST
                             SET FIMESTOQUE = '' 
                             WHERE CODFILIAL = cr_pcest.codfilial 
                             AND CODPROD     = reg_itens.codprod;
                           exception when others then
                             vsmensagem := 'Erro ao atualizar fim de estoque na pcest : '||SQLCODE||'-'||SQLERRM;
                             vbvalido := false;
                             exit;
                          end; 
  
                           
                         end if;
                       
                   end if;
                   
                   if nvl(reg_itens.codcertific,0) > 0 then
                     begin
                       update pccertific 
                       set pesoutilizado = nvl(pesoutilizado,0)-(nvl(nvl(reg_itens.pesobruto,vnpesobruto),0) * reg_itens.qt) 
                       where codcertific = reg_itens.codcertific ; 
                     exception when others then
                      vsmensagem := 'Erro ao atualizar peso do produto com certificado : '||SQLCODE||'-'||SQLERRM;
                      vbvalido := false;
                      exit;
                    end; 
  
                   
                   end if;
                   
                     begin
                            
                     INSERT INTO PCNFCANITEM (NUMPED,    --1
                                              CODROTINA, --2 
                                              MOTIVO,    --3
                                              CODCLI,    --4
                                              CODPROD,   --5
                                              PVENDA,    --6
                                              PTABELA,   --7
                                              NUMSEQ,    --8
                                              DATACANC,  --9
                                              CODFUNCCANC, --10
                                              DATAEMISSAO, --11
                                              CODFUNCEMITE,--12 
                                              DESCRICAO,   --13
                                              CODUSUR,     --14
                                              NUMCAR,      --15
                                              QT,          --16
                                              PBASERCA,    --17
                                              HORACANC,    --18
                                              DTPEDIMPORTACAOWMS, --19 
                                              CODAUXILIAR         --20
                                              )
                                       values (regpedido.numped,          --1
                                               2596,              --2
                                               p_motivo,           --3
                                               regpedido.codcli,  --4
                                               reg_itens.codprod, --5
                                               reg_itens.pvenda,  --6
                                               reg_itens.ptabela, --7
                                               reg_itens.numseq,  --8
                                               trunc(sysdate),    --9
                                               p_codfunc,         --10
                                               regpedido.data,            --11
                                               regpedido.codemitente ,    --12
                                               'Cliente.:' || vncodcli || ' - ' || vscliente || 'CONF.PED.:' || regpedido.numped,                --13
                                               regpedido.codusur,         --14
                                               regpedido.numcar,          --15
                                               reg_itens.qt,      --16
                                               reg_itens.pbaserca,  --17
                                               sysdate,             --18
                                               regpedido.dtimportacao,   --19
                                               reg_itens.codauxiliar --20
                                               );
                            exception when others then
                              vsmensagem := 'Erro ao inserir item na pcnfcanitem : '||SQLCODE||'-'||SQLERRM;
                              vbvalido := false;
                              exit;
                            end;
                            
                end loop;

              end loop;
              
              
  
          
           if vbvalido = true then
             
             --cancelar carregamento
             if regpedido.posicao = 'M' and nvl(regpedido.numcar,0) > 0 then
                           
                select count(*)
                into vncontpedcar
                from pcpedc 
                where numcar = regpedido.numcar;
                            
                if vncontpedcar = 1 then
                              
                   begin
                     select p.codveiculo
                     into vncodveiculo
                     from pccarreg p
                     where p.numcar = regpedido.numcar;
                   exception when others then
                     vsmensagem := 'Erro ao selecionar carregamento : '||SQLCODE||'-'||SQLERRM;
                     vbvalido := false;

                   end ;  
                            
                   if nvl(vncodveiculo,0) > 0 then
                                    
                      select count(*) 
                      into vicontveic
                      from pccarreg 
                      where dtfat is null 
                      and   dt_cancel is null 
                      and   codveiculo = vncodveiculo 
                      and   numcar <> regpedido.numcar 
                      and   numcar > 0;
                                  
                      if vicontveic = 0 then
                                    
                         begin
                         UPDATE PCVEICUL 
                         SET SITUACAO = 'L'
                         WHERE SITUACAO = 'V' 
                         AND CODVEICULO = vncodveiculo;
                         exception when others then
                                       
                          vsmensagem := 'Erro ao atualizar pcveicul : '||SQLCODE||'-'||SQLERRM;
                          vbvalido := false;
                                     
                         end;  
                                                                       
                      end if;
                                  
                    end if;  
                               
                        begin
   
                            INSERT INTO PCNFCAN (CODFUNCCANC, DATACANC, VLTOTAL, NUMCAR,  
                                                 MOTIVO, CODROTINA, DESCRICAO)
                            VALUES (p_codfunc, SYSDATE, 0, regpedido.NUMCAR, 
                                    'PEDIDO BALCAO RESERVA CANCELADO', 2596,'Carregamento : '||vnnumcar);
                         exception when others then
                           
                           vsmensagem := 'Erro ao inserir na pcnfcan : '||SQLCODE||'-'||SQLERRM;
                           vbvalido := false;
                         
                           end ;           
                               
                        begin   
                        update pccarreg 
                        set codfunccancel = p_codfunc, 
                            dt_cancel = sysdate, 
                            totpeso = 0, 
                            totvolume = 0, 
                            vltotal = 0, 
                            destino = null, 
                            codveiculo = 0, 
                            obsfatur = 'PEDIDO BALCAO RESERVA CANCELADO'
                        where numcar = regpedido.numcar;
                       exception when others then
                         vsmensagem := 'Erro ao atualizar carregamento : '||SQLCODE||'-'||SQLERRM;
                         vbvalido := false;
                       end ;  
                               
                end if;
                         
             end if;           
           
            if regpedido.dtimportacao is not null and regpedido.dtexportacao is not null then
              vsintegracaowms := 'S';  
            else
              vsintegracaowms := 'N';
            end if;   
             
            begin
             insert into pcnfcan (numped,       --1
                                  codrotina,    --2
                                  motivo,       --3
                                  codcli,       --4
                                  vltotal,      --5
                                  datacanc,     --6
                                  codfunccanc,  --7
                                  dataemissao,  --8
                                  codfuncemite, --9
                                  descricao,    --10
                                  codusur,      --11
                                  numcar,       --12
                                  codplpag,     --13
                                  codcob,       --14
                                  codfilial,    --15
                                  origemped,    --16
                                  totpeso,      --17
                                  totvolume,    --18
                                  condvenda,    --19
                                  numpedrca,    --20
                                  horacanc,     --21
                                  integracaowms --22
                                  )
                          values (regpedido.numped,           --1
                                  2596,               --2
                                  p_motivo,           --3
                                  regpedido.codcli,   --4
                                  regpedido.vlatend ,         --5
                                  trunc(sysdate),     --6
                                  p_codfunc,          --7
                                  regpedido.data,             --8
                                  regpedido.codemitente ,     --9
                                  'cliente.:' || regpedido.codcli || '-' || regpedido.cliente || ' conf.ped.: '||regpedido.numped, --10
                                  regpedido.codusur,         --11
                                  regpedido.numcar,          --12
                                  regpedido.codplpag,        --13
                                  regpedido.codcob,          --14
                                  regpedido.codfilial,       --15
                                  regpedido.origemped,       --16
                                  regpedido.totpeso,         --17
                                  regpedido.totvolume,       --18
                                  regpedido.condvenda,       --19
                                  regpedido.numpedrca,       --20
                                  sysdate,           --21
                                  regpedido.usaintegracaowms    --22
                                  );
                     exception when others then
                      vsmensagem := 'Erro ao inserir registro na pcnfcan : '||SQLCODE||'-'||SQLERRM;
                      vbvalido := false; 
                     end;             

               if vsorigemped = 'C' then
                 
                 begin
                  UPDATE PCPEDI SET QT = 0, POSICAO = 'C', NUMCAR = 0 WHERE NUMPED = regpedido.numped;
                 exception when others then
                  vsmensagem := 'Erro ao atualizar pcpedi : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 
    
                 begin
                  UPDATE PCPEDC SET POSICAO = 'C', NUMCAR = 0, DTCANCEL = TRUNC(SYSDATE), 
                                    CODMOTCANCEL = p_codmotivo, VLATEND = 0, VLTABELA = 0, 
                                    VLCUSTOFIN = 0, VLCUSTOREAL = 0, CODFUNCCANCEL = p_codfunc 
                  WHERE NUMPED = regpedido.numped;
                                  exception when others then
                  vsmensagem := 'Erro ao atualizar pcpedc : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 
 

               
               else
                 begin
                  delete from pcpedi where numped = regpedido.numped;
                  exception when others then
                  vsmensagem := 'Erro ao excluir pcpedi : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 
 
                 begin    
                  delete from pcpedicesta where numped = regpedido.numped;
                  exception when others then
                  vsmensagem := 'Erro ao excluir pcpedicesta : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 
                  
                  begin
                  delete from pcitemrolo where numped = regpedido.numped;
                  exception when others then
                  vsmensagem := 'Erro ao excluir pcitemrolo : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 

                  begin
                   delete from pcfalta where numped = regpedido.numped;
                  exception when others then
                  vsmensagem := 'Erro ao excluir pcfalta : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 
 
                 begin 
                  delete from pcpedc where numped = regpedido.numped;
                 exception when others then
                  vsmensagem := 'Erro ao excluir pcpedc : '||SQLCODE||'-'||SQLERRM;
                  vbvalido := false; 
                 end; 
 

               end if;    

                if vsusaintegracaowms = 'S' then
                  
                begin
                   UPDATE PCWMS SET DTCANCEL = SYSDATE 
                   WHERE NUMPED = regpedido.numped 
                   AND DTCANCEL IS NULL 
                   AND nvl(MAPAGERADO,'N') = 'N';
                 exception when others then
                 vsmensagem := 'Erro ao atualizar tabela PCWMS : '||SQLCODE||'-'||SQLERRM;
                 vbvalido := false;  
                 
                 end;  
                  
                end if;

             
           end if;
           
          end loop;           
         
         end if;           
           
       end if;
  
 
    end if;
    
    if vbvalido = true then
      
      vsmensagem := 'Pedido cancelado !';
      p_cancelado := 'S';
      
    else
      p_cancelado := 'N';
    
    end if;  

     p_mensagem := vsmensagem;    
            
  end prc_cancela;                        


  end pkg_cancela_pedido;
