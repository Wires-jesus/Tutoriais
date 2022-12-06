create or replace package body INTEGRADORA_COMPLE is

     PROCEDURE proc_registralog
  (
    p_numped        IN pcpedc.numped%TYPE,
    p_numpedrca     IN pcpedc.numpedrca%TYPE,
    p_codprod       IN pcprodut.codprod%TYPE,
    p_numseq        IN pcpedifv.numseq%TYPE,
    p_codauxiliar   IN pcpedi.codauxiliar%TYPE,
    p_cgcent        IN pcclient.cgcent%TYPE,
    p_codigocotacao IN pccota.codcotacao%TYPE,
    p_numrecadofv   IN pcrecfunc.numrecadofv%TYPE,
    p_numcontagem   IN pcgondolac.numcontagem%TYPE,
    p_codusur       IN pcpedc.codusur%TYPE,
    p_data          IN DATE,
    p_cancelada     IN VARCHAR2,
    p_tiporeg       IN VARCHAR2, -- 1 = generico / -1 = Clientes /2 = cabecalho / 3 = itens /4 = Contatos
    p_erro          IN VARCHAR2,
    p_linhareg      IN NUMBER,
    p_numseqfv      IN NUMBER
  ) IS
  vnnumseqfv        pcpedifv.numseq%type;
  VNBLOQUEADO NUMBER := 0;
  --pragma autonomous_transaction;
  BEGIN
    vngcontador := vngcontador + 1;
    gvetregistralog(vngcontador).numped := p_numped;
    gvetregistralog(vngcontador).numpedrca := p_numpedrca;
    gvetregistralog(vngcontador).codprod := p_codprod;
    gvetregistralog(vngcontador).numseq  := p_numseq;
    gvetregistralog(vngcontador).codauxiliar := p_codauxiliar;
    gvetregistralog(vngcontador).cgcent := p_cgcent;
    gvetregistralog(vngcontador).codigocotacao := p_codigocotacao;
    gvetregistralog(vngcontador).numrecadofv := p_numrecadofv;
    gvetregistralog(vngcontador).numcontagem := p_numcontagem;
    gvetregistralog(vngcontador).codusur := p_codusur;
    gvetregistralog(vngcontador).data := p_data;
    gvetregistralog(vngcontador).cancelada := p_cancelada;
    gvetregistralog(vngcontador).tiporeg := p_tiporeg;
    gvetregistralog(vngcontador).erro := p_erro;
    gvetregistralog(vngcontador).linhareg := p_linhareg;

    begin
      select i.numseqfv into vnnumseqfv
        from pcpedipcpedifv i
       where i.numped  = p_numped
         and i.codprod = p_codprod
         and i.codusur = p_codusur
         and i.numseq  = p_numseq;
    exception
      when others then
        vnnumseqfv := p_numseqfv;
    end;

    gvetregistralog(vngcontador).numseq := vnnumseqfv;

    if p_tiporeg = 2 then
      SELECT 1
        INTO VNBLOQUEADO
        FROM PCPEDCFV
       WHERE NUMPEDRCA = p_numpedrca AND
             CODUSUR = p_codusur AND
             DTABERTURAPEDPALM = p_data AND
             ROWNUM = 1
             FOR UPDATE;

      update pcpedcfv c
         set c.observacao_pc = substr(substr(c.observacao_pc, 1, 4000-length(p_erro)) || p_erro, 1, 4000)
       where c.numpedrca         = p_numpedrca
         and c.codusur           = p_codusur
         and c.dtaberturapedpalm = p_data;
    elsif p_tiporeg = 3 then
      update pcpedifv i
         set i.observacao_pc = substr(substr(i.observacao_pc, 1, 4000-length(p_erro)) || p_erro, 1, 4000)
       where i.numpedrca         = p_numpedrca
         and i.codusur           = p_codusur
         and i.dtaberturapedpalm = p_data
         and i.codprod           = p_codprod
         and i.numseq            = vnnumseqfv;
    end if;

  END proc_registralog;

  PROCEDURE proc_pcpedimov(p_regpedido in t_cabped,
                           p_codprod   in number,
                           p_numseq    in number,
                           p_qt        in number,
                           p_movest    in varchar2) IS
    vnqtanterior      pcpedi.qt%type;
  BEGIN

    IF greatest(nvl(p_qt, 0), 0) = 0 THEN

      Begin
        select qt
          into vnqtanterior
          FROM pcpedi
         WHERE numped = p_regpedido.numped
           AND codprod = p_codprod
           AND numseq = p_numseq;
      Exception
        when others then
          vnqtanterior := 0;
      End;

      DELETE FROM pcpedi
       WHERE numped = p_regpedido.numped
         AND codprod = p_codprod
         AND numseq = p_numseq;

      DELETE FROM pcorigempreco
       WHERE numped = p_regpedido.numped
         AND codprod = p_codprod
         AND numseq = p_numseq;

    ELSE
      UPDATE PCPEDI
         SET QT = p_qt
       WHERE numped = p_regpedido.numped
         AND codprod = p_codprod
         AND numseq = p_numseq;

    END IF;

  END proc_pcpedimov;

  FUNCTION BuscarLimCredSazonal(p_codcli  NUMBER,
                                P_codusur NUMBER,
                                p2553_132 VARCHAR2) RETURN NUMBER IS
  
    vlimcredtemp NUMBER := 0;
    vpercaumento NUMBER := 0;
  
  BEGIN
  
    if (p2553_132 = 'N') Then
      select sum(limcred)
        into vlimcredtemp
        from pcclient
       where codcli = p_codcli;
    else
      select sum(limcred)
        into vlimcredtemp
        from pcclient
       where NVL(codcliprinc, codcli) =
             (select NVL(codcliprinc, codcli)
                from pcclient
               where codcli = p_codcli);
    end if;
  
    BEGIN
      SELECT percaumento
        into vpercaumento
        FROM pclimcred
       WHERE pclimcred.coddcli = p_codcli
         AND TRUNC(SYSDATE) BETWEEN pclimcred.dtinicio AND pclimcred.dtfim
         AND ((pclimcred.codusur IS NULL) OR
             (pclimcred.codusur = P_codusur));
    EXCEPTION
      WHEN OTHERS THEN
        vpercaumento := 0;
    END;
  
    Return vlimcredtemp *(nvl(vpercaumento, 0) / 100);
  
  END;

  procedure proc_delitensped(p_regpedido in t_cabped, p_movest in varchar2) is

  BEGIN
    FOR itens IN (SELECT pcpedi.codprod,
                         pcpedi.numseq,
                         pcpedi.codauxiliar,
                         pcpedi.qtfalta,
                         pcpedi.qt
                    FROM pcpedi
                   inner join pcpedipcpedifv
                      on pcpedipcpedifv.numped = pcpedi.numped
                     and pcpedipcpedifv.numseq = pcpedi.numseq
                     and pcpedipcpedifv.codprod = pcpedi.codprod
                   WHERE pcpedi.numped = p_regpedido.numped
                     AND pcpedipcpedifv.numpedrcafv = p_regpedido.numpedrca) LOOP

      proc_pcpedimov(p_regpedido,
                     itens.codprod,
                     itens.numseq,
                     0,
                     nvl(p_movest, 'N'));

    END LOOP;
  END proc_delitensped;

  FUNCTION func_lockpedido(P_NUMPEDRCA   IN NUMBER,
                           P_CODUSUR     IN NUMBER,
                           P_DATA        IN DATE,
                           P_CGCCLI      IN VARCHAR,
                           P_TIPOLEITURA IN NUMBER) RETURN BOOLEAN IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    VNBLOQUEADO NUMBER := 0;

  BEGIN

    -- Lock do registro para evitar que dois processamentos capturem o pedido
  BEGIN
    SELECT 1
      INTO VNBLOQUEADO
      FROM PCPEDCFV
     WHERE NUMPEDRCA = P_NUMPEDRCA
       AND CODUSUR = P_CODUSUR
       AND DTABERTURAPEDPALM = P_DATA
       AND CGCCLI = P_CGCCLI
       AND IMPORTADO = P_TIPOLEITURA
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      VNBLOQUEADO := 0;
    END;     

    IF VNBLOQUEADO > 0 THEN
      -- BLOQUEIA O REGISTRO AUTORIZANDO A IMPORTAÇÃO

      vlog.NUMPEDRCA         := P_NUMPEDRCA;
      vlog.CODUSUR           := P_CODUSUR;
      vlog.CGCCLI            := P_CGCCLI;
      vlog.DTABERTURAPEDPALM := P_DATA;
      vlog.MSG               := 'Efetuando Lock do Pedido ';

      PRC_LOG_INTEGRADORA(vlog,
                          (CASE WHEN vlog.MSG LIKE '%ORA-%' THEN
                           DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
                           TO_CHAR($$PLSQL_LINE) END));

      UPDATE PCPEDCFV
         SET IMPORTADO = 4, VERSAOPKG = vsVersao
       WHERE NUMPEDRCA = P_NUMPEDRCA
         AND CODUSUR = P_CODUSUR
         AND DTABERTURAPEDPALM = P_DATA
         AND CGCCLI = P_CGCCLI;

      UPDATE PCPEDIFV
         SET VERSAOPKG = VSVERSAO
       WHERE NUMPEDRCA = P_NUMPEDRCA
         AND CODUSUR = P_CODUSUR
         AND DTABERTURAPEDPALM = P_DATA
         AND CGCCLI = P_CGCCLI;

      vlog.NUMPEDRCA         := P_NUMPEDRCA;
      vlog.CODUSUR           := P_CODUSUR;
      vlog.CGCCLI            := P_CGCCLI;
      vlog.DTABERTURAPEDPALM := P_DATA;
      vlog.MSG               := 'Lock efetuado com sucesso. ';

      PRC_LOG_INTEGRADORA(vlog,
                          (CASE WHEN vlog.MSG LIKE '%ORA-%' THEN
                           DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
                           TO_CHAR($$PLSQL_LINE) END));

      COMMIT;
      RETURN TRUE;
    END IF;

    -- PEDIDO JÁ ESTÁ EM PROCESSAMENTO, REJEITA A IMPORTAÇÃO
    ROLLBACK;
    RETURN FALSE;

  EXCEPTION
    WHEN OTHERS THEN
      vlog.NUMPEDRCA         := P_NUMPEDRCA;
      vlog.CODUSUR           := P_CODUSUR;
      vlog.CGCCLI            := P_CGCCLI;
      vlog.DTABERTURAPEDPALM := P_DATA;
      vlog.MSG               := 'Não foi possível efetuar lock do pedido. Motivo ' ||
                                SQLERRM || ' - ' || SQLCODE;
      PRC_LOG_INTEGRADORA(vlog,
                          (CASE WHEN vlog.MSG LIKE '%ORA-%' THEN
                           DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE
                           TO_CHAR($$PLSQL_LINE) END));
      ROLLBACK;
      RETURN FALSE;
  END func_lockpedido;

  FUNCTION RetornarMargemMinimaItem(pnCODPROD IN NUMBER,
                                    psCODFILIAL IN VARCHAR2,
                                    pnMargem OUT NUMBER)
    RETURN BOOLEAN
  IS
    vbResult BOOLEAN;
    vnMargemMin NUMBER;
  BEGIN

    vbResult := False;
    pnMargem := 0;

    BEGIN
      SELECT NVL(PERCMARGEMMIN, 0)
        INTO vnMargemMin
        FROM PCPRODFILIAL
       WHERE CODPROD = pnCODPROD
         AND CODFILIAL = psCODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnMargemMin := 0;
    END;

    IF vnMargemMin > 0 THEN
      vbResult := True;
      pnMargem := vnMargemMin;
    END IF;

    RETURN vbResult;

  END RetornarMargemMinimaItem;

  FUNCTION func_calcularperdescitem
  (
    p_ptabela IN pcpedi.ptabela%TYPE,
    p_pvenda  IN pcpedi.pvenda%TYPE
  ) RETURN NUMBER IS
    vnperdesc NUMBER;
  BEGIN

    vnperdesc := ((p_ptabela - p_pvenda) / p_ptabela) * 100;
    --vnperdesc := ROUND(vnperdesc, gregpcconsum.numcasasdecvenda);

    RETURN vnperdesc;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END func_calcularperdescitem;

  PROCEDURE gerarcarregbalcaoreserva
  (
    p_numped            IN pcpedc.numped%TYPE,
    p_numpedrca         IN pcpedc.numpedrca%TYPE,
    p_codusur           IN pcpedc.codusur%TYPE,
    p_cgccli            IN pcclient.cgcent%TYPE,
    p_dtaberturapedpalm IN pcpedc.dtaberturapedpalm%TYPE,
    p_cancelada         IN VARCHAR2,
    p_numcar            OUT pcpedc.numcar%TYPE
  ) IS

    pncaregamento  NUMBER;
    vnvlatendped   pcpedc.vlatend%TYPE;
    vntotpesoped   pcpedc.totpeso%TYPE;
    vntotvolumeped pcpedc.totvolume%TYPE;
    curr_time      NUMBER;
    end_time       NUMBER;
    iTentativa     NUMBER;

  BEGIN
    BEGIN

      pncaregamento := -1;
      pncaregamento := ferramentas.f_prox_numcar;
      iTentativa := 0;
      while iTentativa < 50 or pncaregamento = -1
      loop
        pncaregamento := ferramentas.f_prox_numcar;
         if pncaregamento >= 0 then
           exit;
         end if;
        iTentativa := iTentativa + 1;
      end loop;

      IF nvl(pncaregamento, 0) = 0 THEN
        p_numcar := 0;
        return;
      ELSE
        p_numcar := pncaregamento;
      END IF;

      UPDATE pcpedi
         SET numcar  = pncaregamento,
             posicao = 'M'
       WHERE numped IN (SELECT numped
                          FROM pcpedc
                         WHERE numpedrca = p_numpedrca
                           AND nvl(pcpedc.restricaotransp,
                                   'N') = 'N'
                           AND codusur = p_codusur
                           AND (dtaberturapedpalm = p_dtaberturapedpalm OR dtaberturapedpalm IS NULL)
                           AND posicao = 'L');

      UPDATE pcpedc
         SET numcar    = pncaregamento,
             posicao   = 'M',
             tipocarga = 'R'
       WHERE numped IN (SELECT numped
                          FROM pcpedc
                         WHERE numpedrca = p_numpedrca
                           AND nvl(pcpedc.restricaotransp,
                                   'N') = 'N'
                           AND codusur = p_codusur
                           AND (dtaberturapedpalm = p_dtaberturapedpalm OR dtaberturapedpalm IS NULL)
                           AND posicao = 'L');



      SELECT SUM(pcpedi.qt * pcpedi.pvenda),
             SUM(NVL(pcpedi.qt,
                     0) * NVL(pcprodut.pesobruto,
                              0)) totpeso,
             SUM(NVL(pcpedi.qt,
                     0) * NVL(pcprodut.volume,
                              0)) totvolume
        INTO vnvlatendped,
             vntotpesoped,
             vntotvolumeped
        FROM pcpedi,
             pcprodut
       WHERE pcpedi.codprod = pcprodut.codprod
         AND numped IN (SELECT numped
                          FROM pcpedc
                         WHERE numpedrca = p_numpedrca
                           AND nvl(pcpedc.restricaotransp,
                                   'N') = 'N'
                           AND codusur = p_codusur
                           AND (dtaberturapedpalm = p_dtaberturapedpalm OR dtaberturapedpalm IS NULL)
                           AND posicao = 'M');



      INSERT INTO pccarreg
        (numcar,
         dtsaida,
         totpeso,
         totvolume,
         vltotal,
         destino,
         datamon,
         codveiculo,
         codfuncmon,
         dtfecha,
         numnotas)
      VALUES
        (pncaregamento,
         TRUNC(SYSDATE),
         vntotpesoped,
         vntotvolumeped,
         vnvlatendped,
         'VENDA BALCAO',
         TRUNC(SYSDATE),
         0,
         0,
         '',  -- DDVENDAS-4630
         1);

