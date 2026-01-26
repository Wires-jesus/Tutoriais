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
                                      P_ORCAMENTOEXCEDIDO     PCRATEIOCENTROCUSTO.ORCAMENTOEXCEDIDO%TYPE)
    IS
        G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN
        P_STATUS_OUT   := 200;
        G_ERROR        := '1.';
        P_MENSAGEM_OUT := 'Inserção realizada com sucesso!';
        G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTO('||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTO()||')'||
                    '                         VALUES(:RECNUM,
                                                     :CODCONTA,
                                                     :VALOR,
                                                     :PERCRATEIO,
                                                     :DTLANC,
                                                     :CONTRAPARTIDA,
                                                     :RECNUMPRINC,
                                                     :CODFILIAL,
                                                     :CODIGOCENTROCUSTO,
                                                     NULL,
                                                     NULL,
                                                     :ORCAMENTOEXCEDIDO)';
        G_ERROR := '2.';   
        EXECUTE IMMEDIATE G_SCRIPT
                    USING P_RECNUM,
                          P_CODCONTA,
                          P_VALOR,
                          P_PERCRATEIO,
                          P_DTLANC,
                          P_CONTRAPARTIDA,
                          P_RECNUMPRINC,
                          P_CODFILIAL,
                          P_CODIGOCENTROCUSTO,
                          P_ORCAMENTOEXCEDIDO;           
        
        G_ERROR := '3.';
        COMMIT WORK;
        
        EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
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
                                          P_ORCAMENTOEXCEDIDO     PCRATEIOCENTROCUSTO.ORCAMENTOEXCEDIDO%TYPE)
    IS
        G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
    BEGIN
        P_STATUS_OUT := 200;
        G_ERROR      := '1.';
        P_MENSAGEM_OUT := 'Inserção realizada com sucesso!';
        G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTOBLOQ('||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTOBLOQ()||')'||
                    '                             VALUES(:RECNUM,
                                                         :CODCONTA,
                                                         :VALOR,
                                                         :PERCRATEIO,
                                                         :DTLANC,
                                                         :CONTRAPARTIDA,
                                                         :RECNUMPRINC,
                                                         :CODFILIAL,
                                                         :CODIGOCENTROCUSTO,
                                                         NULL,
                                                         NULL,
                                                         :ORCAMENTOEXCEDIDO)';
        G_ERROR := '2.';   
        EXECUTE IMMEDIATE G_SCRIPT
                    USING P_RECNUM,
                          P_CODCONTA,
                          P_VALOR,
                          P_PERCRATEIO,
                          P_DTLANC,
                          P_CONTRAPARTIDA,
                          P_RECNUMPRINC,
                          P_CODFILIAL,
                          P_CODIGOCENTROCUSTO,
                          P_ORCAMENTOEXCEDIDO;            
        
        G_ERROR := '3.';
        COMMIT WORK;
        
        EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
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

            COMMIT WORK;                        
        END IF; --REPLICANCO PCLANCBLOQ         

        EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            G_MENSAGEM := SQLERRM;
            P_STATUS_OUT   := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na aprovação da suplementacao. Log recebido: ('||G_MENSAGEM||')');            
    END; --APROVA_SUPLEMENTACAO
    
    ----------------------------------------------------------------------------                                   
    PROCEDURE EXP_PCLANCBLOQ(P_STATUS_OUT	       OUT VARCHAR2,
                             P_MENSAGEM_OUT        OUT VARCHAR2,
                             P_RECNUM              PCLANC.RECNUM%TYPE)
    IS
        G_MENSAGEM                  VARCHAR2(300);
        G_SCRIPT                    VARCHAR2(9999); 
        G_ERROR                     VARCHAR2(10);
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
        COMMIT WORK;
        
        EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
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
        G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTO('||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTO()||')'||
                    '                         SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_PCRATEIOCENTROCUSTO()|| 
                    '                           FROM PCRATEIOCENTROCUSTOBLOQ 
                                               WHERE RECNUM = :RECNUM';
        G_ERROR := '2.';                                               
        EXECUTE IMMEDIATE G_SCRIPT USING P_RECNUM;
        
        G_ERROR := '3.';
        COMMIT WORK;
        
        EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            G_MENSAGEM   := SQLERRM;
            P_STATUS_OUT := '500';
            RAISE_APPLICATION_ERROR(-20001, G_ERROR || ' Erro na Exportação da PCRATEIOCENTROCUSTOBLOQ. Log recebido: ('||G_MENSAGEM||')');            
    END; --EXP_PCRATEIOCENTROCUSTOBLOQ
    
END;