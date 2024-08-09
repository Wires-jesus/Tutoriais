CREATE OR REPLACE PROCEDURE PRC_CONTROLE_PRODUCAO(PCODFILIAL            in varchar2,
                                                  PDTINICIO             in date,
                                                  PDTFIM                in date,
                                                  PDTINVENTARIO         in date default null,
                                                  PTIPOCUSTO            in number default 0, -- (0-6)
                                                  PPROD_SEM_MOV         in varchar2 default 'N', -- (S/N)
                                                  PUTILIZA_METODO_PEPS  in varchar2 default 'N',
                                                  PUTILIZA_PRECO_NOTA   in varchar2 default 'N',
                                                  PNUMCASAS_QT          in number default 3,
                                                  PNUMCASAS_UNIT        in number default 6,
                                                  PNUMCASAS_TOTAL       in number default 2,
                                                  PUSOCONSUMO           in varchar default 'S',
                                                  PATIVIOMOBULIZADO     in varchar default 'S',
                                                  PGERACANCPRODUCAO     in varchar default 'N',
                                                  PGERACODOPERSMKARDEX  in varchar default 'N',
                                                  PCODPROD1             in number default 0,
                                                  PCODPROD2             in number default 9999999999,
                                                  PVENDAMANIF_COMTV14   in varchar2 default 'N',
                                                  PGERA_SM_KARDEX_CANC  in varchar default 'N',
                                                  PGERA_NF_ENTRADA_CANC in varchar default 'N',
                                                  PGERA_NF_SAIDA_CANC   in varchar default 'N',
                                                  PDESC_NF_TRANSF_DEP   in varchar default 'N',
                                                  PDESCONSIDERANFEDENEGADA in varchar default 'N',
                                                  PMOSTRARAJUSTESCUSTO in varchar default 'N',
                                                  PORDENAR_PCMOVLOG    in varchar default 'N',
                                                  V_FIL_CALCREDPISFRETECONT in varchar,
                                                  V_UTICREDICMSFRETEFOBCUSTOCONT in varchar,
                                                  V_CALCREDPISCOFINSSERVICOCONT in varchar,
                                                  PGERA_NUMOP_NA_OBS in varchar default 'N',
                                                  PCONSIDERARCUSTOBONIF in varchar default 'N',
                                                  PDESCONS_CUSTO_DEVCLI    in varchar2 default 'N',-- (S) Descons.o custo da NF de entrada devolução de cliente e mantem o custo anterior.
                                                  PDESCONS_CUSTO_NFENTCANC in varchar2 default 'N',-- (S) Descons.o custo da NF de entrada cancelada e mantem o custo anterior.
                                                  PDESCONS_ENT_AJUSTE_ER   in varchar2 default 'N',-- (S) Excluí o lançamento CODOPER = ER (Ajuste de saída consignada rot 1437)
                                                  PDESCONS_ITEM_BRINDE     in varchar2 default 'S', -- (S) Descons.item de brinde do estoque e movimentação. 
                                                  PSTATUSPROD              in varchar2 default 'T'  -- 27 - Status do Produto DTEXCLUSAO - T - Todos / A - Ativo / I - Inativo                                                  
                                                  ) IS
  ---------------------------------------------------------------------------------
  -- Procedure para popular tabela PCDADOS1070_TEMP
  ---------------------------------------------------------------------------------
  -- Criado por: Gleibe em 28/06/2016
  -- Será utilizada na função F_CONTROLE_PRODUCAO:
  ---------------------------------------------------------------------------------
  -- Type de estrutura da tabela TR_MOV_1070
  TYPE TR_MOV_1070 IS RECORD (
    TIPO               PCNFENT.ESPECIE%TYPE
   ,SEQMOV             PCMOV.SEQMOV%TYPE
   ,BASECUSTOCONT      PCMOV.PUNITCONT%TYPE
   ,CUSTOCONT          PCMOV.CUSTOCONT%TYPE
   ,CUSTOCONTANT       PCMOV.CUSTOCONT%TYPE
   ,CUSTOFIN           PCMOV.PUNITCONT%TYPE
   ,CUSTOREAL          PCMOV.PUNITCONT%TYPE
   ,CUSTOREP           PCMOV.PUNITCONT%TYPE
   ,CUSTOULTENT        PCMOV.PUNITCONT%TYPE
   ,CUSTOREALSEMST     PCMOV.PUNITCONT%TYPE
   ,VALORULTENT        PCMOV.PUNITCONT%TYPE
   ,ESPECIE            PCNFENT.ESPECIE%TYPE
   ,SERIE              PCNFENT.SERIE%TYPE
   ,CODCONT            PCNFENT.CODCONT%TYPE
   ,OBSERVACAO         PCNFENT.OBS%TYPE
   ,CODPROD            PCMOV.CODPROD%TYPE
   ,CODOPER            PCMOV.CODOPER%TYPE
   ,NUMNOTA            PCMOV.NUMNOTA%TYPE
   ,DATA               PCMOV.DTMOV%TYPE
   ,HORALANC           PCMOV.HORALANC%TYPE
   ,MINUTOLANC         PCMOV.HORALANC%TYPE
   ,CODFISCAL          PCMOV.CODFISCAL%TYPE
   ,QTCONT             PCMOV.QTCONT%TYPE
   ,QTENTRADA          PCMOV.QTCONT%TYPE
   ,QTSAIDA            PCMOV.QTCONT%TYPE
   ,QTSAIDA_DENTRO     PCMOV.QTCONT%TYPE
   ,QTSAIDA_FORA       PCMOV.QTCONT%TYPE
   ,HISTORICO          PCNFENT.OBS%TYPE
   ,PUNITCONT          PCMOV.PUNITCONT%TYPE
   ,VALORITEMNOTA_ENT  PCMOV.PUNITCONT%TYPE
   ,VALORITEMNOTA_SAID PCMOV.PUNITCONT%TYPE
   ,NUMTRANSENT        PCMOV.NUMTRANSENT%TYPE
   ,NUMTRANSVENDA      PCMOV.NUMTRANSVENDA%TYPE
   ,VLIPI              PCMOV.VLIPI%TYPE
   ,ST                 PCMOV.ST%TYPE
   ,STGUIA             PCMOV.ST%TYPE
   ,DTCANCEL           PCMOV.DTCANCEL%TYPE
   ,SITUACAOTRIBUTARIA PCMOV.SITTRIBUT%TYPE
   ,TIPODESCARGA       PCNFENT.TIPODESCARGA%TYPE
   );

  -- Variaveis de uso interno
  vrDADOS                 TR_MOV_1070;
  vcCURSOR                SYS_REFCURSOR;
  vnCONTADOR              NUMBER default 0;
  vsSQL                   VARCHAR2(10000);
  vsCREATE                VARCHAR2(4000);
  vsDELETE                VARCHAR2(500);
  vsINSERT                VARCHAR2(4000);
  V_DATA_CANCELAMENTO_FIM DATE;

  pragma autonomous_transaction;

  -- PROCEDURE INSERIR DADOS
  procedure INSERIR_DADOS(pTIPO               in varchar2,
                          pSEQMOV             in number,
                          pBASECUSTOCONT      in number,
                          pCUSTOCONT          in number,
                          pCUSTOFIN           in number,
                          pCUSTOREAL          in number,
                          pCUSTOREP           in number,
                          pCUSTOULTENT        in number,
                          pCUSTOREALSEMST     in number,
                          pVALORULTENT        in number,
                          pESPECIE            in varchar2,
                          pSERIE              in varchar2,
                          pCODCONT            in varchar2,
                          pOBSERVACAO         in varchar2,
                          pCODPROD            in number,
                          pCODOPER            in varchar2,
                          pNUMNOTA            in number,
                          pDATA               date,
                          pHORALANC           in varchar2,
                          pCODFISCAL          in number,
                          pQTCONT             in number,
                          pQTENTRADA          in number,
                          pQTSAIDA            in number,
                          pQTSAIDA_DENTRO     in number,
                          pQTSAIDA_FORA       in number,
                          pHISTORICO          in varchar2,
                          pPUNITCONT          in number,
                          pVALORITEMNOTA_ENT  in number,
                          pVALORITEMNOTA_SAID in number,
                          pNUMTRANSENT        in number,
                          pNUMTRANSVENDA      in number,
                          pVLIPI              in number,
                          pST                 in number,
                          pSTGUIA             in number,
                          pDTCANCEL           date,
                          pSITUACAOTRIBUTARIA in varchar2,
                          pTIPODESCARGA       in varchar2,
                          pMINUTOLANC         in varchar2,
                          pCUSTOCONTANT       in number,
                          pROTINALANC         in varchar2,
                          pDTMOVLOG           date,
                          pCUSTOFISCAL        in number,
                          pCUSTOULTENTCONT    in number) is
   begin
      insert into PCDADOS1070_TEMP (TIPO,SEQMOV,BASECUSTOCONT,CUSTOCONT,CUSTOFIN,CUSTOREAL,CUSTOREP ,
                                    CUSTOULTENT,CUSTOREALSEMST,VALORULTENT,ESPECIE,SERIE,CODCONT,OBSERVACAO,
                                    CODPROD,CODOPER,NUMNOTA,DATA,HORALANC,CODFISCAL,QTCONT,QTENTRADA,
                                    QTSAIDA,QTSAIDA_DENTRO,QTSAIDA_FORA,HISTORICO,PUNITCONT,VALORITEMNOTA_ENT,
                                    VALORITEMNOTA_SAID,NUMTRANSENT,NUMTRANSVENDA,VLIPI,ST,STGUIA,DTCANCEL,
                                    SITUACAOTRIBUTARIA,TIPODESCARGA,MINUTOLANC,CUSTOCONTANT,ROTINALANC, DTMOVLOG, CUSTOFISCAL,CUSTOULTENTCONT)
                             values(pTIPO,pSEQMOV,pBASECUSTOCONT,pCUSTOCONT,pCUSTOFIN,pCUSTOREAL,pCUSTOREP,pCUSTOULTENT
                                   ,pCUSTOREALSEMST,pVALORULTENT,pESPECIE,pSERIE,pCODCONT,pOBSERVACAO,pCODPROD,pCODOPER
                                   ,pNUMNOTA,pDATA,pHORALANC,pCODFISCAL,pQTCONT,pQTENTRADA,pQTSAIDA,pQTSAIDA_DENTRO,pQTSAIDA_FORA
                                   ,pHISTORICO,pPUNITCONT,pVALORITEMNOTA_ENT,pVALORITEMNOTA_SAID,pNUMTRANSENT,pNUMTRANSVENDA,pVLIPI
                                   ,pST,pSTGUIA,pDTCANCEL,pSITUACAOTRIBUTARIA,pTIPODESCARGA,pMINUTOLANC, pCUSTOCONTANT, pROTINALANC
                                   ,pDTMOVLOG,pCUSTOFISCAL,pCUSTOULTENTCONT);
   end;
   -----------------------------

