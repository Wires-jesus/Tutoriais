CREATE OR REPLACE TYPE BODY "T_PC_CARREGAMENTO" AS

  MEMBER PROCEDURE setCOLUNA (PCOLUNA VARCHAR2, PVALOR VARCHAR2, PTIPO VARCHAR2)
  IS
  vSQL  VARCHAR2(200);
  BEGIN

    vSQL := 'UPDATE PCCARREG SET ' || PCOLUNA || ' = ';

    CASE PTIPO
     WHEN 'N' THEN --Valor numérico
       vSQL := vSQL || 'TO_NUMBER('||PVALOR||') ';
     WHEN 'A' THEN --Valor Alfanumérico
       vSQL := vSQL || 'TO_CHAR('||PVALOR||') ';
     WHEN 'D' THEN --Valor Data
       vSQL := vSQL || 'TO_DATE('||PVALOR||') ';
    END CASE;

    vSQL := vSQL || 'WHERE NUMCAR = '|| TO_CHAR(FNUMCAR) || ' AND NUMCAR NOT IN (0, -1)  ';

    EXECUTE IMMEDIATE vSQL;

  END;

  CONSTRUCTOR FUNCTION T_PC_CARREGAMENTO (PNUMCAR NUMBER)
  RETURN SELF AS RESULT
  IS
  vdtfat      DATE;
  vdt_cancel  DATE;
  vdt_dtfecha DATE;
  BEGIN

    SELF.FNUMCAR := PNUMCAR;

    SELECT dtfat, dt_cancel, dtfecha
      INTO vdtfat, vdt_cancel, vdt_dtfecha
      FROM PCCARREG
     WHERE NUMCAR = SELF.FNUMCAR;

    SELF.FDTFAT := vdtfat;
    SELF.FDT_CANCEL := vdt_cancel;
    SELF.FDTFECHA := vdt_dtfecha;

    RETURN;

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
     RAISE_APPLICATION_ERROR(-20000,
                             CHR(13) ||
                             'O carregamento '||TO_CHAR(PNUMCAR)||' não foi localizado!'
                             ||CHR(13)||'Mensagem original do banco.: ' || SQLCODE || '-' || SQLERRM);

   WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20000,
                             CHR(13) ||
                             'Não foi possível inicializar o carregamento!'
                             ||CHR(13)||'Mensagem original do banco.: ' || SQLCODE || '-' || SQLERRM);

  END;

  MEMBER FUNCTION GETDTFECHA RETURN DATE IS
  BEGIN
    RETURN SELF.FDTFECHA;
  END;

  MEMBER PROCEDURE CALCULARFRETEKILO
  /******************************************************************************************
    ->Nome da PROCEDURE : calcularFreteKilo
    ->Objetivo          : Procedure para realizar cálculo de Frete na tabela PCPEDC, conforme Projeto 62507
    ->Utilizado por     : T_PC_CARREGAMENTO
    -------------------------------- Historico ------------------------------------------------------------------
    Data          Responsavel       Tarefa  Comentarios
    ------------  ---------------   ------  ----------------------------------------------------------------------
    14/08/2008    Rogério           67040   Cálculo de Frete por Kilo, Projeto 62507
    ------------  ---------------   ---------------------------------------------------------------------------*/
   IS
    vstipofreteauto         pcfilial.tipofreteauto%TYPE;
    vslancarfretepesoautfat pcfilial.lancarfretepesoautfat%TYPE;
    vnvlatend               NUMBER;
    vnvltotal               NUMBER;
    vnvltabela              NUMBER;
  BEGIN
    FOR cab IN (SELECT DISTINCT pcpedc.codfilial,
                                pcpedc.numped,
                                NVL(pcpedc.totpeso, 0) totpeso,
                                NVL(pcpedc.numregiao,
                                    (SELECT pcregiao.numregiao
                                       FROM pcpraca, pcregiao
                                      WHERE pcpraca.numregiao =
                                            pcregiao.numregiao
                                        AND pcpraca.codpraca =
                                            pcclient.codpraca)) numregiao,
                                (SELECT NVL(pcregiao.vlfretekgvenda, 0)
                                   FROM pcregiao
                                  WHERE pcregiao.numregiao = pcpedc.numregiao) vlfretekgvenda,
                                NVL(pcpedc.vloutrasdesp, 0) vloutrasdesp,
                                NVL(pcpedc.vldesconto, 0) vldesconto
                  FROM pcpedc, pcclient, pcplpag, pccob
                 WHERE pcpedc.numcar = FNUMCAR
                   AND pcpedc.codcli = pcclient.codcli
                   AND pcpedc.codplpag = pcplpag.codplpag
                   AND pcpedc.codcob = pccob.codcob
                   AND pcpedc.posicao = 'M'
                   AND pcpedc.fretedespacho = 'C' --tarefa 207295
                   AND pcpedc.numitens > 0
                 ORDER BY pcpedc.numped) LOOP
      BEGIN
        SELECT pcfilial.tipofreteauto,
               NVL(pcfilial.lancarfretepesoautfat, 'N') lancarfretepesoautfat
          INTO vstipofreteauto, vslancarfretepesoautfat
          FROM pcfilial
         WHERE pcfilial.codigo = cab.codfilial;

        IF vstipofreteauto <> 'N' THEN
          IF vslancarfretepesoautfat = 'S' THEN
            SELECT SUM(DECODE(pcpedc.condvenda,
                              4,
                              0,
                              5,
                              0,
                              8,
                              0,
                              11,
                              0,
                              NVL(pcpedi.qt, 0) * NVL(pcpedi.pvenda, 0))) vlatend,
                   SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                       NVL(pcpedi.pvenda, 0)) vltotal,
                   SUM(DECODE(pcpedc.condvenda,
                              4,
                              0,
                              7,
                              0,
                              NVL(pcpedi.qt, 0) * NVL(pcpedi.ptabela, 0))) vltabela
              INTO vnvlatend, vnvltotal, vnvltabela
              FROM pcpedi, pcpedc, pcprodut
             WHERE pcpedi.codprod = pcprodut.codprod
               AND pcpedi.numped = pcpedc.numped
               AND pcpedc.numped = cab.numped
               AND pcpedi.qt > 0;

            vnvlatend  := ROUND(vnvlatend + cab.vloutrasdesp +
                                (cab.totpeso * cab.vlfretekgvenda) -
                                cab.vldesconto,
                                2);
            vnvltotal  := ROUND(vnvltotal + cab.vloutrasdesp +
                                (cab.totpeso * cab.vlfretekgvenda) -
                                cab.vldesconto,
                                2);
            vnvltabela := ROUND(vnvltabela + cab.vloutrasdesp +
                                (cab.totpeso * cab.vlfretekgvenda) -
                                cab.vldesconto,
                                2);

            UPDATE pcpedc
               SET vlfrete  = (cab.totpeso * cab.vlfretekgvenda),
                   vlatend  = vnvlatend,
                   vltotal  = vnvltotal,
                   vltabela = vnvltabela
             WHERE pcpedc.numped = cab.numped;
          END IF;

        END IF;

      END;

    END LOOP;

  END;

END
