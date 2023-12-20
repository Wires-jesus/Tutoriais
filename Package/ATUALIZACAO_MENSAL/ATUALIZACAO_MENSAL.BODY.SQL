CREATE OR REPLACE PACKAGE BODY ATUALIZACAO_MENSAL IS
  
  TYPE T_CODFILIAL_ARRAY IS TABLE OF PCFILIAL.CODIGO%TYPE INDEX BY BINARY_INTEGER;
  TYPE T_CODCLI_ARRAY IS TABLE OF PCCLIENT.CODCLI%TYPE INDEX BY BINARY_INTEGER;
  TYPE T_CODIGO_ARRAY IS TABLE OF INTEGER INDEX BY BINARY_INTEGER;
  TYPE T_VLVENDA_ARRAY IS TABLE OF PCNFSAID.VLTOTAL%TYPE INDEX BY BINARY_INTEGER;
  TYPE T_VLDEVOLUCAO_ARRAY IS TABLE OF PCNFSAID.VLTOTAL%TYPE INDEX BY BINARY_INTEGER;
  TYPE T_VLCUSTOFIN_ARRAY IS TABLE OF PCMOV.CUSTOFIN%TYPE INDEX BY BINARY_INTEGER;
  TYPE T_VLCUSTOREAL_ARRAY IS TABLE OF PCMOV.CUSTOREAL%TYPE INDEX BY BINARY_INTEGER;
  TYPE T_QT_ARRAY IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE T_QTDEVOLUCAO_ARRAY IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE T_QTMIX_ARRAY IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

  PROCEDURE P_PC_ZERAMESPCAUXCLI(PMES      IN VARCHAR2,
                                 PANO      IN VARCHAR2,
                                 PMENSAGEM OUT VARCHAR2) IS
    VSQL VARCHAR2(2000) := '';
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado para zerar os valores do mês para recálculo;
    ------------------------------------------------------------------------------
  BEGIN
    BEGIN
      VSQL := 'UPDATE PCAUXCLI SET VLVENDAMES' || PMES || '          = 0, ' ||
              ' VLCUSTOFINMES' || PMES || '  = 0, ' || ' VLCUSTOREALMES' || PMES ||
              ' = 0, ' || ' QTVENDAMES' || PMES || '     = 0, ' ||
              ' QTMIXMES' || PMES || '       = 0  ' || ' WHERE ANO = :pAno';

      EXECUTE IMMEDIATE VSQL
        USING PANO;

    EXCEPTION
      WHEN OTHERS THEN
        PMENSAGEM := 'Erro ao zerar lançamentos do mês ' || PMES ||
                     ' do ano ' || PANO || ' na PCAUXCLI' || SQLERRM;
    END;

  END; -- Fim procedure P_PC_ZERAMESPCAUXCLI

  PROCEDURE P_PC_ZERAMESPCAUXPRO(PMES      IN VARCHAR2,
                                 PANO      IN VARCHAR2,
                                 PMENSAGEM OUT VARCHAR2) IS
    VSQL VARCHAR2(2000) := '';
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado para zerar os valores do mês da tabela PCAUXPRO ;
    ------------------------------------------------------------------------------
  BEGIN
    BEGIN

      VSQL := 'UPDATE PCAUXPRO SET VLVENDAMES' || PMES || '          = 0, ' ||
              ' VLCUSTOFINMES' || PMES || '  = 0, ' || ' VLCUSTOREALMES' || PMES ||
              ' = 0, ' || ' QTVENDAMES' || PMES || '     = 0, ' ||
              ' QTDEVCLI' || PMES || '       = 0, ' || ' VLDEVCLI' || PMES ||
              '       = 0  ' || ' WHERE ANO = :pAno';

      EXECUTE IMMEDIATE VSQL
        USING PANO;

    EXCEPTION
      WHEN OTHERS THEN
        PMENSAGEM := 'Erro ao zerar lançamentos do mês ' || PMES ||
                     ' do ano ' || PANO || ' na PCAUXCLI' || SQLERRM;
    END;

  END; -- Fim procedure P_PC_ZERAMESPCAUXPRO

  PROCEDURE P_PC_ATUALIZAPCAUXCLI(PCODCLI         IN INTEGER,
                                  PANO            IN VARCHAR2,
                                  PMES            IN VARCHAR2,
                                  PVLVENDAMES     IN FLOAT,
                                  PVLCUSTOFINMES  IN FLOAT,
                                  PVLCUSTOREALMES IN FLOAT,
                                  PQTVENDAMES     IN FLOAT,
                                  PQTMIXMES       IN FLOAT,
                                  PMENSAGEM       OUT VARCHAR2) IS
    VSQL VARCHAR2(2000);
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado atualizar os dados da tabela PCAUXCLI
    ------------------------------------------------------------------------------
    CONTADOR INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO CONTADOR
      FROM PCAUXCLI
     WHERE CODCLI = PCODCLI
       AND PCAUXCLI.ANO = PANO;
    BEGIN
      IF CONTADOR = 0 THEN
        VSQL := ' INSERT INTO PCAUXCLI (ANO,' || ' CODCLI,' ||
                ' VLVENDAMES' || PMES || ',' || ' VLCUSTOFINMES' || PMES || ',' ||
                ' VLCUSTOREALMES' || PMES || ',' || ' QTVENDAMES' || PMES || ',' ||
                ' QTMIXMES' || PMES || ')' || ' VALUES ' || '(' || PANO || ',' ||
                PCODCLI || ',' || REPLACE(NVL(PVLVENDAMES,0), ',', '.') || ',' || REPLACE(NVL(PVLCUSTOFINMES,0), ',', '.') || ',' ||
                REPLACE(NVL(PVLCUSTOREALMES,0), ',', '.') || ',' || REPLACE(NVL(PQTVENDAMES,0), ',', '.') || ',' || REPLACE(NVL(PQTMIXMES,0), ',', '.') || ')';
        EXECUTE IMMEDIATE VSQL;
      ELSE
        VSQL := 'UPDATE PCAUXCLI SET VLVENDAMES' || PMES || '       = ' ||
                REPLACE(NVL(PVLVENDAMES,0), ',', '.') || ', VLCUSTOFINMES' || PMES || '    = ' ||
                REPLACE(NVL(PVLCUSTOFINMES,0), ',', '.') || ', VLCUSTOREALMES' || PMES || '   = ' ||
                REPLACE(NVL(PVLCUSTOREALMES,0), ',', '.') || ', QTVENDAMES' || PMES || '       = ' ||
                REPLACE(NVL(PQTVENDAMES,0), ',', '.') || ', QTMIXMES' || PMES || '         = ' ||
                REPLACE(NVL(PQTMIXMES,0), ',', '.') || ' WHERE ANO = :MANO AND CODCLI = :MCODCLI';
        EXECUTE IMMEDIATE VSQL
          USING PANO, PCODCLI;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN        
        PMENSAGEM := PMENSAGEM || CHR(13) ||
                     'Erro ao zerar lançamentos do mês ' || PMES ||
                     ' do ano ' || PANO || ' na PCAUXCLI' || SQLERRM;
    END;
  END;
  
  PROCEDURE P_PC_ATUALIZAPCAUXCLI_NOTAS(PCODCLI         IN T_CODCLI_ARRAY,
                                        PANO            IN VARCHAR2,
                                        PMES            IN VARCHAR2,
                                        PVLVENDAMES     IN T_VLVENDA_ARRAY,
                                        PVLCUSTOFINMES  IN T_VLCUSTOFIN_ARRAY,
                                        PVLCUSTOREALMES IN T_VLCUSTOREAL_ARRAY,
                                        PQTVENDAMES     IN T_QT_ARRAY,
                                        PQTMIXMES       IN T_QTMIX_ARRAY,
                                        PMENSAGEM       OUT VARCHAR2) IS
    VSQL VARCHAR2(2000);
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado atualizar os dados da tabela PCAUXCLI
    ------------------------------------------------------------------------------
    CONTADOR INTEGER;
  BEGIN
    /* Verifica se ja existe o registro para o cliente no ano em processamento */
    FOR IDX IN PCODCLI.FIRST .. PCODCLI.LAST  
    LOOP
      SELECT COUNT(*)
        INTO CONTADOR
        FROM PCAUXCLI
       WHERE CODCLI = PCODCLI(IDX)
         AND PCAUXCLI.ANO = PANO;
      
      IF CONTADOR = 0 THEN
        VSQL := ' INSERT INTO PCAUXCLI (ANO, CODCLI)' || 
                ' VALUES ' || '(' || PANO || ',' || ':CODCLI' || ')';
        EXECUTE IMMEDIATE VSQL
          USING PCODCLI(IDX);          
      END IF;
    END LOOP;   
    COMMIT;
    
    BEGIN
      VSQL := 'UPDATE PCAUXCLI SET ' || CHR(13) ||
                 'VLVENDAMES' || PMES || '       = DECODE(NVL(:VLVENDAMES' || PMES || ',0), 0, ' || 'VLVENDAMES' || PMES || ' , NVL(:VLVENDAMES' || PMES || ',0)) ' || CHR(13) ||
                 ',VLCUSTOFINMES' || PMES || '       = DECODE(NVL(:VLCUSTOFINMES' || PMES || ',0), 0, ' || 'VLCUSTOFINMES' || PMES || ' , NVL(:VLCUSTOFINMES' || PMES || ',0)) ' || CHR(13) ||
                 ',VLCUSTOREALMES' || PMES || '       = DECODE(NVL(:VLCUSTOREALMES' || PMES || ',0), 0, ' || 'VLCUSTOREALMES' || PMES || ' , NVL(:VLCUSTOREALMES' || PMES || ',0)) ' || CHR(13) ||
                 ',QTVENDAMES' || PMES || '       = DECODE(NVL(:QTVENDAMES' || PMES || ',0), 0, ' || 'QTVENDAMES' || PMES || ' , NVL(:QTVENDAMES' || PMES || ',0)) ' || CHR(13) ||
                 ',QTMIXMES' || PMES || '       = DECODE(NVL(:QTMIXMES' || PMES || ',0), 0, ' || 'QTMIXMES' || PMES || ' , NVL(:QTMIXMES' || PMES || ',0)) ' || CHR(13) ||
                 ' WHERE ANO = :MANO AND CODCLI = :MCODCLI';
                            
      FORALL IDX IN PCODCLI.FIRST .. PCODCLI.LAST
        EXECUTE IMMEDIATE VSQL
          USING PVLVENDAMES(IDX), 
                PVLVENDAMES(IDX),
                PVLCUSTOFINMES(IDX),
                PVLCUSTOFINMES(IDX),
                PVLCUSTOREALMES(IDX),
                PVLCUSTOREALMES(IDX),
                PQTVENDAMES(IDX),
                PQTVENDAMES(IDX),
                PQTMIXMES(IDX),     
                PQTMIXMES(IDX),
                PANO, 
                PCODCLI(IDX);      
                
      COMMIT WORK;          
    EXCEPTION
      WHEN OTHERS THEN        
        PMENSAGEM := PMENSAGEM || CHR(13) ||
                     'Erro ao zerar lançamentos do mês ' || PMES ||
                     ' do ano ' || PANO || ' na PCAUXCLI => ' || SQLERRM;
    END;
  END; 
  
  PROCEDURE P_PC_ATUALIZAPCAUXPRO(PCodProd    in Float,
                                  pAno         in Varchar2,
                                  pMes         in Varchar2,
                                  PCodFilial   in Varchar2,
                                  pVlvenda     in Float,
                                  pVlcustofin  in Float,
                                  pVlcustoreal in Float,
                                  pQtvenda     in Float,
                                  pVldevolucao in Float,
                                  pQtdevolucao in Float,
                                  pVlcompra    in Float,
                                  pQtcompra    in Float,
                                  pVlestoque   in Float,
                                  pCustoFin    in Float,
                                  pCustoReal   in Float,
                                  pCustocont   in Float,
                                  pQtestger    in Float,
                                  pVenda1      in Float) IS
    CONTADOR INTEGER;
    VSQL     VARCHAR2(2000);
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado atualizar os dados da tabela PCAUXPRO
    ------------------------------------------------------------------------------
  BEGIN
    SELECT COUNT(*)
      INTO CONTADOR
      FROM PCAUXPRO
     WHERE ANO = PANO
       AND CODFILIAL = ''|| PCodFilial || ''
       AND CODPROD = PCodProd;

    IF CONTADOR = 0 THEN
      VSQL := ' INSERT INTO PCAUXPRO (ANO,' || ' CODFILIAL,' || ' CODPROD,' ||
              ' VLVENDAMES' || PMES || ',' || ' VLDEVCLI' || PMES || ',' ||
              ' QTDEVCLI' || PMES || ',' || ' VLCUSTOFINMES' || PMES || ',' ||
              ' VLCUSTOREALMES' || PMES || ',' || ' VLCOMPRAMES' || PMES || ',' ||
              ' QTCOMPRAMES' || PMES || ',' || ' VLESTOQUEMES' || PMES || ',' ||
              ' CUSTOFINMES' || PMES || ',' || ' CUSTOREALMES' || PMES || ',' ||
              ' CUSTOCONTMES' || PMES || ',' || ' QTESTGERMES' || PMES || ',' ||
              ' PVENDAMES' || PMES || ',' || ' QTVENDAMES' || PMES || ')' ||
              ' VALUES ' || '(' || PANO || ',''' ||
              PCODFILIAL || ''',' || PCODPROD || ',' || REPLACE(NVL(PVLVENDA, 0), ',', '.') || ',' ||
              REPLACE(NVL(PVLDEVOLUCAO, 0), ',', '.') || ',' || REPLACE(NVL(PQTDEVOLUCAO, 0), ',', '.') || ',' || REPLACE(NVL(PVLCUSTOFIN, 0), ',', '.') || ',' ||
              REPLACE(NVL(PVLCUSTOREAL, 0), ',', '.') || ',' || REPLACE(NVL(PVLCOMPRA, 0), ',', '.') || ',' || REPLACE(NVL(PQTCOMPRA, 0), ',', '.') || ',' ||
              REPLACE(NVL(PVLESTOQUE, 0), ',', '.') || ',' || REPLACE(NVL(PCUSTOFIN, 0), ',', '.') || ',' || REPLACE(NVL(PCUSTOREAL, 0), ',', '.') || ',' ||
              REPLACE(NVL(PCUSTOCONT, 0), ',', '.') || ',' || REPLACE(NVL(PQTESTGER, 0), ',', '.') || ',' || REPLACE(NVL(PVENDA1, 0), ',', '.') || ',' ||
              REPLACE(NVL(PQTVENDA, 0), ',', '.') || ')';
      EXECUTE IMMEDIATE VSQL;
    ELSE
      VSQL := 'UPDATE PCAUXPRO SET ' || CHR(13);
      VSQL := VSQL || ' VLVENDAMES' || PMES || ' = DECODE(NVL(:VLVENDAMES, 0), 0, VLVENDAMES' || PMES || ', NVL(:VLVENDAMES, 0)) ' || CHR(13);
      VSQL := VSQL || ', VLDEVCLI' || PMES || ' = DECODE(NVL(:VLDEVCLI, 0), 0, VLDEVCLI' || PMES || ', NVL(:VLDEVCLI, 0)) ' || CHR(13);    
      VSQL := VSQL || ', QTDEVCLI' || PMES || ' = DECODE(NVL(:QTDEVCLI, 0), 0, QTDEVCLI' || PMES || ', NVL(:QTDEVCLI, 0)) ' || CHR(13);    
      VSQL := VSQL || ', VLCUSTOFINMES' || PMES || ' = DECODE(NVL(:VLCUSTOFINMES, 0), 0, VLCUSTOFINMES' || PMES || ', NVL(:VLCUSTOFINMES, 0)) ' || CHR(13);        
      VSQL := VSQL || ', VLCUSTOREALMES' || PMES || ' = DECODE(NVL(:VLCUSTOREALMES, 0), 0, VLCUSTOREALMES' || PMES || ', NVL(:VLCUSTOREALMES, 0)) ' || CHR(13);    
      VSQL := VSQL || ', QTVENDAMES' || PMES || ' = DECODE(NVL(:QTVENDAMES, 0), 0, QTVENDAMES' || PMES || ', NVL(:QTVENDAMES, 0)) ' || CHR(13);        
      VSQL := VSQL || ', QTCOMPRAMES' || PMES || ' = DECODE(NVL(:QTCOMPRAMES, 0), 0, QTCOMPRAMES' || PMES || ', NVL(:QTCOMPRAMES, 0)) ' || CHR(13);            
      VSQL := VSQL || ', VLCOMPRAMES' || PMES || ' = DECODE(NVL(:VLCOMPRAMES, 0), 0, VLCOMPRAMES' || PMES || ', NVL(:VLCOMPRAMES, 0)) ' || CHR(13);            
      VSQL := VSQL || ', VLESTOQUEMES' || PMES || ' = DECODE(NVL(:VLESTOQUEMES, 0), 0, VLESTOQUEMES' || PMES || ', NVL(:VLESTOQUEMES, 0)) ' || CHR(13);            
      VSQL := VSQL || ', CUSTOFINMES' || PMES || ' = DECODE(NVL(:CUSTOFINMES, 0), 0, CUSTOFINMES' || PMES || ', NVL(:CUSTOFINMES, 0)) ' || CHR(13);
      VSQL := VSQL || ', CUSTOREALMES' || PMES || ' = DECODE(NVL(:CUSTOREALMES, 0), 0, CUSTOREALMES' || PMES || ', NVL(:CUSTOREALMES, 0)) ' || CHR(13);
      VSQL := VSQL || ', CUSTOCONTMES' || PMES || ' = DECODE(NVL(:CUSTOCONTMES, 0), 0, CUSTOCONTMES' || PMES || ', NVL(:CUSTOCONTMES, 0)) ' || CHR(13);
      VSQL := VSQL || ', QTESTGERMES' || PMES || ' = DECODE(NVL(:QTESTGERMES, 0), 0, QTESTGERMES' || PMES || ', NVL(:QTESTGERMES, 0)) ' || CHR(13);
      VSQL := VSQL || ', PVENDAMES' || PMES || ' = DECODE(NVL(:PVENDAMES, 0), 0, PVENDAMES' || PMES || ', NVL(:PVENDAMES, 0)) ' || CHR(13);
      VSQL := VSQL || ' WHERE ANO = :MANO' ||
                       '  AND CODFILIAL = :MCODFILIAL' ||
                       '  AND CODPROD   = :MCODPROD';
      EXECUTE IMMEDIATE VSQL
        USING PVLVENDA,
              PVLVENDA,
              PVLDEVOLUCAO,
              PVLDEVOLUCAO,
              PQTDEVOLUCAO,
              PQTDEVOLUCAO,
              PVLCUSTOFIN,
              PVLCUSTOFIN,
              PVLCUSTOREAL,
              PVLCUSTOREAL,
              PQTVENDA,
              PQTVENDA,
              PQTCOMPRA,
              PQTCOMPRA,
              PVLCOMPRA,
              PVLCOMPRA,
              PVLESTOQUE,
              PVLESTOQUE,
              PCUSTOFIN,
              PCUSTOFIN,
              PCUSTOREAL,
              PCUSTOREAL,
              PCUSTOCONT,
              PCUSTOCONT,
              PQTESTGER,
              PQTESTGER,
              PVENDA1,
              PVENDA1,              
              PANO, 
              PCODFILIAL, 
              PCODPROD;    
    END IF;

  END; -- fim da procedure P_PC_ATUALIZAPCAUXPRO

  PROCEDURE P_PC_ATUALIZAPCAUXPRO_N(PCODPROD     IN T_CODIGO_ARRAY,
                                    PANO         IN VARCHAR2,
                                    PMES         IN VARCHAR2,
                                    PCODFILIAL   IN T_CODFILIAL_ARRAY,
                                    PVLVENDA     IN T_VLVENDA_ARRAY,
                                    PVLCUSTOFIN  IN T_VLCUSTOFIN_ARRAY,
                                    PVLCUSTOREAL IN T_VLCUSTOREAL_ARRAY,
                                    PQTVENDA     IN T_QT_ARRAY,
                                    PVLDEVOLUCAO IN T_VLDEVOLUCAO_ARRAY,
                                    PQTDEVOLUCAO IN T_QTDEVOLUCAO_ARRAY,
                                    PVLCOMPRA    IN T_VLVENDA_ARRAY,
                                    PQTCOMPRA    IN T_QT_ARRAY,
                                    PVLESTOQUE   IN FLOAT,
                                    PCUSTOFIN    IN FLOAT,
                                    PCUSTOREAL   IN FLOAT,
                                    PCUSTOCONT   IN FLOAT,
                                    PQTESTGER    IN FLOAT,
                                    PVENDA1      IN FLOAT) IS
    CONTADOR INTEGER;
    VSQL     VARCHAR2(2000);
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado atualizar os dados da tabela PCAUXPRO
    ------------------------------------------------------------------------------
  BEGIN
    FOR IDX IN PCODPROD.FIRST .. PCODPROD.LAST
    LOOP
      SELECT COUNT(*)
        INTO CONTADOR
        FROM PCAUXPRO
       WHERE ANO = PANO
         AND CODFILIAL = ''|| PCODFILIAL(IDX) || ''
         AND CODPROD = PCODPROD(IDX);

      IF CONTADOR = 0 THEN
        VSQL := ' INSERT INTO PCAUXPRO (ANO,' || ' CODFILIAL,' || ' CODPROD)' ||
                ' VALUES ' || '(' || PANO || ',' ||
                ':CODFILIAL' || ',' || ' :CODPROD'  || ')';
        EXECUTE IMMEDIATE VSQL
          USING PCODFILIAL(IDX),
                PCODPROD(IDX);        
      END IF;      
    END LOOP;
    COMMIT;
    
    VSQL := 'UPDATE PCAUXPRO SET ' || CHR(13);
    VSQL := VSQL || ' VLVENDAMES' || PMES || ' = DECODE(NVL(:VLVENDAMES, 0), 0, VLVENDAMES' || PMES || ', NVL(:VLVENDAMES, 0)) ' || CHR(13);
    VSQL := VSQL || ', VLDEVCLI' || PMES || ' = DECODE(NVL(:VLDEVCLI, 0), 0, VLDEVCLI' || PMES || ', NVL(:VLDEVCLI, 0)) ' || CHR(13);    
    VSQL := VSQL || ', QTDEVCLI' || PMES || ' = DECODE(NVL(:QTDEVCLI, 0), 0, QTDEVCLI' || PMES || ', NVL(:QTDEVCLI, 0)) ' || CHR(13);    
    VSQL := VSQL || ', VLCUSTOFINMES' || PMES || ' = DECODE(NVL(:VLCUSTOFINMES, 0), 0, VLCUSTOFINMES' || PMES || ', NVL(:VLCUSTOFINMES, 0)) ' || CHR(13);        
    VSQL := VSQL || ', VLCUSTOREALMES' || PMES || ' = DECODE(NVL(:VLCUSTOREALMES, 0), 0, VLCUSTOREALMES' || PMES || ', NVL(:VLCUSTOREALMES, 0)) ' || CHR(13);    
    VSQL := VSQL || ', QTVENDAMES' || PMES || ' = DECODE(NVL(:QTVENDAMES, 0), 0, QTVENDAMES' || PMES || ', NVL(:QTVENDAMES, 0)) ' || CHR(13);        
    VSQL := VSQL || ', QTCOMPRAMES' || PMES || ' = DECODE(NVL(:QTCOMPRAMES, 0), 0, QTCOMPRAMES' || PMES || ', NVL(:QTCOMPRAMES, 0)) ' || CHR(13);            
    VSQL := VSQL || ', VLCOMPRAMES' || PMES || ' = DECODE(NVL(:VLCOMPRAMES, 0), 0, VLCOMPRAMES' || PMES || ', NVL(:VLCOMPRAMES, 0)) ' || CHR(13);            
    VSQL := VSQL || ', VLESTOQUEMES' || PMES || ' = DECODE(NVL(:VLESTOQUEMES, 0), 0, VLESTOQUEMES' || PMES || ', NVL(:VLESTOQUEMES, 0)) ' || CHR(13);            
    VSQL := VSQL || ', CUSTOFINMES' || PMES || ' = DECODE(NVL(:CUSTOFINMES, 0), 0, CUSTOFINMES' || PMES || ', NVL(:CUSTOFINMES, 0)) ' || CHR(13);
    VSQL := VSQL || ', CUSTOREALMES' || PMES || ' = DECODE(NVL(:CUSTOREALMES, 0), 0, CUSTOREALMES' || PMES || ', NVL(:CUSTOREALMES, 0)) ' || CHR(13);
    VSQL := VSQL || ', CUSTOCONTMES' || PMES || ' = DECODE(NVL(:CUSTOCONTMES, 0), 0, CUSTOCONTMES' || PMES || ', NVL(:CUSTOCONTMES, 0)) ' || CHR(13);
    VSQL := VSQL || ', QTESTGERMES' || PMES || ' = DECODE(NVL(:QTESTGERMES, 0), 0, QTESTGERMES' || PMES || ', NVL(:QTESTGERMES, 0)) ' || CHR(13);
    VSQL := VSQL || ', PVENDAMES' || PMES || ' = DECODE(NVL(:PVENDAMES, 0), 0, PVENDAMES' || PMES || ', NVL(:PVENDAMES, 0)) ' || CHR(13);
    VSQL := VSQL || ' WHERE ANO = :MANO' ||
              '  AND CODFILIAL = :MCODFILIAL' ||
              '  AND CODPROD   = :MCODPROD';
              
    FORALL IDX IN PCODPROD.FIRST .. PCODPROD.LAST          
      EXECUTE IMMEDIATE VSQL
        USING PVLVENDA(IDX),
              PVLVENDA(IDX),
              PVLDEVOLUCAO(IDX),
              PVLDEVOLUCAO(IDX),
              PQTDEVOLUCAO(IDX),
              PQTDEVOLUCAO(IDX),
              PVLCUSTOFIN(IDX),
              PVLCUSTOFIN(IDX),
              PVLCUSTOREAL(IDX),
              PVLCUSTOREAL(IDX),
              PQTVENDA(IDX),
              PQTVENDA(IDX),
              PQTCOMPRA(IDX),
              PQTCOMPRA(IDX),
              PVLCOMPRA(IDX),
              PVLCOMPRA(IDX),
              PVLESTOQUE,
              PVLESTOQUE,
              PCUSTOFIN,
              PCUSTOFIN,
              PCUSTOREAL,
              PCUSTOREAL,
              PCUSTOCONT,
              PCUSTOCONT,
              PQTESTGER,
              PQTESTGER,
              PVENDA1,
              PVENDA1,
              
              PANO, 
              PCODFILIAL(IDX), 
              PCODPROD(IDX);    
    COMMIT WORK;
  END; -- fim da procedure P_PC_ATUALIZAPCAUXPRO_N

  PROCEDURE P_PC_ATUALIZAPCCONSOLIDAMES(pCodigo    in Integer,
                                        pAno       in Varchar2,
                                        pMes       in Varchar2,
                                        pVlvenda   in Float,
                                        pVlcompra  in Float,
                                        pQtvenda   in Float,
                                        pCodfilial in Varchar2,
                                        pTipo      in Varchar2) IS
    CONTADOR INTEGER;
    VSQL     VARCHAR2(2000);
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado atualizar os dados da tabela PCCONSOLIDAMES
    ------------------------------------------------------------------------------
  BEGIN
    BEGIN
      SELECT COUNT(*)
        INTO CONTADOR
        FROM PCCONSOLIDAMES P
       WHERE P.TIPO = ''|| TRIM(pTipo) || ''
         AND P.CODIGO = PCODIGO
         AND P.CODFILIAL = ''|| TRIM(PCODFILIAL) || ''
         AND P.MES = TRIM(PMES)
         AND P.ANO = TRIM(PANO);
    EXCEPTION
       WHEN OTHERS THEN
         CONTADOR := -1;
    END;

    IF CONTADOR = 0 THEN
      VSQL := ' INSERT INTO PCCONSOLIDAMES (TIPO, CODIGO, CODFILIAL, MES, ANO, QTVENDA, VLVENDA, VLCOMPRA)
                VALUES (''' || PTIPO || ''',' ||
                             PCODIGO || ',''' || PCODFILIAL || ''',' || PMES || ',' || PANO || ',' ||
                             REPLACE(NVL(PQTVENDA,0), ',', '.') || ',' || REPLACE(NVL(PVLVENDA,0), ',', '.') || ',' || REPLACE(NVL(PVLCOMPRA,0), ',', '.') || ')';
      BEGIN
        EXECUTE IMMEDIATE VSQL;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001, 'INSERT');
      END;
    ELSE
      VSQL := 'UPDATE PCCONSOLIDAMES SET TIPO     = ''' || PTIPO||'''';
      IF NVL(PQTVENDA,0) > 0 THEN
        VSQL := VSQL || ' , QTVENDA  = ' || REPLACE(NVL(PQTVENDA,0), ',', '.');
      END IF;
      IF NVL(PVLVENDA,0) > 0 THEN
        VSQL := VSQL || ' , VLVENDA  = ' || REPLACE(NVL(PVLVENDA,0), ',', '.');
      END IF;
      IF NVL(PVLCOMPRA,0) > 0 THEN
        VSQL := VSQL || ' , VLCOMPRA = ' || REPLACE(NVL(PVLCOMPRA,0), ',', '.');
      END IF;
      VSQL := VSQL || '  WHERE ANO = :MANO' || '  AND CODIGO = :MCODCLI' ||
              '  AND MES = :MMES' || '  AND TIPO = :MTIPO' ||
              '  AND CODFILIAL = :MCODFILIAL';
      BEGIN
        EXECUTE IMMEDIATE VSQL USING PANO, PCODIGO, PMES, PTIPO, PCODFILIAL;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001, 'UPDATE '||sqlerrm);
      END;

    END IF;
  END;
  
  PROCEDURE P_PC_ATUALIZAPCCONSOLIDAMES_N(PCODIGO    in T_CODIGO_ARRAY,
                                          PANO       in Varchar2,
                                          PMES       in Varchar2,
                                          PVLVENDA   in T_VLVENDA_ARRAY,
                                          PVLCOMPRA  in T_VLVENDA_ARRAY,
                                          PQTVENDA   in T_QT_ARRAY,
                                          PCODFILIAL in T_CODFILIAL_ARRAY,
                                          PTIPO      in Varchar2) IS
    CONTADOR INTEGER;
    VSQL     VARCHAR2(2000);
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011
    -- Purpose : Criado atualizar os dados da tabela PCCONSOLIDAMES
    ------------------------------------------------------------------------------
  BEGIN
    FOR IDX IN PCODIGO.FIRST .. PCODIGO.LAST
    LOOP  
      SELECT COUNT(*)
       INTO CONTADOR
       FROM PCCONSOLIDAMES P
      WHERE P.TIPO = ''|| TRIM(PTIPO) || ''
        AND P.CODIGO = PCODIGO(IDX)
        AND P.CODFILIAL = ''|| TRIM(PCODFILIAL(IDX)) || ''
        AND P.MES = TRIM(PMES)
        AND P.ANO = TRIM(PANO); 
           
      IF CONTADOR = 0 THEN
        VSQL := ' INSERT INTO PCCONSOLIDAMES (TIPO, CODIGO, CODFILIAL, MES, ANO)
                  VALUES (''' || PTIPO || ''',' ||
                               ':CODIGO' || ',' || ':CODFILIAL' || ',' || PMES || ',' || PANO || ')';
        BEGIN
          EXECUTE IMMEDIATE VSQL 
            USING PCODIGO(IDX), 
                  PCODFILIAL(IDX);          
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'INSERT PCCONSOLIDAMES ' ||SQLERRM);              
        END;
      END IF;               
    END LOOP;  
    COMMIT;    

    VSQL := 'UPDATE PCCONSOLIDAMES SET TIPO     = ''' || PTIPO||'''' || CHR(13);
    VSQL := VSQL || ' , QTVENDA  =  DECODE(NVL(:QTVENDA,0), 0, NVL(QTVENDA,0), NVL(:QTVENDA,0))  ' || CHR(13);
    VSQL := VSQL || ' , VLVENDA  =  DECODE(NVL(:VLVENDA,0), 0, NVL(VLVENDA,0), NVL(:VLVENDA,0)) ' || CHR(13);
    VSQL := VSQL || ' , VLCOMPRA  =  DECODE(NVL(:VLCOMPRA,0), 0, NVL(VLCOMPRA,0), NVL(:VLCOMPRA,0)) ' || CHR(13);
    VSQL := VSQL || '  WHERE ANO = :MANO' || '  AND CODIGO = :MCODCLI' ||
            '  AND MES = :MMES' || '  AND TIPO = :MTIPO' ||
            '  AND CODFILIAL = :MCODFILIAL';
    BEGIN
      FORALL IDX IN PCODIGO.FIRST .. PCODIGO.LAST 
        /* Passagem de parametros conforme a quantidade de parametros do SQL Dinamico. */    
        EXECUTE IMMEDIATE VSQL USING PQTVENDA(IDX), 
                                     PQTVENDA(IDX),
                                     PVLVENDA(IDX), 
                                     PVLVENDA(IDX),
                                     PVLCOMPRA(IDX),
                                     PVLCOMPRA(IDX),   
                                     PANO, 
                                     PCODIGO(IDX), 
                                     PMES, 
                                     PTIPO, 
                                     PCODFILIAL(IDX);
      COMMIT WORK;                               
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'UPDATE PCCONSOLIDAMES '||sqlerrm);
    END;
  END;

  PROCEDURE P_PC_CONSOLIDADADOSHISTORICO(pdataini  in date,
                                         pdatafim  in date,
                                         pMensagem out VARCHAR2,
                                         pCommit   in Varchar2 Default 'N') IS
    CURSOR C_NOTAS(PDATAINI DATE,
                   PDATAFIM DATE) IS
      SELECT CODFILIAL
             ,CODPROD
             ,SUM(VLVENDA) VLVENDA
             ,SUM(QT) QT
             ,SUM(VLDEVOLUCAO) VLDEVOLUCAO
             ,SUM(QTDEVOLUCAO) QTDEVOLUCAO
             ,SUM(VLCUSTOFIN) VLCUSTOFIN
             ,SUM(VLCUSTOREAL) VLCUSTOREAL
             ,0 VLCOMPRA
             ,0 QTCOMPRA
         FROM (SELECT N.CODFILIAL
                      ,M.CODPROD
                      -- VLVENDA
                      ,SUM(ROUND(NVL(NVL((CASE
                                           WHEN ROUND(CP.VLSUBTOTITEM, 2) IS NOT NULL THEN
                                             (CASE
                                                WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                                                  (DECODE(M.CODOPER,
                                                          'S',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                           0)),
                                                          'ST',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                           0)),
                                                          'SM',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                           0)),
                                                          0) - (ROUND(NVL(M.VLFRETE, 0), 2) * M.QT))
                                                WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIROUTRASDESP' THEN
                                                  (DECODE(M.CODOPER,
                                                          'S',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                               0)),
                                                          'ST',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                               0)),
                                                          'SM',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                               0)),
                                                          0) - (ROUND(NVL(M.VLOUTRASDESP, 0), 2) * M.QT))
                                                WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                                                  (DECODE(M.CODOPER,
                                                          'S',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                               0)),
                                                          'ST',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                               0)),
                                                          'SM',
                                                          (NVL(DECODE(N.CONDVENDA,
                                                                      5,
                                                                      0,
                                                                      6,
                                                                      0,
                                                                      11,
                                                                      0,
                                                                      12,
                                                                      0,
                                                                      DECODE(M.CODOPER,
                                                                             'SB',
                                                                             0,
                                                                             ROUND(CP.VLSUBTOTITEM, 2))),
                                                               0)),
                                                          0) - (ROUND(NVL(M.VLFRETE, 0), 2) * M.QT) -
                                                          (ROUND(NVL(M.VLOUTRASDESP, 0), 2) * M.QT))
                                                ELSE
                                                  ROUND(CP.VLSUBTOTITEM, 2)
                                              END)
                                           ELSE
                                             NULL
                                         END),
                                        (ROUND((DECODE(M.CODOPER,
                                                       'S',
                                                       (NVL(DECODE(N.CONDVENDA,
                                                                   5,
                                                                   0,
                                                                   6,
                                                                   0,
                                                                   11,
                                                                   0,
                                                                   12,
                                                                   0,
                                                                   DECODE(M.CODOPER,
                                                                          'SB',
                                                                          0,
                                                                          DECODE(M.TIPOITEM,
                                                                                 'N',
                                                                                 M.QTCONT,
                                                                                 M.QT))),
                                                            0)),
                                                       'ST',
                                                       (NVL(DECODE(N.CONDVENDA,
                                                                   5,
                                                                   0,
                                                                   6,
                                                                   0,
                                                                   11,
                                                                   0,
                                                                   12,
                                                                   0,
                                                                   DECODE(M.CODOPER,
                                                                          'SB',
                                                                          0,
                                                                          DECODE(M.TIPOITEM,
                                                                                 'N',
                                                                                 M.QTCONT,
                                                                                 M.QT))),
                                                            0)),
                                                       'SM',
                                                       (NVL(DECODE(N.CONDVENDA,
                                                                   5,
                                                                   0,
                                                                   6,
                                                                   0,
                                                                   11,
                                                                   0,
                                                                   12,
                                                                   0,
                                                                   DECODE(M.CODOPER,
                                                                          'SB',
                                                                          0,
                                                                          DECODE(M.TIPOITEM,
                                                                          'N',
                                                                          M.QTCONT,
                                                                          M.QT))),
                                                            0)),
                                                       0)) *
                                                      ((CASE
                                                          WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                                                            (NVL(DECODE(N.CONDVENDA,
                                                                        7,
                                                                        DECODE(M.TIPOITEM,
                                                                               'N',
                                                                               NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                          'S',
                                                                                          M.PUNIT,
                                                                                          M.PUNITCONT),
                                                                                   0),
                                                                               M.PUNIT) + NVL(M.VLOUTRASDESP, 0) +
                                                                          NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                                          DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                 'S',
                                                                                 NVL(M.VLREPASSE, 0),
                                                                                 0),
                                                                        NVL(DECODE(M.TIPOITEM,
                                                                                   'N',
                                                                                   NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                              'S',
                                                                                              M.PUNIT,
                                                                                              M.PUNITCONT),
                                                                                       0),
                                                                                   M.PUNIT),
                                                                            0) + NVL(M.VLOUTRASDESP, 0) +
                                                                          NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                                          DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                     'S',
                                                                                     NVL(M.VLREPASSE, 0),
                                                                                     0)),
                                                                 0))
                                                          WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIROUTRASDESP' THEN
                                                            (NVL(DECODE(N.CONDVENDA,
                                                                        7,
                                                                        DECODE(M.TIPOITEM,
                                                                               'N',
                                                                               NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                          'S',
                                                                                          M.PUNIT,
                                                                                          M.PUNITCONT),
                                                                                   0),
                                                                               M.PUNIT) + NVL(M.VLFRETE, 0) +
                                                                          NVL(M.VLFRETE_RATEIO, 0) +
                                                                          NVL(M.VLOUTRASDESP, 0),
                                                                        NVL(DECODE(M.TIPOITEM,
                                                                                   'N',
                                                                                   NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                              'S',
                                                                                              M.PUNIT,
                                                                                              M.PUNITCONT),
                                                                                       0),
                                                                                   M.PUNIT),
                                                                            0) + NVL(M.VLFRETE, 0) +
                                                                          NVL(M.VLFRETE_RATEIO, 0) +
                                                                          NVL(M.VLOUTRASDESP, 0)),
                                                                 0))
                                                          WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                                                            (NVL(DECODE(N.CONDVENDA,
                                                                        7,
                                                                        DECODE(M.TIPOITEM,
                                                                               'N',
                                                                               NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                          'S',
                                                                                          M.PUNIT,
                                                                                          M.PUNITCONT),
                                                                                   0),
                                                                               M.PUNIT) + NVL(M.VLFRETE_RATEIO, 0) +
                                                                                 NVL(M.VLOUTRASDESP, 0),
                                                                        NVL(DECODE(M.TIPOITEM,
                                                                                   'N',
                                                                                   NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                              'S',
                                                                                              M.PUNIT,
                                                                                              M.PUNITCONT),
                                                                                       0),
                                                                                   M.PUNIT),
                                                                            0) + NVL(M.VLFRETE_RATEIO, 0) +
                                                                          NVL(M.VLOUTRASDESP, 0)),
                                                                 0))
                                                          ELSE
                                                            (NVL(DECODE(N.CONDVENDA,
                                                                        7,
                                                                        DECODE(M.TIPOITEM,
                                                                               'N',
                                                                               NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                          'S',
                                                                                          M.PUNIT,
                                                                                          M.PUNITCONT),
                                                                                   0),
                                                                               M.PUNIT) + NVL(M.VLFRETE, 0) +
                                                                          NVL(M.VLOUTRASDESP, 0) +
                                                                          NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                                          DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                 'S',
                                                                                 NVL(M.VLREPASSE, 0),
                                                                                 0),
                                                                        NVL(DECODE(M.TIPOITEM,
                                                                                   'N',
                                                                                   NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF,'N'),
                                                                                              'S',
                                                                                              M.PUNIT,
                                                                                              M.PUNITCONT),
                                                                                       0),
                                                                                   M.PUNIT),
                                                                            0) + NVL(M.VLFRETE, 0) +
                                                                          NVL(M.VLOUTRASDESP, 0) +
                                                                          NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                                          DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                 'S',
                                                                                 NVL(M.VLREPASSE, 0),
                                                                                 0)),
                                                                 0))
                                                        END) - NVL(M.VLIPI, 0) - NVL(M.ST, 0)),
                                               2)) + ROUND(NVL(M.VLIPI, 0) *
                                                 (DECODE(M.CODOPER,
                                                         'S',
                                                         (NVL(DECODE(N.CONDVENDA,
                                                                     5,
                                                                     0,
                                                                     6,
                                                                     0,
                                                                     11,
                                                                     0,
                                                                     12,
                                                                     0,
                                                                     DECODE(M.CODOPER,
                                                                            'SB',
                                                                            0,
                                                                            DECODE(M.TIPOITEM,
                                                                                   'N',
                                                                                   M.QTCONT,
                                                                                   M.QT))),
                                                              0)),
                                                         'ST',
                                                         (NVL(DECODE(N.CONDVENDA,
                                                                     5,
                                                                     0,
                                                                     6,
                                                                     0,
                                                                     11,
                                                                     0,
                                                                     12,
                                                                     0,
                                                                     DECODE(M.CODOPER,
                                                                            'SB',
                                                                            0,
                                                                            DECODE(M.TIPOITEM,
                                                                                   'N',
                                                                                   M.QTCONT,
                                                                                   M.QT))),
                                                              0)),
                                                         'SM',
                                                         (NVL(DECODE(N.CONDVENDA,
                                                                     5,
                                                                     0,
                                                                     6,
                                                                     0,
                                                                     11,
                                                                     0,
                                                                     12,
                                                                     0,
                                                                     DECODE(M.CODOPER,
                                                                            'SB',
                                                                            0,
                                                                            DECODE(M.TIPOITEM,
                                                                            'N',
                                                                            M.QTCONT,
                                                                            M.QT))),
                                                              0)),
                                                         0)),
                                                           2) +
                                                 ROUND(NVL(M.ST, 0) *
                                                       (DECODE(M.CODOPER,
                                                              'S',
                                                               (NVL(DECODE(N.CONDVENDA,
                                                                           5,
                                                                           0,
                                                                           6,
                                                                           0,
                                                                           11,
                                                                           0,
                                                                           12,
                                                                           0,
                                                                           DECODE(M.CODOPER,
                                                                                  'SB',
                                                                                  0,
                                                                                  DECODE(M.TIPOITEM,
                                                                                         'N',
                                                                                         M.QTCONT,
                                                                                         M.QT))),
                                                                    0)),
                                                               'ST',
                                                               (NVL(DECODE(N.CONDVENDA,
                                                                           5,
                                                                           0,
                                                                           6,
                                                                           0,
                                                                           11,
                                                                           0,
                                                                           12,
                                                                           0,
                                                                           DECODE(M.CODOPER,
                                                                                  'SB',
                                                                                  0,
                                                                                  DECODE(M.TIPOITEM,
                                                                                         'N',
                                                                                         M.QTCONT,
                                                                                         M.QT))),
                                                                    0)),
                                                               'SM',
                                                               (NVL(DECODE(N.CONDVENDA,
                                                                           5,
                                                                           0,
                                                                           6,
                                                                           0,
                                                                           11,
                                                                           0,
                                                                           12,
                                                                           0,
                                                                           DECODE(M.CODOPER,
                                                                                  'SB',
                                                                                  0,
                                                                                  DECODE(M.TIPOITEM,
                                                                                         'N',
                                                                                         M.QTCONT,
                                                                                         M.QT))),
                                                                    0)),
                                                                0)),
                                                       2)),
                                    0),
                                2)) VLVENDA
                      -- QT
                      ,SUM(NVL((DECODE(M.CODOPER,
                                      'S',
                                      (NVL(DECODE(N.CONDVENDA,
                                                  7,
                                                  DECODE(M.TIPOITEM,
                                                         'N',
                                                         M.QTCONT,
                                                         M.QT),
                                                  M.QT),
                                           0)),
                                      'SM',
                                      (NVL(DECODE(N.CONDVENDA,
                                                  7,
                                                  DECODE(M.TIPOITEM,
                                                         'N',
                                                         M.QTCONT,
                                                         M.QT),
                                                  M.QT),
                                           0)),
                                      'ST',
                                      (NVL(DECODE(N.CONDVENDA,
                                                  7,
                                                  DECODE(M.TIPOITEM,
                                                         'N',
                                                         M.QTCONT,
                                                         M.QT),
                                                  M.QT),
                                           0)),
                                      0)),
                              0)) QT
                      ,0 VLDEVOLUCAO
                      ,0 QTDEVOLUCAO
                      -- VLCUSTOFIN
                      ,SUM(NVL(ROUND((DECODE(M.CODOPER,
                                            'S',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        7,
                                                        DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT),
                                                        M.QT),
                                                 0)),
                                            'ST',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        7,
                                                        DECODE(M.TIPOITEM,
                                                              'N',
                                                               M.QTCONT,
                                                               M.QT),
                                                        M.QT),
                                                 0)),
                                            'SM',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        7,
                                                        DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT),
                                                        M.QT),
                                                 0)),
                                            0)) * (NVL(M.CUSTOFIN, 0)),
                                    2),
                          0)) VLCUSTOFIN
                      -- VLCUSTOREAL
                      ,SUM(NVL(ROUND((DECODE(M.CODOPER,
                                            'S',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        7,
                                                        DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT),
                                                        M.QT),
                                                 0)),
                                            'ST',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        7,
                                                        DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT),
                                                        M.QT),
                                                 0)),
                                            'SM',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        7,
                                                        DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT),
                                                        M.QT),
                                                 0)),
                                            0)) * (NVL(M.CUSTOREAL, 0)),
                                    2),
                              0)) VLCUSTOREAL
                 FROM PCNFSAID    N,
                      PCMOV       M,
                      PCMOVCOMPLE CP
                WHERE N.NUMTRANSVENDA = M.NUMTRANSVENDA
                  AND N.NUMNOTA       = M.NUMNOTA
                  AND M.NUMTRANSITEM  = CP.NUMTRANSITEM(+)
                  AND NVL(N.TIPOVENDA, 'X') NOT IN ('SR', 'DF')
                  AND N.DTCANCEL IS NULL
                  AND NVL(M.TIPOITEM, 'C') IN ('C', 'N')
                  AND N.CODFISCAL <> 0                  
                  AND N.DTSAIDA BETWEEN PDATAINI AND PDATAFIM
                  AND N.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
                  AND NVL(N.CONDVENDA, -1) IN (1, 5, -1, 7, 9, 11, 14)
                  AND NVL(M.CODOPER, 'X') IN ('S', 'SB', 'SM')
               GROUP BY N.CODFILIAL, M.CODPROD
               UNION ALL
               SELECT DEVOL.CODFILIAL
                     ,DEVOL.CODPROD
                     ,0 AS VLVENDA
                     ,0 AS QT
                     ,SUM(NVL(DEVOL.VLDEVOLUCAO, 0)) VLDEVOLUCAO
                     ,SUM(NVL(DEVOL.QT, 0)) QTDEVOLUCAO
                     ,0 AS VLCUSTOFIN
                     ,0 AS VLCUSTOREAL
                 FROM (SELECT PCNFENT.CODFILIAL,
                              PCMOV.CODPROD,            
                              NVL((DECODE(PCMOV.CODOPER,
                                          'S',
                                          (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                      7,
                                                      DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                                             'C',
                                                             PCMOV.QT,
                                                             PCMOV.QTCONT),
                                                      PCMOV.QT),
                                               0)),
                                          'SM',
                                          (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                      7,
                                                      DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                                             'C',
                                                             PCMOV.QT,
                                                             PCMOV.QTCONT),
                                                      PCMOV.QT),
                                               0)),
                                          'ST',
                                          (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                      7,
                                                      DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                                             'C',
                                                             PCMOV.QT,
                                                             PCMOV.QTCONT),
                                                      PCMOV.QT),
                                               0)),
                                          PCMOV.QT)),
                                  0) QT,
                                  
                               (NVL(PCMOV.QT, 0) *
                              (DECODE(PCNFSAID.CONDVENDA,
                                       5,
                                       0,
                                       6,
                                       0,
                                       11,
                                       0,
                                       1,
                                       (CASE
                                         WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') = 'N' THEN
                                          (DECODE(PCMOV.PUNIT,
                                                  0,
                                                  PCMOV.PUNITCONT,
                                                  NULL,
                                                  PCMOV.PUNITCONT,
                                                  PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                          NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                          NVL(PCMOV.VLOUTROS, 0))
                                         ELSE
                                          0
                                       END),
                                        
                                       (DECODE(PCMOV.PUNIT,
                                               0,
                                               PCMOV.PUNITCONT,
                                               NULL,
                                               PCMOV.PUNITCONT,
                                               PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                       NVL(PCMOV.VLOUTRASDESP, 0) +
                                       NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                       NVL(PCMOV.VLOUTROS, 0))) -
                              DECODE(PCNFSAID.CONDVENDA,
                                       5,
                                       0,
                                       6,
                                       0,
                                       11,
                                       0,
                                       NVL(PCMOV.VLREPASSE, 0)) -
                              DECODE(PCNFSAID.CONDVENDA,
                                       5,
                                       0,
                                       6,
                                       0,
                                       11,
                                       0,
                                       (NVL(PCMOV.ST, 0) + NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))))) +
                              ROUND((NVL(PCMOV.QT, 0) *
                                    DECODE(PCNFSAID.CONDVENDA,
                                            5,
                                            0,
                                            6,
                                            0,
                                            11,
                                            0,
                                            12,
                                            0,
                                            DECODE(PCMOV.CODOPER,
                                                   'SB',
                                                   0,
                                                   (NVL(PCMOV.ST, 0) +
                                                   NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))))),
                                    2) VLDEVOLUCAO            
                         FROM PCNFENT,
                              PCESTCOM,
                              PCNFSAID,
                              PCMOV,
                              PCMOVCOMPLE
                        WHERE PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT
                          AND PCESTCOM.NUMTRANSENT = PCMOV.NUMTRANSENT
                          AND PCESTCOM.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA(+)
                          AND NVL(PCESTCOM.NUMTRANSVENDA, 0) <> 0
                          AND PCNFENT.TIPODESCARGA IN ('6', '7', 'T')
                          AND NVL(PCNFENT.CODFISCAL, 0) IN (131, 132, 231, 232, 199, 299)
                          AND PCMOV.DTCANCEL IS NULL
                          AND PCMOV.CODOPER = 'ED'
                          AND (NVL(PCNFENT.ESPECIE, 'X') <> 'OE' OR
                              (NVL(PCNFENT.ESPECIE, 'X') = 'OE' AND
                              NVL(PCNFSAID.VENDAASSISTIDA, 'N') = 'S' AND
                              PCNFSAID.CONDVENDA = 7))
                          AND NVL(PCNFENT.OBS, 'X') <> 'NF CANCELADA'
                          AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                          AND NVL(PCNFENT.TIPOMOVGARANTIA, -1) = -1
                          AND NOT (PCNFENT.ROTINACAD LIKE '%1303%' AND PCNFSAID.CONDVENDA = 8)
                          AND PCNFENT.DTENT BETWEEN PDATAINI AND PDATAFIM
                          AND PCNFSAID.CONDVENDA NOT IN (4, 8, 10, 13, 20, 98, 99, 16)) DEVOL
                 
                WHERE 0 = 0
                GROUP BY DEVOL.CODFILIAL, DEVOL.CODPROD)
                WHERE PDATAINI <> SYSDATE --Para completar o número de parametros
                  AND PDATAFIM <> SYSDATE --Para completar o número de parametros
        GROUP BY CODFILIAL, CODPROD;

  CURSOR C_NOTASAUXCLI(PDATAINI DATE,
                       PDATAFIM DATE) IS 
    SELECT N.CODCLI,
           -- VLVENDA
           SUM(ROUND(NVL(NVL((CASE
                                WHEN ROUND(CP.VLSUBTOTITEM, 2) IS NOT NULL THEN
                                  (CASE
                                     WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                                       (DECODE(M.CODOPER,
                                               'S',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                0)),
                                               'ST',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                0)),
                                               'SM',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                0)),
                                               0) - (ROUND(NVL(M.VLFRETE, 0), 2) * M.QT))
                                     WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIROUTRASDESP' THEN
                                       (DECODE(M.CODOPER,
                                               'S',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'ST',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'SM',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               0) - (ROUND(NVL(M.VLOUTRASDESP, 0), 2) * M.QT))
                                     WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                                       (DECODE(M.CODOPER,
                                               'S',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'ST',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'SM',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               0) - (ROUND(NVL(M.VLFRETE, 0), 2) * M.QT) -
                                               (ROUND(NVL(M.VLOUTRASDESP, 0), 2) * M.QT))
                                     ELSE
                                       ROUND(CP.VLSUBTOTITEM, 2)
                                   END)
                                ELSE
                                  NULL
                              END),
                             (ROUND((DECODE(M.CODOPER,
                                            'S',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        5,
                                                        0,
                                                        6,
                                                        0,
                                                        11,
                                                        0,
                                                        12,
                                                        0,
                                                        DECODE(M.CODOPER,
                                                               'SB',
                                                               0,
                                                               DECODE(M.TIPOITEM,
                                                                      'N',
                                                                      M.QTCONT,
                                                                      M.QT))),
                                                 0)),
                                            'ST',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        5,
                                                        0,
                                                        6,
                                                        0,
                                                        11,
                                                        0,
                                                        12,
                                                        0,
                                                        DECODE(M.CODOPER,
                                                               'SB',
                                                               0,
                                                               DECODE(M.TIPOITEM,
                                                                      'N',
                                                                      M.QTCONT,
                                                                      M.QT))),
                                                 0)),
                                            'SM',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        5,
                                                        0,
                                                        6,
                                                        0,
                                                        11,
                                                        0,
                                                        12,
                                                        0,
                                                        DECODE(M.CODOPER,
                                                               'SB',
                                                               0,
                                                               DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT))),
                                                 0)),
                                            0)) *
                                           ((CASE
                                               WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                      'S',
                                                                      NVL(M.VLREPASSE, 0),
                                                                      0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                          'S',
                                                                          NVL(M.VLREPASSE, 0),
                                                                          0)),
                                                      0))
                                               WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIROUTRASDESP' THEN
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) +
                                                               NVL(M.VLOUTRASDESP, 0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) +
                                                               NVL(M.VLOUTRASDESP, 0)),
                                                      0))
                                               WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLFRETE_RATEIO, 0) +
                                                                      NVL(M.VLOUTRASDESP, 0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLFRETE_RATEIO, 0) +
                                                               NVL(M.VLOUTRASDESP, 0)),
                                                      0))
                                               ELSE
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                      'S',
                                                                      NVL(M.VLREPASSE, 0),
                                                                      0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF,'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                      'S',
                                                                      NVL(M.VLREPASSE, 0),
                                                                      0)),
                                                      0))
                                             END) - NVL(M.VLIPI, 0) - NVL(M.ST, 0)),
                                    2)) + ROUND(NVL(M.VLIPI, 0) *
                                      (DECODE(M.CODOPER,
                                              'S',
                                              (NVL(DECODE(N.CONDVENDA,
                                                          5,
                                                          0,
                                                          6,
                                                          0,
                                                          11,
                                                          0,
                                                          12,
                                                          0,
                                                          DECODE(M.CODOPER,
                                                                 'SB',
                                                                 0,
                                                                 DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        M.QTCONT,
                                                                        M.QT))),
                                                   0)),
                                              'ST',
                                              (NVL(DECODE(N.CONDVENDA,
                                                          5,
                                                          0,
                                                          6,
                                                          0,
                                                          11,
                                                          0,
                                                          12,
                                                          0,
                                                          DECODE(M.CODOPER,
                                                                 'SB',
                                                                 0,
                                                                 DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        M.QTCONT,
                                                                        M.QT))),
                                                   0)),
                                              'SM',
                                              (NVL(DECODE(N.CONDVENDA,
                                                          5,
                                                          0,
                                                          6,
                                                          0,
                                                          11,
                                                          0,
                                                          12,
                                                          0,
                                                          DECODE(M.CODOPER,
                                                                 'SB',
                                                                 0,
                                                                 DECODE(M.TIPOITEM,
                                                                 'N',
                                                                 M.QTCONT,
                                                                 M.QT))),
                                                   0)),
                                              0)),
                                                2) +
                                      ROUND(NVL(M.ST, 0) *
                                            (DECODE(M.CODOPER,
                                                    'S',
                                                    (NVL(DECODE(N.CONDVENDA,
                                                                5,
                                                                0,
                                                                6,
                                                                0,
                                                                11,
                                                                0,
                                                                12,
                                                                0,
                                                                DECODE(M.CODOPER,
                                                                       'SB',
                                                                       0,
                                                                       DECODE(M.TIPOITEM,
                                                                              'N',
                                                                              M.QTCONT,
                                                                              M.QT))),
                                                         0)),
                                                    'ST',
                                                    (NVL(DECODE(N.CONDVENDA,
                                                                5,
                                                                0,
                                                                6,
                                                                0,
                                                                11,
                                                                0,
                                                                12,
                                                                0,
                                                                DECODE(M.CODOPER,
                                                                       'SB',
                                                                       0,
                                                                       DECODE(M.TIPOITEM,
                                                                              'N',
                                                                              M.QTCONT,
                                                                              M.QT))),
                                                         0)),
                                                    'SM',
                                                    (NVL(DECODE(N.CONDVENDA,
                                                                5,
                                                                0,
                                                                6,
                                                                0,
                                                                11,
                                                                0,
                                                                12,
                                                                0,
                                                                DECODE(M.CODOPER,
                                                                       'SB',
                                                                       0,
                                                                       DECODE(M.TIPOITEM,
                                                                              'N',
                                                                              M.QTCONT,
                                                                              M.QT))),
                                                         0)),
                                                     0)),
                                            2)),
                         0),
                     2)) VLVENDA,
           -- VLCUSTOFIN
           SUM(NVL(ROUND((DECODE(M.CODOPER,
                                 'S',
                                 (NVL(DECODE(N.CONDVENDA,
                                             7,
                                             DECODE(M.TIPOITEM,
                                                    'N',
                                                    M.QTCONT,
                                                    M.QT),
                                             M.QT),
                                      0)),
                                 'ST',
                                 (NVL(DECODE(N.CONDVENDA,
                                             7,
                                             DECODE(M.TIPOITEM,
                                                    'N',
                                                    M.QTCONT,
                                                    M.QT),
                                             M.QT),
                                      0)),
                                 'SM',
                                 (NVL(DECODE(N.CONDVENDA,
                                             7,
                                             DECODE(M.TIPOITEM,
                                                    'N',
                                                    M.QTCONT,
                                                    M.QT),
                                             M.QT),
                                      0)),
                                 0)) * (NVL(M.CUSTOFIN, 0)),
                         2),
               0)) VLCUSTOFIN,
           -- VLCUSTOREAL
           SUM(NVL(ROUND((DECODE(M.CODOPER,
                                 'S',
                                 (NVL(DECODE(N.CONDVENDA,
                                             7,
                                             DECODE(M.TIPOITEM,
                                                    'N',
                                                    M.QTCONT,
                                                    M.QT),
                                             M.QT),
                                      0)),
                                 'ST',
                                 (NVL(DECODE(N.CONDVENDA,
                                             7,
                                             DECODE(M.TIPOITEM,
                                                    'N',
                                                    M.QTCONT,
                                                    M.QT),
                                             M.QT),
                                      0)),
                                 'SM',
                                 (NVL(DECODE(N.CONDVENDA,
                                             7,
                                             DECODE(M.TIPOITEM,
                                                    'N',
                                                    M.QTCONT,
                                                    M.QT),
                                             M.QT),
                                      0)),
                                 0)) * (NVL(M.CUSTOREAL, 0)),
                         2),
                   0)) VLCUSTOREAL,
           -- QT
           COUNT(DISTINCT N.NUMNOTA) QT,
           -- QTMIX
           COUNT(DISTINCT M.CODPROD) QTMIX
      FROM PCNFSAID    N,
           PCMOV       M,
           PCMOVCOMPLE CP
     WHERE N.NUMTRANSVENDA = M.NUMTRANSVENDA
       AND N.NUMNOTA       = M.NUMNOTA
       AND M.NUMTRANSITEM  = CP.NUMTRANSITEM(+)
       AND NVL(N.TIPOVENDA, 'X') NOT IN ('SR', 'DF')
       AND N.DTCANCEL IS NULL
       AND NVL(M.TIPOITEM, 'C') IN ('C', 'N')
       AND N.CODFISCAL <> 0       
       AND N.DTSAIDA BETWEEN PDATAINI AND PDATAFIM
       AND N.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
       AND NVL(N.CONDVENDA, -1) IN (1, 5, -1, 7, 9, 11, 14)
    GROUP BY N.CODCLI;
    
  CURSOR C_NOTAS_CLI_FILIAL(PDATAINI DATE,
                            PDATAFIM DATE) IS
    SELECT N.CODCLI,
           N.CODFILIAL,
           -- VLVENDA
           SUM(ROUND(NVL(NVL((CASE
                                WHEN ROUND(CP.VLSUBTOTITEM, 2) IS NOT NULL THEN
                                  (CASE
                                     WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                                       (DECODE(M.CODOPER,
                                               'S',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                0)),
                                               'ST',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                0)),
                                               'SM',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                0)),
                                               0) - (ROUND(NVL(M.VLFRETE, 0), 2) * M.QT))
                                     WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIROUTRASDESP' THEN
                                       (DECODE(M.CODOPER,
                                               'S',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'ST',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'SM',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               0) - (ROUND(NVL(M.VLOUTRASDESP, 0), 2) * M.QT))
                                     WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                                       (DECODE(M.CODOPER,
                                               'S',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'ST',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               'SM',
                                               (NVL(DECODE(N.CONDVENDA,
                                                           5,
                                                           0,
                                                           6,
                                                           0,
                                                           11,
                                                           0,
                                                           12,
                                                           0,
                                                           DECODE(M.CODOPER,
                                                                  'SB',
                                                                  0,
                                                                  ROUND(CP.VLSUBTOTITEM, 2))),
                                                    0)),
                                               0) - (ROUND(NVL(M.VLFRETE, 0), 2) * M.QT) -
                                               (ROUND(NVL(M.VLOUTRASDESP, 0), 2) * M.QT))
                                     ELSE
                                       ROUND(CP.VLSUBTOTITEM, 2)
                                   END)
                                ELSE
                                  NULL
                              END),
                             (ROUND((DECODE(M.CODOPER,
                                            'S',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        5,
                                                        0,
                                                        6,
                                                        0,
                                                        11,
                                                        0,
                                                        12,
                                                        0,
                                                        DECODE(M.CODOPER,
                                                               'SB',
                                                               0,
                                                               DECODE(M.TIPOITEM,
                                                                      'N',
                                                                      M.QTCONT,
                                                                      M.QT))),
                                                 0)),
                                            'ST',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        5,
                                                        0,
                                                        6,
                                                        0,
                                                        11,
                                                        0,
                                                        12,
                                                        0,
                                                        DECODE(M.CODOPER,
                                                               'SB',
                                                               0,
                                                               DECODE(M.TIPOITEM,
                                                                      'N',
                                                                      M.QTCONT,
                                                                      M.QT))),
                                                 0)),
                                            'SM',
                                            (NVL(DECODE(N.CONDVENDA,
                                                        5,
                                                        0,
                                                        6,
                                                        0,
                                                        11,
                                                        0,
                                                        12,
                                                        0,
                                                        DECODE(M.CODOPER,
                                                               'SB',
                                                               0,
                                                               DECODE(M.TIPOITEM,
                                                               'N',
                                                               M.QTCONT,
                                                               M.QT))),
                                                 0)),
                                            0)) *
                                           ((CASE
                                               WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                      'S',
                                                                      NVL(M.VLREPASSE, 0),
                                                                      0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                          'S',
                                                                          NVL(M.VLREPASSE, 0),
                                                                          0)),
                                                      0))
                                               WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIROUTRASDESP' THEN
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) +
                                                               NVL(M.VLOUTRASDESP, 0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) +
                                                               NVL(M.VLOUTRASDESP, 0)),
                                                      0))
                                               WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLFRETE_RATEIO, 0) +
                                                                      NVL(M.VLOUTRASDESP, 0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLFRETE_RATEIO, 0) +
                                                               NVL(M.VLOUTRASDESP, 0)),
                                                      0))
                                               ELSE
                                                 (NVL(DECODE(N.CONDVENDA,
                                                             7,
                                                             DECODE(M.TIPOITEM,
                                                                    'N',
                                                                    NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                               'S',
                                                                               M.PUNIT,
                                                                               M.PUNITCONT),
                                                                        0),
                                                                    M.PUNIT) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                      'S',
                                                                      NVL(M.VLREPASSE, 0),
                                                                      0),
                                                             NVL(DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        NVL(DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF,'N'),
                                                                                   'S',
                                                                                   M.PUNIT,
                                                                                   M.PUNITCONT),
                                                                            0),
                                                                        M.PUNIT),
                                                                 0) + NVL(M.VLFRETE, 0) +
                                                               NVL(M.VLOUTRASDESP, 0) +
                                                               NVL(M.VLFRETE_RATEIO, 0) + NVL(M.VLOUTROS, 0) -
                                                               DECODE(NVL(N.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                                      'S',
                                                                      NVL(M.VLREPASSE, 0),
                                                                      0)),
                                                      0))
                                             END) - NVL(M.VLIPI, 0) - NVL(M.ST, 0)),
                                    2)) + ROUND(NVL(M.VLIPI, 0) *
                                      (DECODE(M.CODOPER,
                                              'S',
                                              (NVL(DECODE(N.CONDVENDA,
                                                          5,
                                                          0,
                                                          6,
                                                          0,
                                                          11,
                                                          0,
                                                          12,
                                                          0,
                                                          DECODE(M.CODOPER,
                                                                 'SB',
                                                                 0,
                                                                 DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        M.QTCONT,
                                                                        M.QT))),
                                                   0)),
                                              'ST',
                                              (NVL(DECODE(N.CONDVENDA,
                                                          5,
                                                          0,
                                                          6,
                                                          0,
                                                          11,
                                                          0,
                                                          12,
                                                          0,
                                                          DECODE(M.CODOPER,
                                                                 'SB',
                                                                 0,
                                                                 DECODE(M.TIPOITEM,
                                                                        'N',
                                                                        M.QTCONT,
                                                                        M.QT))),
                                                   0)),
                                              'SM',
                                              (NVL(DECODE(N.CONDVENDA,
                                                          5,
                                                          0,
                                                          6,
                                                          0,
                                                          11,
                                                          0,
                                                          12,
                                                          0,
                                                          DECODE(M.CODOPER,
                                                                 'SB',
                                                                 0,
                                                                 DECODE(M.TIPOITEM,
                                                                 'N',
                                                                 M.QTCONT,
                                                                 M.QT))),
                                                   0)),
                                              0)),
                                                2) +
                                      ROUND(NVL(M.ST, 0) *
                                            (DECODE(M.CODOPER,
                                                    'S',
                                                    (NVL(DECODE(N.CONDVENDA,
                                                                5,
                                                                0,
                                                                6,
                                                                0,
                                                                11,
                                                                0,
                                                                12,
                                                                0,
                                                                DECODE(M.CODOPER,
                                                                       'SB',
                                                                       0,
                                                                       DECODE(M.TIPOITEM,
                                                                              'N',
                                                                              M.QTCONT,
                                                                              M.QT))),
                                                         0)),
                                                    'ST',
                                                    (NVL(DECODE(N.CONDVENDA,
                                                                5,
                                                                0,
                                                                6,
                                                                0,
                                                                11,
                                                                0,
                                                                12,
                                                                0,
                                                                DECODE(M.CODOPER,
                                                                       'SB',
                                                                       0,
                                                                       DECODE(M.TIPOITEM,
                                                                              'N',
                                                                              M.QTCONT,
                                                                              M.QT))),
                                                         0)),
                                                    'SM',
                                                    (NVL(DECODE(N.CONDVENDA,
                                                                5,
                                                                0,
                                                                6,
                                                                0,
                                                                11,
                                                                0,
                                                                12,
                                                                0,
                                                                DECODE(M.CODOPER,
                                                                       'SB',
                                                                       0,
                                                                       DECODE(M.TIPOITEM,
                                                                              'N',
                                                                              M.QTCONT,
                                                                              M.QT))),
                                                         0)),
                                                     0)),
                                            2)),
                         0),
                     2)) VLVENDA,
           -- QT
           COUNT(DISTINCT N.NUMNOTA) QT,
           0 VLCOMPRA
      FROM PCNFSAID    N,
           PCMOV       M,
           PCMOVCOMPLE CP
     WHERE N.NUMTRANSVENDA = M.NUMTRANSVENDA
       AND N.NUMNOTA       = M.NUMNOTA
       AND M.NUMTRANSITEM  = CP.NUMTRANSITEM(+)
       AND NVL(N.TIPOVENDA, 'X') NOT IN ('SR', 'DF')
       AND N.DTCANCEL IS NULL
       AND NVL(M.TIPOITEM, 'C') IN ('C', 'N')
       AND N.CODFISCAL <> 0       
       AND N.DTSAIDA BETWEEN PDATAINI AND PDATAFIM
       AND N.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
       AND NVL(N.CONDVENDA, -1) IN (1, 5, -1, 7, 9, 11, 14)
       AND NVL(TRIM(N.CODFILIAL),'X') <> 'X'
    GROUP BY N.CODCLI, N.CODFILIAL;  
    
  CURSOR C_PED_AUXPRO(PDATAINI DATE,
                      PDATAFIM DATE) IS 
    WITH DEVOLUCAO AS
                  (SELECT DEVOL.NUMPED,
                          SUM(NVL(DEVOL.VLDEVOLUCAO, 0)) VLDEVOLUCAO,
                          SUM(NVL(DEVOL.QT, 0)) QTDEVOLUCAO
                     FROM (SELECT PCNFSAID.NUMPED,                                  
                                  PCMOV.QT,
                                  (NVL(PCMOV.QT, 0) *
                                  (DECODE(PCNFSAID.CONDVENDA,
                                           5,
                                           0,
                                           6,
                                           0,
                                           11,
                                           0,
                                           1,
                                           (CASE
                                             WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') = 'N' THEN
                                              (DECODE(PCMOV.PUNIT,
                                                      0,
                                                      PCMOV.PUNITCONT,
                                                      NULL,
                                                      PCMOV.PUNITCONT,
                                                      PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                              NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                              NVL(PCMOV.VLOUTROS, 0))
                                             ELSE
                                              0
                                           END),
                                           (DECODE(PCMOV.PUNIT,
                                                   0,
                                                   PCMOV.PUNITCONT,
                                                   NULL,
                                                   PCMOV.PUNITCONT,
                                                   PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                           NVL(PCMOV.VLOUTROS, 0))) -
                                  DECODE(PCNFSAID.CONDVENDA,
                                           5,
                                           0,
                                           6,
                                           0,
                                           11,
                                           0,
                                           NVL(PCMOV.VLREPASSE, 0)) -
                                  DECODE(PCNFSAID.CONDVENDA,
                                           5,
                                           0,
                                           6,
                                           0,
                                           11,
                                           0,
                                           (NVL(PCMOV.ST, 0) + NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))))) +
                                  ROUND((NVL(PCMOV.QT, 0) *
                                        DECODE(PCNFSAID.CONDVENDA,
                                                5,
                                                0,
                                                6,
                                                0,
                                                11,
                                                0,
                                                12,
                                                0,
                                                DECODE(PCMOV.CODOPER,
                                                       'SB',
                                                       0,
                                                       (NVL(PCMOV.ST, 0) +
                                                       NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))))),
                                        2) VLDEVOLUCAO
                             FROM PCNFENT,
                                  PCESTCOM,
                                  PCNFSAID,
                                  PCMOV,
                                  PCMOVCOMPLE
                            WHERE PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT
                              AND PCESTCOM.NUMTRANSENT = PCMOV.NUMTRANSENT
                              AND PCESTCOM.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA(+)
                              AND NVL(PCESTCOM.NUMTRANSVENDA, 0) <> 0
                              AND PCNFENT.TIPODESCARGA IN ('6', '7', 'T')
                              AND NVL(PCNFENT.CODFISCAL, 0) IN (131, 132, 231, 232, 199, 299)
                              AND PCMOV.DTCANCEL IS NULL
                              AND PCMOV.CODOPER = 'ED'
                              AND (NVL(PCNFENT.ESPECIE, 'X') <> 'OE' OR
                                  (NVL(PCNFENT.ESPECIE, 'X') = 'OE' AND
                                  NVL(PCNFSAID.VENDAASSISTIDA, 'N') = 'S' AND
                                  PCNFSAID.CONDVENDA = 7))
                              AND NVL(PCNFENT.OBS, 'X') <> 'NF CANCELADA'
                              AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                              AND NVL(PCNFENT.TIPOMOVGARANTIA, -1) = -1
                              AND PCNFENT.DTENT BETWEEN PDATAINI AND PDATAFIM
                              AND NOT (PCNFENT.ROTINACAD LIKE '%1303%' AND PCNFSAID.CONDVENDA = 8)) DEVOL
                    WHERE 0 = 0
                    GROUP BY DEVOL.NUMPED)

                  SELECT P.CODFILIAL,
                         I.CODPROD,
                         SUM(DECODE(P.CONDVENDA,
                                    5, 0,
                                    6, 0,
                                    11, 0,
                                    12, 0,
                                    NVL(I.QT, 0)) * NVL(I.PVENDA, 0)
                            ) VLVENDA,
                         SUM(NVL(I.QT, 0)) QT,
                         SUM(NVL(DEVOLUCAO.VLDEVOLUCAO, 0)) VLDEVOLUCAO,
                         SUM(NVL(DEVOLUCAO.QTDEVOLUCAO, 0)) QTDEVOLUCAO,
                         SUM(NVL(I.QT, 0) * NVL(I.VLCUSTOFIN, 0)) VLCUSTOFIN,
                         SUM(NVL(I.QT, 0) * NVL(I.VLCUSTOREAL, 0)) VLCUSTOREAL,
                         0 VLCOMPRA,
                         0 QTCOMPRA
                    FROM PCPEDC P,
                         PCPEDI I,
                         DEVOLUCAO

                   WHERE I.NUMPED = P.NUMPED
                     AND P.NUMPED = DEVOLUCAO.NUMPED(+)
                     AND P.CONDVENDA NOT IN (4, 8, 10, 13, 20, 16)
                     AND P.DTCANCEL IS NULL
                     AND (
                         ((I.DTCONSOLIDACAOAUXPRO IS NULL) AND (P.DATA BETWEEN PDATAINI AND PDATAFIM ))
                           OR ((I.DTCONSOLIDACAOAUXPRO IS NOT NULL) AND (I.DTCONSOLIDACAOAUXPRO BETWEEN PDATAINI AND PDATAFIM ))
                         )
                   GROUP BY P.CODFILIAL, I.CODPROD;  
                   
  CURSOR C_MOV(PDATAINI DATE,
               PDATAFIM DATE) IS 
    SELECT PCMOV.CODFILIAL,
           PCMOV.CODPROD,
           0 VLVENDA,
           0 QTVENDA,           
           0 VLDEVOLUCAO,
           0 QTDEVOLUCAO,
           SUM((DECODE(PCMOV.CODOPER,
                       'EL',
                       (NVL(PCMOV.QT, 0) * (-1)),
                       NVL(PCMOV.QT, 0)) *
               NVL(PCMOV.CUSTOFIN, 0))) VLCUSTOFIN,
           SUM((DECODE(PCMOV.CODOPER,
                       'EL',
                       (NVL(PCMOV.QT, 0) * (-1)),
                       NVL(PCMOV.QT, 0)) *
               NVL(PCMOV.CUSTOREAL, 0))) VLCUSTOREAL,
           0 VLCOMPRA,
           0 QTCOMPRA    
      FROM PCMOV
     WHERE PCMOV.DTMOV >= PDATAINI
       AND PCMOV.DTMOV <= PDATAFIM
       AND NVL(PCMOV.CODOPER, 'X') IN ('SL', 'EL')
     GROUP BY PCMOV.CODFILIAL, PCMOV.CODPROD;                 
    
  CURSOR C_NOTASENTRADA(PDATAINI DATE,
                        PDATAFIM DATE) IS
    SELECT PCMOV.CODFILIAL,
           PCMOV.CODPROD,
           SUM(PCMOV.QT * DECODE(NVL((SELECT PCNFSAID.SOMAREPASSEOUTRASDESPNF FROM PCNFSAID WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
                 AND PCNFSAID.NUMNOTA = PCMOV.NUMNOTA),'N'),'N', PCMOV.PUNIT, PCMOV.PUNITCONT)) VLCOMPRA,
           SUM(PCMOV.QT) QTCOMPRA,
           
           0 VLVENDA,
           0 QTVENDA,
           0 VLDEVOLUCAO,
           0 QTDEVOLUCAO,
           0 VLCUSTOFIN,
           0 VLCUSTOREAL
           
      FROM PCMOV, PCNFENT
   WHERE PCMOV.DTMOV BETWEEN PDATAINI AND PDATAFIM
       AND PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
       AND PCMOV.DTCANCEL IS NULL
       AND PCMOV.CODOPER = 'E'
       AND PCNFENT.TIPODESCARGA NOT IN ('6', '7', '8')
       AND PCMOV.STATUS IN ('B', 'AB')
       AND PCNFENT.CODCONT =
           (SELECT CODCONTFOR FROM PCCONSUM)
     GROUP BY PCMOV.CODFILIAL, PCMOV.CODPROD;  
    
 
  /* VARIAVEIS */
  VMES               VARCHAR2(2);
  VANO               VARCHAR2(4);
  VSQL               VARCHAR2(32767);
  VTIPODADOSPCAUXPRO VARCHAR2(1);
  DATA               DATE;
  VN_CODCLI          NUMBER;
  VS_CODFILIAL       VARCHAR2(2);
  VN_INDEX           NUMBER;  
  
  VCODIGO_ARRAY      T_CODIGO_ARRAY;
  VCODFILIAL_ARRAY   T_CODFILIAL_ARRAY;
  VCODCLI_ARRAY      T_CODCLI_ARRAY;
  VVLVENDA_ARRAY     T_VLVENDA_ARRAY;
  VVLDEVOLUCAO_ARRAY T_VLDEVOLUCAO_ARRAY;
  VVLCUSTOFIN_ARRAY  T_VLCUSTOFIN_ARRAY;
  VVLCUSTOREAL_ARRAY T_VLCUSTOREAL_ARRAY;
  VQT_ARRAY          T_QT_ARRAY;
  VQTDEVOLUCAO_ARRAY T_QTDEVOLUCAO_ARRAY;
  VQTMIX_ARRAY       T_QTMIX_ARRAY;
  VVLCOMPRA_ARRAY    T_VLVENDA_ARRAY;
  VQTCOMPRA_ARRAY    T_QT_ARRAY;
  V_LIMITE           INTEGER := 1000;
    
  BEGIN
    VMES := TO_CHAR(PDATAINI, 'MM');
    VANO := TO_CHAR(PDATAINI, 'YYYY');

    /* Zerando tabela PCAUXCLI */
    P_PC_ZERAMESPCAUXCLI(VMES, VANO, PMENSAGEM);
    IF PMENSAGEM IS NOT NULL THEN
      ROLLBACK;
    END IF;

    /* Zerando tabela PCCONSOLIDAMES */
    P_PC_ZERAMESPCCONSOLIDAMES(VMES, VANO, PMENSAGEM);
    IF PMENSAGEM IS NOT NULL THEN
      ROLLBACK;
    END IF;
    
    OPEN C_NOTASAUXCLI(PDATAINI, PDATAFIM);
    LOOP
      FETCH C_NOTASAUXCLI BULK COLLECT 
        INTO VCODCLI_ARRAY,
             VVLVENDA_ARRAY,
             VVLCUSTOFIN_ARRAY,
             VVLCUSTOREAL_ARRAY,
             VQT_ARRAY,
             VQTMIX_ARRAY        
        LIMIT V_LIMITE;      
      EXIT WHEN VCODCLI_ARRAY.COUNT = 0;    
      
      /* Processo de atualização da PCAUXCLI  */                                 
      P_PC_ATUALIZAPCAUXCLI_NOTAS(VCODCLI_ARRAY,
                                  VANO,
                                  VMES,
                                  VVLVENDA_ARRAY,
                                  VVLCUSTOFIN_ARRAY,
                                  VVLCUSTOREAL_ARRAY,
                                  VQT_ARRAY,
                                  VQTMIX_ARRAY, 
                                  PMENSAGEM);                            
                              
        IF PMENSAGEM IS NOT NULL THEN
          ROLLBACK WORK;
        END IF;       
    END LOOP;
    CLOSE C_NOTASAUXCLI;
    
    BEGIN
      OPEN C_NOTAS_CLI_FILIAL(PDATAINI, PDATAFIM);
      LOOP
        FETCH C_NOTAS_CLI_FILIAL BULK COLLECT 
        INTO VCODIGO_ARRAY,
             VCODFILIAL_ARRAY,
             VVLVENDA_ARRAY,             
             VQT_ARRAY,      
             VVLCOMPRA_ARRAY       
        LIMIT V_LIMITE;      
        EXIT WHEN VCODIGO_ARRAY.COUNT = 0;      
      
        /* Processo de atualização da PCCONSOLIDAMES  */
        P_PC_ATUALIZAPCCONSOLIDAMES_N(VCODIGO_ARRAY,
                                      VANO,
                                      VMES,
                                      VVLVENDA_ARRAY,
                                      VVLCOMPRA_ARRAY,
                                      VQT_ARRAY,
                                      VCODFILIAL_ARRAY,
                                      'C');     
        
      END LOOP;
      CLOSE C_NOTAS_CLI_FILIAL;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010,'Erro  -- Atualização do PCAUXPRO. CLI: '|| VN_CODCLI || 'Filial: ' || VS_CODFILIAL || 'ANO: ' || VANO || 'MES: ' || VMES ||' Erro original: ' || SQLERRM);
        PMENSAGEM := 'Erro:' || SQLERRM;
        ROLLBACK;
    END; -- final do begin do for para consolidação do mês

    /* Zerando tabela PCAUXPRO */
    P_PC_ZERAMESPCAUXPRO(VMES, VANO, PMENSAGEM);
    IF PMENSAGEM IS NOT NULL THEN
      ROLLBACK;
    END IF;

    /*Verificando parâmetro na PCCONSUM*/
    SELECT NVL(TIPOGERACAODADOSPCAUXPRO, 'V')
      INTO VTIPODADOSPCAUXPRO
      FROM PCCONSUM;

    IF VTIPODADOSPCAUXPRO = 'V' THEN
      --Se o parametro estiver marcado para venda

      BEGIN
        OPEN C_PED_AUXPRO(PDATAINI, PDATAFIM);
        LOOP
          FETCH C_PED_AUXPRO BULK COLLECT 
          INTO VCODFILIAL_ARRAY,
               VCODIGO_ARRAY,
               VVLVENDA_ARRAY,             
               VQT_ARRAY,
               VVLDEVOLUCAO_ARRAY,
               VQTDEVOLUCAO_ARRAY,
               VVLCUSTOFIN_ARRAY,
               VVLCUSTOREAL_ARRAY,
               VVLCOMPRA_ARRAY,
               VQTCOMPRA_ARRAY             
          LIMIT V_LIMITE;      
          EXIT WHEN VCODIGO_ARRAY.COUNT = 0;   
        
          /* Processo de atualização da PCAUXPRO  */
          P_PC_ATUALIZAPCAUXPRO_N(VCODIGO_ARRAY,
                                  VANO,
                                  VMES,
                                  VCODFILIAL_ARRAY,
                                  VVLVENDA_ARRAY,
                                  VVLCUSTOFIN_ARRAY,
                                  VVLCUSTOREAL_ARRAY,
                                  VQT_ARRAY,
                                  VVLDEVOLUCAO_ARRAY,
                                  VQTDEVOLUCAO_ARRAY,
                                  VVLCOMPRA_ARRAY,
                                  VQTCOMPRA_ARRAY,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0);

          /* Processo de atualização da PCCONSOLIDAMES */
          P_PC_ATUALIZAPCCONSOLIDAMES_N(VCODIGO_ARRAY,
                                        VANO,
                                        VMES,
                                        VVLVENDA_ARRAY,
                                        VVLCOMPRA_ARRAY,
                                        VQT_ARRAY,
                                        VCODFILIAL_ARRAY,
                                        'P');
          
        END LOOP;
        CLOSE C_PED_AUXPRO;   
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20011,'Erro  -- Atualização do PCAUXPRO. '|| SQLERRM);
          PMENSAGEM := 'Erro: ' || SQLERRM;
      END;
    ELSE
      --Se o parametro estiver marcado para faturamento
      BEGIN
        OPEN C_NOTAS(PDATAINI, PDATAFIM);
        LOOP
          FETCH C_NOTAS BULK COLLECT 
          INTO VCODFILIAL_ARRAY,
               VCODIGO_ARRAY,
               VVLVENDA_ARRAY,             
               VQT_ARRAY,
               VVLDEVOLUCAO_ARRAY,
               VQTDEVOLUCAO_ARRAY,
               VVLCUSTOFIN_ARRAY,
               VVLCUSTOREAL_ARRAY,
               VVLCOMPRA_ARRAY,
               VQTCOMPRA_ARRAY             
          LIMIT V_LIMITE;      
          EXIT WHEN VCODIGO_ARRAY.COUNT = 0;
        
          /* Processo de atualização da PCAUXPRO  */
          P_PC_ATUALIZAPCAUXPRO_N(VCODIGO_ARRAY,
                                  VANO,
                                  VMES,
                                  VCODFILIAL_ARRAY,
                                  VVLVENDA_ARRAY,
                                  VVLCUSTOFIN_ARRAY,
                                  VVLCUSTOREAL_ARRAY,
                                  VQT_ARRAY,
                                  VVLDEVOLUCAO_ARRAY,
                                  VQTDEVOLUCAO_ARRAY,
                                  VVLCOMPRA_ARRAY,
                                  VQTCOMPRA_ARRAY,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0);

          /* Processo de atualização da PCCONSOLIDAMES */
          P_PC_ATUALIZAPCCONSOLIDAMES_N(VCODIGO_ARRAY,
                                        VANO,
                                        VMES,
                                        VVLVENDA_ARRAY,
                                        VVLCOMPRA_ARRAY,
                                        VQT_ARRAY,
                                        VCODFILIAL_ARRAY,
                                        'P');
        
          
        END LOOP;
        CLOSE C_NOTAS;           
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20011,'Erro  -- Atualização do PCAUXPRO. '|| SQLERRM);
          PMENSAGEM := 'Erro: ' || SQLERRM;
      END;         
    END IF;    

    IF VTIPODADOSPCAUXPRO = 'V' THEN
      BEGIN
        OPEN C_MOV(PDATAINI, PDATAFIM);
        LOOP
          FETCH C_MOV BULK COLLECT 
          INTO VCODFILIAL_ARRAY,
               VCODIGO_ARRAY,     
               VVLVENDA_ARRAY,             
               VQT_ARRAY,
               VVLDEVOLUCAO_ARRAY,
               VQTDEVOLUCAO_ARRAY,                         
               VVLCUSTOFIN_ARRAY,
               VVLCUSTOREAL_ARRAY,
               VVLCOMPRA_ARRAY,
               VQTCOMPRA_ARRAY             
          LIMIT V_LIMITE;      
          EXIT WHEN VCODIGO_ARRAY.COUNT = 0; 
          
          /* Processo de atualização da PCAUXPRO  */
          P_PC_ATUALIZAPCAUXPRO_N(VCODIGO_ARRAY,
                                  VANO,
                                  VMES,
                                  VCODFILIAL_ARRAY,
                                  VVLVENDA_ARRAY,
                                  VVLCUSTOFIN_ARRAY,
                                  VVLCUSTOREAL_ARRAY,
                                  VQT_ARRAY,
                                  VVLDEVOLUCAO_ARRAY,
                                  VQTDEVOLUCAO_ARRAY,
                                  VVLCOMPRA_ARRAY,
                                  VQTCOMPRA_ARRAY,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0);
           
        END LOOP;
        CLOSE C_MOV;       
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20013,'Erro  -- Atualização do PCAUXPRO. '|| SQLERRM);
          PMENSAGEM := 'Erro: ' || SQLERRM;
      END;
    END IF;

    VSQL := 'UPDATE PCAUXPRO SET VLCOMPRAMES' || VMES || ' = 0 ' ||
            'WHERE ANO = ' || VANO;
    EXECUTE IMMEDIATE VSQL;

    BEGIN
      OPEN C_NOTASENTRADA(PDATAINI, PDATAFIM);
      LOOP
        FETCH C_NOTASENTRADA BULK COLLECT 
          INTO VCODFILIAL_ARRAY,
               VCODIGO_ARRAY,     
               VVLCOMPRA_ARRAY,
               VQTCOMPRA_ARRAY,
               
               VVLVENDA_ARRAY,             
               VQT_ARRAY,
               VVLDEVOLUCAO_ARRAY,
               VQTDEVOLUCAO_ARRAY,                         
               VVLCUSTOFIN_ARRAY,
               VVLCUSTOREAL_ARRAY                            
          LIMIT V_LIMITE;      
          EXIT WHEN VCODIGO_ARRAY.COUNT = 0;  
          
        /* Processo de atualização da PCAUXPRO  */
        P_PC_ATUALIZAPCAUXPRO_N(VCODIGO_ARRAY,
                                VANO,
                                VMES,
                                VCODFILIAL_ARRAY,
                                VVLVENDA_ARRAY,
                                VVLCUSTOFIN_ARRAY,
                                VVLCUSTOREAL_ARRAY,
                                VQT_ARRAY,
                                VVLDEVOLUCAO_ARRAY,
                                VQTDEVOLUCAO_ARRAY,
                                VVLCOMPRA_ARRAY,
                                VQTCOMPRA_ARRAY,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0);
                                
        /* Processo de atualização da PCCONSOLIDAMES */
        P_PC_ATUALIZAPCCONSOLIDAMES_N(VCODIGO_ARRAY,
                                      VANO,
                                      VMES,
                                      VVLVENDA_ARRAY,
                                      VVLCOMPRA_ARRAY,
                                      VQT_ARRAY,
                                      VCODFILIAL_ARRAY,
                                      'P');
      END LOOP;
      CLOSE C_NOTASENTRADA;          
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20014,'Erro  -- Atualização do PCAUXPRO. '|| SQLERRM);
        PMENSAGEM := 'Erro: ' || SQLERRM;
    END;

    /*Verificando a existência na PCHISTEST*/
    SELECT MAX(PCHISTEST.DATA) DATAPCHISTEST
      INTO DATA
      FROM PCHISTEST
     WHERE PCHISTEST.DATA BETWEEN PDATAINI AND PDATAFIM;

    IF DATA IS NOT NULL THEN
      BEGIN
        VN_INDEX := 0;
        FOR DADOS IN (SELECT PCHISTEST.CODFILIAL,
                             PCHISTEST.CODPROD,
                             (NVL(PCHISTEST.QTESTGER, 0) *
                             NVL(PCHISTEST.CUSTOFIN, 0)) VLESTOQUE,
                             NVL(PCHISTEST.CUSTOFIN, 0) CUSTOFIN,
                             NVL(PCHISTEST.CUSTOREAL, 0) CUSTOREAL,
                             NVL(PCHISTEST.CUSTOCONT, 0) CUSTOCONT,
                             NVL(PCHISTEST.QTESTGER, 0) QTESTGER
                        FROM PCHISTEST
                       WHERE PCHISTEST.DATA = PDATAFIM) LOOP
          /* Processo de atualização da PCAUXPRO  */
          P_PC_ATUALIZAPCAUXPRO(DADOS.CODPROD,
                                VANO,
                                VMES,
                                DADOS.CODFILIAL,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                DADOS.VLESTOQUE,
                                DADOS.CUSTOFIN,
                                DADOS.CUSTOREAL,
                                DADOS.CUSTOCONT,
                                DADOS.QTESTGER,
                                0);

          VN_INDEX := VN_INDEX +1;
          IF (pCommit = 'S' AND VN_INDEX >= 1000) THEN
            COMMIT;
            VN_INDEX := 0;
          END IF;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20015,'Erro  -- Atualização do PCAUXPRO.'|| SQLERRM);
          PMENSAGEM := 'Erro:' || SQLERRM;
      END;
    ELSE
      --Caso a tabela PCHISTEST for nula
      BEGIN
        VN_INDEX := 0;
        FOR DADOS IN (SELECT PCEST.CODFILIAL,
                             PCEST.CODPROD,
                             (NVL(PCEST.QTESTGER, 0) *
                             NVL(PCEST.CUSTOFIN, 0)) VLESTOQUE,
                             NVL(PCEST.CUSTOFIN, 0) CUSTOFIN,
                             NVL(PCEST.CUSTOREAL, 0) CUSTOREAL,
                             NVL(PCEST.CUSTOCONT, 0) CUSTOCONT,
                             NVL(PCEST.QTESTGER, 0) QTESTGER
                        FROM PCEST)

         LOOP
          /* Processo de atualização da PCAUXPRO */
          P_PC_ATUALIZAPCAUXPRO(DADOS.CODPROD,
                                VANO,
                                VMES,
                                DADOS.CODFILIAL,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                DADOS.VLESTOQUE,
                                DADOS.CUSTOFIN,
                                DADOS.CUSTOREAL,
                                DADOS.CUSTOCONT,
                                DADOS.QTESTGER,
                                0);

          VN_INDEX := VN_INDEX +1;
          IF (pCommit = 'S' AND VN_INDEX >= 1000) THEN
            COMMIT;
            VN_INDEX := 0;
          END IF;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20016,'Erro  -- Atualização do PCAUXPRO.'|| SQLERRM);
          PMENSAGEM := 'Erro:' || SQLERRM;
      END;
    END IF;
    /* Leitura no PCTABPR */
    BEGIN
      VN_INDEX := 0;
      FOR DADOS IN (SELECT PCTABPR.CODPROD,
                           NVL(PCTABPR.PVENDA1, 0) PVENDA1,
                           PCEST.CODFILIAL
                      FROM PCTABPR, PCEST
                     WHERE PCTABPR.CODPROD = PCEST.CODPROD
                       AND PCTABPR.NUMREGIAO = 1) LOOP
        /* Processo de atualização da PCAUXPRO */
        P_PC_ATUALIZAPCAUXPRO(DADOS.CODPROD,
                              VANO,
                              VMES,
                              DADOS.CODFILIAL,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              DADOS.PVENDA1);

        VN_INDEX := VN_INDEX +1;
        IF (pCommit = 'S' AND VN_INDEX >= 1000) THEN
          COMMIT;
          VN_INDEX := 0;
        END IF;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20016,'Erro  -- Atualização do PCAUXPRO.'|| SQLERRM);
        PMENSAGEM := 'Erro:' || SQLERRM;
    END;
    COMMIT;
    PMENSAGEM := 'Consolidação de Dados Históricos Concluída!';
  END; -- final da procedure

  PROCEDURE P_PC_ZERAMESPCCONSOLIDAMES (pMes      in VARCHAR2,
                                        pAno      in VARCHAR2,
                                        pMensagem OUT VARCHAR2) IS
    VSQL VARCHAR2(2000) := '';
    ------------------------------------------------------------------------------
    -- Author  : Rondinelli Fortalesa Borges
    -- Created : 12/04/2017
    -- Purpose : Criado para zerar os valores do mês para recálculo;
    ------------------------------------------------------------------------------
  BEGIN
    BEGIN
      VSQL := 'DELETE PCCONSOLIDAMES ' ||
              ' WHERE ANO = :pAno AND MES = :pMes ';

      EXECUTE IMMEDIATE VSQL
        USING PANO, PMES;

    EXCEPTION
      WHEN OTHERS THEN
        PMENSAGEM := 'Erro ao zerar lançamentos do mês ' || PMES ||
                     ' do ano ' || PANO || ' na PCCONSOLIDAMES' || SQLERRM;
    END;

  END; --final da procedure P_PC_ZERAMESPCCONSOLIDAMES
END ATUALIZACAO_MENSAL;
