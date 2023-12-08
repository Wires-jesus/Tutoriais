CREATE OR REPLACE TRIGGER TRG_PCPRODUT_LOGFISCAL
       BEFORE UPDATE
           OF DESCRICAO
           ON PCPRODUT
       REFERENCING OLD AS OLD NEW AS NEW
       FOR EACH ROW
      DECLARE
        VQT NUMBER; 
        PROCEDURE GERAR_LOG(PCAMPO         IN VARCHAR2,
                            PTABELA        IN VARCHAR2,
                            PVALORALFA     IN VARCHAR2,
                            PVALORALFAANT  IN VARCHAR2,
                            PREGISTRO      IN VARCHAR2,
                            PCODPROD       IN NUMBER
                            ) IS
        BEGIN
        INSERT INTO PCLOGFISCAL
          (DATA,
           REGISTRO,
           CODIGO,
           VALORALFA,
           VALORALFAANT,
           TABELA,
           COLUNA)
         VALUES
          (SYSDATE,
           PREGISTRO,
           PCODPROD,
           PVALORALFA,
           PVALORALFAANT,
           PTABELA,
           PCAMPO);
       
           SELECT NVL(COUNT(CODPROD),0) 
             INTO VQT 
             FROM PCLOGULTALTPRODUT 
            WHERE CODPROD = :NEW.CODPROD; 
             IF VQT > 0  THEN 
               UPDATE PCLOGULTALTPRODUT 
                  SET DATPRIMOV = NULL 
                WHERE CODPROD = PCODPROD; 
             ELSE 
               INSERT INTO PCLOGULTALTPRODUT (SELECT CODIGO,PCODPROD,TRUNC(SYSDATE),NULL FROM PCFILIAL GROUP BY CODIGO); 
             END IF; 
        END;
BEGIN      
  IF (:OLD.DESCRICAO <> :NEW.DESCRICAO) THEN
    GERAR_LOG('DESCRICAO','PCPRODUT',:NEW.DESCRICAO,:OLD.DESCRICAO,'REG0205',:OLD.CODPROD);
  END IF;
      
  EXCEPTION WHEN OTHERS THEN
    GERAR_LOG('NENHUM', '', 'ERRO AO GERAR LOG', 'ERRO AO GERAR LOG', '', '0' || SQLERRM);
END;