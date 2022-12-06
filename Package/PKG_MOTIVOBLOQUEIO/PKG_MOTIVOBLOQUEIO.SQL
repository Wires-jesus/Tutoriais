CREATE OR REPLACE PACKAGE PKG_MOTIVOBLOQUEIO IS

  /*****************************************************************************************
                                   CURSORES GLOBAIS
  *****************************************************************************************/
  CURSOR C_CLIENTE(PCODCLI NUMBER) IS
    SELECT PCCLIENT.CLIENTEMONITORADO,
           PCCLIENT.FRETEDESPACHO,
           PCCLIENT.DTVENCALVARA,
           PCCLIENT.DTVENCALVARAFUNC,
           PCCLIENT.DTVENCALVARASUS,
           PCCLIENT.DTVENCALVARAANVISA,
           PCCLIENT.PRAZOMEDIOPLPAG,
           PCCLIENT.CODPLPAG
      FROM PCCLIENT
     WHERE CODCLI = PCODCLI;

  CURSOR C_PEDIDO(PNUMPED NUMBER) IS
    SELECT PCPEDC.FRETEDESPACHO,
           PCPEDC.CODCOB,
           PCPEDC.CODPRACA,
           PCPEDC.CODPLPAG,
           PCPEDC.CONDVENDA,
           PCPEDC.ORIGEMPED,
           PCPEDC.CODCLI,
           PCPEDC.CODUSUR,
           PCPEDC.NUMPED,
           NVL(PCPEDC.VLTOTAL,0) VLTOTAL,
           NVL(PCPEDC.VLENTRADA,0) VLENTRADA,
           NVL(PCPEDC.VLTABELA,0) VLTABELA,
           NVL(PCPEDC.VLATEND,0) VLATEND,
           PCPEDC.CODFILIAL,
           PCPEDC.CODFILIALNF,
           PCPEDC.VLCUSTOFIN,
           PCPEDC.PRAZOMEDIO,
           NVL(PCPLPAG.DESCENTLIMCREDCLI,'N') DESCENTLIMCREDCLI,
           PCPLPAG.MARGEMMIN,
           PCPEDC.PERDESCFIN,
           NVL(PCCOB.COBSUPPLIERCARD, 'N') COBSUPPLIERCARD,
           PCPEDC.TIPOOPER,
           PCPEDC.PERDESC,
           NVL(PCPEDC.BLOQUEIOSUPPLIER, 'N') BLOQUEIOSUPPLIER
      FROM PCPEDC, PCPLPAG, PCCOB
     WHERE NUMPED = PNUMPED
       AND PCPEDC.CODPLPAG = PCPLPAG.CODPLPAG
       AND PCPEDC.CODCOB = PCCOB.CODCOB;

  CURSOR C_PCBLOQUEIO(PNUMPED            NUMBER,
                      PCODCLI            NUMBER,
                      PCONDVENDA         NUMBER,
                      PCODPRACA          NUMBER,
                      PCODPLPAG          NUMBER,
                      PCODFUNC           NUMBER,
                      PCODCOB            VARCHAR2,
                      PFRETEDESPACHO     VARCHAR2,
                      PORIGEMPED         VARCHAR2,
                      PCLIENTEMONITORADO VARCHAR2,
                      PVALORPEDIDO       NUMBER,
                      PCODFILIAL         VARCHAR2) IS

    SELECT CODMOTBLOQUEIO,
           CODMOTIVO,
           (SELECT UPPER(descricao)
              FROM pcmotbloqueio
             WHERE codmotivo = B1.CODMOTIVO) descricao
      FROM PCBLOQUEIO B1
     WHERE ((CodProd IS NULL) OR
           (EXISTS (SELECT 1 FROM PCPEDI WHERE NUMPED = PNUMPED and PCPEDI.CODPROD = B1.CODPROD)))
       AND NVL(CODCLI, PCODCLI) = PCODCLI
       AND NVL(CONDVENDA, PCONDVENDA) = PCONDVENDA
       AND NVL(CODPRACA, PCODPRACA) = PCODPRACA
       AND NVL(CODPLPAG, PCODPLPAG) = PCODPLPAG
       AND NVL(MATRICULAEMPR, PCODFUNC) = PCODFUNC
       AND NVL(CODCOB, PCODCOB) = PCODCOB
