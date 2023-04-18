CREATE OR REPLACE PROCEDURE PRC_GERARAGENDAMENTO(PI_DATAAGENDA         IN DATE,
                                                 PI_HORA               IN DATE,
                                                 PI_ASSUNTO            IN VARCHAR2,
                                                 PI_CODFUNCAB          IN PCEMPR.MATRICULA%TYPE,
                                                 PI_CONSIDERA_OPER_CLI IN BOOLEAN DEFAULT FALSE,
                                                 PI_CODPESQUISA        IN NUMBER DEFAULT NULL,
                                                 PI_CODMOTIVOAGENDA    IN NUMBER DEFAULT NULL
                                                 ) IS
   MATRICULA_AGENDA PCEMPR.MATRICULA%TYPE;
   STATUS_OPERADOR  VARCHAR2(1);
BEGIN

   FOR X IN (SELECT NUMERO CODCLI, NUMDECIMAL MATRICULA
               FROM PCTEMP_SELECIONADOS
              WHERE NUMERO IS NOT NULL
                AND NUMDECIMAL IS NOT NULL) LOOP
      BEGIN
      
         IF PI_CONSIDERA_OPER_CLI THEN
         
            SELECT MIN(MATRICULA)
              INTO MATRICULA_AGENDA
              FROM PCEMPR
             WHERE CODUSUR IN (SELECT CODUSUR
                                FROM VW_USURCLI
                               WHERE CODCLI = X.CODCLI
                                 AND TIPOOPER IN ('OO','A','T','P', 'B', 'R'));
         
            IF MATRICULA_AGENDA IS NULL THEN
            
               MATRICULA_AGENDA := X.MATRICULA;
            
            END IF;
         
         ELSE
         
            MATRICULA_AGENDA := X.MATRICULA;
         
         END IF;
      
         SELECT NVL(PCEMPR.SITUACAO, 'I')
           INTO STATUS_OPERADOR
           FROM PCEMPR
          WHERE MATRICULA = MATRICULA_AGENDA;
      
         IF STATUS_OPERADOR = 'A' THEN
         
            INSERT INTO PCAGENDA
               (CODAGENDA,
                CODCLI,
                DATA,
                CODOPERADORA,
                OBS,
                STATUS,
                DIASEMANA,
                HORA,
                CODFUNCAB,
                DTAB,
                CODPESQUISA,
                PCAGENDA.CODMOTIVO)
            VALUES
               (DFSEQ_PCAGENDA.NEXTVAL,
                X.CODCLI,
                PI_DATAAGENDA,
                MATRICULA_AGENDA,
                PI_ASSUNTO,
                'AB',
                TO_CHAR(PI_DATAAGENDA, 'D'),
                PI_HORA,
                PI_CODFUNCAB,
                SYSDATE,
                (SELECT PCPESQUISA.CODPESQUISA
                   FROM PCPESQUISA
                  WHERE PCPESQUISA.CODPESQUISA = PI_CODPESQUISA
                    AND TRUNC(PI_DATAAGENDA) BETWEEN
                        TRUNC(PCPESQUISA.DTINICIO) AND
                        TRUNC(PCPESQUISA.DTFIM)
                    AND PCPESQUISA.ATIVA = 'A'),
                 PI_CODMOTIVOAGENDA);
         
         END IF;
      
      EXCEPTION
      
         WHEN OTHERS THEN
            NULL;
         
      END;
   
   END LOOP;

   COMMIT;

END PRC_GERARAGENDAMENTO; 
