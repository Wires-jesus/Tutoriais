CREATE OR REPLACE PACKAGE BODY PKG_MOTIVOBLOQUEIO IS

  FUNCTION FUNC_CALCULARPERDESCITEM(P_PTABELA IN PCPEDI.PTABELA%TYPE,
                                    P_PVENDA  IN PCPEDI.PVENDA%TYPE)
    RETURN NUMBER IS
    VNPERDESC NUMBER;
  BEGIN

    VNPERDESC := ((P_PTABELA - P_PVENDA) / P_PTABELA) * 100;

    RETURN VNPERDESC;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END FUNC_CALCULARPERDESCITEM;

  FUNCTION FUNC_TEMPERMISSAO(PCODROTINA   IN NUMBER,
                             PCODUSUARIO  IN NUMBER,
                             PCODCONTROLE IN NUMBER) RETURN BOOLEAN IS
    vsPermissao Varchar2(1);
    vPosicao    NUMBER(22, 0);
  BEGIN

    BEGIN
      vsPermissao := 'N';
      FOR vPosicao IN 1 .. VCPermissoes.COUNT LOOP
         IF VCPermissoes(vPosicao) = PCODCONTROLE THEN
           vsPermissao := 'S';
         END IF;
      END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;

    IF (vsPermissao = 'S') THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END FUNC_TEMPERMISSAO;

  PROCEDURE CARREGAR_PERMISSOES(PCODROTINA   IN NUMBER,
                               PCODUSUARIO  IN NUMBER)
  IS
  BEGIN
    VCPermissoes := TPermissoes();
    FOR permissao in (
      select NVL(pm.acesso, 'N') acesso
           , pm.codcontrole
        from pccontroi pm
       where pm.codrotina = pcodrotina
         and pm.codusuario = pcodusuario
         and NVL(pm.acesso, 'N') = 'S'
         ) loop
           VCPermissoes.EXTEND;
           VCPermissoes(VCPermissoes.LAST) := permissao.codcontrole;
         end loop;
  END;


  FUNCTION FUNC_EXISTEITEMPSICOTROPICO(pNUMPED PCPEDI.NUMPED%TYPE,
                                       pTIPO   VARCHAR2) RETURN BOOLEAN IS
    vnEXISTE Number;
  BEGIN
    BEGIN
      IF (pTIPO = 'P') THEN
        SELECT COUNT(1) RESULT
          INTO vnEXISTE
          FROM PCPRODUT, PCPEDI
         WHERE PCPRODUT.CODPROD = PCPEDI.CODPROD
           AND PCPRODUT.PSICOTROPICO = 'S'
           AND PCPEDI.NUMPED = pNUMPED;

      ELSE
        SELECT COUNT(1) RESULT
          INTO vnEXISTE
          FROM PCPRODUT, PCPEDI
         WHERE PCPRODUT.CODPROD = PCPEDI.CODPROD
           AND PCPRODUT.TIPOMERC IN ('M', 'MA')
           AND PCPEDI.NUMPED = pNUMPED;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;
    IF (vnEXISTE > 0) THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END FUNC_EXISTEITEMPSICOTROPICO;

  FUNCTION FUNC_CALCULANUMPARCPLPAG(PCODPLPAG IN NUMBER) RETURN INTEGER IS
    vnNUMPARCELAS INTEGER;
    vnPRAZO1      NUMBER;
    vnPRAZO2      NUMBER;
    vnPRAZO3      NUMBER;
    vnPRAZO4      NUMBER;
    vnPRAZO5      NUMBER;
    vnPRAZO6      NUMBER;
    vnPRAZO7      NUMBER;
    vnPRAZO8      NUMBER;
    vnPRAZO9      NUMBER;
    vnPRAZO10     NUMBER;
  BEGIN
    VNNUMPARCELAS := 0;
    BEGIN
      SELECT PRAZO1,
             PRAZO2,
             PRAZO3,
             PRAZO4,
             PRAZO5,
             PRAZO6,
             PRAZO7,
             PRAZO8,
             PRAZO9,
             PRAZO10
        INTO vnPRAZO1,
             vnPRAZO2,
             vnPRAZO3,
             vnPRAZO4,
             vnPRAZO5,
             vnPRAZO6,
             vnPRAZO7,
             vnPRAZO8,
             vnPRAZO9,
             vnPRAZO10
        FROM PCPLPAG
       WHERE CODPLPAG = PCODPLPAG;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        VNNUMPARCELAS := 0;
    END;

    VNNUMPARCELAS := 1;
    IF vnPRAZO1 > 0 THEN
      VNNUMPARCELAS := 1;
      IF vnPRAZO2 > 0 THEN
        VNNUMPARCELAS := VNNUMPARCELAS + 1;
        IF vnPRAZO3 > 0 THEN
          VNNUMPARCELAS := VNNUMPARCELAS + 1;
          IF vnPRAZO4 > 0 THEN
            VNNUMPARCELAS := VNNUMPARCELAS + 1;
            IF vnPRAZO5 > 0 THEN
              VNNUMPARCELAS := VNNUMPARCELAS + 1;
              IF vnPRAZO6 > 0 THEN
                VNNUMPARCELAS := VNNUMPARCELAS + 1;
                IF vnPRAZO7 > 0 THEN
                  VNNUMPARCELAS := VNNUMPARCELAS + 1;
                  IF vnPRAZO8 > 0 THEN
                    VNNUMPARCELAS := VNNUMPARCELAS + 1;
                    IF vnPRAZO9 > 0 THEN
                      VNNUMPARCELAS := VNNUMPARCELAS + 1;
                      IF vnPRAZO10 > 0 THEN
                        VNNUMPARCELAS := VNNUMPARCELAS + 1;
                      END IF;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    RETURN VNNUMPARCELAS;
  END FUNC_CALCULANUMPARCPLPAG;

  FUNCTION BLOQWEB(PNUMPED IN NUMBER,
                   PCODMOTBLOQUEIO IN NUMBER) RETURN BOOLEAN IS
       vorigemped varchar2(1);
       vorigembpedloqueio varchar2(1);
  BEGIN

    select origemped into vorigemped
        from pcpedc c
       where c.numped = PNUMPED;

    select nvl(b.origemped, 'T') into vorigembpedloqueio
      from pcbloqueio b
     where b.codmotbloqueio = PCODMOTBLOQUEIO;

    IF vorigemped = 'W' and vorigembpedloqueio <> 'W' THEN
      Return false;
    END IF;

    return true;

  EXCEPTION
    WHEN OTHERS THEN

      IF vorigemped = 'W' THEN
         return false;
      END IF;

      Return true;

  END;

  PROCEDURE INSERTMOTIVO(PNUMPED         IN NUMBER,
                         PCODMOTIVO      IN NUMBER,
                         PMOTIVO         VARCHAR2,
                         PTIPO           VARCHAR2,
                         PCODMOTBLOQUEIO IN NUMBER DEFAULT NULL) IS
    VNCODIGO           PCBLOQUEIOSPEDIDO.codigo%TYPE;
    rPCBLOQUEIOSPEDIDO PCBLOQUEIOSPEDIDO%rowtype;
  BEGIN

    if NVL(PCODMOTIVO, -1) <> 0 --and BLOQWEB(PNUMPED, PCODMOTBLOQUEIO)
    then

      SELECT dfseq_pcbloqueiospedido.NEXTVAL INTO VNCodigo FROM DUAL;

    rPCBLOQUEIOSPEDIDO.codigo         := VNCodigo;
    rPCBLOQUEIOSPEDIDO.numped         := PNUMPED;
    rPCBLOQUEIOSPEDIDO.codmotivo      := PCODMOTIVO;
    rPCBLOQUEIOSPEDIDO.CODMOTBLOQUEIO := pCODMOTBLOQUEIO;
    rPCBLOQUEIOSPEDIDO.motivo         := substr(PMOTIVO, 1, 200);
    rPCBLOQUEIOSPEDIDO.status         := 'B';
    rPCBLOQUEIOSPEDIDO.TIPO           := PTIPO;
    rPCBLOQUEIOSPEDIDO.DTINCLUSAO     := SYSDATE;

    INSERT INTO PCBLOQUEIOSPEDIDO VALUES RPCBLOQUEIOSPEDIDO;

    end if;

  END INSERTMOTIVO;

  PROCEDURE INSERTAUTORC(VCPEDIDO          IN C_PEDIDO%ROWTYPE,
                         pCODFUNC          in number,
                         pVLLIBERADO       in number
                         ) IS
    VNCODIGO  PCAUTORC.NUMPEDIDO%TYPE;
    rPCAUTORC PCAUTORC%rowtype;
    rCount    NUMBER;
    vnVlLiberado NUMBER;
  BEGIN

        BEGIN
      SELECT NVL(MAX(VLLIBERADO),0)
        INTO vnVlLiberado
        from (SELECT PCAUTORC.VLLIBERADO
                FROM PCAUTORC
               WHERE NVL(PCAUTORC.CODCLI, VCPEDIDO.Codcli) = VCPEDIDO.Codcli
                 AND NVL(PCAUTORC.CODUSUR, VCPEDIDO.Codusur) =
                     VCPEDIDO.Codusur
                 AND PCAUTORC.DTUTILIZACAO IS NOT NULL
                 AND PCAUTORC.CODFUNCUTILIZACAO IS NOT NULL
                 AND PCAUTORC.NUMPEDUTILIZACAO = VCPEDIDO.Numped
                 AND PCAUTORC.LIBERARPORPEDIDO = 'LP'
                 AND PCAUTORC.OBS LIKE
                     '%Observação gerada automaticamente pela rotina 336 via PKG_MOTIVOBLOQUEIO%'
               ORDER BY DATA);
    EXCEPTION
      WHEN OTHERS THEN
        vnVlLiberado := 0;
    END;

    IF vnVlLiberado < pVLLIBERADO THEN

      SELECT DFSEQ_PCAUTORC.NEXTVAL INTO VNCodigo FROM DUAL;

      rPCAUTORC.numpedido        := VNCodigo;
      rPCAUTORC.Data             := trunc(sysdate);
      rPCAUTORC.Codfunc          := pCODFUNC;
      rPCAUTORC.Liberalimcred    := 'S';
      rPCAUTORC.Codcli           := VCPEDIDO.codcli;
      rPCAUTORC.Codusur          := VCPEDIDO.codusur;
      rPCAUTORC.Codplpag         := VCPEDIDO.codplpag;
      rPCAUTORC.Vlliberado       := pVLLIBERADO;
      rPCAUTORC.Numpedliberar    := VCPEDIDO.numped;
      rPCAUTORC.Liberarporpedido := 'LP';
      rPCAUTORC.Obs              := 'Observação gerada automaticamente pela rotina 336 via PKG_MOTIVOBLOQUEIO';

      rCount := 0;

      Select NVL(Count(*), 0)
        into rCount
        from PCAUTORC
       Where Numpedido = VNCodigo;

      if (rCount) > 0 then
        UPDATE PCAUTORC
           SET DATA             = rPCAUTORC.Data,
               codfunc          = rPCAUTORC.Codfunc,
               liberalimcred    = 'S',
               vlliberado       = pVLLIBERADO,
               liberarporpedido = 'LP',
               Codplpag         = VCPEDIDO.codplpag,
               Codusur          = VCPEDIDO.codusur,
               obs              = 'Observação gerada automaticamente pela rotina 336 via PKG_MOTIVOBLOQUEIO'
         WHERE NUMPEDIDO = VNCodigo;
      else
        INSERT INTO PCAUTORC VALUES rPCAUTORC;
      end if;
    END IF;

  END INSERTAUTORC;

  PROCEDURE ATUALIZARPCAUTORC(VCPEDIDO        IN C_PEDIDO%ROWTYPE,
                              pCODFUNC        in number,
                              pNUMAUTORIZACAO in number,
                              pLIMCRED        in number) IS
  BEGIN

    UPDATE PCAUTORC
       SET LIMCRED           = pLIMCRED,
           DTUTILIZACAO      = TRUNC(SYSDATE),
           CODFUNCUTILIZACAO = pCODFUNC,
           NUMPEDUTILIZACAO  = VCPEDIDO.NUMPED
     WHERE NUMPEDIDO = pNUMAUTORIZACAO
       AND CODUSUR = VCPEDIDO.codusur
       AND CODCLI = vcpedido.codcli;

  END ATUALIZARPCAUTORC;

  FUNCTION USUARIOPODEAUTORIZARLIMITE(pCODCLI       in NUMBER,
                                      pCODFUNC      in NUMBER,
                                      pVLDISPONIVEL in number,
                                      pVLPEDIDO     in number)
    RETURN BOOLEAN IS
    vnVLAUTORMENSAL    number;
    vnVlMaxAutorizacao number;
    vbResult           boolean;
  BEGIN

    vbResult := false;

    if FUNC_TEMPERMISSAO(336, pCODFUNC, 46) then

      begin
        SELECT SUM(NVL(PCAUTORC.VLLIBERADO, 0))
          into vnVLAUTORMENSAL
          FROM PCAUTORC
         WHERE CODCLI = pCODCLI
           AND CODFUNC = pCODFUNC
           AND PCAUTORC.DATA BETWEEN
               TO_DATE('01/' || TO_CHAR(SYSDATE, 'MM/YYYY'), 'DD/MM/YYYY') AND
               TRUNC(SYSDATE);
      exception
        when others then
          vnVLAUTORMENSAL := 0;
      end;

      vnVLAUTORMENSAL := NVL(vnVLAUTORMENSAL,0);

      begin
        IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('SOMACREDITOCLIPRINCIPAL',
                                                                        '99',
                                                                        'N') = 'S') THEN
          with cliente as
           (select SUM(limcred) limcred
              from pcclient
             where codcli IN (SELECT CODCLI
                                   FROM PCCLIENT
                                  WHERE CODCLIPRINC =
                                        (SELECT NVL(codcliprinc, CODCLI)
                                           FROM PCCLIENT
                                          WHERE PCCLIENT.CODCLI = pCODCLI)
                                 UNION ALL
                                 SELECT CODCLI
                                   FROM PCCLIENT
                                  WHERE CODCLI =
                                        (SELECT NVL(codcliprinc, CODCLI)
                                           FROM PCCLIENT
                                          WHERE PCCLIENT.CODCLI = pCODCLI)
                                    AND CODCLIPRINC IS NULL)),
          usuario as
           (select NVL(PERCEXCLIMCRED,0)PERCEXCLIMCRED  from pcempr where matricula = pCODFUNC)
          select cliente.limcred * (usuario.PERCEXCLIMCRED / 100)
            into vnVlMaxAutorizacao
            from cliente, usuario;
        ELSE
          with cliente as
           (select limcred from pcclient where codcli = pCODCLI),
          usuario as
           (select NVL(PERCEXCLIMCRED,0)PERCEXCLIMCRED  from pcempr where matricula = pCODFUNC)
          select cliente.limcred * (usuario.PERCEXCLIMCRED / 100)
            into vnVlMaxAutorizacao
            from cliente, usuario;
        END IF;
      exception
        when others then
          vnVlMaxAutorizacao := 0;
      end;

      vbResult := (vnVLAUTORMENSAL + (pVLPEDIDO - pVLDISPONIVEL)) <=
                  (vnVlMaxAutorizacao);

    end if;

    return(vbResult);

  END;

  FUNCTION isCobrancaCartao(pCodCob in varchar) return boolean is
    vsCartao varchar2(1);
  begin

    begin
      select nvl(cartao, 'N')
        into vsCartao
        from pccob
       where codcob = pCodCob;
    exception
      when others then
        vsCartao := 'N';
    end;

    return(vsCartao = 'S');

  end;

  PROCEDURE ALTERASTATUSBLOQUEIO(PCODBLOQUEIO  NUMBER,
                                 PSTATUS       VARCHAR,
                                 PNUMPED       NUMBER,
                                 PCODFUNC      NUMBER,
                                 PCODROTINA    NUMBER,
                                 PTIPOBLOQUEIO VARCHAR) IS
    vbPodeAlterarPosicao boolean;
  BEGIN

    IF (PCODROTINA = 336) and (PSTATUS = 'L') then
      case PTIPOBLOQUEIO
        when 'C' then
          vbPodeAlterarPosicao := FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 24);
        when 'F' then
          vbPodeAlterarPosicao := FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 25);
      end case;
    else
      vbPodeAlterarPosicao := true;
    END IF;

    if (vbPodeAlterarPosicao) and (PCODROTINA = 336) then

      UPDATE PCBLOQUEIOSPEDIDO
         SET STATUS        = PSTATUS,
             codfunclibera = decode(PSTATUS, 'L', PCODFUNC, null),
             dtlibera      = decode(PSTATUS, 'L', sysdate, null)
       WHERE CODMOTIVO = PCODBLOQUEIO
         AND NUMPED = PNUMPED
         AND CODFUNCLIBERA IS NULL
         AND DTLIBERA IS NULL;

    end if;

    if (vbPodeAlterarPosicao) and ((PCODROTINA = 316) or (PCODROTINA = 2500)) and (PSTATUS = 'L')then

      DELETE FROM PCBLOQUEIOSPEDIDO
       WHERE NUMPED = PNUMPED
         AND CODMOTIVO = PCODBLOQUEIO
         AND CODMOTBLOQUEIO IS NULL;

    end if;

    delete from PCBLOQUEIOSPEDIDO
     where codmotivo = 0
       and numped = pNUMPED;

  END ALTERASTATUSBLOQUEIO;

