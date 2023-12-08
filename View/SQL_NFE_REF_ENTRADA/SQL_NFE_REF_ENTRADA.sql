CREATE OR REPLACE VIEW SQL_NFE_REF_ENTRADA AS
SELECT PCNFENT.NUMTRANSENT AS NUM_TRANSACAO,
       UF_E.UF AS SIGLA_UF,
       REPLACE(REPLACE(REPLACE(DECODE(PCNFENT.GERANFVENDA,
                                      'S',
                                      EMITENTE.CGC,
                                      PCNFENT.CGC),
                               '.',
                               ''),
                       '/',
                       ''),
               '-',
               '') AS CNPJ_E,
       PCNFENT.DTEMISSAOPRODRURAL AS DATA_EMISSAO,
       PCNFENT.CHAVENFEPRODRURAL AS CHAVE_ACESSO,
       EMITENTE.CODPRODUTORRURAL AS IE,
       DECODE(LPAD(NVL(PCNFENT.MODELOPRODRURAL, '04'), 2, '0'),
              '01',
              '01',
              '04') AS MODELO,
       DECODE(NVL(PCNFENT.SERIEPRODRURAL, 'U'),
              'U',
              '0',
              PCNFENT.SERIEPRODRURAL) AS SERIE,
       PCNFENT.NUMNOTAPRODRURAL AS NUMERO_NOTA,
       4 DOCREF,
       '0' NUMSEQECF
  FROM PCNFENT, 
       PCFORNEC EMITENTE, 
       PCESTADO UF_E, 
       PCCIDADE CIDADE_E

 WHERE PCNFENT.CODFORNEC = EMITENTE.CODFORNEC
   AND EMITENTE.CODCIDADE = CIDADE_E.CODCIDADE
   AND PCNFENT.ESPECIE IN ('NF', 'NE')
   AND CIDADE_E.UF = UF_E.UF
   AND NVL(PCNFENT.NUMNOTAPRODRURAL, 0) > 0 