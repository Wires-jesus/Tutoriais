CREATE OR REPLACE PROCEDURE GERALIVRO_ENTRADA(DATA1      IN DATE,
                                              DATA2      IN DATE,
                                              PCODFILIAL IN VARCHAR2,
                                              NUMNOTA1   IN NUMBER,
                                              NUMNOTA2   IN NUMBER,
                                              RESULTADO  OUT VARCHAR2) IS
  /*********************************************************************************************************/
  V_SQL                        varchar2(5000);
  V_SESSAO_ATIVA               varchar2(1);
  V_LIMPAROBS                  varchar2(1);
  V_REDUCAOISENTA              varchar2(1);
  V_SQLERRO                    varchar2(500);
  V_CODFISCALOUTRASDESP        integer;
  V_CODFISCALINTEROUTRASDESP   integer;
  V_FRETENAOTRIBCOMOOUTRAS     varchar2(1);
  V_TIPOALIQOUTRASDESP         varchar2(1);
  V_ALIQICMOUTRASDESP          number;
  V_ALIQICMINTEROUTRASDESP     number;
  V_PERCICMFRETE               number;
  V_CODFISCALFRETE             number;
  V_PERCICMINTERFRETE          number;
  V_CODFISCALINTERFRETE        number;
  V_LIMPARBASECALCENTRADA      varchar2(1);
  V_GERAR_REFERENCIA_MANIFESTO varchar2(1);
  V_UFFILIAL                   varchar2(2);
  V_INDUSTRIA                  varchar2(1);
  V_NAOGERAR_IPI_VLOUTRAS      varchar(1);
  V_NAOGERAR_ST_VLOUTRAS       varchar(1);
  V_TRIBUTAFRETERATEADO        varchar(1);
  V_TAMANHO_OBS                number;
  V_IPIVLCONTSEMCREDITO        varchar2(1);
  V_DATA_INICIO_NFE20          date := TO_DATE('01/04/2011', 'DD/MM/YYYY');
  V_VALIDACAOLIVRO exception;
  V_VALIDA_VALOR_OUTRAS_IPI    varchar(1);
  V_CONTADORREGISTRO NUMBER;
  V_QUANTIDADECOMMIT NUMBER;
  V_DESTACAR_ICMS_DEVOL_TV13   varchar2(1);
  V_QTDNF_NO_PERIODO number;
  V_NF_CONTABILIZADA number;
  V_VALIDA_NF_CONTABILIZADA varchar2(1);
  V_NUMNOTA    number;
  ---------------------------------------------------------------------------------
  cursor C_NOTAS_NF(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
  -- 01 - NOTAS FISCAIS DE COMPRA COM ITENS (NF CONVENCIONAL)
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS,0) = 100) THEN
             0
           ELSE
             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
           END AS PERCICM,
           ----------------------------------------------------------------
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS,0) = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0), 2))
           END AS VLBASE,
           ----------------------------------------------------------------
           CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS,0) = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.BASEICMS, 0), 0), 2))
           END AS VLBASENAOTRIB,
           ----------------------------------------------------------------
           SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0, B.QTCONT *
                             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', GREATEST(NVL(B.PUNITCONT, 0) -
                                              NVL(B.VLDESCONTO, 0) -
                                              NVL(B.BASEICMS, 0), 0), 0)), 2)) VLBASE_REDUCAO,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(NVL(A.VLFRETE, 0), 0, 0, DECODE(NVL((select UTILIZAFRETECALCICMS
                                    from PCPEDIDO
                                   where NUMPED =
                                         B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, NVL(B.VLFRETE, 0)))) VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(NVL(A.VLFRETE, 0), 0, 0, DECODE(NVL((select UTILIZAFRETECALCICMS
                                               from PCPEDIDO
                                              where NUMPED =
                                                    B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, case
                                            when (NVL(B.BASEICMS, 0) = 0) or (B.GERAICMSLIVROFISCAL = 'N') then
                                             0
                                            else
                                             NVL(B.VLFRETE, 0)
                                          end))) VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           DECODE(max(NVL((select UTILIZAFRETECALCICMS
                            from PCPEDIDO
                           where NUMPED = B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N')), 'S', 0, A.VLFRETE) VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           DECODE(max(NVL(B.CODFISCALFRETEENT, 0)), 0, 'N', 'S') TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           DECODE(max(NVL(B.CODFISCALOUTRASDESPENT, 0)), 0, 'N', 'S') TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(NVL(A.VLOUTRAS, 0), 0, 0, DECODE(NVL((select UTILIZAOUTRASDESPCALCICMS
                                    from PCPEDIDO
                                   where NUMPED =
                                         B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, NVL(B.VLOUTRASDESP, 0)))) VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(NVL(A.VLOUTRAS, 0), 0, 0, DECODE(NVL((select UTILIZAOUTRASDESPCALCICMS
                                               from PCPEDIDO
                                              where NUMPED =
                                                    B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, case
                                            when (NVL(B.BASEICMS, 0) = 0) or (B.GERAICMSLIVROFISCAL = 'N') then
                                             0
                                            else
                                             NVL(B.VLOUTRASDESP, 0)
                                          end))) VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           DECODE(max(NVL((select UTILIZAOUTRASDESPCALCICMS
                            from PCPEDIDO
                           where NUMPED = B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N')), 'S', 0, DECODE(max(NVL(B.CODFISCALOUTRASDESPENT, 0)), 0, DECODE(max(B.CODOPER), 'ET', 0, ROUND(sum(B.QTCONT *
                                             (NVL(B.VLOUTRASDESP, 0) -
                                             NVL(B.VLACRESCIMOPF, 0))), 2)), 0)) VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           DECODE(max(NVL((select UTILIZAOUTRASDESPCALCICMS
                            from PCPEDIDO
                           where NUMPED = B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N')), 'S', 0, DECODE(max(B.CODOPER), 'ET', A.VLOUTRAS, DECODE(max(NVL(B.CODFISCALOUTRASDESPENT, 0)), 0, 0, A.VLOUTRAS))) VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'NF', B.ROWID,'', a.chavenfe),0)) VLICMS,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * case
                       when (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                            (NVL(B.BASEICMS, 0) <= 0) or (NVL(B.PERCICM, 0) <= 0) then
                        (NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100)
                       else
                        0
                     end, 2)) VLICMSNAOTRIB, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
            GREATEST((SUM(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                  FROM PCDESTSITTRIBUT
                                                  WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                 NOT EXISTS (SELECT 1
                                             FROM PCCFOPEXCDESTSITTRIBUT CED
                                             WHERE CED.CODFISCAL = B.CODFISCAL
                                               AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                                 (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                  FROM PCDESTSITTRIBUT
                                                  WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                 EXISTS (SELECT 1
                                         FROM PCCFOPEXCDESTSITTRIBUT CED
                                         WHERE CED.CODFISCAL = B.CODFISCAL
                                           AND CED.SITTRIBUT = B.SITTRIBUT)) THEN

                                                ROUND(B.QTCONT * B.PUNITCONT,2) -
                                                ROUND(B.QTCONT * NVL(B.VLDESCONTO, 0),2) -
                                                ROUND(B.QTCONT * NVL(B.VLSUFRAMA, 0),2 ) +

                                      DECODE(NVL(A.VLOUTRAS, 0), 0, 0,
                                             DECODE(NVL((SELECT UTILIZAOUTRASDESPCALCICMS
                                                         FROM PCPEDIDO
                                                         WHERE NUMPED = B.NUMPED
                                                           AND PCPEDIDO.CODFILIAL = PCODFILIAL
                                                           AND ROWNUM = 1), 'S'), 'S',ROUND(B.QTCONT * NVL(B.VLOUTRASDESP, 0),2), 0)) +
                                      DECODE(NVL(A.VLFRETE, 0), 0, 0,
                                             DECODE(NVL((SELECT UTILIZAFRETECALCICMS
                                                         FROM PCPEDIDO
                                                         WHERE NUMPED = B.NUMPED
                                                           AND PCPEDIDO.CODFILIAL = PCODFILIAL
                                                           AND ROWNUM = 1), 'S'), 'S', ROUND(B.QTCONT * NVL(B.VLFRETE, 0),2), 0))
                   ELSE
                      0
                   END) -
            SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                      FROM PCDESTSITTRIBUT
                                      WHERE NVL(VLISENTAS, 'N') = 'S') AND
                     NOT EXISTS (SELECT 1
                                 FROM PCCFOPEXCDESTSITTRIBUT CED
                                 WHERE CED.CODFISCAL = B.CODFISCAL
                                   AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                     (B.SITTRIBUT IN (SELECT SITTRIBUT
                                      FROM PCDESTSITTRIBUT
                                      WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                     EXISTS (SELECT 1
                             FROM PCCFOPEXCDESTSITTRIBUT CED
                             WHERE CED.CODFISCAL = B.CODFISCAL
                               AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
              B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0) +
              ROUND(B.QTCONT * NVL(MC.VLICMSDESONERACAO,0), 2)
           ELSE
              0
           END, 2))), 0) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           SUM(ROUND(B.QTCONT * B.PUNITCONT, 2) +
               ROUND(B.QTCONT * NVL(B.VLOUTROS,0), 2) -
               ROUND(B.QTCONT * NVL(B.VLDESCONTO,0), 2) -
               ROUND(B.QTCONT * NVL(MC.VLICMSDESONERACAO,0), 2) -
               ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0), 2) +
               DECODE(A.CHAVENFE, NULL, 0, ROUND(B.QTCONT * NVL(B.VLFRETE,0), 2) + ROUND(B.QTCONT * NVL(B.VLOUTRASDESP,0), 2)) +
               ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2) +
               ROUND(B.QTCONT * NVL(B.ST, 0), 2) +
               ROUND(B.QTCONT * DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, NVL(MC.VLFECP,0)), 2)) VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           sum(round(B.QTCONT * B.BASEICST,2)) VLBASEST,
           ----------------------------------------------------------------
           sum(ROUND(NVL(B.ST,0) * B.QTCONT, 2)) VLST,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLBASEIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLBASEIPI, 0), 0))) VLBASEIPI,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLIPI, 0), 0))) VLIPI,
           ----------------------------------------------------------------
           DECODE(NVL(B.CALCCREDIPI,'N'),'N',0,NVL(B.PERCIPI, 0))  PERCIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) else 0 end) VLBASEISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) end) VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', B.QTCONT *
                                  NVL(B.VLIPI, 0), 0))
                 else
                  0
               end) VLISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N',
                                       ROUND(B.QTCONT * NVL(B.VLIPI,0),2), 0))
               end) VLOUTRASIPI,
           ----------------------------------------------------------------
           ROUND(sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCREDPIS),2)), 2) VLPIS,
           ------------------------------------------------------------------

           ROUND(sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT *
                             B.VLCREDCOFINS),2)), 2) VLCOFINS,
           ----------------------------------------------------------------
           sum(round(B.QTCONT * NVL(B.VLBASESTFORANF, 0),2)) VLBASESTFORANF,
           ----------------------------------------------------------------
           sum(round(B.QTCONT * NVL(B.VLDESPADICIONAL, 0),2)) VLSTFORANF,
           ----------------------------------------------------------------
           B.ALIQUOTATIS,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '41', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '20', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '50', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.ST, 0)) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           -----------------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(B.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END VLBASEPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE ROUND(SUM(B.QTCONT * NVL(B.VLCREDPRESUMIDO,0)),2) END AS VLCREDPRESUMIDO,
    ----------------------------------------------------------------
           A.SITUACAONFE,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.PERCIMPPRODUTORURAL,0) * B.QTCONT, 2)) PERCIMPPRODUTORRURAL,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.VLDIFALIQUOTAS,0) * B.QTCONT, 2)) VLDIFALIQUOTA,
    ----------------------------------------------------------------
           0 AS VLCREDITO_CIAP,
           SUM(ROUND(B.QTCONT * MC.VLOUTROSCUSTOSCUSTO,2)) VLOUTROSCUSTOSCUSTO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLICMSANTECIPADO,0),2)) VLICMSANTECIPADO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIMPPRODUTORURAL,0),2)) VLIMPPRODUTORURAL,
           SUM(ROUND(B.QTCONT * NVL(MC.VLOUTROSCUSTOS,0),2)) VLOUTROSCUSTOS,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2))) VLACRESCIMOFUNCEP,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECP,0),2)) VLFECP,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESPFORANF,0),2)) VLDESPFORANF,
           SUM(ROUND(B.QTCONT * NVL(B.VLFRETECONHEC,0),2)) VLFRETECONHEC,
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(MC.PERACRESCIMOFUNCEP,0)) PERACRESCIMOFUNCEP,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2))) VLBASEFCPICMS,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           NVL(MC.ALIQICMSFECP, 0) ALIQICMSFECP,
           0 PERCREDBASEPISCOFINSFRETE,
           SUM(ROUND(B.QTCONT * NVL(B.STBCR,0),2)) VLSTBCR,
           SUM(ROUND(B.QTCONT * NVL(B.VLICMSBCR,0),2)) VLICMSBCR,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECPSTGUIA,0),2)) VLFECPSTGUIA,
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0),2)) ELSE 0 END VLSUFRAMA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.PUNITCONT,0),2)) ELSE 0 END VLBASESUFRAMA
      from PCNFENT      A,
           PCMOV        B,
           PCFORNEC     F,
           PCCFO        CF,
           PCMOVCOMPLE  MC,
           PCPRODUT     P,
           PCPRODFILIAL PF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT
       and A.NUMNOTA = B.NUMNOTA
       and B.CODPROD = PF.CODPROD(+)
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.NUMTRANSITEM = MC.NUMTRANSITEM
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = F.CODFORNEC
       and P.CODPROD = B.CODPROD
       and A.TIPODESCARGA not in ('6', '8', 'F', 'N','P', 'C', 'T')
       and ( nvl(a.notadupliquesvc,'N') = 'N')
       and (B.QTCONT > 0 or NVL(A.SITUACAONFE, '0') in ('101', '102'))
       and (A.CHAVENFE is null or NVL(A.GERANFVENDA, 'N') = 'N')
       and B.STATUS in ('A', 'AB')
       and A.ESPECIE in ('NF', 'DA', 'NS') --ADICIONADO NS PARA ATUALIAR A CONTA CONTABIL, PORÉM, FOI CRIADA CONDICIONAL PARA NÃO GERAR O LIVRO PARA ESSA ESPECIE
       --and A.DTENT >= (SELECT MIN(DTENT) FROM PCNFENT)
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              CF.CODOPER,
              A.CHAVENFE,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              F.FORNECEDOR,
              F.CGC,
              F.IE,
              F.ESTADO,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.VLTOTAL,
              A.VLOUTRAS,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(MC.PERDIFEREIMENTOICMS,0),
              NVL(B.PERCICM, 0),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              DECODE(NVL(B.CALCCREDIPI,'N'),'N',0,NVL(B.PERCIPI, 0)),
              B.ALIQUOTATIS,
              A.NFENTREGAFUTURA,
              B.CODOPER,
              B.DTCANCEL,
              A.SITUACAONFE,
              DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(MC.PERACRESCIMOFUNCEP,0)),
              NVL(MC.ALIQICMSFECP, 0)
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA
              ;

cursor C_NOTAS_NFE(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 02 - NOTAS FISCAIS DE COMPRA COM ITENS (NF-e)
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           case
             when (A.CHAVENFE is not null) and
                  ((A.GERANFDEVCLI = 'S') or (A.GERANFVENDA = 'S')) then
              'S'
             else
              'N'
           end NFE_PROPRIA,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
           END PERCICM,
           ----------------------------------------------------------------
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN SUM(NVL(XML.VBC,0)) > 0 THEN 
                SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'),'S', XML.VBC,0)) 
           ELSE 
             (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                   0
              ELSE
                   sum(DECODE(B.CODOPER, 'ET', B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0),
                                         B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0)))
            END)
            END VLBASE,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             ROUND(sum(B.QTCONT *
                       DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.BASEICMS, 0), 0)), 2)
           END AS VLBASENAOTRIB,
           ----------------------------------------------------------------
           ROUND(sum(DECODE(NVL(B.BASEICMS, 0), 0, 0, B.QTCONT *
                             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', GREATEST(NVL(B.PUNITCONT, 0) -
                                              NVL(B.VLDESCONTO, 0) -
                                              NVL(B.BASEICMS, 0), 0), 0))), 2) VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           A.VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           A.VLOUTRAS VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           0 PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
--           sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'NFE', B.ROWID,'', a.chavenfe),0)) VLICMS,
           
           CASE WHEN SUM(NVL(XML.VICMS,0)) > 0 THEN 
                SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'),'S', XML.VICMS,0)) 
           ELSE 
           (sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'NFE', B.ROWID,'', a.chavenfe),0))) END VLICMS,
           
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * case
                       when (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                            (NVL(B.BASEICMS, 0) <= 0) or (NVL(B.PERCICM, 0) <= 0) then
                        (NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100)
                       else
                        0
                     end, 2)) VLICMSNAOTRIB,
           ----------------------------------------------------------------
           GREATEST((SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                         FROM PCDESTSITTRIBUT
                                                         WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                          NOT EXISTS (SELECT 1
                                                      FROM PCCFOPEXCDESTSITTRIBUT CED
                                                      WHERE CED.CODFISCAL = B.CODFISCAL
                                                        AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                                         (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                          EXISTS (SELECT 1
                                                  FROM PCCFOPEXCDESTSITTRIBUT CED
                                                  WHERE CED.CODFISCAL = B.CODFISCAL
                                                    AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                                  B.QTCONT * (B.PUNITCONT - NVL(B.VLDESCONTO, 0) - NVL(B.VLSUFRAMA, 0) +
                                              DECODE(NVL(A.VLOUTRAS, 0), 0, 0,
                                                     DECODE(NVL((SELECT UTILIZAOUTRASDESPCALCICMS
                                                                 FROM PCPEDIDO
                                                                 WHERE NUMPED = B.NUMPED
                                                                   AND PCPEDIDO.CODFILIAL = PCODFILIAL
                                                                   AND ROWNUM = 1), 'S'), 'S', NVL(B.VLOUTRASDESP, 0), 0)) +
                                                     DECODE(NVL(A.VLFRETE, 0), 0, 0,
                                                            DECODE(NVL((SELECT UTILIZAFRETECALCICMS
                                                                        FROM PCPEDIDO
                                                                        WHERE NUMPED = B.NUMPED
                                                                          AND PCPEDIDO.CODFILIAL = PCODFILIAL
                                                                          AND ROWNUM = 1), 'S'), 'S', NVL(B.VLFRETE, 0), 0)))
                               ELSE
                                  0
                               END, 2)) -
                     SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                          NOT EXISTS (SELECT 1
                                                      FROM PCCFOPEXCDESTSITTRIBUT CED
                                                      WHERE CED.CODFISCAL = B.CODFISCAL
                                                        AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                                         (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                          EXISTS (SELECT 1
                                                  FROM PCCFOPEXCDESTSITTRIBUT CED
                                                  WHERE CED.CODFISCAL = B.CODFISCAL
                                                    AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                                  B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0)
                               ELSE
                                  0
                               END, 2))), 0) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           SUM(ROUND(B.QTCONT * B.PUNITCONT, 2) +
               ROUND(B.QTCONT * NVL(B.VLOUTROS,0), 2) -
               ROUND(B.QTCONT * NVL(B.VLDESCONTO,0), 2) -
               ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0), 2) +
               DECODE(A.CHAVENFE, NULL, 0, ROUND(B.QTCONT * NVL(B.VLFRETE,0), 2) + ROUND(B.QTCONT * NVL(B.VLOUTRASDESP,0), 2)) +
               ROUND(B.QTCONT * NVL(B.VLIPI,0), 2) +
               ROUND(B.QTCONT * NVL(B.ST,0), 2) +
               ROUND(B.QTCONT * DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, NVL(MC.VLFECP,0)), 2)) VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           sum(round(B.QTCONT * B.BASEICST,2)) VLBASEST,
           ----------------------------------------------------------------
           sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLBASEIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLBASEIPI, 0), 0))) VLBASEIPI,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLIPI, 0), 0))) VLIPI,
           ----------------------------------------------------------------
           NVL(B.PERCIPI, 0) PERCIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) else 0 end) VLBASEISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) end) VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', B.QTCONT *
                                  NVL(B.VLIPI, 0), 0))
                 else
                  0
               end) VLISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N',
                                       ROUND(B.QTCONT * NVL(B.VLIPI,0),2), 0))
               end) VLOUTRASIPI,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCREDPIS), 2)) VLPIS,
           ------------------------------------------------------------------

           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT *
                             B.VLCREDCOFINS), 2)) VLCOFINS,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLBASESTFORANF, 0)) VLBASESTFORANF,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLDESPADICIONAL, 0)) VLSTFORANF,
           ----------------------------------------------------------------
           B.ALIQUOTATIS,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '41', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '20', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '50', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.ST, 0)) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           -------------------------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(B.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END as VLBASEPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE ROUND(SUM(B.QTCONT * NVL(B.VLCREDPRESUMIDO,0)),2) END as VLCREDPRESUMIDO,
    ----------------------------------------------------------------
           A.SITUACAONFE,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.PERCIMPPRODUTORURAL,0) * B.QTCONT, 2)) PERCIMPPRODUTORRURAL,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.VLDIFALIQUOTAS,0) * B.QTCONT, 2)) VLDIFALIQUOTA,
    ----------------------------------------------------------------
           0 AS VLCREDITO_CIAP,
           SUM(ROUND(B.QTCONT * MC.VLOUTROSCUSTOSCUSTO,2)) VLOUTROSCUSTOSCUSTO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLICMSANTECIPADO,0),2)) VLICMSANTECIPADO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIMPPRODUTORURAL,0),2)) VLIMPPRODUTORURAL,
           SUM(ROUND(B.QTCONT * NVL(MC.VLOUTROSCUSTOS,0),2)) VLOUTROSCUSTOS,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2))) VLACRESCIMOFUNCEP,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECP,0),2)) VLFECP,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESPFORANF,0),2)) VLDESPFORANF,
           SUM(ROUND(B.QTCONT * NVL(B.VLFRETECONHEC,0),2)) VLFRETECONHEC,
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(MC.PERACRESCIMOFUNCEP,0)) PERACRESCIMOFUNCEP,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2))) VLBASEFCPICMS,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           NVL(MC.ALIQICMSFECP, 0) ALIQICMSFECP,
           0 PERCREDBASEPISCOFINSFRETE,
           SUM(ROUND(B.QTCONT * NVL(B.STBCR,0),2)) VLSTBCR,
           SUM(ROUND(B.QTCONT * NVL(B.VLICMSBCR,0),2)) VLICMSBCR,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECPSTGUIA,0),2)) VLFECPSTGUIA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0),2)) ELSE 0 END VLSUFRAMA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.PUNITCONT,0),2)) ELSE 0 END VLBASESUFRAMA
      from PCNFENT      A,
           PCMOV        B,
           PCFORNEC     F,
           PCCFO        CF,
           PCMOVCOMPLE  MC,
           PCPRODUT     P,
           PCPRODFILIAL PF, 
           PCDADOSXML XML
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
     and NVL(B.CODFILIALNF, B.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT
       and A.NUMNOTA = B.NUMNOTA
       and B.CODPROD = PF.CODPROD(+)
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.NUMTRANSITEM = MC.NUMTRANSITEM
       and B.NUMTRANSITEM = XML.NUMTRANSITEM(+)
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = F.CODFORNEC
       and P.CODPROD = B.CODPROD
       and A.TIPODESCARGA not in ('6', '8', 'F', 'N','P', 'C', 'T')
       and (B.QTCONT > 0 or NVL(A.SITUACAONFE, '0') in ('101', '102'))
       and (A.CHAVENFE is not null and A.GERANFVENDA = 'S')
       and B.STATUS in ('A', 'AB')
       and A.ESPECIE in ('NF', 'DA')
       --and A.DTENT >= (SELECT MIN(DTENT) FROM PCNFENT)
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              CF.CODOPER,
              A.CHAVENFE,
              A.GERANFVENDA,
              A.GERANFDEVCLI,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              F.FORNECEDOR,
              F.CGC,
              F.IE,
              F.ESTADO,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.VLTOTAL,
              A.VLOUTRAS,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              MC.PERDIFEREIMENTOICMS,
              NVL(B.PERCICM, 0),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              NVL(B.PERCIPI, 0),
              B.ALIQUOTATIS,
              A.NFENTREGAFUTURA,
              B.DTCANCEL,
              A.SITUACAONFE,
              DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(MC.PERACRESCIMOFUNCEP,0)),
              NVL(MC.ALIQICMSFECP, 0)
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA
              ;

