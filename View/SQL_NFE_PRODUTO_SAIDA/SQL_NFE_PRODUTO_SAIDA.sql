CREATE OR REPLACE VIEW SQL_NFE_PRODUTO_SAIDA AS
SELECT ALIQUOTA_COFINS
      ,CASE WHEN SITUACAO_TRIBUTARIA = '51' AND ALIQUOTAICMSDIF >= 100 THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', ALIQUOTA_ICMS, 0)
       ELSE
         ALIQUOTA_ICMS
       END ALIQUOTA_ICMS
      ,ALIQUOTA_IPI
      ,ALIQUOTA_PIS
      ,ALIQUOTA_ST
      ,ALIQUOTA_CREDITO_SN
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100)) THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', BASE_ICMS, 0)
       ELSE
         BASE_ICMS
       END BASE_ICMS
      ,BASE_IPI
      ,BASE_ST
      ,BASE_II
      ,BASEBCR
      ,CFOP
      ,CLASSIFICFISCAL
      ,CODFILIALRETIRA
      ,COD_OPERACAO
      ,CODIGO_FABRICANTE
      ,CODIGO_SECAO
      ,CODIGO_DEPARTAMENTO
      ,CODIGO_FORNECEDOR
      ,CODPROD
      ,CODIGO_PRODUTO
      ,CODST
      ,DATA_FABRICACAO
      ,DATA_VALIDADE
      ,DESCRICAO_DEPARTAMENTO
      ,DESCRICAO_SECAO
      ,DIGITO_PRODUTO
      ,EAN
      ,EAN_UNIDADE
      ,EMBALAGEM
      ,EMBALAGEMMASTER
      ,EXTIPI
      ,FANTASIA
      ,FATORUNFARM
      ,FORNECEDOR
      ,GENERO
      ,INFO_TECNICA
      ,MARCA
      ,MODALIDADE_BC_ICMS
      ,MODALIDADE_BC_ST
      ,NATUREZAPRODUTO
      ,NCM
      ,NUM_TRANSACAO
      ,NUMERO_ADICAO
      ,NUMERO_LOTE
      ,NUMERO_SEQUENCIA
      ,NUMORIGINAL
      ,NUMERO_PEDIDO
      ,NUMERO_ITEM_PEDIDO
      ,NUMVOLUMESCONFERENCIA
      ,ORIGEM_MERCADORIA
      ,PERACRESCIMOCUSTO
      ,PERCDESC
      ,PERCENTUAL_MARGEM
      ,PERCENTUAL_REDUCAO_BC
      ,PERCENTUAL_REDUCAO_ST
      ,PERCIPIVENDA
      ,PESO_BRUTO
      ,PESOCX
      ,PESOEMBALAGEM
      ,PRECO_MAXIMO
      ,PRINCIPIOATIVO
      ,PRODUTO
      ,PTABELA
      ,PUNITCONT
      ,QT_LOTE
      ,QTCX
      ,QTD_CAIXA
      ,QTD_UNIDADE
      ,QTD_CAIXAS_MASTER
      ,QTD_PECAS_INTERM
      ,QTPECAS
      ,QTUN
      ,QTUNIT
      ,QTUNITCX
      ,QTUNITEMB
      ,QTD_EMBALAGEM
      ,UNIDADE_LICIT
      ,QT_UNIT_LICIT
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
            0
       ELSE
            CASE WHEN UNIDADE_LICIT IS NOT NULL THEN
              ROUND(QUANTIDADE * QT_UNIT_LICIT, 4)
            ELSE
              CASE WHEN (USAUNIDADEMASTER = 'S') AND (QTD_MASTER > 0) THEN
                   ROUND(QUANTIDADE / QTD_MASTER, 4)
              ELSE
                   ROUND(QUANTIDADE, 4)
            END END
       END AS QUANTIDADE_COMERCIAL
      ,QUANTIDADE_ENTREGA
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
            0
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                ROUND((QUANTIDADE * FATOR_CONVERSAO), 4)
            ELSE
               /*REMOVI ESTA ALTERAÇÃO QUE FOI FEITA NA ULTIMA VERSÃO, PORQUE ESTAVA CAUSANDO
                PROBLEMAS NOS CLIENTES, REJEITANDO AS NOTAS PELO ERRO 630 DEVIDO AO FATO DE ESTAR
                ALTERANDO A QUANTIDADE TRIBUTAVEL, COM ISSO A MULTIPLICAÇÃO FICARA ERRADA.
                OBS.: A QUANTIDADE TRIBUTAVEL DEVE SER SEMPRE A MENOR UNIDADE DO WINTHOR
                CASE WHEN (USAUNIDADEMASTER = 'S') AND (QTD_MASTER > 0) THEN
                   ROUND(QUANTIDADE / QTD_MASTER, 4)
                ELSE
                   ROUND(QUANTIDADE, 4)
                END*/
                ROUND(QUANTIDADE, 4)
            END
       END AS QUANTIDADE_TRIBUTAVEL
     ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
            0
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO_EX,0) > 0 THEN
                 ROUND((QUANTIDADE * FATOR_CONVERSAO_EX), NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4))
            ELSE
                 CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                     ROUND((QUANTIDADE * FATOR_CONVERSAO), NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4))
                 ELSE
                     ROUND(QUANTIDADE, 4)
                 END
            END
       END AS QUANTIDADE_TRIBUTAVEL_EX
      ,RETIDO
      ,SIT_PIS_CONFINS
      ,SITUACAO_TRIBUTARIA
      ,SITUACAO_TRIBUTARIA_IPI
      ,STBCR
      ,STCLIENTEGNRE
      ,TIPO_QUANTIDADE
      ,TIPOESTOQUE
      ,TIPOMERC
      ,TIPOTRIBUTMEDIC
      ,TIPOSEPARACAO
      ,TOTPESOLIQUNIT
      ,UNIDADE AS UNIDADE_COMERCIAL
      ,CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
            UNIDADE_TRIB
       ELSE
            UNIDADE
       END AS UNIDADE_TRIBUTAVEL
     ,CASE WHEN NVL(FATOR_CONVERSAO_EX,0) > 0 THEN
            UNIDADE_TRIB_EX
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                 UNIDADE_TRIB
            ELSE
                 UNIDADE
            END
       END AS UNIDADE_TRIBUTAVEL_EX
      ,UNIDADEMASTER
      ,UNIDADE_EMBALAGEM
      ,VALOR_COFINS
      ,CASE WHEN (UNIDADE_LICIT IS NOT NULL) AND (QT_UNIT_LICIT > 0) THEN
         ROUND((VALOR_LIQUIDO / QT_UNIT_LICIT),10)
       ELSE
       CASE WHEN USAUNIDADEMASTER = 'S' THEN
         CASE WHEN (abs(ROUND(QTCONT * VALOR_LIQUIDO ,2) -
                     ROUND(ROUND(QUANTIDADE / QTD_MASTER, 4) * ROUND((VALOR_LIQUIDO * QTD_MASTER),10),2)) >= 0.01) AND (ROUND(QUANTIDADE * QTD_MASTER,4) > 0) THEN
                     ROUND(ROUND(QTCONT * VALOR_LIQUIDO,2) / ROUND(QUANTIDADE / QTD_MASTER, 4), 10)
         ELSE
           ROUND((VALOR_LIQUIDO * QTD_MASTER),10)
         END
       ELSE
         CASE WHEN (abs(round(QTCONT * VALOR_LIQUIDO,2) -
                      ROUND(ROUND(QUANTIDADE,4) * VALOR_LIQUIDO,2)) >= 0.01) AND (ROUND(QUANTIDADE,4) > 0) THEN
             ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE,4), 10)
         ELSE
             VALOR_LIQUIDO
         END
       END END VALOR_COMERCIAL
      ,VALOR_DESCONTO
      ,VALOR_DESCONTO_ADICAO
      ,VALOR_FRETE
      ,VALOR_ICMS
      ,VALOR_CREDITO_ICMS_SN
      ,VALOR_IPI
      ,VALOR_IPI_UNIDADE
      ,VALOR_LIQUIDO
      ,VALOR_PIS
      ,ROUND(DECODE(NVL(VALOR_LIQUIDO,0), 0, 0, QTCONT) * VALOR_LIQUIDO,2) AS VALOR_PRODUTOS
      ,VALOR_SEGURO
      ,VALOR_OUTROS
      ,VALOR_ST
      ,DECODE(COD_OPERACAO,'SD', VALOR_UNITARIO, 'SO', VALOR_UNITARIO, VALOR_TOT_EMBALAGEM) AS VALOR_TOT_EMBALAGEM
      ,VALOR_UN_EMBALAGEM
      ,VALOR_II
      ,VALOR_DESPESA_ADUANEIRA
      ,VALOR_IOF
      ,CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
            ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE * FATOR_CONVERSAO,4),10)
       ELSE
            CASE WHEN (abs(round(QTCONT * VALOR_LIQUIDO,2) -
                    ROUND(ROUND(QUANTIDADE,4) * VALOR_LIQUIDO,2)) >= 0.01) AND (ROUND(QUANTIDADE,4) > 0) THEN
                ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE,4), 10)
            ELSE
                VALOR_LIQUIDO
            END
       END AS VALOR_TRIBUTAVEL
     ,CASE
         WHEN (ROUND(QUANTIDADE * FATOR_CONVERSAO_EX, NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4)) > 0) then
          CASE
            WHEN NVL(FATOR_CONVERSAO_EX, 0) > 0 THEN
             ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE * FATOR_CONVERSAO_EX, NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4)), 10)
            ELSE
             CASE
               WHEN NVL(FATOR_CONVERSAO, 0) > 0 THEN
                ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE * FATOR_CONVERSAO, 4), 10)
               ELSE
                CASE
                  WHEN (abs(round(QTCONT * VALOR_LIQUIDO, 2) -
                            ROUND(ROUND(QUANTIDADE, 4) * VALOR_LIQUIDO, 2)) >= 0.01) AND
                       (ROUND(QUANTIDADE, 4) > 0) THEN
                   ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE, 4), 10)
                  ELSE
                   VALOR_LIQUIDO
                END
             END
          END
         ELSE
          VALOR_LIQUIDO
       END AS VALOR_TRIBUTAVEL_EX
      ,VL_BASE_CONFINS
      ,VL_BASE_PIS
      ,VLBASEGNRE
      ,VLIPIPORKGVENDA
      ,VOLUME
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
      ,VLDESCSEMABATIMENTO
      ,VLABATIMENTO
      ,CODIGOANP
      ,VLTOTALIMPOSTOS
      ,NUMERO_FCI
      ,ALIQ_INSENCAO_ICMS
      ,VALOR_ISENCAO_ICMS
      ,COD_AUXILIAR_EMBALAGEM
      ,VLTOTALIMPOSTOSFEDERAL
      ,VLTOTALIMPOSTOSESTADUAL
      ,VLTOTALIMPOSTOSMUNICIPAL
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100)) THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', VALORICMSDIF, 0)
       ELSE
         VALORICMSDIF
       END VALORICMSDIF
      ,ALIQUOTAICMSDIF
      ,VLICMSDESONERACAO VALOR_ICMS_DESONERADO
      ,CODMOTIVOICMSDESONERADO COD_MOTIVO_DESONERACAO
      ,VICMSSTDESON VALOR_ICMS_ST_DESONERADO
      ,VALOR_IPI_OUTROS
      ,CASE WHEN (SITUACAO_TRIBUTARIA = '51') THEN
           VALOR_ICMS_OPERACAO  - VALORICMSDIF --Regra modificada a pedido do Lucas dia 30/03/2016
       ELSE
         CASE WHEN VALORICMSDIF  >= VALOR_ICMS THEN
           0
         ELSE
           VALOR_ICMS
         END
       END VALOR_ICMS_DEVIDO
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100)) THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', VALOR_ICMS_OPERACAO, 0)
       ELSE
         VALOR_ICMS_OPERACAO
       END VALOR_ICMS_OPERACAO
      ,TIPO_PRESENCA_ADQUIRINTE
      ,NUMERO_DRAWBACK
      ,CODCEST
      ,CODENQUADRAMENTOIPI
      ,(BASE_ICMS / QUANTIDADE) AS BASE_ICMS_UNITARIO
      ,NUMCHAVEEXP
      ,NUMREGEXP
      ,ALIQFCPPART
      ,ALIQINTERNADEST
      ,ALIQINTERORIGPART
      ,DECODE(ISENTO_ICMS_UF_DEST, 'S',0,VLFCPPART) VLFCPPART
      ,VLBASEPARTDEST
      ,PERCPROVPART
      ,VLICMSDIFALIQPART
      ,DECODE(ISENTO_ICMS_UF_DEST, 'S',0,VLICMSPARTDEST) AS VLICMSPARTDEST
      ,DECODE(ISENTO_ICMS_UF_DEST, 'S',0,VLICMSPARTREM) AS VLICMSPARTREM
      ,VIASTRANSP
      ,VLAFRMM
      ,PROD_ANVISA
      ,PROD_RASTREADO
      ,VLBASEFCPICMS
      ,VLBASEFCPST
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLBCFCPSTRET
       END AS VLBCFCPSTRET
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         PERFCPSTRET
       END AS PERFCPSTRET
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLFCPSTRET
       END AS VLFCPSTRET
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
      ,DATACONSOLIDACAOPREFAT
      ,PREFATURAMENTO
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
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLBCFCPSTRET_PCEST
       END AS VLBCFCPSTRET_PCEST
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         PERFCPSTRET_PCEST
       END AS PERFCPSTRET_PCEST
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLFCPSTRET_PCEST
       END AS VLFCPSTRET_PCEST,
       VLAPROXTRIB
       ,GERAGRPRETTRIB 
       ,VLPISRETORGPUB
       ,VLCOFINSRETORGPUB
       ,VLCSLLRETORGPUB
       ,VLIRPJRETORGPUB
       ,VLBCIRRFRETORGPUB             
       ,EXCLUIRICMSBASEPISCOFINS
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
       ,SOMARVALORDIFBCICMS
       ,VLFCPDIF
       ,INDDEDUZDESONERACAO
       ,NUMTRANSITEM
