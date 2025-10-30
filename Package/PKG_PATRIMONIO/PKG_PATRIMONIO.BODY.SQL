CREATE OR REPLACE PACKAGE BODY PKG_PATRIMONIO
IS
   -- Declarando variaveis internas 
   pCodfiscal varchar(500); 
   
  PROCEDURE EXECUTAR_TESTE_UNITARIO ( PCODFILIAL IN VARCHAR2
                                     ,PDTINICIO IN DATE
                                     ,PDTFIM  IN DATE
                                     ,PGERA_NF_CANCELADAS IN VARCHAR2
                                     ,PNUMCASAS_QT IN NUMBER
                                     ,PNUMCASAS_UNIT IN NUMBER
                                     ,PEXIBITV14 IN VARCHAR2
                                     ,PCODFISCAL IN VARCHAR2
                                     ,PNUMNOTA1 IN NUMBER
                                     ,PNUMNOTA2 IN NUMBER
                                     ,PUTILIZOULISTAPRODUTO IN VARCHAR2
                                     ,PDESCONS_USOCONSUMO IN VARCHAR2
                                     ,PDESCONS_IMOBILIZADO IN VARCHAR2 ) IS
   voPARAMETROS PKG_PATRIMONIO.parametrosExecucao;          
  BEGIN
        --Passagem dos parâmetros');
        voPARAMETROS.CODFILIAL          := PCODFILIAL;
        voPARAMETROS.DTINICIO           := PDTINICIO;
        voPARAMETROS.DTFIM              := PDTFIM;
        voPARAMETROS.GERA_NF_CANCELADAS := PGERA_NF_CANCELADAS;
        voPARAMETROS.EXIBITV14          := PEXIBITV14;
        voPARAMETROS.NUMCASAS_QT        := PNUMCASAS_QT;
        voPARAMETROS.NUMCASAS_UNIT      := PNUMCASAS_UNIT;
        voPARAMETROS.NUMNOTA1           := PNUMNOTA1;
        voPARAMETROS.NUMNOTA2           := PNUMNOTA2;
        voPARAMETROS.CODFISCAL          := PCODFISCAL;
        voPARAMETROS.UTILIZOULISTAPRODUTO := PUTILIZOULISTAPRODUTO;
        voPARAMETROS.DESCONS_USOCONSUMO   := PDESCONS_USOCONSUMO;        
        voPARAMETROS.DESCONS_IMOBILIZADO  := PDESCONS_IMOBILIZADO;       
        
       EXECUTAR(voPARAMETROS);                  
  END;    

   PROCEDURE EXECUTAR( parametros in parametrosExecucao )
   IS 
   --Limpado a tabela/repositório de dados
   --pragma autonomous_transaction;
   BEGIN
     --Limpar base de dados
     DELETE FROM PCDADOS1070_TEMP;
     
     -- Configurando filtros da tela 
     if parametros.CODFISCAL is not null then 
        pCodfiscal := 'AND PCMOV.CODFISCAL IN ('||parametros.CODFISCAL||')';
     else 
        pCodfiscal := 'AND 0=0';      
     end if;
     
     --Obtendo as entradas
     OBTERENTRADAS( parametros );
     OBTERENTRADASCANCELADAS( parametros );
     OBTERENTRADASPRODUCAO(parametros );
     OBTERENTRADASAJUSTECUSTO(parametros );
     
     --Obtendo as saída
     OBTERSAIDAS(parametros );
     OBTERSAIDASCANCELADAS(parametros );

     OBTERID;
   END;
   

   FUNCTION SCRIPTCABECALHO
   RETURN STRING
   IS
   BEGIN
    RETURN 'INSERT INTO PCDADOS1070_TEMP( TIPO
                                        , SEQMOV
                                        , BASECUSTOCONT
                                        , CUSTOCONT
                                        , CUSTOFIN
                                        , CUSTOREAL
                                        , CUSTOREP
                                        , CUSTOULTENT
                                        , CUSTOREALSEMST
                                        , VALORULTENT
                                        , CUSTOFISCAL
                                        , ESPECIE
                                        , SERIE
                                        , CODCONT
                                        , OBSERVACAO
                                        , CODPROD
                                        , CODOPER
                                        , NUMNOTA
                                        , DATA
                                        , HORALANC
                                        , CODFISCAL
                                        , QTCONT
                                        , QTENTRADA
                                        , QTSAIDA
                                        , QTSAIDA_DENTRO
                                        , QTSAIDA_FORA
                                        , HISTORICO
                                        , PUNITCONT
                                        , VALORITEMNOTA_ENT
                                        , VALORITEMNOTA_SAID
                                        , NUMTRANSENT
                                        , NUMTRANSVENDA
                                        , VLIPI
                                        , ST
                                        , STGUIA
                                        , DTCANCEL
                                        , SITUACAOTRIBUTARIA
                                        , TIPODESCARGA
                                        , MINUTOLANC
                                        , CUSTOCONTANT
                                        , ROTINALANC
                                        , DTMOVLOG
                                        , QTESTANT
                                        )';
   END;
   -------------------------------------------------------------------------------
   FUNCTION SCRIPTHORAMINUTO(PHORA IN VARCHAR2, PORDENAR_PCMOVLOG IN VARCHAR2)
     RETURN VARCHAR2
   IS
   BEGIN
     IF PHORA = 'S' THEN
        IF PORDENAR_PCMOVLOG = 'S' THEN
           RETURN ' NVL(TO_CHAR(PCMOV.DTMOVLOG, ''HH24''), TO_CHAR(PCMOV.HORALANC)) HORALANC ';
        ELSE
           RETURN ' PCMOV.HORALANC ';
        END IF;
     ELSE
        IF PORDENAR_PCMOVLOG = 'S' THEN
           RETURN ' NVL(TO_CHAR(PCMOV.DTMOVLOG, ''MI''), TO_CHAR(PCMOV.MINUTOLANC)) MINUTOLANC ';
        ELSE
           RETURN ' PCMOV.MINUTOLANC ';
        END IF;
     END IF;
   END;
   -------------------------------------------------------------------------------
   FUNCTION SCRIPTCANCELADAS(PTABELA IN VARCHAR2, PGERA_NF_ENTRADA_CANC IN VARCHAR2)
     RETURN VARCHAR2
   IS
   BEGIN
     IF PGERA_NF_ENTRADA_CANC = 'N' THEN
        RETURN PTABELA || '.DTCANCEL IS NULL';
     ELSE
        RETURN '1=1';
     END IF;
   END;
   -------------------------------------------------------------------------------
   -- LANCAMENTO DE ENTRADA E ENTRADA CANCELADA COM QUANT POSITIVA.
   -------------------------------------------------------------------------------
   PROCEDURE OBTERENTRADAS( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN

     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       'SELECT CASE WHEN PCNFENT.TIPODESCARGA = ''P''
                                    THEN ''EP''
                                    WHEN PCNFENT.TIPODESCARGA = ''I'' AND PCNFENT.ESPECIE = ''CT''
                                    THEN ''EF''
                                    WHEN PCNFENT.TIPODESCARGA = ''I'' AND PCNFENT.ESPECIE = ''NS''
                                    THEN ''ES''
                                    ELSE ''E''
                               END TIPO
                             , PCMOV.SEQMOV
                             , NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) BASECUSTOCONT  
                             , NVL(PCMOV.CUSTOCONT,0) CUSTOCONT
                             , NVL(PCMOV.CUSTOFIN,0) CUSTOFIN
                             , NVL(PCMOV.CUSTOREAL,0) CUSTOREAL
                             , NVL(PCMOV.CUSTOREP,0) CUSTOREP
                             , NVL(PCMOV.CUSTOULTENT,0) CUSTOULTENT
                             , NVL(PCMOV.CUSTOREALSEMST,0) CUSTOREALSEMST
                             , NVL(PCMOV.VALORULTENT,0) VALORULTENT
                             , NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                             , PCNFENT.ESPECIE
                             , PCNFENT.SERIE
                             , TO_CHAR(PCNFENT.CODCONT) CODCONT
                             , CASE WHEN NVL(PCNFENT.TIPODESCARGA,''XX'') = ''P''
                                    THEN ''COMPLEMENTO DE CUSTO NF-e''
                                    ELSE REPLACE(PCNFENT.OBS,'''''''','''')
                               END OBSERVACAO
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , PCMOV.NUMNOTA
                             , PCNFENT.DTENT
                             , ' || SCRIPTHORAMINUTO('S','S')  || '
                             , NVL(PCMOV.CODFISCAL,0) CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '),0) QTCONT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTENTRADA
                             , 0 QTSAIDA
                             , 0 QTSAIDA_DENTRO
                             , 0 QTSAIDA_FORA
                             , CASE WHEN PCMOV.CODOPER = ''ED''
                                    THEN ''ENTRADA DE DEVOLUÇÃO''
                                    WHEN PCMOV.CODOPER = ''E''
                                    THEN ''ENTRADA DE MERCADORIAS''
                                    ELSE ''OUTRAS''
                               END HISTORICO
                             , NVL(ROUND(PCMOV.PUNITCONT, ' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) PUNITCONT
                             , NVL(ROUND(PCMOV.PUNITCONT -
                                         DECODE(PCMOV.CODOPER, ''ED'',
                                                NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                NVL(PCMOV.VLDESCONTO, 0)), 0' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) VALORITEMNOTA_ENT
                             , 0 VALORITEMNOTA_SAID
                             , PCMOV.NUMTRANSENT
                             , 0 NUMTRANSVENDA
                             , NVL(PCMOV.VLIPI, 0) VLIPI
                             , NVL(PCMOV.ST, 0) ST
                             , NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                             , PCMOV.DTCANCEL
                             , PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                             , PCNFENT.TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S') || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG 
                             , PCMOV.QTESTANT
                          FROM PCNFENT
                             , PCMOV
                             , PCMOVCOMPLE
                         WHERE PCNFENT.NUMTRANSENT = PCMOV.NUMTRANSENT
                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           AND PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                           AND PCNFENT.DTENT BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                           AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = ''' || parametros.CODFILIAL || '''
                                 --AND PCMOV.DTCANCEL IS NULL
                     AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                           AND PCNFENT.TIPODESCARGA NOT IN ( ''F'' ,''H'', ''G'' )
                           AND NVL(PCNFENT.FINALIDADENFE, ''O'') <> ''C''
                           AND NVL(PCNFENT.SITUACAONFE,''0'') NOT IN (110,205,301,302)
                           AND (((PCNFENT.TIPODESCARGA <> ''I'') AND (PCNFENT.ESPECIE IN (''NF'',''NE'',''TP'',''OE''))) OR ((PCNFENT.TIPODESCARGA = ''I'') AND (PCNFENT.ESPECIE IN (''CT'',''NS''))))
                           -- FILTRO DE NFs CANCELADAS --
                           AND ' || SCRIPTCANCELADAS('PCNFENT', parametros.GERA_NF_CANCELADAS)||CHR(13);
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                           AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS)||CHR(13);                           

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                           AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                           AND PCMOV.QTCONT > 0 
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           AND PCMOV.CODOPER <> ''EV''
                           AND NVL(PCMOV.MOVESTOQUECONTABIL,''S'') = ''S''
                           AND (((PCNFENT.TIPODESCARGA  IN (''P'',''I'')) 
                                AND (PCMOV.STATUS = ''B'')) OR ((PCNFENT.TIPODESCARGA NOT IN (''P'',''I'')) 
                                AND (PCMOV.STATUS in (''A'', ''AB''))))'
                           ;

 --Gravar do Debug - Inicio
 --    INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
 --   COMMIT;
 --Gravar do Debug - Fim

      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;

   PROCEDURE OBTERENTRADASCANCELADAS( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN
     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       '
                      SELECT TAB.TIPO,TAB.SEQMOV,TAB.BASECUSTOCONT,TAB.CUSTOCONT,TAB.CUSTOFIN,TAB.CUSTOREAL,TAB.CUSTOREP,TAB.CUSTOULTENT
                            ,TAB.CUSTOREALSEMST,TAB.VALORULTENT,TAB.CUSTOFISCAL,TAB.ESPECIE,TAB.SERIE,TAB.CODCONT,TAB.OBSERVACAO,TAB.CODPROD,TAB.CODOPER,TAB.NUMNOTA
                            ,TAB.DTCANCEL_ORIG DATA 
                            ,TAB.HORALANC,TAB.CODFISCAL,TAB.QTCONT,TAB.QTENTRADA,TAB.QTSAIDA,TAB.QTSAIDA_DENTRO,TAB.QTSAIDA_FORA,TAB.HISTORICO
                            ,TAB.PUNITCONT,TAB.VALORITEMNOTA_ENT,TAB.VALORITEMNOTA_SAID,TAB.NUMTRANSENT,TAB.NUMTRANSVENDA,TAB.VLIPI,TAB.ST,TAB.STGUIA
                            ,TAB.DTCANCEL_ORIG DTCANCEL, TAB.SITUACAOTRIBUTARIA,TAB.TIPODESCARGA,TAB.MINUTOLANC,TAB.CUSTOCONTANT,TAB.ROTINA,TAB.DTMOVLOG,TAB.QTESTANT                      FROM (
                        SELECT CASE WHEN PCNFENT.TIPODESCARGA = ''P''
                                    THEN ''EP''
                                    WHEN PCNFENT.TIPODESCARGA = ''I'' AND PCNFENT.ESPECIE = ''CT''
                                    THEN ''EF''
                                    WHEN PCNFENT.TIPODESCARGA = ''I'' AND PCNFENT.ESPECIE = ''NS''
                                    THEN ''ES''
                                    ELSE ''E''
                               END TIPO
                             , PCMOV.SEQMOV
                             , NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) BASECUSTOCONT
                             , NVL(PCMOVCOMPLE.CUSTOCONTCANC,PCMOV.CUSTOCONT) CUSTOCONT                            
                             , NVL(PCMOV.CUSTOFIN,0) CUSTOFIN
                             , NVL(PCMOV.CUSTOREAL,0) CUSTOREAL
                             , NVL(PCMOV.CUSTOREP,0) CUSTOREP
                             , NVL(PCMOV.CUSTOULTENT,0) CUSTOULTENT
                             , NVL(PCMOV.CUSTOREALSEMST,0) CUSTOREALSEMST
                             , NVL(PCMOV.VALORULTENT,0) VALORULTENT
                             , NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL                             
                             , PCNFENT.ESPECIE
                             , PCNFENT.SERIE
                             , TO_CHAR(PCNFENT.CODCONT) CODCONT
                             , CASE WHEN NVL(PCNFENT.TIPODESCARGA,''XX'') = ''P''
                                    THEN ''COMPLEMENTO DE CUSTO NF-e''
                                    ELSE REPLACE(PCNFENT.OBS,'''''''','''')
                               END OBSERVACAO
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , PCMOV.NUMNOTA
                             , PCMOV.DTCANCEL
                             , ' || SCRIPTHORAMINUTO('S','S')  || '
                             , NVL(PCMOV.CODFISCAL,0) CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '),0) QTCONT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTENTRADA
                             , 0 QTSAIDA
                             , 0 QTSAIDA_DENTRO
                             , 0 QTSAIDA_FORA
                             , CASE WHEN PCMOV.CODOPER = ''ED''
                                    THEN ''ENTRADA DE DEVOLUÇÃO''
                                    WHEN PCMOV.CODOPER = ''E''
                                    THEN ''ENTRADA DE MERCADORIAS''
                                    ELSE ''OUTRAS''
                               END HISTORICO
                             , NVL(ROUND(PCMOV.PUNITCONT, ' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) PUNITCONT
                             , NVL(ROUND(PCMOV.PUNITCONT -
                                         DECODE(PCMOV.CODOPER, ''ED'',
                                                NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                NVL(PCMOV.VLDESCONTO, 0)), 0' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) VALORITEMNOTA_ENT
                             , 0 VALORITEMNOTA_SAID
                             , PCMOV.NUMTRANSENT
                             , 0 NUMTRANSVENDA
                             , NVL(PCMOV.VLIPI, 0) VLIPI
                             , NVL(PCMOV.ST, 0) ST
                             , NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                             , PCMOV.DTCANCEL
                             , PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                             , PCNFENT.TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S') || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG 
                             , PCMOV.QTESTANT
                             ,TRUNC(PCNFENT.DTCANCEL) DTCANCEL_ORIG
                          FROM PCNFENT
                             , PCMOV
                             , PCMOVCOMPLE
                         WHERE PCNFENT.NUMTRANSENT = PCMOV.NUMTRANSENT
                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           AND PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                           AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = ''' || parametros.CODFILIAL || '''
                           AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                           AND PCNFENT.TIPODESCARGA NOT IN ( ''F'' ,''H'', ''G'' )
                           AND  (((PCNFENT.TIPODESCARGA <> ''I'') AND (PCNFENT.ESPECIE IN (''NF'',''NE'',''TP'',''OE''))) OR ((PCNFENT.TIPODESCARGA = ''I'') AND (PCNFENT.ESPECIE IN (''CT'',''NS''))))
                           AND NVL(PCNFENT.FINALIDADENFE, ''O'') <> ''C''
                           AND NVL(PCNFENT.SITUACAONFE,''0'') NOT IN (110,205,301,302)

                           AND PCNFENT.DTENT BETWEEN TO_DATE('''|| parametros.DTINICIO ||''') -30 AND ''' || parametros.DTFIM  ||''''||CHR(13);
                           
                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                                                     
                           AND ' || SCRIPTCANCELADAS('PCNFENT', parametros.GERA_NF_CANCELADAS)|| '
                           AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                           AND PCMOV.QTCONT < 0
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           AND PCMOV.CODOPER <> ''EV''
                           AND NVL(PCMOV.MOVESTOQUECONTABIL,''S'') = ''S''
                           AND  (((PCNFENT.TIPODESCARGA  IN (''P'',''I'')) AND (PCMOV.STATUS = ''B'')) OR  ((PCNFENT.TIPODESCARGA NOT IN (''P'',''I'')) AND (PCMOV.STATUS in (''A'', ''AB''))))
                     ) TAB WHERE TAB.DTCANCEL_ORIG BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM  ||''''||CHR(13);

--Gravar do Debug - Inicio
--   INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
--   COMMIT;
--Gravar do Debug - Fim

      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;

   PROCEDURE OBTERENTRADASCONSIGNADAS( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN-- ENTRADA DE ESTORNO REF.FATURAMENTO DE CONSIGNADO. Esse lançamento faz a contra partida da segunda nota de saída do consignado.
     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       'SELECT ''ER'' TIPO
                             , PCMOV.SEQMOV
                             , 0 BASECUSTOCONT
                             , 0 CUSTOCONT
                             , 0 CUSTOFIN
                             , 0 CUSTOREAL
                             , 0 CUSTOREP
                             , 0 CUSTOULTENT
                             , 0 CUSTOREALSEMST
                             , 0 VALORULTENT
                             , 0 CUSTOFISCAL
                             , ''ER'' ESPECIE
                             , '''' SERIE
                             , '''' CODCONT
                             , ''Ent.Ref.Fat.Consignado'' OBSERVACAO
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , PCMOV.NUMNOTA
                             , PCMOV.DTMOV
                             , ' || SCRIPTHORAMINUTO('S', 'S')  || '
                             , PCMOV.CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '),0) QTCONT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTENTRADA
                             , 0 QTSAIDA
                             , 0 QTSAIDA_DENTRO
                             , 0 QTSAIDA_FORA
                             , ''Ent.Ref.Fat.Consignado'' HISTORICO
                             , 0 PUNITCONT
                             , 0 VALORITEMNOTA_ENT
                             , 0 VALORITEMNOTA_SAID
                             , PCMOV.NUMTRANSENT
                             , 0 NUMTRANSVENDA
                             , 0 VLIPI
                             , 0 ST
                             , 0 STGUIA
                             , PCMOV.DTCANCEL
                             , PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                             , '''' TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S')  || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG 
                             , PCMOV.QTESTANT                             
                          FROM PCMOV
                             , PCPEDC P
                         WHERE PCMOV.DTMOV BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                           AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = ''' || parametros.CODFILIAL||CHR(13);

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                           
                           AND PCMOV.QTCONT > 0
                           AND PCMOV.STATUS = ''AB''
                           AND PCMOV.CODOPER = ''ER''
                           AND NVL(PCMOV.NUMPED,0) = NVL(P.NUMPED,0)
                           AND NVL(P.NUMNOTACONSIG,0) > 0
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           ';

 --Gravar do Debug - Inicio

 --   INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
 --   COMMIT;

 --Gravar do Debug - Fim

      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;


   PROCEDURE OBTERENTRADASAJUSTECUSTO( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT                 varchar2(32767);
     V_FIL_CALCREDPISFRETECONT      varchar2(1);
     V_UTICREDICMSFRETEFOBCUSTOCONT varchar2(1);
     V_CALCREDPISCOFINSSERVICOCONT  varchar2(1);
   -------------------------------------------   
     
   BEGIN
     -- Obtendo parametros:
     V_FIL_CALCREDPISFRETECONT      := paramfilial.obtercomovarchar2('FIL_CALCREDPISFRETECONT', parametros.CODFILIAL);
     V_UTICREDICMSFRETEFOBCUSTOCONT := paramfilial.obtercomovarchar2('FIL_CALCREDPISFRETECONT', parametros.CODFILIAL);
     V_CALCREDPISCOFINSSERVICOCONT  := paramfilial.obtercomovarchar2('CALCREDPISCOFINSSERVICOCONT',parametros.CODFILIAL);

     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       '
                        -- ENTRADA TIPO ''P''
                        SELECT ''EP'' TIPO
                               ,PCMOV.SEQMOV
                               ,0 BASECUSTOCONT
                               ,PCMOV.CUSTOCONT
                               ,PCMOV.CUSTOFIN
                               ,PCMOV.CUSTOREAL
                               ,PCMOV.CUSTOREP
                               ,PCMOV.CUSTOULTENT
                               ,PCMOV.CUSTOREALSEMST
                               ,PCMOV.VALORULTENT
                               ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL                               
                               ,PCNFENT.ESPECIE
                               ,PCNFENT.SERIE
                               ,TO_CHAR(PCNFENT.CODCONT) CODCONT
                               , CASE WHEN PCNFENT.DTCANCEL IS NULL
                                    THEN ''COMPLEMENTO DE CUSTO NF-e''
                                    ELSE REPLACE(PCNFENT.OBS,'''''''','''')
                                END OBSERVACAO
                               ,PCMOV.CODPROD
                               ,PCMOV.CODOPER
                               ,PCNFENT.NUMNOTA
                               ,PCNFENT.DTENT DATA
                               -- CONFIGURANDO HORA_LANC
                               ,' || SCRIPTHORAMINUTO('S','S')  || '
                               --
                               ,PCMOV.CODFISCAL
                               ,0 QTCONT
                               ,0 QTENTRADA
                               ,0 QTSAIDA
                               ,0 QTSAIDA_DENTRO
                               ,0 QTSAIDA_FORA
                               ,DECODE(PCMOV.CODOPER, ''ED'',
                                      ''ENTRADA DE DEVOLUÇÃO'', ''E'',
                                      ''ENTRADA DE MERCADORIAS'', ''OUTRAS'') HISTORICO
                               ,ROUND(PCMOV.PUNITCONT, ' || TO_CHAR(parametros.NUMCASAS_UNIT) || ') PUNITCONT
                               ,ROUND(PCMOV.PUNITCONT -
                                     DECODE(PCMOV.CODOPER, ''ED'',
                                            NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                            NVL(PCMOV.VLDESCONTO, 0)), ' || TO_CHAR(parametros.NUMCASAS_UNIT) || ') VALORITEMNOTA_ENT
                               ,0 VALORITEMNOTA_SAID
                               ,PCMOV.NUMTRANSENT
                               ,0 NUMTRANSVENDA
                               ,NVL(PCMOV.VLIPI, 0) VLIPI
                               ,NVL(PCMOV.ST, 0) ST
                               ,NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                               ,PCNFENT.DTCANCEL
                               ,PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                               ,PCNFENT.TIPODESCARGA
                               -- CONFIGURANDO MINUTO_LANC
                               ,' || SCRIPTHORAMINUTO('N', 'S') || '
                               ---------------------------------------
                               ,PCMOV.CUSTOCONTANT
                               ,PCMOV.ROTINACAD
                               ,PCMOV.DTMOVLOG
                               ,PCMOV.QTESTANT                               
                         FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL
                        WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                           AND PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                          AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                          AND PCNFENT.DTENT BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                          AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = ''' || parametros.CODFILIAL || '''                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                          AND PCNFENT.TIPODESCARGA = ''P''
                          AND PCNFENT.ESPECIE IN (''NF'',''NE'',''TP'')
                          AND ' || SCRIPTCANCELADAS('PCNFENT', parametros.GERA_NF_CANCELADAS)||CHR(13);

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                                                    
                          AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                          AND PCMOV.STATUS = ''B''
                          AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                          AND PCMOV.CODOPER <> ''EV''
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                          AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                          --AND DECODE(PUSOCONSUMO,''N'',NVL(NVL(PCMOV.TIPOMERCDEPTO, ''XX''), ''X''),''XX'') <> ''CI''
                          --AND DECODE(PATIVIOMOBULIZADO,''N'',NVL(NVL(PCMOV.TIPOMERCDEPTO, ''XX''), ''X''),''XX'') <> ''IM''
                        ---------------------------------------------------------
                        UNION ALL
                        ---------------------------------------------------------
                        -- ENTRADA CT AJUSTANDO O CUSTO
                        SELECT ''EF'' TIPO
                               ,PCMOV.SEQMOV
                               -----------------------------------------------------
                               --ROUND(PCMOV.VLFRETECONHEC, 6) BASECUSTOCONT, 
                               ,ROUND(PCMOV.VLFRETECONHEC - ((CASE WHEN NVL( '''||V_FIL_CALCREDPISFRETECONT||''' ,''N'')  = ''S'' THEN
                                                                 (VLCREDPISFRETEFOB + VLCREDCOFINSFRETEFOB) ELSE 0 END)
                                                                 +
                                                            (CASE WHEN NVL( '''||V_UTICREDICMSFRETEFOBCUSTOCONT||''',PCMOVCOMPLE.APROVEITACREDICMSCONT) = ''S'' THEN
                                                                 PCMOVCOMPLE.VLICMSFRETEFOB ELSE 0 END)
                               ),6) AS BASECUSTOCONT 
                               ------------------------------------------------------
                               ,PCMOV.CUSTOCONT
                               ,PCMOV.CUSTOFIN
                               ,PCMOV.CUSTOREAL
                               ,PCMOV.CUSTOREP
                               ,PCMOV.CUSTOULTENT
                               ,PCMOV.CUSTOREALSEMST
                               ,PCMOV.VALORULTENT
                               ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL                               
                               ,PCNFENT.ESPECIE
                               ,PCNFENT.SERIE
                               ,TO_CHAR(PCNFENT.CODCONT) CODCONT
                               ,''COMPLEMENTO DE CUSTO CT-e'' OBSERVACAO
                               ,PCMOV.CODPROD
                               ,PCMOV.CODOPER
                               ,PCNFENT.NUMNOTA
                               ,PCNFENT.DTENT DATA
                               -- CONFIGURANDO HORA_LANC
                               ,' || SCRIPTHORAMINUTO('S','S')  || '
                               --
                               ,PCMOV.CODFISCAL
                               ,ROUND(PCMOV.QT, 2) QTCONT
                               ,DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'',
                                      ROUND(PCMOV.QT, 6),0) QTENTRADA
                               ,0 QTSAIDA
                               ,0 QTSAIDA_DENTRO
                               ,0 QTSAIDA_FORA
                               ,DECODE(PCMOV.CODOPER, ''ED'',
                                      ''ENTRADA DE DEVOLUÇÃO'', ''E'',
                                      ''ENTRADA DE MERCADORIAS'', ''OUTRAS'') HISTORICO
                               ,ROUND(PCMOV.VLFRETECONHEC, 6) PUNITCONT
                               ,ROUND(PCMOV.VLFRETECONHEC -
                                     DECODE(PCMOV.CODOPER, ''ED'',
                                            NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                            NVL(PCMOV.VLDESCONTO, 0)), 6) VALORITEMNOTA_ENT
                               ,0 VALORITEMNOTA_SAID
                               ,PCMOV.NUMTRANSENT
                               ,0 NUMTRANSVENDA
                               ,NVL(PCMOV.VLIPI, 0) VLIPI
                               ,NVL(PCMOV.ST, 0) ST
                               ,NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                               ,PCNFENT.DTCANCEL
                               ,PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                               ,PCNFENT.TIPODESCARGA
                               -- CONFIGURANDO MINUTO_LANC
                               ,' || SCRIPTHORAMINUTO('N', 'S') || '
                               ---------------------------------------
                               ,PCMOV.CUSTOCONTANT
                               ,PCMOV.ROTINACAD
                               ,PCMOV.DTMOVLOG
                               ,PCMOV.QTESTANT                               
                         FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL
                        WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                          AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                          AND PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                          AND PCNFENT.DTENT BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                          AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = ''' || parametros.CODFILIAL || '''                                
                          
                          AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                          AND PCNFENT.TIPODESCARGA = ''I''
                          AND PCNFENT.ESPECIE = ''CT''
                          AND ' || SCRIPTCANCELADAS('PCNFENT', parametros.GERA_NF_CANCELADAS)||CHR(13);

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                           
                          AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                          AND PCMOV.STATUS = ''B''
                          AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                          AND PCMOV.CODOPER <> ''EV''
                           '   ||pCodfiscal||' 
                          AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                          AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                          --AND DECODE(PUSOCONSUMO,''N'',NVL(NVL(PCMOV.TIPOMERCDEPTO, ''XX''), ''X''),''XX'') <> ''CI''
                          --AND DECODE(PATIVIOMOBULIZADO,''N'',NVL(NVL(PCMOV.TIPOMERCDEPTO, ''XX''), ''X''),''XX'') <> ''IM''
                        ---------------------------------------------------------
                        UNION ALL
                        ---------------------------------------------------------
                        -- ENTRADA SERVIÇO AJUSTANDO O CUSTO - ESPECIE = NS
                        SELECT ''ES'' TIPO
                               ,PCMOV.SEQMOV
                               ----------------------------------------------------
                               --ROUND(PCMOVCOMPLE.VLNFSERVICO, 6) BASECUSTOCONT,
                               ,ROUND(PCMOVCOMPLE.VLNFSERVICO - ( -- CASE SOMANDO PIS E COFINS, CASO PARAMETRO COMO SIM.
                                                                   (CASE WHEN NVL( '''||V_CALCREDPISCOFINSSERVICOCONT||''',''N'') = ''S'' THEN
                                                                         (VLCREDPISFRETEFOB + VLCREDCOFINSFRETEFOB) ELSE 0 END))
                               ,6) AS BASECUSTOCONT
                               ------------------------------------------------------
                               ,PCMOV.CUSTOCONT
                               ,PCMOV.CUSTOFIN
                               ,PCMOV.CUSTOREAL
                               ,PCMOV.CUSTOREP
                               ,PCMOV.CUSTOULTENT
                               ,PCMOV.CUSTOREALSEMST
                               ,PCMOV.VALORULTENT
                               ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                               ,PCNFENT.ESPECIE
                               ,PCNFENT.SERIE
                               ,TO_CHAR(PCNFENT.CODCONT) CODCONT
                               ,''COMPLEMENTO DE CUSTO NOTA DE SERVIÇO'' OBSERVACAO
                               ,PCMOV.CODPROD
                               ,PCMOV.CODOPER
                               ,PCNFENT.NUMNOTA
                               ,PCNFENT.DTENT DATA
                               -- CONFIGURANDO HORA_LANC
                               ,' || SCRIPTHORAMINUTO('S','S')  || '
                               --
                               ,PCMOV.CODFISCAL
                               ,ROUND(PCMOV.QT, 2) QTCONT
                               ,DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'',
                                      ROUND(PCMOV.QT, 6),0) QTENTRADA
                               ,0 QTSAIDA
                               ,0 QTSAIDA_DENTRO
                               ,0 QTSAIDA_FORA
                               ,DECODE(PCMOV.CODOPER, ''ED'',
                                      ''ENTRADA DE DEVOLUÇÃO'', ''E'',
                                      ''ENTRADA DE MERCADORIAS'', ''OUTRAS'') HISTORICO
                               ,ROUND(PCMOVCOMPLE.VLNFSERVICO, 6) PUNITCONT
                               ,ROUND(PCMOVCOMPLE.VLNFSERVICO -
                                     DECODE(PCMOV.CODOPER, ''ED'',
                                            NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                            NVL(PCMOV.VLDESCONTO, 0)), 6) VALORITEMNOTA_ENT
                               ,0 VALORITEMNOTA_SAID
                               ,PCMOV.NUMTRANSENT
                               ,0 NUMTRANSVENDA
                               ,NVL(PCMOV.VLIPI, 0) VLIPI
                               ,NVL(PCMOV.ST, 0) ST
                               ,NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                               ,PCNFENT.DTCANCEL
                               ,PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                               ,PCNFENT.TIPODESCARGA
                               -- CONFIGURANDO MINUTO_LANC
                               ,' || SCRIPTHORAMINUTO('N', 'S') || '
                               ---------------------------------------
                               ,PCMOV.CUSTOCONTANT
                               ,PCMOV.ROTINACAD
                               ,PCMOV.DTMOVLOG
                               ,PCMOV.QTESTANT                               
                         FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL
                        WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                          AND PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                          AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                          AND PCNFENT.DTENT BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                          AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = ''' || parametros.CODFILIAL || '''
                          AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                          AND PCNFENT.TIPODESCARGA = ''I''
                          AND PCNFENT.ESPECIE = ''NS''
                          AND ' || SCRIPTCANCELADAS('PCNFENT', parametros.GERA_NF_CANCELADAS)||CHR(13);

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                             
                          AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                          AND PCMOV.STATUS = ''B''
                          AND NVL(PCNFENT.NFENTREGAFUTURA, ''N'') = ''N''
                          AND PCMOV.CODOPER <> ''EV''
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                          AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                          --AND DECODE(PUSOCONSUMO,''N'',NVL(NVL(PCMOV.TIPOMERCDEPTO, ''XX''), ''X''),''XX'') <> ''CI''
                          --AND DECODE(PATIVIOMOBULIZADO,''N'',NVL(NVL(PCMOV.TIPOMERCDEPTO, ''XX''), ''X''),''XX'') <> ''IM''
                          ';

   --Gravar do Debug - Inicio
   --   delete from SQL_GERADO; 
   --   INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
   --   COMMIT;
  
   --Gravar do Debug - Fim

      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;
   ------------------------------------------------------   


   PROCEDURE OBTERSAIDAS( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN-- ENTRADA DE ESTORNO REF.FATURAMENTO DE CONSIGNADO. Esse lançamento faz a contra partida da segunda nota de saída do consignado.
     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       'SELECT CASE WHEN PCNFSAID.DTCANCEL IS NOT NULL
                                    THEN ''SC''
                                    ELSE ''S''
                               END TIPO
                             , PCMOV.SEQMOV SEQMOV
                             , 0 BASECUSTOCONT
                             , NVL(PCMOV.CUSTOCONT,0) CUSTOCONT
                             , NVL(PCMOV.CUSTOFIN,0) CUSTOFIN
                             , NVL(PCMOV.CUSTOREAL,0) CUSTOREAL
                             , NVL(PCMOV.CUSTOREP,0) CUSTOREP
                             , NVL(PCMOV.CUSTOULTENT,0) CUSTOULTENT
                             , NVL(PCMOV.CUSTOREALSEMST,0) CUSTOREALSEMST
                             , NVL(PCMOV.VALORULTENT,0) VALORULTENT
                             , NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                             , PCNFSAID.ESPECIE
                             , PCNFSAID.SERIE
                             , PCNFSAID.CODCONT
                             , REPLACE(PCNFSAID.OBS,'''''''','''')
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , PCMOV.NUMNOTA
                             , PCNFSAID.DTSAIDA DATA
                             , ' || SCRIPTHORAMINUTO('S', 'S')  || '
                             , NVL(PCMOV.CODFISCAL,0) CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '),0) QTCONT
                             , 0 QTENTRADA
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''S'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTSAIDA
                             , CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000
                                    THEN 0
                                    ELSE NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0)
                               END QTSAIDA_DENTRO
                             , CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000
                                    THEN NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0)
                                    ELSE 0
                               END QTSAIDA_FORA
                             , CASE WHEN PCMOV.CODOPER = ''SD''
                                    THEN ''SAIDAS DE DEVOLUÇÃO''
                                    WHEN PCMOV.CODOPER = ''S''
                                    THEN ''SAIDAS DE MERCADORIAS''
                                    ELSE ''OUTRAS''
                               END HISTORICO
                             , NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, ''N''), ''S'', PCMOV.PBONIFIC, PCMOV.PUNITCONT), ' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) PUNITCONT
                             , 0 VALORITEMNOTA_ENT
                             , NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, ''N''), ''S'', PCMOV.PBONIFIC, PCMOV.PUNITCONT) - DECODE(PCMOV.CODOPER, ''SD'', NVL(PCMOV.VLFRETE, 0), 0), ' || TO_CHAR(parametros.NUMCASAS_UNIT) || '),0) VALORITEMNOTA_SAID
                             , 0 NUMTRANSENT
                             , PCMOV.NUMTRANSVENDA
                             , NVL(PCMOV.VLIPI, 0) VLIPI
                             , NVL(PCMOV.ST, 0) ST
                             , NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                             , PCMOV.DTCANCEL
                             , PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                             , NULL TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S')  || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG
                             , PCMOV.QTESTANT                              
                          FROM PCNFSAID
                             , PCMOV
                             , PCMOVCOMPLE
                         WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                           AND PCNFSAID.NUMNOTA = PCMOV.NUMNOTA
                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           AND PCNFSAID.DTSAIDA BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                           AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL)= ''' || parametros.CODFILIAL || '''
                           AND PCNFSAID.ESPECIE IN (''NF'', ''CF'', ''CP'',''NE'',''TP'')
                           AND NVL(PCNFSAID.CONDVENDA, 0) NOT IN (3, 6, DECODE(PCNFSAID.FORNECENTREGA, ''S'', -1, 7), 12,DECODE(''' ||parametros.EXIBITV14|| ''', ''S'', 13, 14))
                           AND NVL(PCNFSAID.FINALIDADENFE, ''O'') <> ''C''
                           AND NVL(PCNFSAID.SITUACAONFE,''0'') NOT IN (110,205,301,302)
                           AND ' || SCRIPTCANCELADAS('PCNFSAID', parametros.GERA_NF_CANCELADAS) ||CHR(13);

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                           AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                           AND PCMOV.QTCONT > 0
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           AND NVL(PCMOV.MOVESTOQUECONTABIL,''S'') = ''S''
                           AND PCMOV.STATUS IN (''A'', ''AB'')
                           ';

 --Gravar do Debug - Inicio

--    INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
--    COMMIT;

 --Gravar do Debug - Fim

      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;

   PROCEDURE OBTERSAIDASCANCELADAS( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN
     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       'SELECT CASE WHEN PCNFSAID.DTCANCEL IS NOT NULL
                                    THEN ''SC''
                                    ELSE ''S''
                               END TIPO
                             , PCMOV.SEQMOV SEQMOV
                             , 0 BASECUSTOCONT
                             , NVL(PCMOV.CUSTOCONT,0) CUSTOCONT
                             , NVL(PCMOV.CUSTOFIN,0) CUSTOFIN
                             , NVL(PCMOV.CUSTOREAL,0) CUSTOREAL
                             , NVL(PCMOV.CUSTOREP,0) CUSTOREP
                             , NVL(PCMOV.CUSTOULTENT,0) CUSTOULTENT
                             , NVL(PCMOV.CUSTOREALSEMST,0) CUSTOREALSEMST
                             , NVL(PCMOV.VALORULTENT,0) VALORULTENT
                             , NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                             , PCNFSAID.ESPECIE
                             , PCNFSAID.SERIE
                             , PCNFSAID.CODCONT
                             , REPLACE(PCNFSAID.OBS,'''''''','''')
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , PCMOV.NUMNOTA
                             , PCMOV.DTCANCEL DATA
                             , ' || SCRIPTHORAMINUTO('S', 'S')  || '
                             , NVL(PCMOV.CODFISCAL,0) CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '),0) QTCONT
                             , 0 QTENTRADA
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''S'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTSAIDA
                             , CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000
                                    THEN 0
                                    ELSE NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0)
                               END  * -1 QTSAIDA_DENTRO
                             , CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000
                                    THEN NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0)
                                    ELSE 0
                               END  * -1 QTSAIDA_FORA
                             , CASE WHEN PCMOV.CODOPER = ''SD''
                                    THEN ''SAIDAS DE DEVOLUÇÃO''
                                    WHEN PCMOV.CODOPER = ''S''
                                    THEN ''SAIDAS DE MERCADORIAS''
                                    ELSE ''OUTRAS''
                               END HISTORICO
                             , NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, ''N''), ''S'', PCMOV.PBONIFIC, PCMOV.PUNITCONT), ' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) PUNITCONT
                             , 0 VALORITEMNOTA_ENT
                             , NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, ''N''), ''S'', PCMOV.PBONIFIC, PCMOV.PUNITCONT) - DECODE(PCMOV.CODOPER, ''SD'', NVL(PCMOV.VLFRETE, 0), 0), ' || TO_CHAR(parametros.NUMCASAS_UNIT) || '),0) VALORITEMNOTA_SAID
                             , 0 NUMTRANSENT
                             , PCMOV.NUMTRANSVENDA
                             , NVL(PCMOV.VLIPI, 0) VLIPI
                             , NVL(PCMOV.ST, 0) ST
                             , NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                             , PCMOV.DTCANCEL
                             , PCMOV.SITTRIBUT SITUACAOTRIBUTARIA
                             , NULL TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S')  || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG
                             , PCMOV.QTESTANT                             
                          FROM PCNFSAID
                             , PCMOV
                             , PCMOVCOMPLE
                         WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                           AND PCNFSAID.NUMNOTA = PCMOV.NUMNOTA
                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           AND PCMOV.DTCANCEL BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                           AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL)= ''' || parametros.CODFILIAL || '''
                           AND NVL(PCNFSAID.CONDVENDA, 0) NOT IN (3, 6, DECODE(PCNFSAID.FORNECENTREGA, ''S'', -1, 7), 12,DECODE(''' ||parametros.EXIBITV14|| ''', ''S'', 13, 14))
                           AND PCNFSAID.ESPECIE IN (''NF'', ''CF'', ''CP'',''NE'',''TP'')
                           AND NVL(PCNFSAID.FINALIDADENFE, ''O'') <> ''C''
                           AND NVL(PCNFSAID.SITUACAONFE,''0'') NOT IN (110,205,301,302)
                           AND ' || SCRIPTCANCELADAS('PCNFSAID', parametros.GERA_NF_CANCELADAS)||CHR(13);

                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'  
                           
                           AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                           AND PCMOV.QTCONT < 0
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           AND NVL(PCMOV.MOVESTOQUECONTABIL,''S'') = ''S''
                           AND PCMOV.STATUS IN (''A'', ''AB'')
                           ';

 --Gravar do Debug - Inicio

 --   INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
