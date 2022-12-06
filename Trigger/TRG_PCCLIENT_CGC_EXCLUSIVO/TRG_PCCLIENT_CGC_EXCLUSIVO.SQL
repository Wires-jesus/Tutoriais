CREATE OR REPLACE TRIGGER TRG_PCCLIENT_CGC_EXCLUSIVO
  BEFORE INSERT ON PCCLIENT
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
DECLARE
  VCOUNT INTEGER;
BEGIN
  IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CGCCLIEXCLUSIVO', '99', 'N') = 'S') and (:NEW.ESTENT <> 'EX') THEN
    SELECT COUNT(1)
      INTO VCOUNT
      FROM PCCLIENT
     WHERE TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CGCENT,
                                                                ' ',
                                                                ''),
                                                        '.',
                                                        ''),
                                                ',',
                                                ''),
                                        '-',
                                        ''),
                                '/',
                                ''),
                        '\',
                        '')) = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(:NEW.CGCENT,
                                                                                    ' ',
                                                                                    ''),
                                                                            '.',
                                                                            ''),
                                                                    ',',
                                                                    ''),
                                                            '-',
                                                            ''),
                                                    '/',
                                                    ''),
                                            '\',
                                            ''))
       AND TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NVL(CGCENT, ''),
                                                                ' ',
                                                                ''),
                                                        '.',
                                                        ''),
                                                ',',
                                                ''),
                                        '-',
                                        ''),
                                '/',
                                ''),
                        '\',
                        '')) || ' ' <> ' '  AND DTEXCLUSAO IS NULL;

    IF VCOUNT > 0 THEN
      RAISE_APPLICATION_ERROR(-29999, 'CLIENTE JÁ CADASTRADO');
    END IF;
  END IF;

END TRG_PCCLIENT_CGC_EXCLUSIVO;

