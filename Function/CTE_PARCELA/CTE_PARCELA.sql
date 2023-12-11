CREATE OR REPLACE FUNCTION CTE_PARCELA(P_TRANSACAO NUMBER)
  RETURN TABELA_CTE_PARCELA IS

  CURSOR CR_PARCELA IS
SELECT PCPREST.NUMTRANSVENDA AS NUM_TRANSACAO,
       (TO_CHAR(PCPREST.DUPLIC) || ' - ' || TO_CHAR(PCPREST.PREST)) AS PRESTACAO,
       DECODE(NVL(PCPREST.CODCOBORIG, PCPREST.CODCOB),
              'VPP',
              PCPREST.DTEMISSAO,
              PCPREST.DTVENC) AS DATAVENCIMENTO,
       NVL(PCNFSAID.VLFRETE, PCPREST.VALOR) VALOR,
       NVL(PCPREST.CODCOBORIG, PCPREST.CODCOB) AS CODCOB,
       NVL(PCPREST.VALORDESC, 0) AS VALORDESCONTO,
       PCPREST.PREST AS PREST,
       'VALOR FRETE' AS NOME,
       'GRIS' AS GRIS,
       NVL(PCNFSAID.VLGRIS,0) VLGRIS,
       'PEDAGIO' AS PEDAGIO,
       NVL(PCNFSAID.VLDESPPEDAGIO, 0) VLDESPPEDAGIO,
       'TAS' AS TAS,
       NVL(PCNFSAID.VLTAS, 0) VLTAS , 
       'OUTRAS' AS OUTRAS,
       NVL(PCNFSAID.VLOUTRAS,0) VLOUTRAS,
       'VALOR SEGURO' AS SEGURO,
       NVL(PCNFSAID.VLSEGURO, 0) AS VLSEGURO
  FROM PCPREST, PCNFSAID, PCCOB
 WHERE PCPREST.STATUS = 'A'
   --AND PCPREST.DTDESD IS NULL
   AND PCPREST.DTESTORNO IS NULL
   AND PCPREST.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
   AND PCCOB.CODCOB = PCPREST.CODCOB
   AND NVL(PCNFSAID.NUMCUPOM, 0) < 1
   AND NVL(PCPREST.VALOR, 0) > 0
   AND PCPREST.CODCOB NOT IN
       ('BNF', 'BNFT', 'BNFR', 'BNTR', 'DESC', 'DESD', 'CRED', 'DEVP',
        'DEVT', 'BNRP', 'BNFM', 'BNFI', 'BNTR', 'BNFN', 'BNFC', 'TR')
   AND NVL(PCCOB.CARTAO, 'N') = 'N'
   AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