cursor C_NOTAS_IMPORTACAO(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 03 - NOTAS FISCAIS DE IMPORTACAO
    ----------------------------------------------------------------
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, A.CODFORNEC) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           CASE WHEN (NVL(B.PERCDESCICMSDIF, MC.PERDIFEREIMENTOICMS) >= 100) THEN
             0
           ELSE
             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
           END PERCICM,
           ----------------------------------------------------------------
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN (NVL(B.PERCDESCICMSDIF, MC.PERDIFEREIMENTOICMS) >= 100) THEN
             0
           ELSE
             ROUND(sum(B.QTCONT *
                       DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',(NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0)), 2)
           END VLBASE,
           ----------------------------------------------------------------
           CASE WHEN (NVL(B.PERCDESCICMSDIF, MC.PERDIFEREIMENTOICMS) >= 100)  THEN
             0
           ELSE
             ROUND(sum(B.QTCONT *
                     DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.BASEICMS, 0), 0)), 2)
           END AS VLBASENAOTRIB,
           ----------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'IMP', B.ROWID,'', a.chavenfe),0)) VLICMS,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.PERCICM, 0), 0, 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', ROUND(B.QTCONT *
                                     DECODE(NVL(MC.VLICMS, 0), 0, NVL(B.VLCREDICMS, 0), MC.VLICMS), 2), 0))) VLICMSNAOTRIB,
           ----------------------------------------------------------------
           SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                FROM PCDESTSITTRIBUT
                                                WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                NOT EXISTS (SELECT 1
                                            FROM PCCFOPEXCDESTSITTRIBUT CED
                                            WHERE CED.CODFISCAL = B.CODFISCAL
                                              AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                               (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                FROM PCDESTSITTRIBUT
                                                WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                EXISTS (SELECT 1
                                        FROM PCCFOPEXCDESTSITTRIBUT CED
                                        WHERE CED.CODFISCAL = B.CODFISCAL
                                          AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                        GREATEST((B.QTCONT * (B.PUNITCONT - NVL(B.VLDESCONTO, 0))) -
                                 (B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0)), 0)
                     ELSE
                        0
                     END, 2)) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           SUM(ROUND((B.QTCONT * B.PUNITCONT),2)) VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           sum( ROUND(B.QTCONT * B.BASEICST,2)) VLBASEST,
           ----------------------------------------------------------------
           sum( ROUND(B.QTCONT * B.ST,2)) VLST,
           ----------------------------------------------------------------
           sum(DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLBASEIPI, 0),2), 0)) VLBASEIPI,
           ----------------------------------------------------------------
           sum(DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLIPI, 0), 2), 0)) VLIPI,
           ----------------------------------------------------------------
           NVL(B.PERCIPI, 0) PERCIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) else 0 end) VLBASEISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) end) VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', B.QTCONT *
                                  NVL(B.VLIPI, 0), 0))
                 else
                  0
               end) VLISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N',
                                       ROUND(B.QTCONT * NVL(B.VLIPI,0),2), 0))
               end) VLOUTRASIPI,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCREDPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT *
                             B.VLCREDCOFINS), 2)) VLCOFINS,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLBASESTFORANF, 0)) VLBASESTFORANF,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLDESPADICIONAL, 0)) VLSTFORANF,
           ----------------------------------------------------------------
           B.ALIQUOTATIS,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '41', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '20', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '50', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.ST, 0)) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           --------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(B.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END as VLBASEPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE ROUND(SUM(B.QTCONT * NVL(B.VLCREDPRESUMIDO,0)),2) END as VLCREDPRESUMIDO,
    ----------------------------------------------------------------
           A.SITUACAONFE,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.PERCIMPPRODUTORURAL,0) * B.QTCONT, 2)) PERCIMPPRODUTORRURAL,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.VLDIFALIQUOTAS,0) * B.QTCONT, 2)) VLDIFALIQUOTA,
    ----------------------------------------------------------------
           0 AS VLCREDITO_CIAP,
           SUM(ROUND(B.QTCONT * MC.VLOUTROSCUSTOSCUSTO,2)) VLOUTROSCUSTOSCUSTO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLICMSANTECIPADO,0),2)) VLICMSANTECIPADO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIMPPRODUTORURAL,0),2)) VLIMPPRODUTORURAL ,
           SUM(ROUND(B.QTCONT * NVL(MC.VLOUTROSCUSTOS,0),2)) VLOUTROSCUSTOS,
           0 VLACRESCIMOFUNCEP,
           0 VLFECP,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESPFORANF,0),2)) VLDESPFORANF,
           SUM(ROUND(B.QTCONT * NVL(B.VLFRETECONHEC,0),2)) VLFRETECONHEC,
           0 PERACRESCIMOFUNCEP,
           0 VLBASEFCPICMS,
           0 VLBASEFCPST,
           0 ALIQICMSFECP,
           0 PERCREDBASEPISCOFINSFRETE,
           SUM(ROUND(B.QTCONT * NVL(B.STBCR,0),2)) VLSTBCR,
           SUM(ROUND(B.QTCONT * NVL(B.VLICMSBCR,0),2)) VLICMSBCR,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECPSTGUIA,0),2)) VLFECPSTGUIA,
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0),2)) ELSE 0 END VLSUFRAMA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.PUNITCONT,0),2)) ELSE 0 END VLBASESUFRAMA
      from PCNFENT      A,
           PCMOV        B,
           PCFORNEC     F,
           PCCFO        CF,
           PCPRODUT     P,
           PCMOVCOMPLE  MC,
           PCPRODFILIAL PF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT
       and A.NUMNOTA = B.NUMNOTA
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, A.CODFORNEC) = F.CODFORNEC
       and P.CODPROD = B.CODPROD
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and A.TIPODESCARGA in ('F', 'N','P')
       and B.QTCONT > 0
       and B.STATUS in ('A', 'AB')
       and A.ESPECIE in ('NF', 'DA')
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              A.CHAVENFE,
              NVL(A.CODEXPORTADOR, A.CODFORNEC),
              F.FORNECEDOR,
              F.CGC,
              F.IE,
              F.ESTADO,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              CF.CODOPER,
              A.VLTOTAL,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              MC.PERDIFEREIMENTOICMS,
              NVL(B.PERCICM, 0),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              NVL(B.PERCIPI, 0),
              B.ALIQUOTATIS,
              A.NFENTREGAFUTURA,
              B.DTCANCEL,
              A.SITUACAONFE,
              B.PERCDESCICMSDIF
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA;

cursor C_NOTAS_DEVOLNF(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 04 - NOTAS FISCAIS DE DEVOLUCAO e COMODATO (NF CONVENCIONAL)
    ----------------------------------------------------------------
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.CLIENTE, D.CLIENTE)
                  else
                   C.CLIENTE
                end) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.CGCENT, D.CGC)
                  else
                   C.CGCENT
                end) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.IEENT, D.IE)
                  else
                   C.IEENT
                end) IE,
           ----------------------------------------------------------------
           NVL(A.UF, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, V_UFFILIAL, D.UF)
                  else
                   C.ESTENT
                end) UF,
           ----------------------------------------------------------------
           NVL(A.TIPOFJ, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.TIPOFJ, 'F')
                  else
                   C.TIPOFJ
                end) TIPOFJ,
           ----------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.CONSUMIDORFINAL, 'S')
                  else
                   C.CONSUMIDORFINAL
                end) CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
           END PERCICM,
           ----------------------------------------------------------------
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT *
                     CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                               (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                        0
                     ELSE
                        NVL(B.BASEICMS, 0)
                     END, 2))
           END VLBASE,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT *
                       CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                 (NVL(B.BASEICMS, 0) <= 0) or (NVL(B.PERCICM, 0) <= 0) THEN
                          NVL(B.BASEICMS, 0)
                       ELSE
                          0
                       END, 2))
           END AS VLBASENAOTRIB,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0, B.QTCONT *
                             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', GREATEST(NVL(B.PUNITCONT, 0) -
                                              NVL(B.VLIPI, 0) -
                                              NVL(B.ST, 0) -
                                              NVL(B.BASEICMS, 0), 0), 0)), 2)) VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           DECODE(sum(B.QTCONT * NVL(B.VLFRETE_RATEIO, 0)), 0, A.VLFRETE, 0) VLFRETE,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLFRETE_RATEIO, 0)) VLFRETE_RATEIO,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLFRETE_RATEIO, 0))) VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           ROUND(NVL(A.VLOUTRAS, 0) -
                 NVL((select sum(QTCONT * NVL(VLACRESCIMOPF, 0))
                       from PCMOV
                      where NUMTRANSENT = A.NUMTRANSENT
                        and NUMNOTA = A.NUMNOTA
                        and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_CODFILIAL
                        and QTCONT > 0
                        and DTCANCEL is null), 0), 2) VLOUTRASDESP,

           ----------------------------------------------------------------
           GREATEST(DECODE(NVL(A.PERBASEREDOUTRASDESP, 0), 0,
                           NVL((select sum(QTCONT * NVL(VLACRESCIMOPF, 0))
                                from PCMOV
                                where NUMTRANSENT = A.NUMTRANSENT
                                  and NUMNOTA = A.NUMNOTA
                                  AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_CODFILIAL
                                  and QTCONT > 0
                                  and DTCANCEL is null), 0),
                           (NVL(A.VLOUTRAS, 0) -
                            NVL((select sum(QTCONT * NVL(VLACRESCIMOPF, 0))
                                 from PCMOV
                                 where NUMTRANSENT = A.NUMTRANSENT
                                   and NUMNOTA = A.NUMNOTA
                                   AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_CODFILIAL
                                   and QTCONT > 0
                                   and DTCANCEL is null), 0)) *
                           A.PERBASEREDOUTRASDESP / 100), 0) VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'DEVNF', B.ROWID,'', a.chavenfe),0)) VLICMS,
           ----------------------------------------------------------------
           SUM(ROUND(B.QTCONT *
                     CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                               (NVL(B.BASEICMS, 0) <= 0) or (NVL(B.PERCICM, 0) <= 0) THEN
                        NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100
                     ELSE
                        0
                     END, 2)) VLICMSNAOTRIB,
           ----------------------------------------------------------------
           SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                FROM PCDESTSITTRIBUT
                                                WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                NOT EXISTS (SELECT 1
                                            FROM PCCFOPEXCDESTSITTRIBUT CED
                                            WHERE CED.CODFISCAL = B.CODFISCAL
                                              AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                               (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                FROM PCDESTSITTRIBUT
                                                WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                EXISTS (SELECT 1
                                        FROM PCCFOPEXCDESTSITTRIBUT CED
                                        WHERE CED.CODFISCAL = B.CODFISCAL
                                          AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                        GREATEST(ROUND((B.QTCONT * (B.PUNITCONT - NVL(B.ST, 0) - NVL(B.VLIPI, 0) + NVL(B.VLOUTROS,0) + NVL(B.VLFRETE,0) - NVL(B.VLACRESCIMOPF,0))),2) -
                                 ROUND((B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0)),2), 0)
                     ELSE
                        0
                     END, 2)) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           CASE
            WHEN A.ROTINACAD NOT LIKE '%1423%'
               THEN SUM(ROUND(
                             ROUND(NVL(B.QTCONT, 0) * NVL(B.PUNITCONT, 0), 2) - 
                             ROUND(NVL(B.QTCONT, 0) * NVL(B.VLIPI, 0), 2) - 
                             ROUND(NVL(B.QTCONT, 0) * NVL(B.ST, 0), 2) -
                             ROUND((NVL(B.QTCONT, 0)* NVL(MC.VLFECP, 0)), 2) +
                             
                             ROUND(NVL(B.QTCONT, 0)  * NVL(B.VLIPI, 0), 2) + 
                             ROUND(NVL(B.QTCONT, 0)  * NVL(B.ST, 0), 2) +
                             ROUND((NVL(B.QTCONT, 0) * NVL(MC.VLFECP, 0)), 2) +
                             (CASE
                              WHEN A.TIPODESCARGA IN('6', '8', 'T') THEN 0
                                ELSE ROUND(NVL(B.QTCONT,0) * NVL(B.VLOUTROS, 0), 2)
                              END) + 
                             DECODE(A.CHAVENFE, NULL, ROUND(NVL(B.QTCONT,0) * NVL(B.VLACRESCIMOPF, 0),2), 0)
                             ,2))
            ELSE SUM(ROUND(  ROUND(NVL(B.QTCONT, 0) * NVL(B.PUNITCONT, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(B.ST, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(B.VLIPI, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(B.VLFRETE, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(MC.VLFECP, 0), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(B.ST, 0)), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(B.VLIPI, 0)), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(B.VLOUTROS, 0)), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(MC.VLFECP, 0)), 2)
                         , 2))
           END VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * B.BASEICST,2)) VLBASEST,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * B.ST, 2)) VLST,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.PERCIPI, 0), 0, 0, ROUND(B.QTCONT *
                             NVL(B.VLBASEIPI, 0), 2))) VLBASEIPI,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2)) VLIPI,
           ----------------------------------------------------------------
           NVL(B.PERCIPI, 0) PERCIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) else 0 end) VLBASEISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) end) VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           0 VLISENTASIPI,
           ----------------------------------------------------------------
           0 VLOUTRASIPI,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCREDPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT *
                             B.VLCREDCOFINS), 2)) VLCOFINS,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLBASESTFORANF, 0)) VLBASESTFORANF,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLDESPADICIONAL, 0)) VLSTFORANF,
           ----------------------------------------------------------------
           B.ALIQUOTATIS,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(B.SITTRIBUT, '41', B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '20', GREATEST(B.PUNITCONT -
                                NVL(B.VLIPI, 0) -
                                NVL(B.ST, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', GREATEST(B.PUNITCONT -
                                NVL(B.VLIPI, 0) -
                                NVL(B.ST, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(B.SITTRIBUT, '50', B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.ST, 0)) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           --------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(B.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END as VLBASEPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE ROUND(SUM(B.QTCONT * NVL(B.VLCREDPRESUMIDO,0)),2) END as VLCREDPRESUMIDO,
    ----------------------------------------------------------------
           A.SITUACAONFE,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.PERCIMPPRODUTORURAL,0) * B.QTCONT, 2)) PERCIMPPRODUTORRURAL,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.VLDIFALIQUOTAS,0) * B.QTCONT, 2)) VLDIFALIQUOTA,
    ----------------------------------------------------------------
           0 AS VLCREDITO_CIAP,
           SUM(ROUND(B.QTCONT * MC.VLOUTROSCUSTOSCUSTO,2)) VLOUTROSCUSTOSCUSTO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLICMSANTECIPADO,0),2)) VLICMSANTECIPADO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIMPPRODUTORURAL,0),2)) VLIMPPRODUTORURAL,
           SUM(ROUND(B.QTCONT * NVL(MC.VLOUTROSCUSTOS,0),2)) VLOUTROSCUSTOS,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2)))) VLACRESCIMOFUNCEP,
           SUM(DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLFECP,0),2)  )) VLFECP,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESPFORANF,0),2)) VLDESPFORANF,
           SUM(ROUND(B.QTCONT * NVL(B.VLFRETECONHEC,0),2)) VLFRETECONHEC,
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP, 0))) PERACRESCIMOFUNCEP,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2))) VLBASEFCPICMS,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)) ALIQICMSFECP,
           0 PERCREDBASEPISCOFINSFRETE,
           SUM(ROUND(B.QTCONT * NVL(B.STBCR,0),2)) VLSTBCR,
           SUM(ROUND(B.QTCONT * NVL(B.VLICMSBCR,0),2)) VLICMSBCR,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECPSTGUIA,0),2)) VLFECPSTGUIA,
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0),2)) ELSE 0 END VLSUFRAMA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.PUNITCONT,0),2)) ELSE 0 END VLBASESUFRAMA
      from PCNFENT      A,
           PCMOV        B,
           PCMOVCOMPLE  MC,
           PCCLIENT     C,
           PCDEVCONSUM  D,
           PCCFO        CF,
           PCPRODUT     P,
           PCPRODFILIAL PF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
     and NVL(B.CODFILIALNF, B.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT
       and A.NUMNOTA = B.NUMNOTA
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       
       and CF.CODFISCAL = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = C.CODCLI(+)
       and A.NUMTRANSENT = D.NUMTRANSENT(+)
       and P.CODPROD = B.CODPROD
       and (A.TIPODESCARGA in ('6', '7', '8', 'C', 'T') or ((a.notadupliquesvc = 'S' and a.tipodescarga = '2')))
       and B.QTCONT > 0
       and ((A.CHAVENFE is null) or 
            ((a.notadupliquesvc = 'S' and a.tipodescarga = '2')))
       and B.STATUS in ('A', 'AB')
       and A.ESPECIE in ('NF', 'DA')
       and A.NUMTRANSENT > 0
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              A.CHAVENFE,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              D.NUMTRANSENT,
              C.CLIENTE,
              D.CLIENTE,
              C.CGCENT,
              D.CGC,
              C.IEENT,
              CF.CODOPER,
              D.IE,
              C.ESTENT,
              D.UF,
              C.TIPOFJ,
              C.CONSUMIDORFINAL,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.TIPOFJ,
              A.CONSUMIDORFINAL,
              A.VLTOTAL,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              MC.PERDIFEREIMENTOICMS,
              NVL(B.PERCICM, 0),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              NVL(B.PERCIPI, 0),
              B.ALIQUOTATIS,
              A.NFENTREGAFUTURA,
              B.DTCANCEL,
              A.SITUACAONFE,
              DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP, 0))),
              DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)),
              A.ROTINACAD
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA
              ;

cursor C_NOTAS_DEVOLNFE(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 05 - NOTAS FISCAIS DE DEVOLUCAO e COMODATO (NF-e)
    ----------------------------------------------------------------
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.CLIENTE, D.CLIENTE)
                  else
                   C.CLIENTE
                end) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.CGCENT, D.CGC)
                  else
                   C.CGCENT
                end) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.IEENT, D.IE)
                  else
                   C.IEENT
                end) IE,
           ----------------------------------------------------------------
           NVL(A.UF, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, V_UFFILIAL, D.UF)
                  else
                   C.ESTENT
                end) UF,
           ----------------------------------------------------------------
           NVL(A.TIPOFJ, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.TIPOFJ, 'F')
                  else
                   C.TIPOFJ
                end) TIPOFJ,
           ----------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, case
                  when NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) in
                       (1, 2, 3) then
                   DECODE(D.NUMTRANSENT, null, C.CONSUMIDORFINAL, 'S')
                  else
                   C.CONSUMIDORFINAL
                end) CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           case
             when (A.CHAVENFE is not null) and
                  ((A.GERANFDEVCLI = 'S') or (A.GERANFVENDA = 'S')) then
              'S'
             else
              'N'
           end NFE_PROPRIA,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
           END PERCICM,
           ----------------------------------------------------------------
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT *
                     CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                               (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                        0
                     ELSE
                        (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0))
                     END, 2))
           END VLBASE,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT *
                       CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                 (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                          (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0))
                       ELSE
                          0
                       END, 2))
           END AS VLBASENAOTRIB,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0, B.QTCONT *
                             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', GREATEST(NVL(B.PUNITCONT, 0) -
                                              NVL(B.VLIPI, 0) -
                                              NVL(B.ST, 0) -
                                              NVL(B.BASEICMS, 0), 0), 0)), 2)) VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           SUM(B.VLFRETE * QTCONT) VLFRETE,          
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           A.VLOUTRAS VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           0 PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'DEVNFE', B.ROWID,'', a.chavenfe),0)) VLICMS,
           ----------------------------------------------------------------
           SUM(ROUND(B.QTCONT *
                     CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                               (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                        (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)) * NVL(B.PERCICM, 0) / 100
                     ELSE
                        0
                     END, 2)) VLICMSNAOTRIB,
           ----------------------------------------------------------------
           SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                FROM PCDESTSITTRIBUT
                                                WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                NOT EXISTS (SELECT 1
                                            FROM PCCFOPEXCDESTSITTRIBUT CED
                                            WHERE CED.CODFISCAL = B.CODFISCAL
                                              AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                               (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                FROM PCDESTSITTRIBUT
                                                WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                EXISTS (SELECT 1
                                        FROM PCCFOPEXCDESTSITTRIBUT CED
                                        WHERE CED.CODFISCAL = B.CODFISCAL
                                          AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                        GREATEST(ROUND(ROUND(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                                       ROUND((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                                       DECODE(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                                       ROUND((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2),2) -
                                       ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) +
                                             NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)), 0),2),0)
                     ELSE
                        0
                     END, 2)) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           CASE
            WHEN A.ROTINACAD NOT LIKE '%1423%'
               THEN SUM(ROUND(
                             ROUND(NVL(B.QTCONT, 0) * NVL(B.PUNITCONT, 0), 2) - 
                             ROUND(NVL(B.QTCONT, 0) * NVL(B.VLIPI, 0), 2) - 
                             ROUND(NVL(B.QTCONT, 0) * NVL(B.ST, 0), 2) -
                             ROUND((NVL(B.QTCONT, 0)* NVL(MC.VLFECP, 0)), 2) +
                             
                             ROUND(NVL(B.QTCONT, 0)  * NVL(B.VLIPI, 0), 2) + 
                             ROUND(NVL(B.QTCONT, 0)  * NVL(B.ST, 0), 2) +
                             ROUND((NVL(B.QTCONT, 0) * NVL(MC.VLFECP, 0)), 2) +
                             (CASE
                              WHEN A.TIPODESCARGA IN('6', '8', 'T') THEN 0
                                ELSE ROUND(NVL(B.QTCONT,0) * NVL(B.VLOUTROS, 0), 2)
                              END) + 
                             DECODE(A.CHAVENFE, NULL, ROUND(NVL(B.QTCONT,0) * NVL(B.VLACRESCIMOPF, 0),2), 0)
                             ,2))
            ELSE SUM(ROUND(  ROUND(NVL(B.QTCONT, 0) * NVL(B.PUNITCONT, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(B.ST, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(B.VLIPI, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(B.VLFRETE, 0), 2)
                           - ROUND(NVL(B.QTCONT, 0) * NVL(MC.VLFECP, 0), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(B.ST, 0)), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(B.VLIPI, 0)), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(B.VLOUTROS, 0)), 2)
                           + ROUND((NVL(B.QTCONT, 0) * NVL(MC.VLFECP, 0)), 2)
                         , 2))
           END VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * B.BASEICST,2)) VLBASEST,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * B.ST, 2)) VLST,
           ----------------------------------------------------------------
          sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLBASEIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLBASEIPI, 0), 0))) VLBASEIPI,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLIPI, 0), 0))) VLIPI,
           ----------------------------------------------------------------
           NVL(B.PERCIPI, 0) PERCIPI,
           ----------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ----------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ----------------------------------------------------------------
          sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', B.QTCONT *
                                  NVL(B.VLIPI, 0), 0))
                 else
                  0
               end) VLISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N',
                                       ROUND(B.QTCONT * NVL(B.VLIPI,0),2), 0))
               end) VLOUTRASIPI,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCREDPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT *
                             B.VLCREDCOFINS), 2)) VLCOFINS,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLBASESTFORANF, 0)) VLBASESTFORANF,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLDESPADICIONAL, 0)) VLSTFORANF,
           ----------------------------------------------------------------
           B.ALIQUOTATIS,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(B.SITTRIBUT, '41', B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '20', GREATEST(B.PUNITCONT -
                                NVL(B.VLIPI, 0) -
                                NVL(B.ST, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', GREATEST(B.PUNITCONT -
                                NVL(B.VLIPI, 0) -
                                NVL(B.ST, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(B.SITTRIBUT, '50', B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.ST, 0)) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           ----------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(B.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END as VLBASEPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE ROUND(SUM(B.QTCONT * NVL(B.VLCREDPRESUMIDO,0)),2) END as VLCREDPRESUMIDO,
    ----------------------------------------------------------------
           A.SITUACAONFE,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.PERCIMPPRODUTORURAL,0) * B.QTCONT, 2)) PERCIMPPRODUTORRURAL,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.VLDIFALIQUOTAS,0) * B.QTCONT, 2)) VLDIFALIQUOTA,
    ----------------------------------------------------------------
           0 AS VLCREDITO_CIAP,
           SUM(ROUND(B.QTCONT * MC.VLOUTROSCUSTOSCUSTO,2)) VLOUTROSCUSTOSCUSTO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLICMSANTECIPADO,0),2)) VLICMSANTECIPADO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIMPPRODUTORURAL,0),2)) VLIMPPRODUTORURAL,
           SUM(ROUND(B.QTCONT * NVL(MC.VLOUTROSCUSTOS,0),2)) VLOUTROSCUSTOS,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2)))) VLACRESCIMOFUNCEP,
           SUM(DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLFECP,0),2))) VLFECP,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESPFORANF,0),2)) VLDESPFORANF,
           SUM(ROUND(B.QTCONT * NVL(B.VLFRETECONHEC,0),2)) VLFRETECONHEC,
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP, 0))) PERACRESCIMOFUNCEP,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2))) VLBASEFCPICMS,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)) ALIQICMSFECP,
           0 PERCREDBASEPISCOFINSFRETE,
           SUM(ROUND(B.QTCONT * NVL(B.STBCR,0),2)) VLSTBCR,
           SUM(ROUND(B.QTCONT * NVL(B.VLICMSBCR,0),2)) VLICMSBCR,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECPSTGUIA,0),2)) VLFECPSTGUIA,
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0),2)) ELSE 0 END VLSUFRAMA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.PUNITCONT,0),2)) ELSE 0 END VLBASESUFRAMA
      from PCNFENT      A,
           PCMOV        B,
           PCMOVCOMPLE  MC,
           PCCLIENT     C,
           PCDEVCONSUM  D,
           PCCFO        CF,
           PCPRODUT     P,
           PCPRODFILIAL PF
     where NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
     and NVL(B.CODFILIALNF, B.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and A.NUMNOTA = B.NUMNOTA
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and CF.CODFISCAL = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = C.CODCLI(+)
       and A.NUMTRANSENT = D.NUMTRANSENT(+)
       and P.CODPROD = B.CODPROD
       and A.TIPODESCARGA in ('6', '7', '8', 'C', 'T')
       and B.QTCONT > 0
       and A.CHAVENFE is not null
       and B.STATUS in ('A', 'AB')
       and A.ESPECIE in ('NF', 'DA')
       --and A.DTENT >= (SELECT MIN(DTENT) FROM PCNFENT)
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              A.CHAVENFE,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              A.CHAVENFE,
              A.GERANFVENDA,
              A.GERANFDEVCLI,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              D.NUMTRANSENT,
              C.CLIENTE,
              D.CLIENTE,
              C.CGCENT,
              D.CGC,
              C.IEENT,
              CF.CODOPER,
              D.IE,
              C.ESTENT,
              D.UF,
              C.TIPOFJ,
              C.CONSUMIDORFINAL,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.TIPOFJ,
              A.CONSUMIDORFINAL,
              A.VLTOTAL,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              MC.PERDIFEREIMENTOICMS,
              NVL(B.PERCIPI, 0),
              B.ALIQUOTATIS,
              A.NFENTREGAFUTURA,
              B.DTCANCEL,
              A.SITUACAONFE,
              DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP, 0))),
              DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)),
              A.ROTINACAD
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA;

