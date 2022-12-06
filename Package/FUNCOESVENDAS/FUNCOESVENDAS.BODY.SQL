CREATE OR REPLACE PACKAGE BODY FUNCOESVENDAS IS

  FUNCTION validarpoliticaprecofixo -- 18 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN

    vbresult := validarpoliticaprecofixo(--19 parametros
                                         p_codprod,
                                         p_data,
                                         p_numregiao,
                                         p_codcli,
                                         p_condvenda,
                                         p_codplpag,
                                         p_ptabela,
                                         p_validapvendabonific,
                                         p_utilizapercfinprecoprom,
                                         p_pertxfim,
                                         p_numdias,
                                         p_codcliprinc,
                                         p_codprodprinc,
                                         p_codpraca,
                                         p_codusur,
                                         0, --p_codsupervisor,
                                         p_dtfim,
                                         p_mensagem,
                                         p_precofixo
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Preco Fixo ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticaprecofixo;

  FUNCTION validardescontoquantidade(--10 parametros
                                     p_tipoteste        IN NUMBER,
                                     p_codprod          IN NUMBER,
                                     p_qtde             IN NUMBER,
                                     p_numregiao        IN NUMBER,
                                     p_ptabela          IN NUMBER,
                                     p_codpraca         IN NUMBER,
                                     p_numcasasdecvenda IN NUMBER,
                                     p_dtfim            OUT DATE,
                                     p_mensagem         OUT VARCHAR2,
                                     p_ptabeladesc      OUT NUMBER) RETURN BOOLEAN IS

    vbresult   BOOLEAN;

  BEGIN

    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_ptabela, --p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc);

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;

  END validardescontoquantidade;

  /* Esta funcao tem um parâmetro a mais ( p_pvenda1) que será utilizado para validar o campo
  pcdescquant.perdescmax */
  FUNCTION validardescontoquantidade -- 11 parametros
  (p_tipoteste        IN NUMBER,
   p_codprod          IN NUMBER,
   p_qtde             IN NUMBER,
   p_numregiao        IN NUMBER,
   p_ptabela          IN NUMBER,
   p_pvenda1          IN NUMBER,
   p_codpraca         IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_ptabeladesc      OUT NUMBER) RETURN BOOLEAN IS

    vbresult           BOOLEAN;

  BEGIN

    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          NULL, --p_numdias,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc);

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;

  END validardescontoquantidade;

  FUNCTION validarpoliticasdesconto -- 13 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN IS

    vbresult          BOOLEAN;

  BEGIN

    vbresult := validarpoliticasdesconto(--14 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         0, --p_codplpag,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION validarpoliticasdesconto_acres -- 13 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN IS

    vbresult             BOOLEAN;

  BEGIN

    vbresult := validarpoliticasdesconto_acres(p_codprod,
                                               p_data,
                                               p_codfilial,
                                               p_numregiao,
                                               p_codcli,
                                               p_codusur,
                                               p_origempedido,
                                               p_codprodprinc,
                                               p_numcasasdecvenda,
                                               0, --p_codplpag,
                                               p_dtfim,
                                               p_mensagem,
                                               p_perdesc,
                                               p_basecreddebrca
                                              );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos Acres: ' ||
                    SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto_acres;

  FUNCTION validarpoliticasdesconto -- 14 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_codplpag         IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN IS

    vbresult          BOOLEAN;

  BEGIN

    vbresult := validarpoliticasdesconto(--15 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         'C', --p_tipo,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION validarpoliticasdesconto_acres -- 14 parametros
  (p_codprod          IN NUMBER,
   p_data             IN DATE,
   p_codfilial        IN VARCHAR2,
   p_numregiao        IN NUMBER,
   p_codcli           IN NUMBER,
   p_codusur          IN NUMBER,
   p_origempedido     IN VARCHAR2,
   p_codprodprinc     IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_codplpag         IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_perdesc          OUT NUMBER,
   p_basecreddebrca   OUT VARCHAR2) RETURN BOOLEAN IS
    CURSOR c_semrede(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER) IS
      SELECT percdesc, nvl(basecreddebrca, 'N') basecreddebrca, dtfim
        FROM pcdesconto
       WHERE p_data BETWEEN dtinicio AND dtfim
         AND nvl(utilizadescrede, 'N') = 'N'
         AND ((codepto = vncodepto) OR (codepto IS NULL))
         AND ((codsec = vncodsec) OR (codsec IS NULL))
         AND ((codcategoria = vncodcategoria) OR (codcategoria IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codfornec = vncodfornec) OR (codfornec IS NULL))
         AND ((codusur = p_codusur) OR (codusur IS NULL))
         AND ((codsupervisor = vncodsupervisor) OR (codsupervisor IS NULL))
         AND ((codcli = p_codcli) OR (codcli IS NULL))
         AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
         AND ((codativ = vncodatv1) OR (codativ IS NULL))
         AND ((origemped = p_origempedido) OR (nvl(origemped, 'O') = 'O'))
         AND ((codpraca = vncodpraca) OR (codpraca IS NULL))
         AND ((codprodprinc = p_codprodprinc) OR (codprodprinc IS NULL))
         AND pcdesconto.percdesc < 0
         AND ((codplpag = p_codplpag) OR (codplpag IS NULL))
       ORDER BY pcdesconto.percdesc DESC;
    CURSOR c_comrede(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vncodcliprinc IN NUMBER) IS
      SELECT percdesc, nvl(basecreddebrca, 'N') basecreddebrca, dtfim
        FROM pcdesconto
       WHERE codcli = vncodcliprinc
         AND p_data BETWEEN dtinicio AND dtfim
         AND nvl(utilizadescrede, 'N') = 'S'
         AND ((codepto = vncodepto) OR (codepto IS NULL))
         AND ((codsec = vncodsec) OR (codsec IS NULL))
         AND ((codcategoria = vncodcategoria) OR (codcategoria IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codusur = p_codusur) OR (codusur IS NULL))
         AND ((codsupervisor = vncodsupervisor) OR (codsupervisor IS NULL))
         AND ((codfornec = vncodfornec) OR (codfornec IS NULL))
         AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
         AND ((codativ = vncodatv1) OR (codativ IS NULL))
         AND ((origemped = p_origempedido) OR (nvl(origemped, 'O') = 'O'))
         AND ((codpraca = vncodpraca) OR (codpraca IS NULL))
         AND pcdesconto.percdesc < 0
         AND ((codplpag = p_codplpag) OR (codplpag IS NULL));
    vbresult             BOOLEAN;
    vntempperdesc        NUMBER;
    vstempbasecreddebrca VARCHAR2(2);
    vnpercdesc           NUMBER;
    vsbasecreddebrca     VARCHAR2(2);
    --Dados do Cliente
    vncodcliprinc NUMBER;
    vncodatv1     NUMBER;
    vncodpraca    NUMBER;
    --Dados do RCA
    vncodsupervisor NUMBER;
    --Dados do Produto}
    vncodfornec                NUMBER;
    vncodepto                  NUMBER;
    vncodsec                   NUMBER;
    vncodcategoria             NUMBER;
    vncodsubcategoria          NUMBER;
    vicont                     NUMBER;
    vicont2                    NUMBER;
    vicont3                    NUMBER;
    vicontador                 NUMBER;
    vicontador2                NUMBER;
    p_tratarrestricaoacrescimo VARCHAR2(1);
  BEGIN
    vbresult         := FALSE;
    vnpercdesc       := 0;
    vsbasecreddebrca := 'N';
    SELECT nvl(tratarrestricaoacrescimo, 'N')
      INTO p_tratarrestricaoacrescimo
      FROM pcconsum;
    --Buscar dados do cliente
    SELECT COUNT(*) INTO vicont FROM pcclient WHERE codcli = p_codcli;
    IF vicont <> 0 THEN
      SELECT nvl(codcliprinc, codcli) codcliprinc, codatv1, codpraca
        INTO vncodcliprinc, vncodatv1, vncodpraca
        FROM pcclient
       WHERE codcli = p_codcli;
      --Buscar dados do RCA
      SELECT COUNT(*) INTO vicont2 FROM pcusuari WHERE codusur = p_codusur;
      IF vicont2 <> 0 THEN
        SELECT codsupervisor
          INTO vncodsupervisor
          FROM pcusuari
         WHERE codusur = p_codusur;
        --Buscar dados do produto
        SELECT COUNT(*)
          INTO vicont3
          FROM pcprodut
         WHERE codprod = p_codprod;
        IF vicont3 <> 0 THEN
          SELECT codfornec, codepto, codsec, codcategoria, codsubcategoria
            INTO vncodfornec,
                 vncodepto,
                 vncodsec,
                 vncodcategoria,
                 vncodsubcategoria
            FROM pcprodut
           WHERE codprod = p_codprod;
          --Verificação de Políticas de Descontos}
          FOR reg_semrede IN c_semrede(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca) LOOP
            vbresult             := TRUE;
            vntempperdesc        := reg_semrede.percdesc;
            vstempbasecreddebrca := reg_semrede.basecreddebrca;
            IF vntempperdesc < vnpercdesc THEN
              vnpercdesc       := vntempperdesc;
              vsbasecreddebrca := vstempbasecreddebrca;
            END IF;
          END LOOP;
          FOR reg_comrede IN c_comrede(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vncodcliprinc) LOOP
            vbresult             := TRUE;
            vntempperdesc        := reg_comrede.percdesc;
            vstempbasecreddebrca := reg_comrede.basecreddebrca;
            IF vntempperdesc < vnpercdesc THEN
              vnpercdesc       := vntempperdesc;
              vsbasecreddebrca := vstempbasecreddebrca;
            END IF;
          END LOOP;
        ELSE
          p_mensagem := 'Não foi possível buscar dados do PCPRODUT!';
        END IF;
      ELSE
        p_mensagem := 'Não foi possível buscar dados do PCUSUARI!';
      END IF; --dados do PCCLIENT
    ELSE
      p_mensagem := 'Não foi possível buscar dados do PCCLIENT!';
    END IF;
    p_perdesc        := (round(vnpercdesc, p_numcasasdecvenda)) * -1;
    p_basecreddebrca := vsbasecreddebrca;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos Acres: ' ||
                    SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END validarpoliticasdesconto_acres;

  FUNCTION validarpoliticasdesconto -- 18 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER) RETURN BOOLEAN IS

    vbresult                BOOLEAN;
    vscreditasobrepolitica  VARCHAR2(1);

  BEGIN

    vbresult := validarpoliticasdesconto(--19 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         vscreditasobrepolitica,
                                         p_perdescrestricao
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION validarpoliticaprecofixo -- 19 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN

    vbresult := validarpoliticaprecofixo(--20 parametros
                                         p_codprod,
                                         p_data,
                                         p_numregiao,
                                         p_codcli,
                                         p_condvenda,
                                         p_codplpag,
                                         p_ptabela,
                                         p_validapvendabonific,
                                         p_utilizapercfinprecoprom,
                                         p_pertxfim,
                                         p_numdias,
                                         p_codcliprinc,
                                         p_codprodprinc,
                                         p_codpraca,
                                         p_codusur,
                                         p_codsupervisor,
                                         0, --p_numlote,
                                         p_dtfim,
                                         p_mensagem,
                                         p_precofixo
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Preco Fixo ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticaprecofixo;

  FUNCTION calcularst -- 25 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,--10
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,--20
   p_valorultent            IN NUMBER,
   p_contribuinte           IN VARCHAR2,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;
    vntempst        NUMBER;
    vstempmsg       VARCHAR2(1000);
    vnpercbaseredst NUMBER;
    vnbaseicst_temp NUMBER;

  BEGIN

   vbresult := calcularst(p_pvenda,
                          p_vlipi,
                          p_percvenda,
                          p_tipocalcst,
                          p_calcstpf,
                          p_mostrarpvendasemst,
                          p_consideraisentoscomopf,
                          p_calculast,
                          p_ieent,
                          p_tipofj,--10
                          p_pauta,
                          p_iva,
                          p_aliqicms1,
                          p_aliqicms2 ,
                          vnpercbaseredst,
                          p_numcasasdecvenda,
                          p_tipocalculo,
                          p_uffilial,
                          p_estent,
                          p_usavalorultentbasest,--20
                          ---------------------------
                          --O parâmetro abaixo será considerado sempre como "N"
                          --simulando casos específicos onde a opção não existe.
                          'N', --p_usavalorultentbasest2,
                          ---------------------------
                          p_valorultent,
                          p_contribuinte,
                          vstempmsg,
                          vntempst,
                          vnbaseicst_temp
                          );

    p_percbaseredst := vnpercbaseredst;
    p_mensagem := vstempmsg;
    p_st := vntempst;
    p_baseicst := vnbaseicst_temp;

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST (25Params): ' || SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END calcularst;

  -- Sabrina em 24/07/2008: tratar pctribut.usavalorultentbasest2
  FUNCTION calcularst -- 26 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,--10
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,--20
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_contribuinte           IN VARCHAR2,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;
    vntempst        NUMBER;
    vstempmsg       VARCHAR2(1000);
    vnpercbaseredst NUMBER;
    vnbaseicst_temp NUMBER;

  BEGIN

    vbresult := calcularst(p_pvenda,
                           p_vlipi,
                           p_percvenda,
                           p_tipocalcst,
                           p_calcstpf,
                           p_mostrarpvendasemst,
                           p_consideraisentoscomopf,
                           p_calculast,
                           p_ieent,
                           p_tipofj,--10
                           p_pauta,
                           p_iva,
                           p_aliqicms1,
                           p_aliqicms2 ,
                           vnpercbaseredst,
                           p_numcasasdecvenda,
                           p_tipocalculo,
                           p_uffilial,
                           p_estent,
                           p_usavalorultentbasest,--20
                           p_usavalorultentbasest2,
                           p_valorultent,
                           p_contribuinte,
                           'N', --p_utilizaiesimplificada -> este parâmetro não está sendo utilizado
                           vstempmsg,
                           vntempst,
                           vnbaseicst_temp,
                           ----------------------------------
                           --Para cada parâmetro abaixo será considerado
                           --o seu próprio valor default
                           'S', --p_aceitapfcontribuinte
                           'N', --p_usapmcbasest
                           0,   --p_precomaxconsum   --30
                           0,   --p_custonfsemst
                           'N', --p_consumidorfinal
                           'N', --p_consideraripialiqicms2
                           'N', --p_usavlultentmediobasest
                           0,   --p_vlultentmes
                           0    --p_percbasestrj
                           ----------------------------------
                           );

    p_percbaseredst := vnpercbaseredst;
    p_mensagem := vstempmsg;
    p_st := vntempst;
    p_baseicst := vnbaseicst_temp;

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST (26Params): ' || SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END calcularst;

  FUNCTION verificarcotarca -- 4 parametros
  (p_codprod  IN NUMBER,
   p_codusur  IN NUMBER,
   p_qtpedida IN NUMBER,
   p_mensagem OUT VARCHAR2) RETURN BOOLEAN IS
    vbresult      BOOLEAN;

  BEGIN

    vbresult := verificarcotarca(p_codprod,
                                 p_codusur,
                                 p_qtpedida,
                                 0, --p_numregiao,
                                 p_mensagem
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Cota RCA: ' || SQLERRM;
      RETURN FALSE;

  END verificarcotarca;

  FUNCTION verificarcotacliente -- 4 parametros
  (p_codprod  IN NUMBER,
   p_codcli   IN NUMBER,
   p_qtpedida IN NUMBER,
   p_mensagem OUT VARCHAR2) RETURN BOOLEAN IS
    vbresult      BOOLEAN;
  BEGIN

    vbresult := verificarcotacliente(p_codprod,
                                     p_codcli,
                                     p_qtpedida,
                                     0, --p_numregiao,
                                     p_mensagem
                                    );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar cota do cliente:' || SQLERRM;
      RETURN FALSE;

  END verificarcotacliente;

  FUNCTION verificarestoquecontabil -- 7 parametros
  (p_codprod             IN NUMBER,
   p_codfilial           IN VARCHAR2,
   p_condvenda           IN INTEGER,
   p_qtpedida            IN NUMBER,
   p_verificaestoquecont IN VARCHAR2,
   p_mensagem            OUT VARCHAR2,
   p_qtestdisp           OUT NUMBER) RETURN BOOLEAN IS
    vbresult      BOOLEAN;
    vnestoque     NUMBER;
    vnqtdereserva NUMBER;
    vnestoquedisp NUMBER;
    vicont        NUMBER;
  BEGIN
    --Inicializar variáveis}
    vbresult      := FALSE;
    vnestoquedisp := 0;
    vnestoque     := 0;
    vnqtdereserva := 0;
    IF (p_condvenda <> 3) AND (p_condvenda <> 6) AND (p_condvenda <> 9) AND
       (p_condvenda <> 12) THEN
      IF p_verificaestoquecont = 'S' THEN
        --Buscar estoque contábil}
        SELECT COUNT(*)
          INTO vicont
          FROM pcest
         WHERE codprod = p_codprod
           AND codfilial = p_codfilial;
        IF vicont <> 0 THEN
          SELECT nvl(qtest, 0) qtest
            INTO vnestoque
            FROM pcest
           WHERE codprod = p_codprod
             AND codfilial = p_codfilial;
          IF vnestoque < 0 THEN
            vnestoque := 0;
          END IF;
          --Buscar quantidade solicitada no período de 3 meses}
          SELECT COUNT(*)
            INTO vicont
            FROM pcpedi, pcpedc
           WHERE pcpedi.data >= (trunc(SYSDATE) - 90) --tem que passar data por causa do índice
             AND pcpedi.codprod = p_codprod
             AND pcpedc.condvenda NOT IN (3, 6, 9, 12)
             AND pcpedc.posicao IN ('L', 'M')
             AND pcpedi.numped = pcpedc.numped;
          IF vicont <> 0 THEN
            SELECT SUM(nvl(pcpedi.qt, 0)) qtpedida
              INTO vnqtdereserva
              FROM pcpedi, pcpedc
             WHERE pcpedi.data >= (trunc(SYSDATE) - 90) --tem que passar data por causa do índice
               AND pcpedi.codprod = p_codprod
               AND pcpedc.condvenda NOT IN (3, 6, 9, 12)
               AND pcpedc.posicao IN ('L', 'M')
               AND pcpedi.numped = pcpedc.numped;
            vnestoquedisp := vnestoque - vnqtdereserva;
            IF vnestoquedisp < 0 THEN
              vnestoquedisp := 0;
            END IF;
            IF vnestoquedisp >= p_qtpedida THEN
              vbresult := TRUE;
            ELSE
              vbresult   := FALSE;
              p_mensagem := 'Não há estoque disponível deste produto!' ||
                            chr(13) || 'Estoque Cont.: ' || vnestoque ||
                            chr(13) ||
                            'Qt. Cont. Pedidos (Últimos 3 meses): ' ||
                            vnqtdereserva || chr(13) ||
                            'Estoque Cont. Disp.: ' || vnestoquedisp;
            END IF;
          ELSE
            p_mensagem := 'Não foram encontrados dados dos pedidos deste produto!';
            vbresult   := FALSE;
          END IF;
        ELSE
          p_mensagem := 'Não foram encontrados dados do estoque do produto!';
          vbresult   := FALSE;
        END IF;
      ELSE
        vbresult := TRUE;
      END IF; --vsVERIFICAESTOQUECONT = 'N'
    ELSE
      vbresult := TRUE;
    END IF; --tipo de venda 3, 6, 9, 12
    p_qtestdisp := vnestoquedisp;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Estoque Contabil: ' || SQLCODE || '-' ||
                    SQLERRM;
  END verificarestoquecontabil;

  FUNCTION verificarvalormaximovendapf -- 12 parametros
  (p_codcli                 IN NUMBER,
   p_vladicional            IN NUMBER,
   p_vlpedoriginal          IN NUMBER,
   p_percvenda              IN NUMBER,
   p_aceitavendapf          IN VARCHAR2,
   p_verificarlimvendapf    IN VARCHAR2,
   p_vlmaxvendapf           IN NUMBER,
   p_perlimvendapf          IN NUMBER,
   p_vlmaxpedidopf          IN NUMBER,
   p_consideraisentoscomopf IN VARCHAR2,
   p_codfilial              IN VARCHAR2,
   p_mensagem               OUT VARCHAR2) RETURN BOOLEAN IS
    vnvlrpedidosmes           NUMBER;
    vnvlrnfmes                NUMBER;
    vnvlrdevmes               NUMBER;
    vnvlrpedidosmespf         NUMBER;
    vnvlrnfmespf              NUMBER;
    vnvlrdevmespf             NUMBER;
    vbresult                  BOOLEAN;
    vstempverificarlimvendapf VARCHAR2(1);
    vsuf_filial               VARCHAR2(2);
    vsestent_cli              VARCHAR2(2);
    vstempmsg                 VARCHAR2(1000);
  BEGIN
    --Iniciar variáveis
    vbresult                  := TRUE;
    vstempmsg                 := '';
    vstempverificarlimvendapf := p_verificarlimvendapf;
    IF (p_aceitavendapf = 'N') THEN
      vstempmsg                 := 'Venda para Pessoa Física não é permitida!';
      vstempverificarlimvendapf := 'N';
      vbresult                  := FALSE;
    END IF;
    IF (nvl(p_vlmaxpedidopf, 0) > 0) THEN
      IF nvl(p_vlmaxpedidopf, 0) <
         (nvl(p_vlpedoriginal, 0) + nvl(p_vladicional, 0)) THEN
        vstempmsg                 := 'Venda para Pessoa Física com valor acima do permitido!';
        vstempverificarlimvendapf := 'N';
        vbresult                  := FALSE;
      END IF;
    END IF;
    --Uf da filial
    vsuf_filial := '';
    BEGIN
      SELECT upper(uf)
        INTO vsuf_filial
        FROM pcfilial
       WHERE codigo = p_codfilial;
    EXCEPTION
      WHEN OTHERS THEN
        vsuf_filial := '';
    END;
    --Uf do cliente
    vsestent_cli := '';
    BEGIN
      SELECT upper(estent)
        INTO vsestent_cli
        FROM pcclient
       WHERE codcli = p_codcli;
    EXCEPTION
      WHEN OTHERS THEN
        vsestent_cli := '';
    END;
    IF (vstempverificarlimvendapf = 'S') THEN
      IF nvl(p_vlmaxvendapf, 0) > 0 THEN
        vnvlrpedidosmes := 0;
        vnvlrnfmes      := 0;
        vnvlrdevmes     := 0;
        BEGIN
          --Valor dos Pedidos ainda não faturados mas liberados
          SELECT SUM(nvl(pcpedc.vlatend, 0) *
                     (nvl(pcpedc.percvenda, 100) / 100)) vlatendpedidos
            INTO vnvlrpedidosmes
            FROM pcpedc
           WHERE pcpedc.codcli = p_codcli
             AND pcpedc.data >=
                 to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                         'DD/MM/YYYY')
             AND pcpedc.codfilial = p_codfilial
             AND pcpedc.condvenda NOT IN (3, 6, 12)
             AND pcpedc.posicao IN ('L', 'M')
             AND pcpedc.dtcancel IS NULL;
        EXCEPTION
          WHEN OTHERS THEN
            vnvlrpedidosmes := 0;
        END;
        BEGIN
          --Valor da NFs do cliente no mês
          SELECT SUM(nvl(pcnfsaid.vltotal, 0)) vltotalnf
            INTO vnvlrnfmes
            FROM pcnfsaid
           WHERE pcnfsaid.codcli = p_codcli
             AND pcnfsaid.dtsaida >=
                 to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                         'DD/MM/YYYY')
             AND pcnfsaid.codfilial = p_codfilial
             AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
             AND pcnfsaid.condvenda NOT IN (3, 6, 12)
             AND pcnfsaid.dtcancel IS NULL;
        EXCEPTION
          WHEN OTHERS THEN
            vnvlrnfmes := 0;
        END;
        BEGIN
          --Buscar valor das devoluções no mês
          SELECT SUM(nvl(pcnfent.vltotal, 0)) vltotaldev
            INTO vnvlrdevmes
            FROM pcnfsaid, pcestcom, pcnfent
           WHERE pcnfsaid.codcli = p_codcli
             AND pcnfsaid.dtsaida >=
                 to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                         'DD/MM/YYYY')
             AND pcnfsaid.codfilial = p_codfilial
             AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
             AND pcnfsaid.dtcancel IS NULL
             AND pcnfent.tipodescarga IN ('6')
             AND pcnfsaid.numtransvenda = pcestcom.numtransvenda
             AND pcestcom.numtransent = pcnfent.numtransent;
        EXCEPTION
          WHEN OTHERS THEN
            vnvlrdevmes := 0;
        END;
        IF (((nvl(vnvlrpedidosmes, 0) + nvl(vnvlrnfmes, 0)) -
           nvl(vnvlrdevmes, 0)) +
           (nvl(p_vladicional, 0) * (p_percvenda / 100))) >
           nvl(p_vlmaxvendapf, 0) THEN
          vstempmsg := 'Vl. Venda para cliente supera o máximo mensal estipulado nos parâmetros do sistema!' ||
                       chr(13) || '(Vl. Máx. Venda PF: $' ||
                       nvl(p_vlmaxvendapf, 0) || ')' || chr(13) || chr(13) ||
                       'Dados do Cliente: ' || chr(13) || '  Vl. Pedidos: ' ||
                       nvl(vnvlrpedidosmes, 0) || chr(13) || '+ Vl. NFs:' ||
                       nvl(vnvlrnfmes, 0) || chr(13) || '- Vl. Devoluções:' ||
                       nvl(vnvlrdevmes, 0) || chr(13) ||
                       '+ Vl. Pedido Atual:' ||
                       ((nvl(p_vladicional, 0) * (p_percvenda / 100))) ||
                       chr(13) || '------------------------------------' ||
                       chr(13) || ' Total = ' ||
                       ((((nvl(vnvlrpedidosmes, 0) + nvl(vnvlrnfmes, 0)) -
                       nvl(vnvlrdevmes, 0)) +
                       (nvl(p_vladicional, 0) * (p_percvenda / 100))));
          vbresult  := FALSE;
        END IF;
      END IF; --if vnVLMAXVENDAPF > 0 then
      IF (nvl(p_perlimvendapf, 0) <> 0) AND (vsuf_filial = vsestent_cli) THEN
        vnvlrpedidosmes   := 0;
        vnvlrnfmes        := 0;
        vnvlrdevmes       := 0;
        vnvlrpedidosmespf := 0;
        vnvlrnfmespf      := 0;
        vnvlrdevmespf     := 0;
        BEGIN
          --Valor dos Pedidos ainda não faturados mas liberados
          SELECT SUM(nvl(pcpedc.vlatend, 0) *
                     (nvl(pcpedc.percvenda, 100) / 100)) vlatendpedidos
            INTO vnvlrpedidosmes
            FROM pcpedc
           WHERE pcpedc.data >=
                 to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                         'DD/MM/YYYY')
             AND pcpedc.codfilial = p_codfilial
             AND pcpedc.condvenda NOT IN (3, 6, 12)
             AND pcpedc.posicao IN ('L', 'M')
             AND pcpedc.dtcancel IS NULL;
        EXCEPTION
          WHEN OTHERS THEN
            vnvlrpedidosmes := 0;
        END;
        BEGIN
          --Valor da NFs do cliente no mês
          SELECT SUM(nvl(pcnfsaid.vltotal, 0)) vltotalnf
            INTO vnvlrnfmes
            FROM pcnfsaid
           WHERE pcnfsaid.dtsaida >=
                 to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                         'DD/MM/YYYY')
             AND pcnfsaid.codfilial = p_codfilial
             AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
             AND pcnfsaid.condvenda NOT IN (3, 6, 12)
             AND pcnfsaid.dtcancel IS NULL;
        EXCEPTION
          WHEN OTHERS THEN
            vnvlrnfmes := 0;
        END;
        BEGIN
          --Buscar valor das devoluções no mês
          SELECT SUM(nvl(pcnfent.vltotal, 0)) vltotaldev
            INTO vnvlrdevmes
            FROM pcnfsaid, pcestcom, pcnfent
           WHERE pcnfsaid.dtsaida >=
                 to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                         'DD/MM/YYYY')
             AND pcnfsaid.codfilial = p_codfilial
             AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
             AND pcnfsaid.dtcancel IS NULL
             AND pcnfent.tipodescarga IN ('6')
             AND pcnfsaid.numtransvenda = pcestcom.numtransvenda
             AND pcestcom.numtransent = pcnfent.numtransent;
        EXCEPTION
          WHEN OTHERS THEN
            vnvlrdevmes := 0;
        END;
        IF p_consideraisentoscomopf = 'S' THEN
          BEGIN
            --Verificar dados das pessoas físicas}
            --Valor dos Pedidos ainda não faturados mas liberados
            SELECT SUM(nvl(pcpedc.vlatend, 0) *
                       (nvl(pcpedc.percvenda, 100) / 100)) vlatendpedidos
              INTO vnvlrpedidosmespf
              FROM pcpedc, pcclient
             WHERE pcpedc.data >=
                   to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                           'DD/MM/YYYY')
               AND pcpedc.codfilial = p_codfilial
               AND pcpedc.condvenda NOT IN (3, 6, 12)
               AND pcpedc.posicao IN ('L', 'M')
               AND pcpedc.dtcancel IS NULL
               AND upper(pcclient.estent) = vsuf_filial
               AND ((pcclient.tipofj = 'F' AND pcclient.contribuinte = 'N') OR
                   (nvl(pcclient.consumidorfinal, 'N') = 'S') OR
                   (pcclient.ieent IS NULL) OR
                   (upper(pcclient.ieent) = 'ISENTO') OR
                   (upper(pcclient.ieent) = 'ISENTA'))
               AND pcpedc.codcli = pcclient.codcli
               AND NVL(PCCLIENT.VALIDAMAXVENDAPF, 'S') = 'S';
          EXCEPTION
            WHEN OTHERS THEN
              vnvlrpedidosmespf := 0;
          END;
        ELSE
          BEGIN
            --Verificar dados das pessoas físicas}
            --Valor dos Pedidos ainda não faturados mas liberados
            SELECT SUM(nvl(pcpedc.vlatend, 0) *
                       (nvl(pcpedc.percvenda, 100) / 100)) vlatendpedidos
              INTO vnvlrpedidosmespf
              FROM pcpedc, pcclient
             WHERE pcpedc.data >=
                   to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                           'DD/MM/YYYY')
               AND pcpedc.codfilial = p_codfilial
               AND pcpedc.condvenda NOT IN (3, 6, 12)
               AND pcpedc.posicao IN ('L', 'M')
               AND pcpedc.dtcancel IS NULL
               AND upper(pcclient.estent) = vsuf_filial
               AND ((pcclient.tipofj = 'F' AND pcclient.contribuinte = 'N') OR
                   (nvl(pcclient.consumidorfinal, 'N') = 'S'))
               AND pcpedc.codcli = pcclient.codcli
               AND NVL(PCCLIENT.VALIDAMAXVENDAPF, 'S') = 'S';
          EXCEPTION
            WHEN OTHERS THEN
              vnvlrpedidosmespf := 0;
          END;
        END IF;
        IF p_consideraisentoscomopf = 'S' THEN
          BEGIN
            --Valor da NFs do cliente no mês
            SELECT SUM(nvl(pcnfsaid.vltotal, 0)) vltotalnf
            --, SUM(NVL(PCNFSAID.VLTOTGER,0)) VLTOTGERNF
              INTO vnvlrnfmespf
              FROM pcnfsaid, pcclient
             WHERE pcnfsaid.dtsaida >=
                   to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                           'DD/MM/YYYY')
               AND pcnfsaid.codfilial = p_codfilial
               AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
               AND pcnfsaid.condvenda NOT IN (3, 6, 12)
               AND pcnfsaid.dtcancel IS NULL
               AND upper(pcclient.estent) = vsuf_filial
               AND ((pcclient.tipofj = 'F' AND pcclient.contribuinte = 'N') OR
                   (nvl(pcclient.consumidorfinal, 'N') = 'S') OR
                   (pcclient.ieent IS NULL) OR
                   (upper(pcclient.ieent) = 'ISENTO') OR
                   (upper(pcclient.ieent) = 'ISENTA'))
               AND pcnfsaid.codcli = pcclient.codcli
               AND NVL(PCCLIENT.VALIDAMAXVENDAPF, 'S') = 'S';
          EXCEPTION
            WHEN OTHERS THEN
              vnvlrnfmespf := 0;
          END;
        ELSE
          BEGIN
            --Valor da NFs do cliente no mês
            SELECT SUM(nvl(pcnfsaid.vltotal, 0)) vltotalnf
            --, SUM(NVL(PCNFSAID.VLTOTGER,0)) VLTOTGERNF
              INTO vnvlrnfmespf
              FROM pcnfsaid, pcclient
             WHERE pcnfsaid.dtsaida >=
                   to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                           'DD/MM/YYYY')
               AND pcnfsaid.codfilial = p_codfilial
               AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
               AND pcnfsaid.condvenda NOT IN (3, 6, 12)
               AND pcnfsaid.dtcancel IS NULL
               AND upper(pcclient.estent) = vsuf_filial
               AND ((pcclient.tipofj = 'F' AND pcclient.contribuinte = 'N') OR
                   (nvl(pcclient.consumidorfinal, 'N') = 'S'))
               AND pcnfsaid.codcli = pcclient.codcli
               AND NVL(PCCLIENT.VALIDAMAXVENDAPF, 'S') = 'S';
          EXCEPTION
            WHEN OTHERS THEN
              vnvlrnfmespf := 0;
          END;
        END IF;
        IF p_consideraisentoscomopf = 'S' THEN
          BEGIN
            --Buscar valor das devoluções no mês
            SELECT SUM(nvl(pcnfent.vltotal, 0)) vltotaldev
              INTO vnvlrdevmespf
              FROM pcnfsaid, pcestcom, pcnfent, pcclient
             WHERE pcnfsaid.dtsaida >=
                   to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                           'DD/MM/YYYY')
               AND pcnfsaid.codfilial = p_codfilial
               AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
               AND pcnfsaid.dtcancel IS NULL
               AND pcnfent.tipodescarga IN ('6')
               AND upper(pcclient.estent) = vsuf_filial
               AND ((pcclient.tipofj = 'F' AND pcclient.contribuinte = 'N') OR
                   (nvl(pcclient.consumidorfinal, 'N') = 'S') OR
                   (pcclient.ieent IS NULL) OR
                   (upper(pcclient.ieent) = 'ISENTO') OR
                   (upper(pcclient.ieent) = 'ISENTA'))
               AND pcnfsaid.codcli = pcclient.codcli
               AND pcnfsaid.numtransvenda = pcestcom.numtransvenda
               AND pcestcom.numtransent = pcnfent.numtransent
               AND NVL(PCCLIENT.VALIDAMAXVENDAPF, 'S') = 'S';
          EXCEPTION
            WHEN OTHERS THEN
              vnvlrdevmespf := 0;
          END;
        ELSE
          BEGIN
            --Buscar valor das devoluções no mês
            SELECT SUM(nvl(pcnfent.vltotal, 0)) vltotaldev
              INTO vnvlrdevmespf
              FROM pcnfsaid, pcestcom, pcnfent, pcclient
             WHERE pcnfsaid.dtsaida >=
                   to_date('01/' || to_char(trunc(SYSDATE), 'MM/YYYY'),
                           'DD/MM/YYYY')
               AND pcnfsaid.codfilial = p_codfilial
               AND pcnfsaid.codfiscal NOT IN (522, 622, 722, 532, 632, 732)
               AND pcnfsaid.dtcancel IS NULL
               AND pcnfent.tipodescarga IN ('6')
               AND upper(pcclient.estent) = vsuf_filial
               AND ((pcclient.tipofj = 'F' AND pcclient.contribuinte = 'N') OR
                   (nvl(pcclient.consumidorfinal, 'N') = 'S'))
               AND pcnfsaid.codcli = pcclient.codcli
               AND pcnfsaid.numtransvenda = pcestcom.numtransvenda
               AND pcestcom.numtransent = pcnfent.numtransent
               AND NVL(PCCLIENT.VALIDAMAXVENDAPF, 'S') = 'S';
          EXCEPTION
            WHEN OTHERS THEN
              vnvlrdevmespf := 0;
          END;
        END IF;
        IF ((nvl(vnvlrpedidosmes, 0) + nvl(vnvlrnfmes, 0)) -
           nvl(vnvlrdevmes, 0) +
           (nvl(p_vladicional, 0) * (p_percvenda / 100))) <> 0 THEN
          IF ((((nvl(vnvlrpedidosmespf, 0) + nvl(vnvlrnfmespf, 0)) -
             nvl(vnvlrdevmespf, 0) +
             (nvl(p_vladicional, 0) * (p_percvenda / 100))) /
             ((nvl(vnvlrpedidosmes, 0) + nvl(vnvlrnfmes, 0)) -
             nvl(vnvlrdevmes, 0) +
             (nvl(p_vladicional, 0) * (p_percvenda / 100)))) * 100) >
             nvl(p_perlimvendapf, 0) THEN
            vstempmsg := '%Venda Estadual para pessoa física supera o máximo mensal estipulado nos parâmetros do sistema!' ||
                         chr(13) || '(%Máx. Venda PF Estadual: ' ||
                         nvl(p_perlimvendapf, 0) || '% )' || chr(13) ||
                         chr(13) || 'Dados Totais Pessoas Físicas: ' ||
                         chr(13) || '  Vl. Pedidos: ' ||
                         nvl(vnvlrpedidosmespf, 0) || chr(13) ||
                         '+ Vl. NFs:' || nvl(vnvlrnfmespf, 0) || chr(13) ||
                         '- Vl. Devoluções:' || nvl(vnvlrdevmespf, 0) ||
                         chr(13) || '+ Vl. Pedido Atual:' ||
                         ((nvl(p_vladicional, 0) * (p_percvenda / 100))) ||
                         chr(13) || '------------------------------------' ||
                         chr(13) || '  Total = ' ||
                         ((((nvl(vnvlrpedidosmespf, 0) +
                         nvl(vnvlrnfmespf, 0)) - nvl(vnvlrdevmespf, 0)) +
                         (nvl(p_vladicional, 0) * (p_percvenda / 100)))) ||
                         chr(13) || chr(13) || 'Dados Gerais: ' || chr(13) ||
                         '  Vl. Pedidos: ' || nvl(vnvlrpedidosmes, 0) ||
                         chr(13) || '+ Vl. NFs:' || nvl(vnvlrnfmes, 0) ||
                         chr(13) || '- Vl. Devoluções:' ||
                         nvl(vnvlrdevmes, 0) || chr(13) ||
                         '+ Vl. Pedido Atual:' ||
                         ((nvl(p_vladicional, 0) * (p_percvenda / 100))) ||
                         chr(13) || '------------------------------------' ||
                         chr(13) || '  Total = ' ||
                         ((((nvl(vnvlrpedidosmes, 0) + nvl(vnvlrnfmes, 0)) -
                         nvl(vnvlrdevmes, 0) +
                         (nvl(p_vladicional, 0) * (p_percvenda / 100))))) ||
                         chr(13) || chr(13) ||
                         ' %Venda Estadual para pessoa física atual:' ||
                         (((((nvl(vnvlrpedidosmespf, 0) +
                         nvl(vnvlrnfmespf, 0)) - nvl(vnvlrdevmespf, 0) +
                         (nvl(p_vladicional, 0) * (p_percvenda / 100))) /
                         ((nvl(vnvlrpedidosmes, 0) + nvl(vnvlrnfmes, 0)) -
                         nvl(vnvlrdevmes, 0) +
                         (nvl(p_vladicional, 0) * (p_percvenda / 100)))) * 100));
            vbresult  := FALSE;
          END IF;
        END IF;
      END IF; --if vnPERLIMVENDAPF <> 0 then
    END IF; --if (vsVERIFICARLIMVENDAPF = 'S') then
    p_mensagem := vstempmsg;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := vstempmsg || '.' ||
                    'Erro ao verificar valor maximo venda pessoa fisica: ' ||
                    SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END verificarvalormaximovendapf;

PROCEDURE buscarprecocestabasica -- 13 parametros ( sendo 7 obrigatórios)
  (p_numped    NUMBER,
   p_codprod   NUMBER,
   p_numregiao NUMBER,
   p_numpr     NUMBER,
   p_ecesta    OUT BOOLEAN,
   p_preco     OUT NUMBER,
   p_mensagem  OUT VARCHAR2,
   p_utilizavendaporembalagem in varchar2 default 'N',
   p_utilizaprecoporembalagem in varchar2 default 'N',
   p_tipoprecificacao         in varchar2 default 'A',
   p_codfilial                in varchar2 default '1',
   p_qt                       in number   default 1,
   p_comimposto               in varchar2 default 'S',

   p_codfilialnf              in varchar2 default '',
   p_codcli                   in number default 0,
   p_codplpag                 in number default 0,
   p_condvenda                in number default 1,
   p_codcliprinc              IN NUMBER DEFAULT 0  ) IS

    vicont NUMBER;
    vnptabelatot pcpedi.ptabela%type;
    vnptabela    pcpedi.ptabela%type;
    vnPreco      pctabpr.pvenda1%type;
    vqtunit      pcembalagem.qtunit%type;
    vfator       pcembalagem.fatorpreco%type;

    vnprecosemimposto  pcpedi.ptabela%type;
    vnst        pcpedi.st%type;
    vnvlipi     pcpedi.vlipi%type;
    vnvlrfecp   pcpedi.vlfecp%type;
    vIEENT       pcclient.ieent%type;
    vbpessoafisica           boolean;
    vsAPLICAACRESCPJISENTA varchar2(1);
    vnperacrescismopf NUMBER;
    vnCodst           NUMBER;
    vnPercentualDescRamoAtividade PCATIVI.PERCDESC%TYPE;
  BEGIN
    p_ecesta := FALSE;
    p_preco  := 0;
    --Verificar se produto é Cesta Básica}
    SELECT COUNT(*) contador
      INTO vicont
      FROM pcformprod
     WHERE pcformprod.codprodacab = p_codprod;


    IF vicont <> 0 THEN
            --Buscar Preço de Venda da Cesta}
          for formprod in (SELECT PCFORMPROD.CodProdMP,
                                  PCFORMPROD.QTPRODMP,
                                  NVL(PCCONSUM.USATRIBUTACAOPORUF, 'N') USATRIBUTACAOPORUF,
                                  PCFORMPROD.CODAUXILIARMP,
                                  NVL((SELECT C.CODPRECOCESTA
                                         FROM PCPRECOCESTAC C
                                        WHERE C.CODPRODACAB = PCFORMPROD.CODPRODACAB
                                          AND C.DTEXCLUSAO IS NULL
                                          AND (C.NUMREGIAO = p_numregiao OR c.numregiao IS null)
                                          AND (C.CODFILIAL = p_codfilial OR c.codfilial IS NULL)
                                          AND (C.CODCLI = DECODE(C.UTILIZAPRECOFIXOREDE,
                                                                 'S',
                                                                 p_codcliprinc,
                                                                 p_codcli) OR c.codcli IS NULL)
                                          AND (C.CODPLPAG = p_codplpag OR C.CODPLPAG IS NULL)
                                          AND TRUNC(SYSDATE) BETWEEN C.DTINICIO AND C.DTFIM), 0) CODPRECOCESTA
                             FROM PCFORMPROD, PCCONSUM
                            WHERE PCFORMPROD.CodProdACAB = p_codprod) loop

            IF FORMPROD.CODPRECOCESTA > 0 THEN
              SELECT I.PRECOFIXO * FORMPROD.QTPRODMP
                INTO VNPRECO
                FROM PCPRECOCESTAI I
               WHERE I.CODPRECOCESTA = FORMPROD.CODPRECOCESTA
                 AND I.CODPRODMP = FORMPROD.CODPRODMP
                 AND I.CODPRODACAB = P_CODPROD;

              IF FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZAPERCFINPRECOPROM', '99', 'N') = 'S' THEN
                SELECT VNPRECO * (1+(PCPLPAG.PERTXFIM/100))
                  INTO VNPRECO
                  FROM PCPLPAG
                 WHERE PCPLPAG.CODPLPAG = p_codplpag;
              END IF;
            ELSE
              DECLARE

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
                  qtminimaatacado     PCEMBALAGEM.QTMINIMAATACADO%TYPE);
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
                     AND PCTABPR.CODPROD = FORMPROD.CODPRODMP
                     AND PCTABPR.NUMREGIAO = p_numregiao;
                EXCEPTION
                  WHEN OTHERS THEN
                    p_regprecos.PVENDAATAC1 := 0;
                    p_regprecos.PVENDAATAC2 := 0;
                    p_regprecos.PVENDAATAC3 := 0;
                    p_regprecos.PVENDAATAC4 := 0;
                    p_regprecos.PVENDAATAC5 := 0;
                    p_regprecos.PVENDAATAC6 := 0;
                    p_regprecos.PVENDAATAC7 := 0;
                    p_regprecos.PVENDA1     := 0;
                    p_regprecos.PVENDA2     := 0;
                    p_regprecos.PVENDA3     := 0;
                    p_regprecos.PVENDA4     := 0;
                    p_regprecos.PVENDA5     := 0;
                    p_regprecos.PVENDA6     := 0;
                    p_regprecos.PVENDA7     := 0;
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
                   (p_tipoprecificacao = 'A' AND
                   p_qt >= p_regprecos.qtminimaatacado) OR --HIS.00185.2015
                   (p_tipoprecificacao = 'V' AND
                   (p_qt < p_regprecos.qtminimaatacado OR
                   NVL(p_regprecos.qtminimaatacado, 0) = 0)))
                   AND p_comimposto = 'S' --HIS.00185.2015
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
                ELSIF ((p_tipoprecificacao = 'A' AND
                      p_qt < p_regprecos.qtminimaatacado) OR --HIS.00185.2015
                      (p_tipoprecificacao = 'V' AND
                      p_qt >= p_regprecos.qtminimaatacado)) --HIS.00185.2015
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
               ELSIF (p_comimposto <> 'S' )
                 THEN
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



              END;

            vnPreco := vnPreco *  nvl(formprod.qtprodmp, 0) ;
            END IF;

            if (p_codcli > 0) then
              SELECT pcclient.ieent, coalesce(pcativi.percdesc, 0)
                INTO vIEENT, vnPercentualDescRamoAtividade
                FROM pcclient , pcativi
               WHERE CODCLI = p_codcli
                 AND pcclient.codatv1 = pcativi.codativ(+);

                vbpessoafisica := (FERRAMENTAS.VERIFICAR_FJ(p_codcli) = 'PESSOA FISICA');

                vnCodst := (PKG_TRIBUTACAO.RETORNA_CODIGO_TRIBUTACAO(p_codcli,
                                                            formprod.CodProdMP,
                                                            p_codfilialnf,
                                                            p_numregiao));


                SELECT NVL(pctribut.aplicaacrescpjisenta,'N'), NVL(pctribut.peracrescismopf, 0)
                  INTO vsAPLICAACRESCPJISENTA, vnperacrescismopf
                FROM PCTRIBUT WHERE CODST = vnCodst;

                IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ACRESCIMOPFCOMIE',p_codfilial,'N') = 'S')
                THEN
                  IF ((vsAPLICAACRESCPJISENTA = 'S') AND ((vIEENT = 'ISENTA') OR (vIEENT = 'ISENTO'))) OR
                    (vbpessoafisica)
                  THEN

                    vnPreco := (vnPreco + (vnPreco * vnperacrescismopf / 100));

                  END IF;
                ELSE
                  IF ((vsAPLICAACRESCPJISENTA = 'S') AND ((vIEENT = 'ISENTA') OR (vIEENT = 'ISENTO'))) OR
                   (vbpessoafisica AND ((vIEENT = 'ISENTA') OR (vIEENT = 'ISENTO')))
                  THEN

                   vnPreco := (vnPreco + (vnPreco * vnperacrescismopf / 100));

                  END IF;
                END IF;
                IF vnPercentualDescRamoAtividade <> 0 THEN
                  vnPreco := vnPreco * (1+(vnPercentualDescRamoAtividade/100));
                END IF;

                SELECT VALORSEMIMPOSTO
                  INTO vnprecosemimposto
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(p_codfilial,
                                                                      p_codfilialnf,--p_regpedido.codfilialnf,
                                                                      '',--p_regitem.codfilialretira,
                                                                      p_codcli,--p_regcliente.codcli,
                                                                      p_codplpag, --p_regpedido.codplpag,
                                                                      formprod.codprodmp,
                                                                      formprod.CODAUXILIARMP,
                                                                      p_condvenda, --condvenda
                                                                      'N',
                                                                      1,
                                                                      0,
                                                                      vnPreco,
                                                                      'S',
                                                                      'S',
                                                                      'N',
                                                                      0,
                                                                      NULL,
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      0,
                                                                      'N',
                                                                      'I'));

                 SELECT VALORIPI
                  INTO vnvlipi
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(p_codfilial,
                                                       p_codfilialnf,--p_regpedido.codfilialnf,
                                                       '',--p_regitem.codfilialretira,
                                                       p_codcli, --p_regcliente.codcli,
                                                       formprod.codprodmp,
                                                       formprod.CODAUXILIARMP,
                                                       p_condvenda,--p_regpedido.condvenda,
                                                       'N',
                                                       vnprecosemimposto,
                                                       'N',
                                                        0,
                                                       'N',--transferencia
                                                       'N',--transferenciaVirtual
                                                       'N',
                                                       'F',
                                                       null,
                                                       'I'
                                                      ));

                SELECT ST, VLRFECP
                  INTO vnst, vnvlrfecp
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(p_codfilial,
                                                      p_codfilialnf, --p_regpedido.codfilialnf,
                                                      '', --p_regitem.codfilialretira,
                                                      p_codcli, --p_regcliente.codcli,
                                                      p_codplpag, --p_regpedido.codplpag,
                                                      formprod.codprodmp,
                                                      formprod.CODAUXILIARMP,
                                                      p_condvenda,--p_regpedido.condvenda,
                                                      'N',
                                                      vnprecosemimposto,
                                                      0,
                                                      'N',
                                                      0,
                                                      0,
                                                      0,
                                                      NULL,
                                                      'S',
                                                      'N',
                                                      'T',
                                                      'N',
                                                      0,
                                                      'N',
                                                      0
                                                      ));

                  vnPreco := vnprecosemimposto + vnvlipi + vnst + vnvlrfecp;
            end if;



            if p_utilizavendaporembalagem = 'S' then
              select DECODE(NVL(PCEMBALAGEM.QTUNIT, 0),
                            0,
                            1,
                            NVL(PCEMBALAGEM.QTUNIT, 0)) QTUNIT,
                     CASE NVL(PCEMBALAGEM.FATORPRECO, 1)
                       WHEN 0 THEN
                        1
                       ELSE
                        NVL(PCEMBALAGEM.FATORPRECO, 1)
                     END FATORPRECO
                into vqtunit, vfator
                from pcformprod, PCEMBALAGEM, PCPRODUT

               WHERE PCFORMPROD.CodProdACAB = p_codprod
                 AND PCFORMPROD.CodProdMP = formprod.CodProdMP
                 AND PCFORMPROD.CODPRODMP = PCPRODUT.CODPROD
                 AND PCFORMPROD.CODPRODMP = PCEMBALAGEM.CODPROD
                 AND PCEMBALAGEM.CODFILIAL = p_codfilial
                 AND PCEMBALAGEM.CODAUXILIAR = NVL(formprod.CODAUXILIARMP,PCPRODUT.CODAUXILIAR);

              p_preco := p_preco + vnPreco  * vqtunit * vfator;
            else
              p_preco := p_preco + vnPreco ;
            end if;

          end loop;
          p_ecesta := TRUE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar preco cesta basica: ' || SQLCODE || '-' ||
                    SQLERRM;
  END buscarprecocestabasica;

  FUNCTION calcularst -- 19 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,--10
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;
    vntempst        NUMBER;
    vstempmsg       VARCHAR2(1000);
    vnpercbaseredst NUMBER;
    vnbaseicst_temp NUMBER;

  BEGIN

    vbresult := calcularst(p_pvenda,
                           p_vlipi,
                           p_percvenda,
                           p_tipocalcst,
                           p_calcstpf,
                           p_mostrarpvendasemst,
                           p_consideraisentoscomopf,
                           p_calculast,
                           p_ieent,
                           p_tipofj,--10
                           p_pauta,
                           p_iva,
                           p_aliqicms1,
                           p_aliqicms2,
                           p_percbaseredst,
                           p_numcasasdecvenda,
                           p_tipocalculo,
                           -----------------------
                           --A chamada da "calcularst" com 19 params considera que
                           --sempre seja operação estadual e NÃO usa o valor da ult. entrada
                           'XX', --p_uffilial
                           'XX', --p_estent
                           'N',  --p_usavalorultentbasest
                           0,    --p_valorultent
                           -----------------------
                           vstempmsg,
                           vntempst,
                           -----------------------
                           vnbaseicst_temp
                           );

    p_percbaseredst := vnpercbaseredst;
    p_mensagem := vstempmsg;
    p_st := vntempst;

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST (19Params): ' || SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END calcularst;

  FUNCTION calcularst -- 24 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,--10
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,--20
   p_valorultent            IN NUMBER,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;
    vntempst        NUMBER;
    vstempmsg       VARCHAR2(1000);
    vnpercbaseredst NUMBER;
    vnbaseicst_temp NUMBER;

  BEGIN

    vbresult := calcularst(p_pvenda,
                           p_vlipi,
                           p_percvenda,
                           p_tipocalcst,
                           p_calcstpf,
                           p_mostrarpvendasemst,
                           p_consideraisentoscomopf,
                           p_calculast,
                           p_ieent,
                           p_tipofj,--10
                           p_pauta,
                           p_iva,
                           p_aliqicms1,
                           p_aliqicms2,
                           vnpercbaseredst,
                           p_numcasasdecvenda,
                           p_tipocalculo,
                           p_uffilial,
                           p_estent,
                           p_usavalorultentbasest,--20
                           p_valorultent,
                           ----------------------------
                           --O campo contribuinte é sempre tratado com NVL para "S".
                           'S', --p_contribuinte
                           ----------------------------
                           vstempmsg,
                           vntempst,
                           vnbaseicst_temp
                           );

    p_percbaseredst := vnpercbaseredst;
    p_mensagem := vstempmsg;
    p_st := vntempst;
    p_baseicst := vnbaseicst_temp;

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST (24Params): ' || SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END calcularst;

  FUNCTION calcularstfonte --26 parametros
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN NUMBER,
   p_aliqicms1fonte            IN NUMBER,
   p_aliqicms2fonte            IN NUMBER,
   p_percbasered               IN NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER IS

    vnivafonte       NUMBER;
    vnaliqicms1fonte NUMBER;
    vnaliqicms2fonte NUMBER;
    vnpercbasered    NUMBER;

    vnbcst           NUMBER;
    vnstfonte        NUMBER;

  BEGIN

    vnbcst    := 0;
    vnstfonte := 0;

    vnivafonte := p_ivafonte;
    vnaliqicms1fonte := p_aliqicms1fonte;
    vnaliqicms2fonte := p_aliqicms2fonte;
    vnpercbasered := p_percbasered;

    vnstfonte := calcularstfonte(p_codprod,
                                 p_condvenda,
                                 p_percvenda,
                                 p_iva,
                                 vnivafonte,
                                 vnaliqicms1fonte,
                                 vnaliqicms2fonte,
                                 vnpercbasered,
                                 p_percbaserednrpa,
                                 p_percbaseredconsumidor,
                                 p_utilizapercbaseredpf_trib,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_utilizapercbaseredpf,
                                 p_clientefontest,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_isentoicms,
                                 p_consumidorfinal,
                                 p_utilizaiesimplificada,
                                 p_tipoempresa,
                                 p_consideraisentoscomopf,
                                 p_pvenda,
                                 p_vlipi,
                                 --------------------------
                                 --Os parâmetros abaixo serão preenchidos com valores padrôes
                                 --NÃO ALTERAR!!!
                                 'XX', --p_uffilial
                                 'XX', --p_estent
                                 'N',  --p_usavalorultentbasest
                                 0,    --p_valorultent
                                 vnbcst,
                                 --------------------------
                                 p_mensagem
                                 );

    RETURN nvl(vnstfonte, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST Fonte (26Params): ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END calcularstfonte;

  FUNCTION buscapercomissao -- 18 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER IS

    vnpercom  NUMBER;

  BEGIN

    vnpercom := buscapercomissao(p_tipovend,
                                 p_pcomint1,
                                 p_pcomext1,
                                 p_pcomrep1,
                                 p_usacomissaoporcliente,
                                 p_percomcli,
                                 p_usacomissaoporrca,
                                 p_comissaorcatipovenda,
                                 p_tipovenda,
                                 p_percent,
                                 p_percent2,
                                 p_usacomissaoporlinhaprod,
                                 p_codplpag,
                                 p_codlinhaprod,
                                 p_perdesc,
                                 p_codusur,
                                 p_numregiao,
                                 ----------------------------
                                 --Os parâmetros abaixo assumirão o valor padrão 0(zero).
                                 0, --p_codsec,
                                 0, --p_codepto,
                                 0, --p_codprod,
                                 ----------------------------
                                 p_mensagem
                                );

    RETURN nvl(vnpercom, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  FUNCTION buscapercomissao -- 21 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_codsec                  IN pcprodut.codsec%TYPE,
   p_codepto                 IN pcprodut.codepto%TYPE,
   p_codprod                 IN pcprodut.codprod%TYPE,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER IS
    vnpercom NUMBER;
    vicont   NUMBER;
    vclasse  pcprodut.classevenda%TYPE;
  BEGIN


    vnpercom := buscapercomissao(p_tipovend,
                                 p_pcomint1,
                                 p_pcomext1,
                                 p_pcomrep1,
                                 p_usacomissaoporcliente,
                                 p_percomcli,
                                 p_usacomissaoporrca,
                                 p_comissaorcatipovenda,
                                 p_tipovenda,
                                 p_percent,
                                 p_percent2,
                                 p_usacomissaoporlinhaprod,
                                 p_codplpag,
                                 p_codlinhaprod,
                                 p_perdesc,
                                 p_codusur,
                                 p_numregiao,
                                 p_codsec,
                                 p_codepto,
                                 p_codprod,
                                 ----------------------------
                                 --O parâmetro abaixo assumirá o valor padrão 0(zero).
                                 0, --p_perluc,
                                 ----------------------------
                                 p_mensagem
                                );

    RETURN nvl(vnpercom, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  FUNCTION buscapercomissao -- 22 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_codsec                  IN pcprodut.codsec%TYPE,
   p_codepto                 IN pcprodut.codepto%TYPE,
   p_codprod                 IN pcprodut.codprod%TYPE,
   p_perluc                  IN NUMBER,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER IS

    vnpercom      NUMBER;
    vsletracomiss VARCHAR2(10);

  BEGIN

    vsletracomiss := NULL;

    vnpercom := buscapercomissao(p_tipovend,
                                 p_pcomint1,
                                 p_pcomext1,
                                 p_pcomrep1,
                                 p_usacomissaoporcliente,
                                 p_percomcli,
                                 p_usacomissaoporrca,
                                 p_comissaorcatipovenda,
                                 p_tipovenda,
                                 p_percent,
                                 p_percent2,
                                 p_usacomissaoporlinhaprod,
                                 p_codplpag,
                                 p_codlinhaprod,
                                 p_perdesc,
                                 p_codusur,
                                 p_numregiao,
                                 p_codsec,
                                 p_codepto,
                                 p_codprod,
                                 p_perluc,
                                 ----------------------------
                                 --O parâmetro abaixo assumirá o valor padrão 0(zero).
                                 vsletracomiss, --p_letracomiss
                                 ----------------------------
                                 p_mensagem
                                );

    RETURN nvl(vnpercom, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  FUNCTION buscapercomissao -- 23 parametros
  (p_tipovend                IN VARCHAR2,
   p_pcomint1                IN NUMBER,
   p_pcomext1                IN NUMBER,
   p_pcomrep1                IN NUMBER,
   p_usacomissaoporcliente   IN VARCHAR2,
   p_percomcli               IN NUMBER,
   p_usacomissaoporrca       IN VARCHAR2,
   p_comissaorcatipovenda    IN VARCHAR2,
   p_tipovenda               IN VARCHAR2,
   p_percent                 IN NUMBER,
   p_percent2                IN NUMBER,
   p_usacomissaoporlinhaprod IN VARCHAR2,
   p_codplpag                IN NUMBER,
   p_codlinhaprod            IN NUMBER,
   p_perdesc                 IN NUMBER,
   p_codusur                 IN NUMBER,
   p_numregiao               IN NUMBER,
   p_codsec                  IN pcprodut.codsec%TYPE,
   p_codepto                 IN pcprodut.codepto%TYPE,
   p_codprod                 IN pcprodut.codprod%TYPE,
   p_perluc                  IN NUMBER,
   p_letracomiss             OUT VARCHAR2,
   p_mensagem                OUT VARCHAR2) RETURN NUMBER IS

    vnpercom      NUMBER;
    vsletracomiss VARCHAR2(2);

  BEGIN

    vnpercom := buscapercomissao(p_tipovend,
                                 p_pcomint1,
                                 p_pcomext1,
                                 p_pcomrep1,
                                 p_usacomissaoporcliente,
                                 p_percomcli,
                                 p_usacomissaoporrca,
                                 p_comissaorcatipovenda,
                                 p_tipovenda,
                                 p_percent,
                                 p_percent2,
                                 p_usacomissaoporlinhaprod,
                                 p_codplpag,
                                 p_codlinhaprod,
                                 p_perdesc,
                                 p_codusur,
                                 p_numregiao,
                                 p_codsec,
                                 p_codepto,
                                 p_codprod,
                                 p_perluc,
                                 ----------------------------
                                 --O parâmetro abaixo assumirá o valor padrão 1.
                                 1, --p_ordemavaliacaocomissaorca
                                 ----------------------------
                                 vsletracomiss,
                                 p_mensagem
                                );

    p_letracomiss := vsletracomiss;

    RETURN nvl(vnpercom, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  FUNCTION buscapercomissao -- 24 parametros
  (p_tipovend                  IN VARCHAR2,
   p_pcomint1                  IN NUMBER,
   p_pcomext1                  IN NUMBER,
   p_pcomrep1                  IN NUMBER,
   p_usacomissaoporcliente     IN VARCHAR2,
   p_percomcli                 IN NUMBER,
   p_usacomissaoporrca         IN VARCHAR2,
   p_comissaorcatipovenda      IN VARCHAR2,
   p_tipovenda                 IN VARCHAR2,
   p_percent                   IN NUMBER,
   p_percent2                  IN NUMBER,
   p_usacomissaoporlinhaprod   IN VARCHAR2,
   p_codplpag                  IN NUMBER,
   p_codlinhaprod              IN NUMBER,
   p_perdesc                   IN NUMBER,
   p_codusur                   IN NUMBER,
   p_numregiao                 IN NUMBER,
   p_codsec                    IN pcprodut.codsec%TYPE,
   p_codepto                   IN pcprodut.codepto%TYPE,
   p_codprod                   IN pcprodut.codprod%TYPE,
   p_perluc                    IN NUMBER,
   p_ordemavaliacaocomissaorca IN NUMBER,
   p_letracomiss               OUT VARCHAR2,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER IS
    vnpercom      NUMBER;
    vsletracomiss VARCHAR2(2);
  BEGIN

    vnpercom := buscapercomissao(p_tipovend,
                                 p_pcomint1,
                                 p_pcomext1,
                                 p_pcomrep1,
                                 p_usacomissaoporcliente,
                                 p_percomcli,
                                 p_usacomissaoporrca,
                                 p_comissaorcatipovenda,
                                 p_tipovenda,
                                 p_percent,
                                 p_percent2,
                                 p_usacomissaoporlinhaprod,
                                 p_codplpag,
                                 p_codlinhaprod,
                                 p_perdesc,
                                 p_codusur,
                                 p_numregiao,
                                 p_codsec,
                                 p_codepto,
                                 p_codprod,
                                 p_perluc,
                                 p_ordemavaliacaocomissaorca,
                                 ----------------------------
                                 --Os parâmetros abaixo assumirão o valor padrão NULO e data atual.
                                 NULL, --p_codfilial,
                                 TRUNC(SYSDATE), --p_data,
                                 ----------------------------
                                 vsletracomiss,
                                 p_mensagem
                                );

    p_letracomiss := vsletracomiss;

    RETURN nvl(vnpercom, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  PROCEDURE calcularcmv -- 33 parametros
  (p_abaterimpostoscomissaorca IN VARCHAR2,
   p_aplicarindicecmv          IN VARCHAR2,
   p_txvenda                   IN NUMBER,
   p_tipofj                    IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_freteespecial             IN VARCHAR2,
   p_perfreteterceiros         IN NUMBER,
   p_perfreteespecial          IN NUMBER,
   p_custofin                  IN NUMBER,
   p_custoreal                 IN NUMBER,
   p_perdesccusto              IN NUMBER,
   p_codicmtab                 IN NUMBER,
   p_codicmtabpf_enulo         IN BOOLEAN,
   p_codicmtabpf               IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_pvenda                    IN NUMBER,
   p_percom                    IN NUMBER,
   p_st                        IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_vliss                     IN NUMBER,
   p_contribuinte              IN VARCHAR2,
   p_perfretecmv               OUT NUMBER,
   p_custofinest               OUT NUMBER,
   p_txvenda_item              OUT NUMBER,
   p_perdesccusto_item         OUT NUMBER,
   p_codicmtab_item            OUT NUMBER,
   p_vlcustoreal               OUT NUMBER,
   p_vlcustofin                OUT NUMBER,
   p_vldesccustocmv            OUT NUMBER,
   p_aplicaredTribut           IN BOOLEAN DEFAULT FALSE,
   p_bonific                   IN BOOLEAN DEFAULT FALSE,
   p_codst                     IN NUMBER DEFAULT 0) IS
    vnbasecalccomissao NUMBER := 0;
  BEGIN

    calcularcmv(p_abaterimpostoscomissaorca,
                p_aplicarindicecmv,
                -------------------------------------
                --O parâmetro abaixo usa como default 'S'(tratamento com NVL)
                'S', --p_incluircomissaosugpvendacmv,
                -------------------------------------
                p_txvenda,
                p_tipofj,
                p_utilizaiesimplificada,
                p_ieent,
                p_freteespecial,
                p_perfreteterceiros,
                p_perfreteespecial,
                p_custofin,
                p_custoreal,
                p_perdesccusto,
                p_codicmtab,
                p_codicmtabpf_enulo,
                p_codicmtabpf,
                p_percvenda,
                p_pvenda,
                p_percom,
                p_st,
                p_vlipi,
                p_vliss,
                p_contribuinte,
                p_perfretecmv,
                p_custofinest,
                p_txvenda_item,
                p_perdesccusto_item,
                p_codicmtab_item,
                p_vlcustoreal,
                p_vlcustofin,
                p_vldesccustocmv);

  END calcularcmv;

  FUNCTION validarrestricaovenda -- 9 parametros
  (p_codprod       IN NUMBER,
   p_numregiao     IN NUMBER,
   p_codcli        IN NUMBER,
   p_codusur       IN NUMBER,
   p_codfornec     IN NUMBER,
   p_codpraca      IN NUMBER,
   p_classeproduto IN pcprodut.classe%TYPE,
   p_codativ       IN pcclient.codatv1%TYPE,
   p_mensagem      OUT VARCHAR2) RETURN BOOLEAN IS

    vbresult       BOOLEAN;

  BEGIN

    vbresult := validarrestricaovenda(p_codprod,
                                      p_numregiao,
                                      p_codcli,
                                      p_codusur,
                                      p_codfornec,
                                      p_codpraca,
                                      p_classeproduto,
                                      p_codativ,
                                      0, --p_codsupervisor,
                                      p_mensagem,
                                      NULL, --p_codfilial,
                                      NULL, --p_condvenda,
                                      NULL, --p_fretedespacho,
                                      NULL, --p_origemped,
                                      NULL, --p_codauxiliar,
                                      NULL, --p_codplpag,
                                      NULL, --p_codcob,
                                      NULL, --p_codmarca,
                                      NULL --p_vlatend
                                     );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Restricao de Venda: ' || SQLERRM;
      RETURN FALSE;

  END validarrestricaovenda;

  FUNCTION validarrestricaovenda -- 19 parametros (pode ser usada para chamada com 10 parâmetros)
  (p_codprod       IN NUMBER,
   p_numregiao     IN NUMBER,
   p_codcli        IN NUMBER,
   p_codusur       IN NUMBER,
   p_codfornec     IN NUMBER,
   p_codpraca      IN NUMBER,
   p_classeproduto IN pcprodut.classe%TYPE,
   p_codativ       IN pcclient.codatv1%TYPE,
   p_codsupervisor in number,
   p_mensagem      OUT VARCHAR2,
   p_codfilial     in  varchar2 default '0',
   p_condvenda     in  number  default 0,
   p_fretedespacho in  varchar2 default ' ',
   p_origemped     in  varchar2 default ' ',
   p_codauxiliar   in  number default null,
   p_codplpag      in  number default 0,
   p_codcob        in  varchar2 default ' ',
   p_codmarca      in  number default 0,
   p_vlatend       in  number default 0) RETURN BOOLEAN IS

    vbresult       BOOLEAN;
    vicont         NUMBER;
    vncodrestricao pcrestricaovenda.codrestricao%TYPE;
    vstipofj       pcclient.tipofj%type;
    vncodepto      pcprodut.codepto%type;
    vncodsec       pcprodut.codsec%type;
    vsMotivoRestricao  pcrestricaovenda.motivo%type;
  BEGIN
    vbresult       := TRUE;
    vncodrestricao := NULL;

    select tipofj into vstipofj from pcclient where codcli = p_codcli;

    select codsec, codepto
      into vncodsec, vncodepto
      from pcprodut
     where codprod = p_codprod;

    SELECT COUNT(*)
      INTO vicont
      FROM pcrestricaovenda
     WHERE ((codcli = p_codcli) OR (codcli IS NULL))
       AND ((codprod = p_codprod) OR (codprod IS NULL))
       AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
       AND ((codfornec = p_codfornec) OR (codfornec IS NULL))
       AND ((codpraca = p_codpraca) OR (codpraca IS NULL))
       AND ((codusur = p_codusur) OR (codusur IS NULL))
       AND ((codativ = p_codativ) OR (codativ IS NULL))
       AND ((classeproduto = p_classeproduto) OR (classeproduto IS NULL))
       AND ((codepto = vncodepto) OR (codepto IS NULL))
       AND ((codsec = vncodsec) OR (codsec IS NULL))
       AND ((codsupervisor = p_codsupervisor) OR (codsupervisor IS NULL))
       AND ((tipofj = vstipofj) OR (tipofj IS NULL))
       AND ((codfilial = p_codfilial ) OR (codfilial IS NULL))
       and ((condvenda = p_condvenda ) OR (condvenda is null))
       and ((fretedespacho = p_fretedespacho) OR (fretedespacho is null) OR (fretedespacho = 'T'))
       and ((origemped   = p_origemped ) OR (origemped is null ) OR (origemped = 'O'))
       and ((codauxiliar = p_codauxiliar) OR (codauxiliar is null))
       and ((codcob = p_codcob) OR (codcob is null))
       and ((codplpag = p_codplpag ) OR (codplpag is null))
       AND ((codmarca = p_codmarca) OR (codmarca IS NULL))
       AND ((valorminimovenda > p_vlatend) OR (nvl(valorminimovenda,0) = 0));
    IF vicont = 0 THEN
      vbresult := TRUE;
    ELSE
      SELECT pcrestricaovenda.codrestricao, pcrestricaovenda.motivo
        INTO vncodrestricao, vsMotivoRestricao
        FROM pcrestricaovenda
       WHERE ((codcli = p_codcli) OR (codcli IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
         AND ((codfornec = p_codfornec) OR (codfornec IS NULL))
         AND ((codpraca = p_codpraca) OR (codpraca IS NULL))
         AND ((codusur = p_codusur) OR (codusur IS NULL))
         AND ((codativ = p_codativ) OR (codativ IS NULL))
         AND ((classeproduto = p_classeproduto) OR (classeproduto IS NULL))
         AND ((codepto = vncodepto) OR (codepto IS NULL))
         AND ((codsec = vncodsec) OR (codsec IS NULL))
         AND ((codsupervisor = p_codsupervisor) OR (codsupervisor IS NULL))
         AND ((tipofj = vstipofj) OR (tipofj IS NULL))
         AND ((codfilial = p_codfilial ) OR (codfilial IS NULL))
         and ((condvenda = p_condvenda ) OR (condvenda is null))
         and ((fretedespacho = p_fretedespacho) OR (fretedespacho is null) OR (fretedespacho = 'T'))
         and ((origemped   = p_origemped ) OR (origemped is null ) OR (origemped = 'O'))
         and ((codauxiliar = p_codauxiliar) OR (codauxiliar is null))
         and ((codcob = p_codcob) OR (codcob is null))
         and ((codplpag = p_codplpag ) OR (codplpag is null))
         AND ((codmarca = p_codmarca) OR (codmarca IS NULL))
         AND ((valorminimovenda > p_vlatend) OR (nvl(valorminimovenda,0) = 0))
         AND rownum = 1;
      vbresult   := FALSE;
      p_mensagem := 'Restricao para esta venda : ' || vncodrestricao;

      if vsMotivoRestricao is not null then
         p_mensagem := p_mensagem || ' - ' ||  vsMotivoRestricao;
      END IF;
    END IF;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Restricao de Venda: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END validarrestricaovenda;

  FUNCTION validarrestricaodeptosecforn -- 5 parametros
  (p_codsec    IN NUMBER,
   p_codepto   IN NUMBER,
   p_codusur   IN NUMBER,
   p_codfornec IN NUMBER,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN IS
    vbresult                    BOOLEAN;
    v_contusurrest              NUMBER;
    v_contusurdepsec            NUMBER;
    v_contusurfornec            NUMBER;
    v_cont                      NUMBER;
    utilizapcusurfornec         pcconsum.utilizapcusurfornec%TYPE;
    validarestricoesvendaporrca pcconsum.validarestricoesvendaporrca%TYPE;
    vsvisualizarproddeptosec     pcusuari.visualizarproddeptosec%type;

  BEGIN

    select nvl(pcusuari.visualizarproddeptosec,'N')
    into vsvisualizarproddeptosec
    from pcusuari
    where codusur = p_codusur;

    -- Depto/Seção
    vbresult := TRUE;

  if vsvisualizarproddeptosec = 'S' then

    SELECT COUNT(*) qt
      INTO v_contusurrest
      FROM pcusurdepsec
     WHERE codusur = p_codusur;

    IF v_contusurrest > 0 THEN

          SELECT COUNT(*) qt
            INTO v_contusurdepsec
            FROM pcusurdepsec
           WHERE codusur = p_codusur
             AND codepto = p_codepto
             AND codsec = p_codsec;

          IF v_contusurdepsec = 0 THEN
            vbresult   := FALSE;
            p_mensagem := 'Departamento/Seção não Autorizado';
          END IF;
       end if;
    END IF;

    --Fornecedor
    SELECT nvl(pcconsum.utilizapcusurfornec, 'N'),
           nvl(pcconsum.validarestricoesvendaporrca, 'N')
      INTO utilizapcusurfornec, validarestricoesvendaporrca
      FROM pcconsum;
    IF utilizapcusurfornec = 'S' THEN
      SELECT COUNT(*) INTO v_contusurfornec FROM pcusurfornec;
      IF v_contusurfornec > 0 THEN
        IF validarestricoesvendaporrca = 'S' THEN
          SELECT COUNT(*)
            INTO v_contusurfornec
            FROM pcusurfornec
           WHERE codusur = p_codusur;
          IF v_contusurfornec > 0 THEN
            SELECT COUNT(*) qt
              INTO v_cont
              FROM pcusurfornec
             WHERE pcusurfornec.codfornec = p_codfornec
               AND pcusurfornec.codusur = p_codusur;
            IF v_cont = 0 THEN
              vbresult   := FALSE;
              p_mensagem := 'Fornecedor não Autorizado';
            END IF;
          END IF;
        ELSE
          SELECT COUNT(*) qt
            INTO v_cont
            FROM pcusurfornec
           WHERE pcusurfornec.codfornec = p_codfornec
             AND pcusurfornec.codusur = p_codusur;
          IF v_cont = 0 THEN
            vbresult   := FALSE;
            p_mensagem := 'Fornecedor não Autorizado';
          END IF;
        END IF;
      END IF;
    END IF;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Restricao de Venda Depto/Seção e Fornecedor ' || SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END validarrestricaodeptosecforn;

  FUNCTION calcularimpostos --36 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN
    vbresult := FALSE;

    vbresult := calcularimpostos(p_pvenda,
                                 p_ptabela,
                                 p_pbaserca,
                                 p_vlipi,
                                 p_percipi,
                                 p_percipivenda,
                                 p_percvenda,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_mostrarpvendasemst,
                                 p_consideraisentoscomopf,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_pauta,
                                 p_iva,
                                 p_aliqicms1,
                                 p_aliqicms2,
                                 p_percbaseredst,
                                 p_numcasasdecvenda,
                                 p_tipocalculo,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 --------------------------------
                                 --NÃO ALTERAR O PADRÃO ABAIXO!
                                 'N', --p_usavalorultentbasest2,
                                 --------------------------------
                                 p_valorultent,
                                 p_isentoipi,
                                 p_suframa,
                                 p_calcularstcomipi,
                                 p_tipocalcipi,
                                 p_filialnf,
                                 p_condvenda,
                                 p_contribuinte,
                                 p_uffilialnf,
                                 p_mensagem,
                                 p_st,
                                 p_baseicst
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularimpostos;

  -- Sabrina em 24/07/2008: tratar pctribut.usavalorultentbasest2
  FUNCTION calcularimpostos --37 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN
    vbresult := FALSE;

    vbresult := calcularimpostos(p_pvenda,
                                 p_ptabela,
                                 p_pbaserca,
                                 p_vlipi,
                                 p_percipi,
                                 p_percipivenda,
                                 p_percvenda,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_mostrarpvendasemst,
                                 p_consideraisentoscomopf,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_pauta,
                                 p_iva,
                                 p_aliqicms1,
                                 p_aliqicms2,
                                 p_percbaseredst,
                                 p_numcasasdecvenda,
                                 p_tipocalculo,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 p_usavalorultentbasest2,
                                 p_valorultent,
                                 p_isentoipi,
                                 p_suframa,
                                 p_calcularstcomipi,
                                 p_tipocalcipi,
                                 p_filialnf,
                                 p_condvenda,
                                 p_contribuinte,
                                 p_uffilialnf,
                                 --------------------------------
                                 --NÃO ALTERAR O PADRÃO ABAIXO!
                                 'N', --p_importado,
                                 --------------------------------
                                 p_mensagem,
                                 p_st,
                                 p_baseicst
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularimpostos;

  FUNCTION buscarparametros -- 2 parametros
  (p_regparametros IN OUT t_parametros, p_mensagem OUT VARCHAR2)
    RETURN BOOLEAN IS
  BEGIN
    SELECT nvl(pcconsum.utilizapercbaseredpf, 'N') utilizapercbaseredpf,
           nvl(pcconsum.tipocalcst, 'T2') tipocalcst,
           nvl(pcconsum.calcstpf, 'S') calcstpf,
           nvl(pcconsum.mostrarpvendasemst, 'N') mostrarpvendasemst,
           nvl(pcconsum.consideraisentoscomopf, 'S') consideraisentoscomopf,
           nvl(pcconsum.numcasasdecvenda, 2) numcasasdecvenda,
           nvl(pcconsum.calcularstcomipi, 'N') calcularstcomipi,
           nvl(pcconsum.tipocalcipi, 'T2') tipocalcipi,
           nvl(pcconsum.tipocalcsulframa, 'T2') tipocalcsulframa,
           nvl(pcconsum.usartributacaotransftv10, 'N') usartributacaotransftv10
      INTO p_regparametros
      FROM pcconsum;
    p_mensagem := '';
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar parametros. Erro: ' || SQLCODE || ' - ' ||
                    SQLERRM;
      RETURN FALSE;
  END buscarparametros;

  FUNCTION buscarfilial -- parametros
  (p_codfilial IN NUMBER,
   p_regfilial IN OUT t_filial,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    SELECT pcfilial.codigo, pcfilial.uf
      INTO p_regfilial
      FROM pcfilial
     WHERE codigo = p_codfilial;
    p_mensagem := '';
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar filial. Erro: ' || SQLCODE || ' - ' ||
                    SQLERRM;
      RETURN FALSE;
  END;

  FUNCTION buscartributacao -- 3 parametros
  (p_codst         IN NUMBER,
   p_regtributacao IN OUT t_tributacao,
   p_mensagem      OUT VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    SELECT pctribut.codst,
           -- Parametros
           nvl(pctribut.tipocalculognre, 'P') tipocalculognre,
           nvl(pctribut.utilizapercbaseredpf, 'N') utilizapercbaseredpf,
           nvl(pctribut.usavalorultentbasest, 'N') usavalorultentbasest,
           -- ST
           nvl(pctribut.iva, 0) iva,
           nvl(pctribut.pauta, 0) pauta,
           nvl(pctribut.aliqicms1, 0) aliqicms1,
           nvl(pctribut.aliqicms2, 0) aliqicms2,
           nvl(pctribut.percbaseredst, 0) percbaseredst,
           -- ST Fonte
           nvl(pctribut.ivafonte, 0) ivafonte,
           nvl(pctribut.aliqicms1fonte, 0) aliqicms1fonte,
           nvl(pctribut.aliqicms2fonte, 0) aliqicms2fonte,
           nvl(pctribut.percbaseredstfonte, 0) percbaseredstfonte,
           nvl(pctribut.perbaserednrpa, 0) perbaserednrpa,
           nvl(pctribut.percbaseredconsumidor, 0) percbaseredconsumidor,
           -- ST Transferência
           nvl(pctribut.ivatransf, 0) ivatransf,
           nvl(pctribut.pautatransf, 0) pautatransf,
           nvl(pctribut.aliqicms1transf, 0) aliqicms1transf,
           nvl(pctribut.aliqicms2transf, 0) aliqicms2transf,
           nvl(pctribut.percbaseredsttransf, 0) percbaseredsttransf,
           --Suframa
           nvl(pctribut.perdescsuframa, 0) perdescsuframa,
           -- Isencao de ICMS
           nvl(pctribut.perdescicmisencao, 0) perdescicmisencao,
           -- ISS
           nvl(pctribut.aliqiss, 0) aliqiss
      INTO p_regtributacao
      FROM pctribut
     WHERE codst = p_codst;
    p_mensagem := '';
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar tributacao. Erro: ' || SQLCODE || ' - ' ||
                    SQLERRM;
      RETURN FALSE;
  END buscartributacao;

  FUNCTION buscarcliente -- 3 parametros
  (p_codcli     IN pcclient.codcli%type,
   p_regcliente IN OUT t_cliente,
   p_mensagem   OUT VARCHAR2) RETURN BOOLEAN IS
  BEGIN

    SELECT pcclient.codcli,
           pcclient.tipofj,
           nvl(pcclient.isentoipi, 'N') isentoipi,
           pcclient.estent,
           pcclient.ieent,
           pcclient.sulframa,
           nvl(pcclient.calculast, 'S') calculast,
           nvl(pcclient.contribuinte, 'N') contribuinte,
           nvl(pcclient.clientefontest, 'N') clientefontest,
           nvl(pcclient.isentoicms, 'N') isentoicms,
           pcclient.consumidorfinal,
           nvl(pcclient.utilizaiesimplificada, 'N') utilizaiesimplificada,
           nvl(pcclient.tipoempresa, ' ') tipoempresa,
           nvl(pcclient.tipodescisencao, 'N') tipodescisencao,
           nvl(pcclient.perdescisentoicms, 0) perdescisentoicms,
           nvl(pcclient.usaivafontediferenciado, 'N') usaivafontediferenciado,
           nvl(pcclient.ivafonte, 0) ivafonte
      into p_regcliente
      FROM pcclient
     WHERE codcli = p_codcli;

    p_mensagem := '';
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar cliente. Erro: ' || SQLCODE || ' - ' ||
                    SQLERRM;
      RETURN FALSE;
  END;

  FUNCTION buscarproduto -- 3 parametros
  (p_codprod    IN NUMBER,
   p_regproduto IN OUT t_produto,
   p_mensagem   OUT VARCHAR2) RETURN BOOLEAN IS
  BEGIN

    SELECT pcprodut.codprod,
           nvl(pcprodut.tipomerc, ' ') tipomerc,
           nvl(pcprodut.percipivenda, 0) percipivenda
      into p_regproduto
      FROM pcprodut
     WHERE codprod = p_codprod;

    p_mensagem := '';
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar produto. Erro: ' || SQLCODE || ' - ' ||
                    SQLERRM;
      RETURN FALSE;
  END;

  -- Sabrina em 27/01/2008
  FUNCTION calculartodosimpostos -- 27 parametros
  (p_codfilial   IN pcpedc.codfilial%TYPE,
   p_codfilialnf IN pcpedc.codfilialnf%TYPE,
   p_codcli      IN pcpedc.codcli%TYPE,
   p_condvenda   IN pcpedc.condvenda%TYPE,
   p_percvenda   IN pcpedc.percvenda%TYPE,
   p_codprod     IN pcpedi.codprod%TYPE,
   p_codst       IN pcpedi.codst%TYPE,
   -- Precos
   p_pvenda   IN OUT pcpedi.pvenda%TYPE,
   p_ptabela  IN OUT pcpedi.ptabela%TYPE,
   p_pbaserca IN OUT pcpedi.pbaserca%TYPE,
   -- ST/ST Fonte
   p_baseicst           IN OUT pcpedi.baseicst%TYPE,
   p_st                 IN OUT pcpedi.st%TYPE,
   p_iva                IN OUT pcpedi.iva%TYPE,
   p_pauta              IN OUT pcpedi.pauta%TYPE,
   p_aliqicms1          IN OUT pcpedi.aliqicms1%TYPE,
   p_aliqicms2          IN OUT pcpedi.aliqicms2%TYPE,
   p_percbaseredst      IN OUT pcpedi.percbaseredst%TYPE,
   p_percbaseredstfonte IN OUT pcpedi.percbaseredstfonte%TYPE,
   -- IPI
   p_vlipi   IN OUT pcpedi.vlipi%TYPE,
   p_percipi IN OUT pcpedi.percipi%TYPE,
   -- ST Cliente GNRE
   p_stclientegnre IN OUT pcpedi.stclientegnre%TYPE,
   -- Suframa
   p_vldescsuframa IN OUT pcpedi.vldescsuframa%TYPE,
   -- Isencao de ICMS
   p_perdescisentoicms IN OUT pcpedi.perdescisentoicms%TYPE,
   p_vldescicmisencao  IN OUT pcpedi.vldescicmisencao%TYPE,
   -- ISS
   p_perciss  IN OUT pcpedi.perciss%TYPE,
   p_vliss    IN OUT pcpedi.vliss%TYPE,
   p_mensagem OUT VARCHAR2) RETURN BOOLEAN IS
    regparametros      t_parametros;
    regfilial          t_filial;
    regfilialnf        t_filial;
    regtributacao      t_tributacao;
    regcliente         t_cliente;
    regproduto         t_produto;
    vbresult           BOOLEAN;
    vsmensagem         VARCHAR2(1000);
    vsmensagem_st      VARCHAR2(1000);
    vsmensagem_stfonte VARCHAR2(1000);
    exc_dados EXCEPTION;

    vnst        pcpedi.st%type;
    vsisentoipi pcclient.isentoipi%type;

  BEGIN
    vbresult := TRUE;
    -- Buscar dados

    -- Buscar parametros do sistema
    IF NOT buscarparametros(regparametros, vsmensagem) THEN
      RAISE exc_dados;
    END IF;

    -- Buscar filial
    IF NOT buscarfilial(p_codfilial, regfilial, vsmensagem) THEN
      RAISE exc_dados;
    END IF;
    -- Buscar filial nf
    IF NOT buscarfilial(p_codfilialnf, regfilialnf, vsmensagem) THEN
      RAISE exc_dados;
    END IF;

    -- Buscar tributacao
    IF NOT buscartributacao(p_codst, regtributacao, vsmensagem) THEN
      RAISE exc_dados;
    END IF;

    -- Buscar dados cliente
    IF NOT buscarcliente(p_codcli, regcliente, vsmensagem) THEN
      RAISE exc_dados;
    END IF;

    -- Buscar dados produto
    IF NOT buscarproduto(p_codprod, regproduto, vsmensagem) THEN
      RAISE exc_dados;
    END IF;

    vnst := 0;
    -----------------------------------------------------------------------
    --Cálculo do Vl. IPI

    vsisentoipi := regcliente.isentoipi;

    IF regcliente.sulframa IS NOT NULL OR regcliente.tipofj = 'E' THEN
      vsisentoipi := 'S';
    END IF;
    IF regcliente.estent = 'EX' THEN
      vsisentoipi := 'S';
    END IF;

    vnst      := 0; --Variável tem que ser zerada para o cálculo abaixo
    p_percipi := 0;
    p_vlipi   := 0;

    /*    IF nvl(p_calcularstcomipi,
             'N') = 'N'
      THEN
        IF (nvl(p_percipivenda,
                0) <> 0)
           AND (vsisentoipi = 'N')
           AND (p_condvenda NOT IN (3, 6, 7, 12))
        --Não se calcula IPI na venda 7
        THEN
          vsuffilial := p_uffilial;
          IF p_filialnf IS NOT NULL
          THEN
            vsuffilial := p_uffilialnf;
          END IF;
          IF NOT calcularst(p_pvenda,
                            0,
                            p_percvenda,
                            p_tipocalcst,
                            p_calcstpf,
                            p_mostrarpvendasemst,
                            p_consideraisentoscomopf,
                            p_calculast,
                            p_ieent,
                            p_tipofj,
                            p_pauta,
                            p_iva,
                            p_aliqicms1,
                            p_aliqicms2,
                            p_percbaseredst,
                            p_numcasasdecvenda,
                            0,
                            vsuffilial,
                            p_estent,
                            p_usavalorultentbasest,
                            p_valorultent,
                            p_contribuinte,
                            vsmensagem_st,
                            vnst,
                            p_baseicst)
          THEN
            vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                          vsmensagem_st;
          END IF;
          p_percipi := p_percipivenda;
          p_vlipi   := (p_pvenda - vnst) * (p_percipivenda / 100);
          IF p_condvenda IN (2, 7)
          THEN
            p_vlipi := p_vlipi * (p_percvenda / 100);
          END IF;
          IF p_condvenda IN (3, 6, 12)
          THEN
            p_vlipi := 0;
          END IF;
          --Tipo de Cálculo do IPI
          IF p_tipocalcipi = 'T2'
          THEN
            p_vlipi := round(p_vlipi * 100) / 100;
          ELSIF p_tipocalcipi = 'A2'
          THEN
            p_vlipi := round(p_vlipi,
                             2);
          ELSIF p_tipocalcipi = 'PV'
          THEN
            p_vlipi := round(p_vlipi,
                             p_numcasasdecvenda);
          END IF;
        END IF;
        --Acrescentar o IPI no P. Venda e no P. Tabela
        p_pvenda   := round(p_pvenda + p_vlipi,
                            p_numcasasdecvenda);
        p_ptabela  := round(p_ptabela + p_vlipi,
                            p_numcasasdecvenda);
        p_pbaserca := round(p_pbaserca + p_vlipi,
                            p_numcasasdecvenda);
        vsuffilial := p_uffilial;
        IF p_filialnf IS NOT NULL
        THEN
          vsuffilial := p_uffilialnf;
        END IF;
        IF NOT calcularst(p_pvenda,
                          p_vlipi,
                          p_percvenda,
                          p_tipocalcst,
                          p_calcstpf,
                          p_mostrarpvendasemst,
                          p_consideraisentoscomopf,
                          p_calculast,
                          p_ieent,
                          p_tipofj,
                          p_pauta,
                          p_iva,
                          p_aliqicms1,
                          p_aliqicms2,
                          p_percbaseredst,
                          p_numcasasdecvenda,
                          0,
                          vsuffilial,
                          p_estent,
                          p_usavalorultentbasest,
                          p_valorultent,
                          p_contribuinte,
                          vsmensagem_st,
                          vnst,
                          p_baseicst)
        THEN
          vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                        vsmensagem_st;
        ELSE
          p_st := vnst;
        END IF;
      ELSE
        vnpercbaseredst := p_percbaseredst;
        IF p_percbaseredst = 0
        THEN
          vnpercbaseredst := 100;
        END IF;
        --Tirar ST e IPI de preço com ambos
        vnpvenda   := (p_pvenda /
                      (1 + (p_percipivenda / 100) +
                      ((((p_aliqicms1 / 100) * (1 + (p_iva / 100)) *
                      (1 + (p_percipivenda / 100)) *
                      (vnpercbaseredst / 100)) - (p_aliqicms2 / 100)))));
        p_percipi  := p_percipivenda;
        p_vlipi    := vnpvenda * (p_percipivenda / 100);
        vsuffilial := p_uffilial;
        IF p_filialnf IS NOT NULL
        THEN
          vsuffilial := p_uffilialnf;
        END IF;
        -- p_pvenda := vnpvenda;
        IF NOT calcularst(vnpvenda,
                          p_vlipi,
                          p_percvenda,
                          p_tipocalcst,
                          p_calcstpf,
                          p_mostrarpvendasemst,
                          p_consideraisentoscomopf,
                          p_calculast,
                          p_ieent,
                          p_tipofj,
                          p_pauta,
                          p_iva,
                          p_aliqicms1,
                          p_aliqicms2,
                          p_percbaseredst,
                          p_numcasasdecvenda,
                          1,
                          vsuffilial,
                          p_estent,
                          p_usavalorultentbasest,
                          p_valorultent,
                          p_contribuinte,
                          vsmensagem_st,
                          vnst,
                          p_baseicst)
        THEN
          vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                        vsmensagem_st;
        ELSE
          p_st := vnst;
        END IF;
        IF vsisentoipi = 'N'
        THEN
          IF p_condvenda IN (2, 7)
          THEN
            p_vlipi := p_vlipi * (p_percvenda / 100);
          END IF;
          IF p_condvenda IN (3, 6, 12)
          THEN
            p_vlipi := 0;
          END IF;
          --Tipo de Cálculo do IPI
          IF p_tipocalcipi = 'T2'
          THEN
            p_vlipi := round(p_vlipi * 100) / 100;
          ELSIF p_tipocalcipi = 'A2'
          THEN
            p_vlipi := round(p_vlipi,
                             2);
          ELSIF p_tipocalcipi = 'PV'
          THEN
            p_vlipi := round(p_vlipi,
                             p_numcasasdecvenda);
          END IF;
        ELSE
          p_percipi := 0;
          p_vlipi   := 0;
        END IF;
      END IF;
      vbresult := TRUE;

    */

    RETURN vbresult;
  EXCEPTION
    WHEN exc_dados THEN
      p_mensagem := 'Erro ao calcular impostos: ' || vsmensagem;
      RETURN FALSE;
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calculartodosimpostos;

  FUNCTION buscardadosprodutos -- 115 parametros
  (pnnumped      IN pcpedc.numped%TYPE,
   pscodfilial   IN pcpedc.codfilial%TYPE,
   pscodfilialnf IN pcpedc.codfilialnf%TYPE,
   ----observacao pode ser filial do PCTABPRCLI
   psorigemped             IN pcpedc.origemped%TYPE,
   psfretedespacho         IN pcpedc.fretedespacho%TYPE,
   pncondvenda             IN pcpedc.condvenda%TYPE,
   pnpercvenda             IN pcpedc.percvenda%TYPE,
   pncodplpag              IN pcpedc.codplpag%TYPE,
   pncodcli                IN pcpedc.codcli%TYPE,
   pncodusur               IN pcpedc.codusur%TYPE,
   pddata                  IN pcpedc.data%TYPE,
   pncodsupervisor         IN pcusuari.codsupervisor%TYPE,
   pstipovend              IN pcusuari.tipovend%TYPE,
   pnpercent               IN pcusuari.percent%TYPE,
   pnpercent2              IN pcusuari.percent2%TYPE,
   psfilialuf              IN pcfilial.uf%TYPE,
   psfilialnfuf            IN pcfilial.uf%TYPE,
   pncodfunc               IN pcempr.matricula%TYPE,
   pnperfreteterceiros     IN pcregiao.perfreteterceiros%TYPE,
   pnperfreteespecial      IN pcregiao.perfreteespecial%TYPE,
   psestent                IN pcclient.estent%TYPE,
   psieent                 IN pcclient.ieent%TYPE,
   pstipofj                IN pcclient.tipofj%TYPE,
   pscontribuinte          IN pcclient.contribuinte%TYPE,
   psclassevenda           IN pcclient.classevenda%TYPE,
   pncodcliprinc           IN pcclient.codcliprinc%TYPE,
   pncodpraca              IN pcclient.codpraca%TYPE,
   pstipocustotransf       IN pcclient.tipocustotransf%TYPE,
   psisentoipi             IN pcclient.isentoipi%TYPE,
   pssulframa              IN pcclient.sulframa%TYPE,
   pscalculast             IN pcclient.calculast%TYPE,
   pnperdesccli            IN pcclient.perdesc%TYPE,
   pnpercomcli             IN pcclient.percomcli%TYPE,
   psutilizaiesimplificada IN pcclient.utilizaiesimplificada%TYPE,
   psclientefontest        IN pcclient.clientefontest%TYPE,
   psisentoicms            IN pcclient.isentoicms%TYPE,
   psconsumidorfinal       IN pcclient.consumidorfinal%TYPE,
   pstipoempresa           IN pcclient.tipoempresa%TYPE,
   pnperdescativ           IN pcativi.percdesc%TYPE,
   pncodprod               IN pcprodut.codprod%TYPE,
   pncodauxiliar           IN pcprodut.codauxiliar%TYPE,
   pnnumregiao             IN pcregiao.numregiao%TYPE,
   --observacao pode ser regiao do PCTABPRCLI ou do broker
   pnperfrete IN pcregiao.perfrete%TYPE,
   --observacao pode ser frete da regiao do PCTABPRCLI ou do broker
   psutilizavendaporembalagem  IN pcconsum.utilizavendaporembalagem%TYPE,
   psprecoporembalagem         IN pcconsum.precoporembalagem%TYPE,
   psusatributacaoporuf        IN pcconsum.usatributacaoporuf%TYPE,
   psabatefretevendabalcao     IN pcconsum.abatefretevendabalcao%TYPE,
   pnnumcasasdecvenda          IN pcconsum.numcasasdecvenda%TYPE,
   psusartributacaotransftv10  IN pcconsum.usartributacaotransftv10%TYPE,
   pnpercacrescimobalcao       IN pcconsum.percacrescimobalcao%TYPE,
   psaplicaacrescpftv3         IN pcconsum.aplicaacrescpftv3%TYPE,
   psacrescimopfcomie          IN pcconsum.acrescimopfcomie%TYPE,
   psusadescporlinhaprod       IN pcconsum.usadescporlinhaprod%TYPE,
   pstratarrestricaoacrescimo  IN pcconsum.tratarrestricaoacrescimo%TYPE,
   psvalidapvendabonific       IN pcconsum.validapvendabonific%TYPE,
   psutilizapercfinprecoprom   IN pcconsum.utilizapercfinprecoprom%TYPE,
   pscalcularstcomipi          IN pcconsum.calcularstcomipi%TYPE,
   psmostrarpvendasemst        IN pcconsum.mostrarpvendasemst%TYPE,
   pstipocalcst                IN pcconsum.tipocalcst%TYPE,
   pscalcstpf                  IN pcconsum.calcstpf%TYPE,
   psconsideraisentoscomopf    IN pcconsum.consideraisentoscomopf%TYPE,
   pnpermaxvenda               IN pcconsum.permaxvenda%TYPE,
   pstipocalcsulframa          IN pcconsum.tipocalcsulframa%TYPE,
   psusacomissaoporcliente     IN pcconsum.usacomissaoporcliente%TYPE,
   psusacomissaoporrca         IN pcconsum.usacomissaoporrca%TYPE,
   pscomissaorcatipovenda      IN pcconsum.comissaorcatipovenda%TYPE,
   psusacomissaoporlinhaprod   IN pcconsum.usacomissaoporlinhaprod%TYPE,
   psabaterimpostoscomissaorca IN pcconsum.abaterimpostoscomissaorca%TYPE,
   psaplicarindicecmv          IN pcconsum.aplicarindicecmv%TYPE,
   pntxvenda                   IN pcconsum.txvenda%TYPE,
   psutilizapercbaseredpf      IN pcconsum.utilizapercbaseredpf%TYPE,
   pnordemavaliacaocomissaorca IN pcconsum.ordemavaliacaocomissaorca%TYPE,
   pstipocalcipi               IN pcconsum.tipocalcipi%TYPE,
   pbusapoliticadescontos      IN BOOLEAN,
   pbusaprecofixo              IN BOOLEAN,
   pnnumpr                     IN pcplpag.numpr%TYPE,
   pnpertxfim                  IN pcplpag.pertxfim%TYPE,
   pnnumdias                   IN pcplpag.numdias%TYPE,
   pstipovenda                 IN pcplpag.tipovenda%TYPE,
   pnpvenda                    IN OUT pcpedi.pvenda%TYPE,
   pnqtvendida                 IN pcpedi.qt%TYPE,
   psnumlote                   IN VARCHAR2,
   pnptabela                   OUT pcpedi.ptabela%TYPE,
   pnpbaserca                  OUT pcpedi.pbaserca%TYPE,
   pnpvendabase                OUT pcpedi.pvendabase%TYPE,
   pnporiginal                 OUT pcpedi.poriginal%TYPE,
   pncodst                     OUT pcpedi.codst%TYPE,
   pnst                        OUT pcpedi.st%TYPE,
   pnbaseicst                  OUT pcpedi.baseicst%TYPE,
   pniva                       OUT pcpedi.iva%TYPE,
   pnpauta                     OUT pcpedi.pauta%TYPE,
   pnaliqicms1                 OUT pcpedi.aliqicms1%TYPE,
   pnaliqicms2                 OUT pcpedi.aliqicms1%TYPE,
   pnvlipi                     OUT pcpedi.vlipi%TYPE,
   pnvliss                     OUT pcpedi.vliss%TYPE,
   pnpercom                    OUT pcpedi.percom%TYPE,
   pnperfretecmv               OUT pcpedi.perfretecmv%TYPE,
   pncustofinest               OUT pcpedi.custofinest%TYPE,
   pntxvenda_item              OUT pcpedi.txvenda%TYPE,
   pnperdesccusto_item         OUT pcpedi.perdesccusto%TYPE,
   pncodicmtab_item            OUT pcpedi.codicmtab%TYPE,
   pnvlcustoreal               OUT pcpedi.vlcustoreal%TYPE,
   pnvlcustofin                OUT pcpedi.vlcustofin%TYPE,
   pnvldesccustocmv            OUT pcpedi.vldesccustocmv%TYPE,
   pnstclientegnre             OUT pcpedi.stclientegnre%TYPE,
   pnpercbaseredst             OUT pcpedi.percbaseredst%TYPE,
   pnpercbaseredstfonte        OUT pcpedi.percbaseredstfonte%TYPE,
   pnpercipi                   OUT pcpedi.percipi%TYPE,
   pnvldescsuframa             OUT pcpedi.vldescsuframa%TYPE,
   pnperciss                   OUT pcpedi.perciss%TYPE,
   pnperdesc                   OUT pcpedi.perdesc%TYPE,
   pnletracomiss               OUT pcpedi.letracomiss%TYPE,
   pnpvendamin                 OUT NUMBER,
   pnpvendamax                 OUT NUMBER,
   psmensagem                  OUT VARCHAR2) RETURN BOOLEAN --Preço Válido Ou Não
   IS
    vncodst                 pctribut.codst%TYPE;
    vnptabela               NUMBER;
    vnptabelaantes          NUMBER;
    vnpbaserca              NUMBER;
    vnpvendabase            NUMBER;
    vnporiginal             NUMBER;
    vbvalido                BOOLEAN;
    vicontador              NUMBER;
    vnvlbonific             NUMBER;
    vnvldescom              NUMBER;
    vnpercdesccom           NUMBER;
    vnprecocesta            NUMBER;
    vnbaseicst              NUMBER;
    vnvlipi                 NUMBER;
    vncodfornec             pcprodut.codfornec%TYPE;
    vnclasseproduto         pcprodut.classe%TYPE;
    vnperdescfob            pctabpr.perdescfob%TYPE;
    vnpvendaemb             pcembalagem.pvenda%TYPE;
    vnqtunit                pcembalagem.qtunit%TYPE;
    vncodauxiliar           pcembalagem.codauxiliar%TYPE;
    vnqtminimaatacado       pcembalagem.qtminimaatacado%TYPE;
    vnfatorpreco            pcembalagem.fatorpreco%TYPE;
    vnpvendaatac            pcembalagem.pvendaatac%TYPE;
    vnpoferta               pcembalagem.poferta%TYPE;
    vddtofertaini           pcembalagem.dtofertaini%TYPE;
    vddtofertafim           pcembalagem.dtofertafim%TYPE;
    vncodsec                pcprodut.codsec%TYPE;
    vncustofin              pcest.custofin%TYPE;
    vncodcategoria          pcprodut.codcategoria%TYPE;
    vncustoreal             pcest.custoreal%TYPE;
    vncustorep              pcest.custorep%TYPE;
    vncustorealsemst        pcest.custorealsemst%TYPE;
    vnperdestab             pctribut.perdestab%TYPE;
    vnperdescmaxesp         pctabpr.perdescmaxesp%TYPE;
    vnperdesccusto          pctribut.perdesccusto%TYPE;
    vnpauta                 pctribut.pauta%TYPE;
    vniva                   pctribut.iva%TYPE;
    vnpercbasered           pctribut.percbasered%TYPE;
    vnaliqicms1             pctribut.aliqicms1%TYPE;
    vnaliqicms2             pctribut.aliqicms2%TYPE;
    vncodicm                pctribut.codicm%TYPE;
    vnsittribut             pctribut.sittribut%TYPE;
    vnperdescmax            pctabpr.perdescmax%TYPE;
    vncodfiscal             pctribut.codfiscal%TYPE;
    vncodfiscalinter        pctribut.codfiscalinter%TYPE;
    vnpercipivenda          pcprodut.percipivenda%TYPE;
    vncodicmtab             pctribut.codicmtab%TYPE;
    vnpvenda                pctabpr.pvenda%TYPE;
    vnpercbonificvenda      pcprodut.percbonificvenda%TYPE;
    vnqtunitcx              pcprodut.qtunitcx%TYPE;
    vnpcomint1              pcprodut.pcomint1%TYPE;
    vnpcomext1              pcprodut.pcomext1%TYPE;
    vnpcomrep1              pcprodut.pcomrep1%TYPE;
    vncodepto               pcprodut.codepto%TYPE;
    vnclasse                pcprodut.classe%TYPE;
    vnperacrescismopf       pctribut.peracrescismopf%TYPE;
    vnpiscofinsretido       pcprodut.piscofinsretido%TYPE;
    vncustocont             pcest.custocont%TYPE;
    vnperdescmaxbalcao      pctabpr.perdescmaxbalcao%TYPE;
    vncustoultent           pcest.custoultent%TYPE;
    vnvalorultent           pcest.valorultent%TYPE;
    vncodlinhaprod          pcprodut.codlinhaprod%TYPE;
    vspsicotropico          pcprodut.psicotropico%TYPE;
    vnmultiplo              pcprodut.multiplo%TYPE;
    vnivafonte              pctribut.ivafonte%TYPE;
    vnaliqicms1fonte        pctribut.aliqicms1fonte%TYPE;
    vnaliqicms2fonte        pctribut.aliqicms2fonte%TYPE;
    vnperbaserednrpa        pctribut.perbaserednrpa%TYPE;
    vnpercbaseredconsumidor pctribut.percbaseredconsumidor%TYPE;
    vnperdescsuframa        pctribut.perdescsuframa%TYPE;
    vsutilizapercbaseredpf  pctribut.utilizapercbaseredpf%TYPE;
    vnperpis                pcprodut.perpis%TYPE;
    vstipomerc              pcprodut.tipomerc%TYPE;
    vnaliqiss               pctribut.aliqiss%TYPE;
    vnpercbaseredst         pctribut.percbaseredst%TYPE;
    vnpercbaseredstfonte    pctribut.percbaseredstfonte%TYPE;
    vsexcluido              pctabpr.excluido%TYPE;
    vncoddistrib            pcfornec.coddistrib%TYPE;
    vncodprodprinc          pcprodut.codprodprinc%TYPE;
    vstipocalculognre       pctribut.tipocalculognre%TYPE;
    vsfreteespecial         pcprodut.freteespecial%TYPE;
    vsaplicaacrescpjisenta  pctribut.aplicaacrescpjisenta%TYPE;
    vsaceitavendafracao     pcprodut.aceitavendafracao%TYPE;
    vncodicmtabpf           pctribut.codicmtabpf%TYPE;
    vncodicmpf              pctribut.codicmpf%TYPE;
    vsusavalorultentbasest  pctribut.usavalorultentbasest%TYPE;
    vstipocomissao          pcprodut.tipocomissao%TYPE;
    vnprecofab              pctabpr.precofab%TYPE;
    vddthoje                DATE;
    vnprazomediovenda       pcprodut.prazomediovenda%TYPE;
    vsestoqueporlote        pcprodut.estoqueporlote%TYPE;
    vnaliqicms1transf       pctribut.aliqicms1transf%TYPE;
    vnaliqicms2transf       pctribut.aliqicms2transf%TYPE;
    vnivatransf             pctribut.ivatransf%TYPE;
    vnpautatransf           pctribut.pautatransf%TYPE;
    vnpercbaseredsttransf   pctribut.percbaseredsttransf%TYPE;
    vsconciliaimportacao    pcprodut.conciliaimportacao%TYPE;
    vsdescontafrete         pctabpr.descontafrete%TYPE;
    --    vnrua pcprodut.rua%type;
    vnpesobruto              pcprodut.pesobruto%TYPE;
    vnpesoliq                pcprodut.pesoliq%TYPE;
    vnvolume                 pcprodut.volume%TYPE;
    vnnumero                 pcprodut.numero%TYPE;
    vnmodulo                 pcprodut.modulo%TYPE;
    vnapto                   pcprodut.apto%TYPE;
    vsobs                    pcprodut.obs%TYPE;
    vbcesta                  BOOLEAN;
    vsmensagemcesta          VARCHAR2(300);
    vsmensagem               VARCHAR2(3000);
    vddtfimdesconto          pcdesconto.dtfim%TYPE;
    vsmensagem_politica      VARCHAR2(300);
    vnperdesc_politica       pcdesconto.percdesc%TYPE;
    vsbasecreddebrca         pcdesconto.basecreddebrca%TYPE;
    vnperdesc_restricao      pcdesconto.percdesc%TYPE;
    vnperdesc                NUMBER;
    vsmensagem_precofixo     VARCHAR2(300);
    vbprecofixo              BOOLEAN;
    vnprecofixo              NUMBER;
    vddtfimpromocao          pcprecoprom.dtfimvigencia%TYPE;
    vsisentoipi              pcclient.isentoipi%TYPE;
    vsuffilial               pcfilial.uf%TYPE;
    vsmensagem_st            VARCHAR2(300);
    vnst                     pcpedi.st%TYPE;
    vnptabelaorig            NUMBER;
    vnpermaxdesc             NUMBER;
    vsmensagemdescquant      VARCHAR2(300);
    vbvalidodescquant        BOOLEAN;
    vddtfim                  DATE;
    vnptabeladescquant       NUMBER;
    vnppolitica              NUMBER;
    vnpvendamin              NUMBER;
    vnpermaxvenda            NUMBER;
    vnpercdescpolitica_acres NUMBER;
    vnpvendamax              NUMBER;
    vnptabela_ant            NUMBER;
    vnnrautorizacao          pcautori.nrautorizacao%TYPE;
    vnpercdescautor          pcautori.percdescautor%TYPE;
    vnpvendaatual            pcautori.pvendaatual%TYPE;
    vsbasecreddebrca_autori  pcautori.basecreddebrca%TYPE;
    vnpvenda_autori          pcautori.pvendido%TYPE;
    vnvldescsuframa          pcpedi.vldescsuframa%TYPE;
    vnperciss                pcpedi.perciss%TYPE;
    vnvliss                  pcpedi.vliss%TYPE;
    vnbciss                  NUMBER;
    vsmensagem_comis         VARCHAR2(300);
    vnpercom                 NUMBER;
    vbcodicmtabpf            BOOLEAN;
    vnstclientegnre          pcpedi.stclientegnre%TYPE;
    vnstfonte                NUMBER;
    vsmensagem_stfonte       VARCHAR2(300);
    vsmensagem_rest          VARCHAR2(300);
    vnpreco                  NUMBER;
    vnperluc                 NUMBER;
    vnperfretecmv            pcpedi.perfretecmv%TYPE;
    vncustofinest            pcpedi.custofinest%TYPE;
    vntxvenda_item           pcpedi.txvenda%TYPE;
    vnperdesccusto_item      pcpedi.perdesccusto%TYPE;
    vncodicmtab_item         pcpedi.codicmtab%TYPE;
    vnvlcustoreal            pcpedi.vlcustoreal%TYPE;
    vnvlcustofin             pcpedi.vlcustofin%TYPE;
    vnvldesccustocmv         pcpedi.vldesccustocmv%TYPE;
    vncodativ                pcclient.codatv1%TYPE;
    vnptabela_aux            pcpedi.ptabela%TYPE;
    vnpvenda_aux             pcpedi.pvenda%TYPE;
  BEGIN
    vbvalido   := TRUE;
    vddthoje   := trunc(SYSDATE);
    vsmensagem := NULL;
    vnpvenda   := pnpvenda;
    SELECT codatv1 INTO vncodativ FROM pcclient WHERE codcli = pncodcli;
    IF nvl(psusatributacaoporuf, 'N') = 'S' THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pctabtrib
       WHERE pctabtrib.codprod = pncodprod
         AND pctabtrib.ufdestino = psestent
         AND pctabtrib.codfilialnf = pscodfilialnf;
      IF vicontador = 0 THEN
        vsmensagem := 'Tributacao por estado inexistente';
        vbvalido   := FALSE;
      ELSE
        SELECT codst
          INTO vncodst
          FROM pctabtrib
         WHERE pctabtrib.codprod = pncodprod
           AND pctabtrib.ufdestino = psestent
           AND pctabtrib.codfilialnf = pscodfilialnf;
      END IF;
    ELSE
      SELECT COUNT(*)
        INTO vicontador
        FROM pctabpr
       WHERE pctabpr.codprod = pncodprod
         AND pctabpr.numregiao = pnnumregiao;
      IF vicontador = 0 THEN
        psmensagem := 'Tributacao inexistente';
        vbvalido   := FALSE;
      ELSE
        SELECT codst
          INTO vncodst
          FROM pctabpr
         WHERE pctabpr.codprod = pncodprod
           AND pctabpr.numregiao = pnnumregiao;
      END IF;
    END IF;
    IF vbvalido = TRUE THEN
      IF (psutilizavendaporembalagem = 'S') AND (psprecoporembalagem = 'S') THEN
        SELECT pcprodut.codfornec,
               nvl(pctabpr.perdescfob, 0) perdescfob,
               nvl(pctabpr.descontafrete, 'N') descontafrete,
               nvl(pcembalagem.pvenda, 0),
               pcembalagem.qtunit,
               pcembalagem.codauxiliar,
               nvl(pcembalagem.qtminimaatacado, 0) qtminimaatacado,
               nvl(pcembalagem.fatorpreco, 0) fatorpreco,
               nvl(pcembalagem.pvendaatac, 0),
               nvl(pcembalagem.poferta, 0),
               pcembalagem.dtofertaini,
               pcembalagem.dtofertafim,
               pcprodut.codsec,
               nvl(pcest.custofin, 0),
               pcprodut.codcategoria,
               nvl(pcest.custoreal, 0),
               nvl(pcest.custorep, 0),
               nvl(pcest.custorealsemst, 0),
               pctribut.perdestab,
               pctabpr.perdescmaxesp,
               nvl(pctribut.perdesccusto, 0),
               nvl(pctribut.pauta, 0),
               nvl(pctribut.iva, 0),
               nvl(pctribut.percbasered, 0),
               nvl(pctribut.aliqicms1, 0),
               nvl(pctribut.aliqicms2, 0),
               pctribut.codicm,
               pctribut.sittribut,
               nvl(pctabpr.perdescmax, 0),
               pctribut.codfiscal,
               pctribut.codfiscalinter,
               nvl(pcprodut.percipivenda, 0),
               pctribut.codicmtab,
               nvl(pcprodut.percbonificvenda, 0),
               pcprodut.qtunitcx,
               pcprodut.pcomint1,
               pcprodut.pcomext1,
               pcprodut.pcomrep1,
               pcprodut.codepto,
               pcprodut.classe,
               nvl(pctribut.peracrescismopf, 0),
               pcprodut.piscofinsretido,
               nvl(pcest.custocont, 0),
               nvl(pctabpr.perdescmaxbalcao, 0),
               nvl(pcest.custoultent, 0),
               nvl(pcest.valorultent, 0),
               pcprodut.codlinhaprod,
               nvl(pcprodut.psicotropico, 'N') psicotropico,
               pcprodut.multiplo,
               nvl(pctribut.ivafonte, 0),
               nvl(pctribut.aliqicms1fonte, 0),
               nvl(pctribut.aliqicms2fonte, 0),
               nvl(pctribut.perbaserednrpa, 0),
               nvl(pctribut.percbaseredconsumidor, 0),
               nvl(pctribut.perdescsuframa, 0),
               pctribut.utilizapercbaseredpf,
               nvl(pcprodut.perpis, 0),
               pcprodut.tipomerc,
               nvl(pctribut.aliqiss, 0),
               nvl(pctribut.percbaseredst, 0),
               nvl(pctribut.percbaseredstfonte, 0),
               nvl(pctabpr.excluido, 'N') excluido,
               nvl(pcfornec.coddistrib, pcprodut.coddistrib) coddistrib,
               pcprodut.codprodprinc,
               nvl(pctribut.tipocalculognre, 'P') tipocalculognre,
               nvl(pcprodut.freteespecial, 'N') freteespecial,
               nvl(pctribut.aplicaacrescpjisenta, 'S') aplicaacrescpjisenta,
               nvl(pcprodut.aceitavendafracao, 'N') aceitavendafracao,
               nvl(pctribut.codicmtabpf, pctribut.codicmtab) codicmtabpf,
               pctribut.codicmpf,
               nvl(pctribut.usavalorultentbasest, 'N') usavalorultentbasest,
               nvl(pcprodut.tipocomissao, 'P') tipocomissao,
               nvl(pctabpr.precofab, 0),
               --             trunc(sysdate),
               pcprodut.prazomediovenda,
               nvl(pcprodut.estoqueporlote, 'N'),
               nvl(pctribut.aliqicms1transf, 0),
               nvl(pctribut.aliqicms2transf, 0),
               nvl(pctribut.ivatransf, 0),
               nvl(pctribut.pautatransf, 0),
               nvl(pctribut.percbaseredsttransf, 0),
               nvl(pcprodut.conciliaimportacao, 'N'),
               pcprodut.classe
          INTO vncodfornec,
               vnperdescfob,
               vsdescontafrete,
               vnptabela,
               vnqtunit,
               vncodauxiliar,
               vnqtminimaatacado,
               vnfatorpreco,
               vnpvendaatac,
               vnpoferta,
               vddtofertaini,
               vddtofertafim,
               vncodsec,
               vncustofin,
               vncodcategoria,
               vncustoreal,
               vncustorep,
               vncustorealsemst,
               vnperdestab,
               vnperdescmaxesp,
               vnperdesccusto,
               vnpauta,
               vniva,
               vnpercbasered,
               vnaliqicms1,
               vnaliqicms2,
               vncodicm,
               vnsittribut,
               vnperdescmax,
               vncodfiscal,
               vncodfiscalinter,
               vnpercipivenda,
               vncodicmtab,
               vnpercbonificvenda,
               vnqtunitcx,
               vnpcomint1,
               vnpcomext1,
               vnpcomrep1,
               vncodepto,
               vnclasse,
               vnperacrescismopf,
               vnpiscofinsretido,
               vncustocont,
               vnperdescmaxbalcao,
               vncustoultent,
               vnvalorultent,
               vncodlinhaprod,
               vspsicotropico,
               vnmultiplo,
               vnivafonte,
               vnaliqicms1fonte,
               vnaliqicms2fonte,
               vnperbaserednrpa,
               vnpercbaseredconsumidor,
               vnperdescsuframa,
               vsutilizapercbaseredpf,
               vnperpis,
               vstipomerc,
               vnaliqiss,
               vnpercbaseredst,
               vnpercbaseredstfonte,
               vsexcluido,
               vncoddistrib,
               vncodprodprinc,
               vstipocalculognre,
               vsfreteespecial,
               vsaplicaacrescpjisenta,
               vsaceitavendafracao,
               vncodicmtabpf,
               vncodicmpf,
               vsusavalorultentbasest,
               vstipocomissao,
               vnprecofab,
               --             vddthoje,
               vnprazomediovenda,
               vsestoqueporlote,
               vnaliqicms1transf,
               vnaliqicms2transf,
               vnivatransf,
               vnpautatransf,
               vnpercbaseredsttransf,
               vsconciliaimportacao,
               vnclasseproduto
          FROM pctabpr, pcembalagem, pcprodut, pctribut, pcest, pcfornec
         WHERE pcprodut.codprod = pncodprod
           AND pctabpr.codprod = pcprodut.codprod
           AND pcembalagem.codprod = pcprodut.codprod
           AND pcembalagem.codfilial = pscodfilial
           AND pcembalagem.codauxiliar = pncodauxiliar
           AND pctribut.codst = vncodst
           AND (pcprodut.codfornec = pcfornec.codfornec)
           AND (pcprodut.codprod = pcest.codprod)
           AND (rtrim(ltrim(pcest.codfilial)) = pscodfilial)
           AND (pctabpr.numregiao = pnnumregiao)
           AND ((pcprodut.codfilial = pscodfilial) OR
               (pcprodut.codfilial IS NULL));
      ELSIF (psutilizavendaporembalagem = 'S') AND
            (psprecoporembalagem = 'N') THEN
        SELECT pcprodut.codfornec,
               nvl(pctabpr.perdescfob, 0) perdescfob,
               nvl(pctabpr.descontafrete, 'N') descontafrete,
               decode(pnnumpr,
                      1,
                      pctabpr.pvenda1,
                      2,
                      pctabpr.pvenda2,
                      3,
                      pctabpr.pvenda3,
                      4,
                      pctabpr.pvenda4,
                      5,
                      pctabpr.pvenda5,
                      6,
                      pctabpr.pvenda6,
                      7,
                      pctabpr.pvenda7,
                      pctabpr.pvenda1) pvenda,
               pcembalagem.qtunit,
               pcembalagem.codauxiliar,
               nvl(pcembalagem.qtminimaatacado, 0) qtminimaatacado,
               nvl(pcembalagem.fatorpreco, 0) fatorpreco,
               0 pvendaatac,
               0 poferta,
               trunc(SYSDATE) dtofertaini,
               trunc(SYSDATE) dtofertafim,
               pcprodut.codsec,
               nvl(pcest.custofin, 0),
               pcprodut.codcategoria,
               nvl(pcest.custoreal, 0),
               nvl(pcest.custorep, 0),
               nvl(pcest.custorealsemst, 0),
               pctribut.perdestab,
               pctabpr.perdescmaxesp,
               nvl(pctribut.perdesccusto, 0),
               nvl(pctribut.pauta, 0),
               nvl(pctribut.iva, 0),
               nvl(pctribut.percbasered, 0),
               nvl(pctribut.aliqicms1, 0),
               nvl(pctribut.aliqicms2, 0),
               pctribut.codicm,
               pctribut.sittribut,
               nvl(pctabpr.perdescmax, 0),
               pctribut.codfiscal,
               pctribut.codfiscalinter,
               nvl(pcprodut.percipivenda, 0),
               pctribut.codicmtab,
               nvl(pcprodut.percbonificvenda, 0),
               pcprodut.qtunitcx,
               pcprodut.pcomint1,
               pcprodut.pcomext1,
               pcprodut.pcomrep1,
               pcprodut.codepto,
               pcprodut.classe,
               nvl(pctribut.peracrescismopf, 0),
               pcprodut.piscofinsretido,
               nvl(pcest.custocont, 0),
               nvl(pctabpr.perdescmaxbalcao, 0),
               nvl(pcest.custoultent, 0),
               nvl(pcest.valorultent, 0),
               pcprodut.codlinhaprod,
               nvl(pcprodut.psicotropico, 'N') psicotropico,
               pcprodut.multiplo,
               nvl(pctribut.ivafonte, 0),
               nvl(pctribut.aliqicms1fonte, 0),
               nvl(pctribut.aliqicms2fonte, 0),
               nvl(pctribut.perbaserednrpa, 0),
               nvl(pctribut.percbaseredconsumidor, 0),
               nvl(pctribut.perdescsuframa, 0),
               pctribut.utilizapercbaseredpf,
               nvl(pcprodut.perpis, 0),
               pcprodut.tipomerc,
               nvl(pctribut.aliqiss, 0),
               nvl(pctribut.percbaseredst, 0),
               nvl(pctribut.percbaseredstfonte, 0),
               nvl(pctabpr.excluido, 'N') excluido,
               nvl(pcfornec.coddistrib, pcprodut.coddistrib) coddistrib,
               pcprodut.codprodprinc,
               nvl(pctribut.tipocalculognre, 'P') tipocalculognre,
               nvl(pcprodut.freteespecial, 'N') freteespecial,
               nvl(pctribut.aplicaacrescpjisenta, 'S') aplicaacrescpjisenta,
               nvl(pcprodut.aceitavendafracao, 'N') aceitavendafracao,
               nvl(pctribut.codicmtabpf, pctribut.codicmtab) codicmtabpf,
               pctribut.codicmpf,
               nvl(pctribut.usavalorultentbasest, 'N') usavalorultentbasest,
               nvl(pcprodut.tipocomissao, 'P') tipocomissao,
               nvl(pctabpr.precofab, 0),
               --             trunc(sysdate),
               pcprodut.prazomediovenda,
               nvl(pcprodut.estoqueporlote, 'N'),
               nvl(pctribut.aliqicms1transf, 0),
               nvl(pctribut.aliqicms2transf, 0),
               nvl(pctribut.ivatransf, 0),
               nvl(pctribut.pautatransf, 0),
               nvl(pctribut.percbaseredsttransf, 0),
               nvl(pcprodut.conciliaimportacao, 'N')
          INTO vncodfornec,
               vnperdescfob,
               vsdescontafrete,
               vnptabela,
               vnqtunit,
               vncodauxiliar,
               vnqtminimaatacado,
               vnfatorpreco,
               vnpvendaatac,
               vnpoferta,
               vddtofertaini,
               vddtofertafim,
               vncodsec,
               vncustofin,
               vncodcategoria,
               vncustoreal,
               vncustorep,
               vncustorealsemst,
               vnperdestab,
               vnperdescmaxesp,
               vnperdesccusto,
               vnpauta,
               vniva,
               vnpercbasered,
               vnaliqicms1,
               vnaliqicms2,
               vncodicm,
               vnsittribut,
               vnperdescmax,
               vncodfiscal,
               vncodfiscalinter,
               vnpercipivenda,
               vncodicmtab,
               vnpercbonificvenda,
               vnqtunitcx,
               vnpcomint1,
               vnpcomext1,
               vnpcomrep1,
               vncodepto,
               vnclasse,
               vnperacrescismopf,
               vnpiscofinsretido,
               vncustocont,
               vnperdescmaxbalcao,
               vncustoultent,
               vnvalorultent,
               vncodlinhaprod,
               vspsicotropico,
               vnmultiplo,
               vnivafonte,
               vnaliqicms1fonte,
               vnaliqicms2fonte,
               vnperbaserednrpa,
               vnpercbaseredconsumidor,
               vnperdescsuframa,
               vsutilizapercbaseredpf,
               vnperpis,
               vstipomerc,
               vnaliqiss,
               vnpercbaseredst,
               vnpercbaseredstfonte,
               vsexcluido,
               vncoddistrib,
               vncodprodprinc,
               vstipocalculognre,
               vsfreteespecial,
               vsaplicaacrescpjisenta,
               vsaceitavendafracao,
               vncodicmtabpf,
               vncodicmpf,
               vsusavalorultentbasest,
               vstipocomissao,
               vnprecofab,
               --             vddthoje,
               vnprazomediovenda,
               vsestoqueporlote,
               vnaliqicms1transf,
               vnaliqicms2transf,
               vnivatransf,
               vnpautatransf,
               vnpercbaseredsttransf,
               vsconciliaimportacao
          FROM pctabpr, pcembalagem, pcprodut, pctribut, pcest, pcfornec
         WHERE pcprodut.codprod = pncodprod
           AND pctabpr.codprod = pcprodut.codprod
           AND pcembalagem.codprod = pcprodut.codprod
           AND pcembalagem.codfilial = pscodfilial
           AND pcembalagem.codauxiliar = pncodauxiliar
           AND pctribut.codst = vncodst
           AND (pcprodut.codfornec = pcfornec.codfornec)
           AND (pcprodut.codprod = pcest.codprod)
           AND (rtrim(ltrim(pcest.codfilial)) = pscodfilial)
           AND (pctabpr.numregiao = pnnumregiao)
           AND ((pcprodut.codfilial = pscodfilial) OR
               (pcprodut.codfilial IS NULL));
      ELSE
        SELECT pcprodut.codfornec,
               nvl(pctabpr.perdescfob, 0) perdescfob,
               nvl(pctabpr.descontafrete, 'N') descontafrete,
               decode(pnnumpr,
                      1,
                      pctabpr.pvenda1,
                      2,
                      pctabpr.pvenda2,
                      3,
                      pctabpr.pvenda3,
                      4,
                      pctabpr.pvenda4,
                      5,
                      pctabpr.pvenda5,
                      6,
                      pctabpr.pvenda6,
                      7,
                      pctabpr.pvenda7,
                      pctabpr.pvenda1) pvenda,
               pcprodut.qtunit,
               pcprodut.codauxiliar,
               0 qtminimaatacado,
               0 fatorpreco,
               0 pvendaatac,
               0 poferta,
               trunc(SYSDATE) dtofertaini,
               trunc(SYSDATE) dtofertafim,
               pcprodut.codsec,
               nvl(pcest.custofin, 0),
               pcprodut.codcategoria,
               nvl(pcest.custoreal, 0),
               nvl(pcest.custorep, 0),
               nvl(pcest.custorealsemst, 0),
               pctribut.perdestab,
               pctabpr.perdescmaxesp,
               nvl(pctribut.perdesccusto, 0),
               nvl(pctribut.pauta, 0),
               nvl(pctribut.iva, 0),
               nvl(pctribut.percbasered, 0),
               nvl(pctribut.aliqicms1, 0),
               nvl(pctribut.aliqicms2, 0),
               pctribut.codicm,
               pctribut.sittribut,
               nvl(pctabpr.perdescmax, 0),
               pctribut.codfiscal,
               pctribut.codfiscalinter,
               nvl(pcprodut.percipivenda, 0),
               pctribut.codicmtab,
               nvl(pcprodut.percbonificvenda, 0),
               pcprodut.qtunitcx,
               pcprodut.pcomint1,
               pcprodut.pcomext1,
               pcprodut.pcomrep1,
               pcprodut.codepto,
               pcprodut.classe,
               nvl(pctribut.peracrescismopf, 0),
               pcprodut.piscofinsretido,
               nvl(pcest.custocont, 0),
               nvl(pctabpr.perdescmaxbalcao, 0),
               nvl(pcest.custoultent, 0),
               nvl(pcest.valorultent, 0),
               pcprodut.codlinhaprod,
               nvl(pcprodut.psicotropico, 'N') psicotropico,
               pcprodut.multiplo,
               nvl(pctribut.ivafonte, 0),
               nvl(pctribut.aliqicms1fonte, 0),
               nvl(pctribut.aliqicms2fonte, 0),
               nvl(pctribut.perbaserednrpa, 0),
               nvl(pctribut.percbaseredconsumidor, 0),
               nvl(pctribut.perdescsuframa, 0),
               pctribut.utilizapercbaseredpf,
               nvl(pcprodut.perpis, 0),
               pcprodut.tipomerc,
               nvl(pctribut.aliqiss, 0),
               nvl(pctribut.percbaseredst, 0),
               nvl(pctribut.percbaseredstfonte, 0),
               nvl(pctabpr.excluido, 'N') excluido,
               nvl(pcfornec.coddistrib, pcprodut.coddistrib) coddistrib,
               pcprodut.codprodprinc,
               nvl(pctribut.tipocalculognre, 'P') tipocalculognre,
               nvl(pcprodut.freteespecial, 'N') freteespecial,
               nvl(pctribut.aplicaacrescpjisenta, 'S') aplicaacrescpjisenta,
               nvl(pcprodut.aceitavendafracao, 'N') aceitavendafracao,
               nvl(pctribut.codicmtabpf, pctribut.codicmtab) codicmtabpf,
               pctribut.codicmpf,
               nvl(pctribut.usavalorultentbasest, 'N') usavalorultentbasest,
               nvl(pcprodut.tipocomissao, 'P') tipocomissao,
               nvl(pctabpr.precofab, 0),
               --             trunc(sysdate),
               pcprodut.prazomediovenda,
               nvl(pcprodut.estoqueporlote, 'N'),
               nvl(pctribut.aliqicms1transf, 0),
               nvl(pctribut.aliqicms2transf, 0),
               nvl(pctribut.ivatransf, 0),
               nvl(pctribut.pautatransf, 0),
               nvl(pctribut.percbaseredsttransf, 0),
               nvl(pcprodut.conciliaimportacao, 'N')
          INTO vncodfornec,
               vnperdescfob,
               vsdescontafrete,
               vnptabela,
               vnqtunit,
               vncodauxiliar,
               vnqtminimaatacado,
               vnfatorpreco,
               vnpvendaatac,
               vnpoferta,
               vddtofertaini,
               vddtofertafim,
               vncodsec,
               vncustofin,
               vncodcategoria,
               vncustoreal,
               vncustorep,
               vncustorealsemst,
               vnperdestab,
               vnperdescmaxesp,
               vnperdesccusto,
               vnpauta,
               vniva,
               vnpercbasered,
               vnaliqicms1,
               vnaliqicms2,
               vncodicm,
               vnsittribut,
               vnperdescmax,
               vncodfiscal,
               vncodfiscalinter,
               vnpercipivenda,
               vncodicmtab,
               vnpercbonificvenda,
               vnqtunitcx,
               vnpcomint1,
               vnpcomext1,
               vnpcomrep1,
               vncodepto,
               vnclasse,
               vnperacrescismopf,
               vnpiscofinsretido,
               vncustocont,
               vnperdescmaxbalcao,
               vncustoultent,
               vnvalorultent,
               vncodlinhaprod,
               vspsicotropico,
               vnmultiplo,
               vnivafonte,
               vnaliqicms1fonte,
               vnaliqicms2fonte,
               vnperbaserednrpa,
               vnpercbaseredconsumidor,
               vnperdescsuframa,
               vsutilizapercbaseredpf,
               vnperpis,
               vstipomerc,
               vnaliqiss,
               vnpercbaseredst,
               vnpercbaseredstfonte,
               vsexcluido,
               vncoddistrib,
               vncodprodprinc,
               vstipocalculognre,
               vsfreteespecial,
               vsaplicaacrescpjisenta,
               vsaceitavendafracao,
               vncodicmtabpf,
               vncodicmpf,
               vsusavalorultentbasest,
               vstipocomissao,
               vnprecofab,
               --             vddthoje,
               vnprazomediovenda,
               vsestoqueporlote,
               vnaliqicms1transf,
               vnaliqicms2transf,
               vnivatransf,
               vnpautatransf,
               vnpercbaseredsttransf,
               vsconciliaimportacao
          FROM pctabpr, pcprodut, pctribut, pcest, pcfornec
         WHERE pcprodut.codprod = pncodprod
           AND pctabpr.codprod = pcprodut.codprod
           AND pctribut.codst = vncodst
           AND (pcprodut.codfornec = pcfornec.codfornec)
           AND (pcprodut.codprod = pcest.codprod)
           AND (rtrim(ltrim(pcest.codfilial)) = pscodfilial)
           AND (pctabpr.numregiao = pnnumregiao)
           AND ((pcprodut.codfilial = pscodfilial) OR
               (pcprodut.codfilial IS NULL));
      END IF;
      -- Tipo de Preço Usado
      -- 1. uso de preço de oferta
      IF (psutilizavendaporembalagem = 'S') AND (psprecoporembalagem = 'S') THEN
        IF vnpoferta <> 0 AND (vddtofertaini <= trunc(SYSDATE) AND
           vddtofertafim >= trunc(SYSDATE)) THEN
          vnptabela := vnpoferta;
        END IF;
        IF (vnpvendaatac <> 0) AND (vnqtminimaatacado > 0) AND
           (pnqtvendida >= vnqtminimaatacado) THEN
          vnptabela := vnpvendaatac;
        END IF;
      END IF;
      --Descontos sobre Tabela
      -- Frete/Fob
      IF psfretedespacho = 'F' THEN
        vnptabela := vnptabela * (1 - (nvl(vnperdescfob, 0) / 100));
      ELSE
        IF ((psorigemped = 'B') OR (psorigemped = 'R')) AND
           (psabatefretevendabalcao = 'S') THEN
          vnptabela := vnptabela / (1 + (nvl(pnperfrete, 0) / 100));
        END IF;
      END IF;
      vnptabela := round(vnptabela, pnnumcasasdecvenda);
      --**********************************************************************************
      IF psorigemped = 'B' THEN
        vnptabela := vnptabela +
                     (vnptabela * (nvl(pnpercacrescimobalcao, 0) / 100));
      END IF;
      -- 1. Desconto o Acrescimo
      vnptabela   := (vnptabela + (vnptabela * nvl(pnpertxfim, 0) / 100));
      vnporiginal := vnptabela;
      vnporiginal := round(vnporiginal, pnnumcasasdecvenda);
      --Tarefa 21088
      IF (pncondvenda NOT IN (3, 6, 12) OR (psaplicaacrescpftv3 = 'S')) THEN
        --Aplicar %Acresc. PF quando PF tiver Insc. Estadual?
        IF nvl(psacrescimopfcomie, 'N') = 'S' THEN
          IF (((nvl(vsaplicaacrescpjisenta, 'S') = 'S') AND
             ((psieent = 'ISENTA') OR (psieent = 'ISENTO'))) OR
             (pstipofj = 'F')) AND (nvl(pscontribuinte, 'S') = 'N') THEN
            -- 2 - Desconto ou Acrescimo
            vnptabela := (vnptabela +
                         (vnptabela * nvl(vnperacrescismopf, 0) / 100));
          END IF;
        ELSE
          IF (((nvl(vsaplicaacrescpjisenta, 'S') = 'S') AND
             ((psieent = 'ISENTA') OR (psieent = 'ISENTO'))) OR
             ((pstipofj = 'F') AND (TRIM(psieent) = ''))) AND
             (nvl(pscontribuinte, 'S') = 'N') THEN
            -- 2 - Desconto ou Acrescimo
            vnptabela := (vnptabela +
                         (vnptabela * nvl(vnperacrescismopf, 0) / 100));
          END IF;
        END IF;
      END IF;
      -- 3. Desconto ou Acrescimo
      vnptabela           := (vnptabela +
                             (vnptabela * nvl(pnperdescativ, 0) / 100));
      vnpvendabase        := vnptabela;
      vnpermaxdesc        := 0;
      vsmensagemdescquant := NULL;
      --Desconto/Acrescimo por quantidade
      vbvalidodescquant := funcoesvendas.validardescontoquantidade(0,
                                                                   pncodprod,
                                                                   pnqtvendida,
                                                                   pnnumregiao,
                                                                   vnptabela,
                                                                   pncodpraca,
                                                                   pnnumcasasdecvenda,
                                                                   vddtfim,
                                                                   vsmensagemdescquant,
                                                                   vnptabeladescquant);
      IF vbvalidodescquant = TRUE THEN
        vnptabela := vnptabeladescquant;
      ELSE
        IF vsmensagemdescquant IS NOT NULL THEN
          vsmensagem := vsmensagem || ' ' || vsmensagemdescquant;
        END IF;
      END IF;
      vnpbaserca := vnptabela;
      -- escolha do maior desconto - comparacao com desconto da tabela de preços
      IF vnperdescmax > vnpermaxdesc THEN
        vnpermaxdesc := vnperdescmax;
      END IF;
      -- escolha do maior desconto - comparacao com desconto do cliente
      IF nvl(pnperdesccli, 0) > vnpermaxdesc THEN
        vnpermaxdesc := nvl(pnperdesccli, 0);
      END IF;
      IF funcoesvendas.validarrestricaovenda(pncodprod,
                                             pnnumregiao,
                                             pncodcli,
                                             pncodusur,
                                             vncodfornec,
                                             pncodpraca,
                                             vnclasseproduto,
                                             vncodativ,
                                             vsmensagem_rest) = FALSE THEN
        vsmensagem := vsmensagem || ' ' || vsmensagem_rest;
        vbvalido   := FALSE;
      END IF;
      vsmensagem_politica := NULL;
      IF pbusapoliticadescontos = TRUE THEN
        --Validar Política de Descontos
        IF validarpoliticasdesconto(pncodprod,
                                    pddata,
                                    pscodfilial,
                                    pnnumregiao,
                                    pncodcli,
                                    pncodusur,
                                    psorigemped,
                                    vncodprodprinc,
                                    pnnumcasasdecvenda,
                                    pncodplpag,
                                    pstratarrestricaoacrescimo,
                                    psclassevenda,
                                    0, -- Parâmetro para desconto Automático
                                    vddtfimdesconto,
                                    vsmensagem_politica,
                                    vnperdesc_politica,
                                    vsbasecreddebrca,
                                    vnperdesc_restricao) THEN
          vnppolitica := (round(vnptabela, pnnumcasasdecvenda)) *
                         (1 - (vnperdesc_politica / 100));
          vnppolitica := round(vnppolitica, pnnumcasasdecvenda);
          IF nvl(vsbasecreddebrca, 'N') = 'S' THEN
            vnpbaserca := vnppolitica;
          END IF;
          IF vnperdesc_politica > vnpermaxdesc THEN
            vnpermaxdesc := vnperdesc_politica;
          END IF;
        END IF;
        IF TRIM(vsmensagem_politica) IS NOT NULL THEN
          vsmensagem := vsmensagem || ' ' || vsmensagem_politica;
        END IF;
      END IF;
      vbcesta := FALSE;
      IF (vstipomerc = 'CB')
      --and ( frmPED_CLI.vbUsaCestaBasica)
       THEN
        buscarprecocestabasica(pnnumped,
                               pncodprod,
                               pnnumregiao,
                               pnnumpr,
                               vbcesta,
                               vnprecocesta,
                               vsmensagemcesta);
        IF vbcesta = TRUE THEN
          vnporiginal  := vnprecocesta;
          vnptabela    := vnprecocesta;
          vnpbaserca   := vnprecocesta;
          vnpvendabase := vnprecocesta;
          vnpvenda     := vnprecocesta;
        END IF;
      END IF;
      IF TRIM(vsmensagemcesta) IS NOT NULL THEN
        vsmensagem := vsmensagem || ' ' || vsmensagemcesta;
      END IF;
      IF pbusaprecofixo = TRUE THEN
        --  {Validar políticas de Preço Fixo}
        IF validarpoliticaprecofixo(pncodprod,
                                    pddata,
                                    pnnumregiao,
                                    pncodcli,
                                    pncondvenda,
                                    pncodplpag,
                                    vnptabela,
                                    psvalidapvendabonific,
                                    psutilizapercfinprecoprom,
                                    pnpertxfim,
                                    pnnumdias,
                                    pncodcliprinc,
                                    vncodprodprinc,
                                    pncodpraca,
                                    pncodusur,
                                    pncodsupervisor,
                                    psnumlote,
                                    vddtfimpromocao,
                                    vsmensagem_precofixo,
                                    vnprecofixo) THEN
          vnptabela    := vnprecofixo;
          vnpvenda     := vnprecofixo;
          vbprecofixo  := TRUE;
          vnpbaserca   := vnprecofixo;
          vnpermaxdesc := 0;
        ELSE
          IF TRIM(vsmensagem_precofixo) IS NOT NULL THEN
            vsmensagem := vsmensagem || ' ' || vsmensagem_precofixo;
          END IF;
        END IF;
      END IF;
      IF (nvl(psusartributacaotransftv10, 'N') = 'S') AND
         (pncondvenda = 10) THEN
        vniva           := vnivatransf;
        vnpauta         := vnpautatransf;
        vnaliqicms1     := vnaliqicms1transf;
        vnaliqicms2     := vnaliqicms2transf;
        vnpercbaseredst := vnpercbaseredsttransf;
      END IF;
      IF pncondvenda = 10 THEN
        --Se TIPOCUSTOTRANSF.AsString = 'P' ->  usa preço de venda
        --Custo Reposição - > default
        IF pstipocustotransf = 'E' THEN
          vnptabela := vncustorep;
        ELSIF pstipocustotransf = 'R' THEN
          vnptabela := vncustoreal;
        ELSIF pstipocustotransf = 'C' THEN
          vnptabela := vncustocont;
        ELSIF pstipocustotransf = 'F' THEN
          vnptabela := vncustofin;
        ELSIF pstipocustotransf = 'U' THEN
          vnptabela := vncustoultent;
        ELSIF pstipocustotransf = 'V' THEN
          vnptabela := vnvalorultent;
        ELSIF pstipocustotransf = 'S' THEN
          vnptabela := vncustorealsemst;
        END IF;
      END IF;
      vnptabela := round(vnptabela, pnnumcasasdecvenda);
      -- calculo preco minimo
      vnpvendamin := (round(vnptabela, pnnumcasasdecvenda)) *
                     (1 - (vnpermaxdesc / 100));
      vnpvendamin := round(vnpvendamin, pnnumcasasdecvenda);
      IF nvl(pstratarrestricaoacrescimo, 'N') = 'S' THEN
        vnpermaxvenda := nvl(pnpermaxvenda, 100);
        IF nvl(vnpercdescpolitica_acres, 100) > vnpermaxvenda THEN
          vnpermaxvenda := vnpercdescpolitica_acres;
        END IF;
      ELSE
        vnpermaxvenda := nvl(pnpermaxvenda, 100);
      END IF;
      -- calculo preco maximo
      vnpvendamax   := (round(vnptabela, pnnumcasasdecvenda)) *
                       (1 + vnpermaxvenda / 100);
      vnpvendamax   := round(vnpvendamax, pnnumcasasdecvenda);
      pnpvendamax   := nvl(vnpvendamax, 0);
      vnptabela_ant := vnptabela;
      pnpvendamin   := vnpvendamin;
      IF nvl(vnpvenda, 0) <> 0 THEN
        -- verifica desconto permitido
        IF vnpvenda < vnpvendamin THEN
          -- verifica autorizacao de venda
          SELECT COUNT(*)
            INTO vicontador
            FROM pcautori
           WHERE codcli = pncodcli
             AND codusur = pncodusur
             AND codplpag = pncodplpag
             AND codprod = pncodprod
             AND statusutiliz = 'N';
          IF vicontador > 0 THEN
            BEGIN
              SELECT pcautori.nrautorizacao,
                     nvl(pcautori.percdescautor, 0),
                     pcautori.pvendaatual,
                     pcautori.basecreddebrca
                INTO vnnrautorizacao,
                     vnpercdescautor,
                     vnpvendaatual,
                     vsbasecreddebrca_autori
                FROM pcautori
               WHERE codcli = pncodcli
                 AND codusur = pncodusur
                 AND codplpag = pncodplpag
                 AND codprod = pncodprod
                 AND statusutiliz = 'N'
                 AND rownum = 1
            ORDER BY percdescautor desc, fimintervalo desc
                 FOR UPDATE;
              vnpvenda_autori := nvl(vnpvendaatual, vnptabela_ant) *
                                 (1 - (vnpercdescautor / 100));
              vnpvenda_autori := round(vnpvenda_autori, pnnumcasasdecvenda);
              IF vnpvenda_autori <= vnpvenda THEN
                IF vsbasecreddebrca_autori = 'S' THEN
                  vnpbaserca := vnpvenda;
                ELSIF vsbasecreddebrca_autori = 'A' THEN
                  vnpbaserca := vnpvenda_autori;
                END IF;
                UPDATE pcautori
                   SET data_utilizacao = trunc(SYSDATE),
                       codfuncutiliz   = pncodfunc,
                       statusutiliz    = 'S',
                       numped          = pnnumped,
                       pvendido        = vnpvenda
                 WHERE nrautorizacao = vnnrautorizacao;
              ELSE
                vsmensagem  := vsmensagem || ' Desconto acima do permitido' ||
                               ' Preco de Venda: ' || vnpvenda;
                vsmensagem  := vsmensagem || ' Preco Tabela  : ' ||
                               round(nvl(vnpvendaatual, vnptabela),
                                     pnnumcasasdecvenda);
                vsmensagem  := vsmensagem || ' Desconto(%)   : ' ||
                               vnpercdescautor;
                vsmensagem  := vsmensagem || ' Preco Minimo  : ' ||
                               vnpvenda_autori;
                pnpvendamin := vnpvenda_autori;
                vbvalido    := FALSE;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                vsmensagem  := vsmensagem || ' Desconto acima do permitido';
                vsmensagem  := vsmensagem || ' Preco de Venda: ' ||
                               vnpvenda;
                vsmensagem  := vsmensagem || ' Preco Tabela  : ' ||
                               round(nvl(vnpvendaatual, vnptabela),
                                     pnnumcasasdecvenda);
                vsmensagem  := vsmensagem || ' Desconto(%)   : ' ||
                               vnpercdescautor;
                vsmensagem  := vsmensagem || ' Preco Minimo  : ' ||
                               vnpvenda_autori;
                pnpvendamin := vnpvenda_autori;
                vbvalido    := FALSE;
            END;
          ELSE
            vsmensagem  := vsmensagem || ' Desconto acima do permitido';
            vsmensagem  := vsmensagem || ' Preco de Venda: ' || vnpvenda;
            vsmensagem  := vsmensagem || ' Preco Tabela  : ' ||
                           round(vnptabela, pnnumcasasdecvenda);
            vsmensagem  := vsmensagem || ' Desconto(%)   : ' ||
                           vnpermaxdesc;
            vsmensagem  := vsmensagem || ' Preco Minimo  : ' || vnpvendamin;
            pnpvendamin := vnpvendamin;
            vbvalido    := FALSE;
          END IF;
        END IF;
      END IF;
      SELECT decode(nvl(pnpvenda, 0), 0, vnptabela, vnpvenda)
        INTO vnpreco
        FROM dual;
      -- 36 parametros
      IF NOT calcularimpostos(vnpreco,
                              vnptabela,
                              vnpbaserca,
                              vnvlipi,
                              pnpercipi,
                              nvl(vnpercipivenda, 0),
                              pnpercvenda,
                              pstipocalcst,
                              pscalcstpf,
                              psmostrarpvendasemst,
                              psconsideraisentoscomopf,
                              pscalculast,
                              psieent,
                              pstipofj,
                              vnpauta,
                              vniva,
                              vnaliqicms1,
                              vnaliqicms2,
                              vnpercbaseredst,
                              pnnumcasasdecvenda,
                              1,
                              vsuffilial,
                              psestent,
                              nvl(vsusavalorultentbasest, 'N'),
                              vnvalorultent,
                              psisentoipi,
                              pssulframa,
                              pscalcularstcomipi,
                              pstipocalcipi,
                              pscodfilialnf,
                              pncondvenda,
                              pscontribuinte,
                              psfilialnfuf,
                              vsmensagem_st,
                              vnst,
                              vnbaseicst) THEN
        IF TRIM(vsmensagem_st) IS NOT NULL THEN
          vsmensagem := vsmensagem ||
                        'Não foi possível realizar o cálculo do ST. ' ||
                        vsmensagem_st;
          vbvalido   := FALSE;
        END IF;
      ELSE
        IF nvl(pnpvenda, 0) = 0 THEN
          vnptabela := vnpreco;
        ELSE
          vnpvenda := vnpreco;
        END IF;
      END IF;
    END IF;
    IF vbvalido = TRUE THEN
      --Tarefa 18723: Se o tipo do cálculo de GNRE for por cliente
      --O st deverá ser retirado do preço e zerado
      --Tarefa 18727: O preço já virá sem st
      vnstclientegnre := 0;
      IF vstipocalculognre = 'C' THEN
        vnst       := 0;
        vsuffilial := psfilialuf;
        IF pscodfilialnf IS NOT NULL THEN
          vsuffilial := psfilialnfuf;
        END IF;
        SELECT decode(nvl(pnpvenda, 0), 0, vnptabela, vnpvenda)
          INTO vnpreco
          FROM dual;
        IF calcularst(vnpreco,
                      vnvlipi,
                      pnpercvenda,
                      pstipocalcst,
                      pscalcstpf,
                      psmostrarpvendasemst,
                      psconsideraisentoscomopf,
                      pscalculast,
                      psieent,
                      pstipofj,
                      vnpauta,
                      vniva,
                      vnaliqicms1,
                      vnaliqicms2,
                      vnpercbaseredst,
                      pnnumcasasdecvenda,
                      1,
                      vsuffilial,
                      psestent,
                      vsusavalorultentbasest,
                      vnvalorultent,
                      pscontribuinte,
                      vsmensagem_st,
                      vnst,
                      vnbaseicst) THEN
          IF TRIM(vsmensagem_st) IS NOT NULL THEN
            vsmensagem := vsmensagem ||
                          'Não foi possível realizar o cálculo do ST. ' ||
                          vsmensagem_st;
          END IF;
          vnstclientegnre := vnst;
        END IF;
      END IF;
      pnbaseicst := vnbaseicst;
      --Tarefa 15398: Calcular ST Fonte
      vnstfonte := 0;
      SELECT decode(nvl(pnpvenda, 0), 0, vnptabela, vnpvenda)
        INTO vnpreco
        FROM dual;
      -- 31 parametros
      vnstfonte := calcularstfonte(pncodprod,
                                   pncondvenda,
                                   pnpercvenda,
                                   vniva,
                                   vnivafonte,
                                   vnaliqicms1fonte,
                                   vnaliqicms2fonte,
                                   vnpercbaseredstfonte,
                                   vnperbaserednrpa,
                                   vnpercbaseredconsumidor,
                                   vsutilizapercbaseredpf,
                                   pstipocalcst,
                                   pscalcstpf,
                                   psutilizapercbaseredpf,
                                   psclientefontest,
                                   pscalculast,
                                   psieent,
                                   pstipofj,
                                   psisentoicms,
                                   psconsumidorfinal,
                                   psutilizaiesimplificada,
                                   pstipoempresa,
                                   psconsideraisentoscomopf,
                                   (vnpreco - vnvlipi - vnst),
                                   vnvlipi,
                                   vsuffilial,
                                   psestent,
                                   vsusavalorultentbasest,
                                   vnvalorultent,
                                   vnbaseicst,
                                   vsmensagem_stfonte);
      IF vsmensagem_stfonte IS NOT NULL THEN
        vsmensagem := vsmensagem ||
                      'Não foi possível realizar o cálculo do STFONTE. ' ||
                      vsmensagem_stfonte;
      END IF;
      --Acresc. ST Fonte ao Preço
      IF (vnst = 0) AND (vnstfonte <> 0) THEN
        vnst       := vnstfonte;
        vnptabela  := round(vnptabela + vnstfonte, pnnumcasasdecvenda);
        vnpbaserca := round(vnpbaserca + vnstfonte, pnnumcasasdecvenda);
        IF nvl(pnpvenda, 0) <> 0 THEN
          vnpvenda := round(vnpvenda + vnstfonte, pnnumcasasdecvenda);
        END IF;
        vniva                := vnivafonte;
        vnpauta              := 0;
        vnaliqicms1          := vnaliqicms1fonte;
        vnaliqicms2          := vnaliqicms2fonte;
        pnpercbaseredst      := vnpercbaseredst;
        pnpercbaseredstfonte := vnpercbaseredstfonte;
      END IF;
      --Suframa
      --Cálculo do %Desc. Suframa
      vnvldescsuframa := 0;
      IF TRIM(pssulframa) IS NOT NULL THEN
        SELECT decode(nvl(pnpvenda, 0), 0, vnptabela, vnpvenda)
          INTO vnpreco
          FROM dual;
        vnvldescsuframa := ((vnpreco - vnst - vnvlipi) *
                           (pnpercvenda / 100)) *
                           (nvl(vnperdescsuframa, 0) / 100);
        IF pstipocalcsulframa = 'T2' THEN
          --Calcular ST - Truncar com 2 casas decimais
          vnvldescsuframa := trunc((vnvldescsuframa) * 100) / 100;
        ELSIF pstipocalcsulframa = 'A2' THEN
          --Calcular ST - Arredondar com 2 casas decimais
          vnvldescsuframa := round((vnvldescsuframa) * 100) / 100;
        ELSIF pstipocalcsulframa = 'PV' THEN
          --Calcular ST - Conf. Casas Dec. Venda
          vnvldescsuframa := round(vnvldescsuframa, pnnumcasasdecvenda);
        END IF;
        vnptabela := vnptabela - vnvldescsuframa;
        IF nvl(pnpvenda, 0) <> 0 THEN
          vnpvenda := vnpvenda - vnvldescsuframa;
        END IF;
      END IF;
      -- ISS
      --Cálculo do Vl. ISS (imposto sobre serviços)
      vnperciss := 0;
      vnvliss   := 0;
      IF vstipomerc = 'SS' THEN
        vnperciss := vnaliqiss;
        vnbciss   := (nvl(vnpvenda, vnptabela) - vnst - vnvlipi);
        vnvliss   := vnbciss - (vnbciss / (1 + (vnaliqiss / 100)));
      END IF;
      IF nvl(pnpvenda, 0) <> 0 THEN
        vnperdesc := (((vnptabela - vnpvenda) / vnptabela) * 100);
        SELECT decode(nvl(pnpvenda, 0), 0, vnptabela, vnpvenda)
          INTO vnpreco
          FROM dual;
        -- CMV sem comissao
        calcularcmv(psabaterimpostoscomissaorca,
                    psaplicarindicecmv,
                    pntxvenda,
                    pstipofj,
                    psutilizaiesimplificada,
                    psieent,
                    vsfreteespecial,
                    pnperfreteterceiros,
                    pnperfreteespecial,
                    vncustofin,
                    vncustoreal,
                    vnperdesccusto,
                    vncodicmtab,
                    vbcodicmtabpf,
                    vncodicmtabpf,
                    pnpercvenda,
                    vnpreco,
                    0,
                    vnst,
                    vnvlipi,
                    vnvliss,
                    pscontribuinte,
                    vnperfretecmv,
                    vncustofinest,
                    vntxvenda_item,
                    vnperdesccusto_item,
                    vncodicmtab_item,
                    vnvlcustoreal,
                    vnvlcustofin,
                    vnvldesccustocmv
                    );
        vnperluc := (vnpreco - vnvlcustofin) / vnpreco;
        --comissão
        vnpercom := buscapercomissao(pstipovend,
                                     vnpcomint1,
                                     vnpcomext1,
                                     vnpcomrep1,
                                     psusacomissaoporcliente,
                                     pnpercomcli,
                                     psusacomissaoporrca,
                                     pscomissaorcatipovenda,
                                     pstipovenda,
                                     pnpercent,
                                     pnpercent2,
                                     psusacomissaoporlinhaprod,
                                     pncodplpag,
                                     vncodlinhaprod,
                                     vnperdesc,
                                     pncodusur,
                                     pnnumregiao,
                                     vncodsec,
                                     vncodepto,
                                     pncodprod,
                                     vnperluc,
                                     pnordemavaliacaocomissaorca,
                                     pnletracomiss,
                                     vsmensagem_comis);
        pnpercom := vnpercom;
        IF TRIM(vsmensagem_comis) IS NOT NULL THEN
          vsmensagem := vsmensagem || ' ' || vsmensagem_comis;
        END IF;
      END IF;
      IF vncodicmtabpf IS NULL THEN
        vbcodicmtabpf := TRUE;
      ELSE
        vbcodicmtabpf := FALSE;
      END IF;
      -- CMV
      calcularcmv(psabaterimpostoscomissaorca,
                  psaplicarindicecmv,
                  pntxvenda,
                  pstipofj,
                  psutilizaiesimplificada,
                  psieent,
                  vsfreteespecial,
                  pnperfreteterceiros,
                  pnperfreteespecial,
                  vncustofin,
                  vncustoreal,
                  vnperdesccusto,
                  vncodicmtab,
                  vbcodicmtabpf,
                  vncodicmtabpf,
                  pnpercvenda,
                  nvl(vnpvenda, vnptabela),
                  vnpercom,
                  vnst,
                  vnvlipi,
                  vnvliss,
                  pscontribuinte,
                  pnperfretecmv,
                  pncustofinest,
                  pntxvenda_item,
                  pnperdesccusto_item,
                  pncodicmtab_item,
                  pnvlcustoreal,
                  pnvlcustofin,
                  pnvldesccustocmv);
      vnptabela := round(vnptabela, pnnumcasasdecvenda);
    END IF;
    IF vnptabela <= 0 THEN
      vsmensagem := vsmensagem || ' Produto sem preço de tabela.';
      vbvalido   := FALSE;
    END IF;
    pnptabela            := vnptabela;
    psmensagem           := vsmensagem;
    pnporiginal          := vnporiginal;
    pnpvendabase         := vnpvendabase;
    pnpbaserca           := vnpbaserca;
    pniva                := vniva;
    pnpauta              := vnpauta;
    pnaliqicms1          := vnaliqicms1;
    pnaliqicms2          := vnaliqicms2;
    pnpercbaseredst      := vnpercbaseredst;
    pnst                 := vnst;
    pnpercipi            := vnpercipivenda;
    pnvlipi              := vnvlipi;
    pnbaseicst           := vnbaseicst;
    pnpercbaseredst      := vnpercbaseredst;
    pnpercbaseredstfonte := vnpercbaseredstfonte;
    pnvldescsuframa      := vnvldescsuframa;
    pnvliss              := vnvliss;
    pnperciss            := vnperciss;
    pnpercom             := vnpercom;
    pnperdesc            := nvl(vnperdesc, 0);
    pncodst              := vncodst;
    pnstclientegnre      := vnstclientegnre;
    IF nvl(pnpvenda, 0) <> 0 THEN
      pnpvenda := round(vnpvenda, pnnumcasasdecvenda);
    END IF;
    RETURN vbvalido;
  END buscardadosprodutos;

  FUNCTION calcularimpostos --35 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult      BOOLEAN;
    vnpbaserca    NUMBER;

  BEGIN
    vbresult := FALSE;
    vnpbaserca := 0;

    vbresult := calcularimpostos(p_pvenda,
                                 p_ptabela,
                                 vnpbaserca, --p_pbaserca
                                 p_vlipi,
                                 p_percipi,
                                 p_percipivenda,
                                 p_percvenda,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_mostrarpvendasemst,
                                 p_consideraisentoscomopf,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_pauta,
                                 p_iva,
                                 p_aliqicms1,
                                 p_aliqicms2,
                                 p_percbaseredst,
                                 p_numcasasdecvenda,
                                 p_tipocalculo,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 p_valorultent,
                                 p_isentoipi,
                                 p_suframa,
                                 p_calcularstcomipi,
                                 p_tipocalcipi,
                                 p_filialnf,
                                 p_condvenda,
                                 p_contribuinte,
                                 p_uffilialnf,
                                 p_mensagem,
                                 p_st,
                                 p_baseicst
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularimpostos;

  FUNCTION calcularstfonte --31 parametros
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN NUMBER,
   p_aliqicms1fonte            IN NUMBER,
   p_aliqicms2fonte            IN NUMBER,
   p_percbasered               IN NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_uffilial                  IN VARCHAR2,
   p_estent                    IN VARCHAR2,
   p_usavalorultentbasest      IN VARCHAR2,
   p_valorultent               IN NUMBER,
   p_baseicst                  OUT NUMBER,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER IS

    vnivafonte       NUMBER;
    vnaliqicms1fonte NUMBER;
    vnaliqicms2fonte NUMBER;
    vnpercbasered    NUMBER;

    vnbcst        NUMBER;
    vnstfonte     NUMBER;

  BEGIN

    vnbcst    := 0;
    vnstfonte := 0;
    vnivafonte := p_ivafonte;
    vnaliqicms1fonte := p_aliqicms1fonte;
    vnaliqicms2fonte := p_aliqicms2fonte;
    vnpercbasered := p_percbasered;

    vnstfonte := calcularstfonte(p_codprod,
                                 p_condvenda,
                                 p_percvenda,
                                 p_iva,
                                 vnivafonte,
                                 vnaliqicms1fonte,
                                 vnaliqicms2fonte,
                                 vnpercbasered,
                                 p_percbaserednrpa,
                                 p_percbaseredconsumidor,
                                 p_utilizapercbaseredpf_trib,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_utilizapercbaseredpf,
                                 p_clientefontest,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_isentoicms,
                                 p_consumidorfinal,
                                 p_utilizaiesimplificada,
                                 p_tipoempresa,
                                 p_consideraisentoscomopf,
                                 p_pvenda,
                                 p_vlipi,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 p_valorultent,
                                 --------------------------
                                 --Os parâmetros abaixo serão preenchidos com valores padrôes
                                 --NÃO ALTERAR!!!
                                 'N', --p_usaivafontediferenciado
                                 0,   --p_ivafonte_cli
                                 --------------------------
                                 vnbcst,
                                 p_mensagem
                                 );

    RETURN nvl(vnstfonte,0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST Fonte (31Params): ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END calcularstfonte;

  -- Sabrina em 27/01/2008
  FUNCTION calcularstfonte --33 parametros
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN OUT NUMBER,
   p_aliqicms1fonte            IN OUT NUMBER,
   p_aliqicms2fonte            IN OUT NUMBER,
   p_percbaseredstfonte        IN OUT NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_uffilial                  IN VARCHAR2,
   p_estent                    IN VARCHAR2,
   p_usavalorultentbasest      IN VARCHAR2,
   p_valorultent               IN NUMBER,
   p_usaivafontediferenciado   IN VARCHAR2,
   p_ivafonte_cli              IN NUMBER,
   p_baseicst                  IN OUT NUMBER,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER IS

    vnbcst        NUMBER;
    vnstfonte     NUMBER;

  BEGIN
    vnbcst    := 0;
    vnstfonte := 0;

    vnstfonte := calcularstfonte(p_codprod,
                                 p_condvenda,
                                 p_percvenda,
                                 p_iva,
                                 p_ivafonte,
                                 p_aliqicms1fonte,
                                 p_aliqicms2fonte,
                                 p_percbaseredstfonte,
                                 p_percbaserednrpa,
                                 p_percbaseredconsumidor,
                                 p_utilizapercbaseredpf_trib,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_utilizapercbaseredpf,
                                 p_clientefontest,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_isentoicms,
                                 p_consumidorfinal,
                                 p_utilizaiesimplificada,
                                 p_tipoempresa,
                                 p_consideraisentoscomopf,
                                 p_pvenda,
                                 p_vlipi,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 p_valorultent,
                                 p_usaivafontediferenciado,
                                 p_ivafonte_cli,
                                 -----------------------------
                                 FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ACEITAPFCONTRIBUINTE','99','N'), --p_AceitaPFContribuinte,
                                 0, --p_ALIQICMS1, EM DESUSO!
                                 0, --p_ALIQICMS2, EM DESUSO!
                                 'N', --p_contribuinte, VALOR DEFAULT NO DICIONARIO DE DADOS PARA NOVOS CADASTROS DE CLIENTES.
                                 FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA','99',6), --p_numcasasdecvenda,
                                 -----------------------------
                                 vnbcst,
                                 p_mensagem,
                                 0, --P_CUSTONFSEMST
                                 'N', --p_usavalorultentbasest2
                                 'N', --p_usapmcbasest
                                 0, --p_precomaxconsum
                                 'N', --p_importado
                                 0, --p_percbasestrj
                                 'N' --p_AGREGARIPICALCULOST
                                );

    p_baseicst := vnbcst;

    RETURN NVL(vnstfonte,0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST Fonte(33Params): ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END calcularstfonte;

  /* Esta funcao tem um parâmetro a mais ( p_pvenda1) que será utilizado para validar o campo
  pcdescquant.perdescmax */
  FUNCTION validardescontoquantidade -- 12 parametros
  (p_tipoteste        IN NUMBER,
   p_codprod          IN NUMBER,
   p_qtde             IN NUMBER,
   p_numregiao        IN NUMBER,
   p_ptabela          IN NUMBER,
   p_pvenda1          IN NUMBER,
   p_codpraca         IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_numdias          IN NUMBER,
   p_dtfim            OUT DATE,
   p_mensagem         OUT VARCHAR2,
   p_ptabeladesc      OUT NUMBER) RETURN BOOLEAN IS

    vbresult              BOOLEAN;
    vscreditasobreptabela VARCHAR2(1);
    vnperdescflex         NUMBER;
  BEGIN

    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_numdias,
                                          NULL, --p_tipodesconto,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc,
                                          vscreditasobreptabela,
                                          vnperdescflex);

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;
  END validardescontoquantidade;

  FUNCTION validarpoliticaprecofixo -- 20 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_numlote                 IN VARCHAR2,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN

    vbresult := validarpoliticaprecofixo(--21 parametros
                                         p_codprod,
                                         p_data,
                                         p_numregiao,
                                         p_codcli,
                                         p_condvenda,
                                         p_codplpag,
                                         p_ptabela,
                                         p_validapvendabonific,
                                         p_utilizapercfinprecoprom,
                                         p_pertxfim,
                                         p_numdias,
                                         p_codcliprinc,
                                         p_codprodprinc,
                                         p_codpraca,
                                         p_codusur,
                                         p_codsupervisor,
                                         p_numlote,
                                         'O', --p_origemped,
                                         p_dtfim,
                                         p_mensagem,
                                         p_precofixo
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Preco Fixo ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticaprecofixo;

  FUNCTION calcularpercverbacmv -- 8 parametros
  (p_codprod          IN NUMBER,
   p_codsec           IN NUMBER,
   p_codepto          IN NUMBER,
   p_data             IN DATE,
   p_codcli           IN NUMBER,
   p_numcasasdecvenda IN NUMBER,
   p_mensagem         OUT VARCHAR2,
   p_percverba        OUT NUMBER,
   p_codrede          IN NUMBER DEFAULT 0
   ) RETURN BOOLEAN IS

    vbresult    BOOLEAN;
    vnpercverba NUMBER;
    vicont      NUMBER;
    vsalteracontacorrente varchar2(1);

  BEGIN
    vbresult    := FALSE;
    vnpercverba := 0;
    vsalteracontacorrente := 'N';

    SELECT COUNT(*)
      INTO vicont
      FROM pcpoliticaverbacmv
     WHERE p_data BETWEEN dtinicio AND dtfim
       AND ((codepto = p_codepto) OR (codepto IS NULL))
       AND ((codsec = p_codsec) OR (codsec IS NULL))
       AND ((codprod = p_codprod) OR (codprod IS NULL))
       AND ((codcli = p_codcli) OR (codcli IS NULL) OR (codcli = 0))
       and ((codrede = p_codrede) OR (codrede IS null));

    IF vicont > 0 THEN

      vbresult := TRUE;

     begin
      SELECT MAX(percverbacmv)
        INTO vnpercverba
        FROM pcpoliticaverbacmv
       WHERE p_data BETWEEN dtinicio AND dtfim
         AND ((codepto = p_codepto) OR (codepto IS NULL))
         AND ((codsec = p_codsec) OR (codsec IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codcli = p_codcli) OR (codcli IS NULL) OR (codcli = 0) )
         and ((codrede = p_codrede) OR (codrede IS null));
       exception when others then

         vnpercverba := 0;

       end;

       select pcpoliticaverbacmv.alteracontacorrente
        INTO vsalteracontacorrente
        FROM pcpoliticaverbacmv
       WHERE p_data BETWEEN dtinicio AND dtfim
         AND ((codepto = p_codepto) OR (codepto IS NULL))
         AND ((codsec = p_codsec) OR (codsec IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codcli = p_codcli) OR (codcli IS NULL) OR (codcli = 0) )
         and ((codrede = p_codrede) OR (codrede IS null))
         and  percverbacmv = vnpercverba;

    END IF;
    p_percverba := round(vnpercverba, p_numcasasdecvenda);
    p_mensagem := vsalteracontacorrente;

    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Calcula verba CMV para cliente: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularpercverbacmv;

  /* Esta funcao tem um parâmetro a mais ( p_pvenda1) que será utilizado para validar o campo
  pcdescquant.perdescmax */
  FUNCTION validardescontoquantidade -- 15 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_dtfim               OUT DATE,
   p_mensagem            OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER) RETURN BOOLEAN IS
    vbresult              BOOLEAN;
    vnpercdesc            NUMBER;
    vnperdescmax          NUMBER;
    vnptabela             NUMBER;
    vicont                NUMBER;
    vnptabela_quantmax    NUMBER;
    vnptabela_quant       NUMBER;
    vscreditasobreptabela VARCHAR2(1);
    vddtinicio            DATE;
    vniniciointervalo     NUMBER;
    vnfimintervalo        NUMBER;

  BEGIN

    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_numdias,
                                          p_tipodesconto,
                                          NULL, --p_codprodprinc,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc,
                                          p_creditasobreptabela,
                                          p_perdescflex);

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;
  END validardescontoquantidade;

  FUNCTION validarpoliticasdesconto -- 19 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER) RETURN BOOLEAN IS

    vbresult         BOOLEAN;
    vnpbaserca       NUMBER;

  BEGIN

    vbresult := validarpoliticasdesconto(--20 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         vnpbaserca
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  PROCEDURE calcularcmv -- 34 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE,
   p_codst                       IN NUMBER DEFAULT 0) IS
    vnbasecalccomissao NUMBER := 0;
  BEGIN

    calcularcmv(p_abaterimpostoscomissaorca,
                p_aplicarindicecmv,
                p_incluircomissaosugpvendacmv,
                p_txvenda,
                p_tipofj,
                p_utilizaiesimplificada,
                p_ieent,
                p_freteespecial,
                p_perfreteterceiros,
                p_perfreteespecial,
                p_custofin,
                p_custoreal,
                p_perdesccusto,
                p_codicmtab,
                p_codicmtabpf_enulo,
                p_codicmtabpf,
                p_percvenda,
                p_pvenda,
                p_percom,
                p_st,
                p_vlipi,
                p_vliss,
                p_contribuinte,
                -------------------------------------
                --O parâmetro abaixo usa como default 0(zero)
                0, --p_vldifaliquotas,
                -------------------------------------
                p_perfretecmv,
                p_custofinest,
                p_txvenda_item,
                p_perdesccusto_item,
                p_codicmtab_item,
                p_vlcustoreal,
                p_vlcustofin,
                p_vldesccustocmv);

  END calcularcmv;

  FUNCTION validarautorizacaovenda -- 16 parametros
  (p_numped                   IN pcpedc.numped%TYPE,
   p_codcli                   IN pcpedc.codcli%TYPE,
   p_codusur                  IN pcpedc.codusur%TYPE,
   p_codplpag                 IN pcpedc.codplpag%TYPE,
   p_codfunc                  IN pcpedc.codemitente%TYPE,
   p_codprod                  IN pcpedi.codprod%TYPE,
   p_ptabelaant               IN pcpedi.ptabela%TYPE,
   p_ptabela                  IN pcpedi.ptabela%TYPE,
   p_pvenda                   IN pcpedi.pvenda%TYPE,
   p_codauxiliar              IN pcpedi.codauxiliar%TYPE,
   p_permaxdesc               IN NUMBER,
   p_numcasasdecvenda         IN pcconsum.numcasasdecvenda%TYPE,
   p_utilizavendaporembalagem IN pcconsum.utilizavendaporembalagem%TYPE,
   p_pbaserca                 IN OUT pcpedi.pbaserca%TYPE,
   p_pvendamin                IN OUT pcpedi.pvenda%TYPE,
   p_mensagem                 OUT VARCHAR2) RETURN BOOLEAN IS

   vbvalido boolean;
   vnPercom pcautori.percom%TYPE;
  BEGIN
       vbvalido :=  validarautorizacaovenda
          (p_numped,
           p_codcli,
           p_codusur,
           p_codplpag,
           p_codfunc,
           p_codprod,
           p_ptabelaant,
           p_ptabela,
           p_pvenda,
           p_codauxiliar,
           p_permaxdesc,
           p_numcasasdecvenda,
           p_utilizavendaporembalagem,
           p_pbaserca,
           p_pvendamin,
           vnPercom,
           p_mensagem);

      RETURN vbvalido;
  END;


  FUNCTION validarautorizacaovenda -- 17 parametros
  (p_numped                   IN pcpedc.numped%TYPE,
   p_codcli                   IN pcpedc.codcli%TYPE,
   p_codusur                  IN pcpedc.codusur%TYPE,
   p_codplpag                 IN pcpedc.codplpag%TYPE,
   p_codfunc                  IN pcpedc.codemitente%TYPE,
   p_codprod                  IN pcpedi.codprod%TYPE,
   p_ptabelaant               IN pcpedi.ptabela%TYPE,
   p_ptabela                  IN pcpedi.ptabela%TYPE,
   p_pvenda                   IN pcpedi.pvenda%TYPE,
   p_codauxiliar              IN pcpedi.codauxiliar%TYPE,
   p_permaxdesc               IN NUMBER,
   p_numcasasdecvenda         IN pcconsum.numcasasdecvenda%TYPE,
   p_utilizavendaporembalagem IN pcconsum.utilizavendaporembalagem%TYPE,
   p_pbaserca                 IN OUT pcpedi.pbaserca%TYPE,
   p_pvendamin                IN OUT pcpedi.pvenda%TYPE,
   p_percomAutorizacao        IN OUT pcautori.percom%TYPE,
   p_mensagem                 OUT VARCHAR2) RETURN BOOLEAN IS
    vicontador              NUMBER;
    vnpvenda_autori         pcpedi.pvenda%TYPE;
    vnpvendaatual           pcautori.pvendaatual%TYPE;
    vnpercdescautor         pcautori.percdescautor%TYPE;
    vsbasecreddebrca_autori pcautori.basecreddebrca%TYPE;
    vnnrautorizacao         pcautori.nrautorizacao%TYPE;
    vnpercomAutorizacao     pcautori.percom%TYPE;
    vsmensagem              VARCHAR2(1000);
    vbvalido                BOOLEAN;
    vnFatorPrecoMinimo      NUMBER;

  BEGIN
    vicontador := 0;
    vbvalido   := TRUE;
    vsmensagem := NULL;
    SELECT COUNT(*)
      INTO vicontador
      FROM pcautori
     WHERE codcli = p_codcli
       AND codusur = p_codusur
       AND codplpag = p_codplpag
       AND codprod = p_codprod
       AND nvl(statusutiliz, 'N') = 'N'
       AND nvl(pcautori.codauxiliar, 0) =
           decode(p_utilizavendaporembalagem,
                  'S',
                  p_codauxiliar,
                  nvl(pcautori.codauxiliar, 0));
    IF vicontador > 0 THEN
      BEGIN


        /*
        --Responsável: Rafael Soares
        --Data:        27/06/2016
        --Solicitação: 0.055283.2016
        --Alteração:   Ajustado para que a validação de politica de autirazação de preço, caso a politica não seja valida para o pedido
        --             a deve ser consultado o próximo registro ao invés de rejeitar diretamente o item.

        */


        for DESCAUT in ( SELECT pcautori.nrautorizacao,
                               nvl(pcautori.percdescautor, 0) percdescautor,
                               pcautori.pvendaatual,
                               pcautori.basecreddebrca,
                               pcautori.percom,
                               pcautori.codfilial
                          FROM pcautori
                         WHERE codcli = p_codcli
                           AND codusur = p_codusur
                           AND codplpag = p_codplpag
                           AND codprod = p_codprod
                           AND nvl(statusutiliz, 'N') = 'N'
                           AND nvl(pcautori.codauxiliar, 0) =
                               decode(p_utilizavendaporembalagem,
                                      'S',
                                      p_codauxiliar,
                                      nvl(pcautori.codauxiliar, 0))
                         ) LOOP

                           vnnrautorizacao := DESCAUT.Nrautorizacao;
                           vnpercdescautor := DESCAUT.percdescautor;
                           vnpvendaatual   := DESCAUT.pvendaatual;
                           vsbasecreddebrca_autori  := DESCAUT.basecreddebrca  ;
                           vnpercomAutorizacao := DESCAUT.PERCOM;

                           vnpvenda_autori := nvl(vnpvendaatual, p_ptabelaant) *
                           (1 - (vnpercdescautor / 100));
                           vnpvenda_autori := round(vnpvenda_autori, p_numcasasdecvenda);

                           IF vnpvenda_autori <= p_pvenda THEN
                              exit;
                           end if;

         end loop;


        p_pbaserca := p_ptabela;

          -- DDVENDAS-972: Equiparada à validação da Integradora.
        if p_numcasasdecvenda <= 3 then
                 vnFatorPrecoMinimo := (1/(power(10, p_numcasasdecvenda)));
              else
                 vnFatorPrecoMinimo := (3/(power(10, p_numcasasdecvenda)));
          end if;

              -- Verifica diferença entre Preço de Venda e Preço Autorizado.
            IF (vnpvenda_autori - round((p_pvenda),p_numcasasdecvenda))
                 between 0 and vnFatorPrecoMinimo
                   THEN
                  vnpvenda_autori := p_pvenda;
              end if;

        IF vnpvenda_autori <= p_pvenda THEN
          IF vsbasecreddebrca_autori = 'S' THEN
            p_pbaserca := p_pvenda;
          ELSIF vsbasecreddebrca_autori = 'A' THEN
            p_pbaserca := vnpvenda_autori;
          END IF;
          
          p_percomAutorizacao := vnpercomAutorizacao;
          UPDATE pcautori
             SET data_utilizacao = trunc(SYSDATE),
                 codfuncutiliz   = p_codfunc,
                 statusutiliz    = 'S',
                 numped          = p_numped,
                 pvendido        = p_pvenda
           WHERE nrautorizacao = vnnrautorizacao;
        ELSE
          vsmensagem  := vsmensagem || ' Desconto acima do permitido #' ||
                         ' Preco de Venda: ' || p_pvenda || '#';
          vsmensagem  := vsmensagem || ' Preco Tabela  : ' ||
                         round(nvl(vnpvendaatual, p_ptabela),
                               p_numcasasdecvenda) || '#';
          vsmensagem  := vsmensagem || ' Desconto(%)   : ' ||
                         vnpercdescautor || '#';
          vsmensagem  := vsmensagem || ' Preco Minimo  : #' ||
                         vnpvenda_autori || '#';
          p_pvendamin := vnpvenda_autori;
          vbvalido    := FALSE;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          vsmensagem  := vsmensagem || ' Desconto acima do permitido #';
          vsmensagem  := vsmensagem || ' Preco de Venda: ' || p_pvenda || '#';
          vsmensagem  := vsmensagem || ' Preco Tabela  : ' ||
                         round(nvl(vnpvendaatual, p_ptabela),
                               p_numcasasdecvenda) || '#';
          vsmensagem  := vsmensagem || ' Desconto(%)   : ' ||
                         vnpercdescautor || '#';
          vsmensagem  := vsmensagem || ' Preco Minimo  : ' ||
                         vnpvenda_autori || '#';
          p_pvendamin := vnpvenda_autori;
          vbvalido    := FALSE;
      END;
    ELSE
      vsmensagem := vsmensagem || ' Desconto acima do permitido #';
      vsmensagem := vsmensagem || ' Preco de Venda: ' || p_pvenda || '#';
      vsmensagem := vsmensagem || ' Preco Tabela  : ' ||
                    round(p_ptabela, p_numcasasdecvenda) || '#';
      vsmensagem := vsmensagem || ' Desconto(%)   : ' || p_permaxdesc || '#';
      vsmensagem := vsmensagem || ' Preco Minimo  : ' || p_pvendamin || '#';
      vbvalido   := FALSE;
    END IF;
    p_mensagem := vsmensagem;
    RETURN vbvalido;
  END validarautorizacaovenda;

  FUNCTION validarpoliticasdesconto( -- 15 parametros
                                    p_codprod          IN NUMBER,
                                    p_data             IN DATE,
                                    p_codfilial        IN VARCHAR2,
                                    p_numregiao        IN NUMBER,
                                    p_codcli           IN NUMBER,
                                    p_codusur          IN NUMBER,
                                    p_origempedido     IN VARCHAR2,
                                    p_codprodprinc     IN NUMBER,
                                    p_numcasasdecvenda IN NUMBER,
                                    p_codplpag         IN NUMBER,
                                    p_tipo             in varchar2,
                                    p_dtfim            OUT DATE,
                                    p_mensagem         OUT VARCHAR2,
                                    p_perdesc          OUT NUMBER,
                                    p_basecreddebrca   OUT VARCHAR2)
    RETURN BOOLEAN IS

    vbresult             BOOLEAN;
    vsperdescrestricao         VARCHAR2(1);
    vstratarrestricaoacrescimo VARCHAR2(1);

  BEGIN

    vstratarrestricaoacrescimo := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TRATARRESTRICAOACRESCIMO','99','S');

    vbresult := validarpoliticasdesconto(--18 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         vstratarrestricaoacrescimo,
                                         NULL,
                                         0,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         vsperdescrestricao
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION buscapercomissao -- 26 parametros
  (p_tipovend                  IN VARCHAR2,
   p_pcomint1                  IN NUMBER,
   p_pcomext1                  IN NUMBER,
   p_pcomrep1                  IN NUMBER,
   p_usacomissaoporcliente     IN VARCHAR2,
   p_percomcli                 IN NUMBER,
   p_usacomissaoporrca         IN VARCHAR2,
   p_comissaorcatipovenda      IN VARCHAR2,
   p_tipovenda                 IN VARCHAR2,
   p_percent                   IN NUMBER,
   p_percent2                  IN NUMBER,
   p_usacomissaoporlinhaprod   IN VARCHAR2,
   p_codplpag                  IN NUMBER,
   p_codlinhaprod              IN NUMBER,
   p_perdesc                   IN NUMBER,
   p_codusur                   IN NUMBER,
   p_numregiao                 IN NUMBER,
   p_codsec                    IN pcprodut.codsec%TYPE,
   p_codepto                   IN pcprodut.codepto%TYPE,
   p_codprod                   IN pcprodut.codprod%TYPE,
   p_perluc                    IN NUMBER,
   p_ordemavaliacaocomissaorca IN NUMBER,
   p_codfilial                 IN VARCHAR2,
   p_data                      in date,
   p_letracomiss               OUT VARCHAR2,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER IS
    vnpercom      NUMBER;
    vsletracomiss VARCHAR2(2);
  BEGIN

    vnpercom := buscapercomissao(p_tipovend,
                                 p_pcomint1,
                                 p_pcomext1,
                                 p_pcomrep1,
                                 p_usacomissaoporcliente,
                                 p_percomcli,
                                 p_usacomissaoporrca,
                                 p_comissaorcatipovenda,
                                 p_tipovenda,
                                 p_percent,
                                 p_percent2,
                                 p_usacomissaoporlinhaprod,
                                 p_codplpag,
                                 p_codlinhaprod,
                                 p_perdesc,
                                 p_codusur,
                                 p_numregiao,
                                 p_codsec,
                                 p_codepto,
                                 p_codprod,
                                 p_perluc,
                                 p_ordemavaliacaocomissaorca,
                                 p_codfilial,
                                 p_data,
                                 ----------------------------
                                 --O parâmetro abaixo assumirá o valor padrão NULO.
                                 NULL, --p_classeproduto,
                                 ----------------------------
                                 vsletracomiss,
                                 p_mensagem
                                );

    p_letracomiss := vsletracomiss;

    RETURN nvl(vnpercom, 0);

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  PROCEDURE Definir_Comissao_por_PCProdut(p_tipovend               in pcusuari.tipovend%type,
                                          p_pcomint1               in pcprodut.pcomint1%type,
                                          P_PCOMEXT1               in pcprodut.pcomext1%type,
                                          P_PCOMREP1               in pcprodut.pcomrep1%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number) IS
    vnpercom number;

  BEGIN

    Definir_Comissao_por_PCProdut(p_tipovend,
                                  p_pcomint1,
                                  P_PCOMEXT1,
                                  P_PCOMREP1,
                                  0, --p_codprod,
                                  NULL, --p_codfilial,
                                  p_considerarcomissaozero,
                                  vnpercom);

    p_percom := vnpercom;

  EXCEPTION
    WHEN OTHERS THEN
      p_percom := 0;

  END;

  procedure Definir_Comissao_por_PCClient(p_usacomissaoporcliente  in pcconsum.usacomissaoporcliente%type,
                                          p_percomcli              in pcclient.percomcli%type,
                                          p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                          p_PerCom                 out number) IS

    vnpercom number;
  begin

    Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                  p_percomcli,
                                  p_ConsiderarComissaoZero,
                                  0, --p_codcli,
                                  NULL, --p_codfilial,
                                  vnpercom);
    p_PerCom := vnpercom;

  EXCEPTION
    WHEN OTHERS THEN
      p_PerCom := 0;

  END;

  procedure Definir_Comissao_por_PCUsuari(P_USACOMISSAOPORRCA      IN pcconsum.usacomissaoporrca%type,
                                          P_TIPOVENDA              IN pcplpag.tipovenda%type,
                                          P_PERCENT                IN pcusuari.percent%type,
                                          P_PERCENT2               IN pcusuari.percent2%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_comissaorcatipovenda   in pcconsum.comissaorcatipovenda%type,
                                          p_percom                 out number) is

    vnpercom number;

  begin
    if P_USACOMISSAOPORRCA = 'S' then

      -- Tarefa 28810
      if p_ComissaoRCATipoVenda = 'S' then

        if p_TIPOVENDA = 'VV' and p_PERCENT is not null then

          if p_PERCENT = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              vnPERCOM := p_PERCENT;
            end if;

          else
            vnPERCOM := p_PERCENT;
          end if;

        else
          if p_TIPOVENDA = 'VP' and p_PERCENT2 is not null then

            if p_PERCENT2 = 0 then

              if p_ConsiderarComissaoZero = 'S' then
                vnPERCOM := p_PERCENT2;
              end if;
            else
              vnPERCOM := p_PERCENT2;
            end if;
          end if;
        end if;
      else
        if p_PERCENT2 is not null then

          if p_PERCENT2 = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              vnPERCOM := p_PERCENT2;
            end if;
          else
            vnPERCOM := p_PERCENT2;
          end if;

        end if;
      end if;
    end if;

    p_percom := vnpercom;

  end;

  procedure Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD in pcconsum.usacomissaoporlinhaprod%type,
                                          p_ConsiderarComissaoZero  in pcfilial.considerarcomissaozero%type,
                                          p_codplpag                in pcplpag.codplpag%type,
                                          p_codlinhaprod            in pcprodut.codlinhaprod%type,
                                          p_percom                  out number) is

    vnperccomiss number;
    vicont       number;
    vnpercom     number;

  begin
    if p_USACOMISSAOPORLINHAPROD = 'S' then

      SELECT count(*)
        INTO Vicont
        FROM PCPLPAGI
       WHERE PCPLPAGI.CODPLPAG = p_codplpag
         AND PCPLPAGI.CODLINHAPROD = p_codlinhaprod;

      if vicont <> 0 then

        SELECT NVL(PCPLPAGI.PERCCOMISS, 0)
          INTO VNPERCCOMISS
          FROM PCPLPAGI
         WHERE PCPLPAGI.CODPLPAG = p_codplpag
           AND PCPLPAGI.CODLINHAPROD = p_codlinhaprod;

        if vnperccomiss is not null then

          if vnPERCCOMISS = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              vnPERCOM := vnPERCCOMISS;
            end if;
          else
            vnPERCOM := vnPERCCOMISS;
          end if;

        end if;
      end if;
    end if;

    p_percom := vnpercom;

  end;

  PROCEDURE Definir_Comissao_por_LUCRO(--7 Parâmetros
                                       p_perluc                 in number,
                                       p_perdesc                in number,
                                       p_tipovend               pcusuari.tipovend%type,
                                       p_tipocomissao           pcprodut.tipocomissao%type,
                                       p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                       p_percom                 out number,
                                       p_letracomiss            out pcpedi.letracomiss%type) is

    vncodfaixa  NUMBER;

  BEGIN

    Definir_Comissao_por_LUCRO(p_perluc,
                               p_perdesc,
                               p_tipovend,
                               p_tipocomissao,
                               p_ConsiderarComissaoZero,
                               p_percom,
                               p_letracomiss,
                               vncodfaixa);

  EXCEPTION
    WHEN OTHERS THEN
      p_percom := 0;
      p_letracomiss := '';
  end;

  procedure Definir_Comis_PCCOMISSAOUSUR
    (p_perdesc                in number,
     p_codusur                in number,
     p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
     p_codepto                in pcprodut.codepto%type,
     p_codsec                 in pcprodut.codsec%type,
     p_codprod                in pcprodut.codprod%type,
     p_percom                 out number,
     p_letracomiss            out varchar2) IS

    vncodcomiss  NUMBER;
    vsmensagem   VARCHAR2(1000);

  BEGIN

    Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                 p_codusur,
                                 p_ConsiderarComissaoZero,
                                 p_codepto,
                                 p_codsec,
                                 p_codprod,
                                 p_percom,
                                 p_letracomiss,
                                 vncodcomiss,
                                 vsmensagem
                                );
  EXCEPTION
    WHEN OTHERS THEN
      p_percom := 0;
      p_letracomiss := NULL;

  end;

  PROCEDURE ValidarPCComissaoRegiao(--11 Parâmetros
                                    p_numregiao              in pcregiao.numregiao%type,
                                    p_codfilial              in pcfilial.codigo%type,
                                    p_perdesc                in number,
                                    p_data                   in date,
                                    p_codprod                in pcprodut.codprod%type,
                                    p_codsec                 in pcprodut.codsec%type,
                                    p_codepto                in pcprodut.codepto%type,
                                    p_tipovend               in pcusuari.tipovend%type,
                                    p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                    p_percom                 out number,
                                    p_letracomiss            out varchar2) IS

    vscodcomissao NUMBER;
    vsmensagem    VARCHAR2(1000);

  BEGIN

    ValidarPCComissaoRegiao(--13 Parâmetros
                            p_numregiao,
                            p_codfilial,
                            round(p_perdesc,2),  --5574.040724.2016
                            p_data,
                            p_codprod,
                            p_codsec,
                            p_codepto,
                            p_tipovend,
                            p_ConsiderarComissaoZero,
                            p_percom,
                            p_letracomiss,
                            vscodcomissao, --p_codcomiss,
                            vsmensagem --p_mensagem
                           );

  EXCEPTION
    WHEN OTHERS THEN
      p_percom := NULL;
      p_letracomiss := NULL;

  END;

  PROCEDURE ValidarPCCOMISSAOPLPAG(--10 Parâmetros
                                   p_tipovend               in pcusuari.tipovend%type,
                                   p_codplpag               in pcplpag.codplpag%type,
                                   p_perdesc                in number,
                                   p_codprod                in pcprodut.codprod%type,
                                   p_codepto                in pcprodut.codepto%type,
                                   p_codsec                 in pcprodut.codsec%type,
                                   p_classeproduto          in pcprodut.classe%type,
                                   p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                   p_percom                 out number,
                                   p_letracomiss            out varchar2) IS

    vscodcomissao NUMBER;
    vsmensagem    VARCHAR2(1000);
  BEGIN

    ValidarPCCOMISSAOPLPAG(p_tipovend,
                           p_codplpag,
                           p_perdesc,
                           p_codprod,
                           p_codepto,
                           p_codsec,
                           p_classeproduto,
                           p_ConsiderarComissaoZero,
                           p_percom,
                           p_letracomiss,
                           vscodcomissao, --p_codcomiss,
                           vsmensagem --p_mensagem
                          );
  EXCEPTION
    WHEN OTHERS THEN
      p_percom := NULL;
      p_letracomiss := NULL;

  END;

  procedure Definir_Comissao_por_Filial(p_codfilial              in pcfilial.codigo%type,
                                        p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                        p_percom                 out number) is

    vnpercom number;

  begin

    begin
      select pcfilial.percomrcabroker
        into vnpercom
        from pcfilial
       where pcfilial.codigo = p_codfilial;
    exception
      when others then
        vnpercom := null;
    end;

    if vnPERCOM is not null then

      if vnPERCOM = 0 then

        if p_ConsiderarComissaoZero = 'S' then
          p_percom := vnpercom;
        end if;

      else
        p_PERCOM := vnPERCOM;
      end if;
    end if;

  end;

  --34 parâmetros
  FUNCTION Definir_Comissao_Item_Vendido(p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2)
    RETURN NUMBER IS

    vnpercom       NUMBER;
    vbUsaPCComissaofilial BOOLEAN;

  BEGIN
    vnPerCom := 0;
    vbUsaPCComissaofilial := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_BROKER',p_codfilial,'N') = 'S');

    vnpercom := Definir_Comissao_Item_Vendido(p_NumRegiao,
                                              p_perluc,
                                              p_perdesc,
                                              p_UsaPcTabComiss,
                                              p_UsaPcComissaoUsur,
                                              p_UsaPCComissaoPlPag,
                                              p_UsaPCComissaoRegiao,
                                              vbUsaPCComissaofilial,
                                              p_usacomissaoporrca,
                                              p_OrdemAvaliacaoComissaoRCA,
                                              p_usacomissaoporcliente,
                                              p_USACOMISSAOPORLINHAPROD,
                                              p_comissaorcatipovenda,
                                              p_tipovend,
                                              p_percent,
                                              p_percent2,
                                              p_codprod,
                                              p_pcomint1,
                                              P_PCOMEXT1,
                                              P_PCOMREP1,
                                              p_codlinhaprod,
                                              p_tipocomissao,
                                              p_codepto,
                                              p_codsec,
                                              p_classeproduto,
                                              p_tipovenda,
                                              p_codplpag,
                                              p_data,
                                              p_codfilial,
                                              p_codusur,
                                              p_considerarcomissaozero,
                                              p_tipoavaliacaocomissao,
                                              p_percomcli,
                                              0, --p_codcli,
                                              p_LetraComiss,
                                              p_mensagem
                                             );

    RETURN vnPerCom;

  exception
    when others then
      p_mensagem := 'Erro ao calcular comissao : ' || SQLERRM;
      RETURN 0;

  end;

  FUNCTION validarpoliticaprecofixo -- 21 parametros
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_numlote                 IN VARCHAR2,
   p_origemped               IN VARCHAR2,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN

    vbresult := validarpoliticaprecofixo(--28 parametros
                                         p_codprod,
                                         p_data,
                                         p_numregiao,
                                         p_codcli,
                                         p_condvenda,
                                         p_codplpag,
                                         p_ptabela,
                                         p_validapvendabonific,
                                         p_utilizapercfinprecoprom,
                                         p_pertxfim,
                                         p_numdias,
                                         p_codcliprinc,
                                         p_codprodprinc,
                                         p_codpraca,
                                         p_codusur,
                                         p_codsupervisor,
                                         p_numlote,
                                         p_origemped,
                                         0, --p_codativ,
                                         p_dtfim,
                                         p_mensagem,
                                         p_precofixo,
                                         '',--p_codfilial,
                                         'S', --p_validarprecovendatv20,
                                         'N', --p_broker,
                                         'N', --p_utilizavendaporfilial,
                                         'N', --p_precoporfilial,
                                         NULL --p_codauxiliar
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Preco Fixo ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticaprecofixo;

  FUNCTION calcularimpostos --38 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_importado              in pcprodut.importado%type,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN
    vbresult := FALSE;

    vbresult := calcularimpostos(p_pvenda,
                                 p_ptabela,
                                 p_pbaserca,
                                 p_vlipi,
                                 p_percipi,
                                 p_percipivenda,
                                 p_percvenda,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_mostrarpvendasemst,
                                 p_consideraisentoscomopf,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_pauta,
                                 p_iva,
                                 p_aliqicms1,
                                 p_aliqicms2,
                                 p_percbaseredst,
                                 p_numcasasdecvenda,
                                 p_tipocalculo,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 p_usavalorultentbasest2,
                                 p_valorultent,
                                 p_isentoipi,
                                 p_suframa,
                                 p_calcularstcomipi,
                                 p_tipocalcipi,
                                 p_filialnf,
                                 p_condvenda,
                                 p_contribuinte,
                                 p_uffilialnf,
                                 p_importado,
                                 --------------------------------
                                 --NÃO ALTERAR O PADRÃO ABAIXO!
                                 'S', --P_CALCULARIPIVENDA,
                                 0, --P_PERCIPIVENDATAB,
                                 0, --P_VLPAUTAIPIVENDA,
                                 0, --P_VLPAUTAIPIVENDATAB,
                                 0, --P_VLIPIPORKGVENDA,
                                 0, --P_VLIPIPORKGVENDATAB,
                                 0, --P_PESOBRUTO,
                                 'P', --P_TIPOCALCULOGNRE,
                                 --------------------------------
                                 p_mensagem,
                                 p_st,
                                 p_baseicst
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularimpostos;

  FUNCTION calcularimpostos --46 parametros
  (p_pvenda                 IN OUT NUMBER,
   p_ptabela                IN OUT NUMBER,
   p_pbaserca               IN OUT NUMBER,
   p_vlipi                  IN OUT NUMBER,
   p_percipi                IN OUT NUMBER,
   p_percipivenda           IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_isentoipi              IN VARCHAR2,
   p_suframa                IN pcclient.sulframa%type,
   p_calcularstcomipi       IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi            IN pcconsum.tipocalcipi%TYPE,
   p_filialnf               IN pcpedc.codfilialnf%TYPE,
   p_condvenda              IN pcpedc.condvenda%TYPE,
   p_contribuinte           IN pcclient.contribuinte%TYPE,
   p_uffilialnf             IN pcfilial.uf%TYPE,
   p_importado              in pcprodut.importado%type,
   P_CALCULARIPIVENDA       IN PCFILIAL.CALCULARIPIVENDA%TYPE,
   P_PERCIPIVENDATAB        IN PCPRODUT.PERCIPIVENDATAB%TYPE,
   P_VLPAUTAIPIVENDA        IN PCPRODUT.VLPAUTAIPIVENDA%type,
   P_VLPAUTAIPIVENDATAB     IN PCPRODUT.VLPAUTAIPIVENDATAB%TYPE,
   P_VLIPIPORKGVENDA        IN PCPRODUT.VLIPIPORKGVENDA%TYPE,
   P_VLIPIPORKGVENDATAB     IN PCPRODUT.VLIPIPORKGVENDATAB%TYPE,
   P_PESOBRUTO              IN PCPRODUT.PESOBRUTO%type,
   P_TIPOCALCULOGNRE        IN PCTRIBUT.Tipocalculognre%type,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER) RETURN BOOLEAN IS

    vbresult    BOOLEAN;
    vnIVA       NUMBER;

  BEGIN

    vbresult := FALSE;
    vnIVA := p_iva;

    vbresult := calcularimpostos(p_pvenda,
                                 p_ptabela,
                                 p_pbaserca,
                                 p_vlipi,
                                 p_percipi,
                                 p_percipivenda,
                                 p_percvenda,
                                 p_tipocalcst,
                                 p_calcstpf,
                                 p_mostrarpvendasemst,
                                 p_consideraisentoscomopf,
                                 p_calculast,
                                 p_ieent,
                                 p_tipofj,
                                 p_pauta,
                                 vnIVA,
                                 p_aliqicms1,
                                 p_aliqicms2,
                                 p_percbaseredst,
                                 p_numcasasdecvenda,
                                 p_tipocalculo,
                                 p_uffilial,
                                 p_estent,
                                 p_usavalorultentbasest,
                                 p_usavalorultentbasest2,
                                 p_valorultent,
                                 p_isentoipi,
                                 p_suframa,
                                 p_calcularstcomipi,
                                 p_tipocalcipi,
                                 p_filialnf,
                                 p_condvenda,
                                 p_contribuinte,
                                 p_uffilialnf,
                                 p_importado,
                                 P_CALCULARIPIVENDA,
                                 P_PERCIPIVENDATAB,
                                 P_VLPAUTAIPIVENDA,
                                 P_VLPAUTAIPIVENDATAB,
                                 P_VLIPIPORKGVENDA,
                                 P_VLIPIPORKGVENDATAB,
                                 P_PESOBRUTO,
                                 P_TIPOCALCULOGNRE,
                                 --------------------------------
                                 --NÃO ALTERAR O PADRÃO ABAIXO!
                                 'N', --p_SIMPLESNACIONAL,
                                 0, --p_PERCREDPVENDASIMPLESNAC,
                                 'N', --p_reduziva, --utilizado pelo fv para fazer um calculo sem redução do iva mesmo que o cliente seja simples nacional
                                 'N', --p_utilizaiesimplificada,
                                 --------------------------------
                                 p_mensagem,
                                 p_st,
                                 p_baseicst,
                                 --------------------------------
                                 --Passando os valores padrões/default
                                 'N', --p_aceitapfcontribuinte,
                                 0, --p_custonfsemst,
                                 'N', --p_usapmcbasest,
                                 0, --p_precomaxconsum,
                                 'N', --p_consumidorfinal,
                                 'S', --p_retiraimp,
                                 'N', --p_novoprocesso,
                                 'N', --p_agregaripicalculost,
                                 'N', --p_utilizacalculostmt,
                                 0, --p_margemmva,
                                 0, --p_percargatribmedia,
                                 'N', --p_usavlultentmediobasest,
                                 0, --p_vlultentmes,
                                 0 --p_percbasestrj
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularimpostos;

  FUNCTION calcularstfonte --45 parametros (mas pode ser usada por packages que chamam a de 38 parÂmetros)
  (p_codprod                   IN NUMBER,
   p_condvenda                 IN NUMBER,
   p_percvenda                 IN NUMBER,
   p_iva                       IN NUMBER,
   p_ivafonte                  IN OUT NUMBER,
   p_aliqicms1fonte            IN OUT NUMBER,
   p_aliqicms2fonte            IN OUT NUMBER,
   p_percbaseredstfonte        IN OUT NUMBER,
   p_percbaserednrpa           IN NUMBER,
   p_percbaseredconsumidor     IN NUMBER,
   p_utilizapercbaseredpf_trib IN VARCHAR2,
   p_tipocalcst                IN VARCHAR2,
   p_calcstpf                  IN VARCHAR2,
   p_utilizapercbaseredpf      IN VARCHAR2,
   p_clientefontest            IN VARCHAR2,
   p_calculast                 IN VARCHAR2,
   p_ieent                     IN VARCHAR2,
   p_tipofj                    IN VARCHAR2,
   p_isentoicms                IN VARCHAR2,
   p_consumidorfinal           IN VARCHAR2,
   p_utilizaiesimplificada     IN VARCHAR2,
   p_tipoempresa               IN VARCHAR2,
   p_consideraisentoscomopf    IN VARCHAR2,
   p_pvenda                    IN NUMBER,
   p_vlipi                     IN NUMBER,
   p_uffilial                  IN VARCHAR2,
   p_estent                    IN VARCHAR2,
   p_usavalorultentbasest      IN VARCHAR2,
   p_valorultent               IN NUMBER,
   p_usaivafontediferenciado   IN VARCHAR2,
   p_ivafonte_cli              IN NUMBER,
   p_AceitaPFContribuinte      IN VARCHAR,
   p_ALIQICMS1                 IN NUMBER,
   p_ALIQICMS2                 IN NUMBER,
   p_contribuinte              IN VARCHAR2,
   p_numcasasdecvenda          in NUMBER,
   p_baseicst                  IN OUT NUMBER,
   p_mensagem                  OUT VARCHAR2,
   P_CUSTONFSEMST              in pcest.custonfsemst%type default 0,
   p_usavalorultentbasest2     in pctribut.usavalorultentbasest2%type default 'N',
   p_usapmcbasest              in pctribut.usapmcbasest%type default 'N' ,
   p_precomaxconsum            in pcprodut.precomaxconsum%type default 0 ,
   p_importado                 in pcprodut.importado%type default 'N',
   p_percbasestrj              in pctribut.percbasestrj%type default 0,
   p_AGREGARIPICALCULOST       in pctribut.agregaripicalculost%type default 'N' ) RETURN NUMBER IS

    vnpercbasered    NUMBER;
    vnbcst           NUMBER;
    vnstf1           NUMBER;
    vnstf2           NUMBER;
    vnstfonte        NUMBER;
    vnpbase          NUMBER;
    vnpbase2         NUMBER;
    vbPessoaFisica   Boolean;
    vscontribuinte   pcclient.contribuinte%type;
    vnIvaFonte       number;
    vbCalculaSTFonte Boolean;
    vnpvenda         number;
    vncustonfsemst   pcest.custonfsemst%type;
    vsConsiderarIpiAliqicms2 varchar2(1);
    vnvlSTMinRJ      pcpedi.st%type;

  BEGIN
    vnbcst           := 0;
    vnstf1           := 0;
    vnstf2           := 0;
    vnstfonte        := 0;
    vbPessoaFisica   := False;
    vnIvaFonte       := p_IVAFONTE;
    vbCalculaSTFonte := True;


    vsConsiderarIpiAliqicms2 := 'N';

    if (p_ConsumidorFinal = 'S') and ((p_Importado = 'S') or (p_Importado = 'D')) and
       (p_uffilial <> p_estent) and (p_AGREGARIPICALCULOST = 'S') then

       vsConsiderarIpiAliqicms2 := 'S';
    end if;

    vscontribuinte := p_contribuinte;

    vnpvenda := p_pvenda;

    vncustonfsemst := p_custonfsemst;

    if nvl(P_CUSTONFSEMST,0) = 0 then
       vnCUSTONFSEMST := p_valorultent;

    end if;

    -- Definindo se é Pessoa Física
    if (p_AceitaPFContribuinte = 'N') then
      vscontribuinte := p_AceitaPFContribuinte;
    end if;

    if (((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N')) or
       (p_CONSUMIDORFINAL = 'S') or
       ((p_CONSIDERAISENTOSCOMOPF = 'S') and
       ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or
       (p_IEENT = 'ISENTA')))) and (vscontribuinte = 'N') then
      vbpessoafisica := true;
    end if;

    -- Identificar a incidência de ST Fonte [RDB05]
    vbCalculaSTFonte := (p_CLIENTEFONTEST = 'S')  and
                        ((p_ALIQICMS1FONTE > 0) or (p_ALIQICMS2FONTE > 0));-- and  ((p_ALIQICMS1 = 0) or (p_ALIQICMS2 = 0));

    vbCalculaSTFonte := vbCalculaSTFonte and
                        (not ((p_CALCSTPF = 'N') and (vbpessoafisica)));

    -- Calcular valor do ST Fonte [RBD04]
    if vbCalculaSTFonte then

      IF (p_uffilial = p_estent) AND
         (nvl(p_usavalorultentbasest, 'N') = 'S') THEN
        vnpbase  := vncustonfsemst;
--        vnpvenda := p_valorultent;
      ELSE
        vnpbase := p_pvenda;
      END IF;

      if (p_UfFilial = p_EstEnt)
      and (p_UsaValorUltEntBaseST2 = 'S') then
      vnPVENDA := vnCustoNFSemST;
      end if;

      --vnpbase := vnpbase + nvl(p_vlipi, 0);
      vnpbase := vnpvenda + nvl(p_vlipi, 0);

      if (p_PRECOMAXCONSUM > 0) and
         (p_USAPMCBASEST = 'S') THEN
        vnPBASE := P_PRECOMAXCONSUM;
      end IF;

      vnpercbasered := p_percbaseredstfonte;

      ---- Se tipo de empresa do cliente for Normal RPA
      ---- Aplicar %reducao na base de ICMS especifico
      IF (p_tipoempresa = 'NRPA') THEN
        vnpercbasered := p_percbaserednrpa;
      END IF;
      ---- Cliente consumidor final utiliza %base red. p/ consumidor final
      IF (p_consumidorfinal = 'S') AND (p_percbaseredconsumidor <> 0) THEN
        vnpercbasered := p_percbaseredconsumidor;
      END IF;
      ---- Cliente PF que utiliza IE simplificada nao aplica %base red
      IF (p_utilizaiesimplificada = 'S') AND (p_tipofj = 'F') AND
         (p_contribuinte = 'N') THEN
        vnpercbasered := 0;
      END IF;

      if vbpessoafisica = true then
        if (p_UTILIZAPERCBASEREDPF = 'N') or
           (p_UTILIZAPERCBASEREDPF_TRIB = 'N') then
          vnPERCBASERED := 0;
        end if;
      end if;

      IF (p_isentoicms = 'S') OR (p_condvenda = 7) THEN
        vnpercbasered := 0;
      END IF;
      p_percbaseredstfonte := vnpercbasered;

      -- Definir IVA do ST Fonte [RBD07]
      if p_UsaIVAFonteDiferenciado = 'N' then
        vnIvaFonte := p_IVAFONTE;

        if vnIVAFONTE = 0  and
           not ((nvl(p_PRECOMAXCONSUM,0) > 0) and (NVL(p_USAPMCBASEST,'N') = 'S')) then
          p_ALIQICMS1FONTE := 0;
          p_ALIQICMS2FONTE := 0;
        end if;
      elsif p_usaivafontediferenciado = 'S' then
        vnIvaFonte := p_IVAFonte_Cli;
      elsif p_usaivafontediferenciado = 'M' then

        if p_IVAFONTE > p_IVAFonte_Cli then
          vnIVAFONTE := p_IVAFONTE;
        else
          vnIvaFonte := p_IVAFonte_Cli;
        end if;
      end if;

      vnpbase2 := vnpbase;

      IF vnpercbasered > 0 THEN
        vnpbase := vnpbase * (vnpercbasered / 100);
      END IF;


      ---****

      if p_precomaxconsum > 0 and p_usapmcbasest = 'S' then
         vnbcst := vnpbase;
      else
         vnbcst := vnpbase * ( 1+ (vnIvaFonte/100));
      end if;

      if nvl(p_percbasestrj,0) > 0 then
         vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
      else
         vnvlstminrj := 0;
      end if;

      p_baseicst := vnbcst;

      vnstf1      := (vnbcst * (p_aliqicms1fonte / 100));

      if vsConsiderarIpiAliqicms2 = 'S' then
        --vnSTf2 := ((vnPVENDA) * (p_aliqicms2fonte / 100));
        vnSTf2 := ((vnpbase2) * (p_aliqicms2fonte / 100));
      ELSE
        --vnSTf2 := ((vnPVENDA - p_vlipi) * (p_ALIQICMS2fonte / 100));
        vnSTf2 := ((vnpbase2 - p_vlipi) * (p_ALIQICMS2fonte / 100));
      end if;

      vnstfonte := vnstf1 - vnstf2;

      if nvl(vnvlstminrj,0) > 0 and vnstfonte < (vnvlSTMinRJ) then
        vnSTfonte := vnvlSTMinRJ;
      end if;

      ---*****

      --Calcular ST - Truncar com 2 casas decimais
      IF p_tipocalcst = 'T2' THEN
        vnstfonte := trunc((vnstfonte) * 100) / 100;
      ELSIF p_tipocalcst = 'A2' THEN
        vnstfonte := round((vnstfonte) * 100) / 100;
      ELSIF p_tipocalcst = 'PV' THEN
        vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);

      END IF;

      --Se ST for menor que 0, torná-lo 0
      IF vnstfonte < 0 THEN
        vnstfonte := 0;
      ELSIF vnstfonte = 0 THEN
        vnbcst := 0;
      END IF;

    end if;
    -- tarefa 53294
    IF nvl(p_aliqicms1fonte, 0) = 0 AND
       nvl(p_aliqicms2fonte, 0) = 0 THEN
      vnbcst := 0;
    END IF;
    p_baseicst := vnbcst;

    RETURN vnstfonte;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular STfonte: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END calcularstfonte;

  FUNCTION buscapercomissao -- 27 parametros
  (p_tipovend                  IN VARCHAR2,
   p_pcomint1                  IN NUMBER,
   p_pcomext1                  IN NUMBER,
   p_pcomrep1                  IN NUMBER,
   p_usacomissaoporcliente     IN VARCHAR2,
   p_percomcli                 IN NUMBER,
   p_usacomissaoporrca         IN VARCHAR2,
   p_comissaorcatipovenda      IN VARCHAR2,
   p_tipovenda                 IN VARCHAR2,
   p_percent                   IN NUMBER,
   p_percent2                  IN NUMBER,
   p_usacomissaoporlinhaprod   IN VARCHAR2,
   p_codplpag                  IN NUMBER,
   p_codlinhaprod              IN NUMBER,
   p_perdesc                   IN NUMBER,
   p_codusur                   IN NUMBER,
   p_numregiao                 IN NUMBER,
   p_codsec                    IN pcprodut.codsec%TYPE,
   p_codepto                   IN pcprodut.codepto%TYPE,
   p_codprod                   IN pcprodut.codprod%TYPE,
   p_perluc                    IN NUMBER,
   p_ordemavaliacaocomissaorca IN NUMBER,
   p_codfilial                 IN VARCHAR2,
   p_data                      in date,
   p_classeproduto             in pcprodut.classe%type,
   p_letracomiss               OUT VARCHAR2,
   p_mensagem                  OUT VARCHAR2) RETURN NUMBER IS
    vnpercom      NUMBER;
    vicont        NUMBER;
    vitabcomiss   NUMBER;
    vsletracomiss VARCHAR2(2);
  BEGIN

    --Por Cliente e Produto

    -- Comissão
    -- Por Produto
    IF p_tipovend = 'I' THEN
      vnpercom := p_pcomint1;
    ELSIF p_tipovend = 'E' THEN
      vnpercom := p_pcomext1;
    ELSIF p_tipovend = 'R' THEN
      vnpercom := p_pcomrep1;
    ELSE
      vnpercom := 0;
    END IF;
    -- Por Cliente
    IF nvl(p_usacomissaoporcliente, 'N') = 'S' THEN
      IF p_percomcli IS NOT NULL THEN
        vnpercom := p_percomcli;
      END IF;
    END IF;
    -- Por Rca
    IF nvl(p_usacomissaoporrca, 'N') = 'S' THEN
      -- Tarefa 28810
      IF nvl(p_comissaorcatipovenda, 'N') = 'S' THEN
        IF p_tipovenda = 'VV' THEN
          vnpercom := p_percent;
        ELSIF p_tipovenda = 'VP' THEN
          vnpercom := p_percent2;
        END IF;
      ELSIF p_percent2 IS NOT NULL THEN
        vnpercom := p_percent2;
      END IF;
    END IF;
    --Por plano de pagamento/Linha de produto
    IF nvl(p_usacomissaoporlinhaprod, 'N') = 'S' THEN
      SELECT COUNT(*)
        INTO vicont
        FROM pcplpagi
       WHERE pcplpagi.codplpag = p_codplpag
         AND pcplpagi.codlinhaprod = p_codlinhaprod;
      IF vicont <> 0 THEN
        SELECT nvl(pcplpagi.perccomiss, 0) perccomiss
          INTO vnpercom
          FROM pcplpagi
         WHERE pcplpagi.codplpag = p_codplpag
           AND pcplpagi.codlinhaprod = p_codlinhaprod;
      END IF;
    END IF;
    --Por Faixa de Desconto
    SELECT COUNT(*)
      INTO vicont
      FROM pctabcomiss
     WHERE p_perdesc BETWEEN pctabcomiss.percdescini AND
           pctabcomiss.percdescfim;
    IF vicont <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    pctabcomiss.percomint,
                    'E',
                    pctabcomiss.percomext,
                    'R',
                    pctabcomiss.percomrep,
                    0) percom
        INTO vnpercom
        FROM pctabcomiss
       WHERE p_perdesc BETWEEN pctabcomiss.percdescini AND
             pctabcomiss.percdescfim
         AND rownum = 1
    ORDER BY decode(p_tipovend,
                    'I',
                    pctabcomiss.percomint,
                    'E',
                    pctabcomiss.percomext,
                    'R',
                    pctabcomiss.percomrep,
                    0);
    END IF;
    --tarefa 41489
    SELECT COUNT(*)
      INTO vitabcomiss
      FROM pctabcomiss
     WHERE pctabcomiss.tipoapliccomiss = 'L'
       AND pctabcomiss.percdescini <= p_perluc
       AND pctabcomiss.percdescfim >= p_perluc;
    IF vitabcomiss <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    pctabcomiss.percomint,
                    'E',
                    pctabcomiss.percomext,
                    'R',
                    pctabcomiss.percomrep,
                    0) percom,
             letracomiss
        INTO vnpercom, vsletracomiss
        FROM pctabcomiss
       WHERE pctabcomiss.tipoapliccomiss = 'L'
         AND pctabcomiss.percdescini <= p_perluc
         AND pctabcomiss.percdescfim >= p_perluc
         AND rownum = 1
    ORDER BY decode(p_tipovend,
                    'I',
                    pctabcomiss.percomint,
                    'E',
                    pctabcomiss.percomext,
                    'R',
                    pctabcomiss.percomrep,
                    0);
    ELSE
      SELECT COUNT(*)
        INTO vitabcomiss
        FROM pctabcomiss
       WHERE pctabcomiss.tipoapliccomiss <> 'L'
         AND pctabcomiss.percdescini <= p_perdesc
         AND pctabcomiss.percdescfim >= p_perdesc;
      IF vitabcomiss <> 0 THEN
        SELECT decode(p_tipovend,
                      'I',
                      pctabcomiss.percomint,
                      'E',
                      pctabcomiss.percomext,
                      'R',
                      pctabcomiss.percomrep,
                      0) percom
          INTO vnpercom
          FROM pctabcomiss
         WHERE pctabcomiss.tipoapliccomiss <> 'L'
           AND pctabcomiss.percdescini <= p_perdesc
           AND pctabcomiss.percdescfim >= p_perdesc
           AND rownum = 1
      ORDER BY decode(p_tipovend,
                      'I',
                      pctabcomiss.percomint,
                      'E',
                      pctabcomiss.percomext,
                      'R',
                      pctabcomiss.percomrep,
                      0);
        vsletracomiss := NULL;
      END IF;
    END IF;

    --Tarefa 21265: Por Faixa de Desconto por RCA
    --Por RCA
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND nvl(tipo, 'R') = 'R';
    IF vicont <> 0 THEN
      SELECT MAX(percom)
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND nvl(tipo, 'R') = 'R';
      vsletracomiss := NULL;
    END IF;

    --Por RCA/Departamento
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND codepto = p_codepto
       AND nvl(tipo, 'R') = 'RD';
    IF vicont <> 0 THEN
      SELECT percom
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codepto = p_codepto
         AND nvl(tipo, 'R') = 'RD';
      vsletracomiss := NULL;
    END IF;

    --Por RCA/Seção
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND codsec = p_codsec
       AND nvl(tipo, 'R') = 'RS';
    IF vicont <> 0 THEN
      SELECT percom
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codsec = p_codsec
         AND nvl(tipo, 'R') = 'RS';
      vsletracomiss := NULL;
    END IF;

    --Por RCA/Produto
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND codprod = p_codprod
       AND nvl(tipo, 'R') = 'RP';
    IF vicont <> 0 THEN
      SELECT percom
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codprod = p_codprod
         AND nvl(tipo, 'R') = 'RP';
      vsletracomiss := NULL;
    END IF;

    --Tarefa 21534: Por Faixa de Desconto por Pl. Pagto
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoplpag
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codplpag = p_codplpag
       AND nvl(tipo, 'P') = 'P';
    IF vicont <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    percomint,
                    'E',
                    percomext,
                    'R',
                    percomrep,
                    0) percom
        INTO vnpercom
        FROM pccomissaoplpag
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codplpag = p_codplpag
         AND nvl(tipo, 'P') = 'P';
      vsletracomiss := NULL;
    END IF;
    -- tarefa 40181
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoplpag
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codplpag = p_codplpag
       AND nvl(tipo, 'P') = 'PD'
       AND codepto = p_codepto;
    IF vicont <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    percomint,
                    'E',
                    percomext,
                    'R',
                    percomrep,
                    0) percom
        INTO vnpercom
        FROM pccomissaoplpag
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codplpag = p_codplpag
         AND nvl(tipo, 'P') = 'PD'
         AND codepto = p_codepto;
      vsletracomiss := NULL;
    END IF;
    -- tarefa 40181
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoplpag
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codplpag = p_codplpag
       AND nvl(tipo, 'P') = 'PS'
       AND codsec = p_codsec;
    IF vicont <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    percomint,
                    'E',
                    percomext,
                    'R',
                    percomrep,
                    0) percom
        INTO vnpercom
        FROM pccomissaoplpag
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codplpag = p_codplpag
         AND nvl(tipo, 'P') = 'PS'
         AND codsec = p_codsec;
      vsletracomiss := NULL;
    END IF;
    -- tarefa 40181
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoplpag
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codplpag = p_codplpag
       AND nvl(tipo, 'P') = 'PP'
       AND codprod = p_codprod;
    IF vicont <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    percomint,
                    'E',
                    percomext,
                    'R',
                    percomrep,
                    0) percom
        INTO vnpercom
        FROM pccomissaoplpag
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codplpag = p_codplpag
         AND nvl(tipo, 'P') = 'PP'
         AND codprod = p_codprod;
      vsletracomiss := NULL;
    END IF;

    --tarefa 81820
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoplpag
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND CODPLPAG = P_CODPLPAG
       AND CLASSEPRODUTO = P_CLASSEPRODUTO
       AND NVL(TIPO, 'P') = 'PC';

    IF vicont <> 0 THEN
      SELECT decode(p_tipovend,
                    'I',
                    percomint,
                    'E',
                    percomext,
                    'R',
                    percomrep,
                    0) percom
        INTO vnpercom
        FROM pccomissaoplpag
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CLASSEPRODUTO = P_CLASSEPRODUTO
         AND NVL(TIPO, 'P') = 'PC';

      vsletracomiss := NULL;
    END IF;

    -- Tarefa 22785
    --Por regiao
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoregiao
     WHERE numregiao = p_numregiao
       AND nvl(tipo, 'R') = 'R'
       AND p_perdesc BETWEEN perdescini AND perdescfim
       and (codfilial = p_codfilial or codfilial is null)
       and ((dtinicio <= p_data and dtfim >= p_data) or
           (dtinicio is null and dtfim is null));

    IF vicont <> 0 THEN
      SELECT nvl(decode(tipovendedor,
                        'S',
                        decode(p_tipovend,
                               'I',
                               pccomissaoregiao.percomint,
                               'E',
                               pccomissaoregiao.percomext,
                               'R',
                               pccomissaoregiao.percom,
                               0),
                        pccomissaoregiao.percom),
                 0)
        INTO vnpercom
        FROM pccomissaoregiao
       WHERE numregiao = p_numregiao
         AND nvl(tipo, 'R') = 'R'
         AND p_perdesc BETWEEN perdescini AND perdescfim
         and (codfilial = p_codfilial or codfilial is null)
         and ((dtinicio <= p_data and dtfim >= p_data) or
             (dtinicio is null and dtfim is null))
         and rownum = 1;

      vsletracomiss := NULL;
    END IF;
    -- tarefa 40925
    --Por regiao e departamento
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoregiao
     WHERE numregiao = p_numregiao
       AND nvl(tipo, 'R') = 'RD'
       AND codepto = p_codepto
       AND p_perdesc BETWEEN perdescini AND perdescfim
       and (codfilial = p_codfilial or codfilial is null)
       and ((dtinicio <= p_data and dtfim >= p_data) or
           (dtinicio is null and dtfim is null));

    IF vicont <> 0 THEN
      SELECT nvl(decode(tipovendedor,
                        'S',
                        decode(p_tipovend,
                               'I',
                               pccomissaoregiao.percomint,
                               'E',
                               pccomissaoregiao.percomext,
                               'R',
                               pccomissaoregiao.percom,
                               0),
                        pccomissaoregiao.percom),
                 0)
        INTO vnpercom
        FROM pccomissaoregiao
       WHERE numregiao = p_numregiao
         AND nvl(tipo, 'R') = 'RD'
         AND codepto = p_codepto
         AND p_perdesc BETWEEN perdescini AND perdescfim
         and (codfilial = p_codfilial or codfilial is null)
         and ((dtinicio <= p_data and dtfim >= p_data) or
             (dtinicio is null and dtfim is null))
         and rownum = 1;

      vsletracomiss := NULL;
    END IF;

    --Por regiao e seção
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoregiao
     WHERE numregiao = p_numregiao
       AND nvl(tipo, 'R') = 'RS'
       AND codsec = p_codsec
       AND p_perdesc BETWEEN perdescini AND perdescfim
       and (codfilial = p_codfilial or codfilial is null)
       and ((dtinicio <= p_data and dtfim >= p_data) or
           (dtinicio is null and dtfim is null));

    IF vicont <> 0 THEN
      SELECT nvl(decode(tipovendedor,
                        'S',
                        decode(p_tipovend,
                               'I',
                               pccomissaoregiao.percomint,
                               'E',
                               pccomissaoregiao.percomext,
                               'R',
                               pccomissaoregiao.percom,
                               0),
                        pccomissaoregiao.percom),
                 0)
        INTO vnpercom
        FROM pccomissaoregiao
       WHERE numregiao = p_numregiao
         AND nvl(tipo, 'R') = 'RS'
         AND codsec = p_codsec
         AND p_perdesc BETWEEN perdescini AND perdescfim
         and (codfilial = p_codfilial or codfilial is null)
         and ((dtinicio <= p_data and dtfim >= p_data) or
             (dtinicio is null and dtfim is null))
         and rownum = 1;

      vsletracomiss := NULL;
    END IF;

    --Por produto
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoregiao
     WHERE nvl(tipo, 'R') = 'P'
       AND codprod = p_codprod
       AND p_perdesc BETWEEN perdescini AND perdescfim
       and (codfilial = p_codfilial or codfilial is null)
       and ((dtinicio <= p_data and dtfim >= p_data) or
            (dtinicio is null and dtfim is null));

    IF vicont <> 0 THEN
      SELECT nvl(decode(tipovendedor,
                        'S',
                        decode(p_tipovend,
                               'I',
                               pccomissaoregiao.percomint,
                               'E',
                               pccomissaoregiao.percomext,
                               'R',
                               pccomissaoregiao.percom,
                               0),
                        pccomissaoregiao.percom),
                 0)
        INTO vnpercom
        FROM pccomissaoregiao
       WHERE nvl(tipo, 'R') = 'P'
         AND codprod = p_codprod
         AND p_perdesc BETWEEN perdescini AND perdescfim
         and (codfilial = p_codfilial or codfilial is null)
         and ((dtinicio <= p_data and dtfim >= p_data) or
              (dtinicio is null and dtfim is null))
         and rownum = 1;

      vsletracomiss := NULL;
    END IF;

    --Por regiao e produto
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaoregiao
     WHERE numregiao = p_numregiao
       AND nvl(tipo, 'R') = 'RP'
       AND codprod = p_codprod
       AND p_perdesc BETWEEN perdescini AND perdescfim
       and (codfilial = p_codfilial or codfilial is null)
       and ((dtinicio <= p_data and dtfim >= p_data) or
           (dtinicio is null and dtfim is null));

    IF vicont <> 0 THEN
      SELECT nvl(decode(tipovendedor,
                        'S',
                        decode(p_tipovend,
                               'I',
                               pccomissaoregiao.percomint,
                               'E',
                               pccomissaoregiao.percomext,
                               'R',
                               pccomissaoregiao.percom,
                               0),
                        pccomissaoregiao.percom),
                 0)
        INTO vnpercom
        FROM pccomissaoregiao
       WHERE numregiao = p_numregiao
         AND nvl(tipo, 'R') = 'RP'
         AND codprod = p_codprod
         AND p_perdesc BETWEEN perdescini AND perdescfim
         and (codfilial = p_codfilial or codfilial is null)
         and ((dtinicio <= p_data and dtfim >= p_data) or
             (dtinicio is null and dtfim is null))
         and rownum = 1;

      vsletracomiss := NULL;
    END IF;

    --tarefa 48074
    IF nvl(p_ordemavaliacaocomissaorca, 1) = 2 THEN
      -- Por Rca
      IF nvl(p_usacomissaoporrca, 'N') = 'S' THEN
        -- Tarefa 28810
        IF nvl(p_comissaorcatipovenda, 'N') = 'S' THEN
          IF p_tipovenda = 'VV' THEN
            vnpercom := p_percent;
          ELSIF p_tipovenda = 'VP' THEN
            vnpercom := p_percent2;
          END IF;
        ELSIF p_percent2 IS NOT NULL THEN
          vnpercom := p_percent2;
        END IF;
      END IF;
      -- Por Cliente
      IF nvl(p_usacomissaoporcliente, 'N') = 'S' THEN
        IF p_percomcli IS NOT NULL THEN
          vnpercom := p_percomcli;
        END IF;
      END IF;
    END IF;
    p_letracomiss := vsletracomiss;
    RETURN nvl(vnpercom, 0);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao buscar o percentual de comissao: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN 0;
  END buscapercomissao;

  FUNCTION verificarcotarca -- 5 parametros
  (p_codprod   IN NUMBER,
   p_codusur   IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_mensagem  OUT VARCHAR2
   ) RETURN BOOLEAN IS
    vbresult    BOOLEAN;
    vnqtdisp    NUMBER;
  BEGIN

    vbresult := verificarcotarca(p_codprod,
                                 p_codusur,
                                 p_qtpedida,
                                 p_numregiao,
                                 vnqtdisp, --p_qtdisp,
                                 p_mensagem
                                );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Cota RCA: ' || SQLERRM;
      RETURN FALSE;

  END verificarcotarca;

  FUNCTION verificarcotacliente -- 5 parametros
  (p_codprod   IN NUMBER,
   p_codcli    IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN IS
    vbresult      BOOLEAN;
    vnqtdisp      NUMBER;

  BEGIN

    vbresult := verificarcotacliente(p_codprod,
                                     p_codcli,
                                     p_qtpedida,
                                     p_numregiao,
                                     vnqtdisp, --p_qtdisp,
                                     p_mensagem
                                    );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar cota do cliente:' || SQLERRM;
      RETURN FALSE;

  END verificarcotacliente;

  -- 8 parâmetros
  PROCEDURE Definir_Comissao_por_PCProdut(p_tipovend               in pcusuari.tipovend%type,
                                          p_pcomint1               in pcprodut.pcomint1%type,
                                          P_PCOMEXT1               in pcprodut.pcomext1%type,
                                          P_PCOMREP1               in pcprodut.pcomrep1%type,
                                          p_codprod                in pcprodut.codprod%type,
                                          p_codfilial              in pcfilial.codigo%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number) IS
    vnpercom   number;
    vnPCOMREP1 number;
    vnPCOMINT1 number;
    vnPCOMEXT1 number;
    vicont     number;

  BEGIN

    vicont := 0;

    if (p_TIPOVEND = 'I' and P_PCOMINT1 Is not Null) then

      if P_PCOMINT1 = 0 then
        if P_ConsiderarComissaoZero = 'S' then
          vnPERCOM := P_PCOMINT1;
        end if;

      else
        vnPERCOM := P_PCOMINT1;
      end if;

    else
      if P_TIPOVEND = 'E' and P_PCOMEXT1 is not null then

        if P_PCOMEXT1 = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            vnPERCOM := p_PCOMEXT1;
          end if;

        else
          vnPERCOM := P_PCOMEXT1;
        end if;

      else
        if P_TIPOVEND = 'R' and P_PCOMREP1 is not null then

          if P_PCOMREP1 = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              vnPERCOM := P_PCOMREP1;
            end if;

          else
            vnPERCOM := P_PCOMREP1;
          end if;

          --  else
          --  vnPERCOM := 0;
        end if;
      end if;
    end if;

    --Opcional por Filial

    select count(*)
      into vicont
      from pcprodfilial p
     where p.codprod = p_codprod
       and p.codfilial = p_codfilial;

    if vicont > 0 then

      begin
        select PCOMREP1, PCOMINT1, PCOMEXT1
          into vnPCOMREP1, vnPCOMINT1, vnPCOMEXT1
          from pcprodfilial p
         where p.codprod = p_codprod
           and p.codfilial = p_codfilial;
      exception
        when others then
          vnPCOMREP1 := 0;
          vnPCOMINT1 := 0;
          vnPCOMEXT1 := 0;
      end;

      if (p_TIPOVEND = 'I' and vnPCOMINT1 Is not Null) then

        if vnPCOMINT1 = 0 then
          if P_ConsiderarComissaoZero = 'S' then
            vnPERCOM := vnPCOMINT1;
          end if;

        else
          vnPERCOM := vnPCOMINT1;
        end if;

      else
        if P_TIPOVEND = 'E' and vnPCOMEXT1 is not null then

          if vnPCOMEXT1 = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              vnPERCOM := vnPCOMEXT1;
            end if;

          else
            vnPERCOM := vnPCOMEXT1;
          end if;

        else
          if P_TIPOVEND = 'R' and vnPCOMREP1 is not null then

            if vnPCOMREP1 = 0 then

              if p_ConsiderarComissaoZero = 'S' then
                vnPERCOM := vnPCOMREP1;
              end if;

            else
              vnPERCOM := vnPCOMREP1;
            end if;

            -- else
            -- vnPERCOM := 0;
          end if;
        end if;
      end if;

    end if;

    p_percom := vnpercom;

  END;

  -- 6 parâmetros
  procedure Definir_Comissao_por_PCClient(p_usacomissaoporcliente  in pcconsum.usacomissaoporcliente%type,
                                          p_percomcli              in pcclient.percomcli%type,
                                          p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                          p_codcli                 in pcclient.codcli%type,
                                          p_codfilial              in pcfilial.codigo%type,
                                          p_PerCom                 out number) IS

    vnpercom    number;
    vicont      number;
    vnpercomcli number;
  begin

    if p_USACOMISSAOPORCLIENTE = 'S' and p_PERCOMCLI is not null then
      if p_PERCOMCLI = 0 then

        if p_ConsiderarComissaoZero = 'S' then
          vnPERCOM := p_PERCOMCLI;
        end if;

      else
        vnPERCOM := p_PERCOMCLI;
      end if;
    end if;

    --Opcional por Filial

    select count(*)
      into vicont
      from pcclientfilial
     where codcli = p_codcli
       and codfilial = p_Codfilial;

    if vicont > 0 then

      begin

        select percomcli
          into vnpercomcli
          from pcclientfilial
         where codcli = p_codcli
           and codfilial = p_Codfilial;
      exception
        when others then
          vnpercomcli := 0;
      end;

    if vnpercomcli is not null then
      if vnPERCOMCLI = 0 then

        if p_ConsiderarComissaoZero = 'S' then
          vnPERCOM := vnPERCOMCLI;
        end if;

      else
        vnPERCOM := vnPERCOMCLI;
      end if;
    end if;

    end if;

    p_percom := vnpercom;

  end;

  -- 36 parâmetros
  FUNCTION Definir_Comissao_Item_Vendido(p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_UsaPCComissaoFilial       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_codcli                    in pcclient.codcli%type,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2)
    RETURN NUMBER IS

    vnpercom       number;
    vbUsaPCComissaofilial BOOLEAN;

  begin
    vnPerCom := 0;
    vbUsaPCComissaofilial := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_BROKER',p_codfilial,'N') = 'S');

    vnpercom := Definir_Comissao_Item_Vendido(p_NumRegiao,
                                              p_perluc,
                                              p_perdesc,
                                              p_UsaPcTabComiss,
                                              p_UsaPcComissaoUsur,
                                              p_UsaPCComissaoPlPag,
                                              p_UsaPCComissaoRegiao,
                                              vbUsaPCComissaofilial,
                                              p_usacomissaoporrca,
                                              p_OrdemAvaliacaoComissaoRCA,
                                              p_usacomissaoporcliente,
                                              p_USACOMISSAOPORLINHAPROD,
                                              p_comissaorcatipovenda,
                                              p_tipovend,
                                              p_percent,
                                              p_percent2,
                                              p_codprod,
                                              p_pcomint1,
                                              P_PCOMEXT1,
                                              P_PCOMREP1,
                                              p_codlinhaprod,
                                              p_tipocomissao,
                                              p_codepto,
                                              p_codsec,
                                              p_classeproduto,
                                              p_tipovenda,
                                              p_codplpag,
                                              p_data,
                                              p_codfilial,
                                              p_codusur,
                                              p_considerarcomissaozero,
                                              p_tipoavaliacaocomissao,
                                              p_percomcli,
                                              p_codcli,
                                              0, --p_coddesconto,
                                              p_LetraComiss,
                                              p_mensagem
                                             );

    RETURN vnPerCom;

  exception
    when others then
      p_mensagem := 'Erro ao calcular comissao : ' || SQLERRM;
      RETURN 0;

  end;

  function verificabloqueio(p_numped            in pcpedc.numped%type,
                            p_codcli            in pcclient.codcli%type,
                            p_codpraca          in pcclient.codpraca%type,
                            p_condvenda         in pcpedc.condvenda%type,
                            p_Codplpag          in pcpedc.codplpag%type,
                            p_Codcob            in pcpedc.codcob%type,
                            p_clientemonitorado in pcclient.clientemonitorado%type,
                            p_Codmotivo         out pcbloqueio.codmotivo%type,
                            p_Codmotbloqueio    out pcbloqueio.codmotbloqueio%type,
                            p_log               out pcpedc.log%type)
    return boolean is

    vicont   number;
    vbvalido boolean;
    vslog    clob;

  begin

    vbvalido := false;

    for reg_bloq in (SELECT CODMOTBLOQUEIO,
                            CODMOTIVO,
                            (SELECT UPPER(descricao)
                               FROM pcmotbloqueio
                              WHERE codmotivo = PCBLOQUEIO.CODMOTIVO) descricao
                       FROM PCBLOQUEIO
                      WHERE ((CodProd IS NULL) OR
                            (CodProd IN
                            (SELECT CodProd
                                 FROM PCPEDI
                                WHERE NUMPED = p_numped)))
                        AND (CODCLI = p_codcli or codcli is null)
                        AND (CONDVENDA = p_CONDVENDA or condvenda is null)
                        AND (CODPRACA = p_CODPRACA or codpraca is null)
                        AND (CODPLPAG = p_codplpag or codplpag is null)
                        AND (CODCOB = p_CODCOB or codcob is null)
                        AND ((NVL(pcbloqueio.clientemonitorado, 'N') = 'N') OR
                            ((pcbloqueio.clientemonitorado = 'S') AND
                            (p_clientemonitorado = 'S')))
                      ORDER BY CODMOTBLOQUEIO) loop

      p_codmotivo      := reg_bloq.CODMOTIVO;
      p_codmotbloqueio := reg_bloq.CODMOTBLOQUEIO;
      vslog            := vslog || CHR(13) || reg_bloq.descricao;

      vbvalido := true;

    end loop;

    if vbvalido = true then
      p_log := vslog;

    end if;

    return vbvalido;

  end; --verificabloqueio

  FUNCTION validarpoliticasdesconto -- 21 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2) RETURN BOOLEAN IS

    vbresult             BOOLEAN;
    vsalteraptabela      VARCHAR2(1);

  BEGIN

    vbresult := validarpoliticasdesconto(--22 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         p_prioritaria,
                                         p_questionausoprioritaria,
                                         vsalteraptabela
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION validardescontoquantidade -- 17 parametros
  (p_tipoteste            IN NUMBER,
   p_codprod              IN NUMBER,
   p_qtde                 IN NUMBER,
   p_numregiao            IN NUMBER,
   p_ptabela              IN NUMBER,
   p_pvenda1              IN NUMBER,
   p_codpraca             IN NUMBER,
   p_numcasasdecvenda     IN NUMBER,
   p_numdias              IN NUMBER,
   p_tipodesconto         IN VARCHAR2,
   p_dtfim                OUT DATE,
   p_mensagem             OUT VARCHAR2,
   p_ptabeladesc          OUT NUMBER,
   p_creditasobreptabela  OUT VARCHAR2,
   p_perdescflex          OUT NUMBER,
   p_prioritaria          out varchar2,
   p_questionaprioritaria out varchar2) RETURN BOOLEAN IS
    vbresult               BOOLEAN;
    vsbasedebcredrca       VARCHAR2(1);
    vnpercbaserca          NUMBER;

  BEGIN
    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_numdias,
                                          p_tipodesconto,
                                          0, --p_codprodprinc,
                                          0, --p_codcli,
                                          0, --p_codusur,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc,
                                          p_creditasobreptabela,
                                          p_perdescflex,
                                          vsbasedebcredrca,
                                          vnpercbaserca,
                                          NULL --p_codfilial
                                         );

    p_prioritaria := NULL;
    p_questionaprioritaria := NULL;

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;
  END validardescontoquantidade;

  FUNCTION validarpoliticasdesconto -- 22 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_alteraptabela            out varchar2) RETURN BOOLEAN IS

    vbresult       BOOLEAN;
    vnpbaserca     NUMBER;

  BEGIN

    vbresult := validarpoliticasdesconto(--23 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         p_prioritaria,
                                         p_questionausoprioritaria,
                                         p_alteraptabela,
                                         vnpbaserca
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION verificacampanhasdesconto(p_numped        in pcpedc.numped%type,
                                     p_codfilial     in pcpedc.codfilial%type,
                                     p_numregiao     in pcpedc.numregiao%type,
                                     p_codcli        in pcpedc.codcli%type,
                                     p_codativ       in pcclient.codatv1%type,
                                     p_codcliprinc   in pcclient.codcliprinc%type,
                                     p_codusur       in pcpedc.codusur%type,
                                     p_codsupervisor in pcpedc.codsupervisor%type,
                                     p_coddistrib    in pcpedc.coddistrib%type,
                                     p_pertxfim      in pcplpag.pertxfim%type,
                                     p_codcombo      in pcdescontoc.codigo%type,
                                     p_mensagem      out varchar2,
                                     p_codplpag      in pcpedc.codplpag%type default 0)
    return boolean is
 BEGIN

    return PKG_CAMPANHACOMBO.VerificaCampanhasDesconto(p_numped,

                                                       p_codfilial,
                                                       p_numregiao,
                                                       p_codcli,
                                                       p_codativ,
                                                       p_codusur,
                                                       p_codsupervisor,
                                                       p_coddistrib,
                                                       p_codcombo,
                                                       p_mensagem,
                                                       p_codplpag);

 END verificacampanhasdesconto;

  FUNCTION validarpoliticaprecofixo -- 28 parametros ou mais
  (p_codprod                 IN NUMBER,
   p_data                    IN DATE,
   p_numregiao               IN NUMBER,
   p_codcli                  IN NUMBER,
   p_condvenda               IN NUMBER,
   p_codplpag                IN NUMBER,
   p_ptabela                 IN NUMBER,
   p_validapvendabonific     IN VARCHAR2,
   p_utilizapercfinprecoprom IN VARCHAR2,
   p_pertxfim                IN NUMBER,
   p_numdias                 IN NUMBER,
   p_codcliprinc             IN NUMBER,
   p_codprodprinc            IN NUMBER,
   p_codpraca                IN NUMBER,
   p_codusur                 IN NUMBER,
   p_codsupervisor           IN NUMBER,
   p_numlote                 IN VARCHAR2,
   p_origemped               IN VARCHAR2,
   p_codativ                 in pcclient.codatv1%type,
   p_dtfim                   OUT DATE,
   p_mensagem                OUT VARCHAR2,
   p_precofixo               OUT NUMBER,
   p_codfilial               in pcfilial.codigo%type default '',
   p_validarprecovendatv20   in varchar2  default 'S',
   p_broker                  in varchar2  default 'N',
   p_utilizavendaporfilial   in varchar2 default 'N',
   p_precoporfilial          in varchar2 default 'N',
   p_codauxiliar             in varchar2 default NULL) RETURN BOOLEAN IS
    vbresult        BOOLEAN;
    vicont          NUMBER;
    vnprecofixotemp NUMBER;
    vscodfilial   pcfilial.codigo%type;

    vncodrede                 pcclient.codrede%type;
    vsclassevenda             pcclient.classevenda%type;
    vsutilizaembalagem        varchar2(1);
    vconsideraprecosemimposto varchar2(1);

  BEGIN
    vbresult := validarpoliticaprecofixo(p_codprod                 ,
                                         p_data                    ,
                                         p_numregiao               ,
                                         p_codcli                  ,
                                         p_condvenda               ,
                                         p_codplpag                ,
                                         p_ptabela                 ,
                                         p_validapvendabonific     ,
                                         p_utilizapercfinprecoprom ,
                                         p_pertxfim                ,
                                         p_numdias                 ,
                                         p_codcliprinc             ,
                                         p_codprodprinc            ,
                                         p_codpraca                ,
                                         p_codusur                 ,
                                         p_codsupervisor           ,
                                         p_numlote                 ,
                                         p_origemped               ,
                                         p_codativ                 ,
                                         p_dtfim                   ,
                                         p_mensagem                ,
                                         p_precofixo               ,
                                         p_codfilial               ,
                                         p_validarprecovendatv20   ,
                                         p_broker                  ,
                                         p_utilizavendaporfilial   ,
                                         p_precoporfilial          ,
                                         p_codauxiliar             ,
                                         vconsideraprecosemimposto);
      return vbresult;
  END validarpoliticaprecofixo;

  FUNCTION validarpoliticaprecofixo -- 29 parametros ou mais
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_condvenda                IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_ptabela                  IN NUMBER,
   p_validapvendabonific      IN VARCHAR2,
   p_utilizapercfinprecoprom  IN VARCHAR2,
   p_pertxfim                 IN NUMBER,
   p_numdias                  IN NUMBER,
   p_codcliprinc              IN NUMBER,
   p_codprodprinc             IN NUMBER,
   p_codpraca                 IN NUMBER,
   p_codusur                  IN NUMBER,
   p_codsupervisor            IN NUMBER,
   p_numlote                  IN VARCHAR2,
   p_origemped                IN VARCHAR2,
   p_codativ                  in pcclient.codatv1%type,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_precofixo                OUT NUMBER,
   p_codfilial                in pcfilial.codigo%type default '',
   p_validarprecovendatv20    in varchar2  default 'S',
   p_broker                   in varchar2  default 'N',
   p_utilizavendaporfilial    in varchar2 default 'N',
   p_precoporfilial           in varchar2 default 'N',
   p_codauxiliar              in varchar2 default NULL,
   p_consideraprecosemimposto out varchar2) RETURN BOOLEAN IS
    vbresult        BOOLEAN;
    vicont          NUMBER;
    vnprecofixotemp NUMBER;
    vscodfilial   pcfilial.codigo%type;

    vncodrede                 pcclient.codrede%type;
    vsclassevenda             pcclient.classevenda%type;
    vsutilizaembalagem        varchar2(1);

  BEGIN
    --Inicializar variáveis
    vbresult        := FALSE;
    vnprecofixotemp := NULL;
    vsclassevenda := null;

    if p_codfilial = '' then

       vscodfilial := null;
    else
       vscodfilial := p_codfilial;

    end if;

    if p_codcli is not null then
      select codrede,classevenda
      into vncodrede,vsclassevenda
      from pcclient
      where codcli = p_codcli;
    end if;


   if p_utilizavendaporfilial = 'S' and p_precoporfilial = 'S' then

      vsutilizaembalagem := 'S';

   else
      vsutilizaembalagem := 'N';
   end if;


    IF (p_condvenda in (1,7,9,14)) OR
       (p_condvenda = 20  and p_validarprecovendatv20 = 'S') OR
       (p_condvenda = 4 and p_broker = 'S') OR
        ((p_validapvendabonific = 'S') AND
       ((p_condvenda in( 5,11))) ) THEN

         SELECT COUNT(*)
          INTO vicont
          FROM pcprecoprom, pcplpag
         WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
           AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
           AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
           AND pcprecoprom.codprod = p_codprod
           AND pcprecoprom.numregiao = p_numregiao
           AND ((((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
           (nvl(pcplpag.numdias, 0) >= p_numdias)) OR
               ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
           ((pcprecoprom.codplpagmax = p_codplpag)))) or NVL(pcprecoprom.codplpagmax, 0) = 0)
           AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
               (pcprecoprom.codusur = p_codusur))
           AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
               (pcprecoprom.codpraca = p_codpraca))
           AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
               (pcprecoprom.codcli = p_codcli))
           AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
               (pcprecoprom.codsupervisor = p_codsupervisor))
           AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
               (pcprecoprom.numlote = p_numlote))
           AND ((pcprecoprom.origemped = p_origemped) OR
               (nvl(pcprecoprom.origemped, 'O') = 'O'))
           AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
               (pcprecoprom.codativ = p_codativ))
           AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
           AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
               (pcprecoprom.codrede = vncodrede))
           AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
           AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                vsutilizaembalagem = 'N')
           AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
           AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
           OR EXISTS (SELECT 1
                        FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                       WHERE PG.CODGRUPO = PP.CODGRUPO
                         AND PG.TIPO = 'CL'
                         AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                         AND PG.CODFILIAL = VSCODFILIAL
                         AND PP.DTEXCLUSAO IS NULL
                         AND PP.CODITEM = P_CODCLI))
           AND (NVL(PCPRECOPROM.PRIORITARIA,'N')= 'S');
        IF vicont <> 0 THEN
          vbresult := TRUE;
          FOR c_comprioridade IN (SELECT pcprecoprom.codprecoprom,
                                   pcprecoprom.precofixo,
                                   pcprecoprom.dtfimvigencia,
                                   pcprecoprom.consideraprecosemimposto
                              FROM pcprecoprom, pcplpag
                             WHERE pcprecoprom.codplpagmax =
                                   pcplpag.codplpag(+)
                               AND pcprecoprom.dtiniciovigencia <=
                                   trunc(SYSDATE)
                               AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                               AND pcprecoprom.codprod = p_codprod
                               AND pcprecoprom.numregiao = p_numregiao
                               AND ((((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                               (nvl(pcplpag.numdias, 0) >= p_numdias)) OR
                               ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                               ((pcprecoprom.codplpagmax = p_codplpag)))) OR  NVL(pcprecoprom.codplpagmax, 0) = 0)

                               AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                   (pcprecoprom.codusur = p_codusur))
                               AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                   (pcprecoprom.codpraca = p_codpraca))
                               AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                   (pcprecoprom.codcli = p_codcli))
                               AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                   (pcprecoprom.codsupervisor =
                                   p_codsupervisor))
                               AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                   (pcprecoprom.numlote = p_numlote))
                               AND ((pcprecoprom.origemped = p_origemped) OR
                                   (nvl(pcprecoprom.origemped, 'O') = 'O'))
                               AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                   (pcprecoprom.codativ = p_codativ))
                               AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                    (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                              AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                   (pcprecoprom.codrede = vncodrede))
                              AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                              AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                   vsutilizaembalagem = 'N')
                              AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                              AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                              OR EXISTS (SELECT 1
                                           FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                          WHERE PG.CODGRUPO = PP.CODGRUPO
                                            AND PG.TIPO = 'CL'
                                            AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                            AND PG.CODFILIAL = VSCODFILIAL
                                            AND PP.DTEXCLUSAO IS NULL
                                            AND PP.CODITEM = P_CODCLI))
                               AND (NVL(PCPRECOPROM.PRIORITARIA,'N')= 'S')
                               ORDER BY PCPRECOPROM.PRECOFIXO
                            )

           LOOP
            IF c_comprioridade.precofixo < vnprecofixotemp OR
               vnprecofixotemp IS NULL THEN
               vnprecofixotemp            := c_comprioridade.precofixo;
               p_dtfim                    := c_comprioridade.dtfimvigencia;
               p_mensagem                 := c_comprioridade.codprecoprom;
               p_consideraprecosemimposto := nvl(c_comprioridade.consideraprecosemimposto, 'N');
            END IF;
          END LOOP;
         ELSE

          SELECT COUNT(*)
            INTO vicont
            FROM pcprecoprom, pcplpag
           WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
             AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
             AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
             AND pcprecoprom.codprod = p_codprod
             AND pcprecoprom.numregiao = p_numregiao
             AND ((((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
             (nvl(pcplpag.numdias, 0) >= p_numdias)) OR
                 ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
             ((pcprecoprom.codplpagmax = p_codplpag)))) or NVL(pcprecoprom.codplpagmax, 0) = 0)
             AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'N'
             AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'N'
             AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                 (pcprecoprom.codusur = p_codusur))
             AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                 (pcprecoprom.codpraca = p_codpraca))
             AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                 (pcprecoprom.codcli = p_codcli))
             AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                 (pcprecoprom.codsupervisor = p_codsupervisor))
             AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                 (pcprecoprom.numlote = p_numlote))
             AND ((pcprecoprom.origemped = p_origemped) OR
                 (nvl(pcprecoprom.origemped, 'O') = 'O'))
             AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                 (pcprecoprom.codativ = p_codativ))
             AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                  (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
             AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                 (pcprecoprom.codrede = vncodrede))
             AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
             AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                  vsutilizaembalagem = 'N')
             AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
             AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
             OR EXISTS (SELECT 1
                          FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                         WHERE PG.CODGRUPO = PP.CODGRUPO
                           AND PG.TIPO = 'CL'
                           AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                           AND PG.CODFILIAL = VSCODFILIAL
                           AND PP.DTEXCLUSAO IS NULL
                           AND PP.CODITEM = P_CODCLI));

          IF vicont <> 0 THEN
            vbresult := TRUE;
            FOR c_semrede IN (SELECT pcprecoprom.codprecoprom,
                                     pcprecoprom.precofixo,
                                     pcprecoprom.dtfimvigencia,
                                     pcprecoprom.consideraprecosemimposto
                                FROM pcprecoprom, pcplpag
                               WHERE pcprecoprom.codplpagmax =
                                     pcplpag.codplpag(+)
                                 AND pcprecoprom.dtiniciovigencia <=
                                     trunc(SYSDATE)
                                 AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                                 AND pcprecoprom.codprod = p_codprod
                                 AND pcprecoprom.numregiao = p_numregiao
                                 AND ((((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                                 (nvl(pcplpag.numdias, 0) >= p_numdias)) OR
                                 ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                                 ((pcprecoprom.codplpagmax = p_codplpag)))) OR  NVL(pcprecoprom.codplpagmax, 0) = 0)
                                 AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'N'
                                 AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                         'N') = 'N'
                                 AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                     (pcprecoprom.codusur = p_codusur))
                                 AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                     (pcprecoprom.codpraca = p_codpraca))
                                 AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                     (pcprecoprom.codcli = p_codcli))
                                 AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                     (pcprecoprom.codsupervisor =
                                     p_codsupervisor))
                                 AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                     (pcprecoprom.numlote = p_numlote))
                                 AND ((pcprecoprom.origemped = p_origemped) OR
                                     (nvl(pcprecoprom.origemped, 'O') = 'O'))
                                 AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                     (pcprecoprom.codativ = p_codativ))
                                 AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                      (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                     (pcprecoprom.codrede = vncodrede))
                                AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                     vsutilizaembalagem = 'N')
                                AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                OR EXISTS (SELECT 1
                                             FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                            WHERE PG.CODGRUPO = PP.CODGRUPO
                                              AND PG.TIPO = 'CL'
                                              AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                              AND PG.CODFILIAL = VSCODFILIAL
                                              AND PP.DTEXCLUSAO IS NULL
                                              AND PP.CODITEM = P_CODCLI))
                                ORDER BY PCPRECOPROM.PRECOFIXO

                              )

             LOOP
              IF c_semrede.precofixo < vnprecofixotemp OR
                 vnprecofixotemp IS NULL THEN
                 vnprecofixotemp            := c_semrede.precofixo;
                 p_dtfim                    := c_semrede.dtfimvigencia;
                 p_mensagem                 := c_semrede.codprecoprom;
                 p_consideraprecosemimposto := nvl(c_semrede.consideraprecosemimposto, 'N');
              END IF;
            END LOOP;
          ELSE
            --Pesquisar preços fixos da rede de clientes
            --> sem plano especificado
            SELECT COUNT(*)
              INTO vicont
              FROM pcprecoprom, pcplpag
             WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
               AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
               AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
               AND pcprecoprom.codprod = p_codprod
               AND pcprecoprom.numregiao = p_numregiao
               AND NVL(pcprecoprom.codplpagmax, 0) = 0
               AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'S'
               AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'N'
               AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                   (pcprecoprom.codusur = p_codusur))
               AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                   (pcprecoprom.codpraca = p_codpraca))
               AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                   (pcprecoprom.codcli = p_codcliprinc))
               AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                   (pcprecoprom.codsupervisor = p_codsupervisor))
               AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                   (pcprecoprom.numlote = p_numlote))
               AND ((pcprecoprom.origemped = p_origemped) OR
                   (nvl(pcprecoprom.origemped, 'O') = 'O'))
               AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                   (pcprecoprom.codativ = p_codativ))
               AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                   (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
               AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                    (pcprecoprom.codrede = vncodrede))
               AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
               AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                 vsutilizaembalagem = 'N')
               AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
               AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
             OR EXISTS (SELECT 1
                          FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                         WHERE PG.CODGRUPO = PP.CODGRUPO
                           AND PG.TIPO = 'CL'
                           AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                           AND PG.CODFILIAL = VSCODFILIAL
                           AND PP.DTEXCLUSAO IS NULL
                           AND PP.CODITEM = P_CODCLI));


            IF vicont <> 0 THEN
              FOR c_comrede IN (SELECT pcprecoprom.codprecoprom,
                                       pcprecoprom.precofixo,
                                       pcprecoprom.dtfimvigencia,
                                       pcprecoprom.consideraprecosemimposto
                                  FROM pcprecoprom, pcplpag
                                 WHERE pcprecoprom.codplpagmax =
                                       pcplpag.codplpag(+)
                                   AND pcprecoprom.dtiniciovigencia <=
                                       trunc(SYSDATE)
                                   AND pcprecoprom.dtfimvigencia >=
                                       trunc(SYSDATE)
                                   AND pcprecoprom.codprod = p_codprod
                                   AND pcprecoprom.numregiao = p_numregiao
                                   AND NVL(pcprecoprom.codplpagmax, 0) = 0
                                   AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'S'
                                   AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                           'N') = 'N'
                                   AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                       (pcprecoprom.codusur = p_codusur))
                                   AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                       (pcprecoprom.codpraca = p_codpraca))
                                   AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                       (pcprecoprom.codcli = p_codcliprinc))
                                   AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                       (pcprecoprom.codsupervisor =
                                       p_codsupervisor))
                                   AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                       (pcprecoprom.numlote = p_numlote))
                                   AND ((pcprecoprom.origemped = p_origemped) OR
                                       (nvl(pcprecoprom.origemped, 'O') = 'O'))
                                   AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                       (pcprecoprom.codativ = p_codativ))
                                   AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                       (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                   AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                        (pcprecoprom.codrede = vncodrede))
                                   AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                   AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                         vsutilizaembalagem = 'N')
                                   AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                   AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                   OR EXISTS (SELECT 1
                                                FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                               WHERE PG.CODGRUPO = PP.CODGRUPO
                                                 AND PG.TIPO = 'CL'
                                                 AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                 AND PG.CODFILIAL = VSCODFILIAL
                                                 AND PP.DTEXCLUSAO IS NULL
                                                 AND PP.CODITEM = P_CODCLI))
                                   ORDER BY PCPRECOPROM.PRECOFIXO
                                   )

               LOOP
                IF c_comrede.precofixo < vnprecofixotemp OR
                   vnprecofixotemp IS NULL THEN
                  vnprecofixotemp            := c_comrede.precofixo;
                  p_dtfim                    := c_comrede.dtfimvigencia;
                  p_mensagem                 := c_comrede.codprecoprom;
                  p_consideraprecosemimposto := nvl(c_comrede.consideraprecosemimposto, 'N');
                END IF;
              END LOOP;
              vbresult := TRUE;
              IF p_utilizapercfinprecoprom = 'S' THEN
                vnprecofixotemp := vnprecofixotemp * (1 + (p_pertxfim / 100));
              END IF;
            ELSE
              --Pesquisar preços fixos da rede de clientes
              --> com plano especificado
              SELECT COUNT(*)
                INTO vicont
                FROM pcprecoprom, pcplpag
               WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
                 AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
                 AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                 AND pcprecoprom.codprod = p_codprod
                 AND pcprecoprom.numregiao = p_numregiao
                 AND (NVL(pcprecoprom.codplpagmax, 0) = 0 or
                     (((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                     (pcplpag.numdias >= p_numdias)) OR
                     ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                     ((pcprecoprom.codplpagmax = p_codplpag)))))
                 AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'S'
                 AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'N'
                 AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                     (pcprecoprom.codusur = p_codusur))
                 AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                     (pcprecoprom.codpraca = p_codpraca))
                 AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                     (pcprecoprom.codcli = p_codcliprinc))
                 AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                     (pcprecoprom.codsupervisor = p_codsupervisor))
                 AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                     (pcprecoprom.numlote = p_numlote))
                 AND ((pcprecoprom.origemped = p_origemped) OR
                     (nvl(pcprecoprom.origemped, 'O') = 'O'))
                 AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                     (pcprecoprom.codativ = p_codativ))
                 AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                      (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                 AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                     (pcprecoprom.codrede = vncodrede))
                 AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                 AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                      vsutilizaembalagem = 'N')
                 AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                 AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                 OR EXISTS (SELECT 1
                              FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                             WHERE PG.CODGRUPO = PP.CODGRUPO
                               AND PG.TIPO = 'CL'
                               AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                               AND PG.CODFILIAL = VSCODFILIAL
                               AND PP.DTEXCLUSAO IS NULL
                               AND PP.CODITEM = P_CODCLI));


              IF vicont <> 0 THEN
                vbresult := TRUE;
                FOR c_comrede2 IN (SELECT pcprecoprom.codprecoprom,
                                          pcprecoprom.precofixo,
                                          pcprecoprom.dtfimvigencia,
                                          pcprecoprom.consideraprecosemimposto
                                     FROM pcprecoprom, pcplpag
                                    WHERE pcprecoprom.codplpagmax =
                                          pcplpag.codplpag(+)
                                      AND pcprecoprom.dtiniciovigencia <=
                                          trunc(SYSDATE)
                                      AND pcprecoprom.dtfimvigencia >=
                                          trunc(SYSDATE)
                                      AND pcprecoprom.codprod = p_codprod
                                      AND pcprecoprom.numregiao = p_numregiao
                                      AND (NVL(pcprecoprom.codplpagmax, 0) = 0 or
                                           (((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                                           (pcplpag.numdias >= p_numdias)) OR
                                           ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                                           ((pcprecoprom.codplpagmax = p_codplpag)))))
                                      AND nvl(pcprecoprom.utilizaprecofixorede,
                                              'N') = 'S'
                                      AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                              'N') = 'N'
                                      AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                          (pcprecoprom.codusur = p_codusur))
                                      AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                          (pcprecoprom.codpraca = p_codpraca))
                                      AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                          (pcprecoprom.codcli = p_codcliprinc))
                                      AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                          (pcprecoprom.codsupervisor =
                                          p_codsupervisor))
                                      AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                          (pcprecoprom.numlote = p_numlote))
                                      AND ((pcprecoprom.origemped = p_origemped) OR
                                          (nvl(pcprecoprom.origemped, 'O') = 'O'))
                                      AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                          (pcprecoprom.codativ = p_codativ))
                                      AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                           (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                      AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                            (pcprecoprom.codrede = vncodrede))
                                     AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                     AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                          vsutilizaembalagem = 'N')
                                     AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                     AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                     OR EXISTS (SELECT 1
                                                  FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                                 WHERE PG.CODGRUPO = PP.CODGRUPO
                                                   AND PG.TIPO = 'CL'
                                                   AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                   AND PG.CODFILIAL = VSCODFILIAL
                                                   AND PP.DTEXCLUSAO IS NULL
                                                   AND PP.CODITEM = P_CODCLI))
                                     ORDER BY PCPRECOPROM.PRECOFIXO
                                     )

                 LOOP
                  IF c_comrede2.precofixo < vnprecofixotemp OR
                     vnprecofixotemp IS NULL THEN
                    vnprecofixotemp            := c_comrede2.precofixo;
                    p_dtfim                    := c_comrede2.dtfimvigencia;
                    p_mensagem                 := c_comrede2.codprecoprom;
                    p_consideraprecosemimposto := nvl(c_comrede2.consideraprecosemimposto, 'N');
                  END IF;
                END LOOP;
              ELSE
                --Pesquisar preços fixos da família de produtos}
                -- sem plano especificado
                -- sem rede de clientes
                SELECT COUNT(*)
                  INTO vicont
                  FROM pcprecoprom, pcplpag
                 WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
                   AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
                   AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                   AND pcprecoprom.codprod = p_codprodprinc
                   AND pcprecoprom.numregiao = p_numregiao
                   AND NVL(pcprecoprom.codplpagmax, 0) = 0
                   AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'N'
                   AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'S'
                   AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                       (pcprecoprom.codusur = p_codusur))
                   AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                       (pcprecoprom.codpraca = p_codpraca))
                   AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                       (pcprecoprom.codcli = p_codcli))
                   AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                       (pcprecoprom.codsupervisor = p_codsupervisor))
                   AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                       (pcprecoprom.numlote = p_numlote))
                   AND ((pcprecoprom.origemped = p_origemped) OR
                       (nvl(pcprecoprom.origemped, 'O') = 'O'))
                   AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                       (pcprecoprom.codativ = p_codativ))
                   AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                       (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                   AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                        (pcprecoprom.codrede = vncodrede))
                   AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                   AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                       vsutilizaembalagem = 'N')
                   AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                   AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                   OR EXISTS (SELECT 1
                                FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                               WHERE PG.CODGRUPO = PP.CODGRUPO
                                 AND PG.TIPO = 'CL'
                                 AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                 AND PG.CODFILIAL = VSCODFILIAL
                                 AND PP.DTEXCLUSAO IS NULL
                                 AND PP.CODITEM = P_CODCLI));


                IF vicont <> 0 THEN
                  FOR c_semrede2 IN (SELECT pcprecoprom.codprecoprom,
                                            pcprecoprom.precofixo,
                                            pcprecoprom.dtfimvigencia,
                                            pcprecoprom.consideraprecosemimposto
                                       FROM pcprecoprom, pcplpag
                                      WHERE pcprecoprom.codplpagmax =
                                            pcplpag.codplpag(+)
                                        AND pcprecoprom.dtiniciovigencia <=
                                            trunc(SYSDATE)
                                        AND pcprecoprom.dtfimvigencia >=
                                            trunc(SYSDATE)
                                        AND pcprecoprom.codprod = p_codprodprinc
                                        AND pcprecoprom.numregiao = p_numregiao
                                        AND NVL(pcprecoprom.codplpagmax, 0) = 0
                                        AND nvl(pcprecoprom.utilizaprecofixorede,
                                                'N') = 'N'
                                        AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                                'N') = 'S'
                                        AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                            (pcprecoprom.codusur = p_codusur))
                                        AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                            (pcprecoprom.codpraca = p_codpraca))
                                        AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                            (pcprecoprom.codcli = p_codcli))
                                        AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                            (pcprecoprom.codsupervisor =
                                            p_codsupervisor))
                                        AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                            (pcprecoprom.numlote = p_numlote))
                                        AND ((pcprecoprom.origemped =
                                            p_origemped) OR
                                            (nvl(pcprecoprom.origemped, 'O') = 'O'))
                                        AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                            (pcprecoprom.codativ = p_codativ))
                                       AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                             (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                       AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                            (pcprecoprom.codrede = vncodrede))
                                       AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                       AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                            vsutilizaembalagem = 'N')
                                       AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                       AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                       OR EXISTS (SELECT 1
                                                    FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                                   WHERE PG.CODGRUPO = PP.CODGRUPO
                                                     AND PG.TIPO = 'CL'
                                                     AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                     AND PG.CODFILIAL = VSCODFILIAL
                                                     AND PP.DTEXCLUSAO IS NULL
                                                     AND PP.CODITEM = P_CODCLI))
                                       ORDER BY PCPRECOPROM.PRECOFIXO
                                       )

                    LOOP

                    IF c_semrede2.precofixo < vnprecofixotemp OR
                       vnprecofixotemp IS NULL THEN
                      vnprecofixotemp := c_semrede2.precofixo;
                      p_dtfim         := c_semrede2.dtfimvigencia;
                      p_mensagem      := c_semrede2.codprecoprom;
                      p_consideraprecosemimposto := nvl(c_semrede2.consideraprecosemimposto, 'N');
                    END IF;
                  END LOOP;
                  vbresult := TRUE;
                  IF p_utilizapercfinprecoprom = 'S' THEN
                    vnprecofixotemp := vnprecofixotemp *
                                       (1 + (p_pertxfim / 100));
                  END IF;
                ELSE
                  --Pesquisar preços fixos da família de produtos}
                  -- com plano especificado
                  -- sem rede de clientes
                  SELECT COUNT(*)
                    INTO vicont
                    FROM pcprecoprom, pcplpag
                   WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
                     AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
                     AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                     AND pcprecoprom.codprod = p_codprodprinc
                     AND pcprecoprom.numregiao = p_numregiao
                     AND (NVL(pcprecoprom.codplpagmax, 0) = 0 or
                         (((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                         (pcplpag.numdias >= p_numdias)) OR
                         ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                         ((pcprecoprom.codplpagmax = p_codplpag)))))
                     AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'N'
                     AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'S'
                     AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                         (pcprecoprom.codusur = p_codusur))
                     AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                         (pcprecoprom.codpraca = p_codpraca))
                     AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                         (pcprecoprom.codcli = p_codcli))
                     AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                         (pcprecoprom.codsupervisor = p_codsupervisor))
                     AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                         (pcprecoprom.numlote = p_numlote))
                     AND ((pcprecoprom.origemped = p_origemped) OR
                         (nvl(pcprecoprom.origemped, 'O') = 'O'))
                     AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                         (pcprecoprom.codativ = p_codativ))
                     AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                         (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                     AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                          (pcprecoprom.codrede = vncodrede))
                     AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                     AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                          vsutilizaembalagem = 'N')
                     AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                     AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                     OR EXISTS (SELECT 1
                                  FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                 WHERE PG.CODGRUPO = PP.CODGRUPO
                                   AND PG.TIPO = 'CL'
                                   AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                   AND PG.CODFILIAL = VSCODFILIAL
                                   AND PP.DTEXCLUSAO IS NULL
                                   AND PP.CODITEM = P_CODCLI));


                  IF vicont <> 0 THEN
                    FOR c_semrede3 IN (SELECT pcprecoprom.codprecoprom,
                                              pcprecoprom.precofixo,
                                              pcprecoprom.dtfimvigencia,
                                              pcprecoprom.consideraprecosemimposto
                                         FROM pcprecoprom, pcplpag
                                        WHERE pcprecoprom.codplpagmax =
                                              pcplpag.codplpag(+)
                                          AND pcprecoprom.dtiniciovigencia <=
                                              trunc(SYSDATE)
                                          AND pcprecoprom.dtfimvigencia >=
                                              trunc(SYSDATE)
                                          AND pcprecoprom.codprod =
                                              p_codprodprinc
                                          AND pcprecoprom.numregiao =
                                              p_numregiao
                                          AND (NVL(pcprecoprom.codplpagmax, 0) = 0 or
                                               (((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                                               (pcplpag.numdias >= p_numdias)) OR
                                               ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                                               ((pcprecoprom.codplpagmax = p_codplpag)))))
                                          AND nvl(pcprecoprom.utilizaprecofixorede,
                                                  'N') = 'N'
                                          AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                                  'N') = 'S'
                                          AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                              (pcprecoprom.codusur = p_codusur))
                                          AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                              (pcprecoprom.codpraca =
                                              p_codpraca))
                                          AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                              (pcprecoprom.codcli = p_codcli))
                                          AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                              (pcprecoprom.codsupervisor =
                                              p_codsupervisor))
                                          AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                              (pcprecoprom.numlote = p_numlote))
                                          AND ((pcprecoprom.origemped =
                                              p_origemped) OR
                                              (nvl(pcprecoprom.origemped, 'O') = 'O'))
                                          AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                              (pcprecoprom.codativ = p_codativ))
                                         AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                              (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                         AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                               (pcprecoprom.codrede = vncodrede))
                                        AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                        AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                          vsutilizaembalagem = 'N')
                                        AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                        AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                        OR EXISTS (SELECT 1
                                                     FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                                    WHERE PG.CODGRUPO = PP.CODGRUPO
                                                      AND PG.TIPO = 'CL'
                                                      AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                      AND PG.CODFILIAL = VSCODFILIAL
                                                      AND PP.DTEXCLUSAO IS NULL
                                                      AND PP.CODITEM = P_CODCLI))
                                        ORDER BY PCPRECOPROM.PRECOFIXO
                                        )

                      LOOP

                      IF c_semrede3.precofixo < vnprecofixotemp OR
                         vnprecofixotemp IS NULL THEN
                        vnprecofixotemp := c_semrede3.precofixo;
                        p_dtfim         := c_semrede3.dtfimvigencia;
                        p_mensagem      := c_semrede3.codprecoprom;
                        p_consideraprecosemimposto := nvl(c_semrede3.consideraprecosemimposto, 'N');
                      END IF;
                    END LOOP;
                    vbresult := TRUE;
                  ELSE
                    --Pesquisar preços fixos da família de produtos}
                    -- sem plano especificado
                    -- com rede de clientes
                    SELECT COUNT(*)
                      INTO vicont
                      FROM pcprecoprom, pcplpag
                     WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
                       AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
                       AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                       AND pcprecoprom.codprod = p_codprodprinc
                       AND pcprecoprom.numregiao = p_numregiao
                       AND NVL(pcprecoprom.codplpagmax, 0) = 0
                       AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'S'
                       AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'S'
                       AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                           (pcprecoprom.codusur = p_codusur))
                       AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                           (pcprecoprom.codpraca = p_codpraca))
                       AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                           (pcprecoprom.codcli = p_codcliprinc))
                       AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                           (pcprecoprom.codsupervisor = p_codsupervisor))
                       AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                           (pcprecoprom.numlote = p_numlote))
                       AND ((pcprecoprom.origemped = p_origemped) OR
                           (nvl(pcprecoprom.origemped, 'O') = 'O'))
                       AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                           (pcprecoprom.codativ = p_codativ))
                       AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                         (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                       AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                            (pcprecoprom.codrede = vncodrede))
                       AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                       AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                            vsutilizaembalagem = 'N')
                       AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                       AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                       OR EXISTS (SELECT 1
                                    FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                   WHERE PG.CODGRUPO = PP.CODGRUPO
                                     AND PG.TIPO = 'CL'
                                     AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                     AND PG.CODFILIAL = VSCODFILIAL
                                     AND PP.DTEXCLUSAO IS NULL
                                     AND PP.CODITEM = P_CODCLI));


                    IF vicont <> 0 THEN
                      FOR c_comrede3 IN (SELECT pcprecoprom.codprecoprom,
                                                pcprecoprom.precofixo,
                                                pcprecoprom.dtfimvigencia,
                                                pcprecoprom.consideraprecosemimposto
                                           FROM pcprecoprom, pcplpag
                                          WHERE pcprecoprom.codplpagmax =
                                                pcplpag.codplpag(+)
                                            AND pcprecoprom.dtiniciovigencia <=
                                                trunc(SYSDATE)
                                            AND pcprecoprom.dtfimvigencia >=
                                                trunc(SYSDATE)
                                            AND pcprecoprom.codprod =
                                                p_codprodprinc
                                            AND pcprecoprom.numregiao =
                                                p_numregiao
                                            AND NVL(pcprecoprom.codplpagmax, 0) = 0
                                            AND nvl(pcprecoprom.utilizaprecofixorede,
                                                    'N') = 'S'
                                            AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                                    'N') = 'S'
                                            AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                                (pcprecoprom.codusur =
                                                p_codusur))
                                            AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                                (pcprecoprom.codpraca =
                                                p_codpraca))
                                            AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                                (pcprecoprom.codcli =
                                                p_codcliprinc))
                                            AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                                (pcprecoprom.codsupervisor =
                                                p_codsupervisor))
                                            AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                                (pcprecoprom.numlote =
                                                p_numlote))
                                            AND ((pcprecoprom.origemped =
                                                p_origemped) OR
                                                (nvl(pcprecoprom.origemped, 'O') = 'O'))
                                            AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                                (pcprecoprom.codativ =
                                                p_codativ))
                                            AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                                 (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                            AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                                   (pcprecoprom.codrede = vncodrede))
                                            AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                            AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                                  vsutilizaembalagem = 'N')
                                            AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                            AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                            OR EXISTS (SELECT 1
                                                         FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                                        WHERE PG.CODGRUPO = PP.CODGRUPO
                                                          AND PG.TIPO = 'CL'
                                                          AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                          AND PG.CODFILIAL = VSCODFILIAL
                                                          AND PP.DTEXCLUSAO IS NULL
                                                          AND PP.CODITEM = P_CODCLI))
                                            ORDER BY PCPRECOPROM.PRECOFIXO
                                            )

                        LOOP

                        IF c_comrede3.precofixo < vnprecofixotemp OR
                           vnprecofixotemp IS NULL THEN
                          vnprecofixotemp            := c_comrede3.precofixo;
                          p_dtfim                    := c_comrede3.dtfimvigencia;
                          p_mensagem                 := c_comrede3.codprecoprom;
                          p_consideraprecosemimposto := nvl(c_comrede3.consideraprecosemimposto, 'N');
                        END IF;
                      END LOOP;
                      vbresult := TRUE;
                      IF p_utilizapercfinprecoprom = 'S' THEN
                        vnprecofixotemp := vnprecofixotemp *
                                           (1 + (p_pertxfim / 100));
                      END IF;
                    ELSE
                      --Pesquisar preços fixos da família de produtos
                      -- com plano especificado
                      -- com rede de clientes
                      SELECT COUNT(*)
                        INTO vicont
                        FROM pcprecoprom, pcplpag
                       WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
                         AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
                         AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                         AND pcprecoprom.codprod = p_codprodprinc
                         AND pcprecoprom.numregiao = p_numregiao
                         AND (NVL(pcprecoprom.codplpagmax, 0) = 0 or
                             (((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                             (pcplpag.numdias >= p_numdias)) OR
                             ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                             ((pcprecoprom.codplpagmax = p_codplpag)))))
                         AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'S'
                         AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'S'
                         AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                             (pcprecoprom.codusur = p_codusur))
                         AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                             (pcprecoprom.codpraca = p_codpraca))
                         AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                             (pcprecoprom.codcli = p_codcliprinc))
                         AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                             (pcprecoprom.codsupervisor = p_codsupervisor))
                         AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                             (pcprecoprom.numlote = p_numlote))
                         AND ((pcprecoprom.origemped = p_origemped) OR
                             (nvl(pcprecoprom.origemped, 'O') = 'O'))
                         AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                             (pcprecoprom.codativ = p_codativ))
                         AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                              (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                         AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                              (pcprecoprom.codrede = vncodrede))
                         AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                         AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR vsutilizaembalagem = 'N')
                         AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                         AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                         OR EXISTS (SELECT 1
                                      FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                     WHERE PG.CODGRUPO = PP.CODGRUPO
                                       AND PG.TIPO = 'CL'
                                       AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                       AND PG.CODFILIAL = VSCODFILIAL
                                       AND PP.DTEXCLUSAO IS NULL
                                       AND PP.CODITEM = P_CODCLI));

                      IF vicont <> 0 THEN
                        vbresult := TRUE;
                        FOR c_comrede4 IN (SELECT pcprecoprom.codprecoprom,
                                                  pcprecoprom.precofixo,
                                                  pcprecoprom.dtfimvigencia,
                                                  pcprecoprom.consideraprecosemimposto
                                             FROM pcprecoprom, pcplpag
                                            WHERE pcprecoprom.codplpagmax =
                                                  pcplpag.codplpag(+)
                                              AND pcprecoprom.dtiniciovigencia <=
                                                  trunc(SYSDATE)
                                              AND pcprecoprom.dtfimvigencia >=
                                                  trunc(SYSDATE)
                                              AND pcprecoprom.codprod =
                                                  p_codprodprinc
                                              AND pcprecoprom.numregiao =
                                                  p_numregiao
                                              AND (NVL(pcprecoprom.codplpagmax, 0) = 0 or
                                                   (((nvl(pcprecoprom.apenasplpagmax, 'N') = 'N') AND
                                                   (pcplpag.numdias >= p_numdias)) OR
                                                   ((nvl(pcprecoprom.apenasplpagmax, 'N') = 'S') AND
                                                   ((pcprecoprom.codplpagmax = p_codplpag)))))
                                              AND nvl(pcprecoprom.utilizaprecofixorede,
                                                      'N') = 'S'
                                              AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                                      'N') = 'S'
                                              AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                                  (pcprecoprom.codusur =
                                                  p_codusur))
                                              AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                                  (pcprecoprom.codpraca =
                                                  p_codpraca))
                                              AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                                  (pcprecoprom.codcli =
                                                  p_codcliprinc))
                                              AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                                  (pcprecoprom.codsupervisor =
                                                  p_codsupervisor))
                                              AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                                  (pcprecoprom.numlote =
                                                  p_numlote))
                                              AND ((pcprecoprom.origemped =
                                                  p_origemped) OR
                                                  (nvl(pcprecoprom.origemped,
                                                        'O') = 'O'))
                                              AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                                  (pcprecoprom.codativ =
                                                  p_codativ))
                                              AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                                   (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                              AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                                   (pcprecoprom.codrede = vncodrede))
                                              AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                              AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                                  vsutilizaembalagem = 'N')
                                              AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                              AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                              OR EXISTS (SELECT 1
                                                           FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                                          WHERE PG.CODGRUPO = PP.CODGRUPO
                                                            AND PG.TIPO = 'CL'
                                                            AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                            AND PG.CODFILIAL = VSCODFILIAL
                                                            AND PP.DTEXCLUSAO IS NULL
                                                            AND PP.CODITEM = P_CODCLI))
                                              ORDER BY PCPRECOPROM.PRECOFIXO
                                              )

                          LOOP

                          IF c_comrede4.precofixo < vnprecofixotemp OR
                             vnprecofixotemp IS NULL THEN
                            vnprecofixotemp            := c_comrede4.precofixo;
                            p_dtfim                    := c_comrede4.dtfimvigencia;
                            p_mensagem                 := c_comrede4.codprecoprom;
                            p_consideraprecosemimposto := nvl(c_comrede4.consideraprecosemimposto, 'N');
                          END IF;
                        END LOOP;
                      ELSE
                        SELECT COUNT(*)
                          INTO vicont
                          FROM pcprecoprom, pcplpag
                         WHERE pcprecoprom.codplpagmax = pcplpag.codplpag(+)
                           AND pcprecoprom.dtiniciovigencia <= trunc(SYSDATE)
                           AND pcprecoprom.dtfimvigencia >= trunc(SYSDATE)
                           AND pcprecoprom.codprod = p_codprod
                           AND pcprecoprom.numregiao = p_numregiao
                           AND NVL(pcprecoprom.codplpagmax, 0) = 0
                           AND nvl(pcprecoprom.utilizaprecofixorede, 'N') = 'N'
                           AND nvl(pcprecoprom.utilizaprecofixofamilia, 'N') = 'N'
                           AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                               (pcprecoprom.codusur = p_codusur))
                           AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                               (pcprecoprom.codpraca = p_codpraca))
                           AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                               (pcprecoprom.codcli = p_codcli))
                           AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                               (pcprecoprom.codsupervisor = p_codsupervisor))
                           AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                               (pcprecoprom.numlote = p_numlote))
                           AND ((pcprecoprom.origemped = p_origemped) OR
                               (nvl(pcprecoprom.origemped, 'O') = 'O'))
                           AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                               (pcprecoprom.codativ = p_codativ))
                           AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                           AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                (pcprecoprom.codrede = vncodrede))
                           AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                           AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                vsutilizaembalagem = 'N')
                           AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                           AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                           OR EXISTS (SELECT 1
                                        FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                       WHERE PG.CODGRUPO = PP.CODGRUPO
                                         AND PG.TIPO = 'CL'
                                         AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                         AND PG.CODFILIAL = VSCODFILIAL
                                         AND PP.DTEXCLUSAO IS NULL
                                         AND PP.CODITEM = P_CODCLI));

                        IF vicont <> 0 THEN
                          FOR c_semrede4 IN (SELECT pcprecoprom.codprecoprom,
                                                    pcprecoprom.precofixo,
                                                    pcprecoprom.dtfimvigencia,
                                                    pcprecoprom.consideraprecosemimposto
                                               FROM pcprecoprom, pcplpag
                                              WHERE pcprecoprom.codplpagmax =
                                                    pcplpag.codplpag(+)
                                                AND pcprecoprom.dtiniciovigencia <=
                                                    trunc(SYSDATE)
                                                AND pcprecoprom.dtfimvigencia >=
                                                    trunc(SYSDATE)
                                                AND pcprecoprom.codprod =
                                                    p_codprod
                                                AND pcprecoprom.numregiao =
                                                    p_numregiao
                                                AND NVL(pcprecoprom.codplpagmax, 0) = 0
                                                AND nvl(pcprecoprom.utilizaprecofixorede,
                                                        'N') = 'N'
                                                AND nvl(pcprecoprom.utilizaprecofixofamilia,
                                                        'N') = 'N'
                                                AND ((NVL(pcprecoprom.codusur, 0) = 0) OR
                                                    (pcprecoprom.codusur =
                                                    p_codusur))
                                                AND ((NVL(pcprecoprom.codpraca, 0) = 0) OR
                                                    (pcprecoprom.codpraca =
                                                    p_codpraca))
                                                AND ((NVL(pcprecoprom.codcli, 0) = 0) OR
                                                    (pcprecoprom.codcli =
                                                    p_codcli))
                                                AND ((NVL(pcprecoprom.codsupervisor, 0) = 0) OR
                                                    (pcprecoprom.codsupervisor =
                                                    p_codsupervisor))
                                                AND ((NVL(pcprecoprom.numlote, 'X') = 'X') OR
                                                    (pcprecoprom.numlote =
                                                    p_numlote))
                                                AND ((pcprecoprom.origemped =
                                                    p_origemped) OR
                                                    (nvl(pcprecoprom.origemped,
                                                          'O') = 'O'))
                                                AND ((NVL(pcprecoprom.codativ, 0) = 0) OR
                                                    (pcprecoprom.codativ =
                                                    p_codativ))
                                               AND ((NVL(pcprecoprom.codfilial, 'X') = 'X' ) OR
                                                     (pcprecoprom.codfilial = nvl(vscodfilial,pcprecoprom.codfilial)))
                                               AND ((NVL(pcprecoprom.codrede, 0) = 0) OR
                                                     (pcprecoprom.codrede = vncodrede))
                                               AND (pcprecoprom.classevenda = vsclassevenda OR NVL(pcprecoprom.classevenda, 'X') = 'X')
                                               AND (vsutilizaembalagem= 'S' and (pcprecoprom.codauxiliar = p_codauxiliar or NVL(pcprecoprom.codauxiliar, 0) = 0) OR
                                                    vsutilizaembalagem = 'N')
                                               AND (NVL(pcprecoprom.enviafv, 'S') = 'S')
                                               AND ((NVL(pcprecoprom.Codgrupocli, 0) = 0)
                                               OR EXISTS (SELECT 1
                                                            FROM PCGRUPOSCAMPANHAC PG, PCGRUPOSCAMPANHAI PP
                                                           WHERE PG.CODGRUPO = PP.CODGRUPO
                                                             AND PG.TIPO = 'CL'
                                                             AND PP.CODGRUPO = PCPRECOPROM.CODGRUPOCLI
                                                             AND PG.CODFILIAL = VSCODFILIAL
                                                             AND PP.DTEXCLUSAO IS NULL
                                                             AND PP.CODITEM = p_codcli))
                                               ORDER BY PCPRECOPROM.PRECOFIXO
                                               )
                                                 LOOP

                            IF c_semrede4.precofixo < vnprecofixotemp OR
                               vnprecofixotemp IS NULL THEN
                              vnprecofixotemp := c_semrede4.precofixo;
                              p_dtfim         := c_semrede4.dtfimvigencia;
                              p_mensagem      := c_semrede4.codprecoprom;
                              p_consideraprecosemimposto := nvl(c_semrede4.consideraprecosemimposto, 'N');
                            END IF;
                          END LOOP;
                          vbresult := TRUE;
                          IF p_utilizapercfinprecoprom = 'S' THEN
                            vnprecofixotemp := vnprecofixotemp *
                                               (1 + (p_pertxfim / 100));
                          END IF;
                        END IF;
                      END IF; --sem familia, sem rede, sem plano
                    END IF; --com familia, com rede, sem plano
                  END IF; --com familia, sem rede, com plano
                END IF; --com familia, sem rede, sem plano
              END IF; --sem familia, com rede, com plano
            END IF; --sem familia, com rede, sem plano
          END IF; --sem familia, sem rede, com plano
        END IF; --Desconsiderando Utiliza preço fixo familia
      END IF; --tipos de venda
    p_precofixo := nvl(vnprecofixotemp, p_ptabela);
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Preco Fixo ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END validarpoliticaprecofixo;

  FUNCTION calculo_preco_sem_impostos --19 parametros

    /**************************************************************************************************
    ---------------------------------------------------------------------------------------------------
    Data            Tarefa   Autor              Descrição
    ---------------------------------------------------------------------------------------------------
    18/01/2010      99625    Zilmar Guimaraes   1) parâmetro percipi deve receber o valor de percipivenda para evitar erro de passagem de parâmetros
                                                2) o parâmetro percbaseredst deve ser tratado caso seja igual a zero deve receber o valor de 100, para que o cálculo não seja influenciado                                                       3) desconciderar o cálculo para variável precofinal, deve ser utilizado o valor do parâmetro pvenda
    28/07/2010     112330    Pablo              Alteração para calcular o preço sem impostos mesmo que não tenha IPI
    08/06/2010     132417    Thiago Alves       Criação de dois novos parâmetros de entrada para retorna preço sem impostos
                                                a partir do pmvc - Preço Máximo Consumidor
    28/09/2012     175195    Thiago Melo        Retirado o variavél "vscalcularstcomipi"
    02/10/2012     175248    Marcos Garcia      Inclusão do parametro de entrada considerarIpiAliqicms2
    26/07/2013     201665    Andréa             Atualização com as novas regras implementadas na procedure interna da 316
    ***************************************************************************************************/
  (percipivenda           IN NUMBER,
   vlpautaipivenda        IN NUMBER,
   vlipiporkgvenda        IN NUMBER,
   pvenda                 IN NUMBER,
   pauta                  IN NUMBER,
   pesobruto              IN NUMBER,
   percdifaliquotas       IN NUMBER,
   percipi                IN OUT NUMBER,
   valorultent            IN NUMBER,
   iva                    IN NUMBER,
   percbaseredst          IN OUT NUMBER,
   aliqicms1              IN NUMBER,
   aliqicms2              IN NUMBER,
   usavalorultentbasest   IN VARCHAR,
   usavalorultentbasest2  IN VARCHAR,
   uf_pcfilial            IN VARCHAR,
   pcclient_estent        IN VARCHAR,
   preco_sem_impostos     OUT NUMBER,
   p_mensagem             OUT VARCHAR2,
   usapmcbasest           IN VARCHAR2 := 'N',
   precomaxconsumidor     IN number := 0,
   considerarIpiAliqicms2 IN VARCHAR2 default 'N',
   usavlultentmediobasest in varchar2 default 'N',
   vlultentmes            in number default 0,
   p_percbasestrj            in pctribut.percbasestrj%type default 0 ,
   p_percredaliqipi          IN NUMBER DEFAULT 0) RETURN BOOLEAN IS

   vnvlultent             pcest.valorultent%type;
    preco_sem_impostos_rj number;
  BEGIN
    IF percbaseredst = 0 THEN
      percbaseredst := 100;
    END IF;

    IF nvl(p_percredaliqipi,0) > 0 THEN
      percipi := percipivenda * (1 - (p_percredaliqipi/100));
    ELSE
      percipi := percipivenda;
    END IF;

    -- 1. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (IVA)
    IF (((percipivenda > 0) OR (percipivenda = 0)) AND
       (vlpautaipivenda = 0) AND (vlipiporkgvenda = 0)) AND (pauta = 0) THEN

      if (NVL(considerarIpiAliqicms2,'N') = 'S') and (NVL(iva, 0) > 0) and (NVL(aliqicms1, 0) > 0) and (NVL(aliqicms2, 0) > 0) then
        preco_sem_impostos := (pvenda / (1 + (NVL(percipi, 0) / 100) +
                              (NVL(percdifaliquotas, 0) / 100) +
                              ((((NVL(aliqicms1, 0) / 100) *
                              (1 + (NVL(iva, 0) / 100)) *
                              (1 + (NVL(percipi, 0) / 100)) *
                              (NVL(percbaseredst, 0) / 100)) -
                              ((NVL(aliqicms2, 0) +
                              (NVL(percipi, 0) / 100)) / 100)))));
      else
        preco_sem_impostos := (pvenda / (1 + (NVL(percipi, 0) / 100) +
                              (NVL(percdifaliquotas, 0) / 100) +
                              ((((NVL(aliqicms1, 0) / 100) *
                              (1 + (NVL(iva, 0) / 100)) *
                              (1 + (NVL(percipi, 0) / 100)) *
                              (NVL(percbaseredst, 0) / 100)) -
                              (NVL(aliqicms2, 0) / 100)))));

      end if;
    END IF;

    -- 2. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (PAUTA)
    IF (((percipivenda > 0) OR (percipivenda = 0)) AND
       (vlpautaipivenda = 0) AND (vlipiporkgvenda = 0)) AND (pauta > 0) THEN

      if (NVL(considerarIpiAliqicms2,'N') = 'S') and (NVL(iva, 0) > 0) and (NVL(aliqicms1, 0) > 0) and (NVL(aliqicms2, 0) > 0) then

        preco_sem_impostos := (pvenda -
                              ((pauta * (NVL(percbaseredst, 0) / 100)) *
                              (NVL(aliqicms1, 0) / 100))) /
                              (1 + (NVL(percdifaliquotas, 0) / 100) +
                              (NVL(percipi, 0) / 100) -
                              (NVL(aliqicms2, 0) / 100) - (nvl(percipi,0)/100)*(nvl(aliqicms2,0)/100));

      else
        preco_sem_impostos := (pvenda -
                              ((pauta * (NVL(percbaseredst, 0) / 100)) *
                              (NVL(aliqicms1, 0) / 100))) /
                              (1 + (NVL(percdifaliquotas, 0) / 100) +
                              (NVL(percipi, 0) / 100) -
                              (NVL(aliqicms2, 0) / 100));
      end if;
    END IF;

    -- 3. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
    IF (((percipivenda > 0) OR (percipivenda = 0)) AND
       (vlpautaipivenda = 0) AND (vlipiporkgvenda = 0)) AND
       (PAUTA = 0) AND
       (usavalorultentbasest = 'S') AND (uf_pcfilial = pcclient_estent) THEN
      preco_sem_impostos := (pvenda -
                            ((valorultent * (1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100)) *
                            (NVL(aliqicms1, 0) / 100))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) +
                            (NVL(percipi, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100) +
                            ((NVL(percipi, 0) / 100) *
                            (1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)));


                            --RAFAEL SOARES  RETIRA IMPOSTO DO PREÇO PARA ST RJ
                            --FOI CRIADO ESTA FUNCIONALIDADE PARA QUANDO O SISTEMA TRABALHAR COM 2% DE ST
                            --INFORMADOS POIS A FUNÇÃO QUE RETIRA IMPOSTOS DO PREÇO É DIFERENTE NESTE CASO
                           if (p_percbasestrj <> 0) and (NVL(aliqicms1, 0) > 0 ) and (NVL(aliqicms2, 0) > 0) then

                               preco_sem_impostos_rj := (pvenda  -  (valorultent*(1+(iva/100))*(percbaseredst/100))*(p_percbasestrj/100))/
                               ((1 + percipi/100 + percdifaliquotas/100)+ ((percipi/100)*(1+iva/100))*(percbaseredst/100)*(p_percbasestrj/100) );

                                --O SISTEMA IDENTICA QUAL PREÇO SEM IMPOSTOS É MENOR, O MENOR PREÇO ENCONTRADO É O PREÇO SEM IMPOSTOS CORRETO
                                -- ISSO SERVE PARA IDENTIFICAR SE QUAL PREÇO CONTA DE RETIRADA DE IMPOSTOS FUI UTILIZADA
                                if (preco_sem_impostos_rj <  preco_sem_impostos) then
                                   preco_sem_impostos := preco_sem_impostos_rj;
                                end if;

                            end if;
    END IF;

    -- 4. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
    IF (((percipivenda > 0) OR (percipivenda = 0)) AND
       (vlpautaipivenda = 0) AND (vlipiporkgvenda = 0)) AND
       (usavalorultentbasest = 'S') AND (usavalorultentbasest2 = 'S') AND
       (uf_pcfilial = pcclient_estent) THEN
      preco_sem_impostos := (pvenda +
                            (valorultent * ((NVL(aliqicms2, 0) / 100) -
                            (1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) +
                            (NVL(percipi, 0) / 100) +
                            ((NVL(percipi, 0) / 100) *
                            (1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)));
    END IF;

    -- 5. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (IVA)
    IF (vlpautaipivenda > 0) AND (pauta = 0) THEN

     if (NVL(considerarIpiAliqicms2,'N') = 'S') and (NVL(iva, 0) > 0) and (NVL(aliqicms1, 0) > 0) and (NVL(aliqicms2, 0) > 0) then

      preco_sem_impostos := (pvenda - (vlpautaipivenda *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100))))+ VlPautaIPIVenda * (nvl(aliqicms2,0)/100) ) /
                            ((1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100)) +
                            ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)));

     else
      preco_sem_impostos := (pvenda - (vlpautaipivenda *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100))))) /
                            ((1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100)) +
                            ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)));
      end if;

    END IF;

    -- 6. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (PAUTA)
    IF (vlpautaipivenda > 0) AND (pauta > 0) THEN

     if (NVL(considerarIpiAliqicms2,'N') = 'S') and (NVL(iva, 0) > 0) and (NVL(aliqicms1, 0) > 0) and (NVL(aliqicms2, 0) > 0) then

      preco_sem_impostos := (pvenda -
                            ((pauta * (NVL(percbaseredst, 0) / 100)) *
                            (NVL(aliqicms1, 0) / 100)) - (vlpautaipivenda) +   (VlPautaIPIVenda)*(nvl(aliqicms2,0)/100)) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));


     else
      preco_sem_impostos := (pvenda -
                            ((pauta * (NVL(percbaseredst, 0) / 100)) *
                            (NVL(aliqicms1, 0) / 100)) - (vlpautaipivenda)) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));
     end if;


    END IF;

    -- 7. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
    IF (vlpautaipivenda > 0) AND (usavalorultentbasest = 'S') AND
       (nvl(pauta,0) = 0 ) AND
       (uf_pcfilial = pcclient_estent) THEN
      preco_sem_impostos := (pvenda -
                            ((vlpautaipivenda *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) +
                            (valorultent * (1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));
    END IF;

    -- 8. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
    IF (vlpautaipivenda > 0) AND (usavalorultentbasest = 'S') AND
       (usavalorultentbasest2 = 'S') AND (uf_pcfilial = pcclient_estent) THEN
      preco_sem_impostos := (pvenda -
                            ((vlpautaipivenda *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) +
                            (valorultent * (((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)) -
                            (NVL(aliqicms2, 0) / 100))))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100));
    END IF;

    -- 9. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (IVA)
    IF (vlipiporkgvenda > 0) AND (pauta = 0) THEN

     if (NVL(considerarIpiAliqicms2,'N') = 'S') and (NVL(iva, 0) > 0) and (NVL(aliqicms1, 0) > 0) and (NVL(aliqicms2, 0) > 0) then

      preco_sem_impostos := (pvenda - ((vlipiporkgvenda * pesobruto) *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100))))+
                             (nvl(aliqicms2,0)/100)*
                              (VlIPIPorKGVenda * PesoBruto) ) /
                            ((1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100)) +
                            ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)));

     else
      preco_sem_impostos := (pvenda - ((vlipiporkgvenda * pesobruto) *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100))))) /
                            ((1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100)) +
                            ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)));
     end if;
    END IF;

    -- 10. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (PAUTA)
    IF (vlipiporkgvenda > 0) AND (pauta > 0) THEN

     if (NVL(considerarIpiAliqicms2,'N') = 'S') and (NVL(iva, 0) > 0) and (NVL(aliqicms1, 0) > 0) and (NVL(aliqicms2, 0) > 0) then
      preco_sem_impostos := (pvenda -
                            ((pauta * (NVL(percbaseredst, 0) / 100)) *
                            (NVL(aliqicms1, 0) / 100)) -
                            (vlipiporkgvenda * pesobruto)+
                            (VlIPIPorKGVenda * PesoBruto)*(nvl(aliqicms1,0)/100) ) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));

     else
      preco_sem_impostos := (pvenda -
                            ((pauta * (NVL(percbaseredst, 0) / 100)) *
                            (NVL(aliqicms1, 0) / 100)) -
                            (vlipiporkgvenda * pesobruto)) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));

     end if;
    END IF;

    -- 11. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE)
    IF (vlipiporkgvenda > 0) AND (usavalorultentbasest = 'S') AND
       (pauta = 0) AND
       (uf_pcfilial = pcclient_estent) THEN
      preco_sem_impostos := (pvenda -
                            (((vlipiporkgvenda * pesobruto) *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) +
                            (valorultent * (1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));
    END IF;

    -- 12. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
    IF (vlipiporkgvenda > 0) AND (usavalorultentbasest = 'S') AND
       (usavalorultentbasest2 = 'S') AND (uf_pcfilial = pcclient_estent) THEN
      preco_sem_impostos := (pvenda -
                            (((vlipiporkgvenda * pesobruto) *
                            (1 + ((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)))) +
                            (valorultent * (((1 + (NVL(iva, 0) / 100)) *
                            (NVL(percbaseredst, 0) / 100) *
                            (NVL(aliqicms1, 0) / 100)) -
                            (NVL(aliqicms2, 0) / 100))))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100));
    END IF;

    -- 13. CALCULA ST COM BASE NO PREÇO MÁXIMO DO CONSUMIDOR FINAL Tarefa 132417
    IF (usapmcbasest = 'S') AND (precomaxconsumidor > 0) THEN
      preco_sem_impostos := (pvenda - ((precomaxconsumidor *
                            (NVL(percbaseredst, 0) / 100)) *
                            (NVL(aliqicms1, 0) / 100))) /
                            (1 + (NVL(percdifaliquotas, 0) / 100) -
                            (NVL(aliqicms2, 0) / 100));
    END IF;


     --14. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + PAUTA ST
      if (((PercIPI > 0) or
         (PercIPI = 0)) and
          (VlPautaIPIVenda = 0) and
         (VlIPIPorKGVenda = 0)) and
         (usavalorultentbasest = 'S') and
          (usavalorultentbasest2 = 'S') and
         (Pauta > 0) and
         (uf_pcfilial = pcclient_estent) then

        preco_sem_impostos := (PVenda -
                              ((Pauta * (percbaseredst/100)*
                              (nvl(aliqicms1,0)/100)) -
                              (valorultent * ((nvl(aliqicms2,0)/100)))))/
                              (1 + (nvl(percdifaliquotas,0)/100)
                              +(percipi/100));
      end if;

     --15. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + ST PAUTA
       if (vlpautaipivenda > 0) and
         (usavalorultentbasest = 'S') and
         (usavalorultentbasest2 = 'S') and
          (Pauta > 0) and
         (uf_pcfilial = pcclient_estent) then

        preco_sem_impostos := (pVenda -
                              ((Pauta * (percbaseredst/100)*
                               (nvl(aliqicms1,0)/100)) -
                               (valorultent * ((nvl(aliqicms2,0)/100))))-
                               vlpautaipivenda)/(1 + (nvl(percdifaliquotas,0)/100));
       end if;

      --16. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE)
      IF (vlipiporkgvenda > 0) and
         (usavalorultentbasest = 'S') and
          (usavalorultentbasest2 = 'S') and
         (Pauta > 0) and
         (uf_pcfilial = pcclient_estent) then

        preco_sem_impostos := (pVenda -
                              ((Pauta * (percbaseredst/100)*
                               (nvl(aliqicms1,0)/100)) -
                               (valorultent * ((nvl(aliqicms2,0)/100))))-
                               (VlIPIPorKGVenda * PesoBruto))/(1 + (nvl(percdifaliquotas,0)/100));


     end if;

      if (UsaVlUltEntMedioBasest = 'S') then

           if nvl(vlultentmes,0) > 0 then
              vnvlultent  := vlultentmes;
           else
              vnvlultent := valorultent;
           end if;

        -- 17. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE) -- IGUAL AO 3
        if (((PercIPIVenda > 0) or
           (PercIPIVenda = 0)) and
           (VlPautaIPIVenda = 0) and
           (VlIPIPorKGVenda = 0)) and
           (Pauta = 0) and
           (Uf_pcFilial = pcclient_estent) then


           preco_sem_impostos := (PVenda -
                                ((vnvlultent * (1 + (nvl(Iva,0)/100)) *
                                (nvl(percbaseredst,0)/100)) *
                                (nvl(aliqicms1,0)/ 100))) /
                                (1 + (nvl(percdifaliquotas,0)/100) +
                                (PercIPI/100) -
                                (nvl(aliqicms2,0)/100) +
                                ((PercIPI/100) *
                                (1 + (Iva/100)) *
                                (percbaseredst/100) *
                                (nvl(aliqicms1,0)/100)));
        end if;

        --18. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) -- IGUAL AO 4.
        if (((PercIPIVenda > 0) or
           (PercIPIVenda = 0)) and
           (VlPautaIPIVenda = 0) and
           (VlIPIPorKGVenda = 0)) and
           (uf_pcFilial = pcclient_estent) then


          preco_sem_impostos := (pvenda +
                                (vnvlultent * ((NVL(aliqicms2, 0) / 100) -
                                (1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) /
                                (1 + (NVL(percdifaliquotas, 0) / 100) +
                                (NVL(percipi, 0) / 100) +
                                ((NVL(percipi, 0) / 100) *
                                (1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)));

        end if;


        --19. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE) -- IGUAL AO 7.

        IF (vlpautaipivenda > 0) AND
           (nvl(pauta,0) = 0 ) AND
           (uf_pcfilial = pcclient_estent) THEN

          preco_sem_impostos := (pvenda -
                                ((vlpautaipivenda *
                                (1 + ((1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) +
                                (vnvlultent * (1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) /
                                (1 + (NVL(percdifaliquotas, 0) / 100) -
                                (NVL(aliqicms2, 0) / 100));

        end if;

        --20. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) -- IGUAL AO 8.

        IF (vlpautaipivenda > 0) AND
           (uf_pcfilial = pcclient_estent) THEN

          preco_sem_impostos := (pvenda -
                                ((vlpautaipivenda *
                                (1 + ((1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) +
                                (vnvlultent * (((1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)) -
                                (NVL(aliqicms2, 0) / 100))))) /
                                (1 + (NVL(percdifaliquotas, 0) / 100));

        end if;


        --21. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE) -- IGUAL AO 11.
        IF (vlipiporkgvenda > 0) AND
           (pauta = 0) AND
           (uf_pcfilial = pcclient_estent) THEN

          preco_sem_impostos := (pvenda -
                                (((vlipiporkgvenda * pesobruto) *
                                (1 + ((1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) +
                                (vnvlultent * (1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) /
                                (1 + (NVL(percdifaliquotas, 0) / 100) -
                                (NVL(aliqicms2, 0) / 100));



        end if;

        --22. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) -- IGUAL AO 12.
        IF (vlipiporkgvenda > 0) AND
           (uf_pcfilial = pcclient_estent) THEN

          preco_sem_impostos := (pvenda -
                                (((vlipiporkgvenda * pesobruto) *
                                (1 + ((1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)))) +
                                (vnvlultent * (((1 + (NVL(iva, 0) / 100)) *
                                (NVL(percbaseredst, 0) / 100) *
                                (NVL(aliqicms1, 0) / 100)) -
                                (NVL(aliqicms2, 0) / 100))))) /
                                (1 + (NVL(percdifaliquotas, 0) / 100));

        end if;

        --23. DIFERENCIAL DE ALÍQUOTAS + IPI (ALÍQUOTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + PAUTA ST IGUAL AO 14.
        if (((PercIPI > 0) or
           (PercIPI = 0)) and
           (VlPautaIPIVenda = 0) and
           (VlIPIPorKGVenda = 0)) and
           (Pauta > 0) and
           (uf_pcfilial = pcclient_estent) then

          preco_sem_impostos := (PVenda -
                                ((Pauta * (percbaseredst/100)*
                                (nvl(aliqicms1,0)/100)) -
                                (vnvlultent * ((nvl(aliqicms2,0)/100)))))/
                                (1 + (nvl(percdifaliquotas,0)/100)
                                +(percipi/100));

        end if;

        --24. DIFERENCIAL DE ALÍQUOTAS + IPI (PAUTA) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) + ST PAUTA -- IGUAL AO 15.
           if (vlpautaipivenda > 0) and
              (Pauta > 0) and
              (uf_pcfilial = pcclient_estent) then

            preco_sem_impostos := (pVenda -
                                  ((Pauta * (percbaseredst/100)*
                                   (nvl(aliqicms1,0)/100)) -
                                   (vnvlultent * ((nvl(aliqicms2,0)/100))))-
                                   vlpautaipivenda)/(1 + (nvl(percdifaliquotas,0)/100));


        end if;

        --25. DIFERENCIAL DE ALÍQUOTAS + IPI (KG) + ST (ÚLTIMA ENTRADA NA PRIMEIRA BASE E NA SEGUNDA BASE) IGUAL AO 16.
          IF (vlipiporkgvenda > 0) and
             (Pauta > 0) and
             (uf_pcfilial = pcclient_estent) then

            preco_sem_impostos := (pVenda -
                                  ((Pauta * (percbaseredst/100)*
                                   (nvl(aliqicms1,0)/100)) -
                                   (vnvlultent * ((nvl(aliqicms2,0)/100))))-
                                   (VlIPIPorKGVenda * PesoBruto))/(1 + (nvl(percdifaliquotas,0)/100));

        end if;

     end if;

    p_mensagem := '';
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular preco sem imposto: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calculo_preco_sem_impostos;


  PROCEDURE calcularcmv -- 35 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE,
   p_codst                       IN NUMBER DEFAULT 0) IS
    vnbasecalccomissao NUMBER := 0;
  BEGIN

    calcularcmv(p_abaterimpostoscomissaorca,
                p_aplicarindicecmv,
                p_incluircomissaosugpvendacmv,
                p_txvenda,
                p_tipofj,
                p_utilizaiesimplificada,
                p_ieent,
                p_freteespecial,
                p_perfreteterceiros,
                p_perfreteespecial,
                p_custofin,
                p_custoreal,
                p_perdesccusto,
                p_codicmtab,
                p_codicmtabpf_enulo,
                p_codicmtabpf,
                p_percvenda,
                p_pvenda,
                p_percom,
                p_st,
                p_vlipi,
                p_vliss,
                p_contribuinte,
                p_vldifaliquotas,
                -------------------------------------
                --O parâmetro abaixo usa como default 0(zero) por tratamento com NVL
                0, --p_perredcmvsimplesnac,
                'N', --p_consumidorfinal,
                'N', --p_consideraisentoscomopf
                -------------------------------------
                p_perfretecmv,
                p_custofinest,
                p_txvenda_item,
                p_perdesccusto_item,
                p_codicmtab_item,
                p_vlcustoreal,
                p_vlcustofin,
                p_vldesccustocmv,
                0 --P_CODCLI
                );

  END calcularcmv;

  procedure Define_Comissao_Por_PCDesconto(p_CodDesconto            in pcdesconto.coddesconto%type,
                                           p_TipoVend               in pcusuari.tipovend%type,
                                           p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                           p_PerCom                 out number,
                                           p_perdesc                in pcpedi.perdesc%type,
                                           p_tabela                 in number default 0,
                                           p_venda                  in number default 0,
                                           p_numcasasdecvenda       in number default 2) is

    vicont   number;
    vnpercom number;
    vnperdesc number;
    vnpvendacalc number;
  begin

    vnpercom := null;

    if p_CodDesconto <> 0 then

      SELECT count(*)
        INTO vicont
        FROM pcdesconto
       WHERE coddesconto = p_coddesconto;

      if vicont is not null then

        SELECT DECODE(p_tipovend,
                      'I',
                      percommint,
                      'E',
                      percomext,
                      'R',
                      percomrep,
                      0) percom,
               nvl(percdesc,0)       
          into vnpercom, vnperdesc
          FROM pcdesconto
         WHERE coddesconto = p_coddesconto;

        /*alterado para pegar comissão apenas se o desconto não for
        maior que o máximo da política de desconto.*/ 
        if (vnpercom is not null) and (round(p_perdesc,2) <= vnperdesc + 0.03) then

          if (vnpercom = 0) then

            if p_ConsiderarComissaoZero = 'S' then

              p_PERCOM := vnpercom;
            end if;

          else
            p_percom := vnPERCOM;
          end if;
        else
          vnpvendacalc := ROUND(p_tabela * ((100-vnperdesc)/100),p_numcasasdecvenda);
          if vnpvendacalc = p_venda then
            p_percom := vnPERCOM;
          end if;
        end if;
      end if;
    end if;

  end; --define_comissao_por_PCdesconto

  -- 37 parâmetros
  FUNCTION Definir_Comissao_Item_Vendido(p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_UsaPCComissaoFilial       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_codcli                    in pcclient.codcli%type,
                                         p_coddesconto               in pcdesconto.coddesconto%type,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2)
    RETURN NUMBER IS

    vnpercom       number;
    vncodcomissao  NUMBER;
    vsrotinacomissao VARCHAR2(20);
    vbUsaPCComissaofilial BOOLEAN;

  begin
    vnPerCom := 0;
    vbUsaPCComissaofilial := (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_BROKER',p_codfilial,'N') = 'S');
    vncodcomissao := NULL;
    vsrotinacomissao := NULL;

    vnpercom := Definir_Comissao_Item_Vendido(p_NumRegiao,
                                              p_perluc,
                                              p_perdesc,
                                              p_UsaPcTabComiss,
                                              p_UsaPcComissaoUsur,
                                              p_UsaPCComissaoPlPag,
                                              p_UsaPCComissaoRegiao,
                                              vbUsaPCComissaofilial,
                                              p_usacomissaoporrca,
                                              p_OrdemAvaliacaoComissaoRCA,
                                              p_usacomissaoporcliente,
                                              p_USACOMISSAOPORLINHAPROD,
                                              p_comissaorcatipovenda,
                                              p_tipovend,
                                              p_percent,
                                              p_percent2,
                                              p_codprod,
                                              p_pcomint1,
                                              P_PCOMEXT1,
                                              P_PCOMREP1,
                                              p_codlinhaprod,
                                              p_tipocomissao,
                                              p_codepto,
                                              p_codsec,
                                              p_classeproduto,
                                              p_tipovenda,
                                              p_codplpag,
                                              p_data,
                                              p_codfilial,
                                              p_codusur,
                                              p_considerarcomissaozero,
                                              p_tipoavaliacaocomissao,
                                              p_percomcli,
                                              p_codcli,
                                              p_coddesconto,
                                              vncodcomissao,
                                              vsrotinacomissao,
                                              p_LetraComiss,
                                              p_mensagem,
                                              ------------------------------
                                              --Não alterar padrão abaixo!
                                              NULL, --p_codauxiliar,
                                              NULL, --p_pcomint1_emb,
                                              NULL, --P_PCOMEXT1_emb,
                                              NULL, --P_PCOMREP1_emb,
                                              'N' --p_utilizavendaporembalagem
                                             );

    RETURN vnPerCom;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular comissao : ' || SQLERRM;
      RETURN 0;

  end;

  FUNCTION validarpoliticasdesconto -- 20 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_pbaserca                 OUT NUMBER) RETURN BOOLEAN IS

    vbresult            BOOLEAN;
    vsprioritaria       VARCHAR2(1);
    vsquestionausoprioritaria VARCHAR2(1);

  BEGIN

    vbresult := validarpoliticasdesconto(--21 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         vsprioritaria,
                                         vsquestionausoprioritaria
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION validardescontoquantidade -- 16 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_dtfim               OUT DATE,
   p_mensagem            OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER) RETURN BOOLEAN IS

    vbresult               BOOLEAN;
    vsprioritaria          VARCHAR2(1);
    vsquestionaprioritaria VARCHAR2(1);

  BEGIN

    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_numdias,
                                          p_tipodesconto,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc,
                                          p_creditasobreptabela,
                                          p_perdescflex,
                                          vsprioritaria,
                                          vsquestionaprioritaria);

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;

  END validardescontoquantidade;

  FUNCTION verificarcotarca -- 6 parametros
  (p_codprod   IN NUMBER,
   p_codusur   IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_qtdisp    out number,
   p_mensagem  OUT VARCHAR2
   ) RETURN BOOLEAN IS
    vbresult      BOOLEAN;
    vncota        NUMBER;
    vnqtdevendida NUMBER;
    vddtinicio    DATE;
    vddtfim       DATE;
    vnnumregiao   pcregiao.numregiao%type;

    vicont NUMBER;
  BEGIN
    --Inicializar variáveis}
    vbresult      := FALSE;
    vncota        := 0;
    vnqtdevendida := 0;
    --Verificar se há cota do RCA p/ o produto}
    SELECT COUNT(*)
      INTO vicont
      FROM pcprodusur
     WHERE codcli IS NULL
       AND codprod = p_codprod
       AND codusur = p_codusur
       AND (numregiao = p_numregiao or numregiao is null)
       AND datainicio <= trunc(SYSDATE)
       AND datafim >= trunc(SYSDATE);
    IF vicont <> 0 THEN

      SELECT qtmaxvenda, datainicio, datafim, numregiao
        INTO vncota, vddtinicio, vddtfim, vnnumregiao
        FROM pcprodusur
       WHERE codcli IS NULL
         AND codprod = p_codprod
         AND codusur = p_codusur
         AND (numregiao = p_numregiao or numregiao is null)
         AND datainicio <= trunc(SYSDATE)
         AND datafim >= trunc(SYSDATE);
      --Verificar quantidade adquirida através do rca no período}
      SELECT COUNT(*)
        INTO vicont
        FROM pcpedi, pcpedc
       WHERE pcpedi.numped = pcpedc.numped
         AND pcpedi.codprod = p_codprod
         AND pcpedc.codusur = p_codusur
         AND pcpedc.dtcancel IS NULL
         and (pcpedc.numregiao = nvl(vnnumregiao, pcpedc.numregiao) or
             pcpedc.numregiao is null)
         AND pcpedc.data >= vddtinicio
         AND pcpedc.data <= vddtfim;
      IF vicont <> 0 THEN
        SELECT SUM(pcpedi.qt) qtdevendida
          INTO vnqtdevendida
          FROM pcpedi, pcpedc
         WHERE pcpedi.numped = pcpedc.numped
           AND pcpedi.codprod = p_codprod
           AND pcpedc.codusur = p_codusur
           AND pcpedc.dtcancel IS NULL
           and (pcpedc.numregiao = nvl(vnnumregiao, pcpedc.numregiao) or
               pcpedc.numregiao is null)
           AND pcpedc.data >= vddtinicio
           AND pcpedc.data <= vddtfim;
      END IF;
      IF (nvl(vnqtdevendida, 0) + nvl(p_qtpedida, 0)) <= vncota THEN
        vbresult := TRUE;
      ELSE
        vbresult   := FALSE;
        p_qtdisp   := vncota - nvl(vnqtdevendida, 0);
        p_mensagem := 'Quantidade do produto vendida através do RCA supera cota do período.' ||
                      chr(13) || 'Cota : ' || vncota || chr(13) ||
                      'Qtde. Vendida : ' || vnqtdevendida || chr(13) ||
                      'Qtde. Pedida: ' || p_qtpedida || chr(13) ||
                      'Período :' || to_char(vddtinicio, 'dd/mm/yyyy') ||
                      ' a ' || to_char(vddtfim, 'dd/mm/yyyy');
      END IF;
    ELSE
      --Se não há cota
      vbresult := TRUE;
    END IF;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar Cota RCA: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END verificarcotarca;

  FUNCTION verificarcotacliente -- 6 parametros
  (p_codprod   IN NUMBER,
   p_codcli    IN NUMBER,
   p_qtpedida  IN NUMBER,
   p_numregiao in pcregiao.numregiao%type,
   p_qtdisp    out number,
   p_mensagem  OUT VARCHAR2) RETURN BOOLEAN IS
    vbresult      BOOLEAN;
    vncota        NUMBER;
    vnqtdevendida NUMBER;
    vddtinicio    DATE;
    vddtfim       DATE;
    vnnumregiao   pcregiao.numregiao%type;
    vicont        NUMBER;
  BEGIN
    --Inicializar variáveis
    vbresult      := FALSE;
    vncota        := 0;
    vnqtdevendida := 0;
    --Verificar se há cota do cliente p/ o produto}
    SELECT COUNT(*)
      INTO vicont
      FROM pcprodusur
     WHERE codusur IS NULL
       AND codprod = p_codprod
       AND codcli = p_codcli
       AND (numregiao = p_numregiao or numregiao is null)
       AND datainicio <= trunc(SYSDATE)
       AND datafim >= trunc(SYSDATE);
    IF vicont <> 0 THEN
      SELECT qtmaxvenda, datainicio, datafim, numregiao
        INTO vncota, vddtinicio, vddtfim, vnnumregiao
        FROM pcprodusur
       WHERE codusur IS NULL
         AND codprod = p_codprod
         AND codcli = p_codcli
         AND (numregiao = p_numregiao or numregiao is null)
         AND datainicio <= trunc(SYSDATE)
         AND datafim >= trunc(SYSDATE);
      --Verificar quantidade adquirida através do rca no período
      SELECT COUNT(*)
        INTO vicont
        FROM pcpedi, pcpedc
       WHERE pcpedi.numped = pcpedc.numped
         AND pcpedi.codprod = p_codprod
         AND pcpedc.codcli = p_codcli
         AND pcpedc.dtcancel IS NULL
         and (pcpedc.numregiao = nvl(vnnumregiao, pcpedc.numregiao) or
             pcpedc.numregiao is null)
         AND pcpedc.data >= vddtinicio
         AND pcpedc.data <= vddtfim;
      IF vicont <> 0 THEN
        SELECT SUM(pcpedi.qt) qtdevendida
          INTO vnqtdevendida
          FROM pcpedi, pcpedc
         WHERE pcpedi.numped = pcpedc.numped
           AND pcpedi.codprod = p_codprod
           AND pcpedc.codcli = p_codcli
           AND pcpedc.dtcancel IS NULL
           and (pcpedc.numregiao = nvl(vnnumregiao, pcpedc.numregiao) or
               pcpedc.numregiao is null)
           AND pcpedc.data >= vddtinicio
           AND pcpedc.data <= vddtfim;
      END IF;
      IF (nvl(vnqtdevendida, 0) + nvl(p_qtpedida, 0)) <= vncota THEN
        vbresult := TRUE;
      ELSE
        vbresult   := FALSE;
        p_qtdisp   := vncota - nvl(vnqtdevendida, 0);
        p_mensagem := 'Quantidade do produto vendida ao cliente supera cota do período.' ||
                      chr(13) || 'Cota : ' || vncota || chr(13) ||
                      'Qtde. Vendida : ' || vnqtdevendida || chr(13) ||
                      'Qtde. Pedida: ' || p_qtpedida || chr(13) ||
                      'Período :' || to_char(vddtinicio, 'dd/mm/yyyy') ||
                      ' a ' || to_char(vddtfim, 'dd/mm/yyyy');
      END IF;
    ELSE
      --Se não há cota
      vbresult := TRUE;
    END IF;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao verificar cota do cliente:' || SQLERRM;
      RETURN FALSE;

  END verificarcotacliente;

  FUNCTION calcularimpostos --69 parametros ( pode ser usada para packages que usam 50 parÂmetros)
  (p_pvenda                  IN OUT NUMBER,
   p_ptabela                 IN OUT NUMBER,
   p_pbaserca                IN OUT NUMBER,
   p_vlipi                   IN OUT NUMBER,
   p_percipi                 IN OUT NUMBER,
   p_percipivenda            IN NUMBER,
   p_percvenda               IN NUMBER,
   p_tipocalcst              IN VARCHAR2,
   p_calcstpf                IN VARCHAR2,
   p_mostrarpvendasemst      IN VARCHAR2,--10
   p_consideraisentoscomopf  IN VARCHAR2,
   p_calculast               IN VARCHAR2,
   p_ieent                   IN VARCHAR2,
   p_tipofj                  IN VARCHAR2,
   p_pauta                   IN NUMBER,
   p_iva                     IN OUT NUMBER,
   p_aliqicms1               IN NUMBER,
   p_aliqicms2               IN NUMBER,
   p_percbaseredst           IN OUT NUMBER,
   p_numcasasdecvenda        IN NUMBER,--20
   p_tipocalculo             IN NUMBER,
   p_uffilial                IN VARCHAR2,
   p_estent                  IN VARCHAR2,
   p_usavalorultentbasest    IN VARCHAR2,
   p_usavalorultentbasest2   IN VARCHAR2,
   p_valorultent             IN NUMBER,
   p_isentoipi               IN VARCHAR2,
   p_suframa                 IN pcclient.sulframa%type,
   p_calcularstcomipi        IN pcconsum.calcularstcomipi%TYPE,
   p_tipocalcipi             IN pcconsum.tipocalcipi%TYPE,--30
   p_filialnf                IN pcpedc.codfilialnf%TYPE,
   p_condvenda               IN pcpedc.condvenda%TYPE,
   p_contribuinte            IN pcclient.contribuinte%TYPE,
   p_uffilialnf              IN pcfilial.uf%TYPE,
   p_importado               in pcprodut.importado%type,
   P_CALCULARIPIVENDA        IN PCFILIAL.CALCULARIPIVENDA%TYPE,
   P_PERCIPIVENDATAB         IN PCPRODUT.PERCIPIVENDATAB%TYPE,
   P_VLPAUTAIPIVENDA         IN PCPRODUT.VLPAUTAIPIVENDA%type,
   P_VLPAUTAIPIVENDATAB      IN PCPRODUT.VLPAUTAIPIVENDATAB%TYPE,
   P_VLIPIPORKGVENDA         IN PCPRODUT.VLIPIPORKGVENDA%TYPE,--40
   P_VLIPIPORKGVENDATAB      IN PCPRODUT.VLIPIPORKGVENDATAB%TYPE,
   P_PESOBRUTO               IN PCPRODUT.PESOBRUTO%type,
   P_TIPOCALCULOGNRE         IN PCTRIBUT.Tipocalculognre%type,
   p_SIMPLESNACIONAL         IN PCCLIENT.SIMPLESNACIONAL%type,
   p_PERCREDPVENDASIMPLESNAC IN pctribut.PERCREDPVENDASIMPLESNAC%type,
   p_reduziva                IN varchar2, --utilizado pelo fv para fazer um calculo sem redução do iva mesmo que o cliente seja simples nacional
   p_utilizaiesimplificada   IN pcclient.utilizaiesimplificada%type,
   p_mensagem                OUT VARCHAR2,
   p_st                      OUT NUMBER,
   p_baseicst                OUT NUMBER,--50
   p_aceitapfcontribuinte    IN pcconsum.aceitapfcontribuinte%type default 'N',
   p_custonfsemst            IN pcest.custonfsemst%type default 0,
   p_usapmcbasest            IN pctribut.usapmcbasest%type default 'N',
   p_precomaxconsum          IN pcprodut.precomaxconsum%type default 0,
   p_consumidorfinal         IN pcclient.consumidorfinal%type default 'N',
   p_retiraimp               IN VARCHAR2 default 'S',
   p_novoprocesso            IN VARCHAR2 default 'N',
   p_agregaripicalculost in varchar2 default 'N',
   p_utilizacalculostmt      IN pcclient.utilizacalculostmt%type default 'N',
   p_margemmva               IN pccnae.margemmva%type default 0,--60
   p_percargatribmedia       IN pccnae.percargatribmedia%type default 0,
   p_usavlultentmediobasest  in pctribut.usavlultentmediobasest%type default 'N',
   p_vlultentmes             in pctabpr.vlultentmes%type default 0,
   p_percbasestrj            in pctribut.percbasestrj%type default 0,
   p_vlstPrecificacao        in pctabpr.vlst%type default 1 ,
   p_tipoPreco               in varchar2 default 'N',
   p_foiprecificadocomIpi    in varchar2 default 'S',
   p_percredaliqipi          IN NUMBER DEFAULT 0,
   p_calcularSTRamoAtiv      IN VARCHAR DEFAULT 'S')
  RETURN BOOLEAN IS

    vbresult               BOOLEAN;
    --vnst                   NUMBER;
    vsisentoipi            pcclient.isentoipi%TYPE;
    vsuffilial             pcfilial.uf%TYPE;
    vnpercbaseredst        pctribut.percbaseredst%TYPE;
    vnpvenda               pcpedi.pvenda%TYPE;
    vsmensagem             VARCHAR2(1000);
    vsmensagem_st          VARCHAR2(1000);
    vntipocalculo          number;
    vniva                  pcpedi.iva%type;
    vnAliqIcms1            pctribut.ALIQICMS1%TYPE;
    vnAliqIcms2            pctribut.aliqicms2%TYPE;
    vscontribuinte         pcclient.contribuinte%type;
    vsaceitapfcontribuinte pcconsum.aceitapfcontribuinte%type;

    vsmensagemprecosemimposto varchar2(1000);
    vbcalculosemimposto       boolean;
    vnpercipivenda            number;

    vnptabela                 number;
    vnpbaserca                number;

    vnstaux                   number;

    vnpvenda_red              pcpedi.pvenda%type;
    vnptabela_red             pcpedi.ptabela%type;
    vnpbaserca_red            pcpedi.pbaserca%type;
    vsConsiderarIpiAliqicms2  varchar2(1);

    vnvlipi_pvenda            pcpedi.vlipi%type;
    vnvlipi_ptabela           pcpedi.ptabela%type;
    vnvlipi_pbaserca          pcpedi.pbaserca%type;

    vnst_pvenda               pcpedi.st%type;
    vnst_ptabela              pcpedi.st%type;
    vnst_pbaserca             pcpedi.st%type;
    vnbaseicst_pvenda         pcpedi.baseicst%type;
    vnbaseicst_ptabela        pcpedi.baseicst%type;
    vnbaseicst_pbaserca       pcpedi.baseicst%type;

    vnPERCIPI_REDUZIDO        NUMBER(18,6) := 0;

  BEGIN
    vbresult := FALSE;
    vnst_pvenda     := 0;
    vnst_ptabela    := 0;
    vnst_pbaserca   := 0;

    vnAliqIcms1  := p_aliqicms1;
    vnAliqIcms2  := p_aliqicms2;

    vscontribuinte := p_contribuinte;

    select pcconsum.aceitapfcontribuinte
      into vsaceitapfcontribuinte
      from pcconsum;

    if vsaceitapfcontribuinte = 'N' then
      vscontribuinte := 'N';

    end if;

     vsConsiderarIpiAliqicms2 := 'N';

    if (p_ConsumidorFinal = 'S') and ((p_Importado = 'S') or (p_Importado = 'D')) and
       (vsuffilial <> p_estent) and (p_AGREGARIPICALCULOST = 'S') then

       vsConsiderarIpiAliqicms2 := 'S';
    end if;


    -----------------------------------------------------------------------
    --Cálculo do Vl. IPI
    vsisentoipi := p_isentoipi;
    --tarefa 70971 não zerar ipi caso o cliente tenha suframa e o produto seja importado(S ou D)
    IF (p_suframa IS NOT NULL and p_importado = 'P') OR p_tipofj = 'E' THEN
      vsisentoipi := 'S';
    END IF;

    -- Tarefa: 3717.016212.2015
    -- Descricao: Checar parâmetro 2210 para antes de fazer o cálculo de IPI.
    IF nvl(p_calcularstcomipi, 'N') = 'N' then
        vsISENTOIPI := 'S';
        --vnpercipivenda := 0;
    END IF;

    IF p_estent = 'EX' THEN
      vsisentoipi := 'S';
    END IF;
    vnst_pvenda      := 0; --Variável tem que ser zerada para o cálculo abaixo
    vnst_ptabela     := 0; --Variável tem que ser zerada para o cálculo abaixo
    vnst_pbaserca    := 0; --Variável tem que ser zerada para o cálculo abaixo

    p_percipi := 0;
    vnvlipi_pvenda   := 0;
    vnvlipi_ptabela  := 0;
    vnvlipi_pbaserca := 0;

    vnpvenda  := p_pvenda;

    vnpercbaseredst := nvl(p_percbaseredst, 0);
    vniva           := p_iva;


    --tarefa 114907
    if p_SIMPLESNACIONAL = 'S' and p_reduziva = 'S' then

      if p_pauta > 0 or nvl(vniva, 0) > 0 or vnAliqIcms1 > 0 or
         vnAliqIcms2 > 0 then

        select nvl(p_iva, 0) *
               (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                       0,
                       100,
                       P_PERCREDPVENDASIMPLESNAC) / 100)
          into vniva
          from dual;
      end if;

    end if;

    IF (P_TIPOPRECO = 'V') AND
       (p_calcularSTRamoAtiv = 'N')
    THEN
      vniva        := 0;
      vnAliqIcms1  := 0;
      vnAliqIcms2  := 0;
    END IF;


     if p_novoprocesso = 'N' then
         if (p_mostrarpvendasemst = 'S' and p_retiraimp = 'S' and P_TIPOCALCULOGNRE = 'P') or
             p_mostrarpvendasemst = 'N' then

          vbcalculosemimposto := calculo_preco_sem_impostos(CASE WHEN p_foiprecificadocomIpi = 'S' then nvl(p_PERCIPIVENDA, 0) ELSE 0 END,
                                                            CASE WHEN p_foiprecificadocomIpi = 'S' then p_vlpautaipivenda ELSE 0 END,
                                                            CASE WHEN p_foiprecificadocomIpi = 'S' then p_vlipiporkgvenda ELSE 0 END,
                                                            p_pvenda,
                                                            p_pauta,
                                                            p_pesobruto,
                                                            0, --p_percdifaliquotas,
                                                            vnpercipivenda,
                                                            p_valorultent,
                                                            vniva,
                                                            p_percbaseredst,
                                                            (CASE WHEN p_vlstPrecificacao > 0 THEN  vnAliqIcms1 ELSE 0 END),
                                                            (CASE WHEN p_vlstPrecificacao > 0 THEN  vnAliqIcms2 ELSE 0 END),
                                                            p_usavalorultentbasest,
                                                            p_usavalorultentbasest2,
                                                            p_uffilial,
                                                            p_estent,
                                                            vnpvenda_red,
                                                            vsmensagemprecosemimposto,
                                                            p_usapmcbasest,
                                                            p_precomaxconsum,
                                                            'N', --vsConsiderarIpiAliqicms2
                                                            p_usavlultentmediobasest,
                                                            p_vlultentmes,
                                                            p_percbasestrj,
                                                            CASE WHEN p_tipoPreco IN ('T','R') THEN 0 ELSE p_percredaliqipi END
                                                            );

           if vnpvenda_red > p_pvenda  or ((p_pvenda - vnpvenda_red) <= 0.01) then

              vnpvenda_red := p_pvenda;

           end if;

          vbcalculosemimposto := calculo_preco_sem_impostos(CASE WHEN p_foiprecificadocomIpi = 'S' then nvl(p_PERCIPIVENDA, 0) ELSE 0 END,
                                                            CASE WHEN p_foiprecificadocomIpi = 'S' then p_vlpautaipivenda ELSE 0 END,
                                                            CASE WHEN p_foiprecificadocomIpi = 'S' then p_vlipiporkgvenda ELSE 0 END,
                                                            p_ptabela,
                                                            p_pauta,
                                                            p_pesobruto,
                                                            0, --p_percdifaliquotas,
                                                            vnpercipivenda,
                                                            p_valorultent,
                                                            p_iva,
                                                            p_percbaseredst,
                                                            (CASE WHEN p_vlstPrecificacao > 0 THEN  vnAliqIcms1 ELSE 0 END),
                                                            (CASE WHEN p_vlstPrecificacao > 0 THEN  vnAliqIcms2 ELSE 0 END),
                                                            p_usavalorultentbasest,
                                                            p_usavalorultentbasest2,
                                                            p_uffilial,
                                                            p_estent,
                                                            vnptabela_red,
                                                            vsmensagemprecosemimposto,
                                                            p_usapmcbasest,
                                                            p_precomaxconsum,
                                                            'N', --vsConsiderarIpiAliqicms2
                                                            p_usavlultentmediobasest,
                                                            p_vlultentmes,
                                                            p_percbasestrj,
                                                            CASE WHEN p_tipoPreco IN ('T','R') THEN 0 ELSE p_percredaliqipi END);

           if vnptabela_red > p_ptabela  or ((p_ptabela - vnptabela_red) <= 0.01) then

              vnptabela_red := p_ptabela;

           end if;


          vbcalculosemimposto := calculo_preco_sem_impostos(CASE WHEN p_foiprecificadocomIpi = 'S' then nvl(p_PERCIPIVENDA, 0) ELSE 0 END,
                                                            CASE WHEN p_foiprecificadocomIpi = 'S' then p_vlpautaipivenda ELSE 0 END,
                                                            CASE WHEN p_foiprecificadocomIpi = 'S' then p_vlipiporkgvenda ELSE 0 END,
                                                            p_pbaserca,
                                                            p_pauta,
                                                            p_pesobruto,
                                                            0, --p_percdifaliquotas,
                                                            vnpercipivenda,
                                                            p_valorultent,
                                                            p_iva,
                                                            p_percbaseredst,
                                                            (CASE WHEN p_vlstPrecificacao > 0 THEN  vnAliqIcms1 ELSE 0 END),
                                                            (CASE WHEN p_vlstPrecificacao > 0 THEN  vnAliqIcms2 ELSE 0 END),
                                                            p_usavalorultentbasest,
                                                            p_usavalorultentbasest2,
                                                            p_uffilial,
                                                            p_estent,
                                                            vnpbaserca_red,
                                                            vsmensagemprecosemimposto,
                                                            p_usapmcbasest,
                                                            p_precomaxconsum,
                                                            'N', --vsConsiderarIpiAliqicms2
                                                            p_usavlultentmediobasest,
                                                            p_vlultentmes,
                                                            p_percbasestrj,
                                                            CASE WHEN p_tipoPreco IN ('T','R') THEN 0 ELSE p_percredaliqipi END);

           if vnpbaserca_red > p_pbaserca  or ((p_pbaserca - vnpbaserca_red) <= 0.01) then

              vnpbaserca_red := p_pbaserca;

           end if;

        else

          vnpvenda_red  := p_pvenda;
          vnptabela_red := p_ptabela;
          vnpbaserca_red := p_pbaserca;

        end if;
    else

      vnpvenda_red  := p_pvenda;
      vnptabela_red := p_ptabela;
      vnpbaserca_red := p_pbaserca;

    end if;

    --arredondar depois de retirar impostos
    vnpvenda_red := round(vnpvenda_red,p_numcasasdecvenda);
    vnptabela_red := round(vnptabela_red,p_numcasasdecvenda);
    vnpbaserca_red := round(vnpbaserca_red,p_numcasasdecvenda);



    IF --nvl(p_calcularstcomipi, 'N') = 'N' or
        (vsISENTOIPI = 'S') or
       (p_CONDVENDA in (3, 6, 12)) THEN
      IF (nvl(p_percipivenda, 0) <> 0) AND (vsisentoipi = 'N') AND
         (p_condvenda NOT IN (3, 6, 7, 12))
      --Não se calcula IPI na venda 7
      THEN
        --Tarefa 70519 - Projeto 69444
        if P_CALCULARIPIVENDA = 'S' then

          if P_VLPAUTAIPIVENDA > 0 then
            vnVLIPI_pvenda := P_VLPAUTAIPIVENDA;
            vnVLIPI_ptabela := P_VLPAUTAIPIVENDA;
            vnVLIPI_pbaserca := P_VLPAUTAIPIVENDA;
          end if;

          if P_VLIPIPORKGVENDA > 0 then
            vnVLIPI_pvenda := P_PESOBRUTO * P_VLIPIPORKGVENDA;
            vnVLIPI_ptabela := P_PESOBRUTO * P_VLIPIPORKGVENDA;
            vnVLIPI_pbaserca := P_PESOBRUTO * P_VLIPIPORKGVENDA;
          end if;

          if P_PERCIPIVENDA > 0 then

            -----------------------------------------------------------
            --Autor: Rodrigo Santos
            --Solicitação: HIS.01467.2015
            --Data: 05/05/2015
            --Descrição: Implementação do redutor da alíquota de IPI,
            -- quando o parâmetro abaixo for informado (p_percredaliqipi > 0)
            -- assume que PCPRODUT.APLICAPERCREDALIQIPI = 'S', logo a aplicação
            -- da redução deve ser controlada pela passagem deste parâmetro.
            -- Ou seja, SE "p_percredaliqipi > 0" então PCPRODUT.APLICAPERCREDALIQIPI = 'S',
            -- ou SE "p_percredaliqipi = 0" então PCPRODUT.APLICAPERCREDALIQIPI = 'N'

            IF nvl(p_percredaliqipi,0) > 0 THEN
              vnPERCIPI_REDUZIDO := nvl(P_PERCIPIVENDA - (P_PERCIPIVENDA * (p_percredaliqipi / 100)),0);
            ELSE
              vnPERCIPI_REDUZIDO := nvl(P_PERCIPIVENDA,0);
            END IF;
            -----------------------------------------------------------

            vnVLIPI_pvenda   := vnPVENDA_red  *(nvl(vnPERCIPI_REDUZIDO, 0) / 100);
            vnVLIPI_ptabela  := vnPtabela_red  *(nvl(vnPERCIPI_REDUZIDO, 0) / 100);
            vnVLIPI_pbaserca := vnPbaserca_red  *(nvl(vnPERCIPI_REDUZIDO, 0) / 100);

            p_percipi := vnPERCIPI_REDUZIDO;
          end if;

        else
          vnVLIPI_pvenda := 0;
          vnVLIPI_ptabela := 0;
          vnVLIPI_pbaserca := 0;
        END IF;

        --Fim-Tarefa 70519
        IF p_condvenda IN (2, 7) THEN
          vnvlipi_pvenda := nvl(vnvlipi_pvenda, 0) * (p_percvenda / 100);
          vnvlipi_ptabela := nvl(vnvlipi_ptabela, 0) * (p_percvenda / 100);
          vnvlipi_pbaserca := nvl(vnvlipi_pbaserca, 0) * (p_percvenda / 100);
        END IF;

        IF p_condvenda IN (3, 6, 12) THEN
          vnvlipi_pvenda := 0;
          vnvlipi_ptabela := 0;
          vnvlipi_pbaserca := 0;
        END IF;

        --Tipo de Cálculo do IPI
        IF p_tipocalcipi = 'T2' THEN
          vnvlipi_pvenda := trunc(vnvlipi_pvenda * 100) / 100;
          vnvlipi_ptabela := trunc(vnvlipi_ptabela * 100) / 100;
          vnvlipi_pbaserca := trunc(vnvlipi_pbaserca * 100) / 100;
        ELSIF p_tipocalcipi = 'A2' THEN
          vnvlipi_pvenda := round(vnvlipi_pvenda, 2);
          vnvlipi_ptabela := round(vnvlipi_ptabela, 2);
          vnvlipi_pbaserca := round(vnvlipi_pbaserca, 2);
        ELSIF p_tipocalcipi = 'PV' THEN
          vnvlipi_pvenda := round(vnvlipi_pvenda, p_numcasasdecvenda);
          vnvlipi_ptabela := round(vnvlipi_ptabela, p_numcasasdecvenda);
          vnvlipi_pbaserca := round(vnvlipi_pbaserca, p_numcasasdecvenda);
        END IF;
      END IF;

      p_vlipi := vnvlipi_pvenda;

    IF (P_TIPOPRECO IN ('T', 'R','N')) AND
       (p_calcularSTRamoAtiv = 'N')
    THEN
      vniva        := 0;
      vnAliqIcms1  := 0;
      vnAliqIcms2  := 0;
    END IF;

  --diferenciaçao de st para cliente do estado MT
  if p_ESTENT = 'MT' AND p_UTILIZACALCULOSTMT = 'S' then

      proc_calculastMT (vnpvenda_red ,
                        vnptabela_red ,
                        vnpbaserca_red,
                        p_percipi ,
                        vnpercbaseredst,
                        p_mostrarpvendasemst,
                        p_tipofj,
                        p_utilizaiesimplificada,
                        p_consumidorfinal ,
                        p_ieent ,
                        p_contribuinte,
                        p_calculast,
                        p_estent ,
                        p_consideraisentoscomopf,
                        p_tipocalcst,
                        p_calcstpf,
                        p_numcasasdecvenda,
                        p_aceitapfcontribuinte,
                        vnvlipi_pvenda,
                        vnvlipi_ptabela,
                        vnvlipi_pbaserca,
                        p_pauta ,
                        p_iva ,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        p_margemmva,
                        p_percargatribmedia,
                        p_uffilial ,
                        p_st ,
                        p_baseicst ,
                        p_mensagem);

      p_pvenda   := vnpvenda_red;
      p_ptabela  := vnptabela_red;
      p_pbaserca := vnpbaserca_red;

  else

      vntipocalculo := 0;

      if P_MOSTRARPVENDASEMST = 'S' then
        vntipocalculo := 1;
      end if;

      if vnVLIPI_pvenda > 0 then
        vntipocalculo := 1;
      end if;

      vsuffilial := p_uffilial;

      IF p_filialnf IS NOT NULL THEN
        vsuffilial := p_uffilialnf;
      END IF;

      IF NOT calcularst(vnpvenda_red,
                        nvl(vnvlipi_pvenda,0),
                        p_percvenda,
                        p_tipocalcst,
                        p_calcstpf,
                        p_mostrarpvendasemst,
                        p_consideraisentoscomopf,
                        p_calculast,
                        p_ieent,
                        p_tipofj,
                        p_pauta,
                        vniva,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        vnpercbaseredst,
                        p_numcasasdecvenda,
                        1,--vntipocalculo,
                        vsuffilial,
                        p_estent,
                        p_usavalorultentbasest,
                        p_usavalorultentbasest2,
                        p_valorultent,
                        vscontribuinte,
                        p_utilizaiesimplificada,
                        vsmensagem_st,
                        vnst_pvenda,
                        p_baseicst,
                        p_aceitapfcontribuinte,
                        p_usapmcbasest,
                        p_precomaxconsum,
                        p_custonfsemst,
                        p_consumidorfinal,
                        vsConsiderarIpiAliqicms2,
                        p_usavlultentmediobasest,
                        p_vlultentmes,
                        p_percbasestrj) THEN

        vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                      vsmensagem_st;
      ELSE
        p_st := vnst_pvenda;
        if  (P_TIPOCALCULOGNRE = 'C') then
          vnST_pvenda := 0;
        end if;

        P_PVENDA := Round(vnPVENDA_red + nvl(vnST_pvenda, 0) + nvl(vnvlipi_pvenda,0), p_NumCasasDecVenda);

      END IF;

      --ptabela
      IF NOT calcularst(vnptabela_red, -- - (nvl(vnST, 0) + nvl(P_VLIPI, 0)),
                        nvl(vnvlipi_ptabela,0),
                        p_percvenda,
                        p_tipocalcst,
                        p_calcstpf,
                        p_mostrarpvendasemst,
                        p_consideraisentoscomopf,
                        p_calculast,
                        p_ieent,
                        p_tipofj,
                        p_pauta,
                        case when p_tipoPreco = 'N' then nvl(vniva, 0) else p_iva end,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        vnpercbaseredst,
                        p_numcasasdecvenda,
                        1, --vntipocalculo,
                        vsuffilial,
                        p_estent,
                        p_usavalorultentbasest,
                        p_usavalorultentbasest2,
                        p_valorultent,
                        vscontribuinte,
                        p_utilizaiesimplificada,
                        vsmensagem_st,
                        vnst_ptabela,
                        vnbaseicst_ptabela,
                        p_aceitapfcontribuinte,
                        p_usapmcbasest,
                        p_precomaxconsum,
                        p_custonfsemst,
                        p_consumidorfinal,
                        vsConsiderarIpiAliqicms2,
                        p_usavlultentmediobasest,
                        p_vlultentmes,
                        p_percbasestrj) THEN

        vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                      vsmensagem_st;
      ELSE

        if (P_TIPOCALCULOGNRE = 'C') then
          vnST_ptabela := 0;
        end if;

        if  p_tipoPreco = 'T' then
          p_st := vnST_ptabela;
        end if;

        P_PTABELA  := Round(vnPTABELA_red + nvl(vnST_ptabela,0)+ nvl(vnvlipi_ptabela,0), p_numcasasdecvenda);


      END IF;

      --pbaserca
      IF NOT calcularst(vnpbaserca_red, -- - (nvl(vnST, 0) + nvl(P_VLIPI, 0)),
                        nvl(vnvlipi_pbaserca,0),
                        p_percvenda,
                        p_tipocalcst,
                        p_calcstpf,
                        p_mostrarpvendasemst,
                        p_consideraisentoscomopf,
                        p_calculast,
                        p_ieent,
                        p_tipofj,
                        p_pauta,
                        case when p_tipoPreco = 'N' then nvl(vniva, 0) else p_iva end,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        vnpercbaseredst,
                        p_numcasasdecvenda,
                        1,--vntipocalculo,
                        vsuffilial,
                        p_estent,
                        p_usavalorultentbasest,
                        p_usavalorultentbasest2,
                        p_valorultent,
                        vscontribuinte,
                        p_utilizaiesimplificada,
                        vsmensagem_st,
                        vnst_pbaserca,
                        vnbaseicst_pbaserca,
                        p_aceitapfcontribuinte,
                        p_usapmcbasest,
                        p_precomaxconsum,
                        p_custonfsemst,
                        p_consumidorfinal,
                        vsConsiderarIpiAliqicms2,
                        p_usavlultentmediobasest,
                        p_vlultentmes,
                        p_percbasestrj) THEN

        vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                      vsmensagem_st;
      ELSE
        if (P_TIPOCALCULOGNRE = 'C') then
          vnST_pbaserca := 0;
        end if;

        if  p_tipoPreco = 'R' then
          p_st := vnST_pbaserca;
        end if;

        P_PBASERCA := Round(vnPBASERCA_red + nvl(vnST_pbaserca,0)+ nvl(vnvlipi_pbaserca,0), p_numcasasdecvenda);

      END IF;

    end if;

    ELSE

      IF vnpercbaseredst = 0 THEN
        vnpercbaseredst := 100;
      END IF;

      if P_CALCULARIPIVENDA = 'S' then

        -----------------------------------------------------------
        --Autor: Rodrigo Santos
        --Solicitação: HIS.01467.2015
        --Data: 05/05/2015
        --Descrição: Implementação do redutor da alíquota de IPI,
        -- quando o parâmetro abaixo for informado (p_percredaliqipi > 0)
        -- assume que PCPRODUT.APLICAPERCREDALIQIPI = 'S', logo a aplicação
        -- da redução deve ser controlada pela passagem deste parâmetro.
        -- Ou seja, SE "p_percredaliqipi > 0" então PCPRODUT.APLICAPERCREDALIQIPI = 'S',
        -- ou SE "p_percredaliqipi = 0" então PCPRODUT.APLICAPERCREDALIQIPI = 'N'

        IF nvl(p_percredaliqipi,0) > 0 THEN
          vnPERCIPI_REDUZIDO := nvl(P_PERCIPIVENDA - (P_PERCIPIVENDA * (p_percredaliqipi / 100)),0);
        ELSE
          vnPERCIPI_REDUZIDO := nvl(P_PERCIPIVENDA,0);
        END IF;
        -----------------------------------------------------------

        if P_VLPAUTAIPIVENDA > 0 then
          vnVLIPI_pvenda   := P_VLPAUTAIPIVENDA;
          vnVLIPI_ptabela   := P_VLPAUTAIPIVENDA;
          vnVLIPI_pbaserca   := P_VLPAUTAIPIVENDA;

          p_percipi := 0;
        end if;

        if P_VLIPIPORKGVENDA > 0 then
          vnVLIPI_pvenda   := P_PESOBRUTO * P_VLIPIPORKGVENDA;
          vnVLIPI_ptabela   := P_PESOBRUTO * P_VLIPIPORKGVENDA;
          vnVLIPI_pbaserca   := P_PESOBRUTO * P_VLIPIPORKGVENDA;

           p_percipi := 0;
        end if;

        if vnPERCIPI_REDUZIDO > 0 THEN

          vnVLIPI_pvenda   := vnPVENDA_red * (vnPERCIPI_REDUZIDO / 100);
          vnVLIPI_ptabela   := vnptabela_red * (vnPERCIPI_REDUZIDO / 100);
          vnVLIPI_pbaserca   := vnpbaserca_red * (vnPERCIPI_REDUZIDO / 100);
          P_PERCIPI := vnPERCIPI_REDUZIDO;

        end if;
      else

        vnVLIPI_pvenda   := 0;
        vnvlipi_ptabela  := 0;
        vnvlipi_pbaserca := 0;

        P_PERCIPI := 0;
      end if;
      --Fim-Tarefa 70519

      vsuffilial := p_uffilial;

      IF p_filialnf IS NOT NULL THEN
        vsuffilial := p_uffilialnf;
      END IF;

      p_vlipi := nvl(vnvlipi_pvenda,0);

      IF p_condvenda IN (2, 7) THEN
        p_vlipi := p_vlipi * (p_percvenda / 100);
      END IF;

      --Tipo de Cálculo do IPI
      IF p_tipocalcipi = 'T2' THEN
        p_vlipi := round(p_vlipi * 100) / 100;
        vnvlipi_pvenda := round(vnvlipi_pvenda * 100) / 100;
        vnvlipi_ptabela := round(vnvlipi_ptabela * 100) / 100;
        vnvlipi_pbaserca := round(vnvlipi_pbaserca * 100) / 100;
      ELSIF p_tipocalcipi = 'A2' THEN
        p_vlipi := round(p_vlipi, 2);
        vnvlipi_pvenda := round(vnvlipi_pvenda, 2);
        vnvlipi_ptabela := round(vnvlipi_ptabela, 2);
        vnvlipi_pbaserca := round(vnvlipi_pbaserca, 2);
      ELSIF p_tipocalcipi = 'PV' THEN
        p_vlipi := round(p_vlipi, p_numcasasdecvenda);
        vnvlipi_pvenda := round(vnvlipi_pvenda, p_numcasasdecvenda);
        vnvlipi_ptabela := round(vnvlipi_ptabela, p_numcasasdecvenda);
        vnvlipi_pbaserca := round(vnvlipi_pbaserca, p_numcasasdecvenda);
      END IF;

      IF (P_TIPOPRECO IN ('T', 'R','N')) AND
       (p_calcularSTRamoAtiv = 'N')
      THEN
        vniva        := 0;
        vnAliqIcms1  := 0;
        vnAliqIcms2  := 0;
      END IF;
      --diferenciaçao de st para cliente do estado MT
      if  p_ESTENT = 'MT' AND p_UTILIZACALCULOSTMT = 'S' then

      proc_calculastMT (vnpvenda_red ,
                        vnptabela_red ,
                        vnpbaserca_red,
                        p_percipi ,
                        vnpercbaseredst,
                        p_mostrarpvendasemst,
                        p_tipofj,
                        p_utilizaiesimplificada,
                        p_consumidorfinal ,
                        p_ieent ,
                        p_contribuinte,
                        p_calculast,
                        p_estent ,
                        p_consideraisentoscomopf,
                        p_tipocalcst,
                        p_calcstpf,
                        p_numcasasdecvenda,
                        p_aceitapfcontribuinte,
                        vnvlipi_pvenda,
                        vnvlipi_ptabela,
                        vnvlipi_pbaserca,
                        p_pauta ,
                        p_iva ,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        p_margemmva,
                        p_percargatribmedia,
                        p_uffilial ,
                        p_st ,
                        p_baseicst ,
                        p_mensagem) ;


      p_pvenda   := vnpvenda_red;
      p_ptabela  := vnptabela_red;
      p_pbaserca := vnpbaserca_red;

      else

      -- p_pvenda := vnpvenda;
      IF NOT calcularst(vnpvenda_red + nvl(vnvlipi_pvenda,0),
                        nvl(vnvlipi_pvenda,0),
                        p_percvenda,
                        p_tipocalcst,
                        p_calcstpf,
                        p_mostrarpvendasemst,
                        p_consideraisentoscomopf,
                        p_calculast,
                        p_ieent,
                        p_tipofj,
                        p_pauta,
                        nvl(vniva, 0),
                        vnAliqIcms1,
                        vnAliqIcms2,
                        vnpercbaseredst,
                        p_numcasasdecvenda,
                        1,
                        vsuffilial,
                        p_estent,
                        p_usavalorultentbasest,
                        p_usavalorultentbasest2,
                        p_valorultent,
                        vscontribuinte,
                        p_utilizaiesimplificada,
                        vsmensagem_st,
                        vnst_pvenda,
                        p_baseicst,
                        p_aceitapfcontribuinte,
                        p_usapmcbasest,
                        p_precomaxconsum,
                        p_custonfsemst,
                        p_consumidorfinal,
                        vsConsiderarIpiAliqicms2,
                        p_usavlultentmediobasest,
                        p_vlultentmes,
                        p_percbasestrj ) THEN

        vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                      vsmensagem_st;
      ELSE
        p_st := vnst_pvenda;

        if (P_TIPOCALCULOGNRE = 'C') then
          vnST_pvenda := 0;
        end if;

        P_PVENDA := Round(vnPVENDA_red + nvl(vnST_pvenda, 0) + nvl(vnvlipi_pvenda,0), p_NumCasasDecVenda);

      END IF;

    --ptabela
      IF NOT calcularst(vnptabela_red + nvl(vnvlipi_ptabela,0),
                        nvl(vnvlipi_ptabela,0),
                        p_percvenda,
                        p_tipocalcst,
                        p_calcstpf,
                        p_mostrarpvendasemst,
                        p_consideraisentoscomopf,
                        p_calculast,
                        p_ieent,
                        p_tipofj,
                        p_pauta,
                        case when p_tipoPreco = 'N' then nvl(vniva, 0) else p_iva end,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        vnpercbaseredst,
                        p_numcasasdecvenda,
                        1,
                        vsuffilial,
                        p_estent,
                        p_usavalorultentbasest,
                        p_usavalorultentbasest2,
                        p_valorultent,
                        vscontribuinte,
                        p_utilizaiesimplificada,
                        vsmensagem_st,
                        vnst_ptabela,
                        vnbaseicst_ptabela,
                        p_aceitapfcontribuinte,
                        p_usapmcbasest,
                        p_precomaxconsum,
                        p_custonfsemst,
                        p_consumidorfinal,
                        vsConsiderarIpiAliqicms2,
                        p_usavlultentmediobasest,
                        p_vlultentmes,
                        p_percbasestrj ) THEN

        vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                      vsmensagem_st;
      ELSE
          if (P_TIPOCALCULOGNRE = 'C') then
            vnst_ptabela := 0;
          end if;

          if  p_tipoPreco = 'T' then
            p_st := vnst_ptabela;
          end if;

          P_PTABELA  := Round(vnPTABELA_red + nvl(vnst_ptabela,0) + nvl(vnvlipi_ptabela,0), p_numcasasdecvenda);

      END IF;

      --pbaaserca
      IF NOT calcularst(vnpbaserca_red + nvl(vnvlipi_pbaserca,0),
                        nvl(vnvlipi_pbaserca,0),
                        p_percvenda,
                        p_tipocalcst,
                        p_calcstpf,
                        p_mostrarpvendasemst,
                        p_consideraisentoscomopf,
                        p_calculast,
                        p_ieent,
                        p_tipofj,
                        p_pauta,
                        case when p_tipoPreco = 'N' then nvl(vniva, 0) else p_iva end,
                        vnAliqIcms1,
                        vnAliqIcms2,
                        vnpercbaseredst,
                        p_numcasasdecvenda,
                        1,
                        vsuffilial,
                        p_estent,
                        p_usavalorultentbasest,
                        p_usavalorultentbasest2,
                        p_valorultent,
                        vscontribuinte,
                        p_utilizaiesimplificada,
                        vsmensagem_st,
                        vnst_pbaserca,
                        vnbaseicst_pbaserca,
                        p_aceitapfcontribuinte,
                        p_usapmcbasest,
                        p_precomaxconsum,
                        p_custonfsemst,
                        p_consumidorfinal,
                        vsConsiderarIpiAliqicms2 ,
                        p_usavlultentmediobasest,
                        p_vlultentmes,
                        p_percbasestrj) THEN

        vsmensagem := 'Não foi possível realizar o cálculo do ST.' ||
                      vsmensagem_st;
      ELSE
          if (P_TIPOCALCULOGNRE = 'C') then
            vnst_pbaserca := 0;
          end if;

          if  p_tipoPreco = 'R' then
            p_st := vnst_pbaserca;
          end if;

          P_PBASERCA := Round(vnPBASERCA_red + nvl(vnst_pbaserca,0) + nvl(vnvlipi_pbaserca,0), p_numcasasdecvenda);

      END IF;

    end if;

    END IF;

    vbresult := TRUE;
    p_iva    := vniva;
    p_percbaseredst := vnpercbaseredst;


    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END calcularimpostos;


PROCEDURE calcularcmv -- 46 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,--30
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE,
   p_codst                       IN NUMBER DEFAULT 0, --40
   p_vlicmspartilha              IN NUMBER DEFAULT 0,
   p_codicmstabsn                IN NUMBER DEFAULT 0,
   p_vlrebaixacmv                in NUMBER DEFAULT 0,
   p_codfilial                   in pcfilial.codigo%type DEFAULT '',
   p_codicmtab_diferenciado      in NUMBER DEFAULT 0,
   p_custosemST                  in NUMBER DEFAULT 0

   ) IS
 BEGIN
    calcularcmv(p_abaterimpostoscomissaorca,
                    p_aplicarindicecmv,
                    p_incluircomissaosugpvendacmv,
                    p_txvenda,
                    p_tipofj,
                    p_utilizaiesimplificada,
                    p_ieent,
                    p_freteespecial,
                    p_perfreteterceiros,
                    p_perfreteespecial,
                    p_custofin,
                    p_custoreal,
                    p_perdesccusto,
                    p_codicmtab,
                    p_codicmtabpf_enulo,
                    p_codicmtabpf,
                    p_percvenda,
                    p_pvenda,
                    p_percom,
                    p_st,
                    0, -- VLFECP
                    p_vlipi,
                    p_vliss,
                    p_contribuinte,
                    p_vldifaliquotas,
                    -------------------------------------
                    --O parâmetro abaixo usa como default 0(zero) por tratamento com NVL
                    0, --p_perredcmvsimplesnac,
                    'N', --p_consumidorfinal,
                    'N', --p_consideraisentoscomopf
                    -------------------------------------
                    p_perfretecmv,
                    p_custofinest,
                    p_txvenda_item,
                    p_perdesccusto_item,
                    p_codicmtab_item,
                    p_vlcustoreal,
                    p_vlcustofin,
                    p_vldesccustocmv,
                    0 --P_CODCLI
                    );
 END calcularcmv;

 PROCEDURE calcularcmv -- 50 parametros
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlfecp                      IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER, --30
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE, --40
   p_codst                       IN NUMBER DEFAULT 0,
   p_vlicmspartilha              IN NUMBER DEFAULT 0,
   p_codicmstabsn                IN NUMBER DEFAULT 0,
   p_vlrebaixacmv                in NUMBER DEFAULT 0,
   p_codfilial                   in pcfilial.codigo%type DEFAULT '',
   p_codicmtab_diferenciado      in NUMBER DEFAULT 0,
   p_custosemST                  in NUMBER DEFAULT 0,
   p_VLDESCREDUCAOPIS            in NUMBER DEFAULT 0,
   p_DESCREDUCAOCOFINS           in NUMBER DEFAULT 0,
   p_DESCICMISENCAO              in NUMBER DEFAULT 0
   ) IS
  BEGIN
 calcularcmv -- 53 parametros, usando a 50 como base
  (p_abaterimpostoscomissaorca
  , p_aplicarindicecmv
  , p_incluircomissaosugpvendacmv
  , p_txvenda
  , p_tipofj
  , p_utilizaiesimplificada
  , p_ieent
  , p_freteespecial
  , p_perfreteterceiros
  , p_perfreteespecial
  , p_custofin
  , p_custoreal
  , p_perdesccusto
  , p_codicmtab
  , p_codicmtabpf_enulo
  , p_codicmtabpf
  , p_percvenda
  , p_pvenda
  , p_percom
  , p_st
  , p_vlfecp
  , p_vlipi
  , p_vliss
  , p_contribuinte
  , p_vldifaliquotas
  , p_perredcmvsimplesnac
  , p_consumidorfinal
  , p_consideraisentoscomopf
  , p_perfretecmv
  , p_custofinest
  , p_txvenda_item
  , p_perdesccusto_item
  , p_codicmtab_item
  , p_vlcustoreal
  , p_vlcustofin
  , p_vldesccustocmv
  , P_CODCLI
  , p_custoprecific
  , p_aplicaredTribut
  , p_bonific
  , p_codst
  , p_vlicmspartilha
  , p_codicmstabsn
  , p_vlrebaixacmv
  , p_codfilial
  , p_codicmtab_diferenciado
  , p_custosemST
  , p_VLDESCREDUCAOPIS
  , p_DESCREDUCAOCOFINS
  , p_DESCICMISENCAO
  ,0
  ,0
  ,0
   );

  END calcularcmv;

 PROCEDURE calcularcmv -- 53 parametros, usando a 50 como base
  (p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlfecp                      IN NUMBER,
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER, --30
   p_txvenda_item                OUT NUMBER,
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_aplicaredTribut             IN BOOLEAN DEFAULT FALSE,
   p_bonific                     IN BOOLEAN DEFAULT FALSE, --40
   p_codst                       IN NUMBER DEFAULT 0,
   p_vlicmspartilha              IN NUMBER DEFAULT 0,
   p_codicmstabsn                IN NUMBER DEFAULT 0,
   p_vlrebaixacmv                in NUMBER DEFAULT 0,
   p_codfilial                   in pcfilial.codigo%type DEFAULT '',
   p_codicmtab_diferenciado      in NUMBER DEFAULT 0,
   p_custosemST                  in NUMBER DEFAULT 0,
   p_VLDESCREDUCAOPIS            in NUMBER DEFAULT 0,
   p_DESCREDUCAOCOFINS           in NUMBER DEFAULT 0,
   p_DESCICMISENCAO              in NUMBER DEFAULT 0,
   p_NUMPED                      in NUMBER,
   p_NUMSEQ                      in NUMBER,
   p_CODPROD                     in NUMBER

   ) IS
    vnbasecalccomissao NUMBER := 0;
    vncodicmtabpfbonif  NUMBER := 0;
    vncodicmtabbonif  NUMBER := 0;
    vsTipoEmpresa       varchar2(4);
    vsUFFILIAL          varchar2(2);
    vsUFCLI             varchar2(2);
    vsusacmvdiferenciado    VARCHAR2(2);

    vnPercentualICMS PCTRIBUT.CODICM%TYPE;
    vsFormulaCMV     PCTRIBUT.FORMULACMV%TYPE;

    vnCustoReal       NUMBER := 0;
    TYPE T_ESTOQUE IS RECORD
        (CUSTOFIN   PCEST.CUSTOFIN%TYPE,
         CUSTOREAL   PCEST.CUSTOREAL%TYPE);
    ESTOQUE T_ESTOQUE;

    FUNCTION receberDadosEstoque(PNCODPROD IN NUMBER, PSCODFILIAL IN VARCHAR2) RETURN  T_ESTOQUE IS
      ESTOQUELOCAL T_ESTOQUE;
    BEGIN
      BEGIN
       SELECT CUSTOFIN, CUSTOREAL
         INTO ESTOQUELOCAL.CUSTOFIN, ESTOQUELOCAL.CUSTOREAL
         FROM PCEST
        WHERE CODPROD = PNCODPROD
          AND CODFILIAL = PSCODFILIAL;
      EXCEPTION
        WHEN OTHERS THEN
          ESTOQUELOCAL.CUSTOFIN  := 0;
          ESTOQUELOCAL.CUSTOREAL := 0;
      END;

       RETURN ESTOQUELOCAL;
    END;

    procedure validarCustos(ESTOQUE T_ESTOQUE, pnCustofinest IN OUT NUMBER, pnCustoREAL IN OUT NUMBER) is
    begin
       if (nvl(pnCustoREAL,0) = 0) then
         pnCustoREAL := ESTOQUE.CUSTOREAL;
       end if;

       if (nvl(pnCustofinest,0) = 0) then
         pnCustofinest := ESTOQUE.CUSTOFIN;
       end if;
    end;

  begin
    vnCustoReal   := p_custoREAL;
    p_custofinest := p_custofin;
    validarCustos(receberDadosEstoque(p_CODPROD, p_codfilial), p_custofinest, vnCustoReal);

    vnPercentualICMS := nvl(p_codicmtab, 0);
    IF p_codst > 0 THEN
       vsFormulaCMV := 'NAO INFORMADA';

       begin
         SELECT PCTRIBUT.FORMULACMV
              , CASE WHEN (((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N'))
                  -- 2º caso
                  or (p_CONSUMIDORFINAL = 'S')
                  -- 3º caso
                  or ((p_CONSIDERAISENTOSCOMOPF = 'S') and ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or (p_IEENT = 'ISENTA'))))
                  -- somente quando
                 and (p_contribuinte = 'N') and (p_codicmtabpf IS NOT NULL)
                     THEN NVL(PCTRIBUT.CODICMPF, PCTRIBUT.CODICM)
                     ELSE NVL(PCTRIBUT.CODICM,0)
                END
           INTO vsFormulaCMV
              , vnPercentualICMS
           FROM PCTRIBUT
          WHERE CODST = p_codst
            AND PCTRIBUT.FORMULACMV IS NOT NULL;
       exception
       when no_data_found then
         vsFormulaCMV := 'NAO INFORMADA';
       when others then
         vsFormulaCMV := 'NAO INFORMADA';
       end;

       if vsFormulaCMV <> 'NAO INFORMADA' then
         begin
           SELECT a.CODICMTAB
             INTO vnPercentualICMS
             FROM TABLE(funcoesvendas.CALCULAR_CMV( p_numped --número do pedido
                                                  , p_codprod --código do produto
                                                  , p_numseq --número da sequência do item no pedido
                                                  , vnPercentualICMS --Alíquota de ICMS
                                                  , p_pvenda --Preço de venda
                                                  , vsFormulaCMV --Nome da função principal
                                                  )) a;
         exception
         when no_data_found then
           vnPercentualICMS := nvl(p_codicmtab, 0);
		   vsFormulaCMV     := 'X';
         when others then
           vnPercentualICMS := nvl(p_codicmtab, 0);
		   vsFormulaCMV     := 'X';
         end;
       else  
          vnPercentualICMS := nvl(p_codicmtab, 0);
		  vsFormulaCMV     := 'X';
       end if;
	ELSE
	  vsFormulaCMV     := 'X';
    END IF;

    p_codicmtab_item := nvl(vnPercentualICMS,nvl(p_codicmtab, 0));

    --Dados para cálculo do CMV
    p_perfretecmv := p_perfreteterceiros;
    IF p_freteespecial = 'S' THEN
      p_perfretecmv := p_perfreteespecial;
    END IF;

    BEGIN
      SELECT NVL(F.UF, 'XX') INTO VSUFFILIAL
        FROM PCFILIAL F
       WHERE F.CODIGO = P_CODFILIAL;
    EXCEPTION
       WHEN OTHERS THEN
         VSUFFILIAL := 'XX';
    END;

    BEGIN
      SELECT NVL(C.ESTENT, 'XX'),
             NVL(C.USACMVDIFERENCIADO, 'N')
        INTO VSUFCLI,
             VSUSACMVDIFERENCIADO
        FROM PCCLIENT C
       WHERE C.CODCLI = P_CODCLI;
    EXCEPTION
      WHEN OTHERS THEN
        VSUFCLI    := 'XX';
    END;

    /*4346.127564.2014 - Rafael Braga*/
    if p_custoprecific > 0 and FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('PRECIFICREGIAOFORAUFSEMST', 99, 'N') = 'S'
     and vsUFFILIAL <> vsUFCLI and p_custosemST > 0 then
      p_custofinest := p_custosemST;
    end if;

    /*HIS.02027.2016 - Parametro descontinuado */
    /*if p_custoprecific > 0 and FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCULARCMVCUSTOPRECIFICACAO', 99, 'N') = 'S' then
      p_custofinest := p_custoprecific;
    end if;  */

    p_txvenda_item      := nvl(p_txvenda, 0);
    p_perdesccusto_item := nvl(p_perdesccusto, 0);

    IF vsFormulaCMV IN ('X','NAO INFORMADA') then
        p_codicmtab_item    := nvl(p_codicmtab, 0);
		/* Alterado abaixo por Rodrigo Santos
		IF  -- 1º caso
		(((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N')) or
		  -- 2º caso
		  (p_CONSUMIDORFINAL = 'S') or
		  -- 3º caso
		  ((p_CONSIDERAISENTOSCOMOPF = 'S') and
		  ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or
		  (p_IEENT = 'ISENTA'))))
		  -- somente quando
		and (p_contribuinte = 'N') and (p_codicmtabpf IS NOT NULL) then

		  p_codicmtab_item := nvl(p_codicmtabpf, 0);
		END IF;*/
		BEGIN
		   SELECT pcclient.tipoempresa INTO vsTipoEmpresa
		   FROM pcclient
			WHERE pcclient.codcli = P_CODCLI;
		  exception
			when no_data_found then
			  vsTipoEmpresa := '';
		end;
		if (vsTipoEmpresa = 'SN') and (p_codicmstabsn > 0) then
		   p_codicmtab_item := nvl(p_codicmstabsn,0);
		ELSE
		 IF FERRAMENTAS.VERIFICAR_FJ(P_CODCLI) = 'PESSOA FISICA' THEN
		   p_codicmtab_item := nvl(p_codicmtabpf, 0);
		 END IF;
		END IF;

		if((p_bonific) and--HIS.05176.2014
		not(p_aplicaredTribut) and
		(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('DEDUZIRPISCOFINSICMSDOCMV',99,'N') <> 'S'))then

		  SELECT codicmtabbonif,codicmtabpfbonif
			into vncodicmtabbonif,vncodicmtabpfbonif
			FROM PCTRIBUT WHERE CODST = p_codst;

		   IF FERRAMENTAS.VERIFICAR_FJ(P_CODCLI) = 'PESSOA FISICA' THEN
			 IF vncodicmtabpfbonif is not null THEN
			  p_codicmtab_item :=  vncodicmtabpfbonif;
			 end if;
			Else
			  IF vncodicmtabbonif is not null THEN
				p_codicmtab_item :=  vncodicmtabbonif;
			  End If;
		   end if;
		 end if;

	  IF (vsusacmvdiferenciado = 'S') and
		 (p_codicmtab_diferenciado > 0)
	  THEN
		p_codicmtab_item := p_codicmtab_diferenciado;
	  END IF;
   END IF;	 
	  

    --Tarefa 25188
 /* Solicitação : 0.080679.2015 */
  if FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_INCLUIRCOMISSAOCMVVENDA', 99, 'N') = 'S' then
    vnbasecalccomissao := p_pvenda;

    if FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ABATERIMPOSTOSCOMISSAORCA', 99, 'N') = 'S' then

      if p_abaterimpostoscomissaorca = 'S' THEN
        vnbasecalccomissao := p_pvenda - nvl(p_st, 0) - nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0);
      end if;

      if p_abaterimpostoscomissaorca = 'A' THEN
        vnbasecalccomissao := p_pvenda - nvl(p_st, 0) - nvl(p_vlipi, 0) - nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0);
      end if;

      if p_abaterimpostoscomissaorca = 'I' THEN
        vnbasecalccomissao := p_pvenda - nvl(p_vlipi, 0) - nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0);
      end if;

    end if;

   else
     vnbasecalccomissao := 0;

  end if;
 /* //Solicitação : 0.080679.2015 */

    --tarefas 43617 e 44750
    IF p_aplicarindicecmv = 'S' THEN
      p_vlcustoreal := ((vnCustoReal - ((nvl(p_perredcmvsimplesnac, 0) * vnCustoReal) / 100)) -
                       ((vnCustoReal /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlfecp,0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (nvl(p_percvenda, 100) / 100) --Tarefa 43617
                       * (p_codicmtab_item / 100)) + nvl(p_st, 0) + nvl(p_vlfecp,0) +
                       nvl(p_vlipi, 0) + nvl(p_vliss, 0) +
                       nvl(p_vldifaliquotas, 0) + nvl(p_vlicmspartilha,0) - nvl(p_vlrebaixacmv,0));

      p_vlcustofin  := ((p_custofinest - ((nvl(p_perredcmvsimplesnac, 0) * p_custofinest) / 100)) -
                       ((p_custofinest /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlfecp,0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (nvl(p_percvenda, 100) / 100) --Tarefa 43617
                       * (p_codicmtab_item / 100)) + nvl(p_st, 0) + nvl(p_vlfecp,0) +
                       nvl(p_vlipi, 0) + nvl(p_vliss, 0) +
                       nvl(p_vldifaliquotas, 0) + nvl(p_vlicmspartilha,0) - nvl(p_vlrebaixacmv,0));
    ELSE
      p_vlcustoreal := ((vnCustoReal - ((nvl(p_perredcmvsimplesnac, 0) * vnCustoReal) / 100)) -
                       ((vnCustoReal /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0)- nvl(p_vlfecp,0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (p_codicmtab_item / 100)) + nvl(p_st, 0) + nvl(p_vlfecp,0) + nvl(p_vlipi, 0) +
                       nvl(p_vliss, 0) + nvl(p_vldifaliquotas, 0)+ nvl(p_vlicmspartilha,0) - nvl(p_vlrebaixacmv,0));

      p_vlcustofin  := ((p_custofinest - ((nvl(p_perredcmvsimplesnac, 0) * p_custofinest) / 100)) -
                       ((p_custofinest /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlfecp,0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (p_codicmtab_item / 100)) + nvl(p_st, 0) + nvl(p_vlfecp,0) + nvl(p_vlipi, 0) +
                       nvl(p_vliss, 0) + nvl(p_vldifaliquotas, 0)+ nvl(p_vlicmspartilha,0) - nvl(p_vlrebaixacmv,0));

/*((pdCUSTOFINEST) - ((pdCUSTOFINEST) * pdPERDESCCUSTO_ITEM / 100) +
       (pdPVENDA * pdTXVENDA_ITEM / 100) + (vnBASECALCCOMISSAO * pdPERCOM / 100) +
       (pdPVENDA * pdPERFRETECMV / 100) +
       ((pdPVENDA - pdST - pdVLIPI - pdVLISS - pdVLDifAliquotas) * (pdCODICMTAB_ITEM / 100))
       + pdST + pdVLIPI + pdVLISS + pdVLDifAliquotas);    */


    END IF;

    if(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('DEDUZIRPISCOFINSICMSDOCMV',P_CODFILIAL,'N') <> 'S')then
      p_vlcustofin  := p_vlcustofin  - p_VLDESCREDUCAOPIS - p_DESCREDUCAOCOFINS - p_DESCICMISENCAO;
      p_vlcustoreal := p_vlcustoreal - p_VLDESCREDUCAOPIS - p_DESCREDUCAOCOFINS - p_DESCICMISENCAO;
    end if;

    -- tarefa 56190
    IF nvl(p_incluircomissaosugpvendacmv, 'S') = 'N' THEN
      p_vlcustoreal := p_vlcustoreal -
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100);
      p_vlcustofin  := p_vlcustofin -
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100);
    END IF;
    -- Valor do Desconto no Custo Financeiro
    p_vldesccustocmv := (round(((nvl(p_custofinest, 0) *
                               nvl(p_perdesccusto_item, 0) / 100) * 100))) / 100;

   END;

 FUNCTION calcularredsimplesnac --21 parametros
  (p_custofin                 in pcest.custofin%type,
   p_custonfsemst             in pcest.custonfsemst%type,
   p_custonfsemstguiaultent   in pcest.custonfsemstguiaultent%type,
   p_ivaultent                in pcest.ivaultent%type,
   p_aliqicms1ultent          in pcest.aliqicms1ultent%type,
   p_aliqicms2ultent          in pcest.aliqicms2ultent%type,
   p_redbaseivaultent         in pcest.redbaseivaultent%type,
   p_percicmsfretefobstultent in pcest.percicmsfretefobstultent%type,
   p_vlfreteconhecultent      in pcest.vlfreteconhecultent%type,
   p_percaliqextguiaultent    in pcest.percaliqextguiaultent%type,
   p_vlstultent               in pcest.vlstultent%type,
   p_baseicmsultent           in pcest.baseicmsultent%type,
   p_vlstguiaultent           in pcest.vlstguiaultent%type,
   P_PERCREDPVENDASIMPLESNAC  in number,
   p_numcasasdecvenda         in pcconsum.numcasasdecvenda%type,
   p_param1                   in number,
   p_param2                   in number,
   p_param3                   in number,
   p_param4                   in number,
   p_mensagem                 out varchar2,
   p_vlreducao                out number) RETURN BOOLEAN IS



    vsMensagem  VARCHAR2(500);
    vnVlReducao NUMBER;
    vRetorno BOOLEAN;
  BEGIN
     vRetorno := calcularredsimplesnac (p_custofin,
                                   p_custonfsemst,
                                   p_custonfsemstguiaultent,
                                   p_ivaultent,
                                   p_aliqicms1ultent,
                                   p_aliqicms2ultent,
                                   p_redbaseivaultent,
                                   p_percicmsfretefobstultent,
                                   p_vlfreteconhecultent,
                                   p_percaliqextguiaultent,
                                   p_vlstultent,
                                   p_baseicmsultent,
                                   p_vlstguiaultent,
                                   P_PERCREDPVENDASIMPLESNAC,
                                   p_numcasasdecvenda,
                                   p_param1,
                                   p_param2,
                                   p_param3,
                                   p_param4,
                                   0,--p_PVenda
                                   0,--p_PERCIPIVENDA
                                   0,--p_vlpautaipivenda
                                   0,--p_vlipiporkgvenda
                                   0,--p_PAUTA_tribut
                                   0,--p_pesobruto
                                   0,--p_percdifaliquotas
                                   0,--p_valorultent
                                   0,--p_iva
                                   0,--p_percbaseredst
                                   0,--p_aliqicms1
                                   0,--p_aliqicms2
                                   0,--p_calcularstcomipi
                                   'PV',--p_tipocalcst
                                   'PV',--p_tipocalcipi
                                   'N',--p_usavalorultentbasest
                                   'N',--p_usavalorultentbasest2
                                   'N',--p_CALCULARIPIVENDA
                                   NULL,--p_uffilial
                                   NULL,--p_estent
                                   NULL,--p_CODFILIAL
                                   vsMensagem,
                                   vnVlReducao);

    p_mensagem     := vsMensagem;
    p_vlreducao     := vnVlReducao;
    RETURN vRetorno;

  END calcularredsimplesnac;

  FUNCTION calcularredsimplesnac --43 parametros
    (p_custofin                 in pcest.custofin%type,
     p_custonfsemst             in pcest.custonfsemst%type,
     p_custonfsemstguiaultent   in pcest.custonfsemstguiaultent%type,
     p_ivaultent                in pcest.ivaultent%type,
     p_aliqicms1ultent          in pcest.aliqicms1ultent%type,
     p_aliqicms2ultent          in pcest.aliqicms2ultent%type,
     p_redbaseivaultent         in pcest.redbaseivaultent%type,
     p_percicmsfretefobstultent in pcest.percicmsfretefobstultent%type,
     p_vlfreteconhecultent      in pcest.vlfreteconhecultent%type,
     p_percaliqextguiaultent    in pcest.percaliqextguiaultent%type,
     p_vlstultent               in pcest.vlstultent%type,
     p_baseicmsultent           in pcest.baseicmsultent%type,
     p_vlstguiaultent           in pcest.vlstguiaultent%type,
     P_PERCREDPVENDASIMPLESNAC  in number,
     p_numcasasdecvenda         in pcconsum.numcasasdecvenda%type,
     p_param1                   in number,
     p_param2                   in number,
     p_param3                   in number,
     p_param4                   in number,
     ---novos parâmetros
     p_PVenda                  in number,
     p_PERCIPIVENDA            in number,
     p_vlpautaipivenda         in number,
     p_vlipiporkgvenda         in number,
     p_PAUTA_tribut            in number,
     p_pesobruto               in number,
     p_percdifaliquotas        in number,
     p_valorultent             in number,
     p_iva                     in number,
     p_percbaseredst           in number,
     p_aliqicms1               in number,
     p_aliqicms2               in number,
     p_calcularstcomipi        in pcconsum.calcularstcomipi%TYPE,
     p_tipocalcst              in pcconsum.tipocalcst%TYPE,
     p_tipocalcipi             in pcconsum.tipocalcipi%TYPE,
     p_usavalorultentbasest    in pctribut.usavalorultentbasest%TYPE,
     p_usavalorultentbasest2   in pctribut.usavalorultentbasest2%TYPE,
     p_CALCULARIPIVENDA        in VARCHAR2,
     p_uffilial                in VARCHAR2,
     p_estent                  in VARCHAR2,
     p_CODFILIAL               in VARCHAR2,
     p_mensagem                 out varchar2,
     p_vlreducao                out number,
     p_AlteraFatorAjusteIVASN   IN  pctribut.alterafatorajusteivasn%TYPE DEFAULT 'N'
     ) RETURN BOOLEAN IS

    vnValor_IPI           NUMBER;
    vnPVendaSemImp        NUMBER;
    vnBase01              NUMBER;
    vnBase02              NUMBER;
    vnNovoPVendaSimpNasc  NUMBER;
    vnST                  NUMBER;
    vnST1                 NUMBER;
    vnST2                 NUMBER;
    vnPercIPI_Venda       NUMBER;
    vnPercbaseredst       NUMBER;
    vnPercREDPvendaSimplesNac NUMBER;

    vbresult      BOOLEAN;
    vsmensagem    VARCHAR2(1000);
    vsmensagem_st VARCHAR2(1000);

    vnstguia      number;

    vncalc1       number;
    vncalc2       number;
    vnFatorAjuste     NUMBER;
    vnFatorAjusteGuia NUMBER;
    vbcalculosemimposto BOOLEAN;
    vsmensagemprecosemimposto VARCHAR2(500);
  BEGIN
    vnPercIPI_Venda := NVL(p_PERCIPIVENDA,0);
    vnPercbaseredst :=  NVL(p_percbaseredst,0);
    vnPercREDPvendaSimplesNac :=  NVL(P_PERCREDPVENDASIMPLESNAC,0);

    if vnPercbaseredst = 0 then
      vnPercbaseredst := 100;
    END IF;

    if vnPercREDPvendaSimplesNac = 0 then
      vnPercREDPvendaSimplesNac := 100;
    END IF;

    vbresult := FALSE;

    -----------------------------------------------------------
    --Autor: Rodrigo Santos
    --Solicitação: HIS.03842.2014
    --Data: 25/11/2014
    --Descrição: Implementação da nova legislação referente ao Simples Nacional (SC).
    -----------------------------------------------------------
    IF ((p_uffilial = p_estent) AND (p_AlteraFatorAjusteIVASN = 'S')) AND
       (p_iva = 0) AND (p_PAUTA_tribut = 0) AND
       (p_aliqicms1 <= p_aliqicms2)
    THEN --Indica que não tem ST
      vnst     := 0;
      vnstguia := 0;

      vnFatorAjuste := (1 - (P_ALIQICMS2ULTENT / 100)) / (1 - (P_ALIQICMS1ULTENT / 100));
      vnFatorAjusteGuia := (1 - (P_PERCALIQEXTGUIAULTENT / 100)) / (1 - (P_ALIQICMS1ULTENT / 100));

      IF (nvl(p_CUSTONFSEMST, 0) = 0) AND
         (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) = 0)
      THEN
        vnST     := 0;
        vnstguia := 0;

      ELSIF (nvl(P_CUSTONFSEMST, 0) > 0) AND
            (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) = 0)
      THEN

        SELECT ((((nvl(P_CUSTONFSEMST, 0) *
               (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
               (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                 0,
                                 100,
                                 P_PERCREDPVENDASIMPLESNAC) / 100))))
               * vnFatorAjuste
               ) *
               (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -
               (nvl(P_BASEICMSULTENT, 0) * (nvl(P_ALIQICMS2ULTENT, 0) / 100)))
          INTO vnst
          FROM dual;

        IF vnst < 0 THEN
          vnst := 0;
        END IF;

      ELSIF (nvl(P_CUSTONFSEMST, 0) = 0) AND
            (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) > 0)
      THEN

        SELECT ((((nvl(P_CUSTONFSEMSTGUIAULTENT, 0) *
               (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
               (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                 0,
                                 100,
                                 P_PERCREDPVENDASIMPLESNAC) / 100))))
               * vnFatorAjusteGuia
               ) *
               (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -
               (nvl(P_BASEICMSULTENT, 0) *
               (NVL(P_PERCALIQEXTGUIAULTENT, 0) / 100) +
               ((NVL(P_VLFRETECONHECULTENT, 0)) *
               (NVL(P_PERCICMSFRETEFOBSTULTENT, 0)) / 100)))
          INTO vnstguia
          FROM dual;

        IF vnstguia < 0 THEN
          vnstguia := 0;
        END IF;

      ELSIF (nvl(P_CUSTONFSEMST, 0) > 0) AND
            (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) > 0)
      THEN

        SELECT ((((nvl(P_CUSTONFSEMST, 0) *
               (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
               (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                 0,
                                 100,
                                 P_PERCREDPVENDASIMPLESNAC) / 100))))
               * vnFatorAjuste
               ) *
               (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -
               (nvl(P_BASEICMSULTENT, 0) * (nvl(P_ALIQICMS2ULTENT, 0) / 100))

               )
          INTO vnst
          FROM dual;

        IF vnst < 0 THEN
          vnst := 0;
        END IF;

        SELECT ((((nvl(P_CUSTONFSEMSTGUIAULTENT, 0) *
               (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
               (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                 0,
                                 100,
                                 P_PERCREDPVENDASIMPLESNAC) / 100))))
               * vnFatorAjusteGuia
               ) *
               (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -

               (NVL(P_VLFRETECONHECULTENT, 0) *
               (NVL(P_PERCALIQEXTGUIAULTENT, 0) / 100)))
          INTO vnstguia
          FROM dual;

        IF vnstguia < 0 THEN
          vnstguia := 0;
        END IF;

      END IF;

      vncalc1 := (nvl(p_vlstultent, 0) - vnst) ;
      vncalc2 := (nvl(p_vlstguiaultent, 0) - vnstguia);

      if vncalc1 < 0 then
        vncalc1 := 0;
      end if;

      if vncalc2 < 0 then
        vncalc2 := 0;
      end if;

      p_vlreducao := nvl(vncalc1,0) + nvl(vncalc2,0);

      if p_vlreducao < 0 THEN
        p_vlreducao := 0;
      end if;

      p_vlreducao := round(p_vlreducao, 2);

      if nvl(p_PERCREDPVENDASIMPLESNAC, 0) = 0 THEN
        p_vlreducao := 0;
      end if;

      vbresult := TRUE;
    -----------------------------------------------------------
    ELSIF (p_iva = 0) and (p_PAUTA_tribut = 0) and
       (p_aliqicms1 <= p_aliqicms2) then --Indica que não tem ST

          vnst     := 0;
          vnstguia := 0;

          if (nvl(p_CUSTONFSEMST, 0) = 0) and
             (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) = 0) THEN
            vnST     := 0;
            vnstguia := 0;

          elsif (nvl(P_CUSTONFSEMST, 0) > 0) and
                (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) = 0) THEN

            select ((((nvl(P_CUSTONFSEMST, 0) *
                   (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
                   (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                     0,
                                     100,
                                     P_PERCREDPVENDASIMPLESNAC) / 100)))) *
                   (decode(NVL(P_REDBASEIVAULTENT, 100),
                              0,
                              100,
                              nvl(P_REDBASEIVAULTENT, 100)) / 100)) *
                   (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -
                   (nvl(P_BASEICMSULTENT, 0) * (nvl(P_ALIQICMS2ULTENT, 0) / 100)))
              into vnst
              from dual;

            if vnst < 0 then
              vnst := 0;

            end if;

          elsif (nvl(P_CUSTONFSEMST, 0) = 0) and
                (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) > 0) THEN

            select ((((nvl(P_CUSTONFSEMSTGUIAULTENT, 0) *
                   (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
                   (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                     0,
                                     100,
                                     P_PERCREDPVENDASIMPLESNAC) / 100)))) *
                   (decode(NVL(P_REDBASEIVAULTENT, 100),
                              0,
                              100,
                              nvl(P_REDBASEIVAULTENT, 100)) / 100)) *
                   (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -
                   (nvl(P_BASEICMSULTENT, 0) *
                   (NVL(P_PERCALIQEXTGUIAULTENT, 0) / 100) +
                   ((NVL(P_VLFRETECONHECULTENT, 0)) *
                   (NVL(P_PERCICMSFRETEFOBSTULTENT, 0)) / 100)))
              into vnstguia
              from dual;

            if vnstguia < 0 then
              vnstguia := 0;
            end if;

          elsif (nvl(P_CUSTONFSEMST, 0) > 0) AND
                (nvl(P_CUSTONFSEMSTGUIAULTENT, 0) > 0) THEN

            select ((((nvl(P_CUSTONFSEMST, 0) *
                   (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
                   (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                     0,
                                     100,
                                     P_PERCREDPVENDASIMPLESNAC) / 100)))) *
                   (decode(NVL(P_REDBASEIVAULTENT, 100),
                              0,
                              100,
                              nvl(P_REDBASEIVAULTENT, 100)) / 100)) *
                   (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -
                   (nvl(P_BASEICMSULTENT, 0) * (nvl(P_ALIQICMS2ULTENT, 0) / 100))

                   )
              into vnst
              from dual;

            if vnst < 0 then
              vnst := 0;
            end if;

            select ((((nvl(P_CUSTONFSEMSTGUIAULTENT, 0) *
                   (1 + ((decode(nvl(P_IVAULTENT, 0), 0, 100, P_IVAULTENT) / 100) *
                   (decode(nvl(P_PERCREDPVENDASIMPLESNAC, 0),
                                     0,
                                     100,
                                     P_PERCREDPVENDASIMPLESNAC) / 100)))) *
                   (decode(NVL(P_REDBASEIVAULTENT, 100),
                              0,
                              100,
                              nvl(P_REDBASEIVAULTENT, 100)) / 100)) *
                   (nvl(P_ALIQICMS1ULTENT, 0) / 100)) -

                   (NVL(P_VLFRETECONHECULTENT, 0) *
                   (NVL(P_PERCALIQEXTGUIAULTENT, 0) / 100)))
              into vnstguia
              from dual;

            if vnstguia < 0 then

              vnstguia := 0;
            end if;

          end if;

           vncalc1 := (nvl(p_vlstultent, 0) - vnst) ;
           vncalc2 := (nvl(p_vlstguiaultent, 0) - vnstguia);

           if vncalc1 < 0 then
              vncalc1 := 0;
           end if;

           if vncalc2 < 0 then
              vncalc2 := 0;
           end if;

           p_vlreducao := nvl(vncalc1,0) + nvl(vncalc2,0);


          if p_vlreducao < 0 then

            p_vlreducao := 0;

          end if;

          p_vlreducao := round(p_vlreducao, 2);

          if nvl(p_PERCREDPVENDASIMPLESNAC, 0) = 0 then

            p_vlreducao := 0;

          end if;

          vbresult := TRUE;

    ELSE

          vbcalculosemimposto := calculo_preco_sem_impostos(nvl(p_PERCIPIVENDA, 0),
                                                            p_vlpautaipivenda,
                                                            p_vlipiporkgvenda,
                                                            p_pvenda,
                                                            p_PAUTA_tribut,
                                                            p_pesobruto,
                                                            0, --p_percdifaliquotas,
                                                            vnPercIPI_Venda,
                                                            p_valorultent,
                                                            p_iva,
                                                            vnPercbaseredst,
                                                            p_aliqicms1,
                                                            p_aliqicms2,
                                                            p_usavalorultentbasest,
                                                            p_usavalorultentbasest2,
                                                            p_uffilial,
                                                            p_estent,
                                                            vnPVendaSemImp,
                                                            vsmensagemprecosemimposto);


        vnValor_IPI := 0;
        if p_CALCULARIPIVENDA = 'S' then

          if p_vlpautaipivenda > 0 then
            vnValor_IPI := p_vlpautaipivenda;
          end if;

          if p_vlipiporkgvenda > 0 then
            vnValor_IPI := p_pesobruto * p_vlipiporkgvenda;
          end if;

          if p_PERCIPIVENDA > 0 then
            vnValor_IPI := (vnPVendaSemImp ) * (nvl(p_PERCIPIVENDA, 0) / 100);
          end if;

        else
          vnValor_IPI := 0;
        END IF;

        --Tipo de Cálculo do IPI
        IF p_tipocalcipi = 'T2' THEN
          vnValor_IPI := round(vnValor_IPI * 100) / 100;
        ELSIF p_tipocalcipi = 'A2' THEN
          vnValor_IPI := round(vnValor_IPI, 2);
        ELSIF p_tipocalcipi = 'PV' THEN
          vnValor_IPI := round(vnValor_IPI, p_numcasasdecvenda);
        END IF;

        vnBase01 := vnPVendaSemImp;
        vnBase02 := vnPVendaSemImp;
        vnST := 0;

        if p_calcularstcomipi = 'S' then
          vnBase01 := vnPVendaSemImp + vnValor_IPI;
        END IF;

        if vnPercbaseredst = 0 then
          vnPercbaseredst := 100;
        END IF;

        if vnPercREDPvendaSimplesNac = 0 then
          vnPercREDPvendaSimplesNac := 100;
        END IF;

        if p_PAUTA_tribut = 0 then
          vnST1 :=
           ((vnBase01 * (1 + (((p_iva / 100) * (vnPercREDPvendaSimplesNac / 100))))
             ) * (vnPercbaseredst / 100)) * (p_aliqicms1 / 100);
        else
          vnST1 := p_PAUTA_tribut * (p_aliqicms1 / 100);
        END IF;

        vnST2 := (vnBase02 * (p_aliqicms2 / 100));

        vnST := vnST1 - vnST2;

        if vnST < 0 then
          vnST := 0;
        END IF;

        vnNovoPVendaSimpNasc := vnPVendaSemImp + vnST;

        if p_CALCULARIPIVENDA = 'S' then
          vnNovoPVendaSimpNasc := vnNovoPVendaSimpNasc + vnValor_IPI;
        END IF;


        if vnST = 0 THEN
          p_vlreducao               := 0;
          vnNovoPVendaSimpNasc      := 0;
        ELSIF vnNovoPVendaSimpNasc < p_pvenda then
          p_vlreducao := p_pvenda - vnNovoPVendaSimpNasc;
        else
          p_vlreducao := 0;
        END IF;

        vbresult := TRUE;

    END IF;

    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular impostos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;

  END calcularredsimplesnac;

  --Tem a politica prioritaria e também retorna qual percentual irá utilizar para deb/cred de rca
  FUNCTION validarpoliticasdesconto -- 23 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_alteraptabela            out varchar2,
   p_pbaserca                 out number) RETURN BOOLEAN IS

    vbresult        BOOLEAN;

  BEGIN

    vbresult := validarpoliticasdesconto(--25 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         NULL, --p_param,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         p_alteraptabela,
                                         p_pbaserca,
                                         'N', --p_naousarautdebcredpoldesc,
                                         NULL, --p_param1,
                                         NULL --p_param2
                                        );

    p_prioritaria := 'N';
    p_questionausoprioritaria := 'N';

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION calcularst -- 37 parametros
  (p_pvenda                 IN NUMBER,
   p_vlipi                  IN NUMBER,
   p_percvenda              IN NUMBER,
   p_tipocalcst             IN VARCHAR2,
   p_calcstpf               IN VARCHAR2,
   p_mostrarpvendasemst     IN VARCHAR2,
   p_consideraisentoscomopf IN VARCHAR2,
   p_calculast              IN VARCHAR2,
   p_ieent                  IN VARCHAR2,
   p_tipofj                 IN VARCHAR2,--10
   p_pauta                  IN NUMBER,
   p_iva                    IN NUMBER,
   p_aliqicms1              IN NUMBER,
   p_aliqicms2              IN NUMBER,
   p_percbaseredst          IN OUT NUMBER,
   p_numcasasdecvenda       IN NUMBER,
   p_tipocalculo            IN NUMBER,
   p_uffilial               IN VARCHAR2,
   p_estent                 IN VARCHAR2,
   p_usavalorultentbasest   IN VARCHAR2,--20
   p_usavalorultentbasest2  IN VARCHAR2,
   p_valorultent            IN NUMBER,
   p_contribuinte           IN VARCHAR2,
   p_utilizaiesimplificada  IN VARCHAR2,
   p_mensagem               OUT VARCHAR2,
   p_st                     OUT NUMBER,
   p_baseicst               OUT NUMBER,
   p_aceitapfcontribuinte   IN pcconsum.aceitapfcontribuinte%type default 'S',
   p_usapmcbasest           IN pctribut.usapmcbasest%type default 'N',
   p_precomaxconsum         IN pcprodut.precomaxconsum%type default 0,--30
   p_custonfsemst           IN pcest.custonfsemst%type default 0,
   p_consumidorfinal        IN pcclient.consumidorfinal%type default 'N',
   p_consideraripialiqicms2 in varchar2 default 'N',
   p_usavlultentmediobasest in pctribut.usavlultentmediobasest%type default 'N',
   p_vlultentmes            in pctabpr.vlultentmes%type default 0,
   p_percbasestrj           in pctribut.PERCBASESTRJ%type default 0,
   p_calculaStRamoAtiv      IN pcativi.CALCULAST%TYPE DEFAULT 'S'
   ) RETURN BOOLEAN IS

    vbresult     BOOLEAN;
    vntempst     NUMBER;
    vstempmsg    VARCHAR2(1000);
    vnindicest   NUMBER;
    vnprecosemst NUMBER;
    vnbcst       NUMBER;
    vnst1        NUMBER;
    vnst2        NUMBER;
    vnPVENDA_Red number;
    vnpvenda     number;

    vscontribuinte pcclient.contribuinte%type;
    vbpessoafisica  boolean;
    vnst         number;
    vncustonfsemst pcest.custonfsemst%type;

    vnvlultent     pcest.valorultent%type;

    vnvlSTMinRJ    pcpedi.st%type;

  BEGIN
    vbresult     := FALSE;
    vntempst     := 0;
    vstempmsg    := '';
    vnindicest   := 0;
    vnprecosemst := 0;


    vncustonfsemst := p_custonfsemst;

    if nvl(p_custonfsemst,0) = 0 then

      vncustonfsemst := p_valorultent;
    end if;

    IF NVL(p_percbaseredst,0) = 0 THEN
      p_percbaseredst := 100;
    END IF;


    vscontribuinte := p_contribuinte;

     -- Definindo se é Pessoa Física
    if (p_AceitaPFContribuinte = 'N') then
      vscontribuinte := p_AceitaPFContribuinte;
    end if;

    vnpvenda := p_pvenda;

    if (p_UfFilial = p_EstEnt)
      and (p_UsaValorUltEntBaseST2 = 'S') then
      vnPVENDA := vnCustoNFSemST;
    end if;

    vnPVENDA_Red := vnPVENDA * (p_PERCVENDA / 100); -- Tarefa 57899

    vnPVENDA_Red := vnPVENDA_Red - nvl(p_vlipi,0);

  if (p_USAPMCBASEST = 'S') and
       (p_PRECOMAXCONSUM > 0) then -- Tarefa 132424

        vnBCST := (p_PRECOMAXCONSUM * (p_PERCBASEREDST / 100));
        p_BaseICST := vnBCST;
        vnST1 := (vnBCST * (p_ALIQICMS1 / 100));
        vnST2 := (vnPVENDA_Red * (p_ALIQICMS2 / 100));
        vnTempST := vnST1 - vnST2;


    else

      --ST MG
      if p_usavlultentmediobasest = 'S' then

          if nvl(p_vlultentmes,0) > 0 then
             vnvlultent := p_vlultentmes;
          else
             vnvlultent := p_valorultent;
          end if;

          vnBCST     := ((vnvlultent  + nvl(p_vlipi,0)) *
                          (1 + (p_Iva / 100)) * (p_percbaseredst/ 100));

          p_baseicst := vnBCST;

          vnST1      := (p_baseicst * (p_AliqIcms1 / 100));
          vnST2      := ((vnvlultent) * (p_AliqIcms2 / 100));
          vnTempST   := vnST1 - vnST2;

      else

          --Cálculo do ST - Sem IPI
          IF (p_vlipi = 0) AND (p_tipocalculo = 0) THEN
            IF p_pauta = 0 THEN
              IF (p_usavalorultentbasest = 'S') AND (p_uffilial = p_estent) THEN
                vnbcst := ((vncustonfsemst + nvl(p_vlipi, 0)) *
                              (1 + (p_iva / 100))) * (p_percbaseredst / 100);

                if nvl(p_percbasestrj,0) > 0 then
                  vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
                else
                  vnvlstminrj := 0;
                end if;

                p_baseicst := vnbcst  ;

                vnst1      := (vnbcst * (p_aliqicms1 / 100));

                 if p_ConsiderarIpiAliqicms2 = 'S'then
                    vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                 else

                    if p_usavalorultentbasest2 = 'N' then
                      vnST2 := (vnPVENDA_Red * (p_ALIQICMS2 / 100));
                    else
                      vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                    end if;


                 end if;

                vntempst := vnst1 - vnst2;

                if nvl(vnvlstminrj,0) > 0 and vnTempSt < (vnvlSTMinRJ) then
                   vnTempST := vnvlSTMinRJ;
                end if;

              ELSE
                vnbcst := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * ( 1 + (p_iva/100)) * (p_percbaseredst/100));

                p_baseicst := vnbcst;

                if nvl(p_percbasestrj,0) > 0 then
                  vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
                else
                  vnvlstminrj := 0;
                end if;

                vnst1 := vnbcst * (p_aliqicms1/100);

                 if p_ConsiderarIpiAliqicms2 = 'S'then
                    vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                 else

                    if p_usavalorultentbasest2 = 'N' then
                      vnST2 := (vnPVENDA_Red * (p_ALIQICMS2 / 100));
                    else
                      vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                    end if;


                 end if;

                vntempst := vnst1 - vnst2;

                if nvl(vnvlstminrj,0) > 0 and vnTempSt < (vnvlSTMinRJ) then
                   vnTempST := vnvlSTMinRJ;
                end if;

                p_st := vntempst;

                IF p_st < 0 THEN
                  p_st := 0;
                END IF;

              END IF;
            ELSE
              vnbcst   := (p_pauta * (p_percbaseredst / 100));
              p_baseicst   := vnbcst;


              if nvl(p_percbasestrj,0) > 0 then
                 vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
              else
                 vnvlstminrj := 0;
              end if;

              vnst1      := (vnbcst * (p_aliqicms1 / 100));

              if p_ConsiderarIpiAliqicms2 = 'S'then
                vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
              else

                if p_usavalorultentbasest2 = 'N' then
                  vnST2 := (vnPVENDA_Red * (p_ALIQICMS2 / 100));
                else
                  vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                end if;

              end if;

              vntempst := vnst1 - vnst2;

              if nvl(vnvlstminrj,0) > 0 and vnTempSt < (vnvlSTMinRJ) then
                 vnTempST := vnvlSTMinRJ;
              end if;

            END IF;
          ELSE
            ----Cálculo do ST - Com IPI - Neste caso o pvenda está sem st
            --se p_TipoCalculo for <> 0, então o cálculo é a partir de preço sem st
            IF p_pauta = 0 THEN
              IF (p_usavalorultentbasest = 'S') AND (p_uffilial = p_estent) THEN
                vnbcst     := ((vncustonfsemst + nvl(p_vlipi, 0)) *
                              (1 + (p_iva / 100)) * (p_percbaseredst / 100));
                p_baseicst := vnbcst;

                if nvl(p_percbasestrj,0) > 0 then
                  vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
                else
                  vnvlstminrj := 0;
                end if;

                vnst1      := (vnbcst * (p_aliqicms1 / 100));

                if p_ConsiderarIpiAliqicms2 = 'S' then
                  vnST2 := ((vnPVENDA_Red + p_VLIPI) * (p_ALIQICMS2 / 100));
                else

                  if p_usavalorultentbasest2 = 'N' then
                    --vnST2 := ((vnPVENDA_Red - p_VLIPI) * (p_ALIQICMS2 / 100));
                    vnST2 := ((vnPVENDA_Red ) * (p_ALIQICMS2 / 100));
                  else
                    vnST2 := ((vnPVENDA_Red) * (p_ALIQICMS2 / 100));
                  end if;
                end if;

                vntempst := vnst1 - vnst2;

                if nvl(vnvlstminrj,0) > 0 and vnTempSt < (vnvlSTMinRJ) then
                  vnTempST := vnvlSTMinRJ;
                end if;

              ELSE
                vnbcst     := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (1 + (p_iva / 100)) *
                              (p_percbaseredst / 100));

                if nvl(p_percbasestrj,0) > 0 then
                  vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
                else
                  vnvlstminrj := 0;
                end if;

                p_baseicst := vnbcst;

                vnst1      := (vnbcst * (p_aliqicms1 / 100));

                if p_ConsiderarIpiAliqicms2 = 'S'then
                  vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                else
                  vnST2 := (vnPVENDA_Red * (p_ALIQICMS2 / 100));
                end if;

                vntempst   := vnst1 - vnst2;

                if nvl(vnvlstminrj,0) > 0 and vnTempSt < (vnvlSTMinRJ) then
                   vnTempST := vnvlSTMinRJ;
                end if;

              END IF;
            ELSE

              vnbcst   := (p_pauta * (p_percbaseredst / 100));
              p_baseicst   := vnbcst;

              if nvl(p_percbasestrj,0) > 0 then
                 vnvlSTMinRJ :=  vnBCST * (p_PERCBASESTRJ/100);
              else
                 vnvlstminrj := 0;
              end if;

              vnst1      := (vnbcst * (p_aliqicms1 / 100));

              if p_ConsiderarIpiAliqicms2 = 'S'then
                vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
              else

                if p_usavalorultentbasest2 = 'N' then
                  vnST2 := (vnPVENDA_Red * (p_ALIQICMS2 / 100));
                else
                  vnST2 := ((vnPVENDA_Red + nvl(p_VLIPI,0)) * (p_ALIQICMS2 / 100));
                end if;

              end if;

              vntempst := vnst1 - vnst2;

              if nvl(vnvlstminrj,0) > 0 and vnTempSt < (vnvlSTMinRJ) then
                 vnTempST := vnvlSTMinRJ;
              end if;
            END IF;
          END IF;

    end if;
  end if;


    if ((p_PAUTA = 0)
      or (p_IVA = 0)
      or (p_PRECOMAXCONSUM = 0))
      and (p_ALIQICMS1 = 0)
      and (p_ALIQICMS2 = 0) then
      p_BaseICST := 0;
     end if;

    IF (p_mostrarpvendasemst = 'N') OR
       ((p_mostrarpvendasemst = 'S') AND (p_tipocalculo = 1)) THEN
      --Cliente isento de ST
      IF p_calculast = 'N' THEN
        vntempst   := 0;
        p_baseicst := 0;
      END IF;
      --Cálcula ST p/ Pessoa Física?
      IF p_calcstpf = 'N' THEN
        IF p_tipofj = 'F' THEN
          vntempst   := 0;
          p_baseicst := 0;
        END IF;
      END IF;

      IF p_calculaStRamoAtiv = 'N' THEN
        vntempst   := 0;
        p_baseicst := 0;

      end IF;
    END IF;
    --Calcular ST - Truncar com 2 casas decimais
    IF p_tipocalcst = 'T2' THEN
      vntempst := trunc((vntempst) * 100) / 100;
    ELSIF p_tipocalcst = 'A2' THEN
      vntempst := round(vntempst,2);
    ELSIF p_tipocalcst = 'PV' THEN
      vntempst := round(vntempst, p_numcasasdecvenda);
    END IF;
    --Se ST for menor que 0, torná-lo 0
    IF vntempst < 0 THEN
      vntempst := 0;
   -- ELSIF vntempst = 0 THEN
      --p_baseicst := 0;
    END IF;


    p_st     := vntempst;
    vbresult := TRUE;
    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao calcular ST: ' || SQLCODE || '-' || SQLERRM;
      RETURN FALSE;
  END calcularst;

  --possui verificação do simplenacional, retorna percentual de base deb/cred de rca, retorna altera ptabela
  FUNCTION validarpoliticasdesconto -- 25 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_param1                   IN number,
   p_param2                   IN number) RETURN BOOLEAN IS

    vbresult         BOOLEAN;
    vsprioritaria    VARCHAR2(1);
    vsquestionausoprioritaria VARCHAR2(1);

  BEGIN

    vbresult := validarpoliticasdesconto(--27 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         p_param,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         p_alteraptabela,
                                         p_pbaserca,
                                         vsprioritaria, --p_prioritaria,
                                         vsquestionausoprioritaria, --p_questionausoprioritaria,
                                         p_naousarautdebcredpoldesc,
                                         p_param1,
                                         p_param2
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  FUNCTION validardescontoquantidade -- 21 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_codcli              IN NUMBER default 0,
   p_codusur             IN NUMBER default 0,
   p_dtfim               OUT DATE,
   p_mensagem            OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER,
   p_basedebcredrca      OUT VARCHAR2,
   p_percbaserca         OUT NUMBER,
   p_codfilial           in varchar2 default ' ') RETURN BOOLEAN IS

    vbresult         BOOLEAN;
    vsprioritaria    VARCHAR2(1);
    vsquestionaprioritaria VARCHAR2(1);

  BEGIN
    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_numdias,
                                          p_tipodesconto,
                                          p_codprodprinc,
                                          p_codcli,
                                          p_codusur,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc,
                                          p_creditasobreptabela,
                                          p_perdescflex,
                                          p_basedebcredrca,
                                          p_percbaserca,
                                          vsprioritaria,
                                          vsquestionaprioritaria,
                                          p_codfilial
                                         );

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;
  END validardescontoquantidade;


  --possui verificação do simplenacional, retorna percentual de base deb/cred de rca, retorna altera ptabela,politica prioritaria
  FUNCTION validarpoliticasdesconto -- 27 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    in NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_param1                   IN number,
   p_param2                   IN number) RETURN BOOLEAN IS

    vbresult          BOOLEAN;
    vncodpolbaserca   NUMBER;
  BEGIN

    vbresult := validarpoliticasdesconto(--27 Parâmetros
                                         p_codprod,
                                         p_data,
                                         p_codfilial,
                                         p_numregiao,
                                         p_codcli,
                                         p_codusur,
                                         p_origempedido,
                                         p_codprodprinc,
                                         p_numcasasdecvenda,
                                         p_codplpag,
                                         p_tratarrestricaoacrescimo,
                                         p_classevenda,
                                         p_aplicadesconto,
                                         0, --p_numdias,
                                         p_dtfim,
                                         p_mensagem,
                                         p_perdesc,
                                         p_basecreddebrca,
                                         p_creditasobrepolitica,
                                         p_perdescrestricao,
                                         p_alteraptabela,
                                         p_pbaserca,
                                         p_prioritaria,
                                         p_questionausoprioritaria,
                                         p_naousarautdebcredpoldesc,
                                         p_param1,
                                         p_param2,
                                         vncodpolbaserca --p_codpolbaserca
                                        );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto;

  --Tem retorno do percetual de deb/cred de rca e prioritaria
  FUNCTION validardescontoquantidade -- 23 parametros
  (p_tipoteste           IN NUMBER,
   p_codprod             IN NUMBER,
   p_qtde                IN NUMBER,
   p_numregiao           IN NUMBER,
   p_ptabela             IN NUMBER,
   p_pvenda1             IN NUMBER,
   p_codpraca            IN NUMBER,
   p_numcasasdecvenda    IN NUMBER,
   p_numdias             IN NUMBER,
   p_tipodesconto        IN VARCHAR2,
   p_codprodprinc        IN NUMBER,
   p_codcli              IN NUMBER,
   p_codusur             IN NUMBER,
   p_dtfim               OUT DATE,
   p_mensagem            IN OUT VARCHAR2,
   p_ptabeladesc         OUT NUMBER,
   p_creditasobreptabela OUT VARCHAR2,
   p_perdescflex         OUT NUMBER,
   p_basedebcredrca      OUT VARCHAR2,
   p_percbaserca         OUT NUMBER,
   p_prioritaria          out varchar2,
   p_questionaprioritaria out varchar2,
   p_codfilial            in  varchar2 default ' ') RETURN BOOLEAN IS

    vbresult         BOOLEAN;
    vncodpolpbaserca NUMBER;
    vncoddesconto    NUMBER;

  BEGIN
    vbresult := validardescontoquantidade(p_tipoteste,
                                          p_codprod,
                                          p_qtde,
                                          p_numregiao,
                                          p_ptabela,
                                          p_pvenda1,
                                          p_codpraca,
                                          p_numcasasdecvenda,
                                          p_numdias,
                                          p_tipodesconto,
                                          p_codprodprinc,
                                          p_codcli,
                                          p_codusur,
                                          p_dtfim,
                                          p_mensagem,
                                          p_ptabeladesc,
                                          p_creditasobreptabela,
                                          p_perdescflex,
                                          p_basedebcredrca,
                                          p_percbaserca,
                                          p_prioritaria,
                                          p_questionaprioritaria,
                                          p_codfilial,
                                          vncodpolpbaserca, --p_codpolpbaserca,
                                          vncoddesconto, --p_coddesconto,
                                          'N' --p_apenasvalida
                                         );

    RETURN vbresult;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;
  END validardescontoquantidade;

  FUNCTION validarPCPLPAGRESTRICAO
  (p_codplpag      IN NUMBER,
   p_codprod       IN NUMBER,
   p_codcli        IN NUMBER,
   p_codativ       IN NUMBER,
   p_codfornec     IN NUMBER,
   p_coddepto      IN NUMBER,
   p_origemped     IN varchar2,
   p_codsec        IN NUMBER,
   p_codfilial     IN VARCHAR2,
   p_numregiao     IN NUMBER,
   p_condvenda     IN number,
   p_mensagem      OUT VARCHAR2,
   p_codcategoria     IN number default 0,
   p_codsubcategoria  IN number default 0

 ) RETURN BOOLEAN IS

    vbresult       BOOLEAN;
    vicont         number;
    vnorigemped    number;
    vsmensagem     varchar2(400);
    vicontador     number;
    vrestrito      varchar2(1);

  BEGIN
    vbresult       := FALSE;
    vsmensagem     := null;

    select decode(p_origemped,'R',3,'F',4)
    into vnorigemped
    from dual;

    SELECT PCPLPAG.TIPOPRAZO INTO VRESTRITO
      FROM PCPLPAG
     WHERE PCPLPAG.CODPLPAG = p_codplpag;

    SELECT COUNT(*)
      INTO vicont
      FROM pcplpagrestricao p
     WHERE p.codplpag = p_codplpag;



   /************************************************************************************
     Responsável: Rafael Soares
     Data:        08/03/2016
     Solicitação: 630.026348.2016
     Motivo: Bloco abaixo foi comentado pois a validação estava errada, caso o plano de pagamento seja
             restrito, mas não exista nenhum registro na tabela pcplpagrestricao, o pedido não pode ser
             rejeitado.
     ************************************************************************************************/
    /*IF NVL(VRESTRITO,'N') = 'G' AND vicont = 0 THEN
      vbresult   := TRUE;
      if vsmensagem is null then
         vsmensagem := 'Restricao de venda neste plano de pagamento para ramo atividade';
      else
         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para ramo atividade';
      end if;
    ELSIF vicont = 0 THEN*/
    IF vicont = 0 THEN
      vbresult := FALSE;
    ELSIF (NVL(VRESTRITO,'N') = 'G') THEN

      for reg in (select distinct p.tiporestricao
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag) loop

           --restricao por ramo de atividade
           if reg.tiporestricao = 'RA' and p_codativ is not null then

                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'RA'
                  and   p.codrestricao = p_codativ;

                  if vicontador = 0 then
                     vbresult   := TRUE;

                      if vsmensagem is null then
                         vsmensagem := 'Restricao de venda neste plano de pagamento para ramo atividade';
                      else
                         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para ramo atividade';
                      end if;
                  end if;

           end if;

           --restricao por forncedor
           if reg.tiporestricao = 'FO' and p_codfornec is not null then

                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'FO'
                  and   p.codrestricao = p_codfornec;

                  if vicontador = 0 then


                    vbresult   := TRUE;

                    if vsmensagem is null then
                       vsmensagem := 'Restricao de venda neste plano de pagamento para fornecedor';
                    else
                       vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para fornecedor';
                    end if;
                 end if;

           end if;

           --restricao por departamento
           if reg.tiporestricao = 'DP' and p_coddepto is not null then

                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'DP'
                  and   p.codrestricao = p_coddepto;

                  if vicontador = 0 then


                      vbresult   := TRUE;

                      if vsmensagem is null then
                         vsmensagem := 'Restricao de venda neste plano de pagamento para departamento';
                      else
                         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para departamento';
                      end if;
                  end if;

           end if;


           --restricao por origem pedido
           if reg.tiporestricao = 'OP' and p_origemped is not null then


                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'OP'
                  and   p.codrestricao = vnorigemped;

                  if vicontador = 0 then


                      vbresult   := TRUE;

                      if vsmensagem is null then
                         vsmensagem := 'Restricao de venda neste plano de pagamento para origem do pedido';
                      else
                         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para origem do pedido';
                      end if;
                  end if;

           end if;


           --restricao por seção
           if reg.tiporestricao = 'SE' and p_codsec is not null then


                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'SE'
                  and   p.codrestricao = p_codsec;

                  if vicontador = 0 then

                      vbresult   := TRUE;

                      if vsmensagem is null then
                         vsmensagem := 'Restricao de venda neste plano de pagamento para seção ';
                      else
                         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para seção';
                      end if;
                  end if;

           end if;


           --restricao por categoria
           if reg.tiporestricao = 'CA' and p_codcategoria is not null then

                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'CA'
                  and   p.codrestricao = p_codcategoria;

                  if vicontador = 0 then
                     vbresult   := TRUE;

                      if vsmensagem is null then
                         vsmensagem := 'Restricao de venda neste plano de pagamento para categoria';
                      else
                         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para categoria';
                      end if;
                  end if;

           end if;

           --restricao por subcategoria
           if reg.tiporestricao = 'SB' and p_codsubcategoria is not null then

                  select count(*)
                  into vicontador
                  FROM pcplpagrestricao p
                  WHERE p.codplpag = p_codplpag
                  and   p.tiporestricao = 'SB'
                  and   p.codrestricao = p_codsubcategoria;

                  if vicontador = 0 then
                     vbresult   := TRUE;

                      if vsmensagem is null then
                         vsmensagem := 'Restricao de venda neste plano de pagamento para sub categoria';
                      else
                         vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para sub categoria';
                      end if;
                  end if;

           end if;

           /* Restrição por cliente
            *
            * Verifica se o plano de contas pode ser utilizado pelo cliente
            * informado. HIS.03403.2017
            *
            */
           IF ( (REG.TIPORESTRICAO = 'CL') AND (p_codcli IS NOT NULL) ) THEN

             -- verifica se existe restrição de cliente
             SELECT COUNT(*)
               INTO vicontador
               FROM pcplpagrestricao p
              WHERE p.codplpag = p_codplpag
                AND p.tiporestricao = 'CL';

             if vicontador > 0 THEN
               -- verifica se existe restrição para o cliente
               SELECT COUNT(*)
                 INTO vicontador
                 FROM pcplpagrestricao p
                WHERE p.codplpag = p_codplpag
                  AND p.CODRESTRICAO = p_codcli
                  AND p.tiporestricao = 'CL';

               IF (vicontador = 0) THEN
                 vbresult   := TRUE;

                 if vsmensagem is null then
                   vsmensagem := 'Restricao de venda neste plano de pagamento para cliente';
                 else
                   vsmensagem := vsmensagem||CHR(13)||'Restricao de venda neste plano de pagamento para cliente';
                 end if;
               end if;
             END IF;

           END IF;

      end loop;

    END IF;


    p_mensagem := vsmensagem;

    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Restricao de Venda por Plano de Pagamento: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN TRUE;
  END validarPCPLPAGRESTRICAO;

FUNCTION validarpoliticasdesconto_med -- 28 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_perdescfin               OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_usadescfinseparadodesccom IN varchar2,
   p_param2                   IN number) RETURN BOOLEAN IS

    vbresult           BOOLEAN;
    vncodpolbaserca    NUMBER;

  BEGIN

    vbresult := validarpoliticasdesconto_med(p_codprod,
                                             p_data,
                                             p_codfilial,
                                             p_numregiao,
                                             p_codcli,
                                             p_codusur,
                                             p_origempedido,
                                             p_codprodprinc,
                                             p_numcasasdecvenda,
                                             p_codplpag,
                                             p_tratarrestricaoacrescimo,
                                             p_classevenda,
                                             p_aplicadesconto,
                                             0, --p_numdias,
                                             p_dtfim,
                                             p_mensagem,
                                             p_perdesc,
                                             p_perdescfin,
                                             p_basecreddebrca,
                                             p_creditasobrepolitica,
                                             p_perdescrestricao,
                                             p_alteraptabela,
                                             p_pbaserca,
                                             p_prioritaria,
                                             p_questionausoprioritaria,
                                             p_naousarautdebcredpoldesc,
                                             p_usadescfinseparadodesccom,
                                             p_param2,
                                             vncodpolbaserca
                                            );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto_med;

  procedure Definir_Comissao_por_TERCEIRO(p_codprod                in pcprodut.codprod%type,
                                        p_codcli                 in pcclient.codcli%type,
                                        p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                        p_percom                 out number,
                                        p_codcomiss              out number) is

    vnpercom number;

  begin

    begin
      select max(t.percom)
        into vnpercom
        from pccomissaoterceiros t
       where t.dtinicio <= trunc(sysdate)
         and t.dtfim >= trunc(sysdate)
         and t.tipo = 'CP'
         and t.tipoterceiro = 'R'
         and t.codcli = p_codcli
         and t.codprod = p_codprod;
    exception
      when others then
        vnpercom := null;
    end;

    if vnPERCOM is not null then


      begin
          select t.codigo
            into p_codcomiss
            from pccomissaoterceiros t
           where t.dtinicio <= trunc(sysdate)
             and t.dtfim >= trunc(sysdate)
             and t.tipo = 'CP'
             and t.tipoterceiro = 'R'
             and t.codcli = p_codcli
             and t.codprod = p_codprod
             and t.percom = vnpercom
             and rownum = 1;
        exception
          when others then
            p_codcomiss := null;
        end;

      if vnPERCOM = 0 then

        if p_ConsiderarComissaoZero = 'S' then
          p_percom := vnpercom;
        end if;

      else
        p_PERCOM := vnPERCOM;
      end if;
    end if;

  end;

  procedure Definir_Comissao_por_TERCEIRO(p_codprod                in pcprodut.codprod%type,
                                          p_codcli                 in pcclient.codcli%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number) is

    vnpercom NUMBER;
    vncodcomiss NUMBER;

  begin

    Definir_Comissao_por_TERCEIRO(p_codprod,
                                  p_codcli,
                                  p_considerarcomissaozero,
                                  vnpercom,
                                  vncodcomiss);
    p_percom := vnpercom;

  exception
    when others then
      p_percom := 0;
  end;

  procedure ValidarPCComissaoCliente(p_codcli                 in pcclient.codcli%type,
                                     p_perdesc                in pcpedi.perdesc%type,
                                     p_codfornec              in pcprodut.codfornec%type,
                                     p_codprod                in pcpedi.codprod%type,
                                     p_codfilial              in pcpedc.codfilial%type,
                                     p_tipovend               in pcusuari.tipovend%type,
                                     p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                     p_data                   in date,
                                     p_percom                 out number,
                                     p_letracomiss            out varchar2,
                                     p_codcomiss              out number,
                                     p_mensagem               out varchar2) IS

    vnPercom   number;
    vnCodFaixa number;
    viCount    number;
    viCont_Reg number;

  begin

    begin
      SELECT count(*) INTO viCont_Reg FROM PCCOMISSAOCLIENTE;
    exception
      when others then
        viCont_Reg := 0;
    end;

    if viCont_Reg > 0 then

      -- Por Cliente
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOCLIENTE
                 WHERE CODCLI = p_codcli
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'C') = 'C'
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Por Cliente / Grupo de Produto
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOCLIENTE
                 WHERE CODCLI = p_codcli
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'C') = 'CG'
                   AND PCCOMISSAOCLIENTE.CODGRUPO IN
                       (SELECT GRUPO.CODGRUPO
                          FROM PCGRUPOSCAMPANHAC GRUPO,
                               PCGRUPOSCAMPANHAI ITENS
                         WHERE GRUPO.CODGRUPO = ITENS.CODGRUPO
                           AND GRUPO.DTEXCLUSAO IS NULL
                           AND GRUPO.TIPO = 'GP'
                           AND ITENS.DTEXCLUSAO IS NULL
                           AND ITENS.CODITEM = p_codprod)
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Por Fornecedor
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOCLIENTE
                 WHERE CODCLI = p_codcli
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'C') = 'CF'
                   AND CODFORNEC = p_codfornec
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Comissão por Fornecedor/Produto
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOCLIENTE
                 WHERE CODCLI = p_codcli
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'C') = 'CFP'
                   AND CODPROD = p_codprod
                   AND CODFORNEC = p_codfornec
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

    end if;
  end;

 PROCEDURE ValidarPCComissaoCliente(p_codcli                 in pcclient.codcli%type,
                                    p_perdesc                in pcpedi.perdesc%type,
                                    p_codfornec              in pcprodut.codfornec%type,
                                    p_codprod                in pcpedi.codprod%type,
                                    p_codfilial              in pcpedc.codfilial%type,
                                    p_tipovend               in pcusuari.tipovend%type,
                                    p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                    p_data                   in date,
                                    p_percom                 out number,
                                    p_letracomiss            out varchar2) IS

    vnPercom NUMBER;
    vsLetraComiss VARCHAR2(1);

  BEGIN

    ValidarPCComissaoCliente(p_codcli,
                             p_perdesc,
                             p_codfornec,
                             p_codprod,
                             p_codfilial,
                             p_tipovend,
                             p_considerarcomissaozero,
                             p_data,
                             vnPercom,
                             vsLetracomiss);

    p_percom := vnPercom;
    p_letracomiss := vsLetraComiss;


  EXCEPTION
    WHEN OTHERS THEN
      p_percom := NULL;

  END;

  procedure ValidarPCComissaoAtividade(p_codatv1                in pcclient.codatv1%type,
                                       p_perdesc                in pcpedi.perdesc%type,
                                       p_codfornec              in pcprodut.codfornec%type,
                                       p_codprod                in pcpedi.codprod%type,
                                       p_codfilial              in pcpedc.codfilial%type,
                                       p_tipovend               in pcusuari.tipovend%type,
                                       p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                       p_data                   in date,
                                       p_percom                 out number,
                                       p_letracomiss            out varchar2,
                                       p_codcomiss              out number,
                                       p_mensagem               out varchar2) IS

  vnPercom   number;
  vnCodFaixa number;
  viCount    number;
  viCont_Reg number;

  begin

    begin
      SELECT count(*) INTO viCont_Reg FROM PCCOMISSAOATIVI;
    exception
      when others then
        viCont_Reg := 0;
    end;

    if viCont_Reg > 0 then

      -- Por Atividade
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOATIVI
                 WHERE CODATIV = p_codatv1
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'A') = 'A'
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Por Grupo / Produto
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOATIVI
                 WHERE CODATIV = p_codatv1
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'A') = 'AG'
                   AND PCCOMISSAOATIVI.CODGRUPO IN
                       (SELECT GRUPO.CODGRUPO
                          FROM PCGRUPOSCAMPANHAC GRUPO, PCGRUPOSCAMPANHAI ITENS
                         WHERE GRUPO.CODGRUPO = ITENS.CODGRUPO
                           AND GRUPO.DTEXCLUSAO IS NULL
                           AND GRUPO.TIPO = 'GP'
                           AND ITENS.DTEXCLUSAO IS NULL
                           AND ITENS.CODITEM = p_codprod)
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Por Fornecedor
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOATIVI
                 WHERE CODATIV = p_codatv1
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'A') = 'AF'
                   AND CODFORNEC = p_codfornec
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Comissão por Fornecedor/Produto
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOATIVI
                 WHERE CODATIV = p_codatv1
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'A') = 'AFP'
                   AND CODPROD = p_codprod
                   AND CODFORNEC = p_codfornec
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

    end if;
  end;

  PROCEDURE ValidarPCComissaoAtividade(p_codatv1                in pcclient.codcli%type,
                                       p_perdesc                in pcpedi.perdesc%type,
                                       p_codfornec              in pcprodut.codfornec%type,
                                       p_codprod                in pcpedi.codprod%type,
                                       p_codfilial              in pcpedc.codfilial%type,
                                       p_tipovend               in pcusuari.tipovend%type,
                                       p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                       p_data                   in date,
                                       p_percom                 out number,
                                       p_letracomiss            out varchar2) IS

    vnPercom      NUMBER;
    vsLetraComiss VARCHAR2(1);

  BEGIN

    ValidarPCComissaoAtividade(p_codatv1,
                               p_perdesc,
                               p_codfornec,
                               p_codprod,
                               p_codfilial,
                               p_tipovend,
                               p_considerarcomissaozero,
                               p_data,
                               vnPercom,
                               vsLetracomiss);

    p_percom      := vnPercom;
    p_letracomiss := vsLetraComiss;

  EXCEPTION
    WHEN OTHERS THEN
      p_percom := NULL;

  END;

  procedure ValidarPCComissaoFornecedor(p_codfornec              in pcprodut.codfornec%type,
                                        p_perdesc                in pcpedi.perdesc%type,
                                        p_codprod                in pcpedi.codprod%type,
                                        p_codfilial              in pcpedc.codfilial%type,
                                        p_tipovend               in pcusuari.tipovend%type,
                                        p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                        p_data                   in date,
                                        p_percom                 out number,
                                        p_letracomiss            out varchar2,
                                        p_codcomiss              out number,
                                        p_mensagem               out varchar2) IS

  vnPercom   number;
  vnCodFaixa number;
  viCount    number;
  viCont_Reg number;

  begin

    begin
      SELECT count(*) INTO viCont_Reg FROM PCCOMISSAOFORNEC;
    exception
      when others then
        viCont_Reg := 0;
    end;

    if viCont_Reg > 0 then

      -- Por Fornecedor
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOFORNEC
                 WHERE codfornec = p_codfornec
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'F') = 'F'
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Por Grupo / Produto
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOFORNEC
                 WHERE CODFORNEC = p_codfornec
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'F') = 'FG'
                   AND PCCOMISSAOFORNEC.CODGRUPO IN
                       (SELECT GRUPO.CODGRUPO
                          FROM PCGRUPOSCAMPANHAC GRUPO, PCGRUPOSCAMPANHAI ITENS
                         WHERE GRUPO.CODGRUPO = ITENS.CODGRUPO
                           AND GRUPO.DTEXCLUSAO IS NULL
                           AND GRUPO.TIPO = 'GP'
                           AND ITENS.DTEXCLUSAO IS NULL
                           AND ITENS.CODITEM = p_codprod)
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      -- Comissão por Fornecedor/Produto
      begin
        SELECT CODFAIXA, PERCOM
          INTO vnCodFaixa, vnPercom
          FROM (SELECT CODFAIXA, PERCOM
                  FROM PCCOMISSAOFORNEC
                 WHERE CODFORNEC = p_codfornec
                   AND p_perdesc BETWEEN PERCDESCINI AND PERCDESCFIM
                   AND NVL(TIPO, 'F') = 'FP'
                   AND CODPROD = p_codprod
                 ORDER BY PERCOM DESC)
         WHERE ROWNUM = 1;
      exception
        when others then
          vnPercom   := null;
          vnCodFaixa := null;
      end;
      if vnPercom is not null then

        if vnPercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom    := vnPercom;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_percom    := vnPercom;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

    end if;
  end;

  PROCEDURE ValidarPCComissaoFornecedor(p_codfornec              in pcprodut.codfornec%type,
                                        p_perdesc                in pcpedi.perdesc%type,
                                        p_codprod                in pcpedi.codprod%type,
                                        p_codfilial              in pcpedc.codfilial%type,
                                        p_tipovend               in pcusuari.tipovend%type,
                                        p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                        p_data                   in date,
                                        p_percom                 out number,
                                        p_letracomiss            out varchar2) IS

    vnPercom      NUMBER;
    vsLetraComiss VARCHAR2(1);

  BEGIN

    ValidarPCComissaoFornecedor(p_codfornec,
                                p_perdesc,
                                p_codprod,
                                p_codfilial,
                                p_tipovend,
                                p_considerarcomissaozero,
                                p_data,
                                vnPercom,
                                vsLetracomiss);

    p_percom      := vnPercom;
    p_letracomiss := vsLetraComiss;

  EXCEPTION
    WHEN OTHERS THEN
      p_percom := NULL;

  END;

  procedure Definir_Comissao_por_LUCRO(--8 Parâmetros
                                       p_perluc                 in number,
                                       p_perdesc                in number,
                                       p_tipovend               pcusuari.tipovend%type,
                                       p_tipocomissao           pcprodut.tipocomissao%type,
                                       p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
                                       p_percom                 out number,
                                       p_letracomiss            out pcpedi.letracomiss%type,
                                       p_codfaixa               out number) is

    vnpercom      number;
    vsletracomiss pcpedi.letracomiss%type;

  begin
    p_LetraComiss := '';

    if p_TIPOCOMISSAO = 'L' then

      begin

        SELECT DECODE(p_TIPOVEND,
                      'I',
                      PCTABCOMISS.PERCOMINT,
                      'E',
                      PCTABCOMISS.PERCOMEXT,
                      'R',
                      PCTABCOMISS.PERCOMREP,
                      0) PERCOM,
               LETRACOMISS
          into vnpercom, vsletracomiss
          FROM PCTABCOMISS
         WHERE p_PERLUC BETWEEN PCTABCOMISS.PERCDESCINI AND
               PCTABCOMISS.PERCDESCFIM
           AND TIPOAPLICCOMISS = 'L';
      exception
        when others then
          vnpercom      := null;
          vsletracomiss := null;
      end;

      if vnpercom is not null then
        p_LetraComiss := vsLETRACOMISS;
      else
        begin
          SELECT DECODE(P_TIPOVEND,
                        'I',
                        PCTABCOMISS.PERCOMINT,
                        'E',
                        PCTABCOMISS.PERCOMEXT,
                        'R',
                        PCTABCOMISS.PERCOMREP,
                        0) PERCOM
            into vnpercom
            FROM PCTABCOMISS
           WHERE P_PERDESC BETWEEN PCTABCOMISS.PERCDESCINI AND
                 PCTABCOMISS.PERCDESCFIM
             AND TIPOAPLICCOMISS <> 'L';
        exception
          when others then
            vnpercom := null;
        end;
      end if;

    else
      begin
        SELECT DECODE(P_TIPOVEND,
                      'I',
                      PCTABCOMISS.PERCOMINT,
                      'E',
                      PCTABCOMISS.PERCOMEXT,
                      'R',
                      PCTABCOMISS.PERCOMREP,
                      0) PERCOM
          into vnpercom
          FROM PCTABCOMISS
         WHERE P_PERDESC BETWEEN PCTABCOMISS.PERCDESCINI AND
               PCTABCOMISS.PERCDESCFIM
           AND TIPOAPLICCOMISS <> 'L';
      exception
        when others then
          vnpercom := null;
      end;
    end if;

    if vnPERCOM is not null then

      if vnPERCOM = 0 then

        if p_ConsiderarComissaoZero = 'S' then
          p_percom := vnpercom;
        end if;

      else
        p_PERCOM := vnPERCOM;
      end if;
    end if;

  end;

  --10 parametros
  procedure Definir_Comis_PCCOMISSAOUSUR
    (p_perdesc                in number,
     p_codusur                in number,
     p_ConsiderarComissaoZero pcfilial.considerarcomissaozero%type,
     p_codepto                in pcprodut.codepto%type,
     p_codsec                 in pcprodut.codsec%type,
     p_codprod                in pcprodut.codprod%type,
     p_percom                 out number,
     p_letracomiss            out varchar2,
     p_codcomiss              out number,
     p_mensagem               out varchar2) IS

    vicont   number;
    vnpercom number;
    vncodfaixa number;

  begin

    --Por RCA
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND nvl(tipo, 'R') = 'R'
       AND ROWNUM = 1;

   IF vicont <> 0 THEN

     if vicont = 1 then

            SELECT percom
              INTO vnpercom
              FROM pccomissaousur
             WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
               AND codusur = p_codusur
               AND nvl(tipo, 'R') = 'R'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

             SELECT codfaixa
              INTO vncodfaixa
              FROM pccomissaousur
             WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
               AND codusur = p_codusur
               AND nvl(tipo, 'R') = 'R'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

           if vnpercom = 0 then

            if p_ConsiderarComissaoZero = 'S' then
                  p_PERCOM := vnPERCOM;
                  p_codcomiss := vncodfaixa;
            end if;
           else

             p_percom := vnpercom;
             p_codcomiss := vncodfaixa;

           end if;
      else

       p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 553 por RCA(R) para o percentual : '||p_perdesc;

      end if;


      p_letracomiss := NULL;

    END IF;

    --Por RCA/Departamento
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND codepto = p_codepto
       AND nvl(tipo, 'R') = 'RD'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

   IF vicont <> 0 THEN

     if vicont = 1 then

      SELECT percom
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codepto = p_codepto
         AND nvl(tipo, 'R') = 'RD'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        INTO vncodfaixa
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codepto = p_codepto
         AND nvl(tipo, 'R') = 'RD'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;


             if vnpercom = 0 then

              if p_ConsiderarComissaoZero = 'S' then
             p_percom := vnpercom;
             p_codcomiss := vncodfaixa;

              end if;
             else

             p_percom := vnpercom;
             p_codcomiss := vncodfaixa;


             end if;


      else

         p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 553 por RCA/Departamento(RD) para o percentual : '||p_perdesc;
      end if;



      p_letracomiss := NULL;
    END IF;

    --Por RCA/Seção
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND codsec = p_codsec
       AND nvl(tipo, 'R') = 'RS'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

   IF vicont <> 0 THEN

    if vicont = 1 then

      SELECT percom
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codsec = p_codsec
         AND nvl(tipo, 'R') = 'RS'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        INTO vncodfaixa
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codsec = p_codsec
         AND nvl(tipo, 'R') = 'RS'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

     if vnpercom = 0 then

      if p_ConsiderarComissaoZero = 'S' then
            p_PERCOM := vnPERCOM;
            p_codcomiss := vncodfaixa;
      end if;
     else

       p_percom := vnpercom;
       p_codcomiss := vncodfaixa;

     end if;

    else
        p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 553 por RCA/Secao(RS) para o percentual : '||p_perdesc;

    end if;

      p_letracomiss := NULL;
    END IF;

    --Por RCA/Produto
    SELECT COUNT(*)
      INTO vicont
      FROM pccomissaousur
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND codusur = p_codusur
       AND codprod = p_codprod
       AND nvl(tipo, 'R') = 'RP'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

   IF vicont <> 0 THEN

     if vicont = 1 then

      SELECT percom
        INTO vnpercom
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codprod = p_codprod
         AND nvl(tipo, 'R') = 'RP'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        INTO vncodfaixa
        FROM pccomissaousur
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND codusur = p_codusur
         AND codprod = p_codprod
         AND nvl(tipo, 'R') = 'RP'
               AND ROWNUM = 1
          ORDER BY PERCOM DESC;


           if vnpercom = 0 then

            if p_ConsiderarComissaoZero = 'S' then
                  p_PERCOM := vnPERCOM;
                  p_codcomiss := vncodfaixa;
            end if;
           else

             p_percom := vnpercom;
             p_codcomiss := vncodfaixa;

           end if;

       else

        p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 553 por RCA/Produto(RP) para o percentual : '||p_perdesc;

       end if;

      p_letracomiss := NULL;

    END IF;

  end;

  procedure ValidarPCCOMISSAOPLPAG(--12 Parâmetros
                                   p_tipovend               in pcusuari.tipovend%type,
                                   p_codplpag               in pcplpag.codplpag%type,
                                   p_perdesc                in number,
                                   p_codprod                in pcprodut.codprod%type,
                                   p_codepto                in pcprodut.codepto%type,
                                   p_codsec                 in pcprodut.codsec%type,
                                   p_classeproduto          in pcprodut.classe%type,
                                   p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                   p_percom                 out number,
                                   p_letracomiss            out varchar2,
                                   p_codcomiss              out number,
                                   p_mensagem               out varchar2) IS

    vnpercom number;
    vicont   number;
    vncodfaixa number;
  begin

    -- Por Plano de Pagamento
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOPLPAG
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND CODPLPAG = P_CODPLPAG
       AND NVL(TIPO, 'P') = 'P'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

    if vicont <> 0 then

      if vicont = 1 then

        SELECT DECODE(p_TIPOVEND,
                      'I',
                      PERCOMINT,
                      'E',
                      PERCOMEXT,
                      'R',
                      PERCOMREP,
                      0) PERCOM
          INTO vnpercom
          FROM PCCOMISSAOPLPAG
         WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
           AND CODPLPAG = P_CODPLPAG
           AND NVL(TIPO, 'P') = 'P'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

        SELECT codfaixa
          INTO vncodfaixa
          FROM PCCOMISSAOPLPAG
         WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
           AND CODPLPAG = P_CODPLPAG
           AND NVL(TIPO, 'P') = 'P'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;


        if vnpercom is not null then

          if vnPERCOM = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              p_PERCOM := vnpercom;
              p_codcomiss := vncodfaixa;
            end if;
          else
            p_PERCOM := vnPERCOM;
            p_codcomiss := vncodfaixa;
          end if;

          p_LetraComiss := '';
        end if;
      else

        p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 583 por Plano(P) para o percentual : '||p_perdesc;

      end if;

    end if;

    -- Por Plano de Pagamento / Depto
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOPLPAG
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND CODPLPAG = P_CODPLPAG
       AND cODEPTO = p_CODEPTO
       AND NVL(TIPO, 'P') = 'PD'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(p_TIPOVEND,
                    'I',
                    PERCOMINT,
                    'E',
                    PERCOMEXT,
                    'R',
                    PERCOMREP,
                    0) PERCOM
        INTO vnpercom
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         and CODEPTO = p_codepto
         AND NVL(TIPO, 'P') = 'PD'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

       SELECT codfaixa
        INTO vncodfaixa
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         and CODEPTO = p_codepto
         AND NVL(TIPO, 'P') = 'PD'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

      if vnpercom is not null then

        if vnPERCOM = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_PERCOM := vnpercom;
            p_codcomiss := vncodfaixa;
          end if;
        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;
    else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 583 por Plano/Depto(PD) para o percentual : '||p_perdesc;

    end if;


    end if;

    -- Por Plano de Pagamento / Secao
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOPLPAG
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND CODPLPAG = P_CODPLPAG
       AND CODSEC = P_CODSEC
       AND NVL(TIPO, 'P') = 'PS'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(p_TIPOVEND,
                    'I',
                    PERCOMINT,
                    'E',
                    PERCOMEXT,
                    'R',
                    PERCOMREP,
                    0) PERCOM
        INTO vnpercom
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CODSEC = p_CODSEC
         AND NVL(TIPO, 'P') = 'PS'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

      SELECT codfaixa
        INTO vncodfaixa
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CODSEC = p_CODSEC
         AND NVL(TIPO, 'P') = 'PS'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;


      if vnpercom is not null then

        if vnPERCOM = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_PERCOM := vnpercom;
            p_codcomiss := vncodfaixa;
          end if;
        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;


        p_LetraComiss := '';
      end if;

    else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 583 por Plano/Secao(PS) para o percentual : '||p_perdesc;

    end if;

    end if;

    -- Por Plano de Pagamento / Produto
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOPLPAG
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND CODPLPAG = P_CODPLPAG
       AND CODPROD = P_CODPROD
       AND NVL(TIPO, 'P') = 'PP'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

    if vicont <> 0 then

      if vicont = 1 then

      SELECT DECODE(p_TIPOVEND,
                    'I',
                    PERCOMINT,
                    'E',
                    PERCOMEXT,
                    'R',
                    PERCOMREP,
                    0) PERCOM
        INTO vnpercom
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CODPROD = P_CODPROD
         AND NVL(TIPO, 'P') = 'PP'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

      SELECT CODFAIXA
        INTO vncodfaixa
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CODPROD = P_CODPROD
         AND NVL(TIPO, 'P') = 'PP'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;


      if vnpercom is not null then

        if vnPERCOM = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_PERCOM := vnpercom;
            p_codcomiss := vncodfaixa;
          end if;
        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;
    else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 583 por Plano/Produto(PP) para o percentual : '||p_perdesc;

    end if;


    end if;

    -- Por Plano de Pagamento / Classe do Produto (Tarefa 54546)

    SELECT count(*)
      into vicont
      FROM PCCOMISSAOPLPAG
     WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
       AND CODPLPAG = P_CODPLPAG
       AND CLASSEPRODUTO = P_CLASSEPRODUTO
       AND NVL(TIPO, 'P') = 'PC'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(p_TIPOVEND,
                    'I',
                    PERCOMINT,
                    'E',
                    PERCOMEXT,
                    'R',
                    PERCOMREP,
                    0) PERCOM
        INTO vnpercom
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CLASSEPRODUTO = P_CLASSEPRODUTO
         AND NVL(TIPO, 'P') = 'PC'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;

      SELECT codfaixa
        INTO vncodfaixa
        FROM PCCOMISSAOPLPAG
       WHERE round(p_perdesc, 2) BETWEEN percdescini AND percdescfim
         AND CODPLPAG = P_CODPLPAG
         AND CLASSEPRODUTO = P_CLASSEPRODUTO
         AND NVL(TIPO, 'P') = 'PC'
               AND ROWNUM = 1
          ORDER BY PERCOMINT, PERCOMEXT, PERCOMREP DESC;



      if vnpercom is not null then

        if vnPERCOM = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_PERCOM := vnpercom;
            p_Codcomiss := vncodfaixa;
          end if;
        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

    else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 583 por Plano/Classe produto(PC) para o percentual : '||p_perdesc;

    end if;


    end if;

  end;

  PROCEDURE ValidarPCComissaoRegiao(--13 Parâmetros
                                    p_numregiao              in pcregiao.numregiao%type,
                                    p_codfilial              in pcfilial.codigo%type,
                                    p_perdesc                in number,
                                    p_data                   in date,
                                    p_codprod                in pcprodut.codprod%type,
                                    p_codsec                 in pcprodut.codsec%type,
                                    p_codepto                in pcprodut.codepto%type,
                                    p_tipovend               in pcusuari.tipovend%type,
                                    p_ConsiderarComissaoZero in pcfilial.considerarcomissaozero%type,
                                    p_percom                 out number,
                                    p_letracomiss            out varchar2,
                                    p_codcomiss              out number,
                                    p_mensagem               out varchar2) IS

    vnpercom number;
    vicont   number;
    vncodfaixa number;


  BEGIN

    -- Por Regiao
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOREGIAO
     WHERE NUMREGIAO = P_NUMREGIAO
       AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
       AND NVL(TIPO, 'R') = 'R'
       AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
       AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
            p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
        AND ROWNUM = 1
          ORDER BY PERCOM DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(NVL(TIPOVENDEDOR, 'N'),
                    'S',
                    DECODE(p_TIPOVEND,
                           'I',
                           NVL(PERCOMINT, 0),
                           'E',
                           NVL(PERCOMEXT, 0),
                           'R',
                           NVL(PERCOM, 0)),
                    PCCOMISSAOREGIAO.PERCOM) PERCOM
        into vnpercom
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = P_NUMREGIAO
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'R'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        into vncodfaixa
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = P_NUMREGIAO
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'R'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;


      if vnpercom is not null then

        if vnPERCOM = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_PERCOM := vnPERCOM;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := ' ';
      end if;

     else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina  363 por Regiao(R) para o percentual : '||p_perdesc;

     end if;

    end if;

    -- Por Regiao / Departamento
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOREGIAO
     WHERE NUMREGIAO = p_NUMREGIAO
       AND CODEPTO = p_CODEPTO
       AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
       AND NVL(TIPO, 'R') = 'RD'
       AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
       AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
            p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
       AND ROWNUM = 1
          ORDER BY PERCOM DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(NVL(TIPOVENDEDOR, 'N'),
                    'S',
                    DECODE(p_TIPOVEND,
                           'I',
                           NVL(PERCOMINT, 0),
                           'E',
                           NVL(PERCOMEXT, 0),
                           'R',
                           NVL(PERCOM, 0)),
                    PCCOMISSAOREGIAO.PERCOM) PERCOM
        into vnpercom
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = p_NUMREGIAO
         AND CODEPTO = p_CODEPTO
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'RD'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        into vncodfaixa
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = p_NUMREGIAO
         AND CODEPTO = p_CODEPTO
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'RD'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;


      if vnPERCOM is not null then

        if vnpercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom := vnPERCOM;
            p_codcomiss := vncodfaixa;
          end if;

        else
            p_PERCOM := vnPERCOM;
            p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := ' ';
      end if;

     else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 363 por Regiao/Depto(RD) para o percentual : '||p_perdesc;

     end if;


    end if;

    -- Por Regiao / Seção
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOREGIAO
     WHERE NUMREGIAO = p_NUMREGIAO
       AND CODSEC = p_CODSEC
       AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
       AND NVL(TIPO, 'R') = 'RS'
       AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
       AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
            p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
       AND ROWNUM = 1
          ORDER BY PERCOM DESC;

    if vicont <> 0 then

      if vicont = 1 then

      SELECT DECODE(NVL(TIPOVENDEDOR, 'N'),
                    'S',
                    DECODE(p_TIPOVEND,
                           'I',
                           NVL(PERCOMINT, 0),
                           'E',
                           NVL(PERCOMEXT, 0),
                           'R',
                           NVL(PERCOM, 0)),
                    PCCOMISSAOREGIAO.PERCOM) PERCOM
        into vnpercom
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = p_NUMREGIAO
         AND CODSEC = p_CODSEC
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'RS'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;


      SELECT codfaixa
        into vncodfaixa
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = p_NUMREGIAO
         AND CODSEC = p_CODSEC
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'RS'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;


      if vnPERCOM is not null then

        if vnpercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom := vnPERCOM;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 363 por Regiao/Secao(RS) para o percentual : '||p_perdesc;

     end if;

    end if;

   /*
    -- Por Produto (Tarefa 62046)

   Solicitação: VEN-5979
   Responsável: Daniel Costa
   Alteração: Conforme alinhado com Silas Lopes, a comissão abaixo não utilizava a
               o filtro de região, mas a tabela é para comissão de região.
               316 e 3308 não tinha esse código

   Solicitação: VEN-6281
   Responsável: Daniel Costa
   Alteração: Alterado para voltar a comissão por região, mas olhando se a mesma
              está nula ou igual a informada. */

    SELECT count(*)
      into vicont
      FROM PCCOMISSAOREGIAO
     WHERE CODPROD = p_CODPROD
       AND ((NUMREGIAO IS NULL) OR (NUMREGIAO = p_NUMREGIAO))
       AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
       AND NVL(TIPO, 'R') = 'P'
       AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
       AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
            p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
       AND ROWNUM = 1
          ORDER BY PERCOM DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(NVL(TIPOVENDEDOR, 'N'),
                    'S',
                    DECODE(p_TIPOVEND,
                           'I',
                           NVL(PERCOMINT, 0),
                           'E',
                           NVL(PERCOMEXT, 0),
                           'R',
                           NVL(PERCOM, 0)),
                    PCCOMISSAOREGIAO.PERCOM) PERCOM
        into vnpercom
        FROM PCCOMISSAOREGIAO
       WHERE CODPROD = p_CODPROD
         AND ((NUMREGIAO IS NULL) OR (NUMREGIAO = p_NUMREGIAO))
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'P'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
          AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        into vncodfaixa
        FROM PCCOMISSAOREGIAO
       WHERE CODPROD = p_CODPROD
         AND ((NUMREGIAO IS NULL) OR (NUMREGIAO = p_NUMREGIAO))
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'P'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;



      if vnPERCOM is not null then

        if vnpercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom := vnPERCOM;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_PERCOM := vnPERCOM;
          p_Codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 363 por Produto(P) para o percentual : '||p_perdesc;

     end if;


    end if;

    -- Por Regiao / Produto
    SELECT count(*)
      into vicont
      FROM PCCOMISSAOREGIAO
     WHERE NUMREGIAO = p_NUMREGIAO
       AND CODPROD = p_CODPROD
       AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
       AND NVL(TIPO, 'R') = 'RP'
       AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
       AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
            p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
       AND ROWNUM = 1
          ORDER BY PERCOM DESC;

    if vicont <> 0 then

     if vicont = 1 then

      SELECT DECODE(NVL(TIPOVENDEDOR, 'N'),
                    'S',
                    DECODE(p_TIPOVEND,
                           'I',
                           NVL(PERCOMINT, 0),
                           'E',
                           NVL(PERCOMEXT, 0),
                           'R',
                           NVL(PERCOM, 0)),
                    PCCOMISSAOREGIAO.PERCOM) PERCOM
        into vnpercom
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = p_NUMREGIAO
         AND CODPROD = p_CODPROD
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'RP'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;

      SELECT codfaixa
        into vncodfaixa
        FROM PCCOMISSAOREGIAO
       WHERE NUMREGIAO = p_NUMREGIAO
         AND CODPROD = p_CODPROD
         AND p_PERDESC BETWEEN PERDESCINI AND PERDESCFIM
         AND NVL(TIPO, 'R') = 'RP'
         AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL, ' ') = p_CODFILIAL))
         AND ((CASE WHEN(DTINICIO IS NULL) AND (DTFIM IS NULL) THEN TRUNC(SYSDATE) ELSE
              p_DATA END) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
         AND ROWNUM = 1
          ORDER BY PERCOM DESC;


      if vnPERCOM is not null then

        if vnpercom = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            p_percom := vnPERCOM;
            p_codcomiss := vncodfaixa;
          end if;

        else
          p_PERCOM := vnPERCOM;
          p_codcomiss := vncodfaixa;
        end if;

        p_LetraComiss := '';
      end if;

      else

      p_mensagem := 'Existe mais de uma comissao cadastrada na rotina 363 por Regiao/Produto(RP) para o percentual : '||p_perdesc;

     end if;


    end if;

  end;

  -- 44 parâmetros, mas serve para a de 39 parametros
  FUNCTION Definir_Comissao_Item_Vendido(p_NumRegiao                 in pcregiao.numregiao%type,
                                         p_perluc                    in number,
                                         p_perdesc                   in number,
                                         p_UsaPcTabComiss            in boolean,
                                         p_UsaPcComissaoUsur         in boolean,
                                         p_UsaPCComissaoPlPag        in boolean,
                                         p_UsaPCComissaoRegiao       in boolean,
                                         p_UsaPCComissaoFilial       in boolean,
                                         p_usacomissaoporrca         in pcconsum.usacomissaoporrca%type,
                                         p_OrdemAvaliacaoComissaoRCA in pcconsum.ordemavaliacaocomissaorca%type,
                                         p_usacomissaoporcliente     in pcconsum.usacomissaoporcliente%type,
                                         p_USACOMISSAOPORLINHAPROD   in pcconsum.usacomissaoporlinhaprod%type,
                                         p_comissaorcatipovenda      in pcconsum.comissaorcatipovenda%type,
                                         p_tipovend                  in pcusuari.tipovend%type,
                                         p_percent                   in pcusuari.percent%type,
                                         p_percent2                  in pcusuari.percent2%type,
                                         p_codprod                   in pcprodut.codprod%type,
                                         p_pcomint1                  in pcprodut.pcomint1%type,
                                         P_PCOMEXT1                  in pcprodut.pcomext1%type,
                                         P_PCOMREP1                  in pcprodut.pcomrep1%type,
                                         p_codlinhaprod              in pcprodut.codlinhaprod%type,
                                         p_tipocomissao              in pcprodut.tipocomissao%type,
                                         p_codepto                   in pcprodut.codepto%type,
                                         p_codsec                    in pcprodut.codsec%type,
                                         p_classeproduto             in pcprodut.classe%type,
                                         p_tipovenda                 in pcplpag.tipovenda%type,
                                         p_codplpag                  in pcpedc.codplpag%type,
                                         p_data                      in pcpedc.data%type,
                                         p_codfilial                 in pcpedc.codfilial%type,
                                         p_codusur                   in pcpedc.codusur%type,
                                         p_considerarcomissaozero    in pcfilial.considerarcomissaozero%type,
                                         p_tipoavaliacaocomissao     in pcfilial.tipoavaliacaocomissao%type,
                                         p_percomcli                 in pcclient.percomcli%type,
                                         p_codcli                    in pcclient.codcli%type,
                                         p_coddesconto               in pcdesconto.coddesconto%type,
                                         p_codcomissao               out number,
                                         p_rotinacomissao            out varchar2,
                                         p_LetraComiss               out varchar2,
                                         p_mensagem                  out varchar2,
                                         p_codauxiliar               in pcembalagem.codauxiliar%type default null,
                                         p_pcomint1_emb              in pcembalagem.pcomint1%type default null,
                                         P_PCOMEXT1_emb              in pcembalagem.pcomext1%type default null,
                                         P_PCOMREP1_emb              in pcembalagem.pcomrep1%type default null,
                                         p_utilizavendaporembalagem  in pcconsum.utilizavendaporembalagem%type default 'N',
                                         p_tabela                 in number default 0,
                                         p_venda                  in number default 0,
                                         p_numcasasdecvenda       in number default 2
                                         )
    RETURN NUMBER IS

    vnpercom       number;
    vnPerCom_Maior number;
    vnPerCom_Menor number;
    vsletracomiss  pcpedi.letracomiss%type;
    vicont         number;
    vnpercom_aux   number;
    vncodcomiss         pcorigemcomis.codcomis%type;
    vnrotinacomissao_menor      pcorigemcomis.codrotinacomis%type;
    vncodcomissao_menor pcorigemcomis.codcomis%type;
    vnrotinacomissao_maior      pcorigemcomis.codrotinacomis%type;
    vncodcomissao_maior pcorigemcomis.codcomis%type;
    vncodfornec         pcprodut.codfornec%type;
    vncodatv1           pcclient.codatv1%type;

    vsmensagem              varchar2(1000);
    vsmensagem_comissaousur varchar2(200);
    vsmensagem_comissaoplpag varchar2(200);
    vsmensagem_comissaoregiao varchar2(200);
    vsmensagem_comissaocliente  varchar2(200);
    vsmensagem_comissaoatividade varchar2(200);
    vsmensagem_comissaofornecedor varchar2(200);


  begin

    vsmensagem               := null;
    vsmensagem_comissaousur  := null;
    vsmensagem_comissaoplpag := null;
    vsmensagem_comissaoregiao := null;
    vsmensagem_comissaocliente := null;
    vsmensagem_comissaoatividade := null;
    vsmensagem_comissaofornecedor := null;


    p_codcomissao       := null;
    p_rotinacomissao    := null;
    vncodcomiss         := null;
    vncodcomissao_maior := null;
    vncodcomissao_menor := null;
    vnrotinacomissao_maior      := null;
    vnrotinacomissao_menor     := null;

    BEGIN
      SELECT CODFORNEC
        INTO vncodfornec
        FROM PCPRODUT
       WHERE CODPROD = p_codprod;
    EXCEPTION
      WHEN OTHERS THEN
        vncodfornec := null;
    END;

    BEGIN
      SELECT CODATV1
        INTO vncodatv1
        FROM PCCLIENT
       WHERE CODCLI = p_codcli;
    EXCEPTION
      WHEN OTHERS THEN
        vncodatv1 := null;
    END;

    --vnPerCom := 0;

    -- Comissão apartir da ordem definida na rotina 132
    if p_tipoavaliacaocomissao = 1 then

      if p_OrdemAvaliacaoComissaoRCA = 1 then

        ValidarPCComissaoCliente(p_codcli,
                                   p_perdesc,
                                   vnCodFornec,
                                   p_codprod,
                                   p_codfilial,
                                   p_tipovend,
                                   p_considerarcomissaozero,
                                   p_data,
                                   vnpercom_aux,
                                   p_letracomiss,
                                   vncodcomiss,
                                   vsmensagem_comissaocliente);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;
          end if;

            if vsmensagem_comissaocliente is not null then

              if vsmensagem is null then
                  vsmensagem := vsmensagem_comissaocliente;
              else
                  vsmensagem := vsmensagem ||';'||vsmensagem_comissaocliente;
              end if;

            end if;

          ValidarPCComissaoAtividade(vncodatv1,
                                     p_perdesc,
                                     vnCodFornec,
                                     p_codprod,
                                     p_codfilial,
                                     p_tipovend,
                                     p_considerarcomissaozero,
                                     p_data,
                                     vnpercom_aux,
                                     p_letracomiss,
                                     vncodcomiss,
                                     vsmensagem_comissaoatividade);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;
          end if;

          if vsmensagem_comissaoatividade is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoatividade;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoatividade;
            end if;

          end if;

          ValidarPCComissaoFornecedor(vnCodFornec,
                                      p_perdesc,
                                      p_codprod,
                                      p_codfilial,
                                      p_tipovend,
                                      p_considerarcomissaozero,
                                      p_data,
                                      vnpercom_aux,
                                      p_letracomiss,
                                      vncodcomiss,
                                      vsmensagem_comissaofornecedor);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;
          end if;

          if vsmensagem_comissaofornecedor is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaofornecedor;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaofornecedor;
            end if;

          end if;

        Definir_Comissao_por_TERCEIRO(p_codprod,
                                      p_codcli,
                                      p_considerarcomissaozero,
                                      vnpercom_aux,
                                      vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom    := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 3304;

        end if;


        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null;
            p_rotinacomissao := 2014;

          end if;

        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then

            Definir_Comissao_por_PCProdut(p_tipovend,
                                          p_pcomint1,
                                          P_PCOMEXT1,
                                          P_PCOMREP1,
                                          p_codprod,
                                          p_codfilial,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

            if vnpercom_aux is not null then
              vnpercom := vnpercom_aux;
              p_codcomissao := null;
              p_rotinacomissao := 203;

            end if;

        end if;

        Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                      p_percomcli,
                                      p_considerarcomissaozero,
                                      p_codcli,
                                      p_codfilial,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 302;

        end if;

        Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                      p_tipovenda,
                                      p_percent,
                                      P_PERCENT2,
                                      p_considerarcomissaozero,
                                      p_comissaorcatipovenda,
                                      vnPerCom_aux);
        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 517;

        end if;

        Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                      p_ConsiderarComissaoZero,
                                      p_codplpag,
                                      p_codlinhaprod,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 558;

        end if;

        if p_UsaPcTabComiss then

          Definir_Comissao_por_LUCRO(p_perluc,
                                     p_perdesc,
                                     p_tipovend,
                                     p_tipocomissao,
                                     p_ConsiderarComissaoZero,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 550;

          end if;

        end if;

        if p_UsaPcComissaoUsur then
          Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                       p_codusur,
                                       p_ConsiderarComissaoZero,
                                       p_codepto,
                                       p_codsec,
                                       p_codprod,
                                       vnpercom_aux,
                                       vsletracomiss,
                                       vncodcomiss,
                                       vsmensagem_comissaousur);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 553 ;

          end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;

        end if;

        if p_UsaPCComissaoPlPag then
          ValidarPCCOMISSAOPLPAG(p_tipovend,
                                 p_codplpag,
                                 p_perdesc,
                                 p_codprod,
                                 p_codepto,
                                 p_codsec,
                                 p_classeproduto,
                                 p_ConsiderarComissaoZero,
                                 vnpercom_aux,
                                 vsletracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaoplpag);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 583;

          end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoRegiao then

          ValidarPCComissaoRegiao(p_numregiao,
                                  p_codfilial,
                                  p_perdesc,
                                  p_data,
                                  p_codprod,
                                  p_codsec,
                                  p_codepto,
                                  p_tipovend,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux,
                                  vsletracomiss,
                                  vncodcomiss,
                                  vsmensagem_comissaoregiao);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;

          end if;

          if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoFilial then

          Definir_Comissao_por_Filial(p_codfilial,
                                      p_ConsiderarComissaoZero,
                                      vnpercom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null;
            p_rotinacomissao := 2110;

          end if;

        end if;

        /*
        Autor      : Rafael Braga
        Solicitação: 2359.097355.2016
        Data       : 13/09/2016
        Descrição  : A rotina 316 aplica comissão da PCDESCONTO caso tenha sido encontrada
                     política de desconto, não necessariamente ela deve ter sido aplicada.
        */
        --if p_perdesc > 0 then --TAREFA: 1519.077167.2014
          Define_Comissao_Por_PCDesconto(p_coddesconto,
                                         p_tipovend,
                                         p_considerarcomissaozero,
                                         vnpercom_aux,
                                         p_perdesc,
                                         p_tabela,
                                         p_venda,
                                         p_numcasasdecvenda);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := p_coddesconto;
            p_rotinacomissao := 561;

          end if;
       -- end if; --FIM TAREFA: 1519.077167.2014

      elsif p_OrdemAvaliacaoComissaoRCA = 2 then

        ValidarPCComissaoCliente(p_codcli,
                                 p_perdesc,
                                 vnCodFornec,
                                 p_codprod,
                                 p_codfilial,
                                 p_tipovend,
                                 p_considerarcomissaozero,
                                 p_data,
                                 vnpercom_aux,
                                 p_letracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaocliente);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 363;
        end if;

          if vsmensagem_comissaocliente is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaocliente;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaocliente;
            end if;

          end if;

        ValidarPCComissaoAtividade(vncodatv1,
                                   p_perdesc,
                                   vnCodFornec,
                                   p_codprod,
                                   p_codfilial,
                                   p_tipovend,
                                   p_considerarcomissaozero,
                                   p_data,
                                   vnpercom_aux,
                                   p_letracomiss,
                                   vncodcomiss,
                                   vsmensagem_comissaoatividade);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 363;
        end if;

          if vsmensagem_comissaoatividade is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoatividade;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoatividade;
            end if;

          end if;

        ValidarPCComissaoFornecedor(vnCodFornec,
                                    p_perdesc,
                                    p_codprod,
                                    p_codfilial,
                                    p_tipovend,
                                    p_considerarcomissaozero,
                                    p_data,
                                    vnpercom_aux,
                                    p_letracomiss,
                                    vncodcomiss,
                                    vsmensagem_comissaofornecedor);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 363;
        end if;

        if vsmensagem_comissaofornecedor is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaofornecedor;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaofornecedor;
          end if;

        end if;

        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null;
            p_rotinacomissao := 2014;

          end if;

        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then

        Definir_Comissao_por_PCProdut(p_tipovend,
                                      p_pcomint1,
                                      P_PCOMEXT1,
                                      P_PCOMREP1,
                                      p_codprod,
                                      p_codfilial,
                                      p_considerarcomissaozero,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 203;

        end if;

        end if;

        Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                      p_ConsiderarComissaoZero,
                                      p_codplpag,
                                      p_codlinhaprod,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 558;

        end if;

        if p_UsaPcTabComiss then

          Definir_Comissao_por_LUCRO(p_perluc,
                                     p_perdesc,
                                     p_tipovend,
                                     p_tipocomissao,
                                     p_ConsiderarComissaoZero,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 550;

          end if;

        end if;

        if p_UsaPcComissaoUsur then

          Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                       p_codusur,
                                       p_ConsiderarComissaoZero,
                                       p_codepto,
                                       p_codsec,
                                       p_codprod,
                                       vnpercom_aux,
                                       vsletracomiss,
                                       vncodcomiss,
                                       vsmensagem_comissaousur);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss ;
            p_rotinacomissao := 553;

          end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoPlPag then

          ValidarPCCOMISSAOPLPAG(p_tipovend,
                                 p_codplpag,
                                 p_perdesc,
                                 p_codprod,
                                 p_codepto,
                                 p_codsec,
                                 p_classeproduto,
                                 p_ConsiderarComissaoZero,
                                 vnpercom_aux,
                                 vsletracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaoplpag);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 583;

          end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoRegiao then

          ValidarPCComissaoRegiao(p_numregiao,
                                  p_codfilial,
                                  p_perdesc,
                                  p_data,
                                  p_codprod,
                                  p_codsec,
                                  p_codepto,
                                  p_tipovend,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux,
                                  vsletracomiss,
                                  vncodcomiss,
                                  vsmensagem_comissaoregiao);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;

          end if;

          if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;

        end if;

        Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                      p_tipovenda,
                                      p_percent,
                                      P_PERCENT2,
                                      p_considerarcomissaozero,
                                      p_comissaorcatipovenda,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao :=517 ;


        end if;

        Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                      p_percomcli,
                                      p_considerarcomissaozero,
                                      p_codcli,
                                      p_codfilial,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 302;

        end if;

        Definir_Comissao_por_TERCEIRO(p_codprod,
                                      p_codcli,
                                      p_considerarcomissaozero,
                                      vnpercom_aux,
                                      vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 3304;

        end if;

        if p_UsaPCComissaoFilial then

          Definir_Comissao_por_Filial(p_codfilial,
                                      p_ConsiderarComissaoZero,
                                      vnpercom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null ;
            p_rotinacomissao := 2110;

          end if;

        end if;

        Define_Comissao_Por_PCDesconto(p_coddesconto,
                                         p_tipovend,
                                         p_considerarcomissaozero,
                                         vnpercom_aux,
                                         p_perdesc,
                                         p_tabela,
                                         p_venda,
                                         p_numcasasdecvenda);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := p_coddesconto;
          p_rotinacomissao := 561;

        end if;

      end if;

      --Comissão por sobre posição
    elsif p_tipoavaliacaocomissao = 2 then

      SELECT count(*)
        into vicont
        FROM PCOrdemApuracaoComis
       WHERE CODFILIAL = p_CODFILIAL;

      if vicont <> 0 then

        SELECT count(*)
          into vicont
          FROM PCOrdemApuracaoComis
         WHERE CODFILIAL = p_CODFILIAL
           AND NVL(ORDEM, 0) = 0;

        if vicont <> 0 then

          if vsmensagem is null then
            vsmensagem := 'Ordem de validação das comissões está inválida! Verifique rotina 584.';
          else
            vsmensagem := vsmensagem||';'||'Ordem de validação das comissões está inválida! Verifique rotina 584.';

          end if;

        else

          for reg in (SELECT CODCOMIS, ORDEM
                        FROM PCOrdemApuracaoComis
                       WHERE CODFILIAL = p_CODFILIAL
                       ORDER BY ORDEM) loop

            if reg.codcomis = 1 then

              if p_utilizavendaporembalagem = 'S' then

                Definir_comissao_Por_Embalagem( p_tipovend,
                                                p_pcomint1_emb,
                                                P_PCOMEXT1_emb,
                                                P_PCOMREP1_emb,
                                                p_considerarcomissaozero,
                                                vnPerCom_aux);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := null;
                  p_rotinacomissao := 2014;

                end if;

              end if;

               if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then


                    Definir_Comissao_por_PCProdut(p_tipovend,
                                                  p_pcomint1,
                                                  P_PCOMEXT1,
                                                  P_PCOMREP1,
                                                  p_codprod,
                                                  p_codfilial,
                                                  p_considerarcomissaozero,
                                                  vnPerCom_aux);
                    if vnpercom_aux is not null then
                      vnpercom := vnpercom_aux;
                      p_codcomissao := null;
                      p_rotinacomissao := 203;

                    end if;

             end if;

            elsif reg.codcomis = 2 then
              Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                            p_percomcli,
                                            p_considerarcomissaozero,
                                            p_codcli,
                                            p_codfilial,
                                            vnPerCom_aux);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := null;
                p_rotinacomissao := 302;


              end if;

            elsif reg.codcomis = 3 then
              Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                            p_tipovenda,
                                            p_percent,
                                            P_PERCENT2,
                                            p_considerarcomissaozero,
                                            p_comissaorcatipovenda,
                                            vnPerCom_aux);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := null;
                p_rotinacomissao := 517;


              end if;

            elsif reg.codcomis = 4 then
              Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                            p_ConsiderarComissaoZero,
                                            p_codplpag,
                                            p_codlinhaprod,
                                            vnPerCom_aux);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := null;
                p_rotinacomissao := 558;


              end if;

            elsif reg.codcomis = 5 then

              if p_UsaPcTabComiss then
                Definir_Comissao_por_LUCRO(p_perluc,
                                           p_perdesc,
                                           p_tipovend,
                                           p_tipocomissao,
                                           p_ConsiderarComissaoZero,
                                           vnpercom_aux,
                                           vsletracomiss,
                                           vncodcomiss);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 550;

                end if;

              end if;

            elsif reg.codcomis = 6 then
              if p_UsaPcComissaoUsur then

                Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                             p_codusur,
                                             p_ConsiderarComissaoZero,
                                             p_codepto,
                                             p_codsec,
                                             p_codprod,
                                             vnpercom_aux,
                                             vsletracomiss,
                                             vncodcomiss,
                                             vsmensagem_comissaousur);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 553;

                end if;

                if vsmensagem_comissaousur is not null then

                  if vsmensagem is null then
                      vsmensagem := vsmensagem_comissaousur;
                  else
                      vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
                  end if;

                end if;


              end if;

            elsif reg.codcomis = 7 then
              if p_UsaPCComissaoPlPag then

                ValidarPCCOMISSAOPLPAG(p_tipovend,
                                       p_codplpag,
                                       p_perdesc,
                                       p_codprod,
                                       p_codepto,
                                       p_codsec,
                                       p_classeproduto,
                                       p_ConsiderarComissaoZero,
                                       vnpercom_aux,
                                       vsletracomiss,
                                       vncodcomiss,
                                       vsmensagem_comissaoplpag);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 583;

                end if;


                if vsmensagem_comissaoplpag is not null then

                  if vsmensagem is null then
                      vsmensagem := vsmensagem_comissaoplpag;
                  else
                      vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
                  end if;

                end if;


              end if;

            elsif reg.codcomis = 8 then
              if p_UsaPCComissaoRegiao then

                ValidarPCComissaoRegiao(p_numregiao,
                                        p_codfilial,
                                        p_perdesc,
                                        p_data,
                                        p_codprod,
                                        p_codsec,
                                        p_codepto,
                                        p_tipovend,
                                        p_ConsiderarComissaoZero,
                                        vnpercom_aux,
                                        vsletracomiss,
                                        vncodcomiss,
                                        vsmensagem_comissaoregiao);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 363;

                end if;

              if vsmensagem_comissaoregiao is not null then

                if vsmensagem is null then
                    vsmensagem := vsmensagem_comissaoregiao;
                else
                    vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
                end if;

              end if;

              end if;

            elsif reg.codcomis = 9 then

              Definir_Comissao_por_TERCEIRO(p_codprod,
                                            p_codcli,
                                            p_ConsiderarComissaoZero,
                                            vnpercom_aux,
                                            vncodcomiss);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := vncodcomiss;
                p_rotinacomissao := 3304;

              end if;

            elsif reg.codcomis = 10 then

              Define_Comissao_Por_PCDesconto(p_coddesconto,
                                             p_tipovend,
                                             p_considerarcomissaozero,
                                             vnpercom_aux,
                                             p_perdesc,
                                             p_tabela,
                                             p_venda,
                                             p_numcasasdecvenda);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := p_coddesconto;
                p_rotinacomissao := 561;

              end if;

            elsif reg.codcomis = 12 then

              ValidarPCComissaoCliente(p_codcli,
                                 p_perdesc,
                                 vnCodFornec,
                                 p_codprod,
                                 p_codfilial,
                                 p_tipovend,
                                 p_considerarcomissaozero,
                                 p_data,
                                 vnpercom_aux,
                                 p_letracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaocliente);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := vncodcomiss;
                p_rotinacomissao := 363;
              end if;

              if vsmensagem_comissaocliente is not null then

                if vsmensagem is null then
                    vsmensagem := vsmensagem_comissaocliente;
                else
                    vsmensagem := vsmensagem ||';'||vsmensagem_comissaocliente;
                end if;

              end if;

           elsif reg.codcomis = 13 then

             ValidarPCComissaoFornecedor(vnCodFornec,
                                    p_perdesc,
                                    p_codprod,
                                    p_codfilial,
                                    p_tipovend,
                                    p_considerarcomissaozero,
                                    p_data,
                                    vnpercom_aux,
                                    p_letracomiss,
                                    vncodcomiss,
                                    vsmensagem_comissaofornecedor);

             if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := vncodcomiss;
                p_rotinacomissao := 363;
              end if;

              if vsmensagem_comissaofornecedor is not null then

                if vsmensagem is null then
                    vsmensagem := vsmensagem_comissaofornecedor;
                else
                    vsmensagem := vsmensagem ||';'||vsmensagem_comissaofornecedor;
                end if;

             end if;

           elsif reg.codcomis = 14 then

             ValidarPCComissaoAtividade(vncodatv1,
                                        p_perdesc,
                                        vnCodFornec,
                                        p_codprod,
                                        p_codfilial,
                                        p_tipovend,
                                        p_considerarcomissaozero,
                                        p_data,
                                        vnpercom_aux,
                                        p_letracomiss,
                                        vncodcomiss,
                                        vsmensagem_comissaoatividade);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := vncodcomiss;
                p_rotinacomissao := 363;
              end if;

              if vsmensagem_comissaoatividade is not null then

                if vsmensagem is null then
                    vsmensagem := vsmensagem_comissaoatividade;
                else
                    vsmensagem := vsmensagem ||';'||vsmensagem_comissaoatividade;
                end if;

              end if;

            end if;
          end loop;
        end if;
      end if;

      if p_UsaPCComissaoFilial then

        Definir_Comissao_por_Filial(p_codfilial,
                                    p_ConsiderarComissaoZero,
                                    vnpercom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 2110;

        end if;

      end if;

      -- Menor valor de comissão
    elsif p_tipoavaliacaocomissao = 3 then

      ValidarPCComissaoCliente(p_codcli,
                                 p_perdesc,
                                 vnCodFornec,
                                 p_codprod,
                                 p_codfilial,
                                 p_tipovend,
                                 p_considerarcomissaozero,
                                 p_data,
                                 vnpercom_aux,
                                 p_letracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaocliente);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          vncodcomissao_menor := vncodcomiss;
          vnrotinacomissao_menor := 363;
        end if;

        if vsmensagem_comissaocliente is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaocliente;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaocliente;
          end if;

        end if;

        ValidarPCComissaoAtividade(vncodatv1,
                                   p_perdesc,
                                   vnCodFornec,
                                   p_codprod,
                                   p_codfilial,
                                   p_tipovend,
                                   p_considerarcomissaozero,
                                   p_data,
                                   vnpercom_aux,
                                   p_letracomiss,
                                   vncodcomiss,
                                   vsmensagem_comissaoatividade);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          vncodcomissao_menor := vncodcomiss;
          vnrotinacomissao_menor := 363;
        end if;

        if vsmensagem_comissaoatividade is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaoatividade;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaoatividade;
          end if;

        end if;

        ValidarPCComissaoFornecedor(vnCodFornec,
                                    p_perdesc,
                                    p_codprod,
                                    p_codfilial,
                                    p_tipovend,
                                    p_considerarcomissaozero,
                                    p_data,
                                    vnpercom_aux,
                                    p_letracomiss,
                                    vncodcomiss,
                                    vsmensagem_comissaofornecedor);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          vncodcomissao_menor := vncodcomiss;
          vnrotinacomissao_menor := 363;
        end if;

        if vsmensagem_comissaofornecedor is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaofornecedor;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaofornecedor;
          end if;

        end if;

        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
          end if;

          vnPerCom_Menor := vnPerCom;
          vncodcomissao_menor := null;
          vnrotinacomissao_menor := 2014;


        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then


          Definir_Comissao_por_PCProdut(p_tipovend,
                                        p_pcomint1,
                                        P_PCOMEXT1,
                                        P_PCOMREP1,
                                        p_codprod,
                                        p_codfilial,
                                        p_considerarcomissaozero,
                                        vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
          end if;

          vnPerCom_Menor := vnPerCom;
          vncodcomissao_menor := null;
          vnrotinacomissao_menor := 203;

      end if;


      Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                    p_percomcli,
                                    p_considerarcomissaozero,
                                    p_codcli,
                                    p_codfilial,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
     end if;

      if (vnPerCom_Menor > vnPerCom) or vnpercom_menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 302;

      end if;

      Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                    p_tipovenda,
                                    p_percent,
                                    P_PERCENT2,
                                    p_considerarcomissaozero,
                                    p_comissaorcatipovenda,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
         vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 517;

      end if;

      Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                    p_ConsiderarComissaoZero,
                                    p_codplpag,
                                    p_codlinhaprod,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 558;

      end if;

      if p_UsaPcTabComiss then
        Definir_Comissao_por_LUCRO(p_perluc,
                                   p_perdesc,
                                   p_tipovend,
                                   p_tipocomissao,
                                   p_ConsiderarComissaoZero,
                                   vnpercom_aux,
                                   vsletracomiss,
                                   vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;

        end if;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 550;

      end if;

      if p_UsaPcComissaoUsur then
        Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                     p_codusur,
                                     p_ConsiderarComissaoZero,
                                     p_codepto,
                                     p_codsec,
                                     p_codprod,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss,
                                     vsmensagem_comissaousur);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;

        end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;



      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 553;

      end if;

      if p_UsaPCComissaoPlPag then
        ValidarPCCOMISSAOPLPAG(p_tipovend,
                               p_codplpag,
                               p_perdesc,
                               p_codprod,
                               p_codepto,
                               p_codsec,
                               p_classeproduto,
                               p_ConsiderarComissaoZero,
                               vnpercom_aux,
                               vsletracomiss,
                               vncodcomiss,
                               vsmensagem_comissaoplpag);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 583;

      end if;

      if p_UsaPCComissaoRegiao then
        ValidarPCComissaoRegiao(p_numregiao,
                                p_codfilial,
                                p_perdesc,
                                p_data,
                                p_codprod,
                                p_codsec,
                                p_codepto,
                                p_tipovend,
                                p_ConsiderarComissaoZero,
                                vnpercom_aux,
                                vsletracomiss,
                                vncodcomiss,
                                vsmensagem_comissaoregiao);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;

        end if;

         if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 363;

      end if;

      Definir_Comissao_por_TERCEIRO(p_codprod,
                                    p_codcli,
                                    p_ConsiderarComissaoZero,
                                    vnpercom_aux,
                                    vncodcomiss);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 3304;

      end if;

      Definir_Comissao_por_Filial(p_codfilial,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 2110;

      end if;

      Define_Comissao_Por_PCDesconto(p_coddesconto,
                                     p_tipovend,
                                     p_considerarcomissaozero,
                                     vnpercom_aux,
                                     p_perdesc,
                                     p_tabela,
                                     p_venda,
                                     p_numcasasdecvenda);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := p_coddesconto;
        vnrotinacomissao_menor := 561;

      end if;

      -- Atribuindo a menor comissão para a variável que será retornada para o Result
      vnPerCom := vnPerCom_Menor;
       p_codcomissao :=  vncodcomissao_menor;
       p_rotinacomissao := vnrotinacomissao_menor;


      -- Maior valor de comissão
    elsif p_tipoavaliacaocomissao = 4 then

        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
          end if;

            vnPerCom_Maior := vnPerCom;
            vncodcomissao_maior := null;
            vnrotinacomissao_maior := 2014;


        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then


            Definir_Comissao_por_PCProdut(p_tipovend,
                                          p_pcomint1,
                                          P_PCOMEXT1,
                                          P_PCOMREP1,
                                          p_codprod,
                                          p_codfilial,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

            if vnpercom_aux is not null then
              vnpercom := vnpercom_aux;
            end if;

            vnPerCom_Maior := vnPerCom;
            vncodcomissao_maior := null;
            vnrotinacomissao_maior := 203;

      end if;

      Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                    p_percomcli,
                                    p_considerarcomissaozero,
                                    p_codcli,
                                    p_codfilial,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 302;

      end if;

      ValidarPCComissaoCliente(p_codcli,
                               p_perdesc,
                               vnCodFornec,
                               p_codprod,
                               p_codfilial,
                               p_tipovend,
                               p_considerarcomissaozero,
                               p_data,
                               vnpercom_aux,
                               p_letracomiss,
                               vncodcomiss,
                               vsmensagem_comissaocliente);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

        if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
          vnPerCom_Maior := vnPerCom;
          vncodcomissao_maior := vncodcomiss;
          vnrotinacomissao_maior := 363;

        end if;

        if vsmensagem_comissaocliente is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaocliente;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaocliente;
          end if;

        end if;

        ValidarPCComissaoAtividade(vncodatv1,
                                   p_perdesc,
                                   vnCodFornec,
                                   p_codprod,
                                   p_codfilial,
                                   p_tipovend,
                                   p_considerarcomissaozero,
                                   p_data,
                                   vnpercom_aux,
                                   p_letracomiss,
                                   vncodcomiss,
                                   vsmensagem_comissaoatividade);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

        if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
          vnPerCom_Maior := vnPerCom;
          vncodcomissao_maior := vncodcomiss;
          vnrotinacomissao_maior := 363;

        end if;

        if vsmensagem_comissaoatividade is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaoatividade;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaoatividade;
          end if;

        end if;

        ValidarPCComissaoFornecedor(vnCodFornec,
                                    p_perdesc,
                                    p_codprod,
                                    p_codfilial,
                                    p_tipovend,
                                    p_considerarcomissaozero,
                                    p_data,
                                    vnpercom_aux,
                                    p_letracomiss,
                                    vncodcomiss,
                                    vsmensagem_comissaofornecedor);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

        if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
          vnPerCom_Maior := vnPerCom;
          vncodcomissao_maior := vncodcomiss;
          vnrotinacomissao_maior := 363;

        end if;

        if vsmensagem_comissaofornecedor is not null then

          if vsmensagem is null then
              vsmensagem := vsmensagem_comissaofornecedor;
          else
              vsmensagem := vsmensagem ||';'||vsmensagem_comissaofornecedor;
          end if;

        end if;

      Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                    p_tipovenda,
                                    p_percent,
                                    P_PERCENT2,
                                    p_considerarcomissaozero,
                                    p_comissaorcatipovenda,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 517;

      end if;

      Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                    p_ConsiderarComissaoZero,
                                    p_codplpag,
                                    p_codlinhaprod,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 558;

      end if;

      if p_UsaPcTabComiss then

        Definir_Comissao_por_LUCRO(p_perluc,
                                   p_perdesc,
                                   p_tipovend,
                                   p_tipocomissao,
                                   p_ConsiderarComissaoZero,
                                   vnpercom_aux,
                                   vsletracomiss,
                                   vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 550;

      end if;

      if p_UsaPcComissaoUsur then

        Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                     p_codusur,
                                     p_ConsiderarComissaoZero,
                                       p_codepto,
                                       p_codsec,
                                       p_codprod,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss,
                                     vsmensagem_comissaousur);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;


      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 553;

      end if;

      if p_UsaPCComissaoPlPag then

        ValidarPCCOMISSAOPLPAG(p_tipovend,
                               p_codplpag,
                               p_perdesc,
                               p_codprod,
                               p_codepto,
                               p_codsec,
                               p_classeproduto,
                               p_ConsiderarComissaoZero,
                               vnpercom_aux,
                               vsletracomiss,
                               vncodcomiss,
                               vsmensagem_comissaoplpag);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


      end if;



      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 583;

      end if;

      if p_UsaPCComissaoRegiao then
        ValidarPCComissaoRegiao(p_numregiao,
                                p_codfilial,
                                p_perdesc,
                                p_data,
                                p_codprod,
                                p_codsec,
                                p_codepto,
                                p_tipovend,
                                p_ConsiderarComissaoZero,
                                vnpercom_aux,
                                vsletracomiss,
                                vncodcomiss,
                                vsmensagem_comissaoregiao);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;

      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 363;

      end if;

      Definir_Comissao_por_TERCEIRO(p_codprod,
                                    p_codcli,
                                    p_ConsiderarComissaoZero,
                                    vnpercom_aux,
                                    vncodcomiss);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
         vnPerCom_Maior := vnPerCom;
         vncodcomissao_maior := vncodcomiss;
         vnrotinacomissao_maior := 3304;

      end if;

      Definir_Comissao_por_Filial(p_codfilial,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 2110;

      end if;

      Define_Comissao_Por_PCDesconto(p_coddesconto,
                                     p_tipovend,
                                     p_considerarcomissaozero,
                                     vnpercom_aux,
                                     p_perdesc,
                                     p_tabela,
                                     p_venda,
                                     p_numcasasdecvenda);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := p_coddesconto;
        vnrotinacomissao_maior := 561;

      end if;

      -- Atribuindo a menor comissão para a variável que será retornada para o Result
      vnPerCom         := vnPerCom_Maior;
      p_codcomissao    :=  vncodcomissao_maior ;
      p_rotinacomissao := vnrotinacomissao_maior  ;


    end if;

    p_letracomiss := vsletracomiss;

    if vnpercom is null then

      vnpercom := 0;
      p_codcomissao := null;
      p_rotinacomissao := null;
    end if;

  p_mensagem := vsmensagem;

    return vnPerCom;

  exception
    when others then

     if vsmensagem is null then
         vsmensagem := 'Erro ao calcular comissao : ' || SQLCODE || ' ' || SQLERRM;
     else
         vsmensagem := vsmensagem||';'||'Erro ao calcular comissao : ' || SQLCODE || ' ' || SQLERRM;
     end if;

     p_mensagem := vsmensagem;

  end;

FUNCTION Definir_Comissao_Item_Vendido(P_NUMTRANSENT     IN NUMBER
                                      ,P_CODPROD         IN NUMBER DEFAULT 0
                                      ,P_NUMSEQ          IN NUMBER DEFAULT 0
                                      ,P_CODCOMISSAO     OUT NUMBER
                                      ,P_ROTINACOMISSAO  OUT VARCHAR2
                                      ,P_LETRACOMISS     OUT VARCHAR2
                                      ,P_MENSAGEM        OUT VARCHAR2)
    RETURN NUMBER IS

    vnpercom               number;
    vnPerCom_Maior         number;
    vnPerCom_Menor         number;
    vsletracomiss          pcpedi.letracomiss%type;
    vicont                 number;
    vnpercom_aux           number;
    vncodcomiss            pcorigemcomis.codcomis%type;
    vnrotinacomissao_menor pcorigemcomis.codrotinacomis%type;
    vncodcomissao_menor    pcorigemcomis.codcomis%type;
    vnrotinacomissao_maior pcorigemcomis.codrotinacomis%type;
    vncodcomissao_maior    pcorigemcomis.codcomis%type;

    vsmensagem                varchar2(1000);
    vsmensagem_comissaousur   varchar2(200);
    vsmensagem_comissaoplpag  varchar2(200);
    vsmensagem_comissaoregiao varchar2(200);

    -- VARIAVEIS UTILIZADAS NO PROCESSO ----------------------------------------------------
    p_NumRegiao                 pcregiao.numregiao%type;
    p_perluc                    number;
    p_perdesc                   number;
    p_UsaPcTabComiss            boolean;
    p_UsaPcComissaoUsur         boolean;
    p_UsaPCComissaoPlPag        boolean;
    p_UsaPCComissaoRegiao       boolean;
    p_UsaPCComissaoFilial       boolean;
    p_usacomissaoporrca         pcconsum.usacomissaoporrca%type;
    p_OrdemAvaliacaoComissaoRCA pcconsum.ordemavaliacaocomissaorca%type;
    p_usacomissaoporcliente     pcconsum.usacomissaoporcliente%type;
    p_USACOMISSAOPORLINHAPROD   pcconsum.usacomissaoporlinhaprod%type;
    p_comissaorcatipovenda      pcconsum.comissaorcatipovenda%type;
    p_tipovend                  pcusuari.tipovend%type;
    p_percent                   pcusuari.percent%type;
    p_percent2                  pcusuari.percent2%type;
    p_pcomint1                  pcprodut.pcomint1%type;
    P_PCOMEXT1                  pcprodut.pcomext1%type;
    P_PCOMREP1                  pcprodut.pcomrep1%type;
    p_codlinhaprod              pcprodut.codlinhaprod%type;
    p_tipocomissao              pcprodut.tipocomissao%type;
    p_codepto                   pcprodut.codepto%type;
    p_codsec                    pcprodut.codsec%type;
    p_classeproduto             pcprodut.classe%type;
    p_tipovenda                 pcplpag.tipovenda%type;
    p_codplpag                  pcpedc.codplpag%type;
    p_data                      pcpedc.data%type;
    p_codfilial                 pcpedc.codfilial%type;
    p_codusur                   pcpedc.codusur%type;
    p_considerarcomissaozero    pcfilial.considerarcomissaozero%type;
    p_tipoavaliacaocomissao     pcfilial.tipoavaliacaocomissao%type;
    p_percomcli                 pcclient.percomcli%type;
    p_codcli                    pcclient.codcli%type;
    p_coddesconto               pcdesconto.coddesconto%type;
    -- CAMPOS COM VALOR DEFAULT
    p_codauxiliar               pcembalagem.codauxiliar%type default null;
    p_pcomint1_emb              pcembalagem.pcomint1%type default null;
    P_PCOMEXT1_emb              pcembalagem.pcomext1%type default null;
    P_PCOMREP1_emb              pcembalagem.pcomrep1%type default null;
    p_utilizavendaporembalagem  pcconsum.utilizavendaporembalagem%type default 'N';
    p_tabela                    number default 0;
    p_venda                     number default 0;
    p_numcasasdecvenda          number default 2;
    -- FIM DECLARAÇÃO VARIAVEIS ----------------------------------------------------

begin
  -- DEFINIR VARIAVEIS COM VALOR PADRÃO
  p_perluc   := 0;
  --vnperluc := ((integradora_comple.gvet_regitem(j).pvenda - integradora_comple.gvet_regitem(j).vlcustofin) / integradora_comple.gvet_regitem(j).pvenda) * 100;
  p_perdesc  := 0;
  --integradora_comple.gvet_regitem(j).perdesc := integradora_comple.func_calcularperdescitem(integradora_comple.gvet_regitem(j).ptabela,integradora_comple.gvet_regitem(j).pvenda);

  -- BUSCA DADOS PARA DEFINIR A COMISSÃO
  BEGIN
      SELECT PCMOV.NUMREGIAO
            ,NVL(PCUSUARI.TIPOVEND, 'R')
            ,PCUSUARI.PERCENT
            ,PCUSUARI.PERCENT2
            ,PCPRODUT.PCOMINT1
            ,PCPRODUT.PCOMEXT1
            ,PCPRODUT.PCOMREP1
            ,PCPRODUT.CODLINHAPROD
            ,PCPRODUT.TIPOCOMISSAO
            ,PCPRODUT.CODEPTO
            ,PCPRODUT.CODSEC
            ,PCPRODUT.CLASSE
            ,PCPLPAG.TIPOVENDA
            ,PCMOV.CODPLPAG
            ,PCMOV.DTMOV
            ,NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)
            ,PCMOV.CODUSUR
            ,PCFILIAL.CONSIDERARCOMISSAOZERO
            ,PCFILIAL.TIPOAVALIACAOCOMISSAO
            ,PCCLIENT.PERCOMCLI
            ,PCCLIENT.CODCLI
            ,PCMOV.CODDESCONTO
        INTO p_NumRegiao
            ,p_tipovend
            ,p_percent
            ,p_percent2
            ,p_pcomint1
            ,P_PCOMEXT1
            ,P_PCOMREP1
            ,p_codlinhaprod
            ,p_tipocomissao
            ,p_codepto
            ,p_codsec
            ,p_classeproduto
            ,p_tipovenda
            ,p_codplpag
            ,p_data
            ,p_codfilial
            ,p_codusur
            ,p_considerarcomissaozero
            ,p_tipoavaliacaocomissao
            ,p_percomcli
            ,p_codcli
            ,p_coddesconto
        FROM PCNFENT
            ,PCMOV
            ,PCPRODUT
            ,PCUSUARI
            ,PCPLPAG
            ,PCFILIAL
            ,PCCLIENT
       WHERE PCNFENT.NUMTRANSENT = PCMOV.NUMTRANSENT
         AND PCMOV.CODPROD = PCPRODUT.CODPROD(+)
         AND PCMOV.CODUSUR = PCUSUARI.CODUSUR(+)
         AND PCMOV.CODPLPAG = PCPLPAG.CODPLPAG(+)
         AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCFILIAL.CODIGO
         AND PCNFENT.CODFORNEC = PCCLIENT.CODCLI
         -- FILTRO DO ITEM
         AND PCNFENT.NUMTRANSENT = P_NUMTRANSENT
         AND PCMOV.CODPROD = P_CODPROD
         AND PCMOV.NUMSEQ = DECODE(P_NUMSEQ, 0, PCMOV.NUMSEQ, P_NUMSEQ);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        P_CODCOMISSAO    := null;
        P_ROTINACOMISSAO := null;
        P_LETRACOMISS    := null;
        P_MENSAGEM       := 'ITEM NÃO ENCONTRADO';
    END;

    -- UTILIZA TABELA COMISSAO
    SELECT COUNT(*) INTO vicont FROM pctabcomiss p;
    p_UsaPcTabComiss := vicont <> 0;

    -- UTILIZA COMISSÃO POR USUARIO
    SELECT COUNT(*) INTO vicont FROM pccomissaousur p;
    p_UsaPcComissaoUsur := vicont <> 0;

    -- UTILIZA COMISSÃO POR PLANO PAGAMENTO
    SELECT COUNT(*) INTO vicont FROM pccomissaoplpag p;
    p_UsaPCComissaoPlPag :=  vicont <> 0;

    -- UTILIZA COMISSÃO POR REGIÃO
    SELECT COUNT(*) INTO vicont FROM pccomissaoregiao p;
    p_UsaPCComissaoRegiao :=  vicont <> 0;

    -- UTILZIA COMISSAO FILIAL
    p_UsaPCComissaoFilial := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_BROKER','13','N') = 'S';

    -- UTILIZA COMISSÃO POR RCA
    p_usacomissaoporrca := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USACOMISSAOPORRCA', '99', 'N');

    -- ORDEM DE AVALIAÇÃO COMISSÃO RCA
    p_OrdemAvaliacaoComissaoRCA := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ORDEMAVALIACAOCOMISSAORCA','99','N');

    -- UTILIZA COMISSÃO POR CLIENTE
    p_usacomissaoporcliente := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USACOMISSAOPORCLIENTE','99', 'N');

    -- UTILIZA COMISSÃO POR LINHA PRODUTOS
    p_USACOMISSAOPORLINHAPROD := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USACOMISSAOPORLINHAPROD','99','N');

    -- COMISSÃO RCA TIPO VENDA
    p_comissaorcatipovenda := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_COMISSAORCATIPOVENDA','99', 'N');
    -- FIM BUSCA DADOS ---------------------------------------------------


    vsmensagem                := null;
    vsmensagem_comissaousur   := null;
    vsmensagem_comissaoplpag  := null;
    vsmensagem_comissaoregiao := null;


    p_codcomissao          := null;
    p_rotinacomissao       := null;
    vncodcomiss            := null;
    vncodcomissao_maior    := null;
    vncodcomissao_menor    := null;
    vnrotinacomissao_maior := null;
    vnrotinacomissao_menor := null;

    -- Comissão apartir da ordem definida na rotina 132
    if p_tipoavaliacaocomissao = 1 then

      if p_OrdemAvaliacaoComissaoRCA = 1 then

        Definir_Comissao_por_TERCEIRO(p_codprod,
                                      p_codcli,
                                      p_considerarcomissaozero,
                                      vnpercom_aux,
                                      vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom    := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 3304;

        end if;


        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null;
            p_rotinacomissao := 2014;

          end if;

        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then

            Definir_Comissao_por_PCProdut(p_tipovend,
                                          p_pcomint1,
                                          P_PCOMEXT1,
                                          P_PCOMREP1,
                                          p_codprod,
                                          p_codfilial,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

            if vnpercom_aux is not null then
              vnpercom := vnpercom_aux;
              p_codcomissao := null;
              p_rotinacomissao := 203;

            end if;

        end if;

        Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                      p_percomcli,
                                      p_considerarcomissaozero,
                                      p_codcli,
                                      p_codfilial,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 302;

        end if;

        Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                      p_tipovenda,
                                      p_percent,
                                      P_PERCENT2,
                                      p_considerarcomissaozero,
                                      p_comissaorcatipovenda,
                                      vnPerCom_aux);
        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 517;

        end if;

        Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                      p_ConsiderarComissaoZero,
                                      p_codplpag,
                                      p_codlinhaprod,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 558;

        end if;

        if p_UsaPcTabComiss then

          Definir_Comissao_por_LUCRO(p_perluc,
                                     p_perdesc,
                                     p_tipovend,
                                     p_tipocomissao,
                                     p_ConsiderarComissaoZero,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 550;

          end if;

        end if;

        if p_UsaPcComissaoUsur then
          Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                       p_codusur,
                                       p_ConsiderarComissaoZero,
                                       p_codepto,
                                       p_codsec,
                                       p_codprod,
                                       vnpercom_aux,
                                       vsletracomiss,
                                       vncodcomiss,
                                       vsmensagem_comissaousur);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 553 ;

          end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;

        end if;

        if p_UsaPCComissaoPlPag then
          ValidarPCCOMISSAOPLPAG(p_tipovend,
                                 p_codplpag,
                                 p_perdesc,
                                 p_codprod,
                                 p_codepto,
                                 p_codsec,
                                 p_classeproduto,
                                 p_ConsiderarComissaoZero,
                                 vnpercom_aux,
                                 vsletracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaoplpag);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 583;

          end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoRegiao then

          ValidarPCComissaoRegiao(p_numregiao,
                                  p_codfilial,
                                  p_perdesc,
                                  p_data,
                                  p_codprod,
                                  p_codsec,
                                  p_codepto,
                                  p_tipovend,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux,
                                  vsletracomiss,
                                  vncodcomiss,
                                  vsmensagem_comissaoregiao);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;

          end if;

          if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoFilial then

          Definir_Comissao_por_Filial(p_codfilial,
                                      p_ConsiderarComissaoZero,
                                      vnpercom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null;
            p_rotinacomissao := 2110;

          end if;

        end if;

        /*
        Autor      : Rafael Braga
        Solicitação: 2359.097355.2016
        Data       : 13/09/2016
        Descrição  : A rotina 316 aplica comissão da PCDESCONTO caso tenha sido encontrada
                     política de desconto, não necessariamente ela deve ter sido aplicada.
        */
        --if p_perdesc > 0 then --TAREFA: 1519.077167.2014
          Define_Comissao_Por_PCDesconto(p_coddesconto,
                                         p_tipovend,
                                         p_considerarcomissaozero,
                                         vnpercom_aux,
                                         p_perdesc,
                                         p_tabela,
                                         p_venda,
                                         p_numcasasdecvenda);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := p_coddesconto;
            p_rotinacomissao := 561;

          end if;
       -- end if; --FIM TAREFA: 1519.077167.2014

      elsif p_OrdemAvaliacaoComissaoRCA = 2 then


        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null;
            p_rotinacomissao := 2014;

          end if;

        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then

        Definir_Comissao_por_PCProdut(p_tipovend,
                                      p_pcomint1,
                                      P_PCOMEXT1,
                                      P_PCOMREP1,
                                      p_codprod,
                                      p_codfilial,
                                      p_considerarcomissaozero,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 203;

        end if;

        end if;

        Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                      p_ConsiderarComissaoZero,
                                      p_codplpag,
                                      p_codlinhaprod,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 558;

        end if;

        if p_UsaPcTabComiss then

          Definir_Comissao_por_LUCRO(p_perluc,
                                     p_perdesc,
                                     p_tipovend,
                                     p_tipocomissao,
                                     p_ConsiderarComissaoZero,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 550;

          end if;

        end if;

        if p_UsaPcComissaoUsur then

          Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                       p_codusur,
                                       p_ConsiderarComissaoZero,
                                       p_codepto,
                                       p_codsec,
                                       p_codprod,
                                       vnpercom_aux,
                                       vsletracomiss,
                                       vncodcomiss,
                                       vsmensagem_comissaousur);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss ;
            p_rotinacomissao := 553;

          end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoPlPag then

          ValidarPCCOMISSAOPLPAG(p_tipovend,
                                 p_codplpag,
                                 p_perdesc,
                                 p_codprod,
                                 p_codepto,
                                 p_codsec,
                                 p_classeproduto,
                                 p_ConsiderarComissaoZero,
                                 vnpercom_aux,
                                 vsletracomiss,
                                 vncodcomiss,
                                 vsmensagem_comissaoplpag);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 583;

          end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


        end if;

        if p_UsaPCComissaoRegiao then

          ValidarPCComissaoRegiao(p_numregiao,
                                  p_codfilial,
                                  p_perdesc,
                                  p_data,
                                  p_codprod,
                                  p_codsec,
                                  p_codepto,
                                  p_tipovend,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux,
                                  vsletracomiss,
                                  vncodcomiss,
                                  vsmensagem_comissaoregiao);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := vncodcomiss;
            p_rotinacomissao := 363;

          end if;

          if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;

        end if;

        Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                      p_tipovenda,
                                      p_percent,
                                      P_PERCENT2,
                                      p_considerarcomissaozero,
                                      p_comissaorcatipovenda,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao :=517 ;


        end if;

        Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                      p_percomcli,
                                      p_considerarcomissaozero,
                                      p_codcli,
                                      p_codfilial,
                                      vnPerCom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 302;

        end if;

        Definir_Comissao_por_TERCEIRO(p_codprod,
                                      p_codcli,
                                      p_considerarcomissaozero,
                                      vnpercom_aux,
                                      vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := vncodcomiss;
          p_rotinacomissao := 3304;

        end if;

        if p_UsaPCComissaoFilial then

          Definir_Comissao_por_Filial(p_codfilial,
                                      p_ConsiderarComissaoZero,
                                      vnpercom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
            p_codcomissao := null ;
            p_rotinacomissao := 2110;

          end if;

        end if;

        Define_Comissao_Por_PCDesconto(p_coddesconto,
                                         p_tipovend,
                                         p_considerarcomissaozero,
                                         vnpercom_aux,
                                         p_perdesc,
                                         p_tabela,
                                         p_venda,
                                         p_numcasasdecvenda);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := p_coddesconto;
          p_rotinacomissao := 561;

        end if;

      end if;

      --Comissão por sobre posição
    elsif p_tipoavaliacaocomissao = 2 then

      SELECT count(*)
        into vicont
        FROM PCOrdemApuracaoComis
       WHERE CODFILIAL = p_CODFILIAL;

      if vicont <> 0 then

        SELECT count(*)
          into vicont
          FROM PCOrdemApuracaoComis
         WHERE CODFILIAL = p_CODFILIAL
           AND NVL(ORDEM, 0) = 0;

        if vicont <> 0 then

          if vsmensagem is null then
            vsmensagem := 'Ordem de validação das comissões está inválida! Verifique rotina 584.';
          else
            vsmensagem := vsmensagem||';'||'Ordem de validação das comissões está inválida! Verifique rotina 584.';

          end if;

        else

          for reg in (SELECT CODCOMIS, ORDEM
                        FROM PCOrdemApuracaoComis
                       WHERE CODFILIAL = p_CODFILIAL
                       ORDER BY ORDEM) loop

            if reg.codcomis = 1 then

              if p_utilizavendaporembalagem = 'S' then

                Definir_comissao_Por_Embalagem( p_tipovend,
                                                p_pcomint1_emb,
                                                P_PCOMEXT1_emb,
                                                P_PCOMREP1_emb,
                                                p_considerarcomissaozero,
                                                vnPerCom_aux);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := null;
                  p_rotinacomissao := 2014;

                end if;

              end if;

               if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then


                    Definir_Comissao_por_PCProdut(p_tipovend,
                                                  p_pcomint1,
                                                  P_PCOMEXT1,
                                                  P_PCOMREP1,
                                                  p_codprod,
                                                  p_codfilial,
                                                  p_considerarcomissaozero,
                                                  vnPerCom_aux);
                    if vnpercom_aux is not null then
                      vnpercom := vnpercom_aux;
                      p_codcomissao := null;
                      p_rotinacomissao := 203;

                    end if;

             end if;

            elsif reg.codcomis = 2 then
              Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                            p_percomcli,
                                            p_considerarcomissaozero,
                                            p_codcli,
                                            p_codfilial,
                                            vnPerCom_aux);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := null;
                p_rotinacomissao := 302;


              end if;

            elsif reg.codcomis = 3 then
              Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                            p_tipovenda,
                                            p_percent,
                                            P_PERCENT2,
                                            p_considerarcomissaozero,
                                            p_comissaorcatipovenda,
                                            vnPerCom_aux);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := null;
                p_rotinacomissao := 517;


              end if;

            elsif reg.codcomis = 4 then
              Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                            p_ConsiderarComissaoZero,
                                            p_codplpag,
                                            p_codlinhaprod,
                                            vnPerCom_aux);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := null;
                p_rotinacomissao := 558;


              end if;

            elsif reg.codcomis = 5 then

              if p_UsaPcTabComiss then
                Definir_Comissao_por_LUCRO(p_perluc,
                                           p_perdesc,
                                           p_tipovend,
                                           p_tipocomissao,
                                           p_ConsiderarComissaoZero,
                                           vnpercom_aux,
                                           vsletracomiss,
                                           vncodcomiss);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 550;

                end if;

              end if;

            elsif reg.codcomis = 6 then
              if p_UsaPcComissaoUsur then

                Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                             p_codusur,
                                             p_ConsiderarComissaoZero,
                                             p_codepto,
                                             p_codsec,
                                             p_codprod,
                                             vnpercom_aux,
                                             vsletracomiss,
                                             vncodcomiss,
                                             vsmensagem_comissaousur);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 553;

                end if;

                if vsmensagem_comissaousur is not null then

                  if vsmensagem is null then
                      vsmensagem := vsmensagem_comissaousur;
                  else
                      vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
                  end if;

                end if;


              end if;

            elsif reg.codcomis = 7 then
              if p_UsaPCComissaoPlPag then

                ValidarPCCOMISSAOPLPAG(p_tipovend,
                                       p_codplpag,
                                       p_perdesc,
                                       p_codprod,
                                       p_codepto,
                                       p_codsec,
                                       p_classeproduto,
                                       p_ConsiderarComissaoZero,
                                       vnpercom_aux,
                                       vsletracomiss,
                                       vncodcomiss,
                                       vsmensagem_comissaoplpag);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 583;

                end if;


                if vsmensagem_comissaoplpag is not null then

                  if vsmensagem is null then
                      vsmensagem := vsmensagem_comissaoplpag;
                  else
                      vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
                  end if;

                end if;


              end if;

            elsif reg.codcomis = 8 then
              if p_UsaPCComissaoRegiao then

                ValidarPCComissaoRegiao(p_numregiao,
                                        p_codfilial,
                                        p_perdesc,
                                        p_data,
                                        p_codprod,
                                        p_codsec,
                                        p_codepto,
                                        p_tipovend,
                                        p_ConsiderarComissaoZero,
                                        vnpercom_aux,
                                        vsletracomiss,
                                        vncodcomiss,
                                        vsmensagem_comissaoregiao);

                if vnpercom_aux is not null then
                  vnpercom := vnpercom_aux;
                  p_codcomissao := vncodcomiss;
                  p_rotinacomissao := 363;

                end if;

              if vsmensagem_comissaoregiao is not null then

                if vsmensagem is null then
                    vsmensagem := vsmensagem_comissaoregiao;
                else
                    vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
                end if;

              end if;

              end if;

            elsif reg.codcomis = 9 then

              Definir_Comissao_por_TERCEIRO(p_codprod,
                                            p_codcli,
                                            p_ConsiderarComissaoZero,
                                            vnpercom_aux,
                                            vncodcomiss);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := vncodcomiss;
                p_rotinacomissao := 3304;

              end if;

            elsif reg.codcomis = 10 then

              Define_Comissao_Por_PCDesconto(p_coddesconto,
                                             p_tipovend,
                                             p_considerarcomissaozero,
                                             vnpercom_aux,
                                             p_perdesc,
                                             p_tabela,
                                             p_venda,
                                             p_numcasasdecvenda);

              if vnpercom_aux is not null then
                vnpercom := vnpercom_aux;
                p_codcomissao := p_coddesconto;
                p_rotinacomissao := 561;

              end if;

            end if;
          end loop;
        end if;
      end if;

      if p_UsaPCComissaoFilial then

        Definir_Comissao_por_Filial(p_codfilial,
                                    p_ConsiderarComissaoZero,
                                    vnpercom_aux);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
          p_codcomissao := null;
          p_rotinacomissao := 2110;

        end if;

      end if;

      -- Menor valor de comissão
    elsif p_tipoavaliacaocomissao = 3 then

        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
          end if;

          vnPerCom_Menor := vnPerCom;
          vncodcomissao_menor := null;
          vnrotinacomissao_menor := 2014;


        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then


          Definir_Comissao_por_PCProdut(p_tipovend,
                                        p_pcomint1,
                                        P_PCOMEXT1,
                                        P_PCOMREP1,
                                        p_codprod,
                                        p_codfilial,
                                        p_considerarcomissaozero,
                                        vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
          end if;

          vnPerCom_Menor := vnPerCom;
          vncodcomissao_menor := null;
          vnrotinacomissao_menor := 203;

      end if;


      Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                    p_percomcli,
                                    p_considerarcomissaozero,
                                    p_codcli,
                                    p_codfilial,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
     end if;

      if (vnPerCom_Menor > vnPerCom) or vnpercom_menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 302;

      end if;

      Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                    p_tipovenda,
                                    p_percent,
                                    P_PERCENT2,
                                    p_considerarcomissaozero,
                                    p_comissaorcatipovenda,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
         vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 517;

      end if;

      Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                    p_ConsiderarComissaoZero,
                                    p_codplpag,
                                    p_codlinhaprod,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 558;

      end if;

      if p_UsaPcTabComiss then
        Definir_Comissao_por_LUCRO(p_perluc,
                                   p_perdesc,
                                   p_tipovend,
                                   p_tipocomissao,
                                   p_ConsiderarComissaoZero,
                                   vnpercom_aux,
                                   vsletracomiss,
                                   vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;

        end if;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 550;

      end if;

      if p_UsaPcComissaoUsur then
        Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                     p_codusur,
                                     p_ConsiderarComissaoZero,
                                     p_codepto,
                                     p_codsec,
                                     p_codprod,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss,
                                     vsmensagem_comissaousur);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;

        end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;



      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 553;

      end if;

      if p_UsaPCComissaoPlPag then
        ValidarPCCOMISSAOPLPAG(p_tipovend,
                               p_codplpag,
                               p_perdesc,
                               p_codprod,
                               p_codepto,
                               p_codsec,
                               p_classeproduto,
                               p_ConsiderarComissaoZero,
                               vnpercom_aux,
                               vsletracomiss,
                               vncodcomiss,
                               vsmensagem_comissaoplpag);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 583;

      end if;

      if p_UsaPCComissaoRegiao then
        ValidarPCComissaoRegiao(p_numregiao,
                                p_codfilial,
                                p_perdesc,
                                p_data,
                                p_codprod,
                                p_codsec,
                                p_codepto,
                                p_tipovend,
                                p_ConsiderarComissaoZero,
                                vnpercom_aux,
                                vsletracomiss,
                                vncodcomiss,
                                vsmensagem_comissaoregiao);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;

        end if;

         if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 363;

      end if;

      Definir_Comissao_por_TERCEIRO(p_codprod,
                                    p_codcli,
                                    p_ConsiderarComissaoZero,
                                    vnpercom_aux,
                                    vncodcomiss);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := vncodcomiss;
        vnrotinacomissao_menor := 3304;

      end if;

      Definir_Comissao_por_Filial(p_codfilial,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := null;
        vnrotinacomissao_menor := 2110;

      end if;

      Define_Comissao_Por_PCDesconto(p_coddesconto,
                                     p_tipovend,
                                     p_considerarcomissaozero,
                                     vnpercom_aux,
                                     p_perdesc,
                                     p_tabela,
                                     p_venda,
                                     p_numcasasdecvenda);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;

      end if;

      if (vnPerCom_Menor > vnPerCom) or vnperCom_Menor is null then
        vnPerCom_Menor := vnPerCom;
        vncodcomissao_menor := p_coddesconto;
        vnrotinacomissao_menor := 561;

      end if;

      -- Atribuindo a menor comissão para a variável que será retornada para o Result
      vnPerCom := vnPerCom_Menor;
       p_codcomissao :=  vncodcomissao_menor;
       p_rotinacomissao := vnrotinacomissao_menor;


      -- Maior valor de comissão
    elsif p_tipoavaliacaocomissao = 4 then

        if p_utilizavendaporembalagem = 'S' then

          Definir_comissao_Por_Embalagem( p_tipovend,
                                          p_pcomint1_emb,
                                          P_PCOMEXT1_emb,
                                          P_PCOMREP1_emb,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

          if vnpercom_aux is not null then
            vnpercom := vnpercom_aux;
          end if;

            vnPerCom_Maior := vnPerCom;
            vncodcomissao_maior := null;
            vnrotinacomissao_maior := 2014;


        end if;

       if p_utilizavendaporembalagem = 'N' or (p_utilizavendaporembalagem = 'S' and p_rotinacomissao <> 2014 or p_rotinacomissao is null) then


            Definir_Comissao_por_PCProdut(p_tipovend,
                                          p_pcomint1,
                                          P_PCOMEXT1,
                                          P_PCOMREP1,
                                          p_codprod,
                                          p_codfilial,
                                          p_considerarcomissaozero,
                                          vnPerCom_aux);

            if vnpercom_aux is not null then
              vnpercom := vnpercom_aux;
            end if;

            vnPerCom_Maior := vnPerCom;
            vncodcomissao_maior := null;
            vnrotinacomissao_maior := 203;

      end if;

      Definir_Comissao_por_PCClient(p_usacomissaoporcliente,
                                    p_percomcli,
                                    p_considerarcomissaozero,
                                    p_codcli,
                                    p_codfilial,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 302;

      end if;

      Definir_Comissao_por_PCUsuari(p_usacomissaoporrca,
                                    p_tipovenda,
                                    p_percent,
                                    P_PERCENT2,
                                    p_considerarcomissaozero,
                                    p_comissaorcatipovenda,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 517;

      end if;

      Definir_Comissao_por_PCPLPAGI(p_USACOMISSAOPORLINHAPROD,
                                    p_ConsiderarComissaoZero,
                                    p_codplpag,
                                    p_codlinhaprod,
                                    vnPerCom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 558;

      end if;

      if p_UsaPcTabComiss then

        Definir_Comissao_por_LUCRO(p_perluc,
                                   p_perdesc,
                                   p_tipovend,
                                   p_tipocomissao,
                                   p_ConsiderarComissaoZero,
                                   vnpercom_aux,
                                   vsletracomiss,
                                   vncodcomiss);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 550;

      end if;

      if p_UsaPcComissaoUsur then

        Definir_Comis_PCCOMISSAOUSUR(p_perdesc,
                                     p_codusur,
                                     p_ConsiderarComissaoZero,
                                       p_codepto,
                                       p_codsec,
                                       p_codprod,
                                     vnpercom_aux,
                                     vsletracomiss,
                                     vncodcomiss,
                                     vsmensagem_comissaousur);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaousur is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaousur;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaousur;
            end if;

          end if;


      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 553;

      end if;

      if p_UsaPCComissaoPlPag then

        ValidarPCCOMISSAOPLPAG(p_tipovend,
                               p_codplpag,
                               p_perdesc,
                               p_codprod,
                               p_codepto,
                               p_codsec,
                               p_classeproduto,
                               p_ConsiderarComissaoZero,
                               vnpercom_aux,
                               vsletracomiss,
                               vncodcomiss,
                               vsmensagem_comissaoplpag);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaoplpag is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoplpag;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoplpag;
            end if;

          end if;


      end if;



      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 583;

      end if;

      if p_UsaPCComissaoRegiao then
        ValidarPCComissaoRegiao(p_numregiao,
                                p_codfilial,
                                p_perdesc,
                                p_data,
                                p_codprod,
                                p_codsec,
                                p_codepto,
                                p_tipovend,
                                p_ConsiderarComissaoZero,
                                vnpercom_aux,
                                vsletracomiss,
                                vncodcomiss,
                                vsmensagem_comissaoregiao);

        if vnpercom_aux is not null then
          vnpercom := vnpercom_aux;
        end if;

          if vsmensagem_comissaoregiao is not null then

            if vsmensagem is null then
                vsmensagem := vsmensagem_comissaoregiao;
            else
                vsmensagem := vsmensagem ||';'||vsmensagem_comissaoregiao;
            end if;

          end if;

      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := vncodcomiss;
        vnrotinacomissao_maior := 363;

      end if;

      Definir_Comissao_por_TERCEIRO(p_codprod,
                                    p_codcli,
                                    p_ConsiderarComissaoZero,
                                    vnpercom_aux,
                                    vncodcomiss);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
         vnPerCom_Maior := vnPerCom;
         vncodcomissao_maior := vncodcomiss;
         vnrotinacomissao_maior := 3304;

      end if;

      Definir_Comissao_por_Filial(p_codfilial,
                                  p_ConsiderarComissaoZero,
                                  vnpercom_aux);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := null;
        vnrotinacomissao_maior := 2110;

      end if;

      Define_Comissao_Por_PCDesconto(p_coddesconto,
                                     p_tipovend,
                                     p_considerarcomissaozero,
                                     vnpercom_aux,
                                     p_perdesc,
                                     p_tabela,
                                     p_venda,
                                     p_numcasasdecvenda);

      if vnpercom_aux is not null then
        vnpercom := vnpercom_aux;
      end if;

      if (vnPerCom > vnPerCom_Maior) or vnpercom_maior is null then
        vnPerCom_Maior := vnPerCom;
        vncodcomissao_maior := p_coddesconto;
        vnrotinacomissao_maior := 561;

      end if;

      -- Atribuindo a menor comissão para a variável que será retornada para o Result
      vnPerCom         := vnPerCom_Maior;
      p_codcomissao    :=  vncodcomissao_maior ;
      p_rotinacomissao := vnrotinacomissao_maior  ;


    end if;

    p_letracomiss := vsletracomiss;

    if vnpercom is null then

      vnpercom := 0;
      p_codcomissao := null;
      p_rotinacomissao := null;
    end if;

    p_mensagem := vsmensagem;

    return vnPerCom;

  exception
    when others then

     if vsmensagem is null then
         vsmensagem := 'Erro ao calcular comissao : ' || SQLCODE || ' ' || SQLERRM;
     else
         vsmensagem := vsmensagem||';'||'Erro ao calcular comissao : ' || SQLCODE || ' ' || SQLERRM;
     end if;

     p_mensagem := vsmensagem;

  end;

--possui verificação do simplenacional, retorna percentual de base deb/cred de rca, retorna altera ptabela,politica prioritaria
  FUNCTION validarpoliticasdesconto -- 28 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_numdias                  in NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_param1                   IN number,
   p_param2                   IN number,
   p_codpolbaserca            out number,
   p_tipo                     in varchar2 default null
) RETURN BOOLEAN IS

    CURSOR c_semrede(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number) IS
      SELECT pcdesconto.percdesc,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             nvl(pcdesconto.prioritariageral,'N') prioritariageral
        FROM pcdesconto,pcplpag
       WHERE p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'N'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codcli = p_codcli) OR (pcdesconto.codcli IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND ((pcdesconto.codprodprinc = p_codprodprinc) OR (pcdesconto.codprodprinc IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(percdesc, 0) > 0)
         AND (nvl(pcdesconto.tipo,'C') = COALESCE(P_TIPO, pcdesconto.tipo,'C'))
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
       ORDER BY pcdesconto.percdesc DESC;

    CURSOR c_semrede_cr(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                        vncodrede IN number , vncodmarca IN number) IS
      SELECT pcdesconto.percdesc,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(pcdesconto.creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             nvl(pcdesconto.prioritariageral,'N') prioritariageral
        FROM pcdesconto,pcplpag
       WHERE p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'N'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codcli = p_codcli) OR (pcdesconto.codcli IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND ((pcdesconto.codprodprinc = p_codprodprinc) OR (pcdesconto.codprodprinc IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(percdesc, 0) < 0)
         AND (nvl(pcdesconto.tipo,'C') = COALESCE(P_TIPO, pcdesconto.tipo,'C'))
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')

       ORDER BY pcdesconto.percdesc DESC;

    CURSOR c_comrede(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vncodcliprinc IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number) IS
      SELECT pcdesconto.percdesc,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(pcdesconto.creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             nvl(pcdesconto.prioritariageral,'N') prioritariageral
        FROM pcdesconto,pcplpag
       WHERE pcdesconto.codcli = vncodcliprinc
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'S'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND (nvl(percdesc, 0) > 0)
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(pcdesconto.tipo,'C') = COALESCE(P_TIPO, pcdesconto.tipo,'C'))
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T');

    CURSOR c_comrede_cr(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vncodcliprinc IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                        vncodrede IN number , vncodmarca IN number) IS
      SELECT pcdesconto.percdesc,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(pcdesconto.creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             nvl(pcdesconto.prioritariageral,'N') prioritariageral
        FROM pcdesconto,pcplpag
       WHERE codcli = vncodcliprinc
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(utilizadescrede, 'N') = 'S'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(percdesc, 0) < 0)
         AND (nvl(pcdesconto.tipo,'C') = COALESCE(P_TIPO, pcdesconto.tipo,'C'))
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T');

    vbresult             BOOLEAN;
    vntempperdesc        NUMBER;
    vstempbasecreddebrca VARCHAR2(2);
    vnpercdesc           NUMBER;
    vsbasecreddebrca     VARCHAR2(2);
    vbresult_cr          BOOLEAN;
    vntempperdesc_cr     NUMBER;
    vnpercdesc_cr        NUMBER;
    --Dados do Cliente
    vncodcliprinc NUMBER;
    vncodatv1     NUMBER;
    vncodpraca    NUMBER;
    --Dados do RCA
    vncodsupervisor NUMBER;
    --Dados do Produto}
    vncodfornec                NUMBER;
    vncodepto                  NUMBER;
    vncodsec                   NUMBER;
    vncodcategoria             NUMBER;
    vncodsubcategoria          NUMBER;
    vicont                     NUMBER;
    vicont2                    NUMBER;
    vicont3                    NUMBER;
    vicontador                 NUMBER;
    vicontador2                NUMBER;
    vsaplicadesconto           VARCHAR2(1);
    vscreditasobrepolitica     VARCHAR2(1);
    vstempcreditasobrepolitica VARCHAR2(1);
    vsareaatuacao              pcusuari.areaatuacao%type;
    vnpercbaserca              number;
    vntemppbaserca             number;
    vssimplesnacional          pcclient.simplesnacional%type;
    vsalteraptabela            varchar2(1);
    vstempalteraptabela        varchar2(1);

    vncodrede                  pcclient.codrede%type;
    vncodmarca                 pcprodut.codmarca%type;

    vstempprioritaria          varchar2(1);
    vsprioritaria              varchar2(1);
    vsquestionaprioritaria     varchar2(1);
    vstempquestionaprioritaria varchar2(1);
    vsusaprioritaria           varchar2(1);
    vsprioritariageral         varchar2(1);
    vstempprioritariageral     varchar2(1);

    vncodpoldescbaserca        pcdesconto.coddesconto%type;


  BEGIN
    vbresult      := FALSE;
    vnpercdesc    := 0;
    vnpercbaserca := 0;
    --    vnpercdesc_cr          := 0;
    vsbasecreddebrca       := 'N';
    vscreditasobrepolitica := 'S';
    vsalteraptabela        := 'N';
    vsprioritaria          := 'N';
    vsusaprioritaria       := p_mensagem;

    vsprioritariageral     := 'N';
    vncodpoldescbaserca    := null;

    IF p_aplicadesconto = 0 THEN
      vsaplicadesconto := 'N';
    ELSE
      vsaplicadesconto := 'S';
    END IF;
    --Buscar dados do cliente
    SELECT COUNT(*) INTO vicont FROM pcclient WHERE codcli = p_codcli;
    IF vicont <> 0 THEN
      SELECT nvl(codcliprinc, codcli) codcliprinc,
             codatv1,
             codpraca,
             pcclient.simplesnacional,
             pcclient.codrede
        INTO vncodcliprinc, vncodatv1, vncodpraca, vssimplesnacional,vncodrede
        FROM pcclient
       WHERE codcli = p_codcli;

      --Buscar dados do RCA
      SELECT COUNT(*) INTO vicont2 FROM pcusuari WHERE codusur = p_codusur;
      IF vicont2 <> 0 THEN
        SELECT codsupervisor, pcusuari.areaatuacao
          INTO vncodsupervisor, vsareaatuacao
          FROM pcusuari
         WHERE codusur = p_codusur;
        --Buscar dados do produto
        SELECT COUNT(*)
          INTO vicont3
          FROM pcprodut
         WHERE codprod = p_codprod;
        IF vicont3 <> 0 THEN
          SELECT codfornec, codepto, codsec, codcategoria, codsubcategoria,codmarca
            INTO vncodfornec,
                 vncodepto,
                 vncodsec,
                 vncodcategoria,
                 vncodsubcategoria,
                 vncodmarca
            FROM pcprodut
           WHERE codprod = p_codprod;
          --Verificação de Políticas de Descontos}
          FOR reg_semrede IN c_semrede(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca) LOOP
            IF (p_tratarrestricaoacrescimo = 'S' AND
               reg_semrede.percdesc >= 0) OR
               p_tratarrestricaoacrescimo = 'N' THEN
              vbresult                   := TRUE;
              vntempperdesc              := reg_semrede.percdesc;
              vntemppbaserca             := reg_semrede.percdesc;
              vstempbasecreddebrca       := reg_semrede.basecreddebrca;
              vstempcreditasobrepolitica := reg_semrede.creditasobrepolitica;
              vstempalteraptabela        := reg_semrede.alteraptabela;
              vstempprioritaria          := reg_semrede.prioritaria;
              vstempquestionaprioritaria := reg_semrede.questionausoprioritaria;
              vstempprioritariageral     := reg_semrede.prioritariageral;


              if vsprioritariageral = 'N' and vstempprioritariageral = 'S' then

                 vsprioritariageral := 'S';

                 vnpercdesc             := vntempperdesc;
                 vsprioritaria          := vstempprioritaria;
                 vsquestionaprioritaria := vstempquestionaprioritaria;
                 vsalteraptabela        := vstempalteraptabela;


                 p_mensagem := to_char(reg_semrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_semrede.coddesconto;

                  p_dtfim := reg_semrede.dtfim ;


                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                      vsbasecreddebrca       := vstempbasecreddebrca;
                      vnpercbaserca          := vntemppbaserca;
                      vscreditasobrepolitica := vstempcreditasobrepolitica;
                    vncodpoldescbaserca    := reg_semrede.coddesconto;

                end if;


              end if;

             if vsprioritariageral = 'N' then--só verifica outras politicas se a encontrada não for prioritaria geral

              if vsprioritaria = 'N' then

                if vstempprioritaria = 'S' then
                  --registro atual é de politica prioritaria

                  if vsusaprioritaria = 'S' then


                    vnpercdesc             := vntempperdesc;
                    vsprioritaria          := vstempprioritaria;
                    vsquestionaprioritaria := vstempquestionaprioritaria;
                    vsalteraptabela        := vstempalteraptabela;


                    p_mensagem := to_char(reg_semrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_semrede.coddesconto;


                    p_dtfim := reg_semrede.dtfim ;

                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_semrede.coddesconto;

                     end if;


                  end if;



                else
                  --registro atual não é de politica prioritaria

                  IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc := vntempperdesc;
                        vsprioritaria          := 'N';
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_semrede.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_semrede.coddesconto;


                        p_dtfim := reg_semrede.dtfim ;

                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_semrede.coddesconto;

                        end if;



                  END IF;

                        if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' and
                           vntemppbaserca > vnpercbaserca then

                            vsbasecreddebrca       := vstempbasecreddebrca;
                            vnpercbaserca          := vntemppbaserca;
                            vscreditasobrepolitica := vstempcreditasobrepolitica;
                      vncodpoldescbaserca    := reg_semrede.coddesconto;

                  end if;



                end if;

              else
                -- já tem uma politica prioritaria

                      IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc             := vntempperdesc;
                        vsprioritaria          := vstempprioritaria;
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_semrede.dtinicio, 'dd/mm/yyyy') || ',' ||
                                      reg_semrede.coddesconto;

                        p_dtfim := reg_semrede.dtfim ;

                              if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_semrede.coddesconto;

                                end if;



                      END IF;

              end if;
             end if;
            END IF;
          END LOOP;

          FOR reg_comrede IN c_comrede(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vncodcliprinc,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca) LOOP
            IF (p_tratarrestricaoacrescimo = 'S' AND
               reg_comrede.percdesc > 0) OR
               p_tratarrestricaoacrescimo = 'N' THEN
              vbresult                   := TRUE;
              vntempperdesc              := reg_comrede.percdesc;
              vntemppbaserca             := reg_comrede.percdesc;
              vstempbasecreddebrca       := reg_comrede.basecreddebrca;
              vstempcreditasobrepolitica := reg_comrede.creditasobrepolitica;
              vstempalteraptabela        := reg_comrede.alteraptabela;

              vstempprioritaria          := reg_comrede.prioritaria;
              vstempquestionaprioritaria := reg_comrede.questionausoprioritaria;
              vstempprioritariageral     := reg_comrede.prioritariageral;


              if vsprioritariageral = 'N' and vstempprioritariageral = 'S' then

                 vsprioritariageral := 'S';

                 vnpercdesc             := vntempperdesc;
                 vsprioritaria          := vstempprioritaria;
                 vsquestionaprioritaria := vstempquestionaprioritaria;
                 vsalteraptabela        := vstempalteraptabela;


                 p_mensagem := to_char(reg_comrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_comrede.coddesconto;

                  p_dtfim := reg_comrede.dtfim ;


                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                      vsbasecreddebrca       := vstempbasecreddebrca;
                      vnpercbaserca          := vntemppbaserca;
                      vscreditasobrepolitica := vstempcreditasobrepolitica;
                    vncodpoldescbaserca    := reg_comrede.coddesconto;

                end if;


              end if;

             if vsprioritariageral = 'N' then--só verifica outras politicas se a encontrada não for prioritaria geral

              if vsprioritaria = 'N' then

                if vstempprioritaria = 'S' then
                  --registro atual é de politica prioritaria

                  if vsusaprioritaria = 'S' then


                    vnpercdesc             := vntempperdesc;
                    vsprioritaria          := vstempprioritaria;
                    vsquestionaprioritaria := vstempquestionaprioritaria;
                    vsalteraptabela        := vstempalteraptabela;


                    p_mensagem := to_char(reg_comrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_comrede.coddesconto;

                    p_dtfim := reg_comrede.dtfim ;

                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                                end if;


                  end if;



                else
                  --registro atual não é de politica prioritaria

                  IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc := vntempperdesc;
                        vsprioritaria          := 'N';
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_comrede.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_comrede.coddesconto;

                        p_dtfim := reg_comrede.dtfim ;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                        end if;



                  END IF;

                        if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' and
                           vntemppbaserca > vnpercbaserca then

                            vsbasecreddebrca       := vstempbasecreddebrca;
                            vnpercbaserca          := vntemppbaserca;
                            vscreditasobrepolitica := vstempcreditasobrepolitica;
                      vncodpoldescbaserca    := reg_comrede.coddesconto;

                        end if;

                end if;

              else
                -- já tem uma politica prioritaria

                      IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc             := vntempperdesc;
                        vsprioritaria          := vstempprioritaria;
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_comrede.dtinicio, 'dd/mm/yyyy') || ',' ||
                                      reg_comrede.coddesconto;

                        p_dtfim := reg_comrede.dtfim ;

                              if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                            end if;



                      END IF;

              end if;

            end if;

            END IF;
          END LOOP;

          FOR reg_semrede_cr IN c_semrede_cr(vncodepto,
                                             vncodsec,
                                             vncodcategoria,
                                             vncodfornec,
                                             vncodsupervisor,
                                             vncodatv1,
                                             vncodpraca,
                                             vsaplicadesconto,
                                             vsareaatuacao,
                                             vssimplesnacional,
                                             vncodrede,
                                             vncodmarca) LOOP

            IF p_tratarrestricaoacrescimo = 'S' then

              vbresult_cr                := TRUE;
              vntempperdesc_cr           := reg_semrede_cr.percdesc;
              vntemppbaserca             := reg_semrede_cr.percdesc;
              vstempbasecreddebrca       := reg_semrede_cr.basecreddebrca;
              vstempcreditasobrepolitica := reg_semrede_cr.creditasobrepolitica;
              vstempalteraptabela        := reg_semrede_cr.alteraptabela;

              IF vntempperdesc_cr < nvl(vnpercdesc_cr, 0) THEN
                vnpercdesc_cr := vntempperdesc_cr;
                vsalteraptabela        := vstempalteraptabela;

                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                    vsbasecreddebrca       := vstempbasecreddebrca;
                    vnpercbaserca          := vntemppbaserca;
                    vscreditasobrepolitica := vstempcreditasobrepolitica;
                    vncodpoldescbaserca    := reg_semrede_cr.coddesconto;


                end if;


              END IF;

               if vstempbasecreddebrca = 'S' and  nvl(p_naousarautdebcredpoldesc,'N') = 'N' and
                 vntemppbaserca < vnpercbaserca then
                vsbasecreddebrca       := vstempbasecreddebrca;
                vnpercbaserca          := vntemppbaserca;
                vscreditasobrepolitica := vstempcreditasobrepolitica;
                vncodpoldescbaserca    := reg_semrede_cr.coddesconto;

              end if;

            END IF;
          END LOOP;

          FOR reg_comrede_cr IN c_comrede_cr(vncodepto,
                                             vncodsec,
                                             vncodcategoria,
                                             vncodfornec,
                                             vncodsupervisor,
                                             vncodatv1,
                                             vncodpraca,
                                             vncodcliprinc,
                                             vsaplicadesconto,
                                             vsareaatuacao,
                                             vssimplesnacional,
                                             vncodrede,
                                             vncodmarca) LOOP

            IF p_tratarrestricaoacrescimo = 'S' then

              vbresult                   := TRUE;
              vntempperdesc_cr           := reg_comrede_cr.percdesc;
              vntemppbaserca             := reg_comrede_cr.percdesc;
              vstempbasecreddebrca       := reg_comrede_cr.basecreddebrca;
              vstempcreditasobrepolitica := reg_comrede_cr.creditasobrepolitica;
              vstempalteraptabela        := reg_comrede_cr.alteraptabela;

              IF vntempperdesc_cr < nvl(vnpercdesc_cr, 0) THEN
                vnpercdesc_cr := vntempperdesc_cr;
                vsalteraptabela        := vstempalteraptabela;

                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                    vsbasecreddebrca       := vstempbasecreddebrca;
                    vnpercbaserca          := vntemppbaserca;
                    vscreditasobrepolitica := vstempcreditasobrepolitica;
                    vncodpoldescbaserca    := reg_comrede_cr.coddesconto;


                end if;


              END IF;

               if vstempbasecreddebrca = 'S' and  nvl(p_naousarautdebcredpoldesc,'N') = 'N' and
                 vntemppbaserca < vnpercbaserca then
                vsbasecreddebrca       := vstempbasecreddebrca;
                vnpercbaserca          := vntemppbaserca;
                vscreditasobrepolitica := vstempcreditasobrepolitica;
                 vncodpoldescbaserca    := reg_comrede_cr.coddesconto;

              end if;
            END IF;

          END LOOP;
        ELSE
          p_mensagem := 'Não foi possível buscar dados do PCPRODUT!';
        END IF;
      ELSE
        p_mensagem := 'Não foi possível buscar dados do PCUSUARI!';
      END IF; --dados do PCCLIENT
    ELSE
      p_mensagem := 'Não foi possível buscar dados do PCCLIENT!';
    END IF;

    p_perdescrestricao := (round(vnpercdesc_cr, p_numcasasdecvenda)) * -1;

    p_perdesc              := round(vnpercdesc, p_numcasasdecvenda);
    p_basecreddebrca       := vsbasecreddebrca;
    p_creditasobrepolitica := vscreditasobrepolitica;
    p_pbaserca             := round(vnpercbaserca, p_numcasasdecvenda);
    p_alteraptabela        := vsalteraptabela;

    p_prioritaria             := nvl(vsprioritaria, 'N');
    p_questionausoprioritaria := nvl(vsquestionaprioritaria, 'N');

    p_codpolbaserca         :=  vncodpoldescbaserca ;


    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END validarpoliticasdesconto;

-- Tarefa 1612.064252.2014
  --Tem retorno do percetual de deb/cred de rca e prioritaria
  FUNCTION validardescontoquantidade -- 26 parametros
  (P_TIPOTESTE            IN NUMBER,
   P_CODPROD              IN NUMBER,
   P_QTDE                 IN NUMBER,
   P_NUMREGIAO            IN NUMBER,
   P_PTABELA              IN NUMBER,
   P_PVENDA1              IN NUMBER,
   P_CODPRACA             IN NUMBER,
   P_NUMCASASDECVENDA     IN NUMBER,
   P_NUMDIAS              IN NUMBER,
   P_TIPODESCONTO         IN VARCHAR2,
   P_CODPRODPRINC         IN NUMBER,
   P_CODCLI               IN NUMBER,
   P_CODUSUR              IN NUMBER,
   P_DTFIM                OUT DATE,
   P_MENSAGEM             IN OUT VARCHAR2,
   P_PTABELADESC          OUT NUMBER,
   P_CREDITASOBREPTABELA  OUT VARCHAR2,
   P_PERDESCFLEX          OUT NUMBER,
   P_BASEDEBCREDRCA       OUT VARCHAR2,
   P_PERCBASERCA          OUT NUMBER,
   P_PRIORITARIA          OUT VARCHAR2,
   P_QUESTIONAPRIORITARIA OUT VARCHAR2,
   P_CODFILIAL            IN VARCHAR2 DEFAULT ' ',
   P_CODPOLPBASERCA       OUT NUMBER,
   P_CODDESCONTO          OUT NUMBER,
   P_APENASVALIDA         IN VARCHAR2 DEFAULT 'N') RETURN BOOLEAN IS

    VBRESULT         BOOLEAN;
    VNPERCDESC       NUMBER;
    VNPERDESCTEMP    NUMBER;
    VNPERDESCMAX     NUMBER;
    VNPERDESCMAXTEMP NUMBER;
    VNPTABELA        NUMBER;

    VNPTABELA_QUANTMAX         NUMBER;
    VNPTABELA_QUANT            NUMBER;
    VSCREDITASOBREPTABELA      VARCHAR2(1);
    VSCREDITASOBREPTABELATEMP  VARCHAR2(1);
    VDDTINICIO                 DATE;
    VDDTFIM                    DATE;
    VNINICIOINTERVALO          NUMBER;
    VNFIMINTERVALO             NUMBER;
    VSBASECREDDEBRCA           PCDESCQUANT.BASECREDDEBRCA%TYPE;
    VSBASECREDDEBRCATEMP       PCDESCQUANT.BASECREDDEBRCA%TYPE;
    VNPERCBASERCA              NUMBER;
    VNPERCBASERCATEMP          NUMBER;
    VSPRIORITARIA              PCDESCQUANT.PRIORITARIA%TYPE;
    VSQUESTIONAPRIORITARIA     PCDESCQUANT.QUESTIONAUSOPRIORITARIA%TYPE;
    VSTEMPPRIORITARIA          PCDESCQUANT.PRIORITARIA%TYPE;
    VSTEMPQUESTIONAPRIORITARIA PCDESCQUANT.QUESTIONAUSOPRIORITARIA%TYPE;
    VSUSAPRIORITARIA           VARCHAR2(1);
    VSCLASSEVENDA              PCCLIENT.CLASSEVENDA%TYPE;
    VNCODPOLBASERCA            PCDESCONTO.CODDESCONTO%TYPE;
    VNCODDESCONTO              PCDESCONTO.CODDESCONTO%TYPE;

  BEGIN
    --Quando o tipo de teste for:
    --0 -> verifica a quantidade
    --1 -> não verifica a quantidade

    VBRESULT         := FALSE;
    VNPTABELA        := P_PTABELA;
    VNPERCDESC       := NULL;
    VNPERCBASERCA    := NULL;
    VSPRIORITARIA    := 'N';
    VSUSAPRIORITARIA := P_MENSAGEM;

    P_MENSAGEM    := NULL;
    VSCLASSEVENDA := NULL;

    IF P_CODCLI IS NOT NULL THEN

      SELECT PCCLIENT.CLASSEVENDA
        INTO VSCLASSEVENDA
        FROM PCCLIENT
       WHERE CODCLI = P_CODCLI;
    END IF;

    IF P_TIPOTESTE <> 1 THEN

      FOR REG IN (SELECT PCDESCQUANT.PERCDESC,
                         PCDESCQUANT.DTFIM,
                         PCDESCQUANT.PERDESCMAX,
                         PCDESCQUANT.CREDITASOBREPTABELA,
                         PCDESCQUANT.DTINICIO,
                         PCDESCQUANT.INICIOINTERVALO,
                         PCDESCQUANT.FIMINTERVALO,
                         NVL(PCDESCQUANT.BASECREDDEBRCA, 'N') BASECREDDEBRCA,
                         PCDESCQUANT.PRIORITARIA,
                         PCDESCQUANT.QUESTIONAUSOPRIORITARIA,
                         PCDESCQUANT.CODDESCONTO
                    FROM PCDESCQUANT, PCPLPAG
                   WHERE PCDESCQUANT.CODPROD =
                         DECODE(PCDESCQUANT.APLICAFAMILIAPRODUTOS,
                                'S',
                                P_CODPRODPRINC,
                                P_CODPROD)
                     AND PCDESCQUANT.CODPLPAGMAX = PCPLPAG.CODPLPAG(+)
                     AND DECODE(PCDESCQUANT.CODPLPAGMAX,
                                NULL,
                                P_NUMDIAS,
                                PCPLPAG.NUMDIAS) >= P_NUMDIAS
                     AND PCDESCQUANT.INICIOINTERVALO <= P_QTDE
                     AND PCDESCQUANT.FIMINTERVALO >= P_QTDE
                     AND ((PCDESCQUANT.NUMREGIAO = P_NUMREGIAO) OR
                         (PCDESCQUANT.NUMREGIAO IS NULL))
                     AND ((PCDESCQUANT.CODPRACA = P_CODPRACA) OR
                         (PCDESCQUANT.CODPRACA IS NULL))
                     AND ((TRUNC(SYSDATE) BETWEEN PCDESCQUANT.DTINICIO AND
                         PCDESCQUANT.DTFIM) OR ((PCDESCQUANT.DTINICIO IS NULL) AND
                         (PCDESCQUANT.DTFIM IS NULL)))
                     AND NVL(PCDESCQUANT.TIPODESCONTO, 'A') = P_TIPODESCONTO
                     AND (((PCDESCQUANT.CODGRUPOREST IS NULL) OR
                         (PCDESCQUANT.TIPOGRUPOREST IS NULL)) OR
                         ((PCDESCQUANT.CODGRUPOREST = CASE
                          WHEN(PCDESCQUANT.TIPOGRUPOREST = 'GR') OR
                          (PCDESCQUANT.TIPOGRUPOREST = 'CL') THEN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                               FROM PCGRUPOSCAMPANHAI, PCGRUPOSCAMPANHAC
                              WHERE PCGRUPOSCAMPANHAC.CODGRUPO =
                                    PCGRUPOSCAMPANHAI.CODGRUPO
                                AND PCGRUPOSCAMPANHAC.DTEXCLUSAO IS NULL
                                AND (PCGRUPOSCAMPANHAC.CODFILIAL IS NULL OR
                                    PCGRUPOSCAMPANHAC.CODFILIAL = P_CODFILIAL)
                                AND PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                AND PCGRUPOSCAMPANHAI.CODGRUPO =
                                    PCDESCQUANT.CODGRUPOREST
                                AND PCGRUPOSCAMPANHAI.CODITEM =
                                    DECODE(TIPOGRUPOREST,
                                           'CL',
                                           P_CODCLI,
                                           'GR',
                                           P_CODUSUR)
                                AND ROWNUM = 1) ELSE 0 END)))
                     AND (PCDESCQUANT.CLASSEVENDA = VSCLASSEVENDA OR
                         PCDESCQUANT.CLASSEVENDA IS NULL)
                     AND (PCDESCQUANT.CODFILIAL = P_CODFILIAL OR
                         PCDESCQUANT.CODFILIAL IS NULL OR
                         PCDESCQUANT.CODFILIAL = '99')

                   ORDER BY PCDESCQUANT.PERCDESC) LOOP

        VBRESULT                   := TRUE;
        VNPERDESCTEMP              := REG.PERCDESC;
        VSBASECREDDEBRCATEMP       := REG.BASECREDDEBRCA;
        VSCREDITASOBREPTABELATEMP  := REG.CREDITASOBREPTABELA;
        VNPERCBASERCATEMP          := REG.PERCDESC;
        VSTEMPPRIORITARIA          := REG.PRIORITARIA;
        VSTEMPQUESTIONAPRIORITARIA := REG.QUESTIONAUSOPRIORITARIA;

        IF VNPERDESCTEMP < 0 THEN
          --desconto

          IF VSPRIORITARIA = 'N' THEN

            IF VSTEMPPRIORITARIA = 'S' THEN
              --registro atual é de politica prioritaria

              IF VSUSAPRIORITARIA = 'S' THEN

                VNPERCDESC             := VNPERDESCTEMP;
                VDDTINICIO             := REG.DTINICIO;
                VDDTFIM                := REG.DTFIM;
                VNINICIOINTERVALO      := REG.INICIOINTERVALO;
                VNFIMINTERVALO         := REG.FIMINTERVALO;
                VNPERDESCMAX           := REG.PERDESCMAX;
                VSPRIORITARIA          := REG.PRIORITARIA;
                VSQUESTIONAPRIORITARIA := REG.QUESTIONAUSOPRIORITARIA;
                VNCODDESCONTO          := REG.CODDESCONTO;



              END IF;

              IF VSBASECREDDEBRCATEMP = 'S' THEN
                  VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
                  VNPERCBASERCA         := VNPERCBASERCATEMP;
                  VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
                  VNCODPOLBASERCA       := REG.CODDESCONTO;
                END IF;

              VNPERCDESC := VNPERDESCTEMP;

            ELSE
              --registro atual não é prioritaria

              IF (VNPERDESCTEMP < VNPERCDESC) OR VNPERCDESC IS NULL THEN

                VNPERCDESC             := VNPERDESCTEMP;
                VDDTINICIO             := REG.DTINICIO;
                VDDTFIM                := REG.DTFIM;
                VNINICIOINTERVALO      := REG.INICIOINTERVALO;
                VNFIMINTERVALO         := REG.FIMINTERVALO;
                VNPERDESCMAX           := REG.PERDESCMAX;
                VSPRIORITARIA          := 'N';
                VSQUESTIONAPRIORITARIA := REG.QUESTIONAUSOPRIORITARIA;
                VNCODDESCONTO          := REG.CODDESCONTO;

              END IF;

              IF VSBASECREDDEBRCATEMP = 'S' AND
                 ((VNPERCBASERCATEMP < VNPERCBASERCA) OR
                 VNPERCBASERCA IS NULL) THEN
                VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
                VNPERCBASERCA         := VNPERCBASERCATEMP;
                VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
                VNCODPOLBASERCA       := REG.CODDESCONTO;
              END IF;
            END IF;

          ELSE
            -- já tem politica prioritaria

            IF (VNPERDESCTEMP < VNPERCDESC) OR VNPERCDESC IS NULL THEN

              VNPERCDESC             := VNPERDESCTEMP;
              VDDTINICIO             := REG.DTINICIO;
              VDDTFIM                := REG.DTFIM;
              VNINICIOINTERVALO      := REG.INICIOINTERVALO;
              VNFIMINTERVALO         := REG.FIMINTERVALO;
              VNPERDESCMAX           := REG.PERDESCMAX;
              VSPRIORITARIA          := REG.PRIORITARIA;
              VSQUESTIONAPRIORITARIA := REG.QUESTIONAUSOPRIORITARIA;
              VNCODDESCONTO          := REG.CODDESCONTO;

            END IF;

            IF VSBASECREDDEBRCATEMP = 'S' AND
               ((VNPERCBASERCATEMP < VNPERCBASERCA) OR
               VNPERCBASERCA IS NULL) THEN
              VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
              VNPERCBASERCA         := VNPERCBASERCATEMP;
              VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
              VNCODPOLBASERCA       := REG.CODDESCONTO;
            END IF;

          END IF;

        ELSE
          --acrescimo

          IF (VNPERCDESC IS NOT NULL AND VNPERCDESC > 0) OR
             VNPERCDESC IS NULL THEN
            -- teve um registro anterior que era acrescimo ou não teve registro anterior
            --caso registro anterior seja desconto ele será utilizado, desconsiderando os acrescimos

            IF (VNPERDESCTEMP > VNPERCDESC) OR VNPERCDESC IS NULL THEN

              VNPERCDESC        := VNPERDESCTEMP;
              VDDTINICIO        := REG.DTINICIO;
              VDDTFIM           := REG.DTFIM;
              VNINICIOINTERVALO := REG.INICIOINTERVALO;
              VNFIMINTERVALO    := REG.FIMINTERVALO;
              VNPERDESCMAX      := REG.PERDESCMAX;
              VNCODDESCONTO     := REG.CODDESCONTO;

            END IF;

            IF VSBASECREDDEBRCATEMP = 'S' AND
               ((VNPERCBASERCATEMP > VNPERCBASERCA) OR
               VNPERCBASERCA IS NULL) THEN
              VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
              VNPERCBASERCA         := VNPERCBASERCATEMP;
              VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
              VNCODPOLBASERCA       := REG.CODDESCONTO;
            END IF;

          END IF;

        END IF;

      END LOOP;

    ELSE

      FOR REG IN (SELECT PCDESCQUANT.PERCDESC,
                         PCDESCQUANT.DTFIM,
                         PCDESCQUANT.PERDESCMAX,
                         PCDESCQUANT.CREDITASOBREPTABELA,
                         PCDESCQUANT.DTINICIO,
                         PCDESCQUANT.INICIOINTERVALO,
                         PCDESCQUANT.FIMINTERVALO,
                         PCDESCQUANT.BASECREDDEBRCA,
                         PCDESCQUANT.PRIORITARIA,
                         PCDESCQUANT.QUESTIONAUSOPRIORITARIA,
                         PCDESCQUANT.CODDESCONTO
                    FROM PCDESCQUANT, PCPLPAG
                   WHERE PCDESCQUANT.CODPROD =
                         DECODE(PCDESCQUANT.APLICAFAMILIAPRODUTOS,
                                'S',
                                P_CODPRODPRINC,
                                P_CODPROD)
                     AND PCDESCQUANT.CODPLPAGMAX = PCPLPAG.CODPLPAG(+)
                     AND DECODE(PCDESCQUANT.CODPLPAGMAX,
                                NULL,
                                P_NUMDIAS,
                                PCPLPAG.NUMDIAS) >= P_NUMDIAS
                     AND ((PCDESCQUANT.NUMREGIAO = P_NUMREGIAO) OR
                         (PCDESCQUANT.NUMREGIAO IS NULL))
                     AND ((PCDESCQUANT.CODPRACA = P_CODPRACA) OR
                         (PCDESCQUANT.CODPRACA IS NULL))
                     AND ((TRUNC(SYSDATE) BETWEEN PCDESCQUANT.DTINICIO AND
                         PCDESCQUANT.DTFIM) OR ((PCDESCQUANT.DTINICIO IS NULL) AND
                         (PCDESCQUANT.DTFIM IS NULL)))
                     AND NVL(PCDESCQUANT.TIPODESCONTO, 'A') = P_TIPODESCONTO
                     AND (((PCDESCQUANT.CODGRUPOREST IS NULL) OR
                         (PCDESCQUANT.TIPOGRUPOREST IS NULL)) OR
                         ((PCDESCQUANT.CODGRUPOREST = CASE
                          WHEN(PCDESCQUANT.TIPOGRUPOREST = 'GR') OR
                          (PCDESCQUANT.TIPOGRUPOREST = 'CL') THEN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                               FROM PCGRUPOSCAMPANHAI, PCGRUPOSCAMPANHAC
                              WHERE PCGRUPOSCAMPANHAC.CODGRUPO =
                                    PCGRUPOSCAMPANHAI.CODGRUPO
                                AND PCGRUPOSCAMPANHAC.DTEXCLUSAO IS NULL
                                AND (PCGRUPOSCAMPANHAC.CODFILIAL IS NULL OR
                                    PCGRUPOSCAMPANHAC.CODFILIAL = P_CODFILIAL)
                                AND PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                AND PCGRUPOSCAMPANHAI.CODGRUPO =
                                    PCDESCQUANT.CODGRUPOREST
                                AND PCGRUPOSCAMPANHAI.CODITEM =
                                    DECODE(TIPOGRUPOREST,
                                           'CL',
                                           P_CODCLI,
                                           'GR',
                                           P_CODUSUR)
                                AND ROWNUM = 1) ELSE 0 END)))
                     AND (PCDESCQUANT.CLASSEVENDA = VSCLASSEVENDA OR
                         PCDESCQUANT.CLASSEVENDA IS NULL)
                     AND (PCDESCQUANT.CODFILIAL = P_CODFILIAL OR
                         PCDESCQUANT.CODFILIAL IS NULL OR
                         PCDESCQUANT.CODFILIAL = '99')
                   ORDER BY PCDESCQUANT.PERCDESC) LOOP

        VBRESULT                   := TRUE;
        VNPERDESCTEMP              := REG.PERCDESC;
        VSBASECREDDEBRCATEMP       := REG.BASECREDDEBRCA;
        VSCREDITASOBREPTABELATEMP  := REG.CREDITASOBREPTABELA;
        VNPERCBASERCATEMP          := REG.PERCDESC;
        VSTEMPPRIORITARIA          := REG.PRIORITARIA;
        VSTEMPQUESTIONAPRIORITARIA := REG.QUESTIONAUSOPRIORITARIA;

        IF VNPERDESCTEMP < 0 THEN
          --desconto

          IF VSPRIORITARIA = 'N' THEN

            IF VSTEMPPRIORITARIA = 'S' THEN
              --registro atual é de politica prioritaria

              IF VSUSAPRIORITARIA = 'S' THEN

                VNPERCDESC        := VNPERDESCTEMP;
                VDDTINICIO        := REG.DTINICIO;
                VDDTFIM           := REG.DTFIM;
                VNINICIOINTERVALO := REG.INICIOINTERVALO;
                VNFIMINTERVALO    := REG.FIMINTERVALO;
                VNPERDESCMAX      := REG.PERDESCMAX;
                VNCODDESCONTO     := REG.CODDESCONTO;

                IF VSBASECREDDEBRCATEMP = 'S' THEN
                  VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
                  VNPERCBASERCA         := VNPERCBASERCATEMP;
                  VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
                  VNCODPOLBASERCA       := REG.CODDESCONTO;
                END IF;

              END IF;

            ELSE
              --registro atual não é prioritaria

              IF (VNPERDESCTEMP < VNPERCDESC) OR VNPERCDESC IS NULL THEN

                VNPERCDESC        := VNPERDESCTEMP;
                VDDTINICIO        := REG.DTINICIO;
                VDDTFIM           := REG.DTFIM;
                VNINICIOINTERVALO := REG.INICIOINTERVALO;
                VNFIMINTERVALO    := REG.FIMINTERVALO;
                VNPERDESCMAX      := REG.PERDESCMAX;
                VNCODDESCONTO     := REG.CODDESCONTO;

              END IF;

              IF VSBASECREDDEBRCATEMP = 'S' AND
                 ((VNPERCBASERCATEMP < VNPERCBASERCA) OR
                 VNPERCBASERCA IS NULL) THEN
                VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
                VNPERCBASERCA         := VNPERCBASERCATEMP;
                VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
                VNCODPOLBASERCA       := REG.CODDESCONTO;
              END IF;
            END IF;

          ELSE
            -- já tem politica prioritaria

            IF (VNPERDESCTEMP < VNPERCDESC) OR VNPERCDESC IS NULL THEN

              VNPERCDESC        := VNPERDESCTEMP;
              VDDTINICIO        := REG.DTINICIO;
              VDDTFIM           := REG.DTFIM;
              VNINICIOINTERVALO := REG.INICIOINTERVALO;
              VNFIMINTERVALO    := REG.FIMINTERVALO;
              VNPERDESCMAX      := REG.PERDESCMAX;
              VNCODDESCONTO     := REG.CODDESCONTO;

            END IF;

            IF VSBASECREDDEBRCATEMP = 'S' AND
               ((VNPERCBASERCATEMP < VNPERCBASERCA) OR
               VNPERCBASERCA IS NULL) THEN
              VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
              VNPERCBASERCA         := VNPERCBASERCATEMP;
              VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
              VNCODPOLBASERCA       := REG.CODDESCONTO;
            END IF;

          END IF;

        ELSE
          --acrescimo

          IF (VNPERCDESC IS NOT NULL AND VNPERCDESC > 0) OR
             VNPERCDESC IS NULL THEN
            -- teve um registro anterior que era acrescimo ou não teve registro anterior
            --caso registro anterior seja desconto ele será utilizado, desconsiderando os acrescimos

            IF (VNPERDESCTEMP > VNPERCDESC) OR VNPERCDESC IS NULL THEN

              VNPERCDESC        := VNPERDESCTEMP;
              VDDTINICIO        := REG.DTINICIO;
              VDDTFIM           := REG.DTFIM;
              VNINICIOINTERVALO := REG.INICIOINTERVALO;
              VNFIMINTERVALO    := REG.FIMINTERVALO;
              VNPERDESCMAX      := REG.PERDESCMAX;
              VNCODDESCONTO     := REG.CODDESCONTO;

            END IF;

            IF VSBASECREDDEBRCATEMP = 'S' AND
               ((VNPERCBASERCATEMP > VNPERCBASERCA) OR
               VNPERCBASERCA IS NULL) THEN
              VSBASECREDDEBRCA      := VSBASECREDDEBRCATEMP;
              VNPERCBASERCA         := VNPERCBASERCATEMP;
              VSCREDITASOBREPTABELA := VSCREDITASOBREPTABELATEMP;
              VNCODPOLBASERCA       := REG.CODDESCONTO;
            END IF;

          END IF;

        END IF;

      END LOOP;
    END IF;

    IF P_TIPODESCONTO = 'A' THEN

      IF VNPERDESCMAX IS NOT NULL THEN
        IF VNPTABELA > P_PVENDA1 * (1 + (NVL(VNPERDESCMAX, 0) / 100)) THEN
          VNPTABELA_QUANT    := VNPTABELA *
                                (1 + (NVL(VNPERCDESC, 0) / 100));
          VNPTABELA_QUANTMAX := P_PVENDA1 *
                                (1 + (NVL(VNPERDESCMAX, 0) / 100));
          IF VNPTABELA_QUANT < VNPTABELA_QUANTMAX THEN
            VNPTABELA := VNPTABELA_QUANTMAX;
            --utilizado só para retornar o percentual
            P_PERDESCFLEX := VNPERDESCMAX;
          ELSE
            VNPTABELA := VNPTABELA_QUANT;
            --utilizado só para retornar o percentual
            P_PERDESCFLEX := VNPERCDESC;
          END IF;
        END IF;
      ELSE
        VNPTABELA := VNPTABELA * (1 + (NVL(VNPERCDESC, 0) / 100));
        --utilizado só para retornar o percentual
        P_PERDESCFLEX := VNPERCDESC;
      END IF;

    ELSE
      P_PERDESCFLEX := NVL(VNPERCDESC, 0);
    END IF;
    --4. Desconto ou Acrescimo
    IF P_APENASVALIDA = 'N' THEN
      VNPTABELA := ROUND(VNPTABELA, P_NUMCASASDECVENDA);
    END IF;

    P_PTABELADESC         := VNPTABELA;
    P_CREDITASOBREPTABELA := VSCREDITASOBREPTABELA;

    P_BASEDEBCREDRCA := VSBASECREDDEBRCA;

    P_PERCBASERCA := VNPERCBASERCA;

    P_PRIORITARIA          := NVL(VSPRIORITARIA, 'N');
    P_QUESTIONAPRIORITARIA := NVL(VSQUESTIONAPRIORITARIA, 'N');

    P_CODDESCONTO    := VNCODDESCONTO;
    P_CODPOLPBASERCA := VNCODPOLBASERCA;

    IF VDDTINICIO IS NOT NULL THEN

      P_DTFIM    := VDDTFIM;
      P_MENSAGEM := TO_CHAR(VDDTINICIO, 'dd/mm/yyyy') || ',' ||
                    VNINICIOINTERVALO || ',' || VNFIMINTERVALO;
    END IF;

    RETURN VBRESULT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
          RETURN FALSE;

    WHEN OTHERS THEN
          p_mensagem := 'Erro validar desconto por quantidade ' || SQLERRM;
          RETURN FALSE;
  END VALIDARDESCONTOQUANTIDADE;
-- Fim Tarefa 1612.064252.2014

FUNCTION validarpoliticasdesconto_med -- 29 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_numdias                  IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_perdescfin               OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_usadescfinseparadodesccom IN varchar2,
   p_param2                   IN number,
   p_codpolbaserca            out number ) RETURN BOOLEAN IS

    CURSOR c_semrede(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number) IS
      SELECT decode(p_usadescfinseparadodesccom,'S',nvl(percdesc,0),(nvl(percdesc,0) + nvl(percdescfin,0))) percdesc,
             nvl(basecreddebrca, 'N') basecreddebrca,
             dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             decode(p_usadescfinseparadodesccom,'S',nvl(pcdesconto.percdescfin,0),0) percdescfin
        FROM pcdesconto,pcplpag
       WHERE p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'N'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codcli = p_codcli) OR (pcdesconto.codcli IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND ((pcdesconto.codprodprinc = p_codprodprinc) OR (pcdesconto.codprodprinc IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(pcdesconto.percdesc, 0) > 0)
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
       ORDER BY pcdesconto.percdesc DESC;

    CURSOR c_semrede_cr(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                        vncodrede IN number , vncodmarca IN number) IS
      SELECT decode(p_usadescfinseparadodesccom,'S',nvl(percdesc,0),(nvl(percdesc,0) + nvl(percdescfin,0))) percdesc,
             nvl(basecreddebrca, 'N') basecreddebrca,
             dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             decode(p_usadescfinseparadodesccom,'S',nvl(percdescfin,0),0) percdescfin
        FROM pcdesconto,pcplpag
       WHERE p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'N'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codcli = p_codcli) OR (pcdesconto.codcli IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND ((pcdesconto.codprodprinc = p_codprodprinc) OR (pcdesconto.codprodprinc IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(pcdesconto.percdesc, 0) < 0)
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')

       ORDER BY pcdesconto.percdesc DESC;

    CURSOR c_comrede(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vncodcliprinc IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number) IS
      SELECT decode(p_usadescfinseparadodesccom,'S',nvl(percdesc,0),(nvl(percdesc,0) + nvl(percdescfin,0))) percdesc,
             nvl(basecreddebrca, 'N') basecreddebrca,
             dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             decode(p_usadescfinseparadodesccom,'S',nvl(pcdesconto.percdescfin,0),0) percdescfin
        FROM pcdesconto,pcplpag
       WHERE pcdesconto.codcli = vncodcliprinc
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'S'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND (nvl(percdesc, 0) > 0)
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T');

    CURSOR c_comrede_cr(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vncodcliprinc IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                        vncodrede IN number , vncodmarca IN number) IS
      SELECT decode(p_usadescfinseparadodesccom,'S',nvl(percdesc,0),(nvl(percdesc,0) + nvl(percdescfin,0))) percdesc,
             nvl(basecreddebrca, 'N') basecreddebrca,
             dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             decode(p_usadescfinseparadodesccom,'S',nvl(pcdesconto.percdescfin,0),0) percdescfin
        FROM pcdesconto,pcplpag
       WHERE pcdesconto.codcli = vncodcliprinc
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         AND nvl(pcdesconto.utilizadescrede, 'N') = 'S'
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(pcdesconto.percdesc, 0) < 0)
         AND case when
       pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T');

    vbresult             BOOLEAN;
    vntempperdesc        NUMBER;
    vstempbasecreddebrca VARCHAR2(2);
    vnpercdesc           NUMBER;
    vsbasecreddebrca     VARCHAR2(2);
    vbresult_cr          BOOLEAN;
    vntempperdesc_cr     NUMBER;
    vnpercdesc_cr        NUMBER;
    --Dados do Cliente
    vncodcliprinc NUMBER;
    vncodatv1     NUMBER;
    vncodpraca    NUMBER;
    --Dados do RCA
    vncodsupervisor NUMBER;
    --Dados do Produto}
    vncodfornec                NUMBER;
    vncodepto                  NUMBER;
    vncodsec                   NUMBER;
    vncodcategoria             NUMBER;
    vncodsubcategoria          NUMBER;
    vicont                     NUMBER;
    vicont2                    NUMBER;
    vicont3                    NUMBER;
    vicontador                 NUMBER;
    vicontador2                NUMBER;
    vsaplicadesconto           VARCHAR2(1);
    vscreditasobrepolitica     VARCHAR2(1);
    vstempcreditasobrepolitica VARCHAR2(1);
    vsareaatuacao              pcusuari.areaatuacao%type;
    vnpercbaserca              number;
    vntemppbaserca             number;
    vssimplesnacional          pcclient.simplesnacional%type;
    vsalteraptabela            varchar2(1);
    vstempalteraptabela        varchar2(1);

    vncodrede                  pcclient.codrede%type;
    vncodmarca                 pcprodut.codmarca%type;

    vstempprioritaria          varchar2(1);
    vsprioritaria              varchar2(1);
    vsquestionaprioritaria     varchar2(1);
    vstempquestionaprioritaria varchar2(1);
    vsusaprioritaria           varchar2(1);

    vntempperdescfin           NUMBER;
    vnpercdescfin               number;

    vncodpoldescbaserca        pcdesconto.coddesconto%type;


  BEGIN
    vbresult      := FALSE;
    vnpercdesc    := 0;
    vnpercdescfin := 0;
    vnpercbaserca := 0;
    --    vnpercdesc_cr          := 0;
    vsbasecreddebrca       := 'N';
    vscreditasobrepolitica := 'S';
    vsalteraptabela        := 'N';
    vsprioritaria          := 'N';
    vsusaprioritaria       := p_mensagem;

    vncodpoldescbaserca    := null;

    IF p_aplicadesconto = 0 THEN
      vsaplicadesconto := 'N';
    ELSE
      vsaplicadesconto := 'S';
    END IF;
    --Buscar dados do cliente
    SELECT COUNT(*) INTO vicont FROM pcclient WHERE codcli = p_codcli;
    IF vicont <> 0 THEN
      SELECT nvl(codcliprinc, codcli) codcliprinc,
             codatv1,
             codpraca,
             pcclient.simplesnacional,
             pcclient.codrede
        INTO vncodcliprinc, vncodatv1, vncodpraca, vssimplesnacional,vncodrede
        FROM pcclient
       WHERE codcli = p_codcli;

      --Buscar dados do RCA
      SELECT COUNT(*) INTO vicont2 FROM pcusuari WHERE codusur = p_codusur;
      IF vicont2 <> 0 THEN
        SELECT codsupervisor, pcusuari.areaatuacao
          INTO vncodsupervisor, vsareaatuacao
          FROM pcusuari
         WHERE codusur = p_codusur;
        --Buscar dados do produto
        SELECT COUNT(*)
          INTO vicont3
          FROM pcprodut
         WHERE codprod = p_codprod;
        IF vicont3 <> 0 THEN
          SELECT codfornec, codepto, codsec, codcategoria, codsubcategoria,codmarca
            INTO vncodfornec,
                 vncodepto,
                 vncodsec,
                 vncodcategoria,
                 vncodsubcategoria,
                 vncodmarca
            FROM pcprodut
           WHERE codprod = p_codprod;
          --Verificação de Políticas de Descontos}
          FOR reg_semrede IN c_semrede(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca) LOOP
            IF (p_tratarrestricaoacrescimo = 'S' AND
               reg_semrede.percdesc >= 0) OR
               p_tratarrestricaoacrescimo = 'N' THEN
              vbresult                   := TRUE;
              vntempperdesc              := reg_semrede.percdesc;
              vntemppbaserca             := reg_semrede.percdesc;
              vstempbasecreddebrca       := reg_semrede.basecreddebrca;
              vstempcreditasobrepolitica := reg_semrede.creditasobrepolitica;
              vstempalteraptabela        := reg_semrede.alteraptabela;
              vstempprioritaria          := reg_semrede.prioritaria;
              vstempquestionaprioritaria := reg_semrede.questionausoprioritaria;
              vntempperdescfin           := reg_semrede.percdescfin;


              if vsprioritaria = 'N' then

                if vstempprioritaria = 'S' then
                  --registro atual é de politica prioritaria

                  if vsusaprioritaria = 'S' then


                    vnpercdesc             := vntempperdesc;
                    vsprioritaria          := vstempprioritaria;
                    vsquestionaprioritaria := vstempquestionaprioritaria;
                    vsalteraptabela        := vstempalteraptabela;
                    vnpercdescfin          := vntempperdescfin;


                    p_mensagem := to_char(reg_semrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_semrede.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_semrede.coddesconto;

                     end if;


                  end if;



                else
                  --registro atual não é de politica prioritaria

                  IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc             := vntempperdesc;
                        vnpercdescfin          := vntempperdescfin;
                        vsprioritaria          := 'N';
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_semrede.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_semrede.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_semrede.coddesconto;

                        end if;



                  END IF;

                        if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' and
                           vntemppbaserca > vnpercbaserca then

                            vsbasecreddebrca       := vstempbasecreddebrca;
                            vnpercbaserca          := vntemppbaserca;
                            vscreditasobrepolitica := vstempcreditasobrepolitica;
                      vncodpoldescbaserca    := reg_semrede.coddesconto;

                  end if;



                end if;

              else
                -- já tem uma politica prioritaria

                      IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc             := vntempperdesc;
                        vnpercdescfin          := vntempperdescfin;
                        vsprioritaria          := vstempprioritaria;
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_semrede.dtinicio, 'dd/mm/yyyy') || ',' ||
                                      reg_semrede.coddesconto;

                              if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_semrede.coddesconto;

                                end if;



                      END IF;

              end if;
            END IF;
          END LOOP;

          FOR reg_comrede IN c_comrede(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vncodcliprinc,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca) LOOP
            IF (p_tratarrestricaoacrescimo = 'S' AND
               reg_comrede.percdesc > 0) OR
               p_tratarrestricaoacrescimo = 'N' THEN
              vbresult                   := TRUE;
              vntempperdesc              := reg_comrede.percdesc;
              vntemppbaserca             := reg_comrede.percdesc;
              vstempbasecreddebrca       := reg_comrede.basecreddebrca;
              vstempcreditasobrepolitica := reg_comrede.creditasobrepolitica;
              vstempalteraptabela        := reg_comrede.alteraptabela;

              vstempprioritaria          := reg_comrede.prioritaria;
              vstempquestionaprioritaria := reg_comrede.questionausoprioritaria;
              vntempperdescfin           := reg_comrede.percdescfin;

              if vsprioritaria = 'N' then

                if vstempprioritaria = 'S' then
                  --registro atual é de politica prioritaria

                  if vsusaprioritaria = 'S' then


                    vnpercdesc             := vntempperdesc;
                    vnpercdescfin          := vntempperdescfin;
                    vsprioritaria          := vstempprioritaria;
                    vsquestionaprioritaria := vstempquestionaprioritaria;
                    vsalteraptabela        := vstempalteraptabela;


                    p_mensagem := to_char(reg_comrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_comrede.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                                end if;


                  end if;



                else
                  --registro atual não é de politica prioritaria

                  IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc := vntempperdesc;
                        vnpercdescfin := vntempperdescfin;
                        vsprioritaria          := 'N';
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_comrede.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_comrede.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                        end if;



                  END IF;

                        if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' and
                           vntemppbaserca > vnpercbaserca then

                            vsbasecreddebrca       := vstempbasecreddebrca;
                            vnpercbaserca          := vntemppbaserca;
                            vscreditasobrepolitica := vstempcreditasobrepolitica;
                      vncodpoldescbaserca    := reg_comrede.coddesconto;

                            end if;

                end if;

              else
                -- já tem uma politica prioritaria

                      IF vntempperdesc > vnpercdesc THEN

                        vnpercdesc             := vntempperdesc;
                        vnpercdescfin          := vntempperdescfin;
                        vsprioritaria          := vstempprioritaria;
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_comrede.dtinicio, 'dd/mm/yyyy') || ',' ||
                                      reg_comrede.coddesconto;

                              if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                                end if;



                      END IF;

              end if;



            END IF;
          END LOOP;

          FOR reg_semrede_cr IN c_semrede_cr(vncodepto,
                                             vncodsec,
                                             vncodcategoria,
                                             vncodfornec,
                                             vncodsupervisor,
                                             vncodatv1,
                                             vncodpraca,
                                             vsaplicadesconto,
                                             vsareaatuacao,
                                             vssimplesnacional,
                                             vncodrede,
                                             vncodmarca) LOOP

            IF p_tratarrestricaoacrescimo = 'S' then

              vbresult_cr                := TRUE;
              vntempperdesc_cr           := reg_semrede_cr.percdesc;
              vntemppbaserca             := reg_semrede_cr.percdesc;
              vstempbasecreddebrca       := reg_semrede_cr.basecreddebrca;
              vstempcreditasobrepolitica := reg_semrede_cr.creditasobrepolitica;
              vstempalteraptabela        := reg_semrede_cr.alteraptabela;

              IF vntempperdesc_cr < nvl(vnpercdesc_cr, 0) THEN
                vnpercdesc_cr := vntempperdesc_cr;
                vsalteraptabela        := vstempalteraptabela;

                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                    vsbasecreddebrca       := vstempbasecreddebrca;
                    vnpercbaserca          := vntemppbaserca;
                    vscreditasobrepolitica := vstempcreditasobrepolitica;
                    vncodpoldescbaserca    := reg_semrede_cr.coddesconto;


                end if;


              END IF;

               if vstempbasecreddebrca = 'S' and  nvl(p_naousarautdebcredpoldesc,'N') = 'N' and
                 vntemppbaserca < vnpercbaserca then
                vsbasecreddebrca       := vstempbasecreddebrca;
                vnpercbaserca          := vntemppbaserca;
                vscreditasobrepolitica := vstempcreditasobrepolitica;
                vncodpoldescbaserca    := reg_semrede_cr.coddesconto;

              end if;

            END IF;
          END LOOP;

          FOR reg_comrede_cr IN c_comrede_cr(vncodepto,
                                             vncodsec,
                                             vncodcategoria,
                                             vncodfornec,
                                             vncodsupervisor,
                                             vncodatv1,
                                             vncodpraca,
                                             vncodcliprinc,
                                             vsaplicadesconto,
                                             vsareaatuacao,
                                             vssimplesnacional,
                                             vncodrede,
                                             vncodmarca) LOOP

            IF p_tratarrestricaoacrescimo = 'S' then

              vbresult                   := TRUE;
              vntempperdesc_cr           := reg_comrede_cr.percdesc;
              vntemppbaserca             := reg_comrede_cr.percdesc;
              vstempbasecreddebrca       := reg_comrede_cr.basecreddebrca;
              vstempcreditasobrepolitica := reg_comrede_cr.creditasobrepolitica;
              vstempalteraptabela        := reg_comrede_cr.alteraptabela;

              IF vntempperdesc_cr < nvl(vnpercdesc_cr, 0) THEN
                vnpercdesc_cr := vntempperdesc_cr;
                vsalteraptabela        := vstempalteraptabela;

                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                    vsbasecreddebrca       := vstempbasecreddebrca;
                    vnpercbaserca          := vntemppbaserca;
                    vscreditasobrepolitica := vstempcreditasobrepolitica;


                end if;


              END IF;

               if vstempbasecreddebrca = 'S' and  nvl(p_naousarautdebcredpoldesc,'N') = 'N' and
                 vntemppbaserca < vnpercbaserca then
                vsbasecreddebrca       := vstempbasecreddebrca;
                vnpercbaserca          := vntemppbaserca;
                vscreditasobrepolitica := vstempcreditasobrepolitica;
                vncodpoldescbaserca    := reg_comrede_cr.coddesconto;

              end if;
            END IF;

          END LOOP;
        ELSE
          p_mensagem := 'Não foi possível buscar dados do PCPRODUT!';
        END IF;
      ELSE
        p_mensagem := 'Não foi possível buscar dados do PCUSUARI!';
      END IF; --dados do PCCLIENT
    ELSE
      p_mensagem := 'Não foi possível buscar dados do PCCLIENT!';
    END IF;

    p_perdescrestricao := (round(vnpercdesc_cr, p_numcasasdecvenda)) * -1;

    p_perdesc              := round(vnpercdesc, p_numcasasdecvenda);
    p_perdescfin           := round(vnpercdescfin, p_numcasasdecvenda);
    p_basecreddebrca       := vsbasecreddebrca;
    p_creditasobrepolitica := vscreditasobrepolitica;
    p_pbaserca             := round(vnpercbaserca, p_numcasasdecvenda);
    p_alteraptabela        := vsalteraptabela;

    p_prioritaria             := nvl(vsprioritaria, 'N');
    p_questionausoprioritaria := nvl(vsquestionaprioritaria, 'N');

    p_codpolbaserca   := vncodpoldescbaserca;


    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END validarpoliticasdesconto_med;


FUNCTION BUSCARLIMCREDCLI
  (pcodcli   IN PCCLIENT.Codcli%type,
   pcodusur  IN PCUSUARI.Codusur%type,
   ptipolim  IN VARCHAR2,
   p_UsarLimiteExtra IN VARCHAR2 DEFAULT 'S')
  RETURN NUMBER

 IS

 vResultado                number;
 vbConsFinal               boolean;
 vperexcedelimcred         number;
 p2553_132                 varchar2(1);
 p2583_132                 varchar2(1);
 p1304_132                 varchar2(1);
 vUsaLimCredCPF            varchar2(1);
 vChecarDiasUteisTitPgnLib varchar2(1);
 vcount                    number;



 FUNCTION BUSCARLIMITE
  (p_codcli   IN PCCLIENT.Codcli%type,
   p_codusur  IN PCUSUARI.Codusur%type,
   p_tipolim  IN VARCHAR2)
  RETURN NUMBER

   AS

     vresult                   number;
     vlimcredtemp              number;
     vpercaumento              number;
     vsStatus                  varchar2(15);
     vLIMCREDCPF               number;
     vDIFERENCA                number;

     BEGIN
       vResult := 0;

       CASE p_tipolim
        WHEN 'N' --Limite Normal
         THEN
          select sum(limcred)
           into vresult
           from pcclient
           where
           decode(p2553_132,
                  'N', codcli,
                  NVL(codcliprinc,codcli)) = decode(p2553_132, 'N', p_codcli,
                                        (select NVL(codcliprinc,codcli)
                                          from pcclient
                                          where codcli = p_codcli));


         WHEN 'E' --Extra
         THEN
          if (p2553_132 = 'N') then
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

          vresult := round((vlimcredtemp * (vperexcedelimcred / 100)), 2);

        WHEN 'S' --Sazonal
         THEN
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

          SELECT percaumento
            into vpercaumento
            FROM pclimcred
           WHERE pclimcred.coddcli = p_codcli
             AND TRUNC(SYSDATE) BETWEEN pclimcred.dtinicio AND
                 pclimcred.dtfim
             AND ((pclimcred.codusur IS NULL) OR
                 (pclimcred.codusur = P_codusur));

          vresult := vlimcredtemp * (nvl(vpercaumento, 0) / 100);
        WHEN 'R' --Contas a Receber em aberto
         THEN

           If vbConsFinal then
            vresult := 0;
          else

            if p2583_132 = 'N' then

              if (p2553_132 = 'N') then
                SELECT SUM(VALOR) VALOR
                  into vresult
                  FROM PCPREST
                 WHERE DTPAG IS NULL
                   AND CODCLI = p_codcli
                   AND codcob not in
                       ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP','SUPP')
                   AND NVL(CHEQUETERCEIRO, 'N') =
                       decode(vUsaLimCredCPF,
                              'S',
                              'N',
                              NVL(CHEQUETERCEIRO, 'N'));
              else
                SELECT SUM(VALOR) VALOR
                  into vresult
                  FROM PCPREST
                 WHERE DTPAG IS NULL
                   AND CODCLI IN (SELECT CODCLI
                                    FROM PCCLIENT
                                   WHERE CODCLIPRINC in (select nvl(codcliprinc,codcli) from pcclient where codcli = p_codcli)
                                  UNION ALL
                                  SELECT CODCLI
                                    FROM PCCLIENT
                                   WHERE CODCLI = p_codcli
                                     AND CODCLIPRINC IS NULL)
                   AND codcob not in
                       ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP','SUPP')
                   AND NVL(CHEQUETERCEIRO, 'N') =
                       decode(vUsaLimCredCPF,
                              'S',
                              'N',
                              NVL(CHEQUETERCEIRO, 'N'));
              end if;

            else
              if (p2553_132 = 'N') then
                SELECT SUM(VALOR) VALOR
                  into vresult
                  FROM PCPREST
                 WHERE DTPAG IS NULL
                   AND CODCLI = p_codcli
                   AND CODCOB <> 'SUPP'
                   AND NVL(CHEQUETERCEIRO, 'N') =
                       decode(vUsaLimCredCPF,
                              'S',
                              'N',
                              NVL(CHEQUETERCEIRO, 'N'));
              else
                SELECT SUM(VALOR) VALOR
                  into vresult
                  FROM PCPREST
                 WHERE DTPAG IS NULL
                   AND CODCOB <> 'SUPP'
                   AND CODCLI IN (SELECT CODCLI
                                    FROM PCCLIENT
                                   WHERE CODCLIPRINC in (select nvl(codcliprinc,codcli) from pcclient where codcli = p_codcli)
                                  UNION ALL
                                  SELECT CODCLI
                                    FROM PCCLIENT
                                   WHERE CODCLI = p_codcli
                                     AND CODCLIPRINC IS NULL)

                   AND NVL(CHEQUETERCEIRO, 'N') =
                       decode(vUsaLimCredCPF,
                              'S',
                              'N',
                              NVL(CHEQUETERCEIRO, 'N'));
              end if;

            end if;

          end if;

          WHEN 'P' --Pedidos a faturar
         THEN
          If vbConsFinal then
            vresult := 0;
          else
            if (p2553_132 = 'N') then
                SELECT SUM(ROUND(NVL(VLATEND, 0), 2)) VLATEND
                  into vresult
                  FROM PCPEDC
                 WHERE DTCANCEL IS NULL
                  AND POSICAO IN ('L', 'M')
                   AND CODCOB <> 'SUPP'
                   AND CODCLI = p_codcli;
                Else
                  SELECT SUM(ROUND(NVL(VLATEND, 0), 2)) VLATEND
                    into vresult
                    FROM PCPEDC
                   WHERE DTCANCEL IS NULL
                     AND POSICAO IN ('L', 'M')
                     AND CODCOB <> 'SUPP'
                     AND CODCLI in (SELECT CODCLI
                                      FROM PCCLIENT
                                     WHERE CODCLIPRINC = p_codcli
                                    UNION ALL
                                    SELECT CODCLI
                                      FROM PCCLIENT
                                     WHERE CODCLI = p_codcli
                                      AND CODCLIPRINC IS NULL);
              end if;
          end if;

         WHEN 'C' --Cheques a Receber
          THEN
           If vbConsFinal then
            vresult := 0;
          else

            if vChecarDiasUteisTitPgnLib = 'S' then
              begin
                SELECT USER_OBJECTS.STATUS
                  into vsStatus
                  FROM USER_OBJECTS
                 WHERE USER_OBJECTS.OBJECT_NAME = 'FNC_DTFINAL';

                if (vsStatus = 'VALID') then
                  vChecarDiasUteisTitPgnLib := 'S';
                else
                  vChecarDiasUteisTitPgnLib := 'N';
                end if;

              exception
                when others then
                  vChecarDiasUteisTitPgnLib := 'N';

              end;

            end if;

            if vChecarDiasUteisTitPgnLib = 'S' then
              if (p2553_132 = 'N') then
                SELECT /*+ INDEX (PCPREST PCPREST_IDX1)*/
                 SUM(NVL(PCPREST.VALOR, 0)) VLCHEQUE
                  into vResult
                  FROM PCPREST
                 WHERE PCPREST.CODCOB NOT IN ('DESD','SUPP')
                   AND PCPREST.DTPAG IS NOT NULL
                   AND NVL(CHEQUETERCEIRO, 'N') = 'N'
                   AND CODCLI = p_codcli
                   AND FNC_DTFINAL(PCPREST.DTPAG,
                                   (SELECT NVL(PCCOB.NUMDIASLIBERACAOCREDITO,
                                               0)
                                      FROM PCCOB
                                     WHERE PCCOB.CODCOB = PCPREST.CODCOB),
                                   'S') > TRUNC(SYSDATE);
              else
                SELECT /*+ INDEX (PCPREST PCPREST_IDX1)*/
                 SUM(NVL(PCPREST.VALOR, 0)) VLCHEQUE
                  into vResult
                  FROM PCPREST
                 WHERE PCPREST.CODCOB NOT IN ('DESD','SUPP')
                   AND PCPREST.DTPAG IS NOT NULL
                   AND NVL(CHEQUETERCEIRO, 'N') = 'N'
                   AND CODCLI in
                       (select codcli
                          from pcclient
                         where NVL(codcliprinc, codcli) =

                               (select NVL(codcliprinc, codcli)
                                  from pcclient
                                 where codcli = p_codcli))
                   AND FNC_DTFINAL(PCPREST.DTPAG,
                                   (SELECT NVL(PCCOB.NUMDIASLIBERACAOCREDITO,
                                               0)
                                      FROM PCCOB
                                     WHERE PCCOB.CODCOB = PCPREST.CODCOB),
                                   'S') > TRUNC(SYSDATE);
              end if;

            else
              if (p2553_132 = 'N') then
                SELECT /*+ INDEX (PCPREST PCPREST_IDX1)*/
                 SUM(NVL(PCPREST.VALOR, 0)) VLCHEQUE
                  into vResult
                  FROM PCPREST
                 WHERE PCPREST.CODCOB NOT IN ('DESD','SUPP')
                   AND PCPREST.DTPAG IS NOT NULL
                   AND NVL(CHEQUETERCEIRO, 'N') = 'N'
                   AND CODCLI = p_codcli
                   AND (PCPREST.DTPAG +
                       (SELECT NVL(PCCOB.NUMDIASLIBERACAOCREDITO, 0)
                           FROM PCCOB
                          WHERE PCCOB.CODCOB = PCPREST.CODCOB)) >
                       TRUNC(SYSDATE);
              else
                SELECT /*+ INDEX (PCPREST PCPREST_IDX1)*/
                 SUM(NVL(PCPREST.VALOR, 0)) VLCHEQUE
                  into vResult
                  FROM PCPREST
                 WHERE PCPREST.CODCOB NOT IN ('DESD','SUPP')
                   AND PCPREST.DTPAG IS NOT NULL
                   AND NVL(CHEQUETERCEIRO, 'N') = 'N'
                   AND CODCLI in (SELECT CODCLI
                                    FROM PCCLIENT
                                   WHERE CODCLIPRINC = p_codcli
                                  UNION ALL
                                  SELECT CODCLI
                                    FROM PCCLIENT
                                   WHERE CODCLI = p_codcli
                                     AND CODCLIPRINC IS NULL)

                   AND (PCPREST.DTPAG +
                       (SELECT NVL(PCCOB.NUMDIASLIBERACAOCREDITO, 0)
                           FROM PCCOB
                          WHERE PCCOB.CODCOB = PCPREST.CODCOB)) >
                       TRUNC(SYSDATE);
              end if;

            end if;

          end if;

         WHEN 'T' --Cheque de Terceiros
          THEN

            SELECT LIMCREDCPF
             into vLIMCREDCPF
             FROM PCCLIENT
             WHERE codcli = p_codcli;

            FOR i in (SELECT cgccpfch
                        FROM pcprest
                       WHERE codcli = p_codcli
                         AND dtpag IS NULL
                         AND NVL (chequeterceiro, 'N') = 'S'
                         AND CODCOB <> 'SUPP'
                        GROUP BY cgccpfch)
              loop

               SELECT GREATEST((SUM(NVL(valor, 0)) - vLIMCREDCPF),0) DIFERENCA
                into vDIFERENCA
                FROM pcprest
                WHERE cgccpfch = i.cgccpfch
                AND CODCOB <> 'SUPP'
                AND dtpag IS NULL;

               vResult := vResult + vDIFERENCA;

              end loop;
          WHEN 'F' --Pedidos a Faturar validando Parametro 1304
            THEN
               If vbConsFinal then
                  vresult := 0;
                else
                   if (p2553_132 = 'N') then
                      SELECT SUM(ROUND(NVL(VLATEND, 0), 2)) VLATEND
                        into vresult
                        FROM PCPEDC,PCPLPAG
                       WHERE DTCANCEL IS NULL
                        AND PCPLPAG.CODPLPAG = PCPEDC.CODPLPAG
                        AND POSICAO IN ('L', 'M')
                         AND PCPEDC.CODCOB NOT IN ('D', 'DH', 'CAR','SUPP')
                         AND PCPEDC.CODCOB NOT IN (SELECT CODCOB
                              FROM PCCOB where CARTAO = 'S')

                         AND CODCLI = p_codcli;
                    Else
                      SELECT SUM(ROUND(NVL(VLATEND, 0), 2)) VLATEND
                        into vresult
                        FROM PCPEDC,PCPLPAG
                       WHERE DTCANCEL IS NULL
                         AND PCPLPAG.CODPLPAG = PCPEDC.CODPLPAG
                         AND POSICAO IN ('L', 'M')
                         AND PCPEDC.CODCOB NOT IN ('D', 'DH', 'CAR','SUPP')
                         AND PCPEDC.CODCOB NOT IN (SELECT CODCOB
                              FROM PCCOB where CARTAO = 'S')
                         AND CODCLI in (SELECT CODCLI
                                          FROM PCCLIENT
                                         WHERE CODCLIPRINC = p_codcli
                                        UNION ALL
                                        SELECT CODCLI
                                          FROM PCCLIENT
                                         WHERE CODCLI = p_codcli
                                           AND CODCLIPRINC IS NULL);
                    End if;
              end if;
       END CASE;

       RETURN nvl(vresult,0);

     END buscarlimite;


 BEGIN

   vbConsFinal := false;

   if pcodcli = 1 then
       vbConsFinal := true;
   end if;

    IF pcodcli in (2,3) then
      begin
        select count(*)
        into vcount
        from pcclient
         where
         cliente = 'CONSUMIDOR FINAL'
         and codcli = pcodcli;
      exception
        when others then
          vcount := 0;
      end;
    end if;

   If ((pcodcli in (2,3)) and (vcount > 0)) then
      vbConsFinal := True;
   end if;

   select Nvl(VALOR,'N')
    into p2553_132
    from pcparamfilial
    where
    nome = 'SOMACREDITOCLIPRINCIPAL'
    and codfilial = '99';

   select Nvl(VALOR,'N')
    into p2583_132
    from pcparamfilial
    where
    nome = 'USABNFLIMITECREDITO'
    and codfilial = '99';

    select Nvl(VALOR,'N')
    into p1304_132
    from pcparamfilial
    where
    nome = 'CON_VERIFICALIMCREDCODCOBD'
    and codfilial = '99';

   SELECT nvl(PEREXCEDELIMCRED,0), NVL(UsaLimCredCPF,'N'), NVL(ChecarDiasUteisTitPgnLib, 'N')
       into vperexcedelimcred, vUsaLimCredCPF, vChecarDiasUteisTitPgnLib
       from pcconsum;

   if ptipolim  = 'D'
      then

       vResultado := BUSCARLIMITE(pcodcli,pcodusur,'N');

       if  p_UsarLimiteExtra = 'S' then
         vResultado :=  vResultado + BUSCARLIMITE(pcodcli,pcodusur,'E');
       end if;

       vResultado :=  vResultado
        - (buscarlimite(pcodcli,pcodusur,'R')
         + buscarlimite(pcodcli,pcodusur,case when p1304_132 = 'N' THEN 'F' ELSE 'P' END)
         + buscarlimite(pcodcli,pcodusur,'C'));

   else
      vResultado := BUSCARLIMITE(pcodcli,pcodusur,ptipolim);

   end if;

 RETURN vResultado;

 END BUSCARLIMCREDCLI;

function CalculoArredondamento(p_Valor            pcpedi.pvenda%type,
                               p_NumCasasDecVenda pcconsum.numcasasdecvenda%type,
                               p_TipoArredondamento pcconsum.tipocalcst%type) return number
-- Função para arredondar cálculo de ST, IPI e Suframa de acordo com os seus respectivos parâmetros da 132
as

vnresult pcpedi.pvenda%type;

begin

   vnresult := p_valor;

     if p_Valor <> 0 then

      if p_TipoArredondamento = 'T2' then

        SELECT TRUNC(p_valor,2) VALOR
        into vnresult
         FROM DUAL;

      elsif p_TipoArredondamento = 'A2' then

         SELECT ROUND(p_VALOR,2) VALOR
         into vnresult
         FROM DUAL;

      elsif  p_TipoArredondamento = 'PV' then
          SELECT ROUND(p_VALOR,p_NUMCASASDECVENDA) VALOR
          into vnresult
          FROM DUAL;

      end if;
     end if;

  return vnresult;

end CalculoArredondamento;



function calcularStMT(p_PVENDA                 in     pcpedi.pvenda%type,
                      p_VLIPI                  in     pcpedi.vlipi%type,
                      p_TIPOCALCST             in     pcconsum.tipocalcst%type,
                      p_CALCSTPF               in     pcconsum.calcstpf%type,
                      p_CONSIDERAISENTOSCOMOPF in     pcconsum.consideraisentoscomopf%type,
                      p_CALCULAST              in     pcclient.calculast%type,
                      p_IEENT                  in     pcclient.ieent%type,
                      p_TIPOFJ                 in     pcclient.tipofj%type,
                      p_contribuinte           in     pcclient.contribuinte%type,
                      p_PAUTA                  in     pctribut.pauta%type,
                      p_IVA                    in     pctribut.iva%type,
                      p_ALIQICMS1              in     pctribut.aliqicms1%type,
                      p_ALIQICMS2              in     pctribut.aliqicms2%type,
                      p_MARGEMVA               in     pccnae.margemmva%type,
                      p_PERCARGATRIBMEDIA      in     pccnae.percargatribmedia%type,
                      p_PERCBASEREDST          in     pctribut.percbaseredst%type,
                      p_NumCasasDecVenda       in     pcconsum.numcasasdecvenda%type,
                      p_UFFilial               in     pcfilial.uf%type,
                      p_EstEnt                 in     pcclient.estent%type,
                      p_ConsumidorFinal        in     pcclient.consumidorfinal%type,
                      p_aceitapfcontribuinte   in     pcconsum.aceitapfcontribuinte%type,
                      p_ClientePessoaEhPessoFisica    in boolean,
                      p_BaseICST               out    pcpedi.baseicst%type,
                      p_Mensagem               out    varchar2,
                      p_ST                     out    pcpedi.st%type) return boolean
as

  vbResult        Boolean;
  vnTempST        pcpedi.st%type;
  vsTempMsg       varchar2(1000);
  vnIndiceST      pcpedi.st%type;
  vnPrecoSemST    pcpedi.pvenda%type;
  vnBCST          pcpedi.st%type;
  vnST1           pcpedi.st%type;
  vnST2           pcpedi.st%type;
  vnValorAgregado pcpedi.pvenda%type;

  -- vbPessoaFisica :Boolean;
  vnBaseICST     pcpedi.baseicst%type;
  vnST           pcpedi.st%type;


begin
  vbResult := false;
  vnBaseICST := 0;
  vnTempST := 0;
  vsTempMsg := '';
  vnIndiceST := 0;
  vnPrecoSemST := 0;
  vnST := 0;


    if (p_ALIQICMS1 <> 0) or (p_ALIQICMS2 <> 0) then
      if p_UFFilial = p_EstEnt then

        if (p_MARGEMVA <> 0) and (p_PERCARGATRIBMEDIA <> 0 )  then
          vnST1 := CalculoArredondamento((p_PVENDA * (p_ALIQICMS1 / 100)), p_NumCasasDecVenda, p_TIPOCALCST);

          vnValorAgregado := CalculoArredondamento(((p_PVENDA + p_VLIPI)* (p_MARGEMVA / 100)), p_NumCasasDecVenda, p_TIPOCALCST);

          vnTempST :=  CalculoArredondamento((vnValorAgregado * (p_PERCARGATRIBMEDIA / 100)), p_NumCasasDecVenda, p_TIPOCALCST);
          vnBaseICST := CalculoArredondamento(((vnST1 + vnTempST ) / (p_ALIQICMS1  / 100)), p_NumCasasDecVenda, p_TIPOCALCST);
        End if;
      else
        if (nvl(p_PERCARGATRIBMEDIA,0) <> 0 )  then

          vnST2 := CalculoArredondamento((p_PVENDA * (p_ALIQICMS2 / 100)), p_NumCasasDecVenda, p_TIPOCALCST);
          --vnValorAgregado := CalculoArredondamento(((pdPVENDA + pdVLIPI)* (pdMARGEMVA / 100)), piNumCasasDecVenda, psTIPOCALCST);
          vnTempST :=  CalculoArredondamento(((p_PVENDA + p_VLIPI) * (p_PERCARGATRIBMEDIA / 100)), p_NumCasasDecVenda, p_TIPOCALCST);
          vnBaseICST := CalculoArredondamento(((vnST2 + vnTempST ) / (p_ALIQICMS1  / 100)), p_NumCasasDecVenda, p_TIPOCALCST);
        End if;
      end if;
    End if;

    if p_CALCULAST = 'N' then
      vnTempST := 0;
    end if;

    if vnTempST < 0 then
      vnTempST := 0;
    end if;

    if ( (p_MARGEMVA = 0) or (p_PERCARGATRIBMEDIA = 0 ) ) and  (p_ALIQICMS1 = 0) and (p_ALIQICMS2 = 0) then
      vnBaseICST := 0;
    end if;

    vbResult := True;

  -- Retorno da função
  p_BaseICST := vnBaseICST;
  p_ST       := vnTempST;
  p_Mensagem := vsTempMsg;

  return vbResult;

   exception when others then

     if vsTempMsg <> '' then
        vsTempMsg := vsTempMsg ||CHR(13) ||'Erro: ' ||SQLCODE||'-'||SQLERRM;
      else
        vsTempMsg := 'Erro: ' ||SQLCODE||'-'||SQLERRM;
      end if;

     return false;



 end calcularstMT;

 procedure proc_calculastMT (p_pvenda                 in out pcpedi.pvenda%type,
                             p_ptabela               in out pcpedi.ptabela%type,
                             p_pbaserca              in out pcpedi.pbaserca%type,
                             p_percipi                in out pcpedi.percipi%type,
                             p_percbaseredst          in out pctribut.percbaseredst%type,
                             p_mostrarpvendasemst     in pctribut.mostrarpvendasemst%type,
                             p_tipofj                 in pcclient.tipofj%type,
                             p_utilizaiesimplificada  in pcclient.utilizaiesimplificada%type,
                             p_consumidorfinal        in pcclient.consumidorfinal%type,
                             p_ieent                  in pcclient.ieent%type,
                             p_contribuinte           in pcclient.contribuinte%type,
                             p_calculast              in pcclient.calculast%type,
                             p_estent                 in pcclient.estent%type,
                             p_consideraisentoscomopf in pcconsum.consideraisentoscomopf%type,
                             p_tipocalcst             in pcconsum.tipocalcst%type,
                             p_calcstpf               in pcconsum.calcstpf%type,
                             p_numcasasdecvenda       in pcconsum.numcasasdecvenda%type,
                             p_aceitapfcontribuinte   in pcconsum.aceitapfcontribuinte%type,
                             p_vlipi                  in pcpedi.vlipi%type,
                             p_vlipiptabela           in pcpedi.vlipi%type,
                             p_vlipipbaserca          in pcpedi.vlipi%type,
                             p_pauta                  in pctribut.pauta%type,
                             p_iva                    in pctribut.iva%type,
                             p_aliqicms1              in pctribut.aliqicms1%type,
                             p_aliqicms2              in pctribut.aliqicms2%type,
                             p_margemmva              in pccnae.margemmva%type,
                             p_percargatribmedia      in pccnae.percargatribmedia%type,
                             p_uffilial               in pcfilial.uf%type,
                             p_st                     out pcpedi.st%type,
                             p_baseicst               out pcpedi.baseicst%type,
                             p_mensagem               out varchar2

                             ) is

  vnstmt              pcpedi.st%type;
  vnstmttabela        pcpedi.st%type;
  vnstmtpbaserca      pcpedi.st%type;
  vbpessoafisica      boolean;
  vnpvenda_red        pcpedi.pvenda%type;
  vnptabela_red       pcpedi.ptabela%type;
  vnpbaserca_red      pcpedi.pbaserca%type;
  vnvlipi_pvenda      pcpedi.vlipi%type;
  vnvlipi_ptabela     pcpedi.vlipi%type;
  vnvlipi_pbaserca    pcpedi.vlipi%type;
  vbcalculosemimposto boolean;
  vnbaseicst          pcpedi.baseicst%type;
  vnbaseicstMT        pcpedi.baseicst%type;
  vbcalculastmt       boolean;

  begin



      vbpessoafisica := false;
      vnStMT         := 0;
      vnStMTTABELA   := 0;
      vnStMTPBASERCA := 0;

    IF  -- 1º caso
    (((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N')) or
      -- 2º caso
      (p_CONSUMIDORFINAL = 'S') or
      -- 3º caso
      ((p_CONSIDERAISENTOSCOMOPF = 'S') and
      ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or
      (p_IEENT = 'ISENTA'))))
      -- somente quando
    and (p_contribuinte = 'N') then

     vbpessoafisica := true;

    end if;

      --Pvenda
      vbcalculastmt := calcularStMT(p_pvenda ,
                                   p_VLIPI,
                                   p_tipocalcst,
                                   p_CALCSTPF,
                                   p_CONSIDERAISENTOSCOMOPF,
                                   p_CALCULAST,
                                   p_IEENT,
                                   p_TIPOFJ,
                                   p_Contribuinte,
                                   p_Pauta,
                                   p_IVA,
                                   p_AliqICMS1,
                                   p_AliqICMS2,
                                   p_MARGEMMVA,
                                   p_PERCARGATRIBMEDIA,
                                   p_PERCBASEREDST,
                                   p_numcasasdecvenda,
                                   p_uffilial,
                                   p_ESTENT,
                                   p_CONSUMIDORFINAL,
                                   p_AceitaPFContribuinte,
                                   vbpessoaFisica,
                                   vnBaseICSTMT,
                                   p_mensagem,
                                   vnStMT);

      --PTabela
      vbcalculastmt :=    calcularStMT(p_Ptabela ,
                                       p_VLIPIPTABELA,
                                       p_tipocalcst,
                                       p_CALCSTPF,
                                       p_CONSIDERAISENTOSCOMOPF,
                                       p_CALCULAST,
                                       p_IEENT,
                                       p_TIPOFJ,
                                       p_Contribuinte,
                                       p_Pauta,
                                       p_IVA,
                                       p_AliqICMS1,
                                       p_AliqICMS2,
                                       p_MARGEMMVA,
                                       p_PERCARGATRIBMEDIA,
                                       p_PERCBASEREDST,
                                       p_numcasasdecvenda,
                                       p_uffilial,
                                       p_ESTENT,
                                       p_CONSUMIDORFINAL,
                                       p_AceitaPFContribuinte,
                                       vbpessoaFisica,
                                       vnBaseICST,
                                       p_mensagem,
                                       vnStMTTABELA);

      --PbaseRca
      vbcalculastmt :=    calcularStMT(p_PBaseRCA ,
                                     p_VLIPIPBASERCA,
                                     p_tipocalcst,
                                     p_CALCSTPF,
                                     p_CONSIDERAISENTOSCOMOPF,
                                     p_CALCULAST,
                                     p_IEENT,
                                     p_TIPOFJ,
                                     p_Contribuinte,
                                     p_Pauta,
                                     p_IVA,
                                     p_AliqICMS1,
                                     p_AliqICMS2,
                                     p_MARGEMMVA,
                                     p_PERCARGATRIBMEDIA,
                                     p_PERCBASEREDST,
                                     p_numcasasdecvenda,
                                     p_uffilial,
                                     p_ESTENT,
                                     p_CONSUMIDORFINAL,
                                     p_AceitaPFContribuinte,
                                     vbpessoaFisica,
                                     vnBaseICST,
                                     p_mensagem,
                                     vnStMTPBASERCA);

     -- if vnStMT > 0 then

        p_ST := vnStMT;

--        if Trim(p_TIPOCALCULOGNRE) = 'P' then
   --        p_st := vnStMT;
  --      elsif Trim(p_TIPOCALCULOGNRE) = 'C' then
    --       p_STClienteGNRE := vnStMT;
      --  end if;

        --(*Preço de Venda*)
        p_PVENDA := Round((p_pvenda + nvl(vnStMT,0) + nvl(p_VLIPI,0)), p_numcasasdecvenda);
        --(*Preço de Tabela*)
        p_PTABELA := Round((p_ptabela + nvl(vnStMTTABELA,0) + nvl(p_VLIPIPTABELA,0)), p_numcasasdecvenda);
        --(*Preço Base RCA*)
        p_PBASERCA := Round((p_PBaseRCA + nvl(vnStMTPBASERCA,0) + nvl(p_VLIPIPBASERCA,0)),p_numcasasdecvenda);

         --p_pauta                         := 0;
         p_baseicst                      := vnBaseICSTMT;


     -- end if;





  end proc_calculastMT;

PROCEDURE Definir_Comissao_por_Embalagem( p_tipovend               in pcusuari.tipovend%type,
                                          p_pcomint1               in pcembalagem.pcomint1%type,
                                          P_PCOMEXT1               in pcembalagem.pcomext1%type,
                                          P_PCOMREP1               in pcembalagem.pcomrep1%type,
                                          p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                          p_percom                 out number) IS
    vnpercom   number;
    vnPCOMREP1 number;
    vnPCOMINT1 number;
    vnPCOMEXT1 number;
    vicont     number;

  BEGIN

    vicont := 0;

    if (p_TIPOVEND = 'I' and P_PCOMINT1 Is not Null) then

      if P_PCOMINT1 = 0 then
        if P_ConsiderarComissaoZero = 'S' then
          vnPERCOM := P_PCOMINT1;
        end if;

      else
        vnPERCOM := P_PCOMINT1;
      end if;

    else
      if P_TIPOVEND = 'E' and P_PCOMEXT1 is not null then

        if P_PCOMEXT1 = 0 then

          if p_ConsiderarComissaoZero = 'S' then
            vnPERCOM := p_PCOMEXT1;
          end if;

        else
          vnPERCOM := P_PCOMEXT1;
        end if;

      else
        if P_TIPOVEND = 'R' and P_PCOMREP1 is not null then

          if P_PCOMREP1 = 0 then

            if p_ConsiderarComissaoZero = 'S' then
              vnPERCOM := P_PCOMREP1;
            end if;

          else
            vnPERCOM := P_PCOMREP1;
          end if;

          --  else
          --  vnPERCOM := 0;
        end if;
      end if;
    end if;


    p_percom := vnpercom;

  END;

procedure Definir_Comissao_PROFISSIONAL(p_codprod                in pcprodut.codprod%type,
                                        p_codcli                 in pcclient.codcli%type,
                                        p_codusur                in pcusuari.codusur%type,
                                        p_tipovenda              in pcplpag.tipovenda%type,
                                        p_codfilial              in pcfilial.codigo%type,
                                        p_considerarcomissaozero in pcfilial.considerarcomissaozero%type,
                                        p_comissaorcatipovenda   in pcconsum.comissaorcatipovenda%type,
                                        p_percom                 out number
                                        ) is

    vnpercom_prof             pcpedi.percom%type;
    vnpercom_prod             pcpedi.percom%type;
    vnprioridade_prod         pccomissaoterceiros.prioridade%type;
    vnpercom_TC               pcpedi.percom%type;
    vnprioridade_TC           pccomissaoterceiros.prioridade%type;
    vnpercom_TCP              pcpedi.percom%type;
    vnprioridade_TCP          pccomissaoterceiros.prioridade%type;
    vnpercent                 pcusuari.percent%type;
    vnpercent2                pcusuari.percent2%type;
    vsTipoMaior_Prioridade    varchar2(4);

  begin


    begin

      SELECT percent
            ,percent2
      into vnpercent,vnpercent2
      FROM pcusuari
      WHERE dttermino IS NULL
      AND codusur = p_codusur
      AND tipovend = 'P';
      exception when others then
      vnpercent := null;
      vnpercent2 := null;

    end;


    if p_comissaorcatipovenda = 'S' then

       if p_tipovenda = 'VV' and vnpercent is not null then

          if vnpercent = 0 then
             if p_considerarcomissaozero = 'S' then
                vnpercom_prof := 0;
             end if;

          else
             vnpercom_prof := vnpercent;
          end if;

        elsif p_tipovenda = 'VP' and vnpercent2 is not null then

          if vnpercent2 = 0 then
             if p_considerarcomissaozero = 'S' then
                vnpercom_prof := 0;
             end if;

          else
             vnpercom_prof := vnpercent2;
          end if;


       end if;

    else

       if vnpercent2 is not null then

          if vnpercent2 = 0 then
             if p_considerarcomissaozero = 'S' then
                vnpercom_prof := 0;
             end if;

          else
             vnpercom_prof := vnpercent2;
          end if;


       end if;

    end if;


  --Comissao Produto

    begin
      select p.percom ,p.prioridade
      into vnpercom_prod, vnprioridade_prod
      from pccomissaoterceiros p,
          (select max(t.percom) percom
            from pccomissaoterceiros t
           where nvl(t.dtinicio,trunc(sysdate)) <= trunc(sysdate)
             and nvl(t.dtfim, trunc(sysdate)) >= trunc(sysdate)
             and t.tipo = 'P'
             and nvl(t.tipoterceiro,'P') = 'P'
             and t.codprod = p_codprod
             and (nvl(t.codfilial, '99') = p_codfilial or nvl(t.codfilial, '99') = '99')) tab
      where nvl(p.dtinicio,trunc(sysdate)) <= trunc(sysdate)
             and nvl(p.dtfim, trunc(sysdate)) >= trunc(sysdate)
             and p.tipo = 'P'
             and nvl(p.tipoterceiro,'P') = 'P'
             and p.codprod = p_codprod
             and (nvl(p.codfilial, '99') = p_codfilial or nvl(p.codfilial, '99') = '99')
             and p.percom = tab.percom
             and rownum = 1;
    exception
      when others then
        vnpercom_prod := null;
        vnprioridade_prod := null;
    end;

    if vnpercom_prod is not null then
       vstipoMaior_prioridade := 'P';

    end if;


--Comissao Terceiro/Cliente

    begin
      select p.percom ,p.prioridade
      into vnpercom_TC, vnprioridade_TC
      from pccomissaoterceiros p,
          (select max(t.percom) percom
            from pccomissaoterceiros t
           where nvl(t.dtinicio,trunc(sysdate)) <= trunc(sysdate)
             and nvl(t.dtfim, trunc(sysdate)) >= trunc(sysdate)
             and t.tipo                  = 'TC'
             and nvl(t.tipoterceiro,'P') = 'P'
             and t.codterceiro           = p_codusur
             and t.codcli                = p_codcli
             and (nvl(t.codfilial, '99') = p_codfilial or nvl(t.codfilial, '99') = '99')) tab
      where nvl(p.dtinicio,trunc(sysdate)) <= trunc(sysdate)
             and nvl(p.dtfim, trunc(sysdate)) >= trunc(sysdate)
             and p.tipo                  = 'TC'
             and nvl(p.tipoterceiro,'P') = 'P'
             and p.codterceiro           = p_codusur
             and p.codcli                = p_codcli
             and (nvl(p.codfilial, '99') = p_codfilial or nvl(p.codfilial, '99') = '99')
             and p.percom                = tab.percom
             and rownum = 1;
    exception
      when others then
        vnpercom_TC := null;
        vnprioridade_TC := null;
    end;

    if vnpercom_TC is not null then

      if (vnPrioridade_TC > vnPrioridade_Prod) or ((vnPrioridade_TC = vnPrioridade_Prod) and
         (vnPerCom_TC > vnPerCom_Prod)) then
        vsTipoMaior_Prioridade := 'TC';
      end if;

    end if;


--Comissao Terceiro/Cliente/Produto

    begin
      select p.percom ,p.prioridade
      into vnpercom_TCP, vnprioridade_TCP
      from pccomissaoterceiros p,
          (select max(t.percom) percom
            from pccomissaoterceiros t
           where nvl(t.dtinicio,trunc(sysdate)) <= trunc(sysdate)
             and nvl(t.dtfim, trunc(sysdate)) >= trunc(sysdate)
             and t.tipo                  = 'TCP'
             and nvl(t.tipoterceiro,'P') = 'P'
             and t.codterceiro           = p_codusur
             and t.codcli                = p_codcli
             and t.codprod               = p_codprod
             and (nvl(t.codfilial, '99') = p_codfilial or nvl(t.codfilial, '99') = '99')) tab
      where nvl(p.dtinicio,trunc(sysdate)) <= trunc(sysdate)
             and nvl(p.dtfim, trunc(sysdate)) >= trunc(sysdate)
             and p.tipo                  = 'TCP'
             and nvl(p.tipoterceiro,'P') = 'P'
             and p.codterceiro           = p_codusur
             and p.codcli                = p_codcli
             and p.codprod               = p_codprod
             and (nvl(p.codfilial, '99') = p_codfilial or nvl(p.codfilial, '99') = '99')
             and p.percom                = tab.percom
             and rownum = 1;
    exception
      when others then
        vnpercom_TCP := null;
        vnprioridade_TCP := null;
    end;

    if vnpercom_TCP is not null then

      if (vnPrioridade_TCP > vnPrioridade_Prod) or ((vnPrioridade_TCP = vnPrioridade_Prod) and
         (vnPerCom_TCP > vnPerCom_Prod)) then

        vsTipoMaior_Prioridade := 'TCP';
      else

         if (vnPrioridade_TCP > vnPrioridade_TC) or
            ((vnPrioridade_TCP = vnPrioridade_TC) and (vnPerCom_TCP > vnPerCom_TC)) then

            vsTipoMaior_Prioridade := 'TCP';
         end if;
      end if;

    end if;


    if vsTipoMaior_Prioridade is null then
      vsTipoMaior_Prioridade := 'PROF';
    end if;


    -- Retornando a comissão de maior prioridade
    if vsTipoMaior_Prioridade = 'P' then
      p_percom := vnPerCom_Prod;
    elsif vsTipoMaior_Prioridade = 'TC' then
      p_percom := vnPerCom_TC;
    elsif vsTipoMaior_Prioridade = 'TCP' then
      p_percom := vnPerCom_TCP;
    elsif vsTipoMaior_Prioridade = 'PROF' then
      p_percom := vnPerCom_Prof;
    end if;

    -- Caso as prioridades sejam iguais será retornado a maior dentre todas
    if (vnPrioridade_Prod <> -1) and (vnPrioridade_Prod = vnPrioridade_TC) and
     (vnPrioridade_Prod = vnPrioridade_TCP) then

      p_percom := vnPerCom_Prod;

      if p_percom < vnPerCom_TC then
          p_percom := vnPerCom_TC;
      end if;

      if p_percom < vnPerCom_TCP then
         p_percom := vnPerCom_TCP;
      end if;

    end if;

  end;

  PROCEDURE proc_pcparamfilial
  (
    p_codfilial IN pcfilial.codigo%TYPE,
    p_nome      IN pcparamfilial.nome%TYPE,
    p_padrao    IN pcparamfilial.valor%TYPE,
    p_valor     OUT pcparamfilial.valor%TYPE
  ) IS

    vsnome pcparamfilial.nome%TYPE;

  BEGIN

    vsnome := upper(TRIM(p_nome));


    BEGIN
      SELECT nvl(p.valor,
                 p_padrao)
        INTO p_valor
        FROM pcparamfilial p
       WHERE upper(TRIM(p.nome)) = vsnome
         AND p.codfilial = p_codfilial;
    EXCEPTION

      WHEN no_Data_found THEN

        BEGIN

          SELECT nvl(p.valor,
                     p_padrao)
            INTO p_valor
            FROM pcparamfilial p
           WHERE upper(TRIM(p.nome)) = vsnome
             AND p.codfilial = '99';
        EXCEPTION
          WHEN no_data_found THEN

            p_valor := p_padrao;

        END;

      WHEN OTHERS THEN
        p_valor := p_padrao;

    END;



  END proc_pcparamfilial;

  FUNCTION func_HoraDigitacaoPedido
  (
    P_CODFILIAL IN VARCHAR2,
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
     WHERE CODIGO = P_CODFILIAL;

    p_mensagem := NULL;

    vbResult := (SYSDATE >= vdHoraInicialimportacao) AND (SYSDATE <= vdHoraFinalimportacao);

    IF vbresult = FALSE
    THEN
      p_mensagem := 'Horário limite para digitação do pedido ultrapassado.#' || 'Verifique rotina 535.';
    END IF;

    RETURN vbresult;

  END func_HoraDigitacaoPedido;


  FUNCTION CALCULAR_CMV(pNumped                IN NUMBER,
                        pCodProd               IN NUMBER,
                        pNumseq                IN NUMBER,
                        pAliquotaInterna       IN NUMBER,
                        pPrecoVenda            IN NUMBER,
                        pFORMULACMV            IN VARCHAR2
                   ) RETURN TB_CALCULOCMV
  PIPELINED IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    DADOS_SAIDA T_CALCULOCMV;
    pValor      NUMBER(18,6);
    VFORMULA    PCFORMULA.FORMULA%TYPE;

    vtVariaveis formula.tbVariaveis;
    resultado   formula.tbvariaveis;
    variavel    formula.RVARIAVEL;

    procedure GerarLog1
    is
      voLog       pcpedicmv%rowtype;
      i           number;
    begin
      --Gravar log
      voLog.numped  := pNumped;
      voLog.numseq  := pNumseq;
      voLog.codprod := pCodprod;
      voLog.codformula := pFORMULACMV;
      voLog.cmvformula := Vformula;
      i := 0;
      LOOP
        EXIT WHEN i > vtVariaveis.last;

        voLog.cmvvariaveis := voLog.cmvvariaveis || 'Nome: '|| vtVariaveis(i).Nome||' Valor: '||NVL(vtVariaveis(i).Valor,'VAZIO') || CHR(13);
        i := i + 1;
      END LOOP;

      if (voLog.Numped > 0) and  (voLog.codprod > 0)then
       begin
          insert into pcpedicmv ( numped
                               , codprod
                               , numseq
                               , codformula
                               , cmvformula
                               , cmvvariaveis )
              values ( pNumped
                     , pCodprod
                     , pNumseq
                     , pFORMULACMV
                     , empty_clob()
                     , empty_clob())
                         returning cmvformula, cmvvariaveis
                             into voLog.cmvformula, voLog.cmvvariaveis;
        exception
        when dup_val_on_index then
          update pcpedicmv
             set codformula   = voLog.codformula
               , cmvformula   = voLog.cmvformula
               , cmvvariaveis = voLog.cmvvariaveis
           where codprod      = voLog.codprod
             and numped       = voLog.numped
             and numseq       = voLog.numseq;
        end;

        commit;
      end if;
    end;

    procedure GerarLog2(psNomeFormula in Varchar2,
                        psNomeAtributo in Varchar2,
                        pnValor        in Number)
    is
      voLog PCPEDICMVRESULTADO%rowtype;
    begin
       voLog.numped     := pNumped;
       voLog.numseq     := pNumseq;
       voLog.codprod    := pCodprod;
       voLog.codformula := psNomeFormula;
       voLog.registro   := psNomeAtributo;
       voLog.Valor      := pnValor;

       if (voLog.Numped > 0) and  (voLog.codprod > 0) then
       begin
         insert into PCPEDICMVRESULTADO
               values voLog;
       exception
         when dup_val_on_index then
           update PCPEDICMVRESULTADO
              set registro   = voLog.registro
                , valor      = voLog.Valor
            where codprod      = voLog.codprod
              and numped       = voLog.numped
              and numseq       = voLog.numseq
              and codformula = voLog.codformula;
       end;
       commit;
      end if;
    end;

  BEGIN
    variavel.Nome         := '[CODPROD]';
    variavel.Valor        := pCodProd;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERICM]';
    variavel.Valor        := pAliquotaInterna;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[NUMPED]';
    variavel.Valor        := pNumped;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[NUMSEQ]';
    variavel.Valor        := pNumSeq;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PVENDA]';
    variavel.Valor        := pPrecoVenda;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERPIS]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);

    variavel.Nome         := '[PERCOFINS]';
    variavel.Valor        := 0;
    FORMULA.ATRIBUIVALOR(variavel, vtVariaveis);
   
    VFORMULA := FORMULA.SUBSTITUIFORMULAS(pFORMULACMV, RESULTADO);

    GerarLog1;

    BEGIN
      DADOS_SAIDA.CODICMTAB := ROUND( COALESCE( formula.CalcularSubFormula(VFORMULA, vtVariaveis),0), 4);
      GerarLog2(pFORMULACMV, 'CODICMTAB', DADOS_SAIDA.CODICMTAB);
    EXCEPTION
    WHEN OTHERS THEN
      Raise_Application_Error(-20001,  sqlerrm);
    END;

    PIPE ROW(DADOS_SAIDA);
    RETURN;
  END;

  FUNCTION RETORNARPRECOTABELASEMIMPOSTO(PNNUMPED  IN NUMBER,
                                                         PNCODPROD IN NUMBER,
                                                         PNNUMSEQ  IN NUMBER)
  RETURN NUMBER IS
  VCONSIDERAPRECOSEMIMPOSTO VARCHAR2(1);
  VPRECOFIXO                VARCHAR2(1);
  VINDVLST                  NUMBER;
  VSRETIRAIMPOSTO201        VARCHAR2(1);
  VSITEMTV1BNF              VARCHAR2(1);
  VNPTABELASEMIMPOSTO       NUMBER;
  VNPTABELASEMIMPOSTO_TEMP  NUMBER;
  VSMSGRETORNO              VARCHAR2(4000);

BEGIN

  BEGIN
    VSMSGRETORNO := '';

    /*
    BEGIN*/

    FOR PEDIDO IN (SELECT C.CODFILIAL,
                          C.CODFILIALNF,
                          I.CODFILIALRETIRA,
                          C.CODCLI,
                          C.CODPLPAG,
                          I.CODPROD,
                          I.CODAUXILIAR,
                          C.CONDVENDA,
                          NVL(I.PTABELA,0) PTABELA,
                          NVL(I.ST, 0) ST,
                          NVL(I.VLFECP, 0) VLFECP,
                          NVL(I.STPTABELA, 0) STPTABELA,
                          NVL(I.VLIPIPTABELA, 0) VLIPIPTABELA,
                          NVL(I.CODPRECOFIXO, 0) CODPRECOFIXO,
                          NVL(I.PERDESC, 0) PERDESC,
                          CLI.SIMPLESNACIONAL,
                          NVL(TRI.PERCREDPVENDASIMPLESNAC, 0) PERCREDPVENDASIMPLESNAC,
                          C.VENDATRIANGULAR,
                          C.CODENDENTCLI,
                          C.TIPODOCUMENTO,
                          I.BONIFIC,
                          C.CODBNF
                     FROM PCPEDC C, PCPEDI I, PCCLIENT CLI, PCTRIBUT TRI
                    WHERE C.NUMPED = I.NUMPED
                      AND CLI.CODCLI = C.CODCLI
                      AND TRI.CODST = I.CODST
                      AND I.NUMPED = PNNUMPED
                      AND I.CODPROD = PNCODPROD
                      AND I.NUMSEQ = PNNUMSEQ
                      UNION
                   SELECT C.CODFILIAL,
                          C.CODFILIALNF,
                          I.CODFILIALRETIRA,
                          C.CODCLI,
                          C.CODPLPAG,
                          A.CODPRODMP AS CODPROD,
                          I.CODAUXILIAR,
                          C.CONDVENDA,
                          NVL(A.PTABELA, 0) PTABELA,
                          NVL(A.ST, 0) ST,
                          NVL(A.VLFECP, 0) VLFECP,
                          NVL(A.STPTABELA, 0) STPTABELA,
                          NVL(A.VLIPIPTABELA, 0) VLIPIPTABELA,
                          0 CODPRECOFIXO,
                          NVL(I.PERDESC, 0) PERDESC,
                          CLI.SIMPLESNACIONAL,
                          NVL(TRI.PERCREDPVENDASIMPLESNAC, 0) PERCREDPVENDASIMPLESNAC,
                          C.VENDATRIANGULAR,
                          C.CODENDENTCLI,
                          C.TIPODOCUMENTO,
                          'N' AS BONIFIC,
                          C.CODBNF
                     FROM PCPEDC      C,
                          PCPEDI      I,
                          PCPEDICESTA A,
                          PCCLIENT    CLI,
                          PCTRIBUT    TRI
                    WHERE C.NUMPED = I.NUMPED
                      AND I.NUMPED = A.NUMPED
                      AND C.NUMPED = A.NUMPED
                      AND I.CODPROD = A.CODPROD
                      AND A.NUMSEQ = I.NUMSEQ
                      AND CLI.CODCLI = C.CODCLI
                      AND TRI.CODST = I.CODST
                      AND A.NUMPED = PNNUMPED
                      AND (A.CODPRODMP = PNCODPROD OR A.CODPROD = PNCODPROD)
                      AND I.NUMSEQ = PNNUMSEQ
                      AND A.CODPROD <> 999999) LOOP

      VCONSIDERAPRECOSEMIMPOSTO := 'N';
      VPRECOFIXO                := 'N';
      VINDVLST := CASE
                    WHEN NVL(PEDIDO.ST, 0) = 0 THEN
                     0
                    ELSE
                     1
                  END;

      IF NVL(PEDIDO.CODPRECOFIXO, 0) > 0 THEN
        BEGIN
          VPRECOFIXO := 'S';
          SELECT NVL(PCPRECOPROM.CONSIDERAPRECOSEMIMPOSTO, 'N')
            INTO VCONSIDERAPRECOSEMIMPOSTO
            FROM PCPRECOPROM
           WHERE CODPRECOPROM = PEDIDO.CODPRECOFIXO
             AND CODPROD = PEDIDO.CODPROD;

        EXCEPTION
          WHEN OTHERS THEN
            VCONSIDERAPRECOSEMIMPOSTO := 'N';
        END;

        IF nvl(VCONSIDERAPRECOSEMIMPOSTO, 'N') = 'S' THEN
          VINDVLST := 0;
        ELSE
          VINDVLST := 1;

        END IF;

      END IF;

      VSRETIRAIMPOSTO201 := CASE VPRECOFIXO
                              when 'S' then
                               VCONSIDERAPRECOSEMIMPOSTO
                              else
                               'S'
                            END;

      IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',
                                             NVL(PEDIDO.CODFILIALNF,
                                                 PEDIDO.CODFILIAL),
                                             'N') = 'N') AND
         (nvl(PEDIDO.SIMPLESNACIONAL, 'N') = 'S') AND
         (nvl(PEDIDO.PERCREDPVENDASIMPLESNAC, 0) > 0) THEN
        VSRETIRAIMPOSTO201 := 'S';
      END IF;

      IF PEDIDO.BONIFIC <> 'N' THEN
        VSITEMTV1BNF := 'S';
      ELSE
        VSITEMTV1BNF := 'N';

      END IF;

      VNPTABELASEMIMPOSTO_TEMP := (PEDIDO.PTABELA - PEDIDO.VLIPIPTABELA - PEDIDO.STPTABELA -
                                          (NVL(PEDIDO.VLFECP, 0) * 100 / (100 - PEDIDO.PERDESC)));

      SELECT VALORSEMIMPOSTO, MSG
        INTO VNPTABELASEMIMPOSTO, VSMSGRETORNO
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(PEDIDO.CODFILIAL,
                                                              PEDIDO.CODFILIALNF,
                                                              PEDIDO.CODFILIALRETIRA,
                                                              PEDIDO.CODCLI,
                                                              PEDIDO.CODPLPAG,
                                                              PEDIDO.CODPROD,
                                                              PEDIDO.CODAUXILIAR,
                                                              PEDIDO.CONDVENDA,
                                                              'N',
                                                              VINDVLST,
                                                              0,
                                                              PEDIDO.PTABELA,
                                                              VSRETIRAIMPOSTO201,
                                                              'S',
                                                              VSITEMTV1BNF,
                                                              PEDIDO.CODPRECOFIXO,
                                                              NULL,
                                                              'N',
                                                              'N',
                                                              'N',
                                                              'N',
                                                              0,
                                                              PEDIDO.VENDATRIANGULAR,
                                                              'I',
                                                              PEDIDO.CODBNF,
                                                              PEDIDO.CODENDENTCLI,
                                                              PEDIDO.TIPODOCUMENTO));

        IF NVL(VNPTABELASEMIMPOSTO, 0) = 0 THEN
          VNPTABELASEMIMPOSTO := VNPTABELASEMIMPOSTO_TEMP;
        END IF;

      RETURN VNPTABELASEMIMPOSTO;

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      VSMSGRETORNO := VSMSGRETORNO ||
                      'Erro ao buscar Preço de Tabela sem Imposto: ' ||
                      CHR(13) || SQLCODE || ' - ' || SQLERRM;
  END;

END RETORNARPRECOTABELASEMIMPOSTO;


END; -- FUNCOESVENDAS
