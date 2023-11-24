create or replace procedure GERAR_CIAP(PCODFILIAL               in varchar2, -- 01
                                       PEXERCICIO               in number,   -- 02
                                       PRECALCULAR              in varchar2, -- 03
                                       PMSG                     out varchar2,-- 04
                                       PVALORCONTABIL           in varchar2, -- 05
                                       PVALORBASECALC           in varchar2, -- 06
                                       PVALOROUTRAS             in varchar2, -- 07
                                       PVALORISENAOTRIB         in varchar2, -- 08
                                       PVALORSUBSTTRIB          in varchar2, -- 08
                                       PVALORIPI                in varchar2, -- 09
                                       PCONSIDERARDIFALIQ       in varchar2, -- 10
                                       PCFOP_SAIDA_TRIB         in varchar2, -- 11 -- CFOP INSERIDO NO FILTRO POR CFOP (SAIDAS TRIBUTADAS)
                                       PDESCONSCFOP_SAIDA_TRIB  in varchar2, -- 12 -- PARAMETRO DESCONSIDERAR CFOPS NA TOTALIZAÇÃO.(SAIDAS TRIBUTADAS)
                                       PCFOP_SAIDA              in varchar2, -- 13 -- CFOP INSERIDO NA FILTRO POR CFOP (SAIDAS)
                                       PDESCONSIDERACFOP_SAIDA  in varchar2, -- 14 -- PARAMETRO DESCONSIDERAR CFOPS NA TOTALIZAÇÃO.(SAIDAS)
                                       PRECALCULARMES           in  NUMBER DEFAULT 0, -- 15
                                       PVUTILIZOUGRIDSAIDATRIB  in varchar2, -- 16
                                       PVUTILIZOUGRIDSAIDA      in varchar2, -- 17 
                                       PUTILIZAVALORCONTABIL    in VARCHAR2 DEFAULT 'N', -- 18 -- Define que a saida tributada será o vlcontabil quando parametro igual a SIM e vlbase zerado
                                       PCONS_CFOP_SAIDA_TRIB    in varchar2 DEFAULT 'N', -- 19 -- Define se o cfop da grid saida tributada será considerado no calculo
                                       PCONS_CFOP_TOT_SAIDA     in varchar2 DEFAULT 'N', -- 20 -- Define se o cfop da grid total saida será considerado no calculo
                                       PDEDUZIR_DEV_CLIENTE     in varchar2 DEFAULT 'N'  -- 21 -- Define se a devolução de cliente será deduzida dos valores tributados e saida
                                       ) is
   ------------------------------------------------------------------------
   -- Geração de dados para apuração do Livro CIAP
   -- Data criação: 18/06/2008

   -- Implementação de processos - Gleibe
   -- PROCESSO 1 : PROCEDIMENTO UTILIZANDO FILTRO POR CFOP DA TELA - TOTAL DAS SAIDAS TRIBUTADAS **** DESCONTINUADO
   -- PROCESSO 2 : PROCEDIMENTO UTILIZANDO FILTRO POR CFOP DA TELA - TOTAL DAS SAIDAS            **** DESCONTINUADO
   -- PROCESSO 3 : PROCEDIMENTO UTILIZANDO GRID POR CFOP - TOTAL DAS SAIDAS TRIBUTADAS e TOTAL DAS SAIDAS
   -- PROCESSO 5 : PROCEDIMENTO PARA GERAR SQL TOTALIZANDO OS VALORES QUANDO NÃO HÁ FILTROS INFORMADOS NA TELA OU NA GRID DE CFOPS
   -- PROCESSO 6 : PROCEDIMENTO PARA SOMAR AS ENTRADAS E DEDUZIR DO TOTAL DAS SAIDAS.
   -- PROCESSO 7 : PROCEDIMENTO PARA SOMAR AS ENTRADAS E DEDUZIR DO TOTAL DAS SAIDAS TRIBUTADAS.
   ------------------------------------------------------------------------
   V_QTMESESCIAP              number;
   V_MES                      number;
   V_TOTALSAIDAS              number;
   V_TOTALTRIBUTADAS          number;
   V_ENTRADATRIBUTADA         number;
   V_ENTRADATOTAL             number;
   V_SQL                      varchar2(16000);
   V_SQLETRI                  varchar2(16000);
   V_CFOP_SAIDA_TRIB          varchar2(6000);
   V_DESCONSCFOPSAITRIB       varchar2(1);
   V_CFOP_SAIDA               varchar2(6000);
   V_DESCONSIDERACFOPTLNOTA   varchar2(1);
   V_TIPOCALCULOCIAP          varchar2(1);
   V_GEROU_CIAPITEM           boolean;
   V_EXISTEFILTRO3403TOTSAI   VARCHAR2(1);
   V_EXISTEFILTRO3403SAITRIB  VARCHAR2(1);
   V_CONDICAOCFOPTOTSAI       VARCHAR2(8000);
   V_CONDICAOCFOPSAITRIB      VARCHAR2(8000);
   V_EXECUTAR                 VARCHAR2(1);
   V_TODOSPARAMETROS          VARCHAR2(1);
   V_ENCONTROU_CFOP_GRID      VARCHAR2(1);
   V_UTILIZOU_FILTROS         VARCHAR2(1); -- Variável que define se existe algum filtro definido pelo usuário na tela.
   V_AUX                      VARCHAR2(200);
   V_CODFISCALIN              VARCHAR2(200);
begin
   V_TODOSPARAMETROS := 'N';
   V_ENCONTROU_CFOP_GRID  := 'N';
   V_CODFISCALIN := 'CODFISCAL IN';
   ------------------------------------------------------------------------
   -- Tipo de cálculo do CIAP - "M" = Mensal ou "D" = Pro Rata Die
   V_TIPOCALCULOCIAP := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP',PCODFILIAL), 'M');
   ------------------------------------------------------------------------
   -- Atribuindo a quantidade limite de meses para calculo do CIAP
   select NVL(QTMESESCREDCIAP, 48) into V_QTMESESCIAP from PCCONSUM;
   ------------------------------------------------------------------------
   -- Apurar meses não apurados
   update PCCIAP
   set APURADO = 'S'
   where NVL(APURADO, 'N') = 'N'
     and ANO = PEXERCICIO
     and MES < EXTRACT(month from sysdate);
   ------------------------------------------------------------------------
   -- Se recalculo por exercicio deletar o exercicio.
   if PRECALCULARMES = 0 then
      delete from PCCIAP
      where CODFILIAL = PCODFILIAL
        and ANO = PEXERCICIO
        and (NVL(APURADO, 'N') = 'N' or PRECALCULAR = 'S');
   else
      -- Se recalculo por período, deletar somente período que sera reprocessado
      delete from PCCIAP
      where CODFILIAL = PCODFILIAL
        and ANO = PEXERCICIO
        and MES >= PRECALCULARMES
        and (NVL(APURADO, 'N') = 'N' or PRECALCULAR = 'S');
   end if;
   ------------------------------------------------------------------------
   if PRECALCULARMES = 0 then
      delete from PCCIAPITEM
      where CODFILIAL = PCODFILIAL
        and ANO = PEXERCICIO
        and (NVL(APURADO, 'N') = 'N' or PRECALCULAR = 'S');
   else
      delete from PCCIAPITEM
      where CODFILIAL = PCODFILIAL
        and ANO = PEXERCICIO
        and MES >= PRECALCULARMES
        and (NVL(APURADO, 'N') = 'N' or PRECALCULAR = 'S');
   end if;
   -- Percorrer todo o exercicio para calcular o CIAP
   ------------------------------------------------------------------------
   if PRECALCULAR = 'S' then
      if PRECALCULARMES > 0 then
         V_MES := PRECALCULARMES;
      else
          V_MES := 1;
      end if;
   else
      if EXTRACT(year from sysdate) = PEXERCICIO  then
         V_MES := EXTRACT(month from sysdate);
      else
         V_MES := 13;
      end if;
   end if;
   -- Iniciando variaveis
   V_TOTALSAIDAS      := 0;
   V_TOTALTRIBUTADAS  := 0;
   V_ENTRADATRIBUTADA := 0;
   V_ENTRADATOTAL     := 0;
   V_SQL := '';
   V_UTILIZOU_FILTROS   := 'N'; -- Iniciando variável sobre filtros na tela.

   while V_MES <= 12
   loop
      V_EXISTEFILTRO3403TOTSAI := 'N';
      begin
         begin
