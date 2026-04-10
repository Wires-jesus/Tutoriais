DECLARE
  vCodMensagem number(10);

  function getNextvalSequence return number is
    vretorno number(10);
  begin
    select dfseq_pcmensagemadicional.nextval into vretorno from dual;
    return vretorno;
  end;

BEGIN
  vCodMensagem := getNextvalSequence();
  ------------------Inicio: Operação sujeita à redução linear de benefícios da LC 224/2025 (NF-e)------------------
  INSERT INTO PCMENSAGEMADICIONAL
    (CODMENSAGEM, DESCRICAO, MOVIMENTO, SQL, MENSAGEMATIVA, OBRIGATORIA)
  VALUES
    (vCodMensagem,
     'Operação sujeita à redução linear de benefícios da LC 224/2025 (NF-e)',
     'SA',
     'SELECT DISTINCT MENSAGEM01
		  FROM (SELECT ''Operação sujeita à redução linear de benefícios da LC 224/2025'' MENSAGEM01
				FROM PCNFSAID
				    ,PCMOV
			        ,PCMOVCOMPLE
				    ,PCTRIBPISCOFINSVIGENCIA
			   WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
			     AND PCMOVCOMPLE.CODTRIBPISCOFINS = PCTRIBPISCOFINSVIGENCIA.CODTRIBPISCOFINS
			     AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
				 AND PCMOV.DTMOV BETWEEN PCTRIBPISCOFINSVIGENCIA.DTINICIO AND PCTRIBPISCOFINSVIGENCIA.DTFINAL
				 AND PCTRIBPISCOFINSVIGENCIA.LC22425 = ''S''
				 AND PCNFSAID.NUMTRANSVENDA = :NUM_TRANSACAO 
			  UNION
			  SELECT ''Operação sujeita à redução linear de benefícios da LC 224/2025'' MENSAGEM01
				FROM PCNFSAID
				    ,PCMOV
			        ,PCMOVCOMPLE
				    ,PCTRIBPISCOFINS
			   WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
			     AND PCMOVCOMPLE.CODTRIBPISCOFINS = PCTRIBPISCOFINS.CODTRIBPISCOFINS
			     AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
			     AND PCTRIBPISCOFINS.LC22425 = ''S''
			     AND PCNFSAID.NUMTRANSVENDA = :NUM_TRANSACAO )',
			 'S',
     'N');

  INSERT INTO PCMENSAGEMADICIONALITENS
    (CODMENSAGEM, ORDEM, TEXTO)
  VALUES
    (vCodMensagem, 0, '[MENSAGEM01]');
  ------------------Fim: Operação sujeita à redução linear de benefícios da LC 224/2025 (NF-e)------------------

  
  
  COMMIT;
END;