--      COMMIT;

      vLog.NUMPEDRCA         := p_numpedrca;
      vLog.CODUSUR           := p_CODUSUR;
      vLog.CGCCLI            := p_CGCCLI;
      vLog.DTABERTURAPEDPALM := p_DTABERTURAPEDPALM;
      vLog.TIPOLOG           := 'C';
      vLog.MSG               := 'Carregamento criado para pedido balcão reserva. NUMCAR = ' || to_char(p_numcar);

      PRC_LOG_INTEGRADORA(vlog, (CASE WHEN vLog.MSG LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));



      proc_registralog(p_numped,
                                   p_numpedrca,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_cgccli,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_codusur,
                                   p_dtaberturapedpalm,
                                   p_cancelada,
                                   '2',
                                   'CARREGAMENTO CRIADO PARA PEDIDO BALCAO RESERVA. NUMCAR = ' || TO_CHAR(p_numcar) || ';',
                                   NULL,
                                   NULL);

      p_numcar := pncaregamento;

    EXCEPTION
      WHEN OTHERS THEN

        vLog.NUMPEDRCA         := p_numpedrca;
        vLog.CODUSUR           := p_CODUSUR;
        vLog.CGCCLI            := p_CGCCLI;
        vLog.DTABERTURAPEDPALM := p_DTABERTURAPEDPALM;
        vLog.TIPOLOG           := 'C';
        vLog.MSG               := 'Erro ao gerar carregamento ' || to_char(pncaregamento);

        PRC_LOG_INTEGRADORA(vlog, (CASE WHEN vLog.MSG LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

        proc_registralog(p_numped,
                                     p_numpedrca,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_cgccli,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_codusur,
                                     p_dtaberturapedpalm,
                                     p_cancelada,
                                     '2',
                                     'ERRO: NAO GEROU/ATUALIZOU CARREGAMENTO. NUMCAR = ' || TO_CHAR(pncaregamento,
                                                                                                    '000000') || ';',
                                     NULL,
                                     NULL);
        --ROLLBACK;
    END;
  END gerarcarregbalcaoreserva;

  PROCEDURE proc_validaplanosmed
  (
    p_regpedido        IN OUT t_cabped,
    p_regcliente       IN t_clientepedido,
    p_regplpag         OUT t_planodepagamento,
    p_regplpagetico    OUT t_plpagetico,
    p_regplpaggenerico OUT t_plpaggenerico
  ) IS


    vicontador         NUMBER;
    vsmensagem         VARCHAR2(32767) := NULL;
    vschar             VARCHAR2(1) DEFAULT '#';
    vbvalidacob        BOOLEAN;
    vsprazos           VARCHAR2(50);
    vicont             NUMBER;
    vnprazototal       NUMBER;
    vsboleto           pccob.boleto%TYPE;
    vnprazomaximovenda pccob.prazomaximovenda%TYPE;

  BEGIN

    p_regpedido.codplpag := 99;

    p_regpedido.codplpagetico    := nvl(p_regpedido.codplpagetico,
                                        p_regcliente.codplpagetico);
    p_regpedido.codplpaggenerico := nvl(p_regpedido.codplpaggenerico,
                                        p_regcliente.codplpaggenerico);

    SELECT boleto,
           prazomaximovenda
      INTO vsboleto,
           vnprazomaximovenda
      FROM pccob
     WHERE codcob = p_regpedido.codcob;


    IF p_regpedido.codplpagetico = 99
       OR p_regpedido.codplpagetico IS NULL
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO NAO PODE SER NULO nem 99 ;';
      p_regpedido.valido := FALSE;

    END IF;

    IF p_regpedido.codplpaggenerico = 99
       OR p_regpedido.codplpaggenerico IS NULL
    THEN
      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO  NAO PODE SER NULO nem 99 ;';
      p_regpedido.valido := FALSE;

    END IF;



    --valida plano de pagamento etico
    SELECT COUNT(*)
      INTO vicontador
      FROM pcplpag
     WHERE codplpag = p_regpedido.codplpagetico;

    IF vicontador = 0
    THEN
      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO :' || p_regpedido.codplpagetico || ' NAO CADASTRADO ;';
      p_regpedido.valido := FALSE;
    ELSE

      SELECT codplpag,
             nvl(numdias,
                 0),
             NVL(numitensminimo,
                 0),
             NVL(numpr,
                 1) numpr,
             obs,
             NVL(pertxfim,
                 0),
             prazo1,
             prazo2,
             prazo3,
             prazo4,
             prazo5,
             prazo6,
             prazo7,
             prazo8,
             prazo9,
             prazo10,
             prazo11,
             prazo12,
             NVL(tipoprazo,
                 'N'),
             tipovenda,
             NVL(vlminpedido,
                 0),
             NVL(pcplpag.vendabk,
                 'N'),
             NVL(tiporestricao,
                 'NR'),
             codrestricao,
             TRIM(codfilial),
             pcplpag.formaparcelamento
        INTO p_regplpagetico
        FROM pcplpag
       WHERE codplpag = p_regpedido.codplpagetico;

    END IF;


    IF p_regplpagetico.formaparcelamento <> 'C'
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO SÓ ACEITA PLANO TIPO CUSTOMIZADO ;';
      p_regpedido.valido := FALSE;

    END IF;


    vbvalidacob := TRUE;

    --tarefa 125968

    SELECT COUNT(*)
      INTO vicontador
      FROM pccobplpag p
     WHERE p.codcob = p_Regpedido.codcob;


    IF vicontador <> 0
    THEN

      SELECT COUNT(*)
        INTO vicontador
        FROM pccobplpag p
       WHERE p.codplpag = p_Regpedido.codplpagetico
         AND p.codcob = p_Regpedido.codcob;


      IF vicontador = 0
      THEN

        IF vsmensagem IS NOT NULL
        THEN
          vschar := '#';
        ELSE
          vschar := NULL;
        END IF;
        vsmensagem         := vsmensagem || vschar || 'RELACIONAMENTO ENTRE PLANO DE PAGAMENTO ETICO ' || p_regpedido.codplpagetico || ' E COBRANCA ' || p_regpedido.codcob || ' NAO CADASTRADO;';
        p_regpedido.valido := FALSE;


      ELSE

        vbvalidacob := FALSE;

      END IF;
    END IF;



    IF vbvalidacob = TRUE
    THEN

      --12 Plano de Pagamento Restritivo do cliente
      SELECT COUNT(*)
        INTO vicontador
        FROM pcplpagcli
       WHERE codcli = p_regpedido.codcli;

      IF vicontador <> 0
      THEN

        SELECT COUNT(*)
          INTO vicontador
          FROM pcplpagcli
         WHERE codcli = p_regpedido.codcli
           AND codplpag = p_regpedido.codplpagetico;

        IF vicontador = 0
        THEN
          IF vsmensagem IS NOT NULL
          THEN
            vschar := '#';
          ELSE
            vschar := NULL;
          END IF;
          vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO ' || p_regpedido.codplpagetico || ' NAO CADASTRADO PARA ESTE CLIENTE;';
          p_regpedido.valido := FALSE;

        END IF;

      END IF;

    END IF;


    IF p_regplpagetico.codfilial IS NOT NULL
       AND p_regplpag.codfilial <> '99'
       AND

       p_regplpagetico.codfilial <> p_regpedido.codfilial
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;

      vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO' || p_regpedido.codplpagetico || ' NAO EXISTE PARA A FILIAL ' || p_regpedido.codfilial || ';';

      p_regpedido.valido := FALSE;

    END IF;

    IF p_regplpagetico.tiporestricao = 'OP'
       AND p_regplpagetico.codrestricao <> 4
    THEN
      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO ' || p_regpedido.codplpagetico || ' COM RESTRICAO POR ORIGEM DE PEDIDO NAO ACEITA FORCA DE VENDAS ;';

      p_regpedido.valido := FALSE;

    END IF;

    IF p_regplpagetico.tiporestricao = 'RA'
       AND p_regplpagetico.codrestricao <> p_regcliente.codatv1
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;

      vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO ' || p_regpedido.codplpagetico || ' COM RESTRICAO POR RAMO DE ATIVIDADE NAO ACEITA CODIGO ATIVIDADE: ' || p_regcliente.codatv1 || ';';

      p_regpedido.valido := FALSE;

    END IF;

    IF vbvalidacob = TRUE
    THEN


      -- verifica prazo do plano de pagamento
      IF p_regcliente.codplpag > 0
      THEN

        IF p_regplpagetico.numdias > p_regcliente.numdias
        THEN

          IF NVL(gregpcconsum.bloqprazomdvenda,
                 'N') = 'S'
          THEN

            IF vsmensagem IS NOT NULL
            THEN
              vschar := '#';
            ELSE
              vschar := NULL;
            END IF;
            vsmensagem := vsmensagem || vschar || 'PRAZO DO PLANO DE PAGAMENTO ETICO #' || 'SUPERIOR AO PRAZO DO CLIENTE #' || 'PRAZO DO PEDIDO ' || p_regplpagetico.numdias || ';' ||
                          ' PRAZO DO CLIENTE ' || p_regcliente.numdias || ';';

            p_regpedido.valido := FALSE;

          END IF;
        END IF;
      END IF;

      IF (vnprazomaximovenda < p_regplpagetico.numdias)
      THEN

        IF vsmensagem IS NOT NULL
        THEN
          vschar := '#';
        ELSE
          vschar := NULL;
        END IF;

        vsmensagem := vsmensagem || vschar || 'PRAZO MAXIMO DA COBRANCA #' || 'INFERIOR AO PRAZO DO PLANO ETICO #' || 'PRAZO MAXIMO DA COBRANCA ' || vnprazomaximovenda || ';' || 'PRAZO DO PLANO ' ||
                      p_regplpagetico.numdias || ';';

        p_regpedido.valido := FALSE;

      END IF;


      IF vsboleto = 'S'
         OR p_regpedido.codcob = 'BK'
      THEN

        IF p_regplpagetico.vendabk = 'N'
        THEN

          IF vsmensagem IS NOT NULL
          THEN
            vschar := '#';
          ELSE
            vschar := NULL;
          END IF;
          vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO ETICO NAO ACEITA COBRANCA BK ' || ';';
          p_regpedido.valido := FALSE;

        END IF;

      END IF;


    END IF;


    -------------------------------------------------------------------------------------------------------------------------------------
    --valida plano de pagamento generico
    SELECT COUNT(*)
      INTO vicontador
      FROM pcplpag
     WHERE codplpag = p_regpedido.codplpaggenerico;

    IF vicontador = 0
    THEN
      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO ' || p_regpedido.codplpaggenerico || ' NAO CADASTRADO ;';
      p_regpedido.valido := FALSE;
    ELSE

      SELECT codplpag,
             nvl(numdias,
                 0),
             NVL(numitensminimo,
                 0),
             NVL(numpr,
                 1) numpr,
             obs,
             NVL(pertxfim,
                 0),
             prazo1,
             prazo2,
             prazo3,
             prazo4,
             prazo5,
             prazo6,
             prazo7,
             prazo8,
             prazo9,
             prazo10,
             prazo11,
             prazo12,
             NVL(tipoprazo,
                 'N'),
             tipovenda,
             NVL(vlminpedido,
                 0),
             NVL(pcplpag.vendabk,
                 'N'),
             NVL(tiporestricao,
                 'NR'),
             codrestricao,
             TRIM(codfilial),
             pcplpag.formaparcelamento
        INTO p_regplpaggenerico
        FROM pcplpag
       WHERE codplpag = p_regpedido.codplpaggenerico;

    END IF;


    IF p_regplpaggenerico.formaparcelamento <> 'C'
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO SÓ ACEITA PLANO TIPO CUSTOMIZADO ;';
      p_regpedido.valido := FALSE;

    END IF;


    vbvalidacob := TRUE;

    --tarefa 125968

    SELECT COUNT(*)
      INTO vicontador
      FROM pccobplpag p
     WHERE p.codcob = p_Regpedido.codcob;


    IF vicontador <> 0
    THEN

      SELECT COUNT(*)
        INTO vicontador
        FROM pccobplpag p
       WHERE p.codplpag = p_Regpedido.codplpaggenerico
         AND p.codcob = p_Regpedido.codcob;


      IF vicontador = 0
      THEN

        IF vsmensagem IS NOT NULL
        THEN
          vschar := '#';
        ELSE
          vschar := NULL;
        END IF;
        vsmensagem         := vsmensagem || vschar || 'RELACIONAMENTO ENTRE PLANO DE PAGAMENTO GENERICO ' || p_regpedido.codplpaggenerico || ' E COBRANCA ' || p_regpedido.codcob || ' NAO CADASTRADO;';
        p_regpedido.valido := FALSE;


      ELSE

        vbvalidacob := FALSE;

      END IF;
    END IF;


    IF vbvalidacob = TRUE
    THEN

      --12 Plano de Pagamento Restritivo do cliente
      SELECT COUNT(*)
        INTO vicontador
        FROM pcplpagcli
       WHERE codcli = p_regpedido.codcli;

      IF vicontador <> 0
      THEN

        SELECT COUNT(*)
          INTO vicontador
          FROM pcplpagcli
         WHERE codcli = p_regpedido.codcli
           AND codplpag = p_regpedido.codplpaggenerico;

        IF vicontador = 0
        THEN
          IF vsmensagem IS NOT NULL
          THEN
            vschar := '#';
          ELSE
            vschar := NULL;
          END IF;
          vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO ' || p_regpedido.codplpaggenerico || ' NAO CADASTRADO PARA ESTE CLIENTE ;';
          p_regpedido.valido := FALSE;

        END IF;


      END IF;

    END IF;


    IF p_regplpaggenerico.codfilial IS NOT NULL
       AND p_regplpag.codfilial <> '99'
       AND

       p_regplpaggenerico.codfilial <> p_regpedido.codfilial
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;

      vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO ' || p_regpedido.codplpaggenerico || ' NAO EXISTE PARA A FILIAL ' || p_regpedido.codfilial || ';';

      p_regpedido.valido := FALSE;

    END IF;

    IF p_regplpaggenerico.tiporestricao = 'OP'
       AND p_regplpaggenerico.codrestricao <> 4
    THEN
      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;
      vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO ' || p_regpedido.codplpaggenerico || ' COM RESTRICAO POR ORIGEM DE PEDIDO NAO ACEITA FORCA DE VENDAS ;';

      p_regpedido.valido := FALSE;

    END IF;

    IF p_regplpaggenerico.tiporestricao = 'RA'
       AND p_regplpaggenerico.codrestricao <> p_regcliente.codatv1
    THEN

      IF vsmensagem IS NOT NULL
      THEN
        vschar := '#';
      ELSE
        vschar := NULL;
      END IF;

      vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO ' || p_regpedido.codplpaggenerico || ' COM RESTRICAO POR RAMO DE ATIVIDADE NAO ACEITA CODIGO ATIVIDADE : ' ||
                    p_regcliente.codatv1 || ';';

      p_regpedido.valido := FALSE;

    END IF;

    IF vbvalidacob = TRUE
    THEN


      -- verifica prazo do plano de pagamento
      IF p_regcliente.codplpag > 0
      THEN

        IF p_regplpaggenerico.numdias > p_regcliente.numdias
        THEN

          IF NVL(gregpcconsum.bloqprazomdvenda,
                 'N') = 'S'
          THEN

            IF vsmensagem IS NOT NULL
            THEN
              vschar := '#';
            ELSE
              vschar := NULL;
            END IF;
            vsmensagem := vsmensagem || vschar || 'PRAZO DO PLANO DE PAGAMENTO GENERICO #' || 'SUPERIOR AO PRAZO DO CLIENTE #' || 'PRAZO DO PEDIDO ' || p_regplpaggenerico.numdias || ';' ||
                          'PRAZO DO CLIENTE ' || p_regcliente.numdias || ';';

            p_regpedido.valido := FALSE;

          END IF;
        END IF;
      END IF;


      IF (vnprazomaximovenda < p_regplpaggenerico.numdias)
      THEN

        IF vsmensagem IS NOT NULL
        THEN
          vschar := '#';
        ELSE
          vschar := NULL;
        END IF;

        vsmensagem := vsmensagem || vschar || 'PRAZO MAXIMO DA COBRANCA #' || 'INFERIOR AO PRAZO DO PLANO GENERICO #' || 'PRAZO MAXIMO DA COBRANCA ' || vnprazomaximovenda || ';' || 'PRAZO DO PLANO ' ||
                      p_regplpaggenerico.numdias || ';';

        p_regpedido.valido := FALSE;

      END IF;


      IF vsboleto = 'S'
         OR p_regpedido.codcob = 'BK'
      THEN

        IF p_regplpaggenerico.vendabk = 'N'
        THEN

          IF vsmensagem IS NOT NULL
          THEN
            vschar := '#';
          ELSE
            vschar := NULL;
          END IF;
          vsmensagem         := vsmensagem || vschar || 'PLANO DE PAGAMENTO GENERICO NAO ACEITA COBRANCA BK' || ';';
          p_regpedido.valido := FALSE;

        END IF;

      END IF;


    END IF;


    IF p_regpedido.valido = TRUE
    THEN

      vsprazos     := NULL;
      vicont       := 0;
      vnprazototal := 0;

      FOR reg IN (SELECT prazo
                    FROM (SELECT p.prazo1 prazo
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo2
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo3
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo4
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo5
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo6
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo7
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo8
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo9
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo10
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo11
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION
                          SELECT p.prazo12
                            FROM pcplpag p
                           WHERE codplpag = p_regplpagetico.codplpag
                          UNION

                          SELECT p.prazo1
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo2
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo3
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo4
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo5
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo6
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo7
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo8
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo9
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo10
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo11
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag
                          UNION
                          SELECT p.prazo12
                            FROM pcplpag p
                           WHERE codplpag = p_regplpaggenerico.codplpag)
                   WHERE rownum < 13)
      LOOP

        vicont       := vicont + 1;
        vnprazototal := vnprazototal + reg.prazo;

        IF vsprazos IS NULL
        THEN
          vsprazos := reg.prazo;
        ELSE
          vsprazos := vsprazos || ';' || reg.prazo;
        END IF;

      END LOOP;


      p_regplpag.prazo1  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   35);
      p_regplpag.prazo2  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   33);
      p_regplpag.prazo3  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   31);
      p_regplpag.prazo4  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   29);
      p_regplpag.prazo5  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   27);
      p_regplpag.prazo6  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   25);
      p_regplpag.prazo7  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   23);
      p_regplpag.prazo8  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   21);
      p_regplpag.prazo9  := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   19);
      p_regplpag.prazo10 := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   17);
      p_regplpag.prazo11 := substr(vsprazos,
                                   1,
                                   instr(vsprazos,
                                         ';',
                                         1) - 1);
      vsprazos           := substr(vsprazos,
                                   instr(vsprazos,
                                         ';',
                                         1) + 1,
                                   15);
      p_regplpag.prazo12 := substr(vsprazos,
                                   1,
                                   3);

      p_regpedido.prazomedio := vnprazototal / vicont;

    END IF;


    IF (vsmensagem IS NOT NULL)
    THEN
      proc_registralog(p_regpedido.numped,
                                   p_regpedido.numpedrca,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_regpedido.cgccli,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_regpedido.codusur,
                                   p_regpedido.dtaberturapedpalm,
                                   NULL,
                                   '2',
                                   vsmensagem || ';',
                                   NULL,
                                   NULL);

    END IF;


  EXCEPTION
    WHEN OTHERS THEN
      p_regpedido.valido := FALSE;
      proc_registralog(p_regpedido.numped,
                                   p_regpedido.numpedrca,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_regpedido.cgccli,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_regpedido.codusur,
                                   p_regpedido.dtaberturapedpalm,
                                   NULL,
                                   '2',
                                   'Erro ao validar planos de pagto Medicamentos : ' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';',
                                   NULL,
                                   NULL);

  END proc_validaplanosmed;

  PROCEDURE proc_validavenctos
  (
    p_regpedido  IN OUT t_cabped,
    p_regplpag   IN OUT t_planodepagamento,
    p_regfilial  IN     t_filial,
    p_mensagem   OUT VARCHAR2
  ) IS

    vicont       NUMBER;
    vbvalido     BOOLEAN;
    vsmensagem   VARCHAR2(1000);
    vicontparc   NUMBER;
    viparcela    NUMBER;
    vddatainicio DATE;
    vddataaux    DATE;
    vndif        NUMBER;
    vndiftot     NUMBER;
    vicontador   NUMBER;
    vnprazomedio NUMBER;
    vddtvenc     DATE;
    vddatabase   DATE;
  BEGIN

    vsmensagem := NULL;
    vicont     := 0;
    vbvalido   := TRUE;

    SELECT COUNT(*)
      INTO vicont
      FROM pcpedcvctofv p
     WHERE p.numpedrca = p_regpedido.numpedrca
       AND p.codusur = p_Regpedido.codusur
       AND p.cgccli = p_regpedido.cgccli
       AND p.dtaberturapedpalm = p_regpedido.dtaberturapedpalm;

    vddatabase := trunc(SYSDATE);
    if (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('VALIDARPRAZOMEDIOPORDTENTREGA', p_regpedido.codfilial,'N') = 'S') then
       vddatabase := nvl(p_regpedido.dtentrega, trunc(SYSDATE));
    end if;

    IF vicont > 0
    THEN



      IF vicont > p_regplpag.numparcelas
      THEN

        vbvalido := FALSE;

        vsmensagem := 'Numero de parcelas enviadas é maior que o número de parcelas permitidas';

      END IF;



      IF vbvalido = TRUE
      THEN

        viparcela := 0;

        FOR reg IN (SELECT p.numparcela,
                           p.dtvenc
                      FROM pcpedcvctofv p
                     WHERE p.numpedrca = p_regpedido.numpedrca
                       AND p.codusur = p_Regpedido.codusur
                       AND p.cgccli = p_regpedido.cgccli
                       AND p.dtaberturapedpalm = p_regpedido.dtaberturapedpalm
                     ORDER BY numparcela)
        LOOP

          viparcela := viparcela + 1;

          IF viparcela = 1
          THEN

            vddatainicio := vddatabase;
          ELSE

            vddatainicio := vddataaux;

          END IF;

          IF vicont > 1
          THEN

            IF reg.dtvenc < (vddatainicio + p_regplpag.diasminparcela)
            THEN

              vbvalido := FALSE;

              IF vsmensagem IS NULL
              THEN

                vsmensagem := 'Parcela : ' || reg.numparcela || ' enviada está com data de vencimento menor que o permitido : ' ||
                              to_date(vddatainicio + p_regplpag.diasminparcela,
                                      'dd/mm/yyyy');

              ELSE

                vsmensagem := vsmensagem || CHR(13) || ' Parcela : ' || reg.numparcela || ' enviada está com data de vencimento menor que o permitido : ' ||
                              to_date(vddatainicio + p_regplpag.diasminparcela,
                                      'dd/mm/yyyy');

              END IF;

            END IF;

            IF reg.dtvenc > (vddatainicio + p_regplpag.diasmaxparcela)
            THEN
              vbvalido := FALSE;


              IF vsmensagem IS NULL
              THEN

                vsmensagem := 'Parcela : ' || reg.numparcela || ' enviada está com data de vencimento maior que o permitido : ' ||
                              to_date(vddatainicio + p_regplpag.diasmaxparcela,
                                      'dd/mm/yyyy');

              ELSE

                vsmensagem := vsmensagem || CHR(13) || ' Parcela : ' || reg.numparcela || ' enviada está com data de vencimento maior que o permitido : ' ||
                              to_date(vddatainicio + p_regplpag.diasmaxparcela,
                                      'dd/mm/yyyy');

              END IF;


            END IF;

          END IF;

          IF reg.numparcela <= 0
          THEN
            vbvalido := FALSE;


            IF vsmensagem IS NULL
            THEN

              vsmensagem := 'Parcela : ' || reg.numparcela || ' enviada está com numero inválido !';

            ELSE

              vsmensagem := vsmensagem || CHR(13) || ' Parcela : ' || reg.numparcela || ' enviada está com numero inválido !';

            END IF;


          END IF;



          vddataaux := reg.dtvenc;

        END LOOP;

        IF vbvalido = TRUE
        THEN

          BEGIN

            INSERT INTO pcpedcvcto
              (numped,
               numparcela,
               dtvenc)
              SELECT p_regpedido.numped,
                     p.numparcela,
                     p.dtvenc
                FROM pcpedcvctofv p
               WHERE p.numpedrca = p_regpedido.numpedrca
                 AND p.codusur = p_Regpedido.codusur
                 AND p.cgccli = p_regpedido.cgccli
                 AND p.dtaberturapedpalm = p_regpedido.dtaberturapedpalm
               ORDER BY numparcela;
          EXCEPTION
            WHEN OTHERS THEN

              vbvalido := FALSE;

              IF vsmensagem IS NULL
              THEN

                vsmensagem := 'Erro ao inserir na tabela pcpedcvcto ' || SQLCODE || ' - ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              ELSE

                vsmensagem := vsmensagem || CHR(13) || 'Erro ao inserir na tabela pcpedcvcto ' || SQLCODE || ' - ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              END IF;


          END;


        END IF;


      END IF;

      --não foi enviado registro na pcpedcvctofv

    ELSE

      IF p_regfilial.aceitavendasemdtvencfv = 'S'
      THEN

        viparcela := 0;

        FOR reg IN 1 .. p_regplpag.numparcelas
        LOOP

          viparcela := viparcela + 1;

          IF viparcela = 1
          THEN

            vddatainicio := vddatabase;
          ELSE

            vddatainicio := vddataaux;

          END IF;

          vddtvenc := vddatainicio + p_regplpag.diasminparcela;

          BEGIN

            INSERT INTO pcpedcvcto
              (numped,
               numparcela,
               dtvenc)
            VALUES
              (p_regpedido.numped,
               viparcela,
               vddtvenc);
          EXCEPTION
            WHEN OTHERS THEN

              vbvalido := FALSE;

              IF vsmensagem IS NULL
              THEN

                vsmensagem := 'Erro ao inserir na tabela pcpedcvcto ' || SQLCODE || ' - ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              ELSE

                vsmensagem := vsmensagem || CHR(13) || 'Erro ao inserir na tabela pcpedcvcto ' || SQLCODE || ' - ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              END IF;


          END;


          vddataaux := vddtvenc;

        END LOOP;

      ELSE

        vbvalido := FALSE;

        IF vsmensagem IS NULL
        THEN

          vsmensagem := 'De acordo com parâmetro aceitavendasemdtvencfv é ncessário o envio de dados pcpedcvctoFV ';

        ELSE

          vsmensagem := vsmensagem || CHR(13) || 'De acordo com parâmetro aceitavendasemdtvencfv é ncessário o envio de dados pcpedcvctoFV ';

        END IF;

      END IF;

    END IF;


    IF vbvalido = TRUE
    THEN

      --prazo medio

      vndif      := 0;
      vndiftot   := 0;
      vicontparc := 0;

      FOR regprazo IN (SELECT numparcela,
                              dtvenc
                         FROM pcpedcvcto
                        WHERE numped = p_regpedido.numped)
      LOOP

        vndif := regprazo.dtvenc - vddatabase;

        vndiftot := vndiftot + vndif;

        vicontparc := vicontparc + 1;

      END LOOP;

      vnprazomedio := trunc(vndiftot / vicontparc);

      IF vnprazomedio > p_regplpag.numdias
      THEN

        vbvalido := FALSE;

        IF vsmensagem IS NULL
        THEN

          vsmensagem := 'Prazo medio: ' || vnprazomedio || ' maior que o permitido : ' || p_regplpag.numdias;

        ELSE

          vsmensagem := vsmensagem || CHR(13) || 'Prazo medio: ' || vnprazomedio || ' maior que o permitido : ' || p_regplpag.numdias;

        END IF;

      ELSE
        p_regpedido.prazomedio := vnprazomedio;
      END IF;

      p_regpedido.percplpag := 0;


      SELECT COUNT(*)
        INTO vicontador
        FROM PCPLPAGVARIAVELJUROS p
       WHERE p.codplpag = p_regplpag.codplpag
         AND p.prazomedioinicial <= p_regpedido.prazomedio
         AND p.prazomediofinal >= p_regpedido.prazomedio;

      IF vicontador = 1
      THEN

        SELECT nvl(p.percdesc,0)
          INTO p_regpedido.percplpag
          FROM PCPLPAGVARIAVELJUROS p
         WHERE p.codplpag = p_regplpag.codplpag
           AND p.prazomedioinicial <= p_regpedido.prazomedio
           AND p.prazomediofinal >= p_regpedido.prazomedio;

      END IF;



      SELECT COUNT(*)
        INTO vicontador
        FROM pcplpag p
       WHERE codplpag = 99;

      IF vicontador = 1
      THEN

        SELECT p.prazo1,
               p.prazo2,
               p.prazo3,
               p.prazo4,
               p.prazo5,
               p.prazo6,
               p.prazo7,
               p.prazo8,
               p.prazo9,
               p.prazo10,
               p.prazo11,
               p.prazo12
          INTO p_regplpag.prazo1,
               p_regplpag.prazo2,
               p_regplpag.prazo3,
               p_regplpag.prazo4,
               p_regplpag.prazo5,
               p_regplpag.prazo6,
               p_regplpag.prazo7,
               p_regplpag.prazo8,
               p_regplpag.prazo9,
               p_regplpag.prazo10,
               p_regplpag.prazo11,
               p_regplpag.prazo12
          FROM pcplpag p
         WHERE codplpag = 99;
      END IF;


    END IF;

    IF vbvalido = FALSE
    THEN

      p_regpedido.valido := FALSE;
      p_mensagem         := vsmensagem;

    END IF;



  END proc_validavenctos;

  FUNCTION func_HoraDigitacaoPedido
  (
    p_Regfilial IN t_filial,
    p_mensagem  OUT VARCHAR2
  ) RETURN BOOLEAN IS



    vbresult                BOOLEAN := TRUE;
    vdhorainicialimportacao DATE;
    vdhorafinalimportacao   DATE;

  BEGIN


    SELECT TO_DATE(TO_CHAR(TRUNC(SYSDATE),
                           'dd/mm/yyyy') || TO_CHAR(horainicialimportacaoped,
                                                    'hh24:mi'),
                   'dd/mm/yyyy hh24:mi') HoraInicialDigitacaoPed,
           CASE GREATEST(TO_DATE(TO_CHAR(TRUNC(SYSDATE),
                                     'dd/mm/yyyy') || TO_CHAR(horainicialimportacaoped,
                                                              'hh24:mi'),
                             'dd/mm/yyyy hh24:mi'),
                     TO_DATE(TO_CHAR(TRUNC(SYSDATE),
                                     'dd/mm/yyyy') || TO_CHAR(horafinalimportacaoped,
                                                              'hh24:mi'),
                             'dd/mm/yyyy hh24:mi'))
             WHEN TO_DATE(TO_CHAR(TRUNC(SYSDATE),
                              'dd/mm/yyyy') || TO_CHAR(horainicialimportacaoped,
                                                       'hh24:mi'),
                      'dd/mm/yyyy hh24:mi') THEN
              TO_DATE(TO_CHAR((TRUNC(SYSDATE) + 1),
                              'dd/mm/yyyy') || TO_CHAR(horafinalimportacaoped,
                                                       'hh24:mi'),
                      'dd/mm/yyyy hh24:mi')
             ELSE
              TO_DATE(TO_CHAR(TRUNC(SYSDATE),
                              'dd/mm/yyyy') || TO_CHAR(horafinalimportacaoped,
                                                       'hh24:mi'),
                      'dd/mm/yyyy hh24:mi')
           END HoraFinalDigitacaoPed
      INTO vdhorainicialimportacao,
           vdhorafinalimportacao
      FROM PCFILIAL
     WHERE CODIGO = p_Regfilial.codigo;

    p_mensagem := NULL;

    vbResult := (SYSDATE >= vdHoraInicialimportacao) AND (SYSDATE <= vdHoraFinalimportacao);

    IF vbresult = FALSE
    THEN
      p_mensagem := 'Horário limite para digitação do pedido ultrapassado.#' || 'Verifique rotina 535.';
    END IF;

    RETURN vbresult;

  END func_HoraDigitacaoPedido;

  FUNCTION func_retornaUfEntEnd(p_codendent in number,
                                p_codcli    in NUMBER) RETURN VARCHAR2 IS

    vsUfEnt   PCCLIENT.ESTENT%TYPE;
  BEGIN

    BEGIN
      SELECT ESTENT
        INTO VSUFENT
        FROM PCCLIENTENDENT
       WHERE CODCLI = P_CODCLI
         AND CODENDENTCLI = P_CODENDENT;

      IF VSUFENT IS NULL THEN
        SELECT ESTENT
          INTO VSUFENT
          FROM PCCLIENT
         WHERE CODCLI = P_CODCLI;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        VSUFENT := '';
    END;

    RETURN VSUFENT;
  END;

  FUNCTION func_validaautorizacaopcautorc
  (
    p_regcliente IN t_clientepedido,
    p_codusur    IN pcpedc.codusur%TYPE,
    p_regfilial  IN t_filial,
    p_vldisp     IN NUMBER,
    p_vlatend    IN NUMBER
  ) RETURN NUMBER IS

    vnvlliberado NUMBER;

  BEGIN

    BEGIN

      SELECT SUM(pcautorc.vlliberado)
        INTO vnvlliberado
        FROM pcautorc,
             pcempr
       WHERE ((pcautorc.codcli = p_regcliente.codcli) OR
             (p_regfilial.somacreditocliprincipal = 'S' AND (pcautorc.codcli IN (SELECT pcclient.codcli
                                                                                    FROM pcclient
                                                                                   WHERE codcliprinc = p_regcliente.codcliprinc))))
         AND pcautorc.codusur = p_codusur
         AND pcautorc.codfunc = pcempr.matricula
         AND pcautorc.liberalimcred = 'S'
         AND pcautorc.dtutilizacao IS NULL
         AND pcautorc.codfuncutilizacao IS NULL
         AND (p_vldisp + nvl(pcautorc.vlliberado,
                             0)) >= p_vlatend
         AND rownum = 1
       ORDER BY data;
    EXCEPTION
      WHEN OTHERS THEN

        vnvlliberado := 0;

    END;

    RETURN vnvlliberado;



  END func_validaautorizacaopcautorc;


  PROCEDURE proc_atualizarpcautorc
  (
    p_numped     IN pcpedc.numped%TYPE,
    p_codusur    IN pcpedc.codusur%TYPE,
    p_codcli     IN pcpedc.codcli%TYPE,
    p_vlpendente IN NUMBER,
    p_limcred    IN NUMBER
  ) IS

    vnnumpedido pcautorc.numpedido%TYPE;

  BEGIN


    SELECT numpedido
      INTO vnnumpedido
      FROM pcautorc
     WHERE codusur = p_codusur
       AND codcli = p_codcli
       AND codfuncutilizacao IS NULL
       AND dtutilizacao IS NULL
       AND rownum = 1
     ORDER BY data;


    FOR reg IN (SELECT *
                  FROM pcautorc
                 WHERE numpedido = vnnumpedido
                   AND codusur = p_codusur
                   AND codcli = p_codcli
                   FOR UPDATE)
    LOOP

      EXIT;
    END LOOP;

    UPDATE pcautorc
       SET limcred           = p_limcred,
           vlpendente        = p_vlpendente,
           dtutilizacao      = trunc(SYSDATE),
           codfuncutilizacao = 8888,
           numpedutilizacao  = p_numped
     WHERE numpedido = vnnumpedido
       AND codusur = p_codusur
       AND codcli = p_codcli
       AND codfuncutilizacao IS NULL
       AND dtutilizacao IS NULL;


  END proc_atualizarpcautorc;

  FUNCTION usacfopvendanatv10(p_codcli in pcclient.codcli%type, p_codfilial in pcfilial.codigo%type)
    RETURN VARCHAR2 IS
    vsRadicalCli         varchar2(8);
    vsRadicalFilial      varchar2(8);
  BEGIN

    SELECT SUBSTR(TRANSLATE(C.CGCENT, 'X-.,/', 'X'), 1, 8) INTO vsRadicalCli FROM PCCLIENT C WHERE CODCLI = p_codcli;
    SELECT SUBSTR(TRANSLATE(C.CGC, 'X-.,/', 'X'), 1, 8) INTO vsRadicalFilial FROM PCFILIAL C WHERE CODIGO = p_codfilial;

    IF vsRadicalCli = vsRadicalFilial THEN
      RETURN 'N';
    ELSE
      RETURN 'S';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
  END;

  FUNCTION func_existelimitecliente
  (
    p_regpedido       IN t_cabped,
    p_regcliente      IN t_clientepedido,
    p_regfilial       IN t_filial,
    p_vltotped        IN NUMBER,
    p_saldodisponivel OUT NUMBER
  ) RETURN BOOLEAN IS

									
									
									
    vnvltotped               NUMBER;

    vnVLBONIFIC              NUMBER;
    vbValidarLimiteCredito   VARCHAR2(1);

  BEGIN

    p_saldodisponivel := 0;
						   
    vnvltotped        := p_vltotped;
    
    p_saldodisponivel := PKG_LIMITECREDITO.RETORNA_LIMITE_CRED_DISPONIVEL(p_regcliente.codcli);
    
    SELECT NVL(PCCOB.VALIDALIMITECREDITO, 'S')
      INTO vbValidarLimiteCredito
      FROM PCCOB
     WHERE CODCOB = p_regpedido.codcob;

    IF (vnvltotped > p_saldodisponivel) AND
       (p_regcliente.codcli not in (1,2,3)) and
       (p_regpedido.condvenda not in (4,5,8,11,20)) and
        not(((p_regpedido.CODCOB = 'D') or
            (p_regpedido.CODCOB = 'DH') or
            (p_regpedido.CODCOB = 'CAR') or
            (isCobrancaCartao(p_regpedido.CODCOB))) and
          (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICALIMCREDCODCOBD',99,'N') = 'N'))
          and (vbValidarLimiteCredito = 'S')
          
    THEN

      IF p_saldodisponivel + func_validaautorizacaopcautorc(p_regcliente,
                                                            p_regpedido.codusur,
                                                            p_regfilial,
                                                            p_saldodisponivel,
                                                            vnvltotped) >= vnvltotped
      THEN

													
									 
						  
									   
					  
												   
									   
									 

        proc_atualizarpcautorc(p_regpedido.numped,
                               p_regpedido.codusur,
                               p_regpedido.codcli,
                               (NVL(PKG_LIMITECREDITO.RETORNA_CONTAS_RECEBER_ABERTO(p_regcliente.codcli),
                                    0) + NVL(PKG_LIMITECREDITO.RETORNA_PEDIDOS_FATURAR(p_regcliente.codcli),
                                              0)),
                               p_regcliente.limcred);

								 
							
										
					   
											 
								 
																				
																						 
														
													
																		 
													 
			

        RETURN TRUE;
							
										
					   
											 
								 
																				
																						 
													 

			   

										
						  
					 
										   
																			  
																					   
									  
											

																					   

      ELSE
        RETURN FALSE;
									 
						  
									   
					  
												   
									
																					


										   

																					 
							
										
							   
													
											  
											
										
																					   
																								
																			 
											  
																			 
														
													
																		 
													 

			

																					 
						  
									  
							 
												  
											
										  
									  
																					 
																							  
																				  
											
												   

			   

      END IF;


													  
																			  
															   
														 
																  
												  
																	 
																	 
																					  

												   
																

															
											 
												 
														 
											
											
											 
														 
																							
		  

																		   
																				  
																		  
																				
																					   
			


													
													 
													
															   
																	   
													
													   


					  

			
					   
			   
		  
					
			 

    ELSE

											  
		  

													
									 
						  
									   
					  
														 
												  
																																  
									   
									 

									   
										   

								 
							
										
					   
												   
											
																													
								 
																				
																						 
																			 
														
													
																		 
													 

			

								 
						  
									  
					 
												 
										  
																												  
							   
																			  
																					   
								   
												   

			   

										 
						  
							   
											  
													   
															   
																					 
																							  
									   
											

																		 

		  

													
									 
						  
									   
					  
														 
												  
																																  
									
																					

									   
																				   
						  
									  
							 
														
												 
																																
											
										  
									  
																					 
																							  
																				  
											
												   

			 

								  
						   
					 
																									   

												
																			  
															   
														 
																  
												  
																	 
																	 
																					  

												   
																

															
											 
												 
														 
											
											
											 
														 
																							
		  

																		   
																				  
																		  
																				
																					   
			


													
													 
													
															   
																	   
													
													   


      RETURN TRUE;

			
					   
			   
		  
					
    END IF;


		   

  EXCEPTION
    WHEN OTHERS THEN

      proc_registralog(p_regpedido.numped,
                                   p_regpedido.numpedrca,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_regpedido.cgccli,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_regpedido.codusur,
                                   p_regpedido.dtaberturapedpalm,
                                   NULL,
                                   '2',
                                   SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';',
                                   NULL,
                                   null);
      RETURN FALSE;

  END func_existelimitecliente;

  FUNCTION func_calculanumparcplpag(p_regplpag IN t_planodepagamento) RETURN INTEGER IS
    vnnumparcelas INTEGER;
  BEGIN
    vnnumparcelas := 1;
    IF p_regplpag.prazo1 > 0
    THEN
      vnnumparcelas := 1;
      IF p_regplpag.prazo2 > 0
      THEN
        vnnumparcelas := vnnumparcelas + 1;
        IF p_regplpag.prazo3 > 0
        THEN
          vnnumparcelas := vnnumparcelas + 1;
          IF p_regplpag.prazo4 > 0
          THEN
            vnnumparcelas := vnnumparcelas + 1;
            IF p_regplpag.prazo5 > 0
            THEN
              vnnumparcelas := vnnumparcelas + 1;
              IF p_regplpag.prazo6 > 0
              THEN
                vnnumparcelas := vnnumparcelas + 1;
                IF p_regplpag.prazo7 > 0
                THEN
                  vnnumparcelas := vnnumparcelas + 1;
                  IF p_regplpag.prazo8 > 0
                  THEN
                    vnnumparcelas := vnnumparcelas + 1;
                    IF p_regplpag.prazo9 > 0
                    THEN
                      vnnumparcelas := vnnumparcelas + 1;
                      IF p_regplpag.prazo10 > 0
                      THEN
                        vnnumparcelas := vnnumparcelas + 1;
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
    RETURN vnnumparcelas;
  END func_calculanumparcplpag;


  PROCEDURE proc_GravaLogConvEmbalagem
  (
    p_NUMPED                    IN pcpedc.numped%TYPE,
    p_CODFILIAL                 IN pcpedc.codfilial%TYPE,
    p_CODPROD                   IN pcpedi.codprod%TYPE,
    p_QTESTGER                  IN pcest.qtestger%TYPE,
    p_mensagem                  OUT VARCHAR2
  ) IS

    vnQTESTGER_DEPOIS      NUMBER;
    vnNUMTRANSVENDA        NUMBER;
    vnCODPROD_MASTER       NUMBER;
    vnQT_MASTER            NUMBER;
    vnQTESTGER_MASTER      NUMBER;
    vbBuscouDadosConversao BOOLEAN;
    vicont                 NUMBER;
    vsprograma             VARCHAR2(80);
    vnqt                   NUMBER;

  BEGIN
    --Buscar dados da Conversão
    vbBuscouDadosConversao := FALSE;
    p_mensagem             := NULL;

    SELECT COUNT(*)
      INTO vicont
      FROM PCMOV
     WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
       AND PCMOV.CODPROD = p_CODPROD
       AND PCMOV.CODFILIAL = p_CODFILIAL
       AND NVL(PCMOV.CODOPER,
               'X') = 'EP'
     GROUP BY PCMOV.NUMTRANSVENDA
     ORDER BY PCMOV.NUMTRANSVENDA DESC;

    IF vicont IS NOT NULL
    THEN

      BEGIN
        SELECT PCMOV.NUMTRANSVENDA,
               SUM(PCMOV.QT) QT
          INTO vnNUMTRANSVENDA,
               vnqt
          FROM PCMOV
         WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
           AND PCMOV.CODPROD = p_CODPROD
           AND PCMOV.CODFILIAL = p_CODFILIAL
           AND NVL(PCMOV.CODOPER,
                   'X') = 'EP'
         GROUP BY PCMOV.NUMTRANSVENDA
         ORDER BY PCMOV.NUMTRANSVENDA DESC;
      EXCEPTION
        WHEN OTHERS THEN
          vnNUMTRANSVENDA := NULL;
          vnqt            := 0;
      END;

      vnQTESTGER_DEPOIS := p_QTESTGER + vnQT;

      IF vnnumtransvenda IS NOT NULL
      THEN

        SELECT COUNT(*)
          INTO vicont
          FROM PCMOV,
               PCEST
         WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
           AND PCMOV.NUMTRANSVENDA = vnNUMTRANSVENDA
           AND PCMOV.CODFILIAL = p_CODFILIAL
           AND PCMOV.CODPROD = PCEST.CODPROD
           AND PCMOV.CODFILIAL = PCEST.CODFILIAL
           AND NVL(PCMOV.CODOPER,
                   'X') = 'SP';

        IF vicont <> 0
        THEN

          SELECT PCMOV.CODPROD,
                 PCMOV.QT,
                 PCEST.QTESTGER
            INTO vnCODPROD_MASTER,
                 vnQT_MASTER,
                 vnQTESTGER_MASTER
            FROM PCMOV,
                 PCEST
           WHERE PCMOV.DTMOV = TRUNC(SYSDATE)
             AND PCMOV.NUMTRANSVENDA = vnNUMTRANSVENDA
             AND PCMOV.CODFILIAL = p_CODFILIAL
             AND PCMOV.CODPROD = PCEST.CODPROD
             AND PCMOV.CODFILIAL = PCEST.CODFILIAL
             AND NVL(PCMOV.CODOPER,
                     'X') = 'SP';

          vbBuscouDadosConversao := TRUE;
        END IF;
      END IF;
    END IF;

    IF vbBuscouDadosConversao = TRUE
    THEN


      BEGIN
        -- utilização do rownum. Se a alteração for disparada por um usuário com permissão de sysdba
        -- ou for um job cadastrado por este usuário, o USERENV('SESSIONID') deste usuário é null.
        SELECT SUBSTR(program,
                      1,
                      80)
          INTO vsprograma
          FROM usuarios_logados
         WHERE audsid = USERENV('SESSIONID')
           AND rownum = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsprograma := NULL;
      END;


      --Gravação de log do acesso a esta permissão

      INSERT INTO PCLOGALTERACAODADOS
        (DATA,
         CODFUNC,
         CODROTINA,
         TABELA,
         COLUNA,
         TIPOVALOR,
         VALORNUM,
         VALORNUMANT,
         VALORALFA,
         VALORALFAANT,
         USACTRLACESSO,
         CODCTRLACESSO,
         OBSERVACOES,
         MAQUINA,
         PROGRAMA,
         TERMINAL,
         OSUSER)
      VALUES
        (SYSDATE,
         8888,
         2596,
         'PCEST',
         'QTESTGER',
         'N',
         vnqtestger_depois,
         p_qtestger,
         NULL,
         NULL,
         'S',
         NULL,
         'CONV. EMB. PROD. ' || ' PED.: ' || p_NUMPED,
         'PRODUCAO',
         vsPROGRAMA,
         p_numped,
         p_codprod);


      INSERT INTO PCLOGALTERACAODADOS
        (DATA,
         CODFUNC,
         CODROTINA,
         TABELA,
         COLUNA,
         TIPOVALOR,
         VALORNUM,
         VALORNUMANT,
         VALORALFA,
         VALORALFAANT,
         USACTRLACESSO,
         CODCTRLACESSO,
         OBSERVACOES,
         MAQUINA,
         PROGRAMA,
         TERMINAL,
         OSUSER)
      VALUES
        (SYSDATE,
         8888,
         2596,
         'PCEST',
         'QTESTGER',
         'N',
         vnqtestger_master,
         vnQTESTGER_MASTER + vnQT_MASTER,
         NULL,
         NULL,
         'S',
         NULL,
         'CONV. EMB. PROD. ' || ' PED.: ' || p_NUMPED,
         'REQUISICAO',
         vsPROGRAMA,
         p_numped,
         vncodprod_master);


    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao gravar log de conversão de embalagem : ' || SQLCODE || ' ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

  END proc_GravaLogConvEmbalagem;


   PROCEDURE proc_converte_estoque
  (
    p_condvenda    IN pcpedc.condvenda%TYPE,
    p_numped       IN pcpedc.numped%TYPE,
    p_codfilial    IN pcpedc.codfilial%TYPE,
    p_codprod      IN pcpedi.codprod%TYPE,
    p_qtsolicitada IN NUMBER,
    p_qtestger     IN NUMBER,
    p_qtatendida   OUT NUMBER,
    p_mensagem     OUT VARCHAR2
  ) IS


    vnqtatendida    NUMBER;
    vncodprodmaster pcprodut.codprodmaster%TYPE;
    vicont          NUMBER;
    vsmensagem      VARCHAR2(1000);
    vsmensagemlog   VARCHAR2(1000);

  BEGIN

    vnqtatendida := 0;

    --if p_unidade = 'UN' and
    IF gregpcconsum.usaconversaoembalagem = 'S'
    THEN

      --Verificar se produto é filho de algum outro produto}
      SELECT NVL(CODPRODMASTER,
                 CODPROD) CODPRODMASTER
        INTO vncodprodmaster
        FROM PCPRODUT
       WHERE CODPROD = P_CODPROD;

      IF p_codprod <> vncodprodmaster
      THEN

        --verifica se pai existe
        SELECT COUNT(*)
          INTO vicont
          FROM PCPRODUT
         WHERE CODPROD = vncodprodmaster;

        IF vicont > 0
        THEN

          prc_conversao_estoque_pacote(p_condvenda,
                                       p_codfilial,
                                       p_codprod,
                                       p_qtsolicitada,
                                       vsmensagem,
                                       0,
                                       8888);

          IF vsmensagem <> 'CONVERSAO REALIZADA COM SUCESSO!!!'
          THEN
            p_mensagem := 'Não foi possível converter estoque de caixa para o produto solicitado : ' || p_codprod || CHR(13) || 'Erro: ' || vsmensagem;

            vnqtatendida := p_qtsolicitada;

          ELSE

            proc_GravaLogConvEmbalagem(p_numped,
                                       p_codfilial,
                                       p_codprod,
                                       p_qtestger,
                                       vsmensagemlog);

          END IF;


        ELSE
          vnqtatendida := p_qtsolicitada;
        END IF;

      ELSE
        vnqtatendida := p_qtsolicitada;
      END IF;

    ELSE

      vnqtatendida := p_qtsolicitada;
    END IF;
    p_qtatendida := vnqtatendida;

  END proc_converte_estoque;

  FUNCTION ValidarTV1comBNF(p_regpedido  IN OUT t_cabped,
                            p_msg        OUT VARCHAR2)
    RETURN BOOLEAN
  IS
    vbResult     BOOLEAN;
    vnTOTAL_BNF  NUMBER;
    vnTOTAL_TV1  NUMBER;
    vnQTRESTR    NUMBER;

    vsPERMITEITEMBNFTV1 VARCHAR2(1);
    vsBLOQUEARTV1BNFFV  VARCHAR2(1);
    vnVLMINTV1BNF       NUMBER;
    vnVLBNFMAXTV1       NUMBER;
    vsSEPARARRESTRICAOTRANSP VARCHAR2(1);

  BEGIN
    vbResult := TRUE;
    p_msg := 'OK';
    vnTOTAL_BNF := 0;
    vnTOTAL_TV1 := 0;
    vnQTRESTR   := 0;

    BEGIN
      SELECT SUM(qt * pbonific)
        INTO vnTOTAL_BNF
        FROM pcpedi
       WHERE numped = p_regpedido.numped
         AND nvl(bonific,'N') <> 'N';

      vnTOTAL_BNF := NVL(vnTOTAL_BNF,0);

      SELECT SUM(qt * pvenda)
        INTO vnTOTAL_TV1
        FROM pcpedi
       WHERE numped = p_regpedido.numped
         AND nvl(bonific,'N') = 'N';

      vnTOTAL_TV1 := NVL(vnTOTAL_TV1,0);

      SELECT COUNT(*)
        INTO vnQTRESTR
        FROM (SELECT DISTINCT nvl(pcprodut.restricaotransp,'N') -- RAFAEL TV1
                FROM pcprodut, pcpedi
               WHERE pcpedi.codprod = pcprodut.codprod
                 AND pcpedi.numped = p_regpedido.numped);

    EXCEPTION
      WHEN OTHERS THEN
        p_msg := 'Ocorreu um erro ao tentar fazer a leitura de itens BNF no pedido.' ||
                 'Msg. original: ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        RETURN vbResult;
    END;

    vsPERMITEITEMBNFTV1 := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('PERMITEITEMBNFTV1','99','N');
    vsBLOQUEARTV1BNFFV := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('BLOQUEARTV1BNFFV','99','N');
    vnVLMINTV1BNF := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('VLMINTV1BNF','99',0);
    vnVLBNFMAXTV1 := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('VLBNFMAXTV1','99',0);
    vsSEPARARRESTRICAOTRANSP := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('SEPARARPRODCOMRESTRICAOTRANSP',p_regpedido.codfilial,'N');

    IF (vsPERMITEITEMBNFTV1 = 'S')
      AND (vnTOTAL_BNF > 0)
      AND p_regpedido.condvenda = 1
    THEN

      IF vsBLOQUEARTV1BNFFV = 'S' THEN
        p_regpedido.posicao := 'B';
        p_regpedido.codmotivo := 18;
        p_regpedido.motivoposicao := 'Pedido com itens bonificados bloqueado.';
      END IF;

      IF (vnQTRESTR > 1)
        AND (vsSEPARARRESTRICAOTRANSP = 'S')
      THEN
        vbResult := FALSE;
        p_msg := 'Quando houver itens BNF em um pedido TV1, não serão permitidas diversas restriçõa de transporte.';
      END IF;

      IF vnTOTAL_TV1 < vnVLMINTV1BNF THEN
        vbResult := FALSE;
        p_msg := 'Valor mínimo em venda para pedidos TV1 com BNF não foi atingido(parâmetro: "VLMINTV1BNF" = R$' || TO_CHAR(vnVLMINTV1BNF) || ').';
      END IF;

      IF (vnTOTAL_BNF > vnVLBNFMAXTV1)
       AND (vnVLBNFMAXTV1 > 0)
      THEN
        vbResult := FALSE;
        p_msg := 'Valor máximo em BNF permitido para pedidos TV1 foi ultrapassado(parâmetro: "VLBNFMAXTV1" = R$' || TO_CHAR(vnVLBNFMAXTV1) || ').';
      END IF;

      IF (vnTOTAL_BNF > 0)
        AND (vnTOTAL_TV1 <= 0)
      THEN
        vbResult := FALSE;
        p_msg := 'Não é permitido um pedido de venda conter apenas itens bonificados.';
      END IF;

    ELSIF (vnTOTAL_BNF > 0)
      AND (vsPERMITEITEMBNFTV1 = 'N')
      AND p_regpedido.condvenda = 1
    THEN
      vbResult := FALSE;
      p_msg := 'Parametrização do sistema não permite item BNF em um pedido TV1(parâmetro: "PERMITEITEMBNFTV1").';

    END IF;

    RETURN vbRESULT;

  END ValidarTV1comBNF;

    PROCEDURE proc_RebaixarCMV
  (
    p_numped    IN NUMBER,
    p_data      IN DATE,
    p_codfilial IN VARCHAR2,
    P_CONDVENDA IN PCPEDC.CONDVENDA%TYPE DEFAULT NULL
  ) IS


    vbutilizouverba BOOLEAN;
    at_vlverbacmv  pcpedc.vlverbacmv%TYPE;



  BEGIN





    FOR reg_itens IN (SELECT pcpedi.codprod,
                             PCPEDI.QT,
                             PCPEDI.NUMSEQ
                        FROM pcpedi
                       WHERE numped = p_numped)
    LOOP

      vbutilizouverba := FALSE;

      FOR reg IN (SELECT PCVERBA.NUMVERBA,
                         PCVERBA.DTEMISSAO,
                         PCVERBA.DTVENC,
                         pcverba.codconta,
                         (SELECT SUM((NVL(PCPEDI.VLVERBACMV,
                                          0) * NVL(PCPEDI.QT,
                                                    0)))
                            FROM PCPEDI,
                                 PCPEDC
                           WHERE PCPEDC.DATA BETWEEN PCAPLICVERBAI.DTINICIOVIGENCIA AND PCAPLICVERBAI.DTFIMVIGENCIA
                             AND PCPEDI.DATA BETWEEN PCAPLICVERBAI.DTINICIOVIGENCIA AND PCAPLICVERBAI.DTFIMVIGENCIA
                             AND PCPEDC.DTCANCEL IS NULL
                             AND PCPEDC.CONDVENDA <> 4
                             AND PCPEDC.POSICAO <> 'C'
                             AND PCPEDC.POSICAO NOT IN ('P', 'B', 'C')
                             AND PCPEDI.NUMPED = PCPEDC.NUMPED
                             AND PCPEDI.NUMVERBAREBCMV = PCVERBA.NUMVERBA
                             AND PCPEDI.CODPROD = PCAPLICVERBAI.CODPROD
                             AND (pcaplicverbai.condvenda = PCPEDC.condvenda OR nvl(pcaplicverbai.condvenda,0) = 0)
                             AND (( PCAPLICVERBAI.CODCLI = PCPEDC.codcli) OR (PCAPLICVERBAI.CODCLI IS NULL))
                           ) VLVERBAUTILIZ,
                         PCAPLICVERBAI.VLAPLIC,
                         decode(pcaplicverbai.vlaplicunitario,
                                NULL,
                                (nvl(PCAPLICVERBAI.VLAPLIC,
                                     0) / greatest(nvl(PCAPLICVERBAI.QTVENDA,
                                               0),1)),
                                pcaplicverbai.vlaplicunitario) VLVERBA_ITEM,
                         pcaplicverbai.Vlaplicunitario
                    FROM PCVERBA,
                         PCAPLICVERBAI
                   WHERE p_DATA BETWEEN PCAPLICVERBAI.DTINICIOVIGENCIA AND PCAPLICVERBAI.DTFIMVIGENCIA
                     AND PCVERBA.NUMVERBA = PCAPLICVERBAI.NUMVERBA
                     AND PCAPLICVERBAI.CODPROD = reg_itens.CODPROD
                     AND pcaplicverbai.codfilial = p_codfilial
                     AND (pcaplicverbai.condvenda = p_condvenda OR
                          nvl(pcaplicverbai.condvenda,0) = 0)
                AND (( PCAPLICVERBAI.CODCLI in (SELECT CODCLI FROM PCPEDC WHERE PCPEDC.NUMPED = p_numped)) OR (PCAPLICVERBAI.CODCLI IS NULL))
                     AND pcverba.dtapuracao IS NULL)
     LOOP


        IF nvl(reg.numverba,
               0) <> 0
           AND vbutilizouverba = FALSE
        THEN


          --Verba a apurar
          IF reg.codconta = gregpcconsum.CODCONTAREBAIXACMVAAPURAR
          THEN


            UPDATE PCPEDI
               SET VLCUSTOFIN     = nvl(vlcustofin,
                                        0) - nvl(reg.VLAPLICUNITARIO,
                                                 0),
                   VLCUSTOREAL    = nvl(VLCUSTOREAL,
                                        0) - nvl(reg.VLAPLICUNITARIO,
                                                 0),
                   VLVERBACMV     = nvl(reg.VLAPLICUNITARIO,
                                        0),
                   numverbarebcmv = reg.numverba
             WHERE NUMPED = P_NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;


            vbutilizouverba := TRUE;

            -- Verba valor definido
          ELSIF reg.codconta = gregpcconsum.codcontarebaixacmv
          THEN

            IF Round(nvl(reg.VLVERBAUTILIZ,
                         0),
                     2) < Round(nvl(reg.VLAPLIC,
                                    0),
                                2)
            THEN

              FOR reg_verba IN (SELECT NUMVERBA
                                  FROM PCAPLICVERBAI
                                 WHERE NUMVERBA = reg.NUMVERBA
                                   FOR UPDATE)
              LOOP

                EXIT;

              END LOOP;

              IF Round((reg_itens.qt * nvl(reg.VLVERBA_ITEM,
                                           0)),
                       2) < Round((nvl(reg.VLAPLIC,
                                       0) - nvl(reg.VLVERBAUTILIZ,
                                                 0)),
                                  2)
              THEN

                UPDATE PCPEDI
                   SET VLCUSTOREAL    = nvl(VLCUSTOREAL,
                                            0) - nvl(reg.vlverba_item,
                                                     0),
                       VLCUSTOFIN     = nvl(VLCUSTOFIN,
                                            0) - nvl(reg.vlverba_item,
                                                     0),
                       VLVERBACMV     = nvl(reg.vlverba_item,
                                            0),
                       numverbarebcmv = reg.numverba
                 WHERE NUMPED = P_NUMPED
                   AND CODPROD = REG_ITENS.CODPROD
                   AND NUMSEQ = REG_ITENS.NUMSEQ;

                vbutilizouverba := TRUE;

              ELSE
                if (round((Round((nvl(reg.VLAPLIC,
                                                        0) - nvl(reg.VLVERBAUTILIZ,
                                                                  0)),
                                                   2) / reg_itens.qt),
                                            2) > 0) then
                  reg.vlverba_item := round((Round((nvl(reg.VLAPLIC,
                                                        0) - nvl(reg.VLVERBAUTILIZ,
                                                                  0)),
                                                   2) / reg_itens.qt),
                                            2);

                  -- 1299.122165.2015
                  IF greatest(nvl(reg.vlverba_item,0), 0) <> 0 THEN
                    UPDATE PCPEDI
                       SET VLCUSTOREAL    = nvl(VLCUSTOREAL,
                                                0) - nvl(reg.vlverba_item,
                                                         0),
                           VLCUSTOFIN     = nvl(VLCUSTOFIN,
                                                0) - nvl(reg.vlverba_item,
                                                         0),
                           VLVERBACMV     = nvl(reg.vlverba_item,
                                                0),
                           numverbarebcmv = reg.numverba
                     WHERE NUMPED = P_NUMPED
                       AND CODPROD = REG_ITENS.CODPROD
                       AND NUMSEQ = REG_ITENS.NUMSEQ;


                    vbutilizouverba := TRUE;
                  END IF;
               END IF;

              END IF;
            END IF;
          END IF;
        END IF;

      END LOOP;

    END LOOP;

    SELECT  SUM(NVL(pcpedi.vlverbacmv,
                     0) * NVL(pcpedi.qt,
                              0))  --1
        INTO  at_vlverbacmv --1
        FROM pcpedi
       WHERE pcpedi.numped = P_NUMPED
     AND   PCPEDI.QT > 0;

    UPDATE pcpedc
         SET
             vlverbacmv  = at_vlverbacmv
       WHERE numped = P_NUMPED;


  END proc_RebaixarCMV;

  PROCEDURE proc_processarabatimento
  (
    p_regpedido  IN OUT t_cabped,
    p_regcliente IN t_clientepedido,
    p_regregiao  IN t_regiaocliente,
    p_regfilial  IN t_filial,
    p_regrca     IN t_rca,
    p_regplpag   IN t_planodepagamento,
    p_vltotped   IN OUT NUMBER
  ) IS



    vnvldescitem           NUMBER;
    vnvldescabatimento_tot NUMBER;
    vbCalculouPerDescAbat  BOOLEAN;

    --  vnvltotal              pcpedc.vltotal%type;
    --  vnvlatend              pcpedc.vlatend%type;


    vnperfretecmv     pcpedi.perfretecmv%TYPE;
    vnCUSTOFINEST     pcpedi.custofinest%TYPE;
    vntxvenda         pcpedi.txvenda%TYPE;
    vnperdesccusto    pcpedi.perdesccusto%TYPE;
    vnCODICMTAB       pcpedi.codicmtab%TYPE;
    vnVLCUSTOREAL     pcpedi.vlcustoreal%TYPE;
    vnVLCUSTOFIN      pcpedi.vlcustofin%TYPE;
    vnVLDESCCUSTOCMV  pcpedi.vldesccustocmv%TYPE;
    vbcodicmtabpf     BOOLEAN;
    vnperluc          NUMBER;
    vicont            NUMBER;
    vsmensagem_comiss VARCHAR2(300);

    vbUsaPcTabComiss      BOOLEAN;
    vbUsaPcComissaoUsur   BOOLEAN;
    vbUsaPCComissaoPlPag  BOOLEAN;
    vbUsaPCComissaoRegiao BOOLEAN;
    vbUsaPCComissaofilial BOOLEAN;

    vnpercom         pcpedi.percom%TYPE;
    vnpercom_aux     pcpedi.percom%TYPE;
    vnperdesc        pcpedi.perdesc%TYPE;
    vsletracomis     pcpedi.letracomiss%TYPE;
    vncodcomis       pcorigemcomis.codcomis%TYPE;
    vncodrotinacomis pcorigemcomis.codrotinacomis%TYPE;
    vberroitem       BOOLEAN;
    vnvldescpbaserca pcpedi.vldescabatimento%TYPE;


    vnvlatendped           pcpedc.vlatend%TYPE;

    vnpcomint1_emb pcembalagem.pcomint1%TYPE;
    vnpcomext1_emb pcembalagem.pcomext1%TYPE;
    vnpcomrep1_emb pcembalagem.pcomrep1%TYPE;

  BEGIN

      vbCalculouPerDescAbat := FALSE;

      SELECT SUM((pcpedi.qt - nvl(pcpedi.qtfalta,
                                  0)) * pcpedi.pvenda)
       INTO vnvlatendped
       FROM pcpedi
      WHERE pcpedi.numped = p_regpedido.numped;

    IF nvl(p_regpedido.vldescabatimento,
           0) > 0
    THEN

      p_regpedido.percdescabatimento := (p_regpedido.vldescabatimento * 100) / vnvlatendped;

      vbCalculouPerDescAbat := TRUE;

      IF (nvl(p_regpedido.percdescabatimento,0) > 100)
        OR (nvl(p_regpedido.percdescabatimento,0) > 100
               and p_regfilial.percmaxabatimento > 100)
        OR (nvl(p_regpedido.percdescabatimento,
               0) > nvl(p_regfilial.percmaxabatimento,
                        0))
      THEN

        proc_registralog(p_regpedido.numped,
                                     p_regpedido.numpedrca,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_regpedido.cgccli,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_regpedido.codusur,
                                     p_regpedido.dtaberturapedpalm,
                                     NULL,
                                     '2',
                                     'Percentual de Abatimento do pedido :' || round(p_regpedido.percdescabatimento,6) || ', calculado pelo valor de abatimento enviado EXCEDE o maximo permitido : '
                                      || p_Regfilial.percmaxabatimento || ' ou ultrapassa 100% do valor do pedido. ' || CHR(13) ||
                                      'Valor do Pedido: ' || vnvlatendped || CHR(13) ||
                                      'Valor de Abatimento informado: ' || p_regpedido.vldescabatimento ||  ';',
                                     NULL,
                                     null);

        IF nvl(p_regpedido.numpedorig,
               0) = 0
        THEN

          DELETE FROM pcpedi
           WHERE pcpedi.numped = p_regpedido.numped;

          DELETE FROM pcorigempreco
           WHERE numped = p_regpedido.numped;
        END IF;

        p_regpedido.valido := FALSE;

      END IF;

   ELSIF nvl(p_regpedido.percdescabatimento,
           0) > 0 AND not (vbCalculouPerDescAbat)
    THEN

        IF nvl(p_regpedido.percdescabatimento,
             0) > nvl(p_regfilial.percmaxabatimento,
                      0)
      THEN


        proc_registralog(p_regpedido.numped,
                                     p_regpedido.numpedrca,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_regpedido.cgccli,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_regpedido.codusur,
                                     p_regpedido.dtaberturapedpalm,
                                     NULL,
                                     '2',
                                     'PERCENTUAL DE ABATIMENTO DO PEDIDO :' || p_regpedido.percdescabatimento || ' CALCULADO PELO VALOR ENVIADO, EXCEDE O MAXIMO PERMITIDO : ' || p_Regfilial.percmaxabatimento || ';',
                                     NULL,
                                     null);

        IF nvl(p_regpedido.numpedorig,
               0) = 0
        THEN

          DELETE FROM pcpedi
           WHERE pcpedi.numped = p_regpedido.numped;

          DELETE FROM pcorigempreco
           WHERE numped = p_regpedido.numped;
        END IF;

        p_regpedido.valido := FALSE;

      END IF;

      p_regpedido.vldescabatimento := round(((p_regpedido.percdescabatimento * vnvlatendped) / 100), 2);

    END IF;

    vnvldescabatimento_tot := 0;
    vberroitem             := FALSE;

    FOR reg_itens IN (SELECT i.codprod,
                             i.numseq,
                             i.pvenda,
                             i.pbaserca,
                             (i.qt - nvl(i.qtfalta,0)) qt,
                             i.codauxiliar,
                             i.ptabela,
                             i.vlredpvendasimplesna,
                             i.coddesconto,
                             p.freteespecial,
                             t.codicmtabpf,
                             p.pcomint1,
                             p.PCOMEXT1,
                             p.PCOMREP1,
                             p.codlinhaprod,
                             p.tipocomissao,
                             i.st,
                             i.vlipi,
                             p.codepto,
                             p.codsec,
                             p.classe,
                             e.custofin,
                             e.custoreal,
                             t.perdesccusto,
                             t.codicmtab,
                             t.codicmdifer,
               i.codst,
               e.codfilial,
               t.codicmtabsimpnasc
                        FROM pcpedi   i,
                             pcprodut p,
                             pctribut t,
                             pcest    e
                       WHERE numped = p_regpedido.numped
                         AND i.codprod = p.codprod
                         AND i.codst = t.codst
                         AND i.codprod = e.codprod
                         AND e.codfilial = decode(p_regfilial.origemcustofilialretira,
                                                  'V',
                                                  p_regpedido.codfilial,
                                                  i.codfilialretira))
    LOOP


      IF p_regfilial.utilizavendaporembalagem = 'S'
      THEN

        BEGIN
          SELECT pcomint1,
                 pcomext1,
                 pcomrep1
            INTO vnpcomint1_emb,
                 vnpcomext1_emb,
                 vnpcomrep1_emb
            FROM pcembalagem
           WHERE codprod = reg_itens.codprod
             AND codauxiliar = reg_itens.codauxiliar
             AND codfilial = p_regpedido.codfilial;
        EXCEPTION
          WHEN OTHERS THEN

            vnpcomint1_emb := NULL;
            vnpcomext1_emb := NULL;
            vnpcomrep1_emb := NULL;

        END;



      END IF;


      vnvldescitem := 0;


      vnvldescitem := reg_itens.pvenda * (p_regpedido.percdescabatimento) / 100;


      IF p_regpedido.valido = TRUE
      THEN

        IF p_regfilial.abatimentodebitarccrca = 'S'
        THEN
          vnvldescpbaserca := 0;

        ELSE
          vnvldescpbaserca := reg_itens.pbaserca * (p_regpedido.percdescabatimento) / 100;
        END IF;


        vnperdesc := func_calcularperdescitem(reg_itens.ptabela,
                                              round((reg_itens.pvenda - nvl(vnvldescitem,
                                                                            0)),
                                                    gregpcconsum.numcasasdecvenda));




        IF reg_itens.codicmtabpf IS NULL
        THEN
          vbcodicmtabpf := TRUE;
        ELSE
          vbcodicmtabpf := FALSE;
        END IF;

        -- CMV sem comissao
        --53 parâmetros
        BEGIN
          funcoesvendas.calcularcmv(p_regfilial.impostocomissaorca,
                                    gregpcconsum.aplicarindicecmv,
                                    gregpcconsum.INCLUIRCOMISSAOCMVVENDA,
                                    nvl(gregpcconsum.txvenda,
                                        0),
                                    p_regcliente.tipofj,
                                    p_regcliente.utilizaiesimplificada,
                                    p_regcliente.ieent,
                                    reg_itens.freteespecial,
                                    p_regregiao.perfreteterceiros,
                                    p_regregiao.perfreteespecial,
                                    reg_itens.custofin,
                                    reg_itens.custoreal,
                                    reg_itens.perdesccusto,
                                    reg_itens.codicmtab,
                                    vbcodicmtabpf,
                                    reg_itens.codicmtabpf,
                                    p_regpedido.percvenda,
                                    (reg_itens.pvenda - nvl(vnvldescitem,
                                                            0)),
                                    0,
                                    reg_itens.st,
                                    0,
                                    reg_itens.vlipi,
                                    0,
                                    p_regcliente.contribuinte,
                                    0,
                                    ----------------------------------
                                    --nvl(reg_itens.VLREDPVENDASIMPLESNA,0),
                                    CASE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',
                                                                       p_regpedido.codfilial,
                                                                       'N') WHEN 'S' THEN 0 ELSE nvl(reg_itens.VLREDPVENDASIMPLESNA,
                                        0) END,
                                    ----------------------------------
                                    p_regcliente.consumidorfinal,
                                    nvl(gregpcconsum.consideraisentoscomopf,
                                        'N'),
                                    vnperfretecmv,
                                    vnCUSTOFINEST,
                                    vntxvenda,
                                    vnperdesccusto,
                                    vnCODICMTAB,
                                    vnVLCUSTOREAL,
                                    vnVLCUSTOFIN,
                                    vnVLDESCCUSTOCMV,
                                    0,
                                    0,
                                    False,
                                    False,
                                    reg_itens.codst,
                                    0,
                                    reg_itens.codicmtabsimpnasc,
                                    0,
                                    reg_itens.codfilial,
                                    reg_itens.CodIcmDifer,
                                    0,
                                    0,
                                    0,
                                    0,
                                    p_regpedido.numped,
                                    reg_itens.numseq,
                                    reg_itens.codprod);
        EXCEPTION
          WHEN OTHERS THEN
            proc_registralog(p_regpedido.numped,
                                         p_regpedido.numpedrca,
                                         reg_itens.codprod,
                                         reg_itens.numseq,
                                         reg_itens.codauxiliar,
                                         p_regpedido.cgccli,
                                         NULL,
                                         NULL,
                                         NULL,
                                         p_regpedido.codusur,
                                         p_regpedido.dtaberturapedpalm,
                                         NULL,
                                         '3',
                                         'Erro ao calcular cmv apos abatimento. ' || SQLCODE || ' ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                                         NULL,
                                         null);

        END;


        vnperluc := (((reg_itens.pvenda - nvl(vnvldescitem,
                                              0)) - vnvlcustofin) / (reg_itens.pvenda - nvl(vnvldescitem,
                                                                                             0))) * 100;


        -- busca percentual de comissao
        vsmensagem_comiss := NULL;

        SELECT COUNT(*)
          INTO vicont
          FROM pctabcomiss p;

        IF vicont <> 0
        THEN
          vbUsaPcTabComiss := TRUE;
        ELSE
          vbUsaPcTabComiss := FALSE;
        END IF;

        SELECT COUNT(*)
          INTO vicont
          FROM pccomissaousur p;

        IF vicont <> 0
        THEN
          vbUsaPcComissaoUsur := TRUE;
        ELSE
          vbUsaPcComissaoUsur := FALSE;
        END IF;


        SELECT COUNT(*)
          INTO vicont
          FROM pccomissaoplpag p;

        IF vicont <> 0
        THEN
          vbUsaPcComissaoplpag := TRUE;
        ELSE
          vbUsaPCComissaoPlPag := FALSE;
        END IF;


        SELECT COUNT(*)
          INTO vicont
          FROM pccomissaoregiao p;

        IF vicont <> 0
        THEN
          vbUsaPcComissaoregiao := TRUE;
        ELSE
          vbUsaPcComissaoregiao := FALSE;
        END IF;

        IF p_regfilial.broker = 'S'
        THEN
          vbUsaPCComissaofilial := TRUE;
        ELSE
          vbUsaPCComissaofilial := FALSE;
        END IF;

        BEGIN

        if p_regpedido.condvenda not in (4, 5, 8, 10, 13, 11, 20) or
           (p_regpedido.condvenda = 9 and ferramentas.F_BUSCARPARAMETRO_ALFA('CON_CALCULACOMISSTV9',p_regpedido.codfilial, 'N') = 'S')
        then

          vnpercom := FUNCOESVENDAS.Definir_Comissao_Item_Vendido(p_regregiao.numregiao,
                                                                  vnperluc,
                                                                  vnperdesc,
                                                                  vbUsaPcTabComiss,
                                                                  vbUsaPcComissaoUsur,
                                                                  vbUsaPCComissaoPlPag,
                                                                  vbUsaPCComissaoRegiao,
                                                                  vbUsaPCComissaofilial,
                                                                  gregpcconsum.usacomissaoporrca,
                                                                  gregpcconsum.OrdemAvaliacaoComissaoRCA,
                                                                  gregpcconsum.usacomissaoporcliente,
                                                                  gregpcconsum.USACOMISSAOPORLINHAPROD,
                                                                  gregpcconsum.comissaorcatipovenda,
                                                                  p_regrca.tipovend,
                                                                  p_regrca.percent,
                                                                  p_regrca.percent2,
                                                                  reg_itens.codprod,
                                                                  reg_itens.pcomint1,
                                                                  reg_itens.PCOMEXT1,
                                                                  reg_itens.PCOMREP1,
                                                                  reg_itens.codlinhaprod,
                                                                  reg_itens.tipocomissao,
                                                                  reg_itens.codepto,
                                                                  reg_itens.codsec,
                                                                  reg_itens.classe,
                                                                  p_regplpag.tipovenda,
                                                                  p_regplpag.codplpag,
                                                                  p_regpedido.data,
                                                                  p_regpedido.codfilial,
                                                                  p_regpedido.codusur,
                                                                  p_regfilial.considerarcomissaozero,
                                                                  p_regfilial.tipoavaliacaocomissao,
                                                                  p_regcliente.percomcli,
                                                                  p_regcliente.codcli,
                                                                  reg_itens.coddesconto,
                                                                  vncodcomis,
                                                                  vncodrotinacomis,
                                                                  vsLetraComis,
                                                                  vsmensagem_comiss,
                                                                  reg_itens.codauxiliar,
                                                                  vnpcomint1_emb,
                                                                  vnPCOMEXT1_emb,
                                                                  vnPCOMREP1_emb,
                                                                  p_regfilial.utilizavendaporembalagem);

        end if;
        EXCEPTION
          WHEN OTHERS THEN
            proc_registralog(p_regpedido.numped,
                             p_regpedido.numpedrca,
                             reg_itens.codprod,
                             reg_itens.numseq,
                             reg_itens.codauxiliar,
                             p_regpedido.cgccli,
                             NULL,
                             NULL,
                             NULL,
                             p_regpedido.codusur,
                             p_regpedido.dtaberturapedpalm,
                             NULL,
                             '3',
                             'Erro ao calcular comissão. ' || SQLCODE || ' ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                             NULL,
                             null);

        END;

        UPDATE pcorigemcomis p
           SET percom           = vnpercom,
               perdesc          = vnperdesc,
               p.codcomis       = vncodcomis,
               p.codrotinacomis = vncodrotinacomis
         WHERE p.numped = p_regpedido.numped
           AND p.codprod = reg_itens.codprod
           AND p.numseq = reg_itens.numseq;



        IF vsmensagem_comiss IS NOT NULL
        THEN
          proc_registralog(p_regpedido.numped,
                           p_regpedido.numpedrca,
                           reg_itens.codprod,
                           reg_itens.numseq,
                           reg_itens.codauxiliar,
                           p_regpedido.cgccli,
                           NULL,
                           NULL,
                           NULL,
                           p_regpedido.codusur,
                           p_regpedido.dtaberturapedpalm,
                           NULL,
                           '3',
                           vsmensagem_comiss,
                           NULL,
                           null);
        END IF;





        IF nvl(gregpcconsum.incluircomissaocmvvenda,
               'S') = 'N'
        THEN
          vnpercom_aux := 0;
        ELSE
          vnpercom_aux := vnpercom;
        END IF;

        BEGIN
          -- 53 parâmetros
          funcoesvendas.calcularcmv(p_regfilial.impostocomissaorca,
                                    gregpcconsum.aplicarindicecmv,
                                    gregpcconsum.INCLUIRCOMISSAOCMVVENDA,
                                    nvl(gregpcconsum.txvenda, 0),
                                    p_regcliente.tipofj,
                                    p_regcliente.utilizaiesimplificada,
                                    p_regcliente.ieent,
                                    reg_itens.freteespecial,
                                    p_regregiao.perfreteterceiros,
                                    p_regregiao.perfreteespecial,
                                    reg_itens.custofin,
                                    reg_itens.custoreal,
                                    reg_itens.perdesccusto,
                                    reg_itens.codicmtab,
                                    vbcodicmtabpf,
                                    reg_itens.codicmtabpf,
                                    p_regpedido.percvenda,
                                    (reg_itens.pvenda - nvl(vnvldescitem,0)),
                                    vnpercom_aux,
                                    reg_itens.st,
                                    0,
                                    reg_itens.vlipi,
                                    0,
                                    p_regcliente.contribuinte,
                                    0,
                                    CASE FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',
                                                                       p_regpedido.codfilial,   
                                                                       'N') WHEN 'S' THEN 0 ELSE nvl(reg_itens.VLREDPVENDASIMPLESNA,
                                        0) END,
                                    p_regcliente.consumidorfinal,
                                    nvl(gregpcconsum.consideraisentoscomopf, 'N'),
                                    vnperfretecmv,
                                    vnCUSTOFINEST,
                                    vntxvenda,
                                    vnperdesccusto,
                                    vnCODICMTAB,
                                    vnVLCUSTOREAL,
                                    vnVLCUSTOFIN,
                                    vnVLDESCCUSTOCMV,
                                    0,
                                    0,
                                    False,
                                    False,
                                    reg_itens.codst,
                                    0,
                                    reg_itens.codicmtabsimpnasc,
                                    0,
                                    reg_itens.codfilial,
                                    reg_itens.CodIcmDifer,
                                    0,
                                    0,
                                    0,
                                    0,
                                    p_regpedido.numped,
                                    reg_itens.numseq,
                                    reg_itens.codprod
                                    );
        EXCEPTION
          WHEN OTHERS THEN
            proc_registralog(p_regpedido.numped,
                             p_regpedido.numpedrca,
                             reg_itens.codprod,
                             reg_itens.numseq,
                             reg_itens.codauxiliar,
                             p_regpedido.cgccli,
                             NULL,
                             NULL,
                             NULL,
                             p_regpedido.codusur,
                             p_regpedido.dtaberturapedpalm,
                             NULL,
                             '3',
                             'Erro ao calcular comissão. ' || SQLCODE || ' ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                             NULL,
                             null);

        END;

        BEGIN

          UPDATE pcpedi
             SET pvenda             = round(pvenda - vnvldescitem,
                                            gregpcconsum.numcasasdecvenda),
                 pbaserca           = round(pbaserca - vnvldescpbaserca,
                                            gregpcconsum.numcasasdecvenda),
                 percom             = vnpercom,
                 letracomiss        = vsletracomis,
                 perdesc            = vnperdesc,
                 vldescabatimento   = vnvldescitem,
                 percdescabatimento = p_regpedido.percdescabatimento,
                 perfretecmv        = vnperfretecmv,
                 custofinest        = vnCUSTOFINEST,
                 txvenda            = vntxvenda,
                 perdesccusto       = vnperdesccusto,
                 codicmtab          = vnCODICMTAB,
                 vlcustoreal        = vnVLCUSTOREAL,
                 vlcustofin         = vnVLCUSTOFIN,
                 vldesccustocmv     = vnVLDESCCUSTOCMV
           WHERE numped = p_regpedido.numped
             AND codprod = reg_itens.codprod
             AND numseq = reg_itens.numseq;

           SELECT SUM(pcpedi.qt * pcpedi.pvenda)
             INTO p_vltotped
             FROM pcpedi
            WHERE pcpedi.numped = p_regpedido.numped;

        EXCEPTION
          WHEN OTHERS THEN

            vberroitem := TRUE;
            ROLLBACK;
            proc_registralog(p_regpedido.numped,
                             p_regpedido.numpedrca,
                             NULL,
                             NULL,
                             NULL,
                             p_regpedido.cgccli,
                             NULL,
                             NULL,
                             NULL,
                             p_regpedido.codusur,
                             p_regpedido.dtaberturapedpalm,
                             NULL,
                             '2',
                             'Erro ao aplicar abatimento no item : ' || reg_itens.codprod || ' ' || SQLCODE || ' ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                             NULL,
                             null);
            EXIT;

        END;




        vnvldescabatimento_tot := vnvldescabatimento_tot + (vnvldescitem * reg_itens.qt);

      END IF;

    END LOOP;
   /*p_regpedido.vldescabatimento := nvl(p_regpedido.vldescabatimento,
                                        vnvldescabatimento_tot); */
      BEGIN

          UPDATE PCPEDC
          SET VLDESCABATIMENTO = nvl(p_regpedido.vldescabatimento,
                                          vnvldescabatimento_tot)
          WHERE NUMPED = p_regpedido.numped;

          EXCEPTION
          WHEN OTHERS THEN
          proc_registralog(p_regpedido.numped,
                                       p_regpedido.numpedrca,
                                       NULL,
                                       NULL,
                                       NULL,
                                       p_regpedido.cgccli,
                                       NULL,
                                       NULL,
                                       NULL,
                                       p_regpedido.codusur,
                                       p_regpedido.dtaberturapedpalm,
                                       NULL,
                                       '2',
                                       'Não foi possível atualizar o VLDESCABATIMENTO no cabeçalho do pedido:' || ' ' || SQLCODE || ' ' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                                       NULL,
                                       null);
          END;

  END proc_processarabatimento;


  PROCEDURE proc_divide_numitensnfe
  (

    p_numpedrca         IN pcpedc.numpedrca%TYPE,
    p_codusur           IN pcpedc.codusur%TYPE,
    p_codcli            IN pcpedc.codcli%TYPE,
    p_dtaberturapedpalm IN pcpedc.dtaberturapedpalm%TYPE,
    regfilial           IN t_filial,
    p_mensagem          OUT VARCHAR2,
    p_valido            OUT BOOLEAN,
   p_num_pedido        IN pcpedc.numped%TYPE  DEFAULT NULL

  ) IS



    vnproxnumped    pcusuari.proxnumped%TYPE;

    vnnumseqnovoped NUMBER;

    vnvltabela       pcpedc.vltabela%TYPE;
    vnvlatend        pcpedc.vlatend%TYPE;
    vnvltotal        pcpedc.vltotal%TYPE;
    vnvlcustofin     pcpedc.vlcustofin%TYPE;
    vnvlcustoreal    pcpedc.vlcustoreal%TYPE;
    vnvlcustorep     pcpedc.vlcustorep%TYPE;
    vnvlcustocont    pcpedc.vlcustocont%TYPE;
    vntotpeso        pcpedc.totpeso%TYPE;
    vntotvolume      pcpedc.totvolume%TYPE;
    vnnumitens       pcpedc.numitens%TYPE;
    vnnumped         pcpedc.numped%TYPE;
    vnperdescped     NUMBER;

    vsdata      pcfalta.data%type;
    vscodprod   pcfalta.codprod%type;
    vscodusur   pcfalta.codusur%type;
    vscodcli    pcfalta.codcli%type;
    vsqt        pcfalta.qt%type;
    vspvenda    pcfalta.pvenda%type;
    vscodfilial pcfalta.codfilial%type;

    viaux            NUMBER;
    vbvalido         BOOLEAN;


  BEGIN

    p_valido := FALSE;

    vnnumseqnovoped := 0;





    FOR reg_ped IN (SELECT numped,
                          (select cgcent from pcclient where codcli = p_codcli)cgccli,
                           numitens,
                           condvenda,
                           nvl(regfilial.nummaxitensnfe,
                               400) nummaxitensnfe
                      FROM pcpedc
                     WHERE numpedrca = p_numpedrca
                       AND pcpedc.codusur = p_codusur
                       AND pcpedc.codcli = p_codcli
                       AND pcpedc.dtaberturapedpalm = p_dtaberturapedpalm
                       AND pcpedc.numitens > nvl(regfilial.nummaxitensnfe,
                                                 400))
    LOOP



      BEGIN

      IF p_num_pedido IS NULL THEN
         vnproxnumped := ferramentas.F_PROX_NUMPED(p_codusur);
      ELSE
         vnproxnumped := p_num_pedido;
      END IF;


      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao buscar numeração do novo pedido : ' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          RAISE;
      END;


      if nvl(vnproxnumped,0) = 0 then -- VEN-9145 - Ajustado o log para informar quando não gravar o 'proxnumpedrca' na divisão dos pedidos.
             integradora_comple.vLog.NUMPEDRCA          := p_numpedrca;
             integradora_comple.vLog.CODUSUR            := p_codusur;
             integradora_comple.vLog.CGCCLI             := reg_ped.cgccli;
             integradora_comple.vLog.DTABERTURAPEDPALM  := p_dtaberturapedpalm;
             integradora_comple.vLog.TipoLog            := 'C';
             integradora_comple.vLog.MSG                := 'Erro! Função F_PROX_NUMPED retornou NUMPED = 0 ao dividir os itens para a NF-e.';

            PRC_LOG_INTEGRADORA(integradora_comple.vLog, (CASE WHEN integradora_comple.vLog.MSG LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));

      END IF;

      viaux           := 0;
      vnnumseqnovoped := 0;

      FOR reg_itens IN (SELECT codprod,
                               codauxiliar,
                               condvenda,
                               numseq
                          FROM pcpedi
                         WHERE numped = reg_ped.numped)
      LOOP

        viaux    := viaux + 1;
        vbvalido := TRUE;

        IF viaux > reg_ped.nummaxitensnfe
        THEN
          --insere no novo pedido
          vnnumseqnovoped := vnnumseqnovoped + 1;

          BEGIN
            UPDATE PCPEDI
            SET   numped = vnproxnumped,
                  numseq = vnnumseqnovoped,
                  pbonific = CASE WHEN reg_ped.condvenda = 5 THEN pvenda ELSE 0 END
            WHERE numped = reg_ped.numped
                  AND codprod = reg_itens.codprod
                  AND numseq = reg_itens.numseq;

          EXCEPTION
            WHEN OTHERS THEN
              p_mensagem := 'Erro ao inserir item do novo pedido na pcpedi : ' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              vbvalido := FALSE;

          END;

          BEGIN
            UPDATE pcorigempreco
            SET    numped = vnproxnumped,
                   numseq = vnnumseqnovoped
            WHERE  numped = reg_ped.numped
                   AND codprod = reg_itens.codprod
                   AND numseq = reg_itens.numseq;

          EXCEPTION
            WHEN OTHERS THEN
              p_mensagem := 'Erro ao inserir item do novo pedido na pcorigempreco : ' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              vbvalido := FALSE;

          END;

          BEGIN

            UPDATE pcorigemcomis
            SET    numped = vnproxnumped,
                   numseq = vnnumseqnovoped
            WHERE  numped = reg_ped.numped
                   AND codprod = reg_itens.codprod
                   AND numseq = reg_itens.numseq;

          EXCEPTION
            WHEN OTHERS THEN
              p_mensagem := 'Erro ao inserir item do novo pedido na pcorigemcomis : ' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              vbvalido := FALSE;

          END;

        END IF;
      END LOOP;


      IF vbvalido = TRUE
      THEN
        --recalcular pedido

        SELECT SUM(Round(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.ptabela,
                                0), 2)) vltabela,
               SUM(DECODE(NVL(pcpedi.bonific, 'N'), 'F', 0,
                      Round(pcpedi.qt * pcpedi.pvenda, 2))) vlatend,
               SUM(Round((nvl(pcpedi.qt,
                        0) + nvl(pcpedi.qtfalta,
                                  0)) * nvl(pcpedi.pvenda,
                                            0), 2)) vltotal,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustofin,
                                0)) vlcustofin,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustoreal,
                                0)) vlcustoreal,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustorep,
                                0)) vlcustorep,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustocont,
                                0)) vlcustocont,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcprodut.pesoliq,
                                0)) totpeso,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcprodut.volume,
                                0)) totvolume,
               COUNT(*) numitens
          INTO vnvltabela,
               vnvlatend,
               vnvltotal,
               vnvlcustofin,
               vnvlcustoreal,
               vnvlcustorep,
               vnvlcustocont,
               vntotpeso,
               vntotvolume,
               vnnumitens
          FROM pcpedi,
               pcprodut
         WHERE pcpedi.numped = reg_ped.numped
           AND pcpedi.codprod = pcprodut.codprod
       AND PCPEDI.QT > 0;


        UPDATE pcpedc
           SET pcpedc.vltabela    = vnvltabela,
               pcpedc.vlatend     = vnvlatend,
               pcpedc.vltotal     = nvl(vnvltotal,
                                        0),
               pcpedc.vlcustofin  = vnvlcustofin,
               pcpedc.vlcustoreal = vnvlcustoreal,
               pcpedc.vlcustorep  = vnvlcustorep,
               pcpedc.vlcustocont = vnvlcustocont,
               pcpedc.totpeso     = vntotpeso,
               pcpedc.totvolume   = vntotvolume,
               pcpedc.numitens    = vnnumitens
         WHERE pcpedc.numped = reg_ped.numped;

        vnnumped := reg_ped.numped;


        --gravar novo pedido
        SELECT SUM(round(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.ptabela,
                                0), 2)) vltabela,
               SUM(DECODE(NVL(pcpedi.bonific, 'N'), 'F', 0,
                       Round(pcpedi.qt * pcpedi.pvenda, 2))) vlatend,
               SUM(Round((nvl(pcpedi.qt,
                        0) + nvl(pcpedi.qtfalta,
                                  0)) * nvl(pcpedi.pvenda,
                                            0), 2)) vltotal,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustofin,
                                0)) vlcustofin,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustoreal,
                                0)) vlcustoreal,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustorep,
                                0)) vlcustorep,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcpedi.vlcustocont,
                                0)) vlcustocont,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcprodut.pesoliq,
                                0)) totpeso,
               SUM(nvl(pcpedi.qt,
                       0) * nvl(pcprodut.volume,
                                0)) totvolume,
               COUNT(*) numitens
          INTO vnvltabela,
               vnvlatend,
               vnvltotal,
               vnvlcustofin,
               vnvlcustoreal,
               vnvlcustorep,
               vnvlcustocont,
               vntotpeso,
               vntotvolume,
               vnnumitens
          FROM pcpedi,
               pcprodut
         WHERE pcpedi.numped = vnproxnumped
           AND pcpedi.codprod = pcprodut.codprod;


        vnperdescped := round((((vnvltabela - vnvltotal) / vnvltabela) * 100),
                              gregpcconsum.numcasasdecvenda);

        INSERT INTO pcpedc
          (codcli, --1
           codcob, --2
           coddistrib, --3
           codemitente, --4
           codfilial, --5
           codfilialnf, --6
           codplpag, --7
           codpraca, --8
           codsupervisor, --9
           codusur, --10
           condvenda, --11
           DATA, --12
           dtentrega, --13
           hora, --14
           minuto, --15
           numcar, --16
           numitens, --17
           numped, --18
           numpedcli, --19
           numpedrca, --20
           obs1, --21
           obs2, --22
           obsentrega1, --23
           obsentrega2, --24
           operacao, --25
           origemped, --26
           percvenda, --27
           perdesc, --28
           posicao, --29
           prazo1, --30
           prazo2, --31
           prazo3, --32
           prazo4, --33
           prazo5, --34
           prazo6, --35
           prazo7, --36
           prazo8, --37
           prazo9, --38
           prazo10, --39
           prazo11, --40
           prazo12, --41
           prazomedio, --42
           tipovenda, --43
           totpeso, --44
           totvolume, --45
           vlatend, --46
           vlcustocont, --47
           vlcustofin, --48
           vlcustoreal, --49
           vlcustorep, --50
           vltabela, --51
           vltotal, --52
           dtaberturapedpalm, --53
           dtfechamentopedpalm, --54
           numregiao, --55
           usaintegracaowms, --56
           usacredrca, --57
           usadebcredrca, --58
           bonificaltdebcredrca, --59
           trocaaltdebcredrca, --60
           crmaltdebcredrca, --61
           brokeraltdebcredrca, --62
           tipomovccrca, --63
           vlfrete, --64
           codfornecfrete, --65
           fretedespacho, --66
           freteredespacho, --67
           broker, --68
           tipodocumento, --69
           codclinf, --70
           contaordem, --71
           codmotivo, --72
           motivoposicao, --73
           log, --74
           codclitv8, --75
           codplpagetico, --76
           codplpaggenerico, --77
           tipoprioridadeentrega, --78
           localdesembaraco, --79
           ufdesembaraco, --80
           numpedtv1, --81
           agrupamento, --82
           codbnf, --83
           custobonificacao, --84
           codfornecbonific, --85
           turnoentrega, --86
           codendent, --87
           vlentrada, --88
           codendentcli, --89
           vldescabatimento, --90
           codestabelecimento, --91
           numtabela, --92
           obsentrega3, --93
           obsentrega4, --94
           codmotbloqueio, --95
           utilizavendaporembalagem, --96
           codusur2, --97
           codusur3, --98
           codusur4, --99
           vlbonific, --100
           vendatriangular, --101
           codgerente, --102
           tipocontacorrente --103
           )
          SELECT codcli, --1
                 codcob, --2
                 coddistrib, --3
                 codemitente, --4
                 codfilial, --5
                 codfilialnf, --6
                 codplpag, --7
                 codpraca, --8
                 codsupervisor, --9
                 codusur, --10
                 condvenda, --11
                 DATA, --12
                 dtentrega, --13
                 hora, --14
                 minuto, --15
                 numcar, --16
                 vnnumitens, --17
                 vnproxnumped, --18
                 numpedcli, --19
                 numpedrca, --20
                 obs1, --21
                 obs2, --22
                 obsentrega1, --23
                 obsentrega2, --24
                 operacao, --25
                 origemped, --26
                 percvenda, --27
                 vnperdescped, --28
                 posicao, --29
                 prazo1, --30
                 prazo2, --31
                 prazo3, --32
                 prazo4, --33
                 prazo5, --34
                 prazo6, --35
                 prazo7, --36
                 prazo8, --37
                 prazo9, --38
                 prazo10, --39
                 prazo11, --40
                 prazo12, --41
                 prazomedio, --42
                 tipovenda, --43
                 vntotpeso, --44
                 vntotvolume, --45
                 vnvlatend, --46
                 vnvlcustocont, --47
                 vnvlcustofin, --48
                 vnvlcustoreal, --49
                 vnvlcustorep, --50
                 vnvltabela, --51
                 vnvltotal, --52
                 dtaberturapedpalm, --53
                 dtfechamentopedpalm, --54
                 numregiao, --55
                 usaintegracaowms, --56
                 usacredrca, --57
                 usadebcredrca, --58
                 bonificaltdebcredrca, --59
                 trocaaltdebcredrca, --60
                 crmaltdebcredrca, --61
                 brokeraltdebcredrca, --62
                 tipomovccrca, --63
                 vlfrete, --64
                 codfornecfrete, --65
                 fretedespacho, --66
                 freteredespacho, --67
                 broker, --68
                 tipodocumento, --69
                 codclinf, --70
                 contaordem, --71
                 codmotivo, --72
                 motivoposicao, --73
                 log, --74
                 codclitv8, --75
                 codplpagetico, --76
                 codplpaggenerico, --77
                 tipoprioridadeentrega, --78
                 localdesembaraco, --79
                 ufdesembaraco, --80
                 numpedtv1, --81
                 agrupamento, --82
                 codbnf, --83
                 custobonificacao, --84
                 codfornecbonific, --85
                 turnoentrega, --86
                 codendent, --87
                 vlentrada, --88
                 codendentcli, --89
                 vldescabatimento, --90
                 codestabelecimento, --91
                 numtabela, --92
                 obsentrega3, --93
                 obsentrega4, --94
                 codmotbloqueio, --95
                 utilizavendaporembalagem, --96
                 codusur2, --97
                 codusur3, --98
                 codusur4, --99
                 CASE WHEN reg_ped.condvenda = 5 THEN vnvlatend ELSE 0 END, --100 --tarefa 663.123945.2014
                 PCPEDC.VENDATRIANGULAR,
                 pcpedc.codgerente,
                 nvl(pcpedc.tipocontacorrente,'R') tipocontacorrente
            FROM pcpedc
           WHERE numped = reg_ped.numped;

        p_mensagem := 'Gerado com sucesso Pedido : ' || vnproxnumped || ' com itens que ultrapassaram maximo de linhas';

        p_valido := TRUE;


      END IF;


    END LOOP;


  END;

 PROCEDURE PROC_TOTALIZARPEDIDO(P_NUMPED NUMBER) IS
   VNCONDVENDA        PCPEDC.CONDVENDA%TYPE;
   VNVLTABELA         PCPEDC.VLTABELA%TYPE;
   VNVLATEND          PCPEDC.VLATEND%TYPE;
   VNNUMITENS         PCPEDC.NUMITENS%TYPE;
   VNVLCUSTOFIN       PCPEDC.VLCUSTOFIN%TYPE;
   VNVLCUSTOREAL      PCPEDC.VLCUSTOREAL%TYPE;
   VNVLCUSTOREP       PCPEDC.VLCUSTOREP%TYPE;
   VNVLCUSTOCONT      PCPEDC.VLCUSTOCONT%TYPE;
   VNTOTPESO          PCPEDC.TOTPESO%TYPE;
   VNTOTVOLUME        PCPEDC.TOTVOLUME%TYPE;
   VNVLVERBACMV       PCPEDC.VLVERBACMV%TYPE;
   VNVLVERBACMVCLI    PCPEDC.VLVERBACMV%TYPE;
   VNVLBONIFIC        PCPEDC.VLBONIFIC%TYPE;
   VNVLBONIFIC_BRINDE PCPEDC.VLBONIFIC%TYPE := 0;
   VNVLTOTAL          PCPEDC.VLTOTAL%TYPE;
   VSUTILIZAVENDAPOREMBALAGEM VARCHAR2(2);
   VSUTILIZAEMBALAGEMFILIALRETIRA VARCHAR2(2);
   VBEXISTEITEMCESTA  BOOLEAN := FALSE;
   VNCONTADORPCPEDICESTA INTEGER := 0;
   VNTOTPESO_PRODACAB  PCPEDC.TOTPESO%TYPE;
   VNTOTPESO_PRODMP    PCPEDC.TOTPESO%TYPE;
 BEGIN

    BEGIN
      SELECT NVL((SELECT PCPARAMFILIAL.VALOR
                   FROM PCPARAMFILIAL
                  WHERE PCPARAMFILIAL.NOME LIKE
                        'FIL_UTILIZAVENDAPOREMBALAGEM'
                    AND PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO),
                 NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM,
                     NVL(PCCONSUM.UTILIZAVENDAPOREMBALAGEM, 'N')))
        INTO VSUTILIZAVENDAPOREMBALAGEM
        FROM PCFILIAL, PCCONSUM
       WHERE PCFILIAL.CODIGO IN
             (SELECT NVL(CODFILIALNF, CODFILIAL)
                FROM PCPEDC
               WHERE NUMPED = p_numped);
    EXCEPTION
      WHEN OTHERS THEN
        VSUTILIZAVENDAPOREMBALAGEM := 'N';
    END;

    BEGIN
      SELECT NVL((SELECT PCPARAMFILIAL.VALOR
                   FROM PCPARAMFILIAL
                  WHERE PCPARAMFILIAL.NOME LIKE 'UTILIZAEMBALAGEMFILIALRETIRA'
                    AND PCPARAMFILIAL.CODFILIAL = (SELECT NVL(CODFILIALNF, CODFILIAL)
                                                     FROM PCPEDC
                                                    WHERE NUMPED = p_numped)), 'N')
        INTO VSUTILIZAEMBALAGEMFILIALRETIRA
      FROM DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        VSUTILIZAEMBALAGEMFILIALRETIRA := 'N';
    END;

    SELECT pcpedc.condvenda, --1
           SUM(Round(NVL(pcpedi.qt, 0) * NVL(pcpedi.ptabela, 0), 2)) vltabela, --2
           SUM(DECODE(NVL(pcpedi.bonific, 'N'),
                      'F',
                      0,
                      'S',
                      0,
                      Round(pcpedi.qt * pcpedi.pvenda, 2))) vlatend, --3
           COUNT(*) numitens, --4
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustofin, 0)) vlcustofin, --5
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustoreal, 0)) vlcustoreal, --6
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustorep, 0)) vlcustorep, --7
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustocont, 0)) vlcustocont, --8
           SUM(pcpedi.qt *
               decode(VSUTILIZAVENDAPOREMBALAGEM,
                      'S',
                      decode(NVL((select nvl(pcembalagem.pesobruto, 0)
                                   from pcembalagem
                                  where pcembalagem.codfilial =
                                        case when VSUTILIZAEMBALAGEMFILIALRETIRA = 'S'
                                             then pcpedi.codfilialretira
                                             else nvl(pcpedc.codfilialnf,pcpedc.codfilial) end
                                    and pcembalagem.codprod = pcpedi.codprod
                                    and pcembalagem.codauxiliar =
                                        pcpedi.codauxiliar),
                                 0),
                             0,
                             pcprodut.pesobruto,
                             (select NVL(pcembalagem.pesobruto, 0) /
                                     decode(NVL(pcembalagem.qtunit, 0),
                                            0,
                                            1,
                                            pcembalagem.qtunit)
                                from pcembalagem
                               where pcembalagem.codfilial =
                                     case when VSUTILIZAEMBALAGEMFILIALRETIRA = 'S'
                                          then pcpedi.codfilialretira
                                          else nvl(pcpedc.codfilialnf,pcpedc.codfilial) end
                                 and pcembalagem.codprod = pcpedi.codprod
                                 and pcembalagem.codauxiliar =
                                     pcpedi.codauxiliar)),
                      pcprodut.pesobruto)) totpeso, --9
           SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.volume, 0)) totvolume, --10
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlverbacmv, 0)) vlverbacmv, --11
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlverbacmvcli, 0)) vlverbacmvcli, --12
           SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.pbonific, 0)) vlbonific, --13
           pcpedc.vltotal --14
      INTO vncondvenda,
           vnvltabela,
           vnvlatend,
           vnnumitens,
           vnvlcustofin,
           vnvlcustoreal,
           vnvlcustorep,
           vnvlcustocont,
           vntotpeso,
           vntotvolume,
           vnvlverbacmv,
           vnvlverbacmvcli,
           vnvlbonific,
           vnvltotal
      FROM pcpedc, pcpedi, pcprodut
     WHERE pcpedc.numped = pcpedi.numped
       AND pcpedi.numped = p_numped
       AND pcpedi.codprod = pcprodut.codprod
     AND PCPEDI.QT > 0
     GROUP BY pcpedc.condvenda, pcpedc.vltotal;

     SELECT NVL(SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.pbonific, 0)),0) vlbonific_brinde
      INTO vnVlBonific_Brinde
      FROM pcpedc, pcpedi, pcprodut
     WHERE pcpedc.numped = pcpedi.numped
       AND pcpedi.numped = p_numped
       AND pcpedi.codprod = pcprodut.codprod
       AND nvl(pcpedi.brinde, 'N') <> 'N'
       AND nvl(pcpedi.codigobrinde, 0) <> 0;

     VNVLTOTAL := VNVLTOTAL + VNVLBONIFIC_BRINDE;

     /* Caso o pedido tenha itens 'CB', ir? tirar o peso do produto acabado
     e incrementar o peso do produto mat?ria prima ao total do peso dos produtos normais
     para equiparar o comportamento da rotina 1400.
     */

     BEGIN
       SELECT COUNT(*)
         INTO VNCONTADORPCPEDICESTA
         FROM PCPEDICESTA
        WHERE NUMPED = p_numped;
     EXCEPTION
       WHEN OTHERS THEN
         VNCONTADORPCPEDICESTA := 0;
     END;

     VBEXISTEITEMCESTA := VNCONTADORPCPEDICESTA > 0;

     IF VBEXISTEITEMCESTA THEN
       SELECT SUM(pcpedi.qt *
                  decode(VSUTILIZAVENDAPOREMBALAGEM,
                         'S',
                         decode(NVL((select nvl(pcembalagem.pesobruto, 0)
                                      from pcembalagem
                                     where pcembalagem.codfilial = case
                                             when VSUTILIZAEMBALAGEMFILIALRETIRA = 'S' then
                                              pcpedi.codfilialretira
                                             else
                                              nvl(pcpedc.codfilialnf,
                                                  pcpedc.codfilial)
                                           end
                                       and pcembalagem.codprod =
                                           pcpedi.codprod
                                       and pcembalagem.codauxiliar =
                                           pcpedi.codauxiliar),
                                    0),
                                0,
                                pcprodut.pesobruto,
                                (select NVL(pcembalagem.pesobruto, 0) /
                                        decode(NVL(pcembalagem.qtunit, 0),
                                               0,
                                               1,
                                               pcembalagem.qtunit)
                                   from pcembalagem
                                  where pcembalagem.codfilial = case
                                          when VSUTILIZAEMBALAGEMFILIALRETIRA = 'S' then
                                           pcpedi.codfilialretira
                                          else
                                           nvl(pcpedc.codfilialnf,
                                               pcpedc.codfilial)
                                        end
                                    and pcembalagem.codprod = pcpedi.codprod
                                    and pcembalagem.codauxiliar =
                                        pcpedi.codauxiliar)),
                         pcprodut.pesobruto))
         INTO VNTOTPESO_PRODACAB
         FROM pcpedc, pcpedi, pcprodut
        WHERE pcpedc.numped = pcpedi.numped
          AND pcpedi.numped = p_numped
          AND pcpedi.codprod = pcprodut.codprod
          AND PCPEDI.QT > 0
          AND PCPRODUT.TIPOMERC = 'CB';

       VNTOTPESO := VNTOTPESO - VNTOTPESO_PRODACAB;

       SELECT SUM((PCPEDICESTA.QTMP *
                  DECODE(VSUTILIZAVENDAPOREMBALAGEM,
                          'S',
                          DECODE(NVL((SELECT NVL(PCEMBALAGEM.PESOBRUTO, 0)
                                       FROM PCEMBALAGEM
                                      WHERE PCEMBALAGEM.CODFILIAL =
                                            NVL(PCPEDC.CODFILIALNF,
                                                PCPEDC.CODFILIAL)
                                        AND PCEMBALAGEM.CODPROD =
                                            PCPEDICESTA.CODPRODMP
                                        AND PCEMBALAGEM.CODAUXILIAR =
                                            PCPEDICESTA.CODAUXILIAR),
                                     0),
                                 0,
                                 PCPRODUT.PESOBRUTO,
                                 (SELECT NVL(PCEMBALAGEM.PESOBRUTO, 0) /
                                         DECODE(NVL(PCEMBALAGEM.QTUNIT, 0),
                                                0,
                                                1,
                                                PCEMBALAGEM.QTUNIT)
                                    FROM PCEMBALAGEM
                                   WHERE PCEMBALAGEM.CODFILIAL =
                                         NVL(PCPEDC.CODFILIALNF, PCPEDC.CODFILIAL)
                                     AND PCEMBALAGEM.CODPROD = PCPEDICESTA.CODPRODMP
                                     AND PCEMBALAGEM.CODAUXILIAR =
                                         PCPEDICESTA.CODAUXILIAR)),
                          PCPRODUT.PESOBRUTO)) * PCPEDI.QT)
         INTO VNTOTPESO_PRODMP
         FROM PCPEDC, PCPEDI, PCPEDICESTA, PCPRODUT
        WHERE PCPEDC.NUMPED = PCPEDICESTA.NUMPED
          AND PCPEDC.NUMPED = PCPEDI.NUMPED
          AND PCPEDICESTA.CODPRODMP = PCPRODUT.CODPROD
          AND PCPEDI.CODPROD = PCPEDICESTA.CODPROD
          AND PCPEDICESTA.NUMPED = p_numped
          AND PCPEDICESTA.QTMP > 0;

       IF VNTOTPESO_PRODMP > 0 THEN
         VNTOTPESO := VNTOTPESO + VNTOTPESO_PRODMP;
       END IF;
     END IF;

     UPDATE pcpedc
         SET pcpedc.vltabela      = decode(vncondvenda, 20, 0, vnvltabela),
             pcpedc.vlatend       = decode(vncondvenda,
                                           5,
                                           0,decode(vncondvenda,
										   11,
										   0,
                                           decode(vncondvenda,
                                                  20,
                                                  0,
                                                  vnvlatend + NVL(VLFRETE, 0)))),
             pcpedc.vlcustofin    = decode(vncondvenda, 20, 0, vnvlcustofin),
             pcpedc.vlcustoreal   = decode(vncondvenda, 20, 0, vnvlcustoreal),
             pcpedc.vlcustorep    = decode(vncondvenda, 20, 0, vnvlcustorep),
             pcpedc.vlcustocont   = vnvlcustocont,
             pcpedc.totpeso       = vntotpeso,
             pcpedc.totvolume     = vntotvolume,
             pcpedc.numitens      = vnnumitens,
             pcpedc.vlverbacmv    = vnvlverbacmv,
             pcpedc.vlverbacmvcli = vnvlverbacmvcli,
             pcpedc.vlbonific     = vnvlbonific,
             pcpedc.vltotal       = vnvltotal
       WHERE pcpedc.numped        = p_numped;

 END; -- totalizarpedido

 FUNCTION func_existepcfalta(p_numped  IN pcfalta.numped%TYPE,
                              p_codprod IN pcfalta.codprod%TYPE,
                              p_numseq  IN pcfalta.numseq%TYPE)
    RETURN BOOLEAN is
    contador number;
 BEGIN
   BEGIN
     select (1)
       into contador
       from PCFALTA
      where numped = p_numped
        and codprod = p_codprod
        and numseq = p_numseq;
   exception
     WHEN NO_DATA_FOUND THEN
        contador := 0;
   END;

   if nvl(contador, 0) > 0 then
     Return True;
   else
     Return False;
   end if;
 END func_existepcfalta;


