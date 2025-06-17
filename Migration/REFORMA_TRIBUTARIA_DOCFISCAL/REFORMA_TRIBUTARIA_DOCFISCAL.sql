declare
  vErro varchar2(200);
BEGIN
  insert into pccentronotificdocfiscal
    (codnotificacao,
     tiponotificacao,
     notificacao,
     textoadicional,
     visualizado,
     datanotificacao)
  values
    (dfseq_pccentronotificdocfiscal.nextval,
     'infoinfoinfoinfoinfoinfoinfoinfoinfoinfo',
     'Objetos da Reforma Tributaria para o DocFiscal atualizados com sucesso!',
     'Todos os objetos necessários para o DocFiscal, referentes a reforma tributaria, foram atualizados com sucesso em ' ||
     to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') || '.',
     'N',
     sysdate);

EXCEPTION
  WHEN OTHERS THEN
    vErro := SQLERRM;
    INSERT INTO PCLOGFATURAMENTO
      (CODLOG, DATAHORA, PROCESSO, MAQUINA, TERMINAL, OSUSER, LOG, TIPOLOG)
    VALUES
      (DFSEQ_PCLOGFATURAMENTO.NEXTVAL,
       SYSDATE,
       'REFORMA_TRIBUTARIA_DOCFISCAL',
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       ('Erro ao atualizar objetos da reforma tributaria do DocFiscal. Erro: ' || vErro),
       'ERROR');
END;