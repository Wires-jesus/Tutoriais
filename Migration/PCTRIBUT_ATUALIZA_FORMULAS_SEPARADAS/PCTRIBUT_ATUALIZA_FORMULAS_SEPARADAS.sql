DECLARE
  PROCEDURE ATUALIZAR_PCTRIBUT(
    pTIPO NUMBER,
    pCODST NUMBER,
    pFORMULA VARCHAR2
  )
  IS
    vSQL VARCHAR2(1000);
    vCONT NUMBER;
    vIMPOSTO VARCHAR2(200);
    vCODTIPOFORMULA PCFORMULA.CODTIPOFORMULA%TYPE;
  BEGIN
    IF pFORMULA IS NULL THEN
      RETURN;
    END IF;

    vSQL := NULL;
    vCONT := 1;

    LOOP
      BEGIN
        SELECT DBMS_LOB.SUBSTR(
                 FORMULA,
                 INSTR(FORMULA, '#', 1, vCONT + 1) - INSTR(FORMULA, '#', 1, vCONT) - 1,
                 INSTR(FORMULA, '#', 1, vCONT) + 1
               )
          INTO vIMPOSTO
          FROM PCFORMULA
         WHERE CODFORMULA = pFORMULA;
      EXCEPTION
        WHEN OTHERS THEN
          vIMPOSTO := NULL;
      END;

      IF vIMPOSTO IS NULL THEN
        EXIT;
      END IF;

      BEGIN
        SELECT CODTIPOFORMULA
          INTO vCODTIPOFORMULA
          FROM PCFORMULA
         WHERE CODFORMULA = TRIM(vIMPOSTO);
      EXCEPTION
        WHEN OTHERS THEN
          vCODTIPOFORMULA := -1;
      END;

      IF vCODTIPOFORMULA IN(1, 2, 8) THEN
        vSQL := vSQL || CASE WHEN vSQL IS NOT NULL THEN ',' ELSE '' END;
        vSQL := vSQL || CASE vCODTIPOFORMULA
                          WHEN 1 THEN --ST
                            CASE pTIPO 
                              WHEN 1 THEN 'FORMULAST'
                              WHEN 2 THEN 'FORMULASTTRANSF'
                              WHEN 3 THEN 'FORMULASTTRANSFVIRT'
                            END
                          WHEN 2 THEN --IPI
                            CASE pTIPO
                              WHEN 1 THEN 'FORMULAIPI'
                              WHEN 2 THEN 'FORMULAIPITRANSF'
                              WHEN 3 THEN 'FORMULAIPITRANSFVIRT'
                            END
                          WHEN 8 THEN --FECP
                            CASE pTIPO
                              WHEN 1 THEN 'FORMULAFECP'
                              WHEN 2 THEN 'FORMULAFECPTRANSF'
                              WHEN 3 THEN 'FORMULAFECPTRANSFVIRT'
                            END
                        END || ' = ''' || TRIM(vIMPOSTO) ||'''';
      END IF;

      vCONT := vCONT + 2;
    END LOOP;

    IF vSQL IS NOT NULL THEN
      EXECUTE IMMEDIATE 'UPDATE PCTRIBUT SET '|| vSQL ||' WHERE CODST = :CODST' USING pCODST;
    END IF;
  END;
BEGIN
  FOR TRIBUT IN(SELECT CODST,
                       FORMULAPVENDA, --TIPO = 1
                       FORMULAPVENDATRANSF, --TIPO = 2
                       FORMULAPVENDATRANSFVIRT --TIPO = 3
                  FROM PCTRIBUT
                 WHERE FORMULAST IS NULL
                   AND FORMULAIPI IS NULL
                   AND FORMULAFECP IS NULL
                   AND FORMULASTTRANSF IS NULL
                   AND FORMULAIPITRANSF IS NULL
                   AND FORMULAFECPTRANSF IS NULL
                   AND FORMULASTTRANSFVIRT IS NULL
                   AND FORMULAIPITRANSFVIRT IS NULL
                   AND FORMULAFECPTRANSFVIRT IS NULL
                   AND (FORMULAPVENDA IS NOT NULL OR
                        FORMULAPVENDATRANSF IS NOT NULL OR
                        FORMULAPVENDATRANSFVIRT IS NOT NULL)
                 ORDER BY CODST)
  LOOP
    ATUALIZAR_PCTRIBUT(1, TRIBUT.CODST, TRIBUT.FORMULAPVENDA);
    ATUALIZAR_PCTRIBUT(2, TRIBUT.CODST, TRIBUT.FORMULAPVENDATRANSF);
    ATUALIZAR_PCTRIBUT(3, TRIBUT.CODST, TRIBUT.FORMULAPVENDATRANSFVIRT);
  END LOOP;
END;