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
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
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
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
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

        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
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
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
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
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
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
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Exclusão realizada com sucesso!';
		G_SCRIPT       := 'DELETE FROM PCRATEIOCENTROCUSTO WHERE RECNUM = :RECNUM';
		
		G_ERROR := '2.';                                               
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;
        
        G_ERROR := '3.';
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
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
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Exclusão realizada com sucesso!';
		G_SCRIPT       := 'DELETE FROM PCRATEIOCENTROCUSTOBLOQ WHERE RECNUM = :RECNUM';
		
		G_ERROR := '2.';                                               
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;
        
        G_ERROR := '3.';
        EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM   := SQLERRM;
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
    
        ------------------------------------------------------------------------
        -- Estorno
        ------------------------------------------------------------------------
        IF P_NEW_CODCOB = 'ESTR'
           AND P_NEW_DTESTORNO IS NOT NULL THEN
    
            DEL_PCRECEBIMENTOJUROSDESCONTO(P_NUMTRANSVENDA,
                                           P_PREST,
                                           P_CODCLI,
                                           P_CODFILIAL);
            RETURN;
        END IF;
    
        ------------------------------------------------------------------------
        -- Não houve baixa
        ------------------------------------------------------------------------
        IF P_OLD_DTPAG IS NOT NULL
           OR P_NEW_DTPAG IS NULL THEN
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
    
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
    
            RAISE_APPLICATION_ERROR(
                -20001,
                'Erro na INS_PCRECEBIMENTOJUROSDESCONTO. ('||G_MENSAGEM||')'
            );
    
    END;
    ----------------------------------------------------------------------------
    PROCEDURE DEL_PCRECEBIMENTOJUROSDESCONTO(P_NUMTRANSVENDA IN PCPREST.NUMTRANSVENDA%TYPE,
                                             P_PREST         IN PCPREST.PREST%TYPE,
                                             P_CODCLI        IN PCPREST.CODCLI%TYPE,
                                             P_CODFILIAL     IN PCPREST.CODFILIAL%TYPE)
    IS
        G_MENSAGEM VARCHAR2(4000);
    BEGIN
    
        DELETE
          FROM PCRECEBIMENTOJUROSDESCONTO
         WHERE NUMTRANSVENDA     = P_NUMTRANSVENDA
           AND PREST             = P_PREST
           AND CODCLI            = P_CODCLI
           AND CODFILIAL         = P_CODFILIAL
           AND NVL(GERADONF,'N') = 'N';
    
    EXCEPTION
        WHEN OTHERS THEN
            G_MENSAGEM := SQLERRM;
    
            RAISE_APPLICATION_ERROR(
                -20001,
                'Erro na DEL_PCRECEBIMENTOJUROSDESCONTO. ('||G_MENSAGEM||')'
            );
    
    END;
END;