PROCEDURE PROCURAR_ESTOQUE( pnNUMPEDRCA IN NUMBER
                          , psCGCCLI    IN VARCHAR2
                          , pnCODUSUR   IN NUMBER
                          )
iS
  vnSALDO PCPEDIFV.QT%TYPE;
  voLINHAPCPEDIFV PCPEDIFV%ROWTYPE;
  voNOVONUMSEQ PCPEDIFV.NUMSEQ%TYPE;

  Function ProximoNumSeq( pnNumpedido in NUMBER
                        , psCNPJ_CPF  in varchar
                        , pnCodigoRCA in NUMBER)
    RETURN NUMBER
  IS
    vnProximo PCPEDIFV.NUMSEQ%TYPE;
  BEGIN
    BEGIN
      SELECT MAX(PCPEDIFV.NUMSEQ)
        INTO vnProximo
        FROM PCPEDIFV
       WHERE PCPEDIFV.NUMPEDRCA = pnNumpedido
         AND PCPEDIFV.CGCCLI    = psCNPJ_CPF
         AND PCPEDIFV.CODUSUR   = pnCodigoRCA;
    exception
    WHEN NO_DATA_FOUND THEN
      vnProximo := 0;
    END;

    vnProximo := vnProximo + 1;

    return vnProximo;
  END;

