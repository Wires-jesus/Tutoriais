CREATE OR REPLACE PACKAGE BODY FERRAMENTAS IS

  --Versão 21 Pacote
  G_GERARLOG VARCHAR2(1) := 'N';
  
  FUNCTION VERIFICAR_FJ
  (PCODCLI  NUMBER)
  RETURN VARCHAR2
  IS
  /******************************************************************************************
     ->Nome da PROCEDURE : VERIFICAR_FJ
     ->Objetivo          : Identificar se o cliente deve ser tratado como PESSOA FISICA ou PESSOA JURIDICA.
     ->Versao            : Pacote
     -------------------------- Alterações ---------------------------------------------------
     Data          Autor             Tarefa      Comentários
     ------------  ---------------   ---------------------------------------------------------
     24/10/2012    Rodrigo Santos    178297      Função criada para facilitar a identificação do TIPOFJ do cliente.
     ------------  ---------------   ---------------------------------------------------------*/
  vtipopessoa              pcclient.tipofj%type;
  vieent                   pcclient.ieent%type;
  vutilizaiesimplificada   pcclient.utilizaiesimplificada%type;
  vconsumidorfinal         pcclient.consumidorfinal%type;
  vcontribuinte            pcclient.contribuinte%type;
  VCONSIDERAISENTOSCOMOPF  VARCHAR2(1);
  VACEITAPFCONTRIBUINTE    VARCHAR2(1);
  VBFORCACLIPF    VARCHAR2(1);
  VBFORCACLIPJ    VARCHAR2(1);


  BEGIN

    SELECT NVL(PCCONSUM.CONSIDERAISENTOSCOMOPF, 'N'),
           NVL(PCCONSUM.ACEITAPFCONTRIBUINTE, 'N')
     INTO VCONSIDERAISENTOSCOMOPF,
          VACEITAPFCONTRIBUINTE
     FROM PCCONSUM;

     SELECT tipofj,
            TRIM(UPPER(ieent)),
            NVL(utilizaiesimplificada, 'N'),
            NVL(consumidorfinal, 'N'),
            DECODE(TIPOFJ, 'J',
                           NVL(contribuinte, 'N'),
                           DECODE(VACEITAPFCONTRIBUINTE, 'S',
                                                         NVL(contribuinte, 'N'),
                                                         'N')) CONTRIBUINTE,
           Forceclipf,
           FORCACLIPJ
       INTO vtipopessoa,
            vieent,
            vutilizaiesimplificada,
            vconsumidorfinal,
            vcontribuinte,
            VBFORCACLIPF,
            VBFORCACLIPJ
      FROM pcclient
     WHERE codcli = pcodcli;

    if (VBFORCACLIPF = 'S') then
      RETURN 'PESSOA FISICA';
    else
      if (VBFORCACLIPJ = 'S') then
        RETURN 'PESSOA JURIDICA';
      END IF;
    end if;

    IF (((vtipopessoa = 'F') AND
       (vutilizaiesimplificada = 'N')) OR
       (vconsumidorfinal = 'S') OR
       ((VCONSIDERAISENTOSCOMOPF = 'S') AND
       ((vieent IS NULL) OR (vieent = 'ISENTO') OR
       (vieent = 'ISENTA')))) AND
       (vcontribuinte = 'N') THEN
      RETURN 'PESSOA FISICA';
    ELSE
      RETURN 'PESSOA JURIDICA';
    END IF;



  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'CLIENTE NAO ENCONTRADO';

    WHEN OTHERS THEN
      RETURN 'NAO IDENTIFICADO';


  END VERIFICAR_FJ;

  FUNCTION VERIFICAR_ISENTOST (PCODCLI        NUMBER,
                               PCODPROD       NUMBER,
                               PCODST         NUMBER,
                               PTRANSFERENCIA VARCHAR2 DEFAULT 'N')
  RETURN VARCHAR2
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : VERIFICAR_ISENTOST
  ->Objetivo          : Definir se o cliente é isento de ST para o produto ou não.
  ->Utilizado por     : FATU_FATURA_PEDIDO
  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/01/2013    Rodrigo Santos    187291            Criada nova função para definir se o cliente é isento de ST ou não.
  22/08/2013    Rodrigo Santos    208191            Melhoria para contemplar ST e ST Fonte simultâneamente na mesma figura tributária.
  27/11/2014    Rafael Braga      4346.129538.2014  Alterado para buscar tributação da aba de transferência caso recebe o parâmetro PTRANSFERENCIA como "S".
  30/11/2015    Guilherme Freitas HIS.01257.2015    Verificando se o cliente é isento é participante do Rio Log e se a figura tributária isenta de ST os
                                                    clientes participantes do Rio Log. Adicionado cláusula para retornar como isento de ST.
   11/04/2016    Rafael Soares     Sem solicitação   Em conversa com o Silas foi retirado a validação do CONFAZ para identificar se o pedido é isento ou  não de ST,
                                                    Isso foi feito devido a este campo não ficar habilitado na 203 e ninguem saber a regra.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  vscalculast        PCCLIENT.CALCULAST%TYPE;
  vsclientefontest   PCCLIENT.CLIENTEFONTEST%TYPE;
  vsusaivadifer      PCCLIENT.USAIVAFONTEDIFERENCIADO%TYPE;
  vnivadifer         PCCLIENT.IVAFONTE%TYPE;
  vsclienteriolog    PCCLIENT.RIOLOG%TYPE;
  vsconfaz           PCPRODUT.CONFAZ%TYPE;
  vniva              PCTRIBUT.IVA%TYPE;
  vnivafonte         PCTRIBUT.IVAFONTE%TYPE;
  vnpauta            PCTRIBUT.PAUTA%TYPE;
  vnaliqicms1        PCTRIBUT.ALIQICMS1%TYPE;
  vnaliqicms2        PCTRIBUT.ALIQICMS2%TYPE;
  vnaliqicms1fonte   PCTRIBUT.ALIQICMS1FONTE%TYPE;
  vnaliqicms2fonte   PCTRIBUT.ALIQICMS2FONTE%TYPE;
  vsriologisentost   PCTRIBUT.RIOLOGISENTOST%TYPE;
  vbPF               BOOLEAN;
  vsCALCULASTPF      VARCHAR2(1);
  vsCALCULASTFONTEPF VARCHAR2(1);
  vsISENTOSTCOZINHAINDUSTRIAL VARCHAR2(1);
  vsCOZINHAINDUSTRIAL         VARCHAR2(1);
  BEGIN

  vbPF := (VERIFICAR_FJ(PCODCLI) = 'PESSOA FISICA');

  vsCALCULASTPF      := PARAMETROS.getVALORALFANVL('CON_CALCSTPF','99','N');
  vsCALCULASTFONTEPF := PARAMETROS.getVALORALFANVL('CON_CALCSTFONTEPF','99','N');

  SELECT NVL(PCCLIENT.CALCULAST,'S'),
         NVL(PCCLIENT.CLIENTEFONTEST,'N'),
         NVL(PCCLIENT.USAIVAFONTEDIFERENCIADO,'N'),
         NVL(PCCLIENT.IVAFONTE,0),
         NVL(PCCLIENT.RIOLOG, 'N'),
         NVL(COZINHAINDUSTRIAL, 'N')
    INTO vscalculast,
         vsclientefontest,
         vsusaivadifer,
         vnivadifer,
         vsclienteriolog,
         vsCOZINHAINDUSTRIAL
    FROM PCCLIENT
   WHERE CODCLI = PCODCLI;

  SELECT CONFAZ, nvl(ISENTOSTCOZINHAINDUSTRIAL, 'N')
    INTO vsconfaz, vsISENTOSTCOZINHAINDUSTRIAL
    FROM PCPRODUT
   WHERE CODPROD = PCODPROD;

  SELECT DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.IVA,0), NVL(PCTRIBUT.IVATRANSF,0)),
         DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.IVAFONTE,0), NVL(PCTRIBUT.IVATRANSF,0)),
         DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.PAUTA,0), NVL(PCTRIBUT.PAUTATRANSF,0)),
         DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.ALIQICMS1,0), NVL(PCTRIBUT.ALIQICMS1TRANSF, 0)),
         DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.ALIQICMS2,0), NVL(PCTRIBUT.ALIQICMS2TRANSF,0)),
         DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.ALIQICMS1FONTE,0) , NVL(PCTRIBUT.ALIQICMS1TRANSF, 0)),
         DECODE(PTRANSFERENCIA, 'N', NVL(PCTRIBUT.ALIQICMS2FONTE,0), NVL(PCTRIBUT.ALIQICMS2TRANSF,0)),
         NVL(PCTRIBUT.RIOLOGISENTOST, 'N')
    INTO vniva,
         vnivafonte,
         vnpauta,
         vnaliqicms1,
         vnaliqicms2,
         vnaliqicms1fonte,
         vnaliqicms2fonte,
         vsriologisentost
    FROM PCTRIBUT
   WHERE CODST = PCODST;


  IF vsusaivadifer = 'S' THEN
    vnivafonte := vnivadifer;
  END IF;

  --1ª VERIFICAÇÃO (Tarefa: 208191)
  IF ((vbPF) AND (vsCALCULASTFONTEPF = 'N')) and
     ((vnivafonte > 0) OR (vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)) THEN
    RETURN 'S';
  ELSIF ((vbPF) AND (vsCALCULASTPF = 'N')) and
        ((vniva > 0) OR (vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))  THEN
    RETURN 'S';
  END IF;

  --2ª VERIFICAÇÃO (Tarefa: 208191)
  CASE
    WHEN (vsISENTOSTCOZINHAINDUSTRIAL = 'S') AND (vsCOZINHAINDUSTRIAL = 'S')
    THEN

         RETURN 'S';

    WHEN ((vniva > 0) OR (vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0)) --COM ST NORMAL
      AND ((vnivafonte > 0) OR (vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)) --COM ST FONTE
      AND ((vsclientefontest = 'N') AND (vscalculast = 'N')) --CLIENTE ISENTO DE ST E ST FONTE
    THEN

      RETURN 'S';

    WHEN ((vniva > 0) OR (vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0)) --COM ST NORMAL
      AND (NOT ((vnivafonte > 0) OR (vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --SEM ST FONTE
      AND ((vscalculast = 'N')) --CLIENTE ISENTO DE ST
    THEN

      RETURN 'S';

    WHEN (NOT ((vniva > 0) OR (vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --SEM ST NORMAL
      AND ((vnivafonte > 0) OR (vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)) --COM ST FONTE
      AND ((vsclientefontest = 'N') AND (vscalculast = 'N')) --CLIENTE ISENTO DE ST FONTE
    THEN

      RETURN 'S';

    --RIO LOG ISENTO DE ST
    WHEN (vsclienteriolog = 'S') AND (vsriologisentost = 'S')
    THEN

      RETURN 'S';

    ELSE

      RETURN 'N';

  END CASE;


  END VERIFICAR_ISENTOST;


  FUNCTION VERIFICAR_TIPOST (PCODCLI  NUMBER,
                             PCODST   NUMBER)
  RETURN VARCHAR2
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : VERIFICAR_TIPOST
  ->Objetivo          : Definir qual o tipo de ST será calculado.
  ->Utilizado por     : FATU_FATURA_PEDIDO
  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  22/08/2013    Rodrigo Santos    208191  Melhoria para contemplar ST e ST Fonte simultâneamente na mesma figura tributária.
  08/08/2014    Lucas Lima        085202  Tratado problema referente a st e st fonte na mesma figura. (OR -> AND após verificação do
                                          IVA em todas as cláusulas).
  ------------  ---------------   ---------------------------------------------------------------------------*/
  vscalculast        PCCLIENT.CALCULAST%TYPE;
  vsclientefontest   PCCLIENT.CLIENTEFONTEST%TYPE;
  vsusaivadifer      PCCLIENT.USAIVAFONTEDIFERENCIADO%TYPE;
  vnivadifer         PCCLIENT.IVAFONTE%TYPE;
  vniva              PCTRIBUT.IVA%TYPE;
  vnivafonte         PCTRIBUT.IVAFONTE%TYPE;
  vnpauta            PCTRIBUT.PAUTA%TYPE;
  vnaliqicms1        PCTRIBUT.ALIQICMS1%TYPE;
  vnaliqicms2        PCTRIBUT.ALIQICMS2%TYPE;
  vnaliqicms1fonte   PCTRIBUT.ALIQICMS1FONTE%TYPE;
  vnaliqicms2fonte   PCTRIBUT.ALIQICMS2FONTE%TYPE;
  vnusavalorstfonte  PCTRIBUT.USAVALORSTFONTE%TYPE;

  BEGIN

  SELECT NVL(PCCLIENT.CALCULAST, 'S'),
         NVL(PCCLIENT.CLIENTEFONTEST, 'N'),
         NVL(PCCLIENT.USAIVAFONTEDIFERENCIADO,'N'),
         NVL(PCCLIENT.IVAFONTE,0)
    INTO vscalculast,
         vsclientefontest,
         vsusaivadifer,
         vnivadifer
    FROM PCCLIENT
   WHERE CODCLI = PCODCLI;

  SELECT NVL(PCTRIBUT.IVA,0),
         NVL(PCTRIBUT.IVAFONTE,0),
         NVL(PCTRIBUT.PAUTA,0),
         NVL(PCTRIBUT.ALIQICMS1,0),
         NVL(PCTRIBUT.ALIQICMS2,0),
         NVL(PCTRIBUT.ALIQICMS1FONTE,0),
         NVL(PCTRIBUT.ALIQICMS2FONTE,0),
         NVL(PCTRIBUT.USAVALORSTFONTE,'N')
    INTO vniva,
         vnivafonte,
         vnpauta,
         vnaliqicms1,
         vnaliqicms2,
         vnaliqicms1fonte,
         vnaliqicms2fonte,
         vnusavalorstfonte

    FROM PCTRIBUT
   WHERE CODST = PCODST;

  IF vsusaivadifer = 'S' THEN
    vnivafonte := vnivadifer;
  END IF;

  CASE
    --1º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0)) OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'S') AND (vscalculast = 'S')) --CLIENTE ISENTO DE ST E ST FONTE
    THEN

      RETURN 'ST FONTE';

    --2º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0)) OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'N') AND (vscalculast = 'S')) --CLIENTE ISENTO DE ST FONTE
    THEN

      RETURN 'ST NORMAL';

    --3º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0)) OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'S') AND (vscalculast = 'N')) --CLIENTE ISENTO DE ST
    THEN

      RETURN 'SEM ST';

    --4º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'N') AND (vscalculast = 'N')) --CLIENTE ISENTO DE ST E ISENTO DE ST FONTE
    THEN

      RETURN 'SEM ST';

    --5º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND (NOT ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)))) --SEM ST FONTE
      AND (vnusavalorstfonte <> 'S')--ADicionado verificação da flag que força ser stfonte mesmo se estiver sem aliquota
      AND ((vsclientefontest = 'S') AND (vscalculast = 'S')) --CLIENTE NÃO ISENTO DE ST E NÃO ISENTO DE ST FONTE
    THEN

      RETURN 'ST NORMAL';

    --6º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND (NOT ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)))) --SEM ST FONTE
      AND ((vsclientefontest = 'N') AND (vscalculast = 'S')) --CLIENTE ISENTO DE ST FONTE
    THEN

      RETURN 'ST NORMAL';

    --7º TESTE
    WHEN (NOT (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0)))) --SEM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'S') AND (vscalculast = 'S')) --CLIENTE NÃO ISENTO DE ST E NÃO ISENTO DE ST FONTE
    THEN

      RETURN 'ST FONTE';

    --8º TESTE
    WHEN (NOT (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0)))) --SEM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'S') AND (vscalculast = 'N')) --CLIENTE NÃO ISENTO DE ST E NÃO ISENTO DE ST FONTE
    THEN

      RETURN 'SEM ST';

    --9º TESTE
    WHEN (NOT (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0)))) --SEM ST NORMAL
      AND (NOT ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)))) --SEM ST FONTE
    THEN

      RETURN 'SEM ST';

    --10º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND (NOT ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)))) --SEM ST FONTE
      AND ((vsclientefontest = 'N') AND (vscalculast = 'S')) --CLIENTE NÃO ISENTO DE ST E ISENTO DE ST FONTE
    THEN

      RETURN 'ST NORMAL';

    --11º TESTE
    WHEN (NOT (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0)))) --SEM ST NORMAL
      AND ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) --COM ST FONTE
      AND ((vsclientefontest = 'S') AND (vscalculast = 'N')) --CLIENTE ISENTO DE ST E NÃO ISENTO DE ST FONTE
    THEN

      RETURN 'SEM ST';

    --12º TESTE
    WHEN (((vniva > 0) OR (vnpauta > 0))  OR ((vnaliqicms1 > 0) OR (vnaliqicms2 > 0) OR (vnpauta > 0))) --COM ST NORMAL
      AND (NOT ((vnivafonte > 0) OR ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0)))) --SEM ST FONTE
      AND (vnusavalorstfonte = 'S')--ADicionado verificação da flag que força ser stfonte mesmo se estiver sem aliquota
      AND ((vsclientefontest = 'S') AND (vscalculast = 'S')) --CLIENTE NÃO ISENTO DE ST
    THEN

     RETURN 'ST FONTE';

    ELSE

      RETURN 'SEM ST';

  END CASE;


  END VERIFICAR_TIPOST;


  FUNCTION F_PROX_NUMCAR
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_NUMCAR
  ->Objetivo          : Buscar o próximo NUMCAR em transação autônoma(separada).
  ->Utilizado por     : FATURAMENTO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  26/02/2013    Rodrigo Santos            Criada nova função F_PROX_NUMCAR.
  29/05/2013    Rodrigo Santos    200414  Tratamento para retornar zero sempre que ocorrer exceção.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_numcar  NUMBER;
  BEGIN

    SELECT NVL(proxnumcar, 0)
      INTO v_numcar
      FROM pcconsum
     WHERE ROWNUM = 1
       FOR UPDATE NOWAIT;

    UPDATE pcconsum
       SET proxnumcar = NVL(proxnumcar, 0) + 1
     WHERE ROWNUM = 1;

    COMMIT;

    RETURN v_numcar;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN 0;
  END F_PROX_NUMCAR;

  FUNCTION F_PROX_NUMTRANS
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_NUMTRANS
  ->Objetivo          : Buscar o próximo NUMTRANS em transação autônoma(separada).
  ->Utilizado por     : PCSIS1402

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  22/10/2013    Rodrigo Santos            Criada nova função F_PROX_NUMTRANS.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_numtrans  NUMBER;
  BEGIN

    SELECT NVL(PROXNUMTRANS,0)
      INTO v_numtrans
      FROM pcconsum
     WHERE ROWNUM = 1
       FOR UPDATE NOWAIT;

    UPDATE pcconsum
       SET proxnumtrans = NVL(proxnumtrans, 0) + 1
     WHERE ROWNUM = 1;

    COMMIT;

    RETURN v_numtrans;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN 0;
  END F_PROX_NUMTRANS;

  FUNCTION F_PROX_NUMTRANSVENDA(P_INCREMENTO IN NUMBER DEFAULT 1)
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_NUMTRANSVENDA
  ->Objetivo          : Buscar o próximo NUMTRANSVENDA em transação autônoma(separada).
  ->Utilizado por     : FATURAMENTO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/01/2013    Rodrigo Santos            Criada nova função F_PROX_NUMTRANSVENDA.
  29/05/2013    Rodrigo Santos    200414  Tratamento para retornar zero sempre que ocorrer exceção.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_numtransvenda  NUMBER;
  v_INCREMENTO NUMBER;
  v_Count         NUMBER := 0;
  v_Id            NUMBER(15);
  V_SQLERRM       VARCHAR2(300);
  BEGIN

    SELECT TRUNC(DBMS_RANDOM.VALUE(1, 999999999999999))
      INTO v_Id
      FROM DUAL;

	  v_INCREMENTO := NVL(P_INCREMENTO,0);

    IF  v_INCREMENTO < 1 THEN
       v_INCREMENTO  := 1;
    END IF;

   WHILE v_Count <= 5 LOOP
    v_Count := v_Count + 1;
    BEGIN
      SELECT NVL(proxnumtransvenda, 0)
        INTO v_numtransvenda
        FROM pcconsum
       WHERE ROWNUM = 1
         FOR UPDATE NOWAIT;

        UPDATE pcconsum
           SET proxnumtransvenda = NVL(proxnumtransvenda, 0) + v_INCREMENTO
         WHERE ROWNUM = 1;

        COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
        V_SQLERRM       := '1- Erro ao buscar prox. numtransvenda: ' || SQLERRM;
        v_numtransvenda := 0;

        --Gravar log dos look no banco
        PKG_LOG.GRAVAR_LOG_PARAMETRO('PCCONSUM',
                                     V_SQLERRM,
                                     V_Id,
                                     v_Count);

        -- Na segunda tentativa sem sucesso propagar erro
        IF (v_Count >= 2) THEN
          RAISE;
        END IF;
    END;

    IF (v_numtransvenda = 0) THEN
      F_SLEEP(1);
    ELSE
      v_Count := 10;
    END IF;
   END LOOP;

    RETURN v_numtransvenda;

  EXCEPTION
    WHEN OTHERS THEN
      V_SQLERRM := '2- Erro ao buscar prox. numtransvenda: ' || SQLERRM;
      PKG_LOG.GRAVAR_LOG_PARAMETRO('PCCONSUM', V_SQLERRM, V_Id, v_Count);
      ROLLBACK;
      RETURN 0;
  END F_PROX_NUMTRANSVENDA;


  FUNCTION F_PROX_NUMTRANSENT(P_INCREMENTO IN NUMBER DEFAULT 1)
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_NUMTRANSENT
  ->Objetivo          : Buscar o próximo NUMTRANSENT em transação autônoma(separada).
  ->Utilizado por     : FATURAMENTO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/01/2013    Rodrigo Santos            Criada nova função F_PROX_NUMTRANSENT.
  29/05/2013    Rodrigo Santos    200414  Tratamento para retornar zero sempre que ocorrer exceção.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_numtransent  NUMBER;
  v_INCREMENTO NUMBER;
  BEGIN
  
	v_INCREMENTO := NVL(P_INCREMENTO,0);
    
    IF  v_INCREMENTO < 1 THEN
       v_INCREMENTO  := 1;
    END IF;

    SELECT NVL(proxnumtransent, 0)
      INTO v_numtransent
      FROM pcconsum
     WHERE ROWNUM = 1
       FOR UPDATE NOWAIT;

    UPDATE pcconsum
       SET proxnumtransent = NVL(proxnumtransent, 0) + v_INCREMENTO
     WHERE ROWNUM = 1;

    COMMIT;

    RETURN v_numtransent;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN 0;
  END F_PROX_NUMTRANSENT;

  FUNCTION F_PROX_RECNUM
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_RECNUM
  ->Objetivo          : Buscar o próximo NUMLANC em transação autônoma(separada).
  ->Utilizado por     : FATURAMENTO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/01/2013    Rodrigo Santos            Criada nova função F_PROX_RECNUM.
  29/05/2013    Rodrigo Santos    200414  Tratamento para retornar zero sempre que ocorrer exceção.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  vnproxnumtemp  NUMBER;
  BEGIN

    SELECT NVL(pcconsum.proxnumlanc, 1)
      INTO vnproxnumtemp
      FROM pcconsum
     WHERE ROWNUM = 1
       FOR UPDATE;

    UPDATE pcconsum
       SET proxnumlanc = NVL(proxnumlanc, 1) + 1
     WHERE ROWNUM = 1;

    COMMIT;

    RETURN vnproxnumtemp;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN 0;
  END F_PROX_RECNUM;

 FUNCTION F_PROX_NUMPED(PCODUSUR NUMBER)
 RETURN NUMBER
 IS
 /************************************************************************************************************
 ->Nome da FUNCTION  : F_PROX_NUMPED
 ->Objetivo          : Buscar o próximo NUMPED em transação autônoma(separada).
 ->Utilizado por     : ALTERAR PEDIDO DE VENDA(336)

 -------------------------------- Historico ------------------------------------------------------------------
 Data          Responsavel       Tarefa               Comentarios
 ------------  ---------------   ------  ----------------------------------------------------------------------
 26/02/2013    Iran Junior       4693.010291.2015      Criada nova função F_PROX_NUMPED.
 ------------  ---------------   ---------------------------------------------------------------------------*/
 PRAGMA AUTONOMOUS_TRANSACTION;
 v_numped  NUMBER;
 BEGIN

   SELECT NVL(proxnumped, 0)
     INTO v_numped
     FROM pcusuari
    WHERE codusur = PCODUSUR
      FOR UPDATE;

   UPDATE pcusuari
      SET proxnumped = NVL(proxnumped, 0) + 1
    WHERE codusur = PCODUSUR;

   COMMIT;

   RETURN v_numped;

 EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     RETURN 0;
 END F_PROX_NUMPED;

FUNCTION F_PROX_CODCLI
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_CODCLI
  ->Objetivo          : Buscar o próximo código cliente em transação autônoma(separada).
  ->Utilizado por     : IMPORTARCADASTRO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/10/2017    Rodrigo Santos            Criada nova função F_PROX_CODCLI.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  VNPROXNUMCLI  NUMBER;
 BEGIN

    SELECT NVL(PCCONSUM.PROXNUMCLI, 1)
      INTO VNPROXNUMCLI
      FROM PCCONSUM
       FOR UPDATE;

    UPDATE PCCONSUM 
	SET PROXNUMCLI = NVL(PCCONSUM.PROXNUMCLI, 0) + 1;

    COMMIT;

    RETURN VNPROXNUMCLI;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN 0;
 END F_PROX_CODCLI;

