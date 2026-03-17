CREATE OR REPLACE TYPE BODY "T_PC_CONTASRECEBER"
AS

 CONSTRUCTOR FUNCTION T_PC_CONTASRECEBER(PMATRICULA NUMBER,PSTABELA VARCHAR2 DEFAULT 'PCPREST')
   RETURN SELF AS RESULT
 IS
 BEGIN
   SELF.TABELA := PSTABELA;

   RETURN;
 END;

 MEMBER PROCEDURE LIMPAR
 IS
 BEGIN
   SELF.CODFILIAL             := NULL; -- 01
   SELF.CODCLI                := NULL; -- 02
   SELF.CODUSUR               := NULL; -- 03
   SELF.PREST                 := NULL; -- 04
   SELF.DUPLIC                := NULL; -- 05
   SELF.VALOR                 := NULL; -- 06
   SELF.CODCOB                := NULL; -- 07
   SELF.DTVENC                := NULL; -- 08
   SELF.DTVENCORIG            := NULL; -- 09
   SELF.DTEMISSAO             := NULL; -- 10
   SELF.OPERACAO              := NULL; -- 11
   SELF.BOLETO                := NULL; -- 12
   SELF.STATUS                := NULL; -- 13
   SELF.NUMCAR                := NULL; -- 14
   SELF.CODSUPERVISOR         := NULL; -- 15
   SELF.NUMTRANSVENDA         := NULL; -- 16
   SELF.VLTXBOLETO            := NULL; -- 17
   SELF.VALORLIQCOM           := NULL; -- 18
   SELF.PERCOM                := NULL; -- 19
   SELF.CODEPTO               := NULL; -- 20
   SELF.VALORORIG             := NULL; -- 21
   SELF.CODCOBORIG            := NULL; -- 22
   SELF.PERDESC               := NULL; -- 23
   SELF.VALORDESC             := NULL; -- 24
   SELF.OBS2                  := NULL; -- 25
   SELF.CODFILIALNF           := NULL; -- 26
   SELF.NUMPED                := NULL; -- 27
   SELF.CODESTABELECIMENTO    := NULL; -- 28
   SELF.NUMCHECKOUT           := NULL; -- 29
   SELF.CODFUNCCHECKOUT       := NULL; -- 30
   SELF.CODEMITENTEPEDIDO     := NULL; -- 31
   SELF.BLOQDESDEMITENTEDIF   := NULL; -- 32
   SELF.DTCRIACAO             := NULL; -- 33
   SELF.DTEMISSAOORIG         := NULL; -- 34
   SELF.PERCOM2               := NULL; -- 35
   SELF.PERCOM3               := NULL; -- 36
   SELF.PERCOM4               := NULL; -- 37
   SELF.CODUSUR2              := NULL; -- 38
   SELF.CODUSUR3              := NULL; -- 39
   SELF.CODUSUR4              := NULL; -- 40
   SELF.CODAUTORIZACAOTEF     := NULL; -- 41
   SELF.NSUTEF                := NULL; -- 42
   SELF.CODADMCARTAO          := NULL; -- 43
   SELF.SOMATXBOLETO          := NULL; -- 44
   SELF.VALORDESCORIG         := NULL; -- 45
   SELF.DTDESC                := NULL; -- 46
   SELF.PRESTTEF              := NULL; -- 47
   SELF.NUMTRANSVENDAST       := NULL; -- 48
   SELF.CODBANCO              := NULL; -- 49
   SELF.TXPERM                := NULL; -- 51
   SELF.VPAGO                 := NULL; -- 52
   SELF.DTPAG                 := NULL; -- 53
   SELF.DTBAIXA               := NULL; -- 54
   SELF.DTDESD                := NULL; -- 55
   SELF.DTFECHA               := NULL; -- 56
   SELF.DTESTORNO             := NULL; -- 57
   SELF.DTULTALTER            := NULL; -- 58
   SELF.HORAFECHA             := NULL; -- 59
   SELF.MINUTOFECHA           := NULL; -- 60
   SELF.DTLANCCH              := NULL; -- 61
   SELF.NUMAGENCIA            := NULL; -- 62
   SELF.NUMCHEQUE             := NULL; -- 63
   SELF.NUMCONTACORRENTE      := NULL; -- 64
   SELF.DTCXMOTHHMMSS         := NULL; -- 65
   SELF.CODFUNCCCXMOT         := NULL; -- 66
   SELF.VLTROCO               := NULL; -- 67
   SELF.CODCOBSEFAZ           := NULL; -- 68
   SELF.BANDEIRACARTAO        := NULL; -- 69
   SELF.PERCOMLIQ             := NULL; -- 70
   SELF.CNPJCREDENCCARTAO     := NULL; -- 71
   SELF.CORRESPONDENTE        := NULL; -- 72
   SELF.VALORMULTA            := NULL; -- 73
   SELF.NUMTRANSPAGDIGITAL    := NULL; -- 74
   SELF.DTMOVIMENTOCX         := NULL; -- 75
   SELF.CNPJPAG               := NULL; -- 76
   SELF.UFPAG                 := NULL; -- 77
   SELF.CNPJRECEB             := NULL; -- 78
   SELF.IDTERMPAG             := NULL; -- 79
 END LIMPAR;

 MEMBER PROCEDURE INSERIR
 IS
   vSQL VARCHAR2(4000);
 BEGIN
   /*
    Data       : 07/02/2018
    Solicitação: VEN-1937
    Responsável: Guilherme Freitas
    Motivo     : Foi feita a alteração abaixo para conteplar o processo de
                 inserção das prestações nas tabelas de pré-faturamento.
                 A implementação abaixo foi executada desta forma para não
                 causa impactos em demais lugares que utilizam o type
                 para inserção de contas à receber.
   */
   vSql :=
   'INSERT INTO ' || self.tabela || ' --pcprest
    (codfilial, -- 01
     codcli, -- 02
     codusur, -- 03
     prest, -- 04
     duplic, -- 05
     valor, -- 06
     codcob, -- 07
     dtvenc, -- 08
     dtvencorig, -- 09
     dtemissao, -- 10
     operacao, -- 11
     boleto, -- 12
     status, -- 13
     numcar, -- 14
     codsupervisor, -- 15
     numtransvenda, -- 16
     vltxboleto, -- 17
     valorliqcom, -- 18
     percom, -- 19
     codepto, -- 20
     valororig, -- 21
     codcoborig, -- 22
     perdesc, -- 23
     valordesc, -- 24
     obs2, -- 25
     codfilialnf, -- 26
     numped, -- 27
     codestabelecimento, -- 28
     numcheckout, -- 29
     codfunccheckout, -- 30
     codemitentepedido, -- 31
     bloqdesdemitentedif, -- 32
     dtcriacao, -- 33
     dtemissaoorig, -- 34
     percom2, -- 35
     percom3, -- 36
     percom4, -- 37
     codusur2, -- 38
     codusur3, -- 39
     codusur4, -- 40
     codautorizacaotef, -- 41
     nsutef, -- 42
     codadmcartao, -- 43
     somatxboleto, -- 44
     valordescorig, -- 45 Este é uma copia do campo 24
     dtdesc, -- 46
     presttef, --47
     numtransvendast, -- 48
     codmotorista, -- 49
     codbanco, -- 50
     TXPERM,  -- 51
     VPAGO,   -- 52
     DTPAG,   -- 53
     DTBAIXA, -- 54
     DTDESD,  -- 55
     DTFECHA, -- 56
     DTESTORNO, --57
     PERMITEESTORNO, --58
     DTCXMOT,        -- 59
     CODFUNCCXMOT,   -- 60
     CODFUNCFECHA,   -- 61
     VALORESTORNO,    -- 62
     DTULTALTER, --63
     HORAFECHA,           -- 64
     MINUTOFECHA,         -- 65
     DTLANCCH,            -- 66
     NUMAGENCIA,          -- 67
     NUMCHEQUE,           -- 68
     NUMCONTACORRENTE,    -- 69
     DTCXMOTHHMMSS,       -- 70
     VLTROCO,       --71
     CODCOBSEFAZ,    --72
     BANDEIRACARTAO,  --73
     PERCOMLIQ, --74
     CNPJCREDENCCARTAO, --75
     CORRESPONDENTE, --76
     VALORMULTA, --77
     NUMTRANSPAGDIGITAL, --78
     DTMOVIMENTOCX, --79
     CNPJPAG, --80
     UFPAG,  --81
     CNPJRECEB, --82
     IDTERMPAG --83
     )
  VALUES
  (:CODFILIAL, -- 01
   :CODCLI, -- 02
   :CODUSUR, -- 03
   :PREST, -- 04
   :DUPLIC, -- 05
   :VALOR, -- 06
   :CODCOB, -- 07
   :DTVENC, -- 08
   :DTVENCORIG, -- 09
   :DTEMISSAO, -- 10
   :OPERACAO, -- 11
   :BOLETO, -- 12
   :STATUS, -- 13
   :NUMCAR, -- 14
   :CODSUPERVISOR, -- 15
   :NUMTRANSVENDA, -- 16
   :VLTXBOLETO, -- 17
   :VALORLIQCOM, -- 18
   :PERCOM, -- 19
   :CODEPTO, -- 20
   :VALORORIG, -- 21
   :CODCOBORIG, -- 22
   :PERDESC, -- 23
   :VALORDESC, -- 24
   :OBS2, -- 25
   :CODFILIALNF, -- 26
   :NUMPED, -- 27
   :CODESTABELECIMENTO, -- 28
   :NUMCHECKOUT, -- 29
   :CODFUNCCHECKOUT, -- 30
   :CODEMITENTEPEDIDO, -- 31
   :BLOQDESDEMITENTEDIF, -- 32
   :DTCRIACAO, -- 33
   :DTEMISSAOORIG, -- 34
   :PERCOM2, -- 35
   :PERCOM3, -- 36
   :PERCOM4, -- 37
   :CODUSUR2, -- 38
   :CODUSUR3, -- 39
   :CODUSUR4, -- 40
   :CODAUTORIZACAOTEF, -- 41
   :NSUTEF, -- 42
   :CODADMCARTAO, -- 43
   :SOMATXBOLETO, -- 44
   :VALORDESCORIG, -- 45 ESTE É UMA COPIA DO CAMPO 24
   :DTDESC, -- 46
   :PRESTTEF,  -- 47
   :NUMTRANSVENDAST, -- 48
   :CODMOTORISTA, -- 49
   :CODBANCO, -- 50
   :TXPERM,  -- 51
   :VPAGO,   -- 52
   :DTPAG,   -- 53
   :DTBAIXA, -- 54
   :DTDESD,  -- 55
   :DTFECHA,  -- 56
   :DTESTORNO, --57
   :PERMITEESTORNO, --58
   :DTCXMOT,        -- 59
   :CODFUNCCXMOT,   -- 60
   :CODFUNCFECHA,   -- 61
   :VALORESTORNO,    -- 62
   TRUNC(SYSDATE),       --63
   :HORAFECHA,       -- 64
   :MINUTOFECHA,     -- 65
   :DTLANCCH,        -- 66
   :NUMAGENCIA,      -- 67
   :NUMCHEQUE,       -- 68
   :NUMCONTACORRENTE,-- 69
   :DTCXMOTHHMMSS,   -- 70
   :VLTROCO,        --71
   :CODCOBSEFAZ,    --72
   :BANDEIRACARTAO, --73
   :PERCOMLIQ,        --74
   :CNPJCREDENCCARTAO, --75
   :CORRESPONDENTE, -- 76
   :VALORMULTA, --77
   :NUMTRANSPAGDIGITAL, --78
   :DTMOVIMENTOCX, --79
   :CNPJPAG, --80
   :UFPAG,  --81
   :CNPJRECEB, --82
   :IDTERMPAG --83
   )';

   EXECUTE IMMEDIATE vsql
   USING
   SELF.CODFILIAL, -- 01
   SELF.CODCLI, -- 02
   SELF.CODUSUR, -- 03
   SELF.PREST, -- 04
   SELF.DUPLIC, -- 05
   SELF.VALOR, -- 06
   SELF.CODCOB, -- 07
   SELF.DTVENC, -- 08
   SELF.DTVENCORIG, -- 09
   SELF.DTEMISSAO, -- 10
   SELF.OPERACAO, -- 11
   SELF.BOLETO, -- 12
   SELF.STATUS, -- 13
   SELF.NUMCAR, -- 14
   SELF.CODSUPERVISOR, -- 15
   SELF.NUMTRANSVENDA, -- 16
   SELF.VLTXBOLETO, -- 17
   SELF.VALORLIQCOM, -- 18
   SELF.PERCOM, -- 19
   SELF.CODEPTO, -- 20
   SELF.VALORORIG, -- 21
   SELF.CODCOBORIG, -- 22
   SELF.PERDESC, -- 23
   SELF.VALORDESC, -- 24
   SELF.OBS2, -- 25
   SELF.CODFILIALNF, -- 26
   SELF.NUMPED, -- 27
   SELF.CODESTABELECIMENTO, -- 28
   SELF.NUMCHECKOUT, -- 29
   SELF.CODFUNCCHECKOUT, -- 30
   SELF.CODEMITENTEPEDIDO, -- 31
   SELF.BLOQDESDEMITENTEDIF, -- 32
   SELF.DTCRIACAO, -- 33
   SELF.DTEMISSAOORIG, -- 34
   SELF.PERCOM2, -- 35
   SELF.PERCOM3, -- 36
   SELF.PERCOM4, -- 37
   SELF.CODUSUR2, -- 38
   SELF.CODUSUR3, -- 39
   SELF.CODUSUR4, -- 40
   SELF.CODAUTORIZACAOTEF, -- 41
   SELF.NSUTEF, -- 42
   SELF.CODADMCARTAO, -- 43
   SELF.SOMATXBOLETO, -- 44
   SELF.VALORDESCORIG, -- 45 ESTE É UMA COPIA DO CAMPO 24
   SELF.DTDESC, -- 46
   SELF.PRESTTEF,  -- 47
   SELF.NUMTRANSVENDAST, -- 48
   SELF.CODMOTORISTA, -- 49
   SELF.CODBANCO, -- 50
   SELF.TXPERM, -- 51
   SELF.VPAGO,   -- 52
   SELF.DTPAG,   -- 53
   SELF.DTBAIXA, -- 54
   SELF.DTDESD,  -- 55
   SELF.DTFECHA,  -- 56
   SELF.DTESTORNO, --57
   SELF.PERMITEESTORNO, --58
   SELF.DTCXMOT,        -- 59
   SELF.CODFUNCCXMOT,   -- 60
   SELF.CODFUNCFECHA,   -- 61
   SELF.VALORESTORNO,    -- 62
   --TRUNC(SYSDATE),       --63
   SELF.HORAFECHA,       -- 64
   SELF.MINUTOFECHA,     -- 65
   SELF.DTLANCCH,        -- 66
   SELF.NUMAGENCIA,      -- 67
   SELF.NUMCHEQUE,       -- 68
   SELF.NUMCONTACORRENTE,-- 69
   SELF.DTCXMOTHHMMSS,   -- 70
   SELF.VLTROCO,        --71
   SELF.CODCOBSEFAZ,    --72
   SELF.BANDEIRACARTAO,  --73
   SELF.PERCOMLIQ, --74
   SELF.CNPJCREDENCCARTAO, --75
   SELF.CORRESPONDENTE, --76
   SELF.VALORMULTA, --77
   SELF.NUMTRANSPAGDIGITAL, --78
   SELF.DTMOVIMENTOCX, --79
   SELF.CNPJPAG, --80
   SELF.UFPAG,  --81
   SELF.CNPJRECEB, --82
   SELF.IDTERMPAG; --83
 END INSERIR;

 MEMBER PROCEDURE ACERTAR
 IS
   vSQL VARCHAR2(4000);
 BEGIN
   vSql := ' UPDATE ' || SELF.TABELA || --PCPREST
              ' SET DTFECHA      = TRUNC(SYSDATE),
                    CODFUNCFECHA = :CODFUNCFECHA,
                    DTCXMOT      = :DTEMISSAO,
                    CODFUNCCXMOT = :CODFUNCFECHA
              WHERE NUMTRANSVENDA = :NUMTRANSVENDA
                AND PREST = :PREST';

   EXECUTE IMMEDIATE vsql
   USING SELF.CODFUNCCHECKOUT
        ,SELF.DTEMISSAO
        ,SELF.CODFUNCFECHA
        ,SELF.NUMTRANSVENDA
        ,SELF.PREST;

 END ACERTAR;

 MEMBER PROCEDURE QUITAR
 IS
   vSQL VARCHAR2(4000);
 BEGIN
   vSql := ' UPDATE ' || self.tabela || --PCPREST
              ' SET DTPAG     = DECODE(CODCOB, ''CRED'', TRUNC(SYSDATE), :DTEMISSAO),
                    DTBAIXA   = DECODE(CODCOB, ''CRED'', TRUNC(SYSDATE), :DTEMISSAO),
                    CODBAIXA  = :CODBAIXA,
                    VPAGO     = :VALOR
              WHERE NUMTRANSVENDA = :NUMTRANSVENDA
                AND PREST = :PREST';

   EXECUTE IMMEDIATE vsql
     USING SELF.DTEMISSAO
          ,SELF.DTEMISSAO
          ,SELF.CODBAIXA
          ,SELF.VALOR
          ,SELF.NUMTRANSVENDA
          ,SELF.PREST;

 END QUITAR;

 MEMBER PROCEDURE BAIXARCOMCREDITO
  IS
 BEGIN

   UPDATE PCPREST SET
          VPAGO        = SELF.VPAGO,
          DTPAG        = TRUNC(SYSDATE),
          CODBAIXA     = SELF.CODBAIXA,
          DTBAIXA      = TRUNC(SYSDATE),
          CODCOBORIG   = SELF.CODCOBORIG,
          DTBAIXACRED  = SYSDATE,
          DTULTALTER   = TRUNC(SYSDATE),
          TXPERM       = SELF.TXPERM,
          VALORMULTA   = SELF.VALORMULTA,
          DTCXMOT      = TRUNC(SYSDATE),
          CODFUNCCXMOT = SELF.CODFUNCCXMOT,
          CODFUNCFECHA = SELF.CODFUNCFECHA,
          CODCOB       = 'CRED',
          DTFECHA      = NVL(DTFECHA,TRUNC(SYSDATE))
  WHERE   NUMTRANSVENDA = SELF.NUMTRANSVENDA
  AND     PREST         = SELF.PREST;

 END BAIXARCOMCREDITO;

 MEMBER PROCEDURE DESDOBRAR
  IS
 BEGIN

   UPDATE PCPREST SET
          VPAGO        = VALOR,
          DTPAG        = TRUNC(SYSDATE),
          DTBAIXA      = TRUNC(SYSDATE),
          DTULTALTER   = TRUNC(SYSDATE),
          DTCXMOT      = TRUNC(SYSDATE),
          DTFECHA      = TRUNC(SYSDATE),
          DTDESD       = TRUNC(SYSDATE),
          CODFUNCCXMOT = SELF.CODFUNCCXMOT,
          CODFUNCFECHA = SELF.CODFUNCFECHA,
          CODFUNCDESD  = SELF.CODFUNCFECHA,
          CODCOB       = 'DESD'
  WHERE   NUMTRANSVENDA = SELF.NUMTRANSVENDA
  AND     PREST         = SELF.PREST;

 END DESDOBRAR;

 MEMBER PROCEDURE BUSCARREGISTRO(PNUMTRANSVENDA NUMBER, PPREST VARCHAR2)
 IS
 BEGIN
   SELECT CODFILIAL,           -- 01
          CODCLI,              -- 02
          CODUSUR,             -- 03
          PREST,               -- 04
          DUPLIC,              -- 05
          VALOR,               -- 06
          CODCOB,              -- 07
          DTVENC,              -- 08
          DTVENCORIG,          -- 09
          DTEMISSAO,           -- 10
          OPERACAO,            -- 11
          BOLETO,              -- 12
          STATUS,              -- 13
          NUMCAR,              -- 14
          CODSUPERVISOR,       -- 15
          NUMTRANSVENDA,       -- 16
          VLTXBOLETO,          -- 17
          VALORLIQCOM,         -- 18
          PERCOM,              -- 19
          CODEPTO,             -- 20
          VALORORIG,           -- 21
          CODCOBORIG,          -- 22
          PERDESC,             -- 23
          VALORDESC,           -- 24
          OBS2,                -- 25
          CODFILIALNF,         -- 26
          NUMPED,              -- 27
          CODESTABELECIMENTO,  -- 28
          NUMCHECKOUT,         -- 29
          CODFUNCCHECKOUT,     -- 30
          CODEMITENTEPEDIDO,   -- 31
          BLOQDESDEMITENTEDIF, -- 32
          DTCRIACAO,           -- 33
          DTEMISSAOORIG,       -- 34
          PERCOM2,             -- 35
          PERCOM3,             -- 36
          PERCOM4,             -- 37
          CODUSUR2,            -- 38
          CODUSUR3,            -- 39
          CODUSUR4,            -- 40
          CODAUTORIZACAOTEF,   -- 41
          NSUTEF,              -- 42
          CODADMCARTAO,        -- 43
          SOMATXBOLETO ,       -- 44
          VALORDESCORIG,       -- 45
          DTDESC,              -- 46
          PRESTTEF,            -- 47
          CODFUNCFECHA,        -- 48
          CODFUNCCXMOT,        -- 49
          CODBAIXA,            -- 50
          NUMTRANSVENDAST,     -- 51
          CODMOTORISTA,        -- 52
          CODBANCO,            -- 53
          DTDESD,              -- 54
          DTFECHA,             -- 55
          DTPAG,               -- 56
          PERMITEESTORNO,      -- 57
          VPAGO,               -- 58
          DTBAIXA,             -- 59
          DTCXMOT,             -- 60
          TXPERM,              -- 61
          CODFUNCCXMOT,        -- 62
          CODFUNCFECHA,        -- 63
          VALORESTORNO,        -- 64
          DTULTALTER,          -- 65
          HORAFECHA,           -- 66
          MINUTOFECHA,         -- 67
          DTLANCCH,            -- 68
          NUMAGENCIA,          -- 69
          NUMCHEQUE,           -- 70
          NUMCONTACORRENTE,    -- 71
          DTCXMOTHHMMSS,       -- 72
          CODFUNCCCXMOT,       -- 73
          HORAFECHA,           -- 74
          MINUTOFECHA,         -- 75
          VLTROCO,             -- 76
          VALORMULTA,          -- 77
          NUMTRANSPAGDIGITAL,  -- 78
          DTMOVIMENTOCX,       -- 79
          CNPJPAG,             -- 80
          UFPAG,               -- 81
          CNPJRECEB,           -- 82
          IDTERMPAG            -- 83
   INTO
          SELF.CODFILIAL,           -- 01
          SELF.CODCLI,              -- 02
          SELF.CODUSUR,             -- 03
          SELF.PREST,               -- 04
          SELF.DUPLIC,              -- 05
          SELF.VALOR,               -- 06
          SELF.CODCOB,              -- 07
          SELF.DTVENC,              -- 08
          SELF.DTVENCORIG,          -- 09
          SELF.DTEMISSAO,           -- 10
          SELF.OPERACAO,            -- 11
          SELF.BOLETO,              -- 12
          SELF.STATUS,              -- 13
          SELF.NUMCAR,              -- 14
          SELF.CODSUPERVISOR,       -- 15
          SELF.NUMTRANSVENDA,       -- 16
          SELF.VLTXBOLETO,          -- 17
          SELF.VALORLIQCOM,         -- 18
          SELF.PERCOM,              -- 19
          SELF.CODEPTO,             -- 20
          SELF.VALORORIG,           -- 21
          SELF.CODCOBORIG,          -- 22
          SELF.PERDESC,             -- 23
          SELF.VALORDESC,           -- 24
          SELF.OBS2,                -- 25
          SELF.CODFILIALNF,         -- 26
          SELF.NUMPED,              -- 27
          SELF.CODESTABELECIMENTO,  -- 28
          SELF.NUMCHECKOUT,         -- 29
          SELF.CODFUNCCHECKOUT,     -- 30
          SELF.CODEMITENTEPEDIDO,   -- 31
          SELF.BLOQDESDEMITENTEDIF, -- 32
          SELF.DTCRIACAO,           -- 33
          SELF.DTEMISSAOORIG,       -- 34
          SELF.PERCOM2,             -- 35
          SELF.PERCOM3,             -- 36
          SELF.PERCOM4,             -- 37
          SELF.CODUSUR2,            -- 38
          SELF.CODUSUR3,            -- 39
          SELF.CODUSUR4,            -- 40
          SELF.CODAUTORIZACAOTEF,   -- 41
          SELF.NSUTEF,              -- 42
          SELF.CODADMCARTAO,        -- 43
          SELF.SOMATXBOLETO ,       -- 44
          SELF.VALORDESCORIG,       -- 45
          SELF.DTDESC,              -- 46
          SELF.PRESTTEF,            -- 47
          SELF.CODFUNCFECHA,        -- 48
          SELF.CODFUNCCXMOT,        -- 49
          SELF.CODBAIXA,            -- 50
          SELF.NUMTRANSVENDAST,     -- 51
          SELF.CODMOTORISTA,        -- 52
          SELF.CODBANCO,            -- 53
          SELF.DTDESD,              -- 54
          SELF.DTFECHA,             -- 55
          SELF.DTPAG,               -- 56
          SELF.PERMITEESTORNO,      -- 57
          SELF.VPAGO,               -- 58
          SELF.DTBAIXA,             -- 59
          SELF.DTCXMOT,             -- 60
          SELF.TXPERM,              -- 61
          SELF.CODFUNCCXMOT,        -- 62
          SELF.CODFUNCFECHA,        -- 63
          SELF.VALORESTORNO,        -- 64
          SELF.DTULTALTER,          -- 65
          SELF.HORAFECHA,           -- 66
          SELF.MINUTOFECHA,         -- 67
          SELF.DTLANCCH,            -- 68
          SELF.NUMAGENCIA,          -- 69
          SELF.NUMCHEQUE,           -- 70
          SELF.NUMCONTACORRENTE,    -- 71
          SELF.DTCXMOTHHMMSS,       -- 72
          SELF.CODFUNCCCXMOT,       -- 73
          SELF.HORAFECHA,           -- 74
          SELF.MINUTOFECHA,         -- 75
          SELF.VLTROCO,             -- 76
          SELF.VALORMULTA,          -- 77
          SELF.NUMTRANSPAGDIGITAL,  -- 78
          SELF.DTMOVIMENTOCX,       -- 79
          SELF.CNPJPAG,             -- 80
          SELF.UFPAG,               -- 81
          SELF.CNPJRECEB,           -- 82
          SELF.IDTERMPAG            -- 83
    FROM PCPREST
    WHERE NUMTRANSVENDA = PNUMTRANSVENDA
    AND   PREST         = PPREST;
 END BUSCARREGISTRO;

 MEMBER PROCEDURE ESTORNAR
 IS
   VPRESTORIG PCPREST.PREST%TYPE;
   VOCCAREGAMENTO T_PC_CARREGAMENTO;
 BEGIN
   --ESTORNANDO O ORIGINAL
   UPDATE PCPREST P SET P.DTESTORNO = TRUNC(SYSDATE),
                        P.PERMITEESTORNO = 'N',
                        P.DTULTALTER = TRUNC(SYSDATE),
                        P.VALORESTORNO = P.VPAGO
   WHERE P.NUMTRANSVENDA = SELF.NUMTRANSVENDA
   AND   P.PREST         = SELF.PREST;

  PKG_CANCELARDESDOBRAMENTO.PCPREST_INSERIR_PCDESDPREST(
    SELF.NUMTRANSVENDA,
    SELF.PREST,
    SELF.CODCOB,
    SELF.DTCXMOT,
    SELF.DTFECHA,
    SELF.DTBAIXA,
    SELF.DTLANCCH,
    SELF.NUMAGENCIA,
    SELF.NUMCHEQUE,
    SELF.NUMCONTACORRENTE,
    SELF.DTCXMOTHHMMSS,
    SELF.HORAFECHA,
    SELF.MINUTOFECHA,
    SELF.CODFUNCCCXMOT,
    0
  );

   VPRESTORIG := SELF.PREST;

   --INSERINDO O ESTORNO
   SELF.PREST          := FNC_GETPROXIMAPREST(SELF.NUMTRANSVENDA);
   SELF.DTESTORNO      := TRUNC(SYSDATE);
   SELF.PERMITEESTORNO := 'N';
   SELF.VALOR          := SELF.VALOR * (-1);
   SELF.VPAGO          := SELF.VPAGO * (-1);
   SELF.TXPERM         := SELF.TXPERM * (-1);
   SELF.VALORMULTA     := SELF.VALORMULTA * (-1);
   SELF.VALORESTORNO   := SELF.VPAGO;

   IF NVL(SELF.NUMCAR, 0) > 0 THEN
   BEGIN
     VOCCAREGAMENTO := T_PC_CARREGAMENTO(SELF.NUMCAR);

    IF VOCCAREGAMENTO.GETDTFECHA IS NULL THEN
      SELF.DTFECHA := NULL;
    END IF;

     EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
   END IF;

   SELF.CODCOB         := 'ESTR';
   SELF.INSERIR;

   --INSERINDO O TITULO EM ABERTO
   SELF.PREST          := FNC_GETPROXIMAPREST(SELF.NUMTRANSVENDA);
   SELF.PERMITEESTORNO := 'S';
   SELF.DTESTORNO      := TRUNC(SYSDATE);
   SELF.DTPAG          := NULL;
   SELF.DTBAIXA        := NULL;
   SELF.DTFECHA        := SELF.DTFECHA;
   SELF.VPAGO          := NULL;
   SELF.TXPERM         := NULL;
   SELF.VALORMULTA     := NULL;
   SELF.CODCOB         := SELF.CODCOBORIG;
   SELF.VALOR          := SELF.VALOR * (-1);
   SELF.VALORESTORNO   := NULL;
   SELF.INSERIR;

   PKG_CANCELARDESDOBRAMENTO.PCPREST_INSERIR_PCDESDMAP(
     'ESTORNO TOTAL',
     SELF.NUMTRANSVENDA,
     SELF.PREST,
     SELF.NUMTRANSVENDA,
     VPRESTORIG
   );

 END ESTORNAR;

 MEMBER PROCEDURE BAIXAR_BONIFIC
 IS
   vSQL VARCHAR2(4000);
 BEGIN
   vSql := 'UPDATE ' || SELF.TABELA ||  --PCPREST
             ' SET VPAGO         = :VALOR
                  ,DTPAG         = :DTEMISSAO
                  ,DTFECHA       = :DTEMISSAO
                  ,DTBAIXA       = :DTEMISSAO
                  ,CODBAIXA      = :CODBAIXA
                  ,CODFUNCFECHA  = :CODFUNCFECHA
                  ,HORAFECHA     = :MINUTOFECHA
                  ,MINUTOFECHA   = :HORAFECHA
                  ,DTCXMOT       = :DTCXMOT
             WHERE NUMTRANSVENDA = :NUMTRANSVENDA
               AND PREST         = :PREST ';

   EXECUTE IMMEDIATE vsql
     USING SELF.VALOR
          ,SELF.DTEMISSAO
          ,SELF.DTEMISSAO
          ,SELF.DTEMISSAO
          ,SELF.CODBAIXA
          ,SELF.CODFUNCFECHA
          ,SELF.MINUTOFECHA
          ,SELF.HORAFECHA
          ,SELF.DTCXMOT
          ,SELF.NUMTRANSVENDA
          ,SELF.PREST;
 END;
END;
