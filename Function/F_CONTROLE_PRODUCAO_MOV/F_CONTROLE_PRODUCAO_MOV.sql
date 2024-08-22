CREATE OR REPLACE FUNCTION F_CONTROLE_PRODUCAO_MOV(PCODFILIAL               in varchar2,
                                                   PDTINICIO                in date,
                                                   PDTFIM                   in date,
                                                   PDTINVENTARIO            in date default null,
                                                   PTIPOCUSTO               in number default 0,     --
                                                   PPROD_SEM_MOV            in varchar2 default 'N', -- 02
                                                   PUTILIZA_METODO_PEPS     in varchar2 default 'N', --
                                                   PUTILIZA_PRECO_NOTA      in varchar2 default 'N', -- 05
                                                   PNUMCASAS_QT             in number default 3,
                                                   PNUMCASAS_UNIT           in number default 6,
                                                   PNUMCASAS_TOTAL          in number default 2,
                                                   PUSOCONSUMO              in varchar default  'S', -- 07 - Desconsiderar item de consumo
                                                   PATIVIOMOBULIZADO        in varchar default  'S', -- 06 - Desconsiderar item de imobilizado
                                                   PGERACANCPRODUCAO        in varchar default  'N', -- 09
                                                   PGERACODOPERSMKARDEX     in varchar default  'N',
                                                   PCODPROD1                in number default 0,
                                                   PCODPROD2                in number default 9999999999,
                                                   PVENDAMANIF_COMTV14      in varchar2 default 'N', -- 16
                                                   PGERA_SM_KARDEX_CANC     in varchar default  'N', --
                                                   PGERA_NF_ENTRADA_CANC    in varchar default  'N', -- 14
                                                   PGERA_NF_SAIDA_CANC      in varchar default  'N', -- 15
                                                   PDESC_NF_TRANSF_DEP      in varchar default  'N', -- 17
                                                   PUTILIZA_PROCEDURE       in varchar2 default 'N', -- 24 - Desconsidera função e executar procedure
                                                   PDESCONSIDERANFEDENEGADA in varchar default  'N', -- 18 - Desconsiderar nfe denegada
                                                   PMOSTRARAJUSTESCUSTO     in varchar default  'N', -- Desativado para alterações manuais. Default S
                                                   PORDENAR_PCMOVLOG        in varchar default  'N', -- Desativado para alterações manuais. Default N
                                                   PGERA_NUMOP_NA_OBS       in varchar2 default 'N', -- 10.2 - (S) Exibe no campo OBS a número da Operação correspondente ao lançamento.
                                                   PCONSIDERARCUSTOBONIF    in varchar2 default 'N', -- 20 - (S) Considera o custo registrado na NF de bonificação.
                                                   PDESCONS_CUSTO_DEVCLI    in varchar2 default 'N', -- 21 - (S) Descons.o custo da NF de entrada devolução de cliente e mantem o custo anterior.
                                                   PDESCONS_ENT_AJUSTE_ER   in varchar2 default 'N', -- 23 - (S)Excluí o lançamento CODOPER = ER (Ajuste de saída consignada rot 1437)
                                                   PDESCONS_CUSTO_NFENTCANC in varchar2 default 'N', -- 22 - (S) Descons.o custo da NF de entrada cancelada e mantem o custo anterior.
                                                   PDESCONS_ITEM_BRINDE     in varchar2 default 'S',  -- 08 - (S) Descons.o item do Estoque/Movimentação(NFs) com a informação TIPOMERC = BD.
                                                   PSTATUSPROD              in varchar2 default 'T'  -- 27 - Status do Produto DTEXCLUSAO - T - Todos / A - Ativo / I - Inativo                                                  
                                                   )
