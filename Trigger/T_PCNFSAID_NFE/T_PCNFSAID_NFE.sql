CREATE OR REPLACE TRIGGER "T_PCNFSAID_NFE" 
 BEFORE INSERT OR UPDATE
 OF ESPECIE, SERIE, NUMNOTA, CHAVENFE, PROTOCOLONFE, RECIBONFE, SITUACAONFE, TIPOEMISSAO, CONSUMIUNUMNFE, CHAVECTE, SITUACAOCTE, SITUACAONFEEPEC, AMBIENTENFE, 
    AMBIENTECTE, CODFILIAL, CODFILIALNF, DTCANCEL, DTSAIDA, DTSAIDANF, DTENTREGA, DTFAT, HORALANC, MINUTOLANC, CODIGONUMERICOCHAVE, TIPOIMPRESSAO,
    VLOUTRASDESP, VLFRETE, PRAZOMEDIO, CODUSUR, CODCLI, VLTOTAL, VLTOTGER
 ON PCNFSAID 
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
declare
  procedure GERAR_LOG(PCAMPO         in varchar2,
                      PVALORANT      in varchar2,
                      PVALORNOVO     in varchar2,
                      PNUMTRANSVENDA in number,                      
                      PERROADIC      in varchar2 default '') is
  
    vObs varchar(200);
  begin
    CASE 
         WHEN UPDATING  THEN vObs := 'MUDANÇA DE INFORMAÇÃO: NUMTRANSVENDA: ' || TO_CHAR(PNUMTRANSVENDA);
         WHEN INSERTING THEN vObs := 'NOVA NOTA: ' || TO_CHAR(PNUMTRANSVENDA);
         ELSE vObs := 'ERRO.';
    END CASE;    
  
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
       OBSERVACOES2)
    values
      (sysdate,
       'PCNFSAID',
       PCAMPO,
       'A',
       PVALORANT,
       PVALORNOVO,
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       vObs,       
       PERROADIC);
  end;

