CREATE OR REPLACE TRIGGER TRG_LOG1751                                                                                      
      BEFORE INSERT OR UPDATE                                                                                                             
      ON PCCONFOPERACAOWMS                                                                                                                
      REFERENCING OLD AS OLD NEW AS NEW                                                                                                   
      FOR EACH ROW                                                                                                                        
   BEGIN                                                                                                                                  
     if :old.Enderecopickingvalidade <> :new.Enderecopickingvalidade then                                                                 
       insert into PCLOG_ALTERACAO1751 (campo,Valor_Old,Valor_New,Data)                                                                   
              values ('Enderecopickingvalidade',to_char(:old.Enderecopickingvalidade) ,to_char(:new.Enderecopickingvalidade),sysdate);  
     end if;                                                                                                                              
   END;
