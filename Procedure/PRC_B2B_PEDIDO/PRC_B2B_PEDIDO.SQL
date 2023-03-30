CREATE OR REPLACE PROCEDURE PRC_B2B_PEDIDO(P_NUMPEDWEB VARCHAR2, P_FILIAL VARCHAR2, P_INTEGRADORA NUMBER)
IS
   r_ped                pcpedctemp%rowtype;
   r_item               pcpeditemp%rowtype;
   v_codcli             pcclient.codcli%type;
   v_cgc                PCECOMMERCEB2BPCPEDC.Cpfcnpjconsumidor%type;
   v_erro               varchar2(400);
   v_codusur            pcusuari.codusur%type;
   r_param              PCECOMMERCEB2B%rowtype;
   v_count              number;
   v_count_bnf          number;
   v_bnfpedido          PCPARAMFILIAL.VALOR%type;
   v_seq                number;
   v_codprod            PCPRODUT.CODPROD%type;
   v_codauxiliar        PCPRODUT.codauxiliar%TYPE;   
   v_codauxiliar_conv        PCPRODUT.codauxiliar%TYPE;
   v_fator              number;
   v_tipoconversao      PCECOMMERCEB2BPRODUTO.TIPOCONVERSAO%TYPE;
   v_tipointegracao     PCECOMMERCEB2BPRODUTO.TIPOINTEGRACAO%TYPE;
   v_qtunit             PCPRODUT.QTUNIT%TYPE;
   v_LimiteCredito      number;
   v_PedidoBloqueado    pcconsum.AceitavENDabloq%type; 
   v_numped             pcpedc.numped%type;  
   v_Matricula          pcecommerceb2b.matricula%type;
   p_Mensagem           varchar2(500);
   p_Cancelado          varchar2(500);
   vUTILIZAPCUSURFORNEC varchar2(1);
   vCODCOBPEDIDOBONIFICADO varchar2(4);
   vCODCOBPLPAGBONIFICACAO number;
