CREATE OR REPLACE TRIGGER TR_WMSLOG_ALTERACAOPCPEDI
BEFORE UPDATE
OF QT
ON PCPEDI
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
 vMACHINE    PCWMSLOGALTERACAO.MAQUINA_REDE%TYPE;
 vTERMINAL   PCWMSLOGALTERACAO.MAQUINA%TYPE;
 vPROGRAM    PCWMSLOGALTERACAO.PROGRAMA%TYPE;
 vOSUSER     PCWMSLOGALTERACAO.USUARIO_OS%TYPE;
 vUSERNAME   PCWMSLOGALTERACAO.USUARIO_DB%TYPE;
 vAPLICACAO  PCWMSLOGALTERACAO.APLICACAO%TYPE;
 vWMSGERADO  VARCHAR2(2);
 vPRODUSAWMS VARCHAR2(2);
 vPOSICAOPCEDC VARCHAR2(2);
 vOPERACAO    PCWMSLOGALTERACAO.OPERACAO%TYPE;
BEGIN              
    select case when (select DTWMS from PCPEDC where NUMPED = :NEW.NUMPED) is null then 'N' else 'S' end 
           into vWMSGERADO from PCPRODUT where CODPROD = :NEW.CODPROD;                       
    if vWMSGERADO <> 'S' then
       return;   
    end if;

    select nvl(USAWMS,'N') into vPRODUSAWMS from PCPRODUT where CODPROD = :NEW.CODPROD;                       
    if vPRODUSAWMS <> 'S' then
       return;   
    end if;
                     
    select MACHINE,TERMINAL,PROGRAM,OSUSER,USERNAME,sys_context('USERENV', 'MODULE') INTO 
           vMACHINE,vTERMINAL,vPROGRAM,vOSUSER,vUSERNAME,vAPLICACAO
    from usuarios_logados
    where audsid = sys_context('USERENV', 'SESSIONID');
    
    select POSICAO into vPOSICAOPCEDC from PCPEDC where NUMPED = :NEW.Numped;
    
    insert into PCWMSLOGALTERACAO (CODFILIAL
                                  ,NUMPED
                                  ,NUMCAR
                                  ,CODPROD
                                  ,QT
                                  ,QTANT
                                  ,PROGRAMA
                                  ,APLICACAO
                                  ,MAQUINA
                                  ,MAQUINA_REDE
                                  ,USUARIO_OS
                                  ,USUARIO_DB
                                  ,TRIGGER_DISPARADA
                                  ,TABELA
                                  ,OPERACAO
                                  ,OBS
                                  ,DATA)
                  VALUES          ((SELECT CODFILIAL FROM PCPEDC WHERE NUMPED=:NEW.NUMPED)
                                   ,:NEW.NUMPED
                                   ,:NEW.NUMCAR
                                   ,:NEW.CODPROD
                                   ,:NEW.QT
                                   ,:OLD.QT
                                   ,vPROGRAM
                                   ,vAPLICACAO
                                   ,vTERMINAL
                                   ,vMACHINE 
                                   ,vOSUSER      
                                   ,vUSERNAME
                                   ,'TR_WMSLOG_ALTERACAOPCPEDI'
                                   ,'PCPEDI'
                                   ,'U'
                                   ,'PCPEDC.POSICAO=' || vPOSICAOPCEDC || ', PCPEDI.NUMSEQ=' || :NEW.NUMSEQ
                                   ,SYSDATE           
                  );
    
END;
