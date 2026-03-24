CREATE OR REPLACE PROCEDURE WMS_GERA_MOVIMENTACAO(P_NUMPED IN NUMBER, P_CODROTINA IN NUMBER)
IS
  V_NUMTRANSWMS PCMOVENDPEND.NUMTRANSWMS%TYPE;
  V_CODENDERECOPK PCMOVENDPEND.CODENDERECO%TYPE;
  V_CODENDERECOLOJA PCMOVENDPEND.CODENDERECO%TYPE;
  V_CODENDERECOVIRTUAL PCENDERECO.CODENDERECO%TYPE;
  V_DEPOSITOVIRTUAL PCENDERECO.DEPOSITO%TYPE;
  V_RUAVIRTUAL PCENDERECO.RUA%TYPE;
  V_PREDIOVIRTUAL PCENDERECO.PREDIO%TYPE;
  V_NIVELVIRTUAL PCENDERECO.NIVEL%TYPE;
  V_APTOVIRTUAL PCENDERECO.APTO%TYPE;
  V_NUMOS PCMOVENDPEND.NUMOS%TYPE;
  V_TOTENDERECOS NUMBER;
  V_SEQ NUMBER;
  V_EHENDVIRTUAL NUMBER;
  V_DEPAUTOSERVICO PCENDERECO.DEPOSITO%TYPE;
  V_GERAWMSAUTOMATICO PCPARAMETROWMS.VALOR%TYPE;
  V_TIPOENDERECO VARCHAR(3);
  V_EXISTEENDLOJA NUMBER;
  V_QTLINHASENDPK NUMBER;
  V_GERAWMSAUTOMATICOMOVPRODUCAO PCPARAMETROWMS.VALOR%TYPE;
  V_NUMBONUS PCBONUSC.NUMBONUS%TYPE;
  V_NUMSEQBONUS PCBONUSI.NUMSEQ%TYPE;

  FUNCTION FNC_GET_PROX_NUMTRANSWMS
    RETURN NUMBER
  IS
  /******************************************************************************************
     ->Nome da FUNCTION : GETPROXNUMTRANSWMS
     ->Objetivo          : Buscar o próximo NUMTRANSWMS
     ->Versao            : Pacote
     -------------------------- Alterações ---------------------------------------------------
     Data           Autor                   Tarefa      Comentários
     -----------------------------------------------------------------------------------------
     22/09/2020     Alef de Oliveira        DDWMS-5223  Função criada para solucionar problema de lock.
  *******************************************************************************************/
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_TRANSWMS NUMBER;
  BEGIN
    SELECT TRUNC(NVL(PROXNUMTRANSWMS, 1))
    INTO   V_TRANSWMS
    FROM   PCCONSUM
    FOR UPDATE WAIT 5;
    
    UPDATE PCCONSUM
    SET    PROXNUMTRANSWMS = NVL(PROXNUMTRANSWMS, 1) + 1
    WHERE  ROWNUM = 1;

    COMMIT;

    RETURN V_TRANSWMS;
  END FNC_GET_PROX_NUMTRANSWMS;
  
  FUNCTION FNC_GET_PROX_NUMBONUS
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_NUMBONUS NUMBER;
  BEGIN
    SELECT NVL(PROXNUMBONUS, 1)
    INTO   V_NUMBONUS
    FROM   PCCONSUM
    FOR UPDATE WAIT 5;
      
    UPDATE PCCONSUM
    SET    PROXNUMBONUS = NVL(PROXNUMBONUS, 1) + 1
    WHERE  ROWNUM = 1;
    
    COMMIT;
    
    RETURN V_NUMBONUS;
  END FNC_GET_PROX_NUMBONUS;
  
  PROCEDURE PRC_INSERIR_PCBONUSC
    ( P_NUMBONUS     IN PCBONUSC.NUMBONUS%TYPE,
      P_DATABONUS    IN PCBONUSC.DATABONUS%TYPE,
      P_CODFUNCBONUS IN PCBONUSC.CODFUNCBONUS%TYPE,
      P_QTNFS        IN PCBONUSC.QTNFS%TYPE,
      P_VALORTOTAL   IN PCBONUSC.VALORTOTAL%TYPE,
      P_PESOTOTAL    IN PCBONUSC.PESOTOTAL%TYPE,
      P_DATARM       IN PCBONUSC.DATARM%TYPE,
      P_CODFUNCRM    IN PCBONUSC.CODFUNCRM%TYPE,
      P_OBS          IN PCBONUSC.OBS%TYPE,
      P_DTFECHAMENTO IN PCBONUSC.DTFECHAMENTO%TYPE,
      P_CODFUNCFECHA IN PCBONUSC.CODFUNCFECHA%TYPE,
      P_CODFILIAL    IN PCBONUSC.CODFILIAL%TYPE,
      P_DTMONTAGEM   IN PCBONUSC.DTMONTAGEM%TYPE )
  AS
  BEGIN
    INSERT INTO PCBONUSC (
      NUMBONUS,
      DATABONUS,
      QTNFS,
      VALORTOTAL,
      PESOTOTAL,
      DATARM,
      CODFUNCRM,
      OBS,
      DTFECHAMENTO,
      CODFUNCBONUS,
      CODFUNCFECHA,
      CODFILIAL,
      DTMONTAGEM
    )
    VALUES (
      P_NUMBONUS,
      P_DATABONUS,
      P_QTNFS,
      P_VALORTOTAL,
      P_PESOTOTAL,
      P_DATARM,
      P_CODFUNCRM,
      P_OBS,
      P_DTFECHAMENTO,
      P_CODFUNCBONUS,
      P_CODFUNCFECHA,
      P_CODFILIAL,
      P_DTMONTAGEM
    );
  END PRC_INSERIR_PCBONUSC;
  
  PROCEDURE PRC_ALTERAR_PCBONUSC
    ( P_NUMBONUS   IN PCBONUSC.NUMBONUS%TYPE,
      P_CODFILIAL  IN PCBONUSC.CODFILIAL%TYPE,
      P_VALORTOTAL IN PCBONUSC.VALORTOTAL%TYPE,
      P_PESOTOTAL  IN PCBONUSC.PESOTOTAL%TYPE )
  AS
  BEGIN
    UPDATE PCBONUSC
    SET    VALORTOTAL = (VALORTOTAL + P_VALORTOTAL),
           PESOTOTAL = (PESOTOTAL + P_PESOTOTAL)
    WHERE  NUMBONUS = P_NUMBONUS
    AND    CODFILIAL = P_CODFILIAL;
  END PRC_ALTERAR_PCBONUSC;
  
  PROCEDURE PRC_INSERIR_PCBONUSI 
    ( P_NUMBONUS   IN PCBONUSI.NUMBONUS%TYPE,
      P_CODPROD    IN PCBONUSI.CODPROD%TYPE,
      P_QTNF       IN PCBONUSI.QTNF%TYPE,
      P_QTENTRADA  IN PCBONUSI.QTENTRADA%TYPE,
      P_ENDERECADO IN PCBONUSI.ENDERECADO%TYPE,
      P_NUMLOTE    IN PCBONUSI.NUMLOTE%TYPE,
      P_NUMSEQ     IN PCBONUSI.NUMSEQ%TYPE )
  AS
  BEGIN
    INSERT INTO PCBONUSI (
      NUMBONUS,
      CODPROD,
      QTNF,
      QTENTRADA,
      ENDERECADO,
      NUMLOTE,
      NUMSEQ          
    )
    VALUES (
      P_NUMBONUS,
      P_CODPROD,
      P_QTNF,
      P_QTENTRADA,
      P_ENDERECADO,
      P_NUMLOTE,
      P_NUMSEQ
    );    
  END PRC_INSERIR_PCBONUSI;
  
  PROCEDURE PRC_INSERIR_PCWMS
    ( P_CODFUNCCX       IN PCWMS.CODFUNCGERA%TYPE,
      P_CODFILIAL       IN PCWMS.CODFILIAL%TYPE,
      P_CODPROD         IN PCWMS.CODPROD%TYPE,
      P_QT              IN PCWMS.QT%TYPE,
      P_NUMCAR          IN PCWMS.NUMCAR%TYPE,
      P_CODFILIALORIGEM IN PCWMS.CODFILIAL%TYPE,
      P_CODOPER         IN PCWMS.CODOPER%TYPE,
      P_NUMLOTE         IN PCWMS.NUMLOTE%TYPE,
      P_CODVEICULO      IN PCWMS.CODVEICULO%TYPE,
      P_DESTINO         IN PCWMS.DESTINO%TYPE,
      P_NUMPED          IN PCWMS.NUMPED%TYPE,
      P_CODCLI          IN PCWMS.CODCLI%TYPE,
      P_CODROTINA       IN PCWMS.CODROTINA%TYPE,
      P_QTTOTPALCX       IN PCWMS.QTTOTPALCX%TYPE,
      P_QTUNITCX        IN PCWMS.QTUNITCX%TYPE,
      P_CODDISTRIB      IN PCWMS.CODDISTRIB%TYPE,
      P_DTGERACAO       IN PCWMS.DTGERACAO%TYPE,
      P_TOTPESO         IN PCWMS.TOTPESO%TYPE,
      P_TOTVOLUME       IN PCWMS.TOTVOLUME%TYPE,
      P_NUMTRANSVENDA   IN PCWMS.NUMTRANSVENDA%TYPE,
      P_NUMSEQENTREGA   IN PCWMS.NUMSEQENTREGA%TYPE,
      P_PVENDA          IN PCWMS.PVENDA%TYPE,
      P_DTENTREGA       IN PCWMS.DTENTREGA%TYPE,
      P_CODPRACA        IN PCWMS.CODPRACA%TYPE,
      P_QTAVARIA        IN PCWMS.QTAVARIA%TYPE,
      P_NUMSEQMONTAGEM  IN PCWMS.NUMSEQMONTAGEM%TYPE,
      P_QTPECAS         IN PCWMS.QTPECAS%TYPE,
      P_NUMTRANSWMS     IN PCWMS.NUMTRANSWMS%TYPE,
      P_NUMNOTA         IN PCWMS.NUMNOTA%TYPE,
      P_NUMTRANSENT     IN PCWMS.NUMTRANSENT%TYPE,
      P_NUMBONUS        IN PCWMS.NUMBONUS%TYPE )
  AS
  BEGIN      
    INSERT INTO PCWMS (
      CODFUNCGERA,
      CODPROD,
      QT,
      CODFILIALORIGEM,
      CODOPER,
      NUMCAR,
      NUMLOTE,
      CODVEICULO,
      DESTINO,
      NUMPED,
      CODCLI,
      CODROTINA,
      QTTOTPALCX,
      QTUNITCX,
      CODDISTRIB,
      DATAWMS,
      TOTPESO,
      TOTVOLUME,
      NUMTRANSVENDA,
      NUMSEQENTREGA,
      PVENDA,
      DTENTREGA,
      CODPRACA,
      CODFILIAL,
      QTAVARIA,
      NUMSEQMONTAGEM,
      QTPECAS,
      NUMTRANSWMS,
      NUMNOTA,
      NUMTRANSENT,
      NUMBONUS
    )
    VALUES (
      P_CODFUNCCX,
      P_CODPROD,
      P_QT,
      P_CODFILIALORIGEM,
      P_CODOPER,
      P_NUMCAR,
      P_NUMLOTE,
      P_CODVEICULO,
      P_DESTINO,
      P_NUMPED,
      P_CODCLI,
      P_CODROTINA,
      P_QTTOTPALCX,
      P_QTUNITCX,
      P_CODDISTRIB,
      P_DTGERACAO,
      P_TOTPESO,
      P_TOTVOLUME,
      P_NUMTRANSVENDA,
      P_NUMSEQENTREGA,
      P_PVENDA,
      P_DTENTREGA,
      P_CODPRACA,
      P_CODFILIAL,
      P_QTAVARIA,
      P_NUMSEQMONTAGEM,
      P_QTPECAS,
      P_NUMTRANSWMS,
      P_NUMNOTA,
      P_NUMTRANSENT,
      P_NUMBONUS
    );
  END PRC_INSERIR_PCWMS;
  
  FUNCTION FNC_GET_PROX_NUMOS
    RETURN NUMBER
  IS
    V_RESULT NUMBER;
  BEGIN
    SELECT DFSEQ_PCMOVENDPEND.NEXTVAL
    INTO   V_RESULT
    FROM   DUAL;
    
    RETURN V_RESULT;
  END FNC_GET_PROX_NUMOS;
  
  PROCEDURE PRC_INSERIR_PCMOVENDPEND
    ( P_CODENDERECO   IN PCMOVENDPEND.CODENDERECO%TYPE,
      P_CODPROD       IN PCMOVENDPEND.CODPROD%TYPE,
      P_QTORIG        IN PCMOVENDPEND.QTORIG%TYPE,
      P_QT            IN PCMOVENDPEND.QT%TYPE,
      P_CODOPER       IN PCMOVENDPEND.CODOPER%TYPE,
      P_HORA          IN PCMOVENDPEND.HORA%TYPE,
      P_MINUTO        IN PCMOVENDPEND.MINUTO%TYPE,
      P_NUMTRANSWMS   IN PCMOVENDPEND.NUMTRANSWMS%TYPE,
      P_NUMTRANSVENDA IN PCMOVENDPEND.NUMTRANSVENDA%TYPE,
      P_CODPRACA      IN PCMOVENDPEND.CODPRACA%TYPE,
      P_CODROTINA     IN PCMOVENDPEND.CODROTINA%TYPE,
      P_NUMCAR        IN PCMOVENDPEND.NUMCAR%TYPE,
      P_NUMPED        IN PCMOVENDPEND.NUMPED%TYPE,
      P_POSICAO       IN PCMOVENDPEND.POSICAO%TYPE,
      P_NUMBOX        IN PCMOVENDPEND.NUMBOX%TYPE,
      P_TIPOOS        IN PCMOVENDPEND.TIPOOS%TYPE,
      P_TIPOEMBALAGEM IN PCMOVENDPEND.TIPOEMBALAGEM%TYPE,
      P_DTFIMOS       IN PCMOVENDPEND.DTFIMOS%TYPE,
      P_NUMOS         IN PCMOVENDPEND.NUMOS%TYPE,
      P_CODFILIAL     IN PCMOVENDPEND.CODFILIAL%TYPE,
      P_NUMBONUS      IN PCMOVENDPEND.NUMBONUS%TYPE )
  AS
  BEGIN    
    INSERT INTO PCMOVENDPEND (
      DATA,
      CODENDERECO,
      CODPROD,
      QTORIG,
      QT,
      CODOPER,
      HORA,
      MINUTO,
      NUMTRANSWMS,
      NUMTRANSVENDA,
      CODPRACA,
      CODROTINA,
      NUMCAR,
      NUMPED,
      POSICAO,
      NUMBOX,
      TIPOOS,
      TIPOEMBALAGEM,
      DTFIMOS,
      NUMOS,
      CODFILIAL,
      NUMBONUS,
      DTENTRADA
    )
    VALUES (
      TRUNC(SYSDATE),
      P_CODENDERECO,
      P_CODPROD,
      P_QTORIG,
      P_QT,
      P_CODOPER,
      P_HORA,
      P_MINUTO,
      P_NUMTRANSWMS,
      P_NUMTRANSVENDA,
      P_CODPRACA,
      P_CODROTINA,
      P_NUMCAR,
      P_NUMPED,
      P_POSICAO,
      P_NUMBOX,
      P_TIPOOS,
      P_TIPOEMBALAGEM,
      P_DTFIMOS,
      P_NUMOS,
      P_CODFILIAL,
      P_NUMBONUS,
      NVL( ( SELECT NVL(DTENTRADA, TRUNC(SYSDATE))
             FROM   PCESTENDERECO
             WHERE  CODENDERECO = P_CODENDERECO
             AND    CODPROD = P_CODPROD
             AND    ROWNUM = 1)
           , TRUNC(SYSDATE) )
    );
  END PRC_INSERIR_PCMOVENDPEND;
  
  PROCEDURE PRC_INSERIR_PCMOVEND
    ( P_NUMSEQ      IN PCMOVEND.NUMSEQ%TYPE,
      P_DATA        IN PCMOVEND.DATA%TYPE,
      P_HORA        IN PCMOVEND.HORA%TYPE,
      P_MINUTO      IN PCMOVEND.MINUTO%TYPE,
      P_CODOPER     IN PCMOVEND.CODOPER%TYPE,
      P_CODPROD     IN PCMOVEND.CODPROD%TYPE,
      P_QT          IN PCMOVEND.QT%TYPE,
      P_CODENDERECO IN PCMOVEND.CODENDERECO%TYPE,
      P_NUMTRANSWMS IN PCMOVEND.NUMTRANSWMS%TYPE,
      P_CODROTINA   IN PCMOVEND.CODROTINA%TYPE,
      P_NUMOS       IN PCMOVEND.NUMOS%TYPE,
      P_CODFILIAL   IN PCMOVEND.CODFILIAL%TYPE,
      P_NUMPED      IN PCMOVEND.NUMPED%TYPE,
      P_NUMBONUS    IN PCMOVEND.NUMBONUS%TYPE )
  AS
  BEGIN
    INSERT INTO PCMOVEND (
      NUMSEQ,
      DATA,
      HORA,
      MINUTO,
      CODOPER,
      CODPROD,
      QT,
      CODENDERECO,
      NUMTRANSWMS,
      CODROTINA,
      NUMOS,
      CODFILIAL,
      NUMPED,
      NUMBONUS
    )
    VALUES (
      P_NUMSEQ,
      P_DATA,
      P_HORA,
      P_MINUTO,
      P_CODOPER,
      P_CODPROD,
      P_QT,
      P_CODENDERECO,
      P_NUMTRANSWMS,
      P_CODROTINA,
      P_NUMOS,
      P_CODFILIAL,
      P_NUMPED,
      P_NUMBONUS
    );
  END PRC_INSERIR_PCMOVEND;
  
  PROCEDURE PRC_INSERIR_PCESTENDERECO
    ( P_CODENDERECO IN PCESTENDERECO.CODENDERECO%TYPE,
      P_CODPROD     IN PCESTENDERECO.CODPROD%TYPE,
      P_QT          IN PCESTENDERECO.QT%TYPE,
      P_DTENTRADA   IN PCESTENDERECO.DTENTRADA%TYPE )
  AS
  BEGIN
    INSERT INTO PCESTENDERECO (
      CODENDERECO,
      CODPROD,
      QT,
      DTENTRADA )
    VALUES (
      P_CODENDERECO,
      P_CODPROD,
      P_QT,
      P_DTENTRADA );
  END PRC_INSERIR_PCESTENDERECO;
  
 PROCEDURE PRC_ALTERAR_PCESTENDERECO
   ( P_CODENDERECO  IN PCESTENDERECO.CODENDERECO%TYPE,
     P_CODPROD      IN PCESTENDERECO.CODPROD%TYPE,
     P_QT           IN PCESTENDERECO.QT%TYPE,
     P_SUBTRAIR     IN BOOLEAN DEFAULT FALSE )
  AS
  BEGIN
    IF P_SUBTRAIR THEN
      UPDATE PCESTENDERECO
      SET    QT = (QT - P_QT)
      WHERE  CODPROD = P_CODPROD
      AND    CODENDERECO = P_CODENDERECO;
    ELSE
      UPDATE PCESTENDERECO
      SET    QT = (QT + P_QT)
      WHERE  CODPROD = P_CODPROD
      AND    CODENDERECO = P_CODENDERECO;
    END IF;
    
  END PRC_ALTERAR_PCESTENDERECO;
  
  PROCEDURE PRC_INSERIR_PCPRODUTPICKING
    ( P_CODPROD        IN PCPRODUTPICKING.CODPROD%TYPE,
      P_CODFILIAL      IN PCPRODUTPICKING.CODFILIAL%TYPE,
      P_CODENDERECO    IN PCPRODUTPICKING.CODENDERECO%TYPE,
      P_TIPO           IN PCPRODUTPICKING.TIPO%TYPE,
      P_CAPACIDADE     IN PCPRODUTPICKING.CAPACIDADE%TYPE,
      P_PONTOREPOSICAO IN PCPRODUTPICKING.PONTOREPOSICAO%TYPE,
      P_TIPOESTRUTURA  IN PCPRODUTPICKING.TIPOESTRUTURA%TYPE,
      P_TIPOENDERECO   IN PCPRODUTPICKING.TIPOENDERECO%TYPE )
  AS
  BEGIN
    INSERT INTO PCPRODUTPICKING (
      CODPROD,
      CODFILIAL,
      CODENDERECO,
      TIPO,
      CAPACIDADE,
      PONTOREPOSICAO,
      TIPOESTRUTURA,
      TIPOENDERECO
    )
    VALUES (
      P_CODPROD,
      P_CODFILIAL,
      P_CODENDERECO,
      P_TIPO,
      P_CAPACIDADE,
      P_PONTOREPOSICAO,
      P_TIPOESTRUTURA,
      P_TIPOENDERECO
    );
  END PRC_INSERIR_PCPRODUTPICKING;
  
  PROCEDURE PRC_INSERIR_PCESTENDLOJA
    ( P_CODPROD        IN PCESTENDLOJA.CODPROD%TYPE,
      P_CODFILIAL      IN PCESTENDLOJA.CODFILIAL%TYPE,
      P_CODENDERECO    IN PCESTENDLOJA.CODENDERECO%TYPE,
      P_PONTOREPOSICAO IN PCESTENDLOJA.PONTOREPOSICAO%TYPE,
      P_CAPACIDADE     IN PCESTENDLOJA.CAPACIDADE%TYPE )
  AS
  BEGIN
    INSERT INTO PCESTENDLOJA (
      CODPROD,
      CODFILIAL,
      CODENDERECO,
      PONTOREPOSICAO,
      CAPACIDADE
    )
    VALUES (
      P_CODPROD,
      P_CODFILIAL,
      P_CODENDERECO,
      P_PONTOREPOSICAO,
      P_CAPACIDADE
    );    
  END PRC_INSERIR_PCESTENDLOJA;
  
  FUNCTION FNC_BUSCAR_PARAMETRO
    ( P_NOME      IN PCPARAMETROWMS.NOME%TYPE,
      P_CODFILIAL IN PCPARAMETROWMS.CODFILIAL%TYPE,
      P_DEFAULT   IN PCPARAMETROWMS.NOME%TYPE DEFAULT NULL )
    RETURN VARCHAR2
  IS
    V_RESULT VARCHAR2(100);
  BEGIN
    BEGIN
      IF P_DEFAULT IS NULL THEN
        SELECT VALOR
        INTO   V_RESULT
        FROM   PCPARAMETROWMS
        WHERE  NOME = P_NOME
        AND    CODFILIAL = P_CODFILIAL;
      ELSE
        SELECT NVL(VALOR, P_DEFAULT)
        INTO   V_RESULT
        FROM   PCPARAMETROWMS
        WHERE  NOME = P_NOME
        AND    CODFILIAL = P_CODFILIAL;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        V_RESULT := P_DEFAULT;
    END;
    
    RETURN V_RESULT;
  END FNC_BUSCAR_PARAMETRO;
  
  FUNCTION FNC_RETORNAR_ENDERECO_LOJA 
    ( P_CODPROD             IN  PCESTENDLOJA.CODPROD%TYPE,
      P_CODFILIAL           IN  PCESTENDLOJA.CODFILIAL%TYPE,
      P_QT                  IN  PCESTENDERECO.QT%TYPE )
    RETURN NUMBER
  IS
    V_RESULT NUMBER;
  BEGIN    
    BEGIN
      SELECT NVL(NVL(MAX(( SELECT MAX(CODENDERECO)
                           FROM   PCESTENDERECO
                           WHERE  CODENDERECO = E.CODENDERECO
                           AND    CODPROD = E.CODPROD
                           AND    NVL(EN.QT, 0) >= P_QT)),
                     NVL((MAX(( SELECT MAX(CODENDERECO)
                                FROM   PCESTENDERECO
                                WHERE  CODENDERECO = E.CODENDERECO
                                AND CODPROD = E.CODPROD
                                AND NVL(EN.QT, 0) > 0))),
                         MIN(E.CODENDERECO))), 0) AS CODENDERECO
      INTO   V_RESULT
      FROM   PCESTENDLOJA E
           , PCESTENDERECO EN
      WHERE  E.CODPROD = EN.CODPROD
      AND    E.CODENDERECO = EN.CODENDERECO
      AND    E.CODPROD = P_CODPROD
      AND    E.CODFILIAL = P_CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESULT := 0;
    END;

    IF V_RESULT = 0 THEN
      V_RESULT := NULL;
    END IF;
    
    RETURN V_RESULT;
  END FNC_RETORNAR_ENDERECO_LOJA;
      
  FUNCTION FNC_RETORNAR_ENDERECO_PICKING
    ( P_CODPROD                IN  PCESTENDLOJA.CODPROD%TYPE,
      P_CODFILIAL              IN  PCESTENDLOJA.CODFILIAL%TYPE,
      P_QT                     IN  PCESTENDERECO.QT%TYPE,
      P_CODENDERECOLOJA        IN  PCESTENDERECO.CODENDERECO%TYPE )
    RETURN NUMBER
  IS
    V_RESULT NUMBER;
    V_VALIDAENDBAIXAESTAUTOSERV VARCHAR2(100);
  BEGIN
    V_RESULT := 0;
    
    V_VALIDAENDBAIXAESTAUTOSERV := FNC_BUSCAR_PARAMETRO ( 'VALIDAENDERBAIXAESTOQUEAUTOSERV',
                                                          P_CODFILIAL,
                                                          'PI' );
    
    SELECT NVL(CASE V_VALIDAENDBAIXAESTAUTOSERV
                 WHEN 'PI' /* Picking venda */
                   THEN (COALESCE( ( SELECT NVL(PK.CODENDERECO, 0)
                                     FROM   PCPRODUTPICKING PK
                                     WHERE  PK.TIPO = 'V'
                                     AND    PK.CODPROD = P_CODPROD
                                     AND    PK.CODFILIAL = P_CODFILIAL )
                                 , ( SELECT NVL(PK.CODENDERECO, 0)

                                     FROM   PCPRODUTPICKING PK
                                     WHERE  PK.TIPO = 'M'
                                     AND    PK.CODPROD = P_CODPROD
                                     AND    PK.CODFILIAL = P_CODFILIAL )
                                 , 0))
                 WHEN 'PR' /* Pré-picking */
                   THEN ( SELECT NVL(PK.CODENDERECO, 0)
                          FROM   PCPRODUTPICKING PK
                          WHERE  PK.TIPO = 'P'
                          AND    PK.CODPROD = P_CODPROD
                          AND    PK.CODFILIAL = P_CODFILIAL )
                 WHEN 'PP' /* Pré-picking/ Picking venda */
                   THEN (COALESCE( ( SELECT NVL(PK.CODENDERECO, 0)
                                     FROM   PCPRODUTPICKING PK
                                     WHERE  PK.TIPO = 'P'
                                     AND    PK.CODPROD = P_CODPROD
                                     AND    PK.CODFILIAL = P_CODFILIAL )
                                 , ( SELECT NVL(PK.CODENDERECO, 0)
                                     FROM   PCPRODUTPICKING PK
                                     WHERE  PK.TIPO = 'V'
                                     AND    PK.CODPROD = P_CODPROD
                                     AND    PK.CODFILIAL = P_CODFILIAL )
                                 , 0))
                 WHEN 'EL' /* Endereço Loja */
                   THEN NVL(P_CODENDERECOLOJA, 0)

                 WHEN 'EV' /* Endereço Loja / Picking venda */
                   THEN (COALESCE( P_CODENDERECOLOJA
                                 , ( SELECT NVL(PK.CODENDERECO, 0)
                                     FROM   PCPRODUTPICKING PK
                                     WHERE  PK.TIPO = 'V'
                                     AND    PK.CODPROD = P_CODPROD
                                     AND    PK.CODFILIAL = P_CODFILIAL )
                                 , 0))
                 WHEN 'EP' /* Endereço Loja / Pré-picking */
                   THEN (COALESCE( P_CODENDERECOLOJA
                                 , ( SELECT NVL(PK.CODENDERECO, 0)
                                     FROM   PCPRODUTPICKING PK
                                     WHERE  PK.TIPO = 'P'
                                     AND    PK.CODPROD = P_CODPROD
                                     AND    PK.CODFILIAL = P_CODFILIAL )
                                 , 0))
               END, 0)
    INTO   V_RESULT
    FROM   DUAL;
    
    RETURN V_RESULT;
  END FNC_RETORNAR_ENDERECO_PICKING;
  
