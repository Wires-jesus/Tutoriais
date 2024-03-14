CREATE OR REPLACE TRIGGER LOG_PCMOV 
  BEFORE INSERT OR UPDATE ON PCMOV
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
DECLARE
  /*******************************************************************************
                           Historico de Alteracoes
  --------------------------------------------------------------------------------
    Data        Responsavel    Tarefa    Alteracao
   -----------  -------------  --------  -----------------------------------------
    15/01/2007  Sabrina        37619     Correcao na gravacao de dados de usuario
                                         para tratar quando a execucao for
                                         acionada por jobs e nao usuarios
    16/03/2010  Pablo          103340    Alteração para gravar o campo NEW.equiplanc somente com 64 posições
                                         conf. orientação do DBA MAx
    24/05/2016  Rafael Braga        0    Ajustado para gravar log de alteração de preços e quantidades, conforme
                                         solicitado por Hugo Silva.
    26/09/2017  Rubens Paulo        0    Adição dos campos numnota e dtcancel para gerar log.

    11/03/2020  Paulo Castro  8208367    limitar a gravacao no campo rotinacad somente na insercao
  *******************************************************************************/
  VSEQUIPAMENTO VARCHAR2(64);
  VSUSUARIO     VARCHAR2(30);
  VSPROGRAMA    VARCHAR2(48);
BEGIN

  if (SYS_CONTEXT('USERENV', 'MODULE') not like '%PCSIS1000%') then

  IF :NEW.CODFILIALNF IS NULL THEN
    :NEW.CODFILIALNF := :NEW.CODFILIAL;
  END IF;

  VSEQUIPAMENTO := SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64);
  VSUSUARIO     := SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30);
  VSPROGRAMA    := SUBSTR(UPPER(SYS_CONTEXT('USERENV', 'MODULE')), 1, 48);
  IF NOT(TRIM(VSPROGRAMA) LIKE '%PCSIS%') THEN
    VSPROGRAMA  := f_obternomeaplicacao;
  END IF;

  :NEW.HORALANC   := TO_CHAR(SYSDATE, 'HH24');
  :NEW.MINUTOLANC := TO_CHAR(SYSDATE, 'MI');
  :NEW.ROTINALANC := VSPROGRAMA;
  IF INSERTING THEN
    :NEW.ROTINACAD  := NVL(:NEW.ROTINACAD, NVL(:OLD.ROTINALANC, VSPROGRAMA));
  END IF;
  :NEW.EQUIPLANC  := SUBSTR(VSEQUIPAMENTO, 1, 64);
  :NEW.FUNCLANC   := VSUSUARIO;

  if (:new.punit <> :old.punit) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'PUNIT',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'PUNIT ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.PUNIT,
       :NEW.PUNIT
       );
  end if;

  if (:new.punitcont <> :old.punitcont) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'PUNITCONT',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'PUNITCONT ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.PUNITCONT,
       :NEW.PUNITCONT
       );
  end if;

  if (:new.qt <> :old.qt) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'QT',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'QT ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.QT,
       :NEW.QT
       );
  end if;

  if (:new.qtcont <> :old.qtcont) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'QTCONT',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'QT ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.QTCONT,
       :NEW.QTCONT
       );
  end if;

  if (:new.numnota <> :old.numnota) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'NUMNOTA',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'NUMNOTA ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.NUMNOTA,
       :NEW.NUMNOTA
       );
  end if;

  if (:new.dtcancel <> :old.dtcancel) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'DTCANCEL',
       'D',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'DTCANCEL ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.DTCANCEL,
       :NEW.DTCANCEL
       );
  end if;
  if (:new.VLFRETE <> :old.VLFRETE) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'VLFRETE',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'VLFRETE ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.VLFRETE,
       :NEW.VLFRETE
       );
  end if;
  if (:new.LOCALIZACAO <> :old.LOCALIZACAO) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'LOCALIZACAO',
       'A',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'LOCALIZACAO ALT ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.LOCALIZACAO,
       :NEW.LOCALIZACAO
       );
  end if;
  if (:new.DTMOV <> :old.DTMOV) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'DTMOV',
       'D',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'DTMOV ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.DTMOV,
       :NEW.DTMOV
       );
  end if;
  if (:new.NUMCAR <> :old.NUMCAR) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'NUMCAR',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'NUMCAR ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.NUMCAR,
       :NEW.NUMCAR
       );
  end if;
  if (:new.CUSTOFIN <> :old.CUSTOFIN) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'CUSTOFIN',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'CUSTOFIN ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.CUSTOFIN,
       :NEW.CUSTOFIN
       );
  end if; 
  if (:new.NUMPED <> :old.NUMPED) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'NUMPED',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'NUMPED ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.NUMPED,
       :NEW.NUMPED
       );
  end if;
  if (:new.NUMBONUS <> :old.NUMBONUS) then
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORALFAANT,
       PCLOGALTERACAODADOS.VALORALFA
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'NUMBONUS',
       'N',
       'MUDANÇA DE INFORMAÇÃO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'NUMBONUS ALTERADO ' || 'NUMTRANSVENDA: ' || TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)) || ' NUMTRANSENT: ' || TO_CHAR(NVL(:NEW.NUMTRANSENT, 0)),
       ' NUMNOTA: ' || TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD || ' NUMSEQ: ' || :NEW.NUMSEQ,
       :OLD.NUMBONUS,
       :NEW.NUMBONUS
       );
  end if;
 end if;
END;