cursor C_NOTAS_PCNFBASE_TIPO1(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 06 - NOTAS FISCAIS SEM ITENS E CONHECIMENTO DE FRETE SEM RATEIO (tipo = 1)
    ----------------------------------------------------------------
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           NVL(B.CODFISCAL, 0) CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(NVL(B.SITTRIBUT, '90'), 'N', '0', A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.ALIQUOTA, 0)) PERCICM,
           ----------------------------------------------------------------
           DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.ALIQUOTA, 0)) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.ALIQUOTA, 0), 0, 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLBASE, 0)))) VLBASE,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.ALIQUOTA, 0), 0, 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', NVL(B.VLBASE, 0), 0))) VLBASENAOTRIB,
           ----------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           sum(DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLICMS, 0))) VLICMS,
           ----------------------------------------------------------------
           sum(DECODE(B.GERAICMSLIVROFISCAL, 'N', NVL(B.VLICMS, 0), 0)) VLICMSNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN EXISTS (SELECT 1
                             FROM PCMOVCIAP
                             WHERE NUMTRANSENT = A.NUMTRANSENT) THEN
                 CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                            FROM PCDESTSITTRIBUT
                                            WHERE NVL(VLISENTAS, 'N') = 'S') AND
                            NOT EXISTS (SELECT 1
                                        FROM PCCFOPEXCDESTSITTRIBUT CED
                                        WHERE CED.CODFISCAL = B.CODFISCAL
                                          AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                           (B.SITTRIBUT IN (SELECT SITTRIBUT
                                            FROM PCDESTSITTRIBUT
                                            WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                            EXISTS (SELECT 1
                                    FROM PCCFOPEXCDESTSITTRIBUT CED
                                    WHERE CED.CODFISCAL = B.CODFISCAL
                                      AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                       SUM(NVL(B.VLCONTABIL,0)) - SUM(NVL(B.Vlbase,0))
                    ELSE
                       0
                 END
              ELSE
                 SUM(NVL(B.VLISENTAS, 0))
           END VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           case
             when sum(B.VLCONTABIL) is null then
              sum(A.VLTOTAL /
                  (select count(1)
                   from PCNFBASE
                   where NUMTRANSENT = A.NUMTRANSENT
                   and CODCONT = A.CODCONT))
             else
              sum(B.VLCONTABIL +
                NVL((SELECT SUM(ROUND(P.QTCONT * NVL(P.VLFCPST,0),2))
                 FROM PCMOVCIAP P
                 WHERE P.NUMTRANSENT = A.NUMTRANSENT
                 AND P.CODFISCAL = B.CODFISCAL
                 AND P.SITTRIBUT = B.SITTRIBUT
                 AND NVL(P.PERCICM, 0) = B.ALIQUOTA),0))
           end VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           case
             when ((select count(1)  from pcmovciap p
                 where p.numtransent= A.NUMTRANSENT
                   and p.codfiscal = B.CODFISCAL
                   and p.sittribut =  B.SITTRIBUT
                   and nvl(p.percicm,0) =  B.ALIQUOTA) >= 1 ) then
               0
             else
              NVL(A.BASEICST,0)
           end VLBASEST,
           ----------------------------------------------------------------
           case
             when ((select count(1)  from pcmovciap p
                 where p.numtransent= A.NUMTRANSENT
                   and p.codfiscal = B.CODFISCAL
                   and p.sittribut =  B.SITTRIBUT
                   and nvl(p.percicm,0) =  B.ALIQUOTA) >= 1 ) then
               0
             else
              NVL(A.VLST,0)
           end VLST,
           ----------------------------------------------------------------
            case
             when ((select count(1)  from pcmovciap p
                 where p.numtransent= A.NUMTRANSENT
                   and p.codfiscal = B.CODFISCAL
                   and p.sittribut =  B.SITTRIBUT
                   and nvl(p.percicm,0) =  B.ALIQUOTA) >= 1 ) then
               0
             else
              (select sum(VLBASE)
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and TIPO = '2')
           end VLBASEIPI,
           ----------------------------------------------------------------
           case
             when ((select count(1)  from pcmovciap p
                 where p.numtransent= A.NUMTRANSENT
                   and p.codfiscal = B.CODFISCAL
                   and p.sittribut =  B.SITTRIBUT
                   and nvl(p.percicm,0) =  B.ALIQUOTA) >= 1 ) then
               0
             else
              (select sum(VLICMS)
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and TIPO = '2')
           end VLIPI,
           ----------------------------------------------------------------
            case
             when ((select count(1)  from pcmovciap p
                 where p.numtransent= A.NUMTRANSENT
                   and p.codfiscal = B.CODFISCAL
                   and p.sittribut =  B.SITTRIBUT
                   and nvl(p.percicm,0) =  B.ALIQUOTA) >= 1 ) then
               0
             else
             (select max(ALIQUOTA)
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and TIPO = '2')
           end PERCIPI,
           ----------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ----------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           -- 0 VLISENTASIPI,
           (select sum(NVL(VLISENTAS,0))
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and TIPO = '2') VLISENTASIPI,
           ----------------------------------------------------------------
           0 VLOUTRASIPI,
           ----------------------------------------------------------------
           CASE
             WHEN (SELECT COUNT(*)
                     FROM PCMOVCIAP C1
                    WHERE C1.NUMTRANSENT = B.NUMTRANSENT) > 0 THEN
----------------------------------------------------------------
         (SUM((SELECT SUM(ROUND(CI.QTCONT * CI.Vlpis,2))
             FROM PCMOVCIAP CI
            WHERE CI.NUMTRANSENT = A.NUMTRANSENT
              AND CI.CODFISCAL = B.CODFISCAL
              AND CI.SITTRIBUT = B.SITTRIBUT
              AND NVL(CI.PERCICM,0) = NVL(B.ALIQUOTA,0)
              AND CI.CODFILIAL = NVL(A.CODFILIALNF, A.CODFILIAL))))
----------------------------------------------------------------
             ELSE
              case
             when (select count(*)
                     from PCNFENTPISCOFINS PC
                    where PC.NUMTRANSENT = B.NUMTRANSENT) > 0 then
              (select sum(NVL(PC.VLPIS, 0))
                 from PCNFENTPISCOFINS PC
                where PC.NUMTRANSENT = B.NUMTRANSENT
                  and PC.NUMTRANSPISCOFINS = B.NUMTRANSPISCOFINS)
             else
              NVL(A.VLPIS, 0) /
              GREATEST(NVL((select count(1)
                             from PCNFBASE
                            where NUMTRANSENT = A.NUMTRANSENT
                              and CODCONT = A.CODCONT
                              and TIPO IN ('1','3')),
                           1),
                       1)
           end
           END VLPIS,
           CASE
             WHEN (SELECT COUNT(*)
                     FROM PCMOVCIAP C1
                    WHERE C1.NUMTRANSENT = B.NUMTRANSENT) > 0 THEN
--------------------------------------------------------------------------------
         (SUM((SELECT SUM(ROUND(CI.QTCONT * CI.vlcofins,2))
             FROM PCMOVCIAP CI
            WHERE CI.NUMTRANSENT = A.NUMTRANSENT
              AND CI.CODFISCAL = B.CODFISCAL
              AND CI.SITTRIBUT = B.SITTRIBUT
              AND NVL(CI.PERCICM,0) = NVL(B.ALIQUOTA,0)
              AND CI.CODFILIAL = NVL(A.CODFILIALNF, A.CODFILIAL))))
--------------------------------------------------------------------------------
             ELSE
              case
             when (select count(*)
                     from PCNFENTPISCOFINS PC
                    where PC.NUMTRANSENT = B.NUMTRANSENT) > 0 then
              (select sum(NVL(PC.VLCOFINS, 0))
                 from PCNFENTPISCOFINS PC
                where PC.NUMTRANSENT = B.NUMTRANSENT
                  and PC.NUMTRANSPISCOFINS = B.NUMTRANSPISCOFINS)
             else
              NVL(A.VLCOFINS, 0) /
              GREATEST(NVL((select count(1)
                             from PCNFBASE
                            where NUMTRANSENT = A.NUMTRANSENT
                              and CODCONT = A.CODCONT
                              and TIPO IN ('1','3')),
                           1),
                       1)
           end END VLCOFINS,
           ----------------------------------------------------------------
           0 VLBASESTFORANF,
           ----------------------------------------------------------------
           0 VLSTFORANF,
           ----------------------------------------------------------------
           0 ALIQUOTATIS,
           ----------------------------------------------------------------
           (select sum(NVL(VLCONTABIL, VLBASE))
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and CODFISCAL = B.CODFISCAL
               and TIPO = '1'
               and SITTRIBUT = '41') VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           (select sum(NVL(VLCONTABIL, VLBASE))
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and TIPO = '1'
               and SITTRIBUT = '20') VLBASERED_DAPI,
           ----------------------------------------------------------------
           (select sum(NVL(VLCONTABIL, VLBASE))
              from PCNFBASE
             where NUMTRANSENT = A.NUMTRANSENT
               and CODCONT = A.CODCONT
               and TIPO = '1'
               and SITTRIBUT = '50') VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
                 NVL((select  sum(round(p.qtcont * p.vlst,2))
                  from pcmovciap p
                 where p.numtransent= A.NUMTRANSENT
                   and p.codfiscal = B.CODFISCAL
                   and p.sittribut =  B.SITTRIBUT
                   and nvl(p.percicm,0) =  B.ALIQUOTA),
            A.VLST) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           ------------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           'N' NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(B.VLFCPPART,0)) END AS VLFCP --vFCPUFFim
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(b.VLICMSPARTDEST,0)) END AS VLICMSPARTDEST --vICMSUFFim
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(b.VLICMSPARTREM,0)) END AS VLICMSPARTREM --vICMSUFIni
           , 0 as VLICMSDIFALIQPART
           , 0 as VLBASEPARTDEST
           , 0 as VLCREDPRESUMIDO
           , A.SITUACAONFE
    ----------------------------------------------------------------
           , 0 as PERCIMPPRODUTORRURAL
    ----------------------------------------------------------------
           ,(SELECT sum(ROUND( DECODE( NVL(M.GRAVADOUNITARIO,'N'), 'S', M.QTCONT, 1) * M.VLDIFALIQUOTA, 2))
               FROM PCMOVCIAP M
              WHERE M.NUMTRANSENT = A.NUMTRANSENT
                AND M.NUMNOTA = A.NUMNOTA
                AND M.SITTRIBUT = B.SITTRIBUT
                AND M.CODFISCAL = B.CODFISCAL) VLDIFALIQUOTA
    ----------------------------------------------------------------
           ,(SELECT sum(ROUND( DECODE( NVL(M.GRAVADOUNITARIO,'N'), 'S', M.QTCONT, 1) * M.VLCREDITO, 2))
               FROM PCMOVCIAP M
              WHERE M.NUMTRANSENT = A.NUMTRANSENT
                AND M.NUMNOTA = A.NUMNOTA
                AND M.SITTRIBUT = B.SITTRIBUT
                AND M.CODFISCAL = B.CODFISCAL) VLCREDITO_CIAP
    ----------------------------------------------------------------
          , 0 AS VLOUTROSCUSTOSCUSTO
          , 0 AS VLICMSANTECIPADO
          , 0 AS VLIMPPRODUTORURAL
          , 0 AS VLOUTROSCUSTOS
    ----------------------------------------------------------------
          ,NVL(ROUND((SELECT SUM(M.QTCONT * NVL(M.VLFCP, 0))
             FROM PCMOVCIAP M
            WHERE M.NUMTRANSENT = A.NUMTRANSENT
              AND M.CODFISCAL = B.CODFISCAL
              AND M.SITTRIBUT = B.SITTRIBUT
              AND M.NUMNOTA = A.NUMNOTA)
           , 2), 0) VLACRESCIMOFUNCEP
    ----------------------------------------------------------------
          , 0 AS VLFECP
          , 0 AS VLDESPFORANF
          , 0 AS VLFRETECONHEC
    ----------------------------------------------------------------
          ,NVL((SELECT MAX(M.PERCFCP)
             FROM PCMOVCIAP M
            WHERE M.NUMTRANSENT = A.NUMTRANSENT
              AND M.CODFISCAL = B.CODFISCAL
              AND M.NUMNOTA = A.NUMNOTA)
          ,0) PERACRESCIMOFUNCEP
    ----------------------------------------------------------------
          ,(SELECT SUM(ROUND(M.QTCONT * M.BASECALCFCP, 2))
             FROM PCMOVCIAP M
            WHERE M.NUMTRANSENT = A.NUMTRANSENT
              AND M.CODFISCAL = B.CODFISCAL
              AND M.NUMNOTA = A.NUMNOTA) VLBASEFCPICMS
    ----------------------------------------------------------------
          , 0 AS VLBASEFCPST
          , 0 AS ALIQICMSFECP
          , MAX(NVL(A.PERCREDBASEPISCOFINSFRETE,0)) PERCREDBASEPISCOFINSFRETE
          , 0 AS VLSTBCR
          , 0 AS VLICMSBCR
          , 0 AS VLFECPSTGUIA
          , 0 AS VLSUFRAMA
          , 0 AS VLBSESUFRAMA
      from PCNFENT  A,
           PCNFBASE B,
           PCFORNEC F,
           PCCFO    CF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT(+)
       and A.CODCONT = B.CODCONT(+)
       and B.TIPO IN ('1','3')
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = F.CODFORNEC
       and A.ESPECIE in ('NF', 'CO', 'CT', 'DA', 'NC', 'NS') --ADICIONADO NS PARA ATUALIAR A CONTA CONTABIL, PORÉM, FOI CRIADA CONDICIONAL PARA NÃO GERAR O LIVRO PARA ESSA ESPECIE
       and ((not exists (select CODPROD
                         from PCMOV
                         where NUMTRANSENT = A.NUMTRANSENT
                         and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = NVL(A.CODFILIALNF,A.CODFILIAL)
                           and NUMNOTA = A.NUMNOTA)) or (a.especie = 'CT'))
       and (V_TRIBUTAFRETERATEADO = 'N' or
            (not exists (select NUMNOTA
                         from PCNFENTFRETE
                         where NUMTRANSENT = A.NUMTRANSENT)))
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              B.NUMTRANSENT,
              B.NUMTRANSPISCOFINS,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              A.CHAVENFE,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              F.FORNECEDOR,
              F.CGC,
              CF.CODOPER,
              F.IE,
              F.ESTADO,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.VLTOTAL,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              B.SITTRIBUT,
              B.GERAICMSLIVROFISCAL,
              B.ALIQUOTA,
              NVL(A.OBSLIVROFISCAL, A.OBS),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLPIS,
              A.VLCOFINS,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              A.BASEICST,
              A.VLST,
              A.CODCONT,
              A.NFENTREGAFUTURA,
              A.DTCANCEL,
              A.SITUACAONFE
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA;

cursor C_NOTAS_PCNFBASE_TIPO2(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 07 - NOTAS FISCAIS SEM ITENS E CONHECIMENTO DE FRETE SEM RATEIO (tipo = 2)
    ----------------------------------------------------------------
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           NVL(B.CODFISCAL, 0) CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(NVL(B.SITTRIBUT, '90'), 'N', '0', A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           0 PERCICM,
           ----------------------------------------------------------------
           0 PERCICMNAOTRIB,
           ----------------------------------------------------------------
           0 VLBASE,
           ----------------------------------------------------------------
           0 VLBASENAOTRIB,
           ----------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           0 VLICMS,
           ----------------------------------------------------------------
           0 VLICMSNAOTRIB,
           ----------------------------------------------------------------
           sum(NVL(B.VLISENTAS, 0)) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           case
             when sum(B.VLCONTABIL) is null then
              sum(A.VLTOTAL /
                  (select count(1)
                     from PCNFBASE
                    where NUMTRANSENT = A.NUMTRANSENT
                    and CODCONT = A.CODCONT))
             else
              sum(B.VLCONTABIL)
           end VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           A.BASEICST VLBASEST,
           ----------------------------------------------------------------
           A.VLST,
           ----------------------------------------------------------------
           sum(NVL(B.VLBASE, 0)) VLBASEIPI,
           ----------------------------------------------------------------
           sum(NVL(B.VLICMS, 0)) VLIPI,
           ----------------------------------------------------------------
           NVL(B.ALIQUOTA, 0) PERCIPI,
           ----------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ----------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           0 VLISENTASIPI,
           ----------------------------------------------------------------
           0 VLOUTRASIPI,
           ----------------------------------------------------------------
           ----------------------------------------------------------------
           CASE WHEN (SELECT COUNT(*)
                      FROM PCMOVCIAP C1
                      WHERE C1.NUMTRANSENT = B.NUMTRANSENT) > 0 THEN
                   (SELECT SUM(ROUND(C2.QTCONT * NVL(C2.VLPIS,0),2))
                    FROM PCMOVCIAP C2
                    WHERE C2.NUMTRANSENT = B.NUMTRANSENT
                      AND C2.CODFISCAL = B.CODFISCAL)
                ELSE
                   (case when NVL(A.VLPIS, 0) > 0 then
                      NVL(A.VLPIS, 0) /
                      GREATEST(NVL((select count(1)
                                    from PCNFBASE
                                    where NUMTRANSENT = A.NUMTRANSENT
                                      and CODCONT = A.CODCONT
                                      and TIPO = B.TIPO), 1), 1)
                     else
                      (select sum(NVL(PC.VLPIS, 0))
                       from PCNFENTPISCOFINS PC
                       where PC.NUMTRANSENT = B.NUMTRANSENT
                         and PC.NUMTRANSPISCOFINS = B.NUMTRANSPISCOFINS)
                    end)
           END VLPIS,
           ----------------------------------------------------------------
           CASE WHEN (SELECT COUNT(*)
                      FROM PCMOVCIAP C1
                      WHERE C1.NUMTRANSENT = B.NUMTRANSENT) > 0 THEN
                   (SELECT SUM(ROUND(C2.QTCONT * NVL(C2.VLCOFINS,0),2))
                    FROM PCMOVCIAP C2
                    WHERE C2.NUMTRANSENT = B.NUMTRANSENT
                      AND C2.CODFISCAL = B.CODFISCAL)
                ELSE
                   (case when NVL(A.VLPIS, 0) > 0 then
                      NVL(A.VLCOFINS, 0) /
                      GREATEST(NVL((select count(1)
                                     from PCNFBASE
                                    where NUMTRANSENT = A.NUMTRANSENT
                                      and CODCONT = A.CODCONT
                                      and TIPO = B.TIPO), 1), 1)
                     else
                      (select sum(NVL(PC.VLCOFINS, 0))
                         from PCNFENTPISCOFINS PC
                        where PC.NUMTRANSENT = B.NUMTRANSENT
                          and PC.NUMTRANSPISCOFINS = B.NUMTRANSPISCOFINS)
                    end)
           END VLCOFINS,
           ----------------------------------------------------------------
           0 VLBASESTFORANF,
           ----------------------------------------------------------------
           0 VLSTFORANF,
           ----------------------------------------------------------------
           0 ALIQUOTATIS,
           ----------------------------------------------------------------
           0 VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           0 VLBASERED_DAPI,
           ----------------------------------------------------------------
           0 VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           0 VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           ------------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           'N' NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(B.VLFCPPART,0)) END AS VLFCP --vFCPUFFim
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(b.VLICMSPARTDEST,0)) END AS VLICMSPARTDEST --vICMSUFFim
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(b.VLICMSPARTREM,0)) END AS VLICMSPARTREM --vICMSUFIni
           ,0  as VLICMSDIFALIQPART
           ,0  as VLBASEPARTDEST
           ,0  as VLCREDPRESUMIDO
           ,A.SITUACAONFE
    ----------------------------------------------------------------
           , 0 as PERCIMPPRODUTORRURAL
    ----------------------------------------------------------------
           ,(SELECT sum(ROUND( DECODE( NVL(M.GRAVADOUNITARIO,'N'), 'S', M.QTCONT, 1) * M.VLDIFALIQUOTA, 2))
               FROM PCMOVCIAP M
              WHERE M.NUMTRANSENT = A.NUMTRANSENT
                AND M.NUMNOTA = A.NUMNOTA
                AND M.CODFISCAL = B.CODFISCAL) VLDIFALIQUOTA
    ----------------------------------------------------------------
           ,(SELECT sum(ROUND( DECODE( NVL(M.GRAVADOUNITARIO,'N'), 'S', M.QTCONT, 1) * M.VLCREDITO, 2))
               FROM PCMOVCIAP M
              WHERE M.NUMTRANSENT = A.NUMTRANSENT
                AND M.NUMNOTA = A.NUMNOTA
                AND M.CODFISCAL = B.CODFISCAL) VLCREDITO_CIAP
    ----------------------------------------------------------------
           ,0 AS VLOUTROSCUSTOSCUSTO
           ,0 AS VLICMSANTECIPADO
           ,0 AS VLIMPPRODUTORURAL
           ,0 AS VLOUTROSCUSTOS
    ----------------------------------------------------------------
          ,NVL(ROUND((SELECT SUM(M.QTCONT * NVL(M.VLFCP, 0))
             FROM PCMOVCIAP M
            WHERE M.NUMTRANSENT = A.NUMTRANSENT
              AND M.CODFISCAL = B.CODFISCAL
              AND M.NUMNOTA = A.NUMNOTA)
           , 2), 0) VLACRESCIMOFUNCEP
    ----------------------------------------------------------------
           ,0 AS VLFECP
           ,0 AS VLDESPFORANF
           ,0 AS VLFRETECONHEC
    ----------------------------------------------------------------
          ,NVL((SELECT MAX(M.PERCFCP)
             FROM PCMOVCIAP M
            WHERE M.NUMTRANSENT = A.NUMTRANSENT
              AND M.CODFISCAL = B.CODFISCAL
              AND M.NUMNOTA = A.NUMNOTA)
          ,0) PERACRESCIMOFUNCEP
    ----------------------------------------------------------------
          ,(SELECT SUM(ROUND(M.QTCONT * M.BASECALCFCP, 2))
             FROM PCMOVCIAP M
            WHERE M.NUMTRANSENT = A.NUMTRANSENT
              AND M.CODFISCAL = B.CODFISCAL
              AND M.NUMNOTA = A.NUMNOTA) VLBASEFCPICMS
    ----------------------------------------------------------------
           ,0 AS VLBASEFCPST
           ,0 AS ALIQICMSFECP
           , MAX(NVL(A.PERCREDBASEPISCOFINSFRETE,0)) PERCREDBASEPISCOFINSFRETE
           ,0 AS VLSTBCR
           ,0 AS VLICMSBCR
           ,0 AS VLFECPSTGUIA
           ,0 AS VLSUFRAMA
          , 0 AS VLBSESUFRAMA           
      from PCNFENT  A,
           PCNFBASE B,
           PCFORNEC F,
           PCCFO    CF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT(+)
       and A.CODCONT = B.CODCONT(+)
       and (B.TIPO = '2' and not exists (select 1
                                         from PCNFBASE
                                         where NUMTRANSENT = A.NUMTRANSENT
                                           and TIPO = '1'))
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = F.CODFORNEC
       and A.ESPECIE in ('NF', 'CO', 'CT', 'DA', 'NC', 'NS') --ADICIONADO NS PARA ATUALIAR A CONTA CONTABIL, PORÉM, FOI CRIADA CONDICIONAL PARA NÃO GERAR O LIVRO PARA ESSA ESPECIE
       and ((not exists
           (select CODPROD
            from PCMOV
            where NUMTRANSENT = A.NUMTRANSENT
               and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = NVL(A.CODFILIALNF,A.CODFILIAL)
               and NUMNOTA = A.NUMNOTA)) or (a.especie = 'CT'))
       and (V_TRIBUTAFRETERATEADO = 'N' or
            (not exists (select NUMNOTA
                           from PCNFENTFRETE
                          where NUMTRANSENT = A.NUMTRANSENT)))
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              B.NUMTRANSENT,
              B.NUMTRANSPISCOFINS,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              A.CHAVENFE,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              F.FORNECEDOR,
              F.CGC,
              CF.CODOPER,
              F.IE,
              F.ESTADO,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.VLTOTAL,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              B.SITTRIBUT,
              B.TIPO,
              B.GERAICMSLIVROFISCAL,
              NVL(B.ALIQUOTA, 0),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLPIS,
              A.VLCOFINS,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              A.BASEICST,
              A.VLST,
              A.CODCONT,
              A.NFENTREGAFUTURA,
              A.DTCANCEL,
              A.SITUACAONFE
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA;

