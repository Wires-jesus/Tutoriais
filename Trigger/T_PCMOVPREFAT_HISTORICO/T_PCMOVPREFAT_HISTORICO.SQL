CREATE OR REPLACE TRIGGER T_PCMOVPREFAT_HISTORICO BEFORE INSERT
       ON PCMOVPREFAT REFERENCING OLD AS OLD NEW AS NEW FOR EACH ROW
DECLARE
  /************************************************************************************************
  PROPOSITO: TRIGGER PARA GRAVAÇÃO DOS DADOS DE CADASTRO (HISTORICO DE MOVIMENTAÇÃO)
  ROTINA: PACOTE
  UTILIZADA POR: ROTINAS QUE FAZEM INCLUSÃO NA PCNFSAID, PCNFENT, PCMOV
  ------------------------------------------------------------------------------------------------
  DATA        RESPONSAVEL     DESCRICAO
  ----------  --------------  --------------------------------------------------------------------*
  11/04/2018  JEAN.TEIXEIRA   Trigger criada com base T_PCMOV_HISTORICO
  ************************************************************************************************/
  V_UFFILIAL              PCFILIAL.UF%TYPE;
  V_USATRIBENTPORUF       PCCONSUM.USATRIBENTPORUF%TYPE;
  V_CODPRODANTUTICAD      VARCHAR2(20);
  V_DTINICODPRODANTUTICAD DATE;
  VUSAPISCOFINSPORFILIAL  VARCHAR2(1);
  VPISCOFINSRETIDO        VARCHAR2(1);
 ------------------------------------------------------------------------------------------------
  -- FUNÇÕES GERAR LOG SE OCORRER UM ERRO
  ------------------------------------------------------------------------------------------------

  PROCEDURE GERAR_LOG(PMENSAGEM_ERRO IN VARCHAR2) IS
  BEGIN
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2)
    VALUES
      (SYSDATE,
       'PCMOVPREFAT',
       'INDEFINIDA',
       'A',
       'ERRO NA INCLUSÃO DO REGISTRO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'ERRO TRIGGER HISTORICO: NUMTRANSVENDA: ' ||
       TO_CHAR(NVL(:NEW.NUMTRANSVENDA, 0)) || ' NUMNOTA: ' ||
       TO_CHAR(NVL(:NEW.NUMNOTA, 0)) || ' CODPROD: ' || :NEW.CODPROD,
       SUBSTR('ERRO ORIGINAL: ' || PMENSAGEM_ERRO, 1, 100));
  END;
