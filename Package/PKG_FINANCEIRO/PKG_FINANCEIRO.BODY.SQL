CREATE OR REPLACE PACKAGE BODY PKG_FINANCEIRO
IS
    ----------------------------------------------------------------------------
    PROCEDURE APROVAR_SUPLEMENTACAO(PSTATUS                OUT VARCHAR2,
                                    PMENSAGEM              OUT VARCHAR2,
                                    PRECNUM                PCLANC.RECNUM%TYPE,
                                    PMATRICULA             PCLANC.CODFUNCAUTSUPLORC%TYPE)
    IS
        VMENSAGEM                  VARCHAR2(300);
        VPROGRAMA                  VARCHAR2(30);
        VMSGPCMOVCR                PCRECFUNC.TEXTORECADO%TYPE;
        VSCRIPT                    VARCHAR2(9999); 
        VERROR                     VARCHAR2(10);
    BEGIN

        /* RETORNOS DOS STATUS
        200 - Sucesso
        204 - Não encontrado
        500 - Error */

        PSTATUS   := '200';
        PMENSAGEM := 'Suplementação não Aprovada!';
        VPROGRAMA := F_OBTERNOMEAPLICACAO;

        --REPLICANCO PCLANCBLOQ 
        VERROR := '1.';
        IF NOT (PKG_FINANCEIRO_SCRIPTS.TEM_PCLANCBLOQ(PRECNUM)) THEN
           PSTATUS   := '204';
           PMENSAGEM := 'RecNum: '||PRECNUM||' não encontrado na tabela PCLANCBLOQ !';
        ELSE 
           VERROR  := '1.1';
           VSCRIPT := 'INSERT INTO PCLANC('||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCLANC()||')'||
                                  'SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCLANC()||
                                  '  FROM PCLANCBLOQ 
                                    WHERE RECNUM = '||PRECNUM;
           
           EXECUTE IMMEDIATE VSCRIPT;            

            VERROR := '1.2';
            UPDATE PCLANC                                 
               SET CODFUNCAUTSUPLORC = PMATRICULA
                  ,DATAAUTSUPLORC    = SYSDATE
             WHERE RECNUM            = PRECNUM;

            --Buscando PCRATEIOCENTROCUSTOBLOQ
            VERROR      := '2.';
            VMSGPCMOVCR := '';
            IF (PKG_FINANCEIRO_SCRIPTS.TEM_PCRATEIOCENTROCUSTOBLOQ(PRECNUM)) THEN
                VERROR  := '2.1';          
                VSCRIPT := 'INSERT INTO PCRATEIOCENTROCUSTO('||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCRATEIOCENTROCUSTO()||')'||
                                                    'SELECT '||PKG_FINANCEIRO_SCRIPTS.GET_FIELDS_PCRATEIOCENTROCUSTO()|| 
                                                    '  FROM PCRATEIOCENTROCUSTOBLOQ 
                                                      WHERE RECNUM = '||PRECNUM;

                EXECUTE IMMEDIATE VSCRIPT;            
                
                VERROR := '2.2';
                UPDATE PCRATEIOCENTROCUSTO                     
                   SET CODFUNCAUTSUPLORC  = PMATRICULA
                      ,DATAAUTSUPLORC     = SYSDATE
                 WHERE RECNUM             = PRECNUM;

            END IF; --REPLICANDO PCRATEIOCENTROCUSTO
            
            --Excluindo PCRETEIOCENTROCUSTOBLOQ
            VERROR := '3.';
            DELETE FROM PCRATEIOCENTROCUSTOBLOQ
             WHERE RECNUM = PRECNUM;

            --Excluindo PCLANCBLOQ
            VERROR := '4.';
            DELETE FROM PCLANCBLOQ
             WHERE RECNUM = PRECNUM;

            PMENSAGEM := 'Suplementação Aprovada!';

            COMMIT WORK;                        
        END IF; --REPLICANCO PCLANCBLOQ         

        EXCEPTION
        WHEN OTHERS THEN
            VMENSAGEM := SQLERRM;
            PSTATUS   := '500';
            RAISE_APPLICATION_ERROR(-20001, VERROR || ' Erro na aprovação da suplementacao. Log recebido: ('||VMENSAGEM||')');            
    END; --APROVA_SUPLEMENTACAO
    ----------------------------------------------------------------------------                                   
END;