--------------------------------------------------------------------------------------------
      -- Select para busca dos valores das saídas para calculo do CIAP
      V_CFOP_SAIDA_TRIB        := PCFOP_SAIDA_TRIB;
      V_DESCONSCFOPSAITRIB     := PDESCONSCFOP_SAIDA_TRIB;
      V_CFOP_SAIDA             := PCFOP_SAIDA;
      V_DESCONSIDERACFOPTLNOTA := PDESCONSIDERACFOP_SAIDA;

      if PCFOP_SAIDA_TRIB is null then
         V_CFOP_SAIDA_TRIB        := '-1';
--               V_DESCONSCFOPSAITRIB := 'S';
      end if;

      if PCFOP_SAIDA is null then
         V_CFOP_SAIDA             := '-1';
--               V_DESCONSIDERACFOPTLNOTA := 'S';
      end if;

--------------------------------------------------------------------------------------------
-- PROCESSO 1 : INICIO DO PROCEDIMENTO UTILIZANDO FILTRO POR CFOP DA TELA - TOTAL DAS SAIDAS TRIBUTADAS
--------------------------------------------------------------------------------------------
     if (PCFOP_SAIDA_TRIB is not null) and (V_CFOP_SAIDA_TRIB <> '-1') then
         V_TODOSPARAMETROS := 'S';  -- Esse parâmetro determina a passagem de todos os parâmetros ou não na na execução da sql montado.
         V_UTILIZOU_FILTROS := 'S'; -- Esse parâmetro determina se será montado no final um sql totalizando as movimentações ou não, pois em caso de não ter nenhum filtro informado, será usado essa opção para gerar o sql geral.

         -- Configurando Total das saidas tributadas utilizado filtros da tela
         if (V_DESCONSCFOPSAITRIB = 'S') then
            V_SQL := 'select SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN (' || V_CFOP_SAIDA_TRIB || ') THEN
                                    0
                                 ELSE
                                    DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +
                              
                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0      
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) +                                     
                                    DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                    DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                    DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                    DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)
                                 END) TOTALTRIB,';
         else
            V_SQL := 'select SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN (' || V_CFOP_SAIDA_TRIB || ') THEN
                                    DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +
                                    
                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0      
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) +                                     
                                                                            
                                    DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                    DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                    DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                    DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)
                                 ELSE
                                    0
                                 END) TOTALTRIB,
                                 -------------------------------------------------------------
                                 ';
      end if;
         -- CONFIGURANDO TOTAL DAS SAIDAS
         -- Se desconsiderar estiver marcado na tela e cfop preenchido
         IF (V_DESCONSIDERACFOPTLNOTA = 'S') and (V_CFOP_SAIDA <> '-1') THEN
             V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN ( ' || V_CFOP_SAIDA || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                               0
                                            ELSE ';
                V_SQL := V_SQL || ' NVL(PCNFBASESAID.VLDESDOBRADO, 0) END), 0) TOTALSAIDAS ';
         END IF;
         --------------------------------//-----------------------------------
         -- Se desconsiderar estiver desmarcado na tela e cfop preenchido
         IF (V_DESCONSIDERACFOPTLNOTA = 'N') and (V_CFOP_SAIDA <> '-1') THEN
             V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN ( ' || V_CFOP_SAIDA || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                               NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                            ELSE
                                               0
                                            END), 0) TOTALSAIDAS ';
         END IF;
         --------------------------------//-----------------------------------
         -- Se desconsiderar estiver desmarcado ou não e nenhum cfop preenchido na tela.
         IF (V_DESCONSIDERACFOPTLNOTA = 'S' or V_DESCONSIDERACFOPTLNOTA = 'N') and (V_CFOP_SAIDA = '-1') THEN
             V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN PCNFBASESAID.CODFISCAL > 0 AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                               NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                            ELSE
                                               NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                            END), 0) TOTALSAIDAS ';
         END IF;
     end if;
--------------------------------------------------------------------------------------------
-- FIM DO PROCESSO 1
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- PROCESSO 2 : INICIO DO PROCEDIMENTO UTILIZANDO FILTRO POR CFOP DA TELA - TOTAL DAS SAIDAS
--------------------------------------------------------------------------------------------
     if (PCFOP_SAIDA is not null) and (V_CFOP_SAIDA <> '-1') then
         -- Valores dos totais de tributação
         V_TODOSPARAMETROS := 'S';
         V_UTILIZOU_FILTROS := 'S';

         -- Configurando Saida Tributada (desconsiderando)
         if (V_DESCONSCFOPSAITRIB = 'S') and (V_CFOP_SAIDA_TRIB <> '-1') then
             V_SQL := 'select SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN (' || V_CFOP_SAIDA_TRIB || ') THEN
                                     0
                                  ELSE
                                     DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +

                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0      
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) + 
                                                                        
                                     DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                     DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                     DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                     DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)
                                  END) TOTALTRIB,';

         end if;
         ---------------------------------//----------------------------------

         -- Configurando Saida Tributada (Considerando)
         if (V_DESCONSCFOPSAITRIB = 'N') and (V_CFOP_SAIDA_TRIB <> '-1') then
             V_SQL := 'select SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN (' || V_CFOP_SAIDA_TRIB || ') THEN
                                     DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +

                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0      
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) + 
                                                                        
                                     DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                     DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                     DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                     DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)
                                  ELSE
                                     0
                                  END) TOTALTRIB,';
         end if;
         ---------------------------------//----------------------------------

         -- Configurando Saida Tributada total. Quando não foi informado nenhum cfop na tela
         if ( V_DESCONSCFOPSAITRIB = 'N' or  V_DESCONSCFOPSAITRIB = 'S' ) and (V_CFOP_SAIDA_TRIB = '-1') then
              V_SQL := 'select SUM(CASE WHEN PCNFBASESAID.CODFISCAL > 0 THEN
                                        DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +

                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0      
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) + 
                                                                        

                                        DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                        DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                        DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                        DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)
                                    ELSE
                                       0
                                    END) TOTALTRIB,';
         end if;
         ---------------------------------//----------------------------------

         -- CONFIGURANDO TOTAL DAS SAIDAS
         -- Se desconsiderar estiver marcado na tela e cfop preenchido
         IF (V_DESCONSIDERACFOPTLNOTA = 'S') and (V_CFOP_SAIDA <> '-1') THEN
             V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN ( ' || V_CFOP_SAIDA || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                               0
                                            ELSE ';
                V_SQL := V_SQL || ' NVL(PCNFBASESAID.VLDESDOBRADO, 0) END), 0) TOTALSAIDAS ';
         END IF;
         --------------------------------//-----------------------------------
         -- Se desconsiderar estiver desmarcado na tela e cfop preenchido
         IF (V_DESCONSIDERACFOPTLNOTA = 'N') and (V_CFOP_SAIDA <> '-1') THEN
             V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN ( ' || V_CFOP_SAIDA || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                               NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                            ELSE
                                               0
                                            END), 0) TOTALSAIDAS ';
         END IF;
         --------------------------------//-----------------------------------
         -- Se desconsiderar estiver desmarcado e nenhum cfop preenchido na tela.
         IF (V_DESCONSIDERACFOPTLNOTA = 'S' or V_DESCONSIDERACFOPTLNOTA = 'N') and (V_CFOP_SAIDA = '-1') THEN
             V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN PCNFBASESAID.CODFISCAL > 0 AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                               NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                            ELSE
                                               NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                            END), 0) TOTALSAIDAS ';
         END IF;
         --------------------------------//-----------------------------------
     end if;
