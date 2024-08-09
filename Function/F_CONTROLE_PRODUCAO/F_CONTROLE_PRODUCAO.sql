CREATE OR REPLACE FUNCTION F_CONTROLE_PRODUCAO(PCODFILIAL               in varchar2,
                                               PDTINICIO                in date,
                                               PDTFIM                   in date,
                                               PDTINVENTARIO            in date default null,
                                               PTIPOCUSTO               in number default 0,     --
                                               PPROD_SEM_MOV            in varchar2 default 'N', -- 02 - Gerar itens sem movimentação.
                                               PUTILIZA_METODO_PEPS     in varchar2 default 'N', -- 
                                               PUTILIZA_PRECO_NOTA      in varchar2 default 'N', -- 05 - Utiliza o preço unitário do produto.
                                               PNUMCASAS_QT             in number default 3,
                                               PNUMCASAS_UNIT           in number default 6,
                                               PNUMCASAS_TOTAL          in number default 2,
                                               PUSOCONSUMO              in varchar default  'S', -- 07 - Desconsiderar item de consumo
                                               PATIVIOMOBULIZADO        in varchar default  'S', -- 06 - Desconsiderar item de imobilizado
                                               PGERACANCPRODUCAO        in varchar default  'N', -- 09 - - Considerar produção cancelada
                                               PGERACODOPERSMKARDEX     in varchar default  'N',
                                               PCODPROD1                in number default 0,
                                               PCODPROD2                in number default 9999999999,
                                               PVENDAMANIF_COMTV14      in varchar2 default 'N', -- 16
                                               PGERA_SM_KARDEX_CANC     in varchar default  'N', --
                                               PGERA_NF_ENTRADA_CANC    in varchar default  'N', -- 14 - Considerar nfs canceladas
                                               PGERA_NF_SAIDA_CANC      in varchar default  'N', -- 15 - Considerar nfs canceladas
                                               PDESC_NF_TRANSF_DEP      in varchar default  'N', -- 17
                                               PUTILIZA_PROCEDURE       in varchar2 default 'N', -- 24 - Desconsidera função e executar procedure
                                               PDESCONSIDERANFEDENEGADA in varchar default  'N', -- 18 - Desconsiderar nfe denegada
                                               PMOSTRARAJUSTESCUSTO     in varchar default  'N', -- Desativado para alterações manuais. Default S
                                               PORDENAR_PCMOVLOG        in varchar default  'N', -- Desativado para alterações manuais. Default N
                                               PGERA_NUMOP_NA_OBS       in varchar2 default 'N', -- 10.2 - (S) Exibe no campo OBS a número da Operação correspondente ao lançamento.
                                               PCONSIDERARCUSTOBONIF    in varchar2 default 'N', -- 20 - (S) Considera o custo registrado na NF de bonificação.
                                               PDESCONS_CUSTO_DEVCLI    in varchar2 default 'N', -- 21 - (S) Descons.o custo da NF de entrada devolução de cliente e mantem o custo anterior.
                                               PDESCONS_ENT_AJUSTE_ER   in varchar2 default 'N', -- 23 - (S)Excluí o lançamento CODOPER = ER (Ajuste de saída consignada rot 1437)
                                               PDESCONS_CUSTO_NFENTCANC in varchar2 default 'N', -- 22 - (S) Descons.o custo da NF de entrada cancelada e mantem o custo anterior.
                                               PDESCONS_ITEM_BRINDE     in varchar2 default 'S', -- 08 - (S) Descons.o item do Estoque/Movimentação(NFs) com a informação TIPOMERC = BD.
                                               PCONS_CUSTO_ZERO         in varchar2 default 'N', -- 26 - (S) Considera no estoque e movimentação entrada com custo zero. (N) mantém o custo anterior
                                               PSTATUSPROD              in varchar2 default 'T'  -- 27 - Status do Produto DTEXCLUSAO - T - Todos / A - Ativo / I - Inativo
                                               )
