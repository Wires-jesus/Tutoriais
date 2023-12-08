create or replace procedure NFE_CANCELARNUMERACAO(P_CODFILIAL          varchar2,
                                                  P_DTEMISSAO          date,
                                                  P_NUMNOTA            number,
                                                  P_SERIE              number,
                                                  P_CODCLIFORNEC       number,
                                                  P_CHAVENFE           varchar2,
                                                  P_PROTOCOLOAUTOR     varchar2,
                                                  P_DTAUTOR            date,
                                                  P_PROTOCOLOCANC      varchar2,
                                                  P_DTCANCELAMENTO     date,
                                                  P_AMBIENTE           varchar2,
                                                  P_TIPOMOV            varchar2 default 'S',
                                                  P_NUMTRANSACAOREF    number,
                                                  P_NUMTRANSACAOGERADA out number) is

  VNPROXNUMTRANSVENDA    PCNFSAID.NUMTRANSVENDA%type;
  VNPROXNUMTRANSENT      PCNFENT.NUMTRANSENT%type;
  V_NUMTRANSITEMORIGINAL PCMOV.NUMTRANSITEM%type;
  CAB_SAIDA              PCNFSAID%rowtype;
  CAB_ENT                PCNFENT%rowtype;
  ITEM                   PCMOV%rowtype;
  ITEMCOMPLE             PCMOVCOMPLE%rowtype;
  PREFATURAMENTO         varchar2(1);
  V_CONT_NOTA_SAIDA      number(18,0);
  V_CONT_NOTA_PREFAT     number(18,0);

