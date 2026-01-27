CREATE OR REPLACE PACKAGE BODY PKG_FINANCEIRO_SCRIPTS
IS

    /* IMPORTANTE  
    
        -- CUIDADO AO INCLUIR UM NOVO CAMPO, CERTIFIQUE-SE DELE SER REPLICADO EM TODOS AS CHAMADAS DA FUNÇÃO
        -- CERTIFIQUE-SE DE INCLUIR A DEPENDENCIA DA TABELA NO ARQUIVO .JSON
    
    */
    
    FUNCTION GET_PCLANC RETURN VARCHAR2
    IS
    BEGIN
        
        RETURN ' RECNUM,                   DTLANC,                   HISTORICO,             DUPLIC,             
                 LOCALIZACAO,              CODFILIAL,                INDICE,                NUMCHEQUE,          
                 TIPOLANC,                 TIPOPARCEIRO,             NOMEFUNC,              ASSINATURA,         
                 TIPOPAGTO,                NUMDVDESTDOC,             NUMCODBARRA,           HISTORICO2,         
                 MOEDA,                    DVAG,                     PORTADORCHEQUE,        NUMDIIMPORTACAO,    
                 ADIANTAMENTO,             NFSERVICO,                PREST,                 BOLETO,             
                 PAGTONOMEDOCLIENTE,       OBSBLOQ,                  AGENDAMENTO,           NUMCONTRATOCAMBIO,  
                 IDCONTROLEEMBARQUE,       FORMAPGTO,                CODROTINACAD,          DTMOEDA,            
                 CODROTINAALT,             PARCELA,                  NUMNOTA,               CODFORNEC,          
                 VLRUTILIZADOADIANTFORNEC, TIPOSERVICO,              IDENTIFICADORFGTS,     LACREDIGCONECSOCIAL,
                 OPCAOPAGAMENTOIPVA,       VALOR,                    CODCONTA,              VPAGO,              
                 NUMNOTADEV,               VALORDEV,                 PRORROG,               NUMBORDERO,         
                 VPAGOBORDERO,             NUMSEQBORDERO,            NUMCHEQUE2,            NUMBANCO,           
                 DESCONTOFIN,              TXPERM,                   NUMVIA,                NUMBCODESTDOC,      
                 NUMAGDESTDOC,             NUMCCDESTDOC,             NUMTRANSENT,           NUMTAB,             
                 CODFORNECPRINC,           VLIRRF,                   VLSESTSENAT,           NUMTRANSADIANTFOR,  
                 CODFUNCBAIXA,             NUMAGDESTDOC2,            NUMVIASFICHACP,        CODFUNCAUTOR,       
                 NUMTRANS,                 CODFUNCESTORNOBAIXA,      CODFUNCRECLASSIFIC,    CODCOMPRADOR,       
                 MOEDAESTRANGEIRA,         COTACAO,                  RECNUMPRINC,           COTACAOBAIXA,       
                 FROTA_QTLITROS,           FROTA_CODPRACA,           FROTA_NUMCAR,          FROTA_CODVEICULO,   
                 FROTA_COMISSAO,           FROTA_KMABASTECE,         NUMTRANSVENDA,         NUMNEGOCIACAO,      
                 PERCDESCFINREAL,          VALORMOEDAESTRANGEIRA,    FROTA_PESO,            CODFUNCULTALTER,    
                 CODPROJETO,               VLISS,                    VLINSS,                VLCSRF,             
                 FUNCBLOQ,                 VLPIS,                    VLCOFINS,              VLVARIACAOCAMBIAL,  
                 VLOUTRAS,                 NUMTRANSENTNF,            CODRECEITA,            VRECEITABRUTA,      
                 PERCRECEITABRUTA,         NUMPARCELAMENTO,          NUMSEQPARCELAMENTO,    VLRPARIDADEMOEDA,   
                 MOEDAPARIDADE,            NUMSEQCONTRATOEMPRESTIMO, CODROTINABAIXA,        VLDESPFIN,          
                 DTVENC,                   DTPAGTO,                  DTBORDER,              DTEMISSAO,          
                 DTCHEQ,                   DTASSINATURA,             DTAUTOR,               DTESTORNOBAIXA,     
                 DTRECLASSIFIC,            DTPRORROG,                FROTA_DTABASTECE,      DTCOTACAO,          
                 DTPAGADIANTFOR,           DTULTALTER,               DTCOMPETENCIA,         DTDESD,             
                 DTBLOQ,                   DTAGENDAMENTO,            DTCANCEL,              DTIMPRESSAO,        
                 CODLANCAMENTORM,          FORNECEDOR,               CODSERVICOSPEDEFD,     RECNUMBAIXA,        
                 CODCOBSEFAZ,              RAZAOCREDENCCARTAO,       CNPJCREDENCCARTAO,     NSUTEF,             
                 BANDEIRACARTAO,           CODMOEDABAIXA,            REINFEVENTOR4040,      CODSERVICOSPEDIRPJ, 
                 CODSERVICOSPEDIRPF,       CODSERVICOSPEDBNI,        CODTIPOCHAVEPIX,       TIPOCHAVEPIX,       
                 CHAVEPIX,                 QRCODEPIX,                VLBASEIR,              VLBASEPCC,
                 DTCOMPETENCIAIRRETIDO ';
    END; --GET_PCLANC
    
    FUNCTION GET_PCRATEIOCENTROCUSTO RETURN VARCHAR2
    IS
    BEGIN
        
        RETURN ' RECNUM,            CODCONTA,         
                 VALOR,             PERCRATEIO,       
                 DTLANC,            CONTRAPARTIDA,    
                 RECNUMPRINC,       CODFILIAL,        
                 CODIGOCENTROCUSTO, CODFUNCAUTSUPLORC,
                 DATAAUTSUPLORC,    ORCAMENTOEXCEDIDO ';
    END; --GET_PCRATEIOCENTROCUSTO
    
    FUNCTION GET_PCRATEIOCENTROCUSTOBLOQ RETURN VARCHAR2
    IS
    BEGIN
        
        RETURN ' RECNUM,            CODCONTA,         
                 VALOR,             PERCRATEIO,       
                 DTLANC,            CONTRAPARTIDA,    
                 RECNUMPRINC,       CODFILIAL,        
                 CODIGOCENTROCUSTO, CODFUNCAUTSUPLORC,
                 DATAAUTSUPLORC,    ORCAMENTOEXCEDIDO ';
    END; --GET_PCRATEIOCENTROCUSTOBLOQ
    
    FUNCTION TEM_PCLANC(P_RECNUM PCLANC.RECNUM%TYPE) RETURN BOOLEAN
    IS
        V_REGISTRO NUMBER;
    BEGIN
        V_REGISTRO := 0;
        SELECT COUNT(1) INTO V_REGISTRO FROM PCLANC WHERE RECNUM = P_RECNUM;
         
        RETURN V_REGISTRO > 0;     
    END; --GET_PCLANC_EXISTE
    
    FUNCTION TEM_PCLANCBLOQ(P_RECNUM PCLANC.RECNUM%TYPE) RETURN BOOLEAN
    IS
        V_REGISTRO NUMBER;
    BEGIN
        V_REGISTRO := 0;
        SELECT COUNT(1) INTO V_REGISTRO FROM PCLANCBLOQ WHERE RECNUM = P_RECNUM;
         
        RETURN V_REGISTRO > 0;     
    END; --GET_PCLANCBLOQ_EXISTE
    
    FUNCTION TEM_PCRATEIOCENTROCUSTO(P_RECNUM PCLANC.RECNUM%TYPE) RETURN BOOLEAN
    IS
        V_REGISTRO NUMBER;
    BEGIN
        V_REGISTRO := 0;
        SELECT COUNT(1) INTO V_REGISTRO FROM PCRATEIOCENTROCUSTO WHERE RECNUM = P_RECNUM;
         
        RETURN V_REGISTRO > 0;     
    END; --GET_PCRATEIOCENTROCUSTO_EXISTE
    
    FUNCTION TEM_PCRATEIOCENTROCUSTOBLOQ(P_RECNUM PCLANC.RECNUM%TYPE) RETURN BOOLEAN
    IS
        V_REGISTRO NUMBER;
    BEGIN
        V_REGISTRO := 0;
        SELECT COUNT(1) INTO V_REGISTRO FROM PCRATEIOCENTROCUSTOBLOQ WHERE RECNUM = P_RECNUM;
         
        RETURN V_REGISTRO > 0;     
    END; --GET_PCRATEIOCENTROCUSTOBLOQ_EXISTE


END PKG_FINANCEIRO_SCRIPTS;