---------------------------------------------------------------------------------
  -- Função para retorno de movimentação de controle de produção
  ---------------------------------------------------------------------------------
  -- Criado por: RICARDO em 25/10/2011

  -- Será utilizada para:
  -- Rotina 1070 - Controle de Produção
  -- Módulo contábil (para demonstrar o custo diário)
  ---------------------------------------------------------------------------------
  /*
  INDICE DO PARAMETRO "PTIPOCUSTO"
  0 : CUSTOCONT
  1 : CUSTOREAL
  2 : CUSTOREALSEMST
  3 : CUSTOFIN
  4 : CUSTOREP
  5 : CUSTOULTENT
  6 : VALORULTENT
  7 : CUSTOFISCAL
  8 : CUSTOULTENTCONT
  */

  return TABELA_CONTROLE_PRODUCAO
  parallel_enable
  pipelined is

  OUTROW TIPO_CONTROLE_PRODUCAO := TIPO_CONTROLE_PRODUCAO(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                                          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL ); -- 78 colunas
  --V_RETORNO                      TABELA_CONTROLE_PRODUCAO;
  V_CUSTOTOTAL                   number(22, 6);
  V_CUSTOMEDIO                   number(22, 6);
  V_CUSTOTOTALENTRADA            number(22, 6);
  V_CUSTOSAIDA                   number(22, 6);
  V_CUSTOTOTALSAIDA              number(22, 6);
  V_SALDOQT                      number(22, 6);
  V_CUSTOTOTAL_ANTERIOR          number(22, 6);
  V_CUSTOMEDIO_ANTERIOR          number(22, 6);
  V_BASECUSTOCONT                number(22, 6);
  V_SALDOQT_ANTERIOR             number(22, 6);
  V_CUSTOUTILIZAR                number(22, 6);
  V_CODPROD                      PCPRODUT.CODPROD%type;
  V_INFORMACAO                   varchar2(50);
  V_DATA_INVENTARIO              date;
  V_UTILIZA_PROCEDURE            varchar2(1);  
  -- PARAMETROS FRETE FOB -------------------
  V_FIL_CALCREDPISFRETECONT      varchar2(1);
  V_UTICREDICMSFRETEFOBCUSTOCONT varchar2(1);
  V_CALCREDPISCOFINSSERVICOCONT  varchar2(1);
  -------------------------------------------
  V_UTILIZA_CUSTO_ULTIMA_ENTRADA boolean;
  -------------------------------------------
  --V_DATA_CANCELAMENTO_FIM DATE;

  function CODOPER_ALTERA_CUSTO(PCODOPER in varchar2,
                                PDTCANCEL in date) return boolean is
  BEGIN
    if (PCODOPER = 'ED') then
      if (PDESCONS_CUSTO_DEVCLI = 'S') then
          return false; -- Retorna Falso.
      else
          return true; -- Retorna Falso
      end if;
    -- QUALQUER ENTRADA CANCELADA
    elsif (PCODOPER LIKE 'E%' AND PDTCANCEL IS NOT NULL) then
      if (PDESCONS_CUSTO_NFENTCANC = 'S') then
           return false; -- Retorna Verdadeiro
        else
           return true;
      end if;
    -- NF DE BONICAÇÃO
    elsif  (PCODOPER = 'EB') then
      if (PCONSIDERARCUSTOBONIF = 'S') then
           return true
 ; -- Retorna Verdadeiro
        else
           return false;
      end if;
    -- NF DE SAIDA
    elsif (PCODOPER like 'S%') then -- Se movimentação de saída não altera o custo
      return False;
    else
      return true;
    end if;
  END;

  -----------------------------------------------------------------------------------------------------

  function CODOPER_ALTERA_CUSTO_ESTOQUE(PCODOPER in varchar2,
                                        PDTCANCEL in date) return boolean is
  BEGIN
    if (PCODOPER = 'ED') then
      if (PDESCONS_CUSTO_DEVCLI = 'S') then
          return false; -- Retorna Falso.
      else
          return true; -- Retorna Falso
      end if;
    -- QUALQUER ENTRADA CANCELADA
    elsif (PCODOPER LIKE 'E%' AND PDTCANCEL IS NOT NULL) then
      if (PDESCONS_CUSTO_NFENTCANC = 'S') then
           return false; -- Retorna Verdadeiro
        else
           return true;
      end if;
    --
    elsif  (PCODOPER = 'EB') then
      if (PCONSIDERARCUSTOBONIF = 'S') then
           return true; -- Retorna Verdadeiro
        else
           return false;
      end if;

    elsif (PCODOPER like 'S%') then -- Se movimentação de saída não altera o custo
      return False;
    else
      return true;
    end if;
  END;

  -----------------------------------------------------------------------------------------------------
  function GET_CUSTOMEDIO_PEPS(PNUMTRANSVENDA         in number,
                               PCODPROD               in number,
                               PDATAMOV               in date,
                               PBUSCAR_CUSTO_ANTERIOR in varchar2,
                               PVLCUSTO               in out number)
    return boolean is
  BEGIN
    BEGIN
      SELECT ROUND(case PTIPOCUSTO
                     when 0 then
                      max(M.CUSTOCONT)
                     when 1 then
                      max(M.CUSTOREAL)
                     when 2 then
                      max(M.CUSTOREALSEMST)
                     when 3 then
                      max(M.CUSTOREP)
                     when 4 then
                      max(MC.CUSTOFISCAL)
                   END,
                   PNUMCASAS_UNIT)
        INTO PVLCUSTO
        FROM PCMOVSAID MS, PCMOV M, PCMOVCOMPLE MC 
       WHERE ((PBUSCAR_CUSTO_ANTERIOR = 'N' AND
             MS.NUMTRANSVENDA = PNUMTRANSVENDA) or
             (MS.NUMTRANSVENDA =
             (SELECT max(MS2.NUMTRANSVENDA)
              FROM PCMOVSAID MS2
              WHERE MS2.DATA <= PDATAMOV
               AND MS2.CODPROD = PCODPROD)))
         AND MS.CODPROD = PCODPROD
         AND M.NUMTRANSENT = MS.NUMTRANSENT
         AND M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
         AND M.CODPROD = MS.CODPROD;

      return true;
    EXCEPTION
      when others then
        return false;
    END;
  END;
  -----------------------------------------------------------------------------------------------------
  function GET_CUSTOMEDIO_ESTOQUE(PCODOPER    in varchar2,
                                  PNOVOCUSTO  in number,
                                  PCUSTOATUAL in number,
                                  PQTMOV      in number,
                                  PSALDOQT    in out number,
                                  PCUSTOTOTAL in out number,
                                  PDTCANCEL in Date)
                                  return number is
    V_CUSTO number;
  BEGIN
    if SUBSTR(PCODOPER, 1, 1) = 'E'
    then
      PSALDOQT := NVL(PSALDOQT, 0) + ROUND(NVL(PQTMOV, 0), PNUMCASAS_QT);
    else
      PSALDOQT := NVL(PSALDOQT, 0) - ROUND(NVL(PQTMOV, 0), PNUMCASAS_QT);
    END if;

    if ((PNOVOCUSTO > 0) or 
        (PCODOPER = 'EB') or 
        (PCONS_CUSTO_ZERO = 'S')) 
        and (CODOPER_ALTERA_CUSTO_ESTOQUE(PCODOPER,PDTCANCEL))
    then
      V_CUSTO := ROUND(PNOVOCUSTO, PNUMCASAS_UNIT);
    else
      V_CUSTO := ROUND(PCUSTOATUAL, PNUMCASAS_UNIT);
    END if;

    PCUSTOTOTAL := ROUND(PSALDOQT * V_CUSTO, PNUMCASAS_TOTAL);
    return V_CUSTO;
  END;
  -----------------------------------------------------------------------------------------------------
