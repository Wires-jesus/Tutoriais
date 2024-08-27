CREATE OR REPLACE FUNCTION CTE_IDENTIFICACAO
(
   P_TRANSACAO   IN NUMBER
  ,P_CODIGO_FILIAL IN VARCHAR2
  ,P_MOV IN VARCHAR2 DEFAULT 'S'
) RETURN TABELA_CTE_IDENTIFICACAO IS

   CURSOR CR_IDENTIFICACAO IS
      SELECT PCNFBASE.CODFISCAL AS CFOP
            ,PCNFSAID.CHAVECTE
            ,PCNFSAID.NUMTRANSVENDA AS NUMTRANSACAO
            ,PCCFO.DESCCFO AS NATUREZA_OP
            ,DECODE(NVL(PCNFSAID.TIPOFRETE
                       ,'C')
                   ,'C'
                   ,(CASE WHEN (SELECT COUNT(*) AS SOMA FROM PCPREST WHERE NUMTRANSVENDA = P_TRANSACAO AND ROWNUM = 1) > 0 THEN
                       1
                     ELSE
                       0
                     END)
                   ,'F'
                   ,1
                   ,2) AS FORMA_PAGAMENTO
             ,REPLACE(TRANSLATE(PCNFSAID.SERIE,
                             TRIM(TRANSLATE(PCNFSAID.SERIE,
                                            '1234567890',
                                            ' ')) || ' ',
                             ' '),
                   ' ',
                   '') SERIE
            ,PCNFSAID.NUMNOTA AS NUMERO_NOTA
            ,TO_DATE((TO_CHAR(PCNFSAID.DTSAIDA
                             ,'dd/MM/yyyy') || ' ' ||
                     NVL(PCNFSAID.HORALANC
                         ,'00') || ':' || NVL(PCNFSAID.MINUTOLANC
                                              ,'00') || ':00')
                    ,'dd/MM/yyyy HH24:MI:SS') AS DATA_HORA_EMISSAO
            ,DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPODACTE'
                                                     ,PCFILIAL.CODIGO)
                       ,'R')
                   ,'R'
                   ,1
                   ,2) AS TIPO_DACTE
            ,NVL(PCNFSAID.TIPOEMISSAO
                ,'1') AS TIPO_EMISSAO
            ,NVL(PCNFSAID.TIPOEMISSAOCTE,0) AS TIPO_CTE
            /*,DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE'
                                                     ,PCFILIAL.CODIGO)
                       ,'H')
                   ,'H'
                   ,2
                   ,1) AS TIPO_AMBIENTE*/
            ,DECODE(NVL(PCNFSAID.AMBIENTECTE,PCNFSAID.AMBIENTENFE), 'H', 2, 1) AS TIPO_AMBIENTE
            ,CASE WHEN NVL(PCNFSAID.TIPOSUBCONTRATACAOCTE,'0') = '0' THEN
                  NVL(PCNFSAID.CHAVECTEREF, (SELECT S.CHAVECTE FROM PCNFSAID S WHERE S.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDAORIGEM)) 
             ELSE NVL(PCNFSAID.CTESUBCONTRATADOCHAVECTEREF, (SELECT S.CHAVECTE FROM PCNFSAID S WHERE S.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDAORIGEM)) 
             END AS CHAVECTE_REFERENCIADA
            ,1 AS MODAL
            ,DECODE(PCNFSAID.TIPOSERVICOCTE,'1',
                    DECODE(PCNFSAID.TIPOSUBCONTRATACAOCTE,'1',1, 0), DECODE(PCNFSAID.TIPOSERVICOCTE,'2', 2, 0)) AS TIPO_SERVICO
            ,NVL(TIPOSERVICOCTE, '0') AS TIPOSERVICOCTE
            ,1 AS RETIRA
            ,'' AS DETALHE_RETIRA
            ,NVL(PCNFSAID.TOMADORCTE,
                 CASE WHEN (TIPOSERVICOCTE = '1' AND TIPOSUBCONTRATACAOCTE = '1') THEN
                           4
                      WHEN (TIPOSERVICOCTE = '2' AND TIPOSUBCONTRATACAOCTE = '0') THEN
                           1
                 ELSE
                   DECODE(NVL(PCNFSAID.TIPOFRETE,'C') ,'C' ,0 ,'G' ,0 ,3)
                 END) AS TOMADOR_SERVICO
            ,PCNFSAID.VLTOTAL
            ,PCNFSAID.PROTOCOLOCTE
            ,NVL(PCNFSAID.DTHORAAUTORIZACAOSEFAZ, PCNFSAID.DTA_HORAENVIOSEFAZ) AS DTHORAAUTORIZACAOSEFAZ
            ,PCNFSAID.DTAHORAENTRADACONTIGENCIA
            ,PCNFSAID.JUSTIFICATIVACONTIGENCIA
            ,PCNFSAID.VLFRETE AS VLFRETE
            ,(SELECT DECODE(NVL(N.FRETEDESPACHO, N.TIPOFRETE), 'F', D.IEENT, DECODE(R.CODCLI, NULL, F.IE, R.IEENT)) AS  IE_TOMADOR
               FROM PCNFSAID N,
                    PCCLIENT D,
                    PCCLIENT R,
                    PCFILIAL L,
                    PCFORNEC F
               WHERE  NVL(N.CODFILIALNF,N.CODFILIAL) = L.CODIGO
               AND    L.CODFORNEC = F.CODFORNEC(+)
               AND    R.CODCLI(+) = N.CODREMETENTEFRETE
               AND    D.CODCLI(+) = N.CODDESTINATARIOFRETE
               AND    N.CODCLI = F.CODCLI
               AND    N.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA ) AS IE_TOMADOR
            ,NVL(PCNFSAID.CTEGLOBALIZADO, 'N') CTE_GLOBALIZADO
            ,PCNFSAID.INFGLOBALIZADO INF_GLOBALIZADO
            ,PCNFSAID.QRCODE
            ,PCNFSAID.CODIGONUMERICOCHAVE AS CODIGO_NUMERICO_CHAVE
      FROM   PCNFSAID
            ,PCFILIAL
            ,PCNFBASE
            ,PCCFO
      WHERE  PCNFSAID.NUMTRANSVENDA = PCNFBASE.NUMTRANSVENDA(+)
      AND    NVL(PCNFSAID.CODFILIALNF
                ,PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
      AND    PCNFBASE.CODFISCAL = PCCFO.CODFISCAL(+)
      AND    PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
      AND    P_MOV = 'S'

      UNION ALL

      SELECT PCNFBASE.CODFISCAL AS CFOP
            ,PCNFENT.CHAVECTE
            ,PCNFENT.NUMTRANSENT AS NUMTRANSACAO
            ,PCCFO.DESCCFO AS NATUREZA_OP
            ,DECODE(NVL(PCNFENT.TIPOFRETECIFFOB
                       ,'C')
                   ,'C'
                   ,(CASE WHEN (SELECT COUNT(*) AS SOMA FROM PCPREST WHERE NUMTRANSVENDA = P_TRANSACAO AND ROWNUM = 1) > 0 THEN
                       1
                     ELSE
                       0
                     END)
                   ,'F'
                   ,1
                   ,2) AS FORMA_PAGAMENTO
             ,REPLACE(TRANSLATE(PCNFENT.SERIE,
                             TRIM(TRANSLATE(PCNFENT.SERIE,
                                            '1234567890',
                                            ' ')) || ' ',
                             ' '),
                   ' ',
                   '') SERIE
            ,PCNFENT.NUMNOTA AS NUMERO_NOTA
            ,TO_DATE((TO_CHAR(PCNFENT.DTEMISSAO
                             ,'dd/MM/yyyy') || ' ' ||
                     NVL(PCNFENT.HORALANC
                         ,'00') || ':' || NVL(PCNFENT.MINUTOLANC
                                              ,'00') || ':00')
                    ,'dd/MM/yyyy HH24:MI:SS') AS DATA_HORA_EMISSAO
            ,DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPODACTE'
                                                     ,PCFILIAL.CODIGO)
                       ,'R')
                   ,'R'
                   ,1
                   ,2) AS TIPO_DACTE
            ,NVL(PCNFENT.TIPOEMISSAO
                ,'1') AS TIPO_EMISSAO
            ,'2' AS TIPO_CTE
            ,DECODE(NVL(PCNFENT.AMBIENTENFE,
                        NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE'
                                                          ,PCFILIAL.CODIGO)
                            ,'H'))
                   ,'H'
                   ,2
                   ,1) AS TIPO_AMBIENTE
            ,'' AS CHAVECTE_REFERENCIADA
            ,1 AS MODAL
            --,0 AS TIPO_SERVICO
            ,NVL((SELECT DECODE(PCNFSAID.TIPOSERVICOCTE,'1', 
                  DECODE(PCNFSAID.TIPOSUBCONTRATACAOCTE,'1',1, 0), DECODE(PCNFSAID.TIPOSERVICOCTE,'2', 2, 0))
                  FROM PCNFSAID
                  WHERE PCNFSAID.NUMTRANSCTEANUL = PCNFENT.NUMTRANSENT), 0) AS TIPO_SERVICO   
            ,'0' AS TIPOSERVICOCTE
            ,1 AS RETIRA
            ,'' AS DETALHE_RETIRA
            ,DECODE(NVL(PCNFENT.TIPOFRETECIFFOB
                       ,'C')
                   ,'C'
                   ,0
                   ,'G'
                   ,0
                   ,3) AS TOMADOR_SERVICO
            ,PCNFENT.VLTOTAL
            ,PCNFENT.PROTOCOLOCTE
            ,PCNFENT.DTHORAAUTORIZACAOSEFAZ
            ,PCNFENT.DTAHORAENTRADACONTIGENCIA
            ,PCNFENT.JUSTIFICATIVACONTIGENCIA
            ,PCNFENT.VLFRETE AS VLFRETE,
            (SELECT DECODE(NVL(N.FRETEDESPACHO, N.TIPOFRETE), 'F', D.IEENT, DECODE(R.CODCLI, NULL, F.IE, R.IEENT)) AS  IE_TOMADOR
             FROM PCNFSAID N,
                  PCCLIENT D,
                  PCCLIENT R,
                  PCFILIAL L,
                  PCFORNEC F
             WHERE  NVL(N.CODFILIALNF,N.CODFILIAL) = L.CODIGO
             AND    L.CODFORNEC = F.CODFORNEC(+)
             AND    R.CODCLI(+) = N.CODREMETENTEFRETE
             AND    D.CODCLI(+) = N.CODDESTINATARIOFRETE
             AND    N.CODCLI = F.CODCLI
             AND    N.NUMTRANSCTEANUL = PCNFENT.NUMTRANSENT ) AS IE_TOMADOR
            ,'N' CTE_GLOBALIZADO
            ,'' INF_GLOBALIZADO
            ,PCNFENT.QRCODE
            ,PCNFENT.CODIGONUMERICOCHAVE AS CODIGO_NUMERICO_CHAVE
      FROM   PCNFENT
            ,PCFILIAL
            ,PCNFBASE
            ,PCCFO
      WHERE  PCNFENT.NUMTRANSENT = PCNFBASE.NUMTRANSENT(+)
      AND    PCNFBASE.CODCONT(+) = PCNFENT.CODCONT
      AND    NVL(PCNFENT.CODFILIALNF
                ,PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
      AND    PCNFBASE.CODFISCAL = PCCFO.CODFISCAL(+)
      AND    PCNFENT.NUMTRANSENT = P_TRANSACAO
      AND    P_MOV = 'E';


   RETORNO TABELA_CTE_IDENTIFICACAO;

  -- VCODIGO_CLIENTE PCCLIENT.CODCLI%TYPE;

   VCODIGO_MUNICIPIO_INICIO PCCIDADE.CODIBGE%TYPE;
   VNOME_MUNICIPIO_INICIO   PCCIDADE.NOMECIDADE%TYPE;
   VSIGLA_UF_INICIO         PCCIDADE.UF%TYPE;

   VCODIGO_MUNICIPIO_FIM PCCIDADE.CODIBGE%TYPE;
   VNOME_MUNICIPIO_FIM   PCCIDADE.NOMECIDADE%TYPE;
   VSIGLA_UF_FIM         PCCIDADE.UF%TYPE;

   VCODIGO_MUNICIPIO_EMISSAO PCCIDADE.CODIBGE%TYPE;
   VNOME_MUNICIPIO_EMISSAO   PCCIDADE.NOMECIDADE%TYPE;
   VSIGLA_UF_EMISSAO         PCCIDADE.UF%TYPE;

   VTOTAL_PESO_BRUTO         NUMBER(12,6);
   VTOTAL_CUBAGEM            NUMBER(12,6);
   VQTDE_VOLUMES             NUMBER(12,6);
   VTOTALVOLUMETEMP          NUMBER(12,6);
   VLACRES                   VARCHAR2(200);

   NUMTRANSACAO_TEMP      PCNFSAID.NUMTRANSVENDA%TYPE;
   
   VTIPOSERVICOCTE        PCNFSAID.TIPOSERVICOCTE%TYPE;
   VTOMADORCTE            PCNFSAID.TOMADORCTE%TYPE;
BEGIN
   RETORNO := TABELA_CTE_IDENTIFICACAO();
   NUMTRANSACAO_TEMP := P_TRANSACAO;
   
   BEGIN
     SELECT NVL(PCNFSAID.TIPOSERVICOCTE, 0) AS TIPOSERVICOCTE, NVL(PCNFSAID.TOMADORCTE, 0) TOMADORCTE
     INTO VTIPOSERVICOCTE, VTOMADORCTE
     FROM PCNFSAID
     WHERE PCNFSAID.NUMTRANSVENDA = NUMTRANSACAO_TEMP;
   EXCEPTION
   WHEN OTHERS THEN
     NULL;
   END;
     
   

   IF P_MOV = 'E' THEN
      BEGIN
         SELECT NUMTRANSVENDA
           INTO NUMTRANSACAO_TEMP
           FROM PCNFSAID
          WHERE NUMTRANSCTEANUL = P_TRANSACAO;
      EXCEPTION
         WHEN OTHERS THEN
           RETURN RETORNO;
      END;
   END IF;
   
   IF (VTIPOSERVICOCTE = 1 AND VTOMADORCTE = 4) THEN
   --PROCESSO PARA CTE DE SUBCONTRATAÇÃO, SOLICITADO PELO VENDAS DDFISCAL-15720
     BEGIN
       SELECT --MUNICIPIO INICIO DA PRESTACAO
              PCNFSAID.CODMUNINICTE  AS CODIGO_MUNICIPIO_INI,
              INI.NOMECIDADE         AS NOME_MUNICIPIO_INI,
              INI.UF                 AS SIGLA_UF_INI,
              --MUNICIPIO FIM DA PRESTACAO
              PCNFSAID.CODMUNFIMCTE  AS CODIGO_MUNICIPIO_FIM,
              FIM.NOMECIDADE         AS NOME_MUNICIPIO_FIM,
              FIM.UF                 AS SIGLA_UF_FIM
         INTO VCODIGO_MUNICIPIO_INICIO,
              VNOME_MUNICIPIO_INICIO,
              VSIGLA_UF_INICIO,
              VCODIGO_MUNICIPIO_FIM,
              VNOME_MUNICIPIO_FIM,
              VSIGLA_UF_FIM
         FROM PCNFSAID, PCCIDADE INI, PCCIDADE FIM
        WHERE PCNFSAID.CODMUNINICTE = INI.CODIBGE
          AND PCNFSAID.CODMUNFIMCTE = FIM.CODIBGE
          AND PCNFSAID.NUMTRANSVENDA = NUMTRANSACAO_TEMP;
     EXCEPTION
       WHEN OTHERS THEN
         NULL;
     END;
   ELSE
   --PROCESSO NORMAL
     --MUNICIPIO INICIO DA PRESTACAO (REMETENTE)
     BEGIN
      SELECT 
             CASE WHEN ((PCNFSAID.TIPOSERVICOCTE = 1) AND (NVL(PCNFSAID.CODCIDADECOLETA, 0) > 0)) THEN
                       REM.CODIGO_MUNICIPIO
             ELSE
                       DECODE(PCNFSAID.CHAVECTEREF, NULL, REM.CODIGO_MUNICIPIO, EMIT.CODIGO_MUNICIPIO)
             END
             ,CASE WHEN ((PCNFSAID.TIPOSERVICOCTE = 1) AND (NVL(PCNFSAID.CODCIDADECOLETA, 0) > 0)) THEN
                       REM.NOME_MUNICIPIO
             ELSE
                       DECODE(PCNFSAID.CHAVECTEREF, NULL, REM.NOME_MUNICIPIO, EMIT.NOME_MUNICIPIO)
             END
             ,CASE WHEN ((PCNFSAID.TIPOSERVICOCTE = 1) AND (NVL(PCNFSAID.CODCIDADECOLETA, 0) > 0)) THEN
                       REM.SIGLA_UF
             ELSE
                       DECODE(PCNFSAID.CHAVECTEREF, NULL, REM.SIGLA_UF, EMIT.SIGLA_UF)
             END
      INTO   VCODIGO_MUNICIPIO_INICIO
            ,VNOME_MUNICIPIO_INICIO
            ,VSIGLA_UF_INICIO
      FROM   PCNFSAID,
             (SELECT  NVL(CIDADE_E.CODIBGE ,0) AS CODIGO_MUNICIPIO
              ,CIDADE_E.NOMECIDADE AS NOME_MUNICIPIO
              ,UF_E.UF AS SIGLA_UF
          FROM PCCLIENT REMETENTE
              ,PCCIDADE CIDADE_E
              ,PCESTADO UF_E
              ,PCPAIS PAIS_E
              ,PCNFSAID
         WHERE PCNFSAID.CODREMETENTEFRETE = REMETENTE.CODCLI
           AND NVL(PCNFSAID.CODCIDADECOLETA, REMETENTE.CODCIDADE) = CIDADE_E.CODCIDADE
           AND CIDADE_E.UF = UF_E.UF(+)
           AND UF_E.CODPAIS = PAIS_E.CODPAIS(+)
           AND PCNFSAID.NUMTRANSVENDA = NUMTRANSACAO_TEMP) REM,


      TABLE(CAST(CTE_EMITENTE(P_CODIGO_FILIAL) AS TABELA_CTE_EMITENTE)) EMIT
      WHERE PCNFSAID.NUMTRANSVENDA = NUMTRANSACAO_TEMP;
     EXCEPTION
          WHEN OTHERS THEN
            NULL;
     END;

     -- MUNICIPIO FIM DA PRESTACAO (DESTINATARIO)
     BEGIN
       SELECT CODIGO_MUNICIPIO
             ,NOME_MUNICIPIO
             ,SIGLA_UF
       INTO   VCODIGO_MUNICIPIO_FIM
             ,VNOME_MUNICIPIO_FIM
             ,VSIGLA_UF_FIM
       FROM   TABLE(CAST(CTE_DESTINATARIO(NUMTRANSACAO_TEMP) AS TABELA_CTE_DESTINATARIO));
     EXCEPTION
           WHEN OTHERS THEN
             NULL;
     END;
   END IF;  

   -- MUNICIPIO DE EMISSAO (EMITENTE)
   BEGIN
     SELECT CODIGO_MUNICIPIO
           ,NOME_MUNICIPIO
           ,SIGLA_UF
     INTO   VCODIGO_MUNICIPIO_EMISSAO
           ,VNOME_MUNICIPIO_EMISSAO
           ,VSIGLA_UF_EMISSAO
     FROM   TABLE(CAST(CTE_EMITENTE(P_CODIGO_FILIAL) AS TABELA_CTE_EMITENTE));
   EXCEPTION
         WHEN OTHERS THEN
           NULL;
   END;

   -- PESO BRUTO E CUBAGEM
   BEGIN
     SELECT SUM(VALOR_PESO_BRUTO)
           ,SUM(CUBAGEM)
     INTO   VTOTAL_PESO_BRUTO
           ,VTOTAL_CUBAGEM
     FROM   TABLE(CAST(CTE_INFO_CARGA(NUMTRANSACAO_TEMP) AS TABELA_CTE_INFO_CARGA));
   EXCEPTION
         WHEN OTHERS THEN
           NULL;
   END;

   -- QUANTIDADE DE VOLUME
   BEGIN
      VQTDE_VOLUMES := 0;
      
     FOR DADOS IN (SELECT NUMTRANSVENDA
                        FROM PCNFSAID
                       WHERE NUMTRANSVENDACONHEC = NUMTRANSACAO_TEMP
                         AND ESPECIE NOT IN ('CE', 'CO', 'CT')) LOOP
        
     BEGIN                 
      SELECT SUM(NVL(NUMVOL,0)) 
        INTO VTOTALVOLUMETEMP
        FROM TABLE(NFE_RODAPE_SAIDA(DADOS.NUMTRANSVENDA));                   
                         
      EXCEPTION
        WHEN OTHERS THEN 
          VTOTALVOLUMETEMP := 0;
        END;
        
      VQTDE_VOLUMES := VQTDE_VOLUMES +  VTOTALVOLUMETEMP;             

     END LOOP;
     
     FOR DADOS IN (SELECT NVL(VOLUME,0) AS VOLUME
                FROM PCCONHECIMENTOFRETEI
               WHERE PCCONHECIMENTOFRETEI.NUMTRANSCONHEC = NUMTRANSACAO_TEMP) LOOP
    
      VQTDE_VOLUMES := VQTDE_VOLUMES +  DADOS.VOLUME;      
     END LOOP;    
   EXCEPTION
         WHEN OTHERS THEN
           NULL;
   END;

    --LACRES
    BEGIN
      FOR LACRE IN (SELECT PCLACREEDI.NUMLACRE
                      FROM PCNFSAID, PCLACREEDI
                     WHERE PCNFSAID.NUMCARGAEDI = PCLACREEDI.NUMCARGAEDI
                          AND PCNFSAID.NUMTRANSVENDA = NUMTRANSACAO_TEMP)
      LOOP
          VLACRES := VLACRES || LACRE.NUMLACRE || '; ';
      END LOOP;
    EXCEPTION
         WHEN OTHERS THEN
           NULL;
    END;


   FOR IDENTIFICACAO IN CR_IDENTIFICACAO LOOP
      RETORNO.EXTEND;

      RETORNO(RETORNO.COUNT) := TIPO_CTE_IDENTIFICACAO(NUM_TRANSACAO               => NULL
                                                      ,CHAVECTE                    => NULL
                                                      ,CFOP                        => NULL
                                                      ,NATUREZA_OP                 => NULL
                                                      ,FORMA_PAGAMENTO             => NULL
                                                      ,SERIE                       => NULL
                                                      ,NUMERO_NOTA                 => NULL
                                                      ,DATA_HORA_EMISSAO           => NULL
                                                      ,TIPO_DACTE                  => NULL
                                                      ,TIPO_EMISSAO                => NULL
                                                      ,TIPO_AMBIENTE               => NULL
                                                      ,TIPO_CTE                    => NULL
                                                      ,CHAVECTE_REFERENCIADA       => NULL
                                                      ,CODIGO_MUN_EMISSAO          => NULL
                                                      ,MUNICIPIO_EMISSAO           => NULL
                                                      ,SIGLA_UF_EMISSAO            => NULL
                                                      ,MODAL                       => NULL
                                                      ,TIPO_SERVICO                => NULL
                                                      ,TIPOSERVICOCTE              => NULL
                                                      ,CODIGO_MUN_INICIO_PRESTACAO => NULL
                                                      ,MUNICIPIO_INICIO_PRESTACAO  => NULL
                                                      ,SIGLA_UF_INICIO_PRESTACAO   => NULL
                                                      ,CODIGO_MUN_FIM_PRESTACAO    => NULL
                                                      ,MUNICIPIO_FIM_PRESTACAO     => NULL
                                                      ,SIGLA_UF_FIM_PRESTACAO      => NULL
                                                      ,RETIRA                      => NULL
                                                      ,DETALHE_RETIRA              => NULL
                                                      ,TOMADOR_SERVICO             => NULL
                                                      ,VALOR_TOTAL                 => NULL
                                                      ,PROTOCOLO_AUTORIZACAO       => NULL
                                                      ,DATA_HORA_AUTORIZACAO       => NULL
                                                      ,DTHORA_CONTINGENCIA         => NULL
                                                      ,JUSTIFICATIVA_CONTINGENCIA  => NULL
                                                      ,TOTAL_PESO_BRUTO            => NULL
                                                      ,TOTAL_CUBAGEM               => NULL
                                                      ,QTDE_VOLUMES                => NULL
                                                      ,LACRES                      => NULL
                                                      ,VALOR_TOTAL_SERVICO         => NULL
                                                      ,IE_TOMADOR                  => NULL
                                                      ,CTE_GLOBALIZADO             => NULL
                                                      ,INF_GLOBALIZADO             => NULL 
                                                      ,QRCODE                      => NULL
                                                      ,CODIGO_NUMERICO_CHAVE       => NULL
                                                       );


      RETORNO(RETORNO.COUNT).NUM_TRANSACAO               := IDENTIFICACAO.NUMTRANSACAO;
      RETORNO(RETORNO.COUNT).CHAVECTE                    := IDENTIFICACAO.CHAVECTE;
      RETORNO(RETORNO.COUNT).CFOP                        := IDENTIFICACAO.CFOP;
      RETORNO(RETORNO.COUNT).NATUREZA_OP                 := IDENTIFICACAO.NATUREZA_OP;
      RETORNO(RETORNO.COUNT).FORMA_PAGAMENTO             := IDENTIFICACAO.FORMA_PAGAMENTO;
      RETORNO(RETORNO.COUNT).SERIE                       := IDENTIFICACAO.SERIE;
      RETORNO(RETORNO.COUNT).NUMERO_NOTA                 := IDENTIFICACAO.NUMERO_NOTA;
      RETORNO(RETORNO.COUNT).DATA_HORA_EMISSAO           := IDENTIFICACAO.DATA_HORA_EMISSAO;
      RETORNO(RETORNO.COUNT).TIPO_DACTE                  := IDENTIFICACAO.TIPO_DACTE;
      RETORNO(RETORNO.COUNT).TIPO_EMISSAO                := IDENTIFICACAO.TIPO_EMISSAO;
      RETORNO(RETORNO.COUNT).TIPO_AMBIENTE               := IDENTIFICACAO.TIPO_AMBIENTE;
      RETORNO(RETORNO.COUNT).TIPO_CTE                    := IDENTIFICACAO.TIPO_CTE;
      RETORNO(RETORNO.COUNT).CHAVECTE_REFERENCIADA       := IDENTIFICACAO.CHAVECTE_REFERENCIADA;
      RETORNO(RETORNO.COUNT).CODIGO_MUN_EMISSAO          := VCODIGO_MUNICIPIO_EMISSAO;
      RETORNO(RETORNO.COUNT).MUNICIPIO_EMISSAO           := VNOME_MUNICIPIO_EMISSAO;
      RETORNO(RETORNO.COUNT).SIGLA_UF_EMISSAO            := VSIGLA_UF_EMISSAO;
      RETORNO(RETORNO.COUNT).MODAL                       := IDENTIFICACAO.MODAL;
      RETORNO(RETORNO.COUNT).TIPO_SERVICO                := IDENTIFICACAO.TIPO_SERVICO;
      RETORNO(RETORNO.COUNT).TIPOSERVICOCTE              := IDENTIFICACAO.TIPOSERVICOCTE;
      RETORNO(RETORNO.COUNT).CODIGO_MUN_INICIO_PRESTACAO := VCODIGO_MUNICIPIO_INICIO;
      RETORNO(RETORNO.COUNT).MUNICIPIO_INICIO_PRESTACAO  := VNOME_MUNICIPIO_INICIO;
      RETORNO(RETORNO.COUNT).SIGLA_UF_INICIO_PRESTACAO   := VSIGLA_UF_INICIO;
      RETORNO(RETORNO.COUNT).CODIGO_MUN_FIM_PRESTACAO    := VCODIGO_MUNICIPIO_FIM;
      RETORNO(RETORNO.COUNT).MUNICIPIO_FIM_PRESTACAO     := VNOME_MUNICIPIO_FIM;
      RETORNO(RETORNO.COUNT).SIGLA_UF_FIM_PRESTACAO      := VSIGLA_UF_FIM;
      RETORNO(RETORNO.COUNT).RETIRA                      := IDENTIFICACAO.RETIRA;
      RETORNO(RETORNO.COUNT).DETALHE_RETIRA              := IDENTIFICACAO.DETALHE_RETIRA;
      RETORNO(RETORNO.COUNT).TOMADOR_SERVICO             := IDENTIFICACAO.TOMADOR_SERVICO;
      RETORNO(RETORNO.COUNT).VALOR_TOTAL                 := IDENTIFICACAO.VLTOTAL;
      RETORNO(RETORNO.COUNT).PROTOCOLO_AUTORIZACAO       := IDENTIFICACAO.PROTOCOLOCTE;
      RETORNO(RETORNO.COUNT).DATA_HORA_AUTORIZACAO       := IDENTIFICACAO.DTHORAAUTORIZACAOSEFAZ;
      RETORNO(RETORNO.COUNT).DTHORA_CONTINGENCIA         := IDENTIFICACAO.DTAHORAENTRADACONTIGENCIA;
      RETORNO(RETORNO.COUNT).JUSTIFICATIVA_CONTINGENCIA  := IDENTIFICACAO.JUSTIFICATIVACONTIGENCIA;
      RETORNO(RETORNO.COUNT).TOTAL_PESO_BRUTO            := VTOTAL_PESO_BRUTO;
      RETORNO(RETORNO.COUNT).TOTAL_CUBAGEM               := VTOTAL_CUBAGEM;
      RETORNO(RETORNO.COUNT).QTDE_VOLUMES                := VQTDE_VOLUMES;
      RETORNO(RETORNO.COUNT).LACRES                      := VLACRES;
      RETORNO(RETORNO.COUNT).VALOR_TOTAL_SERVICO         := IDENTIFICACAO.VLFRETE;
      RETORNO(RETORNO.COUNT).IE_TOMADOR                  := IDENTIFICACAO.IE_TOMADOR;
      RETORNO(RETORNO.COUNT).CTE_GLOBALIZADO             := IDENTIFICACAO.CTE_GLOBALIZADO;      
      RETORNO(RETORNO.COUNT).INF_GLOBALIZADO             := IDENTIFICACAO.INF_GLOBALIZADO;
      RETORNO(RETORNO.COUNT).QRCODE                      := IDENTIFICACAO.QRCODE;
      RETORNO(RETORNO.COUNT).CODIGO_NUMERICO_CHAVE       := IDENTIFICACAO.CODIGO_NUMERICO_CHAVE;

   END LOOP;
   RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;