BEGIN
  FOR REGISTROS IN (SELECT A.*
                         , CASE WHEN (A.TIPOESTOQUE = 'FR') AND (A.UTILIZAFRIOSEMBALAGEM = 'S')
                                THEN CASE WHEN A.UNIDADEMASTER = A.UNIDADEVENDA
                                          THEN 'M' --Unidade master
                                          WHEN A.UNIDADEVENDA = 'PC'
                                          THEN 'P' --Peças
                                          ELSE 'N' --Normal
                                     END
                                ELSE 'N' --Normal
                            END CONFIGURACAO_ESTOQUE
                      FROM (SELECT PCPEDCFV.NUMPEDRCA
                                 , PCPEDCFV.CGCCLI
                                 , PCPEDCFV.CODUSUR
                                 , PCPEDCFV.CODFILIAL
                                 , PCPEDIFV.CODPROD
                                 , NVL(PCPEDIFV.CODAUXILIAR, PCPRODUT.CODAUXILIAR) CODAUXILIAR
                                 , PCPEDIFV.NUMSEQ
                                 , PCPEDIFV.QT
                                 , PCPEDIFV.ROWID RID
                                 , NVL(PCPEDIFV.CODFILIALRETIRA, PCPEDCFV.CODFILIAL) CODFILIALRETIRA

                                 , UPPER(TRIM(PCPEDIFV.UNIDADE_FRIOS)) UNIDADEVENDA
                                 , UPPER(TRIM(PCPRODUT.UNIDADEMASTER)) UNIDADEMASTER
                                 , DECODE(NVL(PCPRODFILIAL.PESOBRUTOMASTER,0), 0, NVL(PCPRODUT.PESOBRUTOMASTER,1), PCPRODFILIAL.PESOBRUTOMASTER) PESOBRUTOMASTER
                                 , DECODE(NVL(PCPRODFILIAL.PESOPECA,0), 0, NVL(PCPRODUT.PESOPECA,1), PCPRODFILIAL.PESOPECA) PESOPECA
                                 , FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAFRIOSEMBALAGEM', PCFILIAL.CODIGO, 'N') UTILIZAFRIOSEMBALAGEM
                                 , NVL(PCPRODUT.TIPOESTOQUE,'X') TIPOESTOQUE

                              FROM PCPEDIFV
                                 , PCPEDCFV

                                 , PCPRODUT
                                 , PCFILIAL
                                 , PCPRODFILIAL
                             WHERE PCPEDIFV.CODPROD    = PCPRODUT.CODPROD
                          AND NVL(PCPEDIFV.CODFILIALRETIRA, PCPEDCFV.CODFILIAL) = PCFILIAL.CODIGO
                               AND PCPEDIFV.CODPROD    = PCPRODFILIAL.CODPROD
                               AND PCFILIAL.CODIGO     = PCPRODFILIAL.CODFILIAL
                               AND PCPEDCFV.NUMPEDRCA  = pnNUMPEDRCA
                               AND PCPEDCFV.CGCCLI     = psCGCCLI
                               AND PCPEDCFV.CODUSUR    = pnCODUSUR
                               AND PCPEDIFV.NUMPEDRCA  = PCPEDCFV.NUMPEDRCA
                               AND PCPEDIFV.CGCCLI     = PCPEDCFV.CGCCLI
                               AND PCPEDIFV.codusur    = PCPEDCFV.CODUSUR
                     ) A
                    )
  LOOP
    --Saldo do produto a ser analisado
    vnSALDO := REGISTROS.QT;

    --Retornado o dados do estoque que tem saldo
    FOR ESTOQUES IN (SELECT B.*
                       FROM (SELECT A.CODFILIAL
                                  , A.CODPROD
                                  , A.PRIORIDADE
                                  , TRUNC(CASE WHEN REGISTROS.CONFIGURACAO_ESTOQUE = 'P'
                                         THEN A.QTDISPPECA
                                         WHEN REGISTROS.CONFIGURACAO_ESTOQUE = 'M'
                                         THEN A.QTDISPPESOBRUTO --pesobruto/caixa
                                         ELSE A.QTDISP --unitario
                                    END)
                                  --Retira o saldo já usado no pedido, caso o Item já esteja inserido
                                  - NVL((SELECT SUM(CASE WHEN (NVL(PCPRODUT.TIPOESTOQUE,'X')  = 'FR') AND (REGISTROS.UTILIZAFRIOSEMBALAGEM = 'S')
                                                         THEN CASE WHEN UPPER(TRIM(PCPRODUT.UNIDADEMASTER)) = UPPER(TRIM(PCPEDIFV.UNIDADE_FRIOS))
                                                                   THEN PCPEDIFV.QT * REGISTROS.PESOBRUTOMASTER
                                                                   WHEN UPPER(TRIM(PCPEDIFV.UNIDADE_FRIOS)) = 'PC'
                                                                   THEN PCPEDIFV.QT * REGISTROS.PESOPECA
                                                                   ELSE PCPEDIFV.QT
                                                              END
                                                         ELSE PCPEDIFV.QT
                                                END)
                                           FROM PCPEDIFV, PCPRODUT
                                          WHERE PCPEDIFV.NUMPEDRCA       = REGISTROS.NUMPEDRCA
                                            AND PCPEDIFV.CODPROD         = REGISTROS.CODPROD
                                            AND PCPEDIFV.CGCCLI          = REGISTROS.CGCCLI
                                            AND PCPEDIFV.CODUSUR         = REGISTROS.CODUSUR
                                            AND PCPEDIFV.CODFILIALRETIRA = A.CODFILIAL
                                            AND PCPEDIFV.CODPROD         = PCPRODUT.CODPROD
                                            AND PCPEDIFV.NUMSEQ         <> REGISTROS.NUMSEQ
                                            AND PCPEDIFV.OBSERVACAO_PC   = 'ANALISADO' --Para pegar apenas que foi analisado ainda
                                        ),0) QTDISP
                               FROM TABLE(pkg_estoque.ESTOQUE_DISPONIVEL_RETIRA( REGISTROS.CODPROD
                                                                               , REGISTROS.CODAUXILIAR
                                                                               , REGISTROS.CODFILIAL)
                            ) A
                         ) B
                     WHERE B.QTDISP > 0
                    )
    LOOP
      --Se o estoque atender a necessidade
      IF ESTOQUES.QTDISP >= vnSALDO THEN
         --Altera a filial retira caso não seja a mesma
         IF ESTOQUES.CODFILIAL <> REGISTROS.CODFILIALRETIRA THEN
            UPDATE PCPEDIFV
               SET PCPEDIFV.CODFILIALRETIRA = ESTOQUES.CODFILIAL
              , PCPEDIFV.OBSERVACAO_PC   = 'ANALISADO'
                 , PCPEDIFV.QT              = vnSALDO
             WHERE PCPEDIFV.ROWID           = REGISTROS.RID;
         END IF;
         vnSaldo := 0;
      ELSE
        vnSaldo := vnSaldo - ESTOQUES.QTDISP;

        --Clonar a linha para desdobrar o pedido
        SELECT *
          INTO voLINHAPCPEDIFV
          FROM PCPEDIFV
         WHERE PCPEDIFV.ROWID           = REGISTROS.RID;

        --Ajustando o registro do novo lançamento
        voLINHAPCPEDIFV.QT              := ESTOQUES.QTDISP;
        voLINHAPCPEDIFV.CODFILIALRETIRA := ESTOQUES.CODFILIAL;
        voLINHAPCPEDIFV.NUMSEQ          := PROXIMONUMSEQ(REGISTROS.NUMPEDRCA, REGISTROS.CGCCLI, REGISTROS.CODUSUR);
      voLINHAPCPEDIFV.OBSERVACAO_PC   := 'ANALISADO';

        --Inserindo um novo item no pedido
        INSERT INTO PCPEDIFV
             VALUES voLINHAPCPEDIFV;

        --Atualizar o saldo do item original
        UPDATE PCPEDIFV
           SET PCPEDIFV.QT      = GREATEST(PCPEDIFV.QT - ESTOQUES.QTDISP,0)
         WHERE PCPEDIFV.ROWID           = REGISTROS.RID;

        --Sair quando a prioridade não está pcfilialretira
        EXIT WHEN (ESTOQUES.PRIORIDADE < 0);
      END IF;

      --Saldo zerado para a execução
      IF vnSALDO = 0 THEN
         EXIT;
      END IF;

    END LOOP;

    SELECT PCPEDIFV.QT
      INTO vnSALDO
      FROM PCPEDIFV
     WHERE PCPEDIFV.ROWID   = REGISTROS.RID;

    IF vnSALDO <= 0 THEN
       --Excluir o registro se o mesmo ficar zerado
       DELETE PCPEDIFV
        WHERE PCPEDIFV.ROWID   = REGISTROS.RID
          AND PCPEDIFV.QT      = 0;

       --Pega o último registro gerado e coloca na posição do numseq excluido para não ficar espaço entre a numeração da sequencia
       UPDATE PCPEDIFV
          SET NUMSEQ              = REGISTROS.NUMSEQ
        WHERE PCPEDIFV.NUMPEDRCA  = REGISTROS.NUMPEDRCA
          AND PCPEDIFV.CODPROD    = REGISTROS.CODPROD
          AND PCPEDIFV.CGCCLI     = REGISTROS.CGCCLI
          AND PCPEDIFV.codusur    = REGISTROS.CODUSUR
          AND PCPEDIFV.NUMSEQ     = voLINHAPCPEDIFV.NUMSEQ;
    else  --Caso ainda tenha saldo, joga para ultimo numseq para durante o corte, se usado ele
       voNOVONUMSEQ := PROXIMONUMSEQ(REGISTROS.NUMPEDRCA, REGISTROS.CGCCLI, REGISTROS.CODUSUR);

       UPDATE PCPEDIFV
          SET NUMSEQ              = voNOVONUMSEQ
        WHERE PCPEDIFV.NUMPEDRCA  = REGISTROS.NUMPEDRCA
          AND PCPEDIFV.CODPROD    = REGISTROS.CODPROD
          AND PCPEDIFV.CGCCLI     = REGISTROS.CGCCLI
          AND PCPEDIFV.codusur    = REGISTROS.CODUSUR
          AND PCPEDIFV.NUMSEQ     = REGISTROS.NUMSEQ;
    END IF;
  END LOOP;

  --Remove a marcação
  UPDATE PCPEDIFV
     SET PCPEDIFV.OBSERVACAO_PC   = NULL
   WHERE PCPEDIFV.NUMPEDRCA       = pnNUMPEDRCA
     AND PCPEDIFV.CGCCLI          = psCGCCLI
     AND PCPEDIFV.CODUSUR         = pnCODUSUR
     AND PCPEDIFV.OBSERVACAO_PC   = 'ANALISADO';