UNION ALL
SELECT DISTINCT PCPREST.NUMTRANSVENDA AS NUM_TRANSACAO,
                (TO_CHAR(PCPREST.DUPLIC) || ' - ' || TO_CHAR(PCPREST.PREST)) AS PRESTACAO,
                DECODE(NVL(PCPREST.CODCOBORIG, PCPREST.CODCOB),
                       'VPP',
                       PCPREST.DTEMISSAO,
                       PCPREST.DTVENC) AS DATAVENCIMENTO,
                NVL(PCNFSAID.VLFRETE, PCPREST.VALOR) VALOR,
                NVL(PCPREST.CODCOBORIG, PCPREST.CODCOB) AS CODCOB,
                NVL(PCPREST.VALORDESC, 0) AS VALORDESCONTO,
                PCDESD.PRESTORIG AS PREST,
                'VALOR FRETE' AS NOME,
                'GRIS' AS GRIS,
                NVL(PCNFSAID.VLGRIS,0) VLGRIS,
                'PEDAGIO' AS PEDAGIO,
                NVL(PCNFSAID.VLDESPPEDAGIO, 0) VLDESPPEDAGIO,
                'TAS' AS TAS,
                NVL(PCNFSAID.VLTAS, 0) VLTAS , 
       'OUTRAS' AS OUTRAS,
       NVL(PCNFSAID.VLOUTRAS,0) VLOUTRAS,
       'VALOR SEGURO' AS SEGURO,
       NVL(PCNFSAID.VLSEGURO, 0) AS VLSEGURO 
  FROM PCPREST, PCDESD, PCNFSAID, PCCOB
 WHERE PCPREST.CODCOB = 'DESD'
   AND PCDESD.NUMTRANSVENDAORIG = PCPREST.NUMTRANSVENDA
   AND PCDESD.PRESTORIG = PCPREST.PREST
   AND PCNFSAID.NUMTRANSVENDA = PCPREST.NUMTRANSVENDA
   AND PCCOB.CODCOB = PCPREST.CODCOB
   AND PCDESD.PRESTORIG NOT IN (SELECT PRESTDEST FROM PCDESD  WHERE PCDESD.NUMTRANSVENDAORIG = P_TRANSACAO)
   AND DTDESD IS NOT NULL
   AND NVL(PCCOB.CARTAO, 'N') = 'N'
   AND NVL(PCNFSAID.NUMCUPOM, 0) < 1
   AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO;

  RETORNO TABELA_CTE_PARCELA;
BEGIN
  RETORNO := TABELA_CTE_PARCELA();

  FOR ITEM IN CR_PARCELA LOOP
    RETORNO.EXTEND;
    
    RETORNO(RETORNO.COUNT) := TIPO_CTE_PARCELA(   PRESTACAO                => NULL,
                                              VALOR                        => NULL,
                                              VALORDESCONTO                => NULL,
                                              DATAVENCIMENTO               => NULL,
                                              CODCOB                       => NULL,
                                              NOME                         => NULL,
                                              GRIS                         => NULL,
                                              VLGRIS                       => NULL,
                                              PEDAGIO                      => NULL,
                                              VLDESPPEDAGIO                => NULL,
                                              TAS                          => NULL,
                                              VLTAS                        => NULL, 
                                              VLOUTRAS                     => NULL,
                                              OUTRAS                       => NULL,
                                              SEGURO                       => NULL,
                                              VALOR_SEGURO                 => NULL );
                                              
    RETORNO(RETORNO.COUNT).PRESTACAO                    := ITEM.PRESTACAO;
    RETORNO(RETORNO.COUNT).VALOR                        := ITEM.VALOR;
    RETORNO(RETORNO.COUNT).VALORDESCONTO                := ITEM.VALORDESCONTO;
    RETORNO(RETORNO.COUNT).DATAVENCIMENTO               := ITEM.DATAVENCIMENTO;
    RETORNO(RETORNO.COUNT).CODCOB                       := ITEM.CODCOB;
    RETORNO(RETORNO.COUNT).NOME                         := ITEM.NOME;
    RETORNO(RETORNO.COUNT).GRIS                         := ITEM.GRIS;
    RETORNO(RETORNO.COUNT).VLGRIS                       := ITEM.VLGRIS;
    RETORNO(RETORNO.COUNT).PEDAGIO                      := ITEM.PEDAGIO;
    RETORNO(RETORNO.COUNT).VLDESPPEDAGIO                := ITEM.VLDESPPEDAGIO;
    RETORNO(RETORNO.COUNT).TAS                          := ITEM.TAS;
    RETORNO(RETORNO.COUNT).VLTAS                        := ITEM.VLTAS;
    RETORNO(RETORNO.COUNT).VLOUTRAS                     := ITEM.VLOUTRAS;
    RETORNO(RETORNO.COUNT).OUTRAS                       := ITEM.OUTRAS; 
    RETORNO(RETORNO.COUNT).SEGURO                       := ITEM.SEGURO; 
    RETORNO(RETORNO.COUNT).VALOR_SEGURO                 := ITEM.VLSEGURO; 
  
  END LOOP;

  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;