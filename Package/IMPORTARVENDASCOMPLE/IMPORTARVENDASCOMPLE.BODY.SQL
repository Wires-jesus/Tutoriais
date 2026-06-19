

CREATE OR REPLACE PACKAGE BODY IMPORTARVENDASCOMPLE IS
   VGLOBAL_ORIGEMPED          PCPEDC.ORIGEMPED%TYPE;
   VGLOBAL_CODPLPAG           PCPEDC.CODPLPAG%TYPE;
   VGLOBAL_CODFILIAL          PCPEDC.CODFILIAL%TYPE;
   VGLOBAL_USATRIBUTACAOPORUF VARCHAR2(1);
   VGLOBAL_NUMREGIAO          PCREGIAO.NUMREGIAO%TYPE;
   VGLOBAL_OBSENTREGA4        PCPEDCTEMP.OBSENTREGA4%TYPE;
   VGLOBAL_CODTRANSP          PCPEDCTEMP.CODTRANSP%TYPE;
   VGLOBAL_TIPOVENDA          PCPLPAG.TIPOVENDA%TYPE;
   VGLOBAL_CODFORNECFRETE     PCPEDCTEMP.CODFORNECFRETE%TYPE;
   VGLOBAL_CODENDENTCLI       PCPEDC.CODENDENTCLI%TYPE;
   VGLOBAL_RETORNO_ESTOQUE    VARCHAR2(4000);
   VPRAZO1                    PCPLPAG.PRAZO1%TYPE;
   VPRAZO2                    PCPLPAG.PRAZO2%TYPE;
   VPRAZO3                    PCPLPAG.PRAZO3%TYPE;
   VPRAZO4                    PCPLPAG.PRAZO4%TYPE;
   VPRAZO5                    PCPLPAG.PRAZO5%TYPE;
   VPRAZO6                    PCPLPAG.PRAZO6%TYPE;
   VPRAZO7                    PCPLPAG.PRAZO7%TYPE;
   VPRAZO8                    PCPLPAG.PRAZO8%TYPE;
   VPRAZO9                    PCPLPAG.PRAZO9%TYPE;
   VPRAZO10                   PCPLPAG.PRAZO10%TYPE;
   VPRAZO11                   PCPLPAG.PRAZO11%TYPE;
   VPRAZO12                   PCPLPAG.PRAZO12%TYPE;
   VNUMDIAS                   PCPLPAG.NUMDIAS%TYPE;
   VGLOBAL_VLCUSTOFIN         PCPEDC.VLCUSTOFIN%TYPE;
   VGLOBAL_VLCUSTOREAL        PCPEDC.VLCUSTOREAL%TYPE;
   VGLOBAL_VLCUSTOREP         PCPEDC.VLCUSTOREP%TYPE;
   VGLOBAL_VLCUSTOCONT        PCPEDC.VLCUSTOCONT%TYPE;
   VGLOBAL_OBS2               PCPEDC.OBS2%TYPE;
   VVLIPI_PTABELA             PCPEDI.VLIPI%TYPE;
   VUTILIZOUMOTORCALCULO      PCPEDI.UTILIZOUMOTORCALCULO%TYPE;
   VUNILEVER                  VARCHAR2(1); -- Se for "S" é gerado pela rotina 2697 da UNILEVER

   FUNCTION FUNC_GET_CODMOTIVO RETURN NUMBER IS
      VCODMOTIVO PCMOTBLOQUEIO.CODMOTIVO%TYPE;
   BEGIN
      VCODMOTIVO := 25;
   
      BEGIN
         SELECT CODMOTIVO
         INTO   VCODMOTIVO
         FROM   PCMOTBLOQUEIO
         WHERE  DESCRICAO = 'PEDIDOS DA INTEGRACAO';
      EXCEPTION
         WHEN OTHERS THEN
            VCODMOTIVO := 25;
      END;
   
      RETURN VCODMOTIVO;
   END;

   FUNCTION FUNC_TIPOCONTACORRENTE
   (
      P_CONDVENDA NUMBER,
      P_VLTOTPED  FLOAT,
      P_VLTOTTAB  FLOAT
   ) RETURN PCPEDC.TIPOCONTACORRENTE%TYPE IS
      V_TIPOCONTACORRENTE PCPEDC.TIPOCONTACORRENTE%TYPE;
   BEGIN
      IF P_CONDVENDA = 5
      THEN
         V_TIPOCONTACORRENTE := NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTEBONIF',
                                                                       '99',
                                                                       NULL),
                                    NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTEFV',
                                                                           '99',
                                                                           NULL),
                                        FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTE',
                                                                           '99',
                                                                           NULL)));
      ELSE
         IF (P_VLTOTPED = P_VLTOTTAB)
         THEN
            V_TIPOCONTACORRENTE := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTE',
                                                                      '99',
                                                                      NULL);
         ELSE
            V_TIPOCONTACORRENTE := NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTEFV',
                                                                          '99',
                                                                          NULL),
                                       FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('TIPOCONTACORRENTE',
                                                                          '99',
                                                                          NULL));
         END IF;
      END IF;
   
      RETURN V_TIPOCONTACORRENTE;
   END FUNC_TIPOCONTACORRENTE;

   FUNCTION FUNC_CALCULARPERDESCITEM
   (
      P_PTABELA     IN PCPEDI.PTABELA%TYPE,
      P_PVENDA      IN PCPEDI.PVENDA%TYPE,
      P_INTEGRADORA IN PCPEDC.INTEGRADORA%TYPE
   ) RETURN NUMBER IS
      VNPERDESC NUMBER;
   BEGIN
      IF P_INTEGRADORA = 4
      THEN
         IF ROUND(P_PTABELA, 2) <> 0
         THEN
            VNPERDESC := ((ROUND(P_PTABELA, 2) - ROUND(P_PVENDA, 2)) /
                         ROUND(P_PTABELA, 2)) * 100;
         ELSE
            VNPERDESC := 0;
         END IF;
      ELSE
         IF NVL(P_PTABELA, 0) <> 0
         THEN
            VNPERDESC := ((P_PTABELA - P_PVENDA) / P_PTABELA) * 100;
         ELSE
            VNPERDESC := 0;
         END IF;
      END IF;
   
      VNPERDESC := ROUND(VNPERDESC, 6);
      RETURN VNPERDESC;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN 0;
   END FUNC_CALCULARPERDESCITEM;

   FUNCTION FUNC_BUSCAR_RCA_B2B_ECOMMERCE
   (
      P_CODCLI      IN PCCLIENT.CODCLI%TYPE,
      P_CODFILIAL   IN PCFILIAL.CODIGO%TYPE,
      P_INTEGRADORA IN PCPEDC.INTEGRADORA%TYPE
   ) RETURN PCUSUARI.CODUSUR%TYPE IS
      VRETORNO PCUSUARI.CODUSUR%TYPE;
      VPARAM   VARCHAR2(1);
   BEGIN
      BEGIN
         SELECT NVL(VALOR, 'N')
         INTO   VPARAM
         FROM   PCPARAMFILIAL
         WHERE  NOME = 'GRAVAPEDRCAINTEGB2BECOMMERCE' AND
                CODFILIAL = P_CODFILIAL;
      EXCEPTION
         WHEN OTHERS THEN
            VPARAM := 'N';
      END;
   
      IF VPARAM = 'N'
      THEN
         RETURN 0;
      END IF;
   
      BEGIN
         SELECT NVL(PCCLIENT.CODUSUR1, 0)
         INTO   VRETORNO
         FROM   PCECOMMERCEB2BRCA, PCCLIENT
         WHERE  PCECOMMERCEB2BRCA.CODUSUR = PCCLIENT.CODUSUR1 AND
                PCECOMMERCEB2BRCA.CODFILIAL = P_CODFILIAL AND
                PCECOMMERCEB2BRCA.TIPOINTEGRACAO = P_INTEGRADORA AND
                PCCLIENT.CODCLI = P_CODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VRETORNO := 0;
      END;
   
      IF VRETORNO > 0
      THEN
         RETURN VRETORNO;
      END IF;
   
      BEGIN
         SELECT NVL(PCCLIENT.CODUSUR2, 0)
         INTO   VRETORNO
         FROM   PCECOMMERCEB2BRCA, PCCLIENT
         WHERE  PCECOMMERCEB2BRCA.CODUSUR = PCCLIENT.CODUSUR2 AND
                PCECOMMERCEB2BRCA.CODFILIAL = P_CODFILIAL AND
                PCECOMMERCEB2BRCA.TIPOINTEGRACAO = P_INTEGRADORA AND
                PCCLIENT.CODCLI = P_CODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VRETORNO := 0;
      END;
   
      IF VRETORNO > 0
      THEN
         RETURN VRETORNO;
      END IF;
   
      BEGIN
         SELECT NVL(PCCLIENT.CODUSUR3, 0)
         INTO   VRETORNO
         FROM   PCECOMMERCEB2BRCA, PCCLIENT
         WHERE  PCECOMMERCEB2BRCA.CODUSUR = PCCLIENT.CODUSUR3 AND
                PCECOMMERCEB2BRCA.CODFILIAL = P_CODFILIAL AND
                PCECOMMERCEB2BRCA.TIPOINTEGRACAO = P_INTEGRADORA AND
                PCCLIENT.CODCLI = P_CODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VRETORNO := 0;
      END;
   
      IF VRETORNO > 0
      THEN
         RETURN VRETORNO;
      END IF;
   
      BEGIN
         SELECT NVL(PCUSURCLI.CODUSUR, 0)
         INTO   VRETORNO
         FROM   PCECOMMERCEB2BRCA, PCUSURCLI
         WHERE  PCECOMMERCEB2BRCA.CODUSUR = PCUSURCLI.CODUSUR AND
                PCECOMMERCEB2BRCA.CODFILIAL = P_CODFILIAL AND
                PCECOMMERCEB2BRCA.TIPOINTEGRACAO = P_INTEGRADORA AND
                PCUSURCLI.CODCLI = P_CODCLI AND
                ROWNUM <= 1;
      EXCEPTION
         WHEN OTHERS THEN
            VRETORNO := 0;
      END;
   
      IF VRETORNO > 0
      THEN
         RETURN VRETORNO;
      END IF;
   
      BEGIN
         SELECT NVL(PCECOMMERCEB2B.CODUSUR, 0)
         INTO   VRETORNO
         FROM   PCECOMMERCEB2B
         WHERE  PCECOMMERCEB2B.CODFILIAL = P_CODFILIAL AND
                PCECOMMERCEB2B.TIPOINTEGRACAO = P_INTEGRADORA;
      EXCEPTION
         WHEN OTHERS THEN
            VRETORNO := 0;
      END;
   
      IF VRETORNO > 0
      THEN
         RETURN VRETORNO;
      END IF;
   
      IF P_INTEGRADORA = 29
      THEN
         BEGIN
            SELECT NVL(PCECOMMERCEUNILEVER.CODUSUR, 0)
            INTO   VRETORNO
            FROM   PCECOMMERCEUNILEVER
            WHERE  PCECOMMERCEUNILEVER.CODFILIAL = P_CODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VRETORNO := 0;
         END;
      
         IF VRETORNO > 0
         THEN
            RETURN VRETORNO;
         END IF;
      END IF;
   
      BEGIN
         SELECT NVL(PCCLIENT.CODUSUR1, 0)
         INTO   VRETORNO
         FROM   PCCLIENT
         WHERE  PCCLIENT.CODCLI = P_CODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VRETORNO := 0;
      END;
   
      IF VRETORNO > 0
      THEN
         RETURN VRETORNO;
      END IF;
   
      RETURN 0;
   END FUNC_BUSCAR_RCA_B2B_ECOMMERCE;

   PROCEDURE OBTERINTERMEDIADOR
   (
      PCODFILIAL         IN PCFILIAL.CODIGO%TYPE,
      PINTEGRADORA       IN PCPEDCTEMP.INTEGRADORA%TYPE,
      PCNPJINTERMEDIADOR OUT PCPEDCTEMP.CNPJINTERMEDIADOR%TYPE,
      PDESCINTERMEDIADOR OUT PCPEDCTEMP.DESCINTERMEDIADOR%TYPE
   ) IS
   BEGIN
      IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
         BEGIN
            SELECT CNPJ_INTERMEDIADOR, INTERMEDIADOR
            INTO   PCNPJINTERMEDIADOR, PDESCINTERMEDIADOR
            FROM   PCECOMMERCEB2B
            WHERE  CODFILIAL = PCODFILIAL AND
                   TIPOINTEGRACAO = PINTEGRADORA AND
                   ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS THEN
               PCNPJINTERMEDIADOR := NULL;
               PDESCINTERMEDIADOR := NULL;
         END;
      
         IF (PINTEGRADORA = 29) AND
            (PCNPJINTERMEDIADOR IS NULL OR PDESCINTERMEDIADOR IS NULL)
         THEN
            BEGIN
               SELECT CNPJ_INTERMEDIADOR, INTERMEDIADOR
               INTO   PCNPJINTERMEDIADOR, PDESCINTERMEDIADOR
               FROM   PCECOMMERCEUNILEVER
               WHERE  CODFILIAL = PCODFILIAL AND
                      ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS THEN
                  PCNPJINTERMEDIADOR := NULL;
                  PDESCINTERMEDIADOR := NULL;
            END;
         END IF;
      END IF;
   END OBTERINTERMEDIADOR;

   PROCEDURE CALCULARVALORES_ST
   (
      PCODFILIAL         IN PCFILIAL.CODIGO%TYPE,
      PCODFILIALNF       IN PCFILIAL.CODIGO%TYPE,
      PCODFILIALRETIRA   IN PCFILIAL.CODIGO%TYPE,
      PCODCLI            IN PCCLIENT.CODCLI%TYPE,
      PCODPLPAG          IN PCPEDC.CODPLPAG%TYPE,
      PCODPROD           IN PCPRODUT.CODPROD%TYPE,
      PCODAUXILIAR       IN PCPRODUT.CODAUXILIAR%TYPE,
      PCONDVENDA         IN PCPEDC.CONDVENDA%TYPE,
      PVENDA_SEMIMPOSTOS IN NUMBER,
      PBASEST            OUT PCPEDI.BASEICST%TYPE,
      PST                OUT PCPEDI.ST%TYPE,
      PVLFECP            OUT PCPEDI.VLFECP%TYPE,
      PBASEFECP          OUT PCPEDI.VLBASEFCPST%TYPE,
      PALIQFECP          OUT PCPEDI.ALIQFCP%TYPE
   ) IS
   BEGIN
      BEGIN
         SELECT BASEST, ST, VLRFECP, BASEFECP, ALIQFECP
         INTO   PBASEST, PST, PVLFECP, PBASEFECP, PALIQFECP
         FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_ST(PCODFILIAL, --01
                                                 PCODFILIALNF, --02
                                                 PCODFILIALRETIRA, --03
                                                 PCODCLI, --04
                                                 PCODPLPAG, --05
                                                 PCODPROD, --06
                                                 PCODAUXILIAR, --07
                                                 PCONDVENDA, --08
                                                 'N', --09
                                                 PVENDA_SEMIMPOSTOS, --10
                                                 0, --11
                                                 'N', --12
                                                 0, --13
                                                 0, --14
                                                 0, --15
                                                 NULL, --16
                                                 'S', --17
                                                 'N', --18
                                                 'T', --19
                                                 'N', --20
                                                 0, --21
                                                 'N', --22
                                                 0, --23
                                                 NULL, --24
                                                 'I', --25
                                                 NULL, --26
                                                 NULL --27
                                                 ));
      EXCEPTION
         WHEN OTHERS THEN
            PBASEST   := 0;
            PST       := 0;
            PVLFECP   := 0;
            PBASEFECP := 0;
            PALIQFECP := 0;
      END;
   END CALCULARVALORES_ST;

   PROCEDURE IMPORTAR_PEDIDO_WEB_CODUSUR
   (
      PINTEGRADORA IN NUMBER,
      PNUMPEDWEB   NUMBER,
      PCODCLI      IN PCCLIENT.CODCLI%TYPE
   ) IS
      VCODUSUR   PCUSUARI.CODUSUR%TYPE;
      VPARAM     VARCHAR2(1);
      VCODFILIAL PCFILIAL.CODIGO%TYPE;
      VNUMPED    PCPEDC.NUMPED%TYPE;
   BEGIN
      IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
         --Unilever
         BEGIN
            SELECT CODFILIAL, NVL(NUMPED, -1) AS NUMPED
            INTO   VCODFILIAL, VNUMPED
            FROM   PCPEDCTEMP
            WHERE  NUMPEDWEB = PNUMPEDWEB
			AND ROWNUM <= 1;
         EXCEPTION
            WHEN OTHERS THEN
               VCODFILIAL := NULL;
         END;
      
         IF NOT VCODFILIAL IS NULL
         THEN
            VCODUSUR := FUNC_BUSCAR_RCA_B2B_ECOMMERCE(PCODCLI,
                                                      VCODFILIAL,
                                                      PINTEGRADORA);
         ELSE
            VCODUSUR := 0;
         END IF;
      
         IF VCODUSUR > 0
         THEN
            UPDATE PCPEDCTEMP
            SET    CODUSUR = VCODUSUR
            WHERE  NUMPEDWEB = PNUMPEDWEB AND
                   INTEGRADORA = PINTEGRADORA;
         
            UPDATE PCPEDITEMP
            SET    CODUSUR = VCODUSUR
            WHERE  NUMPEDWEB = PNUMPEDWEB AND
                   INTEGRADORA = PINTEGRADORA;
         
            UPDATE PCPEDC SET CODUSUR = VCODUSUR WHERE NUMPED = VNUMPED;
         
            UPDATE PCPEDI SET CODUSUR = VCODUSUR WHERE NUMPED = VNUMPED;
         
            COMMIT;
         ELSE
            FOR REG IN (SELECT I.CODCLI,
                               UF.CODFORNEC,
                               NVL(C.NUMPED, -1) AS NUMPED,
                               C.CODFILIAL
                        FROM   PCPEDITEMP   I,
                               PCPRODUT     P,
                               PCUSURFORNEC UF,
                               PCPEDCTEMP   C
                        WHERE  UF.CODFORNEC = P.CODFORNEC AND
                               I.CODPROD = P.CODPROD AND
                               I.NUMPEDWEB = PNUMPEDWEB AND
                               I.INTEGRADORA = PINTEGRADORA AND
                               I.CODCLI = PCODCLI AND
                               C.NUMPEDWEB = I.NUMPEDWEB AND
                               C.INTEGRADORA = I.INTEGRADORA AND
                               C.CODCLI = I.CODCLI)
            LOOP
               VPARAM := '';
            
               SELECT UTILIZAPCUSURFORNEC INTO VPARAM FROM PCCONSUM;
            
               IF VPARAM = 'S'
               THEN
                  VCODUSUR := FNC_ECOMMERCEUNILEVER_CODUSUR(PCODCLI,
                                                            REG.CODFORNEC,
                                                            REG.CODFILIAL);
               ELSE
                  SELECT CODUSURECOMMERCE
                  INTO   VCODUSUR
                  FROM   PCCLIENT
                  WHERE  CODCLI = PCODCLI;
               END IF;
            
               IF VCODUSUR > 0
               THEN
                  UPDATE PCPEDCTEMP
                  SET    CODUSUR = VCODUSUR
                  WHERE  NUMPEDWEB = PNUMPEDWEB AND
                         INTEGRADORA = PINTEGRADORA;
               
                  UPDATE PCPEDITEMP
                  SET    CODUSUR = VCODUSUR
                  WHERE  NUMPEDWEB = PNUMPEDWEB AND
                         INTEGRADORA = PINTEGRADORA;
               
                  UPDATE PCPEDC
                  SET    CODUSUR = VCODUSUR
                  WHERE  NUMPED = REG.NUMPED;
               
                  UPDATE PCPEDI
                  SET    CODUSUR = VCODUSUR
                  WHERE  NUMPED = REG.NUMPED;
               
                  COMMIT;
               
                  EXIT;
               END IF;
            END LOOP;
         END IF;
      END IF;
   END IMPORTAR_PEDIDO_WEB_CODUSUR;

   PROCEDURE IMPORTAR_PEDIDO_WEB_COMPLETO
   (
      PNUMPED   IN NUMBER,
      PCOMPLETO OUT VARCHAR2
   ) IS
      VCONTITEM NUMBER(10, 0);
      VCONTCABE NUMBER(10, 0);
   BEGIN
      PCOMPLETO := 'N';
      VCONTITEM := 0;
      VCONTCABE := 0;
   
      BEGIN
         SELECT COUNT(NUMPED) AS CONTADOR
         INTO   VCONTITEM
         FROM   PCPEDI
         WHERE  NUMPED = PNUMPED;
      EXCEPTION
         WHEN OTHERS THEN
            VCONTITEM := 0;
      END;
   
      BEGIN
         SELECT COUNT(NUMPED) AS CONTADOR
         INTO   VCONTCABE
         FROM   PCPEDC
         WHERE  NUMPED = PNUMPED;
      EXCEPTION
         WHEN OTHERS THEN
            VCONTCABE := 0;
      END;
   
      IF VCONTITEM > 0 AND
         VCONTCABE > 0
      THEN
         PCOMPLETO := 'S';
      END IF;
   END IMPORTAR_PEDIDO_WEB_COMPLETO;

   PROCEDURE IMPORTAR_PEDIDO_PCFORMAPAGTO
   (
      PNUMPEDWEB IN NUMBER,
      PNUMPED    IN NUMBER
   ) IS
      QT_PEDIDOS      INTEGER;
      PCODCOBSEFAZ    VARCHAR2(4);
      PCODBANDEIRA    NUMBER(6);
      QT_PEDIDOB2B    INTEGER;
      PCODCOBSEFAZB2B VARCHAR2(4);
      PCODBANDEIRAB2B NUMBER(6);
   BEGIN
      QT_PEDIDOS      := 0;
      PCODCOBSEFAZ    := 0;
      PCODBANDEIRA    := 0;
      QT_PEDIDOB2B    := 0;
      PCODCOBSEFAZB2B := 0;
      PCODBANDEIRAB2B := 0;
   
      BEGIN
         SELECT COUNT(E.NUMPEDWEB) AS CONTADOR
         INTO   QT_PEDIDOS
         FROM   PCPRESTTEMP E
         WHERE  E.NUMPEDWEB = PNUMPEDWEB;
      EXCEPTION
         WHEN OTHERS THEN
            QT_PEDIDOS := 0;
      END;
   
      IF QT_PEDIDOS > 1
      THEN
         FOR REG IN (SELECT E.*
                     FROM   PCPRESTTEMP E
                     WHERE  E.NUMPEDWEB = PNUMPEDWEB)
         LOOP
            SELECT CODCOBSEFAZ, CODBANDEIRA
            INTO   PCODCOBSEFAZ, PCODBANDEIRA
            FROM   PCCOB
            WHERE  CODCOB = REG.CODCOB;
         
            INSERT INTO PCFORMAPGTOPEDIDO
               (NUMPED,
                CODCOB,
                CODPLPAG,
                DTVENC,
                VALOR,
                TIPOINTEGRACAO,
                VLRTROCO,
                CODBANDEIRACARTAO,
                CODCOBSEFAZ)
            VALUES
               (PNUMPED,
                REG.CODCOB,
                REG.CODPLPAG,
                SYSDATE,
                REG.VALOR,
                NULL,
                0,
                PCODBANDEIRA,
                PCODCOBSEFAZ);
         END LOOP;
      END IF;
   
      BEGIN
         SELECT COUNT(E.NUMPEDWEB) CONTADOR
         INTO   QT_PEDIDOB2B
         FROM   PCFORMAPGTOPEDIDOTEMP E
         WHERE  E.NUMPEDWEB = PNUMPEDWEB;
      EXCEPTION
         WHEN OTHERS THEN
            QT_PEDIDOB2B := 0;
      END;
   
      IF QT_PEDIDOB2B > 1
      THEN
         FOR REG IN (SELECT *
                     FROM   PCFORMAPGTOPEDIDOTEMP
                     WHERE  NUMPEDWEB = PNUMPEDWEB)
         LOOP
            SELECT CODCOBSEFAZ, CODBANDEIRA
            INTO   PCODCOBSEFAZB2B, PCODBANDEIRAB2B
            FROM   PCCOB
            WHERE  CODCOB = REG.CODCOB;
         
            INSERT INTO PCFORMAPGTOPEDIDO
               (NUMPED,
                CODCOB,
                CODPLPAG,
                DTVENC,
                VALOR,
                TIPOINTEGRACAO,
                VLRTROCO,
                CODBANDEIRACARTAO,
                CODCOBSEFAZ)
            VALUES
               (PNUMPED,
                REG.CODCOB,
                REG.CODPLPAG,
                SYSDATE,
                REG.VALOR,
                NULL,
                0,
                PCODBANDEIRAB2B,
                PCODCOBSEFAZB2B);
         END LOOP;
      END IF;
   END IMPORTAR_PEDIDO_PCFORMAPAGTO;

   PROCEDURE IMPORTAR_PEDIDO_WEB_LIMPAOBS
   (
      PNUMPEDWEB   IN NUMBER,
      PINTEGRADORA IN NUMBER,
      PCODUSUR     IN NUMBER
   ) IS
      VIMPORTADO PCPEDCTEMP.IMPORTADO%TYPE;
   BEGIN
      VIMPORTADO := 'N';
   
      BEGIN
         SELECT NVL(T.IMPORTADO, 'N')
         INTO   VIMPORTADO
         FROM   PCPEDCTEMP T
         WHERE  T.NUMPEDWEB = PNUMPEDWEB AND
                T.INTEGRADORA = PINTEGRADORA AND
                T.CODUSUR = PCODUSUR AND
                NVL(T.IMPORTADO, 'N') = 'N' AND
                T.TIPOINTEGRACAO = 'W';
      EXCEPTION
         WHEN OTHERS THEN
            VIMPORTADO := 'S';
      END;
   
      IF VIMPORTADO = 'N'
      THEN
         UPDATE PCPEDITEMP T
         SET    T.OBSERVACAO_PC = NULL
         WHERE  T.NUMPEDWEB = PNUMPEDWEB AND
                T.INTEGRADORA = PINTEGRADORA AND
                T.CODUSUR = PCODUSUR;
      
         UPDATE PCPEDCTEMP T
         SET    T.OBSERVACAO_PC  = NULL,
                T.OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  T.NUMPEDWEB = PNUMPEDWEB AND
                T.INTEGRADORA = PINTEGRADORA AND
                T.CODUSUR = PCODUSUR;
      
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
   END IMPORTAR_PEDIDO_WEB_LIMPAOBS;

   PROCEDURE IMPORTAR_PEDIDO_WEB_NUMREGIAO
   (
      PCODFILIAL IN VARCHAR2,
      PCODPRACA  IN NUMBER,
      PCODCLI    IN PCCLIENT.CODCLI%TYPE,
      PNUMREGIAO OUT NUMBER
   ) IS
      VNUMREGIAO PCREGIAO.NUMREGIAO%TYPE;
   BEGIN
      VNUMREGIAO := 0;
   
      BEGIN
         SELECT NVL(TC.NUMREGIAO, 0) AS NUMREGIAO
         INTO   VNUMREGIAO
         FROM   PCTABPRCLI TC
         WHERE  TC.CODFILIALNF = PCODFILIAL AND
                TC.CODCLI = PCODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VNUMREGIAO := 0;
      END;
   
      IF VNUMREGIAO <= 0
      THEN
         BEGIN
            SELECT NVL(TC.NUMREGIAO, 0) AS NUMREGIAO
            INTO   VNUMREGIAO
            FROM   PCPRACA TC
            WHERE  TC.CODPRACA = PCODPRACA;
         EXCEPTION
            WHEN OTHERS THEN
               VNUMREGIAO := 0;
         END;
      END IF;
   
      PNUMREGIAO := VNUMREGIAO;
   END IMPORTAR_PEDIDO_WEB_NUMREGIAO;

   PROCEDURE IMPORTAR_PEDIDO_WEB_CODST
   (
      PCODFILIAL   IN VARCHAR2,
      PCODPROD     IN NUMBER,
      PUF          IN VARCHAR2,
      PCODPRACA    IN NUMBER,
      PCODST       OUT NUMBER,
      PCODCLI      IN PCCLIENT.CODCLI%TYPE,
      PINTEGRADORA IN NUMBER
   ) IS
      VUSATRIBUTACAOPORUF     VARCHAR2(1);
      VCODST                  PCTABPR.CODST%TYPE;
      VCODFILIAL              VARCHAR2(2);
      VCODFILIALNF            VARCHAR2(2);
      VUTILIZAFILIALCLIENTENF VARCHAR2(1);
   BEGIN
      --Código de st - início
      VCODST              := 0;
      VUSATRIBUTACAOPORUF := 'N';
      VCODFILIAL          := PCODFILIAL;
   
      IF PINTEGRADORA IN (29)
      THEN
         --Ecommerce Unilever 2697
         BEGIN
            SELECT NVL(PCECOMMERCEUNILEVER.USAFILIALNF, 'N') AS VALOR
            INTO   VUTILIZAFILIALCLIENTENF
            FROM   PCECOMMERCEUNILEVER
            WHERE  PCECOMMERCEUNILEVER.CODFILIAL = PCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VUTILIZAFILIALCLIENTENF := 'N';
         END;
      
         IF VUTILIZAFILIALCLIENTENF = 'S'
         THEN
            SELECT NVL(CODFILIALNF, PCODFILIAL)
            INTO   VCODFILIALNF
            FROM   PCCLIENT
            WHERE  CODCLI = PCODCLI;
            VCODFILIAL := VCODFILIALNF;
         END IF;
      END IF;
   
      BEGIN
         SELECT NVL(VALOR, 'N') AS VALOR
         INTO   VUSATRIBUTACAOPORUF
         FROM   PCPARAMFILIAL T
         WHERE  T.NOME = 'CON_USATRIBUTACAOPORUF' AND
                CODFILIAL = '99';
      EXCEPTION
         WHEN OTHERS THEN
            VUSATRIBUTACAOPORUF := 'N';
      END;
   
      VGLOBAL_USATRIBUTACAOPORUF := VUSATRIBUTACAOPORUF;
   
      IF VUSATRIBUTACAOPORUF = 'S'
      THEN
         BEGIN
            SELECT NVL(P.CODST, 0)
            INTO   VCODST
            FROM   PCTABTRIB P
            WHERE  P.CODPROD = PCODPROD AND
                   P.CODFILIALNF = VCODFILIAL AND
                   P.UFDESTINO = PUF AND
                   ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS THEN
               VCODST := 0;
         END;
      ELSE
         BEGIN
            SELECT NVL(T.CODST, 0) AS CODST
            INTO   VCODST
            FROM   PCTABPR T, PCTABPRCLI TC
            WHERE  T.CODPROD = PCODPROD AND
                   T.NUMREGIAO = TC.NUMREGIAO AND
                   TC.CODFILIALNF = VCODFILIAL AND
                   TC.CODCLI = PCODCLI;
         EXCEPTION
            WHEN OTHERS THEN
               VCODST := 0;
         END;
      
         IF VCODST = 0
         THEN
            BEGIN
               SELECT NVL(T.CODST, 0) AS CODST
               INTO   VCODST
               FROM   PCTABPR T, PCPRACA P
               WHERE  T.CODPROD = PCODPROD AND
                      T.NUMREGIAO = P.NUMREGIAO AND
                      P.CODPRACA = PCODPRACA;
            EXCEPTION
               WHEN OTHERS THEN
                  VCODST := 0;
            END;
         END IF;
      END IF;
   
      PCODST := VCODST;
      --Código de st - fim
   END IMPORTAR_PEDIDO_WEB_CODST;

   PROCEDURE IMPORTAR_PEDIDO_WEB_ESTOQUEPKG
   (
      PNUMPED  IN NUMBER,
      PPOSICAO IN VARCHAR2
   ) IS
      VSMSGRETORNO    VARCHAR2(4000);
      VSRETORNOFUNCAO VARCHAR2(4000);
   BEGIN
      VGLOBAL_RETORNO_ESTOQUE := '';
      IF PPOSICAO = 'L'
      THEN
         VSRETORNOFUNCAO := PKG_ESTOQUE.RESERVA_INCLUIR_PEDIDO(PNUMPED,
                                                               'IN',
                                                               VSMSGRETORNO);
      ELSE
         VSRETORNOFUNCAO := PKG_ESTOQUE.PENDENTE_INCLUIR_PEDIDO(PNUMPED,
                                                                'IN',
                                                                VSMSGRETORNO);
      END IF;
   
      IF (VSRETORNOFUNCAO = 'N')
      THEN
         VGLOBAL_RETORNO_ESTOQUE := VSMSGRETORNO;
      END IF;
   
      COMMIT;
   END IMPORTAR_PEDIDO_WEB_ESTOQUEPKG;

   PROCEDURE IMPORTAR_PEDIDO_WEB_PCPEDI
   (
      PNUMPED            NUMBER --01
     ,
      PCODPROD           NUMBER --02
     ,
      PNUMSEQ            NUMBER --03
     ,
      PDATA              DATE --04
     ,
      PQT                NUMBER --05
     ,
      PPVENDA            NUMBER --06
     ,
      PPTABELA           NUMBER --07
     ,
      PCODCLI            PCCLIENT.CODCLI%TYPE --08
     ,
      PCODUSUR           NUMBER --09
     ,
      PPOSICAO           VARCHAR2 --10
     ,
      PVLCUSTOFIN        NUMBER --11
     ,
      PVLCUSTOREAL       NUMBER --12
     ,
      PPERCOM            NUMBER --13
     ,
      PPERDESC           NUMBER --14
     ,
      PCODFILIALRETIRA   VARCHAR2 --15
     ,
      PPESOBRUTO         NUMBER --16
     ,
      PVLCUSTOCONT       NUMBER --17
     ,
      PVLCUSTOREP        NUMBER --18
     ,
      PPBONIFIC          NUMBER --19
     ,
      PBONIFIC           VARCHAR2 --20
     ,
      PVLIPI             NUMBER --21
     ,
      PPERCIPI           NUMBER --22
     ,
      PPORIGINAL         NUMBER --23
     ,
      PNUMCAR            NUMBER --24
     ,
      PCODAUXILIAR       NUMBER --25
     ,
      PIVA               NUMBER --26
     ,
      QTUNITEMB          NUMBER --27
     ,
      PNUMREGIAO         NUMBER --28
     ,
      PCODST             NUMBER --29
     ,
      PCODFILIAL         PCFILIAL.CODIGO%TYPE --30
     ,
      PCODFILIALNF       PCFILIAL.CODIGO%TYPE --31
     ,
      PCODPLPAG          PCPEDC.CODPLPAG%TYPE --32
     ,
      PCONDVENDA         PCPEDC.CONDVENDA%TYPE --33
     ,
      PVENDA_SEMIMPOSTOS NUMBER --34
   ) IS
      VPCCOMSUM               PCCONSUM%ROWTYPE;
      VPCCLIENT               PCCLIENT%ROWTYPE;
      VCUSTOFINEST            PCPEDI.CUSTOFINEST%TYPE;
      VPERFRETECMV            PCPEDI.PERFRETECMV%TYPE;
      VTXVENDA                PCPEDI.TXVENDA%TYPE;
      VPERDESCCUSTO           PCPEDI.PERDESCCUSTO%TYPE;
      VCODICMTAB              PCPEDI.CODICMTAB%TYPE;
      VCODICMTABPJ            PCPEDI.CODICMTAB%TYPE;
      VCODICMTABPF            PCPEDI.CODICMTAB%TYPE;
      VVLCUSTOREAL            PCPEDI.VLCUSTOREAL%TYPE;
      VVLCUSTOFIN             PCPEDI.VLCUSTOFIN%TYPE;
      VVLDESCCUSTOCMV         PCPEDI.VLDESCCUSTOCMV%TYPE;
      VFRETEESPECIAL          PCPRODUT.FRETEESPECIAL%TYPE;
      VPERCFRETEESPECIAL      PCREGIAO.PERFRETEESPECIAL%TYPE;
      VPERCFRETETERCEIROS     PCREGIAO.PERFRETETERCEIROS%TYPE;
      VBASEST                 NUMBER(18, 6);
      VST                     NUMBER(18, 6);
      VVLFECP                 PCPEDI.VLFECP%TYPE;
      VBASEFECP               PCPEDI.VLBASEFCPST%TYPE;
      VALIQICMSFECP           PCPEDI.ALIQICMSFECP%TYPE;
      VNUMEMPENHO             PCPEDC.NUMEMPENHO%TYPE;
      VPRAZOMEDIO             PCPEDC.PRAZOMEDIO%TYPE;
      VVALOR_DESCONTO_PIS     PCPEDI.VLDESCREDUCAOPIS%TYPE;
      VPERC_DESCONTO_PIS      PCPEDI.PERCDESCPIS%TYPE;
      VVALOR_DESCONTO_COFINS  PCPEDI.VLDESCREDUCAOCOFINS%TYPE;
      VPERC_DESCONTO_COFINS   PCPEDI.PERCDESCCOFINS%TYPE;
      VVALOR_DESCONTO_ICMS    PCPEDI.VLDESCICMISENCAO%TYPE;
      VPERC_DESCONTO_ICMS     PCPEDI.PERDESCISENTOICMS%TYPE;
      VVALOR_DESCONTO_SUFRAMA PCPEDI.VLDESCSUFRAMA%TYPE;
      VPVENDA                 PCPEDI.PVENDA%TYPE;
      VPTABELA                PCPEDI.PTABELA%TYPE;
      VUSADESCISENCAOICMS     VARCHAR2(1);
   BEGIN
      BEGIN
         SELECT * INTO VPCCOMSUM FROM PCCONSUM;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   
      BEGIN
         SELECT * INTO VPCCLIENT FROM PCCLIENT WHERE CODCLI = PCODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   
      BEGIN
         SELECT NVL(FRETEESPECIAL, 'N')
         INTO   VFRETEESPECIAL
         FROM   PCPRODUT
         WHERE  CODPROD = PCODPROD;
      EXCEPTION
         WHEN OTHERS THEN
            VFRETEESPECIAL := 'N';
      END;
   
      BEGIN
         SELECT NVL(PERFRETEESPECIAL, 0), NVL(PERFRETETERCEIROS, 0)
         INTO   VPERCFRETEESPECIAL, VPERCFRETETERCEIROS
         FROM   PCREGIAO G
         WHERE  G.NUMREGIAO = PNUMREGIAO;
      EXCEPTION
         WHEN OTHERS THEN
            VPERCFRETEESPECIAL  := 0;
            VPERCFRETETERCEIROS := 0;
      END;
   
      BEGIN
         SELECT NVL(UTILIZAMOTORCALCULO, 'N'),
                NVL(CODICMTAB, 0),
                NVL(CODICMTABPF, 0)
         INTO   VUTILIZOUMOTORCALCULO, VCODICMTABPJ, VCODICMTABPF
         FROM   PCTRIBUT
         WHERE  CODST = PCODST;
      EXCEPTION
         WHEN OTHERS THEN
            VUTILIZOUMOTORCALCULO := 'N';
            VCODICMTABPJ          := 0;
            VCODICMTABPF          := 0;
      END;
   
      BEGIN
         CALCULARVALORES_ST(PCODFILIAL,
                            PCODFILIALNF,
                            PCODFILIALRETIRA,
                            PCODCLI,
                            PCODPLPAG,
                            PCODPROD,
                            PCODAUXILIAR,
                            PCONDVENDA,
                            PVENDA_SEMIMPOSTOS,
                            VBASEST,
                            VST,
                            VVLFECP,
                            VBASEFECP,
                            VALIQICMSFECP);
      EXCEPTION
         WHEN OTHERS THEN
            VBASEST       := 0;
            VST           := 0;
            VVLFECP       := 0;
            VBASEFECP     := 0;
            VALIQICMSFECP := 0;
      END;
   
      BEGIN
         FUNCOESVENDAS.CALCULARCMV(VPCCOMSUM.ABATERIMPOSTOSCOMISSAORCA, --01
                                   VPCCOMSUM.APLICARINDICECMV, --02
                                   VPCCOMSUM.INCLUIRCOMISSAOSUGPVENDACMV, --03
                                   NVL(VPCCOMSUM.TXVENDA, 0), --04
                                   VPCCLIENT.TIPOFJ, --05
                                   VPCCLIENT.UTILIZAIESIMPLIFICADA, --06
                                   VPCCLIENT.IEENT, --07
                                   VFRETEESPECIAL, --08
                                   VPERCFRETETERCEIROS, --09
                                   VPERCFRETEESPECIAL, --10
                                   PVLCUSTOFIN, --11
                                   PVLCUSTOREAL, --12
                                   0, --13
                                   VCODICMTABPJ, --14
                                   FALSE, --15
                                   VCODICMTABPF, --16
                                   PPERDESC, --17
                                   PPVENDA, --18
                                   PPERCOM, --19
                                   VST, --20
                                   PVLIPI, --21
                                   0, --22
                                   VPCCLIENT.CONTRIBUINTE, --23
                                   0, --24
                                   0, --25
                                   VPCCLIENT.CONSUMIDORFINAL, --26
                                   NVL(VPCCOMSUM.CONSIDERAISENTOSCOMOPF,
                                       'N'), --27
                                   VPERFRETECMV, --28
                                   VCUSTOFINEST, --29
                                   VTXVENDA, --30
                                   VPERDESCCUSTO, --31
                                   VCODICMTAB, --32
                                   VVLCUSTOREAL, --33
                                   VVLCUSTOFIN, --34
                                   VVLDESCCUSTOCMV, --35
                                   VPCCLIENT.CODCLI, --36
                                   0, --37
                                   FALSE, --38
                                   FALSE, --39
                                   0, --40
                                   0, --41
                                   0 --42
                                   );
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   
      VUSADESCISENCAOICMS := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCISENCAOICMS',
                                                                PCODFILIAL,
                                                                'N');
   
      IF VUSADESCISENCAOICMS = 'S'
      THEN
         BEGIN
            SELECT NVL(NUMEMPENHO, 0), PRAZOMEDIO
            INTO   VNUMEMPENHO, VPRAZOMEDIO
            FROM   PCPEDC
            WHERE  NUMPED = PNUMPED;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      
         BEGIN
            SELECT VALOR_DESCONTO_PIS,
                   PERC_DESCONTO_PIS,
                   VALOR_DESCONTO_COFINS,
                   PERC_DESCONTO_COFINS,
                   VALOR_DESCONTO_ICMS,
                   PERC_DESCONTO_ICMS,
                   VALOR_DESCONTO_SUFRAMA
            INTO   VVALOR_DESCONTO_PIS,
                   VPERC_DESCONTO_PIS,
                   VVALOR_DESCONTO_COFINS,
                   VPERC_DESCONTO_COFINS,
                   VVALOR_DESCONTO_ICMS,
                   VPERC_DESCONTO_ICMS,
                   VVALOR_DESCONTO_SUFRAMA
            FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(PCODFILIAL, --psCodFilial VARCHAR2,
                                                                      PCODFILIALNF, --psCodFilialNF VARCHAR2,
                                                                      PCODFILIALRETIRA, -- psCodFilialRetira VARCHAR2,
                                                                      PCODCLI, --pCodCli IN NUMBER,
                                                                      PCODPROD, --pCodProd IN NUMBER,
                                                                      PVENDA_SEMIMPOSTOS, --Preço sem imposto pPreco IN FLOAT,
                                                                      VNUMEMPENHO, --pNumEmpenho IN VARCHAR2,
                                                                      VPRAZOMEDIO --pPrazoMedioPedido IN NUMBER
                                                                      ));
         
            VPVENDA  := (PPVENDA - VVALOR_DESCONTO_PIS -
                        VVALOR_DESCONTO_COFINS - VVALOR_DESCONTO_ICMS -
                        VVALOR_DESCONTO_SUFRAMA);
            VPTABELA := (PPTABELA - VVALOR_DESCONTO_PIS -
                        VVALOR_DESCONTO_COFINS - VVALOR_DESCONTO_ICMS -
                        VVALOR_DESCONTO_SUFRAMA);
         
         EXCEPTION
            WHEN OTHERS THEN
               VVALOR_DESCONTO_PIS     := 0;
               VPERC_DESCONTO_PIS      := 0;
               VVALOR_DESCONTO_COFINS  := 0;
               VPERC_DESCONTO_COFINS   := 0;
               VVALOR_DESCONTO_ICMS    := 0;
               VPERC_DESCONTO_ICMS     := 0;
               VVALOR_DESCONTO_SUFRAMA := 0;
         END;
      ELSE
         VPVENDA  := PPVENDA;
         VPTABELA := PPTABELA;
      END IF;
   
      INSERT INTO PCPEDI
         (NUMPED,
          CODPROD,
          NUMSEQ,
          DATA,
          QT,
          PVENDA,
          PTABELA,
          CODCLI,
          CODUSUR,
          POSICAO,
          VLCUSTOFIN,
          VLCUSTOREAL,
          PERCOM,
          PERDESC,
          CODFILIALRETIRA,
          PESOBRUTO,
          VLCUSTOCONT,
          VLCUSTOREP,
          PBONIFIC,
          BONIFIC,
          VLIPI,
          PERCIPI,
          PORIGINAL,
          NUMCAR,
          CODAUXILIAR,
          IVA,
          CUSTOFINEST,
          UTILIZOUMOTORCALCULO,
          CODICMTAB,
          QTUNITEMB,
          PERFRETECMV,
          CODST,
          BASEICST,
          ST,
          VLBASEFCPST,
          ALIQICMSFECP,
          VLFECP,
          ALIQFCP,
          VLDESCREDUCAOPIS,
          PERCDESCPIS,
          VLDESCREDUCAOCOFINS,
          PERCDESCCOFINS,
          VLDESCICMISENCAO,
          PERDESCISENTOICMS,
          VLDESCSUFRAMA)
      VALUES
         (PNUMPED,
          PCODPROD,
          PNUMSEQ,
          PDATA,
          PQT,
          VPVENDA,
          VPTABELA,
          PCODCLI,
          PCODUSUR,
          PPOSICAO,
          VVLCUSTOFIN,
          VVLCUSTOREAL,
          PPERCOM,
          PPERDESC,
          PCODFILIALRETIRA,
          PPESOBRUTO,
          PVLCUSTOCONT,
          PVLCUSTOREP,
          PPBONIFIC,
          PBONIFIC,
          VVLIPI_PTABELA,
          PPERCIPI,
          PPORIGINAL,
          PNUMCAR,
          PCODAUXILIAR,
          PIVA,
          VCUSTOFINEST,
          VUTILIZOUMOTORCALCULO,
          VCODICMTAB,
          QTUNITEMB,
          VPERFRETECMV,
          PCODST,
          VBASEST,
          VST,
          VBASEFECP,
          VALIQICMSFECP,
          VVLFECP,
          VALIQICMSFECP,
          VVALOR_DESCONTO_PIS,
          VPERC_DESCONTO_PIS,
          VVALOR_DESCONTO_COFINS,
          VPERC_DESCONTO_COFINS,
          VVALOR_DESCONTO_ICMS,
          VPERC_DESCONTO_ICMS,
          VVALOR_DESCONTO_SUFRAMA);
   
      INSERT INTO PCORIGEMPRECO
         (NUMPED,
          CODPROD,
          NUMSEQ,
          DATA,
          PORIGINAL,
          CODCLI,
          VLST,
          VLIPI,
          CODAUXILIAR,
          ORIGEMPED,
          CODPLPAG,
          CODFILIAL,
          USATRIBUTPORUF,
          NUMREGIAO,
          VLFECP)
      VALUES
         (PNUMPED,
          PCODPROD,
          PNUMSEQ,
          PDATA,
          PPVENDA,
          PCODCLI,
          VST,
          PVLIPI,
          PCODAUXILIAR,
          VGLOBAL_ORIGEMPED,
          VGLOBAL_CODPLPAG,
          VGLOBAL_CODFILIAL,
          VGLOBAL_USATRIBUTACAOPORUF,
          VGLOBAL_NUMREGIAO,
          VVLFECP);
   END IMPORTAR_PEDIDO_WEB_PCPEDI;

   PROCEDURE IMPORTAR_PEDIDO_WEB_PCPEDC
   (
      PNUMPED            NUMBER,
      PDATA              DATE,
      PCODFILIAL         VARCHAR2,
      PCODFILIALNF       VARCHAR2,
      PCODCLI            PCCLIENT.CODCLI%TYPE,
      PCODUSUR           NUMBER,
      PCODPLPAG          NUMBER,
      PCODCOB            VARCHAR2,
      PVLTOTAL           NUMBER,
      PVLATEND           NUMBER,
      PVLTABELA          NUMBER,
      PPOSICAO           VARCHAR2,
      PCODPRACA          NUMBER,
      PNUMPEDWEB         NUMBER,
      PNUMPEDCLI         VARCHAR2,
      PNUMPEDRCA         NUMBER,
      PINTEGRADORA       NUMBER,
      PTOTPESO           NUMBER,
      PTOTPESOLIQ        NUMBER,
      PORIGEMPED         VARCHAR2,
      PNUMITENS          NUMBER,
      PCONDVENDA         NUMBER,
      PVLFRETE           NUMBER,
      PDTENTREGA         DATE,
      PPERCVENDA         NUMBER,
      PVLOUTRASDESP      NUMBER,
      PCODDISTRIB        VARCHAR2,
      PFRETEDESPACHO     VARCHAR2,
      PFRETEREDESPACHO   VARCHAR2,
      PCODSUPERVISOR     NUMBER,
      PVLBONIFIC         NUMBER,
      PCODEMITENTE       NUMBER,
      POBS1              VARCHAR2,
      PNUMCAR            NUMBER,
      PHORA              NUMBER,
      PMINUTO            NUMBER,
      PNUMREGIAO         NUMBER,
      PVLDESCONTOCUPOM   NUMBER,
      PUSADEBCREDRCA     VARCHAR2,
      PUSACREDRCA        VARCHAR2,
      PCNPJINTERMEDIADOR VARCHAR2,
      PDESCINTERMEDIADOR VARCHAR2,
	  PCODBNF            NUMBER
   ) IS
      VTIPODOCUMENTO     PCPEDC.TIPODOCUMENTO%TYPE;
      VTIPOCONTACORRENTE PCPEDC.TIPOCONTACORRENTE%TYPE;
      VCNPJINTERMEDIADOR PCPEDCTEMP.CNPJINTERMEDIADOR%TYPE;
      VDESCINTERMEDIADOR PCPEDCTEMP.DESCINTERMEDIADOR%TYPE;
   BEGIN
      VTIPOCONTACORRENTE := FUNC_TIPOCONTACORRENTE(PCONDVENDA,
                                                   PVLTOTAL,
                                                   PVLTABELA);
      VTIPODOCUMENTO     := 'A';
      VCNPJINTERMEDIADOR := PCNPJINTERMEDIADOR;
      VDESCINTERMEDIADOR := PDESCINTERMEDIADOR;
   
      IF PCNPJINTERMEDIADOR IS NULL OR
         PDESCINTERMEDIADOR IS NULL
      THEN
         OBTERINTERMEDIADOR(PCODFILIAL,
                            PINTEGRADORA,
                            VCNPJINTERMEDIADOR,
                            VDESCINTERMEDIADOR);
      END IF;
   
      INSERT INTO PCPEDC
         (NUMPED,
          DATA,
          CODFILIAL,
          CODFILIALNF,
          CODCLI,
          CODUSUR,
          CODPLPAG,
          CODCOB,
          VLTOTAL,
          VLATEND,
          VLTABELA,
          POSICAO,
          CODPRACA,
          NUMPEDWEB,
          NUMPEDCLI,
          NUMPEDRCA,
          INTEGRADORA,
          TOTPESO,
          TOTPESOLIQ,
          ORIGEMPED,
          NUMITENS,
          CONDVENDA,
          VLFRETE,
          DTENTREGA,
          PERCVENDA,
          VLOUTRASDESP,
          CODDISTRIB,
          FRETEDESPACHO,
          FRETEREDESPACHO,
          CODSUPERVISOR,
          VLBONIFIC,
          CODEMITENTE,
          OBS1,
          NUMCAR,
          HORA,
          MINUTO,
          TIPODOCUMENTO,
          NUMREGIAO,
          OBSENTREGA4,
          CODFORNECFRETE,
          TIPOVENDA,
          CODTRANSP,
          CODENDENTCLI,
          PRAZO1,
          PRAZO2,
          PRAZO3,
          PRAZO4,
          PRAZO5,
          PRAZO6,
          PRAZO7,
          PRAZO8,
          PRAZO9,
          PRAZO10,
          PRAZO11,
          PRAZO12,
          PRAZOMEDIO,
          VLCUSTOFIN,
          VLCUSTOREAL,
          VLCUSTOREP,
          VLCUSTOCONT,
          OBS2,
          TIPOCONTACORRENTE,
          VLDESCONTOCUPOM,
          USADEBCREDRCA,
          USACREDRCA,
          CNPJINTERMEDIADOR,
          DESCINTERMEDIADOR,
		  CODBNF)
      VALUES
         (PNUMPED,
          PDATA,
          PCODFILIAL,
          PCODFILIALNF,
          PCODCLI,
          PCODUSUR,
          PCODPLPAG,
          PCODCOB,
          PVLTOTAL,
          PVLATEND,
          PVLTABELA,
          PPOSICAO,
          PCODPRACA,
          PNUMPEDWEB,
          PNUMPEDCLI,
          PNUMPEDRCA,
          PINTEGRADORA,
          PTOTPESO,
          PTOTPESOLIQ,
          PORIGEMPED,
          PNUMITENS,
          PCONDVENDA,
          PVLFRETE,
          PDTENTREGA,
          PPERCVENDA,
          PVLOUTRASDESP,
          PCODDISTRIB,
          PFRETEDESPACHO,
          PFRETEREDESPACHO,
          PCODSUPERVISOR,
          PVLBONIFIC,
          PCODEMITENTE,
          POBS1,
          PNUMCAR,
          PHORA,
          PMINUTO,
          VTIPODOCUMENTO,
          PNUMREGIAO,
          VGLOBAL_OBSENTREGA4,
          VGLOBAL_CODFORNECFRETE,
          VGLOBAL_TIPOVENDA,
          VGLOBAL_CODTRANSP,
          VGLOBAL_CODENDENTCLI,
          VPRAZO1,
          VPRAZO2,
          VPRAZO3,
          VPRAZO4,
          VPRAZO5,
          VPRAZO6,
          VPRAZO7,
          VPRAZO8,
          VPRAZO9,
          VPRAZO10,
          VPRAZO11,
          VPRAZO12,
          VNUMDIAS,
          VGLOBAL_VLCUSTOFIN,
          VGLOBAL_VLCUSTOREAL,
          VGLOBAL_VLCUSTOREP,
          VGLOBAL_VLCUSTOCONT,
          VGLOBAL_OBS2,
          VTIPOCONTACORRENTE,
          PVLDESCONTOCUPOM,
          PUSADEBCREDRCA,
          PUSACREDRCA,
          VCNPJINTERMEDIADOR,
          VDESCINTERMEDIADOR,
		  PCODBNF);
   END IMPORTAR_PEDIDO_WEB_PCPEDC;

   PROCEDURE IMPORTAR_PEDIDO_WEB_PERCOM(PNUMPED IN NUMBER) IS
      VNPERCOM                    PCPEDI.PERCOM%TYPE;
      VNUMPED                     PCPEDC.NUMPED%TYPE;
      VCODUSUR                    PCPEDC.CODUSUR%TYPE;
      VCODCLI                     PCPEDC.CODCLI%TYPE;
      VCODCOB                     PCPEDC.CODCOB%TYPE;
      VCODPLPAG                   PCPEDC.CODPLPAG%TYPE;
      VINTEGRADORA                PCPEDC.INTEGRADORA%TYPE;
      VCODFILIAL                  PCPEDC.CODFILIAL%TYPE;
      VDATA                       PCPEDC.DATA%TYPE;
      VUSACOMISSAOPORRCA          PCCONSUM.USACOMISSAOPORRCA%TYPE;
      VORDEMAVALIACAOCOMISSAORCA  PCCONSUM.ORDEMAVALIACAOCOMISSAORCA%TYPE;
      VUSACOMISSAOPORCLIENTE      PCCONSUM.USACOMISSAOPORCLIENTE%TYPE;
      VUSACOMISSAOPORLINHAPROD    PCCONSUM.USACOMISSAOPORLINHAPROD%TYPE;
      VCOMISSAORCATIPOVENDA       PCCONSUM.COMISSAORCATIPOVENDA%TYPE;
      VTIPOVEND                   PCUSUARI.TIPOVEND%TYPE;
      VPERCENT                    PCUSUARI.PERCENT%TYPE;
      VPERCENT2                   PCUSUARI.PERCENT2%TYPE;
      VTIPOVENDA                  PCPLPAG.TIPOVENDA%TYPE;
      VCONSIDERARCOMISSAOZERO     PCFILIAL.CONSIDERARCOMISSAOZERO%TYPE;
      VTIPOAVALIACAOCOMISSAO      PCFILIAL.TIPOAVALIACAOCOMISSAO%TYPE;
      VPERCOMCLI                  PCCLIENT.PERCOMCLI%TYPE;
      VCODPRACA                   PCCLIENT.CODPRACA%TYPE;
      VNUMREGIAO                  PCREGIAO.NUMREGIAO%TYPE;
      VICONT                      NUMBER(10, 0);
      VBUSAPCTABCOMISS            BOOLEAN;
      VBUSAPCCOMISSAOUSUR         BOOLEAN;
      VBUSAPCCOMISSAOPLPAG        BOOLEAN;
      VBUSAPCCOMISSAOREGIAO       BOOLEAN;
      VCODPROD                    PCPRODUT.CODPROD%TYPE;
      VPCOMINT1                   PCPRODUT.PCOMINT1%TYPE;
      VPCOMEXT1                   PCPRODUT.PCOMEXT1%TYPE;
      VPCOMREP1                   PCPRODUT.PCOMREP1%TYPE;
      VCODLINHAPROD               PCPRODUT.CODLINHAPROD%TYPE;
      VTIPOCOMISSAO               PCPRODUT.TIPOCOMISSAO%TYPE;
      VCODEPTO                    PCPRODUT.CODEPTO%TYPE;
      VCODSEC                     PCPRODUT.CODSEC%TYPE;
      VCLASSE                     PCPRODUT.CLASSE%TYPE;
      VNCODCOMISS                 PCORIGEMCOMIS.CODCOMIS%TYPE;
      VNCODROTINACOMISS           PCORIGEMCOMIS.CODROTINACOMIS%TYPE;
      VSLETRACOMISS               VARCHAR2(100);
      VSMENSAGEM_COMISS           VARCHAR2(4000);
      VNPERLUC                    NUMBER(20, 6);
      VNPERDESC                   NUMBER(10, 6);
      VUSACOMISSAOPARARCAEMPEDWEB VARCHAR2(1);
      V2COM                       BOOLEAN;
   BEGIN
      VNPERCOM := 0;
   
      BEGIN
         SELECT PCPEDC.NUMPED,
                PCPEDC.CODUSUR,
                PCPEDC.CODCLI,
                PCPEDC.CODCOB,
                PCPEDC.CODPLPAG,
                PCPEDC.INTEGRADORA,
                PCPEDC.CODFILIAL,
                PCPEDC.DATA
         INTO   VNUMPED,
                VCODUSUR,
                VCODCLI,
                VCODCOB,
                VCODPLPAG,
                VINTEGRADORA,
                VCODFILIAL,
                VDATA
         FROM   PCPEDC
         WHERE  PCPEDC.NUMPED = PNUMPED;
      EXCEPTION
         WHEN OTHERS THEN
            VINTEGRADORA := 0;
      END;
   
      BEGIN
         VUSACOMISSAOPARARCAEMPEDWEB := 'N';
      
         SELECT SUBSTR(UPPER(NVL(VALOR, 'N')), 1, 1) VALOR
         INTO   VUSACOMISSAOPARARCAEMPEDWEB
         FROM   PCPARAMFILIAL
         WHERE  NOME = 'USACOMISSAORCAPEDWEB' --Parâmetro 4058 da rotina 132
                AND
                CODFILIAL = VCODFILIAL;
      EXCEPTION
         WHEN OTHERS THEN
            VUSACOMISSAOPARARCAEMPEDWEB := 'N';
      END;
   
      V2COM := (VINTEGRADORA = 28) AND
               (NVL(VUSACOMISSAOPARARCAEMPEDWEB, 'N') = 'S');
   
      IF (VINTEGRADORA IN (29, 32, 33, 34, 36) OR VINTEGRADORA > 999) OR
         (V2COM) THEN
         BEGIN
            SELECT PCCONSUM.USACOMISSAOPORRCA,
                   PCCONSUM.ORDEMAVALIACAOCOMISSAORCA,
                   PCCONSUM.USACOMISSAOPORCLIENTE,
                   PCCONSUM.USACOMISSAOPORLINHAPROD,
                   PCCONSUM.COMISSAORCATIPOVENDA
            INTO   VUSACOMISSAOPORRCA,
                   VORDEMAVALIACAOCOMISSAORCA,
                   VUSACOMISSAOPORCLIENTE,
                   VUSACOMISSAOPORLINHAPROD,
                   VCOMISSAORCATIPOVENDA
            FROM   PCCONSUM;
         EXCEPTION
            WHEN OTHERS THEN
               VUSACOMISSAOPORRCA         := 'N';
               VORDEMAVALIACAOCOMISSAORCA := 1;
               VUSACOMISSAOPORCLIENTE     := 'N';
               VUSACOMISSAOPORLINHAPROD   := 'N';
               VCOMISSAORCATIPOVENDA      := 'N';
         END;
      
         BEGIN
            SELECT PCUSUARI.TIPOVEND, PCUSUARI.PERCENT, PCUSUARI.PERCENT2
            INTO   VTIPOVEND, VPERCENT, VPERCENT2
            FROM   PCUSUARI
            WHERE  PCUSUARI.CODUSUR = VCODUSUR;
         EXCEPTION
            WHEN OTHERS THEN
               VTIPOVEND := NULL;
               VPERCENT  := NULL;
               VPERCENT2 := NULL;
         END;
      
         BEGIN
            SELECT PCPLPAG.TIPOVENDA,
                   PCPLPAG.CODPLPAG,
                   PRAZO1,
                   PRAZO2,
                   PRAZO3,
                   PRAZO4,
                   PRAZO5,
                   PRAZO6,
                   PRAZO7,
                   PRAZO8,
                   PRAZO9,
                   PRAZO10,
                   PRAZO11,
                   PRAZO12,
                   NUMDIAS
            INTO   VTIPOVENDA,
                   VCODPLPAG,
                   VPRAZO1,
                   VPRAZO2,
                   VPRAZO3,
                   VPRAZO4,
                   VPRAZO5,
                   VPRAZO6,
                   VPRAZO7,
                   VPRAZO8,
                   VPRAZO9,
                   VPRAZO10,
                   VPRAZO11,
                   VPRAZO12,
                   VNUMDIAS
            FROM   PCPLPAG
            WHERE  PCPLPAG.CODPLPAG = VCODPLPAG;
         EXCEPTION
            WHEN OTHERS THEN
               VTIPOVENDA := '';
               VCODPLPAG  := 0;
         END;
      
         BEGIN
            SELECT PCFILIAL.CONSIDERARCOMISSAOZERO,
                   PCFILIAL.TIPOAVALIACAOCOMISSAO
            INTO   VCONSIDERARCOMISSAOZERO, VTIPOAVALIACAOCOMISSAO
            FROM   PCFILIAL
            WHERE  PCFILIAL.CODIGO = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VCONSIDERARCOMISSAOZERO := NULL;
               VTIPOAVALIACAOCOMISSAO  := NULL;
         END;
      
         BEGIN
            SELECT PCCLIENT.PERCOMCLI, PCCLIENT.CODPRACA
            INTO   VPERCOMCLI, VCODPRACA
            FROM   PCCLIENT
            WHERE  PCCLIENT.CODCLI = VCODCLI;
         EXCEPTION
            WHEN OTHERS THEN
               VPERCOMCLI := 0;
               VCODPRACA  := 0;
         END;
      
         BEGIN
            SELECT PCPRACA.NUMREGIAO
            INTO   VNUMREGIAO
            FROM   PCPRACA
            WHERE  PCPRACA.CODPRACA = VCODPRACA;
         EXCEPTION
            WHEN OTHERS THEN
               VNUMREGIAO := NULL;
         END;
      
         SELECT COUNT(*) INTO VICONT FROM PCTABCOMISS;
      
         IF VICONT <> 0
         THEN
            VBUSAPCTABCOMISS := TRUE;
         ELSE
            VBUSAPCTABCOMISS := FALSE;
         END IF;
      
         SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOUSUR;
      
         IF VICONT <> 0
         THEN
            VBUSAPCCOMISSAOUSUR := TRUE;
         ELSE
            VBUSAPCCOMISSAOUSUR := FALSE;
         END IF;
      
         SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOPLPAG;
      
         IF VICONT <> 0
         THEN
            VBUSAPCCOMISSAOPLPAG := TRUE;
         ELSE
            VBUSAPCCOMISSAOPLPAG := FALSE;
         END IF;
      
         SELECT COUNT(*) INTO VICONT FROM PCCOMISSAOREGIAO;
      
         IF VICONT <> 0
         THEN
            VBUSAPCCOMISSAOREGIAO := TRUE;
         ELSE
            VBUSAPCCOMISSAOREGIAO := FALSE;
         END IF;
      
         FOR REG IN (SELECT * FROM PCPEDI WHERE NUMPED = PNUMPED)
         LOOP
            BEGIN
               SELECT P.CODPROD,
                      P.PCOMINT1,
                      P.PCOMEXT1,
                      P.PCOMREP1,
                      P.CODLINHAPROD,
                      P.TIPOCOMISSAO,
                      P.CODEPTO,
                      P.CODSEC,
                      P.CLASSE
               INTO   VCODPROD,
                      VPCOMINT1,
                      VPCOMEXT1,
                      VPCOMREP1,
                      VCODLINHAPROD,
                      VTIPOCOMISSAO,
                      VCODEPTO,
                      VCODSEC,
                      VCLASSE
               FROM   PCPRODUT P
               WHERE  P.CODPROD = REG.CODPROD;
            EXCEPTION
               WHEN OTHERS THEN
                  VPCOMINT1 := NULL;
            END;
         
            VNCODCOMISS       := NULL;
            VNCODROTINACOMISS := NULL;
            VSLETRACOMISS     := NULL;
            VSMENSAGEM_COMISS := NULL;
            VNPERLUC          := 0;
            IF NVL(REG.PVENDA, 0) <> 0
            THEN
               VNPERLUC := ((REG.PVENDA - REG.VLCUSTOFIN) / REG.PVENDA) * 100;
            END IF;
         
            VNPERDESC := REG.PERDESC;
         
            VNPERCOM := FUNCOESVENDAS.DEFINIR_COMISSAO_ITEM_VENDIDO(VNUMREGIAO, --OK
                                                                    VNPERLUC, --OK
                                                                    VNPERDESC, --OK
                                                                    VBUSAPCTABCOMISS, --OK
                                                                    VBUSAPCCOMISSAOUSUR, --OK
                                                                    VBUSAPCCOMISSAOPLPAG, --OK
                                                                    VBUSAPCCOMISSAOREGIAO, --OK
                                                                    VUSACOMISSAOPORRCA, --OK
                                                                    VORDEMAVALIACAOCOMISSAORCA, --OK
                                                                    VUSACOMISSAOPORCLIENTE, --OK ------> 10
                                                                    VUSACOMISSAOPORLINHAPROD, --OK
                                                                    VCOMISSAORCATIPOVENDA, --OK
                                                                    VTIPOVEND, --OK
                                                                    VPERCENT, --OK
                                                                    VPERCENT2, --OK
                                                                    VCODPROD, --OK
                                                                    VPCOMINT1, --OK
                                                                    VPCOMEXT1, --OK
                                                                    VPCOMREP1, --OK
                                                                    VCODLINHAPROD, --OK ------> 20
                                                                    VTIPOCOMISSAO, --OK
                                                                    VCODEPTO, --OK
                                                                    VCODSEC, --OK
                                                                    VCLASSE, --OK
                                                                    VTIPOVENDA, --OK
                                                                    VCODPLPAG, --OK
                                                                    VDATA, --OK
                                                                    VCODFILIAL, --OK
                                                                    VCODUSUR, --OK
                                                                    NVL(VCONSIDERARCOMISSAOZERO,
                                                                        'N'), --OK ------> 30
                                                                    NVL(VTIPOAVALIACAOCOMISSAO,
                                                                        1), --OK
                                                                    VPERCOMCLI, --OK
                                                                    VSLETRACOMISS, --OK
                                                                    VSMENSAGEM_COMISS --OK ------> 34
                                                                    );
            UPDATE PCPEDI
            SET    PERCOM = NVL(VNPERCOM, 0)
            WHERE  NUMPED = REG.NUMPED AND
                   CODPROD = REG.CODPROD AND
                   NUMSEQ = REG.NUMSEQ;
         END LOOP;
      END IF;
   END IMPORTAR_PEDIDO_WEB_PERCOM;

   FUNCTION IMPORTAR_PEDIDO_WEB_PROXNUMPED(PCODUSUR IN NUMBER) RETURN NUMBER IS
      VNPROXNUMPED PCPEDC.NUMPED%TYPE;
      VNNUMPED     PCPEDC.NUMPED%TYPE;
      VSEXISTE     VARCHAR2(1);
   BEGIN
      VSEXISTE := 'S';
   
      WHILE VSEXISTE = 'S'
      LOOP
         VNPROXNUMPED := FERRAMENTAS.F_PROX_NUMPED(PCODUSUR);
      
         BEGIN
            SELECT NUMPED
            INTO   VNNUMPED
            FROM   PCPEDC
            WHERE  NUMPED = VNPROXNUMPED;
         EXCEPTION
            WHEN OTHERS THEN
               VSEXISTE := 'N';
         END;
      END LOOP;
   
      RETURN VNPROXNUMPED;
   END IMPORTAR_PEDIDO_WEB_PROXNUMPED;

   FUNCTION IMPORTAR_PEDIDO_WEB_CREDITOCLI(P_CODCLI IN PCCLIENT.CODCLI%TYPE)
      RETURN NUMBER IS
   BEGIN
      RETURN FUNCOESVENDAS.BUSCARLIMCREDCLI(P_CODCLI, NULL, 'D', 'S');
   END IMPORTAR_PEDIDO_WEB_CREDITOCLI;

   FUNCTION IMPORTAR_PEDIDO_WEB_POSICAO
   (
      PNUMPEDWEB   IN NUMBER,
      PINTEGRADORA IN NUMBER,
      PCODUSUR     IN NUMBER,
      PCODFILIAL   IN VARCHAR2,
      PCODCOB      IN VARCHAR2
   ) RETURN VARCHAR2 IS
      VPOSICAO                VARCHAR2(1);
      VIMPORTARPEDIDOLIBERADO VARCHAR2(1);
      VORIGEMPED              VARCHAR2(1);
      VEXISTEBLOQUEIO         NUMBER(6, 0);
      VCODCOB                 PCCOB.CODCOB%TYPE;
      VQTDISPONIVEL           PCEST.QTESTGER%TYPE;
      VCODCLI                 PCPEDC.CODCLI%TYPE;
      VCODFILIAL              PCPEDC.CODFILIAL%TYPE;
      VPEDIDOB2B              NUMBER;
      VREGISTRO               NUMBER;
   BEGIN
      VIMPORTARPEDIDOLIBERADO := 'N';
      VPOSICAO                := 'P';
      VORIGEMPED              := 'W';
      VCODCOB                 := PCODCOB;
      VEXISTEBLOQUEIO         := 0;
      VPEDIDOB2B              := 0;
   
      BEGIN
         SELECT COUNT(PCECOMMERCEB2BPCPEDC.NUMPEDWEB) CONTADOR
         INTO   VPEDIDOB2B
         FROM   PCECOMMERCEB2BPCPEDC
         WHERE  PCECOMMERCEB2BPCPEDC.NUMPEDWEB = PNUMPEDWEB AND
                PCECOMMERCEB2BPCPEDC.CODFILIAL = PCODFILIAL AND
                PCECOMMERCEB2BPCPEDC.INTEGRADORA = PINTEGRADORA;
      EXCEPTION
         WHEN OTHERS THEN
            VPEDIDOB2B := 0;
      END;
   
      IF PINTEGRADORA = 29
      THEN
         --Ecommerce Unilever
         BEGIN
            VUNILEVER := 'N';
         
            SELECT COUNT(1)
            INTO   VREGISTRO
            FROM   PCECOMMERCEUNILEVER
            WHERE  PCECOMMERCEUNILEVER.CODFILIAL = PCODFILIAL;
         
            IF VREGISTRO > 0
            THEN
               VUNILEVER := 'S';
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               VUNILEVER := 'N';
         END;
      
         IF VPEDIDOB2B = 0
         THEN
            BEGIN
               SELECT CODCLI, CODFILIAL
               INTO   VCODCLI, VCODFILIAL
               FROM   PCPEDCTEMP
               WHERE  NUMPEDWEB = PNUMPEDWEB AND
                      ROWNUM = 1;
            
               VEXISTEBLOQUEIO := 0;
            
               SELECT COUNT(T.ORIGEMPED)
               INTO   VEXISTEBLOQUEIO
               FROM   (SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_AVISTA AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_07DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_14DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_21DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_28DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_CARTAO AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_TROCA AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEUNILEVER EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_BONIFICACAO AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)) T;
            
               VPOSICAO := 'B';
            EXCEPTION
               WHEN OTHERS THEN
                  VEXISTEBLOQUEIO := 0;
            END;
         END IF;
      END IF;
   
      IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
         --Ecommerce B2B
         IF VPEDIDOB2B > 0
         THEN
            BEGIN
               SELECT CODCLI, CODFILIAL
               INTO   VCODCLI, VCODFILIAL
               FROM   PCPEDCTEMP
               WHERE  NUMPEDWEB = PNUMPEDWEB AND
                      ROWNUM = 1;
            
               VEXISTEBLOQUEIO := 0;
            
               SELECT COUNT(T.ORIGEMPED)
               INTO   VEXISTEBLOQUEIO
               FROM   (SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_AVISTA AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_07DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_14DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_21DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_28DIAS AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_CARTAO AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_TROCA AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)
                       UNION
                       SELECT DISTINCT B.ORIGEMPED
                       FROM   PCBLOQUEIO B, PCECOMMERCEB2B EU
                       WHERE  B.ORIGEMPED = VORIGEMPED AND
                              B.CODCOB = EU.CODCOB_BONIFICACAO AND
                              EU.CODFILIAL = VCODFILIAL AND
                              B.CODCOB = VCODCOB AND
                              (B.CODCLI IS NULL OR B.CODCLI = VCODCLI)) T;
            
               VPOSICAO := 'B';
            EXCEPTION
               WHEN OTHERS THEN
                  VEXISTEBLOQUEIO := 0;
            END;
         END IF;
      END IF;
   
      IF VEXISTEBLOQUEIO > 0
      THEN
         VPOSICAO := 'B';
      ELSE
         VPOSICAO := 'P';
      END IF;
   
      IF VPOSICAO = 'B'
      THEN
         RETURN VPOSICAO;
      END IF;
   
      BEGIN
         SELECT VALOR
         INTO   VIMPORTARPEDIDOLIBERADO
         FROM   PCPARAMFILIAL
         WHERE  NOME = 'IMPORTARPEDIDOLIBERADOCOMMERCE' AND
                CODFILIAL = PCODFILIAL;
      EXCEPTION
         WHEN OTHERS THEN
            VIMPORTARPEDIDOLIBERADO := 'N';
      END;
   
      IF VIMPORTARPEDIDOLIBERADO = 'S'
      THEN
         VPOSICAO := 'L';
      
         FOR ITENS IN (SELECT I.CODPROD, SUM(I.QT) QTPEDIDA
                       FROM   PCPEDITEMP I
                       WHERE  I.NUMPEDWEB = PNUMPEDWEB AND
                              I.INTEGRADORA = PINTEGRADORA AND
                              I.CODUSUR = PCODUSUR
                       GROUP  BY I.CODPROD)
         LOOP
            VQTDISPONIVEL := PKG_ESTOQUE.ESTOQUE_DISPONIVEL(ITENS.CODPROD,
                                                            PCODFILIAL,
                                                            NULL,
                                                            TRUNC(SYSDATE));
         
            VGLOBAL_RETORNO_ESTOQUE := '';
         
            IF (VQTDISPONIVEL < ITENS.QTPEDIDA)
            THEN
               VPOSICAO := 'P';
            END IF;
         END LOOP;
      ELSE
         VPOSICAO := 'P';
      END IF;
   
      RETURN VPOSICAO;
   END IMPORTAR_PEDIDO_WEB_POSICAO;

   PROCEDURE IMPORTAR_PEDIDO_WEB_NORMAL_BNF
   (
      PNUMPEDWEB   IN NUMBER,
      PINTEGRADORA IN NUMBER,
      PCODUSUR     IN NUMBER,
      PCONDVENDA   IN NUMBER
   ) IS
      VIVA                      PCTRIBUT.IVA%TYPE;
      VIMPORTADO                VARCHAR2(1);
      VNUMPED                   NUMBER(10);
      VNUMPEDWEB                NUMBER(10);
      VCODCLI                   PCCLIENT.CODCLI%TYPE;
      VCODUSUR                  NUMBER(4);
      VVLTOTAL                  NUMBER(18, 6);
      VVLTABELA                 NUMBER(18, 6);
      VCODPLPAG                 NUMBER(6);
      VCODCOB                   VARCHAR2(5);
      VCODFILIAL                VARCHAR2(2);
      VPOSICAO                  VARCHAR2(1);
      VTOTPESO                  NUMBER(18, 6);
      VTOTPESOLIQ               NUMBER(18, 6);
      VCUSTOFIN                 NUMBER(18, 6);
      VCUSTOREAL                NUMBER(18, 6);
      VCUSTOCONT                NUMBER(18, 6);
      VCUSTOREP                 NUMBER(18, 6);
      VCODPROD                  NUMBER(10);
      VNUMITENS                 NUMBER(10);
      VCONDVENDA                NUMBER(6);
      VMENSAGEM                 VARCHAR2(3000);
      VERRO                     VARCHAR2(1);
      VCONTADOR                 NUMBER(6);
      VCODST                    NUMBER(4);
      VESTENT                   VARCHAR2(2);
      VVLFRETE                  NUMBER(18, 6);
      VDTENTREGA                DATE;
      VORIGEMPED                VARCHAR2(1);
      VPERCVENDA                NUMBER(5, 2);
      VVLOUTRASDESP             NUMBER(18, 6);
      VCODDISTRIB               VARCHAR2(4);
      VFRETEDESPACHO            VARCHAR2(1);
      VFRETEREDESPACHO          VARCHAR2(1);
      VINTEGRADORA29            VARCHAR2(1); --Ecommerce Unilever
      VPERMITEITEMBNFTV1        VARCHAR2(1);
      VCONTADORTV1              NUMBER(10, 0);
      VCONTADORTV5              NUMBER(10, 0);
      VVLPAUTAIPIVENDA          NUMBER(18, 6);
      VVLIPIPORKGVENDA          NUMBER(18, 6);
      VPESOBRUTO                NUMBER(18, 6);
      VPERCIPIVENDA             NUMBER(18, 6);
      VSCALCULARIPIVENDA        VARCHAR2(1);
      VNVLIPI                   NUMBER(18, 6);
      VNPERCIPI                 NUMBER(18, 6);
      VTIPOCALCIPI              VARCHAR2(2);
      VNUMCASASDECVENDA         NUMBER(2, 0);
      VVLBONIFIC                NUMBER(18, 6);
      VVLATEND                  NUMBER(18, 6);
      VCODSUPERVISOR            PCUSUARI.CODSUPERVISOR%TYPE;
      VPBONIFIC                 PCPEDI.PBONIFIC%TYPE;
      VCODEMITENTE              PCPEDC.CODEMITENTE%TYPE;
      VNUMCAR                   PCPEDC.NUMCAR%TYPE;
      VCODPRACA                 PCPRACA.CODPRACA%TYPE;
      VPERCOM                   PCPEDI.PERCOM%TYPE;
      VCODAUXILIAR              PCPEDI.CODAUXILIAR%TYPE;
      VPEDIDO_COMPLETO          VARCHAR2(1);
      VSMSGTEMP                 VARCHAR2(300);
      VNUMREGIAO                PCREGIAO.NUMREGIAO%TYPE;
      VCODPRACAPEDIDO           PCPRACA.CODPRACA%TYPE;
      VTIPOVENDA                PCPLPAG.TIPOVENDA%TYPE;
      VBLOQUEIO                 VARCHAR2(1);
      VVENDA_SEMIMPOSTOS        NUMBER(18, 6);
      VPVENDA                   PCPEDI.PVENDA%TYPE;
      VPTABELA                  PCPEDI.PTABELA%TYPE;
      VACEITAVENDABLOQ          VARCHAR2(1);
      VL_LIMITECLIENTE          NUMBER;
      COBRANCACORRETA           INTEGER;
      VVLDESCONTOCUPOM          NUMBER;
      VQT_PEDIDOB2B             NUMBER;
      VPEDIDOB2B_CONDICAO_VENDA NUMBER;
      VMATRICULA                NUMBER;
      VPEDIDOB2B                NUMBER;
      VPOSSUIPEDIDOBLOQUEADO    NUMBER;
      VQTPEDIDOS                INTEGER;
      VCODCOBFORMAPGTO          PCFORMAPGTOPEDIDO.CODCOB%TYPE;
      VCODPLPAGFORMAPGTO        PCFORMAPGTOPEDIDO.CODPLPAG%TYPE;
      VTOTALPVENDABNF           NUMBER(12, 2);
   BEGIN
      VGLOBAL_RETORNO_ESTOQUE   := ''; --1
      VPEDIDO_COMPLETO          := 'N';
      VPERCOM                   := 0;
      VNUMCAR                   := 0;
      VCODEMITENTE              := 8888;
      VCONDVENDA                := PCONDVENDA;
      VMENSAGEM                 := '';
      VERRO                     := 'N';
      VPOSICAO                  := 'P';
      VORIGEMPED                := 'W';
      VGLOBAL_ORIGEMPED         := VORIGEMPED;
      VPERCVENDA                := 100;
      VQT_PEDIDOB2B             := 0;
      VPEDIDOB2B_CONDICAO_VENDA := 0;
      VMATRICULA                := 0;
      VPEDIDOB2B                := 0;
      VPOSSUIPEDIDOBLOQUEADO    := 0;
      VQTPEDIDOS                := 0;
      VTOTALPVENDABNF           := 0;
   
      IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
         BEGIN
            SELECT DISTINCT PCBLOQUEIO.ORIGEMPED
            INTO   VINTEGRADORA29
            FROM   PCBLOQUEIO
            WHERE  PCBLOQUEIO.ORIGEMPED = VORIGEMPED;
         
            VPOSICAO := 'B';
         EXCEPTION
            WHEN OTHERS THEN
               VPOSICAO := 'P';
         END;
      END IF;
   
      BEGIN
         SELECT NVL(PCPEDCTEMP.IMPORTADO, 'N'),
                PCPEDCTEMP.NUMPED,
                PCPEDCTEMP.CODCLI,
                PCPEDCTEMP.CODUSUR,
                PCPEDCTEMP.CODPLPAG,
                PCPEDCTEMP.CODCOB,
                PCPEDCTEMP.CODFILIAL,
                PCPEDCTEMP.NUMPED,
                PCPEDCTEMP.VLFRETE,
                PCPEDCTEMP.DTENTREGA,
                NVL(NVL(PCPEDCTEMP.FRETEDESPACHO, C.FRETEDESPACHO), 'N') FRETEDESPACHO,
                PCPEDCTEMP.FRETEREDESPACHO,
                NVL(PCPEDCTEMP.CONDVENDA, 1) AS CONDVENDA,
                PCPEDCTEMP.CODPRACA,
                PCPEDCTEMP.VLDESCONTOCUPOM
         INTO   VIMPORTADO,
                VNUMPED,
                VCODCLI,
                VCODUSUR,
                VCODPLPAG,
                VCODCOB,
                VCODFILIAL,
                VNUMPED,
                VVLFRETE,
                VDTENTREGA,
                VFRETEDESPACHO,
                VFRETEREDESPACHO,
                VCONDVENDA,
                VCODPRACAPEDIDO,
                VVLDESCONTOCUPOM
         FROM   PCPEDCTEMP, PCCLIENT C
         WHERE  NVL(PCPEDCTEMP.CODCLINF, PCPEDCTEMP.CODCLI) = C.CODCLI(+) AND
                PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01001-Pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) ||
                         ' não foi encontrado nas tabelas temporárias;';
            VERRO     := 'S';
      END;
   
      VPOSICAO := IMPORTAR_PEDIDO_WEB_POSICAO(PNUMPEDWEB,
                                              PINTEGRADORA,
                                              PCODUSUR,
                                              VCODFILIAL,
                                              VCODCOB);
   
      IF (NVL(VGLOBAL_RETORNO_ESTOQUE, '') <> '')
      THEN
         VMENSAGEM := VMENSAGEM || VGLOBAL_RETORNO_ESTOQUE || ';';
         VERRO     := 'S';
      END IF;
      --VALIDANDO CABEÇALHO----------------------------------
      IF VIMPORTADO = 'S'
      THEN
         VMENSAGEM := VMENSAGEM || 'EC-01002-Pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' já importado;';
         VMENSAGEM := VMENSAGEM || 'Pedido Winthor de número ' ||
                      TO_CHAR(VNUMPED);
         VERRO     := 'S';
      END IF;
      ----Inicio -- Valida item bonificado na venda tv1
      IF VERRO = 'N'
      THEN
         VPERMITEITEMBNFTV1 := 'N';
      
         BEGIN
            SELECT NVL(PCPARAMFILIAL.VALOR, 'N') AS VALOR
            INTO   VPERMITEITEMBNFTV1
            FROM   PCPARAMFILIAL
            WHERE  PCPARAMFILIAL.NOME = 'PERMITEITEMBNFTV1' --Parâmetro 3045  da rotina 132
                   AND
                   PCPARAMFILIAL.CODFILIAL = '99';
         EXCEPTION
            WHEN OTHERS THEN
               VPERMITEITEMBNFTV1 := 'N';
         END;
      
         BEGIN
            SELECT COUNT(PCPEDITEMP.NUMPEDWEB) AS CONTADOR
            INTO   VCONTADORTV1
            FROM   PCPEDITEMP
            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                   NVL(PCPEDITEMP.BONIFIC, 'N') = 'N';
         EXCEPTION
            WHEN OTHERS THEN
               VCONTADORTV1 := 0;
         END;
      
         BEGIN
            SELECT COUNT(PCPEDITEMP.NUMPEDWEB) AS CONTADOR
            INTO   VCONTADORTV5
            FROM   PCPEDITEMP
            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                   NVL(PCPEDITEMP.BONIFIC, 'N') = 'F';
         EXCEPTION
            WHEN OTHERS THEN
               VCONTADORTV5 := 0;
         END;
      
         IF VCONTADORTV1 = 0 AND
            VCONTADORTV5 > 0 AND
            VPERMITEITEMBNFTV1 = 'S'
         THEN
            VMENSAGEM := VMENSAGEM || 'EC-01015-Pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) ||
                         ' possui somente itens bonificados;';
            VERRO     := 'S';
         END IF;
      
         IF VPERMITEITEMBNFTV1 = 'N' AND
            VCONTADORTV5 > 0 AND
            VERRO = 'N'
         THEN
            VMENSAGEM := VMENSAGEM || 'EC-01016-Pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) ||
                         ' possui itens bonificados, mas o parâmetro 3045, da rotina 132, está marcado como "Não". Deve ser alterado para "Sim";';
            VERRO     := 'S';
         END IF;
      END IF;
      ----Fim -- Valida item bonificado na venda tv1
      BEGIN
         SELECT PCCLIENT.CODCLI,
                PCCLIENT.ESTENT,
                PCCLIENT.CODPRACA,
                CASE
                   WHEN NVL(PCCLIENT.BLOQUEIO, 'N') = 'N' AND
                        NVL(PCCLIENT.BLOQUEIOSEFAZ, 'N') = 'N' THEN
                    'N'
                   ELSE
                    'S'
                END BLOQUEIO
         INTO   VNUMPEDWEB, VESTENT, VCODPRACA, VBLOQUEIO
         FROM   PCCLIENT
         WHERE  PCCLIENT.CODCLI = VCODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01003-Cliente de código ' ||
                         TO_CHAR(VCODCLI) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      IMPORTAR_PEDIDO_WEB_NUMREGIAO(VCODFILIAL,
                                    NVL(VCODPRACAPEDIDO, VCODPRACA),
                                    VCODCLI,
                                    VNUMREGIAO);
   
      BEGIN
         SELECT PCUSUARI.CODUSUR,
                PCUSUARI.CODDISTRIB,
                PCUSUARI.CODSUPERVISOR
         INTO   VCODUSUR, VCODDISTRIB, VCODSUPERVISOR
         FROM   PCUSUARI
         WHERE  PCUSUARI.CODUSUR = VCODUSUR;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01004-RCA de código ' ||
                         TO_CHAR(VCODUSUR) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCPLPAG.CODPLPAG,
                PCPLPAG.TIPOVENDA,
                PRAZO1,
                PRAZO2,
                PRAZO3,
                PRAZO4,
                PRAZO5,
                PRAZO6,
                PRAZO7,
                PRAZO8,
                PRAZO9,
                PRAZO10,
                PRAZO11,
                PRAZO12,
                NUMDIAS
         INTO   VCODPLPAG,
                VTIPOVENDA,
                VPRAZO1,
                VPRAZO2,
                VPRAZO3,
                VPRAZO4,
                VPRAZO5,
                VPRAZO6,
                VPRAZO7,
                VPRAZO8,
                VPRAZO9,
                VPRAZO10,
                VPRAZO11,
                VPRAZO12,
                VNUMDIAS
         FROM   PCPLPAG
         WHERE  PCPLPAG.CODPLPAG = VCODPLPAG;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01005-Plano de pagamento de código ' ||
                         TO_CHAR(VCODPLPAG) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCCOB.CODCOB
         INTO   VCODCOB
         FROM   PCCOB
         WHERE  PCCOB.CODCOB = VCODCOB;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01006-Cobrança de código ' ||
                         (VCODCOB) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCFILIAL.CODIGO
         INTO   VCODFILIAL
         FROM   PCFILIAL
         WHERE  PCFILIAL.CODIGO = VCODFILIAL;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01007-Filial de código ' ||
                         (VCODFILIAL) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      IF VERRO = 'S'
      THEN
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(OBSERVACAO_PC || VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      END IF;
      --VALIDANDO ITENS----------------------------------
      BEGIN
         SELECT COUNT(PCPEDITEMP.NUMPEDWEB) AS CONTADOR
         INTO   VCONTADOR
         FROM   PCPEDITEMP
         WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDITEMP.CODUSUR = PCODUSUR AND
                PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01008-Não existe itens para o pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) || ' nas tabelas temporárias;';
            VERRO     := 'S';
      END;
   
      IF VCONTADOR = 0
      THEN
         VMENSAGEM := VMENSAGEM ||
                      'EC-01008-Não existe itens para o pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' nas tabelas temporárias;';
         VERRO     := 'S';
      END IF;
   
      IF VERRO = 'N'
      THEN
         FOR REGCAB IN (SELECT *
                        FROM   PCPEDCTEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               PCPEDCTEMP.CONDVENDA = VCONDVENDA)
         LOOP
            FOR REGITEM IN (SELECT PCPEDITEMP.*, ROWID
                            FROM   PCPEDITEMP
                            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED)
            LOOP
               VMENSAGEM := '';
            
               BEGIN
                  SELECT PCPRODUT.CODPROD
                  INTO   VCODPROD
                  FROM   PCPRODUT
                  WHERE  PCPRODUT.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VMENSAGEM := VMENSAGEM ||
                                  'EC-01009-Produto de código ' ||
                                  TO_CHAR(REGITEM.CODPROD) ||
                                  ' não foi encontrado;';
                     VERRO     := 'S';
               END;
            
               BEGIN
                  SELECT PCEST.CODFILIAL, PCEST.CODPROD
                  INTO   VCODFILIAL, VCODPROD
                  FROM   PCEST
                  WHERE  PCEST.CODFILIAL = REGCAB.CODFILIAL AND
                         PCEST.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VMENSAGEM := VMENSAGEM ||
                                  'EC-01010-Produto de código ' ||
                                  TO_CHAR(REGITEM.CODPROD) ||
                                  ' não foi encontrado na filial de código ' ||
                                  REGCAB.CODFILIAL || ';';
                     VERRO     := 'S';
               END;
            
               IMPORTAR_PEDIDO_WEB_CODST(REGCAB.CODFILIAL,
                                         REGITEM.CODPROD,
                                         VESTENT,
                                         NVL(REGCAB.CODPRACA, VCODPRACA),
                                         VCODST,
                                         VCODCLI,
                                         PINTEGRADORA);
               IF VCODST <= 0
               THEN
                  VMENSAGEM := VMENSAGEM || 'EC-01011-Produto de código ' ||
                               TO_CHAR(REGITEM.CODPROD) ||
                               ' não possui código de st;';
                  VERRO     := 'S';
               END IF;
            
               IF VERRO = 'S'
               THEN
                  UPDATE PCPEDITEMP
                  SET    OBSERVACAO_PC = SUBSTR(OBSERVACAO_PC || VMENSAGEM,
                                                1,
                                                300)
                  WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                         PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                         PCPEDITEMP.CODUSUR = PCODUSUR AND
                         PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                         PCPEDITEMP.CODPROD = REGITEM.CODPROD AND
                         PCPEDITEMP.NUMSEQ = REGITEM.NUMSEQ;
               
                  COMMIT;
               END IF;
            END LOOP; --FIM LOOP ITEM
         END LOOP; --FIM LOOP CABEÇALHO
      END IF;
      ---OBTENDO O PRÓXIMO NÚMERO DE PEDIDO---------------------------------
      IF VERRO = 'N'
      THEN
         VNUMPED := IMPORTAR_PEDIDO_WEB_PROXNUMPED(VCODUSUR);
      
         IF VNUMPED = 0
         THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01012-Erro ao gerar próximo número de pedido;';
            VERRO     := 'S';
         END IF;
      END IF;
      ---MONTANDO DO PEDIDO---------------------------------
      IF VERRO = 'N'
      THEN
         FOR REGCAB IN (SELECT *
                        FROM   PCPEDCTEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               PCPEDCTEMP.CONDVENDA = VCONDVENDA)
         LOOP
            FOR REGITEM IN (SELECT *
                            FROM   PCPEDITEMP
                            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED)
            LOOP
               BEGIN
                  SELECT NVL(PCEST.CUSTOFIN, 0) CUSTOFIN,
                         NVL(PCEST.CUSTOREAL, 0) CUSTOREAL,
                         NVL(PCEST.CUSTOCONT, 0) CUSTOCONT,
                         NVL(PCEST.CUSTOREP, 0) CUSTOREP
                  INTO   VCUSTOFIN, VCUSTOREAL, VCUSTOCONT, VCUSTOREP
                  FROM   PCEST
                  WHERE  PCEST.CODFILIAL = REGCAB.CODFILIAL AND
                         PCEST.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VCUSTOFIN  := 0;
                     VCUSTOREAL := 0;
               END;
            
               VPBONIFIC := NULL;
               VPVENDA   := NVL(VPBONIFIC, REGITEM.PVENDA);
               VPTABELA  := NVL(VPBONIFIC, REGITEM.PVENDA);
               IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
                  IF NVL(REGITEM.BONIFIC, 'N') = 'F'
                  THEN
                     BEGIN
                        SELECT NVL(PCTABPR.PTABELA, 0)
                        INTO   VPBONIFIC
                        FROM   PCTABPR, PCPRACA, PCCLIENT
                        WHERE  PCPRACA.CODPRACA = PCCLIENT.CODPRACA AND
                               PCTABPR.NUMREGIAO = PCPRACA.NUMREGIAO AND
                               PCCLIENT.CODCLI = VCODCLI AND
                               PCTABPR.CODPROD = REGITEM.CODPROD;
                     EXCEPTION
                        WHEN OTHERS THEN
                           VPBONIFIC := NULL;
                     END;
                     VPVENDA         := NVL(VPBONIFIC, REGITEM.PVENDA);
                     VPTABELA        := NVL(VPBONIFIC, REGITEM.PVENDA);
                     VTOTALPVENDABNF := VTOTALPVENDABNF +
                                        (VPVENDA * REGITEM.QT);
                  ELSE
                     VPVENDA  := REGITEM.PVENDA;
                     VPTABELA := NVL(REGITEM.PTABELA, REGITEM.PVENDA);
                  END IF;
               END IF;
            
               BEGIN
                  IMPORTAR_PEDIDO_WEB_CODST(REGCAB.CODFILIAL,
                                            REGITEM.CODPROD,
                                            VESTENT,
                                            NVL(REGCAB.CODPRACA, VCODPRACA),
                                            VCODST,
                                            VCODCLI,
                                            PINTEGRADORA);
               EXCEPTION
                  WHEN OTHERS THEN
                     NULL;
               END;
            
               BEGIN
                  SELECT VALORSEMIMPOSTO
                  INTO   VVENDA_SEMIMPOSTOS
                  FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(REGCAB.CODFILIAL,
                                                                          NVL(REGCAB.CODFILIALNF,
                                                                              REGCAB.CODFILIAL),
                                                                          REGITEM.CODFILIALRETIRA,
                                                                          REGCAB.CODCLI,
                                                                          REGCAB.CODPLPAG,
                                                                          REGITEM.CODPROD,
                                                                          REGITEM.CODAUXILIAR,
                                                                          NVL(NVL(REGCAB.CONDVENDA,
                                                                                  VCONDVENDA),
                                                                              1),
                                                                          'N',
                                                                          0,
                                                                          0,
                                                                          VPVENDA,
                                                                          'N',
                                                                          'P',
                                                                          'N',
                                                                          0,
                                                                          NULL,
                                                                          'N',
                                                                          'N',
                                                                          'N',
                                                                          'N',
                                                                          NULL,
                                                                          NULL,
                                                                          'I',
                                                                          NULL,
                                                                          REGCAB.CODENDENTCLI));
               EXCEPTION
                  WHEN OTHERS THEN
                     VVENDA_SEMIMPOSTOS := 0;
               END;
            
               BEGIN
                  SELECT VALORIPI
                  INTO   VVLIPI_PTABELA
                  FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(REGCAB.CODFILIAL,
                                                           REGCAB.CODFILIALNF,
                                                           REGCAB.CODFILIAL,
                                                           REGCAB.CODCLI,
                                                           REGITEM.CODPROD,
                                                           REGITEM.CODAUXILIAR,
                                                           VCONDVENDA,
                                                           'N',
                                                           VVENDA_SEMIMPOSTOS,
                                                           'N',
                                                           REGCAB.CODENDENTCLI,
                                                           'N', --transferencia
                                                           'N', --transferenciaVirtual
                                                           'N',
                                                           'F',
                                                           NULL,
                                                           'I',
                                                           0,
                                                           'S',
                                                           'N' --VEN-1315
                                                           ));
               EXCEPTION
                  WHEN OTHERS THEN
                     VVLIPI_PTABELA := 0;
               END;
            
               BEGIN
                  SELECT NVL(T.IVA, 0) IVA
                  INTO   VIVA
                  FROM   PCTRIBUT T
                  WHERE  T.CODST = VCODST;
               EXCEPTION
                  WHEN OTHERS THEN
                     VIVA := 0;
               END;
               --Cálculo de IPI
               BEGIN
                  BEGIN
                     SELECT PCPRODUT.VLPAUTAIPIVENDA,
                            PCPRODUT.VLIPIPORKGVENDA,
                            PCPRODUT.PESOBRUTO,
                            PCPRODUT.PERCIPIVENDA
                     INTO   VVLPAUTAIPIVENDA,
                            VVLIPIPORKGVENDA,
                            VPESOBRUTO,
                            VPERCIPIVENDA
                     FROM   PCPRODUT
                     WHERE  PCPRODUT.CODPROD = REGITEM.CODPROD;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMENSAGEM := VMENSAGEM ||
                                     'EC-01009-Produto de código ' ||
                                     TO_CHAR(REGITEM.CODPROD) ||
                                     ' não foi encontrado;';
                        VERRO     := 'S';
                  END;
               
                  BEGIN
                     SELECT NVL(PCFILIAL.CALCULARIPIVENDA, 'N')
                     INTO   VSCALCULARIPIVENDA
                     FROM   PCFILIAL
                     WHERE  PCFILIAL.CODIGO = REGCAB.CODFILIAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VSCALCULARIPIVENDA := 'N';
                  END;
               
                  IF VSCALCULARIPIVENDA = 'N'
                  THEN
                     VNVLIPI := 0;
                  ELSE
                     IF VVLPAUTAIPIVENDA > 0
                     THEN
                        VNVLIPI := VVLPAUTAIPIVENDA;
                     ELSE
                        IF VVLIPIPORKGVENDA > 0
                        THEN
                           VNVLIPI := VPESOBRUTO * VVLIPIPORKGVENDA;
                        ELSE
                           IF VPERCIPIVENDA > 0
                           THEN
                              VNVLIPI   := VVENDA_SEMIMPOSTOS *
                                           (VPERCIPIVENDA / 100);
                              VNPERCIPI := VPERCIPIVENDA;
                           END IF;
                        END IF;
                     END IF;
                  
                     BEGIN
                        SELECT TIPOCALCIPI, NUMCASASDECVENDA
                        INTO   VTIPOCALCIPI, VNUMCASASDECVENDA
                        FROM   PCCONSUM;
                     END;
                  
                     IF VTIPOCALCIPI = 'T2'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI * 100) / 100;
                     ELSIF VTIPOCALCIPI = 'A2'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI, 2);
                     ELSIF VTIPOCALCIPI = 'PV'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI, VNUMCASASDECVENDA);
                     END IF;
                  END IF;
               EXCEPTION
                  WHEN OTHERS THEN
                     VNVLIPI   := 0;
                     VNPERCIPI := 0;
               END;
            
               BEGIN
                  SELECT NVL(P.PESOBRUTO, 0) PESOBRUTO, P.CODAUXILIAR
                  INTO   VPESOBRUTO, VCODAUXILIAR
                  FROM   PCPRODUT P
                  WHERE  P.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPESOBRUTO   := 0;
                     VCODAUXILIAR := NULL;
               END;
            
               IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
                  VCODAUXILIAR := NVL(REGITEM.CODAUXILIAR, VCODAUXILIAR);
               END IF;
            
               VGLOBAL_ORIGEMPED := VORIGEMPED;
               VGLOBAL_CODPLPAG  := REGCAB.CODPLPAG;
               VGLOBAL_CODFILIAL := REGCAB.CODFILIAL;
               VGLOBAL_NUMREGIAO := VNUMREGIAO;
            
               IF VBLOQUEIO = 'S'
               THEN
                  VPOSICAO := 'B';
               END IF;
            
               BEGIN
                  SELECT NVL(ACEITAVENDABLOQ, 'N')
                  INTO   VACEITAVENDABLOQ
                  FROM   PCCONSUM;
               EXCEPTION
                  WHEN OTHERS THEN
                     VACEITAVENDABLOQ := 'N';
               END;
            
               BEGIN
                  SELECT SUM(NVL(PCPEDITEMP.QT, 0) *
                             NVL(PCPEDITEMP.PVENDA, 0)) VLTOTAL
                  INTO   VVLTOTAL
                  FROM   PCPEDITEMP
                  WHERE  NUMPEDWEB = REGITEM.NUMPEDWEB;
               EXCEPTION
                  WHEN OTHERS THEN
                     VVLTOTAL := 0;
               END;
            
               BEGIN
                  SELECT COUNT(C.CODCOB)
                  INTO   COBRANCACORRETA
                  FROM   PCCOB C
                  WHERE  NVL(C.CARTAO, 'N') = 'N' AND
                         C.CODCOB <> 'D' AND
                         C.CODCOB = REGCAB.CODCOB;
               EXCEPTION
                  WHEN OTHERS THEN
                     COBRANCACORRETA := 0;
               END;
            
               IF VACEITAVENDABLOQ = 'S'
               THEN
                  VL_LIMITECLIENTE := IMPORTAR_PEDIDO_WEB_CREDITOCLI(REGCAB.CODCLI);
                  IF VL_LIMITECLIENTE < VVLTOTAL
                  THEN
                     IF COBRANCACORRETA > 0
                     THEN
                        VPOSICAO := 'B';
                     END IF;
                  END IF;
               END IF;
            
               IMPORTAR_PEDIDO_WEB_PCPEDI(VNUMPED --01
                                         ,
                                          REGITEM.CODPROD --02
                                         ,
                                          REGITEM.NUMSEQ --03
                                         ,
                                          TRUNC(SYSDATE) --04
                                         ,
                                          REGITEM.QT --05
                                         ,
                                          REGITEM.PVENDA --06
                                         ,
                                          VPTABELA --07
                                         ,
                                          NVL(REGCAB.CODCLI,
                                              REGCAB.CODCLINF) --08
                                         ,
                                          VCODUSUR --09
                                         ,
                                          VPOSICAO --10
                                         ,
                                          VCUSTOFIN --11
                                         ,
                                          VCUSTOREAL --12
                                         ,
                                          VPERCOM --13
                                         ,
                                          NVL(REGITEM.PERDESC, 0) --14
                                         ,
                                          REGITEM.CODFILIALRETIRA --15
                                         ,
                                          VPESOBRUTO --16
                                         ,
                                          VCUSTOCONT --17
                                         ,
                                          VCUSTOREP --18
                                         ,
                                          CASE WHEN
                                          NVL(REGITEM.BONIFIC, 'N') = 'F' THEN
                                          VPBONIFIC ELSE NULL END --19
                                         ,
                                          NVL(REGITEM.BONIFIC, 'N') --20
                                         ,
                                          VNVLIPI --21
                                         ,
                                          VNPERCIPI --22
                                         ,
                                          NVL(REGITEM.PTABELA,
                                              REGITEM.PVENDA) --23
                                         ,
                                          VNUMCAR --24
                                         ,
                                          VCODAUXILIAR --25
                                         ,
                                          VIVA --26
                                         ,
                                          REGITEM.QTUNITEMB --27
                                         ,
                                          VNUMREGIAO --28
                                         ,
                                          VCODST --29
                                         ,
                                          REGCAB.CODFILIAL --30
                                         ,
                                          REGCAB.CODFILIALNF --31
                                         ,
                                          NVL(REGITEM.CODPLPAG, VCODPLPAG) --32
                                         ,
                                          NVL(REGCAB.CONDVENDA, VCONDVENDA) --33
                                         ,
                                          VVENDA_SEMIMPOSTOS --34
                                          );
            END LOOP; --FIM LOOP ITEM
         
            VVLBONIFIC          := 0;
            VGLOBAL_VLCUSTOFIN  := 0;
            VGLOBAL_VLCUSTOREAL := 0;
            VGLOBAL_VLCUSTOREP  := 0;
            VGLOBAL_VLCUSTOCONT := 0;
         
            SELECT SUM(PCPEDI.QT * PCPEDI.PVENDA) AS VLTOTAL,
                   SUM(PCPEDI.QT * PCPEDI.PTABELA) AS VLTABELA,
                   SUM(PCPEDI.QT * PCPEDI.PVENDA * CASE
                          WHEN NVL(PCPEDI.BONIFIC, 'N') = 'N' THEN
                           1
                          ELSE
                           0
                       END) AS VLATEND,
                   SUM(PCPEDI.QT * PCPEDI.PBONIFIC * CASE
                          WHEN NVL(PCPEDI.BONIFIC, 'N') = 'F' THEN
                           1
                          ELSE
                           0
                       END) AS VLBONIFIC,
                   SUM(PCPEDI.QT * PCPRODUT.PESOBRUTO) AS TOTPESO,
                   SUM(PCPEDI.QT * PCPRODUT.PESOLIQ) AS TOTPESOLIQ,
                   COUNT(PCPEDI.CODPROD) AS NUMITENS,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN) AS VLCUSTOFIN,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL) AS VLCUSTOREAL,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP) AS VLCUSTOREP,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT) AS VLCUSTOCONT
            INTO   VVLTOTAL,
                   VVLTABELA,
                   VVLATEND,
                   VVLBONIFIC,
                   VTOTPESO,
                   VTOTPESOLIQ,
                   VNUMITENS,
                   VGLOBAL_VLCUSTOFIN,
                   VGLOBAL_VLCUSTOREAL,
                   VGLOBAL_VLCUSTOREP,
                   VGLOBAL_VLCUSTOCONT
            FROM   PCPEDI, PCPRODUT
            WHERE  PCPEDI.NUMPED = VNUMPED AND
                   PCPRODUT.CODPROD = PCPEDI.CODPROD;
         
            VVLOUTRASDESP          := NVL(REGCAB.VLOUTRASDESP, 0);
            VVLTOTAL               := NVL(VVLTOTAL, 0) + NVL(VVLFRETE, 0) +
                                      VVLOUTRASDESP;
            VVLTABELA              := NVL(VVLTABELA, 0) + NVL(VVLFRETE, 0) +
                                      VVLOUTRASDESP;
            VVLATEND               := NVL(VVLATEND, 0) + NVL(VVLFRETE, 0) +
                                      VVLOUTRASDESP;
            VCODEMITENTE           := NVL(REGCAB.CODEMITENTE, '8888');
            VGLOBAL_OBSENTREGA4    := REGCAB.OBSENTREGA4;
            VGLOBAL_CODTRANSP      := CASE WHEN NVL(REGCAB.CODTRANSP, 0) > 0 THEN REGCAB.CODTRANSP ELSE NULL END;
            VGLOBAL_TIPOVENDA      := VTIPOVENDA;
            VGLOBAL_CODFORNECFRETE := CASE WHEN NVL(REGCAB.CODFORNECFRETE, 0) > 0 THEN REGCAB.CODFORNECFRETE ELSE NULL END;
            VGLOBAL_CODENDENTCLI   := REGCAB.CODENDENTCLI;
            VGLOBAL_OBS2           := REGCAB.OBS2;
         
            IMPORTAR_PEDIDO_WEB_PCPEDC(VNUMPED,
                                       TRUNC(SYSDATE),
                                       REGCAB.CODFILIAL,
                                       REGCAB.CODFILIALNF,
                                       REGCAB.CODCLI,
                                       REGCAB.CODUSUR,
                                       REGCAB.CODPLPAG,
                                       REGCAB.CODCOB,
                                       VVLTOTAL,
                                       VVLATEND,
                                       VVLTABELA,
                                       VPOSICAO,
                                       NVL(REGCAB.CODPRACA, VCODPRACA),
                                       PNUMPEDWEB,
                                       TO_CHAR(PNUMPEDWEB),
                                       PNUMPEDWEB,
                                       PINTEGRADORA,
                                       VTOTPESO,
                                       VTOTPESOLIQ,
                                       VORIGEMPED,
                                       VNUMITENS,
                                       VCONDVENDA,
                                       VVLFRETE,
                                       NVL(VDTENTREGA, TRUNC(SYSDATE)),
                                       VPERCVENDA,
                                       VVLOUTRASDESP,
                                       VCODDISTRIB,
                                       VFRETEDESPACHO,
                                       VFRETEREDESPACHO,
                                       VCODSUPERVISOR,
                                       VVLBONIFIC,
                                       VCODEMITENTE,
                                       REGCAB.OBS1,
                                       VNUMCAR,
                                       TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                                       TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                                       VNUMREGIAO,
                                       VVLDESCONTOCUPOM,
                                       'N',
                                       'N',
                                       REGCAB.CNPJINTERMEDIADOR,
                                       REGCAB.DESCINTERMEDIADOR,
									   REGCAB.CODBNF);
         
            IMPORTAR_PEDIDO_WEB_PERCOM(VNUMPED);
            IMPORTAR_PEDIDO_WEB_ESTOQUEPKG(VNUMPED, VPOSICAO);
         
            IF (NVL(VGLOBAL_RETORNO_ESTOQUE, '') <> '')
            THEN
               VERRO     := 'S';
               VMENSAGEM := VMENSAGEM || VGLOBAL_RETORNO_ESTOQUE || ';';
            END IF;
         
            IF (REGCAB.INTEGRADORA IN (29, 33, 34, 36) OR REGCAB.INTEGRADORA > 999) AND
               REGCAB.CONDVENDA <> 5
            THEN
               -- Possui item bonificado no pedido
               IF VCONTADORTV5 > 0
               THEN
                  -- Valida PCPRESTTEMP em pedido com multiplas forma de pagamento 2697
                  BEGIN
                     SELECT COUNT(E.NUMPEDWEB) CONTADOR
                     INTO   VQTPEDIDOS
                     FROM   PCPRESTTEMP E
                     WHERE  E.NUMPEDWEB = PNUMPEDWEB;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VQTPEDIDOS := 0;
                  END;
               
                  IF VQTPEDIDOS > 1
                  THEN
                     BEGIN
                        SELECT CODCOB_BONIFICACAO, CODPLPAG_BONIFICACAO
                        INTO   VCODCOBFORMAPGTO, VCODPLPAGFORMAPGTO
                        FROM   PCECOMMERCEUNILEVER
                        WHERE  PCECOMMERCEUNILEVER.CODFILIAL =
                               REGCAB.CODFILIAL;
                     EXCEPTION
                        WHEN OTHERS THEN
                           VCODCOBFORMAPGTO   := 0;
                           VCODPLPAGFORMAPGTO := 0;
                     END;
                  
                     FOR REG IN (SELECT E.*
                                 FROM   PCPRESTTEMP E
                                 WHERE  E.NUMPEDWEB = PNUMPEDWEB)
                     LOOP
                        INSERT INTO PCPRESTTEMP
                           (IDTITULO,
                            TIPOINTEGRACAO,
                            INTEGRADORA,
                            CODCLI,
                            CODUSUR,
                            VALOR,
                            DTEMISSAO,
                            CODCOB,
                            NOSSONUMBCO,
                            VLTXBOLETO,
                            IDPONTOVENDA,
                            NUMPEDWEB,
                            CODPLPAG,
                            CODAUTTEF,
                            PRESTTEF,
                            PREST,
                            NSUTEF,
                            DTINCLUSAO,
                            DTTRANSACAOCC,
                            DTVENC,
                            CONFIRMADO)
                        VALUES
                           (DFSEQ_PCPRESTTEMP_IDTITULO.NEXTVAL,
                            REG.TIPOINTEGRACAO,
                            REG.INTEGRADORA,
                            REG.CODCLI,
                            REG.CODUSUR,
                            VTOTALPVENDABNF,
                            REG.DTEMISSAO,
                            VCODCOBFORMAPGTO,
                            REG.NOSSONUMBCO,
                            REG.VLTXBOLETO,
                            REG.IDPONTOVENDA,
                            REG.NUMPEDWEB,
                            VCODPLPAGFORMAPGTO,
                            REG.CODAUTTEF,
                            REG.PRESTTEF,
                            REG.PREST,
                            REG.NSUTEF,
                            REG.DTINCLUSAO,
                            REG.DTTRANSACAOCC,
                            REG.DTVENC,
                            REG.CONFIRMADO);
                        EXIT;
                     END LOOP;
                  END IF;
                  -- Valida PCFORMAPGTOPEDIDOTEMP em pedido com multiplas forma de pagamento 2696
                  BEGIN
                     SELECT COUNT(E.NUMPEDWEB) CONTADOR
                     INTO   VQTPEDIDOS
                     FROM   PCFORMAPGTOPEDIDOTEMP E
                     WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                            E.CODFILIAL = REGCAB.CODFILIAL AND
                            E.INTEGRADORA = REGCAB.INTEGRADORA;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VQTPEDIDOS := 0;
                  END;
               
                  IF VQTPEDIDOS > 1
                  THEN
                     BEGIN
                        SELECT CODCOB_BONIFICACAO, CODPLPAG_BONIFICACAO
                        INTO   VCODCOBFORMAPGTO, VCODPLPAGFORMAPGTO
                        FROM   PCECOMMERCEB2B
                        WHERE  PCECOMMERCEB2B.CODFILIAL = REGCAB.CODFILIAL AND
                               PCECOMMERCEB2B.TIPOINTEGRACAO =
                               REGCAB.INTEGRADORA;
                     EXCEPTION
                        WHEN OTHERS THEN
                           VCODCOBFORMAPGTO   := 0;
                           VCODPLPAGFORMAPGTO := 0;
                     END;
                  
                     FOR REG IN (SELECT *
                                 FROM   PCFORMAPGTOPEDIDOTEMP
                                 WHERE  NUMPEDWEB = PNUMPEDWEB)
                     LOOP
                        INSERT INTO PCFORMAPGTOPEDIDOTEMP
                           (NUMPEDRCA,
                            NUMPEDWEB,
                            NUMPEDCLI,
                            INTEGRADORA,
                            NUMPED,
                            CODUSUR,
                            DTINCLUSAO,
                            CODCOB,
                            CODPLPAG,
                            DTVENC,
                            VALOR,
                            TIPOINTEGRACAO,
                            CNPJCREDCARTAO,
                            NUMAUTORIZACAO,
                            VLRTROCO,
                            VLENTRADA,
                            CODFILIAL)
                        VALUES
                           (REG.NUMPEDRCA,
                            REG.NUMPEDWEB,
                            REG.NUMPEDCLI,
                            REG.INTEGRADORA,
                            REG.NUMPED,
                            REG.CODUSUR,
                            REG.DTINCLUSAO,
                            VCODCOBFORMAPGTO,
                            VCODPLPAGFORMAPGTO,
                            REG.DTVENC,
                            VTOTALPVENDABNF,
                            REG.TIPOINTEGRACAO,
                            REG.CNPJCREDCARTAO,
                            REG.NUMAUTORIZACAO,
                            REG.VLRTROCO,
                            REG.VLENTRADA,
                            REG.CODFILIAL);
                        EXIT;
                     END LOOP;
                  END IF;
               END IF;
            
               IMPORTAR_PEDIDO_PCFORMAPAGTO(PNUMPEDWEB, VNUMPED);
            END IF;
         
            IF VPOSICAO = 'B'
            THEN
               BEGIN
                  SELECT COUNT(PCECOMMERCEB2BPCPEDC.NUMPEDWEB) AS CONTADOR
                  INTO   VPEDIDOB2B
                  FROM   PCECOMMERCEB2BPCPEDC
                  WHERE  PCECOMMERCEB2BPCPEDC.NUMPEDWEB = VNUMPED AND
                         PCECOMMERCEB2BPCPEDC.CODFILIAL = VCODFILIAL AND
                         PCECOMMERCEB2BPCPEDC.INTEGRADORA = PINTEGRADORA;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPEDIDOB2B := 0;
               END;
            
               IF VPEDIDOB2B > 0
               THEN
                  BEGIN
                     SELECT PCECOMMERCEB2B.MATRICULA
                     INTO   VMATRICULA
                     FROM   PCECOMMERCEB2B
                     WHERE  PCECOMMERCEB2B.CODFILIAL = VCODFILIAL AND
                            PCECOMMERCEB2B.TIPOINTEGRACAO = PINTEGRADORA;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMATRICULA := 0;
                  END;
               ELSE
                  BEGIN
                     SELECT PCECOMMERCEUNILEVER.MATRICULA
                     INTO   VMATRICULA
                     FROM   PCECOMMERCEUNILEVER
                     WHERE  PCECOMMERCEUNILEVER.CODFILIAL = VCODFILIAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMATRICULA := 0;
                  END;
               END IF;
            
               PKG_MOTIVOBLOQUEIO.VALIDAMOTIVOSBLOQUEIO(VNUMPED,
                                                        VMATRICULA,
                                                        2500);
            
               DELETE FROM PCBLOQUEIOSPEDIDO
               WHERE  PCBLOQUEIOSPEDIDO.NUMPED = VNUMPED AND
                      PCBLOQUEIOSPEDIDO.CODMOTIVO IN
                      (1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24);
            
               BEGIN
                  SELECT COUNT(PCBLOQUEIOSPEDIDO.NUMPED) CONTADOR
                  INTO   VPOSSUIPEDIDOBLOQUEADO
                  FROM   PCBLOQUEIOSPEDIDO
                  WHERE  PCBLOQUEIOSPEDIDO.NUMPED = VNUMPED;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPOSSUIPEDIDOBLOQUEADO := 0;
               END;
            
               IF VPOSSUIPEDIDOBLOQUEADO = 0
               THEN
                  PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(VNUMPED,
                                                  25,
                                                  'PEDIDOS DA INTEGRACAO',
                                                  'C');
               END IF;
            END IF;
         END LOOP; --FIM LOOP CABEÇALHO
      
         BEGIN
            UPDATE PCPEDCTEMP
            SET    IMPORTADO      = 'S',
                   NUMPED         = VNUMPED,
                   OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
            WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                   PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                   PCPEDCTEMP.CODUSUR = PCODUSUR AND
                   PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                   PCPEDCTEMP.CONDVENDA = VCONDVENDA;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      
         IMPORTAR_PEDIDO_WEB_COMPLETO(VNUMPED, VPEDIDO_COMPLETO);
      
         IF VPEDIDO_COMPLETO = 'N'
         THEN
            VERRO     := 'S';
            VMENSAGEM := VMENSAGEM ||
                         'EC-01013-Pedido gerado com ausência de cabeçalho e/ou item;';
         END IF;
      
         VSMSGTEMP := '';
      
         BEGIN
            SELECT COUNT(E.NUMPEDWEB) CONTADOR
            INTO   VQT_PEDIDOB2B
            FROM   PCFORMAPGTOPEDIDOTEMP E
            WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                   E.INTEGRADORA = PINTEGRADORA AND
                   E.CODFILIAL = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VQT_PEDIDOB2B := 0;
         END;
      
         BEGIN
            SELECT CONDVENDA
            INTO   VPEDIDOB2B_CONDICAO_VENDA
            FROM   PCPEDCTEMP E
            WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                   E.INTEGRADORA = PINTEGRADORA AND
                   E.CODFILIAL = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VPEDIDOB2B_CONDICAO_VENDA := 0;
         END;
      
         IF VQT_PEDIDOB2B > 1 AND
            VPEDIDOB2B_CONDICAO_VENDA <> 5
         THEN
            IF IMPORTARVENDASMULTIPAG.FUNC_VALIDAR_MULT_PLANOS_WEB(PNUMPEDWEB,
                                                                   PCODUSUR,
                                                                   PINTEGRADORA,
                                                                   VNUMPED,
                                                                   VSMSGTEMP) =
               FALSE
            THEN
               VERRO     := 'S';
               VMENSAGEM := VMENSAGEM || 'EC-01014-' || VSMSGTEMP;
            END IF;
         END IF;
      
         IF VERRO = 'S'
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END IF;
   
      IF VERRO = 'N'
      THEN
         VMENSAGEM := '';
         VMENSAGEM := VMENSAGEM || 'Pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' importado com sucesso;';
         VMENSAGEM := VMENSAGEM || 'Pedido pendente de número ' ||
                      TO_CHAR(VNUMPED) || ' foi gerado no Winthor.';
      
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      ELSE
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      END IF;
   END IMPORTAR_PEDIDO_WEB_NORMAL_BNF;

   PROCEDURE IMPORTAR_PEDIDO_WEB_BONIFIC
   (
      PNUMPEDWEB     IN NUMBER,
      PINTEGRADORA   IN NUMBER,
      PCODUSUR       IN NUMBER,
      PCONDVENDA     IN NUMBER,
      P_NORMAL_E_BNF IN VARCHAR2
   ) IS
      VIVA                      PCTRIBUT.IVA%TYPE;
      VIMPORTADO                VARCHAR2(1);
      VNUMPED                   NUMBER(10);
      VNUMPEDWEB                NUMBER(10);
      VCODCLI                   PCCLIENT.CODCLI%TYPE;
      VCODUSUR                  NUMBER(4);
      VVLTOTAL                  NUMBER(18, 6);
      VVLTABELA                 NUMBER(18, 6);
      VCODPLPAG                 NUMBER(6);
      VCODCOB                   VARCHAR2(5);
      VCODFILIAL                VARCHAR2(2);
      VPOSICAO                  VARCHAR2(1);
      VTOTPESO                  NUMBER(18, 6);
      VTOTPESOLIQ               NUMBER(18, 6);
      VCUSTOFIN                 NUMBER(18, 6);
      VCUSTOREAL                NUMBER(18, 6);
      VCUSTOCONT                NUMBER(18, 6);
      VCUSTOREP                 NUMBER(18, 6);
      VCODPROD                  NUMBER(10);
      VNUMITENS                 NUMBER(10);
      VCONDVENDA                NUMBER(6);
      VMENSAGEM                 VARCHAR2(3000);
      VERRO                     VARCHAR2(1);
      VCONTADOR                 NUMBER(6);
      VCODST                    NUMBER(4);
      VESTENT                   VARCHAR2(2);
      VVLFRETE                  NUMBER(18, 6);
      VDTENTREGA                DATE;
      VORIGEMPED                VARCHAR2(1);
      VPERCVENDA                NUMBER(5, 2);
      VVLOUTRASDESP             NUMBER(18, 6);
      VCODDISTRIB               VARCHAR2(4);
      VFRETEDESPACHO            VARCHAR2(1);
      VFRETEREDESPACHO          VARCHAR2(1);
      VINTEGRADORA29            VARCHAR2(1); --UNILEVER
      VBLOQUEIO                 VARCHAR2(1);
      VVLPAUTAIPIVENDA          NUMBER(18, 6);
      VVLIPIPORKGVENDA          NUMBER(18, 6);
      VPESOBRUTO                NUMBER(18, 6);
      VPERCIPIVENDA             NUMBER(18, 6);
      VSCALCULARIPIVENDA        VARCHAR2(1);
      VNVLIPI                   NUMBER(18, 6);
      VNPERCIPI                 NUMBER(18, 6);
      VTIPOCALCIPI              VARCHAR2(2);
      VNUMCASASDECVENDA         NUMBER(2, 0);
      VVLBONIFIC                NUMBER(18, 6);
      VVLATEND                  NUMBER(18, 6);
      VCODSUPERVISOR            PCUSUARI.CODSUPERVISOR%TYPE;
      VPBONIFIC                 PCPEDI.PBONIFIC%TYPE;
      VCODEMITENTE              PCPEDC.CODEMITENTE%TYPE;
      VNUMCAR                   PCPEDC.NUMCAR%TYPE;
      VCODPRACA                 PCPRACA.CODPRACA%TYPE;
      VPERCOM                   PCPEDI.PERCOM%TYPE;
      VCODAUXILIAR              PCPEDI.CODAUXILIAR%TYPE;
      VPEDIDO_COMPLETO          VARCHAR2(1);
      VSMSGTEMP                 VARCHAR2(300);
      VNUMREGIAO                PCREGIAO.NUMREGIAO%TYPE;
      VCODPRACAPEDIDO           PCPRACA.CODPRACA%TYPE;
      VTIPOVENDA                PCPLPAG.TIPOVENDA%TYPE;
      VVENDA_SEMIMPOSTOS        NUMBER(18, 6);
      VACEITAVENDABLOQ          VARCHAR2(1);
      VL_LIMITECLIENTE          NUMBER;
      COBRANCACORRETA           INTEGER;
      VVLDESCONTOCUPOM          NUMBER;
      VQT_PEDIDOB2B             NUMBER;
      VPEDIDOB2B_CONDICAO_VENDA NUMBER;
      VMATRICULA                NUMBER;
      VPEDIDOB2B                NUMBER;
      VPOSSUIPEDIDOBLOQUEADO    NUMBER;
   BEGIN
      VGLOBAL_RETORNO_ESTOQUE   := ''; --2
      VPEDIDO_COMPLETO          := 'N';
      VPERCOM                   := 0;
      VNUMCAR                   := 0;
      VCODEMITENTE              := 8888;
      VCONDVENDA                := PCONDVENDA;
      VMENSAGEM                 := '';
      VERRO                     := 'N';
      VPOSICAO                  := 'P';
      VORIGEMPED                := 'W';
      VGLOBAL_ORIGEMPED         := VORIGEMPED;
      VPERCVENDA                := 100;
      VQT_PEDIDOB2B             := 0;
      VPEDIDOB2B_CONDICAO_VENDA := 0;
      VMATRICULA                := 0;
      VPEDIDOB2B                := 0;
      VPOSSUIPEDIDOBLOQUEADO    := 0;
   
      IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
         BEGIN
            SELECT DISTINCT PCBLOQUEIO.ORIGEMPED
            INTO   VINTEGRADORA29
            FROM   PCBLOQUEIO
            WHERE  ORIGEMPED = VORIGEMPED;
         
            VPOSICAO := 'B';
         EXCEPTION
            WHEN OTHERS THEN
               VPOSICAO := 'P';
         END;
      END IF;
   
      BEGIN
         SELECT NVL(PCPEDCTEMP.IMPORTADO, 'N'),
                PCPEDCTEMP.NUMPED,
                PCPEDCTEMP.CODCLI,
                PCPEDCTEMP.CODUSUR,
                PCPEDCTEMP.CODPLPAG,
                PCPEDCTEMP.CODCOB,
                PCPEDCTEMP.CODFILIAL,
                PCPEDCTEMP.NUMPED,
                PCPEDCTEMP.VLFRETE,
                PCPEDCTEMP.DTENTREGA,
                NVL(NVL(PCPEDCTEMP.FRETEDESPACHO, C.FRETEDESPACHO), 'N') FRETEDESPACHO,
                PCPEDCTEMP.FRETEREDESPACHO,
                NVL(PCPEDCTEMP.CONDVENDA, 1) AS CONDVENDA,
                PCPEDCTEMP.CODPRACA,
                PCPEDCTEMP.VLDESCONTOCUPOM
         INTO   VIMPORTADO,
                VNUMPED,
                VCODCLI,
                VCODUSUR,
                VCODPLPAG,
                VCODCOB,
                VCODFILIAL,
                VNUMPED,
                VVLFRETE,
                VDTENTREGA,
                VFRETEDESPACHO,
                VFRETEREDESPACHO,
                VCONDVENDA,
                VCODPRACAPEDIDO,
                VVLDESCONTOCUPOM
         FROM   PCPEDCTEMP, PCCLIENT C
         WHERE  NVL(PCPEDCTEMP.CODCLINF, PCPEDCTEMP.CODCLI) = C.CODCLI(+) AND
                PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01001-Pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) ||
                         ' não foi encontrado nas tabelas temporárias;';
            VERRO     := 'S';
      END;
   
      VPOSICAO := IMPORTAR_PEDIDO_WEB_POSICAO(PNUMPEDWEB,
                                              PINTEGRADORA,
                                              PCODUSUR,
                                              VCODFILIAL,
                                              VCODCOB);
   
      IF (NVL(VGLOBAL_RETORNO_ESTOQUE, '') <> '')
      THEN
         VMENSAGEM := VMENSAGEM || VGLOBAL_RETORNO_ESTOQUE || ';';
         VERRO     := 'S';
      END IF;
      --VALIDANDO CABEÇALHO----------------------------------
      IF VIMPORTADO = 'S' AND
         P_NORMAL_E_BNF = 'F'
      THEN
         VMENSAGEM := VMENSAGEM || 'EC-01002-Pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' já importado;';
         VMENSAGEM := VMENSAGEM || 'Pedido Winthor de número ' ||
                      TO_CHAR(VNUMPED);
         VERRO     := 'S';
      END IF;
   
      BEGIN
         SELECT PCCLIENT.CODCLI,
                PCCLIENT.ESTENT,
                PCCLIENT.CODPRACA,
                CASE
                   WHEN NVL(PCCLIENT.BLOQUEIO, 'N') = 'N' AND
                        NVL(PCCLIENT.BLOQUEIOSEFAZ, 'N') = 'N' THEN
                    'N'
                   ELSE
                    'S'
                END BLOQUEIO
         INTO   VNUMPEDWEB, VESTENT, VCODPRACA, VBLOQUEIO
         FROM   PCCLIENT
         WHERE  PCCLIENT.CODCLI = VCODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01003-Cliente de código ' ||
                         TO_CHAR(VCODCLI) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      IMPORTAR_PEDIDO_WEB_NUMREGIAO(VCODFILIAL,
                                    NVL(VCODPRACAPEDIDO, VCODPRACA),
                                    VCODCLI,
                                    VNUMREGIAO);
   
      BEGIN
         SELECT PCUSUARI.CODUSUR,
                PCUSUARI.CODDISTRIB,
                PCUSUARI.CODSUPERVISOR
         INTO   VCODUSUR, VCODDISTRIB, VCODSUPERVISOR
         FROM   PCUSUARI
         WHERE  PCUSUARI.CODUSUR = VCODUSUR;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01004-RCA de código ' ||
                         TO_CHAR(VCODUSUR) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCPLPAG.CODPLPAG,
                PCPLPAG.TIPOVENDA,
                PRAZO1,
                PRAZO2,
                PRAZO3,
                PRAZO4,
                PRAZO5,
                PRAZO6,
                PRAZO7,
                PRAZO8,
                PRAZO9,
                PRAZO10,
                PRAZO11,
                PRAZO12,
                NUMDIAS
         INTO   VCODPLPAG,
                VTIPOVENDA,
                VPRAZO1,
                VPRAZO2,
                VPRAZO3,
                VPRAZO4,
                VPRAZO5,
                VPRAZO6,
                VPRAZO7,
                VPRAZO8,
                VPRAZO9,
                VPRAZO10,
                VPRAZO11,
                VPRAZO12,
                VNUMDIAS
         FROM   PCPLPAG
         WHERE  PCPLPAG.CODPLPAG = VCODPLPAG;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01005-Plano de pagamento de código ' ||
                         TO_CHAR(VCODPLPAG) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCCOB.CODCOB
         INTO   VCODCOB
         FROM   PCCOB
         WHERE  PCCOB.CODCOB = VCODCOB;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01006-Cobrança de código ' ||
                         (VCODCOB) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCFILIAL.CODIGO
         INTO   VCODFILIAL
         FROM   PCFILIAL
         WHERE  PCFILIAL.CODIGO = VCODFILIAL;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01007-Filial de código ' ||
                         (VCODFILIAL) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      IF VERRO = 'S'
      THEN
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(OBSERVACAO_PC || VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      END IF;
      --VALIDANDO ITENS----------------------------------
      BEGIN
         SELECT COUNT(PCPEDITEMP.NUMPEDWEB) AS CONTADOR
         INTO   VCONTADOR
         FROM   PCPEDITEMP
         WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDITEMP.CODUSUR = PCODUSUR AND
                PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                NVL(PCPEDITEMP.BONIFIC, 'N') = P_NORMAL_E_BNF AND
                EXISTS
          (SELECT T.NUMPEDWEB
                 FROM   PCPEDCTEMP T
                 WHERE  T.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                        T.INTEGRADORA = PCPEDITEMP.INTEGRADORA AND
                        T.CODUSUR = PCPEDITEMP.CODUSUR AND
                        T.TIPOINTEGRACAO = PCPEDITEMP.TIPOINTEGRACAO AND
                        T.CONDVENDA = VCONDVENDA);
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01008-Não existe itens para o pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) || ' nas tabelas temporárias;';
            VERRO     := 'S';
      END;
   
      IF VCONTADOR = 0
      THEN
         VMENSAGEM := VMENSAGEM ||
                      'EC-01008-Não existe itens para o pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' nas tabelas temporárias;';
         VERRO     := 'S';
      END IF;
   
      IF VERRO = 'N'
      THEN
         FOR REGCAB IN (SELECT *
                        FROM   PCPEDCTEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               PCPEDCTEMP.CONDVENDA = VCONDVENDA)
         LOOP
            FOR REGITEM IN (SELECT PCPEDITEMP.*, ROWID
                            FROM   PCPEDITEMP
                            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                                   NVL(PCPEDITEMP.BONIFIC, 'N') =
                                   P_NORMAL_E_BNF AND
                                   EXISTS
                             (SELECT T.NUMPEDWEB
                                    FROM   PCPEDCTEMP T
                                    WHERE  T.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                                           T.INTEGRADORA =
                                           PCPEDITEMP.INTEGRADORA AND
                                           T.CODUSUR = PCPEDITEMP.CODUSUR AND
                                           T.TIPOINTEGRACAO =
                                           PCPEDITEMP.TIPOINTEGRACAO AND
                                           T.CONDVENDA = VCONDVENDA))
            LOOP
               VMENSAGEM := '';
            
               BEGIN
                  SELECT PCPRODUT.CODPROD
                  INTO   VCODPROD
                  FROM   PCPRODUT
                  WHERE  PCPRODUT.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VMENSAGEM := VMENSAGEM ||
                                  'EC-01009-Produto de código ' ||
                                  TO_CHAR(REGITEM.CODPROD) ||
                                  ' não foi encontrado;';
                     VERRO     := 'S';
               END;
            
               BEGIN
                  SELECT PCEST.CODFILIAL, PCEST.CODPROD
                  INTO   VCODFILIAL, VCODPROD
                  FROM   PCEST
                  WHERE  PCEST.CODFILIAL = REGCAB.CODFILIAL AND
                         PCEST.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VMENSAGEM := VMENSAGEM ||
                                  'EC-01010-Produto de código ' ||
                                  TO_CHAR(REGITEM.CODPROD) ||
                                  ' não foi encontrado na filial de código ' ||
                                  REGCAB.CODFILIAL || ';';
                     VERRO     := 'S';
               END;
            
               IMPORTAR_PEDIDO_WEB_CODST(REGCAB.CODFILIAL,
                                         REGITEM.CODPROD,
                                         VESTENT,
                                         NVL(REGCAB.CODPRACA, VCODPRACA),
                                         VCODST,
                                         VCODCLI,
                                         PINTEGRADORA);
               IF VCODST <= 0
               THEN
                  VMENSAGEM := VMENSAGEM || 'EC-01011-Produto de código ' ||
                               TO_CHAR(REGITEM.CODPROD) ||
                               ' não possui código de st;';
                  VERRO     := 'S';
               END IF;
            
               IF VERRO = 'S'
               THEN
                  UPDATE PCPEDITEMP
                  SET    OBSERVACAO_PC = SUBSTR(OBSERVACAO_PC || VMENSAGEM,
                                                1,
                                                300)
                  WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                         PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                         PCPEDITEMP.CODUSUR = PCODUSUR AND
                         PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                         PCPEDITEMP.CODPROD = REGITEM.CODPROD AND
                         PCPEDITEMP.NUMSEQ = REGITEM.NUMSEQ AND
                         NVL(PCPEDITEMP.BONIFIC, 'N') = P_NORMAL_E_BNF AND
                         PCPEDITEMP.ROWID = REGITEM.ROWID;
               
                  COMMIT;
               END IF;
            END LOOP; --FIM LOOP ITEM
         END LOOP; --FIM LOOP CABEÇALHO
      END IF;
      ---OBTENDO O PRÓXIMO NÚMERO DE PEDIDO---------------------------------
      IF VERRO = 'N'
      THEN
         VNUMPED := IMPORTAR_PEDIDO_WEB_PROXNUMPED(VCODUSUR);
      
         IF VNUMPED = 0
         THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01012-Erro ao gerar próximo número de pedido;';
            VERRO     := 'S';
         END IF;
      END IF;
      ---MONTANDO DO PEDIDO---------------------------------
      IF VERRO = 'N'
      THEN
         FOR REGCAB IN (SELECT *
                        FROM   PCPEDCTEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               PCPEDCTEMP.CONDVENDA = VCONDVENDA)
         LOOP
            FOR REGITEM IN (SELECT PCPEDITEMP.*, ROWID
                            FROM   PCPEDITEMP
                            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                                   NVL(PCPEDITEMP.BONIFIC, 'N') =
                                   P_NORMAL_E_BNF AND
                                   EXISTS
                             (SELECT T.NUMPEDWEB
                                    FROM   PCPEDCTEMP T
                                    WHERE  T.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                                           T.INTEGRADORA =
                                           PCPEDITEMP.INTEGRADORA AND
                                           T.CODUSUR = PCPEDITEMP.CODUSUR AND
                                           T.TIPOINTEGRACAO =
                                           PCPEDITEMP.TIPOINTEGRACAO AND
                                           T.CONDVENDA = VCONDVENDA))
            LOOP
               BEGIN
                  SELECT NVL(PCEST.CUSTOFIN, 0) AS CUSTOFIN,
                         NVL(PCEST.CUSTOREAL, 0) AS CUSTOREAL,
                         NVL(PCEST.CUSTOCONT, 0) AS CUSTOCONT,
                         NVL(PCEST.CUSTOREP, 0) AS CUSTOREP
                  INTO   VCUSTOFIN, VCUSTOREAL, VCUSTOCONT, VCUSTOREP
                  FROM   PCEST
                  WHERE  PCEST.CODFILIAL = REGCAB.CODFILIAL AND
                         PCEST.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VCUSTOFIN  := 0;
                     VCUSTOREAL := 0;
               END;
            
               BEGIN
                  IMPORTAR_PEDIDO_WEB_CODST(REGCAB.CODFILIAL,
                                            REGITEM.CODPROD,
                                            VESTENT,
                                            NVL(REGCAB.CODPRACA, VCODPRACA),
                                            VCODST,
                                            VCODCLI,
                                            PINTEGRADORA);
               EXCEPTION
                  WHEN OTHERS THEN
                     NULL;
               END;
            
               BEGIN
                  SELECT VALORSEMIMPOSTO
                  INTO   VVENDA_SEMIMPOSTOS
                  FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(REGCAB.CODFILIAL,
                                                                          NVL(REGCAB.CODFILIALNF,
                                                                              REGCAB.CODFILIAL),
                                                                          REGITEM.CODFILIALRETIRA,
                                                                          REGCAB.CODCLI,
                                                                          REGCAB.CODPLPAG,
                                                                          REGITEM.CODPROD,
                                                                          REGITEM.CODAUXILIAR,
                                                                          NVL(NVL(REGCAB.CONDVENDA,
                                                                                  VCONDVENDA),
                                                                              1),
                                                                          'N',
                                                                          0,
                                                                          0,
                                                                          REGITEM.PVENDA,
                                                                          'N',
                                                                          'P',
                                                                          'N',
                                                                          0,
                                                                          NULL,
                                                                          'N',
                                                                          'N',
                                                                          'N',
                                                                          'N',
                                                                          NULL,
                                                                          NULL,
                                                                          'I',
                                                                          NULL,
                                                                          REGCAB.CODENDENTCLI));
               EXCEPTION
                  WHEN OTHERS THEN
                     VVENDA_SEMIMPOSTOS := 0;
               END;
            
               BEGIN
                  SELECT VALORIPI
                  INTO   VVLIPI_PTABELA
                  FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(REGCAB.CODFILIAL,
                                                           REGCAB.CODFILIALNF,
                                                           REGCAB.CODFILIAL,
                                                           REGCAB.CODCLI,
                                                           REGITEM.CODPROD,
                                                           REGITEM.CODAUXILIAR,
                                                           VCONDVENDA,
                                                           'N',
                                                           VVENDA_SEMIMPOSTOS,
                                                           'N',
                                                           REGCAB.CODENDENTCLI,
                                                           'N', --transferencia
                                                           'N', --transferenciaVirtual
                                                           'N',
                                                           'F',
                                                           NULL,
                                                           'I',
                                                           0,
                                                           'S',
                                                           'N' --VEN-1315
                                                           ));
               EXCEPTION
                  WHEN OTHERS THEN
                     VVLIPI_PTABELA := 0;
               END;
            
               BEGIN
                  SELECT NVL(T.IVA, 0)
                  INTO   VIVA
                  FROM   PCTRIBUT T
                  WHERE  T.CODST = VCODST;
               EXCEPTION
                  WHEN OTHERS THEN
                     VIVA := 0;
               END;
               --Cálculo de IPI
               BEGIN
                  BEGIN
                     SELECT PCPRODUT.VLPAUTAIPIVENDA,
                            PCPRODUT.VLIPIPORKGVENDA,
                            PCPRODUT.PESOBRUTO,
                            PCPRODUT.PERCIPIVENDA
                     INTO   VVLPAUTAIPIVENDA,
                            VVLIPIPORKGVENDA,
                            VPESOBRUTO,
                            VPERCIPIVENDA
                     FROM   PCPRODUT
                     WHERE  PCPRODUT.CODPROD = REGITEM.CODPROD;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMENSAGEM := VMENSAGEM ||
                                     'EC-01009-Produto de código ' ||
                                     TO_CHAR(REGITEM.CODPROD) ||
                                     ' não foi encontrado;';
                        VERRO     := 'S';
                  END;
               
                  BEGIN
                     SELECT NVL(PCFILIAL.CALCULARIPIVENDA, 'N')
                     INTO   VSCALCULARIPIVENDA
                     FROM   PCFILIAL
                     WHERE  PCFILIAL.CODIGO = REGCAB.CODFILIAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VSCALCULARIPIVENDA := 'N';
                  END;
               
                  IF VSCALCULARIPIVENDA = 'N'
                  THEN
                     VNVLIPI := 0;
                  ELSE
                     IF VVLPAUTAIPIVENDA > 0
                     THEN
                        VNVLIPI := VVLPAUTAIPIVENDA;
                     ELSE
                        IF VVLIPIPORKGVENDA > 0
                        THEN
                           VNVLIPI := VPESOBRUTO * VVLIPIPORKGVENDA;
                        ELSE
                           IF VPERCIPIVENDA > 0
                           THEN
                              VNVLIPI   := VVENDA_SEMIMPOSTOS *
                                           (VPERCIPIVENDA / 100);
                              VNPERCIPI := VPERCIPIVENDA;
                           END IF;
                        END IF;
                     END IF;
                  
                     BEGIN
                        SELECT TIPOCALCIPI, NUMCASASDECVENDA
                        INTO   VTIPOCALCIPI, VNUMCASASDECVENDA
                        FROM   PCCONSUM;
                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL;
                     END;
                  
                     IF VTIPOCALCIPI = 'T2'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI * 100) / 100;
                     ELSIF VTIPOCALCIPI = 'A2'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI, 2);
                     ELSIF VTIPOCALCIPI = 'PV'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI, VNUMCASASDECVENDA);
                     END IF;
                  END IF;
               EXCEPTION
                  WHEN OTHERS THEN
                     VNVLIPI   := 0;
                     VNPERCIPI := 0;
               END;
            
               VPBONIFIC := NULL;
            
               IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
                  IF NVL(REGITEM.BONIFIC, 'N') = 'F'
                  THEN
                     BEGIN
                        SELECT NVL(PCTABPR.PTABELA, 0)
                        INTO   VPBONIFIC
                        FROM   PCTABPR, PCPRACA, PCCLIENT
                        WHERE  PCPRACA.CODPRACA = PCCLIENT.CODPRACA AND
                               PCTABPR.NUMREGIAO = PCPRACA.NUMREGIAO AND
                               PCCLIENT.CODCLI = VCODCLI AND
                               PCTABPR.CODPROD = REGITEM.CODPROD;
                     EXCEPTION
                        WHEN OTHERS THEN
                           VPBONIFIC := NULL;
                     END;
                  END IF;
               END IF;
            
               BEGIN
                  SELECT NVL(P.PESOBRUTO, 0) AS PESOBRUTO, P.CODAUXILIAR
                  INTO   VPESOBRUTO, VCODAUXILIAR
                  FROM   PCPRODUT P
                  WHERE  P.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPESOBRUTO   := 0;
                     VCODAUXILIAR := NULL;
               END;
            
               IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
                  VCODAUXILIAR := NVL(REGITEM.CODAUXILIAR, VCODAUXILIAR);
               END IF;
            
               VGLOBAL_ORIGEMPED := VORIGEMPED;
               VGLOBAL_CODPLPAG  := REGCAB.CODPLPAG;
               VGLOBAL_CODFILIAL := REGCAB.CODFILIAL;
               VGLOBAL_NUMREGIAO := VNUMREGIAO;
            
               IF VBLOQUEIO = 'S'
               THEN
                  VPOSICAO := 'B';
               END IF;
            
               BEGIN
                  SELECT NVL(ACEITAVENDABLOQ, 'N')
                  INTO   VACEITAVENDABLOQ
                  FROM   PCCONSUM;
               EXCEPTION
                  WHEN OTHERS THEN
                     VACEITAVENDABLOQ := 'N';
               END;
            
               BEGIN
                  SELECT SUM(NVL(PCPEDITEMP.QT, 0) *
                             NVL(PCPEDITEMP.PVENDA, 0))
                  INTO   VVLTOTAL
                  FROM   PCPEDITEMP
                  WHERE  NUMPEDWEB = REGITEM.NUMPEDWEB;
               EXCEPTION
                  WHEN OTHERS THEN
                     VVLTOTAL := 0;
               END;
            
               BEGIN
                  SELECT COUNT(C.CODCOB)
                  INTO   COBRANCACORRETA
                  FROM   PCCOB C
                  WHERE  NVL(C.CARTAO, 'N') = 'N' AND
                         C.CODCOB <> 'D' AND
                         C.CODCOB = REGCAB.CODCOB;
               EXCEPTION
                  WHEN OTHERS THEN
                     COBRANCACORRETA := 0;
               END;
            
               IF VACEITAVENDABLOQ = 'S'
               THEN
                  VL_LIMITECLIENTE := IMPORTAR_PEDIDO_WEB_CREDITOCLI(REGCAB.CODCLI);
                  IF VL_LIMITECLIENTE < VVLTOTAL
                  THEN
                     IF COBRANCACORRETA > 0
                     THEN
                        VPOSICAO := 'B';
                     END IF;
                  END IF;
               END IF;
            
               IMPORTAR_PEDIDO_WEB_PCPEDI(VNUMPED --01
                                         ,
                                          REGITEM.CODPROD --02
                                         ,
                                          REGITEM.NUMSEQ --03
                                         ,
                                          TRUNC(SYSDATE) --04
                                         ,
                                          REGITEM.QT --05
                                         ,
                                          NVL(REGITEM.PVENDA, 0) --06
                                         ,
                                          NVL(REGITEM.PTABELA, 0) --07
                                         ,
                                          VCODCLI --08
                                         ,
                                          VCODUSUR --09
                                         ,
                                          VPOSICAO --10
                                         ,
                                          VCUSTOFIN --11
                                         ,
                                          VCUSTOREAL --12
                                         ,
                                          VPERCOM --13
                                         ,
                                          NVL(REGITEM.PERDESC, 0) --14
                                         ,
                                          VCODFILIAL --15
                                         ,
                                          VPESOBRUTO --16
                                         ,
                                          VCUSTOCONT --17
                                         ,
                                          VCUSTOREP --18
                                         ,
                                          NVL(VPBONIFIC,
                                              CASE WHEN
                                              NVL(REGITEM.PBONIFIC, 0) > 0 THEN
                                              NVL(REGITEM.PBONIFIC, 0) WHEN
                                              NVL(REGITEM.PVENDA, 0) > 0 THEN
                                              NVL(REGITEM.PVENDA, 0) WHEN
                                              NVL(REGITEM.PTABELA, 0) > 0 THEN
                                              NVL(REGITEM.PTABELA, 0) END) --19
                                         ,
                                          'F' --20
                                         ,
                                          VNVLIPI --21
                                         ,
                                          VNPERCIPI --22
                                         ,
                                          NVL(REGITEM.PTABELA,
                                              REGITEM.PVENDA) --23
                                         ,
                                          VNUMCAR --24
                                         ,
                                          VCODAUXILIAR --25
                                         ,
                                          VIVA --26
                                         ,
                                          REGITEM.QTUNITEMB --27
                                         ,
                                          VNUMREGIAO --28
                                         ,
                                          VCODST --29
                                         ,
                                          REGCAB.CODFILIAL --30
                                         ,
                                          REGCAB.CODFILIALNF --31
                                         ,
                                          NVL(REGITEM.CODPLPAG, VCODPLPAG) --32
                                         ,
                                          NVL(REGCAB.CONDVENDA, VCONDVENDA) --33
                                         ,
                                          VVENDA_SEMIMPOSTOS --34
                                          );
            END LOOP; --FIM LOOP ITEM
         
            VVLBONIFIC          := 0;
            VGLOBAL_VLCUSTOFIN  := 0;
            VGLOBAL_VLCUSTOREAL := 0;
            VGLOBAL_VLCUSTOREP  := 0;
            VGLOBAL_VLCUSTOCONT := 0;
         
            SELECT SUM(PCPEDI.QT * PCPEDI.PVENDA) AS VLTOTAL,
                   SUM(PCPEDI.QT * PCPEDI.PTABELA) AS VLTABELA,
                   SUM(PCPEDI.QT * PCPEDI.PVENDA * CASE
                          WHEN NVL(PCPEDI.BONIFIC, 'N') = 'N' THEN
                           1
                          ELSE
                           0
                       END) AS VLATEND,
                   SUM(PCPEDI.QT * PCPEDI.PBONIFIC * CASE
                          WHEN NVL(PCPEDI.BONIFIC, 'N') = 'F' THEN
                           1
                          ELSE
                           0
                       END) AS VLBONIFIC,
                   SUM(PCPEDI.QT * PCPRODUT.PESOBRUTO) AS TOTPESO,
                   SUM(PCPEDI.QT * PCPRODUT.PESOLIQ) AS TOTPESOLIQ,
                   COUNT(PCPEDI.CODPROD) AS NUMITENS,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN) AS VLCUSTOFIN,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL) AS VLCUSTOREAL,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP) AS VLCUSTOREP,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT) AS VLCUSTOCONT
            INTO   VVLTOTAL,
                   VVLTABELA,
                   VVLATEND,
                   VVLBONIFIC,
                   VTOTPESO,
                   VTOTPESOLIQ,
                   VNUMITENS,
                   VGLOBAL_VLCUSTOFIN,
                   VGLOBAL_VLCUSTOREAL,
                   VGLOBAL_VLCUSTOREP,
                   VGLOBAL_VLCUSTOCONT
            FROM   PCPEDI, PCPRODUT
            WHERE  PCPEDI.NUMPED = VNUMPED AND
                   PCPRODUT.CODPROD = PCPEDI.CODPROD;
         
            VVLOUTRASDESP          := NVL(REGCAB.VLOUTRASDESP, 0);
            VVLTOTAL               := NVL(VVLTOTAL, 0) + NVL(VVLFRETE, 0) +
                                      VVLOUTRASDESP;
            VVLTABELA              := NVL(VVLTABELA, 0) + NVL(VVLFRETE, 0) +
                                      VVLOUTRASDESP;
            VVLATEND               := NVL(VVLATEND, 0) + NVL(VVLFRETE, 0) +
                                      VVLOUTRASDESP;
            VCONDVENDA             := 5;
            VCODEMITENTE           := NVL(REGCAB.CODEMITENTE, '8888');
            VGLOBAL_OBSENTREGA4    := REGCAB.OBSENTREGA4;
            VGLOBAL_CODTRANSP      := CASE WHEN NVL(REGCAB.CODTRANSP, 0) > 0 THEN REGCAB.CODTRANSP ELSE NULL END;
            VGLOBAL_TIPOVENDA      := VTIPOVENDA;
            VGLOBAL_CODFORNECFRETE := CASE WHEN NVL(REGCAB.CODFORNECFRETE, 0) > 0 THEN REGCAB.CODFORNECFRETE ELSE NULL END;
            VGLOBAL_CODENDENTCLI   := REGCAB.CODENDENTCLI;
            VGLOBAL_OBS2           := REGCAB.OBS2;
         
            IMPORTAR_PEDIDO_WEB_PCPEDC(VNUMPED,
                                       TRUNC(SYSDATE),
                                       REGCAB.CODFILIAL,
                                       REGCAB.CODFILIALNF,
                                       REGCAB.CODCLI,
                                       REGCAB.CODUSUR,
                                       REGCAB.CODPLPAG,
                                       REGCAB.CODCOB,
                                       VVLTOTAL,
                                       VVLATEND,
                                       VVLTABELA,
                                       VPOSICAO,
                                       NVL(REGCAB.CODPRACA, VCODPRACA),
                                       PNUMPEDWEB,
                                       TO_CHAR(PNUMPEDWEB),
                                       PNUMPEDWEB,
                                       PINTEGRADORA,
                                       VTOTPESO,
                                       VTOTPESOLIQ,
                                       VORIGEMPED,
                                       VNUMITENS,
                                       VCONDVENDA,
                                       VVLFRETE,
                                       NVL(VDTENTREGA, TRUNC(SYSDATE)),
                                       VPERCVENDA,
                                       VVLOUTRASDESP,
                                       VCODDISTRIB,
                                       VFRETEDESPACHO,
                                       VFRETEREDESPACHO,
                                       VCODSUPERVISOR,
                                       VVLBONIFIC,
                                       VCODEMITENTE,
                                       REGCAB.OBS1,
                                       VNUMCAR,
                                       TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                                       TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                                       VNUMREGIAO,
                                       REGCAB.VLDESCONTOCUPOM,
                                       'N',
                                       'N',
                                       REGCAB.CNPJINTERMEDIADOR,
                                       REGCAB.DESCINTERMEDIADOR,
									   REGCAB.CODBNF);
         
            IMPORTAR_PEDIDO_WEB_ESTOQUEPKG(VNUMPED, VPOSICAO);
         
            IF (NVL(VGLOBAL_RETORNO_ESTOQUE, '') <> '')
            THEN
               VERRO     := 'S';
               VMENSAGEM := VMENSAGEM || VGLOBAL_RETORNO_ESTOQUE || ';';
            END IF;
         
            IF (REGCAB.INTEGRADORA IN (29, 33, 34, 36) OR REGCAB.INTEGRADORA > 999) AND
               REGCAB.CONDVENDA <> 5
            THEN
               IMPORTAR_PEDIDO_PCFORMAPAGTO(PNUMPEDWEB, VNUMPED);
            END IF;
         
            IF VPOSICAO = 'B'
            THEN
               BEGIN
                  SELECT COUNT(PCECOMMERCEB2BPCPEDC.NUMPEDWEB) CONTADOR
                  INTO   VPEDIDOB2B
                  FROM   PCECOMMERCEB2BPCPEDC
                  WHERE  PCECOMMERCEB2BPCPEDC.NUMPEDWEB = VNUMPED AND
                         PCECOMMERCEB2BPCPEDC.CODFILIAL = VCODFILIAL AND
                         PCECOMMERCEB2BPCPEDC.INTEGRADORA = PINTEGRADORA;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPEDIDOB2B := 0;
               END;
            
               IF VPEDIDOB2B > 0
               THEN
                  BEGIN
                     SELECT PCECOMMERCEB2B.MATRICULA
                     INTO   VMATRICULA
                     FROM   PCECOMMERCEB2B
                     WHERE  PCECOMMERCEB2B.CODFILIAL = VCODFILIAL AND
                            PCECOMMERCEB2B.TIPOINTEGRACAO = PINTEGRADORA;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMATRICULA := 0;
                  END;
               ELSE
                  BEGIN
                     SELECT PCECOMMERCEUNILEVER.MATRICULA
                     INTO   VMATRICULA
                     FROM   PCECOMMERCEUNILEVER
                     WHERE  PCECOMMERCEUNILEVER.CODFILIAL = VCODFILIAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMATRICULA := 0;
                  END;
               END IF;
            
               PKG_MOTIVOBLOQUEIO.VALIDAMOTIVOSBLOQUEIO(VNUMPED,
                                                        VMATRICULA,
                                                        2500);
            
               DELETE FROM PCBLOQUEIOSPEDIDO
               WHERE  PCBLOQUEIOSPEDIDO.NUMPED = VNUMPED AND
                      PCBLOQUEIOSPEDIDO.CODMOTIVO IN
                      (1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24);
            
               BEGIN
                  SELECT COUNT(PCBLOQUEIOSPEDIDO.NUMPED) CONTADOR
                  INTO   VPOSSUIPEDIDOBLOQUEADO
                  FROM   PCBLOQUEIOSPEDIDO
                  WHERE  PCBLOQUEIOSPEDIDO.NUMPED = VNUMPED;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPOSSUIPEDIDOBLOQUEADO := 0;
               END;
            
               IF VPOSSUIPEDIDOBLOQUEADO = 0
               THEN
                  PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(VNUMPED,
                                                  25,
                                                  'PEDIDOS DA INTEGRACAO',
                                                  'C');
               END IF;
            END IF;
         END LOOP; --FIM LOOP CABEÇALHO
      
         UPDATE PCPEDCTEMP
         SET    IMPORTADO      = 'S',
                NUMPED         = VNUMPED,
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         IMPORTAR_PEDIDO_WEB_COMPLETO(VNUMPED, VPEDIDO_COMPLETO);
      
         IF VPEDIDO_COMPLETO = 'N'
         THEN
            VERRO     := 'S';
            VMENSAGEM := VMENSAGEM ||
                         'EC-01013-Pedido gerado com ausência de cabeçalho e/ou item;';
         END IF;
      
         VSMSGTEMP := '';
      
         BEGIN
            SELECT COUNT(E.NUMPEDWEB) AS CONTADOR
            INTO   VQT_PEDIDOB2B
            FROM   PCFORMAPGTOPEDIDOTEMP E
            WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                   E.INTEGRADORA = PINTEGRADORA AND
                   E.CODFILIAL = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VQT_PEDIDOB2B := 0;
         END;
      
         BEGIN
            SELECT CONDVENDA
            INTO   VPEDIDOB2B_CONDICAO_VENDA
            FROM   PCPEDCTEMP E
            WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                   E.INTEGRADORA = PINTEGRADORA AND
                   E.CODFILIAL = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VPEDIDOB2B_CONDICAO_VENDA := 0;
         END;
      
         IF VQT_PEDIDOB2B > 1 AND
            VPEDIDOB2B_CONDICAO_VENDA <> 5
         THEN
            IF IMPORTARVENDASMULTIPAG.FUNC_VALIDAR_MULT_PLANOS_WEB(PNUMPEDWEB,
                                                                   PCODUSUR,
                                                                   PINTEGRADORA,
                                                                   VNUMPED,
                                                                   VSMSGTEMP) =
               FALSE
            THEN
               VERRO     := 'S';
               VMENSAGEM := VMENSAGEM || 'EC-01014-' || VSMSGTEMP;
            END IF;
         END IF;
      
         IF VERRO = 'S'
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END IF;
   
      IF VERRO = 'N'
      THEN
         VMENSAGEM := '';
         VMENSAGEM := VMENSAGEM || 'Pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' importado com sucesso;';
         VMENSAGEM := VMENSAGEM || 'Pedido pendente de número ' ||
                      TO_CHAR(VNUMPED) || ' foi gerado no Winthor.';
      
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      ELSE
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      END IF;
   END IMPORTAR_PEDIDO_WEB_BONIFIC;

   PROCEDURE IMPORTAR_PEDIDO_WEB_NORMAL
   (
      PNUMPEDWEB     IN NUMBER,
      PINTEGRADORA   IN NUMBER,
      PCODUSUR       IN NUMBER,
      PCONDVENDA     IN NUMBER,
      P_NORMAL_E_BNF IN VARCHAR2
   ) IS
      VIVA                      PCTRIBUT.IVA%TYPE;
      VIMPORTADO                VARCHAR2(1);
      VNUMPED                   NUMBER(10);
      VNUMPEDWEB                NUMBER(10);
      VCODCLI                   PCCLIENT.CODCLI%TYPE;
      VCODUSUR                  NUMBER(4);
      VVLTOTAL                  NUMBER(18, 6);
      VVLTABELA                 NUMBER(18, 6);
      VCODPLPAG                 NUMBER(6);
      VCODCOB                   VARCHAR2(5);
      VCODFILIAL                VARCHAR2(2);
      VPOSICAO                  VARCHAR2(1);
      VTOTPESO                  NUMBER(18, 6);
      VTOTPESOLIQ               NUMBER(18, 6);
      VCUSTOFIN                 NUMBER(18, 6);
      VCUSTOREAL                NUMBER(18, 6);
      VCUSTOCONT                NUMBER(18, 6);
      VCUSTOREP                 NUMBER(18, 6);
      VCODPROD                  NUMBER(10);
      VNUMITENS                 NUMBER(10);
      VCONDVENDA                NUMBER(6);
      VMENSAGEM                 VARCHAR2(3000);
      VERRO                     VARCHAR2(1);
      VCONTADOR                 NUMBER(6);
      VCODST                    NUMBER(4);
      VESTENT                   VARCHAR2(2);
      VVLFRETE                  NUMBER(18, 6);
      VDTENTREGA                DATE;
      VORIGEMPED                VARCHAR2(1);
      VPERCVENDA                NUMBER(5, 2);
      VVLOUTRASDESP             NUMBER(18, 6);
      VCODDISTRIB               VARCHAR2(4);
      VFRETEDESPACHO            VARCHAR2(1);
      VFRETEREDESPACHO          VARCHAR2(1);
      VINTEGRADORA29            VARCHAR2(1); --Ecommerce Unilever
      VBLOQUEIO                 VARCHAR2(1);
      VVLPAUTAIPIVENDA          NUMBER(18, 6);
      VVLIPIPORKGVENDA          NUMBER(18, 6);
      VPESOBRUTO                NUMBER(18, 6);
      VPERCIPIVENDA             NUMBER(18, 6);
      VSCALCULARIPIVENDA        VARCHAR2(1);
      VNVLIPI                   NUMBER(18, 6);
      VNPERCIPI                 NUMBER(18, 6);
      VTIPOCALCIPI              VARCHAR2(2);
      VNUMCASASDECVENDA         NUMBER(2, 0);
      VVLBONIFIC                NUMBER(18, 6);
      VVLATEND                  NUMBER(18, 6);
      VCODSUPERVISOR            PCUSUARI.CODSUPERVISOR%TYPE;
      VPBONIFIC                 PCPEDI.PBONIFIC%TYPE;
      VCODEMITENTE              PCPEDC.CODEMITENTE%TYPE;
      VNUMCAR                   PCPEDC.NUMCAR%TYPE;
      VCODPRACA                 PCPRACA.CODPRACA%TYPE;
      VPERCOM                   PCPEDI.PERCOM%TYPE;
      VCODAUXILIAR              PCPEDI.CODAUXILIAR%TYPE;
      VPEDIDO_COMPLETO          VARCHAR2(1);
      VSMSGTEMP                 VARCHAR2(300);
      VNUMREGIAO                PCREGIAO.NUMREGIAO%TYPE;
      VCODPRACAPEDIDO           PCPRACA.CODPRACA%TYPE;
      VTIPOVENDA                PCPLPAG.TIPOVENDA%TYPE;
      VVENDA_SEMIMPOSTOS        NUMBER(18, 6);
      VACEITAVENDABLOQ          VARCHAR2(1);
      VL_LIMITECLIENTE          NUMBER;
      COBRANCACORRETA           INTEGER;
      VVLDESCONTOCUPOM          NUMBER;
      VPTABELA                  PCPEDI.PTABELA%TYPE;
      VPERDESC                  PCPEDI.PERDESC%TYPE;
      VQT_PEDIDOB2B             NUMBER;
      VPEDIDOB2B_CONDICAO_VENDA NUMBER;
      VMATRICULA                NUMBER;
      VPEDIDOB2B                NUMBER;
      VPOSSUIPEDIDOBLOQUEADO    NUMBER;
      VPVENDA                   PCPEDI.PVENDA%TYPE;
   BEGIN
      VGLOBAL_RETORNO_ESTOQUE   := ''; --3
      VPEDIDO_COMPLETO          := 'N';
      VPERCOM                   := 0;
      VNUMCAR                   := 0;
      VCODEMITENTE              := 8888;
      VCONDVENDA                := PCONDVENDA;
      VMENSAGEM                 := '';
      VERRO                     := 'N';
      VPOSICAO                  := 'P';
      VORIGEMPED                := 'W';
      VPERCVENDA                := 100;
      VQT_PEDIDOB2B             := 0;
      VPEDIDOB2B_CONDICAO_VENDA := 0;
      VMATRICULA                := 0;
      VPEDIDOB2B                := 0;
      VPOSSUIPEDIDOBLOQUEADO    := 0;
   
      IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
         --Ecommerce Unilever
         BEGIN
            SELECT DISTINCT PCBLOQUEIO.ORIGEMPED
            INTO   VINTEGRADORA29
            FROM   PCBLOQUEIO
            WHERE  PCBLOQUEIO.ORIGEMPED = VORIGEMPED;
         
            VPOSICAO := 'B';
         EXCEPTION
            WHEN OTHERS THEN
               VPOSICAO := 'P';
         END;
      END IF;
   
      BEGIN
         SELECT PCPEDCTEMP.IMPORTADO,
                PCPEDCTEMP.NUMPED,
                PCPEDCTEMP.CODCLI,
                PCPEDCTEMP.CODUSUR,
                PCPEDCTEMP.CODPLPAG,
                PCPEDCTEMP.CODCOB,
                PCPEDCTEMP.CODFILIAL,
                PCPEDCTEMP.NUMPED,
                PCPEDCTEMP.VLFRETE,
                PCPEDCTEMP.DTENTREGA,
                NVL(NVL(PCPEDCTEMP.FRETEDESPACHO, C.FRETEDESPACHO), 'N') FRETEDESPACHO,
                PCPEDCTEMP.FRETEREDESPACHO,
                NVL(PCPEDCTEMP.CONDVENDA, 1) AS CONDVENDA,
                PCPEDCTEMP.CODPRACA,
                PCPEDCTEMP.VLDESCONTOCUPOM
         INTO   VIMPORTADO,
                VNUMPED,
                VCODCLI,
                VCODUSUR,
                VCODPLPAG,
                VCODCOB,
                VCODFILIAL,
                VNUMPED,
                VVLFRETE,
                VDTENTREGA,
                VFRETEDESPACHO,
                VFRETEREDESPACHO,
                VCONDVENDA,
                VCODPRACAPEDIDO,
                VVLDESCONTOCUPOM
         FROM   PCPEDCTEMP, PCCLIENT C
         WHERE  NVL(PCPEDCTEMP.CODCLINF, PCPEDCTEMP.CODCLI) = C.CODCLI(+) AND
                PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01001-Pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) ||
                         ' não foi encontrado nas tabelas temporárias;';
            VERRO     := 'S';
      END;
   
      VPOSICAO := IMPORTAR_PEDIDO_WEB_POSICAO(PNUMPEDWEB,
                                              PINTEGRADORA,
                                              PCODUSUR,
                                              VCODFILIAL,
                                              VCODCOB);
   
      IF (NVL(VGLOBAL_RETORNO_ESTOQUE, '') <> '')
      THEN
         VMENSAGEM := VMENSAGEM || VGLOBAL_RETORNO_ESTOQUE || ';';
         VERRO     := 'S';
      END IF;
      --VALIDANDO CABEÇALHO----------------------------------
      IF VIMPORTADO = 'S' AND
         P_NORMAL_E_BNF = 'N'
      THEN
         VMENSAGEM := VMENSAGEM || 'EC-01002-Pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' já importado;';
         VMENSAGEM := VMENSAGEM || 'Pedido Winthor de número ' ||
                      TO_CHAR(VNUMPED);
         VERRO     := 'S';
      END IF;
   
      BEGIN
         SELECT PCCLIENT.CODCLI,
                PCCLIENT.ESTENT,
                PCCLIENT.CODPRACA,
                CASE
                   WHEN NVL(PCCLIENT.BLOQUEIO, 'N') = 'N' AND
                        NVL(PCCLIENT.BLOQUEIOSEFAZ, 'N') = 'N' THEN
                    'N'
                   ELSE
                    'S'
                END BLOQUEIO
         INTO   VNUMPEDWEB, VESTENT, VCODPRACA, VBLOQUEIO
         FROM   PCCLIENT
         WHERE  PCCLIENT.CODCLI = VCODCLI;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01003-Cliente de código ' ||
                         TO_CHAR(VCODCLI) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      IMPORTAR_PEDIDO_WEB_NUMREGIAO(VCODFILIAL,
                                    NVL(VCODPRACAPEDIDO, VCODPRACA),
                                    VCODCLI,
                                    VNUMREGIAO);
   
      BEGIN
         SELECT PCUSUARI.CODUSUR,
                PCUSUARI.CODDISTRIB,
                PCUSUARI.CODSUPERVISOR
         INTO   VCODUSUR, VCODDISTRIB, VCODSUPERVISOR
         FROM   PCUSUARI
         WHERE  PCUSUARI.CODUSUR = VCODUSUR;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01004-RCA de código ' ||
                         TO_CHAR(VCODUSUR) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCPLPAG.CODPLPAG,
                PCPLPAG.TIPOVENDA,
                PRAZO1,
                PRAZO2,
                PRAZO3,
                PRAZO4,
                PRAZO5,
                PRAZO6,
                PRAZO7,
                PRAZO8,
                PRAZO9,
                PRAZO10,
                PRAZO11,
                PRAZO12,
                NUMDIAS
         INTO   VCODPLPAG,
                VTIPOVENDA,
                VPRAZO1,
                VPRAZO2,
                VPRAZO3,
                VPRAZO4,
                VPRAZO5,
                VPRAZO6,
                VPRAZO7,
                VPRAZO8,
                VPRAZO9,
                VPRAZO10,
                VPRAZO11,
                VPRAZO12,
                VNUMDIAS
         FROM   PCPLPAG
         WHERE  PCPLPAG.CODPLPAG = VCODPLPAG;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01005-Plano de pagamento de código ' ||
                         TO_CHAR(VCODPLPAG) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCCOB.CODCOB
         INTO   VCODCOB
         FROM   PCCOB
         WHERE  PCCOB.CODCOB = VCODCOB;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01006-Cobrança de código ' ||
                         (VCODCOB) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      BEGIN
         SELECT PCFILIAL.CODIGO
         INTO   VCODFILIAL
         FROM   PCFILIAL
         WHERE  PCFILIAL.CODIGO = VCODFILIAL;
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM || 'EC-01007-Filial de código ' ||
                         (VCODFILIAL) || ' não foi encontrado;';
            VERRO     := 'S';
      END;
   
      IF VERRO = 'S'
      THEN
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(OBSERVACAO_PC || VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      END IF;
      --VALIDANDO ITENS----------------------------------
      BEGIN
         SELECT COUNT(PCPEDITEMP.NUMPEDWEB) AS CONTADOR
         INTO   VCONTADOR
         FROM   PCPEDITEMP
         WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDITEMP.CODUSUR = PCODUSUR AND
                PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                NVL(PCPEDITEMP.BONIFIC, 'N') = P_NORMAL_E_BNF AND
                EXISTS
          (SELECT T.NUMPEDWEB
                 FROM   PCPEDCTEMP T
                 WHERE  T.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                        T.INTEGRADORA = PCPEDITEMP.INTEGRADORA AND
                        T.CODUSUR = PCPEDITEMP.CODUSUR AND
                        T.TIPOINTEGRACAO = PCPEDITEMP.TIPOINTEGRACAO AND
                        T.CONDVENDA = VCONDVENDA);
      EXCEPTION
         WHEN OTHERS THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01008-Não existe itens para o pedido web de número ' ||
                         TO_CHAR(PNUMPEDWEB) || ' nas tabelas temporárias;';
            VERRO     := 'S';
      END;
   
      IF VCONTADOR = 0
      THEN
         VMENSAGEM := VMENSAGEM ||
                      'Não existe itens para o pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' nas tabelas temporárias;';
         VERRO     := 'S';
      END IF;
   
      IF VERRO = 'N'
      THEN
         FOR REGCAB IN (SELECT *
                        FROM   PCPEDCTEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               PCPEDCTEMP.CONDVENDA = VCONDVENDA)
         LOOP
            FOR REGITEM IN (SELECT PCPEDITEMP.*, ROWID
                            FROM   PCPEDITEMP
                            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                                   NVL(PCPEDITEMP.BONIFIC, 'N') =
                                   P_NORMAL_E_BNF AND
                                   EXISTS
                             (SELECT T.NUMPEDWEB
                                    FROM   PCPEDCTEMP T
                                    WHERE  T.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                                           T.INTEGRADORA =
                                           PCPEDITEMP.INTEGRADORA AND
                                           T.CODUSUR = PCPEDITEMP.CODUSUR AND
                                           T.TIPOINTEGRACAO =
                                           PCPEDITEMP.TIPOINTEGRACAO AND
                                           T.CONDVENDA = VCONDVENDA))
            LOOP
               VMENSAGEM := '';
            
               BEGIN
                  SELECT PCPRODUT.CODPROD
                  INTO   VCODPROD
                  FROM   PCPRODUT
                  WHERE  PCPRODUT.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VMENSAGEM := VMENSAGEM ||
                                  'EC-01009-Produto de código ' ||
                                  TO_CHAR(REGITEM.CODPROD) ||
                                  ' não foi encontrado;';
                     VERRO     := 'S';
               END;
            
               BEGIN
                  SELECT PCEST.CODFILIAL, PCEST.CODPROD
                  INTO   VCODFILIAL, VCODPROD
                  FROM   PCEST
                  WHERE  PCEST.CODFILIAL = REGCAB.CODFILIAL AND
                         PCEST.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VMENSAGEM := VMENSAGEM ||
                                  'EC-01010-Produto de código ' ||
                                  TO_CHAR(REGITEM.CODPROD) ||
                                  ' não foi encontrado na filial de código ' ||
                                  REGCAB.CODFILIAL || ';';
                     VERRO     := 'S';
               END;
            
               IMPORTAR_PEDIDO_WEB_CODST(REGCAB.CODFILIAL,
                                         REGITEM.CODPROD,
                                         VESTENT,
                                         NVL(REGCAB.CODPRACA, VCODPRACA),
                                         VCODST,
                                         VCODCLI,
                                         PINTEGRADORA);
               IF VCODST <= 0
               THEN
                  VMENSAGEM := VMENSAGEM || 'EC-01011-Produto de código ' ||
                               TO_CHAR(REGITEM.CODPROD) ||
                               ' não possui código de st;';
                  VERRO     := 'S';
               END IF;
            
               IF VERRO = 'S'
               THEN
                  UPDATE PCPEDITEMP
                  SET    OBSERVACAO_PC = SUBSTR(OBSERVACAO_PC || VMENSAGEM,
                                                1,
                                                300)
                  WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                         PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                         PCPEDITEMP.CODUSUR = PCODUSUR AND
                         PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                         PCPEDITEMP.CODPROD = REGITEM.CODPROD AND
                         PCPEDITEMP.NUMSEQ = REGITEM.NUMSEQ AND
                         NVL(PCPEDITEMP.BONIFIC, 'N') = P_NORMAL_E_BNF AND
                         PCPEDITEMP.ROWID = REGITEM.ROWID;
               
                  COMMIT;
               END IF;
            END LOOP; --FIM LOOP ITEM
         END LOOP; --FIM LOOP CABEÇALHO
      END IF;
      ---OBTENDO O PRÓXIMO NÚMERO DE PEDIDO---------------------------------
      IF VERRO = 'N'
      THEN
         VNUMPED := IMPORTAR_PEDIDO_WEB_PROXNUMPED(VCODUSUR);
      
         IF VNUMPED = 0
         THEN
            VMENSAGEM := VMENSAGEM ||
                         'EC-01012-Erro ao gerar próximo número de pedido;';
            VERRO     := 'S';
         END IF;
      END IF;
      ---MONTANDO DO PEDIDO---------------------------------
      IF VERRO = 'N'
      THEN
         FOR REGCAB IN (SELECT *
                        FROM   PCPEDCTEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               PCPEDCTEMP.CONDVENDA = VCONDVENDA)
         LOOP
            FOR REGITEM IN (SELECT *
                            FROM   PCPEDITEMP
                            WHERE  PCPEDITEMP.NUMPEDWEB = PNUMPEDWEB AND
                                   PCPEDITEMP.INTEGRADORA = PINTEGRADORA AND
                                   PCPEDITEMP.CODUSUR = PCODUSUR AND
                                   PCPEDITEMP.TIPOINTEGRACAO = VORIGEMPED AND
                                   NVL(PCPEDITEMP.BONIFIC, 'N') =
                                   P_NORMAL_E_BNF AND
                                   EXISTS
                             (SELECT T.NUMPEDWEB
                                    FROM   PCPEDCTEMP T
                                    WHERE  T.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                                           T.INTEGRADORA =
                                           PCPEDITEMP.INTEGRADORA AND
                                           T.CODUSUR = PCPEDITEMP.CODUSUR AND
                                           T.TIPOINTEGRACAO =
                                           PCPEDITEMP.TIPOINTEGRACAO AND
                                           T.CONDVENDA = VCONDVENDA))
            LOOP
               BEGIN
                  SELECT NVL(PCEST.CUSTOFIN, 0) AS CUSTOFIN,
                         NVL(PCEST.CUSTOREAL, 0) AS CUSTOREAL,
                         NVL(PCEST.CUSTOCONT, 0) AS CUSTOCONT,
                         NVL(PCEST.CUSTOREP, 0) AS CUSTOREP
                  INTO   VCUSTOFIN, VCUSTOREAL, VCUSTOCONT, VCUSTOREP
                  FROM   PCEST
                  WHERE  PCEST.CODFILIAL = REGCAB.CODFILIAL AND
                         PCEST.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VCUSTOFIN  := 0;
                     VCUSTOREAL := 0;
               END;
               -- fim cálculo do PTABELA
               VPVENDA := NVL(REGITEM.PVENDA, 0);
               IF NVL(REGITEM.PVENDA, 0) = 0
               THEN
                  VPVENDA := VPTABELA;
               END IF;
               -- fim cálculo do PTABELA
               BEGIN
                  IMPORTAR_PEDIDO_WEB_CODST(REGCAB.CODFILIAL,
                                            REGITEM.CODPROD,
                                            VESTENT,
                                            NVL(REGCAB.CODPRACA, VCODPRACA),
                                            VCODST,
                                            VCODCLI,
                                            PINTEGRADORA);
               EXCEPTION
                  WHEN OTHERS THEN
                     NULL;
               END;
            
               BEGIN
                  SELECT VALORSEMIMPOSTO
                  INTO   VVENDA_SEMIMPOSTOS
                  FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(REGCAB.CODFILIAL,
                                                                          NVL(REGCAB.CODFILIALNF,
                                                                              REGCAB.CODFILIAL),
                                                                          REGITEM.CODFILIALRETIRA,
                                                                          REGCAB.CODCLI,
                                                                          REGCAB.CODPLPAG,
                                                                          REGITEM.CODPROD,
                                                                          REGITEM.CODAUXILIAR,
                                                                          NVL(NVL(REGCAB.CONDVENDA,
                                                                                  VCONDVENDA),
                                                                              1),
                                                                          'N',
                                                                          0,
                                                                          0,
                                                                          VPVENDA,
                                                                          'N',
                                                                          'P',
                                                                          'N',
                                                                          0,
                                                                          NULL,
                                                                          'N',
                                                                          'N',
                                                                          'N',
                                                                          'N',
                                                                          NULL,
                                                                          NULL,
                                                                          'I',
                                                                          NULL,
                                                                          REGCAB.CODENDENTCLI));
               EXCEPTION
                  WHEN OTHERS THEN
                     VVENDA_SEMIMPOSTOS := 0;
               END;
            
               BEGIN
                  SELECT VALORIPI
                  INTO   VVLIPI_PTABELA
                  FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(REGCAB.CODFILIAL,
                                                           REGCAB.CODFILIALNF,
                                                           REGCAB.CODFILIAL,
                                                           REGCAB.CODCLI,
                                                           REGITEM.CODPROD,
                                                           REGITEM.CODAUXILIAR,
                                                           VCONDVENDA,
                                                           'N',
                                                           VVENDA_SEMIMPOSTOS,
                                                           'N',
                                                           REGCAB.CODENDENTCLI,
                                                           'N', --transferencia
                                                           'N', --transferenciaVirtual
                                                           'N',
                                                           'F',
                                                           NULL,
                                                           'I',
                                                           0,
                                                           'S',
                                                           'N' --VEN-1315
                                                           ));
               EXCEPTION
                  WHEN OTHERS THEN
                     VVLIPI_PTABELA := 0;
               END;
            
               BEGIN
                  SELECT NVL(T.IVA, 0) IVA
                  INTO   VIVA
                  FROM   PCTRIBUT T
                  WHERE  T.CODST = VCODST;
               EXCEPTION
                  WHEN OTHERS THEN
                     VIVA := 0;
               END;
               --Cálculo de IPI
               BEGIN
                  BEGIN
                     SELECT PCPRODUT.VLPAUTAIPIVENDA,
                            PCPRODUT.VLIPIPORKGVENDA,
                            PCPRODUT.PESOBRUTO,
                            PCPRODUT.PERCIPIVENDA
                     INTO   VVLPAUTAIPIVENDA,
                            VVLIPIPORKGVENDA,
                            VPESOBRUTO,
                            VPERCIPIVENDA
                     FROM   PCPRODUT
                     WHERE  PCPRODUT.CODPROD = REGITEM.CODPROD;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMENSAGEM := VMENSAGEM ||
                                     'EC-01009-Produto de código ' ||
                                     TO_CHAR(REGITEM.CODPROD) ||
                                     ' não foi encontrado;';
                        VERRO     := 'S';
                  END;
               
                  BEGIN
                     VSCALCULARIPIVENDA := 'N';
                     SELECT PCFILIAL.CALCULARIPIVENDA
                     INTO   VSCALCULARIPIVENDA
                     FROM   PCFILIAL
                     WHERE  PCFILIAL.CODIGO = REGCAB.CODFILIAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VSCALCULARIPIVENDA := 'N';
                  END;
               
                  BEGIN
                     SELECT VALORSEMIMPOSTO
                     INTO   VVENDA_SEMIMPOSTOS
                     FROM   TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(REGCAB.CODFILIAL,
                                                                             NVL(REGCAB.CODFILIALNF,
                                                                                 REGCAB.CODFILIAL),
                                                                             REGITEM.CODFILIALRETIRA,
                                                                             REGCAB.CODCLI,
                                                                             REGCAB.CODPLPAG,
                                                                             REGITEM.CODPROD,
                                                                             REGITEM.CODAUXILIAR,
                                                                             NVL(NVL(REGCAB.CONDVENDA,
                                                                                     VCONDVENDA),
                                                                                 1),
                                                                             'N',
                                                                             0,
                                                                             0,
                                                                             REGITEM.PVENDA,
                                                                             'N',
                                                                             'P',
                                                                             'N',
                                                                             0,
                                                                             NULL,
                                                                             'N',
                                                                             'N',
                                                                             'N',
                                                                             'N',
                                                                             NULL,
                                                                             NULL,
                                                                             'I',
                                                                             NULL,
                                                                             REGCAB.CODENDENTCLI));
                  EXCEPTION
                     WHEN OTHERS THEN
                        VVENDA_SEMIMPOSTOS := 0;
                  END;
               
                  IF VSCALCULARIPIVENDA = 'N'
                  THEN
                     VNVLIPI := 0;
                  ELSE
                     IF VVLPAUTAIPIVENDA > 0
                     THEN
                        VNVLIPI := VVLPAUTAIPIVENDA;
                     ELSE
                        IF VVLIPIPORKGVENDA > 0
                        THEN
                           VNVLIPI := VPESOBRUTO * VVLIPIPORKGVENDA;
                        ELSE
                           IF VPERCIPIVENDA > 0
                           THEN
                              VNVLIPI   := VVENDA_SEMIMPOSTOS *
                                           (VPERCIPIVENDA / 100);
                              VNPERCIPI := VPERCIPIVENDA;
                           END IF;
                        END IF;
                     END IF;
                  
                     BEGIN
                        SELECT TIPOCALCIPI, NUMCASASDECVENDA
                        INTO   VTIPOCALCIPI, VNUMCASASDECVENDA
                        FROM   PCCONSUM;
                     END;
                  
                     IF VTIPOCALCIPI = 'T2'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI * 100) / 100;
                     ELSIF VTIPOCALCIPI = 'A2'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI, 2);
                     ELSIF VTIPOCALCIPI = 'PV'
                     THEN
                        VNVLIPI := ROUND(VNVLIPI, VNUMCASASDECVENDA);
                     END IF;
                  END IF;
               EXCEPTION
                  WHEN OTHERS THEN
                     VNVLIPI   := 0;
                     VNPERCIPI := 0;
               END;
            
               VPBONIFIC := NULL;
            
               BEGIN
                  SELECT NVL(P.PESOBRUTO, 0) AS PESOBRUTO, P.CODAUXILIAR
                  INTO   VPESOBRUTO, VCODAUXILIAR
                  FROM   PCPRODUT P
                  WHERE  P.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPESOBRUTO   := 0;
                     VCODAUXILIAR := NULL;
               END;
            
               IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
                  VCODAUXILIAR := NVL(REGITEM.CODAUXILIAR, VCODAUXILIAR);
               END IF;
            
               VGLOBAL_ORIGEMPED := VORIGEMPED;
               VGLOBAL_CODPLPAG  := REGCAB.CODPLPAG;
               VGLOBAL_CODFILIAL := REGCAB.CODFILIAL;
               VGLOBAL_NUMREGIAO := VNUMREGIAO;
            
               IF VBLOQUEIO = 'S'
               THEN
                  VPOSICAO := 'B';
               END IF;
            
               BEGIN
                  SELECT NVL(ACEITAVENDABLOQ, 'N')
                  INTO   VACEITAVENDABLOQ
                  FROM   PCCONSUM;
               EXCEPTION
                  WHEN OTHERS THEN
                     VACEITAVENDABLOQ := 'N';
               END;
            
               BEGIN
                  SELECT SUM(PCPEDITEMP.QT * PCPEDITEMP.PVENDA) AS VLTOTAL
                  INTO   VVLTOTAL
                  FROM   PCPEDITEMP
                  WHERE  NUMPEDWEB = REGITEM.NUMPEDWEB;
               EXCEPTION
                  WHEN OTHERS THEN
                     VVLTOTAL := 0;
               END;
            
               BEGIN
                  SELECT COUNT(C.CODCOB)
                  INTO   COBRANCACORRETA
                  FROM   PCCOB C
                  WHERE  NVL(C.CARTAO, 'N') = 'N' AND
                         C.CODCOB <> 'D' AND
                         C.CODCOB = REGCAB.CODCOB;
               EXCEPTION
                  WHEN OTHERS THEN
                     COBRANCACORRETA := 0;
               END;
            
               IF VACEITAVENDABLOQ = 'S'
               THEN
                  VL_LIMITECLIENTE := IMPORTAR_PEDIDO_WEB_CREDITOCLI(REGCAB.CODCLI);
                  IF VL_LIMITECLIENTE < VVLTOTAL
                  THEN
                     IF COBRANCACORRETA > 0
                     THEN
                        VPOSICAO := 'B';
                     END IF;
                  END IF;
               END IF;
               -- Cálculo do PTABELA
               BEGIN
                  SELECT (CASE
                            WHEN P.NUMPR = 1 THEN
                             NVL(T.PVENDA1, 0)
                            ELSE
                             CASE
                            WHEN P.NUMPR = 2 THEN
                             NVL(T.PVENDA2, 0)
                            ELSE
                             CASE
                            WHEN P.NUMPR = 3 THEN
                             NVL(T.PVENDA3, 0)
                            ELSE
                             CASE
                            WHEN P.NUMPR = 4 THEN
                             NVL(T.PVENDA4, 0)
                            ELSE
                             CASE
                            WHEN P.NUMPR = 5 THEN
                             NVL(T.PVENDA5, 0)
                            ELSE
                             CASE
                            WHEN P.NUMPR = 6 THEN
                             NVL(T.PVENDA6, 0)
                            ELSE
                             CASE
                            WHEN P.NUMPR = 7 THEN
                             NVL(T.PVENDA7, 0)
                         END END END END END END END) PTABELA
                  INTO   VPTABELA
                  FROM   PCTABPR T, PCPLPAG P
                  WHERE  T.NUMREGIAO IN
                         (SELECT NUMREGIAO
                          FROM   PCPRACA
                          WHERE  CODPRACA IN
                                 (SELECT CODPRACA
                                  FROM   PCCLIENT
                                  WHERE  CODCLI = REGCAB.CODCLI)) AND
                         P.CODPLPAG = REGCAB.CODPLPAG AND
                         T.CODPROD = REGITEM.CODPROD;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPTABELA := 0;
               END;
               ------------------------------------------------------------------------------------------------------------------------------------------
               -- Início => UNILEVER (Integradora 29)
               -- Essa opção é necessária para gerar o valor do PTABELA que foi gravado do PCPEDITEMP.PTABELA da UNILEVER (Rotina 2697)
               -- Se esse valor estiver zerado ou não for da UNILEVER (Rotina 2697 e integradora 29), continua calculando o PTABELA da forma que já estava
               IF VUNILEVER = 'S'
               THEN
                  VPTABELA := NVL(REGITEM.PTABELA, 0);
               END IF;
               -- Fim => UNILEVER (Integradora 29)
               ------------------------------------------------------------------------------------------------------------------------------------------
               IF NVL(VPTABELA, 0) = 0
               THEN
                  VPTABELA := NVL(REGITEM.PVENDA, 0);
               END IF;
               --Cálculo do percentual de desconto (PERDESC)
               VPERDESC := FUNC_CALCULARPERDESCITEM(VPTABELA,
                                                    VPVENDA,
                                                    REGCAB.INTEGRADORA);
               -- fim cálculo do percentual de desconto (PERDESC)
               -- Inclusão do itens na tabela PCPEDI
               IMPORTAR_PEDIDO_WEB_PCPEDI(VNUMPED --01
                                         ,
                                          REGITEM.CODPROD --02
                                         ,
                                          REGITEM.NUMSEQ --03
                                         ,
                                          TRUNC(SYSDATE) --04
                                         ,
                                          REGITEM.QT --05
                                         ,
                                          VPVENDA --06
                                         ,
                                          VPTABELA --07
                                         ,
                                          VCODCLI --08
                                         ,
                                          VCODUSUR --09
                                         ,
                                          VPOSICAO --10
                                         ,
                                          VCUSTOFIN --11
                                         ,
                                          VCUSTOREAL --12
                                         ,
                                          VPERCOM --13
                                         ,
                                          NVL(VPERDESC, 0) --14
                                         ,
                                          VCODFILIAL --15
                                         ,
                                          VPESOBRUTO --16
                                         ,
                                          VCUSTOCONT --17
                                         ,
                                          VCUSTOREP --18
                                         ,
                                          VPBONIFIC --19
                                         ,
                                          'N' --20
                                         ,
                                          VNVLIPI --21
                                         ,
                                          VNPERCIPI --22
                                         ,
                                          VPTABELA --23
                                         ,
                                          VNUMCAR --24
                                         ,
                                          VCODAUXILIAR --25
                                         ,
                                          VIVA --26
                                         ,
                                          REGITEM.QTUNITEMB --27
                                         ,
                                          VNUMREGIAO --28
                                         ,
                                          VCODST --29
                                         ,
                                          REGCAB.CODFILIAL --30
                                         ,
                                          REGCAB.CODFILIALNF --31
                                         ,
                                          NVL(REGITEM.CODPLPAG, VCODPLPAG) --32
                                         ,
                                          NVL(REGCAB.CONDVENDA, VCONDVENDA) --33
                                         ,
                                          VVENDA_SEMIMPOSTOS --34
                                          );
            END LOOP; --FIM LOOP ITEM
         
            VGLOBAL_VLCUSTOFIN  := 0;
            VGLOBAL_VLCUSTOREAL := 0;
            VGLOBAL_VLCUSTOREP  := 0;
            VGLOBAL_VLCUSTOCONT := 0;
            VVLBONIFIC          := 0;
         
            SELECT SUM(ROUND(PCPEDI.QT * PCPEDI.PVENDA, 2)) AS VLTOTAL,
                   SUM(ROUND(PCPEDI.QT * PCPEDI.PTABELA, 2)) AS VLTABELA,
                   SUM(PCPEDI.QT * PCPEDI.PVENDA * CASE
                          WHEN NVL(PCPEDI.BONIFIC, 'N') = 'N' THEN
                           1
                          ELSE
                           0
                       END) AS VLATEND,
                   SUM(PCPEDI.QT * NVL(PCPEDI.PBONIFIC, 0) * CASE
                          WHEN NVL(PCPEDI.BONIFIC, 'N') = 'F' THEN
                           1
                          ELSE
                           0
                       END) AS VLBONIFIC,
                   SUM(PCPEDI.QT * PCPRODUT.PESOBRUTO) AS TOTPESO,
                   SUM(PCPEDI.QT * PCPRODUT.PESOLIQ) AS TOTPESOLIQ,
                   COUNT(PCPEDI.CODPROD) AS NUMITENS,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN) AS VLCUSTOFIN,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL) AS VLCUSTOREAL,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP) AS VLCUSTOREP,
                   SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT) AS VLCUSTOCONT
            INTO   VVLTOTAL,
                   VVLTABELA,
                   VVLATEND,
                   VVLBONIFIC,
                   VTOTPESO,
                   VTOTPESOLIQ,
                   VNUMITENS,
                   VGLOBAL_VLCUSTOFIN,
                   VGLOBAL_VLCUSTOREAL,
                   VGLOBAL_VLCUSTOREP,
                   VGLOBAL_VLCUSTOCONT
            FROM   PCPEDI, PCPRODUT
            WHERE  PCPEDI.NUMPED = VNUMPED AND
                   PCPRODUT.CODPROD = PCPEDI.CODPROD;
         
            VVLOUTRASDESP := NVL(REGCAB.VLOUTRASDESP, 0);
            VVLTOTAL      := NVL(VVLTOTAL, 0) + NVL(VVLFRETE, 0) +
                             VVLOUTRASDESP;
            VVLTABELA     := NVL(VVLTABELA, 0) + NVL(VVLFRETE, 0) +
                             VVLOUTRASDESP;
            VVLATEND      := NVL(VVLATEND, 0) + NVL(VVLFRETE, 0) +
                             VVLOUTRASDESP;
         
            VCODEMITENTE           := NVL(REGCAB.CODEMITENTE, '8888');
            VGLOBAL_OBSENTREGA4    := REGCAB.OBSENTREGA4;
            VGLOBAL_CODTRANSP      := CASE WHEN NVL(REGCAB.CODTRANSP, 0) > 0 THEN REGCAB.CODTRANSP ELSE NULL END;
            VGLOBAL_TIPOVENDA      := VTIPOVENDA;
            VGLOBAL_CODFORNECFRETE := CASE WHEN NVL(REGCAB.CODFORNECFRETE, 0) > 0 THEN REGCAB.CODFORNECFRETE ELSE NULL END;
            VGLOBAL_CODENDENTCLI   := REGCAB.CODENDENTCLI;
            VGLOBAL_OBS2           := REGCAB.OBS2;
         
            IMPORTAR_PEDIDO_WEB_PCPEDC(VNUMPED,
                                       TRUNC(SYSDATE),
                                       REGCAB.CODFILIAL,
                                       REGCAB.CODFILIALNF,
                                       REGCAB.CODCLI,
                                       REGCAB.CODUSUR,
                                       REGCAB.CODPLPAG,
                                       REGCAB.CODCOB,
                                       VVLTOTAL,
                                       VVLATEND,
                                       VVLTABELA,
                                       VPOSICAO,
                                       NVL(REGCAB.CODPRACA, VCODPRACA),
                                       PNUMPEDWEB,
                                       TO_CHAR(PNUMPEDWEB),
                                       PNUMPEDWEB,
                                       PINTEGRADORA,
                                       VTOTPESO,
                                       VTOTPESOLIQ,
                                       VORIGEMPED,
                                       VNUMITENS,
                                       VCONDVENDA,
                                       VVLFRETE,
                                       NVL(VDTENTREGA, TRUNC(SYSDATE)),
                                       VPERCVENDA,
                                       VVLOUTRASDESP,
                                       VCODDISTRIB,
                                       VFRETEDESPACHO,
                                       VFRETEREDESPACHO,
                                       VCODSUPERVISOR,
                                       VVLBONIFIC,
                                       VCODEMITENTE,
                                       REGCAB.OBS1,
                                       VNUMCAR,
                                       TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                                       TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                                       VNUMREGIAO,
                                       REGCAB.VLDESCONTOCUPOM,
                                       'N',
                                       'N',
                                       REGCAB.CNPJINTERMEDIADOR,
                                       REGCAB.DESCINTERMEDIADOR,
									   REGCAB.CODBNF);
         
            IMPORTAR_PEDIDO_WEB_PERCOM(VNUMPED);
         
            IMPORTAR_PEDIDO_WEB_ESTOQUEPKG(VNUMPED, VPOSICAO);
         
            IF (NVL(VGLOBAL_RETORNO_ESTOQUE, '') <> '')
            THEN
               VERRO     := 'S';
               VMENSAGEM := VMENSAGEM || VGLOBAL_RETORNO_ESTOQUE || ';';
            END IF;
         
            IF (REGCAB.INTEGRADORA IN (29, 33, 34, 36) OR REGCAB.INTEGRADORA > 999) AND
               REGCAB.CONDVENDA <> 5
            THEN
               IMPORTAR_PEDIDO_PCFORMAPAGTO(PNUMPEDWEB, VNUMPED);
            END IF;
         
            IF VPOSICAO = 'B'
            THEN
               BEGIN
                  SELECT COUNT(PCECOMMERCEB2BPCPEDC.NUMPEDWEB) CONTADOR
                  INTO   VPEDIDOB2B
                  FROM   PCECOMMERCEB2BPCPEDC
                  WHERE  PCECOMMERCEB2BPCPEDC.NUMPEDWEB = VNUMPED AND
                         PCECOMMERCEB2BPCPEDC.CODFILIAL = VCODFILIAL AND
                         PCECOMMERCEB2BPCPEDC.INTEGRADORA = PINTEGRADORA;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPEDIDOB2B := 0;
               END;
            
               IF VPEDIDOB2B > 0
               THEN
                  BEGIN
                     SELECT PCECOMMERCEB2B.MATRICULA
                     INTO   VMATRICULA
                     FROM   PCECOMMERCEB2B
                     WHERE  PCECOMMERCEB2B.CODFILIAL = VCODFILIAL AND
                            PCECOMMERCEB2B.TIPOINTEGRACAO = PINTEGRADORA;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMATRICULA := 0;
                  END;
               ELSE
                  BEGIN
                     SELECT PCECOMMERCEUNILEVER.MATRICULA
                     INTO   VMATRICULA
                     FROM   PCECOMMERCEUNILEVER
                     WHERE  PCECOMMERCEUNILEVER.CODFILIAL = VCODFILIAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        VMATRICULA := 0;
                  END;
               END IF;
            
               PKG_MOTIVOBLOQUEIO.VALIDAMOTIVOSBLOQUEIO(VNUMPED,
                                                        VMATRICULA,
                                                        2500);
            
               DELETE FROM PCBLOQUEIOSPEDIDO
               WHERE  PCBLOQUEIOSPEDIDO.NUMPED = VNUMPED AND
                      PCBLOQUEIOSPEDIDO.CODMOTIVO IN
                      (1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24);
            
               BEGIN
                  SELECT COUNT(PCBLOQUEIOSPEDIDO.NUMPED) AS CONTADOR
                  INTO   VPOSSUIPEDIDOBLOQUEADO
                  FROM   PCBLOQUEIOSPEDIDO
                  WHERE  PCBLOQUEIOSPEDIDO.NUMPED = VNUMPED;
               EXCEPTION
                  WHEN OTHERS THEN
                     VPOSSUIPEDIDOBLOQUEADO := 0;
               END;
            
               IF VPOSSUIPEDIDOBLOQUEADO = 0
               THEN
                  PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(VNUMPED,
                                                  25,
                                                  'PEDIDOS DA INTEGRACAO',
                                                  'C');
               END IF;
            END IF;
         END LOOP; --FIM LOOP CABEÇALHO
      
         UPDATE PCPEDCTEMP
         SET    IMPORTADO      = 'S',
                NUMPED         = VNUMPED,
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         IMPORTAR_PEDIDO_WEB_COMPLETO(VNUMPED, VPEDIDO_COMPLETO);
      
         IF VPEDIDO_COMPLETO = 'N'
         THEN
            VERRO     := 'S';
            VMENSAGEM := VMENSAGEM ||
                         'EC-01013-Pedido gerado com ausência de cabeçalho e/ou item;';
         END IF;
      
         VSMSGTEMP := '';
      
         BEGIN
            SELECT COUNT(E.NUMPEDWEB) AS CONTADOR
            INTO   VQT_PEDIDOB2B
            FROM   PCFORMAPGTOPEDIDOTEMP E
            WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                   E.INTEGRADORA = PINTEGRADORA AND
                   E.CODFILIAL = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VQT_PEDIDOB2B := 0;
         END;
      
         BEGIN
            SELECT CONDVENDA
            INTO   VPEDIDOB2B_CONDICAO_VENDA
            FROM   PCPEDCTEMP E
            WHERE  E.NUMPEDWEB = PNUMPEDWEB AND
                   E.INTEGRADORA = PINTEGRADORA AND
                   E.CODFILIAL = VCODFILIAL;
         EXCEPTION
            WHEN OTHERS THEN
               VPEDIDOB2B_CONDICAO_VENDA := 0;
         END;
      
         IF VQT_PEDIDOB2B > 1 AND
            VPEDIDOB2B_CONDICAO_VENDA <> 5
         THEN
            IF IMPORTARVENDASMULTIPAG.FUNC_VALIDAR_MULT_PLANOS_WEB(PNUMPEDWEB,
                                                                   PCODUSUR,
                                                                   PINTEGRADORA,
                                                                   VNUMPED,
                                                                   VSMSGTEMP) =
               FALSE
            THEN
               VERRO     := 'S';
               VMENSAGEM := VMENSAGEM || 'EC-01014-' || VSMSGTEMP;
            END IF;
         END IF;
      
         IF VERRO = 'S'
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END IF;
   
      IF VERRO = 'N'
      THEN
         VMENSAGEM := '';
         VMENSAGEM := VMENSAGEM || 'Pedido web de número ' ||
                      TO_CHAR(PNUMPEDWEB) || ' importado com sucesso;';
         VMENSAGEM := VMENSAGEM || 'Pedido pendente de número ' ||
                      TO_CHAR(VNUMPED) || ' foi gerado no Winthor.';
      
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      ELSE
         UPDATE PCPEDCTEMP
         SET    OBSERVACAO_PC  = SUBSTR(VMENSAGEM, 1, 300),
                OBSINTEGRACAO1 = 'PACKAGE IMPORTARVENDASCOMPLE'
         WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                PCPEDCTEMP.CODUSUR = PCODUSUR AND
                PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                PCPEDCTEMP.CONDVENDA = VCONDVENDA;
      
         COMMIT;
      END IF;
   END IMPORTAR_PEDIDO_WEB_NORMAL;

   PROCEDURE IMPORTAR_PEDIDO_WEB
   (
      PNUMPEDWEB   IN NUMBER,
      PINTEGRADORA IN NUMBER,
      PCODUSUR     IN NUMBER
   ) IS
      VORIGEMPED              VARCHAR2(1);
      VPERMITEITEMBNFTV1      VARCHAR2(1);
      VUTILIZAFILIALCLIENTENF VARCHAR2(1);
      VCONTADOR               NUMBER(8, 0);
      VCADASTROCLICEUNILEVER  VARCHAR2(10);
   BEGIN
      VORIGEMPED              := 'W';
      VCONTADOR               := 0;
      VPERMITEITEMBNFTV1      := 'N';
      VUTILIZAFILIALCLIENTENF := 'N';
      VCADASTROCLICEUNILEVER  := 'PEN';
   
      BEGIN
         SELECT NVL(PCPARAMFILIAL.VALOR, 'N') AS VALOR
         INTO   VPERMITEITEMBNFTV1
         FROM   PCPARAMFILIAL
         WHERE  PCPARAMFILIAL.NOME = 'PERMITEITEMBNFTV1' --Parâmetro 3045  da rotina 132
                AND
                PCPARAMFILIAL.CODFILIAL = '99';
      EXCEPTION
         WHEN OTHERS THEN
            VPERMITEITEMBNFTV1 := 'N';
      END;
   
      IF PINTEGRADORA IN (29)
      THEN
         --Ecommerce Unilever 2697
         BEGIN
            SELECT NVL(PCECOMMERCEUNILEVER.USAFILIALNF, 'N') AS VALOR
            INTO   VUTILIZAFILIALCLIENTENF
            FROM   PCECOMMERCEUNILEVER
            WHERE  PCECOMMERCEUNILEVER.CODFILIAL =
                   (SELECT DISTINCT CODFILIAL
                    FROM   PCPEDCTEMP
                    WHERE  NUMPEDWEB = PNUMPEDWEB AND
                           INTEGRADORA = PINTEGRADORA AND
                           CODUSUR = PCODUSUR);
         EXCEPTION
            WHEN OTHERS THEN
               VUTILIZAFILIALCLIENTENF := 'N';
         END;
      
         SELECT SITUACAOECOMMERCEUNILEVER
         INTO   VCADASTROCLICEUNILEVER
         FROM   PCCLIENT
         WHERE  CODCLI = (SELECT DISTINCT CODCLI
                          FROM   PCPEDCTEMP
                          WHERE  NUMPEDWEB = PNUMPEDWEB AND
                                 INTEGRADORA = PINTEGRADORA AND
                                 CODUSUR = PCODUSUR);
      
         IF VUTILIZAFILIALCLIENTENF = 'S'
         THEN
            UPDATE PCPEDCTEMP
            SET    CODFILIALNF = (SELECT CODFILIALNF
                                  FROM   PCCLIENT
                                  WHERE  CODCLI =
                                         (SELECT DISTINCT CODCLI
                                          FROM   PCPEDCTEMP
                                          WHERE  NUMPEDWEB = PNUMPEDWEB AND
                                                 INTEGRADORA = PINTEGRADORA AND
                                                 CODUSUR = PCODUSUR))
            WHERE  NUMPEDWEB = PNUMPEDWEB AND
                   INTEGRADORA = PINTEGRADORA;
         END IF;
      END IF;
   
      IF VUTILIZAFILIALCLIENTENF = 'S' AND
         VCADASTROCLICEUNILEVER <> 'APV'
      THEN
         UPDATE PCPEDCTEMP
         SET    IMPORTADO     = 'N',
                OBSERVACAO_PC = 'O cadastro do cliente precisa ser aprovado e verificar se o mesmo tem filial de faturamento.'
         WHERE  NUMPEDWEB = PNUMPEDWEB AND
                INTEGRADORA = PINTEGRADORA;
         COMMIT;
      
      ELSE
      
         FOR REG IN (SELECT PCPEDCTEMP.NUMPEDWEB,
                            PCPEDCTEMP.INTEGRADORA,
                            PCPEDCTEMP.CODUSUR,
                            NVL(PCPEDCTEMP.CONDVENDA, 1) CONDVENDA,
                            NVL(PCPEDCTEMP.CODCLI, 0) CODCLI
                     FROM   PCPEDCTEMP
                     WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                            PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                            PCPEDCTEMP.CODUSUR = PCODUSUR AND
                            PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                            NVL(PCPEDCTEMP.CONDVENDA, 1) IN (1, 5)
                     ORDER  BY PCPEDCTEMP.CONDVENDA DESC)
         LOOP
            IMPORTAR_PEDIDO_WEB_LIMPAOBS(PNUMPEDWEB,
                                         PINTEGRADORA,
                                         PCODUSUR);
         
            IF REG.CONDVENDA = 1
            THEN
               IF VPERMITEITEMBNFTV1 = 'N'THEN
                  IF PINTEGRADORA IN (29, 33, 34, 36) OR PINTEGRADORA > 999 THEN
                     IMPORTAR_PEDIDO_WEB_NORMAL(PNUMPEDWEB,
                                                PINTEGRADORA,
                                                PCODUSUR,
                                                REG.CONDVENDA,
                                                'N');
                  ELSE
                     -- Verifica se há itens bonificadas para venda tv1
                     VCONTADOR := 0;
                     BEGIN
                        SELECT COUNT(PCPEDCTEMP.NUMPEDWEB) AS TOTAL
                        INTO   VCONTADOR
                        FROM   PCPEDCTEMP, PCPEDITEMP
                        WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                               NVL(PCPEDCTEMP.CONDVENDA, 1) = 1 AND
                               PCPEDCTEMP.NUMPEDWEB = PCPEDITEMP.NUMPEDWEB AND
                               PCPEDCTEMP.INTEGRADORA =
                               PCPEDITEMP.INTEGRADORA AND
                               PCPEDCTEMP.CODUSUR = PCPEDITEMP.CODUSUR AND
                               PCPEDCTEMP.TIPOINTEGRACAO =
                               PCPEDITEMP.TIPOINTEGRACAO AND
                               PCPEDITEMP.BONIFIC = 'F';
                     EXCEPTION
                        WHEN OTHERS THEN
                           VCONTADOR := 0;
                     END;
                  
                     IF VCONTADOR > 0
                     THEN
                        IMPORTAR_PEDIDO_WEB_NORMAL(PNUMPEDWEB,
                                                   PINTEGRADORA,
                                                   PCODUSUR,
                                                   REG.CONDVENDA,
                                                   'N');
                        IMPORTAR_PEDIDO_WEB_BONIFIC(REG.NUMPEDWEB,
                                                    REG.INTEGRADORA,
                                                    REG.CODUSUR,
                                                    REG.CONDVENDA,
                                                    'F');
                     ELSE
                        IMPORTAR_PEDIDO_WEB_NORMAL(PNUMPEDWEB,
                                                   PINTEGRADORA,
                                                   PCODUSUR,
                                                   REG.CONDVENDA,
                                                   'N');
                     END IF;
                  END IF;
               ELSE
                  IMPORTAR_PEDIDO_WEB_NORMAL_BNF(PNUMPEDWEB,
                                                 PINTEGRADORA,
                                                 PCODUSUR,
                                                 REG.CONDVENDA);
               END IF;
            ELSE
               IMPORTAR_PEDIDO_WEB_BONIFIC(REG.NUMPEDWEB,
                                           REG.INTEGRADORA,
                                           REG.CODUSUR,
                                           REG.CONDVENDA,
                                           'F');
            END IF;
         
            IMPORTAR_PEDIDO_WEB_CODUSUR(REG.INTEGRADORA,
                                        REG.NUMPEDWEB,
                                        REG.CODCLI);
         END LOOP;
      
         FOR REG IN (SELECT PCPEDCTEMP.NUMPEDWEB,
                            PCPEDCTEMP.INTEGRADORA,
                            PCPEDCTEMP.CODUSUR,
                            PCPEDCTEMP.CODFILIAL,
                            NVL(PCPEDCTEMP.CONDVENDA, 1) CONDVENDA,
                            NVL(PCPEDCTEMP.CODCLI, 0) CODCLI
                     FROM   PCPEDCTEMP
                     WHERE  PCPEDCTEMP.NUMPEDWEB = PNUMPEDWEB AND
                            PCPEDCTEMP.INTEGRADORA = PINTEGRADORA AND
                            PCPEDCTEMP.CODUSUR = PCODUSUR AND
                            PCPEDCTEMP.TIPOINTEGRACAO = VORIGEMPED AND
                            NVL(PCPEDCTEMP.CONDVENDA, 1) IN (1, 5)
                     ORDER  BY PCPEDCTEMP.CONDVENDA DESC)
         LOOP
            UPDATE PCPEDC T
            SET    NUMPEDTV1 = (SELECT TV1.NUMPED
                                FROM   PCPEDC TV1
                                WHERE  TV1.NUMPEDWEB = T.NUMPEDWEB AND
                                       TV1.INTEGRADORA = T.INTEGRADORA AND
                                       TV1.CONDVENDA = 1)
            WHERE  T.NUMPEDWEB = REG.NUMPEDWEB AND
                   T.INTEGRADORA = REG.INTEGRADORA AND
                   T.CONDVENDA = 5;
         
            UPDATE PCPEDC T
            SET    NUMPEDBNF = (SELECT TV5.NUMPED
                                FROM   PCPEDC TV5
                                WHERE  TV5.NUMPEDWEB = T.NUMPEDWEB AND
                                       TV5.INTEGRADORA = T.INTEGRADORA AND
                                       TV5.CONDVENDA = 5)
            WHERE  T.NUMPEDWEB = REG.NUMPEDWEB AND
                   T.INTEGRADORA = REG.INTEGRADORA AND
                   T.CONDVENDA = 1;
            COMMIT;
         
         END LOOP;
      
      END IF;
   END IMPORTAR_PEDIDO_WEB;

END IMPORTARVENDASCOMPLE;


