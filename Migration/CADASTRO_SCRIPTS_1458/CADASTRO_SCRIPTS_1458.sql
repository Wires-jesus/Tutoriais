DECLARE
  vCodMensagem number(10);
  vNomeMensagem varchar2(300);
  vMovimento varchar2(3);

  function getNextvalSequence return number is
    vretorno number(10);
  begin
    select dfseq_pcmensagemadicional.nextval into vretorno from dual;
    return vretorno;
  end;
  
  function mensagemJaExiste(vNome varchar2, vMovimento varchar2) return varchar2 is
	vQtd number(10);
	vretorno varchar2(1);
  begin
	select count(*) into vQtd from pcmensagemadicional where upper(descricao) = upper(vNome) and upper(movimento) = upper(vMovimento);
	
	if vQtd > 0 then
		return 'S';
	else
		return 'N';
	end if;	
  end;
  
  procedure deletarMensagemExiste(vNome varchar2, vMovimento varchar2) is
  begin
	delete from pcmensagemadicional where upper(descricao) = upper(vNome) and upper(movimento) = upper(vMovimento);
  end;

BEGIN
  vNomeMensagem := '';
  vMovimento := '';
  
------------------------------------------------------------------------------------------------------------------------------
  ------------------Inicio: Operação sujeita à redução linear de benefícios da LC 224/2025 (NF-e)------------------
  vCodMensagem := getNextvalSequence();
  vNomeMensagem := 'Operação sujeita à redução linear de benefícios da LC 224/2025 (NF-e)';
  vMovimento := 'SA';
  
  if mensagemJaExiste(vNomeMensagem, vMovimento) = 'S' then
	deletarMensagemExiste(vNomeMensagem, vMovimento);
  end if;
  
  INSERT INTO PCMENSAGEMADICIONAL
    (CODMENSAGEM, DESCRICAO, MOVIMENTO, SQL, MENSAGEMATIVA, OBRIGATORIA)
  VALUES
    (vCodMensagem,
     vNomeMensagem,
     vMovimento,
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
------------------------------------------------------------------------------------------------------------------------------
  
  
  COMMIT;
END;
