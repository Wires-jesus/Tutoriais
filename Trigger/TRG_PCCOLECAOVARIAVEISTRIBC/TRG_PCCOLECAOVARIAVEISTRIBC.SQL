CREATE OR REPLACE TRIGGER TRG_PCCOLECAOVARIAVEISTRIBC
 BEFORE
  INSERT OR UPDATE OR DELETE
 ON PCCOLECAOVARIAVEISTRIBC
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
/*****************************************************************************
                           Historico de Alteracoes
------------------------------------------------------------------------------
 Data        Responsavel           Tarefa     Alteracao
 ----------  --------------------  -----------    --------------------------------
 25/04/2006  Rogerio                              Criacao do Programa
 01/02/2008  Pablo                                  Alteração para gravar PCPEDC.VLBONIFIC conforme total de PCPEDC.VLATEND
                                                                (Totalização do preço de venda PCPEDI.PVENDA que é o mesmo valor de
PCPEDI.PBONIFIC)
 27/05/2008  Pablo                  63215     Alteração para gravar PCPEDC.VLBONIFIC somente quando este for null
 19/09/2008  Aracelia               69110     Alteração realizada para restringir apenas qt maior q zero
 04/02/2010  Pablo                  121185    Alteração para passar a registrar o LOG de motivo de bloqueio na tabela pclogbloqueiopedvenda
*****************************************************************************/
  vicontador              INTEGER;
  VSPROGRAMA              VARCHAR2(30);
  VSMOTIVO                VARCHAR2(100);
  VSOWNER                 VARCHAR2(1000);
  VSNAME                  VARCHAR2(1000);
  VNLINE                  VARCHAR2(1000);
  VSTYPE                  VARCHAR2(1000);
  VSDADOSOBSERVACAO2      VARCHAR2(4000) := '';

  procedure GERAR_LOG(PCAMPO       in varchar2,
                      PVALORANT    in varchar2,
                      PVALORNOVO   in varchar2,
                      PCODCOLECAOVAR      in number,
                      POBSERVACAO2 in varchar2 default '') is

    vObs varchar(200);
  begin

    IF INSERTING THEN
      vObs := 'INCLUSÃO DE INFORMAÇÃO NO CAMPO ' || PCAMPO || '. CODCOLECAOVAR: ' ||
              TO_CHAR(PCODCOLECAOVAR);
    ELSIF UPDATING THEN
      vObs := 'ALTERAÇÃO DE INFORMAÇÃO NO CAMPO ' || PCAMPO || '. CODCOLECAOVAR: ' ||
              TO_CHAR(PCODCOLECAOVAR);
    ELSIF DELETING THEN
      vObs := 'DELEÇÃO DE INFORMAÇÃO NO CAMPO ' || PCAMPO || '. CODCOLECAOVAR: ' ||
              TO_CHAR(PCODCOLECAOVAR);
    END IF;

    insert into PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFAANT,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       CODIGO)
    values
      (sysdate,
       'PCCOLECAOVARIAVEISTRIBC',
       PCAMPO,
       'A',
       PVALORANT,
       PVALORNOVO,
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       vObs,
       POBSERVACAO2,
       PCODCOLECAOVAR);
  end;

BEGIN

  VSPROGRAMA := SUBSTR(SYS_CONTEXT('USERENV',
                                   'MODULE'),
                       1,
                       30);
  OWA_UTIL.WHO_CALLED_ME(VSOWNER, VSNAME, VNLINE, VSTYPE);

   IF (VSOWNER IS NOT NULL) OR (VSNAME IS NOT NULL) OR (VNLINE IS NOT NULL) OR
      (VSTYPE IS NOT NULL) THEN
      VSDADOSOBSERVACAO2 := SUBSTR(CASE
                            WHEN VSOWNER IS NOT NULL THEN
                             'VSOWNER: ' || VSOWNER
                            ELSE
                             'VSOWNER DNF'
                            END || '; ' || CASE
                            WHEN VSNAME IS NOT NULL THEN
                             'VSNAME: ' || VSNAME
                            ELSE
                             'VSNAME DNF'
                            END || '; ' || CASE
                            WHEN VNLINE IS NOT NULL THEN
                             'VNLINE: ' || VNLINE
                            ELSE
                             'VNLINE DNF'
                            END || '; ' || CASE
                            WHEN VSTYPE IS NOT NULL THEN
                             'VSTYPE: ' || VSTYPE
                            ELSE
                             'VSTYPE DNF'
                            END, 1, 2000);
   END IF;
   IF (INSERTING) OR (UPDATING) THEN
     IF NVL((:NEW.DESCRICAO), 0) <> NVL((:OLD.DESCRICAO), 0) THEN
      GERAR_LOG('CODCOLECAOVAR',
                :old.DESCRICAO,
                :new.DESCRICAO,
                :new.CODCOLECAOVAR,
                VSDADOSOBSERVACAO2);
     END IF;
   ELSE
      GERAR_LOG('CODCOLECAOVAR',
        :old.CODCOLECAOVAR,
        :new.CODCOLECAOVAR,
        :new.CODCOLECAOVAR,
        VSDADOSOBSERVACAO2);
   END IF;

END;
