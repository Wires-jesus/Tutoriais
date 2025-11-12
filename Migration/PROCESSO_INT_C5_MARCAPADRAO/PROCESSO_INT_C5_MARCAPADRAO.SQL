BEGIN
    DECLARE
        vVariavel NUMBER;
        vSEqMarca NUMBER;
    BEGIN
        BEGIN
            SELECT VALOR
              INTO vVariavel
              FROM PCPARAMFILIAL
             WHERE NOME = 'MARCAINTEGRACAOCONSINCO'
               AND CODFILIAL = '99';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                vVariavel := NULL;  
        END;

			IF vVariavel IS NULL THEN 
				BEGIN
					SELECT DFSEQ_PCMARCA.NEXTVAL
					  INTO vSEqMarca
					  FROM PCCONSUM
					 WHERE ROWNUM = 1; 

				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						SELECT DFSEQ_PCMARCA.NEXTVAL
						  INTO vSEqMarca
						  FROM DUAL;
				END;
            
            INSERT INTO PCMARCA (CODMARCA, MARCA, ATIVO, DTCADASTRO)
            VALUES (vSEqMarca, 'MARCA PADRAO PDV SUPER', 'S', SYSDATE);

            UPDATE PCPARAMFILIAL
               SET VALOR = TO_CHAR(vSEqMarca)
             WHERE NOME = 'MARCAINTEGRACAOCONSINCO'
               AND CODFILIAL = '99';
        END IF;
    END;

    DELETE FROM PCPARAMFILIAL
     WHERE NOME IN (
            'USUARIOCONSINCO',
            'SENHAUSUARIOCONSINCO',
            'IPINTEGRACAOCONSINCO',
            'SERVICOINTEGRACAOCONSINCO',
            'PORTAINTEGRACAOCONSINCO'
     );

    DELETE FROM PCMETAPARAMFILIAL
     WHERE ID IN (4701, 4702, 4703, 4704, 4705);

    UPDATE PCMETAPARAMFILIAL
       SET TITULO = 'Utiliza integração PDV Supermercados',
           TEXTOAJUDA = 'Com o parâmetro habilitado, a filial irá usar o PDV Supermercados, habilitando as configurações de integração para finalizadoras, produtos, promoções, descontos por gatilho (561 e 357), kits, cestas, produtos acabados, clientes e tributações'
     WHERE ID = 4691;

    UPDATE PCMETAPARAMFILIAL
       SET TITULO = 'Código da marca padrão utilizada na Integração do PDV Supermercados',
           TEXTOAJUDA = 'Código da marca padrão utilizada na Integração PDV Supermercados'
     WHERE ID = 4706;

    COMMIT;


EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;