BEGIN
    BEGIN
      SELECT COUNT(*)
        INTO vnCONTADOR
        FROM PCDADOS1070_TEMP;
      EXCEPTION
        WHEN OTHERS THEN
          vnCONTADOR := 0;
      END;

      IF vnCONTADOR > 0 THEN
         vsDELETE := 'DELETE FROM PCDADOS1070_TEMP';
         EXECUTE IMMEDIATE vsDELETE;
       END IF;
       
   V_DATA_CANCELAMENTO_FIM := TO_DATE(TO_CHAR(PDTFIM, 'DD/MM/YYYY') || ' 23:59:59', 'DD/MM/YYYY HH24:MI:SS');       
   
/*-- GerarLogP1  
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'INICIO PROCESSO', 0); 
   COMMIT;
*/-- GerarLogP2   

-- ENTRADA ----------------------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'E' TIPO,
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
                        AND PCNFENT.TIPODESCARGA NOT IN ( 'N' ,'F', 'P','H','G' )
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
                        AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
		                             (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                        AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                  WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                  WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                  ELSE 0 END = 1)  
                      )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG, 
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;


---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - E', 1); 
   COMMIT;
*/-- GerarLogP2   

--- ENTRADA CANCELADA ------------------------------------------------------------------------------
   FOR REGISTROS IN (
                     SELECT TAB.TIPO,TAB.SEQMOV,TAB.BASECUSTOCONT,TAB.CUSTOCONT,TAB.CUSTOFIN,TAB.CUSTOREAL,TAB.CUSTOREP,TAB.CUSTOULTENT,TAB.CUSTOREALSEMST,TAB.VALORULTENT,
                         TAB.ESPECIE,TAB.SERIE,TAB.CODCONT,TAB.OBSERVACAO,TAB.CODPROD,TAB.CODOPER,TAB.NUMNOTA,TAB.DTCANCEL_ORIG DATA,TAB.DTMOVLOG,TAB.HORALANC,
                         TAB.CODFISCAL,TAB.QTCONT,TAB.QTENTRADA,TAB.QTSAIDA,TAB.QTSAIDA_DENTRO,TAB.QTSAIDA_FORA,TAB.HISTORICO,TAB.PUNITCONT,TAB.VALORITEMNOTA_ENT,
                         TAB.VALORITEMNOTA_SAID,TAB.NUMTRANSENT,TAB.NUMTRANSVENDA,TAB.VLIPI,TAB.ST,TAB.STGUIA,TAB.DTCANCEL,TAB.SITUACAOTRIBUTARIA,TAB.TIPODESCARGA,
                         TAB.MINUTOLANC,TAB.CUSTOCONTANT,TAB.ROTINACAD,TAB.CUSTO_SEM_IPI_PIS_COFINS,TAB.ID_PCMOV,TAB.ID_PCMOVCOMPLE,TAB.NUMTRANSORIGEM,TAB.VLR_CRED_ICMS,
                         TAB.CUSTOULTENTCONT,TAB.NUMSEQ,TAB.VLR_ICMS_REAL,TAB.VLR_CRED_COFINS,TAB.VLR_CRED_PIS,TAB.NCM, TAB.CUSTOFISCAL   
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
                                             AND ROWNUM = 1) 
                                      END BASECUSTOCONT,
                                     --------------------------------------------------------------------------------
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
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
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
                                AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
                                         (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)  
                     ) TAB WHERE TAB.DTCANCEL_ORIG BETWEEN PDTINICIO AND PDTFIM

)
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------