FUNCTION F_COMPARARCNPJ (PCODCLI1 NUMBER,
                         PCODCLI2 NUMBER)
 RETURN BOOLEAN
IS
  /******************************************************************************************
  ->Nome da FUNCTION  : F_COMPARARCNPJ
  ->Objetivo          : Comparar dois CNPJs retornando TRUE caso possuam o mesmo radical, ou seja,
                        se o cliente1 é filial do cliente2 ou vice-versa.
  ->Utilizado por     : Uso Externo
  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  22/05/2013    Rodrigo Santos    000000  Criação da função.
  ------------  ---------------   ---------------------------------------------------------------------------*/
VNCOUNT NUMBER;
BEGIN

  SELECT CASE
           WHEN (SELECT SUBSTR(REGEXP_REPLACE(PCCLIENT.CGCENT,'[^0-9]',''),
                               0,8)
                   FROM PCCLIENT
                  WHERE CODCLI = PCODCLI1) =
                (SELECT SUBSTR(REGEXP_REPLACE(PCCLIENT.CGCENT,'[^0-9]',''),
                               0,8)
                   FROM PCCLIENT
                  WHERE CODCLI = PCODCLI2)
           THEN
            1
           ELSE
            0
         END
    INTO VNCOUNT
    FROM DUAL;

  RETURN (VNCOUNT = 1);

END F_COMPARARCNPJ;

PROCEDURE Recontar_NUMSEQ(PNUMPED PCPEDC.NUMPED%TYPE)
IS
  /******************************************************************************************
  ->Nome da FUNCTION  : Recontar_NUMSEQ
  ->Objetivo          : Redefinir o valor dos campos NUMSEQ de todas as tabelas envolvidas no processo de venda.
  ->Utilizado por     : Uso Externo
  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  07/05/2013    Rafael Braga      197200  Ajuste para prevenir erro de PK na tabela PCORIGEMPRECO(Validado no cliente).
  10/05/2013    Rodrigo Santos    198311  Implementação de nova tentativa com ordem inversa do ROWID caso ocorra erro.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  vnmax_numseq   NUMBER;
  BEGIN

    BEGIN --Primeira tentativa na ordem comum do ROWID --> Tarefa: 198311

      --Recontando NUMSEQ da PCORCAVENDAI
      FOR CR_ORCAVENDAI IN (SELECT ROWNUM NOVO_NUMSEQ,
                             tb.NUMSEQ,
                             tb.CODPROD, tb.tipomerc
                        FROM (select numseq, codprod,
                             (SELECT TIPOMERC
                                FROM PCPRODUT
                               WHERE CODPROD = PCORCAVENDAI.CODPROD) AS TIPOMERC
                        FROM PCORCAVENDAI
                       WHERE NUMORCA = PNUMPED
                       ORDER BY ROWID) tb) LOOP

        UPDATE PCORCAVENDAI
           SET NUMSEQ = CR_ORCAVENDAI.NOVO_NUMSEQ
         WHERE NUMORCA = PNUMPED
           AND CODPROD = CR_ORCAVENDAI.CODPROD
           AND NUMSEQ = CR_ORCAVENDAI.NUMSEQ;

        IF CR_ORCAVENDAI.TIPOMERC = 'CB' THEN
          UPDATE PCORCAVENDAICESTA
             SET NUMSEQ = CR_ORCAVENDAI.NOVO_NUMSEQ
           WHERE CODPROD = CR_ORCAVENDAI.CODPROD
             AND NUMSEQ = CR_ORCAVENDAI.NUMSEQ
             AND NUMORCA = PNUMPED;
        END IF;

      END LOOP;

      --Recontando NUMSEQ da PCORIGEMPRECO com base na PCPEDI
      FOR CR_ORIGEMPRECO IN (SELECT ROWNUM NOVO_NUMSEQ, tb.NUMSEQ, tb.CODPROD /* alteração, tabela virtual TB para o select */
                               FROM (select numseq, codprod
                                       FROM PCPEDI
                                      WHERE NUMPED = PNUMPED
                              --ORDER BY NUMSEQ  Tarefa: 184743
                              ORDER BY ROWID) tb) LOOP

        UPDATE PCORIGEMPRECO
           SET NUMSEQ = CR_ORIGEMPRECO.NOVO_NUMSEQ
         WHERE NUMPED = PNUMPED
           AND CODPROD = CR_ORIGEMPRECO.CODPROD
           AND NUMSEQ = CR_ORIGEMPRECO.NUMSEQ;

      END LOOP;

      --Recontando NUMSEQ da PCLOGRCA COM BASE
      FOR CR_LOGRCA IN (SELECT ROWNUM NOVO_NUMSEQ, tb.NUMSEQ, tb.CODPROD /* alteração, tabela virtual TB para o select */
                          FROM (select numseq, codprod
                                  FROM PCPEDI
                                 WHERE NUMPED = PNUMPED
                              --ORDER BY NUMSEQ  Tarefa: 184743
                              ORDER BY ROWID) tb) LOOP

        UPDATE PCLOGRCA
           SET NUMSEQ = CR_LOGRCA.NOVO_NUMSEQ
         WHERE CODPROD = CR_LOGRCA.CODPROD
           AND NUMPED = PNUMPED
           AND NUMSEQ = CR_LOGRCA.NUMSEQ;


      END LOOP;


      --Recontando NUMSEQ da PCPEDI
      FOR CR_PEDI IN (SELECT ROWNUM NOVO_NUMSEQ,
                             tb.NUMSEQ,
                             tb.CODPROD, tb.tipomerc
                        FROM (select numseq, codprod,
                             (SELECT TIPOMERC
                                FROM PCPRODUT
                               WHERE CODPROD = PCPEDI.CODPROD) AS TIPOMERC
                        FROM PCPEDI
                       WHERE NUMPED = PNUMPED
                       --ORDER BY NUMSEQ  Tarefa: 184743
                       ORDER BY ROWID) tb) LOOP

        UPDATE PCPEDI
           SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
         WHERE NUMPED = PNUMPED
           AND CODPROD = CR_PEDI.CODPROD
           AND NUMSEQ = CR_PEDI.NUMSEQ;

        IF CR_PEDI.TIPOMERC = 'CB' THEN
          UPDATE PCPEDICESTA
             SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
           WHERE CODPROD = CR_PEDI.CODPROD
             AND NUMPED = PNUMPED
             AND NUMSEQ = CR_PEDI.NUMSEQ;
        END IF;

        UPDATE PCPEDIFILHO
           SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
         WHERE CODPROD = CR_PEDI.CODPROD
           AND NUMPED = PNUMPED
           AND NUMSEQ = CR_PEDI.NUMSEQ;

        UPDATE PCNFCANITEM
           SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
         WHERE CODPROD = CR_PEDI.CODPROD
           AND NUMPED = PNUMPED
           AND NUMSEQ = CR_PEDI.NUMSEQ;


      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        BEGIN --Segunda tentativa na ordem inversa do ROWID --> Tarefa: 198311
          vnmax_numseq := 0;

          --Recontando NUMSEQ da PCORCAVENDAI
          SELECT (MAX(NUMSEQ) + 1) INTO VNMAX_NUMSEQ
              FROM PCORCAVENDAI
             WHERE NUMORCA = PNUMPED;

          FOR CR_ORCAVENDAI IN (SELECT ROWNUM NOVO_NUMSEQ,
                             tb.NUMSEQ,
                             tb.CODPROD, tb.tipomerc
                        FROM (select numseq, codprod,
                             (SELECT TIPOMERC
                                FROM PCPRODUT
                               WHERE CODPROD = PCORCAVENDAI.CODPROD) AS TIPOMERC
                        FROM PCORCAVENDAI
                       WHERE NUMORCA = PNUMPED
                       ORDER BY ROWID DESC) tb) LOOP

            UPDATE PCORCAVENDAI
               SET NUMSEQ = CR_ORCAVENDAI.NOVO_NUMSEQ
             WHERE NUMORCA = PNUMPED
               AND CODPROD = CR_ORCAVENDAI.CODPROD
               AND NUMSEQ = CR_ORCAVENDAI.NUMSEQ;

            IF CR_ORCAVENDAI.TIPOMERC = 'CB' THEN
              UPDATE PCORCAVENDAICESTA
                 SET NUMSEQ = CR_ORCAVENDAI.NOVO_NUMSEQ
               WHERE CODPROD = CR_ORCAVENDAI.CODPROD
                 AND NUMSEQ = CR_ORCAVENDAI.NUMSEQ
                 AND NUMORCA = PNUMPED;
            END IF;

          END LOOP;

          --Recontando NUMSEQ da PCORIGEMPRECO com base na PCPEDI
          select (max(numseq) + 1) into vnmax_numseq
              from PCORIGEMPRECO
             where numped = PNUMPED;

            for cr_max in (select numseq, codprod from PCORIGEMPRECO
                            where numped = PNUMPED)
            LOOP
              update PCORIGEMPRECO
                 set numseq = vnmax_numseq
               where numped = PNUMPED
                 and codprod = cr_max.codprod
                 and numseq = cr_max.numseq;

              vnmax_numseq := vnmax_numseq + 1;
            end loop;

          FOR CR_ORIGEMPRECO IN (SELECT ROWNUM NOVO_NUMSEQ, tb.NUMSEQ, tb.CODPROD /* alteração, tabela virtual TB para o select */
                                   FROM (select numseq, codprod
                                           FROM PCPEDI
                                          WHERE NUMPED = PNUMPED
                                  --ORDER BY NUMSEQ  Tarefa: 184743
                                  ORDER BY ROWID DESC) tb) LOOP

            UPDATE PCORIGEMPRECO
               SET NUMSEQ = CR_ORIGEMPRECO.NOVO_NUMSEQ
             WHERE NUMPED = PNUMPED
               AND CODPROD = CR_ORIGEMPRECO.CODPROD
               AND NUMSEQ = CR_ORIGEMPRECO.NUMSEQ;

          END LOOP;

          --Recontando NUMSEQ da PCLOGRCA COM BASE
          select (max(numseq) + 1) into vnmax_numseq
              from PCLOGRCA
             where numped = PNUMPED;

            for cr_max in (select numseq, codprod from PCLOGRCA
                            where numped = PNUMPED)
            LOOP
              update PCLOGRCA
                 set numseq = vnmax_numseq
               where numped = PNUMPED
                 and codprod = cr_max.codprod
                 and numseq = cr_max.numseq;

              vnmax_numseq := vnmax_numseq + 1;
            end loop;

          FOR CR_LOGRCA IN (SELECT ROWNUM NOVO_NUMSEQ, tb.NUMSEQ, tb.CODPROD /* alteração, tabela virtual TB para o select */
                              FROM (select numseq, codprod
                                      FROM PCPEDI
                                     WHERE NUMPED = PNUMPED
                                  --ORDER BY NUMSEQ  Tarefa: 184743
                                  ORDER BY ROWID DESC) tb) LOOP

            UPDATE PCLOGRCA
               SET NUMSEQ = CR_LOGRCA.NOVO_NUMSEQ
             WHERE CODPROD = CR_LOGRCA.CODPROD
               AND NUMPED = PNUMPED
               AND NUMSEQ = CR_LOGRCA.NUMSEQ;


          END LOOP;


          --Recontando NUMSEQ da PCPEDI
          select (max(numseq) + 1) into vnmax_numseq
              from PCPEDI
             where numped = PNUMPED;

            for cr_max in (select numseq, codprod from PCPEDI
                            where numped = PNUMPED)
            LOOP
              update PCPEDI
                 set numseq = vnmax_numseq
               where numped = PNUMPED
                 and codprod = cr_max.codprod
                 and numseq = cr_max.numseq;

              vnmax_numseq := vnmax_numseq + 1;
            end loop;

          FOR CR_PEDI IN (SELECT ROWNUM NOVO_NUMSEQ,
                                 tb.NUMSEQ,
                                 tb.CODPROD, tb.tipomerc
                            FROM (select numseq, codprod,
                                 (SELECT TIPOMERC
                                    FROM PCPRODUT
                                   WHERE CODPROD = PCPEDI.CODPROD) AS TIPOMERC
                            FROM PCPEDI
                           WHERE NUMPED = PNUMPED
                           --ORDER BY NUMSEQ  Tarefa: 184743
                           ORDER BY ROWID DESC) tb) LOOP

            UPDATE PCPEDI
               SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
             WHERE NUMPED = PNUMPED
               AND CODPROD = CR_PEDI.CODPROD
               AND NUMSEQ = CR_PEDI.NUMSEQ;

            IF CR_PEDI.TIPOMERC = 'CB' THEN
              UPDATE PCPEDICESTA
                 SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
               WHERE CODPROD = CR_PEDI.CODPROD
                 AND NUMPED = PNUMPED
                 AND NUMSEQ = CR_PEDI.NUMSEQ;
            END IF;

            UPDATE PCPEDIFILHO
               SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
             WHERE CODPROD = CR_PEDI.CODPROD
               AND NUMPED = PNUMPED
               AND NUMSEQ = CR_PEDI.NUMSEQ;

            UPDATE PCNFCANITEM
               SET NUMSEQ = CR_PEDI.NOVO_NUMSEQ
             WHERE CODPROD = CR_PEDI.CODPROD
               AND NUMPED = PNUMPED
               AND NUMSEQ = CR_PEDI.NUMSEQ;

          END LOOP;

        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
        END;
    END;

    COMMIT;

  END Recontar_NUMSEQ;

  FUNCTION F_RETORNARLISTA(PLISTA     VARCHAR2,
                           PSEPARADOR VARCHAR2)
    RETURN TD_LISTA
    PARALLEL_ENABLE PIPELINED
   IS
  /******************************************************************************************
   ->Nome da Função    : F_RETORNARLISTA
   ->Objetivo          : Retornar uma string em forma de lista considenrando um separador.
   ->Versao            : Pacote
   -------------------------- Alterações ---------------------------------------------------
   Data          Autor             Tarefa      Comentários
   ------------  ---------------   ---------------------------------------------------------
   09/08/2013    Rodrigo Santos    0           Função criada.
   ------------  ---------------   ---------------------------------------------------------*/
  vsRETORNO    VARCHAR2(30000);
  DADOS_SAIDA  TR_LISTA;

  BEGIN

    vsRETORNO := '';

    IF length(PLISTA) > 0 THEN

      FOR X IN 1..length(PLISTA)
      LOOP

        IF TO_CHAR(substr(PLISTA,X,1)) <> TO_CHAR(PSEPARADOR) THEN

          vsRETORNO := vsRETORNO || substr(PLISTA,X,1);

          IF X = length(PLISTA) THEN
            DADOS_SAIDA.ITEM := vsRETORNO;
            PIPE ROW (DADOS_SAIDA);
          END IF;

        ELSIF TO_CHAR(substr(PLISTA,X,1)) = TO_CHAR(PSEPARADOR) THEN

          DADOS_SAIDA.ITEM := vsRETORNO;
          PIPE ROW (DADOS_SAIDA);
          vsRETORNO := '';

        END IF;

      END LOOP;

    ELSE
      DADOS_SAIDA.ITEM := '0';
      PIPE ROW (DADOS_SAIDA);
    END IF;

    RETURN;

  END F_RETORNARLISTA;

  FUNCTION F_BUSCARPARAMETRO_ALFA(PNOMEPARAM   IN VARCHAR2,
                                  PCODFILIAL   IN VARCHAR2,
                                  PVALORSENULO IN VARCHAR2)
   RETURN VARCHAR2
  IS
  vsVALORTEMP  VARCHAR2(100);
  BEGIN

    SELECT NVL(VALOR, PVALORSENULO)
      INTO vsVALORTEMP
      FROM PCPARAMFILIAL
     WHERE NOME = PNOMEPARAM
       AND CODFILIAL = PCODFILIAL;

    RETURN vsVALORTEMP;

  EXCEPTION
   WHEN OTHERS THEN

     RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_ALFA;

  FUNCTION F_BUSCARPARAMETRO_NUM(PNOMEPARAM   IN VARCHAR2,
                                 PCODFILIAL   IN VARCHAR2,
                                 PVALORSENULO IN NUMBER)
   RETURN NUMBER
  IS
  vnVALORTEMP  NUMBER;
  BEGIN

    SELECT NVL(TO_NUMBER(VALOR), PVALORSENULO)
      INTO vnVALORTEMP
      FROM PCPARAMFILIAL
     WHERE NOME = PNOMEPARAM
       AND CODFILIAL = PCODFILIAL;

    RETURN vnVALORTEMP;

  EXCEPTION
    WHEN INVALID_NUMBER THEN

    BEGIN
      SELECT NVL(TO_NUMBER(translate(VALOR,',.','.,')), PVALORSENULO)
        INTO vnVALORTEMP
        FROM PCPARAMFILIAL
       WHERE NOME = PNOMEPARAM
         AND CODFILIAL = PCODFILIAL;

      RETURN vnVALORTEMP;

    EXCEPTION
      WHEN INVALID_NUMBER THEN
        RAISE_APPLICATION_ERROR(-20000, 'NÚMERO INVÁLIDO ATRIBUÍDO AO PARÂMETRO: "' || PNOMEPARAM || '". VERIFIQUE O SEPARADOR DECIMAL');
    WHEN OTHERS THEN
      RETURN PVALORSENULO;
    END;

    WHEN OTHERS THEN

      RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_NUM;

  FUNCTION F_BUSCARPARAMETRO_DATA(PNOMEPARAM   IN VARCHAR2,
                                  PCODFILIAL   IN VARCHAR2,
                                  PVALORSENULO IN DATE)
   RETURN DATE
  IS
  vdVALORTEMP  DATE;
  BEGIN

    SELECT NVL(TO_DATE(VALOR), PVALORSENULO)
      INTO vdVALORTEMP
      FROM PCPARAMFILIAL
     WHERE NOME = PNOMEPARAM
       AND CODFILIAL = PCODFILIAL;

    RETURN vdVALORTEMP;

  EXCEPTION
   WHEN OTHERS THEN

     RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_DATA;

------------------------------------------------------------------------------------
  FUNCTION BUSCAR_RAMO_ATIVIDADE(pCodAtivi IN NUMBER) RETURN T_RAMO_ATIVIDADE IS
    R_RAMO_ATIVIDADE T_RAMO_ATIVIDADE;
  BEGIN
    BEGIN
      SELECT NVL(PCATIVI.PERCREDALIQIPI, 0),
             NVL(PCATIVI.CALCULAST, 'S')
        INTO R_RAMO_ATIVIDADE.PercRedAliqIpi,
             R_RAMO_ATIVIDADE.CALCULAST
        FROM PCATIVI
       WHERE PCATIVI.CODATIV = pCodAtivi;
    EXCEPTION
      WHEN OTHERS THEN
        R_RAMO_ATIVIDADE.PercRedAliqIpi := 0;
        R_RAMO_ATIVIDADE.CALCULAST      := 'S';
    END;

    RETURN R_RAMO_ATIVIDADE;
  END;

------------------------------------------------------------------------------------

FUNCTION BUSCAR_CLIENTE(pCodCli IN NUMBER, pCODFILIALNF IN VARCHAR2, pconsultardblink IN varchar2 DEFAULT 'N')
    RETURN T_CLIENTE IS
    R_CLIENTE T_CLIENTE;
    vsscript  VARCHAR2(4000);
    v_cursor  SYS_REFCURSOR;
    vbcountdblink number := 0;
    vsCodcli varchar2(80);
    vsCodfilialnf varchar(4);
  BEGIN
    IF (pconsultardblink = 'S') THEN
      BEGIN
        SELECT COUNT(1)
          INTO vbcountdblink
          FROM user_db_links a
         WHERE a.db_link = 'DBLSERVIDOR';
      EXCEPTION
        WHEN OTHERS THEN
          vbcountdblink := 0;
      END;
    END IF;

    if pCodCli is null then
       vsCodCli := 'null';
    else
       vsCodCLi := pCodCLI;
    end if;

    if pCODFILIALNF is null then
       vsCodFilialNF := 'null';
    else
       vsCodFilialNF := pCODFILIALNF;
    end if;

    vsscript := '
    SELECT PCCLIENT.CODCLI,
           PCCLIENT.CODCLIPRINC,
           PCCLIENT.CLASSEVENDA,
           PCCLIENT.TIPOFJ,
           PCCLIENT.CODREDE,
           PCCLIENT.SIMPLESNACIONAL,
           PCCLIENT.CODATV1,
           PCCLIENT.CODPRACA,
           PCCLIENT.Codcnae,
           PCCLIENT.estent,
           NVL(PCCLIENT.calculast, ''S''),
           NVL(PCCLIENT.Clientefontest, ''N''),
           NVL(PCCLIENT.Usaivafontediferenciado, ''N'') Usaivafontediferenciado,
           PCCLIENT.Ivafonte,
           PCCLIENT.ieent,
           PCCLIENT.utilizaiesimplificada,
           PCCLIENT.isentoipi,
           PCCLIENT.Isentoicms,
           PCCLIENT.sulframa,
           PCCLIENT.ISENCAOSUFRAMA,
           NVL(PCCLIENT.contribuinte,''N'') contribuinte,
           NVL(PCCLIENT.consumidorfinal,''N'') consumidorfinal,
           PCCLIENT.UTILIZACALCULOSTMT,
           PCCLIENT.TIPOEMPRESA,
           NVL(PCCLIENT.TIPODESCISENCAO,''N'') TIPODESCISENCAO,
           NVL(PCCLIENT.PERDESCISENTOICMS, 0),
           NVL(PCCLIENT.ORGAOPUB, ''N''),
           NVL(PCCLIENT.ORGAOPUBFEDERAL, ''N''),
           NVL(PCCLIENT.USADESCONTOICMS, ''N''),
           FERRAMENTAS.VERIFICAR_FJ(PCCLIENT.CODCLI),
            NVL((CASE
             WHEN :codfilialnf
                 IS NOT NULL THEN
              (SELECT NUMREGIAO
                 FROM PCTABPRCLI
                WHERE CODCLI = :codcli
                  AND CODFILIALNF = :codfilialnf )
             ELSE
              PCREGIAO.NUMREGIAO
           END), PCREGIAO.NUMREGIAO) AS NUMREGIAO,
           PCCLIENT.codfilialnf,
           PCCLIENT.RIOLOG,
           PCCLIENT.COZINHAINDUSTRIAL,
           PCCLIENT.TIPODOCUMENTO';

    IF (pconsultardblink = 'S') and (vbcountdblink >= 1) THEN
      vsscript := vsscript ||
                  ' FROM PCCLIENT@DBLSERVIDOR, PCPRACA@DBLSERVIDOR, PCREGIAO@DBLSERVIDOR';
    ELSE
      vsscript := vsscript || ' FROM PCCLIENT, PCPRACA, PCREGIAO';
    END IF;

    vsscript := vsscript || ' WHERE CODCLI = :codcli
       AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA
       AND PCPRACA.NUMREGIAO = PCREGIAO.NUMREGIAO';

    OPEN v_cursor FOR vsscript using vsCodFilialNF, vsCodCLi, vsCodFilialNF, vsCodCli;

    fetch v_cursor into
           R_CLIENTE.CodCli,
           R_CLIENTE.CodCliPrinc,
           R_CLIENTE.ClasseVenda,
           R_CLIENTE.TipoPessoa,
           R_CLIENTE.CodRede,
           R_CLIENTE.SimplesNacional,
           R_CLIENTE.CodAtiv1,
           R_CLIENTE.CodPraca,
           R_CLIENTE.CodCnae,
           R_CLIENTE.EstEnt,
           R_CLIENTE.CalculaSt,
           R_CLIENTE.ClienteFonteST,
           R_CLIENTE.UsaivaFonteDiferenciado,
           R_CLIENTE.IvaFonte,
           R_CLIENTE.IEEnt,
           R_CLIENTE.Utilizaiesimplificada,
           R_CLIENTE.Isentoipi,
           R_CLIENTE.Isentoicms,
           R_CLIENTE.Sulframa,
           R_CLIENTE.IsencaoSuframa,
           R_CLIENTE.Contribuinte,
           R_CLIENTE.ConsumidorFinal,
           R_CLIENTE.UtilizaCalculoSTMT,
           R_CLIENTE.TipoEmpresa,
           R_CLIENTE.TipoDescIsencao,
           R_CLIENTE.PerDescIsentoICMS,
           R_CLIENTE.OrgaoPub,
           R_CLIENTE.OrgaoPubFederal,
           R_CLIENTE.UsaDescontoICMS,
           R_CLIENTE.PessoaFisicaJuridica,
           R_CLIENTE.NumRegiao,
           R_CLIENTE.CodFilialNf,
           R_CLIENTE.RioLog,
           R_CLIENTE.CozinhaIndustrial,
           R_CLIENTE.TipoDocumento;

    CLOSE v_cursor;

    R_CLIENTE.RamoAtividade := BUSCAR_RAMO_ATIVIDADE(R_CLIENTE.CodAtiv1);

    RETURN R_CLIENTE;
  END;

  PROCEDURE GRAVARLOG(PPARAMS    IN OUT PCLOGIMPOSTOS%ROWTYPE
                     ,PSLINHAMSG IN VARCHAR2 DEFAULT '') IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    VSLINHAERRO VARCHAR2(400);
  BEGIN

    IF NVL(G_GERARLOG, 'N') = 'N'
    THEN
      RETURN;
    END IF;

    PPARAMS.DATA   := SYSDATE;

    SELECT DFSEQ_PCLOGIMPOSTOS.NEXTVAL
      INTO PPARAMS.SEQUENCIA
      FROM DUAL;

    VSLINHAERRO := '';
    IF PPARAMS.DESCRICAO LIKE '%ORA-%'
    THEN
      -- Verifica se é mensagem com erro
      VSLINHAERRO := PSLINHAMSG;
    END IF;

    -- Adicionar número da linha, quando for erro ou quando for apenas uma mensagem informativa
    PPARAMS.DESCRICAO := PPARAMS.DESCRICAO || CHR(13) || CASE
                           WHEN VSLINHAERRO IS NOT NULL THEN
                            ' ERRO: ' || VSLINHAERRO
                           WHEN PSLINHAMSG IS NOT NULL THEN
                            ' LINHA MSG: ' || PSLINHAMSG
                           ELSE
                            ' LINHA: ' || PSLINHAMSG
                         END;

    INSERT INTO PCLOGIMPOSTOS
    VALUES PPARAMS;

    COMMIT;

  END GRAVARLOG;

  PROCEDURE DEFINIRCODFISCAL(T_PCPEDC    PCPEDC%ROWTYPE,
                           T_PCPEDI    PCPEDI%ROWTYPE,
                           P_CODFISCAL OUT NUMBER,
                           P_SITTRIBUT OUT VARCHAR2,
                           P_MSG       OUT VARCHAR2,
                           P_GERALOG   IN  VARCHAR2 DEFAULT 'N')
  /******************************************************************************************
    ->Nome da PROCEDURE : DEFINIR_CODFISCALPCMOV
    ->Objetivo          : Retornar o PCMOV.CODFISCAL para o Item da NF (PCMOV.CODFISCAL)
    ->Versao            : Pacote
    ->Utilização        : FATU_FATURA_PEDIDO

    -------------------------------- Historico ------------------------------------------------
    Data         Realizado por    Tarefa    Comentarios
    -----------  --------------------- Historico ------------------------------------------------
    31/10/2016   Deyvid Costa          Criação da procedure

    -------------------------------------------------------------------------------------------*/
   IS
    VBPESSOAFISICA          BOOLEAN;
    VNCFOEST                PCMOV.CODFISCAL%TYPE;
    VNCFOINTER              PCMOV.CODFISCAL%TYPE;
    VNCFOINTERNASC          PCMOV.CODFISCAL%TYPE;
    VSSITTRIBUT             PCTRIBUT.SITTRIBUT%TYPE;
    VNCONTROLCST            NUMBER := 0;
    VNCONTROLISENTOST       NUMBER := 0;
