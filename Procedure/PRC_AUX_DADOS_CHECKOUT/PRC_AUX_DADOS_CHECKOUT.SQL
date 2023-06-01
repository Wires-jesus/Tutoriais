CREATE OR REPLACE PROCEDURE PRC_AUX_DADOS_CHECKOUT (p_numcar IN NUMBER, pmensagem OUT VARCHAR2)
/**********************************************************************************************
                                Historico de Alteracoes
-----------------------------------------------------------------------------------------------
 Data        Responsavel    Tarefa  Alteracao
 ----------  -------------  ------  -----------------------------------------------------------
 23/05/2007  Sabrina        44380   Correcao na gravacao do emitente da NF
**********************************************************************************************/
IS
BEGIN
   pmensagem := '';

   --Gravar Dados do Checkout no Contas a Receber
   --Antes de Zerar o Carregamento
   UPDATE pcprest
      SET codfunccheckout =
             (SELECT pcpedc.codfunccx
                FROM pcpedc, pcnfsaid
               WHERE pcpedc.numped = pcnfsaid.numped
                 AND pcnfsaid.numtransvenda = pcprest.numtransvenda),
          numcheckout =
             (SELECT pcpedc.numcaixa
                FROM pcpedc, pcnfsaid
               WHERE pcpedc.numped = pcnfsaid.numped
                 AND pcnfsaid.numtransvenda = pcprest.numtransvenda),
          duplic =
             (SELECT pcpedc.numcupom
                FROM pcpedc, pcnfsaid
               WHERE pcpedc.numped = pcnfsaid.numped
                 AND pcnfsaid.numtransvenda = pcprest.numtransvenda)
    WHERE numcar = p_numcar
      AND EXISTS (
             SELECT pcpedc.numcupom
               FROM pcpedc, pcnfsaid
              WHERE pcpedc.numped = pcnfsaid.numped
                AND pcnfsaid.numtransvenda = pcprest.numtransvenda);

   UPDATE pcnfsaid
      SET codemitente = (SELECT pcpedc.codfunccx
                           FROM pcpedc
                          WHERE pcpedc.numped = pcnfsaid.numped),
          caixa = (SELECT pcpedc.numcaixa
                     FROM pcpedc
                    WHERE pcpedc.numped = pcnfsaid.numped),
          numnota = (SELECT pcpedc.numcupom
                       FROM pcpedc
                      WHERE pcpedc.numped = pcnfsaid.numped),
          numcupom = (SELECT pcpedc.numcupom
                        FROM pcpedc
                       WHERE pcpedc.numped = pcnfsaid.numped)
    WHERE numcar = p_numcar
      AND dtcancel IS NULL
      AND EXISTS (SELECT pcpedc.numcupom
                    FROM pcpedc
                   WHERE pcpedc.numped = pcnfsaid.numped);

   UPDATE pcmov
      SET numnota =
             (SELECT pcpedc.numcupom
                FROM pcpedc, pcnfsaid
               WHERE pcpedc.numped = pcnfsaid.numped
                 AND pcnfsaid.numtransvenda = pcmov.numtransvenda)
    WHERE numcar = p_numcar
      AND EXISTS (
             SELECT pcpedc.numcupom
               FROM pcpedc, pcnfsaid
              WHERE pcpedc.numped = pcnfsaid.numped
                AND pcnfsaid.numtransvenda = pcmov.numtransvenda);

   COMMIT;
   pmensagem := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      pmensagem := 'ERRO AO GRAVAR DADOS CHECKOUT:' || SQLCODE || ' ' || SQLERRM;
END;                                                              -- Procedure