FROM   (SELECT PCMOV.NUMTRANSVENDA AS NUM_TRANSACAO
              ,PCMOV.CODPROD
              ,PCNFSAID.FINALIDADENFE
              --Melhoria HIS.03196.2014 - Eddy
              --,DECODE(PCMOV.CODOPER, 'SD', DECODE(PCNFSAID.NUMTAB, 1, 'S', PCMOVCOMPLE.USAUNIDADEMASTER), PCMOVCOMPLE.USAUNIDADEMASTER) AS USAUNIDADEMASTER
              ,CASE WHEN (PCMOV.CODOPER = 'SD') THEN
                     CASE WHEN (NVL(PCMOV.TIPOEMBALAGEMPEDIDO, 'X') = 'X') THEN
                         DECODE(PCNFSAID.NUMTAB, 1, 'S', NVL(PCMOVCOMPLE.USAUNIDADEMASTER, 'N'))
                     ELSE
                         DECODE(NVL(PCMOV.TIPOEMBALAGEMPEDIDO, 'X'), 'M', 'S', NVL(PCMOVCOMPLE.USAUNIDADEMASTER,'N'))
                     END
               ELSE
                 NVL(PCMOVCOMPLE.USAUNIDADEMASTER, 'N')
               END AS USAUNIDADEMASTER
              ,CASE WHEN (PCMOV.CODOPER = 'SD') THEN
                  DECODE(NVL(PCMOVCOMPLE.FATORENT, 0), 0, NVL(PCMOV.QTUNITCX, PCPRODUT.QTUNITCX), PCMOVCOMPLE.FATORENT)
                 ELSE
                  NVL(PCMOV.QTUNITCX, PCPRODUT.QTUNITCX)
               END AS QTD_MASTER
              ,NVL(TRIM(PCMOV.CODINTERNO), TO_CHAR(PCMOV.CODPROD)) AS CODIGO_PRODUTO
              ,PCPRODUT.UNIDADETRIB AS UNIDADE_TRIB
              ,PCPRODUT.FATORCONVTRIB AS FATOR_CONVERSAO
              ,NVL(PCMOVCOMPLE.UNIDADETRIBEX, PCPRODUT.UNIDADETRIBEX) AS UNIDADE_TRIB_EX
              ,ROUND(NVL(PCMOVCOMPLE.FATORCONVTRIBEX, PCPRODUT.FATORCONVTRIBEX), 6) AS FATOR_CONVERSAO_EX
              ,PCMOV.CODST AS CODST
              ,PCMOV.CODOPER AS COD_OPERACAO
              ,PCMOV.CODFILIALRETIRA
              ,CASE WHEN LENGTH(NVL(PCPRODUT.CODAUXILIAR, '')) IN (NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      CASE WHEN (PCMOVCOMPLE.USAUNIDADEMASTER = 'S') THEN
                         TO_CHAR(PCPRODUT.CODAUXILIAR2)
                      ELSE
                         TO_CHAR(PCPRODUT.CODAUXILIAR)
                      END
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR) < NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      CASE WHEN (PCMOVCOMPLE.USAUNIDADEMASTER = 'S') THEN
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR2), PCPRODUT.GTINCODAUXILIAR2,'0')
                      ELSE
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
                      END
                ELSE
                  NULL
               END AS EAN
              ,PCMOV.DV AS DIGITO_PRODUTO
              ,(NVL(TRIM(PCMOV.PRODDESCRICAOCONTRATO),
                    NVL(TRIM(PCMOV.COMPLEMENTO), TRIM(PCMOV.DESCRICAO))) || ' ' ||
                    CASE WHEN LENGTH(PCPRODUT.SUBSTANCIA) > 0 THEN
                        '('||PCPRODUT.SUBSTANCIA||')' ELSE '' END ||
               DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE, 'N'),
                       'S',
                       DECODE(NVL(PCMOVCOMPLE.USAUNIDADEMASTER, 'N'),
                              'S',
                              PCPRODUT.EMBALAGEMMASTER,
                              DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),
                                      'N',
                                      PCMOV.EMBALAGEM,
                                      (PCEMBALAGEM.EMBALAGEM || ' QTD. ' ||
                                       LTRIM(to_char((PCMOV.QTCONT /
                                      DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                                   0),
                                               0,
                                               1,
                                               PCEMBALAGEM.QTUNIT)),'999999999999999990.99')) || ' ' ||
                                      PCEMBALAGEM.UNIDADE || ' '))))) AS PRODUTO
              ,NVL(PCPRODUT.NATUREZAPRODUTO,
                   'X') AS NATUREZAPRODUTO
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
              --148.058921.2015 PERMITEINFOLEITRANSPCONSFINAL
              ,NVL(PCPRODFILIAL.INFTECNICA, '') || ' ' ||
               CASE WHEN (NVL(PCMOVCOMPLE.ENVIARALIQREDUCAOPISCOFINS,'N') = 'S') THEN
                    ';%Red.Aliq.PIS ' || LTRIM(to_char(NVL(PCMOVCOMPLE.ALIQREDUCAOPIS,0),'999999999999999990.99')) ||
                    ';%Red.Aliq.COFINS ' || LTRIM(to_char(NVL(PCMOVCOMPLE.ALIQREDUCAOCOFINS,0),'999999999999999990.99'))
               END
               || ' ' ||DECODE(LENGTH(NVL(TRIM(PCMOVCOMPLE.CODBENEFICIOFISCALCOMPLE),'')),'','','cBenef: '||TRIM(PCMOVCOMPLE.CODBENEFICIOFISCALCOMPLE))|| ' ' ||
               ---------MELHORIA HIS.01182.2016 - EDDY
               CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIAINFOLOTENFE', PCMOV.CODFILIAL), 'S') = 'S') THEN
                 TRIM((DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                             '')),
                                  0),
                              0,
                              '',
                              ' N LT. ') || TRIM(PCMOV.NUMLOTE) || ' ' ||
                 DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                             '')),
                                  0),
                              0,
                              '',
                              ' DATA FAB.: ') ||
                 (SELECT TRUNC(NVL(PCMOV.DATAFABRICACAO, PCLOTE.DATAFABRICACAO)) AS DATAFABRICACAO
                  FROM   PCLOTE
                  WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                  AND    PCLOTE.CODFILIAL = NVL(PCMOV.CODFILIALRETIRA,PCMOV.CODFILIAL)
                  AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                  AND    ROWNUM = 1) || ' ' ||
                  DECODE(NVL(LENGTH(NVL(TRIM(PCMOV.NUMLOTE),
                                             '')),
                                0),
                            0,
                            '',
                            ' DATA VAL.: ') || (SELECT TRUNC(NVL(PCMOV.DATAVALIDADE, PCLOTE.DTVALIDADE)) AS DTVALIDADE
                FROM   PCLOTE
                WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
                AND    PCLOTE.CODFILIAL = NVL(PCMOV.CODFILIALRETIRA,PCMOV.CODFILIAL)
                AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
                AND    ROWNUM = 1)))
              ELSE
                 ''
              END
              ------------------
              ||' '||
              TRIM((
                CASE WHEN (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIADADOSSECSAUDE', NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)) = 'S') THEN
                  ('Cód. Registro Médico: '|| PCPRODUT.REGISTROMSMED || ' ' ||
                   'Marca: '||PCMARCA.MARCA || ' ' ||
                   (SELECT 'Princípio Ativo: '|| PCPRINCIPATIVO.DESCRICAO
                    FROM   PCPRINCIPATIVO
                    WHERE  PCPRINCIPATIVO.CODPRINCIPATIVO = PCPRODUT.CODPRINCIPATIVO))
                ELSE
                  ''
                END
               ||' '||
                  DECODE(NVL(PCPRODUT.ENVIAINFTECNICANFE, 'S'),'S', PCPRODUT.INFORMACOESTECNICAS, NULL) ||
                    ---
                     (SELECT DECODE(TO_CHAR(MAX(PCCERTIFIC.CODCERTIFIC)), '', '', ' - ' || 'CERTIFIC.: ' || to_char(MAX(PCCERTIFIC.CODCERTIFIC)) || ' ' || MAX(PCCERTIFIC.MENSAGEMNF))
                        FROM PCCERTIFIC
                       WHERE 1=1
                         AND PCMOV.CODPROD = PCCERTIFIC.CODPROD
                         AND PCMOV.CODFILIAL = PCCERTIFIC.CODFILIAL
                        --esta clausula serve para pegar sempre o certificado mais atual
                         AND TRUNC(PCCERTIFIC.DTVENC) = (SELECT TRUNC(MAX(F1.DTVENC)) FROM PCCERTIFIC F1
                                                          WHERE F1.CODPROD = PCCERTIFIC.CODPROD
                                                            AND F1.CODFILIAL = PCCERTIFIC.CODFILIAL
                                                            AND NVL(F1.NUMLOTE,0) = NVL(PCCERTIFIC.NUMLOTE,0)))
                    ----
                    )
                    || ' ' ||
                    DECODE(NVL(LENGTH(NVL(PCMOV.REFCOR,'')),0),0,'','REF.DA COR: ' || PCMOV.REFCOR) ||
                    CASE WHEN (PCPRODUT.OBS = 'EQ' AND PCEQUIPAMENTO.IDPATRIMONIO IS NOT NULL) THEN
                      CASE WHEN (PCMOV.CODOPER = 'SO' OR PCMOV.CODOPER = 'SD') THEN
                          'ID.EQUIP.:'|| PCEQUIPAMENTO.IDPATRIMONIO || ' ' ||
                          'COD.EQUIP.: ' || PCEQUIPAMENTO.CODEQUIPAMENTO || ' ' ||
                          'MARCA EQUIP.: ' || PCEQUIPAMENTO.MARCA || ' ' ||
                          'VOLT.EQUIP.: ' || PCEQUIPAMENTO.VOLTAGEM
                      END
                    ELSE '' END || CASE WHEN (NVL(PCMOV.VOLUMEDESEJADO,0) > 0) THEN ' - ' || PCMOV.VOLUMEDESEJADO ||' ML' ELSE '' END
                    ||
            CASE WHEN (PCMOVCOMPLE.NUMFCI IS NOT NULL) AND (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('NUMFCIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                ' PERC.PARC.FCI: ' || NVL(PCMOVCOMPLE.percconteudoimpfci, 0) ||
                ' - N. FCI: ' || PCMOVCOMPLE.numfci
            ELSE
                ''
            END || ' ' ||
            CASE WHEN NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0) > 0 THEN
                  ' VBCFCP: ' || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPICMS, 0),2),'999999999999999990.99')) ||
                  ' PFCP: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.PERACRESCIMOFUNCEP, 0),'999999999999999990.99')) ||
                  ' VFCP: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0),2),'999999999999999990.99'))
             END ||
             CASE WHEN NVL(PCMOVCOMPLE.VLFECP, 0) > 0 THEN
                  ' VBCFCPST: ' || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEFCPST, 0),2),'999999999999999990.99')) ||
                  ' PFCPST: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.ALIQICMSFECP, 0),'999999999999999990.99')) ||
                  ' VFCPST: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFECP, 0),2),'999999999999999990.99'))
             END ||
             CASE WHEN ((NVL(PCMOV.SITTRIBUT, '55') IN ('60','500')) AND (SQL_NFE_CABECALHO_SAIDA.CONTRIBUINTE = 'S')) THEN
                 CASE WHEN NVL(PCMOVCOMPLE.VLFCPSTRET, 0) > 0 THEN
                      ' VBCFCPSTRET: ' || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBCFCPSTRET, 0),2),'999999999999999990.99')) ||
                      ' PFCPSTRET: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLE.PERFCPSTRET, 0),'999999999999999990.99')) ||
                      ' VFCPSTRET: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFCPSTRET, 0),2),'999999999999999990.99'))
                 WHEN NVL(PCEST.VLFCPSTRET, 0) > 0 THEN
                      ' VBCFCPSTRET: ' || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCEST.VLBCFCPSTRET, 0),2),'999999999999999990.99')) ||
                      ' PFCPSTRET: '   || TRIM(TO_CHAR(NVL(PCEST.PERFCPSTRET, 0),'999999999999999990.99')) ||
                      ' VFCPSTRET: '   || TRIM(TO_CHAR(ROUND(PCMOV.QTCONT * NVL(PCEST.VLFCPSTRET, 0),2),'999999999999999990.99'))
                 END
             END ||
             CASE WHEN (PARAMFILIAL.OBTERCOMOVARCHAR2('GERACHAVEULTENTINFADPRODNFE',
                                                      NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)) = 'S') THEN
                (SELECT ' CHAVE ULTIMA ENTRADA: ' || TRIM(PCNFENT.CHAVENFE)
                   FROM PCNFENT, PCEST
                  WHERE PCEST.CODFILIAL = NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)
                    AND PCEST.CODPROD = PCMOV.CODPROD
                    AND PCEST.NUMTRANSENTULTENT = PCNFENT.NUMTRANSENT
                    AND PCMOV.CODFISCAL BETWEEN 5000 AND 6999
                    AND NVL(PCMOV.ST, 0) > 0
                    AND ROWNUM = 1)
               ELSE
                ''
             END ||
             --produtos perigosos
             CASE WHEN (PCPRODUT.CODRISCO IS NOT NULL AND PCPRODUT.CODACONDICIONAMENTO IS NOT NULL AND PCPRODUT.CODONU IS NOT NULL AND (PCMOV.QTCONT * NVL(PCMOV.PESOBRUTO, 0)) > 0) THEN
                  ' PESO BRUTO DO PRODUTO PERIGOSO: ' || TRIM(TO_CHAR((PCMOV.QTCONT * NVL(PCMOV.PESOBRUTO, 0)),'999999999999999990.99')) || ' KG'
             ELSE
                  ''
             END ||
             CASE WHEN ((NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARCHAVENATURAL',NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)),'N') = 'S') AND
              (NVL(PCMOV.ST,0) + NVL(PCMOV.STBCR, 0) + NVL(PCMOV.VLDESPADICIONAL,0) > 0) ) THEN
                NVL((SELECT '##CHAVENATURAL='||
                             SUBSTR(E.CHAVENFE, 1,2)|| --UF
                             SUBSTR(E.CHAVENFE, 7,14)||--CNPJ
                             SUBSTR(E.CHAVENFE, 21,2)||--MODELO
                             SUBSTR(E.CHAVENFE, 23,3)||--SERIE
                             SUBSTR(E.CHAVENFE, 26,9) ||--NUMNOTA
                             LPAD(NVL(MCE.NUMSEQENT, ME.NUMSEQ),3,'0')|| '##' AS CHAVENATURAL
                      FROM PCNFENT E,
                           PCMOV ME,
                           PCMOVCOMPLE MCE,
                           PCEST
                      WHERE 1=1
                       AND E.NUMTRANSENT = ME.NUMTRANSENT
                       AND E.NUMNOTA = ME.NUMNOTA
                       AND ME.NUMTRANSITEM = MCE.NUMTRANSITEM
                       AND ME.CODPROD = PCMOV.CODPROD
                       AND PCMOV.CODFISCAL BETWEEN 5000 AND 6999
                       AND (NVL(PCMOV.ST,0) + NVL(PCMOV.STBCR, 0) + NVL(PCMOV.VLDESPADICIONAL,0)) > 0
                       AND PCEST.NUMTRANSENTULTENT = E.NUMTRANSENT
                       AND PCEST.CODFILIAL = NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)
                       AND PCEST.CODPROD = PCMOV.CODPROD
                       AND ROWNUM = 1), PCPRODFILIAL.CHAVENATURAL)
               END ||
             CASE WHEN ((NVL(PCMOV.SITTRIBUT, '55') = '61') AND 
                        (NVL(PCMOVCOMPLE.VICMSMONORET, 0) > 0) AND 
                        (SQL_NFE_CABECALHO_SAIDA.CONSUMIDOR_FINAL = 'S') AND
                        (SQL_NFE_CABECALHO_SAIDA.CONTRIBUINTE = 'N')) THEN
                  ' ICMS monofásico sobre combustíveis cobrado anteriormente conforme Convênio ICMS 199/2022.'
             END
            ) AS INFO_TECNICA
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
            ,REPLACE(PCMOV.NBM, '.', '') AS NCM
            ,
            CASE
                WHEN (PCMOVCOMPLE.EXTIPI BETWEEN '01' AND '09') THEN
                    LPAD(TO_CHAR(PCMOVCOMPLE.EXTIPI), 2,'0')
              ELSE
            CASE
                WHEN (PCMOVCOMPLE.EXTIPI = '0') THEN
             NULL
            END
            END AS EXTIPI
            ,(SUBSTR(PCMOV.NBM,
                     1,
                     2)) AS GENERO
            ,PCMOV.CODFISCAL AS CFOP
            ,CASE
              WHEN PCMOVCOMPLE.UNIDADELICIT IS NOT NULL THEN
                   PCMOVCOMPLE.UNIDADELICIT
            ELSE
              CASE
                WHEN PCMOVCOMPLE.USAUNIDADEMASTER = 'S' THEN
                  PCPRODUT.UNIDADEMASTER
               ELSE
                 DECODE(PCMOV.CODOPER, 'SD', DECODE(CASE WHEN (NVL(PCMOV.TIPOEMBALAGEMPEDIDO, 'X') = 'X') THEN
                         DECODE(PCNFSAID.NUMTAB, 1, 'S', NVL(PCMOVCOMPLE.USAUNIDADEMASTER, 'N'))
                     ELSE
                         DECODE(NVL(PCMOV.TIPOEMBALAGEMPEDIDO, 'X'), 'M', 'S', NVL(PCMOVCOMPLE.USAUNIDADEMASTER,'N'))
                     END, 'S', PCPRODUT.UNIDADEMASTER, PCMOV.UNIDADE),PCMOV.UNIDADE)
             END END AS UNIDADE
            ,PCMOV.QTCONT AS QUANTIDADE
            ,PCMOV.QTCONT
            ,CASE
               WHEN (ORGAO_PUBLICO = 'S') THEN
                DECODE(NVL(PCNFSAID.DEDUZIRDESONERORGAOPUB, 'N'),
                      'S',
                       ROUND((PCMOV.PTABELA
                          + NVL(PCMOV.VLDESCRODAPE, 0)
                          - NVL(PCMOV.VLDESCICMISENCAO, 0)),
                          2),
                       ROUND((PCMOV.PTABELA
                          + NVL(PCMOV.VLDESCRODAPE, 0)
                          + NVL(PCMOV.VLDESCICMISENCAO, 0)),
                          2))
               ELSE
                (DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT) -
                CASE WHEN (PCMOV.CODOPER = 'SD' AND
                      NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',PCFILIAL.CODIGO),'S') = 'N') THEN
                      0
                ELSE NVL(PCMOV.ST,0) END -
                NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                     0) -
                CASE WHEN (PCMOV.CODOPER = 'SD' AND
                      NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                      0
                ELSE NVL(PCMOV.VLIPI,0) END -
                 DECODE(PCMOV.CODOPER, 'SD', NVL(PCMOV.VLFRETE,0), 0)
                 - NVL(PCMOV.VLREPASSE,0)
                      +
                DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N','',PCPRODFILIAL.PRECOUTILIZADONFE), PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                          PCFILIAL.CODIGO),
                            'L'))),
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
                                          0) - NVL(DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT),
                                                   0)) + DECODE(NVL(PCNFSAID.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, NVL(PCMOV.VLDESCICMISENCAO,0)) )) +
                NVL(PCMOV.VLDESCPISSUFRAMA,
                     0) + DECODE(PCMOV.CODOPER, 'SD', 0, NVL(PCMOV.VLDESCSUFRAMA,
                               0)) + NVL(PCMOV.VLSUFRAMA,
                                         0) +
                 NVL(PCMOV.VLDESCREDUCAOCOFINS,
                               0) + NVL(PCMOV.VLDESCREDUCAOPIS,
                                         0) )
             END AS VALOR_UNITARIO
            ,(DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'),
               'C',
               DECODE(NVL(PCMOVCOMPLE.BONIFIC,'N') , 'S', PCMOV.PBONIFIC, PCMOV.PUNITCONT),
               --não subtotaliza se não tiver impostos agregados ao valor do produto
               CASE WHEN (((NVL(PCMOV.VLIPI,0) + NVL(PCMOV.ST,0) + NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLDESCONTONF, 0)) > 0) AND (NVL(PCMOV.CODOPER, 'S') <> 'SD') ) THEN
                   ((ROUND((DECODE( NVL(PCMOVCOMPLE.BONIFIC,'N') , 'S', PCMOV.PBONIFIC, PCMOV.PUNITCONT) - NVL(PCMOV.VLIPI,0) - NVL(PCMOV.ST,0) -
                    DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0), 0, 0,NVL(PCMOVCOMPLE.VLFECP, 0))
                   ) * PCMOV. QTCONT, (CASE WHEN PCMOV.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) )) / PCMOV.QTCONT
                   + (ROUND(NVL(PCMOV.VLIPI,0) * PCMOV.QTCONT, (CASE WHEN PCMOV.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) )) / PCMOV.QTCONT
                   + (ROUND(NVL(PCMOV.ST,0) * PCMOV.QTCONT, (CASE WHEN PCMOV.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) )) / PCMOV.QTCONT
                   + (ROUND(DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0), 0, 0,NVL(PCMOVCOMPLE.VLFECP, 0)) * PCMOV.QTCONT, (CASE WHEN PCMOV.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) ))
                   / PCMOV.QTCONT)
               ELSE
                   DECODE(NVL(PCMOVCOMPLE.BONIFIC,'N') , 'S', PCMOV.PBONIFIC, PCMOV.PUNITCONT)
               END
             )
            -
           CASE WHEN (PCMOV.CODOPER = 'SD' AND
                             NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',PCFILIAL.CODIGO),'S') = 'N') THEN
                      0
                ELSE
                      DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'),
                            'C',
                            NVL(PCMOV.ST,0),
                              DECODE(PCMOV.CODOPER,
                                'SD',
                                NVL(PCMOV.ST,0),
                                ((ROUND(NVL(PCMOV.ST,0) * PCMOV.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2))) / PCMOV.QTCONT)
                              )
                            )
                END -
                (DECODE(PCNFSAID.TIPOVENDA, 'DF', NVL(PCMOV.VLSEGURO,0), 0))-
                (DECODE(NVL(PCMOVCOMPLE.VLBASEFCPST, 0), 0, 0,DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'), 'C', PCMOVCOMPLE.VLFECP, (ROUND(NVL(PCMOVCOMPLE.VLFECP, 0) * QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2))/QTCONT)) )) -
                NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR, 0) -
                CASE WHEN (PCMOV.CODOPER = 'SD' AND
                           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                      0
                ELSE
                      DECODE(NVL(PCNFSAID.FINALIDADENFE, 'N'), 'C', NVL(PCMOV.VLIPI,0), ((ROUND(NVL(PCMOV.VLIPI,0) * PCMOV.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2))) / PCMOV.QTCONT))
                END -
                --Na nfe 4.0 o ipiDevol compoe o valor total da nota, e por isso deve ser subtraido do valor do produto
                CASE WHEN (PCMOV.CODOPER = 'SD') THEN
                     (NVL(PCMOV.VLDESPDENTRONF,0) -
                      DECODE(NVL(PCMOVCOMPLE.VLIPIDEVFORNEC, 0),
                            0,
                            0,
                            NVL(PCMOVCOMPLE.VLIPIOUTRAS, 0))) + NVL(PCMOVCOMPLE.VLIPIDEVFORNEC, 0)
                ELSE
                     0
                END -
                DECODE(PCMOV.CODOPER, 'SD',NVL(PCMOV.VLFRETE,0),0) +
                NVL(PCMOV.VLDESCPISSUFRAMA,0) +
                DECODE(PCMOV.CODOPER, 'SD', 0, ROUND(NVL(PCMOV.VLDESCSUFRAMA,0) * PCMOV.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT) +
                DECODE(PCMOV.CODOPER, 'SD', 0, NVL(PCMOV.VLSUFRAMA,0))) +
                DECODE(PCMOV.CODOPER, 'SD', 0, DECODE(NVL(PCNFSAID.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, ROUND(NVL(PCMOV.VLDESCICMISENCAO,0) * PCMOV.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT )) +
                CASE WHEN ( (PCMOV.CODOPER = 'SD') AND (NVL(PCMOVCOMPLE.PERCICMSDESONERACAO,0) > 0) AND (NVL(PCMOVCOMPLE.VLICMSDESONERACAO,0) > 0) ) THEN
                   PCMOVCOMPLE.VLICMSDESONERACAO
                ELSE
                  0
                END +
             CASE WHEN (ORGAO_PUBLICO = 'S') THEN
                  0
             ELSE
                  DECODE(PCMOV.CODOPER, 'SD',
                         -- Saida de Devolu??o
                         (NVL(PCMOV.VLDESCONTO,0) +
                          NVL(NVL(PCMOV.VLDESCSUFRAMA,PCMOV.VLSUFRAMA),0)),
                         -- Normal
                         CASE WHEN (PCNFSAID.CONDVENDA = 4 OR NVL(PCNFSAID.NUMCUPOM,0) > 0) THEN

                              DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,
                                              NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N',
                                                                              '',
                                                                              PCPRODFILIAL.PRECOUTILIZADONFE),
                                                      PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', PCFILIAL.CODIGO),'L'))),
                                   'L',


                                      (NVL(PCMOV.VLDESCREDUCAOCOFINS,0) + NVL
                                      (PCMOV.VLDESCREDUCAOPIS,0)),
                                   'LR', 0,
                                      NVL(PCMOVCOMPLE.VLSUBTOTDESCONTO,0))
                         ELSE
                              (DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,
                                               NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N',
                                                                               '',
                                                                               PCPRODFILIAL.PRECOUTILIZADONFE),
                                                       PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', PCFILIAL.CODIGO), 'L'))),
                                   'L',
                                      0,
                                   'LR',
                                      0,
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
                                        ), NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT),

                                        (ROUND( PCMOV.QTCONT *
                                        (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                     0,
                                                       0,
                                                       DECODE(SIGN(NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                                   -1,
                                                                   0,
                                                                   NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)))
                                        ), NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT))
                                   + (NVL(PCMOV.VLDESCPISSUFRAMA, 0)))) +
                               (
                                --Melhoria HIS.04338.2015 - Eddy
                                CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                           ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  PCNFSAID.DTSAIDA))) THEN
                                       0
                                     ELSE
                                       (ROUND((NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOV.VLDESCREDUCAOPIS, 0)) * PCMOV.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOV.QTCONT)
                                END
                                )
                         END +
                         --utilizado somente para equipe de medicamentos
                         (CASE WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',PCFILIAL.CODIGO) = 'L' THEN
                            NVL(PCMOVCOMPLE.VLDESCCOMERCIALICMISENCAO,0)
                          ELSE
                            0
                          END)
                         )
             END  AS VALOR_LIQUIDO
            ,CASE WHEN (PCNFSAID.CONDVENDA = 4) AND (PCNFSAID.NUMCUPOM > 0) then
                NVL(PCMOVCOMPLE.VLSUBTOTITEM,
                    DECODE(PCMOV.TRUNCARITEM,
                           'S',
                           TRUNC((DECODE(PCMOVCOMPLE.BONIFIC,
                                        'S',
                                        0,
                                        PCMOV.PUNITCONT) -
                                 NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                                     0) -
                                 DECODE(PCMOV.CODOPER,
                                        'SD',
                                        NVL(PCMOV.VLFRETE,
                                            0),
                                        0) +
                                 NVL(PCMOV.VLDESCPISSUFRAMA,
                                     0)) *
                                 PCMOV.QTCONT,
                                 2),
                           ROUND((DECODE(PCMOVCOMPLE.BONIFIC,
                                        'S',
                                        0,
                                        PCMOV.PUNITCONT) -
                                 NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                                     0) -
                                 DECODE(PCMOV.CODOPER,
                                        'SD',
                                        NVL(PCMOV.VLFRETE,
                                            0),
                                        0) +
                                 NVL(PCMOV.VLDESCPISSUFRAMA,
                                     0)) *
                                 PCMOV.QTCONT,
                                 2)))
               WHEN (ORGAO_PUBLICO = 'S') THEN
                ROUND(PCMOV.QTCONT *
                      (PCMOV.PTABELA + NVL(PCMOV.VLDESCRODAPE,
                                           0) +
                      DECODE(NVL(PCNFSAID.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, NVL(PCMOV.VLDESCICMISENCAO,0))),
                      2)
               ELSE
                ROUND(((DECODE(PCMOVCOMPLE.BONIFIC, 'S', 0, PCMOV.PUNITCONT) - NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                                             0) -
                                             DECODE(PCMOV.CODOPER, 'SD', NVL(PCMOV.VLFRETE,0),0) +
                      NVL(PCMOV.VLDESCPISSUFRAMA,
                           0))) * PCMOV.QTCONT ,2)
             END AS PRECO_PRODUTO
           /*               -- Campo n?o utilizado
            ,CASE
               WHEN (ORGAO_PUBLICO = 'S') THEN
                ROUND(PCMOV.QTCONT *
                      (PCMOV.PTABELA + NVL(PCMOV.VLDESCRODAPE,
                                           0) +
                      NVL(PCMOV.VLDESCICMISENCAO,
                           0)),
                      2)
               ELSE
                ROUND((DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT) - NVL(PCMOV.ST,
                                             0) -
                      NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                           0) - NVL(PCMOV.VLIPI,
                                     0) - DECODE(PCMOV.CODOPER, 'SD', NVL(PCMOV.VLFRETE,0),0)
                                                                  - NVL(PCMOV.VLREPASSE,0)+
                      NVL(PCMOV.VLDESCPISSUFRAMA,
                           0) + DECODE(PCMOV.CODOPER, 'SD', 0, NVL(PCMOV.VLDESCSUFRAMA,
                               0)) + NVL(PCMOV.VLSUFRAMA,
                                               0) +
                      NVL(PCMOV.VLDESCREDUCAOCOFINS,
                                     0) + NVL(PCMOV.VLDESCREDUCAOPIS,
                                               0)  ) * PCMOV.QTCONT +
                                              ROUND(DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE, NVL(PCCLIENT.PRECOUTILIZADONFE,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                PCFILIAL.CODIGO),
                                  'L'))),
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
                                                0) - NVL(DECODE(PCMOVCOMPLE.BONIFIC, 'S',PCMOV.PBONIFIC, PCMOV.PUNITCONT),
                                                         0))+ NVL(PCMOV.VLDESCICMISENCAO,
                     0)))* PCMOV.QTCONT,2)
                     ,2)
             END AS VALOR_PRODUTOS
               --*/
            ,CASE WHEN (LENGTH(PCPRODUT.CODAUXILIARTRIB) <= NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIARTRIB), PCPRODUT.GTINCODAUXILIARTRIB,'0')
                  WHEN (LENGTH(PCPRODUT.CODAUXILIAR) <= NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
             ELSE
                NULL
             END AS EAN_UNIDADE
            ,ROUND(NVL(PCMOV.VLFRETE ,0) * QTCONT,2) AS VALOR_FRETE
            ,ROUND((PCMOV.QTCONT * NVL(PCMOV.VLSEGURO,0)),2) AS VALOR_SEGURO
            ,CASE
                     WHEN (ORGAO_PUBLICO = 'S') THEN
                      0
                     ELSE
                     DECODE(PCMOV.CODOPER, 'SD',
                         -- Saida de Devolu??o
                         ROUND(((ROUND(NVL(PCMOV.VLDESCONTO,0) * PCMOV.QTCONT ,2) / PCMOV.QTCONT) + NVL(NVL(PCMOV.VLDESCSUFRAMA,PCMOV.VLSUFRAMA),0)) * PCMOV.QTCONT, 2),
                         -- Normal
                         CASE WHEN (PCNFSAID.CONDVENDA = 4 OR NVL(PCNFSAID.NUMCUPOM,0) > 0)
                         THEN
                         DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE,NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N','',PCPRODFILIAL.PRECOUTILIZADONFE),PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                               PCFILIAL.CODIGO),
                                 'L'))),
                             'L', (NVL(PCMOV.VLDESCREDUCAOCOFINS,
                                   0) + NVL(PCMOV.VLDESCREDUCAOPIS,
                                              0))
                                              , 'LR', 0,
                             ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLSUBTOTDESCONTO,0), 2) )
                         ELSE ROUND((DECODE(NVL(PCMOVCOMPLE.PRECOUTILIZADONFE, NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N','',PCPRODFILIAL.PRECOUTILIZADONFE),PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                               PCFILIAL.CODIGO),
                                 'L'))),
                             'L',
                                 0,
                             'LR',0,
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
                                      (GREATEST((ROUND( PCMOV.QTCONT *
                                      (DECODE((NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0)),
                                                   0,
                                                     0,
                                                     DECODE(SIGN((NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0))),
                                                                 -1,
                                                                 0,
                                                                 (NVL(PCMOVCOMPLE.VLDESCONTONF, 0) - NVL(PCMOV.VLREPASSE, 0))))
                                      ), 2) / PCMOV.QTCONT)

                                      , 0)) ))
                                 +
                           (NVL(PCMOV.VLDESCPISSUFRAMA, 0) +
                           CASE WHEN (PCMOVCOMPLE.CODMOTIVOICMSDESONERADO  IN ('7', '8')) THEN
                                     0
                           ELSE
                                     NVL(NVL(PCMOV.VLDESCSUFRAMA,PCMOV.VLSUFRAMA),0)
                           END)             ) * PCMOV.QTCONT , 2) END +
                        ROUND((
                        (
                        --Melhoria HIS.04338.2015 - Eddy
                        CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                   ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  PCNFSAID.DTSAIDA))) THEN
                                       0
                             ELSE
                                 CASE WHEN (PCNFSAID.CONDVENDA = 4 OR NVL(PCNFSAID.NUMCUPOM,0) > 0) THEN
                                   0
                                 ELSE
                                   (NVL(PCMOV.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOV.VLDESCREDUCAOPIS, 0))
                                 END
                        END
                        )) * QTCONT,2) +
                        --utilizado somente para equipe de medicamentos
                        ROUND(
                          (CASE WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',PCFILIAL.CODIGO) = 'L' THEN
                            NVL(PCMOVCOMPLE.VLDESCCOMERCIALICMISENCAO,0)
                          ELSE
                            0
                          END) * PCMOV.QTCONT, 2)
                        )
                   END AS VALOR_DESCONTO
            ,(NVL(PCMOV.PESOBRUTO,
                  0) * PCMOV.QTCONT) AS PESO_BRUTO
            ,NVL(PCMOV.PERCIPI,
                 0) AS PERCIPIVENDA
            ,NVL(PCMOV.VLIPIPORKG,
                 0) AS VLIPIPORKGVENDA
            ,PCMOV.TIPOMERC
            ,PCMOV.NUMSEQ AS NUMERO_ADICAO
            ,PCMOV.NUMSEQ AS NUMERO_SEQUENCIA
            ,0 AS VALOR_DESCONTO_ADICAO
            ,PCMOV.NUMLOTE AS NUMERO_LOTE
            ,(SELECT TRUNC(NVL(PCMOV.DATAFABRICACAO, PCLOTE.DATAFABRICACAO)) AS DATAFABRICACAO
              FROM   PCLOTE
              WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
              AND    PCLOTE.CODFILIAL = NVL(PCMOV.CODFILIALRETIRA,PCMOV.CODFILIAL)
              AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
              AND    ROWNUM = 1) AS DATA_FABRICACAO
            ,(SELECT TRUNC(NVL(PCMOV.DATAVALIDADE, PCLOTE.DTVALIDADE)) AS DTVALIDADE
              FROM   PCLOTE
              WHERE  PCLOTE.CODPROD = PCMOV.CODPROD
              AND    PCLOTE.CODFILIAL = NVL(PCMOV.CODFILIALRETIRA,PCMOV.CODFILIAL)
              AND    PCLOTE.NUMLOTE = PCMOV.NUMLOTE
              AND    ROWNUM = 1) AS DATA_VALIDADE
            ,PCMOV.QTCONT AS QT_LOTE
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
            ,NVL(PCMOV.SITTRIBUT,
                 55) AS SITUACAO_TRIBUTARIA
            ,'3' AS MODALIDADE_BC_ICMS

            , CASE WHEN (PCMOV.CODOPER ='SD'  AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                    PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                    0
               ELSE
                    DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOV.VLDESCRODAPE, 0),
                                               ROUND(PCMOV.QTCONT * (NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(PCMOVCOMPLE.VLBASEOUTROS,0)),2))
               END
                AS BASE_ICMS
            ,CASE WHEN
                 (PCMOV.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S')
                THEN
                 0
                 ELSE
                 NVL(NVL(PCMOV.PERCICM2,
                         NVL(PCMOV.PERCICMCP,
                             PCMOV.PERCICM)),
                     0)END
              AS ALIQUOTA_ICMS
            ,CASE WHEN PCMOVCOMPLE.SOMARVALORDIFBCICMS = 'S' THEN 0 ELSE
                CASE WHEN (PCMOV.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                  PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                  0
                ELSE
                  (ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOV.VLDESCRODAPE, 0), 0) +
                            NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE, 0) + NVL(PCMOVCOMPLE.VLBASEOUTROS, 0))
                            * pcmov.QTCONT , 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2))
                   -
                  (ROUND(ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOV.VLDESCRODAPE, 0), 0) +
                            NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE, 0) + NVL(PCMOVCOMPLE.VLBASEOUTROS, 0))
                            * PCMOV.QTCONT, 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                          (NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,NVL(PCMOV.PERCDESCICMSDIF,0))/100), 2))

                END
            END AS VALOR_ICMS
          ,CASE WHEN (PCMOV.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                      PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                 0
           ELSE
                (ROUND(ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOV.VLDESCRODAPE, 0), 0) +
                          NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE, 0) + NVL(PCMOVCOMPLE.VLBASEOUTROS, 0))
                         * PCMOV.QTCONT, 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2), 2))
           END AS VALOR_ICMS_OPERACAO
            ,ROUND(NVL(PCMOVCOMPLE.PERCICMSSIMPLESNAC,0),2) ALIQUOTA_CREDITO_SN
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLRICMSSIMPLESNAC,0),2) VALOR_CREDITO_ICMS_SN
            ,ROUND(NVL(PCMOV.VLADUANEIRA,
                       0) * PCMOV.QTCONT,
                   2) BASE_II
            ,ROUND(NVL(PCMOV.VLADUANEIRA,
                       0) * PCMOV.QTCONT,
                   2) VALOR_DESPESA_ADUANEIRA
            ,ROUND(NVL(PCMOV.VLIMPORTACAO,
                       0) * PCMOV.QTCONT,
                   2) VALOR_II
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
                                       AND    PCTABTRIBENT.UFORIGEM =
                                              'ES'
                                       AND    PCTABTRIBENT.UFDESTINO =
                                              'EX'
                                       AND    ROWNUM = 1))),
                        'N'),
                    'S',
                    50,
                    NVL((SELECT CODSITTRIBIPISAID FROM PCFIGURATRIBIPI F WHERE F.CODFIGURAIPI IN (SELECT CODFIGURAIPI FROM PCTRIBIPI WHERE CODPROD = PCMOV.CODPROD AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCTRIBIPI.CODFILIAL AND ROWNUM = 1) AND ROWNUM = 1), 99))) SITUACAO_TRIBUTARIA_IPI
            ,ROUND(DECODE(PCMOV.CODOPER,
                          'SD',
                          (DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                                    PCFILIAL.CODIGO),
                                      'N'),
                                  'N',
                                  NVL(PCMOV.VLBASEIPI,
                                      0),
                                  'S',
                                  DECODE(NVL(PCMOV.CALCCREDIPI,
                                             'S'),
                                         'S',
                                         NVL(PCMOV.VLBASEIPI,
                                             0),
                                         'N',
                                         DECODE(NVL(PCMOV.IMPORTADO,
                                                    'N'),
                                                'D',
                                                NVL(PCMOV.VLBASEIPI,
                                                    0),
                                                0))) +
                          DECODE(ORGAO_PUBLICO,
                                  'S',
                                  NVL(PCMOV.VLDESCRODAPE,
                                      0),
                                  0)),
                          NVL(PCMOV.VLBASEIPI,
                              0)) * PCMOV.QTCONT,
                   2) AS BASE_IPI
            ,ROUND((DECODE(ORGAO_PUBLICO,
                           'S',
                           NVL(PCMOV.VLDESCRODAPE,
                               0),
                           0) + DECODE(PCMOV.CODOPER,
                                        'SD',
                                        DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                                                 PCFILIAL.CODIGO),
                                                   'N'),
                                               'N',
                                               NVL(PCMOV.VLIPI,
                                                   0),
                                               'S', 0,
                                               DECODE(NVL(PCMOV.CALCCREDIPI,
                                                          'S'),
                                                      'S',
                                                      NVL(PCMOV.VLIPI,
                                                          0),
                                                      'N',
                                                      DECODE(NVL(PCMOV.IMPORTADO,
                                                                 'N'),
                                                             'D',
                                                             NVL(PCMOV.VLIPI,
                                                                 0),
                                                             0))),
                                        NVL(PCMOV.VLIPI,
                                            0))) * PCMOV.QTCONT,
                   2) AS VALOR_IPI
            ,
            CASE WHEN (PCMOV.CODOPER = 'SD' AND
                  NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                  0
            ELSE
                  ROUND(NVL(NVL(PCMOV.VLIPI,
                           0) * PCMOV.QTCONT,
                       0),
                   2) END AS VALOR_IPI_CALCULO
            ,DECODE(PCMOV.CODOPER,
                    'SD',
                    DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                             PCFILIAL.CODIGO),
                               'N'),
                           'N',
                           NVL(PCMOV.VLIPI,
                               0),
                           'S',
                           DECODE(NVL(PCMOV.CALCCREDIPI,
                                      'S'),
                                  'S',
                                  NVL(PCMOV.VLIPI,
                                      0),
                                  'N',
                                  DECODE(NVL(PCMOV.IMPORTADO,
                                             'N'),
                                         'D',
                                         NVL(PCMOV.VLIPI,
                                             0),
                                         0))),
                    NVL(PCMOV.VLIPI,
                        0)) AS VALOR_IPI_UNIDADE
            ,DECODE(PCMOV.CODOPER,
                    'SD',
                    DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                             PCFILIAL.CODIGO),
                               'N'),
                           'N',
                           NVL(PCMOV.PERCIPI,
                               0),
                           'S',
                           DECODE(NVL(PCMOV.CALCCREDIPI,
                                      'S'),
                                  'S',
                                  NVL(PCMOV.PERCIPI,
                                      0),
                                  'N',
                                  DECODE(NVL(PCMOV.IMPORTADO,
                                             'N'),
                                         'D',
                                         NVL(PCMOV.PERCIPI,
                                             0),
                                         0))),
                    NVL(PCMOV.PERCIPI,
                        0)) AS ALIQUOTA_IPI
            ,NVL(100 - PCMOV.PERCBASERED,
                 0) AS PERCENTUAL_REDUCAO_BC
            ,CASE
               WHEN ((NVL(PCCONSUM.UTILIZACONTROLELOTE, 'N') = 'S') OR
                    (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZACONTROLEMEDICAMENTOS',
                                                        '99'),
                          'N') = 'S')) THEN
                DECODE(NVL(PCMOVCOMPLE.USAPMCBASEST, 'N'),
                       'S',
                       0,
                       DECODE(NVL(PCMOV.TIPOTRIBUTMEDIC, 'OM'),
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
                                END))
               ELSE
                CASE WHEN (NVL(PCMOV.PAUTA, 0) > 0) AND (ROUND(NVL(PCMOV.PAUTA, 0) * (DECODE(NVL(PCMOV.PERCBASEREDST,0), 0, 1, PCMOV.PERCBASEREDST/100)), 6) = PCMOV.BASEICST) THEN
                       5
                    ELSE
                       4
                    END
             END MODALIDADE_BC_ST
            ,ROUND(NVL(PCMOV.PERCIVA, NVL(PCMOV.IVA, 0)), 2) AS PERCENTUAL_MARGEM
            ,ROUND(CASE WHEN GREATEST(NVL(PCMOV.ALIQSTSAIDA,0), NVL(PCMOV.PERCBASEREDST,0), NVL(PCMOV.PERCBASEREDSTFONTE,0) ) > 0 THEN
                         100 - GREATEST(NVL(PCMOV.ALIQSTSAIDA,0), NVL(PCMOV.PERCBASEREDST,0), NVL(PCMOV.PERCBASEREDSTFONTE,0))
                      ELSE
                         0
                   END, 4) AS PERCENTUAL_REDUCAO_ST
            ,ROUND(NVL(DECODE(PCMOV.CODOPER,
                              'SD',
                              DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',
                                                                       PCFILIAL.CODIGO),
                                         'S'),
                                     'S',
                                     (DECODE(ORGAO_PUBLICO,
                                             'S',
                                             NVL(PCMOV.VLDESCRODAPE,
                                                 0),
                                             0) + NVL(PCMOV.BASEICST,
                                                       0)),
                                     0),
                              DECODE(ORGAO_PUBLICO,
                                     'S',
                                     NVL(PCMOV.VLDESCRODAPE,
                                         0),
                                     0) + NVL(PCMOV.BASEICST,
                                              0)) * PCMOV.QTCONT,
                       0),
                   2) AS BASE_ST
            ,ROUND(NVL(DECODE(PCMOV.CODOPER,
                              'SD',
                              DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',
                                                                       PCFILIAL.CODIGO),
                                         'S'),
                                     'S',
                                     (DECODE(ORGAO_PUBLICO,
                                             'S',
                                             NVL(PCMOV.VLDESCRODAPE,
                                                 0),
                                             0) + NVL(PCMOV.ST,
                                                       0)),
                                     0),
                              DECODE(ORGAO_PUBLICO,
                                     'S',
                                     NVL(PCMOV.VLDESCRODAPE,
                                         0),
                                     0) + NVL(PCMOV.ST,
                                              0)) * PCMOV.QTCONT,
                       0),
                   2) AS VALOR_ST
            ,ROUND((PCMOV.PUNITCONT * PCMOV.QTCONT),2) AS VALOR_TOT_EMBALAGEM
            ,ROUND((PCMOV.PUNITCONT  * QTUNITEMB),2)  AS VALOR_UN_EMBALAGEM
            ,CASE WHEN (PCMOV.CODOPER = 'SD' AND
                  NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',PCFILIAL.CODIGO),'S') = 'N') THEN
                 0
             ELSE
                 ROUND(NVL(NVL(PCMOV.ST,
                           0) * PCMOV.QTCONT,
                       0),
                   2) END AS VALOR_ST_CALCULO
            ,NVL(PCMOV.ALIQICMS1,
                 0) AS ALIQUOTA_ST
            ,NVL(PCMOV.PISCOFINSRETIDO,
                 'I') AS RETIDO
            ,CASE WHEN NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLE.USAPISCOFINSLIT,'N') = 'S'  THEN
                NVL(PCMOV.VLCOFINS,0)
             else
                NVL(PCMOV.PERCOFINS, 0)
             end ALIQUOTA_COFINS
            ,CASE WHEN NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLE.USAPISCOFINSLIT,'N') = 'S'THEN
                NVL(PCMOV.VLPIS,0)
             else
                NVL(PCMOV.PERPIS, 0)
             end ALIQUOTA_PIS
            ,NVL(PCMOV.CODSITTRIBPISCOFINS,99) AS SIT_PIS_CONFINS
            ,CASE WHEN NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                  AND NVL(PCMOVCOMPLE.USAPISCOFINSLIT, 'N') = 'S' THEN
               NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) * PCMOV.QTCONT
            ELSE
               NVL(PCMOV.VLBASEPISCOFINS, 0) * PCMOV.QTCONT
            END VL_BASE_PIS
           ,CASE  WHEN NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLE.USAPISCOFINSLIT, 'N') = 'S' THEN
               ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) * NVL(PCMOV.VLCOFINS,0), 2)
            ELSE
               ROUND(PCMOV.QTCONT * NVL(PCMOV.VLCOFINS,0), 2)
            END VALOR_COFINS
           ,CASE WHEN NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                  AND NVL(PCMOVCOMPLE.USAPISCOFINSLIT, 'N') = 'S' THEN
               NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) * PCMOV.QTCONT
            ELSE
               NVL(PCMOV.VLBASEPISCOFINS, 0) * PCMOV.QTCONT
            END VL_BASE_CONFINS
           ,CASE  WHEN NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLE.USAPISCOFINSLIT, 'N') = 'S' THEN
               ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.QTLITRAGEM, PCPRODUT.LITRAGEM) * NVL(PCMOV.VLPIS,0), 2)
            ELSE
               ROUND(PCMOV.QTCONT * NVL(PCMOV.VLPIS,0), 2)
            END VALOR_PIS
            --
            ,PCMOV.CLASSIFICFISCAL
            ,PCPRODUT.CODFAB AS CODIGO_FABRICANTE
            ,PCMOV.CODFORNEC AS CODIGO_FORNECEDOR
            ,DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),'N',
               NVL(PCMOV.EMBALAGEM, PCEMBALAGEM.EMBALAGEM),
               NVL(PCEMBALAGEM.EMBALAGEM,PCMOV.EMBALAGEM)) AS EMBALAGEM
            ,PCPRODUT.EMBALAGEMMASTER
            ,PCFORNEC.FANTASIA
            ,PCFORNEC.FORNECEDOR
            ,PCPRODUT.PESOEMBALAGEM
            ,PCPRODUT.FATORUNFARM
            ,PCPRODUT.NUMORIGINAL
            ,PCMARCA.MARCA
            ,(SELECT PCPRINCIPATIVO.DESCRICAO
              FROM   PCPRINCIPATIVO
              WHERE  PCPRINCIPATIVO.CODPRINCIPATIVO =
                     PCPRODUT.CODPRINCIPATIVO) AS PRINCIPIOATIVO
            ,NVL(PCMOV.PERCDESC, 0) PERCDESC
            ,NVL(DECODE(NVL(PCMOV.PESOBRUTO,
                            0),
                        0,
                        (SELECT PCPEDI.PESOBRUTO
                         FROM   PCPEDI
                         WHERE  PCPEDI.NUMPED = PCMOV.NUMPED
                         AND    PCPEDI.CODPROD = PCMOV.CODPROD
                         AND    PCPEDI.NUMSEQ = PCMOV.NUMSEQ
                         AND    ROWNUM = 1),
                        PCMOV.PESOBRUTO),
                 0) PESOCX
            -----TAREFA: 195705-----
            ,CASE
                 WHEN NVL(PCMOV.QTCX, 0) > 0 OR NVL(PCMOV.QTPECAS, 0) > 0 THEN
                         PCMOV.QTCX
                      ELSE
                         CASE WHEN NVL(PCPRODUT.TIPOESTOQUE, 'PA') = 'PA' THEN
                           NULL
                         ELSE
                           PCMOV.QTCONT
                         END
                 END QTCX
            ,NVL(PCMOV.QTPECAS, 0) QTPECAS
            ------------------------
            ,NVL(PCMOVCOMPLE.QTUN,
                 0) QTUN
            ,NVL(PCMOV.PTABELA,
                 0) PTABELA
            ,PCMOV.PUNITCONT
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
                (PCMOV.QTCONT - (TRUNC(PCMOV.QTCONT / CASE
               WHEN NVL(PCPRODUT.PESOBRUTOMASTER,
                        1) > 0 THEN
                NVL(PCPRODUT.PESOBRUTOMASTER,
                    1)
               ELSE
                1
             END) * NVL(PCPRODUT.PESOBRUTOMASTER, 1))) ELSE PCMOV.QTCONT / DECODE(NVL(PCPRODUT.PESOPECA, 1), 0, 1, NVL(PCPRODUT.PESOPECA, 1)) END AS QTD_PECAS_INTERM
            ,NVL(PCMOV.QTUNITCX,
                 0) QTUNITCX
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
            ,ROUND(NVL(PCMOV.STCLIENTEGNRE, 0) * NVL(PCMOV.QTCONT, 0), 2) STCLIENTEGNRE
            ,NVL(PCPRODUT.TIPOESTOQUE, 'PA') AS TIPOESTOQUE
            ,NVL(PCMOV.TIPOTRIBUTMEDIC, 'X') TIPOTRIBUTMEDIC
            ,DECODE(PCPEDC.TIPOEMBALAGEM,
                    'C',
                    (PCMOV.QTCONT / DECODE(NVL(PCMOV.QTUNITCX,
                                               0),
                                           0,
                                           1,
                                           NVL(PCMOV.QTUNITCX,
                                               0))),
                    PCMOV.QTCONT) * PCMOV.PESOLIQ TOTPESOLIQUNIT
            ,PCPRODUT.UNIDADEMASTER
            ,ROUND(NVL(PCMOV.VLBASEGNRE, 0) * NVL(PCMOV.QTCONT, 0), 2) VLBASEGNRE
            ,PCMOV.NUMVOLUMESCONFERENCIA
            ,PCMOV.PERACRESCIMOCUSTO
            ,PCMOV.TIPOSEPARACAO
            ,PCMOV.QTUNITEMB
            ,CASE WHEN (PCMOV.CODOPER IN ('SD','SR')) THEN
                  PCMOV.UNIDADE
             ELSE
                  PCEMBALAGEM.UNIDADE
             END AS UNIDADE_EMBALAGEM -- TAREFA: 133424
            --,DECODE(PCMOV.CODOPER, 'SD', PCMOV.UNIDADE, PCEMBALAGEM.UNIDADE) AS UNIDADE_EMBALAGEM
            ,CASE WHEN (PCMOV.CODOPER IN ('SD,SR')) THEN
                  PCMOV.QTCONT
             ELSE
             PCMOV.QTCONT / DECODE(NVL(PCMOV.QTEMBALAGEM,
                                        0),
                                    0,
                                    DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                               1),
                                           0,
                                           1,
                                           PCEMBALAGEM.QTUNIT),
                                    PCMOV.QTEMBALAGEM) END AS QTD_EMBALAGEM --TAREFA: 133424 E 138681
            ,PCMOV.CODSEC AS CODIGO_SECAO
            ,PCMOV.CODEPTO AS CODIGO_DEPARTAMENTO
            ,PCSECAO.DESCRICAO AS DESCRICAO_SECAO
            ,PCDEPTO.DESCRICAO AS DESCRICAO_DEPARTAMENTO
            ,DECODE(NVL(PCNFSAID.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.BASEBCR, 0) * PCMOV.QTCONT),0) AS BASEBCR
            ,DECODE(NVL(PCNFSAID.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.STBCR, 0) * PCMOV.QTCONT),0) AS STBCR
            ,NVL(PCMOV.VOLUME, 0) AS VOLUME
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
            ,PCMOVCOMPLE.UNIDADELICIT AS UNIDADE_LICIT
            ,PCMOVCOMPLE.QTUNITLICIT AS QT_UNIT_LICIT
            ,DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARNUMPEDGRUPOCOMPRA', PCFILIAL.CODIGO), 'N'),'S',
             NVL(PCMOVCOMPLE.NUMPEDCLI, NVL(PCNFSAID.NUMPEDCLI, NVL(PCMOV.NUMPED, 0))),
             NVL(PCNFSAID.NUMPEDVANXML, NVL( PCMOV.NUMPED, 0))) AS NUMERO_PEDIDO
            ,NVL(PCMOVCOMPLE.NUMITEMPED,NVL(PCMOVCOMPLE.IDVENDA, NVL(PCMOV.NUMSEQ, 1))) AS NUMERO_ITEM_PEDIDO
            ,PCMOV.NUMSEQ
            ,NVL(PCMOV.QTUNIT, 0) AS QTUNIT
            ,ROUND((DECODE(PCMOV.CODOPER, 'SD',
                           NVL(PCMOV.VLDESPDENTRONF,0) -
                           DECODE(NVL(PCMOVCOMPLE.VLIPIDEVFORNEC, 0),
                                  0,
                                  0,
                                  NVL(PCMOVCOMPLE.VLIPIOUTRAS, 0)),
                           NVL(PCMOV.VLOUTROS,0) - NVL(PCMOV.VLSEGURO,0))) * QTCONT,2) AS VALOR_OUTROS
            --dados veiculos
            ,PCPEDIDADOSVEICULOS.TPOPERACAO AS TPOPERACAO
            ,PCPEDIDADOSVEICULOS.CHASSI AS CHASSIVEICULO
            ,PCPEDIDADOSVEICULOS.CODCOR AS CORVEICULO
            ,PCPEDIDADOSVEICULOS.DESCCOR AS DESCCORVEICULO
            ,PCPEDIDADOSVEICULOS.POTMOTOR AS POTVEICULO
            ,PCPEDIDADOSVEICULOS.CILINDRADAS AS  CILINVEICULO
            ,PCPEDIDADOSVEICULOS.PESOLIQUIDO AS  PESOLVEICULO
            ,PCPEDIDADOSVEICULOS.PESOBRUTO AS PESOBVEICULO
            ,PCPEDIDADOSVEICULOS.SERIE AS SERIALVEICULO
            ,PCPEDIDADOSVEICULOS.TPCOMBUSTIVEL AS TPCOMBVEICULO
            ,PCPEDIDADOSVEICULOS.NUMMOTOR AS NMOTORVEICULO
            ,PCPEDIDADOSVEICULOS.CMT AS CMTVEICULO
            ,PCPEDIDADOSVEICULOS.DISTANCIAEIXO AS DISTEIXOVEICULO
            ,PCPEDIDADOSVEICULOS.ANOMOD AS ANOMODVEICULO
            ,PCPEDIDADOSVEICULOS.ANOFAB AS ANOFABVEICULO
            ,PCPEDIDADOSVEICULOS.TPPINTURA AS TPPINTVEICULO
            ,PCPEDIDADOSVEICULOS.TPVEICULO AS TPVEICVEICULO
            ,PCPEDIDADOSVEICULOS.ESPECIEVEICULO AS ESPVEICVEICULO
            ,PCPEDIDADOSVEICULOS.VIN AS CONDVINVEICULO
            ,PCPEDIDADOSVEICULOS.CONDVEICULO AS CONDVEICVEICULO
            ,PCPEDIDADOSVEICULOS.CODMODELO AS MARCMODVEICULO
            ,PCPEDIDADOSVEICULOS.CODCORDENATRAM AS CORDENATRANVEICULO
            ,PCPEDIDADOSVEICULOS.LOTACAO AS LOTACAOVEICULO
            ,PCPEDIDADOSVEICULOS.TPRESTRICAO AS TPRESTVEICULO
            --fim dados veiculos
            ,PCMOVCOMPLE.PRECOMAXCONSUM AS PRECO_MAX_CONSUMIDOR
            ,CASE WHEN ((NVL(PCMOV.PUNITCONT,0) - NVL(PCMOV.VLREPASSE,0)) > NVL(PCMOVCOMPLE.PORIGINAL,0)) THEN
            --Quando o campo PCNFSAID.SOMAREPASSEOUTRASDESPNF = S a package de faturamento já subtraiu o VLREPASSE do PUNITCONT
                  NVL(PCMOV.PUNITCONT,0) - DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'), 'S', 0, NVL(PCMOV.VLREPASSE,0))
             ELSE PCMOVCOMPLE.PORIGINAL END AS PRECO_FABRICA
            ,PCMOVCOMPLE.DESCPRECOFAB AS DESCONTO_FABRICA
            ,PCMOVCOMPLE.CODPRODACABCESTA AS CODPRODCABCESTA
            ,PCMOV.PERBONIFIC AS PERCBONIFIC
            --Dados abatimento
            ,GREATEST((NVL(PCMOV.VLDESCONTO, 0 ) - NVL(PCMOVCOMPLE.VLDESCABATIMENTO,0)) * PCMOV.QTCONT, 0) AS VLDESCSEMABATIMENTO
            ,(NVL(PCMOVCOMPLE.VLDESCABATIMENTO ,0) * PCMOV.QTCONT) AS VLABATIMENTO
            --Dados abatimento - Fim
            ,PCPRODUT.ANP AS CODIGOANP
            ,CASE WHEN (NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N') = 'S') THEN
                  DECODE(NVL(PCCLIENT.CONSUMIDORFINAL,'N'), 'S', ROUND((NVL(PCMOVCOMPLE.VLITEMTRIBUTOS,0) + NVL(PCMOVCOMPLE.VLITEMTRIBUTOSEST,0) + NVL(PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC,0)) * QTCONT,2), 0)
             ELSE
                  ROUND((NVL(PCMOVCOMPLE.VLITEMTRIBUTOS,0) + NVL(PCMOVCOMPLE.VLITEMTRIBUTOSEST,0) + NVL(PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC,0)) * QTCONT,2) END AS VLTOTALIMPOSTOS
            ,DECODE(NVL(PCMOVCOMPLE.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), '3', PCMOVCOMPLE.NUMFCI, '5', PCMOVCOMPLE.NUMFCI, '8', PCMOVCOMPLE.NUMFCI, '') AS NUMERO_FCI
            ,NVL(PCMOV.PERDESCISENTOICMS,0) ALIQ_INSENCAO_ICMS
            ,ROUND((PCMOV.QTCONT * NVL(PCMOV.VLDESCICMISENCAO,0)),2) VALOR_ISENCAO_ICMS
            ,PCEMBALAGEM.CODAUXILIAR AS COD_AUXILIAR_EMBALAGEM
            ,NVL(PCMOVCOMPLE.VLITEMTRIBUTOS,0) VLTOTALIMPOSTOSFEDERAL
            ,NVL(PCMOVCOMPLE.VLITEMTRIBUTOSEST,0) VLTOTALIMPOSTOSESTADUAL
            ,NVL(PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC,0) VLTOTALIMPOSTOSMUNICIPAL
            ,(ROUND(ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOV.VLDESCRODAPE, 0), 0) +
                          NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE, 0) + NVL(PCMOVCOMPLE.VLBASEOUTROS, 0))
                          * PCMOV.QTCONT, 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                        (NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,NVL(PCMOV.PERCDESCICMSDIF,0))/100), 2))
             AS VALORICMSDIF
            ,NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,NVL(PCMOV.PERCDESCICMSDIF,0)) AS ALIQUOTAICMSDIF
            ,CASE WHEN (PCMOV.CODOPER = 'SD') THEN
              CASE WHEN (PCMOVCOMPLE.CODMOTIVOICMSDESONERADO = '7') THEN
                  0
                 WHEN (NVL(PCMOV.VLDESCICMISENCAO,0) > 0) THEN
                  ROUND(PCMOV.QTCONT * NVL(PCMOV.VLDESCICMISENCAO, 0), 2)
                 WHEN (NVL(PCMOVCOMPLE.VLICMSDESONERACAO,0) > 0) THEN
                  ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSDESONERACAO, 0), 2)
              ELSE
                 0
              END
            ELSE
              ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSDESONERACAO, 0), 2)
            END VLICMSDESONERACAO
            ,CASE WHEN (PCMOV.CODOPER = 'SD') THEN
              CASE WHEN (PCMOVCOMPLE.CODMOTIVOICMSDESONERADO = '7') THEN
                  0
                 WHEN (NVL(PCMOV.VLDESCICMISENCAO,0) > 0) THEN
                  ROUND(PCMOV.QTCONT * NVL(PCMOV.VLDESCICMISENCAO, 0), NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2))
                 WHEN (NVL(PCMOVCOMPLE.VICMSSTDESON,0) > 0) THEN
                  ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSSTDESON, 0), NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2))
              ELSE
                 0
              END
            ELSE
              ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VICMSSTDESON, 0), NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2))
            END VICMSSTDESON
            ,CASE WHEN ((PCMOV.CODOPER = 'SD') AND (PCMOVCOMPLE.CODMOTIVOICMSDESONERADO = '7')) THEN '' ELSE PCMOVCOMPLE.CODMOTIVOICMSDESONERADO END CODMOTIVOICMSDESONERADO
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLIPIDEVFORNEC, 0),2) AS VALOR_IPI_OUTROS
            ,NULL AS TIPO_PRESENCA_ADQUIRINTE
            ,DECODE(NVL((PARAMFILIAL.OBTERCOMOVARCHAR2('INFDADOSEXPORTPORITEM', 99)),'N'),
                   'S',
                   PCMOVCOMPLE.NUMDRAWBACK,
                   PCNFSAID.NUMDRAWBACK
             ) NUMERO_DRAWBACK
            ,PCMOVCOMPLE.CODCEST
            ,PCMOVCOMPLE.CODENQIPI CODENQUADRAMENTOIPI
             ,DECODE(NVL((PARAMFILIAL.OBTERCOMOVARCHAR2('INFDADOSEXPORTPORITEM', 99)),'N'),
                   'S',
                   PCMOVCOMPLE.NUMCHAVEEXP,
                   PCNFSAID.NUMCHAVEEXP
             ) NUMCHAVEEXP
             ,DECODE(NVL((PARAMFILIAL.OBTERCOMOVARCHAR2('INFDADOSEXPORTPORITEM', 99)),'N'),
                   'S',
                   PCMOVCOMPLE.NUMREGEXP,
                   PCNFSAID.NUMREGEXP
             ) NUMREGEXP
            ,NVL(PCMOVCOMPLE.ALIQFCP, 0) AS ALIQFCPPART
            ,NVL(PCMOVCOMPLE.ALIQINTERNADEST, 0) AS ALIQINTERNADEST
            ,NVL(PCMOVCOMPLE.ALIQINTERORIGPART, 0) AS ALIQINTERORIGPART
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFCPPART, 0),2) AS VLFCPPART
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEPARTDEST, 0),2) AS VLBASEPARTDEST
            ,NVL(PCMOVCOMPLE.PERCPROVPART,0) AS PERCPROVPART
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSDIFALIQPART, 0),2) AS VLICMSDIFALIQPART
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSPARTDEST, 0),2) AS VLICMSPARTDEST
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSPARTREM, 0),2) AS VLICMSPARTREM
            ,PCFILIAL.CODIGO AS CODFILIAL
            ,0 AS VIASTRANSP
            ,0 AS VLAFRMM
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
            ,CASE WHEN (PCMOVCOMPLE.SOMARVALORDIFBCICMS = 'S') THEN 0 ELSE ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP, 0),2) END AS VLACRESCIMOFUNCEP
            ,NVL(PCMOVCOMPLE.PERACRESCIMOFUNCEP, 0) AS PERACRESCIMOFUNCEP
            ,NVL(PCMOVCOMPLE.ALIQICMSFECP, 0) AS ALIQICMSFECP
            ,CASE
               WHEN PCNFSAID.TIPOVENDA = 'DF' THEN
                PCMOVCOMPLE.CODBENEFICIONOTA --Código de benefício que veio na nota de entrada
               ELSE
                PCMOVCOMPLE.CODBENEFICIOFISCAL
             END AS COD_BENEFICIO_FISCAL
            ,NVL(PCMOVCOMPLE.INDESCALARELEVANTE, PCPRODFILIAL.INDESCALARELEVANTE) AS IND_ESCALA_RELEVANTE
            ,PCMOVCOMPLE.CODAGREGACAO AS COD_AGREGACAO
            ,PCMOVCOMPLE.CNPJFABRICANTE AS CNPJ_FABRICANTE
            ,NVL(PCMOVCOMPLE.DESCANP, PCPRODUT.DESCANP) AS DESC_ANP
            ,NVL((SELECT NVL(T.ISENTAICMSUFDEST,  'N')
                   FROM PCTRIBUTPARTILHA P
                        ,PCTRIBUT        T
                  WHERE P.CODSTPARTILHA = T.CODST
                    AND P.CODST = PCMOV.CODST
                    AND P.UF = PCNFSAID.UF), 'N') AS ISENTO_ICMS_UF_DEST
            ,NVL(PCPRODUT.TIPOPROD, 0) AS MIUDEZA
            ,NVL(PCMOVCOMPLE.PGLP, NVL(PCPRODUT.pGLP, 0)) AS PERCENTUAL_GLP
            ,NVL(PCMOVCOMPLE.PGNN, NVL(PCPRODUT.PGNN, 0)) AS PERC_GAS_NATURAL_NACIONAL
            ,NVL(PCMOVCOMPLE.PGNI, NVL(PCPRODUT.PGNI, 0)) AS PERC_GAS_NATURAL_IMPORTADO
            ,NVL(PCMOVCOMPLE.VPART, NVL(PCPRODUT.VPART, 0)) AS VALOR_PARTIDA
            ,NVL((SELECT PRIORIDADE FROM PCPRIORIDADEPRODDANFE WHERE CODPRIORIDADE = PCPRODFILIAL.CODCADPRIORIDADE), 0) AS COD_PRIORIDADE_IMPRESSAO
            ,PCMOV.NUMNOTA
            ,PCMOV.DATACONSOLIDACAOPREFAT
            ,'N' PREFATURAMENTO
            ,NVL(PCMOVCOMPLE.PERCREDBASEEFET, 0) AS PERCREDBASEEFET
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLBASEEFET, 0),2) VLBASEEFET
            --,NVL(PCMOVCOMPLE.PERCICMSEFET, (NVL(PCEST.ALIQICMS1, 0) + NVL(PCEST.PERFCPSTRET, 0))) AS PERCICMSEFET
            ,NVL(PCMOVCOMPLE.PERCICMSEFET, 0) AS PERCICMSEFET
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLICMSEFET, 0),2) VLICMSEFET
            ,NVL(PCMOVCOMPLE.ALIQICMS1RET, 0) + NVL(PCMOVCOMPLE.PERFCPSTRET, 0) AS PERCSTRET
            ,NVL(PCMOVCOMPLE.CODMOTISENCAOANVISA, PCPRODUT.CODMOTISENCAOANVISA) AS MOTIVO_ISENCAO_ANVISA
            ,DECODE(NVL(PCNFSAID.GERARBCRNFE, 'N'), 'S', (NVL(PCMOV.VLICMSBCR, 0) * PCMOV.QTCONT),0) AS VLICMSBCR
             --PCEST TEMPORARIO
            ,DECODE(NVL(PCNFSAID.GERARBCRNFE, 'N'), 'S', (NVL(PCEST.BASEBCR, 0) * PCMOV.QTCONT),0) AS BASEBCR_PCEST
            ,NVL(PCEST.ALIQICMS1, 0) + NVL(PCEST.PERFCPSTRET, 0) AS PERCSTRET_PCEST
            ,DECODE(NVL(PCNFSAID.GERARBCRNFE, 'N'), 'S', (NVL(PCEST.VLICMSBCR, 0) * PCMOV.QTCONT),0) AS VLICMSBCR_PCEST
            ,DECODE(NVL(PCNFSAID.GERARBCRNFE, 'N'), 'S', (NVL(PCEST.STBCR, 0) * PCMOV.QTCONT),0) AS STBCR_PCEST
            ,ROUND(PCMOV.QTCONT * NVL(PCEST.VLBCFCPSTRET, 0),2) VLBCFCPSTRET_PCEST
            ,NVL(PCEST.PERFCPSTRET, 0) PERFCPSTRET_PCEST
            ,ROUND(PCMOV.QTCONT * NVL(PCEST.VLFCPSTRET, 0),2) VLFCPSTRET_PCEST
            ,SQL_NFE_CABECALHO_SAIDA.SIGLA_UF_E
            ,SQL_NFE_CABECALHO_SAIDA.SIGLA_UF_D
            ,CASE WHEN NVL(PCMOVCOMPLE.VLITEMTRIBUTOS,0) > 0 THEN
                   DECODE(NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N'),  'S',
                   DECODE(NVL(PCCLIENT.CONSUMIDORFINAL, 'N'), 'S', ' VL.APROX.TRIB. FEDERAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLE.VLITEMTRIBUTOS,0) * PCMOV.QTCONT),'999999999999999990.99')), ''),
                   ' VL.APROX.TRIB. FEDERAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLE.VLITEMTRIBUTOS,0) * PCMOV.QTCONT),'999999999999999990.99')))
               ELSE '' END || ' ' ||
               CASE WHEN NVL(PCMOVCOMPLE.VLITEMTRIBUTOSEST,0) > 0 THEN
                   DECODE(NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N'),  'S',
                   DECODE(NVL(PCCLIENT.CONSUMIDORFINAL, 'N'), 'S', ' VL.APROX.TRIB. ESTADUAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLE.VLITEMTRIBUTOSEST,0) * PCMOV.QTCONT),'999999999999999990.99')), ''),
                   ' VL.APROX.TRIB. ESTADUAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLE.VLITEMTRIBUTOSEST,0) * PCMOV.QTCONT),'999999999999999990.99')))
               ELSE '' END || ' ' ||
               CASE WHEN NVL(PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC,0) > 0 THEN
                   DECODE(NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N'),  'S',
                   DECODE(NVL(PCCLIENT.CONSUMIDORFINAL, 'N'), 'S', ' VL.APROX.TRIB. MUNICIPAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC,0) * PCMOV.QTCONT),'999999999999999990.99')), ''),
                   ' VL.APROX.TRIB. MUNICIPAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC,0) * PCMOV.QTCONT),'999999999999999990.99')))
            END AS VLAPROXTRIB
            ,(CASE WHEN ((NVL(PCCLIENT.GERAGRPRETTRIB, 'N') = 'S') AND 
             ((NVL(PCCLIENT.ORGAOPUBFEDERAL, 'N') = 'S') OR 
              (NVL(PCCLIENT.ORGAOPUBMUNICIPAL, 'N') = 'S') OR 
              (NVL(PCCLIENT.ORGAOPUB, 'N') = 'S'))) THEN 'S' ELSE 'N' END) GERAGRPRETTRIB
            ,DECODE(NVL(PCCLIENT.RETECAOPISORGPUB, 'N'), 'S', ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLPISRETORGPUB, 0),2), 0) AS VLPISRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOCOFINSORGPUB, 'N'), 'S', ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLCOFINSRETORGPUB, 0),2), 0) AS VLCOFINSRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOCSORGPUB, 'N'), 'S', ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLCSLLRETORGPUB, 0),2), 0) AS VLCSLLRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOIRORGPUB, 'N'), 'S', ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLIRPJRETORGPUB, 0),2), 0) AS VLIRPJRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOIRORGPUB, 'N'), 'S', ROUND(PCMOV.QTCONT * NVL((PCMOV.PUNITCONT - PCMOV.ST - PCMOV.VLIPI), 0),2), 0) AS VLBCIRRFRETORGPUB            
            ,PCMOVCOMPLE.EXCLUIRICMSBASEPISCOFINS
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
            ,PCMOVCOMPLE.SOMARVALORDIFBCICMS
            ,ROUND(PCMOV.QTCONT * NVL(PCMOVCOMPLE.VLFCPDIF, 0),2) AS VLFCPDIF
            ,PCMOVCOMPLE.INDDEDUZDESONERACAO
            ,PCMOV.NUMTRANSITEM
      FROM   PCMOV
            ,PCPRODUT
            ,PCMOVCOMPLE
            ,PCEMBALAGEM
            ,PCCONSUM
            ,PCFORNEC
            ,PCTABPR
            ,PCSECAO
            ,PCMOVIMPOSTOS
            ,PCDEPTO
            ,PCFILIAL
            ,PCPEDC
            ,PCMARCA
            ,PCNFSAID
            ,PCPEDIDADOSVEICULOS
            ,PCCLIENT
            ,PCEQUIPAMENTO
            ,SQL_NFE_CABECALHO_SAIDA
            ,PCPRODFILIAL
            ,PCEST
            ,PCTRIBUT
      WHERE  PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
      AND    PCMOV.NUMTRANSVENDA = SQL_NFE_CABECALHO_SAIDA.NUM_TRANSACAO
      AND    PCMOV.CODPROD = PCPRODUT.CODPROD
      AND    PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
      AND    PCNFSAID.NUMNOTA = PCMOV.NUMNOTA
      AND    PCMOV.CODCLI = PCCLIENT.CODCLI(+)
      AND    PCMOV.CODEQUIPAMENTO = PCEQUIPAMENTO.CODEQUIPAMENTO(+)
      AND    PCMOV.CODPROD = PCTABPR.CODPROD(+)
      AND    PCMOV.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR(+)
      AND    PCMOV.CODPROD = PCEMBALAGEM.CODPROD(+)
      AND    PCMOV.NUMTRANSVENDA = PCMOVIMPOSTOS.NUMTRANSVENDA(+)
      AND    PCMOV.CODPROD = PCMOVIMPOSTOS.CODPROD(+)
      AND    PCMOV.NUMSEQ = PCMOVIMPOSTOS.NUMSEQ(+)
      AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCFILIAL.CODIGO
      AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+)
      AND    PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)
      AND    PCMOV.NUMREGIAO = PCTABPR.NUMREGIAO(+)
      AND    PCMOV.NUMPED = PCPEDC.NUMPED(+)
      AND    PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC(+)
      AND    PCPRODUT.CODSEC = PCSECAO.CODSEC(+)
      AND    PCPRODUT.CODEPTO = PCDEPTO.CODEPTO(+)
      AND    PCMOV.CODPROD = PCPEDIDADOSVEICULOS.CODPROD(+)
      AND    PCMOV.NUMPED = PCPEDIDADOSVEICULOS.NUMPED(+)
      AND    PCMOV.NUMSEQ = PCPEDIDADOSVEICULOS.NUMSEQ(+)
      AND    PCMOV.CODPROD = PCPRODFILIAL.CODPROD(+)
      AND    NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCPRODFILIAL.CODFILIAL(+)
      AND    NVL(PCMOV.QTCONT,0) > 0
      AND    PCMOV.CODPROD = PCEST.CODPROD
      AND    NVL(PCMOV.CODFILIALRETIRA, NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)) = PCEST.CODFILIAL
      AND    PCMOV.CODST = PCTRIBUT.CODST(+)
      )