--------------------------------------------------------------------------------------------
-- FIM DO PROCESSO 2
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- PROCESSO 3 : INICIO DO PROCEDIMENTO UTILIZANDO GRID POR CFOP - TOTAL DAS SAIDAS TRIBUTADAS
--------------------------------------------------------------------------------------------
   if ((PCFOP_SAIDA_TRIB is null) and 
       (PVUTILIZOUGRIDSAIDATRIB = 'S' or 
        PVUTILIZOUGRIDSAIDA = 'S')) then
            --------------------------------------------------------------------------------
            -- GRID CFOP DAS SAÍDAS TRIBUTADAS
            IF ( PVUTILIZOUGRIDSAIDATRIB = 'S') THEN
                 V_CONDICAOCFOPSAITRIB := '';
                 V_EXISTEFILTRO3403SAITRIB := 'N';
                 V_TODOSPARAMETROS := 'N';
               -----------------------------------------------------------------------------
               -- CFOP Grid de Saídas Tributadas
               for dados in (SELECT to_char((SELECT TO_NUMBER(VALOR_NUM) AS CODFISCAL
                                             FROM PCDADOSGENERICOS
                                             WHERE DADOSID = 'SAITRI'
                                               AND CAMPO = 'CODFISCAL'
                                               AND CODREGISTRO = ITENS.CODREGISTRO)) CODFISCAL,
                                    to_char(substr(LPAD((SELECT TO_NUMBER(VALOR_TEXTO) CODFISCAL
                                                         FROM PCDADOSGENERICOS
                                                         WHERE DADOSID = 'SAITRI'
                                                         AND CAMPO = 'CSTICMS'
                                                         AND CODREGISTRO = ITENS.CODREGISTRO),3,'0'),2,2))  CSTICMS
                             FROM (SELECT COUNT(*) QUANTIDADE, CODREGISTRO, DADOSID
                                   FROM PCDADOSGENERICOS
                                   WHERE DADOSID = 'SAITRI'
                                   GROUP BY CODREGISTRO, DADOSID) ITENS)
               LOOP
                  IF V_EXISTEFILTRO3403SAITRIB = 'S' THEN
                     IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                        V_AUX := ' OR (PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ')) ';
                     ELSE
                        V_AUX := ' OR (PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                     END IF;
                  ELSE
                     IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                        V_AUX := '(PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ') ) ';
                     ELSE
                        V_AUX := '(PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                     END IF;
                  END IF;
                  V_CONDICAOCFOPSAITRIB := V_CONDICAOCFOPSAITRIB || V_AUX;
                  V_AUX := '';
                  V_EXISTEFILTRO3403SAITRIB := 'S';
               END LOOP;
               -----------------------------------------------------------------------------
               IF V_EXISTEFILTRO3403SAITRIB = 'N' THEN
                  V_SQL := 'select SUM(CASE WHEN PCNFBASESAID.CODFISCAL IN (' || V_CFOP_SAIDA_TRIB ||') AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN ';
               -- Gerando vltrib analisando parametros 
                  IF PVALORCONTABIL = 'S' THEN
                     V_SQL := V_SQL || ' NVL(PCNFBASESAID.VLDESDOBRADO, 0) END) TOTALTRIB,';
                   else 
                    V_TODOSPARAMETROS := 'P';                   
                     V_SQL := V_SQL || '
                     (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL( PCNFBASESAID.VLBASE,0) = 0 THEN 
                               DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                          ELSE 
                               DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) END    +
                                     DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                     DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                     DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                     DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)) TOTALTRIB,';
                   end if;
                --------------     
               ELSE
                 ------------------------------------- // --------------------------------------- 
                  IF PCONS_CFOP_SAIDA_TRIB = 'S' THEN -- Abrindo 1
                      V_SQL := 'select SUM(CASE WHEN ( ' || V_CONDICAOCFOPSAITRIB || ' ) 
                                          AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - 
                                                NVL(PCNFBASESAID.VLOUTRAS, 0) - 
                                                NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN ';
                      
                      IF PVALORCONTABIL = 'S' THEN
                         V_SQL := V_SQL || ' NVL(PCNFBASESAID.VLDESDOBRADO, 0) END) TOTALTRIB,';
                      ELSE
                        V_TODOSPARAMETROS := 'P';
                         V_SQL := V_SQL || '
                         (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                        DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                                   ELSE 
                                        DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) END    +
                                         DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                         DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                         DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                         DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)) TOTALTRIB,';
                      END IF;  
                      
                  ELSE
                 
                  V_SQL := 'select SUM(CASE WHEN ( ' || V_CONDICAOCFOPSAITRIB || ' ) 
                                      AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - 
                                            NVL(PCNFBASESAID.VLOUTRAS, 0) - 
                                            NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                           0
                                        ELSE ';

               -- Gerando vltrib analisando parametros 
                  IF PVALORCONTABIL = 'S' THEN
                     V_SQL := V_SQL || ' NVL(PCNFBASESAID.VLDESDOBRADO, 0) END) TOTALTRIB,';
                  ELSE
                    V_TODOSPARAMETROS := 'P';
                     V_SQL := V_SQL || '
                     (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) END    +
                                       DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                       DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                       DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                       DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)) TOTALTRIB,';
                     
                   END IF;
                 END IF; -- Fechando 1
                 ------------------------------------- // --------------------------------------- 
               END IF;
            else -- Se não utilizou Grid Saida tributada, então será gerado todos os cfops.
                V_TODOSPARAMETROS := 'S';
                V_SQL := 'select SUM(   DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +

                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0      
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE 
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) + 
                                    DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                                    DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                                    DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                                    DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)
                                        ) TOTALTRIB,
                                        ------------------------------
                                        ';

            end if;

            -- CALCULADO DO TOTAL DA SAIDA - UTILIZANDO A GRID
            IF ( PVUTILIZOUGRIDSAIDA = 'S' ) THEN
                 V_CONDICAOCFOPTOTSAI := '';
                 V_EXISTEFILTRO3403TOTSAI := 'N';
               -----------------------------------------------------------------------------
               for dados in (SELECT to_char((SELECT TO_NUMBER(VALOR_NUM) AS CODFISCAL
                                             FROM PCDADOSGENERICOS
                                             WHERE DADOSID = 'CFOPCI'
                                               AND CAMPO = 'CODFISCAL'
                                               AND CODREGISTRO = ITENS.CODREGISTRO)) CODFISCAL,
                                    to_char(substr(LPAD((SELECT TO_NUMBER(VALOR_TEXTO) CODFISCAL
                                                         FROM PCDADOSGENERICOS
                                                         WHERE DADOSID = 'CFOPCI'
                                                         AND CAMPO = 'CSTICMS'
                                                         AND CODREGISTRO = ITENS.CODREGISTRO),3,'0'),2,2))  CSTICMS
                             FROM (SELECT COUNT(*) QUANTIDADE, CODREGISTRO, DADOSID
                                   FROM PCDADOSGENERICOS
                                   WHERE DADOSID = 'CFOPCI'
                                   GROUP BY CODREGISTRO, DADOSID) ITENS)
               LOOP
                  IF V_EXISTEFILTRO3403TOTSAI = 'S' THEN
                     IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                        V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI || ' OR (PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ')) ';
                     ELSE
                        V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI || ' OR (PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                     END IF;
                  ELSE
                     IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                        V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI || '(PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ') ) ';
                     ELSE
                        V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI || '(PCNFBASESAID.CODFISCAL IN (' || DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                     END IF;
                  END IF;

                  V_EXISTEFILTRO3403TOTSAI := 'S';
               END LOOP;
               -----------------------------------------------------------------------------
               IF V_EXISTEFILTRO3403TOTSAI = 'N' THEN
                  V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN CODFISCAL IN ( ' || V_CFOP_SAIDA || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                                 NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)
                                              ELSE
                                                 NVL(PCNFBASESAID.VLDESDOBRADO, 0)
                                              END), 0) TOTALSAIDAS ';
               ELSE
                  
                  IF PCONS_CFOP_TOT_SAIDA = 'S' THEN -- Abrindo 2
                     V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN ( ' || V_CONDICAOCFOPTOTSAI || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN ';
                     V_SQL := V_SQL || ' NVL(PCNFBASESAID.VLDESDOBRADO, 0) END), 0) TOTALSAIDAS ';
                  else 
                     
                     V_SQL :=  V_SQL || 'NVL(SUM(CASE WHEN ( ' || V_CONDICAOCFOPTOTSAI || ' ) AND ((NVL(PCNFBASESAID.VLDESDOBRADO, 0) - NVL(PCNFBASESAID.VLOUTRAS, 0) - NVL(PCNFBASESAID.VLISENTAS, 0)) >= 0) THEN
                                                         0
                                                 ELSE ';
                  V_SQL := V_SQL || '                   NVL(PCNFBASESAID.VLDESDOBRADO, 0) END), 0) TOTALSAIDAS ';
                  
                END IF; -- Fechando 2
                  
                  
               END IF;
       else -- Se não utilizou a grid total saidas, então deve-se gerar todos os cfops.
               V_SQL :=  V_SQL || 'SUM(NVL(PCNFBASESAID.VLDESDOBRADO,0)) TOTALSAIDAS ';
       end if;

       V_UTILIZOU_FILTROS := 'S'; -- Se V_SQL estiver preenchido, a variavel abaixo deve receber "S" para não gerar sql em duplicidade.
  end if;
--------------------------------------------------------------------------------------------
-- FIM DO PROCESSO 3
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- PROCESSO 5 : INICIO DO PROCEDIMENTO PARA GERAR SQL TOTALIZANDO OS VALORES QUANDO NÃO HÁ FILTROS INFORMADOS NA TELA
--------------------------------------------------------------------------------------------
   if V_UTILIZOU_FILTROS = 'N' then
      V_TODOSPARAMETROS := 'S';
      V_SQL := 'select SUM(   DECODE(:PVALORCONTABIL, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0) +

                              -- Considerar vldesdobrado quando parametro SIM e vlbase = 0
                              (CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASESAID.VLBASE,0) = 0 THEN
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLDESDOBRADO, 0), 0)
                               ELSE
                                    DECODE(:PVALORBASECALC, ''S'', NVL(PCNFBASESAID.VLBASE, 0), 0) END) +

                              DECODE(:PVALOROUTRAS, ''S'', NVL(PCNFBASESAID.VLOUTRAS, 0), 0)       +
                              DECODE(:PVALORISENAOTRIB, ''S'', NVL(PCNFBASESAID.VLISENTAS, 0), 0)  +
                              DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASESAID.VLST, 0), 0)        +
                              DECODE(:PVALORIPI, ''S'', NVL(PCNFBASESAID.VLIPI, 0), 0)) TOTALTRIB, ';
      V_SQL :=  V_SQL || ' SUM(NVL(PCNFBASESAID.VLDESDOBRADO,0)) TOTALSAIDAS ';
   end if;
