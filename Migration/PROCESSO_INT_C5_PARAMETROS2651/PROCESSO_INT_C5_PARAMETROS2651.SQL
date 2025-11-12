BEGIN

  BEGIN
    MERGE INTO PCPARAMETROS2651 T
    USING (
      SELECT 'TIMER_SINCRONIZACAO_CARGA_DESCIDA' NOME, '00:15:00' VALOR, 'Intervalo de carga da descida de dados' DESCRICAO, '99' CODFILIAL FROM DUAL
      UNION ALL
      SELECT 'TIMER_SINCRONIZACAO_CARGA_SUBIDA' NOME, '30000' VALOR, 'Intervalo de carga da subida de dados' DESCRICAO, '99' CODFILIAL FROM DUAL
      UNION ALL
      SELECT 'SINCRONIZAR_COM_TELA_ABERTA' NOME, 'N' VALOR, 'Se o timer continua rodando em background' DESCRICAO, '99' CODFILIAL FROM DUAL
    ) S
    ON (T.NOME = S.NOME)
    WHEN NOT MATCHED THEN
      INSERT (
        NOME,
        DESCRICAO,
        VALOR,
        CODFILIAL
      )
      VALUES (
        S.NOME,
        S.DESCRICAO,
        S.VALOR,
        S.CODFILIAL
      );
  END;

  DECLARE
    vVariavel NUMBER;
    vSEqMarca NUMBER;
  BEGIN
    BEGIN
      SELECT VALOR INTO vVariavel
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
        FROM PCCONSUM;
      END;

      INSERT INTO PCMARCA (CODMARCA, MARCA, ATIVO, DTCADASTRO)
      VALUES (vSEqMarca, 'MARCA PADRAO PDV SUPER', 'S', SYSDATE);

      UPDATE PCPARAMFILIAL
      SET VALOR = TO_CHAR(vSEqMarca)
      WHERE NOME = 'MARCAINTEGRACAOCONSINCO';

      COMMIT;
    END IF;
  END;

  BEGIN
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

END;