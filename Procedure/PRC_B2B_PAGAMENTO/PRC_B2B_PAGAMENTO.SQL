CREATE OR REPLACE PROCEDURE PRC_B2B_PAGAMENTO(P_NUMPEDWEB NUMBER) 
IS
   v_COUNT        NUMBER;
   v_Matricula    PCECOMMERCEB2B.MATRICULA%type;
   v_Mensagem     VARCHAR2(500);
   v_Cancelado    VARCHAR2(1);
   v_MensagemErro VARCHAR2(1);
BEGIN
   v_MensagemErro := 'S';
   -- VERIFICA SE O PEDIDO EXISTE NA TABELA DE INTEGRAÇÃO
   FOR DADOS IN (SELECT CODFILIAL, 
                        TIPOINTEGRACAO,
                        NVL(STATUS,'ER') STATUS
                 FROM PCECOMMERCEB2BPAGAMENTO
                 WHERE NUMPED = P_NUMPEDWEB)
   LOOP
      v_MensagemErro := 'N';
      -- VERIFICA O NUMPED
      FOR PED IN (SELECT NUMPEDWEB,
                         CODFILIAL,
                         NUMPED
                  FROM PCPEDC
                  WHERE NUMPEDWEB = P_NUMPEDWEB
                    AND CODFILIAL = DADOS.CODFILIAL)
      LOOP
         -- VERIFICA SE O PEDIDO EXISTE NA PAGAMENTOS
         BEGIN
            SELECT COUNT(1)
            INTO v_COUNT
            FROM PCBLOQUEIOSPEDIDO
            WHERE NUMPED = PED.NUMPED;
         EXCEPTION WHEN OTHERS THEN
            v_COUNT := 0;
         END;

         IF v_COUNT = 0 THEN
            BEGIN
               UPDATE PCECOMMERCEB2BPAGAMENTO P
                   SET P.LOG = 'Pedido não encontrado na tabela PCBLOQUEIOSPEDIDO',
                       P.PROCESSADO = 'ERR'
               WHERE P.NUMPED = PED.NUMPED
                 AND P.CODFILIAL = PED.CODFILIAL
                 AND P.TIPOINTEGRACAO = DADOS.TIPOINTEGRACAO;
            EXCEPTION WHEN OTHERS THEN
               NULL;
            END;
         ELSE
      	    BEGIN
      	       -- Recupera usuário da tabela PCECOMMERCEB
      	       SELECT MATRICULA
      	       INTO v_Matricula
      	       FROM PCECOMMERCEB2B
      	       WHERE CODFILIAL = PED.CODFILIAL
      	         AND TIPOINTEGRACAO = DADOS.TIPOINTEGRACAO
      	         AND ROWNUM <= 1;
      	    EXCEPTION WHEN OTHERS THEN
      	       v_Matricula := 0;
      	       RAISE_APPLICATION_ERROR(-20000, 'Erro ao recuperar a matricula do usuário na tabela PCECOMMERCEB2B.');
      	    END;
      	    -- Faz a alteração da tabela PCBLOQUEIOSPEDIDO
      	    IF DADOS.STATUS = 'AP' THEN
      	       -- Pagamento aprovado
      	       UPDATE PCBLOQUEIOSPEDIDO B
      	       SET B.STATUS = 'L',
      	           B.CODFUNCLIBERA = v_Matricula,
      	           B.DTLIBERA = SYSDATE
      	       WHERE B.NUMPED = PED.NUMPED;

      	       UPDATE PCECOMMERCEB2BPAGAMENTO P
      	       SET P.LOG = 'Pagamento aprovado.',
      	           P.PROCESSADO = 'SIM'
      	       WHERE P.NUMPED = PED.NUMPEDWEB
                 AND P.TIPOINTEGRACAO = DADOS.TIPOINTEGRACAO 
                 AND P.CODFILIAL = DADOS.CODFILIAL;
      	    ELSIF DADOS.STATUS = 'RP' THEN
      	       -- Pagamento reprovado - Cancela o pedido
               PKG_CANCELA_PEDIDO.PRC_CANCELA(PED.NUMPED,
                                              v_Matricula,
                                              'Cancelamento B2B',
                                              0,
                                              v_Mensagem,
                                              v_Cancelado);
               IF v_cancelado = 'S' THEN
                  UPDATE PCECOMMERCEB2BPAGAMENTO P
                  SET P.LOG = 'Pagamento reprovado.',
                      P.PROCESSADO = 'SIM'
                  WHERE P.NUMPED = PED.NUMPEDWEB
                    AND P.TIPOINTEGRACAO = DADOS.TIPOINTEGRACAO
                    AND P.CODFILIAL = DADOS.CODFILIAL;
      	       ELSE
                  UPDATE PCECOMMERCEB2BPAGAMENTO P
                  SET P.LOG = 'Erro ao cancelar pedido: '|| SUBSTR(v_Mensagem,1,400),
                      P.PROCESSADO = 'ERR'
                  WHERE P.NUMPED = PED.NUMPEDWEB
                    AND P.CODFILIAL = DADOS.CODFILIAL
                    AND P.TIPOINTEGRACAO = DADOS.TIPOINTEGRACAO;
      	       END IF;
      	    END IF;

            COMMIT;
         END IF;
      END LOOP;	 	 
   END LOOP;
   
   IF v_MensagemErro = 'S' THEN
      RAISE_APPLICATION_ERROR(-20000, 'Pedido não encontrado na tabela de integração.');
   END IF;
END PRC_B2B_PAGAMENTO;
