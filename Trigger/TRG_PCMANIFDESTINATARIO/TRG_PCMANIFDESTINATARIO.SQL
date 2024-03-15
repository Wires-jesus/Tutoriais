CREATE OR REPLACE TRIGGER TRG_PCMANIFDESTINATARIO
 BEFORE INSERT OR DELETE OR UPDATE
 ON PCMANIFDESTINATARIO
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
  RECORDSET SYS_REFCURSOR;
  TIPO_LOG  VARCHAR2(10);  
  ERR_CODE  VARCHAR2(30);
  ERR_MSG   VARCHAR2(200);
  VSOWNER   VARCHAR2(100);
  VSNAME    VARCHAR2(100);
  VSTYPE    VARCHAR2(100);
  VNLINE    NUMBER;
BEGIN
  BEGIN
    OWA_UTIL.WHO_CALLED_ME(VSOWNER, VSNAME, VNLINE, VSTYPE);

    IF UPDATING OR DELETING THEN
      OPEN RECORDSET FOR
        SELECT :OLD.CODIGO                AS CODIGO,               
               :OLD.TIPODOCUMENTO         AS TIPODOCUMENTO,        
               :OLD.DATARECEBDOCUMENTO    AS DATARECEBDOCUMENTO,   
               :OLD.CODFILIAL             AS CODFILIAL,            
               :OLD.UF                    AS UF,                   
               :OLD.CNPJCPF               AS CNPJCPF,              
               :OLD.IE                    AS IE,                   
               :OLD.NOME                  AS NOME,                 
               :OLD.CHAVENFE              AS CHAVENFE,             
               :OLD.DATAENTRADA           AS DATAENTRADA,          
               :OLD.DATAEMISSAO           AS DATAEMISSAO,          
               :OLD.TIPONOTA              AS TIPONOTA,             
               :OLD.FINALIDADENFE         AS FINALIDADENFE,        
               :OLD.DIGESTVALUE           AS DIGESTVALUE,          
               :OLD.SITUACAONFE           AS SITUACAONFE,          
               :OLD.SITCONFIRMACAODEST    AS SITCONFIRMACAODEST,   
               :OLD.DATAAUTORIZACAOSEFAZ  AS DATAAUTORIZACAOSEFAZ, 
               :OLD.VLTOTALNFE            AS VLTOTALNFE,           
               :OLD.TIPOEVENTO            AS TIPOEVENTO,           
               :OLD.SEQEVENTO             AS SEQEVENTO,            
               :OLD.DESCRICAOEVENTO       AS DESCRICAOEVENTO,      
               :OLD.CORRECAO              AS CORRECAO,             
               :OLD.FEZDOWNLOADXML        AS FEZDOWNLOADXML,       
               :OLD.AMBIENTE              AS AMBIENTE,             
               :OLD.NSU                   AS NSU,                  
               :OLD.JUSTIFICATIVA         AS JUSTIFICATIVA,        
               :OLD.CODSTATUS             AS CODSTATUS,            
               :OLD.DESCSTATUS            AS DESCSTATUS,           
               :OLD.NUMEROLOTE            AS NUMEROLOTE,           
               :OLD.SITCONFIRMACAODESTANT AS SITCONFIRMACAODESTAN, 
               :OLD.IDREMESSA             AS IDREMESSA,            
               :OLD.IDREMESSADOWNLOAD     AS IDREMESSADOWNLOAD,    
               :OLD.CODSTATUSDOWNLOAD     AS CODSTATUSDOWNLOAD,    
               :OLD.DESCSTATUSDOWNLOAD    AS DESCSTATUSDOWNLOAD,   
               :OLD.MAQUINA               AS MAQUINA,              
               :OLD.PROGRAMA              AS PROGRAMA,             
               :OLD.USUARIO               AS USUARIO,              
               :OLD.QTDEREPROCDOCE        AS QTDEREPROCDOCE,
               VSOWNER                    AS VSOWNER,
               VSNAME                     AS VSNAME,
               VNLINE                     AS VNLINE,
               VSTYPE                     AS VSTYPE
          FROM DUAL;
    END IF;

    IF INSERTING THEN
      TIPO_LOG := 'INSERT';
      OPEN RECORDSET FOR
        SELECT :NEW.CODIGO                AS CODIGO,               
               :NEW.TIPODOCUMENTO         AS TIPODOCUMENTO,        
               :NEW.DATARECEBDOCUMENTO    AS DATARECEBDOCUMENTO,   
               :NEW.CODFILIAL             AS CODFILIAL,            
               :NEW.UF                    AS UF,                   
               :NEW.CNPJCPF               AS CNPJCPF,              
               :NEW.IE                    AS IE,                   
               :NEW.NOME                  AS NOME,                 
               :NEW.CHAVENFE              AS CHAVENFE,             
               :NEW.DATAENTRADA           AS DATAENTRADA,          
               :NEW.DATAEMISSAO           AS DATAEMISSAO,          
               :NEW.TIPONOTA              AS TIPONOTA,             
               :NEW.FINALIDADENFE         AS FINALIDADENFE,        
               :NEW.DIGESTVALUE           AS DIGESTVALUE,          
               :NEW.SITUACAONFE           AS SITUACAONFE,          
               :NEW.SITCONFIRMACAODEST    AS SITCONFIRMACAODEST,   
               :NEW.DATAAUTORIZACAOSEFAZ  AS DATAAUTORIZACAOSEFAZ, 
               :NEW.VLTOTALNFE            AS VLTOTALNFE,           
               :NEW.TIPOEVENTO            AS TIPOEVENTO,           
               :NEW.SEQEVENTO             AS SEQEVENTO,            
               :NEW.DESCRICAOEVENTO       AS DESCRICAOEVENTO,      
               :NEW.CORRECAO              AS CORRECAO,             
               :NEW.FEZDOWNLOADXML        AS FEZDOWNLOADXML,       
               :NEW.AMBIENTE              AS AMBIENTE,             
               :NEW.NSU                   AS NSU,                  
               :NEW.JUSTIFICATIVA         AS JUSTIFICATIVA,        
               :NEW.CODSTATUS             AS CODSTATUS,            
               :NEW.DESCSTATUS            AS DESCSTATUS,           
               :NEW.NUMEROLOTE            AS NUMEROLOTE,           
               :NEW.SITCONFIRMACAODESTANT AS SITCONFIRMACAODESTAN, 
               :NEW.IDREMESSA             AS IDREMESSA,            
               :NEW.IDREMESSADOWNLOAD     AS IDREMESSADOWNLOAD,    
               :NEW.CODSTATUSDOWNLOAD     AS CODSTATUSDOWNLOAD,    
               :NEW.DESCSTATUSDOWNLOAD    AS DESCSTATUSDOWNLOAD,   
               :NEW.MAQUINA               AS MAQUINA,              
               :NEW.PROGRAMA              AS PROGRAMA,             
               :NEW.USUARIO               AS USUARIO,              
               :NEW.QTDEREPROCDOCE        AS QTDEREPROCDOCE,
               VSOWNER                    AS VSOWNER,
               VSNAME                     AS VSNAME,
               VNLINE                     AS VNLINE,
               VSTYPE                     AS VSTYPE
          FROM DUAL;
    ELSIF UPDATING THEN
      TIPO_LOG := 'UPDATE';
    ELSIF DELETING THEN
      TIPO_LOG := 'DELETE';
    END IF;
    
    INSERT INTO PCLOGFATURAMENTO
                (CODLOG
               , DATAHORA
               , PROCESSO
               , MAQUINA
               , TERMINAL
               , OSUSER
               , CODFILIAL
               , CODIGOIDENTIFICADOR
               , TIPOLOG
               , LOG)
         VALUES (DFSEQ_PCLOGFATURAMENTO.NEXTVAL
               , SYSDATE
               , 'MANIFESTACAO'
               , SYS_CONTEXT('USERENV', 'HOST')
               , SYS_CONTEXT('USERENV', 'TERMINAL')
               , SYS_CONTEXT('USERENV', 'OS_USER')
               , NVL(:OLD.CODFILIAL, :NEW.CODFILIAL)
               , NVL(:OLD.CODIGO, :NEW.CODIGO)
               , TIPO_LOG
               , PKG_JSON_UTIL.REF_CURSOR_TO_JSON(RECORDSET));
  EXCEPTION
    WHEN OTHERS THEN
      TIPO_LOG := 'ERRO';
      ERR_CODE := SQLCODE;
      ERR_MSG := SUBSTR(SQLERRM, 1, 200);
      BEGIN
        INSERT INTO PCLOGFATURAMENTO
                    (CODLOG
                   , DATAHORA
                   , PROCESSO
                   , MAQUINA
                   , TERMINAL
                   , OSUSER
                   , CODFILIAL
                   , CODIGOIDENTIFICADOR
                   , TIPOLOG
                   , LOG)
             VALUES (DFSEQ_PCLOGFATURAMENTO.NEXTVAL
                   , SYSDATE
                   , 'MANIFESTACAO'
                   , SYS_CONTEXT('USERENV', 'HOST')
                   , SYS_CONTEXT('USERENV', 'TERMINAL')
                   , SYS_CONTEXT('USERENV', 'OS_USER')
                   , NVL(:OLD.CODFILIAL, :NEW.CODFILIAL)
                   , NVL(:OLD.CODIGO, :NEW.CODIGO)
                   , TIPO_LOG
                   , (ERR_CODE || ' - ' || SUBSTR(ERR_MSG, 1, 200)));
      EXCEPTION
        WHEN OTHERS THEN
          TIPO_LOG := 'ERRO';
      END;
  END;
END TRG_PCMANIFDESTINATARIO;
