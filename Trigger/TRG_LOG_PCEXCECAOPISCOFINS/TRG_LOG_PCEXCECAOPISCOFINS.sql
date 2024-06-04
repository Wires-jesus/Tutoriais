CREATE OR REPLACE TRIGGER TRG_LOG_PCEXCECAOPISCOFINS
   BEFORE INSERT OR UPDATE OR DELETE
   ON PCEXCECAOPISCOFINS
   REFERENCING OLD AS OLD NEW AS NEW
   FOR EACH ROW
DECLARE
   VSEQUIPAMENTO   VARCHAR2(64);
   VSUSUARIO       VARCHAR2(30);
   VSPROGRAMA      VARCHAR2(48);
   VSTIPO          VARCHAR2(20);

   PROCEDURE GERARLOG(PNOMECOLUNA VARCHAR2, POLDVALUE VARCHAR2, PNEWVALUE VARCHAR2)
   IS
   BEGIN
      IF NVL(POLDVALUE, 'X') <> NVL(PNEWVALUE, 'X')
      THEN
         INSERT INTO PCLOGALTERACAODADOS
                     (DATA
                    , TABELA
                    , COLUNA
                    , CODIGO
                    , OBSERVACOES
                    , PROGRAMA
                    , TERMINAL
                    , OSUSER
                    , VALORALFAANT
                    , VALORALFA
                    , OPERACAO
                    , OBSERVACOES2)
              VALUES (SYSDATE
                    , 'PCEXCECAOPISCOFINS'
                    , PNOMECOLUNA
                    , DECODE(VSTIPO,'D',:OLD.CODEXCECAO,:NEW.CODEXCECAO)
                    , 'CODEXCECAO: ' || DECODE(VSTIPO,'D',:OLD.CODEXCECAO,:NEW.CODEXCECAO)
                    , VSPROGRAMA
                    , VSEQUIPAMENTO
                    , VSUSUARIO
                    , POLDVALUE
                    , PNEWVALUE
                    , VSTIPO
                    , 'CODEXCECAO: ' || :OLD.CODEXCECAO);
      END IF;
   END;
BEGIN
   VSEQUIPAMENTO              := SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64);
   VSUSUARIO                  := SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30);
   VSPROGRAMA                 := SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48);

   IF UPDATING
   THEN
      VSTIPO                     := 'U';
   ELSIF INSERTING
   THEN
      VSTIPO                     := 'I';
   ELSE
      VSTIPO                     := 'D';
   END IF;

   /*Gerar Log*/
    GERARLOG('CODEXCECAO', TO_CHAR(:OLD.CODEXCECAO), TO_CHAR(:NEW.CODEXCECAO));
    GERARLOG('CODTRIBPISCOFINS', TO_CHAR(:OLD.CODTRIBPISCOFINS), TO_CHAR(:NEW.CODTRIBPISCOFINS));
    GERARLOG('TIPO', TO_CHAR(:OLD.TIPO), TO_CHAR(:NEW.TIPO));
    GERARLOG('VALOR', TO_CHAR(:OLD.VALOR), TO_CHAR(:NEW.VALOR));
    GERARLOG('TIPO2', TO_CHAR(:OLD.TIPO2), TO_CHAR(:NEW.TIPO2));
    GERARLOG('VALOR2', TO_CHAR(:OLD.VALOR2), TO_CHAR(:NEW.VALOR2));
    GERARLOG('TIPO3', TO_CHAR(:OLD.TIPO3), TO_CHAR(:NEW.TIPO3));
    GERARLOG('VALOR3', TO_CHAR(:OLD.VALOR3), TO_CHAR(:NEW.VALOR3));
    GERARLOG('CODEXCFIGTRIB', TO_CHAR(:OLD.CODEXCFIGTRIB), TO_CHAR(:NEW.CODEXCFIGTRIB));
END;