--------------------------------------------------------------------------------------------
-- FIM DO PROCESSO 5
--------------------------------------------------------------------------------------------
  V_SQL := V_SQL ||
     '------------------------
      from PCNFBASESAID
     where EXTRACT(year from PCNFBASESAID.DTSAIDA) = :PEXERCICIO
       and EXTRACT(month from PCNFBASESAID.DTSAIDA) = :V_MES
       and PCNFBASESAID.CODFILIALNF = :PCODFILIAL
       and PCNFBASESAID.ESPECIE <> ''MR''
       and PCNFBASESAID.DTCANCEL IS NULL 
       and PCNFBASESAID.CODFISCAL BETWEEN 5000 AND 7999
       and ((PCNFBASESAID.VLDESDOBRADO > 0 ) or (PCNFBASESAID.VLICMS > 0) or (PCNFBASESAID.VLBASE > 0))
       and NVL(PCNFBASESAID.SERIE, ''X'') not in (''CF'', ''CP'')';

         V_EXECUTAR := 'N';
         IF PDESCONSCFOP_SAIDA_TRIB = 'S' OR PDESCONSIDERACFOP_SAIDA = 'S' THEN
            V_EXECUTAR := 'S';
         END IF;

         IF V_TODOSPARAMETROS = 'N' THEN
            execute immediate V_SQL
               into V_TOTALTRIBUTADAS, V_TOTALSAIDAS
               using PEXERCICIO, 
                     V_MES, 
                     PCODFILIAL;
          END IF;

         -- Se parametro igual a Sim 
         IF V_TODOSPARAMETROS = 'S' THEN
            execute immediate V_SQL
               into V_TOTALTRIBUTADAS, V_TOTALSAIDAS
              using PVALORCONTABIL,
                    PUTILIZAVALORCONTABIL,
                    PVALORBASECALC, 
                    PVALORBASECALC,                     
                    PVALOROUTRAS, 
                    PVALORISENAOTRIB, 
                    PVALORSUBSTTRIB,
                    PVALORIPI, 
                    PEXERCICIO, 
                    V_MES, 
                    PCODFILIAL;
         END IF;
         
         -- 
         IF V_TODOSPARAMETROS = 'T' THEN
            execute immediate V_SQL
               into V_TOTALTRIBUTADAS, V_TOTALSAIDAS
               using PUTILIZAVALORCONTABIL,
                     PVALORBASECALC, 
                     PVALORBASECALC, 
                     PEXERCICIO, 
                     V_MES, 
                     PCODFILIAL;
          END IF; 
          
         IF V_TODOSPARAMETROS = 'P' THEN
            execute immediate V_SQL
               into V_TOTALTRIBUTADAS, V_TOTALSAIDAS
              using PUTILIZAVALORCONTABIL,
                    PVALORBASECALC, 
                    PVALORBASECALC,                     
                    PVALOROUTRAS, 
                    PVALORISENAOTRIB, 
                    PVALORSUBSTTRIB,
                    PVALORIPI, 
                    PEXERCICIO, 
                    V_MES, 
                    PCODFILIAL;
         END IF;
         

