create or replace procedure PRC_ATUALIZA_ROTA  (p_utilizaroteirizacao in varchar2,
                                                  p_atualizarotanomomentovenda in varchar2,
                                                  p_codcli      in pcpedc.codcli%type,
                                                  p_codusur     in pcpedc.codusur%type,
                                                  p_tipo        in varchar2,
                                                  p_numped      in pcpedc.numped%type,
                                                  p_data        in date,
                                                  p_codrota     in pcmovrotacli.codrota%type,
                                                  p_codvisita   in pcvisita.codvisita%type,
                                                  p_codmotivovis in pcvisita.codmotivo%type,
                                                  p_mensagem    out varchar2,
                                                  p_justvalida  out boolean) is


  vnrowid        rowid;
  vddtpedido     pcmovrotacli.dtpedido%type;
  vnqtpedido     pcmovrotacli.qtpedido%type;
  vddtvisitaprog pcmovrotacli.dtvisitaprog%type;
  vddtproxvisita pcmovrotacli.dtproxvisita%type;
  vncodvisita    pcmovrotacli.codvisita%type;
  vddtjustific   pcmovrotacli.dtjustific%type;
  vddtcancel     pcmovrotacli.dtcancel%type;
  vncodcli       pcmovrotacli.codcli%type;
  vncodusur      pcmovrotacli.codusur%type;
  vstipomotivo   pcmotvisita.tipomotivo%type;
  
  vicont         number;
  vbvalido       boolean;


