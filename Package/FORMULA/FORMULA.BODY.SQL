CREATE OR REPLACE PACKAGE BODY FORMULA IS

  PROCEDURE settarNLS IS
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
  END;
  
  function IsCodFormula(pFormula in clob) return boolean is
  begin
    return not (instr(pFormula, '[') > 0 or instr(pFormula, '#') > 0);
  end; 

  FUNCTION BuscaFormula(pCodFormula in Varchar2) Return clob IS
    vFormula clob;
  BEGIN

    SELECT '(' || F.FORMULA || ')'
      INTO vFormula
      FROM PCFORMULA F
     WHERE F.CODFORMULA = pCodFormula;

    Return vFormula;
  END;

  FUNCTION BuscaVariavel(pVariavel in Varchar2, pCodFormula in VarChar2) Return Varchar2 IS
     vsVariavel Varchar2(50);
  BEGIN
    SELECT V.VALORDEFAULT
      INTO vsVariavel
      FROM PCVARIAVEL V INNER JOIN PCFORMULA F
                                ON F.CODTIPOFORMULA = V.CODTIPOFORMULA
     WHERE V.Tabela || '.' || V.Campo =  pVariavel
       AND F.CODFORMULA = pCodFormula;

    Return vsVariavel;
  END;

  -- Ricardo -> Criado metodo padrão para substituição de variáveis
  function ReplaceAllVariaveis(pFormula in clob,
                     rVariavel in rVariavel) RETURN clob IS
  begin
    return replace(pformula, rVariavel.Nome, rVariavel.Valor);
  end;

  Function SubstituiVariaveis(pFormula     in clob,
                              pVariaveis   in tbVariaveis,
                              pIdentificar out rVariavel) RETURN VARCHAR2 IS
    vsFormula     clob := pFormula;
    i             number;
    vbIdentificar boolean := false;
    vsmsgerro varchar2(4000);
  BEGIN
    -- Varre a fórmula substituindo variáveis por valores conhecidos
    -- Caso alguma não seja informada, assume-se que devemos identificar o seu valor
    vsmsgerro := '';
    i         := 0;
    LOOP
      EXIT WHEN i > pVariaveis.last;

      IF pVariaveis(i).Valor IS NULL THEN
        IF NOT(vbIdentificar) THEN
          pIdentificar.Nome := pVariaveis(i).Nome;
          vbIdentificar := true;
        ELSE
          vsmsgerro := vsmsgerro||'Nome: '|| pVariaveis(i).Nome||' Valor: '||pVariaveis(i).Valor;
        END IF;
      ELSE
        -- Ricardo -> Passar a utilizar o novo método de substituição de variáveis
        vsFormula := ReplaceAllVariaveis(vsFormula, pVariaveis(i));
      END IF;
      i := i + 1;
    END LOOP;

    IF NOT(vbIdentificar) THEN
      Raise_Application_Error(-20002, 'Para CalcularReverso, você deve omitir uma variável!');
    END IF;

    if vsmsgerro <> '' then
      Raise_Application_Error(-20001, 'Para CalcularReverso, você pode omitir no máximo uma variável!'||CHR(13)||vsmsgerro );
    END IF;

    Return vsFormula;
  END;

  -- Ricardo -> Criado metodo para desdobramento de formulas e subformulas
  function DesdobrarFormula(pFormula in clob) return clob is
    vPosicaoInicial integer;
    vPosicaoFinal integer;
    vFormulaAtual clob;
    vCorpoFormula clob;
    vFormulaDesdobrada clob;
  begin
    -- Desdobra as formulas recursivamente
    vFormulaDesdobrada := pformula;
    vPosicaoInicial := instr(pformula, '#');

    if vPosicaoInicial > 0 then
     vPosicaoFinal := instr(pformula, '#', 1, 2);
     vFormulaAtual := substr(pformula, vPosicaoInicial + 1, vPosicaoFinal - vPosicaoInicial - 1);
     vCorpoFormula := BuscaFormula(vFormulaAtual);
     vFormulaDesdobrada := replace(pformula, '#'||vFormulaAtual||'#', vCorpoFormula);
     vFormulaDesdobrada := DesdobrarFormula(vFormulaDesdobrada);
    end if;
    return vFormulaDesdobrada;
  end;

  Function SubstituiVariaveis(pFormula     in clob,
                              pVariaveis   in tbVariaveis) RETURN clob IS
    vsFormula clob := pFormula;
    i         number;
    vsmsgerro varchar2(4000);
  BEGIN
    -- Varre a fórmula substituindo variáveis por valores conhecidos
    -- Caso alguma não seja informada, dispara-se uma exceção
    vsmsgerro := '';
    i         := 0;
    LOOP
      EXIT WHEN i > pVariaveis.last;

      IF pVariaveis(i).Valor IS NULL THEN
        vsmsgerro := vsmsgerro||'Nome: '|| pVariaveis(i).Nome||' Valor: '||pVariaveis(i).Valor;
      ELSE
        -- Ricardo -> Passar a utilizar o novo método de substituição de variáveis
        vsFormula := ReplaceAllVariaveis(vsFormula, pVariaveis(i));
      END IF;
      i := i + 1;
    END LOOP;

    if vsmsgerro <> '' then
      raise_application_error(-20000, 'O valor de (' || pVariaveis(i).Nome || ') não foi informado'||CHR(13)||vsmsgerro );
    END IF;

    Return vsFormula;
  END;

  Function SubstituiFormulas(pFormula in clob) RETURN clob IS
    vsFormula    clob := pFormula;
    --vrFormulaSub rVariavel;
    --i            number := 1;
  BEGIN
    
    if IsCodFormula(vsFormula) then
        vsFormula := '#' || vsFormula || '#';
    end if;
        
    return DesdobrarFormula(vsFormula);

    /* Ricardo -> comentado para utilizar apenas o desdobramento padrao

    IF G_SUBSTITUIR_FORMULA = FALSE THEN
      RETURN pFormula;
    END IF;
    -- Localiza e substitui as fórmula existentes em pFormula
    LOOP
      vrFormulaSub.Nome := REGEXP_SUBSTR(vsFormula,'[[:alpha:]]+[[:alnum:]_]+', 1, i);

      EXIT WHEN vrFormulaSub.Nome is NULL;
      BEGIN
        vrFormulaSub.Valor := BuscaFormula(vrFormulaSub.Nome);
        vsFormula          := ReplaceAllVariaveis(vsFormula, vrFormulaSub);
      EXCEPTION
        WHEN OTHERS THEN
          i := i+1;
      END;

    END LOOP;
    Return vsFormula;
    */
  END;


  -- Ricardo -> Criado metodo para buscar a primeira subformula
  function BuscarProximaFormula(pFormula in clob) return clob is
    vPosicaoInicial integer;
    vPosicaoFinal integer;
    vSubFormula varchar2(100);
  begin
    vSubFormula := null;
    vPosicaoInicial := instr(pformula, '#');
    if vPosicaoInicial > 0 then
     vPosicaoFinal := instr(pformula, '#', 1, 2);
     vSubFormula := substr(pformula, vPosicaoInicial + 1, vPosicaoFinal - vPosicaoInicial - 1);
    end if;
    return vSubFormula;
  end;
  Function SubstituiFormulas(pFormula in clob, vtbFormulasSubstituidas out tbVariaveis) RETURN clob IS
    vsFormula    clob := pFormula;
    vrFormulaSub rVariavel;
    i            number := 1;
    n            number := 0;
  BEGIN
    /*IF G_SUBSTITUIR_FORMULA = FALSE THEN
      RETURN pFormula;
    END IF;*/
    -- Localiza e substitui as fórmula existentes em pFormula
    -- Retorna um tbVariaveis com a lista das formulas substituidas
    LOOP

      -- Ricardo -> utilizar o metodo abaixo para evitar o uso de Regex
      if IsCodFormula(vsFormula) then
        vsFormula := '#' || vsFormula || '#';
      end if;
      vrFormulaSub.Nome := BuscarProximaFormula(vsFormula);

      EXIT WHEN vrFormulaSub.Nome is NULL;
      BEGIN
        vrFormulaSub.Valor := BuscaFormula(vrFormulaSub.Nome);
        vrFormulaSub.Nome := '#' || vrFormulaSub.Nome || '#';
        vrFormulaSub.NomeFormula := vrFormulaSub.Nome ;
        -- Ricardo -> Passar a utilizar o novo método de substituição de variáveis
        vsFormula          := ReplaceAllVariaveis(vsFormula, vrFormulaSub);

        BEGIN
          SELECT T.DESCRICAO INTO vrFormulaSub.Nome
            FROM PCFORMULA F INNER JOIN PCFORMULATIPO T
                                     ON T.CODTIPOFORMULA = F.CODTIPOFORMULA
           WHERE F.CODFORMULA = replace(vrFormulaSub.Nome, '#', '');
        END;
        vtbFormulasSubstituidas(n).Nome  := vrFormulaSub.Nome;
        vtbFormulasSubstituidas(n).Valor := vrFormulaSub.Valor;
        vtbFormulasSubstituidas(n).NomeFormula := vrFormulaSub.NomeFormula;
        n := n + 1;

      EXCEPTION
        WHEN OTHERS THEN
          i := i+1;
      END;

    END LOOP;
    Return vsFormula;
  END;

  FUNCTION BuscaValor(ptbVariaveis in tbVariaveis,
                      pNome        in varchar2,
                      pNomeFormula out varchar2 ) RETURN Varchar2 IS
    i NUMBER := 0;
  BEGIN
    LOOP
     IF ptbVariaveis(i).Nome = pNome THEN
       pNomeFormula :=  ptbVariaveis(i).NomeFormula;
       Return ptbVariaveis(i).Valor;

     ELSIF i = ptbVariaveis.Last THEN
       Return '0';
     END IF;
     i := i + 1;
   END LOOP;
  END;

  FUNCTION BuscaValor(ptbVariaveis in tbVariaveis,
                      pNome        in varchar2) RETURN Varchar2 IS
    i varchar2(300);
  BEGIN
    return BuscaValor(ptbVariaveis ,
                      pNome        ,
                      i);
  END;

  PROCEDURE AtribuiValor(prVariaveis in rVariavel,
                         ptbVariaveis in out tbVariaveis) IS
    i NUMBER := 0;
    vsvalorTemp varchar2(4000);
  BEGIN
   LOOP

     begin
       vsvalorTemp := trim(to_char(prVariaveis.Valor,'999999990.00000000'));
     EXCEPTION
       WHEN OTHERS THEN
         vsvalorTemp := prVariaveis.Valor;
     end;

     IF ptbVariaveis(i).Nome = prVariaveis.Nome THEN
       ptbVariaveis(i).Valor := vsvalorTemp;
       EXIT;
     ELSIF i = ptbVariaveis.Last THEN
       ptbVariaveis(i+1).Nome := prVariaveis.Nome;
       ptbVariaveis(i+1).Valor := vsvalorTemp;
       EXIT;
     END IF;
     i := i + 1;
   END LOOP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ptbVariaveis(i).Nome := prVariaveis.Nome;
      ptbVariaveis(i).Valor := vsvalorTemp;
  END;

  FUNCTION TabelaVariaveis(pCodFormula in Varchar2) RETURN tbVariaveisConsulta PIPELINED IS
    vtbVariaveis tbVariaveis;
    vrVariavel   rVariavel;
    vtbFormulas  tbVariaveis;
    vsFormula    CLOB;
    i            number := 1;
    x            number;
  BEGIN

    BEGIN
      SELECT F.FORMULA INTO vsFormula
        FROM PCFORMULA F
       WHERE F.CODFORMULA = pCodFormula;
    Exception
      When No_Data_Found Then
        Raise_Application_Error(-20004, 'Fórmula não localizada'||CHR(13)||'FORMULA: '||pCodFormula);
    END;

    vsFormula := SubstituiFormulas(vsFormula, vtbFormulas);

    -- Falta a tabela com os valores default
    LOOP
      BEGIN
        vrVariavel.Nome := REGEXP_SUBSTR(vsFormula,'[_[[:alpha:]]+[[:alnum:]]+[[:alpha:]]+[[:alnum:]_]]+', 1, i);

        EXIT WHEN vrVariavel.Nome is NULL;

        x := 0;
        LOOP
          BEGIN
            vrVariavel.Valor := BuscaVariavel(vrVariavel.Nome, vtbFormulas(x).Nome);
            EXIT;
          Exception
            When NO_DATA_FOUND Then
              IF x >= vtbFormulas.Last THEN
                Raise NO_DATA_FOUND;
              END IF;
             x := x + 1;
          END;
        END LOOP;

        AtribuiValor(vrVariavel, vtbVariaveis);
        PIPE row(vrVariavel);
        i := i + 1;
      Exception
        When NO_DATA_FOUND Then
          AtribuiValor(vrVariavel, vtbVariaveis);
          PIPE row(vrVariavel);
          i := i + 1;
      END;
    END LOOP;

    RETURN;
  END;

  FUNCTION ExecutarReverso(pFormula in clob, pIdentificar in out rVariavel) RETURN NUMBER IS
    vnRetorno NUMBER;
    vFormula clob;
  BEGIN
    -- Ricardo -> Passar a utilizar o novo método de substituição de variáveis
    vFormula := ReplaceAllVariaveis(pFormula, pIdentificar);
    
    EXECUTE IMMEDIATE 'SELECT ' || dbms_lob.substr(vFormula, 32765) || ' FROM DUAL'
      INTO vnRetorno;
    RETURN vnRetorno;
  END;

  FUNCTION Executar(pFormula in clob) RETURN NUMBER IS
    vnRetorno NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT ' || dbms_lob.substr(pFormula, 32765) || ' FROM DUAL'
      INTO vnRetorno;
    RETURN vnRetorno;
  END;

  FUNCTION CalcularSubFormula (pFormula           in clob,
                    ptbVariaveis       in tbVariaveis) RETURN Varchar2 IS
    vsFormula               clob := pFormula;
    vtbResult               tbVariaveis;
    i                       NUMBER := 0;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

    settarNLS();

    vsFormula := SubstituiFormulas(vsFormula);
    vsFormula := SubstituiVariaveis(vsFormula, ptbVariaveis);

    vtbResult(i).Nome  := 'RESULTADO';
    vtbResult(i).Valor := Executar(vsFormula);
  ROLLBACK;

    Return vtbResult(i).Valor;
  END;

  FUNCTION Calcular(pFormula           in clob,
                    ptbVariaveis       in tbVariaveis) RETURN tbVariaveis IS
    vsFormula               clob := pFormula;
    vtbFormulasSubstituidas tbVariaveis;
    vtbResult               tbVariaveis;
    i                       NUMBER := 0;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

    settarNLS;

    if IsCodFormula(vsFormula) then
       vsFormula := '#'|| vsFormula ||'#';
    end if;   
       
    vsFormula := SubstituiFormulas(vsFormula, vtbFormulasSubstituidas);
    vsFormula := SubstituiVariaveis(vsFormula, ptbVariaveis);

    vtbResult(i).Nome  := 'RESULTADO';
    vtbResult(i).Valor := Executar(vsFormula);

    BEGIN
      LOOP
        i := i + 1;
        EXIT WHEN (i-1) > vtbFormulasSubstituidas.last;
        vtbFormulasSubstituidas(i-1).Valor := SubstituiFormulas(vtbFormulasSubstituidas(i-1).Valor);
        vtbFormulasSubstituidas(i-1).Valor := SubstituiVariaveis(vtbFormulasSubstituidas(i-1).Valor, ptbVariaveis);
        vtbFormulasSubstituidas(i-1).Valor := Executar(vtbFormulasSubstituidas(i-1).Valor);

        AtribuiValor(vtbFormulasSubstituidas(i-1), vtbResult);
      END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    i := 0;
    LOOP
      EXIT WHEN i > ptbVariaveis.last;
      AtribuiValor(ptbVariaveis(i), vtbResult);
      i := i + 1;
    END LOOP;

  ROLLBACK;
    Return vtbResult;
  END;

  FUNCTION CalcularReverso(pFormula           in clob,
                           ptbVariaveis       in tbVariaveis,
                           pResultadoEsperado in NUMBER,
                           pValorMinimo       in number default NULL,
                           pValorMaximo       in NUMBER default NULL) RETURN tbVariaveis IS
    x             NUMBER;
    vlMin         NUMBER := NVL(pValorMinimo, 0);
    vlMax         NUMBER := NVL(pValorMaximo, pResultadoEsperado);
    vrIdentificar rVariavel;
    vsFormula     clob := pFormula;
    vtbVariaveis  tbVariaveis := ptbVariaveis;
    vnTentativas  NUMBER := 0;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    settarNLS();

    if IsCodFormula(vsFormula) then
       vsFormula := '#'|| vsFormula ||'#';
    end if;   

    vsFormula := SubstituiFormulas(vsFormula);
    vsFormula := SubstituiVariaveis(vsFormula, vtbVariaveis, vrIdentificar);
   

    LOOP

      vrIdentificar.Valor := (vlmin + vlmax) / 2;
      x := ExecutarReverso(vsFormula, vrIdentificar) - pResultadoEsperado;

      IF ABS(x) <= 0.0000001 THEN
        Exit;
      ELSIF x < 0 THEN
        vlMin := vrIdentificar.Valor;
      ELSIF x > 0 THEN
        vlMax := vrIdentificar.Valor;
      END IF;

      vnTentativas := vnTentativas + 1;
      IF vnTentativas > 999 THEN
        Raise_application_Error(-20003, 'Não foi possível realizar o cálculo reverso. Nº de tentativas excedido! Verifique se o valor total dos impostos não é superior ao total do produto!');
      END IF;
    END LOOP;

    vrIdentificar.Valor := round(vrIdentificar.Valor,6);
    vrIdentificar.Nome  := '[PTABELASEMIMPOSTO1]';
    AtribuiValor(vrIdentificar, vtbVariaveis);

    ROLLBACK;
    Return vtbVariaveis;

   /* vtbResult(0).Nome  := 'RESULTADO';
      vtbResult(0).Valor := Executar(vsFormula);
      AtribuiValor(vrIdentificar, vtbVariaveis);

      Return Calcular(pFormula,vtbVariaveis); -- Muito importante enviar pFormulaOriginal
   */


  END;

END;
