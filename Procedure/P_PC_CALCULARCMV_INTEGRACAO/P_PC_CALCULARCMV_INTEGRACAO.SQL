CREATE OR REPLACE PROCEDURE P_PC_CALCULARCMV_INTEGRACAO(P_CODCLI      IN NUMBER DEFAULT 0,
                                                        P_CODST       IN NUMBER DEFAULT 0,
                                                        P_CODAUXILIAR IN NUMBER DEFAULT 0,
                                                        P_CODFILIAL   IN VARCHAR2 DEFAULT '',
                                                        P_PVENDA      IN NUMBER DEFAULT 0,
                                                        P_CUSTOFINEST OUT NUMBER,
                                                        P_VLCUSTOREAL OUT NUMBER,
                                                        P_VLCUSTOFIN  OUT NUMBER,
                                                        P_VLCUSTOREP  OUT NUMBER,
                                                        P_VLCUSTOCONT OUT NUMBER,
                                                        P_RETORNO     OUT VARCHAR2) IS

  V_TIPOFJ                    VARCHAR2(2);
  V_UTILIZAIESIMPLIFICADA     VARCHAR2(2);
  V_IEENT                     VARCHAR2(15);
  V_CONTRIBUINTE              VARCHAR2(10);
  V_ABATERIMPOSTOSCOMISSAORCA VARCHAR2(2);
  V_APLICARINDICECMV          VARCHAR2(20);
  V_TXVENDA                   NUMBER;
  V_PERFRETEESPECIAL          VARCHAR2(2);
  V_PERFRETETERCEIROS         VARCHAR2(2);
  V_FRETEESPECIAL             VARCHAR2(2);
  V_CUSTOFIN                  NUMBER;
  V_CUSTOREAL                 NUMBER;
  V_PERDESCCUSTO              NUMBER;
  V_CODICMTAB                 NUMBER;
  V_CODICMTABPF_ENULO         INTEGER;
  V_CODICMTABPF               NUMBER;
  V_PERCVENDA                 NUMBER;
  V_PVENDA                    NUMBER;
  V_PERCOM                    NUMBER;
  V_VLIPI                     NUMBER;
  V_VLISS                     NUMBER;
  V_PERFRETECMV               NUMBER;
  V_CUSTOFINEST               NUMBER;
  V_TXVENDA_ITEM              NUMBER;
  V_PERDESCCUSTO_ITEM         NUMBER;
  V_CODICMTAB_ITEM            NUMBER;
  V_VLCUSTOREAL               NUMBER;
  V_VLCUSTOFIN                NUMBER;
  V_VLDESCCUSTOCMV            NUMBER;
  V_VLCUSTOREP                NUMBER;
  V_VLCUSTOCONT               NUMBER;
  V_ST                        NUMBER;

  PROCEDURE CARREGAR_PARAM_INICIAIS IS
  BEGIN
    V_PVENDA := P_PVENDA;
  END;

  PROCEDURE CARREGAR_DAD0S_CLIENTE IS
  BEGIN
    BEGIN
      SELECT COALESCE(L.TIPOFJ, 'J') V_TIPOFJ,
             COALESCE(L.UTILIZAIESIMPLIFICADA, 'N') V_UTILIZAIESIMPLIFICADA,
             L.IEENT V_IEENT,
             COALESCE(L.CONTRIBUINTE, 'N') V_CONTRIBUINTE
        INTO V_TIPOFJ, V_UTILIZAIESIMPLIFICADA, V_IEENT, V_CONTRIBUINTE
      
        FROM PCCLIENT L
       WHERE L.CODCLI = P_CODCLI;
    EXCEPTION
      WHEN OTHERS THEN
        V_TIPOFJ                := 'F';
        V_UTILIZAIESIMPLIFICADA := 'N';
        V_IEENT                 := 'ISENTO';
        V_CONTRIBUINTE          := 'N';
    END;
  
  END;

  PROCEDURE CARREGAR_DADOS_PRODUTO IS
  BEGIN
    BEGIN
      SELECT (SELECT COALESCE(VALOR, 'N') FROM PCPARAMFILIAL WHERE NOME = 'CON_ABATERIMPOSTOSCOMISSAORCA') V_ABATERIMPOSTOSCOMISSAORCA,
             (SELECT APLICARINDICECMV FROM PCCONSUM) V_APLICARINDICECMV,
             (SELECT COALESCE(VALOR, '0') FROM PCPARAMFILIAL WHERE NOME = 'CON_TXVENDA') V_TXVENDA,
             (SELECT COALESCE(R.PERFRETEESPECIAL, 0)
                FROM PCREGIAO R
               WHERE R.NUMREGIAO = (SELECT VALOR
                                      FROM PCPARAMFILIAL
                                     WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                                       AND CODFILIAL = '1')) V_PERFRETEESPECIAL,
             (SELECT COALESCE(R.PERFRETETERCEIROS, 0)
                FROM PCREGIAO R
               WHERE R.NUMREGIAO = (SELECT VALOR
                                      FROM PCPARAMFILIAL
                                     WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                                       AND CODFILIAL = '1')) V_PERFRETETERCEIROS,
             COALESCE(P.FRETEESPECIAL, 'N') V_FRETEESPECIAL,
             COALESCE(S.CUSTOFIN, 0) V_CUSTOFIN,
             COALESCE(S.CUSTOREAL, 0) V_CUSTOREAL,
             COALESCE(S.CUSTOREP, 0) V_CUSTOREP,
             COALESCE(S.CUSTOCONT, 0) V_CUSTOCONT
        INTO V_ABATERIMPOSTOSCOMISSAORCA,
             V_APLICARINDICECMV,
             V_TXVENDA,
             V_PERFRETEESPECIAL,
             V_PERFRETETERCEIROS,
             V_FRETEESPECIAL,
             V_CUSTOFIN,
             V_CUSTOREAL,
             V_VLCUSTOREP,
             V_VLCUSTOCONT
        FROM PCPRODUT P, PCEMBALAGEM E, PCEST S
       WHERE E.CODPROD = P.CODPROD
         AND E.CODPROD = S.CODPROD
         AND E.CODFILIAL = S.CODFILIAL
         AND E.CODFILIAL = P_CODFILIAL
         AND E.CODAUXILIAR = P_CODAUXILIAR;
    EXCEPTION
      WHEN OTHERS THEN
        V_ABATERIMPOSTOSCOMISSAORCA := 'N';
        V_APLICARINDICECMV          := 'N';
        V_TXVENDA                   := 100;
        V_PERFRETEESPECIAL          := 0;
        V_PERFRETETERCEIROS         := 0;
        V_FRETEESPECIAL             := 0;
        V_CUSTOFIN                  := 0;
        V_CUSTOREAL                 := 0;
        V_VLCUSTOREP                := 0;
        V_VLCUSTOCONT               := 0;
    END;
  END;

  PROCEDURE CARREGAR_DADOS_TRIBUTACAO IS
  BEGIN
    BEGIN
      SELECT COALESCE(T.PERDESCCUSTO, 0) V_PERDESCCUSTO,
             T.CODICMTAB V_CODICMTAB,
             (CASE
               WHEN T.CODICMTAB IS NULL THEN
                1
               ELSE
                0
             END) CODICMTABPF_ENULO,
             T.CODICMTABPF V_CODICMTABPF
        INTO V_PERDESCCUSTO, V_CODICMTAB, V_CODICMTABPF_ENULO, V_CODICMTABPF
        FROM PCTRIBUT T
       WHERE CODST = P_CODST;
    EXCEPTION
      WHEN OTHERS THEN
        V_PERDESCCUSTO      := 0;
        V_CODICMTAB         := 0;
        V_CODICMTABPF_ENULO := 0;
        V_CODICMTABPF       := 0;
    END;
  END;

  PROCEDURE CALCULAR_CMV IS
  BEGIN
    BEGIN
      FUNCOESVENDAS.CALCULARCMV -- 33 PARAMETROS
      (V_ABATERIMPOSTOSCOMISSAORCA,
       V_APLICARINDICECMV,
       V_TXVENDA,
       V_TIPOFJ,
       V_UTILIZAIESIMPLIFICADA,
       V_IEENT,
       V_FRETEESPECIAL,
       V_PERFRETETERCEIROS,
       V_PERFRETEESPECIAL,
       V_CUSTOFIN,
       V_CUSTOREAL,
       V_PERDESCCUSTO,
       V_CODICMTAB,
       SYS.diutil.int_to_bool(V_CODICMTABPF_ENULO), -- V_CODICMTABPF_ENULO IN BOOLEAN,
       V_CODICMTABPF,
       V_PERCVENDA,
       V_PVENDA,
       V_PERCOM,
       V_ST,
       V_VLIPI,
       V_VLISS,
       V_CONTRIBUINTE,
       V_PERFRETECMV,
       V_CUSTOFINEST,
       V_TXVENDA_ITEM,
       V_PERDESCCUSTO_ITEM,
       V_CODICMTAB_ITEM,
       V_VLCUSTOREAL,
       V_VLCUSTOFIN,
       V_VLDESCCUSTOCMV,
       FALSE, --V_APLICAREDTRIBUT IN BOOLEAN DEFAULT FALSE,
       FALSE, --V_BONIFIC IN BOOLEAN DEFAULT FALSE,
       0 --V_CODST IN NUMBER DEFAULT 0
       );
    EXCEPTION
      WHEN OTHERS THEN
        P_RETORNO := 'ERROR: ' || SQLCODE || '-' || SQLERRM || '- LINHA: ' || DBMS_UTILITY.format_error_backtrace;
    END;
  END;
BEGIN

  --
  CARREGAR_PARAM_INICIAIS;
  --
  CARREGAR_DAD0S_CLIENTE;
  --
  CARREGAR_DADOS_PRODUTO;
  --
  CARREGAR_DADOS_TRIBUTACAO;
  --
  CALCULAR_CMV;
  --

  P_CUSTOFINEST := V_CUSTOFINEST;
  P_VLCUSTOREAL := V_VLCUSTOREAL;
  P_VLCUSTOFIN  := V_VLCUSTOFIN;
  P_VLCUSTOREAL := V_VLCUSTOREAL;
  P_VLCUSTOFIN  := V_VLCUSTOFIN;
  P_VLCUSTOREP  := V_VLCUSTOREP;
  P_VLCUSTOCONT := V_VLCUSTOCONT;
  P_RETORNO     := 'OK';

END P_PC_CALCULARCMV_INTEGRACAO;