/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - EC', 2); 
   COMMIT; 
*/-- GerarLogP2   

--- ENTRADA TIPO N ------------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'E' TIPO,
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
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                                AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
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
                                AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
		                                     (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)    
            )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT
                  );
  END LOOP;
COMMIT;
-------------------------------------------------------------------------------------------------

/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - E TIPO N', 3); 
   COMMIT; 
*/-- GerarLogP2   
--- ENTRADA TIPO P ------------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'EP' TIPO,
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
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                               FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
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
                                AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
		                                     (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)  
)
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------

/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - EP', 4); 
   COMMIT; 
*/-- GerarLogP2   
--- ENTRADA COMPLEMENTO DE FRETE ------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'EF' TIPO,
                                     PCMOV.SEQMOV,
                                     -----------------------------------------------------
/*                                     ROUND(PCMOV.VLFRETECONHEC - ((CASE WHEN NVL(V_FIL_CALCREDPISFRETECONT,'N')  = 'S' THEN
                                                                       (VLCREDPISFRETEFOB + VLCREDCOFINSFRETEFOB) ELSE 0 END)
                                                                       +
                                                                  (CASE WHEN NVL(V_UTICREDICMSFRETEFOBCUSTOCONT,PCMOVCOMPLE.APROVEITACREDICMSCONT) = 'S' THEN
                                                                       PCMOVCOMPLE.VLICMSFRETEFOB ELSE 0 END)
                                     ),6) AS BASECUSTOCONT,
                                     */ -- Conforme testes, deverá ser considerado o parametro da movimentação para manter o resultado registrado em cada lançamento. Gleibe/Fabio
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
                                     --'COMPLEMENTO DE CUSTO CT-e' OBSERVACAO,
                                     'Atualização de Custo por Importação' OBSERVACAO,
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
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
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
                                AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
		                                     (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)
                                          )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;

