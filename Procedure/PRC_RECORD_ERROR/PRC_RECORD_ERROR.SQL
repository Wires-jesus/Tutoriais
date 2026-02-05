CREATE OR REPLACE PROCEDURE PRC_RECORD_ERROR
(
  vIdProcesso IN pccontroleconsinco.id%TYPE DEFAULT null,
  vProcesso IN pccontroleconsinco.objetoreferencia%TYPE DEFAULT null
)

IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   l_code   PLS_INTEGER := SQLCODE;
   l_mesg   VARCHAR2(32767) := SQLERRM;
   vProc VARCHAR2(100);
BEGIN
   vProc := vProcesso;
   
   INSERT INTO PCERRORLOGCONSINCO (error_code
                                ,  error_message
                                ,  backtrace
                                ,  callstack
                                ,  created_on
                                ,  created_by
                                ,  id_processo
								,  tipo_erro)
        VALUES (l_code
              , l_mesg
              , sys.DBMS_UTILITY.format_error_backtrace
              , sys.DBMS_UTILITY.format_call_stack
              , SYSDATE
              , USER
              , vIdProcesso
			  , 'E');
   
   IF vProcesso IS NULL THEN 
      SELECT OBJETOREFERENCIA INTO vProc FROM PCCONTROLECONSINCO WHERE ID = vIdProcesso;     
   END IF;     
   
   INSERT INTO PCDEVLOGCONSINCO
        (dv_name, dv_message, dv_message_2, dv_date, dv_timestamp)
   VALUES
        ('pkg_sinc_PDV_Consinco', vProc, vProc, SYSDATE, CURRENT_TIMESTAMP);     
   
   COMMIT;
END;
