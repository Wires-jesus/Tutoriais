CREATE OR REPLACE TRIGGER T_PCNFENT_NFE
   BEFORE UPDATE
   OF ESPECIE, SERIE, NUMNOTA, CHAVENFE, PROTOCOLONFE, RECIBONFE, SITUACAONFE, TIPOEMISSAO, CONSUMIUNUMNFE, CHAVECTE, SITUACAOCTE, SITUACAONFEEPEC,
      AMBIENTENFE, CODFILIAL, CODFILIALNF, DTCANCEL, CODIGONUMERICOCHAVE, TIPOIMPRESSAO
   ON PCNFENT
   REFERENCING OLD AS OLD NEW AS NEW
   FOR EACH ROW
declare
   procedure GERAR_LOG(PCAMPO       in varchar2,
                       PVALORANT    in varchar2,
                       PVALORNOVO   in varchar2,
                       PNUMTRANSENT in number,
                       PERROADIC    in varchar2 default '') is
   begin
      insert into PCLOGALTERACAODADOS(DATA,
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
                                      OBSERVACOES2)
                               values(sysdate,
                                      'PCNFENT',
                                      PCAMPO,
                                      'A',
                                      PVALORANT,
                                      PVALORNOVO,
                                      SYS_CONTEXT('USERENV', 'TERMINAL'),
                                      SYS_CONTEXT('USERENV', 'HOST'),
                                      SYS_CONTEXT('USERENV', 'MODULE'),
                                      SYS_CONTEXT('USERENV', 'OS_USER'),
                                      'MUDANÇA DE INFORMAÇÃO: NUMTRANSENT: ' || TO_CHAR(PNUMTRANSENT),
                                      PERROADIC);
   end;

begin
   if (SYS_CONTEXT('USERENV', 'MODULE') not like '%PCNFE%' and
       SYS_CONTEXT('USERENV', 'MODULE') not like '%PCSIS1007%') then
      if (:old.ESPECIE <> :new.ESPECIE) and (:old.chavenfe is not null) then
         GERAR_LOG('ESPECIE', :old.ESPECIE, :new.ESPECIE, :new.NUMTRANSENT);
      end if;
      if (:old.NUMNOTA <> :new.NUMNOTA and :old.NUMNOTA > 0) then
         GERAR_LOG('NUMNOTA',
                   TO_CHAR(:old.NUMNOTA),
                   TO_CHAR(:new.NUMNOTA),
                   :new.NUMTRANSENT);
      end if;
      if (:old.SERIE <> :new.SERIE) and (:old.chavenfe is not null) then
         GERAR_LOG('SERIE', :old.SERIE, :new.SERIE, :new.NUMTRANSENT);
      end if;
      if NVL(:old.CHAVENFE, '0') <> NVL(:new.CHAVENFE, '0') then
         GERAR_LOG('CHAVENFE',
                   :old.CHAVENFE,
                   :new.CHAVENFE,
                   :new.NUMTRANSENT);
      end if;
      if NVL(:old.PROTOCOLONFE, '0') <> NVL(:new.PROTOCOLONFE, '0') then
         GERAR_LOG('PROTOCOLONFE',
                   :old.PROTOCOLONFE,
                   :new.PROTOCOLONFE,
                   :new.NUMTRANSENT);
      end if;
      if NVL(:old.RECIBONFE, '0') <> NVL(:new.RECIBONFE, '0') then
         GERAR_LOG('RECIBONFE',
                   :old.RECIBONFE,
                   :new.RECIBONFE,
                   :new.NUMTRANSENT);
      end if;
      if NVL(:old.SITUACAONFE, 0) <> NVL(:new.SITUACAONFE, 0) then
         GERAR_LOG('SITUACAONFE',
                   TO_CHAR(:old.SITUACAONFE),
                   TO_CHAR(:new.SITUACAONFE),
                   :new.NUMTRANSENT);
      end if;
      if NVL(:old.TIPOEMISSAO, '0') <> NVL(:new.TIPOEMISSAO, '0') then
         GERAR_LOG('TIPOEMISSAO',
                   TO_CHAR(:old.TIPOEMISSAO),
                   TO_CHAR(:new.TIPOEMISSAO),
                   :new.NUMTRANSENT);
      end if;
    GERAR_LOG('CONSUMIUNUMNFE',
                TO_CHAR(:old.CONSUMIUNUMNFE),
                TO_CHAR(:new.CONSUMIUNUMNFE),
                :new.NUMTRANSENT);
    if NVL(:old.CHAVECTE, '0') <> NVL(:new.CHAVECTE, '0')
    then
      GERAR_LOG('CHAVECTE',
                TO_CHAR(:old.CHAVECTE),
                TO_CHAR(:new.CHAVECTE),
                :new.NUMTRANSENT);
    end if;
    if NVL(:old.SITUACAOCTE, '0') <> NVL(:new.SITUACAOCTE, '0')
    then
      GERAR_LOG('SITUACAOCTE',
                TO_CHAR(:old.SITUACAOCTE),
                TO_CHAR(:new.SITUACAOCTE),
                :new.NUMTRANSENT);
    end if;
    if NVL(:old.SITUACAONFEEPEC, '0') <> NVL(:new.SITUACAONFEEPEC, '0')
    then
      GERAR_LOG('SITUACAONFEEPEC',
                TO_CHAR(:old.SITUACAONFEEPEC),
                TO_CHAR(:new.SITUACAONFEEPEC),
                :new.NUMTRANSENT);
    end if;
    if NVL(:old.AMBIENTENFE, '0') <> NVL(:new.AMBIENTENFE, '0')
    then
      GERAR_LOG('AMBIENTENFE',
                TO_CHAR(:old.AMBIENTENFE),
                TO_CHAR(:new.AMBIENTENFE),
                :new.NUMTRANSENT);
    end if;
    if NVL(:old.CODFILIAL, '0') <> NVL(:new.CODFILIAL, '0')
    then
      GERAR_LOG('CODFILIAL',
                TO_CHAR(:old.CODFILIAL),
                TO_CHAR(:new.CODFILIAL),
                :new.NUMTRANSENT);
    end if;
    if NVL(:old.CODFILIALNF, '0') <> NVL(:new.CODFILIALNF, '0')
    then
      GERAR_LOG('CODFILIAL',
                TO_CHAR(:old.CODFILIALNF),
                TO_CHAR(:new.CODFILIALNF),
                :new.NUMTRANSENT);
    end if;
    if (:old.DTCANCEL) <> (:new.DTCANCEL)
    then
      GERAR_LOG('DTCANCEL',
                (:old.DTCANCEL),
                (:new.DTCANCEL),
                :new.NUMTRANSENT);
    end if;
    if (:old.CODIGONUMERICOCHAVE) <> (:new.CODIGONUMERICOCHAVE)
    then
      GERAR_LOG('CODIGONUMERICOCHAVE',
                (:old.CODIGONUMERICOCHAVE),
                (:new.CODIGONUMERICOCHAVE),
                :new.NUMTRANSENT);
    end if;
    if (:old.TIPOIMPRESSAO) <> (:new.TIPOIMPRESSAO)
    then
      GERAR_LOG('TIPOIMPRESSAO',
                (:old.TIPOIMPRESSAO),
                (:new.TIPOIMPRESSAO),
                :new.NUMTRANSENT);
    end if;

   end if;
exception
   when others then
      GERAR_LOG('NENHUM',
                '',
                'ERRO AO GERAR RASTREABILIDADE NFE',
                :new.NUMTRANSENT,
                'ERRO OCORRIDO: ' || sqlerrm);
end; -- Eduardo 24/09/2013