--  VNCODICMSIMPLESNAC  PCTRIBUT.CODICMSIMPLESNAC%TYPE;
    PNCODST                 PCTRIBUT.CODST%TYPE;
    PNCODPROD               PCPRODUT.CODPROD%TYPE;
    PNCONDVENDA             PCPEDC.CONDVENDA%TYPE;
    PSTIPOEMPRESA           PCCLIENT.TIPOEMPRESA%TYPE;
    VSUTILIZACFOPPFISENTOST VARCHAR2(1);

    VC2CODIGOSUFRAMA PCCLIENT.SULFRAMA%TYPE;
    --  PNVLDESCSUFRAMA          PCPEDI.VLDESCSUFRAMA%TYPE;
    PNCODBNF                 PCPEDC.CODBNF%TYPE;
    VSITEMTV1BNF             VARCHAR2(1);
    VSRAMOATIVIDADECALCULAST PCATIVI.CALCULAST%TYPE;
    VNCODFISCAL              PCTRIBUT.CODFISCAL%TYPE;
	  VNESTENT				 VARCHAR2(2);
    VBORIGMERCTRIBESTRANGEIRA    BOOLEAN;

    ROWTRIBUTACAO PCTRIBUT%ROWTYPE;
    ROWCLIENTE    PCCLIENT%ROWTYPE;
    ROWPRODUTO    PCPRODUT%ROWTYPE;
    ROWPRODFILIAL PCPRODFILIAL%ROWTYPE;
    ROWFILIAL     PCFILIAL%ROWTYPE;
    vrlog         PCLOGIMPOSTOS%ROWTYPE;

    ------------------------------------ ENCONTRA OS DADOS DA TRIBUTAÇÃO -------------------------------------
    FUNCTION ENCONTRATRIBUTACAO(PNCODST NUMBER) RETURN BOOLEAN IS
    BEGIN
      SELECT T.* INTO ROWTRIBUTACAO FROM PCTRIBUT T WHERE CODST = PNCODST;

      ROWTRIBUTACAO.sittribut                  := NVL(ROWTRIBUTACAO.sittribut,
                                                      '000');
      ROWTRIBUTACAO.sittributpf                := NVL(ROWTRIBUTACAO.sittributpf,
                                                      NVL(ROWTRIBUTACAO.sittribut,
                                                          '000'));
      ROWTRIBUTACAO.usacfopbnfparabrinde       := NVL(ROWTRIBUTACAO.usacfopbnfparabrinde,
                                                      'N');
      ROWTRIBUTACAO.tipocalculognre            := NVL(ROWTRIBUTACAO.tipocalculognre,
                                                      'P');
      ROWTRIBUTACAO.codfiscalisentost          := NVL(ROWTRIBUTACAO.codfiscalisentost,
                                                      ROWTRIBUTACAO.codfiscal);
      ROWTRIBUTACAO.codfiscalisentostinter     := NVL(ROWTRIBUTACAO.codfiscalisentostinter,
                                                      ROWTRIBUTACAO.codfiscalinter);
      ROWTRIBUTACAO.codfiscalisentostinternasc := NVL(ROWTRIBUTACAO.codfiscalisentostinternasc,
                                                      ROWTRIBUTACAO.codfiscalinternasc);
      ROWTRIBUTACAO.sittributisentost          := ROWTRIBUTACAO.sittributisentost;
      ROWTRIBUTACAO.codfiscaltroca             := NVL(ROWTRIBUTACAO.codfiscaltroca,
                                                      ROWTRIBUTACAO.codfiscalbonific);
      ROWTRIBUTACAO.codfiscaltrocainter        := NVL(ROWTRIBUTACAO.codfiscaltrocainter,
                                                      ROWTRIBUTACAO.codfiscalbonificinter);
      ROWTRIBUTACAO.codfiscaltrocainternasc    := NVL(ROWTRIBUTACAO.codfiscaltrocainternasc,
                                                      ROWTRIBUTACAO.codfiscalbonificinternasc);
      ROWTRIBUTACAO.sittributnrpa              := ROWTRIBUTACAO.sittributnrpa;

      ROWTRIBUTACAO.codfiscaltv9          := NVL(ROWTRIBUTACAO.codfiscaltv9,
                                                 ROWTRIBUTACAO.codfiscalbonific);
      ROWTRIBUTACAO.codfiscalintertv9     := NVL(ROWTRIBUTACAO.codfiscalintertv9,
                                                 ROWTRIBUTACAO.codfiscalbonificinter);
      ROWTRIBUTACAO.codfiscalinternasctv9 := NVL(ROWTRIBUTACAO.codfiscalinternasctv9,
                                                 ROWTRIBUTACAO.codfiscalbonificinternasc);

      ROWTRIBUTACAO.codfiscaltriangularpf          := NVL(ROWTRIBUTACAO.codfiscaltriangularpf,
                                                          ROWTRIBUTACAO.codfiscaltriangular);
      ROWTRIBUTACAO.codfiscaltriangularinterpf     := NVL(ROWTRIBUTACAO.codfiscaltriangularinterpf,
                                                          ROWTRIBUTACAO.codfiscaltriangularinter);
      ROWTRIBUTACAO.codfiscaltriangularinternascpf := NVL(ROWTRIBUTACAO.codfiscaltriangularinternascpf,
                                                          ROWTRIBUTACAO.codfiscaltriangularinternasc);
      ROWTRIBUTACAO.codfiscalcontaordem            := NVL(ROWTRIBUTACAO.codfiscalcontaordem,
                                                          ROWTRIBUTACAO.codfiscalvendaentfut);
      ROWTRIBUTACAO.codfiscalcontaordeminter       := NVL(ROWTRIBUTACAO.codfiscalcontaordeminter,
                                                          ROWTRIBUTACAO.codfiscalvendaentfutinter);
      ROWTRIBUTACAO.codfiscalcontaordemsimpent     := NVL(ROWTRIBUTACAO.codfiscalcontaordemsimpent,
                                                          ROWTRIBUTACAO.codfiscalsimpentfut);
      ROWTRIBUTACAO.codfiscalcontaordemsimpentinte := NVL(ROWTRIBUTACAO.codfiscalcontaordemsimpentinte,
                                                          ROWTRIBUTACAO.codfiscalsimpentfutinter);
      --           ROWTRIBUTACAO.sittributtv7,
      ROWTRIBUTACAO.sittributbonific := ROWTRIBUTACAO.sittributbonific;

      ROWTRIBUTACAO.SITTRIBUTBNFTV1 := ROWTRIBUTACAO.SITTRIBUTBNFTV1;

      ROWTRIBUTACAO.SITTRIBUTBNFTV14 := ROWTRIBUTACAO.SITTRIBUTBNFTV14;

      ROWTRIBUTACAO.PRODRURALCALCDIFER := NVL(ROWTRIBUTACAO.PRODRURALCALCDIFER,'N');

      ROWTRIBUTACAO.SITTRIBUTPRODRURALCALCDIFER := NVL(ROWTRIBUTACAO.SITTRIBUTPRODRURALCALCDIFER,
                                            NVL(ROWTRIBUTACAO.sittribut,
                                                '000'));

      RETURN ROWTRIBUTACAO.CODST is not null;

    END;

    ------------------------------------ ENCONTRA OS DADOS DO CLIENTE ---------------------------------------
    FUNCTION ENCONTRACLIENTE(PNCODCLI NUMBER, PNNUMPED NUMBER) RETURN BOOLEAN IS
      vicontador  NUMBER;
    BEGIN

      SELECT C.* INTO ROWcliente FROM PCCLIENT C WHERE CODCLI = PNCODCLI;

      rowcliente.estent                  := UPPER(LTRIM(RTRIM(rowcliente.estent)));
      rowcliente.isentoicms              := NVL(rowcliente.isentoicms, 'N');
      rowcliente.ieent                   := TRIM(UPPER(rowcliente.ieent));
      rowcliente.clientefontest          := NVL(rowcliente.clientefontest,
                                                'N');
      rowcliente.utilizaiesimplificada   := NVL(rowcliente.utilizaiesimplificada,
                                                'N');
      rowcliente.consumidorfinal         := NVL(rowcliente.consumidorfinal,
                                                'N');
      rowcliente.tipoempresa             := NVL(rowcliente.tipoempresa, 'O');
      rowcliente.orgaopub                := NVL(rowcliente.orgaopub, 'N');
      rowcliente.contribuinte            := NVL(rowcliente.contribuinte,
                                                'N');
      rowcliente.usaivafontediferenciado := NVL(rowcliente.usaivafontediferenciado,
                                                'N');
      rowcliente.ivafonte                := NVL(rowcliente.ivafonte, 0);
      rowcliente.orgaopubfederal         := NVL(rowcliente.orgaopubfederal,
                                                'N');
      rowcliente.participafuncep         := NVL(rowcliente.participafuncep,
                                                'N');

      IF PNCODCLI IN (1, 2, 3) THEN
          SELECT COUNT(*)
            INTO vicontador
            FROM pcvendaconsum
           WHERE numped = PNNUMPED;

          IF vicontador = 1 THEN

            SELECT NVL(UPPER(LTRIM(RTRIM(estent))),UPPER(LTRIM(RTRIM(rowcliente.estent))))
              INTO rowcliente.estent
              FROM pcvendaconsum
             WHERE numped = PNNUMPED;

          END IF;
       END IF;

      RETURN ROWcliente.CODCLI > 0;
      ---------------------------------------------------------------------------------------------------------
    END;

    ------------------------------------ ENCONTRA OS DADOS DA FILIAL ----------------------------------------
    FUNCTION ENCONTRAFILIAL(PNCODDILIAL PCFILIAL.CODIGO%TYPE) RETURN BOOLEAN IS
    BEGIN
      BEGIN
      SELECT F.* INTO ROWFILIAL FROM PCFILIAL F WHERE CODIGO = PNCODDILIAL; --NVL(T_PCPEDC.CODFILIALNF, T_PCPEDC.CODFILIAL);

      ROWFILIAL.uf            := UPPER(LTRIM(RTRIM(ROWFILIAL.uf)));
      ROWFILIAL.industria     := NVL(ROWFILIAL.industria, 'N');
      VSUTILIZACFOPPFISENTOST := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZACFOPPFISENTOST',
                                                                    T_PCPEDC.CODFILIAL,
                                                                    'N');
      RETURN ROWFILIAL.CODIGO <> '';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN FALSE;
      END;
    END;
    ---------------------------------------------------------------------------------------------------------

    ------------------------------------ ENCONTRA OS DADOS DO PRODUTO ----------------------------------------
    FUNCTION ENCONTRAPRODUTO(PNCODPROD NUMBER) RETURN BOOLEAN IS
    BEGIN
      BEGIN
      SELECT P.* INTO ROWPRODUTO FROM PCPRODUT P WHERE CODPROD = PNCODPROD; --T_PCPEDI.codprod;

      ROWPRODUTO.compraconsignado := NVL(ROWPRODUTO.compraconsignado, 'N');
      ROWPRODUTO.importado        := NVL(ROWPRODUTO.importado, 'N');
      RETURN ROWPRODUTO.CODPROD > 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN FALSE;
      END;
    END;
    ---------------------------------------------------------------------------------------------------------

    ------------------------------------ ENCONTRA OS DADOS DO PRODUTO NA FILIAL ----------------------------------------
    FUNCTION ENCONTRAPRODFILIAL(PNCODPROD NUMBER, PNCODDILIAL PCFILIAL.CODIGO%TYPE) RETURN BOOLEAN IS
    BEGIN
      SELECT P.* INTO ROWPRODFILIAL FROM PCPRODFILIAL P WHERE CODPROD = PNCODPROD AND CODFILIAL = PNCODDILIAL;

      ROWPRODFILIAL.origmerctrib := NVL(ROWPRODFILIAL.origmerctrib, '0');

      RETURN ROWPRODFILIAL.CODPROD > 0;
    END;
    ---------------------------------------------------------------------------------------------------------

  BEGIN

    ------------------------------------ INICIALIZANDO DADOS DO LOG ------------------------------------------
    VRLOG.NUMPED  := T_PCPEDC.NUMPED;
    VRLOG.CODPROD := T_PCPEDI.CODPROD;
    VRLOG.NUMSEQ  := T_PCPEDI.NUMSEQ;
    VRLOG.OBJETO  := 'DEFINIRCODFISCAL';
    G_GERARLOG    := P_GERALOG;

    VRLOG.DESCRICAO := 'Início da procedure de definição do Código Fiscal e Situação Tributária.';
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    ------------------------------------ ENCONTRA OS DADOS DA TRIBUTAÇÃO -------------------------------------
    VRLOG.DESCRICAO := 'Buscando dados da Tributação ' || T_PCPEDI.CODST;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF NOT ENCONTRATRIBUTACAO(T_PCPEDI.Codst) THEN
      P_MSG := 'Dados da tributação não encontrado (DEFINIRCODFISCAL)';
      VRLOG.DESCRICAO := P_MSG;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;


    ------------------------------------ ENCONTRA OS DADOS DO CLIENTE ---------------------------------------
    VRLOG.DESCRICAO := 'Buscando dados do Cliente ' || T_PCPEDI.CODCLI;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF NOT ENCONTRACLIENTE(T_PCPEDC.CodCLI, T_PCPEDC.NUMPED) THEN
      P_MSG := 'Dados da cliente não encontrado (DEFINIRCODFISCAL)';
      VRLOG.DESCRICAO := P_MSG;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;

	IF (T_PCPEDC.CODENDENTCLI > 0 AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZATRIBENDENT',T_PCPEDC.CODFILIAL,'N') = 'S'  ) then
		BEGIN

		 SELECT ESTENT
		   INTO VNESTENT
		   FROM PCCLIENTENDENT
		  WHERE PCCLIENTENDENT.CODENDENTCLI =  T_PCPEDC.CODENDENTCLI
			AND PCCLIENTENDENT.DTEXCLUSAO IS NULL;

		EXCEPTION
		  WHEN OTHERS THEN
			VNESTENT := ROWCLIENTE.ESTENT;
		END;

		ROWCLIENTE.ESTENT := VNESTENT;
	END IF;

    BEGIN

      SELECT NVL(PCATIVI.CALCULAST, 'N')
        INTO VSRAMOATIVIDADECALCULAST
        FROM PCCLIENT, PCATIVI
       WHERE PCCLIENT.CODATV1 = PCATIVI.CODATIV
         AND PCCLIENT.CODCLI = T_PCPEDC.CODCLI;

    EXCEPTION
      WHEN OTHERS THEN
        VSRAMOATIVIDADECALCULAST :=  'N';
    END;

    VRLOG.DESCRICAO := 'Verificar se Ramo de Atividade do Cliente calcula st. VSRAMOATIVIDADECALCULAST = ' || VSRAMOATIVIDADECALCULAST;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    ------------------------------------ ENCONTRA OS DADOS DA FILIAL ----------------------------------------
    VRLOG.DESCRICAO := 'Buscando dados da Filial ' || NVL(T_PCPEDC.CODFILIALNF, T_PCPEDC.CODFILIAL);
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF NOT ENCONTRAFILIAL(NVL(T_PCPEDC.CODFILIALNF, NVL(ROWCLIENTE.CODFILIALNF, T_PCPEDC.CODFILIAL))) THEN
      P_MSG := 'Dados da filial não foi encontrado (DEFINIRCODFISCAL)';
      VRLOG.DESCRICAO := P_MSG;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;


    ------------------------------------ ENCONTRA OS DADOS DO PRODUTO ----------------------------------------
    VRLOG.DESCRICAO := 'Buscando dados do produto ' || T_PCPEDI.CODPROD;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF NOT ENCONTRAPRODUTO(T_PCPEDI.codprod) THEN
      P_MSG := 'Dados do produto não foi encontrado (DEFINIRCODFISCAL)';
      VRLOG.DESCRICAO := P_MSG;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;
	
    ------------------------------------ ENCONTRA OS DADOS DO PRODUTO ----------------------------------------
    VRLOG.DESCRICAO := 'Buscando dados do produto ' || T_PCPEDI.CODPROD || ' na filial ' || ROWFILIAL.CODIGO;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF NOT ENCONTRAPRODFILIAL(T_PCPEDI.codprod, ROWFILIAL.CODIGO) THEN
      P_MSG := 'Dados do produto na filial não foi encontrado (DEFINIRCODFISCAL)';
      VRLOG.DESCRICAO := P_MSG;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;

    VRLOG.DESCRICAO := 'vncfoest       = ' || ROWTRIBUTACAO.codfiscal ||chr(13) ||
                       'vncfointer     = ' || ROWTRIBUTACAO.codfiscalinter||chr(13) ||
                       'vncfointernasc = ' || ROWTRIBUTACAO.codfiscalinternasc||chr(13) ||
                       'vssittribut    = ' || ROWTRIBUTACAO.sittribut;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    vncfoest       := ROWTRIBUTACAO.codfiscal;
    vncfointer     := ROWTRIBUTACAO.codfiscalinter;
    vncfointernasc := ROWTRIBUTACAO.codfiscalinternasc;
    vssittribut    := ROWTRIBUTACAO.sittribut;

    pncodst   := T_PCPEDI.Codst;
    pncodprod := T_PCPEDI.CODPROD;
    --  vssittributpriorit := ROWTRIBUTACAO.SITTRIBUTPRIORIT;
    pncondvenda   := T_PCPEDC.CONDVENDA;
    pncodbnf      := T_PCPEDC.Codbnf;

    /*
        OBS.: Não Adicionar regras acima desse ponto,
    */

       VRLOG.DESCRICAO := 'Cliente definido com MEI. Utilizando SITTRIBUT de cliente MEI';
       GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    vsITEMTV1BNF := case
                      when T_PCPEDC.CONDVENDA in (1, 14) then
                       case
                         when NVL(T_PCPEDI.BONIFIC, 'N') = 'F' then
                          'S'
                         else
                          'N'
                       end
                      else
                       'N'
                    end;

    VRLOG.DESCRICAO := 'Definindo se item é bonificado na mesma nota. vsITEMTV1BNF = ' || VSITEMTV1BNF;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    -- RETORNA O TIPO DE PESSOA FÍSICA OU JURÍDICA
    IF (NVL(T_PCPEDC.codclinf, T_PCPEDC.codcli) <> 0) AND
       (NVL(T_PCPEDC.codclinf, T_PCPEDC.codcli) <> T_PCPEDC.codcli) THEN
      VBPESSOAFISICA := (FERRAMENTAS.VERIFICAR_FJ(NVL(T_PCPEDC.codclinf,
                                                      T_PCPEDC.codcli)) =
                        'PESSOA FISICA');
    ELSE
      VBPESSOAFISICA := (FERRAMENTAS.VERIFICAR_FJ(T_PCPEDC.CODCLI) =
                        'PESSOA FISICA');
    END IF;

    VRLOG.DESCRICAO := 'Cliente ' || NVL(T_PCPEDC.CODCLINF, T_PCPEDC.CODCLI) || ' definido como ' || VERIFICAR_FJ(NVL(T_PCPEDC.CODCLINF, T_PCPEDC.CODCLI));
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

     /* ?VersaoRotina | 27.0.34.232
        Tarefa | 3688.047875.2017
        Rotina | PCSIS300.PC
        Descricao | Ajustado para quando o cliente for PF, isento de ST e a 514 não possui CST de isento a rotina estava fazendo NVL para o CST de PJ e não de PF

     */
     IF (VBPESSOAFISICA) THEN
          ROWTRIBUTACAO.sittributisentost          := NVL(ROWTRIBUTACAO.sittributisentost,
                                                      NVL(ROWTRIBUTACAO.sittributpf,
                                                          '000'));
         ROWTRIBUTACAO.sittributnrpa              := NVL(ROWTRIBUTACAO.sittributnrpa,
                                                      NVL(ROWTRIBUTACAO.sittributpf,
                                                          '000'));
         ROWTRIBUTACAO.sittributbonific := NVL(ROWTRIBUTACAO.sittributbonific,
                                            ROWTRIBUTACAO.sittributpf);

         ROWTRIBUTACAO.SITTRIBUTBNFTV1 :=  ROWTRIBUTACAO.SITTRIBUTBNFTV1;

     ELSE
          ROWTRIBUTACAO.sittributisentost          := NVL(ROWTRIBUTACAO.sittributisentost,
                                                      NVL(ROWTRIBUTACAO.sittribut,
                                                          '000'));
         ROWTRIBUTACAO.sittributnrpa              := NVL(ROWTRIBUTACAO.sittributnrpa,
                                                      NVL(ROWTRIBUTACAO.sittribut,
                                                          '000'));
         ROWTRIBUTACAO.sittributbonific := NVL(ROWTRIBUTACAO.sittributbonific,
                                            ROWTRIBUTACAO.sittribut);

     END IF;

    if VBPESSOAFISICA then
      ROWTRIBUTACAO.sittributnrpa := NVL(ROWTRIBUTACAO.sittributnrpa,
                                         NVL(ROWTRIBUTACAO.sittributpf,
                                             '000'));
      /*  vssittributisentost,
      pssittributbonific*/
    end if;

    IF NVL(T_PCPEDC.codclinf, T_PCPEDC.codcli) <> 0 Then
      vc2codigosuframa := ROWcliente.Sulframa;
    end if;
	
    IF ROWPRODFILIAL.origmerctrib IN ('0', '3','4','5','8') THEN
      VBORIGMERCTRIBESTRANGEIRA := FALSE;
    ELSE
      VBORIGMERCTRIBESTRANGEIRA := TRUE;
    END IF;


    ------------------------------- INÍCIO DAS REGRAS -------------------------------
    --ATENÇÃO!!!!!
    --NÃO INVERTER OU ALTERAR AS REGRAS ABAIXO
    --REGRA 01 --Tarefa: 208890
    IF (vbpessoafisica) AND (pncondvenda NOT IN (5, 6, 11, 12)) THEN
      VRLOG.DESCRICAO := 'Selecionando CFOPs de Pessoa Física.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      vncfoest       := ROWTRIBUTACAO.codfiscalpf; -- vncfoestpf;
      vncfointer     := ROWTRIBUTACAO.codfiscalinterpf; --vncfointerpf;
      vncfointernasc := ROWTRIBUTACAO.codfiscalinternascpf; --vncfointernascpf;
    END IF;
    --REGRA 02
    IF vbpessoafisica THEN
      VRLOG.DESCRICAO := 'Selecionado CSTs de pessoa física.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      vssittribut := ROWTRIBUTACAO.sittributpf;
      --    vncontrolcst := vncontrolcst + 1;
    END IF;

    --Responsável: Rafael Soares
    --Data:        28/09/2016
    --Alteração: Quando o cliente é simples nascional, mas isento de ST o sitema deve pegar o CST de ISENTO de ST
    --           Isso estava gerando falha quando o cliente realizava vendas para cliente SN isentos e não de ST
    --           Caso isso gere problema Procure Rafael Soares ou Silas

    IF (UPPER(TRIM(ROWCLIENTE.TIPOEMPRESA)) = 'SN') THEN
      VRLOG.DESCRICAO := 'Definido CFOP de cliente Simples Nacional';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      vncfoest       := NVL(ROWTRIBUTACAO.codfiscalsimplesnacest, vncfoest);
      vncfointer     := NVL(ROWTRIBUTACAO.codfiscalsimplesnacnac, vncfointer);
      vncfointernasc := NULL;

      IF (ROWTRIBUTACAO.codicmsimplesnac IS NOT NULL) AND (ROWTRIBUTACAO.SITTRIBUTSIMPLESNAC IS NOT NULL) THEN
        VRLOG.DESCRICAO := 'Cliente simples nacional. Utilizando CST de cliente Simples Nacional.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        vssittribut := ROWTRIBUTACAO.SITTRIBUTSIMPLESNAC;
      END IF;
    END IF;
      --Retorno da validação anterior
      IF (FERRAMENTAS.VERIFICAR_ISENTOST(T_PCPEDC.codcli, pncodprod, pncodst,(case when pncondvenda = 10 then 'S' ELSE 'N' END)) = 'S') AND
       NOT (vbpessoafisica AND (VSUTILIZACFOPPFISENTOST = 'S'))
	   AND (pncondvenda NOT IN (5, 7, 8, 9, 11, 20) AND NOT (pncondvenda = 14 AND ((SUBSTR(T_pcpedc.codcob, 1, 3) = 'BNF') OR (T_pcpedc.codcob = 'BNTR')))) THEN
      VRLOG.DESCRICAO := 'Cliente Isento de ST. Utilizando CFOPs e CST de Isento ST.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      vncfoest          := ROWTRIBUTACAO.codfiscalisentost; --vncfoisentost;
        vncfointer      := ROWTRIBUTACAO.Codfiscalisentostinter; --vncfoisentostinter;
      vncfointernasc    := ROWTRIBUTACAO.Codfiscalisentostinternasc; --vncfoisentostinternasc;
      vssittribut       := ROWTRIBUTACAO.sittributisentost;

    END IF;
    -------------------------------------------

	--HIS.02351.2016
	IF (rowcliente.consumidorfinal = 'S') THEN
	  IF (ROWTRIBUTACAO.CODFISCALCONSUFINAL > 0) THEN
	    VRLOG.DESCRICAO := 'Definido CFOP estadual de cliente consumidor final;';
	    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

	    vncfoest := ROWTRIBUTACAO.CODFISCALCONSUFINAL;
	  END IF;

	  IF (ROWTRIBUTACAO.CODFISCALCONSUFINALINTER > 0) THEN
	    VRLOG.DESCRICAO := 'Definido CFOP interestadual de cliente consumidor final;';
	    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

	    vncfointer := ROWTRIBUTACAO.CODFISCALCONSUFINALINTER;
	  END IF;

	  IF (ROWTRIBUTACAO.CODFISCALCONSUFINALINTERNASC > 0) THEN
	    VRLOG.DESCRICAO := 'Definido CFOP internacional de cliente consumidor final;';
	    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

	    vncfointernasc := ROWTRIBUTACAO.CODFISCALCONSUFINALINTERNASC;
	  END IF;

	  IF ROWTRIBUTACAO.SITTRIBUTCONSFINAL IS NOT NULL THEN
	    VSSITTRIBUT  := ROWTRIBUTACAO.SITTRIBUTCONSFINAL;
	    VNCONTROLCST := VNCONTROLCST + 1;
	  END IF;
	END IF;


     --HIS.02246.2016
    IF (FERRAMENTAS.VERIFICAR_ISENTOST(rowcliente.codcli,
                                       pncodprod,
                                       pncodst,
                                       (case when pncondvenda = 10 then 'S' ELSE 'N' END)) = 'S') AND
       (rowcliente.CONTRIBUINTE = 'S') THEN
      IF (ROWTRIBUTACAO.CODFISCALISENTOSTCONT > 0) THEN
        VRLOG.DESCRICAO := 'Definido CFOP estadual de Cliente Isento de ST e contribuinte.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfoest := ROWTRIBUTACAO.CODFISCALISENTOSTCONT;
      END IF;
      IF (ROWTRIBUTACAO.CODFISCALISENTOSTCONTINTER > 0) THEN
        VRLOG.DESCRICAO := 'Definido CFOP interestadual de Cliente Isento de ST e contribuinte.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfointer := ROWTRIBUTACAO.CODFISCALISENTOSTCONTINTER;
      END IF;
      IF (ROWTRIBUTACAO.CODFISCALISENTOSTCONTINTER > 0) THEN
        VRLOG.DESCRICAO := 'Definido CFOP internacional de Cliente Isento de ST e contribuinte.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfointernasc := ROWTRIBUTACAO.CODFISCALISENTOSTCONTINTER;
      END IF;
    end if;


    -----------------------------------------------------
    IF pncondvenda NOT IN (7, 8, 9, 10, 11, 20) THEN

      IF UPPER(TRIM(ROWCLIENTE.TIPOEMPRESA)) = 'NRPA' THEN
        VRLOG.DESCRICAO := 'Cliente Tipo Empresa NRPA. Utilizando CST Cli. NRPA.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        vssittribut := ROWTRIBUTACAO.sittributnrpa;
        vncontrolcst := vncontrolcst + 1;
      END IF;

      -- Se for venda suframada
      IF (vc2codigosuframa IS NOT NULL) AND
         ((NVL(T_PCPEDI.VLDESCSUFRAMA, 0) > 0) OR
         (VBORIGMERCTRIBESTRANGEIRA) OR
         (NVL(T_PCPEDI.vldescicmisencao,0) > 0) OR
         (NVL(T_PCPEDI.VLDESCREDUCAOPIS, 0) > 0) OR
         (NVL(T_PCPEDI.VLDESCREDUCAOCOFINS, 0) > 0))
      THEN
        VRLOG.DESCRICAO := 'Cliente Suframado, Produto Nacional, e com desconto de Isenção ICMS/Reducao Pis/Reducao Cofins.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        IF (F_BUSCARPARAMETRO_ALFA('UTILIZACFOPSUFRAMAPRODIMPORT',
                                   '99',
                                   'S') = 'S') AND
           (VBORIGMERCTRIBESTRANGEIRA)
        THEN
          vncfoest       := 5110;
          vncfointer     := 6110;
          vncfointernasc := 7110;
          VRLOG.DESCRICAO := 'Parametrizado para Utilizar CFOP Suframa de Produto Importado.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        END IF;

        IF NVL(ROWFILIAL.industria, 'N') = 'S' THEN
          VRLOG.DESCRICAO := 'Filial parametrizada como industria.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfoest       := 5109;
          vncfointer     := 6109;
          vncfointernasc := 7109;
        END IF;

        --Tarefa 149786
        IF ROWTRIBUTACAO.codfiscalsuframa IS NOT NULL THEN
          VRLOG.DESCRICAO := 'Definido CFOP estadual de cliente suframado parametrizado na tributaçao.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfoest := ROWTRIBUTACAO.codfiscalsuframa;
        END IF;

        IF ROWTRIBUTACAO.codfiscalsuframainter IS NOT NULL THEN
          VRLOG.DESCRICAO := 'Definido CFOP interestadual de cliente suframado parametrizado na tributação.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfointer := ROWTRIBUTACAO.codfiscalsuframainter;
        END IF;

        IF (vc2codigosuframa IS NOT NULL) AND
           ((NVL(T_PCPEDI.vldescsuframa, 0) > 0) OR
           (NVL( /*pnVLDESCICMISENCAO*/ T_PCPEDI.vldescicmisencao, 0)) > 0) THEN
          IF ROWTRIBUTACAO.sittributsuframa IS NOT NULL THEN
            VRLOG.DESCRICAO := 'Definido CST de cliente suframado parametrizado na tributação.';
            GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
            vssittribut := ROWTRIBUTACAO.sittributsuframa;
            vncontrolcst := vncontrolcst + 1;
          END IF;
        END IF;
      END IF;
    END IF; --pncondvenda NOT IN (7, 8, 9, 10, 11, 20)
    ----------------------------------

    IF pncondvenda NOT IN (5, 7, 8, 9, 10, 11, 13, 14, 20) THEN


      -- Venda Consignada enviada anteriormente --
      --      IF pnnumnotaconsig IS NOT NULL THEN
      IF NVL(T_PCPEDC.numnotaconsig, 0) > 0 THEN
        VRLOG.DESCRICAO := 'Definido CFOPs de venda consignada definida na tributação.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        vncfoest       := ROWTRIBUTACAO.CODFISCALMERCCONSIG; -- vncfomercadoriaconsig;
        vncfointer     := ROWTRIBUTACAO.CODFISCALMERCCONSIGINTER; -- vncfomercadoriaconsiginter;
        vncfointernasc := ROWTRIBUTACAO.CODFISCALMERCCONSIGINTERNASC; --vncfomercadoriaconsiginternasc;
        vssittribut    := COALESCE(ROWTRIBUTACAO.SITTRIBUTMERCCONSIG, vssittribut);
        vncontrolcst := vncontrolcst + 1;
      END IF;

      -- (Projeto 80066 - Entrada Consignada de Mercadorias) Tarefa 88714
      IF (ROWPRODUTO.compraconsignado = 'S') THEN
        IF ROWTRIBUTACAO.codfiscalconsig IS NOT NULL THEN
          VRLOG.DESCRICAO := 'Definido CFOP estadual de venda de mercadoria consignada definido na tributação.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfoest := ROWTRIBUTACAO.codfiscalconsig;
        END IF;

        IF ROWTRIBUTACAO.codfiscalconsiginter IS NOT NULL THEN
          VRLOG.DESCRICAO := 'Definido CFOP interestadual de venda de mercadoria consignada definido na tributação.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfointer := ROWTRIBUTACAO.codfiscalconsiginter;
        END IF;

        IF ROWTRIBUTACAO.codfiscalconsiginternac IS NOT NULL THEN
          VRLOG.DESCRICAO := 'Definido CFOP internacional de venda de mercadoria consignada definido na tributação.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfointernasc := ROWTRIBUTACAO.codfiscalconsiginternac;
        END IF;
      END IF;

      -- Se for Cupom Fiscal --
      IF (TRIM(UPPER(t_PCPEDC.Serieecf)) = 'X') AND (pncondvenda = 4) AND
         (t_PCPEDC.tipocfoptv4 = 'OS') THEN
        VRLOG.DESCRICAO := 'Definido CFOP de Cupom Fiscal';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        vncfoest   := 5929;
        vncfointer := 6929;
      END IF;

      -- Tarefa 30382
      IF T_PCPEDI.PVENDA = 0 -- Brinde
       THEN
        IF ROWTRIBUTACAO.usacfopbnfparabrinde = 'S' -- Tarefa 60930
         THEN
          VRLOG.DESCRICAO := 'Definido CFOP de brindes. PVENDA=0';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          vncfoest       := ROWTRIBUTACAO.CODFISCALBONIFIC; --vncfobonific;
          vncfointer     := ROWTRIBUTACAO.CODFISCALBONIFICINTER; --vncfobonificinter;
          vncfointernasc := ROWTRIBUTACAO.CODFISCALBONIFICINTERNASC; --vncfobonificinternasc;
        END IF;
      END IF;

      --Tarefa: 170840
      --Implementada a validação de venda triângular para os demais tipos de venda,
      --tendo em vista que no projeto 88516 não é citado um tipo de venda específico para a situação.
      IF (t_PCPEDC.vendatriangular = 'S') THEN
        VRLOG.DESCRICAO := 'Definido CFOP de venda triangular para pessoa ';
        IF NOT vbpessoafisica THEN
          IF ROWTRIBUTACAO.codfiscaltriangular IS NOT NULL THEN
            vncfoest       := ROWTRIBUTACAO.codfiscaltriangular;
          END IF;
          IF  ROWTRIBUTACAO.codfiscaltriangularinter IS NOT NULL THEN
            vncfointer     := ROWTRIBUTACAO.codfiscaltriangularinter;
          END IF;
          IF ROWTRIBUTACAO.codfiscaltriangularinternasc IS NOT NULL THEN
            vncfointernasc := ROWTRIBUTACAO.codfiscaltriangularinternasc;
          END IF;
        ELSE
          IF ROWTRIBUTACAO.codfiscaltriangularpf IS NOT NULL THEN
            vncfoest       := ROWTRIBUTACAO.codfiscaltriangularpf;
          END IF;
          IF  ROWTRIBUTACAO.codfiscaltriangularinterpf IS NOT NULL THEN
            vncfointer     := ROWTRIBUTACAO.codfiscaltriangularinterpf;
          END IF;
          IF ROWTRIBUTACAO.codfiscaltriangularinternascpf IS NOT NULL THEN
            vncfointernasc := ROWTRIBUTACAO.codfiscaltriangularinternascpf;
          END IF;
        END IF;
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      END IF;
      --Fim da tarefa: 170840

      --Tarefa 133549
      /*Projeto 125838 Processo de Venda Triangular com Entrega pelo Fornecedor */
      IF t_PCPEDC.fornecentrega = 'S' THEN
        VRLOG.DESCRICAO := 'CFOP do processo de venda triangular com Entrega pelo Fornecedor.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        vncfoest   := 5120;
        vncfointer := 6120;
      END IF;

      --Tarefa 134228
      IF T_PCPEDI.bonific = 'S' THEN
        VRLOG.DESCRICAO := 'Definido CFOP de venda bonificada. ';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        vncfoest   := ROWTRIBUTACAO.CODFISCALBONIFIC; -- vncfobonific;
        vncfointer := ROWTRIBUTACAO.CODFISCALBONIFICINTER; --vncfobonificinter;
      END IF;

      -----------------------------------------------------------
      --Autor: Rodrigo Santos
      --Solicitação: HIS.04000.2014
      --Data: 30/12/2014
      --Descrição: Implementação das regras para tributação quando
      --"pcclient.clientefontest = S".
      -----------------------------------------------------------
      IF (ROWcliente.Clientefontest = 'S') AND (not (NVL(T_PCPEDC.numnotaconsig, 0) > 0)) THEN
        VRLOG.DESCRICAO := 'Definido CFOP e CST de venda para cliente Fonte de ST.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfoest       := NVL(ROWTRIBUTACAO.codfiscalstfonteest,
                              vncfoest);
        vncfointer     := NVL(ROWTRIBUTACAO.codfiscalstfonteinterest,
                             vncfointer);
        vncfointernasc := NVL(ROWTRIBUTACAO.codfiscalstfonteinternac,
                              vncfointernasc);
      END IF;
      -----------------------------------------------------------

      IF((UPPER(TRIM(ROWCLIENTE.TIPOEMPRESA)) = 'PR') and (ROWTRIBUTACAO.PRODRURALCALCDIFER = 'S') --HIS.02480.2018
            AND ROWCLIENTE.CONTRIBUINTE = 'S' AND ROWCLIENTE.IEENT NOT IN('ISENTO', 'ISENTA')) THEN
            VRLOG.DESCRICAO := 'Definido CST de Produtor Rural, IE não-isento(a) e Contribuinte = S.';
            GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        IF(NVL(ROWTRIBUTACAO.SITTRIBUTPRODRURALCALCDIFER,'XX') <> 'XX')THEN
                vssittribut := ROWTRIBUTACAO.SITTRIBUTPRODRURALCALCDIFER;
        END IF;
      END IF;
    END IF; -- IF pncondvenda NOT IN (5, 7, 8, 9, 10, 11, 13, 14, 20)
	
	IF pncondvenda NOT IN (7, 8, 9) THEN
	
		IF (ROWcliente.Clientefontest = 'S') AND (not (NVL(T_PCPEDC.numnotaconsig, 0) > 0)) THEN
			GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

			IF vbpessoafisica THEN
			  vssittribut := NVL(ROWTRIBUTACAO.sittribstfontepf, vssittribut);
			  vncontrolcst := vncontrolcst + 1;
			ELSE
			  vssittribut := NVL(ROWTRIBUTACAO.sittribstfontepj, vssittribut);
			  vncontrolcst := vncontrolcst + 1;
			END IF;

		END IF;
	END IF;
	 --HIS.02047.2016
   IF(UPPER(TRIM(ROWCLIENTE.TIPOEMPRESA)) = 'MEI') and (ROWTRIBUTACAO.MEINAOCALCDIF = 'S')then
		-- vnperdifereimentoicms := 0;
		IF(NVL(ROWTRIBUTACAO.sittributmei,'XX') <> 'XX')
		and pncondvenda in(1, 4, 5, 9, 11) THEN
         vssittribut := ROWTRIBUTACAO.sittributmei;
        END IF;
     END IF;

    IF pncondvenda = 7 --Se for Venda Entrega Futura --
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda TV7';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      IF(NVL(T_PCPEDC.contaordem, 'N') <> 'S' and NVL(T_PCPEDC.vendatriangular,'N') <> 'S')THEN
        vncfoest   := ROWTRIBUTACAO.CODFISCALVENDAENTFUT; -- vncfovendaentfut;
        vncfointer := ROWTRIBUTACAO.CODFISCALVENDAENTFUTINTER; --vncfovendaentfutinter;
      END IF;

      IF T_PCPEDC.contaordem = 'S' THEN
        VRLOG.DESCRICAO := 'Definido CFOP de venda TV7 Conta Ordem';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfoest   := ROWTRIBUTACAO.CODFISCALCONTAORDEM; --vncfopcontaordem;
        vncfointer := ROWTRIBUTACAO.CODFISCALCONTAORDEMINTER; --vncfopcontaordeminter;
      END IF;

      --Tarefa 134475
      IF (ROWTRIBUTACAO.sittributtv7 IS NOT NULL) AND
         (NVL(T_PCPEDC.contaordem, 'X') <> 'S') THEN
        VRLOG.DESCRICAO := 'Definido CST de TV7';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vssittribut := ROWTRIBUTACAO.sittributtv7;
        vncontrolcst := vncontrolcst + 1;
      END IF;

      --HIS.03449.2017
      IF (ROWTRIBUTACAO.SITTRIBUTTV7ORDEM IS NOT NULL) AND
         (NVL(T_PCPEDC.contaordem, 'X') = 'S') THEN
        VRLOG.DESCRICAO := 'Definido CST de TV7 CONTA/ORDEM';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vssittribut := ROWTRIBUTACAO.SITTRIBUTTV7ORDEM;
        vncontrolcst := vncontrolcst + 1;
      END IF;

      -- Tarefa 104048 (Projeto 88516 - Venda Triangular)
      IF (T_PCPEDC.vendatriangular = 'S') THEN
        IF NOT vbpessoafisica THEN
          IF ROWTRIBUTACAO.codfiscaltriangular IS NOT NULL THEN
            vncfoest       := ROWTRIBUTACAO.codfiscaltriangular;
          END IF;
          IF  ROWTRIBUTACAO.codfiscaltriangularinter IS NOT NULL THEN
            vncfointer     := ROWTRIBUTACAO.codfiscaltriangularinter;
          END IF;
          IF ROWTRIBUTACAO.codfiscaltriangularinternasc IS NOT NULL THEN
            vncfointernasc := ROWTRIBUTACAO.codfiscaltriangularinternasc;
          END IF;
        ELSE
          IF ROWTRIBUTACAO.codfiscaltriangularpf IS NOT NULL THEN
            vncfoest       := ROWTRIBUTACAO.codfiscaltriangularpf;
          END IF;
          IF  ROWTRIBUTACAO.codfiscaltriangularinterpf IS NOT NULL THEN
            vncfointer     := ROWTRIBUTACAO.codfiscaltriangularinterpf;
          END IF;
          IF ROWTRIBUTACAO.codfiscaltriangularinternascpf IS NOT NULL THEN
            vncfointernasc := ROWTRIBUTACAO.codfiscaltriangularinternascpf;
          END IF;
        END IF;
      END IF;
    ELSIF pncondvenda = 8 -- Se for Simples Entrega Futura --
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda TV8';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      VNCFOEST   := ROWTRIBUTACAO.CODFISCALSIMPENTFUT; --VNCFOSIMPENTFUT;
      VNCFOINTER := ROWTRIBUTACAO.CODFISCALSIMPENTFUTINTER; --VNCFOSIMPENTFUTINTER;

      --HIS.03449.2017
      IF (ROWTRIBUTACAO.SITTRIBUTTV8 IS NOT NULL) AND
         (NVL(T_PCPEDC.contaordem, 'X') <> 'S') THEN
        VSSITTRIBUT := ROWTRIBUTACAO.SITTRIBUTTV8; --Solicitação: 3221.003077.2013
        vncontrolcst := vncontrolcst + 1;
      ELSIF VBPESSOAFISICA THEN
        VSSITTRIBUT := ROWTRIBUTACAO.SITTRIBUTPF;
        vncontrolcst := vncontrolcst + 1;
      END IF;

      --HIS.03449.2017
      IF (ROWTRIBUTACAO.SITTRIBUTTV8ORDEM IS NOT NULL) AND
         (NVL(T_PCPEDC.contaordem, 'X') = 'S') THEN
        VSSITTRIBUT := ROWTRIBUTACAO.SITTRIBUTTV8ORDEM;
        vncontrolcst := vncontrolcst + 1;
      END IF;

      IF t_PCPEDC.Contaordem = 'S' THEN
        VNCFOEST   := ROWTRIBUTACAO.CODFISCALCONTAORDEMSIMPENT; --VNCFOPCONTAORDEMSIMPENT;
        VNCFOINTER := ROWTRIBUTACAO.CODFISCALCONTAORDEMSIMPENTINTE; --VNCFOPCONTAORDEMSIMPENTINTE;
      END IF;

      -- Tarefa 104048 (Projeto 88516 - Venda Triangular)
      IF (t_PCPEDC.vendatriangular = 'S') AND (pncondvenda <> 20) THEN
        IF NOT vbpessoafisica THEN
          IF ROWTRIBUTACAO.codfiscaltriangular IS NOT NULL THEN
            vncfoest       := ROWTRIBUTACAO.codfiscaltriangular;
          END IF;
          IF  ROWTRIBUTACAO.codfiscaltriangularinter IS NOT NULL THEN
            vncfointer     := ROWTRIBUTACAO.codfiscaltriangularinter;
          END IF;
          IF ROWTRIBUTACAO.codfiscaltriangularinternasc IS NOT NULL THEN
            vncfointernasc := ROWTRIBUTACAO.codfiscaltriangularinternasc;
          END IF;
        ELSE
          IF ROWTRIBUTACAO.codfiscaltriangularpf IS NOT NULL THEN
            vncfoest       := ROWTRIBUTACAO.codfiscaltriangularpf;
          END IF;
          IF  ROWTRIBUTACAO.codfiscaltriangularinterpf IS NOT NULL THEN
            vncfointer     := ROWTRIBUTACAO.codfiscaltriangularinterpf;
          END IF;
          IF ROWTRIBUTACAO.codfiscaltriangularinternascpf IS NOT NULL THEN
            vncfointernasc := ROWTRIBUTACAO.codfiscaltriangularinternascpf;
          END IF;
        END IF;
      END IF;
    ELSIF pncondvenda = 9 -- tarefa 81651
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda TV9';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      --
      IF ROWTRIBUTACAO.SITTRIBUTTV9 IS NOT NULL THEN
        VRLOG.DESCRICAO := 'Definido CST de Venda TV9';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vssittribut := ROWTRIBUTACAO.SITTRIBUTTV9;
        vncontrolcst := vncontrolcst + 1;
      END IF;
      --
      vncfoest       := ROWTRIBUTACAO.codfiscaltv9;
      vncfointer     := ROWTRIBUTACAO.codfiscalintertv9;
      vncfointernasc := ROWTRIBUTACAO.codfiscalinternasctv9;
    ELSIF ((pncondvenda = 10) AND (t_PCPEDC.usacfopvendanatv10 = 'N')) -- Transferência
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda TV10 (usacfopvendatv10 = ''N'')';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vncfoest       := ROWTRIBUTACAO.CODFISCALTRANSF; --vncfotransf;
      vncfointer     := ROWTRIBUTACAO.CODFISCALTRANSFINTER; --vncfotransfinter;
      vncfointernasc := ROWTRIBUTACAO.CODFISCALTRANSFINTERNASC; --vncfotransfinternasc;

      if (NVL(ROWTRIBUTACAO.sittributtransf, 'XX') <> 'XX') and
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USARTRIBUTACAOTRANSFTV10',
                                              '99',
                                              'N') = 'S') then
         vssittribut :=  ROWTRIBUTACAO.sittributtransf;
      end if;

    ELSIF pncondvenda = 11 -- Troca
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda TV11';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vncfoest       := ROWTRIBUTACAO.codfiscaltroca;
      vncfointer     := ROWTRIBUTACAO.codfiscaltrocainter;
      vncfointernasc := ROWTRIBUTACAO.codfiscaltrocainternasc;
    ELSIF (pncondvenda = 13) -- Se for Manifesto --
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda TV13(Venda manifesto)';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vncfoest       := ROWTRIBUTACAO.CODFISCALPRONTAENT; --vncfoprontaent;
      vncfointer     := ROWTRIBUTACAO.CODFISCALPRONTAENTINTER; --vncfoprontaentinter;
      vncfointernasc := ROWTRIBUTACAO.CODFISCALPRONTAENTINTERNASC; --vncfoprontaentinternasc;
	  
      /* FOI DECIDIDO JUNTO AO PO QUE ADOTAREMOS ESSA SOLUÇÃO ABAIXO ATÉ A LIBERAÇÃO
         DO MOTOR DE EXCEÇÃO. PARA EVITARMOS A CRIAÇÃO DE MAIS UM SITTRIBUT NA 514
         OPTAMOS POR ADICIONAR ESSA CONDIÇÃO ABAIXO 
      */
      IF ROWFILIAL.DESTACARIMPOSTOSVENDATV13 = 'N' THEN
        VSSITTRIBUT := '41';
      END IF;
    ELSIF pncondvenda IN (4, 14)  THEN
      IF ((ROWTRIBUTACAO.CODFISCALVENDAPRONTAENT IS NOT NULL) AND
         (ROWTRIBUTACAO.CODFISCALVENDAPRONTAENTINTER IS NOT NULL) AND
         (pncondvenda = 14)) OR
         (((ROWTRIBUTACAO.CODFISCALVENDAPRONTAENT IS NOT NULL) AND
         (ROWTRIBUTACAO.CODFISCALVENDAPRONTAENTINTER IS NOT NULL)) AND
         ((pncondvenda = 4) AND (T_pcpedc.prontaentrega = 'S'))) THEN
        VRLOG.DESCRICAO := 'Definido CFOP de venda Pronta Entrega';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfoest   := ROWTRIBUTACAO.CODFISCALVENDAPRONTAENT;
        vncfointer := ROWTRIBUTACAO.CODFISCALVENDAPRONTAENTINTER;
      END IF;

      IF ((SUBSTR(T_pcpedc.codcob, 1, 3) = 'BNF') OR
         (T_pcpedc.codcob = 'BNTR')) THEN
        VRLOG.DESCRICAO := 'Definido CFOP de Bonificação';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vncfoest       := ROWTRIBUTACAO.Codfiscalbonific; --vncfobonific;
        vncfointer     := ROWTRIBUTACAO.Codfiscalbonificinter; --vncfobonificinter;
        vncfointernasc := ROWTRIBUTACAO.Codfiscalbonificinternasc; --vncfobonificinternasc;
      END IF;
    ELSIF pncondvenda = 20 -- Se for Venda Consignada --
     THEN
      VRLOG.DESCRICAO := 'Definido CFOP de venda Consignada';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vncfoest       := ROWTRIBUTACAO.Codfiscalvendaconsig; --vncfovendaconsig;
      vncfointer     := ROWTRIBUTACAO.Codfiscalvendaconsiginter; --vncfovendaconsiginter;
      vncfointernasc := ROWTRIBUTACAO.Codfiscalvendaconsiginternasc; --vncfovendaconsiginternasc;
    END IF;

    -- Tarefa 213468 - CST - Clientes orgão públicos municipal, estadual e federal
    -- HIS.01120.2013 - Caso o cliente seja do "tipo empresa" igual a "R" (Regime Especial)
    IF (((ROWCLIENTE.Orgaopub = 'S') OR
       (ROWCLIENTE.orgaopubmunicipal = 'S') OR
       (ROWCLIENTE.orgaopubfederal = 'S') OR
       ((UPPER(TRIM(ROWCLIENTE.TIPOEMPRESA)) = 'R')and pncondvenda <> 9)) AND  --4346.021024.2019: Não validar TV9 para Regime Especial.
       (ROWTRIBUTACAO.sittributorgaopub is not null)) THEN
        VRLOG.DESCRICAO := 'Definido CST de cliente Orgão Público.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vssittribut := ROWTRIBUTACAO.sittributorgaopub;
      vncontrolcst := vncontrolcst + 1;
    END IF;

    ------- HIS.02571.2015 -------
    IF (vsItemTV1Bnf = 'S') AND (pncondvenda IN (1, 14)) THEN
      VRLOG.DESCRICAO := 'Definido CFOP e CST de para item bonificado no pedido TV1/TV14.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      if (pncondvenda = 1) and (ROWTRIBUTACAO.SITTRIBUTBNFTV1 is not null) then
        vssittribut    := ROWTRIBUTACAO.SITTRIBUTBNFTV1;
      elsif (ROWTRIBUTACAO.SITTRIBUTBNFTV14 is not null) then
        vssittribut    := ROWTRIBUTACAO.SITTRIBUTBNFTV14;
      END IF;

      vncfoest       := ROWTRIBUTACAO.Codfiscalbonific; -- vncfobonific;
      vncfointer     := ROWTRIBUTACAO.Codfiscalbonificinter; -- vncfobonificinter;
      vncfointernasc := ROWTRIBUTACAO.Codfiscalbonificinternasc; -- vncfobonificinternasc;
      vncontrolcst   := vncontrolcst + 1;
    END IF;

    IF (NVL(ROWTRIBUTACAO.SITTRIBUTTRIANG, 0) <> 0) and
       nvl(t_pcpedc.vendatriangular, 'N') = 'S' THEN
      VRLOG.DESCRICAO := 'Definido CST de venda triângular.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vssittribut := ROWTRIBUTACAO.SITTRIBUTTRIANG;
    END IF;

    ------HIS.00488.2016-------
    IF (ROWPRODUTO.Verifcramoativcalcst = 'S') AND
       (vsRamoAtividadeCalculaST = 'N') AND
       (ROWTRIBUTACAO.codfiscalisentostramo IS NOT NULL)
	   and (not (NVL(T_PCPEDC.numnotaconsig, 0) > 0))
	then
      VRLOG.DESCRICAO := 'Definido CFOP e CST de Ramo de Atividade Isento de ST.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      vssittribut := ROWTRIBUTACAO.sittributisentostramo;
      vncfoest    := ROWTRIBUTACAO.codfiscalisentostramo;
      vncfointer  := ROWTRIBUTACAO.codfiscalisentostramointer;
      vncontrolcst := vncontrolcst + 1;
    END IF;

    IF vncontrolcst > 1 THEN
      IF ROWTRIBUTACAO.sittributpriorit IS NOT NULL THEN
        VRLOG.DESCRICAO := 'Definido CST prioritário.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        vssittribut := ROWTRIBUTACAO.sittributpriorit;
      END IF;
    END IF;

     --2752.066696.2015-> bonificação separado dos demais para sempre receber
    --o CFOP destinado, conforme solicitado. (Rafael Braga)
    IF pncondvenda IN (5) THEN
      IF pncodbnf = 5 THEN
        vncfoest       := ROWTRIBUTACAO.codfiscaltroca;
        vncfointer     := ROWTRIBUTACAO.codfiscaltrocainter;
        vncfointernasc := ROWTRIBUTACAO.codfiscaltrocainternasc;

      ELSIF (pncodbnf = 4) AND (t_pcpedc.cfopbnfdegusta IS NOT NULL) THEN
        vncfoest       := t_pcpedc.cfopbnfdegusta; --pcfopbnfdegusta;
        vncfointer     := t_pcpedc.cfopbnfdegusta; --pcfopbnfdegusta;
        vncfointernasc := t_pcpedc.cfopbnfdegusta; --pcfopbnfdegusta;

      ELSE
        vncfoest       := ROWTRIBUTACAO.Codfiscalbonific; --vncfobonific;
        vncfointer     := ROWTRIBUTACAO.Codfiscalbonificinter; --vncfobonificinter;
        vncfointernasc := ROWTRIBUTACAO.Codfiscalbonificinternasc; --vncfobonificinternasc;
      END IF;

      --Tarefa 144179
      IF (ROWTRIBUTACAO.isentaicmsbonific = 'S') AND
         (nvl(ROWTRIBUTACAO.sittributbonific, '0') <> '0') AND --Tarefa: 201381
         (UPPER(LTRIM(RTRIM(ROWcliente.Estent))) = UPPER(LTRIM(RTRIM(ROWFILIAL.UF)))) --Tarefa: 1937.046304.2017
       THEN
        vssittribut := ROWTRIBUTACAO.sittributbonific;
        vncontrolcst := vncontrolcst + 1;
      END IF;
      --Fim tarefa 144179

	  IF (ROWTRIBUTACAO.isentaicmsbonificint = 'S') AND
         (nvl(ROWTRIBUTACAO.sittributbonificint, '0') <> '0') AND --Tarefa: 201381
         (UPPER(LTRIM(RTRIM(ROWcliente.Estent))) <> UPPER(LTRIM(RTRIM(ROWFILIAL.UF)))) --Tarefa: 1937.046304.2017
       THEN
        vssittribut := ROWTRIBUTACAO.sittributbonificint;
        vncontrolcst := vncontrolcst + 1;
      END IF;

      --História HIS.02559.2014
      IF UPPER(TRIM(ROWCLIENTE.TIPOEMPRESA)) = 'NRPA' THEN
        vssittribut := ROWTRIBUTACAO.sittributnrpa;
        vncontrolcst := vncontrolcst + 1;
      END IF;
      -- fim HIS.02559.2014

    END IF; --pncondvenda IN (5)

    IF t_pcpedc.opervendaexpindireta = 'S'
    AND pncondvenda in('1', '5', '9')
     THEN
        vncfoest       := NVL(ROWTRIBUTACAO.Codfiscalvendaexpindireta,vncfoest);
        vncfointer     := NVL(ROWTRIBUTACAO.Codfiscalvendaexpindiretainter,vncfointer);
        vssittribut    := NVL(ROWTRIBUTACAO.Sittributvendaexpindireta,vssittribut);
    END IF;
	
    ----------------------- DEFINIÇÃO DE CFOP --------------------------------
    CASE UPPER(LTRIM(RTRIM(ROWcliente.Estent))) --vsestent_client
      WHEN 'EX' THEN
        vnCODFISCAL := vncfointernasc; -- CLIENTE ESTRANGEIRO
      WHEN ROWFILIAL.UF THEN
        vnCODFISCAL := vncfoest; -- CLIENTE ESTADUAL
      ELSE
        vnCODFISCAL := vncfointer; -- CLIENTE INTERESTADUAL
    END CASE;

    --SE FOR VENDA EXPORTAÇÃO
    IF t_pcpedc.VENDAEXPORTACAO = 'S' THEN
      vnCODFISCAL := vncfointernasc;
    END IF;

    --SE FOR VENDA LOCAL PARA ESTRANGEIRO.(HIS.03059.2015)
    IF t_pcpedc.VENDALOCESTRANG = 'S' THEN
      vnCODFISCAL := vncfoest;
    END IF;

    --- RETORNA O CFOP e o CST (SITTRIBUT)-----------
    P_CODFISCAL := vnCODFISCAL;
    P_SITTRIBUT := vssittribut;
    VRLOG.DESCRICAO := 'CFOP de Retorno = ' || P_CODFISCAL || '; CST de retorno = ' || P_SITTRIBUT;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    -------------------------------------------------

  END DEFINIRCODFISCAL;

  PROCEDURE DEFINIR_TRIBUTOS(P_CODPROD       IN  NUMBER
                            ,P_CODFILIAL     IN  VARCHAR2
                            ,P_CODCLI        IN  NUMBER
                            ,P_CODST         IN  NUMBER
                            ,P_TRIBMUNICIPAL OUT NUMBER
                            ,P_TRIBESTADUAL  OUT NUMBER
                            ,P_TRIBFEDERAL   OUT NUMBER)
  /******************************************************************************************
    ->Nome da PROCEDURE : DEFINIR_TRIBUTOS
    ->Objetivo          : Retornar o valor de tributos da NF, referente à lei da transparência.
    ->Versao            : Pacote
    ->Utilização        : 1419

    -------------------------------- Historico ------------------------------------------------
    Data         Realizado por      Tarefa       Comentarios
    -----------  --------------------- Historico ------------------------------------------------
    31/10/2016   Guilherme Freitas               Criação da procedure

    -------------------------------------------------------------------------------------------*/
  IS
    REG_PCTRIBNCMFILIAL    PCTRIBNCMFILIAL%ROWTYPE;
    VSNBM                  PCPRODUT.NBM%TYPE;
    VSIMPORTADO            PCPRODUT.IMPORTADO%TYPE;
    VNCODPROD              PCPRODUT.CODPROD%TYPE;
    VSCODFILIAL            PCPEDC.CODFILIAL%TYPE;
    VBPESSOAFISICA         BOOLEAN;
    VNCODCLI               PCPEDC.CODCLI%TYPE;
    VNPERCTRIBUTOS         PCMOVCOMPLE.VLITEMTRIBUTOS%TYPE;
    VNPERCTRIBUTOSESTADUAL PCMOVCOMPLE.VLITEMTRIBUTOSEST%TYPE;
    VNPERCTRIBUTOSMUNIC    PCMOVCOMPLE.VLITEMTRIBUTOSMUNIC%TYPE;
    VNCODST                PCMOV.CODST%TYPE;
    VSCODNCMEX             PCPRODUT.CODNCMEX%TYPE;
  BEGIN
    VNCODPROD   := P_CODPROD;
    VSCODFILIAL := P_CODFILIAL;
    VNCODCLI    := P_CODCLI;
    VNCODST     := P_CODST;

    VBPESSOAFISICA := (FERRAMENTAS.VERIFICAR_FJ(VNCODCLI) = 'PESSOA FISICA');

    SELECT NBM, CODNCMEX, NVL(IMPORTADO, 'N')
      INTO VSNBM, VSCODNCMEX, VSIMPORTADO
      FROM PCPRODUT
     WHERE CODPROD = VNCODPROD;

    BEGIN
      SELECT PCTRIBNCMFILIAL.*
        INTO REG_PCTRIBNCMFILIAL
        FROM PCTRIBNCMFILIAL
       WHERE PCTRIBNCMFILIAL.CODNCM = CASE
               WHEN INSTR(PCTRIBNCMFILIAL.CODNCM, '.') > 0 THEN
                VSCODNCMEX
               ELSE
                VSNBM
             END
         AND ((PCTRIBNCMFILIAL.CODFILIAL = VSCODFILIAL) OR
             (PCTRIBNCMFILIAL.CODFILIAL = '99' AND NOT EXISTS
              (SELECT 1
                  FROM PCTRIBNCMFILIAL A
                 WHERE A.CODNCM = PCTRIBNCMFILIAL.CODNCM
                   AND A.CODFILIAL = VSCODFILIAL)));
    EXCEPTION
      WHEN OTHERS THEN
        REG_PCTRIBNCMFILIAL := NULL;
    END;

    SELECT NVL(PCTRIBUT.PERCTRIBUTOS, 0)
      INTO VNPERCTRIBUTOS
      FROM PCTRIBUT
     WHERE PCTRIBUT.CODST = VNCODST;

    IF NOT VBPESSOAFISICA
    THEN
      --PESSOA JURIDICA
      IF ((VSIMPORTADO = 'D') OR (VSIMPORTADO = 'S')) -- PRODUTOS IMPORTADOS
      THEN

        IF REG_PCTRIBNCMFILIAL.PERCENTJURIDICAIMPORTADO IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCJURIDICESTIMP IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCJURIDICMUNICIMP IS NOT NULL
        THEN
          -- % FEDERAL
          IF REG_PCTRIBNCMFILIAL.PERCENTJURIDICAIMPORTADO IS NOT NULL
          THEN
            VNPERCTRIBUTOS := REG_PCTRIBNCMFILIAL.PERCENTJURIDICAIMPORTADO;
          ELSE
            VNPERCTRIBUTOS := 0;
          END IF;

          -- % ESTADUAL
          IF REG_PCTRIBNCMFILIAL.PERCJURIDICESTIMP IS NOT NULL
          THEN
            VNPERCTRIBUTOSESTADUAL := REG_PCTRIBNCMFILIAL.PERCJURIDICESTIMP;
          ELSE
            VNPERCTRIBUTOSESTADUAL := 0;
          END IF;

          -- % MUNICIPAL
          IF REG_PCTRIBNCMFILIAL.PERCJURIDICMUNICIMP IS NOT NULL
          THEN
            VNPERCTRIBUTOSMUNIC := REG_PCTRIBNCMFILIAL.PERCJURIDICMUNICIMP;
          ELSE
            VNPERCTRIBUTOSMUNIC := 0;
          END IF;

        END IF;

        -- FIM PRODUTOS IMPORTADOS
      ELSE
        -- PRODUTOS NACIONAIS

        IF REG_PCTRIBNCMFILIAL.PERCENTJURIDICA IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCJURIDICESTNAC IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCJURIDICMUNICNAC IS NOT NULL
        THEN

          -- % FEDERAL
          IF REG_PCTRIBNCMFILIAL.PERCENTJURIDICA IS NOT NULL
          THEN
            VNPERCTRIBUTOS := REG_PCTRIBNCMFILIAL.PERCENTJURIDICA;
          ELSE
            VNPERCTRIBUTOS := 0;
          END IF;

          -- % ESTADUAL
          IF REG_PCTRIBNCMFILIAL.PERCJURIDICESTNAC IS NOT NULL
          THEN
            VNPERCTRIBUTOSESTADUAL := REG_PCTRIBNCMFILIAL.PERCJURIDICESTNAC;
          ELSE
            VNPERCTRIBUTOSESTADUAL := 0;
          END IF;

          -- % MUNICIPAL
          IF REG_PCTRIBNCMFILIAL.PERCJURIDICMUNICNAC IS NOT NULL
          THEN
            VNPERCTRIBUTOSMUNIC := REG_PCTRIBNCMFILIAL.PERCJURIDICMUNICNAC;
          ELSE
            VNPERCTRIBUTOSMUNIC := 0;
          END IF;
          -- FIM PRODUTOS IMPORTADOS
        END IF;
      END IF;
    ELSE
      -- PESSOA FISICA
      IF ((VSIMPORTADO = 'D') OR (VSIMPORTADO = 'S')) -- PRODUTOS IMPORTADOS
      THEN
        IF REG_PCTRIBNCMFILIAL.PERCENTFISICAIMPORTADO IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCFISICAESTIMP IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCFISICAMUNICIMP IS NOT NULL
        THEN
          -- % FEDERAL
          IF REG_PCTRIBNCMFILIAL.PERCENTFISICAIMPORTADO IS NOT NULL
          THEN
            VNPERCTRIBUTOS := REG_PCTRIBNCMFILIAL.PERCENTFISICAIMPORTADO;
          ELSE
            VNPERCTRIBUTOS := 0;
          END IF;

          -- % ESTADUAL
          IF REG_PCTRIBNCMFILIAL.PERCFISICAESTIMP IS NOT NULL
          THEN
            VNPERCTRIBUTOSESTADUAL := REG_PCTRIBNCMFILIAL.PERCFISICAESTIMP;
          ELSE
            VNPERCTRIBUTOSESTADUAL := 0;
          END IF;

          -- % MUNICIPAL
          IF REG_PCTRIBNCMFILIAL.PERCFISICAMUNICIMP IS NOT NULL
          THEN
            VNPERCTRIBUTOSMUNIC := REG_PCTRIBNCMFILIAL.PERCFISICAMUNICIMP;
          ELSE
            VNPERCTRIBUTOSMUNIC := 0;
          END IF;
          -- FIM PRODUTOS IMPORTADOS
        END IF;

      ELSE
        -- PRODUTOS NACIONAIS
        IF REG_PCTRIBNCMFILIAL.PERCENTFISICA IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCFISICAESTNAC IS NOT NULL OR
           REG_PCTRIBNCMFILIAL.PERCFISICAMUNICNAC IS NOT NULL
        THEN
          -- % FEDERAL
          IF REG_PCTRIBNCMFILIAL.PERCENTFISICA IS NOT NULL
          THEN
            VNPERCTRIBUTOS := REG_PCTRIBNCMFILIAL.PERCENTFISICA;
          ELSE
            VNPERCTRIBUTOS := 0;
          END IF;

          -- % ESTADUAL
          IF REG_PCTRIBNCMFILIAL.PERCFISICAESTNAC IS NOT NULL
          THEN
            VNPERCTRIBUTOSESTADUAL := REG_PCTRIBNCMFILIAL.PERCFISICAESTNAC;
          ELSE
            VNPERCTRIBUTOSESTADUAL := 0;
          END IF;

          -- % MUNICIPAL
          IF REG_PCTRIBNCMFILIAL.PERCFISICAMUNICNAC IS NOT NULL
          THEN
            VNPERCTRIBUTOSMUNIC := REG_PCTRIBNCMFILIAL.PERCFISICAMUNICNAC;
          ELSE
            VNPERCTRIBUTOSMUNIC := 0;
          END IF;
        END IF;
        -- FIM PRODUTOS NACIONAIS
      END IF;
    END IF;

    P_TRIBMUNICIPAL := VNPERCTRIBUTOSMUNIC;
    P_TRIBESTADUAL  := VNPERCTRIBUTOSESTADUAL;
    P_TRIBFEDERAL   := VNPERCTRIBUTOS;

  END DEFINIR_TRIBUTOS;

  FUNCTION RETORNAR_ICMS(P_NUMPED  IN NUMBER
                        ,P_GERALOG IN VARCHAR2 DEFAULT 'N'
                        ,P_CODPROD IN NUMBER DEFAULT 0
                        ,P_NUMSEQ  IN NUMBER DEFAULT 0)
    RETURN TB_DADOS_ICMS
    PIPELINED IS
    DADOS_SAIDA TR_DADOS_ICMS;
    VRLOG       PCLOGIMPOSTOS%ROWTYPE;
    PEDIDO      ITENS_PEDIDO%ROWTYPE;
  BEGIN
    VRLOG.OBJETO    := 'RETORNAR_ICMS';
    G_GERARLOG      := P_GERALOG;
    VRLOG.NUMPED    := P_NUMPED;
    VRLOG.CODPROD   := P_CODPROD;
    VRLOG.NUMSEQ    := P_NUMSEQ;
    VRLOG.DESCRICAO := 'Inicio da RETORNAR_BASE_ICMS. ' || CHR(13) ||
                       'Parâmetros Entrada : ' || CHR(13) ||
                       ' P_NUMPED  = ' || P_NUMPED || CHR(13) ||
                       ' P_CODPROD = ' || P_CODPROD || CHR(13) ||
                       ' P_NUMSEQ  = ' || P_NUMSEQ;

    BEGIN
      SELECT NUMTRANSVENDA
        INTO VRLOG.NUMTRANSVENDA
        FROM PCPEDC
       WHERE NUMPED = P_NUMPED;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        VRLOG.NUMTRANSVENDA := NULL;
    END;

    GRAVARLOG(VRLOG,
              (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN
               DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
               TO_CHAR($$PLSQL_LINE) END));

    /* SE UTILIZAR CHAVE TRIPLA, E FOR BUSCAR POR ITEM, É OBRIGATÓRIO INFORMAR QUAL O NUMSEQ DO MESMO */
    IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USACHAVETRIPLAPCPEDI',
                                           '99',
                                           'N') = 'S') AND
       ((P_CODPROD > 0) AND (P_NUMSEQ <= 0))
    THEN
      VRLOG.DESCRICAO := 'Sistema parametrizado para permitir incluir item mais de uma vez no mesmo pedido(CON_USACHAVETRIPLAPCPEDI).' ||
                         CHR(13) ||
                         'Foi informado o código do produto, porém o sequencial do mesmo não foi informado. Não será possível obter a base de ICMS';

      GRAVARLOG(VRLOG,
                (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN
                 DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
                 TO_CHAR($$PLSQL_LINE) END));
      RETURN;
    END IF;

    BEGIN
      OPEN ITENS_PEDIDO(P_NUMPED, P_CODPROD, P_NUMSEQ);

      FETCH ITENS_PEDIDO
        INTO PEDIDO;

      WHILE ITENS_PEDIDO%FOUND
      LOOP
        VRLOG.DESCRICAO := 'Inicio loop de itens. Produto: ' ||
                           PEDIDO.CODPROD || '; Num. Seq.: ' || PEDIDO.NUMSEQ;
        VRLOG.CODPROD := PEDIDO.CODPROD;
        VRLOG.NUMSEQ  := PEDIDO.NUMSEQ;
        GRAVARLOG(VRLOG,
                  (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN
                   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
                   TO_CHAR($$PLSQL_LINE) END));

        DADOS_SAIDA := RETORNAR_ICMS_PROD(PEDIDO);
        
       
        PIPE ROW(DADOS_SAIDA);
        
        FETCH ITENS_PEDIDO
          INTO PEDIDO;

      END LOOP;

      CLOSE ITENS_PEDIDO;         
    EXCEPTION
      WHEN OTHERS THEN
        IF ITENS_PEDIDO%ISOPEN
        THEN
           CLOSE ITENS_PEDIDO;
        END IF;
    
    END;
    RETURN;
  END;

  FUNCTION RETORNAR_ICMS_PROD(PEDIDO IN OUT ITENS_PEDIDO%ROWTYPE) RETURN TR_DADOS_ICMS IS
    DADOS_SAIDA TR_DADOS_ICMS;

    VRLOG                   PCLOGIMPOSTOS%ROWTYPE;
    VNPERCBASERED           PCTRIBUT.PERCBASERED%TYPE;
    VSISENTOICMS_CLIENT     PCCLIENT.ISENTOICMS%TYPE;
    VSAGREGARIPIBASEICMS_CLIENT     PCCLIENT.AGREGARIPIBASEICMS%TYPE;
    VBPESSOAFISICA          BOOLEAN;
    VNPERCBASEREDCONSUMIDOR PCTRIBUT.PERCBASEREDCONSUMIDOR%TYPE;
    VNPERBASEREDNRPA        PCTRIBUT.PERBASEREDNRPA%TYPE;
    VNCODICM                PCTRIBUT.CODICM%TYPE;
    --VNCODICM2                    PCTRIBUT.CODICM%TYPE;
    VNVLBASEICMS_AUX             NUMBER;
    VNVLBASEICMS_AUX2            NUMBER;
    VNSUBTOT_AUX                 NUMBER;
    VSZERARBASEICMSORGPUBSUFRAMA PCTRIBUT.ZERARBASEICMSORGPUBSUFRAMA%TYPE;
    VSUSAISENCAOICMSVP           PCTRIBUT.USAISENCAOICMSVP%TYPE;
    VSORGAOPUB_CLIENT            PCCLIENT.ORGAOPUB%TYPE;
    VSORGAOPUBFEDERAL_CLIENT     PCCLIENT.ORGAOPUBFEDERAL%TYPE;
    VSSUFRAMA_CLIENT             PCCLIENT.SULFRAMA%TYPE;
    VSUSADESCONTOICMS            PCCLIENT.USADESCONTOICMS%TYPE;
    VSESTENT_CLIENT              PCCLIENT.ESTENT%TYPE;
    VSCONSUMIDORFINAL_CLIENT     PCCLIENT.CONSUMIDORFINAL%TYPE;
    VSCONTRIBUINTE_CLIENT        PCCLIENT.CONTRIBUINTE%TYPE;
    VSDESCICMSREDUZBASEICMS      PCTRIBUT.DESCICMSREDUZBASEICMS%TYPE;
    VNVLPAUTAICMSINTEREST        PCTRIBUT.VLPAUTAICMSINTEREST%TYPE;
    VNPERCBASEREDADICIONALINTER  PCTRIBUT.PERCBASEREDADICIONALINTER%TYPE;
    VC2UF_FILIAL                 PCFILIAL.UF%TYPE;
    VSAPLICAREDICMSSEMIPIBA      PCTRIBUT.APLICAREDICMSSEMIPIBA%TYPE;
    VNPERPAUTAICMS               PCTRIBUT.PERPAUTAICMS%TYPE;
    VNPERPAUTAICMSINTER          PCTRIBUT.PERPAUTAICMSINTER%TYPE;
    VSUSAVLULTENTMEDIOBASEST     PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE;
    VNPERCBASEREDST              PCTRIBUT.PERCBASEREDST%TYPE;
    VNPUNIT_ULTENT               NUMBER;
    VNPRECOPAUTA                 NUMBER;
    VNNUMTRANSENT                NUMBER;
    VNPAUTA                      NUMBER;
    VSIMPORTADO_PRODUT           PCPRODUT.IMPORTADO%TYPE;
    VSISENTAICMSBONIFIC          PCTRIBUT.ISENTAICMSBONIFIC%TYPE;
	VSISENTAICMSBONIFICINT       PCTRIBUT.ISENTAICMSBONIFICINT%TYPE;
    VSSITTRIBUT                  PCTRIBUT.SITTRIBUT%TYPE;
    VSCALCULARICMSSITTRIBUT060   PCTRIBUT.CALCULARICMSSITTRIBUT060%TYPE;
    VSISENTAICMSSITTRIBUT041     PCTRIBUT.ISENTAICMSSITTRIBUT041%TYPE;
    VNBST_AUX                    NUMBER;
    VNIVA                        NUMBER;
    VNIVAFONTE                   NUMBER;

    VSCLIENTEFONTEST_CLIENT     PCCLIENT.CLIENTEFONTEST%TYPE;
    VNALIQICMS1FONTE            NUMBER;
    VNALIQICMS2FONTE            NUMBER;
    VNPERCBASEREDSTFONTE        NUMBER;
    VSCALCSTPF_CONSUM           PCCONSUM.CALCSTPF%TYPE;
    VSCALCULAST_CLIENT          PCCLIENT.CALCULAST%TYPE;
    VNST                        NUMBER;
    VSTIPOCALCULOGNRE           PCTRIBUT.TIPOCALCULOGNRE%TYPE;
    VNBSTGNRE_AUX               NUMBER;
    VSMOSTRARPVENDASEMST_CONSUM PCCONSUM.MOSTRARPVENDASEMST%TYPE;
    VSVALIDAVLMAXISENCAOSTPF    VARCHAR2(1);
    VNVLMAXISENCAOSTPF_FILIAL   PCFILIAL.VLMAXISENCAOSTPF%TYPE;
    VNCODST                     NUMBER;
    VSUSAALIQUOTATRANSFTV10     VARCHAR2(1);
    VNVLULTENTMES               PCTABPR.VLULTENTMES%TYPE;
    VNVALORULTENTBASEICMS       PCEST.VALORULTENT%TYPE;
    VSCLIENTE_EH_ISENTO         VARCHAR2(2);
    VNPERACRESCIMOFUNCEP        PCTRIBUT.PERACRESCIMOFUNCEP%TYPE;
    VNPERDIFEREIMENTOICMS       NUMBER(18,6);
    variavel                    formula.RVARIAVEL;
    vtVariaveis                 formula.tbVariaveis;
    resultado                   formula.tbvariaveis;
    vnvlpautaicmsest            pctribut.vlpautaicmsest%type;
    VBCALCULABASEMG				      BOOLEAN;
    vMsgAux                     VARCHAR2(1000);
    VSISENCAOSUFRAMA            PCCLIENT.ISENCAOSUFRAMA%TYPE;
    vsVALIDARAIZCNPJTRANSFVIRT  PCPARAMFILIAL.VALOR%TYPE;
    VSSOMARVALORDIFBCICMS       PCTRIBUT.SOMARVALORDIFBCICMS%TYPE;
    VVLR_IVA                    PCTABPR.VLULTENTMES%TYPE;

    PROCEDURE DEFINIR_BASEST(PN_PERCREDBASEST   IN NUMBER
                            ,PN_BASEICST        IN NUMBER
                            ,PS_VENDATRIANGULAR IN VARCHAR2
                            ,PN_STCLIENTEGNRE   IN NUMBER
                            ,PN_ALIQICMS1       IN NUMBER
                            ,PN_ALIQICMS2       IN NUMBER
                            ,PN_VLATEND         IN NUMBER
                            ,PN_CODPROD         IN NUMBER
                            ,PN_CODCLI          IN NUMBER)
    /******************************************************************************************
        ->Nome da PROCEDURE : DEFINIR_BASEST
        ->Objetivo          : Concentrar as regras de definição da base de st em um único lugar.
        ->Versao            : Pacote
      *******************************************************************************************/
     IS
    BEGIN

      VNBST_AUX := 0;

      IF PN_PERCREDBASEST IS NOT NULL
      THEN
        VNPERCBASEREDST := NVL(PN_PERCREDBASEST, 0);
      END IF;

      IF NVL(VNPERCBASEREDST, 0) = 0
      THEN
        VNPERCBASEREDST := 100;
      END IF;

      IF VNPAUTA <> 0
      THEN
        VNBST_AUX := VNPAUTA;
      ELSE
        VNBST_AUX := (((VNSUBTOT_AUX * (VNPERCBASEREDST / 100)) +
                     ((VNSUBTOT_AUX * (VNPERCBASEREDST / 100)) * VNIVA) / 100));
      END IF;

      IF NVL(VNPERCBASEREDST, 0) = 100
      THEN
        VNPERCBASEREDST := 0;
      END IF;

      IF (VNIVA = 0) AND (VSCLIENTEFONTEST_CLIENT = 'S') AND
         ((VNALIQICMS1FONTE > 0) OR (VNALIQICMS1FONTE > 0))
      THEN
        VNBST_AUX := ((VNSUBTOT_AUX * (VNPERCBASEREDSTFONTE / 100)) +
                     (((VNSUBTOT_AUX * (VNPERCBASEREDSTFONTE / 100)) *
                     VNIVAFONTE) / 100));
      END IF;

      IF PN_BASEICST IS NOT NULL
      THEN
        VNBST_AUX := PN_BASEICST;
      END IF;

      IF (NVL(VNIVA, 0) = 0) AND (NVL(VNPAUTA, 0) = 0) AND
         (NVL(PN_ALIQICMS1, 0) = 0) AND (NVL(PN_ALIQICMS2, 0) = 0) AND
         (VSCLIENTEFONTEST_CLIENT = 'S')
      THEN
        VNBST_AUX := 0;
      END IF;

      IF PS_VENDATRIANGULAR = 'S'
      THEN
        VNBST_AUX := 0;
      END IF;

      IF VSCALCSTPF_CONSUM = 'N'
      THEN
        IF VBPESSOAFISICA
        THEN
          VNBST_AUX := 0;
        END IF;
      END IF;

      IF (VSCALCULAST_CLIENT = 'N') AND (VSCLIENTEFONTEST_CLIENT = 'N')
      THEN
        VNBST_AUX := 0;
      END IF;

      IF (VNST = 0) AND (PN_BASEICST IS NULL)
      THEN
        VNBST_AUX := 0;
      END IF;

      IF VSTIPOCALCULOGNRE = 'C'
      THEN
        VNBSTGNRE_AUX := VNBST_AUX;
        VNBST_AUX     := 0;
      END IF;

      IF PN_STCLIENTEGNRE = 0
      THEN
        VNBSTGNRE_AUX := 0;
      END IF;

      IF (VBPESSOAFISICA) AND (VSCLIENTEFONTEST_CLIENT = 'N') AND
         (VSMOSTRARPVENDASEMST_CONSUM = 'N') AND
         (VSVALIDAVLMAXISENCAOSTPF = 'S') AND
         (ROUND(PN_VLATEND, 2) <= ROUND(VNVLMAXISENCAOSTPF_FILIAL, 2)) AND
         (VSESTENT_CLIENT = VC2UF_FILIAL)
      THEN

        VNBST_AUX := 0;

      END IF;

      --198310
      IF FERRAMENTAS.VERIFICAR_ISENTOST(PN_CODCLI,
                                        PN_CODPROD,
                                        VNCODST,
                                        VSUSAALIQUOTATRANSFTV10) = 'S'
      THEN
        VNBST_AUX     := 0;
        VNBSTGNRE_AUX := 0;
      END IF;
      /* 198310
      IF ((vscalculast_client = 'N') AND (vsconfaz_produt = 'N') AND
         ((vniva > 0) OR (vnpauta > 0))) --ST NORMAL
         OR ((vsclientefontest_client = 'N') AND (vnivafonte > 0) AND
         ((vnaliqicms1fonte > 0) OR (vnaliqicms2fonte > 0))) -- ST FONTE
      --Mesma regra para definição do CST para isentos de st em "definircodfiscalpcmov"
       THEN
        vnbst_aux     := 0;
        vnbstgnre_aux := 0;
      END IF;*/
    END DEFINIR_BASEST;
  BEGIN
    DADOS_SAIDA.NUMPED  := PEDIDO.NUMPED;
    DADOS_SAIDA.CODPROD := PEDIDO.CODPROD;
    DADOS_SAIDA.NUMSEQ  := PEDIDO.NUMSEQ;
    VRLOG.CODPROD       := PEDIDO.CODPROD;
    VRLOG.NUMSEQ        := PEDIDO.NUMSEQ;
    /*Tulio Sousa
      Inicializando os campos abaixo para evitar valores nulos na package de faturamento.
      Os mesmos só tem valores se usar o motor de calculo (UTILIZAMOTORCALCULO = S). Mas são usados no insert da
      PCMOVCOMPLE, e caso não utilize o motor, os valores chegam nulos para o calculo*/
    DADOS_SAIDA.VALOR_FECP_ICMS  := 0;
    DADOS_SAIDA.PERC_FECP_ICMS   := 0;
    DADOS_SAIDA.BASE_FECP_ICMS   := 0;

    VNPERCBASEREDCONSUMIDOR      := PEDIDO.PERCBASEREDCONSUMIDOR;
    VSZERARBASEICMSORGPUBSUFRAMA := PEDIDO.ZERARBASEICMSORGPUBSUFRAMA;
    VSUSAISENCAOICMSVP           := PEDIDO.USAISENCAOICMSVP;
    VSORGAOPUB_CLIENT            := PEDIDO.ORGAOPUB_CLIENT;
    VSORGAOPUBFEDERAL_CLIENT     := PEDIDO.ORGAOPUBFEDERAL_CLIENT;
    VSSUFRAMA_CLIENT             := PEDIDO.SUFRAMA_CLIENT;
    VSDESCICMSREDUZBASEICMS      := PEDIDO.DESCICMSREDUZBASEICMS;
    VSUSADESCONTOICMS            := PEDIDO.USADESCONTOICMS;
    VNVLPAUTAICMSINTEREST        := PEDIDO.VLPAUTAICMSINTEREST;
    VNVLPAUTAICMSEST             := PEDIDO.VLPAUTAICMSEST;
    VSESTENT_CLIENT              := PEDIDO.ESTENT_CLIENT;
    VC2UF_FILIAL                 := PEDIDO.UF_FILIAL;
    VSAPLICAREDICMSSEMIPIBA      := PEDIDO.APLICAREDICMSSEMIPIBA;
    VSCONSUMIDORFINAL_CLIENT     := PEDIDO.CONSUMIDORFINAL_CLIENT;
    VSCONTRIBUINTE_CLIENT        := PEDIDO.CONTRIBUINTE_CLIENT;
    VNPERPAUTAICMS               := PEDIDO.PERPAUTAICMS;
    VNPERCBASEREDADICIONALINTER  := PEDIDO.PERCBASEREDADICIONALINTER;
    VNPERPAUTAICMSINTER          := PEDIDO.PERPAUTAICMSINTER;
    VSUSAVLULTENTMEDIOBASEST     := PEDIDO.USAVLULTENTMEDIOBASEST;
    VNPAUTA                      := PEDIDO.PAUTA;
    VNPERCBASEREDST              := PEDIDO.PERCBASEREDST;
    VSIMPORTADO_PRODUT           := PEDIDO.IMPORTADO;
    VSISENTAICMSBONIFIC          := PEDIDO.ISENTAICMSBONIFIC;
    VSISENTAICMSBONIFICINT       := PEDIDO.ISENTAICMSBONIFICINT;
    VSCALCULARICMSSITTRIBUT060   := PEDIDO.CALCULARICMSSITTRIBUT060;
    VSISENTAICMSSITTRIBUT041     := PEDIDO.ISENTAICMSSITTRIBUT041;
    VSISENTOICMS_CLIENT          := PEDIDO.ISENTOICMS;
    VSAGREGARIPIBASEICMS_CLIENT  := PEDIDO.AGREGARIPIBASEICMS;
    VNPERCBASERED                := PEDIDO.PERCBASERED;
    VSSITTRIBUT                  := PEDIDO.SITTRIBUT_ITEM;
    -- base MG
    VSCLIENTEFONTEST_CLIENT     := PEDIDO.CLIENTEFONTEST;
    VNALIQICMS1FONTE            := PEDIDO.ALIQICMS1FONTE;
    VNALIQICMS2FONTE            := PEDIDO.ALIQICMS2FONTE;
    VNPERCBASEREDSTFONTE        := PEDIDO.PERCBASEREDSTFONTE;
    VSCALCSTPF_CONSUM           := PEDIDO.CALCSTPF;
    VSCALCULAST_CLIENT          := PEDIDO.CALCULAST;
    VNST                        := PEDIDO.ST;
    VSTIPOCALCULOGNRE           := PEDIDO.TIPOCALCULOGNRE;
    VNBSTGNRE_AUX               := 0;
    VSMOSTRARPVENDASEMST_CONSUM := PEDIDO.MOSTRARPVENDASEMST;
    VSVALIDAVLMAXISENCAOSTPF    := PEDIDO.VALIDAVLMAXISENCAOSTPF;
    VNVLMAXISENCAOSTPF_FILIAL   := PEDIDO.VLMAXISENCAOSTPF;
    VNCODST                     := PEDIDO.CODST;
    VNCODICM                    := PEDIDO.CODICM;
    VNPERACRESCIMOFUNCEP        := PEDIDO.PERACRESCIMOFUNCEP;
    VNPERDIFEREIMENTOICMS       := PEDIDO.PERDIFEREIMENTOICMS;
    VNPERBASEREDNRPA            := PEDIDO.PERBASEREDNRPA;
    VSISENCAOSUFRAMA            := PEDIDO.ISENCAOSUFRAMA;
    VSSOMARVALORDIFBCICMS       := PEDIDO.SOMARVALORDIFBCICMS;
	
	/* G_GERARLOG = 'N' -> Desabilita o log da PCLOGIMPOSTOS */
    G_GERARLOG := 'N';
	vsVALIDARAIZCNPJTRANSFVIRT  := ferramentas.F_BUSCARPARAMETRO_ALFA('VALIDARAIZCNPJTRANSFVIRT','99','N');
	
    /* INICIO DEFINIÇÃO DA BASE DE ICMS */

    IF (PEDIDO.CONDVENDA = 10) AND
       (PEDIDO.CON_USARTRIBUTACAOTRANSFTV10 = 'S')
    THEN
      VSUSAALIQUOTATRANSFTV10 := 'S';
    ELSE
      VSUSAALIQUOTATRANSFTV10 := 'N';
    END IF;

    VRLOG.DESCRICAO := 'Pedido Cond. Venda = ' || pedido.condvenda || '; CON_USARTRIBUTACAOTRANSFTV10 = ' ||
                       pedido.CON_USARTRIBUTACAOTRANSFTV10 || '; VSUSAALIQUOTATRANSFTV10 = ' || VSUSAALIQUOTATRANSFTV10;

    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    -- VERIFICANDO SE O CLIENTE É PF (PESSOA FÍSICA) OU (PESSOA JURÍDICA)
    IF (PEDIDO.CODCLINF <> 0) AND (PEDIDO.CODCLINF <> PEDIDO.CODCLI)
    THEN
      VRLOG.DESCRICAO := 'Cliente ' || PEDIDO.CODCLINF || ' definido como ' || FERRAMENTAS.VERIFICAR_FJ(PEDIDO.CODCLINF);
      VBPESSOAFISICA := (FERRAMENTAS.VERIFICAR_FJ(PEDIDO.CODCLINF) =
                        'PESSOA FISICA');
    ELSE
      VRLOG.DESCRICAO := 'Cliente ' || PEDIDO.CODCLI || ' definido como ' || FERRAMENTAS.VERIFICAR_FJ(PEDIDO.CODCLI);
      VBPESSOAFISICA := (FERRAMENTAS.VERIFICAR_FJ(PEDIDO.CODCLI) =
                        'PESSOA FISICA');
    END IF;

    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    VRLOG.DESCRICAO := 'CODICMPF = ' || PEDIDO.CODICMPF || '; ' || '; SUFRAMA_CLIENT = ' || PEDIDO.SUFRAMA_CLIENT;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF (PEDIDO.CODICMPF IS NOT NULL) AND (VBPESSOAFISICA) AND
      --lucas.lima | 2460.068410.2014 | Comentada a regra referente ao
      --condvenda = 7 pois, segundo a análise, não fazia sentido.
      --Regra discutida com Fernandes e Jussana.
      --(CAB.CONDVENDA <> 7) AND
       (PEDIDO.SUFRAMA_CLIENT IS NULL)
    THEN
      VNCODICM := PEDIDO.CODICMPF;
    END IF;
    --Fim Tarefa: 182346

    VRLOG.DESCRICAO := 'ALIQICMSTV9 = ' || PEDIDO.ALIQICMSTV9;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF (PEDIDO.CONDVENDA = 9)
    THEN
      VNCODICM := PEDIDO.ALIQICMSTV9;
    END IF;

    VRLOG.DESCRICAO := 'TIPOEMPRESA_CLIENT = ' || PEDIDO.TIPOEMPRESA_CLIENT || '; CODICMPRODRURAL = ' || PEDIDO.CODICMPRODRURAL;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF (PEDIDO.TIPOEMPRESA_CLIENT = 'PR') AND
       (PEDIDO.CODICMPRODRURAL IS NOT NULL)
    THEN
      VNCODICM := PEDIDO.CODICMPRODRURAL;
    END IF;

    VRLOG.DESCRICAO := 'CODICMSIMPLESNAC = ' || PEDIDO.CODICMSIMPLESNAC;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF (PEDIDO.TIPOEMPRESA_CLIENT = 'SN') AND
       (PEDIDO.CODICMSIMPLESNAC IS NOT NULL)
    THEN
      VNCODICM := PEDIDO.CODICMSIMPLESNAC;
    END IF;

    VRLOG.DESCRICAO := 'VSISENTOICMS_CLIENT = ' || VSISENTOICMS_CLIENT || '; CONTAORDEM = ' || PEDIDO.CONTAORDEM;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF (VSISENTOICMS_CLIENT <> 'S') AND (PEDIDO.CONDVENDA = 7) AND
       (PEDIDO.CONTAORDEM = 'N')
    THEN
      VSISENTOICMS_CLIENT := 'S';
    END IF;

    IF VSISENTOICMS_CLIENT = 'S'
    THEN
      VRLOG.DESCRICAO := 'Cliente definido como isento de ICMS. Zerando Alíquotas de ICMS';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNCODICM                := 0;
      VNPERCBASERED           := 0;
      VNPERCBASEREDCONSUMIDOR := 0;
      VNPERBASEREDNRPA        := 0;
    END IF;

    VRLOG.DESCRICAO := 'VSORGAOPUB_CLIENT = '|| VSORGAOPUB_CLIENT || '; VSZERARBASEICMSORGPUBSUFRAMA = ' || VSZERARBASEICMSORGPUBSUFRAMA;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF ((VSORGAOPUB_CLIENT = 'S') OR (PEDIDO.ORGAOPUBFEDERAL_CLIENT = 'S') OR
       (PEDIDO.SUFRAMA_CLIENT IS NOT NULL) OR (PEDIDO.TIPOEMPRESA_CLIENT = 'R'))
        AND VSISENCAOSUFRAMA NOT IN('I', 'N')
        AND (VSZERARBASEICMSORGPUBSUFRAMA = 'S')
    THEN
      IF (VSUSAISENCAOICMSVP = 'S')
      THEN
        VRLOG.DESCRICAO := 'Tributação Parametrizada para utilizar isenção de ICMS em Vendas à prazo. Zerando alíquotas de ICMS';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        VNCODICM                := 0;
        VNPERCBASERED           := 0;
        VNPERCBASEREDCONSUMIDOR := 0;
        VNPERBASEREDNRPA        := 0;
      ELSE
        IF (PEDIDO.TIPOVENDA = 'VV')
        THEN
          VRLOG.DESCRICAO := 'Venda à vista. Zerando alíquotas de ICMS.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          VNCODICM                := 0;
          VNPERCBASERED           := 0;
          VNPERCBASEREDCONSUMIDOR := 0;
          VNPERBASEREDNRPA        := 0;
        END IF;
      END IF;
    END IF;

    IF PEDIDO.VENDATRIANGULAR = 'S'
    THEN
      VRLOG.DESCRICAO := 'Venda Triangular. Zerando alíquotas de ICMS.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNCODICM                := 0;
      VNPERCBASERED           := 0;
      VNPERCBASEREDCONSUMIDOR := 0;
      VNPERBASEREDNRPA        := 0;
    END IF;
  IF (NVL(PEDIDO.ST, 0) > 0) OR (NVL(PEDIDO.VLDIFALIQUOTAS, 0) > 0) OR
       (NVL(PEDIDO.VLIPI, 0) > 0) OR  (NVL(PEDIDO.VLFECP, 0) > 0) THEN
      IF (VSCONSUMIDORFINAL_CLIENT = 'S') OR (VSAGREGARIPIBASEICMS_CLIENT = 'S')
      THEN
        VNSUBTOT_AUX := ROUND((ROUND((NVL(PEDIDO.PVENDA, 0) - NVL(PEDIDO.ST,0) - NVL(PEDIDO.VLIPI,0) - NVL(PEDIDO.VLFECP,0)) * PEDIDO.QT, 6)
                                + ROUND((NVL(PEDIDO.ST,     0)) * PEDIDO.QT, (CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))
                                + ROUND((NVL(PEDIDO.VLIPI,0)) * PEDIDO.QT, (CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))
                                + ROUND((NVL(PEDIDO.VLFECP,0)) * PEDIDO.QT, (CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END)) ) / PEDIDO.QT
                              - NVL(ROUND(PEDIDO.ST * PEDIDO.QT ,(CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))/PEDIDO.QT , 0)
                              - NVL(PEDIDO.VLDIFALIQUOTAS, 0)
                              - NVL(ROUND(PEDIDO.VLFECP * PEDIDO.QT ,(CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))/PEDIDO.QT , 0)
                            ,
                              6);
      ELSE
        VNSUBTOT_AUX := ROUND((ROUND((NVL(PEDIDO.PVENDA, 0) - NVL(PEDIDO.ST,0) - NVL(PEDIDO.VLIPI,0) - NVL(PEDIDO.VLFECP,0)) * PEDIDO.QT, 6)
                                + ROUND((NVL(PEDIDO.ST,0)) * PEDIDO.QT, (CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))
                                + ROUND((NVL(PEDIDO.VLIPI,0)) * PEDIDO.QT, (CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))
                                + ROUND((NVL(PEDIDO.VLFECP,0)) * PEDIDO.QT, (CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))) / PEDIDO.QT
                              - NVL(ROUND(PEDIDO.ST * PEDIDO.QT ,(CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))/PEDIDO.QT , 0)
                              - NVL(ROUND(PEDIDO.VLIPI * PEDIDO.QT ,(CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))/PEDIDO.QT , 0)
                              - NVL(PEDIDO.VLDIFALIQUOTAS, 0)
                              - NVL(ROUND(PEDIDO.VLFECP * PEDIDO.QT ,(CASE WHEN PEDIDO.QT < 1 THEN 6 ELSE NVL(PARAMFILIAL.ObterComoNumber('QTDCASASVLUNITARIONFE'),2) END))/PEDIDO.QT , 0)
                              ,
                              6) ;
      END IF;
    ELSE
      VNSUBTOT_AUX := PEDIDO.PVENDA;
    END IF;

    VRLOG.DESCRICAO := 'Definindo VNSUBTOT_AUX = ' || VNSUBTOT_AUX || '; ST = ' || pedido.st || '; VLDIFALIQUOTAS = ' || PEDIDO.VLDIFALIQUOTAS ||
                       '; VLIPI = ' || PEDIDO.VLIPI || '; PVENDA = ' || PEDIDO.PVENDA;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));


    VRLOG.DESCRICAO := 'USADESCONTOICMS = ' || PEDIDO.USADESCONTOICMS || '; VSDESCICMSREDUZBASEICMS = ' || VSDESCICMSREDUZBASEICMS ||
                       '; VSZERARBASEICMSORGPUBSUFRAMA ' || VSZERARBASEICMSORGPUBSUFRAMA;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF (NVL(PEDIDO.VLDESCICMISENCAO, 0) > 0) AND (VSDESCICMSREDUZBASEICMS = 'N')
    THEN
      VNSUBTOT_AUX := VNSUBTOT_AUX + NVL(PEDIDO.VLDESCICMISENCAO, 0);

      IF (VSZERARBASEICMSORGPUBSUFRAMA = 'S')
      THEN
        IF (VSUSAISENCAOICMSVP = 'S')
        THEN
          VRLOG.DESCRICAO := 'Tributação Parametrizada para utilizar isenção de ICMS em Vendas à prazo. Zerando alíquotas de ICMS';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          VNCODICM                := 0;
          VNPERCBASERED           := 0;
          VNPERCBASEREDCONSUMIDOR := 0;
          VNPERBASEREDNRPA        := 0;
        ELSE
          IF (PEDIDO.TIPOVENDA = 'VV')
          THEN
            VRLOG.DESCRICAO := 'Venda à vista. Zerando alíquotas de ICMS';
            GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
            VNCODICM                := 0;
            VNPERCBASERED           := 0;
            VNPERCBASEREDCONSUMIDOR := 0;
            VNPERBASEREDNRPA        := 0;
          END IF;
        END IF;
      END IF;
    END IF;


    /*IF /*((VSORGAOPUB_CLIENT = 'S') OR (VSORGAOPUBFEDERAL_CLIENT = 'S') OR
       (VSSUFRAMA_CLIENT IS NOT NULL)) AND
      -- FEFA
       (VSDESCICMSREDUZBASEICMS = 'S') AND
       NVL(PEDIDO.VLDESCICMISENCAO, 0) > 0 and (VSUSADESCONTOICMS = 'N')
    THEN
      VRLOG.DESCRICAO := 'Agregando VLDESCICMSISENCAO à base de Icms.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNSUBTOT_AUX := VNSUBTOT_AUX + NVL(PEDIDO.VLDESCICMISENCAO, 0);
    END IF;    */

    VRLOG.DESCRICAO := 'Param132.ENVIARVLDESCPISCOFINSXMLDANFENFE = ' ||
                        PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE',
                                                      PEDIDO.CODFILIAL);
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    --A base de ICMS deve ser cheia com o valor da redução de PIS e COFINS
    IF PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIARVLDESCPISCOFINSXMLDANFENFE',
                                     PEDIDO.CODFILIAL) = 'S'
    THEN
      VNSUBTOT_AUX := VNSUBTOT_AUX + PEDIDO.VLDESCREDUCAOPIS + PEDIDO.VLDESCREDUCAOCOFINS;
    END IF;

    VRLOG.DESCRICAO := 'VNVLPAUTAICMSINTERES = ' || VNVLPAUTAICMSINTEREST || '; VNSUBTOT_AUX = ' || VNSUBTOT_AUX ||
                       '; VSESTENT_CLIENT = ' || VSESTENT_CLIENT || '; VC2UF_FILIAL ' || VC2UF_FILIAL ||
                       'PERCBASEREDTRANSFSAID = '|| PEDIDO.PERCBASEREDTRANFSAID || '; VNPERCBASERED = ' || VNPERCBASERED ||
                       '; VNVLPAUTAICMSEST = ' || VNVLPAUTAICMSEST;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    /*VEN-2372 pauta intraestadual*/
    IF (VNVLPAUTAICMSEST > VNSUBTOT_AUX) AND (VNVLPAUTAICMSEST > 0) AND (VSESTENT_CLIENT = VC2UF_FILIAL) THEN
          VNSUBTOT_AUX := VNVLPAUTAICMSEST;
    END IF;

    IF (VNVLPAUTAICMSINTEREST > VNSUBTOT_AUX) AND (VNVLPAUTAICMSINTEREST > 0) AND (VSESTENT_CLIENT <> VC2UF_FILIAL) THEN
          VNSUBTOT_AUX := VNVLPAUTAICMSINTEREST;
    END IF;

    IF (PEDIDO.CONDVENDA = 10)
    THEN
      IF (FERRAMENTAS.F_COMPARARCNPJ(PEDIDO.CODCLI_FILIAL, PEDIDO.CODCLI)) OR
			((vsVALIDARAIZCNPJTRANSFVIRT = 'N') AND 
			(NOT FERRAMENTAS.F_COMPARARCNPJ(PEDIDO.CODCLI_FILIAL, PEDIDO.CODCLI)) AND
			(PEDIDO.TIPOVENDA = 'TR'))	  
      THEN
      --Tarefa: 191609 -> Verificar dados de tributação como transferencia na TV10 após todas as demais verificações
        IF (PEDIDO.CON_USARTRIBUTACAOTRANSFTV10 = 'S') THEN
          VRLOG.DESCRICAO := 'PEDIDO TV10, COM RADICAIS DE CNPJ IGUAIS E PARAMÂMETRO CON_USARTRIBUTACAOTRANSFTV10 = ''S''' || CHR(13) ||
                             'SERÁ UTILIZADA ALÍQUOTA DE TRANSFERÊNCIA('|| PEDIDO.CODICMTRANSF ||') E PERCENTUAL DE REDUÇÃO DE TRANSFERÊNCIA('|| PEDIDO.PERCBASEREDSTTRANSF ||')';

          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          VNPERCBASEREDST := PEDIDO.PERCBASEREDSTTRANSF;
          VNCODICM        := PEDIDO.CODICMTRANSF;
        END IF;

        IF (PEDIDO.CON_USARREDUCAOICMSABATRANSF = 'S')
        THEN
          VNPERCBASERED := PEDIDO.PERCBASEREDTRANFSAID;
        END IF;
      END IF;
    END IF;


    VRLOG.DESCRICAO := 'VNPERCBASEREDCONSUMIDOR = ' || VNPERCBASEREDCONSUMIDOR ||
                       ' ; CON_UTILIZAPERCBASEREDPF = ' || PEDIDO.CON_UTILIZAPERCBASEREDPF ||
                       ' ; UTILIZAPERCBASEREDPF_TRIB = ' || PEDIDO.UTILIZAPERCBASEREDPF_TRIB;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    -- CLIENTE CONSUMIDOR FINAL UTILIZA %BASE RED. P/ CONSUMIDOR FINAL
    IF (VSCONSUMIDORFINAL_CLIENT = 'S') AND
       (VNPERCBASEREDCONSUMIDOR IS NOT NULL)
    THEN
      IF (VBPESSOAFISICA) AND (PEDIDO.CON_UTILIZAPERCBASEREDPF = 'S') AND
         (PEDIDO.UTILIZAPERCBASEREDPF_TRIB = 'S')
      THEN
        VNPERCBASERED := VNPERCBASEREDCONSUMIDOR;

      ELSIF (NOT VBPESSOAFISICA)
      THEN
        VNPERCBASERED := VNPERCBASEREDCONSUMIDOR;

      ELSE
        VNPERCBASERED := 0;
      END IF;
    ELSE
      IF (VBPESSOAFISICA) AND
          NOT ((PEDIDO.CON_UTILIZAPERCBASEREDPF = 'S') AND
               (PEDIDO.UTILIZAPERCBASEREDPF_TRIB = 'S')) THEN
        VNPERCBASERED := 0;
      END IF;

    END IF;

    VRLOG.DESCRICAO := 'TIPOEMPRESA_CLIENT = ' || PEDIDO.TIPOEMPRESA_CLIENT ||
                       ' ; VNPERCBASEREDNRPA = ' || VNPERBASEREDNRPA ||
                       ' ; PERCBASEREDSIMPLESNAC = ' || PEDIDO.PERBASEREDSIMPLESNAC;

    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    -- APLICAR %REDUCAO NA BASE DE ICMS ESPECIFICO
    IF (PEDIDO.TIPOEMPRESA_CLIENT = 'NRPA') AND (PEDIDO.CONDVENDA <> 10)
    THEN
      VNPERCBASERED := NVL(VNPERBASEREDNRPA, 0);
    END IF;

    IF PEDIDO.TIPOEMPRESA_CLIENT = 'SN'
    THEN
      VNPERCBASERED := NVL(PEDIDO.PERBASEREDSIMPLESNAC, 0);
    END IF;

    --VEN-2858
    IF (PEDIDO.PERCREDICMS > 0) THEN
      VNPERCBASERED := PEDIDO.PERCREDICMS;
      VRLOG.DESCRICAO := 'Utilizou percentual de redução de base de ICMS da rotina 302. PERCBASERED=' || PEDIDO.PERCREDICMS;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;

    VRLOG.DESCRICAO := 'APLICAACRESPFJURIDICA = ' || PEDIDO.APLICAACRESPFJURIDICA || ' ; TIPOFJ = ' || PEDIDO.TIPOFJ ||
                       ' ; VSCONSUMIDORFINAL_CLIENT = ' || VSCONSUMIDORFINAL_CLIENT || ' ; VSCONTRIBUINTE_CLIENT =  ' || VSCONTRIBUINTE_CLIENT ||
                       ' ; UTILIZAIESIMPLIFICADA_CLIENT = '|| PEDIDO.UTILIZAIESIMPLIFICADA_CLIENT ||
                       ' ; CON_UTILIZAPERCBASEREDPF = ' || PEDIDO.CON_UTILIZAPERCBASEREDPF ||
                       ' ; UTILIZAPERCBASEREDPF_TRIB = '|| PEDIDO.UTILIZAPERCBASEREDPF_TRIB;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    -- CLIENTE PF QUE UTILIZA IE SIMPLIFICADA NAO APLICA %BASE RED
    IF (PEDIDO.UTILIZAIESIMPLIFICADA_CLIENT = 'S') AND (VBPESSOAFISICA)
    THEN
      VNPERCBASERED := 0;
    END IF;

    -- SE SISTEMA NAO APLICAR %BASE RED. P/ PF OU ISENTOS
    IF PEDIDO.CON_UTILIZAPERCBASEREDPF = 'N'
    THEN
      -- CASO SISTEMA ESTEJA PARAMETRIZADO PARA NAO APLICAR %BASE RED P/ PF OU ISENTOS
      IF VBPESSOAFISICA
      THEN
        VNPERCBASERED := 0;
      END IF;
    ELSE
      -- SE SISTEMA APLICAR BASE RED. P/ PES. FIS OU ISENTOS
      IF PEDIDO.UTILIZAPERCBASEREDPF_TRIB = 'N'
      THEN
        -- CASO SISTEMA ESTEJA PARAMETRIZADO PARA NAO APLICAR %BASE RED P/ PF OU ISENTOS
        IF VBPESSOAFISICA
        THEN
          VNPERCBASERED := 0;
        END IF;
      END IF;
    END IF;


    --VEN-2858'

    IF NVL(VNPERCBASERED, 0) = 0
    THEN
      VNPERCBASERED := 100;
    END IF;

    VRLOG.DESCRICAO := 'Definido percentual de redução de ' || VNPERCBASERED || ' % na base de ICMS';
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    ---------------------- DEFINIÇÃO DE REDUÇÃO DE BASE CONCLUÍDA -----------

    /*********************************************
    ** DEFININDO A BASEICMS;
    ** VARIÁVEL "vnvlbaseicms_aux"; CAMPO "BASEICMS"
    */

    VRLOG.DESCRICAO := 'REDUZBASEICMSDECRETOMARANHAO = ' || PEDIDO.REDUZBASEICMDECRETOMARANHAO ||
                       ' ; VLATEND ' || PEDIDO.VLATEND ||
                       ' ; VLRREDBCMA = ' || PARAMETROS.GETVALORALFA('VLRREDBCMA',
                                                                     PEDIDO.CODFILIAL);
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF  (PEDIDO.REDUZBASEICMDECRETOMARANHAO = 'N') OR (VSESTENT_CLIENT <> 'MA')
    THEN
      -- Aplicacao do %Base Reduzida Maranhão
      VNVLBASEICMS_AUX := ((VNSUBTOT_AUX * NVL(VNPERCBASERED, 0)) / 100);
    ELSE

      IF (NVL(PEDIDO.VLATEND, 0) >=
         TO_NUMBER(REPLACE(NVL(PARAMETROS.GETVALORALFA('VLRREDBCMA',
                                                       PEDIDO.CODFILIAL),
                                '0'),
                            ',',
                            '.'))) AND (PEDIDO.CODCLI NOT IN (1, 2, 3))
      THEN

        VNVLBASEICMS_AUX := ((VNSUBTOT_AUX * NVL(VNPERCBASERED, 0)) / 100);

      ELSE
        VNVLBASEICMS_AUX := VNSUBTOT_AUX;
      END IF;
    END IF;

    VRLOG.DESCRICAO := 'VSAPLICAREDICMSSEMIPIBA = ' || VSAPLICAREDICMSSEMIPIBA;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF (VSAPLICAREDICMSSEMIPIBA = 'S') AND (VSAGREGARIPIBASEICMS_CLIENT = 'S')
    THEN
      IF (VSCONSUMIDORFINAL_CLIENT = 'S')
      THEN
        VRLOG.DESCRICAO := 'Aplicando percentual de redução de base de Icms sem o valor do IPI.';
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
        VNVLBASEICMS_AUX := (((VNSUBTOT_AUX - PEDIDO.VLIPI) *
                            NVL(VNPERCBASERED, 0)) / 100);

        VNVLBASEICMS_AUX := VNVLBASEICMS_AUX + PEDIDO.VLIPI;
      ELSE
        VNVLBASEICMS_AUX := ((VNSUBTOT_AUX * NVL(VNPERCBASERED, 0)) / 100);

      END IF;

    END IF;

    VRLOG.DESCRICAO := 'VSCONTRIBUINTE_CLIENT = ' || VSCONTRIBUINTE_CLIENT ||
                       ' ; VNPERPAUTAICMS = ' || VNPERPAUTAICMS ||
                       ' ; VNPERCBASEREDADICIONALINTER = ' || VNPERCBASEREDADICIONALINTER;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF ((VSCONTRIBUINTE_CLIENT = 'S') OR (NOT VBPESSOAFISICA)) AND
       ((VNPERPAUTAICMS > 0) OR (VNPERCBASEREDADICIONALINTER > 0))
    THEN
      VNPUNIT_ULTENT  := 0;
      VNPRECOPAUTA    := 0;

      VRLOG.DESCRICAO := 'Obtendo última entrada efetuada.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      BEGIN
        SELECT MAX(PCNFENT.NUMTRANSENT)
          INTO VNNUMTRANSENT
          FROM PCMOV, PCNFENT
         WHERE PCMOV.CODPROD = PEDIDO.CODPROD
           AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
           AND PCNFENT.CODCONT = (SELECT CODCONTFOR
                                    FROM PCCONSUM)
           AND PCNFENT.TIPODESCARGA = '1'
           AND UPPER(TRIM(NVL(PCMOV.CODOPER, ' '))) = 'E'
           AND NVL(PCNFENT.OBS, ' ') <> 'NF CANCELADA';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          VNNUMTRANSENT := 0;
      END;

      IF VNNUMTRANSENT > 0
      THEN
        VRLOG.DESCRICAO := 'Obtendo valor da última entrada. NUMTRANSENT = ' || VNNUMTRANSENT;
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        BEGIN
          SELECT MAX(PCMOV.PUNIT)
            INTO VNPUNIT_ULTENT
            FROM PCMOV
           WHERE NUMTRANSENT = VNNUMTRANSENT
             AND CODPROD = PEDIDO.CODPROD;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VNNUMTRANSENT := 0;
        END;

        VRLOG.DESCRICAO := 'Valor da última entrada encontrado = ' || VNPUNIT_ULTENT;
        GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      END IF;

      IF VNPUNIT_ULTENT > 0
      THEN
        IF (VSESTENT_CLIENT <> VC2UF_FILIAL)
        THEN
          VRLOG.DESCRICAO := 'Definido utilização de %pauta interestadual; ESTCLI = ' || VSESTENT_CLIENT || ' ; UF_FILIAL = ' || VC2UF_FILIAL;
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

          VNPERPAUTAICMS := VNPERPAUTAICMSINTER;
        END IF;

        IF VNPERPAUTAICMS > 0
        THEN
          VNPERCBASERED := 100;
          -- Setando para 100 para indicar que não utilizado
          VNPRECOPAUTA := ROUND((VNPUNIT_ULTENT *
                                (1 + (VNPERPAUTAICMS / 100))),
                                FERRAMENTAS.PARAMETROS.GETVALORNUMNVL('CON_NUMCASASDECVENDA',
                                                                      '99',
                                                                      2));

          IF PEDIDO.PVENDA < VNPRECOPAUTA
          THEN
            VRLOG.DESCRICAO := 'Definindo base de ICMS o valor da última entrada aplicado ao %pauta.' || CHR(13) ||
                               'VNPRECOPAUTA = ' || VNPRECOPAUTA || ' ; PVENDA = ' || PEDIDO.PVENDA;
            GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

            VNVLBASEICMS_AUX := VNPRECOPAUTA;
            VNPERCBASERED    := 100;
          END IF;
        END IF; -- IF vnPerPautaICMS
      END IF;
    END IF; -- IF vscontribuiente_client

    VNSUBTOT_AUX := (PEDIDO.PVENDA - NVL(PEDIDO.ST, 0));

    VRLOG.DESCRICAO := 'VNSUBTOT_AUX = ' || VNSUBTOT_AUX;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));


    IF PEDIDO.ALIQICMS1 IS NOT NULL
    THEN
      VNPAUTA := PEDIDO.PAUTA;
    END IF;

    ---------------------- precisa ser refeito BASEICMS MG ---------------------
    VNIVA      := PEDIDO.IVA;
    VNIVAFONTE := PEDIDO.IVAFONTE;

    --tenta refazer a base de st se não tiver st calculado.
    --precisa verificar se é certo efetuar essa validação.
    VNBST_AUX := PEDIDO.BASEICST;
    IF NVL(PEDIDO.BASEICST, 0) <= 0
    THEN
      VRLOG.DESCRICAO := 'Definindo Base de ST para o Produto. '        || chr(13) ||
                         'PERCBASEREDST = '   || PEDIDO.PERCBASEREDST   || chr(13) ||
                         'BASEICST = '        || PEDIDO.BASEICST        || chr(13) ||
                         'VENDATRIANGULAR = ' || PEDIDO.VENDATRIANGULAR || chr(13) ||
                         'STCLIENTEGNRE = '   || PEDIDO.STCLIENTEGNRE   || chr(13) ||
                         'ALIQICMS1 = '       || PEDIDO.ALIQICMS1       || chr(13) ||
                         'ALIQICMS2 = '       || PEDIDO.ALIQICMS2       || chr(13) ||
                         'VLATEND = '         || PEDIDO.VLATEND         || chr(13) ||
                         'CODPROD = '         || PEDIDO.CODPROD         || chr(13) ||
                         'CODCLI = '          || PEDIDO.CODCLI;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      DEFINIR_BASEST(VNPERCBASEREDST,--PEDIDO.PERCBASEREDST,
                     PEDIDO.BASEICST,
                     PEDIDO.VENDATRIANGULAR,
                     PEDIDO.STCLIENTEGNRE,
                     PEDIDO.ALIQICMS1,
                     PEDIDO.ALIQICMS2,
                     PEDIDO.VLATEND,
                     PEDIDO.CODPROD,
                     PEDIDO.CODCLI);
    END IF;

    VRLOG.DESCRICAO := 'Base de ST definida = ' || VNBST_AUX;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    --Base de ICMS para MG
    VBCALCULABASEMG := ((PEDIDO.UTILIZAMOTORCALCULO = 'S') AND (PEDIDO.CALCBASEICMSMEDIAENT = 'S')) OR
                       ((PEDIDO.UTILIZAMOTORCALCULO = 'N') AND ((PEDIDO.CALCBASEICMSMEDIAENT = 'S') OR (VSUSAVLULTENTMEDIOBASEST = 'S')));

    IF VBCALCULABASEMG THEN
      VRLOG.DESCRICAO := 'Buscando Valor da Última Entrada ICMS de MG. PCTRIBUT.USAVLULTENTMEDIOBASEST = ''S'' ' || chr(13) ||
                         'VNPAUTA = ' || VNPAUTA || ' ; CALCBASEICMSMEDIAENT = ' || PEDIDO.CALCBASEICMSMEDIAENT ;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      SELECT NVL(VLULTENTMES,0)
        INTO VNVLULTENTMES
        FROM PCTABPR
       WHERE NUMREGIAO = PEDIDO.NUMREGIAO
         AND CODPROD = PEDIDO.CODPROD;

      VRLOG.DESCRICAO := 'Valor de última entrada encontrado = ' || VNVLULTENTMES;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

  	  IF VNVLULTENTMES = 0 THEN

         SELECT NVL(PCEST.VALORULTENT,0)
            INTO  VNVLULTENTMES
            FROM PCEST
         WHERE CODPROD = PEDIDO.CODPROD
            AND CODFILIAL = PEDIDO.CODFILIALRETIRA;

	    END IF;

      IF (PEDIDO.COMPARARBASEICMSMEDULTENTMES = 'S') AND
         (VSCONSUMIDORFINAL_CLIENT = 'S')            THEN
 
        IF  NVL(PEDIDO.IVA, 0) = 0 THEN
          BEGIN
            SELECT 
              NVL(IVA, 0) IVA INTO PEDIDO.IVA
            FROM PCTRIBUT
            WHERE CODST = vncodst;
          EXCEPTION 
            WHEN OTHERS THEN VRLOG.DESCRICAO := '';
          END; 
        END IF;

        VVLR_IVA := ROUND(VNVLULTENTMES * (1 + (PEDIDO.IVA / 100)), 2);

        IF (VVLR_IVA) > VNSUBTOT_AUX THEN
          VNSUBTOT_AUX := (VVLR_IVA);
        END IF;  

        IF NVL(VNPERCBASERED, 0) > 0 THEN
           VNSUBTOT_AUX := ((VNSUBTOT_AUX * NVL(VNPERCBASERED, 0)) / 100);
        END IF;   

        VNVLBASEICMS_AUX := VNSUBTOT_AUX ;

        IF NVL(VNVLBASEICMS_AUX, 0) = 0 THEN
          VRLOG.DESCRICAO := 'Zerando base de Icms. Comparação valor médio de entradas como base de icms(ST MG) resultando em 0';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          VNCODICM := 0;          
        END IF;

      ELSE
        IF (NVL(VNPAUTA, 0) = 0) AND
           (FERRAMENTAS.VERIFICAR_ISENTOST(PEDIDO.CODCLI,
                                           PEDIDO.CODPROD,
                                           PEDIDO.CODST) = 'N')
        THEN
          /*IF (NVL(VNPERCBASEREDST, 0) = 0)
          THEN
            VNSUBTOT_AUX := ((VNBST_AUX * 100) / (100 + PEDIDO.IVA)) -
                            PEDIDO.VLIPI;
          ELSE
            VNSUBTOT_AUX := (((VNBST_AUX * 100) / (100 + PEDIDO.IVA)) /
                            (VNPERCBASEREDST / 100)) - PEDIDO.VLIPI;
          END IF;   */
          VNSUBTOT_AUX := VNVLULTENTMES;

        ELSIF (NVL(VNPAUTA, 0) > 0)
        THEN
          --vnsubtot_aux := vnpauta;

          VNSUBTOT_AUX := VNVLULTENTMES;
        ELSIF (FERRAMENTAS.VERIFICAR_ISENTOST(PEDIDO.CODCLI,
                                              PEDIDO.CODPROD,
                                              VNCODST) = 'S')
        THEN
          VNSUBTOT_AUX := VNVLULTENTMES;

           if  nvl(PEDIDO.IVA,0) = 0 then
              SELECT NVL(IVA, 0) IVA
                INTO PEDIDO.IVA
                FROM PCTRIBUT
               WHERE CODST = vncodst;
           END IF;

        END IF;

        VNVLBASEICMS_AUX := ((VNSUBTOT_AUX * NVL(VNPERCBASERED, 0)) / 100);

        IF NVL(VNVLBASEICMS_AUX, 0) = 0 AND
          NVL(PEDIDO.CALCBASEICMSMEDIAENT, 'N') = 'N'
        THEN
          VRLOG.DESCRICAO := 'Zerando base de Icms. Tributação definida para não utilizar valor da última entrada como base de ICMS ST.';
          GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
          VNCODICM := 0;
        END IF;
      END IF;
    END IF;

    /*IF (NVL(VNBST_AUX, 0) = 0) AND (PEDIDO.CALCBASEICMSMEDIAENT = 'S')
    THEN
      VNVLBASEICMS_AUX := ((VNVLULTENTMES * NVL(VNPERCBASERED, 0)) / 100);
      VRLOG.DESCRICAO := 'Aplicando percentual de redução de icms ao valor de última entrada.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;  */
    --Fim Base ICMS MG

    -----------------------------------------------------------
    --Autor: Rafael Soares
    --Solicitação: HIS.02754.2015
    --Data: 13/10/2015
    --Descrição: Utilizar valor da ultima entrada como base de ICMS conforme parametrizado
    --na rotina 514.
    VRLOG.DESCRICAO := 'USAVALORULTENTBASEICMS = ' || PEDIDO.USAVALORULTENTBASEICMS ||
                       ' ; USAVALORULTENTBASEICMSFONTE = ' || PEDIDO.USAVALORULTENTBASEICMSFONTE ||
                       ' ; TIPO_ST = ' || FERRAMENTAS.VERIFICAR_TIPOST(PEDIDO.CODCLI, VNCODST);
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    IF ((PEDIDO.USAVALORULTENTBASEICMS = 'S') AND
       (FERRAMENTAS.VERIFICAR_TIPOST(PEDIDO.CODCLI, VNCODST) = 'ST NORMAL')) OR
       ((PEDIDO.USAVALORULTENTBASEICMSFONTE = 'S') AND
       (FERRAMENTAS.VERIFICAR_TIPOST(PEDIDO.CODCLI, VNCODST) = 'ST FONTE'))
    THEN
      SELECT NVL(DECODE(PCEST.VALORULTENT ,
                        0,
                        PCEST.CUSTONFSEMST,
                        PCEST.VALORULTENT),
                 PCEST.CUSTONFSEMST)
        INTO VNVALORULTENTBASEICMS
        FROM PCEST
       WHERE CODPROD = PEDIDO.CODPROD
         AND CODFILIAL = PEDIDO.CODFILIALRETIRA;

      VNSUBTOT_AUX := VNVALORULTENTBASEICMS;

      VNVLBASEICMS_AUX := ((VNSUBTOT_AUX * NVL(VNPERCBASERED, 0)) / 100);
    END IF;
    -----------------------------------------------------------

    /*** HIS.00670.2017 ***/
    IF (PEDIDO.APLICAMVABASEICMS = 'S') AND
       (VSCONSUMIDORFINAL_CLIENT = 'S')
    THEN
      VRLOG.DESCRICAO := 'Aplicando Valor do IVA à base de ICMS. ';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX := VNVLBASEICMS_AUX * (1 + (PEDIDO.IVA / 100));
    END IF;
    /*** HIS.00670.2017 ***/

    -- Quanto a aliquota de ICMS for igual a 0 zerar a base de calculo (30/04/2004)
    IF VNCODICM = 0
    THEN
      VRLOG.DESCRICAO := 'Percentual de ICMS não definido. Zerando valor da base de ICMS.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX := 0;
    END IF;

    --Autor: Guilherme Freitas
    --Solicitação: HIS.02571.2015
    --Data: 28/09/2015
    --Descrição: Critério 1.2.4.1. ICMS: Deve validar o parâmetro da 514 'Não calcular ICMS de
    --item bonificado em mercadoria no pedido de venda (TV1)'. Caso o parametro estiver marcado,
    --deve zerar a base, aliquota e valor do ICMS e gravar o cst de acordo ao parametro 514
    --'Situação tributária de item bonificado em mercadoria no pedido de venda (TV1)'.
    IF (((PEDIDO.BNFNAOCALCULAICMS = 'S') AND (PEDIDO.CONDVENDA = 1)) OR
        ((PEDIDO.BNFNAOCALCULAICMSTV14 = 'S') AND (PEDIDO.CONDVENDA = 14))) AND
        (PEDIDO.BONIFIC = 'S')
    THEN
      VRLOG.DESCRICAO := 'Item de TV' || PEDIDO.CONDVENDA || ' bonificado. Tributação isenta ICMS de item bonificando. Zerando valores de ICMS.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNSUBTOT_AUX     := 0;
      VNVLBASEICMS_AUX := 0;
      VNCODICM         := 0;
    END IF;

    -- Tarefa 53334
    IF (VSSUFRAMA_CLIENT IS NOT NULL) AND (PEDIDO.VLDESCSUFRAMA > 0) AND
       (VSIMPORTADO_PRODUT = 'N') -- Tarefa 92242
    THEN
      VRLOG.DESCRICAO := 'Cliente Suframado e produto não importado. Zerando valores de ICMS';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNCODICM         := 0;
      VNVLBASEICMS_AUX := 0;
    END IF;

    /*--Tarefa 134228
    verificar se a regra ainda é valida
    IF PEDIDO.BONIFIC = 'S'
    THEN
      VNVLBASEICMS_AUX := 0;
      VNCODICM         := 0;
    END IF;*/

    --Tarefa 144179
    IF (PEDIDO.CONDVENDA = 5) AND (VSISENTAICMSBONIFIC = 'S') AND
       (VSESTENT_CLIENT = VC2UF_FILIAL)
    THEN
      VRLOG.DESCRICAO := 'Pedido TV5, tributaçã parametrizada para isentar ICMS de bonificações e venda estadual. Zerando valores de ICMS';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX := 0;
      VNCODICM         := 0;
    END IF;
	
    IF (PEDIDO.CONDVENDA = 5) AND (VSISENTAICMSBONIFICINT = 'S') AND
       (VSESTENT_CLIENT <> VC2UF_FILIAL)
    THEN
      VRLOG.DESCRICAO := 'Pedido TV5, tributaçã parametrizada para isentar ICMS de bonificações e venda intestadual. Zerando valores de ICMS';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX := 0;
      VNCODICM         := 0;
    END IF;
    --Tarefa HIS.02803.2016
    IF (PEDIDO.CONDVENDA = 7) AND
       (PARAMFILIAL.OBTERCOMOVARCHAR2('NAOCALCULARICMSVENDATV7',
                                      PEDIDO.CODFILIAL) = 'S')
    THEN
      VRLOG.DESCRICAO := 'Pedido TV7 e sistema parametrizado para não calcular ICMS na venda TV7.(NAOCALCULARICMSVENDATV7). Zerando valores de ICMS.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX := 0;
      VNCODICM         := 0;
    END IF;

    -- Tarefa 77214
    IF ((VSSITTRIBUT = '60') OR (VSSITTRIBUT = '060')) AND
       (VSCALCULARICMSSITTRIBUT060 <> 'S')
    THEN
      VRLOG.DESCRICAO := 'Sit. Tribut. 060/60. Tributação não calcula ICMS para esses Sit. Tribut. Zerando valores de ICMS';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX2 := VNVLBASEICMS_AUX;
      VNCODICM          := 0;
      VNVLBASEICMS_AUX  := 0;
    END IF;
	
    IF ((VSSITTRIBUT = '41') OR (VSSITTRIBUT = '041')) AND
       (VSISENTAICMSSITTRIBUT041 = 'S')
    THEN
      VRLOG.DESCRICAO := 'Sit. Tribut. 041/41. Tributação não calcula ICMS para esses Sit. Tribut. Zerando valores de ICMS';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNVLBASEICMS_AUX2 := VNVLBASEICMS_AUX;
      VNCODICM          := 0;
      VNVLBASEICMS_AUX  := 0;
    END IF;

    -- Tarefa 168654
    IF (PEDIDO.VENDAEXPORTACAO = 'S')
    THEN
      VRLOG.DESCRICAO := 'Venda exportação. Zerando valores de ICMS.';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
      VNCODICM         := 0;
      VNVLBASEICMS_AUX := 0;
    END IF;

    --Tarefa 133021

    IF ((PEDIDO.IEENT IS NULL) OR (PEDIDO.IEENT = 'ISENTO') OR
       (PEDIDO.IEENT = 'ISENTA'))
    THEN
      VSCLIENTE_EH_ISENTO := 'S';
    ELSE
      VSCLIENTE_EH_ISENTO := 'N';
    END IF;

    --VEN-5126
    /*  Venda interestadual para cliente não contribuinte e consumidor final
      que tem incidência de ICMS Partilha
      não haverá o calculo de Funcep na origem da operação.*/
    IF((VSCONSUMIDORFINAL_CLIENT = 'S')AND
      (VSESTENT_CLIENT <> VC2UF_FILIAL)AND
      (VSCONTRIBUINTE_CLIENT = 'N')AND
      (PEDIDO.Vlicmspartrem > 0))
    THEN
      VNPERACRESCIMOFUNCEP := 0;
    END IF;

    /*IF ((PEDIDO.PARTICIPAFUNCEP <> 'S') OR
        ((NVL(VSCLIENTE_EH_ISENTO, 'N') = 'S') AND
         (PEDIDO.CALCULARFUNCEPISENTOIE <> 'S')))
    THEN
        VNPERACRESCIMOFUNCEP := 0;
    END IF;*/
    IF CLIENTE_CALCULA_FUNCEP(PEDIDO.CODCLI, PEDIDO.CODST, vMsgAux) = 'N' THEN
      VNPERACRESCIMOFUNCEP := 0;
    END IF;
	  
  if TRIM(vMsgAux) <> '' THEN
    RAISE_APPLICATION_ERROR(-20000, vMsgAux);
  END IF;

    -- Tarefa 87935
    IF (VNCODICM > 0) AND (PEDIDO.UTILIZAMOTORCALCULO = 'N')
    THEN

      IF (VNPERACRESCIMOFUNCEP > 0) THEN
        DADOS_SAIDA.BASE_FECP_ICMS := GREATEST(VNVLBASEICMS_AUX, 0);
      END IF;

      VRLOG.DESCRICAO := 'Cliente isento de IE. PEDIDO.PARTICIPAFUNCEP = ' || PEDIDO.PARTICIPAFUNCEP ||
                         '; CALCULARFUNCEPISENTOIE = ' || PEDIDO.CALCULARFUNCEPISENTOIE ||'';
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      VNCODICM := VNCODICM + NVL(VNPERACRESCIMOFUNCEP, 0);

      VRLOG.DESCRICAO := 'Agregando percentual de acréscimo do FUNCEP ao ICMS. VNPERACRESCIMOFUNCEP = ' || VNPERACRESCIMOFUNCEP;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));
    END IF;

    IF (PEDIDO.UTILIZAMOTORCALCULO = 'S') AND
       (PEDIDO.FORMULAFUNCEPICMS IS NOT NULL)
    THEN
      VRLOG.DESCRICAO := 'Figura tributária utiliza motor de cálculo. Calculando FUNCEP ICMS com motor. Formula: ' || PEDIDO.FORMULAFUNCEPICMS;
      GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      variavel.Nome  := '[PAUTAICMS]';
      variavel.Valor := 0;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERACRESCIMOFUNCEP]';
      variavel.Valor := VNPERACRESCIMOFUNCEP;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PTABELASEMIMPOSTO1]';
      variavel.Valor := VNVLBASEICMS_AUX/(VNPERCBASERED/100);--passar sempre valor desconsiderando a redução
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[VLFRETE]';
      variavel.Valor := PEDIDO.VLFRETE;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[VLOUTRASDESP]';
      variavel.Valor := PEDIDO.VLOUTRASDESP;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[CONSUMIDORFINAL]';
      variavel.Valor := VSCONSUMIDORFINAL_CLIENT;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[UFCLIENTE]';
      variavel.Valor := VSESTENT_CLIENT;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[UFFILIAL]';
      variavel.Valor := VC2UF_FILIAL;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[CONTRIBUINTE]';
      variavel.Valor := VSCONTRIBUINTE_CLIENT;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[VLICMSPARTREM]';
      variavel.Valor := PEDIDO.Vlicmspartrem;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

      variavel.Nome  := '[PERCBASERED]';
      variavel.Valor := CASE
                          WHEN VNPERCBASERED = 0 THEN
                            100
                          ELSE
                            VNPERCBASERED
                          END;
      FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

        if (VNPERACRESCIMOFUNCEP > 0 ) then
          resultado                    := FORMULA.CALCULAR(PEDIDO.FORMULAFUNCEPICMS, vtVariaveis);
          DADOS_SAIDA.VALOR_FECP_ICMS  := formula.BUSCAVALOR(resultado, 'FUNCEP');
          DADOS_SAIDA.BASE_FECP_ICMS   := formula.BUSCAVALOR(resultado, 'BASE_FECP');
          DADOS_SAIDA.PERC_FECP_ICMS   := CASE 
                                            WHEN COALESCE(DADOS_SAIDA.BASE_FECP_ICMS, 0) = 0 THEN 
                                              0
                                            ELSE 
                                              VNPERACRESCIMOFUNCEP
                                          END;
        else
          DADOS_SAIDA.PERC_FECP_ICMS := 0;
          DADOS_SAIDA.BASE_FECP_ICMS  := 0;
          DADOS_SAIDA.VALOR_FECP_ICMS := 0;
        end if;


    END IF;

    /* DIFERIMENTO */
    IF (PEDIDO.CONDVENDA = 10)  THEN
      VNPERDIFEREIMENTOICMS     := PEDIDO.PERDIFERIMENTOCMSTRANSF;
    END IF;

    IF (PEDIDO.CONDVENDA = 9) AND (PEDIDO.PERDIFEREIMENTOICMSTV9 > 0) THEN
      VNPERDIFEREIMENTOICMS     := PEDIDO.PERDIFEREIMENTOICMSTV9;
    END IF;

    IF (PEDIDO.IEENT NOT IN ('ISENTO', 'ISENTA')
       AND PEDIDO.TIPOEMPRESA_CLIENT = 'PR'
       AND PEDIDO.CONTRIBUINTE_CLIENT = 'S'
       AND PEDIDO.PRODRURALCALCDIFER = 'S')  THEN

       VNPERDIFEREIMENTOICMS     := PEDIDO.PERDIFEREIMENTOICMS; --HIS.02480.2018
    END IF;

    IF VSCONSUMIDORFINAL_CLIENT = 'S' OR
    (PEDIDO.TIPOEMPRESA_CLIENT = 'PR' AND PEDIDO.PRODRURALCALCDIFER = 'N')  THEN --HIS.02480.2018
      VNPERDIFEREIMENTOICMS := 0;
    END IF;

    --HIS.02047.2016
    IF (PEDIDO.TIPOEMPRESA_CLIENT = 'MEI') AND (PEDIDO.MEINAOCALCDIF = 'S') THEN
      VNPERDIFEREIMENTOICMS := 0;
    END IF;

     --HIS.02457.2018
    IF (PEDIDO.TIPOEMPRESA_CLIENT = 'SN') AND (PEDIDO.SNNAOCALCDIF = 'S') THEN
        VNPERDIFEREIMENTOICMS := 0;
      END IF;
    /* DIFERIMENTO */

    VRLOG.DESCRICAO := 'Percentual de diferimento definido = ' || VNPERDIFEREIMENTOICMS;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

