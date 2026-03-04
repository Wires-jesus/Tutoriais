CREATE OR REPLACE FUNCTION F_CONSULTADADOS1017(pCODFILIAL               in varchar2,
                                               pDTINICIO                in date,
                                               pDTFIM                   in date,
                                               pRELATORIO               in varchar2 default 'N')
---------------------------------------------------------------------------------
-- Função para retorno de dados da rotina 1017
---------------------------------------------------------------------------------
-- Criado por: Gleibe em 11/10/2021
---------------------------------------------------------------------------------
-- Definição do Parâmetro pRELATORIO
   -- 'R45_UE' - RELATÓRIO 45 OPÇÃO UE (ÚLTIMA ENTRADA)
   -- 'R45_CC' - RELATÓRIO 45 OPÇÃO CC (CONTA CORRENTE)
---------------------------------------------------------------------------------
  return TABELA_ROTINA_1017
  parallel_enable
  pipelined is

  OUTROW TIPO_ROTINA_1017 := TIPO_ROTINA_1017(
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, -- 20
      NULL,NULL,NULL,NULL,NULL
      ); -- 205 colunas
---------------------------------------------------------------------------------
  BEGIN
---------------------------------------------------------------------------------
 -- ENTRADA NORMAL
---------------------------------------------------------------------------------
   IF pRELATORIO = 'R45_UE' THEN
       FOR DADOS IN ( SELECT NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                             NVL(ME.NBM, PE.NBM) NCM,
                             ME.CODPROD,
                             NVL(ME.DESCRICAO, PE.DESCRICAO) DSCPRODUTO,
                             NVL(PE.CESTABASICALEGIS,'N') CESTABASICALEGIS,
                             PE.CODLINHAPROD,
                             PE.UNIDADE UNIDADECAD,
                             NVL(PPF.PERCALIQVIGINT,0) PERCALIQVIGINTCAD,
                             NVL(PPF.PERCALIQVIGEXT,0) PERCALIQVIGEXTCAD,
                             ------------------------------------------------------
                             -- Informações de Entradas
                             ------------------------------------------------------
                             E.NUMTRANSENT,
                             E.NUMNOTA NUMNOTAENT,
                             ------------------------------------------------------
                             CASE
                               WHEN ((E.UF = 'EX') AND (NVL(E.GERANFVENDA, 'N') = 'S')) THEN
                                 (SELECT CODFORNEC
                                  FROM (SELECT F.CODFORNEC,
                                               F.CGC
                                          FROM PCFORNEC F
                                         ORDER BY F.CODFORNEC) A
                                 WHERE CGC = PF.CGC
                                   AND ROWNUM = 1)
                             ELSE
                               NVL(E.CODFORNECNF, E.CODFORNEC)
                             END CODFORNECENT,
                             ------------------------------------------------------
                             E.FORNECEDOR FORNECEDORENT,
                             E.CGC CNPJENT,
                             E.IE IEENT,
                             E.CONSUMIDORFINAL CONSUMIDORFINALENT,
                             E.CHAVENFE CHAVENFEENT,
                             E.MODELO MODELOENT,
                             E.UF UFENT,
                             E.UFFILIAL UFFILIALENT,
                             E.DTENT DATAENT,
                             E.DTEMISSAO DATAEMIENT,
                             E.ESPECIE ESPECIEENT,
                             E.SERIE SERIEENT,
                             E.TIPODESCARGA TIPOCOMPRAENT,
                             NVL(E.CONTRIBUINTE,'N') CONTRIBUINTEENT,
                             E.VLTOTAL VLTOTALENT,
                             ME.SITTRIBUT SITTRIBUTENT,
                             MCE.ORIGMERCTRIB ORIGMERCTRIBENT,
                             ME.NUMSEQ NUMSEQENT,
                             MCE.NITEMXML,
                             MCE.NUMSEQENT NUMSEQENT_ENT,
                             ME.IMPORTADO IMPORTADOENT,
                             ME.CODFISCAL CODFISCALENT,
                             ME.CODOPER CODOPERENT,
                             ME.QTCONT QTCONTENT,
                             ME.PUNITCONT PUNITCONTENT,
                             ROUND(ME.QTCONT * NVL(ME.BASEBCR,0), 2) VLBASEBCRENT,
                             NVL(ME.BASEBCR,0) VLBASEBCRENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLDESCONTO,0), 2) VLDESCONTOENT,
                             NVL(ME.VLDESCONTO,0) VLDESCONTOENT_UNIT,
                             ------------------------------------------------------
                             -- CAMPO 12 - BASE ICMS ENTRADA - TOTAL --------------
                             ------------------------------------------------------
                             CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                     ROUND(ME.QTCONT * (NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                  ELSE
                                     --ROUND(ME.QTCONT * NVL(ME.BASEICMS, 0),2)
                                  CASE WHEN ( (ME.QTCONT * NVL(ME.VLICMSBCR,0)) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND (ME.QTCONT * NVL(ME.BASEICMSBCR,0)) > 0) THEN
                                            ROUND( (ME.QTCONT * NVL(ME.BASEICMSBCR, 0)),2)
                                        WHEN ( (ME.QTCONT * NVL(ME.VLICMSBCR,0)) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND (ME.QTCONT * NVL(ME.BASEICMSBCR,0)) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                            ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                        WHEN ( (ME.QTCONT * (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND (ME.QTCONT * NVL(ME.BASEICMS,0)) > 0) THEN
                                            ROUND( (ME.QTCONT * NVL(ME.BASEICMS, 0)) ,2)
                                        WHEN ( (ME.QTCONT * (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND ( ME.QTCONT * NVL(ME.BASEICMS,0)) = 0) THEN
                                            ROUND( (ME.QTCONT * NVL(ME.BASEICMSBCR, 0)),2)
                                        ELSE
                                            ROUND( (ME.QTCONT * NVL(ME.BASEICMS, 0)),2)
                                    END
                             END VLBASECALCICMSENT,
                             ------------------------------------------------------
                             -- CAMPO 12 - BASE ICMS ENTRADA UNITARIO -------------
                             ------------------------------------------------------
                             CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                        ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                    ELSE
                                    CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                            ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                        WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                            ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                        WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                            ROUND(NVL(ME.BASEICMS, 0),2)
                                        WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                            ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                        ELSE
                                            ROUND(NVL(ME.BASEICMS, 0),2)
                                    END
                             END VLBASECALCICMSENT_UNIT,
                             ------------------------------------------------------
                            -- ME.PERCICM ALIQICMSENT,
                            CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                              ME.PERCICM
                            ELSE
                               CASE WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  = 0 AND NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                        (NVL(ME.VLICMSBCR,0) / NVL(ME.BASEICMSBCR,0)) * 100
                                    WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                         NVL(PPF.PERCALIQVIGINT,0)
                               ELSE
                                  ME.PERCICM
                               END
                            END ALIQICMSENT, /*CAMPO13*/

                             ------------------------------------------------------
                             CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                     ROUND(ME.QTCONT * (NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)) * NVL(ME.PERCICM, 0) / 100, 2)
                                  ELSE
                                   CASE WHEN (SAI.CODFISCALSAI BETWEEN 5000 AND 5999) AND
                                               (CASE WHEN E.TIPODESCARGA = 'N' THEN '3'                               
                                                 ELSE                                   
                                                    CASE                                
                                                       WHEN MCE.TIPOCALCST = 'N' THEN '1'                          
                                                       WHEN MCE.TIPOCALCST = 'G' THEN '3'                          
                                                     ELSE '2'                         
                                                  END                                   
                                                 END = 2) THEN
                                    ROUND((LEAST (                                    
                                         /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END,
                                        /*FIM CAMPO 12*/
                                        /*CAMPO 09*/
                                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                                    ELSE
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                             END
                                        /*FIM CAMPO 09*/     
                                          ) *  ((NVL(ME.PERCICM, 0) / 100))) * ME.QTCONT, 2)
                                    ELSE
                                        ROUND(ME.QTCONT * (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100),2)
                                    END                                 
                             END VLICMSENT,
                             ------------------------------------------------------
                           CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                     ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)) * NVL(ME.PERCICM, 0) / 100, 2)
                                  ELSE
                                  CASE WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  = 0 AND NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                         NVL(ME.VLICMSBCR,0)
                                       WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  = 0 AND NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0) THEN
                                         NVL(ME.VLICMSBCR,0)
                                  ELSE
                                  CASE WHEN (SAI.CODFISCALSAI BETWEEN 5000 AND 5999) AND
                                               (CASE WHEN E.TIPODESCARGA = 'N' THEN '3'                               
                                                 ELSE                                   
                                                    CASE                                
                                                       WHEN MCE.TIPOCALCST = 'N' THEN '1'                          
                                                       WHEN MCE.TIPOCALCST = 'G' THEN '3'                          
                                                     ELSE '2'                         
                                                  END                                   
                                                 END = 2) THEN
                                    LEAST (                                    
                                         /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END,
                                        /*FIM CAMPO 12*/
                                        /*CAMPO 09*/
                                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                                    ELSE
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                             END
                                        /*FIM CAMPO 09*/     
                                          ) * (NVL(ME.PERCICM, 0) / 100)
                                    ELSE
                                       (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100)
                                    END                                    
                                  END
                           END VLICMSENT_UNIT, /*CAMPO15*/
                             ------------------------------------------------------
                             CASE
                               WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                                 ROUND(ME.QTCONT * NVL(ME.BASEICMSBCR, 0), 2)
                               ELSE
                                 0
                             END VLBASECALCICMSBCRENT,
                             ------------------------------------------------------
                             CASE
                               WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                                 NVL(ME.BASEICMSBCR, 0)
                               ELSE
                                 0
                             END VLBASECALCICMSBCRENT_UNIT,
                             ------------------------------------------------------
                             CASE
                               WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                                 ROUND(ME.QTCONT * NVL(ME.VLICMSBCR, 0), 2)
                               ELSE
                                 0
                             END VLICMSBCRENT,
                             ------------------------------------------------------
                             CASE
                               WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                                 NVL(ME.VLICMSBCR, 0)
                               ELSE
                                 0
                             END VLICMSBCRENT_UNIT,

                            -----------------------CAMPO 14-----------------------
                             CASE WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                        ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0) THEN
                                        /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                        ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END
                                        /*FIM CAMPO 12*/
                                WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0) > 0) AND NVL(ME.BASEICMS,0) > 0)  THEN
                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0) > 0) AND NVL(ME.BASEICMS,0) = 0)  THEN
                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                ELSE
                                 CASE WHEN (SAI.CODFISCALSAI BETWEEN 5000 AND 5999) AND
                                               (CASE WHEN E.TIPODESCARGA = 'N' THEN '3'                               
                                                 ELSE                                   
                                                    CASE                                
                                                       WHEN MCE.TIPOCALCST = 'N' THEN '1'                          
                                                       WHEN MCE.TIPOCALCST = 'G' THEN '3'                          
                                                     ELSE '2'                         
                                                  END                                   
                                                 END = 2) THEN
                                    LEAST (                                    
                                         /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END,
                                        /*FIM CAMPO 12*/
                                        /*CAMPO 09*/
                                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                                    ELSE
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                             END
                                        /*FIM CAMPO 09*/     
                                          )
                                    ELSE
                                       ROUND(DECODE(NVL(ME.BASEICST, 0),0,NVL(ME.PUNITCONT, 0),NVL(ME.BASEICST, 0)),2)
                                    END
                             END VLBASEICMSSTENT_14,
                             ------------------------------------------------------
                             NVL(ME.ALIQICMS1, 0) ALIQICMSINTENT,
                             NVL(ME.ALIQICMS2, 0) ALIQICMSEXTENT,
                             NVL(ME.PERCALIQEXTGUIA, 0) PERCALIQEXTGUIAENT,
                             NVL(ME.PERCIVA, 0) PERCMVAAJUSTADOENT,
                             ROUND(ME.QTCONT * NVL(ME.BASEICST, 0),2) VLBASEICMSSTENT,
                             -----------------------CAMPO 09-----------------------
                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                        ROUND(NVL(ME.BASEICST, 0),2)
                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                    ELSE
                                        ROUND(NVL(ME.BASEICST, 0),2)
                             END VLBASEICMSSTENT_UNIT,

                             ROUND(ME.QTCONT * NVL(ME.ST, 0),2) VLSTENT,
                             NVL(ME.ST, 0) VLSTENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLBASESTFORANF, 0),2) VLBASEICMSSTENTGUIA,
                             NVL(ME.VLBASESTFORANF, 0) VLBASEICMSSTENTGUIA_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLDESPADICIONAL, 0),2) VLSTGUIAENT,
                             ROUND(ME.QTCONT * NVL(ME.STBCR,0),2) VLSTBCRENT,
                             NVL(ME.STBCR,0) VLSTBCRENT_UNIT,
                             NVL(ME.VLDESPADICIONAL, 0) VLSTGUIAENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLBASEIPI, 0), 2) VLBASEIPIENT,
                             NVL(ME.PERCIPI, 0) PERCIPIENT,
                             ROUND(ME.QTCONT * NVL(ME.VLIPI, 0), 2) VLIPIENT,
                             NVL(ME.VLIPI, 0) VLIPIENT_UNIT,
                             ROUND((ME.QTCONT * (NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTRASDESP, 0))),2) VLENCARGOSENT, --Frete, Seguro, Impostos e outros encargos transf. ou cobr. do destin.
                             NVL(MCE.PERCMVAORIG, 0) VLAGREGADOMVA_ENT, --Margem de Valor Agregado - MVA
                             ------------------------------------------------------
                             CASE WHEN (E.TIPODESCARGA IN ('6','8','C','T')) THEN
                                     ROUND(ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTROS,0)), 2)
                                  WHEN E.TIPODESCARGA IN ('N','F','I') THEN
                                     ROUND((ME.QTCONT * ME.PUNITCONT),2)
                                  ELSE
                                     ROUND(ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLIPI,0) + NVL(ME.ST,0) + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTRASDESP,0) - NVL(ME.VLDESCONTO,0) - NVL(ME.VLSUFRAMA,0)),2)
                             END VLCONTABILENT,
                             ------------------------------------------------------
                             CASE WHEN (E.TIPODESCARGA IN ('6','8','C','T')) THEN
                                     (ME.PUNITCONT + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTROS,0))
                                  WHEN E.TIPODESCARGA IN ('N','F','I') THEN
                                     ME.PUNITCONT
                                  ELSE
                                     (ME.PUNITCONT + NVL(ME.VLIPI,0) + NVL(ME.ST,0) + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTRASDESP,0) - NVL(ME.VLDESCONTO,0) - NVL(ME.VLSUFRAMA,0))
                             END VLCONTABILENT_UNIT,
                             ------------------------------------------------------
                             ROUND(ME.QTCONT * NVL(ME.VLFRETE, 0), 2) VLFRETEENT,
                             NVL(ME.VLFRETE, 0) VLFRETEENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLOUTRASDESP, 0), 2) VLOUTRASDESPENT,
                             NVL(ME.VLOUTRASDESP, 0) VLOUTRASDESPENT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLREDPVENDASIMPLESNA, 0), 2) VLREDPVENDASIMPLESNAENT,
                             E.NUMTRANSORIGEM NUMTRANSORIGEMENT,
                             ME.UNIDADE UNIDADEMOVENT,
                             MCE.TIPOCALCST,
                             NVL(MCE.VLBASEFCPST,0) VLBASEFCPSTENT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLBASEFCPST,0), 2) VLBASEFCPSTENT,
                             NVL(MCE.ALIQICMSFECP,0) ALIQICMSFECPENT,
                             NVL(MCE.VLFECP,0) VLFECPENT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLFECP,0), 2) VLFECPENT,
                             NVL(MCE.VLFECPSTGUIA,0) VLFECPSTGUIAT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLFECPSTGUIA,0), 2) VLFECPSTGUIAENT,
                             NVL(MCE.VLACRESCIMOFUNCEP,0) VLACRESCIMOFUNCEP_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLACRESCIMOFUNCEP,0), 2) VLACRESCIMOFUNCEPENT,
                             NVL(MCE.VLFCPSTRET,0) VLFCPSTRETENT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLFCPSTRET,0), 2) VLFCPSTRETENT,
                             NVL(MCE.PERFCPSTRET,0) PERFCPSTRETENT,
                             NVL(ME.PAUTA,0) PAUTAENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.PAUTA,0), 2) PAUTAENT,
                             NVL(ME.VLPAUTA2,0) VLPAUTA2ENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLPAUTA2,0), 2) VLPAUTA2ENT,
                             NVL(ME.VLPAUTAICMS,0) VLPAUTAICMSENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLPAUTAICMS,0), 2) VLPAUTAICMSENT,
                             NVL(ME.VLPAUTAICMSANTEC,0) VLPAUTAICMSANTECENT_UNIT,
                             ROUND(ME.QTCONT * NVL(ME.VLPAUTAICMSANTEC,0), 2) VLPAUTAICMSANTECENT,
                             NVL(MCE.VLPAUTABCR,0) VLPAUTABCRENT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.VLPAUTABCR,0), 2) VLPAUTABCRENT,
                             NVL(MCE.USAPMCBASEST,'N') USAPMCBASESTENT,
                             NVL(MCE.PRECOMAXCONSUM,0) PRECOMAXCONSUMENT_UNIT,
                             ROUND(ME.QTCONT * NVL(MCE.PRECOMAXCONSUM,0), 2) PRECOMAXCONSUMENT,
                             MCE.UNIDADECOMERCIAL UNIDADECOMERCIALENT,
                             MCE.CODFABRICA CODFABRICAENT,
                             ME.QTUNITCX QTUNITCXENT,
                             ------------------------------------------------------
                             -- Informações de Saídas
                             ------------------------------------------------------
                             SAI.CHAVENFEULTENT,
                             SAI.NUMTRANSENTULTENT,
                             SAI.NUMNFULTENT,
                             SAI.CODFORNECULTENT,
                             SAI.SERIEULTENT,
                             SAI.NUMSEQENTULTENT,
                             SAI.CODFILIALULTENT,
                             SAI.CODFILIALSAI,
                             SAI.NUMTRANSVENDA,
                             SAI.NUMNOTASAI,
                             SAI.CODCLISAI,
                             SAI.CLIENTESAI,
                             SAI.CNPJSAI,
                             SAI.IESAI,
                             SAI.CONSUMIDORFINALSAI,
                             SAI.CHAVENFESAI,
                             SAI.MODELOSAI,
                             SAI.SIMPLESNACIONALSAI,
                             SAI.UFSAI,
                             SAI.UFFILIALSAI,
                             SAI.DATASAI,
                             SAI.DATAEMISAI,
                             SAI.ESPECIESAI,
                             SAI.SERIESAI,
                             SAI.TIPOVENDASAI,
                             SAI.VLTOTALSAI,
                             SAI.SITTRIBUTSAI,
                             SAI.ORIGMERCTRIBSAI,
                             SAI.NUMSEQSAI,
                             SAI.NUMSEQENTSAI,
                             SAI.IMPORTADOSAI,
                             SAI.CONTRIBUINTESAI,
                             SAI.ORGAOPUBSAI,
                             SAI.ORGAOPUBFEDERALSAI,
                             SAI.ORGAOPUBMUNICIPALSAI,
                             SAI.CODFISCALSAI,
                             SAI.CODOPERSAI,
                             SAI.QTCONTSAI,
                             SAI.VLBASEBCRSAI,
                             SAI.VLBASEBCRSAI_UNIT,
                             SAI.VLSTBCRSAI,
                             SAI.VLSTBCRSAI_UNIT,
                             SAI.VLDESCONTOSAI,
                             SAI.VLDESCONTOSAI_UNIT,
                             SAI.PUNITCONTSAI,
                             SAI.VLBASECALCICMSSAI,
                             SAI.VLBASECALCICMSSAI_UNIT,
                             SAI.ALIQICMSSAI,
                             SAI.VLICMSSAI,
                             SAI.VLICMSSAI_UNIT,
                             SAI.VLBASEICMSSTSAI,
                             SAI.VLBASEICMSSTSAI_UNIT,
                             SAI.ALIQICMSINTSAI,
                             SAI.ALIQICMSEXTSAI,
                             SAI.VLSTSAI,
                             SAI.VLSTSAI_UNIT,
                             SAI.VLSTGUIASAI,
                             SAI.VLSTGUIASAI_UNIT,
                             SAI.CODIPISAI,
                             SAI.VLBASEIPISAI,
                             SAI.PERCIPISAI,
                             SAI.VLIPISAI,
                             SAI.VLIPISAI_UNIT,
                             SAI.VLENCARGOSSAI,
                             SAI.VLCONTABILSAI,
                             SAI.VLFRETESAI,
                             SAI.VLFRETESAI_UNIT,
                             SAI.VLOUTRASDESPSAI,
                             SAI.VLOUTRASDESPSAI_UNIT,
                             SAI.VLCONTABILSAI_UNIT,
                             SAI.VLREDPVENDASIMPLESNASAI,
                             SAI.NUMTRANSENTORIGEMSAI,
                             SAI.UNIDADEMOVSAI,
                             SAI.NUMSERIEEQUIP NUMSERIEEQUIPSAI,
                             SAI.NUMSERIESAT NUMSERIESATSAI,
                             SAI.USAPMCBASESTSAI,
                             SAI.PAUTASAI_UNIT,
                             SAI.VLPAUTA2SAI_UNIT,
                             SAI.VLPAUTAICMSANTECSAI_UNIT,
                             SAI.VLPAUTABCRSAI_UNIT,
                             SAI.PRECOMAXCONSUMSAI_UNIT,
                             SAI.PAUTASAI,
                             SAI.VLPAUTA2SAI,
                             SAI.VLPAUTAICMSANTECSAI,
                             SAI.VLPAUTABCRSAI,
                             SAI.PRECOMAXCONSUMSAI,
                             SAI.PERFCPSTRETSAI,
                             SAI.VLFCPSTRETSAI,
                             SAI.VLFCPSTRETSAI_UNIT,
                             SAI.UNIDADECOMERCIALSAI,
                             SAI.CODFABRICASAI,
                             SAI.QTUNITCXSAI
                      FROM PCNFENT E,
                           PCFILIAL PF,
                           PCMOV ME,
                           PCMOVCOMPLE MCE,
                           PCPRODUT PE,
                           PCPRODFILIAL PPF,
                           (SELECT /*+ INDEX(S PCNFSAID_IDX49)*/
                                   S.NUMTRANSVENDA,
                                   NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIALSAI,
                                   S.NUMNOTA NUMNOTASAI,
                                   MVS.NUMTRANSENT NUMTRANSENTSAI,
                                   NVL(S.CODCLINF, S.CODCLI) CODCLISAI,
                                   S.CLIENTE CLIENTESAI,
                                   S.CGC CNPJSAI,
                                   S.IE IESAI,
                                   S.CONSUMIDORFINAL CONSUMIDORFINALSAI,
                                   S.CHAVENFE CHAVENFESAI,
                                   DECODE(S.CHAVENFE, NULL, NULL, SUBSTR(S.CHAVENFE, 21, 2)) MODELOSAI,
                                   NVL(S.SIMPLESNACIONAL,'N') SIMPLESNACIONALSAI,
                                   S.UF UFSAI,
                                   S.UFFILIAL UFFILIALSAI,
                                   S.DTSAIDA DATASAI,
                                   S.DTENTREGA DATAEMISAI,
                                   S.ESPECIE ESPECIESAI,
                                   S.SERIE SERIESAI,
                                   S.TIPOVENDA TIPOVENDASAI,
                                   S.VLTOTAL VLTOTALSAI,
                                   MS.SITTRIBUT SITTRIBUTSAI,
                                   MCS.ORIGMERCTRIB ORIGMERCTRIBSAI,
                                   NVL(MCS.NITEMXML,MS.NUMSEQ) NUMSEQSAI,
                                   MCS.NUMSEQENT NUMSEQENTSAI,
                                   MS.IMPORTADO IMPORTADOSAI,
                                   NVL(S.CONTRIBUINTE,'N') CONTRIBUINTESAI,
                                   NVL(S.ORGAOPUB,'N') ORGAOPUBSAI,
                                   NVL(S.ORGAOPUBFEDERAL,'N') ORGAOPUBFEDERALSAI,
                                   NVL(S.ORGAOPUBMUNICIPAL,'N') ORGAOPUBMUNICIPALSAI,
                                   MS.CODFISCAL CODFISCALSAI,
                                   MS.CODPROD CODPRODSAI,
                                   MS.CODOPER CODOPERSAI,
                                   SUM(MS.QTCONT) QTCONTSAI,
                                   MAX(MS.PUNITCONT) PUNITCONTSAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.BASEBCR,0), 2)) VLBASEBCRSAI,
                                   NVL(MS.BASEBCR,0) VLBASEBCRSAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLDESCONTO,0), 2)) VLDESCONTOSAI,
                                   NVL(MS.VLDESCONTO,0) VLDESCONTOSAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * MS.BASEICMS, 2)) VLBASECALCICMSSAI,
                                   MAX(MS.BASEICMS) VLBASECALCICMSSAI_UNIT,
                                   NVL(MS.PERCICM, 0) ALIQICMSSAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.BASEICMS, 0) * NVL(MS.PERCICM, 0) / 100, 2)) VLICMSSAI,
                                   MAX(NVL(MS.BASEICMS, 0) * NVL(MS.PERCICM, 0) / 100) VLICMSSAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.BASEICST, 0), 2)) VLBASEICMSSTSAI,
                                   MAX(NVL(MS.BASEICST, 0)) VLBASEICMSSTSAI_UNIT,
                                   NVL(MS.ALIQICMS1,0) ALIQICMSINTSAI,
                                   NVL(MS.ALIQICMS2,0) ALIQICMSEXTSAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.ST, 0), 2)) VLSTSAI,
                                   MAX(NVL(MS.ST, 0)) VLSTSAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLDESPADICIONAL, 0), 2)) VLSTGUIASAI,
                                   MAX(NVL(MS.VLDESPADICIONAL, 0)) VLSTGUIASAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.STBCR,0), 2)) VLSTBCRSAI,
                                   NVL(MS.STBCR,0) VLSTBCRSAI_UNIT,
                                   MCS.CODSITTRIBIPI CODIPISAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLBASEIPI, 0), 2)) VLBASEIPISAI,
                                   NVL(MS.PERCIPI, 0) PERCIPISAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLIPI, 0), 2)) VLIPISAI,
                                   MAX(NVL(MS.VLIPI, 0)) VLIPISAI_UNIT,
                                   SUM( ROUND((MS.QTCONT * (NVL(MS.VLFRETE, 0) + NVL(MS.VLOUTRASDESP, 0))),2)) VLENCARGOSSAI, --Frete, Seguro, Impostos e outros encargos transf. ou cobr. do destin.
                                   MAX(NVL(MCS.PERCMVAORIG, 0)) VLAGREGADOMVASAI, --Margem de Valor Agregado - MVA
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLFRETE, 0), 2)) VLFRETESAI,
                                   MAX(NVL(MS.VLFRETE, 0)) VLFRETESAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLOUTRASDESP, 0), 2)) VLOUTRASDESPSAI,
                                   MAX(NVL(MS.VLOUTRASDESP, 0)) VLOUTRASDESPSAI_UNIT,
                                   ------------------------------------------------
                                   SUM(CASE WHEN (NVL(MS.CODOPER,'X') <> 'SD') THEN
                                             ROUND(MS.QTCONT * (MS.PUNITCONT + NVL(MS.VLFRETE,0) + NVL(MS.VLOUTROS,0)), 2)
                                          ELSE
                                             ROUND(MS.QTCONT * (MS.PUNITCONT + NVL(MS.VLOUTRASDESP,0)), 2)
                                       END) VLCONTABILSAI,
                                   ------------------------------------------------
                                   MAX(CASE WHEN (NVL(MS.CODOPER,'X') <> 'SD') THEN
                                             (MS.PUNITCONT + NVL(MS.VLFRETE,0) + NVL(MS.VLOUTROS,0))
                                          ELSE
                                             (MS.PUNITCONT + NVL(MS.VLOUTRASDESP,0))
                                       END) VLCONTABILSAI_UNIT,
                                   ------------------------------------------------
                                   SUM(ROUND(MS.QTCONT * NVL(MCS.VLREDPVENDASIMPLESNA, 0),2)) VLREDPVENDASIMPLESNASAI,
                                   S.NUMTRANSENTORIGEM NUMTRANSENTORIGEMSAI,
                                   MS.UNIDADE UNIDADEMOVSAI,
                                   MAX(MVS.CHAVENFEULTENT) CHAVENFEULTENT,
                                   MAX(MVS.NUMTRANSENTULTENT) NUMTRANSENTULTENT,
                                   MAX(MVS.NUMNFULTENT) NUMNFULTENT,
                                   MAX(MVS.CODFORNECULTENT) CODFORNECULTENT,
                                   MAX(MVS.SERIEULTENT) SERIEULTENT,
                                   MAX(MVS.NUMSEQENTULTENT) NUMSEQENTULTENT,
                                   MAX(MVS.CODFILIALULTENT) CODFILIALULTENT,
                                   S.NUMSERIEEQUIP,
                                   S.NUMSERIESAT,
                                   NVL(MCS.USAPMCBASEST,'N') USAPMCBASESTSAI,
                                   MAX(NVL(MS.PAUTA,0)) PAUTASAI_UNIT,
                                   MAX(NVL(MS.VLPAUTA2,0)) VLPAUTA2SAI_UNIT,
                                   MAX(NVL(MS.VLPAUTAICMSANTEC,0)) VLPAUTAICMSANTECSAI_UNIT,
                                   MAX(NVL(MCS.VLPAUTABCR,0)) VLPAUTABCRSAI_UNIT,
                                   MAX(NVL(MCS.PRECOMAXCONSUM,0)) PRECOMAXCONSUMSAI_UNIT,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.PAUTA, 0), 2)) PAUTASAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLPAUTA2,0), 2)) VLPAUTA2SAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MS.VLPAUTAICMSANTEC,0), 2)) VLPAUTAICMSANTECSAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MCS.VLPAUTABCR,0), 2)) VLPAUTABCRSAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MCS.PRECOMAXCONSUM,0), 2)) PRECOMAXCONSUMSAI,
                                   NVL(MCS.PERFCPSTRET,0) PERFCPSTRETSAI,
                                   SUM(ROUND(MS.QTCONT * NVL(MCS.VLFCPSTRET,0), 2)) VLFCPSTRETSAI,
                                   MAX(NVL(MCS.VLFCPSTRET,0)) VLFCPSTRETSAI_UNIT,
                                   MAX(MCS.UNIDADECOMERCIAL) UNIDADECOMERCIALSAI,
                                   MAX(MCS.CODFABRICA) CODFABRICASAI,
                                   MAX(MS.QTUNITCX) QTUNITCXSAI,
                                   MAX(MVS.NUMSEQ) NUMSEQ
                            FROM PCNFSAID S,
                                 PCMOV MS,
                                 PCMOVCOMPLE MCS,
                                 PCUEPSSAIDUE MVS
                            WHERE NVL(S.CODFILIALNF, S.CODFILIAL) = NVL(MS.CODFILIALNF,MS.CODFILIAL)
                              AND S.NUMTRANSVENDA  = MS.NUMTRANSVENDA
                              AND S.NUMNOTA        = MS.NUMNOTA
                              AND MS.NUMTRANSITEM  = MCS.NUMTRANSITEM
                              AND MVS.CODFILIAL    = NVL(S.CODFILIALNF,S.CODFILIAL)
                              AND MVS.NUMTRANSVENDA = S.NUMTRANSVENDA
                              AND MVS.CODPROD = MS.CODPROD
                              AND S.ESPECIE IN ('NF','CP')
                              AND MS.STATUS IN ('A','AB')
                              AND MS.DTCANCEL IS NULL
                              -- Filtrando Pelas Datas
                              AND S.DTSAIDA BETWEEN pDTINICIO AND pDTFIM
                              AND MVS.DTSAIDA BETWEEN pDTINICIO AND pDTFIM
                              AND MS.DTMOV BETWEEN pDTINICIO AND pDTFIM
                              -- Filtrando pelas Filiais 
                              AND NVL(S.CODFILIALNF, S.CODFILIAL) = pCODFILIAL
                              AND NVL(MS.CODFILIALNF, MS.CODFILIAL) = pCODFILIAL
                              AND MVS.CODFILIAL = pCODFILIAL
                              -- Predicado
                             AND S.DTSAIDA   >= (SELECT MIN(dtsaida) FROM pcnfsaid)
                             AND MVS.DTSAIDA >= (SELECT MIN(dtsaida) FROM pcnfsaid)
                             AND MS.DTMOV    >= (SELECT MIN(dtsaida) FROM pcnfsaid)                                                           
                             GROUP BY S.NUMTRANSVENDA, S.NUMNOTA, MVS.NUMTRANSENT, S.CGC, S.IE, S.CONSUMIDORFINAL, S.CHAVENFE, S.NUMSERIEEQUIP,
                                      NVL(S.SIMPLESNACIONAL,'N'), S.DTSAIDA, S.DTENTREGA, NVL(S.CODCLINF, S.CODCLI), S.NUMTRANSENTORIGEM,
                                      S.CLIENTE, S.UF, S.UFFILIAL, S.ESPECIE, S.SERIE, S.TIPOVENDA, NVL(S.CONTRIBUINTE,'N'), S.NUMSERIESAT,
                                      NVL(S.ORGAOPUB,'N'), NVL(S.ORGAOPUBFEDERAL,'N'), NVL(S.ORGAOPUBMUNICIPAL,'N'), NVL(MCS.USAPMCBASEST,'N'),
                                      S.VLTOTAL, MS.CODPROD, MS.UNIDADE, MS.SITTRIBUT, MCS.ORIGMERCTRIB, NVL(MCS.NITEMXML,MS.NUMSEQ), MCS.NUMSEQENT, MS.IMPORTADO,
                                      MS.CODFISCAL, MS.CODOPER, MS.PERCICM, MS.ALIQICMS1, MS.ALIQICMS2, NVL(MCS.PERFCPSTRET,0),
                                      NVL(MS.BASEBCR,0), NVL(MS.STBCR,0), NVL(MS.VLDESCONTO,0), MCS.CODSITTRIBIPI,
                                      MS.PERCIPI,NVL(S.CODFILIALNF,S.CODFILIAL)
                           ) SAI
                      WHERE E.NUMTRANSENT = ME.NUMTRANSENT
                        AND E.NUMNOTA     = ME.NUMNOTA
                        AND PF.CODIGO     = NVL(E.CODFILIALNF, E.CODFILIAL)
                        AND ME.NUMTRANSITEM = MCE.NUMTRANSITEM
                        AND ME.CODPROD      = PE.CODPROD
                        AND ME.CODPROD(+)   = SAI.CODPRODSAI
                        AND ME.NUMTRANSENT(+) = SAI.NUMTRANSENTSAI
                        AND  DECODE(NVL(SAI.NUMSEQ, -1), -1, NVL(MCE.NUMSEQENT, 1), NVL(ME.NUMSEQ, 1)) =
                             DECODE(NVL(SAI.NUMSEQ, -1), -1, NVL(SAI.NUMSEQENTULTENT, 1), NVL(SAI.NUMSEQ, 1))
                        AND ME.CODPROD = PPF.CODPROD
                        AND NVL(ME.CODFILIALNF,ME.CODFILIAL) = PPF.CODFILIAL
                        AND E.ESPECIE = 'NF'
                        AND ME.DTCANCEL IS NULL
                        AND ME.STATUS IN ('A','AB')
                        AND NVL(E.CODFILIALNF, E.CODFILIAL) = pCODFILIAL
                        AND NVL(ME.CODFILIALNF, ME.CODFILIAL) = pCODFILIAL
         )
         LOOP
            OUTROW.CODFILIAL                      := DADOS.CODFILIAL                       ;
            OUTROW.NCM                            := DADOS.NCM                             ;
            OUTROW.CODPROD                        := DADOS.CODPROD                         ;
            OUTROW.DSCPRODUTO                     := DADOS.DSCPRODUTO                      ;
            OUTROW.CESTABASICALEGIS               := DADOS.CESTABASICALEGIS                ;
            OUTROW.CODLINHAPROD                   := DADOS.CODLINHAPROD                    ;
            OUTROW.UNIDADECAD                     := DADOS.UNIDADECAD                      ;
            OUTROW.PERCALIQVIGINTCAD              := DADOS.PERCALIQVIGINTCAD               ;
            OUTROW.PERCALIQVIGEXTCAD              := DADOS.PERCALIQVIGEXTCAD               ;
            OUTROW.NUMTRANSENT                    := DADOS.NUMTRANSENT                     ;
            OUTROW.NUMNOTAENT                     := DADOS.NUMNOTAENT                      ;
            OUTROW.CODFORNECENT                   := DADOS.CODFORNECENT                    ;
            OUTROW.FORNECEDORENT                  := DADOS.FORNECEDORENT                   ;
            OUTROW.CNPJENT                        := DADOS.CNPJENT                         ;
            OUTROW.IEENT                          := DADOS.IEENT                           ;
            OUTROW.CONSUMIDORFINALENT             := DADOS.CONSUMIDORFINALENT              ;
            OUTROW.CHAVENFEENT                    := DADOS.CHAVENFEENT                     ;
            OUTROW.MODELOENT                      := DADOS.MODELOENT                       ;
            OUTROW.UFENT                          := DADOS.UFENT                           ;
            OUTROW.UFFILIALENT                    := DADOS.UFFILIALENT                     ;
            OUTROW.DATAENT                        := DADOS.DATAENT                         ;
            OUTROW.DATAEMIENT                     := DADOS.DATAEMIENT                      ;
            OUTROW.ESPECIEENT                     := DADOS.ESPECIEENT                      ;
            OUTROW.SERIEENT                       := DADOS.SERIEENT                        ;
            OUTROW.TIPOCOMPRAENT                  := DADOS.TIPOCOMPRAENT                   ;
            OUTROW.CONTRIBUINTEENT                := DADOS.CONTRIBUINTEENT                 ;
            OUTROW.VLTOTALENT                     := DADOS.VLTOTALENT                      ;
            OUTROW.SITTRIBUTENT                   := DADOS.SITTRIBUTENT                    ;
            OUTROW.ORIGMERCTRIBENT                := DADOS.ORIGMERCTRIBENT                 ;
            OUTROW.NUMSEQENT                      := DADOS.NUMSEQENT                       ;
            OUTROW.NITEMXML                       := DADOS.NITEMXML                        ;
            OUTROW.NUMSEQENT_ENT                  := DADOS.NUMSEQENT_ENT                   ;
            OUTROW.IMPORTADOENT                   := DADOS.IMPORTADOENT                    ;
            OUTROW.CODFISCALENT                   := DADOS.CODFISCALENT                    ;
            OUTROW.CODOPERENT                     := DADOS.CODOPERENT                      ;
            OUTROW.QTCONTENT                      := DADOS.QTCONTENT                       ;
            OUTROW.PUNITCONTENT                   := DADOS.PUNITCONTENT                    ;
            OUTROW.VLBASEBCRENT                   := DADOS.VLBASEBCRENT                    ;
            OUTROW.VLBASEBCRENT_UNIT              := DADOS.VLBASEBCRENT_UNIT               ;
            OUTROW.VLDESCONTOENT                  := DADOS.VLDESCONTOENT                   ;
            OUTROW.VLDESCONTOENT_UNIT             := DADOS.VLDESCONTOENT_UNIT              ;
            OUTROW.VLBASECALCICMSENT              := DADOS.VLBASECALCICMSENT               ;
            OUTROW.VLBASECALCICMSENT_UNIT         := DADOS.VLBASECALCICMSENT_UNIT          ;
            OUTROW.ALIQICMSENT                    := DADOS.ALIQICMSENT                     ;
            OUTROW.VLICMSENT                      := DADOS.VLICMSENT                       ;
            OUTROW.VLICMSENT_UNIT                 := DADOS.VLICMSENT_UNIT                  ;
            OUTROW.VLBASECALCICMSBCRENT           := DADOS.VLBASECALCICMSBCRENT            ;
            OUTROW.VLBASECALCICMSBCRENT_UNIT      := DADOS.VLBASECALCICMSBCRENT_UNIT       ;
            OUTROW.VLICMSBCRENT                   := DADOS.VLICMSBCRENT                    ;
            OUTROW.VLICMSBCRENT_UNIT              := DADOS.VLICMSBCRENT_UNIT               ;
            OUTROW.VLBASEICMSSTENT_14             := DADOS.VLBASEICMSSTENT_14              ;
            OUTROW.ALIQICMSINTENT                 := DADOS.ALIQICMSINTENT                  ;
            OUTROW.ALIQICMSEXTENT                 := DADOS.ALIQICMSEXTENT                  ;
            OUTROW.PERCALIQEXTGUIAENT             := DADOS.PERCALIQEXTGUIAENT              ;
            OUTROW.PERCMVAAJUSTADOENT             := DADOS.PERCMVAAJUSTADOENT              ;
            OUTROW.VLBASEICMSSTENT                := DADOS.VLBASEICMSSTENT                 ;
            OUTROW.VLBASEICMSSTENT_UNIT           := DADOS.VLBASEICMSSTENT_UNIT            ;
            OUTROW.VLSTENT                        := DADOS.VLSTENT                         ;
            OUTROW.VLSTENT_UNIT                   := DADOS.VLSTENT_UNIT                    ;
            OUTROW.VLBASEICMSSTENTGUIA            := DADOS.VLBASEICMSSTENTGUIA             ;
            OUTROW.VLBASEICMSSTENTGUIA_UNIT       := DADOS.VLBASEICMSSTENTGUIA_UNIT        ;
            OUTROW.VLSTGUIAENT                    := DADOS.VLSTGUIAENT                     ;
            OUTROW.VLSTBCRENT                     := DADOS.VLSTBCRENT                      ;
            OUTROW.VLSTBCRENT_UNIT                := DADOS.VLSTBCRENT_UNIT                 ;
            OUTROW.VLSTGUIAENT_UNIT               := DADOS.VLSTGUIAENT_UNIT                ;
            OUTROW.VLBASEIPIENT                   := DADOS.VLBASEIPIENT                    ;
            OUTROW.PERCIPIENT                     := DADOS.PERCIPIENT                      ;
            OUTROW.VLIPIENT                       := DADOS.VLIPIENT                        ;
            OUTROW.VLIPIENT_UNIT                  := DADOS.VLIPIENT_UNIT                   ;
            OUTROW.VLENCARGOSENT                  := DADOS.VLENCARGOSENT                   ;
            OUTROW.VLAGREGADOMVA_ENT              := DADOS.VLAGREGADOMVA_ENT               ;
            OUTROW.VLCONTABILENT                  := DADOS.VLCONTABILENT                   ;
            OUTROW.VLCONTABILENT_UNIT             := DADOS.VLCONTABILENT_UNIT              ;
            OUTROW.VLFRETEENT                     := DADOS.VLFRETEENT                      ;
            OUTROW.VLFRETEENT_UNIT                := DADOS.VLFRETEENT_UNIT                 ;
            OUTROW.VLOUTRASDESPENT                := DADOS.VLOUTRASDESPENT                 ;
            OUTROW.VLOUTRASDESPENT_UNIT           := DADOS.VLOUTRASDESPENT_UNIT            ;
            OUTROW.VLREDPVENDASIMPLESNAENT        := DADOS.VLREDPVENDASIMPLESNAENT         ;
            OUTROW.NUMTRANSORIGEMENT              := DADOS.NUMTRANSORIGEMENT               ;
            OUTROW.UNIDADEMOVENT                  := DADOS.UNIDADEMOVENT                   ;
            OUTROW.TIPOCALCST                     := DADOS.TIPOCALCST                      ;
            OUTROW.VLBASEFCPSTENT_UNIT            := DADOS.VLBASEFCPSTENT_UNIT             ;
            OUTROW.VLBASEFCPSTENT                 := DADOS.VLBASEFCPSTENT                  ;
            OUTROW.ALIQICMSFECPENT                := DADOS.ALIQICMSFECPENT                 ;
            OUTROW.VLFECPENT_UNIT                 := DADOS.VLFECPENT_UNIT                  ;
            OUTROW.VLFECPENT                      := DADOS.VLFECPENT                       ;
            OUTROW.VLFECPSTGUIAT_UNIT             := DADOS.VLFECPSTGUIAT_UNIT              ;
            OUTROW.VLFECPSTGUIAENT                := DADOS.VLFECPSTGUIAENT                 ;
            OUTROW.VLACRESCIMOFUNCEP_UNIT         := DADOS.VLACRESCIMOFUNCEP_UNIT          ;
            OUTROW.VLACRESCIMOFUNCEPENT           := DADOS.VLACRESCIMOFUNCEPENT            ;
            OUTROW.VLFCPSTRETENT_UNIT             := DADOS.VLFCPSTRETENT_UNIT              ;
            OUTROW.VLFCPSTRETENT                  := DADOS.VLFCPSTRETENT                   ;
            OUTROW.PERFCPSTRETENT                 := DADOS.PERFCPSTRETENT                  ;
            OUTROW.PAUTAENT_UNIT                  := DADOS.PAUTAENT_UNIT                   ;
            OUTROW.PAUTAENT                       := DADOS.PAUTAENT                        ;
            OUTROW.VLPAUTA2ENT_UNIT               := DADOS.VLPAUTA2ENT_UNIT                ;
            OUTROW.VLPAUTA2ENT                    := DADOS.VLPAUTA2ENT                     ;
            OUTROW.VLPAUTAICMSENT_UNIT            := DADOS.VLPAUTAICMSENT_UNIT             ;
            OUTROW.VLPAUTAICMSENT                 := DADOS.VLPAUTAICMSENT                  ;
            OUTROW.VLPAUTAICMSANTECENT_UNIT       := DADOS.VLPAUTAICMSANTECENT_UNIT        ;
            OUTROW.VLPAUTAICMSANTECENT            := DADOS.VLPAUTAICMSANTECENT             ;
            OUTROW.VLPAUTABCRENT_UNIT             := DADOS.VLPAUTABCRENT_UNIT              ;
            OUTROW.VLPAUTABCRENT                  := DADOS.VLPAUTABCRENT                   ;
            OUTROW.USAPMCBASESTENT                := DADOS.USAPMCBASESTENT                 ;
            OUTROW.PRECOMAXCONSUMENT_UNIT         := DADOS.PRECOMAXCONSUMENT_UNIT          ;
            OUTROW.PRECOMAXCONSUMENT              := DADOS.PRECOMAXCONSUMENT               ;
            OUTROW.UNIDADECOMERCIALENT            := DADOS.UNIDADECOMERCIALENT             ;
            OUTROW.CODFABRICAENT                  := DADOS.CODFABRICAENT                   ;
            OUTROW.QTUNITCXENT                    := DADOS.QTUNITCXENT                     ;
            OUTROW.CHAVENFEULTENT                 := DADOS.CHAVENFEULTENT                  ;
            OUTROW.NUMTRANSENTULTENT              := DADOS.NUMTRANSENTULTENT               ;
            OUTROW.NUMNFULTENT                    := DADOS.NUMNFULTENT                     ;
            OUTROW.CODFORNECULTENT                := DADOS.CODFORNECULTENT                 ;
            OUTROW.SERIEULTENT                    := DADOS.SERIEULTENT                     ;
            OUTROW.NUMSEQENTULTENT                := DADOS.NUMSEQENTULTENT                 ;
            OUTROW.CODFILIALULTENT                := DADOS.CODFILIALULTENT                 ;
            OUTROW.CODFILIALSAI                   := DADOS.CODFILIALSAI                    ;
            OUTROW.NUMTRANSVENDA                  := DADOS.NUMTRANSVENDA                   ;
            OUTROW.NUMNOTASAI                     := DADOS.NUMNOTASAI                      ;
            OUTROW.CODCLISAI                      := DADOS.CODCLISAI                       ;
            OUTROW.CLIENTESAI                     := DADOS.CLIENTESAI                      ;
            OUTROW.CNPJSAI                        := DADOS.CNPJSAI                         ;
            OUTROW.IESAI                          := DADOS.IESAI                           ;
            OUTROW.CONSUMIDORFINALSAI             := DADOS.CONSUMIDORFINALSAI              ;
            OUTROW.CHAVENFESAI                    := DADOS.CHAVENFESAI                     ;
            OUTROW.MODELOSAI                      := DADOS.MODELOSAI                       ;
            OUTROW.SIMPLESNACIONALSAI             := DADOS.SIMPLESNACIONALSAI              ;
            OUTROW.UFSAI                          := DADOS.UFSAI                           ;
            OUTROW.UFFILIALSAI                    := DADOS.UFFILIALSAI                     ;
            OUTROW.DATASAI                        := DADOS.DATASAI                         ;
            OUTROW.DATAEMISAI                     := DADOS.DATAEMISAI                      ;
            OUTROW.ESPECIESAI                     := DADOS.ESPECIESAI                      ;
            OUTROW.SERIESAI                       := DADOS.SERIESAI                        ;
            OUTROW.TIPOVENDASAI                   := DADOS.TIPOVENDASAI                    ;
            OUTROW.VLTOTALSAI                     := DADOS.VLTOTALSAI                      ;
            OUTROW.SITTRIBUTSAI                   := DADOS.SITTRIBUTSAI                    ;
            OUTROW.ORIGMERCTRIBSAI                := DADOS.ORIGMERCTRIBSAI                 ;
            OUTROW.NUMSEQSAI                      := DADOS.NUMSEQSAI                       ;
            OUTROW.NUMSEQENTSAI                   := DADOS.NUMSEQENTSAI                    ;
            OUTROW.IMPORTADOSAI                   := DADOS.IMPORTADOSAI                    ;
            OUTROW.CONTRIBUINTESAI                := DADOS.CONTRIBUINTESAI                 ;
            OUTROW.ORGAOPUBSAI                    := DADOS.ORGAOPUBSAI                     ;
            OUTROW.ORGAOPUBFEDERALSAI             := DADOS.ORGAOPUBFEDERALSAI              ;
            OUTROW.ORGAOPUBMUNICIPALSAI           := DADOS.ORGAOPUBMUNICIPALSAI            ;
            OUTROW.CODFISCALSAI                   := DADOS.CODFISCALSAI                    ;
            OUTROW.CODOPERSAI                     := DADOS.CODOPERSAI                      ;
            OUTROW.QTCONTSAI                      := DADOS.QTCONTSAI                       ;
            OUTROW.VLBASEBCRSAI                   := DADOS.VLBASEBCRSAI                    ;
            OUTROW.VLBASEBCRSAI_UNIT              := DADOS.VLBASEBCRSAI_UNIT               ;
            OUTROW.VLSTBCRSAI                     := DADOS.VLSTBCRSAI                      ;
            OUTROW.VLSTBCRSAI_UNIT                := DADOS.VLSTBCRSAI_UNIT                 ;
            OUTROW.VLDESCONTOSAI                  := DADOS.VLDESCONTOSAI                   ;
            OUTROW.VLDESCONTOSAI_UNIT             := DADOS.VLDESCONTOSAI_UNIT              ;
            OUTROW.PUNITCONTSAI                   := DADOS.PUNITCONTSAI                    ;
            OUTROW.VLBASECALCICMSSAI              := DADOS.VLBASECALCICMSSAI               ;
            OUTROW.VLBASECALCICMSSAI_UNIT         := DADOS.VLBASECALCICMSSAI_UNIT          ;
            OUTROW.ALIQICMSSAI                    := DADOS.ALIQICMSSAI                     ;
            OUTROW.VLICMSSAI                      := DADOS.VLICMSSAI                       ;
            OUTROW.VLICMSSAI_UNIT                 := DADOS.VLICMSSAI_UNIT                  ;
            OUTROW.VLBASEICMSSTSAI                := DADOS.VLBASEICMSSTSAI                 ;
            OUTROW.VLBASEICMSSTSAI_UNIT           := DADOS.VLBASEICMSSTSAI_UNIT            ;
            OUTROW.ALIQICMSINTSAI                 := DADOS.ALIQICMSINTSAI                  ;
            OUTROW.ALIQICMSEXTSAI                 := DADOS.ALIQICMSEXTSAI                  ;
            OUTROW.VLSTSAI                        := DADOS.VLSTSAI                         ;
            OUTROW.VLSTSAI_UNIT                   := DADOS.VLSTSAI_UNIT                    ;
            OUTROW.VLSTGUIASAI                    := DADOS.VLSTGUIASAI                     ;
            OUTROW.VLSTGUIASAI_UNIT               := DADOS.VLSTGUIASAI_UNIT                ;
            OUTROW.CODIPISAI                      := DADOS.CODIPISAI                       ;
            OUTROW.VLBASEIPISAI                   := DADOS.VLBASEIPISAI                    ;
            OUTROW.PERCIPISAI                     := DADOS.PERCIPISAI                      ;
            OUTROW.VLIPISAI                       := DADOS.VLIPISAI                        ;
            OUTROW.VLIPISAI_UNIT                  := DADOS.VLIPISAI_UNIT                   ;
            OUTROW.VLENCARGOSSAI                  := DADOS.VLENCARGOSSAI                   ;
            OUTROW.VLCONTABILSAI                  := DADOS.VLCONTABILSAI                   ;
            OUTROW.VLFRETESAI                     := DADOS.VLFRETESAI                      ;
            OUTROW.VLFRETESAI_UNIT                := DADOS.VLFRETESAI_UNIT                 ;
            OUTROW.VLOUTRASDESPSAI                := DADOS.VLOUTRASDESPSAI                 ;
            OUTROW.VLOUTRASDESPSAI_UNIT           := DADOS.VLOUTRASDESPSAI_UNIT            ;
            OUTROW.VLCONTABILSAI_UNIT             := DADOS.VLCONTABILSAI_UNIT              ;
            OUTROW.VLREDPVENDASIMPLESNASAI        := DADOS.VLREDPVENDASIMPLESNASAI         ;
            OUTROW.NUMTRANSENTORIGEMSAI           := DADOS.NUMTRANSENTORIGEMSAI            ;
            OUTROW.UNIDADEMOVSAI                  := DADOS.UNIDADEMOVSAI                   ;
            OUTROW.NUMSERIEEQUIPSAI               := DADOS.NUMSERIEEQUIPSAI                ;
            OUTROW.NUMSERIESATSAI                 := DADOS.NUMSERIESATSAI                  ;
            OUTROW.USAPMCBASESTSAI                := DADOS.USAPMCBASESTSAI                 ;
            OUTROW.PAUTASAI_UNIT                  := DADOS.PAUTASAI_UNIT                   ;
            OUTROW.VLPAUTA2SAI_UNIT               := DADOS.VLPAUTA2SAI_UNIT                ;
            OUTROW.VLPAUTAICMSANTECSAI_UNIT       := DADOS.VLPAUTAICMSANTECSAI_UNIT        ;
            OUTROW.VLPAUTABCRSAI_UNIT             := DADOS.VLPAUTABCRSAI_UNIT              ;
            OUTROW.PRECOMAXCONSUMSAI_UNIT         := DADOS.PRECOMAXCONSUMSAI_UNIT          ;
            OUTROW.PAUTASAI                       := DADOS.PAUTASAI                        ;
            OUTROW.VLPAUTA2SAI                    := DADOS.VLPAUTA2SAI                     ;
            OUTROW.VLPAUTAICMSANTECSAI            := DADOS.VLPAUTAICMSANTECSAI             ;
            OUTROW.VLPAUTABCRSAI                  := DADOS.VLPAUTABCRSAI                   ;
            OUTROW.PRECOMAXCONSUMSAI              := DADOS.PRECOMAXCONSUMSAI               ;
            OUTROW.PERFCPSTRETSAI                 := DADOS.PERFCPSTRETSAI                  ;
            OUTROW.VLFCPSTRETSAI                  := DADOS.VLFCPSTRETSAI                   ;
            OUTROW.VLFCPSTRETSAI_UNIT             := DADOS.VLFCPSTRETSAI_UNIT              ;
            OUTROW.UNIDADECOMERCIALSAI            := DADOS.UNIDADECOMERCIALSAI             ;
            OUTROW.CODFABRICASAI                  := DADOS.CODFABRICASAI                   ;
            OUTROW.QTUNITCXSAI                    := DADOS.QTUNITCXSAI                     ;
      pipe row(OUTROW);
   END LOOP;
  END IF;