---------------------------------------------------------------------------------------------------------

/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - EF', 5); 
   COMMIT; 
*/-- GerarLogP2   
--- ENTRADA SERVIÇO AJUSTANDO O CUSTO - ESPECIE = NS ----------------------------------------------------
   FOR REGISTROS IN (SELECT 'ES' TIPO,
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
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                              FROM PCNFENT, PCMOV, PCMOVCOMPLE, PCCONSUM, PCFILIAL, PCPRODUT
                              WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                                AND PCMOVCOMPLE.NUMTRANSITEM(+) = PCMOV.NUMTRANSITEM
                                AND PCNFENT.DTENT between PDTINICIO AND PDTFIM
                                AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCODFILIAL
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
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
                                AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
		                                    (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)  
                                     )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - ES', 6); 
   COMMIT; 
*/-- GerarLogP2   

--- ENTRADA ER
   FOR REGISTROS IN (SELECT 'ER' TIPO, -- ENTRADA DE ESTORNO REF.FATURAMENTO DE CONSIGNADO. Esse lançamento faz a contra partida da segunda nota de saída do consignado.
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
                          ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                    FROM PCMOV, PCMOVCOMPLE, PCPEDC P, PCPRODUT
                    WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                      AND DTMOV between PDTINICIO AND PDTFIM
                      AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                      AND NVL(P.CODFILIALNF, P.CODFILIAL) = PCODFILIAL
                      AND PCMOV.CODPROD = PCPRODUT.CODPROD
                      AND PCMOV.QTCONT > 0
                      AND PCMOV.STATUS = 'AB'
                      AND PCMOV.CODOPER = 'ER'
                      AND PCMOV.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                      AND PDESCONS_ENT_AJUSTE_ER ='N'
                      AND NVL(PCMOV.NUMPED,0) = NVL(P.NUMPED,0)
                      AND NVL(P.NUMNOTACONSIG,0) > 0
                      AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCMOV.TIPOMERC,'XX'),'XX') <> 'BD' 
                      AND NOT ((PCMOV.CODFISCAL BETWEEN 1116 AND 1123) OR
		                           (PCMOV.CODFISCAL BETWEEN 2116 AND 2123))
                                AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                          WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                          WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                          ELSE 0 END = 1)) 
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - ER', 7); 
   COMMIT; 