BEGIN
   -- LOOP pedidos
   FOR R IN (SELECT * 
             FROM PCECOMMERCEB2BPCPEDC 
             WHERE NUMPEDWEB = P_NUMPEDWEB
       AND CODFILIAL = P_FILIAL 
       AND INTEGRADORA = P_INTEGRADORA
       AND PROCESSADO = 'NAO') 
   LOOP
      -- VerIFica dados da configuração
      BEGIN
         SELECT *
         INTO r_param
         FROM PCECOMMERCEB2B
         WHERE CODFILIAL = R.CODFILIAL
           AND TIPOINTEGRACAO = R.INTEGRADORA;
      EXCEPTION WHEN OTHERS THEN
         v_erro := SUBSTR(sqlerrm,1,400);
         ROLLBACK;
         UPDATE PCECOMMERCEB2BPCPEDC P
         SET P.LOG = 'Erro ao localizar configuração para a filial '|| R.CODFILIAL,
             P.PROCESSADO = 'ERR'
         WHERE P.NUMPEDWEB = R.NUMPEDWEB
           AND P.CODFILIAL = R.CODFILIAL;
        
         COMMIT;
         RETURN;
      END;

      BEGIN
        -- Aplica regex no CPF/CNPJ
        SELECT TO_NUMBER(REGEXP_REPLACE(r.cpfcnpjconsumidor, '[^0-9]'))
        INTO v_cgc
        FROM DUAL;
        -- Localiza o cliente
        SELECT max(codcli)
        INTO v_codcli
        FROM (SELECT TO_NUMBER(REGEXP_REPLACE(c.cgcent, '[^0-9]')) CGC, c.codcli
              FROM PCCLIENT c
              WHERE DTEXCLUSAO IS NULL
              AND c.TIPOFJ = 'J') cliente
        WHERE cgc = v_cgc;
      EXCEPTION WHEN OTHERS THEN
         v_erro := SUBSTR(sqlerrm,1,400);
         ROLLBACK;
         UPDATE PCECOMMERCEB2BPCPEDC p
         set p.log = 'Erro ao localizar cliente: '|| v_erro,
             p.processado = 'ERR'
         WHERE p.numpedweb = r.numpedweb
           AND p.codfilial = r.codfilial;
        
         COMMIT;
         RETURN;
      END;
    
    IF NVL(v_codcli,0) <= 0 THEN
         ROLLBACK;
         UPDATE PCECOMMERCEB2BPCPEDC p
         set p.log = 'Não foi localizado o cliente ' || v_cgc,
             p.processado = 'ERR'
         WHERE p.numpedweb = r.numpedweb
           AND p.codfilial = r.codfilial;
          
         COMMIT;
         RETURN;
      END IF;
    
      -- Busca o RCA      
      v_codusur := IMPORTARVENDASCOMPLE.FUNC_BUSCAR_RCA_B2B_ECOMMERCE(v_codcli, r.codfilial, r.integradora);
      
      IF v_codusur = 0 THEN
         v_codusur := -1;
      END IF;
      
      IF v_codusur = -1 THEN
        IF r_param.produto_distrib = 'S' THEN
           v_codusur := -1;
           -- Valida CODUSUR1
           BEGIN
              SELECT u.codusur
              INTO v_codusur
              FROM pcusuari u, pcclient c
              WHERE u.coddistrib = r_param.coddistrib
                AND c.codusur1 = u.codusur
                AND c.codcli = v_codcli
                AND rownum <= 1;
           EXCEPTION WHEN OTHERS THEN
              v_codusur := -1;
           END;
           -- Valida CODUSUR2
           IF v_codusur = -1 THEN
              BEGIN
                 SELECT u.codusur
                 INTO v_codusur
                 FROM pcusuari u, pcclient c
                 WHERE u.coddistrib = r_param.coddistrib
                   AND c.codusur2 = u.codusur
                   AND c.codcli = v_codcli
                   AND rownum <= 1;
              EXCEPTION WHEN OTHERS THEN
                 v_codusur := -1;
              END;
           END IF;
           -- Valida CODUSUR3
           IF v_codusur = -1 THEN
              BEGIN
                 SELECT u.codusur
                 INTO v_codusur
                 FROM pcusuari u, pcclient c
                 WHERE u.coddistrib = r_param.coddistrib
                   AND c.codusur3 = u.codusur
                   AND c.codcli = v_codcli
                   AND rownum <= 1;
              EXCEPTION WHEN OTHERS THEN
                 v_codusur := -1;
              END;
           END IF;
           -- Valida PCUSURCLI
           IF v_codusur = -1 THEN
              BEGIN
                 SELECT u.codusur
                 INTO v_codusur
                 FROM pcusuari u, pcusurcli c
                 WHERE u.coddistrib = r_param.coddistrib
                   AND c.codusur = u.codusur
                   AND c.codcli = v_codcli
                   AND rownum <= 1;
              EXCEPTION WHEN OTHERS THEN
                 v_codusur := -1;
              END;
           END IF;
           -- Default
           IF v_codusur = -1 THEN
              v_codusur := r_param.codusur;
           END IF;
        ELSE
           v_codusur := -1;
           -- Verificar parâmetro 1131 da rotina 132 Utilizar restrição de fornecedores por RCA
           BEGIN
              SELECT NVL(VALOR,'N')
              INTO vUTILIZAPCUSURFORNEC
              FROM PCPARAMFILIAL P
              WHERE UPPER(TRIM(P.NOME)) = 'CON_UTILIZAPCUSURFORNEC'
                AND ROWNUM = 1;
           EXCEPTION WHEN OTHERS THEN
              vUTILIZAPCUSURFORNEC := 'N';
           END;
           --Se só irá verificar o fornecedor se o parâmetro 1131 estiver setado como "S" (Sim)
           IF vUTILIZAPCUSURFORNEC = 'S' THEN
              -- VerIFica RCA na PCUSURFORNEC com CODUSUR1
              BEGIN
                 SELECT NVL(F.CODUSUR,0)
                 INTO v_codusur
                 FROM PCPRODUT P, 
                      PCECOMMERCEB2BPCPEDI I, 
                      PCUSURFORNEC F, 
                      PCCLIENT C
                 WHERE I.NUMPEDWEB = R.NUMPEDWEB
                   AND DECODE(INSTR(I.CODAUXILIAR,'C'), 0, I.CODAUXILIAR, SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1)) = TO_CHAR(P.CODAUXILIAR)
                   AND F.CODFORNEC = P.CODFORNEC
                   AND C.CODUSUR1 = F.CODUSUR
                   AND C.CODCLI = v_codcli
                   AND ROWNUM <= 1;

                 IF NVL(v_codusur,0) <= 0 THEN
                    v_codusur := -1;
                 END IF;
              EXCEPTION WHEN OTHERS THEN
                 v_codusur := -1;
              END;
              -- VerIFica RCA na PCUSURFORNEC com CODUSUR2
              IF v_codusur = -1 THEN
                 BEGIN
                    SELECT NVL(F.CODUSUR,0)
                    INTO v_codusur
                    FROM PCPRODUT P, 
                         PCECOMMERCEB2BPCPEDI I, 
                         PCUSURFORNEC F, 
                         PCCLIENT C
                    WHERE I.NUMPEDWEB = R.NUMPEDWEB
                      AND DECODE(INSTR(I.CODAUXILIAR,'C'), 0, I.CODAUXILIAR, SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1)) = TO_CHAR(P.CODAUXILIAR)
                      AND F.CODFORNEC = P.CODFORNEC
                      AND C.CODUSUR2 = F.CODUSUR
                      AND C.CODCLI = v_codcli
                      AND ROWNUM <= 1;

                    IF NVL(v_codusur,0) <= 0 THEN
                       v_codusur := -1;
                    END IF;
                 EXCEPTION WHEN OTHERS THEN
                    v_codusur := -1;
                 END;   
              END IF;   
              -- VerIFica RCA na PCUSURFORNEC com CODUSUR3
              IF v_codusur = -1 THEN
                 BEGIN
                    SELECT NVL(F.CODUSUR,0)
                    INTO v_codusur
                    FROM PCPRODUT P, 
                         PCECOMMERCEB2BPCPEDI I, 
                         PCUSURFORNEC F, 
                         PCCLIENT C
                    WHERE I.NUMPEDWEB = R.NUMPEDWEB
                      AND DECODE(INSTR(I.CODAUXILIAR,'C'), 0, I.CODAUXILIAR, SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1)) = TO_CHAR(P.CODAUXILIAR)
                      AND F.CODFORNEC = P.CODFORNEC
                      AND C.CODUSUR3 = F.CODUSUR
                      AND C.CODCLI = v_codcli
                      AND ROWNUM <= 1;

                    IF NVL(v_codusur,0) <= 0 THEN
                       v_codusur := -1;
                    END IF;
                 EXCEPTION WHEN OTHERS THEN
                    v_codusur := -1;
                 END;   
              END IF;

              IF v_codusur = -1 THEN
                 BEGIN
                    SELECT NVL(F.CODUSUR,0)
                    INTO v_codusur
                    FROM PCPRODUT P, 
                         PCECOMMERCEB2BPCPEDI I, 
                         PCUSURFORNEC F, 
                         PCUSURCLI C
                    WHERE I.NUMPEDWEB = R.NUMPEDWEB
                      AND DECODE(INSTR(I.CODAUXILIAR,'C'), 0, I.CODAUXILIAR, SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1)) = TO_CHAR(P.CODAUXILIAR)
                      AND F.CODFORNEC = P.CODFORNEC
                      AND C.CODUSUR = F.CODUSUR
                      AND C.CODCLI = v_codcli
                      AND ROWNUM <= 1;

                    IF NVL(v_codusur,0) <= 0 THEN
                       v_codusur := -1;
                    END IF;
                 EXCEPTION WHEN OTHERS THEN
                    v_codusur := -1;
                END;    
              END IF;
           END IF;
           -- VerIFica RCA ECOMMERCE PCCLIENT
           IF v_codusur = -1 THEN
              BEGIN
                 SELECT NVL(c.codusurecommerce,0)
                 INTO v_codusur
                 FROM pcclient c
                 WHERE c.codcli = v_codcli
                   AND rownum <= 1;
                 -- VerIFica se foi inFORmado
                 IF NVL(v_codusur,0) <= 0 THEN
                    v_codusur := -1;
                 END IF;
              EXCEPTION WHEN OTHERS THEN
                 v_codusur := -1;
              END;    
           END IF;    
           -- VerIFica RCA CODUSUR1 PCCLIENT  
           IF v_codusur = -1 THEN
              BEGIN
                 SELECT NVL(c.codusur1,0)
                 INTO v_codusur
                 FROM pcclient c
                 WHERE c.codcli = v_codcli
                   AND rownum <= 1;
                 -- VerIFica se foi inFORmado
                 IF NVL(v_codusur,0) <= 0 THEN
                    v_codusur := -1;
                 END IF;
              EXCEPTION WHEN OTHERS THEN
                 v_codusur := -1;
              END;    
           END IF;
           -- Default
           IF v_codusur = -1 THEN
              v_codusur := r_param.codusur;
           END IF;  
        END IF;
      END IF;

      IF NVL(v_codusur,0) <= 0 THEN
         ROLLBACK;
         UPDATE PCECOMMERCEB2BPCPEDC p
         set p.log = 'Nenhum RCA encontrado para o pedido.',
             p.processado = 'ERR'
         WHERE p.numpedweb = r.numpedweb
           AND p.codfilial = r.codfilial;
          
         COMMIT;
         RETURN;
      END IF;
      -- Quantidade de itens
      SELECT COUNT(1)
      INTO v_count
      FROM PCECOMMERCEB2BPCPEDI
      WHERE NUMPEDWEB = R.NUMPEDWEB;
      -- Quantidade de itens bonIFicados
      SELECT COUNT(1)
      INTO v_count_bnf
      FROM PCECOMMERCEB2BPCPEDI
      WHERE NUMPEDWEB = R.NUMPEDWEB
        AND BONIFIC = 'FFR';

      r_ped := null;
      r_ped.numpedcli := r.numpedweb;
      r_ped.numpedrca := r.numpedweb;
      r_ped.numpedweb := r.numpedweb;
      r_ped.tipointegracao := 'W';
      r_ped.integradora := r.integradora;
      r_ped.data := r.data;
      r_ped.codcli := v_codcli;
      r_ped.codusur := v_codusur;
      r_ped.codfilial := r.codfilial;
      r_ped.codfilialnf := r.codfilial;
      r_ped.importado := 'N';
      r_ped.dtinclusao := sysdate;
      -- Se todos os itens FORem bonIFicados, tipo de vENDa é 5
      IF v_count = v_count_bnf THEN
         r_ped.condvENDa := 5;
      ELSE
         r_ped.condvENDa := 1;
      END IF;

      r_ped.origemped := 'W';
      r_ped.numitens := v_count;
      -- Processa CODCOB e PLPAG
      IF r.tipopagamento = 'BILL' THEN
         r_ped.codcob := r_param.codcob_avista;
         r_ped.codplpag := r_param.codplpag_avista;
      ELSIF r.tipopagamento = 'COUPON' THEN
         r_ped.codcob := r_param.codcob_troca;
         r_ped.codplpag := r_param.codplpag_troca;
      ELSIF r.tipopagamento = 'CREDIT_CARD' THEN
         r_ped.codcob := r_param.codcob_cartao;
         r_ped.codplpag := r_param.codplpag_cartao;
      ELSIF r.tipopagamento = 'CRL-7' THEN
         r_ped.codcob := r_param.codcob_07dias;
         r_ped.codplpag := r_param.codplpag_07dias;
      ELSIF r.tipopagamento = 'CRL-14' THEN
         r_ped.codcob := r_param.codcob_14dias;
         r_ped.codplpag := r_param.codplpag_14dias;
      ELSIF r.tipopagamento = 'CRL-21' THEN
         r_ped.codcob := r_param.codcob_21dias;
         r_ped.codplpag := r_param.codplpag_21dias;
      ELSIF r.tipopagamento = 'CRL-28' THEN
         r_ped.codcob := r_param.codcob_28dias;
         r_ped.codplpag := r_param.codplpag_28dias;
      ELSE
         ROLLBACK;
         UPDATE PCECOMMERCEB2BPCPEDC p
         set p.log = 'Tipo de pagamento inválido',
             p.processado = 'ERR'
         WHERE p.numpedweb = r.numpedweb
           AND p.codfilial = r.codfilial;
        
         COMMIT;
         RETURN;
      END IF;
    
    IF r_ped.condvENDa = 5 THEN
    
        BEGIN
          SELECT CODCOB_BONIFICACAO
          INTO vCODCOBPEDIDOBONIFICADO
          FROM PCECOMMERCEB2B B
          WHERE B.TIPOINTEGRACAO = R.INTEGRADORA AND CODFILIAL = R.CODFILIAL;
      
      r_ped.codcob := vCODCOBPEDIDOBONIFICADO;
      
        EXCEPTION WHEN OTHERS THEN
          ROLLBACK;
          UPDATE PCECOMMERCEB2BPCPEDC p
          set p.log = 'Código cobrança não encontrado para pedido bonificado',
             p.processado = 'ERR'
          WHERE p.numpedweb = r.numpedweb
            AND p.codfilial = r.codfilial;
        
          COMMIT;
          RETURN;
        END;
    
        BEGIN
          SELECT CODPLPAG_BONIFICACAO
          INTO vCODCOBPLPAGBONIFICACAO
          FROM PCECOMMERCEB2B B
          WHERE B.TIPOINTEGRACAO = R.INTEGRADORA AND CODFILIAL = R.CODFILIAL;
      
      r_ped.codplpag := vCODCOBPLPAGBONIFICACAO;
      
        EXCEPTION WHEN OTHERS THEN
          ROLLBACK;
          UPDATE PCECOMMERCEB2BPCPEDC p
          set p.log = 'Código plano pagamento não encontrado para pedido bonificado',
             p.processado = 'ERR'
          WHERE p.numpedweb = r.numpedweb
            AND p.codfilial = r.codfilial;
        
          COMMIT;
          RETURN;
        END;    
        
    END IF;

      -- Insere o cabeçalho do pedido
      INSERT INTO pcpedctemp VALUES r_ped;
      -- Campos default dos itens
      r_item := null;
      r_item.tipointegracao := 'W';
      r_item.numpedcli := r.numpedweb;
      r_item.numpedrca := r.numpedweb;
      r_item.numpedweb := r.numpedweb;
      r_item.data := r.data;
      r_item.codcli := v_codcli;
      r_item.codusur := v_codusur;
      r_item.codfilialretira := r.codfilial;
      r_item.integradora := r.integradora;
      r_item.codplpag := r_ped.codplpag;
      v_seq := 1;
      r_item.dtinclusao := sysdate;

      /**** ITENS ****/
      FOR I IN (SELECT * 
                FROM PCECOMMERCEB2BPCPEDI 
                WHERE NUMPEDWEB = R.NUMPEDWEB) 
      LOOP
         BEGIN
            v_codauxiliar := TO_NUMBER(I.CODAUXILIAR);
            v_fator := 1;
         EXCEPTION WHEN OTHERS THEN
            SELECT SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1) CODAUXILIAR,
                   TO_NUMBER(SUBSTR(I.CODAUXILIAR, INSTR(I.CODAUXILIAR,'C')+1)) FATOR
            INTO v_codauxiliar, 
                 v_fator
            FROM dual;
         END;
         --Veficiar se o item esta cadastrado na tabela PCECOMMERCEB2BPRODUTO como alienacao
         BEGIN
            SELECT b2bproduto.tipoconversao,
                   b2bproduto.codprod,
                   b2bproduto.tipointegracao,
                   1 qtunit
            INTO v_tipoconversao, 
                 v_codprod, 
                 v_tipointegracao, 
                 v_qtunit
            FROM pcecommerceb2bproduto b2bproduto
            WHERE b2bproduto.codauxiliar = v_codauxiliar
              AND b2bproduto.tipointegracao = r.integradora
              AND b2bproduto.tipoconversao = 'AL'
              AND b2bproduto.codfilial = r.codfilial;
         EXCEPTION WHEN NO_DATA_FOUND THEN
            v_codprod := -1;
            v_tipoconversao := 'UN';
         END;

         IF v_tipoconversao <> 'AL' THEN
            BEGIN
               -- Localiza o produto
               SELECT codprod, tipointegracaob2b, decode(nvl(qtunit,0),0,1,qtunit)
               INTO v_codprod, v_tipointegracao, v_qtunit
               FROM pcprodut
               WHERE codauxiliar = v_codauxiliar;
            EXCEPTION WHEN OTHERS THEN
               ROLLBACK;
               UPDATE PCECOMMERCEB2BPCPEDC p
               set p.log = 'Não foi possível localizar produto para o SKU ' || i.codauxiliar || ' do pedido ' || r.numpedweb,
                   p.processado = 'ERR'
               WHERE p.numpedweb = r.numpedweb
                 AND p.codfilial = r.codfilial;
               
               COMMIT;
               RETURN;
            END;
      
            --Verifica tipo conversão
            BEGIN
               SELECT 
                 b2bproduto.tipointegracao, 
                 b2bproduto.tipoconversao, 
                 b2bproduto.codauxiliar
               INTO 
                 v_tipointegracao, 
                 v_tipoconversao, 
                 v_codauxiliar_conv
               FROM 
                 pcecommerceb2bproduto b2bproduto
               WHERE b2bproduto.codprod = v_codprod
                 AND b2bproduto.tipointegracao = r.integradora
                 AND b2bproduto.fatorconversao = v_fator
                 AND b2bproduto.codfilial = r.codfilial
                 AND rownum = 1;
            EXCEPTION WHEN OTHERS THEN
               ROLLBACK;
               UPDATE PCECOMMERCEB2BPCPEDC p
               set p.log = 'Não foi possível localizar produto na tabela de alienação de produto para este tipo de integração, SKU ' || i.codauxiliar || ' do pedido ' || r.numpedweb,
                   p.processado = 'ERR'
               WHERE p.numpedweb = r.numpedweb
                 AND p.codfilial = r.codfilial;
               
               COMMIT;
               RETURN;
            END;
         END IF;

         IF v_tipoconversao =  'EM' THEN
           r_item.codauxiliar := v_codauxiliar_conv;
           r_item.QTUNITEMB := v_fator;
         ELSE 
           r_item.codauxiliar := v_codauxiliar;
         END IF;

         r_item.codprod := v_codprod;
         
         IF (v_tipoconversao = 'AL') THEN
            r_item.qt := i.qt * v_fator;
         ELSE
            r_item.qt := i.qt * (v_fator / v_qtunit);
         END IF;
         -- VerIFica se o item é bonIFicado e trata conFORme
         IF i.bonIFic = 'FFR' THEN
            r_item.bonIFic := 'F';

            IF ( v_tipoconversao = 'AL' ) THEN
               r_item.pvENDa := i.ptabela / v_fator;
            ELSE
               r_item.pvENDa := i.ptabela * ( v_qtunit / v_fator );
            END IF;

            r_item.pvENDa := ROUND(r_item.pvENDa,2);
         ELSE
            r_item.bonIFic := NULL;

          IF (v_tipoconversao = 'AL') THEN
             r_item.pvENDa := i.pvENDa / v_fator;
          ELSE
             r_item.pvENDa := i.pvENDa * (v_qtunit / v_fator);
          END IF;

          r_item.pvENDa := ROUND(r_item.pvENDa,2);
         END IF;

         IF (v_tipoconversao = 'AL') THEN
            r_item.ptabela := i.ptabela / v_fator;
         ELSE
            r_item.ptabela := i.ptabela * (v_qtunit / v_fator);
         END IF;

         r_item.ptabela := ROUND(r_item.ptabela,2);
         r_item.numseq := v_seq;
         v_seq := v_seq + 1;
         -- Insere o item
         INSERT INTO pcpeditemp VALUES r_item;
      END LOOP;
       -- Se tiver itens bonIFicados junto a itens normais
      IF v_count_bnf > 0 AND v_count != v_count_bnf THEN
         -- VerIFica se permite bonIFicação no mesmo pedido que o TV1
        SELECT valor
        INTO v_bnfpedido
        FROM pcparamfilial
        WHERE nome = 'PERMITEITEMBNFTV1'
          AND codfilial in ('1','99')
          AND rownum <= 1;
      
        -- Duplica o cabeçalho, mas com o condvENDa 5
        IF v_bnfpedido != 'S' THEN
     
          BEGIN
            SELECT CODCOB_BONIFICACAO
            INTO vCODCOBPEDIDOBONIFICADO
            FROM PCECOMMERCEB2B B
            WHERE B.TIPOINTEGRACAO = R.INTEGRADORA AND CODFILIAL = R.CODFILIAL;
      
        r_ped.codcob := vCODCOBPEDIDOBONIFICADO;
      
          EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
            UPDATE PCECOMMERCEB2BPCPEDC p
            set p.log = 'Código cobrança não encontrado para pedido bonificado',
              p.processado = 'ERR'
            WHERE p.numpedweb = r.numpedweb
              AND p.codfilial = r.codfilial;
        
            COMMIT;
            RETURN;
          END;
    
          BEGIN
            SELECT CODPLPAG_BONIFICACAO
            INTO vCODCOBPLPAGBONIFICACAO
            FROM PCECOMMERCEB2B B
            WHERE B.TIPOINTEGRACAO = R.INTEGRADORA AND CODFILIAL = R.CODFILIAL;
      
        r_ped.codplpag := vCODCOBPLPAGBONIFICACAO;
      
          EXCEPTION WHEN OTHERS THEN
            ROLLBACK;
            UPDATE PCECOMMERCEB2BPCPEDC p
            set p.log = 'Código plano pagamento não encontrado para pedido bonificado',
              p.processado = 'ERR'
            WHERE p.numpedweb = r.numpedweb
              AND p.codfilial = r.codfilial;
        
            COMMIT;
            RETURN;
          END;
    
          r_ped.condvENDa := 5;
          INSERT INTO pcpedctemp VALUES r_ped;
        END IF;
      END IF;

      COMMIT;
      -- Executa a importação do pedido
      IMPORTARVENDASCOMPLE.IMPORTAR_PEDIDO_WEB(r_ped.numpedweb,
                                               r_ped.integradora,
                                               r_ped.codusur);
                         
      -- Verificar se foi inserido na pcpedctemp por mais que possa ocorrer algum erro 
    -- na IMPORTARVENDASCOMPLE.IMPORTAR_PEDIDO_WEB o cliente pode reimportar na 2696
      SELECT count(1)
      INTO v_count
      FROM pcpedctemp
      WHERE numpedweb = r_ped.numpedweb;

      IF v_count > 0 THEN
         UPDATE PCECOMMERCEB2BPCPEDC p
         set p.log = 'Pedido importado com sucesso!',
             p.processado = 'SIM'
         WHERE p.numpedweb = r.numpedweb
           AND p.codfilial = r.codfilial;
      END IF;

      COMMIT;      
      
      SELECT NUMPED 
      INTO v_numped
      FROM PCPEDC 
      WHERE NUMPEDWEB = R.NUMPEDWEB
        AND CODFILIAL = R.CODFILIAL;      

      IF NVL(v_numped,0) > 0 THEN
         SELECT FUNCOESVENDAS.BUSCARLIMCREDCLI(v_codcli , NULL, 'D', 'S'),
                (SELECT NVL(ACEITAVENDABLOQ,'N') FROM PCCONSUM)  
         INTO v_LimiteCredito,
              v_PedidoBloqueado
         FROM DUAL;
      
         SELECT MATRICULA INTO v_Matricula FROM PCECOMMERCEB2B B
         WHERE B.TIPOINTEGRACAO = R.INTEGRADORA AND CODFILIAL = R.CODFILIAL;

         IF (NOT (v_LimiteCredito >= R.VLTOTAL OR v_PedidoBloqueado = 'S') AND 
             R.TIPOPAGAMENTO IN ('CRL-7', 'CRL-14', 'CRL-21', 'CRL-28')) THEN
            PKG_CANCELA_PEDIDO.PRC_CANCELA(v_numped,
                                           v_Matricula,
                                           'Cliente sem limite de crédito',
                                           -1,
                                           p_mensagem,
                                           p_cancelado
                                          );
            IF p_cancelado = 'S' THEN  
               UPDATE PCPEDCTEMP SET OBSERVACAO_PC = 'Cliente sem limite de crédito - Pedido cancelado '
               WHERE NUMPEDWEB = R.NUMPEDWEB AND CODFILIAL = R.CODFILIAL;
            
               COMMIT ;
            END IF;
         END IF;
      END IF;
   END LOOP;
END PRC_B2B_PEDIDO;