/* Retirar melhoria Somar Diferimento base ICMS implementado na issue DDFAT-350 para uma melhorar análise e validação da legislação.
    VRLOG.DESCRICAO := 'Somar Valor Diferido à BC ICMS definido = ' || VSSOMARVALORDIFBCICMS;
    GRAVARLOG(VRLOG, (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

    IF (VSSOMARVALORDIFBCICMS = 'S') AND (VNPERDIFEREIMENTOICMS <> 0) THEN
      VNVLBASEICMS_AUX := VNVLBASEICMS_AUX / ( ( 100 - VNPERDIFEREIMENTOICMS ) /100);
    END IF;

*/
    --DDFAT-5104
    IF (VSSOMARVALORDIFBCICMS = 'S') AND (VNPERDIFEREIMENTOICMS <> 0) THEN
      VNVLBASEICMS_AUX := VNVLBASEICMS_AUX / (( 1 - ((VNCODICM + (CASE WHEN PEDIDO.UTILIZAMOTORCALCULO = 'N' THEN 0 ELSE VNPERACRESCIMOFUNCEP END)) /100)));
      DADOS_SAIDA.BASE_FECP_ICMS := GREATEST(VNVLBASEICMS_AUX, 0);
      DADOS_SAIDA.VALOR_FECP_ICMS := CASE
                                         WHEN (VNPERDIFEREIMENTOICMS = 100) THEN
                                           0
                                         ELSE DADOS_SAIDA.VALOR_FECP_ICMS END;

      DADOS_SAIDA.VLFCPDIF := DADOS_SAIDA.BASE_FECP_ICMS * ((CASE WHEN PEDIDO.UTILIZAMOTORCALCULO = 'N' THEN 0 ELSE VNPERACRESCIMOFUNCEP END)/100) * (VNPERDIFEREIMENTOICMS/100);

    END IF;