END;

PROCEDURE proc_lerparametros(p_existerro IN OUT BOOLEAN) IS
  BEGIN
    SELECT *
      INTO integradora_comple.gregpcconsum
      FROM pcconsum;
    integradora_comple.gregpcconsum.codfilialfv      := NVL(integradora_comple.gregpcconsum.codfilialfv,
                                         '1');
    integradora_comple.gregpcconsum.numcasasdecvenda := NVL(integradora_comple.gregpcconsum.numcasasdecvenda,
                                         2);


  EXCEPTION
    WHEN OTHERS THEN
      p_existerro := TRUE;
      integradora_comple.proc_registralog(NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       '1',
                       'Erro ao ler parametros#;' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';',
                       NULL,
                       NULL);

  END proc_lerparametros;

  FUNCTION validarValorTv1Tv5(p_NumpedTV1   IN pcpedc.numped%TYPE,
                              p_NumpedTV5   IN pcpedc.numped%TYPE,
                              p_VlTotalTV5  IN pcpedc.vltotal%TYPE,
                              p_PercBonific IN pcpedc.perdesc%TYPE,
                              p_mensagem    OUT VARCHAR2) RETURN BOOLEAN is

    VNPERC_ENCONTRADO pcpedc.perdesc%TYPE;

  BEGIN

    p_mensagem := 'OK';
    IF p_PercBonific > 0 THEN

      BEGIN
        SELECT NVL((((p_VlTotalTV5 +
                   (select nvl(sum(vlbonific), 0)
                         from pcpedc
                        where pcpedc.numpedtv1 = p_NumpedTV1
                          and numped <> p_NumpedTV5
                          and nvl(brinde,'N') <> 'S'
                          AND condvenda = 5)) / TV1.VLTOTAL) * 100),
                   0)
          INTO VNPERC_ENCONTRADO

          FROM PCPEDC TV1
         WHERE TV1.NUMPED = p_NumpedTV1;
      EXCEPTION
        WHEN OTHERS THEN
          VNPERC_ENCONTRADO := 0;
      END;

      IF VNPERC_ENCONTRADO > p_PercBonific THEN

        p_mensagem := 'Valor dos itens do pedido TV5 é superior ao limite para o pedido TV1.' ||
                      CHR(13) || 'Percentual permitido: ' || p_PercBonific || ' | Percentual encontrado: ' || VNPERC_ENCONTRADO  || CHR(13) ||
                      'Verifique o parâmetro 3759 na rotina 132.';
        RETURN FALSE;
      END IF;
    END IF;

  RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
      p_mensagem := 'Erro ao verificar o percentual do TV5 em relação ao TV1.' ||
                    SQLCODE || '-' || SQLERRM || '-' ||
                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

  END validarValorTv1Tv5;
  
