CREATE OR REPLACE PACKAGE PKG_PATRIMONIO
IS 
  --Paramêtros de execução 
  type parametrosExecucao 
    is record ( CODFILIAL VARCHAR2(2) 
              , DTINICIO DATE 
              , DTFIM DATE 
              , GERA_NF_CANCELADAS VARCHAR2(1) 
              , NUMCASAS_QT NUMBER 
              , NUMCASAS_UNIT NUMBER 
              , EXIBITV14 VARCHAR2(1) 
              , CODFISCAL VARCHAR2(500) 
              , NUMNOTA1 NUMBER 
              , NUMNOTA2 NUMBER 
              , UTILIZOULISTAPRODUTO VARCHAR2(1) 
              , DESCONS_USOCONSUMO VARCHAR2(1) 
              , DESCONS_IMOBILIZADO VARCHAR2(1) 
              ); 

   --Execução complenta 
   PROCEDURE EXECUTAR               (parametros in parametrosExecucao); 
   --Listando entradas 
   PROCEDURE OBTERENTRADAS          (parametros in parametrosExecucao); 
   --Listando entradas canceladas 
   PROCEDURE OBTERENTRADASCANCELADAS(parametros in parametrosExecucao); 
   --Listando entradas de produção 
   PROCEDURE OBTERENTRADASPRODUCAO  (parametros in parametrosExecucao); 
   --Listando entradas de produção 
   PROCEDURE OBTERENTRADASPRODUCAO_CANC (parametros in parametrosExecucao); 
   --Listando ajustes de custo pela movimentação de importação.  
   PROCEDURE OBTERENTRADASAJUSTECUSTO (parametros in parametrosExecucao); 
   --Listando saídas 
   PROCEDURE OBTERSAIDAS            (parametros in parametrosExecucao); 
   --Listando saídas canceladas 
   PROCEDURE OBTERSAIDASCANCELADAS  (parametros in parametrosExecucao); 
   -- Registrar ID na tabela PCDADOS1070_TEMP 
   PROCEDURE OBTERID; 
   PROCEDURE EXECUTAR_TESTE_UNITARIO (PCODFILIAL IN VARCHAR2
                                    , PDTINICIO IN DATE
                                    , PDTFIM  IN DATE
                                    , PGERA_NF_CANCELADAS IN VARCHAR2
                                    , PNUMCASAS_QT IN NUMBER
                                    , PNUMCASAS_UNIT IN NUMBER
                                    , PEXIBITV14 IN VARCHAR2
                                    , PCODFISCAL IN VARCHAR2
                                    , PNUMNOTA1 IN NUMBER
                                    , PNUMNOTA2 IN NUMBER
                                    , PUTILIZOULISTAPRODUTO IN VARCHAR2
                                    , PDESCONS_USOCONSUMO IN VARCHAR2
                                    , PDESCONS_IMOBILIZADO IN VARCHAR2 ); 
   -- Observações: 
   -- Os parametros de imobilizado e consumo são utilizado na geração da tabela de itens a  
   -- serem pesquisados, logo nas selects principais não é necessário informar esses dois parametros 
END;