-------------------------------------------------------------------------------------------------
-- PROCESSO 6 : PROCEDIMENTO PARA SOMAR AS ENTRADAS E DEDUZIR DO TOTAL DAS SAIDAS.
-------------------------------------------------------------------------------------------------
         IF PDEDUZIR_DEV_CLIENTE = 'S' THEN

            V_CONDICAOCFOPTOTSAI := '';
            V_CONDICAOCFOPSAITRIB := '';
            V_EXISTEFILTRO3403TOTSAI := 'N';
            V_EXISTEFILTRO3403SAITRIB := 'N';
            V_SQLETRI := '';
            V_ENTRADATOTAL := 0;
            --------------------------------------------------------------
            -- CFOP Grid de Total das Saídas
            IF PVUTILIZOUGRIDSAIDA = 'S' THEN -- Abriu Ponto1
                for dados in (SELECT to_char((SELECT TO_NUMBER(VALOR_NUM) CODFISCAL
                                              FROM PCDADOSGENERICOS
                                              WHERE DADOSID = 'CFOPCI'
                                                AND CAMPO = 'CODFISCAL'
                                                AND CODREGISTRO = ITENS.CODREGISTRO)) CODFISCAL,
                                     to_char(substr(LPAD((SELECT TO_NUMBER(VALOR_TEXTO) CODFISCAL
                                                          FROM PCDADOSGENERICOS
                                                          WHERE DADOSID = 'CFOPCI'
                                                            AND CAMPO = 'CSTICMS'
                                                            AND CODREGISTRO = ITENS.CODREGISTRO),3,'0'),2,2))  CSTICMS
                              FROM (SELECT COUNT(*) QUANTIDADE, CODREGISTRO, DADOSID
                                    FROM PCDADOSGENERICOS
                                    WHERE DADOSID = 'CFOPCI'
                                    GROUP BY CODREGISTRO, DADOSID) ITENS)
                LOOP
                   IF PDESCONSCFOP_SAIDA_TRIB = 'S' THEN
                     V_CODFISCALIN := 'CODFISCAL <> ';
                   ELSE
                     V_CODFISCALIN := 'CODFISCAL IN';
                   END IF;           
                 
                   IF V_EXISTEFILTRO3403TOTSAI = 'S' THEN
                      IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                        IF PDESCONSCFOP_SAIDA_TRIB = 'S' THEN
                          V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI  ||  ' AND CODFISCAL <> ' ||  DADOS.CODFISCAL; 
                        ELSE
                          V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI  ||  ' OR ('|| V_CODFISCALIN ||' (' ||  DADOS.CODFISCAL || ')) ';
                        END IF;
                      ELSE
                        IF PDESCONSCFOP_SAIDA_TRIB = 'S' THEN
                          V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI  ||  ' AND (CODFISCAL <> ' ||  DADOS.CODFISCAL || ' AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) ))';
                        ELSE
                          V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI  ||  ' OR ('|| V_CODFISCALIN ||' (' ||  DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                        END IF;
                      END IF;
                   ELSE
                      IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                         V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI ||  '('|| V_CODFISCALIN ||' (' || DADOS.CODFISCAL || ') ) ';
                      ELSE
                         V_CONDICAOCFOPTOTSAI := V_CONDICAOCFOPTOTSAI ||  '('|| V_CODFISCALIN ||' (' || DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                      END IF;
                   END IF;
    
                   V_EXISTEFILTRO3403TOTSAI := 'S';
    
                   if DADOS.CODFISCAL > 0 then
                      V_ENCONTROU_CFOP_GRID := 'S';
                   end if ;
    
                END LOOP;
            END IF; -- Fechou Ponto1

            V_SQLETRI := 'SELECT NVL(SUM(NVL(VLDESDOBRADO,0)),0) ';                   
            
            V_SQLETRI := V_SQLETRI ||
                         'from PCNFBASEENT
                         where EXTRACT(year from dtentrada) = :PEXERCICIO
                           and EXTRACT(month from dtentrada) = :V_MES
                           and CODFILIALNF = :PCODFILIAL
                           and TIPODESCARGA IN (''6'',''8'',''T'')';
                             
                IF ((PVUTILIZOUGRIDSAIDA = 'S') and (V_ENCONTROU_CFOP_GRID = 'S')) THEN
                   V_SQLETRI := V_SQLETRI || ' AND  (' || V_CONDICAOCFOPTOTSAI || ' ) ';
                END IF;

--        INSERT INTO SQL_GERADO (TEXTO_SQL) VALUES (V_SQLETRI);

                execute immediate V_SQLETRI
                   into V_ENTRADATOTAL
                   using PEXERCICIO, V_MES, PCODFILIAL;

         -- Mudar variavel para N caso esteja como Sim, para ser utilizada no processo abaixo.
         IF V_ENCONTROU_CFOP_GRID = 'S' THEN
            V_ENCONTROU_CFOP_GRID := 'N';
         END IF;
     END IF; -- Fechando IF ref. Dedução.
