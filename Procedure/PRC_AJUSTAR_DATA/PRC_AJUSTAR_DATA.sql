CREATE OR REPLACE PROCEDURE PRC_AJUSTAR_DATA AS
BEGIN
  UPDATE pcnfsaid nf
  SET nf.dtsaida = (
    SELECT MAX(mv.dtmov)
    FROM pcmov mv
    WHERE mv.numtransvenda = nf.numtransvenda
  )
  WHERE EXISTS (
    SELECT 1
    FROM pcmov mv
    WHERE mv.numtransvenda = nf.numtransvenda
      AND mv.dtmov <> nf.dtsaida
  )
  AND nf.dtsaida >= TO_DATE('01/06/2025', 'DD/MM/YYYY')
  AND nf.dtcancel IS NULL
  AND nf.docemissao = 'CE';

  COMMIT;
END;

