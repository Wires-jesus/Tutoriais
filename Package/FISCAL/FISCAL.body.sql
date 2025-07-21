create or replace package body FISCAL is


    CURSOR CONSULTA_DADOS_CREDPRESUMIDO(P_NUMTRANSACAO  NUMBER,
                                        P_TIPOMOV VARCHAR2 ) IS
                     (SELECT 'N' PREFATURAMENTO,
                             M.CODPROD,
                             M.NUMTRANSITEM,
                             MC.CODBENEFICIOFISCAL, -- Código Beneficio Fiscal
                             M.CODST, -- Figura tributária rotina 514
                             M.PERCICM, -- Alíquota ICMS NF
                             DECODE(NVL(N.CONSUMIDORFINAL,'N'),'S',NVL(N.CONTRIBUINTE,'N'),  'S', 'S', 'N') CONTRIBUINTECONSFINAL, -- Contribuinte consumidor final (Opcional)
                             CLIENTE.TIPOEMPRESA, -- Tipo de empresa (Opcional)
                             CLIENTE.TIPOFJ TIPOPESSOA, -- Tipo de pessoa (Opcional)
                             MC.ORIGMERCTRIB, -- Origem da mercadoria (Opcional)
                             M.SITTRIBUT, -- Situação tributária (Opcional)
                             M.CODFISCAL, -- Código fiscal(CFOP) (Opcional)
                             M.NBM, -- NCM da mercadoria (Opcional)
                             M.PUNITCONT, -- Preço unitário
                             M.VLIPI, -- Valor do IPI
                             M.VLFRETE, -- Valor do frete
                             M.ST VLST, -- Valor do ST
                             M.VLOUTROS, -- Valor de outros
                             M.BASEICMS, -- Base ICMS
                             M.PERCBASERED -- Redução Base ICMS
                        from PCNFSAID       N,
                             PCMOV          M,
                             PCMOVCOMPLE    MC,
                             PCPRODUT       P,
                             PCCLIENTENDENT ENT,
                             PCCIDADE       CIDADE_ENT,
                             PCPEDC         PD,
                             PCCLIENT       CLIENTE,
                             PCFILIAL       FI
                       where N.NUMTRANSVENDA = P_NUMTRANSACAO
                         and N.NUMTRANSVENDA = M.NUMTRANSVENDA
                         and PD.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
                         and ENT.CODENDENTCLI(+) = NVL(PD.CODENDENTCLI, PD.CODENDENT)
                         and ENT.CODCLI(+) = PD.CODCLI
                         and P.CODPROD = M.CODPROD
                         and N.NUMNOTA = M.NUMNOTA
                         and M.CODOPER <> 'SD'
                         and NVL(N.FINALIDADENFE, 'X') <> 'C'
                         and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                         and CIDADE_ENT.CODCIDADE(+) = CLIENTE.CODCIDADECOM
                         and CLIENTE.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
                         and FI.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                         and P_TIPOMOV = 'S'
                         and M.DTCANCEL is null
                         and M.QTCONT > 0
                   UNION ALL
                      SELECT 'S' PREFATURAMENTO,
                             M.CODPROD,
                             M.NUMTRANSITEM,
                             MC.CODBENEFICIOFISCAL, -- Código Beneficio Fiscal
                             M.CODST, -- Figura tributária rotina 514
                             M.PERCICM, -- Alíquota ICMS NF
                             DECODE(NVL(N.CONSUMIDORFINAL,'N'),'S',NVL(N.CONTRIBUINTE,'N'),  'S', 'S', 'N') CONTRIBUINTECONSFINAL, -- Contribuinte consumidor final (Opcional)
                             CLIENTE.TIPOEMPRESA, -- Tipo de empresa (Opcional)
                             CLIENTE.TIPOFJ TIPOPESSOA, -- Tipo de pessoa (Opcional)
                             MC.ORIGMERCTRIB, -- Origem da mercadoria (Opcional)
                             M.SITTRIBUT, -- Situação tributária (Opcional)
                             M.CODFISCAL, -- Código fiscal(CFOP) (Opcional)
                             M.NBM, -- NCM da mercadoria (Opcional)
                             M.PUNITCONT, -- Preço unitário
                             M.VLIPI, -- Valor do IPI
                             M.VLFRETE, -- Valor do frete
                             M.ST VLST, -- Valor do ST
                             M.VLOUTROS, -- Valor de outros
                             M.BASEICMS, -- Base ICMS
                             M.PERCBASERED -- Redução Base ICMS
                        from PCNFSAIDPREFAT       N,
                             PCMOVPREFAT          M,
                             PCMOVCOMPLEPREFAT    MC,
                             PCPRODUT       P,
                             PCCLIENTENDENT ENT,
                             PCCIDADE       CIDADE_ENT,
                             PCPEDC         PD,
                             PCCLIENT       CLIENTE,
                             PCFILIAL       FI
                       where N.NUMTRANSVENDA = P_NUMTRANSACAO
                         and N.NUMTRANSVENDA = M.NUMTRANSVENDA
                         and PD.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
                         and ENT.CODENDENTCLI(+) = NVL(PD.CODENDENTCLI, PD.CODENDENT)
                         and ENT.CODCLI(+) = PD.CODCLI
                         and P.CODPROD = M.CODPROD
                         and N.NUMNOTA = M.NUMNOTA
                         and M.CODOPER <> 'SD'
                         and NVL(N.FINALIDADENFE, 'X') <> 'C'
                         and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                         and CIDADE_ENT.CODCIDADE(+) = CLIENTE.CODCIDADECOM
                         and CLIENTE.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
                         and FI.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                         and P_TIPOMOV = 'S'
                         and M.DTCANCEL is null
                         and M.QTCONT > 0
                UNION ALL
                      SELECT 'N' PREFATURAMENTO,
                             M.CODPROD,
                             M.NUMTRANSITEM,
                             MC.CODBENEFICIOFISCAL, -- Código Beneficio Fiscal
                             M.CODST, -- Figura tributária rotina 514
                             M.PERCICM, -- Alíquota ICMS NF
                             DECODE(NVL(N.CONSUMIDORFINAL,'N'),'S',NVL(N.CONTRIBUINTE,'N'),  'S', 'S', 'N') CONTRIBUINTECONSFINAL, -- Contribuinte consumidor final (Opcional)
                             'N' TIPOEMPRESA, -- Tipo de empresa (Opcional)
                             N.TIPOFJ TIPOPESSOA, -- Tipo de pessoa (Opcional)
                             MC.ORIGMERCTRIB, -- Origem da mercadoria (Opcional)
                             M.SITTRIBUT, -- Situação tributária (Opcional)
                             M.CODFISCAL, -- Código fiscal(CFOP) (Opcional)
                             M.NBM, -- NCM da mercadoria (Opcional)
                             M.PUNITCONT, -- Preço unitário
                             M.VLIPI, -- Valor do IPI
                             M.VLFRETE, -- Valor do frete
                             M.ST VLST, -- Valor do ST
                             M.VLOUTROS, -- Valor de outros
                             M.BASEICMS, -- Base ICMS
                             M.PERCBASERED -- Redução Base ICMS
                        from PCNFENT N, PCMOV M, PCMOVCOMPLE MC, PCPRODUT P
                       where N.NUMTRANSENT = P_NUMTRANSACAO
                         and N.NUMTRANSENT = M.NUMTRANSENT
                         AND P.CODPROD = M.CODPROD
                         and N.NUMNOTA = M.NUMNOTA
                         and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                         and N.TIPODESCARGA in ('6', '8', 'T')
                         and P_TIPOMOV = 'E'
                         and M.DTCANCEL is null
                         and M.QTCONT > 0
          );


   -- VERIFICANDO SE A FILIAL UTILIZA PIS/COFINS POR FIGURA TRIBUTÁRIA
   function UTILIZA_FIGURA_PISCOFINS(MSG out varchar2) return boolean is
   begin
         begin
            if PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPISCOFINSFIGVENDA', VCODFILIAL) = 'S'
            then
               return true;
            else
               MSG := 'S:Esta filial não utiliza PIS/COFINS por figura tributária!'||
                      ' Isso significa que o parâmetro 2506 - (UTILIZAPISCOFINSFIGVENDA) está marcado como Não.'||
                      ' Marque o mesmo como Sim, depois verifique o parâmetro 1092 - (CON_USATRIBUTACAOPORUF),  '||
                      'se o mesmo tiver como Sim, faça a configuração da tributação na rotina 574 se Não, faça a configuração na rotina 271.' ;
               return false;
            end if;
         exception
            when others then
               MSG := 'S:Esta filial não utiliza PIS/COFINS por figura tributária!';
               return false;
         end;
   end;

   function RETORNAULTIMAENTRADA(PCOPROD in number
                                ,PDATA   in date
                                ,PFILIAL in varchar2) return number is
      VNUMULTENTRADA number;
   begin
      begin
         select NUMTRANSENT
           into VNUMULTENTRADA
           from (select max(PCMOV.NUMTRANSENT) NUMTRANSENT
                   from PCMOV
                       ,PCNFENT
                  where PCMOV.CODPROD = PCOPROD
                    and PCMOV.DTMOV < PDATA
                    and PCMOV.QTCONT > 0
                    and PCMOV.DTCANCEL is null
                    and NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PFILIAL
                    and PCNFENT.ESPECIE = 'NF'
                    and PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                    and PCMOV.NUMNOTA = PCNFENT.NUMNOTA
                    and PCMOV.CODOPER in ('E', 'EB')
                    and (NVL(PCMOV.ST, 0) > 0 or NVL(PCMOV.VLDESPADICIONAL, 0) > 0)
                  order by PCMOV.NUMTRANSENT)
          where ROWNUM = 1;
         return VNUMULTENTRADA;
      exception
         when others then
            return 0;
      end;
   end;

   function GET_DADOS_ICMS(P_CODFILIAL   in varchar2
                           ,P_TIPO       in varchar2
                           ,P_CURSOR     in varchar2
                           ,P_ROWIDPCMOV in varchar2
                           ,P_ESTENT     in varchar2
                           ,P_CHAVENFE   IN VARCHAR2
                           ,P_CONSLIVRO  in varchar2 := 'S' ) return number is

   V_VALORICMS              PCMOVCOMPLE.VLICMS%type;
   V_GERABASENORMALQUANDOST varchar2(1);
   V_UFFILIAL               varchar2(2);

   begin
     begin
       select NVL(GERABASENORMALQUANDOST, 'S'),
              UF
         into V_GERABASENORMALQUANDOST,
              V_UFFILIAL
         from PCFILIAL F
        where F.CODIGO = P_CODFILIAL;
     exception
       when others then
         return 0;
     end;

     if (P_TIPO = 'V') then
       begin
         SELECT
                CASE  P_CURSOR
                  WHEN 'NF' THEN
                    SUM(
                        CASE WHEN (decode(P_CONSLIVRO,'S',NVL(B.GERAICMSLIVROFISCAL, 'S'),'S') = 'N') OR
                                  (NVL(B.BASEICMS,0) <= 0) OR (NVL(B.PERCICM,0) <= 0) THEN
                           0
                        ELSE
                           ((ROUND(
                                  ROUND(
                                    DECODE(NVL(P_CHAVENFE,'X'),'X',NVL(B.BASEICMS, 0), (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0))) * B.QTCONT , 2) * (NVL(NVL(B.PERCICMCP, B.PERCICM), 0) / 100), 2))
                                      -
                            (ROUND(
                                  ROUND(
                                      ROUND(  DECODE(NVL(P_CHAVENFE,'X'),'X',NVL(B.BASEICMS, 0), (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0))) * B.QTCONT, 2) *
                                         (NVL(NVL(B.PERCICMCP, B.PERCICM), 0) / 100), 2) * (NVL(MC.PERDIFEREIMENTOICMS,NVL(B.PERCDESCICMSDIF,0))/100), 2)))
                    END)
                  WHEN 'NFCE' THEN
                    SUM(DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                               DECODE(NVL(B.BASEICMS,0),0,0,
                                      DECODE(NVL(B.PERCBASERED,0), 0,
                                             ROUND(MC.VLSUBTOTITEM * B.PERCICM / 100 - NVL(NVL(VLDESCICMSDIF,0), NVL(MC.VLICMSDIFERIDO,0)),2),
                                             ROUND(B.QTCONT * (B.BASEICMS * B.PERCICM / 100), 2) -
                                             (ROUND(ROUND((NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) *
                                                          B.QTCONT * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                               (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)))),
                              ROUND((B.QTCONT * (NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100)),2) ))
                  WHEN 'CP' THEN
                    ROUND(SUM(
                      CASE WHEN (decode(P_CONSLIVRO,'S',(NVL(B.GERAICMSLIVROFISCAL, 'S') ),'S')= 'N') or
                                ((V_GERABASENORMALQUANDOST = 'N') and (NVL(B.ST,0) > 0) and (P_ESTENT <> V_UFFILIAL)) or
                                 (NVL(B.BASEICMS,0) <= 0) or (NVL(B.PERCICM,0) <= 0) THEN
                         0
                      ELSE
                         DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                                B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100 -
                                   (ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                          B.QTCONT * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                    (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100)),
                                B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100)
                      END), 2)
                  WHEN 'DF' THEN
                    SUM(
                    CASE WHEN (decode(P_CONSLIVRO,'S',(NVL(B.GERAICMSLIVROFISCAL, 'S') ),'S')= 'N') or
                            ((V_GERABASENORMALQUANDOST = 'N') and (NVL(B.ST,0) > 0) and (P_ESTENT <> V_UFFILIAL)) or
                            (NVL(B.BASEICMS,0) <= 0) or (NVL(B.PERCICM,0) <= 0) THEN
                       0
                    ELSE
                       DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                              ROUND(B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100, 2) -
                                 (ROUND(ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                              B.QTCONT * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                        (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)),
                              ROUND(B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100, 2))
                    END)
                END VLICMS
         into V_VALORICMS
         from PCMOV       B,
              PCMOVCOMPLE MC
         where B.ROWID = P_ROWIDPCMOV
           and NVL(B.CODFILIALNF,B.CODFILIAL) = P_CODFILIAL
           and MC.NUMTRANSITEM(+) = B.NUMTRANSITEM
           and B.STATUS in ('A', 'AB')
           and B.QTCONT > 0;

         return V_VALORICMS;
       exception
         when others then
               return 0;
       end;
     else
       begin
         SELECT
            CASE P_CURSOR
              WHEN 'NF' THEN
                SUM(
                     CASE WHEN (decode(P_CONSLIVRO,'S',(NVL(B.GERAICMSLIVROFISCAL, 'S') ),'S')= 'N') or
                          (NVL(B.BASEICMS,0) <= 0) or (NVL(B.PERCICM,0) <= 0) THEN
                        0
                     ELSE
---------------
                      DECODE(B.CODOPER,'ET',
                          DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                                 ROUND( ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) * NVL(B.PERCICM, 0) / 100, 2) -
                                    (ROUND(ROUND( ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                 B.QTCONT,2) * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                           (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)),
                                 ROUND( ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) * NVL(B.PERCICM,0) / 100,2)),

                          DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                                 ROUND(B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM, 0) / 100, 2) -
                                    (ROUND(ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                 B.QTCONT * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                           (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)),
                                 ROUND(B.QTCONT * (NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100),2))
                            )
                   END)

              WHEN 'NFE' THEN
                SUM(
                CASE WHEN (decode(P_CONSLIVRO,'S',(NVL(B.GERAICMSLIVROFISCAL, 'S') ),'S')= 'N') or
                          (NVL(B.BASEICMS,0) <= 0) or (NVL(B.PERCICM,0) <= 0) THEN
                   0
                ELSE
                      DECODE(B.CODOPER,'ET',
                          DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                                 ROUND( ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) * NVL(B.PERCICM, 0) / 100, 2) -
                                    (ROUND(ROUND( ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                 B.QTCONT,2) * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                           (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)),
                                 ROUND( ROUND(B.QTCONT * NVL(B.BASEICMS,0),2) * NVL(B.PERCICM,0) / 100,2)),

                   DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                          ROUND(B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM, 0) / 100, 2) -
                             (ROUND(ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                          B.QTCONT * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                    (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)),
                          ROUND(B.QTCONT * (NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100),2))
                        )
                END)
              WHEN 'IMP' THEN
                 SUM(DECODE(NVL(B.PERCICM, 0), 0, 0,
                            DECODE(decode(P_CONSLIVRO,'S',NVL(B.GERAICMSLIVROFISCAL, 'S'),'S'), 'N', 0,
                                   ROUND(B.QTCONT * DECODE(NVL(MC.VLICMS,0), 0, NVL(B.VLCREDICMS,0), MC.VLICMS), 2))))
              WHEN 'DEVNF' THEN
                SUM(
                CASE WHEN (NVL(B.GERAICMSLIVROFISCAL, 'S') = 'N') OR
                          (NVL(B.BASEICMS,0) <= 0) OR (NVL(B.PERCICM,0) <= 0) THEN
                   0
                ELSE
                   DECODE(DECODE(LENGTH(NVL(B.SITTRIBUT, 0)), 3, SUBSTR(B.SITTRIBUT, 2, 3), B.SITTRIBUT), '51',
                          ROUND(B.QTCONT *NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100, 2) -
                             (ROUND(ROUND((NVL(B.BASEICMS,0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                          B.QTCONT * (DECODE(NVL(B.PERCICMCP,0), 0, NVL(B.PERCICM,0), B.PERCICMCP) / 100), 2) *
                                    (DECODE(NVL(MC.PERDIFEREIMENTOICMS,0), 0, NVL(B.PERCDESCICMSDIF,0), MC.PERDIFEREIMENTOICMS) / 100), 2)),
                          ROUND(B.QTCONT * NVL(B.BASEICMS,0) * NVL(B.PERCICM,0) / 100, 2))
                END)
              WHEN 'DEVNFE' THEN
                SUM(
                CASE WHEN (decode(P_CONSLIVRO,'S',(NVL(B.GERAICMSLIVROFISCAL, 'S') ),'S')= 'N') OR
                          (NVL(B.BASEICMS,0) <= 0) OR (NVL(B.PERCICM,0) <= 0) THEN
                   0
                ELSE
                   ((ROUND(
                          ROUND(
                             (NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) * B.QTCONT , 2) * (NVL(NVL(B.PERCICMCP, B.PERCICM), 0) / 100), 2))
                              -
                    (ROUND(
                          ROUND(
                              ROUND((NVL(B.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) * B.QTCONT, 2) *
                                 (NVL(NVL(B.PERCICMCP, B.PERCICM), 0) / 100), 2) * (NVL(MC.PERDIFEREIMENTOICMS,NVL(B.PERCDESCICMSDIF,0))/100), 2)))
                END)
            END VLICMS
         into V_VALORICMS
         from PCMOV        B,
              PCMOVCOMPLE  MC
         where B.NUMTRANSITEM = MC.NUMTRANSITEM(+)
           and NVL(B.CODFILIALNF,B.CODFILIAL) = P_CODFILIAL
           and B.STATUS in ('A', 'AB')
           and B.ROWID = P_ROWIDPCMOV;
           return V_VALORICMS;
       exception
         when others then
               return 0;
       end;
     end if;
   exception
      when others then
         return 0;
   end;

   function FORMATAR_CST_ICMS(PSITTRIBUT    in varchar2
                             ,PIMPORTADO    in varchar2
                             ,PORIGMERCTRIB in varchar2
                             ,PDATAOPER     in date) return varchar2 is
      VSITTRIBUT_TEMP varchar2(3);
   begin

      VSITTRIBUT_TEMP := SUBSTR(PSITTRIBUT, 1, 3);

      if LENGTH(VSITTRIBUT_TEMP) = 3
      then
         return PSITTRIBUT;
      end if;

      VSITTRIBUT_TEMP := RPAD(VSITTRIBUT_TEMP, 2, '0');

      if PDATAOPER > TO_DATE('01/01/2013', 'DD/MM/YYYY')
      then
         if PORIGMERCTRIB is not null
         then
            return PORIGMERCTRIB || VSITTRIBUT_TEMP;
         end if;
      end if;

      if PIMPORTADO = 'S'
      then
         return '2' || VSITTRIBUT_TEMP;
      elsif PIMPORTADO = 'D'
      then
         return '1' || VSITTRIBUT_TEMP;
      else
         return '0' || VSITTRIBUT_TEMP;
      end if;

   exception
      when others then
         return '';
   end;

   --Função de buscar informa??es de ipi
   function GET_DADOS_TRIBUTACAO_IPI(P_CODCLI           in number
                                    ,P_CODPROD          in number
                                    ,P_CODFILIAL        in varchar2
                                    ,P_DATAOPERACAO     in date
                                    ,P_CST_ENTRADA      out number
                                    ,P_CST_SAIDA        out number
                                    ,P_GERABASEALIQZERO out varchar2
                                    ,P_MSG              out varchar2
                                    ,P_CODFISCAL        in number
                                    ,P_TIPO_VENDA       in varchar2
                                    ,P_TIPO_ENTRADA     in varchar2
                                    ,P_CODIGO_OPERACAO  in varchar2
                                    ,P_CODENQENTRADA    out varchar2
                                    ,P_CODENQSAIDA      out varchar2
                                    ,P_FINALIDADENFE    in varchar2 := 'N')  return varchar2 is

      V_CODFIGURAIPI        PCFIGURATRIBIPI.CODFIGURAIPI%type;
      V_CODFIGURAIPIEXCECAO PCFIGURATRIBIPI.CODFIGURAIPI%type;
      V_CLIENTESUFRAMA      varchar2(2);
      V_PROD_IMPORTADO      PCPRODUT.IMPORTADO%type;
   begin

      -- Nota complementar não deve calcular ipi
      if (NVL(P_FINALIDADENFE, 'N') = 'C') then
        P_CST_ENTRADA := '49';
        P_CST_SAIDA := '99';
        P_GERABASEALIQZERO := 'S';
        P_CODENQENTRADA := '999';
        P_CODENQSAIDA := '999';
        P_MSG := 'NOTA COMPLEMENTAR NÃO TEM IPI';
        return 'S';
      end if;

      begin
         -- Pegar a figura vinculada ao produto
         select CODFIGURAIPI
           into V_CODFIGURAIPI
           from PCTRIBIPI
          where CODFILIAL = P_CODFILIAL
            and CODPROD = P_CODPROD;
      exception
         when others then
            P_MSG := 'FIGURA TRIBUTÁRIA DO IPI INEXISTENTE OU NÃO VINCULADA!';
            return 'N';
      end;

      if V_CODFIGURAIPI > 0
      then
         begin
            -- Pegar informações do cliente
            select case
                      when (trim(C.SULFRAMA) is not null and C.DTVENCSUFRAMA >= P_DATAOPERACAO) then
                       'S'
                      else
                       'N'
                   end CLI_SUFRAMA
              into V_CLIENTESUFRAMA
              from PCCLIENT C
             where CODCLI = P_CODCLI;
         exception
            when others then
               V_CLIENTESUFRAMA := 'N';
         end;

         begin
            -- Pegar informações do produto
            select IMPORTADO into V_PROD_IMPORTADO from PCPRODUT P where CODPROD = P_CODPROD;
         exception
            when others then
               V_PROD_IMPORTADO := 'N';
         end;

         begin
            -- Verificar se enquadra numa das regras de exceção
            select min(CODFIGURAIPIEXCECAO)
              into V_CODFIGURAIPIEXCECAO
              from PCEXCECAOIPI
             where CODFIGURAIPI = V_CODFIGURAIPI
               and VALOR1 = DECODE(TIPO1
                                  ,'CS'
                                  ,V_CLIENTESUFRAMA
                                  ,'PI'
                                  ,DECODE(V_PROD_IMPORTADO, 'D', 'S', V_PROD_IMPORTADO)
                                  ,'TV'
                                  ,P_TIPO_VENDA
                                  ,'TE'
                                  ,P_TIPO_ENTRADA
                                  ,'CF'
                                  ,P_CODFISCAL
                                  ,'CO'
                                  ,P_CODIGO_OPERACAO
                                  ,'CC'
                                  ,P_CODCLI
                                  ,'DS'
                                  ,P_CODFISCAL)
               and (VALOR2 is null or
                   VALOR2 = DECODE(TIPO2
                                   ,'CS'
                                   ,V_CLIENTESUFRAMA
                                   ,'PI'
                                   ,DECODE(V_PROD_IMPORTADO, 'D', 'S', V_PROD_IMPORTADO)
                                   ,'TV'
                                   ,P_TIPO_VENDA
                                   ,'TE'
                                   ,P_TIPO_ENTRADA
                                   ,'CF'
                                   ,P_CODFISCAL
                                   ,'CO'
                                   ,P_CODIGO_OPERACAO));

            if NVL(V_CODFIGURAIPIEXCECAO, 0) > 0
            then
               V_CODFIGURAIPI := V_CODFIGURAIPIEXCECAO;
            end if;
         exception
            when others then
               null;
         end;
         begin
            -- Pegando o CST de entrada e saida da figura
            select CODSITTRIBIPIENT
                  ,CODSITTRIBIPISAID
                  ,GERABASEALIQZERO
                  ,CODENQENTRADA
                  ,CODENQSAIDA
              into P_CST_ENTRADA
                  ,P_CST_SAIDA
                  ,P_GERABASEALIQZERO
                  ,P_CODENQENTRADA
                  ,P_CODENQSAIDA
              from PCFIGURATRIBIPI
             where CODFIGURAIPI = V_CODFIGURAIPI;
            return 'S';
         exception
            when others then
               return 'N';
         end;
      else
         return 'N';
      end if;
   exception
      when others then
         return 'N';
   end;
   -- PROCEDIMENTO PARA OBTER EXCECAO PIS/COFINS
   function GET_CODTRIBEXCECAO_PISCOFINS(PCODTRIBPISCOFINS in number
                                        ,PCODFISCAL        in number
                                        ,PCODOPER          in varchar2
                                        ,PCONDVENDA        in number
                                        ,PCLIENTESUFRAMA   in varchar2
                                        ,PPRODUTOIMPORTADO in varchar2
                                        ,PTIPOCLIENT       in varchar2
                                        ,PPISCOFINSCUM     in varchar2
                                        ,PFILIALORIGEM     in varchar2
                                        ,PDATAVIGENCIA     in date
                                        ,PCODIGOCLIENTE    in varchar2
                                        ,PCODEXCTRIBPISCOFINS IN INTEGER
                                        ,PNCM              in varchar2) return number is
      VCODTRIB number;
   begin
      VCODTRIB := -1;

      select NVL(min(CODEXCFIGTRIB), -1)
        into VCODTRIB
        from (select E.CODEXCFIGTRIB
                from PCEXCECAOPISCOFINSVIGENCIA E
               where E.CODTRIBPISCOFINS = PCODTRIBPISCOFINS
                 and PDATAVIGENCIA between E.DTINICIO and E.DTFINAL
                 and trim(E.VALOR) = trim(DECODE(E.TIPO
                                                ,'CF'
                                                ,TO_CHAR(PCODFISCAL)
                                                ,'CO'
                                                ,PCODOPER
                                                ,'TV'
                                                ,TO_CHAR(PCONDVENDA)
                                                ,'CS'
                                                ,TO_CHAR(PCLIENTESUFRAMA)
                                                ,'PI'
                                                ,TO_CHAR(PPRODUTOIMPORTADO)
                                                ,'TC'
                                                ,TO_CHAR(PTIPOCLIENT)
                                                ,'PC'
                                                ,TO_CHAR(PPISCOFINSCUM)
                                                ,'FO'
                                                ,TO_CHAR(PFILIALORIGEM)
                                                ,'CC'
                                                ,TO_CHAR(PCODIGOCLIENTE)
                                                ,'DS'
                                                ,TO_CHAR(PCODFISCAL)
                                                ,'NC'
                                                ,TO_CHAR(PNCM)))
                 and (trim(E.VALOR2) is null or
                     trim(E.VALOR2) = trim(DECODE(E.TIPO2
                                                  ,'CF'
                                                  ,TO_CHAR(PCODFISCAL)
                                                  ,'CO'
                                                  ,PCODOPER
                                                  ,'TV'
                                                  ,TO_CHAR(PCONDVENDA)
                                                  ,'CS'
                                                  ,TO_CHAR(PCLIENTESUFRAMA)
                                                  ,'PI'
                                                  ,TO_CHAR(PPRODUTOIMPORTADO)
                                                  ,'TC'
                                                  ,TO_CHAR(PTIPOCLIENT)
                                                  ,'PC'
                                                  ,TO_CHAR(PPISCOFINSCUM)
                                                  ,'FO'
                                                  ,TO_CHAR(PFILIALORIGEM)
                                                  ,'CC'
                                                  ,TO_CHAR(PCODIGOCLIENTE)
                                                  ,'DS'
                                                  ,TO_CHAR(PCODFISCAL)
                                                  ,'NC'
                                                  ,TO_CHAR(PNCM))))
                 and (trim(E.VALOR3) is null or
                     trim(E.VALOR3) = trim(DECODE(E.TIPO3
                                                  ,'CF'
                                                  ,TO_CHAR(PCODFISCAL)
                                                  ,'CO'
                                                  ,PCODOPER
                                                  ,'TV'
                                                  ,TO_CHAR(PCONDVENDA)
                                                  ,'CS'
                                                  ,TO_CHAR(PCLIENTESUFRAMA)
                                                  ,'PI'
                                                  ,TO_CHAR(PPRODUTOIMPORTADO)
                                                  ,'TC'
                                                  ,TO_CHAR(PTIPOCLIENT)
                                                  ,'PC'
                                                  ,TO_CHAR(PPISCOFINSCUM)
                                                  ,'FO'
                                                  ,TO_CHAR(PFILIALORIGEM)
                                                  ,'CC'
                                                  ,TO_CHAR(PCODIGOCLIENTE)
                                                  ,'DS'
                                                  ,TO_CHAR(PCODFISCAL)
                                                  ,'NC'
                                                  ,TO_CHAR(PNCM))))
               order by E.DTFINAL desc
                       ,E.CODEXCECAO)
       where ROWNUM = 1;

      if VCODTRIB < 0
      then
         select NVL(min(E.CODEXCFIGTRIB), -1)
           into VCODTRIB
           from PCEXCECAOPISCOFINS E
          where E.CODTRIBPISCOFINS = PCODTRIBPISCOFINS
            and trim(E.VALOR) = trim(DECODE(E.TIPO
                                           ,'CF'
                                           ,TO_CHAR(PCODFISCAL)
                                           ,'CO'
                                           ,PCODOPER
                                           ,'TV'
                                           ,TO_CHAR(PCONDVENDA)
                                           ,'CS'
                                           ,TO_CHAR(PCLIENTESUFRAMA)
                                           ,'PI'
                                           ,TO_CHAR(PPRODUTOIMPORTADO)
                                           ,'TC'
                                           ,TO_CHAR(PTIPOCLIENT)
                                           ,'PC'
                                           ,TO_CHAR(PPISCOFINSCUM)
                                           ,'FO'
                                           ,TO_CHAR(PFILIALORIGEM)
                                           ,'CC'
                                           ,TO_CHAR(PCODIGOCLIENTE)
                                           ,'DS'
                                           ,TO_CHAR(PCODFISCAL)
                                           ,'NC'
                                           ,TO_CHAR(PNCM)))
            and (trim(E.VALOR2) is null or
                trim(E.VALOR2) = trim(DECODE(E.TIPO2
                                             ,'CF'
                                             ,TO_CHAR(PCODFISCAL)
                                             ,'CO'
                                             ,PCODOPER
                                             ,'TV'
                                             ,TO_CHAR(PCONDVENDA)
                                             ,'CS'
                                             ,TO_CHAR(PCLIENTESUFRAMA)
                                             ,'PI'
                                             ,TO_CHAR(PPRODUTOIMPORTADO)
                                             ,'TC'
                                             ,TO_CHAR(PTIPOCLIENT)
                                             ,'PC'
                                             ,TO_CHAR(PPISCOFINSCUM)
                                             ,'FO'
                                             ,TO_CHAR(PFILIALORIGEM)
                                             ,'CC'
                                             ,TO_CHAR(PCODIGOCLIENTE)
                                             ,'DS'
                                             ,TO_CHAR(PCODFISCAL)
                                             ,'NC'
                                             ,TO_CHAR(PNCM))))
            and (trim(E.VALOR3) is null or
                trim(E.VALOR3) = trim(DECODE(E.TIPO3
                                             ,'CF'
                                             ,TO_CHAR(PCODFISCAL)
                                             ,'CO'
                                             ,PCODOPER
                                             ,'TV'
                                             ,TO_CHAR(PCONDVENDA)
                                             ,'CS'
                                             ,TO_CHAR(PCLIENTESUFRAMA)
                                             ,'PI'
                                             ,TO_CHAR(PPRODUTOIMPORTADO)
                                             ,'TC'
                                             ,TO_CHAR(PTIPOCLIENT)
                                             ,'PC'
                                             ,TO_CHAR(PPISCOFINSCUM)
                                             ,'FO'
                                             ,TO_CHAR(PFILIALORIGEM)
                                             ,'CC'
                                             ,TO_CHAR(PCODIGOCLIENTE)
                                             ,'DS'
                                             ,TO_CHAR(PCODFISCAL)
                                             ,'NC'
                                             ,TO_CHAR(PNCM))));
      end if;

      IF PCONDVENDA = 8 AND PCODEXCTRIBPISCOFINS > 0 THEN
         VCODTRIB := PCODEXCTRIBPISCOFINS;
      END IF;

      if NVL(VCODTRIB, 0) < 0
      then
         return PCODTRIBPISCOFINS;
      else
         return VCODTRIB;
      end if;
   exception
      when others then
         return PCODTRIBPISCOFINS;
   end;
  --PRODIMENTO PARA BUSAR MOTIVO DA DESONERACAO DO ICMS
  function GET_MOTIVO_DESONICMS(PCST            in number,
                                PCODFILIAL      in varchar2,
                                PPRODUTORRURAL  in varchar2,
                                PSUFRAMA        in varchar2,
                                PORGAOPUBLICO   in varchar2,
                                PREGIMEESPECIAL IN VARCHAR2,
                                PCODCLI         in number,
                                PCODPROD        in number,
                                PTIPOCLIENTE    out varchar2,
                                PDESCONSIDERAR_SUFRAMA_DESCICM out varchar2,
                                PINCLUIRICMSBASEDESONERACAO    out varchar2)

   return number is
   vTipoCliente         varchar2(5);
   VCODTRIB             number;
   VMOTIVODESONERACAO   number;
   VMOVIVODESONERACAOEX NUMBER;
   VUFFILIAL            varchar2(2);
  begin
    begin
      select F.UF
        into VUFFILIAL
      from PCFILIAL F
      where F.CODIGO = PCODFILIAL;

      if PSUFRAMA = 'S' then
        vTipoCliente := 'SUF';
      elsif PORGAOPUBLICO = 'S' then
        vTipoCliente := 'OP';
      elsif PREGIMEESPECIAL = 'S' then
        vTipoCliente := 'RE';
      elsif PPRODUTORRURAL = 'S' then
        vTipoCliente := 'PR';
      else
        vTipoCliente := 'NI'; --não informado
      end if;

      PTIPOCLIENTE := vTipoCliente;

      select MOTIVODESONERACAO,
             CODIGO,
             NVL(DESCONSIDERAR_SUFRAMA_DESCICMS,'N') DESCONSIDERAR_SUFRAMA_DESCICMS,
             NVL(INCLUIRICMSBASEDESONERACAO, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGAVLDESONBASEDESON', PCODFILIAL), 'N'))
        into VMOTIVODESONERACAO,
             VCODTRIB,
             PDESCONSIDERAR_SUFRAMA_DESCICM,
             PINCLUIRICMSBASEDESONERACAO
      from PCFIGURATRIBDESONICMS
      where CST = PCST
        AND CODFILIAL = PCODFILIAL
        AND TIPOCLIENTE = vTipoCliente;
    exception
    when no_data_found then
      begin
        if (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGAVLDESONBASEDESON', PCODFILIAL), 'N') = 'S') and
           (VUFFILIAL = 'RJ') then
          select MOTIVODESONERACAO,
                 CODIGO,
                 NVL(DESCONSIDERAR_SUFRAMA_DESCICMS,'N') DESCONSIDERAR_SUFRAMA_DESCICMS,
                 NVL(INCLUIRICMSBASEDESONERACAO, NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGAVLDESONBASEDESON', PCODFILIAL), 'N'))
            into VMOTIVODESONERACAO,
                 VCODTRIB,
                 PDESCONSIDERAR_SUFRAMA_DESCICM,
                 PINCLUIRICMSBASEDESONERACAO
          from PCFIGURATRIBDESONICMS
          where CST = PCST
            AND CODFILIAL = PCODFILIAL
            AND TIPOCLIENTE = 'NI';
        end if;
      exception
        when others then
            return null;
      end;
    end;


    begin
        select NVL(min(EX.MOTIVODESONERACAO), 0)
        into VMOVIVODESONERACAOEX
        from PCEXCECAODESONICMS EX
        where EX.CODFIGURADESONICMS = VCODTRIB
          and trim(EX.VALOR1) = pcodprod
          and EX.TIPO1    = 'CP';

        IF VMOVIVODESONERACAOEX = 0 THEN
            select NVL(min(EX.MOTIVODESONERACAO), 0)
            into VMOVIVODESONERACAOEX
            from PCEXCECAODESONICMS EX
            where EX.CODFIGURADESONICMS = VCODTRIB
              and trim(EX.VALOR1) =  PCODCLI
              and ex.tipo1 = 'CC';

       END IF;
    exception
      when others then
        VMOVIVODESONERACAOEX := 0;
    end;

    if VMOVIVODESONERACAOEX = 0 then
      return VMOTIVODESONERACAO;
    else
      return VMOVIVODESONERACAOEX;
    end if;
  end;

   -- PROCEDIMENTO PARA GRAVACAO DOS VALORES
   procedure GRAVAR_ITEM_PISCOFINS(PTABELAPREFAT               in boolean
                                  ,PROWID_PCMOV                in varchar
                                  ,PNUMTRANSITEM               in number
                                  ,PPISCOFINSDEDUZIDO          in varchar
                                  ,PCODTRIB                    in number
                                  ,PUSAPISCOFINSLIT            in varchar
                                  ,PQTLITRAGEM                 in number
                                  ,PBASEPISCOFINS              in number
                                  ,PPERPIS                     in number
                                  ,PPERCOFINS                  in number
                                  ,PVLPIS                      in number
                                  ,PVLCOFINS                   in number
                                  ,PCSTPISCOFINS               in number
                                  ,PDEVOLUCAO                  in boolean
                                  ,PALIQREDUCAOPIS             in number
                                  ,PALIQREDUCAOCOFINS          in number
                                  ,PENVIARALIQREDUCAOPISCOFINS in varchar
                                  ,PPERCREDBASCALPC            in number
                                  ,PVLBASEPISCOFINSEXIGIBSUSP  in number
                                  ,PVLPISEXIGIBSUSPENSA        in number
                                  ,PVLCOFINSEXIGIBSUSPENSA     in number
                                  ,PEXCLUIRICMSBASEPISCOFINS   in varchar
                                  ,PEXCLUIRDIFALBASEPISCOFINS   in varchar
                                  -- Campos Pcmov
                                  ,PVLBASEPISCOFINS_ATUAL in number
                                  ,PPERPIS_ATUAL          in number
                                  ,PPERCOFINS_ATUAL       in number
                                  ,PVLPIS_ATUAL           in number
                                  ,PVLCOFINS_ATUAL        in number
                                  ,PCODSITTRIBPISCOFINS_ATUAL in number
                                  -- Campos PcmovComple
                                  ,pPISCOFINSDEDUZIDO_ATUAL          in varchar2
                                  ,pCODTRIBPISCOFINS_ATUAL           in number
                                  ,pUSAPISCOFINSLIT_ATUAL            in varchar2
                                  ,pALIQREDUCAOPIS_ATUAL             in number
                                  ,pALIQREDUCAOCOFINS_ATUAL          in number
                                  ,pENVIARALIQREDUCAOPC_ATUAL in varchar2
                                  ,pQTLITRAGEM_ATUAL                 in number
                                  ,pPERCREDBASCALPC_ATUAL            in number
                                  ,pVLBASEPCEXIGIBSUSP_ATUAL  in number
                                  ,pVLPISEXIGIBSUSPENSA_ATUAL        in number
                                  ,pVLCOFINSEXIGIBSUSPENSA_ATUAL     in number
                                  ,pEXCLUIRICMSBASEPC_ATUAL   in varchar2
                                  ,pEXCLUIRDIFALBASEPC_ATUAL   in varchar2
                            ) is
   begin

     if PTABELAPREFAT then
         update PCMOVCOMPLEPREFAT
         set PISCOFINSDEDUZIDO          = PPISCOFINSDEDUZIDO
            ,CODTRIBPISCOFINS           = PCODTRIB
            ,USAPISCOFINSLIT            = PUSAPISCOFINSLIT
            ,ALIQREDUCAOPIS             = PALIQREDUCAOPIS
            ,ALIQREDUCAOCOFINS          = PALIQREDUCAOCOFINS
            ,ENVIARALIQREDUCAOPISCOFINS = PENVIARALIQREDUCAOPISCOFINS
            ,QTLITRAGEM                 = PQTLITRAGEM
            ,PERCREDBASCALPC            = PPERCREDBASCALPC
            ,VLBASEPISCOFINSEXIGIBSUSP  = PVLBASEPISCOFINSEXIGIBSUSP
            ,VLPISEXIGIBSUSPENSA        = PVLPISEXIGIBSUSPENSA
            ,VLCOFINSEXIGIBSUSPENSA     = PVLCOFINSEXIGIBSUSPENSA
            ,EXCLUIRICMSBASEPISCOFINS   = PEXCLUIRICMSBASEPISCOFINS
            ,EXCLUIRDIFALBASEPISCOFINS   = PEXCLUIRDIFALBASEPISCOFINS
       where NUMTRANSITEM = PNUMTRANSITEM
       AND DATACONSOLIDACAOPREFAT IS NULL;

       if PDEVOLUCAO
       then
          update PCMOVPREFAT
             set VLBASEPISCOFINS     = PBASEPISCOFINS
                ,PERPIS              = PPERPIS
                ,PERCOFINS           = PPERCOFINS
                ,VLCREDPIS           = PVLPIS
                ,VLCREDCOFINS        = PVLCOFINS
                ,CODSITTRIBPISCOFINS = PCSTPISCOFINS
           where rowid = PROWID_PCMOV
           AND DATACONSOLIDACAOPREFAT IS NULL;
       else
          update PCMOVPREFAT
             set VLBASEPISCOFINS     = PBASEPISCOFINS
                ,PERPIS              = PPERPIS
                ,PERCOFINS           = PPERCOFINS
                ,VLPIS               = PVLPIS
                ,VLCOFINS            = PVLCOFINS
                ,CODSITTRIBPISCOFINS = PCSTPISCOFINS
           where rowid = PROWID_PCMOV
           AND DATACONSOLIDACAOPREFAT IS NULL;
       end if;

     else
      -- GRAVAÇÃO -----------------------------------------------------
      -- So executar o update se pelo menos uma das colunas estiver diferente das atuais.
      if ((pPISCOFINSDEDUZIDO_ATUAL      <> PPISCOFINSDEDUZIDO         ) or
          (pCODTRIBPISCOFINS_ATUAL       <> PCODTRIB                   ) or
          (pUSAPISCOFINSLIT_ATUAL        <> PUSAPISCOFINSLIT           ) or
          (pALIQREDUCAOPIS_ATUAL         <> PALIQREDUCAOPIS            ) or
          (pALIQREDUCAOCOFINS_ATUAL      <> PALIQREDUCAOCOFINS         ) or
          (pENVIARALIQREDUCAOPC_ATUAL    <> PENVIARALIQREDUCAOPISCOFINS) or
          (pQTLITRAGEM_ATUAL             <> PQTLITRAGEM                ) or
          (pPERCREDBASCALPC_ATUAL        <> PPERCREDBASCALPC           ) or
          (pVLBASEPCEXIGIBSUSP_ATUAL     <> PVLBASEPISCOFINSEXIGIBSUSP ) or
          (pVLPISEXIGIBSUSPENSA_ATUAL    <> PVLPISEXIGIBSUSPENSA       ) or
          (pVLCOFINSEXIGIBSUSPENSA_ATUAL <> PVLCOFINSEXIGIBSUSPENSA    ) or
          (pEXCLUIRICMSBASEPC_ATUAL      <> PEXCLUIRICMSBASEPISCOFINS  ) or
          (pEXCLUIRDIFALBASEPC_ATUAL     <> PEXCLUIRDIFALBASEPISCOFINS )) then
      update PCMOVCOMPLE
         set PISCOFINSDEDUZIDO          = PPISCOFINSDEDUZIDO
            ,CODTRIBPISCOFINS           = PCODTRIB
            ,USAPISCOFINSLIT            = PUSAPISCOFINSLIT
            ,ALIQREDUCAOPIS             = PALIQREDUCAOPIS
            ,ALIQREDUCAOCOFINS          = PALIQREDUCAOCOFINS
            ,ENVIARALIQREDUCAOPISCOFINS = PENVIARALIQREDUCAOPISCOFINS
            ,QTLITRAGEM                 = PQTLITRAGEM
            ,PERCREDBASCALPC            = PPERCREDBASCALPC
            ,VLBASEPISCOFINSEXIGIBSUSP  = PVLBASEPISCOFINSEXIGIBSUSP
            ,VLPISEXIGIBSUSPENSA        = PVLPISEXIGIBSUSPENSA
            ,VLCOFINSEXIGIBSUSPENSA     = PVLCOFINSEXIGIBSUSPENSA
            ,EXCLUIRICMSBASEPISCOFINS   = PEXCLUIRICMSBASEPISCOFINS
            ,EXCLUIRDIFALBASEPISCOFINS  = PEXCLUIRDIFALBASEPISCOFINS
       where NUMTRANSITEM = PNUMTRANSITEM;
      end if;

     if PDEVOLUCAO
     then
        update PCMOV
           set VLBASEPISCOFINS     = PBASEPISCOFINS
              ,PERPIS              = PPERPIS
              ,PERCOFINS           = PPERCOFINS
              ,VLCREDPIS           = PVLPIS
              ,VLCREDCOFINS        = PVLCOFINS
              ,CODSITTRIBPISCOFINS = PCSTPISCOFINS
         where rowid = PROWID_PCMOV;
     else
      -- So executar o update se pelo menos uma das colunas estiver diferente das atuais.
      if ((PBASEPISCOFINS <> PVLBASEPISCOFINS_ATUAL) or
          (PPERPIS        <> PPERPIS_ATUAL ) or
          (PPERCOFINS     <> PPERCOFINS_ATUAL ) or
          (PVLPIS         <> PVLPIS_ATUAL ) or
          (PVLCOFINS      <> PVLCOFINS_ATUAL ) or
          (PCSTPISCOFINS  <> PCODSITTRIBPISCOFINS_ATUAL)  ) then

        update PCMOV
           set VLBASEPISCOFINS     = PBASEPISCOFINS
              ,PERPIS              = PPERPIS
              ,PERCOFINS           = PPERCOFINS
              ,VLPIS               = PVLPIS
              ,VLCOFINS            = PVLCOFINS
              ,CODSITTRIBPISCOFINS = PCSTPISCOFINS
         where rowid = PROWID_PCMOV;
       end if;
      end if;
     end if;
   end;
   -- PROCEDIMENTO PARA CALCULAR E VALIDAR ITENS
   function CALCULAR_ITEM_PISCOFINS(TABELAPREFAT      in boolean
                                   ,PIDREGISTRO       in varchar2
                                   ,PCODPROD          in number
                                   ,PNUMTRANSITEM     number
                                   ,PCODFISCAL        in number
                                   ,PNCM              in varchar2
                                   ,PCODOPER          in varchar2
                                   ,PCONDVENDA        in number
                                   ,PCONSUMIDOR       in varchar2
                                   ,PQTLITRAGEM       in number
                                   ,PQTCONT           in number
                                   ,PVLPRODUTO        in number
                                   ,PVLFRETE          in number
                                   ,PVLDESPESA        in number
                                   ,PVLSUFRAMA        in number
                                   ,PVLIPI            in number
                                   ,PVLST             in number
                                   ,PCODTRIB          in number
                                   ,PCLIENTESUFRAMA   in varchar2
                                   ,PPRODUTOIMPORTADO in varchar2
                                   ,PDEVOLUCAO        in boolean
                                   ,MSG               out varchar2
                                   ,PTIPOCLIENT       in varchar2
                                   ,PPISCOFINSCUM     in varchar2
                                   ,PFILIALORIGEM     in varchar2
                                   ,PDATAVIGENTE      in date
                                   ,PCODIGOCLIENTE    in varchar2
                                   ,PVLICMS           in number
                                   ,PVLFCPST          in number
                                   ,PVLFCPICMS        in number
                                   ,PVLICMSDESONERACAO in number
                                   ,PDATAOPER          in date
                                   ,PVLSTBCR           in number
                                   ,PVLBASEPISCOFINS_ATUAL in number
                                   ,PPERPIS_ATUAL          in number
                                   ,PPERCOFINS_ATUAL       in number
                                   ,PVLPIS_ATUAL           in number
                                   ,PVLCOFINS_ATUAL        in number
                                   ,PCODSITTRIBPISCOFINS_ATUAL in number
                                   ,pPISCOFINSDEDUZIDO_ATUAL          in varchar2
                                   ,pCODTRIBPISCOFINS_ATUAL           in number
                                   ,pUSAPISCOFINSLIT_ATUAL            in varchar2
                                   ,pALIQREDUCAOPIS_ATUAL             in number
                                   ,pALIQREDUCAOCOFINS_ATUAL          in number
                                   ,pENVIARALIQREDUCAOPC_ATUAL in varchar2
                                   ,pQTLITRAGEM_ATUAL                 in number
                                   ,pPERCREDBASCALPC_ATUAL            in number
                                   ,pVLBASEPCEXIGIBSUSP_ATUAL  in number
                                   ,pVLPISEXIGIBSUSPENSA_ATUAL        in number
                                   ,pVLCOFINSEXIGIBSUSPENSA_ATUAL     in number
                                   ,pEXCLUIRICMSBASEPC_ATUAL   in varchar2
                                   ,pAGREGARFCPBASEPISCOFINSSAIDA in varchar2
                                   ,pEXCLUIRDIFALBASEPC_ATUAL   in varchar2
                                   ,PVLDIFALIQUOTAS in number) return boolean is
      VCODTRIB                    number;
      VPERPIS                     number;
      VPERCOFINS                  number;
      VCSTPIS                     number;
      VCSTCOFINS                  number;
      VCSTDEV                     number;
      VTIPOTRIBUTACAO             varchar2(1);
      VBASEPISCOFINS              number;
      VVLBASEPISCOFINSEXIGIBSUSP  number;
      VVLPISEXIGIBSUSPENSA        number;
      VVLCOFINSEXIGIBSUSPENSA     number;
      VVLPIS                      number;
      VVLCOFINS                   number;
      VPISCOFINSDEDUZIDO          varchar2(1);
      VUSAPISCOFINSLIT            varchar2(1);
      VGERABASEPISCOFINSSEMALIQ   varchar2(1);
      VALIQREDUCAOPIS             number;
      VALIQREDUCAOCOFINS          number;
      VENVIARALIQREDUCAOPISCOFINS varchar2(1);
      VCONSIDERAPAUTAMINIMA       varchar2(1);
      V_CSTSAIDAPAUTAMIN          number;
      V_CSTDEVPAUTAMIN            number;
      V_PAUTAMINIMAPIS            number(22, 6);
      V_PAUTAMINIMACOFINS         number(22, 6);
      V_QTLITRAGEM                PCMOVCOMPLE.QTLITRAGEM%type;
      V_USAVIGENCIA               varchar2(1);
      V_DTINICIO_VIG              date;
      V_DTFIM_VIG                 date;
      V_ZERARBCCSTST              varchar2(1);
      V_PERCREDBASCALPC           NUMBER(12,4);
      V_CODEXCTRIBPISCOFINS       NUMBER;
      V_AGREGARFCPBASEPISCOFINSSAIDA VARCHAR2(1);
      V_EXCLUIRICMSBASEPISCOFINS  VARCHAR2(1);
      V_EXCLUIRDIFALBASEPISCOFINS VARCHAR2(1);
      VMENSAGEM PCTRIBPISCOFINS.MENSAGEMGERAL%type;
   begin
     -- Busca de Parâmetros
     V_AGREGARFCPBASEPISCOFINSSAIDA := pAGREGARFCPBASEPISCOFINSSAIDA;
      -- VERIFICAR SE É DOCUMENTO TV8
      IF PCODOPER = 'ED' AND PCONDVENDA = 8 THEN
         BEGIN
            SELECT NVL(CODEXCTRIBPISCOFINS,0)
            INTO V_CODEXCTRIBPISCOFINS
            FROM PCTRIBPISCOFINSVIGENCIA
            WHERE CODTRIBPISCOFINS = PCODTRIB
              AND PDATAOPER BETWEEN DTINICIO AND DTFINAL;
         EXCEPTION WHEN NO_DATA_FOUND THEN
            V_CODEXCTRIBPISCOFINS := 0;
         END;

         IF V_CODEXCTRIBPISCOFINS = 0 THEN
            BEGIN
               SELECT NVL(CODEXCTRIBPISCOFINS,0)
               INTO V_CODEXCTRIBPISCOFINS
               FROM PCTRIBPISCOFINS
               WHERE CODTRIBPISCOFINS = PCODTRIB;
            EXCEPTION WHEN NO_DATA_FOUND THEN
               V_CODEXCTRIBPISCOFINS := 0;
            END;
         END IF;
      END IF;
      -- VERIFICAR SE HÁ EXCEÇÃO TRIBUTAÇÃO -------------------------------------
      VCODTRIB := GET_CODTRIBEXCECAO_PISCOFINS(PCODTRIB
                                              ,PCODFISCAL
                                              ,PCODOPER
                                              ,PCONDVENDA
                                              ,PCLIENTESUFRAMA
                                              ,PPRODUTOIMPORTADO
                                              ,PTIPOCLIENT
                                              ,PPISCOFINSCUM
                                              ,PFILIALORIGEM
                                              ,PDATAVIGENTE
                                              ,PCODIGOCLIENTE
                                              ,V_CODEXCTRIBPISCOFINS
                                              ,PNCM);
      -- BUSCAR INFORMAÇOES DA FIGURA TRIBUTÁRIA -----------------------------------
      begin
         begin
            V_USAVIGENCIA := 'N';
            select DTINICIO,DTFINAL,PERPIS,PERCOFINS,CSTPIS,CSTCOFINS,TIPOTRIBUTACAO,CONSIDERAPAUTAMINIMA,VLBASEPISCOFINS
                  ,VLBASEPISCOFINSEXIGIBSUSP,VLPISLIT,VLCOFINSLIT,RETERPISCOFINS,CONSIDERAVLFIXOLIT,CST_DEV,MENSAGEM
                  ,GERABASEPISCOFINSSEMALIQ,ALIQREDUCAOPIS,ALIQREDUCAOCOFINS,ENVIARALIQREDUCAOPISCOFINS,SITTRIBUTPAUTAMIN
                  ,SITTRIBUTDEVPAUTAMIN,ZERARBCCSTST,PERCREDBASCALPC, EXCLUIRICMSBASEPISCOFINS, EXCLUIRDIFALBASEPISCOFINS
          into V_DTINICIO_VIG,V_DTFIM_VIG,VPERPIS,VPERCOFINS,VCSTPIS,VCSTCOFINS,VTIPOTRIBUTACAO,VCONSIDERAPAUTAMINIMA
                  ,VBASEPISCOFINS,VVLBASEPISCOFINSEXIGIBSUSP,VVLPIS,VVLCOFINS,VPISCOFINSDEDUZIDO,VUSAPISCOFINSLIT,VCSTDEV
                  ,VMENSAGEM,VGERABASEPISCOFINSSEMALIQ,VALIQREDUCAOPIS,VALIQREDUCAOCOFINS,VENVIARALIQREDUCAOPISCOFINS
                  ,V_CSTSAIDAPAUTAMIN,V_CSTDEVPAUTAMIN,V_ZERARBCCSTST,V_PERCREDBASCALPC,V_EXCLUIRICMSBASEPISCOFINS
                  ,V_EXCLUIRDIFALBASEPISCOFINS
              from (select DTINICIO
                          ,DTFINAL
                          ,case
                              when (PCONSUMIDOR = 'S')
                                   and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                               T.PERCPISCONSUMO
                              else
                               T.PERCPIS
                           end PERPIS
                          ,case
                              when (PCONSUMIDOR = 'S')
                                   and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                               T.PERCCOFINSCONSUMO
                              else
                               T.PERCCOFINS
                           end PERCOFINS
                          ,case
                              when (PCONSUMIDOR = 'S')
                                   and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                               T.SITTRIBUTCONSUMO
                              else
                               T.SITTRIBUT
                           end CSTPIS
                          ,case
                              when (PCONSUMIDOR = 'S')
                                   and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                               T.SITTRIBUTCONSUMO
                              else
                               T.SITTRIBUT
                           end CSTCOFINS
                          ,case
                              when T.CONSIDERAVLFIXOLIT = 'S' then
                               'L'
                              when T.CONSIDERAPAUTA = 'S' then
                               'P'
                              when T.CONSIDERAPRECOMERC = 'S' then
                               'M'
                              else
                               ''
                           end TIPOTRIBUTACAO
                          ,T.CONSIDERAPAUTAMINIMA
                          --------------------
                          ,(case
                              when T.CONSIDERAVLFIXOLIT = 'S' then T.BASEPISCOFINSLIT
                              when T.CONSIDERAPAUTA     = 'S' then GREATEST(NVL(T.VLPAUTAPIS, 0), NVL(T.VLPAUTACOFINS, 0))
                              when T.CONSIDERAPRECOMERC = 'S' then PVLPRODUTO + PVLICMSDESONERACAO +
                               DECODE(T.CONSIDERAIPI, 'S', PVLIPI, 0) +
                               DECODE(T.CONSIDERAST, 'S', PVLST, 0) +
                               DECODE(T.CONSIDERAST, 'S', PVLFCPST, 0) +
                               DECODE(T.CONSIDERAOUTRASDESP, 'S', PVLDESPESA, 0) +
                               DECODE(T.CONSIDERAFRETE, 'S', PVLFRETE, 0) -
                               DECODE(T.CONSIDERASUFRAMA, 'S', PVLSUFRAMA + PVLICMSDESONERACAO, 0)
                              else
                               0
                           end) -
                           --melhoria para subtair o valor do icms da base de pis/cofins
                           (case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                      (T.EXCLUIRICMSBASEPISCOFINS = 'S') then
                               case when (NVL((case
                                                    when T.CONSIDERAVLFIXOLIT = 'S' then T.BASEPISCOFINSLIT
                                                    when T.CONSIDERAPAUTA     = 'S' then GREATEST(NVL(T.VLPAUTAPIS, 0), NVL(T.VLPAUTACOFINS, 0))
                                                    when T.CONSIDERAPRECOMERC = 'S' then PVLPRODUTO + PVLICMSDESONERACAO +
                                                     DECODE(T.CONSIDERAIPI, 'S', PVLIPI, 0) +
                                                     DECODE(T.CONSIDERAST, 'S', PVLST, 0) +
                                                     DECODE(T.CONSIDERAST, 'S', PVLFCPST, 0) +
                                                     DECODE(T.CONSIDERAOUTRASDESP, 'S', PVLDESPESA, 0) +
                                                     DECODE(T.CONSIDERAFRETE, 'S', PVLFRETE, 0) -
                                                     DECODE(T.CONSIDERASUFRAMA, 'S', PVLSUFRAMA + PVLICMSDESONERACAO, 0)
                                              else
                                               0
                                              end), 0) > 0) then
                               (case when PCODFISCAL > 4999 then
                                     (ROUND(PQTCONT * PVLICMS,2) / PQTCONT)
                                 else PVLICMS end)

                                      + DECODE(V_AGREGARFCPBASEPISCOFINSSAIDA,'S', PVLFCPICMS, 0)
                               else
                                      0
                               end
                           else
                               0
                           end) - DECODE(T.EXCLUIRDIFALBASEPISCOFINS, 'S', PVLDIFALIQUOTAS, 0) -- DEDUÇÃO DO ICMS DIFAL DA BASE
                                - case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                            (T.EXCLUIRICMSSTBCRBASEPISCOFINS  = 'S') then
                                       PVLSTBCR
                                     else
                                       0
                                  end
                           AS VLBASEPISCOFINS
                           ------------------
                           ,(case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                       (T.EXCLUIRICMSBASEPISCOFINS = 'S') then
                              (case
                                when T.CONSIDERAVLFIXOLIT = 'S' then T.BASEPISCOFINSLIT
                                when T.CONSIDERAPAUTA     = 'S' then GREATEST(NVL(T.VLPAUTAPIS, 0), NVL(T.VLPAUTACOFINS, 0))
                                when T.CONSIDERAPRECOMERC = 'S' then PVLPRODUTO + PVLICMSDESONERACAO +
                                 DECODE(T.CONSIDERAIPI, 'S', PVLIPI, 0) +
                                 DECODE(T.CONSIDERAST, 'S', PVLST, 0) +
                                 DECODE(T.CONSIDERAST, 'S', PVLFCPST, 0) +
                                 DECODE(T.CONSIDERAOUTRASDESP, 'S', PVLDESPESA, 0) +
                                 DECODE(T.CONSIDERAFRETE, 'S', PVLFRETE, 0) -
                                 DECODE(T.CONSIDERASUFRAMA, 'S', PVLSUFRAMA + PVLICMSDESONERACAO, 0)
                              else
                                0
                              end)
                           else
                             0
                           end) VLBASEPISCOFINSEXIGIBSUSP
                           ------------------
                          ,T.VLPISLIT
                          ,T.VLCOFINSLIT
                          ,T.RETERPISCOFINS
                          ,T.CONSIDERAVLFIXOLIT
                          ,case
                              when (PCONSUMIDOR = 'S')
                                   and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                               T.SITTRIBUTCONSUMODEV
                              else
                               T.SITTRIBUTDEV
                           end CST_DEV
                          ,case
                              when (PCONSUMIDOR = 'S')
                                   and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                               T.MENSAGEMCONSUMO
                              else
                               T.MENSAGEMGERAL
                           end MENSAGEM
                          ,NVL(T.GERABASEPISCOFINSSEMALIQ, 'N') GERABASEPISCOFINSSEMALIQ
                          ,NVL(T.ALIQREDUCAOPIS, 0) ALIQREDUCAOPIS
                          ,NVL(T.ALIQREDUCAOCOFINS, 0) ALIQREDUCAOCOFINS
                          ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARALIQREDUCAOPISCOFINS'
                                                            ,VCODFILIAL)
                              ,'N') ENVIARALIQREDUCAOPISCOFINS
                          ,T.SITTRIBUTPAUTAMIN
                          ,T.SITTRIBUTDEVPAUTAMIN
                          ,NVL(T.ZERARBCCSTST,'N') ZERARBCCSTST
                          ,NVL(T.PERCREDBASCALPC,0) PERCREDBASCALPC
                          ,case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                      (T.EXCLUIRICMSBASEPISCOFINS = 'S') then
                              'S'
                            ELSE
                               'N'
                            END EXCLUIRICMSBASEPISCOFINS
                          ,T.EXCLUIRDIFALBASEPISCOFINS
                      from PCTRIBPISCOFINSVIGENCIA T
                     where T.CODTRIBPISCOFINS = VCODTRIB
                       and PDATAVIGENTE between T.DTINICIO and T.DTFINAL
                     order by T.DTFINAL desc)
             where ROWNUM = 1;
            -- USOU VIGENCIA
            V_USAVIGENCIA := 'S';
         exception
            when NO_DATA_FOUND then
               select case
                         when (PCONSUMIDOR = 'S')
                              and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                          T.PERCPISCONSUMO
                         else
                          T.PERCPIS
                      end PERPIS
                     ,case
                         when (PCONSUMIDOR = 'S')
                              and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                          T.PERCCOFINSCONSUMO
                         else
                          T.PERCCOFINS
                      end PERCOFINS
                     ,case
                         when (PCONSUMIDOR = 'S')
                              and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                          T.SITTRIBUTCONSUMO
                         else
                          T.SITTRIBUT
                      end CSTPIS
                     ,case
                         when (PCONSUMIDOR = 'S')
                              and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                          T.SITTRIBUTCONSUMO
                         else
                          T.SITTRIBUT
                      end CSTCOFINS
                     ,case
                         when T.CONSIDERAVLFIXOLIT = 'S' then
                          'L'
                         when T.CONSIDERAPAUTA = 'S' then
                          'P'
                         when T.CONSIDERAPRECOMERC = 'S' then
                          'M'
                         else
                          ''
                      end TIPOTRIBUTACAO
                     ,T.CONSIDERAPAUTAMINIMA
                     ------------------------------
                     ,(case
                         when T.CONSIDERAVLFIXOLIT = 'S' then
                            T.BASEPISCOFINSLIT
                         when T.CONSIDERAPAUTA     = 'S' then
                            GREATEST(NVL(T.VLPAUTAPIS, 0), NVL(T.VLPAUTACOFINS, 0))
                         when T.CONSIDERAPRECOMERC = 'S' then
                            PVLPRODUTO + PVLICMSDESONERACAO +
                            DECODE(T.CONSIDERAIPI, 'S', PVLIPI, 0) +
                            DECODE(T.CONSIDERAST, 'S', PVLST, 0) +
                            DECODE(T.CONSIDERAST, 'S', PVLFCPST, 0) +
                            DECODE(T.CONSIDERAOUTRASDESP, 'S', PVLDESPESA, 0) +
                            DECODE(T.CONSIDERAFRETE, 'S', PVLFRETE, 0) -
                            DECODE(T.CONSIDERASUFRAMA, 'S', PVLSUFRAMA + PVLICMSDESONERACAO, 0)
                         else
                            0
                      end) -
                      --melhoria para subtair o valor do icms da base de pis/cofins
                      (case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                 (T.EXCLUIRICMSBASEPISCOFINS = 'S') then
                               case when (NVL((case
                                                    when T.CONSIDERAVLFIXOLIT = 'S' then T.BASEPISCOFINSLIT
                                                    when T.CONSIDERAPAUTA     = 'S' then GREATEST(NVL(T.VLPAUTAPIS, 0), NVL(T.VLPAUTACOFINS, 0))
                                                    when T.CONSIDERAPRECOMERC = 'S' then PVLPRODUTO + PVLICMSDESONERACAO +
                                                     DECODE(T.CONSIDERAIPI, 'S', PVLIPI, 0) +
                                                     DECODE(T.CONSIDERAST, 'S', PVLST, 0) +
                                                     DECODE(T.CONSIDERAST, 'S', PVLFCPST, 0) +
                                                     DECODE(T.CONSIDERAOUTRASDESP, 'S', PVLDESPESA, 0) +
                                                     DECODE(T.CONSIDERAFRETE, 'S', PVLFRETE, 0) -
                                                     DECODE(T.CONSIDERASUFRAMA, 'S', PVLSUFRAMA + PVLICMSDESONERACAO, 0)
                                              else
                                               0
                                              end), 0) > 0) then
                               (case when PCODFISCAL > 4999 then
                                     (ROUND(PQTCONT * PVLICMS,2) / PQTCONT)
                                 else PVLICMS end)

                                      + DECODE(V_AGREGARFCPBASEPISCOFINSSAIDA,'S', PVLFCPICMS, 0)
                               else
                                      0
                               end
                      else
                          0
                      end) - DECODE(T.EXCLUIRDIFALBASEPISCOFINS, 'S', PVLDIFALIQUOTAS, 0) -- DEDUÇÃO DO ICMS DIFAL DA BASE
                           - case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                       (T.EXCLUIRICMSSTBCRBASEPISCOFINS  = 'S') then
                                 PVLSTBCR
                               else
                                 0
                             end
                      as VLBASEPISCOFINS
                      ------------------
                     ,(case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                 (T.EXCLUIRICMSBASEPISCOFINS = 'S') then
                        (case
                           when T.CONSIDERAVLFIXOLIT = 'S' then T.BASEPISCOFINSLIT
                           when T.CONSIDERAPAUTA     = 'S' then GREATEST(NVL(T.VLPAUTAPIS, 0), NVL(T.VLPAUTACOFINS, 0))
                           when T.CONSIDERAPRECOMERC = 'S' then PVLPRODUTO + PVLICMSDESONERACAO +
                            DECODE(T.CONSIDERAIPI, 'S', PVLIPI, 0) +
                            DECODE(T.CONSIDERAST, 'S', PVLST, 0) +
                            DECODE(T.CONSIDERAST, 'S', PVLFCPST, 0) +
                            DECODE(T.CONSIDERAOUTRASDESP, 'S', PVLDESPESA, 0) +
                            DECODE(T.CONSIDERAFRETE, 'S', PVLFRETE, 0) -
                            DECODE(T.CONSIDERASUFRAMA, 'S', PVLSUFRAMA + PVLICMSDESONERACAO, 0)
                        else
                          0
                        end)
                      else
                        0
                      end) VLBASEPISCOFINSEXIGIBSUSP
                      --------------------------------
                     ,T.VLPISLIT
                     ,T.VLCOFINSLIT
                     ,T.RETERPISCOFINS
                     ,T.CONSIDERAVLFIXOLIT
                     ,case
                         when (PCONSUMIDOR = 'S')
                              and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                          T.SITTRIBUTCONSUMODEV
                         else
                          T.SITTRIBUTDEV
                      end CST_DEV
                     ,case
                         when (PCONSUMIDOR = 'S')
                              and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                          T.MENSAGEMCONSUMO
                         else
                          T.MENSAGEMGERAL
                      end MENSAGEM
                     ,NVL(T.GERABASEPISCOFINSSEMALIQ, 'N') GERABASEPISCOFINSSEMALIQ
                     ,NVL(T.ALIQREDUCAOPIS, 0) ALIQREDUCAOPIS
                     ,NVL(T.ALIQREDUCAOCOFINS, 0) ALIQREDUCAOCOFINS
                     ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARALIQREDUCAOPISCOFINS', VCODFILIAL)
                         ,'N') ENVIARALIQREDUCAOPISCOFINS
                     ,T.SITTRIBUTPAUTAMIN
                     ,T.SITTRIBUTDEVPAUTAMIN
                     ,NVL(T.ZERARBCCSTST,'N')
                     ,NVL(T.PERCREDBASCALPC,0)
                     ,(case when (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, PDATAOPER) = 'S') AND
                                 (T.EXCLUIRICMSBASEPISCOFINS = 'S') then
                         'S'
                       ELSE
                          'N'
                       END) EXCLUIRICMSBASEPISCOFINS
                     ,T.EXCLUIRDIFALBASEPISCOFINS
                 into VPERPIS
                     ,VPERCOFINS
                     ,VCSTPIS
                     ,VCSTCOFINS
                     ,VTIPOTRIBUTACAO
                     ,VCONSIDERAPAUTAMINIMA
                     ,VBASEPISCOFINS
                     ,VVLBASEPISCOFINSEXIGIBSUSP
                     ,VVLPIS
                     ,VVLCOFINS
                     ,VPISCOFINSDEDUZIDO
                     ,VUSAPISCOFINSLIT
                     ,VCSTDEV
                     ,VMENSAGEM
                     ,VGERABASEPISCOFINSSEMALIQ
                     ,VALIQREDUCAOPIS
                     ,VALIQREDUCAOCOFINS
                     ,VENVIARALIQREDUCAOPISCOFINS
                     ,V_CSTSAIDAPAUTAMIN
                     ,V_CSTDEVPAUTAMIN
                     ,V_ZERARBCCSTST
                     ,V_PERCREDBASCALPC
                     ,V_EXCLUIRICMSBASEPISCOFINS
                     ,V_EXCLUIRDIFALBASEPISCOFINS
                 from PCTRIBPISCOFINS T
                where T.CODTRIBPISCOFINS = VCODTRIB;
               V_USAVIGENCIA := 'N';
            when others then
               raise;
         end;
      exception
        when NO_DATA_FOUND then
          MSG := 'Tributacao PIS/COFINS inexistente para o produto ' || PCODPROD ||
                 ', verificar cadastro na rotina 271 ou 574 conforme marcacao do parametro 1092 da rotina 132.';

          return false;

        when others then
           MSG := 'N:Erro ao calcular PIS/COFINS no item. ' || CHR(13) || 'Erro original: ' || sqlerrm;
           return false;
      end;
      -----------------------------------------------------------------
      -- VALIDAR O VALOR DA BASE PARA NOTAS FISCAIS COMPLEMENTARES.
      IF (VBASEPISCOFINS < 0) THEN
         VBASEPISCOFINS := 0;
      END IF;
      -----------------------------------------------------------------
      -- VALIDAR CST --------------------------------------------------
      if ((not PDEVOLUCAO) and (NVL(NVL(VCSTPIS, VCSTCOFINS), 0) <= 0))
         or ((PDEVOLUCAO) and (NVL(VCSTDEV, 0) <= 0))
      then
         MSG := 'N:CST PIS/COFINS não informado para tributação: ' || TO_CHAR(VCODTRIB) ||
                ' Produto relacionado: ' || PCODPROD;
         return false;
      end if;
      -----------------------------------------------------------------
      -- ACUMULAR MENSAGENS -------------------------------------------
      if VMENSAGEMPISCOFINS is null
      then
         VMENSAGEMPISCOFINS := VMENSAGEM;
      else
         if VMENSAGEMPISCOFINS not like '%' || VMENSAGEM || '%'
         then
            VMENSAGEMPISCOFINS := SUBSTR(VMENSAGEMPISCOFINS || CHR(13) || VMENSAGEM, 1, 4000);
         end if;
      end if;
      -----------------------------------------------------------------
      -- CALCULOS -----------------------------------------------------
      if NVL(VTIPOTRIBUTACAO, 'M') <> 'L'
      then
         if NVL(V_PERCREDBASCALPC,0) > 0 then
            VVLPIS    := (NVL(VBASEPISCOFINS,0) - (NVL(VBASEPISCOFINS,0) * V_PERCREDBASCALPC / 100)) * NVL(VPERPIS,0) / 100;
            VVLCOFINS := (NVL(VBASEPISCOFINS,0) - (NVL(VBASEPISCOFINS,0) * V_PERCREDBASCALPC / 100)) * NVL(VPERCOFINS,0) / 100;

            VVLPISEXIGIBSUSPENSA    := (NVL(VVLBASEPISCOFINSEXIGIBSUSP,0) - (NVL(VVLBASEPISCOFINSEXIGIBSUSP,0) * V_PERCREDBASCALPC / 100)) * NVL(VPERPIS,0) / 100;
            VVLCOFINSEXIGIBSUSPENSA := (NVL(VVLBASEPISCOFINSEXIGIBSUSP,0) - (NVL(VVLBASEPISCOFINSEXIGIBSUSP,0) * V_PERCREDBASCALPC / 100)) * NVL(VPERCOFINS,0) / 100;
         else
            VVLPIS    := NVL(VBASEPISCOFINS,0) * NVL(VPERPIS,0) / 100;
            VVLCOFINS := NVL(VBASEPISCOFINS,0) * NVL(VPERCOFINS,0) / 100;

            VVLPISEXIGIBSUSPENSA    := NVL(VVLBASEPISCOFINSEXIGIBSUSP,0) * NVL(VPERPIS,0) / 100;
            VVLCOFINSEXIGIBSUSPENSA := NVL(VVLBASEPISCOFINSEXIGIBSUSP,0) * NVL(VPERCOFINS,0) / 100;
         end if;
      end if;
      -----------------------------------------------------------------
      -- ZERAR BASE SE NÃO HOUVER VALORES E TIVER MARCADO NA ROTINA 4001 PRA NÃO GERAR O VALOR DA BASE DO PIS/COFINS
      if (NVL(VVLPIS, 0) = 0)
         and (NVL(VVLCOFINS, 0) = 0)
         and (NVL(VPERPIS, 0) = 0)
         and (NVL(VPERCOFINS, 0) = 0)
         and (VGERABASEPISCOFINSSEMALIQ = 'N')
      then
         VBASEPISCOFINS := 0;
      end if;
      -------------------------------------------------------------
      V_QTLITRAGEM := PQTLITRAGEM;
      -----------------------------------------------------------------
      -- VALIDAR PAUTA MINIMA
      if VTIPOTRIBUTACAO = 'M'
         and VCONSIDERAPAUTAMINIMA = 'S'
      then
         begin
            if V_USAVIGENCIA = 'S'
            then
               select VALORMINIMOPIS
                     ,VALORMINIMOCOFINS
                 into V_PAUTAMINIMAPIS
                     ,V_PAUTAMINIMACOFINS
                 from (select VALORMINIMOPIS
                             ,VALORMINIMOCOFINS
                         from PCPAUTAMINIMAPISCOFINSVIG
                        where CODTRIBPISCOFINS = VCODTRIB
                          and DTINICIO = V_DTINICIO_VIG
                          and DTFINAL = V_DTFIM_VIG
                          and NCM = PNCM
                        order by DTFINAL desc)
                where ROWNUM = 1;
            else
               select VALORMINIMOPIS
                     ,VALORMINIMOCOFINS
                 into V_PAUTAMINIMAPIS
                     ,V_PAUTAMINIMACOFINS
                 from PCPAUTAMINIMAPISCOFINS
                where CODTRIBPISCOFINS = VCODTRIB
                  and NCM = PNCM;
            end if;

            if (VVLPIS < (V_PAUTAMINIMAPIS * CASE WHEN NVL(PQTLITRAGEM, 0) = 0 THEN 1 ELSE PQTLITRAGEM END)
              or (VVLCOFINS < (V_PAUTAMINIMACOFINS * CASE WHEN NVL(PQTLITRAGEM, 0) = 0 THEN 1 ELSE PQTLITRAGEM END)))
            then
               VCSTPIS    := V_CSTSAIDAPAUTAMIN;
               VCSTCOFINS := V_CSTSAIDAPAUTAMIN;
               VCSTDEV    := V_CSTDEVPAUTAMIN;
               -----------------------------------------------------------------
               -- VALIDAR CST --------------------------------------------------
               if ((not PDEVOLUCAO) and (NVL(NVL(VCSTPIS, VCSTCOFINS), 0) <= 0))
                  or ((PDEVOLUCAO) and (NVL(VCSTDEV, 0) <= 0))
               then
                  MSG := 'N:CST PIS/COFINS Pauta Mìnima não informado para tributação: ' ||
                         TO_CHAR(VCODTRIB) || ' Produto relacionado: ' || PCODPROD;
                  return false;
               end if;

               VUSAPISCOFINSLIT := 'S';
               VVLPIS           := V_PAUTAMINIMAPIS;
               VVLCOFINS        := V_PAUTAMINIMACOFINS;
               V_QTLITRAGEM     := NVL(PQTLITRAGEM, 0);
               V_QTLITRAGEM     := GREATEST(V_QTLITRAGEM, 1);
            end if;
         exception
            when others then
               null;
         end;
      end if;
      -----------------------------------------------------------------
      -- Zerar o valor da Base do PIS/COFINS e do imposto também, deixando lançado apenas a alíquota do PIS/COFINS (Rotina 4001 campo ZERARBCCSTST). Além da marcação do parâmetro o CST do PIS/COFINS deverá ser igual a 05 ou 75.
      if ((V_ZERARBCCSTST = 'S') AND
          ((NVL(VCSTCOFINS,VCSTPIS) = 05) OR (VCSTDEV = 75))) then
         VVLPIS         := 0;
         VVLCOFINS      := 0;
         VBASEPISCOFINS := 0;
      end if;
      -----------------------------------------------------------------
      -- Verificar se existe redução na Base de Cálculo do PIS/COFINS
      IF (VBASEPISCOFINS > 0) AND (V_PERCREDBASCALPC > 0) THEN
         VBASEPISCOFINS := VBASEPISCOFINS - (NVL(VBASEPISCOFINS,0) * V_PERCREDBASCALPC / 100);
      END IF;
      -----------------------------------------------------------------
      -- GRAVAR VALORES
      GRAVAR_ITEM_PISCOFINS(TABELAPREFAT
                           ,PIDREGISTRO
                           ,PNUMTRANSITEM
                           ,VPISCOFINSDEDUZIDO
                           ,VCODTRIB
                           ,VUSAPISCOFINSLIT
                           ,V_QTLITRAGEM
                           ,VBASEPISCOFINS
                           ,VPERPIS
                           ,VPERCOFINS
                           ,VVLPIS
                           ,VVLCOFINS
                           ,case when PDEVOLUCAO then VCSTDEV else NVL(VCSTPIS, VCSTCOFINS) end
                           ,PDEVOLUCAO
                           ,VALIQREDUCAOPIS
                           ,VALIQREDUCAOCOFINS
                           ,VENVIARALIQREDUCAOPISCOFINS
                           ,V_PERCREDBASCALPC
                           ,VVLBASEPISCOFINSEXIGIBSUSP
                           ,VVLPISEXIGIBSUSPENSA
                           ,VVLCOFINSEXIGIBSUSPENSA
                           ,V_EXCLUIRICMSBASEPISCOFINS
                           ,V_EXCLUIRDIFALBASEPISCOFINS
                           -- Colunas Pcmov
                           ,PVLBASEPISCOFINS_ATUAL
                           ,PPERPIS_ATUAL
                           ,PPERCOFINS_ATUAL
                           ,PVLPIS_ATUAL
                           ,PVLCOFINS_ATUAL
                           ,PCODSITTRIBPISCOFINS_ATUAL
                           -- Colunas PcmovComple
                           ,pPISCOFINSDEDUZIDO_ATUAL
                           ,pCODTRIBPISCOFINS_ATUAL
                           ,pUSAPISCOFINSLIT_ATUAL
                           ,pALIQREDUCAOPIS_ATUAL
                           ,pALIQREDUCAOCOFINS_ATUAL
                           ,pENVIARALIQREDUCAOPC_ATUAL
                           ,pQTLITRAGEM_ATUAL
                           ,pPERCREDBASCALPC_ATUAL
                           ,pVLBASEPCEXIGIBSUSP_ATUAL
                           ,pVLPISEXIGIBSUSPENSA_ATUAL
                           ,pVLCOFINSEXIGIBSUSPENSA_ATUAL
                           ,pEXCLUIRICMSBASEPC_ATUAL
                           ,pEXCLUIRDIFALBASEPC_ATUAL);
      -- CONFIRMANDO OPERACAO -----------------------------------------
      VVLPIS_NF    := VVLPIS_NF + ROUND(PQTCONT * VVLPIS, 2);
      VVLCOFINS_NF := VVLCOFINS_NF + ROUND(PQTCONT * VVLCOFINS, 2);
      return true;
   end;
   -- PROCEDIMENTO PARA CALCULO DE PIS/COFINS PARA VENDA
   function CALCULARPISCOFINS_VENDA(NUMTRANSACAO in number
                                   ,MSG          out varchar2) return varchar2 is
      VFALHATRIBUTACAO exception;
      VMSG_REGIAO      varchar2(40);
      VMSG_ITEM        varchar2(1000);
      VDESPESA_RATEADA varchar2(1);
      VMENSAGENS       varchar2(4000);
      V_GERABASENORMALQUANDOST varchar2(1);
      V_UFFILIAL       varchar2(2);
      V_DTSAIDA        date;
      V_FINALIDADE     VARCHAR2(1);
      V_AGREGARFCPBASEPISCOFINSSAIDA VARCHAR2(1);
   begin
     -- PEGANDO CODFILIAL DA NOTA FISCAL ------------------------------
      begin
        WITH NFSAID AS (
          SELECT NVL(CODFILIALNF, CODFILIAL) CODFILIAL
               ,DESPESASRATEADA
               ,DTSAIDA
               ,NVL(FINALIDADENFE, 'N') AS FINALIDADENFE
           FROM PCNFSAID
          WHERE NUMTRANSVENDA = NUMTRANSACAO
          UNION ALL
          SELECT NVL(CODFILIALNF, CODFILIAL) CODFILIAL
               ,DESPESASRATEADA
               ,DTSAIDA
               ,NVL(FINALIDADENFE, 'N') AS FINALIDADENFE
           FROM PCNFSAIDPREFAT
          WHERE NUMTRANSVENDA = NUMTRANSACAO
            AND DATACONSOLIDACAOPREFAT IS NULL
        )
        SELECT CODFILIAL
             , DESPESASRATEADA
             , DTSAIDA
             , FINALIDADENFE
          INTO VCODFILIAL
             , VDESPESA_RATEADA
             , V_DTSAIDA
             , V_FINALIDADE
          FROM NFSAID;

      exception
         when others then
            MSG := 'N:Nota Fiscal inexistente ou Cod.Filial não informado!';
            raise VFALHATRIBUTACAO;
      end;

      -- Nota complementar não deve calcular pis/cofins
      if (V_FINALIDADE = 'C') then
        MSG := 'Nota fiscal complementar não deve calcular pis/cofins!';
        return 'S';
      end if;

      -- Atualizar pcnfsaid se parâmetro 4085(EXCLUIRICMSBASEPISCOFINS) como Sim.
      if (PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, V_DTSAIDA)='S') then
         update PCNFSAID
            set DEDUZIRICMSBASEPISCOFINS = 'S'
          where NUMTRANSVENDA = NUMTRANSACAO;
      end if;

      -- Buscando parâmetro da filial
      begin
        select F.UF,
               NVL(F.GERABASENORMALQUANDOST, 'S')
          into V_UFFILIAL,
               V_GERABASENORMALQUANDOST
        from PCFILIAL F
       where F.CODIGO = VCODFILIAL;
     exception
         when NO_DATA_FOUND then
            MSG := 'Dados da Filial Inexistente ou Cód.Filial Não Informado!';
            raise VFALHATRIBUTACAO;
      end;
      -----------------------------------------

      -- VALIDANDO TIPO DE NOTA FISCAL (SEM ITENS N?O ? CONTEMPLADO) ----
      begin
        WITH MOV AS (
         SELECT NVL(CODFILIALNF, CODFILIAL) CODFILIAL
           FROM PCMOV
          WHERE NUMTRANSVENDA = NUMTRANSACAO
            and ROWNUM = 1
          UNION ALL
         SELECT NVL(CODFILIALNF, CODFILIAL) CODFILIAL
           FROM PCMOVPREFAT
          WHERE NUMTRANSVENDA = NUMTRANSACAO
            AND DATACONSOLIDACAOPREFAT IS NULL
            and ROWNUM = 1
        )
         SELECT CODFILIAL
           INTO VCODFILIAL
           FROM MOV;

      exception
         when others then
            MSG := 'S:Nota Fiscal sem item! O procedimento não contempla este tipo de documento.';
            return 'S';
      end;

      -- VERIFICANDO SE A FILIAL UTILIZA PIS/COFINS POR FIGURA TRIBUTÁRIA ---
      if not UTILIZA_FIGURA_PISCOFINS(MSG)
      then
         return 'S';
      end if;

      VVLPIS_NF    := 0;
      VVLCOFINS_NF := 0;
      VMENSAGENS   := '';

      -- Busca de Parâmetros
       V_AGREGARFCPBASEPISCOFINSSAIDA := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGARFCPBASEPISCOFINSSAIDA', VCODFILIAL);

      -- PERCORRER ITENS DA NOTA PARA CALCULO- ----------------------------
      for DADOS in (select N.CONDVENDA
                          ,N.DTSAIDA
                          ,C.CONSUMIDORFINAL
                          ,case
                              when (trim(C.SULFRAMA) is not null and C.DTVENCSUFRAMA >= N.DTSAIDA) then
                               'S'
                              else
                               'N'
                           end CLI_SUFRAMA
                          ,case
                              when NVL(M.IMPORTADO, PD.IMPORTADO) in ('S', 'D') then
                               'S'
                              else
                               'N'
                           end PROD_IMPORTADO
                          ,M.ROWID IDREGISTRO
                          ,M.CODPROD
                          ,M.NUMTRANSITEM
                          ,M.CODFISCAL
                          ,M.NBM as NCM
                          ,NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
                          ,M.CODOPER
                          ,MC.QTLITRAGEM
                          ,M.QTCONT
                          ,NVL(M.VLIPI, 0) VLIPI
                          ,NVL(M.ST, 0) ST
                          ,NVL(M.VLDESCSUFRAMA, 0) VLDESCSUFRAMA
                          ,M.PUNITCONT - NVL(M.ST, 0) - NVL(MC.VLFECP, 0) - NVL(M.VLIPI, 0) + NVL(M.VLDESCSUFRAMA, 0) VLPRODUTO
                          ,NVL(M.VLFRETE, 0) VLFRETE
                          ,NVL(M.VLOUTROS, 0) VLDESPESA
                          , NVL(PRC.NUMREGIAO,NVL(N.NUMREGIAO, PR.NUMREGIAO)) NUMREGIAO
                          ,DECODE(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBUTACAOPORUF')
                                 ,'S'
                                 ,(select CODTRIBPISCOFINS
                                    from PCTABTRIB T
                                   where T.CODPROD = M.CODPROD
                                     and T.CODFILIALNF = NVL(N.CODFILIALNF, N.CODFILIAL)
                                     and T.UFDESTINO = NVL(N.UF, C.ESTENT))
                                 ,(select CODTRIBPISCOFINS
                                    from PCTABPR T
                                   where T.CODPROD = M.CODPROD
                                     and T.NUMREGIAO =
                                         NVL(PRC.NUMREGIAO, NVL(N.NUMREGIAO, PR.NUMREGIAO)))) CODTRIBPISCOFINS
                          ,NVL(N.TIPOFJ, C.TIPOFJ) TIPOFJ
                          ,NVL(C.PISCOFINSCUMULATIVO, 'N') PISCOFINSCUMULATIVO
                          ,N.CODCLI
                         --,((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)) AS VLICMS
                          ,(CASE WHEN (M.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', NVL(N.CODFILIALNF, N.CODFILIAL)) = 'N') AND
                                  PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', NVL(N.CODFILIALNF,  N.CODFILIAL)) IN  ('E', 'S') THEN
                                0
                           ELSE
                                ((DECODE(CASE WHEN NVL(C.TIPOCLIMED,'X') IN ('D','E','M') AND
                                                                                        (NVL(PCPEDC.ROTINA,'X') = 'PCMED316') THEN
                                                       'S'
                                                     ELSE
                                                       'N'
                                                     END,
                                              'S', NVL(M.VLDESCRODAPE, 0), 0) +
                                          NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0))
                                           * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100))
                                 -
                                ((DECODE(CASE WHEN NVL(C.TIPOCLIMED,'X') IN ('D','E','M') AND
                                                                                              (NVL(PCPEDC.ROTINA,'X') = 'PCMED316') THEN
                                                             'S'
                                                           ELSE
                                                             'N'
                                                           END,
                                                    'S', NVL(M.VLDESCRODAPE, 0), 0) +
                                          NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0))
                                           * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100) *
                                        (NVL(MC.PERDIFEREIMENTOICMS,NVL(M.PERCDESCICMSDIF,0))/100))

                            END) AS VLICMS
                          -------------------- // ------------------
                          ,NVL(MC.VLACRESCIMOFUNCEP, 0) AS VLFCPICMS
                          ,NVL(MC.VLFECP, 0) AS VLFCPST
                          ,'N' PREFATURAMENTO
                          ,NVL(MC.VLICMSDESONERACAO,0)  VLICMSDESONERACAO
                          ,DECODE(M.SITTRIBUT,'60',NVL(M.STBCR, 0),0) AS VLSTBCR
                          ,NVL(M.VLBASEPISCOFINS,0)     VLBASEPISCOFINS_ATUAL
                          ,NVL(M.PERPIS,0)              PERPIS_ATUAL
                          ,NVL(M.PERCOFINS,0)           PERCOFINS_ATUAL
                          ,NVL(M.VLPIS,0)               VLPIS_ATUAL
                          ,NVL(M.VLCOFINS,0)            VLCOFINS_ATUAL
                          ,NVL(M.CODSITTRIBPISCOFINS,0)            CODSITTRIBPISCOFINS_ATUAL
                          ,NVL(MC.PISCOFINSDEDUZIDO,'X')           PISCOFINSDEDUZIDO_ATUAL
                          ,MC.CODTRIBPISCOFINS                     CODTRIBPISCOFINS_ATUAL
                          ,NVL(MC.USAPISCOFINSLIT,'X')             USAPISCOFINSLIT_ATUAL
                          ,NVL(MC.ALIQREDUCAOPIS,0)                ALIQREDUCAOPIS_ATUAL
                          ,NVL(MC.ALIQREDUCAOCOFINS,0)             ALIQREDUCAOCOFINS_ATUAL
                          ,NVL(MC.ENVIARALIQREDUCAOPISCOFINS,'X')  ENVIARALIQREDUCAOPC_ATUAL
                          ,NVL(MC.QTLITRAGEM,0)                    QTLITRAGEM_ATUAL
                          ,NVL(MC.PERCREDBASCALPC,0)               PERCREDBASCALPC_ATUAL
                          ,NVL(MC.VLBASEPISCOFINSEXIGIBSUSP,0)     VLBASEPCEXIGIBSUSP_ATUAL
                          ,NVL(MC.VLPISEXIGIBSUSPENSA,0)           VLPISEXIGIBSUSPENSA_ATUAL
                          ,NVL(MC.VLCOFINSEXIGIBSUSPENSA,0)        VLCOFINSEXIGIBSUSPENSA_ATUAL
                          ,NVL(MC.EXCLUIRICMSBASEPISCOFINS,'X')    EXCLUIRICMSBASEPC_ATUAL
                          ,NVL(MC.EXCLUIRDIFALBASEPISCOFINS,'X')   EXCLUIRDIFALBASEPC_ATUAL
                          ,NVL(MC.VLICMSPARTDEST,0)                 VLICMSPARTDEST
                      from PCNFSAID    N
                          ,PCMOV       M
                          ,PCMOVCOMPLE MC
                          ,PCCLIENT    C
                          ,PCPRACA     PR
                          ,PCPRODUT    PD
                          ,PCTABPRCLI  PRC
                          ,PCPEDC
                          ,PCFILIAL F
                     where N.NUMTRANSVENDA = NUMTRANSACAO
                       and M.NUMTRANSVENDA = N.NUMTRANSVENDA
                       and PD.CODPROD = M.CODPROD
                       and NVL(N.CODCLINF, N.CODCLI) = PRC.CODCLI(+)
                       and NVL(N.CODFILIALNF, N.CODFILIAL) = PRC.CODFILIALNF(+)
                       and NVL(M.CODFILIALNF, M.CODFILIAL) =  NVL(N.CODFILIALNF, N.CODFILIAL)
                       and COALESCE(N.CODFILIALNF, N.CODFILIAL) = F.CODIGO
                       and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                       and C.CODCLI = DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF)
                       and PR.CODPRACA(+) = C.CODPRACA
                       AND N.NUMPED = PCPEDC.NUMPED(+)
                       and M.STATUS in ('A', 'AB')
                       and M.QTCONT > 0
                       and M.DTCANCEL is null
                       and N.DTCANCEL is null
                       and (not exists (select 1 from PCLISTAPROD_TMP) or exists
                            (select 1 from PCLISTAPROD_TMP where CODPROD = M.CODPROD))
                   UNION ALL
                   select N.CONDVENDA
                          ,N.DTSAIDA
                          ,C.CONSUMIDORFINAL
                          ,case
                              when (trim(C.SULFRAMA) is not null and C.DTVENCSUFRAMA >= N.DTSAIDA) then
                               'S'
                              else
                               'N'
                           end CLI_SUFRAMA
                          ,case
                              when NVL(M.IMPORTADO, PD.IMPORTADO) in ('S', 'D') then
                               'S'
                              else
                               'N'
                           end PROD_IMPORTADO
                          ,M.ROWID IDREGISTRO
                          ,M.CODPROD
                          ,M.NUMTRANSITEM
                          ,M.CODFISCAL
                          ,M.NBM as NCM
                          ,NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
                          ,M.CODOPER
                          ,MC.QTLITRAGEM
                          ,M.QTCONT
                          ,NVL(M.VLIPI, 0) VLIPI
                          ,NVL(M.ST, 0) ST
                          ,NVL(M.VLDESCSUFRAMA, 0) VLDESCSUFRAMA
                          ,M.PUNITCONT - NVL(M.ST, 0) - NVL(MC.VLFECP, 0) - NVL(M.VLIPI, 0) + NVL(M.VLDESCSUFRAMA, 0) VLPRODUTO
                          ,NVL(M.VLFRETE, 0) VLFRETE
                          ,NVL(M.VLOUTROS, 0) VLDESPESA
                          , NVL(PRC.NUMREGIAO,NVL(N.NUMREGIAO, PR.NUMREGIAO)) NUMREGIAO
                          ,DECODE(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBUTACAOPORUF')
                                 ,'S'
                                 ,(select CODTRIBPISCOFINS
                                    from PCTABTRIB T
                                   where T.CODPROD = M.CODPROD
                                     and T.CODFILIALNF = NVL(N.CODFILIALNF, N.CODFILIAL)
                                     and T.UFDESTINO = NVL(N.UF, C.ESTENT))
                                 ,(select CODTRIBPISCOFINS
                                    from PCTABPR T
                                   where T.CODPROD = M.CODPROD
                                     and T.NUMREGIAO =
                                         NVL(PRC.NUMREGIAO, NVL(N.NUMREGIAO, PR.NUMREGIAO)))) CODTRIBPISCOFINS
                          ,NVL(N.TIPOFJ, C.TIPOFJ) TIPOFJ
                          ,NVL(C.PISCOFINSCUMULATIVO, 'N') PISCOFINSCUMULATIVO
                          ,N.CODCLI
                          --Cálculo do valor do icms conforme livro fiscal
--                          ,((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)) AS VLICMS
                          ,CASE WHEN (M.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', NVL(N.CODFILIALNF, N.CODFILIAL)) = 'N') AND
                                  PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', NVL(N.CODFILIALNF, N.CODFILIAL)) IN  ('E', 'S') THEN
                                0
                           ELSE
                                ((DECODE(CASE WHEN NVL(C.TIPOCLIMED,'X') IN ('D','E','M') AND
                                                                                        (NVL(PCPEDC.ROTINA,'X') = 'PCMED316') THEN
                                                       'S'
                                                     ELSE
                                                       'N'
                                                     END, 'S', NVL(M.VLDESCRODAPE, 0), 0) +
                                          NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0))
                                           * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100))
                                 -
                                ((DECODE(CASE WHEN NVL(C.TIPOCLIMED,'X') IN ('D','E','M') AND
                                                                                              (NVL(PCPEDC.ROTINA,'X') = 'PCMED316') THEN
                                                             'S'
                                                           ELSE
                                                             'N'
                                                           END, 'S', NVL(M.VLDESCRODAPE, 0), 0) +
                                          NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0))
                                           * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100) *
                                        (NVL(MC.PERDIFEREIMENTOICMS,NVL(M.PERCDESCICMSDIF,0))/100))

                            END AS VLICMS
                          ,NVL(MC.VLACRESCIMOFUNCEP, 0) AS VLFCPICMS
                          ,NVL(MC.VLFECP, 0) AS VLFCPST
                          ,'S' PREFATURAMENTO
                          ,NVL(MC.VLICMSDESONERACAO,0) VLICMSDESONERACAO
                          ,DECODE(M.SITTRIBUT,'60',NVL(M.STBCR, 0),0) AS VLSTBCR
                          ,NVL(M.VLBASEPISCOFINS,0)     VLBASEPISCOFINS_ATUAL
                          ,NVL(M.PERPIS,0)              PERPIS_ATUAL
                          ,NVL(M.PERCOFINS,0)           PERCOFINS_ATUAL
                          ,NVL(M.VLPIS,0)               VLPIS_ATUAL
                          ,NVL(M.VLCOFINS,0)            VLCOFINS_ATUAL
                          ,M.CODSITTRIBPISCOFINS                   CODSITTRIBPISCOFINS_ATUAL
                          ,NVL(MC.PISCOFINSDEDUZIDO,'X')           PISCOFINSDEDUZIDO_ATUAL
                          ,NVL(MC.CODTRIBPISCOFINS,0)              CODTRIBPISCOFINS_ATUAL
                          ,NVL(MC.USAPISCOFINSLIT,'X')             USAPISCOFINSLIT_ATUAL
                          ,NVL(MC.ALIQREDUCAOPIS,0)                ALIQREDUCAOPIS_ATUAL
                          ,NVL(MC.ALIQREDUCAOCOFINS,0)             ALIQREDUCAOCOFINS_ATUAL
                          ,NVL(MC.ENVIARALIQREDUCAOPISCOFINS,'X')  ENVIARALIQREDUCAOPC_ATUAL
                          ,NVL(MC.QTLITRAGEM,0)                    QTLITRAGEM_ATUAL
                          ,NVL(MC.PERCREDBASCALPC,0)               PERCREDBASCALPC_ATUAL
                          ,NVL(MC.VLBASEPISCOFINSEXIGIBSUSP,0)     VLBASEPCEXIGIBSUSP_ATUAL
                          ,NVL(MC.VLPISEXIGIBSUSPENSA,0)           VLPISEXIGIBSUSPENSA_ATUAL
                          ,NVL(MC.VLCOFINSEXIGIBSUSPENSA,0)        VLCOFINSEXIGIBSUSPENSA_ATUAL
                          ,NVL(MC.EXCLUIRICMSBASEPISCOFINS,'X')    EXCLUIRICMSBASEPC_ATUAL
                          ,NVL(MC.EXCLUIRDIFALBASEPISCOFINS,'X')   EXCLUIRDIFALBASEPC_ATUAL
                          ,NVL(MC.VLICMSPARTDEST,0)                 VLICMSPARTDEST
                      from PCNFSAIDPREFAT    N
                          ,PCMOVPREFAT       M
                          ,PCMOVCOMPLEPREFAT MC
                          ,PCCLIENT    C
                          ,PCPRACA     PR
                          ,PCPRODUT    PD
                          ,PCTABPRCLI  PRC
                          ,PCPEDC
                     where N.NUMTRANSVENDA = NUMTRANSACAO
                       and M.NUMTRANSVENDA = N.NUMTRANSVENDA
                       and PD.CODPROD = M.CODPROD
                       and NVL(N.CODCLINF, N.CODCLI) = PRC.CODCLI(+)
                       and NVL(N.CODFILIALNF, N.CODFILIAL) = PRC.CODFILIALNF(+)
                       and NVL(M.CODFILIALNF, M.CODFILIAL) =  NVL(N.CODFILIALNF, N.CODFILIAL)
                       and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                       and C.CODCLI = DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF)
                       and PR.CODPRACA(+) = C.CODPRACA
                       AND N.NUMPED = PCPEDC.NUMPED(+)
                       and M.STATUS in ('A', 'AB')
                       and M.QTCONT > 0
                       and M.DTCANCEL is null
                       and N.DTCANCEL is null
                       and (not exists (select 1 from PCLISTAPROD_TMP) or exists
                            (select 1 from PCLISTAPROD_TMP where CODPROD = M.CODPROD))
                       AND N.DATACONSOLIDACAOPREFAT IS NULL
                       AND M.DATACONSOLIDACAOPREFAT IS NULL
                       AND MC.DATACONSOLIDACAOPREFAT IS NULL)
      loop
         VMSG_REGIAO := 'N:Núm. Região: ' || DADOS.NUMREGIAO;

         -- CALCULAR E GRAVAR ITEM -----------------------------------------
         if not CALCULAR_ITEM_PISCOFINS(DADOS.PREFATURAMENTO = 'S'
                                       ,DADOS.IDREGISTRO
                                       ,DADOS.CODPROD
                                       ,DADOS.NUMTRANSITEM
                                       ,DADOS.CODFISCAL
                                       ,DADOS.NCM
                                       ,DADOS.CODOPER
                                       ,DADOS.CONDVENDA
                                       ,DADOS.CONSUMIDORFINAL
                                       ,DADOS.QTLITRAGEM
                                       ,DADOS.QTCONT
                                       ,DADOS.VLPRODUTO
                                       ,DADOS.VLFRETE
                                       ,DADOS.VLDESPESA
                                       ,DADOS.VLDESCSUFRAMA
                                       ,DADOS.VLIPI
                                       ,DADOS.ST
                                       ,DADOS.CODTRIBPISCOFINS
                                       ,DADOS.CLI_SUFRAMA
                                       ,DADOS.PROD_IMPORTADO
                                       ,false
                                       ,VMSG_ITEM
                                       ,DADOS.TIPOFJ
                                       ,DADOS.PISCOFINSCUMULATIVO
                                       ,DADOS.CODFILIAL
                                       ,DADOS.DTSAIDA
                                       ,DADOS.CODCLI
                                       ,DADOS.VLICMS
                                       ,DADOS.VLFCPST
                                       ,DADOS.VLFCPICMS
                                       ,DADOS.VLICMSDESONERACAO
                                       ,DADOS.DTSAIDA
                                       ,DADOS.VLSTBCR
                                       -- DADOS PCMOV
                                       ,DADOS.VLBASEPISCOFINS_ATUAL
                                       ,DADOS.PERPIS_ATUAL
                                       ,DADOS.PERCOFINS_ATUAL
                                       ,DADOS.VLPIS_ATUAL
                                       ,DADOS.VLCOFINS_ATUAL
                                       ,DADOS.CODSITTRIBPISCOFINS_ATUAL
                                       -- DADOS PCMOVCOMPLE
                                       ,DADOS.PISCOFINSDEDUZIDO_ATUAL
                                       ,DADOS.CODTRIBPISCOFINS_ATUAL
                                       ,DADOS.USAPISCOFINSLIT_ATUAL
                                       ,DADOS.ALIQREDUCAOPIS_ATUAL
                                       ,DADOS.ALIQREDUCAOCOFINS_ATUAL
                                       ,DADOS.ENVIARALIQREDUCAOPC_ATUAL
                                       ,DADOS.QTLITRAGEM_ATUAL
                                       ,DADOS.PERCREDBASCALPC_ATUAL
                                       ,DADOS.VLBASEPCEXIGIBSUSP_ATUAL
                                       ,DADOS.VLPISEXIGIBSUSPENSA_ATUAL
                                       ,DADOS.VLCOFINSEXIGIBSUSPENSA_ATUAL
                                       ,DADOS.EXCLUIRICMSBASEPC_ATUAL
                                       ,V_AGREGARFCPBASEPISCOFINSSAIDA
                                       ,DADOS.EXCLUIRDIFALBASEPC_ATUAL
                                       ,DADOS.VLICMSPARTDEST)
         then
            if LENGTH(VMENSAGENS || CHR(13) || VMSG_ITEM) <= 3800
            then
               VMENSAGENS := VMENSAGENS || CHR(13) || VMSG_ITEM;
            end if;
            -- raise VFALHATRIBUTACAO;
         end if;
      end loop;

      ----------------------------------------------------------------------
      if NVL(VMENSAGENS, ':') <> ':'
      then
         if LENGTH(VMENSAGENS) >= 3800
         then
            VMENSAGENS := VMSG_REGIAO || SUBSTR(VMENSAGENS, 1, 3800) || '...';
         end if;
         MSG := VMSG_REGIAO || VMENSAGENS;
      else
         -- GRAVAR MENSAGENS PIS/COFINS NA NOTA FISCAL ------------------------
        update PCNFSAIDPREFAT
            set MENSAGEMPISCOFINS = VMENSAGEMPISCOFINS
               ,VLPIS             = VVLPIS_NF
               ,VLCOFINS          = VVLCOFINS_NF
          where NUMTRANSVENDA = NUMTRANSACAO
            AND DATACONSOLIDACAOPREFAT IS NULL;

        if sql%rowcount = 0 then
           update PCNFSAID
              set MENSAGEMPISCOFINS = VMENSAGEMPISCOFINS
                 ,VLPIS             = VVLPIS_NF
                 ,VLCOFINS          = VVLCOFINS_NF
            where NUMTRANSVENDA = NUMTRANSACAO;
         end if;

         MSG := 'S:PIS/COFINS calculado.';
      end if;

      return 'S';
   exception
      when VFALHATRIBUTACAO then
         return 'S';

      when others then
         MSG := 'S:Erro ao calcular PIS/COFINS. ' || CHR(13) || 'Erro original: ' || sqlerrm;
         return 'S';
   end;

   -- PROCEDIMENTO PARA CALCULO DE PIS/COFINS PARA DEVOLUCAO
   function CALCULARPISCOFINS_DEVOLUCAO(NUMTRANSACAO in number
                                       ,MSG          out varchar2) return varchar2 is
      VFALHATRIBUTACAO exception;
      VREPLICOU_VENDA  boolean;
      VDESPESA_RATEADA varchar2(1);
      VMSG_ITEM        varchar2(1000);
      VMENSAGENS       varchar2(4000);
      V_AGREGARFCPBASEPISCOFINSSAIDA VARCHAR2(1);
   begin

      -- PEGANDO CODFILIAL DA NOTA FISCAL ------------------------------
      begin
         select NVL(CODFILIALNF, CODFILIAL)
               ,DESPESASRATEADA
           into VCODFILIAL
               ,VDESPESA_RATEADA
           from PCNFENT
          where NUMTRANSENT = NUMTRANSACAO
            and ROWNUM = 1;
      exception
         when others then
            MSG := 'N:Nota Fiscal inexistente ou Cod.Filial não informado!';
            return 'N';
      end;

      -- VALIDANDO TIPO DE NOTA FISCAL (SEM ITENS NÃO É CONTEMPLADO) ----
      begin
         select NVL(CODFILIALNF, CODFILIAL)
           into VCODFILIAL
           from PCMOV
          where NUMTRANSENT = NUMTRANSACAO
            and ROWNUM = 1;
      exception
         when others then
            MSG := 'S:Nota Fiscal sem item! O procedimento não contempla este tipo de documento.';
            return 'S';
      end;

      -- RATEAR A DESPESA ACESSORIA SE AINDA NÃO ESTIVER RATEADA
      begin
         if NVL(VDESPESA_RATEADA, 'N') <> 'S'
         then
            CALCULAR_RATEIO_DESPESAS_DEVOL(NUMTRANSACAO, MSG);
         end if;
      exception
         when others then
            null;
      end;

      -- VERIFICANDO SE A FILIAL UTILIZA PIS/COFINS POR FIGURA TRIBUT?RIA ---
      if UPPER(SYS_CONTEXT('USERENV', 'MODULE')) not like '%PCSIS1000.EXE%'
      then
         if not UTILIZA_FIGURA_PISCOFINS(MSG)
         then
            return 'S';
         end if;
      end if;

      VREPLICOU_VENDA := false;

      VVLPIS_NF    := 0;
      VVLCOFINS_NF := 0;
      VMENSAGENS   := 'N:';

      V_AGREGARFCPBASEPISCOFINSSAIDA := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGARFCPBASEPISCOFINSSAIDA',
                                                                      VCODFILIAL);

      -- BUSCAR DADOS DA DEVOLU??O
      for DADOS in (select CODFILIAL
                          ,CODPROD
                          ,CONDVENDA
                          ,IDREGISTRO
                          ,NUMTRANSITEM
                          ,NUMTRANSENT
                          ,DTEMISSAO
                          ,CONSUMIDORFINAL
                          ,CODFISCAL
                          ,NBM NCM
                          ,CODOPER
                          ,QTLITRAGEM
                          ,QTCONT
                          ,VLPRODUTO
                          ,VLFRETE
                          ,VLDESPESA
                          ,VLIPI
                          ,ST
                          ,VLDESCSUFRAMA
                          ,VLBASEPISCOFINS
                          ,PERPIS
                          ,PERCOFINS
                          ,VLPIS
                          ,VLCOFINS
                          ,CODTRIBPISCOFINS
                          ,CODTRIBPISCOFINS_DEV
                          ,PISCOFINSDEDUZIDO
                          ,USAPISCOFINSLIT
                           -------------------------------------------------------
                          ,(select case
                                      when UTILIZAPERCPISCOFINSDIFCONS = 'S'
                                           and D.CONSUMIDORFINAL = 'S' then
                                       SITTRIBUTCONSUMODEV
                                      else
                                       SITTRIBUTDEV
                                   end
                              from PCTRIBPISCOFINS
                             where CODTRIBPISCOFINS = D.CODTRIBPISCOFINS) CST_DEV
                           -------------------------------------------------------
                          ,ALIQREDUCAOPIS
                          ,ALIQREDUCAOCOFINS
                          ,ENVIARALIQREDUCAOPISCOFINS
                          ,CLI_SUFRAMA
                          ,PROD_IMPORTADO
                          ,TIPOFJ
                          ,PISCOFINSCUMULATIVO
                          ,CODCLI
                          ,VLICMS
                          ,VLFCPICMS
                          ,VLFCPST
                          ,VLICMSDESONERACAO
                          ,VLSTBCR
                      from (select N.CODFILIAL
                                  ,M.CODPROD
                                  ,M.ROWID IDREGISTRO
                                  ,MCE.NUMTRANSITEM
                                  ,M.NUMTRANSENT
                                  ,N.DTENT DTEMISSAO
                                  ,C.CONSUMIDORFINAL
                                  ,M.CODFISCAL
                                  ,M.NBM
                                  ,M.CODOPER
                                  ,max(MC.QTLITRAGEM) QTLITRAGEM
                                  ,max(M.QTCONT) QTCONT
                                  ,max(NVL(M.VLSUFRAMA, 0)) VLDESCSUFRAMA
                                  ----------------------------------------------
                                  ,max(M.PUNITCONT - NVL(M.ST, 0) - NVL(M.VLIPI, 0)  - NVL(MC.VLFECP, 0) +
                                       NVL(M.VLDESCSUFRAMA, 0)) VLPRODUTO
                                  ----------------------------------------------
                                  ,max(NVL(M.VLFRETE, 0)) VLFRETE
                                  ,max(NVL(M.VLOUTROS, 0)) VLDESPESA
                                  ,max(NVL(M.VLIPI, 0)) VLIPI
                                  ,max(NVL(M.ST, 0)) ST
                                  ,min(NVL(NS.CONDVENDA, 0)) CONDVENDA
                                  ,max(NVL(S.VLBASEPISCOFINS, 0)) VLBASEPISCOFINS
                                  ,max(S.PERPIS) PERPIS
                                  ,max(S.PERCOFINS) PERCOFINS
                                  ,max(S.VLPIS) VLPIS
                                  ,max(S.VLCOFINS) VLCOFINS
                                  ,max(MC.USAPISCOFINSLIT) USAPISCOFINSLIT
                                  ,max(NVL(MC.CODTRIBPISCOFINS,MCE.CODTRIBPISCOFINS)) CODTRIBPISCOFINS
                                  ,max(MC.PISCOFINSDEDUZIDO) PISCOFINSDEDUZIDO
                                  ----------------------------------------------
                                  ,GET_CODTRIBEXCECAO_PISCOFINS(NVL(max(MC.CODTRIBPISCOFINS), MCE.CODTRIBPISCOFINS)
                                                               ,M.CODFISCAL
                                                               ,M.CODOPER
                                                               ,1
                                                               ,case
                                                                   when trim(C.SULFRAMA) is not null
                                                                        and C.DTVENCSUFRAMA >= N.DTENT then
                                                                    'S'
                                                                   else
                                                                    'N'
                                                                end
                                                               ,M.IMPORTADO
                                                               ,C.TIPOFJ
                                                               ,NVL(C.PISCOFINSCUMULATIVO, 'N')
                                                               ,NVL(N.CODFILIALNF, N.CODFILIAL)
                                                               ,N.DTEMISSAO
                                                               ,NS.CODCLI
                                                               ,(CASE WHEN MIN(NVL(NS.CONDVENDA,0)) = 8 THEN
                                                                   (CASE WHEN (SELECT MAX(NVL(CODEXCTRIBPISCOFINS,0))
                                                                               FROM PCTRIBPISCOFINSVIGENCIA
                                                                               WHERE CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS
                                                                                 AND NS.DTSAIDA BETWEEN DTINICIO AND DTFINAL) > 0 THEN
                                                                       (SELECT MAX(NVL(CODEXCTRIBPISCOFINS,0))
                                                                        FROM PCTRIBPISCOFINSVIGENCIA
                                                                        WHERE CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS
                                                                          AND NS.DTSAIDA BETWEEN DTINICIO AND DTFINAL)
                                                                    ELSE
                                                                       (SELECT MAX(NVL(CODEXCTRIBPISCOFINS,0))
                                                                        FROM PCTRIBPISCOFINS
                                                                        WHERE CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS)
                                                                    END)
                                                                 ELSE
                                                                    0
                                                                 END)
                                                               ,M.NBM
                                  ) CODTRIBPISCOFINS_DEV
                                  ,
                                  ----------------------------------------------
                                   case
                                      when (select max(NVL(ALIQREDUCAOPIS, 0))
                                              from PCTRIBPISCOFINSVIGENCIA
                                             where CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS
                                               and NS.DTSAIDA between DTINICIO and DTFINAL) > 0 then
                                       (select max(NVL(ALIQREDUCAOPIS, 0))
                                          from PCTRIBPISCOFINSVIGENCIA
                                         where CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS
                                           and NS.DTSAIDA between DTINICIO and DTFINAL)
                                      else
                                       (select max(NVL(ALIQREDUCAOPIS, 0))
                                          from PCTRIBPISCOFINS
                                         where CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS)
                                   end ALIQREDUCAOPIS
                                   -------------------------------------------------------
                                  ,case
                                      when (select max(NVL(ALIQREDUCAOCOFINS, 0))
                                              from PCTRIBPISCOFINSVIGENCIA
                                             where CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS
                                               and NS.DTSAIDA between DTINICIO and DTFINAL) > 0 then
                                       (select max(NVL(ALIQREDUCAOCOFINS, 0))
                                          from PCTRIBPISCOFINSVIGENCIA
                                         where CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS
                                           and NS.DTSAIDA between DTINICIO and DTFINAL)
                                      else
                                       (select max(NVL(ALIQREDUCAOCOFINS, 0))
                                          from PCTRIBPISCOFINS
                                         where CODTRIBPISCOFINS = MC.CODTRIBPISCOFINS)
                                   end ALIQREDUCAOCOFINS
                                  ----------------------------------------------
                                  ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARALIQREDUCAOPISCOFINS'
                                                                    ,NVL(N.CODFILIALNF, N.CODFILIAL))
                                      ,'N') ENVIARALIQREDUCAOPISCOFINS
                                  ----------------------------------------------
                                  ,case
                                     when (trim(C.SULFRAMA) is not null and C.DTVENCSUFRAMA >= N.DTENT) then
                                      'S'
                                     else
                                      'N'
                                  end CLI_SUFRAMA
                                  ----------------------------------------------
                                 ,case
                                     when NVL(M.IMPORTADO, P.IMPORTADO) in ('S', 'D') then
                                      'S'
                                     else
                                      'N'
                                  end PROD_IMPORTADO
                                  ----------------------------------------------
                                  ,NVL(N.TIPOFJ, C.TIPOFJ) TIPOFJ
                                  ,NVL(C.PISCOFINSCUMULATIVO, 'N') PISCOFINSCUMULATIVO
                                  ,N.CODFORNEC AS CODCLI
                                   --C?lculo do valor do icms conforme livro fiscal
                                  --,MAX((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)) AS VLICMS
                                  ,MAX(CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', NVL(N.CODFILIALNF, N.CODFILIAL)),'N') = 'S') AND
                                       (N.TIPODESCARGA = 'F') THEN
                                        --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                                        CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', NVL(N.CODFILIALNF, N.CODFILIAL)),'N') = 'N' THEN
                                              (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                   (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)
                                              -
                                                   (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                   (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100) *
                                                   (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100)
                                        ELSE
                                             0
                                        END
                                   ELSE
                                              (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                              (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)
                                         -
                                               (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                               (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100) *
                                               (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100)
                                   END) AS VLICMS
                                  ,MAX(NVL(MC.VLACRESCIMOFUNCEP, 0)) AS VLFCPICMS
                                  ,MAX(NVL(MC.VLFECP, 0)) AS VLFCPST
                                  ,MAX(NVL(MC.VLICMSDESONERACAO,0)) VLICMSDESONERACAO
                                  ,MAX(DECODE(M.SITTRIBUT,'60',NVL(M.STBCR, 0),0)) AS VLSTBCR
                              from PCNFENT     N
                                  ,PCMOV       M
                                  ,PCESTCOM    E
                                  ,PCNFSAID    NS
                                  ,PCCLIENT    C
                                  ,PCMOV       S
                                  ,PCMOVCOMPLE MC
                                  ,PCMOVCOMPLE MCE
                                  ,PCPRODUT    P
                             where M.NUMTRANSENT = NUMTRANSACAO
                               and N.NUMTRANSENT = E.NUMTRANSENT
                               and NS.NUMTRANSVENDA = E.NUMTRANSVENDA
                               and S.NUMTRANSVENDA = NS.NUMTRANSVENDA
                               and N.NUMTRANSENT = M.NUMTRANSENT
                               and NVL(M.CODFILIALNF, M.CODFILIAL) =  NVL(N.CODFILIALNF, N.CODFILIAL)
                               and N.NUMNOTA = M.NUMNOTA
                               and NS.NUMNOTA = S.NUMNOTA
                               and C.CODCLI = NVL(N.CODFORNECNF, N.CODFORNEC)
                               and M.CODPROD = P.CODPROD
                               and NVL(NS.CONDVENDA, 0) <> 13
                               and N.TIPODESCARGA <> 'C'
                               and MC.NUMTRANSITEM(+) = S.NUMTRANSITEM
                               and MCE.NUMTRANSITEM(+) = M.NUMTRANSITEM
                               and M.QTCONT > 0
                               and M.DTCANCEL is null
                               and S.QTCONT > 0
                               and S.DTCANCEL is null
                               and M.CODPROD = S.CODPROD
                               and M.NUMSEQ = S.NUMSEQ
                               and (not exists (select 1 from PCLISTAPROD_TMP) or exists
                                    (select 1 from PCLISTAPROD_TMP where CODPROD = S.CODPROD))
                             group by N.CODFILIAL
                                     ,M.CODPROD
                                     ,NVL(N.CODFILIALNF, N.CODFILIAL)
                                     ,M.CODFISCAL
                                     ,M.CODOPER
                                     ,C.SULFRAMA
                                     ,C.CONSUMIDORFINAL
                                     ,M.NBM
                                     ,C.DTVENCSUFRAMA
                                     ,N.DTENT
                                     ,M.IMPORTADO
                                     ,C.TIPOFJ
                                     ,C.PISCOFINSCUMULATIVO
                                     ,M.ROWID
                                     ,N.DESPESASRATEADA
                                     ,MCE.NUMTRANSITEM
                                     ,M.NUMTRANSENT
                                     ,N.DTEMISSAO
                                     ,MC.CODTRIBPISCOFINS
                                     ,MCE.CODTRIBPISCOFINS
                                     ,NS.DTSAIDA
                                     ,NS.CODCLI
                                     ,NVL(M.IMPORTADO, P.IMPORTADO)
                                     ,NVL(N.TIPOFJ, C.TIPOFJ)
                                     ,N.CODFORNEC) D)
      loop
         VREPLICOU_VENDA := true;

         -- VALIDAR CST --------------------------------------------------
         if (NVL(DADOS.CST_DEV, 0) <= 0)
            and (DADOS.CODTRIBPISCOFINS is not null)
         then
            if LENGTH(VMENSAGENS || CHR(13) || 'CST PIS/COFINS não informado para tributação: ' ||
                      TO_CHAR(DADOS.CODTRIBPISCOFINS) || ' Produto relacionado: ' || DADOS.CODPROD) <= 3700
            then
               VMENSAGENS := VMENSAGENS || CHR(13) ||
                             'CST PIS/COFINS não informado para tributação: ' ||
                             TO_CHAR(DADOS.CODTRIBPISCOFINS) || ' Produto relacionado: ' ||
                             DADOS.CODPROD;
            end if;

         else
            if (NVL(DADOS.CODTRIBPISCOFINS_DEV, 0) <> NVL(DADOS.CODTRIBPISCOFINS, 0))
               or (DADOS.CODTRIBPISCOFINS is null)
            then
               VREPLICOU_VENDA := false;
               exit;
            end if;

            if not CALCULAR_ITEM_PISCOFINS(FALSE
                                          ,DADOS.IDREGISTRO
                                          ,DADOS.CODPROD
                                          ,DADOS.NUMTRANSITEM
                                          ,DADOS.CODFISCAL
                                          ,DADOS.NCM
                                          ,DADOS.CODOPER
                                          ,DADOS.CONDVENDA
                                          ,DADOS.CONSUMIDORFINAL
                                          ,DADOS.QTLITRAGEM
                                          ,DADOS.QTCONT
                                          ,DADOS.VLPRODUTO
                                          ,DADOS.VLFRETE
                                          ,DADOS.VLDESPESA
                                          ,DADOS.VLDESCSUFRAMA
                                          ,DADOS.VLIPI
                                          ,DADOS.ST
                                          ,DADOS.CODTRIBPISCOFINS
                                          ,DADOS.CLI_SUFRAMA
                                          ,DADOS.PROD_IMPORTADO
                                          ,true
                                          ,VMSG_ITEM
                                          ,DADOS.TIPOFJ
                                          ,DADOS.PISCOFINSCUMULATIVO
                                          ,DADOS.CODFILIAL
                                          ,DADOS.DTEMISSAO
                                          ,DADOS.CODCLI
                                          ,DADOS.VLICMS
                                          ,DADOS.VLFCPST
                                          ,DADOS.VLFCPICMS
                                          ,DADOS.VLICMSDESONERACAO
                                          ,DADOS.DTEMISSAO
                                          ,DADOS.VLSTBCR
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,V_AGREGARFCPBASEPISCOFINSSAIDA
                                          ,0
                                          ,0)
            then
               if LENGTH(VMENSAGENS || CHR(13) || VMSG_ITEM) <= 3800
               then
                  VMENSAGENS := VMENSAGENS || CHR(13) || VMSG_ITEM;
               end if;
            end if;
         end if;
      end loop;

      -- GERAR VALORES DE PIS/COFINS SEM A VENDA, INDO NOVAMENTE NA TRIBUTA??O
      if not VREPLICOU_VENDA
      then
         for DADOS in (select NVL((select min(NS.CONDVENDA)
                                    from PCNFSAID NS
                                        ,PCESTCOM E
                                   where NS.NUMTRANSVENDA = E.NUMTRANSVENDA
                                     and E.NUMTRANSENT = N.NUMTRANSENT)
                                 ,0) CONDVENDA
                             ,C.CONSUMIDORFINAL
                             ,case
                                 when (trim(C.SULFRAMA) is not null and C.DTVENCSUFRAMA >= N.DTENT) then
                                  'S'
                                 else
                                  'N'
                              end CLI_SUFRAMA
                             ,case
                                 when NVL(M.IMPORTADO, P.IMPORTADO) in ('S', 'D') then
                                  'S'
                                 else
                                  'N'
                              end PROD_IMPORTADO
                             ,N.DTEMISSAO
                             ,M.ROWID IDREGISTRO
                             ,M.CODPROD
                             ,M.NUMTRANSITEM
                             ,M.CODFISCAL
                             ,M.NBM as NCM
                             ,NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
                             ,M.CODOPER
                             ,MC.QTLITRAGEM
                             ,M.QTCONT
                             ,NVL(M.VLIPI, 0) VLIPI
                             ,NVL(M.ST, 0) ST
                             ,NVL(M.VLSUFRAMA, 0) VLDESCSUFRAMA
                             ,M.PUNITCONT - NVL(M.ST, 0) - NVL(M.VLIPI, 0) +
                              NVL(M.VLDESCSUFRAMA, 0) VLPRODUTO
                             ,NVL(M.VLFRETE, 0) VLFRETE
                             ,NVL(M.VLOUTROS, 0) VLDESPESA
                             ,DECODE(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBUTACAOPORUF')
                                    ,'S'
                                    ,(select CODTRIBPISCOFINS
                                       from PCTABTRIB T
                                      where T.CODPROD = M.CODPROD
                                        and T.CODFILIALNF = NVL(N.CODFILIALNF, N.CODFILIAL)
                                        and T.UFDESTINO = NVL(N.UF, C.ESTENT))
                                    ,(select CODTRIBPISCOFINS
                                       from PCTABPR T
                                      where T.CODPROD = M.CODPROD
                                        and T.NUMREGIAO = NVL(PRC.NUMREGIAO, PR.NUMREGIAO))) CODTRIBPISCOFINS
                             ,NVL(N.TIPOFJ, C.TIPOFJ) TIPOFJ
                             ,NVL(C.PISCOFINSCUMULATIVO, 'N') PISCOFINSCUMULATIVO
                             ,N.CODFORNEC AS CODCLI
                             , CASE WHEN (NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', NVL(N.CODFILIALNF, N.CODFILIAL)),'N') = 'S') AND
                                       (N.TIPODESCARGA = 'F') THEN
                                        --MELHORIA PARA PASSAR A FORMAR O VALOR DE PRODUTOS DE ACORDO COM PARAMETROS DA 132 - HIS.02054.2015
                                        CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', NVL(N.CODFILIALNF, N.CODFILIAL)),'N') = 'N' THEN
                                                   (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                   (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)
                                              -
                                                   (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                                   (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100) *
                                                   (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100)
                                        ELSE
                                             0
                                        END
                                   ELSE
                                              (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                              (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100)
                                         -
                                               (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)) *
                                               (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100) *
                                               (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100)
                               END AS VLICMS
                             ,NVL(MC.VLACRESCIMOFUNCEP, 0) AS VLFCPICMS
                             ,NVL(MC.VLFECP, 0) AS VLFCPST
                             ,NVL(MC.VLICMSDESONERACAO,0) VLICMSDESONERACAO
                         from PCNFENT     N
                             ,PCMOV       M
                             ,PCMOVCOMPLE MC
                             ,PCCLIENT    C
                             ,PCPRACA     PR
                             ,PCPRODUT    P
                             ,PCTABPRCLI  PRC
                        where N.NUMTRANSENT = NUMTRANSACAO
                          and M.NUMTRANSENT = N.NUMTRANSENT
                          and NVL(N.CODFORNECNF, N.CODFORNEC) = PRC.CODCLI(+)
                          and NVL(N.CODFILIALNF, N.CODFILIAL) = PRC.CODFILIALNF(+)
                          and NVL(M.CODFILIALNF, M.CODFILIAL) =  NVL(N.CODFILIALNF, N.CODFILIAL)
                          and P.CODPROD = M.CODPROD
                          and N.TIPODESCARGA in ('6', '8', 'T', 'C')
                          and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                          and C.CODCLI =
                              DECODE(NVL(N.CODFORNECNF, 0), 0, N.CODFORNEC, N.CODFORNECNF)
                          and PR.CODPRACA(+) = C.CODPRACA
                          and M.STATUS in ('A', 'AB')
                          and M.QTCONT > 0
                          and M.DTCANCEL is null)
         loop
            if not CALCULAR_ITEM_PISCOFINS(FALSE
                                          ,DADOS.IDREGISTRO
                                          ,DADOS.CODPROD
                                          ,DADOS.NUMTRANSITEM
                                          ,DADOS.CODFISCAL
                                          ,DADOS.NCM
                                          ,DADOS.CODOPER
                                          ,DADOS.CONDVENDA
                                          ,DADOS.CONSUMIDORFINAL
                                          ,DADOS.QTLITRAGEM
                                          ,DADOS.QTCONT
                                          ,DADOS.VLPRODUTO
                                          ,DADOS.VLFRETE
                                          ,DADOS.VLDESPESA
                                          ,DADOS.VLDESCSUFRAMA
                                          ,DADOS.VLIPI
                                          ,DADOS.ST
                                          ,DADOS.CODTRIBPISCOFINS
                                          ,DADOS.CLI_SUFRAMA
                                          ,DADOS.PROD_IMPORTADO
                                          ,true
                                          ,VMSG_ITEM
                                          ,DADOS.TIPOFJ
                                          ,DADOS.PISCOFINSCUMULATIVO
                                          ,DADOS.CODFILIAL
                                          ,DADOS.DTEMISSAO
                                          ,DADOS.CODCLI
                                          ,DADOS.VLICMS
                                          ,DADOS.VLFCPST
                                          ,DADOS.VLFCPICMS
                                          ,DADOS.VLICMSDESONERACAO
                                          ,DADOS.DTEMISSAO
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,0
                                          ,V_AGREGARFCPBASEPISCOFINSSAIDA
                                          ,0
                                          ,0)
            then
               if LENGTH(VMENSAGENS || CHR(13) || VMSG_ITEM) <= 3800
               then
                  VMENSAGENS := VMENSAGENS || CHR(13) || VMSG_ITEM;
               end if;
            end if;
         end loop;
      end if;
      ----------------------------------------------------------------------
      if VMENSAGENS <> 'N:'
      then
         if LENGTH(VMENSAGENS) >= 3800
         then
            VMENSAGENS := SUBSTR(VMENSAGENS, 1, 3800) || '...';
         end if;
         MSG := VMENSAGENS;
      else
         -- GRAVAR MENSAGENS PIS/COFINS NA NOTA FISCAL ------------------------
         update PCNFENT
            set VLPIS    = VVLPIS_NF
               ,VLCOFINS = VVLCOFINS_NF
          where NUMTRANSENT = NUMTRANSACAO;

         MSG := 'S:PIS/COFINS calculado.';
      end if;

      return 'S';
   exception
      when VFALHATRIBUTACAO then
         return 'S';

      when others then
         MSG := 'N:Erro ao calcular PIS/COFINS para devolução. ' || CHR(13) || 'Erro original: ' ||
                sqlerrm;
         return 'S';
   end;

   -- PROCEDIMENTO PARA CALCULO DE PIS/COFINS PARA TRANSPORTE
   function CALCULARPISCOFINS_TRANSPORTE(NUMTRANSACAO in number
                                        ,MSG          out varchar2) return varchar2 is
      VFALHATRIBUTACAO exception;
      VESPECIE           PCNFSAID.ESPECIE%type;
      VUF                varchar2(2);
      VPERPIS            number;
      VPERCOFINS         number;
      VCSTFRETE          number;
      VNUMTRANSPISCOFINS PCNFENTPISCOFINS.NUMTRANSPISCOFINS%type;
      VVLICMSFRETE       number;
      V_DATAOPER          date;
      VDEDUZIR_ICMS_BC   varchar2(1);
   begin
      begin
         WITH NFSAID AS(
           select N.ESPECIE
                 ,NVL(N.UF, C.ESTENT) UF
                 ,NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
                 --obtem o valor do icms do frete
                 ,(SELECT SUM(VLICMS) FROM PCNFBASE WHERE PCNFBASE.NUMTRANSVENDA = N.NUMTRANSVENDA) VLICMS
                 ,DTSAIDA
             from PCNFSAID N
                 ,PCCLIENT C
            where NVL(N.CODCLINF, N.CODCLI) = C.CODCLI
              and N.NUMTRANSVENDA = NUMTRANSACAO
            UNION ALL
           select N.ESPECIE
                 ,NVL(N.UF, C.ESTENT) UF
                 ,NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
                 --obtem o valor do icms do frete
                 ,(SELECT SUM(VLICMS) FROM PCNFBASE WHERE PCNFBASE.NUMTRANSVENDA = N.NUMTRANSVENDA) VLICMS
                 ,DTSAIDA
             from PCNFSAIDPREFAT N
                 ,PCCLIENT C
            where NVL(N.CODCLINF, N.CODCLI) = C.CODCLI
              and N.NUMTRANSVENDA = NUMTRANSACAO
              AND DATACONSOLIDACAOPREFAT IS NULL
         )
           SELECT ESPECIE, UF, CODFILIAL, VLICMS, DTSAIDA
             into VESPECIE, VUF, VCODFILIAL, VVLICMSFRETE, V_DATAOPER
             FROM NFSAID;

         if VESPECIE not in ('CT', 'CO', 'CE')
         then
            MSG := 'N:O documento fiscal informado não é um conhecimento de frete.';
            raise VFALHATRIBUTACAO;
         end if;
      exception
         when others then
            MSG := 'N:Conhecimento de frete inexistente para a transação informada.';
            raise VFALHATRIBUTACAO;
      end;

      VDEDUZIR_ICMS_BC := PODE_DEDUZIR_ICMS_BCPISCOFINS(VCODFILIAL, V_DATAOPER);

      -- VERIFICANDO SE A FILIAL UTILIZA PIS/COFINS POR FIGURA TRIBUT?RIA ---
      if UPPER(SYS_CONTEXT('USERENV', 'MODULE')) not like '%PCSIS1000%'
      then
         if not UTILIZA_FIGURA_PISCOFINS(MSG)
         then
            return 'S';
         end if;
      end if;

      -- BUSCANDO A TRIBUTA??O
      begin
         select NVL(T.PERCPIS, 0)
               ,NVL(T.PERCCOFINS, 0)
               ,T.CSTPISCOFINS
           into VPERPIS
               ,VPERCOFINS
               ,VCSTFRETE
           from PCTRIBOUTROS T
          where T.UFDESTINO = VUF
            and T.CODFILIALNF = VCODFILIAL;

         if NVL(VCSTFRETE, 0) <= 0
         then
            MSG := 'N:CST PIS/COFINS não informado. UF: ' || VUF;

            raise VFALHATRIBUTACAO;
         end if;

      exception
         when others then
            MSG := 'N:Tributação PIS/COFINS inexistente para a UF: ' || VUF;
            raise VFALHATRIBUTACAO;
      end;

      -- APLICANDO CALCULOS
   update PCNFSAIDPREFAT
         set VLBASEPISCOFINS     = GREATEST(VLTOTAL - DECODE(VDEDUZIR_ICMS_BC, 'S', VVLICMSFRETE, 0),0)
            ,PERPIS              = VPERPIS
            ,PERCOFINS           = VPERCOFINS
            ,CODSITTRIBPISCOFINS = VCSTFRETE
            ,VLPIS               = GREATEST((VLTOTAL - DECODE(VDEDUZIR_ICMS_BC, 'S', VVLICMSFRETE, 0)) * VPERPIS / 100,0)
            ,VLCOFINS            = GREATEST((VLTOTAL - DECODE(VDEDUZIR_ICMS_BC, 'S', VVLICMSFRETE, 0)) * VPERCOFINS / 100,0)
       where NUMTRANSVENDA = NUMTRANSACAO;

      if sql%rowcount = 0 then
        update PCNFSAID
           set VLBASEPISCOFINS     = GREATEST(VLTOTAL - DECODE(VDEDUZIR_ICMS_BC, 'S', VVLICMSFRETE, 0),0)
              ,PERPIS              = VPERPIS
              ,PERCOFINS           = VPERCOFINS
              ,CODSITTRIBPISCOFINS = VCSTFRETE
              ,VLPIS               = GREATEST((VLTOTAL - DECODE(VDEDUZIR_ICMS_BC, 'S', VVLICMSFRETE, 0)) * VPERPIS / 100,0)
              ,VLCOFINS            = GREATEST((VLTOTAL - DECODE(VDEDUZIR_ICMS_BC, 'S', VVLICMSFRETE, 0)) * VPERCOFINS / 100,0)
         where NUMTRANSVENDA = NUMTRANSACAO;
      end if;

      if NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARENTTRANSPCIFPROPVENDA', VCODFILIAL), 'N') = 'S'
      then
         -- APLICAR TRIBUTA??O NO CONHECIMENTO DE ENTRADA
         declare
            VL_TOTAL  PCNFSAID.VLTOTAL%type;
            TRANSACAO PCNFSAID.NUMTRANSENTORIGEM%type;

            V_CONT            number(18);
            VLBASEPIS_TEMP    number(18, 2);
            VLBASECOFINS_TEMP number(18, 2);
            PERPIS_TEMP       number(18, 2);
            PERCOFINS_TEMP    number(18, 2);
            VLPIS_TEMP        number(18, 2);
            VLCOFINS_TEMP     number(18, 2);
         begin
         select sum(VLTOTAL)
              into VL_TOTAL
              from PCNFSAIDPREFAT
             where ESPECIE in ('NF', 'NE')
               and NUMTRANSVENDACONHEC = NUMTRANSACAO
               AND DATACONSOLIDACAOPREFAT IS NULL;

           IF VL_TOTAL IS NULL THEN
            select sum(VLTOTAL)
              into VL_TOTAL
              from PCNFSAID
             where ESPECIE in ('NF', 'NE')
               and NUMTRANSVENDACONHEC = NUMTRANSACAO;
           END IF;

            if VL_TOTAL > 0 then
            WITH NFSAID AS(
               select NUMTRANSENTORIGEM
                 from PCNFSAID
                where NUMTRANSVENDA = NUMTRANSACAO
                UNION ALL
               SELECT NUMTRANSENTORIGEM
                 from PCNFSAIDPREFAT
                where NUMTRANSVENDA = NUMTRANSACAO
                  AND DATACONSOLIDACAOPREFAT IS NULL
              )
              SELECT NUMTRANSENTORIGEM into TRANSACAO FROM NFSAID;

               delete from PCNFENTPISCOFINS where PCNFENTPISCOFINS.NUMTRANSENT = TRANSACAO;

               --ATUALIZAR DADOS PCNFENT
               update PCNFENT
                  set PCNFENT.VLPIS            = null
                     ,VLCOFINS                 = null
                     ,PCNFENT.CODTRIBPISCOFINS = null
                     ,PCNFENT.VLBASEPIS        = null
                     ,PCNFENT.VLBASECOFINS     = null
                where NUMTRANSENT = TRANSACAO;

               for DADOS_CON in (select NUMTRANSVENDA
                                       ,VLTOTAL
                                   from PCNFSAID
                                  where ESPECIE in ('CE', 'CT', 'CO')
                                    and NUMTRANSVENDA = NUMTRANSACAO
                                               UNION ALL
                 select NUMTRANSVENDA
                       ,VLTOTAL
                   from PCNFSAIDPREFAT
                  where ESPECIE in ('CE', 'CT', 'CO')
                    and NUMTRANSVENDA = NUMTRANSACAO
                    AND DATACONSOLIDACAOPREFAT IS NULL)
               loop
                  select DFSEQ_PCNFENTPISCOFINS.NEXTVAL into VNUMTRANSPISCOFINS from DUAL;

                  for DADOS in (select M.CODSITTRIBPISCOFINS
                                      ,V.CSTTRANSPORTE
                                      ,V.PERCPIS
                                      ,V.PERCCOFINS
                                      ,sum((PUNITCONT * QTCONT)) VLITEM
                                      ,N.NUMTRANSENTORIGEM
                                  from PCNFSAID               N
                                      ,PCMOV                  M
                                      ,PCVINCULARCSTPISCOFINS V
                                 where N.NUMTRANSVENDA = M.NUMTRANSVENDA
                                   and N.NUMTRANSVENDACONHEC = DADOS_CON.NUMTRANSVENDA
                                   and M.CODSITTRIBPISCOFINS = V.CSTVENDA
                                   and NVL(M.CODFILIALNF, M.CODFILIAL) = V.CODFILIAL
                                   and N.ESPECIE in ('NE', 'NF')
                                 group by M.CODSITTRIBPISCOFINS
                                         ,V.CSTTRANSPORTE
                                         ,V.PERCPIS
                                         ,V.PERCCOFINS
                                         ,N.NUMTRANSENTORIGEM
                                     UNION ALL
                    select M.CODSITTRIBPISCOFINS
                          ,V.CSTTRANSPORTE
                          ,V.PERCPIS
                          ,V.PERCCOFINS
                          ,sum((PUNITCONT * QTCONT)) VLITEM
                          ,N.NUMTRANSENTORIGEM
                      from PCNFSAIDPREFAT         N
                          ,PCMOVPREFAT            M
                          ,PCVINCULARCSTPISCOFINS V
                     where N.NUMTRANSVENDA = M.NUMTRANSVENDA
                       and N.NUMTRANSVENDACONHEC = DADOS_CON.NUMTRANSVENDA
                       and M.CODSITTRIBPISCOFINS = V.CSTVENDA
                       and NVL(M.CODFILIALNF, M.CODFILIAL) = V.CODFILIAL
                       and N.ESPECIE in ('NE', 'NF')
                       AND N.DATACONSOLIDACAOPREFAT IS NULL
                       AND M.DATACONSOLIDACAOPREFAT IS NULL
                     group by M.CODSITTRIBPISCOFINS
                             ,V.CSTTRANSPORTE
                             ,V.PERCPIS
                             ,V.PERCCOFINS
                             ,N.NUMTRANSENTORIGEM)
                  loop
                     if (DADOS.CSTTRANSPORTE is not null) AND (DADOS.PERCPIS > 0 OR DADOS.PERCCOFINS > 0) then

                        select DECODE(DADOS.PERCPIS
                                     ,0
                                     ,0
                                     ,ROUND(DADOS.VLITEM * (DADOS_CON.VLTOTAL / VL_TOTAL), 2))
                              ,DECODE(DADOS.PERCCOFINS
                                     ,0
                                     ,0
                                     ,ROUND(DADOS.VLITEM * (DADOS_CON.VLTOTAL / VL_TOTAL), 2))
                              ,DADOS.PERCPIS
                              ,DADOS.PERCCOFINS
                              ,ROUND(DADOS.VLITEM * (DADOS_CON.VLTOTAL / VL_TOTAL) *
                                     (DADOS.PERCPIS / 100)
                                    ,2)
                              ,ROUND(DADOS.VLITEM * (DADOS_CON.VLTOTAL / VL_TOTAL) *
                                     (DADOS.PERCCOFINS / 100)
                                    ,2)
                          into VLBASEPIS_TEMP
                              ,VLBASECOFINS_TEMP
                              ,PERPIS_TEMP
                              ,PERCOFINS_TEMP
                              ,VLPIS_TEMP
                              ,VLCOFINS_TEMP
                          from DUAL;

                        select count(*)
                          into V_CONT
                          from PCNFENTPISCOFINS P
                         where NUMTRANSPISCOFINS = VNUMTRANSPISCOFINS
                           and CODTRIBPISCOFINS = DADOS.CSTTRANSPORTE
                           and PERPIS = DADOS.PERCPIS
                           and PERCOFINS = DADOS.PERCCOFINS;

                        if V_CONT > 0 then
                           update PCNFENTPISCOFINS
                              set VLBASEPIS    = VLBASEPIS + VLBASEPIS_TEMP
                                 ,VLBASECOFINS = VLBASECOFINS + VLBASECOFINS_TEMP
                                 ,VLPIS        = VLPIS + VLPIS_TEMP
                                 ,VLCOFINS     = VLCOFINS + VLCOFINS_TEMP
                            where NUMTRANSPISCOFINS = VNUMTRANSPISCOFINS
                              and CODTRIBPISCOFINS = DADOS.CSTTRANSPORTE
                              and PERPIS = DADOS.PERCPIS
                              and PERCOFINS = DADOS.PERCCOFINS;
                        else
                           insert into PCNFENTPISCOFINS
                              (NUMTRANSENT
                              ,CODTRIBPISCOFINS
                              ,NUMTRANSPISCOFINS
                              ,VLBASEPIS
                              ,VLBASECOFINS
                              ,PERPIS
                              ,PERCOFINS
                              ,VLPIS
                              ,VLCOFINS)
                           values
                              (TRANSACAO
                              ,DADOS.CSTTRANSPORTE
                              ,VNUMTRANSPISCOFINS
                              ,VLBASEPIS_TEMP
                              ,VLBASECOFINS_TEMP
                              ,DADOS.PERCPIS
                              ,DADOS.PERCCOFINS
                              ,VLPIS_TEMP
                              ,VLCOFINS_TEMP);
                        end if;
                     end if;
                  end loop;

                  if TRANSACAO > 0 then
                     update PCNFBASEPREFAT
                        set NUMTRANSPISCOFINS = VNUMTRANSPISCOFINS
                      where NUMTRANSENT = TRANSACAO
                        AND DATACONSOLIDACAOPREFAT IS NULL;
                     if sql%rowcount = 0 THEN
                       update PCNFBASE
                          set NUMTRANSPISCOFINS = VNUMTRANSPISCOFINS
                        where NUMTRANSENT = TRANSACAO;
                     END IF;
                  end if;

               end loop;
            end if;
         end;
      end if;
      --  FIM APLICAR TRIBUTA??O NO CONHECIMENTO DE ENTRADA


     -- REPLICAR PCNFENTPISCOFINS
      if NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CONSIDERARENTTRANSPCIFPROPVENDA', VCODFILIAL), 'N') = 'N'
      then
         -- APLICAR TRIBUTA??O NO CONHECIMENTO DE ENTRADA
         declare
            VL_TOTAL  PCNFSAID.VLTOTAL%type;
            TRANSACAO PCNFSAID.NUMTRANSENTORIGEM%type;

            V_CONT            number(18);
            VLBASEPIS_TEMP    number(18, 2);
            VLBASECOFINS_TEMP number(18, 2);
            PERPIS_TEMP       number(18, 2);
            PERCOFINS_TEMP    number(18, 2);
            VLPIS_TEMP        number(18, 2);
            VLCOFINS_TEMP     number(18, 2);
         begin
         select sum(VLTOTAL)
              into VL_TOTAL
              from PCNFSAIDPREFAT
             where ESPECIE in ('NF', 'NE')
               and NUMTRANSVENDACONHEC = NUMTRANSACAO
               AND DATACONSOLIDACAOPREFAT IS NULL;

           IF VL_TOTAL IS NULL THEN
            select sum(VLTOTAL)
              into VL_TOTAL
              from PCNFSAID
             where ESPECIE in ('NF', 'NE')
               and NUMTRANSVENDACONHEC = NUMTRANSACAO;
           END IF;

            if VL_TOTAL > 0 then
            WITH NFSAID AS(
               select NUMTRANSENTORIGEM
                 from PCNFSAID
                where NUMTRANSVENDA = NUMTRANSACAO
                UNION ALL
               SELECT NUMTRANSENTORIGEM
                 from PCNFSAIDPREFAT
                where NUMTRANSVENDA = NUMTRANSACAO
                  AND DATACONSOLIDACAOPREFAT IS NULL
              )
              SELECT NUMTRANSENTORIGEM into TRANSACAO FROM NFSAID;

              delete from PCNFENTPISCOFINS where PCNFENTPISCOFINS.NUMTRANSENT = TRANSACAO;

       FOR DADOS IN (SELECT E.CODTRIBPISCOFINS,
                               E.VLBASEPIS,
                               E.VLBASECOFINS,
                               E.PERPIS,
                               E.PERCOFINS,
                               E.VLPIS,
                               E.VLCOFINS,
                               E.NUMTRANSENT,
                               E.CODCONT
                          FROM PCNFENT E
                         WHERE E.ESPECIE IN ('CT', 'CO')
                           AND E.NUMTRANSENT = TRANSACAO
                           --AND NVL(E.CODFILIALNF, E.CODFILIAL) = :CODFILIAL
                           AND E.CODTRIBPISCOFINS IS NOT NULL) LOOP

            SELECT DFSEQ_PCNFENTPISCOFINS.NEXTVAL
            INTO  VNUMTRANSPISCOFINS
            FROM DUAL ;




            INSERT INTO PCNFENTPISCOFINS
              (CODTRIBPISCOFINS,
               VLBASEPIS,
               VLBASECOFINS,
               PERPIS,
               PERCOFINS,
               VLCOFINS,
               VLPIS,
               NUMTRANSENT,
               NATCREDITO,
               NUMTRANSPISCOFINS)
            VALUES
              (DADOS.CODTRIBPISCOFINS,
               DADOS.VLBASEPIS,
               DADOS.VLBASECOFINS,
               DADOS.PERPIS,
               DADOS.PERCOFINS,
               DADOS.VLCOFINS,
               DADOS.VLPIS,
               DADOS.NUMTRANSENT,
               '',
               VNUMTRANSPISCOFINS);
               UPDATE PCNFBASE SET NUMTRANSPISCOFINS = NULL WHERE NUMTRANSENT = DADOS.NUMTRANSENT AND CODCONT = DADOS.CODCONT;
               UPDATE PCNFBASE SET NUMTRANSPISCOFINS = VNUMTRANSPISCOFINS WHERE NUMTRANSENT = DADOS.NUMTRANSENT AND CODCONT = DADOS.CODCONT and rownum = 1;
          END LOOP;


            end if;
         end;
      end if;

/*INICIO Processo para deduzir VLICMS da base PIS/COFINS CONHECIMENTO TRANSPORTE ESPECIE 'CT','CO'*/

   FOR NFTRANSP IN (SELECT NUMTRANSENTORIGEM
                         , ESPECIE
                      FROM PCNFSAID
                     WHERE NUMTRANSVENDA = NUMTRANSACAO
                    UNION ALL
                    SELECT NUMTRANSENTORIGEM
                         , ESPECIE
                      FROM PCNFSAIDPREFAT
                     WHERE NUMTRANSVENDA = NUMTRANSACAO AND DATACONSOLIDACAOPREFAT IS NULL)
   LOOP
      IF (NFTRANSP.NUMTRANSENTORIGEM > 0) AND(NFTRANSP.ESPECIE IN('CT', 'CO')) AND (VDEDUZIR_ICMS_BC = 'S')
      THEN
         DECLARE
            VLICMS_TEMP   NUMBER(18, 2);
         BEGIN
            VLICMS_TEMP                := 0;

            SELECT SUM(VLICMS)
              INTO VLICMS_TEMP
              FROM PCNFBASE
             WHERE PCNFBASE.NUMTRANSENT = NFTRANSP.NUMTRANSENTORIGEM;

            IF VLICMS_TEMP > 0
            THEN
               FOR DADOS IN (SELECT E.VLBASEPIS
                                  , E.VLBASECOFINS
                                  , NVL(F.PERPIS,E.PERPIS) PERPIS
                                  , NVL(F.PERCOFINS,E.PERCOFINS) PERCOFINS
                                  , E.VLCOFINS
                                  , E.VLPIS
                                  , E.NUMTRANSENT
                                  , NVL(NVL(F.CODSITTRIBPISCOFINSCONHEC,E.CODTRIBPISCOFINS),VCSTFRETE) CODTRIBPISCOFINS
                                  , E.VLTOTAL
                                  , E.CODCONT
                               FROM PCNFENT E,
                                    PCFORNECFILIAL F
                              WHERE E.ESPECIE IN('CT', 'CO')
                                AND E.CODFORNEC = F.CODFORNEC(+)
                                AND NVL(E.CODFILIAL,E.CODFILIALNF) = F.CODFILIAL(+)
                                AND E.NUMTRANSENT = NFTRANSP.NUMTRANSENTORIGEM
                                AND E.VLTOTAL > 0)
               LOOP
                  UPDATE PCNFENTPISCOFINS
                     SET VLBASECOFINS = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0)
                       , VLBASEPIS    = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0)
                       , VLPIS        = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0) *(PERPIS / 100)
                       , VLCOFINS     = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0) *(PERCOFINS / 100)
                       , CODTRIBPISCOFINS  = DADOS.CODTRIBPISCOFINS
                   WHERE NUMTRANSENT       = DADOS.NUMTRANSENT
                     AND PERPIS            = DADOS.PERPIS
                     AND PERCOFINS         = DADOS.PERCOFINS;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     SELECT DFSEQ_PCNFENTPISCOFINS.NEXTVAL
                       INTO VNUMTRANSPISCOFINS
                       FROM DUAL;

                     INSERT INTO PCNFENTPISCOFINS
                                 (CODTRIBPISCOFINS
                                , VLBASEPIS
                                , VLBASECOFINS
                                , PERPIS
                                , PERCOFINS
                                , VLCOFINS
                                , VLPIS
                                , NUMTRANSENT
                                , NATCREDITO
                                , NUMTRANSPISCOFINS)
                          VALUES (DADOS.CODTRIBPISCOFINS
                                , GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0)
                                , GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0)
                                , DADOS.PERPIS
                                , DADOS.PERCOFINS
                                , GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0) *(DADOS.PERCOFINS / 100)
                                , GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0) *(DADOS.PERPIS / 100)
                                , DADOS.NUMTRANSENT
                                , ''
                                , VNUMTRANSPISCOFINS);

                                UPDATE PCNFBASE SET NUMTRANSPISCOFINS = NULL WHERE NUMTRANSENT = DADOS.NUMTRANSENT AND CODCONT = DADOS.CODCONT;
                                UPDATE PCNFBASE SET NUMTRANSPISCOFINS = VNUMTRANSPISCOFINS WHERE NUMTRANSENT = DADOS.NUMTRANSENT AND CODCONT = DADOS.CODCONT and rownum = 1;

                  END IF;

                  --ATUALIZAR DADOS PCNFENT
                  UPDATE PCNFENT
                     SET PCNFENT.VLPIS        = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0) *(DADOS.PERPIS / 100)
                       , PCNFENT.VLCOFINS     = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0) *(DADOS.PERCOFINS / 100)
                       , PCNFENT.CODTRIBPISCOFINS = DADOS.CODTRIBPISCOFINS
                       , PCNFENT.VLBASEPIS    = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0)
                       , PCNFENT.VLBASECOFINS = GREATEST(DADOS.VLTOTAL - VLICMS_TEMP, 0)
                   WHERE NUMTRANSENT = DADOS.NUMTRANSENT AND CODCONT = DADOS.CODCONT;
               END LOOP;
            END IF;
         END;
      END IF;
   END LOOP;
 -- FIM DEDUÇÃO VLICMS

      MSG := 'S:PIS/COFINS calculado';
      return 'S';
   exception
      when VFALHATRIBUTACAO then
         return 'S';

      when others then
         MSG := 'N:Erro ao calcular PIS/COFINS. ' || CHR(13) || 'Erro original: ' || sqlerrm;
         return 'S';
   end;

--RATEIO OUTRAS DESPESAS E FRETE (ILQUIAS 20/07/2011)
   procedure CALCULAR_RATEIO_DESPESAS(P_TRANSACAO in number
                                     ,MSG         out varchar2) is
      VALOR_TOTAL_FRETE       PCNFSAID.VLFRETE%type;
      VALOR_TOTAL_OUTROS      PCNFSAID.VLOUTRASDESP%type;
      VALOR_TOTAL_ACRESCIMOPF number(18, 2);
      VALOR_TOTAL_PRODUTOS    number(18, 2);
      VALOR_TOTAL_REPASSE     number(18, 2);
      VALOR_TOTAL_STOUTRAS    number(18, 2);

      VALOR_OUTRAS_RATEADO         PCMOV.VLOUTROS%type;
      VALOR_RATEIO_OUTRAS_UNITARIO PCMOV.VLOUTROS%type;
      VALOR_FRETE_RATEADO          PCMOV.VLFRETE%type;
      VALOR_RATEIO_FRETE_UNITARIO  PCMOV.VLFRETE%type;

      ID_ULTIMO_REGISTRO_PCMOV       rowid;
      ULTIMO_REGISTRO_PREFATURAMENTO VARCHAR2(1);
      ID_ULTIMO_REGISTRO_PCMOVCOMPLE PCMOVCOMPLE.NUMTRANSITEM%type;
      QTCONT_ULTIMO_REGISTRO_PCMOV   PCMOV.QTCONT%type;
      PERC_REDUCAO_OUTRASDESP        PCNFSAID.PERBASEREDOUTRASDESP%type;
      GEROU_OUTROS_FRETE_ULTIMO_REG  VARCHAR2(1);

      MOV_TRANSFERENCIA varchar2(1);
   begin

    WITH TABELA AS(
      select NVL(PCNFSAID.VLFRETE, 0) as VALOR_FRETE,
             NVL(PCNFSAID.VLTOTAL, 0) - NVL(PCNFSAID.VLFRETE, 0) -
             NVL(PCNFSAID.VLOUTRASDESP, 0) as VALOR_PRODUTOS,
             sum(NVL(PCMOV.VLACRESCIMOPF, 0) * PCMOV.QTCONT) as VALOR_ACRESCIMOPF,
             sum(CASE
                   WHEN (NVL((SELECT PCPARAMFILIAL.VALOR
                               FROM PCPARAMFILIAL
                              WHERE (PCPARAMFILIAL.CODFILIAL =
                                    PCNFSAID.CODFILIAL)
                                AND PCPARAMFILIAL.NOME =
                                    'SOMAREPASSEOUTRASDESPNF'),
                             'N') = 'S') THEN
                    Round(NVL(PCMOV.VLREPASSE, 0) * PCMOV.QTCONT, 2)
                   ELSE
                    0
                 END) AS VALOR_REPASSE,
             NVL(PCNFSAID.VLOUTRASDESP, 0) as VALOR_OUTROS,
             DECODE(max(PCMOV.CODOPER), 'ST', 'S', 'N') MOV_TRANSFERENCIA,
             sum(CASE
                   WHEN (NVL((SELECT PCPARAMFILIAL.VALOR
                               FROM PCPARAMFILIAL
                              WHERE (PCPARAMFILIAL.CODFILIAL =
                                    PCNFSAID.CODFILIAL)
                                AND PCPARAMFILIAL.NOME =
                                    'RATEARDESPESASVLSTOUTRAS'),
                             'N') = 'S') THEN
                    Round(NVL(PCMOVCOMPLE.VLSTOUTRAS, 0) * PCMOV.QTCONT, 2)
                   ELSE
                    0
                 END) AS VALOR_STOUTRAS
        from PCNFSAID, PCMOV, PCMOVCOMPLE
       where PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
         and PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
         and PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
         and PCMOV.QTCONT > 0
         and NVL(PCNFSAID.DOCEMISSAO, 'X') NOT IN ('CE', 'SF', 'MF', 'CF')
       group by NVL(PCNFSAID.VLTOTAL, 0),
                NVL(PCNFSAID.VLFRETE, 0),
                NVL(PCNFSAID.VLOUTRASDESP, 0),
                NVL(PCNFSAID.PERBASEREDOUTRASDESP, 0)
      UNION ALL
      select NVL(PCNFSAIDPREFAT.VLFRETE, 0) as VALOR_FRETE,
             NVL(PCNFSAIDPREFAT.VLTOTAL, 0) - NVL(PCNFSAIDPREFAT.VLFRETE, 0) -
             NVL(PCNFSAIDPREFAT.VLOUTRASDESP, 0) as VALOR_PRODUTOS,
             sum(NVL(PCMOVPREFAT.VLACRESCIMOPF, 0) * PCMOVPREFAT.QTCONT) as VALOR_ACRESCIMOPF,
             sum(CASE
                   WHEN (NVL((SELECT PCPARAMFILIAL.VALOR
                               FROM PCPARAMFILIAL
                              WHERE (PCPARAMFILIAL.CODFILIAL =
                                    PCNFSAIDPREFAT.CODFILIAL)
                                AND PCPARAMFILIAL.NOME =
                                    'SOMAREPASSEOUTRASDESPNF'),
                             'N') = 'S') THEN
                    Round(NVL(PCMOVPREFAT.VLREPASSE, 0) * PCMOVPREFAT.QTCONT, 2)
                   ELSE
                    0
                 END) AS VALOR_REPASSE,
             NVL(PCNFSAIDPREFAT.VLOUTRASDESP, 0) as VALOR_OUTROS,
             DECODE(max(PCMOVPREFAT.CODOPER), 'ST', 'S', 'N') MOV_TRANSFERENCIA,
             sum(CASE
                   WHEN (NVL((SELECT PCPARAMFILIAL.VALOR
                               FROM PCPARAMFILIAL
                              WHERE (PCPARAMFILIAL.CODFILIAL =
                                    PCNFSAIDPREFAT.CODFILIAL)
                                AND PCPARAMFILIAL.NOME =
                                    'RATEARDESPESASVLSTOUTRAS'),
                             'N') = 'S') THEN
                    Round(NVL(PCMOVCOMPLEPREFAT.VLSTOUTRAS, 0) * PCMOVPREFAT.QTCONT, 2)
                   ELSE
                    0
                 END) AS VALOR_STOUTRAS
        from PCNFSAIDPREFAT, PCMOVPREFAT, PCMOVCOMPLEPREFAT
       where PCNFSAIDPREFAT.NUMTRANSVENDA = P_TRANSACAO
         and PCMOVPREFAT.NUMTRANSVENDA = PCNFSAIDPREFAT.NUMTRANSVENDA
         and PCMOVPREFAT.NUMTRANSITEM = PCMOVCOMPLEPREFAT.NUMTRANSITEM
         and PCMOVPREFAT.QTCONT > 0
         and NVL(PCNFSAIDPREFAT.DOCEMISSAO, 'X') NOT IN ('CE', 'SF', 'MF', 'CF')
         and PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
         and PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
       group by NVL(PCNFSAIDPREFAT.VLTOTAL, 0),
                NVL(PCNFSAIDPREFAT.VLFRETE, 0),
                NVL(PCNFSAIDPREFAT.VLOUTRASDESP, 0),
                NVL(PCNFSAIDPREFAT.PERBASEREDOUTRASDESP, 0)
     ) SELECT VALOR_FRETE
             ,VALOR_PRODUTOS
             ,VALOR_ACRESCIMOPF
             ,VALOR_REPASSE
             ,VALOR_OUTROS
             , MOV_TRANSFERENCIA
             ,VALOR_STOUTRAS
        into VALOR_TOTAL_FRETE
            ,VALOR_TOTAL_PRODUTOS
            ,VALOR_TOTAL_ACRESCIMOPF
            ,VALOR_TOTAL_REPASSE
            ,VALOR_TOTAL_OUTROS
            ,MOV_TRANSFERENCIA
            ,VALOR_TOTAL_STOUTRAS
        FROM TABELA;

      VALOR_TOTAL_OUTROS := VALOR_TOTAL_OUTROS - VALOR_TOTAL_ACRESCIMOPF - VALOR_TOTAL_REPASSE - NVL(VALOR_TOTAL_STOUTRAS,0);

     GEROU_OUTROS_FRETE_ULTIMO_REG := 'N' ;
      VALOR_OUTRAS_RATEADO := 0;
      VALOR_FRETE_RATEADO  := 0;

      --ATUALIZAR DADOS PCMOV E PCMOVCOMPLE
      for REGISTROS in (select PCMOV.ROWID IDREGISTRO
                              ,PCMOVCOMPLE.NUMTRANSITEM as ITEM_NUMTRANSITEM
                              ,PCMOV.BASEICMS as ITEM_BASE_ICMS
                              ,NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) as ITEM_ALIQUOTA_ICMS
                              ,PCMOV.CODOPER as ITEM_CODIGO_OPERACAO
                              ,PCMOV.QTCONT as ITEM_QUANTIDADE
                              ,NVL((PCMOV.QTCONT * PCMOV.PUNITCONT), 0) as ITEM_VALOR_TOTAL
                              ,NVL((PCMOV.VLACRESCIMOPF), 0) as ITEM_ACRESCIMOPF
                              ,CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFSAID.CODFILIAL) AND PCPARAMFILIAL.NOME = 'SOMAREPASSEOUTRASDESPNF'),'N') = 'S') THEN
                                 NVL((PCMOV.VLREPASSE), 0)
                               ELSE
                                 0
                               END AS ITEM_VLREPASSE
                              ,NVL(PCMOV.VLOUTRASDESP, 0) as ITEM_VLOUTRASDESP
                              ,NVL(PCMOV.VLFRETE, 0) as ITEM_VLFRETE
                              ,NVL(PCMOVCOMPLE.BONIFIC, 'N') as ITEM_BONIFIC
                              ,case
                                  when NVL(PCMOV.PERCBASERED, 0) > 0 then
                                   100 - NVL(PCMOV.PERCBASERED,0)
                                  else
                                   0
                               end as PERC_REDUCAO_OUTRASDESP
                              ,'N' PREFATURAMENTO
                              ,CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFSAID.CODFILIAL) AND PCPARAMFILIAL.NOME = 'RATEARDESPESASVLSTOUTRAS'),'N') = 'S') THEN
                                 NVL((PCMOVCOMPLE.VLSTOUTRAS), 0)
                               ELSE
                                 0
                               END AS ITEM_VLSTOUTRAS
                          from PCMOV
                              ,PCNFSAID
                              ,PCMOVCOMPLE
                         where PCMOV.NUMTRANSVENDA = P_TRANSACAO
                           and PCMOV.QTCONT > 0
                           and PCMOV.PUNITCONT > 0
                           and PCNFSAID.DTCANCEL is null
                           and PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                           and PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                           and NVL(PCNFSAID.DOCEMISSAO, 'X') NOT IN ('CE', 'SF', 'MF', 'CF')
                         union all
                        select PCMOVPREFAT.ROWID IDREGISTRO
                              ,PCMOVCOMPLEPREFAT.NUMTRANSITEM as ITEM_NUMTRANSITEM
                              ,PCMOVPREFAT.BASEICMS as ITEM_BASE_ICMS
                              ,NVL(NVL(PCMOVPREFAT.PERCICMCP, PCMOVPREFAT.PERCICM), 0) as ITEM_ALIQUOTA_ICMS
                              ,PCMOVPREFAT.CODOPER as ITEM_CODIGO_OPERACAO
                              ,PCMOVPREFAT.QTCONT as ITEM_QUANTIDADE
                              ,NVL((PCMOVPREFAT.QTCONT * PCMOVPREFAT.PUNITCONT), 0) as ITEM_VALOR_TOTAL
                              ,NVL((PCMOVPREFAT.VLACRESCIMOPF), 0) as ITEM_ACRESCIMOPF
                              ,CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFSAIDPREFAT.CODFILIAL) AND PCPARAMFILIAL.NOME = 'SOMAREPASSEOUTRASDESPNF'),'N') = 'S') THEN
                                 NVL((PCMOVPREFAT.VLREPASSE), 0)
                               ELSE
                                 0
                               END AS ITEM_VLREPASSE
                              ,NVL(PCMOVPREFAT.VLOUTRASDESP, 0) as ITEM_VLOUTRASDESP
                              ,NVL(PCMOVPREFAT.VLFRETE, 0) as ITEM_VLFRETE
                              ,NVL(PCMOVCOMPLEPREFAT.BONIFIC, 'N') as ITEM_BONIFIC
                              ,case
                                  when NVL(PCMOVPREFAT.PERCBASERED, 0) > 0 then
                                   100 - NVL(PCMOVPREFAT.PERCBASERED,0)
                                  else
                                   0
                               end as PERC_REDUCAO_OUTRASDESP
                              ,'S' PREFATURAMENTO
                              ,CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFSAIDPREFAT.CODFILIAL) AND PCPARAMFILIAL.NOME = 'RATEARDESPESASVLSTOUTRAS'),'N') = 'S') THEN
                                 NVL((PCMOVCOMPLEPREFAT.VLSTOUTRAS), 0)
                               ELSE
                                 0
                               END AS ITEM_VLSTOUTRAS
                          from PCMOVPREFAT
                              ,PCNFSAIDPREFAT
                              ,PCMOVCOMPLEPREFAT
                         where PCMOVPREFAT.NUMTRANSVENDA = P_TRANSACAO
                           and PCMOVPREFAT.QTCONT > 0
                           and PCMOVPREFAT.PUNITCONT > 0
                           and PCNFSAIDPREFAT.DTCANCEL is null
                           and PCMOVPREFAT.NUMTRANSVENDA = PCNFSAIDPREFAT.NUMTRANSVENDA
                           and PCMOVPREFAT.NUMTRANSITEM = PCMOVCOMPLEPREFAT.NUMTRANSITEM(+)
                           and NVL(PCNFSAIDPREFAT.DOCEMISSAO, 'X') NOT IN ('CE', 'SF', 'MF', 'CF')
                           AND PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                           AND PCMOVCOMPLEPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                           AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                         order by ITEM_VALOR_TOTAL)
      loop
         if (VALOR_TOTAL_OUTROS > 0)
            or (VALOR_TOTAL_FRETE > 0) then

            if REGISTROS.ITEM_CODIGO_OPERACAO not in ('SD')
               and REGISTROS.ITEM_BONIFIC in ('N') then

               ULTIMO_REGISTRO_PREFATURAMENTO := REGISTROS.PREFATURAMENTO;
               ID_ULTIMO_REGISTRO_PCMOV       := REGISTROS.IDREGISTRO;
               ID_ULTIMO_REGISTRO_PCMOVCOMPLE := REGISTROS.ITEM_NUMTRANSITEM;
               QTCONT_ULTIMO_REGISTRO_PCMOV   := REGISTROS.ITEM_QUANTIDADE;
               -------------------------ATRIBUIR VALOR DE FRETE E OUTRAS DESPESAS AS VARIAVEIS ---------------------------------------
               VALOR_RATEIO_OUTRAS_UNITARIO := NVL(TRUNC(((REGISTROS.ITEM_VALOR_TOTAL / VALOR_TOTAL_PRODUTOS) * VALOR_TOTAL_OUTROS),2) /
                                                   REGISTROS.ITEM_QUANTIDADE,0);

               VALOR_RATEIO_FRETE_UNITARIO := NVL(TRUNC(((REGISTROS.ITEM_VALOR_TOTAL / VALOR_TOTAL_PRODUTOS) * VALOR_TOTAL_FRETE),2) /
                                                  REGISTROS.ITEM_QUANTIDADE,0);
               ----------------------------ATUALIZAR OUTRAS DESP E FRETE DE CADA ITEM--------------------------------------------------
               if REGISTROS.PREFATURAMENTO = 'S' THEN
                 if REGISTROS.ITEM_NUMTRANSITEM is null then
                    --GRAVAR VLFRETE E VLOUTROS PCMOV.
                    update PCMOVPREFAT
                       set VLOUTROS     = VALOR_RATEIO_OUTRAS_UNITARIO + REGISTROS.ITEM_ACRESCIMOPF + REGISTROS.ITEM_VLREPASSE + NVL(REGISTROS.ITEM_VLSTOUTRAS,0)
                          ,VLFRETE      = VALOR_RATEIO_FRETE_UNITARIO
                          ,NUMTRANSITEM = DFSEQ_PCMOVCOMPLE.NEXTVAL
                     where rowid = REGISTROS.IDREGISTRO
                       AND DATACONSOLIDACAOPREFAT IS NULL;

                    if ROUND(REGISTROS.ITEM_BASE_ICMS * REGISTROS.ITEM_QUANTIDADE, 2) > 0 and
                       (REGISTROS.ITEM_ALIQUOTA_ICMS > 0)
                    then
                       insert into PCMOVCOMPLEPREFAT
                          (NUMTRANSITEM
                          ,DTREGISTRO
                          ,VLBASEFRETE
                          ,VLBASEOUTROS)
                       values
                          (DFSEQ_PCMOVCOMPLE.CURRVAL
                          ,TRUNC(sysdate)
                          ,VALOR_RATEIO_FRETE_UNITARIO
                          ,VALOR_RATEIO_OUTRAS_UNITARIO - (VALOR_RATEIO_OUTRAS_UNITARIO * (REGISTROS.PERC_REDUCAO_OUTRASDESP / 100)));
                          GEROU_OUTROS_FRETE_ULTIMO_REG := 'S' ;
                    ELSE
                          GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';
                    end if;

                    select DFSEQ_PCMOVCOMPLE.CURRVAL into ID_ULTIMO_REGISTRO_PCMOVCOMPLE from DUAL;
                 else
                    if ROUND(REGISTROS.ITEM_BASE_ICMS * REGISTROS.ITEM_QUANTIDADE, 2) > 0
                       and (REGISTROS.ITEM_ALIQUOTA_ICMS > 0)
                    then
                       update PCMOVCOMPLEPREFAT
                          set VLBASEOUTROS = VALOR_RATEIO_OUTRAS_UNITARIO -
                                             (VALOR_RATEIO_OUTRAS_UNITARIO * (REGISTROS.PERC_REDUCAO_OUTRASDESP / 100))
                             ,VLBASEFRETE  = VALOR_RATEIO_FRETE_UNITARIO -
                                             (VALOR_RATEIO_FRETE_UNITARIO * (REGISTROS.PERC_REDUCAO_OUTRASDESP / 100))
                        where NUMTRANSITEM = REGISTROS.ITEM_NUMTRANSITEM
                          AND DATACONSOLIDACAOPREFAT IS NULL;

                        GEROU_OUTROS_FRETE_ULTIMO_REG := 'S' ;
                     ELSE
                        GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';
                    end if;

                    update PCMOVPREFAT
                       set VLOUTROS = VALOR_RATEIO_OUTRAS_UNITARIO + REGISTROS.ITEM_ACRESCIMOPF + REGISTROS.ITEM_VLREPASSE + NVL(REGISTROS.ITEM_VLSTOUTRAS,0)
                          ,VLFRETE  = VALOR_RATEIO_FRETE_UNITARIO
                     where rowid = REGISTROS.IDREGISTRO
                       AND DATACONSOLIDACAOPREFAT IS NULL;
                 end if;
               ELSE
                 if REGISTROS.ITEM_NUMTRANSITEM is null then
                    --GRAVAR VLFRETE E VLOUTROS PCMOV.
                    update PCMOV
                       set PCMOV.VLOUTROS     = VALOR_RATEIO_OUTRAS_UNITARIO + REGISTROS.ITEM_ACRESCIMOPF + REGISTROS.ITEM_VLREPASSE + NVL(REGISTROS.ITEM_VLSTOUTRAS,0)
                          ,PCMOV.VLFRETE      = VALOR_RATEIO_FRETE_UNITARIO
                          ,PCMOV.NUMTRANSITEM = DFSEQ_PCMOVCOMPLE.NEXTVAL
                     where rowid = REGISTROS.IDREGISTRO;

                    if ROUND(REGISTROS.ITEM_BASE_ICMS * REGISTROS.ITEM_QUANTIDADE, 2) > 0 and
                       (REGISTROS.ITEM_ALIQUOTA_ICMS > 0)
                    then
                       insert into PCMOVCOMPLE
                          (NUMTRANSITEM
                          ,DTREGISTRO
                          ,VLBASEFRETE
                          ,VLBASEOUTROS)
                       values
                          (DFSEQ_PCMOVCOMPLE.CURRVAL
                          ,TRUNC(sysdate)
                          ,VALOR_RATEIO_FRETE_UNITARIO
                          ,VALOR_RATEIO_OUTRAS_UNITARIO - (VALOR_RATEIO_OUTRAS_UNITARIO * (REGISTROS.PERC_REDUCAO_OUTRASDESP / 100)));
                          GEROU_OUTROS_FRETE_ULTIMO_REG := 'S' ;
                    ELSE
                          GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';
                    end if;

                    select DFSEQ_PCMOVCOMPLE.CURRVAL into ID_ULTIMO_REGISTRO_PCMOVCOMPLE from DUAL;
                 else
                    if ROUND(REGISTROS.ITEM_BASE_ICMS * REGISTROS.ITEM_QUANTIDADE, 2) > 0
                       and (REGISTROS.ITEM_ALIQUOTA_ICMS > 0)
                    then
                       update PCMOVCOMPLE
                          set PCMOVCOMPLE.VLBASEOUTROS = VALOR_RATEIO_OUTRAS_UNITARIO -
                                                         (VALOR_RATEIO_OUTRAS_UNITARIO * (REGISTROS.PERC_REDUCAO_OUTRASDESP / 100))
                             ,PCMOVCOMPLE.VLBASEFRETE  = VALOR_RATEIO_FRETE_UNITARIO -
                                                         (VALOR_RATEIO_FRETE_UNITARIO * (REGISTROS.PERC_REDUCAO_OUTRASDESP / 100))
                        where PCMOVCOMPLE.NUMTRANSITEM = REGISTROS.ITEM_NUMTRANSITEM;
                        GEROU_OUTROS_FRETE_ULTIMO_REG := 'S' ;
                     ELSE
                        GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';
                    end if;

                    update PCMOV
                       set PCMOV.VLOUTROS = VALOR_RATEIO_OUTRAS_UNITARIO + REGISTROS.ITEM_ACRESCIMOPF + REGISTROS.ITEM_VLREPASSE + NVL(REGISTROS.ITEM_VLSTOUTRAS,0)
                          ,PCMOV.VLFRETE  = VALOR_RATEIO_FRETE_UNITARIO
                     where rowid = REGISTROS.IDREGISTRO;
                 end if;
               END IF;

               --SOMANDO O VALOR DE OUTRAS DESPESAS JA RATEADO
               VALOR_OUTRAS_RATEADO := VALOR_OUTRAS_RATEADO + ROUND(VALOR_RATEIO_OUTRAS_UNITARIO * REGISTROS.ITEM_QUANTIDADE,2);
               --SOMANDO O VALOR DO FRETE JA RATEADO
               VALOR_FRETE_RATEADO := VALOR_FRETE_RATEADO + ROUND(VALOR_RATEIO_FRETE_UNITARIO * REGISTROS.ITEM_QUANTIDADE,2);
            end if;
         end if;
      end loop;
      ------------------------------------------ATUALIZAR DIFERENCA DE RATEIO----------------------------------------------------
      if ULTIMO_REGISTRO_PREFATURAMENTO = 'N' THEN
        --OUTRAS DESPESAS
        if NVL(VALOR_TOTAL_OUTROS,0) <> NVL(VALOR_OUTRAS_RATEADO,0)
        then
           VALOR_RATEIO_OUTRAS_UNITARIO := (VALOR_TOTAL_OUTROS - NVL(VALOR_OUTRAS_RATEADO,0)) / NVL(QTCONT_ULTIMO_REGISTRO_PCMOV,0);

           update PCMOV
              set PCMOV.VLOUTROS = NVL(PCMOV.VLOUTROS,0) + NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0)
            where rowid = ID_ULTIMO_REGISTRO_PCMOV;

           select case
                     when NVL(PCMOV.PERCBASERED,0) > 0 then
                      100 - NVL(PCMOV.PERCBASERED,0)
                     else
                      0
                  end
             into PERC_REDUCAO_OUTRASDESP
             from PCMOV
            where rowid = ID_ULTIMO_REGISTRO_PCMOV;

           IF GEROU_OUTROS_FRETE_ULTIMO_REG = 'S' THEN
           update PCMOVCOMPLE
              set PCMOVCOMPLE.VLBASEOUTROS = NVL(PCMOVCOMPLE.VLBASEOUTROS,0) + NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) -
                                             (NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) * (NVL(PERC_REDUCAO_OUTRASDESP,0) / 100))
            where PCMOVCOMPLE.NUMTRANSITEM = ID_ULTIMO_REGISTRO_PCMOVCOMPLE
              and exists (select NUMTRANSITEM
                     from PCMOV
                    where rowid = ID_ULTIMO_REGISTRO_PCMOV
                      and ROUND(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.QTCONT,0), 2) > 0
                      and PCMOV.PERCICM > 0);
           END IF;
        end if;

        --FRETE
        if NVL(VALOR_TOTAL_FRETE,0) <> NVL(VALOR_FRETE_RATEADO,0) then
           VALOR_RATEIO_FRETE_UNITARIO := (NVL(VALOR_TOTAL_FRETE,0) - NVL(VALOR_FRETE_RATEADO,0)) / NVL(QTCONT_ULTIMO_REGISTRO_PCMOV,0);

           update PCMOV
              set PCMOV.VLFRETE = NVL(PCMOV.VLFRETE,0) + NVL(VALOR_RATEIO_FRETE_UNITARIO,0)
            where rowid = ID_ULTIMO_REGISTRO_PCMOV;

           IF GEROU_OUTROS_FRETE_ULTIMO_REG = 'S' THEN
           update PCMOVCOMPLE
              set PCMOVCOMPLE.VLBASEFRETE = NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(VALOR_RATEIO_FRETE_UNITARIO,0) -
                                            (NVL(VALOR_RATEIO_FRETE_UNITARIO,0) * (NVL(PERC_REDUCAO_OUTRASDESP,0) / 100))
            where PCMOVCOMPLE.NUMTRANSITEM = ID_ULTIMO_REGISTRO_PCMOVCOMPLE
              and exists (select NUMTRANSITEM
                     from PCMOV
                    where rowid = ID_ULTIMO_REGISTRO_PCMOV
                      and ROUND(NVL(PCMOV.BASEICMS,0) * NVL(PCMOV.QTCONT,0), 2) > 0
                      and PCMOV.PERCICM > 0);
           END IF;
        end if;
      ELSE
        --OUTRAS DESPESAS
        if NVL(VALOR_TOTAL_OUTROS,0) <> NVL(VALOR_OUTRAS_RATEADO,0)
        then
           VALOR_RATEIO_OUTRAS_UNITARIO := (VALOR_TOTAL_OUTROS - NVL(VALOR_OUTRAS_RATEADO,0)) / NVL(QTCONT_ULTIMO_REGISTRO_PCMOV,0);

           update PCMOVPREFAT
              set PCMOVPREFAT.VLOUTROS = NVL(PCMOVPREFAT.VLOUTROS,0) + NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0)
            where rowid = ID_ULTIMO_REGISTRO_PCMOV;

           select case
                     when NVL(PCMOVPREFAT.PERCBASERED,0) > 0 then
                      100 - NVL(PCMOVPREFAT.PERCBASERED,0)
                     else
                      0
                  end
             into PERC_REDUCAO_OUTRASDESP
             from PCMOVPREFAT
            where rowid = ID_ULTIMO_REGISTRO_PCMOV;

           IF GEROU_OUTROS_FRETE_ULTIMO_REG = 'S' THEN
           update PCMOVCOMPLEPREFAT
              set PCMOVCOMPLEPREFAT.VLBASEOUTROS = NVL(PCMOVCOMPLEPREFAT.VLBASEOUTROS,0) + NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) -
                                                  (NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) * (NVL(PERC_REDUCAO_OUTRASDESP,0) / 100))
            where PCMOVCOMPLEPREFAT.NUMTRANSITEM = ID_ULTIMO_REGISTRO_PCMOVCOMPLE
              and exists (select NUMTRANSITEM
                            from PCMOVPREFAT
                           where rowid = ID_ULTIMO_REGISTRO_PCMOV
                             and ROUND(NVL(PCMOVPREFAT.BASEICMS,0) * NVL(PCMOVPREFAT.QTCONT,0), 2) > 0
                             and PCMOVPREFAT.PERCICM > 0);
           END IF;
        end if;

        --FRETE
        if NVL(VALOR_TOTAL_FRETE,0) <> NVL(VALOR_FRETE_RATEADO,0) then
           VALOR_RATEIO_FRETE_UNITARIO := (NVL(VALOR_TOTAL_FRETE,0) - NVL(VALOR_FRETE_RATEADO,0)) / NVL(QTCONT_ULTIMO_REGISTRO_PCMOV,0);

           update PCMOVPREFAT
              set PCMOVPREFAT.VLFRETE = NVL(PCMOVPREFAT.VLFRETE,0) + NVL(VALOR_RATEIO_FRETE_UNITARIO,0)
            where rowid = ID_ULTIMO_REGISTRO_PCMOV;

           IF GEROU_OUTROS_FRETE_ULTIMO_REG = 'S' THEN
           update PCMOVCOMPLEPREFAT
              set PCMOVCOMPLEPREFAT.VLBASEFRETE = NVL(PCMOVCOMPLEPREFAT.VLBASEFRETE,0) + NVL(VALOR_RATEIO_FRETE_UNITARIO,0) -
                                                 (NVL(VALOR_RATEIO_FRETE_UNITARIO,0) * (NVL(PERC_REDUCAO_OUTRASDESP,0) / 100))
            where PCMOVCOMPLEPREFAT.NUMTRANSITEM = ID_ULTIMO_REGISTRO_PCMOVCOMPLE
              and exists (select NUMTRANSITEM
                     from PCMOVPREFAT
                    where rowid = ID_ULTIMO_REGISTRO_PCMOV
                      and ROUND(NVL(PCMOVPREFAT.BASEICMS,0) * NVL(PCMOVPREFAT.QTCONT,0), 2) > 0
                      and PCMOVPREFAT.PERCICM > 0);
           END IF;
        end if;
      END IF;
      --------------------------------------- FIM ATUALIZAR DIFERENCA DE RATEIO--------------------------------------------------
      --ATUALIZAR INFORMACAO DO RECALCULO REALIZADA.
      update PCNFSAIDPREFAT
         set DESPESASRATEADA = 'S'
       where NUMTRANSVENDA = P_TRANSACAO
         and DATACONSOLIDACAOPREFAT IS NULL;

      if sql%rowcount = 0 then
        update PCNFSAID
           set PCNFSAID.DESPESASRATEADA = 'S'
         where PCNFSAID.NUMTRANSVENDA = P_TRANSACAO;
      end if;
      ---------------------------------------------------------------------------------------------------------
      if MOV_TRANSFERENCIA = 'S'
      then
         for DADOS in (select ME.NUMTRANSENT
                             ,ME.ROWID ID_PCMOV
                             ,CE.ROWID ID_PCMOVCOMPLE
                             ,MS.VLOUTROS
                             ,MS.VLFRETE
                             ,CS.VLBASEOUTROS
                             ,CS.VLBASEFRETE
                             ,'N' PREFATURAMENTO
                         from PCNFSAID    S
                             ,PCMOV       MS
                             ,PCMOVCOMPLE CS
                             ,PCMOV       ME
                             ,PCMOVCOMPLE CE
                        where ME.NUMTRANSITEM = CE.NUMTRANSITEM
                          and ME.NUMTRANSENT = S.NUMTRANSENTORIGEM
                          and ME.CODPROD = MS.CODPROD
                          and S.NUMTRANSVENDA = MS.NUMTRANSVENDA
                          and MS.NUMTRANSITEM = CS.NUMTRANSITEM
                          and S.NUMTRANSVENDA = P_TRANSACAO
                          and MS.QTCONT > 0
                          and ME.QTCONT > 0
                          and S.DTCANCEL is null
                          and MS.DTCANCEL is null
                          and ME.DTCANCEL is null
                        UNION ALL
                       select ME.NUMTRANSENT
                             ,ME.ROWID ID_PCMOV
                             ,CE.ROWID ID_PCMOVCOMPLE
                             ,MS.VLOUTROS
                             ,MS.VLFRETE
                             ,CS.VLBASEOUTROS
                             ,CS.VLBASEFRETE
                             ,'S' PREFATURAMENTO
                         from PCNFSAIDPREFAT    S
                             ,PCMOVPREFAT       MS
                             ,PCMOVCOMPLEPREFAT CS
                             ,PCMOVPREFAT       ME
                             ,PCMOVCOMPLEPREFAT CE
                        where ME.NUMTRANSITEM = CE.NUMTRANSITEM
                          and ME.NUMTRANSENT = S.NUMTRANSENTORIGEM
                          and ME.CODPROD = MS.CODPROD
                          and S.NUMTRANSVENDA = MS.NUMTRANSVENDA
                          and MS.NUMTRANSITEM = CS.NUMTRANSITEM
                          and S.NUMTRANSVENDA = P_TRANSACAO
                          and MS.QTCONT > 0
                          and ME.QTCONT > 0
                          and S.DTCANCEL is null
                          and MS.DTCANCEL is null
                          and ME.DTCANCEL is null
                          AND S.DATACONSOLIDACAOPREFAT IS NULL
                          AND MS.DATACONSOLIDACAOPREFAT IS NULL
                          AND CS.DATACONSOLIDACAOPREFAT IS NULL
                          AND ME.DATACONSOLIDACAOPREFAT IS NULL
                          AND CE.DATACONSOLIDACAOPREFAT IS NULL)
         loop
          if DADOS.PREFATURAMENTO = 'S' THEN
            update PCMOVPREFAT
               set VLOUTROS = NVL(DADOS.VLOUTROS,0)
                  ,VLFRETE  = NVL(DADOS.VLFRETE,0)
             where rowid = DADOS.ID_PCMOV
               AND DATACONSOLIDACAOPREFAT IS NULL;

            update PCMOVCOMPLEPREFAT
               set VLBASEOUTROS = NVL(DADOS.VLBASEOUTROS,0)
                  ,VLBASEFRETE  = NVL(DADOS.VLBASEFRETE,0)
             where rowid = DADOS.ID_PCMOVCOMPLE
               AND DATACONSOLIDACAOPREFAT IS NULL;
          ELSE
            update PCMOV
               set VLOUTROS = NVL(DADOS.VLOUTROS,0)
                  ,VLFRETE  = NVL(DADOS.VLFRETE,0)
             where rowid = DADOS.ID_PCMOV;

            update PCMOVCOMPLE
               set VLBASEOUTROS = NVL(DADOS.VLBASEOUTROS,0)
                  ,VLBASEFRETE  = NVL(DADOS.VLBASEFRETE,0)
             where rowid = DADOS.ID_PCMOVCOMPLE;
           END IF;
           update PCNFENT set DESPESASRATEADA = 'S' where NUMTRANSENT = DADOS.NUMTRANSENT;
         end loop;
      end if;
      ---------------------------------------------------------------------------------------------------------
      MSG := 'OK';
   exception
      when others then
         MSG := 'ERRO AO REALIZAR RATEIO DE DESPESAS' || CHR(13) || 'ERRO ORIGINAL: ' || sqlerrm;
   end;
   --FIM RATEIO OUTRAS DESPESAS
   -------------------------------------------RATEIO OUTRAS DESPESAS DEVOLUCAO ---------------------------------------------
   procedure CALCULAR_RATEIO_DESPESAS_DEVOL(P_TRANSACAO in number
                                           ,MSG         out varchar2) is
      VALOR_TOTAL_FRETE       PCNFENT.VLFRETE%type;
      VALOR_TOTAL_OUTROS      PCNFENT.VLOUTRAS%type;
      VALOR_TOTAL_ACRESCIMOPF number(18, 2);
      VALOR_TOTAL_PRODUTOS    number(18, 2);
      VALOR_TOTAL_REPASSE     number(18, 2);
      VALOR_TOTAL_STOUTRAS    number(18, 2);

      VALOR_OUTRAS_RATEADO         PCMOV.VLOUTROS%type;
      VALOR_RATEIO_OUTRAS_UNITARIO PCMOV.VLOUTROS%type;
      VALOR_FRETE_RATEADO          PCMOV.VLFRETE%type;
      VALOR_RATEIO_FRETE_UNITARIO  PCMOV.VLFRETE%type;
      V_IMPORTADOXML               PCNFENT.IMPORTADOXML%type;

      ID_ULTIMO_REGISTRO_PCMOV       rowid;
      ID_ULTIMO_REGISTRO_PCMOVCOMPLE PCMOVCOMPLE.NUMTRANSITEM%type;
      QTCONT_ULTIMO_REGISTRO_PCMOV   PCMOV.QTCONT%type;
      PERC_REDUCAO_OUTRASDESP        PCNFENT.PERBASEREDOUTRASDESP%type;
      GEROU_OUTROS_FRETE_ULTIMO_REG   VARCHAR2(1);
   begin

      select NVL(PCNFENT.VLFRETE,0) as VALOR_FRETE
            ,NVL(PCNFENT.VLTOTAL,0) - NVL(PCNFENT.VLFRETE, 0) - NVL(PCNFENT.VLOUTRAS, 0) as VALOR_PRODUTOS
            ,sum(NVL(PCMOV.VLACRESCIMOPF,0) * PCMOV.QTCONT) as VALOR_ACRESCIMOPF
            ,SUM( CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFENT.CODFILIAL) AND PCPARAMFILIAL.NOME = 'SOMAREPASSEOUTRASDESPNF'),'N') = 'S') THEN
                    ROUND(NVL(PCMOV.VLREPASSE, 0) * PCMOV.QTCONT)
                  ELSE
                    0
                  END ) AS VALOR_REPASSE
            ,NVL(PCNFENT.VLOUTRAS,0) as VALOR_OUTROS
            ,SUM( CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFENT.CODFILIAL) AND PCPARAMFILIAL.NOME = 'RATEARDESPESASVLSTOUTRAS'),'N') = 'S') THEN
                    ROUND(NVL(PCMOVCOMPLE.VLSTOUTRAS, 0) * PCMOV.QTCONT)
                  ELSE
                    0
                  END ) AS VALOR_STOUTRAS
             ,MAX(NVL(PCNFENT.IMPORTADOXML,'N')) as IMPORTADOXML
        into VALOR_TOTAL_FRETE
            ,VALOR_TOTAL_PRODUTOS
            ,VALOR_TOTAL_ACRESCIMOPF
            ,VALOR_TOTAL_REPASSE
            ,VALOR_TOTAL_OUTROS
            ,VALOR_TOTAL_STOUTRAS
            ,V_IMPORTADOXML
        from PCNFENT
            ,PCMOV
            ,PCMOVCOMPLE
       where PCNFENT.NUMTRANSENT = P_TRANSACAO
         and PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
         and PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
         and PCMOV.QTCONT > 0
       group by NVL(PCNFENT.VLTOTAL,0)
               ,NVL(PCNFENT.VLFRETE,0)
               ,NVL(PCNFENT.VLOUTRAS,0)
               ,NVL(PCNFENT.PERBASEREDOUTRASDESP,0);

      VALOR_TOTAL_OUTROS := NVL(VALOR_TOTAL_OUTROS,0) - NVL(VALOR_TOTAL_ACRESCIMOPF,0) - NVL(VALOR_TOTAL_REPASSE,0) - NVL(VALOR_TOTAL_STOUTRAS,0);

      GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';
      VALOR_OUTRAS_RATEADO := 0;
      VALOR_FRETE_RATEADO  := 0;

      --ATUALIZAR DADOS PCMOV E PCMOVCOMPLE
      for REGISTROS in (select PCMOV.ROWID IDREGISTRO
                              ,PCMOVCOMPLE.NUMTRANSITEM as ITEM_NUMTRANSITEM
                              ,NVL(PCMOV.BASEICMS,0) as ITEM_BASE_ICMS
                              ,NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) as ITEM_ALIQUOTA_ICMS
                              ,PCMOV.CODOPER as ITEM_CODIGO_OPERACAO
                              ,PCMOV.QTCONT as ITEM_QUANTIDADE
                              ,NVL((PCMOV.QTCONT * PCMOV.PUNITCONT), 0) as ITEM_VALOR_TOTAL
                              ,NVL((PCMOV.VLACRESCIMOPF), 0) as ITEM_ACRESCIMOPF
                              ,CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFENT.CODFILIAL) AND PCPARAMFILIAL.NOME = 'SOMAREPASSEOUTRASDESPNF'),'N') = 'S') THEN
                                 NVL((PCMOV.VLREPASSE), 0)
                               ELSE
                                 0
                               END AS ITEM_VLREPASSE
                              ,NVL(PCMOV.VLOUTRASDESP, 0) as ITEM_VLOUTRASDESP
                              ,NVL(PCMOV.VLFRETE, 0) as ITEM_VLFRETE
                              ,NVL(PCMOVCOMPLE.BONIFIC, 'N') as ITEM_BONIFIC
                              ,case
                                  when NVL(PCMOV.PERCBASERED, 0) > 0 then
                                   100 - NVL(PCMOV.PERCBASERED,0)
                                  else
                                   0
                               end as PERC_REDUCAO_OUTRASDESP
	                              ,CASE WHEN (NVL((SELECT PCPARAMFILIAL.VALOR FROM PCPARAMFILIAL WHERE (PCPARAMFILIAL.CODFILIAL = PCNFENT.CODFILIAL) AND PCPARAMFILIAL.NOME = 'RATEARDESPESASVLSTOUTRAS'),'N') = 'S') THEN
                                 NVL((PCMOVCOMPLE.VLSTOUTRAS), 0)
                               ELSE
                                 0
                               END AS ITEM_VLSTOUTRAS
                               ,NVL(PCNFENT.IMPORTADOXML,'N') IMPORTADOXML
                          from PCMOV
                              ,PCNFENT
                              ,PCMOVCOMPLE
                         where PCMOV.NUMTRANSENT = P_TRANSACAO
                           and PCMOV.QTCONT > 0
                           and PCMOV.PUNITCONT > 0
                           and PCNFENT.VLTOTAL > 0
                           and PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
                           and PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                         order by ITEM_VALOR_TOTAL)
      loop

         if (NVL(VALOR_TOTAL_OUTROS,0) > 0) or (NVL(VALOR_TOTAL_FRETE,0) > 0)
         then
            if REGISTROS.ITEM_CODIGO_OPERACAO = 'ED' and REGISTROS.ITEM_BONIFIC = 'N'
            then
               ID_ULTIMO_REGISTRO_PCMOV       := REGISTROS.IDREGISTRO;
               ID_ULTIMO_REGISTRO_PCMOVCOMPLE := REGISTROS.ITEM_NUMTRANSITEM;
               QTCONT_ULTIMO_REGISTRO_PCMOV   := REGISTROS.ITEM_QUANTIDADE;
               -------------------------ATRIBUIR VALOR DE FRETE E OUTRAS DESPESAS AS VARIAVEIS ---------------------------------------
               VALOR_RATEIO_OUTRAS_UNITARIO := NVL(TRUNC(((NVL(REGISTROS.ITEM_VALOR_TOTAL,0) / NVL(VALOR_TOTAL_PRODUTOS,0)) *
                                                         NVL(VALOR_TOTAL_OUTROS,0)),2) / NVL(REGISTROS.ITEM_QUANTIDADE,0),0);

               VALOR_RATEIO_FRETE_UNITARIO := NVL(TRUNC(((NVL(REGISTROS.ITEM_VALOR_TOTAL,0) / NVL(VALOR_TOTAL_PRODUTOS,0)) *
                                                        NVL(VALOR_TOTAL_FRETE,0)),2) / NVL(REGISTROS.ITEM_QUANTIDADE,0),0);

               ----------------------------ATUALIZAR OUTRAS DESP E FRETE DE CADA ITEM--------------------------------------------------
               if REGISTROS.ITEM_NUMTRANSITEM is null
               then
                  --GRAVAR VLFRETE E VLOUTROS PCMOV.
                  update PCMOV
                     set PCMOV.VLOUTROS     = NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) + NVL(REGISTROS.ITEM_ACRESCIMOPF,0) + NVL(REGISTROS.ITEM_VLREPASSE,0) + NVL(REGISTROS.ITEM_VLSTOUTRAS,0)
                        ,PCMOV.VLFRETE      = NVL(VALOR_RATEIO_FRETE_UNITARIO,0)
                        ,PCMOV.NUMTRANSITEM = DFSEQ_PCMOVCOMPLE.NEXTVAL
                   where rowid = REGISTROS.IDREGISTRO;

                  if ROUND(NVL(REGISTROS.ITEM_BASE_ICMS,0) * NVL(REGISTROS.ITEM_QUANTIDADE,0), 2) > 0 and (NVL(REGISTROS.ITEM_ALIQUOTA_ICMS,0) > 0)
                  then
                     insert into PCMOVCOMPLE
                        (NUMTRANSITEM
                        ,DTREGISTRO
                        ,VLBASEFRETE
                        ,VLBASEOUTROS)
                     values
                        (DFSEQ_PCMOVCOMPLE.CURRVAL
                        ,TRUNC(sysdate)
                        ,NVL(VALOR_RATEIO_FRETE_UNITARIO,0)
                        ,NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) - (NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) * (NVL(REGISTROS.PERC_REDUCAO_OUTRASDESP,0) / 100)));

                        GEROU_OUTROS_FRETE_ULTIMO_REG := 'S';
                  ELSE
                        GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';

                  end if;

                  select DFSEQ_PCMOVCOMPLE.CURRVAL into ID_ULTIMO_REGISTRO_PCMOVCOMPLE from DUAL;
               else
                  if ROUND(NVL(REGISTROS.ITEM_BASE_ICMS,0) * NVL(REGISTROS.ITEM_QUANTIDADE,0), 2) > 0 and (NVL(REGISTROS.ITEM_ALIQUOTA_ICMS,0) > 0)
                  then
                     update PCMOVCOMPLE
                        set PCMOVCOMPLE.VLBASEOUTROS = DECODE(REGISTROS.IMPORTADOXML,'S',0, NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) -
                                                       (NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) * (NVL(REGISTROS.PERC_REDUCAO_OUTRASDESP,0) / 100)))
                           ,PCMOVCOMPLE.VLBASEFRETE  = DECODE(REGISTROS.IMPORTADOXML,'S',0,NVL(VALOR_RATEIO_FRETE_UNITARIO,0) -
                                                       (NVL(VALOR_RATEIO_FRETE_UNITARIO,0) * (NVL(REGISTROS.PERC_REDUCAO_OUTRASDESP,0) / 100)))
                      where PCMOVCOMPLE.NUMTRANSITEM = REGISTROS.ITEM_NUMTRANSITEM;

                      GEROU_OUTROS_FRETE_ULTIMO_REG := 'S';
                  else
                      GEROU_OUTROS_FRETE_ULTIMO_REG := 'N';

                  end if;

                  update PCMOV
                     set PCMOV.VLOUTROS = NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) + NVL(REGISTROS.ITEM_ACRESCIMOPF,0) + NVL(REGISTROS.ITEM_VLREPASSE,0) + NVL(REGISTROS.ITEM_VLSTOUTRAS,0)
                        ,PCMOV.VLFRETE  = NVL(VALOR_RATEIO_FRETE_UNITARIO,0)
                   where rowid = REGISTROS.IDREGISTRO;

               end if;

               --SOMANDO O VALOR DE OUTRAS DESPESAS JA RATEADO
               VALOR_OUTRAS_RATEADO := NVL(VALOR_OUTRAS_RATEADO,0) + ROUND(NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) * NVL(REGISTROS.ITEM_QUANTIDADE,0),2);
               --SOMANDO O VALOR DO FRETE JA RATEADO
               VALOR_FRETE_RATEADO := NVL(VALOR_FRETE_RATEADO,0) + ROUND(NVL(VALOR_RATEIO_FRETE_UNITARIO,0) * NVL(REGISTROS.ITEM_QUANTIDADE,0),2);
            end if;
         end if;
      end loop;
      ------------------------------------------ATUALIZAR DIFERENCA DE RATEIO----------------------------------------------------
      --OUTRAS DESPESAS
      if NVL(VALOR_TOTAL_OUTROS,0) <> NVL(VALOR_OUTRAS_RATEADO,0)
      then
         VALOR_RATEIO_OUTRAS_UNITARIO := (NVL(VALOR_TOTAL_OUTROS,0) - NVL(VALOR_OUTRAS_RATEADO,0)) / NVL(QTCONT_ULTIMO_REGISTRO_PCMOV,0);

         update PCMOV
            set PCMOV.VLOUTROS = NVL(PCMOV.VLOUTROS,0) + NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0)
          where rowid = ID_ULTIMO_REGISTRO_PCMOV;

         select NVL(PCMOV.PERCBASERED, 0)
           into PERC_REDUCAO_OUTRASDESP
           from PCMOV
          where rowid = ID_ULTIMO_REGISTRO_PCMOV;

          IF GEROU_OUTROS_FRETE_ULTIMO_REG = 'S' THEN
             update PCMOVCOMPLE
             set PCMOVCOMPLE.VLBASEOUTROS = DECODE(V_IMPORTADOXML,'S',0,NVL(PCMOVCOMPLE.VLBASEOUTROS,0) + NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) -
                                           (NVL(VALOR_RATEIO_OUTRAS_UNITARIO,0) * (NVL(PERC_REDUCAO_OUTRASDESP,0) / 100)))
             where PCMOVCOMPLE.NUMTRANSITEM = ID_ULTIMO_REGISTRO_PCMOVCOMPLE;
          END IF;
      end if;

      --FRETE
      if NVL(VALOR_TOTAL_FRETE,0) <> NVL(VALOR_FRETE_RATEADO,0)
      then
         VALOR_RATEIO_FRETE_UNITARIO := (NVL(VALOR_TOTAL_FRETE,0) - NVL(VALOR_FRETE_RATEADO,0)) / NVL(QTCONT_ULTIMO_REGISTRO_PCMOV,0);

         update PCMOV
            set PCMOV.VLFRETE = NVL(PCMOV.VLFRETE,0) + NVL(VALOR_RATEIO_FRETE_UNITARIO,0)
          where rowid = ID_ULTIMO_REGISTRO_PCMOV;
        IF GEROU_OUTROS_FRETE_ULTIMO_REG = 'S' THEN
           update PCMOVCOMPLE
              set PCMOVCOMPLE.VLBASEFRETE = DECODE(V_IMPORTADOXML,'S',0,NVL(PCMOVCOMPLE.VLBASEFRETE,0) + NVL(VALOR_RATEIO_FRETE_UNITARIO,0) -
                                          (NVL(VALOR_RATEIO_FRETE_UNITARIO,0) * (NVL(PERC_REDUCAO_OUTRASDESP,0) / 100)))
            where PCMOVCOMPLE.NUMTRANSITEM = ID_ULTIMO_REGISTRO_PCMOVCOMPLE;
        END IF;
      end if;

      --------------------------------------- FIM ATUALIZAR DIFERENCA DE RATEIO--------------------------------------------------
      --ATUALIZAR INFORMA??O DO RECALCULO REALIZADA.
      update PCNFENT set PCNFENT.DESPESASRATEADA = 'S' where PCNFENT.NUMTRANSENT = P_TRANSACAO;

      MSG := 'OK';
   exception
      when others then
         MSG := 'ERRO AO REALIZAR RATEIO DE DESPESAS DEVOLUCAO' || CHR(13) || 'ERRO ORIGINAL: ' ||
                sqlerrm;
   end;
   --FIM RATEIO OUTRAS DESPESAS DEVOLUCAO

   function GET_DADOS_TRIBUTACAO_IPI(P_CODCLI           in number
                                    ,P_CODPROD          in number
                                    ,P_CODFILIAL        in varchar2
                                    ,P_DATAOPERACAO     in date
                                    ,P_CST_ENTRADA      out number
                                    ,P_CST_SAIDA        out number
                                    ,P_GERABASEALIQZERO out varchar2
                                    ,P_MSG              out varchar2
                                    ,P_CODFISCAL        in number
                                    ,P_TIPO_VENDA       in varchar2
                                    ,P_TIPO_ENTRADA     in varchar2
                                    ,P_CODIGO_OPERACAO  in varchar2
                                    ,P_FINALIDADENFE    in varchar2 := 'N') return varchar2 is

        P_CODENQENTRADA varchar2(6);
        P_CODENQSAIDA   varchar2(6);
   begin
      -- Nota complementar não deve calcular ipi
      if (NVL(P_FINALIDADENFE, 'N') = 'C') then
        P_CST_ENTRADA := '49';
        P_CST_SAIDA := '99';
        P_GERABASEALIQZERO := 'S';
        P_MSG := 'NOTA COMPLEMENTAR NÃO TEM IPI';
        return 'S';
      end if;

      return fiscal.GET_DADOS_TRIBUTACAO_IPI(P_CODCLI
                                    ,P_CODPROD
                                    ,P_CODFILIAL
                                    ,P_DATAOPERACAO
                                    ,P_CST_ENTRADA
                                    ,P_CST_SAIDA
                                    ,P_GERABASEALIQZERO
                                    ,P_MSG
                                    ,P_CODFISCAL
                                    ,P_TIPO_VENDA
                                    ,P_TIPO_ENTRADA
                                    ,P_CODIGO_OPERACAO
                                    ,P_CODENQENTRADA
                                    ,P_CODENQSAIDA
                                    ,P_FINALIDADENFE);
   end;

  --CALCULA ICMS DESONERADO
  function CALCULARDESONERACAOICMS_SAIDA(NUMTRANSACAO in number,
                                         MSG          out varchar2)
    return varchar2 is
    VFALHATRIBUTACAO exception;
    VMOTIVODESONERACAO number;
    VVALORDESONERADO NUMBER;
    VVALOR_ST_DESONERADO NUMBER;
    VTIPOCLIENTE VARCHAR2(5);
    vDESCONSIDERAR_SUFRAMA_DESCICM VARCHAR2(1);
    vINCLUIRICMSBASEDESONERACAO    VARCHAR2(1);
    vINDDEDUZDESONERACAO           VARCHAR2(1);
  begin
    begin
      -- PEGANDO CODFILIAL DA NOTA FISCAL ------------------------------
      begin
        WITH NFSAID AS(
          select NVL(CODFILIALNF, CODFILIAL) CODFILIAL
            from PCNFSAID
           where NUMTRANSVENDA = NUMTRANSACAO
           UNION ALL
          select NVL(CODFILIALNF, CODFILIAL) CODFILIAL
            from PCNFSAIDPREFAT
           where NUMTRANSVENDA = NUMTRANSACAO
             AND DATACONSOLIDACAOPREFAT IS NULL
        )select CODFILIAL
          into VCODFILIAL
          from NFSAID;
      exception
        when others then
          MSG := 'N:NOTA FISCAL INEXISTENTE OU COD.FILIAL NÃO INFORMADO!';
          raise VFALHATRIBUTACAO;
      end;

      -- VALIDANDO TIPO DE NOTA FISCAL (SEM ITENS N?O ? CONTEMPLADO) ----
      begin
        WITH MOV AS(
          select NVL(CODFILIALNF, CODFILIAL) CODFILIAL
            from PCMOV
           where NUMTRANSVENDA = NUMTRANSACAO
             and ROWNUM = 1
           UNION ALL
          select NVL(CODFILIALNF, CODFILIAL) CODFILIAL
            from PCMOVPREFAT
           where NUMTRANSVENDA = NUMTRANSACAO
             and ROWNUM = 1
             AND DATACONSOLIDACAOPREFAT IS NULL
        )select CODFILIAL
          into VCODFILIAL
          from MOV;

      exception
        when others then
          MSG := 'S:NOTA FISCAL SEM ITEM! O PROCEDIMENTO NÃO CONTEMPLA ESTE TIPO DE DOCUMENTO.';
          return 'S';
      end;

      for DADOS in (SELECT M.NUMTRANSVENDA NUMTRANSACAO,
                           C.CODCLI,
                           CASE
                             WHEN (TRIM(C.SULFRAMA) IS NOT NULL AND
                                  C.DTVENCSUFRAMA >= N.DTSAIDA) THEN
                              'S'
                             ELSE
                              'N'
                           END CLI_SUFRAMA,
                           CASE
                             WHEN (NVL(N.ORGAOPUBMUNICIPAL, 'N') = 'S') OR
                                  (NVL(N.ORGAOPUB, 'N') = 'S') OR
                                  (NVL(N.ORGAOPUBFEDERAL, 'N') = 'S') THEN
                              'S'
                             ELSE
                              'N'
                           END CLI_ORGAO_PUBLICO,
                           case
                             when ((nvl(c.tipoempresa, 'N') = 'PR') and
                                  (nvl(c.ieent, 'N') <> 'N')) then
                              'S'
                             else
                              'N'
                           end CLI_PRODUTOR_RURAL,
                           case
                             WHEN nvl(c.tipoempresa, 'N') = 'R' then
                              'S'
                             else
                              'N'
                           end CLI_REGIME_ESPECIAL,
                           case
                             WHEN nvl(c.tipoempresa, 'N') = 'O' then
                              'S'
                             else
                              'N'
                           end CLI_OUTROS,
                           M.ROWID IDREGISTRO,
                           M.SITTRIBUT,
                           M.CODPROD,
                           M.NUMTRANSITEM,
                           NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
                           --C?LCULO DO VALOR DO ICMS DESONERADO
                          DECODE(NVL(M.VLDESCSUFRAMA,0),0, NVL(M.VLDESCICMISENCAO,0),NVL(M.VLDESCSUFRAMA,0)) VLDESCSUFRAMA,
                          nvl(M.VLDESCICMISENCAO,0) VLDESCICMISENCAO,
                          nvl(M.PERCBASERED, 0) as PERCBASERED,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) *
                                    (1 - (NVL(M.PERCBASERED,0) / 100)))) * ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100)), 6) VLREDUCAO_SEM_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) *
                                    (1 - (NVL(M.PERCBASERED,0) / 100))) / (1 - ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100))) * ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100)), 6)  VLREDUCAO_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           CASE WHEN M.CODFISCAL BETWEEN 5000 AND 5999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0)))) *
                                          (NVL(PF.PERCALIQVIGINT, 0) / 100)), 6)
                               WHEN M.CODFISCAL BETWEEN 6000 AND 6999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0)))) *
                                  (NVL(PF.PERCALIQVIGEXT, 0) / 100)), 6)
                               ELSE
                                 0
                           END AS VLISENCAO_SEM_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           CASE WHEN M.CODFISCAL BETWEEN 5000 AND 5999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) /
                                          (1 - (NVL(PF.PERCALIQVIGINT, 0) / 100))) * (NVL(PF.PERCALIQVIGINT, 0) / 100)), 6)
                               WHEN M.CODFISCAL BETWEEN 6000 AND 6999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) /
                                          (1 - (NVL(PF.PERCALIQVIGEXT, 0) / 100))) * (NVL(PF.PERCALIQVIGEXT, 0) / 100)), 6)
                               ELSE
                                 0
                           END AS VLISENCAO_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.BASEICST ,0) ) *
                                    (1 - (NVL(M.PERCBASEREDST,0) / 100)))) * ((NVL(M.PERCICM,0) + NVL(MC.ALIQICMSFECP ,0)) / 100)), 6) VLREDUCAO_ST_SEM_ACRES_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.BASEICST ,0)) *
                                    (1 - (NVL(M.PERCBASEREDST,0) / 100))) / (1 - ((NVL(M.PERCICM,0) + NVL(MC.ALIQICMSFECP ,0)) / 100))) * ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100)), 6)  VLREDUCAO_ST_ACRES_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                          'N' PREFATURAMENTO,
                          N.FINALIDADENFE,
                          M.PERCBASEREDST
                      FROM PCNFSAID              N,
                           PCMOV                 M,
                           PCMOVCOMPLE           MC,
                           PCCLIENT              C,
                           PCPRODUT              PD,
                           PCPRODFILIAL          PF
                     WHERE M.NUMTRANSVENDA = N.NUMTRANSVENDA
                       AND n.numtransvenda = NUMTRANSACAO
                       AND M.CODPROD = PD.CODPROD
                       AND MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                       AND M.CODPROD = PF.CODPROD(+)
                       AND M.CODFILIAL = PF.CODFILIAL(+)
                       AND C.CODCLI = DECODE(NVL(N.CODCLINF, 0),
                                             0,
                                             N.CODCLI,
                                             N.CODCLINF)
                       AND M.STATUS IN ('A', 'AB')
                       AND M.QTCONT > 0
                       AND M.DTCANCEL IS NULL
                       AND N.DTCANCEL IS NULL
               UNION ALL
                    SELECT M.NUMTRANSVENDA NUMTRANSACAO,
                           C.CODCLI,
                           CASE
                             WHEN (TRIM(C.SULFRAMA) IS NOT NULL AND
                                  C.DTVENCSUFRAMA >= N.DTSAIDA) THEN
                              'S'
                             ELSE
                              'N'
                           END CLI_SUFRAMA,
                           CASE
                             WHEN (NVL(N.ORGAOPUBMUNICIPAL, 'N') = 'S') OR
                                  (NVL(N.ORGAOPUB, 'N') = 'S') OR
                                  (NVL(N.ORGAOPUBFEDERAL, 'N') = 'S') THEN
                              'S'
                             ELSE
                              'N'
                           END CLI_ORGAO_PUBLICO,
                           case
                             when ((nvl(c.tipoempresa, 'N') = 'PR') and
                                  (nvl(c.ieent, 'N') <> 'N')) then
                              'S'
                             else
                              'N'
                           end CLI_PRODUTOR_RURAL,
                           case
                             WHEN nvl(c.tipoempresa, 'N') = 'R' then
                              'S'
                             else
                              'N'
                           end CLI_REGIME_ESPECIAL,
                           case
                             WHEN nvl(c.tipoempresa, 'N') = 'O' then
                              'S'
                             else
                              'N'
                           end CLI_OUTROS,
                           M.ROWID IDREGISTRO,
                           M.SITTRIBUT,
                           M.CODPROD,
                           M.NUMTRANSITEM,
                           NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
                           --C?LCULO DO VALOR DO ICMS DESONERADO
                           DECODE(NVL(M.VLDESCSUFRAMA,0),0, NVL(M.VLDESCICMISENCAO,0),NVL(M.VLDESCSUFRAMA,0)) VLDESCSUFRAMA,
                           nvl(M.VLDESCICMISENCAO,0) VLDESCICMISENCAO,
                           nvl(M.PERCBASERED, 0) as PERCBASERED,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) *
                                    (1 - (NVL(M.PERCBASERED,0) / 100)))) * ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100)), 6) VLREDUCAO_SEM_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) *
                                    (1 - (NVL(M.PERCBASERED,0) / 100))) / (1 - ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100))) * ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100)), 6)  VLREDUCAO_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           CASE WHEN M.CODFISCAL BETWEEN 5000 AND 5999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0)))) *
                                          (NVL(PF.PERCALIQVIGINT, 0) / 100)), 6)
                               WHEN M.CODFISCAL BETWEEN 6000 AND 6999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0)))) *
                                  (NVL(PF.PERCALIQVIGEXT, 0) / 100)), 6)
                               ELSE
                                 0
                           END AS VLISENCAO_SEM_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           CASE WHEN M.CODFISCAL BETWEEN 5000 AND 5999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) /
                                          (1 - (NVL(PF.PERCALIQVIGINT, 0) / 100))) * (NVL(PF.PERCALIQVIGINT, 0) / 100)), 6)
                               WHEN M.CODFISCAL BETWEEN 6000 AND 6999 THEN
                                 ROUND((( (NVL(M.PUNITCONT,0) - NVL(M.VLIPI,0) - NVL(M.ST,0) - DECODE(NVL(MC.VLBASEFCPST, 0), 0, 0,NVL(MC.VLFECP, 0))) /
                                          (1 - (NVL(PF.PERCALIQVIGEXT, 0) / 100))) * (NVL(PF.PERCALIQVIGEXT, 0) / 100)), 6)
                               ELSE
                                 0
                           END AS VLISENCAO_ACRESCIMO_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.BASEICST ,0) ) *
                                    (1 - (NVL(M.PERCBASEREDST,0) / 100)))) * ((NVL(M.PERCICM,0) + NVL(MC.ALIQICMSFECP ,0)) / 100)), 6) VLREDUCAO_ST_SEM_ACRES_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           ROUND(((( (NVL(M.BASEICST ,0)) *
                                    (1 - (NVL(M.PERCBASEREDST,0) / 100))) / (1 - ((NVL(M.PERCICM,0) + NVL(MC.ALIQICMSFECP ,0)) / 100))) * ((NVL(M.PERCICM,0) + NVL(MC.PERACRESCIMOFUNCEP,0)) / 100)), 6)  VLREDUCAO_ST_ACRES_ICMS,
                           -------------------------------------------------------------------------------------------------------------------
                           'S' PREFATURAMENTO,
                           N.FINALIDADENFE,
                           M.PERCBASEREDST
                      FROM PCNFSAIDPREFAT              N,
                           PCMOVPREFAT                 M,
                           PCMOVCOMPLEPREFAT           MC,
                           PCCLIENT              C,
                           PCPRODUT              PD,
                           PCPRODFILIAL          PF
                     WHERE M.NUMTRANSVENDA = N.NUMTRANSVENDA
                       AND n.numtransvenda = NUMTRANSACAO
                       AND M.CODPROD = PD.CODPROD
                       AND MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                       AND M.CODPROD = PF.CODPROD(+)
                       AND M.CODFILIAL = PF.CODFILIAL(+)
                       AND C.CODCLI = DECODE(NVL(N.CODCLINF, 0),
                                             0,
                                             N.CODCLI,
                                             N.CODCLINF)
                       AND M.STATUS IN ('A', 'AB')
                       AND M.QTCONT > 0
                       AND M.DTCANCEL IS NULL
                       AND N.DTCANCEL IS NULL
                       AND N.DATACONSOLIDACAOPREFAT IS NULL
                       AND N.DATACONSOLIDACAOPREFAT IS NULL
                       AND M.DATACONSOLIDACAOPREFAT IS NULL
                       AND MC.DATACONSOLIDACAOPREFAT IS NULL
                     ) loop

        if ((DADOS.CLI_PRODUTOR_RURAL = 'S') or
            (DADOS.CLI_SUFRAMA = 'S') or
            (DADOS.CLI_ORGAO_PUBLICO = 'S') or
            (DADOS.CLI_REGIME_ESPECIAL = 'S') or
            (DADOS.CLI_OUTROS = 'S') or
            ((DADOS.VLREDUCAO_ACRESCIMO_ICMS + DADOS.VLISENCAO_ACRESCIMO_ICMS + DADOS.VLREDUCAO_ST_ACRES_ICMS) > 0) or
            (((DADOS.VLREDUCAO_ACRESCIMO_ICMS + DADOS.VLISENCAO_ACRESCIMO_ICMS) = 0) and DADOS.FINALIDADENFE = 'C') ) then

          vINDDEDUZDESONERACAO := '';

          VMOTIVODESONERACAO := NVL(GET_MOTIVO_DESONICMS(DADOS.SITTRIBUT,
                                                         DADOS.CODFILIAL,
                                                         DADOS.CLI_PRODUTOR_RURAL,
                                                         DADOS.CLI_SUFRAMA,
                                                         DADOS.CLI_ORGAO_PUBLICO,
                                                         DADOS.CLI_REGIME_ESPECIAL,
                                                         DADOS.CODCLI,
                                                         DADOS.CODPROD,
                                                         VTIPOCLIENTE,
                                                         VDESCONSIDERAR_SUFRAMA_DESCICM,
                                                         VINCLUIRICMSBASEDESONERACAO),
                                                         0);


          if ((VMOTIVODESONERACAO > 0) and (((dados.VLDESCSUFRAMA + DADOS.VLDESCICMISENCAO) > 0) or ((DADOS.VLREDUCAO_ACRESCIMO_ICMS +
                                                                                                      DADOS.VLISENCAO_ACRESCIMO_ICMS +
                                                                                                      DADOS.VLREDUCAO_ST_ACRES_ICMS) > 0))) then

            VVALORDESONERADO     := 0;
            VVALOR_ST_DESONERADO := 0;
            vINDDEDUZDESONERACAO := '0';

            if (((DADOS.CLI_ORGAO_PUBLICO = 'S') OR
                 (DADOS.CLI_REGIME_ESPECIAL = 'S') OR
                 (DADOS.CLI_PRODUTOR_RURAL = 'S') OR
                 (DADOS.CLI_OUTROS = 'S') OR
                 (DADOS.CLI_SUFRAMA = 'S')) OR
                 ((VTIPOCLIENTE = 'NI') AND (VMOTIVODESONERACAO = 9)) ) AND
               (DADOS.SITTRIBUT IN ('20', '30', '40', '41', '50', '70', '90')) then

              if (DADOS.SITTRIBUT IN ('20', '70', '90')) then
                if (VINCLUIRICMSBASEDESONERACAO = 'S') then
                  if (DADOS.PERCBASERED > 0) then
                    VVALORDESONERADO := DADOS.VLREDUCAO_ACRESCIMO_ICMS;
                  end if;

                  if (DADOS.PERCBASEREDST > 0) then
                    VVALOR_ST_DESONERADO := DADOS.VLREDUCAO_ST_ACRES_ICMS;
                  end if;
                else
                  if (DADOS.PERCBASERED > 0) then
                    VVALORDESONERADO := DADOS.VLREDUCAO_SEM_ACRESCIMO_ICMS;
                  end if;

                  if (DADOS.PERCBASEREDST > 0) then
                    VVALOR_ST_DESONERADO := DADOS.VLREDUCAO_ST_SEM_ACRES_ICMS;
                  end if;
                end if;
              end if;

              if (DADOS.SITTRIBUT IN ('30', '40', '41', '50')) then
                if (VINCLUIRICMSBASEDESONERACAO = 'S') then
                  VVALORDESONERADO := DADOS.VLISENCAO_ACRESCIMO_ICMS;
                else
                  VVALORDESONERADO := DADOS.VLISENCAO_SEM_ACRESCIMO_ICMS;
                end if;
              end if;
            end if;

            if ((DADOS.CLI_SUFRAMA = 'S') and (DADOS.VLDESCSUFRAMA > 0)) then
               VVALORDESONERADO := DADOS.VLDESCSUFRAMA;
               vINDDEDUZDESONERACAO := '1';
            end if;

            if (((DADOS.CLI_ORGAO_PUBLICO = 'S') OR
                 (DADOS.CLI_REGIME_ESPECIAL = 'S') OR
                 (DADOS.CLI_PRODUTOR_RURAL = 'S') OR
                 (DADOS.CLI_OUTROS = 'S') OR
                 (VTIPOCLIENTE = 'NI') )  AND
                 (DADOS.VLDESCICMISENCAO > 0)) then
               VVALORDESONERADO := DADOS.VLDESCICMISENCAO;
               vINDDEDUZDESONERACAO := '1';
            end if;

            --SÓ GRAVA MOTIVO E VALOR CASO TENHA VALOR, POIS SE GRAVAR VALOR ZERO E MOTIVO, DA REJEIÇÃO
            IF (VVALORDESONERADO + VVALOR_ST_DESONERADO > 0) THEN
              IF DADOS.PREFATURAMENTO = 'N' THEN
                update PCMOVCOMPLE
                   set PCMOVCOMPLE.VLICMSDESONERACAO = VVALORDESONERADO,
                       PCMOVCOMPLE.VICMSSTDESON      = VVALOR_ST_DESONERADO,
                       CODMOTIVOICMSDESONERADO       = VMOTIVODESONERACAO,
                       INDDEDUZDESONERACAO           = vINDDEDUZDESONERACAO
                 where NUMTRANSITEM = DADOS.NUMTRANSITEM;

                if sql%rowcount = 0 then
                  insert into PCMOVCOMPLE
                    (NUMTRANSITEM,
                     DTREGISTRO,
                     VLICMSDESONERACAO,
                     VICMSSTDESON,
                     CODMOTIVOICMSDESONERADO,
                     INDDEDUZDESONERACAO)
                  values
                    (DFSEQ_PCMOVCOMPLE.CURRVAL,
                     TRUNC(sysdate),
                     VVALORDESONERADO,
                     VVALOR_ST_DESONERADO,
                     VMOTIVODESONERACAO,
                     vINDDEDUZDESONERACAO);
                end if;
              ELSE
                update PCMOVCOMPLEPREFAT
                   set PCMOVCOMPLEPREFAT.VLICMSDESONERACAO = VVALORDESONERADO,
                       PCMOVCOMPLEPREFAT.VICMSSTDESON      = VVALOR_ST_DESONERADO,
                       CODMOTIVOICMSDESONERADO             = VMOTIVODESONERACAO,
                       INDDEDUZDESONERACAO                 = vINDDEDUZDESONERACAO
                 where NUMTRANSITEM = DADOS.NUMTRANSITEM;

                if sql%rowcount = 0 then
                  insert into PCMOVCOMPLEPREFAT
                    (NUMTRANSITEM,
                     DTREGISTRO,
                     VLICMSDESONERACAO,
                     VICMSSTDESON,
                     CODMOTIVOICMSDESONERADO,
                     INDDEDUZDESONERACAO)
                  values
                    (DFSEQ_PCMOVCOMPLE.CURRVAL,
                     TRUNC(sysdate),
                     VVALORDESONERADO,
                     VVALOR_ST_DESONERADO,
                     VMOTIVODESONERACAO,
                     vINDDEDUZDESONERACAO);
                end if;
              END IF;
               --  HABILITANDO SERVIÇO LOG
               PKG_DEBUGGING_FWPC.ATIVARDEBUG('Cálculo Desoneração ICMS Saída', '1.0',NUMTRANSACAO);
               -- GRAVANDO LOG
               PKG_DEBUGGING_FWPC.LOG('Produto: ' || DADOS.CODPROD || ' Cod.Motivo: ' || VMOTIVODESONERACAO , 'S');
               -- DESABILITANDO SERVIÇO LOG
               PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
            END IF;


          else
            MSG := MSG ||
                   'S:NÃO FOI ENCONTRADO CADASTRO DE TRIBUTAÇÃO, VERIFIQUE ROTINA 4003! CST NÃO ENCONTRADAO : ' ||
                   DADOS.SITTRIBUT;
          end if;
        end if;
      end loop;

      if NVL(MSG, 'X') = 'X' then
        MSG := 'S:Desoneração do ICMS calculado';
      end if;

      return 'S';
    exception
      when VFALHATRIBUTACAO then
        return 'S';

      when others then
        MSG := 'N:Erro ao calcular Desoneração do ICMS. ' || CHR(13) ||
               'Erro original: ' || sqlerrm;
        return 'S';
    end;
  end;

   PROCEDURE GRAVAR_ENQUADRAMENTO_IPI(P_TRANSACAO IN NUMBER,
                                     P_MOVIMENTO IN VARCHAR2,
                                     MSG OUT VARCHAR2) IS
    VMENSAGENS VARCHAR2(4000);
  BEGIN
    VMENSAGENS := '';
    IF P_MOVIMENTO = 'E' THEN
      FOR DADOS IN (SELECT MC.NUMTRANSITEM,
                           M.CODPROD,
                           MC.CODENQIPI,
                           M.NUMTRANSENT,
                           T.CODFIGURAIPI,
                           F.CODENQENTRADA
                      FROM PCMOV           M,
                           PCTRIBIPI       T,
                           PCMOVCOMPLE     MC,
                           PCFIGURATRIBIPI F
                     WHERE M.CODPROD = T.CODPROD
                       AND M.CODFILIAL = T.CODFILIAL
                       AND M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                       AND M.NUMTRANSENT = P_TRANSACAO
                       AND T.CODFIGURAIPI = F.CODFIGURAIPI
                     UNION ALL
                    SELECT MC.NUMTRANSITEM,
                           M.CODPROD,
                           MC.CODENQIPI,
                           M.NUMTRANSENT,
                           T.CODFIGURAIPI,
                           F.CODENQENTRADA
                      FROM PCMOVPREFAT           M,
                           PCTRIBIPI       T,
                           PCMOVCOMPLEPREFAT     MC,
                           PCFIGURATRIBIPI F
                     WHERE M.CODPROD = T.CODPROD
                       AND M.CODFILIAL = T.CODFILIAL
                       AND M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                       AND M.NUMTRANSENT = P_TRANSACAO
                       AND T.CODFIGURAIPI = F.CODFIGURAIPI
                       AND M.DATACONSOLIDACAOPREFAT IS NULL
                       AND MC.DATACONSOLIDACAOPREFAT IS NULL) LOOP
        IF DADOS.CODENQIPI IS NULL THEN
          IF DADOS.CODFIGURAIPI IS NULL THEN
            VMENSAGENS := VMENSAGENS ||
                          'FIGURA TRIBUTÁRIA DO IPI INEXISTENTE OU NÃO VINCULADA, PRODUTO:' ||
                          DADOS.CODPROD;
          ELSE
            UPDATE PCMOVCOMPLE
               SET CODENQIPI = DADOS.CODENQENTRADA
             WHERE NUMTRANSITEM = DADOS.NUMTRANSITEM;

            IF SQL%ROWCOUNT = 0 THEN
               UPDATE PCMOV
               SET NUMTRANSITEM = DFSEQ_PCMOVCOMPLE.NEXTVAL
               WHERE NUMTRANSENT = DADOS.NUMTRANSENT
               AND CODPROD = DADOS.CODPROD;

              INSERT INTO PCMOVCOMPLE(NUMTRANSITEM, DTREGISTRO, CODENQIPI)
              VALUES(DFSEQ_PCMOVCOMPLE.CURRVAL,
                     TRUNC(SYSDATE),
                     DADOS.CODENQENTRADA);
            END IF;
          END IF;
        END IF;
      END LOOP;

    ELSIF P_MOVIMENTO = 'S' THEN

      FOR DADOS IN (SELECT MC.NUMTRANSITEM,
                           M.CODPROD,
                           MC.CODENQIPI,
                           T.CODFIGURAIPI,
                           M.NUMTRANSVENDA,
                           F.CODENQSAIDA,
                           'N' PREFATURAMENTO
                      FROM PCMOV           M,
                           PCTRIBIPI       T,
                           PCMOVCOMPLE     MC,
                           PCFIGURATRIBIPI F
                     WHERE M.CODPROD = T.CODPROD
                       AND M.CODFILIAL = T.CODFILIAL
                       AND M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                       AND M.NUMTRANSVENDA = P_TRANSACAO
                       AND T.CODFIGURAIPI = F.CODFIGURAIPI
                     UNION ALL
                    SELECT MC.NUMTRANSITEM,
                           M.CODPROD,
                           MC.CODENQIPI,
                           T.CODFIGURAIPI,
                           M.NUMTRANSVENDA,
                           F.CODENQSAIDA,
                           'S' PREFATURAMENTO
                      FROM PCMOVPREFAT           M,
                           PCTRIBIPI       T,
                           PCMOVCOMPLEPREFAT     MC,
                           PCFIGURATRIBIPI F
                     WHERE M.CODPROD = T.CODPROD
                       AND M.CODFILIAL = T.CODFILIAL
                       AND M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                       AND M.NUMTRANSVENDA = P_TRANSACAO
                       AND T.CODFIGURAIPI = F.CODFIGURAIPI
                       AND M.DATACONSOLIDACAOPREFAT IS NULL
                       AND MC.DATACONSOLIDACAOPREFAT IS NULL) LOOP
        IF DADOS.CODENQIPI IS NULL THEN
          IF DADOS.CODFIGURAIPI IS NULL THEN
            VMENSAGENS := VMENSAGENS ||
                          'FIGURA TRIBUTÁRIA DO IPI INEXISTENTE OU NÃO VINCULADA, PRODUTO:' ||
                          DADOS.CODPROD;
          ELSE
              IF DADOS.PREFATURAMENTO = 'N' THEN
              UPDATE PCMOVCOMPLE
                 SET CODENQIPI = DADOS.CODENQSAIDA
               WHERE NUMTRANSITEM = DADOS.NUMTRANSITEM;

              IF SQL%ROWCOUNT = 0 THEN
                 UPDATE PCMOV
                 SET NUMTRANSITEM = DFSEQ_PCMOVCOMPLE.NEXTVAL
                 WHERE NUMTRANSVENDA = DADOS.NUMTRANSVENDA
                 AND CODPROD = DADOS.CODPROD;

                INSERT INTO PCMOVCOMPLE(NUMTRANSITEM, DTREGISTRO, CODENQIPI)
                VALUES (DFSEQ_PCMOVCOMPLE.CURRVAL,
                        TRUNC(SYSDATE),
                        DADOS.CODENQSAIDA);
              END IF;
            ELSE
              UPDATE PCMOVCOMPLEPREFAT
                 SET CODENQIPI = DADOS.CODENQSAIDA
               WHERE NUMTRANSITEM = DADOS.NUMTRANSITEM;

              IF SQL%ROWCOUNT = 0 THEN
                 UPDATE PCMOVPREFAT
                 SET NUMTRANSITEM = DFSEQ_PCMOVCOMPLE.NEXTVAL
                 WHERE NUMTRANSVENDA = DADOS.NUMTRANSVENDA
                 AND CODPROD = DADOS.CODPROD;

                INSERT INTO PCMOVCOMPLEPREFAT(NUMTRANSITEM, DTREGISTRO, CODENQIPI)
                VALUES (DFSEQ_PCMOVCOMPLE.CURRVAL,
                        TRUNC(SYSDATE),
                        DADOS.CODENQSAIDA);
              END IF;
            END IF;
          END IF;
        END IF;
      END LOOP;

      IF NVL(TRIM(VMENSAGENS),'N') <> 'N' THEN
         MSG := TRIM(VMENSAGENS);
      ELSE
         MSG := 'S:ENQUADRAMENTO IPI CALCULADO.';
      END IF;
    END IF;
  END;

  FUNCTION GET_CONTA_CONTABIL_SPED(P_COD_FILIAL IN VARCHAR2,
                                   P_ESPECIE    IN VARCHAR2,
                                   P_CFOP       IN VARCHAR2,
                                   P_CST        IN VARCHAR2)
    RETURN VARCHAR2 IS
    vCONTA_CONTABIL_SPED VARCHAR2(255);
    P_MENSAGEM_RETORNO VARCHAR2(255);
    V_ESPECIE VARCHAR2(5);
  BEGIN
    vCONTA_CONTABIL_SPED := NULL;

    IF P_COD_FILIAL IS NULL THEN
      P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_COD_FILIAL NÃO FOI INFORMADO.';
      RAISE_APPLICATION_ERROR(-20999,P_MENSAGEM_RETORNO);
    END IF;
    --Implementado essa alteração, já que na construção da melhoria de CONTA_CONTÁBIL não viabilizaram o CO
    -- CO deve seguir o mesmo processo de CT já que utilizam o mesmo CFOP, validado pelo analista Douglas.
    if P_ESPECIE = 'CO' THEN
      V_ESPECIE := 'CT';
    else
      V_ESPECIE := P_ESPECIE;
    end if;

    /*PESQUISA POR CFOP E CST*/
    BEGIN
      SELECT COD_CTA
        INTO vCONTA_CONTABIL_SPED
        FROM PCCONTASCONTABEISSPED
       WHERE CODFILIAL      = P_COD_FILIAL
         AND SUBSTR(NATUREZAFISCAL,1,2) = V_ESPECIE
         AND CODFISCAL      = P_CFOP
         AND CSTPISCOFINS   = P_CST
         AND TIPOCONTA      = 'N'
         AND GERARSPED      = 'S'
         AND ROWNUM = 1;

      P_MENSAGEM_RETORNO := 'S: REGISTRO LOCALIZADO PARA O P_CFOP: '||P_CFOP||' E P_CST: '||P_CST||' P_COD_FILIAL: '||P_COD_FILIAL||'.';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN BEGIN
        BEGIN
          SELECT COD_CTA
            INTO vCONTA_CONTABIL_SPED
            FROM PCCONTASCONTABEISSPED
           WHERE CODFILIAL      = '99'
             AND SUBSTR(NATUREZAFISCAL,1,2) = V_ESPECIE
             AND CODFISCAL      = P_CFOP
             AND CSTPISCOFINS   = P_CST
             AND TIPOCONTA      = 'N'
             AND GERARSPED      = 'S'
             AND ROWNUM = 1;

          P_MENSAGEM_RETORNO := 'S: REGISTRO LOCALIZADO PARA O P_CFOP: '||P_CFOP||' E P_CST: '||P_CST||' P_COD_FILIAL: "99".';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN BEGIN
            P_MENSAGEM_RETORNO := 'N: NENHUM REGISTRO FOI LOCALIZADO PARA O P_CFOP: '||P_CFOP||' E P_CST: '||P_CST||' P_COD_FILIAL: "99".';
          END;
        END;
      END;
    END;
    /*PESQUISA POR CFOP*/
    BEGIN
      IF vCONTA_CONTABIL_SPED IS NULL THEN
        SELECT COD_CTA
          INTO vCONTA_CONTABIL_SPED
          FROM PCCONTASCONTABEISSPED
         WHERE CODFILIAL      = P_COD_FILIAL
           AND SUBSTR(NATUREZAFISCAL,1,2) = V_ESPECIE
           AND CODFISCAL      = P_CFOP
           AND CSTPISCOFINS   IS NULL
           AND TIPOCONTA      = 'N'
           AND GERARSPED      = 'S'
           AND ROWNUM = 1;

        P_MENSAGEM_RETORNO := 'S: REGISTRO LOCALIZADO PARA O P_CFOP: '||P_CFOP||' P_COD_FILIAL: '||P_COD_FILIAL||'.';
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN BEGIN
        BEGIN
          IF vCONTA_CONTABIL_SPED IS NULL THEN
            SELECT COD_CTA
              INTO vCONTA_CONTABIL_SPED
              FROM PCCONTASCONTABEISSPED
             WHERE CODFILIAL      = '99'
               AND SUBSTR(NATUREZAFISCAL,1,2) = V_ESPECIE
               AND CODFISCAL      = P_CFOP
               AND CSTPISCOFINS   IS NULL
               AND TIPOCONTA      = 'N'
               AND GERARSPED      = 'S'
               AND ROWNUM = 1;

            P_MENSAGEM_RETORNO := 'S: REGISTRO LOCALIZADO PARA O P_CFOP: '||P_CFOP||' P_COD_FILIAL: "99".';
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            P_MENSAGEM_RETORNO := 'N: NENHUM REGISTRO FOI LOCALIZADO PARA O P_CFOP: '||P_CFOP||' P_COD_FILIAL: "99".';
        END;
      END;
    END;


    /*PESQUISA POR CST*/
    BEGIN
      IF vCONTA_CONTABIL_SPED IS NULL THEN
        SELECT COD_CTA
          INTO vCONTA_CONTABIL_SPED
          FROM PCCONTASCONTABEISSPED
         WHERE CODFILIAL      = P_COD_FILIAL
           AND SUBSTR(NATUREZAFISCAL,1,2) = V_ESPECIE
           AND CODFISCAL      IS NULL
           AND CSTPISCOFINS   = P_CST
           AND TIPOCONTA      = 'N'
           AND GERARSPED      = 'S'
           AND ROWNUM = 1;

        P_MENSAGEM_RETORNO := 'S: REGISTRO LOCALIZADO PARA O P_CST: '||P_CST||' P_COD_FILIAL: '||P_COD_FILIAL||' CFOP'||P_CFOP||'.';
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN BEGIN
        BEGIN
          IF vCONTA_CONTABIL_SPED IS NULL THEN
            SELECT COD_CTA
              INTO vCONTA_CONTABIL_SPED
              FROM PCCONTASCONTABEISSPED
             WHERE CODFILIAL      = '99'
               AND SUBSTR(NATUREZAFISCAL,1,2) = V_ESPECIE
               AND CODFISCAL      IS NULL
               AND CSTPISCOFINS   = P_CST
               AND TIPOCONTA      = 'N'
               AND GERARSPED      = 'S'
               AND ROWNUM = 1;

            P_MENSAGEM_RETORNO := 'S: REGISTRO LOCALIZADO PARA O P_CST: '||P_CST||' P_COD_FILIAL: "99".';
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            P_MENSAGEM_RETORNO := 'N: NENHUM REGISTRO FOI LOCALIZADO PARA O P_CST: '||P_CST||' CFOP '||P_CFOP|| ' P_COD_FILIAL: '
                                  || P_COD_FILIAL||             '.';
        END;
      END;

      RETURN P_MENSAGEM_RETORNO;
    END;

    RETURN(vCONTA_CONTABIL_SPED);
  END GET_CONTA_CONTABIL_SPED;
  /****************************************************************************/
  PROCEDURE GERA_CONTAS_CONTABEIS_SPED(PCODFILIAL IN VARCHAR2,
                                       PDATA1     IN DATE,
                                       PDATA2     IN DATE,
                                       PTRANSACAO IN NUMBER,
                                       PTIPOMOV   IN VARCHAR2) IS

       /*CONSULTA DE NOTAS COM ITEM*/
    CURSOR CR_DADOS_PCMOVCOMPLE IS
           SELECT NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIAL,
                  S.ESPECIE,
                  M.CODFISCAL CFOP,
                  M.CODSITTRIBPISCOFINS CST,
                  M.NUMTRANSITEM
             FROM PCNFSAID S,
                  PCMOV M
            WHERE S.NUMTRANSVENDA = M.NUMTRANSVENDA
              AND S.NUMNOTA = M.NUMNOTA
              AND S.ESPECIE not in ('OE','CT')
              AND COALESCE(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
              AND S.DTSAIDA BETWEEN PDATA1 AND PDATA2
              AND DECODE(PTRANSACAO,0,0,S.NUMTRANSVENDA) = PTRANSACAO
              AND DECODE(PTIPOMOV,'T', NULL, (SELECT C.CODCONTACONTSPED
                                               FROM PCMOVCOMPLE C
                                              WHERE C.NUMTRANSITEM = M.NUMTRANSITEM)) IS NULL
             AND ((PTIPOMOV = 'S')
                  OR (PTIPOMOV = 'T'))
        UNION ALL
           SELECT NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                  E.ESPECIE,
                  M.CODFISCAL CFOP,
                  M.CODSITTRIBPISCOFINS CST,
                  M.NUMTRANSITEM
             FROM PCNFENT E,
                  PCMOV M,
                  PCMOVCOMPLE C
            WHERE E.NUMTRANSENT = M.NUMTRANSENT
              AND E.NUMNOTA     = M.NUMNOTA
              AND M.NUMTRANSITEM  = C.NUMTRANSITEM
              AND COALESCE(E.CODFILIALNF, E.CODFILIAL) = PCODFILIAL
              AND E.ESPECIE not in ('OE','CT')
              AND E.DTENT BETWEEN PDATA1 AND PDATA2
              AND DECODE(PTRANSACAO,0,0,E.NUMTRANSENT) = PTRANSACAO
              AND DECODE(PTIPOMOV,'T', NULL, C.CODCONTACONTSPED) IS NULL
              AND ((PTIPOMOV = 'E') OR
                   (PTIPOMOV = 'T'));

    /*CONSULTA DOS DADOS NA PCMOVCIAP*/
    CURSOR CR_DADOS_PCMOVCIAP IS
           SELECT 'S' TIPO,--SAÍDA
                  NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIAL,
                  S.ESPECIE,
                  M.CODFISCAL CFOP,
                  M.CODSITTRIBPISCOFINS CST,
                  M.NUMTRANSVENDA TRANSACAO,
                  M.CODPROD
             FROM PCNFSAID S,
                  PCMOVCIAP M
            WHERE S.NUMTRANSVENDA = M.NUMTRANSVENDA
              AND COALESCE(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
              AND S.DTSAIDA BETWEEN PDATA1 AND PDATA2
              AND DECODE(PTRANSACAO,0,0,S.NUMTRANSVENDA) = PTRANSACAO
              AND DECODE(PTIPOMOV,'T', NULL, M.CODCONTACONTSPED) IS NULL
              AND ((PTIPOMOV = 'S')
                  OR (PTIPOMOV = 'T'))
           -------------------------------------------------------------
           UNION ALL
           -------------------------------------------------------------
           SELECT 'E' TIPO,--ENTRADA
                  NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                  E.ESPECIE,
                  M.CODFISCAL CFOP,
                  M.CODSITTRIBPISCOFINS CST,
                  E.NUMTRANSENT TRANSACAO,
                  M.CODPROD
             FROM PCNFENT E,
                  PCNFBASE B,
                  PCMOVCIAP M
            WHERE E.NUMTRANSENT   = M.NUMTRANSENT
              AND E.NUMNOTA       = M.NUMNOTA
              AND E.NUMTRANSENT   = B.NUMTRANSENT(+)
              AND NVL(E.CODFILIALNF, E.CODFILIAL) = PCODFILIAL
              AND E.DTENT BETWEEN PDATA1 AND PDATA2
              AND DECODE(PTRANSACAO,0,0,E.NUMTRANSENT) = PTRANSACAO
              AND DECODE(PTIPOMOV, 'T', NULL, NVL(B.CODCONTACONTSPED, M.CODCONTACONTSPED)) IS NULL
              AND ((PTIPOMOV = 'E')
                OR (PTIPOMOV = 'T'));
    /*CONSULTA DE NOTAS SEM ITENS*/
    CURSOR CR_DADOS_PCNFBASE IS
            SELECT 'S' TIPO,--SAÍDA
                   S.ESPECIE,
                   NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIAL,
                   S.NUMTRANSVENDA TRANSACAO,
                   B.CODFISCAL CFOP,
                   NVL(P.CODTRIBPISCOFINS, S.CODSITTRIBPISCOFINS) CST,
                   P.NUMTRANSPISCOFINS,
                   B.ROWID ID_BASE,
                   P.ROWID ID_PISCOFINS
              FROM PCNFSAID S,
                   PCNFBASE B,
                   PCNFENTPISCOFINS P
             WHERE S.NUMTRANSVENDA     = B.NUMTRANSVENDA
               AND B.NUMTRANSPISCOFINS = P.NUMTRANSPISCOFINS(+)
               AND S.DTSAIDA BETWEEN PDATA1 AND PDATA2
               AND COALESCE(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
               AND DECODE(PTRANSACAO,0,0,S.NUMTRANSVENDA) = PTRANSACAO
               AND DECODE(PTIPOMOV,'T', NULL, P.CODCONTACONTSPED) IS NULL
               AND S.ESPECIE <> 'OE'
               AND NVL(B.CODFISCAL,0) > 0
               AND ((PTIPOMOV = 'S')
                 OR (PTIPOMOV = 'T'))
               AND CASE S.ESPECIE
                        WHEN 'NF' THEN (SELECT COUNT(1)
                                          FROM PCMOV M,
                                               PCMOVCOMPLE MC
                                         WHERE M.NUMTRANSVENDA = S.NUMTRANSVENDA
                                           AND M.NUMNOTA = S.NUMNOTA
                                           AND COALESCE(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                                           AND M.NUMTRANSITEM = MC.NUMTRANSITEM)
                        ELSE 0
                   END = 0
            -----------------------------------
             UNION ALL
            -----------------------------------
            -- LANÇAMENTOS 1
            SELECT 'E' TIPO,
                   E.ESPECIE,
                   NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                   E.NUMTRANSENT TRANSACAO,
                   B.CODFISCAL CFOP,
                   NVL(P.CODTRIBPISCOFINS,E.CODTRIBPISCOFINS) CST,
                   P.NUMTRANSPISCOFINS,
                   B.ROWID ID_BASE,
                   P.ROWID ID_PISCOFINS
              FROM PCNFENT E,
                   PCNFBASE B,
                   PCNFENTPISCOFINS P
             WHERE E.NUMTRANSENT       = B.NUMTRANSENT
               AND B.NUMTRANSPISCOFINS = P.NUMTRANSPISCOFINS(+)
               AND E.CODCONT = B.CODCONT
               AND B.CODCONT = P.CODCONT(+)
               AND E.DTENT BETWEEN PDATA1 AND PDATA2
               AND COALESCE(E.CODFILIALNF, E.CODFILIAL) = PCODFILIAL
               AND DECODE(PTRANSACAO,0,0,E.NUMTRANSENT) = PTRANSACAO
               AND DECODE(PTIPOMOV,'T', NULL,P.CODCONTACONTSPED) IS NULL
               AND E.NUMTRANSENT NOT IN (SELECT M.NUMTRANSENT FROM PCMOVCIAP M WHERE M.NUMTRANSENT = E.NUMTRANSENT)
               AND E.ESPECIE <> 'OE'
               AND NVL(B.CODFISCAL,0) > 0
               AND ((PTIPOMOV = 'E')
                 OR (PTIPOMOV = 'T'))
               AND CASE E.ESPECIE
                        WHEN 'NF' THEN (SELECT COUNT(1)
                                          FROM PCMOV M,
                                               PCMOVCOMPLE MC
                                         WHERE M.NUMTRANSENT = E.NUMTRANSENT
                                           AND M.NUMNOTA = E.NUMNOTA
                                           AND COALESCE(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                                           AND M.NUMTRANSITEM = MC.NUMTRANSITEM)
                        ELSE 0
                   END = 0
            -----------------------------------
             UNION ALL
            -----------------------------------
            -- LANÇAMENTOS SEM VINCULO COM CODCONT E COM OBRIG DE TER A PCNFENTPISCOFINS
            SELECT 'E' TIPO,
                   E.ESPECIE,
                   NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                   E.NUMTRANSENT TRANSACAO,
                   B.CODFISCAL CFOP,
                   NVL(P.CODTRIBPISCOFINS,E.CODTRIBPISCOFINS) CST,
                   P.NUMTRANSPISCOFINS,
                   B.ROWID ID_BASE,
                   P.ROWID ID_PISCOFINS
              FROM PCNFENT E,
                   PCNFBASE B,
                   PCNFENTPISCOFINS P
             WHERE E.NUMTRANSENT       = B.NUMTRANSENT
               AND B.NUMTRANSPISCOFINS = P.NUMTRANSPISCOFINS
               AND E.CODCONT = B.CODCONT
               AND E.DTENT BETWEEN PDATA1 AND PDATA2
               AND COALESCE(E.CODFILIALNF, E.CODFILIAL) = PCODFILIAL
               AND DECODE(PTRANSACAO,0,0,E.NUMTRANSENT) = PTRANSACAO
               AND DECODE(PTIPOMOV,'T', NULL,P.CODCONTACONTSPED) IS NULL
               AND E.NUMTRANSENT NOT IN (SELECT M.NUMTRANSENT FROM PCMOVCIAP M WHERE M.NUMTRANSENT = E.NUMTRANSENT)
               AND E.ESPECIE <> 'OE'
               AND NVL(B.CODFISCAL,0) > 0
               AND ((PTIPOMOV = 'E')
                  OR (PTIPOMOV = 'T'))
               AND CASE E.ESPECIE
                        WHEN 'NF' THEN (SELECT COUNT(1)
                                          FROM PCMOV M,
                                               PCMOVCOMPLE MC
                                         WHERE M.NUMTRANSENT = E.NUMTRANSENT
                                           AND M.NUMNOTA = E.NUMNOTA
                                           AND COALESCE(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                                           AND M.NUMTRANSITEM = MC.NUMTRANSITEM)
                        ELSE 0
                   END = 0;


    VCONTA varchar2(255);
  BEGIN
    VCONTA := '';

    /*ATUALIZA NOTAS COM ITENS*/
    FOR DADOS IN CR_DADOS_PCMOVCOMPLE
    LOOP
      VCONTA  := GET_CONTA_CONTABIL_SPED(DADOS.CODFILIAL, DADOS.ESPECIE, DADOS.CFOP, DADOS.CST);

      UPDATE PCMOVCOMPLE M
         SET M.CODCONTACONTSPED = VCONTA
       WHERE M.NUMTRANSITEM = DADOS.NUMTRANSITEM;

    END LOOP;

    /*ATUALIZA NOTAS DA PCMOVCIAP*/
    FOR DADOS IN CR_DADOS_PCMOVCIAP
    LOOP

      VCONTA := GET_CONTA_CONTABIL_SPED(DADOS.CODFILIAL, DADOS.ESPECIE, DADOS.CFOP, DADOS.CST);

      IF DADOS.TIPO = 'S' THEN
        UPDATE PCMOVCIAP M
           SET M.CODCONTACONTSPED = VCONTA
         WHERE M.NUMTRANSVENDA = DADOS.TRANSACAO
           AND M.CODPROD       = DADOS.CODPROD;
      END IF;

      IF DADOS.TIPO = 'E' THEN
        -- Atualizando PCMOVCIAP
        UPDATE PCMOVCIAP M
           SET M.CODCONTACONTSPED = VCONTA
         WHERE M.NUMTRANSENT = DADOS.TRANSACAO
           AND M.CODPROD     = DADOS.CODPROD;

        -- Atualizando PCNFBASE
        UPDATE PCNFBASE B
           SET B.CODCONTACONTSPED = VCONTA
         WHERE B.NUMTRANSENT = DADOS.TRANSACAO
           AND B.NUMTRANSENT IN (SELECT M.NUMTRANSENT FROM PCMOVCIAP M WHERE M.NUMTRANSENT = B.NUMTRANSENT);
      END IF;
    END LOOP;

    /*ATUALIZA NOTAS SEM ITENS*/
    FOR DADOS IN CR_DADOS_PCNFBASE
    LOOP
      VCONTA := GET_CONTA_CONTABIL_SPED(DADOS.CODFILIAL, DADOS.ESPECIE, DADOS.CFOP, DADOS.CST);

      IF DADOS.TIPO = 'S' THEN
        UPDATE PCNFBASE B
           SET B.CODCONTACONTSPED = VCONTA
         WHERE B.NUMTRANSVENDA = DADOS.TRANSACAO
           AND B.ROWID = DADOS.ID_BASE;
      END IF;

      IF DADOS.TIPO = 'E' THEN
        UPDATE PCNFBASE B
           SET B.CODCONTACONTSPED = VCONTA
         WHERE B.NUMTRANSENT = DADOS.TRANSACAO
           AND B.ROWID = DADOS.ID_BASE;
      END IF;

      UPDATE PCNFENTPISCOFINS E
         SET E.CODCONTACONTSPED = VCONTA
       WHERE E.NUMTRANSPISCOFINS = DADOS.NUMTRANSPISCOFINS
         AND E.ROWID = DADOS.ID_PISCOFINS;
    END LOOP;
  END;

  /****************************************************************************/
  PROCEDURE GERA_CONTAS_CONTAB_SPED_ITEM(PCODFILIAL IN VARCHAR2,
                                         PESPECIE   IN VARCHAR2,
                                         PCFOP      IN NUMBER,
                                         PCST       IN VARCHAR2,
                                         PNUMTRANSITEM IN NUMBER) IS

    VCONTA varchar2(255);
  BEGIN
    VCONTA  := GET_CONTA_CONTABIL_SPED(PCODFILIAL, PESPECIE, PCFOP, PCST);

    UPDATE PCMOVCOMPLE M
       SET M.CODCONTACONTSPED = VCONTA
     WHERE M.NUMTRANSITEM = PNUMTRANSITEM;
  END;
  -------------------------------------------------------------------------------
  PROCEDURE GERA_NATUREZA_RECEITA(PCODFILIAL IN VARCHAR2,
                                  PDATA1     IN DATE,
                                  PDATA2     IN DATE,
                                  PTRANSACAO IN NUMBER,
                                  PREPROCESSAR_TODOS   IN VARCHAR2) IS

    /*CONSULTA DE NOTAS COM ITEM*/
    CURSOR CR_DADOS_PCMOVCOMPLE IS
           SELECT S.DTSAIDA DATA,
                  LPAD(M.CODSITTRIBPISCOFINS,2,0) CST_PIS_COFINS,
                  M.CODPROD,
                  M.NBM NCM,
                  C.EXTIPI,
                  M.NUMTRANSITEM
             FROM PCNFSAID S,
                  PCMOV M,
                  PCMOVCOMPLE C
            WHERE S.NUMTRANSVENDA = M.NUMTRANSVENDA
              AND S.NUMNOTA = M.NUMNOTA
              AND M.NUMTRANSITEM  = C.NUMTRANSITEM
              AND SUBSTR(S.CHAVENFE, 21, 2) in ('55','65')
              AND COALESCE(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
              AND DECODE(PTRANSACAO,0,0,S.NUMTRANSVENDA) = PTRANSACAO
              AND S.DTSAIDA BETWEEN PDATA1 AND PDATA2
         --     OPCAO TRAVA CLIENTE VAREJO
         --     AND M.DTMOV >= (SELECT MIN(DTMOV) FROM PCMOV)
         --     AND M.DTMOV >= (SELECT MIN(DTMOV) FROM PCMOV)
              AND S.ESPECIE not in ('OE','CT')
              AND DECODE(PREPROCESSAR_TODOS,'S', NULL, C.NATUREZARECEITA) IS NULL;

    VNATUREZARECEITA varchar2(30);
  BEGIN
    VNATUREZARECEITA := '';

    /*ATUALIZA NOTAS*/
    FOR DADOS IN CR_DADOS_PCMOVCOMPLE
    LOOP
      VNATUREZARECEITA  := F_NATUREZARECEITA(DADOS.DATA, DADOS.CST_PIS_COFINS, DADOS.CODPROD, DADOS.NCM, '', DADOS.EXTIPI);


      UPDATE PCMOVCOMPLE M
         SET M.NATUREZARECEITA = VNATUREZARECEITA
       WHERE M.NUMTRANSITEM = DADOS.NUMTRANSITEM;
    END LOOP;
  END;
  --------------------------------------------------------------------------------------------
  PROCEDURE GERA_NATUREZA_RECEITA_ITEM(PCODFILIAL IN VARCHAR2,
                                       PDATA      IN DATE,
                                       PCODPROD   IN NUMBER,
                                       PCST       IN VARCHAR2,
                                       PNCM       IN VARCHAR2,
                                       PEXTIPI    IN NUMBER,
                                       PNUMTRANSITEM IN NUMBER) IS
    VNATUREZARECEITA varchar2(30);
  BEGIN
    VNATUREZARECEITA  := F_NATUREZARECEITA(PDATA, PCST, PCODPROD, PNCM, '', PEXTIPI);

    UPDATE PCMOVCOMPLE M
       SET M.NATUREZARECEITA = VNATUREZARECEITA
     WHERE M.NUMTRANSITEM = PNUMTRANSITEM;

  END;
  ----------------------------------------------------------------------------
  function GET_CSTPISCONFINS_DEV(P_TRIB IN VARCHAR2,
                                 P_DATA IN DATE,
                                 P_CONSUMIDOR IN VARCHAR2) return number is
    VCSTDEV2 number;
  begin
    VCSTDEV2 := 0;
    begin
        select CST_DEV
          into VCSTDEV2
          from (select case
                          when (NVL(P_CONSUMIDOR,'N') = 'S')
                               and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                           T.SITTRIBUTCONSUMODEV
                          else
                           T.SITTRIBUTDEV
                       end CST_DEV
                  from PCTRIBPISCOFINSVIGENCIA T
                 where T.CODTRIBPISCOFINS = P_TRIB
                   and P_DATA between T.DTINICIO and T.DTFINAL
                 order by T.DTFINAL desc)
         where ROWNUM = 1;
     exception
        when NO_DATA_FOUND then
           select case
                     when (NVL(P_CONSUMIDOR,'N') = 'S')
                          and (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') then
                      T.SITTRIBUTCONSUMODEV
                     else
                      T.SITTRIBUTDEV
                  end CST_DEV
             into VCSTDEV2
             from PCTRIBPISCOFINS T
            where T.CODTRIBPISCOFINS = P_TRIB;
        when others then
           raise;
     end;
     return VCSTDEV2;
  end;
   --Adicionado procedure de partilha 1.5
   PROCEDURE CALCULAR_PARTILHA_ICMS_1_5(P_CODFILIAL    in varchar2
                                        ,P_CODCLI       in number
                                        ,P_UFOPERCONSUM in varchar2
                                        ,P_UFENTREGA    in varchar2
                                        ,P_DATAOPER     in date
                                        ,P_VLPRODUTO    in number
                                        ,P_CODTRIBUT    in number
                                        ,P_CODPROD      in number
                                        ,P_CFOP         in number
                                        ,P_CST          in varchar2
                                        ,P_RETORNO      out varchar2
                                        ,P_CODMSG       out number
                                        ,P_MSG          out varchar2) is
   begin
      begin
           PKG_FWPC_FISCAL.ICMSPARTILHA_CALCULAR_1_5(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_CST,P_RETORNO,P_CODMSG,P_MSG);
      exception
        when others then
          P_RETORNO := '';
          P_CODMSG  := 999;
          P_MSG     := 'Erro o calcular ICMS Partilha.' || CHR(13) ||
                       'Erro original: ' || sqlerrm;
      end;
   end;

   --Adicionado procedure de partilha 1.6
   PROCEDURE CALCULAR_PARTILHA_ICMS_1_6(P_CODFILIAL    in varchar2
                                        ,P_CODCLI       in number
                                        ,P_UFOPERCONSUM in varchar2
                                        ,P_UFENTREGA    in varchar2
                                        ,P_DATAOPER     in date
                                        ,P_VLPRODUTO    in number
                                        ,P_CODTRIBUT    in number
                                        ,P_CODPROD      in number
                                        ,P_CFOP         in number
                                        ,P_BASEICMS     in number
                                        ,P_CST          in varchar2
                                        ,P_RETORNO      OUT VARCHAR2
                                        ,P_CODMSG       OUT NUMBER
                                        ,P_MSG          OUT VARCHAR2) is
   begin
     begin
        PKG_FWPC_FISCAL.ICMSPARTILHA_CALCULAR_1_6(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_BASEICMS,P_CST,P_RETORNO,P_CODMSG,P_MSG);
     exception
        when others then
          P_RETORNO := '';
          P_CODMSG  := 999;
          P_MSG     := 'Erro o calcular ICMS Partilha.' || CHR(13) ||
                       'Erro original: ' || sqlerrm;
     end;
   end;

   --Adicionado procedure de partilha 1.7
   PROCEDURE CALCULAR_PARTILHA_ICMS_1_7(P_CODFILIAL    in varchar2
                                        ,P_CODCLI       in number
                                        ,P_UFOPERCONSUM in varchar2
                                        ,P_UFENTREGA    in varchar2
                                        ,P_DATAOPER     in date
                                        ,P_VLPRODUTO    in number
                                        ,P_CODTRIBUT    in number
                                        ,P_CODPROD      in number
                                        ,P_CFOP         in number
                                        ,P_BASEICMS     in number
                                        ,P_CST          in varchar2
                                        ,P_ROTINA       in varchar2  := 'X'
                                        ,P_RETORNO      OUT VARCHAR2
                                        ,P_CODMSG       OUT NUMBER
                                        ,P_MSG          OUT VARCHAR2) is
   begin
     begin
        PKG_FWPC_FISCAL.ICMSPARTILHA_CALCULAR_1_7(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_BASEICMS,P_CST,P_ROTINA,P_RETORNO,P_CODMSG,P_MSG);
     exception
        when others then
          P_RETORNO := '';
          P_CODMSG  := 999;
          P_MSG     := 'Erro o calcular ICMS Partilha.' || CHR(13) ||
                       'Erro original: ' || sqlerrm;
     end;
   end;

   PROCEDURE CALCULAR_PARTILHA_ICMS_1_8(P_NUMTRANSACAO in number
                                       ,P_TIPOMOV      varchar2
                                       ,P_ATIVARLOG    varchar2 := 'N'
                                       ,P_MSG      out varchar2) is
   begin
     begin
        PKG_FWPC_FISCAL.ICMSPARTILHA_CALCULAR_1_8(P_NUMTRANSACAO, P_TIPOMOV, P_ATIVARLOG, P_MSG);
     exception
        when others then
          P_MSG     := 'Erro o calcular ICMS Partilha.' || CHR(13) ||
                       'Erro original: ' || sqlerrm;
     end;
   end;

  FUNCTION F_CALCULAR_PARTILHA_ICMS_1_9(P_NUMTRANSACAO in number
                                       ,P_TIPOMOV      varchar2
                                       ,P_ATIVARLOG    varchar2 := 'N'
                                       ,P_CODMSG   out varchar2
                                       ,P_MSG      out varchar2)
  RETURN VARCHAR2 is
  V_RETURN VARCHAR2(1);
  begin


     begin
       V_RETURN := PKG_FWPC_FISCAL.F_CALCULAR_PARTILHA_ICMS_1_9(P_NUMTRANSACAO, P_TIPOMOV, P_ATIVARLOG, P_CODMSG, P_MSG);
     exception
        when others then
          P_MSG     := 'Erro o calcular ICMS Partilha.' || CHR(13) ||
                       'Erro original: ' || sqlerrm;
     end;


     RETURN(V_RETURN);
  end;

 PROCEDURE OBTERCODIGOCEST_1_3 (P_CODPROD      in number
                               ,P_CSTICMS      in varchar2
                               ,P_TIPOMOV      in varchar2
                               ,P_TIPOOPERACAO in varchar2
                               ,P_CODOPER      in varchar2
                               ,P_CFOP         in number
                               ,P_CODPART      in number
                               ,P_VLST         in number
                               ,P_CODFILIAL    in varchar2
                               ,P_CODCEST      out varchar2
                               ,P_CODMSG       out number
                               ,P_MSG          out varchar2) IS

 begin
    begin
        PKG_FWPC_FISCAL.CEST_OBTERCODIGO_1_3(P_CODPROD,P_CSTICMS,P_TIPOMOV,P_TIPOOPERACAO,P_CODOPER,P_CFOP,P_CODPART,P_VLST,P_CODFILIAL,P_CODCEST,P_CODMSG,P_MSG);
    exception
      when others then
        P_CODCEST := '';
        P_CODMSG  := 999;
        P_MSG     := 'Erro o obter código cest.' || CHR(13) ||
                     'Erro original: ' || sqlerrm;
    end;
 end;

 FUNCTION PODE_DEDUZIR_ICMS_BCPISCOFINS(P_CODFILIAL IN VARCHAR2,
                                        P_DATA IN DATE) RETURN VARCHAR2 IS
    VEXCLUIRICMSBASEPISCOFINS       VARCHAR2(1);
  BEGIN
    BEGIN
      VEXCLUIRICMSBASEPISCOFINS      := PARAMFILIAL.OBTERCOMOVARCHAR2('EXCLUIRICMSBASEPISCOFINS', P_CODFILIAL);

      IF (VEXCLUIRICMSBASEPISCOFINS = 'S')
      THEN
         RETURN 'S';
      ELSE
         RETURN 'N';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
        RETURN 'N';
   END;
 END;

 ----------
  FUNCTION GET_HORACERTA_TIMEZONE(P_UF VARCHAR2) RETURN DATE IS
    /*
    * Método que faz o cálculo da data e hora correta de acordo com o fusorário da uf
    * Author: Eddy Pereira
    *OBS: só funciona se a tabela PCESTADOTIMEZONE estiver populada. Quem popula é a rotina 820 do WTA.
    */
    V_DATA_CORRETA DATE;
    V_TIMEZONE     VARCHAR2(100);

  BEGIN
    BEGIN
      --INICIALIZA A VARIÁVEL DE RETORNO
      V_DATA_CORRETA := SYSDATE;

      --CASO A UF ESTEJA NULA, DEVOLVE A DATA DO BANCO
      IF (P_UF IS NULL) THEN
        RETURN V_DATA_CORRETA;
      END IF;

      BEGIN
        --PEGA O INTERVALO DA ZONA DA UF
        SELECT REGEXP_SUBSTR(TIMEZONE, '(-?\d{2})') TIMEZONE
          INTO V_TIMEZONE
          FROM PCESTADOTIMEZONE
         WHERE UPPER(SIGLAESTADO) = UPPER(P_UF);
      EXCEPTION
        WHEN OTHERS THEN
          --CASO NÃO TENHA REGISTRO NA TABELA, RETORNA A DATA DO BANCO
          RETURN V_DATA_CORRETA;
      END;

      --FAZ O CÁLCULO DE ACORDO COM O TIMEZONE DA UF
      SELECT CAST(((CURRENT_TIMESTAMP AT TIME ZONE 'UTC') + NUMTODSINTERVAL(V_TIMEZONE, 'HOUR')) AS DATE) AS HORA_AJUSTADA
        INTO V_DATA_CORRETA
        FROM DUAL;

      IF (V_DATA_CORRETA IS NOT NULL) THEN
        RETURN V_DATA_CORRETA;
      ELSE
        RETURN SYSDATE;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        RETURN V_DATA_CORRETA;
    END;

  END;
 ----------
  FUNCTION OBTER_ALIQUOTAS_PISCOFINS(P_CODPROD   IN NUMBER,
                                     P_CODFISCAL IN NUMBER,
                                     P_CODOPER   IN VARCHAR2,
                                     P_CONDVENDA IN NUMBER,
                                     P_CODTRIB   IN NUMBER,
                                     P_CODIGO_FILIAL  IN VARCHAR2,
                                     P_DATAO_PERACAO  IN DATE,
                                     P_CODIGO_CLIENTE IN VARCHAR2,
                                     P_NCM            IN VARCHAR2,
                                     P_PERPIS           OUT NUMBER,
                                     P_PERCOFINS        OUT NUMBER,
                                     P_MENSAGEM_RETORNO OUT VARCHAR2)
    RETURN BOOLEAN IS

    V_CODTRIB             NUMBER;
    V_PERPIS              NUMBER;
    V_PERCOFINS           NUMBER;
    V_CODEXCTRIBPISCOFINS NUMBER;
    V_CONSUMIDOR       VARCHAR2(1);
    V_CLIENTESUFRAMA   VARCHAR2(1);
    V_PRODUTOIMPORTADO VARCHAR2(1);
    V_TIPOCLIENT       VARCHAR2(1);
    V_PISCOFINSCUM     VARCHAR2(1);

  BEGIN
    P_MENSAGEM_RETORNO := '';
    V_PERPIS    := 0;
    V_PERCOFINS := 0;
    P_PERPIS    := 0;
    P_PERCOFINS := 0;

    --BUSCAR DADOS DO CLIENTE
    BEGIN
      SELECT PCCLIENT.CONSUMIDORFINAL,
             CASE
               WHEN (TRIM(PCCLIENT.SULFRAMA) IS NOT NULL AND
                    PCCLIENT.DTVENCSUFRAMA >= P_DATAO_PERACAO) THEN
                'S'
               ELSE
                'N'
             END CLI_SUFRAMA,
             PCCLIENT.TIPOFJ,
             NVL(PCCLIENT.PISCOFINSCUMULATIVO, 'N') PISCOFINSCUMULATIVO
        INTO V_CONSUMIDOR, V_CLIENTESUFRAMA, V_TIPOCLIENT, V_PISCOFINSCUM
        FROM PCCLIENT
       WHERE CODCLI = P_CODIGO_CLIENTE;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        P_MENSAGEM_RETORNO := 'Não foi encontrado cliente com o códig informado (' ||
                             P_CODIGO_CLIENTE || ').';
        RETURN FALSE;
    END;

    --BUSCAR DADOS DO PRODUTO
    BEGIN
      SELECT CASE
               WHEN PCPRODUT.IMPORTADO IN ('S', 'D') THEN
                'S'
               ELSE
                'N'
             END PROD_IMPORTADO
        INTO V_PRODUTOIMPORTADO
        FROM PCPRODUT
       WHERE CODPROD = P_CODPROD;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        P_MENSAGEM_RETORNO := 'Não foi encontrado produto com o código informado (' ||
                             P_CODPROD || ').';
        RETURN FALSE;
    END;

    -- VERIFICAR SE É DOCUMENTO TV8
    IF P_CODOPER = 'ED' AND P_CONDVENDA = 8 THEN
      BEGIN
        SELECT NVL(CODEXCTRIBPISCOFINS, 0)
          INTO V_CODEXCTRIBPISCOFINS
          FROM PCTRIBPISCOFINSVIGENCIA
         WHERE CODTRIBPISCOFINS = P_CODTRIB
           AND P_DATAO_PERACAO BETWEEN DTINICIO AND DTFINAL;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_CODEXCTRIBPISCOFINS := 0;
      END;

      IF V_CODEXCTRIBPISCOFINS = 0 THEN
        BEGIN
          SELECT NVL(CODEXCTRIBPISCOFINS, 0)
            INTO V_CODEXCTRIBPISCOFINS
            FROM PCTRIBPISCOFINS
           WHERE CODTRIBPISCOFINS = P_CODTRIB;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_CODEXCTRIBPISCOFINS := 0;
        END;
      END IF;
    END IF;

    -- VERIFICAR SE HÁ EXCEÇÃO TRIBUTAÇÃO --
    V_CODTRIB := GET_CODTRIBEXCECAO_PISCOFINS(P_CODTRIB,
                                              P_CODFISCAL,
                                              P_CODOPER,
                                              P_CONDVENDA,
                                              V_CLIENTESUFRAMA,
                                              V_PRODUTOIMPORTADO,
                                              V_TIPOCLIENT,
                                              V_PISCOFINSCUM,
                                              P_CODIGO_FILIAL,
                                              P_DATAO_PERACAO,
                                              P_CODIGO_CLIENTE,
                                              V_CODEXCTRIBPISCOFINS,
                                              P_NCM);
    BEGIN
      BEGIN
        --CASO USE VIGÊNCIA
        SELECT PERPIS, PERCOFINS
          INTO V_PERPIS, V_PERCOFINS
          FROM (SELECT CASE
                         WHEN (V_CONSUMIDOR = 'S') AND
                              (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') THEN
                          T.PERCPISCONSUMO
                         ELSE
                          T.PERCPIS
                       END PERPIS,
                       CASE
                         WHEN (V_CONSUMIDOR = 'S') AND
                              (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') THEN
                          T.PERCCOFINSCONSUMO
                         ELSE
                          T.PERCCOFINS
                       END PERCOFINS
                  FROM PCTRIBPISCOFINSVIGENCIA T
                 WHERE T.CODTRIBPISCOFINS = V_CODTRIB
                   AND P_DATAO_PERACAO BETWEEN T.DTINICIO AND T.DTFINAL
                 ORDER BY T.DTFINAL DESC)
         WHERE ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --CASO NÃO USE VIGÊNCIA
          SELECT CASE
                   WHEN (V_CONSUMIDOR = 'S') AND (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') THEN
                    T.PERCPISCONSUMO
                   ELSE
                    T.PERCPIS
                 END PERPIS,
                 CASE
                   WHEN (V_CONSUMIDOR = 'S') AND (T.UTILIZAPERCPISCOFINSDIFCONS = 'S') THEN
                    T.PERCCOFINSCONSUMO
                   ELSE
                    T.PERCCOFINS
                 END PERCOFINS
            INTO V_PERPIS, V_PERCOFINS
            FROM PCTRIBPISCOFINS T
           WHERE T.CODTRIBPISCOFINS = V_CODTRIB;
        WHEN OTHERS THEN
          RAISE;
      END;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        P_MENSAGEM_RETORNO := 'Tributacao PIS/COFINS inexistente para o produto ' ||
                             P_CODPROD ||
                             ', verificar cadastro na rotina 271 ou 574 conforme marcacao do parametro 1092 da rotina 132.';
        RETURN FALSE;
      WHEN OTHERS THEN
        P_MENSAGEM_RETORNO := 'Erro ao calcular PIS/COFINS no item. ' ||
                             CHR(13) || 'Erro original: ' || SQLERRM;
        RETURN FALSE;
    END;
    -- RETORNANDO PERCENTUAIS --
    P_MENSAGEM_RETORNO := 'OK';
    P_PERPIS    := V_PERPIS;
    P_PERCOFINS := V_PERCOFINS;

    RETURN TRUE;

  END;

  FUNCTION GET_VIGENCIANTSEFAZ(P_IDENTIFICADORNT IN VARCHAR2,
                               P_DATADOCUMENTO IN DATE) RETURN VARCHAR2 IS
    vDATAINICIALVIGENCIA DATE;
    vDATAFINALVIGENCIA   DATE;
    vRESULTADO           VARCHAR2(1);
  BEGIN
    BEGIN
      SELECT DATAINICIALVIGENCIA,
             NVL(DATAFINALVIGENCIA,TO_DATE('01/01/2999','DD/MM/YYYY'))
        INTO vDATAINICIALVIGENCIA,
             vDATAFINALVIGENCIA
        FROM PCVIGENCIANTSEFAZ
       WHERE UPPER(IDENTIFICADOR_NT) = UPPER(P_IDENTIFICADORNT);

       IF vDATAINICIALVIGENCIA <= P_DATADOCUMENTO AND
          vDATAFINALVIGENCIA >= P_DATADOCUMENTO THEN
          vRESULTADO := 'S';
       ELSE
         vRESULTADO := 'N';
       END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vRESULTADO := 'N';
    END;

    RETURN  vRESULTADO;
  END;

  FUNCTION GET_NATUREZAOPERACAO(P_CODFISCAL IN VARCHAR2,
                                P_CODOPER IN VARCHAR2,
                                P_CODROTINAEMISSAO IN VARCHAR2 := 0) RETURN VARCHAR2 IS
    vNATUREZAOPERACAO    VARCHAR2(60);
  BEGIN
    BEGIN
      SELECT DESCRICAO
        INTO vNATUREZAOPERACAO
        FROM PCNATUREZAOPERACAO
       WHERE CODFISCAL       = P_CODFISCAL
         AND CODOPER         = P_CODOPER
         AND CODROTINAORIGEM = P_CODROTINAEMISSAO;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
       BEGIN
         SELECT DESCRICAO
           INTO vNATUREZAOPERACAO
           FROM PCNATUREZAOPERACAO
          WHERE CODFISCAL       = P_CODFISCAL
            AND CODOPER         = P_CODOPER
            AND CODROTINAORIGEM = 0;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
         BEGIN
           SELECT DESCCFO
             INTO vNATUREZAOPERACAO
             FROM PCCFO
            WHERE CODFISCAL = P_CODFISCAL;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             vNATUREZAOPERACAO := '';
         END;
       END;
     END;
    RETURN  vNATUREZAOPERACAO;
  END;

  FUNCTION NFE_DENEGADA(P_SITUACAONFE IN VARCHAR2,
                        P_DATADOCUMENTOS IN DATE := SYSDATE) RETURN VARCHAR2 IS
  vRetorno VARCHAR2(1);
  vDataDocumentos DATE;
  BEGIN
    BEGIN

      IF P_DATADOCUMENTOS IS NULL THEN
        vDataDocumentos := TRUNC(SYSDATE); /*Em alguns casos o valor default não está sendo passado para o parâmetro*/
      ELSE
        vDataDocumentos := P_DATADOCUMENTOS;
      END IF;

      IF (P_SITUACAONFE IS NOT NULL) THEN
        vRetorno := 'N';

        IF GET_VIGENCIANTSEFAZ('NFE-NT2024.001-CRT-MEIv1.10', vDataDocumentos) = 'N' THEN
          IF (P_SITUACAONFE IN ('110','205','301','302','303','307')) THEN
            vRetorno := 'S';
          END IF;
        ELSE
          IF (P_SITUACAONFE IN ('110','205')) THEN
            vRetorno := 'S';
          END IF;
        END IF;
      ELSE
        vRetorno := 'N';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        vRetorno := 'N';
    END;

    RETURN vRetorno;
  END;

  FUNCTION CTE_DENEGADO(P_SITUACAOCTE IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    BEGIN
      IF (P_SITUACAOCTE IS NOT NULL) THEN
        IF (P_SITUACAOCTE IN ('110','205','301')) THEN
          RETURN 'S';
        ELSE
          RETURN 'N';
        END IF;
      ELSE
        RETURN 'N';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN 'N';
    END;
  END;

 FUNCTION GET_DESCRICAO_NATUREZA_OP(
    P_CODFISCAL       NUMBER,
    P_CODOPER         VARCHAR2,
    P_CODROTINAORIGEM NUMBER DEFAULT 0,
    P_CHEQUEMORADIA   VARCHAR2 DEFAULT 'N') RETURN VARCHAR2 IS
  V_DESCRICAO VARCHAR2(60);
  BEGIN
      V_DESCRICAO:='';
      -- VALIDAÇÃO DOS PARÂMETROS
      IF P_CODFISCAL < 1000 OR P_CODFISCAL > 7999 THEN
          RAISE_APPLICATION_ERROR(-20001, 'CFOP deve estar entre 1000 e 7999.');
      ELSIF P_CODOPER IS NULL OR TRIM(P_CODOPER) = '' THEN
          RAISE_APPLICATION_ERROR(-20002, 'Código da Operação não pode ser vazio.');
      END IF;

      -- BUSCA A DESCRIÇÃO ROTINA 4014 BASEADA NOS PARÂMETROS RECEBIDOS
      BEGIN
          IF P_CHEQUEMORADIA = 'S' THEN
            V_DESCRICAO := 'VENDA COM CHEQUE MORADIA';
          ELSE
              SELECT DESCRICAO
              INTO V_DESCRICAO
              FROM PCNATUREZAOPERACAO
              WHERE CODFISCAL = P_CODFISCAL
                AND CODOPER = P_CODOPER
                AND ((NVL(CODROTINAORIGEM,0) = 0) OR (NVL(P_CODROTINAORIGEM, 0) = 0) OR (NVL(CODROTINAORIGEM, 0) = P_CODROTINAORIGEM));
          END IF;
          -- GRAVANDO LOG
          PKG_DEBUGGING_FWPC.ATIVARDEBUG('Chamou GET_DESCRICAO_NATUREZA_OP retorno:','1.0');
          PKG_DEBUGGING_FWPC.LOG('DESCRICAO ROTINA 4014: '||V_DESCRICAO||' ', 'S');
          PKG_DEBUGGING_FWPC.LOG('CODFISCAL: '||P_CODFISCAL||' CODOPER: '||P_CODOPER||' CODROTINAORIGEM: '||P_CODROTINAORIGEM, 'S');
          -- DESABILITANDO SERVIÇO LOG
          PKG_DEBUGGING_FWPC.DESATIVARDEBUG;

          RETURN V_DESCRICAO;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              -- SE NÃO ENCONTRAR NA 4014 VERIFICA SE O CFOP EXISTE NA ROTINA 543
              BEGIN
                  SELECT DESCCFO
                  INTO V_DESCRICAO
                  FROM PCCFO
                  WHERE CODFISCAL = P_CODFISCAL;
              EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      RETURN 'CFOP não encontrado rotinas: 4014/543.';
              END;
              -- GRAVANDO LOG
              PKG_DEBUGGING_FWPC.ATIVARDEBUG('Chamou GET_DESCRICAO_NATUREZA_OP retorno:','1.0');
              PKG_DEBUGGING_FWPC.LOG('DESCRICAO ROTINA 543: '||V_DESCRICAO||' ', 'S');
              PKG_DEBUGGING_FWPC.LOG('CODFISCAL: '||P_CODFISCAL||' CODOPER: '||P_CODOPER||' CODROTINAORIGEM: '||P_CODROTINAORIGEM, 'S');
              -- DESABILITANDO SERVIÇO LOG
              PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
              RETURN V_DESCRICAO;
      END;

  EXCEPTION
      WHEN OTHERS THEN
           PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
           IF SQLCODE IN (-20001, -20002) THEN
              RETURN SQLERRM;
          ELSE
              RETURN 'Erro ao buscar descrição Natureza da Operação.';
          END IF;
  END GET_DESCRICAO_NATUREZA_OP;

  FUNCTION GET_FORMULA_CREDPRESUMIDO (
                                      P_CODBENEFICIOFISCAL IN VARCHAR2,
                                      P_CODST IN NUMBER,
                                      P_ALIQICMSNF IN NUMBER,
                                      P_CONTRIBUINTECONSFINAL IN VARCHAR2,
                                      P_TIPO_EMPRESA IN VARCHAR2 DEFAULT NULL,
                                      P_TIPO_PESSOA IN VARCHAR2 DEFAULT NULL,
                                      P_ORIGEM_MERC IN VARCHAR2 DEFAULT NULL,
                                      P_SIT_TRIBUT IN VARCHAR2 DEFAULT NULL,
                                      P_CODFISCAL IN NUMBER DEFAULT NULL,
                                      P_NCM IN VARCHAR2 DEFAULT NULL,
                                      P_ALIQCREDPRESUMIDO OUT NUMBER,
                                      P_FORMULACREDPRES OUT VARCHAR2,
                                      P_CCREDPRESUMIDO OUT VARCHAR2,
                                      P_IDCREDPRESUMIDO OUT NUMBER
  )
  RETURN VARCHAR2
  IS
    v_FORMULACREDPRES VARCHAR2(200);
    v_ALIQCREDPRESUMIDO NUMBER;
    V_CCREDPRESUMIDO VARCHAR2(10);
    V_IDCREDPRESUMIDO VARCHAR2(10);
  BEGIN
    -- Query para buscar o FORMULACREDPRES
    BEGIN
      SELECT P.FORMULACREDPRES, I.ALIQCREDPRESUMIDO, P.CCREDPRESUMIDO, P.IDPRES
        INTO v_FORMULACREDPRES, v_ALIQCREDPRESUMIDO, V_CCREDPRESUMIDO, V_IDCREDPRESUMIDO
        FROM PCBENEFICFISCALCREDPRES P, PCBENEFICFISCALCREDPRESI I
        WHERE P.IDPRES = I.IDPRES
          AND P.CODST = P_CODST
          AND I.ALIQICMSNF = P_ALIQICMSNF
          -- Filtros adicionais somente se os parâmetros não forem nulos
          AND (P_CONTRIBUINTECONSFINAL IS NULL OR NVL(CONTRIBUINTECONSFINAL, 'N') = P_CONTRIBUINTECONSFINAL)
          AND ((NVL(TIPOEMPRESA, 'N') = P_TIPO_EMPRESA) OR (TIPOEMPRESA IS NULL ))
          AND ((NVL(TIPOPESSOA, 'N') = P_TIPO_PESSOA) OR (TIPOPESSOA IS NULL ))
          AND (ORIGMERCTRIB IS NULL OR REGEXP_LIKE(ORIGMERCTRIB, '(^|,)' || P_ORIGEM_MERC || '($|,)'))
          AND (SITTRIBUT IS NULL OR REGEXP_LIKE(SITTRIBUT, '(^|,)' || P_SIT_TRIBUT || '($|,)'))
          -- Verificar CFOP com base no DESCONSIDERARCFOP
          AND (NVL(P.DESCONSIDERARCFOP,'N') = 'S' AND NOT REGEXP_LIKE(CODFISCAL, '(^|,)' || P_CODFISCAL || '($|,)')
              OR NVL(P.DESCONSIDERARCFOP,'N') = 'N' AND (CODFISCAL IS NULL OR REGEXP_LIKE(CODFISCAL, '(^|,)' || P_CODFISCAL || '($|,)')))
          -- Verificar NCM com base no DESCONSIDERARNCM
          AND (NVL(P.DESCONSIDERARNCM,'N') = 'S' AND NOT REGEXP_LIKE(NCM, '(^|,)' || P_NCM || '($|,)')
              OR NVL(P.DESCONSIDERARNCM,'N') = 'N' AND (NCM IS NULL OR REGEXP_LIKE(NCM, '(^|,)' || P_NCM || '($|,)')))
          AND ROWNUM  = 1
          ORDER BY P.DTCADASTRO;

        -- Atribui os valores para os parâmetros de saída
        P_FORMULACREDPRES := v_FORMULACREDPRES;
        P_ALIQCREDPRESUMIDO := v_ALIQCREDPRESUMIDO;
        P_CCREDPRESUMIDO := V_CCREDPRESUMIDO;
        P_IDCREDPRESUMIDO := V_IDCREDPRESUMIDO;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_FORMULACREDPRES := NULL;
            P_ALIQCREDPRESUMIDO := NULL;
            P_CCREDPRESUMIDO := NULL;
            RETURN 'Nenhum dado encontrado';

        WHEN OTHERS THEN
            -- Em caso de erro inesperado, retorna o erro detalhado
            P_FORMULACREDPRES := NULL;
            P_ALIQCREDPRESUMIDO := NULL;
            P_CCREDPRESUMIDO := NULL;
            RETURN 'Erro inesperado: ' || SQLCODE || ' - ' || SQLERRM;
    END;

    RETURN 'OK';

  END GET_FORMULA_CREDPRESUMIDO;

  FUNCTION GET_DADOS_CREDITOPRESUMIDO (
                                        P_CODBENEFICIOFISCAL IN VARCHAR2, -- Código Beneficio Fiscal
                                        P_CODST IN NUMBER, -- Figura tributária rotina 514
                                        P_ALIQICMSNF IN NUMBER, -- Alíquota ICMS NF
                                        P_CONTRIBUINTECONSFINAL IN VARCHAR2 DEFAULT NULL, -- Contribuinte consumidor final (Opcional)
                                        P_TIPO_EMPRESA IN VARCHAR2 DEFAULT NULL, -- Tipo de empresa (Opcional)
                                        P_TIPO_PESSOA IN VARCHAR2 DEFAULT NULL, -- Tipo de pessoa (Opcional)
                                        P_ORIGEM_MERC IN VARCHAR2 DEFAULT NULL, -- Origem da mercadoria (Opcional)
                                        P_SIT_TRIBUT IN VARCHAR2 DEFAULT NULL, -- Situação tributária (Opcional)
                                        P_CODFISCAL IN NUMBER DEFAULT NULL, -- Código fiscal(CFOP) (Opcional)
                                        P_NCM IN VARCHAR2 DEFAULT NULL, -- NCM da mercadoria (Opcional)
                                        P_PUNITCONT IN NUMBER DEFAULT 0, -- Preço unitário
                                        P_VLIPI IN NUMBER DEFAULT 0, -- Valor do IPI
                                        P_VLFRETE IN NUMBER DEFAULT 0, -- Valor do frete
                                        P_VLST IN NUMBER DEFAULT 0, -- Valor do ST
                                        P_VLOUTROS IN NUMBER DEFAULT 0, -- Valor de outros
                                        P_BASEICMS IN NUMBER DEFAULT 0, -- Base ICMS
                                        P_PERCBASERED IN NUMBER DEFAULT 0, -- Redução Base ICMS
                                        -- Declarando as variáveis de saída
                                        P_BASECREDITOPRESUMIDO OUT PCMOV.BASEICMS%TYPE,
                                        P_VLCREDITOPRESUMIDO OUT PCMOV.VLCREDPRESUMIDO%TYPE,
                                        P_ALIQCREDITOPRESUMIDO OUT PCMOV.PERCCREDICMPRESUMIDO%TYPE,
                                        P_CCREDPRESUMIDO OUT PCMOVCOMPLE.CCREDPRESUMIDO%TYPE,
                                        P_IDCREDPRESUMIDO OUT NUMBER,
                                        P_MSG OUT VARCHAR2
  )
  RETURN VARCHAR2 IS
    VSMENSAGEM   VARCHAR2(32767);
    V_RESULT     VARCHAR2(500);
    VARIAVEL    FORMULA.RVARIAVEL;
    VFORMULACREDPRES    PCFORMULA.FORMULA%TYPE;
    VTVARIAVEIS FORMULA.TBVARIAVEIS;
    RESULTADO   FORMULA.TBVARIAVEIS;
    VFORMULARESULT    VARCHAR2(500);

    /*
    TIPO DE EMPRESA:
    Empresa Pequeno Porte        - EPP
    Filantrópica                 - FI
    Micro Empresa                - ME
    Microempreendedor Individual - MEI
    Normal RPA                   - NRPA
    Outros                       - O
    Produtor Rural               - PR
    Regime Especial              - R
    Simples Nacional             - SN
    Nenhum                       - NULL

    TIPO DE PESSOA:
    Física - F
    Jurídica - J
    Nenhum   - NULL

    Origem Mercadoria (valores de 0 a 8 ou NULL)
    Situação Tributária: (valores 00, 10, 20 ,30 ,40, 41, 50, 51, 60, 70, 90 ou NULL)
    Contribuinte consumidor final (valores 'S', 'N' ou NULL)
    */

  BEGIN
    -- Validações obrigatórias
    IF NVL(P_PUNITCONT, 0) + NVL(P_BASEICMS, 0) <= 0 THEN
        P_MSG := 'Erro: Pelo menos um dos valores P_PUNITCONT ou P_BASEICMS deve ser maior que zero.';
        RETURN P_MSG;
    END IF;

    IF (P_CODST IS NULL) OR (P_CODST <= 0) THEN
        P_MSG := 'Erro: Código figura tributária rotina 514 não informada.';
        RETURN P_MSG;
    END IF;

    IF (P_ALIQICMSNF IS NULL) OR (P_ALIQICMSNF < 0) THEN
        P_MSG := 'Erro: Alíquota de ICMS NF não informada e/ou inválida.';
        RETURN P_MSG;
    END IF;


    -- Obter fórmula do crédito presumido
    V_RESULT := FISCAL.GET_FORMULA_CREDPRESUMIDO(
        P_CODBENEFICIOFISCAL => P_CODBENEFICIOFISCAL,
        P_CODST => P_CODST,
        P_ALIQICMSNF => P_ALIQICMSNF,
        P_CONTRIBUINTECONSFINAL => P_CONTRIBUINTECONSFINAL,
        P_TIPO_EMPRESA => P_TIPO_EMPRESA,
        P_TIPO_PESSOA => P_TIPO_PESSOA,
        P_ORIGEM_MERC => P_ORIGEM_MERC,
        P_SIT_TRIBUT => P_SIT_TRIBUT,
        P_CODFISCAL => P_CODFISCAL,
        P_NCM => P_NCM,
        P_ALIQCREDPRESUMIDO => P_ALIQCREDITOPRESUMIDO,
        P_FORMULACREDPRES  => VFORMULACREDPRES,
        P_CCREDPRESUMIDO => P_CCREDPRESUMIDO,
        P_IDCREDPRESUMIDO => P_IDCREDPRESUMIDO
    );

    IF V_RESULT = 'OK' THEN
        -- Atribuir valores das variáveis
        VARIAVEL.NOME  := '[PUNITCONT]';
        VARIAVEL.VALOR := CASE WHEN P_PUNITCONT IS NULL THEN 0 ELSE P_PUNITCONT END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[VLIPI]';
        VARIAVEL.VALOR := CASE WHEN P_VLIPI IS NULL THEN 0 ELSE P_VLIPI END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[VLFRETE]';
        VARIAVEL.VALOR := CASE WHEN P_VLFRETE IS NULL THEN 0 ELSE P_VLFRETE END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[ST]';
        VARIAVEL.VALOR := CASE WHEN P_VLST IS NULL THEN 0 ELSE P_VLST END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[VLOUTROS]';
        VARIAVEL.VALOR := CASE WHEN P_VLOUTROS IS NULL THEN 0 ELSE P_VLOUTROS END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[BASEICMS]';
        VARIAVEL.VALOR := CASE WHEN P_BASEICMS IS NULL THEN 0 ELSE P_BASEICMS END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[PERCBASERED]';
        VARIAVEL.VALOR := CASE WHEN P_PERCBASERED IS NULL THEN 0 ELSE P_PERCBASERED END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        VARIAVEL.NOME  := '[PERC_CRED_PRESUMIDO]';
        VARIAVEL.VALOR := CASE WHEN P_ALIQCREDITOPRESUMIDO IS NULL THEN 0 ELSE P_ALIQCREDITOPRESUMIDO END;
        FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

        -- Calcular crédito presumido ICMS
        VFORMULACREDPRES := FORMULA.SUBSTITUIFORMULAS(VFORMULACREDPRES, RESULTADO);
        VFORMULARESULT := FORMULA.BUSCAVALOR(RESULTADO, 'VLR_CRED_PRES_BENEF_FISCAL');
        P_VLCREDITOPRESUMIDO := FORMULA.CALCULARSUBFORMULA(VFORMULARESULT, VTVARIAVEIS);

        IF P_VLCREDITOPRESUMIDO <= 0 THEN
            P_BASECREDITOPRESUMIDO := 0;
            P_ALIQCREDITOPRESUMIDO := 0;
        ELSE
            VFORMULACREDPRES := FORMULA.BUSCAVALOR(RESULTADO, 'BASE_CRED_PRES_BENEF_FISCAL');
            P_BASECREDITOPRESUMIDO := FORMULA.CALCULARSUBFORMULA(VFORMULACREDPRES, VTVARIAVEIS);
        END IF;

        -- Mensagem de sucesso
        P_MSG := 'OK';
    ELSE
        P_MSG := V_RESULT;
    END IF;

    RETURN P_MSG;

  EXCEPTION
    WHEN OTHERS THEN
        VSMENSAGEM := SQLCODE || '-' || SQLERRM;
        P_MSG := 'Erro inesperado: ' || VSMENSAGEM;
        RETURN NULL;
  END GET_DADOS_CREDITOPRESUMIDO;


  FUNCTION CALCULAR_CREDITOPRESUMIDO(P_NUMTRANSACAO IN NUMBER
                                     ,P_TIPOMOV      VARCHAR2
                                     ,P_ATIVARLOG    VARCHAR2 := 'N'
                                     ,P_MSG      OUT VARCHAR2)
  RETURN VARCHAR2 IS
  V_RETURN VARCHAR2(1);
  -- Variáveis de saída
  V_BASECREDITOPRESUMIDO NUMBER;
  v_VLCREDITOPRESUMIDO   NUMBER;
  v_ALIQCREDITOPRESUMIDO NUMBER;
  V_CCREDPRESUMIDO VARCHAR2(10);
  V_IDCREDPRESUMIDO NUMBER;
  V_MSG_RETORNO VARCHAR2(200);

  BEGIN
     BEGIN
       FOR DADOS_CREDITOPRESUMIDO IN CONSULTA_DADOS_CREDPRESUMIDO(P_NUMTRANSACAO,
                                                                   P_TIPOMOV)
       LOOP

       IF P_ATIVARLOG = 'S' THEN
         PKG_DEBUGGING_FWPC.ATIVARDEBUG('Cálculo de crédito presumido', '1.0',P_NUMTRANSACAO);
       END IF;

       PKG_DEBUGGING_FWPC.LOG('Dados : CODBENEFICIOFISCAL '||DADOS_CREDITOPRESUMIDO.CODBENEFICIOFISCAL||
                                       ' CODST '||DADOS_CREDITOPRESUMIDO.CODST||
                                       ' PERCICM '||DADOS_CREDITOPRESUMIDO.PERCICM||
                                       ' CONTRIBUINTECONSFINAL '||DADOS_CREDITOPRESUMIDO.CONTRIBUINTECONSFINAL||
                                       ' TIPOEMPRESA '||DADOS_CREDITOPRESUMIDO.TIPOEMPRESA||
                                       ' TIPOPESSOA '||DADOS_CREDITOPRESUMIDO.TIPOPESSOA||
                                       ' ORIGMERCTRIB '||DADOS_CREDITOPRESUMIDO.ORIGMERCTRIB||
                                       ' SITTRIBUT '||DADOS_CREDITOPRESUMIDO.SITTRIBUT||
                                       ' CODFISCAL '||DADOS_CREDITOPRESUMIDO.CODFISCAL||
                                       ' NBM '||DADOS_CREDITOPRESUMIDO.NBM||
                                       ' PUNITCONT '||DADOS_CREDITOPRESUMIDO.PUNITCONT||
                                       ' VLIPI '||DADOS_CREDITOPRESUMIDO.VLIPI||
                                       ' VLFRETE '||DADOS_CREDITOPRESUMIDO.VLFRETE||
                                       ' VLST '||DADOS_CREDITOPRESUMIDO.VLST||
                                       ' VLOUTROS '||DADOS_CREDITOPRESUMIDO.VLOUTROS||
                                       ' BASEICMS '||DADOS_CREDITOPRESUMIDO.BASEICMS||
                                       ' PERCBASERED '||DADOS_CREDITOPRESUMIDO.PERCBASERED
                                       ,'S');


       V_MSG_RETORNO := GET_DADOS_CREDITOPRESUMIDO(DADOS_CREDITOPRESUMIDO.CODBENEFICIOFISCAL, --Código Beneficio Fiscal
                                                   DADOS_CREDITOPRESUMIDO.CODST, -- Figura tributária rotina 514
                                                   DADOS_CREDITOPRESUMIDO.PERCICM, -- Alíquota ICMS NF
                                                   DADOS_CREDITOPRESUMIDO.CONTRIBUINTECONSFINAL, -- Contribuinte consumidor final (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.TIPOEMPRESA, -- Tipo de empresa (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.TIPOPESSOA, -- Tipo de pessoa (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.ORIGMERCTRIB, -- Origem da mercadoria (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.SITTRIBUT, -- Situação tributária (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.CODFISCAL, -- Código fiscal(CFOP) (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.NBM, -- NCM da mercadoria (Opcional)
                                                   DADOS_CREDITOPRESUMIDO.PUNITCONT, -- Preço unitário
                                                   DADOS_CREDITOPRESUMIDO.VLIPI, -- Valor do IPI
                                                   DADOS_CREDITOPRESUMIDO.VLFRETE, -- Valor do frete
                                                   DADOS_CREDITOPRESUMIDO.VLST, -- Valor do ST
                                                   DADOS_CREDITOPRESUMIDO.VLOUTROS, -- Valor de outros
                                                   DADOS_CREDITOPRESUMIDO.BASEICMS, -- Base ICMS
                                                   DADOS_CREDITOPRESUMIDO.PERCBASERED, -- Redução Base ICMS
                                                   V_BASECREDITOPRESUMIDO,
                                                   v_VLCREDITOPRESUMIDO,
                                                   v_ALIQCREDITOPRESUMIDO,
                                                   V_CCREDPRESUMIDO,
                                                   V_IDCREDPRESUMIDO,
                                                   P_MSG => P_MSG);

       IF V_MSG_RETORNO = 'OK' THEN
         IF DADOS_CREDITOPRESUMIDO.PREFATURAMENTO = 'S' THEN
           UPDATE PCMOVPREFAT
              SET PERCCREDICMPRESUMIDO = v_ALIQCREDITOPRESUMIDO,
                  VLCREDPRESUMIDO = v_VLCREDITOPRESUMIDO
            WHERE NUMTRANSITEM = DADOS_CREDITOPRESUMIDO.NUMTRANSITEM;


           UPDATE PCMOVCOMPLEPREFAT
              SET CCREDPRESUMIDO = V_CCREDPRESUMIDO,
                  BASECREDPRESUMIDO = V_BASECREDITOPRESUMIDO
            WHERE NUMTRANSITEM = DADOS_CREDITOPRESUMIDO.NUMTRANSITEM;
         ELSE
           UPDATE PCMOV
              SET PERCCREDICMPRESUMIDO = v_ALIQCREDITOPRESUMIDO,
                  VLCREDPRESUMIDO = v_VLCREDITOPRESUMIDO
            WHERE NUMTRANSITEM = DADOS_CREDITOPRESUMIDO.NUMTRANSITEM;


           UPDATE PCMOVCOMPLE
              SET CCREDPRESUMIDO = V_CCREDPRESUMIDO,
                  BASECREDPRESUMIDO = V_BASECREDITOPRESUMIDO
            WHERE NUMTRANSITEM = DADOS_CREDITOPRESUMIDO.NUMTRANSITEM;
         END IF;
       END IF;

         -- GRAVANDO LOG
       PKG_DEBUGGING_FWPC.LOG('Chamou GET_DADOS_CREDITOPRESUMIDO retorno:','S');
       PKG_DEBUGGING_FWPC.LOG('Produto: '||DADOS_CREDITOPRESUMIDO.CODPROD||' '||P_MSG, 'S');
       PKG_DEBUGGING_FWPC.LOG('ID Cadastro 4008: '|| V_IDCREDPRESUMIDO,'S');
       PKG_DEBUGGING_FWPC.LOG('V_BASECREDITOPRESUMIDO '||V_BASECREDITOPRESUMIDO||
                              ' v_VLCREDITOPRESUMIDO '||v_VLCREDITOPRESUMIDO||
                              ' v_ALIQCREDITOPRESUMIDO '||v_ALIQCREDITOPRESUMIDO
                              ,'S');
       END LOOP;

       V_RETURN := 'S';
       -- DESABILITANDO SERVIÇO LOG
       PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
     EXCEPTION
        WHEN OTHERS THEN
        PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
          P_MSG     := 'Erro o calcular Crédito Presumido.' || CHR(13) ||
                       'Erro original: ' || SQLERRM;
          V_RETURN := 'N';
     END;

    RETURN(V_RETURN);
  END;



  FUNCTION GET_DADOS_TRIBUTOS_REFORMA(P_PARAMETROS IN TIPO_TRIBUT_REFORMA)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_PARAMETROS TIPO_TRIBUT_REFORMA := P_PARAMETROS;

    -- Variáveis para armazenar resultado
    V_CODIGO_TRIBUTACAO_CBSIBS        NUMBER(10);
    V_COD_FORMULA_BASE_CBSIBS VARCHAR2(200);
    V_SOMATOTALNF_CBSIBS              VARCHAR2(1);
    V_CST_CBSIBS                      VARCHAR2(3);
    V_CCLASSTRIB_CBSIBS               VARCHAR2(6);
    --Retorno valores IBS UF
    V_PERC_IBS_UF                     NUMBER(18,6);
    V_PERC_RED_ALIQ_IBS_UF            NUMBER(7,4);
    --Retorno valores IBS Municipio  
    V_PERC_IBS_MUN                    NUMBER(18,6);
    V_PERC_RED_ALIQ_IBS_MUN           NUMBER(7,4);
    --Retorno valores CBS
    V_PERC_CBS                        NUMBER(7,4);
    V_PERC_RED_CBS                    NUMBER(7,4);
    --Retornos valores IS
    V_CODIGO_TRIBUTACAO_IS        NUMBER(10);
    V_COD_FORMULA_BASE_CALCULO_IS VARCHAR2(200);
    V_SOMATOTALNF_IS              VARCHAR2(1);
    V_CST_IS                      VARCHAR2(3);
    V_CCLASSTRIB_IS               VARCHAR2(6);
    V_PERC_IS                     NUMBER(18,6);

    V_UF VARCHAR2(2) := 'BR';
    V_BASE_CALCULO_PADRAO VARCHAR2(50) := '(&BASE_CALCULO& * [ALIQUOTA])';

    -- Função auxiliar para consulta, recebe filtros de consumo específicos
    FUNCTION CONSULTA_TRIBUTOS(
      P_TIPO_LOCAL_CONSUMO VARCHAR2,
      P_LOCAL_CONSUMO VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
      SELECT PCTRIBUTACAO.CODIGO_TRIBUTACAO,
             PCTRIBUTACAO.BASE_CALCULO,
             PCTRIBUTACAO.SOMATOTALNF,
             PCTRIBUTACAO.CST,
             PCTRIBUTACAO.CCLASSTRIB,
             --Retorno valores IBS UF
             PCTRIBUTACAO.PERC_IBS_UF,
             PCTRIBUTACAO.PERC_RED_IBS_UF,
             --Retorno valores IBS Municipio  
             PCTRIBUTACAO.PERC_IBS_MUN,
             PCTRIBUTACAO.PERC_RED_IBS_MUN,
             --Retorno valores CBS
             PCTRIBUTACAO.PERC_CBS,
             PCTRIBUTACAO.PERC_RED_CBS,
             --Retornos valores IS
             PCTRIBUTACAO.CODIGO_TRIBUTACAO,
             PCTRIBUTACAO.BASE_CALCULO,
             PCTRIBUTACAO.SOMATOTALNF,
             PCTRIBUTACAO.CST,
             PCTRIBUTACAO.CCLASSTRIB,
             PCTRIBUTACAO.PERC_IS
        INTO V_CODIGO_TRIBUTACAO_CBSIBS,
             V_COD_FORMULA_BASE_CBSIBS,
             V_SOMATOTALNF_CBSIBS,
             V_CST_CBSIBS,
             V_CCLASSTRIB_CBSIBS,
             --Retorno valores IBS UF
             V_PERC_IBS_UF,
             V_PERC_RED_ALIQ_IBS_UF,
             --Retorno valores IBS Municipio  
             V_PERC_IBS_MUN,
             V_PERC_RED_ALIQ_IBS_MUN,
             --Retorno valores CBS
             V_PERC_CBS,
             V_PERC_RED_CBS,
             --Retornos valores IS
             V_CODIGO_TRIBUTACAO_IS,
             V_COD_FORMULA_BASE_CALCULO_IS,
             V_SOMATOTALNF_IS,
             V_CST_IS,
             V_CCLASSTRIB_IS,
             V_PERC_IS
        FROM PCTRIBUTACAO
        LEFT JOIN PCTRIBUTACAO_FILTRO_PRODUTO ON PCTRIBUTACAO.CODIGO_TRIBUTACAO = PCTRIBUTACAO_FILTRO_PRODUTO.CODIGO_TRIBUTACAO
        LEFT JOIN PCTRIBUTACAO_FILTRO_NCM ON PCTRIBUTACAO.CODIGO_TRIBUTACAO = PCTRIBUTACAO_FILTRO_NCM.CODIGO_TRIBUTACAO
       WHERE TIPO_IMPOSTO = P_PARAMETROS.TIPO_IMPOSTO
         AND TIPO_LOCAL_CONSUMO = P_TIPO_LOCAL_CONSUMO
         AND DTEXCLUSAO IS NULL
         AND NVL(PCTRIBUTACAO.TIPO_OPERACAO, 'A') IN ('A', P_PARAMETROS.TIPO_OPERACAO)
         AND (PCTRIBUTACAO_FILTRO_PRODUTO.CODPROD IS NULL OR PCTRIBUTACAO_FILTRO_PRODUTO.CODPROD = P_PARAMETROS.CODPROD)
         AND (PCTRIBUTACAO_FILTRO_NCM.NCM IS NULL OR PCTRIBUTACAO_FILTRO_NCM.NCM = P_PARAMETROS.NCM)

         AND (PCTRIBUTACAO.DEVOLUCAO IS NULL OR PCTRIBUTACAO.DEVOLUCAO = NVL(P_PARAMETROS.DEVOLUCAO,'N'))
         AND (PCTRIBUTACAO.CONSUMIDOR_FINAL IS NULL OR PCTRIBUTACAO.CONSUMIDOR_FINAL = NVL(P_PARAMETROS.CONSUMIDOR_FINAL,'N'))
         AND (PCTRIBUTACAO.CONTRIBUINTE IS NULL OR PCTRIBUTACAO.CONTRIBUINTE = NVL(P_PARAMETROS.CONTRIBUINTE,'N'))         
         AND (PCTRIBUTACAO.TIPO_EMPRESA IS NULL OR PCTRIBUTACAO.TIPO_EMPRESA = NVL(P_PARAMETROS.TIPO_EMPRESA,'N'))
         AND (PCTRIBUTACAO.TIPO_PESSOA IS NULL OR PCTRIBUTACAO.TIPO_PESSOA = NVL(P_PARAMETROS.TIPO_PESSOA,'N'))
         AND (PCTRIBUTACAO.ORGAO_PUBLICO IS NULL OR PCTRIBUTACAO.ORGAO_PUBLICO = NVL(P_PARAMETROS.ORGAO_PUBLICO,'N'))       
         AND (PCTRIBUTACAO.ORIGEM_MERCADORIA IS NULL OR PCTRIBUTACAO.ORIGEM_MERCADORIA = NVL(P_PARAMETROS.ORIGEM_MERCADORIA,'N'))         
         AND (PCTRIBUTACAO.TIPO_MERC IS NULL OR PCTRIBUTACAO.TIPO_MERC = NVL(P_PARAMETROS.TIPO_MERC,'N'))        
         AND (
              (P_TIPO_LOCAL_CONSUMO = 'M' AND LOCAL_CONSUMO_MUNICIPIO = P_LOCAL_CONSUMO) OR
              (P_TIPO_LOCAL_CONSUMO = 'G' AND LOCAL_CONSUMO_GERAL = P_LOCAL_CONSUMO)
             )
         AND ROWNUM = 1
       ORDER BY
         CASE WHEN NVL(PCTRIBUTACAO.CONSUMIDOR_FINAL,'N') = NVL(P_PARAMETROS.CONSUMIDOR_FINAL,'N') THEN 1 ELSE 2 END,
         CASE WHEN NVL(PCTRIBUTACAO.CONTRIBUINTE,'N') = NVL(P_PARAMETROS.CONTRIBUINTE,'N') THEN 1 ELSE 2 END,         
         CASE WHEN NVL(PCTRIBUTACAO.TIPO_EMPRESA,'N') = NVL(P_PARAMETROS.TIPO_EMPRESA,'N') THEN 1 ELSE 2 END,
         CASE WHEN NVL(PCTRIBUTACAO.TIPO_PESSOA,'N') = NVL(P_PARAMETROS.TIPO_PESSOA,'N') THEN 1 ELSE 2 END,
         CASE WHEN NVL(PCTRIBUTACAO.ORGAO_PUBLICO,'N') = NVL(P_PARAMETROS.ORGAO_PUBLICO,'N') THEN 1 ELSE 2 END,
         CASE WHEN NVL(PCTRIBUTACAO.ORIGEM_MERCADORIA,'N') = NVL(P_PARAMETROS.ORIGEM_MERCADORIA,'N') THEN 1 ELSE 2 END,
         CASE WHEN NVL(PCTRIBUTACAO.TIPO_MERC,'N') = NVL(P_PARAMETROS.TIPO_MERC,'N') THEN 1 ELSE 2 END,
         CASE NVL(PCTRIBUTACAO.TIPO_OPERACAO, 'A')
           WHEN P_PARAMETROS.TIPO_OPERACAO THEN 1
           WHEN 'A' THEN 2
           ELSE 3
         END;
         
         
      IF (P_PARAMETROS.TIPO_IMPOSTO = 'CBSIBS') THEN
        V_PARAMETROS.CODIGO_TRIBUTACAO_CBSIBS  := V_CODIGO_TRIBUTACAO_CBSIBS;
        V_PARAMETROS.COD_FORMULA_BASE_CBSIBS   := V_COD_FORMULA_BASE_CBSIBS;
        V_PARAMETROS.SOMATOTALNF_CBSIBS        := V_SOMATOTALNF_CBSIBS;
        V_PARAMETROS.CST_CBSIBS                := V_CST_CBSIBS;
        V_PARAMETROS.CCLASSTRIB_CBSIBS         := V_CCLASSTRIB_CBSIBS;
             --Retorno valores IBS UF
        V_PARAMETROS.PERC_IBS_UF               := V_PERC_IBS_UF;
        V_PARAMETROS.PERC_RED_ALIQ_IBS_UF      := V_PERC_RED_ALIQ_IBS_UF;
             --Retorno valores IBS Municipio  
        V_PARAMETROS.PERC_IBS_MUN              := V_PERC_IBS_MUN;
        V_PARAMETROS.PERC_RED_ALIQ_IBS_MUN     := V_PERC_RED_ALIQ_IBS_MUN;
             --Retorno valores CBS
        V_PARAMETROS.PERC_CBS                  := V_PERC_CBS;
        V_PARAMETROS.PERC_RED_CBS              := V_PERC_RED_CBS;
      ELSE
        --Retornos valores IS
        V_PARAMETROS.CODIGO_TRIBUTACAO_IS        := V_CODIGO_TRIBUTACAO_IS;
        V_PARAMETROS.COD_FORMULA_BASE_CALCULO_IS := V_COD_FORMULA_BASE_CALCULO_IS;
        V_PARAMETROS.SOMATOTALNF_IS              := V_SOMATOTALNF_IS;
        V_PARAMETROS.CST_IS                      := V_CST_IS;
        V_PARAMETROS.CCLASSTRIB_IS               := V_CCLASSTRIB_IS;
        V_PARAMETROS.PERC_IS                     := V_PERC_IS;        
      END IF;  
      
      
      V_PARAMETROS.FORMULA_VALOR_TRIBUTO_CBSIBS := V_BASE_CALCULO_PADRAO;
      V_PARAMETROS.FORMULA_VALOR_TRIBUTO_IS     := V_BASE_CALCULO_PADRAO;               

      RETURN TRUE;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END CONSULTA_TRIBUTOS;

  BEGIN
    -- Define UF cliente/fornecedor
    IF P_PARAMETROS.CODCLI > 0 THEN
      V_UF := P_PARAMETROS.UF_CLIENTE;
    ELSIF P_PARAMETROS.CODFORNEC > 0 THEN
      V_UF := P_PARAMETROS.UF_FORNECEDOR;
    END IF;

    PKG_DEBUGGING_FWPC.LOG('Iniciando consulta dos dados de novos tributos.', 'S');

    -- Tenta por Município
    IF CONSULTA_TRIBUTOS('M', TO_CHAR(P_PARAMETROS.CODIGO_MUNICIPIO)) THEN
      PKG_DEBUGGING_FWPC.LOG('Tributação localizada por Município: ' || P_PARAMETROS.CODIGO_MUNICIPIO, 'S');

    -- Senão tenta por UF
    ELSIF CONSULTA_TRIBUTOS('G', V_UF) THEN
      PKG_DEBUGGING_FWPC.LOG('Tributação localizada por UF: ' || V_UF, 'S');

    -- Senão tenta por Brasil
    ELSIF CONSULTA_TRIBUTOS('G', 'BR') THEN
      PKG_DEBUGGING_FWPC.LOG('Tributação localizada por Nação: BR', 'S');

    ELSE
      PKG_DEBUGGING_FWPC.LOG('Nenhuma configuração encontrada para o tipo de imposto: ' || P_PARAMETROS.TIPO_IMPOSTO, 'S');
    END IF;

    RETURN V_PARAMETROS;        
  end GET_DADOS_TRIBUTOS_REFORMA;  


  FUNCTION GET_CALCULAR_TRIBUTOS_REFORMA(P_PARAMETROS in TIPO_TRIBUT_REFORMA)
  RETURN TIPO_TRIBUT_REFORMA IS
    VARIAVEL           FORMULA.RVARIAVEL;
    VFORMULA_TRIBUTOS  PCFORMULA.FORMULA%TYPE;
    VTVARIAVEIS        FORMULA.TBVARIAVEIS;
    RESULTADO          FORMULA.TBVARIAVEIS;
    V_PARAMETROS       TIPO_TRIBUT_REFORMA;
    V_TIPO_IMPOSTO     VARCHAR2(15);

    /*Inicio sub funções/procedures*/
    PROCEDURE PREENCHER_VARIAVEIS_FORMULA IS
    BEGIN    
      IF (P_PARAMETROS.COD_FORMULA_BASE_CBSIBS IS NOT NULL) OR
         (P_PARAMETROS.COD_FORMULA_BASE_CALCULO_IS IS NOT NULL) THEN
         -- Atribuir valores das variáveis
         VARIAVEL.NOME  := '&PUNITCONT&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_PRODUTO IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_PRODUTO END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VAR_ST&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_ICMS_ST IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_ICMS_ST END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VAR_FECP&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_FCP_ST IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_FCP_ST END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VAR_IPI&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_IPI IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_IPI END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VLFRETE&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_FRETE IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_FRETE END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VLOUTROS&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_OUTROS IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_OUTROS END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         IF (P_PARAMETROS.TIPO_IMPOSTO = 'CBSIBS') THEN
           V_TIPO_IMPOSTO := 'BASE_CBSIBS';
         ELSE
           V_TIPO_IMPOSTO := 'BASE_IS';
         END IF;
      END IF;             
    END PREENCHER_VARIAVEIS_FORMULA;
    
    PROCEDURE CALCULAR_VALOR_IS IS
    BEGIN 
      -- Calcular tributo
      VFORMULA_TRIBUTOS  := FORMULA.SUBSTITUIFORMULAS(P_PARAMETROS.COD_FORMULA_BASE_CALCULO_IS, RESULTADO);
      VFORMULA_TRIBUTOS  := FORMULA.BUSCAVALOR(RESULTADO, V_TIPO_IMPOSTO);

      V_PARAMETROS.FORMULA_BASE_CALCULO_IS := VFORMULA_TRIBUTOS;             
             
      V_PARAMETROS.VALOR_BASE_IS := FORMULA.CALCULARSUBFORMULA(VFORMULA_TRIBUTOS, VTVARIAVEIS);
      V_PARAMETROS.VALOR_IS      := ROUND(((V_PARAMETROS.VALOR_BASE_IS * V_PARAMETROS.PERC_IS)/100),6);          
    END CALCULAR_VALOR_IS;    
    
    
    PROCEDURE CALCULAR_VALOR_CBSIBS IS
    BEGIN 
      -- Calcular tributo
      VFORMULA_TRIBUTOS  := FORMULA.SUBSTITUIFORMULAS(P_PARAMETROS.COD_FORMULA_BASE_CBSIBS, RESULTADO);
      VFORMULA_TRIBUTOS  := FORMULA.BUSCAVALOR(RESULTADO, V_TIPO_IMPOSTO);

      V_PARAMETROS.FORMULA_BASE_CALCULO_CBSIBS := VFORMULA_TRIBUTOS;                                    
      V_PARAMETROS.VALOR_BASE_CBSIBS           := FORMULA.CALCULARSUBFORMULA(VFORMULA_TRIBUTOS, VTVARIAVEIS);
      

      if (V_PARAMETROS.PERC_RED_CBS > 0) then
        V_PARAMETROS.ALIQ_EFETIVA_CBS     := (V_PARAMETROS.PERC_CBS * (1-(V_PARAMETROS.PERC_RED_CBS/100)));        
      else
        V_PARAMETROS.ALIQ_EFETIVA_CBS     := V_PARAMETROS.PERC_CBS;        
      end if;
        
      if (V_PARAMETROS.PERC_RED_ALIQ_IBS_UF > 0) then
        V_PARAMETROS.ALIQ_EFETIVA_IBS_UF     := (V_PARAMETROS.PERC_IBS_UF * (1-(V_PARAMETROS.PERC_RED_ALIQ_IBS_UF/100)));        
      else
        V_PARAMETROS.ALIQ_EFETIVA_IBS_UF     := V_PARAMETROS.PERC_IBS_UF;        
      end if;
      
      if (V_PARAMETROS.PERC_RED_ALIQ_IBS_MUN > 0) then
        V_PARAMETROS.ALIQ_EFETIVA_IBS_MUN     := (V_PARAMETROS.PERC_IBS_MUN * (1-(V_PARAMETROS.PERC_RED_ALIQ_IBS_MUN/100)));        
      else
        V_PARAMETROS.ALIQ_EFETIVA_IBS_MUN     := V_PARAMETROS.PERC_IBS_MUN;        
      end if;      
            
        
      
      V_PARAMETROS.VALOR_CBS     := ROUND(((V_PARAMETROS.VALOR_BASE_CBSIBS * V_PARAMETROS.ALIQ_EFETIVA_CBS)/100),6);
      V_PARAMETROS.VALOR_IBS_UF  := ROUND(((V_PARAMETROS.VALOR_BASE_CBSIBS * V_PARAMETROS.ALIQ_EFETIVA_IBS_UF)/100),6);
      V_PARAMETROS.VALOR_IBS_MUN := ROUND(((V_PARAMETROS.VALOR_BASE_CBSIBS * V_PARAMETROS.ALIQ_EFETIVA_IBS_MUN)/100),6);
      
      
    END CALCULAR_VALOR_CBSIBS;      
    /*Fim sub funções/procedures*/
    
  BEGIN
    V_PARAMETROS := P_PARAMETROS;

    PKG_DEBUGGING_FWPC.LOG('Inicio do processo de cálculo dos novos tributos','S');

      IF (P_PARAMETROS.COD_FORMULA_BASE_CBSIBS IS NOT NULL) OR
         (P_PARAMETROS.COD_FORMULA_BASE_CALCULO_IS IS NOT NULL) THEN
         -- Atribuir valores das variáveis
         VARIAVEL.NOME  := '&PUNITCONT&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_PRODUTO IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_PRODUTO END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VAR_ST&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_ICMS_ST IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_ICMS_ST END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VAR_FECP&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_FCP_ST IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_FCP_ST END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VAR_IPI&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_IPI IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_IPI END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VLFRETE&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_FRETE IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_FRETE END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         VARIAVEL.NOME  := '&VLOUTROS&';
         VARIAVEL.VALOR := CASE WHEN P_PARAMETROS.VALOR_OUTROS IS NULL THEN 0 ELSE P_PARAMETROS.VALOR_OUTROS END;
         FORMULA.ATRIBUIVALOR(VARIAVEL, VTVARIAVEIS);

         IF (P_PARAMETROS.TIPO_IMPOSTO = 'CBSIBS') THEN
           V_TIPO_IMPOSTO := 'BASE_CBSIBS';
           CALCULAR_VALOR_CBSIBS;           
         ELSE
           V_TIPO_IMPOSTO := 'BASE_IS';
           CALCULAR_VALOR_IS;           
         END IF;                                           
      END IF;             
      
    RETURN(V_PARAMETROS);
    
  END GET_CALCULAR_TRIBUTOS_REFORMA;

  FUNCTION GET_DADOS_CLIENTE_FORNECEDOR(P_PARAMETROS in TIPO_TRIBUT_REFORMA)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_CODIGO_MUNICIPIO VARCHAR2(10);
    V_CONSUMIDOR_FINAL VARCHAR2(1);
    V_TIPO_EMPRESA     VARCHAR2(4);
    V_TIPO_PESSOA      VARCHAR2(1);
    V_CONTRIBUINTE     VARCHAR2(1);
    V_ORGAO_PUBLICO    VARCHAR2(1);
    V_UF               VARCHAR2(2);

    V_PARAMETROS       TIPO_TRIBUT_REFORMA;
  BEGIN
    PKG_DEBUGGING_FWPC.LOG('Inicio da consulta por código de município','S');

    V_PARAMETROS  := P_PARAMETROS;

    IF V_PARAMETROS.CODCLI > 0 THEN
      BEGIN
        PKG_DEBUGGING_FWPC.LOG('Realizando a consulta do código de município para o codcli: '||V_PARAMETROS.CODCLI,'S');

        SELECT PCCIDADE.CODIBGE,
               PCCIDADE.UF,
               PCCLIENT.CONSUMIDORFINAL,
               PCCLIENT.TIPOEMPRESA,
               PCCLIENT.TIPOFJ,
               PCCLIENT.CONTRIBUINTE,
               CASE
                  WHEN PCCLIENT.ORGAOPUB = 'S'
                       OR PCCLIENT.ORGAOPUBFEDERAL = 'S'
                       OR PCCLIENT.ORGAOPUBMUNICIPAL = 'S'
                  THEN 'S'
                  ELSE 'N'
               END AS ORGAO_PUBLICO
          INTO V_CODIGO_MUNICIPIO,
               V_UF,
               V_CONSUMIDOR_FINAL,
               V_TIPO_EMPRESA,
               V_TIPO_PESSOA,
               V_CONTRIBUINTE,
               V_ORGAO_PUBLICO
          FROM PCCLIENT,
               PCCIDADE
         WHERE PCCLIENT.CODCIDADE = PCCIDADE.CODCIDADE
           AND PCCLIENT.CODCLI = V_PARAMETROS.CODCLI;


        V_PARAMETROS.CODIGO_MUNICIPIO := V_CODIGO_MUNICIPIO;
        V_PARAMETROS.UF_CLIENTE       := V_UF;
        V_PARAMETROS.CONSUMIDOR_FINAL := V_CONSUMIDOR_FINAL;
        V_PARAMETROS.TIPO_EMPRESA     := V_TIPO_EMPRESA;
        V_PARAMETROS.TIPO_PESSOA      := V_TIPO_PESSOA;
        V_PARAMETROS.CONTRIBUINTE     := V_CONTRIBUINTE;
        V_PARAMETROS.ORGAO_PUBLICO    := V_ORGAO_PUBLICO;

        PKG_DEBUGGING_FWPC.LOG('OK: Encontrado código de municipio '||V_CODIGO_MUNICIPIO||' para o codcli: '||V_PARAMETROS.CODCLI||
                               ' Cód Municipio: '||V_PARAMETROS.CODIGO_MUNICIPIO||
                               ' UF Cliente: '||V_PARAMETROS.UF_CLIENTE||
                               ' Consumidor Final: '||V_PARAMETROS.CONSUMIDOR_FINAL||
                               ' Tipo Empresa: '||V_PARAMETROS.TIPO_EMPRESA||
                               ' Tipo Pessoa: '||V_PARAMETROS.TIPO_PESSOA||
                               ' Contribuinte: '||V_PARAMETROS.CONTRIBUINTE||
                               ' Contribuinte: '||V_PARAMETROS.ORGAO_PUBLICO,
                               'S');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('ERRO: Não encontrado dados para o CODCLI: '||V_PARAMETROS.CODCLI||' '||SQLERRM,'S');
        END;
        WHEN OTHERS THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('ERRO: Erro ao consultar o código de cliente: '||V_PARAMETROS.CODCLI||' '|| SQLERRM,'S');
        END;
      END;
    END IF;

    IF V_PARAMETROS.CODFORNEC > 0 THEN
      BEGIN
        PKG_DEBUGGING_FWPC.LOG('Realizando a consulta do código de município para o codfornec: '||V_PARAMETROS.CODFORNEC,'S');

        SELECT PCCIDADE.CODIBGE,
               PCCIDADE.UF,
               PCCLIENT.CONSUMIDORFINAL,
               PCCLIENT.TIPOEMPRESA,
               PCCLIENT.TIPOFJ,
               PCCLIENT.CONTRIBUINTE,
               CASE
                  WHEN PCCLIENT.ORGAOPUB = 'S'
                       OR PCCLIENT.ORGAOPUBFEDERAL = 'S'
                       OR PCCLIENT.ORGAOPUBMUNICIPAL = 'S'
                  THEN 'S'
                  ELSE 'N'
               END AS ORGAO_PUBLICO
          INTO V_CODIGO_MUNICIPIO,
               V_UF,
               V_CONSUMIDOR_FINAL,
               V_TIPO_EMPRESA,
               V_TIPO_PESSOA,
               V_CONTRIBUINTE,
               V_ORGAO_PUBLICO
          FROM PCFORNEC,
               PCCIDADE,
               PCCLIENT
         WHERE PCFORNEC.CODCIDADE = PCCIDADE.CODCIDADE
           AND PCFORNEC.CODCLI(+) = PCCLIENT.CODCLI
           AND PCFORNEC.CODFORNEC = V_PARAMETROS.CODFORNEC;

        V_PARAMETROS.CODIGO_MUNICIPIO := V_CODIGO_MUNICIPIO;
        V_PARAMETROS.UF_FORNECEDOR    := V_UF;
        V_PARAMETROS.CONSUMIDOR_FINAL := V_CONSUMIDOR_FINAL;
        V_PARAMETROS.TIPO_EMPRESA     := V_TIPO_EMPRESA;
        V_PARAMETROS.TIPO_PESSOA      := V_TIPO_PESSOA;
        V_PARAMETROS.CONTRIBUINTE     := V_CONTRIBUINTE;
        V_PARAMETROS.ORGAO_PUBLICO    := V_ORGAO_PUBLICO;

        PKG_DEBUGGING_FWPC.LOG('OK: Encontrado dados para o fornecedor codfornec: '||V_PARAMETROS.CODFORNEC||
                               ' Cód Municipio: '||V_PARAMETROS.CODIGO_MUNICIPIO||
                               ' UF Cliente: '||V_PARAMETROS.UF_FORNECEDOR||
                               ' Consumidor Final: '||V_PARAMETROS.CONSUMIDOR_FINAL||
                               ' Tipo Empresa: '||V_PARAMETROS.TIPO_EMPRESA||
                               ' Tipo Pessoa: '||V_PARAMETROS.TIPO_PESSOA||
                               ' Contribuinte: '||V_PARAMETROS.CONTRIBUINTE||
                               ' Contribuinte: '||V_PARAMETROS.ORGAO_PUBLICO,
                               'S');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('ERRO: Não encontrado dados para o fornecedor codfornec: '||V_PARAMETROS.CODFORNEC||' '||SQLERRM,'S');
        END;
        WHEN OTHERS THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('ERRO: Erro ao consultar o código do fornecedor: '||V_PARAMETROS.CODFORNEC||' '|| SQLERRM,'S');
        END;
      END;
    END IF;

    RETURN(V_PARAMETROS);
  END GET_DADOS_CLIENTE_FORNECEDOR;

  FUNCTION GET_DADOS_CLIENTE_END_ENTREGA(P_PARAMETROS in TIPO_TRIBUT_REFORMA)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_CODIGO_MUNICIPIO_END_ENTREGA VARCHAR2(10);
    V_UF_END_ENTREGA               VARCHAR2(2);

    V_PARAMETROS       TIPO_TRIBUT_REFORMA;
  BEGIN
    PKG_DEBUGGING_FWPC.LOG('Inicio da consulta por endereço de entrega codCli: '||V_PARAMETROS.CODCLI||
                           ' V_PARAMETROS.CODIGO_ENDERECO_CLI: '||V_PARAMETROS.CODIGO_ENDERECO_CLI,'S');

    V_PARAMETROS  := P_PARAMETROS;

    V_CODIGO_MUNICIPIO_END_ENTREGA := '';
    V_UF_END_ENTREGA   := '';

    IF (V_PARAMETROS.CODIGO_ENDERECO_CLI > 0) AND
       (V_PARAMETROS.CODCLI > 0)THEN
      BEGIN
      SELECT PCCLIENTENDENT.ESTENT,
             NVL(PCCLIENTENDENT.CODMUNICIPIO, PCCIDADE.CODIBGE) CODMUNICIPIO
        INTO V_UF_END_ENTREGA,
             V_CODIGO_MUNICIPIO_END_ENTREGA
        FROM PCCLIENTENDENT,
             PCCIDADE
       WHERE PCCLIENTENDENT.CODCIDADE    = PCCIDADE.CODCIDADE
         AND PCCLIENTENDENT.CODCLI       = V_PARAMETROS.CODCLI
         AND PCCLIENTENDENT.CODENDENTCLI = V_PARAMETROS.CODIGO_ENDERECO_CLI;



        V_PARAMETROS.CODIGO_MUNICIPIO := V_CODIGO_MUNICIPIO_END_ENTREGA;
        V_PARAMETROS.UF_CLIENTE       := V_UF_END_ENTREGA;

        PKG_DEBUGGING_FWPC.LOG('OK: Encontrado endereco de entrega para o CODCLI: '||V_PARAMETROS.CODCLI||
                               ' V_PARAMETROS.CODIGO_ENDERECO_CLI: '||V_PARAMETROS.CODIGO_ENDERECO_CLI||
                               ' V_CODIGO_MUNICIPIO_END_ENTREGA: '||V_CODIGO_MUNICIPIO_END_ENTREGA||
                               ' V_UF_END_ENTREGA: '||V_UF_END_ENTREGA,
                               'S');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        BEGIN
         PKG_DEBUGGING_FWPC.LOG('ERRO: Não encontrado endereco de entrega para o CODCLI: '||V_PARAMETROS.CODCLI||' V_PARAMETROS.CODIGO_ENDERECO_CLI: '||V_PARAMETROS.CODIGO_ENDERECO_CLI||' '||SQLERRM,'S');
        END;
      END;
    END IF;

    RETURN(V_PARAMETROS);
  END GET_DADOS_CLIENTE_END_ENTREGA;
  
  
  FUNCTION CALCULAR_TODOS_TRIBUTOS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                           P_MSG        out varchar2)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_DADOS_TRIBUTACAO TIPO_TRIBUT_REFORMA;
  BEGIN
    BEGIN
      PKG_DEBUGGING_FWPC.ATIVARDEBUG('CALCULAR_TODOS_TRIB', '1.0');
      PKG_DEBUGGING_FWPC.LOG('Inicio cálculo CBSIBS para filial| '||P_PARAMETROS.CODFILIAL||
                             ' Produto: '||P_PARAMETROS.CODPROD||
                             ' Ncm:'||P_PARAMETROS.NCM,'S');


      V_DADOS_TRIBUTACAO                  := P_PARAMETROS;
      V_DADOS_TRIBUTACAO.TIPO_IMPOSTO     := 'CBSIBS';

      --Busca os dados do cliente ou fornecedor
      V_DADOS_TRIBUTACAO := GET_DADOS_CLIENTE_FORNECEDOR(V_DADOS_TRIBUTACAO);

      --Busca os dados do endereço de entrega do cliente
      V_DADOS_TRIBUTACAO := GET_DADOS_CLIENTE_END_ENTREGA(V_DADOS_TRIBUTACAO);

      --Busca os dados de cadastro da rotina 4000
      V_DADOS_TRIBUTACAO := GET_DADOS_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);

      --Calcula os novos impostos com base na tributação que foi encontrada
      V_DADOS_TRIBUTACAO := GET_CALCULAR_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);      
      
      
      PKG_DEBUGGING_FWPC.LOG('Inicio cálculo CBSIBS para filial| '||P_PARAMETROS.CODFILIAL||
                             ' Produto: '||P_PARAMETROS.CODPROD||
                             ' Ncm:'||P_PARAMETROS.NCM,'S');
                                   
      V_DADOS_TRIBUTACAO.TIPO_IMPOSTO     := 'IS';

      --Busca os dados de cadastro da rotina 4000
      V_DADOS_TRIBUTACAO := GET_DADOS_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);

      --Calcula os novos impostos com base na tributação que foi encontrada
      V_DADOS_TRIBUTACAO := GET_CALCULAR_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);      
      
      PKG_DEBUGGING_FWPC.LOG('Finailzando o processo de cálculo CBS com os seguintes dados:'||
                             ' Código Tributação: '||V_DADOS_TRIBUTACAO.CODIGO_TRIBUTACAO_CBSIBS||
                             ' Código da Base de Cálculo: '||V_DADOS_TRIBUTACAO.COD_FORMULA_BASE_CBSIBS||                                                          
                             ' CST: '||V_DADOS_TRIBUTACAO.CST_CBSIBS||
                             ' CClassTrib: '||V_DADOS_TRIBUTACAO.CCLASSTRIB_CBSIBS||
                             
                             ' Valor da base de cálculo: '||V_DADOS_TRIBUTACAO.VALOR_BASE_CBSIBS||
                             ' Aliquota CBS: '||V_DADOS_TRIBUTACAO.PERC_CBS||
                             ' Valor Cbs calculado: '||V_DADOS_TRIBUTACAO.VALOR_CBS||
                             
                             ' Perc IBS UF: '||V_DADOS_TRIBUTACAO.PERC_IBS_UF||
                             ' Perc Red IBS UF: '||V_DADOS_TRIBUTACAO.PERC_RED_ALIQ_IBS_UF||
                             ' Valor IBS UF calculado: '||V_DADOS_TRIBUTACAO.VALOR_IBS_UF||
                             
                             ' Perc IBS MUN: '||V_DADOS_TRIBUTACAO.PERC_IBS_MUN||
                             ' Perc Red IBS MUN: '||V_DADOS_TRIBUTACAO.PERC_RED_ALIQ_IBS_MUN||
                             ' Valor IBS MUN calculado: '||V_DADOS_TRIBUTACAO.VALOR_IBS_MUN||
                             
                             ' Código Tributação: '||V_DADOS_TRIBUTACAO.CODIGO_TRIBUTACAO_IS||
                             ' Código da Base de Cálculo: '||V_DADOS_TRIBUTACAO.COD_FORMULA_BASE_CALCULO_IS||
                             ' CST: '||V_DADOS_TRIBUTACAO.CST_IS||
                             ' CClassTrib: '||V_DADOS_TRIBUTACAO.CCLASSTRIB_IS||
                             ' Valor da base de cálculo: '||V_DADOS_TRIBUTACAO.VALOR_BASE_IS||
                             ' Aliquota: '||V_DADOS_TRIBUTACAO.PERC_IS||
                             ' IS calculado: '||V_DADOS_TRIBUTACAO.VALOR_IS     
                             ,'S');

      PKG_DEBUGGING_FWPC.DESATIVARDEBUG;

      P_MSG := 'OK';
      RETURN(V_DADOS_TRIBUTACAO);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('Erro geral no processo de cálculo do CALCULAR_TODOS_TRIBUTOS: '||SQLERRM,'S');
          P_MSG := 'ERRO';
          RETURN(V_DADOS_TRIBUTACAO);
        END;
    END;
  END CALCULAR_TODOS_TRIBUTOS;  
  
  

  FUNCTION CALCULAR_CBSIBS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                           P_MSG        out varchar2)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_DADOS_TRIBUTACAO TIPO_TRIBUT_REFORMA;
  BEGIN
    BEGIN
      PKG_DEBUGGING_FWPC.ATIVARDEBUG('CALCULAR_CBSIBS', '1.0');
      PKG_DEBUGGING_FWPC.LOG('Inicio cálculo CBS para filial| '||P_PARAMETROS.CODFILIAL||
                             ' Produto: '||P_PARAMETROS.CODPROD||
                             ' Ncm:'||P_PARAMETROS.NCM,'S');


      V_DADOS_TRIBUTACAO                  := P_PARAMETROS;
      V_DADOS_TRIBUTACAO.TIPO_IMPOSTO     := 'CBSIBS';

      --Busca os dados do cliente ou fornecedor
      V_DADOS_TRIBUTACAO := GET_DADOS_CLIENTE_FORNECEDOR(V_DADOS_TRIBUTACAO);

      --Busca os dados do endereço de entrega do cliente
      V_DADOS_TRIBUTACAO := GET_DADOS_CLIENTE_END_ENTREGA(V_DADOS_TRIBUTACAO);

      --Busca os dados de cadastro da rotina 4000
      V_DADOS_TRIBUTACAO := GET_DADOS_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);

      --Calcula os novos impostos com base na tributação que foi encontrada
      V_DADOS_TRIBUTACAO := GET_CALCULAR_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);

      PKG_DEBUGGING_FWPC.LOG('Finailzando o processo de cálculo CBS com os seguintes dados:'||
                             ' Código Tributação: '||V_DADOS_TRIBUTACAO.CODIGO_TRIBUTACAO_CBSIBS||
                             ' Código da Base de Cálculo: '||V_DADOS_TRIBUTACAO.COD_FORMULA_BASE_CBSIBS||                                                          
                             ' CST: '||V_DADOS_TRIBUTACAO.CST_CBSIBS||
                             ' CClassTrib: '||V_DADOS_TRIBUTACAO.CCLASSTRIB_CBSIBS||
                             
                             ' Valor da base de cálculo: '||V_DADOS_TRIBUTACAO.VALOR_BASE_CBSIBS||
                             ' Aliquota CBS: '||V_DADOS_TRIBUTACAO.PERC_CBS||
                             ' Valor Cbs calculado: '||V_DADOS_TRIBUTACAO.VALOR_CBS||
                             
                             ' Perc IBS UF: '||V_DADOS_TRIBUTACAO.PERC_IBS_UF||
                             ' Perc Red IBS UF: '||V_DADOS_TRIBUTACAO.PERC_RED_ALIQ_IBS_UF||
                             ' Valor IBS UF calculado: '||V_DADOS_TRIBUTACAO.VALOR_IBS_UF||
                             
                             ' Perc IBS MUN: '||V_DADOS_TRIBUTACAO.PERC_IBS_MUN||
                             ' Perc Red IBS MUN: '||V_DADOS_TRIBUTACAO.PERC_RED_ALIQ_IBS_MUN||
                             ' Valor IBS MUN calculado: '||V_DADOS_TRIBUTACAO.VALOR_IBS_MUN                        
                             ,'S');



      PKG_DEBUGGING_FWPC.DESATIVARDEBUG;

      P_MSG := 'OK';

      RETURN(V_DADOS_TRIBUTACAO);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('Erro geral no processo de cálculo do CBS: '||SQLERRM,'S');
          P_MSG := 'ERRO';
          RETURN(V_DADOS_TRIBUTACAO);
        END;
    END;
  END CALCULAR_CBSIBS;


  FUNCTION CALCULAR_IS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                        P_MSG        out varchar2)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_DADOS_TRIBUTACAO TIPO_TRIBUT_REFORMA;
  BEGIN
    BEGIN
      PKG_DEBUGGING_FWPC.ATIVARDEBUG('CALCULAR_IS', '1.0');
      PKG_DEBUGGING_FWPC.LOG('Inicio cálculo IS para filial| '||P_PARAMETROS.CODFILIAL||
                             ' Produto: '||P_PARAMETROS.CODPROD||
                             ' Ncm:'||P_PARAMETROS.NCM,'S');


      V_DADOS_TRIBUTACAO                  := P_PARAMETROS;
      V_DADOS_TRIBUTACAO.TIPO_IMPOSTO     := 'IS';

      --Busca os dados do cliente ou fornecedor
      V_DADOS_TRIBUTACAO := GET_DADOS_CLIENTE_FORNECEDOR(V_DADOS_TRIBUTACAO);

      --Busca os dados do endereço de entrega do cliente
      V_DADOS_TRIBUTACAO := GET_DADOS_CLIENTE_END_ENTREGA(V_DADOS_TRIBUTACAO);

      --Busca os dados de cadastro da rotina 4000
      V_DADOS_TRIBUTACAO := GET_DADOS_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);

      --Calcula os novos impostos com base na tributação que foi encontrada
      V_DADOS_TRIBUTACAO := GET_CALCULAR_TRIBUTOS_REFORMA(V_DADOS_TRIBUTACAO);

      PKG_DEBUGGING_FWPC.LOG('Finailzando o processo de cálculo IS com os seguintes dados:'||
                             ' Código Tributação: '||V_DADOS_TRIBUTACAO.CODIGO_TRIBUTACAO_IS||
                             ' Código da Base de Cálculo: '||V_DADOS_TRIBUTACAO.COD_FORMULA_BASE_CALCULO_IS||
                             ' CST: '||V_DADOS_TRIBUTACAO.CST_IS||
                             ' CClassTrib: '||V_DADOS_TRIBUTACAO.CCLASSTRIB_IS||
                             ' Valor da base de cálculo: '||V_DADOS_TRIBUTACAO.VALOR_BASE_IS||
                             ' Aliquota: '||V_DADOS_TRIBUTACAO.PERC_IS||
                             ' IS calculado: '||V_DADOS_TRIBUTACAO.VALOR_IS
                             ,'S');

      PKG_DEBUGGING_FWPC.DESATIVARDEBUG;

      P_MSG := 'OK';

      RETURN(V_DADOS_TRIBUTACAO);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          PKG_DEBUGGING_FWPC.LOG('Erro geral no processo de cálculo do IS: '||SQLERRM,'S');

          P_MSG := 'ERRO';
          RETURN(V_DADOS_TRIBUTACAO);
        END;
    END;
  END CALCULAR_IS;



  FUNCTION CALCULAR_CBSIBS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                        P_USASUFIXO IN VARCHAR2,
                        P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_DADOS_TRIBUTACAO TIPO_TRIBUT_REFORMA;
  BEGIN
    V_DADOS_TRIBUTACAO := P_PARAMETROS;

    IF P_USASUFIXO = 'S' THEN
        V_DADOS_TRIBUTACAO.FORMULA_VALOR_TRIBUTO_CBSIBS := '(&BASE_CALCULO_CBS& * [ALIQUOTA_CBS] / 100)';
    END IF;

    V_DADOS_TRIBUTACAO := CALCULAR_CBSIBS(V_DADOS_TRIBUTACAO, P_MSG);
    RETURN V_DADOS_TRIBUTACAO;
  END CALCULAR_CBSIBS;


  FUNCTION CALCULAR_IS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                       P_USASUFIXO IN VARCHAR2,
                       P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA IS
    V_DADOS_TRIBUTACAO TIPO_TRIBUT_REFORMA;
  BEGIN
    V_DADOS_TRIBUTACAO := P_PARAMETROS;

    IF P_USASUFIXO = 'S' THEN
        V_DADOS_TRIBUTACAO.FORMULA_VALOR_TRIBUTO_IS := '(&BASE_CALCULO_IS& * [ALIQUOTA_IS] / 100)';
    END IF;

    V_DADOS_TRIBUTACAO := CALCULAR_IS(V_DADOS_TRIBUTACAO, P_MSG);
    RETURN V_DADOS_TRIBUTACAO;
  END CALCULAR_IS;


END;
-- Alteração 14/01/2025 - Implementação do nvl no campo CST da opçao /*CONSULTA DE NOTAS SEM ITENS*/ referente ao metodo GET_CPONTA_CONTABIL_SPED