begin
  if UPDATING then
    if (SYS_CONTEXT('USERENV', 'MODULE') not like '%PCSIS1008%')
    then
      if (:old.ESPECIE <> :new.ESPECIE) and (:old.chavenfe is not null)
      then
        GERAR_LOG('ESPECIE', :old.ESPECIE, :new.ESPECIE, :new.NUMTRANSVENDA);
      end if;
      if (:old.ESPECIE <> :new.ESPECIE) and (:old.chavecte is not null)
      then
        GERAR_LOG('ESPECIE', :old.ESPECIE, :new.ESPECIE, :new.NUMTRANSVENDA);
      end if;
      if (:old.NUMNOTA <> :new.NUMNOTA and :old.NUMNOTA > 0)
      then
        GERAR_LOG('NUMNOTA',
                  TO_CHAR(:old.NUMNOTA),
                  TO_CHAR(:new.NUMNOTA),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.SERIE <> :new.SERIE) and (:old.chavenfe is not null)
      then
        GERAR_LOG('SERIE', :old.SERIE, :new.SERIE, :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.CHAVENFE, '0') <> NVL(:new.CHAVENFE, '0')
      then
        GERAR_LOG('CHAVENFE',
                  :old.CHAVENFE,
                  :new.CHAVENFE,
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.PROTOCOLONFE, '0') <> NVL(:new.PROTOCOLONFE, '0')
      then
        GERAR_LOG('PROTOCOLONFE',
                  :old.PROTOCOLONFE,
                  :new.PROTOCOLONFE,
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.RECIBONFE, '0') <> NVL(:new.RECIBONFE, '0')
      then
        GERAR_LOG('RECIBONFE',
                  :old.RECIBONFE,
                  :new.RECIBONFE,
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.SITUACAONFE, 0) <> NVL(:new.SITUACAONFE, 0)
      then
        GERAR_LOG('SITUACAONFE',
                  TO_CHAR(:old.SITUACAONFE),
                  TO_CHAR(:new.SITUACAONFE),
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.TIPOEMISSAO, '0') <> NVL(:new.TIPOEMISSAO, '0')
      then
        GERAR_LOG('TIPOEMISSAO',
                  TO_CHAR(:old.TIPOEMISSAO),
                  TO_CHAR(:new.TIPOEMISSAO),
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.CONSUMIUNUMNFE, '0') <> NVL(:new.CONSUMIUNUMNFE, '0')
      then
        GERAR_LOG('CONSUMIUNUMNFE',
                  TO_CHAR(:old.CONSUMIUNUMNFE),
                  TO_CHAR(:new.CONSUMIUNUMNFE),
                  :new.NUMTRANSVENDA);
      end if;   
      if NVL(:old.CHAVECTE, '0') <> NVL(:new.CHAVECTE, '0')
      then
        GERAR_LOG('CHAVECTE',
                  TO_CHAR(:old.CHAVECTE),
                  TO_CHAR(:new.CHAVECTE),
                  :new.NUMTRANSVENDA);
      end if; 
      if NVL(:old.SITUACAOCTE, '0') <> NVL(:new.SITUACAOCTE, '0')
      then
        GERAR_LOG('SITUACAOCTE',
                  TO_CHAR(:old.SITUACAOCTE),
                  TO_CHAR(:new.SITUACAOCTE),
                  :new.NUMTRANSVENDA);
      end if; 
      if NVL(:old.SITUACAONFEEPEC, '0') <> NVL(:new.SITUACAONFEEPEC, '0')
      then
        GERAR_LOG('SITUACAONFEEPEC',
                  TO_CHAR(:old.SITUACAONFEEPEC),
                  TO_CHAR(:new.SITUACAONFEEPEC),
                  :new.NUMTRANSVENDA);
      end if; 
      if NVL(:old.AMBIENTENFE, '0') <> NVL(:new.AMBIENTENFE, '0')
      then
        GERAR_LOG('AMBIENTENFE',
                  TO_CHAR(:old.AMBIENTENFE),
                  TO_CHAR(:new.AMBIENTENFE),
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.AMBIENTECTE, '0') <> NVL(:new.AMBIENTECTE, '0')
      then
        GERAR_LOG('AMBIENTECTE',
                  TO_CHAR(:old.AMBIENTECTE),
                  TO_CHAR(:new.AMBIENTECTE),
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.CODFILIAL, '0') <> NVL(:new.CODFILIAL, '0')
      then
        GERAR_LOG('CODFILIAL',
                  TO_CHAR(:old.CODFILIAL),
                  TO_CHAR(:new.CODFILIAL),
                  :new.NUMTRANSVENDA);
      end if;
      if NVL(:old.CODFILIALNF, '0') <> NVL(:new.CODFILIALNF, '0')
      then
        GERAR_LOG('CODFILIAL',
                  TO_CHAR(:old.CODFILIALNF),
                  TO_CHAR(:new.CODFILIALNF),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.DTCANCEL) <> (:new.DTCANCEL)
      then
        GERAR_LOG('DTCANCEL',
                  (:old.DTCANCEL),
                  (:new.DTCANCEL),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.DTSAIDA) <> (:new.DTSAIDA)
      then
        GERAR_LOG('DTSAIDA',
                  (:old.DTSAIDA),
                  (:new.DTSAIDA),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.DTSAIDANF) <> (:new.DTSAIDANF)
      then
        GERAR_LOG('DTSAIDANF',
                  (:old.DTSAIDANF),
                  (:new.DTSAIDANF),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.DTENTREGA) <> (:new.DTENTREGA)
      then
        GERAR_LOG('DTENTREGA',
                  (:old.DTENTREGA),
                  (:new.DTENTREGA),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.DTFAT) <> (:new.DTFAT)
      then
        GERAR_LOG('DTFAT',
                  (:old.DTFAT),
                  (:new.DTFAT),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.CODIGONUMERICOCHAVE) <> (:new.CODIGONUMERICOCHAVE)
      then
        GERAR_LOG('CODIGONUMERICOCHAVE',
                  (:old.CODIGONUMERICOCHAVE),
                  (:new.CODIGONUMERICOCHAVE),
                  :new.NUMTRANSVENDA);
      end if;
      if (:old.TIPOIMPRESSAO) <> (:new.TIPOIMPRESSAO)
      then
        GERAR_LOG('TIPOIMPRESSAO',
                  (:old.TIPOIMPRESSAO),
                  (:new.TIPOIMPRESSAO),
                  :new.NUMTRANSVENDA);
      end if;

	IF NVL(:OLD.VLOUTRASDESP, 0) <> NVL(:NEW.VLOUTRASDESP, 0) THEN
	   GERAR_LOG('VLOUTRASDESP',
				 TO_CHAR(:OLD.VLOUTRASDESP),
				 TO_CHAR(:NEW.VLOUTRASDESP),
				 :NEW.NUMTRANSVENDA);
	END IF;
	IF NVL(:OLD.VLFRETE, 0) <> NVL(:NEW.VLFRETE, 0) THEN
	   GERAR_LOG('VLFRETE',
				 TO_CHAR(:OLD.VLFRETE),
				 TO_CHAR(:NEW.VLFRETE),
				 :NEW.NUMTRANSVENDA);
	END IF;
	IF NVL(:OLD.PRAZOMEDIO, 0) <> NVL(:NEW.PRAZOMEDIO, 0) THEN
	   GERAR_LOG('PRAZOMEDIO',
				 TO_CHAR(:OLD.PRAZOMEDIO),
				 TO_CHAR(:NEW.PRAZOMEDIO),
				 :NEW.NUMTRANSVENDA);
	END IF;  
	IF NVL(:OLD.CODUSUR, 0) <> NVL(:NEW.CODUSUR, 0) THEN
	   GERAR_LOG('CODUSUR',
				 TO_CHAR(:OLD.CODUSUR),
				 TO_CHAR(:NEW.CODUSUR),
				 :NEW.NUMTRANSVENDA);
	END IF;  
	IF NVL(:OLD.CODCLI, 0) <> NVL(:NEW.CODCLI, 0) THEN
	   GERAR_LOG('CODCLI',
				 TO_CHAR(:OLD.CODCLI),
				 TO_CHAR(:NEW.CODCLI),
				 :NEW.NUMTRANSVENDA);
	END IF;
	IF NVL(:OLD.VLTOTAL, 0) <> NVL(:NEW.VLTOTAL, 0) THEN
	   GERAR_LOG('VLTOTAL',
				 TO_CHAR(:OLD.VLTOTAL),
				 TO_CHAR(:NEW.VLTOTAL),
				 :NEW.NUMTRANSVENDA);
	END IF;
	IF NVL(:OLD.VLTOTGER, 0) <> NVL(:NEW.VLTOTGER, 0) THEN
	   GERAR_LOG('VLTOTGER',
				 TO_CHAR(:OLD.VLTOTGER),
				 TO_CHAR(:NEW.VLTOTGER),
				 :NEW.NUMTRANSVENDA);
	END IF;      

      GERAR_LOG('HORALANC',
                  (:old.HORALANC),
                  (:new.HORALANC),
                  :new.NUMTRANSVENDA);
                  
      GERAR_LOG('MINUTOLANC',
                  (:old.MINUTOLANC),
                  (:new.MINUTOLANC),
                  :new.NUMTRANSVENDA);            
    end if;
  else
    GERAR_LOG('DTSAIDA',
              (:old.DTSAIDA),
              (:new.DTSAIDA),
              :new.NUMTRANSVENDA);
  
    GERAR_LOG('DTSAIDANF',
              (:old.DTSAIDANF),
              (:new.DTSAIDANF),
              :new.NUMTRANSVENDA);
  
    GERAR_LOG('DTENTREGA',
              (:old.DTENTREGA),
              (:new.DTENTREGA),
              :new.NUMTRANSVENDA);
  
    GERAR_LOG('DTFAT',
              (:old.DTFAT),
              (:new.DTFAT),
              :new.NUMTRANSVENDA);
              
    GERAR_LOG('HORALANC',
              (:old.HORALANC),
              (:new.HORALANC),
              :new.NUMTRANSVENDA);
                  
    GERAR_LOG('MINUTOLANC',
              (:old.MINUTOLANC),
              (:new.MINUTOLANC),
              :new.NUMTRANSVENDA);                  
  end if;

  --REGISTRA A INSERÇÃO DA NOTA, PARA MEDIR TEMPO DE PROCESSAMENTO ATÉ SUA APROVAÇÃO E CONSOLIDAÇÃO NO WTA
  IF ((NVL(:NEW.ESPECIE, 'X') = 'NF') AND (:NEW.SITUACAONFE = 100) AND (:OLD.SITUACAONFE IS NULL)) THEN
    INSERT INTO PCMEDIATEMPOAPROVACAONFE(NUMTRANSACAO, TIPOMOV, EVENTO, DATAHORAEVENTO, SITUACAONFE)
    VALUES (:NEW.NUMTRANSVENDA, 'S', 'FIM', SYSDATE, 100);    
  END IF;
  
exception
  when others then
    GERAR_LOG('NENHUM',
              '',
              'ERRO AO GERAR RASTREABILIDADE NFE',
              :new.NUMTRANSVENDA,
              'ERRO OCORRIDO: ' || sqlerrm);
  
end;