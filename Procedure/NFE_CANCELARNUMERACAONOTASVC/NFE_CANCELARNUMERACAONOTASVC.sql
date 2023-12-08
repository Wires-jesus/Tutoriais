create or replace procedure NFE_CANCELARNUMERACAONOTASVC(P_CODFILIAL             varchar2,
                                                         P_DTEMISSAO             date,
                                                         P_NUMNOTA               number,
                                                         P_CODCLIFORNEC          number,
                                                         P_CHAVENFE              varchar2,
                                                         P_protocoloCancelamento varchar2,
                                                         P_DTcancelamento        date,
                                                         P_TIPOMOV               varchar2 default 'S') is
  V_NUMTRANSITEMORIGINAL      PCMOV.NUMTRANSITEM%type;
  ITEM                        PCMOV%rowtype;
  ITEMCOMPLE                  PCMOVCOMPLE%rowtype;
  V_NUMTRANSACAOGERADA        number;
  VMSGRETORNORECALCULOESTOQUE VARCHAR2(1000);
  V_DTNOTA                    PCNFSAID.DTSAIDA%type;
  V_TOTAL_NOTA                PCNFSAID.VLTOTAL%type;
  vREC_QTDE                   PKG_ANALISAR_ESTOQUE.TP_ENTRADA;
  VNRETORNOPKGESTOQUE         INTEGER;
  
  PROCEDURE GERAR_LOG(PNUMNOTA       IN NUMBER,
                      PCHAVENFE      IN VARCHAR2,
                      PNUMTRANSVENDA IN VARCHAR2,
                      PMENSAGEM      IN VARCHAR2,
                      PMENSAGEM_ERRO IN VARCHAR2) IS
  BEGIN
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2)
    VALUES
      (SYSDATE,
       'INDEFINIDA',
       'INDEFINIDA',
       'A',
       'CANCELAMENTO DE NOTA DO PROCESSO SVC NUMTRANSVENDA ORIG. : ' ||
       PNUMTRANSVENDA,
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       SUBSTR(PMENSAGEM || PNUMNOTA || ' CHAVENFE: ' || PCHAVENFE, 1, 100),
       SUBSTR('ERRO ORIGINAL: ' || PMENSAGEM_ERRO, 1, 100));
  END;
