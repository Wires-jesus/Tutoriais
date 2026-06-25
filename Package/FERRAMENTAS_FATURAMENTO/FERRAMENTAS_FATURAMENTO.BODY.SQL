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

  PROCEDURE CALCULAR_VITEM(PNUMTRANSVENDA in PCMOV.NUMTRANSVENDA%TYPE) IS
  BEGIN
  
    BEGIN
      FOR DADOS IN (SELECT NUM_TRANSACAO,
                           NUMSEQ,
                           CODPROD,
                           NUMTRANSITEM,
                           QTCONT,
                           VALOR_LIQUIDO,
                           ROUND(DECODE(NVL(VALOR_LIQUIDO, 0), 0, 0, QTCONT) *
                                 VALOR_LIQUIDO,
                                 2) AS VALOR_PRODUTO,
                           (VALOR_DESCONTO / QTCONT) AS VALOR_DESCONTO,
                           VALOR_OUTROS
                    
                      FROM (SELECT PCMOV.NUMTRANSVENDA AS NUM_TRANSACAO,
                                   PCMOV.CODPROD,
                                   PCMOV.NUMSEQ,
                                   PCMOV.NUMTRANSITEM,
                                   PCMOV.QTCONT,
                                   (DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'),
                                           'C',
                                           DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                                                  'S',
                                                  PCMOV.PBONIFIC,
                                                  PCMOV.PUNITCONT),
                                           --não subtotaliza se não tiver impostos agregados ao valor do produto
                                           CASE
                                             WHEN (((NVL(PCMOV.VLIPI, 0) +
                                                  NVL(PCMOV.ST, 0) +
                                                  NVL(PCMOVCOMPLE.VLFECP, 0) +
                                                  NVL(PCMOVCOMPLE.VLDESCONTONF, 0)) > 0) AND
                                                  (NVL(PCMOV.CODOPER, 'S') <> 'SD')) THEN
                                              ((ROUND((DECODE(NVL(PCMOVCOMPLE.BONIFIC,
                                                                  'N'),
                                                              'S',
                                                              PCMOV.PBONIFIC,
                                                              PCMOV.PUNITCONT) -
                                                      NVL(PCMOV.VLIPI, 0) -
                                                      NVL(PCMOV.ST, 0) -
                                                      DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST,
                                                                  0),
                                                              0,
                                                              0,
                                                              NVL(PCMOVCOMPLE.VLFECP, 0))) *
                                                      PCMOV. QTCONT,
                                                      (CASE
                                                        WHEN PCMOV.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOV.QTCONT +
                                              (ROUND(NVL(PCMOV.VLIPI, 0) *
                                                      PCMOV.QTCONT,
                                                      (CASE
                                                        WHEN PCMOV.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOV.QTCONT +
                                              (ROUND(NVL(PCMOV.ST, 0) * PCMOV.QTCONT,
                                                      (CASE
                                                        WHEN PCMOV.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOV.QTCONT +
                                              (ROUND(DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST,
                                                                 0),
                                                             0,
                                                             0,
                                                             NVL(PCMOVCOMPLE.VLFECP, 0)) *
                                                      PCMOV.QTCONT,
                                                      (CASE
                                                        WHEN PCMOV.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOV.QTCONT)
                                             ELSE
                                              DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                                                     'S',
                                                     PCMOV.PBONIFIC,
                                                     PCMOV.PUNITCONT)
                                           END) - CASE
                                     WHEN (PCMOV.CODOPER = 'SD' AND
                                          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',
                                                                             PCFILIAL.CODIGO),
                                               'S') = 'N') THEN
                                      0
                                     ELSE
                                      DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'),
                                             'C',
                                             NVL(PCMOV.ST, 0),
                                             DECODE(PCMOV.CODOPER,
                                                    'SD',
                                                    NVL(PCMOV.ST, 0),
                                                    ((ROUND(NVL(PCMOV.ST, 0) *
                                                            PCMOV.QTCONT,
                                                            NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                2))) /
                                                    PCMOV.QTCONT)))
                                   END - (DECODE(PCNFSAID.TIPOVENDA,
                                                  'DF',
                                                  NVL(PCMOV.VLSEGURO, 0),
                                                  0)) -
                                   (DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0),
                                            0,
                                            0,
                                            DECODE(NVL(PCNFSAID.FINALIDADENFE,
                                                       'N'),
                                                   'C',
                                                   PCMOVCOMPLE.VLFECP,
                                                   (ROUND(NVL(PCMOVCOMPLE.VLFECP,
                                                              0) * QTCONT,
                                                          NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                              2)) / QTCONT)))) -
                                   NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR, 0) - CASE
                                     WHEN (PCMOV.CODOPER = 'SD' AND
                                          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                                             PCFILIAL.CODIGO),
                                               'N') = 'S') THEN
                                      0
                                     ELSE
                                      DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'),
                                             'C',
                                             NVL(PCMOV.VLIPI, 0),
                                             ((ROUND(NVL(PCMOV.VLIPI, 0) *
                                                     PCMOV.QTCONT,
                                                     NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                         2))) / PCMOV.QTCONT))
                                   END -
                                   --Na nfe 4.0 o ipiDevol compoe o valor total da nota, e por isso deve ser subtraido do valor do produto
                                   CASE
                                     WHEN (PCMOV.CODOPER = 'SD') THEN
                                      (NVL(PCMOV.VLDESPDENTRONF, 0) -
                                      DECODE(NVL(PCMOVCOMPLE.VLIPIDEVFORNEC,
                                                  0),
                                              0,
                                              0,
                                              NVL(PCMOVCOMPLE.VLIPIOUTRAS, 0))) +
                                      NVL(PCMOVCOMPLE.VLIPIDEVFORNEC, 0)
                                     ELSE
                                      0
                                   END - DECODE(PCMOV.CODOPER,
                                                 'SD',
                                                 NVL(PCMOV.VLFRETE, 0),
                                                 0) +
                                   NVL(PCMOV.VLDESCPISSUFRAMA, 0) +
                                   DECODE(PCMOV.CODOPER,
                                           'SD',
                                           0,
                                           ROUND(NVL(PCMOV.VLDESCSUFRAMA, 0) *
                                                 PCMOV.QTCONT,
                                                 NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                     2)) / PCMOV.QTCONT) +
                                   DECODE(PCMOV.CODOPER,
                                           'SD',
                                           0,
                                           NVL(PCMOV.VLSUFRAMA, 0))) +
                                   DECODE(PCMOV.CODOPER,
                                          'SD',
                                          0,
                                          DECODE(NVL(PCNFSAID.DEDUZIRDESONERORGAOPUB,
                                                     'N'),
                                                 'S',
                                                 0,
                                                 ROUND(NVL(PCMOV.VLDESCICMISENCAO,
                                                           0) * PCMOV.QTCONT,
                                                       NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                           2)) / PCMOV.QTCONT)) + CASE
                                     WHEN ((PCMOV.CODOPER = 'SD') AND
                                          (NVL(PCMOVCOMPLE.PERCICMSDESONERACAO,
                                                0) > 0) AND
                                          (NVL(PCMOVCOMPLE.VLICMSDESONERACAO,
                                                0) > 0)) THEN
                                      PCMOVCOMPLE.VLICMSDESONERACAO
                                     ELSE
                                      0
                                   END + CASE
                                     WHEN ((CASE
                                            WHEN NVL(PCCLIENT.TIPOCLIMED, 'X') IN
                                                 ('D', 'E', 'M') AND
                                                 (NVL(PCPEDC.ROTINA, 'X') =
                                                  'PCMED316') THEN
                                             'S'
                                            ELSE
                                             'N'
                                          END) = 'S') THEN
                                      0
                                     ELSE
                                      DECODE(PCMOV.CODOPER,
                                             'SD',
                                             -- Saida de Devolução
                                             (NVL(PCMOV.VLDESCONTO, 0) +
                                             NVL(NVL(PCMOV.VLDESCSUFRAMA,
                                                      PCMOV.VLSUFRAMA),
                                                  0)),
                                             -- Normal
                                             CASE
                                                WHEN (PCNFSAID.CONDVENDA = 4 OR
                                                     NVL(PCNFSAID.NUMCUPOM, 0) > 0) THEN
                                                
                                                 DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,
                                                            NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                               'N'),
                                                                           'N',
                                                                           '',
                                                                           PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                    PCCLIENT.PRECOUTILIZADONFE),
                                                                NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                  PCFILIAL.CODIGO),
                                                                    'L'))),
                                                        'L',
                                                        (NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) +
                                                        NVL(PCMOV.VLDESCREDUCAOPIS, 0)),
                                                        'LR',
                                                        0,
                                                        NVL(PCMOVCOMPLE.VLSUBTOTDESCONTO,
                                                            0))
                                                ELSE
                                                 (DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,
                                                             NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                                'N'),
                                                                            'N',
                                                                            '',
                                                                            PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                     PCCLIENT.PRECOUTILIZADONFE),
                                                                 NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                   PCFILIAL.CODIGO),
                                                                     'L'))),
                                                         'L',
                                                         0,
                                                         'LR',
                                                         NVL(ABS(PCMOV.VLREPASSE), 0),
                                                         DECODE(NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                    0),
                                                                0,
                                                                (ROUND(PCMOV.QTCONT *
                                                                       (DECODE((NVL(PCMOV.PTABELA,
                                                                                    0) -
                                                                               NVL(PCMOV.VLREPASSE,
                                                                                    0)),
                                                                               0,
                                                                               0,
                                                                               DECODE(SIGN((NVL(PCMOV.PTABELA,
                                                                                                0) -
                                                                                           NVL(PCMOV.VLREPASSE,
                                                                                                0)) -
                                                                                           DECODE(PCMOVCOMPLE.BONIFIC,
                                                                                                  'S',
                                                                                                  PCMOV.PBONIFIC,
                                                                                                  PCMOV.PUNITCONT)),
                                                                                      -1,
                                                                                      0,
                                                                                      (NVL(PCMOV.PTABELA,
                                                                                           0) -
                                                                                      NVL(PCMOV.VLREPASSE,
                                                                                           0)) -
                                                                                      
                                                                                      NVL(DECODE(PCMOVCOMPLE.BONIFIC,
                                                                                                 'S',
                                                                                                 PCMOV.PBONIFIC,
                                                                                                 PCMOV.PUNITCONT),
                                                                                          0)))),
                                                                       NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                           2)) /
                                                                PCMOV.QTCONT),
                                                                
                                                                (ROUND(PCMOV.QTCONT *
                                                                       (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                                    0) -
                                                                               NVL(PCMOV.VLREPASSE,
                                                                                    0)),
                                                                               0,
                                                                               0,
                                                                               DECODE(SIGN(NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                                               0) -
                                                                                           NVL(PCMOV.VLREPASSE,
                                                                                               0)),
                                                                                      -1,
                                                                                      0,
                                                                                      NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                                          0) -
                                                                                      NVL(PCMOV.VLREPASSE,
                                                                                          0)))),
                                                                       NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                           2)) /
                                                                PCMOV.QTCONT)) +
                                                         (NVL(PCMOV.VLDESCPISSUFRAMA, 0)))) + (
                                                 --Melhoria HIS.04338.2015 - Eddy
                                                  CASE
                                                    WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE',
                                                                                         PCFILIAL.CODIGO) = 'N') AND
                                                         ((PCCLIENT.SULFRAMA IS NOT NULL) AND
                                                         (PCCLIENT.DTVENCSUFRAMA >
                                                         PCNFSAID.DTSAIDA))) THEN
                                                     0
                                                    ELSE
                                                     (ROUND((NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) +
                                                            NVL(PCMOV.VLDESCREDUCAOPIS, 0)) *
                                                            PCMOV.QTCONT,
                                                            NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                2)) / PCMOV.QTCONT)
                                                  END)
                                              END +
                                             --utilizado somente para equipe de medicamentos
                                              (CASE
                                                WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                   PCFILIAL.CODIGO) = 'L' THEN
                                                 NVL(PCMOVCOMPLE.VLDESCCOMERCIALICMISENCAO,
                                                     0)
                                                ELSE
                                                 0
                                              END))
                                   END AS VALOR_LIQUIDO,
                                   CASE
                                     WHEN ((CASE
                                            WHEN NVL(PCCLIENT.TIPOCLIMED, 'X') IN
                                                 ('D', 'E', 'M') AND
                                                 (NVL(PCPEDC.ROTINA, 'X') =
                                                  'PCMED316') THEN
                                             'S'
                                            ELSE
                                             'N'
                                          END) = 'S') THEN
                                      0
                                     ELSE
                                      DECODE(PCMOV.CODOPER,
                                             'SD',
                                             -- Saida de Devolução
                                             ROUND(((ROUND(NVL(PCMOV.VLDESCONTO,
                                                               0) *
                                                           PCMOV.QTCONT,
                                                           2) / PCMOV.QTCONT) +
                                                   NVL(NVL(PCMOV.VLDESCSUFRAMA,
                                                            PCMOV.VLSUFRAMA),
                                                        0)) * PCMOV.QTCONT,
                                                   2),
                                             -- Normal
                                             CASE
                                                WHEN (PCNFSAID.CONDVENDA = 4 OR
                                                     NVL(PCNFSAID.NUMCUPOM, 0) > 0) THEN
                                                 ROUND((DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,
                                                                   NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                                      'N'),
                                                                                  'N',
                                                                                  '',
                                                                                  PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                           PCCLIENT.PRECOUTILIZADONFE),
                                                                       NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                         PCFILIAL.CODIGO),
                                                                           'L'))),
                                                               'L',
                                                               (NVL(PCMOV.VLDESCREDUCAOCOFINS,
                                                                    0) +
                                                               NVL(PCMOV.VLDESCREDUCAOPIS,
                                                                    0)),
                                                               'LR',
                                                               0,
                                                               NVL(PCMOVCOMPLE.VLSUBTOTDESCONTO,
                                                                   0)) * PCMOV.QTCONT),
                                                       2)
                                                ELSE
                                                 ROUND((DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,
                                                                   NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                                      'N'),
                                                                                  'N',
                                                                                  '',
                                                                                  PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                           PCCLIENT.PRECOUTILIZADONFE),
                                                                       NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                         PCFILIAL.CODIGO),
                                                                           'L'))),
                                                               'L',
                                                               0,
                                                               'LR',
                                                               NVL(ABS(PCMOV.VLREPASSE), 0),
                                                               DECODE(NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                          0),
                                                                      0,
                                                                      (ROUND(PCMOV.QTCONT *
                                                                             (DECODE((NVL(PCMOV.PTABELA,
                                                                                          0) -
                                                                                     NVL(PCMOV.VLREPASSE,
                                                                                          0)),
                                                                                     0,
                                                                                     0,
                                                                                     DECODE(SIGN((NVL(PCMOV.PTABELA,
                                                                                                      0) -
                                                                                                 NVL(PCMOV.VLREPASSE,
                                                                                                      0)) -
                                                                                                 DECODE(PCMOVCOMPLE.BONIFIC,
                                                                                                        'S',
                                                                                                        PCMOV.PBONIFIC,
                                                                                                        PCMOV.PUNITCONT)),
                                                                                            -1,
                                                                                            0,
                                                                                            (NVL(PCMOV.PTABELA,
                                                                                                 0) -
                                                                                            NVL(PCMOV.VLREPASSE,
                                                                                                 0)) -
                                                                                            NVL(DECODE(PCMOVCOMPLE.BONIFIC,
                                                                                                       'S',
                                                                                                       PCMOV.PBONIFIC,
                                                                                                       PCMOV.PUNITCONT),
                                                                                                0)))),
                                                                             2) /
                                                                      PCMOV.QTCONT),
                                                                      (GREATEST((ROUND(PCMOV.QTCONT *
                                                                                       (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                                                    0) -
                                                                                               NVL(PCMOV.VLREPASSE,
                                                                                                    0)),
                                                                                               0,
                                                                                               0,
                                                                                               DECODE(SIGN((NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                                                                0) -
                                                                                                           NVL(PCMOV.VLREPASSE,
                                                                                                                0))),
                                                                                                      -1,
                                                                                                      0,
                                                                                                      (NVL(PCMOVCOMPLE.VLDESCONTONF,
                                                                                                           0) -
                                                                                                      NVL(PCMOV.VLREPASSE,
                                                                                                           0))))),
                                                                                       2) /
                                                                                PCMOV.QTCONT)
                                                                                
                                                                               ,
                                                                                0)))) +
                                                       (NVL(PCMOV.VLDESCPISSUFRAMA, 0) + CASE
                                                         WHEN (PCMOVCOMPLE.CODMOTIVOICMSDESONERADO IN
                                                              ('7', '8')) THEN
                                                          0
                                                         ELSE
                                                          NVL(NVL(PCMOV.VLDESCSUFRAMA,
                                                                  PCMOV.VLSUFRAMA),
                                                              0)
                                                       END)) * PCMOV.QTCONT,
                                                       2)
                                              END + ROUND(((
                                                          --Melhoria HIS.04338.2015 - Eddy
                                                          CASE
                                                            WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE',
                                                                                                 PCFILIAL.CODIGO) = 'N') AND
                                                                 ((PCCLIENT.SULFRAMA IS NOT NULL) AND
                                                                 (PCCLIENT.DTVENCSUFRAMA >
                                                                 PCNFSAID.DTSAIDA))) THEN
                                                             0
                                                            ELSE
                                                             CASE
                                                               WHEN (PCNFSAID.CONDVENDA = 4 OR
                                                                    NVL(PCNFSAID.NUMCUPOM, 0) > 0) THEN
                                                                0
                                                               ELSE
                                                                (NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) +
                                                                NVL(PCMOV.VLDESCREDUCAOPIS, 0))
                                                             END
                                                          END)) * QTCONT,
                                                          2) +
                                             --utilizado somente para equipe de medicamentos
                                              ROUND((CASE
                                                      WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                         PCFILIAL.CODIGO) = 'L' THEN
                                                       NVL(PCMOVCOMPLE.VLDESCCOMERCIALICMISENCAO,
                                                           0)
                                                      ELSE
                                                       0
                                                    END) * PCMOV.QTCONT,
                                                    2))
                                   END AS VALOR_DESCONTO,
                                   ROUND((DECODE(PCMOV.CODOPER,
                                                 'SD',
                                                 NVL(PCMOV.VLDESPDENTRONF, 0) -
                                                 DECODE(NVL(PCMOVCOMPLE.VLIPIDEVFORNEC,
                                                            0),
                                                        0,
                                                        0,
                                                        NVL(PCMOVCOMPLE.VLIPIOUTRAS,
                                                            0)),
                                                 NVL(PCMOV.VLOUTROS, 0) -
                                                 NVL(PCMOV.VLSEGURO, 0))) *
                                         QTCONT,
                                         2) AS VALOR_OUTROS
                              FROM PCMOV,
                                   PCMOVCOMPLE,
                                   PCMOVIMPOSTOS,
                                   PCFILIAL,
                                   PCPEDC,
                                   PCNFSAID,
                                   PCCLIENT,
                                   PCPRODFILIAL
                             WHERE PCMOV.NUMTRANSITEM =
                                   PCMOVCOMPLE.NUMTRANSITEM(+)
                               AND PCNFSAID.NUMTRANSVENDA =
                                   PCMOV.NUMTRANSVENDA
                               AND PCNFSAID.NUMNOTA = PCMOV.NUMNOTA
                               AND NVL(PCNFSAID.CODCLINF, PCNFSAID.CODCLI) =
                                   PCCLIENT.CODCLI(+)
                               AND PCMOV.NUMTRANSVENDA =
                                   PCMOVIMPOSTOS.NUMTRANSVENDA(+)
                               AND PCMOV.CODPROD = PCMOVIMPOSTOS.CODPROD(+)
                               AND PCMOV.NUMSEQ = PCMOVIMPOSTOS.NUMSEQ(+)
                               AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) =
                                   PCFILIAL.CODIGO
                               AND PCMOV.NUMPED = PCPEDC.NUMPED(+)
                               AND PCMOV.CODPROD = PCPRODFILIAL.CODPROD(+)
                               AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) =
                                   PCPRODFILIAL.CODFILIAL(+)
                               AND NVL(PCMOV.QTCONT, 0) > 0
                                  
                               AND PCMOV.NUMTRANSVENDA = PNUMTRANSVENDA)
                    
                    UNION ALL
                    
                    SELECT NUM_TRANSACAO,
                           NUMSEQ,
                           CODPROD,
                           NUMTRANSITEM,
                           QTCONT,
                           VALOR_LIQUIDO,
                           ROUND(DECODE(NVL(VALOR_LIQUIDO, 0), 0, 0, QTCONT) *
                                 VALOR_LIQUIDO,
                                 2) AS VALOR_PRODUTOS,
                           (VALOR_DESCONTO / QTCONT) AS VALOR_DESCONTO,
                           VALOR_OUTROS
                    
                      FROM (SELECT PCMOVPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO,
                                   PCMOVPREFAT.CODPROD,
                                   PCMOVPREFAT.NUMSEQ,
                                   PCMOVPREFAT.NUMTRANSITEM,
                                   PCMOVPREFAT.QTCONT,
                                   (DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE,
                                               'N'),
                                           'C',
                                           DECODE(NVL(PCMOVCOMPLEPREFAT.BONIFIC,
                                                      'N'),
                                                  'S',
                                                  PCMOVPREFAT.PBONIFIC,
                                                  PCMOVPREFAT.PUNITCONT),
                                           --não subtotaliza se não tiver impostos agregados ao valor do produto
                                           CASE
                                             WHEN (((NVL(PCMOVPREFAT.VLIPI, 0) +
                                                  NVL(PCMOVPREFAT.ST, 0) +
                                                  NVL(PCMOVCOMPLEPREFAT.VLFECP, 0) +
                                                  NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                         0)) > 0) AND
                                                  (NVL(PCMOVPREFAT.CODOPER, 'S') <> 'SD')) THEN
                                              ((ROUND((DECODE(NVL(PCMOVCOMPLEPREFAT.BONIFIC,
                                                                  'N'),
                                                              'S',
                                                              PCMOVPREFAT.PBONIFIC,
                                                              PCMOVPREFAT.PUNITCONT) -
                                                      NVL(PCMOVPREFAT.VLIPI, 0) -
                                                      NVL(PCMOVPREFAT.ST, 0) -
                                                      DECODE(NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST,
                                                                  0),
                                                              0,
                                                              0,
                                                              NVL(PCMOVCOMPLEPREFAT.VLFECP,
                                                                  0))) * PCMOVPREFAT.
                                                      QTCONT,
                                                      (CASE
                                                        WHEN PCMOVPREFAT.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOVPREFAT.QTCONT +
                                              (ROUND(NVL(PCMOVPREFAT.VLIPI, 0) *
                                                      PCMOVPREFAT.QTCONT,
                                                      (CASE
                                                        WHEN PCMOVPREFAT.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOVPREFAT.QTCONT +
                                              (ROUND(NVL(PCMOVPREFAT.ST, 0) *
                                                      PCMOVPREFAT.QTCONT,
                                                      (CASE
                                                        WHEN PCMOVPREFAT.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOVPREFAT.QTCONT +
                                              (ROUND(DECODE(NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST,
                                                                 0),
                                                             0,
                                                             0,
                                                             NVL(PCMOVCOMPLEPREFAT.VLFECP,
                                                                 0)) *
                                                      PCMOVPREFAT.QTCONT,
                                                      (CASE
                                                        WHEN PCMOVPREFAT.QTCONT < 1 THEN
                                                         6
                                                        ELSE
                                                         NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                             2)
                                                      END))) / PCMOVPREFAT.QTCONT)
                                             ELSE
                                              DECODE(NVL(PCMOVCOMPLEPREFAT.BONIFIC,
                                                         'N'),
                                                     'S',
                                                     PCMOVPREFAT.PBONIFIC,
                                                     PCMOVPREFAT.PUNITCONT)
                                           END) - CASE
                                     WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                                          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',
                                                                             PCFILIAL.CODIGO),
                                               'S') = 'N') THEN
                                      0
                                     ELSE
                                      DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE,
                                                 'N'),
                                             'C',
                                             NVL(PCMOVPREFAT.ST, 0),
                                             DECODE(PCMOVPREFAT.CODOPER,
                                                    'SD',
                                                    NVL(PCMOVPREFAT.ST, 0),
                                                    ((ROUND(NVL(PCMOVPREFAT.ST,
                                                                0) *
                                                            PCMOVPREFAT.QTCONT,
                                                            NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                2))) /
                                                    PCMOVPREFAT.QTCONT)))
                                   END - (DECODE(PCNFSAIDPREFAT.TIPOVENDA,
                                                  'DF',
                                                  NVL(PCMOVPREFAT.VLSEGURO, 0),
                                                  0)) -
                                   (DECODE(NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST,
                                                0),
                                            0,
                                            0,
                                            DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE,
                                                       'N'),
                                                   'C',
                                                   PCMOVCOMPLEPREFAT.VLFECP,
                                                   (ROUND(NVL(PCMOVCOMPLEPREFAT.VLFECP,
                                                              0) *
                                                          PCMOVPREFAT.QTCONT,
                                                          NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                              2)) /
                                                   PCMOVPREFAT.QTCONT)))) -
                                   NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR, 0) - CASE
                                     WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                                          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                                             PCFILIAL.CODIGO),
                                               'N') = 'S') THEN
                                      0
                                     ELSE
                                      DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE,
                                                 'N'),
                                             'C',
                                             NVL(PCMOVPREFAT.VLIPI, 0),
                                             ((ROUND(NVL(PCMOVPREFAT.VLIPI, 0) *
                                                     PCMOVPREFAT.QTCONT,
                                                     NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                         2))) /
                                             PCMOVPREFAT.QTCONT))
                                   END -
                                   --Na nfe 4.0 o ipiDevol compoe o valor total da nota, e por isso deve ser subtraido do valor do produto
                                   CASE
                                     WHEN (PCMOVPREFAT.CODOPER = 'SD') THEN
                                      (NVL(PCMOVPREFAT.VLDESPDENTRONF, 0) -
                                      DECODE(NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC,
                                                  0),
                                              0,
                                              0,
                                              NVL(PCMOVCOMPLEPREFAT.VLIPIOUTRAS,
                                                  0))) +
                                      NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC, 0)
                                     ELSE
                                      0
                                   END - DECODE(PCMOVPREFAT.CODOPER,
                                                 'SD',
                                                 NVL(PCMOVPREFAT.VLFRETE, 0),
                                                 0) +
                                   NVL(PCMOVPREFAT.VLDESCPISSUFRAMA, 0) +
                                   DECODE(PCMOVPREFAT.CODOPER,
                                           'SD',
                                           0,
                                           ROUND(NVL(PCMOVPREFAT.VLDESCSUFRAMA,
                                                     0) * PCMOVPREFAT.QTCONT,
                                                 NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                     2)) / PCMOVPREFAT.QTCONT) +
                                   DECODE(PCMOVPREFAT.CODOPER,
                                           'SD',
                                           0,
                                           NVL(PCMOVPREFAT.VLSUFRAMA, 0))) +
                                   DECODE(PCMOVPREFAT.CODOPER,
                                          'SD',
                                          0,
                                          DECODE(NVL(PCNFSAIDPREFAT.DEDUZIRDESONERORGAOPUB,
                                                     'N'),
                                                 'S',
                                                 0,
                                                 ROUND(NVL(PCMOVPREFAT.VLDESCICMISENCAO,
                                                           0) *
                                                       PCMOVPREFAT.QTCONT,
                                                       NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                           2)) /
                                                 PCMOVPREFAT.QTCONT)) + CASE
                                     WHEN ((PCMOVPREFAT.CODOPER = 'SD') AND
                                          (NVL(PCMOVCOMPLEPREFAT.PERCICMSDESONERACAO,
                                                0) > 0) AND
                                          (NVL(PCMOVCOMPLEPREFAT.VLICMSDESONERACAO,
                                                0) > 0)) THEN
                                      PCMOVCOMPLEPREFAT.VLICMSDESONERACAO
                                     ELSE
                                      0
                                   END + CASE
                                     WHEN ((CASE
                                            WHEN NVL(PCCLIENT.TIPOCLIMED, 'X') IN
                                                 ('D', 'E', 'M') AND
                                                 (NVL(PCPEDC.ROTINA, 'X') =
                                                  'PCMED316') THEN
                                             'S'
                                            ELSE
                                             'N'
                                          END) = 'S') THEN
                                      0
                                     ELSE
                                      DECODE(PCMOVPREFAT.CODOPER,
                                             'SD',
                                             -- Saida de Devolução
                                             (NVL(PCMOVPREFAT.VLDESCONTO, 0) +
                                             NVL(NVL(PCMOVPREFAT.VLDESCSUFRAMA,
                                                      PCMOVPREFAT.VLSUFRAMA),
                                                  0)),
                                             -- Normal
                                             CASE
                                                WHEN (PCNFSAIDPREFAT.CONDVENDA = 4 OR
                                                     NVL(PCNFSAIDPREFAT.NUMCUPOM, 0) > 0) THEN
                                                
                                                 DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,
                                                            NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                               'N'),
                                                                           'N',
                                                                           '',
                                                                           PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                    PCCLIENT.PRECOUTILIZADONFE),
                                                                NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                  PCFILIAL.CODIGO),
                                                                    'L'))),
                                                        'L',
                                                        (NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,
                                                             0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS,
                                                                       0)),
                                                        'LR',
                                                        0,
                                                        NVL(PCMOVCOMPLEPREFAT.VLSUBTOTDESCONTO,
                                                            0))
                                                ELSE
                                                 (DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,
                                                             NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                                'N'),
                                                                            'N',
                                                                            '',
                                                                            PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                     PCCLIENT.PRECOUTILIZADONFE),
                                                                 NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                   PCFILIAL.CODIGO),
                                                                     'L'))),
                                                         'L',
                                                         0,
                                                         'LR',
                                                         NVL(ABS(PCMOVPREFAT.VLREPASSE), 0),
                                                         DECODE(NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                    0),
                                                                0,
                                                                (ROUND(PCMOVPREFAT.QTCONT *
                                                                       (DECODE((NVL(PCMOVPREFAT.PTABELA,
                                                                                    0) -
                                                                               NVL(PCMOVPREFAT.VLREPASSE,
                                                                                    0)),
                                                                               0,
                                                                               0,
                                                                               DECODE(SIGN((NVL(PCMOVPREFAT.PTABELA,
                                                                                                0) -
                                                                                           NVL(PCMOVPREFAT.VLREPASSE,
                                                                                                0)) -
                                                                                           DECODE(PCMOVCOMPLEPREFAT.BONIFIC,
                                                                                                  'S',
                                                                                                  PCMOVPREFAT.PBONIFIC,
                                                                                                  PCMOVPREFAT.PUNITCONT)),
                                                                                      -1,
                                                                                      0,
                                                                                      (NVL(PCMOVPREFAT.PTABELA,
                                                                                           0) -
                                                                                      NVL(PCMOVPREFAT.VLREPASSE,
                                                                                           0)) -
                                                                                      
                                                                                      NVL(DECODE(PCMOVCOMPLEPREFAT.BONIFIC,
                                                                                                 'S',
                                                                                                 PCMOVPREFAT.PBONIFIC,
                                                                                                 PCMOVPREFAT.PUNITCONT),
                                                                                          0)))),
                                                                       NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                           2)) /
                                                                PCMOVPREFAT.QTCONT),
                                                                
                                                                (ROUND(PCMOVPREFAT.QTCONT *
                                                                       (DECODE((NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                                    0) -
                                                                               NVL(PCMOVPREFAT.VLREPASSE,
                                                                                    0)),
                                                                               0,
                                                                               0,
                                                                               DECODE(SIGN(NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                                               0) -
                                                                                           NVL(PCMOVPREFAT.VLREPASSE,
                                                                                               0)),
                                                                                      -1,
                                                                                      0,
                                                                                      NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                                          0) -
                                                                                      NVL(PCMOVPREFAT.VLREPASSE,
                                                                                          0)))),
                                                                       NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                           2)) /
                                                                PCMOVPREFAT.QTCONT)) +
                                                         (NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                                                              0)))) + (
                                                 --Melhoria HIS.04338.2015 - Eddy
                                                  CASE
                                                    WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE',
                                                                                         PCFILIAL.CODIGO) = 'N') AND
                                                         ((PCCLIENT.SULFRAMA IS NOT NULL) AND
                                                         (PCCLIENT.DTVENCSUFRAMA >
                                                         PCNFSAIDPREFAT.DTSAIDA))) THEN
                                                     0
                                                    ELSE
                                                     (ROUND((NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,
                                                                 0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS,
                                                                           0)) *
                                                            PCMOVPREFAT.QTCONT,
                                                            NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),
                                                                2)) / PCMOVPREFAT.QTCONT)
                                                  END)
                                              END +
                                             --utilizado somente para equipe de medicamentos
                                              (CASE
                                                WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                   PCFILIAL.CODIGO) = 'L' THEN
                                                 NVL(PCMOVCOMPLEPREFAT.VLDESCCOMERCIALICMISENCAO,
                                                     0)
                                                ELSE
                                                 0
                                              END))
                                   END AS VALOR_LIQUIDO,
                                   CASE
                                     WHEN ((CASE
                                            WHEN NVL(PCCLIENT.TIPOCLIMED, 'X') IN
                                                 ('D', 'E', 'M') AND
                                                 (NVL(PCPEDC.ROTINA, 'X') =
                                                  'PCMED316') THEN
                                             'S'
                                            ELSE
                                             'N'
                                          END) = 'S') THEN
                                      0
                                     ELSE
                                      DECODE(PCMOVPREFAT.CODOPER,
                                             'SD',
                                             -- Saida de Devolução
                                             ROUND(((ROUND(NVL(PCMOVPREFAT.VLDESCONTO,
                                                               0) *
                                                           PCMOVPREFAT.QTCONT,
                                                           2) /
                                                   PCMOVPREFAT.QTCONT) +
                                                   NVL(NVL(PCMOVPREFAT.VLDESCSUFRAMA,
                                                            PCMOVPREFAT.VLSUFRAMA),
                                                        0)) *
                                                   PCMOVPREFAT.QTCONT,
                                                   2),
                                             -- Normal
                                             CASE
                                                WHEN (PCNFSAIDPREFAT.CONDVENDA = 4 OR
                                                     NVL(PCNFSAIDPREFAT.NUMCUPOM, 0) > 0) THEN
                                                 ROUND((DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,
                                                                   NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                                      'N'),
                                                                                  'N',
                                                                                  '',
                                                                                  PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                           PCCLIENT.PRECOUTILIZADONFE),
                                                                       NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                         PCFILIAL.CODIGO),
                                                                           'L'))),
                                                               'L',
                                                               (NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,
                                                                    0) +
                                                               NVL(PCMOVPREFAT.VLDESCREDUCAOPIS,
                                                                    0)),
                                                               'LR',
                                                               0,
                                                               NVL(PCMOVCOMPLEPREFAT.VLSUBTOTDESCONTO,
                                                                   0)) *
                                                       PCMOVPREFAT.QTCONT),
                                                       2)
                                                ELSE
                                                 ROUND((DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,
                                                                   NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE,
                                                                                      'N'),
                                                                                  'N',
                                                                                  '',
                                                                                  PCPRODFILIAL.PRECOUTILIZADONFE),
                                                                           PCCLIENT.PRECOUTILIZADONFE),
                                                                       NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                                         PCFILIAL.CODIGO),
                                                                           'L'))),
                                                               'L',
                                                               0,
                                                               'LR',
                                                               NVL(ABS(PCMOVPREFAT.VLREPASSE),
                                                                   0),
                                                               DECODE(NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                          0),
                                                                      0,
                                                                      (ROUND(PCMOVPREFAT.QTCONT *
                                                                             (DECODE((NVL(PCMOVPREFAT.PTABELA,
                                                                                          0) -
                                                                                     NVL(PCMOVPREFAT.VLREPASSE,
                                                                                          0)),
                                                                                     0,
                                                                                     0,
                                                                                     DECODE(SIGN((NVL(PCMOVPREFAT.PTABELA,
                                                                                                      0) -
                                                                                                 NVL(PCMOVPREFAT.VLREPASSE,
                                                                                                      0)) -
                                                                                                 DECODE(PCMOVCOMPLEPREFAT.BONIFIC,
                                                                                                        'S',
                                                                                                        PCMOVPREFAT.PBONIFIC,
                                                                                                        PCMOVPREFAT.PUNITCONT)),
                                                                                            -1,
                                                                                            0,
                                                                                            (NVL(PCMOVPREFAT.PTABELA,
                                                                                                 0) -
                                                                                            NVL(PCMOVPREFAT.VLREPASSE,
                                                                                                 0)) -
                                                                                            NVL(DECODE(PCMOVCOMPLEPREFAT.BONIFIC,
                                                                                                       'S',
                                                                                                       PCMOVPREFAT.PBONIFIC,
                                                                                                       PCMOVPREFAT.PUNITCONT),
                                                                                                0)))),
                                                                             2) /
                                                                      PCMOVPREFAT.QTCONT),
                                                                      (GREATEST((ROUND(PCMOVPREFAT.QTCONT *
                                                                                       (DECODE((NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                                                    0) -
                                                                                               NVL(PCMOVPREFAT.VLREPASSE,
                                                                                                    0)),
                                                                                               0,
                                                                                               0,
                                                                                               DECODE(SIGN((NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                                                                0) -
                                                                                                           NVL(PCMOVPREFAT.VLREPASSE,
                                                                                                                0))),
                                                                                                      -1,
                                                                                                      0,
                                                                                                      (NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF,
                                                                                                           0) -
                                                                                                      NVL(PCMOVPREFAT.VLREPASSE,
                                                                                                           0))))),
                                                                                       2) /
                                                                                PCMOVPREFAT.QTCONT)
                                                                                
                                                                               ,
                                                                                0)))) +
                                                       (NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                                                             0) + CASE
                                                         WHEN (PCMOVCOMPLEPREFAT.CODMOTIVOICMSDESONERADO IN
                                                              ('7', '8')) THEN
                                                          0
                                                         ELSE
                                                          NVL(NVL(PCMOVPREFAT.VLDESCSUFRAMA,
                                                                  PCMOVPREFAT.VLSUFRAMA),
                                                              0)
                                                       END)) * PCMOVPREFAT.QTCONT,
                                                       2)
                                              END + ROUND(((
                                                          --Melhoria HIS.04338.2015 - Eddy
                                                          CASE
                                                            WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE',
                                                                                                 PCFILIAL.CODIGO) = 'N') AND
                                                                 ((PCCLIENT.SULFRAMA IS NOT NULL) AND
                                                                 (PCCLIENT.DTVENCSUFRAMA >
                                                                 PCNFSAIDPREFAT.DTSAIDA))) THEN
                                                             0
                                                            ELSE
                                                             CASE
                                                               WHEN (PCNFSAIDPREFAT.CONDVENDA = 4 OR
                                                                    NVL(PCNFSAIDPREFAT.NUMCUPOM, 0) > 0) THEN
                                                                0
                                                               ELSE
                                                                (NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS, 0) +
                                                                NVL(PCMOVPREFAT.VLDESCREDUCAOPIS, 0))
                                                             END
                                                          END)) * QTCONT,
                                                          2) +
                                             --utilizado somente para equipe de medicamentos
                                              ROUND((CASE
                                                      WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                         PCFILIAL.CODIGO) = 'L' THEN
                                                       NVL(PCMOVCOMPLEPREFAT.VLDESCCOMERCIALICMISENCAO,
                                                           0)
                                                      ELSE
                                                       0
                                                    END) * PCMOVPREFAT.QTCONT,
                                                    2))
                                   END AS VALOR_DESCONTO,
                                   ROUND((DECODE(PCMOVPREFAT.CODOPER,
                                                 'SD',
                                                 NVL(PCMOVPREFAT.VLDESPDENTRONF,
                                                     0) -
                                                 DECODE(NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC,
                                                            0),
                                                        0,
                                                        0,
                                                        NVL(PCMOVCOMPLEPREFAT.VLIPIOUTRAS,
                                                            0)),
                                                 NVL(PCMOVPREFAT.VLOUTROS, 0) -
                                                 NVL(PCMOVPREFAT.VLSEGURO, 0))) *
                                         QTCONT,
                                         2) AS VALOR_OUTROS
                              FROM PCMOVPREFAT,
                                   PCMOVCOMPLEPREFAT,
                                   PCMOVIMPOSTOS,
                                   PCFILIAL,
                                   PCPEDC,
                                   PCNFSAIDPREFAT,
                                   PCCLIENT,
                                   PCPRODFILIAL
                             WHERE PCMOVPREFAT.NUMTRANSITEM =
                                   PCMOVCOMPLEPREFAT.NUMTRANSITEM(+)
                               AND PCNFSAIDPREFAT.NUMTRANSVENDA =
                                   PCMOVPREFAT.NUMTRANSVENDA
                               AND PCNFSAIDPREFAT.NUMNOTA =
                                   PCMOVPREFAT.NUMNOTA
                               AND NVL(PCNFSAIDPREFAT.CODCLINF,
                                       PCNFSAIDPREFAT.CODCLI) =
                                   PCCLIENT.CODCLI(+)
                               AND PCMOVPREFAT.NUMTRANSVENDA =
                                   PCMOVIMPOSTOS.NUMTRANSVENDA(+)
                               AND PCMOVPREFAT.CODPROD =
                                   PCMOVIMPOSTOS.CODPROD(+)
                               AND PCMOVPREFAT.NUMSEQ =
                                   PCMOVIMPOSTOS.NUMSEQ(+)
                               AND NVL(PCMOVPREFAT.CODFILIALNF,
                                       PCMOVPREFAT.CODFILIAL) =
                                   PCFILIAL.CODIGO
                               AND PCMOVPREFAT.NUMPED = PCPEDC.NUMPED(+)
                               AND PCMOVPREFAT.CODPROD =
                                   PCPRODFILIAL.CODPROD(+)
                               AND NVL(PCMOVPREFAT.CODFILIALNF,
                                       PCMOVPREFAT.CODFILIAL) =
                                   PCPRODFILIAL.CODFILIAL(+)
                               AND NVL(PCMOVPREFAT.QTCONT, 0) > 0
                               AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                                  
                               AND PCMOVPREFAT.NUMTRANSVENDA = PNUMTRANSVENDA)) LOOP
      
        UPDATE PCMOV
           SET VITEM = DADOS.VALOR_LIQUIDO - DADOS.VALOR_DESCONTO
         WHERE NUMTRANSITEM = DADOS.NUMTRANSITEM;

        UPDATE PCMOVPREFAT
           SET VITEM = DADOS.VALOR_LIQUIDO - DADOS.VALOR_DESCONTO
         WHERE NUMTRANSITEM = DADOS.NUMTRANSITEM;
      
      END LOOP;
    
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END;  

END FERRAMENTAS_FATURAMENTO;