BEGIN
 ------------------------------------------------------------------------------------
  BEGIN
    SELECT NVL(USATRIBENTPORUF, 'N')
      INTO V_USATRIBENTPORUF
      FROM PCCONSUM;
  EXCEPTION
    WHEN OTHERS THEN
      V_USATRIBENTPORUF       := 'N';
  END;
  ------------------------------------------------------------------------------------
    -- BUSCAR PARAMETROS DE TRIBUTAÇÃO DE PIS/COFINS POR FILIAL
  BEGIN
     SELECT DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('USAPISCOFINSPORFILIAL',
                                                     NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)),
                      'S'),
                  'S',
                  (SELECT NVL(USAPISCOFINSPORFILIAL, 'N') FROM PCCONSUM),
                  'N')
      INTO VUSAPISCOFINSPORFILIAL
      FROM DUAL;
  EXCEPTION
    WHEN OTHERS THEN
      VUSAPISCOFINSPORFILIAL := 'N';
  END;   
  ----------------------------------------------------------------------------------
  FOR DADOS IN (SELECT DISTINCT P.PERICM,
                                (SELECT MAX(TB.CODICM)
                                   FROM PCTABPR  PR,
                                        PCTRIBUT TB
                                  WHERE PR.CODPROD = :NEW.CODPROD
                                    AND PR.NUMREGIAO = FL.NUMREGIAOPADRAO
                                    AND TB.CODST = PR.CODST) ALIQICMSVIGENTE,
                                (SELECT VLPAUTASEMIVA
                                   FROM PCTRIBUT
                                  WHERE CODST = :NEW.CODST) VLPAUTASEMIVA,
                                (SELECT PERCIVAPAUTA
                                   FROM PCTRIBUT
                                  WHERE CODST = :NEW.CODST) PERCIVAPAUTA,
                                P.UNIDADE,
                                P.DESCRICAO,
                                P.DESCRICAO1,
                                D.TIPOMERC TIPOMERCDEPTO,
                                P.TIPOMERC,
                                P.CODFORNEC CODFORNECPROD,
                                F.TIPOFORNEC,
                                P.NBM,
                                P.DV,
                                (SELECT IVA
                                   FROM PCTRIBUT
                                  WHERE CODST = :NEW.CODST) IVATRIBUT,
                                P.CODPRODSINTEGRA,
                                P.IMPORTADO,
                                CASE WHEN ((PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_UTILIZAVENDAPOREMBALAGEM',  NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)) = 'S')
                                           AND (:NEW.CODOPER NOT IN ('E', 'SD'))) THEN
                                  (SELECT PCE.EMBALAGEM FROM PCEMBALAGEM PCE WHERE PCE.CODAUXILIAR = :NEW.CODAUXILIAR AND PCE.CODFILIAL = NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL) AND PCE.CODPROD = :NEW.CODPROD)
                                ELSE
                                  CASE WHEN :NEW.TIPOEMBALAGEMPEDIDO = 'M' THEN
                                            P.EMBALAGEMMASTER
                                       ELSE P.EMBALAGEM
                                  END
                                END AS EMBALAGEM,
                                P.CLASSIFICFISCAL,
                                P.CODPASSEFISCAL,
                                P.CODGENEROFISCAL,
                                P.PASSELIVRE,
                                P.CODAUXILIAR,
                                (SELECT MAX(CAIXA)
                                   FROM PCNFSAIDPREFAT
                                  WHERE NUMTRANSVENDA = :NEW.NUMTRANSVENDA) NUMCAIXA,
                                (SELECT CODECF
                                   FROM PCTRIBUT
                                  WHERE CODST = :NEW.CODST) CODECF,
                                P.PESOLIQ,
                                P.PESOBRUTO,
                                P.VOLUME,
                                P.QTUNIT,
                                P.QTUNITCX,
                                P.RUA,
                                F.ESTADO UFFORNEC,
                                P.IVARESSARC,
                                P.ICMSRESSARC,
                                P.ALIQAVULSADARE,
                                P.PERCIVAICMANTECIP,
                                P.PERCALIQINTICMANTECIP,
                                P.PERCALIQEXTICMANTECIP,
                                P.TRIBFEDERAL,
                                P.TIPOTRIBUTMEDIC,
                                (SELECT MAX(VLPAUTAICMSANTEC)
                                   FROM PCNFENT      NE,
                                        PCFORNEC     FE,
                                        PCTABTRIBENT TE
                                  WHERE NE.NUMTRANSENT = :NEW.NUMTRANSENT
                                    AND FE.CODFORNEC = NE.CODFORNEC
                                    AND NE.ESPECIE = 'NF'
                                    AND TE.UFORIGEM = FE.ESTADO
                                    AND TE.UFDESTINO = FL.UF
                                    AND TE.CODPROD = :NEW.CODPROD) VLPAUTAICMSANTEC,
                                DECODE(V_USATRIBENTPORUF, 'S',
                                       NVL(TUF.CALCCREDIPI,
                                            NVL(PF.CALCCREDIPI, P.CALCCREDIPI)),
                                       NVL(PF.CALCCREDIPI, P.CALCCREDIPI)) CALCCREDIPI,
                                C.USATRIBENTPORUF,
                                P.CODPRODRELEV,
                                P.CODPRODDNF,
                                P.CAPVOLDNF,
                                P.FATORCONVDNF,
                                (SELECT MAX(CODSITTRIBIPIENT)
                                   FROM PCTRIBIPI
                                  WHERE CODFILIAL = FL.CODIGO
                                    AND CODPROD = P.CODPROD) CODSITTRIBIPIENT,
                                (SELECT MAX(CODSITTRIBIPISAID)
                                   FROM PCTRIBIPI
                                  WHERE CODFILIAL = FL.CODIGO
                                    AND CODPROD = P.CODPROD) CODSITTRIBIPISAID,
                                P.CODINTERNO,
                                P.DTINICODPRODANTUTICAD,
                                P.CODPRODANTUTICAD,
                                P.FUNDAPIANO,
                                P.PISCOFINSRETIDO PISCOFINSRETIDO_PROD,
                                PF.PISCOFINSRETIDO PISCOFINSRETIDO_FILIAL
                  FROM PCPRODUT P,
                       PCFORNEC F,
                       PCDEPTO D,
                       PCFILIAL FL,
                       PCCONSUM C,
                       (SELECT UFORIGEM,
                               CALCCREDIPI
                          FROM PCTABTRIBENT
                         WHERE UFDESTINO = V_UFFILIAL
                           AND CODPROD = :NEW.CODPROD) TUF,
                       (SELECT CODPROD,
                               CALCCREDIPI,
                               PISCOFINSRETIDO
                          FROM PCPRODFILIAL
                         WHERE CODFILIAL =
                               NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
                           AND CODPROD = :NEW.CODPROD) PF
                 WHERE P.CODPROD = :NEW.CODPROD
                   AND P.CODFORNEC = F.CODFORNEC(+)
                   AND P.CODEPTO = D.CODEPTO(+)
                   AND PF.CODPROD(+) = P.CODPROD
                   AND F.ESTADO = TUF.UFORIGEM(+)
                   AND FL.CODIGO(+) = NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL))
  LOOP
    :NEW.PERICM          := NVL(:NEW.PERICM, DADOS.PERICM);
    :NEW.ALIQICMSVIGENTE := NVL(:NEW.ALIQICMSVIGENTE, DADOS.ALIQICMSVIGENTE);
    :NEW.UNIDADE         := NVL(:NEW.UNIDADE, DADOS.UNIDADE);
    :NEW.DESCRICAO       := NVL(:NEW.DESCRICAO, DADOS.DESCRICAO);
    :NEW.DESCRICAO1      := NVL(:NEW.DESCRICAO1, DADOS.DESCRICAO1);
    :NEW.TIPOMERCDEPTO   := NVL(:NEW.TIPOMERCDEPTO, DADOS.TIPOMERCDEPTO);
    :NEW.TIPOMERC        := NVL(:NEW.TIPOMERC, DADOS.TIPOMERC);
    :NEW.CODFORNECPROD   := NVL(:NEW.CODFORNECPROD, DADOS.CODFORNECPROD);
    :NEW.TIPOFORNEC      := NVL(:NEW.TIPOFORNEC, DADOS.TIPOFORNEC);
    :NEW.NBM             := NVL(:NEW.NBM, DADOS.NBM);
    :NEW.DV              := NVL(:NEW.DV, DADOS.DV);
    :NEW.IVATRIBUT       := NVL(:NEW.IVATRIBUT, DADOS.IVATRIBUT);
    :NEW.CODPRODSINTEGRA := NVL(:NEW.CODPRODSINTEGRA, DADOS.CODPRODSINTEGRA);
    :NEW.IMPORTADO       := NVL(:NEW.IMPORTADO, DADOS.IMPORTADO);
    :NEW.EMBALAGEM       := NVL(:NEW.EMBALAGEM, DADOS.EMBALAGEM);
    :NEW.CLASSIFICFISCAL := NVL(:NEW.CLASSIFICFISCAL, DADOS.CLASSIFICFISCAL);
    :NEW.CODPASSEFISCAL  := NVL(:NEW.CODPASSEFISCAL, DADOS.CODPASSEFISCAL);
    :NEW.CODGENEROFISCAL := NVL(:NEW.CODGENEROFISCAL, DADOS.CODGENEROFISCAL);
    :NEW.PASSELIVRE      := NVL(:NEW.PASSELIVRE, DADOS.PASSELIVRE);
    :NEW.CODAUXILIAR     := NVL(:NEW.CODAUXILIAR, DADOS.CODAUXILIAR);
    :NEW.CODINTERNO      := NVL(:NEW.CODINTERNO, DADOS.CODINTERNO);
    ------------------------------------------------------------------------------------
    ---- GERAR A DATA DA PRIMEIRA MOVIMENTAÇÃO DO PRODUTO APÓS IMPLANTAÇÃO DO WINTHOR.
    ---- ISSO APENAS PARA EMPRESAS ONDE MUDARAM O CÓDIGO DO PRODUTO DO SISTEMA ANTERIOR
    ---- PARA O WINTHOR. TABELA PCPRODUT. SOLICITAÇÃO - HIS.00160.2014 - 07/02/2014
    ------------------------------------------------------------------------------------
    IF ((DADOS.CODPRODANTUTICAD IS NOT NULL) AND (DADOS.DTINICODPRODANTUTICAD <= :NEW.DTMOV)) THEN
       BEGIN
          UPDATE PCPRODUT SET DTPRIMOVNOVCODPROD = :NEW.DTMOV
          WHERE CODPROD = :NEW.CODPROD
            AND DTPRIMOVNOVCODPROD IS NULL
            AND CODPRODANTUTICAD IS NOT NULL
            AND DTINICODPRODANTUTICAD IS NOT NULL;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
    END IF;
    ------------------------------------------------------------------------------------
    ---- GERAR A DATA DA PRIMEIRA MOVIMENTAÇÃO DO PRODUTO APÓS IMPLANTAÇÃO DO WINTHOR.
    ---- ISSO APENAS PARA EMPRESAS ONDE MUDARAM O CÓDIGO DO PRODUTO DO SISTEMA ANTERIOR
    ---- PARA O WINTHOR. TABELA PCPRODFILIAL. SOLICITAÇÃO - HIS.001715.2014 - 04/06/2014
    ------------------------------------------------------------------------------------
    SELECT CODPRODANTUTICAD,
           DTINICODPRODANTUTICAD
    INTO V_CODPRODANTUTICAD,
         V_DTINICODPRODANTUTICAD
    FROM PCPRODFILIAL
    WHERE CODFILIAL = NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
      AND CODPROD = :NEW.CODPROD;

    IF ((V_CODPRODANTUTICAD IS NOT NULL) AND (V_DTINICODPRODANTUTICAD <= :NEW.DTMOV)) THEN
    BEGIN
      UPDATE PCPRODFILIAL SET DTPRIMOVNOVCODPROD = :NEW.DTMOV
      WHERE CODFILIAL = NVL(:NEW.CODFILIALNF, :NEW.CODFILIAL)
        AND CODPROD = :NEW.CODPROD
        AND DTPRIMOVNOVCODPROD IS NULL
        AND CODPRODANTUTICAD IS NOT NULL
        AND DTINICODPRODANTUTICAD IS NOT NULL;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
    END IF;
    -----------------------------------------------------------
    BEGIN
      SELECT NVL(:NEW.CODECF,
                 MAX(CASE
                        WHEN USAINDICEECF = 'S' THEN
                         (SELECT CODECF
                            FROM PCINDICEECF
                           WHERE NUMCAIXA = DADOS.NUMCAIXA
                             AND INDICE = DADOS.CODECF)
                        ELSE
                         DADOS.CODECF
                      END))
        INTO :NEW.CODECF
        FROM PCCAIXA
       WHERE NUMCAIXA = DADOS.NUMCAIXA;
      -----------------------------------------------------------
    EXCEPTION
      WHEN OTHERS THEN
        :NEW.CODECF := NVL(:NEW.CODECF, DADOS.CODECF);
    END;

    :NEW.IVA                   := NVL(:NEW.IVA, DADOS.PERCIVAPAUTA);
    :NEW.PAUTA                 := NVL(:NEW.PAUTA, DADOS.VLPAUTASEMIVA);
    :NEW.PESOLIQ               := NVL(:NEW.PESOLIQ, DADOS.PESOLIQ);
    :NEW.PESOBRUTO             := NVL(:NEW.PESOBRUTO, DADOS.PESOBRUTO);
    :NEW.VOLUME                := NVL(:NEW.VOLUME, DADOS.VOLUME);
    :NEW.QTUNIT                := NVL(:NEW.QTUNIT, DADOS.QTUNIT);
    :NEW.QTUNITCX              := NVL(:NEW.QTUNITCX, DADOS.QTUNITCX);
    :NEW.RUA                   := NVL(:NEW.RUA, DADOS.RUA);
    :NEW.UFFORNEC              := NVL(:NEW.UFFORNEC, DADOS.UFFORNEC);
    :NEW.IVARESSARC            := NVL(:NEW.IVARESSARC, DADOS.IVARESSARC);
    :NEW.ICMSRESSARC           := NVL(:NEW.ICMSRESSARC, DADOS.ICMSRESSARC);
    :NEW.ALIQAVULSADARE        := NVL(:NEW.ALIQAVULSADARE,
                                      DADOS.ALIQAVULSADARE);
    :NEW.PERCIVAICMANTECIP     := NVL(:NEW.PERCIVAICMANTECIP,
                                      DADOS.PERCIVAICMANTECIP);
    :NEW.PERCALIQINTICMANTECIP := NVL(:NEW.PERCALIQINTICMANTECIP,
                                      DADOS.PERCALIQINTICMANTECIP);
    :NEW.PERCALIQEXTICMANTECIP := NVL(:NEW.PERCALIQEXTICMANTECIP,
                                      DADOS.PERCALIQEXTICMANTECIP);
    :NEW.TRIBFEDERAL           := NVL(:NEW.TRIBFEDERAL, DADOS.TRIBFEDERAL);
    :NEW.TIPOTRIBUTMEDIC       := NVL(:NEW.TIPOTRIBUTMEDIC,
                                      DADOS.TIPOTRIBUTMEDIC);
    :NEW.VLPAUTAICMSANTEC      := NVL(:NEW.VLPAUTAICMSANTEC,
                                      DADOS.VLPAUTAICMSANTEC);
    :NEW.CALCCREDIPI           := NVL(:NEW.CALCCREDIPI, DADOS.CALCCREDIPI);
    :NEW.CODPRODRELEV          := NVL(:NEW.CODPRODRELEV, DADOS.CODPRODRELEV);
    :NEW.CODPRODDNF            := NVL(:NEW.CODPRODDNF, DADOS.CODPRODDNF);
    :NEW.CAPVOLDNF             := NVL(:NEW.CAPVOLDNF, DADOS.CAPVOLDNF);
    :NEW.FATORCONVDNF          := NVL(:NEW.FATORCONVDNF, DADOS.FATORCONVDNF);
    :NEW.HISTORICO             := 'S';
    :NEW.FUNDAPIANO            := NVL(:NEW.FUNDAPIANO, DADOS.FUNDAPIANO);
    
    ------------------------------------------------------------------------------------    
    -- BUSCANDO TRIBUTAÇÃO POR UF SE FOR O CASO
    if (VUSAPISCOFINSPORFILIAL = 'S')
    then
      VPISCOFINSRETIDO     := NVL(DADOS.PISCOFINSRETIDO_FILIAL, NVL(DADOS.PISCOFINSRETIDO_PROD, 'N'));
    else
      VPISCOFINSRETIDO     := NVL(DADOS.PISCOFINSRETIDO_PROD, 'N');
    end if;
    VPISCOFINSRETIDO := NVL(VPISCOFINSRETIDO, 'N');
    
    :NEW.PISCOFINSRETIDO   := NVL(:NEW.PISCOFINSRETIDO, VPISCOFINSRETIDO);    
    ------------------------------------------------------------------------------------
  END LOOP;

  -- SE FOR SAÍDA ********************************************************************
  IF :NEW.NUMTRANSVENDA > 0
  THEN
    ---- RECALCULANDO VALORES ----------------------------------------------------------
    :NEW.BCISS := :NEW.PUNITCONT - NVL(:NEW.VLIPI, 0) - NVL(:NEW.ST, 0);

    ---- RECALCULANDO CABEÇALHO --------------------------------------------------------
    UPDATE PCNFSAIDPREFAT
       SET CODFISCALNF = LEAST(NVL(CODFISCALNF, 9999), :NEW.CODFISCAL)
     WHERE NUMTRANSVENDA = :NEW.NUMTRANSVENDA;
  END IF;
  ------------------------------------------------------------------------------------
  ---- ATUALIZAR SEQMOV---------------------------------------------------------------
  IF INSERTING THEN
    BEGIN
      SELECT NVL(:NEW.SEQMOV, DFSEQ_PCMOV_SEQMOV.NEXTVAL)
        INTO :NEW.SEQMOV
        FROM DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;
  ------------------------------------------------------------------------------------
EXCEPTION

  WHEN OTHERS THEN
    BEGIN
      GERAR_LOG(SQLERRM);
    END;

END;
