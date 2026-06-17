CREATE OR REPLACE PACKAGE BODY FERRAMENTAS_FATURAMENTO IS

  PROCEDURE atualizarTotaisVenda(pParametros      IN T_ATUALIZAR_TOTAIS_VENDA,
                                pMensagemRetorno OUT VARCHAR2) IS
  BEGIN
    --Este método já recebe todos os campos e valores calculados, apenas atualiza no banco de dados
    pMensagemRetorno := 'OK';
    BEGIN
      UPDATE pcest
         SET qtvenddia      = qtvenddia + nvl(pParametros.QuantidadeVendaDia, 0),
             qtvendsemana   = qtvendsemana + nvl(pParametros.QuantidadeVendaSemana, 0),
             qtvendmes      = qtvendmes + nvl(pParametros.QuantidadeVendaMes, 0),
             vlvenddia      = vlvenddia + nvl(pParametros.ValorVendaDia, 0),
             vlvendmes      = vlvendmes + nvl(pParametros.ValorVendaMes, 0),
             vlvenddiareal  = vlvenddiareal + nvl(pParametros.ValorVendaRealDia, 0),
             vlvendmesreal  = vlvendmesreal + nvl(pParametros.ValorVendaRealMes, 0),
             vlcustodiareal = vlcustodiareal + nvl(pParametros.ValorCustoRealDia, 0),
             vlcustomesreal = vlcustomesreal + nvl(pParametros.ValorCustoRealMes, 0),
             vlcustodiafin  = vlcustodiafin + nvl(pParametros.ValorCustoFinanceiroDia, 0),
             vlcustomesfin  = vlcustomesfin + nvl(pParametros.ValorCustoFinanceiroMes, 0),
             dtultfat       = sysdate
       where codprod = pParametros.codigoProduto
         AND codfilial = pParametros.CodigoFilial;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pMensagemRetorno := 'Erro ao atualizar totais de venda na tabela PCEST. Dados não encontrados para o produto ' ||
                            pParametros.codigoProduto || ' e filial ' ||
                            pParametros.CodigoFilial;
        RAISE;
      WHEN OTHERS THEN
        pMensagemRetorno := 'Erro ao atualizar totais de venda na tabela PCEST (Produto: ' ||
                            pParametros.codigoProduto || ', filial: ' ||
                            pParametros.CodigoFilial || '). Erro orignal: ' ||
                            SQLERRM;
        RAISE;
    END;
  END;
  
  PROCEDURE atualizarPcGiro(pParametros      IN T_ATUALIZAR_TOTAIS_VENDA,
                                 pMensagemRetorno OUT VARCHAR2) IS
  BEGIN
    --Este método já recebe todos os campos e valores calculados, apenas atualiza no banco de dados
    pMensagemRetorno := 'OK';        
        BEGIN
          -- 11 - Cria ou atualiza dos registros na tabela PCGIRO
          UPDATE pcgiro
             SET giro = giro + nvl(pParametros.QuantidadeVendaDia, 0)
           WHERE codprod =  pParametros.codigoProduto
             AND codfilial = pParametros.CodigoFilial
             AND numregiao = pParametros.numregiao;
        
          IF SQL%ROWCOUNT = 0 THEN
            -- Caso seja um registro novo sera um insert
            INSERT INTO pcgiro
              (codprod, numregiao, giro, codfilial)
            VALUES
              (pParametros.codigoProduto,
               pParametros.numregiao,
               nvl(pParametros.QuantidadeVendaDia, 0),
               pParametros.CodigoFilial);
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            pMensagemRetorno := 'Erro ao atualizar totais de venda na tabela PCGIRO (Produto: ' ||  pParametros.codigoProduto 
                             || ', filial: ' || pParametros.CodigoFilial 
                             || ', Numregiao: ' || pParametros.numregiao || '). Erro orignal: ' ||
                            SQLERRM;
            RAISE;
        END;        
  END;  

  FUNCTION buscarEatualizarTotaisVenda(pNumtransvenda   in pcnfsaid.numtransvenda%type,
                                       pMensagemRetorno OUT VARCHAR2)
    RETURN VARCHAR2 IS
    vAtualizarTotaisVenda T_ATUALIZAR_TOTAIS_VENDA;
  BEGIN
    --Este mpetodo já recebe apenas o código do produto e filial, e faz a busca e cálculo dos valores
    --para atualizar no banco de dados
    pMensagemRetorno := 'OK';
    IF ((pNumtransvenda IS NULL) OR (pNumtransvenda = 0)) THEN
      pMensagemRetorno := 'Parâmetro pNumtransvenda não foi informado!';
      RETURN 'N';
    END IF;
   
    BEGIN
      for movimentacao in (select pcmov.codprod,
                                  pcmov.codfilial,
                                  pcmov.numnota,
								  pcmov.numregiao,
                                  pcmov.custoreal,
                                  pcmov.custofin,
                                  nvl(pcmov.qtcont, 0) qtcont,
                                  (DECODE(NVL(pcmov.tipoitem, 'C'),
                                          'C',
                                          DECODE(pcmov.codoper,
                                                 'S',
                                                 DECODE(NVL(pcmov.tipoitem,
                                                            'C'),
                                                        'C',
                                                        (NVL(DECODE(pcnfsaid.condvenda,
                                                                    7,
                                                                    pcmov.qtcont,
                                                                    pcmov.qt),
                                                             0)),
                                                        pcmov.qtcont),
                                                 'ST',
                                                 (NVL(DECODE(pcnfsaid.condvenda,
                                                             7,
                                                             pcmov.qtcont,
                                                             pcmov.qt),
                                                      0)),
                                                 'SM',
                                                 (NVL(DECODE(pcnfsaid.condvenda,
                                                             7,
                                                             pcmov.qtcont,
                                                             pcmov.qt),
                                                      0)),
                                                 0),
                                          pcmov.qtcont)) qtvenda,
                                  ROUND((((DECODE(pcmov.codoper,
                                                  'S',
                                                  (NVL(DECODE(pcnfsaid.condvenda,
                                                              7,
                                                              pcmov.qtcont,
                                                              pcmov.qt),
                                                       0)),
                                                  'ST',
                                                  (NVL(DECODE(pcnfsaid.condvenda,
                                                              7,
                                                              pcmov.qtcont,
                                                              pcmov.qt),
                                                       0)),
                                                  'SM',
                                                  (NVL(DECODE(pcnfsaid.condvenda,
                                                              7,
                                                              pcmov.qtcont,
                                                              pcmov.qt),
                                                       0)),
                                                  0)) *
                                        (NVL(DECODE(pcnfsaid.condvenda,
                                                      7,
                                                      pcmov.punitcont,
                                                      NVL(pcmov.punit, 0) +
                                                      NVL(pcmov.vlfrete, 0) +
                                                      NVL(pcmov.vloutrasdesp,
                                                          0) +
                                                      NVL(pcmov.vlfrete_rateio,
                                                          0) +
                                                      NVL(pcmov.vloutros, 0) -
                                                      NVL(pcmov.vlrepasse, 0)),
                                               0)))),
                                        2) vlvenda
                             from pcmov, pcnfsaid, pcmovcomple
                            where pcmov.numtransvenda = pNumtransvenda
                              and pcmov.numtransvenda = pcnfsaid.numtransvenda
                              and exists(select 1
                                           from pcpedc
                                          where pcpedc.numped = pcnfsaid.numped
                                            and pcpedc.numtransvenda = pcnfsaid.numtransvenda
                                            and ((nvl(pcpedc.broker, 'N') = 'N') or
                                                 ((nvl(pcpedc.broker, 'N') = 'S') and 
                                                  nvl(paramfilial.obtercomovarchar2('FIL_TIPOBROKER', pcnfsaid.codfilial), 'N') = 'MAB'))
                                            and (pcpedc.condvenda in (1,5,8,9,14) or
                                                 pcpedc.condvenda = decode(nvl(paramfilial.obtercomovarchar2('CON_CALCULAGIROTRANSF'), 'N'), 'S', 10, 1)))
                              and (pcmov.codoper in ('S', 'SB', 'SM') or
                                   pcmov.codoper = decode(nvl(paramfilial.obterComovarchar2('FIL_CONSIDERAMONTAGEMGIROMERC', pcnfsaid.codfilial), 'N'), 'S', 'SP', 'S') or
                                   pcmov.codoper = decode(nvl(paramfilial.obtercomovarchar2('CON_CALCULAGIROTRANSF'), 'N'), 'S', 'ST', 'S'))
                              and pcmov.dtmov = pcnfsaid.dtsaida
                              and pcmovcomple.numtransitem(+) = pcmov.numtransitem
                              and pcnfsaid.numped > 0) LOOP

        BEGIN
          select pcest.codprod,
                 pcest.codfilial
            into vAtualizarTotaisVenda.codigoProduto,
                 vAtualizarTotaisVenda.codigoFilial
            from pcest
           where pcest.codprod = movimentacao.codprod
             and pcest.codfilial = movimentacao.codfilial;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pMensagemRetorno := 'Dados não encontrados na tabela PCEST para o produto ' ||
                                movimentacao.codprod || ' e filial ' ||
                                movimentacao.codfilial;
            RETURN 'N';
          WHEN OTHERS THEN
            pMensagemRetorno := 'Erro ao buscar dados dos totais de venda na tabela PCEST (Produto: ' ||
                                movimentacao.codprod || ', filial: ' ||
                                movimentacao.codfilial ||
                                '). Erro orignal: ' || SQLERRM;
            RETURN 'N';
        END;

        vAtualizarTotaisVenda.QuantidadeVendaDia      := GREATEST(movimentacao.qtvenda, movimentacao.qtcont);
        vAtualizarTotaisVenda.QuantidadeVendaSemana   := GREATEST(movimentacao.qtvenda, movimentacao.qtcont);
        vAtualizarTotaisVenda.QuantidadeVendaMes      := GREATEST(movimentacao.qtvenda, movimentacao.qtcont);
        vAtualizarTotaisVenda.ValorVendaDia           := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorVendaMes           := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorVendaRealDia       := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorVendaRealMes       := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorCustoRealDia       := (movimentacao.qtvenda * movimentacao.custoreal);
        vAtualizarTotaisVenda.ValorCustoRealMes       := (movimentacao.qtvenda * movimentacao.custoreal);
        vAtualizarTotaisVenda.ValorCustoFinanceiroDia := (movimentacao.qtvenda * movimentacao.custofin);
        vAtualizarTotaisVenda.ValorCustoFinanceiroMes := (movimentacao.qtvenda * movimentacao.custofin);
		vAtualizarTotaisVenda.numregiao               := movimentacao.numregiao;
        atualizarTotaisVenda(vAtualizarTotaisVenda, pMensagemRetorno);	
       
	    AtualizarPcGiro(vAtualizarTotaisVenda, pMensagemRetorno);
				
      END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pMensagemRetorno := 'Dados não encontrados na movimentação da nota com transação ' ||
                            pNumtransvenda;
        RETURN 'N';
      WHEN OTHERS THEN
        pMensagemRetorno := 'Erro buscar dados da movimentação da nota com transação ' ||
                            pNumtransvenda || '. Erro orignal: ' || SQLERRM;
        RETURN 'N';
    END;
    
    RETURN 'S';
  END;
  
  FUNCTION TRANSF_CARREGAMENTO(PNUMCARORIGEM IN PCCARREG.NUMCAR%TYPE,
                               PNUMCARDESTINO IN PCCARREG.NUMCAR%TYPE,
                               PMSGRETORNO OUT VARCHAR2,
                               PCODFUNCTRANSF IN PCLOGTRANSFNFCARREG.CODFUNCTRANSF%TYPE DEFAULT NULL,
                               PCODMOTIVO IN PCLOGTRANSFNFCARREG.CODMOTIVO%TYPE DEFAULT NULL,
                               PMOTIVOTRANSF IN PCLOGTRANSFNFCARREG.MOTIVOTRANSF%TYPE DEFAULT '',
                               PNUMPED IN PCNFSAID.NUMPED%TYPE DEFAULT 0,
                               PNUMTRANSVENDA IN PCNFSAID.NUMTRANSVENDA%TYPE DEFAULT 0)
    RETURN VARCHAR2 IS
    VRET VARCHAR2(1) := 'N';
    VTIPOTRANSF VARCHAR2(2);
    
    VLOG PCLOGTRANSFNFCARREG%ROWTYPE;
    TYPE TCARREGAMENTO IS RECORD(
       ORIGEM VARCHAR2(60),
       DESTINO VARCHAR2(60),
       DIFERENTES VARCHAR2(60));
    CARREGAMENTOS TCARREGAMENTO;
    
    TYPE TRECTRANSACAO IS RECORD(
       NUMTRANSVENDA PCNFSAID.NUMTRANSVENDA%TYPE,
       NUMNOTA PCNFSAID.NUMNOTA%TYPE,
       CODFILIAL PCMOV.CODFILIAL%TYPE,
       CODFILIALNF PCMOV.CODFILIALNF%TYPE,
       CODFILIALRETIRA PCMOV.CODFILIALRETIRA%TYPE,
       NUMPED PCNFSAID.NUMPED%TYPE);
    TYPE TTRANSACAO IS TABLE OF TRECTRANSACAO INDEX BY BINARY_INTEGER;
    TRANSACOES TTRANSACAO;
        
    PROCEDURE GRAVARLOG(PPARAMS IN OUT PCLOGTRANSFNFCARREG%ROWTYPE)
    IS
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      PPARAMS.CODFUNCTRANSF := PCODFUNCTRANSF;
      PPARAMS.NUMCARANTERIOR := PNUMCARORIGEM;
      PPARAMS.NUMCARATUAL := PNUMCARDESTINO;
      PPARAMS.DTTRANSF := SYSDATE;
      PPARAMS.CODMOTIVO := PCODMOTIVO;
      PPARAMS.MOTIVOTRANSF := PMOTIVOTRANSF;
      PPARAMS.MAQUINA := ('TRANSF_CARREGAMENTO:'||SYS_CONTEXT('USERENV', 'MODULE'));
      INSERT INTO PCLOGTRANSFNFCARREG VALUES PPARAMS;
      COMMIT;
    END;  
  BEGIN
    PMSGRETORNO := 'OK';   
    BEGIN
      SELECT NVL((SELECT 'S'
                    FROM PCCARREG
                   WHERE NUMCAR = PNUMCARORIGEM), ('CARREGAMENTO DE ORIGEM: '||PNUMCARORIGEM||' INEXISTENTE.')) ORIGEM
           , NVL((SELECT 'S'
                    FROM PCCARREG
                   WHERE NUMCAR = PNUMCARDESTINO), ('CARREGAMENTO DESTINO: '||PNUMCARDESTINO||' INEXISTENTE.')) DESTINO
           , DECODE(NVL(PNUMCARORIGEM, 0), NVL(PNUMCARDESTINO, 0), 'CARREGAMENTO DE ORIGEM E DESTINO DEVE SER DIFERENTES.', 'S') DIFERENTES
      INTO CARREGAMENTOS.ORIGEM
         , CARREGAMENTOS.DESTINO
         , CARREGAMENTOS.DIFERENTES
      FROM DUAL;
      
      SELECT NOTAS.*
        BULK COLLECT INTO TRANSACOES
        FROM (SELECT DISTINCT S.NUMTRANSVENDA
                            , S.NUMNOTA
                            , M.CODFILIAL
                            , M.CODFILIALNF
                            , M.CODFILIALRETIRA
                            , S.NUMPED
                         FROM PCNFSAID S
                            , PCMOV M
                        WHERE S.NUMCAR = PNUMCARORIGEM
                          AND (NVL(PNUMPED, 0) = 0 OR S.NUMPED = PNUMPED)
                          AND (NVL(PNUMTRANSVENDA, 0) = 0 OR S.NUMTRANSVENDA = PNUMTRANSVENDA)
                          AND S.NUMTRANSVENDA = M.NUMTRANSVENDA
                          AND S.CODFILIAL = M.CODFILIAL
                          AND VENDAS.TIPO_TRANSFERENCIA(M.CODFILIAL
                                                      , M.CODFILIALRETIRA
                                                      , M.CODFILIALNF) IN('V', 'R', 'VR')
              UNION
              SELECT DISTINCT S.NUMTRANSVENDA
                            , S.NUMNOTA
                            , S.CODFILIAL
                            , S.CODFILIALNF
                            , M.CODFILIALRETIRA
                            , S.NUMPED
                         FROM PCPEDC S
                            , PCPEDI M
                        WHERE S.NUMCAR = PNUMCARORIGEM
                          AND S.POSICAO NOT IN ('F', 'C')
                          AND (NVL(PNUMPED, 0) = 0 OR S.NUMPED = PNUMPED)
                          AND S.NUMPED = M.NUMPED
                          AND VENDAS.TIPO_TRANSFERENCIA(S.CODFILIAL
                                                      , M.CODFILIALRETIRA
                                                      , S.CODFILIALNF) IN('V', 'R', 'VR')
              UNION
              SELECT DISTINCT S.NUMTRANSVENDA
                            , S.NUMNOTA
                            , M.CODFILIAL
                            , M.CODFILIALNF
                            , M.CODFILIALRETIRA
                            , S.NUMPED
                         FROM PCNFSAIDPREFAT S
                            , PCMOVPREFAT M
                        WHERE S.NUMCAR = PNUMCARORIGEM
                          AND (NVL(PNUMPED, 0) = 0 OR S.NUMPED = PNUMPED)
                          AND (NVL(PNUMTRANSVENDA, 0) = 0 OR S.NUMTRANSVENDA = PNUMTRANSVENDA)
                          AND S.NUMTRANSVENDA = M.NUMTRANSVENDA
                          AND S.CODFILIAL = M.CODFILIAL
                          AND VENDAS.TIPO_TRANSFERENCIA(M.CODFILIAL
                                                      , M.CODFILIALRETIRA
                                                      , M.CODFILIALNF) IN('V', 'R', 'VR')) NOTAS;
                             
      IF TRANSACOES.COUNT > 0 THEN                          
        FOR NOTA IN TRANSACOES.FIRST..TRANSACOES.LAST                                                 
        LOOP
           VTIPOTRANSF := VENDAS.TIPO_TRANSFERENCIA(TRANSACOES(NOTA).CODFILIAL
                                                  , TRANSACOES(NOTA).CODFILIALRETIRA
                                                  , TRANSACOES(NOTA).CODFILIALNF);
           IF (VTIPOTRANSF IN('V', 'VR')) THEN 
              VRET := 'S';
               
              UPDATE PCTRANSFVIRT
                 SET NUMCAR = PNUMCARDESTINO
               WHERE NUMCAR = PNUMCARORIGEM
                 AND NUMPED = TRANSACOES(NOTA).NUMPED;
                
              UPDATE PCTRANSFVIRTDEV
                 SET NUMCAR = PNUMCARDESTINO
               WHERE NUMCAR = PNUMCARORIGEM
                 AND NUMTRANSVENDAFAT = TRANSACOES(NOTA).NUMTRANSVENDA;
               
              UPDATE PCTRANSFVIRTFAT
                 SET NUMCAR = PNUMCARDESTINO
               WHERE NUMCAR = PNUMCARORIGEM
                 AND NUMTRANSVENDAFAT = TRANSACOES(NOTA).NUMTRANSVENDA;               
               
              VLOG.NUMPED := TRANSACOES(NOTA).NUMPED;
              VLOG.NUMNOTA := TRANSACOES(NOTA).NUMNOTA;
              VLOG.NUMTRANSVENDA := TRANSACOES(NOTA).NUMTRANSVENDA;
              GRAVARLOG(VLOG);
           ELSE
             VRET := 'S';
           END IF; 
        END LOOP;
      ELSE       
        VRET := 'S';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        PMSGRETORNO := 'EXCEÇÃO AO ATUALIZAR O CARREGAMENTO: ' || SQLERRM;
        VRET := 'N';
    END;

    RETURN VRET;
  END;  
  
  FUNCTION SINC_INFOXML_SAIDA_ENTRADA(pNumtransvenda IN pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2 IS    
  BEGIN
    RETURN FERRAMENTAS_DOCFISCAL.SINC_INFOXML_SAIDA_ENTRADA(pNumtransvenda, pMensagemRetorno);
  END;  
  
  PROCEDURE GRAVARLOG(PPARAMS    IN OUT PCPARAMFAT%ROWTYPE,
                      PSLINHAMSG IN VARCHAR2 DEFAULT '') IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    VSLINHAERRO VARCHAR2(400);
  BEGIN
  
    IF PPARAMS.NUMCAR IS NULL THEN
      PPARAMS.NUMCAR := 0;
    END IF;
  
    IF NVL(PPARAMS.NUMPED, 0) = 0 THEN
      PPARAMS.SEQ := 0;
    ELSE
      -- Tarefa: 2600.006951.2013
      SELECT DEFSEQ_PCPARAMFAT.NEXTVAL INTO PPARAMS.SEQ FROM DUAL;
    END IF;
  
    -- Deyvid Costa - Sprint 26.02
    VSLINHAERRO := '';
    if PPARAMS.msg like '%ORA-%' THEN
      -- Verifica se Ã© mensagem com erro
      VSLINHAERRO := PSLINHAMSG;
    END IF;
  
    -- Adicionar nÃºmero da linha, quando for erro ou quando for apenas uma mensagem informativa
    PPARAMS.msg := PPARAMS.Msg || CHR(13) || CASE
                     WHEN VSLINHAERRO <> '' THEN
                      ' ERRO: ' || VSLINHAERRO
                     WHEN PSLINHAMSG <> '' THEN
                      ' LINHA MSG: ' || PSLINHAMSG
                     ELSE
                      ' LINHA: ' || PSLINHAMSG
                   END;
    -- Sprint 26.02
  
    INSERT INTO PCPARAMFAT VALUES PPARAMS;
  
    COMMIT;
  
  END GRAVARLOG;  

END FERRAMENTAS_FATURAMENTO;