---------------------------------------------------------------------------------
  -- Função para retorno de movimentação de controle de produção
  ---------------------------------------------------------------------------------
  -- Criado por: Gleibe em 23/04/2021
  ---------------------------------------------------------------------------------
  return TABELA_CONTROLE_PRODUCAO
  parallel_enable
  pipelined is

  OUTROW TIPO_CONTROLE_PRODUCAO := TIPO_CONTROLE_PRODUCAO(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL); -- 80 colunas
  -- PARAMETROS INTERNOS
  V_FIL_CALCREDPISFRETECONT      varchar2(1);
  V_UTICREDICMSFRETEFOBCUSTOCONT varchar2(1);
  V_CALCREDPISCOFINSSERVICOCONT  varchar2(1);
  V_DATA_CANCELAMENTO_FIM        DATE;
  V_UTILIZA_CUSTO_ULTIMA_ENTRADA boolean;
  -----------------------------------------------------------------------------------------------------
  BEGIN
  V_DATA_CANCELAMENTO_FIM := TO_DATE(TO_CHAR(PDTFIM, 'DD/MM/YYYY') || ' 23:59:59', 'DD/MM/YYYY HH24:MI:SS');
 --------------------------------------------------------------------------------------------------------------
 -- ENTRADA NORMAL 
 --------------------------------------------------------------------------------------------------------------
       FOR DADOS IN (SELECT 'E' TIPO,
                             PCMOV.SEQMOV,
                             --- Verificando devolução -----------------------------------------------------
                             CASE
                               WHEN PCMOV.CODOPER IN ('ED') THEN
                                 DECODE(NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0),0,PCMOV.CUSTOCONT,PCMOVCOMPLE.CUSTOULTENTCONT)
                               WHEN PCMOV.CODOPER IN ('ET') THEN
                                 DECODE(NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0),0,PCMOV.CUSTOCONT,PCMOVCOMPLE.CUSTOULTENTCONT)
                             ELSE
                             NVL(PCMOVCOMPLE.CUSTOULTENTCONT,
                                 ROUND(((((GREATEST(NVL(PCMOV.QTESTANT, 0), 0) +
                                         PCMOV.QTCONT) * NVL(PCMOV.CUSTOCONT, 0)) -
                                         (GREATEST(NVL(PCMOV.QTESTANT, 0), 0) *
                                         NVL(PCMOV.CUSTOCONTANT, 0))) / PCMOV.QTCONT),6)) END BASECUSTOCONT,
                             --------------------------------------------------------------------------------
                             PCMOV.CUSTOCONT,
                             PCMOV.CUSTOFIN,
                             PCMOV.CUSTOREAL,
                             PCMOV.CUSTOREP,
                             PCMOV.CUSTOULTENT,
                             PCMOV.CUSTOREALSEMST,
                             PCMOV.VALORULTENT,
                             PCNFENT.ESPECIE,
                             PCNFENT.SERIE,
                             TO_CHAR(PCNFENT.CODCONT) CODCONT,
                             PCNFENT.OBS OBSERVACAO,
                             PCMOV.CODPROD,
                             PCMOV.CODOPER,
                             PCMOV.NUMNOTA,
                             PCNFENT.DTENT DATA,
                             PCMOV.DTMOVLOG,
                             -- CONFIGURANDO HORA_LANC
                             CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                  WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                       TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                  ELSE PCMOV.HORALANC END HORALANC,
                             --
                             PCMOV.CODFISCAL,
                             ROUND(PCMOV.QTCONT, PNUMCASAS_QT) QTCONT,
                             DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                    ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTENTRADA,
                             0 QTSAIDA,
                             0 QTSAIDA_DENTRO,
                             0 QTSAIDA_FORA,
                             DECODE(PCMOV.CODOPER, 'ED',
                                    'ENTRADA DE DEVOLUÇÃO', 'E',
                                    'ENTRADA DE MERCADORIAS', 'OUTRAS') HISTORICO,
                             ROUND(PCMOV.PUNITCONT, PNUMCASAS_UNIT) PUNITCONT,
                             ROUND(PCMOV.PUNITCONT -
                                   DECODE(PCMOV.CODOPER, 'ED',
                                          NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                          NVL(PCMOV.VLDESCONTO, 0)), PNUMCASAS_UNIT) VALORITEMNOTA_ENT,
                             0 VALORITEMNOTA_SAID,
                             PCMOV.NUMTRANSENT,
                             0 NUMTRANSVENDA,
                             NVL(PCMOV.VLIPI, 0) VLIPI,
                             NVL(PCMOV.ST, 0) ST,
                             NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                             PCNFENT.DTCANCEL,
                             PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                             PCNFENT.TIPODESCARGA
                             -- CONFIGURANDO MINUTO_LANC
                             ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                   WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                       TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                  ELSE PCMOV.MINUTOLANC END MINUTOLANC
                             ,PCMOV.CUSTOCONTANT
                             ,PCMOV.ROTINACAD
                             ,(NVL(PCMOV.VLFRETECONHEC,0) -
                               (DECODE(NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0),0,NVL(PCMOVCOMPLE.VLICMSFRETEFOB,0),NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0)) +
                               NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0))) VLFRETEFOB_LIQ
                             ,NVL(ROUND(((NVL(PCMOVCOMPLE.PTABELACUSTO,DECODE(PCMOV.PTABELA,0,PCMOV.PUNITCONT,PCMOV.PTABELA))
                              - NVL(PCMOVCOMPLE.VLDESCONTOCUSTO,NVL(PCMOV.VLDESCONTO,0)))
                              + NVL(PCMOVCOMPLE.VLFRETENFCUSTO,NVL(PCMOV.VLFRETE,0))
                              + NVL(PCMOVCOMPLE.VLSEGUROCUSTO,NVL(PCMOV.VLSEGURO,0))
                              + NVL(PCMOVCOMPLE.VLCAPATAZIACUSTO,0)
                              + NVL(PCMOVCOMPLE.VLDESPDENTRONFCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                 WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                    (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                 ELSE 0
                                                                                              END))
                              + NVL(PCMOV.VLIMPORTACAO,0)
                              + NVL(PCMOV.ST,0)
                              + NVL(PCMOVCOMPLE.VLSISCOMEXCUSTO,NVL(PCMOV.VLSISCOMEX, 0))
                              + NVL(PCMOVCOMPLE.VLAFRMMCUSTO, 0)
                              + NVL(PCMOVCOMPLE.VLADUANEIRACUSTO,NVL(PCMOV.VLADUANEIRA, 0))
                              + NVL(PCMOVCOMPLE.VLOUTRASDESPIMPCUSTO,NVL(PCMOV.VLOUTRASDESPIMP,0))
                              + NVL(PCMOV.VLDESPADICIONAL,0)
                              -- Pis e cofins
                              + CASE
                                 WHEN PCNFENT.TIPODESCARGA IN ('N','I') THEN
                                   (CASE
                                     WHEN (NVL(PCMOVCOMPLE.VLPISCALCDI,0) > 0) THEN
                                       (NVL(PCMOVCOMPLE.VLPISCALCDI, 0) - NVL(PCMOV.VLCREDPIS, 0))
                                     ELSE
                                       0
                                   END)
                                + (CASE
                                     WHEN (NVL(PCMOVCOMPLE.VLCOFINSCALCDI,0) > 0) THEN
                                       (NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0) - NVL(PCMOV.VLCREDCOFINS, 0))
                                     ELSE
                                       0
                                   END)
                                ELSE
                                  0
                                END
                              + NVL(PCMOVCOMPLE.VLOUTROSCUSTOSCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                 WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                    (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                 ELSE 0
                                                                                              END))
                              + (NVL(PCMOV.VLFRETECONHEC,0) - (NVL(VLICMSCUSTOFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0)))
                               ),6),0) CUSTO_SEM_IPI_PIS_COFINS
                            ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                            ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                            ,PCNFENT.NUMTRANSORIGEM                                                -- 68
                            ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                            ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                            ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                            ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                            ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                            ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                            ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                            ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                       FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                      WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                        AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                        AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                        AND PCMOV.CODPROD = PCPRODUT.CODPROD
                        AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                        AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                        AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                        AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                        AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                        AND PCMOV.QTCONT > 0
                        AND DECODE(PGERA_NF_ENTRADA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                        AND PCNFENT.TIPODESCARGA NOT IN ( 'N' ,'F', 'P','H','G' ) -- Retirado 'N' para excluir sql completo do TIPO N
                        -- Incluir OE se parametro marcado.
                        AND (PCNFENT.ESPECIE IN ('NF','NE','TP') OR
                             DECODE(PGERA_NF_ENTRADA_CANC,'S',PCNFENT.ESPECIE, 'OE') = 'OE')
                        AND PCMOV.STATUS in ('A', 'AB')
                        AND NVL(PCNFENT.FINALIDADENFE, 'O') <> 'C'
                        AND PCMOV.CODOPER <> 'EV'
                        AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                        AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                        AND ((PDESCONSIDERANFEDENEGADA = 'N') OR
                            ((PDESCONSIDERANFEDENEGADA = 'S') AND NVL(PCNFENT.SITUACAONFE,'0') NOT IN (110,205,301,302)))
                        AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                        AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                        AND PCMOV.CODOPER NOT in ('EP','EA', 'EX')
                        AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                        AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                  WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                  WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                  ELSE 0 END = 1)                         
                      )
            LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
            
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
   -- ENTRADA CANCELADA --
 --------------------------------------------------------------------------------------------------------------
   FOR DADOS IN (            
                  SELECT TAB.TIPO,TAB.SEQMOV,TAB.BASECUSTOCONT,TAB.CUSTOCONT,TAB.CUSTOFIN,TAB.CUSTOREAL,TAB.CUSTOREP,TAB.CUSTOULTENT,TAB.CUSTOREALSEMST,TAB.VALORULTENT,
                         TAB.ESPECIE,TAB.SERIE,TAB.CODCONT,TAB.OBSERVACAO,TAB.CODPROD,TAB.CODOPER,TAB.NUMNOTA,TAB.DTCANCEL_ORIG DATA,TAB.DTMOVLOG,TAB.HORALANC,
                         TAB.CODFISCAL,TAB.QTCONT,TAB.QTENTRADA,TAB.QTSAIDA,TAB.QTSAIDA_DENTRO,TAB.QTSAIDA_FORA,TAB.HISTORICO,TAB.PUNITCONT,TAB.VALORITEMNOTA_ENT,
                         TAB.VALORITEMNOTA_SAID,TAB.NUMTRANSENT,TAB.NUMTRANSVENDA,TAB.VLIPI,TAB.ST,TAB.STGUIA,TAB.DTCANCEL,TAB.SITUACAOTRIBUTARIA,TAB.TIPODESCARGA,
                         TAB.MINUTOLANC,TAB.CUSTOCONTANT,TAB.ROTINACAD,TAB.CUSTO_SEM_IPI_PIS_COFINS,TAB.ID_PCMOV,TAB.ID_PCMOVCOMPLE,TAB.NUMTRANSORIGEM,TAB.VLR_CRED_ICMS,
                         TAB.CUSTOULTENTCONT,TAB.NUMSEQ,TAB.VLR_ICMS_REAL,TAB.VLR_CRED_COFINS,TAB.VLR_CRED_PIS,TAB.NCM,TAB.CUSTOFISCAL   
                      FROM (   
                              SELECT 'EC' TIPO,--- NF ENTRADA CANCELADA
                                     PCMOV.SEQMOV,
                                     --- Verificando devolução -----------------------------------------------------
                                     CASE
                                       WHEN PCMOV.CODOPER IN ('ED') THEN
                                         DECODE(NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0),0,PCMOV.CUSTOCONT,PCMOVCOMPLE.CUSTOULTENTCONT)
                                       WHEN PCMOV.CODOPER IN ('ET') THEN
                                         DECODE(NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0),0,PCMOV.CUSTOCONT,PCMOVCOMPLE.CUSTOULTENTCONT)
                                     ELSE
                                        (SELECT NVL(C.CUSTOULTENTCONT,
                                                   ROUND(((((GREATEST(NVL(V.QTESTANT, 0), 0) +
                                                           V.QTCONT) * NVL(V.CUSTOCONT, 0)) -
                                                           (GREATEST(NVL(V.QTESTANT, 0), 0) *
                                                           NVL(V.CUSTOCONTANT, 0))) / V.QTCONT),6))
                                            FROM PCMOV V
                                                ,PCNFENT E
                                                ,PCMOVCOMPLE C
                                           WHERE V.NUMTRANSENT = E.NUMTRANSENT
                                             AND V.NUMTRANSITEM = C.NUMTRANSITEM(+)
                                             AND NVL(V.CODFILIALNF,V.CODFILIAL) = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                             AND V.CODPROD = PCMOV.CODPROD
                                             AND V.NUMNOTA = PCMOV.NUMNOTA
                                             AND V.NUMTRANSENT = PCMOV.NUMTRANSENT
                                             AND V.NUMSEQ = PCMOV.NUMSEQ
                                             AND V.QTCONT > 0
                                             AND ROWNUM = 1) --*/
                                      END BASECUSTOCONT,
                                     --------------------------------------------------------------------------------
                                    -- PCMOV.CUSTOCONT, -- Não retornar essa opção. Dúvidas falar com Fábio Figueiredo ou Gleibe. 
                                     NVL(PCMOVCOMPLE.CUSTOCONTCANC,PCMOV.CUSTOCONT)  AS CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     PCNFENT.ESPECIE,
                                     PCNFENT.SERIE,
                                     TO_CHAR(PCNFENT.CODCONT) CODCONT,
                                     PCNFENT.OBS OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCMOV.NUMNOTA,
                                     PCMOV.DTCANCEL DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     ROUND(PCMOV.QTCONT, PNUMCASAS_QT) QTCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                            ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTENTRADA,
                                     0 QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'ED',
                                            'ENTRADA DE DEVOLUÇÃO', 'E',
                                            'ENTRADA DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                     ROUND(PCMOV.PUNITCONT, PNUMCASAS_UNIT) PUNITCONT,
                                     ROUND(PCMOV.PUNITCONT -
                                           DECODE(PCMOV.CODOPER, 'ED',
                                                  NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                  NVL(PCMOV.VLDESCONTO, 0)), PNUMCASAS_UNIT) VALORITEMNOTA_ENT,
                                     0 VALORITEMNOTA_SAID,
                                     PCMOV.NUMTRANSENT,
                                     0 NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCNFENT.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     PCNFENT.TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                    ,PCMOV.CUSTOCONTANT
                                    ,PCMOV.ROTINACAD
                                     ,(NVL(PCMOV.VLFRETECONHEC,0) -
                                       (DECODE(NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0),0,NVL(PCMOVCOMPLE.VLICMSFRETEFOB,0),NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0)) +
                                       NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0))) VLFRETEFOB_LIQ
                                     ,NVL(ROUND(((NVL(PCMOVCOMPLE.PTABELACUSTO,DECODE(PCMOV.PTABELA,0,PCMOV.PUNITCONT,PCMOV.PTABELA))
                                      - NVL(PCMOVCOMPLE.VLDESCONTOCUSTO,NVL(PCMOV.VLDESCONTO,0)))
                                      + NVL(PCMOVCOMPLE.VLFRETENFCUSTO,NVL(PCMOV.VLFRETE,0))
                                      + NVL(PCMOVCOMPLE.VLSEGUROCUSTO,NVL(PCMOV.VLSEGURO,0))
                                      + NVL(PCMOVCOMPLE.VLCAPATAZIACUSTO,0)
                                      + NVL(PCMOVCOMPLE.VLDESPDENTRONFCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + NVL(PCMOV.VLIMPORTACAO,0)
                                      + NVL(PCMOV.ST,0)
                                      + NVL(PCMOVCOMPLE.VLSISCOMEXCUSTO,NVL(PCMOV.VLSISCOMEX, 0))
                                      + NVL(PCMOVCOMPLE.VLAFRMMCUSTO, 0)
                                      + NVL(PCMOVCOMPLE.VLADUANEIRACUSTO,NVL(PCMOV.VLADUANEIRA, 0))
                                      + NVL(PCMOVCOMPLE.VLOUTRASDESPIMPCUSTO,NVL(PCMOV.VLOUTRASDESPIMP,0))
                                      + NVL(PCMOV.VLDESPADICIONAL,0)
                                      -- Pis e cofins
                                      + CASE
                                         WHEN PCNFENT.TIPODESCARGA IN ('N','I') THEN
                                           (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLPISCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLPISCALCDI, 0) - NVL(PCMOV.VLCREDPIS, 0))
                                             ELSE
                                               0
                                           END)
                                        + (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLCOFINSCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0) - NVL(PCMOV.VLCREDCOFINS, 0))
                                             ELSE
                                               0
                                           END)
                                        ELSE
                                          0
                                        END
                                      + NVL(PCMOVCOMPLE.VLOUTROSCUSTOSCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + (NVL(PCMOV.VLFRETECONHEC,0) - (NVL(VLICMSCUSTOFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0)))
                                       ),6),0) CUSTO_SEM_IPI_PIS_COFINS
                                    ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                    ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                    ,PCNFENT.NUMTRANSORIGEM                                                -- 68
                                    ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,TRUNC(PCNFENT.DTCANCEL) DTCANCEL_ORIG
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                                AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                -- Buscando pelo Dtent com 30dias menos e 30dias mais na data final. O filtro do DTCANCEL é feito por fora
                                AND PCNFENT.DTENT BETWEEN TO_DATE(PDTINICIO) - 30 
                                                      AND TO_DATE(PDTFIM)
                                AND PCNFENT.DTCANCEL IS NOT NULL
                                AND PCMOV.QTCONT < 0
                                AND PCNFENT.TIPODESCARGA NOT IN ('F', 'P','H','G' )
                                AND PCNFENT.ESPECIE IN ('NF','NE','TP', 'OE')
                                AND PCMOV.STATUS in ('A', 'AB')
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND PGERA_NF_ENTRADA_CANC = 'S'
                                AND NVL(PCNFENT.FINALIDADENFE, 'O') <> 'C'
                                AND PCMOV.CODOPER <> 'EV'
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND ((PDESCONSIDERANFEDENEGADA = 'N') OR
                                       ((PDESCONSIDERANFEDENEGADA = 'S') AND NVL(PCNFENT.SITUACAONFE,'0') NOT IN (110,205,301,302)))
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)       
                     ) TAB WHERE TAB.DTCANCEL_ORIG BETWEEN PDTINICIO AND PDTFIM

)
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;

  -- ENTRADA TIPO N --
   FOR DADOS IN (            SELECT 'E' TIPO,
                                     PCMOV.SEQMOV,
                                     NVL(PCMOVCOMPLE.CUSTOULTENTCONT,
                                         ROUND(((((GREATEST(NVL(PCMOV.QTESTANT, 0), 0) +
                                                PCMOV.QTCONT) * NVL(PCMOV.CUSTOCONT, 0)) -
                                                (GREATEST(NVL(PCMOV.QTESTANT, 0), 0) *
                                                NVL(PCMOV.CUSTOCONTANT, 0))) / PCMOV.QTCONT), 6)) BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     PCNFENT.ESPECIE,
                                     PCNFENT.SERIE,
                                     TO_CHAR(PCNFENT.CODCONT) CODCONT,
                                     PCNFENT.OBS OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCMOV.NUMNOTA,
                                     PCNFENT.DTENT DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     ROUND(PCMOV.QTCONT, PNUMCASAS_QT) QTCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                            ROUND(PCMOV.QTCONT, PNUMCASAS_QT),0) QTENTRADA,
                                     0 QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'ED',
                                            'ENTRADA DE DEVOLUÇÃO', 'E',
                                            'ENTRADA DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                     ROUND(PCMOV.PUNITCONT, PNUMCASAS_UNIT) PUNITCONT,
                                     ROUND(PCMOV.PUNITCONT -
                                           DECODE(PCMOV.CODOPER, 'ED',
                                                  NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                  NVL(PCMOV.VLDESCONTO, 0)), PNUMCASAS_UNIT) VALORITEMNOTA_ENT,
                                     0 VALORITEMNOTA_SAID,
                                     PCMOV.NUMTRANSENT,
                                     0 NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCNFENT.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     PCNFENT.TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,(NVL(PCMOV.VLFRETECONHEC,0) -
                                       (DECODE(NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0),0,NVL(PCMOVCOMPLE.VLICMSFRETEFOB,0),NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0)) +
                                       NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0))) VLFRETEFOB_LIQ
                                     ,NVL(ROUND(((NVL(PCMOVCOMPLE.PTABELACUSTO,DECODE(PCMOV.PTABELA,0,PCMOV.PUNITCONT,PCMOV.PTABELA))
                                      - NVL(PCMOVCOMPLE.VLDESCONTOCUSTO,NVL(PCMOV.VLDESCONTO,0)))
                                      + NVL(PCMOVCOMPLE.VLFRETENFCUSTO,NVL(PCMOV.VLFRETE,0))
                                      + NVL(PCMOVCOMPLE.VLSEGUROCUSTO,NVL(PCMOV.VLSEGURO,0))
                                      + NVL(PCMOVCOMPLE.VLCAPATAZIACUSTO,0)
                                      + NVL(PCMOVCOMPLE.VLDESPDENTRONFCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + NVL(PCMOV.VLIMPORTACAO,0)
                                      + NVL(PCMOV.ST,0)
                                      + NVL(PCMOVCOMPLE.VLSISCOMEXCUSTO,NVL(PCMOV.VLSISCOMEX, 0))
                                      + NVL(PCMOVCOMPLE.VLAFRMMCUSTO, 0)
                                      + NVL(PCMOVCOMPLE.VLADUANEIRACUSTO,NVL(PCMOV.VLADUANEIRA, 0))
                                      + NVL(PCMOVCOMPLE.VLOUTRASDESPIMPCUSTO,NVL(PCMOV.VLOUTRASDESPIMP,0))
                                      + NVL(PCMOV.VLDESPADICIONAL,0)
                                      -- Pis e cofins
                                      + CASE
                                         WHEN PCNFENT.TIPODESCARGA IN ('N','I') THEN
                                           (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLPISCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLPISCALCDI, 0) - NVL(PCMOV.VLCREDPIS, 0))
                                             ELSE
                                               0
                                           END)
                                        + (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLCOFINSCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0) - NVL(PCMOV.VLCREDCOFINS, 0))
                                             ELSE
                                               0
                                           END)
                                        ELSE
                                          0
                                        END
                                      + NVL(PCMOVCOMPLE.VLOUTROSCUSTOSCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + (NVL(PCMOV.VLFRETECONHEC,0) - (NVL(VLICMSCUSTOFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0)))
                                       ),6),0) CUSTO_SEM_IPI_PIS_COFINS
                                    ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                    ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                    ,PCNFENT.NUMTRANSORIGEM                                                -- 68
                                    ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                                AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND PCFILIAL.CODIGO = PCODFILIAL
                                AND PCMOV.QTCONT > 0
                                AND PCNFENT.TIPODESCARGA = 'N'
                                AND PCNFENT.ESPECIE IN ('NF','NE','TP')
                                AND DECODE(PGERA_NF_ENTRADA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                                AND PCMOV.STATUS in ('A', 'AB')
                                AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                                AND PCMOV.CODOPER <> 'EV'
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND NVL(PCNFENT.FINALIDADENFE, 'O') <> 'C'
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)
            )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
  -- ENTRADA TIPO P --
 --------------------------------------------------------------------------------------------------------------
   FOR DADOS IN              (SELECT 'EP' TIPO,
                                     PCMOV.SEQMOV,
                                     NVL(PCMOVCOMPLE.CUSTOULTENTCONT,
                                         ROUND(((((GREATEST(NVL(PCMOV.QTESTANT, 0), 0) +
                                                PCMOV.QTCONT) * NVL(PCMOV.CUSTOCONT, 0)) -
                                                (GREATEST(NVL(PCMOV.QTESTANT, 0), 0) *
                                                NVL(PCMOV.CUSTOCONTANT, 0))) / PCMOV.QTCONT), 6)) BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     PCNFENT.ESPECIE,
                                     PCNFENT.SERIE,
                                     TO_CHAR(PCNFENT.CODCONT) CODCONT,
                                     'COMPLEMENTO DE CUSTO NF-e' OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCNFENT.NUMNOTA,
                                     PCNFENT.DTENT DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     ROUND(PCMOV.QTCONT, PNUMCASAS_QT) QTCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                            ROUND(PCMOV.QTCONT, PNUMCASAS_QT),0) QTENTRADA,
                                     0 QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'ED',
                                            'ENTRADA DE DEVOLUÇÃO', 'E',
                                            'ENTRADA DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                     ROUND(PCMOV.PUNITCONT, PNUMCASAS_UNIT) PUNITCONT,
                                     ROUND(PCMOV.PUNITCONT -
                                           DECODE(PCMOV.CODOPER, 'ED',
                                                  NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                  NVL(PCMOV.VLDESCONTO, 0)), PNUMCASAS_UNIT) VALORITEMNOTA_ENT,
                                     0 VALORITEMNOTA_SAID,
                                     PCMOV.NUMTRANSENT,
                                     0 NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCNFENT.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     PCNFENT.TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,(NVL(PCMOV.VLFRETECONHEC,0) -
                                       (DECODE(NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0),0,NVL(PCMOVCOMPLE.VLICMSFRETEFOB,0),NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0)) +
                                       NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0))) VLFRETEFOB_LIQ
                                     ,NVL(ROUND(((NVL(PCMOVCOMPLE.PTABELACUSTO,DECODE(PCMOV.PTABELA,0,PCMOV.PUNITCONT,PCMOV.PTABELA))
                                      - NVL(PCMOVCOMPLE.VLDESCONTOCUSTO,NVL(PCMOV.VLDESCONTO,0)))
                                      + NVL(PCMOVCOMPLE.VLFRETENFCUSTO,NVL(PCMOV.VLFRETE,0))
                                      + NVL(PCMOVCOMPLE.VLSEGUROCUSTO,NVL(PCMOV.VLSEGURO,0))
                                      + NVL(PCMOVCOMPLE.VLCAPATAZIACUSTO,0)
                                      + NVL(PCMOVCOMPLE.VLDESPDENTRONFCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + NVL(PCMOV.VLIMPORTACAO,0)
                                      + NVL(PCMOV.ST,0)
                                      + NVL(PCMOVCOMPLE.VLSISCOMEXCUSTO,NVL(PCMOV.VLSISCOMEX, 0))
                                      + NVL(PCMOVCOMPLE.VLAFRMMCUSTO, 0)
                                      + NVL(PCMOVCOMPLE.VLADUANEIRACUSTO,NVL(PCMOV.VLADUANEIRA, 0))
                                      + NVL(PCMOVCOMPLE.VLOUTRASDESPIMPCUSTO,NVL(PCMOV.VLOUTRASDESPIMP,0))
                                      + NVL(PCMOV.VLDESPADICIONAL,0)
                                      -- Pis e cofins
                                      + CASE
                                         WHEN PCNFENT.TIPODESCARGA IN ('N','I') THEN
                                           (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLPISCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLPISCALCDI, 0) - NVL(PCMOV.VLCREDPIS, 0))
                                             ELSE
                                               0
                                           END)
                                        + (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLCOFINSCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0) - NVL(PCMOV.VLCREDCOFINS, 0))
                                             ELSE
                                               0
                                           END)
                                        ELSE
                                          0
                                        END
                                      + NVL(PCMOVCOMPLE.VLOUTROSCUSTOSCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + (NVL(PCMOV.VLFRETECONHEC,0) - (NVL(VLICMSCUSTOFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0)))
                                       ),6),0) CUSTO_SEM_IPI_PIS_COFINS
                                    ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                    ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                    ,PCNFENT.NUMTRANSORIGEM                                                -- 68
                                    ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                               FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND PCNFENT.TIPODESCARGA = 'P'
                                AND PCNFENT.ESPECIE IN ('NF','NE','TP')
                                AND DECODE(PGERA_NF_ENTRADA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                                AND PCMOV.STATUS = 'B'
                                AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                                AND PCMOV.CODOPER <> 'EV'
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND (PMOSTRARAJUSTESCUSTO = 'S')
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)
)
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- ENTRADA COMPLEMENTO DE FRETE --
 --------------------------------------------------------------------------------------------------------------
   FOR DADOS IN             (SELECT 'EF' TIPO,
                                     PCMOV.SEQMOV,
                                     -----------------------------------------------------
                                     ROUND(PCMOV.VLFRETECONHEC - ((CASE WHEN NVL(PCMOVCOMPLE.APROVEITACREDPISCOFINSCONT,'N')  = 'S' THEN
                                                                       (VLCREDPISFRETEFOB + VLCREDCOFINSFRETEFOB) ELSE 0 END)
                                                                       +
                                                                  (CASE WHEN NVL(PCMOV.APROVEITACREDICMS,'N') = 'S' THEN
                                                                        PCMOVCOMPLE.VLICMSFRETEFOB ELSE 0 END)
                                     ),6) AS BASECUSTOCONT,
                                     ------------------------------------------------------
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     PCNFENT.ESPECIE,
                                     PCNFENT.SERIE,
                                     TO_CHAR(PCNFENT.CODCONT) CODCONT,
                                     'Atualização de Custo por Importação' OBSERVACAO,
                                     -- COMPLEMENTO DE CUSTO CT-e
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCNFENT.NUMNOTA,
                                     PCNFENT.DTENT DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     --ROUND(PCMOV.QT, 2) QTCONT,
                                     0 QTCONT,
                                     --DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                     --       ROUND(PCMOV.QT, 6),0) QTENTRADA,
                                     0 QTENTRADA, 
                                     0 QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'ED',
                                            'ENTRADA DE DEVOLUÇÃO', 'E',
                                            'ENTRADA DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                     ROUND(PCMOV.VLFRETECONHEC, 6) PUNITCONT,
                                     ROUND(PCMOV.VLFRETECONHEC -
                                           DECODE(PCMOV.CODOPER, 'ED',
                                                  NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                  NVL(PCMOV.VLDESCONTO, 0)), 6) VALORITEMNOTA_ENT,
                                     0 VALORITEMNOTA_SAID,
                                     PCMOV.NUMTRANSENT,
                                     0 NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCNFENT.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     PCNFENT.TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,(NVL(PCMOV.VLFRETECONHEC,0) -
                                       (DECODE(NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0),0,NVL(PCMOVCOMPLE.VLICMSFRETEFOB,0),NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0)) +
                                       NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0))) VLFRETEFOB_LIQ
                                     ,NVL(ROUND(((NVL(PCMOVCOMPLE.PTABELACUSTO,DECODE(PCMOV.PTABELA,0,PCMOV.PUNITCONT,PCMOV.PTABELA))
                                      - NVL(PCMOVCOMPLE.VLDESCONTOCUSTO,NVL(PCMOV.VLDESCONTO,0)))
                                      + NVL(PCMOVCOMPLE.VLFRETENFCUSTO,NVL(PCMOV.VLFRETE,0))
                                      + NVL(PCMOVCOMPLE.VLSEGUROCUSTO,NVL(PCMOV.VLSEGURO,0))
                                      + NVL(PCMOVCOMPLE.VLCAPATAZIACUSTO,0)
                                      + NVL(PCMOVCOMPLE.VLDESPDENTRONFCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + NVL(PCMOV.VLIMPORTACAO,0)
                                      + NVL(PCMOV.ST,0)
                                      + NVL(PCMOVCOMPLE.VLSISCOMEXCUSTO,NVL(PCMOV.VLSISCOMEX, 0))
                                      + NVL(PCMOVCOMPLE.VLAFRMMCUSTO, 0)
                                      + NVL(PCMOVCOMPLE.VLADUANEIRACUSTO,NVL(PCMOV.VLADUANEIRA, 0))
                                      + NVL(PCMOVCOMPLE.VLOUTRASDESPIMPCUSTO,NVL(PCMOV.VLOUTRASDESPIMP,0))
                                      + NVL(PCMOV.VLDESPADICIONAL,0)
                                      -- Pis e cofins
                                      + CASE
                                         WHEN PCNFENT.TIPODESCARGA IN ('N','I') THEN
                                           (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLPISCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLPISCALCDI, 0) - NVL(PCMOV.VLCREDPIS, 0))
                                             ELSE
                                               0
                                           END)
                                        + (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLCOFINSCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0) - NVL(PCMOV.VLCREDCOFINS, 0))
                                             ELSE
                                               0
                                           END)
                                        ELSE
                                          0
                                        END
                                      + NVL(PCMOVCOMPLE.VLOUTROSCUSTOSCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + (NVL(PCMOV.VLFRETECONHEC,0) - (NVL(VLICMSCUSTOFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0)))
                                       ),6),0) CUSTO_SEM_IPI_PIS_COFINS
                                    ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                    ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                    ,PCNFENT.NUMTRANSORIGEM                                                -- 68
                                    ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND PCNFENT.TIPODESCARGA = 'I'
                                AND PCNFENT.ESPECIE = 'CT'
                                AND DECODE(PGERA_NF_ENTRADA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                                AND PCMOV.STATUS = 'B'
                                AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                                AND PCMOV.CODOPER <> 'EV'
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND (PMOSTRARAJUSTESCUSTO = 'S')
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)
    )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- ENTRADA SERVIÇO AJUSTANDO O CUSTO - ESPECIE = NS --
 --------------------------------------------------------------------------------------------------------------
   FOR DADOS IN             (SELECT 'ES' TIPO,
                                     PCMOV.SEQMOV,
                                     ROUND(PCMOVCOMPLE.VLNFSERVICO - ( -- CASE SOMANDO PIS E COFINS, CASO PARAMETRO COMO SIM.
                                                                         (CASE WHEN NVL(PCNFENT.CALCREDPISSERVICOCONT,'N') = 'S' THEN
                                                                               (VLCREDPISFRETEFOB + VLCREDCOFINSFRETEFOB) ELSE 0 END))
                                     ,6) AS BASECUSTOCONT,
                                     ---------------------
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     PCNFENT.ESPECIE,
                                     PCNFENT.SERIE,
                                     TO_CHAR(PCNFENT.CODCONT) CODCONT,
                                     'COMPLEMENTO DE CUSTO NOTA DE SERVIÇO' OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCNFENT.NUMNOTA,
                                     PCNFENT.DTENT DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     ROUND(PCMOV.QT, 2) QTCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                            ROUND(PCMOV.QT, 6),0) QTENTRADA,
                                     0 QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'ED',
                                            'ENTRADA DE DEVOLUÇÃO', 'E',
                                            'ENTRADA DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                     ROUND(PCMOVCOMPLE.VLNFSERVICO, 6) PUNITCONT,
                                     ROUND(PCMOVCOMPLE.VLNFSERVICO -
                                           DECODE(PCMOV.CODOPER, 'ED',
                                                  NVL(PCMOV.ST, 0) + NVL(PCMOV.VLIPI, 0),
                                                  NVL(PCMOV.VLDESCONTO, 0)), 6) VALORITEMNOTA_ENT,
                                     0 VALORITEMNOTA_SAID,
                                     PCMOV.NUMTRANSENT,
                                     0 NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCNFENT.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     PCNFENT.TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,(NVL(PCMOV.VLFRETECONHEC,0) -
                                       (DECODE(NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0),0,NVL(PCMOVCOMPLE.VLICMSFRETEFOB,0),NVL(PCMOVCOMPLE.VLICMSCUSTOFRETEFOB,0)) +
                                       NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0))) VLFRETEFOB_LIQ
                                     ,NVL(ROUND(((NVL(PCMOVCOMPLE.PTABELACUSTO,DECODE(PCMOV.PTABELA,0,PCMOV.PUNITCONT,PCMOV.PTABELA))
                                      - NVL(PCMOVCOMPLE.VLDESCONTOCUSTO,NVL(PCMOV.VLDESCONTO,0)))
                                      + NVL(PCMOVCOMPLE.VLFRETENFCUSTO,NVL(PCMOV.VLFRETE,0))
                                      + NVL(PCMOVCOMPLE.VLSEGUROCUSTO,NVL(PCMOV.VLSEGURO,0))
                                      + NVL(PCMOVCOMPLE.VLCAPATAZIACUSTO,0)
                                      + NVL(PCMOVCOMPLE.VLDESPDENTRONFCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + NVL(PCMOV.VLIMPORTACAO,0)
                                      + NVL(PCMOV.ST,0)
                                      + NVL(PCMOVCOMPLE.VLSISCOMEXCUSTO,NVL(PCMOV.VLSISCOMEX, 0))
                                      + NVL(PCMOVCOMPLE.VLAFRMMCUSTO, 0)
                                      + NVL(PCMOVCOMPLE.VLADUANEIRACUSTO,NVL(PCMOV.VLADUANEIRA, 0))
                                      + NVL(PCMOVCOMPLE.VLOUTRASDESPIMPCUSTO,NVL(PCMOV.VLOUTRASDESPIMP,0))
                                      + NVL(PCMOV.VLDESPADICIONAL,0)
                                      -- Pis e cofins
                                      + CASE
                                         WHEN PCNFENT.TIPODESCARGA IN ('N','I') THEN
                                           (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLPISCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLPISCALCDI, 0) - NVL(PCMOV.VLCREDPIS, 0))
                                             ELSE
                                               0
                                           END)
                                        + (CASE
                                             WHEN (NVL(PCMOVCOMPLE.VLCOFINSCALCDI,0) > 0) THEN
                                               (NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0) - NVL(PCMOV.VLCREDCOFINS, 0))
                                             ELSE
                                               0
                                           END)
                                        ELSE
                                          0
                                        END
                                      + NVL(PCMOVCOMPLE.VLOUTROSCUSTOSCUSTO,NVL(PCMOV.VLDESPDENTRONF, CASE
                                                                                                         WHEN (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0)) > 0 THEN
                                                                                                            (NVL(PCMOV.VLOUTRASDESP, 0) - NVL(PCMOV.VLSEGURO, 0))
                                                                                                         ELSE 0
                                                                                                      END))
                                      + (NVL(PCMOV.VLFRETECONHEC,0) - (NVL(VLICMSCUSTOFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDPISFRETEFOB,0) + NVL(PCMOVCOMPLE.VLCREDCOFINSFRETEFOB,0)))
                                       ),6),0) CUSTO_SEM_IPI_PIS_COFINS
                                    ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                    ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                    ,PCNFENT.NUMTRANSORIGEM                                                -- 68
                                    ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND PCNFENT.TIPODESCARGA = 'I'
                                AND PCNFENT.ESPECIE = 'NS'
                                AND DECODE(PGERA_NF_ENTRADA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                                AND PCMOV.STATUS = 'B'
                                AND NVL(PCNFENT.NFENTREGAFUTURA, 'N') = 'N'
                                AND PCMOV.CODOPER <> 'EV'
                                AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND PMOSTRARAJUSTESCUSTO = 'S'
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1))
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- ENTRADA ER -- ESTORNO REF.FATURAMENTO DE CONSIGNADO. Esse lançamento faz a contra partida da segunda nota de saída do consignado.
 --------------------------------------------------------------------------------------------------------------
   FOR DADOS IN             (SELECT 'ER' TIPO, 
                                     PCMOV.SEQMOV,
                                     0 BASECUSTOCONT,
                                     0 CUSTOCONT,
                                     0 CUSTOFIN,
                                     0 CUSTOREAL,
                                     0 CUSTOREP,
                                     0 CUSTOULTENT,
                                     0 CUSTOREALSEMST,
                                     0 VALORULTENT,
                                     'ER' ESPECIE,
                                     '' SERIE,
                                     '' CODCONT,
                                     'Ent.Ref.Fat.Consignado' OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCMOV.NUMNOTA,
                                     PCMOV.DTMOV DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     -----------------------------------------
                                     PCMOV.CODFISCAL,
                                     ROUND(PCMOV.QTCONT,PNUMCASAS_QT) QTCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                            ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTENTRADA,
                                     0 QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     'Ent.Ref.Fat.Consignado' HISTORICO,
                                     0 PUNITCONT,
                                     0  VALORITEMNOTA_ENT,
                                     0 VALORITEMNOTA_SAID,
                                     PCMOV.NUMTRANSENT,
                                     0 NUMTRANSVENDA,
                                     0 VLIPI,
                                     0 ST,
                                     0 STGUIA,
                                     PCMOV.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     '' TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                    ,PCMOV.CUSTOCONTANT
                                    ,PCMOV.ROTINACAD
                                    ,0 VLFRETEFOB_LIQ
                                    ,0 CUSTO_SEM_IPI_PIS_COFINS
                                    ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                    ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                    ,0 NUMTRANSORIGEM                                                -- 68
                                    ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCMOV, PCMOVCOMPLE, PCPEDC P, PCPRODUT
                              WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                                AND DTMOV between PDTINICIO AND PDTFIM
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCMOV.QTCONT > 0
                                AND PCMOV.STATUS = 'AB'
                                AND PCMOV.CODOPER = 'ER'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND PDESCONS_ENT_AJUSTE_ER = 'N'
                                AND NVL(PCMOV.NUMPED,0) = NVL(P.NUMPED,0)
                                AND NVL(P.NUMNOTACONSIG,0) > 0
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)  )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- SAIDA --
 --------------------------------------------------------------------------------------------------------------
 FOR DADOS IN              (SELECT 'S' TIPO,
                                   PCMOV.SEQMOV,
                                   0 BASECUSTOCONT,
                                   PCMOV.CUSTOCONT,
                                   PCMOV.CUSTOFIN,
                                   PCMOV.CUSTOREAL,
                                   PCMOV.CUSTOREP,
                                   PCMOV.CUSTOULTENT,
                                   PCMOV.CUSTOREALSEMST,
                                   PCMOV.VALORULTENT,
                                   PCNFSAID.ESPECIE,
                                   PCNFSAID.SERIE,
                                   PCNFSAID.CODCONT,
                                   PCNFSAID.OBS OBSERVACAO,
                                   PCMOV.CODPROD,
                                   PCMOV.CODOPER,
                                   PCMOV.NUMNOTA,
                                   PCNFSAID.DTSAIDA DATA,
                                   PCMOV.DTMOVLOG,
                                   -- CONFIGURANDO HORA_LANC
                                   CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                        WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                             TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                        ELSE PCMOV.HORALANC END HORALANC,
                                   --
                                   PCMOV.CODFISCAL,
                                   NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTCONT,
                                   0 QTENTRADA,
                                   NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'S',
                                              ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0),0) QTSAIDA,
                                   case when PCMOV.CODFISCAL between 6000 AND 7000 then
                                      0
                                   else
                                      NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                   END QTSAIDA_DENTRO,
                                   case when PCMOV.CODFISCAL between 6000 AND 7000 then
                                      NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                   else
                                      0
                                   END QTSAIDA_FORA,
                                   DECODE(PCMOV.CODOPER, 'SD',
                                          'SAIDAS DE DEVOLUÇÃO', 'S',
                                          'SAIDAS DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                   NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S',
                                                    PCMOV.PBONIFIC, PCMOV.PUNITCONT), PNUMCASAS_UNIT), 0) PUNITCONT,
                                   0 VALORITEMNOTA_ENT,
                                   ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S', PCMOV.PBONIFIC, PCMOV.PUNITCONT) -
                                         DECODE(PCMOV.CODOPER, 'SD', NVL(PCMOV.VLFRETE, 0), 0), PNUMCASAS_UNIT) VALORITEMNOTA_SAID,
                                   0 NUMTRANSENT,
                                   PCMOV.NUMTRANSVENDA,
                                   NVL(PCMOV.VLIPI, 0) VLIPI,
                                   NVL(PCMOV.ST, 0) ST,
                                   NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                   PCNFSAID.DTCANCEL,
                                   PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                   NULL TIPODESCARGA
                                   -- CONFIGURANDO MINUTO_LANC
                                   ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                         WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                             TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                        ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                   ---------------------------------------
                                   ,PCMOV.CUSTOCONTANT
                                   ,PCMOV.ROTINACAD
                                   ,0 VLFRETEFOB_LIQ
                                   ,0 CUSTO_SEM_IPI_PIS_COFINS
                                   ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                   ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                   ,0 NUMTRANSORIGEM                                                -- 68
                                   ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                  ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                  ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                  ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                  ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                  ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                  ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                  ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                            FROM PCNFSAID, PCMOV, PCMOVCOMPLE, PCPRODUT
                      WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                        AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                        AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                        AND PCMOV.CODPROD = PCPRODUT.CODPROD
                        AND PCNFSAID.DTSAIDA BETWEEN PDTINICIO AND PDTFIM
                        AND PCMOV.DTMOV BETWEEN PDTINICIO AND PDTFIM
                        AND DECODE(PGERA_NF_SAIDA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                        AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCODFILIAL
                        AND PCMOV.QTCONT > 0
                        AND PCNFSAID.ESPECIE in ('NF', 'CF', 'CP','NE','TP')
                        AND PCMOV.STATUS in ('A', 'AB')
                        AND NVL(PCNFSAID.CONDVENDA, 0) not in (3, 6, DECODE(PCNFSAID.FORNECENTREGA, 'S', -1, 7), 12, DECODE(PVENDAMANIF_COMTV14, 'S', 13, 14))
                        AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                        AND NVL(PCNFSAID.FINALIDADENFE, 'O') <> 'C'
                        AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                        AND DECODE(PATIVIOMOBULIZADO,'N', NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                        AND ((PDESCONSIDERANFEDENEGADA = 'N') OR
                            ((PDESCONSIDERANFEDENEGADA = 'S') AND NVL(PCNFSAID.SITUACAONFE,'0') NOT IN (110,205,301,302)))
                        AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                        AND CASE WHEN PCMOV.CODOPER = 'SD' THEN  
                               PCNFSAID.NUMTRANSVENDA END NOT IN (SELECT F.NUMTRANSVENDA 
                                                                    FROM PCDEVFORNEC F, PCNFENT E 
                                                                   WHERE F.NUMTRANSENT = E.NUMTRANSENT 
                                                                     AND E.TIPODESCARGA = 'H'
                                                                     AND NVL(E.CODFILIALNF, E.CODFILIAL) = PCODFILIAL
                                                                     AND F.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA)                                
                        AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                        AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCNFSAID.NFBRINDE,'N'),'N') <> 'S'
                        AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                  WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                  WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                  ELSE 0 END = 1)                                     
                              )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 -----------------------------------------------------------------------------------------------
 -- SAIDA CANCELADA --
   FOR DADOS IN (             SELECT 'SC' TIPO, -- Notas fiscais canceladas
                                     PCMOV.SEQMOV,
                                     0 BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     PCNFSAID.ESPECIE,
                                     PCNFSAID.SERIE,
                                     PCNFSAID.CODCONT,
                                     PCNFSAID.OBS OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCMOV.NUMNOTA,
                                     trunc(PCMOV.DTCANCEL) DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTCONT,
                                     0 QTENTRADA,

                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1),'S',
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT),0), 0) QTSAIDA,
                                     case when PCMOV.CODFISCAL between 6000 AND 7000 then
                                        0
                                     else
                                        NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                     END QTSAIDA_DENTRO,
                                     case when PCMOV.CODFISCAL between 6000 AND 7000 then
                                        NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                     else
                                        0
                                     END QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'SD',
                                            'SAIDAS DE DEVOLUÇÃO', 'S',
                                            'SAIDAS DE MERCADORIAS', 'OUTRAS') HISTORICO,
                                     NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S',
                                                      PCMOV.PBONIFIC, PCMOV.PUNITCONT), PNUMCASAS_UNIT), 0) PUNITCONT,
                                     0 VALORITEMNOTA_ENT,
                                     ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S', PCMOV.PBONIFIC, PCMOV.PUNITCONT) -
                                           DECODE(PCMOV.CODOPER, 'SD', NVL(PCMOV.VLFRETE, 0), 0), PNUMCASAS_UNIT) VALORITEMNOTA_SAID,
                                     0 NUMTRANSENT,
                                     PCMOV.NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCNFSAID.DTCANCEL,
                                     PCMOV.SITTRIBUT SITUACAOTRIBUTARIA,
                                     NULL TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,0 VLFRETEFOB_LIQ
                                     ,0 CUSTO_SEM_IPI_PIS_COFINS
                                     ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                     ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                     ,0 NUMTRANSORIGEM                                                -- 68
                                     ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCNFSAID, PCMOV, PCMOVCOMPLE, PCPRODUT
                              WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                                AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                                AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                --Em caso de utilização manual do parametro V_DATA_CANCELAMENTO_FIM, o mesmo precisa estar no seguinte formato: TO_DATE(TO_CHAR(PDTFIM, 'DD/MM/YYYY') || ' 23:59:59', 'DD/MM/YYYY HH24:MI:SS');
                                AND PCNFSAID.DTCANCEL BETWEEN PDTINICIO AND V_DATA_CANCELAMENTO_FIM
                                AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCODFILIAL
                                AND PCMOV.QTCONT < 0
                                AND NVL(PCNFSAID.CONDVENDA, 0) not in (3, 6, DECODE(PCNFSAID.FORNECENTREGA, 'S', -1, 7), 12, DECODE(PVENDAMANIF_COMTV14, 'S', 13, 14))
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND PCNFSAID.ESPECIE IN ('NF', 'CF', 'CP','NE','TP')
                                AND PCMOV.DTCANCEL is not null
                                AND PGERA_NF_SAIDA_CANC = 'S' --- PARAMETRO EXTERNO
                                AND PCMOV.STATUS in ('A', 'AB')
                                AND NVL(PCNFSAID.FINALIDADENFE, 'O') <> 'C'
                                AND DECODE(PUSOCONSUMO, 'N', NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO, 'N', NVL(PCMOV.TIPOMERCDEPTO, 'X'), 'XX') <> 'IM'
                                AND ((PDESCONSIDERANFEDENEGADA = 'N') OR
                                    ((PDESCONSIDERANFEDENEGADA = 'S') AND NVL(PCNFSAID.SITUACAONFE,'0') NOT IN (110,205,301,302)))
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND CASE WHEN PCMOV.CODOPER = 'SD' THEN  
                                       PCNFSAID.NUMTRANSVENDA END NOT IN (SELECT F.NUMTRANSVENDA 
                                                                            FROM PCDEVFORNEC F, PCNFENT E 
                                                                           WHERE F.NUMTRANSENT = E.NUMTRANSENT 
                                                                             AND E.TIPODESCARGA = 'H'
                                                                             AND F.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA)                                
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCNFSAID.NFBRINDE,'N'),'N') <> 'S' 
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)  )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- ENTRADA PRODUÇÃO --
   FOR DADOS IN (            SELECT 'AE' TIPO,
                                     PCMOV.SEQMOV,
                                     (CASE WHEN PCMOV.CODOPER = 'EP' THEN
                                         NVL(PCMOV.CUSTOULTENT, 0)
                                      ELSE
                                         NVL(PCMOV.CUSTOCONT, 0)
                                      END) BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     -----------------------------------
                                     --PCMOV.CUSTOULTENT,
                                      (CASE WHEN PCMOV.CODOPER = 'EP' THEN
                                         NVL(PCMOV.CUSTOULTENT, 0)
                                      ELSE
                                         NVL(PCMOV.CUSTOCONT, 0)
                                      END) CUSTOULTENT,
                                     ----------------------------------
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     'OP' ESPECIE,
                                     ' ' SERIE,
                                     null CODCONT,
                                     DECODE(PCMOV.CODOPER, 'EA',
                                            'ENTRADA AJUSTE', 'EP',
                                            'ENTRADA PRODUÇÃO', 'EX',
                                            'DEV. AVULSA PRODUÇÃO', 'RA',
                                            'REQ. AVULSA PRODUÇÃO', 'SA',
                                            'SAÍDA AJUSTE', 'SP',
                                            'SAÍDA DE PRODUÇÃO', 'OUTRAS DE PRODUÇÃO') OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     ------------------------------------------------
                                     CASE WHEN PCMOV.CODOPER LIKE 'E%' THEN
                                          NVL(PCMOV.NUMOP,PCMOV.NUMTRANSENT)
                                          ELSE
                                          NVL(PCMOV.NUMOP,PCMOV.NUMTRANSVENDA)
                                          END NUMNOTA,
                                     ------------------------------------------------
                                     PCMOV.DTMOV AS DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTCONT,
                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0),  0) QTENTRADA,
                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', 0,
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT)), 0) QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'EA',
                                            'ENTRADA AJUSTE', 'EP',
                                            'ENTRADA PRODUÇÃO', 'EX',
                                            'DEV. AVULSA PRODUÇÃO', 'RA',
                                            'REQ. AVULSA PRODUÇÃO', 'SA',
                                            'SAÍDA AJUSTE', 'SP',
                                            'SAÍDA DE PRODUÇÃO', 'OUTRAS DE PRODUÇÃO') HISTORICO,
                                     NVL(ROUND(PCMOV.PUNITCONT, PNUMCASAS_UNIT), 0) PUNITCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', PCMOV.PUNITCONT, 0) VALORITEMNOTA_ENT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', 0, PCMOV.PUNITCONT) VALORITEMNOTA_SAID,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', PCMOV.NUMTRANSENT, 0) NUMTRANSENT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', 0, PCMOV.NUMTRANSVENDA) NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCMOV.DTCANCEL,
                                     NULL SITUACAOTRIBUTARIA,
                                     NULL TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,0 VLFRETEFOB_LIQ
                                     ,0 CUSTO_SEM_IPI_PIS_COFINS
                                     ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                     ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                     ,0 NUMTRANSORIGEM                                                -- 68
                                     ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCMOV, PCMOVCOMPLE, PCPRODUT
                              WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                                AND PCMOV.DTMOV between PDTINICIO AND PDTFIM
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCMOV.QTCONT > 0
                                AND DECODE(PGERACANCPRODUCAO,'N',PCMOV.DTCANCEL, NULL ) IS NULL
                                AND PCMOV.CODOPER in ('EP', 'SP', 'EA', 'SA', 'EX', 'RA')
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND not exists (SELECT 1
                                                FROM PCNFSAID
                                                WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                                                  AND PCNFSAID.ESPECIE = 'NF'
                                                  AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCODFILIAL
                                                  AND PCNFSAID.VLTOTAL > 0)
                                AND PCMOV.STATUS in ('A', 'AB')
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'        
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)
)
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;            

      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- ENTRADA PRODUÇÃO CANCELADA --
 FOR DADOS IN (              SELECT 'AC' TIPO, ---- Entrada produção cancelada
                                     PCMOV.SEQMOV,
                                     (CASE WHEN PCMOV.CODOPER = 'EP' THEN
                                         NVL(PCMOV.CUSTOULTENT, 0)
                                      ELSE
                                         NVL(PCMOV.CUSTOCONT, 0)
                                      END) BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     'OP' ESPECIE,
                                     ' ' SERIE,
                                     null CODCONT,
                                     DECODE(PCMOV.CODOPER, 'EA',
                                            'ENT.AJUSTE - CANCELADA', 'EP',
                                            'ENT.PRODUÇÃO - CANCELADA', 'EX',
                                            'DEV.AVULSA PRODUÇÃO - CANCELADA', 'RA',
                                            'REQ. AVULSA PRODUÇÃO', 'SA',
                                            'SAÍDA AJUSTE - CANCELADA', 'SP',
                                            'SAÍDA DE PRODUÇÃO - CANCELADA', 'OUTRAS DE PRODUÇÃO - CANCELADA') OBSERVACAO,
                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     ------------------------------------------------
                                     CASE WHEN PCMOV.CODOPER LIKE 'E%' THEN
                                          NVL(PCMOV.NUMOP,PCMOV.NUMTRANSENT)
                                          ELSE
                                          NVL(PCMOV.NUMOP,PCMOV.NUMTRANSVENDA)
                                          END NUMNOTA,
                                     ------------------------------------------------
                                     PCMOV.DTMOV AS DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTCONT,
                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E',
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0), 0) QTENTRADA,
                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'E', 0,
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT)),0) QTSAIDA,
                                     0 QTSAIDA_DENTRO,
                                     0 QTSAIDA_FORA,
                                     DECODE(PCMOV.CODOPER, 'EA',
                                              'ENTRADA AJUSTE', 'EP',
                                              'ENTRADA PRODUÇÃO', 'EX',
                                              'DEV. AVULSA PRODUÇÃO', 'RA',
                                              'REQ. AVULSA PRODUÇÃO', 'SA',
                                              'SAÍDA AJUSTE', 'SP',
                                              'SAÍDA DE PRODUÇÃO', 'OUTRAS DE PRODUÇÃO') HISTORICO,
                                     NVL(ROUND(PCMOV.PUNITCONT, PNUMCASAS_UNIT), 0) PUNITCONT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1),'E',PCMOV.PUNITCONT,0) VALORITEMNOTA_ENT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1),'E',0,PCMOV.PUNITCONT) VALORITEMNOTA_SAID,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1),'E',PCMOV.NUMTRANSENT, 0) NUMTRANSENT,
                                     DECODE(SUBSTR(PCMOV.CODOPER, 1, 1),'E',0,PCMOV.NUMTRANSVENDA) NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCMOV.DTCANCEL,
                                     NULL SITUACAOTRIBUTARIA,
                                     NULL TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,0 VLFRETEFOB_LIQ
                                     ,0 CUSTO_SEM_IPI_PIS_COFINS
                                     ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                     ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                     ,0 NUMTRANSORIGEM                                                -- 68
                                     ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCMOV, PCMOVCOMPLE, PCPRODUT
                              WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                                --AND PCMOV.DTMOV between PDTINICIO AND PDTFIM
                                AND PCMOV.DTCANCEL between PDTINICIO AND V_DATA_CANCELAMENTO_FIM
                                AND PCMOV.QTCONT < 0
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCMOV.DTCANCEL is not null
                                AND PCMOV.CODOPER in  ('EP', 'SP', 'EA', 'SA', 'EX', 'RA')
                                AND DECODE(PUSOCONSUMO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCMOV.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                AND not exists (SELECT 1 FROM PCNFSAID WHERE NUMTRANSVENDA = PCMOV.NUMTRANSVENDA)
                                AND PCMOV.STATUS in ('A', 'AB')
                                AND PGERACANCPRODUCAO = 'S'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'        
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1) 
                    )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 --------------------------------------------------------------------------------------------------------------
 -- SAIDA REQUISIÇÃO (SM)--
 FOR DADOS IN (               SELECT 'SM' TIPO,
                                     PCMOV.SEQMOV,
                                     0 BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,

                                     CASE WHEN PGERA_NUMOP_NA_OBS = 'S' THEN '' ELSE 'OP' END ESPECIE,
                                     'SM' SERIE,
                                       NULL CODCONT,
                                     CASE WHEN PGERA_NUMOP_NA_OBS = 'S' THEN
                                         'Requisição Nº '||PCMOV.NUMTRANSOP
                                     ELSE
                                         'Requisição de material de consumo' END OBSERVACAO,

                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCMOV.NUMTRANSVENDA NUMNOTA,
                                     PCMOV.DTMOV DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                          ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTCONT,
                                     0 QTENTRADA,
                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'S',
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0), 0) QTSAIDA,
                                     CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000 THEN
                                        0
                                     ELSE
                                        NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                     END QTSAIDA_DENTRO,
                                     CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000 THEN
                                        NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                     ELSE
                                        0
                                     END QTSAIDA_FORA,
                                     'SAIDA MAT. USO/CONS' HISTORICO,
                                     NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S', PCMOV.PBONIFIC,
                                                      PCMOV.PUNITCONT), PNUMCASAS_UNIT), 0) PUNITCONT,
                                     0 VALORITEMNOTA_ENT,
                                     ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S', PCMOV.PBONIFIC,
                                                  PCMOV.PUNITCONT), PNUMCASAS_UNIT) VALORITEMNOTA_SAID,
                                     0 NUMTRANSENT,
                                     PCMOV.NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCMOV.DTCANCEL,
                                     NULL SITUACAOTRIBUTARIA,
                                     NULL TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,0 VLFRETEFOB_LIQ
                                     ,0 CUSTO_SEM_IPI_PIS_COFINS
                                     ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                     ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                     ,0 NUMTRANSORIGEM                                                -- 68
                                     ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                                FROM PCMOV, PCMOVCOMPLE, PCPRODUT
                              WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                                AND PCMOV.DTMOV BETWEEN PDTINICIO AND PDTFIM
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCMOV.QTCONT > 0
                                AND DECODE(PGERA_SM_KARDEX_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                                AND PCMOV.STATUS IN ('A', 'AB')
                                AND PCMOV.CODOPER = 'SM'
                                AND PGERACODOPERSMKARDEX = 'S'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1) 
                    )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
 
