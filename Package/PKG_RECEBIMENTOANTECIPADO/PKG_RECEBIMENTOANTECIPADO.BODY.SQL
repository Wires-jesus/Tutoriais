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
             WHERE CODFILIAL           = PCODFILIAL
               AND CODCLI              = PCODCLI
               AND NVL(NUMORCA,NUMPED) = PNUMPED;

        RETURN VCURSOR;
    END;

    ----------------------------------------------------------------------------
    FUNCTION CONSULTA_PAGANTECIPADO(PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                    PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                                    PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                                    )
    RETURN TB_PCPRESTANTECIPADA
    PIPELINED
    IS
    DADOS_SAIDA T_PCPRESTANTECIPADA;
    VCURSOR     SYS_REFCURSOR;
    VMENSAGEM   VARCHAR2(300);
    BEGIN
        VMENSAGEM := 'Pagamento antecipado não encontrado';
        VCURSOR := DADOS_PCPRESTANTECIPADA(PCODFILIAL,PCODCLI,PNUMPED);

        LOOP
            FETCH VCURSOR INTO DADOS_SAIDA;
            EXIT WHEN VCURSOR%NOTFOUND;
            PIPE ROW(DADOS_SAIDA);
            VMENSAGEM := NULL;
        END LOOP;
        IF VMENSAGEM IS NOT NULL THEN 
          RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);        
        END IF;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);
    END; --CONSULTA_PAGANTECIPADO

    ----------------------------------------------------------------------------
    FUNCTION CONSULTA_STATUS(PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                             PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                             PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                             )
    RETURN TB_PCPRESTANTECIPADA
    PIPELINED
    IS
    DADOS_SAIDA T_PCPRESTANTECIPADA;
    VCURSOR  SYS_REFCURSOR;
    VMENSAGEM   VARCHAR2(300);
    BEGIN
        VMENSAGEM := 'Pagamento antecipado não encontrado!';
        VCURSOR := DADOS_PCPRESTANTECIPADA(PCODFILIAL,PCODCLI,PNUMPED);

        LOOP
            FETCH VCURSOR INTO DADOS_SAIDA;
            EXIT WHEN VCURSOR%NOTFOUND;
            PIPE ROW(DADOS_SAIDA);
            VMENSAGEM := NULL;
        END LOOP;
        IF VMENSAGEM IS NOT NULL THEN 
          RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);        
        END IF;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);
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

        PMENSAGEM := 'Pagamento antecipado não encontrado!';

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
            PMENSAGEM := 'Pagamento quitado e usuário sem permissão para estorno (530 - 1295 - Permitir efetuar estorno do pagamento digital). Processo não será concluído!';            
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

                    IF DADOS.NUMORCA IS NOT NULL THEN
                        SELECT POSICAO 
                          INTO VPOSICAO
                          FROM PCORCAVENDAC 
                         WHERE NUMORCA   = DADOS.NUMORCA
                           AND CODCLI    = DADOS.CODCLI
                           AND CODFILIAL = DADOS.CODFILIAL;
                    END IF;

                    IF VPOSICAO IS NULL THEN
						SELECT POSICAO 
						  INTO VPOSICAO
						  FROM PCPEDC 
						 WHERE NUMPED    = DADOS.NUMPED
                           AND CODCLI    = DADOS.CODCLI
                           AND CODFILIAL = DADOS.CODFILIAL;               
                    END IF;

                    IF VPOSICAO IN ('M','L') THEN
                        PMENSAGEM := 'Não é possível cancelar pois o pedido já foi liberado. Para cancelar o pagamento, será necessário bloquear ou cancelar o pedido antes.';
                        ROLLBACK;
                        RETURN;
                    END IF;

                    IF VPOSICAO IN ('F') THEN 
                        PMENSAGEM := 'Não é possível cancelar pois o pedido já foi faturado.';
                        ROLLBACK;
                        RETURN;
                    END IF;                

                    IF VPERMISSAO = 'N' THEN
                        PMENSAGEM := 'Pagamento quitado e usuário sem permissão para estorno. Processo não será concluído.';
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
                       STATUSPGTO           = 'CANCELADO'
                 WHERE NUMTRANSPAGADIANTADO = DADOS.NUMTRANSPAGADIANTADO;

                 PMENSAGEM := 'Cancelamento concluído com sucesso';

            END IF; 
            --------------------------------------------------------------------            

        END LOOP;
        COMMIT WORK;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, 'Erro no estorno do pagamento. Log recebido: ('||VMENSAGEM||')');    
    END; --SOLICITA_CANCELAMENTO

    ----------------------------------------------------------------------------
    PROCEDURE ATUALIZAR_STATUS(PMENSAGEM              OUT VARCHAR2,
                               PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
							   PMATRICULA     		  PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE)
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

        PMENSAGEM := 'Atualização realizada com sucesso!';     

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
                PMENSAGEM := 'Necessário informar o banco para baixa na ABA -> Pagamento Antecipado na 522';
                ROLLBACK;
                RETURN;
            END IF;               
            IF ((DADOS.CODMOEDACOBANTECIPADA IS NULL) AND (DADOS.QUITAPCPREST = 'S')) THEN
                PMENSAGEM := 'Necessário informar a moeda para baixa na ABA -> Pagamento Antecipado na 522';
                ROLLBACK;
                RETURN;
            END IF;           

            IF (DADOS.NUMTRANS = 0) THEN 
                SELECT NVL(PROXNUMTRANS,1)
                  INTO VNUMTRANS 
                  FROM PCCONSUM FOR UPDATE;
                UPDATE PCCONSUM
                   SET PROXNUMTRANS = NVL(PROXNUMTRANS,1)+1;
            ELSE
                VNUMTRANS := DADOS.NUMTRANS;
            END IF;

            COMMIT WORK;   

            IF (DADOS.NUMTRANS > 0) THEN            
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
                                    'B',
                                    'CREDITO PROVENIENTE DE PAGAMENTO ANTECIPADO (TRANSAÇÃO: '||PNUMTRANSPAGADIANTADO||')',
                                    1295,
                                    'N',
                                    DADOS.CODCLI,
                                    SYSDATE,
                                    VROTINA); 

            END IF; --VQUITAPCPREST

            IF (DADOS.NUMTRANS > 0) THEN
                SELECT COUNT(*)
                  INTO VOLDNUMTRANS
                  FROM PCCRECLI 
                 WHERE NUMTRANS = DADOS.NUMTRANS;
            END IF; 

            IF (VOLDNUMTRANS = 0) THEN
                INSERT INTO PCCRECLI(CODCLI,                                    /*01*/
                                     DTLANC,									/*02*/
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
                                  PMATRICULA     		 PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE)
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
        
        PMENSAGEM := 'Estorno realizado com sucesso!';     

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
        
            IF (DADOS.NUMTRANS <> 0) THEN 
                SELECT NVL(PROXNUMTRANS,1)
                  INTO VNUMTRANS 
                  FROM PCCONSUM FOR UPDATE;
                UPDATE PCCONSUM
                   SET PROXNUMTRANS = NVL(PROXNUMTRANS,1)+1;
            ELSE
                VNUMTRANS := DADOS.NUMTRANS;
            END IF;            

            SELECT VLSALDO 
              INTO VVLSALDO  
              FROM PCMOVCR
             WHERE NUMSEQ = (SELECT MAX(NUMSEQ) 
                               FROM PCMOVCR 
                              WHERE CODBANCO = DADOS.CODBCOCOBANTECIPADA
                                AND CODCOB   = DADOS.CODMOEDACOBANTECIPADA)
               FOR UPDATE;                                               

            COMMIT WORK;
               
            SELECT CODBANCO,CODCOB
              INTO VCODBANCO,VCODCOB
              FROM PCMOVCR 
             WHERE NUMTRANS = DADOS.NUMTRANS;

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
                                'B',
                                DADOS.NUMTRANSPAGADIANTADO,
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
                                 DTLANC,									    /*02*/
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
END;