-------------------/------------------------------------------------------------------------------
-- PROCESSO 6 : FIM
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
-- PROCESSO 7 : PROCEDIMENTO PARA SOMAR AS ENTRADAS E DEDUZIR DO TOTAL DAS SAIDAS TRIBUTADAS.
-------------------------------------------------------------------------------------------------
  IF PDEDUZIR_DEV_CLIENTE = 'S' THEN
        V_CONDICAOCFOPTOTSAI := '';
        V_CONDICAOCFOPSAITRIB := '';
        V_EXISTEFILTRO3403TOTSAI := 'N';
        V_EXISTEFILTRO3403SAITRIB := 'N';
        V_SQLETRI := '';
        V_SQL := '';
        V_ENTRADATRIBUTADA := 0;
            --------------------------------------------------------------
            -- CFOP Grid de Total das Saídas Trib 
        IF PVUTILIZOUGRIDSAIDATRIB = 'S' THEN -- Abriu Ponto1
            for dados in (SELECT to_char((SELECT TO_NUMBER(VALOR_NUM) CODFISCAL
                                          FROM PCDADOSGENERICOS
                                          WHERE DADOSID = 'SAITRI'
                                            AND CAMPO = 'CODFISCAL'
                                            AND CODREGISTRO = ITENS.CODREGISTRO)) CODFISCAL,
                                 to_char(substr(LPAD((SELECT TO_NUMBER(VALOR_TEXTO) CODFISCAL
                                                      FROM PCDADOSGENERICOS
                                                      WHERE DADOSID = 'SAITRI'
                                                        AND CAMPO = 'CSTICMS'
                                                        AND CODREGISTRO = ITENS.CODREGISTRO),3,'0'),2,2))  CSTICMS
                          FROM (SELECT COUNT(*) QUANTIDADE, CODREGISTRO, DADOSID
                                FROM PCDADOSGENERICOS
                                WHERE DADOSID = 'SAITRI'
                                GROUP BY CODREGISTRO, DADOSID) ITENS)
            LOOP
             IF PDESCONSCFOP_SAIDA_TRIB = 'S' THEN
                 V_CODFISCALIN := 'CODFISCAL <> ';
               ELSE
                 V_CODFISCALIN := 'CODFISCAL IN';
               END IF;             

               IF V_EXISTEFILTRO3403TOTSAI = 'S' THEN
                  IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                    IF PDESCONSCFOP_SAIDA_TRIB = 'S' THEN
                      V_AUX := ' AND CODFISCAL <> ' ||  DADOS.CODFISCAL; 
                    ELSE
                      V_AUX := ' OR ('|| V_CODFISCALIN ||' (' ||  DADOS.CODFISCAL || ')) ';
                    END IF;
                  ELSE
                    IF PDESCONSCFOP_SAIDA_TRIB = 'S' THEN
                      V_AUX := ' AND (CODFISCAL <> ' ||  DADOS.CODFISCAL || ' AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) ))';
                    ELSE
                      V_AUX := ' OR ('|| V_CODFISCALIN ||' (' ||  DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                    END IF;
                  END IF;
               ELSE
                  IF NVL(TRIM(DADOS.CSTICMS),'N') = 'N' THEN
                     V_AUX := '('|| V_CODFISCALIN ||' (' || DADOS.CODFISCAL || ') ) ';
                  ELSE
                     V_AUX := '('|| V_CODFISCALIN ||' (' || DADOS.CODFISCAL || ') AND (DECODE(SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),1,1),0,SUBSTR(LPAD(NVL(SITTRIBUT,0),3,''0''),2,2),NVL(SITTRIBUT,0)) IN (' || DADOS.CSTICMS || ' ) )) ';
                  END IF;
               END IF;
               V_CONDICAOCFOPSAITRIB := V_CONDICAOCFOPSAITRIB || V_AUX;
               V_AUX := '';
               V_EXISTEFILTRO3403TOTSAI := 'S';

               if DADOS.CODFISCAL > 0 then
                  V_ENCONTROU_CFOP_GRID := 'S';
               end if ;

            END LOOP;
        END IF; -- Fechou Ponto1
            
        IF PVALORBASECALC = 'S' THEN
        V_SQLETRI := 'SELECT SUM((CASE WHEN :PUTILIZAVALORCONTABIL = ''S'' AND NVL(PCNFBASEENT.VLBASE,0) = 0 THEN 
                                       DECODE(:PVALORBASECALC,  ''S'', NVL(PCNFBASEENT.VLDESDOBRADO, 0), 0)
                                  ELSE 
                                       DECODE(:PVALORBASECALC,  ''S'', NVL(PCNFBASEENT.VLBASE, 0), 0)   +                                     
                                       DECODE(:PVALOROUTRAS,    ''S'', NVL(PCNFBASEENT.VLOUTRAS, 0), 0) +
                                       DECODE(:PVALORISENAOTRIB,''S'', NVL(PCNFBASEENT.VLISENTAS, 0), 0)+
                                       DECODE(:PVALORSUBSTTRIB, ''S'', NVL(PCNFBASEENT.VLST, 0), 0)     +
                                       DECODE(:PVALORIPI,       ''S'', NVL(PCNFBASEENT.VLIPI, 0), 0)
                                END)) VLENTRADATRIBUTADA ';
        ELSE
           V_SQLETRI := 'SELECT NVL(SUM(NVL(VLDESDOBRADO,0)),0) ';
        END IF;
        
        V_SQLETRI := V_SQLETRI ||
                  'from PCNFBASEENT
                   where EXTRACT(year from dtentrada) = :PEXERCICIO
                     and EXTRACT(month from dtentrada) = :V_MES
                     and CODFILIALNF = :PCODFILIAL
                     and ESPECIE <> ''MR''
                     and TIPODESCARGA IN (''6'',''8'',''T'')
                     and NVL(SERIE, ''X'') not in (''CF'', ''CP'') ';

        IF (PVUTILIZOUGRIDSAIDATRIB = 'S' and V_ENCONTROU_CFOP_GRID = 'S') THEN
          V_SQLETRI := V_SQLETRI || ' AND  (' || V_CONDICAOCFOPSAITRIB || ' ) ';
        END IF;
        
        --INSERT INTO SQL_GERADO (TEXTO_SQL) VALUES (V_SQLETRI);
        
         IF PVALORBASECALC = 'S' THEN
           execute immediate V_SQLETRI
           into V_ENTRADATRIBUTADA
          using PUTILIZAVALORCONTABIL,
                PVALORBASECALC,
                PVALORBASECALC,                     
                PVALOROUTRAS, 
                PVALORISENAOTRIB, 
                PVALORSUBSTTRIB,
                PVALORIPI, 
                PEXERCICIO, 
                V_MES, 
                PCODFILIAL;
          ELSE
           execute immediate V_SQLETRI
           into V_ENTRADATRIBUTADA
           using PEXERCICIO, V_MES, PCODFILIAL;          
          END IF;                
  END IF;