PROCEDURE proc_lockestoque(p_CGCCLI  IN VARCHAR2
                         , p_datainicial  IN DATE
                         , p_datafinal    IN DATE
                         , p_codfilial    IN VARCHAR2
                         , p_codusur      IN NUMBER DEFAULT NULL
                         , p_numpedrca    IN NUMBER DEFAULT NULL
                         , p_mensagem     OUT VARCHAR2
                         , p_valido       OUT BOOLEAN
                         , pCursorEstoque IN OUT T_CURSOR_ESTOQUE_LOCK) is
    vsSqlCursorEstoquePedido   varchar2(4000);
  vsFiltroCodUsur            varchar2(400);
  vsFiltroNumPedRca          varchar2(400);
    BEGIN
      p_valido := FALSE;
      p_mensagem := 'Nenhuma';    
      vsFiltroCodUsur := '';
      vsFiltroNumPedRca := '';
    
      IF p_codusur IS NOT NULL THEN
      vsFiltroCodUsur := 'AND (PCPEDCFV.codusur = ' || p_codusur || ') ';
      END IF;
    
      IF p_numpedrca IS NOT NULL THEN
      vsFiltroNumPedRca := 'AND (PCPEDCFV.numpedrca = ' || p_numpedrca || ') ';
      END IF;
    
      vsSqlCursorEstoquePedido := 'SELECT CODPROD, CODFILIAL
                                     FROM PCEST
                                    WHERE (CODPROD, CODFILIAL) IN
                                          (SELECT CODPROD, NVL(PCPEDIFV.CODFILIALRETIRA, PCPEDCFV.CODFILIAL)
                                             FROM PCPEDIFV
                          , PCPEDCFV
                                            WHERE PCPEDIFV.NUMPEDRCA = PCPEDCFV.NUMPEDRCA
                        AND PCPEDIFV.CODUSUR   = PCPEDCFV.CODUSUR
                        AND nvl(PCPEDIFV.DTABERTURAPEDPALM, PCPEDCFV.DTABERTURAPEDPALM) = PCPEDCFV.DTABERTURAPEDPALM
                                              AND PCPEDCFV.CGCCLI = ' ||''''|| p_CGCCLI||'''' || '
                                              AND (NVL(trunc(PCPEDCFV.dtinclusao), TRUNC(SYSDATE)) BETWEEN 
                                                  TO_DATE(' || '''' || TO_CHAR(p_datainicial, 'DD-MM-YYYY') || '''' || ', ' || '''DD-MM-YYYY'')' || ' AND 
                                                  TO_DATE(' || '''' || TO_CHAR(p_datafinal, 'DD-MM-YYYY') || '''' || ', ' || '''DD-MM-YYYY'')' || ' )
                                              AND nvl(PCPEDCFV.tipofv, ' || '''' || 'FV' || '''' || ') = ' || '''' || 'FV' || '''' ||
                                              vsFiltroCodUsur ||
                                              vsFiltroNumPedRca || '
                                     )
                                   FOR UPDATE';

    OPEN pCursorEstoque FOR
           vsSqlCursorEstoquePedido;
      p_valido := TRUE;
       
  EXCEPTION
    WHEN OTHERS THEN
      p_valido := FALSE;
      p_mensagem := 'Erro ao Bloquear Estoque para importar pedidos.' ||
                    SQLCODE || '-' || SQLERRM || '-' ||
                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    integradora_comple.proc_registralog(NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       '1',
                       'Erro ao Bloquear Estoque para importar pedidos#;' || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';',
                       NULL,
                       NULL);
    END proc_lockestoque;
  