cursor C_NOTAS_CONHECIMENTOFRETE(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
    -- 08 - CONHECIMENTOS DE FRETE COM RATEIO
    ----------------------------------------------------------------
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(NVL(B.SITTRIBUT, '90'), 'N', '0', A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           DECODE(B.TIPO, '1', B.ALIQUOTA, 0) PERCICM,
           ----------------------------------------------------------------
           DECODE(B.TIPO, '1', 0, B.ALIQUOTA) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           NVL(B.VLBASE,0) VLBASE,
           -- Foi alterado em 07/12/2015 pois como ? frete deveria pegar direto da tabela PCNFBASE e n?o dos itens (1812.116739).
           -- Isso foi necess?rio porque nos itens estava tendo diverg?ncia de valores em centavos por causa do arredondamento dos itens.
--           LEAST(ROUND(SUM(DECODE(NVL(M.GERAICMSLIVROFISCAL,'S'), 'S',
--                       M.QTCONT * NVL(M.VLFRETECONHEC, 0), 0)),2),
--                 ROUND(SUM(M.QTCONT *  NVL(M.BASEICMS, 0)),2)) VLBASE,
           ----------------------------------------------------------------
           0 VLBASENAOTRIB,
           ----------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ----------------------------------------------------------------
           0 VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           0 VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           'N' TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           'N' TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           0 VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLICMS, 0)) VLICMS,
           ----------------------------------------------------------------
           0 VLICMSNAOTRIB, -- VALOR RECACALCULADO POSTERIORMENTE SE VLBASE > 0
           ----------------------------------------------------------------
           NVL(B.VLISENTAS, 0) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           A.VLTOTAL VLDESDOBRADO,
           ----------------------------------------------------------------
           '0' TIPODESCARGA,
           ----------------------------------------------------------------
           A.BASEICST VLBASEST,
           ----------------------------------------------------------------
           A.VLST,
           ----------------------------------------------------------------
           DECODE(B.TIPO, '2', NVL(B.VLBASE, 0), 0) VLBASEIPI,
           ----------------------------------------------------------------
           DECODE(B.TIPO, '2', NVL(B.VLICMS, 0), 0) VLIPI,
           ----------------------------------------------------------------
           DECODE(B.TIPO, '2', NVL(B.ALIQUOTA, 0), 0) PERCIPI,
           ----------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ----------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           0 VLISENTASIPI,
           ----------------------------------------------------------------
           0 VLOUTRASIPI,
           ----------------------------------------------------------------
           CASE WHEN (SELECT COUNT(*)
                      FROM PCMOVCIAP C1
                      WHERE C1.NUMTRANSENT = B.NUMTRANSENT) > 0 THEN
                   (SELECT SUM(ROUND(C2.QTCONT * NVL(C2.VLPIS,0),2))
                    FROM PCMOVCIAP C2
                    WHERE C2.NUMTRANSENT = B.NUMTRANSENT
                      AND C2.CODFISCAL = B.CODFISCAL)
                ELSE
                   DECODE(NVL(A.VLPIS, 0), 0, (select sum(NVL(PC.VLPIS, 0))
                                               from PCNFENTPISCOFINS PC
                                               where PC.NUMTRANSENT = B.NUMTRANSENT
                                                 and PC.NUMTRANSPISCOFINS = B.NUMTRANSPISCOFINS), NVL(A.VLPIS, 0))
           END VLPIS,
           ----------------------------------------------------------------
           CASE WHEN (SELECT COUNT(*)
                      FROM PCMOVCIAP C1
                      WHERE C1.NUMTRANSENT = B.NUMTRANSENT) > 0 THEN
                   (SELECT SUM(ROUND(C2.QTCONT * NVL(C2.VLCOFINS,0),2))
                    FROM PCMOVCIAP C2
                    WHERE C2.NUMTRANSENT = B.NUMTRANSENT
                      AND C2.CODFISCAL = B.CODFISCAL)
                ELSE
                   DECODE(NVL(A.VLCOFINS, 0), 0, (select sum(NVL(PC.VLCOFINS, 0))
                                                  from PCNFENTPISCOFINS PC
                                                  where PC.NUMTRANSENT = B.NUMTRANSENT
                                                    and PC.NUMTRANSPISCOFINS = B.NUMTRANSPISCOFINS), NVL(A.VLCOFINS, 0))
           END VLCOFINS,
           ----------------------------------------------------------------
           0 VLBASESTFORANF,
           ----------------------------------------------------------------
           0 VLSTFORANF,
           ----------------------------------------------------------------
           0 ALIQUOTATIS,
           ----------------------------------------------------------------
           0 VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           0 VLBASERED_DAPI,
           ----------------------------------------------------------------
           0 VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           0 VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           ----------------------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(M.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(B.VLFCPPART,0)) END AS VLFCP --vFCPUFFim
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(b.VLICMSPARTDEST,0)) END AS VLICMSPARTDEST --vICMSUFFim
           ,CASE WHEN NOT A.DTCANCEL IS NULL THEN 0 ELSE sum(NVL(b.VLICMSPARTREM,0)) END AS VLICMSPARTREM --vICMSUFIni
           ,0 AS VLICMSDIFALIQPART
           ,0 AS VLBASEPARTDEST
           ,0 AS VLCREDPRESUMIDO
           ,A.SITUACAONFE
    ----------------------------------------------------------------
           ,SUM(ROUND(NVL(M.PERCIMPPRODUTORURAL,0) * M.QTCONT, 2)) PERCIMPPRODUTORRURAL
    ----------------------------------------------------------------
           ,SUM(ROUND(NVL(M.VLDIFALIQUOTAS,0) * M.QTCONT, 2)) VLDIFALIQUOTA
           , 0 AS VLCREDITO_CIAP
           , 0 AS VLOUTROSCUSTOSCUSTO
           , 0 AS VLICMSANTECIPADO
           , 0 AS VLIMPPRODUTORURAL
           , 0 AS VLOUTROSCUSTOS
           , 0 AS VLACRESCIMOFUNCEP
           , 0 AS VLFECP
           , 0 AS VLDESPFORANF
           , 0 AS VLFRETECONHEC
           , 0 AS PERACRESCIMOFUNCEP
           , 0 AS VLBASEFCPICMS
           , 0 AS VLBASEFCPST
           , 0 AS ALIQICMSFECP
           , MAX(NVL(A.PERCREDBASEPISCOFINSFRETE,0)) PERCREDBASEPISCOFINSFRETE
           ,0 AS VLSTBCR
           ,0 AS VLICMSBCR
           ,0 AS VLFECPSTGUIA
           ,0 AS VLSUFRAMA 
           ,0 AS VLBASESUFRAMA
      from PCNFENT      A,
           PCNFENTFRETE EF,
           PCNFENT      N,
           PCMOV        M,
           PCNFBASE     B,
           PCFORNEC     F,
           PCCFO        CF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       AND NVL(M.CODFILIALNF, M.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and F.CODFORNEC = NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC))
       and A.NUMTRANSENT = EF.NUMTRANSENT
       and EF.NUMTRANSENTNF = N.NUMTRANSENT
       and EF.NUMNOTA = N.NUMNOTA
       and A.CODCONT = B.CODCONT(+)
       and CF.CODFISCAL(+) = B.CODFISCAL
       and A.NUMTRANSENT = B.NUMTRANSENT
       and N.NUMTRANSENT = M.NUMTRANSENT
       and N.NUMNOTA = M.NUMNOTA
       and A.TIPODESCARGA not in ('6', '7', '8', 'T')
       and A.ESPECIE in ('CO', 'CT')
       and N.ESPECIE = 'NF'
       and A.VLTOTAL > 0
       and V_TRIBUTAFRETERATEADO = 'S'
       and not exists (select CODPROD
                       from PCMOV
                       where NUMTRANSENT = A.NUMTRANSENT
                         and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = NVL(A.CODFILIALNF,A.CODFILIAL)
                         and NUMNOTA = A.NUMNOTA)
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              B.NUMTRANSENT,
              B.NUMTRANSPISCOFINS,
              A.CODCONT,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.CHAVENFE,
              A.SERIE,
              B.VLBASE,
              B.VLISENTAS,
              B.VLICMS,
              A.VLPIS,
              A.VLCOFINS,
              A.NUMNOTA,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              F.FORNECEDOR,
              CF.CODOPER,
              F.ESTADO,
              F.CGC,
              F.IE,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.VLTOTAL,
              A.BASEICST,
              A.VLST,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              B.SITTRIBUT,
              B.ALIQUOTA,
              NVL(A.OBSLIVROFISCAL, A.OBS),
              B.TIPO,
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
              A.NFENTREGAFUTURA,
              A.DTCANCEL,
              A.SITUACAONFE,
              B.VLICMS,
              B.GERAICMSLIVROFISCAL
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA;
    ----------------------------------------------------------------

 cursor C_NOTAS_COMPLEMETAR_COM_ITEM(P_CODFILIAL in varchar2, P_DATA1 in date, P_DATA2 in date, P_NOTA1 in number, P_NOTA2 in number) is