---------------------------------------------------------------------------------
-- FIM DO RELATÓRIO "R45_UE"
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- INICIO DO PROCESSO 'R45_CC'
---------------------------------------------------------------------------------
  IF pRELATORIO = 'R45_CC' THEN
     FOR DADOS IN (
                    SELECT NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                           NVL(ME.NBM, PE.NBM) NCM,
                           ME.CODPROD,
                           NVL(ME.DESCRICAO, PE.DESCRICAO) DSCPRODUTO,
                           NVL(PE.CESTABASICALEGIS,'N') CESTABASICALEGIS,
                           PE.CODLINHAPROD,
                           PE.UNIDADE UNIDADECAD,
                           NVL(PPF.PERCALIQVIGINT,0) PERCALIQVIGINTCAD,
                           NVL(PPF.PERCALIQVIGEXT,0) PERCALIQVIGEXTCAD,
                           ------------------------------------------------------
                           -- Informações de Entradas
                           ------------------------------------------------------
                           E.NUMTRANSENT,
                           E.NUMNOTA NUMNOTAENT,
                           ------------------------------------------------------
                           CASE
                             WHEN ((E.UF = 'EX') AND (NVL(E.GERANFVENDA, 'N') = 'S')) THEN
                               (SELECT CODFORNEC
                                FROM (SELECT F.CODFORNEC,
                                             F.CGC
                                        FROM PCFORNEC F
                                       ORDER BY F.CODFORNEC) A
                               WHERE CGC = PF.CGC
                                 AND ROWNUM = 1)
                           ELSE
                             NVL(E.CODFORNECNF, E.CODFORNEC)
                           END CODFORNECENT,
                           ------------------------------------------------------
                           E.FORNECEDOR FORNECEDORENT,
                           E.CGC CNPJENT,
                           E.IE IEENT,
                           E.CONSUMIDORFINAL CONSUMIDORFINALENT,
                           E.CHAVENFE CHAVENFEENT,
                           E.MODELO MODELOENT,
                           E.UF UFENT,
                           E.UFFILIAL UFFILIALENT,
                           E.DTENT DATAENT,
                           E.DTEMISSAO DATAEMIENT,
                           E.ESPECIE ESPECIEENT,
                           E.SERIE SERIEENT,
                           E.TIPODESCARGA TIPOCOMPRAENT,
                           NVL(E.CONTRIBUINTE,'N') CONTRIBUINTEENT,
                           E.VLTOTAL VLTOTALENT,
                           ME.SITTRIBUT SITTRIBUTENT,
                           MCE.ORIGMERCTRIB ORIGMERCTRIBENT,
                           ME.NUMSEQ NUMSEQENT,
                           MCE.NITEMXML,
                           MCE.NUMSEQENT NUMSEQENT_ENT,
                           ME.IMPORTADO IMPORTADOENT,
                           ME.CODFISCAL CODFISCALENT,
                           ME.CODOPER CODOPERENT,
                           ME.QTCONT QTCONTENT,
                           ME.PUNITCONT PUNITCONTENT,
                           ROUND(ME.QTCONT * NVL(ME.BASEBCR,0), 2) VLBASEBCRENT,
                           NVL(ME.BASEBCR,0) VLBASEBCRENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLDESCONTO,0), 2) VLDESCONTOENT,
                           NVL(ME.VLDESCONTO,0) VLDESCONTOENT_UNIT,
                           ------------------------------------------------------
                           -- CAMPO 12 - BASE ICMS ENTRADA - TOTAL --------------
                           ------------------------------------------------------
                           CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                   ROUND(ME.QTCONT * (NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                ELSE
                                   --ROUND(ME.QTCONT * NVL(ME.BASEICMS, 0),2)
                                CASE WHEN ( (ME.QTCONT * NVL(ME.VLICMSBCR,0)) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND (ME.QTCONT * NVL(ME.BASEICMSBCR,0)) > 0) THEN
                                          ROUND( (ME.QTCONT * NVL(ME.BASEICMSBCR, 0)),2)
                                      WHEN ( (ME.QTCONT * NVL(ME.VLICMSBCR,0)) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND (ME.QTCONT * NVL(ME.BASEICMSBCR,0)) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                          ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                      WHEN ( (ME.QTCONT * (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND (ME.QTCONT * NVL(ME.BASEICMS,0)) > 0) THEN
                                          ROUND( (ME.QTCONT * NVL(ME.BASEICMS, 0)) ,2)
                                      WHEN ( (ME.QTCONT * (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND ( ME.QTCONT * NVL(ME.BASEICMS,0)) = 0) THEN
                                          ROUND( (ME.QTCONT * NVL(ME.BASEICMSBCR, 0)),2)
                                      ELSE
                                          ROUND( (ME.QTCONT * NVL(ME.BASEICMS, 0)),2)
                                  END
                           END VLBASECALCICMSENT,
                           ------------------------------------------------------
                           -- CAMPO 12 - BASE ICMS ENTRADA UNITARIO -------------
                           ------------------------------------------------------
                           CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                      ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                  ELSE
                                  CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                          ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                      WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                          ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                      WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                          ROUND(NVL(ME.BASEICMS, 0),2)
                                      WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                          ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                      ELSE
                                          ROUND(NVL(ME.BASEICMS, 0),2)
                                  END
                           END VLBASECALCICMSENT_UNIT,
                           ------------------------------------------------------
                          -- ME.PERCICM ALIQICMSENT,
                            CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                              ME.PERCICM
                            ELSE
                               CASE WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  = 0 AND NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                        (NVL(ME.VLICMSBCR,0) / NVL(ME.BASEICMSBCR,0)) * 100
                                    WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                         NVL(PPF.PERCALIQVIGINT,0)
                               ELSE
                                  ME.PERCICM
                               END
                            END ALIQICMSENT, /*CAMPO13*/
                           ------------------------------------------------------
                           CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                   ROUND(ME.QTCONT * (NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)) * NVL(ME.PERCICM, 0) / 100, 2)
                                ELSE
                                   CASE WHEN (SAI.CODFISCALSAI BETWEEN 5000 AND 5999) AND
                                               (CASE WHEN E.TIPODESCARGA = 'N' THEN '3'                               
                                                 ELSE                                   
                                                    CASE                                
                                                       WHEN MCE.TIPOCALCST = 'N' THEN '1'                          
                                                       WHEN MCE.TIPOCALCST = 'G' THEN '3'                          
                                                     ELSE '2'                         
                                                  END                                   
                                                 END = 2) THEN
                                    ROUND((LEAST (                                    
                                         /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END,
                                        /*FIM CAMPO 12*/
                                        /*CAMPO 09*/
                                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                                    ELSE
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                             END
                                        /*FIM CAMPO 09*/     
                                          ) *  ((NVL(ME.PERCICM, 0) / 100))) * ME.QTCONT,2)
                                    ELSE
                                        ROUND(ME.QTCONT * (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100),2)
                                    END 
                           END VLICMSENT,
                           ---------------------------
                           CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                     ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)) * NVL(ME.PERCICM, 0) / 100, 2)
                                  ELSE
                                  CASE WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  = 0 AND NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                         NVL(ME.VLICMSBCR,0)
                                       WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  = 0 AND NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0) THEN
                                         NVL(ME.VLICMSBCR,0)
                                  ELSE
                                    CASE WHEN (SAI.CODFISCALSAI BETWEEN 5000 AND 5999) AND
                                               (CASE WHEN E.TIPODESCARGA = 'N' THEN '3'                               
                                                 ELSE                                   
                                                    CASE                                
                                                       WHEN MCE.TIPOCALCST = 'N' THEN '1'                          
                                                       WHEN MCE.TIPOCALCST = 'G' THEN '3'                          
                                                     ELSE '2'                         
                                                  END                                   
                                                 END = 2) THEN
                                    LEAST (                                    
                                         /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END,
                                        /*FIM CAMPO 12*/
                                        /*CAMPO 09*/
                                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                                    ELSE
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                             END
                                        /*FIM CAMPO 09*/     
                                          ) * (NVL(ME.PERCICM, 0) / 100)
                                    ELSE
                                       (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100)
                                    END 
                                  END
                           END VLICMSENT_UNIT, /*CAMPO15*/
                           ------------------------------------------------------
                           CASE
                             WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                               ROUND(ME.QTCONT * NVL(ME.BASEICMSBCR, 0), 2)
                             ELSE
                               0
                           END VLBASECALCICMSBCRENT,
                           ------------------------------------------------------
                           CASE
                             WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                               NVL(ME.BASEICMSBCR, 0)
                             ELSE
                               0
                           END VLBASECALCICMSBCRENT_UNIT,
                           ------------------------------------------------------
                           CASE
                             WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                               ROUND(ME.QTCONT * NVL(ME.VLICMSBCR, 0), 2)
                             ELSE
                               0
                           END VLICMSBCRENT,
                           ------------------------------------------------------
                           CASE
                             WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60') THEN
                               NVL(ME.VLICMSBCR, 0)
                             ELSE
                               0
                           END VLICMSBCRENT_UNIT,
                           -----------------------CAMPO 14-----------------------
                           CASE WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                        ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0) THEN
                                        /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                        ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                              ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END
                                        /*FIM CAMPO 12*/
                                WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0) > 0) AND NVL(ME.BASEICMS,0) > 0)  THEN
                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                WHEN (SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND (NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0) > 0) AND NVL(ME.BASEICMS,0) = 0)  THEN
                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                ELSE
                                    CASE WHEN (SAI.CODFISCALSAI BETWEEN 5000 AND 5999) AND
                                               (CASE WHEN E.TIPODESCARGA = 'N' THEN '3'                               
                                                 ELSE                                   
                                                    CASE                                
                                                       WHEN MCE.TIPOCALCST = 'N' THEN '1'                          
                                                       WHEN MCE.TIPOCALCST = 'G' THEN '3'                          
                                                     ELSE '2'                         
                                                  END                                   
                                                 END = 2) THEN
                                    LEAST (                                    
                                         /*CAMPO 12*/
                                        CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN
                                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2)
                                        ELSE
                                            CASE WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                                WHEN (NVL(ME.VLICMSBCR,0) > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) = '60' AND NVL(ME.BASEICMSBCR,0) = 0 AND NVL(PPF.PERCALIQVIGINT,0) > 0 ) THEN
                                                    ROUND(NVL((ME.VLICMSBCR / PPF.PERCALIQVIGINT) * 100, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) > 0) THEN
                                                    ROUND(NVL(ME.BASEICMS, 0),2)
                                                WHEN ((NVL(ME.ST,0) + NVL(ME.VLDESPADICIONAL,0))  > 0 AND SUBSTR(LPAD(ME.SITTRIBUT, 3, '0'), 2, 2) <> '60' AND NVL(ME.BASEICMS,0) = 0) THEN
                                                    ROUND(NVL(ME.BASEICMSBCR, 0),2)
                                            ELSE
                                               ROUND(DECODE(NVL(ME.BASEICMS, 0),0,LEAST(NVL(ME.PUNITCONT, 0),NVL(ME.BASEBCR, 0)),NVL(ME.BASEICMS, 0)),2)
                                            END
                                        END,
                                        /*FIM CAMPO 12*/
                                        /*CAMPO 09*/
                                             CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                                    ELSE
                                                        ROUND(NVL(ME.BASEICST, 0),2)
                                             END
                                        /*FIM CAMPO 09*/     
                                          )
                                    ELSE
                                       ROUND(DECODE(NVL(ME.BASEICST, 0),0,NVL(ME.PUNITCONT, 0),NVL(ME.BASEICST, 0)),2)
                                    END
                           END VLBASEICMSSTENT_14,
                           ------------------------------------------------------
                           NVL(ME.ALIQICMS1, 0) ALIQICMSINTENT,
                           NVL(ME.ALIQICMS2, 0) ALIQICMSEXTENT,
                           NVL(ME.PERCALIQEXTGUIA, 0) PERCALIQEXTGUIAENT,
                           NVL(ME.PERCIVA, 0) PERCMVAAJUSTADOENT,
                           ROUND(ME.QTCONT * NVL(ME.BASEICST, 0),2) VLBASEICMSSTENT,
                             -----------------------CAMPO 09-----------------------
                           CASE WHEN NVL(ME.BASEICST,0) > 0  THEN
                                        ROUND(NVL(ME.BASEICST, 0),2)
                                    WHEN NVL(ME.VLBASESTFORANF,0) > 0  THEN
                                        ROUND(NVL(ME.VLBASESTFORANF, 0),2)
                                    WHEN NVL(ME.BASEBCR,0) > 0  THEN
                                        ROUND(NVL(ME.BASEBCR, 0),2)
                                    ELSE
                                        ROUND(NVL(ME.BASEICST, 0),2)
                           END VLBASEICMSSTENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.ST, 0),2) VLSTENT,
                           NVL(ME.ST, 0) VLSTENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLBASESTFORANF, 0),2) VLBASEICMSSTENTGUIA,
                           NVL(ME.VLBASESTFORANF, 0) VLBASEICMSSTENTGUIA_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLDESPADICIONAL, 0),2) VLSTGUIAENT,
                           ROUND(ME.QTCONT * NVL(ME.STBCR,0),2) VLSTBCRENT,
                           NVL(ME.STBCR,0) VLSTBCRENT_UNIT,
                           NVL(ME.VLDESPADICIONAL, 0) VLSTGUIAENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLBASEIPI, 0), 2) VLBASEIPIENT,
                           NVL(ME.PERCIPI, 0) PERCIPIENT,
                           ROUND(ME.QTCONT * NVL(ME.VLIPI, 0), 2) VLIPIENT,
                           NVL(ME.VLIPI, 0) VLIPIENT_UNIT,
                           ROUND((ME.QTCONT * (NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTRASDESP, 0))),2) VLENCARGOSENT, --Frete, Seguro, Impostos e outros encargos transf. ou cobr. do destin.
                           NVL(MCE.PERCMVAORIG, 0) VLAGREGADOMVA_ENT, --Margem de Valor Agregado - MVA
                           ------------------------------------------------------
                           CASE WHEN (E.TIPODESCARGA IN ('6','8','C','T')) THEN
                                   ROUND(ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTROS,0)), 2)
                                WHEN E.TIPODESCARGA IN ('N','F','I') THEN
                                   ROUND((ME.QTCONT * ME.PUNITCONT),2)
                                ELSE
                                  ROUND(ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLIPI,0) + NVL(ME.ST,0) + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTRASDESP,0) - NVL(ME.VLDESCONTO,0) - NVL(ME.VLSUFRAMA,0)),2)
                           END VLCONTABILENT,
                           ------------------------------------------------------
                           CASE WHEN (E.TIPODESCARGA IN ('6','8','C','T')) THEN
                                   (ME.PUNITCONT + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTROS,0))
                                WHEN E.TIPODESCARGA IN ('N','F','I') THEN
                                   ME.PUNITCONT
                                ELSE
                                   (ME.PUNITCONT + NVL(ME.VLIPI,0) + NVL(ME.ST,0) + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTRASDESP,0) - NVL(ME.VLDESCONTO,0) - NVL(ME.VLSUFRAMA,0))
                           END VLCONTABILENT_UNIT,
                           ------------------------------------------------------
                           ROUND(ME.QTCONT * NVL(ME.VLFRETE, 0), 2) VLFRETEENT,
                           NVL(ME.VLFRETE, 0) VLFRETEENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLOUTRASDESP, 0), 2) VLOUTRASDESPENT,
                           NVL(ME.VLOUTRASDESP, 0) VLOUTRASDESPENT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLREDPVENDASIMPLESNA, 0), 2) VLREDPVENDASIMPLESNAENT,
                           E.NUMTRANSORIGEM NUMTRANSORIGEMENT,
                           ME.UNIDADE UNIDADEMOVENT,
                           MCE.TIPOCALCST,
                           UE.CHAVENFEULTENT,
                           UE.NUMTRANSENTULTENT,
                           UE.NUMNFULTENT,
                           UE.CODFORNECULTENT,
                           UE.SERIEULTENT,
                           UE.NUMSEQENTULTENT,
                           UE.CODFILIALULTENT,
                           NVL(MCE.VLBASEFCPST,0) VLBASEFCPSTENT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLBASEFCPST,0), 2) VLBASEFCPSTENT,
                           NVL(MCE.ALIQICMSFECP,0) ALIQICMSFECPENT,
                           NVL(MCE.VLFECP,0) VLFECPENT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLFECP,0), 2) VLFECPENT,
                           NVL(MCE.VLFCPSTRET,0) VLFCPSTRETENT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLFCPSTRET,0), 2) VLFCPSTRETENT,
                           NVL(MCE.PERFCPSTRET,0) PERFCPSTRETENT,
                           NVL(ME.PAUTA,0) PAUTAENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.PAUTA,0), 2) PAUTAENT,
                           NVL(ME.VLPAUTA2,0) VLPAUTA2ENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLPAUTA2,0), 2) VLPAUTA2ENT,
                           NVL(ME.VLPAUTAICMS,0) VLPAUTAICMSENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLPAUTAICMS,0), 2) VLPAUTAICMSENT,
                           NVL(ME.VLPAUTAICMSANTEC,0) VLPAUTAICMSANTECENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLPAUTAICMSANTEC,0), 2) VLPAUTAICMSANTECENT,
                           NVL(MCE.VLPAUTABCR,0) VLPAUTABCRENT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLPAUTABCR,0), 2) VLPAUTABCRENT,
                           NVL(MCE.USAPMCBASEST,'N') USAPMCBASESTENT,
                           NVL(MCE.PRECOMAXCONSUM,0) PRECOMAXCONSUMENT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.PRECOMAXCONSUM,0), 2) PRECOMAXCONSUMENT,
                           MCE.UNIDADECOMERCIAL UNIDADECOMERCIALENT,
                           MCE.CODFABRICA CODFABRICAENT,
                           ME.QTUNITCX QTUNITCXENT,
                           NVL(MCE.VLFECPSTGUIA,0) VLFECPSTGUIAT_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLFECPSTGUIA,0), 2) VLFECPSTGUIAENT,
                           NVL(MCE.VLACRESCIMOFUNCEP,0) VLACRESCIMOFUNCEP_UNIT,
                           ROUND(ME.QTCONT * NVL(MCE.VLACRESCIMOFUNCEP,0), 2) VLACRESCIMOFUNCEPENT,
                           NVL(ME.VLIMPORTACAO,0) VLIIENT_UNIT,
                           ROUND(ME.QTCONT * NVL(ME.VLIMPORTACAO,0), 2) VLIIENT,
                           ------------------------------------------------------
                           -- Informações de Saídas
                           ------------------------------------------------------
                           SAI.CODFILIALSAI,
                           SAI.NUMTRANSVENDA,
                           SAI.NUMNOTASAI,
                           SAI.CODCLISAI,
                           SAI.CLIENTESAI,
                           SAI.CNPJSAI,
                           SAI.IESAI,
                           SAI.CONSUMIDORFINALSAI,
                           SAI.CHAVENFESAI,
                           SAI.MODELOSAI,
                           SAI.SIMPLESNACIONALSAI,
                           SAI.UFSAI,
                           SAI.UFFILIALSAI,
                           SAI.DATASAI,
                           SAI.DATAEMISAI,
                           SAI.ESPECIESAI,
                           SAI.SERIESAI,
                           SAI.TIPOVENDASAI,
                           SAI.VLTOTALSAI,
                           SAI.SITTRIBUTSAI,
                           SAI.ORIGMERCTRIBSAI,
                           SAI.NUMSEQSAI,
                           SAI.NUMSEQENTSAI,
                           SAI.IMPORTADOSAI,
                           SAI.CONTRIBUINTESAI,
                           SAI.ORGAOPUBSAI,
                           SAI.ORGAOPUBFEDERALSAI,
                           SAI.ORGAOPUBMUNICIPALSAI,
                           SAI.CODFISCALSAI,
                           SAI.CODOPERSAI,
                           SAI.QTCONTSAI,
                           SAI.QTCONTMOVSAI,
                           SAI.VLBASEBCRSAI,
                           SAI.VLBASEBCRSAI_UNIT,
                           SAI.VLSTBCRSAI,
                           SAI.VLSTBCRSAI_UNIT,
                           SAI.VLDESCONTOSAI,
                           SAI.VLDESCONTOSAI_UNIT,
                           SAI.PUNITCONTSAI,
                           SAI.VLBASECALCICMSSAI,
                           SAI.VLBASECALCICMSSAI_UNIT,
                           SAI.ALIQICMSSAI,
                           SAI.VLICMSSAI,
                           SAI.VLICMSSAI_UNIT,
                           SAI.VLBASEICMSSTSAI,
                           SAI.VLBASEICMSSTSAI_UNIT,
                           SAI.ALIQICMSINTSAI,
                           SAI.ALIQICMSEXTSAI,
                           SAI.VLSTSAI,
                           SAI.VLSTSAI_UNIT,
                           SAI.VLSTGUIASAI,
                           SAI.VLSTGUIASAI_UNIT,
                           SAI.CODIPISAI,
                           SAI.VLBASEIPISAI,
                           SAI.PERCIPISAI,
                           SAI.VLIPISAI,
                           SAI.VLIPISAI_UNIT,
                           SAI.VLENCARGOSSAI,
                           SAI.VLCONTABILSAI,
                           SAI.VLFRETESAI,
                           SAI.VLFRETESAI_UNIT,
                           SAI.VLOUTRASDESPSAI,
                           SAI.VLOUTRASDESPSAI_UNIT,
                           SAI.VLCONTABILSAI_UNIT,
                           SAI.VLREDPVENDASIMPLESNASAI,
                           SAI.NUMTRANSENTORIGEMSAI,
                           SAI.UNIDADEMOVSAI,
                           SAI.NUMSERIEEQUIP NUMSERIEEQUIPSAI,
                           SAI.NUMSERIESAT NUMSERIESATSAI,
                           SAI.USAPMCBASESTSAI,
                           SAI.PAUTASAI_UNIT,
                           SAI.VLPAUTA2SAI_UNIT,
                           SAI.VLPAUTAICMSANTECSAI_UNIT,
                           SAI.VLPAUTABCRSAI_UNIT,
                           SAI.PRECOMAXCONSUMSAI_UNIT,
                           SAI.PAUTASAI,
                           SAI.VLPAUTA2SAI,
                           SAI.VLPAUTAICMSANTECSAI,
                           SAI.VLPAUTABCRSAI,
                           SAI.PRECOMAXCONSUMSAI,
                           SAI.PERFCPSTRETSAI,
                           SAI.VLFCPSTRETSAI,
                           SAI.VLFCPSTRETSAI_UNIT,
                           SAI.UNIDADECOMERCIALSAI,
                           SAI.CODFABRICASAI,
                           SAI.QTUNITCXSAI,
                           SAI.QTDEVOL
                    FROM PCNFENT E,
                         PCFILIAL PF,
                         PCMOV ME,
                         PCMOVCOMPLE MCE,
                         PCUEPSSALDOENT UE,
                         PCPRODUT PE,
                         PCPRODFILIAL PPF,
                         (SELECT S.NUMTRANSVENDA,
                                 NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIALSAI,
                                 S.NUMNOTA NUMNOTASAI,
                                 MVS.NUMTRANSENT NUMTRANSENTSAI,
                                 NVL(S.CODCLINF, S.CODCLI) CODCLISAI,
                                 S.CLIENTE CLIENTESAI,
                                 S.CGC CNPJSAI,
                                 S.IE IESAI,
                                 S.CONSUMIDORFINAL CONSUMIDORFINALSAI,
                                 S.CHAVENFE CHAVENFESAI,
                                 DECODE(S.CHAVENFE, NULL, NULL, SUBSTR(S.CHAVENFE, 21, 2)) MODELOSAI,
                                 NVL(S.SIMPLESNACIONAL,'N') SIMPLESNACIONALSAI,
                                 S.UF UFSAI,
                                 S.UFFILIAL UFFILIALSAI,
                                 S.DTSAIDA DATASAI,
                                 S.DTENTREGA DATAEMISAI,
                                 S.ESPECIE ESPECIESAI,
                                 S.SERIE SERIESAI,
                                 S.TIPOVENDA TIPOVENDASAI,
                                 S.VLTOTAL VLTOTALSAI,
                                 MS.SITTRIBUT SITTRIBUTSAI,
                                 MCS.ORIGMERCTRIB ORIGMERCTRIBSAI,
                                 NVL(MCS.NITEMXML,MS.NUMSEQ) NUMSEQSAI,
                                 MCS.NUMSEQENT NUMSEQENTSAI,
                                 MS.IMPORTADO IMPORTADOSAI,
                                 NVL(S.CONTRIBUINTE,'N') CONTRIBUINTESAI,
                                 NVL(S.ORGAOPUB,'N') ORGAOPUBSAI,
                                 NVL(S.ORGAOPUBFEDERAL,'N') ORGAOPUBFEDERALSAI,
                                 NVL(S.ORGAOPUBMUNICIPAL,'N') ORGAOPUBMUNICIPALSAI,
                                 MS.CODFISCAL CODFISCALSAI,
                                 MS.CODPROD CODPRODSAI,
                                 MS.CODOPER CODOPERSAI,
                                 MAX(MS.QTCONT) QTCONTSAI,
                                 SUM(MVS.QTCONT) QTCONTMOVSAI,
                                 MAX(MS.PUNITCONT) PUNITCONTSAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.BASEBCR,0), 2)) VLBASEBCRSAI,
                                 NVL(MS.BASEBCR,0) VLBASEBCRSAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLDESCONTO,0), 2)) VLDESCONTOSAI,
                                 NVL(MS.VLDESCONTO,0) VLDESCONTOSAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * MS.BASEICMS, 2)) VLBASECALCICMSSAI,
                                 MAX(MS.BASEICMS) VLBASECALCICMSSAI_UNIT,
                                 NVL(MS.PERCICM, 0) ALIQICMSSAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.BASEICMS, 0) * NVL(MS.PERCICM, 0) / 100, 2)) VLICMSSAI,
                                 MAX(NVL(MS.BASEICMS, 0) * NVL(MS.PERCICM, 0) / 100) VLICMSSAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.BASEICST, 0), 2)) VLBASEICMSSTSAI,
                                 MAX(NVL(MS.BASEICST, 0)) VLBASEICMSSTSAI_UNIT,
                                 NVL(MS.ALIQICMS1,0) ALIQICMSINTSAI,
                                 NVL(MS.ALIQICMS2,0) ALIQICMSEXTSAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.ST, 0), 2)) VLSTSAI,
                                 MAX(NVL(MS.ST, 0)) VLSTSAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLDESPADICIONAL, 0), 2)) VLSTGUIASAI,
                                 MAX(NVL(MS.VLDESPADICIONAL, 0)) VLSTGUIASAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.STBCR,0), 2)) VLSTBCRSAI,
                                 NVL(MS.STBCR,0) VLSTBCRSAI_UNIT,
                                 MCS.CODSITTRIBIPI CODIPISAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLBASEIPI, 0), 2)) VLBASEIPISAI,
                                 NVL(MS.PERCIPI, 0) PERCIPISAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLIPI, 0), 2)) VLIPISAI,
                                 MAX(NVL(MS.VLIPI, 0)) VLIPISAI_UNIT,
                                 SUM(ROUND((MS.QTCONT * (NVL(MS.VLFRETE, 0) + NVL(MS.VLOUTRASDESP, 0))),2)) VLENCARGOSSAI, --Frete, Seguro, Impostos e outros encargos transf. ou cobr. do destin.
                                 MAX(NVL(MCS.PERCMVAORIG, 0)) VLAGREGADOMVASAI, --Margem de Valor Agregado - MVA
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLFRETE, 0), 2)) VLFRETESAI,
                                 MAX(NVL(MS.VLFRETE, 0)) VLFRETESAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLOUTRASDESP, 0), 2)) VLOUTRASDESPSAI,
                                 MAX(NVL(MS.VLOUTRASDESP, 0)) VLOUTRASDESPSAI_UNIT,
                                 ------------------------------------------------
                                 SUM(CASE WHEN (NVL(MS.CODOPER,'X') <> 'SD') THEN
                                           ROUND(MS.QTCONT * (MS.PUNITCONT + NVL(MS.VLFRETE,0) + NVL(MS.VLOUTROS,0)), 2)
                                        ELSE
                                           ROUND(MS.QTCONT * (MS.PUNITCONT + NVL(MS.VLOUTRASDESP,0)), 2)
                                     END) VLCONTABILSAI,
                                 ------------------------------------------------
                                 MAX(CASE WHEN (NVL(MS.CODOPER,'X') <> 'SD') THEN
                                           (MS.PUNITCONT + NVL(MS.VLFRETE,0) + NVL(MS.VLOUTROS,0))
                                        ELSE
                                           (MS.PUNITCONT + NVL(MS.VLOUTRASDESP,0))
                                     END) VLCONTABILSAI_UNIT,
                                 ------------------------------------------------
                                 SUM(ROUND(MS.QTCONT * NVL(MCS.VLREDPVENDASIMPLESNA, 0),2)) VLREDPVENDASIMPLESNASAI,
                                 S.NUMTRANSENTORIGEM NUMTRANSENTORIGEMSAI,
                                 MS.UNIDADE UNIDADEMOVSAI,
                                 MVS.NUMSEQENTULTENT,
                                 S.NUMSERIEEQUIP,
                                 S.NUMSERIESAT,
                                 NVL(MCS.USAPMCBASEST,'N') USAPMCBASESTSAI,
                                 MAX(NVL(MS.PAUTA,0)) PAUTASAI_UNIT,
                                 MAX(NVL(MS.VLPAUTA2,0)) VLPAUTA2SAI_UNIT,
                                 MAX(NVL(MS.VLPAUTAICMSANTEC,0)) VLPAUTAICMSANTECSAI_UNIT,
                                 MAX(NVL(MCS.VLPAUTABCR,0)) VLPAUTABCRSAI_UNIT,
                                 MAX(NVL(MCS.PRECOMAXCONSUM,0)) PRECOMAXCONSUMSAI_UNIT,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.PAUTA, 0), 2)) PAUTASAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLPAUTA2,0), 2)) VLPAUTA2SAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MS.VLPAUTAICMSANTEC,0), 2)) VLPAUTAICMSANTECSAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MCS.VLPAUTABCR,0), 2)) VLPAUTABCRSAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MCS.PRECOMAXCONSUM,0), 2)) PRECOMAXCONSUMSAI,
                                 NVL(MCS.PERFCPSTRET,0) PERFCPSTRETSAI,
                                 SUM(ROUND(MS.QTCONT * NVL(MCS.VLFCPSTRET,0), 2)) VLFCPSTRETSAI,
                                 MAX(NVL(MCS.VLFCPSTRET,0)) VLFCPSTRETSAI_UNIT,
                                 MAX(MCS.UNIDADECOMERCIAL) UNIDADECOMERCIALSAI,
                                 MAX(MCS.CODFABRICA) CODFABRICASAI,
                                 MAX(MS.QTUNITCX) QTUNITCXSAI,
                                 MAX(MS.QTDEVOL) QTDEVOL
                          FROM PCNFSAID S,
                               PCMOV MS,
                               PCMOVCOMPLE MCS,
                               PCUEPSSALDOSAID MVS
                          WHERE S.NUMTRANSVENDA = MS.NUMTRANSVENDA
                            AND S.NUMNOTA = MS.NUMNOTA
                            AND MS.NUMTRANSITEM = MCS.NUMTRANSITEM(+)
                            AND MVS.NUMTRANSVENDA(+) = MS.NUMTRANSVENDA
                            AND MVS.CODPROD(+) = MS.CODPROD
                            AND S.ESPECIE IN ('NF','CP')
                            AND MS.STATUS IN ('A','AB')
                            AND MS.DTCANCEL IS NULL
                            -- Filtrando Pelas Datas
                            AND S.DTSAIDA BETWEEN pDTINICIO AND pDTFIM
                            AND MVS.DTSAIDA BETWEEN pDTINICIO AND pDTFIM
                            AND MS.DTMOV BETWEEN pDTINICIO AND pDTFIM
                            -- Filtrando pelas Filiais 
                            AND NVL(S.CODFILIALNF, S.CODFILIAL) = pCODFILIAL
                            AND NVL(MS.CODFILIALNF, MS.CODFILIAL) = pCODFILIAL
                            AND MVS.CODFILIAL = pCODFILIAL
                            -- Predicado
                            AND S.DTSAIDA   >= (SELECT MIN(dtsaida) FROM pcnfsaid)
                            AND MVS.DTSAIDA >= (SELECT MIN(dtsaida) FROM pcnfsaid)
                            AND MS.DTMOV    >= (SELECT MIN(dtsaida) FROM pcnfsaid)                             
                           GROUP BY S.NUMTRANSVENDA, S.NUMNOTA, MVS.NUMTRANSENT, S.CGC, S.IE, S.CONSUMIDORFINAL, S.CHAVENFE, S.NUMSERIEEQUIP,
                                    NVL(S.SIMPLESNACIONAL,'N'), S.DTSAIDA, S.DTENTREGA, NVL(S.CODCLINF, S.CODCLI), S.NUMTRANSENTORIGEM,
                                    S.CLIENTE, S.UF, S.UFFILIAL, S.ESPECIE, S.SERIE, S.TIPOVENDA, NVL(S.CONTRIBUINTE,'N'), S.NUMSERIESAT,
                                    NVL(S.ORGAOPUB,'N'), NVL(S.ORGAOPUBFEDERAL,'N'), NVL(S.ORGAOPUBMUNICIPAL,'N'), NVL(MCS.USAPMCBASEST,'N'),
                                    S.VLTOTAL, MS.CODPROD, MS.UNIDADE, MS.SITTRIBUT, MCS.ORIGMERCTRIB, NVL(MCS.NITEMXML,MS.NUMSEQ), MCS.NUMSEQENT, MS.IMPORTADO,
                                    MS.CODFISCAL, MS.CODOPER, MS.PERCICM, MS.ALIQICMS1, MS.ALIQICMS2, NVL(MCS.PERFCPSTRET,0),
                                    NVL(MS.BASEBCR,0), NVL(MS.STBCR,0), NVL(MS.VLDESCONTO,0), MCS.CODSITTRIBIPI,
                                    MS.PERCIPI,NVL(S.CODFILIALNF,S.CODFILIAL), MVS.NUMSEQENTULTENT
                         ) SAI
                    WHERE E.NUMTRANSENT = ME.NUMTRANSENT
                      AND E.NUMNOTA = ME.NUMNOTA
                      AND PF.CODIGO = NVL(E.CODFILIALNF, E.CODFILIAL)
                      AND NVL(E.CODFILIALNF, E.CODFILIAL)  = NVL(ME.CODFILIALNF, ME.CODFILIAL)
                      AND E.NUMTRANSENT = UE.NUMTRANSENT
                      AND ME.CODPROD = UE.CODPROD
                      AND ME.CODPROD = PE.CODPROD
                      AND ME.NUMTRANSITEM = MCE.NUMTRANSITEM(+)
                      AND ME.CODPROD(+) = SAI.CODPRODSAI
                      AND ME.NUMTRANSENT(+) = SAI.NUMTRANSENTSAI
                      AND NVL(MCE.NUMSEQENT, 1) = DECODE(NVL(UE.NUMTRANSENTULTENT, -1), -1, NVL(UE.NUMSEQENTULTENT, 1), NVL(MCE.NUMSEQENT, 1)) -- SOMENTE QUANDO VINCULO É NA MESMA FILIAL
                      AND ME.CODPROD = PPF.CODPROD
                      AND NVL(ME.CODFILIALNF,ME.CODFILIAL) = PPF.CODFILIAL
                      AND E.ESPECIE = 'NF'
                      AND ME.DTCANCEL IS NULL
                      AND ME.STATUS IN ('A','AB')
                      AND NVL(E.CODFILIALNF, E.CODFILIAL) = pCODFILIAL
                      AND NVL(ME.CODFILIALNF, ME.CODFILIAL) = pCODFILIAL
                      AND UE.CODFILIAL = pCODFILIAL

                     )
     LOOP
            OUTROW.CODFILIAL                      := DADOS.CODFILIAL                       ;
            OUTROW.NCM                            := DADOS.NCM                             ;
            OUTROW.CODPROD                        := DADOS.CODPROD                         ;
            OUTROW.DSCPRODUTO                     := DADOS.DSCPRODUTO                      ;
            OUTROW.CESTABASICALEGIS               := DADOS.CESTABASICALEGIS                ;
            OUTROW.CODLINHAPROD                   := DADOS.CODLINHAPROD                    ;
            OUTROW.UNIDADECAD                     := DADOS.UNIDADECAD                      ;
            OUTROW.PERCALIQVIGINTCAD              := DADOS.PERCALIQVIGINTCAD               ;
            OUTROW.PERCALIQVIGEXTCAD              := DADOS.PERCALIQVIGEXTCAD               ;
            OUTROW.NUMTRANSENT                    := DADOS.NUMTRANSENT                     ;
            OUTROW.NUMNOTAENT                     := DADOS.NUMNOTAENT                      ;
            OUTROW.CODFORNECENT                   := DADOS.CODFORNECENT                    ;
            OUTROW.FORNECEDORENT                  := DADOS.FORNECEDORENT                   ;
            OUTROW.CNPJENT                        := DADOS.CNPJENT                         ;
            OUTROW.IEENT                          := DADOS.IEENT                           ;
            OUTROW.CONSUMIDORFINALENT             := DADOS.CONSUMIDORFINALENT              ;
            OUTROW.CHAVENFEENT                    := DADOS.CHAVENFEENT                     ;
            OUTROW.MODELOENT                      := DADOS.MODELOENT                       ;
            OUTROW.UFENT                          := DADOS.UFENT                           ;
            OUTROW.UFFILIALENT                    := DADOS.UFFILIALENT                     ;
            OUTROW.DATAENT                        := DADOS.DATAENT                         ;
            OUTROW.DATAEMIENT                     := DADOS.DATAEMIENT                      ;
            OUTROW.ESPECIEENT                     := DADOS.ESPECIEENT                      ;
            OUTROW.SERIEENT                       := DADOS.SERIEENT                        ;
            OUTROW.TIPOCOMPRAENT                  := DADOS.TIPOCOMPRAENT                   ;
            OUTROW.CONTRIBUINTEENT                := DADOS.CONTRIBUINTEENT                 ;
            OUTROW.VLTOTALENT                     := DADOS.VLTOTALENT                      ;
            OUTROW.SITTRIBUTENT                   := DADOS.SITTRIBUTENT                    ;
            OUTROW.ORIGMERCTRIBENT                := DADOS.ORIGMERCTRIBENT                 ;
            OUTROW.NUMSEQENT                      := DADOS.NUMSEQENT                       ;
            OUTROW.NITEMXML                       := DADOS.NITEMXML                        ;
            OUTROW.NUMSEQENT_ENT                  := DADOS.NUMSEQENT_ENT                   ;
            OUTROW.IMPORTADOENT                   := DADOS.IMPORTADOENT                    ;
            OUTROW.CODFISCALENT                   := DADOS.CODFISCALENT                    ;
            OUTROW.CODOPERENT                     := DADOS.CODOPERENT                      ;
            OUTROW.QTCONTENT                      := DADOS.QTCONTENT                       ;
            OUTROW.PUNITCONTENT                   := DADOS.PUNITCONTENT                    ;
            OUTROW.VLBASEBCRENT                   := DADOS.VLBASEBCRENT                    ;
            OUTROW.VLBASEBCRENT_UNIT              := DADOS.VLBASEBCRENT_UNIT               ;
            OUTROW.VLDESCONTOENT                  := DADOS.VLDESCONTOENT                   ;
            OUTROW.VLDESCONTOENT_UNIT             := DADOS.VLDESCONTOENT_UNIT              ;
            OUTROW.VLBASECALCICMSENT              := DADOS.VLBASECALCICMSENT               ;
            OUTROW.VLBASECALCICMSENT_UNIT         := DADOS.VLBASECALCICMSENT_UNIT          ;
            OUTROW.ALIQICMSENT                    := DADOS.ALIQICMSENT                     ;
            OUTROW.VLICMSENT                      := DADOS.VLICMSENT                       ;
            OUTROW.VLICMSENT_UNIT                 := DADOS.VLICMSENT_UNIT                  ;
            OUTROW.VLBASECALCICMSBCRENT           := DADOS.VLBASECALCICMSBCRENT            ;
            OUTROW.VLBASECALCICMSBCRENT_UNIT      := DADOS.VLBASECALCICMSBCRENT_UNIT       ;
            OUTROW.VLICMSBCRENT                   := DADOS.VLICMSBCRENT                    ;
            OUTROW.VLICMSBCRENT_UNIT              := DADOS.VLICMSBCRENT_UNIT               ;
            OUTROW.VLBASEICMSSTENT_14             := DADOS.VLBASEICMSSTENT_14              ;
            OUTROW.ALIQICMSINTENT                 := DADOS.ALIQICMSINTENT                  ;
            OUTROW.ALIQICMSEXTENT                 := DADOS.ALIQICMSEXTENT                  ;
            OUTROW.PERCALIQEXTGUIAENT             := DADOS.PERCALIQEXTGUIAENT              ;
            OUTROW.PERCMVAAJUSTADOENT             := DADOS.PERCMVAAJUSTADOENT              ;
            OUTROW.VLBASEICMSSTENT                := DADOS.VLBASEICMSSTENT                 ;
            OUTROW.VLBASEICMSSTENT_UNIT           := DADOS.VLBASEICMSSTENT_UNIT            ;
            OUTROW.VLSTENT                        := DADOS.VLSTENT                         ;
            OUTROW.VLSTENT_UNIT                   := DADOS.VLSTENT_UNIT                    ;
            OUTROW.VLBASEICMSSTENTGUIA            := DADOS.VLBASEICMSSTENTGUIA             ;
            OUTROW.VLBASEICMSSTENTGUIA_UNIT       := DADOS.VLBASEICMSSTENTGUIA_UNIT        ;
            OUTROW.VLSTGUIAENT                    := DADOS.VLSTGUIAENT                     ;
            OUTROW.VLSTBCRENT                     := DADOS.VLSTBCRENT                      ;
            OUTROW.VLSTBCRENT_UNIT                := DADOS.VLSTBCRENT_UNIT                 ;
            OUTROW.VLSTGUIAENT_UNIT               := DADOS.VLSTGUIAENT_UNIT                ;
            OUTROW.VLBASEIPIENT                   := DADOS.VLBASEIPIENT                    ;
            OUTROW.PERCIPIENT                     := DADOS.PERCIPIENT                      ;
            OUTROW.VLIPIENT                       := DADOS.VLIPIENT                        ;
            OUTROW.VLIPIENT_UNIT                  := DADOS.VLIPIENT_UNIT                   ;
            OUTROW.VLENCARGOSENT                  := DADOS.VLENCARGOSENT                   ;
            OUTROW.VLAGREGADOMVA_ENT              := DADOS.VLAGREGADOMVA_ENT               ;
            OUTROW.VLCONTABILENT                  := DADOS.VLCONTABILENT                   ;
            OUTROW.VLCONTABILENT_UNIT             := DADOS.VLCONTABILENT_UNIT              ;
            OUTROW.VLFRETEENT                     := DADOS.VLFRETEENT                      ;
            OUTROW.VLFRETEENT_UNIT                := DADOS.VLFRETEENT_UNIT                 ;
            OUTROW.VLOUTRASDESPENT                := DADOS.VLOUTRASDESPENT                 ;
            OUTROW.VLOUTRASDESPENT_UNIT           := DADOS.VLOUTRASDESPENT_UNIT            ;
            OUTROW.VLREDPVENDASIMPLESNAENT        := DADOS.VLREDPVENDASIMPLESNAENT         ;
            OUTROW.NUMTRANSORIGEMENT              := DADOS.NUMTRANSORIGEMENT               ;
            OUTROW.UNIDADEMOVENT                  := DADOS.UNIDADEMOVENT                   ;
            OUTROW.TIPOCALCST                     := DADOS.TIPOCALCST                      ;
            OUTROW.VLBASEFCPSTENT_UNIT            := DADOS.VLBASEFCPSTENT_UNIT             ;
            OUTROW.VLBASEFCPSTENT                 := DADOS.VLBASEFCPSTENT                  ;
            OUTROW.ALIQICMSFECPENT                := DADOS.ALIQICMSFECPENT                 ;
            OUTROW.VLFECPENT_UNIT                 := DADOS.VLFECPENT_UNIT                  ;
            OUTROW.VLFECPENT                      := DADOS.VLFECPENT                       ;
            OUTROW.VLFECPSTGUIAT_UNIT             := DADOS.VLFECPSTGUIAT_UNIT              ;
            OUTROW.VLFECPSTGUIAENT                := DADOS.VLFECPSTGUIAENT                 ;
            OUTROW.VLACRESCIMOFUNCEP_UNIT         := DADOS.VLACRESCIMOFUNCEP_UNIT          ;
            OUTROW.VLACRESCIMOFUNCEPENT           := DADOS.VLACRESCIMOFUNCEPENT            ;
            OUTROW.VLFCPSTRETENT_UNIT             := DADOS.VLFCPSTRETENT_UNIT              ;
            OUTROW.VLFCPSTRETENT                  := DADOS.VLFCPSTRETENT                   ;
            OUTROW.PERFCPSTRETENT                 := DADOS.PERFCPSTRETENT                  ;
            OUTROW.PAUTAENT_UNIT                  := DADOS.PAUTAENT_UNIT                   ;
            OUTROW.PAUTAENT                       := DADOS.PAUTAENT                        ;
            OUTROW.VLPAUTA2ENT_UNIT               := DADOS.VLPAUTA2ENT_UNIT                ;
            OUTROW.VLPAUTA2ENT                    := DADOS.VLPAUTA2ENT                     ;
            OUTROW.VLPAUTAICMSENT_UNIT            := DADOS.VLPAUTAICMSENT_UNIT             ;
            OUTROW.VLPAUTAICMSENT                 := DADOS.VLPAUTAICMSENT                  ;
            OUTROW.VLPAUTAICMSANTECENT_UNIT       := DADOS.VLPAUTAICMSANTECENT_UNIT        ;
            OUTROW.VLPAUTAICMSANTECENT            := DADOS.VLPAUTAICMSANTECENT             ;
            OUTROW.VLPAUTABCRENT_UNIT             := DADOS.VLPAUTABCRENT_UNIT              ;
            OUTROW.VLPAUTABCRENT                  := DADOS.VLPAUTABCRENT                   ;
            OUTROW.USAPMCBASESTENT                := DADOS.USAPMCBASESTENT                 ;
            OUTROW.PRECOMAXCONSUMENT_UNIT         := DADOS.PRECOMAXCONSUMENT_UNIT          ;
            OUTROW.PRECOMAXCONSUMENT              := DADOS.PRECOMAXCONSUMENT               ;
            OUTROW.UNIDADECOMERCIALENT            := DADOS.UNIDADECOMERCIALENT             ;
            OUTROW.CODFABRICAENT                  := DADOS.CODFABRICAENT                   ;
            OUTROW.QTUNITCXENT                    := DADOS.QTUNITCXENT                     ;
            OUTROW.CHAVENFEULTENT                 := DADOS.CHAVENFEULTENT                  ;
            OUTROW.NUMTRANSENTULTENT              := DADOS.NUMTRANSENTULTENT               ;
            OUTROW.NUMNFULTENT                    := DADOS.NUMNFULTENT                     ;
            OUTROW.CODFORNECULTENT                := DADOS.CODFORNECULTENT                 ;
            OUTROW.SERIEULTENT                    := DADOS.SERIEULTENT                     ;
            OUTROW.NUMSEQENTULTENT                := DADOS.NUMSEQENTULTENT                 ;
            OUTROW.CODFILIALULTENT                := DADOS.CODFILIALULTENT                 ;
            OUTROW.CODFILIALSAI                   := DADOS.CODFILIALSAI                    ;
            OUTROW.NUMTRANSVENDA                  := DADOS.NUMTRANSVENDA                   ;
            OUTROW.NUMNOTASAI                     := DADOS.NUMNOTASAI                      ;
            OUTROW.CODCLISAI                      := DADOS.CODCLISAI                       ;
            OUTROW.CLIENTESAI                     := DADOS.CLIENTESAI                      ;
            OUTROW.CNPJSAI                        := DADOS.CNPJSAI                         ;
            OUTROW.IESAI                          := DADOS.IESAI                           ;
            OUTROW.CONSUMIDORFINALSAI             := DADOS.CONSUMIDORFINALSAI              ;
            OUTROW.CHAVENFESAI                    := DADOS.CHAVENFESAI                     ;
            OUTROW.MODELOSAI                      := DADOS.MODELOSAI                       ;
            OUTROW.SIMPLESNACIONALSAI             := DADOS.SIMPLESNACIONALSAI              ;
            OUTROW.UFSAI                          := DADOS.UFSAI                           ;
            OUTROW.UFFILIALSAI                    := DADOS.UFFILIALSAI                     ;
            OUTROW.DATASAI                        := DADOS.DATASAI                         ;
            OUTROW.DATAEMISAI                     := DADOS.DATAEMISAI                      ;
            OUTROW.ESPECIESAI                     := DADOS.ESPECIESAI                      ;
            OUTROW.SERIESAI                       := DADOS.SERIESAI                        ;
            OUTROW.TIPOVENDASAI                   := DADOS.TIPOVENDASAI                    ;
            OUTROW.VLTOTALSAI                     := DADOS.VLTOTALSAI                      ;
            OUTROW.SITTRIBUTSAI                   := DADOS.SITTRIBUTSAI                    ;
            OUTROW.ORIGMERCTRIBSAI                := DADOS.ORIGMERCTRIBSAI                 ;
            OUTROW.NUMSEQSAI                      := DADOS.NUMSEQSAI                       ;
            OUTROW.NUMSEQENTSAI                   := DADOS.NUMSEQENTSAI                    ;
            OUTROW.IMPORTADOSAI                   := DADOS.IMPORTADOSAI                    ;
            OUTROW.CONTRIBUINTESAI                := DADOS.CONTRIBUINTESAI                 ;
            OUTROW.ORGAOPUBSAI                    := DADOS.ORGAOPUBSAI                     ;
            OUTROW.ORGAOPUBFEDERALSAI             := DADOS.ORGAOPUBFEDERALSAI              ;
            OUTROW.ORGAOPUBMUNICIPALSAI           := DADOS.ORGAOPUBMUNICIPALSAI            ;
            OUTROW.CODFISCALSAI                   := DADOS.CODFISCALSAI                    ;
            OUTROW.CODOPERSAI                     := DADOS.CODOPERSAI                      ;
            OUTROW.QTCONTSAI                      := DADOS.QTCONTSAI                       ;
            OUTROW.VLBASEBCRSAI                   := DADOS.VLBASEBCRSAI                    ;
            OUTROW.VLBASEBCRSAI_UNIT              := DADOS.VLBASEBCRSAI_UNIT               ;
            OUTROW.VLSTBCRSAI                     := DADOS.VLSTBCRSAI                      ;
            OUTROW.VLSTBCRSAI_UNIT                := DADOS.VLSTBCRSAI_UNIT                 ;
            OUTROW.VLDESCONTOSAI                  := DADOS.VLDESCONTOSAI                   ;
            OUTROW.VLDESCONTOSAI_UNIT             := DADOS.VLDESCONTOSAI_UNIT              ;
            OUTROW.PUNITCONTSAI                   := DADOS.PUNITCONTSAI                    ;
            OUTROW.VLBASECALCICMSSAI              := DADOS.VLBASECALCICMSSAI               ;
            OUTROW.VLBASECALCICMSSAI_UNIT         := DADOS.VLBASECALCICMSSAI_UNIT          ;
            OUTROW.ALIQICMSSAI                    := DADOS.ALIQICMSSAI                     ;
            OUTROW.VLICMSSAI                      := DADOS.VLICMSSAI                       ;
            OUTROW.VLICMSSAI_UNIT                 := DADOS.VLICMSSAI_UNIT                  ;
            OUTROW.VLBASEICMSSTSAI                := DADOS.VLBASEICMSSTSAI                 ;
            OUTROW.VLBASEICMSSTSAI_UNIT           := DADOS.VLBASEICMSSTSAI_UNIT            ;
            OUTROW.ALIQICMSINTSAI                 := DADOS.ALIQICMSINTSAI                  ;
            OUTROW.ALIQICMSEXTSAI                 := DADOS.ALIQICMSEXTSAI                  ;
            OUTROW.VLSTSAI                        := DADOS.VLSTSAI                         ;
            OUTROW.VLSTSAI_UNIT                   := DADOS.VLSTSAI_UNIT                    ;
            OUTROW.VLSTGUIASAI                    := DADOS.VLSTGUIASAI                     ;
            OUTROW.VLSTGUIASAI_UNIT               := DADOS.VLSTGUIASAI_UNIT                ;
            OUTROW.CODIPISAI                      := DADOS.CODIPISAI                       ;
            OUTROW.VLBASEIPISAI                   := DADOS.VLBASEIPISAI                    ;
            OUTROW.PERCIPISAI                     := DADOS.PERCIPISAI                      ;
            OUTROW.VLIPISAI                       := DADOS.VLIPISAI                        ;
            OUTROW.VLIPISAI_UNIT                  := DADOS.VLIPISAI_UNIT                   ;
            OUTROW.VLENCARGOSSAI                  := DADOS.VLENCARGOSSAI                   ;
            OUTROW.VLCONTABILSAI                  := DADOS.VLCONTABILSAI                   ;
            OUTROW.VLFRETESAI                     := DADOS.VLFRETESAI                      ;
            OUTROW.VLFRETESAI_UNIT                := DADOS.VLFRETESAI_UNIT                 ;
            OUTROW.VLOUTRASDESPSAI                := DADOS.VLOUTRASDESPSAI                 ;
            OUTROW.VLOUTRASDESPSAI_UNIT           := DADOS.VLOUTRASDESPSAI_UNIT            ;
            OUTROW.VLCONTABILSAI_UNIT             := DADOS.VLCONTABILSAI_UNIT              ;
            OUTROW.VLREDPVENDASIMPLESNASAI        := DADOS.VLREDPVENDASIMPLESNASAI         ;
            OUTROW.NUMTRANSENTORIGEMSAI           := DADOS.NUMTRANSENTORIGEMSAI            ;
            OUTROW.UNIDADEMOVSAI                  := DADOS.UNIDADEMOVSAI                   ;
            OUTROW.NUMSERIEEQUIPSAI               := DADOS.NUMSERIEEQUIPSAI                ;
            OUTROW.NUMSERIESATSAI                 := DADOS.NUMSERIESATSAI                  ;
            OUTROW.USAPMCBASESTSAI                := DADOS.USAPMCBASESTSAI                 ;
            OUTROW.PAUTASAI_UNIT                  := DADOS.PAUTASAI_UNIT                   ;
            OUTROW.VLPAUTA2SAI_UNIT               := DADOS.VLPAUTA2SAI_UNIT                ;
            OUTROW.VLPAUTAICMSANTECSAI_UNIT       := DADOS.VLPAUTAICMSANTECSAI_UNIT        ;
            OUTROW.VLPAUTABCRSAI_UNIT             := DADOS.VLPAUTABCRSAI_UNIT              ;
            OUTROW.PRECOMAXCONSUMSAI_UNIT         := DADOS.PRECOMAXCONSUMSAI_UNIT          ;
            OUTROW.PAUTASAI                       := DADOS.PAUTASAI                        ;
            OUTROW.VLPAUTA2SAI                    := DADOS.VLPAUTA2SAI                     ;
            OUTROW.VLPAUTAICMSANTECSAI            := DADOS.VLPAUTAICMSANTECSAI             ;
            OUTROW.VLPAUTABCRSAI                  := DADOS.VLPAUTABCRSAI                   ;
            OUTROW.PRECOMAXCONSUMSAI              := DADOS.PRECOMAXCONSUMSAI               ;
            OUTROW.PERFCPSTRETSAI                 := DADOS.PERFCPSTRETSAI                  ;
            OUTROW.VLFCPSTRETSAI                  := DADOS.VLFCPSTRETSAI                   ;
            OUTROW.VLFCPSTRETSAI_UNIT             := DADOS.VLFCPSTRETSAI_UNIT              ;
            OUTROW.UNIDADECOMERCIALSAI            := DADOS.UNIDADECOMERCIALSAI             ;
            OUTROW.CODFABRICASAI                  := DADOS.CODFABRICASAI                   ;
            OUTROW.QTUNITCXSAI                    := DADOS.QTUNITCXSAI                     ;
            OUTROW.QTDEVOL                        := DADOS.QTDEVOL                         ;
            OUTROW.QTCONTMOVSAI                   := DADOS.QTCONTMOVSAI                    ;
            OUTROW.VLIIENT_UNIT                   := DADOS.VLIIENT_UNIT                    ;
            OUTROW.VLIIENT                        := DADOS.VLIIENT                         ;
     pipe row(OUTROW);
     END LOOP;
  END IF;
---------------------------------------------------------------------------------
-- FIM DO RELATÓRIO "R45_CC"
---------------------------------------------------------------------------------
EXCEPTION
  when others then
    RAISE_APPLICATION_ERROR(-20000,
                            'OCORREU UM ERRO AO PROCESSAR DADOS DA ROTINA 1017!' ||
                            CHR(13) || 'ERRO ORIGINAL: ' || sqlerrm);
END;
---------------------------------------------------------------------------------
-- 001 - 21/03/2023 - Performance --
-- 002 - 13/12/2024 - Performance -- Alteração nos objetos vinculados
-- 003 - 04/03/2026 - Implementado a função Round em todas as colunas do sql que são multiplicadas pelo qtcont
---------------------------------------------------------------------------------