PROCEDURE proc_liberaestoque(pCursorEstoque IN OUT T_CURSOR_ESTOQUE_LOCK) is
    BEGIN
    CLOSE pCursorEstoque;
    END proc_liberaestoque;

  FUNCTION isCobrancaCartao(pCodCob in varchar) return boolean is
    vsCartao varchar2(1);
  BEGIN

    BEGIN
      select nvl(cartao, 'N')
        into vsCartao
        from pccob
       where codcob = pCodCob;
    EXCEPTION
      when others then
        vsCartao := 'N';
    END;

    return(vsCartao = 'S');

  END;
  
PROCEDURE pro_insereMensagemFalta(p_codusur IN NUMBER,
                                  p_numped IN NUMBER,
                                  p_codcli IN NUMBER,
                                  p_codfilial IN VARCHAR,
                                  p_codprod IN NUMBER,
                                  p_numseq  IN NUMBER,
                                  p_codauxiliar IN NUMBER,
                                  p_qtfalta IN NUMBER,
                                  p_pvenda IN NUMBER) is
  vsCliente VARCHAR2(200);
  vsEmbalagem VARCHAR2(200);
BEGIN
  SELECT ' Cliente: ' || cli.codcli || '-' || cli.CLIENTE
    into vsCliente
    FROM pcclient cli
   where cli.codcli = p_codcli;
   
  select p.descricao || ' ' ||
         nvl((select e.embalagem from pcembalagem e where e.codauxiliar = p_codauxiliar and e.codfilial = p_codfilial and rownum = 1), p.embalagem)
    into vsEmbalagem
  from pcprodut p
  where p.codprod = p_codprod;
  
  INSERT INTO pcmens
      (codusur, --1
       data, --2
       mens1, --3
       mens2, --4
       mens3, --5
       mens4, --6
       mens5, --7
       codfuncemite --8
       )
    VALUES
      (p_codusur, --1
       sysdate, --2
       substr('Item Canc. Ped.: ' || p_numped, 1, 60), --3
       substr('Prod: ' || p_codprod || ' Valor: ' || p_qtfalta * p_pvenda || ' Qt: ' || p_qtfalta, 1, 60), --4
       substr(vsCliente, 1, 60), --5
       substr('Motivo: ' || 'Falta', 1, 60), --6
       substr(vsEmbalagem, 1, 60), --7
       8888 --8
       );
END;
FUNCTION FUNC_RETORNARPTABELACESTA(P_NUMREGIAO IN PCPEDC.NUMREGIAO%TYPE,
                                                 P_TIPOPRECIFICACAO IN PCFILIAL.TIPOPRECIFICACAO%TYPE,
                                                 P_CODFILIAL IN PCPEDC.CODFILIAL%TYPE, 
                                                 P_NUMPR IN NUMBER,
                                                 P_CODPRODMP IN NUMBER,
                                                 P_CODPRODACAB IN NUMBER,
                                                 P_QT IN NUMBER,
                                                 QTPRODMP IN NUMBER,
                                                 P_COMIMPOSTO IN VARCHAR) RETURN NUMBER IS
vnPreco number := 0;
vnPrecoTabelaCesta number := 0;

TYPE T_preco IS RECORD(
  pvendasemimposto1 PCTABPR.PVENDASEMIMPOSTO1%TYPE,
  pvendasemimposto2 PCTABPR.PVENDASEMIMPOSTO2%TYPE,
  pvendasemimposto3 PCTABPR.PVENDASEMIMPOSTO3%TYPE,
  pvendasemimposto4 PCTABPR.PVENDASEMIMPOSTO4%TYPE,
  pvendasemimposto5 PCTABPR.PVENDASEMIMPOSTO5%TYPE,
  pvendasemimposto6 PCTABPR.PVENDASEMIMPOSTO6%TYPE,
  pvendasemimposto7 PCTABPR.PVENDASEMIMPOSTO7%TYPE,
  pvenda1           PCTABPR.pvenda1%TYPE,
  pvenda2           PCTABPR.PVENDA2%TYPE,
  pvenda3           PCTABPR.PVENDA3%TYPE,
  pvenda4           PCTABPR.PVENDA4%TYPE,
  pvenda5           PCTABPR.PVENDA5%TYPE,
  pvenda6           PCTABPR.PVENDA6%TYPE,
  pvenda7           PCTABPR.PVENDA7%TYPE,
  PVENDAATAC1       PCTABPR.PVENDAATAC1%TYPE,
  PVENDAATAC2       PCTABPR.PVENDAATAC2%TYPE,
  PVENDAATAC3       PCTABPR.PVENDAATAC%TYPE,
  PVENDAATAC4       PCTABPR.PVENDAATAC4%TYPE,
  PVENDAATAC5       PCTABPR.PVENDAATAC5%TYPE,
  PVENDAATAC6       PCTABPR.PVENDAATAC6%TYPE,
  PVENDAATAC7       PCTABPR.PVENDAATAC7%TYPE,
  qtminimaatacado   PCEMBALAGEM.QTMINIMAATACADO%TYPE);
  p_regprecos T_preco;
BEGIN
  BEGIN
    SELECT nvl(pctabpr.pvendaatac1, 0),
       nvl(pctabpr.pvendaatac2, 0),
       nvl(pctabpr.pvendaatac3, 0),
       nvl(pctabpr.pvendaatac4, 0),
       nvl(pctabpr.pvendaatac5, 0),
       nvl(pctabpr.pvendaatac6, 0),
       nvl(pctabpr.pvendaatac7, 0),
       round(NVL(pctabpr.pvenda1, 0), 6),
       round(NVL(pctabpr.pvenda2, 0), 6),
       round(NVL(pctabpr.pvenda3, 0), 6),
       round(NVL(pctabpr.pvenda4, 0), 6),
       round(NVL(pctabpr.pvenda5, 0), 6),
       round(NVL(pctabpr.pvenda6, 0), 6),
       round(NVL(pctabpr.pvenda7, 0), 6),
       round(NVL(pctabpr.pvendasemimposto1, 0), 6),
       round(NVL(pctabpr.pvendasemimposto2, 0), 6),
       round(NVL(pctabpr.pvendasemimposto3, 0), 6),
       round(NVL(pctabpr.pvendasemimposto4, 0), 6),
       round(NVL(pctabpr.pvendasemimposto5, 0), 6),
       round(NVL(pctabpr.pvendasemimposto6, 0), 6),
       round(NVL(pctabpr.pvendasemimposto7, 0), 6),
       DECODE((SELECT COUNT(*)
            FROM pcprodfilial
           WHERE codprod = pcprodut.codprod
             AND codfilial = p_codfilial),
          0,
          DECODE(NVL(pcprodut.qtminimaatacado, 0),
               0,
               1,
               pcprodut.qtminimaatacado),
          NVL((SELECT qtminimaatacado
              FROM pcprodfilial
             WHERE codprod = pcprodut.codprod
               AND codfilial = p_codfilial),
            DECODE(NVL(pcprodut.qtminimaatacado, 0),
                 0,
                 1,
                 pcprodut.qtminimaatacado))) qtminimaatacado
    INTO p_regprecos.PVENDAATAC1,
       p_regprecos.PVENDAATAC2,
       p_regprecos.PVENDAATAC3,
       p_regprecos.PVENDAATAC4,
       p_regprecos.PVENDAATAC5,
       p_regprecos.PVENDAATAC6,
       p_regprecos.PVENDAATAC7,
       p_regprecos.PVENDA1,
       p_regprecos.PVENDA2,
       p_regprecos.PVENDA3,
       p_regprecos.PVENDA4,
       p_regprecos.PVENDA5,
       p_regprecos.PVENDA6,
       p_regprecos.PVENDA7,
       p_regprecos.pvendasemimposto1,
       p_regprecos.pvendasemimposto2,
       p_regprecos.pvendasemimposto3,
       p_regprecos.pvendasemimposto4,
       p_regprecos.pvendasemimposto5,
       p_regprecos.pvendasemimposto6,
       p_regprecos.pvendasemimposto7,
       p_regprecos.qtminimaatacado
    FROM PCTABPR, pcprodut
     WHERE PCTABPR.CODPROD = pcprodut.CODPROD
     AND PCTABPR.CODPROD = p_CODPRODMP
     AND PCTABPR.NUMREGIAO = p_numregiao;
  EXCEPTION
    WHEN OTHERS THEN
    p_regprecos.PVENDAATAC1       := 0;
    p_regprecos.PVENDAATAC2       := 0;
    p_regprecos.PVENDAATAC3       := 0;
    p_regprecos.PVENDAATAC4       := 0;
    p_regprecos.PVENDAATAC5       := 0;
    p_regprecos.PVENDAATAC6       := 0;
    p_regprecos.PVENDAATAC7       := 0;
    p_regprecos.PVENDA1           := 0;
    p_regprecos.PVENDA2           := 0;
    p_regprecos.PVENDA3           := 0;
    p_regprecos.PVENDA4           := 0;
    p_regprecos.PVENDA5           := 0;
    p_regprecos.PVENDA6           := 0;
    p_regprecos.PVENDA7           := 0;
    p_regprecos.pvendasemimposto1 := 0;
    p_regprecos.pvendasemimposto2 := 0;
    p_regprecos.pvendasemimposto3 := 0;
    p_regprecos.pvendasemimposto4 := 0;
    p_regprecos.pvendasemimposto5 := 0;
    p_regprecos.pvendasemimposto6 := 0;
    p_regprecos.pvendasemimposto7 := 0;
    p_regprecos.qtminimaatacado   := 0;
  END;

  if ((p_tipoprecificacao = 'P') OR
     (p_tipoprecificacao = 'A' AND p_qt >= p_regprecos.qtminimaatacado) OR 
     (p_tipoprecificacao = 'V' AND
     (p_qt < p_regprecos.qtminimaatacado OR
     NVL(p_regprecos.qtminimaatacado, 0) = 0))) AND p_comimposto = 'S' 
   THEN
    IF p_numpr = 1 THEN
    VNPRECO := p_regprecos.pvenda1;
    ELSIF p_numpr = 2 THEN
    VNPRECO := p_regprecos.pvenda2;
    ELSIF p_numpr = 3 THEN
    VNPRECO := p_regprecos.pvenda3;
    ELSIF p_numpr = 4 THEN
    VNPRECO := p_regprecos.pvenda4;
    ELSIF p_numpr = 5 THEN
    VNPRECO := p_regprecos.pvenda5;
    ELSIF p_numpr = 6 THEN
    VNPRECO := p_regprecos.pvenda6;
    ELSIF p_numpr = 7 THEN
    VNPRECO := p_regprecos.pvenda7;
    END IF;
  ELSIF ((p_tipoprecificacao = 'A' AND p_qt < p_regprecos.qtminimaatacado) OR 
      (p_tipoprecificacao = 'V' AND p_qt >= p_regprecos.qtminimaatacado)) 
   THEN
    IF p_numpr = 1 THEN
    VNPRECO := p_regprecos.pvendaatac1;
    ELSIF p_numpr = 2 THEN
    VNPRECO := p_regprecos.pvendaatac2;
    ELSIF p_numpr = 3 THEN
    VNPRECO := p_regprecos.pvendaatac3;
    ELSIF p_numpr = 4 THEN
    VNPRECO := p_regprecos.pvendaatac4;
    ELSIF p_numpr = 5 THEN
    VNPRECO := p_regprecos.pvendaatac5;
    ELSIF p_numpr = 6 THEN
    VNPRECO := p_regprecos.pvendaatac6;
    ELSIF p_numpr = 7 THEN
    VNPRECO := p_regprecos.pvendaatac7;
    END IF;
  ELSIF (p_comimposto <> 'S') THEN
    IF p_numpr = 1 THEN
    VNPRECO := p_regprecos.pvendasemimposto1;
    ELSIF p_numpr = 2 THEN
    VNPRECO := p_regprecos.pvendasemimposto2;
    ELSIF p_numpr = 3 THEN
    VNPRECO := p_regprecos.pvendasemimposto3;
    ELSIF p_numpr = 4 THEN
    VNPRECO := p_regprecos.pvendasemimposto4;
    ELSIF p_numpr = 5 THEN
    VNPRECO := p_regprecos.pvendasemimposto5;
    ELSIF p_numpr = 6 THEN
    VNPRECO := p_regprecos.pvendasemimposto6;
    ELSIF p_numpr = 7 THEN
    VNPRECO := p_regprecos.pvendasemimposto7;
    END IF;
  ELSE
    IF p_numpr = 1 THEN
    VNPRECO := p_regprecos.pvenda1;
    ELSIF p_numpr = 2 THEN
    VNPRECO := p_regprecos.pvenda2;
    ELSIF p_numpr = 3 THEN
    VNPRECO := p_regprecos.pvenda3;
    ELSIF p_numpr = 4 THEN
    VNPRECO := p_regprecos.pvenda4;
    ELSIF p_numpr = 5 THEN
    VNPRECO := p_regprecos.pvenda5;
    ELSIF p_numpr = 6 THEN
    VNPRECO := p_regprecos.pvenda6;
    ELSIF p_numpr = 7 THEN
    VNPRECO := p_regprecos.pvenda7;
    END IF;

  END IF;


  vnPrecoTabelaCesta := vnPreco;


  return(vnPrecoTabelaCesta);
END FUNC_RETORNARPTABELACESTA;

