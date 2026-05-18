CREATE OR REPLACE PROCEDURE P_GERA_VINCULO_UE_PROD_ESTOQUE(PCODFILIAL IN VARCHAR2,
                                                           PDTINVENTARIO IN DATE,
                                                           PQTESTOQUE IN NUMBER,
                                                           PCODPROD   IN NUMBER,
                                                           PCODSEQVINCULO IN NUMBER,
                                                           PPROCESSARENTRADABONIFICADA IN VARCHAR2,
                                                           PCST_REGH020 IN VARCHAR2,
                                                           PSOMENTEENTRADASCOMST IN VARCHAR2,
                                                           MSG        OUT VARCHAR2) IS
   ------------------------------------------------------------------------
   -- Programa criado para manter um conta corrente das saidas com relação
   -- às entradas - UEPS
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
   V_SALDO_ENT      NUMBER;
   V_SALDO_SAI      NUMBER;
   V_SALDO_SAI_TEMP NUMBER;
   V_SALDO_SAI_TELA NUMBER;
   V_SALDO_ENTR_MAIOR_SAID VARCHAR2(1);
   V_QT_ENTRADA_USADA NUMBER;

   V_VL_ICMSSTRESTITUIR    NUMBER;
   V_VL_TOTAL_BASEICMS     NUMBER;
   V_VL_TOTAL_ICMS         NUMBER;
   V_VL_TOTAL_BASEST       NUMBER;
   V_VL_TOTAL_ST           NUMBER;
   V_VL_TOTAL_BASEICMSBCR  NUMBER;
   V_VL_TOTAL_ICMSBCR      NUMBER;
   V_VL_TOTAL_BASESTFORANF NUMBER;
   V_VL_TOTAL_STFORANF     NUMBER;
   V_VL_TOTAL_BASESTBCR    NUMBER;
   V_VL_TOTAL_STSTBCR      NUMBER;
   V_VL_TOTAL_PIS          NUMBER;
   V_VL_TOTAL_COFINS       NUMBER;
   V_VL_TOTAL_IPI          NUMBER;
   V_VL_TOTAL_PUNIT        NUMBER;
   V_VL_TOTAL_VLICMSRESTITUIR NUMBER;
   

   V_VL_MEDIA_BASEICMS     NUMBER;
   V_VL_MEDIA_ICMS         NUMBER;
   V_VL_MEDIA_BASEST       NUMBER;
   V_VL_MEDIA_ST           NUMBER;
   V_VL_MEDIA_PIS          NUMBER;
   V_VL_MEDIA_COFINS       NUMBER;
   V_VL_MEDIA_IPI          NUMBER;
   V_VL_MEDIA_PUNIT        NUMBER;      
   V_PERCALIQVIGINT        NUMBER;  

   -- Deleção de movimentação do produto, período e filial
   PROCEDURE DELETAR_DADOS IS
   BEGIN
   ------------------------------------------------------------------------
      -- Apaga os registros de entrada do período informado em diante
      DELETE FROM PCVINCULOENTPRODESTOQUE
      WHERE CODFILIAL = PCODFILIAL
        AND DTINVENTARIO = PDTINVENTARIO
        AND (NVL(PCODPROD,0) = 0 OR CODPROD = NVL(PCODPROD,0));
   END;
   ------------------------------------------------------------------------
   -- Insere registro de controle de entradas
   PROCEDURE INSERIR_TABELA_ENT(P_CODFILIAL       IN VARCHAR,
                                P_NUMTRANSENT     IN NUMBER,
                                P_NUMNOTA         IN NUMBER,
                                P_CODPROD         IN NUMBER,
                                P_DTINVENTARIO    IN DATE,
                                P_CODFORNEC       IN NUMBER,
                                P_FORNECEDOR      IN VARCHAR2,
                                P_UFFORNECEDOR    IN VARCHAR2,
                                P_DTENTRADA       IN DATE,
                                P_CFOP            IN NUMBER,
                                P_CSTICMS         IN NUMBER,
                                P_QT              IN NUMBER,
                                P_VLBASEICMS      IN NUMBER,
                                P_VLICMS          IN NUMBER,
                                P_VLBASEST        IN NUMBER,
                                P_VLST            IN NUMBER,
                                P_VLBASEICMSBCR   IN NUMBER,
                                P_VLICMSBCR       IN NUMBER,
                                P_VLBASESTFORANF  IN NUMBER,
                                P_VLSTFORANF      IN NUMBER,
                                P_VLBASESTBCR     IN NUMBER,
                                P_VLSTSTBCR       IN NUMBER,
                                P_VLPIS           IN NUMBER,
                                P_VLCOFINS        IN NUMBER,
                                P_VLIPI           IN NUMBER,
                                P_PUNIT           IN NUMBER,
                                P_VLICMSRESTITUIR IN NUMBER,
                                P_ORIGMERCTRIB    IN NUMBER) IS
   BEGIN
      INSERT INTO PCVINCULOENTPRODESTOQUE
         (CODSEQVINCULO,
          CODFILIAL,
          NUMTRANSENT,
          NUMNOTA,
          CODPROD,
          DTINVENTARIO,
          CODFORNEC,
          DESCRICAO_FORNECEDOR,
          UFFORNECEDOR,
          DTENTRADA,
          CFOP,
          CSTICMS,
          QT,
          VLBASEICMS,
          VLICMS,
          VLBASEST,
          VLST,
          VLBASEICMSBCR,
          VLICMSBCR,
          VLBASESTFORANF,
          VLSTFORANF,
          VLBASESTBCR,
          VLSTSTBCR,
          VLPIS,
          VLCOFINS,
          VLIPI,
          PUNITCONT,
          VLICMSRESTITUIR,
          ORIGMERCTRIB,
          CST_H020)
      VALUES
         (PCODSEQVINCULO,
          P_CODFILIAL,
          P_NUMTRANSENT,
          P_NUMNOTA,
          P_CODPROD,
          P_DTINVENTARIO,
          P_CODFORNEC,
          P_FORNECEDOR,
          P_UFFORNECEDOR,
          P_DTENTRADA,
          P_CFOP,
          P_CSTICMS,
          P_QT,
          P_VLBASEICMS,
          P_VLICMS,
          P_VLBASEST,
          P_VLST,
          P_VLBASEICMSBCR,
          P_VLICMSBCR,
          P_VLBASESTFORANF,
          P_VLSTFORANF,
          P_VLBASESTBCR,
          P_VLSTSTBCR,
          P_VLPIS,
          P_VLCOFINS,
          P_VLIPI,
          P_PUNIT,
          P_VLICMSRESTITUIR,
          P_ORIGMERCTRIB,
          PCST_REGH020);
   END;
   ------------------------------------------------------------------------
   -- Atualiza saldo de controle de entrada
   PROCEDURE ATUALIZAR_ENTRADA(P_NUMTRANSENT IN NUMBER,
                               P_CODPROD     IN NUMBER,
                               P_SALDO       IN NUMBER) AS
   BEGIN
      UPDATE PCUEPSSALDOENT SET SALDO = NVL(P_SALDO, QTCONT)
      WHERE NUMTRANSENT = P_NUMTRANSENT
        AND CODPROD = P_CODPROD;
   END;

   ------------------------------------------------------------------------
   -- Insere registro de controle de saída
   PROCEDURE ENTRADAS(P_DTINVENTARIO       IN DATE,
                      P_QESTOQUE       IN NUMBER,
                      P_CODPROD       IN NUMBER) IS
   BEGIN
   ------------------------------------------------------------------------
      V_QT_ENTRADA_USADA := 0;
      V_SALDO_SAI        := 0;
      V_SALDO_SAI_TEMP   := P_QESTOQUE;
      V_SALDO_ENT        := 0;
      V_SALDO_ENTR_MAIOR_SAID := 'S';
      V_SALDO_SAI_TELA := P_QESTOQUE;
      /*Totalizadores */
      V_VL_TOTAL_BASEICMS     := 0;
      V_VL_TOTAL_ICMS         := 0;
      V_VL_TOTAL_BASEST       := 0;
      V_VL_TOTAL_ST           := 0;
      V_VL_TOTAL_BASEICMSBCR  := 0;
      V_VL_TOTAL_ICMSBCR      := 0;
      V_VL_TOTAL_BASESTFORANF := 0;
      V_VL_TOTAL_STFORANF     := 0;
      V_VL_TOTAL_BASESTBCR    := 0;
      V_VL_TOTAL_STSTBCR      := 0;
      V_VL_TOTAL_PIS          := 0;
      V_VL_TOTAL_COFINS       := 0;
      V_VL_TOTAL_IPI          := 0;
      V_VL_TOTAL_PUNIT        := 0;

      /*Média*/
      V_VL_MEDIA_BASEICMS     := 0;
      V_VL_MEDIA_ICMS         := 0;
      V_VL_MEDIA_BASEST       := 0;
      V_VL_MEDIA_ST           := 0;

      V_VL_MEDIA_PIS          := 0;
      V_VL_MEDIA_COFINS       := 0;
      V_VL_MEDIA_IPI          := 0;
      V_VL_MEDIA_PUNIT        := 0;

      ------------------------------------------------------------------------
      FOR ENTRADAS IN (SELECT 'NF' TIPO,
                              NVL(E.CODFILIALNF,E.CODFILIAL) CODFILIAL,
                              E.NUMTRANSENT,
                              E.NUMNOTA,
                              M.CODPROD,
                              E.CODFORNEC,
                              E.FORNECEDOR,
                              E.UF,
                              E.DTENT,
                              M.CODFISCAL CFOP,
                              M.SITTRIBUT CSTICMS,
                              M.QTCONT,

                              NVL(M.BASEICMS,0) VLBASEICMS,
                              (FISCAL.GET_DADOS_ICMS(NVL(E.CODFILIALNF,E.CODFILIAL), 'E', E.ESPECIE, M.ROWID,'', E.CHAVENFE, 'N') / M.QTCONT) VLICMS,

                              NVL(M.BASEICST,0) VLBASEST,
                              NVL(M.ST,0) VLST,

                              NVL(M.BASEICMSBCR,0) VLBASEICMSBCR,
                              NVL(M.VLICMSBCR,0) VLICMSBCR,

                              NVL(M.VLBASESTFORANF,0) VLBASESTFORANF,
                              NVL(M.VLDESPADICIONAL,0) VLSTFORANF,

                              NVL(M.BASEBCR,0) VLBASESTBCR,
                              NVL(M.STBCR,0) VLSTSTBCR,

                              NVL(M.VLCREDPIS,0) VLPIS,
                              NVL(M.VLCREDCOFINS,0) VLCOFINS,
                              NVL(M.VLIPI,0) VLIPI,
                              M.PUNIT,
                              NVL(PFL.PERCALIQVIGINT,0) PERCALIQVIGINT,
                              CP.ORIGMERCTRIB 
                       FROM PCNFENT E,
                            PCMOV M,
                            PCMOVCOMPLE CP,
                            PCPRODFILIAL PFL
                       WHERE E.NUMTRANSENT = M.NUMTRANSENT
                         AND E.NUMNOTA = M.NUMNOTA
                         AND M.NUMTRANSITEM = CP.NUMTRANSITEM(+)
                         AND NVL(E.CODFILIALNF,E.CODFILIAL) = PCODFILIAL
                         AND M.CODPROD = P_CODPROD
                         AND P_CODPROD = PFL.CODPROD(+)
                         AND NVL(E.CODFILIALNF,E.CODFILIAL) = PFL.CODFILIAL(+)
                         AND E.ESPECIE = 'NF'
                         AND M.QTCONT > 0
                         AND M.STATUS IN ('A','AB')
                         AND E.TIPODESCARGA NOT IN ('F','P')
                         AND NVL(E.NFENTREGAFUTURA,'N') = 'N'
                         AND M.CODOPER IN ('E','ET', DECODE(PPROCESSARENTRADABONIFICADA,'S', 'EB')  )
                         AND M.DTCANCEL IS NULL
                         AND E.DTENT <= P_DTINVENTARIO
                         AND DECODE(PSOMENTEENTRADASCOMST,'S',(NVL(M.BASEICST,0) + NVL(M.VLBASESTFORANF,0) + NVL(M.BASEBCR,0)), 1   ) > 0

                       ORDER BY DTENT DESC, NUMTRANSENT DESC)
      LOOP
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
         V_PERCALIQVIGINT := ENTRADAS.PERCALIQVIGINT;
         
   
         --Criado para atualização do Saldo, apenas para quantidade de produto da nota
         --de entrada que comporta a quantidade do produto no estoque.
         IF (ENTRADAS.QTCONT >= V_SALDO_SAI_TELA AND V_SALDO_ENTR_MAIOR_SAID = 'S') THEN
            -- Para gerar apenas uma vez quando a quantidade de sáida for suficiente.
            V_SALDO_SAI := 0;

            V_QT_ENTRADA_USADA := (ENTRADAS.QTCONT - (ENTRADAS.QTCONT - V_SALDO_SAI_TELA));
            
           
            /*CALCULANDO A MÉDIA DO ICMS ST*/
            IF (ENTRADAS.VLBASEST > 0) AND
               (ENTRADAS.VLST > 0) THEN
              V_VL_ICMSSTRESTITUIR := (ENTRADAS.VLBASEST * (V_PERCALIQVIGINT / 100));
            ELSIF (ENTRADAS.VLBASESTFORANF > 0) AND
                  (ENTRADAS.VLSTFORANF > 0) THEN
              V_VL_ICMSSTRESTITUIR := (ENTRADAS.VLBASESTFORANF * (V_PERCALIQVIGINT / 100));
            ELSE
              V_VL_ICMSSTRESTITUIR := (ENTRADAS.VLBASESTBCR * (V_PERCALIQVIGINT / 100));
            END IF;                       
            
            ------------------------------------------------------------------------
            INSERIR_TABELA_ENT(ENTRADAS.CODFILIAL,
                               ENTRADAS.NUMTRANSENT,
                               ENTRADAS.NUMNOTA,
                               ENTRADAS.CODPROD,
                               P_DTINVENTARIO,
                               ENTRADAS.CODFORNEC,
                               ENTRADAS.FORNECEDOR,
                               ENTRADAS.UF,
                               ENTRADAS.DTENT,
                               ENTRADAS.CFOP,
                               ENTRADAS.CSTICMS,
                               V_QT_ENTRADA_USADA,
                               ENTRADAS.VLBASEICMS,
                               ENTRADAS.VLICMS,
                               ENTRADAS.VLBASEST,
                               ENTRADAS.VLST,
                               ENTRADAS.VLBASEICMSBCR,
                               ENTRADAS.VLICMSBCR,
                               ENTRADAS.VLBASESTFORANF,
                               ENTRADAS.VLSTFORANF,
                               ENTRADAS.VLBASESTBCR,
                               ENTRADAS.VLSTSTBCR,
                               ENTRADAS.VLPIS,
                               ENTRADAS.VLCOFINS,
                               ENTRADAS.VLIPI,
                               ENTRADAS.PUNIT,
                               V_VL_ICMSSTRESTITUIR,
                               ENTRADAS.ORIGMERCTRIB);

            ------------------------------------------------------------------------
            V_VL_TOTAL_BASEICMS     := V_VL_TOTAL_BASEICMS     + (ENTRADAS.VLBASEICMS * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_ICMS         := V_VL_TOTAL_ICMS         + (ENTRADAS.VLICMS * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_BASEST       := V_VL_TOTAL_BASEST       + (ENTRADAS.VLBASEST * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_ST           := V_VL_TOTAL_ST           + (ENTRADAS.VLST * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_BASEICMSBCR  := V_VL_TOTAL_BASEICMSBCR  + (ENTRADAS.VLBASEICMSBCR * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_ICMSBCR      := V_VL_TOTAL_ICMSBCR      + (ENTRADAS.VLICMSBCR * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_BASESTFORANF := V_VL_TOTAL_BASESTFORANF + (ENTRADAS.VLBASESTFORANF * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_STFORANF     := V_VL_TOTAL_STFORANF     + (ENTRADAS.VLSTFORANF * V_QT_ENTRADA_USADA);
	        IF (ENTRADAS.VLBASEST + ENTRADAS.VLBASESTFORANF) = 0 THEN
               V_VL_TOTAL_BASESTBCR    := V_VL_TOTAL_BASESTBCR    + (ENTRADAS.VLBASESTBCR * V_QT_ENTRADA_USADA);
		    END IF;	
	    	IF (ENTRADAS.VLST + ENTRADAS.VLSTFORANF) = 0 THEN
		       V_VL_TOTAL_STSTBCR      := V_VL_TOTAL_STSTBCR      + (ENTRADAS.VLSTSTBCR * V_QT_ENTRADA_USADA);
		    END IF;	
            V_VL_TOTAL_PIS          := V_VL_TOTAL_PIS          + (ENTRADAS.VLPIS * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_COFINS       := V_VL_TOTAL_COFINS       + (ENTRADAS.VLCOFINS * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_IPI          := V_VL_TOTAL_IPI          + (ENTRADAS.VLIPI * V_QT_ENTRADA_USADA);
            V_VL_TOTAL_PUNIT        := V_VL_TOTAL_PUNIT        + (ENTRADAS.PUNIT * V_QT_ENTRADA_USADA);         
            ------------------------------------------------------------------------
            /*Depois que encontra a quantidade suficiente, pode sair do laço*/
            EXIT;
            ------------------------------------------------------------------------
            --Criado para atualizar e inserir informações quendo a quantidade do produto na
            --entrada, não comporta a quantidade da saída.
            --Exemplo: Quantidade de produto da entrada 30 e quantidade de produto
            --         de saída 40 (Nesse caso tenho que encontrar as quantidades de entrada
            --         notas no período anterior ao que está sendo realidado no momento).
         ELSE
            V_SALDO_ENTR_MAIOR_SAID := 'N';

            IF V_SALDO_SAI_TEMP > ENTRADAS.QTCONT THEN
               V_SALDO_SAI := ENTRADAS.QTCONT;
               V_SALDO_ENT := 0;
            ELSE
               V_SALDO_SAI := V_SALDO_SAI_TEMP;
               V_SALDO_ENT := ENTRADAS.QTCONT - V_SALDO_SAI_TEMP;
            END IF;
         ------------------------------------------------------------------------
            V_SALDO_SAI_TEMP := V_SALDO_SAI_TEMP - ENTRADAS.QTCONT;

            IF V_SALDO_SAI_TEMP > 0 THEN
              V_QT_ENTRADA_USADA := ENTRADAS.QTCONT;
            ELSE
              V_QT_ENTRADA_USADA := (ENTRADAS.QTCONT + (V_SALDO_SAI_TEMP));
            END IF;
         ------------------------------------------------------------------------
         
            /*CALCULANDO A MÉDIA DO ICMS ST*/
            IF (ENTRADAS.VLBASEST > 0) AND
               (ENTRADAS.VLST > 0) THEN
              V_VL_ICMSSTRESTITUIR := (ENTRADAS.VLBASEST * (V_PERCALIQVIGINT / 100));
            ELSIF (ENTRADAS.VLBASESTFORANF > 0) AND
                  (ENTRADAS.VLSTFORANF > 0) THEN
              V_VL_ICMSSTRESTITUIR := (ENTRADAS.VLBASESTFORANF * (V_PERCALIQVIGINT / 100));
            ELSE
              V_VL_ICMSSTRESTITUIR := (ENTRADAS.VLBASESTBCR * (V_PERCALIQVIGINT / 100));
            END IF;                                         
                  
            INSERIR_TABELA_ENT(ENTRADAS.CODFILIAL,
                               ENTRADAS.NUMTRANSENT,
                               ENTRADAS.NUMNOTA,
                               ENTRADAS.CODPROD,
                               P_DTINVENTARIO,
                               ENTRADAS.CODFORNEC,
                               ENTRADAS.FORNECEDOR,
                               ENTRADAS.UF,
                               ENTRADAS.DTENT,
                               ENTRADAS.CFOP,
                               ENTRADAS.CSTICMS,
                               V_QT_ENTRADA_USADA,
                               ENTRADAS.VLBASEICMS,
                               ENTRADAS.VLICMS,
                               ENTRADAS.VLBASEST,
                               ENTRADAS.VLST,
                               ENTRADAS.VLBASEICMSBCR,
                               ENTRADAS.VLICMSBCR,
                               ENTRADAS.VLBASESTFORANF,
                               ENTRADAS.VLSTFORANF,
                               ENTRADAS.VLBASESTBCR,
                               ENTRADAS.VLSTSTBCR,
                               ENTRADAS.VLPIS,
                               ENTRADAS.VLCOFINS,
                               ENTRADAS.VLIPI,
                               ENTRADAS.PUNIT,
                               V_VL_ICMSSTRESTITUIR,
                               ENTRADAS.ORIGMERCTRIB);
         ------------------------------------------------------------------------
            IF V_SALDO_SAI_TEMP <= 0 THEN
               V_VL_TOTAL_BASEICMS     := V_VL_TOTAL_BASEICMS     + (ENTRADAS.VLBASEICMS * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_BASEICMSBCR  := V_VL_TOTAL_BASEICMSBCR  + (ENTRADAS.VLBASEICMSBCR * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_ICMS         := V_VL_TOTAL_ICMS         + (ENTRADAS.VLICMS * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_BASEST       := V_VL_TOTAL_BASEST       + (ENTRADAS.VLBASEST * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_ST           := V_VL_TOTAL_ST           + (ENTRADAS.VLST * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_ICMSBCR      := V_VL_TOTAL_ICMSBCR      + (ENTRADAS.VLICMSBCR * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_BASESTFORANF := V_VL_TOTAL_BASESTFORANF + (ENTRADAS.VLBASESTFORANF * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_STFORANF     := V_VL_TOTAL_STFORANF     + (ENTRADAS.VLSTFORANF * V_QT_ENTRADA_USADA);
	           IF (ENTRADAS.VLBASEST + ENTRADAS.VLBASESTFORANF) = 0 THEN
                 V_VL_TOTAL_BASESTBCR    := V_VL_TOTAL_BASESTBCR    + (ENTRADAS.VLBASESTBCR * V_QT_ENTRADA_USADA);
		       END IF;	
		       IF (ENTRADAS.VLST + ENTRADAS.VLSTFORANF) = 0 THEN
		         V_VL_TOTAL_STSTBCR      := V_VL_TOTAL_STSTBCR      + (ENTRADAS.VLSTSTBCR * V_QT_ENTRADA_USADA);
		       END IF;	
               V_VL_TOTAL_PIS          := V_VL_TOTAL_PIS          + (ENTRADAS.VLPIS * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_COFINS       := V_VL_TOTAL_COFINS       + (ENTRADAS.VLCOFINS * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_IPI          := V_VL_TOTAL_IPI          + (ENTRADAS.VLIPI * V_QT_ENTRADA_USADA);
               V_VL_TOTAL_PUNIT        := V_VL_TOTAL_PUNIT        + (ENTRADAS.PUNIT * V_QT_ENTRADA_USADA);               

               EXIT;

            END IF;
         END IF;

      ------------------------------------------------------------------------
        V_VL_TOTAL_BASEICMS     := V_VL_TOTAL_BASEICMS     + (ENTRADAS.VLBASEICMS * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_ICMS         := V_VL_TOTAL_ICMS         + (ENTRADAS.VLICMS * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_BASEST       := V_VL_TOTAL_BASEST       + (ENTRADAS.VLBASEST * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_ST           := V_VL_TOTAL_ST           + (ENTRADAS.VLST * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_BASEICMSBCR  := V_VL_TOTAL_BASEICMSBCR  + (ENTRADAS.VLBASEICMSBCR * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_ICMSBCR      := V_VL_TOTAL_ICMSBCR      + (ENTRADAS.VLICMSBCR * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_BASESTFORANF := V_VL_TOTAL_BASESTFORANF + (ENTRADAS.VLBASESTFORANF * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_STFORANF     := V_VL_TOTAL_STFORANF     + (ENTRADAS.VLSTFORANF * V_QT_ENTRADA_USADA);
		IF (ENTRADAS.VLBASEST + ENTRADAS.VLBASESTFORANF) = 0 THEN
          V_VL_TOTAL_BASESTBCR    := V_VL_TOTAL_BASESTBCR    + (ENTRADAS.VLBASESTBCR * V_QT_ENTRADA_USADA);
		END IF;	
				
		IF (ENTRADAS.VLST + ENTRADAS.VLSTFORANF) = 0 THEN
		  V_VL_TOTAL_STSTBCR      := V_VL_TOTAL_STSTBCR      + (ENTRADAS.VLSTSTBCR * V_QT_ENTRADA_USADA);
		END IF;	        
        V_VL_TOTAL_PIS          := V_VL_TOTAL_PIS          + (ENTRADAS.VLPIS * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_COFINS       := V_VL_TOTAL_COFINS       + (ENTRADAS.VLCOFINS * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_IPI          := V_VL_TOTAL_IPI          + (ENTRADAS.VLIPI * V_QT_ENTRADA_USADA);
        V_VL_TOTAL_PUNIT        := V_VL_TOTAL_PUNIT        + (ENTRADAS.PUNIT * V_QT_ENTRADA_USADA);        

      END LOOP;

      -----------------------------------------------------------------------------------------------------
      /*CALCULANDO A MÉDIA DO ICMS*/
      IF (V_VL_TOTAL_BASEICMS = 0) AND
         (V_VL_TOTAL_ICMS = 0) THEN
        V_VL_MEDIA_BASEICMS := (V_VL_TOTAL_BASEICMSBCR / PQTESTOQUE);
        V_VL_MEDIA_ICMS     := (V_VL_TOTAL_ICMSBCR / PQTESTOQUE);
      ELSE
        V_VL_MEDIA_BASEICMS := (V_VL_TOTAL_BASEICMS / PQTESTOQUE);
        V_VL_MEDIA_ICMS     := (V_VL_TOTAL_ICMS / PQTESTOQUE);
      END IF;
      -----------------------------------------------------------------------------------------------------
      /*CALCULANDO A MÉDIA DO ICMS ST*/		
	  IF (V_VL_TOTAL_BASEST + V_VL_TOTAL_BASESTFORANF + V_VL_TOTAL_BASESTBCR) > 0 THEN
		 V_VL_MEDIA_BASEST := ((V_VL_TOTAL_BASEST + V_VL_TOTAL_BASESTFORANF + V_VL_TOTAL_BASESTBCR) / PQTESTOQUE);
	  END IF; 
			
	  IF (V_VL_TOTAL_ST + V_VL_TOTAL_STFORANF + V_VL_TOTAL_STSTBCR) > 0 THEN
		 V_VL_MEDIA_ST     := ((V_VL_TOTAL_ST + V_VL_TOTAL_STFORANF + V_VL_TOTAL_STSTBCR)  / PQTESTOQUE);
	  END IF;		

      V_VL_MEDIA_PIS          := (V_VL_TOTAL_PIS     / PQTESTOQUE);
      V_VL_MEDIA_COFINS       := (V_VL_TOTAL_COFINS  / PQTESTOQUE);
      V_VL_MEDIA_IPI          := (V_VL_TOTAL_IPI     / PQTESTOQUE);

      V_VL_MEDIA_PUNIT        := (V_VL_TOTAL_PUNIT    / PQTESTOQUE);
      V_VL_TOTAL_VLICMSRESTITUIR := (V_VL_MEDIA_BASEST * (V_PERCALIQVIGINT / 100));

      -----------------------------------------------------------------------------------------------------
      UPDATE PCCAPAVINCULOENTPRODESTOQUE SET VLTOTALBASEICMS     = V_VL_TOTAL_BASEICMS,
                                             VLTOTALICMS         = V_VL_TOTAL_ICMS,
                                             VLTOTALBASEST       = V_VL_TOTAL_BASEST,
                                             VLTOTALST           = V_VL_TOTAL_ST,
                                             VLTOTALBASEICMSBCR  = V_VL_TOTAL_BASEICMSBCR,
                                             VLTOTALICMSBCR      = V_VL_TOTAL_ICMSBCR,
                                             VLTOTALBASESTFORANF = V_VL_TOTAL_BASESTFORANF,
                                             VLTOTALSTFORANF     = V_VL_TOTAL_STFORANF,
                                             VLTOTALBASESTBCR    = V_VL_TOTAL_BASESTBCR,
                                             VLTOTALSTSTBCR      = V_VL_TOTAL_STSTBCR,
                                             VLTOTALICMSRESTITUIR= V_VL_TOTAL_VLICMSRESTITUIR,
                                             --Valores valor da média
                                             VLMEDIABASEICMS     = V_VL_MEDIA_BASEICMS,
                                             VLMEDIAICMS         = V_VL_MEDIA_ICMS,
                                             VLCOFINS            = V_VL_MEDIA_COFINS,
                                             VLMEDIABASEST       = V_VL_MEDIA_BASEST,
                                             VLMEDIAST           = V_VL_MEDIA_ST,
                                             VLPIS               = V_VL_MEDIA_PIS,
                                             VLIPI               = V_VL_MEDIA_IPI,
                                             VLMEDIAPUNIT        = V_VL_MEDIA_PUNIT
       WHERE CODFILIAL    = PCODFILIAL
         AND DTINVENTARIO = PDTINVENTARIO
         AND CODPROD      = PCODPROD;
   END;
   ------------------------------------------------------------------------
BEGIN
   ------------------------------------------------------------------------      
   DELETAR_DADOS;
   ------------------------------------------------------------------------
   ENTRADAS(PDTINVENTARIO, PQTESTOQUE, PCODPROD);
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
   MSG := 'OK';
   COMMIT;
   ------------------------------------------------------------------------
   /************************ FIM CORPO DA PROCEDURE **********************/
   EXCEPTION
   WHEN OTHERS THEN
   BEGIN
      ROLLBACK;
      MSG := 'ERRO AO GERAR UEPS CONTA CORRENTE: ' || CHR(13) ||
             sqlcode || ' ' || sqlerrm;
   END;
END;   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