begin
  V_TOTAL_NOTA := 0;
  delete from PCLISTAPROD_TMP;
  if P_TIPOMOV = 'S' then
    begin
      select PCNFSAID.NUMTRANSVENDA, PCNFSAID.DTSAIDA, PCNFSAID.VLTOTAL
        into V_NUMTRANSACAOGERADA, V_DTNOTA, V_TOTAL_NOTA
        from PCNFSAID, PCFILIAL
       where PCNFSAID.NUMNOTA = P_NUMNOTA
         and NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
             PCFILIAL.CODIGO
         and pcnfsaid.especie in ('NF')
         and pcnfsaid.notadupliquesvc = 'S'
         and pcfilial.codigo = P_CODFILIAL
         and pcnfsaid.dtsaida = P_DTEMISSAO
         and pcnfsaid.chavenfe = P_CHAVENFE
         and pcnfsaid.dtcancel is null
         and ROWNUM = 1;
    exception
      when others then
        V_NUMTRANSACAOGERADA := 0;
    end;
  
    if NVL(V_NUMTRANSACAOGERADA, 0) <> 0 then
      update pcnfsaid
         set situacaonfe                    = 101,
             dtcancel                       = trunc(P_DTcancelamento),
             pcnfsaid.protocolocancelamento = P_protocoloCancelamento,
             VLTOTAL                        = 0,
             ICMSRETIDO                     = 0,
             BCST                           = 0,
             VLDESCONTO                     = 0,
             VLIPI                          = 0,
             VLBASEIPI                      = 0,
             VLFRETE                        = 0,
             VLOUTRASDESP                   = 0,
             PERCICMFRETE                   = 0,
             ALIQICMOUTRASDESP              = 0
       where numtransvenda = V_NUMTRANSACAOGERADA;
    
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
        (V_NUMTRANSACAOGERADA,
         1,
         P_DTEMISSAO,
         P_CODCLIFORNEC,
         'NF CANCELADA',
         1,
         P_DTEMISSAO,
         V_TOTAL_NOTA,
         1452,
         NULL,
         NULL,
         P_CODFILIAL,
         NULL,
         NULL);
    
      for REG in (select rowid ID
                    from PCMOV
                   where PCMOV.NUMTRANSVENDA = V_NUMTRANSACAOGERADA
                     and PCMOV.QTCONT > 0) loop
      
        select * into ITEM from PCMOV where rowid = REG.ID;
        INSERT INTO PCLISTAPROD_TMP (CODPROD) VALUES (ITEM.CODPROD);
      
        ITEM.NUMTRANSVENDA := V_NUMTRANSACAOGERADA;
        ITEM.NUMNOTA       := P_NUMNOTA;
        ITEM.STATUS        := 'A';
        ITEM.QT            := 0;
        ITEM.DTCANCEL      := sysdate;
        ITEM.QTDEVOL       := 0;
        ITEM.TIPOITEM      := 'N';
        ITEM.MOVESTOQUEGERENCIAL := 'N';
      
        if (ITEM.NUMTRANSITEM is not null) then
          V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
        
          select DFSEQ_PCMOVCOMPLE.NEXTVAL
            into ITEM.NUMTRANSITEM
            from DUAL;
        end if;
      
        ITEM.QTCONT := ITEM.QTCONT * (-1);
      
        insert into PCMOV values ITEM;
        update pcmov set dtcancel = sysdate where rowid = reg.id;
        COMMIT;
      
        if (ITEM.NUMTRANSITEM is not null) then
          begin
            select *
              into ITEMCOMPLE
              from PCMOVCOMPLE
             where NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
          
            ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
            insert into PCMOVCOMPLE values ITEMCOMPLE;
            COMMIT;
          exception
            when others then
              null;
          end;
        end if;
        
        
      
      end loop;
      
      VNRETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_SAIDA(V_NUMTRANSACAOGERADA,'S', VMSGRETORNORECALCULOESTOQUE);
      
      IF NVL(VNRETORNOPKGESTOQUE, 0) <= 0 THEN
        GERAR_LOG(P_NUMNOTA,
          P_CHAVENFE,
          V_NUMTRANSACAOGERADA,
          'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE ' ||
          VMSGRETORNORECALCULOESTOQUE,
          '');
      END IF;
    end if;
  else
    begin
      select PCNFENT.numtransent, PCNFENT.DTENT, PCNFENT.VLTOTAL
        into V_NUMTRANSACAOGERADA, V_DTNOTA, V_TOTAL_NOTA
        from pcnfent, PCFILIAL
       where pcnfent.NUMNOTA = P_NUMNOTA
         and NVL(pcnfent.CODFILIALNF, pcnfent.CODFILIAL) = PCFILIAL.CODIGO
         and pcnfent.especie in ('NF')
         and pcnfent.notadupliquesvc = 'S'
         and pcfilial.codigo = P_CODFILIAL
         and pcnfent.dtsaida = P_DTEMISSAO
         and pcnfent.chavenfe = P_CHAVENFE
         and ROWNUM = 1;
    exception
      when others then
        V_NUMTRANSACAOGERADA := 0;
    end;
  
    if NVL(V_NUMTRANSACAOGERADA, 0) <> 0 then
      update pcnfent
         set situacaonfe           = 101,
             dtcancel              = P_DTcancelamento,
             protocolocancelamento = P_protocoloCancelamento,
             VLTOTAL               = 0,
             VLST                  = 0,
             BASEICST              = 0,
             VLDESCONTO            = 0,
             VLIPI                 = 0,
             VLBASEIPI             = 0,
             VLFRETE               = 0,
             VLOUTRAS              = 0,
             PERBASEREDOUTRASDESP  = 0,
             PERCICMFRETE          = 0,
             ALIQICMOUTRASDESP     = 0
       where numtransent = V_NUMTRANSACAOGERADA;
    
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
        (V_NUMTRANSACAOGERADA,
         1,
         P_DTEMISSAO,
         P_CODCLIFORNEC,
         'NF CANCELADA',
         1,
         P_DTEMISSAO,
         V_TOTAL_NOTA,
         1452,
         NULL,
         NULL,
         P_CODFILIAL,
         NULL,
         NULL);
    
      for REG in (select rowid ID
                    from PCMOV
                   where PCMOV.NUMTRANSENT = V_NUMTRANSACAOGERADA
                     and PCMOV.QTCONT > 0) loop
      
        SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;
        INSERT INTO PCLISTAPROD_TMP (CODPROD) VALUES (ITEM.CODPROD);
      
        ITEM.NUMTRANSENT := V_NUMTRANSACAOGERADA;
        ITEM.NUMNOTA     := P_NUMNOTA;
        ITEM.STATUS      := 'A';
        ITEM.QT          := 0;
        ITEM.DTCANCEL    := sysdate;
        ITEM.QTDEVOL     := 0;
        ITEM.MOVESTOQUEGERENCIAL := 'N';
      
        if (ITEM.NUMTRANSITEM is not null) then
          V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
        
          select DFSEQ_PCMOVCOMPLE.NEXTVAL
            into ITEM.NUMTRANSITEM
            from DUAL;
        end if;
      
        ITEM.QTCONT := ITEM.QTCONT * (-1);
        insert into PCMOV values ITEM;
        update pcmov set dtcancel = sysdate where rowid = reg.id;
        COMMIT;
      
        if (ITEM.NUMTRANSITEM is not null) then
          begin
            select *
              into ITEMCOMPLE
              from PCMOVCOMPLE
             where NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
          
            ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
            insert into PCMOVCOMPLE values ITEMCOMPLE;
            COMMIT;
          exception
            when others then
              null;
          end;
        end if;
      
      end loop;
    
      VNRETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_ENTRADA(V_NUMTRANSACAOGERADA,'S', VMSGRETORNORECALCULOESTOQUE);
      
      IF NVL(VNRETORNOPKGESTOQUE, 0) <= 0 THEN
        GERAR_LOG(P_NUMNOTA,
          P_CHAVENFE,
          V_NUMTRANSACAOGERADA,
          'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE ' ||
          VMSGRETORNORECALCULOESTOQUE,
          '');
      END IF;
    
    end if;
  end if;
  commit;
end;