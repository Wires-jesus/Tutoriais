create or replace trigger T_PCNFENT_CONTROLE_NUMNOTA
  before update of NUMNOTA on PCNFENT
  referencing old as old new as new
  for each row
declare
  ALTERACAO_NUMNOTA_INDEVIDA exception;

  procedure GERAR_LOG(PCAMPO         in varchar2,
                      PVALORANT      in varchar2,
                      PVALORNOVO     in varchar2,
                      PNUMTRANSVENDA in number,
                      PERROADIC      in varchar2 default NULL) is
  begin
    insert into PCLOGALTERACAODADOS
      (DATA
      ,TABELA
      ,COLUNA
      ,TIPOVALOR
      ,VALORALFAANT
      ,VALORALFA
      ,TERMINAL
      ,MAQUINA
      ,PROGRAMA
      ,OSUSER
      ,OBSERVACOES
      ,OBSERVACOES2)
    values
      (sysdate
      ,'PCNFENT'
      ,PCAMPO
      ,'A'
      ,PVALORANT
      ,PVALORNOVO
      ,SYS_CONTEXT('USERENV', 'TERMINAL')
      ,SYS_CONTEXT('USERENV', 'HOST')
      ,SYS_CONTEXT('USERENV', 'MODULE')
      ,SYS_CONTEXT('USERENV', 'OS_USER')
      ,'MUDANÇA DO NUMNOTA: NUMTRANSVENDA: ' || TO_CHAR(PNUMTRANSVENDA)
      ,PERROADIC);
  end;

begin

  if NVL(:OLD.CONSUMIUNUMNFE, 'N') = 'S' and NVL(:NEW.NUMNOTA, 0) <> NVL(:OLD.NUMNOTA, 0) AND NVL(:OLD.ESPECIE , '') <> 'TP'
  then
    raise ALTERACAO_NUMNOTA_INDEVIDA;
  end if;

exception
  when ALTERACAO_NUMNOTA_INDEVIDA then
    RAISE_APPLICATION_ERROR(-20000,
                            'OCORREU UMA TENTATIVA DE ALTERAÇÃO DO NÚMERO DA NOTA FISCAL INDEVIDAMENTE!' || CHR(13) ||
                             'O PROCESSO SERÁ ABORTADO.' || CHR(13) || 'TRANSAÇÃO DE ENTRADA: ' || :NEW.NUMTRANSENT);
  when others then
    GERAR_LOG('NUMNOTA', :OLD.NUMNOTA, :NEW.NUMNOTA, :NEW.NUMTRANSENT, 'ERRO OCORRIDO: ' || sqlerrm);

end;