FUNCTION F_RETORNARDESCFAIXACAMPANHASQP(pNUMPEDRCA         IN NUMBER,
                                        pCODUSUR           IN NUMBER,
                                        pDTABERTURAPEDPALM IN DATE,
                                        pCODFILIAL         IN PCPEDC.CODFILIAL%TYPE,
                                        pCODCOMBO          IN NUMBER,
                                        pMSG               OUT VARCHAR2,
                                        vnPerDesc          OUT NUMBER,
                                        pCODPROD           IN PCPEDI.CODPROD%TYPE DEFAULT NULL)
    RETURN NUMBER is

    vnPercDesc                NUMBER := 0;
    vnQTPCPEDIFAIXA           NUMBER;
    vnQTPCPEDICOMBO           NUMBER;
    vnQTPCPEDICOMBO_EMBALAGEM NUMBER;
    vnQTUNIDADES              NUMBER;
    vsUNIDADE                 VARCHAR2(2);
    vnFAIXA                   NUMBER;
    vnCodFaixa                NUMBER;
    vbVendaEmb                BOOLEAN := FALSE;
    vnCODPROD                 PCPEDI.CODPROD%TYPE;
    vSQL                      VARCHAR2(32767);
    vsListaItensFaixa         VARCHAR2(32767);
    vnQTPCPEDIFVFAIXA         NUMBER;
  BEGIN
    vnQTPCPEDICOMBO           := 0;
    vnQTPCPEDICOMBO_EMBALAGEM := 0;
    vnQTUNIDADES              := 0;
    vsUNIDADE                 := '';
    vSQL                      := '';

    BEGIN

      vbVendaEmb := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',
                                                       pCODFILIAL,
                                                       'N') = 'S';

      IF vbVendaEmb THEN
        BEGIN
          SELECT SUM(I.QT * NVL(DECODE(E.QTUNIT, 0, 1, E.QTUNIT), 1)),
				 SUM(I.QT)
            INTO vnQTPCPEDICOMBO, vnQTPCPEDICOMBO_EMBALAGEM
            FROM PCPEDIFV I, PCPEDCFV P,PCEMBALAGEM E
           WHERE I.CODPROD = E.CODPROD
			       AND I.NUMPEDRCA = P.NUMPEDRCA
             AND I.DTABERTURAPEDPALM = P.DTABERTURAPEDPALM
             AND NVL(I.CODFILIALRETIRA,NVL(P.CODFILIALRETIRA,P.CODFILIAL)) = E.CODFILIAL
             AND I.CODAUXILIAR = E.CODAUXILIAR
             AND I.NUMPEDRCA = pNUMPEDRCA
             AND I.CODUSUR = pCODUSUR
             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
             AND I.CODCOMBO = pCODCOMBO;

        EXCEPTION
          WHEN OTHERS THEN
            vnQTPCPEDICOMBO           := 0;
            vnQTPCPEDICOMBO_EMBALAGEM := 0;
        END;

        BEGIN
          SELECT COUNT(E.UNIDADE), MAX(E.UNIDADE)
            INTO vnQTUNIDADES, vsUNIDADE
            FROM PCPEDIFV I, PCPEDCFV P,PCEMBALAGEM E
           WHERE I.CODPROD = E.CODPROD
			       AND I.NUMPEDRCA = P.NUMPEDRCA
             AND I.DTABERTURAPEDPALM = P.DTABERTURAPEDPALM
             AND NVL(I.CODFILIALRETIRA,NVL(P.CODFILIALRETIRA,P.CODFILIAL)) = E.CODFILIAL
             AND I.CODAUXILIAR = E.CODAUXILIAR
             AND I.NUMPEDRCA = pNUMPEDRCA
             AND I.CODUSUR = pCODUSUR
             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
             AND I.CODCOMBO = pCODCOMBO;

        EXCEPTION
          WHEN OTHERS THEN
            vnQTUNIDADES := 0;
            vsUNIDADE    := '';
        END;

      ELSE
        BEGIN
          vnQTPCPEDICOMBO_EMBALAGEM := 0;
          vnQTUNIDADES              := 0;
          vsUNIDADE                 := '';

          SELECT SUM(I.QT)
            INTO vnQTPCPEDICOMBO
            FROM PCPEDIFV I
           WHERE I.NUMPEDRCA = pNUMPEDRCA
             AND I.CODUSUR = pCODUSUR
             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
             AND I.CODCOMBO = pCODCOMBO;

        EXCEPTION
          WHEN OTHERS THEN
            vnQTPCPEDICOMBO           := 0;
            vnQTPCPEDICOMBO_EMBALAGEM := 0;
            vnQTUNIDADES              := 0;
            vsUNIDADE                 := '';
        END;
      END IF;

      IF pCODPROD > 0
        THEN
        vnCODFAIXA := F_BUSCARFAIXAPRODSQP(pNUMPEDRCA,
                                           pCODUSUR,
                                           pDTABERTURAPEDPALM,
                                           pCODFILIAL,
                                           pCODCOMBO,
                                           pMSG,
                                           pCODPROD);
      END IF;

      FOR FAIXAS IN (SELECT C.*
                       FROM PCDESCONTOCATEGORIA C INNER JOIN PCDESCONTOC D
                                                          ON D.CODIGO = C.CODIGO
                      WHERE D.CODIGO = pCODCOMBO
                        AND SYSDATE BETWEEN D.DTINICIO AND D.DTFIM
                        AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vsUNIDADE, 'XX') = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(C.UNIDADE_EMBALAGEM, vsUNIDADE), 'XX')
                        AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vnQTUNIDADES, -1) = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(vnQTUNIDADES,1), -1)
                        AND NVL(vnCODFAIXA, C.SEQ) = C.SEQ
                   ORDER BY PERCDESC DESC) LOOP

        SELECT SUM(QT)
          INTO vnQTPCPEDIFVFAIXA
          FROM (SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPEDCFV PD
                 WHERE I.CODPROD = FAIXAS.TIPOVALOR
                   AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'P - Produto' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPRODUT P , PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
                   AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND P.Codfornec = FAIXAS.TIPOVALOR
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'F - Fornecedor' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPRODUT P, PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
                   AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND P.CODEPTO = FAIXAS.TIPOVALOR
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'D - Departamento' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPRODUT P, PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
				           AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND P.CODSEC = FAIXAS.TIPOVALOR
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'S - Seção' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR) ,1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPRODUT P, PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
				           AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND P.CODCATEGORIA = FAIXAS.TIPOVALOR
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'C - Categoria' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                 FROM PCPEDIFV I, PCPRODUT P, PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
                   AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND P.CODSUBCATEGORIA = FAIXAS.TIPOVALOR
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'SC - Sub-Categoria' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPRODUT P, PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
				           AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND P.CODLINHAPROD = FAIXAS.TIPOVALOR
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'LP - Linha de Produtos' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                UNION ALL
                SELECT SUM(QT * (NVL((CASE
                             WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'N' THEN
                              NVL((SELECT E.QTUNIT
                                 FROM PCEMBALAGEM E
                                WHERE E.CODPROD = I.CODPROD
                                  AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,NVL(PD.CODFILIALRETIRA,PD.CODFILIAL))
                                  AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                             ELSE
                              1
                           END),1))) QT
                  FROM PCPEDIFV I, PCPRODUT P, PCPEDCFV PD
                 WHERE P.CODPROD = I.CODPROD
				           AND I.NUMPEDRCA = PD.NUMPEDRCA
                   AND I.DTABERTURAPEDPALM = PD.DTABERTURAPEDPALM
                   AND 'GP - Grupo de Produtos' = FAIXAS.TIPO
                   AND I.CODCOMBO = FAIXAS.CODIGO
                   AND I.NUMPEDRCA = pNUMPEDRCA
                   AND I.CODUSUR = pCODUSUR
                   AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                   AND I.CODCOMBO = pCODCOMBO
                   AND EXISTS
                 (SELECT 1
                          FROM PCGRUPOSCAMPANHAC GC, PCGRUPOSCAMPANHAI GI
                         WHERE GC.CODGRUPO = GI.CODGRUPO
                           AND GC.CODGRUPO = FAIXAS.TIPOVALOR
                           AND GI.CODGRUPO = FAIXAS.TIPOVALOR
                           AND GC.TIPO = 'GP'
                           AND GI.CODITEM = P.CODPROD
                           AND GI.DTEXCLUSAO IS NULL
                           AND GC.CODFILIAL = NVL(pCODFILIAL, I.CODFILIALRETIRA))) T;

        vsListaItensFaixa := F_BUSCAITENSFAIXASQP(pNUMPEDRCA,
                                                  pCODUSUR,
                                                  pDTABERTURAPEDPALM,
                                                  pCODCOMBO,
                                                  pCODFILIAL,
                                                  FAIXAS.TIPOVALOR,
                                                  FAIXAS.TIPO,
                                                  pMSG);

        IF vbVendaEmb THEN
          vSQL  := '';
          pMSG  := '';

          vSQL := ' SELECT SUM(I.QT * NVL(DECODE(E.QTUNIT, 0, 1, E.QTUNIT), 1)),
						   SUM(I.QT)
					  FROM PCPEDIFV I, PCEMBALAGEM E, PCPEDCFV P
                     WHERE I.CODPROD = E.CODPROD
					             AND I.NUMPEDRCA = P.NUMPEDRCA
                       AND I.DTABERTURAPEDPALM = P.DTABERTURAPEDPALM
                       AND NVL(I.CODFILIALRETIRA,NVL(P.CODFILIALRETIRA,P.CODFILIAL)) = E.CODFILIAL
                       AND I.CODAUXILIAR = E.CODAUXILIAR
                       AND I.NUMPEDRCA = :pNUMPEDRCA
                       AND I.CODUSUR = :pCODUSUR
                       AND I.DTABERTURAPEDPALM = :pDTABERTURAPEDPALM
                       AND I.CODCOMBO = :pCODCOMBO
                       AND I.CODPROD IN('|| vsListaItensFaixa ||')' ||

                  CASE WHEN FAIXAS.TIPO = 'GP - Grupo de Produtos' THEN

                  '    AND I.CODPROD IN(SELECT GI.CODITEM
                                          FROM PCGRUPOSCAMPANHAC GC, PCGRUPOSCAMPANHAI GI
                                          WHERE GC.CODGRUPO = GI.CODGRUPO
                                            AND GC.CODGRUPO = ' || FAIXAS.TIPOVALOR || '
                                            AND GC.TIPO = ''GP''
                                            AND GI.CODITEM = I.CODPROD
                                            AND GI.DTEXCLUSAO IS NULL
                                            AND GC.CODFILIAL = NVL(:pCODFILIAL, I.CODFILIALRETIRA)) '

                  END;

          IF FAIXAS.TIPO = 'GP - Grupo de Produtos' THEN
            EXECUTE IMMEDIATE vSQL
            INTO vnQTPCPEDICOMBO,
                 vnQTPCPEDICOMBO_EMBALAGEM
            USING pNUMPEDRCA, pCODUSUR, pDTABERTURAPEDPALM, pCODCOMBO, pCODFILIAL;
          ELSE
            EXECUTE IMMEDIATE vSQL
            INTO vnQTPCPEDICOMBO,
                 vnQTPCPEDICOMBO_EMBALAGEM
            USING pNUMPEDRCA, pCODUSUR, pDTABERTURAPEDPALM, pCODCOMBO;
          END IF;

        ELSE
          vnQTPCPEDICOMBO := 0;
          vnQTPCPEDICOMBO_EMBALAGEM := 0;
          vSQL  := '';
          pMSG  := '';

          vSQL := ' SELECT SUM(I.QT)
                      FROM PCPEDIFV I
                     WHERE I.NUMPEDRCA = :pNUMPEDRCA
                       AND I.CODUSUR = :pCODUSUR
                       AND I.DTABERTURAPEDPALM = :pDTABERTURAPEDPALM
                       AND I.CODCOMBO = :pCODCOMBO
                       AND I.CODPROD IN('|| vsListaItensFaixa ||')' ||

                  CASE WHEN FAIXAS.TIPO = 'GP - Grupo de Produtos' THEN

                  '    AND I.CODPROD IN(SELECT GI.CODITEM
                                          FROM PCGRUPOSCAMPANHAC GC, PCGRUPOSCAMPANHAI GI
                                          WHERE GC.CODGRUPO = GI.CODGRUPO
                                            AND GC.CODGRUPO = ' || FAIXAS.TIPOVALOR || '
                                            AND GC.TIPO = ''GP''
                                            AND GI.CODITEM = I.CODPROD
                                            AND GI.DTEXCLUSAO IS NULL
                                            AND GC.CODFILIAL = NVL(:pCODFILIAL, I.CODFILIALRETIRA)) '

                  END;

          IF FAIXAS.TIPO = 'GP - Grupo de Produtos' THEN
            EXECUTE IMMEDIATE vSQL
            INTO vnQTPCPEDICOMBO
            USING pNUMPEDRCA, pCODUSUR, pDTABERTURAPEDPALM, pCODCOMBO, pCODFILIAL;
          ELSE
            EXECUTE IMMEDIATE vSQL
            INTO vnQTPCPEDICOMBO
            USING pNUMPEDRCA, pCODUSUR, pDTABERTURAPEDPALM, pCODCOMBO;
          END IF;
        END IF;

        IF (vnQTPCPEDIFVFAIXA BETWEEN FAIXAS.INICIOINTERVALO AND
           FAIXAS.FIMINTERVALO) AND
           vnQTPCPEDIFVFAIXA =
           (CASE WHEN NVL(FAIXAS.EMBALAGEM_UNICA, 'N') = 'S' THEN
            vnQTPCPEDICOMBO_EMBALAGEM ELSE vnQTPCPEDICOMBO END) AND
           FAIXAS.PERCDESC > vnPercDesc THEN

          vnPercDesc := FAIXAS.PERCDESC;
          vnFAIXA    := FAIXAS.SEQ;

        END IF;

      END LOOP;

      IF nvl(vnPercDesc,0) = 0 THEN
        pMSG := 'Campanha de combo Cód: ' || pCODCOMBO ||
                ', não localizada ou inexistente no pedido!';
      END IF;

      RETURN vnPercDesc;

    EXCEPTION
      WHEN OTHERS THEN
        pMSG := 'Erro ao retornar faixa Campanha Combo: ' || SQLCODE || '-' ||
                SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        return 0;
    END;

    return(vnPerDesc);

  END F_RETORNARDESCFAIXACAMPANHASQP;

  FUNCTION func_consulta_inservivel(pCodProd IN NUMBER) RETURN INTEGRADORA_COMPLE.T_INSERVIVEL IS
      R_DADOS INTEGRADORA_COMPLE.T_INSERVIVEL;

    BEGIN

      SELECT
        NVL(P.ACEITATROCAINSERVIVEL, 'N'),
        NVL(P.CARCACABATERIA, 'N'),
        P.CODPROD,
        NVL(I.CODINSERVIVEL, 0),
        I.PESO,
        I.VLVENDA
      INTO
        R_DADOS.ACEITATROCAINSERVIVEL,
        R_DADOS.CARCACABATERIA,
        R_DADOS.CODPROD,
        R_DADOS.CODINSERVIVEL,
        R_DADOS.PESO,
        R_DADOS.VLKG
      FROM
        PCINSERVIVEL I,
        PCPRODUT P
      WHERE
            P.CODINSERVIVEL = I.CODINSERVIVEL(+)
        AND P.CODPROD = pCodProd;

      RETURN R_DADOS;

  END func_consulta_inservivel;

  FUNCTION func_inservivel_vencido(pCodCli IN NUMBER) RETURN BOOLEAN IS
    TEM_MOVIMENTO_VENCIDO VARCHAR2(1);
  BEGIN

    SELECT
      (CASE
        WHEN EXISTS
         (SELECT MI.NUMPED,
                     MI.CODPROD,
                     SUM(MI.SALDOKG) AS SALDOKG,
                     SUM(MI.SALDOVL) AS SALDOVL
                FROM PCMOVINSERVIVEL MI
               WHERE MI.DTEXCLUSAO IS NULL
                 AND MI.CODCLI = C.CODCLI
                 AND MI.DTVALIDADE < SYSDATE
                 AND NOT EXISTS
               (SELECT 1
                        FROM PCMOVINSERVIVEL M
                       WHERE M.CODMOVINSERVIVELORIGEM = MI.CODMOVINSERVIVEL)
                 AND MI.CODMOVINSERVIVELORIGEM IS NULL
               GROUP BY MI.NUMPED, MI.CODPROD, MI.DTEXCLUSAO, MI.DTVALIDADE
              HAVING SUM(MI.SALDOKG) < 0) THEN
         'S'
        ELSE
         'N'
        END) AS TEMMOVVENCIDO
    INTO TEM_MOVIMENTO_VENCIDO
    FROM PCCLIENT C, PCROTAINSERVIVEL RT
    WHERE C.CODROTAINSERVIVEL = RT.CODROTAINSERVIVEL(+)
      AND C.CODCLI = pCodCli;

    RETURN TEM_MOVIMENTO_VENCIDO = 'S';

  END func_inservivel_vencido;

  PROCEDURE proc_movimenta_inservivel
  (
   p_regpedido       IN integradora_comple.t_cabped,
   p_regcliente      IN integradora_comple.t_clientepedido,
   p_regitem         IN integradora_comple.t_itemped
  ) IS

    vrInservivel       INTEGRADORA_COMPLE.T_INSERVIVEL;
    vnCodMovInservivel NUMBER;
  BEGIN

    vrInservivel := func_consulta_inservivel(p_regitem.codprod);

    IF (vrInservivel.aceitatrocainservivel = 'S') AND (vrInservivel.codinservivel <> 0) THEN

        SELECT DFSEQ_PCMOVINSERVIVEL.NEXTVAL
               INTO vnCodMovInservivel
        FROM DUAL;

        INSERT INTO PCMOVINSERVIVEL (
                CODMOVINSERVIVEL,
                CODCLI,
                CODFILIAL,
                CODPROD,
                NUMPED,
                DTINCLUSAO,
                DTVALIDADE,
                SALDOKG,
                SALDOVL,
                STATUS,
                TIPOMOVIMENTO
        ) VALUES (
                vnCodMovInservivel,
                p_regcliente.codcli,
                p_regpedido.codfilial,
                p_regitem.codprod,
                p_regpedido.numped,
                SYSDATE,
                decode( p_regcliente.prazoentregacarcaca, 0, NULL, SYSDATE + p_regcliente.prazoentregacarcaca),
                (p_regitem.QT * vrInservivel.peso) * -1,
                (p_regitem.QT * (vrInservivel.peso * vrInservivel.vlkg)) * -1,
                'PT',
                'DDC'
        );

        INSERT INTO PCHISTMOVINSERVIVEL
             (
                    CODHISTMOVINSERVIVEL,
                    CODMOVINSERVIVEL,
                    DTREGISTRO,
                    ROTINA,
                    USUARIO,
                    EQUIPAMENTO,
                    SALDOKG,
                    SALDOKGANT,
                    SALDOVL,
                    SALDOVLANT,
                    HISTORICO
            ) VALUES (
                    DFSEQ_PCHISTMOVINSERVIVEL.NEXTVAL,
                    vnCodMovInservivel,
                    SYSDATE,
                    'INTEGRADORA',
                    p_regpedido.CODUSUR,
                    NULL,
                    (p_regitem.QT * vrInservivel.peso) * -1,
                    0,
                    (p_regitem.QT * (vrInservivel.peso * vrInservivel.vlkg)) * -1,
                    0,
                    'Lançamento de débito pela importadora de pedidos FV Número pedido: ' ||
                      p_regpedido.numped
             );
      END IF;

  END proc_movimenta_inservivel;

  FUNCTION F_BUSCARFAIXAPRODSQP(pNUMPEDRCA         IN NUMBER,
                              pCODUSUR           IN NUMBER,
                              pDTABERTURAPEDPALM IN DATE,
                              pCODFILIAL         IN PCPEDC.CODFILIAL%TYPE,
                              pCODCOMBO          IN NUMBER,
                              pMSG               OUT VARCHAR2,
                              pCODPROD           IN PCPEDI.CODPROD%TYPE DEFAULT NULL)
    RETURN NUMBER is

    vnQTUNIDADES       NUMBER;
    vsUNIDADE          VARCHAR2(2);
    vnCODFAIXA         NUMBER := 0;
    vnQTPCPEDIFVFAIXA  NUMBER := 0;
	vsSQL			   VARCHAR(32767);

  BEGIN


    BEGIN
	  vnQTUNIDADES := 0;
      vsUNIDADE    := '';
      vsSQL := '';
      BEGIN
        vsSQL := '  SELECT COUNT(E.UNIDADE), MAX(E.UNIDADE)
          FROM PCPEDIFV I, PCPEDCFV P, PCEMBALAGEM E
         WHERE I.CODPROD = E.CODPROD
           AND I.NUMPEDRCA = P.NUMPEDRCA
           AND I.DTABERTURAPEDPALM = P.DTABERTURAPEDPALM
           AND NVL(I.CODFILIALRETIRA,:pCODFILIAL) = E.CODFILIAL
           AND I.CODAUXILIAR = E.CODAUXILIAR
           AND I.NUMPEDRCA = :pNUMPEDRCA
           AND I.CODUSUR = :pCODUSUR
           AND NVL(:pCODPROD, I.CODPROD) = I.CODPROD
           AND  TO_CHAR(I.DTABERTURAPEDPALM, ''DD/MM/YYYY'')  = TO_CHAR(:pDTABERTURAPEDPALM, ''DD/MM/YYYY'')
           AND I.CODCOMBO = :pCODCOMBO ';

     EXECUTE IMMEDIATE vsSQL
            INTO vnQTUNIDADES,
                 vsUNIDADE
           USING pCODFILIAL,pNUMPEDRCA, pCODUSUR,  pCODPROD, pDTABERTURAPEDPALM, pCODCOMBO;

      EXCEPTION
        WHEN OTHERS THEN
          vnQTUNIDADES := 0;
          vsUNIDADE    := '';
      END;

      FOR DADOS_FAIXA_PROD IN(
        SELECT C.*
               FROM PCDESCONTOCATEGORIA C INNER JOIN PCDESCONTOC D
                                                  ON D.CODIGO = C.CODIGO
              WHERE D.CODIGO = pCODCOMBO
                AND SYSDATE BETWEEN D.DTINICIO AND D.DTFIM
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vsUNIDADE, 'XX') = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(C.UNIDADE_EMBALAGEM, vsUNIDADE), 'XX')
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vnQTUNIDADES, -1) = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(vnQTUNIDADES,1), -1)
           ORDER BY C.PERCDESC DESC) LOOP

      BEGIN
      SELECT SUM(QT)
        INTO vnQTPCPEDIFVFAIXA
        FROM (SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I
                    WHERE I.CODPROD = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'P - Produto' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND P.Codfornec = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'F - Fornecedor' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND P.CODEPTO = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'D - Departamento' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND P.CODSEC = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'S - Seção' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND P.CODCATEGORIA = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'C - Categoria' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND P.CODSUBCATEGORIA = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'SC - Sub-Categoria' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND P.CODLINHAPROD = DADOS_FAIXA_PROD.TIPOVALOR
                      AND 'LP - Linha de Produtos' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                   UNION ALL
                   SELECT SUM(QT * (NVL((CASE
                                WHEN NVL(DADOS_FAIXA_PROD.EMBALAGEM_UNICA, 'N') = 'N' THEN
                                 NVL((SELECT E.QTUNIT
                                    FROM PCEMBALAGEM E
                                   WHERE E.CODPROD = I.CODPROD
                                     AND E.CODFILIAL = NVL(I.CODFILIALRETIRA,pCODFILIAL)
                                     AND E.CODAUXILIAR = I.CODAUXILIAR),1)
                                ELSE
                                 1
                              END),1))) QT
                     FROM PCPEDIFV I, PCPRODUT P
                    WHERE P.CODPROD = I.CODPROD
                      AND 'GP - Grupo de Produtos' = DADOS_FAIXA_PROD.TIPO
                      AND I.NUMPEDRCA = pNUMPEDRCA
                      AND I.CODUSUR = pCODUSUR
                      AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                      AND I.CODCOMBO = pCODCOMBO
                      AND EXISTS
                    (SELECT 1
                          FROM PCGRUPOSCAMPANHAC GC, PCGRUPOSCAMPANHAI GI
                         WHERE GC.CODGRUPO = GI.CODGRUPO
                           AND GC.CODGRUPO = DADOS_FAIXA_PROD.TIPOVALOR
                           AND GC.TIPO = 'GP'
                           AND GI.CODITEM = P.CODPROD
                           AND GI.DTEXCLUSAO IS NULL
                           AND GC.CODFILIAL =
                               NVL(pCODFILIAL, I.CODFILIALRETIRA)));
      EXCEPTION
        WHEN OTHERS THEN
          vnQTPCPEDIFVFAIXA := 0;
      END;

      BEGIN
        SELECT A.SEQ
          INTO vnCODFAIXA
          FROM (SELECT C.*
               FROM PCDESCONTOCATEGORIA C INNER JOIN PCDESCONTOC D
                                                  ON D.CODIGO = C.CODIGO
              WHERE D.CODIGO = pCODCOMBO
                AND SYSDATE BETWEEN D.DTINICIO AND D.DTFIM
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vsUNIDADE, 'XX') = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(C.UNIDADE_EMBALAGEM, vsUNIDADE), 'XX')
                AND DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', vnQTUNIDADES, -1) = DECODE(NVL(C.EMBALAGEM_UNICA, 'N'), 'S', NVL(vnQTUNIDADES,1), -1)
                   AND EXISTS
                 (SELECT I.CODPROD
                          FROM PCPEDIFV I
                         WHERE I.CODPROD = C.TIPOVALOR
                           AND 'P - Produto' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT I.CODPROD
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND P.Codfornec = C.TIPOVALOR
                           AND 'F - Fornecedor' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT I.CODPROD
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND P.CODEPTO = C.TIPOVALOR
                           AND 'D - Departamento' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT I.CODPROD
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND P.CODSEC = C.TIPOVALOR
                           AND 'S - Seção' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT I.CODPROD
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND P.CODCATEGORIA = C.TIPOVALOR
                           AND 'C - Categoria' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT I.CODPROD
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND P.CODSUBCATEGORIA = C.TIPOVALOR
                           AND 'SC - Sub-Categoria' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT I.CODPROD
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND P.CODLINHAPROD = C.TIPOVALOR
                           AND 'LP - Linha de Produtos' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                        UNION ALL
                        SELECT 1
                          FROM PCPEDIFV I, PCPRODUT P
                         WHERE P.CODPROD = I.CODPROD
                           AND 'GP - Grupo de Produtos' = C.TIPO
                           AND I.CODCOMBO = C.CODIGO
                           AND I.NUMPEDRCA = pNUMPEDRCA
                           AND I.CODUSUR = pCODUSUR
                           AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                           AND I.CODCOMBO = pCODCOMBO
                           AND ((vnQTPCPEDIFVFAIXA BETWEEN
                                 C.INICIOINTERVALO AND C.FIMINTERVALO))
                           AND EXISTS
                         (SELECT 1
                                  FROM PCGRUPOSCAMPANHAC GC,
                                       PCGRUPOSCAMPANHAI GI
                                 WHERE GC.CODGRUPO = GI.CODGRUPO
                                   AND GC.CODGRUPO = C.TIPOVALOR
                                   AND GC.TIPO = 'GP'
                                   AND GI.CODITEM = P.CODPROD
                                   AND GI.DTEXCLUSAO IS NULL
                                   AND GC.CODFILIAL =
                                       NVL(pCODFILIAL, I.CODFILIALRETIRA)))
                 ORDER BY PERCDESC DESC) A
         WHERE ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          vnCODFAIXA := 0;
      END;

      IF vnCODFAIXA <> 0
        THEN
          EXIT;
      END IF;

      END LOOP;

      IF nvl(vnCODFAIXA, 0) = 0 THEN
        pMSG := 'Faixa da campanha combo Cód' || pCODCOMBO ||
                ', não localizada ou inexistente no item!';
      END IF;

      RETURN vnCodFaixa;

    EXCEPTION
      WHEN OTHERS THEN
        pMSG := 'Erro ao buscar faixa Campanha Combo para o produto ' ||
                pCODPROD || ': ' || SQLCODE || '-' || SQLERRM || '-' ||
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        return 0;

    END;

    return(vnCodFaixa);
  END F_BUSCARFAIXAPRODSQP;

  FUNCTION F_BUSCAITENSFAIXASQP(pNUMPEDRCA         IN NUMBER,
                                pCODUSUR           IN NUMBER,
                                pDTABERTURAPEDPALM IN DATE,
                                pCODCOMBO          IN NUMBER,
                                pCODFILIAL         IN VARCHAR2 DEFAULT NULL,
                                pCODFAIXA          IN NUMBER DEFAULT NULL,
                                pTIPOCAMPANHA      IN VARCHAR2 DEFAULT NULL,
                                pMSG               OUT VARCHAR2) RETURN VARCHAR2 is

  vsListaProdutos VARCHAR2(4000);

  BEGIN
    vsListaProdutos := '';

    FOR DADOS_CODPROD IN (SELECT I.CODPROD
                            FROM PCPEDIFV I
                           WHERE I.CODPROD = pCODFAIXA
                             AND 'P - Produto' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE P.Codfornec = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'F - Fornecedor' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE P.CODEPTO = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'D - Departamento' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE P.CODSEC = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'S - Seção' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE P.CODCATEGORIA = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'C - Categoria' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE P.CODSUBCATEGORIA = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'SC - Sub-Categoria' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE P.CODLINHAPROD = pCODFAIXA
                             AND P.CODPROD = I.CODPROD
                             AND 'LP - Linha de Produtos' = pTIPOCAMPANHA
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                          UNION ALL
                          SELECT I.CODPROD
                            FROM PCPEDIFV I, PCPRODUT P
                           WHERE 'GP - Grupo de Produtos' = pTIPOCAMPANHA
                             AND P.CODPROD = I.CODPROD
                             AND I.CODCOMBO = pCODCOMBO
                             AND I.NUMPEDRCA = pNUMPEDRCA
                             AND I.CODUSUR   = pCODUSUR
                             AND I.DTABERTURAPEDPALM = pDTABERTURAPEDPALM
                             AND EXISTS
                           (SELECT 1
                                    FROM PCGRUPOSCAMPANHAC GC,
                                         PCGRUPOSCAMPANHAI GI
                                   WHERE GC.CODGRUPO = GI.CODGRUPO
                                     AND GC.CODGRUPO = pCODFAIXA
                                     AND GI.CODGRUPO = pCODFAIXA
                                     AND GC.TIPO = 'GP'
                                     AND GI.CODITEM = P.CODPROD
                                     AND GI.DTEXCLUSAO IS NULL
                                     AND GC.CODFILIAL =
                                         NVL(pCODFILIAL, I.CODFILIALRETIRA)))

     LOOP
      IF SQL%ROWCOUNT > 0 THEN
        IF vsListaProdutos IS NULL THEN
          vsListaProdutos := DADOS_CODPROD.CODPROD;
        ELSE
          vsListaProdutos := vsListaProdutos || ',' || DADOS_CODPROD.CODPROD;

        END IF;

      END IF;


    END LOOP;

    if vsListaProdutos IS NOT NULL THEN
      pMSG := 'Produtos da faixa ' || pCODFAIXA ||
              ', da campanha combo Cód: ' || pCODCOMBO ||
              ' validado(s) com sucesso!';
    END IF;

    RETURN vsListaProdutos;

  EXCEPTION
    WHEN OTHERS THEN
      pMSG := 'Produtos da faixa ' || pCODFAIXA ||
              ', da campanha combo Cód: ' || pCODCOMBO ||
              ', não localizado(s) ou inexistente(s) no pedido!';
      return '0';

  END;

end INTEGRADORA_COMPLE;

