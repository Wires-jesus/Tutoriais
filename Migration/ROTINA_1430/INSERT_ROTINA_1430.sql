DECLARE
  iValue INTEGER;
BEGIN
  SELECT COUNT(*) INTO iVALUE FROM PCROTINA WHERE CODIGO = 1430;
  IF iValue = 0 THEN
          INSERT INTO PCROTINA (
            AUTMENU
            ,CODFUNCULTUTIL
            ,CODIGO
            ,CODMODULO
            ,CODSUBMODULO
            ,DATAEXE
            ,DATASINCRONIZACAO
            ,DTPRIUTILIZACAO
            ,DTULTUTILIZACAO
            ,DTULTVERSAO
            ,EXIBIRMENU
            ,NOMEROTINA
            ,NUMSEQ
            ,ROTINA
            ,ROTINAWEB
            ,UTILIZACONTROLEBIOMETRICO
          ) VALUES ((SELECT MAX(AUTMENU) + 1 FROM PCROTINA WHERE 1=1)
                  ,1
                  ,1430
                  ,14
                  ,1
                  ,SYSDATE
                  ,SYSDATE
                  ,SYSDATE
                  ,SYSDATE
                  ,SYSDATE
                  ,'S'
                  ,'Gerar Faturamento'
                  ,1
                  ,'PCSIS1430'
                  ,'N'
                  ,'N'
                  );
        COMMIT;
  END IF;  
END;