UNION ALL

SELECT ALIQUOTA_COFINS
      ,CASE WHEN SITUACAO_TRIBUTARIA = '51' AND ALIQUOTAICMSDIF >= 100 THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', ALIQUOTA_ICMS, 0)
       ELSE
         ALIQUOTA_ICMS
       END ALIQUOTA_ICMS
      ,ALIQUOTA_IPI
      ,ALIQUOTA_PIS
      ,ALIQUOTA_ST
      ,ALIQUOTA_CREDITO_SN
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100)) THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', BASE_ICMS, 0)
       ELSE
         BASE_ICMS
       END BASE_ICMS
      ,BASE_IPI
      ,BASE_ST
      ,BASE_II
      ,BASEBCR
      ,CFOP
      ,CLASSIFICFISCAL
      ,CODFILIALRETIRA
      ,COD_OPERACAO
      ,CODIGO_FABRICANTE
      ,CODIGO_SECAO
      ,CODIGO_DEPARTAMENTO
      ,CODIGO_FORNECEDOR
      ,CODPROD
      ,CODIGO_PRODUTO
      ,CODST
      ,DATA_FABRICACAO
      ,DATA_VALIDADE
      ,DESCRICAO_DEPARTAMENTO
      ,DESCRICAO_SECAO
      ,DIGITO_PRODUTO
      ,EAN
      ,EAN_UNIDADE
      ,EMBALAGEM
      ,EMBALAGEMMASTER
      ,EXTIPI
      ,FANTASIA
      ,FATORUNFARM
      ,FORNECEDOR
      ,GENERO
      ,INFO_TECNICA
      ,MARCA
      ,MODALIDADE_BC_ICMS
      ,MODALIDADE_BC_ST
      ,NATUREZAPRODUTO
      ,NCM
      ,NUM_TRANSACAO
      ,NUMERO_ADICAO
      ,NUMERO_LOTE
      ,NUMERO_SEQUENCIA
      ,NUMORIGINAL
      ,NUMERO_PEDIDO
      ,NUMERO_ITEM_PEDIDO
      ,NUMVOLUMESCONFERENCIA
      ,ORIGEM_MERCADORIA
      ,PERACRESCIMOCUSTO
      ,PERCDESC
      ,PERCENTUAL_MARGEM
      ,PERCENTUAL_REDUCAO_BC
      ,PERCENTUAL_REDUCAO_ST
      ,PERCIPIVENDA
      ,PESO_BRUTO
      ,PESOCX
      ,PESOEMBALAGEM
      ,PRECO_MAXIMO
      ,PRINCIPIOATIVO
      ,PRODUTO
      ,PTABELA
      ,PUNITCONT
      ,QT_LOTE
      ,QTCX
      ,QTD_CAIXA
      ,QTD_UNIDADE
      ,QTD_CAIXAS_MASTER
      ,QTD_PECAS_INTERM
      ,QTPECAS
      ,QTUN
      ,QTUNIT
      ,QTUNITCX
      ,QTUNITEMB
      ,QTD_EMBALAGEM
      ,UNIDADE_LICIT
      ,QT_UNIT_LICIT
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
            0
       ELSE
            CASE WHEN UNIDADE_LICIT IS NOT NULL THEN
              ROUND(QUANTIDADE * QT_UNIT_LICIT, 4)
            ELSE
              CASE WHEN (USAUNIDADEMASTER = 'S') AND (QTD_MASTER > 0) THEN
                   ROUND(QUANTIDADE / QTD_MASTER, 4)
              ELSE
                   ROUND(QUANTIDADE, 4)
            END END
       END AS QUANTIDADE_COMERCIAL
      ,QUANTIDADE_ENTREGA
      ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
            0
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                ROUND((QUANTIDADE * FATOR_CONVERSAO), 4)
            ELSE
               /*REMOVI ESTA ALTERAÇÃO QUE FOI FEITA NA ULTIMA VERSÃO, PORQUE ESTAVA CAUSANDO
                PROBLEMAS NOS CLIENTES, REJEITANDO AS NOTAS PELO ERRO 630 DEVIDO AO FATO DE ESTAR
                ALTERANDO A QUANTIDADE TRIBUTAVEL, COM ISSO A MULTIPLICAÇÃO FICARA ERRADA.
                OBS.: A QUANTIDADE TRIBUTAVEL DEVE SER SEMPRE A MENOR UNIDADE DO WINTHOR
                CASE WHEN (USAUNIDADEMASTER = 'S') AND (QTD_MASTER > 0) THEN
                   ROUND(QUANTIDADE / QTD_MASTER, 4)
                ELSE
                   ROUND(QUANTIDADE, 4)
                END*/
                ROUND(QUANTIDADE, 4)
            END
       END AS QUANTIDADE_TRIBUTAVEL
     ,CASE WHEN (NVL(FINALIDADENFE,'O') = 'C') THEN
            0
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO_EX,0) > 0 THEN
                 ROUND((QUANTIDADE * FATOR_CONVERSAO_EX), NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4))
            ELSE
                 CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                     ROUND((QUANTIDADE * FATOR_CONVERSAO), NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4))
                 ELSE
                     ROUND(QUANTIDADE, 4)
                 END
            END
       END AS QUANTIDADE_TRIBUTAVEL_EX
      ,RETIDO
      ,SIT_PIS_CONFINS
      ,SITUACAO_TRIBUTARIA
      ,SITUACAO_TRIBUTARIA_IPI
      ,STBCR
      ,STCLIENTEGNRE
      ,TIPO_QUANTIDADE
      ,TIPOESTOQUE
      ,TIPOMERC
      ,TIPOTRIBUTMEDIC
      ,TIPOSEPARACAO
      ,TOTPESOLIQUNIT
      ,UNIDADE AS UNIDADE_COMERCIAL
      ,CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
            UNIDADE_TRIB
       ELSE
            UNIDADE
       END AS UNIDADE_TRIBUTAVEL
     ,CASE WHEN NVL(FATOR_CONVERSAO_EX,0) > 0 THEN
            UNIDADE_TRIB_EX
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                 UNIDADE_TRIB
            ELSE
                 UNIDADE
            END
       END AS UNIDADE_TRIBUTAVEL_EX
      ,UNIDADEMASTER
      ,UNIDADE_EMBALAGEM
      ,VALOR_COFINS
      ,CASE WHEN (UNIDADE_LICIT IS NOT NULL) AND (QT_UNIT_LICIT > 0) THEN
         ROUND((VALOR_LIQUIDO / QT_UNIT_LICIT),10)
       ELSE
       CASE WHEN USAUNIDADEMASTER = 'S' THEN
         CASE WHEN (abs(ROUND(QTCONT * VALOR_LIQUIDO ,2) -
                     ROUND(ROUND(QUANTIDADE / QTD_MASTER, 4) * ROUND((VALOR_LIQUIDO * QTD_MASTER),10),2)) >= 0.01) AND (ROUND(QUANTIDADE * QTD_MASTER,4) > 0) THEN
                     ROUND(ROUND(QTCONT * VALOR_LIQUIDO,2) / ROUND(QUANTIDADE / QTD_MASTER, 4), 10)
         ELSE
           ROUND((VALOR_LIQUIDO * QTD_MASTER),10)
         END
       ELSE
         CASE WHEN (abs(round(QTCONT * VALOR_LIQUIDO,2) -
                      ROUND(ROUND(QUANTIDADE,4) * VALOR_LIQUIDO,2)) >= 0.01) AND (ROUND(QUANTIDADE,4) > 0) THEN
             ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE,4), 10)
         ELSE
             VALOR_LIQUIDO
         END
       END END VALOR_COMERCIAL
      ,VALOR_DESCONTO
      ,VALOR_DESCONTO_ADICAO
      ,VALOR_FRETE
      ,VALOR_ICMS
      ,VALOR_CREDITO_ICMS_SN
      ,VALOR_IPI
      ,VALOR_IPI_UNIDADE
      ,VALOR_LIQUIDO
      ,VALOR_PIS
      ,ROUND(DECODE(NVL(VALOR_LIQUIDO,0), 0, 0, QTCONT) * VALOR_LIQUIDO,2) AS VALOR_PRODUTOS
      ,VALOR_SEGURO
      ,VALOR_OUTROS
      ,VALOR_ST
      ,DECODE(COD_OPERACAO,'SD', VALOR_UNITARIO, 'SO', VALOR_UNITARIO, VALOR_TOT_EMBALAGEM) AS VALOR_TOT_EMBALAGEM
      ,VALOR_UN_EMBALAGEM
      ,VALOR_II
      ,VALOR_DESPESA_ADUANEIRA
      ,VALOR_IOF
      ,CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
            ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE * FATOR_CONVERSAO,4),10)
       ELSE
            CASE WHEN (ABS(ROUND(QTCONT * VALOR_LIQUIDO,2) -
                    ROUND(ROUND(QUANTIDADE,4) * VALOR_LIQUIDO,2)) >= 0.01) AND (ROUND(QUANTIDADE,4) > 0) THEN
                ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE,4), 10)
            ELSE
                VALOR_LIQUIDO
            END
       END  AS VALOR_TRIBUTAVEL
     ,CASE WHEN NVL(FATOR_CONVERSAO_EX,0) > 0 THEN
            ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE * FATOR_CONVERSAO_EX, NVL(PARAMFILIAL.OBTERCOMONUMBER('CASASFATORCONVUNTRIBNFE'), 4)),10)
       ELSE
            CASE WHEN NVL(FATOR_CONVERSAO,0) > 0 THEN
                 ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE * FATOR_CONVERSAO, 4),10)
            ELSE
                CASE WHEN (ABS(ROUND(QTCONT * VALOR_LIQUIDO,2) -
                     ROUND(ROUND(QUANTIDADE,4) * VALOR_LIQUIDO,2)) >= 0.01) AND (ROUND(QUANTIDADE,4) > 0) THEN
                     ROUND((QTCONT * VALOR_LIQUIDO) / ROUND(QUANTIDADE,4), 10)
                ELSE
                     VALOR_LIQUIDO
                END
            END
       END  AS VALOR_TRIBUTAVEL_EX
      ,VL_BASE_CONFINS
      ,VL_BASE_PIS
      ,VLBASEGNRE
      ,VLIPIPORKGVENDA
      ,VOLUME
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
      ,VLDESCSEMABATIMENTO
      ,VLABATIMENTO
      ,CODIGOANP
      ,VLTOTALIMPOSTOS
      ,NUMERO_FCI
      ,ALIQ_INSENCAO_ICMS
      ,VALOR_ISENCAO_ICMS
      ,COD_AUXILIAR_EMBALAGEM
      ,VLTOTALIMPOSTOSFEDERAL
      ,VLTOTALIMPOSTOSESTADUAL
      ,VLTOTALIMPOSTOSMUNICIPAL
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100)) THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', VALORICMSDIF, 0)
       ELSE
         VALORICMSDIF
       END VALORICMSDIF
      ,ALIQUOTAICMSDIF
      ,VLICMSDESONERACAO VALOR_ICMS_DESONERADO
      ,CODMOTIVOICMSDESONERADO COD_MOTIVO_DESONERACAO
      ,VICMSSTDESON VALOR_ICMS_ST_DESONERADO
      ,VALOR_IPI_OUTROS
      ,CASE WHEN (SITUACAO_TRIBUTARIA = '51') THEN
           VALOR_ICMS_OPERACAO  - VALORICMSDIF --Regra modificada a pedido do Lucas dia 30/03/2016
       ELSE
         CASE WHEN VALORICMSDIF  >= VALOR_ICMS THEN
           0
         ELSE
           VALOR_ICMS
         END
       END VALOR_ICMS_DEVIDO
      ,CASE WHEN ((SITUACAO_TRIBUTARIA = '51') AND
                  (ALIQUOTAICMSDIF >= 100)) THEN
         DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARGRUPOICMSDIFNFE', CODFILIAL), 'N'), 'S', VALOR_ICMS_OPERACAO, 0)
       ELSE
         VALOR_ICMS_OPERACAO
       END VALOR_ICMS_OPERACAO
      ,TIPO_PRESENCA_ADQUIRINTE
      ,NUMERO_DRAWBACK
      ,CODCEST
      ,CODENQUADRAMENTOIPI
      ,(BASE_ICMS / QUANTIDADE) AS BASE_ICMS_UNITARIO
      ,NUMCHAVEEXP
      ,NUMREGEXP
      ,ALIQFCPPART
      ,ALIQINTERNADEST
      ,ALIQINTERORIGPART
      ,DECODE(ISENTO_ICMS_UF_DEST, 'S',0,VLFCPPART) VLFCPPART
      ,VLBASEPARTDEST
      ,PERCPROVPART
      ,VLICMSDIFALIQPART
      ,DECODE(ISENTO_ICMS_UF_DEST, 'S',0,VLICMSPARTDEST) AS VLICMSPARTDEST
      ,DECODE(ISENTO_ICMS_UF_DEST, 'S',0,VLICMSPARTREM) AS VLICMSPARTREM
      ,VIASTRANSP
      ,VLAFRMM
      ,PROD_ANVISA
      ,PROD_RASTREADO
      ,VLBASEFCPICMS
      ,VLBASEFCPST
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLBCFCPSTRET
       END AS VLBCFCPSTRET
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         PERFCPSTRET
       END AS PERFCPSTRET
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLFCPSTRET
       END AS VLFCPSTRET
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
      ,numnota
      ,DATACONSOLIDACAOPREFAT
      ,PREFATURAMENTO
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
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLBCFCPSTRET_PCEST
       END AS VLBCFCPSTRET_PCEST
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         PERFCPSTRET_PCEST
       END AS PERFCPSTRET_PCEST
      ,CASE WHEN (SIGLA_UF_E = 'CE' AND SIGLA_UF_D = 'CE') THEN
         0--NÃO DEVE GERAR FCP ST RET PARA UF = CE
       ELSE
         VLFCPSTRET_PCEST
       END AS VLFCPSTRET_PCEST
      ,VLAPROXTRIB
      ,GERAGRPRETTRIB 
      ,VLPISRETORGPUB
      ,VLCOFINSRETORGPUB
      ,VLCSLLRETORGPUB
      ,VLIRPJRETORGPUB
      ,VLBCIRRFRETORGPUB      
      ,EXCLUIRICMSBASEPISCOFINS
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
      ,SOMARVALORDIFBCICMS
      ,VLFCPDIF
      ,INDDEDUZDESONERACAO
      ,NUMTRANSITEM