-------------------------------------------------------------------------------------------------
-- PROCESSO 7 : FIM
-------------------------------------------------------------------------------------------------
  end;--fim do primerio loop

      exception
      when NO_DATA_FOUND then
        begin
          V_TOTALTRIBUTADAS  := 0;
          V_TOTALSAIDAS      := 0;
          V_ENTRADATRIBUTADA := 0;
          V_ENTRADATOTAL     := 0;
        end;
      end;
      --------------------------------------------------------------------
      --------------------------------------------------------------------
      -- Cálculo das colunas de "Saídas Tributadas" e "Total Saídas
      V_TOTALTRIBUTADAS := V_TOTALTRIBUTADAS - V_ENTRADATRIBUTADA;
      IF V_TOTALTRIBUTADAS <= 0 THEN
         V_TOTALTRIBUTADAS :=0;
      END IF; 
            
      V_TOTALSAIDAS := V_TOTALSAIDAS - V_ENTRADATOTAL;
      IF V_TOTALSAIDAS <= 0 THEN
         V_TOTALSAIDAS :=0;
      END IF;
      -- Calcular valores mensais a partir dos dados acima
      ------------------------------------------------------------------------
      insert into PCCIAPITEM(CODITEM,
                             CODFILIAL,
                             MES,
                             ANO,
                             CODPROD,
                             CODPRODSEQ,
                             NUMTRANSENT,
                             TIPOTRANSACAO,
                             VLBASECREDITO,
                             VLCREDITO,
                             FATOR,
                             APURADO,
                             DATAINICIOCIAP,
                             DATAFINALCIAP,
                             DATABAIXA)
         SELECT DFSEQ_PCCIAPITEM.nextval,
                PCODFILIAL,
                V_MES,
                PEXERCICIO,
                S.CODPROD,
                S.CODPRODSEQ, 
                S.TRANSACAO,
                S.TIPOTRANSACAO,
                NVL(S.VLCREDITO, 0),
                ROUND(DECODE(V_TOTALSAIDAS, 0, 0,
                             V_TOTALTRIBUTADAS / V_TOTALSAIDAS), 8) *
                      DECODE(NVL(QTMESESCREDCIAP, V_QTMESESCIAP), 0, 0,
                             NVL(S.VLCREDITO, 0) * (1 / GREATEST(NVL(QTMESESCREDCIAP, V_QTMESESCIAP), 1))) VLCREDITO,
                '1/' || TO_CHAR(GREATEST(NVL(QTMESESCREDCIAP, V_QTMESESCIAP), 1)) FATOR,
                (CASE WHEN TO_DATE('01/' || V_MES || '/' || PEXERCICIO, 'DD/MM/YYYY') < TRUNC(SYSDATE, 'MM') THEN
                    'S'
                 ELSE
                    'N'
                 END) APURADO,
                DATAINICIOCIAP,
                DATAFINALCIAP,
                DATABAIXA
         -- Select para busca do saldo ativo para calculo
         FROM (SELECT CODPROD,
                      CODPRODSEQ, 
                      TRANSACAO,
                      TIPOTRANSACAO,
                      SUM(NVL(VLCREDITO,0)) VLCREDITO,
                      QTMESESCREDCIAP,
                      DATAINICIOCIAP,
                      DATAFINALCIAP,
                      MAX(DATABAIXA) DATABAIXA
               FROM (-- Créditos do CIAP
                     SELECT CODPROD,
                            TRANSACAO,
                            TIPOTRANSACAO,
                              SUM(CASE WHEN (PCONSIDERARDIFALIQ = 'S') THEN
                                       NVL(VLCREDITO, 0) + NVL(VLDIFALIQUOTA, 0) - NVL(VLBAIXACRED, 0) - NVL(VLBAIXADIFALIQUOTA, 0) +
                                       DECODE(VINCULARDOCUMENTOCT, 'S', (NVL(VLCREDFRETE,0) + NVL(VLDIFALIQUOTAFRETE, 0)), 0) -
                                       DECODE(VINCULARDOCUMENTOCT, 'S', (NVL(VLBAIXACREDFRETE,0) + NVL(VLBAIXADIFALIQUOTAFRETE, 0)), 0)
                                    ELSE
                                       NVL(VLCREDITO, 0) - NVL(VLBAIXACRED, 0) +
                                       DECODE(VINCULARDOCUMENTOCT, 'S', NVL(VLCREDFRETE,0), 0) -
                                       DECODE(VINCULARDOCUMENTOCT, 'S', NVL(VLBAIXACREDFRETE,0), 0)
                                    END) VLCREDITO,
                            QTMESESCREDCIAP,
                            DATAINICIOCIAP,
                            DATAFINALCIAP,
                            DATABAIXA, 
                            CODPRODSEQ
                       FROM VIEW_GERA_CIAP
                      WHERE CODFILIAL = PCODFILIAL
                        AND TRUNC(DATA, 'MM') <= TO_DATE('01/' || V_MES || '/' || PEXERCICIO, 'DD/MM/YYYY')
                      GROUP BY CODPROD,
                               CODPRODSEQ, 
                               TRANSACAO,
                               TIPOTRANSACAO,
                               QTMESESCREDCIAP,
                               DATAINICIOCIAP,
                               DATAFINALCIAP,
                               DATABAIXA)
               GROUP BY CODPROD, CODPRODSEQ, TRANSACAO, TIPOTRANSACAO,
                        QTMESESCREDCIAP, DATAINICIOCIAP, DATAFINALCIAP) S
         WHERE TO_DATE('01/' || V_MES || '/' || PEXERCICIO, 'DD/MM/YYYY') <= TRUNC(SYSDATE, 'MM')
           AND ((DATAFINALCIAP >= TO_DATE('01/' ||V_MES|| '/' || PEXERCICIO, 'DD/MM/YYYY') AND NVL(QTMESESCREDCIAP,0) > 1)
             OR (V_MES = EXTRACT(MONTH FROM DATAINICIOCIAP) AND NVL(QTMESESCREDCIAP,0) = 1 AND PEXERCICIO = EXTRACT(YEAR FROM DATAINICIOCIAP)))                
           AND NVL(QTMESESCREDCIAP, V_QTMESESCIAP) > 0;

      V_GEROU_CIAPITEM := sql%rowcount > 0;
      ------------------------------------------------------------------------
      --- UPDATE PARA CÁLCULO DE PRO RATA DIE
      if V_TIPOCALCULOCIAP <> 'M' then
         -- Cálculo rateado do primeiro Mês
         update PCCIAPITEM
         set VLCREDITO = VLCREDITO * ((EXTRACT(day from LAST_DAY(DATAINICIOCIAP)) + 1 -
                         EXTRACT(day from DATAINICIOCIAP)) /
                         EXTRACT(day from LAST_DAY(DATAINICIOCIAP)))
         where DATAINICIOCIAP > TRUNC(DATAINICIOCIAP, 'MM')
           and ANO = EXTRACT(year from DATAINICIOCIAP)
           and MES = EXTRACT(month from DATAINICIOCIAP)
           and ANO = PEXERCICIO
           and MES = V_MES
           and CODFILIAL = PCODFILIAL;

         -- Cálculo rateado do mês da baixa
         BEGIN
         -- Calculando o valor da baixa separadamente e agregando ao valor do credito
         -- registrado no período.
         FOR DADOS IN (
           SELECT TAB.*, ROUND(TAB.VLCREDITO * TAB.PERC_RED,2) VLCRED_NOVO
                       , ROUND(TAB.VLBASECREDITO * TAB.PERC_RED,2) VLBASECREDITO_NOVO
                  FROM (
                  SELECT (SELECT SUM(M.QTCONT)
                            FROM PCMOVCIAP M
                           WHERE M.NUMTRANSENT = I.NUMTRANSENT
                             AND M.CODPROD = I.CODPROD
                             AND M.CODFILIAL = I.CODFILIAL
                           ) QTD_TOTAL
                         ,(SELECT COUNT(1)
                             FROM PCBENSPATRIMONIAIS B
                            WHERE B.NUMTRANSACAO = I.NUMTRANSENT
                              AND B.CODFILIAL = I.CODFILIAL
                              AND B.DATABAIXA > TRUNC(I.DATABAIXA, 'MM' )) QTD_BAIXADA
                         ,I.CODFILIAL, I.CODPROD, I.MES, I.ANO, I.DATABAIXA, I.VLCREDITO, I.CODITEM, I.NUMTRANSENT, I.VLBASECREDITO
                         ,ROUND(EXTRACT(day from I.DATABAIXA) / EXTRACT(day from LAST_DAY(I.DATABAIXA)),8) PERC_RED
                  FROM PCCIAPITEM I
                  where DATABAIXA > TRUNC(DATABAIXA, 'MM')
                             and ANO = EXTRACT(year from DATABAIXA)
                             and MES = EXTRACT(month from DATABAIXA)
                             and ANO = PEXERCICIO
                             and MES = V_MES
                             and CODFILIAL = PCODFILIAL
                  ) TAB)
                  LOOP
                    UPDATE PCCIAPITEM I SET I.VLCREDITO = I.VLCREDITO + DADOS.VLCRED_NOVO,
                                            I.VLBASECREDITO = I.VLBASECREDITO + DADOS.VLBASECREDITO_NOVO
                     WHERE I.NUMTRANSENT = DADOS.NUMTRANSENT
                       AND I.CODPROD = DADOS.CODPROD
                       AND I.CODFILIAL = DADOS.CODFILIAL
                       AND I.CODITEM = DADOS.CODITEM
                       AND I.ANO = DADOS.ANO
                       AND I.MES = DADOS.MES;
                       COMMIT;
                  END LOOP;
         END;

