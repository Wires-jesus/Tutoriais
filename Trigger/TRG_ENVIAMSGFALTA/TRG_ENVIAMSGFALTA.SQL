CREATE OR REPLACE TRIGGER TRG_ENVIAMSGFALTA
  BEFORE INSERT ON PCFALTA
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  /*****************************************************************************
                             HISTORICO DE ALTERACOES
  ------------------------------------------------------------------------------
   DATA        RESPONSAVEL           TAREFA       ALTERACAO
   ----------  --------------------  -----------  --------------------------------
   07/07/2011  THIAGO ALVES          135166       CRIACAO DO PROGRAMA
  *****************************************************************************/
  VSENVIAMSGFALTA VARCHAR2(1);
  VSNOMECLIENTE   VARCHAR2(60);
BEGIN
  BEGIN
    SELECT NVL(PCPARAMFILIAL.VALOR, 'N')
      INTO VSENVIAMSGFALTA
      FROM PCPARAMFILIAL
     WHERE PCPARAMFILIAL.CODFILIAL = '99'
       AND PCPARAMFILIAL.NOME = 'ENVIAMSGFALTA';
  EXCEPTION
    WHEN OTHERS THEN
      VSENVIAMSGFALTA := 'N';
  END;

  IF VSENVIAMSGFALTA = 'S' THEN
    BEGIN
      SELECT PCCLIENT.CLIENTE
       INTO VSNOMECLIENTE
       FROM PCCLIENT
      WHERE CODCLI = :NEW.CODCLI;
    EXCEPTION
      WHEN OTHERS THEN
        VSENVIAMSGFALTA := '';
    END;
    INSERT INTO PCMENS
      (CODUSUR, DATA,MENS1,MENS3, MENS5, DATACOMPLETA)
    VALUES
      (:NEW.CODUSUR,
       TRUNC(SYSDATE),
       SUBSTR(('O Pedido - '||:NEW.NUMPED|| ' alterado'),1,60),
       SUBSTR(('Cliente -'||:NEW.CODCLI||'-'||VSNOMECLIENTE),1,60),
       SUBSTR((SELECT PCPRODUT.DESCRICAO || ' - ' || PCPRODUT.EMBALAGEM ||
                     ' - FALTA ' || TO_CHAR(:NEW.QT)
                FROM PCPRODUT
               WHERE PCPRODUT.CODPROD = :NEW.CODPROD),
              1,
              60),
       SYSDATE);
  END IF;
END;
/