PROCEDURE validaLimCreditoConvencional(PTIPOMOTIVO VARCHAR,
                                         PCODMOTIVO  NUMBER,
                                         VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                                         PCODFUNC    IN NUMBER,
                                         PCODROTINA  IN NUMBER) is
    vnVLCREDDISPONIVEL         NUMBER;
    vnVLCREDCONTASRECEBER      NUMBER;
    vnVLCREDPEDFATURAR         NUMBER;
    vnVLCREDPEDCHEQUE          NUMBER;
    VNVLLIMTCLIENTESAZONAL     NUMBER;
    VNVLLIMTCREDEXTRA          NUMBER;
    vnVLCREDDISPONIVELTOTAL    NUMBER;
    vnVLTOTALPEDIDO            NUMBER;
    vnAUTORIZACAO              NUMBER;
    vnVlLiberado             PCAUTORC.Vlliberado%TYPE;
    vsSOMACREDITOCLIPRINCIPAL  VARCHAR(1);
    vsCHECARDIASUTEISTITPGNLIB VARCHAR(1);
    VSUSABNFLIMITECREDITO      VARCHAR(1);
    VnCODIGO                   PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vdatavalidadecredito       date;
    vsObsMotivo                varchar2(80);
    vbNaoVerificaLimCredCodCobD   BOOLEAN := FALSE;
    vnVLCREDPEDFATURAR_D          NUMBER;
    vSQL                       VARCHAR2(4000);

  begin

    --BUSCA LIMITE DE CREDITO DISPONIVEL
      vsOBSMotivo := null;
      BEGIN

        vsSOMACREDITOCLIPRINCIPAL  := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('SOMACREDITOCLIPRINCIPAL',
                                                                         '99',
                                                                         'N');
        vsCHECARDIASUTEISTITPGNLIB := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_CHECARDIASUTEISTITPGNLIB',
                                                                         '99',
                                                                         'N');
        VSUSABNFLIMITECREDITO      := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USABNFLIMITECREDITO',     -- ALTERAÇÂO PARA RESOLVER LENTIDÃO NO USO PARÂMETRO - DEYVID COSTA
                                                                         '99',
                                                                         'N');

        IF (vsSOMACREDITOCLIPRINCIPAL = 'S') THEN
          SELECT NVL(SUM(LIMCRED), 0) LIMCRED
            INTO vnVLCREDDISPONIVEL
            FROM PCCLIENT
           WHERE PCCLIENT.CODCLI IN
                 (SELECT CODCLI
                    FROM PCCLIENT
                   WHERE CODCLIPRINC =
                         (SELECT NVL(codcliprinc,CODCLI)
                            FROM PCCLIENT
                           WHERE PCCLIENT.CODCLI = VCPEDIDO.CODCLI)
                  UNION ALL
                  SELECT CODCLI
                    FROM PCCLIENT
                   WHERE CODCLI =
                         (SELECT NVL(codcliprinc,CODCLI)
                            FROM PCCLIENT
                           WHERE PCCLIENT.CODCLI = VCPEDIDO.CODCLI)
                     AND CODCLIPRINC IS NULL);
        ELSE
          SELECT LIMCRED
            INTO vnVLCREDDISPONIVEL
            FROM PCCLIENT
           WHERE PCCLIENT.CODCLI = VCPEDIDO.CODCLI;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLCREDDISPONIVEL := 0;
      END;

      BEGIN
        IF vsSOMACREDITOCLIPRINCIPAL = 'S' THEN
           vSQL := 'SELECT NVL(SUM(VALOR), 0)
                      FROM PCPREST
                     WHERE ' || CASE
                    WHEN VSUSABNFLIMITECREDITO = 'N' THEN
                     'CODCOB NOT IN (''BNF'', ''BNFT'', ''BNTR'', ''BNFR'', ''BNRP'') AND'
                  END || '
                       PCPREST.Codcli IN(SELECT CODCLI
                                              FROM PCCLIENT
                                             WHERE CODCLIPRINC = (SELECT NVL(CODCLIPRINC, CODCLI)
                                                                    FROM PCCLIENT
                                                                    WHERE PCCLIENT.CODCLI = '|| VCPEDIDO.CODCLI ||' )
                                            UNION ALL
                                            SELECT CODCLI
                                              FROM PCCLIENT
                                             WHERE CODCLI =
                                                   (SELECT NVL(CODCLIPRINC, CODCLI)
                                                      FROM PCCLIENT
                                                     WHERE PCCLIENT.CODCLI = '|| VCPEDIDO.CODCLI ||' ))
                       AND PCPREST.DTPAG IS NULL';

        ELSE
          vSQL := 'SELECT NVL(SUM(VALOR), 0)
                      FROM PCPREST
                     WHERE ' || CASE
                    WHEN VSUSABNFLIMITECREDITO = 'N' THEN
                     'CODCOB NOT IN (''BNF'', ''BNFT'', ''BNTR'', ''BNFR'', ''BNRP'') AND'
                  END || '
                       PCPREST.Codcli IN(SELECT CODCLI
                                              FROM PCCLIENT
                                             WHERE CODCLI  = '|| VCPEDIDO.CODCLI ||' )
                       AND PCPREST.DTPAG IS NULL';
        END IF;

        EXECUTE IMMEDIATE vSQL
          INTO vnVLCREDCONTASRECEBER;

      EXCEPTION
        WHEN OTHERS THEN
          vnVLCREDCONTASRECEBER := 0;
      END;

      vbNaoVerificaLimCredCodCobD := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICALIMCREDCODCOBD',99,'N') = 'N');

      BEGIN
       vSQL :=  ' SELECT NVL(SUM(ROUND(NVL(VLATEND, 0) - CASE
                               WHEN ((PCPLPAG.TIPOENTRADA = 3) AND
                                    (PCPLPAG.DESCENTLIMCREDCLI = ''S'')) THEN
                                PCPEDC.VLENTRADA
                               ELSE
                                0
                             END,
                             2)),
                   0) VLATEND
          FROM PCPEDC, PCPLPAG
         WHERE DTCANCEL IS NULL
           AND PCPEDC.CONDVENDA NOT IN (8, 13)
           AND PCPEDC.CODPLPAG = PCPLPAG.CODPLPAG
           AND POSICAO IN (''L'', ''M'')
           AND NUMPED <> ' || VCPEDIDO.NUMPED ||  '
           AND PCPEDC.DATA >= SYSDATE - 1183
		       AND PCPEDC.NUMPED >= (SELECT MIN(NUMPED) FROM PCPEDC)';

           IF vsSOMACREDITOCLIPRINCIPAL = 'S' THEN
               vSQL :=  vSQL || '
                AND PCPEDC.CODCLI IN
                   (SELECT CODCLI
                        FROM PCCLIENT
                       WHERE CODCLIPRINC IN
                             (SELECT CODCLIPRINC
                                FROM PCCLIENT
           AND PCPEDC.CODCOB NOT IN ('SUPP')
                               WHERE PCCLIENT.CODCLI = ' || VCPEDIDO.CODCLI || ')
                      UNION ALL
                      SELECT CODCLI
                        FROM PCCLIENT
                       WHERE CODCLI IN
                             (SELECT NVL(codcliprinc,CODCLI)
                                FROM PCCLIENT
                               WHERE PCCLIENT.CODCLI = ' || VCPEDIDO.CODCLI || ')
                         AND CODCLIPRINC IS NULL)';
            else
              vSQL :=  vSQL || ' AND PCPEDC.CODCLI = ' || VCPEDIDO.CODCLI;
            end if;

          EXECUTE IMMEDIATE vSQL
            INTO vnVLCREDPEDFATURAR;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLCREDPEDFATURAR := 0;
      END;

      /*Se o parâmetro 1304 = Sim, não entrará nesta regra e não afetará o cálculo final
      do limite de crédito, pois o valor inicia como 0.
      Se for Não, acrescentará de volta ao Limite de Crédito o valor a faturar das cobranças
      D, DH e Car, para que os pedidos já liberados também não sejam validados,
      igualando a regra da rotina 1203. */

      vnVLCREDPEDFATURAR_D := 0;

      IF vbNaoVerificaLimCredCodCobD THEN
      BEGIN
        vSQL :=  '
        SELECT NVL(SUM(ROUND(NVL(VLATEND, 0) - CASE
                               WHEN ((PCPLPAG.TIPOENTRADA = 3) AND
                                    (PCPLPAG.DESCENTLIMCREDCLI = ''S'')) THEN
                                PCPEDC.VLENTRADA
                               ELSE
                                0
                             END,
                             2)),
                   0) VLATEND
          FROM PCPEDC, PCPLPAG
         WHERE DTCANCEL IS NULL
           AND PCPEDC.CODPLPAG = PCPLPAG.CODPLPAG
           AND POSICAO IN (''L'', ''M'')
           AND NUMPED <> ' || VCPEDIDO.NUMPED || '
           AND PCPEDC.DATA >= SYSDATE - 1183
		       AND PCPEDC.NUMPED >= (SELECT MIN(NUMPED) FROM PCPEDC)
           AND (PCPEDC.CODCOB IN(''D'', ''DH'', ''CAR'')
           AND PCPEDC.CODCOB NOT IN ('SUPP')
                 OR PCPEDC.CODCOB IN(SELECT CODCOB FROM PCCOB WHERE
                 CODCOB = PCPEDC.CODCOB AND NVL(CARTAO,''N'') = ''S''))';

          IF vsSOMACREDITOCLIPRINCIPAL = 'S' THEN
            vSQL := vSQL || '
                 AND PCPEDC.CODCLI IN
                 (SELECT CODCLI
                      FROM PCCLIENT
                     WHERE CODCLIPRINC IN
                           (SELECT CODCLIPRINC
                              FROM PCCLIENT
                             WHERE PCCLIENT.CODCLI = ' || VCPEDIDO.CODCLI || ')
                    UNION ALL
                    SELECT CODCLI
                      FROM PCCLIENT
                     WHERE CODCLI IN
                           (SELECT NVL(codcliprinc,CODCLI)
                              FROM PCCLIENT
                             WHERE PCCLIENT.CODCLI = ' ||VCPEDIDO.CODCLI || ')
                       AND CODCLIPRINC IS NULL)';
            else
              vSQL := vSQL || ' AND PCPEDC.CODCLI = ' || VCPEDIDO.CODCLI;
            end if;

            EXECUTE IMMEDIATE vSQL
                         INTO vnVLCREDPEDFATURAR_D;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLCREDPEDFATURAR_D := 0;
      END;
      END IF;

      BEGIN
        vSQL :=  '

        SELECT NVL(SUM(PCPREST.VALOR), 0)
          FROM PCPREST
         WHERE PCPREST.CODCOB <> ''DESD''
           AND PCPREST.DTPAG IS NOT NULL
           AND NVL(CHEQUETERCEIRO, ''N'') = ''N''
           AND PCPREST.DTCANCEL IS NULL
           AND ((''' || vsCHECARDIASUTEISTITPGNLIB || ''' = ''S'' AND
               FNC_DTFINAL(PCPREST.DTPAG,
                             (SELECT NVL(PCCOB.NUMDIASLIBERACAOCREDITO, 0)
                                FROM PCCOB
                               WHERE PCCOB.CODCOB = PCPREST.CODCOB),
                             ''S'') > TRUNC(SYSDATE)) OR
               (''' || vsCHECARDIASUTEISTITPGNLIB || ''' = ''N'' AND
               PCPREST.DTPAG +
               (SELECT NVL(PCCOB.NUMDIASLIBERACAOCREDITO, 0)
                    FROM PCCOB
                   WHERE PCCOB.CODCOB = PCPREST.CODCOB) > TRUNC(SYSDATE)))
           AND PCPREST.Codcli = ' ||VCPEDIDO.CODCLI || '
           AND PCPREST.DTPAG IS NULL
           ';

           IF vsSOMACREDITOCLIPRINCIPAL = 'S' THEN
              vSQL := vSQL ||
                   ' AND CODCLI IN (SELECT CODCLI
                              FROM PCCLIENT
                             WHERE CODCLIPRINC IN
                                   (SELECT NVL(codcliprinc,CODCLI)
                                      FROM PCCLIENT
                                     WHERE PCCLIENT.CODCLI = ' ||  VCPEDIDO.CODCLI || ')
                            UNION ALL
                            SELECT CODCLI
                              FROM PCCLIENT
                             WHERE CODCLI IN
                                   (SELECT NVL(codcliprinc,CODCLI)
                                      FROM PCCLIENT
                                     WHERE PCCLIENT.CODCLI =' || VCPEDIDO.CODCLI || ')
                               AND CODCLIPRINC IS NULL)';
            else
               vSQL := vSQL || ' AND CODCLI =' ||  VCPEDIDO.CODCLI;
            end if;

             EXECUTE IMMEDIATE vSQL
                         INTO vnVLCREDPEDCHEQUE;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLCREDPEDCHEQUE := 0;
      END;
      BEGIN
        SELECT NVL(VNVLCREDDISPONIVEL * (SUM(PERCAUMENTO) / 100), 0)
          INTO VNVLLIMTCLIENTESAZONAL
          FROM PCLIMCRED
         WHERE PCLIMCRED.CODDCLI = VCPEDIDO.CODCLI
           AND TRUNC(SYSDATE) BETWEEN PCLIMCRED.DTINICIO AND
               PCLIMCRED.DTFIM
           AND ((PCLIMCRED.CODUSUR IS NULL) OR
               (PCLIMCRED.CODUSUR = VCPEDIDO.CODUSUR))
           AND PERCAUMENTO <> 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          VNVLLIMTCLIENTESAZONAL := 0;
      END;

      VNVLLIMTCREDEXTRA := VNVLCREDDISPONIVEL *
                           (FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_PEREXCEDELIMCRED',
                                                              99,
                                                              0) / 100);

      vnVLCREDDISPONIVELTOTAL := (VNVLCREDDISPONIVEL + VNVLLIMTCREDEXTRA + vnVLCREDPEDFATURAR_D -
                                 (vnVLCREDCONTASRECEBER +
                                 vnVLCREDPEDFATURAR + vnVLCREDPEDCHEQUE)) +
                                 VNVLLIMTCLIENTESAZONAL;
      if (VCPEDIDO.DESCENTLIMCREDCLI = 'S') then
        vnVLTOTALPEDIDO := VCPEDIDO.VLATEND - VCPEDIDO.VLENTRADA;
      ELSE
        vnVLTOTALPEDIDO := VCPEDIDO.VLATEND;
      end if;

      begin
        select pcclient.dtvenclimcred
          into vdatavalidadecredito
          from pcclient
         where codcli = vcpedido.codcli;
      exception
        when others then
          vdatavalidadecredito := trunc(sysdate);
      end;

      if vdatavalidadecredito < trunc(sysdate) then
        if (PCODROTINA = 336) and
           not (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 46)) then
          vnVLCREDDISPONIVELTOTAL := 0;
          vsOBSMotivo             := 'Limite de crédito vencido, verifique 1203.';
        elsif (pCODROTINA <> 336) then
          vnVLCREDDISPONIVELTOTAL := 0;
          vsOBSMotivo             := 'Limite de crédito vencido, verifique 1203.';
        end if;
      end if;

      if (PCODROTINA = 336) and
         USUARIOPODEAUTORIZARLIMITE(VCPEDIDO.CODCLI,
                                    pCODFUNC,
                                    vnVLCREDDISPONIVELTOTAL,
                                    VCPEDIDO.VLATEND) then

        IF (vnVLCREDDISPONIVELTOTAL > 0) THEN
          INSERTAUTORC(VCPEDIDO,
                       pCODFUNC,
                       vnVLTOTALPEDIDO - vnVLCREDDISPONIVELTOTAL);
        ELSE
          INSERTAUTORC(VCPEDIDO,
                       pCODFUNC,
                       vnVLTOTALPEDIDO );
        END IF;

      end if;

      --Verifica se o pedido ultrapassou o limit disponivel
      IF (vnVLTOTALPEDIDO > vnVLCREDDISPONIVELTOTAL) and
         (VCPEDIDO.CODCLI NOT IN (1,2,3)) and
         (VCPEDIDO.Condvenda not in (4, 5, 8, 11, 20)) and
          not(((VCPEDIDO.CODCOB = 'D') or
              (VCPEDIDO.CODCOB = 'DH') or
              (VCPEDIDO.CODCOB = 'CAR') or
              (isCobrancaCartao(VCPEDIDO.CodCob))) and
            (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICALIMCREDCODCOBD',99,'N') = 'N'))
       then
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = PCODMOTIVO
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1
             ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       PCODMOTIVO,
                       nvl(vsObsMotivo,
                           'O valor limite de credito foi excedido.  Vl. Ped.: '  || to_char(vnVLTOTALPEDIDO) || ' Cred. Cli.: ' || to_char(vnVLCREDDISPONIVELTOTAL) ),
                       PTIPOMOTIVO);
        ELSE
          UPDATE PCBLOQUEIOSPEDIDO SET MOTIVO = nvl(vsObsMotivo,
                           'O valor limite de credito foi excedido.  Vl. Ped.: '  || to_char(vnVLTOTALPEDIDO) || ' Cred. Cli.: ' || to_char(vnVLCREDDISPONIVELTOTAL) )
                           WHERE CODMOTIVO = PCODMOTIVO
                             AND NUMPED = VCPEDIDO.NUMPED
                             AND CODMOTBLOQUEIO IS NULL;
        END IF;
        --verifica se tem autorização de Limite credito.
        BEGIN
          SELECT numpedido, PCAUTORC.VLLIBERADO
            into vnAUTORIZACAO, vnVlLiberado
            FROM PCAUTORC
            WHERE NVL(PCAUTORC.CODCLI, VCPEDIDO.Codcli) = VCPEDIDO.Codcli
             AND NVL(PCAUTORC.CODUSUR,  VCPEDIDO.Codusur) = VCPEDIDO.Codusur
             /*AND ((CASE WHEN PCAUTORC.NUMPEDLIBERAR > 0 THEN
                    (VNVLTOTALPEDIDO - NVL(PCAUTORC.VLLIBERADO, 0))
                  ELSE
                    VNVLCREDDISPONIVELTOTAL
                  END)*/
             AND (NVL((case
              when VNVLCREDDISPONIVELTOTAL > 0 THEN
               VNVLCREDDISPONIVELTOTAL
              Else
               0
            END),
            0) + NVL(PCAUTORC.VLLIBERADO, 0)) >= VNVLTOTALPEDIDO
             AND ((PCAUTORC.ORIGEMPED = VCPEDIDO.Origemped) OR
                 (PCAUTORC.ORIGEMPED IS NULL))
             --AND NVL(PCAUTORC.NUMPEDLIBERAR, VCPEDIDO.Numped) = VCPEDIDO.Numped
             AND (DECODE(NVL(PCAUTORC.LIBERARPORPEDIDO, 'NH'),
                                'LP',
                                 NVL(PCAUTORC.NUMPEDLIBERAR, 0),-1) =
                         DECODE(NVL(PCAUTORC.LIBERARPORPEDIDO, 'NH'),
                                 'LP',
                                  VCPEDIDO.Numped,
                                  -1))
             AND ((PCAUTORC.DTUTILIZACAO IS NULL
             AND   PCAUTORC.CODFUNCUTILIZACAO IS NULL)
             OR   (PCAUTORC.DTUTILIZACAO IS NOT NULL
             AND   PCAUTORC.CODFUNCUTILIZACAO IS NOT NULL
             AND   PCAUTORC.NUMPEDUTILIZACAO = VCPEDIDO.Numped))
             AND ROWNUM = 1
           ORDER BY DATA;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VNAUTORIZACAO := 0;
        END;
        VNVLCREDDISPONIVELTOTAL := NVL(VNVLCREDDISPONIVELTOTAL,0) + NVL(vnVlLiberado,0);
        IF (VNAUTORIZACAO > 0) THEN
          ATUALIZARPCAUTORC(VCPEDIDO,
                            pCODFUNC,
                            VNAUTORIZACAO,
                            vnVLCREDDISPONIVELTOTAL);
          ALTERASTATUSBLOQUEIO(PCODMOTIVO, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);

        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(PCODMOTIVO, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;

  end validaLimCreditoConvencional;

  procedure validaLimCreditoParceiros(PTIPOMOTIVO VARCHAR,
                                      PCODMOTIVO  NUMBER,
                                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                                      PCODFUNC    IN NUMBER,
                                      PCODROTINA  IN NUMBER) is
    vnLimiteDisponivelParceiro number;
    vnVLTOTALPEDIDO number;
    VNCODIGO number;
  begin

    BEGIN
/*  VEN-1888 - Fernando.Carmo: Corrigido o calculo do limite conforme regras da SuppliCard
   with limiteParceiro as
       (select nvl(pcsupplicliente.limitecreddisponsuppli, 0) limitecreddisponsuppli
          from pcsupplicliente
         where pcsupplicliente.codcli = VCPEDIDO.CODCLI),
      titulosAbertosCobParceiros as
       (SELECT SUM(NVL(VALOR, 0)) VALOR
          FROM PCPREST, PCCOB
         WHERE DTPAG IS NULL
           AND PCPREST.CODCOB = PCCOB.CODCOB
           AND NVL(PCCOB.COBSUPPLIERCARD, 'N') = 'S'
           AND PCPREST.CODCLI = VCPEDIDO.CODCLI),
      pedidosAbertosParceiro as
       (SELECT SUM(ROUND(NVL(VLATEND, 0) - CASE
                           WHEN ((PCPLPAG.TIPOENTRADA = 3) AND
                                (PCPLPAG.DESCENTLIMCREDCLI = 'S')) THEN
                            PCPEDC.VLENTRADA
                           ELSE
                            0
                         END,
                         2)) VLATEND
          FROM PCPEDC, PCPLPAG, PCCOB
         WHERE DTCANCEL IS NULL
           AND PCPLPAG.CODPLPAG = PCPEDC.CODPLPAG
           AND PCPEDC.CODCOB = PCCOB.CODCOB
           AND NVL(PCCOB.COBSUPPLIERCARD, 'N') = 'S'
           AND POSICAO IN ('L', 'M')
           AND PCPEDC.NUMPED <> VCPEDIDO.NUMPED
           AND PCPEDC.CODCLI = VCPEDIDO.CODCLI)
           */
   SELECT (NVL(S.LIMITECOMPRADISPONIVEL, 0) -
           (SELECT NVL(SUM(ROUND(NVL(VLATEND, 0) - CASE WHEN ((PCPLPAG.TIPOENTRADA = 3)
                                                         AND (PCPLPAG.DESCENTLIMCREDCLI = 'S'))
                                                        THEN PCPEDC.VLENTRADA
                                                        ELSE 0
                                                   END, 2)), 0) AS VALOR
             FROM PCPEDC
                , PCPLPAG
            WHERE DTCANCEL IS NULL
              AND PCPLPAG.CODPLPAG = PCPEDC.CODPLPAG
              AND POSICAO IN ('L', 'M')
              AND PCPEDC.CODCOB IN (SELECT CODCOB
                                      FROM PCCOB
                                     WHERE COBSUPPLIERCARD = 'S')
              AND CODCLI = VCPEDIDO.CODCLI
              AND NUMPED <> VCPEDIDO.NUMPED)
                                            - (SELECT NVL(SUM(S.VLTOTAL), 0)
                                                 FROM PCFILASUPPLI F
                                                INNER JOIN PCNFSAID S ON S.NUMTRANSVENDA = F.NUMTRANSVENDA
                                                WHERE TIPOINF = 1
                                                  AND ENVIADOSUPPLI = 'N'
                                                  AND APROVADOSUPPLI IS NULL
                                                  AND S.CODCLI = VCPEDIDO.CODCLI)) as VLRLIMITEDISPONSUPPLI
     INTO vnLimiteDisponivelParceiro
     FROM PCSUPPLICLIENTE S
    WHERE S.CODCLI = VCPEDIDO.CODCLI ;


/* VEN-1888 - Fernando.Carmo: Corrigido o calculo do limite conforme regras da SuppliCard
     select nvl(limiteParceiro.limitecreddisponsuppli,0) -
             (nvl(titulosAbertosCobParceiros.valor,0) +
             nvl(pedidosAbertosParceiro.vlatend,0))
        into vnLimiteDisponivelParceiro
        from limiteParceiro,
             titulosAbertosCobParceiros,
             pedidosAbertosParceiro;
*/
    EXCEPTION
      WHEN OTHERS THEN
          vnLimiteDisponivelParceiro := 0;
    END;

      if (VCPEDIDO.DESCENTLIMCREDCLI = 'S') then
        vnVLTOTALPEDIDO := VCPEDIDO.VLATEND - VCPEDIDO.VLENTRADA;
      ELSE
        vnVLTOTALPEDIDO := VCPEDIDO.VLATEND;
      end if;

     if (vnLimiteDisponivelParceiro < vnVLTOTALPEDIDO) and (VCPEDIDO.CODCLI NOT IN (1,2,3))then

        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = PCODMOTIVO
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       PCODMOTIVO,
                       'Limite de crédito D+Cred excedido',
                       PTIPOMOTIVO);
        END IF;
     else
       ALTERASTATUSBLOQUEIO(PCODMOTIVO, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
     end if;

  end;

  PROCEDURE BLOQUEIOPCBLOQUEIO(PCODFUNC  NUMBER,
                               VCPEDIDO  IN C_PEDIDO%ROWTYPE,
                               VCCLIENTE IN C_CLIENTE%ROWTYPE,
                               PCODROTINA IN NUMBER) IS
    VnCODIGO           PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnPCCONTROBLOQUEIO NUMBER;
    vsTipoBloque       VARCHAR2(1);
  BEGIN

   EXECUTE IMMEDIATE 'ALTER SESSION  SET NLS_NUMERIC_CHARACTERS= ''.,''';

    OPEN C_PCBLOQUEIO(VCPEDIDO.NUMPED,
                      VCPEDIDO.CODCLI,
                      VCPEDIDO.CONDVENDA,
                      VCPEDIDO.CODPRACA,
                      VCPEDIDO.CODPLPAG,
                      PCODFUNC,
                      VCPEDIDO.CODCOB,
                      VCPEDIDO.FRETEDESPACHO,
                      VCPEDIDO.ORIGEMPED,
                      VCCLIENTE.CLIENTEMONITORADO,
                      VCPEDIDO.VLTOTAL,
                      VCPEDIDO.CODFILIAL);
    --Libera os bloqueio desse pedido

    LOOP
      FETCH C_PCBLOQUEIO
        INTO VCPCBLOQUEIO;
      EXIT WHEN C_PCBLOQUEIO%NOTFOUND;
      --Verifica se ja existe pcbloqueio.
      BEGIN
        SELECT CODIGO
          INTO VnCODIGO
          FROM PCBLOQUEIOSPEDIDO
         WHERE CODMOTBLOQUEIO = VCPCBLOQUEIO.CODMOTBLOQUEIO
           AND NUMPED = VCPEDIDO.NUMPED
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          VnCODIGO := 0;
      END;
      IF (VNCODIGO = 0) THEN
        --Se não existir o bloqueio inserido
        IF (VCPCBLOQUEIO.DESCRICAO IS NULL) THEN
          VCPCBLOQUEIO.DESCRICAO := 'Bloqueio Comercial numero: ' ||
                                    VCPCBLOQUEIO.CODMOTBLOQUEIO ||
                                    '.Verifique a rotina 307';
        END IF;
        IF(VCPCBLOQUEIO.CODMOTIVO > 0)THEN
          BEGIN
            SELECT  CASE WHEN (PCMOTBLOQUEIO.TIPO = 1) THEN
                             'F'
                           ELSE
                             'C'
                           END
             INTO VSTIPOBLOQUE
             FROM PCMOTBLOQUEIO
             WHERE PCMOTBLOQUEIO.CODMOTIVO = VCPCBLOQUEIO.CODMOTIVO;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            vsTipoBloque := 'C';
          END;
        ELSE
           vsTipoBloque := 'C';
        END IF;

        INSERTMOTIVO(VCPEDIDO.NUMPED,
                     VCPCBLOQUEIO.CODMOTIVO,
                     VCPCBLOQUEIO.DESCRICAO,
                     vsTipoBloque,
                     VCPCBLOQUEIO.CODMOTBLOQUEIO);
      END IF;

      IF (PCODROTINA = 336) THEN
        BEGIN
          SELECT COUNT(1)
            INTO vnPCCONTROBLOQUEIO
            FROM PCCONTROBLOQUEIO F
           WHERE F.CODMOTBLOQUEIO = VCPCBLOQUEIO.CODMOTBLOQUEIO
             AND F.CODFUNCLIBBLOQ = PCODFUNC;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnPCCONTROBLOQUEIO := 0;
        END;
        IF (VNPCCONTROBLOQUEIO > 0) THEN
          UPDATE PCBLOQUEIOSPEDIDO
             SET STATUS = 'L', DTLIBERA = SYSDATE, CODFUNCLIBERA = PCODFUNC
           WHERE NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO = VCPCBLOQUEIO.CODMOTBLOQUEIO
             AND CODFUNCLIBERA IS NULL
         AND DTLIBERA IS NULL;
        END IF;
      END IF;
    END LOOP;

    IF (C_PCBLOQUEIO%ROWCOUNT <= 0) THEN

      UPDATE PCBLOQUEIOSPEDIDO
         SET STATUS = 'L'
       WHERE NUMPED = VCPEDIDO.NUMPED
         AND CODMOTBLOQUEIO IS NOT NULL;
    END IF;
  END BLOQUEIOPCBLOQUEIO;

  PROCEDURE BLOQUEIOMENOS1(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS
  BEGIN
    --Bloqueios do força de vendas
    IF (PCODMOTIVO = -1) AND (PCODROTINA = 336) THEN
         ALTERASTATUSBLOQUEIO(-1,
                             'L',
                             VCPEDIDO.NUMPED,
                             PCODFUNC,
                             PCODROTINA,
                             PTIPOMOTIVO);
    END IF;
  END BLOQUEIOMENOS1;

  PROCEDURE BLOQUEIO1(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS
    -- Variaveis (codmotivo = 1)
    vsRCABLOQUEADO VARCHAR2(1);
    VnCODIGO       PCBLOQUEIOSPEDIDO.codigo%TYPE;
  BEGIN
    IF (PCODMOTIVO = 1) THEN
      --*O RCA esta bloqueado (codmotivo = 1)
      BEGIN
        SELECT PCUSUARI.BLOQUEIO
          INTO vsRCABLOQUEADO
          FROM PCUSUARI
         WHERE PCUSUARI.Codusur = VCPEDIDO.CODUSUR;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsRCABLOQUEADO := 'N';
      END;

      IF (vsRCABLOQUEADO = 'S') THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 1
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       1,
                       'O RCA esta bloqueado ',
                       PTIPOMOTIVO);
        END IF;
      ELSE
        --VERIFICAR PERMISSAO
        ALTERASTATUSBLOQUEIO(1, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*fim O RCA esta bloqueado (codmotivo = 1)
  END BLOQUEIO1;

  PROCEDURE BLOQUEIO2(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER
                      ) IS
    -- Variaveis (codmotivo = 2)
    vsCLIBLOQUEADO          VARCHAR2(1);
    vnCOUNTCLIREDEBLOQUEADO number;
    VnCODIGO                PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vsClientesRedBloq       VARCHAR2(200);
  BEGIN
    IF (PCODMOTIVO = 2) THEN
      --*O Cliente esta bloqueado (codmotivo = 2)
      BEGIN
        SELECT NVL(PCCLIENT.BLOQUEIO, 'N')
          INTO vsCLIBLOQUEADO
          FROM PCCLIENT
         WHERE PCCLIENT.CODCLI = VCPEDIDO.CODCLI;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsCLIBLOQUEADO := 'N';
      END;

      IF FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICARCLIENTESREDE', '99', 'N') = 'S' THEN

      BEGIN
        SELECT COUNT(1)
          INTO vnCOUNTCLIREDEBLOQUEADO
          FROM PCCLIENT
         WHERE CODCLIPRINC = nvl((select NVL(codcliprinc,CODCLI)
                                       from pcclient
                                      where codcli = VCPEDIDO.Codcli),
                                     -1)
           AND NVL(BLOQUEIO, 'N') = 'S';
         --  AND CODCLI <> NVL(CODCLIPRINC,CODCLI);

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCOUNTCLIREDEBLOQUEADO := 0;
      END;

       IF (vnCOUNTCLIREDEBLOQUEADO > 0) THEN
         vsCLIBLOQUEADO := 'S';

          vsClientesRedBloq := 'Cliente da rede bloqueado:';
          FOR DADOS IN (SELECT CODCLI
                          FROM PCCLIENT
                         WHERE CODCLIPRINC = NVL((SELECT NVL(codcliprinc,CODCLI)
                                                    FROM PCCLIENT
                                                   WHERE CODCLI = VCPEDIDO.CODCLI), -1)
                           AND NVL(BLOQUEIO, 'N') = 'S')
          LOOP
            vsClientesRedBloq := substr((vsClientesRedBloq || ' ' || DADOS.CODCLI || ','), 1, 199);
          END LOOP;

          vsClientesRedBloq   := substr(vsClientesRedBloq,1,length(vsClientesRedBloq) - 1);
        END IF;

      END IF;

      /*
      Autor     : Rafael Braga
      Tarefa    : 2882.130753.2016
      Data      : 21/11/2016
      Descrição : Validando parâmetro ACEITAVENDAAVISTACLIBLOQ caso seja venda a vista.
      */
      if (vsCLIBLOQUEADO = 'S') and ((VCPEDIDO.CODCOB IN ('D', 'DH', 'CAR')) OR
         isCobrancaCartao(VCPEDIDO.CODCOB)) AND
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICALIMCREDCODCOBD',
                                             '99',
                                             'N') = 'N')AND
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('ACEITAVENDAAVISTACLIBLOQ',
                                             VCPEDIDO.CODFILIAL,
                                             'N') = 'S') then
        vsCLIBLOQUEADO := 'N';
      end if;

      IF (vsCLIBLOQUEADO = 'S') THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 2
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       2,
                       CASE WHEN (vsClientesRedBloq is NULL) THEN
                         'O Cliente esta bloqueado. '
                       ELSE
                         vsClientesRedBloq
                       END,
                       PTIPOMOTIVO);
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(2, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*FIM O Cliente esta bloqueado (codmotivo = 2)
  END BLOQUEIO2;

  PROCEDURE BLOQUEIO3(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS

--    vsCLIENTEMAISNEGOCIOS PCCLIENT.CLIENTEMAISNEGOCIOS%TYPE;
  BEGIN
    IF VCPEDIDO.CONDVENDA IN('8','13') THEN
      RETURN;
    END IF;  
    IF (PCODMOTIVO = 3) THEN
      --*O valor limite de credito excedido(codmotivo = 3)
      IF (NVL(VCPEDIDO.COBSUPPLIERCARD,'N') = 'N') OR
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('EMPRESATRABALHACOMSUPPLIERCARD',
                                                VCPEDIDO.CODFILIAL,
                                                'N') = 'N') THEN
/*
        BEGIN
          SELECT NVL(PCCLIENT.CLIENTEMAISNEGOCIOS,'N')
            INTO vsCLIENTEMAISNEGOCIOS
            FROM PCCLIENT
           WHERE PCCLIENT.CODCLI = vcPEDIDO.CODCLI;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsCLIENTEMAISNEGOCIOS := 'N';
        END;
*/
        IF (vcPEDIDO.CODCOB <> 'SUPP') THEN
          validaLimCreditoConvencional(pTipoMotivo,
                                       3,
                                       vcPedido,
                                       pCodfunc,
                                       pCodrotina);
        END IF;
      END IF;

    END IF;
    --*fim O valor limite de credito excedido(codmotivo = 3)
  END BLOQUEIO3;

  PROCEDURE BLOQUEIO4(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS
    VnCODIGO PCBLOQUEIOSPEDIDO.codigo%TYPE;
    VnVlMaxVenda PCPEDC.VLTOTAL%TYPE;
    VnVlMaxVendaBNF PCPEDC.VLTOTAL%TYPE;
  BEGIN
    VnVlMaxVenda    := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_VLMAXVENDA', '99', 0);
    VnVlMaxVendaBNF := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_VLMAXVENDABNF', '99', 0);
    IF (PCODMOTIVO = 4) THEN
      --O Valor do pedido execede ao maximo permitido (codmotivo = 4)
      IF ((VnVlMaxVenda <
         VCPEDIDO.VLATEND AND
         VnVlMaxVenda > 0) AND
         VCPEDIDO.CONDVENDA NOT IN('5','20')) THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 4
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       4,
                       'O Valor do pedido excede o máximo permitido(parâmetro 1309)',
                       PTIPOMOTIVO);
        END IF;

        IF (PCODROTINA = 336) THEN
             ALTERASTATUSBLOQUEIO(4, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
        END IF;
      ELSE
        IF (VnVlMaxVendaBNF <
           VCPEDIDO.VLTOTAL AND
           VnVlMaxVendaBNF > 0) and
           (VCPEDIDO.CONDVENDA = 5) THEN
          BEGIN
            SELECT CODIGO
              INTO VnCODIGO
              FROM PCBLOQUEIOSPEDIDO
             WHERE CODMOTIVO = 4
               AND NUMPED = VCPEDIDO.NUMPED
               AND CODMOTBLOQUEIO IS NULL
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VnCODIGO := 0;
          END;
          IF (VNCODIGO = 0) THEN
            INSERTMOTIVO(VCPEDIDO.NUMPED,
                         4,
                         'O Valor do pedido BNF execede ao maximo permitido(parametro 1309)',
                         PTIPOMOTIVO);
          END IF;

        --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
        IF (PCODROTINA = 336) THEN
            IF (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 37)) THEN
              ALTERASTATUSBLOQUEIO(4, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;
        END IF;
        ELSE
          ALTERASTATUSBLOQUEIO(4, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
        END IF;
      END IF;
    END IF;
    --*FIM O Valor do pedido execede ao maximo permitido (codmotivo = 4)
  END BLOQUEIO4;

PROCEDURE BLOQUEIO5(PTIPOMOTIVO VARCHAR,
                    PCODMOTIVO  IN NUMBER,
                    VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                    PCODFUNC    IN NUMBER,
                    PCODROTINA  IN NUMBER) IS
BEGIN
  --Preço abaixo do mínimo permitido
  IF (PCODMOTIVO = 5) THEN
    --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
    IF (PCODROTINA = 336) THEN
      IF NOT (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 39)) THEN
        ALTERASTATUSBLOQUEIO(5,
                             'L',
                             VCPEDIDO.NUMPED,
                             PCODFUNC,
                             PCODROTINA,
                             PTIPOMOTIVO);
      END IF;
    END IF;
  END IF;

END BLOQUEIO5;

  PROCEDURE BLOQUEIO7(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS

    VnCODIGO PCBLOQUEIOSPEDIDO.codigo%TYPE;
  BEGIN
    IF (PCODMOTIVO = 7) THEN
      --*O pedido for bonificado (codmotivo 7)
      IF VCPEDIDO.CONDVENDA IN ('5', '6', '11', '12') AND
         (VCPEDIDO.ORIGEMPED IN ('T', 'F') OR
         (VCPEDIDO.ORIGEMPED IN ('C') AND VCPEDIDO.TIPOOPER in('T', 'A', 'P'))) AND
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BLOQUEARPEDBONIFIC',
                                             '99',
                                             'N') = 'S') THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 7
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       7,
                       'Bloqueio de Pedidos bonificado',
                       PTIPOMOTIVO);
        END IF;
      ELSE
        --VERIFICAR PERMISSAO
        ALTERASTATUSBLOQUEIO(7, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
      --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
      IF (PCODROTINA = 336) THEN
        IF VCPEDIDO.CONDVENDA IN ('5') THEN
          IF (NOT (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 26))) THEN
            ALTERASTATUSBLOQUEIO(7, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
          END IF;
        ELSE
          IF (VCPEDIDO.CONDVENDA IN ('11')) THEN
            IF (NOT (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 27))) THEN
              ALTERASTATUSBLOQUEIO(7, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
    --*FIM  O pedido for bonificado (codmotivo 7)
  END BLOQUEIO7;

  PROCEDURE BLOQUEIO8(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER
                      ) IS

    VnCODIGO        PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnVLVENDAMINPED NUMBER;
  BEGIN
    IF (PCODMOTIVO = 8) THEN
      BEGIN
        SELECT VLVENDAMINPED
          INTO vnVLVENDAMINPED
          FROM PCUSUARI
         WHERE CODUSUR = VCPEDIDO.CODUSUR;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLVENDAMINPED := 0;
      END;
      --*O valor do pedido abaixo de valor minimo por RCA (codmotivo 8)

      IF (VCPEDIDO.CONDVENDA NOT IN ('5','8','11','20') AND
         (VCPEDIDO.VLATEND < vnVLVENDAMINPED) AND (vnVLVENDAMINPED > 0)) THEN
        --Verifica se for balcao ou balcao reserva se o parametro 2326 esta como 's'.
        IF (VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) not in ('R', 'B')) or
           ((VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) in ('R', 'B')) AND
           FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDAVLMINVENDABALCAO',
                                                VCPEDIDO.CODFILIAL,
                                                'N') = 'S') THEN
          BEGIN
            SELECT CODIGO
              INTO VnCODIGO
              FROM PCBLOQUEIOSPEDIDO
             WHERE CODMOTIVO = 8
               AND NUMPED = VCPEDIDO.NUMPED
               AND CODMOTBLOQUEIO IS NULL
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VnCODIGO := 0;
          END;
          IF (VNCODIGO = 0) THEN
            INSERTMOTIVO(VCPEDIDO.NUMPED,
                         8,
                         'O valor do pedido está abaixo de valor minímo por RCA',
                         PTIPOMOTIVO);
          END IF;
        ELSE
          ALTERASTATUSBLOQUEIO(8, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(8, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*O valor do pedido abaixo de valor minimo por RCA (codmotivo 8)
  END BLOQUEIO8;

  PROCEDURE BLOQUEIO9(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER
                      ) IS

    VnCODIGO      PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnVLMINPEDIDO NUMBER;
  BEGIN
    IF (PCODMOTIVO = 9) THEN
      BEGIN
        SELECT NVL(VLMINPEDIDO,0)
          INTO vnVLMINPEDIDO
          FROM PCCOB
         WHERE CODCOB = VCPEDIDO.CODCOB;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLMINPEDIDO := 0;
      END;
      --*O valor do pedido abaixo do valor mínimo por cobrança (codmotivo 9)

      IF (VCPEDIDO.CONDVENDA NOT IN ('5', '11', '4', '8', '13', '20') AND
         (VCPEDIDO.VLATEND < vnVLMINPEDIDO) AND (vnVLMINPEDIDO > 0) AND
         ((VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) not in ('R', 'B')) or
           ((VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) in ('R', 'B')) AND
           FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDAVLMINVENDABALCAO',
                                                VCPEDIDO.CODFILIAL,
                                                'N') = 'S')))  THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 9
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       9,
                       'O valor do pedido está abaixo do valor mínimo da cobrança',
                       PTIPOMOTIVO);
        END IF;
        --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
        IF (PCODROTINA = 336) THEN
            IF ((FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 34))) THEN
              ALTERASTATUSBLOQUEIO(9, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(9, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*O valor do pedido abaixo do valor mínimo por cobrança (codmotivo 9)
  END BLOQUEIO9;

  PROCEDURE BLOQUEIO10(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS

    VnCODIGO      PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnVLMINPEDIDO NUMBER;
  BEGIN
    IF (PCODMOTIVO = 10) THEN
      BEGIN
        SELECT NVL(VLMINPEDIDO,0)
          INTO vnVLMINPEDIDO
          FROM PCPLPAG
         WHERE CODPLPAG = VCPEDIDO.CODPLPAG;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnVLMINPEDIDO := 0;
      END;
      --*O valor do pedido abaixo do valor mínimo por plano de pagamento (codmotivo 10)

      IF (VCPEDIDO.CONDVENDA NOT IN ('5', '11', '4', '8', '13', '20','10') AND
         (VCPEDIDO.VLATEND < vnVLMINPEDIDO) AND (vnVLMINPEDIDO > 0) AND
         ((VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) not in ('R', 'B')) or
           ((VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) in ('R', 'B')) AND
           FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDAVLMINVENDABALCAO',
                                                VCPEDIDO.CODFILIAL,
                                                'N') = 'S')))  THEN

        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 10
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       10,
                       'O valor do pedido abaixo do valor mínimo do plano',
                       PTIPOMOTIVO);
        END IF;

        --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
        IF (PCODROTINA = 336) THEN
            IF ((FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 33))) THEN
              ALTERASTATUSBLOQUEIO(10, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(10, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*O valor do pedido abaixo do valor mínimo por plano de pagamento  (codmotivo 10)
  END BLOQUEIO10;

  PROCEDURE BLOQUEIO11(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS

    VnCODIGO           PCBLOQUEIOSPEDIDO.codigo%TYPE;
    VLMINPEDIDO        number;
    vnVLPEDIDO         number;
    vbVALIDAVLMINBALCAO boolean;
  BEGIN
    IF (PCODMOTIVO = 11) THEN

      vbVALIDAVLMINBALCAO := (NVL(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDAVLMINVENDABALCAO', VCPEDIDO.CODFILIAL, 'N'), FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VALIDAVLMINVENDABALCAO', '99', 'N')) = 'S');

      if (VCPEDIDO.CONDVENDA NOT IN ('4', '10', '5', '11', '4', '8', '13', '20')) then

        VLMINPEDIDO := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('VLMINVENDA',
                                                         VCPEDIDO.CODFILIAL,
                                                         0);

        if VLMINPEDIDO = 0 then

          VLMINPEDIDO := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_VLMINVENDA',
                                                           '99',
                                                           0);
        end if;

        vnVLPEDIDO := VCPEDIDO.Vlatend;

      elsif VCPEDIDO.CONDVENDA = 5 then

         vnVLPEDIDO := VCPEDIDO.Vltotal;

        if VCPEDIDO.OrigemPed = 'F' then

          VLMINPEDIDO := greatest(FERRAMENTAS.F_BUSCARPARAMETRO_NUM('VLMINVENDABNFFV',
                                                                    VCPEDIDO.CODFILIAL,
                                                                    0),
                                  FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_VLMINVENDABNF',
                                                                    '99',
                                                                    0));
        else
          VLMINPEDIDO := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_VLMINVENDABNF',
                                                           '99',
                                                           0);
        end if;
      ELSE
        ALTERASTATUSBLOQUEIO(11, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      end if;

      --*O valor do pedido abaixo do valor minimo por parametro 132 (codmotivo 11)

      IF (VCPEDIDO.CONDVENDA NOT IN ('11', '4', '8', '13', '20') AND
         (vnVLPEDIDO < VLMINPEDIDO) and (VLMINPEDIDO > 0)) and
         ((VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) in ('B', 'R')) and (vbVALIDAVLMINBALCAO)
         or (VENDAS.getORIGEMPEDIDO(VCPEDIDO.NUMPED) not in ('B', 'R'))) THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 11
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       11,
                       'O valor do pedido abaixo do valor minímo por parametro 132',
                       PTIPOMOTIVO);
        END IF;

        /*libera o pedido de acordo com as permissões*/
        IF (PCODROTINA = 336) THEN
          IF VCPEDIDO.CONDVENDA IN ('5') THEN
            IF ((FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 36))) THEN
              ALTERASTATUSBLOQUEIO(11, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;
          ELSE
            IF ((FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 102))) THEN
              ALTERASTATUSBLOQUEIO(11, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;
          END IF;
        END IF;

      ELSE
        ALTERASTATUSBLOQUEIO(11, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*O valor do pedido abaixo do valor minimo por parametro 132(codmotivo 11)
  END BLOQUEIO11;

  PROCEDURE BLOQUEIO13(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       VCCLIENT    IN C_CLIENTE%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS

    vsNAOVALIDAPRAZOMEDIO varchar2(1);
    vsBLOQPRAZOMDVENDA    varchar2(1);
    VnCODIGO              PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnPrazoCli            NUMBER;
    vnPrazoPED            NUMBER;
    VFORMAPARCELAMENTO    VARCHAR2(1);
    VNUMDIAS              NUMBER;
    vnPrazoMedPCClient       NUMBER;
    vsUTILIZAPRAZOMEDIOPLPAG VARCHAR2(1);
  BEGIN
    IF (PCODMOTIVO = 13) THEN

      --*Prazo médio do plano de pagamento superior ao prazo médio do cliente  (codmotivo 13)
      BEGIN
        SELECT NVL(NAOVALIDAPRAZOMEDIO, 'N')
          INTO vsNAOVALIDAPRAZOMEDIO
          FROM PCCOB
         WHERE codcob = VCPEDIDO.Codcob;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsNAOVALIDAPRAZOMEDIO := 'N';
      END;

      BEGIN
         SELECT NVL(PCPLPAG.NUMDIAS,0), NVL(PRAZOMEDIOPLPAG,0), NVL(UTILIZAPRAZOMEDIOPLPAG, 'S')
          INTO vnPrazoCli, vnPrazoMedPCClient, vsUTILIZAPRAZOMEDIOPLPAG
          FROM PCCLIENT,PCPLPAG
         WHERE PCCLIENT.codcli = VCPEDIDO.codcli
           AND PCPLPAG.codplpag = PCCLIENT.Codplpag;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnPrazoCli := 0;
      END;

      vsBLOQPRAZOMDVENDA := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BLOQPRAZOMDVENDA', '99', 'N');

      IF(vnPrazoCli = 0) and (NVL(VCCLIENT.codplpag,0) <> 0) THEN
      BEGIN
                    SELECT NVL(FORMAPARCELAMENTO,'C'),NVL(NUMDIAS,0)
                    INTO VFORMAPARCELAMENTO,VNUMDIAS
                    FROM PCPLPAG
                    WHERE CODPLPAG = VCCLIENT.CODPLPAG;
                    Exception
                    when others then
                      VFORMAPARCELAMENTO := '';
                      VNUMDIAS := 0;
                  end;

                    IF VFORMAPARCELAMENTO = 'T' THEN
                       vnPrazoCli := FATURAMENTO.retorna_prazomedido_plpagfixo(VCCLIENT.codplpag);
                    ELSE
                        vnPrazoCli := VNUMDIAS;
                    END IF;

                    VFORMAPARCELAMENTO := '';
                    VNUMDIAS := 0;

                    SELECT NVL(FORMAPARCELAMENTO,'C'),NVL(NUMDIAS,0)
                    INTO VFORMAPARCELAMENTO,VNUMDIAS
                    FROM PCPLPAG
                    WHERE CODPLPAG = VCPEDIDO.CODPLPAG;

                    IF VFORMAPARCELAMENTO = 'T' THEN
                       vnPrazoPED := FATURAMENTO.retorna_prazomedido_plpagfixo(VCPEDIDO.codplpag);
                    ELSE
                        vnPrazoPED := VNUMDIAS;
                    END IF;

     else
       vnPrazoPED :=   VCPEDIDO.Prazomedio;
     end if;

       IF (PCODROTINA = 336 and
           NOT (FUNC_TEMPERMISSAO(336, PCODFUNC, 100)))  THEN
         ALTERASTATUSBLOQUEIO(13, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
       ELSE
         IF (((vnPrazoCli < VCPEDIDO.prazomedio and
             vnPrazoCli > 0) or
             (vnPrazoMedPCClient > 0 and
             vnPrazoMedPCClient < VCPEDIDO.prazomedio and
             vsUTILIZAPRAZOMEDIOPLPAG = 'S')) and
             (vsNAOVALIDAPRAZOMEDIO = 'N') AND
             (NOT (FUNC_TEMPERMISSAO(316, PCODFUNC, 49))) and  /*--permissao 49 sendo validada pelas duas rotinas*/
             (vsBLOQPRAZOMDVENDA = 'S')) THEN
          BEGIN
            SELECT CODIGO
              INTO VnCODIGO
              FROM PCBLOQUEIOSPEDIDO
             WHERE CODMOTIVO = 13
               AND NUMPED = VCPEDIDO.NUMPED
               AND CODMOTBLOQUEIO IS NULL
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VnCODIGO := 0;
          END;

          IF (VNCODIGO = 0) THEN
            INSERTMOTIVO(VCPEDIDO.NUMPED,
                         13,
                         'Prazo médio do plano é superior ao prazo médio do cliente',
                         PTIPOMOTIVO);
          END IF;
        ELSE
          ALTERASTATUSBLOQUEIO(13, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
        END IF;
      END IF;

    END IF;
    --*Prazo médio do plano de pagamento superior ao prazo médio do cliente (codmotivo 13)
  END BLOQUEIO13;

  PROCEDURE BLOQUEIO14(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       VCCLIENT    IN C_CLIENTE%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS

    VnCODIGO PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vbTemPermissao boolean;
  BEGIN

    IF (PCODMOTIVO = 14) and (PCODROTINA = 336) THEN
      case pTipoMotivo
        when 'C' then
         vbTemPermissao := FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 24);
        when 'F' then
          vbTemPermissao := FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 25);
        end case;
       else
         vbTemPermissao := false;
    end if;

      --*Frete despacho do pedido difere do cadastro para o cliente (codmotivo = 14)
      IF (VCPEDIDO.FRETEDESPACHO <> VCCLIENT.FRETEDESPACHO AND
         VCCLIENT.FRETEDESPACHO NOT IN ('C', 'N')) and (not vbTemPermissao)  THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 14
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       14,
                       'Frete despacho do pedido difere do cliente',
                       PTIPOMOTIVO);
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(14, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
--    END IF;
    --*Frete despacho do pedido difere do cadastro para o cliente (codmotivo = 14)
  END BLOQUEIO14;

  PROCEDURE BLOQUEIO15(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER
                       ) IS

    VnCODIGO           PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vsVLMINVENDABK     NUMBER;
    vsTIPOVLMINVENDABK VARCHAR(2);
    vnTOTALPEDIDO      NUMBER;
    vnNUMPARCELAS      NUMBER;
    vsBOLETO           VARCHAR(1);
  BEGIN
    IF ((PCODMOTIVO = 15) and (VCPEDIDO.ORIGEMPED <> 'K') and VCPEDIDO.VLATEND > 0) THEN

      vnTOTALPEDIDO := VCPEDIDO.VLATEND;
      --*Pedido com cobrança boleto (BK) com valor abaixo do mínimo (codmotivo= 15)

      vsVLMINVENDABK := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('VLMINVENDABKFILIAL',
                                                              VCPEDIDO.CODFILIAL,
                                                              0);
      if vsVLMINVENDABK = 0 then
        vsVLMINVENDABK     := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_VLMINVENDABK',
                                                                '99',
                                                                0);
      end if;

      vsTIPOVLMINVENDABK := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TIPOVLMINVENDABK',
                                                               '99',
                                                               'VT');

      vnNUMPARCELAS := FUNC_CALCULANUMPARCPLPAG(vcpedido.codplpag);

      IF (vnNUMPARCELAS > 0) and (vsTIPOVLMINVENDABK = 'VP') THEN
        vnTOTALPEDIDO := vnTOTALPEDIDO / vnNUMPARCELAS;
      END IF;

      BEGIN
        SELECT BOLETO
          INTO vsBOLETO
          FROM PCCOB
         WHERE CODCOB = VCPEDIDO.CODCOB;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsBOLETO := 'N';
      END;

      IF (vnTOTALPEDIDO < vsVLMINVENDABK) and
         ((VCPEDIDO.CODCOB = 'BK') or (vsBOLETO = 'S')) THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 15
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       15,
                       'Pedido com cobrança boleto (BK) com valor abaixo do mínimo',
                       PTIPOMOTIVO);
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(15, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*Pedido com cobrança boleto (BK) com valor abaixo do mínimo (codmotivo= 15)
  END BLOQUEIO15;

  PROCEDURE BLOQUEIO16(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER,
                       PMATRICULAAUTORIZADOR IN NUMBER default 0) IS
    VnCODIGO   PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnPerLucro Number;
    viNumPermissao integer;
    viMatricula integer;
      vCodRotina integer;
  BEGIN
    IF (PCODMOTIVO = 16) THEN

       --Na VEN-5035 foi alterado na 336 o Ultimo parametro para 0, pois a função BLOQUEIO05
       --libera os motivos 5 quando a rotina é a 336, mas não pode fazer isso quando se altera um item, por exemplo.
       --com isso ocorreu um erro no BLOQUEIO16, o usuario tinha permissão e o sistema validava com NÃO.
      if (PCODROTINA = 0 )  then
         vCodRotina := 336;
      else
         vCodRotina :=  PCODROTINA ;
      end if;

    case vCodRotina
      when 316 then viNumPermissao := 20;
      when 336 then viNumPermissao := 7;
    else
      viNumPermissao :=  20;
    end case;

    if PMATRICULAAUTORIZADOR > 0 then
       viMatricula := PMATRICULAAUTORIZADOR;
    else
       viMatricula := PCODFUNC;
    end if;

      --*Margem de lucro abaixo do mínimo permitido para o plano pgto (codmotivo=16)
    if VCPEDIDO.VLATEND > 0 then
      vnPerLucro := ROUND(((VCPEDIDO.VLATEND - VCPEDIDO.Vlcustofin) /
                          VCPEDIDO.VLATEND) * 100,
                          2);
    else
      vnPerLucro := 0;
    end if;

      IF (vnPerLucro < VCPEDIDO.MARGEMMIN) AND
        (NOT (FUNC_TEMPERMISSAO(vCodRotina, viMatricula, viNumPermissao))) AND (VCPEDIDO.MARGEMMIN > 0) and (VCPEDIDO.Condvenda <> (5)) THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 16
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       16,
                       'Margem de lucro abaixo do mínimo permitido no plano pgto',
                       PTIPOMOTIVO);
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(16, 'L', VCPEDIDO.NUMPED, PCODFUNC, vCodRotina, PTIPOMOTIVO);
      END IF;
    END IF;
    --*Margem de lucro abaixo do mínimo permitido para o plano pgto (codmotivo=16)
  END BLOQUEIO16;

  PROCEDURE BLOQUEIO17(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       VCCLIENTE   IN C_CLIENTE%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER
                       ) IS

    VnCODIGO PCBLOQUEIOSPEDIDO.codigo%TYPE;
  BEGIN
    IF (PCODMOTIVO = 17) THEN
     IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZACONTROLEMEDICAMENTOS',
                                           VCPEDIDO.Codfilial,
                                           'N') = 'S') THEN
      --*Pedido de cliente com alvará vencido (codmotivo = 17)
      IF (( /*Alvara*/
          (VCCLIENTE.DTVENCALVARA < SYSDATE) And
          (VCCLIENTE.DTVENCALVARA IS NOT NULL) and
          (FUNC_EXISTEITEMPSICOTROPICO(VCPEDIDO.NUMPED, 'P'))) OR
         ( /*Alvará Funcionário*/
          (VCCLIENTE.DTVENCALVARAFUNC < SYSDATE) And
          (VCCLIENTE.DTVENCALVARAFUNC IS NOT NULL) AND
          (FUNC_EXISTEITEMPSICOTROPICO(VCPEDIDO.NUMPED, 'M'))) OR
         ( /*Alvará Sus*/
          (VCCLIENTE.DTVENCALVARASUS < SYSDATE) And
          (VCCLIENTE.DTVENCALVARASUS IS NOT NULL) AND
          (FUNC_EXISTEITEMPSICOTROPICO(VCPEDIDO.NUMPED, 'M'))) OR
         ( /*Alvará Anvisa*/
          (VCCLIENTE.DTVENCALVARAANVISA < SYSDATE) And
          (VCCLIENTE.DTVENCALVARAANVISA IS NOT NULL) AND
          (FUNC_EXISTEITEMPSICOTROPICO(VCPEDIDO.NUMPED, 'M')))) THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 17
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       17,
                        'Pedido com alvará vencido.',
                       PTIPOMOTIVO);
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(17, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;

     ELSE
       ALTERASTATUSBLOQUEIO(17, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
     END IF;

    END IF;
    --*FIM Pedido de cliente com alvará vencido (codmotivo = 17)
  END BLOQUEIO17;

  PROCEDURE BLOQUEIO18(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS

    VnCODIGO       PCBLOQUEIOSPEDIDO.codigo%TYPE;
    vnTOTALBONIFIC NUMBER;
  BEGIN
    IF (PCODMOTIVO = 18) THEN
      --*Pedido de venda com itens bonificado e não tiver permissão(CODMOTIVO = 18)
      BEGIN
        SELECT SUM(PBONIFIC * QT)
          INTO vnTOTALBONIFIC
          FROM PCPEDI
         WHERE NUMPED = VCPEDIDO.NUMPED
           AND BONIFIC IN ('S', 'F');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnTOTALBONIFIC := 0;
      END;

      IF (((VCPEDIDO.ORIGEMPED = 'T') AND
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('BLOQUEARTV1BNF', '99', 'N') = 'S')) OR
         ((VCPEDIDO.ORIGEMPED = 'F') AND
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('BLOQUEARTV1BNFFV', '99', 'N') = 'S'))) AND
         (vnTOTALBONIFIC > 0) THEN
        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = 18
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       18,
                       'Pedido TV1 com itens BNF bloqueado conforme parametrização',
                       PTIPOMOTIVO);
        END IF;

        --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
        IF (PCODROTINA = 336) THEN
          IF (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 70)) THEN
            ALTERASTATUSBLOQUEIO(18, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
          END IF;
        END IF;
      ELSE
        ALTERASTATUSBLOQUEIO(18, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
    --*FIM Pedido de venda com itens bonificado e não tiver permissão(CODMOTIVO = 18)
  END BLOQUEIO18;

  PROCEDURE BLOQUEIO20(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS
  BEGIN
    --Bloqueios do força de vendas
    IF (PCODMOTIVO = 20) AND (PCODROTINA = 336) THEN
      ALTERASTATUSBLOQUEIO(20,
                           'L',
                           VCPEDIDO.NUMPED,
                           PCODFUNC,
                           PCODROTINA,
                           PTIPOMOTIVO);
    END IF;

  END BLOQUEIO20;

  PROCEDURE BLOQUEIO21(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS

    VnCODIGO        PCBLOQUEIOSPEDIDO.codigo%TYPE;
    VNPERCLUCRO     NUMBER;
    VnMargemMin     PCPEDC.VLTOTAL%TYPE;

  BEGIN
    IF (PCODMOTIVO = 21) THEN
        if (VCPEDIDO.Condvenda = 1) AND (VCPEDIDO.ORIGEMPED NOT IN ('B', 'R')) then
          --*Valida Margem minima lucro do pedido

          begin
            SELECT ((((TOTALVENDA - TOTALBONIFIC) - CUSTOFIN) /
                   (TOTALVENDA - TOTALBONIFIC)) * 100)
              INTO VNPERCLUCRO
              FROM DUAL,
                   (SELECT NVL(SUM(VLCUSTOFIN * QT), 0) CUSTOFIN,
                           NVL(SUM(PVENDA * QT), 0) TOTALVENDA,
                           NVL(SUM(DECODE(PCPEDI.BONIFIC,
                                          'F',
                                          PBONIFIC * QT,
                                          'S',
                                          PBONIFIC * QT,
                                          0)),
                               0) TOTALBONIFIC
                      FROM PCPEDI
                     WHERE NUMPED = VCPEDIDO.NUMPED) PEDIDO;
          exception
            when others then
              VNPERCLUCRO := 0;
          end;

          VnMargemMin := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_MARGEMMIN', '99', 0);
          IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICAMARGEMLIBPEDIDO',
                                                 '99',
                                                 'N') = 'S' AND
             VNPERCLUCRO < VnMargemMin AND
             VnMargemMin <> 0)
             AND VCPEDIDO.Condvenda <> (5) THEN
            BEGIN
              SELECT CODIGO
                INTO VnCODIGO
                FROM PCBLOQUEIOSPEDIDO
               WHERE CODMOTIVO = 21
                 AND NUMPED = VCPEDIDO.NUMPED
                 AND CODMOTBLOQUEIO IS NULL
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                VnCODIGO := 0;
            END;
            IF (VNCODIGO = 0) THEN
              INSERTMOTIVO(VCPEDIDO.NUMPED,
                           21,
                           'Pedido com % de Lucrativade menor que o permitido',
                           PTIPOMOTIVO);
            END IF;
            --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
            IF (PCODROTINA = 336) THEN
              IF (FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 80)) THEN
                ALTERASTATUSBLOQUEIO(21, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
              END IF;
            END IF;
          ELSE
            ALTERASTATUSBLOQUEIO(21, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
          END IF;
        END IF;
      END IF;
  END BLOQUEIO21;

 PROCEDURE BLOQUEIO22(PTIPOMOTIVO VARCHAR,
                      PCODMOTIVO  IN NUMBER,
                      VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                      PCODFUNC    IN NUMBER,
                      PCODROTINA  IN NUMBER) IS
      VnCODIGO    PCBLOQUEIOSPEDIDO.codigo%TYPE;
  vnvlcorrente number;
  vnvllimcred  number;
  vnSALDOPEDIDO number;
  vsMSG varchar2(1000);

  BEGIN
    IF (PCODMOTIVO = 22) and
       (VCPEDIDO.ORIGEMPED = 'F') and
       (PC_PKG_CONTROLARSALDORCA.CONTROLASALDORCA(VCPEDIDO.NUMPED, vsMSG) = 'S') THEN

        --*Pedido do força sem saldo CC do RCA
       select vlcorrente, vllimcred
         into vnvlcorrente, vnvllimcred
         from pcusuari
        where codusur = vcpedido.codusur;

       SELECT SUM(( DECODE(NVL(PCPEDI.BONIFIC, 'N'),
                        'N',
                        NVL(PCPEDI.PVENDA, 0),
                        decode(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BONIFICALTDEBCREDRCA',
                                                                  '99',
                                                                  'N'),
                               'S',
                               0,
                               NVL(PCPEDI.PBASERCA, PCPEDI.PTABELA))
                        ) - NVL(PCPEDI.PBASERCA, PCPEDI.PTABELA)
                        ) * NVL(PCPEDI.QT, 0))
         into vnSALDOPEDIDO
         FROM PCPEDI
        WHERE PCPEDI.NUMPED = VCPEDIDO.numped;

        IF (vnSALDOPEDIDO < 0) and (vnvlcorrente + vnvllimcred + (vnSALDOPEDIDO*-1)) < 0 THEN
          BEGIN
            SELECT CODIGO
              INTO VnCODIGO
              FROM PCBLOQUEIOSPEDIDO
             WHERE CODMOTIVO = 22
               AND NUMPED = VCPEDIDO.NUMPED
               AND ROWNUM = 1
               AND CODMOTBLOQUEIO IS NULL;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VnCODIGO := 0;
          END;

          IF (VNCODIGO = 0) THEN
            INSERTMOTIVO(VCPEDIDO.NUMPED,
                         22,
                         'RCA sem saldo de conta corrente disponível',
                         PTIPOMOTIVO);
          END IF;

          --LIBERA BLOQUEIO DE ACORDO COM AS PERMISSOES.
          IF (PCODROTINA = 336) THEN
            IF (NOT FUNC_TEMPERMISSAO(PCODROTINA, PCODFUNC, 38)) THEN
              ALTERASTATUSBLOQUEIO(22, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
            END IF;

          END IF;

        ELSE
          IF (PCODROTINA = 336) THEN
            ALTERASTATUSBLOQUEIO(22, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
          END IF;
        END IF;
    ELSE
      IF (PCODMOTIVO = 22)  THEN
         ALTERASTATUSBLOQUEIO(22, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;

  END BLOQUEIO22;

  PROCEDURE BLOQUEIO23(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS
  BEGIN
    IF (PCODMOTIVO = 23) THEN
      --*O valor limite de credito excedido(codmotivo = 3)
      IF (NVL(VCPEDIDO.COBSUPPLIERCARD, 'N') = 'S') OR
         (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('EMPRESATRABALHACOMSUPPLIERCARD',
                                             VCPEDIDO.CODFILIAL,
                                             'N') = 'S') THEN

        validaLimCreditoParceiros(pTipoMotivo,
                                  23,
                                  vcPedido,
                                  pCodfunc,
                                  pCodrotina);
      END IF;

    END IF;
    --*fim O valor limite de credito excedido(codmotivo = 3)
  END BLOQUEIO23;

  PROCEDURE BLOQUEIO24(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS
    vnPercMaximoDescontoVenda NUMBER;
  BEGIN
    IF (PCODMOTIVO = 24) AND (VCPEDIDO.PERDESC > 0)
    THEN
      vnPercMaximoDescontoVenda := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('PERMAXDESCVENDA',
                                                                     VCPEDIDO.CODFILIAL,
                                                                     0);
      IF vnPercMaximoDescontoVenda <= 0 THEN
        vnPercMaximoDescontoVenda := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('PERMAXDESCVENDA',
                                                                       '99',
                                                                       0);
      END IF;

      IF (vnPercMaximoDescontoVenda > 0) AND
         (VCPEDIDO.PERDESC > vnPercMaximoDescontoVenda)
      THEN
        IF (PCODROTINA = 336) AND FUNC_TEMPERMISSAO(336, PCODFUNC, 92)
        THEN
          ALTERASTATUSBLOQUEIO(24, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
        END IF;
      ELSE
          ALTERASTATUSBLOQUEIO(24, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      END IF;
    END IF;
  END BLOQUEIO24;

  PROCEDURE BLOQUEIO26(PTIPOMOTIVO VARCHAR,
                       PCODMOTIVO  IN NUMBER,
                       VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                       PCODFUNC    IN NUMBER,
                       PCODROTINA  IN NUMBER) IS
    VnCODIGO PCBLOQUEIOSPEDIDO.codigo%TYPE;
  BEGIN
    IF (PCODMOTIVO = 26) THEN
       --336 rotina que libera, deve vir com o bloqueio Supplier liberado, sem olhar a COBRANÇA
     IF (PCODROTINA = 336) AND ((VCPEDIDO.BLOQUEIOSUPPLIER = 'N') OR (VCPEDIDO.CODCOB <> 'SUPP')) THEN
         ALTERASTATUSBLOQUEIO(26, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, PTIPOMOTIVO);
      --Qualquer rotina que mandar cobrança SUPP e estiver com Bloqueio na Supplier bloqueia o pedido
      ELSIF (VCPEDIDO.BLOQUEIOSUPPLIER = 'S') THEN

        BEGIN
          SELECT CODIGO
            INTO VnCODIGO
            FROM PCBLOQUEIOSPEDIDO
           WHERE CODMOTIVO = PCODMOTIVO
             AND NUMPED = VCPEDIDO.NUMPED
             AND CODMOTBLOQUEIO IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VnCODIGO := 0;
        END;
        IF (VNCODIGO = 0) THEN
          INSERTMOTIVO(VCPEDIDO.NUMPED,
                       PCODMOTIVO,
                       'Bloqueio Supplier',
                       PTIPOMOTIVO);
        END IF;

      END IF;
    END IF;
  END BLOQUEIO26;

  PROCEDURE BLOQUEIOSGENERICOS(
                               VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                               PCODROTINA  IN NUMBER,
                               PCODFUNC    IN NUMBER) IS

  BEGIN
    IF(PCODROTINA = 336)THEN
      FOR MOTGENERICO IN (SELECT CODMOTIVO, TIPO
                    FROM PCBLOQUEIOSPEDIDO
                   WHERE NUMPED = VCPEDIDO.NUMPED
           AND (CODMOTIVO >= 100 or CODMOTIVO in (6,12,19,25))
           AND CODMOTBLOQUEIO IS NULL
           AND STATUS <> 'L') LOOP

           ALTERASTATUSBLOQUEIO(MOTGENERICO.CODMOTIVO, 'L', VCPEDIDO.NUMPED, PCODFUNC, PCODROTINA, MOTGENERICO.TIPO);
       END LOOP;

    END IF;
  END BLOQUEIOSGENERICOS;


  PROCEDURE CHAMARBLOQUEIOS(PTIPOMOTIVO VARCHAR,
                            PCODMOTIVO  IN NUMBER,
                            VCPEDIDO    IN C_PEDIDO%ROWTYPE,
                            VCCLIENT    IN C_CLIENTE%ROWTYPE,
                            PCODROTINA  IN NUMBER,
                            PCODFUNC    IN NUMBER,
                            PMATRICULAAUTORIZADOR IN NUMBER default 0) IS
  BEGIN
    BLOQUEIOMENOS1(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO1(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO2(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO3(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO4(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO5(PTIPOMOTIVO,PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA); --A liberação do bloqueio é feita aqui, o bloqueio é via rotina.
    BLOQUEIO7(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO8(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO9(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO10(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO11(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO13(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, VCCLIENT, PCODFUNC, PCODROTINA);
    BLOQUEIO14(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, VCCLIENT, PCODFUNC, PCODROTINA);
    BLOQUEIO15(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO16(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA, PMATRICULAAUTORIZADOR);
    BLOQUEIO17(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, VCCLIENT, PCODFUNC, PCODROTINA);
    BLOQUEIO18(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO20(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO21(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO22(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO23(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO24(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);
    BLOQUEIO26(PTIPOMOTIVO, PCODMOTIVO, VCPEDIDO, PCODFUNC, PCODROTINA);

  END CHAMARBLOQUEIOS;

  PROCEDURE MOTIVOSBLOQUEIO_COMERCIAL(PCODFUNC   IN NUMBER,
                                      VCPEDIDO   IN C_PEDIDO%ROWTYPE,
                                      VCCLIENTE  IN C_CLIENTE%ROWTYPE,
                                      PCODROTINA IN NUMBER,
                                      PMATRICULAAUTORIZADOR IN NUMBER default 0) IS

  BEGIN
    --*Validação PCMOTBLOQUEIO Rotina 398
    FOR MOTIVO IN (SELECT CODMOTIVO FROM pcmotbloqueio where tipo = 2) LOOP
      CHAMARBLOQUEIOS('C',
                      MOTIVO.CODMOTIVO,
                      VCPEDIDO,
                      VCCLIENTE,
                      PCODROTINA,
                      PCODFUNC,
                      PMATRICULAAUTORIZADOR);
    END LOOP;
    --*Validação PCBLOQUEIO Rotina 307
    BLOQUEIOPCBLOQUEIO(PCODFUNC, VCPEDIDO, VCCLIENTE, PCODROTINA);
    --*FIM VALIDAÇÃO PCBLOQUEIO ROTINA 307

    CLOSE C_PCBLOQUEIO;
  END MOTIVOSBLOQUEIO_COMERCIAL;

  PROCEDURE MOTIVOSBLOQUEIO_FINANCEIRO(PCODFUNC   IN NUMBER,
                                       VCPEDIDO   IN C_PEDIDO%ROWTYPE,
                                       VCCLIENTE  IN C_CLIENTE%ROWTYPE,
                                       PCODROTINA IN NUMBER,
                                       PMATRICULAAUTORIZADOR IN NUMBER default 0) IS
  BEGIN

    FOR MOTIVO IN (SELECT CODMOTIVO FROM PCMOTBLOQUEIO WHERE TIPO = 1) LOOP
      CHAMARBLOQUEIOS('F',
                      MOTIVO.CODMOTIVO,
                      VCPEDIDO,
                      VCCLIENTE,
                      PCODROTINA,
                      PCODFUNC,
                      PMATRICULAAUTORIZADOR);
    END LOOP;

  END MOTIVOSBLOQUEIO_FINANCEIRO;

  PROCEDURE VALIDAMOTIVOSBLOQUEIO(PNUMPED    IN NUMBER,
                                  PCODFUNC   IN NUMBER,
                                  PCODROTINA IN NUMBER,
                                  PMATRICULAAUTORIZADOR IN NUMBER default 0
                                  ) IS
  BEGIN

    /************Abertura dos cursores Globais************************/
    IF C_PEDIDO%ISOPEN THEN
     CLOSE C_PEDIDO;
   END IF;

   OPEN C_PEDIDO(PNUMPED);
    FETCH C_PEDIDO
      INTO VCPEDIDO;

   IF PMATRICULAAUTORIZADOR > 0 THEN
     CARREGAR_PERMISSOES(PCODROTINA, PMATRICULAAUTORIZADOR);
   ELSE
     CARREGAR_PERMISSOES(PCODROTINA, PCODFUNC);
   END IF;

    VALIDAMOTIVOSBLOQUEIO(VCPEDIDO, PCODFUNC, PCODROTINA, PMATRICULAAUTORIZADOR);

  END VALIDAMOTIVOSBLOQUEIO;


  PROCEDURE VALIDAMOTIVOSBLOQUEIO(VCPEDIDO   C_PEDIDO%ROWTYPE,
                                  PCODFUNC   IN NUMBER,
                                  PCODROTINA IN NUMBER,
                                  PMATRICULAAUTORIZADOR IN NUMBER default 0) IS
  BEGIN

    /************Abertura dos cursores Globais************************/
    IF C_CLIENTE%ISOPEN THEN
       CLOSE C_CLIENTE;
    END IF;

    OPEN C_CLIENTE(VCPEDIDO.CODCLI);
    FETCH C_CLIENTE
      INTO VCCLIENTE;
    /***********************************Validações de bloqueios*********************************************/

    MOTIVOSBLOQUEIO_COMERCIAL(PCODFUNC, VCPEDIDO, VCCLIENTE, PCODROTINA, PMATRICULAAUTORIZADOR);

    MOTIVOSBLOQUEIO_FINANCEIRO(PCODFUNC, VCPEDIDO, VCCLIENTE, PCODROTINA, PMATRICULAAUTORIZADOR);

    BLOQUEIOSGENERICOS(VCPEDIDO,PCODROTINA, PCODFUNC);

    --CLOSE C_PEDIDO;
    CLOSE C_CLIENTE;

  END VALIDAMOTIVOSBLOQUEIO;

  FUNCTION RETORNALISTAMOTIVOS(PNUMPED IN NUMBER) RETURN VARCHAR2 IS
    vsmotivo varchar2(4000);
  BEGIN

    begin
      for m in (select motivo,codmotivo from pcbloqueiospedido where numped = PNUMPED and status = 'B') loop
        vsMotivo := Substr((m.codmotivo || ' - ' || m.motivo || ' - ' || vsMotivo), 1, 4000);
      end loop;
    exception
      when others then
        vsMotivo := '';
    end;

    return(vsMotivo);

  END RETORNALISTAMOTIVOS;


END PKG_MOTIVOBLOQUEIO;