--       AND NVL(FRETEDESPACHO, PFRETEDESPACHO) = PFRETEDESPACHO
       AND ((FRETEDESPACHO = PFRETEDESPACHO) OR (NVL(FRETEDESPACHO,'T') = 'T'))
       AND ((ORIGEMPED = PORIGEMPED) OR (ORIGEMPED = 'O'))
       AND ((NVL(B1.clientemonitorado, 'N') = 'N') OR
           ((B1.clientemonitorado = 'S') AND
           (PClientemonitorado = 'S')))
       AND ((PVALORPEDIDO > NVL(VLMAXPEDIDO,PVALORPEDIDO)) OR (VLMAXPEDIDO IS NULL))
       AND (NOT EXISTS (SELECT *
                          FROM PCBLOQUEIOMULT M
                         WHERE M.CODMOTBLOQUEIO = B1.CODMOTBLOQUEIO
                           AND M.TIPO IN (1, 2, 3, 4, 5, 6)))
       OR EXISTS (
            SELECT * FROM PCBLOQUEIO B
                    WHERE ((ORIGEMPED = PORIGEMPED) OR (B.ORIGEMPED = 'O'))
                      AND B1.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO
                      AND NVL(MATRICULAEMPR, PCODFUNC) = PCODFUNC
                      AND ((NVL(B.CLIENTEMONITORADO, 'N') = 'N') OR
                           ((B.CLIENTEMONITORADO = 'S') AND
                           (PCLIENTEMONITORADO = 'S')))
                      AND ((PVALORPEDIDO > NVL(VLMAXPEDIDO,PVALORPEDIDO)) OR (VLMAXPEDIDO IS NULL))
                      AND ((FRETEDESPACHO = PFRETEDESPACHO) OR (NVL(FRETEDESPACHO,'T') = 'T'))
                      AND (NVL(CONDVENDA, PCONDVENDA) = PCONDVENDA)
                      AND EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO )
                      AND (EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 1 AND CODIGOA = PCODFILIAL)
                                  OR (/*PCODFILIAL IS NULL AND  */
                                  NOT EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 1)))
                      AND (EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 2 AND CODIGOA = TO_CHAR(PCODPRACA))
                                  OR (B.CODPRACA IS NULL AND
                                  NOT EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 2)))
                      AND (EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 3 AND CODIGOA = TO_CHAR(PCODCLI))
                                  OR (B.CODCLI IS NULL AND
                                  NOT EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 3)))
                      AND (EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 4 AND CODIGOA = PCODCOB)
                                  OR (B.CODCOB IS NULL AND
                                  NOT EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 4)))
                      AND (EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 5 AND CODIGOA = TO_CHAR(PCODPLPAG))
                                  OR (B.CODPLPAG IS NULL
                                  AND NOT EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 5)))
                      AND (EXISTS(SELECT * FROM PCBLOQUEIOMULT M, PCPEDI WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 6
                                            AND PCPEDI.CODPROD = TO_NUMBER(M.CODIGOA)
                                            AND NUMPED = PNUMPED)
                                  OR (NOT EXISTS(SELECT * FROM PCBLOQUEIOMULT M WHERE M.CODMOTBLOQUEIO = B.CODMOTBLOQUEIO AND M.TIPO = 6)))
                      )
       UNION
       SELECT PCBLOQUEIOSPEDIDO.CODMOTBLOQUEIO,
              PCBLOQUEIOSPEDIDO.CODMOTIVO,
              PCBLOQUEIOSPEDIDO.MOTIVO DESCRICAO
         FROM PCBLOQUEIOSPEDIDO, PCMOTBLOQUEIO
        WHERE PCBLOQUEIOSPEDIDO.NUMPED = PNUMPED
          AND PCBLOQUEIOSPEDIDO.STATUS = 'B'
          AND PCBLOQUEIOSPEDIDO.CODMOTIVO = PCMOTBLOQUEIO.CODMOTIVO(+)
          AND PCBLOQUEIOSPEDIDO.CODMOTBLOQUEIO IS NOT NULL
     ORDER BY CODMOTBLOQUEIO;

  /***********************************************************************************
                            VARIÁVEIS P/ OS CURSORES
  ***********************************************************************************/

  VCCLIENTE    C_CLIENTE%ROWTYPE;
  VCPEDIDO     C_PEDIDO%ROWTYPE;
  VCPCBLOQUEIO C_PCBLOQUEIO%ROWTYPE;


  /***********************************************************************************
                            PERMISSÕES DO USUÁRIO
  ***********************************************************************************/

  TYPE TPermissoes IS TABLE OF NUMBER;
  VCPermissoes TPermissoes;


  PROCEDURE VALIDAMOTIVOSBLOQUEIO(PNUMPED               IN NUMBER,
                                  PCODFUNC              IN NUMBER,
                                  PCODROTINA            IN NUMBER,
                                  PMATRICULAAUTORIZADOR IN NUMBER default 0);

  PROCEDURE VALIDAMOTIVOSBLOQUEIO(VCPEDIDO              C_PEDIDO%ROWTYPE,
                                  PCODFUNC              IN NUMBER,
                                  PCODROTINA            IN NUMBER,
                                  PMATRICULAAUTORIZADOR IN NUMBER default 0);

  PROCEDURE INSERTMOTIVO(PNUMPED         IN NUMBER,
                         PCODMOTIVO      IN NUMBER,
                         PMOTIVO         VARCHAR2,
                         PTIPO           VARCHAR2,
                         PCODMOTBLOQUEIO IN NUMBER DEFAULT NULL);

  FUNCTION RETORNALISTAMOTIVOS(PNUMPED IN NUMBER) RETURN VARCHAR2;

END;
