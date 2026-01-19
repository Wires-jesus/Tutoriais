CREATE OR REPLACE PACKAGE BODY PKG_FINANCEIRO
IS
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
           G_SCRIPT := 'INSERT INTO PCLANC('||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCLANC()||')'||
                                  'SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCLANC()||
                                  '  FROM PCLANCBLOQ 
                                    WHERE RECNUM = '||P_RECNUM;
           
           EXECUTE IMMEDIATE G_SCRIPT;            

            G_ERROR := '1.2';
            UPDATE PCLANC                                 
               SET CODFUNCAUTSUPLORC = P_MATRICULA
                  ,DATAAUTSUPLORC    = SYSDATE
             WHERE RECNUM            = P_RECNUM;

            --Buscando PCRATEIOCENTROCUSTOBLOQ
            G_ERROR      := '2.';
            IF (PKG_FINANCEIRO_SCRIPTS.TEM_PCRATEIOCENTROCUSTOBLOQ(P_RECNUM)) THEN
                G_ERROR  := '2.1';          
                G_SCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTO('||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCRATEIOCENTROCUSTO()||')'||
                                                    'SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCRATEIOCENTROCUSTO()|| 
                                                    '  FROM PCRATEIOCENTROCUSTOBLOQ 
                                                      WHERE RECNUM = '||P_RECNUM;

                EXECUTE IMMEDIATE G_SCRIPT;            
                
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
END;