FROM   (SELECT PCMOVPREFAT.NUMTRANSVENDA AS NUM_TRANSACAO
              ,PCMOVPREFAT.CODPROD
              ,PCNFSAIDPREFAT.FINALIDADENFE
              --Melhoria HIS.03196.2014 - Eddy
              --,DECODE(PCMOVPREFAT.CODOPER, 'SD', DECODE(PCNFSAIDPREFAT.NUMTAB, 1, 'S', PCMOVCOMPLEPREFAT.USAUNIDADEMASTER), PCMOVCOMPLEPREFAT.USAUNIDADEMASTER) AS USAUNIDADEMASTER
              ,CASE WHEN (PCMOVPREFAT.CODOPER = 'SD') THEN
                     CASE WHEN (NVL(PCMOVPREFAT.TIPOEMBALAGEMPEDIDO, 'X') = 'X') THEN
                         DECODE(PCNFSAIDPREFAT.NUMTAB, 1, 'S', NVL(PCMOVCOMPLEPREFAT.USAUNIDADEMASTER, 'N'))
                     ELSE
                         DECODE(NVL(PCMOVPREFAT.TIPOEMBALAGEMPEDIDO, 'X'), 'M', 'S', NVL(PCMOVCOMPLEPREFAT.USAUNIDADEMASTER,'N'))
                     END
               ELSE
                 NVL(PCMOVCOMPLEPREFAT.USAUNIDADEMASTER, 'N')
               END AS USAUNIDADEMASTER
              ,NVL(PCMOVPREFAT.QTUNITCX, PCPRODUT.QTUNITCX) AS QTD_MASTER
              ,NVL(TRIM(PCMOVPREFAT.CODINTERNO), TO_CHAR(PCMOVPREFAT.CODPROD)) AS CODIGO_PRODUTO
              ,PCPRODUT.UNIDADETRIB AS UNIDADE_TRIB
              ,PCPRODUT.FATORCONVTRIB AS FATOR_CONVERSAO
              ,NVL(PCMOVCOMPLEPREFAT.UNIDADETRIBEX, PCPRODUT.UNIDADETRIBEX) AS UNIDADE_TRIB_EX
              ,ROUND(NVL(PCMOVCOMPLEPREFAT.FATORCONVTRIBEX, PCPRODUT.FATORCONVTRIBEX), 6) AS FATOR_CONVERSAO_EX
              ,PCMOVPREFAT.CODST AS CODST
              ,PCMOVPREFAT.CODOPER AS COD_OPERACAO
              ,PCMOVPREFAT.CODFILIALRETIRA
              ,CASE WHEN LENGTH(NVL(PCPRODUT.CODAUXILIAR, '')) IN (NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      CASE WHEN (PCMOVCOMPLEPREFAT.USAUNIDADEMASTER = 'S') THEN
                         TO_CHAR(PCPRODUT.CODAUXILIAR2)
                      ELSE
                         TO_CHAR(PCPRODUT.CODAUXILIAR)
                      END
                    WHEN (LENGTH(PCPRODUT.CODAUXILIAR) < NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      CASE WHEN (PCMOVCOMPLEPREFAT.USAUNIDADEMASTER = 'S') THEN
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR2), PCPRODUT.GTINCODAUXILIAR2,'0')
                      ELSE
                        LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
                      END
                ELSE
                  NULL
               END AS EAN
              ,PCMOVPREFAT.DV AS DIGITO_PRODUTO
              ,(NVL(TRIM(PCMOVPREFAT.PRODDESCRICAOCONTRATO),
                    NVL(TRIM(PCMOVPREFAT.COMPLEMENTO), TRIM(PCMOVPREFAT.DESCRICAO))) || ' ' ||
                    CASE WHEN LENGTH(PCPRODUT.SUBSTANCIA) > 0 THEN
                        '('||PCPRODUT.SUBSTANCIA||')' ELSE '' END ||
               DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE, 'N'),
                       'S',
                       DECODE(NVL(PCMOVCOMPLEPREFAT.USAUNIDADEMASTER, 'N'),
                              'S',
                              PCPRODUT.EMBALAGEMMASTER,
                              DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),
                                      'N',
                                      PCMOVPREFAT.EMBALAGEM,
                                      (PCEMBALAGEM.EMBALAGEM || ' QTD. ' ||
                                       LTRIM(to_char((PCMOVPREFAT.QTCONT /
                                      DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                                   0),
                                               0,
                                               1,
                                               PCEMBALAGEM.QTUNIT)),'999999999999999990.99')) || ' ' ||
                                      PCEMBALAGEM.UNIDADE || ' '))))) AS PRODUTO
              ,NVL(PCPRODUT.NATUREZAPRODUTO,
                   'X') AS NATUREZAPRODUTO
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
              --148.058921.2015 PERMITEINFOLEITRANSPCONSFINAL
              ,NVL(PCPRODFILIAL.INFTECNICA, '') || ' ' ||
              CASE WHEN (NVL(PCMOVCOMPLEPREFAT.ENVIARALIQREDUCAOPISCOFINS,'N') = 'S') THEN
                    ';%Red.Aliq.PIS ' || LTRIM(to_char(NVL(PCMOVCOMPLEPREFAT.ALIQREDUCAOPIS,0),'999999999999999990.99')) ||
                    ';%Red.Aliq.COFINS ' || LTRIM(to_char(NVL(PCMOVCOMPLEPREFAT.ALIQREDUCAOCOFINS,0),'999999999999999990.99'))
               END
               || ' ' ||DECODE(LENGTH(NVL(TRIM(PCMOVCOMPLEPREFAT.CODBENEFICIOFISCALCOMPLE),'')),'','','cBenef: '||TRIM(PCMOVCOMPLEPREFAT.CODBENEFICIOFISCALCOMPLE))|| ' ' ||
               ---------MELHORIA HIS.01182.2016 - EDDY
               CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIAINFOLOTENFE', PCMOVPREFAT.CODFILIAL), 'S') = 'S') THEN
                 TRIM((DECODE(NVL(LENGTH(NVL(TRIM(PCMOVPREFAT.NUMLOTE),
                                             '')),
                                  0),
                              0,
                              '',
                              ' N LT. ') || TRIM(PCMOVPREFAT.NUMLOTE) || ' ' ||
                 DECODE(NVL(LENGTH(NVL(TRIM(PCMOVPREFAT.NUMLOTE),
                                             '')),
                                  0),
                              0,
                              '',
                              ' DATA FAB.: ') ||
                 (SELECT TRUNC(NVL(PCMOVPREFAT.DATAFABRICACAO, PCLOTE.DATAFABRICACAO)) AS DATAFABRICACAO
                  FROM   PCLOTE
                  WHERE  PCLOTE.CODPROD = PCMOVPREFAT.CODPROD
                  AND    PCLOTE.CODFILIAL = NVL(PCMOVPREFAT.CODFILIALRETIRA,PCMOVPREFAT.CODFILIAL)
                  AND    PCLOTE.NUMLOTE = PCMOVPREFAT.NUMLOTE
                  AND    ROWNUM = 1) || ' ' ||
                  DECODE(NVL(LENGTH(NVL(TRIM(PCMOVPREFAT.NUMLOTE),
                                             '')),
                                0),
                            0,
                            '',
                            ' DATA VAL.: ') || (SELECT TRUNC(NVL(PCMOVPREFAT.DATAVALIDADE, PCLOTE.DTVALIDADE)) AS DTVALIDADE
                FROM   PCLOTE
                WHERE  PCLOTE.CODPROD = PCMOVPREFAT.CODPROD
                AND    PCLOTE.CODFILIAL = NVL(PCMOVPREFAT.CODFILIALRETIRA,PCMOVPREFAT.CODFILIAL)
                AND    PCLOTE.NUMLOTE = PCMOVPREFAT.NUMLOTE
                AND    ROWNUM = 1)))
              ELSE
                 ''
              END
              ------------------
              ||' '||
              TRIM((
                 --Melhoria DDFISCAL-1759 - Frederico
                CASE WHEN (PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIADADOSSECSAUDE', NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL)) = 'S') THEN
                  ('Cód. Registro Médico: '|| PCPRODUT.REGISTROMSMED || ' ' ||
                   'Marca: '||PCMARCA.MARCA || ' ' ||
                  (SELECT 'Princípio Ativo: '|| PCPRINCIPATIVO.DESCRICAO
                   FROM   PCPRINCIPATIVO
                   WHERE  PCPRINCIPATIVO.CODPRINCIPATIVO = PCPRODUT.CODPRINCIPATIVO))
                ELSE
                  ''
                END

               ||' '||
                  DECODE(NVL(PCPRODUT.ENVIAINFTECNICANFE, 'S'),'S', PCPRODUT.INFORMACOESTECNICAS, NULL) ||
                    ---
                     (SELECT DECODE(TO_CHAR(MAX(PCCERTIFIC.CODCERTIFIC)), '', '', ' - ' || 'CERTIFIC.: ' || to_char(MAX(PCCERTIFIC.CODCERTIFIC)) || ' ' || MAX(PCCERTIFIC.MENSAGEMNF))
                        FROM PCCERTIFIC
                       WHERE 1=1
                         AND PCMOVPREFAT.CODPROD = PCCERTIFIC.CODPROD
                         AND PCMOVPREFAT.CODFILIAL = PCCERTIFIC.CODFILIAL
                        --esta clausula serve para pegar sempre o certificado mais atual
                         AND TRUNC(PCCERTIFIC.DTVENC) = (SELECT TRUNC(MAX(F1.DTVENC)) FROM PCCERTIFIC F1
                                                          WHERE F1.CODPROD = PCCERTIFIC.CODPROD
                                                            AND F1.CODFILIAL = PCCERTIFIC.CODFILIAL
                                                            AND NVL(F1.NUMLOTE,0) = NVL(PCCERTIFIC.NUMLOTE,0)))
                    ----
                    )
                    || ' ' ||
                    DECODE(NVL(LENGTH(NVL(PCMOVPREFAT.REFCOR,'')),0),0,'','REF.DA COR: ' || PCMOVPREFAT.REFCOR) ||
                    CASE WHEN (PCPRODUT.OBS = 'EQ' AND PCEQUIPAMENTO.IDPATRIMONIO IS NOT NULL) THEN
                      CASE WHEN (PCMOVPREFAT.CODOPER = 'SO' OR PCMOVPREFAT.CODOPER = 'SD') THEN
                          'ID.EQUIP.:'|| PCEQUIPAMENTO.IDPATRIMONIO || ' ' ||
                          'COD.EQUIP.: ' || PCEQUIPAMENTO.CODEQUIPAMENTO || ' ' ||
                          'MARCA EQUIP.: ' || PCEQUIPAMENTO.MARCA || ' ' ||
                          'VOLT.EQUIP.: ' || PCEQUIPAMENTO.VOLTAGEM
                      END
                    ELSE '' END || CASE WHEN (NVL(PCMOVPREFAT.VOLUMEDESEJADO,0) > 0) THEN ' - ' || PCMOVPREFAT.VOLUMEDESEJADO ||' ML' ELSE '' END
                    ||
            CASE WHEN (PCMOVCOMPLEPREFAT.NUMFCI IS NOT NULL) AND (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('NUMFCIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                ' PERC.PARC.FCI: ' || NVL(PCMOVCOMPLEPREFAT.percconteudoimpfci, 0) ||
                ' - N. FCI: ' || PCMOVCOMPLEPREFAT.numfci
            ELSE
                ''
            END || ' ' ||
            CASE WHEN NVL(PCMOVCOMPLEPREFAT.VLACRESCIMOFUNCEP, 0) > 0 THEN
                  ' VBCFCP: ' || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBASEFCPICMS, 0),2),'999999999999999990.99')) ||
                  ' PFCP: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLEPREFAT.PERACRESCIMOFUNCEP, 0),'999999999999999990.99')) ||
                  ' VFCP: '   || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLACRESCIMOFUNCEP, 0),2),'999999999999999990.99'))
             END ||
             CASE WHEN NVL(PCMOVCOMPLEPREFAT.VLFECP, 0) > 0 THEN
                  ' VBCFCPST: ' || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST, 0),2),'999999999999999990.99')) ||
                  ' PFCPST: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLEPREFAT.ALIQICMSFECP, 0),'999999999999999990.99')) ||
                  ' VFCPST: '   || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLFECP, 0),2),'999999999999999990.99'))
             END ||
             CASE WHEN ((NVL(PCMOVPREFAT.SITTRIBUT, '55') IN ('60','500')) AND (SQL_NFE_CABECALHO_SAIDA.CONTRIBUINTE = 'S')) THEN
                 CASE WHEN NVL(PCMOVCOMPLEPREFAT.VLFCPSTRET, 0) > 0 THEN
                      ' VBCFCPSTRET: ' || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBCFCPSTRET, 0),2),'999999999999999990.99')) ||
                      ' PFCPSTRET: '   || TRIM(TO_CHAR(NVL(PCMOVCOMPLEPREFAT.PERFCPSTRET, 0),'999999999999999990.99')) ||
                      ' VFCPSTRET: '   || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLFCPSTRET, 0),2),'999999999999999990.99'))
                 WHEN NVL(PCEST.VLFCPSTRET, 0) > 0 THEN
                      ' VBCFCPSTRET: ' || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCEST.VLBCFCPSTRET, 0),2),'999999999999999990.99')) ||
                      ' PFCPSTRET: '   || TRIM(TO_CHAR(NVL(PCEST.PERFCPSTRET, 0),'999999999999999990.99')) ||
                      ' VFCPSTRET: '   || TRIM(TO_CHAR(ROUND(PCMOVPREFAT.QTCONT * NVL(PCEST.VLFCPSTRET, 0),2),'999999999999999990.99'))
                 END
             END ||
             CASE WHEN (PARAMFILIAL.OBTERCOMOVARCHAR2('GERACHAVEULTENTINFADPRODNFE',
                                                      NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL)) = 'S') THEN
                (SELECT ' CHAVE ULTIMA ENTRADA: ' || TRIM(PCNFENT.CHAVENFE)
                   FROM PCNFENT, PCEST
                  WHERE PCEST.CODFILIAL = NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL)
                    AND PCEST.CODPROD = PCMOVPREFAT.CODPROD
                    AND PCEST.NUMTRANSENTULTENT = PCNFENT.NUMTRANSENT
                    AND PCMOVPREFAT.CODFISCAL BETWEEN 5000 AND 6999
                    AND NVL(PCMOVPREFAT.ST, 0) > 0
                    AND ROWNUM = 1)
               ELSE
                ''
             END ||
             --produtos perigosos
             CASE WHEN (PCPRODUT.CODRISCO IS NOT NULL AND PCPRODUT.CODACONDICIONAMENTO IS NOT NULL AND PCPRODUT.CODONU IS NOT NULL AND (PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.PESOBRUTO, 0)) > 0) THEN
                  ' PESO BRUTO DO PRODUTO PERIGOSO: ' || TRIM(TO_CHAR((PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.PESOBRUTO, 0)),'999999999999999990.99')) || ' KG'
             ELSE
                  ''
             END ||
              CASE WHEN ((NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARCHAVENATURAL',NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL)),'N') = 'S') AND
                  (NVL(PCMOVPREFAT.ST,0) + NVL(PCMOVPREFAT.STBCR, 0) + NVL(PCMOVPREFAT.VLDESPADICIONAL,0) > 0) ) THEN
                 NVL((SELECT '##CHAVENATURAL='||
                             SUBSTR(E.CHAVENFE, 1,2)|| --UF
                             SUBSTR(E.CHAVENFE, 7,14)||--CNPJ
                             SUBSTR(E.CHAVENFE, 21,2)||--MODELO
                             SUBSTR(E.CHAVENFE, 23,3)||--SERIE
                             SUBSTR(E.CHAVENFE, 26,9) ||--NUMNOTA
                             LPAD(NVL(MCE.NUMSEQENT, ME.NUMSEQ),3,'0')|| '##' AS CHAVENATURAL
                      FROM PCNFENT E,
                           PCMOV ME,
                           PCMOVCOMPLE MCE,
                           PCEST
                      WHERE 1=1
                       AND E.NUMTRANSENT = ME.NUMTRANSENT
                       AND E.NUMNOTA = ME.NUMNOTA
                       AND ME.NUMTRANSITEM = MCE.NUMTRANSITEM
                       AND ME.CODPROD = PCMOVPREFAT.CODPROD
                       AND PCMOVPREFAT.CODFISCAL BETWEEN 5000 AND 6999
                       AND (NVL(PCMOVPREFAT.ST,0) + NVL(PCMOVPREFAT.STBCR, 0) + NVL(PCMOVPREFAT.VLDESPADICIONAL,0)) > 0
                       AND PCEST.NUMTRANSENTULTENT = E.NUMTRANSENT
                       AND PCEST.CODFILIAL = NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL)
                       AND PCEST.CODPROD = PCMOVPREFAT.CODPROD
                       AND ROWNUM = 1), PCPRODFILIAL.CHAVENATURAL)
               END ||
             CASE WHEN ((NVL(PCMOVPREFAT.SITTRIBUT, '55') = '61') AND 
                        (NVL(PCMOVCOMPLEPREFAT.VICMSMONORET, 0) > 0) AND 
                        (SQL_NFE_CABECALHO_SAIDA.CONSUMIDOR_FINAL = 'S') AND
                        (SQL_NFE_CABECALHO_SAIDA.CONTRIBUINTE = 'N')) THEN
                  ' ICMS monofásico sobre combustíveis cobrado anteriormente conforme Convênio ICMS 199/2022.'
             END
            ) AS INFO_TECNICA
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
            ,REPLACE(PCMOVPREFAT.NBM, '.', '') AS NCM
            ,
            CASE
                WHEN (PCMOVCOMPLEPREFAT.EXTIPI BETWEEN '01' AND '09') THEN
                    LPAD(TO_CHAR(PCMOVCOMPLEPREFAT.EXTIPI), 2,'0')
              ELSE
            CASE
                WHEN (PCMOVCOMPLEPREFAT.EXTIPI = '0') THEN
             NULL
            END
            END AS EXTIPI
            ,(SUBSTR(PCMOVPREFAT.NBM,
                     1,
                     2)) AS GENERO
            ,PCMOVPREFAT.CODFISCAL AS CFOP
            ,CASE
              WHEN PCMOVCOMPLEPREFAT.UNIDADELICIT IS NOT NULL THEN
                   PCMOVCOMPLEPREFAT.UNIDADELICIT
            ELSE
              CASE
                WHEN PCMOVCOMPLEPREFAT.USAUNIDADEMASTER = 'S' THEN
                  PCPRODUT.UNIDADEMASTER
               ELSE
                 DECODE(PCMOVPREFAT.CODOPER, 'SD', DECODE(CASE WHEN (NVL(PCMOVPREFAT.TIPOEMBALAGEMPEDIDO, 'X') = 'X') THEN
                         DECODE(PCNFSAIDPREFAT.NUMTAB, 1, 'S', NVL(PCMOVCOMPLEPREFAT.USAUNIDADEMASTER, 'N'))
                     ELSE
                         DECODE(NVL(PCMOVPREFAT.TIPOEMBALAGEMPEDIDO, 'X'), 'M', 'S', NVL(PCMOVCOMPLEPREFAT.USAUNIDADEMASTER,'N'))
                     END, 'S', PCPRODUT.UNIDADEMASTER, PCMOVPREFAT.UNIDADE),PCMOVPREFAT.UNIDADE)
             END END AS UNIDADE
            ,PCMOVPREFAT.QTCONT AS QUANTIDADE
            ,PCMOVPREFAT.QTCONT
            ,CASE
               WHEN (ORGAO_PUBLICO = 'S') THEN
                DECODE(NVL(PCNFSAIDPREFAT.DEDUZIRDESONERORGAOPUB, 'N'),
                      'S',
                       ROUND((PCMOVPREFAT.PTABELA
                          + NVL(PCMOVPREFAT.VLDESCRODAPE, 0)
                          - NVL(PCMOVPREFAT.VLDESCICMISENCAO, 0)),
                          2),
                       ROUND((PCMOVPREFAT.PTABELA
                          + NVL(PCMOVPREFAT.VLDESCRODAPE, 0)
                          + NVL(PCMOVPREFAT.VLDESCICMISENCAO, 0)),
                          2))
               ELSE
                (DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT) -
                CASE WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                      NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',PCFILIAL.CODIGO),'S') = 'N') THEN
                      0
                ELSE NVL(PCMOVPREFAT.ST,0) END -
                NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                     0) -
                CASE WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                      NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                      0
                ELSE NVL(PCMOVPREFAT.VLIPI,0) END -
                 DECODE(PCMOVPREFAT.CODOPER, 'SD', NVL(PCMOVPREFAT.VLFRETE,0), 0)
                 - NVL(PCMOVPREFAT.VLREPASSE,0)
                      +
                DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N','',PCPRODFILIAL.PRECOUTILIZADONFE), PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                          PCFILIAL.CODIGO),
                            'L'))),
                        'L',
                        0,
                        'LR',
                                           NVL(PCMOVPREFAT.VLREPASSE,0),
                                           NVL(PCMOVPREFAT.VLREPASSE,0) +
                        DECODE(NVL(PCMOVPREFAT.PTABELA,
                                   0),
                               0,
                               0,
                               DECODE(SIGN(NVL(PCMOVPREFAT.PTABELA,
                                               0) - DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT)),
                                      -1,
                                      0,
                                      NVL(PCMOVPREFAT.PTABELA,
                                          0) - NVL(DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT),
                                                   0)) + DECODE(NVL(PCNFSAIDPREFAT.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, NVL(PCMOVPREFAT.VLDESCICMISENCAO,0)) )) +
                NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                     0) + DECODE(PCMOVPREFAT.CODOPER, 'SD', 0, NVL(PCMOVPREFAT.VLDESCSUFRAMA,
                               0)) + NVL(PCMOVPREFAT.VLSUFRAMA,
                                         0) +
                 NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,
                               0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS,
                                         0) )
             END AS VALOR_UNITARIO
            ,(DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE, 'N'),
               'C',
               DECODE(NVL(PCMOVCOMPLEPREFAT.BONIFIC,'N') , 'S', PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT),
               --não subtotaliza se não tiver impostos agregados ao valor do produto
               CASE WHEN (((NVL(PCMOVPREFAT.VLIPI,0) + NVL(PCMOVPREFAT.ST,0) + NVL(PCMOVCOMPLEPREFAT.VLFECP, 0) + NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0)) > 0) AND (NVL(PCMOVPREFAT.CODOPER, 'S') <> 'SD') ) THEN
                   ((ROUND((DECODE( NVL(PCMOVCOMPLEPREFAT.BONIFIC,'N') , 'S', PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT) - NVL(PCMOVPREFAT.VLIPI,0) - NVL(PCMOVPREFAT.ST,0) -
                      DECODE(NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST, 0), 0, 0,NVL(PCMOVCOMPLEPREFAT.VLFECP, 0))
                     ) * PCMOVPREFAT. QTCONT, (CASE WHEN PCMOVPREFAT.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) ))
                     / PCMOVPREFAT.QTCONT
                     + (ROUND(NVL(PCMOVPREFAT.VLIPI,0) * PCMOVPREFAT.QTCONT, (CASE WHEN PCMOVPREFAT.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) )) / PCMOVPREFAT.QTCONT
                     + (ROUND(NVL(PCMOVPREFAT.ST,0) * PCMOVPREFAT.QTCONT, (CASE WHEN PCMOVPREFAT.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) )) / PCMOVPREFAT.QTCONT
                     + (ROUND(DECODE(NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST, 0), 0, 0,NVL(PCMOVCOMPLEPREFAT.VLFECP, 0)) * PCMOVPREFAT.QTCONT, (CASE WHEN PCMOVPREFAT.QTCONT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END) ))
                     / PCMOVPREFAT.QTCONT)
               ELSE
                     DECODE(NVL(PCMOVCOMPLEPREFAT.BONIFIC,'N') , 'S', PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT)
               END
               )
              -
           CASE WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                             NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',PCFILIAL.CODIGO),'S') = 'N') THEN
                      0
                ELSE
                      DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE, 'N'),
                        'C',
                        NVL(PCMOVPREFAT.ST,0),
                          DECODE(PCMOVPREFAT.CODOPER,
                            'SD',
                            NVL(PCMOVPREFAT.ST,0),
                            ((ROUND(NVL(PCMOVPREFAT.ST,0) * PCMOVPREFAT.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2))) / PCMOVPREFAT.QTCONT)
                          )
                        )
                END -
                (DECODE(PCNFSAIDPREFAT.TIPOVENDA, 'DF', NVL(PCMOVPREFAT.VLSEGURO,0), 0))-
                (DECODE(NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST, 0), 0, 0,DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE, 'N'), 'C', PCMOVCOMPLEPREFAT.VLFECP, (ROUND(NVL(PCMOVCOMPLEPREFAT.VLFECP, 0) * PCMOVPREFAT.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2))/PCMOVPREFAT.QTCONT)) )) -
                NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR, 0) -
                CASE WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                            NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                      0
                ELSE
                      DECODE(NVL(PCNFSAIDPREFAT.FINALIDADENFE, 'N'), 'C', NVL(PCMOVPREFAT.VLIPI,0), ((ROUND(NVL(PCMOVPREFAT.VLIPI,0) * PCMOVPREFAT.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2))) / PCMOVPREFAT.QTCONT))
                END -
                 --Na nfe 4.0 o ipiDevol compoe o valor total da nota, e por isso deve ser subtraido do valor do produto
                CASE WHEN (PCMOVPREFAT.CODOPER = 'SD') THEN
                     (NVL(PCMOVPREFAT.VLDESPDENTRONF,0) -
                      DECODE(NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC, 0),
                            0,
                            0,
                            NVL(PCMOVCOMPLEPREFAT.VLIPIOUTRAS, 0))) + NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC, 0)
                ELSE
                     0
                END -
                DECODE(PCMOVPREFAT.CODOPER, 'SD',NVL(PCMOVPREFAT.VLFRETE,0),0) +
                NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,0) +
                DECODE(PCMOVPREFAT.CODOPER, 'SD', 0, ROUND(NVL(PCMOVPREFAT.VLDESCSUFRAMA,0) * PCMOVPREFAT.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOVPREFAT.QTCONT) +
                DECODE(PCMOVPREFAT.CODOPER, 'SD', 0, NVL(PCMOVPREFAT.VLSUFRAMA,0))) +
                DECODE(PCMOVPREFAT.CODOPER, 'SD', 0, DECODE(NVL(PCNFSAIDPREFAT.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, ROUND(NVL(PCMOVPREFAT.VLDESCICMISENCAO,0) * PCMOVPREFAT.QTCONT,NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOVPREFAT.QTCONT)) +
                CASE WHEN ( (PCMOVPREFAT.CODOPER = 'SD') AND (NVL(PCMOVCOMPLEPREFAT.PERCICMSDESONERACAO,0) > 0) AND (NVL(PCMOVCOMPLEPREFAT.VLICMSDESONERACAO,0) > 0) ) THEN
                    PCMOVCOMPLEPREFAT.VLICMSDESONERACAO
                ELSE
                    0
                END  +
             CASE WHEN (ORGAO_PUBLICO = 'S') THEN
                  0
             ELSE
                  DECODE(PCMOVPREFAT.CODOPER, 'SD',
                         -- Saida de Devolu??o
                         (NVL(PCMOVPREFAT.VLDESCONTO,0) +
                          NVL(NVL(PCMOVPREFAT.VLDESCSUFRAMA,PCMOVPREFAT.VLSUFRAMA),0)),
                         -- Normal
                         CASE WHEN (PCNFSAIDPREFAT.CONDVENDA = 4 OR NVL(PCNFSAIDPREFAT.NUMCUPOM,0) > 0) THEN

                              DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,
                                              NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N',
                                                                              '',
                                                                              PCPRODFILIAL.PRECOUTILIZADONFE),
                                                      PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', PCFILIAL.CODIGO),'L'))),
                                   'L',


                                      (NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,0) + NVL
                                      (PCMOVPREFAT.VLDESCREDUCAOPIS,0)),
                                   'LR', 0,
                                      NVL(PCMOVCOMPLEPREFAT.VLSUBTOTDESCONTO,0))
                         ELSE
                              (DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,
                                               NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N',
                                                                               '',
                                                                               PCPRODFILIAL.PRECOUTILIZADONFE),
                                                       PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', PCFILIAL.CODIGO), 'L'))),
                                   'L',
                                      0,
                                   'LR',
                                      0,
                                      DECODE(NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0), 0,
                                        (ROUND( PCMOVPREFAT.QTCONT *
                                        (DECODE((NVL(PCMOVPREFAT.PTABELA, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)),
                                                     0,
                                                       0,
                                                       DECODE(SIGN((NVL(PCMOVPREFAT.PTABELA, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)) - DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT)),
                                                                   -1,
                                                                   0,
                                                                   (NVL(PCMOVPREFAT.PTABELA, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)) -



                                                                   NVL(DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT),0)))
                                        ), NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOVPREFAT.QTCONT),

                                        (ROUND( PCMOVPREFAT.QTCONT *
                                        (DECODE((NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)),
                                                     0,
                                                       0,
                                                       DECODE(SIGN(NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)),
                                                                   -1,
                                                                   0,
                                                                   NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)))
                                        ), NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOVPREFAT.QTCONT))
                                   + (NVL(PCMOVPREFAT.VLDESCPISSUFRAMA, 0)))) +
                               (
                                --Melhoria HIS.04338.2015 - Eddy
                                CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                           ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  PCNFSAIDPREFAT.DTSAIDA))) THEN
                                       0
                                     ELSE
                                        (ROUND((NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS, 0)) *
                                               PCMOVPREFAT.QTCONT, NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2)) / PCMOVPREFAT.QTCONT)
                                END
                                )
                         END +
                         --utilizado somente para equipe de medicamentos
                         (CASE WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',PCFILIAL.CODIGO) = 'L' THEN
                           NVL(PCMOVCOMPLEPREFAT.VLDESCCOMERCIALICMISENCAO,0)
                         ELSE
                           0
                         END)
                         )
             END  AS VALOR_LIQUIDO
            ,CASE WHEN (PCNFSAIDPREFAT.CONDVENDA = 4) AND (PCNFSAIDPREFAT.NUMCUPOM > 0) then
                NVL(PCMOVCOMPLEPREFAT.VLSUBTOTITEM,
                    DECODE(PCMOVPREFAT.TRUNCARITEM,
                           'S',
                           TRUNC((DECODE(PCMOVCOMPLEPREFAT.BONIFIC,
                                        'S',
                                        0,
                                        PCMOVPREFAT.PUNITCONT) -
                                 NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                                     0) -
                                 DECODE(PCMOVPREFAT.CODOPER,
                                        'SD',
                                        NVL(PCMOVPREFAT.VLFRETE,
                                            0),
                                        0) +
                                 NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                                     0)) *
                                 PCMOVPREFAT.QTCONT,
                                 2),
                           ROUND((DECODE(PCMOVCOMPLEPREFAT.BONIFIC,
                                        'S',
                                        0,
                                        PCMOVPREFAT.PUNITCONT) -
                                 NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                                     0) -
                                 DECODE(PCMOVPREFAT.CODOPER,
                                        'SD',
                                        NVL(PCMOVPREFAT.VLFRETE,
                                            0),
                                        0) +
                                 NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                                     0)) *
                                 PCMOVPREFAT.QTCONT,
                                 2)))
               WHEN (ORGAO_PUBLICO = 'S') THEN
                ROUND(PCMOVPREFAT.QTCONT *
                      (PCMOVPREFAT.PTABELA + NVL(PCMOVPREFAT.VLDESCRODAPE,
                                           0) +
                      DECODE(NVL(PCNFSAIDPREFAT.DEDUZIRDESONERORGAOPUB, 'N'), 'S', 0, NVL(PCMOVPREFAT.VLDESCICMISENCAO,0))),
                      2)
               ELSE
                ROUND(((DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S', 0, PCMOVPREFAT.PUNITCONT) - NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                                             0) -
                                             DECODE(PCMOVPREFAT.CODOPER, 'SD', NVL(PCMOVPREFAT.VLFRETE,0),0) +
                      NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                           0))) * PCMOVPREFAT.QTCONT ,2)
             END AS PRECO_PRODUTO
           /*               -- Campo n?o utilizado
            ,CASE
               WHEN (ORGAO_PUBLICO = 'S') THEN
                ROUND(PCMOVPREFAT.QTCONT *
                      (PCMOVPREFAT.PTABELA + NVL(PCMOVPREFAT.VLDESCRODAPE,
                                           0) +
                      NVL(PCMOVPREFAT.VLDESCICMISENCAO,
                           0)),
                      2)
               ELSE
                ROUND((DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT) - NVL(PCMOVPREFAT.ST,
                                             0) -
                      NVL(PCMOVIMPOSTOS.VLICMSCOMPLEMENTAR,
                           0) - NVL(PCMOVPREFAT.VLIPI,
                                     0) - DECODE(PCMOVPREFAT.CODOPER, 'SD', NVL(PCMOVPREFAT.VLFRETE,0),0)
                                                                  - NVL(PCMOVPREFAT.VLREPASSE,0)+
                      NVL(PCMOVPREFAT.VLDESCPISSUFRAMA,
                           0) + DECODE(PCMOVPREFAT.CODOPER, 'SD', 0, NVL(PCMOVPREFAT.VLDESCSUFRAMA,
                               0)) + NVL(PCMOVPREFAT.VLSUFRAMA,
                                               0) +
                      NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,
                                     0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS,
                                               0)  ) * PCMOVPREFAT.QTCONT +
                                              ROUND(DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE, NVL(PCCLIENT.PRECOUTILIZADONFE,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                                PCFILIAL.CODIGO),
                                  'L'))),
                              'L',
                              0,
                                                        'LR',
                                           NVL(PCMOVPREFAT.VLREPASSE,0),
                                           NVL(PCMOVPREFAT.VLREPASSE,0) +
                              DECODE(NVL(PCMOVPREFAT.PTABELA,
                                         0),
                                     0,
                                     0,
                                     DECODE(SIGN(NVL(PCMOVPREFAT.PTABELA,
                                                     0) - DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT)),
                                            -1,
                                            0,
                                            NVL(PCMOVPREFAT.PTABELA,
                                                0) - NVL(DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT),
                                                         0))+ NVL(PCMOVPREFAT.VLDESCICMISENCAO,
                     0)))* PCMOVPREFAT.QTCONT,2)
                     ,2)
             END AS VALOR_PRODUTOS
               --*/
            ,CASE WHEN (LENGTH(PCPRODUT.CODAUXILIARTRIB) <= NVL(PCPRODUT.GTINCODAUXILIARTRIB,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIARTRIB), PCPRODUT.GTINCODAUXILIARTRIB,'0')
                  WHEN (LENGTH(PCPRODUT.CODAUXILIAR) <= NVL(PCPRODUT.GTINCODAUXILIAR,0)) THEN
                      LPAD(TO_CHAR(PCPRODUT.CODAUXILIAR), PCPRODUT.GTINCODAUXILIAR,'0')
             ELSE
                NULL
             END AS EAN_UNIDADE
            ,ROUND(NVL(PCMOVPREFAT.VLFRETE ,0) * QTCONT,2) AS VALOR_FRETE
            ,ROUND((PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.VLSEGURO,0)),2) AS VALOR_SEGURO
            ,CASE
                     WHEN (ORGAO_PUBLICO = 'S') THEN
                      0
                     ELSE
                     DECODE(PCMOVPREFAT.CODOPER, 'SD',
                         -- Saida de Devolu??o
                         ROUND(((ROUND(NVL(PCMOVPREFAT.VLDESCONTO,0) * PCMOVPREFAT.QTCONT ,2) / PCMOVPREFAT.QTCONT) + NVL(NVL(PCMOVPREFAT.VLDESCSUFRAMA, PCMOVPREFAT.VLSUFRAMA),0)) * PCMOVPREFAT.QTCONT, 2),
                         -- Normal
                         CASE WHEN (PCNFSAIDPREFAT.CONDVENDA = 4 OR NVL(PCNFSAIDPREFAT.NUMCUPOM,0) > 0)
                         THEN
                         DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE,NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N','',PCPRODFILIAL.PRECOUTILIZADONFE),PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                               PCFILIAL.CODIGO),
                                 'L'))),
                             'L', (NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS,
                                   0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS,
                                              0))
                                              , 'LR', 0,
                             ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLSUBTOTDESCONTO,0), 2) )
                         ELSE ROUND((DECODE(NVL(PCMOVCOMPLEPREFAT.PRECOUTILIZADONFE, NVL(NVL(DECODE(NVL(PCPRODFILIAL.PRECOUTILIZADONFE, 'N'), 'N','',PCPRODFILIAL.PRECOUTILIZADONFE),PCCLIENT.PRECOUTILIZADONFE),NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',
                                                               PCFILIAL.CODIGO),
                                 'L'))),
                             'L',
                                 0,
                             'LR',0,
                                DECODE(NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0), 0,
                                 (ROUND( PCMOVPREFAT.QTCONT *
                                      (DECODE((NVL(PCMOVPREFAT.PTABELA, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)),
                                                   0,
                                                     0,
                                                     DECODE(SIGN((NVL(PCMOVPREFAT.PTABELA, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)) - DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT)),
                                                                 -1,
                                                                 0,
                                                                 (NVL(PCMOVPREFAT.PTABELA, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)) -
                                                                 NVL(DECODE(PCMOVCOMPLEPREFAT.BONIFIC, 'S',PCMOVPREFAT.PBONIFIC, PCMOVPREFAT.PUNITCONT),0)))
                                      ), 2) / PCMOVPREFAT.QTCONT),
                                      (GREATEST((ROUND( PCMOVPREFAT.QTCONT *
                                      (DECODE((NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0)),
                                                   0,
                                                     0,
                                                     DECODE(SIGN((NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0))),
                                                                 -1,
                                                                 0,
                                                                 (NVL(PCMOVCOMPLEPREFAT.VLDESCONTONF, 0) - NVL(PCMOVPREFAT.VLREPASSE, 0))))
                                      ), 2) / PCMOVPREFAT.QTCONT)

                                      , 0)) ))
                                 +
                           (NVL(PCMOVPREFAT.VLDESCPISSUFRAMA, 0) +
                           CASE WHEN (PCMOVCOMPLEPREFAT.CODMOTIVOICMSDESONERADO  IN ('7', '8')) THEN
                                     0
                           ELSE
                                     NVL(NVL(PCMOVPREFAT.VLDESCSUFRAMA,PCMOVPREFAT.VLSUFRAMA),0)
                           END)             ) * PCMOVPREFAT.QTCONT , 2) END +
                        ROUND((
                        (
                        --Melhoria HIS.04338.2015 - Eddy
                        CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE', PCFILIAL.CODIGO) = 'N') AND
                                   ((PCCLIENT.SULFRAMA IS NOT NULL) AND (PCCLIENT.DTVENCSUFRAMA >  PCNFSAIDPREFAT.DTSAIDA))) THEN
                                       0
                             ELSE
                                CASE WHEN (PCNFSAIDPREFAT.CONDVENDA = 4 OR NVL(PCNFSAIDPREFAT.NUMCUPOM,0) > 0) THEN
                                   0
                                 ELSE
                                   (NVL(PCMOVPREFAT.VLDESCREDUCAOCOFINS, 0) + NVL(PCMOVPREFAT.VLDESCREDUCAOPIS, 0))
                                 END
                        END
                        )) * QTCONT,2) +
                        --utilizado somente para equipe de medicamentos
                        ROUND(
                          (CASE WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',PCFILIAL.CODIGO) = 'L' THEN
                            NVL(PCMOVCOMPLEPREFAT.VLDESCCOMERCIALICMISENCAO,0)
                          ELSE
                            0
                          END) * PCMOVPREFAT.QTCONT, 2)
                        )
                   END AS VALOR_DESCONTO
            ,(NVL(PCMOVPREFAT.PESOBRUTO,
                  0) * PCMOVPREFAT.QTCONT) AS PESO_BRUTO
            ,NVL(PCMOVPREFAT.PERCIPI,
                 0) AS PERCIPIVENDA
            ,NVL(PCMOVPREFAT.VLIPIPORKG,
                 0) AS VLIPIPORKGVENDA
            ,PCMOVPREFAT.TIPOMERC
            ,PCMOVPREFAT.NUMSEQ AS NUMERO_ADICAO
            ,PCMOVPREFAT.NUMSEQ AS NUMERO_SEQUENCIA
            ,0 AS VALOR_DESCONTO_ADICAO
            ,PCMOVPREFAT.NUMLOTE AS NUMERO_LOTE
            ,(SELECT TRUNC(NVL(PCMOVPREFAT.DATAFABRICACAO, PCLOTE.DATAFABRICACAO)) AS DATAFABRICACAO 
              FROM   PCLOTE
              WHERE  PCLOTE.CODPROD = PCMOVPREFAT.CODPROD
              AND    PCLOTE.CODFILIAL = NVL(PCMOVPREFAT.CODFILIALRETIRA,PCMOVPREFAT.CODFILIAL)
              AND    PCLOTE.NUMLOTE = PCMOVPREFAT.NUMLOTE
              AND    ROWNUM = 1) AS DATA_FABRICACAO
            ,(SELECT TRUNC(NVL(PCMOVPREFAT.DATAVALIDADE, PCLOTE.DTVALIDADE)) AS DTVALIDADE
              FROM   PCLOTE
              WHERE  PCLOTE.CODPROD = PCMOVPREFAT.CODPROD
              AND    PCLOTE.CODFILIAL = NVL(PCMOVPREFAT.CODFILIALRETIRA,PCMOVPREFAT.CODFILIAL)
              AND    PCLOTE.NUMLOTE = PCMOVPREFAT.NUMLOTE
              AND    ROWNUM = 1) AS DATA_VALIDADE
            ,PCMOVPREFAT.QTCONT AS QT_LOTE
            ,NVL(PCMOVCOMPLEPREFAT.PRECOMAXCONSUM,
             DECODE(NVL(PCTABPR.PRECOMAXCONSUM,
                        0),
                    0,
                    NVL(PCPRODUT.PRECOMAXCONSUM,
                        0),
                    NVL(PCTABPR.PRECOMAXCONSUM,
                        0))) PRECO_MAXIMO
            ,NVL(LTRIM(TRANSLATE(NVL(PCMOVCOMPLEPREFAT.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), NVL(TRANSLATE(NVL(PCMOVCOMPLEPREFAT.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), '1234567890', ' '),'X'), ' ')),
                    DECODE(NVL(PCMOVPREFAT.IMPORTADO, 'N'),
                        'S',
                            2,
                        'D',
                            1,
                            0
             )) AS  ORIGEM_MERCADORIA
            ,NVL(PCMOVPREFAT.SITTRIBUT,
                 55) AS SITUACAO_TRIBUTARIA
            ,'3' AS MODALIDADE_BC_ICMS

           , CASE WHEN (PCMOVPREFAT.CODOPER ='SD'  AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                        PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                        0
                   ELSE
                        DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOVPREFAT.VLDESCRODAPE, 0),
                                                   ROUND(PCMOVPREFAT.QTCONT * (NVL(PCMOVPREFAT.BASEICMS, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEFRETE,0) + NVL(PCMOVCOMPLEPREFAT.VLBASEOUTROS,0)),2))
                   END
              AS BASE_ICMS
            ,CASE WHEN
               (PCMOVPREFAT.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S')
              THEN
               0
               ELSE
               NVL(NVL(PCMOVPREFAT.PERCICM2,
                       NVL(PCMOVPREFAT.PERCICMCP,
                           PCMOVPREFAT.PERCICM)),
                   0)END
            AS ALIQUOTA_ICMS
          , CASE WHEN PCMOVCOMPLEPREFAT.SOMARVALORDIFBCICMS = 'S' THEN 0 ELSE
              CASE WHEN (PCMOVPREFAT.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                      PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                    0
               ELSE
                    (ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOVPREFAT.VLDESCRODAPE, 0), 0) +
                              NVL(PCMOVPREFAT.BASEICMS, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEFRETE, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEOUTROS, 0))
                              * PCMOVPREFAT.QTCONT , 2) * (NVL(NVL(PCMOVPREFAT.PERCICMCP, PCMOVPREFAT.PERCICM), 0) / 100), 2))
                     -
                    (ROUND(ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOVPREFAT.VLDESCRODAPE, 0), 0) +
                              NVL(PCMOVPREFAT.BASEICMS, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEFRETE, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEOUTROS, 0))
                              * PCMOVPREFAT.QTCONT, 2) * (NVL(NVL(PCMOVPREFAT.PERCICMCP, PCMOVPREFAT.PERCICM), 0) / 100), 2) *
                            (NVL(PCMOVCOMPLEPREFAT.PERDIFEREIMENTOICMS,NVL(PCMOVPREFAT.PERCDESCICMSDIF,0))/100), 2))

                END
            END AS VALOR_ICMS
          ,CASE WHEN (PCMOVPREFAT.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                      PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                 0
           ELSE
                (ROUND(ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOVPREFAT.VLDESCRODAPE, 0), 0) +
                          NVL(PCMOVPREFAT.BASEICMS, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEFRETE, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEOUTROS, 0))
                         * PCMOVPREFAT.QTCONT, 2) * (NVL(NVL(PCMOVPREFAT.PERCICMCP, PCMOVPREFAT.PERCICM), 0) / 100), 2), 2))
           END AS VALOR_ICMS_OPERACAO
            ,ROUND(NVL(PCMOVCOMPLEPREFAT.PERCICMSSIMPLESNAC,0),2) ALIQUOTA_CREDITO_SN
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLRICMSSIMPLESNAC,0),2) VALOR_CREDITO_ICMS_SN
            ,ROUND(NVL(PCMOVPREFAT.VLADUANEIRA,
                       0) * PCMOVPREFAT.QTCONT,
                   2) BASE_II
            ,ROUND(NVL(PCMOVPREFAT.VLADUANEIRA,
                       0) * PCMOVPREFAT.QTCONT,
                   2) VALOR_DESPESA_ADUANEIRA
            ,ROUND(NVL(PCMOVPREFAT.VLIMPORTACAO,
                       0) * PCMOVPREFAT.QTCONT,
                   2) VALOR_II
            ,0 AS VALOR_IOF
            ,NVL(PCMOVCOMPLEPREFAT.CODSITTRIBIPI,DECODE(NVL(DECODE(NVL(PCMOVPREFAT.CALCCREDIPI,
                                   'N'),
                               'S',
                               'S',
                               DECODE(NVL(PCCONSUM.USATRIBUTACAOPORUF,
                                          'N'),
                                      'N',
                                      NVL(PCMOVPREFAT.CALCCREDIPI,
                                          'N'),
                                      (SELECT NVL(PCTABTRIBENT.CALCCREDIPI,
                                                  'N')
                                       FROM   PCTABTRIBENT
                                       WHERE  PCTABTRIBENT.CODPROD =
                                              PCMOVPREFAT.CODPROD
                                       AND    PCTABTRIBENT.UFORIGEM =
                                              'ES'
                                       AND    PCTABTRIBENT.UFDESTINO =
                                              'EX'
                                       AND    ROWNUM = 1))),
                        'N'),
                    'S',
                    50,
                    NVL((SELECT CODSITTRIBIPISAID FROM PCFIGURATRIBIPI F WHERE F.CODFIGURAIPI IN (SELECT CODFIGURAIPI FROM PCTRIBIPI WHERE CODPROD = PCMOVPREFAT.CODPROD AND ROWNUM = 1) AND ROWNUM = 1), 99))) SITUACAO_TRIBUTARIA_IPI
            ,ROUND(DECODE(PCMOVPREFAT.CODOPER,
                          'SD',
                          (DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                                    PCFILIAL.CODIGO),
                                      'N'),
                                  'N',
                                  NVL(PCMOVPREFAT.VLBASEIPI,
                                      0),
                                  'S',
                                  DECODE(NVL(PCMOVPREFAT.CALCCREDIPI,
                                             'S'),
                                         'S',
                                         NVL(PCMOVPREFAT.VLBASEIPI,
                                             0),
                                         'N',
                                         DECODE(NVL(PCMOVPREFAT.IMPORTADO,
                                                    'N'),
                                                'D',
                                                NVL(PCMOVPREFAT.VLBASEIPI,
                                                    0),
                                                0))) +
                          DECODE(ORGAO_PUBLICO,
                                  'S',
                                  NVL(PCMOVPREFAT.VLDESCRODAPE,
                                      0),
                                  0)),
                          NVL(PCMOVPREFAT.VLBASEIPI,
                              0)) * PCMOVPREFAT.QTCONT,
                   2) AS BASE_IPI
            ,ROUND((DECODE(ORGAO_PUBLICO,
                           'S',
                           NVL(PCMOVPREFAT.VLDESCRODAPE,
                               0),
                           0) + DECODE(PCMOVPREFAT.CODOPER,
                                        'SD',
                                        DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                                                 PCFILIAL.CODIGO),
                                                   'N'),
                                               'N',
                                               NVL(PCMOVPREFAT.VLIPI,
                                                   0),
                                               'S', 0,
                                               DECODE(NVL(PCMOVPREFAT.CALCCREDIPI,
                                                          'S'),
                                                      'S',
                                                      NVL(PCMOVPREFAT.VLIPI,
                                                          0),
                                                      'N',
                                                      DECODE(NVL(PCMOVPREFAT.IMPORTADO,
                                                                 'N'),
                                                             'D',
                                                             NVL(PCMOVPREFAT.VLIPI,
                                                                 0),
                                                             0))),
                                        NVL(PCMOVPREFAT.VLIPI,
                                            0))) * PCMOVPREFAT.QTCONT,
                   2) AS VALOR_IPI
            ,
            CASE WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                  NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',PCFILIAL.CODIGO),'N') = 'S') THEN
                  0
            ELSE
                  ROUND(NVL(NVL(PCMOVPREFAT.VLIPI,
                           0) * PCMOVPREFAT.QTCONT,
                       0),
                   2) END AS VALOR_IPI_CALCULO
            ,DECODE(PCMOVPREFAT.CODOPER,
                    'SD',
                    DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                             PCFILIAL.CODIGO),
                               'N'),
                           'N',
                           NVL(PCMOVPREFAT.VLIPI,
                               0),
                           'S',
                           DECODE(NVL(PCMOVPREFAT.CALCCREDIPI,
                                      'S'),
                                  'S',
                                  NVL(PCMOVPREFAT.VLIPI,
                                      0),
                                  'N',
                                  DECODE(NVL(PCMOVPREFAT.IMPORTADO,
                                             'N'),
                                         'D',
                                         NVL(PCMOVPREFAT.VLIPI,
                                             0),
                                         0))),
                    NVL(PCMOVPREFAT.VLIPI,
                        0)) AS VALOR_IPI_UNIDADE
            ,DECODE(PCMOVPREFAT.CODOPER,
                    'SD',
                    DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE',
                                                             PCFILIAL.CODIGO),
                               'N'),
                           'N',
                           NVL(PCMOVPREFAT.PERCIPI,
                               0),
                           'S',
                           DECODE(NVL(PCMOVPREFAT.CALCCREDIPI,
                                      'S'),
                                  'S',
                                  NVL(PCMOVPREFAT.PERCIPI,
                                      0),
                                  'N',
                                  DECODE(NVL(PCMOVPREFAT.IMPORTADO,
                                             'N'),
                                         'D',
                                         NVL(PCMOVPREFAT.PERCIPI,
                                             0),
                                         0))),
                    NVL(PCMOVPREFAT.PERCIPI,
                        0)) AS ALIQUOTA_IPI
            ,NVL(100 - PCMOVPREFAT.PERCBASERED,
                 0) AS PERCENTUAL_REDUCAO_BC
            ,CASE
               WHEN ((NVL(PCCONSUM.UTILIZACONTROLELOTE, 'N') = 'S') OR
                    (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZACONTROLEMEDICAMENTOS',
                                                        '99'),
                          'N') = 'S')) THEN
                DECODE(NVL(PCMOVCOMPLEPREFAT.USAPMCBASEST, 'N'),
                       'S',
                       0,
                       DECODE(NVL(PCMOVPREFAT.TIPOTRIBUTMEDIC, 'OM'),
                              'PO',
                              2,
                              'NG',
                              1,
                              'NT',
                              3,
                              CASE WHEN (ROUND(NVL(PCMOVPREFAT.PAUTA, 0) * (DECODE(NVL(PCMOVPREFAT.PERCBASEREDST,0), 0, 1, PCMOVPREFAT.PERCBASEREDST/100)), 6) = PCMOVPREFAT.BASEICST) THEN
                                   5
                                ELSE
                                   4
                                END))
               ELSE
                CASE WHEN (NVL(PCMOVPREFAT.PAUTA, 0) > 0) AND (ROUND(NVL(PCMOVPREFAT.PAUTA, 0) * (DECODE(NVL(PCMOVPREFAT.PERCBASEREDST,0), 0, 1, PCMOVPREFAT.PERCBASEREDST/100)), 6) = PCMOVPREFAT.BASEICST) THEN
                                   5
                                ELSE
                                   4
                                END
               END MODALIDADE_BC_ST
            ,ROUND(NVL(PCMOVPREFAT.PERCIVA, NVL(PCMOVPREFAT.IVA, 0)), 2) AS PERCENTUAL_MARGEM
            ,ROUND(CASE WHEN GREATEST(NVL(PCMOVPREFAT.PERCBASEREDST,0), NVL(PCMOVPREFAT.PERCBASEREDSTFONTE,0)) > 0 THEN
                         100 - GREATEST(NVL(PCMOVPREFAT.PERCBASEREDST,0), NVL(PCMOVPREFAT.PERCBASEREDSTFONTE,0))
                      ELSE
                         0
                   END, 4) AS PERCENTUAL_REDUCAO_ST
            ,ROUND(NVL(DECODE(PCMOVPREFAT.CODOPER,
                              'SD',
                              DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',
                                                                       PCFILIAL.CODIGO),
                                         'S'),
                                     'S',
                                     (DECODE(ORGAO_PUBLICO,
                                             'S',
                                             NVL(PCMOVPREFAT.VLDESCRODAPE,
                                                 0),
                                             0) + NVL(PCMOVPREFAT.BASEICST,
                                                       0)),
                                     0),
                              DECODE(ORGAO_PUBLICO,
                                     'S',
                                     NVL(PCMOVPREFAT.VLDESCRODAPE,
                                         0),
                                     0) + NVL(PCMOVPREFAT.BASEICST,
                                              0)) * PCMOVPREFAT.QTCONT,
                       0),
                   2) AS BASE_ST
            ,ROUND(NVL(DECODE(PCMOVPREFAT.CODOPER,
                              'SD',
                              DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',
                                                                       PCFILIAL.CODIGO),
                                         'S'),
                                     'S',
                                     (DECODE(ORGAO_PUBLICO,
                                             'S',
                                             NVL(PCMOVPREFAT.VLDESCRODAPE,
                                                 0),
                                             0) + NVL(PCMOVPREFAT.ST,
                                                       0)),
                                     0),
                              DECODE(ORGAO_PUBLICO,
                                     'S',
                                     NVL(PCMOVPREFAT.VLDESCRODAPE,
                                         0),
                                     0) + NVL(PCMOVPREFAT.ST,
                                              0)) * PCMOVPREFAT.QTCONT,
                       0),
                   2) AS VALOR_ST
            ,ROUND((PCMOVPREFAT.PUNITCONT * PCMOVPREFAT.QTCONT),2) AS VALOR_TOT_EMBALAGEM
            ,ROUND((PCMOVPREFAT.PUNITCONT  * QTUNITEMB),2)  AS VALOR_UN_EMBALAGEM
            ,CASE WHEN (PCMOVPREFAT.CODOPER = 'SD' AND
                  NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSSTIMPRESSAODANFE',PCFILIAL.CODIGO),'S') = 'N') THEN
                 0
             ELSE
                 ROUND(NVL(NVL(PCMOVPREFAT.ST,
                           0) * PCMOVPREFAT.QTCONT,
                       0),
                   2) END AS VALOR_ST_CALCULO
            ,NVL(PCMOVPREFAT.ALIQICMS1,
                 0) AS ALIQUOTA_ST
            ,NVL(PCMOVPREFAT.PISCOFINSRETIDO,
                 'I') AS RETIDO
            ,CASE WHEN NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLEPREFAT.USAPISCOFINSLIT,'N') = 'S'  THEN
                NVL(PCMOVPREFAT.VLCOFINS,0)
             else
                NVL(PCMOVPREFAT.PERCOFINS, 0)
             end ALIQUOTA_COFINS
            ,CASE WHEN NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLEPREFAT.USAPISCOFINSLIT,'N') = 'S'THEN
                NVL(PCMOVPREFAT.VLPIS,0)
             else
                NVL(PCMOVPREFAT.PERPIS, 0)
             end ALIQUOTA_PIS
            ,NVL(PCMOVPREFAT.CODSITTRIBPISCOFINS,99) AS SIT_PIS_CONFINS
            ,CASE WHEN NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                  AND NVL(PCMOVCOMPLEPREFAT.USAPISCOFINSLIT, 'N') = 'S' THEN
               NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) * PCMOVPREFAT.QTCONT
            ELSE
               NVL(PCMOVPREFAT.VLBASEPISCOFINS, 0) * PCMOVPREFAT.QTCONT
            END VL_BASE_PIS
           ,CASE  WHEN NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLEPREFAT.USAPISCOFINSLIT, 'N') = 'S' THEN
               ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) * NVL(PCMOVPREFAT.VLCOFINS,0), 2)
            ELSE
               ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.VLCOFINS,0), 2)
            END VALOR_COFINS
           ,CASE WHEN NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                  AND NVL(PCMOVCOMPLEPREFAT.USAPISCOFINSLIT, 'N') = 'S' THEN
               NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) * PCMOVPREFAT.QTCONT
            ELSE
               NVL(PCMOVPREFAT.VLBASEPISCOFINS, 0) * PCMOVPREFAT.QTCONT
            END VL_BASE_CONFINS
           ,CASE  WHEN NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) > 0
                   AND NVL(PCMOVCOMPLEPREFAT.USAPISCOFINSLIT, 'N') = 'S' THEN
               ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.QTLITRAGEM, PCPRODUT.LITRAGEM) * NVL(PCMOVPREFAT.VLPIS,0), 2)
            ELSE
               ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.VLPIS,0), 2)
            END VALOR_PIS
            --
            ,PCMOVPREFAT.CLASSIFICFISCAL
            ,PCPRODUT.CODFAB AS CODIGO_FABRICANTE
            ,PCMOVPREFAT.CODFORNEC AS CODIGO_FORNECEDOR
            ,DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),'N',
               NVL(PCMOVPREFAT.EMBALAGEM, PCEMBALAGEM.EMBALAGEM),
               NVL(PCEMBALAGEM.EMBALAGEM,PCMOVPREFAT.EMBALAGEM)) AS EMBALAGEM
            ,PCPRODUT.EMBALAGEMMASTER
            ,PCFORNEC.FANTASIA
            ,PCFORNEC.FORNECEDOR
            ,PCPRODUT.PESOEMBALAGEM
            ,PCPRODUT.FATORUNFARM
            ,PCPRODUT.NUMORIGINAL
            ,PCMARCA.MARCA
            ,(SELECT PCPRINCIPATIVO.DESCRICAO
              FROM   PCPRINCIPATIVO
              WHERE  PCPRINCIPATIVO.CODPRINCIPATIVO =
                     PCPRODUT.CODPRINCIPATIVO) AS PRINCIPIOATIVO
            ,NVL(PCMOVPREFAT.PERCDESC, 0) PERCDESC
            ,NVL(DECODE(NVL(PCMOVPREFAT.PESOBRUTO,
                            0),
                        0,
                        (SELECT PCPEDI.PESOBRUTO
                         FROM   PCPEDI
                         WHERE  PCPEDI.NUMPED = PCMOVPREFAT.NUMPED
                         AND    PCPEDI.CODPROD = PCMOVPREFAT.CODPROD
                         AND    PCPEDI.NUMSEQ = PCMOVPREFAT.NUMSEQ
                         AND    ROWNUM = 1),
                        PCMOVPREFAT.PESOBRUTO),
                 0) PESOCX
            -----TAREFA: 195705-----
            ,CASE
                 WHEN NVL(PCMOVPREFAT.QTCX, 0) > 0 OR NVL(PCMOVPREFAT.QTPECAS, 0) > 0 THEN
                         PCMOVPREFAT.QTCX
                      ELSE
                         CASE WHEN NVL(PCPRODUT.TIPOESTOQUE, 'PA') = 'PA' THEN
                           NULL
                         ELSE
                           PCMOVPREFAT.QTCONT
                         END
                 END QTCX
            ,NVL(PCMOVPREFAT.QTPECAS, 0) QTPECAS
            ------------------------
            ,NVL(PCMOVCOMPLEPREFAT.QTUN,
                 0) QTUN
            ,NVL(PCMOVPREFAT.PTABELA,
                 0) PTABELA
            ,PCMOVPREFAT.PUNITCONT
            ,TRUNC(PCMOVPREFAT.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                             1),
                                         0,
                                         1,
                                         NVL(PCPRODUT.PESOBRUTOMASTER,
                                             1))) AS QTD_CAIXAS_MASTER
            ,CASE
               WHEN TRUNC(PCMOVPREFAT.QTCONT / DECODE(NVL(PCPRODUT.PESOBRUTOMASTER,
                                                    1),
                                                0,
                                                1,
                                                NVL(PCPRODUT.PESOBRUTOMASTER,
                                                    1))) > 0 THEN
                (PCMOVPREFAT.QTCONT - (TRUNC(PCMOVPREFAT.QTCONT / CASE
               WHEN NVL(PCPRODUT.PESOBRUTOMASTER,
                        1) > 0 THEN
                NVL(PCPRODUT.PESOBRUTOMASTER,
                    1)
               ELSE
                1
             END) * NVL(PCPRODUT.PESOBRUTOMASTER, 1))) ELSE PCMOVPREFAT.QTCONT / DECODE(NVL(PCPRODUT.PESOPECA, 1), 0, 1, NVL(PCPRODUT.PESOPECA, 1)) END AS QTD_PECAS_INTERM
            ,NVL(PCMOVPREFAT.QTUNITCX,
                 0) QTUNITCX
            ,CASE
               WHEN NVL(PCMOVPREFAT.QTCX,
                        0) > 0 THEN
                NVL(PCMOVPREFAT.QTCX,
                    0)
               WHEN NVL(PCMOVPREFAT.QTPECAS,
                        0) > 0 THEN
                NVL(PCMOVPREFAT.QTPECAS,
                    0)
               ELSE
                NVL(PCMOVPREFAT.QTCONT,
                    0)
             END AS QUANTIDADE_ENTREGA
            ,CASE
               WHEN NVL(PCMOVPREFAT.QTCX,
                        0) > 0 THEN
                'CX'
               WHEN NVL(PCMOVPREFAT.QTPECAS,
                        0) > 0 THEN
                'PC'
               ELSE
                'UN'
             END AS TIPO_QUANTIDADE
            ,ROUND(NVL(PCMOVPREFAT.STCLIENTEGNRE, 0) * NVL(PCMOVPREFAT.QTCONT, 0), 2) STCLIENTEGNRE
            ,NVL(PCPRODUT.TIPOESTOQUE, 'PA') AS TIPOESTOQUE
            ,NVL(PCMOVPREFAT.TIPOTRIBUTMEDIC, 'X') TIPOTRIBUTMEDIC
            ,DECODE(PCPEDC.TIPOEMBALAGEM,
                    'C',
                    (PCMOVPREFAT.QTCONT / DECODE(NVL(PCMOVPREFAT.QTUNITCX,
                                               0),
                                           0,
                                           1,
                                           NVL(PCMOVPREFAT.QTUNITCX,
                                               0))),
                    PCMOVPREFAT.QTCONT) * PCMOVPREFAT.PESOLIQ TOTPESOLIQUNIT
            ,PCPRODUT.UNIDADEMASTER
            ,ROUND(NVL(PCMOVPREFAT.VLBASEGNRE, 0) * NVL(PCMOVPREFAT.QTCONT, 0), 2) VLBASEGNRE
            ,PCMOVPREFAT.NUMVOLUMESCONFERENCIA
            ,PCMOVPREFAT.PERACRESCIMOCUSTO
            ,PCMOVPREFAT.TIPOSEPARACAO
            ,PCMOVPREFAT.QTUNITEMB
            ,CASE WHEN (PCMOVPREFAT.CODOPER IN ('SD','SR')) THEN
                  PCMOVPREFAT.UNIDADE
             ELSE
                  PCEMBALAGEM.UNIDADE
             END AS UNIDADE_EMBALAGEM -- TAREFA: 133424
            --,DECODE(PCMOVPREFAT.CODOPER, 'SD', PCMOVPREFAT.UNIDADE, PCEMBALAGEM.UNIDADE) AS UNIDADE_EMBALAGEM
            ,CASE WHEN (PCMOVPREFAT.CODOPER IN ('SD,SR')) THEN
                  PCMOVPREFAT.QTCONT
             ELSE
             PCMOVPREFAT.QTCONT / DECODE(NVL(PCMOVPREFAT.QTEMBALAGEM,
                                        0),
                                    0,
                                    DECODE(NVL(PCEMBALAGEM.QTUNIT,
                                               1),
                                           0,
                                           1,
                                           PCEMBALAGEM.QTUNIT),
                                    PCMOVPREFAT.QTEMBALAGEM) END AS QTD_EMBALAGEM --TAREFA: 133424 E 138681
            ,PCMOVPREFAT.CODSEC AS CODIGO_SECAO
            ,PCMOVPREFAT.CODEPTO AS CODIGO_DEPARTAMENTO
            ,PCSECAO.DESCRICAO AS DESCRICAO_SECAO
            ,PCDEPTO.DESCRICAO AS DESCRICAO_DEPARTAMENTO
            ,DECODE(NVL(PCNFSAIDPREFAT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOVPREFAT.BASEBCR, 0) * PCMOVPREFAT.QTCONT),0) AS BASEBCR
            ,DECODE(NVL(PCNFSAIDPREFAT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOVPREFAT.STBCR, 0) * PCMOVPREFAT.QTCONT),0) AS STBCR
            ,NVL(PCMOVPREFAT.VOLUME, 0) AS VOLUME
            ,CASE
               WHEN ((NVL(PCMOVPREFAT.QTUNITCX,
                          NVL(PCMOVPREFAT.QTUNITCX,
                              1)) > 0) AND
                    (PCMOVPREFAT.QTCONT >= NVL(PCMOVPREFAT.QTUNITCX,
                                      NVL(PCMOVPREFAT.QTUNITCX,
                                          1)))) THEN
                TRUNC(PCMOVPREFAT.QTCONT / NVL(PCMOVPREFAT.QTUNITCX,
                                     NVL(PCMOVPREFAT.QTUNITCX,
                                         1)))
               ELSE
                0
             END QTD_CAIXA
            ,CASE
               WHEN ((NVL(PCMOVPREFAT.QTUNITCX,
                          NVL(PCMOVPREFAT.QTUNITCX,
                              1)) > 0) AND
                    (PCMOVPREFAT.QTCONT >= NVL(PCMOVPREFAT.QTUNITCX,
                                      NVL(PCMOVPREFAT.QTUNITCX,
                                          1)))) THEN
                PCMOVPREFAT.QTCONT - (TRUNC(PCMOVPREFAT.QTCONT / NVL(PCMOVPREFAT.QTUNITCX,
                                                 NVL(PCMOVPREFAT.QTUNITCX,
                                                     1))) *
                NVL(PCMOVPREFAT.QTUNITCX,
                                NVL(PCMOVPREFAT.QTUNITCX,
                                    1)))
               ELSE
                PCMOVPREFAT.QTCONT
             END QTD_UNIDADE
            ,PCMOVCOMPLEPREFAT.UNIDADELICIT AS UNIDADE_LICIT
            ,PCMOVCOMPLEPREFAT.QTUNITLICIT AS QT_UNIT_LICIT
            ,DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARNUMPEDGRUPOCOMPRA', PCFILIAL.CODIGO), 'N'),'S',
             NVL(PCMOVCOMPLEPREFAT.NUMPEDCLI, NVL(PCNFSAIDPREFAT.NUMPEDCLI, NVL(PCMOVPREFAT.NUMPED, 0))),
             NVL(PCNFSAIDPREFAT.NUMPEDVANXML, NVL( PCMOVPREFAT.NUMPED, 0))) AS NUMERO_PEDIDO
            ,NVL(PCMOVCOMPLEPREFAT.NUMITEMPED,NVL(PCMOVCOMPLEPREFAT.IDVENDA, NVL(PCMOVPREFAT.NUMSEQ, 1))) AS NUMERO_ITEM_PEDIDO
            ,PCMOVPREFAT.NUMSEQ
            ,NVL(PCMOVPREFAT.QTUNIT, 0) AS QTUNIT
            ,ROUND((DECODE(PCMOVPREFAT.CODOPER, 'SD',
                           NVL(PCMOVPREFAT.VLDESPDENTRONF,0) -
                           DECODE(NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC, 0),
                                  0,
                                  0,
                                  NVL(PCMOVCOMPLEPREFAT.VLIPIOUTRAS, 0)),
                           NVL(PCMOVPREFAT.VLOUTROS,0) - NVL(PCMOVPREFAT.VLSEGURO,0))) * QTCONT,2) AS VALOR_OUTROS
            --dados veiculos
            ,PCPEDIDADOSVEICULOS.TPOPERACAO AS TPOPERACAO
            ,PCPEDIDADOSVEICULOS.CHASSI AS CHASSIVEICULO
            ,PCPEDIDADOSVEICULOS.CODCOR AS CORVEICULO
            ,PCPEDIDADOSVEICULOS.DESCCOR AS DESCCORVEICULO
            ,PCPEDIDADOSVEICULOS.POTMOTOR AS POTVEICULO
            ,PCPEDIDADOSVEICULOS.CILINDRADAS AS  CILINVEICULO
            ,PCPEDIDADOSVEICULOS.PESOLIQUIDO AS  PESOLVEICULO
            ,PCPEDIDADOSVEICULOS.PESOBRUTO AS PESOBVEICULO
            ,PCPEDIDADOSVEICULOS.SERIE AS SERIALVEICULO
            ,PCPEDIDADOSVEICULOS.TPCOMBUSTIVEL AS TPCOMBVEICULO
            ,PCPEDIDADOSVEICULOS.NUMMOTOR AS NMOTORVEICULO
            ,PCPEDIDADOSVEICULOS.CMT AS CMTVEICULO
            ,PCPEDIDADOSVEICULOS.DISTANCIAEIXO AS DISTEIXOVEICULO
            ,PCPEDIDADOSVEICULOS.ANOMOD AS ANOMODVEICULO
            ,PCPEDIDADOSVEICULOS.ANOFAB AS ANOFABVEICULO
            ,PCPEDIDADOSVEICULOS.TPPINTURA AS TPPINTVEICULO
            ,PCPEDIDADOSVEICULOS.TPVEICULO AS TPVEICVEICULO
            ,PCPEDIDADOSVEICULOS.ESPECIEVEICULO AS ESPVEICVEICULO
            ,PCPEDIDADOSVEICULOS.VIN AS CONDVINVEICULO
            ,PCPEDIDADOSVEICULOS.CONDVEICULO AS CONDVEICVEICULO
            ,PCPEDIDADOSVEICULOS.CODMODELO AS MARCMODVEICULO
            ,PCPEDIDADOSVEICULOS.CODCORDENATRAM AS CORDENATRANVEICULO
            ,PCPEDIDADOSVEICULOS.LOTACAO AS LOTACAOVEICULO
            ,PCPEDIDADOSVEICULOS.TPRESTRICAO AS TPRESTVEICULO
            --fim dados veiculos
            ,PCMOVCOMPLEPREFAT.PRECOMAXCONSUM AS PRECO_MAX_CONSUMIDOR
            ,CASE WHEN ((NVL(PCMOVPREFAT.PUNITCONT,0) - NVL(PCMOVPREFAT.VLREPASSE,0)) > NVL(PCMOVCOMPLEPREFAT.PORIGINAL,0)) THEN
                  --Quando o campo PCNFSAID.SOMAREPASSEOUTRASDESPNF = S a package de faturamento já subtraiu o VLREPASSE do PUNITCONT
                  NVL(PCMOVPREFAT.PUNITCONT,0) - DECODE(NVL(PCNFSAIDPREFAT.SOMAREPASSEOUTRASDESPNF, 'N'), 'S', 0, NVL(PCMOVPREFAT.VLREPASSE,0))
             ELSE PCMOVCOMPLEPREFAT.PORIGINAL END AS PRECO_FABRICA
            ,PCMOVCOMPLEPREFAT.DESCPRECOFAB AS DESCONTO_FABRICA
            ,PCMOVCOMPLEPREFAT.CODPRODACABCESTA AS CODPRODCABCESTA
            ,PCMOVPREFAT.PERBONIFIC AS PERCBONIFIC
            --Dados abatimento
            ,GREATEST((NVL(PCMOVPREFAT.VLDESCONTO, 0 ) - NVL(PCMOVCOMPLEPREFAT.VLDESCABATIMENTO,0)) * PCMOVPREFAT.QTCONT, 0) AS VLDESCSEMABATIMENTO
            ,(NVL(PCMOVCOMPLEPREFAT.VLDESCABATIMENTO ,0) * PCMOVPREFAT.QTCONT) AS VLABATIMENTO
            --Dados abatimento - Fim
            ,PCPRODUT.ANP AS CODIGOANP
            ,CASE WHEN (NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N') = 'S') THEN
                  DECODE(NVL(PCCLIENT.CONSUMIDORFINAL,'N'), 'S', ROUND((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOS,0) + NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSEST,0) + NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSMUNIC,0)) * QTCONT,2), 0)
             ELSE
                  ROUND((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOS,0) + NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSEST,0) + NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSMUNIC,0)) * QTCONT,2) END AS VLTOTALIMPOSTOS
            ,DECODE(NVL(PCMOVCOMPLEPREFAT.ORIGMERCTRIB,PCPRODFILIAL.ORIGMERCTRIB), '3', PCMOVCOMPLEPREFAT.NUMFCI, '5', PCMOVCOMPLEPREFAT.NUMFCI, '8', PCMOVCOMPLEPREFAT.NUMFCI, '') AS NUMERO_FCI
            ,NVL(PCMOVPREFAT.PERDESCISENTOICMS,0) ALIQ_INSENCAO_ICMS
            ,ROUND((PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.VLDESCICMISENCAO,0)),2) VALOR_ISENCAO_ICMS
            ,PCEMBALAGEM.CODAUXILIAR AS COD_AUXILIAR_EMBALAGEM
            ,NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOS,0) VLTOTALIMPOSTOSFEDERAL
            ,NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSEST,0) VLTOTALIMPOSTOSESTADUAL
            ,NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSMUNIC,0) VLTOTALIMPOSTOSMUNICIPAL
            ,(ROUND(ROUND(ROUND((DECODE(ORGAO_PUBLICO, 'S', NVL(PCMOVPREFAT.VLDESCRODAPE, 0), 0) +
                          NVL(PCMOVPREFAT.BASEICMS, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEFRETE, 0) + NVL(PCMOVCOMPLEPREFAT.VLBASEOUTROS, 0))
                          * PCMOVPREFAT.QTCONT, 2) * (NVL(NVL(PCMOVPREFAT.PERCICMCP, PCMOVPREFAT.PERCICM), 0) / 100), 2) *
                        (NVL(PCMOVCOMPLEPREFAT.PERDIFEREIMENTOICMS,NVL(PCMOVPREFAT.PERCDESCICMSDIF,0))/100), 2))
             AS VALORICMSDIF
            ,NVL(PCMOVCOMPLEPREFAT.PERDIFEREIMENTOICMS,NVL(PCMOVPREFAT.PERCDESCICMSDIF,0)) AS ALIQUOTAICMSDIF
            ,CASE WHEN (PCMOVPREFAT.CODOPER = 'SD') THEN
              CASE WHEN (PCMOVCOMPLEPREFAT.CODMOTIVOICMSDESONERADO = '7') THEN
                0
               WHEN (NVL(PCMOVPREFAT.VLDESCICMISENCAO,0) > 0) THEN
                ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.VLDESCICMISENCAO, 0), 2)
               WHEN (NVL(PCMOVCOMPLEPREFAT.VLICMSDESONERACAO,0) > 0) THEN
                  ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLICMSDESONERACAO, 0), 2)
              ELSE
               0
              END
            ELSE
              ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLICMSDESONERACAO, 0), 2)
            END VLICMSDESONERACAO
            ,CASE WHEN (PCMOVPREFAT.CODOPER = 'SD') THEN
              CASE WHEN (PCMOVCOMPLEPREFAT.CODMOTIVOICMSDESONERADO = '7') THEN
                0
               WHEN (NVL(PCMOVPREFAT.VLDESCICMISENCAO,0) > 0) THEN
                ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVPREFAT.VLDESCICMISENCAO, 0), NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2))
               WHEN (NVL(PCMOVCOMPLEPREFAT.VICMSSTDESON,0) > 0) THEN
                  ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VICMSSTDESON, 0), NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2))
              ELSE
               0
              END
            ELSE
              ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VICMSSTDESON, 0), NVL(PARAMFILIAL.OBTERCOMONUMBER('QTDCASASVLUNITARIONFE'), 2))
            END VICMSSTDESON
            ,CASE WHEN ((PCMOVPREFAT.CODOPER = 'SD') AND (PCMOVCOMPLEPREFAT.CODMOTIVOICMSDESONERADO = '7')) THEN '' ELSE PCMOVCOMPLEPREFAT.CODMOTIVOICMSDESONERADO END CODMOTIVOICMSDESONERADO
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLIPIDEVFORNEC, 0),2) AS VALOR_IPI_OUTROS
            ,NULL AS TIPO_PRESENCA_ADQUIRINTE
            ,DECODE(NVL((PARAMFILIAL.OBTERCOMOVARCHAR2('INFDADOSEXPORTPORITEM', 99)),'N'),
                   'S',
                   PCMOVCOMPLEPREFAT.NUMDRAWBACK,
                   PCNFSAIDPREFAT.NUMDRAWBACK
             ) NUMERO_DRAWBACK
            ,PCMOVCOMPLEPREFAT.CODCEST
            ,PCMOVCOMPLEPREFAT.CODENQIPI CODENQUADRAMENTOIPI
             ,DECODE(NVL((PARAMFILIAL.OBTERCOMOVARCHAR2('INFDADOSEXPORTPORITEM', 99)),'N'),
                   'S',
                   PCMOVCOMPLEPREFAT.NUMCHAVEEXP,
                   PCNFSAIDPREFAT.NUMCHAVEEXP
             ) NUMCHAVEEXP
             ,DECODE(NVL((PARAMFILIAL.OBTERCOMOVARCHAR2('INFDADOSEXPORTPORITEM', 99)),'N'),
                   'S',
                   PCMOVCOMPLEPREFAT.NUMREGEXP,
                   PCNFSAIDPREFAT.NUMREGEXP
             ) NUMREGEXP
            ,NVL(PCMOVCOMPLEPREFAT.ALIQFCP, 0) AS ALIQFCPPART
            ,NVL(PCMOVCOMPLEPREFAT.ALIQINTERNADEST, 0) AS ALIQINTERNADEST
            ,NVL(PCMOVCOMPLEPREFAT.ALIQINTERORIGPART, 0) AS ALIQINTERORIGPART
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLFCPPART, 0),2) AS VLFCPPART
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBASEPARTDEST, 0),2) AS VLBASEPARTDEST
            ,NVL(PCMOVCOMPLEPREFAT.PERCPROVPART,0) AS PERCPROVPART
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLICMSDIFALIQPART, 0),2) AS VLICMSDIFALIQPART
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLICMSPARTDEST, 0),2) AS VLICMSPARTDEST
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLICMSPARTREM, 0),2) AS VLICMSPARTREM
            ,PCFILIAL.CODIGO AS CODFILIAL
            ,0 AS VIASTRANSP
            ,0 AS VLAFRMM
            ,NVL(PCPRODUT.REGISTROMSMED, PCPRODUT.ANVISA) AS PROD_ANVISA
            ,NVL(PCPRODUT.ESTOQUEPORLOTE, 'N') PROD_RASTREADO
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBASEFCPICMS, 0),2) VLBASEFCPICMS
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBASEFCPST, 0),2) VLBASEFCPST
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBCFCPSTRET, 0),2) VLBCFCPSTRET
            ,NVL(PCMOVCOMPLEPREFAT.PERFCPSTRET, 0) PERFCPSTRET
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLFCPSTRET, 0),2) VLFCPSTRET
            ,NVL(PCMOVCOMPLEPREFAT.PERFCPSN, 0) PERFCPSN
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLCREDFCPICMSSN, 0),2) VLCREDFCPICMSSN
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLFECP, 0),2) VLFECP
            ,CASE WHEN (PCMOVCOMPLEPREFAT.SOMARVALORDIFBCICMS = 'S') THEN 0 ELSE ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLACRESCIMOFUNCEP, 0),2) END AS VLACRESCIMOFUNCEP
            ,NVL(PCMOVCOMPLEPREFAT.PERACRESCIMOFUNCEP, 0) AS PERACRESCIMOFUNCEP
            ,NVL(PCMOVCOMPLEPREFAT.ALIQICMSFECP, 0) AS ALIQICMSFECP
            ,CASE
               WHEN PCNFSAIDPREFAT.TIPOVENDA = 'DF' THEN
                PCMOVCOMPLEPREFAT.CODBENEFICIONOTA --Código de benefício que veio na nota de entrada
               ELSE
                PCMOVCOMPLEPREFAT.CODBENEFICIOFISCAL
             END AS COD_BENEFICIO_FISCAL
            ,NVL(PCMOVCOMPLEPREFAT.INDESCALARELEVANTE, PCPRODFILIAL.INDESCALARELEVANTE) AS IND_ESCALA_RELEVANTE
            ,PCMOVCOMPLEPREFAT.CODAGREGACAO AS COD_AGREGACAO
            ,PCMOVCOMPLEPREFAT.CNPJFABRICANTE AS CNPJ_FABRICANTE
            ,NVL(PCMOVCOMPLEPREFAT.DESCANP, PCPRODUT.DESCANP) AS DESC_ANP
            ,NVL((SELECT NVL(T.ISENTAICMSUFDEST,  'N')
                   FROM PCTRIBUTPARTILHA P
                        ,PCTRIBUT        T
                  WHERE P.CODSTPARTILHA = T.CODST
                    AND P.CODST = PCMOVPREFAT.CODST
                    AND P.UF = PCNFSAIDPREFAT.UF), 'N') AS ISENTO_ICMS_UF_DEST
            ,NVL(PCPRODUT.TIPOPROD, 0) AS MIUDEZA
            ,NVL(PCMOVCOMPLEPREFAT.PGLP, NVL(PCPRODUT.pGLP, 0)) AS PERCENTUAL_GLP
            ,NVL(PCMOVCOMPLEPREFAT.PGNN, NVL(PCPRODUT.PGNN, 0)) AS PERC_GAS_NATURAL_NACIONAL
            ,NVL(PCMOVCOMPLEPREFAT.PGNI, NVL(PCPRODUT.PGNI, 0)) AS PERC_GAS_NATURAL_IMPORTADO
            ,NVL(PCMOVCOMPLEPREFAT.VPART, NVL(PCPRODUT.VPART, 0)) AS VALOR_PARTIDA
            ,NVL((SELECT PRIORIDADE FROM PCPRIORIDADEPRODDANFE WHERE CODPRIORIDADE = PCPRODFILIAL.CODCADPRIORIDADE), 0) AS COD_PRIORIDADE_IMPRESSAO
            ,PCMOVPREFAT.NUMNOTA
            ,PCMOVPREFAT.DATACONSOLIDACAOPREFAT
            ,'S' PREFATURAMENTO
            ,NVL(PCMOVCOMPLEPREFAT.PERCREDBASEEFET, 0) AS PERCREDBASEEFET
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLBASEEFET, 0),2) VLBASEEFET
            ,NVL(PCMOVCOMPLEPREFAT.PERCICMSEFET, 0) AS PERCICMSEFET
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLICMSEFET, 0),2) VLICMSEFET
            ,NVL(PCMOVCOMPLEPREFAT.ALIQICMS1RET, 0) + NVL(PCMOVCOMPLEPREFAT.PERFCPSTRET, 0) AS PERCSTRET
            ,NVL(PCMOVCOMPLEPREFAT.CODMOTISENCAOANVISA, PCPRODUT.CODMOTISENCAOANVISA) AS MOTIVO_ISENCAO_ANVISA
            ,DECODE(NVL(PCNFSAIDPREFAT.GERARBCRNFE, 'N'), 'S', (NVL(PCMOVPREFAT.VLICMSBCR, 0) * PCMOVPREFAT.QTCONT),0) AS VLICMSBCR
             --PCEST TEMPORARIO
            ,DECODE(NVL(PCNFSAIDPREFAT.GERARBCRNFE, 'N'), 'S', (NVL(PCEST.BASEBCR, 0) * PCMOVPREFAT.QTCONT),0) AS BASEBCR_PCEST
            ,NVL(PCEST.ALIQICMS1, 0) + NVL(PCEST.PERFCPSTRET, 0) AS PERCSTRET_PCEST
            ,DECODE(NVL(PCNFSAIDPREFAT.GERARBCRNFE, 'N'), 'S', (NVL(PCEST.VLICMSBCR, 0) * PCMOVPREFAT.QTCONT),0) AS VLICMSBCR_PCEST
            ,DECODE(NVL(PCNFSAIDPREFAT.GERARBCRNFE, 'N'), 'S', (NVL(PCEST.STBCR, 0) * PCMOVPREFAT.QTCONT),0) AS STBCR_PCEST
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCEST.VLBCFCPSTRET, 0),2) VLBCFCPSTRET_PCEST
            ,NVL(PCEST.PERFCPSTRET, 0) PERFCPSTRET_PCEST
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCEST.VLFCPSTRET, 0),2) VLFCPSTRET_PCEST
            ,SQL_NFE_CABECALHO_SAIDA.SIGLA_UF_E
            ,SQL_NFE_CABECALHO_SAIDA.SIGLA_UF_D
            ,CASE WHEN NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOS,0) > 0 THEN
                   DECODE(NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N'),  'S',
                   DECODE(NVL(PCCLIENT.CONSUMIDORFINAL, 'N'), 'S', 'VL.APROX.TRIB. FEDERAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOS,0) * PCMOVPREFAT.QTCONT),'999999999999999990.99')), ''),
                   'VL.APROX.TRIB. FEDERAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOS,0) * PCMOVPREFAT.QTCONT),'999999999999999990.99')))
               ELSE '' END || ' ' ||
               CASE WHEN NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSEST,0) > 0 THEN
                   DECODE(NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N'),  'S',
                   DECODE(NVL(PCCLIENT.CONSUMIDORFINAL, 'N'), 'S', 'VL.APROX.TRIB. ESTADUAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSEST,0) * PCMOVPREFAT.QTCONT),'999999999999999990.99')), ''),
                   'VL.APROX.TRIB. ESTADUAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSEST,0) * PCMOVPREFAT.QTCONT),'999999999999999990.99')))
               ELSE '' END || ' ' ||
               CASE WHEN NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSMUNIC,0) > 0 THEN
                   DECODE(NVL(PARAMFILIAL.ObterComoVarchar2('PERMITEINFOLEITRANSPCONSFINAL', PCFILIAL.CODIGO), 'N'),  'S',
                   DECODE(NVL(PCCLIENT.CONSUMIDORFINAL, 'N'), 'S', 'VL.APROX.TRIB. MUNICIPAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSMUNIC,0) * PCMOVPREFAT.QTCONT),'999999999999999990.99')), ''),
                   'VL.APROX.TRIB. MUNICIPAL: ' || LTRIM(to_char((NVL(PCMOVCOMPLEPREFAT.VLITEMTRIBUTOSMUNIC,0) * PCMOVPREFAT.QTCONT),'999999999999999990.99')))
            END AS VLAPROXTRIB
            ,(CASE WHEN ((NVL(PCCLIENT.GERAGRPRETTRIB, 'N') = 'S') AND 
             ((NVL(PCCLIENT.ORGAOPUBFEDERAL, 'N') = 'S') OR 
              (NVL(PCCLIENT.ORGAOPUBMUNICIPAL, 'N') = 'S') OR 
              (NVL(PCCLIENT.ORGAOPUB, 'N') = 'S'))) THEN 'S' ELSE 'N' END) GERAGRPRETTRIB
            ,DECODE(NVL(PCCLIENT.RETECAOPISORGPUB, 'N'), 'S', ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLPISRETORGPUB, 0),2), 0) AS VLPISRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOCOFINSORGPUB, 'N'), 'S', ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLCOFINSRETORGPUB, 0),2), 0) AS VLCOFINSRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOCSORGPUB, 'N'), 'S', ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLCSLLRETORGPUB, 0),2), 0) AS VLCSLLRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOIRORGPUB, 'N'), 'S', ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLIRPJRETORGPUB, 0),2), 0) AS VLIRPJRETORGPUB
            ,DECODE(NVL(PCCLIENT.RETECAOIRORGPUB, 'N'), 'S', ROUND(PCMOVPREFAT.QTCONT * NVL((PCMOVPREFAT.PUNITCONT - PCMOVPREFAT.ST - PCMOVPREFAT.VLIPI), 0),2), 0) AS VLBCIRRFRETORGPUB
            ,PCMOVCOMPLEPREFAT.EXCLUIRICMSBASEPISCOFINS            
            ,PCMOVCOMPLEPREFAT.MOTREDADREM
            ,NVL(PCMOVCOMPLEPREFAT.ADREMICMS, 0) AS ADREMICMS
            ,NVL(PCMOVCOMPLEPREFAT.ADREMICMSRETEN, 0) AS ADREMICMSRETEN
            ,NVL(PCMOVCOMPLEPREFAT.PREDADREM, 0) AS PREDADREM
            ,NVL(PCMOVCOMPLEPREFAT.ADREMICMSDIF, 0) AS ADREMICMSDIF
            ,NVL(PCMOVCOMPLEPREFAT.ADREMICMSRET, 0) AS ADREMICMSRET
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.QBCMONO, 0),2) AS QBCMONO
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VICMSMONO, 0),2) AS VICMSMONO
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.QBCMONORETEN, 0),2) AS QBCMONORETEN
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VICMSMONORETEN, 0),2) AS VICMSMONORETEN
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.QBCMONODIF, 0),2) AS QBCMONODIF
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VICMSMONODIF, 0),2) AS VICMSMONODIF
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.QBCMONORET, 0),2) AS QBCMONORET
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VICMSMONORET, 0),2) AS VICMSMONORET
            ,PCPRODUT.OBSCONTXCAMPO
            ,PCPRODUT.OBSCONTXTEXTO
            ,PCPRODUT.OBSFISCOXCAMPO
            ,PCPRODUT.OBSFISCOXTEXTO
            ,PCMOVCOMPLEPREFAT.SOMARVALORDIFBCICMS
            ,ROUND(PCMOVPREFAT.QTCONT * NVL(PCMOVCOMPLEPREFAT.VLFCPDIF, 0),2) AS VLFCPDIF
            ,PCMOVCOMPLEPREFAT.INDDEDUZDESONERACAO
            ,PCMOVPREFAT.NUMTRANSITEM
      FROM   PCMOVPREFAT
            ,PCPRODUT
            ,PCMOVCOMPLEPREFAT
            ,PCEMBALAGEM
            ,PCCONSUM
            ,PCFORNEC
            ,PCTABPR
            ,PCSECAO
            ,PCMOVIMPOSTOS
            ,PCDEPTO
            ,PCFILIAL
            ,PCPEDC
            ,PCMARCA
            ,PCNFSAIDPREFAT
            ,PCPEDIDADOSVEICULOS
            ,PCCLIENT
            ,PCEQUIPAMENTO
            ,SQL_NFE_CABECALHO_SAIDA
            ,PCPRODFILIAL
            ,PCEST
            ,PCTRIBUT
      WHERE  PCMOVPREFAT.NUMTRANSITEM = PCMOVCOMPLEPREFAT.NUMTRANSITEM(+)
      AND    PCMOVPREFAT.NUMTRANSVENDA = SQL_NFE_CABECALHO_SAIDA.NUM_TRANSACAO
      AND    PCMOVPREFAT.CODPROD = PCPRODUT.CODPROD
      AND    PCNFSAIDPREFAT.NUMTRANSVENDA = PCMOVPREFAT.NUMTRANSVENDA
      AND    PCNFSAIDPREFAT.NUMNOTA = PCMOVPREFAT.NUMNOTA
      AND    PCMOVPREFAT.CODCLI = PCCLIENT.CODCLI(+)
      AND    PCMOVPREFAT.CODEQUIPAMENTO = PCEQUIPAMENTO.CODEQUIPAMENTO(+)
      AND    PCMOVPREFAT.CODPROD = PCTABPR.CODPROD(+)
      AND    PCMOVPREFAT.CODAUXILIAR = PCEMBALAGEM.CODAUXILIAR(+)
      AND    PCMOVPREFAT.CODPROD = PCEMBALAGEM.CODPROD(+)
      AND    PCMOVPREFAT.NUMTRANSVENDA = PCMOVIMPOSTOS.NUMTRANSVENDA(+)
      AND    PCMOVPREFAT.CODPROD = PCMOVIMPOSTOS.CODPROD(+)
      AND    PCMOVPREFAT.NUMSEQ = PCMOVIMPOSTOS.NUMSEQ(+)
      AND    NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL) = PCFILIAL.CODIGO
      AND    NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+)
      AND    PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)
      AND    PCMOVPREFAT.NUMREGIAO = PCTABPR.NUMREGIAO(+)
      AND    PCMOVPREFAT.NUMPED = PCPEDC.NUMPED(+)
      AND    PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC(+)
      AND    PCPRODUT.CODSEC = PCSECAO.CODSEC(+)
      AND    PCPRODUT.CODEPTO = PCDEPTO.CODEPTO(+)
      AND    PCMOVPREFAT.CODPROD = PCPEDIDADOSVEICULOS.CODPROD(+)
      AND    PCMOVPREFAT.NUMPED = PCPEDIDADOSVEICULOS.NUMPED(+)
      AND    PCMOVPREFAT.NUMSEQ = PCPEDIDADOSVEICULOS.NUMSEQ(+)
      AND    PCMOVPREFAT.CODPROD = PCPRODFILIAL.CODPROD(+)
      AND    NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL) = PCPRODFILIAL.CODFILIAL(+)
      AND    NVL(PCMOVPREFAT.QTCONT,0) > 0
      AND    PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
      AND    PCMOVPREFAT.CODPROD = PCEST.CODPROD
      AND    NVL(PCMOVPREFAT.CODFILIALRETIRA, NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL)) = PCEST.CODFILIAL
      AND    PCMOVPREFAT.CODST = PCTRIBUT.CODST(+)
      )
ORDER BY NUMERO_ADICAO