--- SAIDA REQUISIÇÃO (SM-CANCELADO)---------------------------------------------------------
  FOR DADOS IN (              SELECT 'SM' TIPO, -- Requisição CANCELADA
                                     PCMOV.SEQMOV,
                                     0 BASECUSTOCONT,
                                     PCMOV.CUSTOCONT,
                                     PCMOV.CUSTOFIN,
                                     PCMOV.CUSTOREAL,
                                     PCMOV.CUSTOREP,
                                     PCMOV.CUSTOULTENT,
                                     PCMOV.CUSTOREALSEMST,
                                     PCMOV.VALORULTENT,
                                     CASE WHEN PGERA_NUMOP_NA_OBS = 'S' THEN '' ELSE 'OP' END ESPECIE,
                                     'SM' SERIE,
                                       NULL CODCONT,
                                     CASE WHEN PGERA_NUMOP_NA_OBS = 'S' THEN
                                         'Requisição Nº '||PCMOV.NUMTRANSOP
                                     ELSE
                                         'Requisição de material de consumo' END OBSERVACAO,                                     PCMOV.CODPROD,
                                     PCMOV.CODOPER,
                                     PCMOV.NUMTRANSVENDA NUMNOTA,
                                     PCMOV.DTMOV DATA,
                                     PCMOV.DTMOVLOG,
                                     -- CONFIGURANDO HORA_LANC
                                     CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.HORALANC
                                          WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'HH24')
                                         ELSE PCMOV.HORALANC END HORALANC,
                                     --
                                     PCMOV.CODFISCAL,
                                     NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0) QTCONT,
                                     0 QTENTRADA,
                                     NVL(DECODE(SUBSTR(PCMOV.CODOPER, 1, 1), 'S',
                                                ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0), 0) QTSAIDA,
                                     CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000 THEN
                                        0
                                     ELSE
                                        NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                     END QTSAIDA_DENTRO,
                                     CASE WHEN PCMOV.CODFISCAL BETWEEN 6000 AND 7000 THEN
                                        NVL(ROUND(PCMOV.QTCONT, PNUMCASAS_QT), 0)
                                     ELSE
                                        0
                                     END QTSAIDA_FORA,
                                     'SAID MAT.USO/CONS-CANC' HISTORICO,
                                     NVL(ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S', PCMOV.PBONIFIC,
                                                      PCMOV.PUNITCONT), PNUMCASAS_UNIT), 0) PUNITCONT,
                                     0 VALORITEMNOTA_ENT,
                                     ROUND(DECODE(NVL(PCMOV.BRINDE, 'N'), 'S', PCMOV.PBONIFIC,
                                                  PCMOV.PUNITCONT), PNUMCASAS_UNIT) VALORITEMNOTA_SAID,
                                     0 NUMTRANSENT,
                                     PCMOV.NUMTRANSVENDA,
                                     NVL(PCMOV.VLIPI, 0) VLIPI,
                                     NVL(PCMOV.ST, 0) ST,
                                     NVL(PCMOV.VLDESPADICIONAL, 0) STGUIA,
                                     PCMOV.DTCANCEL,
                                     NULL SITUACAOTRIBUTARIA,
                                     NULL TIPODESCARGA
                                     -- CONFIGURANDO MINUTO_LANC
                                     ,CASE WHEN PORDENAR_PCMOVLOG = 'N' THEN PCMOV.MINUTOLANC
                                           WHEN PORDENAR_PCMOVLOG = 'S' AND PCMOV.DTMOV = TRUNC(PCMOV.DTMOVLOG) THEN
                                               TO_CHAR(PCMOV.DTMOVLOG, 'MI')
                                          ELSE PCMOV.MINUTOLANC END MINUTOLANC
                                     ---------------------------------------
                                     ,PCMOV.CUSTOCONTANT
                                     ,PCMOV.ROTINACAD
                                     ,0 VLFRETEFOB_LIQ
                                     ,0 CUSTO_SEM_IPI_PIS_COFINS
                                     ,PCMOV.ROWID ID_PCMOV                                                  -- 63
                                     ,PCMOVCOMPLE.ROWID ID_PCMOVCOMPLE
                                     ,0 NUMTRANSORIGEM                                                -- 68
                                     ,NVL(PCMOV.VLCREDICMS,NVL(PCMOVCOMPLE.VLICMS,0)) VLR_CRED_ICMS
                                    ,NVL(PCMOVCOMPLE.CUSTOULTENTCONT,0) CUSTOULTENTCONT
                                    ,NVL(PCMOV.NUMSEQ,1) NUMSEQ
                                    ,(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.PERCICM,0) / 100) VLR_ICMS_REAL
                                    ,NVL(PCMOV.VLCREDCOFINS,PCMOV.VLCOFINS) VLR_CRED_COFINS
                                    ,NVL(PCMOV.VLCREDPIS,PCMOV.VLPIS) VLR_CRED_PIS
                                    ,NVL(PCMOV.NBM, PCPRODUT.NBM) AS NCM
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) CUSTOFISCAL
                              FROM PCMOV, PCMOVCOMPLE, PCPRODUT
                              WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                                AND PCMOV.DTCANCEL BETWEEN PDTINICIO AND PDTFIM -- alterado de dtmov para dtcancel (Gleibe 17/07/2018)
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCMOV.QTCONT < 0 -- incluido
                                AND PCMOV.DTCANCEL IS NOT NULL
                                AND PCMOV.STATUS IN ('A', 'AB')
                                AND PCMOV.CODOPER = 'SM'
                                AND PGERA_SM_KARDEX_CANC = 'S'
                                AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD'
                                AND NVL(PCMOV.MOVESTOQUECONTABIL,'S') = 'S'
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1) 
                    )
    LOOP
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.SEQMOV         := DADOS.SEQMOV;
            OUTROW.BASECUSTOCONT  := DADOS.BASECUSTOCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.HORALANC       := DADOS.HORALANC;
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTENTRADA      := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.QTSAIDA        := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VALORITEMNOTA_ENT  := DADOS.VALORITEMNOTA_ENT;            
            OUTROW.VALORITEMNOTA_SAID := DADOS.VALORITEMNOTA_SAID;            
            OUTROW.NUMTRANSENT        := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA      := DADOS.NUMTRANSVENDA;
            OUTROW.VLIPI              := DADOS.VLIPI;
            OUTROW.ST                 := DADOS.ST;
            OUTROW.STGUIA             := DADOS.STGUIA;
            OUTROW.DTCANCEL           := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.MINUTOLANC         := DADOS.MINUTOLANC;
            OUTROW.ROTINACAD          := DADOS.ROTINACAD;
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.CODFILIAL          := SUBSTR(PCODFILIAL,0,2);
            OUTROW.NCM                := DADOS.NCM;
            OUTROW.DTMOVLOG           := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL        := DADOS.CUSTOFISCAL;
      pipe row(OUTROW);
  END LOOP;
EXCEPTION
  when others then
    RAISE_APPLICATION_ERROR(-20000,
                            'OCORREU UM ERRO AO PROCESSAR O CONTROLE DE PRODUÇÃO!' ||
                            CHR(13) || 'ERRO ORIGINAL: ' || sqlerrm);
END;
----------------------------------------------------------------------------
-- Alt.: 08/08/2024 - Implementado ajuste nos sqls AC na coluna CUSTOULTENT
-- Alt.: 26/07/2024 - Implementado ajuste nos sqls AE e SM para considerar NVL no campo PCMOV.CODFISCAL 
----------------------------------------------------------------------------