/*    
    IF (VSSOMARVALORDIFBCICMS = 'S') AND (VNPERDIFEREIMENTOICMS <> 0)  THEN
      VNVLBASEICMS_AUX := (VNVLBASEICMS_AUX / ( ( 1 - (VNCODICM/100) ))) * (VNPERDIFEREIMENTOICMS/100);            
    END IF;
*/

    VNVLBASEICMS_AUX := GREATEST(VNVLBASEICMS_AUX, 0);
    IF VNVLBASEICMS_AUX = 0 THEN
      VNCODICM := 0;
    END IF;

    /* FINAL DEFINIÇÃO DA BASE DE ICMS */
    DADOS_SAIDA.VALOR_BASE          := VNVLBASEICMS_AUX;
    DADOS_SAIDA.PERC_ICMS           := VNCODICM;
    
    DADOS_SAIDA.VALOR_ICMS          := CASE
                                         WHEN (VNPERDIFEREIMENTOICMS = 100) THEN
                                           0
                                         ELSE
                                           ((DADOS_SAIDA.VALOR_BASE * (DADOS_SAIDA.PERC_ICMS / 100)) -
                                           ((DADOS_SAIDA.VALOR_BASE * (DADOS_SAIDA.PERC_ICMS / 100)) *
                                            (VNPERDIFEREIMENTOICMS / 100)))
                                       END;
                                       --DADOS_SAIDA.VALOR_BASE *
                                       --(DADOS_SAIDA.PERC_ICMS / 100) * (VNPERDIFEREIMENTOICMS/100);

    DADOS_SAIDA.PERC_BASE_RED       := VNPERCBASERED;
    DADOS_SAIDA.VALOR_ICMS_DIFERIDO :=  DADOS_SAIDA.VALOR_BASE *
                                       (DADOS_SAIDA.PERC_ICMS / 100) * (VNPERDIFEREIMENTOICMS/100);

                                       
    DADOS_SAIDA.PERC_ICMS_DIFERIDO  := VNPERDIFEREIMENTOICMS;

    VRLOG.DESCRICAO := 'Retornando Base de ICMS. Produto: ' ||
                       PEDIDO.CODPROD || '; Num. Seq.: ' || PEDIDO.NUMSEQ ||
                       '; Valor Base: ' || DADOS_SAIDA.VALOR_BASE ||
                       '; Perc. ICMS: ' || DADOS_SAIDA.PERC_ICMS;
    GRAVARLOG(VRLOG,
              (CASE WHEN VRLOG.DESCRICAO LIKE '%ORA-%' THEN
               DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
               TO_CHAR($$PLSQL_LINE) END));
    RETURN DADOS_SAIDA;
  END;

  FUNCTION RETORNAR_ROWTIPEPCMOV(P_ROWID  IN VARCHAR2) RETURN PCMOV%ROWTYPE
  IS
   ROWPCMOV PCMOV%ROWTYPE;
  BEGIN
           SELECT PCMOV.* INTO ROWPCMOV
            FROM PCMOV
           WHERE PCMOV.ROWID = P_ROWID;

           return  ROWPCMOV ;

  END RETORNAR_ROWTIPEPCMOV;

  FUNCTION RETORNAR_DADOS_FABRICANTE(pCodprod          IN  number,
                                     pCodFilial        IN  VARCHAR2,
                                     rFabricante       OUT VARCHAR2,
                                     rCgcFabricante    OUT VARCHAR2,
                                     rRelevante        OUT varchar2,
                                     rMsg              OUT VARCHAR2) RETURN BOOLEAN
  IS
  BEGIN
    rMsg := '';
    IF nvl(pCodProd, 0) <= 0 THEN
      rMsg := rMsg || ' Código do Produto não informado' || chr(13);
    end IF;


    IF pCodFilial = '' THEN
      rMsg := rMsg || ' Código da Filial não informada' || chr(13);
    END IF;

    IF RMSG IS NOT NULL THEN
      RETURN FALSE;
    END IF;

    BEGIN
      SELECT P.CNPJFABRICANTE, P.FABRICANTE, NVL(P.INDESCALARELEVANTE, 'S')
        INTO RCGCFABRICANTE, RFABRICANTE, RRELEVANTE
        FROM PCPRODFILIAL P
       WHERE P.CODPROD = PCODPROD
         AND P.CODFILIAL = PCODFILIAL;

      RETURN TRUE;
    EXCEPTION
       WHEN no_data_found THEN
         rMsg := 'Dados do produto não encontrado';
         RETURN FALSE;
       WHEN OTHERS THEN
         rMsg := 'Erro ao buscar dados do produto. msg:' ||sqlcode || SQLERRM;
         RETURN FALSE;
    END;

    RETURN TRUE;
  END;

  PROCEDURE SET_GRAVARLOG(P_Valor in varchar2) is
  BEGIN
    G_GERARLOG := P_Valor;
  END SET_GRAVARLOG;
  
  FUNCTION GET_GRAVARLOG return varchar2 is
  BEGIN
    Return G_GERARLOG;
  END GET_GRAVARLOG;  
  

  FUNCTION SONUMEROS(P_STRING in varchar) return varchar is
  begin
    return replace(trim(TRANSLATE(P_STRING,
                                  NVL(TRANSLATE(P_STRING, '1234567890', ' '),'X'),
                                  ' ')),
                   ' ',
                   '');
  exception
    when others then
      return null;
  END;
  
  FUNCTION CLIENTE_CALCULA_FUNCEP(P_CODIGOCLIENTE          IN NUMBER
                                 ,P_CODIGOFIGURATRIBUTARIA IN NUMBER
                                 ,P_MENSAGEM_RETORNO          OUT VARCHAR2)
    RETURN VARCHAR2 IS
    V_CLIENTE_PARTICIPA_FUNCEP   VARCHAR2(1);
    V_CLIENTE_INSCRICAO_ESTADUAL PCCLIENT.IEENT%TYPE;
    V_CLIENTE_ISENTO             VARCHAR2(1);
    V_CALCULA_FUNCEP_ISENTO_IE   VARCHAR2(1);
    V_MSG_RETORNO                VARCHAR2(1000);
    V_RETORNO                    VARCHAR2(10) := 'N';
    V_SUCESSO_PESQUISIA          BOOLEAN := TRUE;
  BEGIN
    BEGIN
      SELECT COALESCE(PCCLIENT.PARTICIPAFUNCEP, 'N'), PCCLIENT.IEENT
        INTO V_CLIENTE_PARTICIPA_FUNCEP, V_CLIENTE_INSCRICAO_ESTADUAL
        FROM PCCLIENT
       WHERE CODCLI = P_CODIGOCLIENTE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_SUCESSO_PESQUISIA := FALSE;
        V_MSG_RETORNO       := V_MSG_RETORNO || CHR(13) ||
                               'Cliente com código ' || P_CODIGOCLIENTE ||
                               ' não localizado.';
      WHEN OTHERS THEN
        V_SUCESSO_PESQUISIA := FALSE;
        V_MSG_RETORNO       := V_MSG_RETORNO || CHR(13) ||
                               'Erro ao buscar cliente com código ' ||
                               P_CODIGOCLIENTE || '. Msg:' || SQLCODE ||
                               ' - ' || SQLERRM;
    END;
  
    BEGIN
      SELECT COALESCE(PCTRIBUT.CALCULARFUNCEPISENTOIE, 'N')
        INTO V_CALCULA_FUNCEP_ISENTO_IE
        FROM PCTRIBUT
       WHERE PCTRIBUT.CODST = P_CODIGOFIGURATRIBUTARIA;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_SUCESSO_PESQUISIA := FALSE;
        V_MSG_RETORNO       := V_MSG_RETORNO || CHR(13) ||
                               'Figura Tributária com código ' ||
                               P_CODIGOCLIENTE || ' não localizada.';
      WHEN OTHERS THEN
        V_SUCESSO_PESQUISIA := FALSE;
        V_MSG_RETORNO       := V_MSG_RETORNO || CHR(13) ||
                               'Erro ao buscar figura com código ' ||
                               P_CODIGOCLIENTE || '. Msg:' || SQLCODE ||
                               ' - ' || SQLERRM;
    END;
  
    IF ((V_CLIENTE_INSCRICAO_ESTADUAL IS NULL) OR
       (V_CLIENTE_INSCRICAO_ESTADUAL = 'ISENTO') OR
       (V_CLIENTE_INSCRICAO_ESTADUAL = 'ISENTA'))
    THEN
      V_CLIENTE_ISENTO := 'S';
    ELSE
      V_CLIENTE_ISENTO := 'N';
    END IF;
  
    IF V_SUCESSO_PESQUISIA = TRUE
    THEN
      IF  ((V_CLIENTE_PARTICIPA_FUNCEP  = 'S') AND 
           ((NVL(V_CLIENTE_ISENTO, 'N') = 'N') OR
		    ((NVL(V_CLIENTE_ISENTO, 'N') = 'S') AND (V_CALCULA_FUNCEP_ISENTO_IE  = 'S'))))
      THEN
        V_RETORNO := 'S';
      END IF;
    ELSE
      V_RETORNO          := 'ERRO';
      P_MENSAGEM_RETORNO := V_MSG_RETORNO;
    END IF;
  
    RETURN V_RETORNO;
  END;
  
  FUNCTION RETORNAR_ROWTYPE(TABELA      IN VARCHAR2
                           ,CAMPO_CHAVE IN VARCHAR
                           ,VALOR_CHAVE IN VARCHAR) RETURN SYS_REFCURSOR AS
    MCURSOR SYS_REFCURSOR;
    VSQL    VARCHAR2(1000);
  BEGIN
    VSQL := 'SELECT * FROM ' || TABELA || ' WHERE ' || CAMPO_CHAVE || ' = ' ||
            VALOR_CHAVE;
  
    OPEN MCURSOR FOR VSQL;
  
    RETURN MCURSOR;
  END;

  PROCEDURE F_SLEEP(IN_TIME NUMBER) IS
    V_NOW DATE;
  BEGIN
    -- 1) GET THE DATE & TIME
    SELECT SYSDATE INTO V_NOW FROM DUAL;

    -- 2) LOOP UNTIL THE ORIGINAL TIMESTAMP PLUS THE AMOUNT OF SECONDS <= CURRENT DATE
    LOOP
      EXIT WHEN V_NOW +(IN_TIME * (1 / 86400)) <= SYSDATE;
    END LOOP;
  END F_SLEEP;

END;
