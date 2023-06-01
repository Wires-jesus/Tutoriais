CREATE OR REPLACE PROCEDURE PRC_GERA_PCPESSOA
IS
   REC_CLI   PCCLIENT%ROWTYPE;
BEGIN
   FOR R_FOR IN (SELECT    *
                      FROM PCFORNEC)
   LOOP
      INSERT INTO PCPESSOA
                  (CODPESSOA
                 , CODFORNECEDOR
                 , EFORNECEDOR
                 , CODFUNCADASTRO
                 , DTCADASTRO
                 , CNPJCPF
                 , NOME
                 , FANTASIA
                  )
           VALUES (PCPESSOA_DFSEQ.NEXTVAL
                 , R_FOR.CODFORNEC
                 , 'S'
                 , 1
                 , SYSDATE
                 , NVL (R_FOR.CGC, '11111111111')
                 , R_FOR.FORNECEDOR
                 , R_FOR.FANTASIA
                  );

      BEGIN
         SELECT    *
              INTO REC_CLI
              FROM PCCLIENT
             WHERE PCCLIENT.CODCLI = R_FOR.CODCLI;

         UPDATE PCPESSOA
            SET CODCLIENTE = REC_CLI.CODCLI
              , ECLIENTE = 'S'
          WHERE PCPESSOA.CODFORNECEDOR = R_FOR.CODFORNEC;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      COMMIT;
   END LOOP;

   FOR R_CLI IN (SELECT    *
                      FROM PCCLIENT
                     WHERE PCCLIENT.CODCLI NOT IN (SELECT DISTINCT CODCLI
                                                        FROM PCFORNEC
                                                       WHERE CODCLI IS NOT NULL))
   LOOP
      INSERT INTO PCPESSOA
                  (CODPESSOA
                 , CODCLIENTE
                 , ECLIENTE
                 , CODFUNCADASTRO
                 , DTCADASTRO
                 , CNPJCPF
                 , NOME
                 , FANTASIA
                  )
           VALUES (PCPESSOA_DFSEQ.NEXTVAL
                 , R_CLI.CODCLI
                 , 'S'
                 , 1
                 , SYSDATE
                 , NVL (R_CLI.CGCENT, '11111111111')
                 , R_CLI.CLIENTE
                 , R_CLI.FANTASIA
                  );

      COMMIT;
   END LOOP;
END PRC_GERA_PCPESSOA;