*/-- GerarLogP2   

--- SAIDA ------------------------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'S' TIPO,
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
                            ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                      FROM PCNFSAID, PCMOV, PCMOVCOMPLE, PCPRODUT
                      WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                        AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                        AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM (+)
                        AND PCMOV.CODPROD = PCPRODUT.CODPROD
                        AND PCNFSAID.DTSAIDA BETWEEN PDTINICIO AND PDTFIM
                        AND PCMOV.DTMOV BETWEEN PDTINICIO AND PDTFIM
                        AND DECODE(PGERA_NF_SAIDA_CANC,'N', PCMOV.DTCANCEL, NULL ) IS NULL
                        AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCODFILIAL
                        AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                        AND PCMOV.QTCONT > 0
                        AND PCNFSAID.ESPECIE in ('NF', 'CF', 'CP','NE','TP')
                        AND PCMOV.STATUS in ('A', 'AB')
                        AND NVL(PCNFSAID.CONDVENDA, 0) not in (3, 6, DECODE(PCNFSAID.FORNECENTREGA, 'S', -1, 7), 12, DECODE(PVENDAMANIF_COMTV14, 'S', 13, 14))
                        AND PCMOV.CODFISCAL not in (5929, 6929, 5116, 5117, 5118, 5119, 5120, 5122, 5123, 6116, 6117, 6118, 6119, 6120, 6122, 6123)
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
                                  ELSE 0 END = 1))
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - S', 8); 
   COMMIT; 
