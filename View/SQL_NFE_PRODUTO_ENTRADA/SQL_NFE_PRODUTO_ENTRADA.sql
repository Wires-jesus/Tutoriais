CREATE OR REPLACE VIEW SQL_NFE_PRODUTO_ENTRADA AS
SELECT NUM_TRANSACAO
      ,NUMSEQ
      ,CODPROD
      ,NUM_CHAVE_EXPORTACAO
      ,NUM_REGISTRO_EXPORTACAO
      ,CODIGO_PRODUTO
      ,EAN
      ,DIGITO_PRODUTO
      ,PRODUTO
      ,NATUREZAPRODUTO
      ,INFO_TECNICA
      ,NCM
      ,EXTIPI
      ,GENERO
      ,CFOP
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
         '0'
       else UNIDADE_COMERCIAL end UNIDADE_COMERCIAL
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
         0
       else QUANTIDADE_COMERCIAL end QUANTIDADE_COMERCIAL
      ,VALOR_COMERCIAL
      ,VALOR_LIQUIDO
      ,ROUND(QUANTIDADE_COMERCIAL * VALOR_COMERCIAL, 2) AS VALOR_PRODUTOS
      ,EAN_UNIDADE
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
             '0'
      else UNIDADE_TRIBUTAVEL end UNIDADE_TRIBUTAVEL
    ,NULL as UNIDADE_TRIBUTAVEL_EX
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
       0 else QUANTIDADE_TRIBUTAVEL end QUANTIDADE_TRIBUTAVEL
    ,NULL as QUANTIDADE_TRIBUTAVEL_EX
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
        0 else VALOR_TRIBUTAVEL end VALOR_TRIBUTAVEL
    ,NULL as VALOR_TRIBUTAVEL_EX
      ,VALOR_FRETE
      ,VALOR_SEGURO
      ,VALOR_DESCONTO
      ,PESO_BRUTO
      ,PERCIPIVENDA
      ,VLIPIPORKGVENDA
      ,TIPOMERC
      ,NUM_DOC_IMPORTACAO
      ,LOCAL_DESEMBARACO
      ,SIGLA_UF_DESEMBARACO
      ,DATA_DESEMBARACO
      ,CODIGO_EXPORTADOR
      ,NUMERO_ADICAO
      ,NUMERO_SEQUENCIA
      ,CODIGO_FABRICANTE_EX
      ,VALOR_DESCONTO_ADICAO
      ,NUMERO_LOTE
      ,QT_LOTE
      ,DATA_FABRICACAO
      ,DATA_VALIDADE
      ,PRECO_MAXIMO
      ,ORIGEM_MERCADORIA
      ,SITUACAO_TRIBUTARIA
      ,MODALIDADE_BC_ICMS
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100) AND
                  (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARINFODIFERTOTICMSXML', CODFILIAL) = 'N')) THEN
        0
       ELSE
        BASE_ICMS
       END BASE_ICMS
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100) AND
                  (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARINFODIFERTOTICMSXML', CODFILIAL) = 'N')) THEN
        0
       ELSE
         ALIQUOTA_ICMS
       END ALIQUOTA_ICMS
      ,VALOR_ICMS
      ,VALOR_CREDITO_ICMS_SN
      ,SITUACAO_TRIBUTARIA_IPI
      ,BASE_IPI
      ,VALOR_IPI
      ,VALOR_IPI_UNIDADE
      ,ALIQUOTA_IPI
      ,PERCENTUAL_REDUCAO_BC
      ,MODALIDADE_BC_ST
      ,PERCENTUAL_MARGEM
      ,PERCENTUAL_REDUCAO_ST
      ,BASE_ST
      ,BASE_II
      ,ALIQUOTA_ST
      ,ALIQUOTA_CREDITO_SN
      ,VALOR_ST
      ,DECODE(COD_OPERACAO, 'ED', VALOR_COMERCIAL, VALOR_TOT_EMBALAGEM) AS VALOR_TOT_EMBALAGEM
      ,RETIDO
      ,ALIQUOTA_COFINS
      ,ALIQUOTA_PIS
      ,SIT_PIS_CONFINS
      ,VL_BASE_PIS
      ,VALOR_COFINS
      ,VL_BASE_CONFINS
      ,VALOR_PIS
      ,VALOR_II
      ,VALOR_DESPESA_ADUANEIRA
      ,VALOR_OUTROS
      ,VALOR_IOF
      ,CLASSIFICFISCAL
      ,TIPOESTOQUE
      ,COD_OPERACAO
      ,CODIGO_FABRICANTE
      ,CODIGO_FORNECEDOR
      ,PRINCIPIOATIVO
      ,CODST
      ,EMBALAGEM
      ,EMBALAGEMMASTER
      ,FANTASIA
      ,FORNECEDOR
      ,PESOEMBALAGEM
      ,FATORUNFARM
      ,PERCDESC
      ,PESOCX
      ,QTCX
      ,QTPECAS
      ,QTUN
      ,PTABELA
      ,PUNITCONT
      ,TIPO_QUANTIDADE
      ,QUANTIDADE_ENTREGA
      ,QTD_CAIXAS_MASTER
      ,QTD_PECAS_INTERM
      ,QTUNITCX
      ,TIPOTRIBUTMEDIC
      ,VLBASEGNRE
      ,STCLIENTEGNRE
      ,TOTPESOLIQUNIT
      ,UNIDADEMASTER
      ,NUMORIGINAL
      ,MARCA
      ,NUMVOLUMESCONFERENCIA
      ,PERACRESCIMOCUSTO
      ,TIPOSEPARACAO
      ,QTUNITEMB
      ,CODFILIALRETIRA
      ,UNIDADE_EMBALAGEM
      ,QTD_EMBALAGEM
      ,CODIGO_SECAO
      ,CODIGO_DEPARTAMENTO
      ,DESCRICAO_SECAO
      ,DESCRICAO_DEPARTAMENTO
      ,BASEBCR
      ,STBCR
      ,VOLUME
      ,QTD_CAIXA
      ,QTD_UNIDADE
      ,NUMERO_PEDIDO
      ,NUMERO_ITEM_PEDIDO
      ,QTUNIT
      --dados sobre veiculos
      ,TPOPERACAO
      ,CHASSIVEICULO
      ,CORVEICULO
      ,DESCCORVEICULO
      ,POTVEICULO
      ,CILINVEICULO
      ,PESOLVEICULO
      ,PESOBVEICULO
      ,SERIALVEICULO
      ,TPCOMBVEICULO
      ,NMOTORVEICULO
      ,CMTVEICULO
      ,DISTEIXOVEICULO
      ,ANOMODVEICULO
      ,ANOFABVEICULO
      ,TPPINTVEICULO
      ,TPVEICVEICULO
      ,ESPVEICVEICULO
      ,CONDVINVEICULO
      ,CONDVEICVEICULO
      ,MARCMODVEICULO
      ,CORDENATRANVEICULO
      ,LOTACAOVEICULO
      ,TPRESTVEICULO
      --fim dados sobre veiculos
      ,PRECO_MAX_CONSUMIDOR
      ,PRECO_FABRICA
      ,DESCONTO_FABRICA
      ,CODPRODCABCESTA
      ,PERCBONIFIC
      ,CODIGOANP
      ,NUMERO_FCI
      ,COD_AUXILIAR_EMBALAGEM
      ,NUMERO_DRAWBACK
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100) AND
                  (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARINFODIFERTOTICMSXML', CODFILIAL) = 'N')) THEN
        0
       ELSE
         VALORICMSDIF
       END VALORICMSDIF
      ,ALIQUOTAICMSDIF
      ,VLICMSDESONERACAO VALOR_ICMS_DESONERADO
      ,CODMOTIVOICMSDESONERADO COD_MOTIVO_DESONERACAO
      ,VALOR_IPI_OUTROS


      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100) AND
                  (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARINFODIFERTOTICMSXML', CODFILIAL) = 'N')) THEN
        0
      ELSE
        VALOR_ICMS
      END AS VALOR_ICMS_DEVIDO
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100) AND
                  (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARINFODIFERTOTICMSXML', CODFILIAL) = 'N')) THEN
        0
       ELSE
         VALOR_ICMS_OPERACAO
       END VALOR_ICMS_OPERACAO
      ,TIPO_PRESENCA_ADQUIRINTE
      ,CODCEST
      ,CODENQUADRAMENTOIPI
      ,CODOPERCFOP
      ,CASE WHEN QUANTIDADE_COMERCIAL <= 0 THEN
       0
      ELSE
        (BASE_ICMS / QUANTIDADE_COMERCIAL)
      END AS BASE_ICMS_UNITARIO
      ,ALIQFCPPART
      ,ALIQINTERNADEST
      ,ALIQINTERORIGPART
      ,VLFCPPART
      ,VLBASEPARTDEST
      ,PERCPROVPART
      ,VLICMSDIFALIQPART
      ,VLICMSPARTDEST
      ,VLICMSPARTREM
      ,VIASTRANSP
      ,VLAFRMM
      ,FINALIDADENFE
      ,PROD_ANVISA
      ,PROD_RASTREADO
      ,VLBASEFCPICMS
      ,VLBASEFCPST
      ,VLBCFCPSTRET
      ,PERFCPSTRET
      ,VLFCPSTRET
      ,PERFCPSN
      ,VLCREDFCPICMSSN
      ,VLFECP
      ,VLACRESCIMOFUNCEP
      ,PERACRESCIMOFUNCEP
      ,ALIQICMSFECP
      ,COD_BENEFICIO_FISCAL
      ,IND_ESCALA_RELEVANTE
      ,COD_AGREGACAO
      ,CNPJ_FABRICANTE
      ,DESC_ANP
      ,ISENTO_ICMS_UF_DEST
      ,MIUDEZA
      ,PERCENTUAL_GLP
      ,PERC_GAS_NATURAL_NACIONAL
      ,PERC_GAS_NATURAL_IMPORTADO
      ,VALOR_PARTIDA
      ,COD_PRIORIDADE_IMPRESSAO
      ,NUMNOTA
      ,PERCREDBASEEFET
      ,VLBASEEFET
      ,PERCICMSEFET
      ,VLICMSEFET
      ,PERCSTRET
      ,MOTIVO_ISENCAO_ANVISA
      ,VLICMSBCR
      --PCEST TEMPORARIO
      ,BASEBCR_PCEST
      ,PERCSTRET_PCEST
      ,VLICMSBCR_PCEST
      ,STBCR_PCEST
      ,VLBCFCPSTRET_PCEST
      ,PERFCPSTRET_PCEST
      ,VLFCPSTRET_PCEST
      ,VLAPROXTRIB
      ,MOTREDADREM
      ,ADREMICMS
      ,ADREMICMSRETEN
      ,PREDADREM
      ,ADREMICMSDIF
      ,ADREMICMSRET
      ,QBCMONO
      ,VICMSMONO
      ,QBCMONORETEN
      ,VICMSMONORETEN
      ,QBCMONODIF
      ,VICMSMONODIF
      ,QBCMONORET
      ,VICMSMONORET      
      ,OBSCONTXCAMPO
      ,OBSCONTXTEXTO
      ,OBSFISCOXCAMPO
      ,OBSFISCOXTEXTO
FROM   (
SELECT PCMOV.NUMTRANSENT AS NUM_TRANSACAO
              ,PCMOV.NUMSEQ
              ,PCMOV.CODPROD
              ,PCMOVCOMPLE.NUMCHAVEEXP AS NUM_CHAVE_EXPORTACAO
              ,PCMOVCOMPLE.NUMREGEXP AS NUM_REGISTRO_EXPORTACAO
              ,NVL(TRIM(PCMOV.CODINTERNO), TO_CHAR(PCMOV.CODPROD)) AS CODIGO_PRODUTO
              /*,CASE WHEN LENGTH(NVL(PCPRODUT.CODAUXILIAR, '')) IN (NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      TO_CHAR(PCPRODUT.CODAUXILIAR)
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR) < NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
               ELSE
                  NULL
               END AS EAN*/
              ,CASE WHEN (LENGTH(PCPRODUT.CODAUXILIAR) <= NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR2) <= NVL(PCPRODUT.GTINCODAUXILIAR2,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR2), PCPRODUT.GTINCODAUXILIAR2,'0')
               ELSE
                  NULL
               END AS EAN
              ,PCMOV.DV AS DIGITO_PRODUTO
              ,(NVL(PCMOV.PRODDESCRICAOCONTRATO,
                    NVL(PCMOV.DESCRICAO, PCMOV.COMPLEMENTO)) || ' ' ||
               DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE,
                           'N'),
                       'S',
                       DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM,
                                  'N'),
                              'N',
                              PCMOV.EMBALAGEM,
                              ('QTD. ' ||
                              LTRIM(to_char((PCMOV.QTCONT /
                                      DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                                   0),
                                               0,
                                               1,
                                               PCEMBALAGEM.QTUNIT)),'999999999999999990.99')) || ' ' ||
                              PCEMBALAGEM.UNIDADE || '')))) AS PRODUTO
              ,NVL(PCPRODUT.NATUREZAPRODUTO,
                   'X') AS NATUREZAPRODUTO
              ,TRIM(NVL(PCPRODFILIAL.INFTECNICA, '') || ' ' ||
                   CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIAINFOLOTENFE', PCMOV.CODFILIAL), 'S') = 'S') THEN
                       (DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                               '')),
                                    0),
                                0,
                                '',
                                ' N. LT. ')) || PCMOV.NUMLOTE || ' ' ||
                        DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                               '')),
                                    0),
                                0,
                                '',
                                ' DATA FAB.: ') ||
                       (SELECT TO_CHAR(PCLOTE.DATAFABRICACAO, 'DD/MM/YYYY')
                        FROM   PCLOTE
                        WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                        AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                        AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                        AND    ROWNUM = 1) || ' ' ||
                        DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                                   '')),
                                        0),
                                    0,
                                    '',
                                    ' DATA VAL.: ') || (SELECT TO_CHAR(PCLOTE.DTVALIDADE,'DD/MM/YYYY')
                        FROM   PCLOTE
                        WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                        AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                        AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                        AND    ROWNUM = 1)
                    ELSE
                       ''
                    END || ' ' ||
                    DECODE(NVL(PCPRODUT.ENVIAINFTECNICANFE, 'S'), 'S', PCPRODUT.INFORMACOESTECNICAS, NULL) ||
                    (SELECT ' - ' || PCCERTIFIC.MENSAGEMNF
                     FROM   PCCERTIFIC
                     WHERE  PCCERTIFIC.CODCERTIFIC = PCMOV.CODCERTIFIC
                     AND    ROWNUM = 1
                     --esta clausula serve para pegar sempre o certificado mais atual
                     AND TRUNC(PCCERTIFIC.DTVENC) = (SELECT TRUNC(MAX(F1.DTVENC)) FROM PCCERTIFIC F1 WHERE F1.CODCERTIFIC = PCCERTIFIC.CODCERTIFIC)
                     )
                     || ' ' ||
                      DECODE(NVL(LENGTH(NVL(PCMOV.REFCOR,'')),0),0,'','REF.DA COR: ' || PCMOV.REFCOR)
                     || ' ' ||
                      CASE WHEN (PCPRODUT.OBS = 'EQ' AND PCEQUIPAMENTO.IDPATRIMONIO IS NOT NULL) THEN
                      DECODE(PCMOV.CODOPER, 'SO', 'ID.EQUIP.:'|| PCEQUIPAMENTO.IDPATRIMONIO
                      || ' ' || 'COD.EQUIP.: ' || PCEQUIPAMENTO.CODEQUIPAMENTO
                      || ' ' || 'MARCA EQUIP.: ' || PCEQUIPAMENTO.MARCA
                      || ' ' || 'VOLT.EQUIP.: ' || PCEQUIPAMENTO.VOLTAGEM
                      )
                      ELSE '' END
                      ||
                      CASE WHEN (NVL(PCMOVCOMPLE.ENVIARALIQREDUCAOPISCOFINS,'N') = 'S') THEN
                           ';%Red.Aliq.PIS ' || LTRIM(to_char(NVL(PCMOVCOMPLE.ALIQREDUCAOPIS,0),'999999999999999990.99')) ||
                           ';%Red.Aliq.COFINS ' || LTRIM(to_char(NVL(PCMOVCOMPLE.ALIQREDUCAOCOFINS,0),'999999999999999990.99'))
                      END || ' ' ||
                      CASE WHEN NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0) > 0 THEN
                            ' VBCFCP: ' || TRIM(TO_CHAR( CASE WHEN (NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0) > 0) THEN
                                                          ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0),2)
                                                        ELSE
                                                          ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)),2)
                                                        END,'999999999999999990.99')) ||
                            ' PFCP: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.PERACRESCIMOFUNCEP, 0),'999999999999999990.99')) ||
                            ' VFCP: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0),2),'999999999999999990.99'))
                       END ||
                       CASE WHEN NVL(PCMOVCOMPLE.VLFECP, 0) > 0 THEN
                            ' VBCFCPST: ' || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPST, 0),2),'999999999999999990.99')) ||
                            ' PFCPST: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.ALIQICMSFECP, 0),'999999999999999990.99')) ||
                            ' VFCPST: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFECP, 0),2),'999999999999999990.99'))
                       END ||
                       CASE WHEN ((NVL(PCMOV.SITTRIBUT, '55') = '61') AND 
                                  (NVL(PCMOVCOMPLE.VICMSMONORET, 0) > 0)) THEN
                            ' ICMS monofásico sobre combustíveis cobrado anteriormente conforme Convênio ICMS 199/2022.'
                       END
                     ) AS INFO_TECNICA
              ,REPLACE(PCMOV.NBM, '.', '') AS NCM
              ,CASE
                  WHEN (PCMOVCOMPLE.EXTIPI BETWEEN 1 AND 9) THEN
                      LPAD(TO_CHAR(PCMOVCOMPLE.EXTIPI), 2,'0')
                ELSE
              CASE
                  WHEN (NVL(PCMOVCOMPLE.EXTIPI,0) = 0) THEN
               NULL
              END
              END AS EXTIPI
              ,(SUBSTR(PCMOV.NBM,
                       1,
                       2)) AS GENERO
              ,PCMOV.CODFISCAL AS CFOP
              ,PCMOV.UNIDADE AS UNIDADE_COMERCIAL

              ,ROUND(PCMOV.QTCONT, 4) QUANTIDADE_COMERCIAL
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                          (PCNFENT.TIPODESCARGA = 'F') THEN
                         --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                           NVL(PCMOV.PTABELA, 0)    --Pre?o de Tabela
                           - DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DEDUCOES', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESCONTO, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_FRETE', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLFRETE, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SEGURO', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSEGURO, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CAPATAZIA', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLCAPATAZIA, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ACRESCIMOS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESPDENTRONF, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIMPORTACAO, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_IPI', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIPI, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDPIS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0),  0, NVL(PCMOV.VLCREDPIS, 0),  NVL(PCMOVCOMPLE.VLPISCALCDI, 0)), 0) --Vl PIS
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDCOFINS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)), 0) --Vl Cofins
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ST', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.ST, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLICMS, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_AFRMM', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLAFRMM, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SISCOMEX', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSISCOMEX, 0), 0)
                    --       + NVL(PCMOV.VLOUTRASDESPIMP, 0) -- vl Outras despesa importa??o
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DESPADUAN', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLADUANEIRA, 0), 0)
               ELSE
                 CASE WHEN (PCNFENT.TIPODESCARGA = 'F') THEN
                             --FORMA QUE ESTAVA ANTERIORMENTE
                             (DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT) - NVL(PCMOV.VLREPASSE,0) - DECODE(PCNFENT.TIPODESCARGA, 'F', NVL(PCMOV.VLFRETE,
                                          0), 0) +
                               DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                         PCFILIAL.CODIGO), 'L'),
                                       'L',
                                       0,
                                       'LR',
                                       NVL(PCMOV.VLREPASSE,0),
                                       NVL(PCMOV.VLREPASSE,0) +
                                       DECODE(NVL(PCMOV.PTABELA,
                                                  0),
                                              0,
                                              0,
                                              DECODE(SIGN(NVL(PCMOV.PTABELA,
                                                              0) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)),
                                                     -1,
                                                     0,
                                                     NVL(PCMOV.PTABELA,
                                                         0) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)
                                                                  ))) -
                               NVL(PCMOV.VLOUTRASDESP,
                                    0) - NVL(PCMOV.ST,
                                              0) - NVL(PCMOV.VLIPI,
                                                        0) -
                               DECODE(PCNFENT.TIPODESCARGA,
                                       'F',
                                       NVL(PCMOV.VLADUANEIRA,0) + NVL(PCMOV.VLSISCOMEX,0) + NVL(PCMOV.VLIMPORTACAO,0) +
                                       NVL(PCMOV.VLOUTRASDESPIMP,0) +
                                       DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                                       DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)) +
                                       DECODE(NVL(PCMOVCOMPLE.DEDUZIRICMSIMPORTACAO, 'S'),
                                              'S',
                                              NVL(PCMOVCOMPLE.VLICMS, NVL(PCMOV.VLCREDICMS, 0)),
                                              0) + NVL(PCMOVCOMPLE.VLANTIDUMPING, 0) +  NVL(PCMOVCOMPLE.VLAFRMM, 0),
                                       0) +
                               DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                         PCFILIAL.CODIGO), 'N')),
                                       'N',
                                       0,
                                       (NVL(PCMOV.VLIMPORTACAO,0) + NVL(PCMOV.VLFRETE,0) + NVL(PCMOV.VLOUTRASDESP,0))))
                 ELSE
                   NVL(PCMOV.PUNITCONT, 0)
                 END
               END AS VALOR_COMERCIAL
              ,PCMOV.PUNITCONT - NVL(PCMOV.VLDESCONTO,
                                     0) AS VALOR_LIQUIDO
              /*,CASE WHEN LENGTH(NVL(PCPRODUT.CODAUXILIARTRIB, '')) IN (NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                      TO_CHAR(PCPRODUT.CODAUXILIARTRIB)
                    WHEN (LENGTH(PCPRODUT.CODAUXILIARTRIB) < NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIARTRIB), PCPRODUT.GTINCODAUXILIARTRIB,'0')
                    WHEN LENGTH(NVL(PCPRODUT.CODAUXILIAR2, '')) IN (NVL(PCPRODUT.GTINCODAUXILIAR2,0)) THEN
                      TO_CHAR(PCPRODUT.CODAUXILIAR2)
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR2) < NVL(PCPRODUT.GTINCODAUXILIAR2,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR2), PCPRODUT.GTINCODAUXILIAR2,'0')
               ELSE
                      NULL
               END AS EAN_UNIDADE*/
              ,CASE WHEN (LENGTH(PCPRODUT.CODAUXILIARTRIB) <= NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIARTRIB), PCPRODUT.GTINCODAUXILIARTRIB,'0')
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR) <= NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
               ELSE
                  NULL
               END AS EAN_UNIDADE
              ,PCMOVCOMPLE.UNIDADETRIB AS UNIDADE_TRIBUTAVEL
              ,CASE WHEN (NVL(PCNFENT.FINALIDADENFE,'O') = 'C') THEN
                    0
               ELSE
                    ROUND(PCMOV.QTCONT, 4)
              END AS QUANTIDADE_TRIBUTAVEL
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                               (PCNFENT.TIPODESCARGA = 'F') THEN
                             --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                             NVL(PCMOV.PTABELA, 0)    --Pre?o de Tabela
                             - DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DEDUCOES', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESCONTO, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_FRETE', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLFRETE, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SEGURO', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSEGURO, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CAPATAZIA', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLCAPATAZIA, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ACRESCIMOS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESPDENTRONF, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIMPORTACAO, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_IPI', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIPI, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDPIS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0),  0, NVL(PCMOV.VLCREDPIS, 0),  NVL(PCMOVCOMPLE.VLPISCALCDI, 0)), 0) --Vl PIS
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDCOFINS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)), 0) --Vl Cofins
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ST', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.ST, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLICMS, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_AFRMM', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLAFRMM, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SISCOMEX', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSISCOMEX, 0), 0)
                             --  + NVL(PCMOV.VLOUTRASDESPIMP, 0) -- vl Outras despesa importa??o
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DESPADUAN', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLADUANEIRA, 0), 0)
               ELSE
                 CASE WHEN (PCNFENT.TIPODESCARGA = 'F') THEN
                              (DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT) -
                                      NVL(PCMOV.VLREPASSE,0) - DECODE(PCNFENT.TIPODESCARGA, 'F', NVL(PCMOV.VLFRETE,
                                                      0), 0)  +
                                       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                 PCFILIAL.CODIGO),
                                                   'L'),
                                               'L',
                                               0,
                                                                      'LR',
                                               NVL(PCMOV.VLREPASSE,0),
                                               NVL(PCMOV.VLREPASSE,0) +
                                               DECODE(NVL(PCMOV.PTABELA,
                                                          0),
                                                      0,
                                                      0,
                                                      DECODE(SIGN(NVL(PCMOV.PTABELA,
                                                                      0) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)),
                                                             -1,
                                                             0,
                                                             NVL(PCMOV.PTABELA,
                                                                 0) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)
                                                                 ))) -
                                       NVL(PCMOV.VLOUTRASDESP,
                                            0) - NVL(PCMOV.ST,
                                                      0) - NVL(PCMOV.VLIPI,
                                                                0) -
                                       DECODE(PCNFENT.TIPODESCARGA,
                                               'F',
                                               NVL(PCMOV.VLADUANEIRA,
                                                   0) + NVL(PCMOV.VLSISCOMEX,
                                                            0) + NVL(PCMOV.VLIMPORTACAO,
                                                                     0) +
                                               NVL(PCMOV.VLOUTRASDESPIMP,0) +
                                               DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                                               DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)) +
                                               DECODE(NVL(PCMOVCOMPLE.DEDUZIRICMSIMPORTACAO, 'S'),
                                                      'S',
                                                      NVL(PCMOVCOMPLE.VLICMS, NVL(PCMOV.VLCREDICMS, 0)),
                                                      0) + NVL(PCMOVCOMPLE.VLANTIDUMPING, 0) +  NVL(PCMOVCOMPLE.VLAFRMM, 0),
                                               0) +
                                       DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                                 PCFILIAL.CODIGO),
                                                   'N')),
                                               'N',
                                               0,
                                               (NVL(PCMOV.VLIMPORTACAO,
                                                    0) + NVL(PCMOV.VLFRETE,
                                                              0) + NVL(PCMOV.VLOUTRASDESP,
                                                                        0))))
                 ELSE
                   NVL(PCMOV.PUNITCONT, 0)
                 END
               END AS VALOR_TRIBUTAVEL
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                         --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                         ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_FRETE', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLFRETE, 0), 0) *
                                      NVL(PCMOV.QTCONT, 0), 2)
                    ELSE
                         --FORMA ANTIGA
                         DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                NVL(PCNFENT.CODFILIALNF,
                                                                    PCNFENT.CODFILIAL)),
                                  'N')),
                              'S',
                              0,
                              ROUND(NVL(PCMOV.VLFRETE,
                                        0) * NVL(PCMOV.QTCONT,
                                                 0),
                                    2))
               END AS VALOR_FRETE
               ,0 AS VALOR_SEGURO
               ,CASE WHEN (PCNFENT.TIPODESCARGA = 'F') THEN
                  ROUND(DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',PCFILIAL.CODIGO),'L')),
                                          'L',
                                               0,
                                          'LR',
                                               0,
                                          NVL(DECODE(NVL(PCMOV.PTABELA,0),
                                                 0,
                                                    0,
                                                 DECODE(SIGN(NVL(PCMOV.PTABELA,0) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)),
                                                        -1,
                                                          0,
                                                        NVL(PCMOV.PTABELA, 0) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT))), PCMOV.VLDESCONTO)) * PCMOV.QTCONT, 2)
                ELSE
                  ROUND((NVL(PCMOV.VLDESCONTO, 0) + DECODE(NVL(PCNFENT.TIPODESCARGA, ''), 'R', NVL(PCMOV.VLSUFRAMA, 0), 0)) * PCMOV.QTCONT,2)
                END AS VALOR_DESCONTO
              ,(NVL(PCMOV.PESOBRUTO,
                    0) * PCMOV.QTCONT) AS PESO_BRUTO
              ,NVL(PCMOV.PERCIPI,
                   0) AS PERCIPIVENDA
              ,NVL(PCMOV.VLIPIPORKG,
                   0) AS VLIPIPORKGVENDA
              ,PCMOV.TIPOMERC
              ,PCNFENT.NUMDIIMPORTACAO AS NUM_DOC_IMPORTACAO
              ,PCNFENT.LOCALDESEMBARACO AS LOCAL_DESEMBARACO
              ,PCNFENT.UFDESEMBARACO AS SIGLA_UF_DESEMBARACO
              ,PCNFENT.DATADIIMPORTACAO AS DATA_DESEMBARACO
              ,PCNFENT.CODEXPORTADOR AS CODIGO_EXPORTADOR
              ,NVL(PCMOV.NUMADICAO, PCMOV.NUMSEQ) AS NUMERO_ADICAO
              ,NVL(PCMOV.NUMSEQADICAO, PCMOV.NUMSEQ) AS NUMERO_SEQUENCIA
              ,PCNFENT.CODFORNEC AS CODIGO_FABRICANTE_EX
              ,0 AS VALOR_DESCONTO_ADICAO
              ,PCMOV.NUMLOTE AS NUMERO_LOTE
              ,PCMOV.QTCONT AS QT_LOTE
              ,(SELECT PCLOTE.DATAFABRICACAO
                FROM   PCLOTE
                WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                AND    ROWNUM = 1) AS DATA_FABRICACAO
              ,(SELECT PCLOTE.DTVALIDADE
                FROM   PCLOTE
                WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                AND    ROWNUM = 1) AS DATA_VALIDADE
              ,NVL(PCMOVCOMPLE.PRECOMAXCONSUM,
               DECODE(NVL(PCTABPR.PRECOMAXCONSUM,
                          0),
                      0,
                      NVL(PCPRODUT.PRECOMAXCONSUM,
                          0),
                      NVL(PCTABPR.PRECOMAXCONSUM,
                          0))) PRECO_MAXIMO
              ,NVL(LTRIM(TRANSLATE(NVL(PCMOVCOMPLE.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), NVL(TRANSLATE(NVL(PCMOVCOMPLE.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), '1234567890', ' '),'X'), ' ')),
                    DECODE(NVL(PCMOV.IMPORTADO, 'N'),
                        'S',
                            2,
                        'D',
                            1,
                            0
               )) AS  ORIGEM_MERCADORIA
              ,NVL(PCMOV.SITTRIBUT, 55) AS SITUACAO_TRIBUTARIA
              ,'3' AS MODALIDADE_BC_ICMS
              ,ROUND((NVL(PCMOV.BASEICMS, 0) * PCMOV.QTCONT),2) BASE_ICMS
              ,NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) AS ALIQUOTA_ICMS
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', PCFILIAL.CODIGO),'N') = 'N' THEN
                         ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                               (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2)
                          -
                         ROUND(ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                               (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                               (NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) / 100), 2)
                    ELSE
                         0
                    END
               ELSE
                    ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                          (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2)
                     -
                     ROUND(ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                           (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                           (NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) / 100), 2)
               END AS VALOR_ICMS
              ,ROUND((ROUND((NVL(PCMOV.BASEICMS, 0) * PCMOV.QTCONT), 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100)), 2) AS VALOR_ICMS_OPERACAO
              ,ROUND(NVL(PCMOVCOMPLE.PERCICMSSIMPLESNAC,0),2) ALIQUOTA_CREDITO_SN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLRICMSSIMPLESNAC,0),2) VALOR_CREDITO_ICMS_SN
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLADUANEIRA,0), 0) * PCMOV.QTCONT, 2)
               ELSE
                    --C?LCULO ANTIGO
                    ROUND(NVL(PCMOV.VLADUANEIRA, 0) * PCMOV.QTCONT, 2)
               END AS BASE_II
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                   --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                   ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DESPADUAN', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLADUANEIRA, 0), 0) * PCMOV.QTCONT, 2)
               ELSE
                   --C?LCULO ANTIGO
                   ROUND(NVL(PCMOV.VLADUANEIRA, 0) * PCMOV.QTCONT, 2)
               END AS VALOR_DESPESA_ADUANEIRA
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLIMPORTACAO,0), 0) * PCMOV.QTCONT, 2)
               ELSE
                    --C?LCULO ANTIGO
                    DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT', PCFILIAL.CODIGO), 'N')),
                          'N',
                           ROUND(NVL(PCMOV.VLIMPORTACAO,0) * PCMOV.QTCONT, 2),
                           0)
               END AS VALOR_II
              ,0 AS VALOR_IOF
              ,NVL(PCMOVCOMPLE.CODSITTRIBIPI,DECODE(NVL(DECODE(NVL(PCMOV.CALCCREDIPI,
                                     'N'),
                                 'S',
                                 'S',
                                 DECODE(NVL(PCCONSUM.USATRIBUTACAOPORUF,
                                            'N'),
                                        'N',
                                        NVL(PCMOV.CALCCREDIPI,
                                            'N'),
                                        (SELECT NVL(PCTABTRIBENT.CALCCREDIPI,
                                                    'N')
                                         FROM   PCTABTRIBENT
                                         WHERE  PCTABTRIBENT.CODPROD =
                                                PCMOV.CODPROD
                                         AND    ROWNUM = 1))),
                          'N'),
                      'S',
                      00,
                      49)) SITUACAO_TRIBUTARIA_IPI
              ,ROUND((NVL(PCMOV.VLBASEIPI, 0) * PCMOV.QTCONT),2) AS BASE_IPI
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND((DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_IPI', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLIPI, 0), 0) *
                           PCMOV.QTCONT),2)
               ELSE
                    --C?LCULO ANTIGO
                    ROUND((NVL(PCMOV.VLIPI, 0) * PCMOV.QTCONT),2)
               END AS VALOR_IPI
              ,NVL(PCMOV.VLIPI, 0) AS VALOR_IPI_UNIDADE
              ,NVL(PCMOV.PERCIPI, 0) AS ALIQUOTA_IPI
              ,NVL((100 - PCMOV.PERCBASERED), 0) AS PERCENTUAL_REDUCAO_BC
              ,DECODE(NVL(PCCONSUM.UTILIZACONTROLELOTE,
                          'N'),
                      'N',
                      DECODE(NVL(PCMOV.PAUTA,
                                 0),
                             0,
                             4,
                             5),
                      DECODE(NVL(PCMOV.TIPOTRIBUTMEDIC,
                                 'OM'),
                             'PO',
                             2,
                             'NG',
                             1,
                             'NT',
                             3,
                             CASE WHEN (ROUND(NVL(PCMOV.PAUTA, 0) * (DECODE(NVL(PCMOV.PERCBASEREDST,0), 0, 1, PCMOV.PERCBASEREDST/100)), 6) = PCMOV.BASEICST) THEN
                                   5
                                ELSE
                                   4
                                END)) AS MODALIDADE_BC_ST
              ,ROUND(DECODE(NVL(PCMOV.IVA, 0), 0, NVL(PCMOV.PERCIVA, 0), PCMOV.IVA), 2) AS PERCENTUAL_MARGEM
              ,ROUND(DECODE(NVL(PCMOV.CODOPER, 'E'), 'ED', 100 - NVL(PCMOV.PERCBASEREDST, 0), NVL(PCMOV.PERCBASEREDST, 0)), 2) AS PERCENTUAL_REDUCAO_ST
              ,ROUND(NVL(PCMOV.BASEICST, 0) * PCMOV.QTCONT, 2) AS BASE_ST
              ,NVL(PCMOV.ALIQICMS1, 0) AS ALIQUOTA_ST
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ST', PCFILIAL.CODIGO),'N'), 'N', 0, NVL(PCMOV.ST, 0)) *
                          PCMOV.QTCONT, 2)
               ELSE
                    ROUND(NVL(PCMOV.ST, 0) * PCMOV.QTCONT, 2)
               END AS VALOR_ST
              ,0 AS VALOR_TOT_EMBALAGEM
              ,NVL(PCMOV.PISCOFINSRETIDO, 'I') AS RETIDO
              ,(CASE
                 WHEN (NVL(PCMOV.VLDESCPISSUFRAMA,
                           0) > 0)
                      OR (NVL(PCFILIAL.OPTANTESIMPLESNAC,
                              'N') = 'S') THEN
                  0
                 ELSE
                   CASE WHEN (PCMOVCOMPLE.PERCOFINSCALCDI > 0) THEN
                     NVL(PCMOVCOMPLE.PERCOFINSCALCDI, 0)
                   ELSE
                     NVL(NVL(PCMOV.PERCOFINS, PCPRODUT.PERCOFINSIMP), 0)
                   END
               END) AS ALIQUOTA_COFINS
              ,(CASE
                 WHEN (NVL(PCMOV.VLDESCPISSUFRAMA,
                           0) > 0)
                      OR (NVL(PCFILIAL.OPTANTESIMPLESNAC,
                              'N') = 'S') THEN
                  0
                 ELSE
                  CASE WHEN (PCMOVCOMPLE.PERPISCALCDI > 0) THEN
                    NVL(PCMOVCOMPLE.PERPISCALCDI, 0)
                  ELSE
                    NVL(NVL(PCMOV.PERPIS,PCPRODUT.PERPISIMP), 0)
                  END
               END) AS ALIQUOTA_PIS
              ,NVL(PCMOV.CODSITTRIBPISCOFINS,0) AS SIT_PIS_CONFINS
              ,ROUND(NVL(PCMOV.VLBASEPISCOFINS,
                         0) * PCMOV.QTCONT,
                     2) AS VL_BASE_PIS
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    CASE WHEN (PCMOVCOMPLE.VLCOFINSCALCDI > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.COFINSRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.COFINSRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) *
                               DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDCOFINS', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLCREDCOFINS, 0), 0), 2)
                    END
               ELSE
                    --C?LCULO ANTIGO
                    CASE WHEN (PCMOVCOMPLE.VLCOFINSCALCDI > 0) AND (PCNFENT.TIPODESCARGA = 'F') THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.COFINSRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.COFINSRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOV.VLCREDCOFINS, 0), 2)
                    END
               END AS VALOR_COFINS
              ,ROUND(NVL(PCMOV.VLBASEPISCOFINS,
                         0) * PCMOV.QTCONT,
                     2) AS VL_BASE_CONFINS
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'F') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    CASE WHEN (PCMOVCOMPLE.VLPISCALCDI > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.PISRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.PISRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) *
                               DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDPIS', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLCREDPIS, 0), 0), 2)
                    END
               ELSE
                    --C?LCULO ANTIGO
                    CASE WHEN (PCMOVCOMPLE.VLPISCALCDI > 0) AND (PCNFENT.TIPODESCARGA = 'F') THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.PISRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.PISRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOV.VLCREDPIS, 0), 2)
                    END
               END AS VALOR_PIS
              ,PCMOV.CLASSIFICFISCAL AS CLASSIFICFISCAL
              ,NVL(PCPRODUT.TIPOESTOQUE,
                   'PA') AS TIPOESTOQUE
              ,PCMOV.CODOPER AS COD_OPERACAO
              ,PCPRODUT.CODFAB AS CODIGO_FABRICANTE
              ,PCMOV.CODFORNEC AS CODIGO_FORNECEDOR
              ,(SELECT PCPRINCIPATIVO.DESCRICAO
                FROM   PCPRINCIPATIVO
                WHERE  PCPRINCIPATIVO.CODPRINCIPATIVO =
                       PCPRODUT.CODPRINCIPATIVO
                AND    ROWNUM = 1) AS PRINCIPIOATIVO
              ,PCMOV.CODST AS CODST
              ,NVL(PCEMBALAGEM.EMBALAGEM,
                   PCMOV.EMBALAGEM) AS EMBALAGEM
              ,PCPRODUT.EMBALAGEMMASTER
              ,PCFORNEC.FANTASIA
              ,PCFORNEC.FORNECEDOR
              ,PCPRODUT.PESOEMBALAGEM
              ,PCPRODUT.FATORUNFARM
              ,PCMOV.PERCDESC
              ,0 PESOCX
              ,DECODE(NVL(PCMOV.QTCX,
                          0),
                      0,
                      PCMOV.QTCONT,
                      PCMOV.QTCX) QTCX
              ,NVL(PCMOV.QTPECAS,
                   0) QTPECAS
              ,NVL(PCMOVCOMPLE.QTUN,
                   0) QTUN
              ,NVL(PCMOV.PTABELA,
                   0) PTABELA
              ,NVL(PCMOV.PUNITCONT,
                   0) PUNITCONT
              ,CASE
                 WHEN NVL(PCMOV.QTCX,
                          0) > 0 THEN
                  'CX'
                 WHEN NVL(PCMOV.QTPECAS,
                          0) > 0 THEN
                  'PC'
                 ELSE
                  'UN'
               END AS TIPO_QUANTIDADE
              ,CASE
                 WHEN NVL(PCMOV.QTCX,
                          0) > 0 THEN
                  NVL(PCMOV.QTCX,
                      0)
                 WHEN NVL(PCMOV.QTPECAS,
                          0) > 0 THEN
                  NVL(PCMOV.QTPECAS,
                      0)
                 ELSE
                  NVL(PCMOV.QTCONT,
                      0)
               END AS QUANTIDADE_ENTREGA
              ,TRUNC(PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                               1),
                                           0,
                                           1,
                                           NVL(PCPRODUT.PESOBRUTOMASTER,
                                               1))) AS QTD_CAIXAS_MASTER
              ,CASE
                 WHEN TRUNC(PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                                      1),
                                                  0,
                                                  1,
                                                  NVL(PCPRODUT.PESOBRUTOMASTER,
                                                      1))) > 0 THEN
                  (PCMOV.QTCONT -
                  (TRUNC(PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                                    1),
                                                0,
                                                1,
                                                NVL(PCPRODUT.PESOBRUTOMASTER,
                                                    1))) *
                  NVL(PCPRODUT.PESOBRUTOMASTER,
                        1)))
                 ELSE
                  PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOPECA,
                                            1),
                                        0,
                                        1,
                                        NVL(PCPRODUT.PESOPECA,
                                            1))
               END AS QTD_PECAS_INTERM
              ,NVL(PCMOV.QTUNITCX,
                   0) QTUNITCX
              ,NVL(PCPRODUT.TIPOTRIBUTMEDIC,
                   'X') TIPOTRIBUTMEDIC
              ,(NVL(PCMOV.VLBASEGNRE,
                    0) * NVL(PCMOV.QTCONT,
                              0)) VLBASEGNRE
              ,(NVL(PCMOV.STCLIENTEGNRE,
                    0) * NVL(PCMOV.QTCONT,
                              0)) STCLIENTEGNRE
              ,PCMOV.QTCONT * NVL(PCMOV.PESOLIQ,
                                  0) TOTPESOLIQUNIT
              ,PCPRODUT.UNIDADEMASTER
              ,PCPRODUT.NUMORIGINAL
              ,PCMARCA.MARCA
              ,PCMOV.NUMVOLUMESCONFERENCIA
              ,PCMOV.PERACRESCIMOCUSTO
              ,PCMOV.TIPOSEPARACAO
              ,PCMOV.QTUNITEMB
              ,PCMOV.CODFILIALRETIRA
              ,PCEMBALAGEM.UNIDADE AS UNIDADE_EMBALAGEM
              ,(PCMOV.QTCONT / DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                      0),
                                  0,
                                  1,
                                  PCEMBALAGEM.QTUNIT)) AS QTD_EMBALAGEM
              ,PCMOV.CODSEC AS CODIGO_SECAO
              ,PCMOV.CODEPTO AS CODIGO_DEPARTAMENTO
              ,PCSECAO.DESCRICAO AS DESCRICAO_SECAO
              ,PCDEPTO.DESCRICAO AS DESCRICAO_DEPARTAMENTO
              ,(NVL(PCMOV.BASEBCR,
                    0) * PCMOV.QTCONT) AS BASEBCR
              ,(NVL(PCMOV.STBCR,
                    0) * PCMOV.QTCONT) AS STBCR
              ,NVL(PCPRODUT.VOLUME,
                   0) AS VOLUME
              ,CASE
                 WHEN ((NVL(PCMOV.QTUNITCX,
                            NVL(PCMOV.QTUNITCX,
                                1)) > 0) AND
                      (PCMOV.QTCONT >= NVL(PCMOV.QTUNITCX,
                                        NVL(PCMOV.QTUNITCX,
                                            1)))) THEN
                  TRUNC(PCMOV.QTCONT / NVL(PCMOV.QTUNITCX,
                                       NVL(PCMOV.QTUNITCX,
                                           1)))
                 ELSE
                  0
               END QTD_CAIXA
              ,CASE
                 WHEN ((NVL(PCMOV.QTUNITCX,
                            NVL(PCMOV.QTUNITCX,
                                1)) > 0) AND
                      (PCMOV.QTCONT >= NVL(PCMOV.QTUNITCX,
                                        NVL(PCMOV.QTUNITCX,
                                            1)))) THEN
                  PCMOV.QTCONT - (TRUNC(PCMOV.QTCONT / NVL(PCMOV.QTUNITCX,
                                                   NVL(PCMOV.QTUNITCX,
                                                       1))) *
                  NVL(PCMOV.QTUNITCX,
                                  NVL(PCMOV.QTUNITCX,
                                      1)))
                 ELSE
                  PCMOV.QTCONT
               END QTD_UNIDADE
              ,NVL(PCMOV.NUMPED,
                   0) AS NUMERO_PEDIDO
              ,NVL(PCMOV.NUMSEQ,
                   1) AS NUMERO_ITEM_PEDIDO
              ,NVL(PCMOV.QTUNIT,
                   0) AS QTUNIT
              ,ROUND(DECODE(PCNFENT.TIPODESCARGA,'F',NVL(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SOMARVLOUTRASDESPADUANEIRAS',
                                                                  NVL(PCMOV.CODFILIALNF,
                                                                      PCMOV.CODFILIAL)),
                                    'N'),
                                'S',
                                NVL(PCMOV.VLADUANEIRA,
                                     0) + NVL(PCMOV.VLSISCOMEX,
                                               0) + NVL(PCMOV.VLOUTRASDESPIMP,
                                                         0)+
                                DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                  NVL(PCMOV.CODFILIALNF,
                                                                      PCMOV.CODFILIAL)),
                                    'N')),
                                'S',
                                     0,
                                     NVL(PCMOV.VLOUTRASDESP,0)
                                     ),0) +
                                     NVL(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SOMARPISCOFINSVLOUTRASDESPIMP',
                                                                  NVL(PCMOV.CODFILIALNF,
                                                                      PCMOV.CODFILIAL)),
                                    'S'),
                                'S',
                                    DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                                    DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0))),0) +
                                    NVL(PCMOVCOMPLE.VLANTIDUMPING, 0) +  NVL(PCMOVCOMPLE.VLAFRMM, 0),
                         0),DECODE(PCMOV.CODOPER, 'ED', PCMOV.VLOUTROS, PCMOV.VLOUTRASDESP)) * PCMOV.QTCONT,2) AS VALOR_OUTROS
               --dados veiculos
              ,NULL AS TPOPERACAO
              ,NULL AS CHASSIVEICULO
              ,NULL AS CORVEICULO
              ,NULL AS DESCCORVEICULO
              ,NULL AS POTVEICULO
              ,NULL AS CILINVEICULO
              ,NULL AS PESOLVEICULO
              ,NULL AS PESOBVEICULO
              ,NULL AS SERIALVEICULO
              ,NULL AS TPCOMBVEICULO
              ,NULL AS NMOTORVEICULO
              ,NULL AS CMTVEICULO
              ,NULL AS DISTEIXOVEICULO
              ,NULL AS ANOMODVEICULO
              ,NULL AS ANOFABVEICULO
              ,NULL AS TPPINTVEICULO
              ,NULL AS TPVEICVEICULO
              ,NULL AS ESPVEICVEICULO
              ,NULL AS CONDVINVEICULO
              ,NULL AS CONDVEICVEICULO
              ,NULL AS MARCMODVEICULO
              ,NULL AS CORDENATRANVEICULO
              ,NULL AS LOTACAOVEICULO
              ,NULL AS TPRESTVEICULO
              --fim dados veiculos
              ,PCMOVCOMPLE.PRECOMAXCONSUM AS PRECO_MAX_CONSUMIDOR
              ,PCMOVCOMPLE.PORIGINAL AS PRECO_FABRICA
              ,PCMOVCOMPLE.DESCPRECOFAB AS DESCONTO_FABRICA
              ,NULL AS CODPRODCABCESTA
              ,PCMOV.PERBONIFIC AS PERCBONIFIC
              ,PCPRODUT.ANP AS CODIGOANP
              ,NULL AS NUMERO_FCI
              ,PCEMBALAGEM.CODAUXILIAR AS COD_AUXILIAR_EMBALAGEM
              ,PCMOVCOMPLE.NUMDRAWBACK AS  NUMERO_DRAWBACK
              ,ROUND(ROUND((ROUND((NVL(PCMOV.BASEICMS, 0) * PCMOV.QTCONT), 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100)), 2) *
                      (NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) / 100) , 2) AS VALORICMSDIF
              ,NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) AS ALIQUOTAICMSDIF
              ,ROUND(PCMOV.QTCONT * PCMOVCOMPLE.VLICMSDESONERACAO, 2) VLICMSDESONERACAO
              ,PCMOVCOMPLE.CODMOTIVOICMSDESONERADO CODMOTIVOICMSDESONERADO
              ,0 AS VALOR_IPI_OUTROS
              ,PCNFENT.TIPOPRESENCAADQUIRINTE TIPO_PRESENCA_ADQUIRINTE
              ,PCMOVCOMPLE.CODCEST
              ,PCMOVCOMPLE.CODENQIPI CODENQUADRAMENTOIPI
              ,PCCFO.CODOPER CODOPERCFOP
              ,0 AS ALIQFCPPART
              ,0 AS ALIQINTERNADEST
              ,0 AS ALIQINTERORIGPART
              ,0 AS VLFCPPART
              ,0 AS VLBASEPARTDEST
              ,0 AS PERCPROVPART
              ,0 AS VLICMSDIFALIQPART
              ,0 AS VLICMSPARTDEST
              ,0 AS VLICMSPARTREM
              ,PCFILIAL.CODIGO AS CODFILIAL
              ,NVL(PCNFENT.TIPOVIATRANSPORTE, 0) AS VIASTRANSP
              ,0 AS VLAFRMM
              ,PCNFENT.FINALIDADENFE
              ,NVL(PCPRODUT.REGISTROMSMED, PCPRODUT.ANVISA) AS PROD_ANVISA
              ,NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') PROD_RASTREADO
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0),2) VLBASEFCPICMS
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPST, 0),2) VLBASEFCPST
              ,0 VLBCFCPSTRET
              ,0 PERFCPSTRET
              ,0 VLFCPSTRET
              ,0 PERFCPSN
              ,0 VLCREDFCPICMSSN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFECP, 0),2) VLFECP
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0),2) VLACRESCIMOFUNCEP
              ,NVL(PCMOVCOMPLE.PERACRESCIMOFUNCEP, 0) AS PERACRESCIMOFUNCEP
              ,NVL(PCMOVCOMPLE.ALIQICMSFECP, 0) AS ALIQICMSFECP
              ,PCMOVCOMPLE.CODBENEFICIOFISCAL AS COD_BENEFICIO_FISCAL
              ,NVL(PCMOVCOMPLE.INDESCALARELEVANTE, PCPRODFILIAL.INDESCALARELEVANTE) AS IND_ESCALA_RELEVANTE
              ,PCMOVCOMPLE.CODAGREGACAO AS COD_AGREGACAO
              ,PCMOVCOMPLE.CNPJFABRICANTE AS CNPJ_FABRICANTE
              ,NVL(PCMOVCOMPLE.DESCANP, PCPRODUT.DESCANP) AS DESC_ANP
              ,NULL AS ISENTO_ICMS_UF_DEST
              ,NVL(PCPRODUT.TIPOPROD, 0) AS MIUDEZA
              ,NVL(PCMOVCOMPLE.PGLP, NVL(PCPRODUT.pGLP, 0)) AS PERCENTUAL_GLP
              ,NVL(PCMOVCOMPLE.PGNN, NVL(PCPRODUT.PGNN, 0)) AS PERC_GAS_NATURAL_NACIONAL
              ,NVL(PCMOVCOMPLE.PGNI, NVL(PCPRODUT.PGNI, 0)) AS PERC_GAS_NATURAL_IMPORTADO
              ,NVL(PCMOVCOMPLE.VPART, NVL(PCPRODUT.VPART, 0)) AS VALOR_PARTIDA
              ,NVL((SELECT PRIORIDADE FROM PCPRIORIDADEPRODDANFE WHERE CODPRIORIDADE = PCPRODFILIAL.CODCADPRIORIDADE), 0) AS COD_PRIORIDADE_IMPRESSAO
              ,PCMOV.NUMNOTA
              ,NVL(PCMOVCOMPLE.PERCREDBASEEFET, 0) AS PERCREDBASEEFET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEEFET, 0),2) VLBASEEFET
              ,NVL(PCMOVCOMPLE.PERCICMSEFET, 0) AS PERCICMSEFET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSEFET, 0),2) VLICMSEFET
              ,NVL(PCMOVCOMPLE.ALIQICMS1RET, 0) + NVL(PCMOVCOMPLE.PERFCPSTRET, 0) AS PERCSTRET
              ,NVL(PCMOVCOMPLE.CODMOTISENCAOANVISA, PCPRODUT.CODMOTISENCAOANVISA) AS MOTIVO_ISENCAO_ANVISA
              ,DECODE(NVL(PCNFENT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.VLICMSBCR, 0) * PCMOV.QTCONT),0) AS VLICMSBCR
              --PCEST TEMPORARIO
              ,0 AS BASEBCR_PCEST
              ,0 AS PERCSTRET_PCEST
              ,0 AS VLICMSBCR_PCEST
              ,0 AS STBCR_PCEST
              ,0 AS VLBCFCPSTRET_PCEST
              ,0 AS PERFCPSTRET_PCEST
              ,0 AS VLFCPSTRET_PCEST
              ,NULL AS VLAPROXTRIB
              ,PCMOVCOMPLE.MOTREDADREM
              ,NVL(PCMOVCOMPLE.ADREMICMS, 0) AS ADREMICMS
              ,NVL(PCMOVCOMPLE.ADREMICMSRETEN, 0) AS ADREMICMSRETEN
              ,NVL(PCMOVCOMPLE.PREDADREM, 0) AS PREDADREM
              ,NVL(PCMOVCOMPLE.ADREMICMSDIF, 0) AS ADREMICMSDIF
              ,NVL(PCMOVCOMPLE.ADREMICMSRET, 0) AS ADREMICMSRET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONO, 0),2) AS QBCMONO
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONO, 0),2) AS VICMSMONO
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONORETEN, 0),2) AS QBCMONORETEN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONORETEN, 0),2) AS VICMSMONORETEN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONODIF, 0),2) AS QBCMONODIF
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONODIF, 0),2) AS VICMSMONODIF
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONORET, 0),2) AS QBCMONORET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONORET, 0),2) AS VICMSMONORET              
              ,PCPRODUT.OBSCONTXCAMPO
              ,PCPRODUT.OBSCONTXTEXTO
              ,PCPRODUT.OBSFISCOXCAMPO
              ,PCPRODUT.OBSFISCOXTEXTO
        FROM   PCMOV
              ,PCNFENT
              ,PCPRODUT
              ,PCFORNEC
              ,PCCONSUM
              ,PCFILIAL
              ,PCEMBALAGEM
              ,PCSECAO
              ,PCDEPTO
              ,PCMARCA
              ,PCTABPR
              ,PCMOVCOMPLE
              ,PCEQUIPAMENTO
              ,PCPRODFILIAL
              ,PCCFO
        WHERE  PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
        AND    PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
        AND    PCMOV.CODEQUIPAMENTO = PCEQUIPAMENTO.CODEQUIPAMENTO(+)
        AND    PCMOV.NUMNOTA = PCNFENT.NUMNOTA
        AND    PCMOV.CODPROD = PCPRODUT.CODPROD
        AND    PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)
        AND    PCMOV.CODPROD = PCTABPR.CODPROD(+)

        AND    PCMOV.NUMREGIAO = PCTABPR.NUMREGIAO(+)
        AND    PCMOV.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR(+)
        AND    PCMOV.CODPROD = PCEMBALAGEM.CODPROD(+)
        AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCFILIAL.CODIGO
        AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+)
        AND    PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC(+)
        AND    PCPRODUT.CODSEC = PCSECAO.CODSEC(+)
        AND    PCPRODUT.CODEPTO = PCDEPTO.CODEPTO(+)
        AND    PCMOV.CODPROD = PCPRODFILIAL.CODPROD(+)
        AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCPRODFILIAL.CODFILIAL(+)
        AND    PCMOV.QTCONT > 0
        AND    PCNFENT.ESPECIE IN ('NF', 'NE', 'EI')
        AND    (NVL(PCNFENT.GERANFVENDA, 'N') = 'S'
        AND     (PCNFENT.TIPODESCARGA <> 'N'))
        AND    NVL(PCNFENT.GERANFDEVCLI, 'N') = 'N'
        AND    PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
        AND   PCMOV.CODFISCAL = PCCFO.CODFISCAL(+)
        UNION ALL
        --DEVOLUCAO
        SELECT PCMOV.NUMTRANSENT AS NUM_TRANSACAO
              ,PCMOV.NUMSEQ
              ,PCMOV.CODPROD
              ,PCMOVCOMPLE.NUMCHAVEEXP AS NUM_CHAVE_EXPORTACAO
              ,PCMOVCOMPLE.NUMREGEXP AS NUM_REGISTRO_EXPORTACAO
              ,NVL(TRIM(PCMOV.CODINTERNO), TO_CHAR(PCMOV.CODPROD)) AS CODIGO_PRODUTO
              /*,CASE WHEN LENGTH(NVL(PCPRODUT.CODAUXILIARTRIB, '')) IN (8, 12, 13, 14) THEN
                      TO_CHAR(PCPRODUT.CODAUXILIARTRIB)
                    WHEN (LENGTH(PCPRODUT.CODAUXILIARTRIB) < NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIARTRIB), PCPRODUT.GTINCODAUXILIARTRIB,'0')
                    WHEN LENGTH(NVL(PCPRODUT.CODAUXILIAR, '')) IN (8, 12, 13, 14) THEN
                      TO_CHAR(PCPRODUT.CODAUXILIAR)
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR) < NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
               ELSE
                  NULL
               END AS EAN*/
              ,CASE WHEN (LENGTH(PCPRODUT.CODAUXILIAR) <= NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                        CASE WHEN (PCMOVCOMPLE.USAUNIDADEMASTER = 'S') THEN
                          LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR2), PCPRODUT.GTINCODAUXILIAR2,'0')
                        ELSE
                          LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
                        END
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR2) <= NVL(PCPRODUT.GTINCODAUXILIAR2,0)) THEN
                       CASE WHEN (PCMOVCOMPLE.USAUNIDADEMASTER = 'S') THEN
                          LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR2), PCPRODUT.GTINCODAUXILIAR2,'0')
                        ELSE
                          LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
                        END
               ELSE
                  NULL
               END AS EAN
              ,PCMOV.DV AS DIGITO_PRODUTO
              ,(NVL(PCMOV.PRODDESCRICAOCONTRATO,
                    NVL(PCMOV.DESCRICAO, PCMOV.COMPLEMENTO)) || ' ' ||
               DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE,
                           'N'),
                       'S',
                       DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM,
                                  'N'),
                              'N',
                              PCMOV.EMBALAGEM,
                              ('QTD. ' ||
                              LTRIM(to_char((PCMOV.QTCONT /
                                      DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                                   0),
                                               0,
                                               1,
                                               PCEMBALAGEM.QTUNIT)),'999999999999999990.99')) || ' ' ||
                              PCEMBALAGEM.UNIDADE || '')))) AS PRODUTO

              ,NVL(PCPRODUT.NATUREZAPRODUTO,
                   'X') AS NATUREZAPRODUTO
              ,TRIM(NVL(PCPRODFILIAL.INFTECNICA, '') || ' ' ||
                   CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIAINFOLOTENFE', PCMOV.CODFILIAL), 'S') = 'S') THEN
                       DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                               '')),
                                    0),
                                0,
                                '',
                                ' N. LT. ') || PCMOV.NUMLOTE || ' ' ||
                       DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                               '')),
                                    0),
                                0,
                                '',
                                ' DATA FAB.: ') ||
                       (SELECT TO_CHAR(PCLOTE.DATAFABRICACAO, 'DD/MM/YYYY')
                        FROM   PCLOTE
                        WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                        AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                        AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                        AND    ROWNUM = 1) || ' ' ||
                        DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                                   '')),
                                        0),
                                    0,
                                    '',
                                    ' DATA VAL.: ') || (SELECT TO_CHAR(PCLOTE.DTVALIDADE,'DD/MM/YYYY')
                        FROM   PCLOTE
                        WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                        AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                        AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                        AND    ROWNUM = 1)
                    ELSE
                       ''
                    END || ' ' ||
                    DECODE(NVL(PCPRODUT.ENVIAINFTECNICANFE, 'S'), 'S', PCPRODUT.INFORMACOESTECNICAS, NULL) ||
                    (SELECT ' - ' || PCCERTIFIC.MENSAGEMNF
                      FROM   PCCERTIFIC
                      WHERE  PCCERTIFIC.CODCERTIFIC = PCMOV.CODCERTIFIC
                      AND    ROWNUM = 1
                      --esta clausula serve para pegar sempre o certificado mais atual
                      AND TRUNC(PCCERTIFIC.DTVENC) = (SELECT TRUNC(MAX(F1.DTVENC)) FROM PCCERTIFIC F1 WHERE F1.CODCERTIFIC = PCCERTIFIC.CODCERTIFIC)
                     )
                      || ' ' ||
                      DECODE(PCMOV.CODOPER, 'EO', 'ID.EQUIP.:'|| PCEQUIPAMENTO.IDPATRIMONIO
                      || ' ' || 'COD.EQUIP.: ' || PCEQUIPAMENTO.CODEQUIPAMENTO
                      || ' ' || 'MARCA EQUIP.: ' || PCEQUIPAMENTO.MARCA
                      || ' ' || 'VOLT.EQUIP.: ' || PCEQUIPAMENTO.VOLTAGEM
                      )
                      ||
                      CASE WHEN (NVL(PCMOVCOMPLE.ENVIARALIQREDUCAOPISCOFINS,'N') = 'S') THEN
                           ';%Red.Aliq.PIS ' || LTRIM(to_char(NVL(PCMOVCOMPLE.ALIQREDUCAOPIS,0),'999999999999999990.99')) ||
                           ';%Red.Aliq.COFINS ' || LTRIM(to_char(NVL(PCMOVCOMPLE.ALIQREDUCAOCOFINS,0),'999999999999999990.99'))
                      END || ' ' ||
                      CASE WHEN NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0) > 0 THEN
                            ' VBCFCP: ' || TRIM(TO_CHAR(CASE WHEN (NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0) > 0) THEN
                                                  ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0),2)
                                                ELSE
                                                  ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)),2)
                                                END,'999999999999999990.99')) ||
                            ' PFCP: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.PERACRESCIMOFUNCEP, 0),'999999999999999990.99')) ||
                            ' VFCP: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0),2),'999999999999999990.99'))
                       END ||
                       CASE WHEN NVL(PCMOVCOMPLE.VLFECP, 0) > 0 THEN
                            ' VBCFCPST: ' || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPST, 0),2),'999999999999999990.99')) ||
                            ' PFCPST: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.ALIQICMSFECP, 0),'999999999999999990.99')) ||
                            ' VFCPST: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFECP, 0),2),'999999999999999990.99'))
                       END ||
                       CASE WHEN ((NVL(PCMOV.SITTRIBUT, '55') = '61') AND 
                                  (NVL(PCMOVCOMPLE.VICMSMONORET, 0) > 0)) THEN
                            ' ICMS monofásico sobre combustíveis cobrado anteriormente conforme Convênio ICMS 199/2022.'
                       END
                      ) AS INFO_TECNICA
              ,REPLACE(PCMOV.NBM, '.', '') AS NCM
              ,LPAD(TO_CHAR(PCMOVCOMPLE.EXTIPI), 2,'0') EXTIPI
              ,(SUBSTR(PCMOV.NBM,
                       1,
                       2)) AS GENERO
              ,PCMOV.CODFISCAL AS CFOP
              ,PCMOV.UNIDADE AS UNIDADE_COMERCIAL
              ,ROUND(PCMOV.QTCONT, 4) AS QUANTIDADE_COMERCIAL
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                          (PCNFENT.TIPODESCARGA = 'N') THEN
                         --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                           NVL(PCMOV.PTABELA, 0)    --Pre?o de Tabela
                           - DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DEDUCOES', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESCONTO, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_FRETE', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLFRETE, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SEGURO', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSEGURO, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CAPATAZIA', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLCAPATAZIA, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ACRESCIMOS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESPDENTRONF, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIMPORTACAO, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_IPI', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIPI, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDPIS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0),  0, NVL(PCMOV.VLCREDPIS, 0),  NVL(PCMOVCOMPLE.VLPISCALCDI, 0)), 0) --Vl PIS
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDCOFINS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)), 0) --Vl Cofins
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ST', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.ST, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLICMS, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_AFRMM', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLAFRMM, 0), 0)
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SISCOMEX', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSISCOMEX, 0), 0)
                    --       + NVL(PCMOV.VLOUTRASDESPIMP, 0) -- vl Outras despesa importa??o
                           + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DESPADUAN', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLADUANEIRA, 0), 0)
               ELSE
                             --FORMA QUE ESTAVA ANTERIORMENTE
                             (DECODE(PCMOVCOMPLE.BONIFIC, 'S', PCMOV.PBONIFIC, ROUND(PCMOV.PUNITCONT * PCMOV.QTCONT,2) / PCMOV.QTCONT ) - DECODE(PCNFENT.TIPODESCARGA, 'N', NVL(PCMOV.VLFRETE,
                                          0), 0)  +
                              --CONSIDERAR VALOR DESONERAÇÃO PARA ENTRADA DEVOLUÇÃO
                                CASE WHEN (PCMOV.CODOPER = 'ED') THEN
                                    CASE WHEN ((NVL(PCMOVCOMPLE.PERCICMSDESONERACAO, 0) > 0) AND (NVL(PCMOVCOMPLE.VLICMSDESONERACAO, 0) > 0) ) THEN PCMOVCOMPLE.VLICMSDESONERACAO
                                            ELSE 0 END + (ROUND(NVL(PCMOV.VLDESCSUFRAMA, 0) * PCMOV.QTCONT, NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2)) / PCMOV.QTCONT)
                                    ELSE 0 END +

                               DECODE(NVL(PCCLIENT.PRECOUTILIZADONFE,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', PCFILIAL.CODIGO),
                                           'L')),
                                       'L',
                                       0,
                                       'LR',
                                       --devolução tem que ser a msm regra da venda, que é 0 quando parametro = LR
                                       DECODE(PCMOV.CODOPER, 'ED', 0, NVL(PCMOV.VLREPASSE,0)),
                                       DECODE(NVL(PCMOVCOMPLE.VLDESCONTONF, 0), 0,
                                        (ROUND( PCMOV.QTCONT *
                                        (DECODE((NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                     0,
                                                       0,
                                                       DECODE(SIGN((NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)),
                                                                   -1,
                                                                   0,
                                                                   (NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)) -



                                                                   NVL(DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT),0)))
                                        ), 2) / PCMOV.QTCONT),

                                        (ROUND( PCMOV.QTCONT *
                                        (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                     0,
                                                       0,
                                                       DECODE(SIGN(NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                                   -1,
                                                                   0,
                                                                   NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)))
                                        ), 2) / PCMOV.QTCONT))+
                                       CASE WHEN ((PCNFENT.FINALIDADENFE = 'A') AND (PCNFENT.TIPODESCARGA IN ('6','8', 'T'))) THEN
                                               CASE WHEN (TRIM(PCCLIENT.SULFRAMA) IS NOT NULL 
                                                     AND TRUNC(PCCLIENT.DTVENCSUFRAMA) >= TRUNC(PCNFENT.DTENT) ) THEN
                                                  COALESCE(PCMOV.VLDESCSUFRAMA,0)
                                               ELSE
                                                  0
                                               END      
                                            ELSE
                                              0
                                       END

                                     ) +
                                          --apenas para devolução, calculo conforme a venda -- aqui
                                              (CASE WHEN (/*(PCNFENT.FINALIDADENFE <> 'A') AND*/ (PCNFENT.TIPODESCARGA IN ('6','8', 'T'))) THEN
                                                    CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                                               ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  pcnfent.dtent))) THEN
                                                           0
                                                         ELSE

                                                             (ROUND((NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOV.VLDESCREDUCAOPIS, 0)) * PCMOV.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT)

                                                   END
                                              ELSE
                                                    0
                                              END)
                                      +
                                    (CASE WHEN (PCNFENT.TIPODESCARGA IN ('6','8', 'T')) THEN
                                           DECODE(NVL(PCNFENT.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, ROUND(NVL(PCMOV.VLDESCICMISENCAO,0) * PCMOV.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT )
                                     ELSE
                                           0
                                     END) -
                               NVL(PCMOV.VLOUTRASDESP,
                                    0) - NVL(PCMOV.ST,
                                              0) - NVL(PCMOV.VLIPI,
                                                        0) -
                               DECODE(PCNFENT.TIPODESCARGA,
                                       'N',
                                       NVL(PCMOV.VLADUANEIRA,
                                           0) + NVL(PCMOV.VLSISCOMEX,
                                                    0) + NVL(PCMOV.VLIMPORTACAO,
                                                             0) +
                                       NVL(PCMOV.VLOUTRASDESPIMP,
                                           0) +
                                       DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                                       DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)) +
                                       DECODE(NVL(PCMOVCOMPLE.DEDUZIRICMSIMPORTACAO, 'S'),
                                              'S',
                                              NVL(PCMOVCOMPLE.VLICMS, NVL(PCMOV.VLCREDICMS, 0)),
                                              0) + NVL(PCMOVCOMPLE.VLANTIDUMPING, 0) +  NVL(PCMOVCOMPLE.VLAFRMM, 0),
                                       0) +
                               DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                         PCFILIAL.CODIGO),
                                           'N')),
                                       'N',
                                       0,
                                       (NVL(PCMOV.VLIMPORTACAO,
                                            0) + NVL(PCMOV.VLFRETE,
                                                      0) + NVL(PCMOV.VLOUTRASDESP,
                                                                0))))
                                                                -
                             (CASE WHEN PCNFENT.TIPODESCARGA = '8' AND PCMOV.CODOPER = 'ER' AND NVL(PCMOVCOMPLE.VLFECP, 0) > 0 THEN
                                            DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0), 0, 0, NVL(PCMOVCOMPLE.VLFECP, 0))
                                        ELSE
                                            DECODE(PCMOV.CODOPER, 'ED', (DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0), 0, 0, NVL(PCMOVCOMPLE.VLFECP, 0))),
                                                                  'EN', (DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0), 0, 0, NVL(PCMOVCOMPLE.VLFECP, 0))), 0) END)
               END AS VALOR_COMERCIAL
              ,(DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT) - NVL(PCMOV.ST,
                                      0) -
               NVL(PCMOV.VLIPI,
                    0) - NVL(PCMOV.VLFRETE,
                              0) -
               DECODE(PCNFENT.TIPODESCARGA,
                       'N',
                       NVL(PCMOV.VLADUANEIRA,
                           0) + NVL(PCMOV.VLSISCOMEX,
                                    0) + NVL(PCMOV.VLIMPORTACAO,
                                             0) +
                       NVL(PCMOV.VLOUTRASDESPIMP,0) +
                       DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                       DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)) +
                       NVL(PCMOV.VLCREDICMS,
                           0),
                       0) +
               DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                         PCFILIAL.CODIGO),
                           'N')),
                       'N',
                       0,
                       (NVL(PCMOV.VLIMPORTACAO,
                            0) + NVL(PCMOV.VLFRETE,
                                      0) + NVL(PCMOV.VLOUTRASDESP,
                                                0))) +
               NVL(PCMOV.VLDESCPISSUFRAMA,
                    0) + NVL(PCMOV.VLDESCSUFRAMA,
                              0) + NVL(PCMOV.VLDESCICMISENCAO,
                                        0)) AS VALOR_LIQUIDO
              /*,CASE
                 WHEN LENGTH(NVL(PCPRODUT.CODAUXILIAR,
                                 '')) IN (8,
                                          12,
                                          13,
                                          14) THEN
                  TO_CHAR(PCPRODUT.CODAUXILIAR)
                ELSE CASE
                  WHEN (LENGTH(PCPRODUT.CODAUXILIAR) < NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
                ELSE
                  NULL
                END
               END AS EAN_UNIDADE*/
              ,CASE WHEN (LENGTH(PCPRODUT.CODAUXILIARTRIB) <= NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIARTRIB), PCPRODUT.GTINCODAUXILIARTRIB,'0')
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR) <= NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
               ELSE
                  NULL
               END AS EAN_UNIDADE
              ,PCMOVCOMPLE.UNIDADETRIB AS UNIDADE_TRIBUTAVEL
              ,CASE WHEN (NVL(PCNFENT.FINALIDADENFE,'O') = 'C') THEN
                    0
               ELSE
                 ROUND(PCMOV.QTCONT, 4)
               END AS QUANTIDADE_TRIBUTAVEL
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                               (PCNFENT.TIPODESCARGA = 'N') THEN
                             --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                             NVL(PCMOV.PTABELA, 0)    --Pre?o de Tabela
                             - DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DEDUCOES', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESCONTO, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_FRETE', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLFRETE, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SEGURO', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSEGURO, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CAPATAZIA', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLCAPATAZIA, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ACRESCIMOS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLDESPDENTRONF, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIMPORTACAO, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_IPI', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLIPI, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDPIS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0),  0, NVL(PCMOV.VLCREDPIS, 0),  NVL(PCMOVCOMPLE.VLPISCALCDI, 0)), 0) --Vl PIS
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDCOFINS', PCFILIAL.CODIGO),'N'), 'S', DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)), 0) --Vl Cofins
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ST', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.ST, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLICMS, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_AFRMM', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOVCOMPLE.VLAFRMM, 0), 0)
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_SISCOMEX', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLSISCOMEX, 0), 0)
                             --  + NVL(PCMOV.VLOUTRASDESPIMP, 0) -- vl Outras despesa importa??o
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DESPADUAN', PCFILIAL.CODIGO),'N'), 'S', NVL(PCMOV.VLADUANEIRA, 0), 0)
               ELSE
                              (DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT) -
                                      DECODE(PCNFENT.TIPODESCARGA, 'N', NVL(PCMOV.VLFRETE,
                                                      0), 0)  +
                                      --apenas para devolução, calculo conforme a venda -- aqui
                                      (CASE WHEN ((PCNFENT.FINALIDADENFE <> 'A') AND (PCNFENT.TIPODESCARGA IN ('6','8', 'T'))) THEN
                                            CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                                       ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  pcnfent.dtent))) THEN
                                                   0
                                                 ELSE
                                                   (ROUND((NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOV.VLDESCREDUCAOPIS, 0)) * PCMOV.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT)
                                           END
                                      ELSE
                                            0
                                      END)  +
                                      DECODE(NVL(PCCLIENT.PRECOUTILIZADONFE,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                                 PCFILIAL.CODIGO),
                                                   'L')),
                                               'L',
                                               0,
                                               'LR',
                                               --devolução tem que ser a msm regra da venda, que é 0 quando parametro = LR
                                               DECODE(PCMOV.CODOPER, 'ED', 0, NVL(PCMOV.VLREPASSE,0)),

                                               --Adicionado mesmo arredondamento de desconto que existe na saida para corrigir rejeição 610 31/08/2018
                                       DECODE(NVL(PCMOVCOMPLE.VLDESCONTONF, 0), 0,
                                          (ROUND( PCMOV.QTCONT *
                                          (DECODE((NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                       0,
                                                       0,
                                                       DECODE(SIGN((NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)),
                                                                   -1,
                                                                   0,
                                                                   (NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)) -



                                                                   NVL(DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT),0)))
                                        ), 2) / PCMOV.QTCONT),

                                        (ROUND( PCMOV.QTCONT *
                                        (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                     0,
                                                       0,
                                                       DECODE(SIGN(NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                                   -1,
                                                                   0,
                                                                   NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)))
                                        ), 2) / PCMOV.QTCONT)) +
                                       CASE WHEN ((PCNFENT.FINALIDADENFE = 'A') AND (PCNFENT.TIPODESCARGA IN ('6','8', 'T'))) THEN
                                              CASE WHEN (TRIM(PCCLIENT.SULFRAMA) IS NOT NULL 
                                                     AND TRUNC(PCCLIENT.DTVENCSUFRAMA) >= TRUNC(PCNFENT.DTENT) ) THEN
                                                  COALESCE(PCMOV.VLDESCSUFRAMA,0)
                                               ELSE
                                                  0
                                               END
                                            ELSE
                                              0
                                       END
                                  ) +
                                  (CASE WHEN (PCNFENT.TIPODESCARGA IN ('6','8', 'T')) THEN
                                        DECODE(NVL(PCNFENT.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, ROUND(NVL(PCMOV.VLDESCICMISENCAO,0) * PCMOV.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT )
                                  ELSE
                                        0
                                  END) -
                                --FIM DECODE DESCONTO -

                                       NVL(PCMOV.VLOUTRASDESP,
                                            0) - NVL(PCMOV.ST,
                                                      0) - NVL(PCMOV.VLIPI,
                                                                0) -
                                       DECODE(PCNFENT.TIPODESCARGA,
                                               'N',
                                               NVL(PCMOV.VLADUANEIRA,
                                                   0) + NVL(PCMOV.VLSISCOMEX,
                                                            0) + NVL(PCMOV.VLIMPORTACAO,
                                                                     0) +
                                               NVL(PCMOV.VLOUTRASDESPIMP,0) +
                                               DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                                               DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)) +
                                               DECODE(NVL(PCMOVCOMPLE.DEDUZIRICMSIMPORTACAO, 'S'),
                                                      'S',
                                                      NVL(PCMOVCOMPLE.VLICMS, NVL(PCMOV.VLCREDICMS, 0)),
                                                      0) + NVL(PCMOVCOMPLE.VLANTIDUMPING, 0) +  NVL(PCMOVCOMPLE.VLAFRMM, 0),
                                               0) +
                                       DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                                 PCFILIAL.CODIGO),
                                                   'N')),
                                               'N',
                                               0,
                                               (NVL(PCMOV.VLIMPORTACAO,
                                                    0) + NVL(PCMOV.VLFRETE,
                                                              0) + NVL(PCMOV.VLOUTRASDESP,
                                                                        0))))
                                                                             -
                             DECODE(PCMOV.CODOPER, 'ED',
                                     (DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0),
                                      0,
                                      0,
                                      NVL(PCMOVCOMPLE.VLFECP, 0))
                                      ),
                                   0)
               END AS VALOR_TRIBUTAVEL
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                         --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                         ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_FRETE', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLFRETE, 0), 0) *
                                      NVL(PCMOV.QTCONT, 0), 2)
                    ELSE
                         --FORMA ANTIGA
                         DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                                NVL(PCNFENT.CODFILIALNF,
                                                                    PCNFENT.CODFILIAL)),
                                  'N')),
                              'S',
                              0,
                              ROUND(NVL(PCMOV.VLFRETE,
                                        0) * NVL(PCMOV.QTCONT,
                                                 0),
                                    2))
               END AS VALOR_FRETE
              ,0 AS VALOR_SEGURO
              ,ROUND((DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE, NVL(PCCLIENT.PRECOUTILIZADONFE,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                              PCFILIAL.CODIGO),
                                'L'))),
                            'L',
                            0,
                            'LR',
                       /*NVL(PCMOV.VLREPASSE,0)*/0,

                        DECODE(NVL(PCMOVCOMPLE.VLDESCONTONF, 0), 0,
                                    (ROUND( PCMOV.QTCONT *
                                    (DECODE((NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                 0,
                                                   0,
                                                   DECODE(SIGN((NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)) - DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT)),
                                                               -1,
                                                               0,
                                                               (NVL(PCMOV.PTABELA, 0) - NVL(PCMOV.VLREPASSE, 0)) -



                                                               NVL(DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT),0)))
                                    ), 2) / PCMOV.QTCONT),

                                    (ROUND( PCMOV.QTCONT *
                                    (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                 0,
                                                   0,
                                                   DECODE(SIGN(NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                               -1,
                                                               0,
                                                               NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)))
                                    ), 2) / PCMOV.QTCONT)) +
                            CASE WHEN (PCNFENT.TIPODESCARGA IN ('6','8', 'T')) THEN
                                    CASE WHEN (TRIM(PCCLIENT.SULFRAMA) IS NOT NULL 
                                         AND TRUNC(PCCLIENT.DTVENCSUFRAMA) >= TRUNC(PCNFENT.DTENT) ) THEN
                                             COALESCE(PCMOV.VLDESCSUFRAMA,0)
                                   ELSE
                                      0
                                   END
                                 ELSE
                                   0
                            END
                            ) * PCMOV.QTCONT) +
                            (CASE WHEN (PCNFENT.TIPODESCARGA IN ('6','8','T')) THEN
                                 CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                       ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  PCNFENT.DTENT))) THEN
                                           0
                                 ELSE
                                           (NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOV.VLDESCREDUCAOPIS, 0)) * QTCONT
                                 END
                            ELSE
                                 0
                            END)
                     ,2) AS VALOR_DESCONTO
              ,(NVL(PCMOV.PESOBRUTO,
                    0) * PCMOV.QTCONT) AS PESO_BRUTO
              ,NVL(PCMOV.PERCIPI,
                   0) AS PERCIPIVENDA
              ,NVL(PCMOV.VLIPIPORKG,
                   0) AS VLIPIPORKGVENDA
              ,PCMOV.TIPOMERC
              ,PCNFENT.NUMDIIMPORTACAO AS NUM_DOC_IMPORTACAO
              ,PCNFENT.LOCALDESEMBARACO AS LOCAL_DESEMBARACO
              ,PCNFENT.UFDESEMBARACO AS SIGLA_UF_DESEMBARACO
              ,PCNFENT.DATADIIMPORTACAO AS DATA_DESEMBARACO
              ,PCNFENT.CODEXPORTADOR AS CODIGO_EXPORTADOR
              ,NVL(PCMOV.NUMADICAO, PCMOV.NUMSEQ) AS NUMERO_ADICAO
              ,NVL(PCMOV.NUMSEQADICAO, PCMOV.NUMSEQ) AS NUMERO_SEQUENCIA
              ,PCNFENT.CODFORNEC AS CODIGO_FABRICANTE_EX
              ,0 AS VALOR_DESCONTO_ADICAO
              ,PCMOV.NUMLOTE AS NUMERO_LOTE
              ,PCMOV.QTCONT AS QT_LOTE
              ,(SELECT PCLOTE.DATAFABRICACAO
                FROM   PCLOTE
                WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                AND    ROWNUM = 1) AS DATA_FABRICACAO
              ,(SELECT PCLOTE.DTVALIDADE
                FROM   PCLOTE
                WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                AND    PCLOTE.CODFILIAL = PCMOV.CODFILIAL
                AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                AND    ROWNUM = 1) AS DATA_VALIDADE
              ,NVL(PCMOVCOMPLE.PRECOMAXCONSUM,
               DECODE(NVL(PCTABPR.PRECOMAXCONSUM,
                          0),
                      0,
                      NVL(PCPRODUT.PRECOMAXCONSUM,
                          0),
                      NVL(PCTABPR.PRECOMAXCONSUM,
                          0))) PRECO_MAXIMO
              ,NVL(LTRIM(TRANSLATE(NVL(PCMOVCOMPLE.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), NVL(TRANSLATE(NVL(PCMOVCOMPLE.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), '1234567890', ' '),'X'), ' ')),
                    DECODE(NVL(PCMOV.IMPORTADO, 'N'),
                        'S',
                            2,
                        'D',
                            1,
                            0
               )) AS  ORIGEM_MERCADORIA
              ,NVL(PCMOV.SITTRIBUT, 55) AS SITUACAO_TRIBUTARIA
              ,'3' AS MODALIDADE_BC_ICMS
              ,ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)),2) BASE_ICMS
              ,NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) AS ALIQUOTA_ICMS
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', PCFILIAL.CODIGO),'N') = 'N' THEN
                         ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                               (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2)
                          -
                         ROUND(ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                               (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                               (NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) / 100), 2)
                    ELSE
                         0
                    END
               ELSE
                    ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                          (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2)
                     -
                     ROUND(ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                           (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                           (NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) / 100), 2)
               END AS VALOR_ICMS
              ,ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                            (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2)
               AS VALOR_ICMS_OPERACAO
              ,ROUND(NVL(PCMOVCOMPLE.PERCICMSSIMPLESNAC,0),2) ALIQUOTA_CREDITO_SN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLRICMSSIMPLESNAC,0),2) VALOR_CREDITO_ICMS_SN

              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOVCOMPLE.BASEIMPORTACAO, NVL(PCMOV.VLADUANEIRA, 0)),
                                                                                                                    0) * PCMOV.QTCONT, 2)
               ELSE
                    --C?LCULO ANTIGO
                    ROUND(NVL(PCMOVCOMPLE.BASEIMPORTACAO, NVL(PCMOV.VLADUANEIRA, 0)) * PCMOV.QTCONT, 2)
               END AS BASE_II
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                   --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                   ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_DESPADUAN', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLADUANEIRA, 0), 0) * PCMOV.QTCONT, 2)
               ELSE
                   --C?LCULO ANTIGO
                   ROUND(NVL(PCMOV.VLADUANEIRA, 0) * PCMOV.QTCONT, 2)
               END AS VALOR_DESPESA_ADUANEIRA
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_II', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLIMPORTACAO,0), 0) * PCMOV.QTCONT, 2)
               ELSE
                    --C?LCULO ANTIGO
                    DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT', PCFILIAL.CODIGO), 'N')),
                          'N',
                           ROUND(NVL(PCMOV.VLIMPORTACAO,0) * PCMOV.QTCONT, 2),
                           0)
               END AS VALOR_II
              ,0 AS VALOR_IOF
              ,NVL(PCMOVCOMPLE.CODSITTRIBIPI, DECODE(NVL(DECODE(NVL(PCMOV.CALCCREDIPI,
                                     'N'),
                                 'S',
                                 'S',
                                 DECODE(NVL(PCCONSUM.USATRIBUTACAOPORUF,
                                            'N'),
                                        'N',
                                        NVL(PCMOV.CALCCREDIPI,
                                            'N'),
                                        (SELECT NVL(PCTABTRIBENT.CALCCREDIPI,
                                                    'N')
                                         FROM   PCTABTRIBENT
                                         WHERE  PCTABTRIBENT.CODPROD =
                                                PCMOV.CODPROD
                                         AND    ROWNUM = 1))),
                          'N'),
                      'S',
                      00,
                      49)) SITUACAO_TRIBUTARIA_IPI
              ,ROUND((NVL(PCMOV.VLBASEIPI, 0) * PCMOV.QTCONT),2) AS BASE_IPI
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND((DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_IPI', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLIPI, 0), 0) *
                           PCMOV.QTCONT),2)
               ELSE
                    --C?LCULO ANTIGO
                    ROUND((NVL(PCMOV.VLIPI, 0) * PCMOV.QTCONT),2)
               END AS VALOR_IPI
              ,NVL(PCMOV.VLIPI, 0) AS VALOR_IPI_UNIDADE
              ,NVL(PCMOV.PERCIPI, 0) AS ALIQUOTA_IPI
              ,NVL((100 - PCMOV.PERCBASERED), 0) AS PERCENTUAL_REDUCAO_BC
              ,DECODE(NVL(PCCONSUM.UTILIZACONTROLELOTE,
                          'N'),
                      'N',
                      DECODE(NVL(PCMOV.PAUTA,
                                 0),
                             0,
                             4,
                             5),
                      DECODE(NVL(PCMOV.TIPOTRIBUTMEDIC,
                                 'OM'),
                             'PO',
                             2,
                             'NG',
                             1,
                             'NT',
                             3,
                             CASE WHEN (ROUND(NVL(PCMOV.PAUTA, 0) * (DECODE(NVL(PCMOV.PERCBASEREDST,0), 0, 1, PCMOV.PERCBASEREDST/100)), 6) = PCMOV.BASEICST) THEN
                                   5
                                ELSE
                                   4
                                END)) AS MODALIDADE_BC_ST
              ,ROUND(DECODE(NVL(PCMOV.IVA, 0), 0, NVL(PCMOV.PERCIVA, 0), PCMOV.IVA), 2) AS PERCENTUAL_MARGEM
              ,ROUND(DECODE(NVL(PCMOV.CODOPER, 'E'), 'ED', 100 - NVL(PCMOV.PERCBASEREDST, 0), NVL(PCMOV.PERCBASEREDST, 0)), 2) AS PERCENTUAL_REDUCAO_ST
              ,ROUND(NVL(PCMOV.BASEICST, 0) * PCMOV.QTCONT, 2) AS BASE_ST
              ,NVL(PCMOV.ALIQICMS1, 0) AS ALIQUOTA_ST
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    ROUND(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ST', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.ST, 0), 0) *
                          PCMOV.QTCONT, 2)
               ELSE
                    ROUND(NVL(PCMOV.ST, 0) * PCMOV.QTCONT, 2)
               END AS VALOR_ST
              ,0 AS VALOR_TOT_EMBALAGEM
              ,NVL(PCMOV.PISCOFINSRETIDO,
                   'I') AS RETIDO
              ,(CASE
                 WHEN (NVL(PCMOV.VLDESCPISSUFRAMA,
                           0) > 0)
                      OR (NVL(PCFILIAL.OPTANTESIMPLESNAC,
                              'N') = 'S') THEN
                  0
                 ELSE
                   CASE WHEN (PCMOVCOMPLE.PERCOFINSCALCDI > 0) THEN
                     NVL(PCMOVCOMPLE.PERCOFINSCALCDI, 0)
                   ELSE
                     NVL(NVL(PCMOV.PERCOFINS, PCPRODUT.PERCOFINSIMP), 0)
                   END
               END) AS ALIQUOTA_COFINS
              ,(CASE
                 WHEN (NVL(PCMOV.VLDESCPISSUFRAMA,
                           0) > 0)
                      OR (NVL(PCFILIAL.OPTANTESIMPLESNAC,
                              'N') = 'S') THEN
                  0
                 ELSE
                   CASE WHEN (PCMOVCOMPLE.PERPISCALCDI > 0) THEN
                     NVL(PCMOVCOMPLE.PERPISCALCDI, 0)
                   ELSE
                     NVL(NVL(PCMOV.PERPIS, PCPRODUT.PERPISIMP), 0)
                   END
               END) AS ALIQUOTA_PIS
              ,/*(CASE
                 WHEN (PCMOV.CODSITTRIBPISCOFINS = 5) THEN
                  99
                 ELSE
                  DECODE(NVL(PCFILIAL.OPTANTESIMPLESNAC,'N'),'S', 99, NVL(PCMOV.CODSITTRIBPISCOFINS,(CASE
                 WHEN NVL(PCMOV.VLDESCPISSUFRAMA,
                          0) > 0 THEN
                  6
                 ELSE
                  DECODE(NVL(PCPRODUT.PISCOFINSRETIDO,
                             'I'),
                         'N',
                         1,
                         'I',
                         7,
                         'S',
                         DECODE(NVL(PCPRODUT.TIPOPISCOFINSRETIDO,
                                    8),
                                2,
                                4,
                                1,
                                6,
                                5,
                                7,
                                6,
                                9,
                                8))
               END))) END)*/
               NVL(PCMOV.CODSITTRIBPISCOFINS,0) AS SIT_PIS_CONFINS
              ,ROUND(NVL(PCMOV.VLBASEPISCOFINS,
                         0) * PCMOV.QTCONT,
                     2) AS VL_BASE_PIS

              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    CASE WHEN (PCMOVCOMPLE.VLCOFINSCALCDI > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.COFINSRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.COFINSRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) *
                               DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDCOFINS', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLCREDCOFINS, 0), 0), 2)
                    END
               ELSE
                    --C?LCULO ANTIGO
                    CASE WHEN (PCMOVCOMPLE.VLCOFINSCALCDI > 0) AND (PCNFENT.TIPODESCARGA = 'N') THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.COFINSRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.COFINSRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOV.VLCREDCOFINS, 0), 2)
                    END
               END AS VALOR_COFINS
              ,ROUND(NVL(PCMOV.VLBASEPISCOFINS,
                         0) * PCMOV.QTCONT,
                     2) AS VL_BASE_CONFINS
              ,CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                         (PCNFENT.TIPODESCARGA = 'N') THEN
                    --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                    CASE WHEN (PCMOVCOMPLE.VLPISCALCDI > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.PISRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.PISRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) *
                               DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CREDPIS', PCFILIAL.CODIGO),'N'), 'N', NVL(PCMOV.VLCREDPIS, 0), 0), 2)
                    END
               ELSE
                    --C?LCULO ANTIGO
                    CASE WHEN (PCMOVCOMPLE.VLPISCALCDI > 0) AND (PCNFENT.TIPODESCARGA = 'N') THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 2)
                         WHEN (PCMOVCOMPLE.PISRETIDO > 0) THEN
                              ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOVCOMPLE.PISRETIDO, 0), 2)
                    ELSE
                         ROUND(NVL(PCMOV.QTCONT, 0) * NVL(PCMOV.VLCREDPIS, 0), 2)
                    END
               END AS VALOR_PIS
              ,PCPRODUT.CLASSIFICFISCAL AS CLASSIFICFISCAL
              ,NVL(PCPRODUT.TIPOESTOQUE,
                   'PA') AS TIPOESTOQUE
              ,PCMOV.CODOPER AS COD_OPERACAO
              ,PCPRODUT.CODFAB AS CODIGO_FABRICANTE
              ,PCPRODUT.CODFORNEC AS CODIGO_FORNECEDOR
              ,(SELECT PCPRINCIPATIVO.DESCRICAO
                FROM   PCPRINCIPATIVO
                WHERE  PCPRINCIPATIVO.CODPRINCIPATIVO =
                       PCPRODUT.CODPRINCIPATIVO
                AND    ROWNUM = 1) AS PRINCIPIOATIVO
              ,PCMOV.CODST AS CODST
              ,NVL(PCEMBALAGEM.EMBALAGEM,
                   PCPRODUT.EMBALAGEM) AS EMBALAGEM
              ,PCPRODUT.EMBALAGEMMASTER
              ,PCFORNEC.FANTASIA
              ,PCFORNEC.FORNECEDOR
              ,PCPRODUT.PESOEMBALAGEM
              ,PCPRODUT.FATORUNFARM
              ,PCMOV.PERCDESC
              ,0 PESOCX
              ,DECODE(NVL(PCMOV.QTCX,
                          0),
                      0,
                      PCMOV.QTCONT,
                      PCMOV.QTCX) QTCX
              ,NVL(PCMOV.QTPECAS,
                   0) QTPECAS
              ,NVL(PCMOVCOMPLE.QTUN,
                   0) QTUN
              ,NVL(PCMOV.PTABELA,
                   0) PTABELA
              ,NVL(PCMOV.PUNITCONT,
                   0) PUNITCONT
              ,CASE
                 WHEN NVL(PCMOV.QTCX,
                          0) > 0 THEN
                  'CX'
                 WHEN NVL(PCMOV.QTPECAS,
                          0) > 0 THEN
                  'PC'
                 ELSE
                  'UN'
               END AS TIPO_QUANTIDADE
              ,CASE
                 WHEN NVL(PCMOV.QTCX,
                          0) > 0 THEN
                  NVL(PCMOV.QTCX,
                      0)
                 WHEN NVL(PCMOV.QTPECAS,
                          0) > 0 THEN
                  NVL(PCMOV.QTPECAS,
                      0)
                 ELSE
                  NVL(PCMOV.QTCONT,
                      0)
               END AS QUANTIDADE_ENTREGA
              ,TRUNC(PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                               1),
                                           0,
                                           1,
                                           NVL(PCPRODUT.PESOBRUTOMASTER,
                                               1))) AS QTD_CAIXAS_MASTER
              ,CASE
                 WHEN TRUNC(PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                                      1),
                                                  0,
                                                  1,
                                                  NVL(PCPRODUT.PESOBRUTOMASTER,
                                                      1))) > 0 THEN
                  PCMOV.QTCONT -
                  (TRUNC(PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                                   1),
                                               0,
                                               1,
                                               NVL(PCPRODUT.PESOBRUTOMASTER,
                                                   1)) *
                         NVL(PCPRODUT.PESOBRUTOMASTER,
                             1)))
                 ELSE
                  PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOPECA,
                                            1),
                                        0,
                                        1,
                                        NVL(PCPRODUT.PESOPECA,
                                            1))
               END AS QTD_PECAS_INTERM
              ,NVL(PCPRODUT.QTUNITCX,
                   0) QTUNITCX
              ,NVL(PCPRODUT.TIPOTRIBUTMEDIC,
                   'X') TIPOTRIBUTMEDIC
              ,(NVL(PCMOV.VLBASEGNRE,
                    0) * NVL(PCMOV.QTCONT,
                              0)) VLBASEGNRE
              ,(NVL(PCMOV.STCLIENTEGNRE,
                    0) * NVL(PCMOV.QTCONT,
                              0)) STCLIENTEGNRE
              ,PCMOV.QTCONT * NVL(PCPRODUT.PESOLIQ,
                                  0) TOTPESOLIQUNIT
              ,PCPRODUT.UNIDADEMASTER
              ,PCPRODUT.NUMORIGINAL
              ,PCMARCA.MARCA
              ,PCMOV.NUMVOLUMESCONFERENCIA
              ,PCMOV.PERACRESCIMOCUSTO
              ,PCMOV.TIPOSEPARACAO
              ,PCMOV.QTUNITEMB
              ,PCMOV.CODFILIALRETIRA
              ,PCEMBALAGEM.UNIDADE AS UNIDADE_EMBALAGEM
              ,(PCMOV.QTCONT / DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                      0),
                                  0,
                                  1,
                                  PCEMBALAGEM.QTUNIT)) AS QTD_EMBALAGEM
              ,PCPRODUT.CODSEC AS CODIGO_SECAO
              ,PCPRODUT.CODEPTO AS CODIGO_DEPARTAMENTO
              ,PCSECAO.DESCRICAO AS DESCRICAO_SECAO
              ,PCDEPTO.DESCRICAO AS DESCRICAO_DEPARTAMENTO
              ,DECODE(NVL(PCNFENT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.BASEBCR,
                    0) * PCMOV.QTCONT),0) AS BASEBCR
              ,DECODE(NVL(PCNFENT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.STBCR,
                    0) * PCMOV.QTCONT),0) AS STBCR
              ,NVL(PCPRODUT.VOLUME, 0) AS VOLUME
              ,CASE
                 WHEN ((NVL(PCMOV.QTUNITCX,
                            NVL(PCPRODUT.QTUNITCX,
                                1)) > 0) AND
                      (PCMOV.QTCONT >= NVL(PCMOV.QTUNITCX,
                                        NVL(PCPRODUT.QTUNITCX,
                                            1)))) THEN
                  TRUNC(PCMOV.QTCONT / NVL(PCMOV.QTUNITCX,
                                       NVL(PCPRODUT.QTUNITCX,
                                           1)))
                 ELSE
                  0
               END QTD_CAIXA
              ,CASE
                 WHEN ((NVL(PCMOV.QTUNITCX,
                            NVL(PCPRODUT.QTUNITCX,
                                1)) > 0) AND
                      (PCMOV.QTCONT >= NVL(PCMOV.QTUNITCX,
                                        NVL(PCPRODUT.QTUNITCX,
                                            1)))) THEN
                  PCMOV.QTCONT - (TRUNC(PCMOV.QTCONT / NVL(PCMOV.QTUNITCX,
                                                   NVL(PCPRODUT.QTUNITCX,
                                                       1))) *
                  NVL(PCMOV.QTUNITCX,
                                  NVL(PCPRODUT.QTUNITCX,
                                      1)))
                 ELSE
                  PCMOV.QTCONT
               END QTD_UNIDADE
              ,NVL(PCMOV.NUMPED, 0) AS NUMERO_PEDIDO
              ,NVL(PCMOV.NUMSEQ, 1) AS NUMERO_ITEM_PEDIDO
              ,NVL(PCPRODUT.QTUNIT, 0) AS QTUNIT
              ,ROUND(DECODE(PCNFENT.TIPODESCARGA,
                            'N',
                            NVL(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SOMARVLOUTRASDESPADUANEIRAS',
                                           NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)), 'N'),
                                       'S',
                                       NVL(PCMOV.VLADUANEIRA, 0) +
                                       NVL(PCMOV.VLSISCOMEX, 0) +
                                       NVL(PCMOV.VLOUTRASDESPIMP, 0) +
                                       CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') THEN
                                           DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_CAPATAZIA', PCFILIAL.CODIGO),'N'),
                                                  'N',
                                                  NVL(PCMOVCOMPLE.VLCAPATAZIA, 0),
                                                  0)+
                                           DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_AFRMM', PCFILIAL.CODIGO),'N'),
                                                  'N',
                                                  NVL(PCMOVCOMPLE.VLAFRMM, 0),
                                                  0)+

                                           DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ACRESCIMOS', PCFILIAL.CODIGO),'N'),
                                                  'N',
                                                  NVL(PCMOV.VLDESPDENTRONF, 0),
                                                  0)
                                        ELSE
                                           DECODE(NVL(PCNFENT.CONSIDERARIIPUNIT,
                                                      NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARIIPUNIT',
                                                          NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)), 'N')),
                                                  'S',
                                                  0,
                                                  NVL(PCMOV.VLOUTRASDESP,0))
                                        END
                                      ,0) +
                                NVL(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SOMARPISCOFINSVLOUTRASDESPIMP',
                                               NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)), 'S'),
                                           'S',
                                           DECODE(NVL(PCMOVCOMPLE.VLPISCALCDI, 0), 0, NVL(PCMOV.VLCREDPIS, 0), NVL(PCMOVCOMPLE.VLPISCALCDI, 0)) +
                                           DECODE(NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0), 0, NVL(PCMOV.VLCREDCOFINS, 0), NVL(PCMOVCOMPLE.VLCOFINSCALCDI, 0)))
                                ,0) +
                                NVL(PCMOVCOMPLE.VLANTIDUMPING, 0)
                            ,0),
                            DECODE(PCMOV.CODOPER, 'ED', PCMOV.VLOUTROS, PCMOV.VLOUTRASDESP)
                            ) * PCMOV.QTCONT,2
                    ) AS VALOR_OUTROS
              --dados veiculos
              ,NULL AS TPOPERACAO
              ,NULL AS CHASSIVEICULO
              ,NULL AS CORVEICULO
              ,NULL AS DESCCORVEICULO
              ,NULL AS POTVEICULO
              ,NULL AS CILINVEICULO
              ,NULL AS PESOLVEICULO
              ,NULL AS PESOBVEICULO
              ,NULL AS SERIALVEICULO
              ,NULL AS TPCOMBVEICULO
              ,NULL AS NMOTORVEICULO
              ,NULL AS CMTVEICULO
              ,NULL AS DISTEIXOVEICULO
              ,NULL AS ANOMODVEICULO
              ,NULL AS ANOFABVEICULO
              ,NULL AS TPPINTVEICULO
              ,NULL AS TPVEICVEICULO
              ,NULL AS ESPVEICVEICULO
              ,NULL AS CONDVINVEICULO
              ,NULL AS CONDVEICVEICULO
              ,NULL AS MARCMODVEICULO
              ,NULL AS CORDENATRANVEICULO
              ,NULL AS LOTACAOVEICULO
              ,NULL AS TPRESTVEICULO
              --fim dados veiculos
              ,PCMOVCOMPLE.PRECOMAXCONSUM AS PRECO_MAX_CONSUMIDOR
              ,PCMOVCOMPLE.PORIGINAL AS PRECO_FABRICA
              ,PCMOVCOMPLE.DESCPRECOFAB AS DESCONTO_FABRICA
              ,NULL AS CODPRODCABCESTA
              ,PCMOV.PERBONIFIC AS PERCBONIFIC
              ,PCPRODUT.ANP AS CODIGOANP
              ,NULL AS NUMERO_FCI
              ,PCEMBALAGEM.CODAUXILIAR AS COD_AUXILIAR_EMBALAGEM
              ,PCMOVCOMPLE.NUMDRAWBACK AS NUMERO_DRAWBACK
              ,ROUND(ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)), 2) *
                            (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                            (NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) / 100), 2)
               AS VALORICMSDIF
              ,NVL(PCMOV.PERCDESCICMSDIF, NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,0)) AS ALIQUOTAICMSDIF
              ,ROUND(PCMOV.QTCONT * PCMOVCOMPLE.VLICMSDESONERACAO, 2) AS VLICMSDESONERACAO
              ,PCMOVCOMPLE.CODMOTIVOICMSDESONERADO AS CODMOTIVOICMSDESONERADO
              ,0 AS VALOR_IPI_OUTROS
              ,PCNFENT.TIPOPRESENCAADQUIRINTE TIPO_PRESENCA_ADQUIRINTE
              ,PCMOVCOMPLE.CODCEST
              ,PCMOVCOMPLE.CODENQIPI CODENQUADRAMENTOIPI
              ,PCCFO.CODOPER CODOPERCFOP
              ,nvl(PCMOVCOMPLE.ALIQFCP, 0) as ALIQFCPPART
              ,nvl(PCMOVCOMPLE.ALIQINTERNADEST, 0) as ALIQINTERNADEST
              ,nvl(PCMOVCOMPLE.ALIQINTERORIGPART, 0) as ALIQINTERORIGPART
              ,ROUND(PCMOV.QTCONT * nvl(PCMOVCOMPLE.VLFCPPART, 0),2) as VLFCPPART
              ,ROUND(PCMOV.QTCONT * nvl(PCMOVCOMPLE.VLBASEPARTDEST, 0),2) as VLBASEPARTDEST
              ,nvl(PCMOVCOMPLE.PERCPROVPART,0) as PERCPROVPART
              ,ROUND(PCMOV.QTCONT * nvl(PCMOVCOMPLE.VLICMSDIFALIQPART, 0),2) as VLICMSDIFALIQPART
              ,ROUND(PCMOV.QTCONT * nvl(PCMOVCOMPLE.VLICMSPARTDEST, 0),2) as VLICMSPARTDEST
              ,ROUND(PCMOV.QTCONT * nvl(PCMOVCOMPLE.VLICMSPARTREM, 0),2) as VLICMSPARTREM
              ,PCFILIAL.CODIGO AS CODFILIAL
              ,NVL(PCNFENT.TIPOVIATRANSPORTE, 0) AS VIASTRANSP
              ,CASE WHEN ((NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', PCFILIAL.CODIGO),'N') = 'S') AND
                          (PCNFENT.TIPODESCARGA = 'N')) THEN
                    DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_AFRMM', PCFILIAL.CODIGO),'N'), 'N',
                           ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLAFRMM, 0),2), 0)
               ELSE
                    0
               END AS VLAFRMM
              ,PCNFENT.FINALIDADENFE
              ,NVL(PCPRODUT.REGISTROMSMED, PCPRODUT.ANVISA) AS PROD_ANVISA
              ,NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') PROD_RASTREADO
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0),2) VLBASEFCPICMS
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPST, 0),2) VLBASEFCPST
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBCFCPSTRET, 0),2) VLBCFCPSTRET
              ,NVL(PCMOVCOMPLE.PERFCPSTRET, 0) PERFCPSTRET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFCPSTRET, 0),2) VLFCPSTRET
              ,NVL(PCMOVCOMPLE.PERFCPSN, 0) PERFCPSN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLCREDFCPICMSSN, 0),2) VLCREDFCPICMSSN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFECP, 0),2) VLFECP
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0),2) VLACRESCIMOFUNCEP
              ,NVL(PCMOVCOMPLE.PERACRESCIMOFUNCEP, 0) AS PERACRESCIMOFUNCEP
              ,NVL(PCMOVCOMPLE.ALIQICMSFECP, 0) AS ALIQICMSFECP
              ,PCMOVCOMPLE.CODBENEFICIOFISCAL AS COD_BENEFICIO_FISCAL
              ,NVL(PCMOVCOMPLE.INDESCALARELEVANTE, PCPRODFILIAL.INDESCALARELEVANTE) AS INDESCALARELEVANTE
              ,PCMOVCOMPLE.CODAGREGACAO AS COD_AGREGACAO
              ,PCMOVCOMPLE.CNPJFABRICANTE AS CNPJ_FABRICANTE
              ,NVL(PCMOVCOMPLE.DESCANP, PCPRODUT.DESCANP) AS DESC_ANP
              ,NULL AS ISENTO_ICMS_UF_DEST
              ,NVL(PCPRODUT.TIPOPROD, 0) AS MIUDEZA
              ,NVL(PCMOVCOMPLE.PGLP, NVL(PCPRODUT.pGLP, 0)) AS PERCENTUAL_GLP
              ,NVL(PCMOVCOMPLE.PGNN, NVL(PCPRODUT.PGNN, 0)) AS PERC_GAS_NATURAL_NACIONAL
              ,NVL(PCMOVCOMPLE.PGNI, NVL(PCPRODUT.PGNI, 0)) AS PERC_GAS_NATURAL_IMPORTADO
              ,NVL(PCMOVCOMPLE.VPART, NVL(PCPRODUT.VPART, 0)) AS VALOR_PARTIDA
              ,NVL((SELECT PRIORIDADE FROM PCPRIORIDADEPRODDANFE WHERE CODPRIORIDADE = PCPRODFILIAL.CODCADPRIORIDADE), 0) AS COD_PRIORIDADE_IMPRESSAO
              ,PCMOV.NUMNOTA
              ,NVL(PCMOVCOMPLE.PERCREDBASEEFET, 0) AS PERCREDBASEEFET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEEFET, 0),2) VLBASEEFET
              ,NVL(PCMOVCOMPLE.PERCICMSEFET, 0) AS PERCICMSEFET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSEFET, 0),2) VLICMSEFET
              ,NVL(PCMOVCOMPLE.ALIQICMS1RET, 0) + NVL(PCMOVCOMPLE.PERFCPSTRET, 0) AS PERCSTRET
              ,NVL(PCMOVCOMPLE.CODMOTISENCAOANVISA, PCPRODUT.CODMOTISENCAOANVISA) AS MOTIVO_ISENCAO_ANVISA
              ,DECODE(NVL(PCNFENT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.VLICMSBCR, 0) * PCMOV.QTCONT),0) AS VLICMSBCR
               --PCEST TEMPORARIO
              ,0 AS BASEBCR_PCEST
              ,0 AS PERCSTRET_PCEST
              ,0 AS VLICMSBCR_PCEST
              ,0 AS STBCR_PCEST
              ,0 AS VLBCFCPSTRET_PCEST
              ,0 AS PERFCPSTRET_PCEST
              ,0 AS VLFCPSTRET_PCEST
              ,NULL AS VLAPROXTRIB
              ,PCMOVCOMPLE.MOTREDADREM
              ,NVL(PCMOVCOMPLE.ADREMICMS, 0) AS ADREMICMS
              ,NVL(PCMOVCOMPLE.ADREMICMSRETEN, 0) AS ADREMICMSRETEN
              ,NVL(PCMOVCOMPLE.PREDADREM, 0) AS PREDADREM
              ,NVL(PCMOVCOMPLE.ADREMICMSDIF, 0) AS ADREMICMSDIF
              ,NVL(PCMOVCOMPLE.ADREMICMSRET, 0) AS ADREMICMSRET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONO, 0),2) AS QBCMONO
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONO, 0),2) AS VICMSMONO
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONORETEN, 0),2) AS QBCMONORETEN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONORETEN, 0),2) AS VICMSMONORETEN
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONODIF, 0),2) AS QBCMONODIF
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONODIF, 0),2) AS VICMSMONODIF
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QBCMONORET, 0),2) AS QBCMONORET
              ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSMONORET, 0),2) AS VICMSMONORET              
              ,PCPRODUT.OBSCONTXCAMPO
              ,PCPRODUT.OBSCONTXTEXTO
              ,PCPRODUT.OBSFISCOXCAMPO
              ,PCPRODUT.OBSFISCOXTEXTO
        FROM   PCMOV
              ,PCNFENT
              ,PCPRODUT
              ,PCFORNEC
              ,PCEMBALAGEM
              ,PCCONSUM
              ,PCFILIAL
              ,PCSECAO
              ,PCDEPTO
              ,PCMARCA
              ,PCTABPR
              ,PCCLIENT
              ,PCMOVCOMPLE
              ,PCEQUIPAMENTO
              ,PCPRODFILIAL
              ,PCCFO
        WHERE  PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
        AND    PCMOV.CODCLI = PCCLIENT.CODCLI(+)
        AND    PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
        AND    PCMOV.CODEQUIPAMENTO = PCEQUIPAMENTO.CODEQUIPAMENTO(+)
        AND    PCMOV.NUMNOTA = PCNFENT.NUMNOTA
        AND    PCMOV.CODPROD = PCPRODUT.CODPROD
        AND    PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)
        AND    PCMOV.CODPROD = PCTABPR.CODPROD(+)
        AND    PCMOV.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR(+)
        AND    PCMOV.CODPROD = PCEMBALAGEM.CODPROD(+)
        AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCFILIAL.CODIGO
        AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+)
        AND    PCMOV.NUMREGIAO = PCTABPR.NUMREGIAO(+)
        AND    PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC(+)
        AND    PCPRODUT.CODSEC = PCSECAO.CODSEC(+)
        AND    PCPRODUT.CODEPTO = PCDEPTO.CODEPTO(+)
        AND    PCMOV.CODPROD = PCPRODFILIAL.CODPROD(+)
        AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCPRODFILIAL.CODFILIAL(+)
        AND    PCMOV.QTCONT > 0
        AND    PCNFENT.ESPECIE IN ('NF', 'NE', 'EI')
        AND    ((NVL(PCNFENT.GERANFDEVCLI, 'N') = 'S'
        AND      NVL(PCNFENT.GERANFVENDA, 'N') = 'N')
         OR     (NVL(PCNFENT.GERANFVENDA, 'N') = 'S'
        AND      (PCNFENT.TIPODESCARGA IN ('N', '6'))))
        AND    PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
        AND   PCMOV.CODFISCAL = PCCFO.CODFISCAL(+))
ORDER  BY NUMSEQ