BEGIN
  V_NUMTRANSWMS := -1980; -- -1980 é um valor temporário
  V_SEQ := 1;
  V_NUMBONUS := 0;
  V_NUMSEQBONUS := 1;
  
  FOR REG IN ( SELECT 1 AS CONSULTA
                    , C.CODFUNCCX
                    , I.CODPROD
                    , SUM(I.QT) AS QT
                    , ( SELECT NVL(P.VALOR, P.CODFILIAL)
                        FROM   PCPARAMETROWMS P
                        WHERE  P.NOME = 'FILIALESTOQUE'
                        AND    P.CODFILIAL = C.CODFILIAL ) AS CODFILIAL
                    , NVL(MAX(I.CODFILIALRETIRA), C.CODFILIAL) AS CODFILIALORIGEM
                    , 'S' AS CODOPER
                    , C.NUMCAR
                    , NVL(I.NUMLOTE, '1') AS NUMLOTE
                    , G.CODVEICULO
                    , G.DESTINO
                    , C.NUMPED
                    , C.CODCLI
                    , 2075 AS ROTINA
                    , SUM(P.QTUNITCX * PF.QTTOTPAL) AS QTTOTPALCX
                    , P.QTUNITCX
                    , C.CODDISTRIB
                    , TRUNC(SYSDATE) AS DTGERACAO
                    , SUM(NVL(I.QT, 0) * NVL(P.PESOBRUTO, 0)) AS TOTPESO
                    , SUM(NVL(I.QT, 0) * NVL(P.VOLUME, 0)) AS TOTVOLUME
                    , C.NUMTRANSVENDA
                    , TO_CHAR(C.NUMSEQENTREGA) AS NUMSEQENTREGA
                    , NVL(SUM(I.PVENDA),0) AS PVENDA
                    , C.DTENTREGA
                    , C.CODPRACA
                    , 0 QTAVARIA
                    , NVL(C.NUMSEQMONTAGEM, 0) AS NUMSEQMONTAGEM
                    , SUM(NVL(I.QTPECAS, 0)) AS QTPECAS
                    , NVL(( SELECT 'S'
                            FROM   PCPEDICESTA IC
                            WHERE  IC.NUMPED = C.NUMPED
                            AND    IC.CODPROD = I.CODPROD
                            AND    IC.NUMSEQ = I.NUMSEQ
                            GROUP
                            BY     1 )
                          , 'N') AS EHPRODUTOACABADO
               FROM   PCPEDC C
                    , PCPEDI I
                    , PCCARREG G
                    , PCPRODUT P
                    , PCPRODFILIAL PF
               WHERE  C.NUMPED = I.NUMPED
               AND    C.NUMCAR = G.NUMCAR(+)
               AND    I.CODPROD = P.CODPROD
               AND    I.CODPROD = PF.CODPROD
               AND    C.CODFILIAL = PF.CODFILIAL
               AND    C.NUMPED = P_NUMPED
               AND    C.DTCANCEL IS NULL
               AND    P.USAWMS = 'S'
               GROUP
               BY     C.CODFUNCCX
                    , I.CODPROD
                    , C.CODFILIAL
                    , C.NUMCAR
                    , I.NUMLOTE
                    , G.CODVEICULO
                    , G.DESTINO
                    , C.NUMPED
                    , C.CODCLI
                    , P.QTUNITCX
                    , P.QTUNITCX
                    , C.CODDISTRIB
                    , C.NUMTRANSVENDA
                    , C.NUMSEQENTREGA
                    , C.DTENTREGA
                    , C.CODPRACA
                    , C.NUMSEQMONTAGEM
                    , I.NUMSEQ
             
               UNION ALL
             
               SELECT 2 AS CONSULTA
                    , C.CODFUNCCX
                    , IC.CODPRODMP CODPROD
                    , SUM(IC.QTMP) AS QT
                    , ( SELECT NVL(P.VALOR, P.CODFILIAL)
                        FROM   PCPARAMETROWMS P
                        WHERE  P.NOME = 'FILIALESTOQUE'
                        AND    P.CODFILIAL = C.CODFILIAL ) AS CODFILIAL
                    , NVL(MAX(I.CODFILIALRETIRA), C.CODFILIAL) AS CODFILIALORIGEM
                    , 'SP' AS CODOPER
                    , C.NUMCAR
                    , NVL(I.NUMLOTE, '1') AS NUMLOTE
                    , G.CODVEICULO
                    , G.DESTINO
                    , C.NUMPED
                    , C.CODCLI
                    , 2075 AS ROTINA
                    , SUM(P.QTUNITCX * PF.QTTOTPAL) AS QTTOTPALCX
                    , P.QTUNITCX
                    , C.CODDISTRIB
                    , TRUNC(SYSDATE) AS DTGERACAO
                    , SUM(NVL(IC.QTMP, 0) * NVL(P.PESOBRUTO, 0)) AS TOTPESO
                    , SUM(NVL(IC.QTMP, 0) * NVL(P.VOLUME, 0)) AS TOTVOLUME
                    , C.NUMTRANSVENDA
                    , TO_CHAR(C.NUMSEQENTREGA) AS NUMSEQENTREGA
                    , NVL(SUM(IC.PVENDA), 0) AS PVENDA
                    , C.DTENTREGA
                    , C.CODPRACA
                    , 0 AS QTAVARIA
                    , NVL(C.NUMSEQMONTAGEM, 0) AS NUMSEQMONTAGEM
                    , 0 AS QTPECAS
                    , 'N' AS EHPRODUTOACABADO
               FROM   PCPEDC C
                    , PCPEDI I
                    , PCCARREG G
                    , PCPRODUT P
                    , PCPRODFILIAL PF
                    , PCPEDICESTA  IC
               WHERE  C.NUMPED = I.NUMPED
               AND    C.NUMCAR = G.NUMCAR(+)
               AND    I.NUMPED = IC.NUMPED
               AND    I.CODPROD = IC.CODPROD
               AND    I.NUMSEQ = IC.NUMSEQ
               AND    IC.CODPRODMP = P.CODPROD
               AND    IC.CODPRODMP = PF.CODPROD
               AND    C.CODFILIAL = PF.CODFILIAL
               AND    C.NUMPED = P_NUMPED
               AND    C.DTCANCEL IS NULL
               AND    P.USAWMS = 'S'
               AND    C.CODFILIAL IN ( SELECT CODFILIAL
                                       FROM   PCPARAMETROWMS
                                       WHERE  NOME = 'GERAWMSAUTOMATICOMOVIMENTOPRODUCAO'
                                       AND    VALOR = 'S' )
               GROUP
               BY     C.CODFUNCCX
                    , IC.CODPRODMP
                    , C.CODFILIAL
                    , C.NUMCAR
                    , I.NUMLOTE
                    , G.CODVEICULO
                    , G.DESTINO
                    , C.NUMPED
                    , C.CODCLI
                    , P.QTUNITCX
                    , P.QTUNITCX
                    , C.CODDISTRIB
                    , C.NUMTRANSVENDA
                    , C.NUMSEQENTREGA
                    , C.DTENTREGA
                    , C.CODPRACA
                    , C.NUMSEQMONTAGEM
             )
  LOOP
    V_DEPAUTOSERVICO := TO_NUMBER( FNC_BUSCAR_PARAMETRO ( 'DEPOSITOAUTOSERVICO',
                                                          REG.CODFILIAL ));
    V_GERAWMSAUTOMATICO := FNC_BUSCAR_PARAMETRO ( 'GERARWMSAUTOMATICOPARAAUTOSERVICO',
                                                  REG.CODFILIAL,
                                                 'N' );
    V_TIPOENDERECO := FNC_BUSCAR_PARAMETRO ( 'VALIDAENDERBAIXAESTOQUEAUTOSERV',
                                             REG.CODFILIAL );
    
                                                     
    V_GERAWMSAUTOMATICOMOVPRODUCAO := FNC_BUSCAR_PARAMETRO( 'GERAWMSAUTOMATICOMOVIMENTOPRODUCAO',
                                                            REG.CODFILIAL,
                                                            'N' );
      
    IF (REG.CONSULTA = 1) AND (REG.EHPRODUTOACABADO = 'S') AND (V_GERAWMSAUTOMATICOMOVPRODUCAO = 'S') THEN
      IF V_NUMBONUS = 0 THEN
        V_NUMBONUS := FNC_GET_PROX_NUMBONUS;
        
        PRC_INSERIR_PCBONUSC ( V_NUMBONUS,
                               TRUNC(SYSDATE),
                               REG.CODFUNCCX,
                               1,
                               (REG.PVENDA * REG.QT),
                               REG.TOTPESO,
                               TRUNC(SYSDATE),
                               REG.CODFUNCCX,
                               'Geração automática (AutoServico.Faturamento ou 2030)',
                               SYSDATE,
                               REG.CODFUNCCX,
                               REG.CODFILIAL,
                               SYSDATE );
      ELSE
        PRC_ALTERAR_PCBONUSC ( V_NUMBONUS,
                               REG.CODFILIAL,
                               (REG.PVENDA * REG.QT),
                               REG.TOTPESO );
      END IF;
      
      PRC_INSERIR_PCBONUSI ( V_NUMBONUS,
                             REG.CODPROD,
                             REG.QT,
                             REG.QT,
                             'S',
                             REG.NUMLOTE,
                             V_NUMSEQBONUS );
      
      V_NUMSEQBONUS := V_NUMSEQBONUS + 1;
        
      PRC_INSERIR_PCWMS ( REG.CODFUNCCX,
                          REG.CODFILIAL,
                          REG.CODPROD,
                          REG.QT,
                          REG.NUMCAR,
                          REG.CODFILIALORIGEM,
                          'EP',
                          REG.NUMLOTE,
                          REG.CODVEICULO,
                          REG.DESTINO,
                          NULL,
                          REG.CODCLI,
                          REG.ROTINA,
                          REG.QTTOTPALCX,
                          REG.QTUNITCX,
                          REG.CODDISTRIB,
                          REG.DTGERACAO,
                          REG.TOTPESO,
                          REG.TOTVOLUME,
                          REG.NUMTRANSVENDA,
                          REG.NUMSEQENTREGA,
                          REG.PVENDA,
                          REG.DTENTREGA,
                          REG.CODPRACA,
                          REG.QTAVARIA,
                          REG.NUMSEQMONTAGEM,
                          REG.QTPECAS,
                          V_NUMTRANSWMS,
                          0,
                          0,
                          V_NUMBONUS );
                            
      V_CODENDERECOLOJA := FNC_RETORNAR_ENDERECO_LOJA ( REG.CODPROD,
                                                        REG.CODFILIAL,
                                                        REG.QT );
      V_CODENDERECOPK := FNC_RETORNAR_ENDERECO_PICKING ( REG.CODPROD,
                                                         REG.CODFILIAL,
                                                         REG.QT,
                                                         V_CODENDERECOLOJA );
          
      IF V_CODENDERECOPK = 0 THEN
        V_CODENDERECOPK := WMS_PROXENDVIRTUAL(REG.CODFILIAL, 'N');
            
        IF (V_DEPAUTOSERVICO IS NOT NULL) AND (V_GERAWMSAUTOMATICO = 'S') THEN
          --Validação para evitar erro de PK
          BEGIN
            V_QTLINHASENDPK := 0;
                
            SELECT COUNT(1) AS QT
            INTO   V_QTLINHASENDPK
            FROM   PCPRODUTPICKING
            WHERE  CODPROD = REG.CODPROD
            AND    CODFILIAL = REG.CODFILIAL
            AND    TIPO = 'P';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_QTLINHASENDPK := 0;
          END;
              
          IF V_QTLINHASENDPK = 0 THEN
            --Criar registro na PCPRODUTPICKING caso o parâmetro DEPOSITOAUTOSERVICO esteja preechido.
           PRC_INSERIR_PCPRODUTPICKING ( REG.CODPROD,
                                         REG.CODFILIAL,
                                         V_CODENDERECOPK,
                                         'P',
                                         1,
                                         1,
                                         1,
                                         1 );
          END IF;
              
          SELECT COUNT(1)
          INTO   V_EXISTEENDLOJA
          FROM   PCTIPOPAL
          WHERE  ENDERECOLOJA = 'S';
              
          IF (V_TIPOENDERECO = 'EL') AND (V_EXISTEENDLOJA > 0) THEN
            PRC_INSERIR_PCESTENDLOJA ( REG.CODPROD,
                                       REG.CODFILIAL,
                                       V_CODENDERECOPK,
                                       1,
                                       1 );
          END IF;              
        END IF;
      END IF;
          
      V_NUMOS := FNC_GET_PROX_NUMOS;
      
      PRC_INSERIR_PCMOVENDPEND ( V_CODENDERECOPK,
                                 REG.CODPROD,
                                 REG.QT,
                                 REG.QT,
                                 'E',
                                 TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                                 TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                                 V_NUMTRANSWMS,
                                 REG.NUMTRANSVENDA,
                                 REG.CODPRACA,
                                 P_CODROTINA,
                                 REG.NUMCAR,
                                 REG.NUMPED,
                                 'C',
                                 1,
                                 97,
                                 'M',
                                 SYSDATE,
                                 V_NUMOS,
                                 REG.CODFILIAL,
                                 V_NUMBONUS );
      
      PRC_INSERIR_PCMOVEND ( 1,
                             TRUNC(SYSDATE),
                             TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                             TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                             'E',
                             REG.CODPROD,
                             REG.QT,
                             V_CODENDERECOPK,
                             V_NUMTRANSWMS,
                             P_CODROTINA,
                             V_NUMOS,
                             REG.CODFILIAL,
                             REG.NUMPED,
                             V_NUMBONUS );
        
      SELECT COUNT(*)
      INTO   V_TOTENDERECOS
      FROM   PCESTENDERECO
      WHERE  CODPROD = REG.CODPROD
      AND    CODENDERECO = V_CODENDERECOPK;
        
      IF V_TOTENDERECOS = 0 THEN          
        PRC_INSERIR_PCESTENDERECO ( V_CODENDERECOPK,
                                    REG.CODPROD,
                                    REG.QT,
                                    TRUNC(SYSDATE) );
      ELSE
        PRC_ALTERAR_PCESTENDERECO ( V_CODENDERECOPK,
                                    REG.CODPROD,
                                    REG.QT );
      END IF;
    END IF;
      
    --SIMULANDO A ROTINA 1757
    PRC_INSERIR_PCWMS ( REG.CODFUNCCX,
                        REG.CODFILIAL,
                        REG.CODPROD,
                        REG.QT,
                        REG.NUMCAR,
                        REG.CODFILIALORIGEM,
                        REG.CODOPER,
                        REG.NUMLOTE,
                        REG.CODVEICULO,
                        REG.DESTINO,
                        REG.NUMPED,
                        REG.CODCLI,
                        REG.ROTINA,
                        REG.QTTOTPALCX,
                        REG.QTUNITCX,
                        REG.CODDISTRIB,
                        REG.DTGERACAO,
                        REG.TOTPESO,
                        REG.TOTVOLUME,
                        REG.NUMTRANSVENDA,
                        REG.NUMSEQENTREGA,
                        REG.PVENDA,
                        REG.DTENTREGA,
                        REG.CODPRACA,
                        REG.QTAVARIA,
                        REG.NUMSEQMONTAGEM,
                        REG.QTPECAS,
                        V_NUMTRANSWMS,
                        0,
                        0,
                        NULL );
      
    IF NOT ((REG.CONSULTA = 1) AND (REG.EHPRODUTOACABADO = 'S') AND (V_GERAWMSAUTOMATICOMOVPRODUCAO = 'S')) THEN
      --IDENTIFICADO O ENDERECO DE LOJA
      V_CODENDERECOLOJA := FNC_RETORNAR_ENDERECO_LOJA ( REG.CODPROD,
                                                        REG.CODFILIAL,
                                                        REG.QT );
        
      --IDENTIFICANDO O ENDERECO DO PICKING
      V_CODENDERECOPK := FNC_RETORNAR_ENDERECO_PICKING ( REG.CODPROD,
                                                         REG.CODFILIAL,
                                                         REG.QT,
                                                         V_CODENDERECOLOJA );
        
      IF V_CODENDERECOPK = 0 THEN
        V_CODENDERECOPK := WMS_PROXENDVIRTUAL(REG.CODFILIAL, 'N');
        V_EHENDVIRTUAL  := V_CODENDERECOPK;
        
        IF (V_DEPAUTOSERVICO IS NOT NULL) AND (V_GERAWMSAUTOMATICO = 'S') THEN
          --Validação para evitar erro de PK
          BEGIN
            V_QTLINHASENDPK := 0;
              
            SELECT COUNT(1)
            INTO   V_QTLINHASENDPK
            FROM   PCPRODUTPICKING
            WHERE  CODPROD = REG.CODPROD
            AND    CODFILIAL = REG.CODFILIAL
            AND    TIPO = 'P';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_QTLINHASENDPK := 0;
          END;
            
          IF V_QTLINHASENDPK = 0 THEN
            --Criar registro na PCPRODUTPICKING caso o parâmetro DEPOSITOAUTOSERVICO esteja preenchido.
            PRC_INSERIR_PCPRODUTPICKING ( REG.CODPROD,
                                          REG.CODFILIAL,
                                          V_CODENDERECOPK,
                                          'P',
                                          1,
                                          1,
                                          1,
                                          1 );                                        
          END IF;
            
          SELECT COUNT(1)
          INTO   V_EXISTEENDLOJA
          FROM   PCTIPOPAL
          WHERE  ENDERECOLOJA = 'S';
            
          IF (V_TIPOENDERECO = 'EL') AND (V_EXISTEENDLOJA > 0) THEN
            PRC_INSERIR_PCESTENDLOJA ( REG.CODPROD,
                                       REG.CODFILIAL,
                                       V_CODENDERECOPK,
                                       1,
                                       1 );
          END IF;
        END IF;
      ELSE
        V_EHENDVIRTUAL := 0;
      END IF;
    END IF;
      
    V_NUMOS := FNC_GET_PROX_NUMOS;
    
    PRC_INSERIR_PCMOVENDPEND ( V_CODENDERECOPK,
                               REG.CODPROD,
                               REG.QT,
                               REG.QT,
                               'S',
                               TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                               TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                               V_NUMTRANSWMS,
                               REG.NUMTRANSVENDA,
                               REG.CODPRACA,
                               P_CODROTINA,
                               REG.NUMCAR,
                               REG.NUMPED,
                               'C',
                               1,
                               CASE
                                 WHEN REG.CONSULTA = 1
                                   THEN 13
                                 ELSE 41
                               END,
                               'M',
                               SYSDATE,
                               V_NUMOS,
                               REG.CODFILIAL,
                               NULL);
      
    PRC_INSERIR_PCMOVEND ( V_SEQ,
                           TRUNC(SYSDATE),
                           TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                           TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                           'S',
                           REG.CODPROD,
                           REG.QT,
                           V_CODENDERECOPK,
                           V_NUMTRANSWMS,
                           P_CODROTINA,
                           V_NUMOS,
                           REG.CODFILIAL,
                           REG.NUMPED,
                           0 );
                             
    SELECT COUNT(*)
    INTO   V_TOTENDERECOS
    FROM   PCESTENDERECO
    WHERE  CODPROD = REG.CODPROD
    AND    CODENDERECO = V_CODENDERECOPK;
    
    IF V_TOTENDERECOS = 0 THEN        
      PRC_INSERIR_PCESTENDERECO ( V_CODENDERECOPK,
                                  REG.CODPROD,
                                  CASE
                                    WHEN V_EHENDVIRTUAL > 0
                                      THEN (REG.QT * -1)
                                    ELSE REG.QT
                                  END,
                                  TRUNC(SYSDATE) );
    ELSE
      PRC_ALTERAR_PCESTENDERECO ( V_CODENDERECOPK,
                                  REG.CODPROD,
                                  CASE
                                    WHEN V_EHENDVIRTUAL > 0
                                      THEN (REG.QT * -1)
                                    ELSE REG.QT
                                  END,
                                  TRUE );
    END IF;
      
    V_SEQ := V_SEQ + 1;
  END LOOP;
  
  V_NUMTRANSWMS := FNC_GET_PROX_NUMTRANSWMS;
  
  UPDATE PCWMS
  SET    NUMTRANSWMS = V_NUMTRANSWMS
  WHERE  NUMTRANSWMS = -1980;
  
  UPDATE PCMOVENDPEND
  SET    NUMTRANSWMS = V_NUMTRANSWMS
  WHERE  NUMTRANSWMS = -1980;
  
  UPDATE PCMOVEND
  SET    NUMTRANSWMS = V_NUMTRANSWMS
  WHERE  NUMTRANSWMS = -1980;
  
  UPDATE PCPEDC
  SET    DTWMS = SYSDATE
  WHERE  NUMPED = P_NUMPED;
END;