begin

  PREFATURAMENTO    := 'N';
  V_CONT_NOTA_SAIDA := 0;
  V_CONT_NOTA_PREFAT:= 0;
  if P_TIPOMOV = 'S' then
    begin
       P_NUMTRANSACAOGERADA := 0;
       for NOTA_SAIDA in (
         select NUMTRANSVENDA, 'N' PREFATURAMENTO
           from PCNFSAID, PCFILIAL
          where ((PCNFSAID.NUMNOTA = P_NUMNOTA 
                  and NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO 
                  and SERIE = TO_CHAR(P_SERIE) 
                  and PCFILIAL.CODIGO = P_CODFILIAL) 
                or
                 (PCNFSAID.CHAVENFE = P_CHAVENFE 
                  and P_CHAVENFE is not null))
                and PCNFSAID.DTSAIDA >= TRUNC(PCFILIAL.DTUTILIZANFE)
                and PCNFSAID.DTSAIDA >= (P_DTEMISSAO - 90)
                and ROWNUM = 1
          union all
          select NUMTRANSVENDA, 'S' PREFATURAMENTO
           from PCNFSAIDPREFAT, PCFILIAL
          where ((PCNFSAIDPREFAT.NUMNOTA = P_NUMNOTA 
                  and NVL(PCNFSAIDPREFAT.CODFILIALNF, PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO 
                  and SERIE = TO_CHAR(P_SERIE) 
                  and PCFILIAL.CODIGO = P_CODFILIAL) 
                or
                 (PCNFSAIDPREFAT.CHAVENFE = P_CHAVENFE 
                  and P_CHAVENFE is not null))
                and PCNFSAIDPREFAT.DTSAIDA >= TRUNC(PCFILIAL.DTUTILIZANFE)
                and PCNFSAIDPREFAT.DTSAIDA >= (P_DTEMISSAO - 90)
                and PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT is null
                and ROWNUM = 1
       ) loop
         P_NUMTRANSACAOGERADA := NOTA_SAIDA.NUMTRANSVENDA;
         V_CONT_NOTA_SAIDA    := V_CONT_NOTA_SAIDA + 1;
         PREFATURAMENTO       := NOTA_SAIDA.PREFATURAMENTO;
       end loop;
       if (V_CONT_NOTA_SAIDA > 1) then
         P_NUMTRANSACAOGERADA := 0;
       end if;
    exception
      when others then
        P_NUMTRANSACAOGERADA := 0;
    end;
  
    select count(1) into V_CONT_NOTA_PREFAT from PCNFSAIDPREFAT where PCNFSAIDPREFAT.NUMTRANSVENDA = P_NUMTRANSACAOREF and DATACONSOLIDACAOPREFAT is null;
    if (NVL(P_NUMTRANSACAOGERADA, 0) = 0) and (V_CONT_NOTA_PREFAT = 0) then
      
      select * into CAB_SAIDA from PCNFSAID where PCNFSAID.NUMTRANSVENDA = P_NUMTRANSACAOREF;
    
      VNPROXNUMTRANSVENDA  := FERRAMENTAS.F_PROX_NUMTRANSVENDA;
      P_NUMTRANSACAOGERADA := VNPROXNUMTRANSVENDA;
    
      insert into PCNFSAID
        (NUMTRANSVENDA
        ,NUMNOTA
        ,SERIE
        ,ESPECIE
        ,CODFISCAL
        ,VLTOTAL
        ,DTENTREGA
        ,DTSAIDA
        ,ICMSRETIDO
        ,BCST
        ,VLDESCONTO
        ,OBS
        ,CODCLI
        ,CODCONT
        ,CODFILIAL
        ,CODFILIALNF
        ,VLIPI
        ,VLBASEIPI
        ,VLFRETE
        ,VLOUTRASDESP
        ,CODPRACA
        ,CAIXA
        ,CODUSUR
        ,TIPOVENDA
        ,PERBASEREDOUTRASDESP
        ,CODCLINF
        ,CODFISCALFRETE
        ,CODFISCALOUTRASDESP
        ,PERCICMFRETE
        ,ALIQICMOUTRASDESP
        ,SITUACAONFE
        ,DTLANCTO
        ,AMBIENTENFE
        ,CHAVENFE
        ,PROTOCOLONFE
        ,DTHORAAUTORIZACAOSEFAZ
        ,PROTOCOLOCANCELAMENTO
        ,DTCANCEL
        ,DTHORACANCELAMENTOSEFAZ
        ,CONDVENDA
        ,NOTADUPLIQUESVC)
      values
        (VNPROXNUMTRANSVENDA
        ,P_NUMNOTA
        ,TO_CHAR(P_SERIE)
        ,'NF'
        ,599
        ,0
        ,TRUNC(P_DTEMISSAO)
        ,TRUNC(P_DTEMISSAO)
        ,0
        ,0
        ,0
        ,'NF CANCELADA'
        ,P_CODCLIFORNEC
        ,0
        ,P_CODFILIAL
        ,P_CODFILIAL
        ,0
        ,0
        ,0
        ,0
        ,0
        ,0
        ,NVL(CAB_SAIDA.CODUSUR, 0)
        ,'1'
        ,0
        ,P_CODCLIFORNEC
        ,0
        ,0
        ,0
        ,0
        ,100
        ,sysdate
        ,P_AMBIENTE
        ,P_CHAVENFE
        ,P_PROTOCOLOAUTOR
        ,P_DTAUTOR
        ,P_PROTOCOLOCANC
        ,P_DTCANCELAMENTO
        ,P_DTCANCELAMENTO
        ,CAB_SAIDA.CONDVENDA
        ,'S');
      
      --inserto necessário para relatório da rotina 1418  
      INSERT INTO PCNFCAN
        (NUMTRANSVENDA,
         CODFUNCCANC,
         DATACANC,
         CODCLI,
         MOTIVO,
         CODFUNCEMITE,
         DATAEMISSAO,
         VLTOTAL,
         CODROTINA,
         DESCRICAO,
         NUMPED,
         CODFILIAL,
         DTDENEGADA,
         HORADENEGADA)
      VALUES
        (VNPROXNUMTRANSVENDA,
         1,
         P_DTEMISSAO,
         P_CODCLIFORNEC,
         'NF CANCELADA',
         1,
         P_DTEMISSAO,
         0,
         1452,
         NULL,
         NULL,
         P_CODFILIAL,
         NULL,
         NULL);
    
      for REG in (select rowid ID, 'N' PREFATURAMENTO
                    from PCMOV
                   where PCMOV.NUMTRANSVENDA = P_NUMTRANSACAOREF
                     and PCMOV.QTCONT > 0
                     and PREFATURAMENTO = 'N'
                  )
      loop
      
        select * into ITEM from PCMOV where rowid = REG.ID;
      
        ITEM.NUMTRANSVENDA := VNPROXNUMTRANSVENDA;
        ITEM.NUMNOTA       := P_NUMNOTA;
        ITEM.STATUS        := 'A';
        ITEM.QT            := 0;
        ITEM.DTCANCEL      := sysdate;
        ITEM.QTDEVOL       := 0;
        ITEM.TIPOITEM      := 'N';
      
        if (ITEM.NUMTRANSITEM is not null) then
          V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
        
          select DFSEQ_PCMOVCOMPLE.NEXTVAL into ITEM.NUMTRANSITEM from DUAL;
        end if;
      
        insert into PCMOV values ITEM;
      
        if (ITEM.NUMTRANSITEM is not null) then
          begin
            select * into ITEMCOMPLE from PCMOVCOMPLE where NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
          
            ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
          
            insert into PCMOVCOMPLE values ITEMCOMPLE;
          exception
            when others then
              null;
          end;
        end if;
      
        ITEM.QTCONT := ITEM.QTCONT * (-1);
      
        if (ITEM.NUMTRANSITEM is not null) then
          V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
        
          select DFSEQ_PCMOVCOMPLE.NEXTVAL into ITEM.NUMTRANSITEM from DUAL;
        end if;
      
        insert into PCMOV values ITEM;
      
        if (ITEM.NUMTRANSITEM is not null) then
          begin
            select * into ITEMCOMPLE from PCMOVCOMPLE where NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
          
            ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
          
            insert into PCMOVCOMPLE values ITEMCOMPLE;
          exception
            when others then
              null;
          end;
        end if;
      end loop;
      --Removido para correção no processo. Este update é feito agora na rotina 1452
      --UPDATE PCINUTILIZARNFE SET NUMTRANSACAONOVA = P_NUMTRANSACAOGERADA  WHERE NUMTRANSACAO = P_NUMTRANSACAOREF;
    else
      if (V_CONT_NOTA_PREFAT = 0) then
        if (PREFATURAMENTO = 'S') then
          update PCNFSAIDPREFAT
               set SITUACAONFE = 100
                  ,ESPECIE = 'NF'
                  ,CHAVENFE = P_CHAVENFE
                  ,PROTOCOLONFE = P_PROTOCOLOAUTOR
                  ,DTHORAAUTORIZACAOSEFAZ = P_DTAUTOR
                  ,PROTOCOLOCANCELAMENTO = P_PROTOCOLOCANC
                  ,DTHORACANCELAMENTOSEFAZ = P_DTCANCELAMENTO
             where NUMTRANSVENDA = P_NUMTRANSACAOGERADA;  
        else
          update PCNFSAID
               set SITUACAONFE = 100
                  ,ESPECIE = 'NF'
                  ,CHAVENFE = P_CHAVENFE
                  ,PROTOCOLONFE = P_PROTOCOLOAUTOR
                  ,DTHORAAUTORIZACAOSEFAZ = P_DTAUTOR
                  ,PROTOCOLOCANCELAMENTO = P_PROTOCOLOCANC
                  ,DTHORACANCELAMENTOSEFAZ = P_DTCANCELAMENTO
             where NUMTRANSVENDA = P_NUMTRANSACAOGERADA;  
        end if;
      end if;      
    end if;
  
  else
    begin
      select NUMTRANSENT
        into P_NUMTRANSACAOGERADA
        from PCNFENT, PCFILIAL
       where ((PCNFENT.NUMNOTA = P_NUMNOTA and
             NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCFILIAL.CODIGO and
             SERIE = TO_CHAR(P_SERIE) and PCFILIAL.CODIGO = P_CODFILIAL) or
             (PCNFENT.CHAVENFE = P_CHAVENFE and P_CHAVENFE is not null))
         and PCNFENT.DTENT >= TRUNC(PCFILIAL.DTUTILIZANFE)
         and ROWNUM = 1;
    exception
      when others then
        P_NUMTRANSACAOGERADA := 0;
    end;
  
    if NVL(P_NUMTRANSACAOGERADA, 0) = 0 then
    
      select * into CAB_ENT from PCNFENT where PCNFENT.NUMTRANSENT = P_NUMTRANSACAOREF;
    
      VNPROXNUMTRANSENT    := FERRAMENTAS.F_PROX_NUMTRANSENT;
      P_NUMTRANSACAOGERADA := VNPROXNUMTRANSENT;
    
      insert into PCNFENT
        (NUMTRANSENT
        ,NUMNOTA
        ,SERIE
        ,ESPECIE
        ,CODFISCAL
        ,VLTOTAL
        ,DTEMISSAO
        ,DTENT
        ,VLST
        ,BASEICST
        ,VLDESCONTO
        ,OBS
        ,CODFORNEC
        ,CODCONT
        ,CODFILIAL
        ,CODFILIALNF
        ,VLIPI
        ,VLBASEIPI
        ,VLFRETE
        ,VLOUTRAS
        ,TIPODESCARGA
        ,PERBASEREDOUTRASDESP
        ,CODFORNECNF
        ,CODFISCALFRETE
        ,CODFISCALOUTRASDESP
        ,PERCICMFRETE
        ,ALIQICMOUTRASDESP
        ,SITUACAONFE
        ,DTLANCTO
        ,GERANFVENDA
        ,AMBIENTENFE
        ,CHAVENFE
        ,PROTOCOLONFE
        ,DTHORAAUTORIZACAOSEFAZ
        ,PROTOCOLOCANCELAMENTO
        ,DTCANCEL
        ,DTHORACANCELAMENTOSEFAZ
        ,NOTADUPLIQUESVC)
      values
        (VNPROXNUMTRANSENT
        ,P_NUMNOTA
        ,TO_CHAR(P_SERIE)
        ,'NF'
        ,199
        ,0
        ,TRUNC(P_DTEMISSAO)
        ,TRUNC(P_DTEMISSAO)
        ,0
        ,0
        ,0
        ,'NF CANCELADA'
        ,P_CODCLIFORNEC
        ,0
        ,P_CODFILIAL
        ,P_CODFILIAL
        ,0
        ,0
        ,0
        ,0
        ,CAB_ENT.TIPODESCARGA
        ,0
        ,P_CODCLIFORNEC
        ,0
        ,0
        ,0
        ,0
        ,100
        ,sysdate
        ,'S'
        ,P_AMBIENTE
        ,P_CHAVENFE
        ,P_PROTOCOLOAUTOR
        ,P_DTAUTOR
        ,P_PROTOCOLOCANC
        ,P_DTCANCELAMENTO
        ,P_DTCANCELAMENTO
        ,'S');

--inserto necessário para relatório da rotina 1418  
      INSERT INTO PCNFCAN
        (NUMTRANSVENDA,
         CODFUNCCANC,
         DATACANC,
         CODCLI,
         MOTIVO,
         CODFUNCEMITE,
         DATAEMISSAO,
         VLTOTAL,
         CODROTINA,
         DESCRICAO,
         NUMPED,
         CODFILIAL,
         DTDENEGADA,
         HORADENEGADA)
      VALUES
        (VNPROXNUMTRANSVENDA,
         1,
         P_DTEMISSAO,
         P_CODCLIFORNEC,
         'NF CANCELADA',
         1,
         P_DTEMISSAO,
         0,
         1452,
         NULL,
         NULL,
         P_CODFILIAL,
         NULL,
         NULL);
     
      for REG in (select rowid ID
                    from PCMOV
                   where PCMOV.NUMTRANSENT = P_NUMTRANSACAOREF
                     and PCMOV.QTCONT > 0)
      loop
      
        select * into ITEM from PCMOV where rowid = REG.ID;
      
        ITEM.NUMTRANSENT := VNPROXNUMTRANSENT;
        ITEM.NUMNOTA     := P_NUMNOTA;
        ITEM.STATUS      := 'A';
        ITEM.QT          := 0;
        ITEM.DTCANCEL    := sysdate;
        ITEM.QTDEVOL     := 0;
      
        if (ITEM.NUMTRANSITEM is not null) then
          V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
        
          select DFSEQ_PCMOVCOMPLE.NEXTVAL into ITEM.NUMTRANSITEM from DUAL;
        end if;
      
        insert into PCMOV values ITEM;
      
        if (ITEM.NUMTRANSITEM is not null) then
          begin
            select * into ITEMCOMPLE from PCMOVCOMPLE where NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
          
            ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
          
            insert into PCMOVCOMPLE values ITEMCOMPLE;
          exception
            when others then
              null;
          end;
        end if;
      
        ITEM.QTCONT := ITEM.QTCONT * (-1);
      
        if (ITEM.NUMTRANSITEM is not null) then
          V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
        
          select DFSEQ_PCMOVCOMPLE.NEXTVAL into ITEM.NUMTRANSITEM from DUAL;
        end if;
      
        insert into PCMOV values ITEM;
      
        if (ITEM.NUMTRANSITEM is not null) then
          begin
            select * into ITEMCOMPLE from PCMOVCOMPLE where NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
          
            ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
          
            insert into PCMOVCOMPLE values ITEMCOMPLE;
          exception
            when others then
              null;
          end;
        end if;
      
      end loop;
      --Removido para correção no processo. Este update é feito agora na rotina 1452
      --UPDATE PCINUTILIZARNFE SET NUMTRANSACAONOVA = P_NUMTRANSACAOGERADA  WHERE NUMTRANSACAO = P_NUMTRANSACAOREF;
    else
      update PCNFENT
         set SITUACAONFE = 100
            ,ESPECIE = 'NF'
       where NUMNOTA = P_NUMNOTA
         and SERIE = TO_CHAR(P_SERIE)
         and CODFILIAL = P_CODFILIAL
         and NUMTRANSENT = P_NUMTRANSACAOGERADA;
    end if;
  end if;
  commit;
end;
--Bruno 23/05/2018 