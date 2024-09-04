CREATE OR REPLACE PROCEDURE GERALIVRO_SAIDA(DATA1 IN DATE,
                                            -- Parametro Obrigat?rio!
                                            DATA2 IN DATE,
                                            -- Parametro Obrigat?rio!
                                            PCODFILIAL IN VARCHAR2,
                                            -- Parametro Obrigat?rio!
                                            NUMNOTA1 IN NUMBER,
                                            -- Para Ignorar esse Parametro Usar 0 (Zero)
                                            NUMNOTA2 IN NUMBER,
                                            -- Para Ignorar esse Parametro Usar 9999999
                                            RESULTADO OUT VARCHAR2) IS
  /******************************************************************************************/
  V_SQL                        varchar2(5000);
  V_SESSAO_ATIVA               varchar2(1);
  V_INSERIRCF                  varchar2(1);
  V_INSERIRREDZ                varchar2(1);
  V_INSERIRMAPA                varchar2(1);
  V_CFOP5929                   varchar2(1);
  V_ESPECIE                    varchar2(5);
  V_SERIE                      varchar2(5);
  V_REDUCAOISENTA              varchar2(1);
  V_SQLERRO                    varchar2(500);
  V_UFFILIAL                   varchar2(2);
  V_INDUSTRIA                  varchar2(1);
  V_CODFISCALOUTRASDESP        number;
  V_TRIBUTACAOINCOMPLETA       exception;
  V_FALTANDO_REDUCOES_Z        exception;
  V_VALIDACAOLIVRO             exception;
  V_CODFISCALINTEROUTRASDESP   number;
  V_ALIQICMOUTRASDESP          number;
  V_ALIQICMINTEROUTRASDESP     number;
  V_CFOP_ST                    number;
  V_PERCICMFRETE               number;
  V_CODFISCALFRETE             number;
  V_PERCICMINTERFRETE          number;
  V_CODFISCALINTERFRETE        number;
  V_TIPOALIQOUTRASDESP         varchar2(1);
  V_NAOGERAR_IPI_VLOUTRAS      varchar2(1);
  V_NAOGERAR_ST_VLOUTRAS       varchar(1);
  V_GERAR_REFERENCIA_MANIFESTO varchar2(1);
  V_ZERAR_IMPOSTOS_TV14        varchar2(1);
  V_GERAICMSLIVROFISCALTV7     varchar2(1);
  V_LIMITE                     number;
  V_NUMMAPA                    number;
  V_GERABASENORMALQUANDOST     varchar2(1);
  V_IMPEDETIPO14_LIVROFISCAL   varchar2(1);
  V_CONSIDERAISENTOSCOMOPF     varchar2(1);
  V_ARREDVLITENSNFSAIDA        varchar2(1);
  V_TRIBUTAFRETERATEADO        varchar2(1);
  V_TAMANHO_OBS                number;
  V_CONSCALCCREDIPIDANFE       varchar2(1);
  V_REGISTROPCNFSAID           number;
  V_DATA_INICIO_NFE20          date := TO_DATE('01/04/2011', 'DD/MM/YYYY');
  V_VALIDA_VALOR_OUTRAS_IPI    varchar(1);
  V_DATAMAPAANTERIOR           Date;
  V_NUMNOTAINICIAL             number;
  V_NUMNOTAFINAL               number;
  V_CONTADORREGISTRO           number;
  V_QUANTIDADECOMMIT           number;
  V_QTDNF_NO_PERIODO number;
  V_OBS_TEMP                   PCNFBASESAID.OBS%TYPE;
  vnGeraDTENTREGA              varchar2(1);
  /*Declara? das vari?is que substitui a chamada da fun? PARAMFILIAL.OBTERCOMOVARCHAR2 */
  vPARAM_GERARICMSLIVFISCFOP        varchar2(1);
  vPARAM_FIL_REGRAARREDONDAECF      varchar2(1);
  vPARAM_GERARVLCONTCFOP            varchar2(1);
  vPARAM_SOMARIPISTDEVOUTRASDESP    varchar2(1);
  vPARAM_GERALIVRO_VLCONTZERADO     varchar2(1);
  vPARAM_RECALCBASEICMSDIFERIDO     varchar2(1);
  V_NF_CONTABILIZADA number;
  vPARAM_VALIDA_NF_CONTABILIZADA    varchar2(1);
  V_NUMNOTA    number;
  V_NUMTRANSVENDA number;
  -------------------------------------------------------------------------------------------
  cursor C_NOTAS_NF(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
  -- 01 - NOTAS FISCAIS DE VENDA
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           A.NUMTRANSVENDA,
           A.CHAVENFE,
           A.NUMTRANSVENDAORIGEM,
           A.NUMCAR,
           A.CONDVENDA,
           A.ESPECIE,
           A.SERIE,
           A.SUBSERIE,
           A.NUMNOTA,
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           A.DTCANCEL,
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               NVL(B.PERCICM, 0)
           ELSE
              (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                       (B.CODFISCAL in (5929, 6929)) OR
                       (NVL(MC.PERDIFEREIMENTOICMS, 0) = 100) THEN
                  0
               ELSE
                  NVL(B.PERCICM, 0)
               END)
           END) PERCICM,
           ------------------------------------------------------------------
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                          (B.CODFISCAL in (5929, 6929)) THEN
                   NVL(B.PERCICM, 0)
                ELSE
                   0
                END)
            END) PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CLIENTE
                  else
                   C.CLIENTE
                end)) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CGCENT
                  else
                   C.CGCENT
                end)) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.IEENT
                  else
                   C.IEENT
                end)) IE,
           ------------------------------------------------------------------
           NVL(A.UF, (case
                  when A.CODCLI in (1, 2, 3) then
                   (case
                  when NVL(VC.NUMPED, 0) > 0 then
                   VC.ESTENT
                  else
                   V_UFFILIAL
                end) else C.ESTENT end)) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'F'
                  else
                   C.TIPOFJ
                end)) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'S'
                  else
                   C.CONSUMIDORFINAL
                end)) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           A.CODCONT,
           B.CODFISCAL,
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
           CF.CODOPER,
           ------------------------------------------------------------------
           --Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                DECODE(NVL(B.ST,0), 0, DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)), ((B.QTCONT * NVL(B.BASEICMS,0)) + (B.QTCONT * NVL(MC.VLBASEFRETE,0)) + (B.QTCONT * NVL(MC.VLBASEOUTROS,0)))),
                                   DECODE(C.ESTENT, V_UFFILIAL,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)), ((B.QTCONT * NVL(B.BASEICMS,0)) + (B.QTCONT * NVL(MC.VLBASEFRETE,0)) + (B.QTCONT * NVL(MC.VLBASEOUTROS,0)))), 0)),
                         DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)), ((B.QTCONT * NVL(B.BASEICMS,0)) + (B.QTCONT * NVL(MC.VLBASEFRETE,0)) + (B.QTCONT *NVL(MC.VLBASEOUTROS,0))))),2))
            ELSE
               (CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS, 0) = 100) THEN
                   0
                ELSE
                   CASE WHEN (vPARAM_RECALCBASEICMSDIFERIDO = 'S') AND
                              (DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT) = '51') THEN
                     SUM(ROUND(B.QTCONT * (NVL(B.BASEICMS,0) * ((100 - MC.PERDIFEREIMENTOICMS)/100)),2))
                   ELSE
                     SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                         DECODE(V_GERABASENORMALQUANDOST, 'N',
                              DECODE(NVL(B.ST,0), 0, DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), ((B.QTCONT * NVL(B.BASEICMS,0)) + (B.QTCONT * NVL(MC.VLBASEFRETE,0)) + (B.QTCONT * NVL(MC.VLBASEOUTROS,0)))),
                                     DECODE(C.ESTENT, V_UFFILIAL,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)), ((B.QTCONT * NVL(B.BASEICMS,0)) + (B.QTCONT * NVL(MC.VLBASEFRETE,0)) + (B.QTCONT * NVL(MC.VLBASEOUTROS,0)))), 0)),
                             DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), ((B.QTCONT * NVL(B.BASEICMS,0)) + (B.QTCONT * NVL(MC.VLBASEFRETE,0)) + (B.QTCONT *NVL(MC.VLBASEOUTROS,0)))))),2))
                   END
                END)
            END) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           --Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0,
                                              (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                              DECODE(C.ESTENT, V_UFFILIAL,
                                                     (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))), 0)),
                                       (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))), 2))
            END) VLBASENAOTRIB,
           ------------------------------------------------------------------
           --Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.BASEICMS,0), 0, 0,
                         ROUND(DECODE(V_GERABASENORMALQUANDOST,'N', DECODE(NVL(B.ST, 0), 0,
                         GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                  ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),DECODE(C.ESTENT, V_UFFILIAL,
                         GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                  ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                         GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                  ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0) ),2)),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0, DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                         ROUND(DECODE(V_GERABASENORMALQUANDOST,'N', DECODE(NVL(B.ST, 0), 0,
                         GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                  ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),DECODE(C.ESTENT, V_UFFILIAL,
                         GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                  ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                         GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                  ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0) ),2))),2))
            END) VLBASE_REDUCAO,
           ------------------------------------------------------------------
           --Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                DECODE(NVL(B.ST,0), 0, DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)), (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEFRETE,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEOUTROS,0),2))),
                                DECODE(C.ESTENT, V_UFFILIAL,
                                       DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEFRETE,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEOUTROS,0),2))),0)),
                                DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEFRETE,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEOUTROS,0),2)))),2))
            ELSE
               (CASE WHEN (NVL(MC.PERDIFEREIMENTOICMS, 0) = 100) THEN
                   0
                ELSE
                   CASE WHEN (vPARAM_RECALCBASEICMSDIFERIDO = 'S') AND
                              (DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT) = '51') THEN
                     SUM(ROUND(B.QTCONT * (NVL(B.BASEICMS,0) * ((100 - MC.PERDIFEREIMENTOICMS)/100)),2))
                   ELSE
                     SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                                      DECODE(V_GERABASENORMALQUANDOST, 'N',
                                             DECODE(NVL(B.ST,0), 0, DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)), (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEFRETE,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEOUTROS,0),2))),
                                      DECODE(C.ESTENT, V_UFFILIAL,
                                             DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEFRETE,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEOUTROS,0),2))),0)),
                               DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEFRETE,0),2) + ROUND(B.QTCONT * NVL(MC.VLBASEOUTROS,0),2))))),2))
                   END
                END)
            END) VLBASE,
           ------------------------------------------------------------------
           --Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NF', B.ROWID, C.ESTENT, A.CHAVENFE))
            ELSE
               SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'S', FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NF', B.ROWID, C.ESTENT, A.CHAVENFE),0))
            END) VLICMS,
           ------------------------------------------------------------------
           --Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(B.QTCONT *
                         (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                    ((V_GERABASENORMALQUANDOST = 'N') and (NVL(B.ST, 0) > 0) AND
                                     (C.ESTENT <> V_UFFILIAL)) OR (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                             (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)) * NVL(B.PERCICM, 0) / 100
                          ELSE
                             0
                          END), 2))
            END) VLICMSNAOTRIB,
           ------------------------------------------------------------------
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
                  GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                      sum(round(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0)
                      + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)+ NVL(MC.VLFECP,0)), 0),2)) ,0)
               ELSE
                  0
               END VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
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
                 GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                       sum(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) +
                               NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLFECP,0)), 0),2)),0)
               ELSE
                  0
               END VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           A.OBS,
           ------------------------------------------------------------------
           sum(round(
           round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.vlipi,0) - nvl(B.st,0) - nvl(mc.vlfecp,0) ),2) +
           round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
           round((nvl(B.qtcont,0) * nvl(mc.vlfecp,0) ),2) +
           decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
           round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
           ,2)) AS VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           sum(round(
           round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.vlipi,0) - nvl(B.st,0) - nvl(mc.vlfecp,0) ),2) +
           round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
           round((nvl(B.qtcont,0) * nvl(mc.vlfecp,0) ),2) +
           decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
           round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
           ,2)) AS VLDESDOBRADO,
           ------------------------------------------------------------------
           A.VLFRETE,
           DECODE(A.TIPOVENDA,'DF',0,SUM(ROUND(B.QTCONT * NVL(B.VLFRETE, 0), 2))) VLFRETE_MOV,
           ------------------------------------------------------------------
           CASE WHEN (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                      (C.CONSUMIDORFINAL = 'S') or ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                      ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                       (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
              'S'
           ELSE
              'N'
           END FRETEPF,
           ------------------------------------------------------------------
           DECODE(A.CHAVENFE, NULL,
                  GREATEST(ROUND(A.VLOUTRASDESP -
                                 NVL((SELECT ROUND(SUM(QTCONT * VLACRESCIMOPF), 2)
                                      FROM PCMOV
                                      WHERE NUMTRANSVENDA = A.NUMTRANSVENDA
                                        AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                    AND PCMOV.DTMOV BETWEEN P_DATA1 AND P_DATA2
                                        AND QTCONT > 0
                                        AND DTCANCEL IS NULL), 0), 2), 0), NVL(A.VLOUTRASDESP,0)) VLOUTRASDESP,
           ------------------------------------------------------------------
           (GREATEST(A.VLOUTRASDESP -
                     NVL((select ROUND(sum(QTCONT * VLACRESCIMOPF), 2)
                           from PCMOV
                          where NUMTRANSVENDA = A.NUMTRANSVENDA
                            AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
              AND PCMOV.DTMOV BETWEEN P_DATA1 AND P_DATA2
                            and QTCONT > 0
                            and DTCANCEL is null), 0), 0) *
           DECODE(NVL(A.PERBASEREDOUTRASDESP, 0), 0, 100, A.PERBASEREDOUTRASDESP) / 100) VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           NVL((select GREATEST(ROUND(sum(QTCONT * (NVL(VLOUTROS, 0) -
                                         NVL(VLACRESCIMOPF, 0))), 2), 0)
                 from PCMOV
                where NUMTRANSVENDA = A.NUMTRANSVENDA
                  AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
          AND PCMOV.DTMOV BETWEEN P_DATA1 AND P_DATA2
                  and QTCONT > 0
                  and DTCANCEL is null), 0) VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           NVL(A.PERBASEREDOUTRASDESP, 0) PERBASEREDOUTRASDESP,
           A.TIPOVENDA,
           sum(ROUND(NVL(B.BASEICST, 0) * B.QTCONT,2)) BASEST,
           sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
           0 BASESTFORANF,
           0 VLSTFORANF,
           ------------------------------------------------------------------
           sum(case when B.CODFISCAL in (5929, 6929) then
              0
           else
              case
                  when (select max(DESTVALORIPI)
                        from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) IN ('I','O') then
                 0
              else
                 ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
              end
           end) VLBASEIPI,
           ------------------------------------------------------------------
           sum(case when B.CODFISCAL in (5929, 6929) then
              0
           else
              case
                  when (select max(DESTVALORIPI)
                        from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) IN ('I','O') then
                 0
              else
                 ROUND(B.QTCONT * NVL(B.VLIPI, 0),2)
              end
           end) VLIPI,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              NVL(B.PERCIPI, 0)
           end PERCIPI,
           ----------------------------------------------------------------
           sum(
            case
              when B.CODFISCAL in (5929, 6929) then
                0
              else
                case
                  when (select max(DESTVALORIPI)
                        from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                            case
                              when (select max(FORMVALORIPI)
                                    from PCDESTSITTRIBUTIPI
                                    where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                                      ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                                            NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                                            DECODE((select max(FORMVALORIPI)from PCDESTSITTRIBUTIPI
                                                    where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C',
                                                    NVL(B.VLIPI, 0), 0)), 2)
                              else
                                ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
                            end
                 else
                   0
                end
            end) VLBASEISENTASIPI,
           ----------------------------------------------------------------
           sum(
            case
              when B.CODFISCAL in (5929, 6929) then
                0
              else
                case
                  when (select max(DESTVALORIPI)
                        from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'O' then
                            case
                              when (select max(FORMVALORIPI)
                                    from PCDESTSITTRIBUTIPI
                                    where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                                      ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0) - NVL(B.VLDESCONTO, 0) -
                                            NVL(B.VLSUFRAMA, 0) + NVL(B.ST, 0) +
                                            DECODE((select max(FORMVALORIPI)from PCDESTSITTRIBUTIPI
                                                    where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C',
                                                    NVL(B.VLIPI, 0), 0)), 2)
                              else
                                ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
                            end
                else
                  0
                end
            end) VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                       from PCDESTSITTRIBUTIPI
                       where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                         ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2)
                 else
                  0
               end) VLISENTASIPI,
           ----------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                       from PCDESTSITTRIBUTIPI
                       where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'O' then
                    ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2)
                 else
                   0
               end) VLOUTRASIPI,
           ----------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCOFINS), 2)) VLCOFINS,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)), 0) BCIMPESTADUAL,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)), 0) VLIMPESTADUAL,
           ------------------------------------------------------------------
           sum(NVL(B.VLREPASSE, 0) * B.QTCONT) VLREPASSE,
           ------------------------------------------------------------------
           sum(NVL(B.BASEBCR, 0) * B.QTCONT) VLBASEBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.STBCR, 0) * B.QTCONT,2)) VLSTBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLICMSBCR, 0) * B.QTCONT,2)) VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '41', B.QTCONT * B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           SUM(DECODE(B.SITTRIBUT,
                      '20', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0),
                      '70', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0), 0)) VLBASERED_DAPI,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '50', B.QTCONT * B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.ST, 0), 2)) VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS, 0), 2)) VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS, 0), 2)) VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           A.CONTAORDEM,
           A.SITUACAONFE,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) as VLICMSPARTDEST,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) as VLICMSPARTREM ,
           SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) AS VLFCP,
           sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) as VLICMSDIFALIQPART,
           sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) as VLBASEPARTDEST,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
           -- VL.FCP.ICMS 
           CASE WHEN B.CODFISCAL in (5929, 6929) THEN 0 ELSE 
                SUM(DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2))) END VLACRESCIMOFUNCEP,
           --------------
           SUM(DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLFECP,0),2))) VLFECP,
           -- ALIQ.FCP.ICMS
           CASE WHEN B.CODFISCAL in (5929, 6929) THEN 0 ELSE 
                DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP,0)) END PERACRESCIMOFUNCEP,
           ----------------
           -- BASE FCP ICMS
           CASE WHEN B.CODFISCAL in (5929, 6929) THEN 0 ELSE            
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2)) END VLBASEFCPICMS,
           ----------------
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)) ALIQICMSFECP,
           A.DTSAIDA DATA,
           SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS,
           SUM(NVL(DXML.VDESC, 
               ROUND(DECODE(NVL(MC.PRECOUTILIZADONFE, 
                                NVL(NVL(DECODE(NVL(PF.PRECOUTILIZADONFE,'N'), 'N', '', PF.PRECOUTILIZADONFE), 
                                               C.PRECOUTILIZADONFE), 
                                     NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', NVL(A.CODFILIALNF, A.CODFILIAL)), 'L'))),
                           'B', B.QTCONT * NVL(B.VLDESCONTO,0), 0), 2)
           
               )) VL_DESCONTO,
           SUM(NVL(DXML.VPROD, 
               ROUND(B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.ST,0) - NVL(B.VLIPI,0) - NVL(MC.VLIPIDEVFORNEC,0)-
                     NVL(MC.VLFECP,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.ST,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLIPI,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(MC.VLIPIDEVFORNEC,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLFRETE,0)), 2)+
                     DECODE(NVL(A.DOCEMISSAO,'X'), 
                                'CE', 0, 
                                'SF', 0, 
                                'CF', 0, 
                                'MF', 0, 
                                ROUND((NVL(B.QTCONT, 0) * NVL(B.VLFRETE, 0)), 2))              
                 )) VL_PRODUTO
      from PCNFSAID A,
           PCMOV  B,
           PCMOVCOMPLE   MC,
           PCCLIENT C,
           PCVENDACONSUM VC,
           PCFILIAL  F,
           PCCFO CF,
           PCPRODUT P,
           PCPRODFILIAL  PF,
           PCDADOSXML DXML
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       --and NVL(A.CODFILIALNF, A.CODFILIAL) = NVL(B.CODFILIALNF, B.CODFILIAL)
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       AND B.NUMTRANSITEM = DXML.NUMTRANSITEM(+)
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and A.NUMPED = VC.NUMPED(+)
       and P.CODPROD = B.CODPROD
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
       and B.CODPROD = PF.CODPROD(+)
       and B.STATUS in ('A', 'AB')
       and B.QTCONT > 0
       and CF.CODFISCAL(+) = B.CODFISCAL
       and A.ESPECIE in ('NF', 'CO', 'CF', 'NS') --ADICIONADO NS PARA ATUALIAR A CONTA CONTABIL, POR?, FOI CRIADA CONDICIONAL PARA NÏ GERAR O LIVRO PARA ESSA ESPECIE
       and NVL(A.SERIE, 'X') not in ('CF', 'CP')
       and ((A.NUMNOTA >= P_NOTA1) and (A.NUMNOTA <= P_NOTA2))       
       AND A.DTSAIDA BETWEEN P_DATA1 and P_DATA2
     AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
       AND 0 = 0
       AND 0 = 0
       and F.CODIGO = P_CODFILIAL
       and (A.TIPOVENDA <> 'DF' and B.CODOPER <> 'SD')
       and NVL(SUBSTR(A.CHAVENFE, 21,2), 'X') <> '65'
       and NVL(A.DOCEMISSAO, 'X') <> 'SF' -- Retirando lan?entos SAT
       and a.CHAVESAT IS NULL
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              B.SITTRIBUT,
              A.CHAVENFE,
              NVL(A.CLIENTE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CLIENTE
                     else
                      C.CLIENTE
                   end)),
              NVL(A.CGC, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CGCENT
                     else
                      C.CGCENT
                   end)),
              NVL(A.IE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.IEENT
                     else
                      C.IEENT
                   end)),
              NVL(A.UF, (case
                     when A.CODCLI in (1, 2, 3) then
                      (case
                     when NVL(VC.NUMPED, 0) > 0 then
                      VC.ESTENT
                     else
                      V_UFFILIAL
                   end) else C.ESTENT end)),
              NVL(A.TIPOFJ, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'F'
                     else
                      C.TIPOFJ
                   end)),
              NVL(A.CONSUMIDORFINAL, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'S'
                     else
                      C.CONSUMIDORFINAL
                   end)),
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              A.DTCANCEL,
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              A.PERBASEREDOUTRASDESP,
              A.VLFRETE,
              ------------------------------------------------------------------
              (case
                when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                     (C.CONSUMIDORFINAL = 'S') or
                     ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                     ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                     (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
                 'S'
                else
                 'N'
              end),
              ------------------------------------------------------------------
              A.VLOUTRASDESP,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              C.TIPOFJ,
              A.VLTOTAL,
              A.CODCONT,
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
              CF.CODOPER,
              A.OBS,
              A.TIPOVENDA,
              (case
                when B.CODFISCAL in (5929, 6929) then
                 0
                else
                 NVL(B.PERCIPI, 0)
              end),
              A.CONTAORDEM,
              -- Implementados no erro Group By
              A.UF,
              A.CODCLI,
              C.ESTENT,
              VC.NUMPED,
              V_UFFILIAL,
              VC.ESTENT,
              C.TIPOFJ,
              C.UTILIZAIESIMPLIFICADA,
              C.CONSUMIDORFINAL,
              C.CONTRIBUINTE,
              C.IEENT,
              A.SITUACAONFE,
              DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP,0)),
              DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)),NVL(MC.PERDIFEREIMENTOICMS, 0),
              A.DTSAIDA
     order by DTSAIDA, NUMTRANSVENDA, NUMNOTA;
  -------------------------------------------------------------------------------------------
  -- 02 - NFCe
    cursor C_NOTAS_NFCE(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
        select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           A.NUMTRANSVENDA,
           A.CHAVENFE,
           A.NUMTRANSVENDAORIGEM,
           A.NUMCAR,
           A.CONDVENDA,
           A.ESPECIE,
           A.SERIE,
           A.SUBSERIE,
           A.NUMNOTA,
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           A.DTCANCEL,
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               NVL(B.PERCICM, 0)
            ELSE
               (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) OR
                          (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                          (B.CODFISCAL in (5929, 6929)) THEN
                   0
                ELSE
                   NVL(B.PERCICM, 0)
                END)
            END) PERCICM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) OR
                          (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                          (B.CODFISCAL in (5929, 6929)) THEN
                   NVL(B.PERCICM,0)
                ELSE
                   0
                END)
            END) PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CLIENTE
                  else
                   C.CLIENTE
                end)) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CGCENT
                  else
                   C.CGCENT
                end)) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.IEENT
                  else
                   C.IEENT
                end)) IE,
           ------------------------------------------------------------------
           NVL(A.UF, (case
                  when A.CODCLI in (1, 2, 3) then
                   (case
                  when NVL(VC.NUMPED, 0) > 0 then
                   VC.ESTENT
                  else
                   V_UFFILIAL
                end) else C.ESTENT end)) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'F'
                  else
                   C.TIPOFJ
                end)) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'S'
                  else
                   C.CONSUMIDORFINAL
                end)) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           ------------------------------------------------------------------
           A.CODCONT,
           ------------------------------------------------------------------
           B.CODFISCAL,
           ------------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
           ------------------------------------------------------------------
           CF.CODOPER,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(DECODE(NVL(B.BASEICMS,0),0,0,ROUND(B.QTCONT * NVL(B.BASEICMS,0),2)))
            ELSE
               (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                   0
                ELSE
                  --DDFISCAL-14626
                  (CASE WHEN (A.CONDVENDA IN (7,8)) THEN
                     SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                                DECODE(NVL(B.BASEICMS,0),0,0,ROUND(B.QTCONT * NVL(B.BASEICMS,0),2))))
                   ELSE
                     SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                                DECODE(NVL(B.BASEICMS,0),0,0,ROUNDABNT(B.QTCONT * NVL(B.BASEICMS,0),2))))
                   END)
                END)
            END) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
                 SUM( DECODE(NVL(B.BASEICMS,0), 0, 0, DECODE(NVL(B.PERCBASERED,0), 0, (NVL(MC.VLSUBTOTITEM,0) + ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)),
                                                                                      (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2)))))
            ELSE
               (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                   0
                ELSE
                   SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'S', 0,
                              DECODE(NVL(B.BASEICMS,0),0,0,DECODE(NVL(B.PERCBASERED,0), 0,(NVL(MC.VLSUBTOTITEM,0) + ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)),
                                                                                          (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2))))))
                END)
            END) VLBASENAOTRIB,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.BASEICMS,0), 0, 0,
                                ROUND((NVL(MC.VLSUBTOTITEM,0) + ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)) - DECODE(NVL(B.BASEICMS,0),0,0,
                                DECODE(NVL(B.PERCBASERED,0), 0, (NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)) ,(ROUND(B.QTCONT * NVL(B.BASEICMS,0),2)))),2)),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.BASEICMS,0), 0, 0,
                         DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                ROUND((NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)) - DECODE(NVL(B.BASEICMS,0),0,0,
                                DECODE(NVL(B.PERCBASERED,0), 0, (NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)),(ROUND(B.QTCONT * NVL(B.BASEICMS,0),2)))),2))),2))
            END) VLBASE_REDUCAO,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM((ROUNDABNT(B.QTCONT * NVL(B.BASEICMS,0),2)))
            ELSE
              (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                  0
               ELSE
                  --DDFISCAL-15552
                  SUM((ROUNDABNT(B.QTCONT * NVL(B.BASEICMS,0),2)))
               END)
            END) VLBASE,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               ROUND(SUM(FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NFCE', B.ROWID,c.estent, a.chavenfe)), 2)
            ELSE
               ROUND(SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S',FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NFCE', B.ROWID,c.estent, a.chavenfe), 0)),2)
            END) VLICMS,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(B.QTCONT *
                         (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                    (NVL(B.BASEICMS,0) <= 0) or (NVL(B.PERCICM,0) <= 0) THEN
                             DECODE(NVL(B.BASEICMS,0),0,0,DECODE(NVL(B.PERCBASERED,0), 0,
                                    ROUND((NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)) * NVL(B.PERCICM,0) / 100,2),
                                   (ROUND(B.QTCONT * (NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100),2))))
                          ELSE
                             0
                          END), 2))
             END) VLICMSNAOTRIB,
           ------------------------------------------------------------------
           SUM(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
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
                  GREATEST(ROUND( (NVL(MC.VLSUBTOTITEM,0) + ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)) -
                           DECODE(NVL(B.BASEICMS,0), 0, 0,
                                  DECODE(NVL(B.PERCBASERED,0), 0, (NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)),
                                  (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2)))),2),0)
               ELSE
                  0
               END) VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           SUM(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
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
                 GREATEST(ROUND( (NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)) -
                          DECODE(NVL(B.BASEICMS,0), 0, 0,
                                 DECODE(NVL(B.PERCBASERED,0), 0, (NVL(MC.VLSUBTOTITEM,0)+ ROUND(B.QTCONT * NVL(B.VLFRETE,0),2)),
                                        (ROUND(B.QTCONT * NVL(B.BASEICMS,0),2)))),2),0)
               ELSE
                  0
               END) VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           A.OBS,
           ------------------------------------------------------------------
           sum( CASE WHEN MC.VLSUBTOTITEM IS NULL THEN
                     DECODE(NVL(B.TRUNCARITEM, 'S'), 'S', 
                            TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0) + DECODE(NVL(A.DOCEMISSAO,'X'), 'CE', 0, 'SF', 0, 'CF', 0, 'MF', 0, NVL(B.VLFRETE, 0))), 2),
                            ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0) + DECODE(NVL(A.DOCEMISSAO,'X'), 'CE', 0, 'SF', 0, 'CF', 0, 'MF', 0, NVL(B.VLFRETE, 0))), 2))
                     ELSE 
                          (MC.VLSUBTOTITEM + ROUND(B.QTCONT * DECODE(NVL(A.DOCEMISSAO,'X'), 'CE', 0, 'SF', 0, 'CF', 0, 'MF', 0, NVL(B.VLFRETE, 0)),2)) END
              ) VLDESDOBRADO_ARRED_POR_ITEM,
          ------------------------------------------------------------------
           sum( CASE WHEN MC.VLSUBTOTITEM IS NULL THEN
                     DECODE(NVL(B.TRUNCARITEM, 'S'), 'S', 
                            TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0) + DECODE(NVL(A.DOCEMISSAO,'X'), 'CE', 0, 'SF', 0, 'CF', 0, 'MF', 0, NVL(B.VLFRETE, 0))), 2),
                            ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0) + DECODE(NVL(A.DOCEMISSAO,'X'), 'CE', 0, 'SF', 0, 'CF', 0, 'MF', 0, NVL(B.VLFRETE, 0))), 2))
                     ELSE 
                          (MC.VLSUBTOTITEM + ROUND(B.QTCONT * DECODE(NVL(A.DOCEMISSAO,'X'), 'CE', 0, 'SF', 0, 'CF', 0, 'MF', 0, NVL(B.VLFRETE, 0)),2)) END
              ) VLDESDOBRADO,
           ------------------------------------------------------------------
           A.VLFRETE,
           DECODE(A.TIPOVENDA,'DF',0,SUM(ROUND(B.QTCONT * NVL(B.VLFRETE, 0), 2))) VLFRETE_MOV,
           'N' FRETEPF,
           0 VLOUTRASDESP,
           0 VLBASEOUTRASDESP,
           0 VLOUTRASDESP_ITEM,
           0 PERBASEREDOUTRASDESP,
           A.TIPOVENDA,
           0 BASEST,
           0 VLST,
           0 BASESTFORANF,
           0 VLSTFORANF,
           0 VLBASEIPI,
           0 VLIPI,
           0 PERCIPI,
           0 VLISENTASIPI,
           0 VLBASEISENTASIPI,
           0 VLBASEOUTRASIPI,
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           SUM(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S',
                                   NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0,
                            B.QTCONT * NVL(B.VLPIS,0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                            B.QTCONT * NVL(B.VLPIS,0)), 2)) VLPIS,
           ------------------------------------------------------------------
           SUM(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S',
                                   NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0,
                            B.QTCONT * NVL(B.VLCOFINS,0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                            B.QTCONT * NVL(B.VLCOFINS,0)), 2)) VLCOFINS,
           ------------------------------------------------------------------
           0 BCIMPESTADUAL,
           0 VLIMPESTADUAL,
           0 VLREPASSE,
           0 VLBASEBCR,
           0 VLSTBCR,
           0 VLICMSBCR,
           0 VLNAOTRIB_DAPI,
           0 VLBASERED_DAPI,
           0 VLSUSPENSAS_DAPI,
           0 VLST_DAPI,
           0 VLISENTAS_DAPI,
           0 VLOUTRAS_DAPI,
           sysdate DTGERA,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS,0), 2)) VLDESCREDUCAOPIS,
           SUM(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS,0), 2)) VLDESCREDUCAOCOFINS,
           A.CONTAORDEM,
           A.SITUACAONFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) END AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END as VLBASEPARTDEST,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
           SUM(ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2)) VLACRESCIMOFUNCEP,
           SUM(ROUND(B.QTCONT * NVL(MC.VLFECP,0),2)) VLFECP,
           NVL(MC.PERACRESCIMOFUNCEP, 0) PERACRESCIMOFUNCEP,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2)) VLBASEFCPICMS,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           NVL(MC.ALIQICMSFECP, 0) ALIQICMSFECP,
           A.DTSAIDA DATA,
           SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS,
           SUM(NVL(DXML.VDESC,
               CASE WHEN (NVL(B.PERCDESC,0) > 0) AND 
                    (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE',NVL(A.CODFILIALNF, A.CODFILIAL)),'B') <> 'L') THEN
                  ROUND((B.PTABELA * (NVL(B.PERCDESC,0) / 100)) * ROUND(B.QT, 4),2)
               ELSE 
                 0 
               END)) VL_DESCONTO,
           SUM(NVL(DXML.VPROD,
               CASE 
               WHEN NVL(MC.VLSUBTOTITEM, 0) > 0
                  THEN  NVL(MC.VLSUBTOTITEM, 0)
                       + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', NVL(A.CODFILIALNF, A.CODFILIAL)), 'B')
                              , 'B', ROUND((B.PTABELA * (NVL(B.PERCDESC,0) / 100)) * ROUND(B.QT, 4),2)
                              , 0)
               ELSE ROUND(B.QTCONT *
                            (B.PUNITCONT
                             + DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', NVL(A.CODFILIALNF, A.CODFILIAL)), 'B'), 'B', NVL(B.VLDESCONTO, 0), 0)
                             - NVL(B.ST, 0)
                             - NVL(B.VLIPI, 0)
                             - NVL(MC.VLFECP, 0))
                        ,2)
           END)) VL_PRODUTO
      from PCNFSAID      A,
           PCMOV         B,
           PCMOVCOMPLE   MC,
           PCCLIENT      C,
           PCVENDACONSUM VC,
           PCFILIAL      F,
           PCCFO         CF,
           PCPRODUT      P,
           PCPRODFILIAL  PF,
           PCDADOSXML DXML
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       and NVL(A.CODFILIALNF, A.CODFILIAL) = NVL(B.CODFILIALNF, B.CODFILIAL)      
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and B.NUMTRANSITEM = DXML.NUMTRANSITEM(+)       
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and A.NUMPED = VC.NUMPED(+)
       and P.CODPROD = B.CODPROD
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and B.STATUS in ('A', 'AB')
       and B.QTCONT > 0
       and CF.CODFISCAL(+) = B.CODFISCAL
       and A.ESPECIE in ('NF', 'CO', 'CF')
       and NVL(A.SERIE, 'X') not in ('CF', 'CP')
       and NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
       and A.DTSAIDA between P_DATA1 and P_DATA2
     AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
       and ((A.NUMNOTA >= P_NOTA1) and (A.NUMNOTA <= P_NOTA2))
       and (NVL(F.IMPEDETIPO14_LIVROFISCAL, 'N') = 'N'
        or  NVL(A.CONDVENDA, 0) <> 14)
       and NVL(A.CODFILIALNF, A.CODFILIAL) = F.CODIGO
       and (A.TIPOVENDA <> 'DF' and B.CODOPER <> 'SD')
       and NVL(substr(a.chavenfe, 21,2), 'X') = '65'
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              A.CHAVENFE,
              NVL(A.CLIENTE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CLIENTE
                     else
                      C.CLIENTE
                   end)),
              NVL(A.CGC, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CGCENT
                     else
                      C.CGCENT
                   end)),
              NVL(A.IE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.IEENT
                     else
                      C.IEENT
                   end)),
              NVL(A.UF, (case
                     when A.CODCLI in (1, 2, 3) then
                      (case
                     when NVL(VC.NUMPED, 0) > 0 then
                      VC.ESTENT
                     else
                      V_UFFILIAL
                   end) else C.ESTENT end)),
              NVL(A.TIPOFJ, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'F'
                     else
                      C.TIPOFJ
                   end)),
              NVL(A.CONSUMIDORFINAL, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'S'
                     else
                      C.CONSUMIDORFINAL
                   end)),
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              A.DTCANCEL,
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              A.PERBASEREDOUTRASDESP,
              A.VLFRETE,
              ------------------------------------------------------------------
              (case
                when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                     (C.CONSUMIDORFINAL = 'S') or
                     ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                     ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                     (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
                 'S'
                else
                 'N'
              end),
              ------------------------------------------------------------------
              A.VLOUTRASDESP,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              C.TIPOFJ,
              A.VLTOTAL,
              A.CODCONT,
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
              CF.CODOPER,
              A.OBS,
              A.TIPOVENDA,
              MC.PERDIFEREIMENTOICMS,
              (case
                when B.CODFISCAL in (5929, 6929) then
                 0
                else
                 NVL(B.PERCIPI, 0)
              end),
              A.CONTAORDEM,
              -- Implementados no erro Group By
              A.UF,
              A.CODCLI,
              C.ESTENT,
              VC.NUMPED,
              V_UFFILIAL,
              VC.ESTENT,
              C.TIPOFJ,
              C.UTILIZAIESIMPLIFICADA,
              C.CONSUMIDORFINAL,
              C.CONTRIBUINTE,
              C.IEENT,
              A.SITUACAONFE,
              B.DTCANCEL,
              NVL(MC.PERACRESCIMOFUNCEP, 0),
              NVL(MC.ALIQICMSFECP, 0),
              A.DTSAIDA
     order by A.DTSAIDA,
              NUMTRANSVENDA,
              NUMNOTA;
    -------------------------------------------------------------------------------------------
    -- 03 - CUPONS FISCAIS
    cursor C_NOTAS_CUPOM_FISCAL(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    select CODFILIAL,
           NUMTRANSVENDA,
           null CHAVENFE,
           NUMTRANSVENDAORIGEM,
           0 NUMCAR,
           CONDVENDA,
           ESPECIE,
           SERIE,
           SUBSERIE,
           NUMNOTA,
           DTSAIDA,
           DTCANCEL,
           CODCLI,
           PERCICM,
           PERCICMNAOTRIB,
           CLIENTE,
           CNPJ,
           IE,
           UF,
           TIPOFJ,
           CONSUMIDORFINAL,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           sum(VLBASE) VLBASE_ARRED_POR_ITEM,
           sum(VLBASENAOTRIB) VLBASENAOTRIB,
           sum(VLBASE_REDUCAO) VLBASE_REDUCAO,
           sum(VLBASE) VLBASE,
           sum(VLICMS) VLICMS,
           sum(VLICMSNAOTRIB) VLICMSNAOTRIB,
           sum(VLISENTAS) VLISENTAS_ARRED_POR_ITEM,
           sum(VLISENTAS) VLISENTAS,
           sum(VLOUTRAS) VLOUTRAS,
           OBS,
           sum(VLDESDOBRADO) ,
           sum(VLDESDOBRADO) VLDESDOBRADO,
           0 VLFRETE,
           0 VLFRETE_MOV,
           'S' FRETEPF,
           0 VLOUTRASDESP,
           0 VLBASEOUTRASDESP,
           0 VLOUTRASDESP_ITEM,
           0 PERBASEREDOUTRASDESP,
           TIPOVENDA,
           sum(BASEST) BASEST,
           sum(VLST) VLST,
           0 BASESTFORANF,
           0 VLSTFORANF,
           sum(VLBASEIPI) VLBASEIPI,
           sum(VLIPI) VLIPI,
           PERCIPI,
           0 VLISENTASIPI,
           0 VLBASEISENTASIPI,
           0 VLBASEOUTRASIPI,
           0 VLOUTRASIPI,
           sum(VLPIS) VLPIS,
           sum(VLCOFINS) VLCOFINS,
           sum(BCIMPESTADUAL) BCIMPESTADUAL,
           sum(VLIMPESTADUAL) VLIMPESTADUAL,
           sum(VLREPASSE) VLREPASSE,
           sum(VLBASEBCR) VLBASEBCR,
           sum(VLSTBCR) VLSTBCR,
           sum(VLICMSBCR) VLICMSBCR,
           sum(VLNAOTRIB_DAPI) VLNAOTRIB_DAPI,
           sum(VLBASERED_DAPI) VLBASERED_DAPI,
           sum(VLSUSPENSAS_DAPI) VLSUSPENSAS_DAPI,
           sum(VLST_DAPI) VLST_DAPI,
           sum(VLISENTAS_DAPI) VLISENTAS_DAPI,
           sum(VLOUTRAS_DAPI) VLOUTRAS_DAPI,
           DTGERA,
           sum(VLDESCREDUCAOPIS) VLDESCREDUCAOPIS,
           sum(VLDESCREDUCAOCOFINS) VLDESCREDUCAOCOFINS,
           CONTAORDEM,
           SITUACAONFE,
           0 as VLICMSPARTDEST,
           0 as VLICMSPARTREM ,
           0 AS VLFCP ,
           0 as VLICMSDIFALIQPART,
           0 as VLBASEPARTDEST,
           SUM(VLIPIDEVFORNEC) VLIPIDEVFORNEC,
           0 AS VLACRESCIMOFUNCEP,
           0 AS VLFECP,
           0 PERACRESCIMOFUNCEP,
           0 VLBASEFCPICMS,
           0 VLBASEFCPST,
           0 ALIQICMSFECP,
           DATA,
           SUM(VLOUTROS) VLOUTROS,
           0 VL_DESCONTO,
           0 VL_PRODUTO
      from (select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
                   ------------------------------------------------------------------
                   A.NUMTRANSVENDA,
                   ------------------------------------------------------------------
                   A.NUMTRANSVENDAORIGEM,
                   ------------------------------------------------------------------
                   A.CONDVENDA,
                   ------------------------------------------------------------------
                   DECODE(A.ESPECIE, 'CP', 'NF', A.ESPECIE) ESPECIE,
                   ------------------------------------------------------------------
                   DECODE(A.ESPECIE, 'CP', 'CP', DECODE(A.SERIE, 'CP', 'CF', A.SERIE)) SERIE,
                   ------------------------------------------------------------------
                   A.SUBSERIE,
                   ------------------------------------------------------------------
                   A.NUMNOTA,
                   ------------------------------------------------------------------
                   DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
                   ------------------------------------------------------------------
                   A.DTCANCEL,
                   ------------------------------------------------------------------
                   A.CODCLI,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       NVL(B.PERCICM,0)
                    ELSE
                       DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
                    END) PERCICM,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       0
                    ELSE
                       DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0)
                    END) PERCICMNAOTRIB,
                   ------------------------------------------------------------------
                   NVL(A.CLIENTE, DECODE(NVL(VC.NUMPED, 0), 0, C.CLIENTE, VC.CLIENTE)) CLIENTE,
                   ------------------------------------------------------------------
                   NVL(A.CGC, DECODE(NVL(VC.NUMPED, 0), 0, C.CGCENT, VC.CGCENT)) CNPJ,
                   ------------------------------------------------------------------
                   NVL(A.IE, DECODE(NVL(VC.NUMPED, 0), 0, C.IEENT, VC.IEENT)) IE,
                   ------------------------------------------------------------------
                   NVL(A.UF, DECODE(NVL(VC.NUMPED, 0), 0, C.ESTENT, VC.ESTENT)) UF,
                   ------------------------------------------------------------------
                   NVL(A.TIPOFJ, DECODE(NVL(VC.NUMPED, 0), 0, C.TIPOFJ, 'F')) TIPOFJ,
                   ------------------------------------------------------------------
                   NVL(A.CONSUMIDORFINAL, DECODE(NVL(VC.NUMPED, 0), 0, C.CONSUMIDORFINAL, 'S')) CONSUMIDORFINAL,
                   ------------------------------------------------------------------
                   A.VLTOTAL,
                   ------------------------------------------------------------------
                   A.CODCONT,
                   ------------------------------------------------------------------
                   B.CODFISCAL,
                   ------------------------------------------------------------------
                   FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
                   ------------------------------------------------------------------
                   CF.CODOPER,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       SUM(CASE WHEN B.TRUNCARITEM = 'S' THEN
                              TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                    DECODE('N', 'N',
                                           DECODE(NVL(B.ST, 0), 0, (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                           DECODE(C.ESTENT, '1', (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),0)),
                                                                 (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                          ELSE
                              ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                    DECODE('N', 'N',
                                           DECODE(NVL(B.ST, 0), 0, (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                           DECODE(C.ESTENT, '1',(B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),0)),
                                                                (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                          END)
                    ELSE
                       (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                           0
                        ELSE
                           SUM(CASE WHEN B.TRUNCARITEM = 'S' THEN
                                  TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                               DECODE('N', 'N',
                                                      DECODE(NVL(B.ST, 0), 0, (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                                      DECODE(C.ESTENT, '1',(B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),0)),
                                                                           (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                               ELSE
                                  ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                               DECODE('N', 'N',
                                                      DECODE(NVL(B.ST, 0), 0, (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                                      DECODE(C.ESTENT, '1', (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),0)),
                                                                            (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                               END)
                         END)
                    END) VLBASE,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       ROUND(SUM(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                        DECODE(V_GERABASENORMALQUANDOST, 'N',
                                               DECODE(NVL(B.ST, 0), 0, B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.VLIPI,0) - NVL(B.ST,0) - NVL(B.BASEICMS,0)),
                                                      DECODE(C.ESTENT, V_UFFILIAL, B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.VLIPI,0) - NVL(B.ST,0) - NVL(B.BASEICMS,0)), 0)),
                                               B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.VLIPI,0) - NVL(B.ST,0) - NVL(B.BASEICMS,0))))), 2)
                    ELSE
                       ROUND(SUM(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                        DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                               DECODE(V_GERABASENORMALQUANDOST, 'N',
                                                      DECODE(NVL(B.ST, 0), 0, B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.VLIPI,0) - NVL(B.ST,0) - NVL(B.BASEICMS,0)),
                                                             DECODE(C.ESTENT, V_UFFILIAL, B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.VLIPI,0) - NVL(B.ST,0) - NVL(B.BASEICMS,0)), 0)),
                                                      B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.VLIPI,0) - NVL(B.ST,0) - NVL(B.BASEICMS,0)))))), 2)
                    END) VLBASE_REDUCAO,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       ROUND(SUM(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                        DECODE(NVL(B.ST,0), 0, (B.QTCONT *  NVL(B.BASEICMS,0)),
                                               DECODE(C.ESTENT, V_UFFILIAL, (B.QTCONT * NVL(B.BASEICMS, 0)), 0)),
                                        (B.QTCONT * NVL(B.BASEICMS,0)))), 2)
                    ELSE
                       (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                           0
                        ELSE
                           ROUND(SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', 0,
                                            DECODE(V_GERABASENORMALQUANDOST, 'N',
                                                   DECODE(NVL(B.ST,0), 0, (B.QTCONT *  NVL(B.BASEICMS,0)),
                                                          DECODE(C.ESTENT, V_UFFILIAL, (B.QTCONT * NVL(B.BASEICMS, 0)), 0)),
                                                   (B.QTCONT * NVL(B.BASEICMS,0))))), 2)
                        END)
                    END) VLBASENAOTRIB,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       SUM(FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'CP', B.ROWID, C.ESTENT, A.CHAVENFE))
                    ELSE
                       SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'S', FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'CP', B.ROWID, C.ESTENT, A.CHAVENFE), 0))
                    END) VLICMS,
                   ------------------------------------------------------------------
                   -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
                   (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                              (B.CODFISCAL IN (5929, 6929)) THEN
                       ROUND(SUM(B.QTCONT * (CASE WHEN ((V_GERABASENORMALQUANDOST = 'N') AND
                                                       (NVL(B.ST, 0) > 0) AND (C.ESTENT <> V_UFFILIAL)) OR
                                                       (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                                                NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100
                                             ELSE
                                                0
                                             END)), 2)
                    ELSE
                       ROUND(SUM(B.QTCONT * (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR ((V_GERABASENORMALQUANDOST = 'N') AND
                                                       (NVL(B.ST, 0) > 0) AND (C.ESTENT <> V_UFFILIAL)) OR
                                                       (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                                                NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100
                                             ELSE
                                                0
                                             END)), 2)
                    END) VLICMSNAOTRIB,
                   ------------------------------------------------------------------
                   ROUND(sum(case
                               when B.SITTRIBUT in
                                    (select SITTRIBUT
                                       from PCDESTSITTRIBUT
                                      where NVL(VLISENTAS, 'N') = 'S') then
                                GREATEST(ROUND(B.QTCONT * (B.PUNITCONT - NVL(B.ST, 0) -
                                               NVL(B.VLIPI, 0) -
                                               NVL(B.VLDIFALIQUOTAS, 0)), 2) -
                                         ROUND(B.QTCONT *
                                               DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0), 2), 0)
                               else
                                0
                             end), 2) VLISENTAS,
                   ------------------------------------------------------------------
                   0 VLOUTRAS,
                   ------------------------------------------------------------------
                   A.OBS,
                   ------------------------------------------------------------------
                   '1' FLAG,
                   ------------------------------------------------------------------
                   sum(NVL(MC.VLSUBTOTITEM, DECODE(NVL(B.TRUNCARITEM, 'S'), 'S', TRUNC(B.QTCONT *
                                          (B.PUNITCONT +
                                          NVL(B.VLOUTROS, 0)), 2), ROUND(B.QTCONT *
                                          (B.PUNITCONT +
                                          NVL(B.VLOUTROS, 0)), 2)))) VLDESDOBRADO,
                   ------------------------------------------------------------------
                   A.TIPOVENDA,
                   ------------------------------------------------------------------
                   sum(ROUND(NVL(B.BASEICST, 0) * B.QTCONT,2)) BASEST,
                   ------------------------------------------------------------------
                   sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
                   ------------------------------------------------------------------
                   0 VLBASEIPI,
                   ------------------------------------------------------------------
                   0 VLIPI,
                   ------------------------------------------------------------------
                   0 PERCIPI,
                   ------------------------------------------------------------------
                   sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                                     NVL(B.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                                     B.QTCONT * B.VLPIS), 2)) VLPIS,
                   ------------------------------------------------------------------
                   sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                                     NVL(B.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                                     B.QTCONT * B.VLCOFINS), 2)) VLCOFINS,
                   ------------------------------------------------------------------
                   sysdate DTGERA,
                   ------------------------------------------------------------------
                   DECODE(V_UFFILIAL, 'PI', sum(B.QTCONT *
                               NVL(B.BASEACRESCIMOPF, 0)), 'MA', sum(B.QTCONT *
                               NVL(B.BASEACRESCIMOPF, 0)), 0) BCIMPESTADUAL,
                   ------------------------------------------------------------------
                   DECODE(V_UFFILIAL, 'PI', sum(B.QTCONT *
                               NVL(B.VLACRESCIMOPF, 0)), 'MA', sum(B.QTCONT *
                               NVL(B.VLACRESCIMOPF, 0)), 0) VLIMPESTADUAL,
                   ------------------------------------------------------------------
                   sum(NVL(B.VLREPASSE, 0) * B.QTCONT) VLREPASSE,
                   ------------------------------------------------------------------
                   sum(ROUND(NVL(B.BASEBCR, 0) * B.QTCONT,2)) VLBASEBCR,
                   ------------------------------------------------------------------
                   sum(ROUND(NVL(B.STBCR, 0) * B.QTCONT,2)) VLSTBCR,
                   ------------------------------------------------------------------
                   sum(ROUND(NVL(B.VLICMSBCR, 0) * B.QTCONT,2)) VLICMSBCR,
                   ------------------------------------------------------------------
                   sum(DECODE(B.SITTRIBUT, '41', B.QTCONT * B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
                   ------------------------------------------------------------------
                   sum(DECODE(B.SITTRIBUT, '20', B.QTCONT *
                               GREATEST(B.PUNITCONT -
                                        NVL(B.VLIPI, 0) -
                                        NVL(B.ST, 0) -
                                        NVL(B.BASEICMS, 0), 0), '70', B.QTCONT *
                               GREATEST(B.PUNITCONT -
                                        NVL(B.VLIPI, 0) -
                                        NVL(B.ST, 0) -
                                        NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
                   ------------------------------------------------------------------
                   sum(DECODE(B.SITTRIBUT, '50', B.QTCONT * B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
                   ------------------------------------------------------------------
                   sum(ROUND(B.QTCONT * NVL(B.ST, 0), 2)) VLST_DAPI,
                   ------------------------------------------------------------------
                   0 VLISENTAS_DAPI,
                   ------------------------------------------------------------------
                   0 VLOUTRAS_DAPI,
                   ------------------------------------------------------------------
                   sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS, 0), 2)) VLDESCREDUCAOPIS,
                   ------------------------------------------------------------------
                   sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS, 0), 2)) VLDESCREDUCAOCOFINS,
                   ------------------------------------------------------------------
                   A.CONTAORDEM,
                   A.SITUACAONFE,
                   SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
                   SUM(ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2)) VLACRESCIMOFUNCEP,
                   SUM(ROUND(B.QTCONT * NVL(MC.VLFECP,0),2)) VLFECP,
                   A.DTSAIDA DATA,
                   SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS
                   --------------------------------------------------------------------
              from PCNFSAID      A,
                   PCMOV         B,
                   PCMOVCOMPLE   MC,
                   PCCLIENT      C,
                   PCVENDACONSUM VC,
                   PCFILIAL      F,
                   PCCFO         CF,
                   PCPRODUT      P,
                   PCPRODFILIAL  PF
             where A.NUMTRANSVENDA = B.NUMTRANSVENDA
               and MC.NUMTRANSITEM(+) = B.NUMTRANSITEM
               and A.NUMNOTA = B.NUMNOTA
               and C.CODCLI = A.CODCLI
               and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
               and B.CODPROD = PF.CODPROD(+)
               and CF.CODFISCAL(+) = B.CODFISCAL
               and A.NUMPED = VC.NUMPED(+)
               and P.CODPROD(+) = B.CODPROD
               and B.STATUS in ('A', 'AB')
               and B.QTCONT > 0
               and A.ESPECIE in ('NF', 'CF', 'CP')
               and A.SERIE in ('CF', 'CP')
               and (P_INSERIRCF = 'S' OR A.CHAVENFE IS NOT NULL)
               and A.DTSAIDA between P_DATA1 and P_DATA2
         AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
               and ((A.NUMNOTA >= P_NOTA1) and (A.NUMNOTA <= P_NOTA2))
               and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
               and NVL(B.CODFILIALNF, B.CODFILIAL) = F.CODIGO
             group by NVL(A.CODFILIALNF, A.CODFILIAL),
                      A.NUMTRANSVENDA,
                      A.NUMTRANSVENDAORIGEM,
                      A.CONDVENDA,
                      A.ESPECIE,
                      A.SERIE,
                      A.SUBSERIE,
                      NVL(A.CLIENTE, DECODE(NVL(VC.NUMPED, 0), 0, C.CLIENTE, VC.CLIENTE)),
                      NVL(A.CGC, DECODE(NVL(VC.NUMPED, 0), 0, C.CGCENT, VC.CGCENT)),
                      NVL(A.IE, DECODE(NVL(VC.NUMPED, 0), 0, C.IEENT, VC.IEENT)),
                      NVL(A.UF, DECODE(NVL(VC.NUMPED, 0), 0, C.ESTENT, VC.ESTENT)),
                      NVL(A.TIPOFJ, DECODE(NVL(VC.NUMPED, 0), 0, C.TIPOFJ, 'F')),
                      NVL(A.CONSUMIDORFINAL, DECODE(NVL(VC.NUMPED, 0), 0, C.CONSUMIDORFINAL, 'S')),
                      A.NUMNOTA,
                      --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
                      A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
                      A.DTCANCEL,
                      NVL(B.GERAICMSLIVROFISCAL, 'S'),
                      NVL(B.PERCICM, 0),
                      A.CODCLI,
                      C.TIPOFJ,
                      A.VLTOTAL,
                      A.CODCONT,
                      B.CODFISCAL,
                      FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO), NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
                      CF.CODOPER,
                      B.TRUNCARITEM,
                      A.OBS,
                      A.TIPOVENDA,
                      MC.PERDIFEREIMENTOICMS,
                      NVL(B.PERCIPI, 0),
                      A.CONTAORDEM,
                      A.UF,
                      A.CODCLI,
                      C.ESTENT,
                      VC.NUMPED,
                      V_UFFILIAL,
                      VC.ESTENT,
                      A.SITUACAONFE,
                      A.DTSAIDA
                      )
     group by CODFILIAL,
              NUMTRANSVENDA,
              NUMTRANSVENDAORIGEM,
              CONDVENDA,
              ESPECIE,
              SERIE,
              SUBSERIE,
              CLIENTE,
              CNPJ,
              IE,
              UF,
              TIPOFJ,
              CONSUMIDORFINAL,
              NUMNOTA,
              DTSAIDA,
              DTCANCEL,
              CODCLI,
              TIPOFJ,
              PERCICM,
              PERCICMNAOTRIB,
              UF,
              VLTOTAL,
              CODCONT,
              CODFISCAL,
              SITTRIBUT,
              CODOPER,
              OBS,
              FLAG,
              TIPOVENDA,
              PERCIPI,
              DTGERA,
              CONTAORDEM,
              SITUACAONFE,
              DATA
       order by
              DTSAIDA, NUMTRANSVENDA,NUMNOTA;
    -------------------------------------------------------------------------------------------
    -- 04 - DEVOLUCAO A FORNECEDOR
    cursor C_NOTAS_DEV_FORNEC(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ------------------------------------------------------------------
           A.NUMTRANSVENDA,
           ------------------------------------------------------------------
           A.CHAVENFE,
           ------------------------------------------------------------------
           A.NUMTRANSVENDAORIGEM,
           ------------------------------------------------------------------
           A.NUMCAR,
           ------------------------------------------------------------------
           A.CONDVENDA,
           ------------------------------------------------------------------
           DECODE(A.ESPECIE, 'CP', 'NF', A.ESPECIE) ESPECIE,
           ------------------------------------------------------------------
           DECODE(A.ESPECIE, 'CP', 'CP', A.SERIE) SERIE,
           ------------------------------------------------------------------
           A.SUBSERIE,
           ------------------------------------------------------------------
           A.NUMNOTA,
           ------------------------------------------------------------------
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           ------------------------------------------------------------------
           A.DTCANCEL,
           ------------------------------------------------------------------
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               NVL(B.PERCICM,0)
            ELSE
               (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                   0
                ELSE
                   DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(B.PERCICM, 0))
                END)
            END) PERCICM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', NVL(B.PERCICM, 0), 0)
            END) PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, C.CLIENTE) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, C.CGCENT) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, C.IEENT) IE,
           ------------------------------------------------------------------
           NVL(A.UF, C.ESTENT) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, C.TIPOFJ) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, C.CONSUMIDORFINAL) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           ------------------------------------------------------------------
           A.CODCONT,
           ------------------------------------------------------------------
           B.CODFISCAL,
           ------------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, 'N', NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
           ------------------------------------------------------------------
           CF.CODOPER,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                          ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST,0), 0, (B.QTCONT * NVL(B.BASEICMS,0)),
                                              DECODE(C.ESTENT, V_UFFILIAL, (B.QTCONT * NVL(B.BASEICMS,0)), 0)),
                                       (B.QTCONT * NVL(B.BASEICMS,0))), 2)))
            ELSE
               (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) THEN
                   0
                ELSE
                   SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                              ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                           DECODE(NVL(B.ST,0), 0, (B.QTCONT * NVL(B.BASEICMS,0)),
                                                  DECODE(C.ESTENT, V_UFFILIAL, (B.QTCONT * NVL(B.BASEICMS,0)), 0)),
                                           (B.QTCONT * NVL(B.BASEICMS,0))), 2)))
                END)
            END) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) OR
                      ((vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                       (B.CODFISCAL IN (5929, 6929))) THEN
               0
            ELSE
               SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', 0,
                          ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0, (B.QTCONT *  NVL(B.BASEICMS, 0)),
                                              DECODE(C.ESTENT, V_UFFILIAL, (B.QTCONT *  NVL(B.BASEICMS,0)), 0)),
                                       (B.QTCONT * NVL(B.BASEICMS,0))), 2)))
            END) VLBASENAOTRIB,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                ROUND(DECODE(V_GERABASENORMALQUANDOST,'N',
                                             DECODE(NVL(B.ST,0), 0,
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT,0) - B.QTCONT * NVL(B.ST,0) - B.QTCONT * NVL(B.VLIPI,0) -
                                                             ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) ,2) ,0),
                                                    DECODE(C.ESTENT, V_UFFILIAL,
                                                           GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT,0) - B.QTCONT * NVL(B.ST,0) - B.QTCONT * NVL(B.VLIPI,0) -
                                                                    ROUND(B.QTCONT * NVL(B.BASEICMS,0), 2), 2), 0), 0)),
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT,0) -  B.QTCONT * NVL(B.ST,0) - B.QTCONT * NVL(B.VLIPI,0) -
                                                      ROUND(B.QTCONT * NVL(B.BASEICMS,0), 2), 2), 0)), 2)), 2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                       ROUND(DECODE(V_GERABASENORMALQUANDOST,'N',
                                                    DECODE(NVL(B.ST,0), 0,
                                                           GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT,0) - B.QTCONT * NVL(B.ST,0) - B.QTCONT * NVL(B.VLIPI,0) -
                                                                    ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) ,2) ,0),
                                                           DECODE(C.ESTENT, V_UFFILIAL,
                                                                  GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT,0) - B.QTCONT * NVL(B.ST,0) - B.QTCONT * NVL(B.VLIPI,0) -
                                                                           ROUND(B.QTCONT * NVL(B.BASEICMS,0), 2), 2), 0), 0)),
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT,0) -  B.QTCONT * NVL(B.ST,0) - B.QTCONT * NVL(B.VLIPI,0) -
                                                             ROUND(B.QTCONT * NVL(B.BASEICMS,0), 2), 2), 0)), 2))), 2))
            END) VLBASE_REDUCAO,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (MC.PERDIFEREIMENTOICMS = 100) OR
                      ((vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                       (B.CODFISCAL IN (5929, 6929))) THEN
               0
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0, (B.QTCONT * (NVL(B.BASEICMS, 0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                              DECODE(C.ESTENT, V_UFFILIAL,(B.QTCONT * (NVL(B.BASEICMS,0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),0)),
                                       (B.QTCONT * (NVL(B.BASEICMS,0)+ NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2))
           END) VLBASE,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'DF', B.ROWID, C.ESTENT, A.CHAVENFE))
            ELSE
               SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'S', FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'DF', B.ROWID, C.ESTENT, A.CHAVENFE), 0))
            END) VLICMS,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(B.QTCONT *
                         (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                    ((V_GERABASENORMALQUANDOST = 'N') AND (NVL(B.ST, 0) > 0) AND
                                    (C.ESTENT <> V_UFFILIAL)) OR (NVL(B.BASEICMS, 0) <= 0) OR
                                    (NVL(B.PERCICM, 0) <= 0) THEN
                             NVL(B.BASEICMS, 0) * NVL(B.PERCICM, 0) / 100
                          ELSE
                             0
                          END), 2))
            END) VLICMSNAOTRIB,
           ------------------------------------------------------------------
           SUM(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
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
                  GREATEST( round((B.QTCONT * B.PUNITCONT - B.QTCONT * NVL(B.ST, 0) -
                             B.QTCONT * NVL(B.VLIPI, 0) - B.QTCONT * NVL(B.VLDIFALIQUOTAS, 0)),2) -
                            round(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0), 0),2) ,0)
               ELSE
                  0
               END) VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           SUM(CASE WHEN (B.SITTRIBUT IN (SELECT SITTRIBUT
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

                 GREATEST( round( ( B.QTCONT * B.PUNITCONT - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                              B.QTCONT * NVL(B.VLDIFALIQUOTAS, 0) +
                              B.QTCONT * NVL(B.VLOUTROS, 0) - NVL(B.VLACRESCIMOPF, 0)),2) -

                              ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', NVL(B.BASEICMS, 0)
                                                    + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0), 0),2),0)
               ELSE
                  0
               END) VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           A.OBS,
           ------------------------------------------------------------------
           CASE WHEN A.ROTINACAD NOT LIKE '%1302%' then
                SUM(ROUND(B.QTCONT * (B.PUNITCONT - NVL(B.VLFRETE, 0)), 2))
                ELSE
                SUM(ROUND(B.QTCONT *  B.PTABELA,2) - ROUND (B.QTCONT * NVL (B.VLDESCONTO, 0), 2)
                                                   - ROUND (B.QTCONT * NVL (B.VLSUFRAMA, 0), 2)
                                                   - ROUND (B.QTCONT * NVL (MC.VLICMSDESONERACAO, 0), 2)
                                                   + ROUND (B.QTCONT * NVL (NVL(B.VLDESPDENTRONF, 0)
                                                                            - NVL(MC.VLSTOUTRAS, 0)
                                                                            - NVL(MC.VLIPIOUTRAS, 0), 0), 2)
                                                   + ROUND (B.QTCONT * NVL (B.VLSEGURO, 0), 2)
                                                   + ROUND (B.QTCONT * DECODE(NVL(MC.VLSTDEVFORNEC, 0), 0,
                                                                              DECODE(NVL(MC.VLSTOUTRAS, 0), 0, NVL(B.ST, 0), NVL(MC.VLSTOUTRAS, 0)), NVL(MC.VLSTDEVFORNEC,0)),2)
                                                   + ROUND (B.QTCONT * NVL (MC.VLFECP, 0), 2)
                                                   + ROUND (B.QTCONT * DECODE(NVL(MC.VLIPIDEVFORNEC,0),0,
                                                                              DECODE(NVL(MC.VLIPIOUTRAS, 0), 0, NVL(B.VLIPI, 0), NVL(MC.VLIPIOUTRAS, 0)), NVL(MC.VLIPIDEVFORNEC,0)), 2)) END
           VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           CASE WHEN A.ROTINACAD NOT LIKE '%1302%' then
                SUM(ROUND(B.QTCONT * (B.PUNITCONT - NVL(B.VLFRETE, 0)), 2)) -- Calculo anterior
                ELSE
                SUM(ROUND(B.QTCONT *  B.PTABELA,2) - ROUND (B.QTCONT * NVL (B.VLDESCONTO, 0), 2)
                                                   - ROUND (B.QTCONT * NVL (B.VLSUFRAMA, 0), 2)
                                                   - ROUND (B.QTCONT * NVL (MC.VLICMSDESONERACAO, 0), 2)
                                                   + ROUND (B.QTCONT * NVL (NVL(B.VLDESPDENTRONF, 0)
                                                                            - NVL(MC.VLSTOUTRAS, 0)
                                                                            - NVL(MC.VLIPIOUTRAS, 0), 0), 2)
                                                   + ROUND (B.QTCONT * NVL (B.VLSEGURO, 0), 2)
                                                   + ROUND (B.QTCONT * DECODE(NVL(MC.VLSTDEVFORNEC, 0), 0,
                                                                              DECODE(NVL(MC.VLSTOUTRAS, 0), 0, NVL(B.ST, 0), NVL(MC.VLSTOUTRAS, 0)), NVL(MC.VLSTDEVFORNEC,0)),2)
                                                   + ROUND (B.QTCONT * NVL (MC.VLFECP, 0), 2)
                                                   + ROUND (B.QTCONT * DECODE(NVL(MC.VLIPIDEVFORNEC, 0), 0,
                                                                              DECODE(NVL(MC.VLIPIOUTRAS, 0), 0, NVL(B.VLIPI, 0), NVL(MC.VLIPIOUTRAS, 0)), NVL(MC.VLIPIDEVFORNEC,0)), 2)) END
           VLDESDOBRADO,
           ------------------------------------------------------------------

            A.VLFRETE,
            DECODE(A.TIPOVENDA,'DF',0,SUM(ROUND(B.QTCONT * NVL(B.VLFRETE, 0), 2))) VLFRETE_MOV,
           ------------------------------------------------------------------
           case
             when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                  (C.CONSUMIDORFINAL = 'S') or
                  ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                  ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                  (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
              'S'
             else
              'N'
           end FRETEPF,
           ------------------------------------------------------------------
           A.VLOUTRASDESP,
           ------------------------------------------------------------------
           DECODE(NVL(A.PERBASEREDOUTRASDESP, 0), 0, NVL(A.VLOUTRASDESP, 0), NVL(A.VLOUTRASDESP, 0) *
                   NVL(A.PERBASEREDOUTRASDESP, 0) / 100) VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           NVL((select GREATEST(ROUND(sum(QTCONT * (NVL(VLOUTROS, 0) -
                                         NVL(VLACRESCIMOPF, 0))), 2), 0)
                 from PCMOV
                where NUMTRANSVENDA = A.NUMTRANSVENDA
                  AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
          AND PCMOV.DTMOV BETWEEN P_DATA1 AND P_DATA2
                  and QTCONT > 0
                  and DTCANCEL is null), 0) VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           NVL(A.PERBASEREDOUTRASDESP, 0) PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           A.TIPOVENDA,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.BASEICST, 0) * B.QTCONT,2)) BASEST,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLBASESTFORANF, 0) * B.QTCONT, 2)) BASESTFORANF,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLDESPADICIONAL, 0) * B.QTCONT, 2)) VLSTFORANF,
           ------------------------------------------------------------------
           sum(case
               when (V_CONSCALCCREDIPIDANFE = 'N' or B.IMPORTADO = 'D') and
                    (B.CALCCREDIPI = 'S') then
                (B.QTCONT * NVL(B.VLBASEIPI, 0))
               else
                0
               end) VLBASEIPI,
           ------------------------------------------------------------------
           sum(case
               when (V_CONSCALCCREDIPIDANFE = 'N' or B.IMPORTADO = 'D') and
                    (B.CALCCREDIPI = 'S') then
                (B.QTCONT * NVL(B.VLIPI, 0))
               else
                0
               end) VLIPI,
           ------------------------------------------------------------------
           case
             when (V_CONSCALCCREDIPIDANFE = 'N') and
                  (B.CALCCREDIPI = 'S') then
              NVL(B.PERCIPI, 0)
             else
              0
           end PERCIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  case
                 when (V_CONSCALCCREDIPIDANFE = 'N' or B.IMPORTADO = 'D') and
                      (B.CALCCREDIPI = 'S') then
                  0
                 else
                  (B.QTCONT * NVL(B.VLIPI, 0))
               end else 0 end) VLISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  case
                 when (V_CONSCALCCREDIPIDANFE = 'N' or B.IMPORTADO = 'D') and
                      (B.CALCCREDIPI = 'S') then
                  0
                 else
                  case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  (B.QTCONT * NVL(B.VLBASEIPI, 0))
               end end else 0 end) VLBASEISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  case
                 when (V_CONSCALCCREDIPIDANFE = 'N' or B.IMPORTADO = 'D') and
                      (B.CALCCREDIPI = 'S') then
                  0
                 else
                  case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  (B.QTCONT * NVL(B.VLBASEIPI, 0))
               end end end) VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  case
                 when (V_CONSCALCCREDIPIDANFE = 'N' or B.IMPORTADO = 'D') and
                      (B.CALCCREDIPI = 'S') then
                  0
                 else
                  (B.QTCONT * NVL(B.VLIPI, 0))
               end end) VLOUTRASIPI,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLPIS), 2)) VLPIS,
           ------------------------------------------------------------------

           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCOFINS), 2)) VLCOFINS,

           ------------------------------------------------------------------
           DECODE(V_UFFILIAL, 'PI', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)), 'MA', sum(B.QTCONT *
                       NVL(B.BASEACRESCIMOPF, 0)), 0) BCIMPESTADUAL,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL, 'PI', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)), 'MA', sum(B.QTCONT *
                       NVL(B.VLACRESCIMOPF, 0)), 0) VLIMPESTADUAL,
           ------------------------------------------------------------------
           sum(NVL(B.VLREPASSE, 0) * B.QTCONT) VLREPASSE,
           ------------------------------------------------------------------
           sum(NVL(B.BASEBCR, 0) * B.QTCONT) VLBASEBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.STBCR, 0) * B.QTCONT,2)) VLSTBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLICMSBCR, 0) * B.QTCONT,2)) VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '41', B.QTCONT * B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '20', B.QTCONT *
                       GREATEST(B.PUNITCONT -
                                NVL(B.VLIPI, 0) -
                                NVL(B.ST, 0) -
                                NVL(B.BASEICMS, 0), 0), '70', B.QTCONT *
                       GREATEST(B.PUNITCONT -
                                NVL(B.VLIPI, 0) -
                                NVL(B.ST, 0) -
                                NVL(B.BASEICMS, 0), 0), 0)) VLBASERED_DAPI,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '50', B.QTCONT * B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.ST, 0), 2)) VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS, 0), 2)) VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS, 0), 2)) VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           A.CONTAORDEM,
           A.SITUACAONFE,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) END as VLICMSPARTDEST,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) END as VLICMSPARTREM ,
           SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) AS VLFCP,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) END as VLICMSDIFALIQPART,
           CASE WHEN NOT B.DTCANCEL IS NULL THEN 0 ELSE sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) END as VLBASEPARTDEST,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
               DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLACRESCIMOFUNCEP,0),2)))) VLACRESCIMOFUNCEP,
           SUM( DECODE(NVL(MC.VLBASEFCPST,0), 0, 0, ROUND(B.QTCONT * NVL(MC.VLFECP,0),2)  )) VLFECP,
           DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                  DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP, 0))) PERACRESCIMOFUNCEP,
           SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0, ROUND(B.QTCONT * NVL(MC.VLBASEFCPICMS, 0), 2))) VLBASEFCPICMS,
           SUM(ROUND(B.QTCONT * NVL(MC.VLBASEFCPST, 0), 2)) VLBASEFCPST,
           DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)) ALIQICMSFECP,
           A.DTSAIDA DATA,
           SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS,
           SUM(NVL(DXML.VDESC,  ROUND((NVL(B.VLDESCONTO, 0) * B.QTCONT),2))) VL_DESCONTO,
           SUM(NVL(DXML.VPROD,
               CASE WHEN A.ROTINACAD NOT LIKE '%1302%' THEN 
                 ROUND(B.QTCONT * (NVL(B.PUNITCONT, 0) - NVL(B.VLFRETE, 0)), 2)
               ELSE
                 ROUND(B.QTCONT *  NVL(B.PTABELA,0),2)
                 - ROUND(B.QTCONT * NVL(B.VLDESCONTO,0), 2) 
                 - ROUND(B.QTCONT * NVL(B.VLSUFRAMA,0), 2) 
                 - ROUND(B.QTCONT * NVL(MC.VLICMSDESONERACAO,0), 2) 
                 + ROUND(B.QTCONT * NVL(B.VLFRETE,0), 2) 
                 + ROUND(B.QTCONT * NVL(B.VLDESPDENTRONF,0), 2) 
                 + ROUND(B.QTCONT * NVL(B.VLSEGURO,0), 2) 
                 + ROUND(B.QTCONT * NVL(MC.VLFECP,0), 2) 
                 + ROUND(B.QTCONT * DECODE(NVL(MC.VLIPIDEVFORNEC,0),0,NVL (B.VLIPI, 0),NVL(MC.VLIPIDEVFORNEC,0)), 2) 
                 + ROUND(B.QTCONT * DECODE(NVL(MC.VLSTDEVFORNEC,0),0,NVL (B.ST, 0),NVL(MC.VLSTDEVFORNEC,0)), 2) 
               END)) VL_PRODUTO
      from PCNFSAID     A,
           PCMOV        B,
           PCMOVCOMPLE  MC,
           PCCLIENT     C,
           PCCFO        CF,
           PCPRODUT     P,
           PCPRODFILIAL PF,
           PCDADOSXML DXML
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       and B.NUMTRANSITEM = MC.NUMTRANSITEM
       and B.NUMTRANSITEM = DXML.NUMTRANSITEM(+)       
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and B.STATUS in ('A', 'AB')
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and P.CODPROD = B.CODPROD
       and B.QTCONT > 0
       and A.ESPECIE in ('NF', 'CO', 'CF', 'CP')
       and A.DTSAIDA between P_DATA1 and P_DATA2
     AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
       and A.NUMNOTA between P_NOTA1 and P_NOTA2
       and NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
       and (A.TIPOVENDA = 'DF' or B.CODOPER = 'SD')
       and ((NVL(A.SERIE, 'X') <> 'CF') or ('S' = P_INSERIRCF))
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.CHAVENFE,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              NVL(A.CLIENTE, C.CLIENTE),
              NVL(A.CGC, C.CGCENT),
              NVL(A.IE, C.IEENT),
              NVL(A.UF, C.ESTENT),
              NVL(A.TIPOFJ, C.TIPOFJ),
              NVL(A.CONSUMIDORFINAL, C.CONSUMIDORFINAL),
              B.CALCCREDIPI,
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              CF.CODOPER,
              A.DTCANCEL,
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              NVL(A.PERBASEREDOUTRASDESP, 0),
              A.VLFRETE,
              ------------------------------------------------------------------
              case
                when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                     (C.CONSUMIDORFINAL = 'S') or
                     ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                     ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                     (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
                 'S'
                else
                 'N'
              end,
              ------------------------------------------------------------------
              A.VLOUTRASDESP,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              C.TIPOFJ,
              A.VLTOTAL,
              A.CODCONT,
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, 'N', NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
              A.OBS,
              A.TIPOVENDA,
              MC.PERDIFEREIMENTOICMS,
              NVL(B.PERCIPI, 0),
              A.CONTAORDEM,
              A.UF,
              C.ESTENT,
              C.TIPOFJ,
              C.UTILIZAIESIMPLIFICADA,
              C.CONSUMIDORFINAL,
              C.CONTRIBUINTE,
              C.IEENT,
              A.SITUACAONFE,
              B.DTCANCEL,
              DECODE(NVL(MC.VLBASEFCPICMS,0), 0, 0, NVL(MC.PERACRESCIMOFUNCEP, 0)),
              DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0, NVL(MC.ALIQICMSFECP, 0)),
              A.ROTINACAD,
              A.DTSAIDA
       order by
              DTSAIDA,
              NUMTRANSVENDA,
              NUMNOTA;
    -------------------------------------------------------------------------------------------
    -- 05 - NOTAS FISCAIS SEM ITENS E CONHECIMENTO DE FRETE
    cursor C_NOTAS_SEM_ITENS_E_FRETE(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ------------------------------------------------------------------
           A.NUMTRANSVENDA,
           ------------------------------------------------------------------
           A.CHAVENFE,
           ------------------------------------------------------------------
           A.NUMTRANSVENDAORIGEM,
           ------------------------------------------------------------------
           A.NUMCAR,
           ------------------------------------------------------------------
           A.CONDVENDA,
           ------------------------------------------------------------------
           A.ESPECIE,
           ------------------------------------------------------------------
           A.SERIE,
           ------------------------------------------------------------------
           A.SUBSERIE,
           ------------------------------------------------------------------
           A.NUMNOTA,
           ------------------------------------------------------------------
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           ------------------------------------------------------------------
           A.DTCANCEL,
           ------------------------------------------------------------------
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.ALIQUOTA, 0)), 0) PERCICM,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.ALIQUOTA, 0))) PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, C.CLIENTE) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, C.CGCENT) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, C.IEENT) IE,
           ------------------------------------------------------------------
           NVL(A.UF, C.ESTENT) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, C.TIPOFJ) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, C.CONSUMIDORFINAL) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           ------------------------------------------------------------------
           A.CODCONT,
           ------------------------------------------------------------------
           NVL(B.CODFISCAL, A.CODFISCAL) CODFISCAL,
           ------------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(NVL(B.SITTRIBUT, '90'), 'N', '0', A.DTSAIDA) SITTRIBUT,
           ------------------------------------------------------------------
           CF.CODOPER,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', sum(DECODE(NVL(B.ALIQUOTA, 0), 0, 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLBASE, 0)))), 0) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', sum(DECODE(NVL(B.ALIQUOTA, 0), 0, 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', NVL(B.VLBASE, 0), 0))), 0) VLBASENAOTRIB,
           ------------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', sum(DECODE(NVL(B.ALIQUOTA, 0), 0, 0, DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLBASE, 0)))), 0) VLBASE,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', sum(DECODE(B.GERAICMSLIVROFISCAL, 'N', 0, NVL(B.VLICMS, 0))), 0) VLICMS,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '1', sum(DECODE(B.GERAICMSLIVROFISCAL, 'N', NVL(B.VLICMS, 0), 0)), 0) VLICMSNAOTRIB,
           ------------------------------------------------------------------
           CASE WHEN EXISTS (SELECT 1
                             FROM PCMOVCIAP
                             WHERE NUMTRANSVENDA = A.NUMTRANSVENDA) THEN
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
                       SUM(NVL(B.VLCONTABIL,0)-NVL(B.Vlbase,0))
                    ELSE
                       0
                 END
              ELSE
                 SUM(NVL(B.VLISENTAS, 0))
           END VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           CASE WHEN EXISTS (SELECT 1
                             FROM PCMOVCIAP
                             WHERE NUMTRANSVENDA = A.NUMTRANSVENDA) THEN
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
                       SUM(NVL(B.VLCONTABIL,0)-NVL(B.Vlbase,0))
                    ELSE
                       0
                 END
              ELSE
                 SUM(NVL(B.VLISENTAS, 0))
           END VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           A.OBS,
           ------------------------------------------------------------------
           case
             when (select count(*)
                     from PCNFBASE
                    where NUMTRANSVENDA = A.NUMTRANSVENDA) > 1 then
              sum(case
             when B.VLCONTABIL is null then
              NVL(B.VLBASE, 0) + NVL(B.VLISENTAS, 0)
             else
              B.VLCONTABIL
           end) else A.VLTOTAL end VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           case
             when (select count(*)
                     from PCNFBASE
                    where NUMTRANSVENDA = A.NUMTRANSVENDA) > 1 then
              sum(case
             when B.VLCONTABIL is null then
              NVL(B.VLBASE, 0) + NVL(B.VLISENTAS, 0)
             else
              B.VLCONTABIL
           end) else A.VLTOTAL end VLDESDOBRADO,
           ------------------------------------------------------------------
           0 VLFRETE,
           0 VLFRETE_MOV,
           ------------------------------------------------------------------
           'N' FRETEPF,           
           ------------------------------------------------------------------
           0 VLOUTRASDESP,
           ------------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           NVL(A.PERBASEREDOUTRASDESP, 0) PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           A.TIPOVENDA,
           ------------------------------------------------------------------
           A.BCST BASEST,
           ------------------------------------------------------------------
           A.ICMSRETIDO VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '2', sum(NVL(B.VLBASE, 0)), 0) VLBASEIPI,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '2', sum(NVL(B.VLICMS, 0)), 0) VLIPI,
           ------------------------------------------------------------------
           DECODE(B.TIPO, '2', B.ALIQUOTA, 0) PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           A.VLPIS,
           ------------------------------------------------------------------
           A.VLCOFINS,
           ------------------------------------------------------------------
           0 BCIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLREPASSE,
           ------------------------------------------------------------------
           0 VLBASEBCR,
           ------------------------------------------------------------------
           0 VLSTBCR,
           ------------------------------------------------------------------
           0 VLICMSBCR,
           ------------------------------------------------------------------
           (select sum(NVL(VLCONTABIL, VLBASE))
              from PCNFBASE
             where NUMTRANSVENDA = A.NUMTRANSVENDA
               and CODCONT = A.CODCONT
               and TIPO = '1'
               and SITTRIBUT = '41') VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           (select sum(NVL(VLCONTABIL, VLBASE))
              from PCNFBASE
             where NUMTRANSVENDA = A.NUMTRANSVENDA
               and CODCONT = A.CODCONT
               and TIPO = '1'
               and SITTRIBUT = '20') VLBASERED_DAPI,
           ------------------------------------------------------------------
           (select sum(NVL(VLCONTABIL, VLBASE))
              from PCNFBASE
             where NUMTRANSVENDA = A.NUMTRANSVENDA
               and CODCONT = A.CODCONT
               and TIPO = '1'
               and SITTRIBUT = '50') VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           A.ICMSRETIDO VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           A.CONTAORDEM,
           A.SITUACAONFE
           ,sum(NVL(b.VLICMSPARTDEST,0)) AS VLICMSPARTDEST --vICMSUFFim
           ,sum(NVL(b.VLICMSPARTREM,0)) AS VLICMSPARTREM --vICMSUFIni
           ,sum(NVL(B.VLFCPPART,0)) AS VLFCP --vFCPUFFim
           , 0  as VLICMSDIFALIQPART
           , 0  as VLBASEPARTDEST
           , 0 VLIPIDEVFORNEC
    ----------------------------------------------------------------
           ,NVL(ROUND((SELECT SUM(M.QTCONT * NVL(M.VLFCP, 0))
              FROM PCMOVCIAP M
             WHERE M.NUMTRANSVENDA = A.NUMTRANSVENDA
               AND M.CODFISCAL = B.CODFISCAL
               AND M.NUMNOTA = A.NUMNOTA)
            , 2), 0) VLACRESCIMOFUNCEP
    ----------------------------------------------------------------
           , 0 AS VLFECP
    ----------------------------------------------------------------
           ,NVL((SELECT MAX(M.PERCFCP)
              FROM PCMOVCIAP M
             WHERE M.NUMTRANSVENDA = A.NUMTRANSVENDA
               AND M.CODFISCAL = B.CODFISCAL
               AND M.NUMNOTA = A.NUMNOTA)
            ,0) PERACRESCIMOFUNCEP
    ----------------------------------------------------------------
           ,(SELECT SUM(ROUND(M.QTCONT * M.BASECALCFCP, 2))
              FROM PCMOVCIAP M
             WHERE M.NUMTRANSVENDA = A.NUMTRANSVENDA
               AND M.CODFISCAL = B.CODFISCAL
               AND M.NUMNOTA = A.NUMNOTA) VLBASEFCPICMS
    ----------------------------------------------------------------
           , 0 AS VLBASEFCPST
           , 0 AS ALIQICMSFECP
           , A.DTSAIDA DATA
           , 0 AS VLOUTROS,
           (SELECT SUM(ROUND(M.QTCONT * M.VLDESCONTO, 2))
              FROM PCMOVCIAP M
             WHERE M.NUMTRANSVENDA = A.NUMTRANSVENDA
               AND M.CODFISCAL = B.CODFISCAL
               AND M.NUMNOTA = A.NUMNOTA) VL_DESCONTO,
           (SELECT SUM(ROUND(M.QTCONT * M.Punitcont, 2))
              FROM PCMOVCIAP M
             WHERE M.NUMTRANSVENDA = A.NUMTRANSVENDA
               AND M.CODFISCAL = B.CODFISCAL
               AND M.NUMNOTA = A.NUMNOTA) VL_PRODUTO
    -------------------------------------------------------------------
      from PCNFSAID A,
           PCNFBASE B,
           PCCLIENT C,
           PCCFO    CF
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA(+)
       and CF.CODFISCAL(+) = B.CODFISCAL
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and A.ESPECIE in ('CT', 'NF', 'CO', 'NS') --ADICIONADO NS PARA ATUALIAR A CONTA CONTABIL, POR?, FOI CRIADA CONDICIONAL PARA NÏ GERAR O LIVRO PARA ESSA ESPECIE
       and NVL(A.SERIE, 'X') not in ('CF', 'CP')
       and NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and A.DTSAIDA between TO_DATE(P_DATA1) and TO_DATE(P_DATA2)
       and A.NUMNOTA between P_NOTA1 and P_NOTA2

       and not exists (select PCMOV.CODPROD
                         from PCMOV
                        where PCMOV.NUMTRANSVENDA = A.NUMTRANSVENDA 
                          AND PCMOV.NUMNOTA = A.NUMNOTA
                          AND PCMOV.DTMOV = A.DTSAIDA 
                          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL)
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.CHAVENFE,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              A.DTCANCEL,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              NVL(A.CLIENTE, C.CLIENTE),
              NVL(A.CGC, C.CGCENT),
              NVL(A.IE, C.IEENT),
              NVL(A.UF, C.ESTENT),
              NVL(A.TIPOFJ, C.TIPOFJ),
              NVL(A.CONSUMIDORFINAL, C.CONSUMIDORFINAL),
              A.VLPIS,
              A.VLCOFINS,
              NVL(A.PERBASEREDOUTRASDESP, 0),
              B.GERAICMSLIVROFISCAL,
              B.ALIQUOTA,
              A.VLTOTAL,
              A.CODCONT,
              NVL(B.CODFISCAL, A.CODFISCAL),
              B.SITTRIBUT,
              B.CODFISCAL,
              CF.CODOPER,
              A.OBS,
              A.TIPOVENDA,
              A.BCST,
              B.TIPO,
              A.ICMSRETIDO,
              A.CONTAORDEM,
              A.UF,
              C.ESTENT,
              A.SITUACAONFE,
              A.DTSAIDA
       order by
              DTSAIDA,
              NUMTRANSVENDA,
              NUMNOTA;
    -------------------------------------------------------------------------------------------
    -- 06 - REZU??ES Z (TRIBUTADAS)
    cursor C_NOTAS_REDZ_TRIBUT(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    select A.CODFILIAL,
           ------------------------------------------------------------------
           TO_NUMBER('1' ||
                     SUBSTR(TO_CHAR(A.NUMREDUCAOZ, 'FM000000'), 2, 5) ||
                     TO_CHAR(A.NUMECF, 'FM0000')) NUMTRANSVENDA,
           ------------------------------------------------------------------
           null CHAVENFE,
           ------------------------------------------------------------------
           null NUMTRANSVENDAORIGEM,
           ------------------------------------------------------------------
           0 NUMCAR,
           ------------------------------------------------------------------
           1 CONDVENDA,
           ------------------------------------------------------------------
           V_ESPECIE ESPECIE,
           ------------------------------------------------------------------
           V_SERIE SERIE,
           ------------------------------------------------------------------
           '' SUBSERIE,
           ------------------------------------------------------------------
           NVL(A.NUMREDUCAOZ, 0) NUMNOTA,
           ------------------------------------------------------------------
           A.DTEMISSAO DTSAIDA,
           ------------------------------------------------------------------
           null DTCANCEL,
           ------------------------------------------------------------------
           A.NUMECF CODCLI,
           ------------------------------------------------------------------
           NVL(AL.ALIQUOTA,0) PERCICM,
           ------------------------------------------------------------------
           0 PERCICMNAOTRIB,
           ------------------------------------------------------------------
           'CONSUMIDOR FINAL' CLIENTE,
           ------------------------------------------------------------------
           null CNPJ,
           ------------------------------------------------------------------
           null IE,
           ------------------------------------------------------------------
           V_UFFILIAL UF,
           ------------------------------------------------------------------
           'F' TIPOFJ,
           ------------------------------------------------------------------
           'S' CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLCONTABIL VLTOTAL,
           ------------------------------------------------------------------
           C.CODCONTABILCF CODCONT,
           ------------------------------------------------------------------
           AL.CODFISCAL,
           ------------------------------------------------------------------
           '090' SITTRIBUT,
           ------------------------------------------------------------------
           CF.CODOPER,
           ------------------------------------------------------------------
           sum(DECODE(NVL(AL.ALIQUOTA,0), 0, 0, X.VALOR)) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           null VLBASENAOTRIB,
           ------------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ------------------------------------------------------------------
           sum(DECODE(NVL(AL.ALIQUOTA, 0), 0, 0, X.VALOR)) VLBASE,
           ------------------------------------------------------------------
           -- RECALCULAR VLICMS ARREDONDANDO SE PARAMETRO 2263 COMO W.
           CASE WHEN vPARAM_FIL_REGRAARREDONDAECF = 'W' then
                ROUND(sum(X.VALOR) * NVL(AL.ALIQUOTA, 0) / 100, 2)
                else
                TRUNC(sum(X.VALOR) * NVL(AL.ALIQUOTA, 0) / 100, 2) end VLICMS,
           ------------------------------------------------------------------
           0 VLICMSNAOTRIB,
           ------------------------------------------------------------------
           0 VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           0 VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           'CF: ' || NUMCUPOMINICIO || '-' || NUMCUPOMFIM OBS,
           ------------------------------------------------------------------
           sum(X.VALOR) VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           sum(X.VALOR) VLDESDOBRADO,
           ------------------------------------------------------------------
           0 VLFRETE,
           0 VLFRETE_MOV,
           ------------------------------------------------------------------
           'S' FRETEPF,
           ------------------------------------------------------------------
           0 VLOUTRASDESP,
           ------------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           0 PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           'XZ' TIPOVENDA,
           ------------------------------------------------------------------
           0 BASEST,
           ------------------------------------------------------------------
           0 VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           0 VLBASEIPI,
           ------------------------------------------------------------------
           0 VLIPI,
           ------------------------------------------------------------------
           0 PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           0 VLPIS,
           ------------------------------------------------------------------
           0 VLCOFINS,
           ------------------------------------------------------------------
           0 BCIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLREPASSE,
           ------------------------------------------------------------------
           0 VLBASEBCR,
           ------------------------------------------------------------------
           0 VLSTBCR,
           ------------------------------------------------------------------
           0 VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(SUBSTR(X.SITTRIBUT, 1, 1), 'N', VALOR, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           0 VLBASERED_DAPI,
           ------------------------------------------------------------------
           0 VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           0 VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           null CONTAORDEM,
           NULL SITUACAONFE
           ,0 AS VLFCP --vFCPUFFim
           ,0 AS VLICMSPARTDEST --vICMSUFFim
           ,0 AS VLICMSPARTREM --vICMSUFIni
           ,0 as VLICMSDIFALIQPART
           ,0 as VLBASEPARTDEST
           ,0 VLIPIDEVFORNEC
           ,0 AS VLACRESCIMOFUNCEP
           ,0 AS VLFECP
           ,0 AS PERACRESCIMOFUNCEP
           ,0 AS VLBASEFCPICMS
           ,0 AS VLBASEFCPST
           ,0 AS ALIQICMSFECP
           ,A.DTEMISSAO DATA
           ,0 AS VLOUTROS,
           0 VL_DESCONTO,
           0 VL_PRODUTO
    -------------------------------------------------------------------
      from PCCUPOMFISCALZ A,
           PCCUPOMFISCALX X,
           PCALIQUOTACF   AL,
           PCCONSUM       C,
           PCCFO          CF
     where A.NUMECF = X.NUMECF
       and X.CODFILIAL = A.CODFILIAL
       and X.DATA = A.DTEMISSAO
       and AL.SIGLA = X.SITTRIBUT
       and CF.CODFISCAL(+) = AL.CODFISCAL
       and X.DATA between P_DATA1 and P_DATA2
       and SUBSTR(X.SITTRIBUT, 1, 1) not in ('I', 'C', 'D', 'N', 'F')
       and X.CODFILIAL = P_CODFILIAL
       and X.VALOR > 0
     group by A.CODFILIAL,
              C.ESTADO,
              A.NUMREDUCAOZ,
              A.NUMECF,
              A.NUMMAPA,
              A.DTEMISSAO,
              A.NUMCUPOMINICIO,
              A.NUMCUPOMFIM,
              NVL(AL.ALIQUOTA, 0),
              A.NUMECF,
              C.ESTADO,
              A.VLCONTABIL,
              C.CODCONTABILCF,
              AL.CODFISCAL,
              CF.CODOPER;
    -------------------------------------------------------------------------------------------
    -- 07 - REDU??ES Z (CANCELADAS)
    cursor C_NOTAS_REDZ_CANC(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
           select A.CODFILIAL,
           ------------------------------------------------------------------
           TO_NUMBER('1' ||
                     SUBSTR(TO_CHAR(A.NUMREDUCAOZ, 'FM000000'), 2, 5) ||
                     TO_CHAR(A.NUMECF, 'FM0000')) NUMTRANSVENDA,
           ------------------------------------------------------------------
           null CHAVENFE,
           ------------------------------------------------------------------
           null NUMTRANSVENDAORIGEM,
           ------------------------------------------------------------------
           0 NUMCAR,
           ------------------------------------------------------------------
           1 CONDVENDA,
           ------------------------------------------------------------------
           V_ESPECIE ESPECIE,
           ------------------------------------------------------------------
           V_SERIE SERIE,
           ------------------------------------------------------------------
           '' SUBSERIE,
           ------------------------------------------------------------------
           NVL(A.NUMREDUCAOZ, 0) NUMNOTA,
           ------------------------------------------------------------------
           A.DTEMISSAO DTSAIDA,
           ------------------------------------------------------------------
           null DTCANCEL,
           ------------------------------------------------------------------
           A.NUMECF CODCLI,
           ------------------------------------------------------------------
           0 PERCICM,
           ------------------------------------------------------------------
           0 PERCICMNAOTRIB,
           ------------------------------------------------------------------
           'CONSUMIDOR FINAL' CLIENTE,
           ------------------------------------------------------------------
           null CNPJ,
           ------------------------------------------------------------------
           null IE,
           ------------------------------------------------------------------
           V_UFFILIAL UF,
           ------------------------------------------------------------------
           'F' TIPOFJ,
           ------------------------------------------------------------------
           'S' CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLCONTABIL VLTOTAL,
           ------------------------------------------------------------------
           C.CODCONTABILCF CODCONT,
           ------------------------------------------------------------------
           NVL((select min(CODFISCAL) from PCALIQUOTACF), 0) CODFISCAL,
           ------------------------------------------------------------------
           '090' SITTRIBUT,
           ------------------------------------------------------------------
           'S' CODOPER,
           ------------------------------------------------------------------
           0 VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           0 VLBASENAOTRIB,
           ------------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ------------------------------------------------------------------
           0 VLBASE,
           ------------------------------------------------------------------
           0 VLICMS,
           ------------------------------------------------------------------
           0 VLICMSNAOTRIB,
           ------------------------------------------------------------------
           0 VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           0 VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           'SEM MOVIMENTO' OBS,
           ------------------------------------------------------------------
           0 VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           0 VLDESDOBRADO,
           ------------------------------------------------------------------
           0 VLFRETE,
           0 VLFRETE_MOV,
           ------------------------------------------------------------------
           'S' FRETEPF,
           ------------------------------------------------------------------
           0 VLOUTRASDESP,
           ------------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           0 PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           'XZ' TIPOVENDA,
           ------------------------------------------------------------------
           0 BASEST,
           ------------------------------------------------------------------
           0 VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           0 VLBASEIPI,
           ------------------------------------------------------------------
           0 VLIPI,
           ------------------------------------------------------------------
           0 PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           0 VLPIS,
           ------------------------------------------------------------------
           0 VLCOFINS,
           ------------------------------------------------------------------
           0 BCIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLREPASSE,
           ------------------------------------------------------------------
           0 VLBASEBCR,
           ------------------------------------------------------------------
           0 VLSTBCR,
           ------------------------------------------------------------------
           0 VLICMSBCR,
           ------------------------------------------------------------------
           0 VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           0 VLBASERED_DAPI,
           ------------------------------------------------------------------
           0 VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           0 VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           null CONTAORDEM,
           NULL SITUACAONFE
           ,0 AS VLFCP --vFCPUFFim
           ,0 AS VLICMSPARTDEST --vICMSUFFim
           ,0 AS VLICMSPARTREM --vICMSUFIni
           ,0 as VLICMSDIFALIQPART
           ,0 as VLBASEPARTDEST
           ,0 VLIPIDEVFORNEC
           ,0 AS VLACRESCIMOFUNCEP
           ,0 AS VLFECP
           ,0 AS PERACRESCIMOFUNCEP
           ,0 AS VLBASEFCPICMS
           ,0 AS VLBASEFCPST
           ,0 AS ALIQICMSFECP
           ,A.DTEMISSAO DATA
           ,0 AS VLOUTROS,
           0 VL_DESCONTO,
           0 VL_PRODUTO
      from PCCUPOMFISCALZ A,
           PCCONSUM       C
     where A.DTEMISSAO between P_DATA1 and P_DATA2
       and A.CODFILIAL = P_CODFILIAL
       and NVL(A.VLCONTABIL, 0) = 0
     group by A.CODFILIAL,
              C.ESTADO,
              A.NUMREDUCAOZ,
              A.NUMECF,
              A.NUMMAPA,
              A.DTEMISSAO,
              A.NUMCUPOMINICIO,
              A.NUMCUPOMFIM,
              A.NUMECF,
              C.ESTADO,
              A.VLCONTABIL,
              C.CODCONTABILCF
       order by
              DTSAIDA,
              NUMTRANSVENDA,
              NUMNOTA;
    -------------------------------------------------------------------------------------------
    -- 08 - REDU??ES Z (N?O TRIBUTADAS)
    cursor C_NOTAS_REDZ_N_TRIB(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    select A.CODFILIAL,
           ------------------------------------------------------------------
           TO_NUMBER('1' ||
                     SUBSTR(TO_CHAR(A.NUMREDUCAOZ, 'FM000000'), 2, 5) ||
                     TO_CHAR(A.NUMECF, 'FM0000')) NUMTRANSVENDA,
           ------------------------------------------------------------------
           null CHAVENFE,
           ------------------------------------------------------------------
           null NUMTRANSVENDAORIGEM,
           ------------------------------------------------------------------
           0 NUMCAR,
           ------------------------------------------------------------------
           1 CONDVENDA,
           ------------------------------------------------------------------
           V_ESPECIE ESPECIE,
           ------------------------------------------------------------------
           V_SERIE SERIE,
           ------------------------------------------------------------------
           '' SUBSERIE,
           ------------------------------------------------------------------
           NVL(A.NUMREDUCAOZ, 0) NUMNOTA,
           ------------------------------------------------------------------
           A.DTEMISSAO DTSAIDA,
           ------------------------------------------------------------------
           null DTCANCEL,
           ------------------------------------------------------------------
           A.NUMECF CODCLI,
           ------------------------------------------------------------------
           NVL(AL.ALIQUOTA, 0) PERCICM,
           ------------------------------------------------------------------
           0 PERCICMNAOTRIB,
           ------------------------------------------------------------------
           'CONSUMIDOR FINAL' CLIENTE,
           ------------------------------------------------------------------
           null CNPJ,
           ------------------------------------------------------------------
           null IE,
           ------------------------------------------------------------------
           V_UFFILIAL UF,
           ------------------------------------------------------------------
           'F' TIPOFJ,
           ------------------------------------------------------------------
           'S' CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLCONTABIL VLTOTAL,
           ------------------------------------------------------------------
           C.CODCONTABILCF CODCONT,
           ------------------------------------------------------------------
           AL.CODFISCAL,
           ------------------------------------------------------------------
           '090' SITTRIBUT,
           ------------------------------------------------------------------
           CF.CODOPER,
           ------------------------------------------------------------------
           0 VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           0 VLBASENAOTRIB,
           ------------------------------------------------------------------
           0 VLBASE_REDUCAO,
           ------------------------------------------------------------------
           0 VLBASE,
           ------------------------------------------------------------------
           0 VLICMS,
           ------------------------------------------------------------------
           0 VLICMSNAOTRIB,
           ------------------------------------------------------------------
           sum(DECODE(SUBSTR(X.SITTRIBUT, 1, 1), 'I', X.VALOR, 0)) VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           sum(DECODE(SUBSTR(X.SITTRIBUT, 1, 1), 'I', X.VALOR, 0)) VLISENTAS,
           ------------------------------------------------------------------
           sum(DECODE(SUBSTR(X.SITTRIBUT, 1, 1), 'F', X.VALOR, 'N', X.VALOR, 0)) VLOUTRAS,
           ------------------------------------------------------------------
           'CF: ' || NUMCUPOMINICIO || '-' || NUMCUPOMFIM OBS,
           ------------------------------------------------------------------
           sum(X.VALOR) VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           sum(X.VALOR) VLDESDOBRADO,
           ------------------------------------------------------------------
           0 VLFRETE,
           0 VLFRETE_MOV,
           ------------------------------------------------------------------
           'S' FRETEPF,
           ------------------------------------------------------------------
           0 VLOUTRASDESP,
           ------------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           0 PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           'XZ' TIPOVENDA,
           ------------------------------------------------------------------
           0 BASEST,
           ------------------------------------------------------------------
           0 VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           0 VLBASEIPI,
           ------------------------------------------------------------------
           0 VLIPI,
           ------------------------------------------------------------------
           0 PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEISENTASIPI,
           ------------------------------------------------------------------
           0 VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           0 VLPIS,
           ------------------------------------------------------------------
           0 VLCOFINS,
           ------------------------------------------------------------------
           0 BCIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLIMPESTADUAL,
           ------------------------------------------------------------------
           0 VLREPASSE,
           ------------------------------------------------------------------
           0 VLBASEBCR,
           ------------------------------------------------------------------
           0 VLSTBCR,
           ------------------------------------------------------------------
           0 VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(SUBSTR(X.SITTRIBUT, 1, 1), 'N', VALOR, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           0 VLBASERED_DAPI,
           ------------------------------------------------------------------
           0 VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           0 VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           0 VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           null CONTAORDEM,
           NULL SITUACAONFE
           ,0 AS VLFCP --vFCPUFFim
           ,0 AS VLICMSPARTDEST --vICMSUFFim
           ,0 AS VLICMSPARTREM --vICMSUFIni
           ,0 as VLICMSDIFALIQPART
           ,0 as VLBASEPARTDEST
           ,0 VLIPIDEVFORNEC
           ,0 AS VLACRESCIMOFUNCEP
           ,0 AS VLFECP
           ,0 AS PERACRESCIMOFUNCEP
           ,0 AS VLBASEFCPICMS
           ,0 AS VLBASEFCPST
           ,0 AS ALIQICMSFECP
           ,A.DTEMISSAO DATA
           ,0 AS VLOUTROS,
           0 VL_DESCONTO,
           0 VL_PRODUTO
    -------------------------------------------------------------------
      from PCCUPOMFISCALZ A,
           PCCUPOMFISCALX X,
           PCALIQUOTACF   AL,
           PCCONSUM       C,
           PCCFO          CF
     where A.NUMECF = X.NUMECF
       and X.DATA = A.DTEMISSAO
       and X.CODFILIAL = A.CODFILIAL
       and AL.SIGLA = X.SITTRIBUT
       and CF.CODFISCAL(+) = AL.CODFISCAL
       and X.DATA between P_DATA1 and P_DATA2
       and SUBSTR(X.SITTRIBUT, 1, 1) in ('I', 'N', 'F')
       and X.SITTRIBUT <> 'ISS'
       and X.CODFILIAL = P_CODFILIAL
       and X.VALOR > 0
     group by A.CODFILIAL,
              C.ESTADO,
              A.NUMREDUCAOZ,
              A.NUMECF,
              AL.CODFISCAL,
              CF.CODOPER,
              NVL(AL.ALIQUOTA, 0),
              A.NUMMAPA,
              A.NUMECF,
              A.NUMREDUCAOZ,
              A.DTEMISSAO,
              A.NUMCUPOMINICIO,
              A.NUMCUPOMFIM,
              C.ESTADO,
              C.CODCONTABILCF,
              C.CODCONTCLI,
              A.VLCONTABIL
       order by
              DTSAIDA,
              NUMTRANSVENDA,
              NUMNOTA;

cursor C_NOTAS_COMPLEMETAR_COM_ITEM(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    -- 09 - NOTAS FISCAIS COMPLEMENTARES COM ITEM
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           ------------------------------------------------------------------
           A.NUMTRANSVENDA,
           ------------------------------------------------------------------
           A.CHAVENFE,
           ------------------------------------------------------------------
           A.NUMTRANSVENDAORIGEM,
           ------------------------------------------------------------------
           A.NUMCAR,
           ------------------------------------------------------------------
           A.CONDVENDA,
           ------------------------------------------------------------------
           A.ESPECIE,
           ------------------------------------------------------------------
           A.SERIE,
           ------------------------------------------------------------------
           A.SUBSERIE,
           ------------------------------------------------------------------
           A.NUMNOTA,
           ------------------------------------------------------------------
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           ------------------------------------------------------------------
           A.DTCANCEL,
           ------------------------------------------------------------------
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               NVL(B.PERCICM, 0)
            ELSE
               (CASE WHEN (NVL(B.GERAICMSLIVROFISCAL,'S') = 'N') OR
                          (B.CODFISCAL IN (5929, 6929)) THEN
                   0
                ELSE
                   NVL(B.PERCICM, 0)
                END)
            END) PERCICM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                         (B.CODFISCAL in (5929, 6929)) then
                  NVL(B.PERCICM, 0)
               ELSE
                  0
               END
            END) PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CLIENTE
                  else
                   C.CLIENTE
                end)) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CGCENT
                  else
                   C.CGCENT
                end)) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.IEENT
                  else
                   C.IEENT
                end)) IE,
           ------------------------------------------------------------------
           NVL(A.UF, (case
                  when A.CODCLI in (1, 2, 3) then
                   (case
                  when NVL(VC.NUMPED, 0) > 0 then
                   VC.ESTENT
                  else
                   V_UFFILIAL
                end) else C.ESTENT end)) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'F'
                  else
                   C.TIPOFJ
                end)) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'S'
                  else
                   C.CONSUMIDORFINAL
                end)) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           ------------------------------------------------------------------
           A.CODCONT,
           ------------------------------------------------------------------
           B.CODFISCAL,
           ------------------------------------------------------------------
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
           ------------------------------------------------------------------
           CF.CODOPER,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                                DECODE(NVL(B.ST,0), 0,
                                       DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                       DECODE(C.ESTENT, V_UFFILIAL,
                                              DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0)))))),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST,0), 0,
                                              DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                              DECODE(C.ESTENT, V_UFFILIAL,
                                                     DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                       DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0))))))),2))
            END) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0,
                                              (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                              DECODE(C.ESTENT, V_UFFILIAL,
                                                     (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))), 0)),
                                       (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2))
            END) VLBASENAOTRIB,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                ROUND(DECODE(V_GERABASENORMALQUANDOST,'N', DECODE(NVL(B.ST, 0), 0,
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                      ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),DECODE(C.ESTENT, V_UFFILIAL,
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                      ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                      ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0)),2)),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                       ROUND(DECODE(V_GERABASENORMALQUANDOST,'N', DECODE(NVL(B.ST, 0), 0,
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),DECODE(C.ESTENT, V_UFFILIAL,
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0)),2))),2))
            END) VLBASE_REDUCAO,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                DECODE(NVL(B.ST, 0), 0, decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                       DECODE(C.ESTENT, V_UFFILIAL,
                                              DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)),
                                                     (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                         DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0, decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                              DECODE(C.ESTENT, V_UFFILIAL,
                                                     DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)),
                                                            (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2))
            END) VLBASE,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NF', B.ROWID, C.ESTENT, A.CHAVENFE))
            ELSE
               SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'S', FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NF', B.ROWID, C.ESTENT, A.CHAVENFE),0))
            END) VLICMS,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(B.QTCONT *
                         CASE WHEN (NVL(B.GERAICMSLIVROFISCAL,'S') = 'N') OR
                                   ((V_GERABASENORMALQUANDOST = 'N') and (NVL(B.ST,0) > 0) AND
                                   (C.ESTENT <> V_UFFILIAL)) OR (NVL(B.BASEICMS,0) <= 0) OR (NVL(B.PERCICM,0) <= 0) THEN
                           (NVL(B.BASEICMS,0) + NVL(MC.VLBASEOUTROS,0) + NVL(MC.VLBASEFRETE,0)) * NVL(B.PERCICM,0) / 100
                        ELSE
                           0
                        END, 2))
            END) VLICMSNAOTRIB,
           ------------------------------------------------------------------
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
                  GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                       sum(round(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)), 0),2)) ,0)
               ELSE
                  0
               END VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
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
                 GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                       sum(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) +
                           NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)), 0),2)),0)
               ELSE
                  0
               END VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           A.OBS,
           ------------------------------------------------------------------
           ------------------------------------------------------------------
           sum(round(
           round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0) - nvl(mc.vlfecp,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
           round((nvl(B.qtcont,0) * nvl(mc.vlfecp,0) ),2) +
           decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
           round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
           ,2)) AS VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           ------------------------------------------------------------------
           sum(round(
           round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)  - nvl(mc.vlfecp,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
           round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
           round((nvl(B.qtcont,0) * nvl(mc.vlfecp,0) ),2) +
           decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
           round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
           ,2)) AS VLDESDOBRADO,
           ------------------------------------------------------------------
           A.VLFRETE,
           DECODE(A.TIPOVENDA,'DF',0,SUM(ROUND(B.QTCONT * NVL(B.VLFRETE, 0), 2))) VLFRETE_MOV,
           ------------------------------------------------------------------
           CASE WHEN (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                      (C.CONSUMIDORFINAL = 'S') or ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                      ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                       (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
              'S'
           ELSE
              'N'
           END FRETEPF,
           ------------------------------------------------------------------
           DECODE(A.CHAVENFE, NULL,
                  GREATEST(ROUND(A.VLOUTRASDESP -
                                 NVL((SELECT ROUND(SUM(QTCONT * VLACRESCIMOPF), 2)
                                      FROM PCMOV
                                      WHERE NUMTRANSVENDA = A.NUMTRANSVENDA
                      AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                                        AND QTCONT > 0
                                        AND DTCANCEL IS NULL), 0), 2), 0), NVL(A.VLOUTRASDESP,0)) VLOUTRASDESP,
           ------------------------------------------------------------------
           (GREATEST(A.VLOUTRASDESP -
                     NVL((select ROUND(sum(QTCONT * VLACRESCIMOPF), 2)
                           from PCMOV
                          where NUMTRANSVENDA = A.NUMTRANSVENDA
                AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                            and QTCONT > 0
                            and DTCANCEL is null), 0), 0) *
           DECODE(NVL(A.PERBASEREDOUTRASDESP, 0), 0, 100, A.PERBASEREDOUTRASDESP) / 100) VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           NVL((select GREATEST(ROUND(sum(QTCONT * (NVL(VLOUTROS, 0) -
                                         NVL(VLACRESCIMOPF, 0))), 2), 0)
                 from PCMOV
                where NUMTRANSVENDA = A.NUMTRANSVENDA
          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                  and QTCONT > 0
                  and DTCANCEL is null), 0) VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           NVL(A.PERBASEREDOUTRASDESP, 0) PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           A.TIPOVENDA,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.BASEICST, 0) * B.QTCONT,2)) BASEST,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              sum(DECODE(NVL(B.PERCIPI, 0), 0, 0, ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)))
           end VLBASEIPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2)) VLIPI,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              NVL(B.PERCIPI, 0)
           end PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  case
                 when B.CODFISCAL in (5929, 6929) then
                  0
                 else
                  DECODE(NVL(B.PERCIPI, 0), 0, case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0) end else 0 end) VLBASEISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  case
                 when B.CODFISCAL in (5929, 6929) then
                  0
                 else
                  DECODE(NVL(B.PERCIPI, 0), 0, case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0) end end) VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCOFINS), 2)) VLCOFINS,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)), 0) BCIMPESTADUAL,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)), 0) VLIMPESTADUAL,
           ------------------------------------------------------------------
           sum(NVL(B.VLREPASSE, 0) * B.QTCONT) VLREPASSE,
           ------------------------------------------------------------------
           sum(NVL(B.BASEBCR, 0) * B.QTCONT) VLBASEBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.STBCR, 0) * B.QTCONT,2)) VLSTBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLICMSBCR, 0) * B.QTCONT,2)) VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '41', B.QTCONT * B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           SUM(DECODE(B.SITTRIBUT,
                      '20', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0),
                      '70', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0), 0)) VLBASERED_DAPI,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '50', B.QTCONT * B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.ST, 0), 2)) VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS, 0), 2)) VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS, 0), 2)) VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           A.CONTAORDEM,
           A.SITUACAONFE,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) as VLICMSPARTDEST,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) as VLICMSPARTREM ,
           SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) AS VLFCP,
           sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) as VLICMSDIFALIQPART,
           sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) as VLBASEPARTDEST,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
           0 VLACRESCIMOFUNCEP,
           0 VLFECP,
           0 PERACRESCIMOFUNCEP,
           0 VLBASEFCPICMS,
           0 VLBASEFCPST,
           0 ALIQICMSFECP,
           A.DTSAIDA DATA,
           SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS,
           SUM(NVL(DXML.VDESC, 
               ROUND(DECODE(NVL(MC.PRECOUTILIZADONFE, 
                                NVL(NVL(DECODE(NVL(PF.PRECOUTILIZADONFE,'N'), 'N', '', PF.PRECOUTILIZADONFE), 
                                               C.PRECOUTILIZADONFE), 
                                     NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', NVL(A.CODFILIALNF, A.CODFILIAL)), 'L'))),
                           'B', B.QTCONT * NVL(B.VLDESCONTO,0), 0), 2)
           
               )) VL_DESCONTO,
           SUM(NVL(DXML.VPROD, 
               ROUND(B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.ST,0) - NVL(B.VLIPI,0) - NVL(MC.VLIPIDEVFORNEC,0)-
                     NVL(MC.VLFECP,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.ST,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLIPI,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(MC.VLIPIDEVFORNEC,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLFRETE,0)), 2)+
                     DECODE(NVL(A.DOCEMISSAO,'X'), 
                                'CE', 0, 
                                'SF', 0, 
                                'CF', 0, 
                                'MF', 0, 
                                ROUND((NVL(B.QTCONT, 0) * NVL(B.VLFRETE, 0)), 2))              
                 )) VL_PRODUTO
      from PCNFSAID      A,
           PCMOV         B,
           PCMOVCOMPLE   MC,
           PCCLIENT      C,
           PCVENDACONSUM VC,
           PCFILIAL      F,
           PCCFO         CF,
           PCPRODUT      P,
           PCPRODFILIAL  PF,
           PCDADOSXML DXML
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       --and A.CODFILIAL = B.CODFILIAL       
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and B.NUMTRANSITEM = DXML.NUMTRANSITEM(+)       
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and A.NUMPED = VC.NUMPED(+)
       and P.CODPROD = B.CODPROD
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and B.STATUS in ('A', 'AB')
       and B.QTCONT = 0
       AND A.FINALIDADENFE = 'C'
       and CF.CODFISCAL(+) = B.CODFISCAL
       and A.ESPECIE in ('NF', 'CO', 'CF')
       and NVL(A.SERIE, 'X') not in ('CF', 'CP')
       and NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
       and A.DTSAIDA between P_DATA1 and P_DATA2
     AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
       and ((A.NUMNOTA >= P_NOTA1) and (A.NUMNOTA <= P_NOTA2))
       and (NVL(F.IMPEDETIPO14_LIVROFISCAL, 'N') = 'N' or
            NVL(A.CONDVENDA, 0) <> 14)

       and NVL(A.CODFILIALNF, A.CODFILIAL) = F.CODIGO
       and (A.TIPOVENDA <> 'DF' and B.CODOPER <> 'SD')
       and NVL(SUBSTR(A.CHAVENFE, 21,2), 'X') <> '65'
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              B.SITTRIBUT,
              A.CHAVENFE,
              NVL(A.CLIENTE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CLIENTE
                     else
                      C.CLIENTE
                   end)),
              NVL(A.CGC, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CGCENT
                     else
                      C.CGCENT
                   end)),
              NVL(A.IE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.IEENT
                     else
                      C.IEENT
                   end)),
              NVL(A.UF, (case
                     when A.CODCLI in (1, 2, 3) then
                      (case
                     when NVL(VC.NUMPED, 0) > 0 then
                      VC.ESTENT
                     else
                      V_UFFILIAL
                   end) else C.ESTENT end)),
              NVL(A.TIPOFJ, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'F'
                     else
                      C.TIPOFJ
                   end)),
              NVL(A.CONSUMIDORFINAL, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'S'
                     else
                      C.CONSUMIDORFINAL
                   end)),
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              A.DTCANCEL,
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              A.PERBASEREDOUTRASDESP,
              A.VLFRETE,
              ------------------------------------------------------------------
              (case
                when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                     (C.CONSUMIDORFINAL = 'S') or
                     ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                     ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                     (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
                 'S'
                else
                 'N'
              end),
              ------------------------------------------------------------------
              A.VLOUTRASDESP,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              C.TIPOFJ,
              A.VLTOTAL,
              A.CODCONT,
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
              CF.CODOPER,
              A.OBS,
              A.TIPOVENDA,
              (case
                when B.CODFISCAL in (5929, 6929) then
                 0
                else
                 NVL(B.PERCIPI, 0)
              end),
              A.CONTAORDEM,
              -- Implementados no erro Group By
              A.UF,
              A.CODCLI,
              C.ESTENT,
              VC.NUMPED,
              V_UFFILIAL,
              VC.ESTENT,
              C.TIPOFJ,
              C.UTILIZAIESIMPLIFICADA,
              C.CONSUMIDORFINAL,
              C.CONTRIBUINTE,
              C.IEENT,
              A.SITUACAONFE,
              A.DTSAIDA
     order by DTSAIDA, NUMTRANSVENDA, NUMNOTA;
    -------------------------------------------------------------------------------------------
    cursor C_NOTAS_SAT(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    -- 10 - LAN?MENTOS NOTAS - SAT
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           A.NUMTRANSVENDA,
           A.CHAVENFE,
           A.NUMTRANSVENDAORIGEM,
           A.NUMCAR,
           A.CONDVENDA,
           A.ESPECIE,
           A.SERIE,
           A.SUBSERIE,
           A.NUMNOTA,
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           A.DTCANCEL,
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               NVL(B.PERCICM, 0)
            ELSE
               CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                    (B.CODFISCAL in (5929, 6929)) then
                  0
               ELSE
                  NVL(B.PERCICM, 0)
               END
            END) PERCICM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               CASE WHEN (NVL(B.GERAICMSLIVROFISCAL,'S') = 'N') or
                         (B.CODFISCAL in (5929, 6929)) THEN
                  NVL(B.PERCICM,0)
               ELSE
                  0
               END
            END) PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CLIENTE
                  else
                   C.CLIENTE
                end)) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CGCENT
                  else
                   C.CGCENT
                end)) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.IEENT
                  else
                   C.IEENT
                end)) IE,
           ------------------------------------------------------------------
           NVL(A.UF, (case
                  when A.CODCLI in (1, 2, 3) then
                   (case
                  when NVL(VC.NUMPED, 0) > 0 then
                   VC.ESTENT
                  else
                   V_UFFILIAL
                end) else C.ESTENT end)) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'F'
                  else
                   C.TIPOFJ
                end)) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'S'
                  else
                   C.CONSUMIDORFINAL
                end)) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           A.CODCONT,
           B.CODFISCAL,
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
           CF.CODOPER,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(CASE WHEN B.TRUNCARITEM = 'S' THEN
                      TRUNC(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                   DECODE(NVL(B.ST,0), 0,
                                          DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                   DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0)))))),2)
                   ELSE
                      ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                   DECODE(NVL(B.ST, 0), 0,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',
                                                 (B.QTCONT * NVL(B.BASEICMS,0)),
                                                 (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                   DECODE(C.ESTENT, V_UFFILIAL,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)),
                                                 (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS, 0), 0, 0, NVL(MC.VLBASEOUTROS,0)))))),2)
                   END)
            ELSE
               SUM(CASE WHEN B.TRUNCARITEM = 'S' THEN
                      TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST,0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                                 DECODE(C.ESTENT, V_UFFILIAL,
                                                        DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                            DECODE(NVL(A.CHAVENFE,'X'), 'X', (B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0))))))),2)
                   ELSE
                      ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST, 0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',
                                                        (B.QTCONT * NVL(B.BASEICMS,0)),
                                                        (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                   DECODE(C.ESTENT, V_UFFILIAL,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)),
                                                 (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS, 0), 0, 0, NVL(MC.VLBASEOUTROS,0))))))),2)
                   END)
            END) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                DECODE(NVL(B.ST, 0), 0,
                                       (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                       DECODE(C.ESTENT, V_UFFILIAL,
                                              (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))), 0)),
                                (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0,
                                              (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                              DECODE(C.ESTENT, V_UFFILIAL,
                                                     (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))), 0)),
                                       (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2))
            END) VLBASENAOTRIB,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                ROUND(DECODE(V_GERABASENORMALQUANDOST,'N',
                                             DECODE(NVL(B.ST, 0), 0,
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),
                                                             DECODE(C.ESTENT, V_UFFILIAL,
                                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                      ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0) ),2)),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                       ROUND(DECODE(V_GERABASENORMALQUANDOST,'N',
                                                    DECODE(NVL(B.ST, 0), 0,
                                                           GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                                    ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),
                                                                    DECODE(C.ESTENT, V_UFFILIAL,
                                                                           GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                                                    ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0) ),2))),2))
            END) VLBASE_REDUCAO,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                       TRUNC(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                    DECODE(NVL(B.ST, 0), 0,
                                           DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                    DECODE(C.ESTENT, V_UFFILIAL,
                                           DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                             DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                    ELSE
                       ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                    DECODE(NVL(B.ST, 0), 0,
                                           DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                    DECODE(C.ESTENT, V_UFFILIAL,
                                           DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                             DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                   END)
            ELSE
               SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                      TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST, 0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                   ELSE
                      ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST, 0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                  END)
            END) VLBASE,
           ------------------------------------------------------------------
           -- CALCULANDO A BASE DE ICMS
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               ROUND(SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                            TRUNC(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                         DECODE(NVL(B.ST, 0), 0,
                                                DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                  DECODE(C.ESTENT, V_UFFILIAL,
                                         DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                           DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                         ELSE
                            ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                         DECODE(NVL(B.ST, 0), 0,
                                                DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                         DECODE(C.ESTENT, V_UFFILIAL,
                                                DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                  DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                         END) * (NVL(NVL(B.PERCICMCP,B.PERCICM), 0) / 100), 2)
            ELSE
               ROUND(SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                            TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                         DECODE(V_GERABASENORMALQUANDOST, 'N',
                                                DECODE(NVL(B.ST, 0), 0,
                                                       DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                         DECODE(C.ESTENT, V_UFFILIAL,
                                                DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                  DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                         ELSE
                            ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                         DECODE(V_GERABASENORMALQUANDOST, 'N',
                                                DECODE(NVL(B.ST, 0), 0,
                                                       DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                                DECODE(C.ESTENT, V_UFFILIAL,
                                                       DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                         DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                         END) * (NVL(NVL(B.PERCICMCP,B.PERCICM), 0) / 100), 2)
            END) VLICMS,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(B.QTCONT *
                         CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                   ((V_GERABASENORMALQUANDOST = 'N') and (NVL(B.ST, 0) > 0) AND
                                    (C.ESTENT <> V_UFFILIAL)) OR
                                   (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                            (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)) * NVL(B.PERCICM, 0) / 100
                         ELSE
                            0
                         END, 2))
            END) VLICMSNAOTRIB,
           ------------------------------------------------------------------
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
                  GREATEST(
                       -- CALCULO DO VLDESDOBRADO
                       sum( NVL(MC.VLSUBTOTITEM, DECODE( NVL(B.TRUNCARITEM, 'S'),'S',
                               TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2),
                               ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2))))
                  -    -- SINAL DE MENOS
                       -- CALCULO DA BASE DE ICMS
                       SUM(case when b.truncaritem = 'S' then
                       TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                               DECODE(V_GERABASENORMALQUANDOST, 'N',
                                    DECODE(NVL(B.ST, 0), 0, decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                           DECODE(C.ESTENT, V_UFFILIAL,
                                                 decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) , (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                  decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                       ELSE
                       ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                               DECODE(V_GERABASENORMALQUANDOST, 'N',
                                    DECODE(NVL(B.ST, 0), 0, decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                           DECODE(C.ESTENT, V_UFFILIAL,
                                                 decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) , (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                  decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                       END)
               ,0) -- Fechando GREATEST
               ELSE
                  0
               END VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
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
                 GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                       sum(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) +
                           NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)), 0),2)),0)
               ELSE
                  0
               END VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           A.OBS,
           ------------------------------------------------------------------
           ------------------------------------------------------------------
           sum( NVL(MC.VLSUBTOTITEM, DECODE( NVL(B.TRUNCARITEM, 'S'),
                                'S',
                               TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2),
                               ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2)))
           ) VLDESDOBRADO_ARRED_POR_ITEM,

           ------------------------------------------------------------------
           sum( NVL(MC.VLSUBTOTITEM, DECODE( NVL(B.TRUNCARITEM, 'S'),
                                'S',
                               TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2),
                               ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2)))
           ) VLDESDOBRADO,
           ------------------------------------------------------------------
           A.VLFRETE,
           DECODE(A.TIPOVENDA,'DF',0,SUM(ROUND(B.QTCONT * NVL(B.VLFRETE, 0), 2))) VLFRETE_MOV,
           ------------------------------------------------------------------
           CASE WHEN (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                      (C.CONSUMIDORFINAL = 'S') or ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                      ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                       (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
              'S'
           ELSE
              'N'
           END FRETEPF,
           ------------------------------------------------------------------
           DECODE(A.CHAVENFE, NULL,
                  GREATEST(ROUND(A.VLOUTRASDESP -
                                 NVL((SELECT ROUND(SUM(QTCONT * VLACRESCIMOPF), 2)
                                      FROM PCMOV
                                      WHERE NUMTRANSVENDA = A.NUMTRANSVENDA
                      AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                                        AND QTCONT > 0
                                        AND DTCANCEL IS NULL), 0), 2), 0), NVL(A.VLOUTRASDESP,0)) VLOUTRASDESP,
           ------------------------------------------------------------------
           (GREATEST(A.VLOUTRASDESP -
                     NVL((select ROUND(sum(QTCONT * VLACRESCIMOPF), 2)
                           from PCMOV
                          where NUMTRANSVENDA = A.NUMTRANSVENDA
               AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                            and QTCONT > 0
                            and DTCANCEL is null), 0), 0) *
           DECODE(NVL(A.PERBASEREDOUTRASDESP, 0), 0, 100, A.PERBASEREDOUTRASDESP) / 100) VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           NVL((select GREATEST(ROUND(sum(QTCONT * (NVL(VLOUTROS, 0) -
                                         NVL(VLACRESCIMOPF, 0))), 2), 0)
                 from PCMOV
                where NUMTRANSVENDA = A.NUMTRANSVENDA
          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL
                  and QTCONT > 0
                  and DTCANCEL is null), 0) VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           NVL(A.PERBASEREDOUTRASDESP, 0) PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           A.TIPOVENDA,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.BASEICST, 0) * B.QTCONT,2)) BASEST,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              sum(DECODE(NVL(B.PERCIPI, 0), 0, 0, ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)))
           end VLBASEIPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2)) VLIPI,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              NVL(B.PERCIPI, 0)
           end PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  case
                 when B.CODFISCAL in (5929, 6929) then
                  0
                 else
                  DECODE(NVL(B.PERCIPI, 0), 0, case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0) end else 0 end) VLBASEISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  case
                 when B.CODFISCAL in (5929, 6929) then
                  0
                 else
                  DECODE(NVL(B.PERCIPI, 0), 0, case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0) end end) VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCOFINS), 2)) VLCOFINS,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)), 0) BCIMPESTADUAL,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)), 0) VLIMPESTADUAL,
           ------------------------------------------------------------------
           sum(NVL(B.VLREPASSE, 0) * B.QTCONT) VLREPASSE,
           ------------------------------------------------------------------
           sum(NVL(B.BASEBCR, 0) * B.QTCONT) VLBASEBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.STBCR, 0) * B.QTCONT,2)) VLSTBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLICMSBCR, 0) * B.QTCONT,2)) VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '41', B.QTCONT * B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           SUM(DECODE(B.SITTRIBUT,
                      '20', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0),
                      '70', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0), 0)) VLBASERED_DAPI,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '50', B.QTCONT * B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.ST, 0), 2)) VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS, 0), 2)) VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS, 0), 2)) VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           A.CONTAORDEM,
           A.SITUACAONFE,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) as VLICMSPARTDEST,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) as VLICMSPARTREM ,
           SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) AS VLFCP,
           sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) as VLICMSDIFALIQPART,
           sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) as VLBASEPARTDEST,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
           0 VLACRESCIMOFUNCEP,
           0 VLFECP,
           0 PERACRESCIMOFUNCEP,
           0 VLBASEFCPICMS,
           0 VLBASEFCPST,
           0 ALIQICMSFECP,
           A.DTSAIDA DATA,
           SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS,
           SUM(NVL(DXML.VDESC, 
               ROUND(DECODE(NVL(MC.PRECOUTILIZADONFE, 
                                NVL(NVL(DECODE(NVL(PF.PRECOUTILIZADONFE,'N'), 'N', '', PF.PRECOUTILIZADONFE), 
                                               C.PRECOUTILIZADONFE), 
                                     NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', NVL(A.CODFILIALNF, A.CODFILIAL)), 'L'))),
                           'B', B.QTCONT * NVL(B.VLDESCONTO,0), 0), 2)
           
               )) VL_DESCONTO,
           SUM(NVL(DXML.VPROD, 
               ROUND(B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.ST,0) - NVL(B.VLIPI,0) - NVL(MC.VLIPIDEVFORNEC,0)-
                     NVL(MC.VLFECP,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.ST,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLIPI,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(MC.VLIPIDEVFORNEC,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLFRETE,0)), 2)+
                     DECODE(NVL(A.DOCEMISSAO,'X'), 
                                'CE', 0, 
                                'SF', 0, 
                                'CF', 0, 
                                'MF', 0, 
                                ROUND((NVL(B.QTCONT, 0) * NVL(B.VLFRETE, 0)), 2))              
                 )) VL_PRODUTO
      from PCNFSAID      A,
           PCMOV         B,
           PCMOVCOMPLE   MC,
           PCCLIENT      C,
           PCVENDACONSUM VC,
           PCFILIAL      F,
           PCCFO         CF,
           PCPRODUT      P,
           PCPRODFILIAL  PF,
           PCDADOSXML DXML
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and B.NUMTRANSITEM = DXML.NUMTRANSITEM(+)
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and A.NUMPED = VC.NUMPED(+)
       and P.CODPROD = B.CODPROD
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and B.STATUS in ('A', 'AB')
       and B.QTCONT > 0
       and CF.CODFISCAL(+) = B.CODFISCAL
       and A.ESPECIE in ('NF')
       and NVL(A.SERIE, 'X') not in ('CF', 'CP')
       AND 0 = 0
       and A.DTSAIDA between P_DATA1 and P_DATA2
     AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
       and ((A.NUMNOTA >= P_NOTA1) and (A.NUMNOTA <= P_NOTA2))
       and (NVL(F.IMPEDETIPO14_LIVROFISCAL, 'N') = 'N' or NVL(A.CONDVENDA, 0) <> 14)
       and NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
       and F.CODIGO = P_CODFILIAL
       and NVL(A.DOCEMISSAO, 'X') = 'SF'
       and A.CHAVESAT IS NOT NULL
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              B.SITTRIBUT,
              A.CHAVENFE,
              NVL(A.CLIENTE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CLIENTE
                     else
                      C.CLIENTE
                   end)),
              NVL(A.CGC, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CGCENT
                     else
                      C.CGCENT
                   end)),
              NVL(A.IE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.IEENT
                     else
                      C.IEENT
                   end)),
              NVL(A.UF, (case
                     when A.CODCLI in (1, 2, 3) then
                      (case
                     when NVL(VC.NUMPED, 0) > 0 then
                      VC.ESTENT
                     else
                      V_UFFILIAL
                   end) else C.ESTENT end)),
              NVL(A.TIPOFJ, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'F'
                     else
                      C.TIPOFJ
                   end)),
              NVL(A.CONSUMIDORFINAL, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'S'
                     else
                      C.CONSUMIDORFINAL
                   end)),
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              A.DTCANCEL,
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              A.PERBASEREDOUTRASDESP,
              A.VLFRETE,
              ------------------------------------------------------------------
              (case
                when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                     (C.CONSUMIDORFINAL = 'S') or
                     ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                     ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                     (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
                 'S'
                else
                 'N'
              end),
              ------------------------------------------------------------------
              A.VLOUTRASDESP,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              C.TIPOFJ,
              A.VLTOTAL,
              A.CODCONT,
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
              CF.CODOPER,
              A.OBS,
              A.TIPOVENDA,
              (case
                when B.CODFISCAL in (5929, 6929) then
                 0
                else
                 NVL(B.PERCIPI, 0)
              end),
              A.CONTAORDEM,
              -- Implementados no erro Group By
              A.UF,
              A.CODCLI,
              C.ESTENT,
              VC.NUMPED,
              V_UFFILIAL,
              VC.ESTENT,
              C.TIPOFJ,
              C.UTILIZAIESIMPLIFICADA,
              C.CONSUMIDORFINAL,
              C.CONTRIBUINTE,
              C.IEENT,
              A.SITUACAONFE,
              B.PERCICMCP,
              B.PERCICM,
              A.DTSAIDA
     order by DTSAIDA, NUMTRANSVENDA, NUMNOTA;
  -------------------------------------------------------------------------------------------
    cursor C_NOTAS_MFE(P_NOTA1 in number, P_NOTA2 in number, P_DATA1 in date, P_DATA2 in date, P_INSERIRCF in varchar2, P_CODFILIAL in varchar2) is
    -- 11 - LAN?MENTOS NOTAS - MFE
    select NVL(A.CODFILIALNF, A.CODFILIAL) CODFILIAL,
           A.NUMTRANSVENDA,
           A.CHAVENFE,
           A.NUMTRANSVENDAORIGEM,
           A.NUMCAR,
           A.CONDVENDA,
           A.ESPECIE,
           A.SERIE,
           A.SUBSERIE,
           A.NUMNOTA,
           DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA) DTSAIDA,
           A.DTCANCEL,
           DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF) CODCLI,
           ------------------------------------------------------------------
           case
             when (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                  (B.CODFISCAL in (5929, 6929)) then
              0
             else
              NVL(B.PERCICM, 0)
           end PERCICM,
           ------------------------------------------------------------------
           case
             when (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') or
                  (B.CODFISCAL in (5929, 6929)) then
              NVL(B.PERCICM, 0)
             else
              0
           end PERCICMNAOTRIB,
           ------------------------------------------------------------------
           NVL(A.CLIENTE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CLIENTE
                  else
                   C.CLIENTE
                end)) CLIENTE,
           ------------------------------------------------------------------
           NVL(A.CGC, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.CGCENT
                  else
                   C.CGCENT
                end)) CNPJ,
           ------------------------------------------------------------------
           NVL(A.IE, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   VC.IEENT
                  else
                   C.IEENT
                end)) IE,
           ------------------------------------------------------------------
           NVL(A.UF, (case
                  when A.CODCLI in (1, 2, 3) then
                   (case
                  when NVL(VC.NUMPED, 0) > 0 then
                   VC.ESTENT
                  else
                   V_UFFILIAL
                end) else C.ESTENT end)) UF,
           ------------------------------------------------------------------
           NVL(A.TIPOFJ, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'F'
                  else
                   C.TIPOFJ
                end)) TIPOFJ,
           ------------------------------------------------------------------
           NVL(A.CONSUMIDORFINAL, (case
                  when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                   'S'
                  else
                   C.CONSUMIDORFINAL
                end)) CONSUMIDORFINAL,
           ------------------------------------------------------------------
           A.VLTOTAL,
           A.CODCONT,
           B.CODFISCAL,
           FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA) SITTRIBUT,
           CF.CODOPER,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                      TRUNC(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                   DECODE(NVL(B.ST,0), 0,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                   DECODE(C.ESTENT, V_UFFILIAL,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                            DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0)))))),2)
                   ELSE
                      ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                   DECODE(NVL(B.ST,0), 0,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0)))))),2)
                   END)
            ELSE
               SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                      TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST,0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) ,(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0))))))),2)
                   ELSE
                      ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST,0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X', (B.QTCONT * NVL(B.BASEICMS,0)), (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                                 DECODE(C.ESTENT, V_UFFILIAL,
                                                       DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))), 0)),
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS,0)) , (B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + DECODE(NVL(B.VLOUTROS,0), 0, 0, NVL(MC.VLBASEOUTROS,0))))))),2)
                   END)
            END) VLBASE_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                DECODE(NVL(B.ST, 0), 0,
                                       (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                       DECODE(C.ESTENT, V_UFFILIAL,
                                              (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))), 0)),
                                (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', 0,
                                DECODE(V_GERABASENORMALQUANDOST, 'N',
                                       DECODE(NVL(B.ST, 0), 0,
                                              (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))),
                                              DECODE(C.ESTENT, V_UFFILIAL,
                                                     (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))), 0)),
                                       (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2))
            END) VLBASENAOTRIB,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                ROUND(DECODE(V_GERABASENORMALQUANDOST,'N', DECODE(NVL(B.ST, 0), 0,
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                      ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),DECODE(C.ESTENT, V_UFFILIAL,
                                             GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                      ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                                GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                         ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0) ),2)),2))
            ELSE
               SUM(ROUND(DECODE(NVL(B.BASEICMS, 0), 0, 0,
                                DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                       ROUND(DECODE(V_GERABASENORMALQUANDOST,'N', DECODE(NVL(B.ST, 0), 0,
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2) ,2) ,0),DECODE(C.ESTENT, V_UFFILIAL,
                                                    GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                             ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2) ,0), 0)),
                                       GREATEST(ROUND(B.QTCONT * NVL(B.PUNITCONT, 0) - B.QTCONT * NVL(B.ST, 0) - B.QTCONT * NVL(B.VLIPI, 0) -
                                                ROUND(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)),2),2),0) ),2))),2))
            END) VLBASE_REDUCAO,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                      TRUNC(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                   DECODE(NVL(B.ST, 0), 0,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                   DECODE(C.ESTENT, V_UFFILIAL,
                                          DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) , (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                      DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                   ELSE
                      ROUND(DECODE(V_GERABASENORMALQUANDOST, 'N',
                                   DECODE(NVL(B.ST, 0), 0, decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) , (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                            DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0))))),2)
                   END)
            ELSE
               SUM(CASE WHEN B.TRUNCARITEM = 'S' then
                      TRUNC(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST, 0), 0,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                          DECODE(C.ESTENT, V_UFFILIAL,
                                                 DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) , (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                            DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                   ELSE
                      ROUND(DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'N', 0,
                                   DECODE(V_GERABASENORMALQUANDOST, 'N',
                                          DECODE(NVL(B.ST, 0), 0, decode(nvl(a.chavenfe,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),
                                                 DECODE(C.ESTENT, V_UFFILIAL,
                                                        DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) , (B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))),0)),
                                   DECODE(NVL(A.CHAVENFE,'X'),'X',(B.QTCONT * NVL(B.BASEICMS, 0)) ,(B.QTCONT * (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)))))),2)
                   END)
            END) VLBASE,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               SUM(FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NF', B.ROWID, C.ESTENT, A.CHAVENFE))
            ELSE
               SUM(DECODE(NVL(B.GERAICMSLIVROFISCAL,'S'), 'S', FISCAL.GET_DADOS_ICMS(P_CODFILIAL, 'V', 'NF', B.ROWID, C.ESTENT, A.CHAVENFE),0))
            END) VLICMS,
           ------------------------------------------------------------------
           -- Cria? de par?tro na 132 (GERARICMSLIVFISCFOP) - FIS-8312
           (CASE WHEN (vPARAM_GERARICMSLIVFISCFOP = 'S') AND
                      (B.CODFISCAL IN (5929, 6929)) THEN
               0
            ELSE
               SUM(ROUND(B.QTCONT *
                         CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                                   ((V_GERABASENORMALQUANDOST = 'N') and (NVL(B.ST, 0) > 0) AND
                                    (C.ESTENT <> V_UFFILIAL)) OR
                                   (NVL(B.BASEICMS, 0) <= 0) OR (NVL(B.PERCICM, 0) <= 0) THEN
                            (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)) * NVL(B.PERCICM, 0) / 100
                         ELSE
                            0
                         END, 2))
            END) VLICMSNAOTRIB,
           ------------------------------------------------------------------
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
                  GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                       sum(round(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEOUTROS, 0) + NVL(MC.VLBASEFRETE, 0)), 0),2)) ,0)
               ELSE
                  0
               END VLISENTAS_ARRED_POR_ITEM,
           ------------------------------------------------------------------
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
                 GREATEST(
                       sum(round(
                       round(B.qtcont * (nvl(B.punitcont,0) - nvl(B.st,0) - nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.st,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vlipi,0)),2) +
                       round((nvl(B.qtcont,0) * nvl(B.vloutros,0)),2) +
                       decode(a.chavenfe, null, nvl(B.qtcont,0) * NVL(B.VLACRESCIMOPF, 0), 0) +
                       round((nvl(B.qtcont,0) * nvl(B.vlfrete,0)),2)
                       ,2)) -
                       sum(ROUND(B.QTCONT * DECODE(NVL(B.GERAICMSLIVROFISCAL, 'S'), 'S', (NVL(B.BASEICMS, 0) +
                           NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)), 0),2)),0)
               ELSE
                  0
               END VLISENTAS,
           ------------------------------------------------------------------
           0 VLOUTRAS,
           ------------------------------------------------------------------
           A.OBS,
           ------------------------------------------------------------------
           ------------------------------------------------------------------
           sum( NVL(MC.VLSUBTOTITEM, DECODE( NVL(B.TRUNCARITEM, 'S'),
                                'S', TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2),
                               ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2)))
               ) VLDESDOBRADO_ARRED_POR_ITEM,
           ------------------------------------------------------------------
           ------------------------------------------------------------------
           sum( NVL(MC.VLSUBTOTITEM, DECODE( NVL(B.TRUNCARITEM, 'S'),
                                'S', TRUNC(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2),
                               ROUND(B.QTCONT * (B.PUNITCONT + NVL(B.VLOUTROS, 0)), 2)))
               ) VLDESDOBRADO,
           ------------------------------------------------------------------
           A.VLFRETE,
           DECODE(A.TIPOVENDA,'DF',0,SUM(ROUND(B.QTCONT * NVL(B.VLFRETE, 0), 2))) VLFRETE_MOV,
           ------------------------------------------------------------------
           CASE WHEN (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                      (C.CONSUMIDORFINAL = 'S') or ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                      ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                       (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
              'S'
           ELSE
              'N'
           END FRETEPF,
           ------------------------------------------------------------------
           0 VLOUTRASDESP,
           ------------------------------------------------------------------
           0 VLBASEOUTRASDESP,
           ------------------------------------------------------------------
           0 VLOUTRASDESP_ITEM,
           ------------------------------------------------------------------
           NVL(A.PERBASEREDOUTRASDESP, 0) PERBASEREDOUTRASDESP,
           ------------------------------------------------------------------
           A.TIPOVENDA,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.BASEICST, 0) * B.QTCONT,2)) BASEST,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.ST, 0) * B.QTCONT, 2)) VLST,
           ------------------------------------------------------------------
           0 BASESTFORANF,
           ------------------------------------------------------------------
           0 VLSTFORANF,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              sum(DECODE(NVL(B.PERCIPI, 0), 0, 0, ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)))
           end VLBASEIPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLIPI, 0), 2)) VLIPI,
           ------------------------------------------------------------------
           case when B.CODFISCAL in (5929, 6929) then
              0
           else
              NVL(B.PERCIPI, 0)
           end PERCIPI,
           ------------------------------------------------------------------
           0 VLISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  case
                 when B.CODFISCAL in (5929, 6929) then
                  0
                 else
                  DECODE(NVL(B.PERCIPI, 0), 0, case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0) end else 0 end) VLBASEISENTASIPI,
           ------------------------------------------------------------------
           sum(case
                 when (select max(DESTVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) = 'I' then
                  0
                 else
                  case
                 when B.CODFISCAL in (5929, 6929) then
                  0
                 else
                  DECODE(NVL(B.PERCIPI, 0), 0, case
                 when (select max(FORMVALORIPI)
                         from PCDESTSITTRIBUTIPI
                        where CODSITTRIBIPI = MC.CODSITTRIBIPI) in ('C', 'CI') then
                  B.QTCONT *
                  (B.PUNITCONT +
                  DECODE(A.CHAVENFE, null, NVL(B.VLACRESCIMOPF, 0), 0) -
                  DECODE((select max(FORMVALORIPI)
                            from PCDESTSITTRIBUTIPI
                           where CODSITTRIBIPI = MC.CODSITTRIBIPI), 'C', NVL(B.VLIPI, 0), 0))
                 else
                  ROUND(B.QTCONT * NVL(B.VLBASEIPI, 0), 2)
               end, 0) end end) VLBASEOUTRASIPI,
           ------------------------------------------------------------------
           0 VLOUTRASIPI,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLPIS), 2)) VLPIS,
           ------------------------------------------------------------------
           sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, B.QTCONT *
                             NVL(B.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                             B.QTCONT * B.VLCOFINS), 2)) VLCOFINS,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.BASEACRESCIMOPF, 0)), 0) BCIMPESTADUAL,
           ------------------------------------------------------------------
           DECODE(V_UFFILIAL,
                  'PI', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)),
                  'MA', sum(B.QTCONT * NVL(B.VLACRESCIMOPF, 0)), 0) VLIMPESTADUAL,
           ------------------------------------------------------------------
           sum(NVL(B.VLREPASSE, 0) * B.QTCONT) VLREPASSE,
           ------------------------------------------------------------------
           sum(NVL(B.BASEBCR, 0) * B.QTCONT) VLBASEBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.STBCR, 0) * B.QTCONT,2)) VLSTBCR,
           ------------------------------------------------------------------
           sum(ROUND(NVL(B.VLICMSBCR, 0) * B.QTCONT,2)) VLICMSBCR,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '41', B.QTCONT * B.PUNITCONT, 0)) VLNAOTRIB_DAPI,
           ------------------------------------------------------------------
           SUM(DECODE(B.SITTRIBUT,
                      '20', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0),
                      '70', B.QTCONT * GREATEST(B.PUNITCONT - NVL(B.VLIPI, 0) - NVL(B.ST, 0) - (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 0), 0)) VLBASERED_DAPI,
           ------------------------------------------------------------------
           sum(DECODE(B.SITTRIBUT, '50', B.QTCONT * B.PUNITCONT, 0)) VLSUSPENSAS_DAPI,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.ST, 0), 2)) VLST_DAPI,
           ------------------------------------------------------------------
           0 VLISENTAS_DAPI,
           ------------------------------------------------------------------
           0 VLOUTRAS_DAPI,
           ------------------------------------------------------------------
           sysdate DTGERA,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOPIS, 0), 2)) VLDESCREDUCAOPIS,
           ------------------------------------------------------------------
           sum(ROUND(B.QTCONT * NVL(B.VLDESCREDUCAOCOFINS, 0), 2)) VLDESCREDUCAOCOFINS,
           ------------------------------------------------------------------
           A.CONTAORDEM,
           A.SITUACAONFE,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTDEST, 0),2)) as VLICMSPARTDEST,
           SUM(ROUND(B.QTCONT * nvl(MC.VLICMSPARTREM, 0),2)) as VLICMSPARTREM ,
           SUM(ROUND(B.QTCONT * nvl(MC.VLFCPPART, 0),2)) AS VLFCP,
           sum(ROUND(b.QTCONT * nvl(mc.VLICMSDIFALIQPART, 0),2)) as VLICMSDIFALIQPART,
           sum(ROUND(b.QTCONT * nvl(mc.VLBASEPARTDEST, 0),2)) as VLBASEPARTDEST,
           SUM(ROUND(B.QTCONT * NVL(MC.VLIPIDEVFORNEC,0),2)) VLIPIDEVFORNEC,
           0 VLACRESCIMOFUNCEP,
           0 VLFECP,
           0 PERACRESCIMOFUNCEP,
           0 VLBASEFCPICMS,
           0 VLBASEFCPST,
           0 ALIQICMSFECP,
           A.DTSAIDA DATA,
           SUM(ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)),2)) VLOUTROS,
           SUM(NVL(DXML.VDESC, 
               ROUND(DECODE(NVL(MC.PRECOUTILIZADONFE, 
                                NVL(NVL(DECODE(NVL(PF.PRECOUTILIZADONFE,'N'), 'N', '', PF.PRECOUTILIZADONFE), 
                                               C.PRECOUTILIZADONFE), 
                                     NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOUTILIZADONFE', NVL(A.CODFILIALNF, A.CODFILIAL)), 'L'))),
                           'B', B.QTCONT * NVL(B.VLDESCONTO,0), 0), 2)
           
               )) VL_DESCONTO,
           SUM(NVL(DXML.VPROD, 
               ROUND(B.QTCONT * (NVL(B.PUNITCONT,0) - NVL(B.ST,0) - NVL(B.VLIPI,0) - NVL(MC.VLIPIDEVFORNEC,0)-
                     NVL(MC.VLFECP,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.ST,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLIPI,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLOUTROS,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(MC.VLIPIDEVFORNEC,0)), 2) + 
                     ROUND((NVL(B.QTCONT,0) * NVL(B.VLFRETE,0)), 2)+
                     DECODE(NVL(A.DOCEMISSAO,'X'), 
                                'CE', 0, 
                                'SF', 0, 
                                'CF', 0, 
                                'MF', 0, 
                                ROUND((NVL(B.QTCONT, 0) * NVL(B.VLFRETE, 0)), 2))              
                 )) VL_PRODUTO
      from PCNFSAID      A,
           PCMOV         B,
           PCMOVCOMPLE   MC,
           PCCLIENT      C,
           PCVENDACONSUM VC,
           PCFILIAL      F,
           PCCFO         CF,
           PCPRODUT      P,
           PCPRODFILIAL  PF,
           PCDADOSXML    DXML
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       and MC.NUMTRANSITEM = B.NUMTRANSITEM
       and B.NUMTRANSITEM = DXML.NUMTRANSITEM(+)
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and A.NUMPED = VC.NUMPED(+)
       and P.CODPROD = B.CODPROD
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and B.STATUS in ('A', 'AB')
       and B.QTCONT > 0
       and CF.CODFISCAL(+) = B.CODFISCAL
       and A.ESPECIE in ('NF')
       and NVL(A.SERIE, 'X') not in ('CF', 'CP')
       AND 0 = 0
       and A.DTSAIDA between P_DATA1 and P_DATA2
     AND B.DTMOV BETWEEN P_DATA1 AND P_DATA2
       and ((A.NUMNOTA >= P_NOTA1) and (A.NUMNOTA <= P_NOTA2))
       and (NVL(F.IMPEDETIPO14_LIVROFISCAL, 'N') = 'N' or NVL(A.CONDVENDA, 0) <> 14)
       and NVL(A.CODFILIALNF, A.CODFILIAL) = P_CODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = P_CODFILIAL
       and NVL(A.CODFILIALNF, A.CODFILIAL) = F.CODIGO
       and NVL(A.DOCEMISSAO, 'X') = 'MF'
       and A.CHAVESAT IS NOT NULL
     group by NVL(A.CODFILIALNF, A.CODFILIAL),
              A.NUMTRANSVENDA,
              A.NUMTRANSVENDAORIGEM,
              A.NUMCAR,
              A.CONDVENDA,
              A.ESPECIE,
              A.SERIE,
              A.SUBSERIE,
              B.SITTRIBUT,
              A.CHAVENFE,
              NVL(A.CLIENTE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CLIENTE
                     else
                      C.CLIENTE
                   end)),
              NVL(A.CGC, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.CGCENT
                     else
                      C.CGCENT
                   end)),
              NVL(A.IE, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      VC.IEENT
                     else
                      C.IEENT
                   end)),
              NVL(A.UF, (case
                     when A.CODCLI in (1, 2, 3) then
                      (case
                     when NVL(VC.NUMPED, 0) > 0 then
                      VC.ESTENT
                     else
                      V_UFFILIAL
                   end) else C.ESTENT end)),
              NVL(A.TIPOFJ, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'F'
                     else
                      C.TIPOFJ
                   end)),
              NVL(A.CONSUMIDORFINAL, (case
                     when NVL(VC.NUMPED, 0) > 0 and A.CODCLI in (1, 2, 3) then
                      'S'
                     else
                      C.CONSUMIDORFINAL
                   end)),
              A.NUMNOTA,
              --DECODE(vnGeraDTENTREGA,'S',NVL(NVL(A.DTENTREGA, A.DTSAIDANF),A.DTSAIDA),A.DTSAIDA),
              A.DTENTREGA, A.DTSAIDANF, A.DTSAIDA,
              A.DTCANCEL,
              NVL(B.GERAICMSLIVROFISCAL, 'S'),
              NVL(B.PERCICM, 0),
              A.PERBASEREDOUTRASDESP,
              A.VLFRETE,
              ------------------------------------------------------------------
              (case
                when (((C.TIPOFJ = 'F') and (C.UTILIZAIESIMPLIFICADA = 'N')) or
                     (C.CONSUMIDORFINAL = 'S') or
                     ((V_CONSIDERAISENTOSCOMOPF = 'S') and
                     ((C.IEENT is null) or (C.IEENT = 'ISENTO') or
                     (C.IEENT = 'ISENTA')))) and (C.CONTRIBUINTE = 'N') then
                 'S'
                else
                 'N'
              end),
              ------------------------------------------------------------------
              A.VLOUTRASDESP,
              DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF),
              C.TIPOFJ,
              A.VLTOTAL,
              A.CODCONT,
              B.CODFISCAL,
              FISCAL.FORMATAR_CST_ICMS(B.SITTRIBUT, NVL(B.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), A.DTSAIDA),
              CF.CODOPER,
              A.OBS,
              A.TIPOVENDA,
              (case
                when B.CODFISCAL in (5929, 6929) then
                 0
                else
                 NVL(B.PERCIPI, 0)
              end),
              A.CONTAORDEM,
              -- Implementados no erro Group By
              A.UF,
              A.CODCLI,
              C.ESTENT,
              VC.NUMPED,
              V_UFFILIAL,
              VC.ESTENT,
              C.TIPOFJ,
              C.UTILIZAIESIMPLIFICADA,
              C.CONSUMIDORFINAL,
              C.CONTRIBUINTE,
              C.IEENT,
              A.SITUACAONFE,
              A.DTSAIDA
     order by DTSAIDA, NUMTRANSVENDA, NUMNOTA;
  ---------------------------------------------------------------------------------
  TYPE LISTA_NOTAS IS TABLE OF  C_NOTAS_NF%ROWTYPE;

  LISTA_NOTAS_CUPOM_FISCAL            LISTA_NOTAS;
  LISTA_NOTAS_DEV_FORNEC              LISTA_NOTAS;
  LISTA_NOTAS_SEM_ITENS_E_FRETE       LISTA_NOTAS;
  LISTA_NOTAS_REDZ_TRIB               LISTA_NOTAS;
  LISTA_NOTAS_REDZ_CANC               LISTA_NOTAS;
  LISTA_NOTAS_REDZ_N_TRIB             LISTA_NOTAS;
  LISTA_NOTAS_NF                      LISTA_NOTAS;
  LISTA_NOTAS_NFCE                    LISTA_NOTAS;
  LISTA_NOTAS_SAT                     LISTA_NOTAS;
  LISTA_NOTAS_MFE                     LISTA_NOTAS;
  LISTA_NOTAS_COMPLEMENTAR_ITEM       LISTA_NOTAS;
  V_LISTA_NOTAS_TEMP                  C_NOTAS_NF%ROWTYPE;

  -- Functions
  -- NOTAS_CUPOM_FISCAL
  function F_NOTAS_CUPOM_FISCAL(PDATA1 IN DATE,
                                PDATA2 IN DATE,
                                PCODFILIAL IN VARCHAR2,
                                PNUMNOTA1 IN NUMBER,
                                PNUMNOTA2 IN NUMBER,
                                PINSERIRCF IN VARCHAR2) return boolean is
  BEGIN
     BEGIN
     select 1
            INTO V_QTDNF_NO_PERIODO
       from PCNFSAID A
             WHERE A.ESPECIE IN ('NF', 'CF', 'CP')
               AND A.SERIE IN ('CF', 'CP')
               AND (PINSERIRCF = 'S' OR A.CHAVENFE IS NOT NULL)
               AND A.DTSAIDA BETWEEN PDATA1 AND PDATA1
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

  -- Functions
  -- NOTAS_DEV_FORNEC
  function F_NOTAS_DEV_FORNEC(PDATA1 IN DATE,
                              PDATA2 IN DATE,
                              PCODFILIAL IN VARCHAR2,
                              PNUMNOTA1 IN NUMBER,
                              PNUMNOTA2 IN NUMBER,
                              PINSERIRCF IN VARCHAR2) return boolean is
  BEGIN
     BEGIN
     select 1
            INTO V_QTDNF_NO_PERIODO
        from PCNFSAID     A,
           PCMOV        B,
           PCMOVCOMPLE  MC,
           PCCLIENT     C,
           PCCFO        CF,
           PCPRODUT     P,
           PCPRODFILIAL PF
     where A.NUMTRANSVENDA = B.NUMTRANSVENDA
       and A.NUMNOTA = B.NUMNOTA
       --and A.codfilial = B.codfilial       
       and B.NUMTRANSITEM = MC.NUMTRANSITEM
       and C.CODCLI = DECODE(NVL(A.CODCLINF, 0), 0, A.CODCLI, A.CODCLINF)
       and B.STATUS in ('A', 'AB')
       and CF.CODFISCAL(+) = B.CODFISCAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PF.CODFILIAL(+)
       and B.CODPROD = PF.CODPROD(+)
       and P.CODPROD = B.CODPROD
       and B.QTCONT > 0
       and A.ESPECIE in ('NF', 'CO', 'CF', 'CP')
       and NVL(A.CODFILIALNF, A.CODFILIAL) = PCODFILIAL
       and NVL(B.CODFILIALNF, B.CODFILIAL) = PCODFILIAL
       and A.DTSAIDA between PDATA1 and PDATA2
       and B.DTMOV between PDATA1 and PDATA2
       and A.NUMNOTA between PNUMNOTA1 and PNUMNOTA2
       and (A.TIPOVENDA = 'DF' or B.CODOPER = 'SD')
       and ((NVL(A.SERIE, 'X') <> 'CF') or ('S' = PINSERIRCF))
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

  -- Functions
  -- CONSULTAR REDUÇÕES Z FALTANTES 
  function F_VALIDAR_REDUCOES_PERIODO(PDATA1 IN DATE,
                                      PDATA2 IN DATE,
                                      PCODFILIAL IN VARCHAR2,
                                      PNUMNOTA1 IN NUMBER,
                                      PNUMNOTA2 IN NUMBER,
                                      PINSERIRCF IN VARCHAR2) return boolean is
  BEGIN
     BEGIN
        select 1
               INTO V_QTDNF_NO_PERIODO
          from PCNFSAID 
         where ESPECIE in ('NF', 'CP')
           and SERIE in ('CF', 'CP')
           and NVL(CODFILIALNF, CODFILIAL) = PCODFILIAL
           and DTSAIDA between PDATA1 and PDATA2
           and DTCANCEL is null
           and CHAVENFE IS NULL
           and CHAVESAT IS NULL
           and ROWNUM = 1;
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

  -- NOTAS_SAT
  function F_NOTAS_SAT(PDATA1 IN DATE,
                       PDATA2 IN DATE,
                       PCODFILIAL IN VARCHAR2,
                       PNUMNOTA1 IN NUMBER,
                       PNUMNOTA2 IN NUMBER) return boolean is
  BEGIN
     BEGIN
     select 1
            INTO V_QTDNF_NO_PERIODO
      from PCNFSAID      A
     where A.ESPECIE in ('NF')
       and A.DTSAIDA between PDATA1 and PDATA2
       and NVL(A.CODFILIALNF, A.CODFILIAL) = PCODFILIAL
       and NVL(A.DOCEMISSAO, 'X') = 'SF'
       and A.CHAVESAT IS NOT NULL
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

  -- NOTAS_MFE
  function F_NOTAS_MFE(PDATA1 IN DATE,
                       PDATA2 IN DATE,
                       PCODFILIAL IN VARCHAR2,
                       PNUMNOTA1 IN NUMBER,
                       PNUMNOTA2 IN NUMBER) return boolean is
  BEGIN
     BEGIN
     select 1
            INTO V_QTDNF_NO_PERIODO
      from PCNFSAID      A
     where A.ESPECIE in ('NF')
       and A.DTSAIDA between PDATA1 and PDATA2
       and NVL(A.CODFILIALNF, A.CODFILIAL) = PCODFILIAL
       and NVL(A.DOCEMISSAO, 'X') = 'MF'
       and A.CHAVESAT IS NOT NULL
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
  -------------------------------------------------------------------------------------------
  procedure VALIDAR_REDUCOES_PERIODO is
  begin
  -------------------------------------------------------------------------------------------
  -- VERIFICANDO A FALTA DE REDU??ES Z
    for DADOS in (select count(distinct DTSAIDA) QTDECUPOM
                    from PCNFSAID N
                   where ESPECIE in ('NF', 'CP')
                     and SERIE in ('CF', 'CP')
                    -- and (((N.CODFILIALNF IS NOT NULL) AND (N.CODFILIALNF = PCODFILIAL)) OR (N.CODFILIAL = PCODFILIAL))
                     and NVL(CODFILIALNF, CODFILIAL) = PCODFILIAL
                     and NUMNOTA between nvl(NUMNOTA1,0 ) and nvl(NUMNOTA2, 9999999999)
                     and DTSAIDA between DATA1 and DATA2
                     and DTCANCEL is null
                     and N.CHAVENFE IS NULL
                     and N.CHAVESAT IS NULL
                     and NVL(SUBSTR(N.CHAVENFE, 21,2),'XX') <> '65'
                     and not exists
                   (select PCCUPOMFISCALZ.NUMECF
                            from PCCUPOMFISCALZ
                           where PCCUPOMFISCALZ.NUMECF = N.CAIXA
                             and PCCUPOMFISCALZ.CODFILIAL = PCODFILIAL
                             and PCCUPOMFISCALZ.DTEMISSAO = N.DTSAIDA))
    loop
      if DADOS.QTDECUPOM > 0
      then
        V_SQLERRO := substr('VERIFICANDO A FALTA DE REDU??ES Z: ' || CHR(13) ||
                     'EXISTE(M) ' || DADOS.QTDECUPOM ||
                     ' DIA(S) NO PER?ODO SEM LAN?AMENTO DE REDU??O Z!' ||
                     CHR(13) ||
                     'FAVOR CONFERIR NO RELAT?RIO DE REDU??ES Z FALTANTES DA ROTINA 1064.',1,4000);
        raise V_FALTANDO_REDUCOES_Z;
      end if;
    end loop;
  end;
  /*****************************************************************************************/
  procedure CALCULAR_PIS_COFINS_CUPOM_REDZ is
    VNUMTRANSVENDA NUMBER;
  begin
    -- INICIALIZA A VARIAVEL DE CONTROLE
    VNUMTRANSVENDA := 0;
    -------------------------------------------------------------------------------------------
    -- CALCULANDO OS VALORES DO PIS/COFINS SOBRE OS CUPONS E REDU??ES Z
    for CUPONS in (select NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
                          N.NUMTRANSVENDA,
                          N.DTSAIDA,
                          N.CAIXA,
                          M.CODFISCAL,
                          NVL(M.PERCICM, 0) PERCICM,
                          sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, M.QTCONT *
                                            NVL(M.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                                            M.QTCONT *
                                            M.VLPIS), 2)) VLPIS,
                          sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, M.QTCONT *
                                            NVL(M.VLCOFINS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                                            M.QTCONT *
                                            M.VLCOFINS), 2)) VLCOFINS
                     from PCNFSAID    N,
                          PCMOV       M,
                          PCMOVCOMPLE MC,
                          PCPRODUT    P
                    where N.NUMTRANSVENDA = M.NUMTRANSVENDA
                      and M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                      and P.CODPROD = M.CODPROD
                      and N.ESPECIE in ('NF', 'CP')
                      and N.SERIE in ('CF', 'CP')
                      and M.QTCONT > 0
                      and M.DTCANCEL is null
                      and M.STATUS in ('A', 'AB')
                      and N.DTSAIDA between DATA1 and DATA2
                      and NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
            and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                    group by NVL(N.CODFILIALNF, N.CODFILIAL),
                             N.NUMTRANSVENDA,
                             N.DTSAIDA,
                             N.CAIXA,
                             M.CODFISCAL,
                             NVL(M.PERCICM, 0),
                             MC.CODCONTACONTSPED )
    loop
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'CALCULANDO PIS/COFINS (CAIXA ' || CUPONS.CAIXA ||
                   ' EM ' || TO_CHAR(CUPONS.DTSAIDA, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      -- CHAMADA DA GERA!O DOS CONTAS CONATABEIS
      IF (VNUMTRANSVENDA <> CUPONS.NUMTRANSVENDA) THEN
         FISCAL.GERA_CONTAS_CONTABEIS_SPED(PCODFILIAL,
                                           CUPONS.DTSAIDA,
                                           CUPONS.DTSAIDA,
                                           CUPONS.NUMTRANSVENDA,
                                           'S');
         VNUMTRANSVENDA := CUPONS.NUMTRANSVENDA;
      END IF;
      ---------------------------------------------------------------------------------
      -- REDU??O Z
      update PCNFBASESAID
         set VLPIS    = CUPONS.VLPIS,
             VLCOFINS = CUPONS.VLCOFINS
       where CODFILIALNF = CUPONS.CODFILIAL
         and DTSAIDA = CUPONS.DTSAIDA
         and CODCLI = CUPONS.CAIXA
         and CODFISCAL = CUPONS.CODFISCAL
         and PERCICM = CUPONS.PERCICM
         and ESPECIE = 'CF'
         and SERIE = 'ECF';

      -- MAPA RESUMO
      update PCNFBASESAID
         set VLPIS    = NVL(VLPIS, 0) + CUPONS.VLPIS,
             VLCOFINS = NVL(VLCOFINS, 0) + CUPONS.VLCOFINS
       where CODFILIALNF = CUPONS.CODFILIAL
         and DTSAIDA = CUPONS.DTSAIDA
         and CODFISCAL = CUPONS.CODFISCAL
         and PERCICM = CUPONS.PERCICM
         and ie = to_char(cupons.caixa)
         and ESPECIE = 'MR';

      V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
      IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
        V_CONTADORREGISTRO := 0;
        COMMIT;
      END IF;

    end loop;
  end;

  /*****************************************************************************************/
  PROCEDURE CORRIGIR_NUMERACAO_MAPARESUMO IS
      V_NUMMAPADIA                 NUMBER;
      V_DTOLD                      DATE;
  BEGIN
    V_NUMMAPA := 1;
    BEGIN
     --PEGA SEMPRE O MAIOR  NUMMAPA DO DIA ANTERIOR PARA CORRIGIR.
      SELECT MAX(DTEMISSAO)
        INTO V_DATAMAPAANTERIOR
        FROM PCCUPOMFISCALZ
       WHERE CODFILIAL = PCODFILIAL
         AND DTEMISSAO < DATA1;

      V_DTOLD := V_DATAMAPAANTERIOR;

      SELECT MAX(NUMMAPA)
        INTO V_NUMMAPA
        FROM PCCUPOMFISCALZ
       WHERE DTEMISSAO = V_DATAMAPAANTERIOR
         AND CODFILIAL = PCODFILIAL;
    EXCEPTION
      WHEN OTHERS THEN
        V_NUMMAPA := 1;
    END;

    if V_NUMMAPA <= 1 then
      BEGIN
         SELECT MAX(NUMMAPA)
          INTO V_NUMMAPADIA
          FROM PCCUPOMFISCALZ
         WHERE DTEMISSAO = DATA1
           AND CODFILIAL = PCODFILIAL;
      EXCEPTION
               WHEN OTHERS THEN
             V_NUMMAPADIA := 1;
     END;

     IF V_NUMMAPADIA <> 1 THEN
        V_NUMMAPA := V_NUMMAPADIA;
     END IF;
   end if;

   V_NUMMAPA := NVL(V_NUMMAPA, 1);
   ----------------------------------------
    -- CORRIGINDO NUMERACAO DE MAPAS RESUMO
    FOR REG_REDUCOES IN (SELECT DTEMISSAO, ROWID ID, Numreducaoz
                           FROM PCCUPOMFISCALZ
                          WHERE DTEMISSAO BETWEEN DATA1 AND DATA2
                            AND CODFILIAL = PCODFILIAL
                          ORDER BY DTEMISSAO)
    LOOP
      -------------------------------------------------------------------------------------------
      V_SQLERRO := 'CORRIGINDO NUMERA??O DE MAPAS RESUMO (DATA: ' ||
                   TO_CHAR(REG_REDUCOES.DTEMISSAO, 'DD/MM/YYYY') || '))';
      -------------------------------------------------------------------------------------------
      if V_DTOLD < REG_REDUCOES.DTEMISSAO THEN
        V_NUMMAPA := V_NUMMAPA + 1;
        V_DTOLD   := REG_REDUCOES.DTEMISSAO;
      end if;

      UPDATE PCCUPOMFISCALZ
         SET NUMMAPA = V_NUMMAPA
       WHERE ROWID     = REG_REDUCOES.ID
         and DTEMISSAO = REG_REDUCOES.DTEMISSAO
         and CODFILIAL = PCODFILIAL
         and Numreducaoz = REG_REDUCOES.NUMREDUCAOZ;

      V_CONTADORREGISTRO := V_CONTADORREGISTRO +1;
    END LOOP;
  END;

 /*****************************************************************************************/
  -- INCLUS?O DAS NOTAS FISCAIS
  procedure INSERIR_REGISTRO_NOTA(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'INSERINDO REGISTRO (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    insert into PCNFBASESAID
      (CODFILIALNF,
       NUMTRANSVENDA,
       ESPECIE,
       SERIE,
       SUBSERIE,
       NUMNOTA,
       DTSAIDA,
       DTCANCEL,
       CODCLI,
       CLIENTE,
       CGC,
       IE,
       UF,
       TIPOFJ,
       UFFILIAL,
       PERCICM,
       PERCICMNAOTRIB,
       VLTOTAL,
       CODCONT,
       CODFISCAL,
       SITTRIBUT,
       CODOPER,
       VLBASE,
       VLBASENAOTRIB,
       VLBASE_REDUCAO,
       VLICMS,
       VLICMSNAOTRIB,
       VLISENTAS,
       VLOUTRAS,
       OBS,
       VLDESDOBRADO,
       TIPOVENDA,
       BASEST,
       VLST,
       BASESTFORANF,
       VLSTFORANF,
       VLBASEIPI,
       VLIPI,
       PERCIPI,
       VLISENTASIPI,
       VLBASEISENTASIPI,
       VLBASEOUTRASIPI,
       VLOUTRASIPI,
       VLPIS,
       VLCOFINS,
       BCIMPESTADUAL,
       VLIMPESTADUAL,
       VLREPASSE,
       VLBASEBCR,
       VLSTBCR,
       VLICMSBCR,
       VLNAOTRIB_DAPI,
       VLBASERED_DAPI,
       VLSUSPENSAS_DAPI,
       VLST_DAPI,
       VLISENTAS_DAPI,
       VLOUTRAS_DAPI,
       DTGERA,
       VLDESCREDUCAOPIS,
       VLDESCREDUCAOCOFINS,
       VLFCP,
       VLICMSUFREM,
       VLICMSUFDESt,
       VLICMSDIFALIQPART,
       VLBASEPARTDEST,
       VLIPIDEVFORNEC,
       VLACRESCIMOFUNCEP,
       VLFECP,
       PERACRESCIMOFUNCEP,
       VLBASEFCPICMS,
       VLBASEFCPST,
       ALIQICMSFECP,
       VLOUTRASDESP,
       VLFRETE,
       VLDESCONTO,
       VLPRODUTO)
    values
      (P_NOTA.CODFILIAL,
       P_NOTA.NUMTRANSVENDA,
       P_NOTA.ESPECIE,
       P_NOTA.SERIE,
       P_NOTA.SUBSERIE,
       P_NOTA.NUMNOTA,
       P_NOTA.DTSAIDA,
       P_NOTA.DTCANCEL,
       P_NOTA.CODCLI,
       P_NOTA.CLIENTE,
       P_NOTA.CNPJ,
       P_NOTA.IE,
       P_NOTA.UF,
       P_NOTA.TIPOFJ,
       V_UFFILIAL,
       P_NOTA.PERCICM,
       P_NOTA.PERCICMNAOTRIB,
       P_NOTA.VLTOTAL,
       P_NOTA.CODCONT,
       P_NOTA.CODFISCAL,
       P_NOTA.SITTRIBUT,
       P_NOTA.CODOPER,
       case
       when(V_ARREDVLITENSNFSAIDA = 'S') or (P_NOTA.CHAVENFE is not null) then
       P_NOTA.VLBASE_ARRED_POR_ITEM else P_NOTA.VLBASE end,
       P_NOTA.VLBASENAOTRIB,
       P_NOTA.VLBASE_REDUCAO,
       P_NOTA.VLICMS,
       P_NOTA.VLICMSNAOTRIB,
       DECODE(V_ARREDVLITENSNFSAIDA, 'S', P_NOTA.VLISENTAS_ARRED_POR_ITEM, P_NOTA.VLISENTAS),
       P_NOTA.VLOUTRAS,
       SUBSTR(P_NOTA.OBS, 1, V_TAMANHO_OBS),
       DECODE(V_ARREDVLITENSNFSAIDA, 'S', P_NOTA.VLDESDOBRADO_ARRED_POR_ITEM, P_NOTA.VLDESDOBRADO),
       P_NOTA.TIPOVENDA,
       P_NOTA.BASEST,
       P_NOTA.VLST,
       P_NOTA.BASESTFORANF,
       P_NOTA.VLSTFORANF,
       P_NOTA.VLBASEIPI,
       P_NOTA.VLIPI,
       P_NOTA.PERCIPI,
       P_NOTA.VLISENTASIPI,
       P_NOTA.VLBASEISENTASIPI,
       DECODE(V_VALIDA_VALOR_OUTRAS_IPI, 'S', GREATEST(P_NOTA.VLDESDOBRADO -
                        NVL(P_NOTA.VLBASEIPI, 0) -
                        NVL(P_NOTA.VLIPI, 0) -
                        DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', NVL(P_NOTA.VLST, 0), 0), 0), P_NOTA.VLBASEOUTRASIPI),
       P_NOTA.VLOUTRASIPI,
       P_NOTA.VLPIS,
       P_NOTA.VLCOFINS,
       P_NOTA.BCIMPESTADUAL,
       P_NOTA.VLIMPESTADUAL,
       P_NOTA.VLREPASSE,
       P_NOTA.VLBASEBCR,
       P_NOTA.VLSTBCR,
       p_NOTA.VLICMSBCR,
       P_NOTA.VLNAOTRIB_DAPI,
       P_NOTA.VLBASERED_DAPI,
       P_NOTA.VLSUSPENSAS_DAPI,
       P_NOTA.VLST_DAPI,
       P_NOTA.VLISENTAS_DAPI,
       P_NOTA.VLOUTRAS_DAPI,
       P_NOTA.DTGERA,
       P_NOTA.VLDESCREDUCAOPIS,
       P_NOTA.VLDESCREDUCAOCOFINS,
       p_nota.vlfcp,
       case when NOT p_nota.dtcancel is null then 0 else p_nota.vlicmspartrem end,
       case when NOT p_nota.dtcancel is null then 0 else p_nota.vlicmspartdest end,
       case when NOT p_nota.dtcancel is null then 0 else p_nota.VLICMSDIFALIQPART end,
       case when NOT p_nota.dtcancel is null then 0 else p_Nota.VLBASEPARTDEST end,
       P_NOTA.VLIPIDEVFORNEC,
       P_NOTA.VLACRESCIMOFUNCEP,
       P_NOTA.VLFECP,
       P_NOTA.PERACRESCIMOFUNCEP,
       P_NOTA.VLBASEFCPICMS,
       P_NOTA.VLBASEFCPST,
       P_NOTA.ALIQICMSFECP,
       P_NOTA.VLOUTROS,
       P_NOTA.VLFRETE_MOV,
       P_NOTA.VL_DESCONTO,
       P_NOTA.VL_PRODUTO);

  end;

  procedure GERAR_DESPESA_FRETE_NFE(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    -- GRAVAR VALORES DE DESPESA E FRETE, TRUNCANDO EM 2 CASAS DECIMAIS
    --------------------------------------------------------------------------
    for DADOS in (select M.CODFISCAL,
                         M.SITTRIBUT,
                         DECODE(M.GERAICMSLIVROFISCAL, 'N', 0, NVL(M.PERCICM, 0)) PERCICM,
                         DECODE(M.GERAICMSLIVROFISCAL, 'N', NVL(M.PERCICM, 0), 0) PERCICMNAOTRIB,
                         sum(ROUND(M.QTCONT * NVL(M.VLFRETE, 0), 2)) VLFRETE,
                         sum(ROUND(M.QTCONT *
                                   DECODE(M.CODOPER, 'SD', 0, NVL(M.VLOUTROS, 0)), 2)) VLDESPESA,

                         ROUND(sum(M.QTCONT * NVL(MC.VLBASEFRETE, 0)), 2) VLBASEFRETE,
                         ROUND(sum(M.QTCONT * NVL(MC.VLBASEOUTROS, 0)), 2) VLBASEDESPESA,

                         sum(ROUND(ROUND(M.QTCONT * (NVL(MC.VLBASEOUTROS, 0) +
                                         NVL(MC.VLBASEFRETE, 0)), 2) *
                                   DECODE(M.GERAICMSLIVROFISCAL, 'N', 0, M.PERCICM) / 100, 2)) VLICMS,
                         sum(ROUND(ROUND(M.QTCONT * (NVL(MC.VLBASEOUTROS, 0) +
                                         NVL(MC.VLBASEFRETE, 0)), 2) *
                                   DECODE(M.GERAICMSLIVROFISCAL, 'N', M.PERCICM, 0) / 100, 2)) VLICMSNAOTRIB
                    from PCMOV       M,
                         PCMOVCOMPLE MC
                   where M.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                     and M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
           and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                   group by M.GERAICMSLIVROFISCAL,
                            M.CODFISCAL,
                            M.PERCICM,
                            M.SITTRIBUT)
    loop
      update PCNFBASESAID A
         set VLDESDOBRADO  = NVL(VLDESDOBRADO, 0) + NVL(DADOS.VLFRETE, 0) +
                             NVL(DADOS.VLDESPESA, 0),
             VLBASE        = NVL(VLBASE, 0) +
                             DECODE(DADOS.PERCICM, 0, 0, DADOS.VLBASEFRETE +
                                    DADOS.VLBASEDESPESA),
             VLBASENAOTRIB = NVL(VLBASENAOTRIB, 0) +
                             DECODE(DADOS.PERCICMNAOTRIB, 0, 0, DADOS.VLBASEFRETE +
                                     DADOS.VLBASEDESPESA),
             VLFRETE          = NVL(VLFRETE, 0) + NVL(DADOS.VLFRETE, 0),
             VLOUTRASDESP     = NVL(VLOUTRASDESP, 0) +
                                NVL(DADOS.VLDESPESA, 0),
             VLBASEFRETE      = NVL(VLBASEFRETE, 0) +
                                DECODE(DADOS.PERCICM, 0, 0, DADOS.VLBASEFRETE),
             VLBASEOUTRASDESP = NVL(VLBASEOUTRASDESP, 0) +
                                DECODE(DADOS.PERCICM, 0, 0, DADOS.VLBASEDESPESA),
             VLICMS           = NVL(VLICMS, 0) + NVL(DADOS.VLICMS, 0),
             VLICMSNAOTRIB    = NVL(VLICMSNAOTRIB, 0) +
                                NVL(DADOS.VLICMSNAOTRIB, 0),
             VLISENTAS        = NVL(VLISENTAS, 0) +
                                DECODE((SELECT NVL(D.VLISENTAS, 'N')
                                        FROM PCDESTSITTRIBUT D
                                        WHERE D.SITTRIBUT = SUBSTR(A.SITTRIBUT, 2, 2)), 'S',
                                        (NVL(DADOS.VLDESPESA, 0)) - (NVL(DADOS.VLBASEFRETE, 0) + NVL(DADOS.VLBASEDESPESA, 0)), 0)
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA
         and CODFISCAL = DADOS.CODFISCAL
         and PERCICM = DADOS.PERCICM
         and DECODE(LENGTH(DADOS.SITTRIBUT), 3, SITTRIBUT, DECODE(LENGTH(SITTRIBUT), 3, SUBSTR(SITTRIBUT, 2, 2), SUBSTR(SITTRIBUT, 1, 2))) = DADOS.SITTRIBUT
         and ROWNUM = 1;
    end loop;
  end;
  
  --------------------------------------------------------------------------------
  procedure DELETAR_REGISTROS_PCNFBASESAID (pDATA1      IN DATE,
                                            pDATA2      IN DATE,
                                            pPCODFILIAL IN VARCHAR2,
                                            pNUMNOTA1   IN NUMBER,
                                            pNUMNOTA2   IN NUMBER,
                                            pNUMTRANSVENDA IN NUMBER := 0) IS
  begin 
     V_SQLERRO := 'EXCLUINDO REGISTROS ANTERIORES';
    begin
      -- Deletando nfs no processo do DF DTENTREGA. Onde o Dtsaida esta menor que o DTENTREGA
      if vnGeraDTENTREGA = 'S' then
          -- Deletando Doc.onde o DTENTREGA esta maior que DTSAIDA e o livro foi gerado com esse DTENTREGA.
         FOR DADOSNF IN (SELECT S.NUMTRANSVENDA
                           FROM PCNFSAID S
                          WHERE NVL(S.CODFILIALNF, S.CODFILIAL) = pPCODFILIAL
                            AND S.DTSAIDA BETWEEN pDATA1 and pDATA2
                            AND S.DTENTREGA > S.DTSAIDA
                            AND S.NUMNOTA BETWEEN pNUMNOTA1 AND pNUMNOTA2
                            AND S.NUMTRANSVENDA IN (SELECT DISTINCT S2.NUMTRANSVENDA
                                                      FROM PCNFBASESAID S2
                                                     WHERE S2.CODFILIALNF = pPCODFILIAL
                                                       AND S2.NUMTRANSVENDA = S.NUMTRANSVENDA
                                                       AND S2.DTSAIDA = S.DTENTREGA)
                          )
         LOOP
            delete /*+ INDEX (PCNFBASESAID PCNFBASESAID_IDX06) */
             from PCNFBASESAID S
            where S.NUMTRANSVENDA = DADOSNF.NUMTRANSVENDA;
          COMMIT;
         END LOOP;
      end if;

      delete /*+ INDEX (PCNFBASESAID PCNFBASESAID_IDX06) */ from PCNFBASESAID
       where DTSAIDA between pDATA1 and pDATA2
         and CODFILIALNF = pPCODFILIAL
         and NUMNOTA between pNUMNOTA1 and pNUMNOTA2
         AND DECODE(pNUMTRANSVENDA,0,0,NUMTRANSVENDA) = DECODE(pNUMTRANSVENDA,0,0,pNUMTRANSVENDA)
         and ESPECIE not in ('CF', 'MR');
      COMMIT;
      ---------------------------------------------------------------------------------
      delete /*+ INDEX (PCNFBASESAID PCNFBASESAID_IDX06) */ from PCNFBASESAID
       where DTSAIDA between pDATA1 and pDATA2
         and CODFILIALNF = pPCODFILIAL
         and ESPECIE in ('CF', 'MR');
    end;
    COMMIT;

  end; 

  procedure GERAR_MAPARESUMO(P_CODFILIAL in varchar2,
                             P_DATA1     in date,
                             P_DATA2     in date) is
  begin
    for MAPA in (-- MAPA RESUMO
                 select A.CODFILIALNF,
                         ------------------------------------------------------------------
                         TO_NUMBER(TO_CHAR(NVL((select max(NUMMAPA)
                                                 from PCCUPOMFISCALZ
                                                where DTEMISSAO = A.DTSAIDA
                                                  and CODFILIAL =
                                                      A.CODFILIALNF), 0)) ||
                                   TO_CHAR(A.DTSAIDA, 'DD')) NUMTRANSVENDA,
                         ------------------------------------------------------------------
                         null NUMTRANSVENDAORIGEM,
                         ------------------------------------------------------------------
                         0 NUMCAR,
                         ------------------------------------------------------------------
                         1 CONDVENDA,
                         ------------------------------------------------------------------
                         'MR' ESPECIE,
                         ------------------------------------------------------------------
                         V_SERIE SERIE,
                         ------------------------------------------------------------------
                         '' SUBSERIE,
                         ------------------------------------------------------------------
                         max((select max(NUMMAPA)
                               from PCCUPOMFISCALZ
                              where DTEMISSAO = A.DTSAIDA
                                and CODFILIAL = A.CODFILIALNF)) NUMNOTA,
                         ------------------------------------------------------------------
                         A.DTSAIDA,
                         ------------------------------------------------------------------
                         A.DTCANCEL,
                         ------------------------------------------------------------------
                         1 CODCLI,
                         ------------------------------------------------------------------
                         A.PERCICM,
                         ------------------------------------------------------------------
                         'CONSUMIDOR FINAL' CLIENTE,
                         ------------------------------------------------------------------
                         null CNPJ,
                         ------------------------------------------------------------------
                         a.codcli  IE,
                         ------------------------------------------------------------------
                         V_UFFILIAL UF,
                         ------------------------------------------------------------------
                         'F' TIPOFJ,
                         ------------------------------------------------------------------
                         'S' CONSUMIDORFINAL,
                         ------------------------------------------------------------------
                         (select sum(VLCONTABIL)
                            from PCCUPOMFISCALZ
                           where DTEMISSAO = A.DTSAIDA
                             and CODFILIAL = A.CODFILIALNF) VLTOTAL,
                         ------------------------------------------------------------------
                         A.CODCONT,
                         ------------------------------------------------------------------
                         A.CODFISCAL,
                         ------------------------------------------------------------------
                         '090' SITTRIBUT,
                         ------------------------------------------------------------------
                         CF.CODOPER,
                         ------------------------------------------------------------------
                         sum(A.VLBASE) VLBASE_ARRED_POR_ITEM,
                         ------------------------------------------------------------------
                         0 VLBASENAOTRIB,
                         ------------------------------------------------------------------
                         sum(A.VLBASE) VLBASE,
                         ------------------------------------------------------------------
                         sum(A.VLICMS) VLICMS,
                         ------------------------------------------------------------------
                         sum(A.VLISENTAS) VLISENTO_ARRED_POR_ITEM,
                         ------------------------------------------------------------------
                         sum(A.VLISENTAS) VLISENTAS,
                         ------------------------------------------------------------------
                         sum(A.VLOUTRAS) VLOUTRAS,
                         ------------------------------------------------------------------
                         'MAPA RESUMO' OBS,
                         ------------------------------------------------------------------
                         sum(A.VLDESDOBRADO) VLDESDOBRADO_ARRED_POR_ITEM,
                         ------------------------------------------------------------------
                         sum(A.VLDESDOBRADO) VLDESDOBRADO,
                         ------------------------------------------------------------------
                         0 VLFRETE,
                         ------------------------------------------------------------------
                         'S' FRETEPF,
                         ------------------------------------------------------------------
                         0 VLOUTRASDESP,
                         ------------------------------------------------------------------
                         0 VLBASEOUTRASDESP,
                         ------------------------------------------------------------------
                         0 VLOUTRASDESP_ITEM,
                         ------------------------------------------------------------------
                         0 PERBASEREDOUTRASDESP,
                         ------------------------------------------------------------------
                         'MR' TIPOVENDA,
                         ------------------------------------------------------------------
                         sum(A.BASEST) BASEST,
                         ------------------------------------------------------------------
                         sum(A.VLST) VLST,
                         ------------------------------------------------------------------
                         sum(A.VLBASEIPI) VLBASEIPI,
                         ------------------------------------------------------------------
                         sum(A.VLIPI) VLIPI,
                         ------------------------------------------------------------------
                         0 PERCIPI,
                         ------------------------------------------------------------------
                         0 VLISENTASIPI,
                         ------------------------------------------------------------------
                         0 VLBASEISENTASIPI,
                         ------------------------------------------------------------------
                         0 VLBASEOUTRASIPI,
                         ------------------------------------------------------------------
                         0 VLOUTRASIPI,
                         ------------------------------------------------------------------
                         0 VLPIS,
                         ------------------------------------------------------------------
                         0 VLCOFINS,
                         ------------------------------------------------------------------
                         0 BCIMPESTADUAL,
                         ------------------------------------------------------------------
                         0 VLIMPESTADUAL,
                         ------------------------------------------------------------------
                         0 VLREPASSE,
                         ------------------------------------------------------------------
                         0 VLBASEBCR,
                         ------------------------------------------------------------------
                         0 VLSTBCR,
                         ------------------------------------------------------------------
                         0 VLICMSBCR,
                         ------------------------------------------------------------------
                         0 VLNAOTRIB_DAPI,
                         ------------------------------------------------------------------
                         0 VLBASERED_DAPI,
                         ------------------------------------------------------------------
                         0 VLSUSPENSAS_DAPI,
                         ------------------------------------------------------------------
                         0 VLST_DAPI,
                         ------------------------------------------------------------------
                         0 VLISENTAS_DAPI,
                         ------------------------------------------------------------------
                         0 VLOUTRAS_DAPI,
                         ------------------------------------------------------------------
                         sysdate DTGERA,
                         ------------------------------------------------------------------
                         0 VLDESCREDUCAOPIS,
                         ------------------------------------------------------------------
                         0 VLDESCREDUCAOCOFINS,
                         SUM(VLIPIDEVFORNEC) VLIPIDEVFORNEC
                 ------------------------------------------------------------------
                   from PCNFBASESAID A,
                         PCCONSUM     C,
                         PCCFO        CF
                  where A.DTSAIDA between P_DATA1 and P_DATA2
                    and A.CODFILIALNF = P_CODFILIAL
                    and A.TIPOVENDA = 'XZ'
                    and A.CODFISCAL = CF.CODFISCAL(+)
                  group by A.CODFILIALNF,
                            C.ESTADO,
                            A.NUMNOTA || TO_CHAR(A.DTSAIDA, 'DD'),
                            A.NUMNOTA,
                            a.codcli,
                            A.DTSAIDA,
                            A.DTCANCEL,
                            A.PERCICM,
                            A.UF,
                            A.CODCONT,
                            A.CODFISCAL,
                            CF.CODOPER,
                            A.FLAG,
                            A.TIPOVENDA
                 ------------------------------------------------------------------
                  order by DTSAIDA, NUMTRANSVENDA, NUMNOTA)
    loop
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'INSERINDO REGISTRO (MAPA ' || MAPA.NUMNOTA || ' EM ' ||
                   TO_CHAR(MAPA.DTSAIDA, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      insert into PCNFBASESAID
        (CODFILIALNF,
         NUMTRANSVENDA,
         ESPECIE,
         SERIE,
         SUBSERIE,
         NUMNOTA,
         DTSAIDA,
         DTCANCEL,
         CODCLI,
         CLIENTE,
         CGC,
         IE,
         UF,
         TIPOFJ,
         UFFILIAL,
         PERCICM,
         VLTOTAL,
         CODCONT,
         CODFISCAL,
         SITTRIBUT,
         CODOPER,
         VLBASE,
         VLBASENAOTRIB,
         VLICMS,
         VLISENTAS,
         VLOUTRAS,
         OBS,
         VLDESDOBRADO,
         TIPOVENDA,
         BASEST,
         VLST,
         VLBASEIPI,
         VLIPI,
         PERCIPI,
         VLISENTASIPI,
         VLBASEISENTASIPI,
         VLBASEOUTRASIPI,
         VLOUTRASIPI,
         VLPIS,
         VLCOFINS,
         BCIMPESTADUAL,
         VLIMPESTADUAL,
         VLREPASSE,
         VLBASEBCR,
         VLSTBCR,
         VLICMSBCR,
         VLNAOTRIB_DAPI,
         VLBASERED_DAPI,
         VLSUSPENSAS_DAPI,
         VLST_DAPI,
         VLISENTAS_DAPI,
         VLOUTRAS_DAPI,
         DTGERA,
         VLDESCREDUCAOPIS,
         VLDESCREDUCAOCOFINS,
         VLIPIDEVFORNEC)
      values
        (P_CODFILIAL,
         MAPA.NUMTRANSVENDA,
         MAPA.ESPECIE,
         MAPA.SERIE,
         MAPA.SUBSERIE,
         MAPA.NUMNOTA,
         MAPA.DTSAIDA,
         MAPA.DTCANCEL,
         MAPA.CODCLI,
         MAPA.CLIENTE,
         MAPA.CNPJ,
         MAPA.IE,
         MAPA.UF,
         MAPA.TIPOFJ,
         V_UFFILIAL,
         MAPA.PERCICM,
         MAPA.VLTOTAL,
         MAPA.CODCONT,
         MAPA.CODFISCAL,
         MAPA.SITTRIBUT,
         MAPA.CODOPER,
         MAPA.VLBASE,
         MAPA.VLBASENAOTRIB,
         MAPA.VLICMS,
         MAPA.VLISENTAS,
         MAPA.VLOUTRAS,
         SUBSTR(MAPA.OBS, 1, V_TAMANHO_OBS),
         MAPA.VLDESDOBRADO,
         MAPA.TIPOVENDA,
         MAPA.BASEST,
         MAPA.VLST,
         MAPA.VLBASEIPI,
         MAPA.VLIPI,
         MAPA.PERCIPI,
         MAPA.VLISENTASIPI,
         MAPA.VLBASEISENTASIPI,
         MAPA.VLBASEOUTRASIPI,
         MAPA.VLOUTRASIPI,
         MAPA.VLPIS,
         MAPA.VLCOFINS,
         MAPA.BCIMPESTADUAL,
         MAPA.VLIMPESTADUAL,
         MAPA.VLREPASSE,
         MAPA.VLBASEBCR,
         MAPA.VLSTBCR,
         MAPA.VLICMSBCR,
         MAPA.VLNAOTRIB_DAPI,
         MAPA.VLBASERED_DAPI,
         MAPA.VLSUSPENSAS_DAPI,
         MAPA.VLST_DAPI,
         MAPA.VLISENTAS_DAPI,
         MAPA.VLOUTRAS_DAPI,
         MAPA.DTGERA,
         MAPA.VLDESCREDUCAOPIS,
         MAPA.VLDESCREDUCAOCOFINS,
         MAPA.VLIPIDEVFORNEC);

      V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
      IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
        V_CONTADORREGISTRO := 0;
        COMMIT;
      END IF;

    end loop;
  end;

  procedure GERAR_REDUCOES_CFOP_ZERO(P_CODFILIAL in varchar2,
                                     P_DATA1     in date,
                                     P_DATA2     in date) is
    V_GEROU_DIVISAO_CFOP boolean;
    V_VALOR_GERADO       number(20, 2);
    V_ULTIMO_CFOP        number;
  begin
    for REDUCAO in (-- REDU??O RESUMO CFOP ZERO
                     select A.CODFILIALNF,
                            A.NUMTRANSVENDA,
                            A.ESPECIE,
                            A.SERIE,
                            A.NUMNOTA,
                            A.DTSAIDA,
                            A.DTCANCEL,
                            A.CODCLI NUMECF,
                            A.PERCICM,
                            A.CLIENTE,
                            A.CGC,
                            A.IE,
                            A.UF,
                            A.TIPOFJ,
                            A.VLTOTAL,
                            A.CODCONT,
                            A.CODFISCAL,
                            A.SITTRIBUT,
                            A.CODOPER,
                            A.VLBASENAOTRIB,
                            A.VLBASE,
                            A.VLICMS,
                            A.VLISENTAS,
                            A.VLOUTRAS,
                            A.OBS,
                            A.VLDESDOBRADO,
                            A.VLFRETE,
                            A.VLOUTRASDESP,
                            A.VLBASEOUTRASDESP,
                            A.TIPOVENDA,
                            A.BASEST,
                            A.VLST,
                            A.VLBASEIPI,
                            A.VLIPI,
                            A.PERCIPI,
                            A.VLISENTASIPI,
                            A.VLBASEISENTASIPI,
                            A.VLBASEOUTRASIPI,
                            A.VLOUTRASIPI,
                            A.VLPIS,
                            A.VLCOFINS,
                            A.BCIMPESTADUAL,
                            A.VLIMPESTADUAL,
                            A.VLREPASSE,
                            A.VLBASEBCR,
                            A.VLSTBCR,
                            A.VLICMSBCR,
                            A.VLNAOTRIB_DAPI,
                            A.VLBASERED_DAPI,
                            A.VLSUSPENSAS_DAPI,
                            A.VLST_DAPI,
                            A.VLISENTAS_DAPI,
                            A.VLOUTRAS_DAPI,
                            A.DTGERA,
                            A.VLDESCREDUCAOPIS,
                            A.VLDESCREDUCAOCOFINS,
                            A.VLIPIDEVFORNEC
                       from PCNFBASESAID A,
                            PCCONSUM     C,
                            PCCFO        CF
                      where A.DTSAIDA between P_DATA1 and P_DATA2
                        and A.CODFILIALNF = P_CODFILIAL
                        and A.ESPECIE = V_ESPECIE
                        and A.SERIE = V_SERIE
                        and NVL(A.CODFISCAL, 0) = 0
                        and A.CODFISCAL = CF.CODFISCAL(+)
                      order by DTSAIDA, NUMTRANSVENDA, NUMNOTA)
    loop
      ---------------------------------------------------------------------------------
      V_SQLERRO := 'GERANDO CFOP CORRETO (REDU??O ' || REDUCAO.NUMNOTA ||
                   ' EM ' || TO_CHAR(REDUCAO.DTSAIDA, 'DD/MM/YYYY') || ')';
      ---------------------------------------------------------------------------------
      V_GEROU_DIVISAO_CFOP := false;
      V_VALOR_GERADO       := 0;
      -- GERAR REDU??ES COM CFOP DE CUPONS
      for NOVO in (select M.CODFISCAL,
                          sum(DECODE(M.TRUNCARITEM, 'N', ROUND(M.QTCONT *
                                            M.PUNITCONT, 2), TRUNC(M.QTCONT *
                                            M.PUNITCONT, 2))) VLDESDOBRADO,
                          sum(DECODE(M.TRUNCARITEM, 'N', ROUND(M.QTCONT *
                                            NVL(M.BASEICMS, 0), 2), TRUNC(M.QTCONT *
                                            NVL(M.BASEICMS, 0), 2))) VLBASE,
                          sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, M.QTCONT *
                                            NVL(M.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                                            M.QTCONT *
                                            M.VLPIS), 2)) VLPIS,
                          sum(ROUND(DECODE(DECODE(MC.USAPISCOFINSLIT, 'S', NVL(NVL(MC.QTLITRAGEM, P.LITRAGEM), 0), 0), 0, M.QTCONT *
                                            NVL(M.VLPIS, 0), NVL(MC.QTLITRAGEM, P.LITRAGEM) *
                                            M.QTCONT *
                                            M.VLPIS), 2)) VLCOFINS,
                          sum(DECODE(SUBSTR(M.CODECF, 1, 1), 'I', DECODE(M.TRUNCARITEM, 'N', ROUND(M.QTCONT *
                                                    M.PUNITCONT, 2), TRUNC(M.QTCONT *
                                                    M.PUNITCONT, 2)), 0)) VLISENTAS,
                          sum(DECODE(SUBSTR(M.CODECF, 1, 1), 'F', DECODE(M.TRUNCARITEM, 'N', ROUND(M.QTCONT *
                                                    M.PUNITCONT, 2), TRUNC(M.QTCONT *
                                                    M.PUNITCONT, 2)), 'N', DECODE(M.TRUNCARITEM, 'N', ROUND(M.QTCONT *
                                                    M.PUNITCONT, 2), TRUNC(M.QTCONT *
                                                    M.PUNITCONT, 2)), 0)) VLOUTRAS,
                          sum(DECODE(SUBSTR(M.CODECF, 1, 1), 'N', DECODE(M.TRUNCARITEM, 'N', ROUND(M.QTCONT *
                                                    M.PUNITCONT, 2), TRUNC(M.QTCONT *
                                                    M.PUNITCONT, 2)), 0)) VLNAOTRIB_DAPI,
                          0 VLST_DAPI

                     from PCNFSAID     N,
                          PCMOV        M,
                          PCMOVCOMPLE  MC,
                          PCPRODUT     P,
                          PCALIQUOTACF A
                    where N.NUMTRANSVENDA = M.NUMTRANSVENDA
                      and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                      and P.CODPROD(+) = M.CODPROD
                      and M.CODECF = A.SIGLA(+)
                      and NVL(A.CODFISCAL, 0) = 0
                      and M.CODFISCAL > 0
                      and NVL(N.CODFILIALNF, N.CODFILIAL) = REDUCAO.CODFILIALNF
                      and NVL(M.CODFILIALNF, M.CODFILIAL) = REDUCAO.CODFILIALNF
                      and M.PERCICM = REDUCAO.PERCICM
                      and N.DTSAIDA = REDUCAO.DTSAIDA
                      and N.CAIXA = REDUCAO.NUMECF
                      and N.ESPECIE in ('CP', 'NF')
                      and N.SERIE in ('CF', 'CP')
                    group by M.CODFISCAL)
      loop
        ---------------------------------------------------------------------------------
        -- INSERIR NOVO REGISTRO DE CFOP DE CUPOM
        insert into PCNFBASESAID
          (CODFILIALNF,
           NUMTRANSVENDA,
           ESPECIE,
           SERIE,
           SUBSERIE,
           NUMNOTA,
           DTSAIDA,
           DTCANCEL,
           CODCLI,
           CLIENTE,
           CGC,
           IE,
           UF,
           TIPOFJ,
           UFFILIAL,
           PERCICM,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASENAOTRIB,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPOVENDA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           VLISENTASIPI,
           VLBASEISENTASIPI,
           VLBASEOUTRASIPI,
           VLOUTRASIPI,
           VLPIS,
           VLCOFINS,
           BCIMPESTADUAL,
           VLIMPESTADUAL,
           VLREPASSE,
           VLBASEBCR,
           VLSTBCR,
           VLICMSBCR,
           VLNAOTRIB_DAPI,
           VLBASERED_DAPI,
           VLSUSPENSAS_DAPI,
           VLST_DAPI,
           VLISENTAS_DAPI,
           VLOUTRAS_DAPI,
           DTGERA,
           VLDESCREDUCAOPIS,
           VLDESCREDUCAOCOFINS,
           VLIPIDEVFORNEC)
        values
          (REDUCAO.CODFILIALNF,
           REDUCAO.NUMTRANSVENDA,
           REDUCAO.ESPECIE,
           REDUCAO.SERIE,
           null,
           REDUCAO.NUMNOTA,
           REDUCAO.DTSAIDA,
           REDUCAO.DTCANCEL,
           REDUCAO.NUMECF,
           REDUCAO.CLIENTE,
           REDUCAO.CGC,
           REDUCAO.IE,
           REDUCAO.UF,
           REDUCAO.TIPOFJ,
           REDUCAO.UF,
           REDUCAO.PERCICM,
           REDUCAO.VLTOTAL,
           REDUCAO.CODCONT,
           NOVO.CODFISCAL,
           REDUCAO.SITTRIBUT,
           REDUCAO.CODOPER,
           NOVO.VLBASE,
           REDUCAO.VLBASENAOTRIB,
           NOVO.VLBASE * REDUCAO.PERCICM / 100,
           NOVO.VLISENTAS,
           NOVO.VLOUTRAS,
           REDUCAO.OBS,
           NOVO.VLDESDOBRADO,
           REDUCAO.TIPOVENDA,
           REDUCAO.BASEST,
           REDUCAO.VLST,
           REDUCAO.VLBASEIPI,
           REDUCAO.VLIPI,
           REDUCAO.PERCIPI,
           REDUCAO.VLISENTASIPI,
           REDUCAO.VLBASEISENTASIPI,
           DECODE(V_VALIDA_VALOR_OUTRAS_IPI, 'S', NOVO.VLDESDOBRADO, REDUCAO.VLBASEOUTRASIPI),
           REDUCAO.VLOUTRASIPI,
           NOVO.VLPIS,
           NOVO.VLCOFINS,
           REDUCAO.BCIMPESTADUAL,
           REDUCAO.VLIMPESTADUAL,
           REDUCAO.VLREPASSE,
           REDUCAO.VLBASEBCR,
           REDUCAO.VLSTBCR,
           REDUCAO.VLICMSBCR,
           NOVO.VLNAOTRIB_DAPI,
           REDUCAO.VLBASERED_DAPI,
           REDUCAO.VLSUSPENSAS_DAPI,
           NOVO.VLST_DAPI,
           REDUCAO.VLISENTAS_DAPI,
           REDUCAO.VLOUTRAS_DAPI,
           REDUCAO.DTGERA,
           REDUCAO.VLDESCREDUCAOPIS,
           REDUCAO.VLDESCREDUCAOCOFINS,
           REDUCAO.VLIPIDEVFORNEC);

        V_GEROU_DIVISAO_CFOP := true;
        V_VALOR_GERADO       := V_VALOR_GERADO + NOVO.VLDESDOBRADO;
        V_ULTIMO_CFOP        := NOVO.CODFISCAL;

        V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
        IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
          V_CONTADORREGISTRO := 0;
          COMMIT;
        END IF;
      end loop;

      if V_GEROU_DIVISAO_CFOP
      then
        -- AGREGAR DIFEREN?A NO ULTIMO CFOP INCLUSO
        if V_VALOR_GERADO <> REDUCAO.VLDESDOBRADO
        then
          update PCNFBASESAID
             set VLDESDOBRADO    = VLDESDOBRADO +
                                   NVL((REDUCAO.VLDESDOBRADO -
                                       V_VALOR_GERADO), 0),
                 VLBASE          = VLBASE + NVL((REDUCAO.VLDESDOBRADO -
                                                V_VALOR_GERADO), 0),
                 VLICMS          = VLICMS +
                                   NVL(((REDUCAO.VLDESDOBRADO -
                                       V_VALOR_GERADO) * PERCICM / 100), 0),
                 VLBASEOUTRASIPI = VLBASEOUTRASIPI +
                                   NVL((REDUCAO.VLDESDOBRADO -
                                       V_VALOR_GERADO), 0)
           where CODFILIALNF = REDUCAO.CODFILIALNF
             and DTSAIDA = REDUCAO.DTSAIDA
             and CODCLI = REDUCAO.NUMECF
             and CODFISCAL = V_ULTIMO_CFOP
             and PERCICM = REDUCAO.PERCICM
             and ROWNUM = 1;

        end if;
        ---------------------------------------------------------------------------------
        -- EXCLUIR REGISTRO COM CFOP ZERO
        delete from PCNFBASESAID
         where CODFILIALNF = REDUCAO.CODFILIALNF
           and DTSAIDA = REDUCAO.DTSAIDA
           and CODCLI = REDUCAO.NUMECF
           and PERCICM = REDUCAO.PERCICM
           and CODFISCAL = 0;

        COMMIT;
      end if;
      ---------------------------------------------------------------------------------
      V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
      IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
        V_CONTADORREGISTRO := 0;
        COMMIT;
      END IF;

    -----------------------------------------------------------------------------------
    update PCNFBASESAID A
       set VLISENTAS_DAPI = GREATEST(NVL(VLISENTAS, 0) -
                                     NVL(VLNAOTRIB_DAPI, 0) -
                                     NVL(VLBASERED_DAPI, 0), 0),
           VLOUTRAS_DAPI  = GREATEST(NVL(VLOUTRAS, 0) -
                                     NVL(VLSUSPENSAS_DAPI, 0) -
                                     DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', 0, NVL(VLST, 0)), 0)
     where A.NUMTRANSVENDA = REDUCAO.NUMTRANSVENDA
       and A.NUMNOTA       = REDUCAO.NUMNOTA
       and (A.VLOUTRAS > 0 or A.VLISENTAS > 0);
     COMMIT;
    -----------------------------------------------------------------------------------

    end loop;
  end;

  /*****************************************************************************************/
  -- GERA??O DE REGISTROS DE DESPESAS ACESSORIAS
  procedure GERAR_DESPESA_ACESSORIA(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO DEPESA ACESSORIA (NOTA ' || P_NOTA.NUMNOTA ||
                 ' EM ' || TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- REGISTRO DE DESPESA ACESSORIA POR PARAMETROS GERAIS DO SISTEMA
    ---------------------------------------------------------------------------------
    if (V_TIPOALIQOUTRASDESP in ('P', 'F')) and
       (P_NOTA.VLOUTRASDESP_ITEM = 0)
    then
      ---------------------------------------------------------------------------------
      -- ATUALIZANDO SE J? EXISTIR CFOP/ALIQUOTA
      update PCNFBASESAID A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP),
             A.VLICMS           = NVL(A.VLICMS, 0) + DECODE(A.PERCICM, 0, 0, NVL(P_NOTA.VLBASEOUTRASDESP, 0)) *
                                  A.PERCICM / 100,
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)),
             A.VLOUTRASDESP     = P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL =
             DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALOUTRASDESP, V_CODFISCALINTEROUTRASDESP)
         and A.PERCICM =
             DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP)
         and ROWNUM = 1;
      -------------------------------------------------------------------------------------------
      -- INCLUIR SE N?O EXISTIR CFOP/ALIQUOTA
      if sql%rowcount = 0
      then
        insert into PCNFBASESAID
          (CODFILIALNF,
           NUMTRANSVENDA,
           ESPECIE,
           SERIE,
           SUBSERIE,
           NUMNOTA,
           DTSAIDA,
           DTCANCEL,
           CODCLI,
           CLIENTE,
           CGC,
           IE,
           UF,
           TIPOFJ,
           UFFILIAL,
           PERCICM,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASE_REDUCAO,
           VLBASENAOTRIB,
           VLOUTRASDESP,
           VLBASEOUTRASDESP,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPOVENDA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           DTGERA,
           VLREPASSE,
           TIPOREGISTRO,
           VLDESCREDUCAOPIS,
           VLDESCREDUCAOCOFINS,
           VLIPIDEVFORNEC)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSVENDA,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.SUBSERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.DTSAIDA,
                 P_NOTA.DTCANCEL,
                 P_NOTA.CODCLI,
                 P_NOTA.CLIENTE,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 P_NOTA.TIPOFJ,
                 V_UFFILIAL,
                 DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP),
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALOUTRASDESP, V_CODFISCALINTEROUTRASDESP),
                 P_NOTA.SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASE,
                 DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                         P_NOTA.VLBASEOUTRASDESP),
                 0 VLBASENAOTRIB,
                 P_NOTA.VLOUTRASDESP,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) * 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'DESP.ACESSORIA' OBS,
                 P_NOTA.VLOUTRASDESP,
                 'D' TIPOVENDA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 P_NOTA.DTGERA,
                 0 VLREPASSE,
                 'D' TIPOREGISTRO,
                 P_NOTA.VLDESCREDUCAOPIS,
                 P_NOTA.VLDESCREDUCAOCOFINS,
                 P_NOTA.VLIPIDEVFORNEC
            from DUAL;
      end if;
    end if;
    -------------------------------------------------------------------------------------------
    -- REGISTRO DE DESP. ACESS?RIAS ATRAVES DE TRIBUTA??O POR ESTADO
    -------------------------------------------------------------------------------------------
    if (V_TIPOALIQOUTRASDESP = 'T') and (P_NOTA.VLOUTRASDESP_ITEM = 0)
    then
      -------------------------------------------------------------------------------------------
      -- ATUALIZANDO SE JA EXISTIR CFOP/ALIQUOTA
      update PCNFBASESAID A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP),
             A.VLICMS           = NVL(A.VLICMS, 0) + DECODE(A.PERCICM, 0, 0, NVL(P_NOTA.VLBASEOUTRASDESP, 0)) *
                                  A.PERCICM / 100,
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)),
             A.VLOUTRASDESP     = P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and ROWNUM = 1
         and exists
       (select T.CODFILIALNF
                from PCTRIBOUTROS T
               where T.UFDESTINO = A.UF
                 and T.CODFILIALNF = A.CODFILIALNF
                 and A.CODFISCAL =
                     DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', T.CODFISCALOUTRASDESP, T.CODFISCALOUTRASDESPPF)
                 and A.PERCICM =
                     DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0)));
      -------------------------------------------------------------------------------------------
      -- INCLUINDO SE N?O EXISTIR CFOP/ALIQUOTA
      if sql%rowcount = 0
      then
        insert into PCNFBASESAID
          (CODFILIALNF,
           NUMTRANSVENDA,
           ESPECIE,
           SERIE,
           SUBSERIE,
           NUMNOTA,
           DTSAIDA,
           DTCANCEL,
           CODCLI,
           PERCICM,
           CLIENTE,
           CGC,
           IE,
           UF,
           UFFILIAL,
           TIPOFJ,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASE_REDUCAO,
           VLBASENAOTRIB,
           VLOUTRASDESP,
           VLBASEOUTRASDESP,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPOVENDA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           DTGERA,
           VLREPASSE,
           TIPOREGISTRO,
           VLDESCREDUCAOPIS,
           VLDESCREDUCAOCOFINS,
           VLIPIDEVFORNEC)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSVENDA,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.SUBSERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.DTSAIDA,
                 P_NOTA.DTCANCEL,
                 P_NOTA.CODCLI,
                 DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0)),
                 P_NOTA.CLIENTE,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 V_UFFILIAL,
                 P_NOTA.TIPOFJ,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', T.CODFISCALOUTRASDESP, T.CODFISCALOUTRASDESPPF),
                 P_NOTA.SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0)), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                         P_NOTA.VLBASEOUTRASDESP),
                 0 VLBASENAOTRIB,
                 P_NOTA.VLOUTRASDESP,
                 DECODE(DECODE(P_NOTA.TIPOFJ || P_NOTA.CONSUMIDORFINAL, 'JN', NVL(T.ALIQICMOUTRASDESP, 0), NVL(T.ALIQICMOUTRASDESPPF, 0)), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'DESP.ACESSORIA' OBS,
                 P_NOTA.VLOUTRASDESP,
                 'D' TIPOVENDA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 P_NOTA.DTGERA,
                 0 VLREPASSE,
                 'D' TIPOREGISTRO,
                 P_NOTA.VLDESCREDUCAOPIS,
                 P_NOTA.VLDESCREDUCAOCOFINS,
                 P_NOTA.VLIPIDEVFORNEC
            from DUAL,
                 PCTRIBOUTROS T
           where T.CODFILIALNF = P_NOTA.CODFILIAL
             and T.UFDESTINO = P_NOTA.UF;
      end if;
    end if;
    ---------------------------------------------------------------------------------
    -- REGISTRO DE DESP. ACESS?RIAS (TRIBUTA??O POR NOTA FISCAL MIN(CFOP))
    ---------------------------------------------------------------------------------
    if (V_TIPOALIQOUTRASDESP = 'N') and (P_NOTA.VLOUTRASDESP_ITEM = 0)
    then
      -------------------------------------------------------------------------------------------
      -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
      update PCNFBASESAID A
         set A.VLDESDOBRADO     = A.VLDESDOBRADO + P_NOTA.VLOUTRASDESP,
             A.VLBASE           = A.VLBASE +
                                  DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP),
             A.VLICMS           = NVL(A.VLICMS, 0) + DECODE(A.PERCICM, 0, 0, NVL(P_NOTA.VLBASEOUTRASDESP, 0)) *
                                  A.PERCICM / 100,
             A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                  DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                                          DECODE(A.PERCICM, 0, 0, NVL(P_NOTA.VLBASEOUTRASDESP, 0))),
             A.VLOUTRASDESP     = P_NOTA.VLOUTRASDESP,
             A.VLBASEOUTRASDESP = DECODE(A.PERCICM, 0, 0, P_NOTA.VLBASEOUTRASDESP)
       where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and A.NUMNOTA = P_NOTA.NUMNOTA
         and A.CODFISCAL = (select min(CODFISCAL)
                              from PCNFBASESAID
                             where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                               and NUMNOTA = P_NOTA.NUMNOTA)
         and A.PERCICM =
             DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP)
         and ROWNUM = 1;
      -------------------------------------------------------------------------------------------
      --  INCLUIR SE N?O EXISTIR CFOP/ALIQUOTA
      if sql%rowcount = 0
      then
        insert into PCNFBASESAID
          (CODFILIALNF,
           NUMTRANSVENDA,
           ESPECIE,
           SERIE,
           SUBSERIE,
           NUMNOTA,
           DTSAIDA,
           DTCANCEL,
           CODCLI,
           PERCICM,
           CLIENTE,
           CGC,
           IE,
           UF,
           UFFILIAL,
           TIPOFJ,
           VLTOTAL,
           CODCONT,
           CODFISCAL,
           SITTRIBUT,
           CODOPER,
           VLBASE,
           VLBASE_REDUCAO,
           VLBASENAOTRIB,
           VLOUTRASDESP,
           VLBASEOUTRASDESP,
           VLICMS,
           VLISENTAS,
           VLOUTRAS,
           OBS,
           VLDESDOBRADO,
           TIPOVENDA,
           BASEST,
           VLST,
           VLBASEIPI,
           VLIPI,
           PERCIPI,
           DTGERA,
           VLREPASSE,
           TIPOREGISTRO,
           VLDESCREDUCAOPIS,
           VLDESCREDUCAOCOFINS)
          select P_NOTA.CODFILIAL,
                 P_NOTA.NUMTRANSVENDA,
                 P_NOTA.ESPECIE,
                 P_NOTA.SERIE,
                 P_NOTA.SUBSERIE,
                 P_NOTA.NUMNOTA,
                 P_NOTA.DTSAIDA,
                 P_NOTA.DTCANCEL,
                 P_NOTA.CODCLI,
                 DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP),
                 P_NOTA.CLIENTE,
                 P_NOTA.CNPJ,
                 P_NOTA.IE,
                 P_NOTA.UF,
                 V_UFFILIAL,
                 P_NOTA.TIPOFJ,
                 P_NOTA.VLTOTAL,
                 P_NOTA.CODCONT,
                 A.CODFISCAL,
                 '090' SITTRIBUT,
                 P_NOTA.CODOPER,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASE,
                 DECODE(NVL(P_NOTA.VLBASEOUTRASDESP, 0), 0, 0, P_NOTA.VLOUTRASDESP -
                         P_NOTA.VLBASEOUTRASDESP),
                 0 VLBASENAOTRIB,
                 P_NOTA.VLOUTRASDESP,
                 DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, P_NOTA.VLBASEOUTRASDESP) VLBASEOUTRASDESP,
                 0 VLICMS,
                 0 VLISENTAS,
                 0 VLOUTRAS,
                 'DESP.ACESSORIA' OBS,
                 P_NOTA.VLOUTRASDESP,
                 'D' TIPOVENDA,
                 0 BASEST,
                 0 VLST,
                 0 VLBASEIPI,
                 0 VLIPI,
                 0 PERCIPI,
                 P_NOTA.DTGERA,
                 0 VLREPASSE,
                 'D' TIPOREGISTRO,
                 P_NOTA.VLDESCREDUCAOPIS,
                 P_NOTA.VLDESCREDUCAOCOFINS
            from PCNFBASESAID A
           where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
             and A.NUMNOTA = P_NOTA.NUMNOTA
             and A.CODFISCAL =
                 (select min(CODFISCAL)
                    from PCNFBASESAID
                   where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                     and NUMNOTA = P_NOTA.NUMNOTA)
             and ROWNUM = 1;
      end if;
    end if;
    -------------------------------------------------------------------------------------------
    -- REGISTRO DE DESP. ACESSORIA INFORMADA NOS ITENS
    -------------------------------------------------------------------------------------------
    if P_NOTA.VLOUTRASDESP_ITEM > 0
    then
      -------------------------------------------------------------------------------------------
      -- ATUALIZAR SE JA EXISTIR CFOP/ALIQUOTA
      for DADOS in (select M.CODFISCAL,
                           DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP) ALIQUOTA,
                           sum(M.QTCONT *
                               (NVL(M.VLOUTROS, 0) - NVL(M.VLACRESCIMOPF, 0))) VLOUTRASDESP,
                           (sum(M.QTCONT * (NVL(M.VLOUTROS, 0) -
                                NVL(M.VLACRESCIMOPF, 0))) *
                           DECODE(NVL(P_NOTA.PERBASEREDOUTRASDESP, 0), 0, 100, P_NOTA.PERBASEREDOUTRASDESP) / 100) VLBASEOUTRASDESP
                      from PCMOV M
                     where M.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                       and M.DTCANCEL is null
             and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                       and ROUND(M.QTCONT * (NVL(M.VLOUTROS, 0) -
                                 NVL(M.VLACRESCIMOPF, 0)), 2) > 0
                       and M.QTCONT > 0
                       and exists
                     (select NUMNOTA
                              from PCNFBASESAID
                             where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                               and NUMNOTA = P_NOTA.NUMNOTA
                               and CODFISCAL = M.CODFISCAL
                               and PERCICM =
                                   DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP))
                     group by M.CODFISCAL)
      loop
        update PCNFBASESAID A
           set A.VLDESDOBRADO     = A.VLDESDOBRADO + DADOS.VLOUTRASDESP,
               A.VLOUTRASDESP     = DADOS.VLOUTRASDESP,
               A.VLBASE           = A.VLBASE +
                                    DECODE(DADOS.ALIQUOTA, 0, 0, DADOS.VLBASEOUTRASDESP),
               A.VLICMS           = A.VLICMS + DECODE(DADOS.ALIQUOTA, 0, 0, NVL(DADOS.VLBASEOUTRASDESP, 0)) *
                                    DADOS.ALIQUOTA / 100,
               A.VLBASE_REDUCAO   = NVL(A.VLBASE_REDUCAO, 0) +
                                    DECODE(NVL(DADOS.VLBASEOUTRASDESP, 0), 0, 0, DADOS.VLOUTRASDESP -
                                            DADOS.VLBASEOUTRASDESP),
               A.VLBASEOUTRASDESP = DECODE(DADOS.ALIQUOTA, 0, 0, DADOS.VLBASEOUTRASDESP)
         where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFISCAL = DADOS.CODFISCAL
           and A.PERCICM = DADOS.ALIQUOTA
           and ROWNUM = 1;
      end loop;
      -------------------------------------------------------------------------------------------
      -- INCLUIR SE N?O EXISTIR CFOP/ALIQUOTA
      insert into PCNFBASESAID
        (CODFILIALNF,
         NUMTRANSVENDA,
         ESPECIE,
         SERIE,
         SUBSERIE,
         NUMNOTA,
         DTSAIDA,
         DTCANCEL,
         CODCLI,
         PERCICM,
         CLIENTE,
         CGC,
         IE,
         UF,
         UFFILIAL,
         TIPOFJ,
         VLTOTAL,
         CODCONT,
         CODFISCAL,
         SITTRIBUT,
         CODOPER,
         VLBASE,
         VLBASE_REDUCAO,
         VLBASENAOTRIB,
         VLOUTRASDESP,
         VLBASEOUTRASDESP,
         VLICMS,
         VLISENTAS,
         VLOUTRAS,
         OBS,
         VLDESDOBRADO,
         TIPOVENDA,
         BASEST,
         VLST,
         VLBASEIPI,
         VLIPI,
         PERCIPI,
         DTGERA,
         VLREPASSE,
         TIPOREGISTRO,
         VLDESCREDUCAOPIS,
         VLDESCREDUCAOCOFINS)
        select P_NOTA.CODFILIAL,
               P_NOTA.NUMTRANSVENDA,
               P_NOTA.ESPECIE,
               P_NOTA.SERIE,
               P_NOTA.SUBSERIE,
               P_NOTA.NUMNOTA,
               P_NOTA.DTSAIDA,
               P_NOTA.DTCANCEL,
               P_NOTA.CODCLI,
               DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP),
               P_NOTA.CLIENTE,
               P_NOTA.CNPJ,
               P_NOTA.IE,
               P_NOTA.UF,
               V_UFFILIAL,
               P_NOTA.TIPOFJ,
               P_NOTA.VLTOTAL,
               P_NOTA.CODCONT,
               M.CODFISCAL,
               '090' SITTRIBUT,
               P_NOTA.CODOPER,
               DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, sum(M.QTCONT *
                           (NVL(M.VLOUTROS, 0) -
                           NVL(M.VLACRESCIMOPF, 0))) *
                       DECODE(NVL(P_NOTA.PERBASEREDOUTRASDESP, 0), 0, 100, P_NOTA.PERBASEREDOUTRASDESP) / 100) VLBASE,
               P_NOTA.VLOUTRASDESP -
               DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, NVL(P_NOTA.VLBASEOUTRASDESP, 0)),
               0 VLBASENAOTRIB,
               sum(M.QTCONT *
                   (NVL(M.VLOUTROS, 0) - NVL(M.VLACRESCIMOPF, 0))) VLOUTRASDESP,
               DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP), 0, 0, (sum(M.QTCONT *
                            (NVL(M.VLOUTROS, 0) -
                            NVL(M.VLACRESCIMOPF, 0))) *
                       DECODE(NVL(P_NOTA.PERBASEREDOUTRASDESP, 0), 0, 100, P_NOTA.PERBASEREDOUTRASDESP) / 100)) VLBASEOUTRASDESP,
               0 VLICMS,
               0 VLISENTAS,
               0 VLOUTRAS,
               'DESP.ACESSORIA' OBS,
               sum(M.QTCONT *
                   (NVL(M.VLOUTROS, 0) - NVL(M.VLACRESCIMOPF, 0))) VLDESDOBRADO,
               'D' TIPOVENDA,
               0 BASEST,
               0 VLST,
               0 VLBASEIPI,
               0 VLIPI,
               0 PERCIPI,
               P_NOTA.DTGERA,
               0 VLREPASSE,
               'D' TIPOREGISTRO,
               P_NOTA.VLDESCREDUCAOPIS,
               P_NOTA.VLDESCREDUCAOCOFINS
          from PCMOV M
         where M.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and M.NUMNOTA = P_NOTA.NUMNOTA
           and M.QTCONT > 0
           and M.DTCANCEL is null
       and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
           and ROUND(M.QTCONT *
                     (NVL(M.VLOUTROS, 0) - NVL(M.VLACRESCIMOPF, 0)), 2) > 0
           and not exists
         (select NUMNOTA
                  from PCNFBASESAID
                 where NUMTRANSVENDA = M.NUMTRANSVENDA
                   and NUMNOTA = M.NUMNOTA
                   and CODFISCAL = M.CODFISCAL
                   and PERCICM =
                       DECODE(V_UFFILIAL, P_NOTA.UF, V_ALIQICMOUTRASDESP, V_ALIQICMINTEROUTRASDESP))
         group by M.CODFISCAL;
    end if;
  end;

  /*******************************************************************************/
  procedure GERAR_FRETE(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO FRETE (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    if V_TRIBUTAFRETERATEADO = 'N'
    then
      ---------------------------------------------------------------------------------
      -- REGISTRO DE FRETE POR PARAMETROS GERAIS DO SISTEMA
      ---------------------------------------------------------------------------------
      if V_TIPOALIQOUTRASDESP in ('P', 'F')
      then
        ---------------------------------------------------------------------------------
        --- ATUALIZAR SE J? EXISTIR CFOP/ALIQUOTA
        update PCNFBASESAID A
           set A.VLDESDOBRADO = A.VLDESDOBRADO + P_NOTA.VLFRETE,
               A.VLBASE       = A.VLBASE +
                                DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE),
               A.VLICMS       = NVL(A.VLICMS, 0) +
                                NVL(P_NOTA.VLFRETE, 0) * A.PERCICM / 100,
               A.VLFRETE      = P_NOTA.VLFRETE,
               A.VLBASEFRETE  = DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE)
         where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFISCAL =
               DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALFRETE, V_CODFISCALINTERFRETE)
           and A.PERCICM =
               DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE)
           and ROWNUM = 1;
        ---------------------------------------------------------------------------------
        --- INCLUIR SE N?O EXISTIR CFOP/ALIQUOTA
        if sql%rowcount = 0
        then
          insert into PCNFBASESAID
            (CODFILIALNF,
             NUMTRANSVENDA,
             ESPECIE,
             SERIE,
             SUBSERIE,
             NUMNOTA,
             DTSAIDA,
             DTCANCEL,
             CODCLI,
             PERCICM,
             CLIENTE,
             CGC,
             IE,
             UF,
             UFFILIAL,
             TIPOFJ,
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
             TIPOVENDA,
             BASEST,
             VLST,
             VLBASEIPI,
             VLIPI,
             PERCIPI,
             DTGERA,
             VLREPASSE,
             TIPOREGISTRO,
             VLDESCREDUCAOPIS,
             VLDESCREDUCAOCOFINS)
            select P_NOTA.CODFILIAL,
                   P_NOTA.NUMTRANSVENDA,
                   P_NOTA.ESPECIE,
                   P_NOTA.SERIE,
                   P_NOTA.SUBSERIE,
                   P_NOTA.NUMNOTA,
                   P_NOTA.DTSAIDA,
                   P_NOTA.DTCANCEL,
                   P_NOTA.CODCLI,
                   DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE),
                   P_NOTA.CLIENTE,
                   P_NOTA.CNPJ,
                   P_NOTA.IE,
                   P_NOTA.UF,
                   V_UFFILIAL,
                   P_NOTA.TIPOFJ,
                   P_NOTA.VLTOTAL,
                   P_NOTA.CODCONT,
                   DECODE(V_UFFILIAL, P_NOTA.UF, V_CODFISCALFRETE, V_CODFISCALINTERFRETE),
                   P_NOTA.SITTRIBUT,
                   P_NOTA.CODOPER,
                   DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) VLBASE,
                   0 VLBASENAOTRIB,
                   P_NOTA.VLFRETE,
                   DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) VLBASEFRETE,
                   0 VLICMS,
                   0 VLISENTAS,
                   0 VLOUTRAS,
                   'FRETE' OBS,
                   P_NOTA.VLFRETE,
                   'F' TIPOVENDA,
                   0 BASEST,
                   0 VLST,
                   0 VLBASEIPI,
                   0 VLIPI,
                   0 PERCIPI,
                   P_NOTA.DTGERA,
                   0 VLREPASSE,
                   'F' TIPOREGISTRO,
                   P_NOTA.VLDESCREDUCAOPIS,
                   P_NOTA.VLDESCREDUCAOCOFINS
              from DUAL;
        end if;
      end if;
      ---------------------------------------------------------------------------------
      -- REGISTRO DE FRETE POR PARAMETROS POR ESTADO
      ---------------------------------------------------------------------------------
      if V_TIPOALIQOUTRASDESP = 'T'
      then
        ---------------------------------------------------------------------------------
        -- ATUALIZAR SE J? EXISTIR CFOP/ALIQUOTA
        update PCNFBASESAID A
           set A.VLDESDOBRADO = A.VLDESDOBRADO + P_NOTA.VLFRETE,
               A.VLBASE       = A.VLBASE +
                                DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE),
               A.VLICMS       = NVL(A.VLICMS, 0) +
                                NVL(P_NOTA.VLFRETE, 0) * A.PERCICM / 100,
               A.VLFRETE      = P_NOTA.VLFRETE,
               A.VLBASEFRETE  = DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE)
         where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFILIALNF = PCODFILIAL
           and exists
         (select T.CODFILIALNF
                  from PCTRIBOUTROS T
                 where T.CODFILIALNF = A.CODFILIALNF
                   and T.UFDESTINO = A.UF
                   and DECODE(P_NOTA.CONSUMIDORFINAL || P_NOTA.TIPOFJ, 'SF', T.CODFISCALFRETEPF, T.CODFISCALFRETE) =
                       A.CODFISCAL
                   and DECODE(P_NOTA.CONSUMIDORFINAL || P_NOTA.TIPOFJ, 'SF', T.PERCICMFRETEPF, T.PERCICMFRETE) =
                       A.PERCICM)
           and ROWNUM = 1;
        ---------------------------------------------------------------------------------
        -- ATUALIZAR SE J? EXISTIR CFOP/ALIQUOTA
        if sql%rowcount = 0
        then
          insert into PCNFBASESAID
            (CODFILIALNF,
             NUMTRANSVENDA,
             ESPECIE,
             SERIE,
             SUBSERIE,
             NUMNOTA,
             DTSAIDA,
             DTCANCEL,
             CODCLI,
             PERCICM,
             CLIENTE,
             CGC,
             IE,
             UF,
             UFFILIAL,
             TIPOFJ,
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
             TIPOVENDA,
             BASEST,
             VLST,
             VLBASEIPI,
             VLIPI,
             PERCIPI,
             DTGERA,
             VLREPASSE,
             TIPOREGISTRO,
             VLDESCREDUCAOPIS,
             VLDESCREDUCAOCOFINS)
            select P_NOTA.CODFILIAL,
                   P_NOTA.NUMTRANSVENDA,
                   P_NOTA.ESPECIE,
                   P_NOTA.SERIE,
                   P_NOTA.SUBSERIE,
                   P_NOTA.NUMNOTA,
                   P_NOTA.DTSAIDA,
                   P_NOTA.DTCANCEL,
                   P_NOTA.CODCLI,
                   DECODE(P_NOTA.CONSUMIDORFINAL || P_NOTA.TIPOFJ, 'SF', T.PERCICMFRETEPF, T.PERCICMFRETE),
                   P_NOTA.CLIENTE,
                   P_NOTA.CNPJ,
                   P_NOTA.IE,
                   P_NOTA.UF,
                   V_UFFILIAL,
                   P_NOTA.TIPOFJ,
                   P_NOTA.VLTOTAL,
                   P_NOTA.CODCONT,
                   DECODE(P_NOTA.CONSUMIDORFINAL || P_NOTA.TIPOFJ, 'SF', T.CODFISCALFRETEPF, T.CODFISCALFRETE),
                   P_NOTA.SITTRIBUT,
                   P_NOTA.CODOPER,
                   DECODE(DECODE(P_NOTA.CONSUMIDORFINAL || P_NOTA.TIPOFJ, 'SF', T.PERCICMFRETEPF, T.PERCICMFRETE), 0, 0, P_NOTA.VLFRETE) VLBASE,
                   0 VLBASENAOTRIB,
                   P_NOTA.VLFRETE,
                   DECODE(DECODE(P_NOTA.CONSUMIDORFINAL || P_NOTA.TIPOFJ, 'SF', T.PERCICMFRETEPF, T.PERCICMFRETE), 0, 0, P_NOTA.VLFRETE) VLBASEVLFRETE,
                   0 VLICMS,
                   0 VLISENTAS,
                   0 VLOUTRAS,
                   'FRETE' OBS,
                   P_NOTA.VLFRETE,
                   'F' TIPOVENDA,
                   0 BASEST,
                   0 VLST,
                   0 VLBASEIPI,
                   0 VLIPI,
                   0 PERCIPI,
                   P_NOTA.DTGERA,
                   0 VLREPASSE,
                   'F' TIPOREGISTRO,
                   P_NOTA.VLDESCREDUCAOPIS,
                   P_NOTA.VLDESCREDUCAOCOFINS
              from PCTRIBOUTROS T
             where T.CODFILIALNF = P_NOTA.CODFILIAL
               and T.UFDESTINO = P_NOTA.UF;
        end if;
      end if;
      ---------------------------------------------------------------------------------
      -- REGISTRO DE FRETE PELO MENOR CFOP DA NOTA FISCAL
      ---------------------------------------------------------------------------------
      if V_TIPOALIQOUTRASDESP = 'N'
      then
        ---------------------------------------------------------------------------------
        -- ATUALIZAR SE J? EXISTIR CFOP/ALIQUOTA
        update PCNFBASESAID A
           set A.VLDESDOBRADO = A.VLDESDOBRADO ,
               A.VLBASE       = A.VLBASE +
                                DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE),
               A.VLICMS       = NVL(A.VLICMS, 0) +
                                NVL(P_NOTA.VLFRETE, 0) * A.PERCICM / 100,
               A.VLFRETE      = P_NOTA.VLFRETE,
               A.VLBASEFRETE  = DECODE(A.PERCICM, 0, 0, P_NOTA.VLFRETE)
         where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and NVL(A.PERCICM, 0) = DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE)
           and A.CODFISCAL = (select min(CODFISCAL)
                              from PCNFBASESAID
                              where NUMTRANSVENDA = A.NUMTRANSVENDA)
           and ROWNUM = 1;
        ---------------------------------------------------------------------------------
        -- INCLUIR SE N?O EXISTIR CFOP/ALIQUOTA
          if sql%rowcount = 0
          then
            insert into PCNFBASESAID
              (CODFILIALNF,
               NUMTRANSVENDA,
               ESPECIE,
               SERIE,
               SUBSERIE,
               NUMNOTA,
               DTSAIDA,
               DTCANCEL,
               CODCLI,
               PERCICM,
               CLIENTE,
               CGC,
               IE,
               UF,
               UFFILIAL,
               TIPOFJ,
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
               TIPOVENDA,
               BASEST,
               VLST,
               VLBASEIPI,
               VLIPI,
               PERCIPI,
               DTGERA,
               VLREPASSE,
               TIPOREGISTRO,
               VLDESCREDUCAOPIS,
               VLDESCREDUCAOCOFINS)
              select P_NOTA.CODFILIAL,
                     P_NOTA.NUMTRANSVENDA,
                     P_NOTA.ESPECIE,
                     P_NOTA.SERIE,
                     P_NOTA.SUBSERIE,
                     P_NOTA.NUMNOTA,
                     P_NOTA.DTSAIDA,
                     P_NOTA.DTCANCEL,
                     P_NOTA.CODCLI,
                     DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE),
                     P_NOTA.CLIENTE,
                     P_NOTA.CNPJ,
                     P_NOTA.IE,
                     P_NOTA.UF,
                     V_UFFILIAL,
                     P_NOTA.TIPOFJ,
                     P_NOTA.VLTOTAL,
                     P_NOTA.CODCONT,
                     A.CODFISCAL,
                     '090' SITTRIBUT,
                     P_NOTA.CODOPER,
                     DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) VLBASE,
                     0 VLBASENAOTRIB,
                     P_NOTA.VLFRETE,
                     DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) VLBASEFRETE,
  --                   0 VLICMS,
                     ((DECODE(DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE), 0, 0, P_NOTA.VLFRETE) ) * DECODE(V_UFFILIAL, P_NOTA.UF, V_PERCICMFRETE, V_PERCICMINTERFRETE) / 100) AS VLICMS,
                     0 VLISENTAS,
                     0 VLOUTRAS,
                     'FRETE' OBS,
                     P_NOTA.VLFRETE,
                     'F' TIPOVENDA,
                     0 BASEST,
                     0 VLST,
                     0 VLBASEIPI,
                     0 VLIPI,
                     0 PERCIPI,
                     P_NOTA.DTGERA,
                     0 VLREPASSE,
                     'F' TIPOREGISTRO,
                     P_NOTA.VLDESCREDUCAOPIS,
                     P_NOTA.VLDESCREDUCAOCOFINS
                from PCNFBASESAID A
               where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                 and A.NUMNOTA = P_NOTA.NUMNOTA
                 and A.CODFISCAL =
                     (select min(CODFISCAL)
                        from PCNFBASESAID
                       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                         and NUMNOTA = P_NOTA.NUMNOTA)
                 and ROWNUM = 1;
          end if;
          -----------
      -----------------------------------------------------------------------------------------
      -- CORRIGINDO VALOR CONTABIL, OUTRAS OU ISENTAS QUANDO FRETE TRIBUTADO PARA NOTA NÏ ELETRONICA UTILIZANDO PARAMETROS DA 132
      for DADOS in (select M.CODFISCAL,
                           round(sum(M.QTCONT * NVL(M.VLFRETE, 0)),2) VLFRETE
                      from PCMOV M, PCNFSAID S
                     where M.NUMTRANSVENDA = S.NUMTRANSVENDA
                       AND M.NUMNOTA = S.NUMNOTA
                       AND M.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                       AND M.NUMNOTA = P_NOTA.NUMNOTA
             and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                       AND S.DTCANCEL IS NULL
                       AND M.DTCANCEL IS NULL
                       AND M.STATUS in ('A', 'AB')
                       AND M.QTCONT > 0
                       AND NVL(S.CHAVENFE,0) = 0  --- SOMENTE NOTAS DE SA?A NÏ ELETRONICAS
                     GROUP BY M.CODFISCAL)
      loop
        update PCNFBASESAID A
           set VLDESDOBRADO = NVL(VLDESDOBRADO, 0) - DADOS.VLFRETE,
               VLISENTAS    = NVL(VLISENTAS,0) - DECODE(VLISENTAS,0,0,DADOS.VLFRETE),
               VLOUTRAS     = NVL(VLOUTRAS,0) - DECODE(VLOUTRAS,0,0,DADOS.VLFRETE)
         where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFISCAL = DADOS.CODFISCAL
           and NVL(A.VLFRETE,0) = 0;
      end loop;
      -----------------------------------------------------------------------------------------
      end if;
      -----------
    end if;
    -------------------------------------------------------------------------------------------
    -- REGISTRO DE FRETE QUANDO UTILIZA PROCESSO RATEADO
    -------------------------------------------------------------------------------------------
    if V_TRIBUTAFRETERATEADO = 'S'
    then
      for DADOS in (select CODFISCAL,
                           DECODE(NVL(GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(PERCICM, 0)) PERCICM,
                           sum(QTCONT * NVL(VLFRETE_RATEIO, 0)) VLFRETE
                      from PCMOV
                     where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                       and NUMNOTA = P_NOTA.NUMNOTA
             AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                       and DTCANCEL is null
                       and STATUS in ('A', 'AB')
                       and QTCONT > 0
                     group by CODFISCAL,
                              DECODE(NVL(GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(PERCICM, 0)))
      loop
        update PCNFBASESAID A
           set VLDESDOBRADO = NVL(VLDESDOBRADO, 0) + DADOS.VLFRETE,
               VLFRETE      = NVL(VLFRETE, 0) + DADOS.VLFRETE,
               VLBASE       = NVL(VLBASE, 0) +
                              DECODE(DADOS.PERCICM, 0, 0, DADOS.VLFRETE),
               A.VLICMS     = NVL(A.VLICMS, 0) +
                              NVL(DADOS.VLFRETE, 0) * DADOS.PERCICM / 100,
               VLBASEFRETE  = NVL(VLBASEFRETE, 0) +
                              DECODE(DADOS.PERCICM, 0, 0, DADOS.VLFRETE)
         where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and A.NUMNOTA = P_NOTA.NUMNOTA
           and A.CODFISCAL = DADOS.CODFISCAL
           and PERCICM = DADOS.PERCICM
           and ROWNUM = 1;
      end loop;
    end if;
  end;

  /*****************************************************************************************/
  procedure GERAR_INFORMACOES_FINAIS(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'RECALCULANDO VLOUTRAS (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- RECALCULAR VLOUTRAS
    update PCNFBASESAID A
       set VLOUTRAS = GREATEST(NVL(VLDESDOBRADO, 0) - NVL(VLBASE, 0) -
                               NVL(VLISENTAS, 0) - 
                               DECODE(V_NAOGERAR_IPI_VLOUTRAS, 'S', NVL(VLIPI, 0) +
                                      NVL(VLOUTRASIPI, 0), 0) -
                               DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', (NVL(VLST, 0) + NVL(VLFECP,0)), 0), 0)
     where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
       and NUMNOTA = P_NOTA.NUMNOTA;

    -- RECALCULAR CORRIGINDO VLOUTRAS
    update PCNFBASESAID A
       set VLOUTRAS = 0,
           VLISENTAS = VLISENTAS + VLOUTRAS
     where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
       and NUMNOTA = P_NOTA.NUMNOTA
       AND VLISENTAS > 0
       AND VLOUTRAS <= 0.05
       AND (NVL(VLIPI, 0) + NVL(VLST, 0)) > A.VLOUTRAS
       AND (SELECT MIN(ROUND(QTCONT * PUNITCONT,2))
            FROM PCMOV
            WHERE NUMTRANSVENDA = A.NUMTRANSVENDA
      AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
            AND NUMNOTA = A.NUMNOTA
            AND CODFISCAL = A.CODFISCAL
            AND QTCONT > 0
            AND DTCANCEL IS NULL) > 0.05;
    ---------------------------------------------------------------------------------
    V_SQLERRO := 'RECALCULANDO VLOUTRAS (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    ---------------------------------------------------------------------------------
    -- RECALCULAR VLOUTRAS E VLISENTAS COM REDU??O DE BASE DE CALCULO
    update PCNFBASESAID A
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
     where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
       and NUMNOTA = P_NOTA.NUMNOTA
       and VLBASENAOTRIB > 0;
    -------------------------------------------------------------------------------------------
    V_SQLERRO := 'ZERANDO NOTAS CANCELADAS (NOTA ' || P_NOTA.NUMNOTA ||
                 ' EM ' || TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    -------------------------------------------------------------------------------------------
    update PCNFBASESAID A
       set A.VLDESDOBRADO     = 0,
           A.VLTOTAL          = 0,
           A.VLBASE           = 0,
           A.VLICMS           = 0,
           A.VLOUTRAS         = 0,
           A.VLISENTAS        = 0,
           A.VLST             = 0,
           A.BASEST           = 0,
           A.VLBASEIPI        = 0,
           A.VLIPI            = 0,
           A.BCIMPESTADUAL    = 0,
           A.VLIMPESTADUAL    = 0,
           A.VLISENTAS_DAPI   = 0,
           A.VLNAOTRIB_DAPI   = 0,
           A.VLBASERED_DAPI   = 0,
           A.VLSUSPENSAS_DAPI = 0,
           A.VLST_DAPI        = 0,
           A.VLOUTRAS_DAPI    = 0,
           A.VLCOFINS         = 0,
           A.VLPIS            = 0,
           A.PERCICM          = 0,
           A.PERCIPI          = 0,
           A.vloutrasipi      = 0,
           A.VLBASEOUTRASIPI  = 0,
           A.VLICMSDIFERIDO   = 0,
           A.VLICMSNAOTRIB    = 0,
           A.VLFCP            = 0,
           A.VLICMSUFREM      = 0,
           A.VLICMSUFDEST     = 0,
           A.VLICMSDIFALIQPART = 0,
           A.VLBASEPARTDEST   = 0,
           A.VLIPIDEVFORNEC   = 0,
           A.VLACRESCIMOFUNCEP = 0,
           A.VLFECP            = 0,
           A.VLBASEBCR        = 0,
           A.VLSTBCR          = 0,
           A.VLICMSBCR        = 0,
           A.OBS              = DECODE((select count(1)
                                         from PCINUTILIZACAONFE
                                        where CODFILIAL = A.CODFILIALNF
                                          and A.NUMNOTA between
                                              NUMNOTAINICIAL and
                                              NUMNOTAFINAL), 0, DECODE(NVL(P_NOTA.OBS, 'X'), 'X', 'CANCELADA', SUBSTR(P_NOTA.OBS ||
                                                       ' - ' ||
                                                       'CANCELADA', 1, V_TAMANHO_OBS)), A.OBS),
           A.DTCANCEL         = NVL(A.DTCANCEL, DTSAIDA)
     where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
       and NUMNOTA = P_NOTA.NUMNOTA
       and ESPECIE not in ('CF', 'MR')
       and (((A.DTCANCEL is not null) or (P_NOTA.SITUACAONFE = 101)) or
           (A.VLTOTAL = 0 and A.VLBASE = 0 and A.VLISENTAS = 0 and
           A.VLOUTRAS = 0 and A.VLICMS = 0 and A.VLBASEIPI = 0 and
           A.VLIPI = 0 and A.BASEST = 0 and A.VLST = 0 and not exists
            (select NUMTRANS
                from PCCOMPLEMENTO
               where NUMTRANS = A.NUMTRANSVENDA
                 and NOMETABELA = 'PCNFSAID') and
            (CODFISCAL not in (5929, 6929))))
       and (exists (select CODPROD
                      from PCMOV
                     where NUMTRANSVENDA = A.NUMTRANSVENDA
             AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCODFILIAL
                       and NUMNOTA = A.NUMNOTA) or not exists
            (select PCNFBASE.NUMTRANSVENDA
               from PCNFBASE
              where PCNFBASE.NUMTRANSVENDA = A.NUMTRANSVENDA
                and (PCNFBASE.VLBASE > 0 or PCNFBASE.VLISENTAS > 0 or
                    PCNFBASE.VLCONTABIL > 0 or PCNFBASE.VLICMS > 0)));
    -------------------------------------------------------------------------------------------
    -- CORRIGINDO NOTAS FISCAIS DE MANIFESTO/SE
    if (V_UFFILIAL = 'SE') and (P_NOTA.ESPECIE <> 'MR') and
       (NVL(P_NOTA.SERIE, 'X') not in ('CF', 'CP')) and
       (P_NOTA.DTCANCEL is null) and (P_NOTA.CONDVENDA = 13)
    then
      -------------------------------------------------------------------------------------------
      V_SQLERRO := 'CORRIGINDO NOTAS FISCAIS DE MANIFESTO/SE (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
      -------------------------------------------------------------------------------------------
      update PCNFBASESAID A
         set VLOUTRAS  = VLDESDOBRADO,
             VLBASE    = 0,
             VLISENTAS = 0,
             VLICMS    = 0,
             PERCICM   = 0,
             OBS       = 'REM.P/ VENDA FORA ESTABELEC'
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA;
    end if;
    -------------------------------------------------------------------------------------------
    -- ZERANDO IMPOSTOS DAS VENDAS MANIFESTO
    if (P_NOTA.CONDVENDA = 14) and (V_ZERAR_IMPOSTOS_TV14 = 'S')
    then
      -------------------------------------------------------------------------------------------
      V_SQLERRO := 'ZERANDO IMPOSTOS DAS VENDAS MANIFESTO (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
      -------------------------------------------------------------------------------------------
      update PCNFBASESAID A
         set VLOUTRAS         = VLDESDOBRADO,
             BASEST           = 0,
             VLST             = 0,
             VLBASE           = 0,
             VLISENTAS        = 0,
             VLICMS           = 0,
             PERCICM          = 0,
             VLISENTAS_DAPI   = 0,
             VLNAOTRIB_DAPI   = 0,
             VLBASERED_DAPI   = 0,
             VLSUSPENSAS_DAPI = 0,
             VLST_DAPI        = 0,
             VLOUTRAS_DAPI    = 0
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA;
    end if;
    ----------------------------------------------------------------------------
    -- CORRIGIR VLBASE_REDUCAO CONFORME VLISENTAS
    ----------------------------------------------------------------------------
    V_SQLERRO := 'CORRIGINDO VLBASE_REDUCAO (NOTA ' || P_NOTA.NUMNOTA ||
                 ' EM ' || TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    ----------------------------------------------------------------------------
    update PCNFBASESAID
       set VLBASE_REDUCAO = VLISENTAS
     where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
       and NUMNOTA = P_NOTA.NUMNOTA
       and VLBASE_REDUCAO > VLISENTAS;
    ----------------------------------------------------------------------------
    -- ZERANDO NOTAS FISCAL REFERENTE A CUPOM FISCAL
    if (P_NOTA.DTCANCEL is null) and (P_NOTA.CODFISCAL in (5929, 6929)) and
       (vPARAM_GERARICMSLIVFISCFOP = 'N')
    then
      --------------------------------------------------------------------------
      V_SQLERRO := 'ZERANDO NOTAS FISCAL REFERENTE A CUPOM FISCAL (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
      --------------------------------------------------------------------------
      declare
        V_GERARVALORES varchar2(1);
      begin
        begin
          select NVL(CALCVLCONTABILNFCF, 'N')
            into V_GERARVALORES
            from PCESTADO
           where UF = DECODE(vPARAM_GERARVLCONTCFOP, 'S', V_UFFILIAL, P_NOTA.UF);
        exception
          when others then
            V_GERARVALORES := 'N';
        end;
        ------------------------------------------------------------------------
        update PCNFBASESAID A
           set A.VLTOTAL          = DECODE(V_GERARVALORES, 'N', 0, A.VLTOTAL),
               A.VLDESDOBRADO     = DECODE(V_GERARVALORES, 'N', 0, A.VLDESDOBRADO),
               A.PERCICM          = 0,
               A.VLBASE           = 0,
               A.VLICMS           = 0,
               A.VLISENTAS        = 0,
               A.VLOUTRAS         = DECODE(V_GERARVALORES, 'N', 0, A.VLDESDOBRADO),
               A.BASEST           = 0,
               A.VLST             = 0,
               A.VLBASEIPI        = 0,
               A.PERCIPI          = 0,
               A.VLIPI            = 0,
               A.VLISENTAS_DAPI   = 0,
               A.VLNAOTRIB_DAPI   = 0,
               A.VLBASERED_DAPI   = 0,
               A.VLSUSPENSAS_DAPI = 0,
               A.VLST_DAPI        = 0,
               A.VLOUTRAS_DAPI    = 0,
               A.OBS              = 'CF No.' ||
                                    NVL((select TO_CHAR(max(NUMNOTA))
                                          from PCNFSAID
                                         where NUMTRANSVENDA =
                                               P_NOTA.NUMTRANSVENDAORIGEM
                                           and SERIE in ('CF', 'CP')), '0') ||
                                    ' VL.' ||
                                    TO_CHAR(A.VLTOTAL, 'FM99,999,999,990.00')
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      end;
    end if;
    ----------------------------------------------------------------------------
    -- ATRIBUINDO REFERENCIA AS NOTAS MANIFESTO
    if (V_GERAR_REFERENCIA_MANIFESTO = 'S') and (P_NOTA.DTCANCEL is null) and
       (P_NOTA.CONDVENDA in (13, 14))
    then
      if P_NOTA.CONDVENDA = 13
      then
        update PCNFBASESAID N
           set OBS = SUBSTR((select 'NFS VENDA: ' || TO_CHAR(min(NUMNOTA)) ||
                                   ' A ' || TO_CHAR(max(NUMNOTA)) ||
                                   DECODE(min(SERIE), null, ' SEM SERIE', ' SERIE: ' ||
                                           TO_CHAR(min(SERIE)))
                              from PCNFSAID
                             where NUMCAR = P_NOTA.NUMCAR
                               and CONDVENDA = 14
                               and DTCANCEL is null), 1, V_TAMANHO_OBS)
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      else
        ------------------------------------------------------------------------
        update PCNFBASESAID N
           set OBS = SUBSTR((select DECODE(min(NUMNOTA), max(NUMNOTA), 'REF. NF REMESSA: ' ||
                                           TO_CHAR(min(NUMNOTA)), 'REF. NFS REMESSA: ' ||
                                           TO_CHAR(min(NUMNOTA)) ||
                                           ' A ' ||
                                           TO_CHAR(max(NUMNOTA))) || ' DE ' ||
                                   TO_CHAR(min(DTSAIDA), 'DD/MM/YYYY')
                              from PCNFSAID
                             where NUMCAR = P_NOTA.NUMCAR
                               and CONDVENDA = 13
                               and DTCANCEL is null), 1, V_TAMANHO_OBS)
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      end if;
    end if;
    ----------------------------------------------------------------------------
    V_SQLERRO := 'GERANDO REFERENCIA A DEVOLU??O';
    if P_NOTA.TIPOVENDA = 'DF'
    then
      update PCNFBASESAID A
         set OBS = NVL((select max('REF. NF ' || TO_CHAR(N.NUMNOTA) || ' DE ' ||
                                  TO_CHAR(N.DTENT, 'DD/MM/YYYY'))
                         from PCNFENT     N,
                              PCDEVFORNEC E
                        where E.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                          and E.NUMTRANSENT = N.NUMTRANSENT
                          and N.ESPECIE = 'NF'), '') || (case when vPARAM_SOMARIPISTDEVOUTRASDESP = 'S' then
                                                           (select DECODE(nvl(sum(QTCONT * NVL(MC.VLSTOUTRAS, 0)),0), 0, '', 'OBS. VL.ST: ' ||
                                                                          TO_CHAR(sum(QTCONT * NVL(MC.VLSTOUTRAS, 0)), 'FM99,999,999,990.00'))
                                                            from PCMOV       M,
                                                                 PCMOVCOMPLE MC
                                                            where M.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
                                                              and MC.NUMTRANSITEM = M.NUMTRANSITEM
                                and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                                                              and M.DTCANCEL is null
                                                              and M.QTCONT > 0
                                                              and MC.VLSTOUTRAS > 0) else '' end)
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA
         and VLTOTAL > 0;
    end if;
    ----------------------------------------------------------------------------

    V_SQLERRO := 'GERANDO REFERENCIA A BONIFICACAO';
    V_OBS_TEMP := TRIM(REPLACE(REPLACE(REPLACE(UPPER(P_NOTA.OBS), '- BONIFICA??O', '')   ,'Ç', 'C'),'Ã','A'));

    if P_NOTA.CONDVENDA = 5
    then
          IF(INSTR(V_OBS_TEMP, 'BONIFICACAO') = 0) THEN

            update PCNFBASESAID
             set OBS = DECODE(NVL(V_OBS_TEMP, 'X'), 'X', 'BONIFICACAO', SUBSTR(V_OBS_TEMP ||
                                        ' - ' ||
                                    'BONIFICACAO', 1, V_TAMANHO_OBS))
             where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
               and NUMNOTA = P_NOTA.NUMNOTA
               and VLTOTAL > 0;

          ELSE
             update PCNFBASESAID
             set OBS =  V_OBS_TEMP
             where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
               and NUMNOTA = P_NOTA.NUMNOTA
               and VLTOTAL > 0;
         END IF;
    end if;
    ----------------------------------------------------------------------------
    V_SQLERRO := 'RETIRANDO TRIBUTA!O DE ENTREGA FUTURA';
    if (P_NOTA.CONDVENDA = 7)
    then
      if (NVL(V_GERAICMSLIVROFISCALTV7, 'N') = 'N')
      then
        update PCNFBASESAID
           set VLBASE = 0,
               VLICMS = 0,
               PERCICM = 0
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      end if;

      if (NVL(V_GERAICMSLIVROFISCALTV7, 'N') = 'S') and (p_nota.dtcancel is null)
      then
        update PCNFBASESAID
           set OBS = 'Remessa simb??a - Venda a ordem'
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      end if;

      if (NVL(P_NOTA.CONTAORDEM, 'N') = 'S') and (p_nota.dtcancel is null)
      then
        update PCNFBASESAID
           set OBS = 'VENDA POR CONTA E ORDEM'
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      end if;
    end if;

    if (P_NOTA.CONDVENDA = 8) and (p_nota.dtcancel is null)
    then
      if (NVL(P_NOTA.CONTAORDEM, 'N') = 'S')
      then
        update PCNFBASESAID
           set OBS = 'REMESSA POR CONTA E ORDEM'
         where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
           and NUMNOTA = P_NOTA.NUMNOTA;
      end if;
    end if;
    ----------------------------------------------------------------------------
    -- ATRIBUINDO NFS TIPO 14 NA OBSERVA??O. DAS NFS TIPO 13, SE N?O PUDER GERAR 14 NO LIVRO
    if (V_IMPEDETIPO14_LIVROFISCAL = 'S') and (P_NOTA.CONDVENDA = 13) and
       (V_GERAR_REFERENCIA_MANIFESTO = 'N') and (P_NOTA.DTCANCEL is null)
    then
      --------------------------------------------------------------------------
      V_SQLERRO := 'ATRIBUINDO NFS TIPO 14 NA OBSERVA??O. DAS NFS TIPO 13 (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
      --------------------------------------------------------------------------
      update PCNFBASESAID N
         set OBS = SUBSTR('NFS VENDA ' ||
                          NVL((select min(NUMNOTA)
                                from PCNFSAID
                               where NUMCAR = P_NOTA.NUMCAR
                                 and CONDVENDA = 14
                                 and DTCANCEL is null), 0) || ' a ' ||
                          NVL((select max(NUMNOTA)
                                from PCNFSAID
                               where NUMCAR = P_NOTA.NUMCAR
                                 and CONDVENDA = 14
                                 and DTCANCEL is null), 0), 1, V_TAMANHO_OBS)
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA;
    end if;
    ----------------------------------------------------------------------------
    V_SQLERRO := 'GRAVANDO O VALORES RESTANTES EM VLOUTRAS E VLISENTAS - DAPI (NOTA ' ||
                 P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
    ----------------------------------------------------------------------------
    update PCNFBASESAID A
       set VLISENTAS_DAPI = GREATEST(NVL(VLISENTAS, 0) -
                                     NVL(VLNAOTRIB_DAPI, 0) -
                                     NVL(VLBASERED_DAPI, 0), 0),
           VLOUTRAS_DAPI  = GREATEST(NVL(VLOUTRAS, 0) -
                                     NVL(VLSUSPENSAS_DAPI, 0) -
                                     DECODE(V_NAOGERAR_ST_VLOUTRAS, 'S', 0, NVL(VLST, 0)), 0)
     where A.NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
       and A.NUMNOTA = P_NOTA.NUMNOTA
       and (A.VLOUTRAS > 0 or A.VLISENTAS > 0);

    ----------------------------------------------------------------------------
    -- ZERANDO VLCONT?BIL QUANDO CFOP DE AQUISI??O DE BENS PARA REVENDA (5117 e 6117)
    if ((P_NOTA.CODFISCAL in (5117, 6117))
    and (vPARAM_GERALIVRO_VLCONTZERADO = 'S'))
    then
      --------------------------------------------------------------------------
      V_SQLERRO := 'ZERANDO VLCONTABIL QUANDO CFOP DE AQUISICAO DE BENS PARA REVENDA (5117 e 6117)
                    E MARCADO PARAMETRO GERALIVRO_VLCONTABILZERADO NA ROTINA 132 (NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
      --------------------------------------------------------------------------
      update PCNFBASESAID
         set VLDESDOBRADO = 0,
               VLTOTAL = 0
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA
         and CODFISCAL in (5117, 6117);
    end if;
    ----------------------------------------------------------------------------
    -- ZERANDO ICMS QUANDO CFOP DE OUTRAS OPERACOES COM DIREITO A CREDITO (5922 e 6922)
    if ((P_NOTA.CODFISCAL in (5922, 6922))
  and (vPARAM_GERALIVRO_VLCONTZERADO = 'S'))
    then
      --------------------------------------------------------------------------
      V_SQLERRO := 'ZERANDO ICMS QUANDO CFOP DE OUTRAS OPERACOES COM DIREITO A CREDITO (5922 e 6922)
                    E MARCADO PARAMETRO GERALIVRO_VLCONTABILZERADO NA ROTINA 132(NOTA ' ||
                   P_NOTA.NUMNOTA || ' EM ' ||
                   TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
      --------------------------------------------------------------------------
      update PCNFBASESAID
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
       where NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
         and NUMNOTA = P_NOTA.NUMNOTA
         and CODFISCAL in (5922, 6922);
    end if;
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- ZERAR VALORES SITUACAONFE 102
    if P_NOTA.SITUACAONFE = 102 then
    ----------------------------------------------------------------------------
    V_SQLERRO := 'ZERANDO VALORES PARA NFE COM SITUA??O 102(INUTILIZADA) NOTA:'
                 || P_NOTA.NUMNOTA ||' EM '|| TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY')||')';
    ----------------------------------------------------------------------------
    update PCNFBASESAID A
       set A.VLDESDOBRADO     = 0,
           A.VLTOTAL          = 0,
           A.VLBASE           = 0,
           A.VLICMS           = 0,
           A.VLOUTRAS         = 0,
           A.VLISENTAS        = 0,
           A.VLST             = 0,
           A.BASEST           = 0,
           A.VLBASEIPI        = 0,
           A.VLIPI            = 0,
           A.BCIMPESTADUAL    = 0,
           A.VLIMPESTADUAL    = 0,
           A.VLISENTAS_DAPI   = 0,
           A.VLNAOTRIB_DAPI   = 0,
           A.VLBASERED_DAPI   = 0,
           A.VLSUSPENSAS_DAPI = 0,
           A.VLST_DAPI        = 0,
           A.VLOUTRAS_DAPI    = 0,
           A.VLCOFINS         = 0,
           A.VLPIS            = 0,
           A.PERCICM          = 0,
           A.PERCIPI          = 0,
           A.vloutrasipi      = 0,
           A.VLBASEOUTRASIPI  = 0,
           A.VLICMSNAOTRIB    = 0,
           A.VLFCP            = 0,
           A.VLICMSUFREM      = 0,
           A.VLICMSUFDEST     = 0,
           A.VLICMSDIFALIQPART = 0,
           A.VLIPIDEVFORNEC   = 0,
           A.VLBASEBCR        = 0,
           A.VLSTBCR          = 0,
           A.VLICMSBCR        = 0
       where A.NUMTRANSVENDA  = P_NOTA.NUMTRANSVENDA
         and A.NUMNOTA        = P_NOTA.NUMNOTA;
         END IF;
    ----------------------------------------------------------------------------
  end;

  procedure VALIDAR_LIVROFISCAL is
  begin
    begin
      V_SQLERRO := 'DELETANDO BACKUPS';
      --------------------------------------------------------------------------
      for DADOS in (select distinct TABLE_NAME
                      from USER_TAB_COLS
                     where TABLE_NAME like 'PCNFBASESAID_%')
      loop
        execute immediate 'DROP TABLE ' || DADOS.TABLE_NAME;
      end loop;
    exception
      when others then
        null;
    end;
    V_SQLERRO := 'VALIDANDO A GERA??O DO LIVRO FISCAL';
    ----------------------------------------------------------------------------
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

  procedure CORRIGIR_ICMS_CUPONS is
    V_ROWID_ANT      varchar2(100);
    V_CAIXA          number;
    V_DTSAIDA        date;
    V_VLICMS         number;
    V_VLBASE_TOTAL   number;
    V_VLICMS_TOTAL   number;
    V_VLICMS_REDUCAO number;
    V_VLBASE_REDUCAO number;
  begin
    V_ROWID_ANT      := '-1';
    V_CAIXA          := -1;
    V_DTSAIDA        := TRUNC(sysdate) + 1;
    V_VLICMS_REDUCAO := 0;
    V_VLICMS_TOTAL   := 0;
    V_VLBASE_TOTAL   := 0;
    V_VLBASE_REDUCAO := 0;
    ----------------------------------------------------------------------------
    for DADOS in (select L.rowid IDREGISTRO,
                         NVL(N.CAIXA, 0) CAIXA,
                         L.DTSAIDA,
                         L.VLBASE,
                         L.VLICMS
                    from PCNFBASESAID L,
                         PCNFSAID     N
                   where N.NUMTRANSVENDA = L.NUMTRANSVENDA
                     and N.ESPECIE in ('NF', 'CP')
                     and N.SERIE in ('CF', 'CP')
                     and L.CODFILIALNF = PCODFILIAL
                     and L.DTSAIDA between DATA1 and DATA2
                   order by DTSAIDA,
                            CAIXA,
                            VLBASE,
                            VLICMS)
    loop
      if ((V_CAIXA <> DADOS.CAIXA) or (V_DTSAIDA <> DADOS.DTSAIDA))
      then
        if V_CAIXA >= 0
        then
          begin
            select sum(VLICMS),
                   sum(VLBASE)
              into V_VLICMS_REDUCAO,
                   V_VLBASE_REDUCAO
              from PCNFBASESAID
             where ESPECIE = 'CF'
               and SERIE = 'ECF'
               and CODCLI = V_CAIXA
               and DTSAIDA = V_DTSAIDA;
          exception
            when others then
              V_VLICMS_REDUCAO := 0;
              V_VLBASE_REDUCAO := 0;
          end;
          ----------------------------------------------------------------------
          if ABS(V_VLBASE_REDUCAO - V_VLBASE_TOTAL) <= 0.07
          then
            V_VLICMS := V_VLICMS - (V_VLICMS_TOTAL - V_VLICMS_REDUCAO);
          end if;
          ----------------------------------------------------------------------
          V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
          update PCNFBASESAID
             set VLICMS = V_VLICMS
           where rowid = V_ROWID_ANT;
        end if;
        V_CAIXA        := DADOS.CAIXA;
        V_DTSAIDA      := DADOS.DTSAIDA;
        V_VLICMS_TOTAL := 0;
        V_VLBASE_TOTAL := 0;
      end if;
      V_VLICMS       := DADOS.VLICMS;
      V_VLBASE_TOTAL := V_VLBASE_TOTAL + DADOS.VLBASE;
      V_VLICMS_TOTAL := V_VLICMS_TOTAL + DADOS.VLICMS;
      V_ROWID_ANT    := DADOS.IDREGISTRO;

      IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
        V_CONTADORREGISTRO := 0;
        COMMIT;
      END IF;
    end loop;
    ----------------------------------------------------------------------------
    begin
      select sum(VLICMS),
             sum(VLBASE)
        into V_VLICMS_REDUCAO,
             V_VLBASE_REDUCAO
        from PCNFBASESAID
       where ESPECIE = 'CF'
         and SERIE = 'ECF'
         and CODCLI = V_CAIXA
         and DTSAIDA = V_DTSAIDA;
    exception
      when others then
        V_VLICMS_REDUCAO := 0;
        V_VLBASE_REDUCAO := 0;
    end;
    ----------------------------------------------------------------------------
    if ABS(V_VLBASE_REDUCAO - V_VLBASE_TOTAL) <= 0.07
    then
      V_VLICMS := V_VLICMS - (V_VLICMS_TOTAL - V_VLICMS_REDUCAO);
    end if;
    ----------------------------------------------------------------------------
    if V_ROWID_ANT <> '-1'
    then
      update PCNFBASESAID set VLICMS = V_VLICMS where rowid = V_ROWID_ANT;
    end if;
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
       'S',
       PCODFILIAL,
       DATA1,
       DATA2,
       sysdate,
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'OS_USER'));
    ----------------------------------------------------------------------------
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

  procedure CONFIGURAR_DESPESA_FRETE(P_NOTA in C_NOTAS_NF%rowtype) is
  begin
    --Cupom SAT (SERIE = 'SF') nao deve entrar na regra, assim como NFe, NFCe.
    if ((P_NOTA.CHAVENFE is null) and (P_NOTA.SERIE <> 'SF')) or (P_NOTA.DTSAIDA < V_DATA_INICIO_NFE20)
    then
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
    else
      if ((P_NOTA.VLFRETE > 0) or (P_NOTA.VLOUTRASDESP > 0)) AND
          P_NOTA.TIPOVENDA = 'DF' then
        GERAR_DESPESA_FRETE_NFE(P_NOTA);
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
  
-------------------------------------------------------------------------------- 
PROCEDURE INSERIR_NF_CONTABILIZADA(P_NOTA IN C_NOTAS_NF%ROWTYPE) IS
BEGIN
  ---------------------------------------------------------------------------------
    V_SQLERRO := 'INSERINDO OU ATUALIZANDO REGISTRO (NOTA ' || P_NOTA.NUMNOTA || ' EM ' ||
                 TO_CHAR(P_NOTA.DTSAIDA, 'DD/MM/YYYY') || ')';
  ---------------------------------------------------------------------------------
    UPDATE PCMOVTEMP
    SET DATASAI = P_NOTA.DTSAIDA,
        NUMNOTA = P_NOTA.NUMNOTA
    WHERE CODFILIAL = P_NOTA.CODFILIAL
      AND NUMTRANSVENDA = P_NOTA.NUMTRANSVENDA
      AND DATASAI = P_NOTA.DTSAIDA
      AND NUMNOTA  = P_NOTA.NUMNOTA
      AND TIPOREGISTRO = 'NF_CONTABS';

    IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO PCMOVTEMP
          (CODFILIAL,
           NUMTRANSVENDA,
           DATASAI,
           NUMNOTA,
           TIPOREGISTRO
           )
        VALUES
          (P_NOTA.CODFILIAL,
           P_NOTA.NUMTRANSVENDA,
           P_NOTA.DTSAIDA,
           P_NOTA.NUMNOTA,
           'NF_CONTABS');
    END IF;
END;  
--------------------------------------------------------------------------------  
FUNCTION VALIDAR_NF_CONTABILIZADA(P_NOTA IN C_NOTAS_NF%ROWTYPE) RETURN BOOLEAN IS 
BEGIN
  BEGIN
    SELECT 1 INTO V_NF_CONTABILIZADA           
           FROM PCLANCINTERMEDIARIA L                   
        WHERE L.DATALANCTO = P_NOTA.DTSAIDA                      
         AND L.NUMTRANSOPERACAO = P_NOTA.NUMTRANSVENDA            
         AND L.CODFILIAL = P_NOTA.CODFILIAL                   
         AND L.CODREGRA IN (SELECT CODREGRA FROM PCREGRACONTABIL WHERE CODFATOGERADOR = '2')
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

--------------------------------------------------------------------------------
  procedure GERALIVRO_FISCAL(V_LISTA_NOTAS IN OUT  LISTA_NOTAS) IS
  BEGIN
    V_LISTA_NOTAS_TEMP.NUMTRANSVENDA := -1;
    V_LISTA_NOTAS_TEMP.NUMNOTA       := -1;
    V_LISTA_NOTAS_TEMP.VLOUTRASDESP  := 0;
    V_LISTA_NOTAS_TEMP.VLFRETE       := 0;
    V_NF_CONTABILIZADA               := 0;
    V_NUMNOTA                        := 0;
    V_NUMTRANSVENDA                  := 0;    
    
    for I in 1 .. V_LISTA_NOTAS.count
    loop
       IF vPARAM_VALIDA_NF_CONTABILIZADA = 'S' THEN
        -- VALIDA SE A NF ESTA CONTABILIZADA NO MODULO CONTABIL
        IF VALIDAR_NF_CONTABILIZADA(V_LISTA_NOTAS(I)) THEN
           -- INSERIR REGISTRO PCMOVTEMP      
           INSERIR_NF_CONTABILIZADA(V_LISTA_NOTAS(I));
           V_NF_CONTABILIZADA:= 1;
        ELSE
           --DELETA LIVRO DA NF
           IF V_NUMNOTA <> V_LISTA_NOTAS(I).NUMNOTA OR
              V_NUMTRANSVENDA <> V_LISTA_NOTAS(I).NUMTRANSVENDA THEN
                DELETAR_REGISTROS_PCNFBASESAID(V_LISTA_NOTAS(I).DATA,
                                                V_LISTA_NOTAS(I).DATA,
                                                V_LISTA_NOTAS(I).CODFILIAL,
                                                V_LISTA_NOTAS(I).NUMNOTA,
                                                V_LISTA_NOTAS(I).NUMNOTA,
                                                V_LISTA_NOTAS(I).NUMTRANSVENDA); 
            END IF;                                     
           V_NF_CONTABILIZADA:= 0;    
        END IF;
        V_NUMNOTA       := V_LISTA_NOTAS(I).NUMNOTA;
        V_NUMTRANSVENDA := V_LISTA_NOTAS(I).NUMTRANSVENDA;
      END IF;
      IF V_NF_CONTABILIZADA = 0 THEN 
      -- CONDICIONAL CRIADA PARA NÏ GERAR O LIVRO PARA ESPECIE = NS, POR? A MESMA PRECISA TER A CONTA CONTABIL GERADA MAIS A BAIXO.
      IF ((V_LISTA_NOTAS(I).ESPECIE = 'NS') OR ((V_IMPEDETIPO14_LIVROFISCAL = 'S') AND (V_LISTA_NOTAS(I).CONDVENDA = 14))) THEN
         FISCAL.GERA_CONTAS_CONTABEIS_SPED(V_LISTA_NOTAS(I).CODFILIAL,
                                           V_LISTA_NOTAS(I).DATA,
                                           V_LISTA_NOTAS(I).DATA,
                                           V_LISTA_NOTAS(I).NUMTRANSVENDA,
                                           'S');
      ELSE
        -- INSERIR REGISTRO DA NOTA FISCAL
        INSERIR_REGISTRO_NOTA(V_LISTA_NOTAS(I));
        ---------------------------------------------------------------------------
        -- GERAR DESPESA ACESSORIA OU FRETE SE FOR O CASO
        IF (V_LISTA_NOTAS_TEMP.NUMTRANSVENDA <> V_LISTA_NOTAS(I).NUMTRANSVENDA) OR
           (V_LISTA_NOTAS_TEMP.NUMNOTA <> V_LISTA_NOTAS(I).NUMNOTA) then
        -- Caso necess?o retornar esse metodo procurar Pedro Soares - Solic 5043.130169.2017
        /*CONFIGURAR_DESPESA_FRETE(V_LISTA_NOTAS(I));
          GERAR_INFORMACOES_FINAIS(V_LISTA_NOTAS(I));*/

           CONFIGURAR_DESPESA_FRETE(V_LISTA_NOTAS_TEMP);
           GERAR_INFORMACOES_FINAIS(V_LISTA_NOTAS_TEMP);

           V_LISTA_NOTAS_TEMP := V_LISTA_NOTAS(I);
        end if;
        ---------------------------------------------------------------------------
        -- GERAR INFORMA??ES FINAIS (RECALCULO E ATRIBUI??ES DA LEGISLA??O)
        ---------------------------------------------------------------------------
        /* Replica? realizada no final da gera? do livro fiscal. N desconsiderar esse c??o
        FISCAL.GERA_CONTAS_CONTABEIS_SPED(V_LISTA_NOTAS(I).CODFILIAL,
                                          V_LISTA_NOTAS(I).DATA,
                                          V_LISTA_NOTAS(I).DATA,
                                          V_LISTA_NOTAS(I).NUMTRANSVENDA,
                                          'S');
        -----------------------------------------------
        --ATUALIZA NATUREZA DE RECEITA PARA MODELO 65 -
        -----------------------------------------------
        IF (NVL(SUBSTR(V_LISTA_NOTAS(I).CHAVENFE, 21,2),'XX') = '65')  THEN
           FISCAL.GERA_NATUREZA_RECEITA(V_LISTA_NOTAS(I).CODFILIAL,
                                        V_LISTA_NOTAS(I).DATA,
                                        V_LISTA_NOTAS(I).DATA,
                                        V_LISTA_NOTAS(I).NUMTRANSVENDA,
                                        'N');
        END IF;
        */

        V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
        IF V_CONTADORREGISTRO >= V_QUANTIDADECOMMIT THEN
          V_CONTADORREGISTRO := 0;
          COMMIT;
        END IF;
      END IF;
      END IF;
    END LOOP;
    IF V_NF_CONTABILIZADA = 0 THEN 
      CONFIGURAR_DESPESA_FRETE(V_LISTA_NOTAS_TEMP);
      GERAR_INFORMACOES_FINAIS(V_LISTA_NOTAS_TEMP);
    END IF;
  END;

  PROCEDURE PREENCHER_PARAMETROS IS
  BEGIN
    SELECT
          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARICMSLIVFISCFOP', PCODFILIAL), 'N'),
          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_REGRAARREDONDAMENTOECF', PCODFILIAL), 'X'),
          NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARVLCONTCFOP', PCODFILIAL), 'N'),
          PARAMFILIAL.OBTERCOMOVARCHAR2('SOMARIPISTDEVOLUCAOOUTRASDESP', PCODFILIAL),
          PARAMFILIAL.OBTERCOMOVARCHAR2('GERALIVRO_VLCONTABILZERADO', PCODFILIAL),
          PARAMFILIAL.OBTERCOMOVARCHAR2('RECALCULARBASEICMSDIFERIDO', PCODFILIAL),
          PARAMFILIAL.OBTERCOMOVARCHAR2('BLOQCONTABILCANCALTNOTAFISCAL')
     INTO
          vPARAM_GERARICMSLIVFISCFOP,
          vPARAM_FIL_REGRAARREDONDAECF,
          vPARAM_GERARVLCONTCFOP,
          vPARAM_SOMARIPISTDEVOUTRASDESP,
          vPARAM_GERALIVRO_VLCONTZERADO,
          vPARAM_RECALCBASEICMSDIFERIDO,
          vPARAM_VALIDA_NF_CONTABILIZADA
     FROM DUAL;
  END;


  PROCEDURE CODCONTASPED_NOTA_SEM_ITEM IS
    CURSOR CR_DADOS_PCNFBASE IS
            SELECT 'S' TIPO,--SA?A
                   S.DTSAIDA DATA,
                   S.ESPECIE,
                   NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIAL,
                   S.NUMTRANSVENDA TRANSACAO,
                   B.CODFISCAL CFOP,
                   P.CODTRIBPISCOFINS CST,
                   P.NUMTRANSPISCOFINS
              FROM PCNFSAID S,
                   PCNFBASE B,
                   PCNFENTPISCOFINS P
             WHERE S.NUMTRANSVENDA     = B.NUMTRANSVENDA
               AND B.NUMTRANSPISCOFINS = P.NUMTRANSPISCOFINS(+)
               AND S.DTSAIDA BETWEEN DATA1 AND DATA2
               AND S.NUMNOTA BETWEEN NUMNOTA1 AND NUMNOTA2
               AND NVL(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
               AND S.ESPECIE <> 'OE'
               AND NVL(B.CODFISCAL,0) > 0
               AND CASE S.ESPECIE
                        WHEN 'NF' THEN (SELECT COUNT(1)
                                          FROM PCMOV M,
                                               PCMOVCOMPLE MC
                                         WHERE M.NUMTRANSVENDA = S.NUMTRANSVENDA
                                           AND M.NUMNOTA = S.NUMNOTA
                                           AND M.NUMTRANSITEM = MC.NUMTRANSITEM
                                           AND NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                       AND M.DTMOV BETWEEN DATA1 AND DATA2)
                        ELSE 0
                   END = 0;
  BEGIN
    FOR DADOS IN CR_DADOS_PCNFBASE
    LOOP

        FISCAL.GERA_CONTAS_CONTABEIS_SPED(DADOS.CODFILIAL,
                                          DADOS.DATA,
                                          DADOS.DATA,
                                          DADOS.TRANSACAO,
                                          'S');

   END LOOP;
  END;
--------------------------------------------------------------------------------
  procedure PROCESSAR_LIVRO(NUMNOTA1 IN NUMBER,
                            NUMNOTA2 IN NUMBER,
                            DATA1 IN DATE,
                            DATA2 IN DATE,
                            V_INSERIRCF in varchar2,
                            PCODFILIAL IN VARCHAR2,
                            PPROCESSOPORNOTA  IN VARCHAR2) IS
  BEGIN

  open C_NOTAS_NF(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch c_notas_Nf bulk collect
  into LISTA_NOTAS_NF;
  close C_NOTAS_NF;
  GERALIVRO_FISCAL(LISTA_NOTAS_NF);

    IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  IF F_NOTAS_SAT(DATA1,DATA2,PCODFILIAL,NUMNOTA1,NUMNOTA2) then

     open C_NOTAS_SAT(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
     fetch c_notas_SAT bulk collect
     into LISTA_NOTAS_SAT;
     close C_NOTAS_SAT;
     GERALIVRO_FISCAL(LISTA_NOTAS_SAT);

     IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
        COMMIT;
        V_CONTADORREGISTRO := 0;
        RETURN;
     END IF;

     IF V_CONTADORREGISTRO > 0 THEN
        COMMIT;
        V_CONTADORREGISTRO := 0;
     END IF;
  END IF;

  ---------------------------------------------------------------------------------
  IF F_NOTAS_MFE(DATA1,DATA2,PCODFILIAL,NUMNOTA1,NUMNOTA2) then

      open C_NOTAS_MFE(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
      fetch c_notas_MFE bulk collect
      into LISTA_NOTAS_MFE;
      close C_NOTAS_MFE;
      GERALIVRO_FISCAL(LISTA_NOTAS_MFE);

        IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
         COMMIT;
         V_CONTADORREGISTRO := 0;
         RETURN;
      END IF;

      IF V_CONTADORREGISTRO > 0 THEN
         COMMIT;
         V_CONTADORREGISTRO := 0;
      END IF;
   END IF;
  ---------------------------------------------------------------------------------
  
  open C_NOTAS_NFCE(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch c_notas_NfCE bulk collect
  into LISTA_NOTAS_NFCE;
  close C_NOTAS_NFCE;
  GERALIVRO_FISCAL(LISTA_NOTAS_NFCE);

  IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;


  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  
  ---------------------------------------------------------------------------------
  IF F_NOTAS_CUPOM_FISCAL(DATA1,DATA2,PCODFILIAL,NUMNOTA1,NUMNOTA2, V_INSERIRCF) then
  
      open C_NOTAS_CUPOM_FISCAL(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
      fetch C_NOTAS_CUPOM_FISCAL bulk collect
      into LISTA_NOTAS_CUPOM_FISCAL;
      close C_NOTAS_CUPOM_FISCAL;
      GERALIVRO_FISCAL(LISTA_NOTAS_CUPOM_FISCAL);
    
    
      IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
         COMMIT;
         V_CONTADORREGISTRO := 0;
         RETURN;
      END IF;
    
      IF V_CONTADORREGISTRO > 0 THEN
         COMMIT;
         V_CONTADORREGISTRO := 0;
      END IF;
      
  END IF;
  ---------------------------------------------------------------------------------
  IF F_NOTAS_DEV_FORNEC(DATA1,DATA2,PCODFILIAL,NUMNOTA1,NUMNOTA2, V_INSERIRCF) then

    open C_NOTAS_DEV_FORNEC(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
    fetch C_NOTAS_DEV_FORNEC bulk collect
    into LISTA_NOTAS_DEV_FORNEC;
    close C_NOTAS_DEV_FORNEC;
    GERALIVRO_FISCAL(LISTA_NOTAS_DEV_FORNEC);

    IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
       COMMIT;
       V_CONTADORREGISTRO := 0;
       RETURN;
    END IF;


    IF V_CONTADORREGISTRO > 0 THEN
       COMMIT;
       V_CONTADORREGISTRO := 0;
    END IF;

  end if;

  ---------------------------------------------------------------------------------
  open C_NOTAS_SEM_ITENS_E_FRETE(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch C_NOTAS_SEM_ITENS_E_FRETE bulk collect
  into LISTA_NOTAS_SEM_ITENS_E_FRETE;
  close C_NOTAS_SEM_ITENS_E_FRETE;
  GERALIVRO_FISCAL(LISTA_NOTAS_SEM_ITENS_E_FRETE);

  IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;


  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  open C_NOTAS_REDZ_TRIBUT(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch C_NOTAS_REDZ_TRIBUT bulk collect
  into LISTA_NOTAS_REDZ_TRIB;
  close C_NOTAS_REDZ_TRIBUT;
  GERALIVRO_FISCAL(LISTA_NOTAS_REDZ_TRIB);

  IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;


  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  open C_NOTAS_REDZ_CANC(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch C_NOTAS_REDZ_CANC bulk collect
  into LISTA_NOTAS_REDZ_CANC;
  close C_NOTAS_REDZ_CANC;
  GERALIVRO_FISCAL(LISTA_NOTAS_REDZ_CANC);

  IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;


  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  open C_NOTAS_REDZ_N_TRIB(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch C_NOTAS_REDZ_N_TRIB bulk collect
  into LISTA_NOTAS_REDZ_N_TRIB;
  close C_NOTAS_REDZ_N_TRIB;
  GERALIVRO_FISCAL(LISTA_NOTAS_REDZ_N_TRIB);


  IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  open C_NOTAS_COMPLEMETAR_COM_ITEM(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL);
  fetch C_NOTAS_COMPLEMETAR_COM_ITEM bulk collect
  into LISTA_NOTAS_COMPLEMENTAR_ITEM;
  close C_NOTAS_COMPLEMETAR_COM_ITEM;
  GERALIVRO_FISCAL(LISTA_NOTAS_COMPLEMENTAR_ITEM);


  IF (PPROCESSOPORNOTA = 'S' AND V_CONTADORREGISTRO > 0)  THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
     RETURN;
  END IF;

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
 END;
   
begin
  /* Apenas descomente caso necessario gerar tracer da geracao */
  -- ATIVAR_SESSAO;
  --****************************************************************************
  VALIDAR_LIVROFISCAL();
  ------------------------------------------------------------------------------
  -- VALIDANDO SE FALTA REDU??ES Z NO PER?ODO
  IF F_VALIDAR_REDUCOES_PERIODO(DATA1,DATA2,PCODFILIAL,NUMNOTA1,NUMNOTA2, V_INSERIRCF) then
     VALIDAR_REDUCOES_PERIODO();
  END IF; 
  ------------------------------------------------------------------------------
  V_CONTADORREGISTRO := 0;
  V_QUANTIDADECOMMIT := 500;

  --PROCEDURE RESPONSÁVEL POR PREENCHER OS PARAMETROS USADOS NAS INSTRUUES SQL.
  PREENCHER_PARAMETROS();

  V_SQLERRO := 'RECUPERANDO PAR?METROS GERAIS (PCCONSUM)';
  select C.INSERIRCUPOM,
         NVL(C.REDUCAOBCISENTA, 'N'),
         NVL(C.CODFISCALOUTRASDESP, 5949),
         C.SIGLAESPECIE,
         C.SIGLASERIE,
         C.INSERIRREDUCAOZ,
         C.LIMITEARREDONDAMENTO,
         C.INSERIRMAPA,
         NVL(C.CODFISCALINTEROUTRASDESP, 6949),
         NVL(C.ALIQICMOUTRASDESP, 0),
         NVL(C.ALIQICMINTEROUTRASDESP, 0),
         NVL(C.PERCICMFRETE, 0),
         NVL(C.CODFISCALFRETE, 5949),
         NVL(C.PERCICMINTERFRETE, 0),
         NVL(C.CODFISCALINTERFRETE, 6949),
         C.CFOP5929ISENTO,
         C.TIPOALIQOUTRASDESP,
         C.CONSIDERAISENTOSCOMOPF,
         NVL(C.TRIBUTAFRETERATEADO, 'N'),
         PARAMFILIAL.OBTERCOMOVARCHAR2('GERARREFMANIFESTO', PCODFILIAL),
         PARAMFILIAL.OBTERCOMOVARCHAR2('ZERAIMPOSTOSLIVROTV14', PCODFILIAL),
         PARAMFILIAL.OBTERCOMOVARCHAR2('CONSCALCCREDIPIDANFE', PCODFILIAL),
         PARAMFILIAL.OBTERCOMOVARCHAR2('GERAICMSLIVROFISCALTV7', PCODFILIAL),
         PARAMFILIAL.OBTERCOMOVARCHAR2('VLOUTRASIPI_SEMIPI', PCODFILIAL),
         PARAMFILIAL.OBTERCOMOVARCHAR2('GERAINFFISCAISDTENTREGADTSAIDA',PCODFILIAL)
    into V_INSERIRCF,
         V_REDUCAOISENTA,
         V_CODFISCALOUTRASDESP,
         V_ESPECIE,
         V_SERIE,
         V_INSERIRREDZ,
         V_LIMITE,
         V_INSERIRMAPA,
         V_CODFISCALINTEROUTRASDESP,
         V_ALIQICMOUTRASDESP,
         V_ALIQICMINTEROUTRASDESP,
         V_PERCICMFRETE,
         V_CODFISCALFRETE,
         V_PERCICMINTERFRETE,
         V_CODFISCALINTERFRETE,
         V_CFOP5929,
         V_TIPOALIQOUTRASDESP,
         V_CONSIDERAISENTOSCOMOPF,
         V_TRIBUTAFRETERATEADO,
         V_GERAR_REFERENCIA_MANIFESTO,
         V_ZERAR_IMPOSTOS_TV14,
         V_CONSCALCCREDIPIDANFE,
         V_GERAICMSLIVROFISCALTV7,
         V_VALIDA_VALOR_OUTRAS_IPI,
         vnGeraDTENTREGA
    from PCCONSUM C;
  -------------------------------------------------------------------------------------------
  V_SQLERRO := 'RECUPERANDO ALIQUOTA ECF PARA ST';
  begin
    select NVL(max(CODFISCAL), 5405)
      into V_CFOP_ST
      from PCALIQUOTACF
     where SIGLA = 'F';
  end;
  -------------------------------------------------------------------------------------------
  V_SQLERRO := 'RECUPERANDO PARAMETROS POR FILIAL (PCFILIAL)';
  if V_TIPOALIQOUTRASDESP = 'F'
  then
    select NVL(F.CODFISCALOUTRASDESP, 5949),
           NVL(F.CODFISCALINTEROUTRASDESP, 6949),
           NVL(F.ALIQICMOUTRASDESP, 0),
           NVL(F.ALIQICMINTEROUTRASDESP, 0),
           UF,
           NVL(IPISOMENTEVLCONT, 'N'),
           NVL(STSOMENTEVLCONT, 'N'),
           NVL(GERABASENORMALQUANDOST, 'S'),
           NVL(INDUSTRIA, 'N'),
           NVL(IMPEDETIPO14_LIVROFISCAL, 'N'),
           NVL(ARREDVLITENSNFSAIDA, 'S')
      into V_CODFISCALOUTRASDESP,
           V_CODFISCALINTEROUTRASDESP,
           V_ALIQICMOUTRASDESP,
           V_ALIQICMINTEROUTRASDESP,
           V_UFFILIAL,
           V_NAOGERAR_IPI_VLOUTRAS,
           V_NAOGERAR_ST_VLOUTRAS,
           V_GERABASENORMALQUANDOST,
           V_INDUSTRIA,
           V_IMPEDETIPO14_LIVROFISCAL,
           V_ARREDVLITENSNFSAIDA
      from PCFILIAL F
     where F.CODIGO = PCODFILIAL;
  else
    select UF,
           NVL(IPISOMENTEVLCONT, 'N'),
           NVL(STSOMENTEVLCONT, 'N'),
           NVL(GERABASENORMALQUANDOST, 'S'),
           NVL(INDUSTRIA, 'N'),
           NVL(IMPEDETIPO14_LIVROFISCAL, 'N'),
           NVL(ARREDVLITENSNFSAIDA, 'S')
      into V_UFFILIAL,
           V_NAOGERAR_IPI_VLOUTRAS,
           V_NAOGERAR_ST_VLOUTRAS,
           V_GERABASENORMALQUANDOST,
           V_INDUSTRIA,
           V_IMPEDETIPO14_LIVROFISCAL,
           V_ARREDVLITENSNFSAIDA
      from PCFILIAL F
     where F.CODIGO = PCODFILIAL;
  end if;
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'DEFININDO O TAMANHO DO CAMPO OBS';
  begin
    select T.DATA_LENGTH
      into V_TAMANHO_OBS
      from USER_TAB_COLS T
     where T.TABLE_NAME = 'PCNFBASESAID'
       and T.COLUMN_NAME = 'OBS';
  exception
    when others then
      V_TAMANHO_OBS := 60;
  end;
  -------------------------------------------------------------------------------------------
  V_SQLERRO := 'VALIDANDO TRIBUTA??ES POR ESTADO (PCTRIBOUTROS)';
  if V_TIPOALIQOUTRASDESP = 'T'
  then
    select count(1) QTNF
      into V_REGISTROPCNFSAID
      from PCNFSAID
     where NVL(CODFILIALNF, CODFILIAL) = PCODFILIAL
       and DTSAIDA between DATA1 and DATA2
       and ROWNUM = 1;
    if V_REGISTROPCNFSAID > 0
    then
      for DADOS in (select count(1) QTDETRIB
                      from PCTRIBOUTROS A,
                           PCCLIENT     B,
                           PCNFSAID     C
                     where A.UFDESTINO = B.ESTENT
                       and A.CODFILIALNF = NVL(C.CODFILIALNF, C.CODFILIAL)
                       and B.CODCLI = C.CODCLI
                       and NVL(C.CODFILIALNF, C.CODFILIAL) = PCODFILIAL
                       and C.DTSAIDA between DATA1 and DATA2)
      loop
        if DADOS.QTDETRIB = 0
        then
          V_SQLERRO := 'VERIFICANDO A FALTA DE TRIBUTA??ES POR ESTADO: ' ||
                       CHR(13) ||
                       'FALTA CADASTRO DE TRIBUTA??O PARA ALGUM ESTADO NA ROTINA 596. ? NECESS?RIO QUE EXISTA UMA ' ||
                       CHR(13) ||
                       'TRIBUTA??O PARA CADA UF QUANDO O PARAM?TRO "FORMA DE TRIBUTA??O DE DESPESAS ACESSORIA E FRETE" = "T" ' ||
                       CHR(13) || 'NA ROTINA 132, ABA "LIVROS FISCAIS".';
          raise V_TRIBUTACAOINCOMPLETA;
        end if;
      end loop;
    end if;
  end if;
/*  ---------------------------------------------------------------------------------
  -- VALIDAR REDU??ES Z DO PER?ODO
  VALIDAR_REDUCOES_PERIODO();
*/  ---------------------------------------------------------------------------------
  -- CORRIGINDO NUMERA??O DE MAPAS RESUMO DE CAIXA
  CORRIGIR_NUMERACAO_MAPARESUMO();
  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
    
  ---------------------------------------------------------------------------------
  IF vPARAM_VALIDA_NF_CONTABILIZADA = 'N' THEN
    DELETAR_REGISTROS_PCNFBASESAID(DATA1,DATA2,PCODFILIAL,NUMNOTA1,NUMNOTA2); 
  END IF;
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'RATEANDO DESPESAS';
  ---------------------------------------------------------------------------------
  -- RATEAR AS DESPESAS SE AINDA N?O ESTIVEREM
  V_NUMNOTAINICIAL := NUMNOTA1;
  V_NUMNOTAFINAL   := NUMNOTA2;
  FOR DADOSRAT IN (SELECT NUMTRANSVENDA
                   FROM PCNFSAID
                   WHERE NVL(CODFILIALNF, CODFILIAL) = PCODFILIAL
                     AND DTSAIDA BETWEEN TO_DATE(DATA1) AND TO_DATE(DATA2)
                     AND NUMNOTA BETWEEN V_NUMNOTAINICIAL AND V_NUMNOTAFINAL
                     AND DTSAIDA >= V_DATA_INICIO_NFE20                     
                     AND (VLFRETE > 0 OR VLOUTRASDESP > 0)
                     AND NVL(DESPESASRATEADA, 'N') = 'N'
                     AND CHAVENFE IS NOT NULL
                     AND TIPOVENDA <> 'DF'
                     )
  LOOP
      FISCAL.CALCULAR_RATEIO_DESPESAS(DADOSRAT.NUMTRANSVENDA, V_SQLERRO);
      V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
  END LOOP;
  
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'BUSCANDO NOTAS FISCAIS';
  ---------------------------------------------------------------------------------
  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  -- Processando Livro Fiscal.
  ---------------------------------------------------------------------------------
  if NVL(vnGeraDTENTREGA,'N') = 'N' then
     PROCESSAR_LIVRO(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL, 'N');
  else
     -- Gerar notas dentro do periodo
     PROCESSAR_LIVRO(NUMNOTA1,NUMNOTA2,DATA1,DATA2,V_INSERIRCF,PCODFILIAL, 'N');

     -- Gerar notas que estao dentro do periodo pelo DTENTREGA.
       FOR DADOSNF IN (SELECT S.NUMTRANSVENDA, S.NUMNOTA, S.DTSAIDA, NVL(S.DTENTREGA, S.DTSAIDANF) DTENTREGA
                         FROM PCNFSAID S
                        WHERE NVL(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
                          AND NVL(NVL(S.DTENTREGA, S.DTSAIDANF),S.DTSAIDA) BETWEEN DATA1 and DATA2
                          AND NVL(NVL(S.DTENTREGA, S.DTSAIDANF),S.DTSAIDA) <> S.DTSAIDA
                          AND S.NUMNOTA BETWEEN NUMNOTA1 AND NUMNOTA2
                          AND S.DTSAIDA BETWEEN TO_DATE(DATA1, 'DD-MM-YYYY')-90 AND DATA1 -- BUSCAR NOTAS QUE ESTEJAM 30DIAS ABAIXO DA DATA INICIAL.
                        )
       LOOP
          -- Excluir Nf individualmente
          delete /*+ INDEX (PCNFBASESAID PCNFBASESAID_IDX06) */ from PCNFBASESAID
           where DTSAIDA       = DADOSNF.DTSAIDA
             and CODFILIALNF   = PCODFILIAL
             and NUMNOTA       = DADOSNF.NUMNOTA
             and NUMTRANSVENDA = DADOSNF.NUMTRANSVENDA;

          PROCESSAR_LIVRO(DADOSNF.NUMNOTA,DADOSNF.NUMNOTA,DADOSNF.DTSAIDA,DADOSNF.DTSAIDA,V_INSERIRCF,PCODFILIAL,'S');
          COMMIT;
       END LOOP;
   end if;
  ---------------------------------------------------------------------------------
  -- POPULANDO CONTAS CONTABEIS NOTAS SEM ITENS
  CODCONTASPED_NOTA_SEM_ITEM;
  ---------------------------------------------------------------------------------
  -- POPULANDO CONTAS CONTABEIS E NAT.DA RECEITA PARA NFCE.
  BEGIN
    FOR DADOS IN (
        SELECT DISTINCT S.DTSAIDA AS DATA, S.NUMTRANSVENDA, NVL(SUBSTR(S.CHAVENFE, 21,2),'XX') MODELO
              ,S.ESPECIE, M.CODFISCAL CFOP, M.CODSITTRIBPISCOFINS CST, M.NUMTRANSITEM ,M.CODPROD, M.NBM NCM
              ,REGEXP_REPLACE(TRIM(MC.EXTIPI), '[^[:digit:]]') EXTIPI
          FROM PCNFSAID S, PCMOV M, PCMOVCOMPLE MC
         WHERE S.NUMTRANSVENDA = M.NUMTRANSVENDA
           AND M.NUMTRANSITEM = MC.NUMTRANSITEM
           AND S.DTSAIDA BETWEEN DATA1 AND DATA2
           AND NVL(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
           AND NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL  -- incluido conforme solicitado pelo DBA
           AND S.NUMNOTA BETWEEN NVL(NUMNOTA1, 0) AND NVL(NUMNOTA2, 99999999)
           AND ((MC.CODCONTACONTSPED IS NULL) OR (MC.NATUREZARECEITA IS NULL))
    ) LOOP
        -----------------------------------------------
        --ATUALIZA CONTA CONTABIL
        -----------------------------------------------
        FISCAL.GERA_CONTAS_CONTAB_SPED_ITEM(PCODFILIAL,
                                            DADOS.ESPECIE,
                                            DADOS.CFOP,
                                            DADOS.CST,
                                            DADOS.NUMTRANSITEM);
        -----------------------------------------------
        --ATUALIZA NATUREZA DE RECEITA PARA MODELO 65 -
        -----------------------------------------------
         IF DADOS.MODELO  IN ('55', '65') THEN
            FISCAL.GERA_NATUREZA_RECEITA_ITEM(PCODFILIAL,
                                              DADOS.DATA,
                                              DADOS.CODPROD,
                                              DADOS.CST,
                                              DADOS.NCM,
                                              DADOS.EXTIPI,
                                              DADOS.NUMTRANSITEM);
         END IF;
         V_CONTADORREGISTRO := V_CONTADORREGISTRO + 1;
    END LOOP;

      IF V_CONTADORREGISTRO > 0 THEN
         COMMIT;
         V_CONTADORREGISTRO := 0;
      END IF;
  END;
  --------------------------------------------------------------------------------
  -- GERAR CORRE??O DE REDU??ES Z CONSIDERANDO O CFOP DOS CUPONS
  GERAR_REDUCOES_CFOP_ZERO(PCODFILIAL, DATA1, DATA2);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  V_SQLERRO := 'GERANDO MAPA RESUMO (ECF)';
  GERAR_MAPARESUMO(PCODFILIAL, DATA1, DATA2);

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  CALCULAR_PIS_COFINS_CUPOM_REDZ();

  IF V_CONTADORREGISTRO > 0 THEN
     COMMIT;
     V_CONTADORREGISTRO := 0;
  END IF;
  ---------------------------------------------------------------------------------
  if V_UFFILIAL = 'CE' then
    CORRIGIR_ICMS_CUPONS();
  end if;

  if NUMNOTA1 <> NUMNOTA2 then
     IF V_CONTADORREGISTRO > 0 THEN
        COMMIT;
        V_CONTADORREGISTRO := 0;
     END IF;

     GERAR_LOG_BACKUP();
  end if;

  COMMIT;
  DESATIVAR_SESSAO;
  RESULTADO := 'OK';
  ---------------------------------------------------------------------------------
exception
  when V_VALIDACAOLIVRO then
    begin
      RESULTADO := V_SQLERRO || ' -> ' ||
                   'LIVRO FISCAL J? ENCERRADO!';
      rollback;
      DESATIVAR_SESSAO;
    end;
  when V_FALTANDO_REDUCOES_Z then
    begin
      RESULTADO := substr(V_SQLERRO, 0, 4000);
      rollback;
      DESATIVAR_SESSAO;
    end;
    ---------------------------------------------------------------------------------
  when V_TRIBUTACAOINCOMPLETA then
    begin
      RESULTADO := V_SQLERRO;
      rollback;
      DESATIVAR_SESSAO;
    end;
    ---------------------------------------------------------------------------------
  when others then
    begin
      RESULTADO :=  substr('ERRO: ' || V_SQLERRO || ' -> ' || sqlerrm, 1,4000);
      rollback;
      DESATIVAR_SESSAO;
    end;
end;
-- 27/02/2024 - Gam -- Performance.
-- 05/03/2024 - Gam -- Performance.
