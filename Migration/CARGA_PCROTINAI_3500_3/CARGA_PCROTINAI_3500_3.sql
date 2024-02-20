--CARGA_PCROTINAI_3500_3
DECLARE
 iCount INTEGER;
BEGIN
  FOR DADOS IN (
                SELECT '3501' AS CODROTINA, '1'  AS CODCONTROLE, 'Permitir alterar percentual de CPRB' AS DESCRICAO FROM DUAL UNION
                SELECT '3501' AS CODROTINA, '2'  AS CODCONTROLE, 'Permitir alterar tempo serviço para execução do serviço/ percentual de incidência' AS DESCRICAO FROM DUAL UNION
                SELECT '3502' AS CODROTINA, '1'  AS CODCONTROLE, 'Permitir criar/editar layout de relatório' AS DESCRICAO FROM DUAL UNION
                SELECT '3505' AS CODROTINA, '1'  AS CODCONTROLE, 'Permitir criar/editar layout de relatório' AS DESCRICAO FROM DUAL UNION

                SELECT '3503' AS CODROTINA, '1'  AS CODCONTROLE, 'Permitir remover serviço da OS' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '2'  AS CODCONTROLE, 'Permitir remover produto utilizado da OS' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '3'  AS CODCONTROLE, 'Permitir remover funcionário da OS' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '4'  AS CODCONTROLE, 'Cancelar ordem de serviço' AS DESCRICAO FROM DUAL UNION

                SELECT '3503' AS CODROTINA, '5'  AS CODCONTROLE, 'Permitir abrir OS para cliente bloqueado' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '6'  AS CODCONTROLE, 'Permitir Situação OS de "EM EXECUÇÃO" para "ABERTA"' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '7'  AS CODCONTROLE, 'Restringir a alt. da sit. da OS para "EM EXECUÇÃO"' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '8'  AS CODCONTROLE, 'Restringir a alt. da sit. da OS para Fechada' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '9'  AS CODCONTROLE, 'Restringir o Faturamento da Ordem de Serviço' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '10'  AS CODCONTROLE, 'Obrigar o preenchimento da data e ehora de exeução do serviço' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '11'  AS CODCONTROLE, 'Permitir redução do preço do serviço' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '12' AS CODCONTROLE, 'Permitir alterar status OS fechada' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '13' AS CODCONTROLE, 'Não permite alterar o percentual de ISS' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '14' AS CODCONTROLE, 'Não permite alterar situação de OS de Fechada para Cancelada' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '15' AS CODCONTROLE, 'Permitir alterar condição de pagamento para OS Fechada' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '16' AS CODCONTROLE, 'Permitir alterar preço do produto' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '17' AS CODCONTROLE, 'Permitir alterar quantidade do produto' AS DESCRICAO FROM DUAL UNION
                SELECT '3503' AS CODROTINA, '18' AS CODCONTROLE, 'Permitir aplicar desconto no valor total da OS' AS DESCRICAO FROM DUAL UNION
                SELECT '3508' AS CODROTINA, '1'  AS CODCONTROLE, 'Permitir criar/editar layout de orçamento' AS DESCRICAO FROM DUAL UNION
                SELECT '3508' AS CODROTINA, '2'  AS CODCONTROLE, 'Permitir alterar preço do serviço no orçamento' AS DESCRICAO FROM DUAL UNION
                SELECT '3508' AS CODROTINA, '3'  AS CODCONTROLE, 'Permitir alterar status do orçamento' AS DESCRICAO FROM DUAL UNION
                SELECT '3508' AS CODROTINA, '4'  AS CODCONTROLE, 'Permitir alterar status dos serviço' AS DESCRICAO FROM DUAL UNION
                SELECT '3508' AS CODROTINA, '5'  AS CODCONTROLE, 'Permitir alterar status dos produtos' AS DESCRICAO FROM DUAL
    ) LOOP  

    SELECT COUNT (*) INTO iCount FROM PCROTINAI WHERE PCROTINAI.CODROTINA = DADOS.CODROTINA AND PCROTINAI.CODCONTROLE = DADOS.CODCONTROLE;
    IF iCount = 0 THEN    
      EXECUTE IMMEDIATE 'INSERT INTO PCROTINAI (CODROTINA, CODCONTROLE, DESCRICAO) VALUES ('||DADOS.CODROTINA||','||DADOS.CODCONTROLE||', '''||DADOS.DESCRICAO||''')';
    END IF;
  END LOOP;
  COMMIT;
END;
