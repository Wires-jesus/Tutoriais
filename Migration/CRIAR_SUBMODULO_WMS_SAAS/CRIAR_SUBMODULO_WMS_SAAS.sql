DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(1) INTO v_count 
    FROM pcsubmodulo 
    WHERE codmodulo = 11 AND codsubmodulo = 9;

    IF v_count = 0 THEN
        INSERT INTO pcsubmodulo (codmodulo, codsubmodulo, submodulo, exibirmenu) 
        VALUES (11, 9, 'WMS SAAS', 'S');
        COMMIT;
    END IF;
END;