CREATE OR REPLACE TRIGGER TR_WMSVALIDAPESOVARIAVEL 
BEFORE UPDATE OR INSERT                 
OF PESOVARIAVEL,TIPOESTOQUE             
ON PCPRODUT                             
REFERENCING NEW AS NEW OLD AS OLD       
 FOR EACH ROW                           
DECLARE                                 
BEGIN                                   
    IF nvl(:NEW.TIPOESTOQUE,'X') <> 'FR' AND NVL(:NEW.USAWMS,'N')='S' THEN 
       :NEW.PESOVARIAVEL := 'N'; 
    END IF;                      
END;
