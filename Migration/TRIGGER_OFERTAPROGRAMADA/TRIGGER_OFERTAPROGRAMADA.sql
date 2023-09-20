CREATE OR REPLACE TRIGGER TRG_LOGPCOFERTAPROGRAMADAC                                                                                                                   
    AFTER                                                                                                                                                               
    INSERT OR DELETE OR UPDATE                                                                                                                                          
    ON PCOFERTAPROGRAMADAC                                                                                                                                              
    REFERENCING OLD AS OLD NEW AS NEW                                                                                                                                   
    FOR EACH ROW                                                                                                                                                        
BEGIN                                                                                                                                                                  
  IF DELETING THEN                                                                                                                                                     
    INSERT INTO PCOFERTAPROGRAMADAC_HIST(DATAALTER, CODFILIAL, CODOFERTA, DESCOFERTA, DTINICIAL, DTFINAL,                                                              
                                          DTCANCEL, MOTIVOCANCEL, CODFUNCCANCEL,                                                                                        
                                          DTORIG, CODFUNCORIG, DTULTALTOFERTA, CODFUNCULTALT, HORAINICIAL, HORAFINAL, VALIDACONVENIO,                                   
                                          CODTIPOOFERTA, CODOFERTAORIGEM, CODPRECOOFERTA, PRIORIDADEOFERTA, COMPUTADOR)                                                 
                                  VALUES (SYSDATE, :OLD.CODFILIAL, :OLD.CODOFERTA, :OLD.DESCOFERTA, :OLD.DTINICIAL, :OLD.DTFINAL,                                       
                                          :OLD.DTCANCEL, :OLD.MOTIVOCANCEL, :OLD.CODFUNCCANCEL,                                                                         
                                          :OLD.DTORIG, :OLD.CODFUNCORIG, :OLD.DTULTALTOFERTA, :OLD.CODFUNCULTALT, :OLD.HORAINICIAL, :OLD.HORAFINAL, :OLD.VALIDACONVENIO,
                                          :OLD.CODTIPOOFERTA, :OLD.CODOFERTAORIGEM, :OLD.CODPRECOOFERTA, :OLD.PRIORIDADEOFERTA, SYS_CONTEXT('USERENV', 'TERMINAL'));
                                                                                                                                                                        
    END IF;                                                                                                                                                            
  IF (INSERTING OR UPDATING) THEN                                                                                                                                    
    INSERT INTO PCOFERTAPROGRAMADAC_HIST(DATAALTER, CODFILIAL, CODOFERTA, DESCOFERTA, DTINICIAL, DTFINAL,                                                              
                                          DTCANCEL, MOTIVOCANCEL, CODFUNCCANCEL,                                                                                        
                                          DTORIG, CODFUNCORIG, DTULTALTOFERTA, CODFUNCULTALT, HORAINICIAL, HORAFINAL, VALIDACONVENIO,                                   
                                          CODTIPOOFERTA, CODOFERTAORIGEM, CODPRECOOFERTA, PRIORIDADEOFERTA, COMPUTADOR)                                                 
                                  VALUES (SYSDATE, :NEW.CODFILIAL, :NEW.CODOFERTA, :NEW.DESCOFERTA, :NEW.DTINICIAL, :NEW.DTFINAL,                                       
                                          :NEW.DTCANCEL, :NEW.MOTIVOCANCEL, :NEW.CODFUNCCANCEL,                                                                         
                                          :NEW.DTORIG, :NEW.CODFUNCORIG, :NEW.DTULTALTOFERTA, :NEW.CODFUNCULTALT, :NEW.HORAINICIAL, :NEW.HORAFINAL, :NEW.VALIDACONVENIO,
                                          :NEW.CODTIPOOFERTA, :NEW.CODOFERTAORIGEM, :NEW.CODPRECOOFERTA, :NEW.PRIORIDADEOFERTA, SYS_CONTEXT('USERENV', 'TERMINAL'));
  END IF;                                                                                                                                                              
END;                                                                                                                                                                   

\

CREATE OR REPLACE TRIGGER TRG_LOGPCOFERTAPROGRAMADAI
AFTER INSERT OR UPDATE OR DELETE ON PCOFERTAPROGRAMADAI
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  IF DELETING THEN
      INSERT INTO PCOFERTAPROGRAMADAI_HIST (DATAALTER, CODFILIAL, CODOFERTA, CODITEM, CODAUXILIAR,
                                            VLOFERTA, MOTIVOOFERTA, DTEMISSAOETIQ,
                                            QTMAXVENDA, CODOFERTAORIG, QTMAXOFERTA,
                                            QTVENDAOFERTA, VLOFERTAATAC, CODPROD,
                                            RECOMPOSICAO, MOTIVO, DATAEXCLUSAO)
                                    VALUES (SYSDATE, :OLD.CODFILIAL, :OLD.CODOFERTA, :OLD.CODITEM, :OLD.CODAUXILIAR,
                                            :OLD.VLOFERTA, :OLD.MOTIVOOFERTA, :OLD.DTEMISSAOETIQ,
                                            :OLD.QTMAXVENDA, :OLD.CODOFERTAORIG, :OLD.QTMAXOFERTA,
                                            :OLD.QTVENDAOFERTA, :OLD.VLOFERTAATAC, :OLD.CODPROD,
                                            :OLD.RECOMPOSICAO, :OLD.MOTIVO, SYSDATE);
  END IF;
  IF (INSERTING OR UPDATING) THEN
      INSERT INTO PCOFERTAPROGRAMADAI_HIST (DATAALTER, CODFILIAL, CODOFERTA, CODITEM, CODAUXILIAR,
                                            VLOFERTA, MOTIVOOFERTA, DTEMISSAOETIQ,
                                            QTMAXVENDA, CODOFERTAORIG, QTMAXOFERTA,
                                            QTVENDAOFERTA, VLOFERTAATAC, CODPROD,
                                            RECOMPOSICAO, MOTIVO)
                                    VALUES (SYSDATE, :NEW.CODFILIAL, :NEW.CODOFERTA, :NEW.CODITEM, :NEW.CODAUXILIAR,
                                            :NEW.VLOFERTA, :NEW.MOTIVOOFERTA, :NEW.DTEMISSAOETIQ,
                                            :NEW.QTMAXVENDA, :NEW.CODOFERTAORIG, :NEW.QTMAXOFERTA,
                                            :NEW.QTVENDAOFERTA, :NEW.VLOFERTAATAC, :NEW.CODPROD,
                                            :NEW.RECOMPOSICAO, :NEW.MOTIVO);
  END IF;
END;
