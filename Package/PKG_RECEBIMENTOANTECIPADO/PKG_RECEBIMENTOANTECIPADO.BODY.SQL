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
               AND NVL(NUMPED,NUMORCA) = PNUMPED;

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
    PROCEDURE SOLICITA_CANCELAMENTO(PMENSAGEM   OUT VARCHAR2,
                                    PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                    PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                                    PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                                    )
    IS
        VNUMTRANSPAGADIANTADO PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE;
        VUSUARIO              PCEMPR.USUARIOBD%TYPE;
        VMATRICULA            PCPRESTANTECIPADA.MATRICULAESTORNO%TYPE;
        VMENSAGEM             VARCHAR2(300);
        VPOSICAO              PCPEDC.POSICAO%TYPE;
        VPERMISSAO            VARCHAR2(1);
        VACESSO               PCCONTROI.ACESSO%TYPE;
    BEGIN
       
        VUSUARIO  := SYS_CONTEXT('USERENV', 'OS_USER');
        PMENSAGEM := 'Pagamento antecipado não encontrado!';
       
        SELECT PCEMPR.MATRICULA
          INTO VMATRICULA
          FROM PCEMPR
         WHERE UPPER(PCEMPR.USUARIOBD) = UPPER(VUSUARIO);

        BEGIN
          SELECT NVL(PCCONTROI.ACESSO,'N')
            INTO VACESSO
            FROM PCCONTROI                                     
               , PCROTINAI                                     
           WHERE PCCONTROI.CODROTINA   = 1295
             AND PCCONTROI.CODUSUARIO  = VMATRICULA
             AND PCROTINAI.CODCONTROLE = 2
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
            VMENSAGEM := 'Pagamento quitado e usuário sem permissão para estorno (530 - 1295 - Permitir efetuar estorno do pagamento digital). Processo não será concluído!';
            RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);                
            ROLLBACK;
        END IF;
         
        FOR DADOS IN (SELECT NUMTRANSPAGADIANTADO,             /*01*/
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
                             NUMTRANSESTORNO                   /*18*/
                        FROM PCPRESTANTECIPADA
                       WHERE CODFILIAL           = PCODFILIAL
                         AND CODCLI              = PCODCLI
                         AND NVL(NUMPED,NUMORCA) = PNUMPED)
        LOOP
            IF (DADOS.STATUSPGTO IN ('AGUARDANDO PAGAMENTO','PAGO')) THEN

                IF DADOS.STATUSPGTO = 'PAGO' THEN
                
                    SELECT POSICAO 
                      INTO VPOSICAO
                      FROM PCPEDC 
                     WHERE NUMPED = PNUMPED;               
                     
                    IF VPOSICAO IS NULL THEN
                        SELECT POSICAO 
                          INTO VPOSICAO
                          FROM PCORCAVENDAC 
                         WHERE NUMORCA = PNUMPED;
                    END IF;
                    
                    IF VPOSICAO IN ('M','L') THEN
                        VMENSAGEM := 'Não é possível cancelar pois o pedido já foi liberado. Para cancelar o pagamento, será necessário bloquear ou cancelar o pedido antes.';
                        RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);
                    END IF;
                    
                    IF VPOSICAO IN ('F') THEN 
                        VMENSAGEM := 'Não é possível cancelar pois o pedido já foi faturado.';
                        RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);
                    END IF;                
                    
                    IF VPERMISSAO = 'N' THEN
                        VMENSAGEM := 'Pagamento quitado e usuário sem permissão para estorno. Processo não será concluído.';
                        RAISE_APPLICATION_ERROR(-20001, VMENSAGEM);                
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
                                              (DADOS.VALOR*-1),                 /*08*/
                                              DADOS.VLRCREDITOABATIDO,          /*09*/
                                              DADOS.VALORPEDIDO,                /*10*/
                                              DADOS.CODCOBPGTO,                 /*11*/
                                              'CANCELADO',                      /*12*/
                                              DADOS.DTEMISSAOPED,               /*13*/
                                              DADOS.DTGERACAOPGTO,              /*14*/
                                              DADOS.MATRICULAGERACAO,           /*15*/
                                              VMATRICULA,                       /*16*/
                                              SYSDATE,                          /*17*/
                                              VNUMTRANSPAGADIANTADO);           /*18*/

                UPDATE PCPRESTANTECIPADA
                   SET MATRICULAESTORNO     = VMATRICULA,
                       DTESTORNO            = SYSDATE,
                       NUMTRANSESTORNO      = VNUMTRANSPAGADIANTADO,
                       STATUSPGTO           = 'CANCELADO'
                 WHERE NUMTRANSPAGADIANTADO = DADOS.NUMTRANSPAGADIANTADO;
                 
                 PMENSAGEM := 'Cancelamento concluído com sucesso';
                 
            END IF; 
            --------------------------------------------------------------------            
            
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, 'Erro no estorno do pagamento. Log recebido: ('||VMENSAGEM||')');    
    END; --SOLICITA_CANCELAMENTO
END;