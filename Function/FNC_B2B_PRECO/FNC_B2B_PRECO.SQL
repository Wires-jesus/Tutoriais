CREATE OR REPLACE FUNCTION FNC_B2B_PRECO RETURN T_TABELA_PRECO AS
  vPRECOPOREMBALAGEM PCCONSUM.PRECOPOREMBALAGEM%type;
  vPreco             PCEMBALAGEM.PVENDA%type;
  vRet               T_TABELA_PRECO;
  vParams            PCECOMMERCEB2B%rowtype;
  vPrecoAvista       PCTABPR.PTABELA%type;
  vPrecoCartao       PCTABPR.PTABELA%type;
  vPreco7dias        PCTABPR.PTABELA%type;
  vPreco14dias       PCTABPR.PTABELA%type;
  vPreco21dias       PCTABPR.PTABELA%type;
  vPreco28dias       PCTABPR.PTABELA%type;
  vEan               VARCHAR2(20);
  vMultiplicador     NUMBER;
  vnVLRFECEP         NUMBER;
  vCODPLPAG          PCCLIENT.CODPLPAG%TYPE;
  vCODCLIFILIAL      PCCLIENT.CODCLI%TYPE;
  vUSATRIBUTACAOPORUF PCCONSUM.USATRIBUTACAOPORUF%TYPE;