/*************************************************************************************************************************************
 Procedure criada para atualizar movimentação de rotas
 
 Data        Responsável       Tarefa        Comentário
 26/04/2012  Andréa            158674        Primeira versão
 04/05/2012  Andréa                          Ajustes em mensagens e acesso a pcmotvisita


**************************************************************************************************************************************/
  begin
  execute immediate 'Alter Session Set nls_language=''BRAZILIAN PORTUGUESE'' ';

  p_justvalida := true;
  vbvalido     := true;

  if p_utilizaroteirizacao = 'S' then


   if p_atualizarotanomomentovenda = 'S' then


     if (p_tipo not in ( 'PED','VIS') or p_tipo is null )then

        vbvalido := false;
        p_mensagem := 'Precisa informar o tipo de Movimentacao : PED ou VIS';


     end if;
     
     if p_data is null then

        vbvalido := false;
        p_mensagem := 'Precisa informar a data da movimentacao';


     end if;     


      select count(*)
      into vicont
      from pcmovrotacli p;
      
      if vicont = 0 then
      
        vbvalido := false;
        p_mensagem := 'Não existe registro de rota cadastrada na rotina 354.';
        
        
      else
      
          select count(*)
          into vicont
          from pcmovrotacli p
          where p.codusur = p_codusur;

            if vicont = 0 then
            
              vbvalido := false;
              p_mensagem := 'Não existe registro de rota cadastrada na rotina 354 para o rca : '||p_codusur;
              
              
            else

              select count(*)
              into vicont
              from pcmovrotacli p
              where p.codusur = p_codusur
              and   p.codcli  = p_codcli;
    
                if vicont = 0 then
                
                  vbvalido := false;
                  p_mensagem := 'Não existe registro de rota cadastrada na rotina 354 para o rca : '||p_codusur||' e cliente : '||p_codcli;
                  
                end if;



            end if;
      
      end if;


     if vbvalido = true then


       if p_codrota is null then

           if p_tipo = 'PED' then


           --CANCELA REGISTROS ANTIGOS

              update pcmovrotacli
              set dtcancel = trunc(sysdate),
                  tipovisita = 'C'
              where (p_data - to_number(periodicidade)) > dtvisitaprog
              and   dtcancel               is null
              and   codusur                = p_codusur
              and   codcli                 = p_codcli
              and   dtpedido               is null
              and   dtjustific             is null;

               commit; 


              select count(*)
              into vicont
              from pcmovrotacli p
              where p.codusur           = p_codusur
              and   p.codcli            = p_codcli
              and   (p.dtpedido is null or   p.dtpedido = p_data) --não tem pedido ou teve no mesmo dia
              and   dtcancel    is null
              and   dtjustific  is null                 --não tem justificativa
                 ;     


             if vicont > 1 then
             
              select count(*)
              into vicont
              from pcmovrotacli p
              where p.codusur           = p_codusur
              and   p.codcli            = p_codcli
              and   p.dtpedido          = p_data -- teve no mesmo dia
              and   dtcancel            is null
              and   dtjustific          is null                 --não tem justificativa
                 ;     

                   if vicont = 1 then

                      select rowid
                      into vnrowid  
                      from pcmovrotacli p
                      where p.codusur           = p_codusur
                      and   p.codcli            = p_codcli
                      and   p.dtpedido          = p_data -- teve no mesmo dia
                      and   dtcancel            is null
                      and   dtjustific          is null                 --não tem justificativa
                         ;     
    
                       update  PCMOVROTACLI
                       set qtpedido = nvl(qtpedido,0) + 1
                       where rowid = vnrowid;
    
                       commit;
                   end if;    

              elsif vicont = 1 then --encontrado apenas um registro


                 begin

              		select rowid,dtpedido,nvl(qtpedido,0) ,dtvisitaprog ,dtproxvisita,codvisita
              		into   vnrowid,vddtpedido,vnqtpedido ,vddtvisitaprog ,vddtproxvisita,vncodvisita
              		from pcmovrotacli p
              		where p.codusur = p_codusur
              		and   p.codcli  = p_codcli
              		and   p.dtcancel is null
                  and   dtjustific  is null
                  and   (p.dtpedido is null or   p.dtpedido = p_data); --não tem pedido ou teve no mesmo dia
                         

                 exception when others then

                  p_mensagem := 'Erro ao selecionar registro da PCMOVROTACLI :'||SQLCODE||' '||SQLERRM;

                 end;


                if vddtpedido is null then --ainda não atualizado


                  if vddtvisitaprog > p_Data then
                  
                   p_mensagem := 'Rota Antecipada';
                  
                  else


                          if vncodvisita is not null then --teve uma visita para este dia
        
                             update pcvisita
                             set cancelado = 'S',
                                 observacao = 'Justificativa cancelada, importado pedido : '||p_numped
                             where codvisita = vncodvisita;
        
        
                          end if;
        
        
                          update  pcmovrotacli
                          set dtultvisitaprev = vddtproxvisita,
                	            dtproxvisita    = dtproxvisita +
                                                decode(to_number(periodicidade),
                                                    15,
                                                    14,
                                                    30,
                                                    28,
                                                    45,
                                                    42,
                                                    to_number(periodicidade)),
          
                              dtpedido       = p_data,
                	            tipovisita     = (case when trunc(p_data) = pcmovrotacli.dtvisitaprog then 'E'
                	                                   when trunc(p_data) > pcmovrotacli.dtvisitaprog then 'P'
                	                                   end),
                              dtjustific     = null,
                	            codvisita      = null,
                	            qtpedido       = 1
                	         where  rowid = vnrowid;
        
        
                         update pcrotacli
                         set dtultvisitaprev = dtproxvisita,
                             dtproxvisita    = DECODE(nvl(DIAFIXO, 'N'),
                                                          'S',
                                                          dtproxvisita +
                                                          decode(to_number(periodicidade),
                                                                 15,
                                                                 14,
                                                                 30,
                                                                 28,
                                                                 45,
                                                                 42,
                                                                 to_number(periodicidade)),
                                                          NEXT_DAY(dtproxvisita, DIASEMANA))
                          where codusur = p_codusur
                          and   codcli  = p_codcli
                          and   dtproxvisita <= vdDTVISITAPROG 
                          and   dtproxvisita is not null
                          and   periodicidade in   ('1', '7', '14', '21', '28', '35', '42', '15', '30', '45');
        
                         commit;

                   end if;

                 else -- atualizado no dia

                   update  PCMOVROTACLI
                   set qtpedido = nvl(qtpedido,0) + 1
                   where rowid = vnrowid;

                   commit;

                 end if;



              end if;

          elsif p_tipo = 'VIS' then


           if p_codvisita is null then
           
              p_justvalida := false;
              p_mensagem := 'Favor informar o codigo da justificativa';
           
           end if;

           if p_codmotivovis is null then
           
              p_justvalida := false;
              p_mensagem := 'Favor informar o codigo do motivo da justificativa';
              
            else  
 
 
              BEGIN
                select p.tipomotivo
                  into vstipomotivo
                from pcmotvisita p
                where p.codmotivo = p_codmotivovis;

                if vstipomotivo not in (3,4) then
                  p_mensagem := 'Tipo invalido de justificativa :'||vstipomotivo;

                end if;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
               		select count(*)
                  into vicont
                  FROM pcmotnaocompra p
                  where p.codmotivo = p_codmotivovis;
                  if (vicont = 0) then
                      p_justvalida := false;
                      p_mensagem := 'Motivo não compra não cadastrado :'||p_codmotivovis;
                  end if;
              end;
           
           end if;


          if p_justvalida = true then

               --CANCELA REGISTROS ANTIGOS
    
               update pcmovrotacli
               set dtcancel = sysdate,
                   tipovisita = 'C'
               where (p_data - periodicidade > dtvisitaprog)
               and   dtcancel    is null
               and   codusur     = p_codusur
               and   codcli      = p_codcli
               and   dtpedido    is null
               and   dtjustific  is null;
    
               commit;
    
    
               select count(*)
               into vicont
               from PCMOVROTACLI P
               where p.codusur = p_codusur
               and   p.codcli  = p_codcli
               and   p.dtjustific is null
               and   p.dtcancel is null
               and   p.dtpedido is null  ;     
    
    
                 if vicont = 1 then
    
                		select rowid,dtjustific, codvisita,dtvisitaprog
                		into vnrowid,vddtjustific, vncodvisita, vddtvisitaprog
                		from pcmovrotacli p
                		where p.codusur         = p_codusur
                		and   p.codcli          = p_codcli
                		and   p.dtjustific      is null
                		and   p.dtcancel        is null
                    and   p.dtpedido        is null      ;   
    
    
                  if vddtvisitaprog > p_Data then
                  
                   p_mensagem := 'Nao ha rota programada para este cliente';
                   p_justvalida := false;
                  
                  else
    
    
                    update  pcmovrotacli
                    set dtultvisitaprev = dtproxvisita,
                        dtproxvisita    = dtproxvisita +
                                 decode(to_number(periodicidade),
                                        15,
                                        14,
                                        30,
                                        28,
                                        45,
                                        42,
                                        to_number(periodicidade)),
                        dtpedido = null, 
                        tipovisita  = decode(vstipomotivo,3,'N',4,'X'),
                        dtjustific  = trunc(p_data),
                        codvisita   = p_codvisita,
                        qtpedido    = null
                     where rowid = vnrowid;
    
    
                     update pcrotacli
                     set dtultvisitaprev = dtproxvisita,
                         dtproxvisita    = dtproxvisita +
                                          decode(to_number(periodicidade),
                                                  15,
                                                  14,
                                                  30,
                                                  28,
                                                  45,
                                                  42,
                                                  to_number(periodicidade))
                      where codusur = p_codusur
                      and   codcli  = p_codcli
                      and   dtproxvisita <= vdDTVISITAPROG 
                      and   dtproxvisita is not null
                      and   periodicidade in  ('1', '7', '14', '21', '28', '35', '42', '15', '30', '45');
    
    
                       commit;
    
                end if; 
        
                end if;
           end if;

           end if;


      


       else

         if p_tipo = 'PED' then
         
         
              select count(*)
              into vicont
              from pcmovrotacli p
              where codrota = p_codrota;
         
                if vicont = 0 then
                
                  p_mensagem := 'Nao existe rota cadastrada com este codigo :'||p_codrota;
                
                elsif vicont = 1 then
                
                  select p.dtpedido,p.codvisita,p.dtcancel,p.codcli,p.codusur,p.dtvisitaprog,p.dtproxvisita
                  into vddtpedido,vncodvisita,vddtcancel,vncodcli,vncodusur,vddtvisitaprog,vddtproxvisita
                  from pcmovrotacli p
                  where codrota = p_codrota;
                 
                 
                  if vddtcancel is not null then                 
                  
                    p_mensagem := 'Rota : '||p_codrota||' cancelada na data :'||vddtcancel;
                    
                  elsif vncodcli <> p_codcli then
                   
                    p_mensagem := 'Rota : '||p_codrota||' nao existe para cliente : '||p_codcli;
                    
                  elsif vncodusur <> p_Codusur then
                    p_mensagem := 'Rota : '||p_codrota||' nao existe para rca : '||p_codusur;  
                  
                  elsif vncodvisita is not null then
                                    
                     update pcvisita
                     set cancelado = 'S',
                         observacao = 'Justificativa cancelada, importado pedido : '||p_numped
                     where codvisita = vncodvisita;
                  
                     commit;
                     
 
                  
                  else


                    if vddtvisitaprog > p_data then
                 
                        p_mensagem := 'Nao ha rota programada para este cliente';
                  
                    end if;


                        if vddtpedido is not null then --já teve um pedido para esta rota
             
             
                           if trunc(vddtpedido) = trunc(p_data) then
             
                              update pcmovrotacli
                              set qtpedido = nvl(qtpedido,0) + 1
                              where codrota = p_codrota;
                              
                              commit;
                              
                           else -- tentando atualizar para uma rota que já foi atualizada em data diferente
                           
                              p_mensagem := 'Rota :'||p_codrota||' já foi atualizada. Favor entrar em contato seu força de vendas';
                           
                               
                            end if;   
                         else
                         
                              update  pcmovrotacli
                              set dtultvisitaprev = vddtproxvisita,
                    	            dtproxvisita    = dtproxvisita +
                                                    decode(to_number(periodicidade),
                                                        15,
                                                        14,
                                                        30,
                                                        28,
                                                        45,
                                                        42,
                                                        to_number(periodicidade)),
              
                                  dtpedido       = p_data,
                    	            tipovisita     = (case when trunc(p_data) = pcmovrotacli.dtvisitaprog then 'E'
                    	                                   when trunc(p_data) > pcmovrotacli.dtvisitaprog then 'P'
                                                         when trunc(p_data) < pcmovrotacli.dtvisitaprog then 'A'
                    	                                   end),
                                  dtjustific     = null,
                    	            codvisita      = null,
                    	            qtpedido       = 1
                    	         where  codrota = p_codrota;   
                               
                               update pcrotacli
                               set dtultvisitaprev = dtproxvisita,
                                   dtproxvisita    = dtproxvisita +
                                                    decode(to_number(periodicidade),
                                                            15,
                                                            14,
                                                            30,
                                                            28,
                                                            45,
                                                            42,
                                                            to_number(periodicidade))
                                where codusur = p_codusur
                                and   codcli  = p_codcli
                                and dtproxvisita <= vdDTVISITAPROG 
                                and dtproxvisita is not null
                                and periodicidade in
                                    ('1', '7', '14', '21', '28', '35', '42', '15', '30', '45');
                                     
                               commit;
           
                         end if;
                         
                         
                           
                end if;
         
               end if;
         
         
         elsif p_tipo = 'VIS' then
         
              select count(*)
              into vicont
              from pcmovrotacli p
              where codrota = p_codrota;
         
                if vicont = 0 then
                
                  p_mensagem := 'Nao existe rota cadastrada com este codigo :'||p_codrota;
                  p_justvalida := false;
                
                elsif vicont = 1 then
                
                  select p.dtpedido,p.codvisita,p.dtcancel,p.dtvisitaprog,p_codcli,p.codusur
                  into vddtpedido,vncodvisita,vddtcancel,vddtvisitaprog,vncodcli,vncodusur
                  from pcmovrotacli p
                  where codrota = p_codrota;
                 
                 
                  if vddtcancel is not null then                 
                  
                    p_mensagem := 'Rota : '||p_codrota||' cancelada na data :'||vddtcancel;
                   p_justvalida := false;    
                   
                  elsif vncodcli <> p_codcli then
                   
                    p_mensagem := 'Rota : '||p_codrota||' nao existe para cliente : '||p_codcli;
                    p_justvalida := false;
                    
                  elsif vncodusur <> p_Codusur then
                    p_mensagem := 'Rota : '||p_codrota||' nao existe para rca : '||p_codusur;  
                    p_justvalida := false;
                                 
                  
                  else


                    if vddtpedido is not null then --já teve um pedido para esta rota

                       p_mensagem := 'Rota : '||p_codrota||' ja atualizada com um pedido.';
                       p_justvalida := false;
         
                     else

                       if vncodvisita is not null then
         
                          p_mensagem := 'Rota :'||p_codrota||' já foi atualizada. Favor entrar em contato seu força de vendas';
                          p_justvalida := false;
                           
                       elsif vddtvisitaprog > p_data then
                       
                          p_mensagem := 'Visita fora da rota :'||p_codrota||'. Data programada : '||to_char(vddtvisitaprog,'dd/mm/yyyy') ;
                          p_justvalida := false;

                           
                       else

                     
                          update  pcmovrotacli
                          set dtultvisitaprev = dtproxvisita,
                              dtproxvisita    = dtproxvisita +
                                       decode(to_number(periodicidade),
                                              15,
                                              14,
                                              30,
                                              28,
                                              45,
                                              42,
                                              to_number(periodicidade)),
                              dtpedido = null, 
                              tipovisita  = decode(vstipomotivo,3,'N',4,'X'),
                              dtjustific  = trunc(p_data),
                              codvisita   = p_codvisita,
                              qtpedido    = null
                   	         where  codrota = p_codrota;    
                             
                             update pcrotacli
                             set dtultvisitaprev = dtproxvisita,
                                 dtproxvisita    = dtproxvisita +
                                                  decode(to_number(periodicidade),
                                                          15,
                                                          14,
                                                          30,
                                                          28,
                                                          45,
                                                          42,
                                                          to_number(periodicidade))
                              where codusur = p_codusur
                              and   codcli  = p_codcli
                              and   dtproxvisita <= vdDTVISITAPROG 
                              and   dtproxvisita is not null
                              and   periodicidade in  ('1', '7', '14', '21', '28', '35', '42', '15', '30', '45');
                                  
                           commit;
                        
                     end if;
                       
                end if;
         
               end if;
               
             end if;

         end if;


       end if;

    end if;

   end if;

  end if;




end PRC_ATUALIZA_ROTA;
/