-- 09 - NOTAS FISCAIS COMPLEMENTAR COM ITENS
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ----------------------------------------------------------------
           A.NUMTRANSENT,
           ----------------------------------------------------------------
           A.DTENT,
           ----------------------------------------------------------------
           A.DTEMISSAO,
           ----------------------------------------------------------------
           A.ESPECIE,
           ----------------------------------------------------------------
           A.SERIE,
           ----------------------------------------------------------------
           A.NUMNOTA,
           ----------------------------------------------------------------
           NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) CODFORNEC,
           ----------------------------------------------------------------
           NVL(A.FORNECEDOR, F.FORNECEDOR) FORNECEDOR,
           ----------------------------------------------------------------
           NVL(A.CGC, F.CGC) CNPJ,
           ----------------------------------------------------------------
           NVL(A.IE, F.IE) IE,
           ----------------------------------------------------------------
           NVL(A.UF, F.ESTADO) UF,
           ----------------------------------------------------------------
           'J' TIPOFJ,
           ----------------------------------------------------------------
           'N' CONSUMIDORFINAL,
           ----------------------------------------------------------------
           A.VLTOTAL,
           ----------------------------------------------------------------
           SUBSTR(TO_CHAR(A.CODCONT), 1, 10) CODCONT,
           ----------------------------------------------------------------
           B.CODFISCAL,
           ----------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
           ----------------------------------------------------------------
           CF.CODOPER,
           ----------------------------------------------------------------
           'N' NFE_PROPRIA,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
           END AS PERCICM,
           ----------------------------------------------------------------
           DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0) PERCICMNAOTRIB,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0), 2))
           END AS VLBASE,
           ----------------------------------------------------------------
           CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
             0
           ELSE
             SUM(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.BASEICMS, 0), 0), 2))
           END AS VLBASENAOTRIB,
           ----------------------------------------------------------------
           SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0, B.QTCONT *
                             DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', GREATEST(NVL(B.PUNITCONT, 0) -
                                              NVL(B.VLDESCONTO, 0) -
                                              NVL(B.BASEICMS, 0), 0), 0)), 2)) VLBASE_REDUCAO,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(NVL(A.VLFRETE, 0), 0, 0, DECODE(NVL((select UTILIZAFRETECALCICMS
                                    from PCPEDIDO
                                   where NUMPED =
                                         B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, NVL(B.VLFRETE, 0)))) VLFRETE_PEDIDO,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(NVL(A.VLFRETE, 0), 0, 0, DECODE(NVL((select UTILIZAFRETECALCICMS
                                               from PCPEDIDO
                                              where NUMPED =
                                                    B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, case
                                            when (NVL(B.BASEICMS, 0) = 0) or (B.GERAICMSLIVROFISCAL = 'N') then
                                             0
                                            else
                                             NVL(B.VLFRETE, 0)
                                          end))) VLBASEFRETE_PEDIDO,
           ----------------------------------------------------------------
           DECODE(max(NVL((select UTILIZAFRETECALCICMS
                            from PCPEDIDO
                           where NUMPED = B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N')), 'S', 0, A.VLFRETE) VLFRETE,
           ----------------------------------------------------------------
           0 VLFRETE_RATEIO,
           ----------------------------------------------------------------
           0 VLBASEFRETE_RATEIO,
           ----------------------------------------------------------------
           DECODE(max(NVL(B.CODFISCALFRETEENT, 0)), 0, 'N', 'S') TRIBUTA_FRETE_ITEM,
           ----------------------------------------------------------------
           DECODE(max(NVL(B.CODFISCALOUTRASDESPENT, 0)), 0, 'N', 'S') TRIBUTA_DESPESA_ITEM,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(NVL(A.VLOUTRAS, 0), 0, 0, DECODE(NVL((select UTILIZAOUTRASDESPCALCICMS
                                    from PCPEDIDO
                                   where NUMPED =
                                         B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, NVL(B.VLOUTRASDESP, 0)))) VLOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           sum(B.QTCONT * DECODE(NVL(A.VLOUTRAS, 0), 0, 0, DECODE(NVL((select UTILIZAOUTRASDESPCALCICMS
                                               from PCPEDIDO
                                              where NUMPED =
                                                    B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N'), 'N', 0, case
                                            when (NVL(B.BASEICMS, 0) = 0) or (B.GERAICMSLIVROFISCAL = 'N') then
                                             0
                                            else
                                             NVL(B.VLOUTRASDESP, 0)
                                          end))) VLBASEOUTRASDESP_PEDIDO,
           ----------------------------------------------------------------
           DECODE(max(NVL((select UTILIZAOUTRASDESPCALCICMS
                            from PCPEDIDO
                           where NUMPED = B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N')), 'S', 0, DECODE(max(NVL(B.CODFISCALOUTRASDESPENT, 0)), 0, DECODE(max(B.CODOPER), 'ET', 0, ROUND(sum(B.QTCONT *
                                             (NVL(B.VLOUTRASDESP, 0) -
                                             NVL(B.VLACRESCIMOPF, 0))), 2)), 0)) VLOUTRASDESP_ITEM,
           ----------------------------------------------------------------
           DECODE(max(NVL((select UTILIZAOUTRASDESPCALCICMS
                            from PCPEDIDO
                           where NUMPED = B.NUMPED AND PCPEDIDO.CODFILIAL = PCODFILIAL), 'N')), 'S', 0, DECODE(max(B.CODOPER), 'ET', A.VLOUTRAS, DECODE(max(NVL(B.CODFISCALOUTRASDESPENT, 0)), 0, 0, A.VLOUTRAS))) VLOUTRASDESP,
           ----------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ----------------------------------------------------------------
           A.PERBASEREDOUTRASDESP,
           ----------------------------------------------------------------
           sum(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS( P_CODFILIAL, 'E', 'NF', B.ROWID,'', a.chavenfe),0)) VLICMS,
           ----------------------------------------------------------------
           sum(ROUND(B.QTCONT * case
                       when (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                            (NVL(B.BASEICMS, 0) <= 0) or (NVL(B.PERCICM, 0) <= 0) then
                        (NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100)
                       else
                        0
                     end, 2)) VLICMSNAOTRIB, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           GREATEST((SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                         NOT EXISTS (SELECT 1
                                                     FROM PCCFOPEXCDESTSITTRIBUT CED
                                                     WHERE CED.CODFISCAL = B.CODFISCAL
                                                       AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                                         (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                         EXISTS (SELECT 1
                                                 FROM PCCFOPEXCDESTSITTRIBUT CED
                                                 WHERE CED.CODFISCAL = B.CODFISCAL
                                                   AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                                  B.QTCONT * (B.PUNITCONT - NVL(B.VLDESCONTO, 0) - NVL(B.VLSUFRAMA, 0) +
                                              DECODE(NVL(A.VLOUTRAS, 0), 0, 0,
                                                     DECODE(NVL((SELECT UTILIZAOUTRASDESPCALCICMS
                                                                 FROM PCPEDIDO
                                                                 WHERE NUMPED = B.NUMPED
                                                                 AND PCPEDIDO.CODFILIAL = PCODFILIAL
                                                                   AND ROWNUM = 1), 'S'), 'S', NVL(B.VLOUTRASDESP, 0), 0)) +
                                              DECODE(NVL(A.VLFRETE, 0), 0, 0,
                                                     DECODE(NVL((SELECT UTILIZAFRETECALCICMS
                                                                 FROM PCPEDIDO
                                                                 WHERE NUMPED = B.NUMPED
                                                                 AND PCPEDIDO.CODFILIAL = PCODFILIAL
                                                                   AND ROWNUM = 1), 'S'), 'S', NVL(B.VLFRETE, 0), 0)))
                               ELSE
                                  0
                               END, 2)) -
                     SUM(ROUND(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLISENTAS, 'N') = 'S') AND
                                         NOT EXISTS (SELECT 1
                                                     FROM PCCFOPEXCDESTSITTRIBUT CED
                                                     WHERE CED.CODFISCAL = B.CODFISCAL
                                                       AND CED.SITTRIBUT = B.SITTRIBUT)) OR
                                         (B.SITTRIBUT IN (SELECT SITTRIBUT
                                                          FROM PCDESTSITTRIBUT
                                                          WHERE NVL(VLOUTRAS, 'N') = 'S') AND
                                         EXISTS (SELECT 1
                                                 FROM PCCFOPEXCDESTSITTRIBUT CED
                                                 WHERE CED.CODFISCAL = B.CODFISCAL
                                                   AND CED.SITTRIBUT = B.SITTRIBUT)) THEN
                                  B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0)
                               ELSE
                                  0
                               END, 2))), 0) VLISENTAS,
           ----------------------------------------------------------------
           0 VLOUTRAS, -- VALOR CALCULADO POSTERIORMENTE
           ----------------------------------------------------------------
           NVL(A.OBSLIVROFISCAL, A.OBS) OBS,
           ----------------------------------------------------------------
           SUM(ROUND(B.QTCONT * B.PUNITCONT, 2) +
               ROUND(B.QTCONT * NVL(B.VLOUTROS,0), 2) -
               ROUND(B.QTCONT * NVL(B.VLDESCONTO,0), 2) -
               ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0), 2) +
               ROUND(B.QTCONT *
                     DECODE(A.CHAVENFE, NULL, 0, NVL(B.VLOUTRASDESP,0) + NVL(B.VLFRETE,0)),2) +
               ROUND(B.QTCONT * NVL(B.VLIPI,0), 2) +
               ROUND(B.QTCONT * NVL(B.ST,0), 2) +
               ROUND(B.QTCONT * DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, NVL(MC.VLFECP,0)), 2)) VLDESDOBRADO,
           ----------------------------------------------------------------
           A.TIPODESCARGA,
           ----------------------------------------------------------------
           sum(round(B.QTCONT * B.BASEICST,2)) VLBASEST,
           ----------------------------------------------------------------
           sum(ROUND(NVL(B.ST,0) * B.QTCONT, 2)) VLST,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLBASEIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLBASEIPI, 0), 0))) VLBASEIPI,
           ----------------------------------------------------------------
           sum(DECODE(B.CODOPER, 'ET', DECODE(B.CALCCREDIPI, 'S', ROUND(B.QTCONT *
                                     NVL(B.VLIPI, 0), 2), 0), DECODE(B.CALCCREDIPI, 'S', B.QTCONT *
                               NVL(B.VLIPI, 0), 0))) VLIPI,
           ----------------------------------------------------------------
           DECODE(NVL(B.CALCCREDIPI,'N'),'N',0,NVL(B.PERCIPI, 0))  PERCIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) else 0 end) VLBASEISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER,'ET', DECODE(NVL(B.CALCCREDIPI,'N'),'N', case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  ROUND(B.QTCONT *
                        (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                        NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                        DECODE((select max(FORMVALORIPI)
                                  from PCDESTSITTRIBUTIPI
                                 where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0)), 2)
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0),
           DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', case
                     when (select max(FORMVALORIPI)
                             from PCDESTSITTRIBUTIPI
                            where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                      B.QTCONT *
                      (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                      NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                      DECODE((select max(FORMVALORIPI)
                                from PCDESTSITTRIBUTIPI
                               where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                     else
                      B.QTCONT * NVL(B.VLBASEIPI, 0)
                   end, 0)) end) VLBASEOUTRASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', B.QTCONT *
                                  NVL(B.VLIPI, 0), 0))
                 else
                  0
               end) VLISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  DECODE(B.CODOPER, 'ET', DECODE(NVL(B.CALCCREDIPI, 'N'), 'N', ROUND(B.QTCONT *
                                        NVL(B.VLIPI, 0), 2), 0), DECODE(NVL(B.CALCCREDIPI, 'N'), 'N',
                                       ROUND(B.QTCONT * NVL(B.VLIPI,0),2), 0))
               end) VLOUTRASIPI,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCREDPIS), 2)) VLPIS,
           ------------------------------------------------------------------

           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCREDCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT *
                             B.VLCREDCOFINS), 2)) VLCOFINS,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLBASESTFORANF, 0)) VLBASESTFORANF,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.VLDESPADICIONAL, 0)) VLSTFORANF,
           ----------------------------------------------------------------
           B.ALIQUOTATIS,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '41', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLNAOTRIB_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '20', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT *
               DECODE(B.SITTRIBUT, '50', GREATEST(B.PUNITCONT -
                                NVL(B.VLDESCONTO, 0), 0), 0)) VLSUSPENSAS_DAPI,
           ----------------------------------------------------------------
           sum(B.QTCONT * NVL(B.ST, 0)) VLST_DAPI,
           ----------------------------------------------------------------
           0 VLISENTAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           0 VLOUTRAS_DAPI, -- VALORES CALCULADOS POSTERIORMENTE
           ----------------------------------------------------------------
           A.NFENTREGAFUTURA,
           -----------------------------------------------------------
           sysdate DTGERA,
           ----------------------------------------------------------------
           case
             when max(B.CODOPER) = 'ET' and A.CHAVENFE is not null then
              'S'
             else
              'N'
           end NFETRANSFERENCIA,
           ----------------------------------------------------------------
           A.CHAVENFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END VLBASEPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE ROUND(SUM(B.QTCONT * NVL(B.VLCREDPRESUMIDO,0)),2) END AS VLCREDPRESUMIDO,
    ----------------------------------------------------------------
           A.SITUACAONFE,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.PERCIMPPRODUTORURAL,0) * B.QTCONT, 2)) PERCIMPPRODUTORRURAL,
    ----------------------------------------------------------------
           SUM(ROUND(NVL(B.VLDIFALIQUOTAS,0) * B.QTCONT, 2)) VLDIFALIQUOTA,
           0 AS VLCREDITO_CIAP,
           SUM(ROUND(B.QTCONT * MC.VLOUTROSCUSTOSCUSTO,2)) VLOUTROSCUSTOSCUSTO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLICMSANTECIPADO,0),2)) VLICMSANTECIPADO,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIMPPRODUTORURAL,0),2)) VLIMPPRODUTORURAL,
           SUM(ROUND(B.QTCONT * NVL(MC.VLOUTROSCUSTOS,0),2)) VLOUTROSCUSTOS,
           0 VLACRESCIMOFUNCEP,
           0 VLFECP,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESPFORANF,0),2)) VLDESPFORANF,
           SUM(ROUND(B.QTCONT * NVL(B.VLFRETECONHEC,0),2)) VLFRETECONHEC,
           0 PERACRESCIMOFUNCEP,
           0 VLBASEFCPICMS,
           0 VLBASEFCPST,
           0 ALIQICMSFECP,
           0 PERCREDBASEPISCOFINSFRETE,
           SUM(ROUND(B.QTCONT * NVL(B.STBCR,0),2)) VLSTBCR,
           SUM(ROUND(B.QTCONT * NVL(B.VLICMSBCR,0),2)) VLICMSBCR,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECPSTGUIA,0),2)) VLFECPSTGUIA,
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0),2)) ELSE 0 END VLSUFRAMA, 
           CASE WHEN SUBSTR(FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),2,2) = '00' 
                     AND SUM(NVL(B.VLSUFRAMA,0)) > 0
                     AND SUM(NVL(B.BASEICMS,0)) = 0 THEN 
                SUM(ROUND(B.QTCONT * NVL(B.PUNITCONT,0),2)) ELSE 0 END VLBASESUFRAMA
      from PCNFENT      A,
           PCMOV        B,
           PCFORNEC     F,
           PCCFO        CF,
           PCMOVCOMPLE  MC,
           PCPRODUT     P,
           PCPRODFILIAL PF
     where NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
     AND NVL(B.CODFILIALNF, B.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
       and A.DTENT between P_DATA1 and P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and A.NUMTRANSENT = B.NUMTRANSENT
       and A.NUMNOTA = B.NUMNOTA
       and B.CODPROD = PF.CODPROD(+)
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.NUMTRANSITEM = MC.NUMTRANSITEM
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)) = F.CODFORNEC
       and P.CODPROD = B.CODPROD
       and A.TIPODESCARGA not in ('6', '8', 'F', 'N','P', 'C', 'T')
       and ( nvl(a.notadupliquesvc,'N') = 'N')
       and B.QTCONT = 0
       and A.Finalidadenfe = 'C'
       and (A.CHAVENFE is null or NVL(A.GERANFVENDA, 'N') = 'N')
       and B.STATUS in ('A', 'AB')
       and A.ESPECIE in ('NF', 'DA')
       --and A.DTENT >= (SELECT MIN(DTENT) FROM PCNFENT)
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSENT,
              A.DTENT,
              A.DTEMISSAO,
              A.ESPECIE,
              A.SERIE,
              A.NUMNOTA,
              CF.CODOPER,
              A.CHAVENFE,
              NVL(A.CODEXPORTADOR, NVL(A.CODFORNECNF, A.CODFORNEC)),
              F.FORNECEDOR,
              F.CGC,
              F.IE,
              F.ESTADO,
              A.FORNECEDOR,
              A.CGC,
              A.IE,
              A.UF,
              A.VLTOTAL,
              A.VLOUTRAS,
              SUBSTR(TO_CHAR(A.CODCONT), 1, 10),
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
              NVL(A.OBSLIVROFISCAL, A.OBS),
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              MC.PERDIFEREIMENTOICMS,
              NVL(B.PERCICM, 0),
              A.TIPODESCARGA,
              A.VLFRETE,
              A.VLOUTRAS,
              A.PERBASEREDOUTRASDESP,
             DECODE(NVL(B.CALCCREDIPI,'N'),'N',0,NVL(B.PERCIPI, 0)),
              B.ALIQUOTATIS,
              A.NFENTREGAFUTURA,
              B.CODOPER,
              B.DTCANCEL,
              A.SITUACAONFE
     order by DTENT,
              NUMTRANSENT,
              NUMNOTA;
 ------------------------------------------------------------------------------------------------------


  ---------------------------------------------------------------------------------
  TYPE LISTA_NOTAS IS TABLE OF  C_NOTAS_NFE%ROWTYPE;

  LISTA_NOTAS_IMPORTACAO LISTA_NOTAS;
  LISTA_NOTAS_DEVOLNF LISTA_NOTAS;
  LISTA_NOTAS_DEVOLNFE LISTA_NOTAS;
  LISTA_NOTAS_PCNFBASE_TIPO1 LISTA_NOTAS;
  LISTA_NOTAS_PCNFBASE_TIPO2 LISTA_NOTAS;
  LISTA_NOTAS_CONHECIMENTOFRETE LISTA_NOTAS;
  LISTA_NOTAS_NF LISTA_NOTAS;
  LISTA_NOTAS_NFE LISTA_NOTAS;
  LISTA_NOTAS_COMPLEMENTAR_ITEM LISTA_NOTAS;

  R_NOTA_TEMP c_notas_nfe%rowtype;
  --*********************************************************************************
  procedure INSERIR_REGISTRO_NOTA(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'INSERINDO REGISTRO (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    insert into PCNFBASEENT
      (CODFILIALNF,
       NUMTRANSENT,
       DTENTRADA,
       DTEMISSAO,
       ESPECIE,
       SERIE,
       NUMNOTA,
       CODFORNEC,
       FORNECEDOR,
       CGC,
       IE,
       UF,
       VLTOTAL,
       CODCONT,
       CODFISCAL,
       SITTRIBUT,
       CODOPER,
       PERCICM,
       PERCICMNAOTRIB,
       VLBASE,
       VLBASENAOTRIB,
       VLBASE_REDUCAO,
       VLFRETE,
       VLBASEFRETE,
       VLOUTRASDESP,
       VLBASEOUTRASDESP,
       VLICMS,
       VLICMSNAOTRIB,
       VLISENTAS,
       VLOUTRAS,
       OBS,
       VLDESDOBRADO,
       TIPODESCARGA,
       BASEST,
       VLST,
       VLBASEIPI,
       VLIPI,
       PERCIPI,
       VLBASEISENTASIPI,
       VLBASEOUTRASIPI,
       VLISENTASIPI,
       VLOUTRASIPI,
       VLPIS,
       VLCOFINS,
       BASESTFORANF,
       VLSTFORANF,
       ALIQUOTA,
       VLNAOTRIB_DAPI,
       VLBASERED_DAPI,
       VLSUSPENSAS_DAPI,
       VLST_DAPI,
       VLISENTAS_DAPI,
       VLOUTRAS_DAPI,
       DTGERA,
       VLFCP,
       VLICMSUFREM,
       VLICMSUFDESt,
       VLICMSDIFALIQPART,
       VLBASEPARTDEST,
       VLCREDPRESUMIDO,
       PERCIMPPRODUTORRURAL,
       VLDIFALIQUOTA,
       VLCREDITO_CIAP,
       vloutroscustoscusto,
       VLICMSANTECIPADO,
       VLIMPPRODUTORURAL,
       VLOUTROSCUSTOS,
       VLACRESCIMOFUNCEP,
       VLFECP,
       UFFILIAL,
       VLDESPFORANF,
       VLFRETECONHEC,
       PERACRESCIMOFUNCEP,
       VLBASEFCPICMS,
       VLBASEFCPST,
       ALIQICMSFECP,
       PERCREDBASEPISCOFINSFRETE,
       VLSTBCR,
       VLICMSBCR,
       VLFECPSTGUIA, 
       VLSUFRAMA, 
       VLBASESUFRAMA)
    values
      (P_NOTA.CODFILIAL,
       P_NOTA.NUMTRANSENT,
       P_NOTA.DTENT,
       P_NOTA.DTEMISSAO,
       P_NOTA.ESPECIE,
       P_NOTA.SERIE,
       P_NOTA.NUMNOTA,
       P_NOTA.CODFORNEC,
       P_NOTA.FORNECEDOR,
       P_NOTA.CNPJ,
       P_NOTA.IE,
       P_NOTA.UF,
       P_NOTA.VLTOTAL,
       P_NOTA.CODCONT,
       P_NOTA.CODFISCAL,
       P_NOTA.SITTRIBUT,
       P_NOTA.CODOPER,
       P_NOTA.PERCICM,
       P_NOTA.PERCICMNAOTRIB,
       P_NOTA.VLBASE + NVL(P_NOTA.VLBASEFRETE_RATEIO, 0),
       P_NOTA.VLBASENAOTRIB,
       P_NOTA.VLBASE_REDUCAO,
       NVL(P_NOTA.VLFRETE_PEDIDO, 0) + NVL(P_NOTA.VLFRETE_RATEIO, 0),
       NVL(P_NOTA.VLBASEFRETE_PEDIDO, 0) +
       NVL(P_NOTA.VLBASEFRETE_RATEIO, 0),
       NVL(P_NOTA.VLOUTRASDESP_PEDIDO, 0) + P_NOTA.VLOUTRASDESP_ITEM,
       NVL(P_NOTA.VLBASEOUTRASDESP_PEDIDO, 0),
       P_NOTA.VLICMS,
       P_NOTA.VLICMSNAOTRIB,
       P_NOTA.VLISENTAS,
       P_NOTA.VLOUTRAS,
       SUBSTR(P_NOTA.OBS, 1, V_TAMANHO_OBS),
       P_NOTA.VLDESDOBRADO + NVL(P_NOTA.VLFRETE_RATEIO, 0) +
       DECODE(P_NOTA.CHAVENFE, NULL, NVL(P_NOTA.VLFRETE_PEDIDO, 0) + NVL(P_NOTA.VLOUTRASDESP_PEDIDO, 0)+  NVL(P_NOTA.VLOUTRASDESP_ITEM, 0), 0),
       P_NOTA.TIPODESCARGA,
       P_NOTA.VLBASEST,
       P_NOTA.VLST,
       P_NOTA.VLBASEIPI,
       P_NOTA.VLIPI,
       P_NOTA.PERCIPI,
       P_NOTA.VLBASEISENTASIPI,
       DECODE(V_VALIDA_VALOR_OUTRAS_IPI, 'S', GREATEST(P_NOTA.VLDESDOBRADO -
                        NVL(P_NOTA.VLBASEIPI, 0) -
                        NVL(P_NOTA.VLIPI, 0) -
                        DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', (NVL(P_NOTA.VLST, 0) + NVL(P_NOTA.VLFECP, 0)), 0), 0), P_NOTA.VLBASEOUTRASIPI),
       P_NOTA.VLISENTASIPI,
       P_NOTA.VLOUTRASIPI,
       P_NOTA.VLPIS,
       P_NOTA.VLCOFINS,
       P_NOTA.VLBASESTFORANF,
       P_NOTA.VLSTFORANF,
       P_NOTA.ALIQUOTATIS,
       P_NOTA.VLNAOTRIB_DAPI,
       P_NOTA.VLBASERED_DAPI,
       P_NOTA.VLSUSPENSAS_DAPI,
       P_NOTA.VLST_DAPI,
       P_NOTA.VLISENTAS_DAPI,
       P_NOTA.VLOUTRAS_DAPI,
       P_NOTA.DTGERA,
       P_NOTA.VLFCP,
       P_NOTA.VLICMSPARTREM,
       P_NOTA.VLICMSPARTDEST,
       P_NOTA.VLICMSDIFALIQPART,
       P_NOTA.VLBASEPARTDEST,
       P_NOTA.VLCREDPRESUMIDO,
       P_NOTA.PERCIMPPRODUTORRURAL,
       P_NOTA.VLDIFALIQUOTA,
       P_NOTA.VLCREDITO_CIAP,
       P_NOTA.VLOUTROSCUSTOSCUSTO,
       P_NOTA.VLICMSANTECIPADO,
       P_NOTA.VLIMPPRODUTORURAL,
       P_NOTA.VLOUTROSCUSTOS,
       P_NOTA.VLACRESCIMOFUNCEP,
       P_NOTA.VLFECP,
       V_UFFILIAL,
       P_NOTA.VLDESPFORANF,
       P_NOTA.VLFRETECONHEC,
       P_NOTA.PERACRESCIMOFUNCEP,
       P_NOTA.VLBASEFCPICMS,
       P_NOTA.VLBASEFCPST,
       P_NOTA.ALIQICMSFECP,
       P_NOTA.PERCREDBASEPISCOFINSFRETE,
       P_NOTA.VLSTBCR,
       P_NOTA.VLICMSBCR,
       P_NOTA.VLFECPSTGUIA,
       P_NOTA.VLSUFRAMA, 
       P_NOTA.VLBASESUFRAMA);
  end;

  /*********************************************************************************/
  procedure GERAR_DESPESA_ACESSORIA(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    IF P_NOTA.CHAVENFE IS NOT NULL THEN
       RETURN;
    END IF;

    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO DEPESA ACESSORIA (NOTA ' || P_NOTA.NUMNOTA ||
                 ' EM ' || TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- DESPESA TRIBUTADA NOS ITENS
    if P_NOTA.TRIBUTA_DESPESA_ITEM = 'S'
    then
    ---------------------------------------------------------------------------------
      -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
      for DADOS in (select DECODE(NVL(CODFISCALOUTRASDESPENT, 0), 0, CODFISCAL, CODFISCALOUTRASDESPENT) CODFISCAL,
                           NVL(ALIQICMOUTRASDESPENT, 0) PERCICM,
                           sum(ROUND(QTCONT * VLOUTRASDESP, 2)) VLOUTRASDESP
                      from PCMOV
                     where NUMTRANSENT = P_NOTA.NUMTRANSENT
                       and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_NOTA.CODFILIAL
                       and DTCANCEL is null
                       and STATUS in ('A', 'AB')
                       and QTCONT > 0
                       and VLOUTRASDESP > 0
                     group by DECODE(NVL(CODFISCALOUTRASDESPENT, 0), 0, CODFISCAL, CODFISCALOUTRASDESPENT),
                              NVL(ALIQICMOUTRASDESPENT, 0))
      loop
        update PCNFBASEENT A
           set VLBASE           = VLBASE +
                                  DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLOUTRASDESP),
               VLICMS           = VLICMS + DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLOUTRASDESP) *
                                  DADOS.PERCICM / 100,
               VLDESDOBRADO     = VLDESDOBRADO + DADOS.VLOUTRASDESP,
               VLBASEOUTRASDESP = NVL(VLBASEOUTRASDESP, 0) +
                                  DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLOUTRASDESP),
               VLOUTRASDESP     = NVL(VLOUTRASDESP, 0) + DADOS.VLOUTRASDESP
         where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFISCAL = DADOS.CODFISCAL
           and A.PERCICM = DADOS.PERCICM
           and ROWNUM = 1;
        ---------------------------------------------------------------------------------
        if sql%rowcount = 0
        then
          -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
          insert into PCNFBASEENT
            (CODFILIALNF,
             NUMTRANSENT,
             DTENTRADA,
             DTEMISSAO,
             ESPECIE,
             SERIE,
             NUMNOTA,
             CODFORNEC,
             FORNECEDOR,
             CGC,
             IE,
             UF,
             VLTOTAL,
             CODCONT,
             CODFISCAL,
             SITTRIBUT,
             CODOPER,
             PERCICM,
             VLBASE,
             VLBASENAOTRIB,
             VLBASE_REDUCAO,
             VLOUTRASDESP,
             VLBASEOUTRASDESP,
             VLICMS,
             VLISENTAS,
             VLOUTRAS,
             OBS,
             VLDESDOBRADO,
             TIPODESCARGA,
             BASEST,
             VLST,
             VLBASEIPI,
             VLIPI,
             PERCIPI,
             ALIQDIF,
             ALIQUOTA,
             DTGERA,
             TIPOREGISTRO)
            select P_NOTA.CODFILIAL,
                   P_NOTA.NUMTRANSENT,
                   P_NOTA.DTENT,
                   P_NOTA.DTEMISSAO,
                   P_NOTA.ESPECIE,
                   P_NOTA.SERIE,
                   P_NOTA.NUMNOTA,
                   P_NOTA.CODFORNEC,
                   P_NOTA.FORNECEDOR,
                   P_NOTA.CNPJ,
                   P_NOTA.IE,
                   P_NOTA.UF,
                   P_NOTA.VLTOTAL,
                   P_NOTA.CODCONT,
                   DADOS.CODFISCAL,
                   '090' SITTRIBUT,
                   P_NOTA.CODOPER,
                   DADOS.PERCICM,
                   DECODE(DADOS.PERCICM, 0, 0, DADOS.VLOUTRASDESP) BASEICMS,
                   0 VLBASENAOTRIB,
                   DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                           P_NOTA.VLBASEOUTRASDESP),
                   DADOS.VLOUTRASDESP,
                   DECODE(DADOS.PERCICM, 0, 0, DADOS.VLOUTRASDESP) VLBASEOUTRASDESP,
                   DECODE(DADOS.PERCICM, 0, 0, DADOS.VLOUTRASDESP) *
                   (DADOS.PERCICM / 100) VLICMS,
                   0 VLISENTAS,
                   0 VLOUTRAS,
                   'DESP.ACESSORIA' OBS,
                   DADOS.VLOUTRASDESP VLDESDOBRADO,
                   P_NOTA.TIPODESCARGA,
                   0 BASEST,
                   0 VLST,
                   0 VLBASEIPI,
                   0 VLIPI,
                   0 PERCIPI,
                   0 ALIQDIF,
                   0 ALIQUOTA,
                   sysdate DTGERA,
                   'D' TIPOREGISTRO
              from DUAL
             where not exists (select NUMNOTA
                      from PCNFBASEENT
                     where NUMTRANSENT = P_NOTA.NUMTRANSENT
                       and NUMNOTA = P_NOTA.NUMNOTA
                       and CODFISCAL = DADOS.CODFISCAL
                       and PERCICM = DADOS.PERCICM);
        end if;
      end loop;
      return;
    end if;
    ---------------------------------------------------------------------------------
    -- DESPESAS ACESSORIAS POR PARAMETROS GERAIS
    ---------------------------------------------------------------------------------
    -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
    if (V_TIPOALIQOUTRASDESP in ('P', 'F'))
    then
      update PCNFBASEENT A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE + P_NOTA.VLBASEOUTRASDESP,
             A.VLICMS           = A.VLICMS + NVL(P_NOTA.VLBASEOUTRASDESP, 0) *
                                  A.PERCICM / 100,
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          P_NOTA.VLBASEOUTRASDESP),
             A.VLOUTRASDESP     = NVL(A.VLOUTRASDESP, 0) +
                                  P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = NVL(A.VLBASEOUTRASDESP, 0) +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL =
             DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALOUTRASDESP, V_CODFISCALINTEROUTRASDESP)
         and A.PERCICM =
             DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP)
         and ROWNUM = 1;
      ---------------------------------------------------------------------------------
      if sql%rowcount = 0
      then
        -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
        insert into PCNFBASEENT
          (CODFILIALNF,
           NUMTRANSENT,
           DTENTRADA,
           DTEMISSAO,
           ESPECIE,
           SERIE,
           NUMNOTA,
           CODFORNEC,
           FORNECEDOR,
           CGC,
           IE,
           UF,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           PERCICM,
           VLBASE,
           VLBASENAOTRIB,
           VLBASE_REDUCAO,
           VLOUTRASDESP,
           VLBASEOUTRASDESP,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPODESCARGA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           ALIQDIF,
           ALIQUOTA,
           DTGERA,
           TIPOREGISTRO)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSENT,
                 P_NOTA.DTENT,
                 P_NOTA.DTEMISSAO,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.CODFORNEC,
                 P_NOTA.FORNECEDOR,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALOUTRASDESP, V_CODFISCALINTEROUTRASDESP) CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP) PERCICM,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) BASEICMS,
                 0 VLBASENAOTRIB,
                 DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                         P_NOTA.VLBASEOUTRASDESP),
                 P_NOTA.VLOUTRASDESP,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'DESP.ACESSORIA' OBS,
                 P_NOTA.VLOUTRASDESP VLDESDOBRADO,
                 P_NOTA.TIPODESCARGA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 0 ALIQDIF,
                 0 ALIQUOTA,
                 sysdate DTGERA,
                 'D' TIPOREGISTRO
            from DUAL
           where not exists
           (select B.NUMNOTA
                    from PCNFBASEENT B
                   where B.NUMTRANSENT = P_NOTA.NUMTRANSENT
                     and B.NUMNOTA = P_NOTA.NUMNOTA
                     and B.CODFISCAL =
                         DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALOUTRASDESP, V_CODFISCALINTEROUTRASDESP)
                     and B.PERCICM =
                         DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP));
      end if;
    end if;
    ---------------------------------------------------------------------------------
    -- DESPESAS ACESSORIAS ATRAVES DE TRIBUTACAO POR ESTADO
    ---------------------------------------------------------------------------------
    -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
    if (V_TIPOALIQOUTRASDESP = 'T')
    then
      update PCNFBASEENT A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE + P_NOTA.VLBASEOUTRASDESP,
             A.VLICMS           = DECODE(A.VLICMS, 0, 0, A.VLICMS +
                                          P_NOTA.VLBASEOUTRASDESP *
                                          A.PERCICM / 100),
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          P_NOTA.VLBASEOUTRASDESP),
             A.VLOUTRASDESP     = NVL(A.VLOUTRASDESP, 0) +
                                  P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = NVL(A.VLBASEOUTRASDESP, 0) +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and ROWNUM = 1
         and exists
       (select T.CODFILIALNF
                from PCTRIBOUTROS T
               where T.UFDESTINO = A.UF
                 and T.CODFILIALNF = A.CODFILIALNF
                 and (case when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                      DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', T.CODFISCALDEVOUTRASDESP, T.CODFISCALDEVOUTRASDESPPF) else
                      T.CODFISCALOUTRASDESPENT end) = A.CODFISCAL
                 and (case when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                      DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0)) else
                      NVL(T.ALIQICMOUTRASDESPENT, 0) end) = A.PERCICM);
      ---------------------------------------------------------------------------------
      if sql%rowcount = 0
      then
        -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
        insert into PCNFBASEENT
          (CODFILIALNF,
           NUMTRANSENT,
           DTENTRADA,
           DTEMISSAO,
           ESPECIE,
           SERIE,
           NUMNOTA,
           CODFORNEC,
           FORNECEDOR,
           CGC,
           IE,
           UF,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           PERCICM,
           VLBASE,
           VLBASENAOTRIB,
           VLBASE_REDUCAO,
           VLOUTRASDESP,
           VLBASEOUTRASDESP,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPODESCARGA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           ALIQDIF,
           ALIQUOTA,
           DTGERA,
           TIPOREGISTRO)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSENT,
                 P_NOTA.DTENT,
                 P_NOTA.DTEMISSAO,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.CODFORNEC,
                 P_NOTA.FORNECEDOR,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 (case
                   when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                    DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', T.CODFISCALDEVOUTRASDESP, T.CODFISCALDEVOUTRASDESPPF)
                   else
                    T.CODFISCALOUTRASDESPENT
                 end) CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 (case
                   when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                    DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0))
                   else
                    NVL(T.ALIQICMOUTRASDESPENT, 0)
                 end) PERCICM,
                 DECODE((case
                          when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                           DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0))
                          else
                           NVL(T.ALIQICMOUTRASDESPENT, 0)
                        end), 0, 0, P_NOTA.VLBASEOUTRASDESP) BASEICMS,
                 0 VLBASENAOTRIB,
                 DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                         P_NOTA.VLBASEOUTRASDESP),
                 P_NOTA.VLOUTRASDESP,
                 DECODE((case
                          when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                           DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0))
                          else
                           NVL(T.ALIQICMOUTRASDESPENT, 0)
                        end), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'DESP.ACESSORIA' OBS,
                 P_NOTA.VLOUTRASDESP VLDESDOBRADO,
                 P_NOTA.TIPODESCARGA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 0 ALIQDIF,
                 0 ALIQUOTA,
                 sysdate DTGERA,
                 'D' TIPOREGISTRO
            from PCTRIBOUTROS T
           where T.UFDESTINO = P_NOTA.UF
             and T.CODFILIALNF = P_NOTA.CODFILIAL
             and not exists
           (select NUMNOTA
                    from PCNFBASEENT
                   where NUMTRANSENT = P_NOTA.NUMTRANSENT
                     and NUMNOTA = P_NOTA.NUMNOTA
                     and (case when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                          DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', T.CODFISCALDEVOUTRASDESP, T.CODFISCALDEVOUTRASDESPPF) else
                          T.CODFISCALOUTRASDESPENT end) = CODFISCAL
                     and (case when P_NOTA.TIPODESCARGA in ('6', '8', 'T') then
                          DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0)) else
                          NVL(T.ALIQICMOUTRASDESPENT, 0) end) = PERCICM);
      end if;
    end if;
    ---------------------------------------------------------------------------------
    -- DESPESAS ACESSORIAS PEGANDO O MENOR CFOP DOS ITENS
    ---------------------------------------------------------------------------------
    -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
    if (V_TIPOALIQOUTRASDESP = 'N')
    then
        IF P_NOTA.TIPODESCARGA  in ('6', '8', 'T') THEN
        update PCNFBASEENT A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE + P_NOTA.VLBASEOUTRASDESP,
             A.VLICMS           = A.VLICMS + NVL(P_NOTA.VLBASEOUTRASDESP, 0) *
                                  NVL(A.PERCICM, 0) / 100,
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          P_NOTA.VLBASEOUTRASDESP),
             A.VLOUTRASDESP     = NVL(A.VLOUTRASDESP, 0) +
                                  P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = NVL(A.VLBASEOUTRASDESP, 0) +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL = (select min(CODFISCAL)
                              from PCNFBASEENT
                             where NUMTRANSENT = A.NUMTRANSENT
                               and NUMNOTA = A.NUMNOTA)

         and A.PERCICM = P_NOTA.PERCICM
         and ROWNUM = 1;

    ELSE

      update PCNFBASEENT A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE + P_NOTA.VLBASEOUTRASDESP,
             A.VLICMS           = A.VLICMS + NVL(P_NOTA.VLBASEOUTRASDESP, 0) *
                                  NVL(A.PERCICM, 0) / 100,
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          P_NOTA.VLBASEOUTRASDESP),
             A.VLOUTRASDESP     = NVL(A.VLOUTRASDESP, 0) +
                                  P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = NVL(A.VLBASEOUTRASDESP, 0) +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL = (select min(CODFISCAL)
                              from PCNFBASEENT
                             where NUMTRANSENT = A.NUMTRANSENT
                               and NUMNOTA = A.NUMNOTA)
         and A.PERCICM =
             DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP)
         and ROWNUM = 1;
      END IF;
      ---------------------------------------------------------------------------------
      if sql%rowcount = 0
      then
        -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
        insert into PCNFBASEENT
          (CODFILIALNF,
           NUMTRANSENT,
           DTENTRADA,
           DTEMISSAO,
           ESPECIE,
           SERIE,
           NUMNOTA,
           CODFORNEC,
           FORNECEDOR,
           CGC,
           IE,
           UF,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           PERCICM,
           VLBASE,
           VLBASENAOTRIB,
           VLBASE_REDUCAO,
           VLOUTRASDESP,
           VLBASEOUTRASDESP,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPODESCARGA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           ALIQDIF,
           ALIQUOTA,
           DTGERA,
           TIPOREGISTRO)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSENT,
                 P_NOTA.DTENT,
                 P_NOTA.DTEMISSAO,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.CODFORNEC,
                 P_NOTA.FORNECEDOR,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 A.CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP) PERCICM,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) BASEICMS,
                 0 VLBASENAOTRIB,
                 DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                         P_NOTA.VLBASEOUTRASDESP),
                 P_NOTA.VLOUTRASDESP,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'DESP.ACESSORIA' OBS,
                 P_NOTA.VLOUTRASDESP VLDESDOBRADO,
                 P_NOTA.TIPODESCARGA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 0 ALIQDIF,
                 0 ALIQUOTA,
                 sysdate DTGERA,
                 'D' TIPOREGISTRO
            from PCNFBASEENT A
           where NUMTRANSENT = P_NOTA.NUMTRANSENT
             and NUMNOTA = P_NOTA.NUMNOTA
             and CODFISCAL = (select min(CODFISCAL)
                                from PCNFBASEENT
                               where NUMTRANSENT = P_NOTA.NUMTRANSENT
                                 and NUMNOTA = P_NOTA.NUMNOTA)
             and ROWNUM = 1;
      end if;
    end if;
  end;

  --*********************************************************************************
  procedure GERAR_FRETE(P_NOTA in out C_NOTAS_NF%rowtype) is
  begin
    IF P_NOTA.CHAVENFE IS NOT NULL THEN
       RETURN;
    END IF;
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO FRETE (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- FRETE TRIBUTADO NOS ITENS
    if P_NOTA.TRIBUTA_FRETE_ITEM = 'S'
    then
      ---------------------------------------------------------------------------------
      -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
      for DADOS in (select CODFISCALFRETEENT CODFISCAL,
                           NVL(ALIQICMFRETEENT, 0) PERCICM,
                           sum(QTCONT * VLFRETE) VLFRETE
                      from PCMOV
                     where NUMTRANSENT = P_NOTA.NUMTRANSENT
                       and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_NOTA.CODFILIAL
                       and DTCANCEL is null
                       and STATUS in ('A', 'AB')
                       and QTCONT > 0
                       and VLFRETE > 0
                       and CODFISCALFRETEENT > 0
                     group by CODFISCALFRETEENT,
                              NVL(ALIQICMFRETEENT, 0))
      loop
        update PCNFBASEENT A
           set VLBASE       = VLBASE +
                              DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLFRETE),
               VLICMS       = VLICMS + DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLFRETE) *
                              NVL(PERCICM, 0) / 100,
               VLDESDOBRADO = VLDESDOBRADO + DADOS.VLFRETE,
               VLBASEFRETE  = NVL(VLBASEFRETE, 0) +
                              DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLFRETE),
               VLFRETE      = NVL(VLFRETE, 0) + DADOS.VLFRETE
         where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFISCAL = DADOS.CODFISCAL
           and A.PERCICM = DADOS.PERCICM
           and ROWNUM = 1;
        ---------------------------------------------------------------------------------
        if sql%rowcount = 0
        then
          -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
          insert into PCNFBASEENT
            (CODFILIALNF,
             NUMTRANSENT,
             ESPECIE,
             SERIE,
             NUMNOTA,
             DTENTRADA,
             CODFORNEC,
             PERCICM,
             FORNECEDOR,
             CGC,
             IE,
             UF,
             VLTOTAL,
             CODCONT,
             CODFISCAL,
             SITTRIBUT,
             CODOPER,
             VLBASE,
             VLBASENAOTRIB,
             VLFRETE,
             VLBASEFRETE,
             VLICMS,
             VLISENTAS,
             VLOUTRAS,
             OBS,
             VLDESDOBRADO,
             TIPODESCARGA,
             BASEST,
             VLST,
             VLBASEIPI,
             VLIPI,
             PERCIPI,
             DTGERA,
             TIPOREGISTRO,
             PERCREDBASEPISCOFINSFRETE)
            select P_NOTA.CODFILIAL,
                   P_NOTA.NUMTRANSENT,
                   P_NOTA.ESPECIE,
                   P_NOTA.SERIE,
                   P_NOTA.NUMNOTA,
                   P_NOTA.DTENT,
                   P_NOTA.CODFORNEC,
                   DADOS.PERCICM,
                   P_NOTA.FORNECEDOR,
                   P_NOTA.CNPJ,
                   P_NOTA.IE,
                   P_NOTA.UF,
                   P_NOTA.VLTOTAL,
                   P_NOTA.CODCONT,
                   DADOS.CODFISCAL,
                   '090' SITTRIBUT,
                   P_NOTA.CODOPER,
                   DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLFRETE) BASEICMS,
                   0 VLBASENAOTRIB,
                   DADOS.VLFRETE,
                   DECODE(NVL(DADOS.PERCICM, 0), 0, 0, DADOS.VLFRETE) VLBASEFRETE,
                   0 VLICMS,
                   0 VLISENTAS,
                   0 VLOUTRAS,
                   'FRETE' OBS,
                   DADOS.VLFRETE VLDESDOBRADO,
                   P_NOTA.TIPODESCARGA,
                   0 BASEST,
                   0 VLST,
                   0 VLBASEIPI,
                   0 VLIPI,
                   0 PERCIPI,
                   P_NOTA.DTGERA,
                   'F',
                   P_NOTA.PERCREDBASEPISCOFINSFRETE
              from DUAL
             where not exists (select NUMNOTA
                      from PCNFBASEENT
                     where NUMTRANSENT = P_NOTA.NUMTRANSENT
                       and NUMNOTA = P_NOTA.NUMNOTA
                       and CODFISCAL = DADOS.CODFISCAL
                       and PERCICM = DADOS.PERCICM);
        end if;
      end loop;
      return;
    end if;
    ---------------------------------------------------------------------------------
    -- FRETE ATRAVES DOS PARAMETROS GERAIS
    ---------------------------------------------------------------------------------
    -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
    if V_TIPOALIQOUTRASDESP in ('P', 'F')
    then
      update PCNFBASEENT A
         set VLBASE       = VLBASE +
                            DECODE(NVL(A.PERCICM, 0), 0, 0, P_NOTA.VLFRETE),
             VLICMS       = VLICMS + DECODE(NVL(A.PERCICM, 0), 0, 0, P_NOTA.VLFRETE) *
                            NVL(PERCICM, 0) / 100,
             VLDESDOBRADO = VLDESDOBRADO + P_NOTA.VLFRETE,
             VLBASEFRETE  = NVL(VLBASEFRETE, 0) +
                            DECODE(NVL(A.PERCICM, 0), 0, 0, P_NOTA.VLFRETE),
             VLFRETE      = NVL(VLFRETE, 0) + P_NOTA.VLFRETE
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL =
             DECODE(P_NOTA.UF, V_UFFILIAL, V_CODFISCALFRETE, V_CODFISCALINTERFRETE)
         and A.PERCICM =
             DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE)
         and ROWNUM = 1;
      ---------------------------------------------------------------------------------
      if sql%rowcount = 0
      then
        -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
        insert into PCNFBASEENT
          (CODFILIALNF,
           NUMTRANSENT,
           ESPECIE,
           SERIE,
           NUMNOTA,
           DTENTRADA,
           CODFORNEC,
           PERCICM,
           FORNECEDOR,
           CGC,
           IE,
           UF,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASENAOTRIB,
           VLFRETE,
           VLBASEFRETE,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPODESCARGA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           DTGERA,
           TIPOREGISTRO,
           PERCREDBASEPISCOFINSFRETE)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSENT,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.DTENT,
                 P_NOTA.CODFORNEC,
                 DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE) PERCICM,
                 P_NOTA.FORNECEDOR,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 DECODE(P_NOTA.UF, V_UFFILIAL, V_CODFISCALFRETE, V_CODFISCALINTERFRETE) CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) BASEICMS,
                 0 VLBASENAOTRIB,
                 P_NOTA.VLFRETE,
                 DECODE(DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) VLBASEFRETE,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'FRETE' OBS,
                 P_NOTA.VLFRETE VLDESDOBRADO,
                 P_NOTA.TIPODESCARGA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 P_NOTA.DTGERA,
                 'F',
                 P_NOTA.PERCREDBASEPISCOFINSFRETE
            from DUAL
           where not exists
           (select NUMNOTA
                    from PCNFBASEENT
                   where NUMTRANSENT = P_NOTA.NUMTRANSENT
                     and NUMNOTA = P_NOTA.NUMNOTA
                     and CODFISCAL =
                         DECODE(P_NOTA.UF, V_UFFILIAL, V_CODFISCALFRETE, V_CODFISCALINTERFRETE)
                     and PERCICM =
                         DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE));
      end if;
    end if;
    ---------------------------------------------------------------------------------
    -- FRETE ATRAVES DE TRIBUTACAO POR ESTADO
    ---------------------------------------------------------------------------------
    -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
    if V_TIPOALIQOUTRASDESP = 'T'
    then
      update PCNFBASEENT A
         set VLBASE       = VLBASE + DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE),
             VLICMS       = VLICMS + DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE) *
                            NVL(PERCICM, 0) / 100,
             VLDESDOBRADO = VLDESDOBRADO + P_NOTA.VLFRETE,
             VLBASEFRETE  = NVL(VLBASEFRETE, 0) +
                            DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE),
             VLFRETE      = NVL(VLFRETE, 0) + P_NOTA.VLFRETE
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and V_TRIBUTAFRETERATEADO = 'N'
         and ROWNUM = 1
         and exists (select CODFILIALNF
                from PCTRIBOUTROS
               where CODFILIALNF = P_NOTA.CODFILIAL
                 and UFDESTINO = P_NOTA.UF
                 and CODFISCALFRETEENT = A.CODFISCAL
                 and ALIQICMFRETEENT = A.PERCICM);
      ---------------------------------------------------------------------------------
      if sql%rowcount = 0
      then
        -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
        insert into PCNFBASEENT
          (CODFILIALNF,
           NUMTRANSENT,
           ESPECIE,
           SERIE,
           NUMNOTA,
           DTENTRADA,
           CODFORNEC,
           PERCICM,
           FORNECEDOR,
           CGC,
           IE,
           UF,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASENAOTRIB,
           VLFRETE,
           VLBASEFRETE,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPODESCARGA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           DTGERA,
           TIPOREGISTRO,
           PERCREDBASEPISCOFINSFRETE)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSENT,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.DTENT,
                 P_NOTA.CODFORNEC,
                 T.ALIQICMFRETEENT PERCICM,
                 P_NOTA.FORNECEDOR,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 T.CODFISCALFRETEENT CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(T.ALIQICMFRETEENT, 0, 0, P_NOTA.VLFRETE) BASEICMS,
                 0 VLBASENAOTRIB,
                 P_NOTA.VLFRETE,
                 DECODE(T.ALIQICMFRETEENT, 0, 0, P_NOTA.VLFRETE) VLBASEFRETE,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 SUBSTR(P_NOTA.OBS, 1, V_TAMANHO_OBS),
                 P_NOTA.VLFRETE VLDESDOBRADO,
                 P_NOTA.TIPODESCARGA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 P_NOTA.DTGERA,
                 'F',
                 P_NOTA.PERCREDBASEPISCOFINSFRETE
            from PCTRIBOUTROS T
           where V_TRIBUTAFRETERATEADO = 'N'
             and T.UFDESTINO = P_NOTA.UF
             and T.CODFILIALNF = P_NOTA.CODFILIAL
             and not exists
           (select B.NUMNOTA
                    from PCNFBASEENT B
                   where B.NUMTRANSENT = P_NOTA.NUMTRANSENT
                     and B.NUMNOTA = P_NOTA.NUMNOTA
                     and B.CODFISCAL = T.CODFISCALFRETEENT
                     and B.PERCICM = T.ALIQICMFRETEENT);
      end if;
    end if;
    ---------------------------------------------------------------------------------
    -- FRETE ATRAVES DO MENOR CFOP DOS ITENS
    ---------------------------------------------------------------------------------
    -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
    if V_TIPOALIQOUTRASDESP = 'N'
    then
      update PCNFBASEENT A
         set VLBASE       = VLBASE +
                            DECODE(A.PERCICM, 0, 0, P_NOTA. VLFRETE),
             VLICMS       = VLICMS + DECODE(A.PERCICM, 0, 0, P_NOTA. VLFRETE) *
                            NVL(PERCICM, 0) / 100,
             VLDESDOBRADO = VLDESDOBRADO + P_NOTA.VLFRETE,
             VLBASEFRETE  = NVL(VLBASEFRETE, 0) +
                            DECODE(DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE),
             VLFRETE      = NVL(VLFRETE, 0) + P_NOTA.VLFRETE
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL = (select min(CODFISCAL)
                              from PCNFBASEENT
                             where NUMTRANSENT = A.NUMTRANSENT
                               and NUMNOTA = A.NUMNOTA)
         and A.PERCICM =
             DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE)
         and ROWNUM = 1;
      ---------------------------------------------------------------------------------
      if sql%rowcount = 0
      then
        -- INCLUIR SE NAO EXISTIR CFOP/ALIQUOTA
        insert into PCNFBASEENT
          (CODFILIALNF,
           NUMTRANSENT,
           ESPECIE,
           SERIE,
           NUMNOTA,
           DTENTRADA,
           CODFORNEC,
           PERCICM,
           FORNECEDOR,
           CGC,
           IE,
           UF,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASENAOTRIB,
           VLFRETE,
           VLBASEFRETE,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPODESCARGA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           DTGERA,
           TIPOREGISTRO,
           PERCREDBASEPISCOFINSFRETE)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSENT,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.DTENT,
                 P_NOTA.CODFORNEC,
                 DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE) PERCICM,
                 P_NOTA.FORNECEDOR,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 A.CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) BASEICMS,
                 0 VLBASENAOTRIB,
                 P_NOTA.VLFRETE,
                 DECODE(DECODE(P_NOTA.UF, V_UFFILIAL, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) VLBASEFRETE,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'FRETE' OBS,
                 P_NOTA.VLFRETE VLDESDOBRADO,
                 P_NOTA.TIPODESCARGA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 P_NOTA.DTGERA,
                 'F',
                 P_NOTA.PERCREDBASEPISCOFINSFRETE
            from PCNFBASEENT A
           where NUMTRANSENT = P_NOTA.NUMTRANSENT
             and NUMNOTA = P_NOTA.NUMNOTA
             and CODFISCAL = (select min(CODFISCAL)
                                from PCNFBASEENT
                               where NUMTRANSENT = P_NOTA.NUMTRANSENT
                                 and NUMNOTA = P_NOTA.NUMNOTA)
             and ROWNUM = 1;
      end if;
    end if;
  end;

/*********************************************************************************/
PROCEDURE GERAR_DESPESA_IMPORTACAO(P_NOTA IN OUT C_NOTAS_NF%ROWTYPE) IS
  BEGIN
    ---------------------------------------------------------------------------------
    -- GRAVAR VALORES DE DESPESA REFERENTES AS NOTAS DE IMPORTACAO = TIPODESCARGA = 'N'
    --------------------------------------------------------------------------
    FOR DADOS IN (SELECT M.CODFISCAL,
                         FISCAL.FORMATAR_CST_ICMS(M.SITTRIBUT, NVL(M.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
                         CASE WHEN (NVL(M.PERCDESCICMSDIF, MC.PERDIFEREIMENTOICMS) >= 100) THEN
                           0
                         ELSE
                           DECODE(NVL(M.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(M.PERCICM, 0))
                         END PERCICM,
                         ROUND(SUM(QTCONT * NVL(M.VLSISCOMEX,0)),2) VLSISCOMEX,
                         ROUND(SUM(QTCONT * NVL(M.VLIMPORTACAO,0)),2) VLIMPORTACAO,
                         ROUND(SUM(QTCONT * NVL(MC.VLCAPATAZIA,0)),2) VLCAPATAZIA,
                         ROUND(SUM(QTCONT * NVL(MC.VLAFRMM,0)),2) VLAFRMM,
                         ROUND(SUM(QTCONT * NVL(M.VLSEGURO,0)),2) VLSEGURO,
                         ROUND(SUM(QTCONT * NVL(M.VLADUANEIRA,0)),2)VLADUANEIRA,
                         ROUND(SUM(QTCONT * NVL(M.VLOUTRASDESPIMP,0)),2) VLOUTRASDESPIMP,
                         ROUND(SUM(QTCONT * NVL(MC.VLANTIDUMPING,0)),2) VLANTIDUMPING,
                         ROUND(SUM(QTCONT * NVL(MC.VLPISCALCDI,0)),2) VLPISCALCDI,
                         ROUND(SUM(QTCONT * NVL(MC.VLCOFINSCALCDI,0)),2) VLCOFINSCALCDI,
                         ROUND(SUM(QTCONT * NVL(M.VLFRETE,0)),2) VLFRETE,
                         ROUND(SUM(M.QTCONT * NVL(M.VLCREDPRESUMIDO,0)),2) VLCREDPRESUMIDO
                  FROM PCMOV M,
                       PCMOVCOMPLE MC,
                       PCNFENT A,
                       PCPRODUT P,
                       PCPRODFILIAL PF
                  WHERE A.NUMTRANSENT = P_NOTA.NUMTRANSENT
                    AND M.NUMTRANSENT = A.NUMTRANSENT
                    AND M.CODPROD = P.CODPROD
          AND NVL(M.CODFILIALNF, M.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
                    AND M.CODFILIAL = PF.CODFILIAL(+)
                    AND M.CODPROD = PF.CODPROD(+)
                    AND M.NUMTRANSITEM = MC.NUMTRANSITEM
                  GROUP BY M.GERAICMSLIVROFISCAL, M.CODFISCAL, M.SITTRIBUT, M.PERCICM,
                    FISCAL.FORMATAR_CST_ICMS(M.SITTRIBUT, NVL(M.IMPORTADO, P.IMPORTADO),
                    NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
                    M.PERCDESCICMSDIF, MC.PERDIFEREIMENTOICMS)
    LOOP
      UPDATE PCNFBASEENT A
         SET VLSISCOMEX      = NVL(VLSISCOMEX, 0) + DADOS.VLSISCOMEX,
             VLIMPORTACAO    = NVL(VLIMPORTACAO, 0) + DADOS.VLIMPORTACAO,
             VLCAPATAZIA     = NVL(VLCAPATAZIA, 0) + DADOS.VLCAPATAZIA,
             VLAFRMM         = NVL(VLAFRMM, 0) + DADOS.VLAFRMM,
             VLSEGURO        = NVL(VLSEGURO, 0) + DADOS.VLSEGURO,
             VLADUANEIRA     = NVL(VLADUANEIRA, 0) + DADOS.VLADUANEIRA,
             VLOUTRASDESPIMP = NVL(VLOUTRASDESPIMP, 0) + DADOS.VLOUTRASDESPIMP,
             VLANTIDUMPING   = NVL(VLANTIDUMPING, 0) + DADOS.VLANTIDUMPING,
             VLPISCALCDI     = NVL(VLPISCALCDI, 0) + DADOS.VLPISCALCDI,
             VLCOFINSCALCDI  = NVL(VLCOFINSCALCDI, 0) + DADOS.VLCOFINSCALCDI,
             VLFRETECONT     = NVL(VLFRETECONT, 0) + DADOS.VLFRETE,
             VLCREDPRESUMIDO = NVL(VLCREDPRESUMIDO, 0) + DADOS.VLCREDPRESUMIDO

      WHERE NUMTRANSENT = P_NOTA.NUMTRANSENT
        AND NUMNOTA = P_NOTA.NUMNOTA
        AND CODFISCAL = DADOS.CODFISCAL
        AND ROUND(PERCICM,2) = ROUND(DADOS.PERCICM,2)
        AND SITTRIBUT = DADOS.SITTRIBUT
        AND ROWNUM = 1;

      V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
      IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
        V_CONTADORREGISTRO := 0;
        COMMIT;
      END IF;

    END LOOP;
  END;
/*********************************************************************************/
  procedure CALCULAR_ICMS(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    ---------------------------------------------------------------------------------
    -- CALCULAR ICMS
    if P_NOTA.TIPODESCARGA not in ('F', 'N','P')
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'CALCULANDO VALOR DO ICMS (NOTA ' || P_NOTA.NUMNOTA ||
                   ' EM ' || TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
/*N?O EXISTE A NECESSIDADE DE RECALCULAR O VLICMS POIS TODOS OS SQL DEVEM CHAMAR A FISCAL.GET_DADOS_ICMS

       update PCNFBASEENT
         set VLICMS = VLBASE * NVL(PERCICM, 0) / 100
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and VLICMS = 0;

*/

      update PCNFBASEENT
         set VLICMSNAOTRIB = VLBASENAOTRIB * NVL(PERCICMNAOTRIB, 0) / 100
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and NVL(VLICMSNAOTRIB, 0) = 0;
    end if;
  end;

PROCEDURE INSERIROBSERVACAOICMS(P_NOTA IN C_NOTAS_NF%ROWTYPE) IS
  V_BASEICMS_MANIF  VARCHAR2(19);
  V_PERCICM_MANIF    VARCHAR2(19);
  V_VLICMS_MANIF    VARCHAR2(19);

  V_MENSAGEM        VARCHAR2(200);
BEGIN
  --------------HIS.01724.2016 - Eddy---------------------------------------------------------------------
  --MELHORIA PARA PASSAR A GRAVAR OS DADOS DE ICMS NA OBSERVAÇÃO DO LIVRO QUANDO NOVO PROCESSO DO VENDAS
  IF (V_DESTACAR_ICMS_DEVOL_TV13 = 'S') THEN
    SELECT TO_CHAR(NVL(PCMOVCOMPLE.BASEICMS_MANIF,0), 'FM9999999999999999990.00'),
           TO_CHAR(NVL(PCMOVCOMPLE.PERCICM_MANIF,0), 'FM9999999999999999990.00'),
           TO_CHAR(NVL(PCMOVCOMPLE.VLICMS_MANIF,0), 'FM9999999999999999990.00')
      INTO V_BASEICMS_MANIF,
           V_PERCICM_MANIF,
           V_VLICMS_MANIF
      FROM PCMOV,
           PCMOVCOMPLE
     WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
       AND PCMOV.NUMTRANSENT = P_NOTA.NUMTRANSENT
       AND NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_NOTA.CODFILIAL;

     V_MENSAGEM  := ' ';

     IF V_BASEICMS_MANIF > 0 THEN
        V_MENSAGEM  := V_MENSAGEM  || 'BASE DE ICMS: ' || V_BASEICMS_MANIF || ' ';
     END IF;

     IF V_PERCICM_MANIF > 0 THEN
        V_MENSAGEM  := V_MENSAGEM  || 'ALIQUOTA DE ICMS: ' || V_PERCICM_MANIF || ' ';
     END IF;

     IF V_VLICMS_MANIF > 0 THEN
        V_MENSAGEM  := V_MENSAGEM  || 'VALOR DE ICMS: ' || V_VLICMS_MANIF || ' ';
     END IF;

     IF TRIM(V_MENSAGEM) IS NOT NULL THEN
        UPDATE PCNFBASEENT SET OBS = OBS || V_MENSAGEM WHERE PCNFBASEENT.NUMTRANSENT = P_NOTA.NUMTRANSENT;
     END IF;
   END IF;
EXCEPTION
  WHEN OTHERS THEN
  BEGIN
      --este raise é usado só para testes, deixar comentado
      --RAISE_APPLICATION_ERROR(-20000, sqlerrm);
      NULL;
  END;
END;

  /*********************************************************************************/
  procedure GERAR_INFORMACOES_FINAIS(P_NOTA in C_NOTAS_NF%rowtype) is
  begin

    ---------------------------------------------------------------------------------
    V_SQLERRO := 'RECALCULANDO VLOUTRAS (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- RECALCULAR VLOUTRAS
    FOR DADOS IN (
      -- RECALCULAR VLOUTRAS
      select GREATEST(VLDESDOBRADO - VLBASE - VLISENTAS - /*VLFECP -*/
                      DECODE(V_NAOGERAR_IPI_VLOUTRAS, 'S', DECODE(V_IPIVLCONTSEMCREDITO, 'S', NVL(VLOUTRASIPI, 0), NVL(VLIPI, 0) + DECODE(V_VALIDA_VALOR_OUTRAS_IPI,'S',NVL(VLOUTRASIPI, 0),0)), 0) -
                      DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', (NVL(VLST, 0) + NVL(VLFECP, 0)), 0), 0) VLOUTRAS_NEW, PCNFBASEENT.ROWID IDREGISTRO

        from PCNFBASEENT
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA) LOOP

    -- RECALCULAR VLOUTRAS
    update PCNFBASEENT
       set VLOUTRAS  = DECODE(VLISENTAS, 0, DADOS.VLOUTRAS_NEW, CASE WHEN DADOS.VLOUTRAS_NEW <= 0.03 THEN 0 ELSE DADOS.VLOUTRAS_NEW END),
           VLISENTAS = VLISENTAS +
                       DECODE(VLISENTAS, 0, 0, DECODE(DADOS.VLOUTRAS_NEW, 0.01, 0.01, 0))
     where NUMTRANSENT = P_NOTA.NUMTRANSENT
       and NUMNOTA = P_NOTA.NUMNOTA
       AND ROWID  = DADOS.IDREGISTRO;

    END LOOP;

    ---------------------------------------------------------------------------------
    V_SQLERRO := 'RECALCULANDO VLOUTRAS (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- RECALCULAR VLOUTRAS E VLINSENTAS
    update PCNFBASEENT A
       set VLOUTRAS  = DECODE((select NVL(VLISENTAS, 'X')
                                from PCDESTSITTRIBUT
                               where SITTRIBUT = SUBSTR(A.SITTRIBUT, 2, 2)), 'S', --ISENTA

                              DECODE( CASE WHEN  (((select NVL(VLBASEICMS, 'X')
                                        from PCDESTSITTRIBUT
                                       where SITTRIBUT =
                                             SUBSTR(A.SITTRIBUT, 2, 2)) = 'O') AND ( NOT EXISTS (SELECT 1
                                      FROM PCCFOPEXCDESTSITTRIBUT CED
                                      WHERE CED.CODFISCAL = CODFISCAL
                                        AND CED.SITTRIBUT = SITTRIBUT))) THEN 'O' ELSE '' END, 'O', --OUTRAS: GRAVAR BASE EM OUTRAS
                                      VLOUTRAS + VLBASENAOTRIB, VLOUTRAS), DECODE( CASE WHEN (((select NVL(VLBASEICMS, 'X')
                                        from PCDESTSITTRIBUT
                                       where SITTRIBUT =
                                             SUBSTR(A.SITTRIBUT, 2, 2)) = 'I') AND (NOT EXISTS (SELECT 1
                                      FROM PCCFOPEXCDESTSITTRIBUT CED
                                      WHERE CED.CODFISCAL = CODFISCAL
                                        AND CED.SITTRIBUT = SITTRIBUT))) THEN 'I' ELSE '' END, 'I', --ISENTO: RETIRA BASE EM OUTRAS
                                      VLOUTRAS -
                                       VLBASENAOTRIB, VLOUTRAS)),
           VLISENTAS = DECODE((select NVL(VLISENTAS, 'X')
                                from PCDESTSITTRIBUT
                               where SITTRIBUT = SUBSTR(A.SITTRIBUT, 2, 2)), 'S', --ISENTA
                              DECODE(  CASE WHEN  (((select NVL(VLBASEICMS, 'X')
                                        from PCDESTSITTRIBUT
                                       where SITTRIBUT =
                                             SUBSTR(A.SITTRIBUT, 2, 2)) = 'O') AND (NOT EXISTS (SELECT 1
                                      FROM PCCFOPEXCDESTSITTRIBUT CED
                                      WHERE CED.CODFISCAL = CODFISCAL
                                        AND CED.SITTRIBUT = SITTRIBUT))) THEN 'O' ELSE '' END, 'O', --OUTRAS: RETIRA BASE ISENTAS
                                      VLISENTAS - VLBASENAOTRIB, VLISENTAS), DECODE(  CASE WHEN  (((select NVL(VLBASEICMS, 'X')
                                        from PCDESTSITTRIBUT
                                       where SITTRIBUT =
                                             SUBSTR(A.SITTRIBUT, 2, 2)) = 'I' ) AND (NOT EXISTS (SELECT 1
                                      FROM PCCFOPEXCDESTSITTRIBUT CED
                                      WHERE CED.CODFISCAL = CODFISCAL
                                        AND CED.SITTRIBUT = SITTRIBUT))) THEN 'I' ELSE '' END, 'I', --ISENTA:GRAVAR BASE EM ISENTAS
                                      VLISENTAS +
                                       VLBASENAOTRIB, VLISENTAS))
     where NUMTRANSENT = P_NOTA.NUMTRANSENT
       and NUMNOTA = P_NOTA.NUMNOTA
       and VLBASENAOTRIB > 0;
    ---------------------------------------------------------------------------------
    -- CORRIGIR VLBASE_REDUCAO CONFORME VLISENTAS
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'CORRIGINDO VLBASE_REDUCAO (NOTA ' || P_NOTA.NUMNOTA ||
                 ' EM ' || TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    update PCNFBASEENT
       set VLBASE_REDUCAO = VLISENTAS
     where NUMTRANSENT = P_NOTA.NUMTRANSENT
       and NUMNOTA = P_NOTA.NUMNOTA
       and VLBASE_REDUCAO > VLISENTAS;
    ---------------------------------------------------------------------------------
    -- LIMPANDO A OBSERVACAO
    if ('S' = V_LIMPAROBS) and
       (P_NOTA.CODFISCAL in
       (1201, 1202, 1203, 1204, 1410, 1411, 2201, 2202, 2203, 2204, 2410, 2411))
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'LIMPANDO OBSERVCAO (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      update PCNFBASEENT
         set OBS = null
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA;
    end if;
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO REFERENCIA A DEVOLUCAO';
    if P_NOTA.TIPODESCARGA in ('6', '7', '8', 'T')
    then
      update PCNFBASEENT
         set OBS = (select max('REF. NF ' || TO_CHAR(NUMNOTA) || ' DE ' ||
                               TO_CHAR(DTSAIDA, 'DD/MM/YYYY'))
                      from PCNFSAID N,
                           PCESTCOM E
                     where E.NUMTRANSENT = P_NOTA.NUMTRANSENT
                       and E.NUMTRANSVENDA = N.NUMTRANSVENDA)
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and VLTOTAL > 0
         and exists (select 1
                from PCNFENT
               where PCNFENT.NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and PCNFENT.NUMNOTA = P_NOTA.NUMNOTA
                 and PCNFENT.OBSLIVROFISCAL is null);
    end if;
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO REFERENCIA A BONIFICACAO';
    if P_NOTA.TIPODESCARGA = '5'
    then
      update PCNFBASEENT
         set OBS = DECODE(NVL(P_NOTA.OBS, 'X'), 'X', 'BONIFICACAO', SUBSTR(P_NOTA.OBS ||
                                  ' - ' ||
                                  'BONIFICACAO', 1, V_TAMANHO_OBS))
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and exists (select 1
                from PCNFENT
               where PCNFENT.NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and PCNFENT.NUMNOTA = P_NOTA.NUMNOTA
                 and PCNFENT.OBSLIVROFISCAL is null);
    end if;
    ---------------------------------------------------------------------------------
    -- GERANDO INFORMACOES DE MANIFESTO
    if (V_GERAR_REFERENCIA_MANIFESTO = 'S') and
       P_NOTA.TIPODESCARGA in ('6', '7', '8', 'T')
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'GERANDO INFORMACOES DE MANIFESTO. (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      for DADOS in (select D.NUMTRANSENT,
                           min(S.NUMCAR) NUMCAR_MANIFESTO,
                           min(S.NUMTRANSVENDA) NUMTRANSVENDA
                      from PCESTCOM D,
                           PCNFSAID S
                     where D.NUMTRANSENT = P_NOTA.NUMTRANSENT
                       and S.NUMTRANSVENDA = D.NUMTRANSVENDA
                       and S.DTCANCEL is null
                       and S.CONDVENDA = 13
                     group by D.NUMTRANSENT)
      loop
        update PCNFBASEENT A
           set OBS = SUBSTR((select 'REF. NF REMESSA: ' || TO_CHAR(NUMNOTA) ||
                                    ' DE ' || TO_CHAR(DTSAIDA, 'DD/MM/YYYY')
                               from PCNFSAID
                              where NUMTRANSVENDA = DADOS.NUMTRANSVENDA) ||
                            (select ' NFS VENDA: ' || TO_CHAR(min(NUMNOTA)) ||
                                    ' A ' || TO_CHAR(max(NUMNOTA)) ||
                                    DECODE(min(SERIE), null, ' SEM SERIE', ' SERIE: ' ||
                                            TO_CHAR(min(SERIE)))
                               from PCNFSAID
                              where NUMCAR = DADOS.NUMCAR_MANIFESTO
                                and CONDVENDA = 14
                                and DTCANCEL is null), 1, V_TAMANHO_OBS)
         where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and exists (select 1
                  from PCNFENT
                 where PCNFENT.NUMTRANSENT = P_NOTA.NUMTRANSENT
                   and PCNFENT.NUMNOTA = P_NOTA.NUMNOTA
                   and PCNFENT.OBSLIVROFISCAL is null);

        V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
        IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
          V_CONTADORREGISTRO := 0;
          COMMIT;
        END IF;

      end loop;
    end if;
    ---------------------------------------------------------------------------------
    -- GERANDO INFORMACOES DE MANIFESTO PARA SERGIPE
    if (V_UFFILIAL = 'SE') and P_NOTA.TIPODESCARGA in ('6', '7', '8', 'T')
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'GERANDO INFORMACOES DE MANIFESTO PARA SERGIPE. (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      update PCNFBASEENT A
         set VLOUTRAS       = VLDESDOBRADO,
             VLBASE         = 0,
             VLISENTAS      = 0,
             VLICMS         = 0,
             PERCICM        = 0,
             VLICMSNAOTRIB  = 0,
             VLBASENAOTRIB  = 0,
             PERCICMNAOTRIB = 0,
             OBS            = 'RET.REM.P/ VENDA FORA ESTABEL'
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and exists (select NUMNOTA
                from PCNFSAID B,
                     PCESTCOM C
               where C.NUMTRANSENT = A.NUMTRANSENT
                 and B.NUMTRANSVENDA = C.NUMTRANSVENDA
                 and B.CONDVENDA = 13);
    end if;
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'ATRIBUINDO "CV" AS NFS A VISTA E "CP" AS NFS A PRAZO. (NOTA ' ||
                 P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- ATRIBUINDO CONDICOES DE PAGAMENTO
    update PCNFBASEENT A
       set TIPOCOMPRA = DECODE(NVL((select max(DTVENC)
                                     from PCLANC
                                    where NUMTRANSENT = A.NUMTRANSENT
                                      and NUMNOTA = A.NUMNOTA), A.DTEMISSAO), A.DTEMISSAO, 'CV', 'CP')
     where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
       and A.NUMNOTA = P_NOTA.NUMNOTA;

    ---------------------------------------------------------------------------------
    -- LIMPANDO BASE DE CALCULO E ICMS NAS NOTAS
    if V_LIMPARBASECALCENTRADA = 'S'
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'LIMPANDO BASE DE CALCULO E ICMS NAS NOTAS FISCAIS. (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      update PCNFBASEENT
         set VLBASE   = 0,
             VLOUTRAS = VLOUTRAS + VLBASE,
             VLICMS   = 0
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA;
    end if;
    ---------------------------------------------------------------------------------
    --Atualizar OBSERVACAO qd entrega futura
    if (P_NOTA.TIPODESCARGA = '2') and (P_NOTA.NFENTREGAFUTURA = 'S')
    then
      update PCNFBASEENT
         set OBS = 'Simples faturamento para entrega futura'
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and exists (select 1
                from PCNFENT
               where PCNFENT.NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and PCNFENT.NUMNOTA = P_NOTA.NUMNOTA
                 and PCNFENT.OBSLIVROFISCAL is null);
    end if;

    if (P_NOTA.TIPODESCARGA = '1')
    then
      update PCNFBASEENT
         set OBS = 'REF. NF VENDA FUTURA No. ' ||
                   (select NUMNOTA
                      from PCNFENT
                     where CODFORNEC = P_NOTA.CODFORNEC
                       and NUMNOTAENTFUTURA = P_NOTA.NUMNOTA
                       and NFENTREGAFUTURA = 'S'
                       and TIPODESCARGA = '2'
                       and ROWNUM = 1) || ' de ' ||
                   (select DTEMISSAO
                      from PCNFENT
                     where CODFORNEC = P_NOTA.CODFORNEC
                       and NUMNOTAENTFUTURA = P_NOTA.NUMNOTA
                       and NFENTREGAFUTURA = 'S'
                       and TIPODESCARGA = '2'
                       and ROWNUM = 1)
       where exists (select NUMNOTA
                from PCNFENT
               where CODFORNEC = P_NOTA.CODFORNEC
                 and NUMNOTAENTFUTURA = P_NOTA.NUMNOTA
                 and NFENTREGAFUTURA = 'S'
                 and TIPODESCARGA = '2'
                 and ROWNUM = 1)
         and NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and exists (select 1
                from PCNFENT
               where PCNFENT.NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and PCNFENT.NUMNOTA = P_NOTA.NUMNOTA
                 and PCNFENT.OBSLIVROFISCAL is null);
    end if;
    ---------------------------------------------------------------------------------
    -- ZERANDO NOTAS FISCAIS FILHAS DE IMPORTACAO
    if P_NOTA.TIPODESCARGA = 'F'
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'ATUALIZANDO: ZERANDO NOTAS FISCAIS FILHAS DE IMPORTACAO. (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      update PCNFBASEENT A
         set A.VLBASE           = 0,
             A.VLICMS           = 0,
             A.VLISENTAS        = 0,
             A.VLOUTRAS         = VLDESDOBRADO,
             A.BASEST           = 0,
             A.VLST             = 0,
             A.VLBASEIPI        = 0,
             A.VLIPI            = 0,
             A.VLISENTAS_DAPI   = 0,
             A.VLNAOTRIB_DAPI   = 0,
             A.VLBASERED_DAPI   = 0,
             A.VLSUSPENSAS_DAPI = 0,
             A.VLST_DAPI        = 0,
             A.VLOUTRAS_DAPI    = 0,
             A.VLBASENAOTRIB    = 0,
             A.PERCICMNAOTRIB   = 0,
             A.VLICMSNAOTRIB    = 0,
             A.VLFCP            = 0,
             A.VLICMSUFREM      = 0,
             A.VLICMSUFDEST     = 0,
             A.VLICMSDIFALIQPART = 0,
             A.VLACRESCIMOFUNCEP  = 0,
             A.VLFECP             = 0,
             A.OBS              = 'REF.NF IMPORTACAO No.' ||
                                  NVL((select TO_CHAR(max(A2.NUMNOTA))
                                        from PCNFENT A1,
                                             PCNFENT A2
                                       where A1.NUMTRANSENT = A.NUMTRANSENT
                                         and A1.NUMTRANSORIGEM =
                                             A2.NUMTRANSENT), '0')
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA;
    end if;
    -------------------------------------------------------------------------------
    -- GRAVANDO O VALORES RESTANTES EM VLOUTRAS/VLISENTAS - DAPI-MG
    if P_NOTA.ESPECIE not in ('CT', 'CO')
    then
      -------------------------------------------------------------------------------
      V_SQLERRO := 'GRAVANDO O VALORES RESTANTES EM VLOUTRAS/VLISENTAS - DAPI-MG (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      -------------------------------------------------------------------------------
      update PCNFBASEENT A
         set VLISENTAS_DAPI = GREATEST(NVL(VLISENTAS, 0) -
                                       NVL(VLNAOTRIB_DAPI, 0) -
                                       NVL(VLBASERED_DAPI, 0), 0),
             VLOUTRAS_DAPI  = GREATEST(NVL(VLOUTRAS, 0) -
                                       NVL(VLSUSPENSAS_DAPI, 0) -
                                       DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', 0, (NVL(VLST, 0) + NVL(VLFECP, 0))), 0)
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and (A.VLOUTRAS > 0 or A.VLISENTAS > 0);
    end if;
    ---------------------------------------------------------------------------------
    -- ATRIBUINDO CONHECIMENTOS DE FRETE COMO VLISENTAS OU VLOUTRAS
    if V_FRETENAOTRIBCOMOOUTRAS = 'N'
    then
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'ATRIBUINDO CONHECIMENTOS DE FRETE NAO TRIB. COMO VLISENTAS. (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      update PCNFBASEENT A
         set A.VLISENTAS        = A.VLISENTAS + A.VLOUTRAS,
             A.VLISENTAS_DAPI   = DECODE(UF, V_UFFILIAL, A.VLISENTAS +
                                          A.VLOUTRAS, 0),
             A.VLBASERED_DAPI   = 0,
             A.VLNAOTRIB_DAPI   = DECODE(UF, V_UFFILIAL, 0, A.VLISENTAS +
                                          A.VLOUTRAS),
             A.VLOUTRAS         = 0,
             A.VLSUSPENSAS_DAPI = 0,
             A.VLST_DAPI        = 0,
             A.VLOUTRAS_DAPI    = 0
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.ESPECIE in ('CT', 'CO');
    else
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'ATRIBUINDO CONHECIMENTOS DE FRETE NAO TRIB. COMO VLOUTRAS. (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      update PCNFBASEENT A
         set A.VLISENTAS        = GREATEST(A.VLDESDOBRADO - A.VLBASE -
                                           A.VLOUTRAS, 0),
             A.VLISENTAS_DAPI   = GREATEST(A.VLDESDOBRADO - A.VLBASE -
                                           A.VLOUTRAS, 0),
             A.VLNAOTRIB_DAPI   = 0,
             A.VLBASERED_DAPI   = 0,
             A.VLOUTRAS         = GREATEST(A.VLDESDOBRADO - A.VLBASE -
                                           A.VLISENTAS, 0),
             A.VLSUSPENSAS_DAPI = 0,
             A.VLST_DAPI        = 0,
             A.VLOUTRAS_DAPI    = GREATEST(A.VLDESDOBRADO - A.VLBASE -
                                           A.VLISENTAS, 0)
       where A.NUMTRANSENT = P_NOTA.NUMTRANSENT
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.ESPECIE in ('CT', 'CO');
    end if;
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'ZERANDO VALORES PARA CANCELAMENTO. (NOTA ' ||
                 P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- ZERANDO VALORES PARA CANCELAMENTO SE FOR O CASO
    if P_NOTA.VLTOTAL = 0
    then
      update PCNFBASEENT
         set VLBASE           = 0,
             VLBASENAOTRIB    = 0,
             VLICMS           = 0,
             VLISENTAS        = 0,
             VLOUTRAS         = 0,
             PERCICM          = 0,
             VLDESDOBRADO     = 0,
             BASEST           = 0,
             VLST             = 0,
             VLBASEIPI        = 0,
             VLIPI            = 0,
             VLBASEOUTRASIPI  = 0,
             VLBASEISENTASIPI = 0,
             VLOUTRASIPI      = 0,
             VLISENTASIPI     = 0,
             PERCIPI          = 0,
             VLPIS            = 0,
             VLCOFINS         = 0,
             ALIQDIF          = 0,
             VLOUTRAS_DAPI    = 0,
             VLST_DAPI        = 0,
             VLISENTAS_DAPI   = 0,
             VLNAOTRIB_DAPI   = 0,
             VLBASERED_DAPI   = 0,
             VLSUSPENSAS_DAPI = 0,
             PERCICMNAOTRIB   = 0,
             VLICMSNAOTRIB    = 0,
             VLFCP            = 0,
             VLICMSUFREM      = 0,
             VLICMSUFDEST     = 0,
             VLICMSDIFALIQPART= 0,
             VLACRESCIMOFUNCEP= 0,
             VLBASEFCPST      = 0,
             VLBASEFCPICMS    = 0,
             ALIQICMSFECP     = 0,
             PERACRESCIMOFUNCEP = 0,
             VLFECP           = 0,
             OBS              = NVL( DECODE( P_NOTA.SITUACAONFE, 101,
                                                             DECODE( NVL(P_NOTA.OBS, 'X'),
                                                                     'X',
                                                                     'CANCELADA',
                                                                     SUBSTR(P_NOTA.OBS || ' - ' ||'CANCELADA', 1, V_TAMANHO_OBS)),
                                                             DECODE( P_NOTA.SITUACAONFE, 102,
                                                                                         DECODE( NVL(P_NOTA.OBS, 'X') ,
                                                                                                 'X',
                                                                                                 'INUTILIZADA',
                                                                                                 SUBSTR(P_NOTA.OBS || ' - ' ||'INUTILIZADA', 1, V_TAMANHO_OBS) ))),P_NOTA.OBS)
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and exists (select CODPROD
                from PCMOV
               where NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_NOTA.CODFILIAL
                 and NUMNOTA = P_NOTA.NUMNOTA)
         and not exists (select CODPROD
                from PCMOV
               where NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and NVL(PCMOV.CODFILIALNF,PCMOV.CODFILIAL) = P_NOTA.CODFILIAL
                 and NUMNOTA = P_NOTA.NUMNOTA
                 and dtcancel is  null);
/*Atualização NFs Canceladas 3402 e 3422*/
update PCNFBASEENT
         set VLBASE           = 0,
             VLBASENAOTRIB    = 0,
             VLICMS           = 0,
             VLISENTAS        = 0,
             VLOUTRAS         = 0,
             PERCICM          = 0,
             VLDESDOBRADO     = 0,
             BASEST           = 0,
             VLST             = 0,
             VLBASEIPI        = 0,
             VLIPI            = 0,
             VLBASEOUTRASIPI  = 0,
             VLBASEISENTASIPI = 0,
             VLOUTRASIPI      = 0,
             VLISENTASIPI     = 0,
             PERCIPI          = 0,
             VLPIS            = 0,
             VLCOFINS         = 0,
             ALIQDIF          = 0,
             VLOUTRAS_DAPI    = 0,
             VLST_DAPI        = 0,
             VLISENTAS_DAPI   = 0,
             VLNAOTRIB_DAPI   = 0,
             VLBASERED_DAPI   = 0,
             VLSUSPENSAS_DAPI = 0,
             PERCICMNAOTRIB   = 0,
             VLICMSNAOTRIB    = 0,
             VLFCP            = 0,
             VLICMSUFREM      = 0,
             VLICMSUFDEST     = 0,
             VLICMSDIFALIQPART= 0,
             VLACRESCIMOFUNCEP= 0,
             VLBASEFCPST      = 0,
             VLBASEFCPICMS    = 0,
             ALIQICMSFECP     = 0,
             PERACRESCIMOFUNCEP = 0,
             VLFECP           = 0,
             OBS              = NVL( DECODE( P_NOTA.SITUACAONFE, 101,
                                                             DECODE( NVL(P_NOTA.OBS, 'X'),
                                                                     'X',
                                                                     'CANCELADA',
                                                                     SUBSTR(P_NOTA.OBS || ' - ' ||'CANCELADA', 1, V_TAMANHO_OBS)),
                                                             DECODE( P_NOTA.SITUACAONFE, 102,
                                                                                         DECODE( NVL(P_NOTA.OBS, 'X') ,
                                                                                                 'X',
                                                                                                 'INUTILIZADA',
                                                                                                 SUBSTR(P_NOTA.OBS || ' - ' ||'INUTILIZADA', 1, V_TAMANHO_OBS) ))),P_NOTA.OBS)
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and exists (select PCMOVCIAP.CODPROD
                from PCMOVCIAP
               where PCMOVCIAP.NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and PCMOVCIAP.CODFILIAL = P_NOTA.CODFILIAL
                 and PCMOVCIAP.NUMNOTA = P_NOTA.NUMNOTA)
         and not exists (select PCMOVCIAP.CODPROD
                from PCMOVCIAP
               where PCMOVCIAP.NUMTRANSENT = P_NOTA.NUMTRANSENT
                 and PCMOVCIAP.CODFILIAL  = P_NOTA.CODFILIAL
                 and PCMOVCIAP.NUMNOTA = P_NOTA.NUMNOTA
                 and PCMOVCIAP.DTCANCEL is  null);            

    end if;
    -------------------------------------------------------------------------------------------
    -- ZERANDO VLCONTABIL QUANDO CFOP DE AQUISICAO DE BENS PARA REVENDA (1117, 2117)
    if ((P_NOTA.CODFISCAL in (1117, 2117))
    and (PARAMFILIAL.OBTERCOMOVARCHAR2('GERALIVRO_VLCONTABILZERADO', P_NOTA.CODFILIAL) = 'S'))
    then
      -------------------------------------------------------------------------------------------
      V_SQLERRO := 'ZERANDO VLCONTABIL QUANDO CFOP DE AQUISICAO DE BENS PARA REVENDA (1117, 2117)
                    E MARCADO PARAMETRO GERALIVRO_VLCONTABILZERADO NA ROTINA 132 (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      -------------------------------------------------------------------------------------------
      update PCNFBASEENT
         set VLDESDOBRADO = 0,
               VLTOTAL = 0
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and CODFISCAL in (1117, 2117);
    end if;
    -------------------------------------------------------------------------------------------
    -- ZERANDO ICMS QUANDO CFOP DE OUTRAS OPERACOES COM DIREITO A CREDITO (1922, 2922)
    if ((P_NOTA.CODFISCAL in (1922, 2922))
    and (PARAMFILIAL.OBTERCOMOVARCHAR2('GERALIVRO_VLCONTABILZERADO', P_NOTA.CODFILIAL) = 'S'))
    then
      -------------------------------------------------------------------------------------------
      V_SQLERRO := 'ZERANDO ICMS QUANDO CFOP DE OUTRAS OPERACOES COM DIREITO A CREDITO (1922, 2922)
                    E MARCADO PARAMETRO GERALIVRO_VLCONTABILZERADO NA ROTINA 132(NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
      -------------------------------------------------------------------------------------------
      update PCNFBASEENT
         set VLICMS  = 0,
             VLBASE  = 0,
             PERCICM = 0,
             BASEST = 0,
             VLST = 0,
             VLBASEIPI = 0,
             VLIPI = 0,
             VLFRETE = 0,
             VLOUTRASDESP = 0,
            VLOUTRAS = 0,
             VLBASEOUTRASIPI = 0,
             VLISENTAS = 0,
             VLISENTASIPI = 0
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and CODFISCAL in (1922, 2922);
    end if;

    --------------HIS.01724.2016 - Eddy---------------------------------------------------------------------
    --MELHORIA PARA PASSAR A GRAVAR OS DADOS DE ICMS NA OBSERVAÇÃO DO LIVRO QUANDO NOVO PROCESSO DO VENDAS
    INSERIROBSERVACAOICMS(P_NOTA);
    --------------------------------------------------------------------------------------------------------
end;

  procedure VALIDAR_LIVROFISCAL is
  begin
    begin
      V_SQLERRO := 'DELETANDO BACKUPS';
      --------------------------------------------------------------
      for DADOS in (select distinct TABLE_NAME
                      from USER_TAB_COLS
                     where TABLE_NAME like 'PCNFBASEENT_%')
      loop
        execute immediate 'DROP TABLE ' || DADOS.TABLE_NAME;
      end loop;
    exception
      when others then
        null;
    end;
    V_SQLERRO := 'VALIDANDO A GERACAO DO LIVRO FISCAL';
    --------------------------------------------------------------
    for DADOS in (select MES
                    from PCCONTROLELIVROFISCAL
                   where CODFILIAL = PCODFILIAL
                     and ANO = EXTRACT(year from DATA1)
                     and MES = EXTRACT(month from DATA1)
                     and ENCERRADO = 'S'
                  union all
                  select MES
                    from PCCONTROLELIVROFISCAL
                   where CODFILIAL = PCODFILIAL
                     and ANO = EXTRACT(year from DATA2)
                     and MES = EXTRACT(month from DATA2)
                     and ENCERRADO = 'S')
    loop
      raise V_VALIDACAOLIVRO;
    end loop;
  end;

  procedure GERAR_LOG_BACKUP is
    V_ANO               number;
    V_MES               number;
    V_DENTRO_DO_PERIODO boolean;
  begin
    V_SQLERRO := 'GERANDO LOG DO LIVRO FISCAL';
    insert into PCLOGGERACAOLIVROFISCAL
      (CODLOG,
       TIPO,
       CODFILIAL,
       DTINICIO,
       DTFIM,
       DATAGERACAO,
       TERMINAL,
       OS_USUARIO)
    values
      (DFSEQ_PCLOGGERACAOLIVROFISCAL.nextval,
       'E',
       PCODFILIAL,
       DATA1,
       DATA2,
       sysdate,
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'OS_USER'));
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO REGISTRO DE CONTROLE DO LIVRO FISCAL';
    for V_ANO in EXTRACT(year from DATA1) .. EXTRACT(year from DATA2)
    loop
      for V_MES in 1 .. 12
      loop
        V_DENTRO_DO_PERIODO := TO_DATE('01/' || TO_CHAR(V_MES) || '/' ||
                                       TO_CHAR(V_ANO), 'dd/mm/yyyy') between
                               TRUNC(DATA1, 'MM') and TRUNC(DATA2, 'MM');
        if V_DENTRO_DO_PERIODO
        then
          begin
            insert into PCCONTROLELIVROFISCAL
              (CODFILIAL,
               ANO,
               MES,
               ENCERRADO)
            values
              (PCODFILIAL,
               V_ANO,
               V_MES,
               'N');
          exception
            when others then
              null;
          end;
        end if;
      end loop;
    end loop;
  end;

  procedure GERAR_DESPESA_FRETE_NFE(P_NOTA in out C_NOTAS_NF%rowtype) is
  begin
    -- GRAVAR VALORES DE DESPESA E FRETE, TRUNCANDO EM 2 CASAS DECIMAIS
    --------------------------------------------------------------------------
    for DADOS in (select M.CODFISCAL,
                         FISCAL.FORMATAR_CST_ICMS(m.SITTRIBUT, NVL(m.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT) SITTRIBUT,
                         CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS,0) = 100) THEN
                           0
                         ELSE
                           DECODE(NVL(M.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(M.PERCICM, 0))
                         END AS PERCICM,
                         NVL(M.PERCIPI,0) PERCIPI,
                         DECODE(M.GERAICMSLIVROFISCAL, 'N', NVL(M.PERCICM, 0), 0) PERCICMNAOTRIB,
                         SUM(ROUND(M.QTCONT * NVL(M.VLFRETE, 0), 2)) VLFRETE,
                         SUM(ROUND(M.QTCONT * DECODE(M.CODOPER, 'ET', NVL(M.VLOUTRASDESP, 0), NVL(M.VLOUTROS, 0)), 2)) VLDESPESA,
                         SUM(ROUND(M.QTCONT * DECODE(M.CODOPER, 'ED', 0, DECODE(M.CODOPER, 'ET', NVL(M.VLOUTRASDESP, 0), NVL(M.VLOUTROS, 0)), 2))) VLDESPESAISENTA,
                         SUM(ROUND(M.QTCONT * DECODE(M.CODOPER, 'ED', 0, NVL(MC.VLBASEFRETE, 0)), 2)) VLBASEFRETE,
                         SUM(ROUND(M.QTCONT * DECODE(M.CODOPER, 'ED', 0, NVL(MC.VLBASEOUTROS, 0)), 2)) VLBASEDESPESA,
                         SUM(ROUND(  ROUND(M.QTCONT *(DECODE(M.CODOPER, 'ED', 0, NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0))), 2)
                                   * (CASE
                                         WHEN(NVL(MC.PERDIFEREIMENTOICMS, 0) = 100)
                                            THEN 0
                                         ELSE DECODE(NVL(M.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(M.PERCICM, 0))
                                      END)
                                   / 100
                                 , 2)) VLICMS,
                         SUM(ROUND(ROUND(M.QTCONT * (DECODE(M.CODOPER, 'ED', 0, NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0))), 2) *
                                   DECODE(M.GERAICMSLIVROFISCAL, 'N', M.PERCICM, 0) / 100, 2)) VLICMSNAOTRIB
                    from PCMOV       M,
                         pcnfent    a,
                         pcprodut p,
                         PCMOVCOMPLE MC,
                         pcprodfilial pf
                   where M.NUMTRANSENT = P_NOTA.NUMTRANSENT
                     and M.NUMTRANSITEM = MC.NUMTRANSITEM
           AND NVL(M.CODFILIALNF, M.CODFILIAL) = NVL(A.CODFILIALNF, A.CODFILIAL)
                     and m.codprod = p.codprod
                     and m.numtransent = a.numtransent
                     and m.codprod = pf.codprod(+)
                     and m.codfilial = pf.codfilial(+)
                   group by M.GERAICMSLIVROFISCAL,
                            M.CODFISCAL,
                            M.PERCICM,
                            NVL(M.PERCIPI,0),
                            FISCAL.FORMATAR_CST_ICMS(m.SITTRIBUT, NVL(m.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTENT),
                            CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS,0) = 100) THEN
                              0
                            ELSE
                              DECODE(NVL(M.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(M.PERCICM, 0))
                            END
                            )
    loop

      update PCNFBASEENT A
         set VLDESDOBRADO     = NVL(VLDESDOBRADO, 0) + NVL(DADOS.VLFRETE, 0) + NVL(DADOS.VLDESPESA, 0),
             VLBASE           = NVL(VLBASE, 0) + DADOS.VLBASEFRETE + DADOS.VLBASEDESPESA,
             VLFRETE          = NVL(VLFRETE, 0) + NVL(DADOS.VLFRETE, 0),
             VLOUTRASDESP     = NVL(VLOUTRASDESP, 0) + NVL(DADOS.VLDESPESA, 0),
             VLBASEFRETE      = NVL(VLBASEFRETE, 0) + DADOS.VLBASEFRETE,
             VLBASEOUTRASDESP = NVL(VLBASEOUTRASDESP, 0) + DADOS.VLBASEDESPESA,
             VLICMS           = NVL(VLICMS, 0) + DADOS.VLICMS,
             VLICMSNAOTRIB    = NVL(VLICMSNAOTRIB, 0) + DADOS.VLICMSNAOTRIB,
             VLISENTAS        = CASE WHEN DADOS.PERCICM > 0 THEN
                                   NVL(VLISENTAS, 0) +
                                   DECODE((select D.VLISENTAS
                                           from PCDESTSITTRIBUT D
                                           where D.SITTRIBUT = A.SITTRIBUT), 'S',
                                          (NVL(DADOS.VLFRETE, 0) + NVL(DADOS.VLDESPESAISENTA, 0)) -
                                          (NVL(DADOS.VLBASEFRETE, 0) + NVL(DADOS.VLBASEDESPESA, 0)), 0)
                                ELSE
                                   NVL(VLISENTAS, 0)
                                END
       where NUMTRANSENT = P_NOTA.NUMTRANSENT
         and NUMNOTA = P_NOTA.NUMNOTA
         and CODFISCAL = DADOS.CODFISCAL
         and PERCICM = DADOS.PERCICM
         AND NVL(PERCIPI,0) = DADOS.PERCIPI
         and sittribut = dados.sittribut
         and ROWNUM = 1;

      V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
      IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
        V_CONTADORREGISTRO := 0;
        COMMIT;
      END IF;
    end loop;
  end;

  procedure CONFIGURAR_DESPESA_FRETE(P_NOTA in out C_NOTAS_NF%rowtype) is
  begin
    -- RATEAR AS DESPESAS SE AINDA NAO ESTIVEREM
    for DADOS in (select NUMTRANSENT
                    from PCNFENT
                   where NUMTRANSENT = P_NOTA.NUMTRANSENT
                     and NUMNOTA = P_NOTA.NUMNOTA
                     and TIPODESCARGA in ('6', '8', 'T')
                     and (VLFRETE > 0 or VLOUTRAS > 0)
                     and NVL(DESPESASRATEADA, 'N') = 'N'
                     and (CHAVENFE is not null or MODELO = '55')
                     and DTENT >= V_DATA_INICIO_NFE20)
    loop
      FISCAL.CALCULAR_RATEIO_DESPESAS_DEVOL(P_NOTA.NUMTRANSENT, V_SQLERRO);
    end loop;

    if (P_NOTA.TIPODESCARGA in ('6', '8', 'T') or
       ((P_NOTA.NFETRANSFERENCIA = 'S') and (P_NOTA.CHAVENFE IS NULL))) and
       (P_NOTA.DTENT >= V_DATA_INICIO_NFE20) and
       (P_NOTA.CHAVENFE IS NOT NULL)
    then
      if (P_NOTA.VLFRETE > 0) or (P_NOTA.VLOUTRASDESP > 0)
      then
        GERAR_DESPESA_FRETE_NFE(P_NOTA);
      end if;
    else
      -- INSERIR REGISTRO DE DESPESA ACESSORIA SE FOR O CASO
      if P_NOTA.VLOUTRASDESP > 0
      then
        GERAR_DESPESA_ACESSORIA(P_NOTA);
      end if;
      -- INSERIR REGISTRO DE FRETE SE FOR O CASO
      if P_NOTA.VLFRETE > 0
      then
        GERAR_FRETE(P_NOTA);
      end if;
    end if;
  end;


  procedure DESATIVAR_SESSAO is
  begin
    IF (V_SESSAO_ATIVA = 'S') THEN
      V_SQL := 'ALTER SESSION SET SQL_TRACE = FALSE';
      EXECUTE IMMEDIATE V_SQL;
    END IF;
  exception
    when others then
    begin
         NULL;
    end;
  end;

  -- Function F_NOTAS_DEVOLNF
  function F_NOTAS_DEVOLNF(PCODFILIAL IN VARCHAR2,
                           DATA1 IN DATE,
                           DATA2 IN DATE,
                           PNUMNOTA1 IN NUMBER,
                           PNUMNOTA2 IN NUMBER) return boolean is
  BEGIN
     BEGIN
        select 1 INTO V_QTDNF_NO_PERIODO
          from PCNFENT A
         where NVL(A.CODFILIALNF, A.CODFILIAL) = PCODFILIAL
           and A.DTENT between DATA1 and DATA2
           and A.NUMNOTA between PNUMNOTA1 and PNUMNOTA2
           and (A.TIPODESCARGA in ('6', '7', '8', 'C', 'T') or ((a.notadupliquesvc = 'S' and a.tipodescarga = '2')))
           and ((A.CHAVENFE is null) or 
                ((a.notadupliquesvc = 'S' and a.tipodescarga = '2')))
           and A.ESPECIE in ('NF', 'DA')
           and A.DTCANCEL IS NULL       
           and A.NUMTRANSENT > 0     
           AND ROWNUM = 1;
     EXCEPTION
     when NO_DATA_FOUND then
       V_QTDNF_NO_PERIODO := 0;
     END;

     if (V_QTDNF_NO_PERIODO > 0) then
       return True;
     else
       return False;
     end if;
     
   END;
   ----------------------------------------- // -------------------------------------

  -- Function F_NOTAS_DEVOLNF
  function F_NOTAS_DEVOLNFE(PCODFILIAL IN VARCHAR2,
                            DATA1 IN DATE,
                            DATA2 IN DATE,
                            PNUMNOTA1 IN NUMBER,
                            PNUMNOTA2 IN NUMBER) return boolean is
  BEGIN
     BEGIN
        select 1 INTO V_QTDNF_NO_PERIODO
          from PCNFENT A
         where NVL(A.CODFILIALNF, A.CODFILIAL) = PCODFILIAL
           and A.DTENT between DATA1 and DATA2
           and A.NUMNOTA between PNUMNOTA1 and PNUMNOTA2
           and A.TIPODESCARGA in ('6', '7', '8', 'C', 'T')
           and A.CHAVENFE is not null
           and A.ESPECIE in ('NF', 'DA')
           and A.NUMTRANSENT > 0
           AND ROWNUM = 1;
     EXCEPTION
     when NO_DATA_FOUND then
       V_QTDNF_NO_PERIODO := 0;
     END;

     if (V_QTDNF_NO_PERIODO > 0) then
       return True;
     else
       return False;
     end if;
     
   END;
   ----------------------------------------- // -------------------------------------

PROCEDURE INSERIR_NF_CONTABILIZADA(P_NOTA IN C_NOTAS_NF%ROWTYPE) IS
BEGIN
  ---------------------------------------------------------------------------------
    V_SQLERRO := 'INSERINDO OU ATUALIZANDO REGISTRO (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTENT, 'DD/MM/YYYY') || ')';
  ---------------------------------------------------------------------------------
    UPDATE PCMOVTEMP
    SET DATAENT = P_NOTA.DTENT,
        NUMNOTA = P_NOTA.NUMNOTA
    WHERE CODFILIAL = P_NOTA.CODFILIAL
      AND NUMTRANSENT = P_NOTA.NUMTRANSENT
      AND DATAENT = P_NOTA.DTENT
      AND NUMNOTA  = P_NOTA.NUMNOTA
      AND TIPOREGISTRO = 'NF_CONTABE';

    IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO PCMOVTEMP
          (CODFILIAL,
           NUMTRANSENT,
           DATAENT,
           NUMNOTA,
           TIPOREGISTRO
           )
        VALUES
          (P_NOTA.CODFILIAL,
           P_NOTA.NUMTRANSENT,
           P_NOTA.DTENT,
           P_NOTA.NUMNOTA,
           'NF_CONTABE');
    END IF;
END;

FUNCTION VALIDAR_NF_CONTABILIZADA(P_NOTA IN C_NOTAS_NF%ROWTYPE) RETURN BOOLEAN IS 
BEGIN
  BEGIN
    SELECT 1 INTO V_NF_CONTABILIZADA           
           FROM PCLANCINTERMEDIARIA L                   
        WHERE L.DATALANCTO = P_NOTA.DTENT                      
         AND L.NUMTRANSOPERACAO = P_NOTA.NUMTRANSENT            
         AND L.CODFILIAL = P_NOTA.CODFILIAL                   
         AND L.CODREGRA IN (SELECT CODREGRA FROM PCREGRACONTABIL WHERE CODFATOGERADOR = '1')
         AND NVL(L.STATUS,'P') = 'I' 
         AND ROWNUM = 1;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_NF_CONTABILIZADA := 0;
   END;
   IF (V_NF_CONTABILIZADA > 0) THEN
       RETURN TRUE;
   ELSE
       RETURN FALSE;
   END IF; 
END;

   -----------------------------------//---------------------------------------------
procedure GERALIVRO_FISCAL(V_LISTA_NOTAS IN OUT  LISTA_NOTAS) IS
BEGIN
    R_NOTA_TEMP.NUMTRANSENT  := -1;
    R_NOTA_TEMP.NUMNOTA      := -1;
    R_NOTA_TEMP.VLOUTRASDESP := 0;
    R_NOTA_TEMP.VLFRETE      := 0;
    V_NF_CONTABILIZADA       := 0;
    V_NUMNOTA                := 0;

    for I in 1 .. V_LISTA_NOTAS.count
    loop
      IF V_VALIDA_NF_CONTABILIZADA = 'S' THEN
        -- VALIDA SE A NF ESTA CONTABILIZADA NO MODULO CONTABIL
        IF VALIDAR_NF_CONTABILIZADA(V_LISTA_NOTAS(I)) THEN
           -- INSERIR REGISTRO PCMOVTEMP      
           INSERIR_NF_CONTABILIZADA(V_LISTA_NOTAS(I));
           V_NF_CONTABILIZADA:= 1;
        ELSE
           --DELETA LIVRO DA NF
           IF V_NUMNOTA <> V_LISTA_NOTAS(I).NUMNOTA THEN
                DELETE FROM PCNFBASEENT
                    WHERE DTENTRADA BETWEEN V_LISTA_NOTAS(I).DTENT AND V_LISTA_NOTAS(I).DTENT
                        AND CODFILIALNF = V_LISTA_NOTAS(I).CODFILIAL
                        AND NUMTRANSENT = V_LISTA_NOTAS(I).NUMTRANSENT
                        AND NUMNOTA BETWEEN V_LISTA_NOTAS(I).NUMNOTA AND V_LISTA_NOTAS(I).NUMNOTA;
            END IF;            
           V_NF_CONTABILIZADA:= 0;    
        END IF;
        V_NUMNOTA := V_LISTA_NOTAS(I).NUMNOTA;
      END IF; 
      IF V_NF_CONTABILIZADA = 0 THEN        
      -- CONDICIONAL CRIADA PARA NÃO GERAR O LIVRO PARA ESPECIE = NS, PORÉM A MESMA PRECISA TER A CONTA CONTABIL GERADA MAIS A BAIXO.
      IF (V_LISTA_NOTAS(I).ESPECIE = 'NS') THEN
        FISCAL.GERA_CONTAS_CONTABEIS_SPED(V_LISTA_NOTAS(I).CODFILIAL, V_LISTA_NOTAS(I).DTENT, V_LISTA_NOTAS(I).DTENT, V_LISTA_NOTAS(I).NUMTRANSENT, 'E');
      ELSE
        -- INSERIR REGISTRO DA NOTA FISCAL
        INSERIR_REGISTRO_NOTA(V_LISTA_NOTAS(I));
        -- REGISTRO DE DESPESA ACESSORIA E FRETE (GERAR SOMENTE NO ULTIMO REGISTRO DE CADA NOTA FISCAL)
        if ((R_NOTA_TEMP.NUMTRANSENT <> V_LISTA_NOTAS(I).NUMTRANSENT) or
            (R_NOTA_TEMP.NUMNOTA <> V_LISTA_NOTAS(I).NUMNOTA)) then
          -- CALCULAR ICMS
          CALCULAR_ICMS(R_NOTA_TEMP);
          -- INSERIR REGISTRO DE DESPESA ACESSORIA OU FRETE SE FOR O CASO
          CONFIGURAR_DESPESA_FRETE(R_NOTA_TEMP);
          ---------------------------------------------------------------------------------
          -- GERAR INFORMACOES FINAIS (RECALCULO E ATRIBUICOES DA LEGISLACAO)
          if R_NOTA_TEMP.NUMTRANSENT > 0 then
            GERAR_INFORMACOES_FINAIS(R_NOTA_TEMP);
          end if;
          -- RECALCULAR ICMS
          CALCULAR_ICMS(R_NOTA_TEMP);
          ---------------------------------------------------------------------------------
          -- INSERIR CAMPOS REFERENTES A IMPORTACAO - TIPODESCARGA = "N"
          ---------------------------------------------------------------------------------
           IF R_NOTA_TEMP.TIPODESCARGA = 'N' THEN
              GERAR_DESPESA_IMPORTACAO(R_NOTA_TEMP);
           END IF;

           R_NOTA_TEMP := V_LISTA_NOTAS(I);
        end if;
        --------------------------------------------------------------------------------------------------------
        --ATUALIZA CONTA CONTABIL--
        FISCAL.GERA_CONTAS_CONTABEIS_SPED(V_LISTA_NOTAS(I).CODFILIAL, V_LISTA_NOTAS(I).DTENT, V_LISTA_NOTAS(I).DTENT, V_LISTA_NOTAS(I).NUMTRANSENT, 'E');

        V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
        IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
          V_CONTADORREGISTRO := 0;
          COMMIT;
        END IF;
      END IF;
     END IF; 

    END LOOP;
    /********************************************************************************/
    -- PROCESSAMENTO PARA O ULTIMO REGISTRO
    /********************************************************************************/
   IF V_NF_CONTABILIZADA = 0 THEN 
      -- CALCULAR ICMS
      CALCULAR_ICMS(R_NOTA_TEMP);
      -- INSERIR REGISTRO DE DESPESA ACESSORIA OU FRETE SE FOR O CASO
      CONFIGURAR_DESPESA_FRETE(R_NOTA_TEMP);
      ---------------------------------------------------------------------------------
      -- GERAR INFORMACOES FINAIS (RECALCULO E ATRIBUICOES DA LEGISLACAO)
      if R_NOTA_TEMP.NUMTRANSENT > 0 then
        GERAR_INFORMACOES_FINAIS(R_NOTA_TEMP);
      end if;
      -- RECALCULAR ICMS
      CALCULAR_ICMS(R_NOTA_TEMP);
      ---------------------------------------------------------------------------------
      -- INSERIR CAMPOS REFERENTES A IMPORTACAO - TIPODESCARGA = "N"
      ---------------------------------------------------------------------------------
      IF R_NOTA_TEMP.TIPODESCARGA = 'N' THEN
        GERAR_DESPESA_IMPORTACAO(R_NOTA_TEMP);
      END IF;
    END IF;

  END;

begin
  V_CONTADORREGISTRO := 0;
  V_QUANTIDADECOMMIT := 500;

  /* Apenas descomente caso necessário gerar tracer da geração */
  -- ATIVAR_SESSAO;
  --*********************************************************************************
  VALIDAR_LIVROFISCAL();
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'RECUPERANDO PARAMETROS GERAIS (PCCONSUM)';
  select C.LIMPAROBSNFDEVOL,
         C.REDUCAOBCISENTA,
         NVL(C.CODFISCALDEVOUTRASDESP, 1949),
         NVL(C.CODFISCALINTERDEVOUTRASDESP, 2949),
         C.TIPOALIQOUTRASDESP,
         NVL(C.ALIQICMOUTRASDESP, 0),
         NVL(C.ALIQICMINTEROUTRASDESP, 0),
         NVL(C.PERCICMFRETEENT, 0),
         NVL(C.CODFISCALFRETEENT, 1949),
         NVL(C.PERCICMINTERFRETEENT, 0),
         NVL(C.CODFISCALINTERFRETEENT, 2949),
         NVL(C.FRETENAOTRIBCOMOOUTRAS, 'N'),
         NVL(TRIBUTAFRETERATEADO, 'N'),
         PARAMFILIAL.OBTERCOMOVARCHAR2('GERARREFMANIFESTO', PCODFILIAL),
         PARAMFILIAL.OBTERCOMOVARCHAR2('BLOQCONTABILCANCALTNOTAFISCAL')
    into V_LIMPAROBS,
         V_REDUCAOISENTA,
         V_CODFISCALOUTRASDESP,
         V_CODFISCALINTEROUTRASDESP,
         V_TIPOALIQOUTRASDESP,
         V_ALIQICMOUTRASDESP,
         V_ALIQICMINTEROUTRASDESP,
         V_PERCICMFRETE,
         V_CODFISCALFRETE,
         V_PERCICMINTERFRETE,
         V_CODFISCALINTERFRETE,
         V_FRETENAOTRIBCOMOOUTRAS,
         V_TRIBUTAFRETERATEADO,
         V_GERAR_REFERENCIA_MANIFESTO,
         V_VALIDA_NF_CONTABILIZADA
    from PCCONSUM C;
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'RECUPERANDO PARAMETROS POR FILIAL (PCFILIAL)';
  if V_TIPOALIQOUTRASDESP = 'F'
  then
    select NVL(F.CODFISCALDEVOUTRASDESP, 1949),
           NVL(F.CODFISCALINTERDEVOUTRASDESP, 2949),
           NVL(F.ALIQICMOUTRASDESP, 0),
           NVL(F.ALIQICMINTEROUTRASDESP, 0),
           NVL(F.LIMPARBASECALCENTRADA, 'N'),
           F.UF,
           NVL(F.IPISOMENTEVLCONT, 'N'),
           NVL(F.STSOMENTEVLCONT, 'N'),
           NVL(F.INDUSTRIA, 'N')
      into V_CODFISCALOUTRASDESP,
           V_CODFISCALINTEROUTRASDESP,
           V_ALIQICMOUTRASDESP,
           V_ALIQICMINTEROUTRASDESP,
           V_LIMPARBASECALCENTRADA,
           V_UFFILIAL,
           V_NAOGERAR_IPI_VLOUTRAS,
           V_NAOGERAR_ST_VLOUTRAS,
           V_INDUSTRIA
      from PCFILIAL F
     where F.CODIGO = PCODFILIAL;
  else
    select UF,
           NVL(IPISOMENTEVLCONT, 'N'),
           NVL(STSOMENTEVLCONT, 'N'),
           NVL(INDUSTRIA, 'N')
      into V_UFFILIAL,
           V_NAOGERAR_IPI_VLOUTRAS,
           V_NAOGERAR_ST_VLOUTRAS,
           V_INDUSTRIA
      from PCFILIAL
     where CODIGO = PCODFILIAL;
  end if;

  V_IPIVLCONTSEMCREDITO := PARAMFILIAL.OBTERCOMOVARCHAR2('IPIVLCONTSEMCREDITO', PCODFILIAL);
  V_VALIDA_VALOR_OUTRAS_IPI := PARAMFILIAL.OBTERCOMOVARCHAR2('VLOUTRASIPI_SEMIPI', PCODFILIAL);
  V_DESTACAR_ICMS_DEVOL_TV13 := PARAMFILIAL.OBTERCOMOVARCHAR2('DESTACARICMSDEVOLTV13', PCODFILIAL);

  ---------------------------------------------------------------------------------
  V_SQLERRO := 'DEFININDO O TAMANHO DO CAMPO OBS';
  begin
    select T.DATA_LENGTH
      into V_TAMANHO_OBS
      from USER_TAB_COLS T
     where T.TABLE_NAME = 'PCNFBASEENT'
       and T.COLUMN_NAME = 'OBS';
  exception
    when others then
      V_TAMANHO_OBS := 60;
  end;
  ---------------------------------------------------------------------------------
  IF V_VALIDA_NF_CONTABILIZADA = 'N' THEN
     V_SQLERRO := 'EXCLUINDO REGISTROS ANTERIORES';
    delete from PCNFBASEENT
     where DTENTRADA between DATA1 and DATA2
       and CODFILIALNF = PCODFILIAL
       and NUMNOTA between NUMNOTA1 and NUMNOTA2;     
     COMMIT;
  END IF;
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'BUSCANDO NOTAS FISCAIS';
  ---------------------------------------------------------------------------------
 
  open C_NOTAS_NF(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch c_notas_Nf bulk collect
  into LISTA_NOTAS_NF;
  close C_NOTAS_NF;
  GERALIVRO_FISCAL(LISTA_NOTAS_NF);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------

  open C_NOTAS_NFE(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch C_NOTAS_NFE   bulk collect
  into LISTA_NOTAS_NFE ;
  close C_NOTAS_NFE;
  GERALIVRO_FISCAL(LISTA_NOTAS_NFE);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------

  open C_NOTAS_IMPORTACAO(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch C_NOTAS_IMPORTACAO bulk collect
  into LISTA_NOTAS_IMPORTACAO;
  close C_NOTAS_IMPORTACAO;
  GERALIVRO_FISCAL(LISTA_NOTAS_IMPORTACAO);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  IF F_NOTAS_DEVOLNF(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2) then
  
     open C_NOTAS_DEVOLNF(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
     fetch C_NOTAS_DEVOLNF bulk collect
     into LISTA_NOTAS_DEVOLNF;
     close C_NOTAS_DEVOLNF;
     GERALIVRO_FISCAL(LISTA_NOTAS_DEVOLNF);
   
     IF V_CONTADORREGISTRO > 0 THEN
        COMMIT;
        V_CONTADORREGISTRO := 0;
     END IF;
     
  END IF;  
  
  ---------------------------------------------------------------------------------
  IF F_NOTAS_DEVOLNFE(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2) then
  
    open C_NOTAS_DEVOLNFE(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
    fetch C_NOTAS_DEVOLNFE bulk collect
    into LISTA_NOTAS_DEVOLNFE;
    close C_NOTAS_DEVOLNFE;
    GERALIVRO_FISCAL(LISTA_NOTAS_DEVOLNFE);
  
    IF V_CONTADORREGISTRO > 0 THEN
       COMMIT;
       V_CONTADORREGISTRO := 0;
    END IF;
    
  END IF;
  ---------------------------------------------------------------------------------

  open C_NOTAS_PCNFBASE_TIPO1(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch C_NOTAS_PCNFBASE_TIPO1 bulk collect
  into LISTA_NOTAS_PCNFBASE_TIPO1;
  close C_NOTAS_PCNFBASE_TIPO1;
  GERALIVRO_FISCAL(LISTA_NOTAS_PCNFBASE_TIPO1);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------

  open C_NOTAS_PCNFBASE_TIPO2(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch C_NOTAS_PCNFBASE_TIPO2 bulk collect
  into LISTA_NOTAS_PCNFBASE_TIPO2;
  close C_NOTAS_PCNFBASE_TIPO2;
  GERALIVRO_FISCAL(LISTA_NOTAS_PCNFBASE_TIPO2);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
 
  open C_NOTAS_CONHECIMENTOFRETE(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch C_NOTAS_CONHECIMENTOFRETE bulk collect
  into LISTA_NOTAS_CONHECIMENTOFRETE;
  close C_NOTAS_CONHECIMENTOFRETE;
  GERALIVRO_FISCAL(LISTA_NOTAS_CONHECIMENTOFRETE);
  ---------------------------------------------------------------------------------

  open C_NOTAS_COMPLEMETAR_COM_ITEM(PCODFILIAL, DATA1, DATA2, NUMNOTA1, NUMNOTA2);
  fetch C_NOTAS_COMPLEMETAR_COM_ITEM bulk collect
  into LISTA_NOTAS_COMPLEMENTAR_ITEM;
  close C_NOTAS_COMPLEMETAR_COM_ITEM;
  GERALIVRO_FISCAL(LISTA_NOTAS_COMPLEMENTAR_ITEM);
  ---------------------------------------------------------------------------------
  
  IF NUMNOTA1 <> NUMNOTA2 THEN
    IF V_CONTADORREGISTRO > 0 THEN
       COMMIT;
       V_CONTADORREGISTRO := 0;
    END IF;
    GERAR_LOG_BACKUP();
  end if;

  COMMIT;
  DESATIVAR_SESSAO;
  RESULTADO := 'OK';
exception
  when V_VALIDACAOLIVRO then
    begin
      rollback;
      DESATIVAR_SESSAO;
      RESULTADO := V_SQLERRO || ' -> ' ||
                   'LIVRO FISCAL JA ENCERRADO!';
    end;
  when others then
    begin
      rollback;
      DESATIVAR_SESSAO;
      RESULTADO := 'ERRO: ' || V_SQLERRO || ' -> ' || sqlerrm;
    end;
end;
-- 1 - Alteração 03/06/2024 
-- 1.1 - Implementado ajuste no sql NFE para considerar nas coluans vlbase e vlcims os dados do pcdadosxml
-- 1 - Alteração 06/03/2024
-- 1.1 - Alteração nos sqls C_NOTAS_DEVOLNFE e C_NOTAS_DEVOLNF com inclusão de funções
-- V 003 --