*/-- GerarLogP2   
--- SAIDA CANCELADA -------------------------------------------------------------------------------------
   FOR REGISTROS IN (         SELECT 'SC' TIPO, -- Notas fiscais canceladas
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
                                    ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
                              FROM PCNFSAID, PCMOV, PCMOVCOMPLE, PCPRODUT
                              WHERE PCMOV.NUMNOTA = PCNFSAID.NUMNOTA
                                AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                                AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                                AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                --Em caso de utilização manual do parametro V_DATA_CANCELAMENTO_FIM, o mesmo precisa estar no seguinte formato: TO_DATE(TO_CHAR(PDTFIM, 'DD/MM/YYYY') || ' 23:59:59', 'DD/MM/YYYY HH24:MI:SS');
                                AND PCNFSAID.DTCANCEL BETWEEN PDTINICIO AND V_DATA_CANCELAMENTO_FIM
                                AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCODFILIAL
                                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                                AND PCMOV.QTCONT < 0
                                AND NVL(PCNFSAID.CONDVENDA, 0) not in (3, 6, DECODE(PCNFSAID.FORNECENTREGA, 'S', -1, 7), 12, DECODE(PVENDAMANIF_COMTV14, 'S', 13, 14))
                                AND PCMOV.CODFISCAL not in (5929, 6929, 5116, 5117, 5118, 5119, 5120, 5122, 5123, 6116, 6117, 6118, 6119, 6120, 6122, 6123)
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
                                          ELSE 0 END = 1)
                                     )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - SC', 9); 
   COMMIT;
*/-- GerarLogP2   

--- ENTRADA PRODUÇÃO ------------------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'AE' TIPO,
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
                            ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
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
                        AND NOT ((NVL(PCMOV.CODFISCAL,0) BETWEEN 1116 AND 1123) OR
                                 (NVL(PCMOV.CODFISCAL,0) BETWEEN 2116 AND 2123) OR
                                 (NVL(PCMOV.CODFISCAL,0) IN (5929, 6929, 5116, 5117, 5118, 5119, 5120, 5122, 5123, 6116, 6117, 6118, 6119, 6120, 6122, 6123)))
                        AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                  WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                  WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                  ELSE 0 END = 1))
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - AE', 10); 
   COMMIT; 
*/-- GerarLogP2   
--- ENTRADA PRODUÇÃO CANCELADA --------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'AC' TIPO, ---- Entrada produção cancelada
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
                            ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
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
                        AND NOT ((NVL(PCMOV.CODFISCAL,0) BETWEEN 1116 AND 1123) OR
                                 (NVL(PCMOV.CODFISCAL,0) BETWEEN 2116 AND 2123) OR
                                 (NVL(PCMOV.CODFISCAL,0) IN (5929, 6929, 5116, 5117, 5118, 5119, 5120, 5122, 5123, 6116, 6117, 6118, 6119, 6120, 6122, 6123)))
                        AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                  WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                  WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                  ELSE 0 END = 1)
                      )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - AC', 11); 
   COMMIT;
*/-- GerarLogP2   

--- SAIDA REQUISIÇÃO (SM)--------------------------------------------------------------------------------
   FOR REGISTROS IN (SELECT 'SM' TIPO,
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
                          ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
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
                      AND NVL(PCMOV.CODFISCAL,0) NOT IN (5929, 6929, 5116, 5117, 5118, 5119, 5120, 5122, 5123, 6116, 6117, 6118, 6119, 6120, 6122, 6123)
                      AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                ELSE 0 END = 1)
                    )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
  END LOOP;