BEGIN
  vRet := T_TABELA_PRECO();

  vPRECOPOREMBALAGEM := '';

  FOR R in (SELECT p.codprod, nvl(f.observacao,'zero') observacao, f.codfilial, f.rowid, p.tipointegracaob2b as tipointegracao, b.tipoconversao, b.fatorconversao, p.qtunit
              FROM pcprodut p, pcecommerceb2bfila f, pcecommerceb2bproduto b
             where p.rowid = f.id
               and p.codprod = b.codprod
               and f.codfilial = b.codfilial
               and f.tipointegracao = b.tipointegracao
               and f.tabela = 'PRECO'
               and p.tipointegracaob2b is not null)
  LOOP
    -- Fator de conversão
    SELECT FNC_B2B_CONVERSAO(r.codprod, r.codfilial, r.tipoconversao, r.fatorconversao)
    into vMultiplicador
    FROM dual;

    IF vPRECOPOREMBALAGEM = '' THEN
      -- PARAMETROS
      SELECT NVL(F.PRECOPOREMBALAGEM, C.PRECOPOREMBALAGEM)
            ,NVL(C.USATRIBUTACAOPORUF,'N')
            ,F.CODCLI
            ,CLI.CODPLPAG
        INTO vPRECOPOREMBALAGEM
            ,vUSATRIBUTACAOPORUF
            ,vCODCLIFILIAL
            ,vCODPLPAG
        FROM PCFILIAL F, PCCONSUM C, PCCLIENT CLI
       WHERE F.CODIGO = r.CODFILIAL
         AND F.CODCLI = CLI.CODCLI (+);
    END IF;

    -- REGRA PARA PREÇO POR EMBALAGEM
    IF vPRECOPOREMBALAGEM = 'S' THEN
      -- Caso observação venha nula
      IF R.OBSERVACAO != 'zero' THEN
        vPreco := 0;
      ELSE
        -- verifica se o EAN existe
        IF r.tipoconversao = 'AL' THEN
          BEGIN
            SELECT 
              e.PVENDA, 
              TO_CHAR(p.CODAUXILIAR)				
            INTO vPreco, vEan
            FROM PCEMBALAGEM e, PCECOMMERCEB2BPRODUTO p
            WHERE e.CODPROD = r.codprod
              AND e.CODFILIAL = r.CODFILIAL
              AND e.codprod = p.codprod
              AND e.codfilial = p.codfilial
              AND e.codauxiliar = p.codauxiliar
              AND p.tipoconversao = 'AL'
              AND p.tipointegracao = r.tipointegracao;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20000, 'EAN AL não encontrado!');
          END;
          					
        ELSE
        
          BEGIN
            SELECT 
              e.PVENDA, 
              TO_CHAR(e.CODAUXILIAR)
            INTO vPreco, vEan
            FROM PCEMBALAGEM e, PCECOMMERCEB2BPRODUTO p
            WHERE e.CODPROD = r.codprod
              AND e.CODFILIAL = r.CODFILIAL
              AND e.codprod = p.codprod
              AND e.codfilial = p.codfilial
              AND e.codauxiliar = p.codauxiliar
              AND p.tipointegracao = r.tipointegracao;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20000, 'EAN não encontrado!');
            END;
        END IF;			
		
        -- Aplica o fator
        vPreco := vPreco * vMULTIPLICADOR;
      END IF;
      -- Insere dados para retorno
      vRet.extEND; vRet(vRet.count) := t_preco(r.CODFILIAL,
                                               VEAN,
                                               vPreco,
                                               vPreco,
                                               vPreco,
                                               vPreco,
                                               vPreco,
                                               vPreco,
                                               r.rowid,
                         r.tipointegracao);
    -- REGRA PARA PREÇO POR REGIÃO
    ELSE
      -- verifica se o EAN existe
      IF r.tipoconversao = 'AL' THEN
        BEGIN
          SELECT CODAUXILIAR
          INTO vEan
          FROM PCECOMMERCEB2BPRODUTO
          WHERE CODPROD = r.codprod
            AND TIPOCONVERSAO = 'AL'
            AND TIPOINTEGRACAO = r.tipointegracao
            AND CODFILIAL = r.codfilial;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20000, 'EAN AL não encontrado!');
        END;	    
      ELSE
        BEGIN
          SELECT CODAUXILIAR
          INTO vEan
          FROM PCPRODUT
          WHERE CODPROD = r.codprod;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20000, 'EAN não encontrado!');
        END;	  
      END IF;
	  
      -- Recupera os parametros
      BEGIN
        SELECT *
        INTO vParams
        FROM PCECOMMERCEB2B
        WHERE CODFILIAL = R.CODFILIAL
          AND TIPOINTEGRACAO = R.TIPOINTEGRACAO;

        IF nvl(vParams.Numregiao,0) = 0 THEN
          RAISE_APPLICATION_ERROR(-20000, 'Região com parametrização inválida!');
        END IF;
      EXCEPTION WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000, 'Região com parametrização inválida!');
      END;

      -- Caso observação venha nula
      IF R.OBSERVACAO != 'zero' THEN
        vPrecoAvista := 0;
        vPrecoCartao := 0;
        vPreco7dias := 0;
        vPreco14dias := 0;
        vPreco21dias := 0;
        vPreco28dias := 0;
      ELSE
        -- Recupera os preços dinamicamente
        BEGIN
          -- Preco a vista
          EXECUTE IMMEDIATE
          'BEGIN SELECT pvenda' || vParams.Numtabela_Avista || ' into :1 FROM pctabpr where codprod = '
            || R.CODPROD || '  and numregiao = ' || vParams.Numregiao || '; END;'
          USING OUT vPrecoAvista;          

          -- Preco cartao
          EXECUTE IMMEDIATE
          'BEGIN SELECT pvenda' || vParams.Numtabela_Cartao || ' into :1 FROM pctabpr where codprod = '
            || R.CODPROD || '  and numregiao = ' || vParams.Numregiao || '; END;'
          USING OUT vPrecoCartao;          

          -- Preco 7 dias
          EXECUTE IMMEDIATE
          'BEGIN SELECT pvenda' || vParams.Numtabela_07dias || ' into :1 FROM pctabpr where codprod = '
            || R.CODPROD || '  and numregiao = ' || vParams.Numregiao || '; END;'
          USING OUT vPreco7dias;   

          -- Preco 14 dias
          EXECUTE IMMEDIATE
          'BEGIN SELECT pvenda' || vParams.Numtabela_14dias || ' into :1 FROM pctabpr where codprod = '
            || R.CODPROD || '  and numregiao = ' || vParams.Numregiao || '; END;'
          USING OUT vPreco14dias;           

          -- Preco 21 dias
          EXECUTE IMMEDIATE
          'BEGIN SELECT ptabela' || vParams.Numtabela_21dias || ' into :1 FROM pctabpr where codprod = '
            || R.CODPROD || '  and numregiao = ' || vParams.Numregiao || '; END;'
          USING OUT vPreco21dias;         

          -- Preco 28 dias
          EXECUTE IMMEDIATE
          'BEGIN SELECT pvenda' || vParams.Numtabela_28dias || ' into :1 FROM pctabpr where codprod = '
            || R.CODPROD || '  and numregiao = ' || vParams.Numregiao || '; END;'
          USING OUT vPreco28dias;
        exception when others THEN
            RAISE_APPLICATION_ERROR(-20000, 'Erro ao recuperar tabelas de preço por região!');
        END;
      END IF;

      -- Insere dados para retorno
      vRet.extend; vRet(vRet.count) := t_preco(r.CODFILIAL,
                                               CASE WHEN vMultiplicador>1 THEN 
                                                  to_char(VEAN) || 'C' || vMultiplicador 
                                               ELSE 
                                                  to_char(VEAN) 
                                               end,
                                               vPrecoAvista  * vMULTIPLICADOR/r.qtunit,
                                               vPrecoCartao * vMULTIPLICADOR/r.qtunit,
                                               vPreco7dias * vMULTIPLICADOR/r.qtunit,
                                               vPreco14dias * vMULTIPLICADOR/r.qtunit,
                                               vPreco21dias * vMULTIPLICADOR/r.qtunit,
                                               vPreco28dias * vMULTIPLICADOR/r.qtunit,
                                               r.rowid,
                                               r.tipointegracao);
    END IF;
  END LOOP;

  RETURN(vRet);
END FNC_B2B_PRECO;
