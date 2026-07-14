CREATE OR REPLACE PACKAGE BODY PKG_FINANCEIRO
IS
    ----------------------------------------------------------------------------
    PROCEDURE INS_PCRATEIOCENTROCUSTO(P_STATUS_OUT	          OUT VARCHAR2,
                                      P_MENSAGEM_OUT          OUT VARCHAR2,
                                      P_RECNUM                PCRATEIOCENTROCUSTO.RECNUM%TYPE,     
                                      P_CODCONTA              PCRATEIOCENTROCUSTO.CODCONTA%TYPE,
                                      P_CODIGOCENTROCUSTO     PCRATEIOCENTROCUSTO.CODIGOCENTROCUSTO%TYPE,
                                      P_VALOR                 PCRATEIOCENTROCUSTO.VALOR%TYPE,
                                      P_PERCRATEIO            PCRATEIOCENTROCUSTO.PERCRATEIO%TYPE,
                                      P_DTLANC                PCRATEIOCENTROCUSTO.DTLANC%TYPE,
                                      P_CONTRAPARTIDA         PCRATEIOCENTROCUSTO.CONTRAPARTIDA%TYPE,
                                      P_RECNUMPRINC           PCRATEIOCENTROCUSTO.RECNUMPRINC%TYPE,
                                      P_CODFILIAL             PCRATEIOCENTROCUSTO.CODFILIAL%TYPE,
                                      P_ORCAMENTOEXCEDIDO     PCRATEIOCENTROCUSTO.ORCAMENTOEXCEDIDO%TYPE,
                                      P_NUMTRANSPISCOFINS     PCRATEIOCENTROCUSTO.NUMTRANSPISCOFINS%TYPE,
                                      P_RECNUMREF             PCRATEIOCENTROCUSTO.RECNUMREF%TYPE,
                                      P_PERCRATCONTREF        PCRATEIOCENTROCUSTO.PERCRATCONTREF%TYPE,
                                      P_TIPOTRIB              PCRATEIOCENTROCUSTO.TIPOTRIB%TYPE,
                                      P_LANCIMPRETIDO         PCRATEIOCENTROCUSTO.LANCIMPRETIDO%TYPE)
    IS
        G_MENSAGEM     VARCHAR2(300);
        G_SCRIPT       VARCHAR2(9999); 
        G_ERROR        VARCHAR2(10);
    BEGIN
    
        ADDLOG('INS_PCRATEIOCENTROCUSTO','INICIO');
    
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Inserção realizada com sucesso!';
        G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTO('||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTO()||')'||
                    '                         VALUES(:RECNUM,
                                                     :CODCONTA,
													 :CODIGOCENTROCUSTO,
                                                     :VALOR,                                                     
													 :PERCRATEIO,
                                                     :DTLANC,
                                                     :CONTRAPARTIDA,
                                                     :RECNUMPRINC,
                                                     :CODFILIAL,
													 :ORCAMENTOEXCEDIDO,
													 :NUMTRANSPISCOFINS,
													 :RECNUMREF,
													 :PERCRATCONTREF,
													 :TIPOTRIB,
													 :LANCIMPRETIDO)';
        G_ERROR := '2.';   
        EXECUTE IMMEDIATE G_SCRIPT
                    USING P_RECNUM                
                         ,P_CODCONTA              
                         ,P_CODIGOCENTROCUSTO     
                         ,P_VALOR                 
                         ,P_PERCRATEIO            
                         ,P_DTLANC                
                         ,P_CONTRAPARTIDA         
                         ,P_RECNUMPRINC           
                         ,P_CODFILIAL             
                         ,P_ORCAMENTOEXCEDIDO     
                         ,P_NUMTRANSPISCOFINS     
                         ,P_RECNUMREF             
                         ,P_PERCRATCONTREF        
                         ,P_TIPOTRIB              
                         ,P_LANCIMPRETIDO;         
        G_ERROR := '3.';
                
        ADDLOG('INS_PCRATEIOCENTROCUSTO','FIM');
        
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            
            ADDLOG('INS_PCRATEIOCENTROCUSTO','ERROR: ' || G_MENSAGEM);
            
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na INSERÇÃO da PCRATEIOCENTROCUSTO. Log recebido: ('||G_MENSAGEM||')');        
    END; -- INS_PCRATEIOCENTROCUSTO
    
    ----------------------------------------------------------------------------
    PROCEDURE INS_PCRATEIOCENTROCUSTOBLOQ(P_STATUS_OUT	          OUT VARCHAR2,
                                          P_MENSAGEM_OUT          OUT VARCHAR2,
                                          P_RECNUM                PCRATEIOCENTROCUSTO.RECNUM%TYPE,     
                                          P_CODCONTA              PCRATEIOCENTROCUSTO.CODCONTA%TYPE,
                                          P_CODIGOCENTROCUSTO     PCRATEIOCENTROCUSTO.CODIGOCENTROCUSTO%TYPE,
                                          P_VALOR                 PCRATEIOCENTROCUSTO.VALOR%TYPE,
                                          P_PERCRATEIO            PCRATEIOCENTROCUSTO.PERCRATEIO%TYPE,
                                          P_DTLANC                PCRATEIOCENTROCUSTO.DTLANC%TYPE,
                                          P_CONTRAPARTIDA         PCRATEIOCENTROCUSTO.CONTRAPARTIDA%TYPE,
                                          P_RECNUMPRINC           PCRATEIOCENTROCUSTO.RECNUMPRINC%TYPE,
                                          P_CODFILIAL             PCRATEIOCENTROCUSTO.CODFILIAL%TYPE,
                                          P_ORCAMENTOEXCEDIDO     PCRATEIOCENTROCUSTO.ORCAMENTOEXCEDIDO%TYPE,
                                          P_NUMTRANSPISCOFINS     PCRATEIOCENTROCUSTO.NUMTRANSPISCOFINS%TYPE,
                                          P_RECNUMREF             PCRATEIOCENTROCUSTO.RECNUMREF%TYPE,
                                          P_PERCRATCONTREF        PCRATEIOCENTROCUSTO.PERCRATCONTREF%TYPE,
                                          P_TIPOTRIB              PCRATEIOCENTROCUSTO.TIPOTRIB%TYPE,
                                          P_LANCIMPRETIDO         PCRATEIOCENTROCUSTO.LANCIMPRETIDO%TYPE)
    IS
        G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN
    
        ADDLOG('INS_PCRATEIOCENTROCUSTOBLOQ','INICIO');
    
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Inserção realizada com sucesso!';
        G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTOBLOQ('||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTOBLOQ()||')'||
                    '                        	  VALUES(:RECNUM,
                                                         :CODCONTA,
											 		     :CODIGOCENTROCUSTO,
                                                         :VALOR,                                                     
											 		     :PERCRATEIO,
                                                         :DTLANC,
                                                         :CONTRAPARTIDA,
                                                         :RECNUMPRINC,
                                                         :CODFILIAL,
											 		     :ORCAMENTOEXCEDIDO)';
        G_ERROR := '2.';   
        EXECUTE IMMEDIATE G_SCRIPT
                    USING P_RECNUM                
                         ,P_CODCONTA              
                         ,P_CODIGOCENTROCUSTO     
                         ,P_VALOR                 
                         ,P_PERCRATEIO            
                         ,P_DTLANC                
                         ,P_CONTRAPARTIDA         
                         ,P_RECNUMPRINC           
                         ,P_CODFILIAL             
                         ,P_ORCAMENTOEXCEDIDO;            
        
        G_ERROR := '3.';
        
        ADDLOG('INS_PCRATEIOCENTROCUSTOBLOQ','FIM');
        
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            
            ADDLOG('INS_PCRATEIOCENTROCUSTOBLOQ','ERROR: ' || G_MENSAGEM);
            
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na INSERÇÃO da PCRATEIOCENTROCUSTOBLOQ. Log recebido: ('||G_MENSAGEM||')');            
    END; --INS_PCRATEIOCENTROCUSTOBLOQ
    
    ----------------------------------------------------------------------------
    PROCEDURE APROVAR_SUPLEMENTACAO(P_STATUS_OUT            OUT VARCHAR2,
                                    P_MENSAGEM_OUT          OUT VARCHAR2,
                                    P_RECNUM                PCLANC.RECNUM%TYPE,
                                    P_MATRICULA             PCLANC.CODFUNCAUTSUPLORC%TYPE)
    IS
        G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN

        ADDLOG('APROVAR_SUPLEMENTACAO','INICIO');

        /* RETORNOS DOS STATUS
        200 - Sucesso
        204 - Não encontrado
        500 - Error */

        P_STATUS_OUT   := '200';
        
        --REPLICANCO PCLANCBLOQ 
        G_ERROR := '1.';
        IF NOT (PKG_FINANCEIRO_SCRIPTS.TEM_PCLANCBLOQ(P_RECNUM)) THEN
           P_STATUS_OUT   := '204';
           P_MENSAGEM_OUT := 'RecNum: '||P_RECNUM||' não encontrado na tabela PCLANCBLOQ !';
        ELSE 
           G_ERROR  := '1.1';
           PKG_FINANCEIRO.EXP_PCLANCBLOQ(P_STATUS_OUT,
                                         P_MENSAGEM_OUT,
                                         P_RECNUM);
            G_ERROR := '1.2';
            UPDATE PCLANC                                 
               SET CODFUNCAUTSUPLORC = P_MATRICULA
                  ,DATAAUTSUPLORC    = SYSDATE
             WHERE RECNUM            = P_RECNUM;

            --Buscando PCRATEIOCENTROCUSTOBLOQ
            G_ERROR      := '2.';
            IF (PKG_FINANCEIRO_SCRIPTS.TEM_PCRATEIOCENTROCUSTOBLOQ(P_RECNUM)) THEN
                G_ERROR  := '2.1';
                PKG_FINANCEIRO.EXP_PCRATEIOCENTROCUSTOBLOQ(P_STATUS_OUT,
                                                           P_MENSAGEM_OUT,
                                                           P_RECNUM);
                G_ERROR := '2.2';
                UPDATE PCRATEIOCENTROCUSTO                     
                   SET CODFUNCAUTSUPLORC  = P_MATRICULA
                      ,DATAAUTSUPLORC     = SYSDATE
                 WHERE RECNUM             = P_RECNUM;

            END IF; --REPLICANDO PCRATEIOCENTROCUSTO
            
            --Excluindo PCRETEIOCENTROCUSTOBLOQ
            G_ERROR := '3.';
            DELETE FROM PCRATEIOCENTROCUSTOBLOQ
             WHERE RECNUM = P_RECNUM;

            --Excluindo PCLANCBLOQ
            G_ERROR := '4.';
            DELETE FROM PCLANCBLOQ
             WHERE RECNUM = P_RECNUM;

            P_MENSAGEM_OUT := 'Suplementação Aprovada!';

        END IF; --REPLICANCO PCLANCBLOQ         

        ADDLOG('APROVAR_SUPLEMENTACAO','FIM');

        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
            
            ADDLOG('APROVAR_SUPLEMENTACAO','ERROR: ' || G_MENSAGEM);
            
            P_STATUS_OUT   := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na aprovação da suplementacao. Log recebido: ('||G_MENSAGEM||')');            
    END; --APROVA_SUPLEMENTACAO
    
    ----------------------------------------------------------------------------                                   
    PROCEDURE EXP_PCLANCBLOQ(P_STATUS_OUT	       OUT VARCHAR2,
                             P_MENSAGEM_OUT        OUT VARCHAR2,
                             P_RECNUM              PCLANC.RECNUM%TYPE)
    IS
        G_MENSAGEM   VARCHAR2(300);
        G_SCRIPT     VARCHAR2(9999); 
        G_ERROR      VARCHAR2(10);
    BEGIN
    
        ADDLOG('EXP_PCLANCBLOQ','INICIO');
    
        P_STATUS_OUT := 200;
        G_ERROR      := '1.';
        P_MENSAGEM_OUT := 'Inserção realizada com sucesso!';
        G_SCRIPT := 'INSERT INTO PCLANC('||PKG_FINANCEIRO_SCRIPTS.GET_PCLANC()||')'||
                    '            SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_PCLANC()||
                    '              FROM PCLANCBLOQ 
                                  WHERE RECNUM = :RECNUM';
           
        G_ERROR := '2.';   
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;            
        
        G_ERROR := '3.';
        
        ADDLOG('EXP_PCLANCBLOQ','FIM');
        
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            
            ADDLOG('EXP_PCLANCBLOQ','ERROR: ' || G_MENSAGEM);
            
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na Exportação da PCLANCBLOQ. Log recebido: ('||G_MENSAGEM||')');            
    END; --EXP_PCLANCBLOQ
    
    ----------------------------------------------------------------------------                                   
    PROCEDURE EXP_PCRATEIOCENTROCUSTOBLOQ(P_STATUS_OUT	       OUT VARCHAR2,
                                          P_MENSAGEM_OUT       OUT VARCHAR2,
                                          P_RECNUM             PCLANC.RECNUM%TYPE)
    IS
        G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN
        
        ADDLOG('EXP_PCRATEIOCENTROCUSTOBLOQ','INICIO');
        
        P_STATUS_OUT := 200;
        G_ERROR      := '1.';
        P_MENSAGEM_OUT := 'Inserção realizada com sucesso!';
        G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTO('||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTOBLOQ()||')'||
                    '                         SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTOBLOQ()|| 
                    '                           FROM PCRATEIOCENTROCUSTOBLOQ 
                                               WHERE RECNUM = :RECNUM';
        G_ERROR := '2.';                                               
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;
        
        G_ERROR := '3.';
        
        ADDLOG('EXP_PCRATEIOCENTROCUSTOBLOQ','FIM');
        
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            
            ADDLOG('EXP_PCRATEIOCENTROCUSTOBLOQ','ERROR: ' || G_MENSAGEM);
            
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na Exportação da PCRATEIOCENTROCUSTOBLOQ. Log recebido: ('||G_MENSAGEM||')');            
    END; --EXP_PCRATEIOCENTROCUSTOBLOQ
    
    ----------------------------------------------------------------------------                                   
	PROCEDURE DEL_PCRATEIOCENTROCUSTO(P_STATUS_OUT	       OUT VARCHAR2,
									  P_MENSAGEM_OUT       OUT VARCHAR2,
									  P_RECNUM             PCLANC.RECNUM%TYPE)
    IS										
		G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN
        
        ADDLOG('DEL_PCRATEIOCENTROCUSTO','INICIO');
    
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Exclusão realizada com sucesso!';
		G_SCRIPT       := 'DELETE FROM PCRATEIOCENTROCUSTO WHERE RECNUM = :RECNUM';
		
		G_ERROR := '2.';                                               
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;
        
        G_ERROR := '3.';
        
        ADDLOG('DEL_PCRATEIOCENTROCUSTO','FIM');
        
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            
            ADDLOG('DEL_PCRATEIOCENTROCUSTO','ERROR: ' || G_MENSAGEM);
            
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na Exclusão da PCRATEIOCENTROCUSTO. Log recebido: ('||G_MENSAGEM||')');            
	END;
	----------------------------------------------------------------------------
    PROCEDURE DEL_PCRATEIOCENTROCUSTOBLOQ(P_STATUS_OUT	      OUT VARCHAR2,
									      P_MENSAGEM_OUT      OUT VARCHAR2,
									      P_RECNUM            PCLANC.RECNUM%TYPE)
    IS										
		G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN
    
        ADDLOG('DEL_PCRATEIOCENTROCUSTOBLOQ','INICIO');    
        
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Exclusão realizada com sucesso!';
		G_SCRIPT       := 'DELETE FROM PCRATEIOCENTROCUSTOBLOQ WHERE RECNUM = :RECNUM';
		
		G_ERROR := '2.';                                               
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;
        
        G_ERROR := '3.';
        
        ADDLOG('DEL_PCRATEIOCENTROCUSTOBLOQ','FIM');
        
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            
            ADDLOG('DEL_PCRATEIOCENTROCUSTOBLOQ','ERROR: ' || G_MENSAGEM);    
            
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na Exclusão da PCRATEIOCENTROCUSTO. Log recebido: ('||G_MENSAGEM||')');            
	END; 
    ----------------------------------------------------------------------------
    PROCEDURE ADDLOG(P_FONTE IN VARCHAR2,
                     P_LOG IN VARCHAR2)
    IS                 
        PRAGMA AUTONOMOUS_TRANSACTION;
        G_MENSAGEM                  VARCHAR2(300);
    BEGIN
        INSERT INTO PCMONITORAMENTO(SEQUENCIA,
                                    ROTINA,
                                    FONTE,
                                    DATA,
                                    HORA,
                                    LOG,
                                    EQUIPAMENTO,
                                    USUARIO
                                    )
                             VALUES(DFSEQ_PCMONITORAMENTO.NEXTVAL,
                                    SYS_CONTEXT('USERENV','MODULE'),
                                    P_FONTE,
                                    TRUNC(SYSDATE),
                                    TO_CHAR(SYSDATE, 'HH24:MI:SS'),
                                    P_LOG,
                                    SUBSTR(SYS_CONTEXT('USERENV','TERMINAL'),1,2000),
                                    SUBSTR(SYS_CONTEXT('USERENV','OS_USER'),1,2000));      
        COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
            RAISE_APPLICATION_ERROR(-20001, '200 - Erro na Exclusão da ADDLOG. Log recebido: ('||G_MENSAGEM||')');            
    END;
    
    ----------------------------------------------------------------------------    
    PROCEDURE PROCESSA_RECEBIMENTO_JD(P_OLD_DTPAG             IN PCPREST.DTPAG%TYPE,
                                      P_NEW_DTPAG             IN PCPREST.DTPAG%TYPE,
                                      P_NEW_CODCOB            IN PCPREST.CODCOB%TYPE,
                                      P_NEW_DTESTORNO         IN PCPREST.DTESTORNO%TYPE,
                                      P_NUMTRANSVENDA         IN PCPREST.NUMTRANSVENDA%TYPE,
                                      P_PREST                 IN PCPREST.PREST%TYPE,
                                      P_CODCLI                IN PCPREST.CODCLI%TYPE,
                                      P_CODFILIAL             IN PCPREST.CODFILIAL%TYPE,
                                      P_VPAGO                 IN PCPREST.VPAGO%TYPE,
                                      P_VALORMULTA            IN PCPREST.VALORMULTA%TYPE,
                                      P_VALORJUROS            IN PCPREST.TXPERM%TYPE,
                                      P_VALORDESC             IN PCPREST.VALORDESC%TYPE,
                                      P_DTPAG                 IN PCPREST.DTPAG%TYPE,
                                      P_NUMTRANSVENDAORIG     IN PCPREST.NUMTRANSVENDAORIG%TYPE,
                                      P_PRESTORIG             IN PCPREST.PRESTORIG%TYPE)
    IS
    BEGIN
    
        ADDLOG('PROCESSA_RECEBIMENTO_JD','INICIO - NUMTRANSVENDA: ' || P_NUMTRANSVENDA);
        
        ------------------------------------------------------------------------
        -- Estorno
        ------------------------------------------------------------------------
        IF P_NEW_CODCOB = 'ESTR' AND P_NEW_DTESTORNO IS NOT NULL THEN    
            DEL_PCRECEBIMENTOJUROSDESCONTO(P_NUMTRANSVENDA,
                                           P_PREST,
                                           P_CODCLI,
                                           P_CODFILIAL);            
            RETURN;
        END IF;
    
        ------------------------------------------------------------------------
        -- Não houve baixa
        ------------------------------------------------------------------------
        IF P_OLD_DTPAG IS NOT NULL OR P_NEW_DTPAG IS NULL THEN
            RETURN;
        END IF;
    
        ------------------------------------------------------------------------
        -- Cobranças ignoradas
        ------------------------------------------------------------------------
        IF P_NEW_CODCOB IN ('DESD','DEVP','DEVT','CANC','ESTR') THEN
            RETURN;
        END IF;
    
        ------------------------------------------------------------------------
        -- Sem juros/multa/desconto
        ------------------------------------------------------------------------
        IF NVL(P_VALORJUROS,0) = 0 AND NVL(P_VALORMULTA,0) = 0 AND NVL(P_VALORDESC,0) = 0 THEN
            RETURN;
        END IF;
    
        INS_PCRECEBIMENTOJUROSDESCONTO(P_NUMTRANSVENDA,
                                       P_PREST,
                                       P_CODCLI,
                                       P_CODFILIAL,
                                       P_VPAGO,
                                       P_VALORMULTA,
                                       P_VALORJUROS,
                                       P_VALORDESC,
                                       P_DTPAG,
                                       P_NUMTRANSVENDAORIG,
                                       P_PRESTORIG);
                                       
        ADDLOG('PROCESSA_RECEBIMENTO_JD','FIM');  
        
    END;
    ----------------------------------------------------------------------------
    PROCEDURE INS_PCRECEBIMENTOJUROSDESCONTO(P_NUMTRANSVENDA         IN PCPREST.NUMTRANSVENDA%TYPE,
                                             P_PREST                 IN PCPREST.PREST%TYPE,
                                             P_CODCLI                IN PCPREST.CODCLI%TYPE,
                                             P_CODFILIAL             IN PCPREST.CODFILIAL%TYPE,
                                             P_VPAGO                 IN PCPREST.VPAGO%TYPE,
                                             P_VALORMULTA            IN PCPREST.VALORMULTA%TYPE,
                                             P_VALORJUROS            IN PCPREST.TXPERM%TYPE,
                                             P_VALORDESC             IN PCPREST.VALORDESC%TYPE,
                                             P_DTPAG                 IN PCPREST.DTPAG%TYPE,
                                             P_NUMTRANSVENDAORIG     IN PCPREST.NUMTRANSVENDAORIG%TYPE,
                                             P_PRESTORIG             IN PCPREST.PRESTORIG%TYPE)
    IS
        G_MENSAGEM VARCHAR2(4000);
    BEGIN
    
        ADDLOG('INS_PCRECEBIMENTOJUROSDESCONTO','INICIO - NUMTRANSVENDA: ' || P_NUMTRANSVENDA);  
        
        INSERT INTO PCRECEBIMENTOJUROSDESCONTO(NUMTRANSVENDA,
                                               PREST,
                                               CODCLI,
                                               CODFILIAL,
                                               VPAGO,
                                               VALORMULTA,
                                               VALORJUROS,
                                               VALORDESC,
                                               DTPAG,
                                               NUMTRANSVENDAORIG,
                                               PRESTORIG,
                                               GERADONF)
                                        VALUES(P_NUMTRANSVENDA,
                                               P_PREST,
                                               P_CODCLI,
                                               P_CODFILIAL,
                                               P_VPAGO,
                                               P_VALORMULTA,
                                               P_VALORJUROS,
                                               P_VALORDESC,
                                               TRUNC(P_DTPAG),
                                               P_NUMTRANSVENDAORIG,
                                               P_PRESTORIG,
                                               NULL);
                                               
        ADDLOG('INS_PCRECEBIMENTOJUROSDESCONTO','FIM');
        
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
            
            ADDLOG('INS_PCRECEBIMENTOJUROSDESCONTO','ERROR: '||G_MENSAGEM);      
            
            RAISE_APPLICATION_ERROR(-20001,'Erro na INS_PCRECEBIMENTOJUROSDESCONTO. ('||G_MENSAGEM||')');
    
    END;
    ----------------------------------------------------------------------------
    PROCEDURE DEL_PCRECEBIMENTOJUROSDESCONTO(P_NUMTRANSVENDA IN PCPREST.NUMTRANSVENDA%TYPE,
                                             P_PREST         IN PCPREST.PREST%TYPE,
                                             P_CODCLI        IN PCPREST.CODCLI%TYPE,
                                             P_CODFILIAL     IN PCPREST.CODFILIAL%TYPE)
    IS
        G_MENSAGEM VARCHAR2(4000);
    BEGIN
    
        ADDLOG('DEL_PCRECEBIMENTOJUROSDESCONTO','INICIO - NUMTRANSVENDA: ' || P_NUMTRANSVENDA);
        
        DELETE
          FROM PCRECEBIMENTOJUROSDESCONTO
         WHERE NUMTRANSVENDA     = P_NUMTRANSVENDA
           AND PREST             = P_PREST
           AND CODCLI            = P_CODCLI
           AND CODFILIAL         = P_CODFILIAL
           AND NVL(GERADONF,'N') = 'N';
           
        ADDLOG('DEL_PCRECEBIMENTOJUROSDESCONTO','FIM');
        
    EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
            
            ADDLOG('DEL_PCRECEBIMENTOJUROSDESCONTO','ERROR: ' || G_MENSAGEM);
            
            RAISE_APPLICATION_ERROR(-20001,'Erro na DEL_PCRECEBIMENTOJUROSDESCONTO. ('||G_MENSAGEM||')');
    
    END;
    ------------------------------------------------------------------------------
    PROCEDURE PROCESSA_PAGAMENTO_JD(P_RECNUM               IN PCLANC.RECNUM%TYPE,
                                    P_NUMNOTA              IN PCLANC.NUMNOTA%TYPE,
                                    P_CODFILIAL            IN PCLANC.CODFILIAL%TYPE,
                                    P_DUPLIC               IN PCLANC.DUPLIC%TYPE,
                                    P_PREST                IN PCLANC.PREST%TYPE,
                                    P_CODFORNEC            IN PCLANC.CODFORNEC%TYPE,
                                    P_VPAGOBORDERO         IN PCLANC.VPAGOBORDERO%TYPE,
                                    P_TXPERM               IN PCLANC.TXPERM%TYPE,
                                    P_DESCONTOFIN          IN PCLANC.DESCONTOFIN%TYPE,
                                    P_DTPAGTO              IN PCLANC.DTPAGTO%TYPE,
                                    P_RECNUMPRINC          IN PCLANC.RECNUMPRINC%TYPE,
                                    P_DTESTORNOBAIXA       IN PCLANC.DTESTORNOBAIXA%TYPE,
                                    P_DTCANCEL             IN PCLANC.DTCANCEL%TYPE,
                                    P_DTDESD               IN PCLANC.DTDESD%TYPE)
    IS
    
        V_EXISTE NUMBER;
        G_MENSAGEM VARCHAR2(4000);
        
    BEGIN
    
        ADDLOG('PROCESSA_PAGAMENTO_JD','INICIO - RECNUM: ' || P_RECNUM);
        
        --------------------------------------------------------------------------
        -- ESTORNO
        --------------------------------------------------------------------------
        IF P_DTESTORNOBAIXA IS NOT NULL THEN    
            DEL_PCPAGAMENTOJUROSDESCONTO(P_RECNUM);    
            RETURN;    
        END IF;
    
        --------------------------------------------------------------------------
        -- CANCELAMENTO
        --------------------------------------------------------------------------
        IF P_DTCANCEL IS NOT NULL THEN    
            DEL_PCPAGAMENTOJUROSDESCONTO(P_RECNUM);    
            RETURN;    
        END IF;
    
        --------------------------------------------------------------------------
        -- DESDOBRAMENTO
        --------------------------------------------------------------------------
        IF P_DTDESD IS NOT NULL THEN
            RETURN;
        END IF;
    
        --------------------------------------------------------------------------
        -- NÃO BAIXADO
        --------------------------------------------------------------------------
        IF P_DTPAGTO IS NULL THEN
            RETURN;
        END IF;
    
        --------------------------------------------------------------------------
        -- SEM JUROS E SEM DESCONTO
        --------------------------------------------------------------------------
        IF NVL(P_TXPERM,0) = 0 AND NVL(P_DESCONTOFIN,0) = 0 THEN    
            DEL_PCPAGAMENTOJUROSDESCONTO(P_RECNUM);   
            RETURN;    
        END IF;
    
        --------------------------------------------------------------------------
        -- BAIXA 100% DESCONTO
        --------------------------------------------------------------------------
        IF NVL(P_VPAGOBORDERO,0) = 0 THEN    
            DEL_PCPAGAMENTOJUROSDESCONTO(P_RECNUM);    
            RETURN;    
        END IF;
    
        --------------------------------------------------------------------------
        -- EXISTE REGISTRO?
        --------------------------------------------------------------------------
        SELECT COUNT(*)
          INTO V_EXISTE
          FROM PCPAGAMENTOJUROSDESCONTO
         WHERE RECNUM = P_RECNUM;
    
        --------------------------------------------------------------------------
        -- INSERE
        --------------------------------------------------------------------------
        IF V_EXISTE = 0 THEN
    
            INS_PCPAGAMENTOJUROSDESCONTO(P_RECNUM,
                                         P_NUMNOTA,
                                         P_CODFILIAL,
                                         P_DUPLIC,
                                         P_PREST,
                                         P_CODFORNEC,
                                         P_VPAGOBORDERO,
                                         P_TXPERM,
                                         P_DESCONTOFIN,
                                         TRUNC(P_DTPAGTO),
                                         NVL(P_RECNUMPRINC, P_RECNUM));
    
        ELSE
    
            ----------------------------------------------------------------------
            -- RECRIA O REGISTRO
            ----------------------------------------------------------------------
            DEL_PCPAGAMENTOJUROSDESCONTO(P_RECNUM);
    
            INS_PCPAGAMENTOJUROSDESCONTO(P_RECNUM,
                                         P_NUMNOTA,
                                         P_CODFILIAL,
                                         P_DUPLIC,
                                         P_PREST,
                                         P_CODFORNEC,
                                         P_VPAGOBORDERO,
                                         P_TXPERM,
                                         P_DESCONTOFIN,
                                         TRUNC(P_DTPAGTO),
                                         NVL(P_RECNUMPRINC, P_RECNUM));
    
        END IF;
    
        ADDLOG('PROCESSA_PAGAMENTO_JD','FIM');
        
    EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
            
            ADDLOG('PROCESSA_PAGAMENTO_JD','ERROR: ' || SQLERRM);
            
            RAISE_APPLICATION_ERROR(-20001,'Erro na PROCESSA_PAGAMENTO_JD: ' || SQLERRM);
    
    END PROCESSA_PAGAMENTO_JD;
    
    ------------------------------------------------------------------------------
    PROCEDURE INS_PCPAGAMENTOJUROSDESCONTO(P_RECNUM               IN PCPAGAMENTOJUROSDESCONTO.RECNUM%TYPE,
                                           P_NUMNOTA              IN PCPAGAMENTOJUROSDESCONTO.NUMNOTA%TYPE,
                                           P_CODFILIAL            IN PCPAGAMENTOJUROSDESCONTO.CODFILIAL%TYPE,
                                           P_DUPLIC               IN PCPAGAMENTOJUROSDESCONTO.DUPLIC%TYPE,
                                           P_PREST                IN PCPAGAMENTOJUROSDESCONTO.PREST%TYPE,
                                           P_CODFORNEC            IN PCPAGAMENTOJUROSDESCONTO.CODFORNEC%TYPE,
                                           P_VPAGO                IN PCPAGAMENTOJUROSDESCONTO.VPAGO%TYPE,
                                           P_VALORJUROS           IN PCPAGAMENTOJUROSDESCONTO.VALORJUROS%TYPE,
                                           P_VALORDESC            IN PCPAGAMENTOJUROSDESCONTO.VALORDESC%TYPE,
                                           P_DTPAG                IN PCPAGAMENTOJUROSDESCONTO.DTPAG%TYPE,
                                           P_RECNUMPRINC          IN PCPAGAMENTOJUROSDESCONTO.RECNUMPRINC%TYPE)
    IS
        G_MENSAGEM VARCHAR2(4000);
    BEGIN
    
        ADDLOG('INS_PCPAGAMENTOJUROSDESCONTO','INICIO - RECNUM: ' || P_RECNUM);
    
        INSERT INTO PCPAGAMENTOJUROSDESCONTO(RECNUM,
                                             NUMNOTA,
                                             CODFILIAL,
                                             DUPLIC,
                                             PREST,
                                             CODFORNEC,
                                             VPAGO,
                                             VALORJUROS,
                                             VALORDESC,
                                             DTPAG,
                                             RECNUMPRINC,
                                             GERADONF)
                                      VALUES(P_RECNUM,
                                             P_NUMNOTA,
                                             P_CODFILIAL,
                                             P_DUPLIC,
                                             P_PREST,
                                             P_CODFORNEC,
                                             P_VPAGO,
                                             P_VALORJUROS,
                                             P_VALORDESC,
                                             TRUNC(P_DTPAG),
                                             P_RECNUMPRINC,
                                             NULL);
                                             
        ADDLOG('INS_PCPAGAMENTOJUROSDESCONTO','FIM');                                             
    
    EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
            
            ADDLOG('INS_PCPAGAMENTOJUROSDESCONTO','ERROR: ' || G_MENSAGEM);
            
            RAISE_APPLICATION_ERROR(-20001,'Erro INS_PCPAGAMENTOJUROSDESCONTO: '|| SQLERRM);
    
    END INS_PCPAGAMENTOJUROSDESCONTO;
    
    ------------------------------------------------------------------------------
    PROCEDURE DEL_PCPAGAMENTOJUROSDESCONTO(P_RECNUM IN PCPAGAMENTOJUROSDESCONTO.RECNUM%TYPE)
    IS
        G_MENSAGEM VARCHAR2(4000);
    BEGIN
        
        ADDLOG('DEL_PCPAGAMENTOJUROSDESCONTO','INICIO - RECNUM: ' || P_RECNUM);
    
        DELETE 
          FROM PCPAGAMENTOJUROSDESCONTO
         WHERE RECNUM            = P_RECNUM
           AND NVL(GERADONF,'N') = 'N';

        ADDLOG('DEL_PCPAGAMENTOJUROSDESCONTO','FIM');
    
    EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
            
            ADDLOG('DEL_PCPAGAMENTOJUROSDESCONTO','ERROR: ' || G_MENSAGEM);
    
            RAISE_APPLICATION_ERROR(-20001,'Erro DEL_PCPAGAMENTOJUROSDESCONTO: '|| SQLERRM);
    
    END DEL_PCPAGAMENTOJUROSDESCONTO;
    
END;