COMMIT;
---------------------------------------------------------------------------------------------------------
/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - SM', 12); 
   COMMIT;
*/-- GerarLogP2   

--- SAIDA REQUISIÇÃO (SM-CANCELADO)---------------------------------------------------------
   FOR REGISTROS IN (SELECT 'SM' TIPO, -- Requisição CANCELADA
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
                          ,NVL(PCMOVCOMPLE.CUSTOFISCAL,0) AS CUSTOFISCAL
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
                      AND NVL(PCMOV.CODFISCAL,0) NOT IN (5929, 6929, 5116, 5117, 5118, 5119, 5120, 5122, 5123, 6116, 6117, 6118, 6119, 6120, 6122, 6123)
                      AND (CASE WHEN PSTATUSPROD = 'T' THEN 1
                                WHEN PSTATUSPROD = 'A' AND PCPRODUT.DTEXCLUSAO IS NULL THEN 1
                                WHEN PSTATUSPROD = 'I' AND PCPRODUT.DTEXCLUSAO IS NOT NULL THEN 1
                                ELSE 0 END = 1)  
                    )
    LOOP
    INSERIR_DADOS(REGISTROS.TIPO              ,
                  REGISTROS.SEQMOV            ,
                  REGISTROS.BASECUSTOCONT     ,
                  REGISTROS.CUSTOCONT         ,
                  REGISTROS.CUSTOFIN          ,
                  REGISTROS.CUSTOREAL         ,
                  REGISTROS.CUSTOREP          ,
                  REGISTROS.CUSTOULTENT       ,
                  REGISTROS.CUSTOREALSEMST    ,
                  REGISTROS.VALORULTENT       ,
                  REGISTROS.ESPECIE           ,
                  REGISTROS.SERIE             ,
                  REGISTROS.CODCONT           ,
                  REGISTROS.OBSERVACAO        ,
                  REGISTROS.CODPROD           ,
                  REGISTROS.CODOPER           ,
                  REGISTROS.NUMNOTA           ,
                  REGISTROS.DATA              ,
                  REGISTROS.HORALANC          ,
                  REGISTROS.CODFISCAL         ,
                  REGISTROS.QTCONT            ,
                  REGISTROS.QTENTRADA         ,
                  REGISTROS.QTSAIDA           ,
                  REGISTROS.QTSAIDA_DENTRO    ,
                  REGISTROS.QTSAIDA_FORA      ,
                  REGISTROS.HISTORICO         ,
                  REGISTROS.PUNITCONT         ,
                  REGISTROS.VALORITEMNOTA_ENT ,
                  REGISTROS.VALORITEMNOTA_SAID,
                  REGISTROS.NUMTRANSENT       ,
                  REGISTROS.NUMTRANSVENDA     ,
                  REGISTROS.VLIPI             ,
                  REGISTROS.ST                ,
                  REGISTROS.STGUIA            ,
                  REGISTROS.DTCANCEL          ,
                  REGISTROS.SITUACAOTRIBUTARIA,
                  REGISTROS.TIPODESCARGA      ,
                  REGISTROS.MINUTOLANC,
                  REGISTROS.CUSTOCONTANT,
                  REGISTROS.ROTINACAD,
                  REGISTROS.DTMOVLOG,
                  REGISTROS.CUSTOFISCAL,
                  REGISTROS.CUSTOULTENTCONT);
   END LOOP;
 COMMIT;

/*-- GerarLogP1
   INSERT INTO SQL_GERADO (DATA, CODREGRA, OBS, ID) VALUES (SYSDATE, 99, 'FIM - SM CANC', 13); 
   COMMIT; 
*/-- GerarLogP2   
END;
----------------------------------------------------------------------------
-- Alt.: 08/08/2024 - Implementado ajuste nos sqls AC na coluna CUSTOULTENT
-- Alt.: 26/07/2024 - Implementado ajuste nos sqls AE e SM para considerar NVL no campo PCMOV.CODFISCAL 
----------------------------------------------------------------------------