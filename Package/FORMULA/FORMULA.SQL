CREATE OR REPLACE PACKAGE FORMULA IS

  TYPE rVariavel IS RECORD(
    Nome  varchar2(300),
    Valor varchar2(4000),
    NomeFormula varchar(300));

  TYPE tbVariaveis          IS TABLE OF rVariavel INDEX BY BINARY_INTEGER;
  TYPE tbVariaveisConsulta IS TABLE OF rVariavel;-- INDEX BY BINARY_INTEGER;

  FUNCTION TabelaVariaveis(pCodFormula in Varchar2) RETURN tbVariaveisConsulta PIPELINED;

  FUNCTION BuscaValor(ptbVariaveis in tbVariaveis,
                      pNome        in varchar2) RETURN Varchar2;

  FUNCTION BuscaValor(ptbVariaveis in tbVariaveis,
                      pNome        in varchar2,
                      pNomeFormula out varchar2 ) RETURN Varchar2;

  Function SubstituiFormulas(pFormula in clob) RETURN clob;
  Function SubstituiFormulas(pFormula in clob, vtbFormulasSubstituidas out tbVariaveis) RETURN clob;

  PROCEDURE AtribuiValor(prVariaveis in rVariavel,
                         ptbVariaveis in out tbVariaveis);

  FUNCTION CalcularReverso(pFormula           in clob,
                           ptbVariaveis       in tbVariaveis,
                           pResultadoEsperado in NUMBER,
                           pValorMinimo       in number default NULL,
                           pValorMaximo       in NUMBER default NULL) RETURN tbVariaveis;

  FUNCTION Calcular(pFormula           in clob,
                    ptbVariaveis       in tbVariaveis) RETURN tbVariaveis;

  FUNCTION CalcularSubFormula(pFormula           in clob,
                    ptbVariaveis       in tbVariaveis) RETURN Varchar2;

  --G_SUBSTITUIR_FORMULA BOOLEAN DEFAULT TRUE;
END;