--    COMMIT;

 --Gravar do Debug - Fim

      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;

   PROCEDURE OBTERENTRADASPRODUCAO( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN-- ENTRADA DE ESTORNO REF.FATURAMENTO DE CONSIGNADO. Esse lançamento faz a contra partida da segunda nota de saída do consignado.
     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       'SELECT CASE WHEN PCMOV.DTCANCEL IS NOT NULL
                                    THEN ''AC''
                                    ELSE ''AE''
                               END TIPO
                             , PCMOV.SEQMOV
                             , CASE WHEN PCMOV.CODOPER = ''EP''
                                    THEN NVL(PCMOV.CUSTOULTENT, 0)
                                    ELSE NVL(PCMOV.CUSTOCONT, 0)
                               END BASECUSTOCONT
                             , PCMOV.CUSTOCONT
                             , PCMOV.CUSTOFIN
                             , PCMOV.CUSTOREAL
                             , PCMOV.CUSTOREP
                             , CASE WHEN PCMOV.CODOPER = ''EP''
                                    THEN NVL(PCMOV.CUSTOULTENT, 0)
                                    ELSE NVL(PCMOV.CUSTOCONT, 0)
                               END CUSTOULTENT
                             , PCMOV.CUSTOREALSEMST
                             , PCMOV.VALORULTENT
                             , NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                             , ''OP'' ESPECIE
                             , '''' SERIE
                             , null CODCONT
                             , DECODE( PCMOV.CODOPER, ''EA'', ''ENTRADA AJUSTE''
                                                    , ''EP'', ''ENTRADA PRODUÇÃO''
                                                    , ''EX'', ''DEV. AVULSA PRODUÇÃO''
                                                    , ''RA'', ''REQ. AVULSA PRODUÇÃO''
                                                    , ''SA'', ''SAÍDA AJUSTE''
                                                    , ''SP'', ''SAÍDA DE PRODUÇÃO''
                                                    , ''OUTRAS DE PRODUÇÃO'') OBSERVACAO
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , CASE WHEN PCMOV.CODOPER LIKE ''E%''
                                    THEN NVL(PCMOV.NUMOP,PCMOV.NUMTRANSENT)
                                    ELSE NVL(PCMOV.NUMOP,PCMOV.NUMTRANSVENDA)
                               END NUMNOTA
                             , PCMOV.DTMOV DATA
                             , ' || SCRIPTHORAMINUTO('S', 'S')  || '
                             , PCMOV.CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTCONT
                             , NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0),  0) QTENTRADA
                             , NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', 0, ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || ')), 0) QTSAIDA
                             , 0 QTSAIDA_DENTRO
                             , 0 QTSAIDA_FORA
                             , DECODE(PCMOV.CODOPER, ''EA'', ''ENTRADA AJUSTE''
                                                   , ''EP'', ''ENTRADA PRODUÇÃO''
                                                   , ''EX'', ''DEV. AVULSA PRODUÇÃO''
                                                   , ''RA'', ''REQ. AVULSA PRODUÇÃO''
                                                   , ''SA'', ''SAÍDA AJUSTE''
                                                   , ''SP'', ''SAÍDA DE PRODUÇÃO''
                                                   , ''OUTRAS DE PRODUÇÃO'') HISTORICO
                             , NVL(ROUND(PCMOV.PUNITCONT,' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) PUNITCONT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', PCMOV.PUNITCONT, 0) VALORITEMNOTA_ENT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', 0, PCMOV.PUNITCONT) VALORITEMNOTA_SAID
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', PCMOV.NUMTRANSENT, 0) NUMTRANSENT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', 0, PCMOV.NUMTRANSVENDA) NUMTRANSVENDA
                             , NVL(PCMOV.VLIPI, 0) VLIPI
                             , NVL(PCMOV.ST, 0) ST
                             , NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                             , PCMOV.DTCANCEL
                             , NULL SITUACAOTRIBUTARIA
                             , NULL TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S')  || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG 
                             , PCMOV.QTESTANT                             
                          FROM PCMOV, 
                               PCMOVCOMPLE 
                         WHERE PCMOV.DTMOV BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                           AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)= ''' || parametros.CODFILIAL||''''||CHR(13);
                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'                             AND PCMOV.QTCONT > 0
                           AND PCMOV.DTCANCEL is null
                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           AND PCMOV.CODOPER in (''EP'', ''SP'', ''EA'', ''SA'', ''EX'', ''RA'')
                           AND ' || SCRIPTCANCELADAS('PCMOV', parametros.GERA_NF_CANCELADAS) || '
                           AND PCMOV.STATUS in (''A'', ''AB'')
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           AND NOT EXISTS (SELECT 1
                                             FROM PCNFSAID
                                            WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                              AND PCNFSAID.ESPECIE = ''NF''
                                              AND PCNFSAID.DTCANCEL IS NULL
                                              AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL)= ''' || parametros.CODFILIAL || '''
                                              AND PCNFSAID.VLTOTAL > 0)';
 --Gravar do Debug - Inicio
 --   INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
 --   COMMIT;
 --Gravar do Debug - Fim
      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;
   --------------------------------------------------------------------------------------------------------------

   PROCEDURE OBTERENTRADASPRODUCAO_CANC( parametros in parametrosExecucao )
   IS
     vsINSERTSELECT             VARCHAR2(32767);
   BEGIN
     vsINSERTSELECT := SCRIPTCABECALHO;
     vsINSERTSELECT := vsINSERTSELECT || CHR(13) ||
                       'SELECT CASE WHEN PCMOV.DTCANCEL IS NOT NULL
                                    THEN ''AC''
                                    ELSE ''AE''
                               END TIPO
                             , PCMOV.SEQMOV
                             , CASE WHEN PCMOV.CODOPER = ''EP''
                                    THEN NVL(PCMOV.CUSTOULTENT, 0)
                                    ELSE NVL(PCMOV.CUSTOCONT, 0)
                               END BASECUSTOCONT
                             , PCMOV.CUSTOCONT
                             , PCMOV.CUSTOFIN
                             , PCMOV.CUSTOREAL
                             , PCMOV.CUSTOREP
                             , CASE WHEN PCMOV.CODOPER = ''EP''
                                    THEN NVL(PCMOV.CUSTOULTENT, 0)
                                    ELSE NVL(PCMOV.CUSTOCONT, 0)
                               END CUSTOULTENT
                             , PCMOV.CUSTOREALSEMST
                             , PCMOV.VALORULTENT
                             , NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                             , ''OP'' ESPECIE
                             , '''' SERIE
                             , null CODCONT
                             , DECODE( PCMOV.CODOPER, ''EA'', ''ENTRADA AJUSTE''
                                                    , ''EP'', ''ENTRADA PRODUÇÃO''
                                                    , ''EX'', ''DEV. AVULSA PRODUÇÃO''
                                                    , ''RA'', ''REQ. AVULSA PRODUÇÃO''
                                                    , ''SA'', ''SAÍDA AJUSTE''
                                                    , ''SP'', ''SAÍDA DE PRODUÇÃO''
                                                    , ''OUTRAS DE PRODUÇÃO'') OBSERVACAO
                             , PCMOV.CODPROD
                             , PCMOV.CODOPER
                             , CASE WHEN PCMOV.CODOPER LIKE ''E%''
                                    THEN NVL(PCMOV.NUMOP,PCMOV.NUMTRANSENT)
                                    ELSE NVL(PCMOV.NUMOP,PCMOV.NUMTRANSVENDA)
                               END NUMNOTA
                             , PCMOV.DTMOV DATA
                             , ' || SCRIPTHORAMINUTO('S', 'S')  || '
                             , PCMOV.CODFISCAL
                             , NVL(ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0) QTCONT
                             , NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || '), 0),  0) QTENTRADA
                             , NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', 0, ROUND(PCMOV.QTCONT, ' || TO_CHAR(parametros.NUMCASAS_QT) || ')), 0) QTSAIDA
                             , 0 QTSAIDA_DENTRO
                             , 0 QTSAIDA_FORA
                             , DECODE(PCMOV.CODOPER, ''EA'', ''ENTRADA AJUSTE''
                                                   , ''EP'', ''ENTRADA PRODUÇÃO''
                                                   , ''EX'', ''DEV. AVULSA PRODUÇÃO''
                                                   , ''RA'', ''REQ. AVULSA PRODUÇÃO''
                                                   , ''SA'', ''SAÍDA AJUSTE''
                                                   , ''SP'', ''SAÍDA DE PRODUÇÃO''
                                                   , ''OUTRAS DE PRODUÇÃO'') HISTORICO
                             , NVL(ROUND(PCMOV.PUNITCONT,' || TO_CHAR(parametros.NUMCASAS_UNIT) || '), 0) PUNITCONT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', PCMOV.PUNITCONT, 0) VALORITEMNOTA_ENT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', 0, PCMOV.PUNITCONT) VALORITEMNOTA_SAID
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', PCMOV.NUMTRANSENT, 0) NUMTRANSENT
                             , DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), ''E'', 0, PCMOV.NUMTRANSVENDA) NUMTRANSVENDA
                             , NVL(PCMOV.VLIPI, 0) VLIPI
                             , NVL(PCMOV.ST, 0) ST
                             , NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA
                             , PCMOV.DTCANCEL
                             , NULL SITUACAOTRIBUTARIA
                             , NULL TIPODESCARGA
                             , ' || SCRIPTHORAMINUTO('N', 'S')  || '
                             , PCMOV.CUSTOCONTANT
                             , NVL(PCMOV.ROTINACAD, PCMOV.ROTINALANC) ROTINA
                             , PCMOV.DTMOVLOG 
                             , PCMOV.QTESTANT                             
                          FROM PCMOV,
                               PCMOVCOMPLE
                         WHERE PCMOV.DTMOV BETWEEN '''|| parametros.DTINICIO ||''' AND ''' || parametros.DTFIM || '''
                           AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)= ''' || parametros.CODFILIAL||''''||CHR(13);
                           IF parametros.UTILIZOULISTAPRODUTO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND PCMOV.CODPROD IN (SELECT CODPROD FROM PCLISTAPROD_TMP)'||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 

                           IF parametros.DESCONS_USOCONSUMO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''CI'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT; 
                           
                           IF parametros.DESCONS_IMOBILIZADO = 'S' THEN
                              vsINSERTSELECT := vsINSERTSELECT||' AND NVL(PCMOV.TIPOMERCDEPTO, ''XX'') <> ''IM'' '||CHR(13);
                           END IF;                           
                           vsINSERTSELECT := vsINSERTSELECT ||'                             AND PCMOV.QTCONT < 0
                           AND PCMOV.DTCANCEL is not null
                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           AND PCMOV.CODOPER in (''EP'', ''SP'', ''EA'', ''SA'', ''EX'', ''RA'')
                           AND PCMOV.STATUS in (''A'', ''AB'')
                           '   ||pCodfiscal||' 
                           AND PCMOV.NUMNOTA BETWEEN '||parametros.NUMNOTA1||' AND '||parametros.NUMNOTA2||'     
                           AND NOT EXISTS (SELECT 1
                                             FROM PCNFSAID
                                            WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                              AND PCNFSAID.ESPECIE = ''NF''
                                              AND PCNFSAID.DTCANCEL IS NULL
                                              AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL)= ''' || parametros.CODFILIAL || '''
                                              AND PCNFSAID.VLTOTAL > 0)';
 --Gravar do Debug - Inicio
 --   INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, vsINSERTSELECT, 1);
 --   COMMIT;
 --Gravar do Debug - Fim
      EXECUTE IMMEDIATE vsINSERTSELECT;
   END;


  -- Gravando id do lançamento.
  -- ID utilizado para o cálculo do QTSALDO. Ele evita que um lançamento seja igual 
  -- para as colunas CODPROD, DTMOVLOG, DATA, SEQMOV, TIPO, NUMNOTA
  PROCEDURE OBTERID
  IS 
  BEGIN 
  BEGIN 
    FOR DADOS IN (SELECT TAB.CODPROD, 
                         TAB.DTMOVLOG, 
                         TAB.DATA, 
                         TAB.SEQMOV, 
                         TAB.TIPO, 
                         TAB.NUMNOTA, 
                         ROWID REGISTRO, 
                         ROWNUM ID 
                   FROM (SELECT T.CODPROD, T.DTMOVLOG, T.DATA, T.SEQMOV, T.TIPO, T.NUMNOTA
                           FROM PCDADOS1070_TEMP T 
                          ORDER BY T.CODPROD, T.DTMOVLOG, T.DATA, T.SEQMOV, T.TIPO, T.NUMNOTA) 
                          TAB)
        LOOP
                       UPDATE PCDADOS1070_TEMP SET 
      PCDADOS1070_TEMP.ID = DADOS.ID
            WHERE PCDADOS1070_TEMP.ROWID = DADOS.REGISTRO;
        END LOOP;
    END;
  END;
END;
----------------------------------------------------------------------------
-- Alt.: 26/07/2024 - Implementado ajuste nos sqls AE e SM para considerar 
--                    NVL no campo PCMOV.CODFISCAL 
----------------------------------------------------------------------------