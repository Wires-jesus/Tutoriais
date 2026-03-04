CREATE OR REPLACE PACKAGE BODY PKG_RECEBIMENTOANTECIPADO
IS
    ----------------------------------------------------------------------------
    FUNCTION DADOS_PCPRESTANTECIPADA(PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                     PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                                     PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                                     ) RETURN SYS_REFCURSOR
    IS
    TYPE T_CURSOR IS REF CURSOR;
    VCURSOR T_CURSOR;
    BEGIN
        OPEN VCURSOR FOR
            SELECT NUMTRANSPAGADIANTADO
                  ,CODCLI
                  ,CODFILIAL
                  ,NUMPED
                  ,NUMORCA
                  ,COBANTECIPADA
                  ,QUITAPCPREST
                  ,VALOR
                  ,VLRCREDITOABATIDO
                  ,VALORPEDIDO
                  ,CODCOBPGTO
                  ,STATUSPGTO
                  ,DTEMISSAOPED
                  ,DTGERACAOPGTO
                  ,DTCONFIRMACAOPGTO
                  ,DTPGTO
                  ,DTESTORNO
                  ,NUMTRANSESTORNO
                  ,MATRICULAGERACAO
                  ,MATRICULACONFIRMACAO
                  ,MATRICULAESTORNO
              FROM PCPRESTANTECIPADA
             WHERE CODFILIAL  = PCODFILIAL
               AND CODCLI     = PCODCLI
               AND DECODE(NVL(NUMORCA,0),0,NVL(NUMPED,NUMORCA),NUMORCA) = PNUMPED;

        RETURN VCURSOR;
    END;

    ----------------------------------------------------------------------------
    FUNCTION CONSULTA_PAGANTECIPADO(PMENSAGEM   OUT VARCHAR2,
                                    PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                    PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                                    PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                                    )
    RETURN TB_PCPRESTANTECIPADA
    PIPELINED
    IS
    DADOS_SAIDA T_PCPRESTANTECIPADA;
    VCURSOR     SYS_REFCURSOR;
    VMENSAGEM   VARCHAR2(300);
	V_ENCONTROU BOOLEAN := FALSE;
    BEGIN
		PMENSAGEM := NULL;
        VCURSOR := DADOS_PCPRESTANTECIPADA(PCODFILIAL,PCODCLI,PNUMPED);

        LOOP
            FETCH VCURSOR INTO DADOS_SAIDA;
            EXIT WHEN VCURSOR%NOTFOUND;
			V_ENCONTROU := TRUE;
            PIPE ROW(DADOS_SAIDA);            
        END LOOP;
		IF NOT V_ENCONTROU THEN
		   PMENSAGEM := '[CP01] - Pagamento antecipado não encontrado';		   
		END IF;        
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, '[CP02] - '||VMENSAGEM);
    END; --CONSULTA_PAGANTECIPADO

    ----------------------------------------------------------------------------
    FUNCTION CONSULTA_STATUS(PMENSAGEM   OUT VARCHAR2,
                             PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                             PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                             PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                             )
    RETURN TB_PCPRESTANTECIPADA
    PIPELINED
    IS
    DADOS_SAIDA T_PCPRESTANTECIPADA;
    VCURSOR     SYS_REFCURSOR;
    VMENSAGEM   VARCHAR2(300);
	V_ENCONTROU BOOLEAN := FALSE;
    BEGIN
		PMENSAGEM := NULL; 
        VCURSOR   := DADOS_PCPRESTANTECIPADA(PCODFILIAL,PCODCLI,PNUMPED);

        LOOP
            FETCH VCURSOR INTO DADOS_SAIDA;
            EXIT WHEN VCURSOR%NOTFOUND;
			V_ENCONTROU := TRUE;
            PIPE ROW(DADOS_SAIDA);            
        END LOOP;        
		IF NOT V_ENCONTROU THEN
		   PMENSAGEM := '[CS01] - Pagamento antecipado não encontrado!';
		END IF;        
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, '[CS02] - '||VMENSAGEM);
    END; --CONSULTA_STATUS

    ----------------------------------------------------------------------------
    PROCEDURE SOLICITA_CANCELAMENTO(PMENSAGEM              OUT VARCHAR2,
                                    PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                    PMATRICULA             PCPRESTANTECIPADA.MATRICULAESTORNO%TYPE)
    IS
        VNUMTRANSPAGADIANTADO PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE;
        VMENSAGEM             VARCHAR2(300);
        VPOSICAO              PCPEDC.POSICAO%TYPE;
        VPERMISSAO            VARCHAR2(1);
        VACESSO               PCCONTROI.ACESSO%TYPE;
    BEGIN

        PMENSAGEM := '[SC01] - Pagamento antecipado não encontrado!';

        BEGIN
          SELECT NVL(PCCONTROI.ACESSO,'N')
            INTO VACESSO
            FROM PCCONTROI
               , PCROTINAI
           WHERE PCCONTROI.CODROTINA   = 1295
             AND PCCONTROI.CODUSUARIO  = PMATRICULA
             AND PCROTINAI.CODCONTROLE = 1
             AND PCCONTROI.CODROTINA   = PCROTINAI.CODROTINA
             AND PCCONTROI.CODCONTROLE = PCROTINAI.CODCONTROLE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VACESSO := 'N';
          WHEN TOO_MANY_ROWS THEN
            VACESSO := 'N';
          WHEN OTHERS THEN
            VACESSO := 'N';
        END;

        IF (VACESSO = 'N') THEN
            PMENSAGEM := '[SC02] - Pagamento quitado e usuário sem permissão para estorno (530 - 1295 - Permitir efetuar estorno do pagamento digital). Processo não será concluído!';            
            ROLLBACK;
            RETURN;
        END IF;

        FOR DADOS IN (SELECT NUMTRANSPAGADIANTADO,             /*01*/
                             CODCLI,                           /*02*/
                             CODFILIAL,                        /*03*/
                             NUMPED,                           /*04*/
                             NUMORCA,                          /*05*/
                             COBANTECIPADA,                    /*06*/
                             QUITAPCPREST,                     /*07*/
                             (VALOR * -1)       VALOR,         /*08*/
                             VLRCREDITOABATIDO,                /*09*/
                             VALORPEDIDO,                      /*10*/
                             CODCOBPGTO,                       /*11*/
                             STATUSPGTO,                       /*12*/
                             DTEMISSAOPED,                     /*13*/
                             DTGERACAOPGTO,                    /*14*/
                             MATRICULAGERACAO,                 /*15*/
                             MATRICULAESTORNO,                 /*16*/
                             DTESTORNO,                        /*17*/
                             NUMTRANSESTORNO                   /*18*/
                        FROM PCPRESTANTECIPADA
                       WHERE NUMTRANSPAGADIANTADO = PNUMTRANSPAGADIANTADO)
        LOOP
            IF (DADOS.STATUSPGTO IN ('AGUARDANDO PAGAMENTO','PAGO')) THEN

                IF DADOS.STATUSPGTO = 'PAGO' THEN

                    IF NVL(DADOS.NUMORCA,0) > 0 THEN
                        SELECT POSICAO 
                          INTO VPOSICAO
                          FROM PCORCAVENDAC 
                         WHERE NUMORCA   = DADOS.NUMORCA
                           AND CODCLI    = DADOS.CODCLI
                           AND CODFILIAL = DADOS.CODFILIAL;
                    END IF;

                    IF VPOSICAO IS NULL THEN
                        BEGIN
                            SELECT POSICAO 
                              INTO VPOSICAO
                              FROM PCPEDC 
                             WHERE NUMPED    = DADOS.NUMPED
                               AND CODCLI    = DADOS.CODCLI
                               AND CODFILIAL = DADOS.CODFILIAL;
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                VPOSICAO := NULL;
                        END;
                    END IF;

                    IF VPOSICAO IS NULL THEN
                        PMENSAGEM := '[SC03] - Posição do pedido não encontrada:' ||
                                     ' Pedido número: '||DADOS.NUMPED||
                                     ' Cliente: '||DADOS.CODCLI||
                                     ' Filial: '||DADOS.CODFILIAL;
                        ROLLBACK;
                        RETURN;
                    END IF;

                    IF VPOSICAO IN ('M','L') THEN
                        PMENSAGEM := '[SC04] - Não é possível cancelar pois o pedido já foi liberado. Para cancelar o pagamento, será necessário bloquear ou cancelar o pedido antes.';
                        ROLLBACK;
                        RETURN;
                    END IF;

                    IF VPOSICAO IN ('F') THEN 
                        PMENSAGEM := '[SC05] - Não é possível cancelar pois o pedido já foi faturado.';
                        ROLLBACK;
                        RETURN;
                    END IF;

                    IF VPERMISSAO = 'N' THEN
                        PMENSAGEM := '[SC06] - Pagamento quitado e usuário sem permissão para estorno. Processo não será concluído.';
                        ROLLBACK;
                        RETURN;
                    END IF;

                END IF;

                SELECT DFSEQ_PCPRESTANTECIPADA.NEXTVAL
                  INTO VNUMTRANSPAGADIANTADO
                  FROM DUAL;

                INSERT INTO PCPRESTANTECIPADA(NUMTRANSPAGADIANTADO,             /*01*/
                                              CODCLI,                           /*02*/
                                              CODFILIAL,                        /*03*/
                                              NUMPED,                           /*04*/
                                              NUMORCA,                          /*05*/
                                              COBANTECIPADA,                    /*06*/
                                              QUITAPCPREST,                     /*07*/
                                              VALOR,                            /*08*/
                                              VLRCREDITOABATIDO,                /*09*/
                                              VALORPEDIDO,                      /*10*/
                                              CODCOBPGTO,                       /*11*/
                                              STATUSPGTO,                       /*12*/
                                              DTEMISSAOPED,                     /*13*/
                                              DTGERACAOPGTO,                    /*14*/
                                              MATRICULAGERACAO,                 /*15*/
                                              MATRICULAESTORNO,                 /*16*/
                                              DTESTORNO,                        /*17*/
                                              NUMTRANSESTORNO)                  /*18*/
                                       VALUES(VNUMTRANSPAGADIANTADO,            /*01*/
                                              DADOS.CODCLI,                     /*02*/
                                              DADOS.CODFILIAL,                  /*03*/
                                              DADOS.NUMPED,                     /*04*/
                                              DADOS.NUMORCA,                    /*05*/
                                              DADOS.COBANTECIPADA,              /*06*/
                                              DADOS.QUITAPCPREST,               /*07*/
                                              DADOS.VALOR,                      /*08*/
                                              DADOS.VLRCREDITOABATIDO,          /*09*/
                                              DADOS.VALORPEDIDO,                /*10*/
                                              DADOS.CODCOBPGTO,                 /*11*/
                                              'CANCELADO',                      /*12*/
                                              DADOS.DTEMISSAOPED,               /*13*/
                                              DADOS.DTGERACAOPGTO,              /*14*/
                                              DADOS.MATRICULAGERACAO,           /*15*/
                                              PMATRICULA,                       /*16*/
                                              SYSDATE,                          /*17*/
                                              VNUMTRANSPAGADIANTADO);           /*18*/

                UPDATE PCPRESTANTECIPADA
                   SET MATRICULAESTORNO     = PMATRICULA,
                       DTESTORNO            = SYSDATE,
                       NUMTRANSESTORNO      = VNUMTRANSPAGADIANTADO,
                       STATUSPGTO           = 'ESTORNADO'
                 WHERE NUMTRANSPAGADIANTADO = DADOS.NUMTRANSPAGADIANTADO;
                 
                UPDATE PCCRECLI
                   SET NUMTRANSPAGADIANTADO = VNUMTRANSPAGADIANTADO
                 WHERE NUMTRANSPAGADIANTADO = DADOS.NUMTRANSPAGADIANTADO
                   AND NVL(SITUACAO,'1')    NOT IN ('A');

                 PMENSAGEM := '[SC07] - Cancelamento concluído com sucesso';

            END IF; 
            --------------------------------------------------------------------            

        END LOOP;
        COMMIT WORK;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, '[SC08] - Erro no estorno do pagamento. Log recebido: ('||VMENSAGEM||')');    
    END; --SOLICITA_CANCELAMENTO

    ----------------------------------------------------------------------------
    PROCEDURE ATUALIZAR_STATUS(PMENSAGEM              OUT VARCHAR2,
                               PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                               PMATRICULA             PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE)
    IS
        VNUMTRANS      PCMOVCR.NUMTRANS%TYPE;
        VROTINA        PCMOVCR.ROTINALANCAMENTO%TYPE;
        VHORA          PCMOVCR.HORA%TYPE;
        VMINUTO        PCMOVCR.MINUTO%TYPE;
        VVLSALDO       PCMOVCR.VLSALDO%TYPE;
        VQUITAPCPREST  PCCOB.QUITAPCPREST%TYPE;
        VOLDNUMTRANS   PCPRESTANTECIPADA.NUMTRANS%TYPE;
    BEGIN
        VROTINA      := SYS_CONTEXT('USERENV', 'MODULE');
        VOLDNUMTRANS := 0;

        SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP),
               EXTRACT(MINUTE FROM CURRENT_TIMESTAMP) 
          INTO VHORA,VMINUTO
          FROM DUAL;

        PMENSAGEM := '[AS01] - Atualização realizada com sucesso!';

        FOR DADOS IN (SELECT A.NUMTRANSPAGADIANTADO,                            /*01*/
                             A.CODCLI,                                          /*02*/
                             A.CODFILIAL,                                       /*03*/
                             A.NUMPED,                                          /*04*/
                             A.NUMORCA,                                         /*05*/
                             A.COBANTECIPADA,                                   /*06*/
                             NVL(A.QUITAPCPREST,'N') QUITAPCPREST,              /*07*/
                             A.VALOR,                                           /*08*/
                             A.VLRCREDITOABATIDO,                               /*09*/
                             A.VALORPEDIDO,                                     /*10*/
                             A.CODCOBPGTO,                                      /*11*/
                             A.STATUSPGTO,                                      /*12*/
                             A.DTEMISSAOPED,                                    /*13*/
                             A.DTGERACAOPGTO,                                   /*14*/
                             A.MATRICULAGERACAO,                                /*15*/
                             A.MATRICULAESTORNO,                                /*16*/
                             A.DTESTORNO,                                       /*17*/
                             A.NUMTRANSESTORNO,                                 /*18*/
                             A.DTPGTO,                                          /*19*/
                             C.CODBCOCOBANTECIPADA,                             /*20*/
                             C.CODMOEDACOBANTECIPADA,                           /*21*/
                             NVL(A.NUMTRANS,0) NUMTRANS                         /*22*/
                        FROM PCPRESTANTECIPADA       A,
                             PCCOB                   C
                       WHERE A.CODCOBPGTO            = C.CODCOB
                         AND A.NUMTRANSPAGADIANTADO  = PNUMTRANSPAGADIANTADO)
        LOOP
            IF DADOS.CODBCOCOBANTECIPADA IS NULL THEN
                PMENSAGEM := '[AS02] - Necessário informar o banco para baixa na ABA -> Pagamento Antecipado na 522';
                ROLLBACK;
                RETURN;
            END IF;

            IF ((DADOS.CODMOEDACOBANTECIPADA IS NULL) AND (DADOS.QUITAPCPREST = 'S')) THEN
                PMENSAGEM := '[AS03] - Necessário informar a moeda para baixa na ABA -> Pagamento Antecipado na 522';
                ROLLBACK;
                RETURN;
            END IF;

            IF (NVL(DADOS.NUMTRANS,0) = 0) THEN 
                SELECT NVL(PROXNUMTRANS,1)
                  INTO VNUMTRANS 
                  FROM PCCONSUM FOR UPDATE;
                UPDATE PCCONSUM
                   SET PROXNUMTRANS = NVL(PROXNUMTRANS,1)+1 WHERE 1=1;
            ELSE
                VNUMTRANS := DADOS.NUMTRANS;
            END IF;

            COMMIT WORK;

            IF (NVL(DADOS.NUMTRANS,0) > 0) THEN
                SELECT COUNT(*)
                  INTO VOLDNUMTRANS
                  FROM PCMOVCR
                 WHERE NUMTRANS = DADOS.NUMTRANS;
            END IF;

            IF (DADOS.QUITAPCPREST = 'S') AND (VOLDNUMTRANS = 0) THEN

                SELECT VLSALDO 
                  INTO VVLSALDO  
                  FROM PCMOVCR
                 WHERE NUMSEQ = (SELECT MAX(NUMSEQ) 
                                   FROM PCMOVCR 
                                  WHERE CODBANCO = DADOS.CODBCOCOBANTECIPADA
                                    AND CODCOB   = DADOS.CODMOEDACOBANTECIPADA)
                   FOR UPDATE;

                INSERT INTO PCMOVCR(NUMTRANS,                                   /*01*/
                                    DATA,                                       /*02*/
                                    CODBANCO,                                   /*03*/
                                    CODCOB,                                     /*04*/
                                    CODFILIAL,                                  /*05*/
                                    VALOR,                                      /*06*/
                                    TIPO,                                       /*07*/
                                    HISTORICO,                                  /*08*/
                                    NUMCARR,                                    /*09*/
                                    VLSALDO,                                    /*10*/
                                    HORA,                                       /*11*/
                                    MINUTO,                                     /*12*/
                                    CODFUNC,                                    /*13*/
                                    INDICE,                                     /*14*/
                                    HISTORICO2,                                 /*15*/
                                    CODROTINALANC,                              /*16*/
                                    ESTORNO,                                    /*17*/
                                    CODCLI,                                     /*18*/
                                    DATACOMPLETA,                               /*19*/
                                    ROTINALANCAMENTO)                           /*20*/
                             VALUES(VNUMTRANS,
                                    TRUNC(SYSDATE),
                                    DADOS.CODBCOCOBANTECIPADA,
                                    DADOS.CODMOEDACOBANTECIPADA,
                                    DADOS.CODFILIAL,
                                    (DADOS.VALORPEDIDO - DADOS.VLRCREDITOABATIDO),
                                    'D',
                                    'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGADIANTADO||')',
                                    0,
                                    (VVLSALDO + (DADOS.VALORPEDIDO - DADOS.VLRCREDITOABATIDO)),
                                    VHORA,
                                    VMINUTO,
                                    PMATRICULA,
                                    'A',
                                    'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGADIANTADO||')',
                                    1295,
                                    'N',
                                    DADOS.CODCLI,
                                    SYSDATE,
                                    VROTINA); 

            END IF; --VQUITAPCPREST

            IF (NVL(DADOS.NUMTRANS,0) > 0) THEN
                SELECT COUNT(*)
                  INTO VOLDNUMTRANS
                  FROM PCCRECLI 
                 WHERE NUMTRANS = DADOS.NUMTRANS;
            END IF; 

            IF (VOLDNUMTRANS = 0) THEN
                INSERT INTO PCCRECLI(CODCLI,                                    /*01*/
                                     DTLANC,                                    /*02*/
                                     CODFILIAL,                                 /*03*/
                                     VALOR,                                     /*04*/
                                     CODFUNC,                                   /*05*/
                                     HORA,                                      /*06*/
                                     MINUTO,                                    /*07*/
                                     HISTORICO,                                 /*08*/
                                     CODFUNCLANC,                               /*09*/
                                     NUMERARIO,                                 /*10*/
                                     CODMOVIMENTO,                              /*11*/
                                     NUMTRANS,                                  /*12*/
                                     CODROTINA,                                 /*13*/
                                     SITUACAO,                                  /*14*/
                                     ROTINAINSERT,                              /*15*/
                                     ROTINAULTIMAALTERACAO,                     /*16*/
                                     NUMPED,                                    /*18*/
                                     NUMTRANSPAGADIANTADO)                      /*17*/
                              VALUES(DADOS.CODCLI,
                                     TRUNC(SYSDATE),
                                     DADOS.CODFILIAL,
                                     (DADOS.VALORPEDIDO - DADOS.VLRCREDITOABATIDO),
                                     PMATRICULA,
                                     VHORA,
                                     VMINUTO,
                                     'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGADIANTADO||')',
                                     PMATRICULA,
                                     'S',
                                     DADOS.CODBCOCOBANTECIPADA,
                                     VNUMTRANS,
                                     1295,
                                     'A',
                                     VROTINA,
                                     VROTINA,
                                     NVL(DADOS.NUMPED,DADOS.NUMORCA),
                                     PNUMTRANSPAGADIANTADO);
            END IF;

            UPDATE PCPRESTANTECIPADA
               SET DTCONFIRMACAOPGTO    = TRUNC(SYSDATE),
                   DTPGTO               = DADOS.DTPGTO,
                   MATRICULACONFIRMACAO = PMATRICULA,
                   STATUSPGTO           = 'PAGO',
                   NUMTRANS             = VNUMTRANS,
                   VALOR                = DADOS.VALORPEDIDO - DADOS.VLRCREDITOABATIDO
             WHERE NUMTRANSPAGADIANTADO = PNUMTRANSPAGADIANTADO;
        END LOOP;
        COMMIT WORK;
    END; --ATUALIZAR_STATUS

    ----------------------------------------------------------------------------
    PROCEDURE ESTORNO_RECEBIMENTO(PMENSAGEM              OUT VARCHAR2,
                                  PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                  PMATRICULA             PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE)
    IS
        VNUMTRANS      PCMOVCR.NUMTRANS%TYPE;
        VROTINA        PCMOVCR.ROTINALANCAMENTO%TYPE;
        VHORA          PCMOVCR.HORA%TYPE;
        VMINUTO        PCMOVCR.MINUTO%TYPE;
        VVLSALDO       PCMOVCR.VLSALDO%TYPE;
        VVALOR         PCCRECLI.VALOR%TYPE; 
        VCODMOVIMENTO  PCCRECLI.CODMOVIMENTO%TYPE;
        VNUMCRED       PCCRECLI.NUMCRED%TYPE;
        VCOBANTECIPADA PCCRECLI.COBANTECIPADA%TYPE;
        VQUITAPCPREST  PCCRECLI.QUITAPCPREST%TYPE;
        VCODBANCO      PCMOVCR.CODBANCO%TYPE;
        VCODCOB        PCMOVCR.CODCOB%TYPE; 
    BEGIN
        VROTINA      := SYS_CONTEXT('USERENV', 'MODULE');

        PMENSAGEM := '[ER01] - Estorno realizado com sucesso!';

        SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP),
               EXTRACT(MINUTE FROM CURRENT_TIMESTAMP) 
          INTO VHORA,VMINUTO
          FROM DUAL;

        FOR DADOS IN (SELECT A.NUMTRANSPAGADIANTADO,                            /*01*/
                             A.CODCLI,                                          /*02*/
                             A.CODFILIAL,                                       /*03*/
                             A.NUMPED,                                          /*04*/
                             A.NUMORCA,                                         /*05*/
                             A.COBANTECIPADA,                                   /*06*/
                             NVL(A.QUITAPCPREST,'N') QUITAPCPREST,              /*07*/
                             A.VALOR,                                           /*08*/
                             A.VLRCREDITOABATIDO,                               /*09*/
                             A.VALORPEDIDO,                                     /*10*/
                             A.CODCOBPGTO,                                      /*11*/
                             A.STATUSPGTO,                                      /*12*/
                             A.DTEMISSAOPED,                                    /*13*/
                             A.DTGERACAOPGTO,                                   /*14*/
                             A.MATRICULAGERACAO,                                /*15*/
                             A.MATRICULAESTORNO,                                /*16*/
                             A.DTESTORNO,                                       /*17*/
                             A.NUMTRANSESTORNO,                                 /*18*/
                             A.DTPGTO,                                          /*19*/
                             C.CODBCOCOBANTECIPADA,                             /*20*/
                             C.CODMOEDACOBANTECIPADA,                           /*21*/
                             NVL(A.NUMTRANS,0) NUMTRANS                         /*22*/
                        FROM PCPRESTANTECIPADA       A,
                             PCCOB                   C
                       WHERE A.CODCOBPGTO            = C.CODCOB
                         AND A.NUMTRANSPAGADIANTADO  = PNUMTRANSPAGADIANTADO)
        LOOP

            IF (NVL(DADOS.NUMTRANS,0) <> 0) THEN 
                SELECT NVL(PROXNUMTRANS,1)
                  INTO VNUMTRANS 
                  FROM PCCONSUM FOR UPDATE;
                UPDATE PCCONSUM
                   SET PROXNUMTRANS = NVL(PROXNUMTRANS,1)+1 WHERE 1=1;
            ELSE
                VNUMTRANS := DADOS.NUMTRANS;
            END IF;

            SELECT VLSALDO,CODBANCO,CODCOB
              INTO VVLSALDO,VCODBANCO,VCODCOB
              FROM PCMOVCR
             WHERE NUMSEQ = (SELECT MAX(NUMSEQ) 
                               FROM PCMOVCR 
                              WHERE CODBANCO = DADOS.CODBCOCOBANTECIPADA
                                AND CODCOB   = DADOS.CODMOEDACOBANTECIPADA)
               FOR UPDATE;

            COMMIT WORK;

            --UPDATE NA PCMOVCR ORIGINAL
            UPDATE PCMOVCR
               SET ESTORNO  = 'N'
             WHERE NUMTRANS = DADOS.NUMTRANS;

            --INSERT NA PCMOVCR
            INSERT INTO PCMOVCR(NUMTRANS,                                       /*01*/
                                DATA,                                           /*02*/
                                CODBANCO,                                       /*03*/
                                CODCOB,
                                VALOR,                                          /*04*/
                                TIPO,                                           /*05*/
                                HISTORICO,                                      /*06*/
                                NUMCARR,                                        /*07*/
                                VLSALDO,                                        /*08*/
                                CODFUNC,                                        /*09*/
                                HORA,                                           /*10*/
                                MINUTO,                                         /*11*/
                                INDICE,                                         /*12*/
                                HISTORICO2,                                     /*13*/
                                CODROTINALANC,                                  /*14*/
                                ESTORNO,                                        /*15*/
                                DATACOMPLETA,                                   /*16*/
                                ROTINALANCAMENTO)                               /*17*/
                         VALUES(VNUMTRANS,
                                TRUNC(SYSDATE),
                                VCODBANCO,
                                VCODCOB,
                                (DADOS.VALORPEDIDO - DADOS.VLRCREDITOABATIDO),
                                'C',
                                'ESTORNO DE RECEBIMENTO ANTECIPADO',
                                0,
                                (VVLSALDO + DADOS.VALOR),
                                PMATRICULA,
                                VHORA,
                                VMINUTO,
                                'A',
                                'ESTORNO DE RECEBIMENTO ANTECIPADO (TRANSAÇÃO: '||DADOS.NUMTRANSPAGADIANTADO||')',
                                1295,
                                'N',
                                TRUNC(SYSDATE),
                                VROTINA);
                                
            SELECT (VALOR*-1), CODMOVIMENTO , NUMCRED , COBANTECIPADA , QUITAPCPREST
              INTO VVALOR    , VCODMOVIMENTO, VNUMCRED, VCOBANTECIPADA, VQUITAPCPREST 
              FROM PCCRECLI
             WHERE NUMTRANSPAGADIANTADO  = DADOS.NUMTRANSPAGADIANTADO
               AND SITUACAO              = 'A'
               AND VALOR                 > 0;
                                
            --INSERT NA PCCRECLI
            INSERT INTO PCCRECLI(CODCLI,                                        /*01*/
                                 DTLANC,                                        /*02*/
                                 CODFILIAL,                                     /*03*/
                                 VALOR,                                         /*04*/
                                 DTDESCONTO,                                    /*05*/
                                 CODFILIALDESC,                                 /*06*/
                                 CODFUNC,                                       /*07*/
                                 HORA,                                          /*08*/
                                 MINUTO,                                        /*09*/
                                 HISTORICO,                                     /*10*/
                                 CODFUNCLANC,                                   /*11*/
                                 NUMERARIO,                                     /*12*/
                                 CODMOVIMENTO,                                  /*13*/
                                 NUMTRANSBAIXA,                                 /*14*/
                                 CODROTINA,                                     /*15*/
                                 SITUACAO,                                      /*16*/
                                 NUMCRED,                                       /*17*/
                                 DTESTORNO,                                     /*18*/
                                 ROTINAINSERT,                                  /*19*/
                                 ROTINAULTIMAALTERACAO,                         /*20*/
                                 ROTINAESTORNO,                                 /*21*/
                                 ROTINABAIXA,                                   /*22*/
                                 DTCANCEL,                                      /*23*/
                                 CASHBACK,                                      /*24*/
                                 NUMTRANSPAGADIANTADO,                          /*25*/
                                 COBANTECIPADA,                                 /*26*/
                                 QUITAPCPREST)                                  /*27*/
                          VALUES(DADOS.CODCLI,
                                 TRUNC(SYSDATE),
                                 DADOS.CODFILIAL,
                                 VVALOR,
                                 TRUNC(SYSDATE),
                                 DADOS.CODFILIAL,
                                 PMATRICULA,
                                 VHORA,
                                 VMINUTO,
                                 'ESTORNO DE RECEBIMENTO ANTECIPADO',
                                 PMATRICULA,
                                 'S',
                                 VCODMOVIMENTO,
                                 VNUMTRANS,
                                 1295,
                                 'A',
                                 VNUMCRED,
                                 TRUNC(SYSDATE),
                                 VROTINA,
                                 VROTINA,
                                 VROTINA,
                                 VROTINA,
                                 TRUNC(SYSDATE),
                                 'N',
                                 PNUMTRANSPAGADIANTADO,
                                 VCOBANTECIPADA,
                                 VQUITAPCPREST);
                                
            --UPDATE NA PCCRECLI ORIGINAL
            UPDATE PCCRECLI
               SET DTDESCONTO            = TRUNC(SYSDATE),
                   CODFILIALDESC         = DADOS.CODFILIAL,
                   DTESTORNO             = TRUNC(SYSDATE),
                   ROTINAULTIMAALTERACAO = VROTINA,
                   ROTINAESTORNO         = VROTINA,
                   ROTINABAIXA           = VROTINA,
                   NUMPED                = NULL
             WHERE NUMTRANSPAGADIANTADO  = DADOS.NUMTRANSPAGADIANTADO
               AND SITUACAO              = 'A';
        END LOOP;
        COMMIT WORK;
    END;

    ----------------------------------------------------------------------------
    PROCEDURE CRIAR_RECEB_ANTECIPADO(PSTATUS                OUT VARCHAR2,
                                     PMENSAGEM              OUT VARCHAR2,
                                     PNUMTRANSPAGOADIANTADO OUT PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                     PCODIGO                OUT PCCRECLI.CODIGO%TYPE,
                                     PNUMTRANS              OUT PCMOVCR.NUMTRANS%TYPE,

                                     PCODCLI                 IN PCPRESTANTECIPADA.CODCLI%TYPE,
                                     PNUMPED                 IN PCPRESTANTECIPADA.NUMPED%TYPE,
                                     PVALOR                  IN PCPRESTANTECIPADA.VALOR%TYPE,
                                     PCODFILIAL              IN PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                     PVALORPEDIDO            IN PCPRESTANTECIPADA.VALORPEDIDO%TYPE,
                                     PCODCOBPGTO             IN PCPRESTANTECIPADA.CODCOBPGTO%TYPE,
                                     PDTEMISSAOPED           IN PCPRESTANTECIPADA.DTEMISSAOPED%TYPE,
                                     PDTGERACAOPGTO          IN PCPRESTANTECIPADA.DTGERACAOPGTO%TYPE,
                                     PDTCONFIRMACAOPGTO      IN PCPRESTANTECIPADA.DTCONFIRMACAOPGTO%TYPE,
                                     PDTPGTO                 IN PCPRESTANTECIPADA.DTPGTO%TYPE,
                                     PMATRICULAGERACAO       IN PCPRESTANTECIPADA.MATRICULAGERACAO%TYPE,
                                     PMATRICULACONFIRMACAO   IN PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE,

                                     PNSUTEF                 IN PCPRESTANTECIPADA.NSUTEF%TYPE DEFAULT NULL,
                                     PNSUHOST                IN PCPRESTANTECIPADA.NSUHOST%TYPE DEFAULT NULL,
                                     PCODREDE                IN PCPRESTANTECIPADA.CODREDE%TYPE DEFAULT NULL,
                                     PQTDPARCELATEF          IN PCPRESTANTECIPADA.QTDPARCELATEF%TYPE DEFAULT NULL,
                                     PNOME_CARTEIRA_DIGITAL  IN PCPRESTANTECIPADA.NOME_CARTEIRA_DIGITAL%TYPE DEFAULT NULL,
                                     PCODADMINISTRADORA      IN PCPRESTANTECIPADA.CODADMINISTRADORA%TYPE DEFAULT NULL,
                                     PCODBANDEIRA            IN PCPRESTANTECIPADA.CODBANDEIRA%TYPE DEFAULT NULL,
                                     PNUMTRANSPAGDIGITAL     IN PCPRESTANTECIPADA.NUMTRANSPAGDIGITAL%TYPE DEFAULT NULL,
                                     PNUMCAIXAFISCAL         IN PCPRESTANTECIPADA.NUMCAIXAFISCAL%TYPE DEFAULT NULL,
                                     PCODFUNCCHECKOUT        IN PCPRESTANTECIPADA.CODFUNCCHECKOUT%TYPE DEFAULT NULL,
                                     PNUMCAIXA               IN PCPRESTANTECIPADA.NUMCAIXA%TYPE DEFAULT NULL,
                                     PQUITAPCPREST           IN PCPRESTANTECIPADA.QUITAPCPREST%TYPE DEFAULT 'S',
                                     PEXECUTACOMMITROLLBACK  IN VARCHAR2 DEFAULT 'S'
                                    )
    IS
        VNUMTRANSPAGOADIANTADO PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE;
        VNUMTRANS PCMOVCR.NUMTRANS%TYPE;
        VVLSALDO PCMOVCR.VLSALDO%TYPE;
        VHORA PCMOVCR.HORA%TYPE;
        VMINUTO PCMOVCR.MINUTO%TYPE;
        VROTINA PCMOVCR.ROTINALANCAMENTO%TYPE;
        VCODBCOCOBANTECIPADA PCCOB.CODBCOCOBANTECIPADA%TYPE;
        VCODMOEDACOBANTECIPADA PCCOB.CODMOEDACOBANTECIPADA%TYPE;
        VCODIGO PCCRECLI.CODIGO%TYPE;
    BEGIN
        PNUMTRANSPAGOADIANTADO := 0;
        PCODIGO                := 0;
        PNUMTRANS              := 0;

        PSTATUS := 'OK';
        PMENSAGEM := '[CRA01] - Crédito gerado com sucesso';

        IF (PCODCLI <= 0) OR (PCODCLI IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA02] - Necessário informar o código do cliente.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PNUMPED <= 0) OR (PNUMPED IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA03] - Necessário informar o número do pedido.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PVALOR <= 0) OR (PVALOR IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA04] - Necessário informar o valor do recebimento antecipado.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PCODFILIAL = '') OR (PCODFILIAL IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA05] - Necessário informar a filial.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PVALORPEDIDO <= 0) OR (PVALORPEDIDO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA06] - Necessário informar o valor do pedido.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PCODCOBPGTO = '') OR (PCODCOBPGTO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA07] - Necessário informar a cobrança do pagamento.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PDTEMISSAOPED = '') OR (PDTEMISSAOPED IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA08] - Necessário informar a data de emissão do pedido.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PDTGERACAOPGTO = '') OR (PDTGERACAOPGTO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA09] - Necessário informar a data de geração do pagamento.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PDTCONFIRMACAOPGTO = '') OR (PDTCONFIRMACAOPGTO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA10] - Necessário informar a data de confirmação do pagamento.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PDTPGTO = '') OR (PDTPGTO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA11] - Necessário informar a data de pagamento informada na API.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PMATRICULAGERACAO <= 0) OR (PMATRICULAGERACAO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA12] - Necessário informar a matrícula do usuário que gerou o pagamento.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF (PMATRICULACONFIRMACAO <= 0) OR (PMATRICULACONFIRMACAO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA13] - Necessário informar a matrícula do usuário que confirmou o pagamento.';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        SELECT COB.CODBCOCOBANTECIPADA,
               COB.CODMOEDACOBANTECIPADA
          INTO VCODBCOCOBANTECIPADA,
               VCODMOEDACOBANTECIPADA
          FROM PCCOB COB
         WHERE COB.CODCOB = PCODCOBPGTO;

        IF VCODBCOCOBANTECIPADA IS NULL THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA14] - Necessário informar o banco para baixa na ABA -> Pagamento Antecipado na 522';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        IF VCODMOEDACOBANTECIPADA IS NULL THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[CRA15] - Necessário informar a moeda para baixa na ABA -> Pagamento Antecipado na 522';

            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;

            RETURN;
        END IF;

        -- Gerando nova linha de registro na tabela PCPRESTANTECIPADA com os parâmetros recebidos
        SELECT DFSEQ_PCPRESTANTECIPADA.NEXTVAL
          INTO VNUMTRANSPAGOADIANTADO
          FROM DUAL;

        INSERT INTO PCPRESTANTECIPADA (
            NUMTRANSPAGADIANTADO,   /*01*/
            CODCLI,                 /*02*/
            NUMPED,                 /*03*/
            VALOR,                  /*04*/
            VLRCREDITOABATIDO,      /*05*/
            CODFILIAL,              /*06*/
            VALORPEDIDO,            /*07*/
            CODCOBPGTO,             /*08*/
            STATUSPGTO,             /*09*/
            DTEMISSAOPED,           /*10*/
            DTGERACAOPGTO,          /*11*/
            DTCONFIRMACAOPGTO,      /*12*/
            DTPGTO,                 /*13*/
            MATRICULAGERACAO,       /*14*/
            MATRICULACONFIRMACAO,   /*15*/
            NSUTEF,                 /*16*/
            NSUHOST,                /*17*/
            CODREDE,                /*18*/
            QTDPARCELATEF,          /*19*/
            NOME_CARTEIRA_DIGITAL,  /*20*/
            CODADMINISTRADORA,      /*21*/
            CODBANDEIRA,            /*22*/
            NUMTRANSPAGDIGITAL,     /*23*/
            NUMCAIXAFISCAL,         /*24*/
            CODFUNCCHECKOUT,        /*25*/
            NUMCAIXA,               /*26*/
            COBANTECIPADA,          /*27*/
            QUITAPCPREST            /*28*/
        ) VALUES (
            VNUMTRANSPAGOADIANTADO, /*01*/
            PCODCLI,                /*02*/
            PNUMPED,                /*03*/
            PVALOR,                 /*04*/
            0.00,                   /*05*/
            PCODFILIAL,             /*06*/
            PVALORPEDIDO,           /*07*/
            PCODCOBPGTO,            /*08*/
            'PAGO',                 /*09*/
            PDTEMISSAOPED,          /*10*/
            PDTGERACAOPGTO,         /*11*/
            PDTCONFIRMACAOPGTO,     /*12*/
            PDTPGTO,                /*13*/
            PMATRICULAGERACAO,      /*14*/
            PMATRICULACONFIRMACAO,  /*15*/
            PNSUTEF,                /*16*/
            PNSUHOST,               /*17*/
            PCODREDE,               /*18*/
            PQTDPARCELATEF,         /*19*/
            PNOME_CARTEIRA_DIGITAL, /*20*/
            PCODADMINISTRADORA,     /*21*/
            PCODBANDEIRA,           /*22*/
            PNUMTRANSPAGDIGITAL,    /*23*/
            PNUMCAIXAFISCAL,        /*24*/
            PCODFUNCCHECKOUT,       /*25*/
            PNUMCAIXA,              /*26*/
            'S',                    /*27*/
            NVL(PQUITAPCPREST, 'S') /*28*/
        );

        PNUMTRANSPAGOADIANTADO := VNUMTRANSPAGOADIANTADO;

        -- Gerando a movimentação financeira vinculada ao crédito na PCMOVCR.
        VROTINA := SYS_CONTEXT('USERENV', 'MODULE');

        SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP),
               EXTRACT(MINUTE FROM CURRENT_TIMESTAMP) 
          INTO VHORA,
               VMINUTO
          FROM DUAL;

        BEGIN
            SELECT VLSALDO 
              INTO VVLSALDO
              FROM PCMOVCR
             WHERE NUMSEQ = (SELECT MAX(NUMSEQ)
                               FROM PCMOVCR 
                              WHERE CODBANCO = VCODBCOCOBANTECIPADA
                                AND CODCOB   = VCODMOEDACOBANTECIPADA);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                VVLSALDO := 0;
        END;

        SELECT NVL(PROXNUMTRANS, 1)
          INTO VNUMTRANS 
          FROM PCCONSUM FOR UPDATE;
        UPDATE PCCONSUM
           SET PROXNUMTRANS = NVL(PROXNUMTRANS, 1) + 1 WHERE 1=1;

        INSERT INTO PCMOVCR (
            NUMTRANS,        /*01*/
            DATA,            /*02*/
            CODBANCO,        /*03*/
            CODCOB,          /*04*/
            CODFILIAL,       /*05*/
            VALOR,           /*06*/
            TIPO,            /*07*/
            HISTORICO,       /*08*/
            NUMCARR,         /*09*/
            VLSALDO,         /*10*/
            HORA,            /*11*/
            MINUTO,          /*12*/
            CODFUNC,         /*13*/
            INDICE,          /*14*/
            HISTORICO2,      /*15*/
            CODROTINALANC,   /*16*/
            ESTORNO,         /*17*/
            CODCLI,          /*18*/
            DATACOMPLETA,    /*19*/
            ROTINALANCAMENTO /*20*/
        ) VALUES (
            VNUMTRANS,                                                                               /*01*/
            TRUNC(SYSDATE),                                                                          /*02*/
            VCODBCOCOBANTECIPADA,                                                                    /*03*/
            VCODMOEDACOBANTECIPADA,                                                                  /*04*/
            PCODFILIAL,                                                                              /*05*/
            PVALOR,                                                                                  /*06*/
            'D',                                                                                     /*07*/
            'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGOADIANTADO||')', /*08*/
            0,                                                                                       /*09*/
            (VVLSALDO + PVALOR),                                                                     /*10*/
            VHORA,                                                                                   /*11*/
            VMINUTO,                                                                                 /*12*/
            PMATRICULACONFIRMACAO,                                                                   /*13*/
            'A',                                                                                     /*14*/
            'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGOADIANTADO||')', /*15*/
            1400,                                                                                    /*16*/
            'N',                                                                                     /*17*/
            PCODCLI,                                                                                 /*18*/
            SYSDATE,                                                                                 /*19*/
            VROTINA                                                                                  /*20*/
        );

        PNUMTRANS := VNUMTRANS;

        UPDATE PCPRESTANTECIPADA 
		   SET NUMTRANS = VNUMTRANS
         WHERE NUMTRANSPAGADIANTADO = VNUMTRANSPAGOADIANTADO;

        -- Criando crédito antecipado na PCCRECLI
        INSERT INTO PCCRECLI (
            CODCLI,                /*01*/
            DTLANC,                /*02*/
            CODFILIAL,             /*03*/
            VALOR,                 /*04*/
            CODFUNC,               /*05*/
            HORA,                  /*06*/
            MINUTO,                /*07*/
            HISTORICO,             /*08*/
            CODFUNCLANC,           /*09*/
            NUMERARIO,             /*10*/
            CODMOVIMENTO,          /*11*/
            NUMTRANS,              /*12*/
            CODROTINA,             /*13*/
            SITUACAO,              /*14*/
            ROTINAINSERT,          /*15*/
            ROTINAULTIMAALTERACAO, /*16*/
            NUMPED,                /*17*/
            NUMTRANSPAGADIANTADO   /*18*/
        ) VALUES (
            PCODCLI,                                                                                 /*01*/
            TRUNC(SYSDATE),                                                                          /*02*/
            PCODFILIAL,                                                                              /*03*/
            PVALOR,                                                                                  /*04*/
            PMATRICULACONFIRMACAO,                                                                   /*05*/
            VHORA,                                                                                   /*06*/
            VMINUTO,                                                                                 /*07*/
            'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGOADIANTADO||')', /*08*/
            PMATRICULACONFIRMACAO,                                                                   /*09*/
            'S',                                                                                     /*10*/
            VCODBCOCOBANTECIPADA,                                                                    /*11*/
            VNUMTRANS,                                                                               /*12*/
            1400,                                                                                    /*13*/
            'A',                                                                                     /*14*/
            VROTINA,                                                                                 /*15*/
            VROTINA,                                                                                 /*16*/
            PNUMPED,                                                                                 /*17*/
            VNUMTRANSPAGOADIANTADO                                                                   /*18*/
        );

        SELECT MAX(CODIGO) CODIGO
        INTO VCODIGO
        FROM PCCRECLI;

        PCODIGO := VCODIGO;

        IF PEXECUTACOMMITROLLBACK = 'S' THEN
            COMMIT WORK;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            PMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, '[CRA16] - Erro ao criar recebimento antecipado. Log recebido: (' || PMENSAGEM || ')');
    END; --CRIAR_RECEB_ANTECIPADO

    ----------------------------------------------------------------------------
    PROCEDURE ESTORNAR_RECEB_ANTECIPADO(PSTATUS                OUT VARCHAR2,
                                        PMENSAGEM              OUT VARCHAR2,

                                        PCODCLI                 IN PCPRESTANTECIPADA.CODCLI%TYPE,
                                        PNUMPED                 IN PCPRESTANTECIPADA.NUMPED%TYPE,
                                        PVALOR                  IN PCPRESTANTECIPADA.VALOR%TYPE,
                                        PNUMTRANSPAGOADIANTADO  IN PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                        PMATRICULAESTORNO       IN PCPRESTANTECIPADA.MATRICULAESTORNO%TYPE,
                                        PEXECUTACOMMITROLLBACK  IN VARCHAR2 DEFAULT 'S'
                                        )
    IS
        VCODCLI PCPRESTANTECIPADA.CODCLI%TYPE;
        VNUMPED PCPRESTANTECIPADA.NUMPED%TYPE;
        VVALOR PCPRESTANTECIPADA.VALOR%TYPE;
        VNUMTRANS PCPRESTANTECIPADA.NUMTRANS%TYPE;
        VNUMTRANSPAGOADIANTADO PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE;
    BEGIN
        PSTATUS := 'OK';
        PMENSAGEM := '[ERA01] - Recebimento antecipado estornado com sucesso';

        IF (PCODCLI <= 0) OR (PCODCLI IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA02] - Necessário informar o código do cliente.';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        IF (PNUMPED <= 0) OR (PNUMPED IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA03] - Necessário informar o número do pedido.';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        IF (PVALOR <= 0) OR (PVALOR IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA04] - Necessário informar o valor do estorno';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        IF (PNUMTRANSPAGOADIANTADO <= 0) OR (PNUMTRANSPAGOADIANTADO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA05] - Necessário informar o código do recebimento antecipado.';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        IF (PMATRICULAESTORNO <= 0) OR (PMATRICULAESTORNO IS NULL) THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA06] - Necessário informar a matrícula do usuário que confirmou o estorno.';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        BEGIN
            SELECT NUMTRANSPAGADIANTADO,
                   CODCLI,
                   NUMPED,
                   NUMTRANS,
                   VALOR
              INTO VNUMTRANSPAGOADIANTADO,
                   VCODCLI,
                   VNUMPED,
                   VNUMTRANS,
                   VVALOR
              FROM PCPRESTANTECIPADA
             WHERE NUMTRANSPAGADIANTADO = PNUMTRANSPAGOADIANTADO
               AND CODCLI = PCODCLI
               AND NUMPED = PNUMPED;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                VNUMTRANSPAGOADIANTADO := 0;
                VCODCLI := 0;
                VNUMPED := 0;
                VNUMTRANS := 0;
                VVALOR := 0;
        END;

        IF VNUMTRANSPAGOADIANTADO = 0 THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA07] - Recebimento antecipado não encontrado com o código ' || PNUMTRANSPAGOADIANTADO || '.';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        IF PVALOR > VVALOR THEN
            PSTATUS := 'Erro';
            PMENSAGEM := '[ERA08] - O valor informado para estorno de recebimento antecipado é maior que o valor do documento.';
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            RETURN;
        END IF;

        SOLICITA_CANCELAMENTO(PMENSAGEM, PNUMTRANSPAGOADIANTADO, PMATRICULAESTORNO);

        IF PMENSAGEM <> '[SC06] - Cancelamento concluído com sucesso' THEN
            RAISE_APPLICATION_ERROR(-20001, '[ERA09] - '||PMENSAGEM);
        END IF;

        ESTORNO_RECEBIMENTO(PMENSAGEM, PNUMTRANSPAGOADIANTADO, PMATRICULAESTORNO);

        IF PEXECUTACOMMITROLLBACK = 'S' THEN
            COMMIT WORK;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF PEXECUTACOMMITROLLBACK = 'S' THEN
                ROLLBACK;
            END IF;
            PMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, '[ERA10] - Erro ao estornar recebimento antecipado. Log recebido: (' || PMENSAGEM || ')');
    END; --ESTORNAR_RECEBIMENTO_ANTECIPADO
END;