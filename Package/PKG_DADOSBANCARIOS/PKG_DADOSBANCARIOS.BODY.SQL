CREATE OR REPLACE PACKAGE BODY PKG_DADOSBANCARIOS IS
/*
08/09/2014 - Package de geração dos dados bancários
Bancos homologados:
001 - Banco do Brasil
033 - Santander
237 - Bradesco
341 - ItaÃº
399 - HSBC
748 - Sicred
041 - Banrisul
104 - CEF
422 - Safra
756 - SICOOB
6375 - Sofisa Correp. Santander
6111 - Banco Paulista Corresp. Bradesco
655 - Banco Votorantim

Parâmetros de Entrada:
PS_CODFILIAL         - Código da Filial do título selecionado (PCFILIAL)
PS_CODCOBRANCA       - Código da CobranÃ§a do título selecionado (PCCOB)
PN_CODBANCO          - Código do Banco para geraÃ§Ã£o dos dados bancários (PCBANCO)
PN_NUMTRANSVENDA     - Numtransvenda do tÃ­tulo selecionado (PCPREST)
PN_NUMDIASPROTESTO   - Número de dias para protesto do título
PS_PREST             - Prest do título selecionado (PCPREST)
PS_FILIALVIRTUAL     - Determina se utilizada Filial Virtual
PS_UTILIZAVALORBRUTO - Determina se deve ser utilizado o valor bruto do título na geração do Código de Barras e Linha digitável.
PS_PRIMEIRAIMPRESSAO - Determina se deve ser gerado o nosso numero (S) ou somente o codigo de de barras e linha digitável (N).
*/
  V_SQL    VARCHAR2(5000);
  V_SQLAUX VARCHAR2(2000);
  VS_NOSSONUMERO VARCHAR2(30);
  VS_CODBARRA VARCHAR2(44);
  VS_LINHADIGITAVEL VARCHAR2(65);
  VS_MSGERROGERANOSSONUMERO VARCHAR2(400);

  --ATUALIZA DADOS BANCARIOS DA PCPRES *******************************************
  PROCEDURE P_ATUALIZADADOSBANCARIOS(PN_NUMTRANSVENDA     IN NUMBER,
                                     PS_PREST             IN VARCHAR2,
                                     PS_NOSSONUMERO       IN VARCHAR2,
                                     PS_CODBARRA          IN VARCHAR2,
                                     PN_NUMDIASPROTESTO   IN NUMBER,
                                     PS_LINHADIGITAVEL    IN VARCHAR2,
                                     PN_CODBANCO          IN NUMBER,
                                     PS_PRIMEIRAIMPRESSAO IN VARCHAR2) IS
  BEGIN
    V_SQLAUX := 'UPDATE PCPREST
                 SET CODBARRA      = :PS_CODBARRA,
                     LINHADIG      = :PS_LINHADIGITAVEL,
                     CODBANCOCM    = :PS_CODBANCOCM,
                     NUMDIASPRAZOPROTESTO = ''' || PN_NUMDIASPROTESTO || '''';

    IF (PS_PRIMEIRAIMPRESSAO = 'S') AND (PS_NOSSONUMERO IS NOT NULL) THEN
      V_SQLAUX := V_SQLAUX || ' , NOSSONUMBCO = ''' || PS_NOSSONUMERO || '''';
    END IF;

    V_SQLAUX := V_SQLAUX || ' WHERE NUMTRANSVENDA = :PN_NUMTRANSVENDA
                                AND PREST         = :PS_PREST         ';

    EXECUTE IMMEDIATE V_SQLAUX USING PS_CODBARRA, PS_LINHADIGITAVEL, PN_CODBANCO, PN_NUMTRANSVENDA, PS_PREST;
  END;

  --ATUALIZA PROXIMO NOSSO NÃ¿MERO DO BANCO***************************************
  PROCEDURE P_ATUALIZAPROXIMONOSSONUMERO(PN_CODBANCO       IN NUMBER,
                                         PN_PROXNOSSNUMERO IN NUMBER,
                                         PN_NUMCARTEIRA    IN NUMBER DEFAULT -1) IS

  BEGIN
    V_SQLAUX := 'UPDATE PCBANCO SET PROXNOSSONUMBCO = :PN_PROXNOSSNUMERO ';

    IF (PN_NUMCARTEIRA > -1) THEN
      V_SQLAUX := V_SQLAUX || ', NUMCARTEIRA = ' || PN_NUMCARTEIRA;
    END IF;

    V_SQLAUX := V_SQLAUX || ' WHERE CODBANCO = :PN_CODBANCO ';

    EXECUTE IMMEDIATE V_SQLAUX USING PN_PROXNOSSNUMERO, PN_CODBANCO;
  END;

  --LER PRÃ¿XIMO NOSSO NÃ¿MERO DO BANCO*******************************************
  FUNCTION F_LERPROXIMONOSSONUMERO(PN_CODBANCO IN NUMBER,
                                   PS_MSGERRO OUT VARCHAR2) RETURN NUMBER IS

    -- FEITO PARA NÃ¿O PRENDER A TRANSAÃ¿Ã¿O, ASSIM QUE GERAR O PRÃ¿XIMO NOSSO NÃ¿MERO JÃ LIBERA A PCBANCO.
    PRAGMA AUTONOMOUS_TRANSACTION;

    VN_PROXNOSSONUMERO PCBANCO.PROXNOSSONUMBCO%TYPE;-- NUMBER(11);
    VS_PODEATUALIZARNOSSONUM VARCHAR2(1);
  BEGIN
      --SETA DADOS DO BANCO - TEM ESSE MESMO SELECT DENTRO DO MÃ¿TODO "P_GERADADOSBANCARIOS"
    SELECT NUMBANCO,
           PROXNOSSONUMBCO,
           NUMCONVENIO,
           NUMCARTEIRA,
           TIPOCOB,
           FAIXAINI,
           FAIXAFIM,
           REGEXP_REPLACE(UPPER(AGENCIA), '[^A-Z|0-9]'),
           REGEXP_REPLACE(UPPER(CONTA), '[^A-Z|0-9]'),
           NVL(CODCLIENTENOBANCO, '0'),
           NVL(CODCEDENTE, '0'),
           NVL(NUMCARTEIRA3, '0'),
           NVL(NOSSONUMBCO17DIGCOBCEFSIGCBREG,'N')
    INTO BANCO
    FROM PCBANCO
    WHERE CODBANCO = PN_CODBANCO
    FOR UPDATE;

    VN_PROXNOSSONUMERO := BANCO.PROXNOSSONUMBCO;
    --SE FOR BANCO SAFRA OU UNIBANCO
    IF (BANCO.NUMBANCO = 422) OR (BANCO.NUMBANCO = 409) OR (BANCO.NUMBANCO = 4221) OR
       (BANCO.NUMBANCO = 479) OR (BANCO.NUMBANCO = 3412) OR (BANCO.NUMBANCO = 399) OR
       (BANCO.NUMBANCO = 6375) THEN

      VS_PODEATUALIZARNOSSONUM := 'S';

      IF VN_PROXNOSSONUMERO < BANCO.FAIXAINI THEN
        PS_MSGERRO               := 'PrÃ³ximo Nosso NÃºmero Ã© menor que a Faixa Inicial. Favor verifique os parÃ¢metros da IntegraÃ§Ã£o BancÃ¡ria.';
        VN_PROXNOSSONUMERO       := 0;
        VS_PODEATUALIZARNOSSONUM := 'N';
      END IF;

      IF VN_PROXNOSSONUMERO > BANCO.FAIXAFIM THEN
        PS_MSGERRO               := 'PrÃ³ximo Nosso NÃºmero Ã© maior que a Faixa Final. Favor verifique os parÃ¢metros da IntegraÃ§Ã£o BancÃ¡ria.';
        VN_PROXNOSSONUMERO       := 0;
        VS_PODEATUALIZARNOSSONUM := 'N';
      END IF;

      IF VS_PODEATUALIZARNOSSONUM = 'S' THEN
         P_ATUALIZAPROXIMONOSSONUMERO(PN_CODBANCO, VN_PROXNOSSONUMERO + 1);
      END IF;
    ELSE
      IF ((VN_PROXNOSSONUMERO >= 99999) AND (BANCO.NUMBANCO = 1) AND (LENGTH(BANCO.NUMCONVENIO) <= 6)) AND
         (((BANCO.NUMCARTEIRA <> '16') AND (BANCO.NUMCARTEIRA <> '18')) AND (BANCO.TIPOCOB <> 'NR')) THEN
         P_ATUALIZAPROXIMONOSSONUMERO(PN_CODBANCO, 2);
         VN_PROXNOSSONUMERO := 1;
      ELSIF ((VN_PROXNOSSONUMERO >= 99999) AND (BANCO.NUMBANCO = 748)) THEN
         P_ATUALIZAPROXIMONOSSONUMERO(PN_CODBANCO, 2, TO_NUMBER(BANCO.NUMCARTEIRA) + 1);
         VN_PROXNOSSONUMERO := 1;
      ELSE
         P_ATUALIZAPROXIMONOSSONUMERO(PN_CODBANCO, VN_PROXNOSSONUMERO + 1);
      END IF;
    END IF;

  -- FEITO UM COMMIT PARA NÃ¿O PRENDER A TRANSAÃ¿Ã¿O, ASSIM QUE GERAR O PRÃ¿XIMO NOSSO NÃ¿MERO JÃ LIBERA A TABELA PCBANCO.
    -- OBS.: TEM UM PRAGMA NO INÃCIO DO MÃ¿TODO.
    COMMIT;

    RETURN VN_PROXNOSSONUMERO;
  END;

  --CALCULA MÃ¿DULO 10 DV2 CODBARRAS SANTANDER/BANESPA ********************************
  FUNCTION F_CALCULA_MODULO_10_DV2_033(PS_PALAVRA IN VARCHAR2,
                                       PN_BASE    IN NUMBER) RETURN VARCHAR2 IS
    I NUMBER(6);
    VN_MULTIPLICADOR NUMBER(6);
    VN_SOMA          NUMBER(6);
    VN_POSICAO       NUMBER(6);
    VN_NUMERO        NUMBER(6);
    VS_DV1           VARCHAR2(2);
    VN_RESTO         NUMBER(6);
    VS_DIGITO        VARCHAR2(2);
    VN_DIVISAO       NUMBER(6,2);
    VS_PALAVRA       VARCHAR2(44);
  BEGIN
    VN_RESTO   := 1;
    VS_PALAVRA := TRIM(PS_PALAVRA);

    WHILE (VN_RESTO = 1) LOOP -- RECULCULAR O DV ENQUANTO RESTO FOR IGUAL A 1
      VN_POSICAO       := LENGTH(VS_PALAVRA);
      VS_DV1           := SUBSTR(VS_PALAVRA, VN_POSICAO, 1);
      VN_SOMA          := 0;
      VN_MULTIPLICADOR := 2;

      WHILE VN_POSICAO > 0 LOOP
        VN_NUMERO := SUBSTR(VS_PALAVRA, VN_POSICAO, 1);
        VN_SOMA   := VN_SOMA + (VN_NUMERO * VN_MULTIPLICADOR);

        IF VN_MULTIPLICADOR = PN_BASE THEN
          VN_MULTIPLICADOR := 2;
        ELSE
          VN_MULTIPLICADOR := VN_MULTIPLICADOR + 1;
        END IF;

        VN_POSICAO := VN_POSICAO - 1;
      END LOOP;

      VN_DIVISAO := VN_SOMA / 11;
      VN_DIVISAO := TRUNC(VN_DIVISAO);
      VN_RESTO   := VN_SOMA - (VN_DIVISAO * 11);

      IF VN_RESTO = 1 THEN
          IF VS_DV1 = '9' THEN
            VS_DV1 := '0';
          ELSE
            IF TO_NUMBER(VS_DV1) < 9 THEN
              VS_DV1 := TO_NUMBER(VS_DV1) + 1;
            END IF;
          END IF;

          VS_PALAVRA := SUBSTR(VS_PALAVRA, 1, LENGTH(VS_PALAVRA) - 1) || VS_DV1; -- {SUBSTITUINDO DV1}
      END IF;

      IF VN_RESTO = 0 THEN
        VS_DIGITO := VS_DV1 ||'0'; -- {DIGITO A SER CALCULADO DIGITO 2}
      END IF;

      IF VN_RESTO > 1 THEN
        VS_DIGITO := VS_DV1 || TO_CHAR(11 - VN_RESTO);
      END IF;
    END LOOP;

    RETURN VS_DIGITO;
  END;
  --****************************************************************************

  --CALCULA MÃ¿DULO 10 **********************************************************
  FUNCTION F_CALCULA_MODULO_10(PS_PALAVRA IN VARCHAR2,
                               PN_BASE    IN NUMBER,
                               PS_TIPO    IN VARCHAR2 DEFAULT 'L') RETURN VARCHAR2 IS
    I NUMBER(6);
    VN_MULTIPLICADOR NUMBER(6);
    VN_SOMA          NUMBER(6);
    VN_POSICAO       NUMBER(6);
    VN_POSICAO_AUX   NUMBER(6);
    VN_NUMERO        NUMBER(6);
    VN_NUMEROAUX     NUMBER(6);
    VN_RESTO         NUMBER(6);
    VS_DIGITO        VARCHAR2(5);
    VN_MAIORVALOR    NUMBER(6);
    VN_DIVISAO       NUMBER(6,2);
    VN_PESO          NUMBER(6);
    VN_MULTIPLO      NUMBER(6);
    VN_RESULTMULTIPL NUMBER(6);
    VN_CONTADOR      NUMBER(6);
  BEGIN
    IF (BANCO.NUMBANCO = 399) THEN
    -- CALCULO DV PARA O BANCO 399 HSBC
      IF ((BANCO.TIPOCOB = 'NR') OR (BANCO.TIPOCOB = 'NS')) THEN
        VN_POSICAO     := LENGTH(TRIM(PS_PALAVRA)) + 1;
        VN_POSICAO_AUX := 1;
        VN_SOMA        := 0;
        VN_RESTO       := 0;
        VN_MULTIPLO    := 0;

        IF (VN_POSICAO MOD 2) = 0 THEN
          VN_PESO := 2;
        ELSE
          VN_PESO := 1;
        END IF;

        WHILE (VN_POSICAO > VN_POSICAO_AUX) LOOP
          VN_NUMERO := TO_NUMBER(SUBSTR(PS_PALAVRA, VN_POSICAO_AUX, 1));

          IF (VN_NUMERO * VN_PESO) >= 10 THEN
            VN_MULTIPLO := TO_NUMBER(SUBSTR(VN_NUMERO * VN_PESO, 1, 1)) + TO_NUMBER(SUBSTR(VN_NUMERO * VN_PESO, 2, 1));
          ELSE
            VN_MULTIPLO := VN_NUMERO * VN_PESO;
          END IF;

          VN_SOMA := VN_SOMA + VN_MULTIPLO;

          IF (VN_PESO = 2) THEN
            VN_PESO := 1;
          ELSE
            VN_PESO := 2;
          END IF;

          VN_POSICAO_AUX := VN_POSICAO_AUX + 1;
        END LOOP;

        VN_RESTO := (VN_SOMA MOD 10);

        IF (VN_RESTO = 0) THEN
          VS_DIGITO := 0;
        ELSE
          VS_DIGITO := 10 - VN_RESTO;
        END IF;
      ELSE
        VN_POSICAO       := LENGTH(TRIM(PS_PALAVRA));
        VN_SOMA          := 0;
        VN_RESTO         := 0;
        VN_MULTIPLICADOR := 2;

        FOR I IN REVERSE 1 .. VN_POSICAO LOOP
          VN_NUMERO    := TO_NUMBER(SUBSTR(PS_PALAVRA, I, 1));

          IF (VN_NUMERO * VN_MULTIPLICADOR) >= 10 THEN
            VN_SOMA := VN_SOMA + TO_NUMBER(TRUNC((VN_NUMERO * VN_MULTIPLICADOR) / 10) + ((VN_NUMERO * VN_MULTIPLICADOR) MOD 10));
          ELSE
            VN_SOMA := VN_SOMA + (VN_NUMERO * VN_MULTIPLICADOR);
          END IF;

          VN_MULTIPLICADOR := VN_MULTIPLICADOR + 1;

          IF (VN_MULTIPLICADOR > 2) THEN
            VN_MULTIPLICADOR := 1;
          END IF;
        END LOOP;

        VN_DIVISAO := TRUNC(VN_SOMA / 10);
        VN_RESTO   := VN_SOMA - (VN_DIVISAO * 10);

        IF (VN_RESTO = 0) OR (VN_RESTO = 10) THEN
          VS_DIGITO := '0';
        ELSE
          VS_DIGITO := 10 - VN_RESTO;
        END IF;
      END IF;
    ELSIF (BANCO.NUMBANCO = 41) THEN
      VN_MULTIPLICADOR := 2;
      VN_SOMA          := 0;
      VN_POSICAO       := LENGTH(TRIM(PS_PALAVRA));
      --ESSE CONTADOR IRÃ DEFINIR EM QUAL REGISTRO QUE ESTÃ E ESSA FAZER A MULTIPLICAÃ¿Ã¿O CORRETA
      VN_CONTADOR      := 0;
      --PERCORRE, INDIVIDUALMENTE, CADA NÃ¿MERO DO NOSSO NÃ¿MERO PARA FAZER O CALCULO E O SOMATÃ¿RIO
      FOR I IN REVERSE 1 .. VN_POSICAO LOOP
        VN_NUMERO := TO_NUMBER(SUBSTR(PS_PALAVRA, I, 1));
        --AQUI DEFINE O MULTIPLICADOR, SEMPRE COMEÃ¿ANDO DO NÃ¿MERO 2 E O SEGUINTE Ã¿ 1, SEMPRE MULTIPLICARÃ COM UM DOS DOIS E SEMPRE NESSA ORDER, UM SEGUIDO DO OUTRO.
        --AQUI VERIFICA SE O CONTADOR Ã¿ PAR OU IMPAR, CASO SEJA PAR IRÃ MULTIPLICAR POR 2 E CASO SEJA IMPAR IRÃ MULTIPLICAR POR 1
        IF MOD(VN_CONTADOR, 2) = 0 THEN
          VN_RESULTMULTIPL := (VN_NUMERO * 2);
        ELSE
          VN_RESULTMULTIPL := (VN_NUMERO * 1);
        END IF;
        --SÃ¿ IRÃ SUBTRAIR POR 9 CASO A MULTIPLICAÃ¿Ã¿O FEITA FOR MAIOR QUE 9
        IF VN_RESULTMULTIPL > 9 THEN
          VN_RESULTMULTIPL := VN_RESULTMULTIPL - 9;
        END IF;
        --FAZ O SOMATORIO
        VN_SOMA := VN_SOMA + VN_RESULTMULTIPL;
        VN_CONTADOR := VN_CONTADOR + 1;
      END LOOP;
      --CASO O RESULTADO DA SOMA FOR MENOR QUE 10, ENTÃ¿O O RESTO SERÃ ELE MESMO
      IF VN_SOMA < 10 THEN
        VN_RESTO := VN_SOMA;
      ELSE
        --CASO O SOMATÃ¿RIO FOR MAIOR OU IGUAL A 10, ENTÃ¿O IRÃ PEGAR O RESTO DA DIVISÃ¿O DA SOMA POR 10
        VN_RESTO := MOD(VN_SOMA, 10);
      END IF;
      --SE O RESTO FOR MAIOR QUE ZERO, O DIGITO SERÃ O VALOR DA SUBTRAÃ¿Ã¿O DE 10 PELO RESTO,
      IF VN_RESTO > 0 THEN
        VS_DIGITO := 10 - VN_RESTO;
      ELSE
        --SE O RESTO FOR MENOR OU IGUAL A ZERO, O DIGITO SERÃ 0
        VS_DIGITO := 0;
      END IF;
    ELSE
    -- CALCULO DV PARA OS OUTROS BANCOS
      VN_MULTIPLICADOR := 2;
      VN_SOMA          := 0;
      VN_POSICAO       := LENGTH(TRIM(PS_PALAVRA));

      FOR I IN REVERSE 1 .. VN_POSICAO LOOP
        VN_NUMERO    := TO_NUMBER(SUBSTR(PS_PALAVRA, I, 1));

        IF ((BANCO.NUMBANCO = 33) OR (BANCO.NUMBANCO = 6375)) AND (PS_TIPO = 'DV1') THEN -- CALCULO DV1 CODBARRAS BANCO SANTANDER
          IF ((VN_NUMERO * VN_MULTIPLICADOR) > 9) THEN
            VN_SOMA := VN_SOMA + ((VN_NUMERO * VN_MULTIPLICADOR) - 9);
          ELSE
            VN_SOMA := VN_SOMA + (VN_NUMERO * VN_MULTIPLICADOR);
          END IF;

          IF (VN_MULTIPLICADOR = PN_BASE) THEN
            VN_MULTIPLICADOR := 2;
          ELSE
            VN_MULTIPLICADOR := VN_MULTIPLICADOR - 1;
          END IF;
        ELSE
          VN_NUMEROAUX := VN_NUMERO * VN_MULTIPLICADOR;

          IF VN_NUMEROAUX >= 10 THEN
            VN_NUMERO    := VN_NUMEROAUX;

            IF ((BANCO.NUMBANCO = 33) OR (BANCO.NUMBANCO = 6375)) AND (PS_TIPO = 'N') THEN
              VN_NUMEROAUX := TO_NUMBER(SUBSTR(VN_NUMERO, 2, 1));
            ELSE
              VN_NUMEROAUX := TO_NUMBER(SUBSTR(VN_NUMERO, 1, 1)) + TO_NUMBER(SUBSTR(VN_NUMERO, 2, 1));
            END IF;
          END IF;

          VN_SOMA := VN_SOMA + VN_NUMEROAUX;

          IF ((BANCO.NUMBANCO = 33)  OR (BANCO.NUMBANCO = 6375)) AND (PS_TIPO = 'N') THEN
            CASE
              WHEN (VN_MULTIPLICADOR = 3) THEN VN_MULTIPLICADOR := 7;
              WHEN (VN_MULTIPLICADOR = 7) THEN VN_MULTIPLICADOR := 9;
              WHEN (VN_MULTIPLICADOR = 9) THEN VN_MULTIPLICADOR := 1;
              WHEN (VN_MULTIPLICADOR = 1) THEN VN_MULTIPLICADOR := 3;
              ELSE VN_MULTIPLICADOR := VN_MULTIPLICADOR;
            END CASE;
          ELSE
            IF VN_MULTIPLICADOR = PN_BASE THEN
              VN_MULTIPLICADOR := 1;
            ELSE
              VN_MULTIPLICADOR := VN_MULTIPLICADOR + 1;
            END IF;
          END IF;
        END IF;

        VN_POSICAO := VN_POSICAO - 1;
      END LOOP;

     CASE
       WHEN (BANCO.NUMBANCO = 1) OR (BANCO.NUMBANCO = 041) OR (BANCO.NUMBANCO = 104) THEN
         IF (VN_SOMA < 10) AND (BANCO.NUMBANCO <> 104) THEN
           IF VN_SOMA > 0 THEN
             VS_DIGITO := 10 - VN_SOMA;
           ELSE
             VS_DIGITO := 0;
           END IF;
         ELSE
           VN_RESTO := VN_SOMA - ((TRUNC(VN_SOMA / 10)) * 10);

           IF VN_RESTO = 0 THEN
              VS_DIGITO := 0;
           ELSE
              VS_DIGITO := 10 - VN_RESTO;
           END IF;
         END IF;
       WHEN ((BANCO.NUMBANCO = 33) OR (BANCO.NUMBANCO = 6375)) THEN
         IF (PS_TIPO = 'L') THEN
           VN_RESTO := VN_SOMA - (TRUNC(VN_SOMA / 10) * 10);

           IF VN_RESTO = 0 THEN
              VS_DIGITO := 0;
           ELSE
              VS_DIGITO := 10 - VN_RESTO;
           END IF;
         ELSIF (PS_TIPO = 'DV1')  THEN -- CALCULO DV1 CODBARRAS BANCO SANTANDER
           VN_DIVISAO := VN_SOMA / 10;
           VN_DIVISAO := TRUNC(VN_DIVISAO);
           VN_RESTO   := VN_SOMA - (VN_DIVISAO * 10);

           IF VN_RESTO > 0 THEN
             VS_DIGITO := 10 - VN_RESTO;
           ELSE
             VS_DIGITO := '0';
           END IF;
         ELSIF (PS_TIPO = 'N') THEN
           IF (VN_SOMA MOD 10) = 0 THEN
             VN_SOMA := 10;
           ELSE
              IF VN_SOMA > 10 THEN
                VN_SOMA := SUBSTR(VN_SOMA, 2, 1);
              END IF;
           END IF;

           VS_DIGITO := 10 - VN_SOMA;
         END IF;
       WHEN ((BANCO.NUMBANCO = 237) OR (BANCO.NUMBANCO = 6111)) THEN
         VN_MAIORVALOR := 1000;

         WHILE (VN_MAIORVALOR >= VN_SOMA) LOOP
           VS_DIGITO     := VN_MAIORVALOR - VN_SOMA;
           VN_MAIORVALOR := VN_MAIORVALOR - 10;
         END LOOP;
       WHEN (BANCO.NUMBANCO = 341) OR (BANCO.NUMBANCO = 655) THEN
         VN_DIVISAO := VN_SOMA / 10;
         VN_DIVISAO := TRUNC(VN_DIVISAO);
         VN_RESTO   := VN_SOMA - (VN_DIVISAO * 10);

         IF VN_RESTO > 0 THEN
           VS_DIGITO := 10 - VN_RESTO;
         ELSE
           VS_DIGITO := '0';
         END IF;
       WHEN (BANCO.NUMBANCO = 756) THEN
         VN_DIVISAO := VN_SOMA / 10;
         VN_DIVISAO := TRUNC(VN_DIVISAO);
         VN_RESTO   := VN_SOMA - (VN_DIVISAO * 10);
         VS_DIGITO := 10 - VN_RESTO;

         IF VS_DIGITO = '10' THEN
           VS_DIGITO := '0';
         END IF;
       WHEN (BANCO.NUMBANCO = 748) THEN
         CASE
      WHEN (VN_SOMA >= 1) AND (VN_SOMA <= 9) THEN
             IF (VN_SOMA = 10) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 10 - VN_SOMA;
             END IF;

           WHEN (VN_SOMA >= 10) AND (VN_SOMA <= 19) THEN
             IF (VN_SOMA = 10) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 20 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 20) AND (VN_SOMA <= 29) THEN
             IF (VN_SOMA = 20) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 30 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 30) AND (VN_SOMA <= 39) THEN
             IF (VN_SOMA = 30) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 40 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 40) AND (VN_SOMA <= 49) THEN
             IF (VN_SOMA = 40) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 50 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 50) AND (VN_SOMA <= 59) THEN
             IF (VN_SOMA = 50) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 60 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 60) AND (VN_SOMA <= 69) THEN
             IF (VN_SOMA = 60) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 70 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 70) AND (VN_SOMA <= 79) THEN
             IF (VN_SOMA = 70) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 80 - VN_SOMA;
             END IF;
           WHEN (VN_SOMA >= 80) AND (VN_SOMA <= 89) THEN
             IF (VN_SOMA = 80) THEN
               VS_DIGITO := 0;
             ELSE
               VS_DIGITO := 90 - VN_SOMA;
             END IF;
           ELSE
             VS_DIGITO := 0;
         END CASE;
         WHEN (BANCO.NUMBANCO = 422) THEN
           VN_DIVISAO := VN_SOMA / 10;
           VN_DIVISAO := TRUNC(VN_DIVISAO);
           VN_RESTO   := VN_SOMA - (VN_DIVISAO * 10);
           VS_DIGITO := 10 - VN_RESTO;

           IF VN_RESTO > 0 THEN
             VS_DIGITO := 10 - VN_RESTO;
           ELSE
             VS_DIGITO := '0';
           END IF;
     END CASE;

   END IF;
   RETURN VS_DIGITO;
  END;

  --CALCULA MÃ¿DULO 12***********************************************************
  FUNCTION F_CALCULA_MODULO_11_6375(PS_PALAVRA IN VARCHAR2) RETURN VARCHAR IS
    V_CONTADOR NUMBER(10);
    V_AUX_MUL NUMBER(10);
    V_SOMA NUMBER(10);
    V_RESTO NUMBER(10);
    V_AUX_SOMA NUMBER(10);
    V_AUX VARCHAR2(1);
    NAOSOMAR BOOLEAN;
  BEGIN
    V_CONTADOR := 1;
    V_AUX_MUL  := 2;
    V_SOMA     := 0;
    V_AUX_SOMA := 0;
    V_AUX      := '';
    V_RESTO    := 0;
    NAOSOMAR := FALSE;

    WHILE V_CONTADOR <= LENGTH(PS_PALAVRA)
    LOOP
      V_AUX := SUBSTR(PS_PALAVRA,V_CONTADOR*(-1),1);
      V_AUX_SOMA := TO_NUMBER(NVL(V_AUX,0)) * V_AUX_MUL;

      IF V_AUX_MUL = 9 THEN
        V_AUX_MUL := 2;
        NAOSOMAR := TRUE;
      END IF;

      V_SOMA := V_SOMA + V_AUX_SOMA;

      IF NAOSOMAR = TRUE THEN
        V_AUX_MUL  := V_AUX_MUL;
        NAOSOMAR := FALSE;
      ELSE
        V_AUX_MUL  := V_AUX_MUL + 1;
      END IF;

      V_CONTADOR := V_CONTADOR + 1;
    END LOOP;

    V_AUX_SOMA := TRUNC(V_SOMA/11);
    V_AUX_SOMA := V_AUX_SOMA*11;
    V_RESTO := V_SOMA - V_AUX_SOMA;
    V_RESTO := 11 - V_RESTO;

    IF V_RESTO > 9 THEN
      V_RESTO := 0;
    END IF;

    RETURN V_RESTO;
  END;

  --CALCULA MÃ¿DULO 11***********************************************************
  FUNCTION F_CALCULA_MODULO_11(PS_PALAVRA      IN VARCHAR2,
                               PN_BASE         IN NUMBER,
                               PN_TIPO         IN VARCHAR2,
                               PS_NOVODIGMOD10 OUT VARCHAR2) RETURN VARCHAR2 IS
    I NUMBER(6);
    VN_MULTIPLICADOR NUMBER(6);
    VN_SOMA          NUMBER(6);
    VN_POSICAO       NUMBER(6);
    VN_NUMERO        NUMBER(6);
    VN_DIVISAO       NUMBER(6,2);
    VN_RESTO         NUMBER(6);
    VS_DIGITO        VARCHAR2(2);
    VS_PALAVRA       VARCHAR2(44);
    VN_CONTADOR       NUMBER(6);
    VN_RESULTMULTIPL  NUMBER(6);
    VS_NOVODIGMOD10   VARCHAR2(1);
  BEGIN
    PS_NOVODIGMOD10 := '';

    IF (BANCO.NUMBANCO = 1) AND (PN_TIPO = 'N') THEN
    -- VALIDAÃ¿Ã¿O PARA O BANCO 001
      VN_MULTIPLICADOR := PN_BASE;
    ELSIF (BANCO.NUMBANCO = 756) AND (PN_TIPO = 'N') THEN
      VN_MULTIPLICADOR := 3;
    ELSIF (BANCO.NUMBANCO = 399) AND ((BANCO.TIPOCOB = 'NR') OR (BANCO.TIPOCOB = 'NS')) AND (PN_TIPO = 'N') THEN
    -- VALIDAÃ¿Ã¿O PARA O BANCO 399 COBRANÃ¿AS 'NR' E 'NS' -- BASE 9 FIXA
      VN_MULTIPLICADOR := 9;
    ELSE
      VN_MULTIPLICADOR := 2;
    END IF;
    --NOVO JEITO DE CALCULAR O DIGITO PARA O BANCO 41 (BANRISUL)
    IF (BANCO.NUMBANCO = 41) and (PN_TIPO = 'N') THEN
      VN_CONTADOR := 2;
      VN_SOMA     := 0;
      VN_POSICAO  := LENGTH(PS_PALAVRA);
      -- FAZ O CALCULO DO NOSSO NÃ¿MERO (DA DIREITA PARA ESQUERDA)
      FOR I IN REVERSE 1 .. VN_POSICAO LOOP
        VN_NUMERO := TO_NUMBER(SUBSTR(PS_PALAVRA, I, 1));
        VN_RESULTMULTIPL := VN_NUMERO * VN_CONTADOR;
        VN_SOMA := VN_SOMA + VN_RESULTMULTIPL;
        --CONTROLA O MULTIPLICADOR, QUE COMEÃ¿A A PARTIR DO NÃ¿MERO 2 E VAI ATÃ¿ O NÃ¿MERO 7, APÃ¿S RODAR O 7 DEVE VOLTAR PARA O 2
        IF VN_CONTADOR = 7 THEN
          VN_CONTADOR := 2;
        ELSE
          VN_CONTADOR := VN_CONTADOR + 1;
        END IF;
      END LOOP;
      --SE A SOMA DO CALCULO DO NOSSO NÃ¿MERO DER MENOR QUE 11, ENTÃ¿O O RESTO SERÃ ELE MESMO
      IF VN_SOMA < 11 THEN
        VN_RESTO := VN_SOMA;
      ELSE
        --CASO A SOMA SEJA 11 OU MAIOR, O RESTO SERÃ O RESTO DA DIVISÃ¿O DA SOMA POR 11
        VN_RESTO := MOD(VN_SOMA, 11);
      END IF;
      --CASO O RESTO SEJA 1, Ã¿ CONSIDERADO DIGITO INVALIDO, DEVERÃ SOMAR O DIGITO DO MOD10(ULTIMO NÃ¿MERO DO NOSSO NÃ¿MERO) MAIS 1, E FAZER TODO O CALCULO NOVAMENTE
      IF VN_RESTO = 1 THEN
        VS_PALAVRA        := PS_PALAVRA;
        VN_NUMERO         := TO_NUMBER(SUBSTR(VS_PALAVRA, LENGTH(VS_PALAVRA), 1));
        --CASO O DIGITO DO MOD10 SEJA 9, SE ACRESCENTAR MAIS 1 IRÃ FICAR 10, E TAMBÃ¿M NÃ¿O PODE, ENTÃ¿O, DEVE VOLTAR PARA O 0(ZERO)
        IF VN_NUMERO < 9 THEN
          VN_NUMERO := VN_NUMERO + 1;
        ELSE
          VN_NUMERO := 0;
        END IF;

        VS_PALAVRA := SUBSTR(VS_PALAVRA, 1, LENGTH(VS_PALAVRA) - 1);
        VS_PALAVRA := VS_PALAVRA || TO_CHAR(VN_NUMERO);
        VN_CONTADOR := 2;
        VN_SOMA     := 0;
        VN_POSICAO  := LENGTH(VS_PALAVRA);

        --FAZENDO O CALCULO NOVAMENTE COM O NOVO NOSSO NÃ¿MERO, OU SEJA, COM O DIGITO DO MOD10 INCREMENTADO
        FOR I IN REVERSE 1 .. VN_POSICAO LOOP
          VN_NUMERO := TO_NUMBER(SUBSTR(VS_PALAVRA, I, 1));
          VN_RESULTMULTIPL := VN_NUMERO * VN_CONTADOR;
          VN_SOMA := VN_SOMA + VN_RESULTMULTIPL;
          --CONTROLA O MULTIPLICADOR, QUE COMEÃ¿A A PARTIR DO NÃ¿MERO 2 E VAI ATÃ¿ O NÃ¿MERO 7, APÃ¿S RODAR O 7 DEVE VOLTAR PARA O 2
          IF VN_CONTADOR = 7 THEN
            VN_CONTADOR := 2;
          ELSE
            VN_CONTADOR := VN_CONTADOR + 1;
          END IF;
        END LOOP;

        --CASO A SOMA DO NOVO CALCULO SEJA MENOR QUE 11, ENTÃ¿O O RESTO SERÃ ELE MESMO
        IF VN_SOMA < 11 THEN
          VN_RESTO := VN_SOMA;
        ELSE
          --CASO A SOMA SEJA 11 OU MAIOR, ENTÃ¿O IRÃ BUSCAR O RESTO DA DIVISÃ¿O DA SOMA POR 11
          VN_RESTO := MOD(VN_SOMA, 11);
        END IF;

        --CASO O RESTO SEJA 0 (ZERO), O DIGITO TAMBÃ¿M SERÃ 0 (ZERO)
        IF VN_RESTO = 0 THEN
          VS_DIGITO := VN_RESTO;
        ELSE
          --CASO O RESTO SEJA MAIOR QUE 0, ENTÃ¿O IRÃ SUBTRAIR 11 PELO RESTO
          VS_DIGITO := (11 - VN_RESTO);
        END IF;

        PS_NOVODIGMOD10 := SUBSTR(VS_PALAVRA, LENGTH(VS_PALAVRA), 1);
      ELSIF VN_RESTO = 0 THEN
        --REFERENTE AO PRIMEIRO CALCULO AINDA, CASO O RESTO SEJA 0 (ZERO), O DIGITO SERÃ ELE MESMO
        VS_DIGITO := VN_RESTO;
      ELSE
        --CASO O RESTO SEJA MAIOR QUE 1, ENTÃ¿O IRÃ SUBTRAIR 11 PELO RESTO
        VS_DIGITO := (11 - VN_RESTO);
      END IF;

      VS_DIGITO := VS_DIGITO;
    ELSE
      VN_SOMA    := 0;
      VN_POSICAO := LENGTH(PS_PALAVRA);

      FOR I IN REVERSE 1 .. VN_POSICAO LOOP
        VN_NUMERO := SUBSTR(PS_PALAVRA, I, 1);
        VN_SOMA := VN_SOMA + (VN_NUMERO * VN_MULTIPLICADOR);

        IF (BANCO.NUMBANCO = 1) AND (PN_TIPO = 'N') THEN
        -- VALIDAÃ¿Ã¿O PARA O BANCO 001
          IF VN_MULTIPLICADOR = 2 THEN
            VN_MULTIPLICADOR := PN_BASE;
          ELSE
            VN_MULTIPLICADOR := VN_MULTIPLICADOR - 1;
          END IF;

        ELSIF (BANCO.NUMBANCO = 399) AND ((BANCO.TIPOCOB = 'NR') OR (BANCO.TIPOCOB = 'NS')) AND (PN_TIPO = 'N') THEN
        -- VALIDAÃ¿Ã¿O PARA O BANCO 399 COBRANÃ¿AS 'NR' E 'NS' -- BASE 9 FIXA
          IF VN_MULTIPLICADOR = 2 THEN
            VN_MULTIPLICADOR := 9;
          ELSE
            VN_MULTIPLICADOR := VN_MULTIPLICADOR - 1;
          END IF;
        ELSIF (BANCO.NUMBANCO = 104) THEN
          VN_MULTIPLICADOR := VN_MULTIPLICADOR + 1;

          IF VN_MULTIPLICADOR = 10 THEN
            VN_MULTIPLICADOR := 2;
          END IF;
        ELSIF (BANCO.NUMBANCO = 756) AND (PN_TIPO = 'N') THEN
          CASE
            WHEN (VN_MULTIPLICADOR = 3) THEN VN_MULTIPLICADOR := 7;
            WHEN (VN_MULTIPLICADOR = 7) THEN VN_MULTIPLICADOR := 9;
            WHEN (VN_MULTIPLICADOR = 9) THEN VN_MULTIPLICADOR := 1;
            WHEN (VN_MULTIPLICADOR = 1) THEN VN_MULTIPLICADOR := 3;
            ELSE VN_MULTIPLICADOR := VN_MULTIPLICADOR;
          END CASE;

          IF VN_MULTIPLICADOR = PN_BASE THEN
            VN_MULTIPLICADOR := 2;
          ELSE
            VN_MULTIPLICADOR := VN_MULTIPLICADOR + 1;
          END IF;
        END IF;

        VN_POSICAO := VN_POSICAO - 1;
      END LOOP;

      IF (BANCO.NUMBANCO = 041) AND (VN_SOMA < 11) AND (VN_SOMA > 1) THEN
        VS_DIGITO := (11 - VN_SOMA);
      ELSIF (BANCO.NUMBANCO = 399) THEN
        VN_RESTO := VN_SOMA MOD 11;
      ELSE
        VN_DIVISAO := VN_SOMA / 11;
        VN_DIVISAO := TRUNC(VN_DIVISAO);
        VN_RESTO   := VN_SOMA - (VN_DIVISAO * 11);
      END IF;

      IF (PN_TIPO = 'C') THEN
        IF (VN_RESTO = 0) OR (VN_RESTO = 1) OR (VN_RESTO > 9) THEN
          VS_DIGITO := '1';
        ELSE
          VS_DIGITO := 11 - VN_RESTO;
        END IF;
      ELSE
        CASE
          WHEN (BANCO.NUMBANCO = 1) THEN
            VS_DIGITO := 11 - VN_RESTO;

            IF VN_RESTO = 10 THEN
              VS_DIGITO := 'X';
            ELSIF VN_RESTO = 0 THEN
                VS_DIGITO := '0';
            ELSE
              VS_DIGITO := VN_RESTO;
            END IF;
          WHEN (BANCO.NUMBANCO = 33) OR (BANCO.NUMBANCO = 748) OR (BANCO.NUMBANCO = 6375) THEN
            IF (VN_RESTO = 1) OR (VN_RESTO = 0) THEN
              VS_DIGITO := '0';
            ELSE
              VS_DIGITO := 11 - VN_RESTO;
            END IF;
          WHEN ((BANCO.NUMBANCO = 237) OR (BANCO.NUMBANCO = 6111)) THEN
            IF VN_RESTO = 1 THEN
              VS_DIGITO := 'P';
            ELSIF VN_RESTO = 0 THEN
              VS_DIGITO := '0';
            ELSE
              VS_DIGITO := 11 - VN_RESTO;
            END IF;
          WHEN (BANCO.NUMBANCO = 399) THEN
            IF (BANCO.TIPOCOB = 'NR') OR (BANCO.TIPOCOB = 'NS') THEN
              IF (VN_RESTO = 0) OR (VN_RESTO = 10) THEN
                VS_DIGITO := 0;
              ELSE
                VS_DIGITO := VN_RESTO;
              END IF;
            ELSIF (BANCO.TIPOCOB = 'R') THEN
              IF (VN_RESTO = 1) OR (VN_RESTO = 0) THEN
                VS_DIGITO := 0;
              ELSE
                VS_DIGITO := 11 - VN_RESTO;
              END IF;
            END IF;
          WHEN (BANCO.NUMBANCO = 041) THEN
            IF VN_RESTO = 1 THEN
              IF (SUBSTR(PS_PALAVRA, LENGTH(PS_PALAVRA), 1) = '9') THEN
                VS_PALAVRA := SUBSTR(PS_PALAVRA, 1, LENGTH(PS_PALAVRA) -1) || '0';
                VS_DIGITO  := F_CALCULA_MODULO_11(VS_PALAVRA, 7, 'N', VS_NOVODIGMOD10);
              ELSE
                VS_PALAVRA := SUBSTR(PS_PALAVRA, 1, LENGTH(PS_PALAVRA) -1) || (SUBSTR(PS_PALAVRA, LENGTH(PS_PALAVRA), 1) + 1);
                VS_DIGITO  := F_CALCULA_MODULO_11(VS_PALAVRA, 7, 'N', VS_NOVODIGMOD10);
              END IF;
            ELSIF (VN_RESTO = 0) THEN
              VS_DIGITO := VN_RESTO;
            ELSE
              VS_DIGITO := (11 - VN_RESTO);
            END IF;
          WHEN (BANCO.NUMBANCO = 104) THEN
            VS_DIGITO := 11 - VN_RESTO;

            IF VS_DIGITO > 9 THEN
              VS_DIGITO := '0';
            END IF;
          WHEN (BANCO.NUMBANCO = 756) THEN
            IF VN_RESTO = 1 THEN
              VS_DIGITO := '0';
            ELSIF VN_RESTO = 0 THEN
                VS_DIGITO := '0';
            ELSE
              VS_DIGITO := 11 - VN_RESTO;
            END IF;

          WHEN (BANCO.NUMBANCO = 422) THEN
            IF VN_RESTO = 0 THEN
              VS_DIGITO := '1';
            ELSIF VN_RESTO = 1 THEN
              VS_DIGITO := '0';
            ELSE
              VS_DIGITO := 11 - VN_RESTO;
            END IF;
        END CASE;
      END IF;
    END IF;

    RETURN VS_DIGITO;
  END;

  --GERAR LINHA DIGITAVEL PARA OS TITULOS **********************************************************
  FUNCTION F_GERALINHADIGITAVEL(PS_CODBARRA VARCHAR2,
                                PN_VALOR              IN NUMBER,
                                PN_VALORLIQUIDO       IN NUMBER,
                                PS_UTILIZAVALORBRUTO  IN VARCHAR2) RETURN VARCHAR2 IS
    VS_CAMPO1        VARCHAR2(20);
    VS_CAMPO2        VARCHAR2(20);
    VS_CAMPO3        VARCHAR2(20);
    VS_CAMPO4        VARCHAR2(20);
    VS_CAMPO5        VARCHAR2(20);
    VS_LINHADIG_TEMP VARCHAR2(65);
  BEGIN
    -- O CODIGO DE GERACAO DA LINHA DIGITAVEL Ã¿ PADRÃ¿O PARA TODOS OS BANCOS
    VS_CAMPO1 := '';
    VS_CAMPO1 := SUBSTR(PS_CODBARRA, 1, 4);
    VS_CAMPO1 := VS_CAMPO1 || SUBSTR(PS_CODBARRA, 20, 5);
    VS_CAMPO1 := VS_CAMPO1 || F_CALCULA_MODULO_10(VS_CAMPO1, 2, 'L');

    VS_CAMPO2 := '';
    VS_CAMPO2 := SUBSTR(PS_CODBARRA, 25, 10);
    VS_CAMPO2 := VS_CAMPO2 || F_CALCULA_MODULO_10(VS_CAMPO2, 2, 'L');

    VS_CAMPO3 := '';
    VS_CAMPO3 := SUBSTR(PS_CODBARRA, 35, 10);
    VS_CAMPO3 := VS_CAMPO3 || F_CALCULA_MODULO_10(VS_CAMPO3, 2, 'L');

    VS_CAMPO4 := '';
    VS_CAMPO4 := SUBSTR(PS_CODBARRA, 5, 1);

    VS_CAMPO5 := '';

    IF PS_UTILIZAVALORBRUTO = 'S' THEN
      VS_CAMPO5 := SUBSTR(PS_CODBARRA, 6, 4) || LPAD(PN_VALOR * 100, 10, '0');
    ELSE
      VS_CAMPO5 := SUBSTR(PS_CODBARRA, 6, 4) || LPAD(PN_VALORLIQUIDO * 100, 10, '0');
    END IF;

   VS_LINHADIG_TEMP := VS_CAMPO1 || VS_CAMPO2 || VS_CAMPO3 || VS_CAMPO4 || VS_CAMPO5;

   VS_LINHADIG_TEMP := SUBSTR(VS_LINHADIG_TEMP, 1, 5) || '.' || SUBSTR(VS_LINHADIG_TEMP, 6, 5) || '  ' ||
                       SUBSTR(VS_LINHADIG_TEMP, 11, 5) || '.' || SUBSTR(VS_LINHADIG_TEMP, 16, 6) || '  ' ||
                       SUBSTR(VS_LINHADIG_TEMP, 22, 5) || '.' || SUBSTR(VS_LINHADIG_TEMP, 27, 6) || '  ' ||
                       SUBSTR(VS_LINHADIG_TEMP, 33, 1) || '  ' || SUBSTR(VS_LINHADIG_TEMP, 34, 100);

   RETURN VS_LINHADIG_TEMP;
  END;

  -- GERA O INICO DO CODIGO DE BARRAS PADRÃ¿O PARA TODOS OS BANCOS *******************************************
  FUNCTION F_MONTA_INICIO_CODBARRAS(PN_VALOR             IN NUMBER,
                                    PN_VALORLIQUIDO      IN NUMBER,
                                    PS_UTILIZAVALORBRUTO IN VARCHAR2,
                                    PD_DTVENC            IN DATE) RETURN VARCHAR2 IS
    VS_CODBARRA_TEMP VARCHAR2(20);
    VDATA VARCHAR(8);
  BEGIN
    -- POSIÃ¿Ã¿O 01 A 19 DO CODIGO DE BARRAS Ã¿ PADRÃ¿O PARA TODOS OS BANCOS
    IF BANCO.NUMBANCO = '6375' THEN
       VS_CODBARRA_TEMP := '033';
    ELSIF BANCO.NUMBANCO = '6111' THEN
       VS_CODBARRA_TEMP := '237';
    ELSE
       /*01 a 03*/ -- NUMERO DO BANCO
       VS_CODBARRA_TEMP := VS_CODBARRA_TEMP || LPAD(BANCO.NUMBANCO, 3, '0');
    END IF;
    /*04 */ -- CODIGO DA MOEDA
    VS_CODBARRA_TEMP := VS_CODBARRA_TEMP || '9';
    /*05 */ -- DV A SER CALCULADO AO FINAL DA COMPOSIÇÃO
    IF PD_DTVENC < TO_DATE('22022025', 'DDMMYYYY') THEN
      VDATA := '07101997';
    ELSE
      VDATA := '29052022';
    END IF
    /*06 a 09*/ -- FATOR VENCIMENTO
    VS_CODBARRA_TEMP := VS_CODBARRA_TEMP || LPAD(PD_DTVENC - TO_DATE(VDATA, 'DDMMYYYY'), 4, '0');

    /*10 a 19*/ -- VALOR DO TITULOS
    IF PS_UTILIZAVALORBRUTO = 'S' THEN
      VS_CODBARRA_TEMP := VS_CODBARRA_TEMP || LPAD(PN_VALOR * 100, 10, '0');
    ELSE
      VS_CODBARRA_TEMP := VS_CODBARRA_TEMP || LPAD(PN_VALORLIQUIDO * 100, 10, '0');
    END IF;

    RETURN VS_CODBARRA_TEMP;
  END;

  --BANCO DO BRASIL ************************************************************
  PROCEDURE F_GERADADOS_BANCO_001(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PB_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_SEM_DV VARCHAR2(30);
    VB_GERADV             BOOLEAN;
    VS_DVCODBARRA         VARCHAR2(1);
    VS_AGENCIA            VARCHAR2(4);
    VS_CONTA              VARCHAR2(8);
    VS_NOVODIGMOD10       VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO DO BRASIL **********************************************
    IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      IF (LENGTH(BANCO.NUMCONVENIO) <= 6) AND (LENGTH(PN_PROXIMONOSSONUMERO) > 5) THEN -- CONVENIO TAMANHO 6
        IF ((BANCO.NUMCARTEIRA = 16) OR (BANCO.NUMCARTEIRA = 18)) AND (BANCO.TIPOCOB = 'NR') THEN
          -- CARTEIRA 16 OU 18 E COBRANÃ¿A NAO REGISTRADA GERA NOSSO NUMERO TAMANHO 17 SEM DV
          VS_NOSSONUMERO := LPAD(PN_PROXIMONOSSONUMERO, 17, '0');
          VB_GERADV := FALSE;
        ELSE
          -- NOSSO NUMERO FORMADO POR CONVENIO TAMANHO 6 SEGUIDO DE PROXNOSSONUMERO TAMANHO 5 E GERA DV
          VS_NOSSONUMERO := LPAD(BANCO.NUMCONVENIO, 6, '0') || LPAD(PN_PROXIMONOSSONUMERO, 5, '0');
          VB_GERADV := TRUE;
        END IF;
      ELSIF (LENGTH(BANCO.NUMCONVENIO) <= 6) THEN
        VS_NOSSONUMERO := LPAD(BANCO.NUMCONVENIO, 6, '0') || LPAD(PN_PROXIMONOSSONUMERO, 5, '0');
        VB_GERADV := TRUE;
      ELSE
        VS_NOSSONUMERO := LPAD(BANCO.NUMCONVENIO, 7, '0') || LPAD(PN_PROXIMONOSSONUMERO, 10, '0');
        VB_GERADV := FALSE;
      END IF;

      VS_NOSSONUMERO_SEM_DV := VS_NOSSONUMERO;

      IF VB_GERADV THEN
        VS_NOSSONUMERO := VS_NOSSONUMERO || '-' || F_CALCULA_MODULO_11(VS_NOSSONUMERO, 9, 'N', VS_NOVODIGMOD10);
      END IF;
    ELSE
      IF LENGTH(TITULOS.NOSSONUMERO) = 17 THEN
        VS_NOSSONUMERO_SEM_DV := NUMEROS(TITULOS.NOSSONUMERO);
      ELSE
        VS_NOSSONUMERO_SEM_DV := REPLACE(TITULOS.NOSSONUMERO, '-', '');
        VS_NOSSONUMERO_SEM_DV := SUBSTR(VS_NOSSONUMERO_SEM_DV, 1, LENGTH(VS_NOSSONUMERO_SEM_DV) - 1);
      END IF;
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO DO BRASIL  *****************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PB_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
     /*20 A 44*/
    IF LENGTH(BANCO.NUMCONVENIO) <= 6 THEN
      IF ((BANCO.NUMCARTEIRA = '16') OR (BANCO.NUMCARTEIRA = '18')) AND (BANCO.TIPOCOB = 'NR') AND (LENGTH(BANCO.PROXNOSSONUMBCO) > 5) THEN
        /*20 A 25*/
        VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCONVENIO, 6, '0');
        /*26 A 42*/
        VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_SEM_DV, 17, '0');
        /*42 A 44*/
        VS_CODBARRA := VS_CODBARRA || '21';
      ELSE
        /*20 A 30*/
        VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_SEM_DV, 11, '0');
        /*31 A 42*/
        VS_AGENCIA := LPAD(SUBSTR(BANCO.AGENCIA, 1, LENGTH(BANCO.AGENCIA) - 1), 4, '0');
        VS_CONTA   := LPAD(SUBSTR(BANCO.CONTA, 1, LENGTH(BANCO.CONTA) - 1), 8, '0');
        VS_CODBARRA := VS_CODBARRA || VS_AGENCIA || VS_CONTA;
        /*43 A 44*/
        VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA, 2, '0');
      END IF;
    ELSE
     /*20 A 25*/
     VS_CODBARRA := VS_CODBARRA || '000000';
     /*26 A 42*/
     VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_SEM_DV, 17, '0');
     /*43 A 44*/
     VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA, 2, '0');
    END IF;

    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  --BANCO BRADESCO *********************************************************************************
  PROCEDURE F_GERADADOS_BANCO_237(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_DV_TEMP          VARCHAR2(1);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO BRADESCO ***********************************************
    IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      VS_NOSSONUMERO      := LPAD(PN_PROXIMONOSSONUMERO, 11, '0');
      VS_DV_TEMP          := F_CALCULA_MODULO_11(BANCO.NUMCARTEIRA || VS_NOSSONUMERO, 7, 'N', VS_NOVODIGMOD10);
      VS_NOSSONUMERO_TEMP := VS_NOSSONUMERO || VS_DV_TEMP;
      VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || VS_DV_TEMP;
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO BRADESCO *******************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /*20 A 23*/
    VS_CODBARRA := VS_CODBARRA || LPAD(NUMEROS(BANCO.AGENCIA), 4, '0');
    /*24 A 25*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA, 2, '0');
    /*28 A 36*/
    VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 11, '0');
    /*37 A 43*/
    VS_CODBARRA := VS_CODBARRA || LPAD(SUBSTR(BANCO.CONTA, 1, LENGTH(BANCO.CONTA) - 1), 7, '0');
    /*44 A 44*/
    VS_CODBARRA := VS_CODBARRA || '0';
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  --BANCO SAFRA ************************************************************************************
  PROCEDURE F_GERADADOS_BANCO_422(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2,
                                  PN_NUMTRANSVENDA      IN NUMBER,
                                  PS_PREST              IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_DV_TEMP          VARCHAR2(1);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
    VN_DUPLIC           PCPREST.DUPLIC%TYPE;
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO SAFRA **************************************************
    IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      VS_NOSSONUMERO      := LPAD(PN_PROXIMONOSSONUMERO, 8, '0');
      VS_DV_TEMP          := F_CALCULA_MODULO_11(VS_NOSSONUMERO, 10, 'N', VS_NOVODIGMOD10);

      VS_NOSSONUMERO_TEMP := VS_NOSSONUMERO || VS_DV_TEMP;
      VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || VS_DV_TEMP;
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************

    SELECT DUPLIC
      INTO VN_DUPLIC
     FROM PCPREST
    WHERE NUMTRANSVENDA = PN_NUMTRANSVENDA
      AND PREST = PS_PREST;
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO SAFRA **********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /* 20 A 20*/
    VS_CODBARRA := VS_CODBARRA || '7';

    IF BANCO.TIPOCOB = 'R' THEN
      /*21 A 25*/
      VS_CODBARRA := VS_CODBARRA || LPAD(NUMEROS(BANCO.AGENCIA), 5, '0');
      /*26 A 34*/
      VS_CODBARRA := VS_CODBARRA || LPAD(SUBSTR(BANCO.CONTA, 1, LENGTH(BANCO.CONTA)), 9, '0');
      /*35 A 43*/
      VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 9, '0');
      /* 44 A 44*/
      VS_CODBARRA := VS_CODBARRA || '2';
    ELSE
      /*21 A 26*/
      VS_CODBARRA := VS_CODBARRA || LPAD(SUBSTR(BANCO.CODCLIENTENOBANCO, 1, 6), 6, '0');
      /*27 A 43*/
      VS_CODBARRA := VS_CODBARRA || LPAD(VN_DUPLIC || PS_PREST, 17, '0');
      /* 44 A 44*/
      VS_CODBARRA := VS_CODBARRA || '4';
    END IF;

    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  --BANCO SANTANDER *********************************************************************************
  PROCEDURE F_GERADADOS_BANCO_033(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_CODBARRA_TEMP    VARCHAR2(44);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO SANTANDER **********************************************
    IF (BANCO.TIPOCOB <> 'NS') AND (BANCO.NUMBANCO <> '6375') THEN
      VS_NOSSONUMERO      := LPAD(PN_PROXIMONOSSONUMERO, 7, '0');
      VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || F_CALCULA_MODULO_11(VS_NOSSONUMERO, 9, 'N', VS_NOVODIGMOD10);

      IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
        VS_NOSSONUMERO_TEMP := NUMEROS(VS_NOSSONUMERO);
      ELSE
        VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
      END IF;
    ELSE
      IF BANCO.NUMBANCO = '6375' THEN
        IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
          VS_NOSSONUMERO      := LPAD(PN_PROXIMONOSSONUMERO, 12, '0');
          VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || F_CALCULA_MODULO_11_6375(VS_NOSSONUMERO);
        ELSE
          VS_NOSSONUMERO      := TITULOS.NOSSONUMERO;
        END IF;
      ELSE
        VS_NOSSONUMERO      := LPAD(BANCO.AGENCIA, 3, '0') || LPAD(PN_PROXIMONOSSONUMERO, 7, '0');
        VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || F_CALCULA_MODULO_10(VS_NOSSONUMERO, 0, 'N');
      END IF;

      IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
        VS_NOSSONUMERO_TEMP := LPAD(PN_PROXIMONOSSONUMERO, 7, '0');
      ELSE
        VS_NOSSONUMERO_TEMP := NUMEROS(SUBSTR(TITULOS.NOSSONUMERO, 4, LENGTH(TITULOS.NOSSONUMERO)));
      END IF;
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO SANTANDER*******************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    IF (BANCO.TIPOCOB <> 'NS') THEN
      /*20 A 20*/
      VS_CODBARRA := VS_CODBARRA || '9';
      /*21 A 27*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.CODCLIENTENOBANCO, 7, '0');
      /*28 A 36*/
      IF BANCO.NUMBANCO = '6375' THEN
         VS_CODBARRA := VS_CODBARRA || LPAD(NUMEROS(VS_NOSSONUMERO), 13, '0');
      ELSE
         VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 13, '0');
    END IF;
      /*41 A 41*/
      VS_CODBARRA := VS_CODBARRA || '0';
      /*42 A 44*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA3, 3, '0');
    ELSE
      VS_CODBARRA_TEMP := LPAD(BANCO.CODCLIENTENOBANCO, 11, '0') ||
                          LPAD(VS_NOSSONUMERO_TEMP, 7, '0') ||
                          '00033';
      /*20 A 43*/
      VS_CODBARRA := VS_CODBARRA || VS_CODBARRA_TEMP;
      VS_CODBARRA_TEMP := VS_CODBARRA_TEMP || F_CALCULA_MODULO_10(VS_CODBARRA_TEMP, 1, 'DV1');
      /*44 A 44*/
      VS_CODBARRA := VS_CODBARRA || F_CALCULA_MODULO_10_DV2_033(VS_CODBARRA_TEMP, 7);
    END IF;

    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  --BANCO ITAU *************************************************************************************
  PROCEDURE F_GERADADOS_BANCO_341(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_CODBARRA_TEMP    VARCHAR2(44);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_CONTA_SEM_DV     VARCHAR2(10);
    VS_DV_NOSSONUMERO   VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO ITAU ***************************************************
     IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      VS_NOSSONUMERO      := LPAD(PN_PROXIMONOSSONUMERO, 8, '0');
      VS_CONTA_SEM_DV     := SUBSTR(BANCO.CONTA, 1, LENGTH(BANCO.CONTA) - 1);
      VS_DV_NOSSONUMERO   := F_CALCULA_MODULO_10(BANCO.AGENCIA || VS_CONTA_SEM_DV || BANCO.NUMCARTEIRA3 || VS_NOSSONUMERO, 2, 'N');
      VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || VS_DV_NOSSONUMERO;
      VS_NOSSONUMERO_TEMP := NUMEROS(VS_NOSSONUMERO);
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO ITAU ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /*20 A 22*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA3, 3, '0');
    /*23 A 30*/
    VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 9, '0');
    /*32 A 35*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.AGENCIA, 4, '0');
    /*36 A 41*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.CONTA, 6, '0');
    /*42 A 44*/
    VS_CODBARRA := VS_CODBARRA || '000';
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  PROCEDURE F_GERADADOS_BANCO_748(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_DV_NOSSONUMERO   VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO SICRED ***************************************************
     IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      -- CÃLCULO DO DV
      VS_DV_NOSSONUMERO   := F_CALCULA_MODULO_11(LPAD(BANCO.AGENCIA, 4,'0') ||
                                                 LPAD(BANCO.NUMCARTEIRA3, 2, '0') ||
                                                 LPAD(BANCO.CODCLIENTENOBANCO, 5, '0') ||
                                                 TO_CHAR(SYSDATE, 'YY') ||
                                                 SUBSTR(BANCO.NUMCARTEIRA, 1, 1) ||
                                                 LPAD(PN_PROXIMONOSSONUMERO, 5, '0'),
                                                 9, 'N', VS_NOVODIGMOD10);
      -- MONTAGEM DO NOSSO NÃ¿MERO
      VS_NOSSONUMERO      := TO_CHAR(SYSDATE, 'YY') || SUBSTR(BANCO.NUMCARTEIRA, 1, 1) || LPAD(PN_PROXIMONOSSONUMERO, 5, '0') || VS_DV_NOSSONUMERO;
      -- NOSSO NÃ¿MERO SEM CARACTERES ESPECIAIS PARA SER UTILIZADO NO CODIGO DE BARRAS
      VS_NOSSONUMERO_TEMP := NUMEROS(VS_NOSSONUMERO);
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO SICRED ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /*20 A 20*/
    IF BANCO.TIPOCOB = 'R' THEN
      VS_CODBARRA := VS_CODBARRA || '1';
    ELSE
      VS_CODBARRA := VS_CODBARRA || '3';
    END IF;
    /*21 A 21*/
    VS_CODBARRA := VS_CODBARRA || '1';
    /*22 A 30*/
    VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 9, 0);
    /*31 A 34*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.AGENCIA, 4, '0');
    /*35 A 36*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA3, 2, '0');
    /*37 A 41*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.CODCLIENTENOBANCO, 5, '0');
    /*42 A 42*/
    VS_CODBARRA := VS_CODBARRA || '1';
    /*43 A 43*/
    VS_CODBARRA := VS_CODBARRA || '0';
    /*44 A 44*/
    VS_CODBARRA := VS_CODBARRA || F_CALCULA_MODULO_11(SUBSTR(VS_CODBARRA, 19, 24), 9, 'N', VS_NOVODIGMOD10); -- A POSIÃ¿Ã¿O 44 Ã¿ UM DV CALCULADO COM A PARTE LIVRE DO CODIGO DE BARRAS
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  PROCEDURE F_GERADADOS_BANCO_756(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PS_PREST              IN VARCHAR2,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_VALORNOSSONUMERO VARCHAR2(30);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_DV_NOSSONUMERO   VARCHAR2(3);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      -- CÃLCULO DO DV
      VS_DV_NOSSONUMERO   := F_CALCULA_MODULO_11(LPAD(BANCO.AGENCIA, 4,'0') ||
                                                 LPAD(BANCO.CODCLIENTENOBANCO, 10, '0') ||
                                                 LPAD(PN_PROXIMONOSSONUMERO, 7, '0'),
                                                 7, 'N', VS_NOVODIGMOD10);
      VS_NOSSONUMERO     := LPAD(PN_PROXIMONOSSONUMERO, 7, '0');
      -- MONTAGEM DO NOSSO NÃ¿MERO
      VS_VALORNOSSONUMERO := VS_NOSSONUMERO || VS_DV_NOSSONUMERO;
      VS_NOSSONUMERO      := VS_NOSSONUMERO ||'-'|| VS_DV_NOSSONUMERO;
      VS_NOSSONUMERO_TEMP := NUMEROS(VS_NOSSONUMERO);
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO COBB ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /*20 A 20*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA, 1, '0');
    /*21 A 24*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.AGENCIA, 4, '0');
    /*25 A 26*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA3, 2, '0');
    /*27 A 33*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.CODCLIENTENOBANCO, 7, '0');
    /*34 A 41*/
    VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_VALORNOSSONUMERO, 1, 8);
    /*42 A 44*/
    VS_CODBARRA := VS_CODBARRA || LPAD(PS_PREST, 3, '0');
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  PROCEDURE F_GERADADOS_BANCO_399(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_CODBARRA_TEMP    VARCHAR2(44);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_DV_NOSSONUMERO   VARCHAR2(3);
    VS_DV_NOSSONUMERO1  VARCHAR2(1);
    VS_DV_NOSSONUMERO2  VARCHAR2(1);
    VS_DV_NOSSONUMERO3  VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO HSBC ***************************************************
    IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      IF BANCO.TIPOCOB = 'NR' THEN
        VS_NOSSONUMERO     := LPAD(PN_PROXIMONOSSONUMERO, 13, '0');
        VS_DV_NOSSONUMERO1 := F_CALCULA_MODULO_11(VS_NOSSONUMERO, 7, 'N', VS_NOVODIGMOD10); -- MODULO 11 NA BASE 7
        VS_DV_NOSSONUMERO2 := '4';
        VS_DV_NOSSONUMERO3 := F_CALCULA_MODULO_11((TO_NUMBER(VS_NOSSONUMERO) ||
                                                   TO_NUMBER(VS_DV_NOSSONUMERO1) ||
                                                   TO_NUMBER(VS_DV_NOSSONUMERO2)) +
                                                  TO_NUMBER(TO_CHAR(PD_DTVENC, 'DDMMYY')) +
                                                  BANCO.CODCLIENTENOBANCO, 7, 'N', VS_NOVODIGMOD10); -- MODULO 11 NA BASE 7
        VS_DV_NOSSONUMERO  := VS_DV_NOSSONUMERO1 || VS_DV_NOSSONUMERO2 || VS_DV_NOSSONUMERO3;
      ELSIF BANCO.TIPOCOB = 'NS' THEN
        VS_NOSSONUMERO     := LPAD(PN_PROXIMONOSSONUMERO, 13, '0');
        VS_DV_NOSSONUMERO1 := F_CALCULA_MODULO_11(VS_NOSSONUMERO, 7, 'N', VS_NOVODIGMOD10); -- MODULO 11 NA BASE 7
        VS_DV_NOSSONUMERO2 := '5';
        VS_DV_NOSSONUMERO3 := F_CALCULA_MODULO_11((TO_NUMBER(VS_NOSSONUMERO) ||
                                                   TO_NUMBER(VS_DV_NOSSONUMERO1) ||
                                                   TO_NUMBER(VS_DV_NOSSONUMERO2)) +
                                                  TO_NUMBER(TO_CHAR(PD_DTVENC, 'DDMMYY')) +
                                                  BANCO.CODCLIENTENOBANCO, 7, 'N', VS_NOVODIGMOD10); -- MODULO 11 NA BASE 7
        VS_DV_NOSSONUMERO  := VS_DV_NOSSONUMERO1 || VS_DV_NOSSONUMERO2 || VS_DV_NOSSONUMERO3;
      ELSE
        VS_NOSSONUMERO    := LPAD(BANCO.NUMCONVENIO, 5, '0') || LPAD(PN_PROXIMONOSSONUMERO, 5, '0');
        VS_DV_NOSSONUMERO := F_CALCULA_MODULO_11(VS_NOSSONUMERO, 7, 'N', VS_NOVODIGMOD10);
      END IF;

      VS_NOSSONUMERO := VS_NOSSONUMERO || VS_DV_NOSSONUMERO;
      VS_NOSSONUMERO_TEMP := NUMEROS(VS_NOSSONUMERO);
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO HSBC ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);

    IF (BANCO.TIPOCOB = 'NR') OR (BANCO.TIPOCOB = 'NS') THEN
      /*20 A 26*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.CODCLIENTENOBANCO, 7, '0');
      /*27 A 39*/
      VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 13, 0);
      /*40 A 43*/ -- DATA NO CALENDÃRIO JULIANO
      VS_CODBARRA := VS_CODBARRA || LPAD( (PD_DTVENC - (TO_DATE('1/JAN/' || TO_CHAR(SYSDATE, 'YYYY'))) + 1) || TO_CHAR(SYSDATE, 'Y'), 4, '0');
      /*44 A 44*/
      VS_CODBARRA := VS_CODBARRA || '2';
    ELSE
      /*20 A 30*/
      VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 11, '0');
      /*31 A 34*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.AGENCIA, 4, 0);
      /*35 A 41*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.CONTA, 7, '0');
      /*42 A 43*/
      VS_CODBARRA := VS_CODBARRA || '00';
      /*44 A 44*/
      VS_CODBARRA := VS_CODBARRA || '1';
    END IF;

    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  PROCEDURE F_GERADADOS_BANCO_041(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_DV_1             VARCHAR2(1);
    VS_DV_2             VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANRISUL ***************************************************
     IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      -- CÃLCULO DO DV_1
      VS_DV_1   := F_CALCULA_MODULO_10(LPAD(PN_PROXIMONOSSONUMERO, 8, '0'), 2, 'N');
      -- INICIO DA MONTAGEM DO NOSSO NUMERO
      VS_NOSSONUMERO := LPAD(PN_PROXIMONOSSONUMERO, 8, '0') || VS_DV_1;
      -- CÃLCULO DO DV_2
      VS_DV_2 := F_CALCULA_MODULO_11(VS_NOSSONUMERO, 7, 'N', VS_NOVODIGMOD10);
      -- MONTAGEM DO NOSSO NÃ¿MERO
      IF (VS_NOVODIGMOD10 = '') or (VS_NOVODIGMOD10 IS NULL) THEN
        VS_NOSSONUMERO := VS_NOSSONUMERO || VS_DV_2;
      ELSE
        VS_NOSSONUMERO := SUBSTR(VS_NOSSONUMERO, 1, LENGTH(VS_NOSSONUMERO) - 1) || VS_NOVODIGMOD10 || VS_DV_2;
      END IF;
      -- NOSSO NÃ¿MERO SEM DV PARA SER UTILIZADO NO CODIGO DE BARRAS
      VS_NOSSONUMERO_TEMP :=  LPAD(PN_PROXIMONOSSONUMERO, 8, '0');
    ELSE
      VS_NOSSONUMERO_TEMP := SUBSTR(NUMEROS(TITULOS.NOSSONUMERO), 1, LENGTH(NUMEROS(TITULOS.NOSSONUMERO)) - 1);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANRISUL ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_NOVODIGMOD10 := '';

    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /*20 A 20*/
    VS_CODBARRA := VS_CODBARRA || '2';
    /*21 A 21*/
    VS_CODBARRA := VS_CODBARRA || '1';
    /*22 A 25*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.AGENCIA, 4, 0);
    /*26 A 32*/
    VS_CODBARRA := VS_CODBARRA || SUBSTR(BANCO.CODCLIENTENOBANCO, 1, 7);
    /*33 A 40*/
    VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 8, '0');
    /*41 A 42*/
    VS_CODBARRA := VS_CODBARRA || '40';
    /*43 A 43*/
    VS_DV_1 := F_CALCULA_MODULO_10(SUBSTR(VS_CODBARRA, 19, 24), 2, 'N');
    VS_CODBARRA := VS_CODBARRA || VS_DV_1;
    /*44 A 44*/
    VS_DV_2 := F_CALCULA_MODULO_11(SUBSTR(VS_CODBARRA, 19, 24), 7, 'N', VS_NOVODIGMOD10);
    --VS_CODBARRA := VS_CODBARRA || VS_DV_2;
    -- MONTAGEM DO NOSSO NÃ¿MERO
    IF (VS_NOVODIGMOD10 = '') or (VS_NOVODIGMOD10 IS NULL) THEN
      VS_CODBARRA := VS_CODBARRA || VS_DV_2;
    ELSE
      VS_CODBARRA := SUBSTR(VS_CODBARRA, 1, LENGTH(VS_CODBARRA) - 1) || VS_NOVODIGMOD10 || VS_DV_2;
    END IF;
    /* CALCULO DV DO CODIGO DE BARRAS */
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;

  PROCEDURE F_GERADADOS_BANCO_104(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_DV               VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA A CEF ***************************************************
     IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      -- INICIO DA MONTAGEM DO NOSSO NUMERO
      CASE BANCO.TIPOCOB
        WHEN 'NR' THEN
          VS_NOSSONUMERO := '80' || LPAD(PN_PROXIMONOSSONUMERO, 8, '0');
        WHEN 'CR' THEN
          VS_NOSSONUMERO := '82' || LPAD(PN_PROXIMONOSSONUMERO, 8, '0');
        WHEN 'R' THEN
          VS_NOSSONUMERO := '9' || LPAD(PN_PROXIMONOSSONUMERO, 9, '0');
        WHEN 'NS' THEN
          VS_NOSSONUMERO := '9' || LPAD(PN_PROXIMONOSSONUMERO, 17, '0');
        ELSE
          IF (BANCO.TIPOCOB = 'SR') THEN
          BEGIN
            --HIS.01245.2017 NOSSONUMBCO COM 17 AO INVES DE 18 DIGITOS
            IF (BANCO.NOSSONUMBCO17DIGCOBCEFSIGCBREG = 'S') THEN
              VS_NOSSONUMERO := '14' || LPAD(PN_PROXIMONOSSONUMERO, 14, '0');
            ELSE
              VS_NOSSONUMERO := '14' || LPAD(PN_PROXIMONOSSONUMERO, 15, '0');
            END IF;
          END;
          ELSE
            VS_NOSSONUMERO := '24' || LPAD(PN_PROXIMONOSSONUMERO, 15, '0');
          END IF;
      END CASE;

      VS_DV := F_CALCULA_MODULO_11(VS_NOSSONUMERO, 10, 'N', VS_NOVODIGMOD10);
      VS_NOSSONUMERO_TEMP := VS_NOSSONUMERO;
      VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || VS_DV;
    ELSE
      VS_NOSSONUMERO_TEMP := SUBSTR(NUMEROS(TITULOS.NOSSONUMERO), 1, LENGTH(NUMEROS(TITULOS.NOSSONUMERO)) - 1);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA A CEF ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    IF (BANCO.TIPOCOB = 'NS') THEN
      /*20 A 20*/
      VS_CODBARRA := VS_CODBARRA || '1';
      /*21 A 26*/
      VS_CODBARRA := VS_CODBARRA || LPAD(NUMEROS(SUBSTR(BANCO.CODCEDENTE, 1, 6)), 6, '0');
      /*27 A 44*/
      VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 18, '0');
    ELSIF (BANCO.TIPOCOB = 'R') OR (BANCO.TIPOCOB = 'NR') OR (BANCO.TIPOCOB = 'CR') THEN
      /*20 A 29*/
      VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 10, '0');
      /*30 A 33*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.AGENCIA, 4, '0');
      /*34 A 36*/
      VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCARTEIRA3, 3, '0');
      /*37 A 44*/
      VS_CODBARRA := VS_CODBARRA || LPAD(NUMEROS(SUBSTR(BANCO.CODCEDENTE, 1, 8)), 8, '0');
    ELSIF (BANCO.TIPOCOB = 'SR') OR (BANCO.TIPOCOB = 'SN') THEN
      /*20 A 25*/
      VS_CODBARRA := VS_CODBARRA || LPAD(NUMEROS(SUBSTR(BANCO.CODCEDENTE, 1, 6)), 6, '0');
      /*26 A 26*/
      VS_CODBARRA := VS_CODBARRA || F_CALCULA_MODULO_11(LPAD(NUMEROS(SUBSTR(BANCO.CODCEDENTE, 1, 6)), 6, '0'), 10, 'N', VS_NOVODIGMOD10);
      /*27 A 29*/
      VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_NOSSONUMERO_TEMP, 3, 3);
      /*30 A 30*/
      VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_NOSSONUMERO_TEMP, 1, 1);
      /*31 A 33*/
      VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_NOSSONUMERO_TEMP, 6, 3);
      /*34 A 34*/
      VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_NOSSONUMERO_TEMP, 2, 1);
      /*35 A 43*/
      --HIS.01245.2017 NOSSONUMBCO COM 17 AO INVES DE 18 DIGITOS
      IF (BANCO.NOSSONUMBCO17DIGCOBCEFSIGCBREG = 'S') THEN
        VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_NOSSONUMERO_TEMP, 8, 9);
      ELSE
        VS_CODBARRA := VS_CODBARRA || SUBSTR(VS_NOSSONUMERO_TEMP, 9, 9);
      END IF;
      /*44 A 44*/
      VS_CODBARRA := VS_CODBARRA || F_CALCULA_MODULO_11(SUBSTR(VS_CODBARRA, 19, 26), 10, 'N', VS_NOVODIGMOD10);
    END IF;
    /* CALCULO DV DO CODIGO DE BARRAS */
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;
  
  PROCEDURE F_GERADADOS_BANCO_655(PN_CODBANCO           IN NUMBER,
                                  PN_VALOR              IN NUMBER,
                                  PN_VALORLIQUIDO       IN NUMBER,
                                  PD_DTVENC             IN DATE,
                                  PN_PROXIMONOSSONUMERO IN NUMBER,
                                  PS_UTILIZAVALORBRUTO  IN VARCHAR2,
                                  PS_PRIMEIRAIMPRESSAO  IN VARCHAR2) IS
    VS_NOSSONUMERO_TEMP VARCHAR2(30);
    VS_CODBARRA_TEMP    VARCHAR2(44);
    VS_DVCODBARRA       VARCHAR2(1);
    VS_CONTA_SEM_DV     VARCHAR2(10);
    VS_DV_NOSSONUMERO   VARCHAR2(1);
    VS_NOVODIGMOD10     VARCHAR2(1);
  BEGIN
    -- GERAÃ¿Ã¿O DO NOSSO NÃ¿MERO PARA O BANCO ITAU ***************************************************
     IF PS_PRIMEIRAIMPRESSAO = 'S' THEN
      VS_NOSSONUMERO      := LPAD(PN_PROXIMONOSSONUMERO, 9, '0');
      VS_CONTA_SEM_DV     := SUBSTR(BANCO.CONTA, 1, LENGTH(BANCO.CONTA) - 1);
      VS_DV_NOSSONUMERO   := F_CALCULA_MODULO_10(BANCO.AGENCIA || VS_CONTA_SEM_DV || BANCO.NUMCARTEIRA3 || VS_NOSSONUMERO, 2, 'N');
      VS_NOSSONUMERO      := VS_NOSSONUMERO || '-' || VS_DV_NOSSONUMERO;
      VS_NOSSONUMERO_TEMP := NUMEROS(VS_NOSSONUMERO);
    ELSE
      VS_NOSSONUMERO_TEMP := NUMEROS(TITULOS.NOSSONUMERO);
    END IF;
    --**********************************************************************************************
    -- GERAÃ¿Ã¿O DO CODIGO DE BARRAS PARA O BANCO ITAU ***********************************************
    /*01 A 19*/ -- INICIO PADRAO COD BARRAS
    VS_CODBARRA := F_MONTA_INICIO_CODBARRAS(PN_VALOR,
                                            PN_VALORLIQUIDO,
                                            PS_UTILIZAVALORBRUTO,
                                            PD_DTVENC);
    /*20 A 29*/
    VS_CODBARRA := VS_CODBARRA || LPAD(BANCO.NUMCONVENIO, 10, '0');
    /*30 A 32*/
    VS_CODBARRA := VS_CODBARRA || '500';
    /*33 A 42*/
    VS_CODBARRA := VS_CODBARRA || LPAD(VS_NOSSONUMERO_TEMP, 10, '0');
    /*43 A 44*/
    VS_CODBARRA := VS_CODBARRA || '00';
    VS_DVCODBARRA := F_CALCULA_MODULO_11(VS_CODBARRA, 9, 'C', VS_NOVODIGMOD10);
    VS_CODBARRA   := SUBSTR(VS_CODBARRA, 1, 4) || VS_DVCODBARRA || SUBSTR(VS_CODBARRA, 5, 39);
    --**********************************************************************************************
  END;
  
  --BUSCA TÃTULO(S) PARA FAZER GERAÃ¿Ã¿O *************************************************************
  PROCEDURE P_GERADADOSBANCARIOS(PS_CODFILIAL         IN VARCHAR2,
                                 PS_CODCOBRANCA       IN VARCHAR2,
                                 PN_CODBANCO          IN NUMBER,
                                 PN_NUMTRANSVENDA     IN NUMBER,
                                 PN_NUMDIASPROTESTO   IN NUMBER,
                                 PS_PREST             IN VARCHAR2,
                                 PS_FILIALVIRTUAL     IN VARCHAR2 DEFAULT 'N',
                                 PS_UTILIZAVALORBRUTO IN VARCHAR2 DEFAULT 'N',
                                 PS_PRIMEIRAIMPRESSAO IN VARCHAR2 DEFAULT 'S',
                                 PS_SOMACUSTOCARTORIO IN NUMBER DEFAULT 0) IS
    VN_VALORCODBARRA      NUMBER;
    VN_PROXIMONOSSONUMERO NUMBER;
    VN_NUMTRANSVENDA_DUP NUMBER;
    VS_PREST_DUP VARCHAR2(8);
    VN_DUPLIC_DUP NUMBER;
    VS_NOSSONUMBCO_DUP VARCHAR2(30);
    VN_VLTXCOBRANCACARTORIO NUMBER;
    VN_VLCARTORIONOTIFIC NUMBER;
    CURSOR_TITULOS SYS_REFCURSOR;
  BEGIN
    VN_PROXIMONOSSONUMERO := 0;

    IF ((PS_PREST IS NULL) OR (PS_PREST = '')) THEN
      -- NAO DEVE CONTINUAR Pois o nosso nÃºmero Ã© gerado no inÃ­cio da chamada do mÃ©todo, entÃ£o deverÃ¡ ser gerado prest a prest.
      RAISE_APPLICATION_ERROR(-20101, 'NÃ£o foi informado o nÃºmero da PREST e Ã© obrigatÃ³rio informar a PREST para geraÃ§Ã£o dos dados bancÃ¡rios na PKG_DADOSBANCARIOS');
    END IF;

    IF (PS_PRIMEIRAIMPRESSAO = 'S') THEN
      VN_PROXIMONOSSONUMERO := F_LERPROXIMONOSSONUMERO(PN_CODBANCO, VS_MSGERROGERANOSSONUMERO);
    ELSE
      -- SETA DADOS DO BANCO - TEM ESSE MESMO SELECT DENTRO DO MÃ¿TODO "F_LERPROXIMONOSSONUMERO" PORÃ¿M LÃ TEM UM FOR UPDATE.
      -- E ASSIM QUE PEGA O PRÃ¿XIMO NOSSO NÃ¿MERO JÃ LIBERA A TABELA PCBANCO.
      SELECT NUMBANCO,
             PROXNOSSONUMBCO,
             NUMCONVENIO,
             NUMCARTEIRA,
             TIPOCOB,
             FAIXAINI,
             FAIXAFIM,
             REGEXP_REPLACE(UPPER(AGENCIA), '[^A-Z|0-9]'),
             REGEXP_REPLACE(UPPER(CONTA), '[^A-Z|0-9]'),
             NVL(CODCLIENTENOBANCO, '0'),
             NVL(CODCEDENTE, '0'),
             NVL(NUMCARTEIRA3, '0'),
             NVL(NOSSONUMBCO17DIGCOBCEFSIGCBREG,'N')
      INTO BANCO
      FROM PCBANCO
      WHERE CODBANCO = PN_CODBANCO;
    END IF;

    V_SQL := '';
    V_SQL := 'SELECT PCPREST.CODFILIAL,
                     PCCLIENT.CODCLI,
                     PCPREST.NUMTRANSVENDA,
                     PCPREST.DUPLIC,
                     PCPREST.PREST,
                     NVL(PCPREST.DTDESC, PCPREST.DTVENC) DTDESCONTO,
                     PCPREST.VALOR,
                     NVL(PCPREST.VALORDESC,0),
                     NVL(PCPREST.VALOR, 0) + (CASE
                                                WHEN NVL(PCPREST.TXVENDORCLI, 0) <= 0 THEN
                                                 0
                                                ELSE
                                                 NVL(PCPREST.VLTXVENDOR, 0) + NVL(PCPREST.VLTXIOF, 0)
                                              END) + NVL(PCPREST.TXPERMPREVISTO, 0)
                                           + (CASE
                                                WHEN PCPREST.DTRECEBIMENTOPREVISTO IS NOT NULL THEN
                                                  NVL(PCPREST.VLROUTROSACRESC, 0)
                                                ELSE
                                                  0
                                              END)
                                           + (CASE
                                                WHEN NVL(PCPREST.SOMATXBOLETO, ''N'') = ''S'' THEN
                                                  NVL(PCPREST.VLTXBOLETO, 0)
                                                ELSE
                                                  0
                                              END)
                     AS VALOR_TEMP,
                     CASE
                       WHEN NVL(PCPREST.TXVENDORCLI, 0) <= 0 THEN
                        0
                       ELSE
                        NVL(PCPREST.VLTXVENDOR, 0)
                     END AS VLTXVENDOR,
                     NVL(PCPREST.VLTXIOF, 0) AS VLTXIOF,
                     CASE
                        WHEN NVL(PCPREST.DTRECEBIMENTOPREVISTO,PCPREST.DTVENC) <= PCPREST.DTVENC THEN
                           PCPREST.DTVENC
                        ELSE
                           PCPREST.DTRECEBIMENTOPREVISTO
                     END AS DTVENC,
                     NVL(PCPREST.VLDEVOL, 0) VLDEVOL,
                     (PCPREST.VALOR + NVL(PCPREST.VLDEVOL, 0)) AS VALORBRUTO,
                     NVL(PCPREST.VLTXBOLETO, 0) VLTXBOLETO,
                     PCPREST.NOSSONUMBCO,
                     PCCLIENT.CLIENTE
                FROM PCPREST, PCFILIAL, PCCLIENT, PCUSUARI, PCPLPAG, PCNFSAID, PCCONSUM
               WHERE PCPREST.CODUSUR = PCUSUARI.CODUSUR
                 AND PCFILIAL.CODIGO = PCPREST.CODFILIAL
                 AND PCNFSAID.NUMTRANSVENDA(+) = PCPREST.NUMTRANSVENDA
                 AND PCCLIENT.CODCLI = (SELECT DECODE(E.USABKCNPJCODCLIPRINC, ''S'', NVL(E.CODCLIPRINC, E.CODCLI), E.CODCLI)
                                        FROM PCCLIENT E
                                        WHERE E.CODCLI = PCPREST.CODCLI)
                 AND PCPREST.ORIGEMBOLETO IS NULL
                 AND NVL(PCPREST.AGRUPADO, ''N'') <> ''S''
                 AND PCPREST.DTPAG IS NULL
                 AND PCPREST.VALOR > 0
                 AND PCCLIENT.CODPLPAG = PCPLPAG.CODPLPAG(+)
                 AND PCPREST.CODCOB = :PCODCOB
                 AND ((PCPREST.CODBANCOCM = :PCODBANCO) OR (NVL(PCPREST.CODBANCOCM,0) = 0 )) ';

    IF ((PS_CODFILIAL IS NOT NULL) AND (PS_CODFILIAL <> '99')) THEN
       IF PS_FILIALVIRTUAL = 'S' THEN
          V_SQL :=  V_SQL || ' AND NVL(PCPREST.CODFILIALNF, PCPREST.CODFILIAL) = ''' || PS_CODFILIAL || '''';
       ELSE
          V_SQL :=  V_SQL || ' AND PCPREST.CODFILIAL = ''' || PS_CODFILIAL || '''';
       END IF;
    END IF;

    IF ((PN_NUMTRANSVENDA IS NOT NULL) OR (PN_NUMTRANSVENDA <> 0)) THEN
       V_SQL := V_SQL || ' AND PCPREST.NUMTRANSVENDA = ' || PN_NUMTRANSVENDA;
    END IF;

    IF ((PS_PREST IS NOT NULL) OR (PS_PREST <> '')) THEN
       V_SQL := V_SQL || ' AND PCPREST.PREST = ''' || PS_PREST || '''';
    END IF;

    OPEN CURSOR_TITULOS FOR V_SQL USING PS_CODCOBRANCA, PN_CODBANCO;
    LOOP
      FETCH CURSOR_TITULOS INTO TITULOS;
      EXIT WHEN CURSOR_TITULOS%NOTFOUND;

      IF (VS_MSGERROGERANOSSONUMERO <> '')  OR (VS_MSGERROGERANOSSONUMERO IS NOT NULL) THEN
        -- NULL;
        -- NAO DEVE CONTINUAR
        RAISE_APPLICATION_ERROR(-20101, VS_MSGERROGERANOSSONUMERO);
      END IF;

      IF PS_SOMACUSTOCARTORIO = 1 THEN
        BEGIN
          SELECT TXCOBRANCA, VLCARTORIONOTIFICACAO
          INTO VN_VLTXCOBRANCACARTORIO , VN_VLCARTORIONOTIFIC
          FROM PCINTEGRACAOTGI
          WHERE PCINTEGRACAOTGI.CODFILIAL = TITULOS.CODFILIAL
            AND PCINTEGRACAOTGI.CODBANCO = PN_CODBANCO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
             VN_VLTXCOBRANCACARTORIO := 0;
             VN_VLCARTORIONOTIFIC    := 0;
        END;

        TITULOS.VALOR_TEMP := TITULOS.VALOR_TEMP + VN_VLTXCOBRANCACARTORIO + VN_VLCARTORIONOTIFIC;
      END IF;

      CASE BANCO.NUMBANCO
        WHEN   1 THEN F_GERADADOS_BANCO_001(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN  33 THEN F_GERADADOS_BANCO_033(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN 237 THEN F_GERADADOS_BANCO_237(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN 341 THEN F_GERADADOS_BANCO_341(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN 748 THEN F_GERADADOS_BANCO_748(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);

        WHEN 399 THEN F_GERADADOS_BANCO_399(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN  41 THEN F_GERADADOS_BANCO_041(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN 104 THEN F_GERADADOS_BANCO_104(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN 756 THEN F_GERADADOS_BANCO_756(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            TITULOS.PREST,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);
        WHEN 422 THEN F_GERADADOS_BANCO_422(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO,
                                            PN_NUMTRANSVENDA,
                                            PS_PREST);
        WHEN  6375 THEN F_GERADADOS_BANCO_033(PN_CODBANCO,
                                              TITULOS.VALOR_TEMP,
                                              TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                              TITULOS.DTVENC,
                                              VN_PROXIMONOSSONUMERO,
                                              PS_UTILIZAVALORBRUTO,
                                              PS_PRIMEIRAIMPRESSAO);
        WHEN 6111 THEN F_GERADADOS_BANCO_237(PN_CODBANCO,
                                             TITULOS.VALOR_TEMP,
                                             TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                             TITULOS.DTVENC,
                                             VN_PROXIMONOSSONUMERO,
                                             PS_UTILIZAVALORBRUTO,
                                             PS_PRIMEIRAIMPRESSAO);
        WHEN 655 THEN F_GERADADOS_BANCO_655(PN_CODBANCO,
                                            TITULOS.VALOR_TEMP,
                                            TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                            TITULOS.DTVENC,
                                            VN_PROXIMONOSSONUMERO,
                                            PS_UTILIZAVALORBRUTO,
                                            PS_PRIMEIRAIMPRESSAO);                                     
        ELSE
            RAISE_APPLICATION_ERROR(-20101, 'Banco nÃ£o homolagado!');
      END CASE;

      VS_LINHADIGITAVEL := F_GERALINHADIGITAVEL(VS_CODBARRA,
                                                TITULOS.VALOR_TEMP,
                                                TITULOS.VALOR_TEMP - TITULOS.VALORDESC,
                                                PS_UTILIZAVALORBRUTO);

      IF (VS_MSGERROGERANOSSONUMERO = '') OR (VS_MSGERROGERANOSSONUMERO IS NULL)THEN
        BEGIN
          SELECT NUMTRANSVENDA, PREST, DUPLIC, NOSSONUMBCO
          INTO VN_NUMTRANSVENDA_DUP, VS_PREST_DUP, VN_DUPLIC_DUP, VS_NOSSONUMBCO_DUP
          FROM PCPREST
          WHERE PCPREST.NOSSONUMBCO = VS_NOSSONUMERO
            AND PCPREST.CODBANCOCM = PN_CODBANCO
            AND PCPREST.DTPAG IS NULL
            AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            VN_NUMTRANSVENDA_DUP := '';
            VS_PREST_DUP         := '';
            VN_DUPLIC_DUP        := '';
            VS_NOSSONUMBCO_DUP   := '';
        END;

        IF (VS_NOSSONUMBCO_DUP IS NOT NULL) AND (PS_PRIMEIRAIMPRESSAO = 'S') THEN
          P_GERADADOSBANCARIOS(PS_CODFILIAL,
                               PS_CODCOBRANCA,
                               PN_CODBANCO,
                               PN_NUMTRANSVENDA,
                               PN_NUMDIASPROTESTO,
                               PS_PREST,
                               PS_FILIALVIRTUAL,
                               PS_UTILIZAVALORBRUTO,
                               PS_PRIMEIRAIMPRESSAO,
                               PS_SOMACUSTOCARTORIO);
        ELSE
          P_ATUALIZADADOSBANCARIOS(TITULOS.NUMTRANSVENDA,
                                   TITULOS.PREST,
                                   VS_NOSSONUMERO,
                                   VS_CODBARRA,
                                   PN_NUMDIASPROTESTO,
                                   VS_LINHADIGITAVEL,
                                   PN_CODBANCO,
                                   PS_PRIMEIRAIMPRESSAO);
          COMMIT;
        END IF;
      END IF;
    END LOOP;
  END;
END PKG_DADOSBANCARIOS;