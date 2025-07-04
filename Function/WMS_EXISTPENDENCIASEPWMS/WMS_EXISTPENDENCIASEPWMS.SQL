CREATE OR REPLACE FUNCTION WMS_EXISTPENDENCIASEPWMS(PNUMCAR PCCARREG.NUMCAR%TYPE,
                                  PNUMPED IN NUMBER DEFAULT 0)
  RETURN STRING IS
  VCOUNT    INTEGER;
  VCOUNTOSAGRUPAMENTO    INTEGER;
  VUSAPARAM VARCHAR(1);
  VNUMPED PCPEDC.NUMPED%TYPE;
  VNUMCAR PCPEDC.NUMCAR%TYPE;
  VCONDVENDA INTEGER;
BEGIN

  VNUMPED    := NVL(PNUMPED, 0);
  VCONDVENDA := 0;
  VNUMCAR    := NVL(PNUMCAR, 0);

  IF VNUMPED > 0 THEN
   SELECT MAX(CONDVENDA) INTO VCONDVENDA
    FROM PCPEDC
   WHERE NUMPED = VNUMPED;

   IF VCONDVENDA = 7 THEN
    VNUMCAR := 0;
   END IF;
  END IF;

  /*
  Verifica se há pendencia no WMS para o carregamento, se retornar 'S' que dizer que há pendencia, 'N' o processo WMS foi realizado
  Data da ultima alteração: 07/06/2025
  */

 IF NVL(VNUMCAR, 0) > 0 THEN
  --Verificando se existe prtoduto que utiliza WMS
  SELECT COUNT(PCPRODUT.CODPROD)
    INTO VCOUNT
    FROM PCPRODUT, PCPEDC, PCPEDI
   WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
     AND PCPEDI.CODPROD = PCPRODUT.CODPROD
     AND PCPEDC.NUMCAR = VNUMCAR
     AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
     AND NVL(PCPRODUT.USAWMS, 'N') = 'S';
  IF VCOUNT = 0 THEN
    RETURN 'N';
  END IF;

  --Verificando se a pedidos com produtos que usam wms que ainda não foramr importados
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCPEDC, PCPEDI, PCPRODUT
   WHERE PCPEDC.NUMCAR = VNUMCAR
     AND PCPEDC.NUMPED = PCPEDI.NUMPED
     AND PCPEDI.CODPROD = PCPRODUT.CODPROD
     AND NVL(PCPRODUT.USAWMS, 'N') = 'S'
     AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
     AND PCPEDC.DTWMS IS NULL
     AND PCPEDC.DTCANCEL IS NULL;

  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Verificando se os registros entraram para o WMS e tem os mapas gerados
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCWMS
   WHERE PCWMS.NUMPED IN (SELECT NUMPED FROM PCPEDC WHERE NUMCAR = VNUMCAR)
     AND DTCANCEL IS NULL
     AND CODOPER LIKE 'S%'
     AND NVL(MAPAGERADO, 'N') = 'N';

  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Verificando se os volumes foram todos embarcados (Rotina 3720)
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCPARAMETROWMS
   WHERE CODFILIAL IN (SELECT MIN(nvl(pcpedi.CODFILIALretira, PCPEDC.codfilial)) FROM PCPEDC, pcpedi
                                 WHERE pcpedc.NUMCAR = VNUMCAR
                                 and pcpedc.numped= pcpedi.numped
                                 and pcpedc.numcar = pcpedi.numcar)
     AND NOME = 'LIBERACARGAEMBARQUECONF'
     AND VALOR = 'S';

  IF VCOUNT > 0 THEN
    SELECT COUNT(1)
      INTO VCOUNT
      FROM PCVOLUMEOS V
     WHERE V.NUMOS IN
           (SELECT DISTINCT M.NUMOS
              FROM PCMOVENDPEND M
             WHERE M.NUMCAR = VNUMCAR
               AND M.DTESTORNO IS NULL
               AND M.CODFUNCAUTFAT IS NULL
               AND M.CODOPER LIKE 'S%'
               AND M.DATALIBFAT IS NULL
               AND M.TIPOOS IN
                   (SELECT TO_NUMBER(NVL(SUBSTR(NOME, 14, 2), 0)) AS TIPOOS
                      FROM PCPARAMETROWMS
                     WHERE NOME IN ('TIPOOSCONFEMB9',
                                    'TIPOOSCONFEMB10',
                                    'TIPOOSCONFEMB11',
                                    'TIPOOSCONFEMB12',
                                    'TIPOOSCONFEMB13',
                                    'TIPOOSCONFEMB14',
                                    'TIPOOSCONFEMB15',
                                    'TIPOOSCONFEMB16',
                                    'TIPOOSCONFEMB17',
                                    'TIPOOSCONFEMB18',
                                    'TIPOOSCONFEMB19',
                                    'TIPOOSCONFEMB20',
                                    'TIPOOSCONFEMB22')
                       AND CODFILIAL = (SELECT MIN(CODFILIAL)
                                          FROM PCPEDC
                                         WHERE NUMCAR = VNUMCAR)
                       AND VALOR = 'S'))
	   AND NVL (VOLUMECORTADO,'N') = 'N'
       AND V.EMBARCADO = 'N';
    IF VCOUNT > 0 THEN
      RETURN 'S';
    END IF;
  END IF;  
  
  --Verificando se as caixas foram todas embarcadas (Rotinas 3711, 3723 e 3735)
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCPARAMETROWMS
   WHERE CODFILIAL IN (SELECT MIN(nvl(pcpedi.CODFILIALretira, PCPEDC.codfilial)) FROM PCPEDC, pcpedi
                                 WHERE pcpedc.NUMCAR = VNUMCAR
                                 and pcpedc.numped= pcpedi.numped
                                 and pcpedc.numcar = pcpedi.numcar)
     AND NOME = 'LIBERACARGAAPOSCXSEMBARCADAS'
     AND VALOR = 'S';

  IF VCOUNT > 0 THEN
    SELECT COUNT(1)
      INTO VCOUNT
      FROM PCWMSVINCULOCAIXA W
     WHERE W.NUMOS IN
           (SELECT DISTINCT M.NUMOS
              FROM PCMOVENDPEND M
             WHERE M.NUMCAR = VNUMCAR
               AND M.DTESTORNO IS NULL
               AND M.CODFUNCAUTFAT IS NULL
               AND M.CODOPER LIKE 'S%'
               AND M.DATALIBFAT IS NULL
               AND M.TIPOOS IN
                   (SELECT TO_NUMBER(NVL(SUBSTR(NOME, 14, 2), 0)) AS TIPOOS
                      FROM PCPARAMETROWMS
                     WHERE NOME IN ('TIPOOSCONFEMB9',
                                    'TIPOOSCONFEMB10',
                                    'TIPOOSCONFEMB11',
                                    'TIPOOSCONFEMB12',
                                    'TIPOOSCONFEMB13',
                                    'TIPOOSCONFEMB14',
                                    'TIPOOSCONFEMB15',
                                    'TIPOOSCONFEMB16',
                                    'TIPOOSCONFEMB17',
                                    'TIPOOSCONFEMB18',
                                    'TIPOOSCONFEMB19',
                                    'TIPOOSCONFEMB20',
                                    'TIPOOSCONFEMB22')
                       AND CODFILIAL = (SELECT MIN(CODFILIAL)
                                          FROM PCPEDC
                                         WHERE NUMCAR = VNUMCAR)
                       AND VALOR = 'S'))
       AND NVL(W.EMBARCADO, 'N') = 'N';
    IF VCOUNT > 0 THEN
      RETURN 'S';
    END IF;
  END IF;  

  --Verificando se todas as Ordens de serviço foram finalizadas, validando por numero carregamento
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCMOVENDPEND
   WHERE NUMCAR = VNUMCAR
     AND DTESTORNO IS NULL
     AND CODFUNCAUTFAT IS NULL
     AND CODOPER LIKE 'S%'
     AND DATALIBFAT IS NULL
     AND POSICAO <> 'C';
  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Verificando se todas as Ordens de serviço foram finalizadas, validando por numero pedido
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCMOVENDPEND
   WHERE NUMPED IN (SELECT NUMPED FROM PCPEDC WHERE NUMCAR = VNUMCAR)
     AND DTESTORNO IS NULL
     AND CODFUNCAUTFAT IS NULL
     AND CODOPER LIKE 'S%'
     AND DATALIBFAT IS NULL
     AND POSICAO = 'P';
  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Carregamento: Verifica se validar o volume impresso da etiqueta, conforme parametro na tela (não mudar este texto)

  --Verificando se na carga existem Tiposs de agrupamento
  VCOUNTOSAGRUPAMENTO := 0;

  SELECT COUNT(1) INTO VCOUNTOSAGRUPAMENTO
      FROM PCMOVENDPEND
     WHERE PCMOVENDPEND.NUMCAR = PNUMCAR
       AND PCMOVENDPEND.TIPOOS IN (13,17,18,20,22)
       ---AND PCMOVENDPEND.POSICAO = 'P' --retirado pois a OS pode estar finalizada mas não agrupada
       AND PCMOVENDPEND.DTESTORNO IS NULL;

  --Verificando se a carga foi toda agrupado.
  VUSAPARAM := '';
   SELECT NVL(VALOR, 'N')
   INTO VUSAPARAM
    FROM PCPARAMETROWMS
   WHERE NOME = 'LIBERARCARGAVOLAGRUPADOS'
     AND CODFILIAL IN (SELECT MIN(nvl(pcpedi.CODFILIALretira, PCPEDC.codfilial)) FROM PCPEDC, pcpedi
                                 WHERE pcpedc.NUMCAR = VNUMCAR
                                 and pcpedc.numped= pcpedi.numped
                                 and pcpedc.numcar = pcpedi.numcar );

  IF (VUSAPARAM = 'S') AND (VCOUNTOSAGRUPAMENTO >0) THEN

   --SE NÃO EXISTE  PCVOLUMEOS ENTÃO EXISTE PENDENCIA
     SELECT COUNT(1)
      INTO VCOUNT
      FROM PCVOLUMEOS
     WHERE NUMOS IN (SELECT DISTINCT NUMOS
                       FROM PCMOVENDPEND
                      WHERE PCMOVENDPEND.NUMCAR = VNUMCAR
                        AND PCMOVENDPEND.CODOPER LIKE 'S%'
                        AND PCMOVENDPEND.DTESTORNO IS NULL);

     IF VCOUNT = 0 THEN
       RETURN 'S';
     ELSE
    ----CASO EXISTA OS VOLUMES VERIFICAÇÃO PARA VER SE EXISTE ALGUM SEM AGRUPAR SE EXISTE RETORNA PENDENCIA
       SELECT COUNT(1) INTO VCOUNT
      FROM PCVOLUMEOS, PCMOVENDPEND
     WHERE PCMOVENDPEND.NUMOS = PCVOLUMEOS.NUMOS
       AND PCVOLUMEOS.DATAAGRUPAMENTO IS NULL
       AND NVL(PCVOLUMEOS.VOLUMECORTADO, 'N') = 'N'-----
       AND PCVOLUMEOS.DTESTORNO IS NULL
       AND PCMOVENDPEND.NUMCAR = PNUMCAR
       AND PCMOVENDPEND.CODOPER LIKE 'S%'
       AND PCMOVENDPEND.DTESTORNO IS NULL;

       IF VCOUNT > 0 THEN
         RETURN 'S';
       ELSE
         RETURN 'N';
       END IF;
  END IF;

  ELSE
  RETURN 'N';

 END IF;

  RETURN 'N';

 END IF;

 IF VNUMPED <> 0 THEN

 --Verificando se existe prtoduto que utiliza WMS
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCPRODUT, PCPEDC, PCPEDI
   WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
     AND PCPEDI.CODPROD = PCPRODUT.CODPROD
     AND PCPEDC.NUMPED = VNUMPED
     AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
     AND NVL(PCPRODUT.USAWMS, 'N') = 'S';
  IF VCOUNT = 0 THEN
    RETURN 'N';
  END IF;

  --Verificando se a pedidos com produtos que usam wms que ainda não foramr importados
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCPEDC, PCPEDI, PCPRODUT
   WHERE PCPEDC.NUMPED = VNUMPED
     AND PCPEDC.NUMPED = PCPEDI.NUMPED
     AND PCPEDI.CODPROD = PCPRODUT.CODPROD
     AND NVL(PCPRODUT.USAWMS, 'N') = 'S'
     AND PCPEDC.CONDVENDA NOT IN (4, 7, 14)
     AND PCPEDC.DTWMS IS NULL
     AND PCPEDC.DTCANCEL IS NULL;

  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Verificando se os registros entraram para o WMS e tem os mapas gerados
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCWMS
   WHERE PCWMS.NUMPED IN (SELECT NUMPED FROM PCPEDC WHERE NUMPED = VNUMPED)
     AND DTCANCEL IS NULL
     AND CODOPER LIKE 'S%'
     AND NVL(MAPAGERADO, 'N') = 'N';

  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Verificando se os volumes foram todos embarcados (Rotina 3720)
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCPARAMETROWMS
   WHERE CODFILIAL =
         (SELECT MIN(CODFILIAL) FROM PCMOVENDPEND WHERE NUMPED = VNUMPED)
     AND NOME = 'LIBERACARGAEMBARQUECONF'
     AND VALOR = 'S';

  IF VCOUNT > 0 THEN
    SELECT COUNT(1)
      INTO VCOUNT
      FROM PCVOLUMEOS V
     WHERE V.NUMOS IN
           (SELECT DISTINCT M.NUMOS
              FROM PCMOVENDPEND M
             WHERE M.NUMPED = VNUMPED
               AND M.DTESTORNO IS NULL
               AND CODOPER LIKE 'S%'
               AND M.TIPOOS IN
                   (SELECT TO_NUMBER(NVL(SUBSTR(NOME, 14, 2), 0)) AS TIPOOS
                      FROM PCPARAMETROWMS
                     WHERE NOME IN ('TIPOOSCONFEMB13',
                                    'TIPOOSCONFEMB17',
                                    'TIPOOSCONFEMB18',
                                    'TIPOOSCONFEMB20',
                                    'TIPOOSCONFEMB22')
                       AND CODFILIAL = (SELECT MIN(CODFILIAL)
                                          FROM PCMOVENDPEND
                                         WHERE NUMPED = VNUMPED)
                       AND VALOR = 'S'))
     AND NVL (V.VOLUMECORTADO,'N') = 'N'
       AND V.EMBARCADO = 'N';
    IF VCOUNT > 0 THEN
      RETURN 'S';
    END IF;
  END IF;

  --Verificando se todas as Ordens de serviço foram finalizadas, validando por numero carregamento
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCMOVENDPEND
   WHERE NUMPED = VNUMPED
     AND CODFUNCAUTFAT IS NULL
     AND DATALIBFAT IS NULL
     AND DTESTORNO IS NULL
     AND CODOPER LIKE 'S%'
     AND POSICAO <> 'C';
  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;
  --Pedido: Verifica se validar o volume impresso da etiqueta, conforme parametro na tela (não mudar este texto)


  --Verificando se todas as Ordens de serviço foram finalizadas, validando por numero pedido
  SELECT COUNT(1)
    INTO VCOUNT
    FROM PCMOVENDPEND
   WHERE NUMPED IN (SELECT NUMPED FROM PCPEDC WHERE NUMPED = VNUMPED)
     AND DTESTORNO IS NULL
     AND CODFUNCAUTFAT IS NULL
     AND DATALIBFAT IS NULL
     AND CODOPER LIKE 'S%'
     AND POSICAO = 'P';
  IF VCOUNT > 0 THEN
    RETURN 'S';
  END IF;

  --Verificando se a carga foi toda agrupado.
  VUSAPARAM := '';
  SELECT NVL(VALOR, 'N')
    INTO VUSAPARAM
    FROM PCPARAMETROWMS
   WHERE NOME = 'LIBERARCARGAVOLAGRUPADOS'
     AND CODFILIAL IN
         (SELECT MIN(CODFILIAL) FROM PCMOVENDPEND WHERE NUMPED = VNUMPED);
  
  --Verificando se no pedido existem Tiposs de agrupamento
  VCOUNTOSAGRUPAMENTO := 0;

  SELECT COUNT(1) INTO VCOUNTOSAGRUPAMENTO
      FROM PCMOVENDPEND
     WHERE PCMOVENDPEND.NUMPED = VNUMPED
       AND PCMOVENDPEND.TIPOOS IN (13,17,18,20,22)
       ---AND PCMOVENDPEND.POSICAO = 'P' --retirado pois a OS pode estar finalizada mas não agrupada
       AND PCMOVENDPEND.DTESTORNO IS NULL;
       
  IF (VUSAPARAM = 'S') AND (VCOUNTOSAGRUPAMENTO >0) THEN 

   --SE NÃO EXISTE  PCVOLUMEOS ENTÃO EXISTE PENDENCIA
     SELECT COUNT(1)
      INTO VCOUNT
      FROM PCVOLUMEOS
     WHERE NUMOS IN (SELECT DISTINCT NUMOS
                       FROM PCMOVENDPEND
                      WHERE PCMOVENDPEND.NUMPED = VNUMPED
                        AND PCMOVENDPEND.CODOPER LIKE 'S%'
                        AND PCMOVENDPEND.DTESTORNO IS NULL);

     IF VCOUNT = 0 THEN
       RETURN 'S';
     ELSE
    ----CASO EXISTA OS VOLUMES VERIFICAÇÃO PARA VER SE EXISTE ALGUM SEM AGRUPAR SE EXISTE RETORNA PENDENCIA
       SELECT COUNT(1) INTO VCOUNT
      FROM PCVOLUMEOS, PCMOVENDPEND
     WHERE PCMOVENDPEND.NUMOS = PCVOLUMEOS.NUMOS
       AND PCVOLUMEOS.DATAAGRUPAMENTO IS NULL
       AND NVL(PCVOLUMEOS.VOLUMECORTADO, 'N') = 'N'-----
       AND PCVOLUMEOS.DTESTORNO IS NULL
       AND PCMOVENDPEND.NUMPED = VNUMPED
       AND PCMOVENDPEND.CODOPER LIKE 'S%'
       AND PCMOVENDPEND.DTESTORNO IS NULL;

       IF VCOUNT > 0 THEN
         RETURN 'S';
       ELSE
         RETURN 'N';
       END IF;
  END IF;

  ELSE
  RETURN 'N';

 END IF;

  RETURN 'N';

 END IF;

END;