/*  -- processo anterior de ajuste 
         update PCCIAPITEM
         set VLCREDITO = VLCREDITO * EXTRACT(day from DATABAIXA) /
                         EXTRACT(day from LAST_DAY(DATABAIXA))
         where DATABAIXA > TRUNC(DATABAIXA, 'MM')
           and ANO = EXTRACT(year from DATABAIXA)
           and MES = EXTRACT(month from DATABAIXA)
           and ANO = PEXERCICIO
           and MES = V_MES
           and CODFILIAL = PCODFILIAL;
*/

         -- Cálculo rateado do último Mês
         update PCCIAPITEM
         set VLCREDITO = VLCREDITO *
                         EXTRACT(day from ADD_MONTHS(DATAFINALCIAP, 1)) /
                         EXTRACT(day from LAST_DAY(ADD_MONTHS(DATAFINALCIAP, 1)))
         where DATAFINALCIAP > TRUNC(DATAFINALCIAP, 'MM')
           and ANO = EXTRACT(year from ADD_MONTHS(DATAFINALCIAP, 1))
           and MES = EXTRACT(month from ADD_MONTHS(DATAFINALCIAP, 1))
           and ANO = PEXERCICIO
           and MES = V_MES
           and CODFILIAL = PCODFILIAL;
      end if;
/*      ------------------------------------------------------------------------
      -- Atualizar coluna CODPRODSEQ da PCCIAPITEM conforme notas/itens da PCMOVCIAP 
      ------------------------------------------------------------------------
      FOR DADOS1 IN (
          -- Filtrando itens do periodo que contem o mesmo codprod mais de uma vez na pcmovciap
          SELECT TAB.CODFILIAL, TAB.CODPROD, TAB.NUMTRANSENT, TAB.QTD_MOV, TAB.QTD_MESES, TAB.FATOR
          FROM ( SELECT DISTINCT I.CODFILIAL, I.CODPROD, I.NUMTRANSENT
                        ,(SELECT COUNT(*) FROM PCMOVCIAP M WHERE M.NUMTRANSENT = I.NUMTRANSENT AND M.CODPROD = I.CODPROD) QTD_MOV
                        ,TRIM(SUBSTR(I.FATOR,3,3)) QTD_MESES
                        ,I.FATOR 
                    FROM PCCIAPITEM I 
                   WHERE ANO           = PEXERCICIO
                         AND MES      >= V_MES
                         AND CODFILIAL = PCODFILIAL
               ) TAB WHERE TAB.QTD_MOV > 1
          ) LOOP 
            
            FOR DADOS2 IN (
            -- Segundo For para identificar o CODPRODSEQ da pcmovciap
                SELECT M.NUMTRANSENT, M.CODPROD, M.NUMSEQ, M.QTMESESCREDCIAP
                ,CASE WHEN M.ITEMDUPLICADO = 'S' THEN 
                      TO_CHAR(M.CODPROD)||'-'||TO_CHAR(M.NUMSEQ)
                 ELSE 
                      TO_CHAR(M.CODPROD)
                 END CODPRODSEQ 
                FROM PCMOVCIAP M 
               WHERE M.NUMTRANSENT     = DADOS1.NUMTRANSENT
                 AND M.CODPROD         = DADOS1.CODPROD
                 AND M.CODFILIAL       = DADOS1.CODFILIAL
                 AND M.QTMESESCREDCIAP = DADOS1.QTD_MESES
            ) LOOP 
              -- ALTERAÇÃO DA PCCIAPITEM COM O CODPRODSEQ 
              UPDATE PCCIAPITEM I SET I.CODPRODSEQ = DADOS2.CODPRODSEQ 
               WHERE I.NUMTRANSENT = DADOS2.NUMTRANSENT 
                 AND I.CODPROD     = DADOS2.CODPROD 
                 AND I.FATOR       = DADOS1.FATOR
                 AND I.MES        >= V_MES
                 AND I.ANO         = PEXERCICIO
                 AND I.CODFILIAL   = PCODFILIAL;
            END LOOP; -- DADOS2
          END LOOP; -- DADOS1      
      ------------------------------------------------------------------------      */
      begin
         if not V_GEROU_CIAPITEM then
            insert into PCCIAP(CODFILIAL,
                               MES,
                               ANO,
                               VLSAIDASTRIBUTADAS,
                               VLTOTALSAIDAS,
                               VLBASECREDITO,
                               VLCREDITO,
                               APURADO,
                               FRACAO)
                        values(PCODFILIAL,
                               V_MES,
                               PEXERCICIO,
                               NVL(V_TOTALTRIBUTADAS, 0),
                               NVL(V_TOTALSAIDAS, 0),
                               0,
                               0,
                               'S',
                               '1/' || TO_CHAR(V_QTMESESCIAP));
         else
            insert into PCCIAP(CODFILIAL,
                               MES,
                               ANO,
                               VLSAIDASTRIBUTADAS,
                               VLTOTALSAIDAS,
                               VLBASECREDITO,
                               VLCREDITO,
                               APURADO,
                               FRACAO)
               select PCODFILIAL,
                      V_MES,
                      PEXERCICIO,
                      NVL(V_TOTALTRIBUTADAS, 0),
                      NVL(V_TOTALSAIDAS, 0),
                      sum(NVL(S.VLBASECREDITO, 0)) VLBASECREDITO,
                      sum(NVL(S.VLCREDITO, 0)) VLCREDITO,
                      case when TO_DATE('01/' || V_MES || '/' || PEXERCICIO, 'DD/MM/YYYY') < TRUNC(sysdate, 'MM') then
                         'S'
                      else
                         'N'
                      end APURADO,
                      FATOR
               -- Select para busca do saldo ativo para calculo
               from (select sum(VLBASECREDITO) VLBASECREDITO,
                            sum(VLCREDITO) VLCREDITO,
                            FATOR
                     from PCCIAPITEM
                     where CODFILIAL = PCODFILIAL
                       and ANO = PEXERCICIO
                       and MES = V_MES
                     group by FATOR) S
               group by FATOR;
         end if;

         exception
         when others then
            null;
      end;
      ------------------------------------------------------------------------
      V_MES := V_MES + 1;
   end loop;
   ------------------------------------------------------------------------
   commit;
   PMSG := 'OK';
   exception
   when others then
   begin
      rollback;
      PMSG := 'ERRO AO GERAR APURACAO DO CIAP ' ||CHR(13)|| 'ERRO INTERNO: ' ||
              sqlerrm;
   end;
end;
----------------------------------------------------------------------
-- 11/07/2023 - Última alteração - 
-- Implementado alteração no processo de geração do valor de devolução a ser deduzido.
----------------------------------------------------------------------