BEGIN
  -- Inicio --
  if PDTINVENTARIO is not null
  then
    BEGIN
      SELECT DATA
        INTO V_DATA_INVENTARIO
        FROM PCHISTEST
       WHERE CODFILIAL = PCODFILIAL
         AND DATA = PDTINVENTARIO
         AND ROWNUM = 1;
    EXCEPTION
      when NO_DATA_FOUND then
        BEGIN
          SELECT max(DATA)
            INTO V_DATA_INVENTARIO
            FROM PCHISTEST
           WHERE CODFILIAL = PCODFILIAL
             AND DATA <= V_DATA_INVENTARIO;
        EXCEPTION
          when others then
            V_DATA_INVENTARIO := PDTINVENTARIO;
        END;
      when others then
        V_DATA_INVENTARIO := PDTINVENTARIO;
    END;
  ELSE
    BEGIN
   V_DATA_INVENTARIO := PDTINICIO -1;
  EXCEPTION
      when others then
        V_DATA_INVENTARIO := null;
    END;
  END IF;

  -- PREENCHENDO PARAMETROS FRETEFROB.
  V_FIL_CALCREDPISFRETECONT := paramfilial.obtercomovarchar2('FIL_CALCREDPISFRETECONT', PCODFILIAL);
  V_UTILIZA_PROCEDURE := PUTILIZA_PROCEDURE;
  -----------------------------------------------------------------------------------------------------

  if PMOSTRARAJUSTESCUSTO = 'S' then
    BEGIN
     SELECT P.VALOR
          INTO V_UTICREDICMSFRETEFOBCUSTOCONT
       FROM PCPARAMFILIAL P
      WHERE P.NOME = 'UTICREDICMSFRETEFOBCUSTOCONT'
        AND P.CODFILIAL = PCODFILIAL;
    EXCEPTION
      when others then
        V_UTICREDICMSFRETEFOBCUSTOCONT := null;
    END;
  end if;
  -----------------------------------------------------------------------------------------------------
  -- PREENCHENDO PARAMETROS NS(SERVIÇO)
  V_CALCREDPISCOFINSSERVICOCONT  := paramfilial.obtercomovarchar2('CALCREDPISCOFINSSERVICOCONT',PCODFILIAL);
  ------------------------------------ Utilizando Procedure ------------------------------------------
  IF V_UTILIZA_PROCEDURE = 'N'
  THEN
    V_CODPROD := -1;
    FOR DADOS IN (SELECT MOV.TIPO,MOV.SEQMOV,MOV.NUMTRANSENT,MOV.NUMTRANSVENDA,MOV.ESPECIE,MOV.SERIE,MOV.CODCONT,MOV.OBSERVACAO,
                         ESTOQUE.DESCRICAO,ESTOQUE.EMBALAGEM,ESTOQUE.UNIDADE,ESTOQUE.CODPROD,ESTOQUE.CODEPTO,ESTOQUE.CODSEC,
                         ESTOQUE.TIPOMERC,MOV.CODOPER,MOV.NUMNOTA,NVL(MOV.DATA,ESTOQUE.DATA) DATA,MOV.CODFISCAL,MOV.QTCONT,
                         MOV.QTENTRADA,MOV.QTSAIDA,MOV.QTSAIDA_DENTRO,MOV.QTSAIDA_FORA,MOV.PUNITCONT,MOV.VALORITEMNOTA_ENT,
                         MOV.VALORITEMNOTA_SAID,MOV.VLIPI,MOV.ST,MOV.STGUIA,MOV.CUSTOCONT,MOV.CUSTOREP,MOV.CUSTOREAL,
                         MOV.CUSTOREALSEMST,MOV.CUSTOFIN,MOV.CUSTOULTENT,MOV.ROTINACAD,MOV.VALORULTENT,MOV.BASECUSTOCONT,
                         ESTOQUE.QTEST QT_ESTOQUE,ESTOQUE.CUSTOCONT CUSTOCONT_ESTOQUE,ESTOQUE.CUSTOULTENT CUSTOULTENT_ESTOQUE,ESTOQUE.CUSTOULTENTCONT CUSTOULTENTCONT_ESTOQUE,
                         ESTOQUE.CUSTOREP CUSTOREP_ESTOQUE,ESTOQUE.CUSTOFIN CUSTOFIN_ESTOQUE,
                         ESTOQUE.CUSTOREAL CUSTOREAL_ESTOQUE,ESTOQUE.CUSTOREALSEMST CUSTOREALSEMST_ESTOQUE,
                         ESTOQUE.VALORULTENT VALORULTENT_ESTOQUE,MOV.HISTORICO,MOV.DTCANCEL,
                         MOV.SITUACAOTRIBUTARIA,MOV.TIPODESCARGA,MOV.MINUTOLANC,MOV.HORALANC,MOV.NCM,MOV.POSSE
                        ,MOV.DTMOVLOG, ESTOQUE.CUSTOFISCAL CUSTOFISCAL_ESTOQUE, MOV.CUSTOFISCAL, MOV.CUSTOULTENTCONT
                   FROM (SELECT TIPO,SEQMOV,BASECUSTOCONT,CUSTOCONT,CUSTOFIN,CUSTOREAL,CUSTOREP,CUSTOULTENT
                               ,CUSTOREALSEMST,VALORULTENT,ESPECIE,SERIE,CODCONT,OBSERVACAO,CODPROD,CODOPER
                               ,NUMNOTA,DATA,HORALANC,CODFISCAL,QTCONT,QTENTRADA,QTSAIDA,QTSAIDA_DENTRO
                               ,QTSAIDA_FORA,HISTORICO,PUNITCONT,VALORITEMNOTA_ENT,VALORITEMNOTA_SAID,NUMTRANSENT
                               ,NUMTRANSVENDA,VLIPI,ST,STGUIA,DTCANCEL,SITUACAOTRIBUTARIA,TIPODESCARGA,MINUTOLANC
                               ,ROTINACAD,NCM,POSSE,DTMOVLOG, CUSTOFISCAL,CUSTOULTENTCONT
                          FROM TABLE (F_CONTROLE_PRODUCAO_MOV(PCODFILIAL,
                                                              PDTINICIO,
                                                              PDTFIM,
                                                              PDTINVENTARIO,
                                                              PTIPOCUSTO,
                                                              PPROD_SEM_MOV,
                                                              PUTILIZA_METODO_PEPS,
                                                              PUTILIZA_PRECO_NOTA,
                                                              PNUMCASAS_QT,
                                                              PNUMCASAS_UNIT,
                                                              PNUMCASAS_TOTAL,
                                                              PUSOCONSUMO,
                                                              PATIVIOMOBULIZADO,
                                                              PGERACANCPRODUCAO,
                                                              PGERACODOPERSMKARDEX,
                                                              PCODPROD1,
                                                              PCODPROD2,
                                                              PVENDAMANIF_COMTV14,
                                                              PGERA_SM_KARDEX_CANC,
                                                              PGERA_NF_ENTRADA_CANC,
                                                              PGERA_NF_SAIDA_CANC,
                                                              PDESC_NF_TRANSF_DEP,
                                                              PUTILIZA_PROCEDURE,
                                                              PDESCONSIDERANFEDENEGADA,
                                                              PMOSTRARAJUSTESCUSTO,
                                                              PORDENAR_PCMOVLOG,
                                                              PGERA_NUMOP_NA_OBS,
                                                              PCONSIDERARCUSTOBONIF,
                                                              PDESCONS_CUSTO_DEVCLI,
                                                              PDESCONS_ENT_AJUSTE_ER,
                                                              PDESCONS_CUSTO_NFENTCANC,
                                                              PDESCONS_ITEM_BRINDE,
                                                              PSTATUSPROD
                                                              ))
                           WHERE DATA BETWEEN PDTINICIO AND PDTFIM) MOV,
                                 (SELECT PCPRODUT.CODPROD,
                                         PCPRODUT.DESCRICAO,
                                         PCPRODUT.EMBALAGEM,
                                         PCPRODUT.UNIDADE,
                                         PCPRODUT.CODEPTO,
                                         PCPRODUT.CODSEC,
                                         HISTEST.TIPOMERC,
                                         DECODE(NVL(PCPRODUT.COMODATO,'N'), 'S', 2, 0) POSSE,
                                         NVL(HISTEST.QTEST,0) QTEST,
                                         NVL(HISTEST.CUSTOCONT, 0) CUSTOCONT,
                                         NVL(HISTEST.CUSTOREAL, 0) CUSTOREAL,
                                         NVL(HISTEST.CUSTOREALSEMST, 0) CUSTOREALSEMST,
                                         NVL(HISTEST.CUSTOFIN, 0) CUSTOFIN,
                                         NVL(HISTEST.CUSTOREP, 0) CUSTOREP,
                                         NVL(HISTEST.CUSTOULTENT, 0) CUSTOULTENT,
                                         NVL(HISTEST.VALORULTENT, 0) VALORULTENT,
                                         NVL(HISTEST.CUSTOFISCAL, 0) CUSTOFISCAL,
                                         NVL(HISTEST.CUSTOULTENTCONT, 0) CUSTOULTENTCONT,
                                         HISTEST.DATA
                                  FROM (SELECT CODPROD,
                                               QTEST,
                                               DATA,
                                               QTTRANSITO,
                                               CUSTOCONT,
                                               CUSTOREAL,
                                               CUSTOFIN,
                                               CUSTOREP,
                                               CUSTOREALSEMST,
                                               CUSTOULTENT,
                                               VALORULTENT,
                                               TIPOMERC, 
                                               CUSTOFISCAL,
                                               CUSTOULTENTCONT
                                        FROM PCHISTEST
                                        WHERE DATA      = V_DATA_INVENTARIO
                                          AND CODFILIAL = PCODFILIAL
                                          AND CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                          AND DECODE(PUSOCONSUMO,      'N',NVL(PCHISTEST.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                          AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCHISTEST.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                          AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCHISTEST.TIPOMERC, 'X'),'XX') <> 'BD'
                                          AND (CASE
                                                   WHEN PSTATUSPROD = 'T'
                                                      THEN 1
                                                   WHEN PSTATUSPROD = 'A' AND PCHISTEST.DTEXCLUSAOPROD IS NULL
                                                      THEN 1
                                                   WHEN PSTATUSPROD = 'I' AND PCHISTEST.DTEXCLUSAOPROD IS NOT NULL
                                                      THEN 1
                                                   ELSE 0
                                               END = 1)                                                 
                                          ) HISTEST,
                                             PCPRODUT
                                        WHERE PCPRODUT.CODPROD = HISTEST.CODPROD(+)
                                          AND PCPRODUT.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                          AND NVL(PCPRODUT.TIPOMERC, 'X') <> 'SS'
                                          ) ESTOQUE
          
                                  WHERE ESTOQUE.CODPROD = MOV.CODPROD(+)
                                    AND (PPROD_SEM_MOV = 'S' or MOV.CODPROD > 0)
                                  ORDER BY CODPROD, DTMOVLOG, DATA, SEQMOV, TIPO, NUMNOTA)
          LOOP

            V_BASECUSTOCONT     := 0;
            V_CUSTOTOTALENTRADA := 0;
            V_CUSTOSAIDA        := 0;
            V_CUSTOTOTALSAIDA   := 0;

            -- Inicializar valores na mudança do produto
            if V_CODPROD <> DADOS.CODPROD
            then
              V_UTILIZA_CUSTO_ULTIMA_ENTRADA := true;
              -- Momento de busca do custo pelo PEPS
              if (PUTILIZA_METODO_PEPS = 'S')
              then
                if not GET_CUSTOMEDIO_PEPS(DADOS.NUMTRANSVENDA,
                                           DADOS.CODPROD,
                                           DADOS.DATA,
                                           case when SUBSTR(DADOS.CODOPER, 1, 1) = 'S' then 'N' else 'S' END,
                                           V_CUSTOMEDIO /* OUT */)
                then
                  V_UTILIZA_CUSTO_ULTIMA_ENTRADA := true;
                END if;
              END if;

              if (V_UTILIZA_CUSTO_ULTIMA_ENTRADA) or 
                 (NVL(V_CUSTOMEDIO, 0) = 0)
              then
                case PTIPOCUSTO
                  when 0 then
                    V_CUSTOMEDIO := DADOS.CUSTOCONT_ESTOQUE;
                  when 1 then
                    V_CUSTOMEDIO := DADOS.CUSTOREAL_ESTOQUE;
                  when 2 then
                    V_CUSTOMEDIO := DADOS.CUSTOREALSEMST_ESTOQUE;
                  when 3 then
                    V_CUSTOMEDIO := DADOS.CUSTOFIN_ESTOQUE;
                  when 4 then
                    V_CUSTOMEDIO := DADOS.CUSTOREP_ESTOQUE;
                  when 5 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENT_ESTOQUE;
                  when 6 then
                    V_CUSTOMEDIO := DADOS.VALORULTENT_ESTOQUE;
                  when 7 then
                    V_CUSTOMEDIO := DADOS.CUSTOFISCAL_ESTOQUE;
                  when 8 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENTCONT_ESTOQUE;  
                END case; END if;

              if V_CUSTOMEDIO <= 0
              then
                case PTIPOCUSTO
                  when 0 then
                    V_CUSTOMEDIO := DADOS.CUSTOCONT;
                  when 1 then
                    V_CUSTOMEDIO := DADOS.CUSTOREAL;
                  when 2 then
                    V_CUSTOMEDIO := DADOS.CUSTOREALSEMST;
                  when 3 then
                    V_CUSTOMEDIO := DADOS.CUSTOFIN;
                  when 4 then
                    V_CUSTOMEDIO := DADOS.CUSTOREP;
                  when 5 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENT;
                  when 6 then
                    V_CUSTOMEDIO := DADOS.VALORULTENT;
                  when 7 then
                    V_CUSTOMEDIO := DADOS.CUSTOFISCAL;
                  when 8 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENTCONT;  
                END case; END if;
                
              V_CUSTOMEDIO := ROUND(V_CUSTOMEDIO, PNUMCASAS_UNIT);
              V_SALDOQT    := ROUND(DADOS.QT_ESTOQUE, PNUMCASAS_QT);

              V_CUSTOTOTAL := ROUND(V_SALDOQT * V_CUSTOMEDIO, PNUMCASAS_TOTAL);

              V_SALDOQT_ANTERIOR    := V_SALDOQT;
              V_CUSTOMEDIO_ANTERIOR := V_CUSTOMEDIO;
              V_CUSTOTOTAL_ANTERIOR := V_CUSTOTOTAL;

              -- Gravar codigo do produto atual
              V_CODPROD := DADOS.CODPROD;
            END if;

            if (DADOS.ESPECIE is null and DADOS.SERIE <> 'SM') 
            then
              V_INFORMACAO := 'PRODUTO SEM MOVIMENTAÇÃO';
            else
              V_INFORMACAO := RPAD(' ', 50);

              -- Controlar entrada de produção
              if DADOS.CODOPER like 'E%'
              then
                case PTIPOCUSTO
                  when 0 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOCONT;
                  when 1 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOREAL;
                  when 2 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOREALSEMST;
                  when 3 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOFIN;
                  when 4 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOREP;
                  when 5 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOULTENT;
                  when 6 then
                    V_CUSTOUTILIZAR := DADOS.VALORULTENT;
                  when 7 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOFISCAL;
                  when 8 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOULTENTCONT;  
                END case;              

                case PTIPOCUSTO
                  when 0 then
                    V_BASECUSTOCONT := NVL(DADOS.BASECUSTOCONT, 0);
                  when 1 then
                    V_BASECUSTOCONT := NVL(DADOS.CUSTOULTENT, 0);
                  when 2 then
                    V_BASECUSTOCONT := GREATEST(NVL(DADOS.CUSTOULTENT, 0) -
                                                NVL(DADOS.ST, 0) - NVL(DADOS.STGUIA, 0),
                                                0);
                  else
                    V_BASECUSTOCONT := DADOS.BASECUSTOCONT;
                END case;

                V_CUSTOMEDIO := GET_CUSTOMEDIO_ESTOQUE(DADOS.CODOPER,
                                                       V_CUSTOUTILIZAR,
                                                       V_CUSTOMEDIO,
                                                       DADOS.QTCONT,
                                                       V_SALDOQT,
                                                       V_CUSTOTOTAL,
                                                       DADOS.DTCANCEL);

                if not CODOPER_ALTERA_CUSTO(DADOS.CODOPER, DADOS.DTCANCEL)
                then
                  V_BASECUSTOCONT := V_CUSTOMEDIO;
                END if;

                if PUTILIZA_PRECO_NOTA = 'S'
                then
                  V_BASECUSTOCONT := DADOS.VALORITEMNOTA_ENT;
                END if;

                V_BASECUSTOCONT     := ROUND(V_BASECUSTOCONT, PNUMCASAS_UNIT);
                V_CUSTOTOTALENTRADA := ROUND(ROUND(DADOS.QTENTRADA, PNUMCASAS_QT) *
                                             V_BASECUSTOCONT,
                                             PNUMCASAS_TOTAL);

                IF (DADOS.TIPO = 'EF') OR (DADOS.TIPO = 'EP') OR (DADOS.TIPO = 'ES') THEN
                  V_SALDOQT    := (NVL(V_SALDOQT, 0) - NVL(DADOS.QTCONT, 0));
                  V_CUSTOTOTAL := ROUND(V_SALDOQT * V_CUSTOMEDIO, PNUMCASAS_TOTAL);
                END IF;
                
              else
                -- Controlar saída de produção
                -- Momento de busca do custo pelo PEPS
                if (PUTILIZA_METODO_PEPS = 'S') AND (DADOS.CODOPER like 'S%')
                then
                  V_UTILIZA_CUSTO_ULTIMA_ENTRADA := not
                                                     GET_CUSTOMEDIO_PEPS(DADOS.NUMTRANSVENDA,
                                                                         DADOS.CODPROD,
                                                                         DADOS.DATA,
                                                                         'N',
                                                                         V_CUSTOMEDIO
                                                                         /* OUT */);
                END if;

                V_CUSTOMEDIO := GET_CUSTOMEDIO_ESTOQUE(DADOS.CODOPER,
                                                       V_CUSTOMEDIO,
                                                       V_CUSTOMEDIO,
                                                       DADOS.QTCONT,
                                                       V_SALDOQT,
                                                       V_CUSTOTOTAL,
                                                       DADOS.DTCANCEL);

                V_CUSTOSAIDA := V_CUSTOMEDIO;

                if PUTILIZA_PRECO_NOTA = 'S'
                then
                  V_CUSTOSAIDA := DADOS.VALORITEMNOTA_SAID;
                END if;

                -- Se quantidade de saída zero, custo de saída recebe zero.
                if dados.qtsaida = 0 then
                   V_CUSTOSAIDA      := 0;
                  end if;

                V_CUSTOSAIDA      := ROUND(V_CUSTOSAIDA, PNUMCASAS_UNIT);
                V_CUSTOTOTALSAIDA := ROUND(ROUND(DADOS.QTSAIDA, PNUMCASAS_QT) *
                                           V_CUSTOSAIDA,
                                           PNUMCASAS_TOTAL);
              END if;
            END if;


            --    V_RETORNO.extEND;
            --    V_RETORNO(V_RETORNO.count) := TIPO_CONTROLE_PRODUCAO( -- MOVIMENTAÇÃO
            OUTROW.CODFILIAL      := SUBSTR(PCODFILIAL,0,2);
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.INFORMACAO     := SUBSTR(V_INFORMACAO,0,1000);
            OUTROW.NUMTRANSENT    := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA  := DADOS.NUMTRANSVENDA;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.DESCRICAO      := SUBSTR(DADOS.DESCRICAO,0,100);
            OUTROW.EMBALAGEM      := SUBSTR(DADOS.EMBALAGEM,0,50);
            OUTROW.UNIDADE        := SUBSTR(DADOS.UNIDADE,0,2);
            OUTROW.TIPOMERC       := SUBSTR(DADOS.TIPOMERC,0,2);
            OUTROW.CODSEC         := DADOS.CODSEC;
            OUTROW.CODEPTO        := DADOS.CODEPTO;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VLIPI          := DADOS.VLIPI;
            -- VALORES ENTRADA (RELATÓRIO PRODUÇÃO)
            OUTROW.QTENTRADA          := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.BASECUSTOCONT      := V_BASECUSTOCONT;
            OUTROW.CUSTOTOTAL_ENTRADA := V_CUSTOTOTALENTRADA;
            -- VALORES SAÍDA (RELATÓRIO PRODUÇÃO)
            OUTROW.QTSAIDA          := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.CUSTOCONTSAIDA   := V_CUSTOSAIDA;
            OUTROW.CUSTOTOTAL_SAIDA := V_CUSTOTOTALSAIDA;
            -- CUSTOS ESTOQUE
            OUTROW.CUSTOCONT_ESTOQUE      := DADOS.CUSTOCONT_ESTOQUE;
            OUTROW.CUSTOULTENT_ESTOQUE    := DADOS.CUSTOULTENT_ESTOQUE;
            OUTROW.CUSTOREP_ESTOQUE       := DADOS.CUSTOREP;
            OUTROW.CUSTOFIN_ESTOQUE       := DADOS.CUSTOFIN_ESTOQUE;
            OUTROW.CUSTOREAL_ESTOQUE      := DADOS.CUSTOREAL_ESTOQUE;
            OUTROW.CUSTOREALSEMST_ESTOQUE := DADOS.CUSTOREALSEMST_ESTOQUE;
            OUTROW.VALORULTENT_ESTOQUE    := DADOS.VALORULTENT_ESTOQUE;
            -- CUSTO ANTERIOR
            OUTROW.SALDOQT_ANTERIOR    := V_SALDOQT_ANTERIOR;
            OUTROW.CUSTOMEDIO_ANTERIOR := V_CUSTOMEDIO_ANTERIOR;
            OUTROW.CUSTOTOTAL_ANTERIOR := V_CUSTOTOTAL_ANTERIOR;
            -- CUSTO ATUAL
            OUTROW.SALDOQT_ATUAL    := V_SALDOQT;
            OUTROW.CUSTOMEDIO_ATUAL := V_CUSTOMEDIO;
            OUTROW.CUSTOTOTAL_ATUAL := V_CUSTOTOTAL;
            OUTROW.DTCANCEL         := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.ST            := DADOS.ST;
            OUTROW.MINUTOLANC    := DADOS.MINUTOLANC;
            OUTROW.HORALANC      := DADOS.HORALANC;
            OUTROW.SEQMOV        := DADOS.SEQMOV;
            OUTROW.ROTINACAD     := DADOS.ROTINACAD;
            OUTROW.NCM           := DADOS.NCM;
            OUTROW.POSSE         := DADOS.POSSE;
            OUTROW.DTMOVLOG      := DADOS.DTMOVLOG;
            
            pipe row(OUTROW);
          END LOOP;
 END IF;

  ------------------------------------ Utilizando Procedure ------------------------------------------
  IF PUTILIZA_PROCEDURE = 'S'
  THEN
    PRC_CONTROLE_PRODUCAO(PCODFILIAL,
                          PDTINICIO,
                          PDTFIM,
                          PDTINVENTARIO,
                          PTIPOCUSTO,
                          PPROD_SEM_MOV,
                          PUTILIZA_METODO_PEPS,
                          PUTILIZA_PRECO_NOTA,
                          PNUMCASAS_QT,
                          PNUMCASAS_UNIT,
                          PNUMCASAS_TOTAL,
                          PUSOCONSUMO,
                          PATIVIOMOBULIZADO,
                          PGERACANCPRODUCAO,
                          PGERACODOPERSMKARDEX,
                          PCODPROD1,
                          PCODPROD2,
                          PVENDAMANIF_COMTV14,
                          PGERA_SM_KARDEX_CANC,
                          PGERA_NF_ENTRADA_CANC,
                          PGERA_NF_SAIDA_CANC,
                          PDESC_NF_TRANSF_DEP,
                          PDESCONSIDERANFEDENEGADA,
                          PMOSTRARAJUSTESCUSTO,
                          PUTILIZA_PROCEDURE,
                          V_FIL_CALCREDPISFRETECONT,
                          V_UTICREDICMSFRETEFOBCUSTOCONT,
                          V_CALCREDPISCOFINSSERVICOCONT,
                          PGERA_NUMOP_NA_OBS,
                          PCONSIDERARCUSTOBONIF,
                          PDESCONS_CUSTO_DEVCLI,
                          PDESCONS_CUSTO_NFENTCANC,
                          PDESCONS_ENT_AJUSTE_ER,
                          PDESCONS_ITEM_BRINDE,
                          PSTATUSPROD
                          );

          V_CODPROD := -1;
          FOR DADOS IN (SELECT MOV.TIPO,
                               MOV.SEQMOV,
                               MOV.NUMTRANSENT,
                               MOV.NUMTRANSVENDA,
                               MOV.ESPECIE,
                               MOV.SERIE,
                               MOV.CODCONT,
                               MOV.OBSERVACAO,
                               ESTOQUE.DESCRICAO,
                               ESTOQUE.EMBALAGEM,
                               ESTOQUE.UNIDADE,
                               ESTOQUE.CODPROD,
                               ESTOQUE.CODEPTO,
                               ESTOQUE.CODSEC,
                               ESTOQUE.TIPOMERC,
                               MOV.CODOPER,
                               MOV.NUMNOTA,
                               --MOV.DATA,
                               NVL(MOV.DATA,ESTOQUE.DATA) DATA,
                               MOV.CODFISCAL,
                               MOV.QTCONT,
                               MOV.QTENTRADA,
                               MOV.QTSAIDA,
                               MOV.QTSAIDA_DENTRO,
                               MOV.QTSAIDA_FORA,
                               MOV.PUNITCONT,
                               MOV.VALORITEMNOTA_ENT,
                               MOV.VALORITEMNOTA_SAID,
                               MOV.VLIPI,
                               MOV.ST,
                               MOV.STGUIA,
                               MOV.CUSTOCONT,
                               MOV.CUSTOREP,
                               MOV.CUSTOREAL,
                               MOV.CUSTOREALSEMST,
                               MOV.CUSTOFIN,
                               MOV.CUSTOULTENT,
                               MOV.CUSTOULTENTCONT,
                               MOV.ROTINACAD,
                               MOV.VALORULTENT,
                               MOV.BASECUSTOCONT,
                               ESTOQUE.QTEST QT_ESTOQUE,
                               ESTOQUE.CUSTOCONT CUSTOCONT_ESTOQUE,
                               ESTOQUE.CUSTOULTENT CUSTOULTENT_ESTOQUE,
                               ESTOQUE.CUSTOULTENTCONT CUSTOULTENTCONT_ESTOQUE,
                               ESTOQUE.CUSTOREP CUSTOREP_ESTOQUE,
                               ESTOQUE.CUSTOFIN CUSTOFIN_ESTOQUE,
                               ESTOQUE.CUSTOREAL CUSTOREAL_ESTOQUE,
                               ESTOQUE.CUSTOREALSEMST CUSTOREALSEMST_ESTOQUE,
                               ESTOQUE.VALORULTENT VALORULTENT_ESTOQUE,
                               MOV.HISTORICO,
                               MOV.DTCANCEL,
                               MOV.SITUACAOTRIBUTARIA,
                               MOV.TIPODESCARGA,
                               MOV.MINUTOLANC,
                               MOV.HORALANC,
                               MOV.NCM, -- NÃO EXIBE NENHUMA INFORMAÇÃO
                               MOV.POSSE,-- NÃO EXIBE NENHUMA INFORMAÇÃO
                               MOV.DTMOVLOG, 
                               MOV.CUSTOFISCAL,
                               ESTOQUE.CUSTOFISCAL AS CUSTOFISCAL_ESTOQUE
                  FROM (SELECT TIPO
                              ,SEQMOV
                              ,BASECUSTOCONT
                              ,CUSTOCONT
                              ,CUSTOFIN
                              ,CUSTOREAL
                              ,CUSTOREP
                              ,CUSTOULTENT
                              ,CUSTOULTENTCONT
                              ,CUSTOREALSEMST
                              ,VALORULTENT
                              ,ESPECIE
                              ,SERIE
                              ,CODCONT
                              ,OBSERVACAO
                              ,CODPROD
                              ,CODOPER
                              ,NUMNOTA
                              ,DATA
                              ,HORALANC
                              ,CODFISCAL
                              ,QTCONT
                              ,QTENTRADA
                              ,QTSAIDA
                              ,QTSAIDA_DENTRO
                              ,QTSAIDA_FORA
                              ,HISTORICO
                              ,PUNITCONT
                              ,VALORITEMNOTA_ENT
                              ,VALORITEMNOTA_SAID
                              ,NUMTRANSENT
                              ,NUMTRANSVENDA
                              ,VLIPI
                              ,ST
                              ,STGUIA
                              ,DTCANCEL
                              ,SITUACAOTRIBUTARIA
                              ,TIPODESCARGA
                              ,MINUTOLANC
                              ,ROTINALANC AS ROTINACAD
                              ,'' AS NCM
                              ,'' AS POSSE
                              ,DTMOVLOG
                              ,CUSTOFISCAL 
                          FROM PCDADOS1070_TEMP
                         WHERE DATA BETWEEN PDTINICIO AND PDTFIM) MOV,
                             (SELECT PCPRODUT.CODPROD,
                                     PCPRODUT.DESCRICAO,
                                     PCPRODUT.EMBALAGEM,
                                     PCPRODUT.UNIDADE,
                                     PCPRODUT.CODEPTO,
                                     PCPRODUT.CODSEC,
                                     HISTEST.TIPOMERC,
                                     DECODE(NVL(PCPRODUT.COMODATO,'N'), 'S', 2, 0) POSSE,
                                     NVL(HISTEST.QTEST,0) QTEST,
                                     NVL(HISTEST.CUSTOCONT, 0) CUSTOCONT,
                                     NVL(HISTEST.CUSTOREAL, 0) CUSTOREAL,
                                     NVL(HISTEST.CUSTOREALSEMST, 0) CUSTOREALSEMST,
                                     NVL(HISTEST.CUSTOFIN, 0) CUSTOFIN,
                                     NVL(HISTEST.CUSTOREP, 0) CUSTOREP,
                                     NVL(HISTEST.CUSTOULTENT, 0) CUSTOULTENT,
                                     NVL(HISTEST.CUSTOULTENTCONT, 0) CUSTOULTENTCONT,
                                     NVL(HISTEST.VALORULTENT, 0) VALORULTENT,
                                     NVL(HISTEST.CUSTOFISCAL, 0) CUSTOFISCAL,                                     
                                     HISTEST.DATA
                              FROM (SELECT CODPROD,
                                           QTEST,
                                           DATA,
                                           QTTRANSITO,
                                           CUSTOCONT,
                                           CUSTOREAL,
                                           CUSTOFIN,
                                           CUSTOREP,
                                           CUSTOREALSEMST,
                                           CUSTOULTENT,
                                           CUSTOULTENTCONT,
                                           VALORULTENT,
                                           TIPOMERC, 
                                           CUSTOFISCAL
                                    FROM PCHISTEST
                                    WHERE DATA      = V_DATA_INVENTARIO
                                      AND CODFILIAL = PCODFILIAL
                                      AND CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                      AND DECODE(PUSOCONSUMO,      'N',NVL(PCHISTEST.TIPOMERCDEPTO, 'X'),'XX') <> 'CI'
                                      AND DECODE(PATIVIOMOBULIZADO,'N',NVL(PCHISTEST.TIPOMERCDEPTO, 'X'),'XX') <> 'IM'
                                      AND DECODE(PDESCONS_ITEM_BRINDE,'S',NVL(PCHISTEST.TIPOMERC, 'X'),'XX') <> 'BD'
                                      AND (CASE
                                               WHEN PSTATUSPROD = 'T'
                                                  THEN 1
                                               WHEN PSTATUSPROD = 'A' AND PCHISTEST.DTEXCLUSAOPROD IS NULL
                                                  THEN 1
                                               WHEN PSTATUSPROD = 'I' AND PCHISTEST.DTEXCLUSAOPROD IS NOT NULL
                                                  THEN 1
                                               ELSE 0
                                           END = 1)  
                                      ) HISTEST,
                                   PCPRODUT
                              WHERE PCPRODUT.CODPROD = HISTEST.CODPROD(+)
                                AND PCPRODUT.CODPROD BETWEEN PCODPROD1 AND PCODPROD2
                                AND NVL(PCPRODUT.TIPOMERC, 'X') <> 'SS'
                                ) ESTOQUE

                        WHERE ESTOQUE.CODPROD = MOV.CODPROD(+)
                          AND (PPROD_SEM_MOV = 'S' or MOV.CODPROD > 0)
                        ORDER BY CODPROD, DTMOVLOG, DATA, SEQMOV, TIPO, NUMNOTA)
          LOOP

            V_BASECUSTOCONT     := 0;
            V_CUSTOTOTALENTRADA := 0;
            V_CUSTOSAIDA        := 0;
            V_CUSTOTOTALSAIDA   := 0;

            -- Inicializar valores na mudança do produto
            if V_CODPROD <> DADOS.CODPROD
            then
              V_UTILIZA_CUSTO_ULTIMA_ENTRADA := true;
              -- Momento de busca do custo pelo PEPS
              if (PUTILIZA_METODO_PEPS = 'S')
              then
                if not GET_CUSTOMEDIO_PEPS(DADOS.NUMTRANSVENDA,
                                           DADOS.CODPROD,
                                           DADOS.DATA,
                                           case when SUBSTR(DADOS.CODOPER, 1, 1) = 'S' then 'N' else 'S' END,
                                           V_CUSTOMEDIO /* OUT */)
                then
                  V_UTILIZA_CUSTO_ULTIMA_ENTRADA := true;
                END if;
              END if;

              if (V_UTILIZA_CUSTO_ULTIMA_ENTRADA) or 
                 (NVL(V_CUSTOMEDIO, 0) = 0)
              then
                case PTIPOCUSTO
                  when 0 then
                    V_CUSTOMEDIO := DADOS.CUSTOCONT_ESTOQUE;
                  when 1 then
                    V_CUSTOMEDIO := DADOS.CUSTOREAL_ESTOQUE;
                  when 2 then
                    V_CUSTOMEDIO := DADOS.CUSTOREALSEMST_ESTOQUE;
                  when 3 then
                    V_CUSTOMEDIO := DADOS.CUSTOFIN_ESTOQUE;
                  when 4 then
                    V_CUSTOMEDIO := DADOS.CUSTOREP_ESTOQUE;
                  when 5 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENT_ESTOQUE;
                  when 6 then
                    V_CUSTOMEDIO := DADOS.VALORULTENT_ESTOQUE;
                  when 7 then
                    V_CUSTOMEDIO := DADOS.CUSTOFISCAL_ESTOQUE;
                  when 8 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENTCONT_ESTOQUE;                    
                END case; END if;

              if V_CUSTOMEDIO <= 0
              then
                case PTIPOCUSTO 
                  when 0 then
                    V_CUSTOMEDIO := DADOS.CUSTOCONT;
                  when 1 then
                    V_CUSTOMEDIO := DADOS.CUSTOREAL;
                  when 2 then
                    V_CUSTOMEDIO := DADOS.CUSTOREALSEMST;
                  when 3 then
                    V_CUSTOMEDIO := DADOS.CUSTOFIN;
                  when 4 then
                    V_CUSTOMEDIO := DADOS.CUSTOREP;
                  when 5 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENT;
                  when 6 then
                    V_CUSTOMEDIO := DADOS.VALORULTENT;
                  when 7 then
                    V_CUSTOMEDIO := DADOS.CUSTOFISCAL;
                  when 8 then
                    V_CUSTOMEDIO := DADOS.CUSTOULTENTCONT;  
                END case; END if;

              V_CUSTOMEDIO := ROUND(V_CUSTOMEDIO, PNUMCASAS_UNIT);
              V_SALDOQT    := ROUND(DADOS.QT_ESTOQUE, PNUMCASAS_QT);

              V_CUSTOTOTAL := ROUND(V_SALDOQT * V_CUSTOMEDIO, PNUMCASAS_TOTAL);

              V_SALDOQT_ANTERIOR    := V_SALDOQT;
              V_CUSTOMEDIO_ANTERIOR := V_CUSTOMEDIO;
              V_CUSTOTOTAL_ANTERIOR := V_CUSTOTOTAL;

              -- Gravar codigo do produto atual
              V_CODPROD := DADOS.CODPROD;
            END if;

            if (DADOS.ESPECIE is null and DADOS.SERIE <> 'SM') -- Acrescentado essa clausula para evitar o custo ficar zerado quando especie nulla para o lançamento SM
            then
              V_INFORMACAO := 'PRODUTO SEM MOVIMENTAÇÃO';
            else
              V_INFORMACAO := RPAD(' ', 50);

              -- Controlar entrada de produção
              if DADOS.CODOPER like 'E%'
              then
                case PTIPOCUSTO
                  when 0 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOCONT;
                  when 1 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOREAL;
                  when 2 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOREALSEMST;
                  when 3 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOFIN;
                  when 4 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOREP;
                  when 5 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOULTENT;
                  when 6 then
                    V_CUSTOUTILIZAR := DADOS.VALORULTENT;
                  when 7 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOFISCAL;
                  when 8 then
                    V_CUSTOUTILIZAR := DADOS.CUSTOULTENTCONT;   
                END case;  

                case PTIPOCUSTO
                  when 0 then
                    V_BASECUSTOCONT := NVL(DADOS.BASECUSTOCONT, 0);
                  when 1 then
                    V_BASECUSTOCONT := NVL(DADOS.CUSTOULTENT, 0);
                  when 2 then
                    V_BASECUSTOCONT := GREATEST(NVL(DADOS.CUSTOULTENT, 0) -
                                                NVL(DADOS.ST, 0) - NVL(DADOS.STGUIA, 0),
                                                0);
                  else
                    V_BASECUSTOCONT := DADOS.BASECUSTOCONT;
                END case;

                V_CUSTOMEDIO := GET_CUSTOMEDIO_ESTOQUE(DADOS.CODOPER,
                                                       V_CUSTOUTILIZAR,
                                                       V_CUSTOMEDIO,
                                                       DADOS.QTCONT,
                                                       V_SALDOQT,
                                                       V_CUSTOTOTAL,
                                                       DADOS.DTCANCEL);

                if not CODOPER_ALTERA_CUSTO(DADOS.CODOPER, DADOS.DTCANCEL)
                then
                  V_BASECUSTOCONT := V_CUSTOMEDIO;
                END if;

                if PUTILIZA_PRECO_NOTA = 'S'
                then
                  V_BASECUSTOCONT := DADOS.VALORITEMNOTA_ENT;
                END if;

                V_BASECUSTOCONT     := ROUND(V_BASECUSTOCONT, PNUMCASAS_UNIT);
                V_CUSTOTOTALENTRADA := ROUND(ROUND(DADOS.QTENTRADA, PNUMCASAS_QT) *
                                             V_BASECUSTOCONT,
                                             PNUMCASAS_TOTAL);

                IF (DADOS.TIPO = 'EF') OR (DADOS.TIPO = 'EP') OR (DADOS.TIPO = 'ES') THEN
                  V_SALDOQT    := (NVL(V_SALDOQT, 0) - NVL(DADOS.QTCONT, 0));
                  V_CUSTOTOTAL := ROUND(V_SALDOQT * V_CUSTOMEDIO, PNUMCASAS_TOTAL);
                END IF;
              else
                -- Controlar saída de produção
                -- Momento de busca do custo pelo PEPS
                if (PUTILIZA_METODO_PEPS = 'S') AND (DADOS.CODOPER like 'S%')
                then
                  V_UTILIZA_CUSTO_ULTIMA_ENTRADA := not
                                                     GET_CUSTOMEDIO_PEPS(DADOS.NUMTRANSVENDA,
                                                                         DADOS.CODPROD,
                                                                         DADOS.DATA,
                                                                         'N',
                                                                         V_CUSTOMEDIO
                                                                         /* OUT */);
                END if;

                V_CUSTOMEDIO := GET_CUSTOMEDIO_ESTOQUE(DADOS.CODOPER,
                                                       V_CUSTOMEDIO,
                                                       V_CUSTOMEDIO,
                                                       DADOS.QTCONT,
                                                       V_SALDOQT,
                                                       V_CUSTOTOTAL,
                                                       DADOS.DTCANCEL);

                V_CUSTOSAIDA := V_CUSTOMEDIO;

                if PUTILIZA_PRECO_NOTA = 'S'
                then
                  V_CUSTOSAIDA := DADOS.VALORITEMNOTA_SAID;
                END if;

                -- Se quantidade de saída zero, custo de saída recebe zero.
                if dados.qtsaida = 0 then
                  V_CUSTOSAIDA      := 0;
                  end if;

                V_CUSTOSAIDA      := ROUND(V_CUSTOSAIDA, PNUMCASAS_UNIT);
                V_CUSTOTOTALSAIDA := ROUND(ROUND(DADOS.QTSAIDA, PNUMCASAS_QT) *
                                           V_CUSTOSAIDA,
                                           PNUMCASAS_TOTAL);
              END if;
            END if;


            --    V_RETORNO.extEND;
            --    V_RETORNO(V_RETORNO.count) := TIPO_CONTROLE_PRODUCAO( -- MOVIMENTAÇÃO
            OUTROW.CODFILIAL      := SUBSTR(PCODFILIAL,0,2);
            OUTROW.TIPO           := SUBSTR(DADOS.TIPO,0,5);
            OUTROW.INFORMACAO     := SUBSTR(V_INFORMACAO,0,1000);
            OUTROW.NUMTRANSENT    := DADOS.NUMTRANSENT;
            OUTROW.NUMTRANSVENDA  := DADOS.NUMTRANSVENDA;
            OUTROW.ESPECIE        := SUBSTR(DADOS.ESPECIE,0,2);
            OUTROW.SERIE          := SUBSTR(DADOS.SERIE,0,3);
            OUTROW.NUMNOTA        := DADOS.NUMNOTA;
            OUTROW.DATA           := DADOS.DATA;
            OUTROW.CODCONT        := SUBSTR(DADOS.CODCONT,0,11);
            OUTROW.OBSERVACAO     := SUBSTR(DADOS.OBSERVACAO,0,1000);
            OUTROW.HISTORICO      := SUBSTR(DADOS.HISTORICO,0,21);
            OUTROW.CODPROD        := DADOS.CODPROD;
            OUTROW.DESCRICAO      := SUBSTR(DADOS.DESCRICAO,0,100);
            OUTROW.EMBALAGEM      := SUBSTR(DADOS.EMBALAGEM,0,50);
            OUTROW.UNIDADE        := SUBSTR(DADOS.UNIDADE,0,2);
            OUTROW.TIPOMERC       := SUBSTR(DADOS.TIPOMERC,0,2);
            OUTROW.CODSEC         := DADOS.CODSEC;
            OUTROW.CODEPTO        := DADOS.CODEPTO;
            OUTROW.CODOPER        := SUBSTR(DADOS.CODOPER,0,2);
            OUTROW.CODFISCAL      := DADOS.CODFISCAL;
            OUTROW.QTCONT         := DADOS.QTCONT;
            OUTROW.QTSAIDA_DENTRO := DADOS.QTSAIDA_DENTRO;
            OUTROW.QTSAIDA_FORA   := DADOS.QTSAIDA_FORA;
            OUTROW.CUSTOULTENT    := DADOS.CUSTOULTENT;
            OUTROW.CUSTOULTENTCONT:= DADOS.CUSTOULTENTCONT;
            OUTROW.CUSTOCONT      := DADOS.CUSTOCONT;
            OUTROW.CUSTOREAL      := DADOS.CUSTOREAL;
            OUTROW.CUSTOREALSEMST := DADOS.CUSTOREALSEMST;
            OUTROW.CUSTOFIN       := DADOS.CUSTOFIN;
            OUTROW.CUSTOREP       := DADOS.CUSTOREP;
            OUTROW.VALORULTENT    := DADOS.VALORULTENT;
            OUTROW.PUNITCONT      := DADOS.PUNITCONT;
            OUTROW.VLIPI          := DADOS.VLIPI;
            -- VALORES ENTRADA (RELATÓRIO PRODUÇÃO)
            OUTROW.QTENTRADA          := ROUND(DADOS.QTENTRADA, PNUMCASAS_QT);
            OUTROW.BASECUSTOCONT      := V_BASECUSTOCONT;
            OUTROW.CUSTOTOTAL_ENTRADA := V_CUSTOTOTALENTRADA;
            -- VALORES SAÍDA (RELATÓRIO PRODUÇÃO)
            OUTROW.QTSAIDA          := ROUND(DADOS.QTSAIDA, PNUMCASAS_QT);
            OUTROW.CUSTOCONTSAIDA   := V_CUSTOSAIDA;
            OUTROW.CUSTOTOTAL_SAIDA := V_CUSTOTOTALSAIDA;
            -- CUSTOS ESTOQUE
            OUTROW.CUSTOCONT_ESTOQUE      := DADOS.CUSTOCONT_ESTOQUE;
            OUTROW.CUSTOULTENT_ESTOQUE    := DADOS.CUSTOULTENT_ESTOQUE;
            OUTROW.CUSTOREP_ESTOQUE       := DADOS.CUSTOREP;
            OUTROW.CUSTOFIN_ESTOQUE       := DADOS.CUSTOFIN_ESTOQUE;
            OUTROW.CUSTOREAL_ESTOQUE      := DADOS.CUSTOREAL_ESTOQUE;
            OUTROW.CUSTOREALSEMST_ESTOQUE := DADOS.CUSTOREALSEMST_ESTOQUE;
            OUTROW.VALORULTENT_ESTOQUE    := DADOS.VALORULTENT_ESTOQUE;
            -- CUSTO ANTERIOR
            OUTROW.SALDOQT_ANTERIOR    := V_SALDOQT_ANTERIOR;
            OUTROW.CUSTOMEDIO_ANTERIOR := V_CUSTOMEDIO_ANTERIOR;
            OUTROW.CUSTOTOTAL_ANTERIOR := V_CUSTOTOTAL_ANTERIOR;
            -- CUSTO ATUAL
            OUTROW.SALDOQT_ATUAL    := V_SALDOQT;
            OUTROW.CUSTOMEDIO_ATUAL := V_CUSTOMEDIO;
            OUTROW.CUSTOTOTAL_ATUAL := V_CUSTOTOTAL;
            OUTROW.DTCANCEL         := DADOS.DTCANCEL;
            OUTROW.SITUACAOTRIBUTARIA := DADOS.SITUACAOTRIBUTARIA;
            OUTROW.TIPODESCARGA       := DADOS.TIPODESCARGA;
            OUTROW.ST            := DADOS.ST;
            OUTROW.MINUTOLANC    := DADOS.MINUTOLANC;
            OUTROW.HORALANC      := DADOS.HORALANC;
            OUTROW.SEQMOV        := DADOS.SEQMOV;
            OUTROW.ROTINACAD     := DADOS.ROTINACAD;
            OUTROW.NCM           := DADOS.NCM;
            OUTROW.POSSE         := DADOS.POSSE;
            OUTROW.DTMOVLOG      := DADOS.DTMOVLOG;
            OUTROW.CUSTOFISCAL   := DADOS.CUSTOFISCAL;            
            pipe row(OUTROW);
          END LOOP;
 END IF;


EXCEPTION
  when others then
    RAISE_APPLICATION_ERROR(-20000,
                            'OCORREU UM ERRO AO PROCESSAR O CONTROLE DE PRODUÇÃO!' ||
                            CHR(13) || 'ERRO ORIGINAL: ' || sqlerrm);
END;
----------------------------------------------//----------------------------------------------//----------------------------------------------//----------------------------------------------//
-- Últimas Alterações: 
-- Alteração em 17/01/2023 no SQl SF retirando as colunas de quantidade por se tratar de um CT de ajuste de custo. 
-- Alteração em 02/10/2023 - Implementado parametro 26 "PCONS_CUSTO_ZERO" para considerar entradas com custo zero
-- Alteração em 18/12/2023 - Implementação do custo fiscal
-- Alteração em 22/01/2024 - Voltando a lista de custos de 1 a 6 e acrescentando o custo fiscal na posição 7
----------------------------------------------//----------------------------------------------//----------------------------------------------//----------------------------------------------//