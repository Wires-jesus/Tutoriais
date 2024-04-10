DECLARE
  TYPE ListaSequences IS TABLE OF VARCHAR2(60);
  nomeSequence ListaSequences := ListaSequences('DFSEQ_PCINTEGRACAODADOSEMPRESA',
                                                'DFSEQ_PCINTEGRACAOROTASERVICO',
                                                'DFSEQ_PCINTEGRACAOVARIAVEIS',
                                                'DFSEQ_PCINTEGRACAOCORE',
                                                'DFSEQ_PCINTEGRACAOVARIAVELTEMP',
                                                'DFSEQ_INTEGRACAODADOSRECEBIDOS',
                                                'DFSEQ_PCINTEGRACAOAGENDAMENTO',
                                                'DFSEQ_PCINTEGRAFLUXOEXECUCAO',
                                                'DFSEQ_PCINTEGRAERROREQUISICAO');

  vContador NUMBER;
  VSQL      VARCHAR2(5000) := '';
BEGIN

  FOR i IN 1 .. nomeSequence.COUNT LOOP
    SELECT COUNT(1) INTO vContador FROM USER_SEQUENCES S WHERE S.sequence_name = nomeSequence(i);
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRACAODADOSEMPRESA') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRACAODADOSEMPRESA minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRACAOROTASERVICO') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRACAOROTASERVICO minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRACAOVARIAVEIS') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRACAOVARIAVEIS minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRACAOCORE') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRACAOCORE minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRACAOVARIAVELTEMP') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRACAOVARIAVELTEMP minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_INTEGRACAODADOSRECEBIDOS') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_INTEGRACAODADOSRECEBIDOS minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRACAOAGENDAMENTO') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRACAOAGENDAMENTO minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRAERROREQUISICAO') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRAERROREQUISICAO minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeSequence(i) = 'DFSEQ_PCINTEGRAFLUXOEXECUCAO') AND (vContador = 0) THEN
      VSQL := ' create sequence DFSEQ_PCINTEGRAFLUXOEXECUCAO minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache order';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  END LOOP;
END;